Okay, this is an ambitious and fun challenge! I'll design a smart contract called `ChronoGenesisProtocol` that embodies an "Evolving Digital Ecosystem." It will manage dynamic NFTs ("Genesis Fragments") whose traits evolve based on community "cultivation," "mutation" events, a staking-based resource ("Evolutionary Essence"), and even simulated on-chain "environmental" factors. Community governance will allow participants to propose and vote on the very rules of evolution and protocol parameters.

---

## ChronoGenesisProtocol: Evolving Digital Ecosystem

**Purpose:** Manages a collection of dynamically evolving digital assets (Genesis Fragments) through community interaction, staking, and on-chain environmental influences. It aims to create a self-sustaining, community-driven digital ecosystem where participants actively shape the future of their digital lifeforms.

---

### **Outline and Function Summary**

**Core Concepts:**
*   **Dynamic NFTs (Genesis Fragments):** Each fragment is an ERC721 token with mutable on-chain traits that change over time based on various inputs.
*   **Evolutionary Essence (EE):** An internal, fungible resource obtained by staking native tokens. EE is the "fuel" for all evolutionary actions and governance participation.
*   **Community Governance:** EE holders can propose and vote on changes to fragment evolution rules and core protocol parameters, creating a living, adaptable system.
*   **On-chain Environment:** Simulated external factors (e.g., block data, mock oracle feeds) influence fragment evolution, introducing an element of global change.
*   **Gamification:** Mechanics like "Cultivation," "Mutation," and "Ascension" provide engaging ways for users to interact with their fragments.

**State Variables:**
*   `_genesisFragments`: Mapping from fragment ID to its detailed `FragmentState` struct.
*   `_essenceBalances`: Mapping from address to `Evolutionary Essence` balance.
*   `_stakedNativeTokens`: Mapping from address to the amount of native tokens staked for EE.
*   `_lastEssenceClaimTime`: Mapping from address to the last timestamp EE was claimed.
*   `evolutionProposals` / `parameterProposals`: Mappings for tracking governance proposals.
*   `_nextFragmentId`, `_nextEvolutionProposalId`, `_nextParameterProposalId`: Counters for IDs.
*   `_environmentalOracle`: Address of a mock external oracle for environmental data.
*   `protocolParameters`: A mapping of `bytes32` keys to `uint256` values for configurable system constants.
*   `_fragmentObservers`: An array of contract addresses that can subscribe to fragment state change notifications.
*   `_protocolDAO`: The address of the governing entity (initially `Ownable` owner, but conceptually a DAO).

**Enums and Structs:**
*   `TraitType`: Defines categories of fragment traits (e.g., Strength, Resilience).
*   `FragmentState`: Holds all dynamic properties of a Genesis Fragment.
*   `ProposalStatus`: Defines the lifecycle stages of a governance proposal.
*   `EvolutionProposal`: Details proposals aimed at altering trait evolution rules.
*   `ParameterProposal`: Details proposals aimed at altering core protocol parameters.

---

**Functions:**

**I. Fragment Lifecycle & Evolution (Core Dynamic NFT Mechanics)**
1.  `mintGenesisFragment(string memory name, uint256[] memory initialTraits)`: Mints a new Genesis Fragment NFT with initial traits and a name.
2.  `getFragmentDetails(uint256 fragmentId)`: Retrieves comprehensive details (traits, stage, owner, metadata) of a specific fragment.
3.  `getFragmentEvolutionHistory(uint256 fragmentId)`: Returns a chronological array of state hashes representing significant evolution points for a fragment.
4.  `cultivateFragment(uint256 fragmentId, TraitType traitToInfluence, uint256 influencePower)`: Allows an owner to spend EE to gently influence a specific trait, with effectiveness modified by fragment stats and environment.
5.  `triggerMutationEvent(uint256 fragmentId)`: Initiates a probabilistic, potentially drastic mutation in a fragment's traits, consuming more EE. Success and outcome are influenced by adaptability and randomness.
6.  `ascendFragment(uint256 fragmentId)`: Triggers a major evolutionary leap (stage progression) for a fragment that meets specific criteria (e.g., high traits, cumulative EE spent), potentially transforming its type and unlocking new abilities.
7.  `ponderAndDiscoverNewTrait()`: A protocol-level function (callable by anyone, incentivized) that simulates discovery of new evolutionary paths or latent traits based on global ecosystem data and on-chain randomness.
8.  `triggerEnvironmentalShift()`: A function (can be automated or DAO-triggered) that applies global environmental modifiers to all fragments, influenced by data from the `_environmentalOracle`.
9.  `updateFragmentMetadataURI(uint256 fragmentId, string memory newURI)`: Allows the fragment owner to update the URI pointing to its visual/descriptive metadata, typically after significant evolution.

**II. Evolutionary Essence (Internal Resource System)**
10. `stakeForEvolutionaryEssence()`: Allows users to stake native tokens (ETH/MATIC etc.) to begin accruing Evolutionary Essence over time.
11. `unstakeEvolutionaryEssence(uint256 amount)`: Allows users to retrieve a specified amount of their staked native tokens, first claiming any pending Essence.
12. `claimEvolutionaryEssence()`: Allows users to claim all their accrued Evolutionary Essence based on their staked amount and time.
13. `getEvolutionaryEssenceBalance(address account)`: Returns the current liquid (claimable + claimed) Essence balance for an address.
14. `transferEvolutionaryEssence(address recipient, uint256 amount)`: Allows users to transfer their Essence to another address.

**III. Governance & Protocol Parameters (DAO-like Functionality)**
15. `submitEvolutionPathProposal(uint256 targetFragmentId, TraitType traitType, bytes32 newEvolutionRuleHash, string memory description)`: Propose changes to evolution rules, either for a specific fragment (for testing/special cases) or globally (if `targetFragmentId` is 0).
16. `voteOnEvolutionProposal(uint256 proposalId, bool support)`: Casts a vote (for or against) on an active evolution path proposal, with voting power based on the caller's Essence balance.
17. `executeEvolutionPathProposal(uint256 proposalId)`: Executes a passed evolution path proposal, applying its changes to the system's rule-set.
18. `submitProtocolParameterProposal(bytes32 parameterKey, uint256 newValue, string memory description)`: Propose changes to core protocol parameters (e.g., cultivation costs, voting periods).
19. `voteOnProtocolParameterProposal(uint256 proposalId, bool support)`: Casts a vote on an active protocol parameter proposal.
20. `executeProtocolParameterChange(uint256 proposalId)`: Executes a passed protocol parameter proposal, updating the relevant `protocolParameters`.

