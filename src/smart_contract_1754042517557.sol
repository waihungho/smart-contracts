This smart contract, named `Ecosynapse`, represents a unique approach to decentralized digital ecosystems. It leverages several advanced Solidity concepts and aims to be distinct from common open-source implementations by combining dynamic NFTs, oracle-driven evolution, gamified community contributions, and a novel micro-governance system.

---

### **OUTLINE & FUNCTION SUMMARY**

**Contract Name:** `Ecosynapse`

**Core Idea:**
`Ecosynapse` is a sophisticated, dynamic ERC721 NFT that represents a shared, evolving digital ecosystem. Its internal state (parameters like complexity, resilience, sentience) and external representation (metadata URI) dynamically adapt based on collective community contributions (nourishment, attuned actions), external "environmental data" provided by trusted oracles (simulating AI analysis or real-world events), and community-driven "evolutionary directives" voted upon by participants. The contract aims to create a self-sustaining and ever-growing digital entity, gamifying community engagement and leveraging advanced concepts like dynamic NFTs, oracle integration, and micro-governance for ecosystem evolution.

**Functions Summary:**

**I. Core Ecosystem & NFT Management:**
1.  **`constructor()`**: Initializes the ERC721 contract, mints the unique Ecosynapse NFT (ID 1), and sets initial ecosystem parameters and access roles.
2.  **`ecosystemURI()`**: Returns the dynamically generated metadata URI for the Ecosynapse NFT based on its current on-chain state (health, complexity, etc.).
3.  **`getEcosystemState()`**: Provides a summarized view of the core ecosystem's current health, complexity, resilience, and sentience level.
4.  **`tokenURI(uint256 tokenId)`**: Overrides ERC721's `tokenURI` to ensure the main ecosystem NFT (ID 1) points to its dynamic `ecosystemURI`.
5.  **`setBaseURI(string memory newBaseURI)`**: (Governance) Allows the designated governance entity to update the base URL for the NFT's metadata rendering.

**II. Community Engagement & Contributions:**
6.  **`nourishEcosystem()`**: Allows users to contribute native currency (e.g., ETH) to the ecosystem's treasury, which serves as its "nourishment" and fuels its growth.
7.  **`registerAttunedAction(bytes32 actionHash, string memory description)`**: Enables users to register verifiable off-chain actions (e.g., contributing data, positive social engagement) by providing a unique hash and description. This increases their "Affinity Score."
8.  **`claimAffinityReward()`**: Allows users to claim periodic rewards from the ecosystem's treasury, proportional to their accumulated "Affinity Score" and the ecosystem's overall growth.
9.  **`delegateAffinity(address delegatee)`**: Permits users to delegate their voting power and contribution impact (Affinity Score) to another address.
10. **`undelegateAffinity()`**: Revokes an existing affinity delegation.

**III. Dynamic Evolution & Oracle Integration:**
11. **`updateEnvironmentalData(bytes32 dataHash, uint256 timestamp)`**: (Oracle-only) An authorized oracle submits a hash representing recent external environmental data or AI-generated insights, queuing it for impact.
12. **`processEnvironmentalImpact(bytes memory oracleSignedData, uint256 dataTimestamp, bytes memory proof)`**: (Oracle-only) The oracle provides signed data and an optional proof (e.g., a ZKP) to directly influence the ecosystem's parameters based on complex external analysis.
13. **`evolveEcosystem()`**: A publicly callable function that triggers a major evolution cycle for the Ecosynapse. It calculates new ecosystem parameters based on accumulated nourishment, attuned actions, and oracle data, rewarding the caller for initiating the process.
14. **`triggerMetabolicPulse()`**: Simulates a periodic "metabolic cost" for the ecosystem. If nourishment is low, the ecosystem's health may decline, simulating natural decay.
15. **`setEvolutionCoefficients(uint256 nourishCoeff, uint256 actionCoeff, uint256 oracleCoeff)`**: (Governance) Allows adjustment of the weighting coefficients that determine how much each factor (nourishment, actions, oracle data) influences the ecosystem's evolution during the `evolveEcosystem` cycle.

**IV. Governance & Resource Management:**
16. **`proposeEvolutionDirective(string memory description, bytes memory callData, address target)`**: Users with sufficient "Affinity Score" can propose "Evolution Directives," which are essentially on-chain proposals for specific changes to the ecosystem or its treasury.
17. **`voteOnDirective(uint256 directiveId, bool support)`**: Users cast their vote (yes/no) on an open directive using their accumulated (or delegated) "Affinity Score."
18. **`executeDirective(uint256 directiveId)`**: Executes a directive that has successfully passed its voting period, meeting quorum and majority requirements.
19. **`allocateTreasuryFunds(address recipient, uint256 amount, string memory reason)`**: (Governance) Allows the governance entity to allocate native currency funds from the ecosystem's treasury for specified purposes.
20. **`governedWithdrawal(address tokenAddress, address recipient, uint256 amount)`**: (Governance) Provides a secure mechanism for the governance entity to withdraw specific ERC20 tokens from the contract's treasury, typically for managing accidentally sent tokens or approved asset transfers.

