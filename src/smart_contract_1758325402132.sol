This smart contract, **EASFoundry (Evolving Algorithmic Strategy Foundry)**, introduces a novel concept where on-chain "Algorithmic Strategies" (ASs) are created, can "evolve" (mutate their parameters), and "breed" based on external data inputs (via oracles) and internal logic. Each AS has a unique "DNA" (a set of parameters) and an associated "energy balance" (an ERC20 token) required for its operations and evolution. The protocol's core parameters and approved logic hashes are managed through a simplified decentralized governance mechanism.

---

## EASFoundry: Evolving Algorithmic Strategy Foundry

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol"; // Used for clarity, though less critical in Solidity 0.8+
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Pausable.sol"; // For emergency pause functionality

//  _   _     _ _                       ___        _             _
// | | | | __| | |___      ___ __ _ ___|_ _|_ __  | |__  ___  __| | ___  ___
// | |_| |/ _` | __\ \ /\ / / '__| / __|| || '_ \ | '_ \/ __|/ _` |/ _ \/ __|
// |  _  | (_| | |_ \ V  V /| |  | \__ \| || |_) || | | \__ \ (_| |  __/\__ \
// |_| |_|\__,_|\__| \_/\_/ |_|  |_|___/___| .__/ |_| |_|___/\__,_|\___||___/
//                                         |_|
//
// EAS Foundry: Evolving Algorithmic Strategy Foundry
// A decentralized protocol for creating, evolving, and managing algorithmic strategies on-chain.
// Strategies (ASs) possess "DNA" (parameters) that can mutate and breed, driven by energy (ERC20 tokens)
// and guided by fitness functions using external oracle data. The protocol itself is subject
// to decentralized governance for core parameter adjustments.

// --- Outline ---
// 1. Contract Description (above)
// 2. Struct Definitions:
//    - AlgorithmicStrategy: Represents a unique algorithmic strategy with its DNA, owner, and state.
//    - EvolutionGene: Defines characteristics of a mutable parameter (gene) within a strategy's DNA.
//    - FitnessFunction: Defines a metric for evaluating strategy performance based on oracle data.
//    - OracleFeed: Details for a registered external oracle data source.
//    - Proposal: Structure for governance proposals, including voting outcomes.
// 3. Interface Definitions:
//    - IOracle: Simplified interface for an external oracle service.
// 4. Events: Notifications for key contract actions.
// 5. Error Definitions: Custom error types for clearer feedback.
// 6. Main Contract Logic:
//    - State Variables: Core contract data, configurations, and counters.
//    - Constructor: Initializes the contract with the designated energy token.
//    - Access Control & Modifiers: Defines roles and permission checks.
//    - I. Core Strategy Management: Functions for creating, mutating, breeding, and general lifecycle management of ASs.
//    - II. Energy/Resource Management: Functions for depositing, withdrawing, and configuring energy costs for AS operations.
//    - III. Oracle/Data Integration: Functions for managing oracle feeds, requesting data, and fulfilling data requests.
//    - IV. Evolution & Fitness Management: Functions for defining the global gene pool, fitness functions, and triggering strategy fitness calculations.
//    - V. Governance & Protocol Settings: Simplified DAO-like functions for protocol upgrades, parameter changes, and emergency controls.
//    - Internal Helper Functions: Utility functions for internal logic (if needed, none complex enough for this example).

// --- Function Summary ---
// I. Core Strategy Management (7 functions)
// 1. createAlgorithmicStrategy(uint256[] calldata initialDNA, bytes32 logicTreeHash): Deploys a new AS with initial DNA and a reference to off-chain logic, consuming `creationCost` energy.
// 2. mutateAlgorithmicStrategy(uint256 strategyId): Triggers an evolutionary mutation for an AS. Its DNA parameters can randomly change within defined gene ranges, consuming `mutationCost` energy.
// 3. breedAlgorithmicStrategies(uint256 parent1Id, uint256 parent2Id, bytes32 newLogicTreeHash): Creates a new AS by combining the DNA of two parent strategies (crossover logic), consuming `breedingCost` energy.
// 4. updateStrategyLogicHash(uint256 strategyId, bytes32 newLogicTreeHash): Allows an AS owner to update the reference to their strategy's off-chain decision logic.
// 5. deactivateStrategy(uint256 strategyId): Deactivates an AS, preventing further operations like mutation, breeding, or data requests.
// 6. activateStrategy(uint256 strategyId): Reactivates a previously deactivated AS, allowing it to resume operations.
// 7. getStrategyDetails(uint256 strategyId): View function to retrieve all detailed information about an Algorithmic Strategy.

// II. Energy/Resource Management (4 functions)
// 8. depositEnergy(uint256 strategyId, uint256 amount): Allows users to deposit `energyToken` into an AS, fueling its operations.
// 9. withdrawEnergy(uint256 strategyId, uint256 amount): Allows the owner of an AS to withdraw unused `energyToken` from their strategy's balance.
// 10. setEnergyConsumptionRates(uint256 creationCost, uint256 mutationCost, uint256 breedingCost, uint256 oracleRequestCost): Sets the costs for various protocol operations in `energyToken` (protocol owner only).
// 11. getEnergyBalance(uint256 strategyId): View function to check the current `energyToken` balance of a specific AS.

// III. Oracle/Data Integration (4 functions)
// 12. requestOracleDataForStrategy(uint256 strategyId, uint256 oracleFeedId, bytes memory callbackData): Initiates a request for external data from a registered oracle for a specific AS, consuming `oracleRequestCost` energy.
// 13. fulfillOracleData(uint256 strategyId, uint256 oracleFeedId, bytes32 requestId, bytes memory data): Callback function used by registered oracles to deliver requested data. This data is used for fitness calculation.
// 14. registerOracleFeed(address oracleAddress, bytes32 feedIdentifier): Protocol owner registers a new trusted oracle address and its unique identifier for data feeds.
// 15. updateOracleFeedStatus(uint256 oracleFeedId, bool isActive): Protocol owner can activate or deactivate registered oracle feeds.

// IV. Evolution & Fitness Management (4 functions)
// 16. setEvolutionParameters(uint256 globalMutationRate, uint256 mutationEnergyThreshold, uint256 minFitnessForBreeding): Sets global parameters that govern how strategies evolve, such as mutation intensity and breeding eligibility thresholds (protocol owner only).
// 17. calculateFitnessScore(uint256 strategyId): Triggers an on-chain calculation of a strategy's fitness based on its DNA, recent oracle data, and defined fitness functions.
// 18. defineFitnessFunction(string calldata name, uint256 oracleFeedId, uint256 weight, bytes32 calculationLogicHash): Protocol owner defines a new method for evaluating strategy performance, linking it to an oracle feed and weighting.
// 19. updateFitnessFunctionWeight(uint256 fitnessFunctionId, uint256 newWeight): Protocol owner adjusts the weighting of an existing fitness function in the overall fitness score calculation.

