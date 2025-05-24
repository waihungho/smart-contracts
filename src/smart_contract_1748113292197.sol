Okay, this sounds like a fun challenge! Let's brainstorm a concept that is interesting, relatively advanced (combining multiple mechanisms), creative, and touches on trendy areas like dynamic NFTs, on-chain ecosystems, and decentralized governance, *without* being a direct copy of a major open-source protocol like a standard AMM, lending protocol, or basic ERC token/NFT.

**Concept: EtherealBloom Conservatory**

This smart contract creates a digital ecosystem where users cultivate unique, dynamic digital entities called "Blooms". Blooms are like dynamic NFTs – their properties change over time and based on user interactions and simulated environmental factors. The system also includes:

1.  **Essence:** A fungible resource needed to interact with Blooms, acquired by staking an external ERC20 token.
2.  **Dynamic Blooms:** Blooms have properties (like Vitality, Rarity, Evolution Stage) that decay over time if neglected but improve with nurturing. They can also be "cross-pollinated" to potentially create new Blooms or combine/modify traits.
3.  **Environmental Factors:** A simulated environmental factor (e.g., based on block hash or time) subtly influences bloom growth/decay.
4.  **Governance:** A simple decentralized governance mechanism using a native "BloomGovToken" allows users to propose and vote on system parameter changes (e.g., nurture costs, decay rates, adding new Bloom types).

This combines staking, dynamic state, ownership tracking (like simplified NFT), resource management, and governance into a single, novel application concept.

---

**Outline and Function Summary**

**I. Contract Overview:**
    *   Name: `EtherealBloomConservatory`
    *   Core Concept: Cultivate dynamic digital "Blooms" using staked resources ("Essence") within an on-chain ecosystem governed by token holders ("BloomGovToken").
    *   Key Features: Dynamic asset state, resource staking & management, interactive asset mechanics, simulated environmental influence, token-based governance.

**II. State Variables:**
    *   Addresses for owner, staking token, and governance token.
    *   Mappings for Essence balances, Gov token balances, Bloom data, Bloom ownership, user staked amounts, staking timestamps.
    *   Counters for Bloom IDs and Proposal IDs.
    *   Config parameters for staking rates, interaction costs, decay rates, governance settings (quorum, periods).
    *   Structs for `Bloom`, `Proposal`, `BloomTypeConfig`.
    *   Enums for `BloomState`, `ProposalState`.
    *   Arrays/Mappings for tracking Bloom types and proposals.

**III. Events:**
    *   `BloomCreated`, `BloomNurtured`, `BloomsCrossPollinated`, `BloomTransferred`, `BloomRenounced`
    *   `EssenceClaimed`, `TokensStaked`, `TokensUnstaked`, `EssenceTransferred`
    *   `ProposalCreated`, `Voted`, `ProposalExecuted`, `ProposalQueued`
    *   `ParamsUpdated`, `BloomTypeAdded`