**V. Query & Utility Functions:**
21. **`getAffinityScore(address user)`**: Returns a user's current effective "Affinity Score," including any delegated affinity.
22. **`getDirective(uint256 directiveId)`**: Retrieves detailed information about a specific evolution directive, including its status and voting results.
23. **`getLatestEcosystemParameters()`**: Returns the raw, unsummarized current values of all core ecosystem parameters.
24. **`getPendingEnvironmentalDataHash()`**: Returns the hash of the latest environmental data submitted by the oracle that is awaiting processing.
25. **`getTimeSinceLastEvolution()`**: Indicates how much time has passed since the last `evolveEcosystem` cycle was triggered.
26. **`getNourishmentBalance()`**: Returns the current native currency balance held in the ecosystem's treasury.
27. **`getDelegatedAffinity(address user)`**: Returns the address to whom a specific user has delegated their affinity.
28. **`getLatestOracleDataTimestamp()`**: Returns the timestamp when the last oracle data was processed.
29. **`getEvolutionCooldown()`**: Returns the minimum time interval required between successive `evolveEcosystem` calls.
30. **`getTotalAffinity()`**: Returns the sum of all accumulated affinity scores across the entire community.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

// --- OUTLINE & FUNCTION SUMMARY ---
//
// Contract Name: Ecosynapse
//
// Core Idea:
// Ecosynapse is a sophisticated, dynamic ERC721 NFT that represents a shared, evolving digital ecosystem.
// Its internal state (parameters like complexity, resilience, sentience) and external representation (metadata URI)
// dynamically adapt based on collective community contributions (nourishment, attuned actions),
// external "environmental data" provided by trusted oracles (simulating AI analysis or real-world events),
// and community-driven "evolutionary directives" voted upon by participants.
// The contract aims to create a self-sustaining and ever-growing digital entity, gamifying community engagement
// and leveraging advanced concepts like dynamic NFTs, oracle integration, and micro-governance for ecosystem evolution.
//
// Functions Summary:
//
// I. Core Ecosystem & NFT Management:
//    1. constructor(): Initializes the ERC721 contract, mints the unique Ecosynapse NFT, and sets initial parameters.
//    2. ecosystemURI(): Returns the dynamically generated metadata URI for the Ecosynapse NFT based on its current state.
//    3. getEcosystemState(): Provides a summarized view of the core ecosystem parameters (e.g., health, complexity, sentience).
//    4. tokenURI(uint256 tokenId): Overrides ERC721's tokenURI to point to the dynamic ecosystemURI.
//    5. setBaseURI(string memory newBaseURI): Allows governance to update the base URL for metadata rendering.
//
// II. Community Engagement & Contributions:
//    6. nourishEcosystem(): Allows users to contribute ETH/native token to the ecosystem's treasury, increasing "Nourishment" metric.
//    7. registerAttunedAction(bytes32 actionHash, string memory description): Users register proof of verifiable off-chain actions, increasing their "Affinity Score".
//    8. claimAffinityReward(): Allows users to claim rewards from the treasury based on their affinity score and ecosystem milestones.
//    9. delegateAffinity(address delegatee): Enables users to delegate their affinity points for voting or other purposes.
//    10. undelegateAffinity(): Revokes an existing affinity delegation.
//
// III. Dynamic Evolution & Oracle Integration:
//    11. updateEnvironmentalData(bytes memory dataHash, uint256 timestamp): (Oracle-only) An oracle submits a hash of new environmental data or AI insights.
//    12. processEnvironmentalImpact(bytes memory oracleSignedData, uint256 dataTimestamp, bytes memory proof): (Oracle-only) The oracle submits signed data and proof to directly influence ecosystem parameters.
//    13. evolveEcosystem(): A publicly callable function to trigger a state update for the ecosystem, calculating new parameters based on contributions and oracle data. Rewards the caller.
//    14. triggerMetabolicPulse(): Simulates a periodic "metabolic cost" or resource burn, potentially decreasing health if nourishment is low.
//    15. setEvolutionCoefficients(uint256 nourishCoeff, uint256 actionCoeff, uint256 oracleCoeff): (Governance) Adjusts the weight of different factors in ecosystem evolution.
//
// IV. Governance & Resource Management:
//    16. proposeEvolutionDirective(string memory description, bytes memory callData, address target): Users propose changes to ecosystem parameters or treasury allocation.
//    17. voteOnDirective(uint256 directiveId, bool support): Users vote on open directives using their affinity score.
//    18. executeDirective(uint256 directiveId): Executes a successfully passed directive.
//    19. allocateTreasuryFunds(address recipient, uint256 amount, string memory reason): (Governance) Allocates funds from the ecosystem treasury.
//    20. governedWithdrawal(address tokenAddress, address recipient, uint256 amount): (Governance) Allows withdrawal of specific tokens from the treasury after governance approval.
//
// V. Query & Utility Functions:
//    21. getAffinityScore(address user): Returns a user's current affinity score.
//    22. getDirective(uint256 directiveId): Returns details of a specific evolution directive.
//    23. getLatestEcosystemParameters(): Returns the most current raw ecosystem parameters.
//    24. getPendingEnvironmentalDataHash(): Returns the latest environmental data hash awaiting processing.
//    25. getTimeSinceLastEvolution(): Returns the time elapsed since the last ecosystem evolution.
//    26. getNourishmentBalance(): Returns the current ETH/native token balance of the ecosystem's treasury.
//    27. getDelegatedAffinity(address user): Returns the address to whom a user has delegated their affinity.
//    28. getLatestOracleDataTimestamp(): Returns the timestamp of the last processed oracle data.
//    29. getEvolutionCooldown(): Returns the minimum time required between evolutions.
//    30. getTotalAffinity(): Returns the total accumulated affinity across all users.
//
// --- CONTRACT CODE ---

