Okay, this is an ambitious request! Creating a truly unique, advanced, and trendy smart contract with 20+ functions is challenging within a single example while avoiding *any* duplication of common open-source patterns.

My approach will be to design a contract around a concept I call "Evolving Digital Artifacts" or "ChronoForms". These are NFTs (inheriting from a basic ERC721-like structure, but with custom logic to avoid direct OZ copy-paste *for the core features*) that have internal states (energy, maturity, traits) that change over time and through user interactions. The contract will incorporate mechanics like feeding, harvesting, decaying, forging (combining), and a simple internal governance mechanism driven by artifact ownership.

**Concept:** ChronoForms are unique digital entities (NFTs) that require care and interaction. They possess energy that decays over time, and maturity that increases. Users can "feed" them to restore energy and influence traits, "harvest" from mature forms to gain internal resources, "evolve" them to change their status, and "forge" two forms together to create a new one with inherited/mutated traits. The parameters governing these mechanics can be adjusted through a simple governance system where artifact holders propose and vote on changes.

---

**Outline:**

1.  **SPDX License and Pragma**
2.  **Imports:** Basic interfaces (ERC721-like, ERC165-like). *Will define necessary interfaces internally to avoid direct import dependency for uniqueness, mimicking standard behavior.*
3.  **Error Definitions**
4.  **Enums:** `ArtifactStatus`, `ProposalState`
5.  **Structs:** `Artifact`, `Proposal`
6.  **State Variables:**
    *   Contract ownership (`_owner`)
    *   Artifact Data (`artifacts`, `ownerOf`, `balanceOf`, `artifactExists`)
    *   Token Counter (`_nextTokenId`)
    *   Pausability (`paused`)
    *   Global Parameters (`decayRate`, `harvestYieldBase`, `forgeCost`, etc.)
    *   Essence Parameters (`essenceEffectsEnergy`, `essenceEffectsTraits`)
    *   User Internal Balances (`userSparksBalance`)
    *   Governance Data (`proposals`, `proposalCount`, `artifactVotePower`, `voteDelegations`, `proposalVotes`, `proposalExecutions`)
7.  **Events:** Minting, Interaction, Harvesting, Forging, Decay, Proposal, Voting, Execution.
8.  **Modifiers:** `onlyOwner`, `whenNotPaused`, `whenPaused`, `onlyArtifactOwner`, `artifactExistsModifier`, `canInteractWithArtifact`
9.  **Constructor**
10. **Admin Functions (`onlyOwner`):**
    *   `pause`, `unpause`
    *   `setGlobalParameter` (e.g., decayRate, harvestYieldBase)
    *   `setEssenceEffectParameters`
    *   `withdrawEth`
    *   `setForgeCooldown`
    *   `setMinMaturityForHarvest`
    *   `setMinEnergyForAction`
11. **Artifact Core Functions (ERC721-like - custom logic):**
    *   `mintArtifact`
    *   `transferArtifact` (Custom internal transfer logic, *not* just calling OZ)
    *   `balanceOf`
    *   `ownerOf`
    *   `exists`
    *   `getTokenDetails` (View function)
    *   `totalSupply` (View function)
12. **Artifact Interaction Functions:**
    *   `feedArtifact`
    *   `harvestFromArtifact`
    *   `evolveArtifact`
    *   `forgeArtifact`
    *   `putToDormancy`
    *   `wakeFromDormancy`
13. **Lifecycle & State Update Functions:**
    *   `applyDecay` (Public/Internal helper - allows anyone to trigger decay for an artifact, encouraging network upkeep)
    *   `updateArtifactState` (Internal helper factoring in decay and interactions)
14. **Internal Resource (Sparks) Functions:**
    *   `claimSparks` (Transfers collected sparks to user balance)
    *   `getUserSparksBalance` (View)
15. **Governance Functions:**
    *   `proposeParameterChange`
    *   `voteOnProposal`
    *   `executeProposal`
    *   `delegateVote`
    *   `getProposalDetails` (View)
    *   `getVotePower` (View - based on artifact count + delegation)
    *   `getProposalVoteCount` (View)
    *   `getProposalState` (View)
16. **Helper Functions:**
    *   `_safeMint` (Internal)
    *   `_transferArtifact` (Internal)
    *   `_applyEssenceEffect` (Internal)
    *   `_calculateCurrentDecay` (Internal view)
    *   `_calculateVotePower` (Internal view)

---

**Function Summary:**