**IV. Modifiers:**
    *   `onlyOwner`
    *   `onlyGovTokenHolder` (simplified check)
    *   `whenNotPaused`, `whenPaused` (using OpenZeppelin's Pausable pattern)

**V. Functions (20+ required):**

    1.  `constructor()`: Initializes the contract, sets owner, deploys/links Gov token, sets initial parameters.
    2.  `pause()`: Owner can pause sensitive contract interactions.
    3.  `unpause()`: Owner can unpause the contract.
    4.  `setEssenceStakeToken(address _token)`: Sets the ERC20 token address used for staking. (Owner/Governance)
    5.  `setEssenceRate(uint256 _rate)`: Sets the rate at which staked tokens accrue Essence per time unit. (Owner/Governance)
    6.  `stakeForEssence(uint256 _amount)`: Users stake the defined ERC20 token to earn Essence. Requires token approval.
    7.  `claimEssence()`: Users claim their accumulated Essence based on their stake and time.
    8.  `unstake(uint256 _amount)`: Users unstake their tokens and claim accrued Essence up to that point.
    9.  `getAccruedEssence(address _user)`: View function to calculate Essence claimable by a user.
    10. `transferEssence(address _recipient, uint256 _amount)`: Allows users to transfer their Essence balance.
    11. `createInitialBloom(uint8 _bloomTypeIndex)`: Creates a new Bloom for the caller, consuming Essence. Initial properties are based on type and block data.
    12. `nurtureBloom(uint256 _bloomId)`: Nurtures a specific Bloom, increasing its Vitality and potentially Rarity, consuming Essence. Triggers state update.
    13. `crossPollinateBlooms(uint256 _bloomId1, uint256 _bloomId2)`: Combines traits from two Blooms, consuming Essence. Might create a new Bloom seed or modify the parents significantly. Triggers state updates.
    14. `transferBloom(address _to, uint256 _bloomId)`: Transfers ownership of a Bloom.
    15. `renounceBloomOwnership(uint256 _bloomId)`: User burns their Bloom, potentially yielding a small amount of Essence back or influencing environment.
    16. `getBloomProperties(uint256 _bloomId)`: View function returning the current state of a Bloom. Triggers state update before returning.
    17. `getUserBlooms(address _user)`: View function returning an array of Bloom IDs owned by a user.
    18. `getBloomOwner(uint256 _bloomId)`: View function returning the owner of a Bloom.
    19. `isBloomAlive(uint256 _bloomId)`: View function checking if a Bloom's Vitality is above zero.
    20. `getBloomCurrentValueEstimate(uint256 _bloomId)`: View function providing a conceptual value estimate based on properties (not a market price).
    21. `balanceOfGov(address _user)`: View function for BloomGovToken balance.
    22. `getTotalGovSupply()`: View function for total BloomGovToken supply.
    23. `delegateGovVotes(address _delegatee)`: Allows Gov token holders to delegate their voting power.
    24. `getVotes(address _user)`: View function returning current delegated voting power.
    25. `propose(string memory _description, address _target, bytes memory _calldata)`: Create a governance proposal to call a function on a target contract (or self). Requires minimum Gov token stake.
    26. `vote(uint256 _proposalId, bool _support)`: Vote on an active proposal.
    27. `executeProposal(uint256 _proposalId)`: Execute a successful proposal after the voting period and timelock.
    28. `getProposalState(uint256 _proposalId)`: View function returning the state of a proposal (Pending, Active, Succeeded, Defeated, Executed, Expired).
    29. `getProposalVotes(uint256 _proposalId)`: View function returning vote counts for a proposal.
    30. `setGovParams(uint256 _votingPeriod, uint256 _quorumNumerator, uint256 _timelockDelay, uint256 _proposalThreshold)`: Set governance parameters (via Governance).
    31. `getGovParams()`: View governance parameters.
    32. `adminMintGovTokens(address _to, uint256 _amount)`: Owner function to mint initial Gov tokens (should be phase out by governance).
    33. `addBloomType(string memory _name, uint256 _initialVitality, uint256 _initialRarity, uint256 _growthFactor, uint256 _decayFactor)`: Add a new configuration for a Bloom type (via Governance).
    34. `getBloomTypeProperties(uint8 _typeIndex)`: View function for properties of a specific Bloom type.
    35. `getEnvironmentalFactor()`: View function showing the current simulated environmental influence value.
    36. `burnEssence(uint256 _amount)`: Burn Essence to potentially trigger a small positive global or per-user environmental effect.
    37. `withdrawStakedTokens(address _recipient, uint256 _amount)`: Owner/Governance can withdraw staked tokens (e.g., if the contract is being deprecated, though careful with this). *Better: Implement this via Governance proposal requiring user consent or a specific contract state.* Let's remove this direct admin withdrawal.
    38. `getEssenceBalance(address _user)`: View function for a user's Essence balance.
    39. `getStakeInfo(address _user)`: View function showing user's current stake amount and last stake time.
    40. `getBloomCount()`: View function returning the total number of Blooms created.

**VI. Internal Functions (Helpers):**
    *   `_updateBloomState(uint256 _bloomId)`: Applies decay/growth based on time and environmental factors *before* performing an action.
    *   `_calculateDecay(uint256 _vitality, uint256 _timeDelta)`: Calculates vitality reduction.
    *   `_calculateGrowth(uint256 _rarity, uint256 _environmentalFactor, uint256 _nurtureBoost)`: Calculates potential property increase.
    *   `_generateBloomProperties(uint8 _bloomTypeIndex, bytes32 _seed)`: Generates initial/new properties based on type and randomness source (e.g., block hash).
    *   `_applyEnvironmentalEffect()`: Internal logic to compute or fetch the current environmental factor.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// Using minimal interfaces needed instead of full OpenZeppelin imports
interface IERC20 {
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
}

/**
 * @title EtherealBloomConservatory
 * @dev A smart contract creating a dynamic on-chain ecosystem of 'Blooms'.
 * Users stake ERC20 tokens for 'Essence', a resource used to interact with and nurture Blooms.
 * Blooms are dynamic, evolving based on user actions, time, and simulated environmental factors.
 * The system includes decentralized governance via a native BloomGovToken.
 */
contract EtherealBloomConservatory {

    // --- Outline and Function Summary ---
    //
    // I. Contract Overview:
    //    - Name: EtherealBloomConservatory
    //    - Core Concept: Cultivate dynamic digital "Blooms" using staked resources ("Essence") within an on-chain ecosystem governed by token holders ("BloomGovToken").
    //    - Key Features: Dynamic asset state, resource staking & management, interactive asset mechanics, simulated environmental influence, token-based governance.
    //
    // II. State Variables:
    //    - Addresses for owner, staking token, and governance token.
    //    - Mappings for Essence balances, Gov token balances, Bloom data, Bloom ownership, user staked amounts, staking timestamps.
    //    - Counters for Bloom IDs and Proposal IDs.
    //    - Config parameters for staking rates, interaction costs, decay rates, governance settings (quorum, periods).
    //    - Structs for `Bloom`, `Proposal`, `BloomTypeConfig`.
    //    - Enums for `BloomState`, `ProposalState`.
    //    - Arrays/Mappings for tracking Bloom types and proposals.
    //
    // III. Events:
    //    - BloomCreated, BloomNurtured, BloomsCrossPollinated, BloomTransferred, BloomRenounced
    //    - EssenceClaimed, TokensStaked, TokensUnstaked, EssenceTransferred
    //    - ProposalCreated, Voted, ProposalExecuted, ProposalQueued
    //    - ParamsUpdated, BloomTypeAdded
    //
    // IV. Modifiers:
    //    - onlyOwner, whenNotPaused, whenPaused
    //
    // V. Functions (40+):
    //    1. constructor()
    //    2. pause()
    //    3. unpause()
    //    4. setEssenceStakeToken(address _token)
    //    5. setEssenceRate(uint256 _rate)
    //    6. stakeForEssence(uint256 _amount)
    //    7. claimEssence()
    //    8. unstake(uint256 _amount)
    //    9. getAccruedEssence(address _user)
    //    10. transferEssence(address _recipient, uint256 _amount)
    //    11. createInitialBloom(uint8 _bloomTypeIndex)
    //    12. nurtureBloom(uint256 _bloomId)
    //    13. crossPollinateBlooms(uint256 _bloomId1, uint256 _bloomId2)
    //    14. transferBloom(address _to, uint256 _bloomId)
    //    15. renounceBloomOwnership(uint256 _bloomId)
    //    16. getBloomProperties(uint256 _bloomId)
    //    17. getUserBlooms(address _user)
    //    18. getBloomOwner(uint256 _bloomId)
    //    19. isBloomAlive(uint256 _bloomId)
    //    20. getBloomCurrentValueEstimate(uint256 _bloomId)
    //    21. balanceOfGov(address _user)
    //    22. getTotalGovSupply()
    //    23. delegateGovVotes(address _delegatee)
    //    24. getVotes(address _user)
    //    25. propose(string memory _description, address _target, bytes memory _calldata)
    //    26. vote(uint256 _proposalId, bool _support)
    //    27. executeProposal(uint256 _proposalId)
    //    28. getProposalState(uint256 _proposalId)
    //    29. getProposalVotes(uint256 _proposalId)
    //    30. setGovParams(...)
    //    31. getGovParams()
    //    32. adminMintGovTokens(address _to, uint256 _amount)
    //    33. addBloomType(...)
    //    34. getBloomTypeProperties(uint8 _typeIndex)
    //    35. getEnvironmentalFactor()
    //    36. burnEssence(uint256 _amount)
    //    37. getEssenceBalance(address _user)
    //    38. getStakeInfo(address _user)
    //    39. getBloomCount()
    //    40. checkProposal(uint256 _proposalId) (Helper view function)
    //    41. getAllBloomTypeConfigs() (View function)
    //
    // VI. Internal Functions (Helpers):
    //    - _updateBloomState(uint256 _bloomId)
    //    - _calculateDecay(...)
    //    - _calculateGrowth(...)
    //    - _generateBloomProperties(...)
    //    - _applyEnvironmentalEffect()
    //    - _transferBloomOwnership(...)
    //    - _burnBloom(...)

    // --- Errors ---
    error NotOwner();
    error Paused();
    error NotPaused();
    error InsufficientEssence(uint256 required, uint256 has);
    error InsufficientGovTokens(uint256 required, uint256 has);
    error BloomNotFound(uint256 bloomId);
    error NotBloomOwner(uint256 bloomId, address caller);
    error BloomNotAlive(uint256 bloomId);
    error InvalidBloomType();
    error InsufficientStake(uint256 required, uint256 has);
    error NoAccruedEssence();
    error InvalidAmount();
    error TransferFailed();
    error ProposalNotFound(uint256 proposalId);
    error ProposalAlreadyVoted(uint256 proposalId, address voter);
    error ProposalNotInVotingPeriod(uint256 proposalId);
    error ProposalNotInExecutableState(uint256 proposalId);
    error ProposalExecutionFailed(uint256 proposalId);
    error InvalidProposalThreshold();
    error InvalidQuorum();
    error InvalidVotingPeriod();
    error InvalidTimelock();
    error ProposalAlreadyExecuted(uint256 proposalId);
    error DelegationRequired();

    // --- Events ---
    event BloomCreated(uint256 indexed bloomId, address indexed owner, uint8 bloomTypeIndex, uint256 initialVitality);
    event BloomNurtured(uint256 indexed bloomId, address indexed nurturer, uint256 newVitality, uint256 essenceSpent);
    event BloomsCrossPollinated(uint256 indexed bloomId1, uint256 indexed bloomId2, address indexed pollinator, uint256 newSeedBloomId, uint256 essenceSpent);
    event BloomTransferred(uint256 indexed bloomId, address indexed from, address indexed to);
    event BloomRenounced(uint256 indexed bloomId, address indexed owner);

    event EssenceClaimed(address indexed user, uint256 amount);
    event TokensStaked(address indexed user, uint256 amount, uint256 newTotalStake);
    event TokensUnstaked(address indexed user, uint256 amount, uint256 newTotalStake);
    event EssenceTransferred(address indexed from, address indexed to, uint256 amount);

    event ProposalCreated(uint256 indexed proposalId, address indexed proposer, string description);
    event Voted(uint256 indexed proposalId, address indexed voter, bool support, uint256 votes);
    event ProposalExecuted(uint256 indexed proposalId);

    event ParamsUpdated(string paramName, uint256 newValue);
    event BloomTypeAdded(uint8 indexed typeIndex, string name);
    event EssenceBurned(address indexed burner, uint256 amount);

    // --- State Variables ---
    address private _owner;
    bool private _paused;

    IERC20 public essenceStakeToken;
    uint256 public essenceRatePerSecond; // Essence tokens per staked token per second (adjust unit as needed)
    uint256 public constant ESSENCE_DECIMALS = 18; // Assume Essence is 18 decimals for simplicity

    mapping(address => uint256) public essenceBalances;
    mapping(address => uint256) public stakedBalances;
    mapping(address => uint256) public lastStakeClaimTime; // Last time user claimed Essence or staked/unstaked

    uint256 public bloomCreationCost;
    uint256 public nurtureCostPerPoint; // Cost per point of vitality/rarity increase
    uint256 public crossPollinateCost;
    uint256 public vitalityDecayRatePerSecond; // Points of vitality decay per second

    struct Bloom {
        uint256 vitality; // Health/energy level
        uint256 rarity; // A score influencing growth potential and value estimate
        uint8 evolutionStage; // 0 = Seed, 1 = Sprout, 2 = Bloom, etc.
        uint8 bloomTypeIndex; // Index linking to BloomTypeConfig
        uint256 lastInteractionTime; // Timestamp of last nurture/pollinate/create
        bytes32 bloomSeed; // A unique identifier based on creation/pollination
        BloomState state; // e.g., Alive, Dormant, Wilted
    }

    enum BloomState { Alive, Dormant, Wilted } // Dormant might require more essence to revive

    struct BloomTypeConfig {
        string name;
        uint256 initialVitality;
        uint256 initialRarity;
        uint256 growthFactor; // Multiplier for growth from nurture/environment
        uint256 decayFactor; // Multiplier for decay
        uint256 nurtureBoost; // Points gained per nurture
    }

    BloomTypeConfig[] public bloomTypeConfigs; // Array to store different bloom type configurations

    mapping(uint256 => Bloom) public blooms;
    mapping(uint256 => address) public bloomOwners;
    mapping(address => uint256[]) private _userBlooms; // To track blooms per user efficiently

    uint256 private _nextTokenId; // Counter for Blooms

    // --- Governance ---
    address public bloomGovToken; // Address of the governance token (this contract acts as the minter/ledger)
    mapping(address => uint256) private _govBalances;
    mapping(address => address) public delegates;
    mapping(address => uint256) private _currentVotes; // Simple tracking, snapshots needed for robust governance

    uint256 private _totalGovSupply;

    struct Proposal {
        uint256 id;
        address proposer;
        string description;
        address target; // Contract to call
        bytes calldataBytes; // Encoded function call
        uint256 voteStart;
        uint256 voteEnd;
        uint256 forVotes;
        uint256 againstVotes;
        bool executed;
        bool canceled; // Not implemented in detail, but good practice
        ProposalState state;
        // Add mapping to track who voted if needed: mapping(address => bool) hasVoted;
    }

    enum ProposalState { Pending, Active, Succeeded, Defeated, Executed, Expired }

    mapping(uint256 => Proposal) public proposals;
    uint256 private _nextProposalId;

    // Governance Parameters (can be set via governance proposals)
    uint256 public votingPeriod; // In seconds
    uint256 public quorumNumerator; // Numerator for quorum percentage (e.g., 4 = 4%)
    uint256 public constant QUORUM_DENOMINATOR = 100;
    uint256 public timelockDelay; // In seconds, time between proposal success and execution
    uint256 public proposalThreshold; // Minimum Gov tokens required to create a proposal

    // --- Modifiers ---
    modifier onlyOwner() {
        if (msg.sender != _owner) revert NotOwner();
        _;
    }

    modifier whenNotPaused() {
        if (_paused) revert Paused();
        _;
    }

    modifier whenPaused() {
        if (!_paused) revert NotPaused();
        _;
    }

    // --- Constructor ---
    constructor(address _initialGovMinter) {
        _owner = msg.sender;
        _paused = false; // Start unpaused

        // Initialize governance parameters (these should ideally be set by the initial minter via a proposal)
        // Set reasonable defaults - must be updated by governance later
        votingPeriod = 7 * 24 * 60 * 60; // 7 days
        quorumNumerator = 4; // 4% quorum
        timelockDelay = 2 * 24 * 60 * 60; // 2 days timelock
        proposalThreshold = 100 ether; // 100 Gov tokens threshold (assuming 18 decimals)

        // Deploy a simple internal Gov token or link an external one
        // For this example, we'll use an internal ledger for simplicity.
        // In a real scenario, this might deploy a separate Gov token contract.
        // Let's just use the contract itself as the "Gov token minter/ledger".
        bloomGovToken = address(this); // Point to itself for internal ledger

        // Initial parameters for Blooms and Essence
        essenceRatePerSecond = 1; // 1 Wei of Essence per staked token per second
        bloomCreationCost = 100 ether; // 100 Essence
        nurtureCostPerPoint = 1 ether; // 1 Essence per vitality/rarity point nurtured
        crossPollinateCost = 500 ether; // 500 Essence
        vitalityDecayRatePerSecond = 1; // 1 Vitality point decay per second

        // Add a couple of initial Bloom types (can be added later by governance too)
         _addBloomType("Basic Bloom", 1000, 100, 5, 1, 50); // Initial Vitality, Rarity, GrowthFactor, DecayFactor, NurtureBoost
         _addBloomType("Hardy Bloom", 1500, 80, 4, 0, 40);
    }

    // --- Pause Functionality ---
    /**
     * @dev Pauses the contract. Restricted to the owner.
     * Most functions interacting with state should be guarded by `whenNotPaused`.
     */
    function pause() external onlyOwner whenNotPaused {
        _paused = true;
        // Emit event if needed
    }

    /**
     * @dev Unpauses the contract. Restricted to the owner.
     */
    function unpause() external onlyOwner whenPaused {
        _paused = false;
        // Emit event if needed
    }

    // --- Configuration Functions (Ideally callable via Governance) ---
    /**
     * @dev Sets the ERC20 token address accepted for staking to earn Essence.
     * Can only be called by the owner initially, later via governance.
     * @param _token The address of the ERC20 staking token.
     */
    function setEssenceStakeToken(address _token) external onlyOwner { // Should be governance later
        essenceStakeToken = IERC20(_token);
        emit ParamsUpdated("EssenceStakeToken", uint256(uint160(_token)));
    }

    /**
     * @dev Sets the rate at which staked tokens generate Essence.
     * Rate is in Essence Wei per second per staked token (with staked token's decimals).
     * Can only be called by the owner initially, later via governance.
     * @param _rate The new essence rate per second per staked token.
     */
    function setEssenceRate(uint256 _rate) external onlyOwner { // Should be governance later
        essenceRatePerSecond = _rate;
        emit ParamsUpdated("EssenceRatePerSecond", _rate);
    }

    /**
     * @dev Sets the cost to create a new initial Bloom.
     * Can only be called by the owner initially, later via governance.
     * @param _cost The cost in Essence Wei.
     */
    function setBloomCreationCost(uint256 _cost) external onlyOwner { // Should be governance later
         bloomCreationCost = _cost;
         emit ParamsUpdated("BloomCreationCost", _cost);
    }

    /**
     * @dev Sets the Essence cost per point of vitality/rarity gained during nurturing.
     * Can only be called by the owner initially, later via governance.
     * @param _cost The cost in Essence Wei per point.
     */
    function setNurtureCostPerPoint(uint256 _cost) external onlyOwner { // Should be governance later
         nurtureCostPerPoint = _cost;
         emit ParamsUpdated("NurtureCostPerPoint", _cost);
    }

    /**
     * @dev Sets the Essence cost for cross-pollinating two Blooms.
     * Can only be called by the owner initially, later via governance.
     * @param _cost The cost in Essence Wei.
     */
    function setCrossPollinateCost(uint256 _cost) external onlyOwner { // Should be governance later
         crossPollinateCost = _cost;
         emit ParamsUpdated("CrossPollinateCost", _cost);
    }

    /**
     * @dev Sets the rate at which Blooms lose Vitality per second if not nurtured.
     * Can only be called by the owner initially, later via governance.
     * @param _rate The vitality points lost per second.
     */
    function setVitalityDecayRatePerSecond(uint256 _rate) external onlyOwner { // Should be governance later
         vitalityDecayRatePerSecond = _rate;
         emit ParamsUpdated("VitalityDecayRatePerSecond", _rate);
    }

    /**
     * @dev Adds a new Bloom Type configuration. Only callable via Governance.
     * @param _name Name of the bloom type.
     * @param _initialVitality Base initial vitality.
     * @param _initialRarity Base initial rarity.
     * @param _growthFactor Multiplier for growth.
     * @param _decayFactor Multiplier for decay.
     * @param _nurtureBoost Points gained per nurture action.
     */
    function addBloomType(
        string memory _name,
        uint256 _initialVitality,
        uint256 _initialRarity,
        uint256 _growthFactor,
        uint256 _decayFactor,
        uint256 _nurtureBoost
    ) external onlyOwner { // SHOULD BE GOVERNANCE CALL
        bloomTypeConfigs.push(BloomTypeConfig({
            name: _name,
            initialVitality: _initialVitality,
            initialRarity: _initialRarity,
            growthFactor: _growthFactor,
            decayFactor: _decayFactor,
            nurtureBoost: _nurtureBoost
        }));
        emit BloomTypeAdded(uint8(bloomTypeConfigs.length - 1), _name);
    }

    /**
     * @dev Gets the configuration for a specific Bloom type.
     * @param _typeIndex The index of the bloom type.
     * @return BloomTypeConfig struct.
     */
    function getBloomTypeProperties(uint8 _typeIndex) external view returns (BloomTypeConfig memory) {
        if (_typeIndex >= bloomTypeConfigs.length) revert InvalidBloomType();
        return bloomTypeConfigs[_typeIndex];
    }

    /**
     * @dev Gets all Bloom Type configurations.
     * @return An array of BloomTypeConfig structs.
     */
    function getAllBloomTypeConfigs() external view returns (BloomTypeConfig[] memory) {
        return bloomTypeConfigs;
    }


    // --- Essence Management ---
    /**
     * @dev Allows a user to stake the defined ERC20 token to accrue Essence.
     * Requires the user to have approved this contract to spend the tokens.
     * @param _amount The amount of staking tokens to stake.
     */
    function stakeForEssence(uint256 _amount) external whenNotPaused {
        if (_amount == 0) revert InvalidAmount();
        if (address(essenceStakeToken) == address(0)) revert("Staking token not set");

        // Claim pending Essence before updating stake
        claimEssence();

        // Transfer tokens from user to contract
        bool success = essenceStakeToken.transferFrom(msg.sender, address(this), _amount);
        if (!success) revert TransferFailed();

        stakedBalances[msg.sender] += _amount;
        lastStakeClaimTime[msg.sender] = block.timestamp; // Update claim time

        emit TokensStaked(msg.sender, _amount, stakedBalances[msg.sender]);
    }

    /**
     * @dev Allows a user to claim their accrued Essence.
     */
    function claimEssence() public whenNotPaused {
        uint256 accrued = getAccruedEssence(msg.sender);
        if (accrued == 0) {
             // Optional: Check if any stake exists to differentiate no stake vs no recent accrual
             if(stakedBalances[msg.sender] == 0) revert InsufficientStake(1, 0); // Indicate no stake
             else revert NoAccruedEssence(); // Indicate stake exists but no accrual since last claim/stake
        }

        essenceBalances[msg.sender] += accrued;
        lastStakeClaimTime[msg.sender] = block.timestamp; // Reset claim time

        emit EssenceClaimed(msg.sender, accrued);
    }

    /**
     * @dev Allows a user to unstake their tokens. Accrued Essence is claimed automatically.
     * @param _amount The amount of staking tokens to unstake.
     */
    function unstake(uint256 _amount) external whenNotPaused {
        if (_amount == 0) revert InvalidAmount();
        if (_amount > stakedBalances[msg.sender]) revert InsufficientStake(_amount, stakedBalances[msg.sender]);
        if (address(essenceStakeToken) == address(0)) revert("Staking token not set");

        // Claim pending Essence before unstaking
        claimEssence();

        stakedBalances[msg.sender] -= _amount;
        lastStakeClaimTime[msg.sender] = block.timestamp; // Update claim time

        // Transfer tokens back to user
        bool success = essenceStakeToken.transfer(msg.sender, _amount);
        if (!success) revert TransferFailed();

        emit TokensUnstaked(msg.sender, _amount, stakedBalances[msg.sender]);
    }

    /**
     * @dev Calculates the amount of Essence a user has accrued since their last claim/stake/unstake.
     * @param _user The address of the user.
     * @return The amount of accrued Essence.
     */
    function getAccruedEssence(address _user) public view returns (uint256) {
        uint256 staked = stakedBalances[_user];
        if (staked == 0) return 0;

        uint256 timeElapsed = block.timestamp - lastStakeClaimTime[_user];
        return staked * essenceRatePerSecond * timeElapsed; // Simple linear accrual
    }

     /**
     * @dev Gets a user's current stake amount and last claim/stake time.
     * @param _user The address of the user.
     * @return stakeAmount The user's staked balance.
     * @return lastClaimTime The timestamp of their last claim, stake, or unstake.
     */
    function getStakeInfo(address _user) external view returns (uint256 stakeAmount, uint256 lastClaimTime) {
        return (stakedBalances[_user], lastStakeClaimTime[_user]);
    }


    /**
     * @dev Gets a user's current Essence balance.
     * @param _user The address of the user.
     * @return The Essence balance.
     */
    function getEssenceBalance(address _user) external view returns (uint256) {
        return essenceBalances[_user];
    }

    /**
     * @dev Allows a user to transfer Essence to another address.
     * @param _recipient The address to transfer Essence to.
     * @param _amount The amount of Essence to transfer.
     */
    function transferEssence(address _recipient, uint256 _amount) external whenNotPaused {
        if (_amount == 0) revert InvalidAmount();
        if (essenceBalances[msg.sender] < _amount) revert InsufficientEssence(_amount, essenceBalances[msg.sender]);

        essenceBalances[msg.sender] -= _amount;
        essenceBalances[_recipient] += _amount;

        emit EssenceTransferred(msg.sender, _recipient, _amount);
    }

    /**
     * @dev Allows a user to burn Essence. Can have ecosystem-wide effects or temporary buffs.
     * For this example, let's say burning gives a temporary small vitality boost to ALL of the user's ALIVE blooms.
     * @param _amount The amount of Essence to burn.
     */
    function burnEssence(uint256 _amount) external whenNotPaused {
        if (_amount == 0) revert InvalidAmount();
        if (essenceBalances[msg.sender] < _amount) revert InsufficientEssence(_amount, essenceBalances[msg.sender]);

        essenceBalances[msg.sender] -= _amount;

        // Apply a temporary boost to the user's blooms
        // (Implementation detail: Could iterate userBlooms and add temporary vitality)
        // For simplicity here, let's just emit the event and leave the effect logic more conceptual or for a helper contract.
        // In a real Dapp, this would likely involve complex calculations.
        // uint256 boostAmount = _amount / 10; // Example calculation
        // for (uint256 bloomId : _userBlooms[msg.sender]) {
        //     if (blooms[bloomId].state == BloomState.Alive) {
        //          _updateBloomState(bloomId); // Update before boosting
        //          blooms[bloomId].vitality += boostAmount; // Apply boost
        //          // Capping vitality might be needed
        //     }
        // }

        emit EssenceBurned(msg.sender, _amount);
    }


    // --- Bloom Management and Interaction ---
    /**
     * @dev Creates a new initial Bloom for the caller. Consumes Essence.
     * Initial properties are influenced by the selected type and block data.
     * @param _bloomTypeIndex The index of the desired Bloom type configuration.
     */
    function createInitialBloom(uint8 _bloomTypeIndex) external whenNotPaused {
        if (_bloomTypeIndex >= bloomTypeConfigs.length) revert InvalidBloomType();
        if (essenceBalances[msg.sender] < bloomCreationCost) revert InsufficientEssence(bloomCreationCost, essenceBalances[msg.sender]);

        essenceBalances[msg.sender] -= bloomCreationCost;

        uint256 newBloomId = _nextTokenId++;
        bytes32 initialSeed = keccak256(abi.encodePacked(block.timestamp, block.prevrandao, msg.sender, newBloomId)); // Use prevrandao for randomness source

        BloomTypeConfig memory typeConfig = bloomTypeConfigs[_bloomTypeIndex];

        blooms[newBloomId] = Bloom({
            vitality: typeConfig.initialVitality,
            rarity: typeConfig.initialRarity,
            evolutionStage: 0, // Starts as Seed
            bloomTypeIndex: _bloomTypeIndex,
            lastInteractionTime: block.timestamp,
            bloomSeed: initialSeed,
            state: BloomState.Alive // Starts alive
        });

        _transferBloomOwnership(address(0), msg.sender, newBloomId);

        emit BloomCreated(newBloomId, msg.sender, _bloomTypeIndex, typeConfig.initialVitality);
    }

     /**
     * @dev Nurtures a specific Bloom, increasing its Vitality and potentially Rarity. Consumes Essence.
     * Also updates the Bloom's state based on elapsed time before applying nurture.
     * @param _bloomId The ID of the Bloom to nurture.
     */
    function nurtureBloom(uint256 _bloomId) external whenNotPaused {
        Bloom storage bloom = blooms[_bloomId];
        if (bloomOwners[_bloomId] == address(0)) revert BloomNotFound(_bloomId);
        if (bloomOwners[_bloomId] != msg.sender) revert NotBloomOwner(_bloomId, msg.sender);
        if (bloom.state != BloomState.Alive) revert BloomNotAlive(_bloomId);

        // Apply time-based state changes (decay/growth) before nurturing
        _updateBloomState(_bloomId);

        BloomTypeConfig memory typeConfig = bloomTypeConfigs[bloom.bloomTypeIndex];

        // Calculate nurture effect and cost
        uint256 vitalityIncrease = typeConfig.nurtureBoost;
        uint256 rarityIncrease = vitalityIncrease / 10; // Example: Small rarity gain
        uint256 totalPointsGained = vitalityIncrease + rarityIncrease;
        uint256 cost = totalPointsGained * nurtureCostPerPoint;

        if (essenceBalances[msg.sender] < cost) revert InsufficientEssence(cost, essenceBalances[msg.sender]);

        essenceBalances[msg.sender] -= cost;

        // Apply nurture effect
        bloom.vitality += vitalityIncrease;
        bloom.rarity += rarityIncrease; // Rarity can potentially grow
        bloom.lastInteractionTime = block.timestamp;

        // Cap vitality at some max, e.g., 2x initial or a fixed cap
        uint256 maxVitality = typeConfig.initialVitality * 2; // Example cap
        if (bloom.vitality > maxVitality) {
            bloom.vitality = maxVitality;
        }

        emit BloomNurtured(_bloomId, msg.sender, bloom.vitality, cost);
    }

    /**
     * @dev Combines two Blooms to potentially create a new "seed" Bloom or significantly alter the parents. Consumes Essence.
     * This is a complex mechanic; the implementation here is simplified.
     * Updates the state of parent Blooms based on elapsed time before pollinating.
     * @param _bloomId1 The ID of the first Bloom.
     * @param _bloomId2 The ID of the second Bloom.
     */
    function crossPollinateBlooms(uint256 _bloomId1, uint256 _bloomId2) external whenNotPaused {
        if (_bloomId1 == _bloomId2) revert("Cannot pollinate a bloom with itself");

        Bloom storage bloom1 = blooms[_bloomId1];
        Bloom storage bloom2 = blooms[_bloomId2];

        if (bloomOwners[_bloomId1] == address(0) || bloomOwners[_bloomId2] == address(0)) revert BloomNotFound(_bloomId1 == address(0) ? _bloomId1 : _bloomId2);
        if (bloomOwners[_bloomId1] != msg.sender || bloomOwners[_bloomId2] != msg.sender) revert NotBloomOwner(bloomOwners[_bloomId1] != msg.sender ? _bloomId1 : _bloomId2, msg.sender);
        if (bloom1.state != BloomState.Alive || bloom2.state != BloomState.Alive) revert BloomNotAlive(bloom1.state != BloomState.Alive ? _bloomId1 : _bloomId2);
        if (essenceBalances[msg.sender] < crossPollinateCost) revert InsufficientEssence(crossPollinateCost, essenceBalances[msg.sender]);

        // Apply time-based state changes before pollinating
        _updateBloomState(_bloomId1);
        _updateBloomState(_bloomId2);

        essenceBalances[msg.sender] -= crossPollinateCost;

        // --- Simplified Pollination Logic ---
        // Create a new seed Bloom based on combined properties
        uint256 newBloomId = _nextTokenId++;
        // A new seed based on parents' seeds and transaction data
        bytes32 newSeed = keccak256(abi.encodePacked(bloom1.bloomSeed, bloom2.bloomSeed, block.timestamp, block.prevrandao, msg.sender));

        // Example combination logic: weighted average of vitality and rarity, maybe inherit type from dominant parent or random
        uint8 newBloomTypeIndex = block.prevrandao[0] % bloomTypeConfigs.length; // Random type from existing
        BloomTypeConfig memory typeConfig = bloomTypeConfigs[newBloomTypeIndex];

        uint256 combinedVitality = (bloom1.vitality + bloom2.vitality) / 2; // Simple average
        uint256 combinedRarity = (bloom1.rarity + bloom2.rarity) / 2;

        // Add some randomness influenced by the new seed and environmental factor
        uint256 environmental = _applyEnvironmentalEffect();
        combinedVitality = combinedVitality + (uint256(newSeed) % 100) * environmental / 100;
        combinedRarity = combinedRarity + (uint256(newSeed) % 50) * environmental / 50;

         blooms[newBloomId] = Bloom({
            vitality: combinedVitality > typeConfig.initialVitality ? combinedVitality : typeConfig.initialVitality, // Ensure minimum
            rarity: combinedRarity > typeConfig.initialRarity ? combinedRarity : typeConfig.initialRarity, // Ensure minimum
            evolutionStage: 0, // Starts as Seed
            bloomTypeIndex: newBloomTypeIndex,
            lastInteractionTime: block.timestamp,
            bloomSeed: newSeed,
            state: BloomState.Alive
        });

        _transferBloomOwnership(address(0), msg.sender, newBloomId);

        // Optionally, modify parent blooms after pollination (e.g., slight vitality reduction)
        bloom1.vitality = bloom1.vitality * 9 / 10; // Reduce vitality by 10%
        bloom2.vitality = bloom2.vitality * 9 / 10;
        bloom1.lastInteractionTime = block.timestamp; // Update interaction times
        bloom2.lastInteractionTime = block.timestamp;


        emit BloomsCrossPollinated(_bloomId1, _bloomId2, msg.sender, newBloomId, crossPollinateCost);
    }

    /**
     * @dev Transfers ownership of a Bloom.
     * @param _to The recipient address.
     * @param _bloomId The ID of the Bloom to transfer.
     */
    function transferBloom(address _to, uint256 _bloomId) external whenNotPaused {
        if (bloomOwners[_bloomId] == address(0)) revert BloomNotFound(_bloomId);
        if (bloomOwners[_bloomId] != msg.sender) revert NotBloomOwner(_bloomId, msg.sender);
        if (_to == address(0)) revert("Cannot transfer to zero address");

        _transferBloomOwnership(msg.sender, _to, _bloomId);

        emit BloomTransferred(_bloomId, msg.sender, _to);
    }

     /**
     * @dev Allows a user to renounce ownership of a Bloom (effectively burning it).
     * @param _bloomId The ID of the Bloom to renounce.
     */
    function renounceBloomOwnership(uint256 _bloomId) external whenNotPaused {
        if (bloomOwners[_bloomId] == address(0)) revert BloomNotFound(_bloomId);
        if (bloomOwners[_bloomId] != msg.sender) revert NotBloomOwner(_bloomId, msg.sender);

        _burnBloom(_bloomId);

        emit BloomRenounced(_bloomId, msg.sender);
    }


    /**
     * @dev Gets the current properties of a Bloom, updating its state based on time first.
     * @param _bloomId The ID of the Bloom.
     * @return A tuple containing the Bloom's properties.
     */
    function getBloomProperties(uint256 _bloomId) external view returns (
        uint256 vitality,
        uint256 rarity,
        uint8 evolutionStage,
        uint8 bloomTypeIndex,
        uint256 lastInteractionTime,
        bytes32 bloomSeed,
        BloomState state
    ) {
         if (bloomOwners[_bloomId] == address(0)) revert BloomNotFound(_bloomId);

        // Create a temporary copy to apply time-based state changes for the view call
        Bloom memory tempBloom = blooms[_bloomId];
        uint256 timeDelta = block.timestamp - tempBloom.lastInteractionTime;

        if (timeDelta > 0 && tempBloom.state == BloomState.Alive) {
             // Calculate decay
            uint256 decayAmount = _calculateDecay(tempBloom.vitality, timeDelta);
            if (tempBloom.vitality <= decayAmount) {
                 tempBloom.vitality = 0;
                 tempBloom.state = BloomState.Wilted; // Becomes wilted if vitality drops to 0
             } else {
                 tempBloom.vitality -= decayAmount;
             }
            // Decay can also affect rarity slightly? (Optional)
            // tempBloom.rarity = tempBloom.rarity > decayAmount / 10 ? tempBloom.rarity - decayAmount / 10 : 0;
        }

        return (
            tempBloom.vitality,
            tempBloom.rarity,
            tempBloom.evolutionStage,
            tempBloom.bloomTypeIndex,
            tempBloom.lastInteractionTime,
            tempBloom.bloomSeed,
            tempBloom.state
        );
    }

    /**
     * @dev Gets all Bloom IDs owned by a user.
     * @param _user The address of the user.
     * @return An array of Bloom IDs.
     */
    function getUserBlooms(address _user) external view returns (uint256[] memory) {
        return _userBlooms[_user];
    }

    /**
     * @dev Gets the total number of Blooms created.
     * @return The total count.
     */
     function getBloomCount() external view returns (uint256) {
         return _nextTokenId;
     }


    /**
     * @dev Checks if a Bloom is currently alive (Vitality > 0).
     * @param _bloomId The ID of the Bloom.
     * @return True if the Bloom is alive, false otherwise.
     */
    function isBloomAlive(uint256 _bloomId) external view returns (bool) {
         if (bloomOwners[_bloomId] == address(0)) return false; // Not found implies not alive
         Bloom memory bloom = blooms[_bloomId];
         // Apply decay simulation for view
         uint256 timeDelta = block.timestamp - bloom.lastInteractionTime;
         uint256 decayAmount = _calculateDecay(bloom.vitality, timeDelta);
         return bloom.vitality > decayAmount && bloom.state == BloomState.Alive;
    }

    /**
     * @dev Provides a conceptual estimate of a Bloom's 'value' based on its properties.
     * This is not a market price, but an internal score.
     * Updates the Bloom's state based on time first for the estimate.
     * @param _bloomId The ID of the Bloom.
     * @return The estimated value score.
     */
    function getBloomCurrentValueEstimate(uint256 _bloomId) external view returns (uint256) {
         if (bloomOwners[_bloomId] == address(0)) return 0;
         Bloom memory tempBloom = blooms[_bloomId]; // Use temporary copy for simulation
         uint256 timeDelta = block.timestamp - tempBloom.lastInteractionTime;

         // Apply decay simulation for view
         if (timeDelta > 0 && tempBloom.state == BloomState.Alive) {
             uint256 decayAmount = _calculateDecay(tempBloom.vitality, timeDelta);
              if (tempBloom.vitality <= decayAmount) {
                 tempBloom.vitality = 0;
             } else {
                 tempBloom.vitality -= decayAmount;
             }
         }

         // Simple value formula: Vitality * Rarity * (EvolutionStage + 1) * BloomTypeGrowthFactor modifier
         // Ensure no division by zero if factors are 0
         uint256 growthFactor = bloomTypeConfigs[tempBloom.bloomTypeIndex].growthFactor;
         uint256 decayFactor = bloomTypeConfigs[tempBloom.bloomTypeIndex].decayFactor; // Could slightly penalize value based on decay tendency

         uint256 baseValue = tempBloom.vitality * tempBloom.rarity;
         uint256 stageMultiplier = tempBloom.evolutionStage + 1;
         uint256 typeModifier = growthFactor > 0 ? (growthFactor * 100) / (decayFactor > 0 ? decayFactor : 1) : 100; // Example modifier

         // Ensure vitality is not zero for calculation if wilted in simulation
         uint256 effectiveVitality = tempBloom.state == BloomState.Wilted ? 0 : tempBloom.vitality;

         return (effectiveVitality * tempBloom.rarity * stageMultiplier * typeModifier) / 100; // Scale down by 100 due to typeModifier scale
    }

    /**
     * @dev Returns the current simulated environmental factor.
     * For this example, uses a simple computation based on the block hash.
     * @return The environmental factor value.
     */
    function getEnvironmentalFactor() external view returns (uint256) {
        // Example: Use bits of block hash for a simple environmental factor
        // Shift and mask to get a value between 0 and 255
        return uint256(uint8(bytes32(block.prevrandao))); // Use prevrandao for randomness source
    }


    // --- Internal Bloom Helpers ---

    /**
     * @dev Internal function to update a Bloom's state based on time elapsed.
     * Applies decay if the Bloom is Alive. Can apply growth/environmental effects here too.
     * @param _bloomId The ID of the Bloom to update.
     */
    function _updateBloomState(uint256 _bloomId) internal {
        Bloom storage bloom = blooms[_bloomId];
        uint256 timeDelta = block.timestamp - bloom.lastInteractionTime;

        if (timeDelta > 0 && bloom.state == BloomState.Alive) {
            // Apply decay
            uint256 decayAmount = _calculateDecay(bloom.vitality, timeDelta);
             if (bloom.vitality <= decayAmount) {
                 bloom.vitality = 0;
                 bloom.state = BloomState.Wilted; // Becomes wilted if vitality drops to 0
             } else {
                 bloom.vitality -= decayAmount;
             }

            // Apply subtle growth based on environment if decay didn't kill it
            if (bloom.state == BloomState.Alive) {
                uint256 growthAmount = _calculateGrowth(bloom.rarity, _applyEnvironmentalEffect(), 0); // 0 nurture boost here
                 bloom.vitality += growthAmount / 10; // Small passive growth
            }

            // bloom.lastInteractionTime = block.timestamp; // Only update on *interaction*, not just view/update
        }
        // Note: lastInteractionTime is updated by external interaction functions (nurture, pollinate, create)
    }

    /**
     * @dev Internal function to calculate vitality decay based on time.
     * @param _vitality Current vitality.
     * @param _timeDelta Time elapsed in seconds.
     * @return The amount of vitality to decay.
     */
    function _calculateDecay(uint256 _vitality, uint256 _timeDelta) internal view returns (uint256) {
        // Decay scales with time and bloom's decay factor
        uint256 decayFactor = vitalityDecayRatePerSecond; // Base decay rate
        // Could add a factor based on BloomType: decayFactor = vitalityDecayRatePerSecond * bloomTypeConfigs[bloom.bloomTypeIndex].decayFactor / 100;
        return _timeDelta * decayFactor; // Simple linear decay
    }

     /**
     * @dev Internal function to calculate potential growth based on rarity and environmental factors.
     * @param _rarity Current rarity.
     * @param _environmentalFactor Current environmental factor.
     * @param _nurtureBoost Boost from specific nurture action.
     * @return The potential growth amount.
     */
    function _calculateGrowth(uint256 _rarity, uint256 _environmentalFactor, uint256 _nurtureBoost) internal view returns (uint256) {
        // Growth scales with rarity, nurture boost, and environmental factor
        // Example: Growth = (rarity * environmentalFactor / 255 + nurtureBoost) * typeGrowthFactor / 100
        // Simplification:
        uint256 envEffect = (_rarity * _environmentalFactor) / 255; // Scale env effect by rarity
        return envEffect + _nurtureBoost;
    }

     /**
     * @dev Internal function to compute the current environmental factor.
     * Can be based on block hash, time, or other on-chain data.
     * @return The environmental factor value (e.g., 0-255).
     */
    function _applyEnvironmentalEffect() internal view returns (uint256) {
        // Use bits of the block hash for a somewhat random value
        // uint256 factor = uint256(uint8(bytes32(block.blockhash(block.number - 1)))) % 100; // Factor 0-99
        // Using prevrandao (formerly block.difficulty) for post-Merge randomness
         return uint256(uint8(bytes32(block.prevrandao))); // Factor 0-255
    }


    /**
     * @dev Internal function to handle Bloom ownership transfer (ERC721-like).
     * Removes from old owner's list, adds to new owner's list.
     * @param _from The address transferring ownership (0 for mint).
     * @param _to The address receiving ownership.
     * @param _bloomId The ID of the Bloom.
     */
    function _transferBloomOwnership(address _from, address _to, uint256 _bloomId) internal {
        if (_from != address(0)) {
             // Remove from old owner's list (inefficient array removal - consider better data structure for large numbers)
             uint256[] storage userBloomsFrom = _userBlooms[_from];
             for (uint i = 0; i < userBloomsFrom.length; i++) {
                 if (userBloomsFrom[i] == _bloomId) {
                     userBloomsFrom[i] = userBloomsFrom[userBloomsFrom.length - 1];
                     userBloomsFrom.pop();
                     break;
                 }
             }
        }

        bloomOwners[_bloomId] = _to;
        _userBlooms[_to].push(_bloomId); // Add to new owner's list
    }

     /**
     * @dev Internal function to handle burning a Bloom.
     * Sets owner to zero address and removes from user's list.
     * @param _bloomId The ID of the Bloom to burn.
     */
    function _burnBloom(uint256 _bloomId) internal {
        address owner = bloomOwners[_bloomId];
        if (owner == address(0)) return; // Already burned or not found

        _transferBloomOwnership(owner, address(0), _bloomId);
        // Consider deleting bloom data to save space? `delete blooms[_bloomId];` (Makes getBloomProperties revert)
        // For this example, we'll keep the bloom data but mark it as wilted/burned conceptually by owner=address(0)
        blooms[_bloomId].state = BloomState.Wilted; // Mark as wilted/burned state
        blooms[_bloomId].vitality = 0;
        blooms[_bloomId].rarity = 0;
    }

    /**
     * @dev Internal helper to add bloom types during construction or governance.
     * @param _name Name of the bloom type.
     * @param _initialVitality Base initial vitality.
     * @param _initialRarity Base initial rarity.
     * @param _growthFactor Multiplier for growth.
     * @param _decayFactor Multiplier for decay.
     * @param _nurtureBoost Points gained per nurture action.
     */
    function _addBloomType(
        string memory _name,
        uint256 _initialVitality,
        uint256 _initialRarity,
        uint256 _growthFactor,
        uint256 _decayFactor,
        uint256 _nurtureBoost
    ) internal {
         bloomTypeConfigs.push(BloomTypeConfig({
            name: _name,
            initialVitality: _initialVitality,
            initialRarity: _initialRarity,
            growthFactor: _growthFactor,
            decayFactor: _decayFactor,
            nurtureBoost: _nurtureBoost
        }));
        // No event here, event is in public addBloomType (callable by governance)
    }


    // --- Governance (Simplified) ---
    // Note: A real governance system would likely use delegates and snapshots from a dedicated ERC20/ERC721 contract.
    // This implementation keeps the token balance within this contract for simplicity, but it's less robust.
    // Delegation is included conceptually but snapshotting isn't.

    // Gov Token Balance (Internal Ledger)
    function balanceOfGov(address _user) public view returns (uint256) {
        // Simple balance check. For real governance, this would check historical balance at a snapshot block.
        // Need to consider delegated votes if calculating voting power
        return _govBalances[_user];
    }

    function getTotalGovSupply() public view returns (uint256) {
        return _totalGovSupply;
    }

    /**
     * @dev Mints initial Gov tokens. Restricted to the owner.
     * This should ideally be done once or controlled by governance later.
     * @param _to The recipient of the tokens.
     * @param _amount The amount of tokens to mint.
     */
    function adminMintGovTokens(address _to, uint256 _amount) external onlyOwner {
        if (_amount == 0) revert InvalidAmount();
        _govBalances[_to] += _amount;
        _totalGovSupply += _amount;
        // No standard ERC20 Transfer event emitted as it's an internal ledger
    }

    // Delegation (Basic)
    /**
     * @dev Delegates voting power.
     * @param _delegatee The address to delegate voting power to.
     */
    function delegateGovVotes(address _delegatee) external {
        // In a real system, this updates historical voting power.
        // Here, we just record the delegatee. Actual voting power calculation in `getVotes` is simplified.
        delegates[msg.sender] = _delegatee;
        // In a real system, this would trigger a delegate_changed event and snapshot vote changes.
    }

    /**
     * @dev Gets the current voting power for an address, considering delegation.
     * Simplified: Either the user's balance if no delegate, or the delegatee's balance.
     * For real governance, this requires snapshotting logic.
     * @param _user The address to get votes for.
     * @return The current voting power.
     */
    function getVotes(address _user) public view returns (uint256) {
        address delegatee = delegates[_user];
        if (delegatee == address(0)) {
            return _govBalances[_user]; // User votes with their own balance
        } else {
            return _govBalances[delegatee]; // User votes with delegatee's balance (simplified)
        }
        // In a real system, this would check `getPastVotes(delegatee, block.number - 1)`
    }

    // Proposals
    /**
     * @dev Creates a new governance proposal.
     * @param _description A description of the proposal.
     * @param _target The contract address the proposal will call.
     * @param _calldata The encoded function call data.
     */
    function propose(string memory _description, address _target, bytes memory _calldata) external whenNotPaused {
         // Simplified: check current votes. Real systems use snapshot.
         uint256 proposerVotes = getVotes(msg.sender);
         if (proposerVotes < proposalThreshold) revert InsufficientGovTokens(proposalThreshold, proposerVotes);

        uint256 proposalId = _nextProposalId++;
        proposals[proposalId] = Proposal({
            id: proposalId,
            proposer: msg.sender,
            description: _description,
            target: _target,
            calldataBytes: _calldata,
            voteStart: block.timestamp, // Voting starts immediately
            voteEnd: block.timestamp + votingPeriod,
            forVotes: 0,
            againstVotes: 0,
            executed: false,
            canceled: false,
            state: ProposalState.Pending // Starts Pending, moves Active after queue/validation (simplified to Active immediately)
        });

        proposals[proposalId].state = ProposalState.Active; // Simplified: Immediately active

        emit ProposalCreated(proposalId, msg.sender, _description);
    }

    /**
     * @dev Allows a user to vote on an active proposal.
     * @param _proposalId The ID of the proposal.
     * @param _support True for 'for', false for 'against'.
     */
    function vote(uint256 _proposalId, bool _support) external whenNotPaused {
        Proposal storage proposal = proposals[_proposalId];
        if (proposal.id == 0 && _proposalId != 0) revert ProposalNotFound(_proposalId); // Check if proposal exists

        if (proposal.state != ProposalState.Active) revert ProposalNotInVotingPeriod(_proposalId);

        // In a real system, you'd check if msg.sender has voted using a mapping
        // mapping(uint256 => mapping(address => bool)) private _hasVoted;
        // if (_hasVoted[_proposalId][msg.sender]) revert ProposalAlreadyVoted(_proposalId, msg.sender);
        // _hasVoted[_proposalId][msg.sender] = true;
        // NOTE: Without tracking `_hasVoted`, users could vote multiple times with this simplified implementation.
        // A real system needs this or uses vote delegation events with snapshotting.
         // For this example, we omit `_hasVoted` to reduce state complexity, acknowledging this limitation.

        // Get voting power at the start of the proposal (needs snapshotting in real system)
        // Simplified: Use current votes (inaccurate for real governance)
        uint256 voterVotes = getVotes(msg.sender);
        if (voterVotes == 0) revert DelegationRequired(); // User must have votes (either directly or delegated)

        if (_support) {
            proposal.forVotes += voterVotes;
        } else {
            proposal.againstVotes += voterVotes;
        }

        emit Voted(_proposalId, msg.sender, _support, voterVotes);
    }

    /**
     * @dev Executes a successful proposal after the voting period and timelock have passed.
     * Any address can call this function.
     * @param _proposalId The ID of the proposal.
     */
    function executeProposal(uint256 _proposalId) external whenNotPaused {
         Proposal storage proposal = proposals[_proposalId];
        if (proposal.id == 0 && _proposalId != 0) revert ProposalNotFound(_proposalId);

        // Check state transitions and requirements
        if (proposal.state == ProposalState.Executed) revert ProposalAlreadyExecuted(_proposalId);
        if (block.timestamp <= proposal.voteEnd + timelockDelay) revert ProposalNotInExecutableState(_proposalId); // Timelock not passed

        // Check if the proposal succeeded (quorum and majority)
        uint256 totalVotesCast = proposal.forVotes + proposal.againstVotes;
        // Quorum check: total votes >= total supply * quorumNumerator / QUORUM_DENOMINATOR
        uint256 quorumThreshold = (_totalGovSupply * quorumNumerator) / QUORUM_DENOMINATOR;
         if (totalVotesCast < quorumThreshold) revert ProposalNotInExecutableState(_proposalId); // Failed Quorum
         if (proposal.forVotes <= proposal.againstVotes) revert ProposalNotInExecutableState(_proposalId); // Failed Majority

        // Check if the proposal expired before hitting quorum or being executed
        // if (block.timestamp > proposal.voteEnd + timelockDelay && proposal.state != ProposalState.Succeeded) {
        //     proposal.state = ProposalState.Expired; // Or Defeated if failed majority/quorum
        // } // This logic is implicitly handled by the checks above

        // Update state to Succeeded before execution attempt
        proposal.state = ProposalState.Succeeded; // Mark as Succeeded state for timelock period

        // Execute the proposal's calldata
        (bool success, ) = proposal.target.call(proposal.calldataBytes); // Use call to allow arbitrary execution

        if (!success) {
            // Revert or log failure? Reverting is safer for critical actions.
             revert ProposalExecutionFailed(_proposalId);
             // In a real system, may revert or transition state to FailedExecution and allow retries or cancellation.
        }

        proposal.executed = true;
        proposal.state = ProposalState.Executed; // Final state

        emit ProposalExecuted(_proposalId);
    }

    /**
     * @dev Gets the current state of a proposal.
     * @param _proposalId The ID of the proposal.
     * @return The state of the proposal as a string.
     */
    function getProposalState(uint256 _proposalId) public view returns (ProposalState) {
        return checkProposal(_proposalId);
    }

     /**
     * @dev Internal/Helper view function to determine the state of a proposal.
     * @param _proposalId The ID of the proposal.
     * @return The state of the proposal.
     */
    function checkProposal(uint256 _proposalId) public view returns (ProposalState) {
        Proposal memory proposal = proposals[_proposalId];
        if (proposal.id == 0 && _proposalId != 0) return ProposalState.Pending; // Represents 'not found' initially

        if (proposal.executed) return ProposalState.Executed;
        if (proposal.canceled) return ProposalState.Canceled; // If cancellation was implemented

        if (block.timestamp < proposal.voteStart) return ProposalState.Pending; // Voting hasn't started
        if (block.timestamp >= proposal.voteStart && block.timestamp <= proposal.voteEnd) return ProposalState.Active; // Voting is active

        // Voting period ended. Check result.
        uint256 totalVotesCast = proposal.forVotes + proposal.againstVotes;
        uint256 quorumThreshold = (_totalGovSupply * quorumNumerator) / QUORUM_DENOMINATOR;

        if (totalVotesCast < quorumThreshold || proposal.forVotes <= proposal.againstVotes) {
             // Failed quorum or failed majority
             return ProposalState.Defeated;
        }

        // Succeeded, but check timelock
        if (block.timestamp <= proposal.voteEnd + timelockDelay) {
             return ProposalState.Succeeded; // Succeeded, waiting for timelock
        } else {
             // Succeeded, timelock passed, but not yet executed. This state usually means it's ready to be executed.
             // If execution fails, it might transition to FailedExecution, but for this simple example,
             // once timelock passes and it's Succeeded, it's conceptually ready/executable.
             // If block.timestamp > proposal.voteEnd + timelockDelay, it *could* be executed, but if `executed` is false,
             // it might also be considered Expired if no one called `executeProposal`.
             // Let's refine state: If block.timestamp > proposal.voteEnd + timelockDelay AND !executed, it's Expired (didn't get executed in time window).
             // However, typical Governor contracts just require timelock to pass. Let's stick to Succeeded -> Executed transition.
             return ProposalState.Succeeded; // Still 'Succeeded' until executed
        }
    }


    /**
     * @dev Gets the vote counts for a proposal.
     * @param _proposalId The ID of the proposal.
     * @return forVotes The number of votes 'for'.
     * @return againstVotes The number of votes 'against'.
     */
    function getProposalVotes(uint256 _proposalId) external view returns (uint256 forVotes, uint256 againstVotes) {
         if (proposals[_proposalId].id == 0 && _proposalId != 0) revert ProposalNotFound(_proposalId);
         return (proposals[_proposalId].forVotes, proposals[_proposalId].againstVotes);
    }

    /**
     * @dev Sets governance parameters (voting period, quorum, timelock, proposal threshold).
     * This function should ONLY be callable by the contract itself via a successful governance proposal execution.
     * @param _votingPeriod The new voting period in seconds.
     * @param _quorumNumerator The new quorum numerator (percentage).
     * @param _timelockDelay The new timelock delay in seconds.
     * @param _proposalThreshold The new minimum token threshold to propose.
     */
    function setGovParams(
        uint256 _votingPeriod,
        uint256 _quorumNumerator,
        uint256 _timelockDelay,
        uint256 _proposalThreshold
    ) external {
        // Ensure this is called BY the contract itself (i.e., via executeProposal)
        // Check `msg.sender == address(this)` is one way, but not foolproof if executeProposal uses call.
        // A more robust way is to have a specific role checker or rely on the fact that `executeProposal`
        // is the only path to call this function with `proposal.target == address(this)`
        // For this example, we'll add a simple check, but note it's a simplification.
        require(msg.sender == address(this), "Only callable via governance execution");

        if (_votingPeriod == 0) revert InvalidVotingPeriod();
        if (_quorumNumerator > QUORUM_DENOMINATOR) revert InvalidQuorum();
        // Timelock can be 0? Depends on desired security.
        // Proposal threshold can be 0? Depends.
        if (_proposalThreshold > _totalGovSupply && _totalGovSupply > 0) revert InvalidProposalThreshold(); // Threshold can't be more than total supply (if supply > 0)

        votingPeriod = _votingPeriod;
        quorumNumerator = _quorumNumerator;
        timelockDelay = _timelockDelay;
        proposalThreshold = _proposalThreshold;

        emit ParamsUpdated("GovParams", 0); // Use 0 or a specific value to indicate group update
    }

    /**
     * @dev Gets the current governance parameters.
     * @return votingPeriod, quorumNumerator, timelockDelay, proposalThreshold.
     */
     function getGovParams() external view returns (uint256, uint256, uint256, uint256) {
         return (votingPeriod, quorumNumerator, timelockDelay, proposalThreshold);
     }
}
```