// V. Governance & Protocol Settings (6 functions, including Pausable)
// 20. proposeProtocolUpgrade(bytes32 proposalHash, uint256 executionTimestamp): Allows users with sufficient `energyToken` voting power to propose system-wide upgrades or parameter changes.
// 21. voteOnProposal(uint256 proposalId, bool support): Allows users with `energyToken` voting power to cast their vote (yes/no) on an active proposal.
// 22. executeProposal(uint256 proposalId): Executes an approved and passed proposal after its designated execution timestamp (currently owner-gated for simplicity, would be Timelock in a full DAO).
// 23. setCoreGenePool(uint256[] calldata geneIds, string[] calldata geneNames, uint256[] calldata minVals, uint256[] calldata maxVals, uint256[] calldata steps, bool[] calldata isMutableFlags): Protocol owner defines the global set of mutable "genes" (parameters) that strategies can possess, establishing DNA structure and constraints.
// 24. addAllowedStrategyLogicHash(bytes32 logicHash): Protocol owner whitelists a specific strategy logic hash, ensuring only approved off-chain logic can be referenced by ASs.
// 25. emergencyPause(): Allows the contract owner to pause critical functions in case of an emergency (inherited from Pausable).
// 26. unpause(): Allows the contract owner to unpause critical functions (inherited from Pausable).