**IV. Utility & Ecosystem Management**
21. `setEnvironmentalOracle(address oracleAddress)`: Sets the address of the external environmental oracle (callable by `_protocolDAO`).
22. `getProtocolParameter(bytes32 parameterKey)`: Retrieves the current value of a specific protocol parameter.
23. `registerFragmentObserver(address observerContract)`: Allows other smart contracts to register as observers to receive notifications of fragment state changes (e.g., for analytics, dApps).
24. `snapshotEcosystemState(string memory snapshotLabel)`: Records a global snapshot of key ecosystem metrics for historical analysis or potential future forks/upgrades.
25. `donateToEcosystemTreasury()`: Allows users to send native tokens to support protocol development and maintenance.
26. `withdrawFromTreasury(address recipient, uint256 amount)`: Allows the `_protocolDAO` to withdraw funds from the ecosystem treasury.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol"; // Using Ownable for simplicity for _protocolDAO/admin functions.
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol"; // Explicit SafeMath for clarity, even though 0.8.x has checks.
import "@openzeppelin/contracts/utils/Strings.sol"; // For converting uint256 to string for metadata URIs.

// Interface for a potential external environmental oracle
// In a real scenario, this would be Chainlink or a more robust decentralized oracle network.
interface IEnvironmentalOracle {
    function getEnvironmentalFactor(string calldata factorName) external view returns (uint256);
}

// Interface for Fragment Observers to receive notifications
interface IFragmentObserver {
    function onFragmentChange(uint256 fragmentId, address indexed owner, string calldata eventType, bytes32 eventDataHash) external;
}