1.  `constructor()`: Initializes the contract, setting the owner and initial parameters.
2.  `pause()`: Owner can pause core interactions (feeding, harvesting, forging, evolving).
3.  `unpause()`: Owner can unpause interactions.
4.  `setGlobalParameter(bytes32 paramName, uint256 newValue)`: Owner can set various global numeric parameters (e.g., decay rate, base harvest yield).
5.  `setEssenceEffectParameters(uint256 essenceTypeIndex, int256 energyEffect, int256[] traitEffects)`: Owner configures how different essence types impact energy and traits during feeding.
6.  `withdrawEth(address payable recipient, uint256 amount)`: Owner can withdraw ETH from the contract (e.g., collected from minting fees).
7.  `setForgeCooldown(uint256 duration)`: Owner sets the cooldown period for parent artifacts after forging.
8.  `setMinMaturityForHarvest(uint256 maturity)`: Owner sets the minimum maturity level required to harvest.
9.  `setMinEnergyForAction(uint256 energy)`: Owner sets the minimum energy required for complex actions like harvest/forge/evolve.
10. `mintArtifact(uint256[] calldata initialTraits, uint256 energy)`: Mints a new ChronoForm NFT with specified initial traits and energy. Requires payment.
11. `transferArtifact(address from, address to, uint256 artifactId)`: Custom internal transfer logic for the NFT (updates owner mapping, calls hooks).
12. `balanceOf(address owner) view returns (uint256)`: Returns the number of artifacts owned by an address.
13. `ownerOf(uint256 artifactId) view returns (address)`: Returns the owner of a specific artifact.
14. `exists(uint256 artifactId) view returns (bool)`: Checks if an artifact ID exists.
15. `getTokenDetails(uint256 artifactId) view returns (Artifact memory)`: Retrieves the full details of an artifact.
16. `totalSupply() view returns (uint256)`: Returns the total number of artifacts minted.
17. `feedArtifact(uint256 artifactId, uint256 essenceTypeIndex, uint256 amount)`: Feeds an artifact essence, restoring energy and potentially altering traits.
18. `harvestFromArtifact(uint256 artifactId)`: If mature and energetic enough, allows harvesting internal "Sparks" from the artifact.
19. `evolveArtifact(uint256 artifactId)`: Attempts to evolve the artifact's status based on maturity, energy, and traits.
20. `forgeArtifact(uint256 parent1Id, uint256 parent2Id, uint256[] calldata initialTraits)`: Combines two parent artifacts to mint a new one (parents potentially go on cooldown or lose state).
21. `putToDormancy(uint256 artifactId)`: Manually sets an artifact's status to Dormant (might pause decay).
22. `wakeFromDormancy(uint256 artifactId, uint256 cost)`: Wakes a Dormant artifact (might require a fee/cost).
23. `applyDecay(uint256 artifactId)`: Applies time-based decay to an artifact's energy and maturity since its last update/interaction. Callable by anyone.
24. `claimSparks()`: Allows a user to claim their accumulated internal Sparks balance.
25. `getUserSparksBalance(address user) view returns (uint256)`: Returns a user's internal Sparks balance.
26. `proposeParameterChange(bytes32 paramName, uint256 newValue)`: Allows artifact holders with sufficient vote power to propose a change to a global parameter.
27. `voteOnProposal(uint256 proposalId, bool support)`: Allows artifact holders (or their delegates) to vote on an active proposal.
28. `executeProposal(uint256 proposalId)`: Attempts to execute a passed proposal after its voting period ends and a timelock (if any) expires, provided quorum is met.
29. `delegateVote(address delegatee)`: Delegates voting power based on artifact ownership to another address.
30. `getProposalDetails(uint256 proposalId) view returns (Proposal memory)`: Retrieves the details of a specific governance proposal.
31. `getVotePower(address holder) view returns (uint256)`: Returns the current total vote power for an address (direct + delegated in).
32. `getProposalVoteCount(uint256 proposalId) view returns (uint256 supportVotes, uint256 againstVotes)`: Returns current vote counts for a proposal.
33. `getProposalState(uint256 proposalId) view returns (ProposalState)`: Returns the current state of a proposal (Pending, Active, Succeeded, Failed, Executed, Expired).

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title ChronoForms: Evolving Digital Artifacts
 * @author Your Name/Alias (Inspired by concepts of dynamic NFTs, resource management, and on-chain simulation)
 * @notice This contract manages a collection of unique digital artifacts (ChronoForms)
 *         that possess dynamic states like energy, maturity, and traits.
 *         Artifacts require user interaction (feeding, harvesting) to thrive
 *         and can undergo lifecycle changes (evolution, forging).
 *         Key features include time-based decay, internal resource management
 *         (Sparks), and a simple artifact-weighted governance system for
 *         protocol parameters.
 *
 * Outline:
 * 1. SPDX License and Pragma
 * 2. Error Definitions
 * 3. Enums: ArtifactStatus, ProposalState
 * 4. Structs: Artifact, Proposal
 * 5. State Variables: Ownership, Artifact Data, Counters, Pausability, Global Parameters, Essence Parameters, User Internal Balances, Governance Data
 * 6. Events
 * 7. Modifiers
 * 8. Constructor
 * 9. Admin Functions
 * 10. Artifact Core Functions (Custom ERC721-like logic)
 * 11. Artifact Interaction Functions
 * 12. Lifecycle & State Update Functions
 * 13. Internal Resource (Sparks) Functions
 * 14. Governance Functions (Artifact-weighted)
 * 15. Helper Functions
 *
 * Function Summary:
 * - constructor(): Initializes contract, owner, initial parameters.
 * - pause(), unpause(): Owner controls interaction pause.
 * - setGlobalParameter(): Owner sets numeric global parameters.
 * - setEssenceEffectParameters(): Owner configures essence effects on energy/traits.
 * - withdrawEth(): Owner withdraws collected ETH.
 * - setForgeCooldown(): Owner sets forge cooldown duration.
 * - setMinMaturityForHarvest(): Owner sets minimum harvest maturity.
 * - setMinEnergyForAction(): Owner sets minimum energy for complex actions.
 * - mintArtifact(): Mints a new ChronoForm NFT. Requires payment.
 * - transferArtifact(): Custom NFT transfer logic.
 * - balanceOf(), ownerOf(), exists(), getTokenDetails(), totalSupply(): Basic artifact (NFT) info views.
 * - feedArtifact(): Uses essence to restore energy/alter traits.
 * - harvestFromArtifact(): Extracts internal 'Sparks' from mature artifacts.
 * - evolveArtifact(): Attempts to change artifact status based on state.
 * - forgeArtifact(): Combines two artifacts into a new one.
 * - putToDormancy(), wakeFromDormancy(): Manually change artifact status.
 * - applyDecay(): Public function to trigger time-based decay for an artifact.
 * - claimSparks(): User claims earned internal Sparks.
 * - getUserSparksBalance(): View user's Sparks balance.
 * - proposeParameterChange(): Artifact holders propose parameter changes.
 * - voteOnProposal(): Artifact holders/delegates vote on proposals.
 * - executeProposal(): Executes a passed proposal.
 * - delegateVote(): Delegates voting power.
 * - getProposalDetails(), getVotePower(), getProposalVoteCount(), getProposalState(): Governance info views.
 * - _safeMint(), _transferArtifact(), _applyEssenceEffect(), _calculateCurrentDecay(), _calculateVotePower(): Internal helpers.
 */