contract EASFoundry is Ownable, Pausable {
    using SafeMath for uint256;
    using Counters for Counters.Counter;

    // --- State Variables ---

    IERC20 public immutable energyToken; // The ERC20 token used to fuel strategy operations and serves as voting power for governance.

    // Counters for unique IDs across different entities
    Counters.Counter private _strategyIdCounter;
    Counters.Counter private _geneIdCounter;
    Counters.Counter private _fitnessFunctionIdCounter;
    Counters.Counter private _oracleFeedIdCounter;
    Counters.Counter private _proposalIdCounter;

    // --- Struct Definitions ---

    // Represents a unique algorithmic strategy
    struct AlgorithmicStrategy {
        uint256 id;
        address owner;
        uint256[] parentIds; // IDs of parent strategies if created through breeding
        uint256 creationBlock;
        uint256 lastEvolutionBlock;
        uint256 energyBalance; // Balance of energyToken specifically for this strategy
        uint256[] dnaParameters; // Array of uint256 representing the strategy's mutable parameters
        bytes32 logicTreeHash; // Hash referencing off-chain detailed decision logic (e.g., IPFS CID for human-readable logic)
        uint256 fitnessScore; // Current calculated performance score (e.g., out of 1000)
        uint256 mutationThreshold; // Specific mutation threshold for this strategy (can be derived from global, or adapted)
        bool active;
        uint256 lastOracleDataTimestamp; // Timestamp of the last received oracle data relevant to this strategy
        bytes32 lastOracleDataHash;      // Hash of the last received oracle data to prevent replay attacks on fitness calculation
    }

    // Defines a mutable parameter within a strategy's DNA
    struct EvolutionGene {
        uint256 id;
        string name;
        uint256 minVal; // Minimum allowed value for this gene
        uint256 maxVal; // Maximum allowed value for this gene
        uint256 step;   // Granularity/increment for mutation
        bool isMutable; // Can this gene be changed by the mutation process?
    }

    // Defines a metric for evaluating strategy performance
    struct FitnessFunction {
        uint256 id;
        string name;
        uint256 oracleFeedId; // Links to an OracleFeed for necessary external data
        uint256 weight;       // Weighting in the overall fitness calculation (e.g., 0-100)
        bytes32 calculationLogicHash; // Hash referencing off-chain logic for how to calculate fitness from data
        bool isActive;
    }

    // Details for a registered oracle data source
    struct OracleFeed {
        uint256 id;
        address oracleAddress; // The address of the external oracle contract (or a Chainlink Client)
        bytes32 feedIdentifier; // Unique identifier for the data feed (e.g., `keccak256("ETH/USD")`)
        bool isActive;
        mapping(bytes32 => bool) pendingRequests; // requestId => true if a request is pending for this feed
    }

    // Structure for governance proposals
    struct Proposal {
        uint256 id;
        bytes32 proposalHash; // IPFS hash or similar reference to the proposal details (e.g., markdown, code changes)
        uint256 proposerVotingPower; // Voting power of the proposer at the time of proposal creation
        uint256 executionTimestamp; // Timestamp after which the proposal can be executed if it passes
        uint256 yesVotes;
        uint256 noVotes;
        bool executed;
        // In a real system, `targetFunction` and `callData` would be included for direct execution
        // bytes4 targetFunctionSignature;
        // bytes   targetCallData;
    }

    // --- Mappings ---
    mapping(uint256 => AlgorithmicStrategy) public strategies;
    mapping(uint256 => EvolutionGene) public globalGenePool;
    mapping(uint256 => FitnessFunction) public fitnessFunctions;
    mapping(uint256 => OracleFeed) public oracleFeeds;
    mapping(uint256 => Proposal) public proposals;
    mapping(uint256 => mapping(address => bool)) public hasVoted; // proposalId => voterAddress => hasVoted (to prevent double voting)

    mapping(bytes32 => bool) public allowedStrategyLogicHashes; // Whitelisted off-chain logic hashes for strategies
    mapping(uint256 => mapping(uint256 => uint256)) public strategyOracleData; // strategyId => oracleFeedId => latestDataValue

    // --- Protocol Parameters (configurable by governance/owner) ---
    uint256 public creationCost = 1e18;       // Default energy cost to create a strategy (1 ether equivalent of energyToken)
    uint256 public mutationCost = 0.1e18;     // Default energy cost to mutate an AS
    uint256 public breedingCost = 0.5e18;     // Default energy cost to breed two ASs
    uint256 public oracleRequestCost = 0.05e18; // Default energy cost for an oracle data request

    uint256 public globalMutationRate = 10; // Percentage, e.g., 10 for 10% chance per gene to mutate
    uint256 public mutationEnergyThreshold = 0.5e18; // Minimum energy balance required for a strategy to undergo mutation
    uint256 public minFitnessForBreeding = 500; // Minimum fitness score (out of 1000) required for a strategy to be eligible for breeding

    uint256 public minVotingPowerForProposal = 100e18; // Minimum `energyToken` balance required to create a proposal
    uint256 public proposalQuorum = 50; // Percentage of total `energyToken` voting power required for a proposal to pass (Yes Votes / Total Votes)

    // --- Interfaces ---

    // Simplified Oracle Interface (mimicking a common fulfill pattern, e.g., Chainlink)
    // In a real application, this would interact with a specific oracle contract.
    interface IOracle {
        function requestData(uint256 oracleFeedId, bytes calldata callbackData) external returns (bytes32 requestId);
        // The fulfillData function would typically be on a ChainlinkClient type contract
        // that then calls our EASFoundry.fulfillOracleData. For simplicity, we'll imagine
        // the oracle itself calls EASFoundry.fulfillOracleData directly after processing.
    }

    // --- Events ---
    event StrategyCreated(uint256 indexed strategyId, address indexed owner, uint256[] initialDNA, bytes32 logicTreeHash);
    event StrategyMutated(uint256 indexed strategyId, uint256 oldFitness, uint256 newFitness, uint256[] oldDNA, uint256[] newDNA);
    event StrategiesBred(uint256 indexed newStrategyId, uint256 indexed parent1Id, uint256 indexed parent2Id);
    event StrategyEnergyDeposited(uint256 indexed strategyId, address indexed depositor, uint256 amount);
    event StrategyEnergyWithdrawn(uint256 indexed strategyId, address indexed receiver, uint256 amount);
    event OracleDataRequested(uint256 indexed strategyId, uint256 indexed oracleFeedId, bytes32 requestId);
    event OracleDataFulfilled(uint256 indexed strategyId, uint256 indexed oracleFeedId, bytes32 requestId, bytes data);
    event FitnessScoreCalculated(uint256 indexed strategyId, uint256 oldScore, uint256 newScore);
    event ProtocolParameterSet(string indexed paramName, uint256 oldValue, uint256 newValue);
    event ProposalCreated(uint256 indexed proposalId, bytes32 proposalHash, uint256 proposerVotingPower, uint256 executionTimestamp);
    event VotedOnProposal(uint256 indexed proposalId, address indexed voter, bool support);
    event ProposalExecuted(uint256 indexed proposalId);
    event EmergencyPaused(address indexed by);
    event EmergencyUnpaused(address indexed by);

    // --- Error Definitions ---
    error StrategyNotFound(uint256 strategyId);
    error NotStrategyOwner(uint256 strategyId, address caller);
    error StrategyInactive(uint256 strategyId);
    error InsufficientEnergy(uint256 strategyId, uint256 required, uint256 available);
    error InvalidDNA(string message);
    error LogicHashNotAllowed(bytes32 logicHash);
    error GeneNotFound(uint256 geneId);
    error OracleFeedNotFound(uint256 oracleFeedId);
    error OracleFeedInactive(uint256 oracleFeedId);
    error NotRegisteredOracle(address caller);
    error InvalidOracleCallback(bytes32 requestId);
    error FitnessFunctionNotFound(uint256 functionId);
    error InsufficientVotingPower(uint256 required, uint256 available);
    error ProposalNotFound(uint256 proposalId);
    error AlreadyVoted(uint256 proposalId, address voter);
    error ProposalNotReadyForExecution(uint256 proposalId);
    error ProposalAlreadyExecuted(uint256 proposalId);
    error ProposalNotPassed(uint256 proposalId);
    error BreedingRequirementsNotMet(string reason);
    error MaxGeneLengthExceeded(uint256 currentLength, uint256 maxLength);
    error MinGeneLengthNotMet(uint256 currentLength, uint256 minLength);

    // --- Constructor ---
    /// @notice Initializes the contract with the address of the ERC20 token to be used as energy and voting power.
    /// @param _energyTokenAddress The address of the ERC20 token.
    constructor(address _energyTokenAddress) {
        energyToken = IERC20(_energyTokenAddress);
    }

    // --- Modifiers ---
    /// @dev Ensures the caller is the owner of the specified strategy.
    modifier onlyStrategyOwner(uint256 _strategyId) {
        if (_strategyIdCounter.current() == 0 || _strategyId >= _strategyIdCounter.current()) {
            revert StrategyNotFound(_strategyId);
        }
        if (strategies[_strategyId].owner != _msgSender()) {
            revert NotStrategyOwner(_strategyId, _msgSender());
        }
        _;
    }

    /// @dev Ensures the specified strategy is currently active.
    modifier onlyActiveStrategy(uint256 _strategyId) {
        if (_strategyIdCounter.current() == 0 || _strategyId >= _strategyIdCounter.current()) {
            revert StrategyNotFound(_strategyId);
        }
        if (!strategies[_strategyId].active) {
            revert StrategyInactive(_strategyId);
        }
        _;
    }

    /// @dev Ensures the caller is a registered oracle for the specified feed.
    modifier onlyRegisteredOracle(uint256 _oracleFeedId) {
        if (_oracleFeedIdCounter.current() == 0 || _oracleFeedId >= _oracleFeedIdCounter.current()) {
            revert OracleFeedNotFound(_oracleFeedId);
        }
        if (oracleFeeds[_oracleFeedId].oracleAddress != _msgSender()) {
            revert NotRegisteredOracle(_msgSender());
        }
        _;
    }

    /// @dev Ensures the provided logic hash has been whitelisted by the protocol owner.
    modifier onlyAllowedLogicHash(bytes32 _logicHash) {
        if (!allowedStrategyLogicHashes[_logicHash]) {
            revert LogicHashNotAllowed(_logicHash);
        }
        _;
    }

    // --- I. Core Strategy Management ---

    /// @notice Creates a new Algorithmic Strategy (AS) with initial DNA and an off-chain logic reference.
    ///         Requires `creationCost` in `energyToken` to be approved and transferred from the caller.
    /// @param initialDNA An array of uint256 representing the strategy's initial parameters, matching the global gene pool structure.
    /// @param logicTreeHash A bytes32 hash pointing to the strategy's detailed off-chain decision logic (e.g., IPFS CID).
    function createAlgorithmicStrategy(uint256[] calldata initialDNA, bytes32 logicTreeHash)
        external
        whenNotPaused
        onlyAllowedLogicHash(logicTreeHash)
    {
        if (energyToken.balanceOf(_msgSender()) < creationCost) {
            revert InsufficientEnergy(0, creationCost, energyToken.balanceOf(_msgSender()));
        }
        // Validate DNA length against the current global gene pool size
        if (_geneIdCounter.current() == 0) {
            revert InvalidDNA("Global gene pool not yet defined. Cannot create strategy.");
        }
        if (initialDNA.length != _geneIdCounter.current()) {
            revert InvalidDNA("Initial DNA length must match global gene pool size.");
        }

        // Validate DNA parameters against global gene pool's min/max ranges
        for (uint256 i = 0; i < initialDNA.length; i++) {
            EvolutionGene storage gene = globalGenePool[i + 1]; // Gene IDs start from 1
            if (initialDNA[i] < gene.minVal || initialDNA[i] > gene.maxVal) {
                revert InvalidDNA("Initial DNA parameter out of gene's defined range.");
            }
        }

        uint256 newStrategyId = _strategyIdCounter.current();
        _strategyIdCounter.increment();

        require(energyToken.transferFrom(_msgSender(), address(this), creationCost), "Energy token transfer failed for creation cost");

        strategies[newStrategyId] = AlgorithmicStrategy({
            id: newStrategyId,
            owner: _msgSender(),
            parentIds: new uint256[](0), // No parents for a newly created strategy
            creationBlock: block.number,
            lastEvolutionBlock: block.number,
            energyBalance: 0, // Energy cost is paid to the contract directly, not into strategy balance
            dnaParameters: initialDNA,
            logicTreeHash: logicTreeHash,
            fitnessScore: 0, // Initial fitness is zero, needs calculation
            mutationThreshold: globalMutationRate, // Initialize with global rate
            active: true,
            lastOracleDataTimestamp: 0,
            lastOracleDataHash: bytes32(0)
        });

        emit StrategyCreated(newStrategyId, _msgSender(), initialDNA, logicTreeHash);
    }

    /// @notice Triggers an evolutionary mutation for a specific AS, consuming `mutationCost` energy.
    ///         The mutation process is pseudorandom and applies to genes marked as mutable within the global gene pool.
    /// @dev This function uses `block.timestamp`, `block.difficulty`, and `msg.sender` for pseudorandomness, which is NOT cryptographically secure
    ///      and should not be used for high-value operations requiring true randomness. For production, Chainlink VRF or similar is recommended.
    /// @param _strategyId The ID of the strategy to mutate.
    function mutateAlgorithmicStrategy(uint256 _strategyId)
        external
        whenNotPaused
        onlyStrategyOwner(_strategyId)
        onlyActiveStrategy(_strategyId)
    {
        AlgorithmicStrategy storage strategy = strategies[_strategyId];
        if (strategy.energyBalance < mutationCost) {
            revert InsufficientEnergy(_strategyId, mutationCost, strategy.energyBalance);
        }
        if (strategy.energyBalance < mutationEnergyThreshold) {
            revert InsufficientEnergy(_strategyId, mutationEnergyThreshold, strategy.energyBalance);
        }

        uint256 oldFitness = strategy.fitnessScore;
        uint256[] memory oldDNA = new uint256[](strategy.dnaParameters.length);
        for(uint256 i=0; i < strategy.dnaParameters.length; i++) {
            oldDNA[i] = strategy.dnaParameters[i];
        }

        strategy.energyBalance = strategy.energyBalance.sub(mutationCost);

        // Pseudorandom mutation (NOT cryptographically secure for real applications)
        uint256 seed = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, _msgSender(), _strategyId)));

        for (uint256 i = 0; i < strategy.dnaParameters.length; i++) {
            EvolutionGene storage gene = globalGenePool[i + 1]; // Gene IDs start from 1
            if (gene.isMutable) {
                // Use a different part of the seed for each gene for better distribution
                uint256 geneSeed = uint256(keccak256(abi.encodePacked(seed, i)));
                if ((geneSeed % 100) < strategy.mutationThreshold) { // Check against strategy's mutation threshold
                    // Calculate a random value within the gene's range, respecting its step
                    uint256 range = gene.maxVal.sub(gene.minVal);
                    uint256 numSteps = range.div(gene.step).add(1); // Including min/max
                    uint256 randomStepCount = geneSeed % numSteps;
                    strategy.dnaParameters[i] = gene.minVal.add(randomStepCount.mul(gene.step));
                }
            }
        }

        strategy.lastEvolutionBlock = block.number;
        strategy.fitnessScore = 0; // Reset fitness, requires recalculation after mutation

        emit StrategyMutated(_strategyId, oldFitness, strategy.fitnessScore, oldDNA, strategy.dnaParameters);
    }

    /// @notice Creates a new AS by combining the DNA of two parent strategies, consuming `breedingCost` energy.
    ///         The new strategy inherits DNA parameters through a simplified crossover process.
    /// @param parent1Id The ID of the first parent strategy.
    /// @param parent2Id The ID of the second parent strategy.
    /// @param newLogicTreeHash A bytes32 hash for the new strategy's off-chain logic.
    function breedAlgorithmicStrategies(uint256 parent1Id, uint256 parent2Id, bytes32 newLogicTreeHash)
        external
        whenNotPaused
        onlyAllowedLogicHash(newLogicTreeHash)
    {
        AlgorithmicStrategy storage parent1 = strategies[parent1Id];
        AlgorithmicStrategy storage parent2 = strategies[parent2Id];

        // Caller must own at least one of the parents to initiate breeding
        if (parent1.owner != _msgSender() && parent2.owner != _msgSender()) {
            revert NotStrategyOwner(parent1Id, _msgSender()); // Reverts if caller is neither parent1 owner nor parent2 owner
        }
        if (!parent1.active) {
            revert StrategyInactive(parent1Id);
        }
        if (!parent2.active) {
            revert StrategyInactive(parent2Id);
        }
        if (parent1.fitnessScore < minFitnessForBreeding || parent2.fitnessScore < minFitnessForBreeding) {
            revert BreedingRequirementsNotMet("Both parents must meet minimum fitness for breeding.");
        }
        if (energyToken.balanceOf(_msgSender()) < breedingCost) {
            revert InsufficientEnergy(0, breedingCost, energyToken.balanceOf(_msgSender()));
        }
        if (parent1.dnaParameters.length != parent2.dnaParameters.length) {
            revert InvalidDNA("Parent strategies must have DNA of the same length to breed.");
        }
        if (parent1.dnaParameters.length != _geneIdCounter.current()) {
            revert InvalidDNA("Parent DNA length does not match global gene pool size.");
        }

        uint256 newStrategyId = _strategyIdCounter.current();
        _strategyIdCounter.increment();

        require(energyToken.transferFrom(_msgSender(), address(this), breedingCost), "Energy token transfer failed for breeding cost");

        uint256[] memory newDNA = new uint256[](parent1.dnaParameters.length);
        uint256 seed = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, _msgSender(), parent1Id, parent2Id)));

        for (uint256 i = 0; i < parent1.dnaParameters.length; i++) {
            // Crossover logic: pseudorandomly pick gene from parent1 or parent2
            // For production, use Chainlink VRF for secure randomness
            if ((seed % 2) == 0) {
                newDNA[i] = parent1.dnaParameters[i];
            } else {
                newDNA[i] = parent2.dnaParameters[i];
            }
            seed = uint256(keccak256(abi.encodePacked(seed, i))); // Update seed for next gene
        }

        strategies[newStrategyId] = AlgorithmicStrategy({
            id: newStrategyId,
            owner: _msgSender(),
            parentIds: new uint256[](2), // Store references to both parents
            creationBlock: block.number,
            lastEvolutionBlock: block.number,
            energyBalance: 0, // Breeding cost is paid to the contract
            dnaParameters: newDNA,
            logicTreeHash: newLogicTreeHash,
            fitnessScore: 0, // New strategy's fitness needs to be calculated
            mutationThreshold: globalMutationRate,
            active: true,
            lastOracleDataTimestamp: 0,
            lastOracleDataHash: bytes32(0)
        });
        strategies[newStrategyId].parentIds[0] = parent1Id;
        strategies[newStrategyId].parentIds[1] = parent2Id;

        emit StrategiesBred(newStrategyId, parent1Id, parent2Id);
    }

    /// @notice Allows an AS owner to update the reference to their strategy's off-chain decision logic.
    ///         The new logic hash must be whitelisted by the protocol owner.
    /// @param _strategyId The ID of the strategy to update.
    /// @param _newLogicTreeHash The new bytes32 hash pointing to the updated off-chain logic.
    function updateStrategyLogicHash(uint256 _strategyId, bytes32 _newLogicTreeHash)
        external
        whenNotPaused
        onlyStrategyOwner(_strategyId)
        onlyAllowedLogicHash(_newLogicTreeHash)
    {
        AlgorithmicStrategy storage strategy = strategies[_strategyId];
        strategy.logicTreeHash = _newLogicTreeHash;
    }

    /// @notice Deactivates an AS, preventing further operations like mutation, breeding, or data requests.
    ///         This can be done by the strategy owner.
    /// @param _strategyId The ID of the strategy to deactivate.
    function deactivateStrategy(uint256 _strategyId) external onlyStrategyOwner(_strategyId) {
        strategies[_strategyId].active = false;
    }

    /// @notice Reactivates a previously deactivated AS, allowing it to resume operations.
    ///         This can be done by the strategy owner.
    /// @param _strategyId The ID of the strategy to activate.
    function activateStrategy(uint256 _strategyId) external onlyStrategyOwner(_strategyId) {
        strategies[_strategyId].active = true;
    }

    /// @notice View function to retrieve all detailed information about an Algorithmic Strategy.
    /// @param _strategyId The ID of the strategy.
    /// @return A tuple containing all strategy details.
    function getStrategyDetails(uint256 _strategyId)
        external
        view
        returns (AlgorithmicStrategy memory)
    {
        if (_strategyIdCounter.current() == 0 || _strategyId >= _strategyIdCounter.current()) {
            revert StrategyNotFound(_strategyId);
        }
        return strategies[_strategyId];
    }

    // --- II. Energy/Resource Management ---

    /// @notice Allows users to deposit `energyToken` into an AS, fueling its operations.
    ///         The `energyToken` is transferred from the caller to the EASFoundry contract's balance for the specific strategy.
    /// @param _strategyId The ID of the strategy to deposit energy into.
    /// @param _amount The amount of `energyToken` to deposit.
    function depositEnergy(uint256 _strategyId, uint256 _amount)
        external
        whenNotPaused
        onlyActiveStrategy(_strategyId) // Only active strategies can receive energy
    {
        if (_strategyIdCounter.current() == 0 || _strategyId >= _strategyIdCounter.current()) {
            revert StrategyNotFound(_strategyId);
        }
        require(energyToken.transferFrom(_msgSender(), address(this), _amount), "Energy token transfer failed");
        strategies[_strategyId].energyBalance = strategies[_strategyId].energyBalance.add(_amount);
        emit StrategyEnergyDeposited(_strategyId, _msgSender(), _amount);
    }

    /// @notice Allows the owner of an AS to withdraw unused `energyToken` from their strategy's balance.
    /// @param _strategyId The ID of the strategy to withdraw energy from.
    /// @param _amount The amount of `energyToken` to withdraw.
    function withdrawEnergy(uint256 _strategyId, uint256 _amount)
        external
        whenNotPaused
        onlyStrategyOwner(_strategyId)
    {
        AlgorithmicStrategy storage strategy = strategies[_strategyId];
        if (strategy.energyBalance < _amount) {
            revert InsufficientEnergy(_strategyId, _amount, strategy.energyBalance);
        }
        strategy.energyBalance = strategy.energyBalance.sub(_amount);
        require(energyToken.transfer(_msgSender(), _amount), "Energy token transfer failed during withdrawal");
        emit StrategyEnergyWithdrawn(_strategyId, _msgSender(), _amount);
    }

    /// @notice Sets the costs for various protocol operations (creation, mutation, breeding, oracle requests) in `energyToken`.
    ///         Callable only by the contract owner.
    /// @param _creationCost Cost to create a strategy.
    /// @param _mutationCost Cost to mutate a strategy.
    /// @param _breedingCost Cost to breed strategies.
    /// @param _oracleRequestCost Cost to request oracle data.
    function setEnergyConsumptionRates(uint256 _creationCost, uint256 _mutationCost, uint256 _breedingCost, uint256 _oracleRequestCost)
        external
        onlyOwner
        whenNotPaused
    {
        creationCost = _creationCost;
        mutationCost = _mutationCost;
        breedingCost = _breedingCost;
        oracleRequestCost = _oracleRequestCost;
        emit ProtocolParameterSet("creationCost", creationCost, _creationCost);
        emit ProtocolParameterSet("mutationCost", mutationCost, _mutationCost);
        emit ProtocolParameterSet("breedingCost", breedingCost, _breedingCost);
        emit ProtocolParameterSet("oracleRequestCost", oracleRequestCost, _oracleRequestCost);
    }

    /// @notice View function to check the current `energyToken` balance of a specific AS.
    /// @param _strategyId The ID of the strategy.
    /// @return The `energyToken` balance held for that strategy.
    function getEnergyBalance(uint256 _strategyId) external view returns (uint256) {
        if (_strategyIdCounter.current() == 0 || _strategyId >= _strategyIdCounter.current()) {
            revert StrategyNotFound(_strategyId);
        }
        return strategies[_strategyId].energyBalance;
    }

    // --- III. Oracle/Data Integration ---

    /// @notice Initiates a request for external data from a registered oracle for a specific AS, consuming `oracleRequestCost` energy.
    ///         The actual request is delegated to the external `IOracle` contract.
    /// @param _strategyId The ID of the strategy needing data.
    /// @param _oracleFeedId The ID of the registered oracle feed to request data from.
    /// @param _callbackData Any additional data required by the oracle for processing the request.
    function requestOracleDataForStrategy(uint256 _strategyId, uint256 _oracleFeedId, bytes calldata _callbackData)
        external
        whenNotPaused
        onlyStrategyOwner(_strategyId)
        onlyActiveStrategy(_strategyId)
    {
        AlgorithmicStrategy storage strategy = strategies[_strategyId];
        OracleFeed storage feed = oracleFeeds[_oracleFeedId];

        if (_oracleFeedIdCounter.current() == 0 || _oracleFeedId >= _oracleFeedIdCounter.current()) {
            revert OracleFeedNotFound(_oracleFeedId);
        }
        if (!feed.isActive) {
            revert OracleFeedInactive(_oracleFeedId);
        }
        if (strategy.energyBalance < oracleRequestCost) {
            revert InsufficientEnergy(_strategyId, oracleRequestCost, strategy.energyBalance);
        }

        strategy.energyBalance = strategy.energyBalance.sub(oracleRequestCost);
        
        // This simulates requesting data by calling the external IOracle contract.
        bytes32 requestId = IOracle(feed.oracleAddress).requestData(_oracleFeedId, _callbackData);
        feed.pendingRequests[requestId] = true; // Mark this request as pending

        emit OracleDataRequested(_strategyId, _oracleFeedId, requestId);
    }

    /// @notice Callback function used by registered oracles to deliver requested data.
    ///         This function updates the strategy's internal data, making it available for fitness calculation.
    /// @dev This function is expected to be called by the `oracleAddress` registered for the `_oracleFeedId`.
    /// @param _strategyId The ID of the strategy that originally requested the data.
    /// @param _oracleFeedId The ID of the oracle feed that provided the data.
    /// @param _requestId The ID of the original request, to verify against pending requests.
    /// @param _data The actual data returned by the oracle (e.g., an encoded uint256 or other relevant bytes).
    function fulfillOracleData(uint256 _strategyId, uint256 _oracleFeedId, bytes32 _requestId, bytes calldata _data)
        external
        whenNotPaused
        onlyRegisteredOracle(_oracleFeedId) // Only the registered oracle for this feed can fulfill requests
    {
        OracleFeed storage feed = oracleFeeds[_oracleFeedId];
        AlgorithmicStrategy storage strategy = strategies[_strategyId];

        if (_strategyIdCounter.current() == 0 || _strategyId >= _strategyIdCounter.current()) {
            revert StrategyNotFound(_strategyId);
        }
        if (!feed.pendingRequests[_requestId]) {
            revert InvalidOracleCallback(_requestId); // Request ID not found or already fulfilled
        }
        
        feed.pendingRequests[_requestId] = false; // Mark request as fulfilled

        // For simplicity, we assume _data encodes a single uint256 price/value.
        // In a real application, parsing of `_data` would be more complex depending on the oracle's output.
        uint256 dataValue = abi.decode(_data, (uint256));
        strategyOracleData[_strategyId][_oracleFeedId] = dataValue; // Store the latest data value
        strategy.lastOracleDataTimestamp = block.timestamp;
        strategy.lastOracleDataHash = keccak256(_data); // Store data hash to detect changes and prevent replay attacks on fitness calculation

        emit OracleDataFulfilled(_strategyId, _oracleFeedId, _requestId, _data);
    }

    /// @notice Protocol owner registers a new trusted oracle address and its unique identifier for data feeds.
    /// @param _oracleAddress The address of the external oracle contract that will provide data for this feed.
    /// @param _feedIdentifier A unique bytes32 identifier for the specific data feed (e.g., `keccak256("ETH/USD-Price")`).
    function registerOracleFeed(address _oracleAddress, bytes32 _feedIdentifier)
        external
        onlyOwner
        whenNotPaused
    {
        uint256 newFeedId = _oracleFeedIdCounter.current();
        _oracleFeedIdCounter.increment();

        oracleFeeds[newFeedId] = OracleFeed({
            id: newFeedId,
            oracleAddress: _oracleAddress,
            feedIdentifier: _feedIdentifier,
            isActive: true,
            pendingRequests: new mapping(bytes32 => bool)() // Initialize empty mapping
        });
    }

    /// @notice Protocol owner can activate or deactivate registered oracle feeds.
    ///         Deactivating a feed prevents new requests but does not affect past fulfillments.
    /// @param _oracleFeedId The ID of the oracle feed to update.
    /// @param _isActive The new active status (true to activate, false to deactivate).
    function updateOracleFeedStatus(uint256 _oracleFeedId, bool _isActive)
        external
        onlyOwner
        whenNotPaused
    {
        if (_oracleFeedIdCounter.current() == 0 || _oracleFeedId >= _oracleFeedIdCounter.current()) {
            revert OracleFeedNotFound(_oracleFeedId);
        }
        oracleFeeds[_oracleFeedId].isActive = _isActive;
    }

    // --- IV. Evolution & Fitness Management ---

    /// @notice Sets global parameters that govern how strategies evolve, callable by the protocol owner.
    /// @param _globalMutationRate The percentage chance (0-100) for a mutable gene to mutate during an evolution step.
    /// @param _mutationEnergyThreshold The minimum energy an AS needs in its balance to perform a mutation.
    /// @param _minFitnessForBreeding The minimum fitness score (out of 1000) required for a strategy to be eligible for breeding.
    function setEvolutionParameters(uint256 _globalMutationRate, uint256 _mutationEnergyThreshold, uint256 _minFitnessForBreeding)
        external
        onlyOwner
        whenNotPaused
    {
        require(_globalMutationRate <= 100, "Mutation rate cannot exceed 100%");
        globalMutationRate = _globalMutationRate;
        mutationEnergyThreshold = _mutationEnergyThreshold;
        minFitnessForBreeding = _minFitnessForBreeding;

        emit ProtocolParameterSet("globalMutationRate", globalMutationRate, _globalMutationRate);
        emit ProtocolParameterSet("mutationEnergyThreshold", mutationEnergyThreshold, _mutationEnergyThreshold);
        emit ProtocolParameterSet("minFitnessForBreeding", minFitnessForBreeding, _minFitnessForBreeding);
    }

    /// @notice Triggers an on-chain calculation of a strategy's fitness based on its DNA, recent oracle data, and defined fitness functions.
    ///         The fitness score influences breeding eligibility and reflects strategy performance.
    /// @dev This is a simplified fitness calculation. Real-world "AI" strategy evaluation would involve far more complex
    ///      off-chain computation, potentially with on-chain verification (e.g., ZK-proofs) or a simplified proxy.
    /// @param _strategyId The ID of the strategy to calculate fitness for.
    function calculateFitnessScore(uint256 _strategyId)
        external
        whenNotPaused
        onlyStrategyOwner(_strategyId)
        onlyActiveStrategy(_strategyId)
    {
        AlgorithmicStrategy storage strategy = strategies[_strategyId];
        uint256 oldScore = strategy.fitnessScore;
        uint256 totalWeightedScore = 0;
        uint256 totalWeight = 0;

        // Ensure there's at least some oracle data available for calculation
        if (strategy.lastOracleDataTimestamp == 0) {
            // Can decide to revert, or return 0, or calculate with existing (possibly old) data.
            // For now, if no data, fitness remains 0.
            strategy.fitnessScore = 0;
            emit FitnessScoreCalculated(_strategyId, oldScore, 0);
            return;
        }

        // Iterate through all active fitness functions and apply their logic
        for (uint256 i = 0; i < _fitnessFunctionIdCounter.current(); i++) {
            uint256 funcId = i + 1; // Fitness function IDs start from 1
            FitnessFunction storage ff = fitnessFunctions[funcId];

            if (ff.isActive) {
                uint256 oracleData = strategyOracleData[_strategyId][ff.oracleFeedId];
                
                // Example simplified fitness logic: Multiply oracle data by a specific DNA parameter and the function's weight.
                // This is a placeholder; real logic could be far more intricate.
                uint256 dnaParamForFitness = strategy.dnaParameters.length > 0 ? strategy.dnaParameters[0] : 1; // Use first DNA param as a multiplier
                
                // Scale values to avoid overflow for large multiplications, and then normalize for the final score.
                // Assuming oracleData and dnaParamForFitness are not excessively large for uint256 operations.
                uint256 scoreContribution = oracleData.mul(dnaParamForFitness).div(1e6).mul(ff.weight); // Example scaling
                totalWeightedScore = totalWeightedScore.add(scoreContribution);
                totalWeight = totalWeight.add(ff.weight);
            }
        }

        uint256 newScore = 0;
        if (totalWeight > 0) {
            // Normalize the total weighted score to a range (e.g., 0-1000)
            newScore = totalWeightedScore.div(totalWeight).div(1e12); // Further example scaling to fit within 0-1000
            if (newScore > 1000) newScore = 1000; // Cap at max fitness
        }
        
        strategy.fitnessScore = newScore;
        emit FitnessScoreCalculated(_strategyId, oldScore, newScore);
    }

    /// @notice Protocol owner defines a new method for evaluating strategy performance.
    /// @param _name A descriptive name for the fitness function (e.g., "ProfitabilityScore").
    /// @param _oracleFeedId The ID of the oracle feed this function primarily relies on for data.
    /// @param _weight The weighting of this function in the overall fitness calculation (e.g., 1-100).
    /// @param _calculationLogicHash A bytes32 hash referencing off-chain logic for this fitness calculation (e.g., a specific algorithm document).
    function defineFitnessFunction(string calldata _name, uint256 _oracleFeedId, uint256 _weight, bytes32 _calculationLogicHash)
        external
        onlyOwner
        whenNotPaused
        // Optionally, one could add onlyAllowedLogicHash(_calculationLogicHash) if specific fitness calculation logic also needs whitelisting.
    {
        if (_oracleFeedIdCounter.current() == 0 || _oracleFeedId >= _oracleFeedIdCounter.current()) {
            revert OracleFeedNotFound(_oracleFeedId);
        }
        uint256 newFuncId = _fitnessFunctionIdCounter.current();
        _fitnessFunctionIdCounter.increment();

        fitnessFunctions[newFuncId] = FitnessFunction({
            id: newFuncId,
            name: _name,
            oracleFeedId: _oracleFeedId,
            weight: _weight,
            calculationLogicHash: _calculationLogicHash,
            isActive: true
        });
    }

    /// @notice Protocol owner adjusts the weighting of an existing fitness function in the overall fitness score calculation.
    /// @param _fitnessFunctionId The ID of the fitness function to update.
    /// @param _newWeight The new weight (e.g., 1-100) for the function.
    function updateFitnessFunctionWeight(uint256 _fitnessFunctionId, uint256 _newWeight)
        external
        onlyOwner
        whenNotPaused
    {
        if (_fitnessFunctionIdCounter.current() == 0 || _fitnessFunctionId >= _fitnessFunctionIdCounter.current()) {
            revert FitnessFunctionNotFound(_fitnessFunctionId);
        }
        fitnessFunctions[_fitnessFunctionId].weight = _newWeight;
    }

    // --- V. Governance & Protocol Settings ---

    /// @notice Allows users with sufficient `energyToken` voting power to propose system-wide upgrades or parameter changes.
    ///         Proposals reference off-chain details via a hash and specify an execution timestamp.
    /// @param _proposalHash IPFS hash or similar reference to the proposal details (e.g., a markdown file describing changes).
    /// @param _executionTimestamp The timestamp after which the proposal can be executed if it passes.
    function proposeProtocolUpgrade(bytes32 _proposalHash, uint256 _executionTimestamp)
        external
        whenNotPaused
    {
        uint256 proposerVotingPower = energyToken.balanceOf(_msgSender());
        if (proposerVotingPower < minVotingPowerForProposal) {
            revert InsufficientVotingPower(minVotingPowerForProposal, proposerVotingPower);
        }

        uint256 newProposalId = _proposalIdCounter.current();
        _proposalIdCounter.increment();

        proposals[newProposalId] = Proposal({
            id: newProposalId,
            proposalHash: _proposalHash,
            proposerVotingPower: proposerVotingPower, // Snapshot proposer's voting power
            executionTimestamp: _executionTimestamp,
            yesVotes: 0,
            noVotes: 0,
            executed: false
        });

        emit ProposalCreated(newProposalId, _proposalHash, proposerVotingPower, _executionTimestamp);
    }

    /// @notice Allows users with `energyToken` voting power to cast their vote (yes/no) on an active proposal.
    ///         Voting power is determined by the caller's current `energyToken` balance at the time of voting.
    /// @param _proposalId The ID of the proposal to vote on.
    /// @param _support True for a 'yes' vote (in favor), false for a 'no' vote (against).
    function voteOnProposal(uint256 _proposalId, bool _support)
        external
        whenNotPaused
    {
        if (_proposalIdCounter.current() == 0 || _proposalId >= _proposalIdCounter.current()) {
            revert ProposalNotFound(_proposalId);
        }
        Proposal storage proposal = proposals[_proposalId];

        if (proposal.executed) {
            revert ProposalAlreadyExecuted(_proposalId);
        }
        if (hasVoted[_proposalId][_msgSender()]) {
            revert AlreadyVoted(_proposalId, _msgSender());
        }

        uint256 voterVotingPower = energyToken.balanceOf(_msgSender()); // Snapshot current balance as voting power
        require(voterVotingPower > 0, "Voter must hold energy tokens to vote");

        if (_support) {
            proposal.yesVotes = proposal.yesVotes.add(voterVotingPower);
        } else {
            proposal.noVotes = proposal.noVotes.add(voterVotingPower);
        }
        hasVoted[_proposalId][_msgSender()] = true;

        emit VotedOnProposal(_proposalId, _msgSender(), _support);
    }

    /// @notice Executes an approved and passed proposal after its designated execution timestamp.
    ///         For this simplified example, execution means marking the proposal as done. In a full DAO,
    ///         this would involve a Timelock contract dispatching actual function calls.
    /// @dev Callable by the `owner` of this contract. A more robust DAO would have a different execution model.
    /// @param _proposalId The ID of the proposal to execute.
    function executeProposal(uint256 _proposalId)
        external
        whenNotPaused
        onlyOwner // Simplified: Only the owner can trigger execution. A real DAO would use a Timelock/Executor.
    {
        if (_proposalIdCounter.current() == 0 || _proposalId >= _proposalIdCounter.current()) {
            revert ProposalNotFound(_proposalId);
        }
        Proposal storage proposal = proposals[_proposalId];

        if (proposal.executed) {
            revert ProposalAlreadyExecuted(_proposalId);
        }
        if (block.timestamp < proposal.executionTimestamp) {
            revert ProposalNotReadyForExecution(_proposalId);
        }

        uint256 totalVotes = proposal.yesVotes.add(proposal.noVotes);
        // Simplified quorum check: percentage of total votes, not total supply
        // For a true DAO, totalVotingPower would be energyToken.totalSupply() or historical snapshot.
        if (totalVotes == 0 || (proposal.yesVotes.mul(100).div(totalVotes) <= proposalQuorum)) {
            revert ProposalNotPassed(_proposalId); // Not enough 'yes' votes relative to total votes cast.
        }
        
        // --- DUMMY EXECUTION LOGIC ---
        // In a fully decentralized DAO, this section would contain the actual code to apply
        // the proposed changes (e.g., calling setEnergyConsumptionRates, setEvolutionParameters,
        // or triggering an upgrade via a proxy contract).
        // For this demonstration, we simply mark the proposal as executed.
        proposal.executed = true;

        emit ProposalExecuted(_proposalId);
    }

    /// @notice Protocol owner defines the global set of mutable "genes" (parameters) that strategies can possess.
    ///         This sets the structure and constraints for the `dnaParameters` array of all ASs.
    /// @dev This function effectively resets and redefines the entire global gene pool.
    /// @param _geneIds Array of gene IDs (must be sequential starting from 1).
    /// @param _geneNames Array of names for each gene.
    /// @param _minVals Array of minimum allowed values for each gene.
    /// @param _maxVals Array of maximum allowed values for each gene.
    /// @param _steps Array of step increments for mutations for each gene.
    /// @param _isMutableFlags Array of booleans indicating if a gene can mutate during the `mutateAlgorithmicStrategy` process.
    function setCoreGenePool(uint256[] calldata _geneIds, string[] calldata _geneNames, uint256[] calldata _minVals, uint256[] calldata _maxVals, uint256[] calldata _steps, bool[] calldata _isMutableFlags)
        external
        onlyOwner
        whenNotPaused
    {
        require(_geneIds.length == _geneNames.length &&
                _geneIds.length == _minVals.length &&
                _geneIds.length == _maxVals.length &&
                _geneIds.length == _steps.length &&
                _geneIds.length == _isMutableFlags.length, "All gene arrays must have the same length");

        if (_geneIds.length > 32) { // Arbitrary maximum length for DNA to keep it manageable on-chain
            revert MaxGeneLengthExceeded(_geneIds.length, 32);
        }
        if (_geneIds.length == 0) {
            revert MinGeneLengthNotMet(0, 1);
        }

        // Clear existing gene pool before setting a new one
        // Note: This operation assumes that existing strategies will still function with the new gene definitions.
        // In a production system, a gene pool change might require strategy migration or versioning.
        _geneIdCounter._value = 0; // Reset counter for new gene IDs

        for (uint256 i = 0; i < _geneIds.length; i++) {
            require(_geneIds[i] == i + 1, "Gene IDs must be sequential starting from 1");
            require(_minVals[i] < _maxVals[i], "Min value must be less than max value for gene ID");
            require(_steps[i] > 0, "Step must be greater than 0 for gene ID");
            
            // Check if max value is reachable from min value by steps
            require((_maxVals[i].sub(_minVals[i])).div(_steps[i]).mul(_steps[i]).add(_minVals[i]) <= _maxVals[i], "Max value for gene ID not reachable by steps from min value");

            uint256 newGeneId = _geneIdCounter.current().add(1); // Calculate the new gene ID
            _geneIdCounter.increment(); // Increment the counter for the next gene

            globalGenePool[newGeneId] = EvolutionGene({
                id: newGeneId,
                name: _geneNames[i],
                minVal: _minVals[i],
                maxVal: _maxVals[i],
                step: _steps[i],
                isMutable: _isMutableFlags[i]
            });
        }
    }

    /// @notice Protocol owner whitelists a specific strategy logic hash, ensuring only approved off-chain logic can be referenced by ASs.
    ///         This prevents strategies from being created or updated with unapproved or malicious off-chain execution logic.
    /// @param _logicHash The bytes32 hash of the off-chain logic to whitelist (e.g., an IPFS CID).
    function addAllowedStrategyLogicHash(bytes32 _logicHash)
        external
        onlyOwner
        whenNotPaused
    {
        allowedStrategyLogicHashes[_logicHash] = true;
    }

    /// @notice Allows the contract owner to pause critical functions in case of an emergency (inherited from Pausable).
    ///         This halts operations like strategy creation, mutation, breeding, energy deposits, and oracle requests.
    function emergencyPause() external onlyOwner {
        _pause();
        emit EmergencyPaused(_msgSender());
    }

    /// @notice Allows the contract owner to unpause critical functions (inherited from Pausable).
    ///         Resumes normal contract operations after an emergency pause.
    function unpause() external onlyOwner {
        _unpause();
        emit EmergencyUnpaused(_msgSender());
    }
}
```