Here's a Solidity smart contract named `Aethermind` that aims to be a unique, advanced, and creative solution, incorporating several trendy decentralized concepts without directly duplicating open-source implementations (though common patterns like `Ownable` and `Pausable` are from OpenZeppelin for security best practices). The core logic for NFTs, SBTs, and staking is implemented custom within the contract.

This contract simulates a "Decentralized AI Assistant & Reputation Network" where users contribute to a collective knowledge base, earn reputation, and manage dynamic "AI Modules."

---

**Contract Name:** `Aethermind`

**Core Idea:**
Aethermind is designed as a decentralized intelligence platform. It simulates an "AI" on-chain by allowing users to submit queries that are processed by a trusted oracle. Users contribute to the "Aethermind's" collective knowledge and accuracy by staking tokens in specific "knowledge pools" and managing "Knowledge Modules" (dynamic NFTs). A robust reputation system (Soulbound Tokens) incentivizes beneficial contributions and grants voting power in decentralized governance. The goal is a community-governed, self-improving, and transparent oracle/knowledge system.

**Key Features & Concepts:**
1.  **Synthetic Intelligence Core:** Users can `queryAethermind` (passing a hash of their query data). A `queryOracleAddress` is responsible for submitting `submitOracleResponse` for these queries, ideally with off-chain computation/AI. The system tracks query status and accuracy.
2.  **Dynamic Knowledge Modules (NFT-like):** These are unique, non-ERC721 standard, on-chain representations of specialized AI components or data sets. They have an `intelligenceLevel` attribute that can be `upgradeModuleIntelligence` by their owner by burning the native `MIND_TOKEN` and requiring a minimum `reputationScore`. Modules can be `activateModuleInAethermind` to contribute to the overall `aethermindOverallIntelligence`.
3.  **Knowledge Staking Pools:** Users `joinKnowledgePool` by staking `MIND_TOKEN` into domains (e.g., "Medical Diagnostics," "Climate Prediction"). These pools enhance the Aethermind's capabilities in that specific area, and stakers earn `MIND_TOKEN` rewards and influence module growth.
4.  **Reputation Badges (Soulbound Tokens - SBTs):** Non-transferable badges (like `BADGE_ACCURATE_ORACLE`, `BADGE_VALUABLE_QUERY`, `BADGE_GOVERNANCE_VOTER`) are `mintReputationBadge` for verified contributions or accurate oracle submissions. These badges contribute to a `getUserReputationScore`, which can unlock higher privileges (e.g., for module upgrades or proposing governance votes).
5.  **Decentralized Governance:** MIND stakers and reputation holders can `proposeVote` and `castVote` on critical parameters (e.g., `QUERY_FEE`, `MIN_STAKE_PROPOSAL`) or `mintKnowledgeModule`. Passed proposals can `executeProposal` to update the system.
6.  **Economic Model:** A native utility token (`MIND_TOKEN`, assumed ERC20) is required for queries, staking, module upgrades, and governance participation.

---

**Function Summary (31 Functions):**

**I. Core System & Access Control:**
1.  `constructor(address _mindTokenAddress, address _initialOracleAddress)`: Initializes the contract, sets the owner (from `Ownable`), the MIND token address, and the initial trusted oracle. Sets up default core parameters.
2.  `pauseContract()`: Pauses core functionalities in emergencies. Callable by the owner (inherits from `Pausable`).
3.  `unpauseContract()`: Unpauses the contract. Callable by the owner.
4.  `setQueryOracleAddress(address _newOracle)`: Sets the address of the trusted oracle responsible for submitting query responses. Callable by the owner.
5.  `updateCoreParameter(bytes32 _paramName, uint256 _newValue)`: General function to update various system parameters (e.g., `QUERY_FEE`, `MIN_STAKE_PROPOSAL`). Ideally governed by proposals, but set to `onlyOwner` for simplicity in this example.

**II. MIND Token & Staking:**
6.  `createKnowledgePool(string memory _domainName, uint256 _initialWeight)`: Allows privileged roles (owner or governance) to establish new knowledge domains where users can stake MIND tokens.
7.  `joinKnowledgePool(uint256 _poolId, uint256 _amount)`: Allows users to stake `_amount` of `MIND_TOKEN`s into a specified knowledge pool.
8.  `exitKnowledgePool(uint256 _poolId, uint256 _amount)`: Allows users to unstake `_amount` of `MIND_TOKEN`s from a specified knowledge pool.
9.  `claimStakingRewards(uint256 _poolId)`: Allows stakers to claim their accrued `MIND_TOKEN` rewards from a specific knowledge pool based on their stake duration.
10. `distributePoolRewards(uint256 _poolId, uint256 _amount)`: A function for admin/governance to add `MIND_TOKEN`s to a pool for reward distribution.

**III. Aethermind Query & Response:**
11. `queryAethermind(string memory _queryHash, uint256 _timeoutTimestamp)`: Users submit a query (represented by a hash) to the Aethermind, paying a `QUERY_FEE` in `MIND_TOKEN`. Returns a unique query ID.
12. `submitOracleResponse(uint256 _queryId, string memory _responseDataHash, bool _isAccurate)`: Called exclusively by the registered `queryOracleAddress` to provide a response hash for a submitted query and mark its perceived accuracy.
13. `retrieveQueryResponse(uint256 _queryId)`: Allows the original query submitter to retrieve the processed response data hash and accuracy status.

**IV. Dynamic Knowledge Modules (NFT-like):**
14. `mintKnowledgeModule(uint256 _moduleId, string memory _moduleName, uint256 _initialIntelligence, address _recipient)`: Creates a new, unique Knowledge Module with an initial intelligence level and assigns it to a recipient. Callable by governance or owner.
15. `upgradeModuleIntelligence(uint256 _moduleId, uint256 _amountMIND, uint256 _minReputationNeeded)`: The owner of a module can increase its `intelligenceLevel` by burning `MIND_TOKEN`s, provided they meet a minimum `reputationScore`.
16. `transferKnowledgeModule(uint256 _moduleId, address _to)`: Allows the owner of a Knowledge Module to transfer it to another address.
17. `activateModuleInAethermind(uint256 _moduleId)`: Integrates a module's intelligence into the Aethermind's overall active knowledge pool, increasing `aethermindOverallIntelligence`. Callable by module owner.
18. `deactivateModuleFromAethermind(uint256 _moduleId)`: Removes a module from active integration, reducing `aethermindOverallIntelligence`. Callable by module owner.