contract Ecosynapse is ERC721, Ownable, ReentrancyGuard {
    using Counters for Counters.Counter;
    using SafeMath for uint256;

    // --- State Variables ---

    // The single, unique NFT representing the Ecosynapse itself
    uint256 public constant ECOSYSTEM_NFT_ID = 1;

    // Ecosystem State Parameters (on-chain representation of its 'health', 'intelligence', 'complexity')
    struct EcosystemParameters {
        uint256 health;         // Represents overall vitality (0-1000)
        uint256 complexity;     // Represents structural and functional complexity (0-1000)
        uint256 resilience;     // Represents ability to recover from stress (0-1000)
        uint256 sentienceLevel; // Represents AI-driven 'awareness' or data integration level (0-1000)
        uint256 totalNourishment; // Cumulative nourishment received (in wei)
        uint256 totalAttunedActions; // Cumulative verified attuned actions
        uint256 oracleImpactCount; // Cumulative oracle data processed
    }
    EcosystemParameters public ecosystemParams;

    // Last time evolveEcosystem was called
    uint256 public lastEvolutionTime;
    uint256 public constant EVOLUTION_COOLDOWN = 1 days; // Minimum time between evolutions

    // Cooldown for metabolic pulse
    uint256 public lastMetabolicPulseTime;
    uint256 public constant METABOLIC_PULSE_INTERVAL = 1 hours;

    // Evolution coefficients
    // How much each factor contributes to evolution (e.g., 100 = 100%)
    uint256 public nourishmentEvolutionCoeff = 30; // 30%
    uint256 public actionEvolutionCoeff = 50;      // 50%
    uint256 public oracleEvolutionCoeff = 20;      // 20%
    uint256 public constant EVOLUTION_COEFF_SUM = 100; // Must sum to 100

    // Community Affinity System
    mapping(address => uint256) private _affinityScores; // Base affinity for individual users
    mapping(address => address) public affinityDelegates; // User to whom affinity is delegated (delegator => delegatee)
    mapping(address => uint256) private _delegatedAffinityBalance; // Sum of delegated affinity for a delegatee
    uint256 public totalAffinity; // Sum of all _affinityScores

    // Oracle System
    address public oracleAddress; // Trusted address that can update environmental data and process impact
    bytes32 public pendingEnvironmentalDataHash; // Hash of latest data submitted by oracle, awaiting processing
    uint256 public latestOracleDataTimestamp; // Timestamp of the last processed oracle data

    // Governance Directives
    struct EvolutionDirective {
        string description;
        bytes callData;       // ABI-encoded function call to execute
        address target;       // Contract address to call
        uint256 proposerAffinityAtProposal; // Affinity score of proposer at time of proposal
        uint256 voteStartTime;
        uint256 voteEndTime;
        uint256 yesVotes;
        uint256 noVotes;
        bool executed;
        bool passed;
        mapping(address => bool) hasVoted; // Tracks if an address has voted on this directive (using effective voter address)
    }
    Counters.Counter public directiveIdCounter;
    mapping(uint256 => EvolutionDirective) public evolutionDirectives;
    uint256 public constant VOTING_PERIOD = 3 days;
    uint256 public constant MIN_PROPOSAL_AFFINITY = 100; // Minimum affinity to propose a directive
    uint256 public constant QUORUM_PERCENTAGE = 40; // 40% of total affinity needed for a directive to pass
    uint256 public constant MAJORITY_PERCENTAGE = 50; // 50% of votes must be 'yes' of total cast votes

    // Base URI for the NFT metadata (points to an off-chain renderer/API)
    string private _baseURI;

    // --- Events ---
    event EcosystemNourished(address indexed user, uint256 amount, uint256 newTotalNourishment);
    event AttunedActionRegistered(address indexed user, bytes32 actionHash, string description, uint256 newAffinityScore);
    event AffinityRewardClaimed(address indexed user, uint256 amount);
    event AffinityDelegated(address indexed delegator, address indexed delegatee);
    event AffinityUndelegated(address indexed delegator, address indexed previousDelegatee);
    event EnvironmentalDataUpdated(bytes32 dataHash, uint256 timestamp);
    event EnvironmentalImpactProcessed(uint256 newHealth, uint256 newComplexity, uint256 newResilience, uint256 newSentience);
    event EcosystemEvolved(uint256 newHealth, uint256 newComplexity, uint256 newResilience, uint256 newSentience, address indexed caller);
    event MetabolicPulse(uint256 newHealth, uint256 burnAmount);
    event EvolutionCoefficientsSet(uint256 nourishCoeff, uint256 actionCoeff, uint256 oracleCoeff);
    event DirectiveProposed(uint256 indexed directiveId, address indexed proposer, string description);
    event DirectiveVoted(uint256 indexed directiveId, address indexed voter, bool support, uint256 currentYesVotes, uint256 currentNoVotes);
    event DirectiveExecuted(uint256 indexed directiveId);
    event FundsAllocated(address indexed recipient, uint256 amount, string reason);
    event GovernedWithdrawal(address indexed tokenAddress, address indexed recipient, uint256 amount);

    // --- Modifiers ---
    modifier onlyOracle() {
        require(msg.sender == oracleAddress, "Ecosynapse: Caller is not the oracle");
        _;
    }

    modifier onlyGovernance() {
        // For simplicity in this example, the contract owner is the governance.
        // In a real decentralized scenario, this would be a DAO or multisig contract.
        require(msg.sender == owner(), "Ecosynapse: Caller is not governance");
        _;
    }

    // --- Constructor ---
    /// @notice Constructs the Ecosynapse contract, minting the main ecosystem NFT and setting up initial roles.
    /// @param initialOwner The address that will initially control governance functions.
    /// @param initialOracleAddress The address authorized to submit oracle data.
    /// @param initialBaseURI The base URL for the dynamic NFT metadata.
    constructor(
        address initialOwner,
        address initialOracleAddress,
        string memory initialBaseURI
    ) ERC721("Ecosynapse", "ESYN") Ownable(initialOwner) {
        require(initialOracleAddress != address(0), "Ecosynapse: Invalid oracle address");
        require(bytes(initialBaseURI).length > 0, "Ecosynapse: Base URI cannot be empty");

        oracleAddress = initialOracleAddress;
        _baseURI = initialBaseURI;

        // Mint the unique Ecosynapse NFT (ID 1). It's transferred to owner/governance.
        _mint(initialOwner, ECOSYSTEM_NFT_ID);

        // Initialize ecosystem parameters
        ecosystemParams = EcosystemParameters({
            health: 500,
            complexity: 100,
            resilience: 200,
            sentienceLevel: 50,
            totalNourishment: 0,
            totalAttunedActions: 0,
            oracleImpactCount: 0
        });
        lastEvolutionTime = block.timestamp;
        lastMetabolicPulseTime = block.timestamp;
    }

    /// @notice Allows direct ETH contributions to nourish the ecosystem.
    receive() external payable {
        nourishEcosystem();
    }

    // --- I. Core Ecosystem & NFT Management ---

    /// @notice Returns the dynamically generated metadata URI for the Ecosynapse NFT.
    /// @dev This URI will likely point to an off-chain service that renders the NFT based on on-chain parameters.
    function ecosystemURI() public view returns (string memory) {
        // Example: baseURI/health/complexity/resilience/sentienceLevel.json
        // In a real application, this would be more complex, potentially involving IPFS CIDs or direct parameter passing.
        string memory healthStr = _toString(ecosystemParams.health);
        string memory complexityStr = _toString(ecosystemParams.complexity);
        string memory resilienceStr = _toString(ecosystemParams.resilience);
        string memory sentienceStr = _toString(ecosystemParams.sentienceLevel);

        return string(abi.encodePacked(
            _baseURI, "/",
            healthStr, "/",
            complexityStr, "/",
            resilienceStr, "/",
            sentienceStr, ".json"
        ));
    }

    /// @notice Returns a summarized view of the core ecosystem parameters.
    /// @return health The current health score (0-1000).
    /// @return complexity The current complexity score (0-1000).
    /// @return resilience The current resilience score (0-1000).
    /// @return sentienceLevel The current sentience level (0-1000).
    function getEcosystemState() public view returns (uint256 health, uint256 complexity, uint256 resilience, uint256 sentienceLevel) {
        return (
            ecosystemParams.health,
            ecosystemParams.complexity,
            ecosystemParams.resilience,
            ecosystemParams.sentienceLevel
        );
    }

    /// @dev ERC721 override to ensure the single Ecosynapse NFT returns its dynamic URI.
    /// @param tokenId The ID of the NFT (must be ECOSYSTEM_NFT_ID).
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        require(tokenId == ECOSYSTEM_NFT_ID, "Ecosynapse: Only the main ecosystem NFT has a dynamic URI.");
        return ecosystemURI();
    }

    /// @notice Allows governance to update the base URL for the dynamic NFT metadata rendering.
    /// @param newBaseURI The new base URI.
    function setBaseURI(string memory newBaseURI) public onlyGovernance {
        require(bytes(newBaseURI).length > 0, "Ecosynapse: Base URI cannot be empty");
        _baseURI = newBaseURI;
    }

    // --- II. Community Engagement & Contributions ---

    /// @notice Allows users to contribute native currency (ETH) to the ecosystem's treasury.
    /// @dev Increases the "Nourishment" metric. Can be called with `msg.value`.
    function nourishEcosystem() public payable nonReentrant {
        require(msg.value > 0, "Ecosynapse: Contribution amount must be greater than zero.");
        ecosystemParams.totalNourishment = ecosystemParams.totalNourishment.add(msg.value);
        emit EcosystemNourished(msg.sender, msg.value, ecosystemParams.totalNourishment);
    }

    /// @notice Users register a hash representing a verifiable off-chain action (e.g., contributing data, social engagement).
    /// @dev Increases the user's "Affinity Score" (or their delegatee's) and the ecosystem's "Total Attuned Actions".
    /// @param actionHash A unique hash identifying the action (e.g., hash of a URL, IPFS CID of data).
    /// @param description A brief description of the action.
    function registerAttunedAction(bytes32 actionHash, string memory description) public nonReentrant {
        // Simple logic for affinity: 1 point per action. Could be more complex (e.g., weighted, time-decay).
        uint256 points = 1;

        // Determine the effective address to apply affinity to (either self or delegatee)
        address effectiveRecipient = affinityDelegates[msg.sender] != address(0) ? affinityDelegates[msg.sender] : msg.sender;
        _affinityScores[effectiveRecipient] = _affinityScores[effectiveRecipient].add(points);
        totalAffinity = totalAffinity.add(points); // Total affinity simply sums all points
        ecosystemParams.totalAttunedActions = ecosystemParams.totalAttunedActions.add(1);

        emit AttunedActionRegistered(msg.sender, actionHash, description, _affinityScores[effectiveRecipient]);
    }

    /// @notice Allows users to claim rewards from the treasury based on their affinity score.
    /// @dev This is a placeholder for a more complex reward distribution system.
    function claimAffinityReward() public nonReentrant {
        uint256 userAffinity = _affinityScores[msg.sender]; // Only claimable by direct affinity holder
        require(userAffinity > 0, "Ecosynapse: No affinity score to claim rewards.");
        
        // Example: reward 0.0001 ETH per affinity point, up to a certain portion of the treasury
        uint256 rewardPerAffinityPoint = 0.0001 ether; 
        uint256 effectiveReward = userAffinity.mul(rewardPerAffinityPoint);

        require(effectiveReward > 0, "Ecosynapse: No calculable reward at this time.");
        require(address(this).balance >= effectiveReward, "Ecosynapse: Insufficient treasury balance for rewards.");

        // Reset user's affinity score after claiming to prevent double-claiming for the same actions
        _affinityScores[msg.sender] = 0;
        totalAffinity = totalAffinity.sub(userAffinity); // Adjust total affinity

        (bool success, ) = payable(msg.sender).call{value: effectiveReward}("");
        require(success, "Ecosynapse: Failed to send reward.");

        emit AffinityRewardClaimed(msg.sender, effectiveReward);
    }

    /// @notice Allows a user to delegate their affinity points to another address.
    /// @dev The delegatee will be able to vote and register actions that count towards their delegated affinity.
    /// @param delegatee The address to delegate affinity to.
    function delegateAffinity(address delegatee) public {
        require(delegatee != address(0), "Ecosynapse: Cannot delegate to zero address");
        require(delegatee != msg.sender, "Ecosynapse: Cannot delegate to self");

        address currentDelegatee = affinityDelegates[msg.sender];
        uint256 currentAffinity = _affinityScores[msg.sender];

        // If already delegated, remove current delegation from the old delegatee's balance
        if (currentDelegatee != address(0)) {
            _delegatedAffinityBalance[currentDelegatee] = _delegatedAffinityBalance[currentDelegatee].sub(currentAffinity);
        }

        affinityDelegates[msg.sender] = delegatee;
        _delegatedAffinityBalance[delegatee] = _delegatedAffinityBalance[delegatee].add(currentAffinity);

        emit AffinityDelegated(msg.sender, delegatee);
    }

    /// @notice Allows a user to undelegate their affinity points.
    function undelegateAffinity() public {
        address currentDelegatee = affinityDelegates[msg.sender];
        require(currentDelegatee != address(0), "Ecosynapse: Not currently delegated");

        uint256 currentAffinity = _affinityScores[msg.sender];
        _delegatedAffinityBalance[currentDelegatee] = _delegatedAffinityBalance[currentDelegatee].sub(currentAffinity);
        affinityDelegates[msg.sender] = address(0);

        emit AffinityUndelegated(msg.sender, currentDelegatee);
    }

    // --- III. Dynamic Evolution & Oracle Integration ---

    /// @notice (Oracle-only) An oracle submits a hash representing recent environmental data or AI insights.
    /// @dev This data is not immediately processed but queued for the next `evolveEcosystem` call or explicit `processEnvironmentalImpact`.
    /// @param dataHash A hash of the environmental data/AI insights.
    /// @param timestamp The timestamp when the data was generated/observed.
    function updateEnvironmentalData(bytes32 dataHash, uint256 timestamp) public onlyOracle {
        pendingEnvironmentalDataHash = dataHash;
        latestOracleDataTimestamp = timestamp;
        emit EnvironmentalDataUpdated(dataHash, timestamp);
    }

    /// @notice (Oracle-only) The oracle processes specific environmental impacts or AI analysis results, directly altering ecosystem parameters.
    /// @dev This function expects signed data and an optional proof (e.g., a simple signature, or a ZKP for more complex attestations).
    /// @param oracleSignedData The actual data signed by the oracle (e.g., ABI-encoded new parameter values).
    /// @param dataTimestamp The timestamp of the signed data.
    /// @param proof An optional proof (e.g., signature or ZKP output). (Placeholder)
    function processEnvironmentalImpact(
        bytes memory oracleSignedData,
        uint256 dataTimestamp,
        bytes memory proof // Placeholder for potential ZKP or more complex signature verification
    ) public onlyOracle nonReentrant {
        // In a real scenario, `oracleSignedData` would be verified (e.g., `_verifySignature(msg.sender, oracleSignedData, proof)`)
        // and then decoded to apply specific, granular impacts on ecosystem parameters.
        // For this example, we'll simulate a positive impact assuming the data is valid.

        ecosystemParams.health = SafeMath.min(ecosystemParams.health.add(10), 1000);
        ecosystemParams.complexity = SafeMath.min(ecosystemParams.complexity.add(5), 1000);
        ecosystemParams.resilience = SafeMath.min(ecosystemParams.resilience.add(8), 1000);
        ecosystemParams.sentienceLevel = SafeMath.min(ecosystemParams.sentienceLevel.add(15), 1000);
        ecosystemParams.oracleImpactCount = ecosystemParams.oracleImpactCount.add(1);

        // Clear pending hash as it's now processed (or if this is a direct impact, it bypasses the queue)
        pendingEnvironmentalDataHash = bytes32(0);
        latestOracleDataTimestamp = dataTimestamp;

        emit EnvironmentalImpactProcessed(
            ecosystemParams.health,
            ecosystemParams.complexity,
            ecosystemParams.resilience,
            ecosystemParams.sentienceLevel
        );
    }

    /// @notice Triggers an evolution cycle for the Ecosynapse based on accumulated contributions and oracle data.
    /// @dev Anyone can call this after a cooldown. Rewards the caller for triggering.
    function evolveEcosystem() public nonReentrant {
        require(block.timestamp >= lastEvolutionTime.add(EVOLUTION_COOLDOWN), "Ecosynapse: Evolution is on cooldown.");

        // Scale factors: 1 nourishment point per 0.1 ETH, 1 action point per action, 1 oracle point per impact.
        uint256 nourishmentFactor = ecosystemParams.totalNourishment.div(1 ether); 
        uint256 actionFactor = ecosystemParams.totalAttunedActions;
        uint256 oracleFactor = ecosystemParams.oracleImpactCount;

        // Calculate potential growth based on factors and coefficients (weighted average)
        uint256 healthGrowth = (nourishmentFactor.mul(nourishmentEvolutionCoeff) +
                                actionFactor.mul(actionEvolutionCoeff) +
                                oracleFactor.mul(oracleEvolutionCoeff)).div(EVOLUTION_COEFF_SUM);

        // Apply growth, capping at 1000. Growth is proportionate to the calculated healthGrowth
        ecosystemParams.health = SafeMath.min(ecosystemParams.health.add(healthGrowth.div(5)), 1000); 
        ecosystemParams.complexity = SafeMath.min(ecosystemParams.complexity.add(healthGrowth.div(10)), 1000);
        ecosystemParams.resilience = SafeMath.min(ecosystemParams.resilience.add(healthGrowth.div(8)), 1000);
        ecosystemParams.sentienceLevel = SafeMath.min(ecosystemParams.sentienceLevel.add(healthGrowth.div(7)), 1000);

        // Reset cumulative factors for the next evolution cycle.
        ecosystemParams.totalNourishment = 0; 
        ecosystemParams.totalAttunedActions = 0;
        ecosystemParams.oracleImpactCount = 0; 

        lastEvolutionTime = block.timestamp;

        // Reward the caller for triggering evolution
        uint256 callerReward = 0.005 ether; // Example fixed reward
        if (address(this).balance >= callerReward) {
            (bool success, ) = payable(msg.sender).call{value: callerReward}("");
            require(success, "Ecosynapse: Failed to send evolution reward.");
        }

        emit EcosystemEvolved(
            ecosystemParams.health,
            ecosystemParams.complexity,
            ecosystemParams.resilience,
            ecosystemParams.sentienceLevel,
            msg.sender
        );
    }

    /// @notice Simulates a "metabolic cost" for the ecosystem, potentially reducing health if nourishment is low.
    /// @dev Callable periodically.
    function triggerMetabolicPulse() public nonReentrant {
        require(block.timestamp >= lastMetabolicPulseTime.add(METABOLIC_PULSE_INTERVAL), "Ecosynapse: Metabolic pulse on cooldown.");

        uint256 metabolicCostETH = 0.001 ether; // Example: 0.001 ETH per pulse

        // If treasury has enough, simulate a "burn" of resources, otherwise health declines.
        if (address(this).balance >= metabolicCostETH) {
            // Funds are 'used' and effectively burned by remaining in contract but not being claimable by owners unless via governance.
            // A more direct burn would be to send to address(0).
        } else {
            // If treasury is too low, ecosystem health declines significantly
            ecosystemParams.health = SafeMath.max(ecosystemParams.health.sub(50), 0); // Health reduced by 50 points
        }
        
        // Always apply some base decay (simulates natural entropy)
        ecosystemParams.health = SafeMath.max(ecosystemParams.health.sub(10), 0); // Health reduced by 10 points

        lastMetabolicPulseTime = block.timestamp;

        emit MetabolicPulse(ecosystemParams.health, metabolicCostETH);
    }

    /// @notice (Governance) Adjusts the coefficients that determine how much each factor influences ecosystem evolution.
    /// @dev Coefficients must sum up to `EVOLUTION_COEFF_SUM` (100).
    /// @param nourishCoeff New nourishment coefficient.
    /// @param actionCoeff New action coefficient.
    /// @param oracleCoeff New oracle coefficient.
    function setEvolutionCoefficients(uint256 nourishCoeff, uint256 actionCoeff, uint256 oracleCoeff) public onlyGovernance {
        require(nourishCoeff.add(actionCoeff).add(oracleCoeff) == EVOLUTION_COEFF_SUM, "Ecosynapse: Coefficients must sum to EVOLUTION_COEFF_SUM");
        nourishmentEvolutionCoeff = nourishCoeff;
        actionEvolutionCoeff = actionCoeff;
        oracleEvolutionCoeff = oracleCoeff;
        emit EvolutionCoefficientsSet(nourishCoeff, actionCoeff, oracleCoeff);
    }

    // --- IV. Governance & Resource Management ---

    /// @notice Allows users with sufficient affinity to propose an "Evolution Directive".
    /// @dev These directives are essentially proposals for governance actions or parameter changes.
    /// @param description A description of the directive.
    /// @param callData ABI-encoded function call to execute if the directive passes.
    /// @param target The address of the contract to call (e.g., this contract for internal changes).
    function proposeEvolutionDirective(string memory description, bytes memory callData, address target) public {
        require(getAffinityScore(msg.sender) >= MIN_PROPOSAL_AFFINITY, "Ecosynapse: Insufficient affinity to propose.");
        
        directiveIdCounter.increment();
        uint256 newDirectiveId = directiveIdCounter.current();

        evolutionDirectives[newDirectiveId] = EvolutionDirective({
            description: description,
            callData: callData,
            target: target,
            proposerAffinityAtProposal: getAffinityScore(msg.sender), // Store proposer's affinity at time of proposal
            voteStartTime: block.timestamp,
            voteEndTime: block.timestamp.add(VOTING_PERIOD),
            yesVotes: 0,
            noVotes: 0,
            executed: false,
            passed: false
        });

        emit DirectiveProposed(newDirectiveId, msg.sender, description);
    }

    /// @notice Allows users to vote on an open evolution directive using their effective affinity score.
    /// @param directiveId The ID of the directive to vote on.
    /// @param support True for 'yes', false for 'no'.
    function voteOnDirective(uint256 directiveId, bool support) public {
        EvolutionDirective storage directive = evolutionDirectives[directiveId];
        require(directive.voteStartTime > 0, "Ecosynapse: Directive does not exist.");
        require(block.timestamp >= directive.voteStartTime && block.timestamp <= directive.voteEndTime, "Ecosynapse: Voting period not active.");
        
        // Use the effective voter address (if delegated, it's the delegatee)
        address effectiveVoter = affinityDelegates[msg.sender] != address(0) ? affinityDelegates[msg.sender] : msg.sender;
        require(!directive.hasVoted[effectiveVoter], "Ecosynapse: You (or your delegate) have already voted on this directive.");

        uint256 voterAffinity = getAffinityScore(effectiveVoter); // Use effective affinity (including delegated)
        require(voterAffinity > 0, "Ecosynapse: Cannot vote with zero affinity.");

        if (support) {
            directive.yesVotes = directive.yesVotes.add(voterAffinity);
        } else {
            directive.noVotes = directive.noVotes.add(voterAffinity);
        }
        directive.hasVoted[effectiveVoter] = true;

        emit DirectiveVoted(directiveId, msg.sender, support, directive.yesVotes, directive.noVotes);
    }

    /// @notice Executes a successfully passed evolution directive.
    /// @param directiveId The ID of the directive to execute.
    function executeDirective(uint256 directiveId) public nonReentrant {
        EvolutionDirective storage directive = evolutionDirectives[directiveId];
        require(directive.voteStartTime > 0, "Ecosynapse: Directive does not exist.");
        require(block.timestamp > directive.voteEndTime, "Ecosynapse: Voting period not ended.");
        require(!directive.executed, "Ecosynapse: Directive already executed.");

        uint256 totalVotesCast = directive.yesVotes.add(directive.noVotes);
        uint256 requiredQuorum = totalAffinity.mul(QUORUM_PERCENTAGE).div(100);
        
        // Check quorum (total votes cast must meet a percentage of total possible affinity)
        require(totalVotesCast >= requiredQuorum, "Ecosynapse: Directive failed to meet quorum.");

        // Check majority (yes votes must be greater than 50% of total votes cast)
        require(directive.yesVotes.mul(100) > totalVotesCast.mul(MAJORITY_PERCENTAGE), "Ecosynapse: Directive failed to meet majority.");

        directive.passed = true; // Mark as passed before execution attempt

        (bool success, ) = directive.target.call(directive.callData);
        require(success, "Ecosynapse: Directive execution failed.");
        directive.executed = true;
        emit DirectiveExecuted(directiveId);
    }

    /// @notice (Governance) Allows the governance to allocate native currency funds from the ecosystem treasury.
    /// @param recipient The address to send funds to.
    /// @param amount The amount of ETH/native token to send (in wei).
    /// @param reason A descriptive reason for the allocation.
    function allocateTreasuryFunds(address recipient, uint256 amount, string memory reason) public onlyGovernance nonReentrant {
        require(amount > 0, "Ecosynapse: Amount must be greater than zero.");
        require(address(this).balance >= amount, "Ecosynapse: Insufficient treasury balance.");
        
        (bool success, ) = payable(recipient).call{value: amount}("");
        require(success, "Ecosynapse: Failed to allocate funds.");

        emit FundsAllocated(recipient, amount, reason);
    }

    /// @notice (Governance) Allows withdrawal of specific ERC20 tokens from the treasury after governance approval.
    /// @dev This is a safeguard for accidental ERC20 deposits or for managing other assets.
    /// @param tokenAddress The address of the ERC20 token.
    /// @param recipient The address to send the tokens to.
    /// @param amount The amount of tokens to withdraw.
    function governedWithdrawal(address tokenAddress, address recipient, uint256 amount) public onlyGovernance nonReentrant {
        require(tokenAddress != address(0), "Ecosynapse: Invalid token address.");
        require(recipient != address(0), "Ecosynapse: Invalid recipient address.");
        require(amount > 0, "Ecosynapse: Amount must be greater than zero.");

        // Standard ERC20 transfer call
        // 0xa9059cbb is the keccak256 hash of "transfer(address,uint256)"
        (bool success, bytes memory data) = tokenAddress.call(abi.encodeWithSelector(0xa9059cbb, recipient, amount));
        require(success, "Ecosynapse: ERC20 transfer failed");

        // Some ERC20 tokens return false on failure instead of reverting. Check for this.
        if (data.length > 0) {
            require(abi.decode(data, (bool)), "Ecosynapse: ERC20 transfer failed with false return.");
        }

        emit GovernedWithdrawal(tokenAddress, recipient, amount);
    }

    // --- V. Query & Utility Functions ---

    /// @notice Returns a user's current effective affinity score (their direct score plus any delegated to them).
    /// @param user The address to query.
    function getAffinityScore(address user) public view returns (uint256) {
        return _affinityScores[user].add(_delegatedAffinityBalance[user]);
    }

    /// @notice Returns details of a specific evolution directive.
    /// @param directiveId The ID of the directive.
    function getDirective(uint256 directiveId) public view returns (
        string memory description,
        address target,
        uint256 proposerAffinity,
        uint256 voteStartTime,
        uint256 voteEndTime,
        uint256 yesVotes,
        uint256 noVotes,
        bool executed,
        bool passed
    ) {
        EvolutionDirective storage directive = evolutionDirectives[directiveId];
        require(directive.voteStartTime > 0, "Ecosynapse: Directive does not exist.");
        return (
            directive.description,
            directive.target,
            directive.proposerAffinityAtProposal,
            directive.voteStartTime,
            directive.voteEndTime,
            directive.yesVotes,
            directive.noVotes,
            directive.executed,
            directive.passed
        );
    }

    /// @notice Returns the most current raw ecosystem parameters.
    function getLatestEcosystemParameters() public view returns (
        uint256 health,
        uint256 complexity,
        uint256 resilience,
        uint256 sentienceLevel,
        uint256 totalNourishment,
        uint256 totalAttunedActions,
        uint256 oracleImpactCount
    ) {
        return (
            ecosystemParams.health,
            ecosystemParams.complexity,
            ecosystemParams.resilience,
            ecosystemParams.sentienceLevel,
            ecosystemParams.totalNourishment,
            ecosystemParams.totalAttunedActions,
            ecosystemParams.oracleImpactCount
        );
    }

    /// @notice Returns the latest environmental data hash submitted by the oracle, if any, that is awaiting processing.
    function getPendingEnvironmentalDataHash() public view returns (bytes32) {
        return pendingEnvironmentalDataHash;
    }

    /// @notice Returns the time elapsed in seconds since the last ecosystem evolution.
    function getTimeSinceLastEvolution() public view returns (uint256) {
        return block.timestamp.sub(lastEvolutionTime);
    }

    /// @notice Returns the current native currency balance of the ecosystem's treasury.
    function getNourishmentBalance() public view returns (uint256) {
        return address(this).balance;
    }

    /// @notice Returns the address to whom a user has delegated their affinity. Returns address(0) if not delegated.
    /// @param user The address to query.
    function getDelegatedAffinity(address user) public view returns (address) {
        return affinityDelegates[user];
    }

    /// @notice Returns the timestamp of the last time oracle data was processed (i.e., `processEnvironmentalImpact` was called).
    function getLatestOracleDataTimestamp() public view returns (uint256) {
        return latestOracleDataTimestamp;
    }

    /// @notice Returns the minimum time (in seconds) required between successive `evolveEcosystem` calls.
    function getEvolutionCooldown() public pure returns (uint256) {
        return EVOLUTION_COOLDOWN;
    }

    /// @notice Returns the total accumulated affinity across all users who have contributed directly.
    function getTotalAffinity() public view returns (uint256) {
        return totalAffinity;
    }

    // --- Internal Utility Functions ---

    /// @dev Converts a uint256 to its string representation.
    function _toString(uint256 value) internal pure returns (string memory) {
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
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }
}
```