contract ChronoForms {

    // --- 2. Error Definitions ---
    error NotOwner();
    error Paused();
    error NotPaused();
    error ArtifactNotFound(uint256 artifactId);
    error NotArtifactOwner(uint256 artifactId, address caller);
    error TransferBlocked();
    error InvalidEssenceType(uint256 essenceTypeIndex);
    error NotEnoughEnergy(uint256 artifactId, uint256 required, uint256 current);
    error NotEnoughMaturity(uint256 artifactId, uint256 required, uint256 current);
    error InvalidArtifactStatus(uint256 artifactId, ArtifactStatus required, ArtifactStatus current);
    error InvalidParameterName(bytes32 paramName);
    error InvalidProposalState(uint256 proposalId, ProposalState required, ProposalState current);
    error ProposalVotePeriodActive(uint256 proposalId);
    error ProposalExecutionTimelockActive(uint256 proposalId);
    error ProposalAlreadyExecuted(uint256 proposalId);
    error ProposalQuorumNotMet(uint256 proposalId);
    error ProposalFailed(uint256 proposalId);
    error AlreadyVoted(uint256 proposalId, address voter);
    error NoVotePower(address voter);
    error CannotDelegateToSelf();
    error ArtifactOnForgeCooldown(uint256 artifactId, uint256 cooldownUntil);
    error InvalidForgeParents(uint256 parent1, uint256 parent2);
    error InsufficientPayment(uint256 required, uint256 sent);


    // --- 3. Enums ---
    enum ArtifactStatus { Alive, Dormant, Evolving, Forging, Deceased } // Add Deceased for complexity
    enum ProposalState { Pending, Active, Succeeded, Failed, Executed, Expired }

    // --- 4. Structs ---
    struct Artifact {
        uint256 id;
        uint256 creationTime;
        uint256 lastInteractionTime;
        uint256 lastDecayTime; // Separate decay time tracking
        uint256[] traits; // Dynamic array for complexity, e.g., [strength, intelligence, speed, charm, resilience]
        uint256 energy;
        uint256 maturity;
        ArtifactStatus status;
        uint256 parent1; // 0 for base artifacts
        uint256 parent2; // 0 for base artifacts
        uint256 harvestYieldsAvailable; // Internal sparks waiting to be claimed
        uint256 forgeCooldownUntil; // Timestamp when artifact can be used for forging again
    }

    struct Proposal {
        uint256 id;
        bytes32 parameterName;
        uint256 newValue;
        uint256 creationTime;
        uint256 votingPeriodEnds;
        uint256 executionTime; // Timelock
        uint256 supportVotes;
        uint256 againstVotes;
        uint256 totalVotePowerAtStart; // Snapshot vote power
        ProposalState state;
        address proposer;
        bool executed;
    }

    // --- 5. State Variables ---

    // Ownership & Pausability
    address private _owner;
    bool private paused;

    // Artifact Data (Basic ERC721-like mapping)
    mapping(uint256 => address) private _artifactOwners;
    mapping(address => uint256) private _balanceOf;
    mapping(uint256 => Artifact) private _artifacts;
    mapping(uint256 => bool) private _artifactExists;
    uint256 private _nextTokenId; // ERC721 token counter equivalent

    // Global Parameters (Configurable via Governance)
    mapping(bytes32 => uint256) public globalParameters;
    bytes32 constant PARAM_DECAY_RATE_PER_SEC = "decayRatePerSec";
    bytes32 constant PARAM_HARVEST_YIELD_BASE = "harvestYieldBase";
    bytes32 constant PARAM_FORGE_COST_ETH = "forgeCostEth";
    bytes32 constant PARAM_MIN_MATURITY_HARVEST = "minMaturityHarvest";
    bytes32 constant PARAM_MIN_ENERGY_ACTION = "minEnergyAction";
    bytes32 constant PARAM_ESSENCE_TYPES_COUNT = "essenceTypesCount"; // Number of elements expected in traits/essence effects
    bytes32 constant PARAM_FORGE_COOLDOWN_DURATION = "forgeCooldownDuration";
    bytes32 constant PARAM_VOTING_PERIOD_DURATION = "votingPeriodDuration";
    bytes32 constant PARAM_EXECUTION_TIMELOCK_DURATION = "executionTimelockDuration";
    bytes32 constant PARAM_QUORUM_PERCENTAGE = "quorumPercentage"; // e.g., 4 = 4% of total vote power

    // Essence Effects (Configurable via Admin/Governance)
    mapping(uint256 => int256) public essenceEnergyEffects; // essenceTypeIndex => energy change
    mapping(uint256 => int256[]) public essenceTraitEffects; // essenceTypeIndex => array of trait changes

    // User Internal Balances (Sparks)
    mapping(address => uint256) private _userSparksBalance;

    // Governance Data
    mapping(uint256 => Proposal) public proposals;
    uint256 public proposalCount;
    mapping(address => uint256) private _artifactVotePower; // Snapshot of artifact count when used for vote power calculation
    mapping(address => address) public voteDelegations; // address => delegatee
    mapping(uint256 => mapping(address => bool)) private _hasVoted; // proposalId => voter => voted?

    // --- 6. Events ---
    event ArtifactMinted(uint256 indexed artifactId, address indexed owner, uint256[] initialTraits, uint256 initialEnergy);
    event ArtifactTransfer(address indexed from, address indexed to, uint256 indexed artifactId);
    event ArtifactFed(uint256 indexed artifactId, uint256 essenceTypeIndex, uint256 amount, uint256 newEnergy, uint256[] newTraits);
    event ArtifactHarvested(uint256 indexed artifactId, address indexed harvester, uint256 sparksYielded, uint256 newHarvestsAvailable);
    event SparksClaimed(address indexed user, uint256 amount);
    event ArtifactEvolved(uint256 indexed artifactId, ArtifactStatus oldStatus, ArtifactStatus newStatus);
    event ArtifactForged(uint256 indexed parent1Id, uint256 indexed parent2Id, uint256 indexed newArtifactId, address indexed owner);
    event ArtifactStatusChanged(uint256 indexed artifactId, ArtifactStatus oldStatus, ArtifactStatus newStatus);
    event ArtifactDecayed(uint256 indexed artifactId, uint256 energyLost, uint256 maturityLost, uint256 lastDecayTime);
    event ParameterChangeProposed(uint256 indexed proposalId, bytes32 indexed parameterName, uint256 newValue, address indexed proposer);
    event ProposalVoted(uint256 indexed proposalId, address indexed voter, bool support, uint256 votePower);
    event ProposalExecuted(uint256 indexed proposalId, bytes32 parameterName, uint256 newValue);
    event VoteDelegated(address indexed delegator, address indexed delegatee);
    event Paused(address account);
    event Unpaused(address account);


    // --- 7. Modifiers ---
    modifier onlyOwner() {
        if (msg.sender != _owner) revert NotOwner();
        _;
    }

    modifier whenNotPaused() {
        if (paused) revert Paused();
        _;
    }

    modifier whenPaused() {
        if (!paused) revert NotPaused();
        _;
    }

    modifier artifactExistsModifier(uint256 artifactId) {
        if (!_artifactExists[artifactId]) revert ArtifactNotFound(artifactId);
        _;
    }

    modifier onlyArtifactOwner(uint256 artifactId) {
        if (_artifactOwners[artifactId] != msg.sender) revert NotArtifactOwner(artifactId, msg.sender);
        _;
    }

    modifier canInteractWithArtifact(uint256 artifactId) {
        // Basic check: must exist and not be deceased
        if (!_artifactExists[artifactId] || _artifacts[artifactId].status == ArtifactStatus.Deceased) {
             revert ArtifactNotFound(artifactId); // Or a specific error like ArtifactCannotBeInteracted
        }
        // Decay is applied implicitly or explicitly before interaction logic
        _;
    }


    // --- 8. Constructor ---
    constructor() {
        _owner = msg.sender;
        paused = false;
        _nextTokenId = 1; // Start token IDs from 1

        // Set initial default parameters
        globalParameters[PARAM_DECAY_RATE_PER_SEC] = 1; // 1 energy/maturity per second
        globalParameters[PARAM_HARVEST_YIELD_BASE] = 100; // Base sparks per harvest
        globalParameters[PARAM_FORGE_COST_ETH] = 0.01 ether; // Cost to forge
        globalParameters[PARAM_MIN_MATURITY_HARVEST] = 500; // Min maturity to harvest
        globalParameters[PARAM_MIN_ENERGY_ACTION] = 100; // Min energy for complex actions
        globalParameters[PARAM_ESSENCE_TYPES_COUNT] = 5; // Expect 5 traits/essence types
        globalParameters[PARAM_FORGE_COOLDOWN_DURATION] = 1 days; // 1 day cooldown after forging
        globalParameters[PARAM_VOTING_PERIOD_DURATION] = 3 days; // Voting lasts 3 days
        globalParameters[PARAM_EXECUTION_TIMELOCK_DURATION] = 1 days; // 1 day timelock after voting ends
        globalParameters[PARAM_QUORUM_PERCENTAGE] = 4; // 4% quorum

        // Set initial default essence effects (requires manual admin call after deploy or in constructor)
        // Example:
        // essenceEnergyEffects[0] = 50; // Essence 0 adds 50 energy
        // essenceTraitEffects[0] = [int256(10), 0, 0, 0, 0]; // Essence 0 adds 10 to trait 0
    }

    // --- 9. Admin Functions ---
    function pause() external onlyOwner whenNotPaused {
        paused = true;
        emit Paused(msg.sender);
    }

    function unpause() external onlyOwner whenPaused {
        paused = false;
        emit Unpaused(msg.sender);
    }

    function setGlobalParameter(bytes32 paramName, uint256 newValue) external onlyOwner {
        // Ensure the parameter name is recognized
        require(paramName == PARAM_DECAY_RATE_PER_SEC ||
                paramName == PARAM_HARVEST_YIELD_BASE ||
                paramName == PARAM_FORGE_COST_ETH ||
                paramName == PARAM_MIN_MATURITY_HARVEST ||
                paramName == PARAM_MIN_ENERGY_ACTION ||
                paramName == PARAM_ESSENCE_TYPES_COUNT ||
                paramName == PARAM_FORGE_COOLDOWN_DURATION ||
                paramName == PARAM_VOTING_PERIOD_DURATION ||
                paramName == PARAM_EXECUTION_TIMELOCK_DURATION ||
                paramName == PARAM_QUORUM_PERCENTAGE,
                "Invalid parameter name"); // Custom error version needed if we defined one
        // Use custom error here for consistency
        if (!(paramName == PARAM_DECAY_RATE_PER_SEC ||
              paramName == PARAM_HARVEST_YIELD_BASE ||
              paramName == PARAM_FORGE_COST_ETH ||
              paramName == PARAM_MIN_MATURITY_HARVEST ||
              paramName == PARAM_MIN_ENERGY_ACTION ||
              paramName == PARAM_ESSENCE_TYPES_COUNT ||
              paramName == PARAM_FORGE_COOLDOWN_DURATION ||
              paramName == PARAM_VOTING_PERIOD_DURATION ||
              paramName == PARAM_EXECUTION_TIMELOCK_DURATION ||
              paramName == PARAM_QUORUM_PERCENTAGE)) revert InvalidParameterName(paramName);


        globalParameters[paramName] = newValue;
        // No specific event for individual param changes, but proposal execution handles it.
        // This function is for owner-only initial setup or emergency.
    }

     // Note: This admin function allows setting multiple trait effects. Need to match PARAM_ESSENCE_TYPES_COUNT size.
    function setEssenceEffectParameters(uint256 essenceTypeIndex, int256 energyEffect, int256[] calldata traitEffects) external onlyOwner {
        if (essenceTypeIndex >= globalParameters[PARAM_ESSENCE_TYPES_COUNT]) revert InvalidEssenceType(essenceTypeIndex);
        if (traitEffects.length != globalParameters[PARAM_ESSENCE_TYPES_COUNT]) revert("Trait effects array size mismatch");

        essenceEnergyEffects[essenceTypeIndex] = energyEffect;
        // Deep copy array
        essenceTraitEffects[essenceTypeIndex].length = traitEffects.length; // Clear existing if needed
        for (uint i = 0; i < traitEffects.length; i++) {
            essenceTraitEffects[essenceTypeIndex][i] = traitEffects[i];
        }
    }


    function withdrawEth(address payable recipient, uint256 amount) external onlyOwner {
        require(amount > 0, "Cannot withdraw 0"); // Standard check
        // Safely transfer ETH
        (bool success, ) = recipient.call{value: amount}("");
        require(success, "ETH transfer failed"); // Standard check
    }

    // Specific admin functions for key parameters (can also be done via setGlobalParameter or Governance)
    // Added for clarity and direct access for Owner
     function setForgeCooldown(uint256 duration) external onlyOwner {
        globalParameters[PARAM_FORGE_COOLDOWN_DURATION] = duration;
    }

    function setMinMaturityForHarvest(uint256 maturity) external onlyOwner {
        globalParameters[PARAM_MIN_MATURITY_HARVEST] = maturity;
    }

    function setMinEnergyForAction(uint256 energy) external onlyOwner {
        globalParameters[PARAM_MIN_ENERGY_ACTION] = energy;
    }

    // --- 10. Artifact Core Functions (Custom ERC721-like) ---

    // Minimalistic mint function - can be expanded with random traits, tiered pricing, etc.
    function mintArtifact(uint256[] calldata initialTraits, uint256 initialEnergy)
        external
        payable
        whenNotPaused
        returns (uint256 newTokenId)
    {
        // Basic validation
        if (initialTraits.length != globalParameters[PARAM_ESSENCE_TYPES_COUNT]) revert("Initial traits size mismatch");
        if (msg.value < globalParameters[PARAM_FORGE_COST_ETH] / 10) revert InsufficientPayment(globalParameters[PARAM_FORGE_COST_ETH] / 10, msg.value); // Example cost, maybe different from forge cost

        newTokenId = _nextTokenId++;
        _safeMint(msg.sender, newTokenId, initialTraits, initialEnergy, 0, 0);

        emit ArtifactMinted(newTokenId, msg.sender, initialTraits, initialEnergy);
    }

    // Custom transfer logic - does NOT use ERC721 standard functions like transferFrom
    // Requires owner to call directly (or approved address if approved mapping added)
    function transferArtifact(address from, address to, uint256 artifactId)
        external
        whenNotPaused
        artifactExistsModifier(artifactId)
    {
        if (_artifactOwners[artifactId] != from || from != msg.sender) revert TransferBlocked(); // Only owner can initiate transfer, 'from' must be current owner

        // Add any transfer restrictions here (e.g., cannot transfer Evolving artifacts)
        if (_artifacts[artifactId].status == ArtifactStatus.Evolving || _artifacts[artifactId].status == ArtifactStatus.Forging) {
             revert("Cannot transfer artifact in this status"); // Custom error needed
        }

        // Apply decay before transferring to ensure state is current for the recipient
        _applyDecay(artifactId);

        _transferArtifact(from, to, artifactId);

        // Note: Standard ERC721 has approvals. This custom version omits them for simplicity and uniqueness.
        // A real implementation would need ERC721 standard methods or similar access control.
    }

    // Standard ERC721 views (implementing minimal interface)
    function balanceOf(address owner) public view returns (uint256) {
        return _balanceOf[owner];
    }

    function ownerOf(uint256 artifactId) public view artifactExistsModifier(artifactId) returns (address) {
        return _artifactOwners[artifactId];
    }

    function exists(uint256 artifactId) public view returns (bool) {
        return _artifactExists[artifactId];
    }

    function getTokenDetails(uint256 artifactId) public view artifactExistsModifier(artifactId) returns (Artifact memory) {
        // Note: This returns the state *before* decay is applied.
        // A complex system might return state *after* simulating decay.
        return _artifacts[artifactId];
    }

    function totalSupply() public view returns (uint256) {
        // Since we start from 1 and increment, _nextTokenId - 1 is the total minted.
        // If we allowed burning, we'd need a separate total counter.
        return _nextTokenId - 1;
    }

    // --- 11. Artifact Interaction Functions ---

    function feedArtifact(uint256 artifactId, uint256 essenceTypeIndex, uint256 amount)
        external
        whenNotPaused
        onlyArtifactOwner(artifactId)
        canInteractWithArtifact(artifactId)
    {
        if (essenceTypeIndex >= globalParameters[PARAM_ESSENCE_TYPES_COUNT]) revert InvalidEssenceType(essenceTypeIndex);
        if (amount == 0) return;

        // Apply decay first
        _applyDecay(artifactId);

        Artifact storage artifact = _artifacts[artifactId];

        // Apply energy and trait effects
        int256 energyEffect = essenceEnergyEffects[essenceTypeIndex];
        artifact.energy = uint256(int256(artifact.energy) + energyEffect * int256(amount)); // Handle negative effects

        int256[] storage traitEffects = essenceTraitEffects[essenceTypeIndex];
        for (uint i = 0; i < traitEffects.length; i++) {
            artifact.traits[i] = uint256(int256(artifact.traits[i]) + traitEffects[i] * int256(amount)); // Handle negative effects
            // Prevent traits from going negative (optional, depends on game design)
            if (int256(artifact.traits[i]) < 0) artifact.traits[i] = 0;
        }

        artifact.lastInteractionTime = block.timestamp; // Update interaction time

        emit ArtifactFed(artifactId, essenceTypeIndex, amount, artifact.energy, artifact.traits);
    }

    function harvestFromArtifact(uint256 artifactId)
        external
        whenNotPaused
        onlyArtifactOwner(artifactId)
        canInteractWithArtifact(artifactId)
    {
        // Apply decay first
        _applyDecay(artifactId);

        Artifact storage artifact = _artifacts[artifactId];

        if (artifact.maturity < globalParameters[PARAM_MIN_MATURITY_HARVEST]) {
            revert NotEnoughMaturity(artifactId, globalParameters[PARAM_MIN_MATURITY_HARVEST], artifact.maturity);
        }
        if (artifact.energy < globalParameters[PARAM_MIN_ENERGY_ACTION]) {
            revert NotEnoughEnergy(artifactId, globalParameters[PARAM_MIN_ENERGY_ACTION], artifact.energy);
        }
        if (artifact.status != ArtifactStatus.Alive) {
             revert InvalidArtifactStatus(artifactId, ArtifactStatus.Alive, artifact.status);
        }

        // Calculate yield (can be based on maturity, traits, etc.)
        uint256 sparksYielded = globalParameters[PARAM_HARVEST_YIELD_BASE] + (artifact.maturity / 10); // Example formula

        artifact.harvestYieldsAvailable += sparksYielded;
        artifact.energy -= globalParameters[PARAM_MIN_ENERGY_ACTION]; // Cost energy to harvest
        artifact.lastInteractionTime = block.timestamp; // Update interaction time

        emit ArtifactHarvested(artifactId, msg.sender, sparksYielded, artifact.harvestYieldsAvailable);
    }

     function claimSparks() external whenNotPaused {
        uint256 availableSparks = _userSparksBalance[msg.sender];
        if (availableSparks == 0) return;

        _userSparksBalance[msg.sender] = 0; // Transfer all available

        emit SparksClaimed(msg.sender, availableSparks);
        // Note: Sparks are internal to this contract. To make them usable elsewhere,
        // you'd either make this contract an ERC20/1155 issuer or interact with an external token contract.
        // For uniqueness, they are internal points here.
    }

    function evolveArtifact(uint256 artifactId)
        external
        whenNotPaused
        onlyArtifactOwner(artifactId)
        canInteractWithArtifact(artifactId)
    {
        // Apply decay first
        _applyDecay(artifactId);

        Artifact storage artifact = _artifacts[artifactId];
        ArtifactStatus oldStatus = artifact.status;

        // Example evolution logic: Mature + High Energy => Evolving
        if (artifact.status == ArtifactStatus.Alive && artifact.maturity >= 1000 && artifact.energy >= 500) { // Example thresholds
            artifact.status = ArtifactStatus.Evolving;
            artifact.energy -= 500; // Cost energy to evolve
            artifact.lastInteractionTime = block.timestamp;
            emit ArtifactEvolved(artifactId, oldStatus, artifact.status);
            emit ArtifactStatusChanged(artifactId, oldStatus, artifact.status);

        } else if (artifact.status == ArtifactStatus.Evolving && block.timestamp >= artifact.lastInteractionTime + 1 days) { // Example: Takes time
             // Complex logic could apply trait changes or change to a new status (e.g., Primal)
             artifact.status = ArtifactStatus.Alive; // Return to Alive or change to a new status
             artifact.lastInteractionTime = block.timestamp; // Reset timer
             emit ArtifactEvolved(artifactId, oldStatus, artifact.status);
             emit ArtifactStatusChanged(artifactId, oldStatus, artifact.status);

        } else {
             // Add other evolution paths or revert if conditions not met
             revert("Artifact cannot evolve in its current state"); // Custom error needed
        }
    }

    // Forging consumes ETH and potentially parents state/puts on cooldown
    function forgeArtifact(uint256 parent1Id, uint256 parent2Id, uint256[] calldata initialTraits)
        external
        payable
        whenNotPaused
        returns (uint256 newArtifactId)
    {
        if (parent1Id == parent2Id) revert InvalidForgeParents(parent1Id, parent2Id);
        if (msg.value < globalParameters[PARAM_FORGE_COST_ETH]) revert InsufficientPayment(globalParameters[PARAM_FORGE_COST_ETH], msg.value);

        artifactExistsModifier(parent1Id);
        artifactExistsModifier(parent2Id);
        onlyArtifactOwner(parent1Id); // Requires caller owns parent1
        // Add check that caller also owns parent2, or has approval/permission
        if (_artifactOwners[parent2Id] != msg.sender) revert NotArtifactOwner(parent2Id, msg.sender); // Requires caller owns parent2

        Artifact storage parent1 = _artifacts[parent1Id];
        Artifact storage parent2 = _artifacts[parent2Id];

        // Apply decay to parents before checking cooldown/status
        _applyDecay(parent1Id);
        _applyDecay(parent2Id);

        if (block.timestamp < parent1.forgeCooldownUntil) revert ArtifactOnForgeCooldown(parent1Id, parent1.forgeCooldownUntil);
        if (block.timestamp < parent2.forgeCooldownUntil) revert ArtifactOnForgeCooldown(parent2Id, parent2.forgeCooldownUntil);

        // Example: Parents must be Alive and have enough energy
        if (parent1.status != ArtifactStatus.Alive || parent1.energy < globalParameters[PARAM_MIN_ENERGY_ACTION] ||
            parent2.status != ArtifactStatus.Alive || parent2.energy < globalParameters[PARAM_MIN_ENERGY_ACTION]) {
            revert("Parents not ready for forging"); // Custom error needed
        }

        if (initialTraits.length != globalParameters[PARAM_ESSENCE_TYPES_COUNT]) revert("Initial traits size mismatch");


        // --- Forging Logic ---
        // This is where the creative part happens - how are traits combined?
        // Simple example: Average traits, add some bonus, use provided initialTraits as a base.
        uint256[] memory forgedTraits = new uint256[](globalParameters[PARAM_ESSENCE_TYPES_COUNT]);
        for(uint i = 0; i < forgedTraits.length; i++) {
             // Example: Weighted average + influence from initialTraits + random element (difficult on-chain)
             // Let's keep it deterministic: Average + some base from initialTraits
             forgedTraits[i] = (parent1.traits[i] + parent2.traits[i]) / 2 + initialTraits[i];
        }
        uint256 forgedEnergy = (parent1.energy + parent2.energy) / 3; // New artifact starts with some energy

        // --- Mint new artifact ---
        newArtifactId = _nextTokenId++;
        _safeMint(msg.sender, newArtifactId, forgedTraits, forgedEnergy, parent1Id, parent2Id);

        // --- Update parents state ---
        parent1.energy = parent1.energy / 2; // Parents lose energy
        parent2.energy = parent2.energy / 2;
        parent1.forgeCooldownUntil = block.timestamp + globalParameters[PARAM_FORGE_COOLDOWN_DURATION]; // Set cooldown
        parent2.forgeCooldownUntil = block.timestamp + globalParameters[PARAM_FORGE_COOLDOWN_DURATION];
        parent1.lastInteractionTime = block.timestamp; // Update interaction time
        parent2.lastInteractionTime = block.timestamp;

        emit ArtifactForged(parent1Id, parent2Id, newArtifactId, msg.sender);
    }


    function putToDormancy(uint256 artifactId)
         external
         whenNotPaused
         onlyArtifactOwner(artifactId)
         canInteractWithArtifact(artifactId)
    {
        Artifact storage artifact = _artifacts[artifactId];
        ArtifactStatus oldStatus = artifact.status;
        if (oldStatus == ArtifactStatus.Dormant) return; // Already dormant

        // Apply decay before changing status
        _applyDecay(artifactId);

        artifact.status = ArtifactStatus.Dormant;
        artifact.lastInteractionTime = block.timestamp; // Reset timer / Mark dormancy start
        // Decay could potentially be paused or slowed in Dormant state

        emit ArtifactStatusChanged(artifactId, oldStatus, artifact.status);
    }

    function wakeFromDormancy(uint256 artifactId, uint256 cost) // Cost could be ETH, Sparks, or specific essence
         external
         whenNotPaused
         onlyArtifactOwner(artifactId)
         canInteractWithArtifact(artifactId)
    {
         Artifact storage artifact = _artifacts[artifactId];
         ArtifactStatus oldStatus = artifact.status;
         if (oldStatus != ArtifactStatus.Dormant) revert InvalidArtifactStatus(artifactId, ArtifactStatus.Dormant, oldStatus);

         // Apply decay (if any happens in Dormant) before changing status
         _applyDecay(artifactId);

         // Example cost mechanism: require a certain amount of internal Sparks
         if (_userSparksBalance[msg.sender] < cost) revert("Not enough sparks to wake"); // Custom error needed
         _userSparksBalance[msg.sender] -= cost; // Burn sparks

         artifact.status = ArtifactStatus.Alive; // Return to Alive
         artifact.lastInteractionTime = block.timestamp; // Reset timer

         emit ArtifactStatusChanged(artifactId, oldStatus, artifact.status);
    }


    // --- 12. Lifecycle & State Update Functions ---

    // This function allows anyone to trigger decay for an artifact,
    // encouraging the network to keep artifact states up-to-date.
    // A small reward could be added for the caller in a real system.
    function applyDecay(uint256 artifactId)
        public // Can be called by anyone
        artifactExistsModifier(artifactId)
    {
        _applyDecay(artifactId);
    }

    // Internal helper to calculate and apply decay
    function _applyDecay(uint256 artifactId) internal {
        Artifact storage artifact = _artifacts[artifactId];

        // Decay only applies to Alive or Evolving artifacts (example rule)
        if (artifact.status != ArtifactStatus.Alive && artifact.status != ArtifactStatus.Evolving) {
             artifact.lastDecayTime = block.timestamp; // Update decay time even if no decay occurs
             return;
        }

        uint256 timeElapsed = block.timestamp - artifact.lastDecayTime;
        if (timeElapsed == 0) return; // No time has passed

        uint256 decayRate = globalParameters[PARAM_DECAY_RATE_PER_SEC];
        uint256 energyLoss = timeElapsed * decayRate;
        uint256 maturityLoss = timeElapsed * decayRate / 2; // Maturity decays slower? Example

        uint256 energyBefore = artifact.energy;
        uint256 maturityBefore = artifact.maturity;

        // Apply loss, prevent underflow
        if (artifact.energy > energyLoss) {
            artifact.energy -= energyLoss;
        } else {
            artifact.energy = 0;
        }

        if (artifact.maturity > maturityLoss) {
            artifact.maturity -= maturityLoss;
        } else {
            artifact.maturity = 0;
        }

        artifact.lastDecayTime = block.timestamp; // Update decay time

        // If energy reaches 0, maybe change status to Dormant or Deceased
        if (artifact.energy == 0 && artifact.status == ArtifactStatus.Alive) {
             artifact.status = ArtifactStatus.Dormant; // Or Deceased
             emit ArtifactStatusChanged(artifactId, ArtifactStatus.Alive, ArtifactStatus.Dormant);
        } else if (artifact.energy == 0 && artifact.status == ArtifactStatus.Evolving) {
             artifact.status = ArtifactStatus.Dormant; // Stop evolving if energy hits 0
             emit ArtifactStatusChanged(artifactId, ArtifactStatus.Evolving, ArtifactStatus.Dormant);
        }

        uint256 energyLostActual = energyBefore - artifact.energy;
        uint256 maturityLostActual = maturityBefore - artifact.maturity;

        if (energyLostActual > 0 || maturityLostActual > 0) {
             emit ArtifactDecayed(artifactId, energyLostActual, maturityLostActual, artifact.lastDecayTime);
        }
    }

    // Internal helper called before interactions/transfers
    // Factors in decay and other potential state changes
    function _updateArtifactState(uint256 artifactId) internal {
        // For now, this just calls decay. Could include other logic later.
        _applyDecay(artifactId);
    }


    // --- 14. Governance Functions ---

    function proposeParameterChange(bytes32 paramName, uint256 newValue) external whenNotPaused {
        // Basic validation: Requires knowing valid parameters or having an allowlist
        if (!(paramName == PARAM_DECAY_RATE_PER_SEC ||
              paramName == PARAM_HARVEST_YIELD_BASE ||
              paramName == PARAM_FORGE_COST_ETH ||
              paramName == PARAM_MIN_MATURITY_HARVEST ||
              paramName == PARAM_MIN_ENERGY_ACTION ||
              paramName == PARAM_FORGE_COOLDOWN_DURATION ||
              paramName == PARAM_VOTING_PERIOD_DURATION || // Can even propose changes to governance parameters!
              paramName == PARAM_EXECUTION_TIMELOCK_DURATION ||
              paramName == PARAM_QUORUM_PERCENTAGE)) revert InvalidParameterName(paramName);


        // Optional: require minimum vote power to propose
        // if (_calculateVotePower(msg.sender) == 0) revert NoVotePower(msg.sender); // Example threshold

        uint256 proposalId = proposalCount++;
        uint256 votingPeriodDuration = globalParameters[PARAM_VOTING_PERIOD_DURATION];
        uint256 executionTimelockDuration = globalParameters[PARAM_EXECUTION_TIMELOCK_DURATION];

        proposals[proposalId] = Proposal({
            id: proposalId,
            parameterName: paramName,
            newValue: newValue,
            creationTime: block.timestamp,
            votingPeriodEnds: block.timestamp + votingPeriodDuration,
            executionTime: block.timestamp + votingPeriodDuration + executionTimelockDuration,
            supportVotes: 0,
            againstVotes: 0,
            totalVotePowerAtStart: _calculateVotePower(address(0)), // Snapshot total supply vote power
            state: ProposalState.Pending, // Starts pending, activated on first vote or after a delay? Let's say Active immediately
            proposer: msg.sender,
            executed: false
        });

        proposals[proposalId].state = ProposalState.Active; // Activate immediately

        emit ParameterChangeProposed(proposalId, paramName, newValue, msg.sender);
    }

    function voteOnProposal(uint256 proposalId, bool support) external whenNotPaused {
        Proposal storage proposal = proposals[proposalId];

        if (proposal.state != ProposalState.Active) revert InvalidProposalState(proposalId, ProposalState.Active, proposal.state);
        if (block.timestamp > proposal.votingPeriodEnds) revert ProposalVotePeriodActive(proposalId); // Voting period is over

        address voter = msg.sender;
        // Resolve delegatee if delegated
        if (voteDelegations[voter] != address(0)) {
             voter = voteDelegations[voter];
        }

        if (_hasVoted[proposalId][voter]) revert AlreadyVoted(proposalId, voter);

        uint256 votePower = _calculateVotePower(voter); // Calculate vote power at time of vote
        if (votePower == 0) revert NoVotePower(voter);

        if (support) {
            proposal.supportVotes += votePower;
        } else {
            proposal.againstVotes += votePower;
        }

        _hasVoted[proposalId][voter] = true;

        emit ProposalVoted(proposalId, voter, support, votePower);
    }

    function executeProposal(uint256 proposalId) external whenNotPaused {
        Proposal storage proposal = proposals[proposalId];

        if (proposal.state != ProposalState.Active) revert InvalidProposalState(proposalId, ProposalState.Active, proposal.state);
        if (block.timestamp <= proposal.votingPeriodEnds) revert ProposalVotePeriodActive(proposalId); // Voting period must be over
        if (block.timestamp < proposal.executionTime) revert ProposalExecutionTimelockActive(proposalId); // Timelock must be over
        if (proposal.executed) revert ProposalAlreadyExecuted(proposalId); // Cannot execute twice

        // Check if passed (more support votes than against)
        if (proposal.supportVotes <= proposal.againstVotes) {
            proposal.state = ProposalState.Failed;
            revert ProposalFailed(proposalId); // Revert on failure
        }

        // Check Quorum (e.g., 4% of total vote power at proposal start must have voted YES)
        uint256 totalVotePowerSnapshot = proposal.totalVotePowerAtStart;
        uint256 quorumVotesRequired = (totalVotePowerSnapshot * globalParameters[PARAM_QUORUM_PERCENTAGE]) / 100;

        if (proposal.supportVotes < quorumVotesRequired) {
             proposal.state = ProposalState.Failed; // Mark as failed if quorum not met
             revert ProposalQuorumNotMet(proposalId);
        }

        // --- Execution ---
        // Only recognized global parameters can be set
        if (!(proposal.parameterName == PARAM_DECAY_RATE_PER_SEC ||
              proposal.parameterName == PARAM_HARVEST_YIELD_BASE ||
              proposal.parameterName == PARAM_FORGE_COST_ETH ||
              proposal.parameterName == PARAM_MIN_MATURITY_HARVEST ||
              proposal.parameterName == PARAM_MIN_ENERGY_ACTION ||
              proposal.parameterName == PARAM_FORGE_COOLDOWN_DURATION ||
              proposal.parameterName == PARAM_VOTING_PERIOD_DURATION ||
              proposal.parameterName == PARAM_EXECUTION_TIMELOCK_DURATION ||
              proposal.parameterName == PARAM_QUORUM_PERCENTAGE)) {
              // This case should ideally not happen if proposeParameterChange is correct,
              // but included for safety against potential errors or future changes.
              proposal.state = ProposalState.Failed; // Or an error state
              revert("Internal error: invalid parameter name for execution"); // Custom error needed
            }

        globalParameters[proposal.parameterName] = proposal.newValue;

        proposal.state = ProposalState.Executed;
        proposal.executed = true; // Mark as executed

        emit ProposalExecuted(proposalId, proposal.parameterName, proposal.newValue);
    }

    function delegateVote(address delegatee) external {
        if (delegatee == msg.sender) revert CannotDelegateToSelf();
        voteDelegations[msg.sender] = delegatee;
        emit VoteDelegated(msg.sender, delegatee);
    }

    // View functions for Governance
    function getProposalDetails(uint256 proposalId) public view returns (Proposal memory) {
        // Add exists check if needed, but accessing mapping directly is okay for view
        return proposals[proposalId];
    }

    // Calculates vote power based on artifact ownership (live count)
    function getVotePower(address holder) public view returns (uint256) {
         address representative = voteDelegations[holder] == address(0) ? holder : voteDelegations[holder];
         return _balanceOf[representative];
    }

    // Internal helper to calculate vote power for a specific address (considers delegation)
    function _calculateVotePower(address holder) internal view returns (uint256) {
         // Special case: address(0) is used internally to mean total supply vote power snapshot
         if (holder == address(0)) {
              return _nextTokenId - 1; // Total artifacts minted
         }
         address representative = voteDelegations[holder] == address(0) ? holder : voteDelegations[holder];
         return _balanceOf[representative];
    }


    function getProposalVoteCount(uint256 proposalId) public view returns (uint256 supportVotes, uint256 againstVotes) {
        // Add exists check if needed
        Proposal storage proposal = proposals[proposalId];
        return (proposal.supportVotes, proposal.againstVotes);
    }

    function getProposalState(uint256 proposalId) public view returns (ProposalState) {
         // Check if state needs updating based on time
         Proposal storage proposal = proposals[proposalId];
         if (proposal.state == ProposalState.Active && block.timestamp > proposal.votingPeriodEnds) {
              // Voting ended, but not executed yet. Could transition to Succeeded/Failed implicitly here
              // based on votes/quorum if accessed via this getter.
              // For simplicity, executeProposal does the final state transition.
              // Just return the current state as stored.
         }
         return proposal.state;
    }

    // --- 15. Helper Functions ---

    // Custom internal minting function
    function _safeMint(address to, uint256 artifactId, uint256[] memory initialTraits, uint256 initialEnergy, uint256 parent1, uint256 parent2) internal {
        require(to != address(0), "Mint to the zero address"); // Standard check

        _artifactOwners[artifactId] = to;
        _balanceOf[to]++;
        _artifactExists[artifactId] = true;

        // Initialize artifact data
        Artifact memory newArtifact = Artifact({
            id: artifactId,
            creationTime: block.timestamp,
            lastInteractionTime: block.timestamp,
            lastDecayTime: block.timestamp, // Start decay timer now
            traits: new uint256[](initialTraits.length),
            energy: initialEnergy,
            maturity: 0,
            status: ArtifactStatus.Alive, // New artifacts start Alive
            parent1: parent1,
            parent2: parent2,
            harvestYieldsAvailable: 0,
            forgeCooldownUntil: 0 // Not on cooldown initially
        });

        // Copy initial traits
        for(uint i=0; i < initialTraits.length; i++) {
            newArtifact.traits[i] = initialTraits[i];
        }

        _artifacts[artifactId] = newArtifact;

        // ERC721 standard suggests calling hooks here if they existed.
        // _afterTokenTransfer(address(0), to, artifactId);
    }

    // Custom internal transfer function
    function _transferArtifact(address from, address to, uint256 artifactId) internal {
         require(from != address(0), "Transfer from the zero address"); // Standard check
         require(to != address(0), "Transfer to the zero address"); // Standard check
         require(_artifactOwners[artifactId] == from, "Transfer of token not owned by from"); // Standard check

         // ERC721 standard suggests calling hooks here.
         // _beforeTokenTransfer(from, to, artifactId);

         _balanceOf[from]--;
         _artifactOwners[artifactId] = to;
         _balanceOf[to]++;

         // After transfer, the decay timer should potentially reset or be updated for the new owner
         // Let's reset lastInteractionTime and lastDecayTime for simplicity here.
         _artifacts[artifactId].lastInteractionTime = block.timestamp;
         _artifacts[artifactId].lastDecayTime = block.timestamp;


         // ERC721 standard suggests calling hooks here.
         // _afterTokenTransfer(from, to, artifactId);

         emit ArtifactTransfer(from, to, artifactId);
    }

     // Internal helper to apply essence effects during feeding
     function _applyEssenceEffect(Artifact storage artifact, uint256 essenceTypeIndex, uint256 amount) internal view {
         // Logic moved into feedArtifact for direct state modification
     }

     // Internal view to calculate decay amount based on time
     function _calculateCurrentDecay(uint256 artifactId) internal view returns (uint256 energyLoss, uint256 maturityLoss) {
         Artifact storage artifact = _artifacts[artifactId];
         if (artifact.status != ArtifactStatus.Alive && artifact.status != ArtifactStatus.Evolving) {
              return (0, 0); // No decay in certain states
         }

         uint256 timeElapsed = block.timestamp - artifact.lastDecayTime;
         uint256 decayRate = globalParameters[PARAM_DECAY_RATE_PER_SEC];

         energyLoss = timeElapsed * decayRate;
         maturityLoss = timeElapsed * decayRate / 2; // Example: maturity decays slower
     }


    // Fallback/Receive functions to accept ETH for minting/costs
    receive() external payable {}
    fallback() external payable {}

    // --- ERC165-like Interface Support ---
    // While not implementing the *full* ERC165, mimicking it for self-description
    // Add this if you want basic interface support, though standard ERC721 is better
    /*
    function supportsInterface(bytes4 interfaceId) external view returns (bool) {
         // Example: ERC721 and ERC165 interfaces
         return interfaceId == 0x80ac58cd || // ERC721
                interfaceId == 0x01ffc9a7;   // ERC165
                // Add others if applicable
    }
    */
}
```