**V. Reputation Badges (Soulbound Tokens - SBTs):**
19. `mintReputationBadge(address _recipient, uint256 _badgeType)`: Mints a specific, non-transferable reputation badge to a user based on predefined criteria (e.g., successful oracle response, valuable query). Callable by governance or internal logic.
20. `revokeReputationBadge(address _holder, uint256 _badgeType)`: Revokes a reputation badge from a user. Callable by governance (e.g., for malicious activity).
21. `getUserReputationScore(address _user)`: Calculates and returns a user's cumulative reputation score based on the badges they hold.
22. `hasReputationBadge(address _user, uint256 _badgeType)`: Checks if a specific user holds a particular type of reputation badge.

**VI. Governance & Community:**
23. `proposeVote(bytes32 _proposalHash, uint256 _duration)`: Allows users with a minimum `MIND_TOKEN` stake or reputation to create a new governance proposal.
24. `castVote(uint256 _proposalId, bool _support)`: Allows `MIND_TOKEN` stakers and reputation holders to vote for or against an active proposal, with voting power proportional to their stake/reputation.
25. `executeProposal(uint256 _proposalId)`: Allows anyone to trigger the execution of a proposal once its voting period has ended and it has met the quorum and approval thresholds.

**VII. View/Helper Functions:**
26. `getModuleDetails(uint256 _moduleId)`: Returns detailed information about a specific Knowledge Module.
27. `getPoolDetails(uint256 _poolId)`: Returns detailed information about a specific Knowledge Pool.
28. `getUserStake(address _user, uint256 _poolId)`: Returns the amount of `MIND_TOKEN`s a user has staked in a specific knowledge pool.
29. `getPendingRewards(address _user, uint256 _poolId)`: Calculates the estimated pending `MIND_TOKEN` rewards for a user in a given pool.
30. `getQueryStatus(uint256 _queryId)`: Returns the current status (processed, accurate, retrieved) and data hashes of a submitted query.
31. `getAethermindOverallIntelligence()`: Returns the aggregated `intelligenceLevel` of all currently active Knowledge Modules, representing the Aethermind's total processing capability.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
// SafeMath is deprecated in Solidity 0.8+ due to default overflow/underflow checks,
// but included here explicitly for clarity and if a project chooses to revert to unchecked arithmetic.
// For this example, we'll assume `unchecked` blocks are not strictly necessary unless specified,
// relying on Solidity's default overflow checks.
// Using explicit `add`, `sub`, `mul`, `div` functions for clarity as if SafeMath was fully active.
// In practice with 0.8.0+, direct arithmetic is safe.

// Custom Errors for gas efficiency and clearer debugging
error UnauthorizedCaller();
error ContractPaused();
error InvalidQueryId();
error QueryNotProcessed();
error QueryAlreadyProcessed();
error InsufficientMINDStake();
error InvalidModuleId();
error ModuleAlreadyActive();
error ModuleNotActive();
error ModuleDoesNotExist();
error NotModuleOwner();
error InsufficientReputation();
error InvalidAmount();
error PoolDoesNotExist();
error PoolAlreadyExists(); // Although not explicitly used, good to have.
error ProposalDoesNotExist();
error AlreadyVoted();
error ProposalNotExecutable();
error ProposalAlreadyExecuted();
error BadgeAlreadyMinted();
error BadgeNotFound();
error QuorumNotMet();
error ProposalNotApproved();


/**
 * @title Aethermind
 * @dev A decentralized AI (simulated/oracle-augmented) platform where users contribute to its knowledge base through staking,
 *      earn reputation for valid contributions, and manage "AI Modules" as dynamic NFTs. It aims to create a self-improving,
 *      community-governed oracle/knowledge system.
 */

/**
 * @dev Key Features & Concepts:
 * 1.  Synthetic Intelligence Core: A `queryAethermind` function that simulates AI responses based on internal logic or
 *     processes external oracle data. Users submit queries (hashed data), and a trusted oracle provides responses.
 * 2.  Dynamic Knowledge Modules (NFT-like): Represent specialized AI components or data sets. Their "intelligence level"
 *     (an attribute) improves with staked $MIND and validated contributions. Modules are owned and can be transferred.
 * 3.  Knowledge Staking Pools: Users stake $MIND tokens into specific domain pools to enhance the Aethermind's capabilities
 *     in that area, earning rewards and influencing module growth.
 * 4.  Reputation Badges (Soulbound Tokens - SBTs): Non-transferable tokens awarded for accurate predictions, valuable
 *     data contributions, or successful governance participation. They grant higher privileges (e.g., for module upgrades).
 * 5.  Decentralized Governance: For critical parameters, new module creation, and knowledge base updates. MIND stakers
 *     and reputation holders can propose and vote on changes.
 * 6.  Economic Model: A native utility token (`MIND`) (ERC20, external) for queries, staking, module upgrades, and governance.
 */