contract ChronoGenesisProtocol is ERC721, Ownable {
    using Counters for Counters.Counter;
    using SafeMath for uint256;
    using Strings for uint256;

    // --- Enums & Structs ---

    // Represents different categories of traits a fragment can possess
    enum TraitType {
        Strength,
        Resilience,
        Adaptability,
        Mysticism,
        Intelligence,
        Charm,
        GrowthRate,       // Influences how fast traits naturally increase
        EnergyEfficiency  // Influences the Essence cost of actions
    }

    // Current state and properties of a Genesis Fragment
    struct FragmentState {
        uint256 id;
        address owner;
        uint256 creationTime;
        uint256 lastEvolutionTime;      // Last time a significant evolution/mutation event occurred
        mapping(TraitType => uint256) traits; // Dynamic trait values
        uint256 evolutionStage;         // E.g., 0=Larva, 1=Cocoon, 2=Butterfly, 3=Ascended
        string name;
        string currentMetadataURI;      // Points to off-chain data (image, full description)
        uint256 totalEssenceSpent;      // Lifetime Essence spent on this fragment
        uint256 lastActionBlock;        // To enforce cooldowns on cultivation/mutation per fragment
        bytes32[] evolutionHistoryHashes; // Hash of state after major evolutions/milestones
    }

    enum ProposalStatus { Pending, Approved, Rejected, Executed }

    // Structure for proposals related to fragment evolution paths
    // `newEvolutionRuleHash` could point to more complex off-chain logic or an on-chain function ID
    struct EvolutionProposal {
        uint256 proposalId;
        uint256 targetFragmentId;       // 0 for general rule, specific ID for fragment-specific rule
        TraitType traitType;            // The trait category this rule applies to
        bytes32 newEvolutionRuleHash;   // A hash representing a new rule, actual rule implementation is abstract here
        string description;
        uint256 submissionTime;
        uint256 votingDeadline;
        uint256 votesFor;
        uint256 votesAgainst;
        mapping(address => bool) hasVoted; // Tracks if an address has voted
        ProposalStatus status;
    }

    // Structure for proposals related to general protocol parameters
    struct ParameterProposal {
        uint256 proposalId;
        bytes32 parameterKey;           // E.g., keccak256("CULTIVATION_ESSENCE_COST")
        uint256 newValue;
        string description;
        uint256 submissionTime;
        uint256 votingDeadline;
        uint256 votesFor;
        uint256 votesAgainst;
        mapping(address => bool) hasVoted;
        ProposalStatus status;
    }

    // --- State Variables ---

    Counters.Counter private _nextFragmentId;
    Counters.Counter private _nextEvolutionProposalId;
    Counters.Counter private _nextParameterProposalId;

    // Stores all Genesis Fragments by ID
    mapping(uint256 => FragmentState) public _genesisFragments;

    // Evolutionary Essence balances (internal fungible resource)
    mapping(address => uint256) public _essenceBalances;
    mapping(address => uint256) public _stakedNativeTokens;
    mapping(address => uint256) public _lastEssenceClaimTime; // Timestamp of last EE claim or stake

    // Governance proposals
    mapping(uint256 => EvolutionProposal) public evolutionProposals;
    mapping(uint256 => ParameterProposal) public parameterProposals;

    // External dependencies
    IEnvironmentalOracle public _environmentalOracle;

    // Protocol configuration parameters (key-value store for flexibility)
    mapping(bytes32 => uint256) public protocolParameters;

    // Addresses of contracts that want to be notified of fragment changes
    address[] public _fragmentObservers;

    // Timestamp of the last time ponderAndDiscoverNewTrait was called
    uint256 public _lastPonderCallTime;

    // --- Events ---

    event FragmentMinted(uint256 indexed fragmentId, address indexed owner, string name, uint256 creationTime);
    event FragmentCultivated(uint256 indexed fragmentId, address indexed cultivator, TraitType traitType, uint256 influencePower, uint256 essenceCost);
    event FragmentMutated(uint256 indexed fragmentId, address indexed mutator, uint256 essenceCost, bool success);
    event FragmentAscended(uint256 indexed fragmentId, address indexed ascender, uint256 newEvolutionStage);
    event FragmentMetadataURIUpdated(uint256 indexed fragmentId, string newURI);
    event NewTraitDiscovered(bytes32 indexed discoveryHash, string description);
    event EnvironmentalShiftApplied(string indexed factor, uint256 value, uint256 blockNumber);

    event EssenceStaked(address indexed staker, uint256 amount, uint256 totalStaked);
    event EssenceUnstaked(address indexed staker, uint256 amount, uint256 remainingStaked);
    event EssenceClaimed(address indexed claimant, uint256 amount);
    event EssenceTransferred(address indexed from, address indexed to, uint256 amount);

    event EvolutionProposalSubmitted(uint256 indexed proposalId, address indexed proposer, uint256 targetFragmentId, TraitType traitType, bytes32 newRuleHash);
    event ParameterProposalSubmitted(uint256 indexed proposalId, address indexed proposer, bytes32 parameterKey, uint256 newValue);
    event VoteCast(uint256 indexed proposalId, address indexed voter, bool support, bool isEvolutionProposal);
    event ProposalExecuted(uint256 indexed proposalId, bool isEvolutionProposal, bool success);

    event OracleUpdated(address indexed oldOracle, address indexed newOracle);
    event EcosystemSnapshot(string indexed label, uint256 blockNumber, uint256 totalFragments);
    event TreasuryDonation(address indexed donor, uint256 amount);
    event TreasuryWithdrawal(address indexed recipient, uint256 amount);

    // --- Constructor ---

    constructor(address initialOracle, address protocolDAOAddress) ERC721("ChronoGenesis Fragment", "CGF") Ownable(protocolDAOAddress) {
        require(initialOracle != address(0), "Invalid oracle address");
        require(protocolDAOAddress != address(0), "Invalid DAO address");

        _environmentalOracle = IEnvironmentalOracle(initialOracle);
        // _protocolDAO is set via Ownable(protocolDAOAddress)

        // Initialize default protocol parameters
        // Values are illustrative and would be tuned in a real system
        protocolParameters[keccak256("ESSENCE_PER_NATIVE_UNIT_PER_SECOND")] = 10; // 10 Essence per native token unit (scaled by 1e18) per second
        protocolParameters[keccak256("CULTIVATION_BASE_ESSENCE_COST")] = 1000;
        protocolParameters[keccak256("MUTATION_BASE_ESSENCE_COST")] = 5000;
        protocolParameters[keccak256("ASCENSION_BASE_ESSENCE_COST")] = 10000;
        protocolParameters[keccak256("MUTATION_BASE_SUCCESS_CHANCE_PERCENT")] = 30; // 30% base chance
        protocolParameters[keccak256("MIN_ESSENCE_TO_SUBMIT_PROPOSAL")] = 100000; // Min Essence to submit a proposal
        protocolParameters[keccak256("VOTING_PERIOD_SECONDS")] = 86400 * 3; // 3 days voting period
        protocolParameters[keccak256("MIN_VOTES_TO_PASS_PROPOSAL")] = 1; // Minimal for demo, should be higher
        protocolParameters[keccak256("PONDER_COOLDOWN_SECONDS")] = 1 hours; // Cooldown for ponderAndDiscoverNewTrait
        protocolParameters[keccak256("MIN_PONDER_ESSENCE_REWARD")] = 2000; // Reward for triggering ponder
        protocolParameters[keccak256("FRAGMENT_ACTION_COOLDOWN_SECONDS")] = 30 minutes; // Cooldown for cultivation/mutation per fragment

        // Initial trait values for newly minted fragments
        protocolParameters[keccak256("INITIAL_STRENGTH")] = 50;
        protocolParameters[keccak256("INITIAL_RESILIENCE")] = 50;
        protocolParameters[keccak256("INITIAL_ADAPTABILITY")] = 50;
        protocolParameters[keccak256("INITIAL_MYSTICISM")] = 20;
        protocolParameters[keccak256("INITIAL_INTELLIGENCE")] = 40;
        protocolParameters[keccak256("INITIAL_CHARM")] = 30;
        protocolParameters[keccak256("INITIAL_GROWTH_RATE")] = 10; // Small % growth per action
        protocolParameters[keccak256("INITIAL_ENERGY_EFFICIENCY")] = 100; // 100 means no cost modification
    }

    // --- Modifiers ---

    modifier onlyFragmentOwnerOrApproved(uint256 fragmentId) {
        require(_isApprovedOrOwner(msg.sender, fragmentId), "Not fragment owner or approved operator");
        _;
    }

    modifier requiresEssence(uint256 amount) {
        // Ensure Essence balance is up-to-date before checking
        _accruePendingEssence(msg.sender);
        require(_essenceBalances[msg.sender] >= amount, "Insufficient Evolutionary Essence");
        _;
    }

    // --- I. Fragment Lifecycle & Evolution ---

    /**
     * @notice Mints a new Genesis Fragment NFT, initializing its base traits.
     * @param name The name of the new fragment.
     * @param initialTraits A uint array representing specific initial trait values. If shorter than TraitType count, defaults are used.
     * @dev Automatically sets initial metadata URI.
     */
    function mintGenesisFragment(string memory name, uint256[] memory initialTraits) external {
        _nextFragmentId.increment();
        uint256 newFragmentId = _nextFragmentId.current();

        _safeMint(msg.sender, newFragmentId); // Using _safeMint

        FragmentState storage fragment = _genesisFragments[newFragmentId];
        fragment.id = newFragmentId;
        fragment.owner = msg.sender;
        fragment.creationTime = block.timestamp;
        fragment.lastEvolutionTime = block.timestamp;
        fragment.evolutionStage = 0; // Initial stage (e.g., "Seed" or "Larva")
        fragment.name = name;
        fragment.currentMetadataURI = string(abi.encodePacked(
            "ipfs://chronogenesis/fragment-metadata/", newFragmentId.toString(), ".json" // Placeholder URI
        ));

        // Initialize traits using provided values or defaults from protocol parameters
        fragment.traits[TraitType.Strength] = initialTraits.length > uint256(TraitType.Strength) ? initialTraits[uint256(TraitType.Strength)] : protocolParameters[keccak256("INITIAL_STRENGTH")];
        fragment.traits[TraitType.Resilience] = initialTraits.length > uint256(TraitType.Resilience) ? initialTraits[uint256(TraitType.Resilience)] : protocolParameters[keccak256("INITIAL_RESILIENCE")];
        fragment.traits[TraitType.Adaptability] = initialTraits.length > uint256(TraitType.Adaptability) ? initialTraits[uint256(TraitType.Adaptability)] : protocolParameters[keccak256("INITIAL_ADAPTABILITY")];
        fragment.traits[TraitType.Mysticism] = initialTraits.length > uint256(TraitType.Mysticism) ? initialTraits[uint256(TraitType.Mysticism)] : protocolParameters[keccak256("INITIAL_MYSTICISM")];
        fragment.traits[TraitType.Intelligence] = initialTraits.length > uint256(TraitType.Intelligence) ? initialTraits[uint256(TraitType.Intelligence)] : protocolParameters[keccak256("INITIAL_INTELLIGENCE")];
        fragment.traits[TraitType.Charm] = initialTraits.length > uint256(TraitType.Charm) ? initialTraits[uint256(TraitType.Charm)] : protocolParameters[keccak256("INITIAL_CHARM")];
        fragment.traits[TraitType.GrowthRate] = initialTraits.length > uint256(TraitType.GrowthRate) ? initialTraits[uint256(TraitType.GrowthRate)] : protocolParameters[keccak256("INITIAL_GROWTH_RATE")];
        fragment.traits[TraitType.EnergyEfficiency] = initialTraits.length > uint256(TraitType.EnergyEfficiency) ? initialTraits[uint256(TraitType.EnergyEfficiency)] : protocolParameters[keccak256("INITIAL_ENERGY_EFFICIENCY")];

        // Record initial state hash for history
        fragment.evolutionHistoryHashes.push(_calculateFragmentStateHash(newFragmentId));

        emit FragmentMinted(newFragmentId, msg.sender, name, block.timestamp);
        _notifyObservers(newFragmentId, msg.sender, "minted", _calculateFragmentStateHash(newFragmentId));
    }

    /**
     * @notice Retrieves comprehensive details of a specific fragment.
     * @param fragmentId The ID of the fragment.
     * @return A tuple containing all fragment state data.
     */
    function getFragmentDetails(uint256 fragmentId)
        public view
        returns (
            uint256 id,
            address owner,
            uint256 creationTime,
            uint256 lastEvolutionTime,
            uint256 evolutionStage,
            string memory name,
            string memory currentMetadataURI,
            uint256 totalEssenceSpent,
            uint256 lastActionBlock,
            uint256 strength,
            uint256 resilience,
            uint256 adaptability,
            uint256 mysticism,
            uint256 intelligence,
            uint256 charm,
            uint256 growthRate,
            uint256 energyEfficiency
        )
    {
        FragmentState storage fragment = _genesisFragments[fragmentId];
        require(_exists(fragmentId), "Fragment does not exist");

        id = fragment.id;
        owner = fragment.owner; // This is the owner stored in our struct, could differ from ERC721 owner if transferred
        creationTime = fragment.creationTime;
        lastEvolutionTime = fragment.lastEvolutionTime;
        evolutionStage = fragment.evolutionStage;
        name = fragment.name;
        currentMetadataURI = fragment.currentMetadataURI;
        totalEssenceSpent = fragment.totalEssenceSpent;
        lastActionBlock = fragment.lastActionBlock;
        strength = fragment.traits[TraitType.Strength];
        resilience = fragment.traits[TraitType.Resilience];
        adaptability = fragment.traits[TraitType.Adaptability];
        mysticism = fragment.traits[TraitType.Mysticism];
        intelligence = fragment.traits[TraitType.Intelligence];
        charm = fragment.traits[TraitType.Charm];
        growthRate = fragment.traits[TraitType.GrowthRate];
        energyEfficiency = fragment.traits[TraitType.EnergyEfficiency];
    }

    /**
     * @notice Returns a record of past major trait changes for a fragment.
     * @param fragmentId The ID of the fragment.
     * @return An array of hashes, each representing a snapshot of the fragment's state after a major evolution.
     * @dev This provides an immutable history of evolution.
     */
    function getFragmentEvolutionHistory(uint256 fragmentId) public view returns (bytes32[] memory) {
        require(_exists(fragmentId), "Fragment does not exist");
        return _genesisFragments[fragmentId].evolutionHistoryHashes;
    }

    /**
     * @notice Allows owner or approved operator to spend Essence to gently influence a fragment's trait.
     * @dev Traits will typically increase. The magnitude depends on influencePower, fragment's GrowthRate, and environmental factors.
     * @param fragmentId The ID of the fragment to cultivate.
     * @param traitToInfluence The specific trait to attempt to influence.
     * @param influencePower A modifier for how much influence is applied (e.g., 1-100).
     */
    function cultivateFragment(uint256 fragmentId, TraitType traitToInfluence, uint256 influencePower)
        external
        onlyFragmentOwnerOrApproved(fragmentId)
    {
        FragmentState storage fragment = _genesisFragments[fragmentId];
        require(block.timestamp >= fragment.lastActionBlock.add(protocolParameters[keccak256("FRAGMENT_ACTION_COOLDOWN_SECONDS")]), "Fragment is on action cooldown");
        require(influencePower > 0 && influencePower <= 100, "Influence power must be between 1 and 100");

        uint256 essenceCost = protocolParameters[keccak256("CULTIVATION_BASE_ESSENCE_COST")];
        // Adjust cost based on fragment's energy efficiency (higher efficiency reduces cost)
        essenceCost = essenceCost.mul(100).div(fragment.traits[TraitType.EnergyEfficiency] + 10); // +10 to prevent div by zero, arbitrary scale

        _spendEssence(msg.sender, essenceCost);
        fragment.totalEssenceSpent = fragment.totalEssenceSpent.add(essenceCost);

        // Apply influence: example logic
        // Trait increase based on influencePower, fragment's GrowthRate, and a minor environmental factor
        uint256 environmentalImpact = _getEnvironmentalImpact(traitToInfluence);
        uint256 increaseAmount = (influencePower.mul(fragment.traits[TraitType.GrowthRate]).div(100)).add(environmentalImpact.div(500)); // Arbitrary formula
        increaseAmount = increaseAmount.add(1); // Ensure at least 1 increase
        fragment.traits[traitToInfluence] = fragment.traits[traitToInfluence].add(increaseAmount);

        fragment.lastActionBlock = block.timestamp;
        emit FragmentCultivated(fragmentId, msg.sender, traitToInfluence, influencePower, essenceCost);
        _notifyObservers(fragmentId, msg.sender, "cultivated", _calculateFragmentStateHash(fragmentId));
    }

    /**
     * @notice Initiates a probabilistic, potentially drastic mutation in a fragment's traits, consuming more Essence.
     * @dev Mutations can be positive or negative, reflecting uncertainty. Success chance might be influenced by Adaptability.
     * @param fragmentId The ID of the fragment to mutate.
     */
    function triggerMutationEvent(uint256 fragmentId)
        external
        onlyFragmentOwnerOrApproved(fragmentId)
    {
        FragmentState storage fragment = _genesisFragments[fragmentId];
        require(block.timestamp >= fragment.lastActionBlock.add(protocolParameters[keccak256("FRAGMENT_ACTION_COOLDOWN_SECONDS")]), "Fragment is on action cooldown");

        uint256 essenceCost = protocolParameters[keccak256("MUTATION_BASE_ESSENCE_COST")];
        essenceCost = essenceCost.mul(100).div(fragment.traits[TraitType.EnergyEfficiency] + 10); // Adjust cost

        _spendEssence(msg.sender, essenceCost);
        fragment.totalEssenceSpent = fragment.totalEssenceSpent.add(essenceCost);

        // Determine mutation success based on fragment's Adaptability and a pseudo-random factor
        uint256 successChance = protocolParameters[keccak256("MUTATION_BASE_SUCCESS_CHANCE_PERCENT")].add(fragment.traits[TraitType.Adaptability].div(50)); // Adaptability boosts chance
        if (successChance > 90) successChance = 90; // Cap success chance for realism

        bool mutationSuccessful = (_generateRandomNumber(fragmentId, block.timestamp, block.difficulty) % 100) < successChance;
        emit FragmentMutated(fragmentId, msg.sender, essenceCost, mutationSuccessful);

        if (mutationSuccessful) {
            // Apply a random, significant change to a random trait
            TraitType randomTrait = TraitType(_generateRandomNumber(fragmentId, block.number, block.difficulty) % uint256(TraitType.EnergyEfficiency + 1));
            uint256 changeMagnitude = _generateRandomNumber(fragmentId, block.timestamp.add(1), block.gaslimit) % 150; // Max 150 units change
            if (changeMagnitude > 75) { // Simulate positive swing
                fragment.traits[randomTrait] = fragment.traits[randomTrait].add(changeMagnitude.sub(75));
            } else { // Simulate negative swing
                fragment.traits[randomTrait] = fragment.traits[randomTrait].sub(changeMagnitude);
            }
            fragment.lastEvolutionTime = block.timestamp;
            fragment.evolutionHistoryHashes.push(_calculateFragmentStateHash(fragmentId)); // Record major change
        } else {
            // Minor penalty for failed mutation, e.g., slight loss of energy efficiency
            if (fragment.traits[TraitType.EnergyEfficiency] > 10) {
                fragment.traits[TraitType.EnergyEfficiency] = fragment.traits[TraitType.EnergyEfficiency].sub(10);
            }
        }
        fragment.lastActionBlock = block.timestamp;
        _notifyObservers(fragmentId, msg.sender, "mutated", _calculateFragmentStateHash(fragmentId));
    }

    /**
     * @notice Triggers a major evolutionary leap for a fragment that meets specific criteria, potentially transforming its type.
     * @dev This is an "end-game" evolution that moves a fragment to a new "stage" with new base traits or abilities.
     * @param fragmentId The ID of the fragment to ascend.
     */
    function ascendFragment(uint256 fragmentId)
        external
        onlyFragmentOwnerOrApproved(fragmentId)
    {
        FragmentState storage fragment = _genesisFragments[fragmentId];
        require(fragment.evolutionStage < 3, "Fragment has reached maximum ascension stage"); // Max 3 stages for example
        
        // Example criteria for ascension (can be complex and multi-faceted):
        require(fragment.traits[TraitType.Strength] >= 250 || fragment.traits[TraitType.Intelligence] >= 250, "Fragment does not meet ascension criteria (e.g., Strength or Intelligence >= 250)");
        require(fragment.totalEssenceSpent >= protocolParameters[keccak256("ASCENSION_BASE_ESSENCE_COST")].mul(5), "Not enough cumulative Essence spent for ascension");

        uint256 essenceCost = protocolParameters[keccak256("ASCENSION_BASE_ESSENCE_COST")];
        _spendEssence(msg.sender, essenceCost);
        fragment.totalEssenceSpent = fragment.totalEssenceSpent.add(essenceCost);

        fragment.evolutionStage = fragment.evolutionStage.add(1);
        fragment.lastEvolutionTime = block.timestamp;

        // Apply stage-specific trait bonuses/resets and update name/metadata hint
        if (fragment.evolutionStage == 1) {
            fragment.traits[TraitType.Strength] = fragment.traits[TraitType.Strength].add(75);
            fragment.traits[TraitType.Resilience] = fragment.traits[TraitType.Resilience].add(50);
            fragment.name = string(abi.encodePacked("Evolved ", fragment.name));
        } else if (fragment.evolutionStage == 2) {
            fragment.traits[TraitType.Intelligence] = fragment.traits[TraitType.Intelligence].add(150);
            fragment.traits[TraitType.Mysticism] = fragment.traits[TraitType.Mysticism].add(100);
            fragment.name = string(abi.encodePacked("Advanced ", fragment.name));
        } else if (fragment.evolutionStage == 3) {
            fragment.traits[TraitType.Charm] = fragment.traits[TraitType.Charm].add(200);
            fragment.traits[TraitType.GrowthRate] = fragment.traits[TraitType.GrowthRate].add(50); // Significant growth boost
            fragment.name = string(abi.encodePacked("Ascended ", fragment.name));
        }
        
        fragment.evolutionHistoryHashes.push(_calculateFragmentStateHash(fragmentId)); // Record major change
        emit FragmentAscended(fragmentId, msg.sender, fragment.evolutionStage);
        _notifyObservers(fragmentId, msg.sender, "ascended", _calculateFragmentStateHash(fragmentId));
    }

    /**
     * @notice Protocol-level function that simulates discovery of new potential traits or evolution paths based on aggregated data.
     * @dev This function can be called by anyone. It has a cooldown and rewards the caller with Essence.
     *      It signifies a conceptual advancement in the ecosystem's understanding of evolution.
     */
    function ponderAndDiscoverNewTrait() external returns (bytes32 discoveredTraitHash) {
        require(block.timestamp > _lastPonderCallTime.add(protocolParameters[keccak256("PONDER_COOLDOWN_SECONDS")]), "Pondering is on cooldown");

        _lastPonderCallTime = block.timestamp;

        // Simulate discovery based on current ecosystem state (e.g., total fragments, average traits, environment)
        // For simplicity, generates a "new trait" hash. In a full system, this could trigger:
        // 1. A new `EvolutionProposal` automatically.
        // 2. Unlocking a new `TraitType` (if enum was extensible, which is complex).
        // 3. Modifying underlying evolution formulas stored as state.
        bytes32 newDiscoverySeed = keccak256(abi.encodePacked(
            block.timestamp, block.number, block.difficulty, _nextFragmentId.current(),
            _getEnvironmentalImpact(TraitType.Adaptability), // Influence by environment
            address(this) // Add contract address as a seed
        ));
        discoveredTraitHash = keccak256(abi.encodePacked("DiscoveryOf_", newDiscoverySeed));

        emit NewTraitDiscovered(discoveredTraitHash, "A new latent evolutionary path has been discovered!");

        // Reward the caller for triggering this process
        _essenceBalances[msg.sender] = _essenceBalances[msg.sender].add(protocolParameters[keccak256("MIN_PONDER_ESSENCE_REWARD")]);
        emit EssenceClaimed(msg.sender, protocolParameters[keccak256("MIN_PONDER_ESSENCE_REWARD")]);

        return discoveredTraitHash;
    }

    /**
     * @notice Public/DAO callable function that applies global environmental modifiers to all fragments or specific types based on oracle data.
     * @dev This function simulates global changes that affect all fragments. Can be called by anyone (with implied cooldown for spam prevention in a real system).
     */
    uint256 public _lastEnvironmentalShiftBlock;
    function triggerEnvironmentalShift() external {
        // Implement a cooldown if this is callable by anyone, or restrict to DAO
        require(block.number > _lastEnvironmentalShiftBlock.add(50), "Environmental shift is on cooldown"); // Example 50 block cooldown
        _lastEnvironmentalShiftBlock = block.number;

        // Fetch mock environmental factors
        uint256 globalVolcanoActivity = _environmentalOracle.getEnvironmentalFactor("VolcanoActivity");
        uint256 globalSolarFlareIntensity = _environmentalOracle.getEnvironmentalFactor("SolarFlareIntensity");
        uint256 marketVolatilityIndex = _environmentalOracle.getEnvironmentalFactor("MarketVolatility");

        // Affects all fragments (simplified iteration)
        for (uint256 i = 1; i <= _nextFragmentId.current(); i++) {
            FragmentState storage fragment = _genesisFragments[i];
            if (!_exists(i)) continue; // Skip non-existent fragments (e.g., burned)

            // Example effects:
            // High volcano activity reduces resilience, potentially boosts strength
            if (globalVolcanoActivity > 100) {
                uint256 resilienceReduction = globalVolcanoActivity.div(50);
                if (fragment.traits[TraitType.Resilience] > resilienceReduction) {
                    fragment.traits[TraitType.Resilience] = fragment.traits[TraitType.Resilience].sub(resilienceReduction);
                } else {
                    fragment.traits[TraitType.Resilience] = 0;
                }
                fragment.traits[TraitType.Strength] = fragment.traits[TraitType.Strength].add(globalVolcanoActivity.div(100)); // Boost strength
            }
            // High solar flares boost mysticism and adaptability
            fragment.traits[TraitType.Mysticism] = fragment.traits[TraitType.Mysticism].add(globalSolarFlareIntensity.div(30));
            fragment.traits[TraitType.Adaptability] = fragment.traits[TraitType.Adaptability].add(globalSolarFlareIntensity.div(50));

            // High market volatility impacts intelligence negatively, but charm positively (social adaptation)
            if (marketVolatilityIndex > 50) {
                uint256 intelReduction = marketVolatilityIndex.div(20);
                if (fragment.traits[TraitType.Intelligence] > intelReduction) {
                    fragment.traits[TraitType.Intelligence] = fragment.traits[TraitType.Intelligence].sub(intelReduction);
                } else {
                    fragment.traits[TraitType.Intelligence] = 0;
                }
                fragment.traits[TraitType.Charm] = fragment.traits[TraitType.Charm].add(marketVolatilityIndex.div(10));
            }
            fragment.lastEvolutionTime = block.timestamp; // Mark as affected by environment
            _notifyObservers(i, fragment.owner, "environmental_shift", _calculateFragmentStateHash(i));
        }

        emit EnvironmentalShiftApplied("VolcanoActivity", globalVolcanoActivity, block.number);
        emit EnvironmentalShiftApplied("SolarFlareIntensity", globalSolarFlareIntensity, block.number);
        emit EnvironmentalShiftApplied("MarketVolatility", marketVolatilityIndex, block.number);
    }

    /**
     * @notice Allows the fragment owner or approved operator to update the URI pointing to its visual/descriptive metadata.
     * @param fragmentId The ID of the fragment.
     * @param newURI The new URI for the fragment's metadata.
     */
    function updateFragmentMetadataURI(uint256 fragmentId, string memory newURI) external onlyFragmentOwnerOrApproved(fragmentId) {
        require(bytes(newURI).length > 0, "URI cannot be empty");
        _genesisFragments[fragmentId].currentMetadataURI = newURI;
        emit FragmentMetadataURIUpdated(fragmentId, newURI);
    }

    // --- II. Evolutionary Essence (Internal Resource System) ---

    /**
     * @notice Allows users to stake native tokens (ETH/MATIC etc.) to accrue Evolutionary Essence over time.
     * @dev Essence accrues based on staked amount and time.
     */
    function stakeForEvolutionaryEssence() external payable {
        require(msg.value > 0, "Must stake a positive amount");

        _accruePendingEssence(msg.sender); // Claim any pending essence before updating stake

        _stakedNativeTokens[msg.sender] = _stakedNativeTokens[msg.sender].add(msg.value);
        _lastEssenceClaimTime[msg.sender] = block.timestamp; // Reset claim time to start accruing from now

        emit EssenceStaked(msg.sender, msg.value, _stakedNativeTokens[msg.sender]);
    }

    /**
     * @notice Allows users to retrieve their staked native tokens.
     * @param amount The amount of native tokens to unstake.
     */
    function unstakeEvolutionaryEssence(uint256 amount) external {
        require(_stakedNativeTokens[msg.sender] >= amount, "Not enough staked tokens");

        _accruePendingEssence(msg.sender); // Claim any pending essence before unstaking

        _stakedNativeTokens[msg.sender] = _stakedNativeTokens[msg.sender].sub(amount);
        _lastEssenceClaimTime[msg.sender] = block.timestamp; // Update claim time for remaining stake

        (bool sent, ) = msg.sender.call{value: amount}("");
        require(sent, "Failed to send native tokens back");

        emit EssenceUnstaked(msg.sender, amount, _stakedNativeTokens[msg.sender]);
    }

    /**
     * @notice Allows users to claim their accrued Essence.
     * @dev Essence is calculated based on staked amount and time since last claim.
     */
    function claimEvolutionaryEssence() external {
        _accruePendingEssence(msg.sender); // This function does the actual claiming and event emission
    }

    /**
     * @notice Checks an account's current liquid (claimed + pending) Essence balance.
     * @param account The address to check.
     * @return The current Essence balance.
     */
    function getEvolutionaryEssenceBalance(address account) public view returns (uint256) {
        return _essenceBalances[account].add(_calculatePendingEssence(account));
    }

    /**
     * @notice Allows users to transfer their Essence to another address.
     * @param recipient The address to send Essence to.
     * @param amount The amount of Essence to transfer.
     */
    function transferEvolutionaryEssence(address recipient, uint256 amount) external {
        require(recipient != address(0), "Cannot transfer to zero address");
        require(recipient != msg.sender, "Cannot transfer to self");
        require(amount > 0, "Transfer amount must be positive");

        _spendEssence(msg.sender, amount); // This function also accrues pending essence for msg.sender

        _essenceBalances[recipient] = _essenceBalances[recipient].add(amount);

        emit EssenceTransferred(msg.sender, recipient, amount);
    }

    // --- III. Governance & Protocol Parameters ---

    /**
     * @notice Allows users to propose changes to evolution rules for specific traits.
     * @dev Requires a minimum Essence balance to submit.
     * @param targetFragmentId If 0, proposal is for a general rule change; otherwise, for a specific fragment.
     * @param traitType The trait category the rule applies to.
     * @param newEvolutionRuleHash A hash representing the proposed new rule (actual rule logic is abstracted for on-chain storage).
     * @param description A string description of the proposed rule.
     */
    function submitEvolutionPathProposal(uint256 targetFragmentId, TraitType traitType, bytes32 newEvolutionRuleHash, string memory description)
        external
        requiresEssence(protocolParameters[keccak256("MIN_ESSENCE_TO_SUBMIT_PROPOSAL")])
    {
        _nextEvolutionProposalId.increment();
        uint256 proposalId = _nextEvolutionProposalId.current();

        EvolutionProposal storage proposal = evolutionProposals[proposalId];
        proposal.proposalId = proposalId;
        proposal.targetFragmentId = targetFragmentId;
        proposal.traitType = traitType;
        proposal.newEvolutionRuleHash = newEvolutionRuleHash;
        proposal.description = description;
        proposal.submissionTime = block.timestamp;
        proposal.votingDeadline = block.timestamp.add(protocolParameters[keccak256("VOTING_PERIOD_SECONDS")]);
        proposal.status = ProposalStatus.Pending;

        emit EvolutionProposalSubmitted(proposalId, msg.sender, targetFragmentId, traitType, newEvolutionRuleHash);
    }

    /**
     * @notice Allows users to vote on an evolution path proposal.
     * @dev Requires Essence balance to vote. Voting power is proportional to caller's current Essence.
     * @param proposalId The ID of the proposal to vote on.
     * @param support True for 'for', false for 'against'.
     */
    function voteOnEvolutionProposal(uint256 proposalId, bool support) external {
        EvolutionProposal storage proposal = evolutionProposals[proposalId];
        require(proposal.status == ProposalStatus.Pending, "Proposal is not active");
        require(block.timestamp <= proposal.votingDeadline, "Voting period has ended");
        require(!proposal.hasVoted[msg.sender], "Already voted on this proposal");

        uint256 voterEssence = getEvolutionaryEssenceBalance(msg.sender); // Use liquid essence as voting power
        require(voterEssence > 0, "Must have Essence to vote");

        if (support) {
            proposal.votesFor = proposal.votesFor.add(voterEssence);
        } else {
            proposal.votesAgainst = proposal.votesAgainst.add(voterEssence);
        }
        proposal.hasVoted[msg.sender] = true;

        emit VoteCast(proposalId, msg.sender, support, true);
    }

    /**
     * @notice Executes a passed evolution path proposal.
     * @dev Can be called by anyone after the voting period, if the proposal has passed.
     *      The actual "rule change" implementation is abstracted by `newEvolutionRuleHash`.
     */
    function executeEvolutionPathProposal(uint256 proposalId) external {
        EvolutionProposal storage proposal = evolutionProposals[proposalId];
        require(proposal.status == ProposalStatus.Pending, "Proposal is not pending");
        require(block.timestamp > proposal.votingDeadline, "Voting period has not ended");

        if (proposal.votesFor > proposal.votesAgainst && proposal.votesFor >= protocolParameters[keccak256("MIN_VOTES_TO_PASS_PROPOSAL")]) {
            proposal.status = ProposalStatus.Approved;
            // Here, in a full system, the `newEvolutionRuleHash` would be used to update
            // a global mapping of active evolution rules or directly call a rule-implementing contract.
            // For this example, we simply mark it as approved, demonstrating the governance flow.
            emit ProposalExecuted(proposalId, true, true);
        } else {
            proposal.status = ProposalStatus.Rejected;
            emit ProposalExecuted(proposalId, true, false);
        }
    }

    /**
     * @notice Allows users to propose changes to core protocol parameters (e.g., costs, cooldowns).
     * @dev Requires a minimum Essence balance to submit.
     * @param parameterKey The keccak256 hash of the parameter name (e.g., keccak256("CULTIVATION_BASE_ESSENCE_COST")).
     * @param newValue The new value for the parameter.
     * @param description A string description of the proposed change.
     */
    function submitProtocolParameterProposal(bytes32 parameterKey, uint256 newValue, string memory description)
        external
        requiresEssence(protocolParameters[keccak256("MIN_ESSENCE_TO_SUBMIT_PROPOSAL")])
    {
        _nextParameterProposalId.increment();
        uint256 proposalId = _nextParameterProposalId.current();

        ParameterProposal storage proposal = parameterProposals[proposalId];
        proposal.proposalId = proposalId;
        proposal.parameterKey = parameterKey;
        proposal.newValue = newValue;
        proposal.description = description;
        proposal.submissionTime = block.timestamp;
        proposal.votingDeadline = block.timestamp.add(protocolParameters[keccak256("VOTING_PERIOD_SECONDS")]);
        proposal.status = ProposalStatus.Pending;

        emit ParameterProposalSubmitted(proposalId, msg.sender, parameterKey, newValue);
    }

    /**
     * @notice Allows users to vote on a protocol parameter proposal.
     * @dev Requires Essence balance to vote.
     * @param proposalId The ID of the proposal to vote on.
     * @param support True for 'for', false for 'against'.
     */
    function voteOnProtocolParameterProposal(uint256 proposalId, bool support) external {
        ParameterProposal storage proposal = parameterProposals[proposalId];
        require(proposal.status == ProposalStatus.Pending, "Proposal is not active");
        require(block.timestamp <= proposal.votingDeadline, "Voting period has ended");
        require(!proposal.hasVoted[msg.sender], "Already voted on this proposal");

        uint256 voterEssence = getEvolutionaryEssenceBalance(msg.sender); // Use liquid essence as voting power
        require(voterEssence > 0, "Must have Essence to vote");

        if (support) {
            proposal.votesFor = proposal.votesFor.add(voterEssence);
        } else {
            proposal.votesAgainst = proposal.votesAgainst.add(voterEssence);
        }
        proposal.hasVoted[msg.sender] = true;

        emit VoteCast(proposalId, msg.sender, support, false);
    }

    /**
     * @notice Executes a passed protocol parameter proposal.
     * @dev Can be called by anyone after the voting period, if the proposal has passed.
     *      Updates the relevant `protocolParameters` mapping.
     * @param proposalId The ID of the proposal to execute.
     */
    function executeProtocolParameterChange(uint256 proposalId) external {
        ParameterProposal storage proposal = parameterProposals[proposalId];
        require(proposal.status == ProposalStatus.Pending, "Proposal is not pending");
        require(block.timestamp > proposal.votingDeadline, "Voting period has not ended");

        if (proposal.votesFor > proposal.votesAgainst && proposal.votesFor >= protocolParameters[keccak256("MIN_VOTES_TO_PASS_PROPOSAL")]) {
            proposal.status = ProposalStatus.Approved;
            protocolParameters[proposal.parameterKey] = proposal.newValue;
            emit ProposalExecuted(proposalId, false, true);
        } else {
            proposal.status = ProposalStatus.Rejected;
            emit ProposalExecuted(proposalId, false, false);
        }
    }

    // --- IV. Utility & Ecosystem Management ---

    /**
     * @notice Sets the address of the external environmental oracle.
     * @dev Only the `_protocolDAO` (contract owner) can call this.
     * @param oracleAddress The new address for the oracle.
     */
    function setEnvironmentalOracle(address oracleAddress) external onlyOwner {
        require(oracleAddress != address(0), "Invalid oracle address");
        address oldOracle = address(_environmentalOracle);
        _environmentalOracle = IEnvironmentalOracle(oracleAddress);
        emit OracleUpdated(oldOracle, oracleAddress);
    }

    /**
     * @notice Retrieves the current value of a protocol parameter.
     * @param parameterKey The keccak256 hash of the parameter name.
     * @return The value of the parameter.
     */
    function getProtocolParameter(bytes32 parameterKey) public view returns (uint256) {
        return protocolParameters[parameterKey];
    }

    /**
     * @notice Allows other contracts to register to receive notifications on fragment state changes.
     * @dev Observer contracts must implement `IFragmentObserver` interface. Callable by `_protocolDAO`.
     * @param observerContract The address of the contract to register as an observer.
     */
    function registerFragmentObserver(address observerContract) external onlyOwner {
        require(observerContract != address(0), "Invalid observer address");
        for (uint256 i = 0; i < _fragmentObservers.length; i++) {
            require(_fragmentObservers[i] != observerContract, "Observer already registered");
        }
        _fragmentObservers.push(observerContract);
    }

    /**
     * @notice Records a global snapshot of key ecosystem metrics for historical analysis or future forks.
     * @dev This could store a hash of the entire state or just key aggregated metrics. Callable by anyone.
     * @param snapshotLabel A label for this snapshot (e.g., "Epoch 1 End").
     */
    function snapshotEcosystemState(string memory snapshotLabel) external {
        // In a more robust system, this might involve hashing core state variables
        // or aggregating ecosystem-wide metrics (e.g., total Essence in circulation, average trait values).
        emit EcosystemSnapshot(snapshotLabel, block.number, _nextFragmentId.current());
    }

    /**
     * @notice Allows users to send funds to support protocol development and maintenance.
     * @dev Funds go to the contract's address (treasury).
     */
    function donateToEcosystemTreasury() external payable {
        require(msg.value > 0, "Donation amount must be positive");
        emit TreasuryDonation(msg.sender, msg.value);
    }

    /**
     * @notice Allows the `_protocolDAO` (contract owner) to withdraw funds from the treasury.
     * @dev For emergency or planned operational withdrawals.
     * @param recipient The address to send funds to.
     * @param amount The amount of native tokens to withdraw.
     */
    function withdrawFromTreasury(address recipient, uint256 amount) external onlyOwner {
        require(address(this).balance >= amount, "Insufficient treasury balance");
        require(recipient != address(0), "Invalid recipient address");

        (bool sent, ) = recipient.call{value: amount}("");
        require(sent, "Failed to send native tokens from treasury");

        emit TreasuryWithdrawal(recipient, amount);
    }

    // --- Internal & Private Helper Functions ---

    /**
     * @dev Internal function to calculate and add pending Essence to an account's balance.
     * @param account The address for which to accrue Essence.
     */
    function _accruePendingEssence(address account) internal {
        uint256 pendingEssence = _calculatePendingEssence(account);
        if (pendingEssence > 0) {
            _essenceBalances[account] = _essenceBalances[account].add(pendingEssence);
            _lastEssenceClaimTime[account] = block.timestamp;
            emit EssenceClaimed(account, pendingEssence);
        }
    }

    /**
     * @dev Calculates the amount of Essence an account has accrued since last claim.
     * @param account The address to check.
     * @return The amount of pending Essence.
     */
    function _calculatePendingEssence(address account) internal view returns (uint256) {
        uint256 stakedAmount = _stakedNativeTokens[account];
        if (stakedAmount == 0) {
            return 0;
        }
        uint256 timeElapsed = block.timestamp.sub(_lastEssenceClaimTime[account]);
        // Linear accrual: stakedAmount * timeElapsed * ESSENCE_PER_NATIVE_UNIT_PER_SECOND (scaled by 1e18 for native token units)
        uint256 essencePerUnitPerSecond = protocolParameters[keccak256("ESSENCE_PER_NATIVE_UNIT_PER_SECOND")];
        return stakedAmount.mul(timeElapsed).mul(essencePerUnitPerSecond).div(1e18); // Assumes stakedAmount is in wei
    }

    /**
     * @dev Internal function to spend Essence from an account. Automatically accrues pending Essence first.
     * @param account The address whose Essence to spend.
     * @param amount The amount of Essence to spend.
     */
    function _spendEssence(address account, uint256 amount) internal {
        _accruePendingEssence(account); // Ensure balance is up-to-date before spending
        require(_essenceBalances[account] >= amount, "Insufficient Essence to perform action");
        _essenceBalances[account] = _essenceBalances[account].sub(amount);
    }

    /**
     * @dev Generates a pseudo-random number for on-chain mechanics.
     * @dev WARNING: On-chain randomness is exploitable. For production, consider Chainlink VRF or similar.
     * @param seed1 First seed.
     * @param seed2 Second seed.
     * @param seed3 Third seed.
     * @return A pseudo-random uint256.
     */
    function _generateRandomNumber(uint256 seed1, uint256 seed2, uint256 seed3) internal view returns (uint256) {
        return uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, block.gaslimit, seed1, seed2, seed3)));
    }

    /**
     * @dev Calculates a hash representing the current state of a fragment. Used for evolution history and verification.
     * @param fragmentId The ID of the fragment.
     * @return A bytes32 hash of the fragment's state.
     */
    function _calculateFragmentStateHash(uint256 fragmentId) internal view returns (bytes32) {
        FragmentState storage fragment = _genesisFragments[fragmentId];
        // Note: Mapping traits need to be iterated or explicitly included. For simplicity, explicit.
        return keccak256(abi.encodePacked(
            fragment.id,
            fragment.owner,
            fragment.creationTime,
            fragment.lastEvolutionTime,
            fragment.evolutionStage,
            fragment.traits[TraitType.Strength],
            fragment.traits[TraitType.Resilience],
            fragment.traits[TraitType.Adaptability],
            fragment.traits[TraitType.Mysticism],
            fragment.traits[TraitType.Intelligence],
            fragment.traits[TraitType.Charm],
            fragment.traits[TraitType.GrowthRate],
            fragment.traits[TraitType.EnergyEfficiency],
            fragment.lastActionBlock,
            fragment.totalEssenceSpent // Include total Essence spent to reflect investment
        ));
    }

    /**
     * @dev Mocks an environmental impact for a given trait by querying the oracle.
     * @dev In a real scenario, this would involve more complex oracle interactions and interpretation.
     */
    function _getEnvironmentalImpact(TraitType traitType) internal view returns (uint256) {
        // Simplified mock logic for how different factors might influence traits
        if (traitType == TraitType.Adaptability) {
            return _environmentalOracle.getEnvironmentalFactor("VolatilityIndex"); // Higher volatility might boost adaptability
        }
        if (traitType == TraitType.GrowthRate) {
            return _environmentalOracle.getEnvironmentalFactor("GlobalEnergyLevels"); // Abundant energy might boost growth
        }
        if (traitType == TraitType.Strength) {
            return _environmentalOracle.getEnvironmentalFactor("GeomagneticActivity"); // Strong geomagnetic activity might affect strength
        }
        return _environmentalOracle.getEnvironmentalFactor("CosmicDustIndex"); // Default factor
    }

    /**
     * @dev Notifies registered observer contracts of a fragment state change.
     * @param fragmentId The ID of the changed fragment.
     * @param owner The current owner of the fragment.
     * @param eventType A string describing the type of change (e.g., "cultivated", "mutated").
     * @param eventDataHash A hash representing the data related to the event (e.g., new state hash).
     */
    function _notifyObservers(uint256 fragmentId, address owner, string memory eventType, bytes32 eventDataHash) internal {
        for (uint256 i = 0; i < _fragmentObservers.length; i++) {
            // Using a try-catch to prevent a single failing observer from breaking the entire transaction
            try IFragmentObserver(_fragmentObservers[i]).onFragmentChange(fragmentId, owner, eventType, eventDataHash) {} catch {}
        }
    }

    // --- ERC721 Metadata URI Override ---
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        return _genesisFragments[tokenId].currentMetadataURI;
    }

    // Override _beforeTokenTransfer to keep fragment.owner updated if ERC721 owner changes
    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize) internal override {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
        if (_exists(tokenId)) { // Check if the token exists to prevent issues with mint/burn
            _genesisFragments[tokenId].owner = to;
            // Optionally, add logic here for what happens to fragment traits on transfer
            // E.g., some traits might reset or decay, or the fragment enters a "dormant" state.
        }
    }
}
```