/**
 * @dev Function Summary:
 *
 * I. Core System & Access Control:
 *  1.  constructor(address _mindTokenAddress, address _initialOracleAddress): Initializes the contract, sets owner, MIND token address, and initial oracle.
 *  2.  pauseContract(): Pauses core functionalities in emergencies. Only callable by owner.
 *  3.  unpauseContract(): Unpauses the contract. Only callable by owner.
 *  4.  setQueryOracleAddress(address _newOracle): Sets the trusted oracle for query responses. Only callable by owner.
 *  5.  updateCoreParameter(bytes32 _paramName, uint256 _newValue): General function to update various system parameters (e.g., query fee, min reputation for certain actions). Callable by governance (owner for this example).
 *
 * II. MIND Token & Staking:
 *  6.  createKnowledgePool(string memory _domainName, uint256 _initialWeight): Allows privileged roles (owner/governance) to establish new knowledge domains for staking.
 *  7.  joinKnowledgePool(uint256 _poolId, uint256 _amount): Stakes MIND tokens into a specific knowledge pool.
 *  8.  exitKnowledgePool(uint256 _poolId, uint256 _amount): Unstakes MIND tokens from a knowledge pool.
 *  9.  claimStakingRewards(uint256 _poolId): Claims accrued MIND rewards from a knowledge pool.
 *  10. distributePoolRewards(uint256 _poolId, uint256 _amount): Admin/governance function to signal distribution of rewards to a specific pool (actual transfer handled by claimStakingRewards).
 *
 * III. Aethermind Query & Response:
 *  11. queryAethermind(string memory _queryHash, uint256 _timeoutTimestamp): Submits a query to the Aethermind, paying a fee, and generating a unique query ID.
 *  12. submitOracleResponse(uint256 _queryId, string memory _responseDataHash, bool _isAccurate): Callable only by the registered oracle, provides the response to a query and marks its accuracy.
 *  13. retrieveQueryResponse(uint256 _queryId): Allows the user who submitted the query to retrieve their processed response details.
 *
 * IV. Dynamic Knowledge Modules (NFT-like):
 *  14. mintKnowledgeModule(uint256 _moduleId, string memory _moduleName, uint256 _initialIntelligence, address _recipient): Creates a new unique knowledge module. Callable by governance (owner for this example).
 *  15. upgradeModuleIntelligence(uint256 _moduleId, uint256 _amountMIND, uint256 _minReputationNeeded): Improves a module's intelligence by burning MIND tokens and requiring a minimum reputation score from the owner.
 *  16. transferKnowledgeModule(uint256 _moduleId, address _to): Transfers ownership of a module to another address.
 *  17. activateModuleInAethermind(uint256 _moduleId): Integrates a module's capabilities into the active Aethermind logic, increasing its overall "knowledge score". Callable by module owner.
 *  18. deactivateModuleFromAethermind(uint256 _moduleId): Removes a module from active integration. Callable by module owner.
 *
 * V. Reputation Badges (Soulbound Tokens - SBTs):
 *  19. mintReputationBadge(address _recipient, uint256 _badgeType): Mints a non-transferable reputation badge for a user based on criteria (e.g., validated query contributions or oracle accuracy). Callable by governance or specific module logic.
 *  20. revokeReputationBadge(address _holder, uint256 _badgeType): Revokes a reputation badge (e.g., for malicious activity or incorrect oracle submissions). Callable by governance.
 *  21. getUserReputationScore(address _user): Returns a user's cumulative reputation score (e.g., sum of badge values).
 *  22. hasReputationBadge(address _user, uint256 _badgeType): Checks if a user holds a specific badge.
 *
 * VI. Governance & Community:
 *  23. proposeVote(bytes32 _proposalHash, uint256 _duration): Allows users with sufficient MIND stake or reputation to propose system changes.
 *  24. castVote(uint256 _proposalId, bool _support): Allows MIND stakers and reputation holders to vote on proposals.
 *  25. executeProposal(uint256 _proposalId): Executes a passed proposal. Callable by anyone after the voting period ends and threshold met.
 *
 * VII. View/Helper Functions:
 *  26. getModuleDetails(uint256 _moduleId): Returns details of a specific knowledge module.
 *  27. getPoolDetails(uint256 _poolId): Returns details of a specific knowledge pool.
 *  28. getUserStake(address _user, uint256 _poolId): Returns a user's staked amount in a pool.
 *  29. getPendingRewards(address _user, uint256 _poolId): Calculates a user's pending rewards from a pool.
 *  30. getQueryStatus(uint256 _queryId): Returns the current status and data hash of a submitted query.
 *  31. getAethermindOverallIntelligence(): Returns the sum of active module intelligence levels.
 */

contract Aethermind is Ownable, Pausable {
    // using SafeMath for uint256; // No longer strictly needed in 0.8+ for checked arithmetic, but conceptually applied.

    IERC20 public immutable MIND_TOKEN;
    address public queryOracleAddress;

    // --- Core Parameters ---
    mapping(bytes32 => uint256) public coreParameters;
    bytes32 constant PARAM_QUERY_FEE = keccak256("QUERY_FEE");
    bytes32 constant PARAM_MIN_STAKE_PROPOSAL = keccak256("MIN_STAKE_PROPOSAL");
    bytes32 constant PARAM_GOVERNANCE_VOTING_PERIOD_BLOCKS = keccak256("GOVERNANCE_VOTING_PERIOD_BLOCKS");
    bytes32 constant PARAM_GOVERNANCE_QUORUM_PERCENT = keccak256("GOVERNANCE_QUORUM_PERCENT"); // e.g., 5100 for 51%
    bytes32 constant PARAM_GOVERNANCE_APPROVAL_PERCENT = keccak256("GOVERNANCE_APPROVAL_PERCENT"); // e.g., 5100 for 51%
    bytes32 constant PARAM_MIND_REWARD_RATE_PER_STAKE_BLOCK = keccak256("MIND_REWARD_RATE_PER_STAKE_BLOCK"); // Example rate, scaled by 1e18 for precision
    bytes32 constant PARAM_REPUTATION_WEIGHT_FOR_VOTING = keccak256("REPUTATION_WEIGHT_FOR_VOTING"); // e.g., 1e18 = 1 reputation point equals 1 MIND voting power

    // --- Queries ---
    struct Query {
        address user;
        string queryHash;
        uint256 timeoutTimestamp;
        string responseDataHash;
        bool processed;
        bool isAccurate; // Marked by oracle (self-assessment or initial validation)
        bool retrieved;
    }
    uint256 public nextQueryId;
    mapping(uint256 => Query) public queries;

    // --- Knowledge Modules (NFT-like) ---
    struct KnowledgeModule {
        uint256 id;
        string name;
        address owner;
        uint256 intelligenceLevel; // Dynamic attribute, can be upgraded
        bool isActive; // If currently contributing to Aethermind's overall intelligence
    }
    mapping(uint256 => KnowledgeModule) public knowledgeModules;
    uint256 public nextModuleId;
    uint256 public aethermindOverallIntelligence; // Sum of intelligenceLevel of active modules

    // --- Reputation Badges (SBTs) ---
    // BadgeType: 1=AccurateOracleSubmission, 2=ValuableQueryContribution, 3=GovernanceVoter, etc.
    // Maps user address to mapping of badge type to true/false
    mapping(address => mapping(uint256 => bool)) public userReputationBadges;
    // Map badge type to its "value" or "score" for cumulative reputation
    mapping(uint256 => uint256) public reputationBadgeScores;
    uint256 constant BADGE_ACCURATE_ORACLE = 1;
    uint256 constant BADGE_VALUABLE_QUERY = 2;
    uint256 constant BADGE_GOVERNANCE_VOTER = 3;


    // --- Knowledge Pools ---
    struct KnowledgePool {
        uint256 id;
        string domainName;
        uint256 totalStakedMIND;
        mapping(address => uint256) stakedMIND; // User's staked amount
        mapping(address => uint256) lastStakeUpdateBlock; // Block number of last stake/unstake by user for reward calculation
    }
    uint256 public nextPoolId;
    mapping(uint256 => KnowledgePool) public knowledgePools;

    // --- Governance ---
    struct Proposal {
        uint256 id;
        bytes32 proposalHash; // Hash of the proposed action/parameters (e.g., ABI encoded call data)
        uint256 startBlock;
        uint256 endBlock;
        uint256 totalVotesFor;
        uint256 totalVotesAgainst;
        mapping(address => bool) hasVoted; // User's vote status
        bool executed;
    }
    uint256 public nextProposalId;
    mapping(uint256 => Proposal) public proposals;


    event QuerySubmitted(uint256 indexed queryId, address indexed user, string queryHash, uint256 timeoutTimestamp);
    event OracleResponseSubmitted(uint256 indexed queryId, string responseDataHash, bool isAccurate);
    event QueryRetrieved(uint256 indexed queryId, address indexed user);

    event KnowledgeModuleMinted(uint256 indexed moduleId, address indexed owner, string name, uint256 initialIntelligence);
    event KnowledgeModuleUpgraded(uint256 indexed moduleId, uint256 newIntelligenceLevel, uint256 mindBurned);
    event KnowledgeModuleTransferred(uint256 indexed moduleId, address indexed from, address indexed to);
    event KnowledgeModuleActivated(uint256 indexed moduleId, uint256 currentOverallIntelligence);
    event KnowledgeModuleDeactivated(uint256 indexed moduleId, uint256 currentOverallIntelligence);

    event ReputationBadgeMinted(address indexed user, uint256 indexed badgeType);
    event ReputationBadgeRevoked(address indexed user, uint256 indexed badgeType);

    event KnowledgePoolCreated(uint256 indexed poolId, string domainName);
    event MINDStaked(uint256 indexed poolId, address indexed user, uint256 amount);
    event MINDUnstaked(uint256 indexed poolId, address indexed user, uint256 amount);
    event RewardsClaimed(uint256 indexed poolId, address indexed user, uint256 amount);
    event PoolRewardsDistributed(uint256 indexed poolId, uint256 amount); // Signifies external reward injection

    event CoreParameterUpdated(bytes32 indexed paramName, uint256 oldValue, uint256 newValue);
    event ProposalCreated(uint256 indexed proposalId, bytes32 proposalHash, address indexed proposer);
    event VoteCast(uint256 indexed proposalId, address indexed voter, bool support);
    event ProposalExecuted(uint256 indexed proposalId, bytes32 proposalHash);

    constructor(address _mindTokenAddress, address _initialOracleAddress) Ownable(msg.sender) {
        MIND_TOKEN = IERC20(_mindTokenAddress);
        queryOracleAddress = _initialOracleAddress;
        nextQueryId = 1;
        nextModuleId = 1;
        nextPoolId = 1;
        nextProposalId = 1;

        // Initialize default core parameters (values scaled for 18 decimals where applicable)
        coreParameters[PARAM_QUERY_FEE] = 100 * (10 ** 18); // 100 MIND
        coreParameters[PARAM_MIN_STAKE_PROPOSAL] = 1000 * (10 ** 18); // 1000 MIND
        coreParameters[PARAM_GOVERNANCE_VOTING_PERIOD_BLOCKS] = 7 * 24 * 60 * 60 / 12; // 7 days in blocks (approx. 12s/block)
        coreParameters[PARAM_GOVERNANCE_QUORUM_PERCENT] = 1000; // 10% (1000 / 10000)
        coreParameters[PARAM_GOVERNANCE_APPROVAL_PERCENT] = 5100; // 51% (5100 / 10000)
        coreParameters[PARAM_MIND_REWARD_RATE_PER_STAKE_BLOCK] = 10 ** 15; // 0.001 MIND per block per staked MIND (1e18 / 1000)
        coreParameters[PARAM_REPUTATION_WEIGHT_FOR_VOTING] = 10 ** 18; // 1 Reputation Point = 1 MIND voting power

        // Initialize reputation badge scores
        reputationBadgeScores[BADGE_ACCURATE_ORACLE] = 100; // 100 score points for accurate oracle
        reputationBadgeScores[BADGE_VALUABLE_QUERY] = 50;   // 50 score points for valuable query contribution
        reputationBadgeScores[BADGE_GOVERNANCE_VOTER] = 10;  // 10 score points for voting in governance
    }

    // --- I. Core System & Access Control ---

    /**
     * @dev Pauses core functionalities in emergencies.
     * @notice Only callable by the contract owner.
     */
    function pauseContract() public onlyOwner whenNotPaused {
        _pause();
    }

    /**
     * @dev Unpauses the contract.
     * @notice Only callable by the contract owner.
     */
    function unpauseContract() public onlyOwner whenPaused {
        _unpause();
    }

    /**
     * @dev Sets the trusted oracle address for query responses.
     * @param _newOracle The address of the new oracle.
     * @notice Only callable by the contract owner. This could be changed via governance.
     */
    function setQueryOracleAddress(address _newOracle) public onlyOwner {
        address oldOracle = queryOracleAddress;
        queryOracleAddress = _newOracle;
        // HACK: Emitting address as uint256, assuming it's non-zero. Better to log address directly if possible.
        // For actual address change, a dedicated event `OracleAddressUpdated(address old, address new)` would be better.
        emit CoreParameterUpdated(keccak256("QUERY_ORACLE_ADDRESS"), uint256(uint160(oldOracle)), uint256(uint160(_newOracle)));
    }

    /**
     * @dev General function to update various system parameters.
     * @param _paramName The keccak256 hash of the parameter name (e.g., keccak256("QUERY_FEE")).
     * @param _newValue The new value for the parameter.
     * @notice This function should ideally be called by a successful governance proposal.
     *         For this example, it's `onlyOwner` accessible, but conceptually for governance execution.
     */
    function updateCoreParameter(bytes32 _paramName, uint256 _newValue) public onlyOwner {
        uint256 oldValue = coreParameters[_paramName];
        coreParameters[_paramName] = _newValue;
        emit CoreParameterUpdated(_paramName, oldValue, _newValue);
    }

    // --- II. MIND Token & Staking ---

    /**
     * @dev Allows privileged roles (owner/governance) to establish new knowledge domains for staking.
     * @param _domainName The name of the new knowledge domain.
     * @param _initialWeight An initial weighting or priority for this pool (can be used for reward distribution logic).
     */
    function createKnowledgePool(string memory _domainName, uint256 _initialWeight) public onlyOwner { // Should eventually be governance controlled
        uint256 poolId = nextPoolId;
        nextPoolId++;
        // Check if pool ID somehow exists already, though sequential IDs prevent this generally.
        // Or if (_initialWeight == 0) revert InvalidAmount(); - based on desired logic.

        knowledgePools[poolId] = KnowledgePool({
            id: poolId,
            domainName: _domainName,
            totalStakedMIND: 0,
            stakedMIND: new mapping(address => uint256)(), // Initialize inner map
            lastStakeUpdateBlock: new mapping(address => uint256)() // Initialize inner map
        });

        emit KnowledgePoolCreated(poolId, _domainName);
    }

    /**
     * @dev Stakes MIND tokens into a specific knowledge pool.
     * @param _poolId The ID of the knowledge pool.
     * @param _amount The amount of MIND tokens to stake.
     */
    function joinKnowledgePool(uint256 _poolId, uint256 _amount) public whenNotPaused {
        if (_amount == 0) revert InvalidAmount();
        if (knowledgePools[_poolId].id == 0) revert PoolDoesNotExist();

        _updatePendingRewards(msg.sender, _poolId); // Account for pending rewards before state change

        MIND_TOKEN.transferFrom(msg.sender, address(this), _amount);
        knowledgePools[_poolId].stakedMIND[msg.sender] += _amount;
        knowledgePools[_poolId].totalStakedMIND += _amount;
        knowledgePools[_poolId].lastStakeUpdateBlock[msg.sender] = block.number;

        emit MINDStaked(_poolId, msg.sender, _amount);
    }

    /**
     * @dev Unstakes MIND tokens from a knowledge pool.
     * @param _poolId The ID of the knowledge pool.
     * @param _amount The amount of MIND tokens to unstake.
     */
    function exitKnowledgePool(uint256 _poolId, uint256 _amount) public whenNotPaused {
        if (_amount == 0) revert InvalidAmount();
        if (knowledgePools[_poolId].id == 0) revert PoolDoesNotExist();
        if (knowledgePools[_poolId].stakedMIND[msg.sender] < _amount) revert InsufficientMINDStake();

        _updatePendingRewards(msg.sender, _poolId); // Account for pending rewards before state change

        knowledgePools[_poolId].stakedMIND[msg.sender] -= _amount;
        knowledgePools[_poolId].totalStakedMIND -= _amount;
        knowledgePools[_poolId].lastStakeUpdateBlock[msg.sender] = block.number;

        MIND_TOKEN.transfer(msg.sender, _amount);
        emit MINDUnstaked(_poolId, msg.sender, _amount);
    }

    /**
     * @dev Claims accrued MIND rewards from a knowledge pool.
     * @param _poolId The ID of the knowledge pool.
     */
    function claimStakingRewards(uint256 _poolId) public whenNotPaused {
        if (knowledgePools[_poolId].id == 0) revert PoolDoesNotExist();

        uint256 rewards = getPendingRewards(msg.sender, _poolId);
        if (rewards == 0) {
            // No rewards to claim or already claimed by _updatePendingRewards.
            // If `_updatePendingRewards` explicitly transfers, this function might be redundant or just a direct claim.
            return;
        }

        knowledgePools[_poolId].lastStakeUpdateBlock[msg.sender] = block.number; // Reset calculation basis
        MIND_TOKEN.transfer(msg.sender, rewards);
        emit RewardsClaimed(_poolId, msg.sender, rewards);
    }

    /**
     * @dev Admin/governance function to signal distribution of rewards to a specific pool.
     *      This doesn't directly transfer tokens to users; it indicates funds are available for claiming.
     *      The actual reward calculation happens in `getPendingRewards` based on `PARAM_MIND_REWARD_RATE_PER_STAKE_BLOCK`.
     * @param _poolId The ID of the knowledge pool to distribute rewards to.
     * @param _amount The amount of MIND tokens considered for distribution (must be in contract balance).
     * @notice This function could trigger a more complex reward accrual logic or simply signal external injection.
     *         For simplicity, it mainly serves as an event trigger for external systems monitoring reward flows.
     */
    function distributePoolRewards(uint256 _poolId, uint256 _amount) public onlyOwner { // Should be governance controlled
        if (knowledgePools[_poolId].id == 0) revert PoolDoesNotExist();
        if (_amount == 0) revert InvalidAmount();
        // Funds should be pre-approved or sent to the contract, e.g., MIND_TOKEN.transferFrom(msg.sender, address(this), _amount);
        // This function primarily signals that a reward budget has been allocated/moved.
        emit PoolRewardsDistributed(_poolId, _amount);
    }

    // --- III. Aethermind Query & Response ---

    /**
     * @dev Submits a query to the Aethermind, paying a fee, and generating a unique query ID.
     * @param _queryHash A hash representing the actual query data (e.g., IPFS CID of the query).
     * @param _timeoutTimestamp The timestamp by which the oracle should respond.
     * @return The unique ID of the submitted query.
     */
    function queryAethermind(string memory _queryHash, uint256 _timeoutTimestamp) public whenNotPaused returns (uint256) {
        uint256 queryFee = coreParameters[PARAM_QUERY_FEE];
        if (queryFee > 0) {
            MIND_TOKEN.transferFrom(msg.sender, address(this), queryFee);
        }

        uint256 queryId = nextQueryId;
        nextQueryId++;
        queries[queryId] = Query({
            user: msg.sender,
            queryHash: _queryHash,
            timeoutTimestamp: _timeoutTimestamp,
            responseDataHash: "",
            processed: false,
            isAccurate: false,
            retrieved: false
        });

        emit QuerySubmitted(queryId, msg.sender, _queryHash, _timeoutTimestamp);
        return queryId;
    }

    /**
     * @dev Callable only by the registered oracle, provides the response to a query and marks its accuracy.
     * @param _queryId The ID of the query to respond to.
     * @param _responseDataHash A hash of the actual response data.
     * @param _isAccurate A boolean indicating if the oracle deems its own response/the underlying data accurate.
     * @notice This `_isAccurate` flag could be a self-assessment by the oracle or a simple placeholder.
     *         In a more advanced system, a "validation" or "dispute" mechanism would verify accuracy.
     */
    function submitOracleResponse(uint256 _queryId, string memory _responseDataHash, bool _isAccurate) public whenNotPaused {
        if (msg.sender != queryOracleAddress) revert UnauthorizedCaller();
        if (queries[_queryId].user == address(0)) revert InvalidQueryId();
        if (queries[_queryId].processed) revert QueryAlreadyProcessed();
        if (block.timestamp > queries[_queryId].timeoutTimestamp) {
            // Potentially refund query fee or penalize oracle if timed out and not responded.
        }

        queries[_queryId].responseDataHash = _responseDataHash;
        queries[_queryId].isAccurate = _isAccurate;
        queries[_queryId].processed = true;

        if (_isAccurate) {
            _mintReputationBadge(queryOracleAddress, BADGE_ACCURATE_ORACLE);
            _mintReputationBadge(queries[_queryId].user, BADGE_VALUABLE_QUERY); // User who submitted a validated query
        }

        emit OracleResponseSubmitted(_queryId, _responseDataHash, _isAccurate);
    }

    /**
     * @dev Allows the user who submitted the query to retrieve their processed response details.
     * @param _queryId The ID of the query to retrieve.
     * @return The response data hash, and a boolean indicating if the oracle marked it as accurate.
     */
    function retrieveQueryResponse(uint256 _queryId) public returns (string memory, bool) {
        Query storage query = queries[_queryId];
        if (query.user == address(0)) revert InvalidQueryId();
        if (msg.sender != query.user) revert UnauthorizedCaller();
        if (!query.processed) revert QueryNotProcessed();
        if (query.retrieved) {
            // Already retrieved, could add specific error or just return
        }

        query.retrieved = true; // Mark as retrieved

        emit QueryRetrieved(_queryId, msg.sender);
        return (query.responseDataHash, query.isAccurate);
    }

    // --- IV. Dynamic Knowledge Modules (NFT-like) ---

    /**
     * @dev Creates a new unique knowledge module.
     * @param _moduleId The unique ID for the new module.
     * @param _moduleName The name of the module.
     * @param _initialIntelligence The initial intelligence level of the module.
     * @param _recipient The address that will own this new module.
     * @notice Callable by governance/owner.
     */
    function mintKnowledgeModule(uint256 _moduleId, string memory _moduleName, uint256 _initialIntelligence, address _recipient) public onlyOwner { // Should eventually be governance controlled
        if (knowledgeModules[_moduleId].id != 0) revert InvalidModuleId(); // Module ID already exists

        knowledgeModules[_moduleId] = KnowledgeModule({
            id: _moduleId,
            name: _moduleName,
            owner: _recipient,
            intelligenceLevel: _initialIntelligence,
            isActive: false
        });
        
        if (_moduleId >= nextModuleId) { // Ensure nextModuleId is always greater than highest used ID
            nextModuleId = _moduleId + 1;
        }

        emit KnowledgeModuleMinted(_moduleId, _recipient, _moduleName, _initialIntelligence);
    }

    /**
     * @dev Improves a module's intelligence by burning MIND tokens and requiring a minimum reputation score from the owner.
     * @param _moduleId The ID of the module to upgrade.
     * @param _amountMIND The amount of MIND tokens to burn for the upgrade.
     * @param _minReputationNeeded The minimum reputation score required by the module owner.
     * @notice The intelligence increase could be proportional to _amountMIND or a fixed step.
     */
    function upgradeModuleIntelligence(uint256 _moduleId, uint256 _amountMIND, uint256 _minReputationNeeded) public whenNotPaused {
        KnowledgeModule storage module = knowledgeModules[_moduleId];
        if (module.id == 0) revert ModuleDoesNotExist();
        if (module.owner != msg.sender) revert NotModuleOwner();
        if (getUserReputationScore(msg.sender) < _minReputationNeeded) revert InsufficientReputation();
        if (_amountMIND == 0) revert InvalidAmount();

        MIND_TOKEN.transferFrom(msg.sender, address(this), _amountMIND); // Transfer to contract address (simulated burn/treasury)

        uint256 oldIntelligence = module.intelligenceLevel;
        module.intelligenceLevel += (_amountMIND / (10 ** 18)) * 100; // Example: 100 intelligence points per MIND token burned. Scale accordingly.

        if (module.isActive) {
            aethermindOverallIntelligence += (module.intelligenceLevel - oldIntelligence);
        }

        emit KnowledgeModuleUpgraded(_moduleId, module.intelligenceLevel, _amountMIND);
    }

    /**
     * @dev Transfers ownership of a module to another address.
     * @param _moduleId The ID of the module to transfer.
     * @param _to The recipient address.
     */
    function transferKnowledgeModule(uint256 _moduleId, address _to) public whenNotPaused {
        KnowledgeModule storage module = knowledgeModules[_moduleId];
        if (module.id == 0) revert ModuleDoesNotExist();
        if (module.owner != msg.sender) revert NotModuleOwner();
        if (_to == address(0)) revert InvalidAmount(); // Use InvalidAmount for address(0)

        address oldOwner = module.owner;
        module.owner = _to;

        emit KnowledgeModuleTransferred(_moduleId, oldOwner, _to);
    }

    /**
     * @dev Integrates a module's capabilities into the active Aethermind logic, increasing its overall "knowledge score".
     * @param _moduleId The ID of the module to activate.
     */
    function activateModuleInAethermind(uint256 _moduleId) public whenNotPaused {
        KnowledgeModule storage module = knowledgeModules[_moduleId];
        if (module.id == 0) revert ModuleDoesNotExist();
        if (module.owner != msg.sender) revert NotModuleOwner();
        if (module.isActive) revert ModuleAlreadyActive();

        module.isActive = true;
        aethermindOverallIntelligence += module.intelligenceLevel;

        emit KnowledgeModuleActivated(_moduleId, aethermindOverallIntelligence);
    }

    /**
     * @dev Removes a module from active integration, decreasing the Aethermind's overall "knowledge score".
     * @param _moduleId The ID of the module to deactivate.
     */
    function deactivateModuleFromAethermind(uint256 _moduleId) public whenNotPaused {
        KnowledgeModule storage module = knowledgeModules[_moduleId];
        if (module.id == 0) revert ModuleDoesNotExist();
        if (module.owner != msg.sender) revert NotModuleOwner();
        if (!module.isActive) revert ModuleNotActive();

        module.isActive = false;
        aethermindOverallIntelligence -= module.intelligenceLevel;

        emit KnowledgeModuleDeactivated(_moduleId, aethermindOverallIntelligence);
    }

    // --- V. Reputation Badges (Soulbound Tokens - SBTs) ---

    /**
     * @dev Mints a non-transferable reputation badge for a user based on criteria.
     * @param _recipient The address to receive the badge.
     * @param _badgeType The type of badge to mint (e.g., BADGE_ACCURATE_ORACLE).
     * @notice Callable by governance, or specific internal logic like `submitOracleResponse` for `_isAccurate`.
     */
    function mintReputationBadge(address _recipient, uint256 _badgeType) public {
        // Internal helper, or can be `onlyOwner` / `onlyGovernance`
        if (userReputationBadges[_recipient][_badgeType]) revert BadgeAlreadyMinted();
        userReputationBadges[_recipient][_badgeType] = true;
        emit ReputationBadgeMinted(_recipient, _badgeType);
    }

    /**
     * @dev Revokes a reputation badge (e.g., for malicious activity).
     * @param _holder The address whose badge is to be revoked.
     * @param _badgeType The type of badge to revoke.
     * @notice Callable by governance.
     */
    function revokeReputationBadge(address _holder, uint256 _badgeType) public onlyOwner { // Should be governance controlled
        if (!userReputationBadges[_holder][_badgeType]) revert BadgeNotFound();
        userReputationBadges[_holder][_badgeType] = false;
        emit ReputationBadgeRevoked(_holder, _badgeType);
    }

    /**
     * @dev Returns a user's cumulative reputation score.
     * @param _user The address of the user.
     * @return The calculated reputation score.
     */
    function getUserReputationScore(address _user) public view returns (uint256) {
        uint256 score = 0;
        // This is a simple sum. In a real system, different badges might have decay or multiplier.
        if (userReputationBadges[_user][BADGE_ACCURATE_ORACLE]) score += reputationBadgeScores[BADGE_ACCURATE_ORACLE];
        if (userReputationBadges[_user][BADGE_VALUABLE_QUERY]) score += reputationBadgeScores[BADGE_VALUABLE_QUERY];
        if (userReputationBadges[_user][BADGE_GOVERNANCE_VOTER]) score += reputationBadgeScores[BADGE_GOVERNANCE_VOTER];
        // Add more badge types here
        return score;
    }

    /**
     * @dev Checks if a user holds a specific badge.
     * @param _user The address of the user.
     * @param _badgeType The type of badge to check.
     * @return True if the user holds the badge, false otherwise.
     */
    function hasReputationBadge(address _user, uint256 _badgeType) public view returns (bool) {
        return userReputationBadges[_user][_badgeType];
    }

    // --- VI. Governance & Community ---

    /**
     * @dev Allows users with sufficient MIND stake or reputation to propose system changes.
     * @param _proposalHash A hash of the proposed action/parameters (e.g., hash of a Solidity function call payload).
     * @param _durationBlocks The duration in blocks for which the proposal will be open for voting.
     * @return The unique ID of the created proposal.
     */
    function proposeVote(bytes32 _proposalHash, uint256 _durationBlocks) public whenNotPaused returns (uint256) {
        uint256 proposerVotingPower = getUserVotingPower(msg.sender);
        if (proposerVotingPower < coreParameters[PARAM_MIN_STAKE_PROPOSAL]) {
            revert InsufficientMINDStake(); // Reusing error for simplicity, could be InsufficientPrivilege()
        }

        uint256 proposalId = nextProposalId;
        nextProposalId++;
        proposals[proposalId] = Proposal({
            id: proposalId,
            proposalHash: _proposalHash,
            startBlock: block.number,
            endBlock: block.number + _durationBlocks,
            totalVotesFor: 0,
            totalVotesAgainst: 0,
            executed: false
        });

        emit ProposalCreated(proposalId, _proposalHash, msg.sender);
        return proposalId;
    }

    /**
     * @dev Allows MIND stakers and reputation holders to vote on proposals.
     * @param _proposalId The ID of the proposal to vote on.
     * @param _support True for "for" vote, false for "against" vote.
     */
    function castVote(uint256 _proposalId, bool _support) public whenNotPaused {
        Proposal storage proposal = proposals[_proposalId];
        if (proposal.id == 0) revert ProposalDoesNotExist();
        if (block.number > proposal.endBlock) revert ProposalNotExecutable(); // Voting period ended
        if (proposal.hasVoted[msg.sender]) revert AlreadyVoted();

        uint256 voterPower = getUserVotingPower(msg.sender);
        if (voterPower == 0) revert InsufficientMINDStake(); // No voting power

        if (_support) {
            proposal.totalVotesFor += voterPower;
        } else {
            proposal.totalVotesAgainst += voterPower;
        }
        proposal.hasVoted[msg.sender] = true;
        _mintReputationBadge(msg.sender, BADGE_GOVERNANCE_VOTER); // Reward for participation

        emit VoteCast(_proposalId, msg.sender, _support);
    }

    /**
     * @dev Executes a passed proposal. Callable by anyone after the voting period ends and threshold met.
     * @param _proposalId The ID of the proposal to execute.
     * @notice The actual execution logic (e.g., calling `updateCoreParameter`) would happen here based on `proposalHash`.
     *         For this example, it's a placeholder.
     */
    function executeProposal(uint256 _proposalId) public whenNotPaused {
        Proposal storage proposal = proposals[_proposalId];
        if (proposal.id == 0) revert ProposalDoesNotExist();
        if (block.number <= proposal.endBlock) revert ProposalNotExecutable(); // Voting period not ended
        if (proposal.executed) revert ProposalAlreadyExecuted();

        uint256 totalVotes = proposal.totalVotesFor + proposal.totalVotesAgainst;
        uint256 totalPossibleVotingPower = getTotalStakedMIND(); // Simplified: assuming total staked MIND is total voting supply
        
        // Add all reputation holders too in total possible voting power for a more accurate quorum.
        // For simplicity, totalPossibleVotingPower = getTotalStakedMIND(); and reputation is a multiplier.

        uint256 quorumThreshold = (totalPossibleVotingPower * coreParameters[PARAM_GOVERNANCE_QUORUM_PERCENT]) / 10000;
        uint256 approvalThreshold = (totalVotes * coreParameters[PARAM_GOVERNANCE_APPROVAL_PERCENT]) / 10000;

        if (totalVotes < quorumThreshold) revert QuorumNotMet();
        if (proposal.totalVotesFor < approvalThreshold) revert ProposalNotApproved();

        proposal.executed = true;

        // --- Placeholder for actual execution logic ---
        // In a real DAO, the proposalHash would typically encode a function call payload
        // Example: (bool success, ) = address(this).call(abi.decode(proposal.proposalHash, (bytes)));
        // require(success, "Proposal execution failed");
        // Or for direct parameter update:
        // bytes32 paramName = abi.decode(proposal.proposalHash[0:32], (bytes32));
        // uint256 newValue = abi.decode(proposal.proposalHash[32:64], (uint256));
        // coreParameters[paramName] = newValue;

        emit ProposalExecuted(_proposalId, proposal.proposalHash);
    }

    // --- VII. View/Helper Functions ---

    /**
     * @dev Returns details of a specific knowledge module.
     * @param _moduleId The ID of the module.
     * @return Tuple containing module ID, name, owner, intelligence level, and active status.
     */
    function getModuleDetails(uint256 _moduleId) public view returns (uint256, string memory, address, uint256, bool) {
        KnowledgeModule storage module = knowledgeModules[_moduleId];
        if (module.id == 0) revert ModuleDoesNotExist();
        return (module.id, module.name, module.owner, module.intelligenceLevel, module.isActive);
    }

    /**
     * @dev Returns details of a specific knowledge pool.
     * @param _poolId The ID of the pool.
     * @return Tuple containing pool ID, domain name, total staked MIND.
     */
    function getPoolDetails(uint256 _poolId) public view returns (uint256, string memory, uint256) {
        KnowledgePool storage pool = knowledgePools[_poolId];
        if (pool.id == 0) revert PoolDoesNotExist();
        return (pool.id, pool.domainName, pool.totalStakedMIND);
    }

    /**
     * @dev Returns a user's staked amount in a specific pool.
     * @param _user The address of the user.
     * @param _poolId The ID of the pool.
     * @return The amount of MIND tokens staked by the user in that pool.
     */
    function getUserStake(address _user, uint256 _poolId) public view returns (uint256) {
        if (knowledgePools[_poolId].id == 0) return 0; // Return 0 if pool doesn't exist for a view, or revert PoolDoesNotExist();
        return knowledgePools[_poolId].stakedMIND[_user];
    }

    /**
     * @dev Calculates a user's pending rewards from a pool.
     * @param _user The address of the user.
     * @param _poolId The ID of the pool.
     * @return The amount of pending rewards.
     */
    function getPendingRewards(address _user, uint256 _poolId) public view returns (uint256) {
        KnowledgePool storage pool = knowledgePools[_poolId];
        if (pool.id == 0 || pool.stakedMIND[_user] == 0) return 0;

        uint256 blocksStaked = block.number - pool.lastStakeUpdateBlock[_user];
        // Rewards = staked_amount * blocks_staked * rate_per_block_per_token / 1e18 (to account for rate scaling)
        uint256 rewards = (pool.stakedMIND[_user] * blocksStaked * coreParameters[PARAM_MIND_REWARD_RATE_PER_STAKE_BLOCK]) / (10 ** 18);
        return rewards;
    }

    /**
     * @dev Internal helper to update pending rewards (effectively claim for the user before state change).
     * @param _user The user's address.
     * @param _poolId The ID of the pool.
     */
    function _updatePendingRewards(address _user, uint256 _poolId) internal {
        uint256 pending = getPendingRewards(_user, _poolId);
        if (pending > 0) {
            // Transfer actual rewards to the user here as a part of _update
            // This design implicitly claims rewards.
            MIND_TOKEN.transfer(_user, pending);
            emit RewardsClaimed(_poolId, _user, pending);
        }
        knowledgePools[_poolId].lastStakeUpdateBlock[_user] = block.number;
    }

    /**
     * @dev Returns the current status and data hash of a submitted query.
     * @param _queryId The ID of the query.
     * @return Tuple containing query hash, response hash, processed status, accuracy, timeout, and retrieval status.
     */
    function getQueryStatus(uint256 _queryId) public view returns (string memory, string memory, bool, bool, uint256, bool) {
        Query storage query = queries[_queryId];
        if (query.user == address(0)) revert InvalidQueryId(); // Check if query exists
        return (query.queryHash, query.responseDataHash, query.processed, query.isAccurate, query.timeoutTimestamp, query.retrieved);
    }

    /**
     * @dev Returns the current overall intelligence level of the Aethermind, derived from active modules.
     * @return The sum of intelligence levels of all active knowledge modules.
     */
    function getAethermindOverallIntelligence() public view returns (uint256) {
        return aethermindOverallIntelligence;
    }

    /**
     * @dev Returns the total amount of MIND tokens currently staked across all knowledge pools.
     * @return The total staked MIND.
     */
    function getTotalStakedMIND() public view returns (uint256) {
        uint256 total = 0;
        // Iterating through `nextPoolId` assumes pools are sequential from 1.
        // For sparse IDs, a different iterable structure would be needed.
        for (uint256 i = 1; i < nextPoolId; i++) {
            total += knowledgePools[i].totalStakedMIND;
        }
        return total;
    }

    /**
     * @dev Internal helper to get a user's total voting power.
     * @param _user The address of the user.
     * @return The combined voting power from staked MIND and reputation.
     */
    function getUserVotingPower(address _user) internal view returns (uint256) {
        uint256 totalUserStakedMIND = 0;
        for (uint256 i = 1; i < nextPoolId; i++) {
            totalUserStakedMIND += knowledgePools[i].stakedMIND[_user];
        }

        uint256 reputationScore = getUserReputationScore(_user);
        uint256 reputationVotingPower = (reputationScore * coreParameters[PARAM_REPUTATION_WEIGHT_FOR_VOTING]) / (10 ** 18); // Scale reputation to MIND equivalent

        return totalUserStakedMIND + reputationVotingPower;
    }

    /**
     * @dev Internal helper to mint a reputation badge.
     * @param _recipient The address to receive the badge.
     * @param _badgeType The type of badge to mint.
     * @notice This helper is used internally by functions like `submitOracleResponse` and `castVote`.
     *         It calls the public `mintReputationBadge` which includes the `BadgeAlreadyMinted` check.
     */
    function _mintReputationBadge(address _recipient, uint256 _badgeType) internal {
        if (!userReputationBadges[_recipient][_badgeType]) {
            userReputationBadges[_recipient][_badgeType] = true;
            emit ReputationBadgeMinted(_recipient, _badgeType);
        }
    }
}
```