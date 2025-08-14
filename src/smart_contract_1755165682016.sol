Okay, this is an exciting challenge! Creating a truly novel and advanced smart contract requires blending several cutting-edge concepts.

Let's imagine a contract that acts as a **"Parametric Impact & Adaptive Portfolio Nexus" (PIAPN)**.

**Core Idea:**
The contract manages decentralized, dynamically adjusting investment "Impact Pools" whose yield and risk parameters are determined by real-world, verifiable environmental or social impact data (via oracles). Users stake funds into these pools, and their "Eco-Reputation Score" (an on-chain, non-transferable score) is dynamically updated based on their contribution duration, the *actual measured impact* of the projects their funds supported, and the pool's performance. The contract itself has a built-in "Adaptive Logic Engine" (simulated via on-chain computations and oracle triggers) that rebalances pool parameters or even suggests new pool configurations based on the environmental data trends.

**Key Advanced Concepts:**

1.  **Parametric Yield Adjustment:** Pool yields are not fixed but fluctuate based on external, verifiable impact metrics (e.g., carbon credits generated, water quality improvements, social welfare indicators).
2.  **Dynamic Eco-Reputation:** A non-transferable score that evolves based on user engagement, impact contribution, and pool performance, acting as a form of "Soulbound Token" without being an explicit ERC-721. This score could unlock higher yields or governance power.
3.  **On-Chain Adaptive Logic (Simulated AI/ML):** The contract contains internal logic that, triggered by oracle updates, can "suggest" or automatically initiate adjustments to pool parameters (e.g., re-allocating funds, changing base APRs, or triggering a governance vote for significant shifts) based on predefined algorithms reacting to environmental data trends. This mimics an on-chain "AI agent."
4.  **Intent-Based Staking:** Users declare a high-level "impact intent" (e.g., "maximize carbon capture," "support biodiversity") rather than just a specific pool, and the contract, leveraging its adaptive logic, attempts to route their funds to optimal pools or even propose new ones. (Simplified for a single contract, but the concept is there).
5.  **Multi-Asset Liquidity Provisioning & Bridging:** While a full cross-chain bridge isn't in one contract, the contract can manage staking of multiple token types, conceptually enabling more diverse impact investments.
6.  **Oracle-Driven Multi-Tiered Governance:** Decisions (especially major pool reconfigurations) are driven by a combination of reputation-weighted voting and real-world data feeds.
7.  **Flash Rebalancing/Liquidation (Conceptual):** Mechanisms for rapid pool rebalancing or even liquidation of underperforming impact assets, potentially using flash loans for capital efficiency (though highly complex and usually off-chain).
8.  **Time-Series Data Aggregation (Simulated):** The contract stores historical oracle data to inform its adaptive logic, simulating a lightweight on-chain data warehouse.

---

## Contract Outline & Function Summary: `EcoSenseNexus`

**Contract Name:** `EcoSenseNexus`
**Version:** 1.0.0
**Purpose:** A decentralized platform for parametric impact investing, leveraging real-world environmental data and dynamic user reputation.

---

**I. Core Structures & State Variables**

*   **`Pool` Struct:** Defines properties of an impact investment pool (ID, name, target impact metric, current impact value, base APR, parametric yield factor, max capacity, staked amount, status, reward token, accepted stake token, associated oracle IDs).
*   **`OracleFeed` Struct:** Defines registered oracle data feeds (ID, source, last updated value, update frequency).
*   **`Proposal` Struct:** For on-chain governance (ID, target pool, parameter, new value, votes for/against, state, execution timestamp).
*   **Mappings:**
    *   `pools`: `poolId -> Pool`
    *   `ecoReputationScores`: `userAddress -> score`
    *   `oracleDataFeeds`: `oracleId -> OracleFeed`
    *   `userStakes`: `poolId -> userAddress -> amount`
    *   `pendingRewards`: `poolId -> userAddress -> amount`
    *   `activeProposals`: `proposalId -> Proposal`
    *   `votedOnProposal`: `proposalId -> userAddress -> bool`
*   **Counters:** `nextPoolId`, `nextOracleId`, `nextProposalId`.
*   **Roles:** `_adminRole`, `_oracleUpdaterRole`, `_governorRole`.

**II. Core Pool Management (Admin/Governor Controlled)**

1.  **`createEcoImpactPool(string _name, bytes32 _targetImpactMetric, uint256 _baseAPR, uint256 _maxCapacity, address _rewardToken, address _acceptedStakeToken, bytes32[] _associatedOracleIds)`**
    *   **Summary:** Creates a new impact investment pool with defined parameters and links it to specific oracle data feeds.
    *   **Advanced:** `_targetImpactMetric` and `_associatedOracleIds` are crucial for the parametric nature.
2.  **`updatePoolParameters(uint256 _poolId, uint256 _newBaseAPR, uint256 _newMaxCapacity)`**
    *   **Summary:** Allows admins/governors to adjust a pool's base APR and capacity.
    *   **Advanced:** Can be triggered by `triggerAdaptiveParamAdjustment` or governance proposal.
3.  **`pauseEcoImpactPool(uint256 _poolId)`**
    *   **Summary:** Pauses a specific pool, preventing new deposits/withdrawals.
    *   **Standard:** Essential for emergencies.
4.  **`unpauseEcoImpactPool(uint256 _poolId)`**
    *   **Summary:** Unpauses a previously paused pool.
    *   **Standard:** Resume operations.
5.  **`deprecateEcoImpactPool(uint256 _poolId)`**
    *   **Summary:** Marks a pool as deprecated, allowing only withdrawals, no new deposits. Funds can be gradually migrated.
    *   **Advanced:** For graceful sunsetting of less impactful or underperforming pools.

**III. Oracle & Adaptive Logic Integration (Admin/Oracle Controlled)**

6.  **`registerOracleFeed(string _source, uint256 _initialValue, uint256 _updateFrequency)`**
    *   **Summary:** Registers a new oracle data feed that the contract can consume.
    *   **Advanced:** Foundation for parametric adjustments.
7.  **`updateEnvironmentalOracleData(bytes32 _oracleId, uint256 _newValue, uint256 _impactWeight)`**
    *   **Summary:** Authorized oracles push new environmental/impact data. This triggers internal calculations.
    *   **Advanced:** `_impactWeight` allows different oracle feeds to have varying influence on overall impact score.
8.  **`triggerAdaptiveParamAdjustment(uint256 _poolId)`**
    *   **Summary:** Internal or external call (e.g., scheduled keeper) to activate the "Adaptive Logic Engine" for a specific pool, adjusting its `parametricFactor` based on recent oracle data trends and `_impactWeight`.
    *   **Advanced:** Simulates the "AI agent" logic, dynamically altering yield based on *measured impact trend*. This is where the core innovative algorithm would reside.
9.  **`getHistoricalOracleData(bytes32 _oracleId, uint256 _timestamp)`**
    *   **Summary:** A view function to retrieve historical oracle data points stored on-chain (simplified for brevity).
    *   **Advanced:** Essential for the adaptive logic to identify trends.

**IV. User Interaction & Staking**

10. **`depositIntoPool(uint256 _poolId, uint256 _amount)`**
    *   **Summary:** Users stake accepted tokens into a specified impact pool.
    *   **Advanced:** Internally updates user's `ecoReputationScores` based on potential initial impact commitment.
11. **`withdrawFromPool(uint256 _poolId, uint256 _amount)`**
    *   **Summary:** Users withdraw their staked tokens.
    *   **Advanced:** Triggers a recalculation and update of the user's `ecoReputationScores` based on staking duration and the *pool's performance against its impact metric* during their stake period.
12. **`claimRewards(uint256 _poolId)`**
    *   **Summary:** Users claim accumulated rewards from a pool.
    *   **Advanced:** Rewards are calculated using `_baseAPR` *and* the `parametricFactor` dynamically adjusted by oracle data.
13. **`getEstimatedRewards(uint256 _poolId, address _user)`**
    *   **Summary:** View function to estimate pending rewards for a user.
    *   **Standard:** UX helper.
14. **`getUserStakedAmount(uint256 _poolId, address _user)`**
    *   **Summary:** View function to get a user's staked amount in a specific pool.
    *   **Standard:** UX helper.

**V. Eco-Reputation System**

15. **`getEcoReputationScore(address _user)`**
    *   **Summary:** Retrieves a user's current non-transferable Eco-Reputation Score.
    *   **Advanced:** The core "Soulbound" aspect (though it's a score, not an NFT).
16. **`_updateEcoReputation(address _user, uint256 _poolId, uint256 _impactDelta, uint256 _duration)` (Internal/Private)**
    *   **Summary:** Internal function called after deposits/withdrawals/claims to update a user's reputation based on their contribution duration, the *change in the pool's measured impact score*, and any additional positive/negative events.
    *   **Advanced:** This is the heart of the dynamic reputation. `_impactDelta` is crucial for linking reputation to real-world outcomes.
17. **`slashEcoReputation(address _user, uint256 _amount)`**
    *   **Summary:** Admin function to reduce a user's reputation score for malicious behavior or non-compliance.
    *   **Advanced:** A necessary counter-measure for a reputation system.

**VI. Decentralized Governance (Reputation-Weighted)**

18. **`proposePoolParameterChange(uint256 _poolId, bytes32 _paramKey, uint256 _newValue)`**
    *   **Summary:** Users with a minimum `ecoReputationScore` can propose changes to pool parameters.
    *   **Advanced:** Reputation-weighted proposals.
19. **`voteOnProposal(uint256 _proposalId, bool _voteFor)`**
    *   **Summary:** Users (potentially reputation-weighted voting) vote on active proposals.
    *   **Advanced:** Voting power could be proportional to `ecoReputationScore`.
20. **`executeProposal(uint256 _proposalId)`**
    *   **Summary:** Executes a successful proposal (if quorum and majority are met).
    *   **Advanced:** Fully on-chain governance.

**VII. Emergency & Maintenance**

21. **`emergencyWithdrawAdmin(address _tokenAddress, uint256 _amount)`**
    *   **Summary:** Allows the admin to withdraw funds in extreme emergencies (e.g., critical bug, exploit).
    *   **Standard:** Safety feature.
22. **`upgradeToNewContract(address _newImplementation)`**
    *   **Summary:** Placeholder for upgradability via proxy patterns (e.g., UUPS, Transparent Proxies). The actual proxy logic lives outside this contract.
    *   **Advanced:** Crucial for long-term project viability.
23. **`setRolePermissions(bytes32 _role, address _account)`**
    *   **Summary:** Admin function to grant or revoke specific roles (e.g., `_oracleUpdaterRole`, `_governorRole`).
    *   **Advanced:** Robust access control.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
// For a real implementation, AccessControl.sol would be used for roles,
// but for brevity and focusing on core logic, we'll use onlyOwner for admin.
// import "@openzeppelin/contracts/access/AccessControl.sol";


/**
 * @title EcoSenseNexus
 * @dev A decentralized platform for parametric impact investing, leveraging
 *      real-world environmental data and dynamic user reputation.
 *      This contract implements an "Adaptive Logic Engine" (simulated via
 *      on-chain computations) that adjusts pool parameters based on oracle data,
 *      and a dynamic "Eco-Reputation Score" system.
 *
 * Outline & Function Summary:
 *
 * I. Core Structures & State Variables:
 *    - Pool Struct: Defines properties of an impact investment pool.
 *    - OracleFeed Struct: Defines registered oracle data feeds.
 *    - Proposal Struct: For on-chain governance.
 *    - Mappings for pools, reputation, oracles, stakes, rewards, proposals.
 *    - Counters for IDs.
 *    - Roles (Admin, Oracle Updater, Governor).
 *
 * II. Core Pool Management (Admin/Governor Controlled):
 *    1. createEcoImpactPool: Creates a new impact investment pool.
 *    2. updatePoolParameters: Adjusts a pool's base APR and capacity.
 *    3. pauseEcoImpactPool: Pauses a specific pool.
 *    4. unpauseEcoImpactPool: Unpauses a previously paused pool.
 *    5. deprecateEcoImpactPool: Marks a pool as deprecated.
 *
 * III. Oracle & Adaptive Logic Integration (Admin/Oracle Controlled):
 *    6. registerOracleFeed: Registers a new oracle data feed.
 *    7. updateEnvironmentalOracleData: Authorized oracles push new data, triggers internal calculations.
 *    8. triggerAdaptiveParamAdjustment: Activates the "Adaptive Logic Engine" to adjust parametric factor.
 *    9. getHistoricalOracleData: View function for historical oracle data.
 *
 * IV. User Interaction & Staking:
 *    10. depositIntoPool: Users stake tokens into a pool.
 *    11. withdrawFromPool: Users withdraw their staked tokens.
 *    12. claimRewards: Users claim accumulated rewards.
 *    13. getEstimatedRewards: View function to estimate pending rewards.
 *    14. getUserStakedAmount: View function to get a user's staked amount.
 *
 * V. Eco-Reputation System:
 *    15. getEcoReputationScore: Retrieves a user's current Eco-Reputation Score.
 *    16. _updateEcoReputation (Internal): Updates a user's reputation based on contribution and impact.
 *    17. slashEcoReputation: Admin function to reduce reputation score.
 *
 * VI. Decentralized Governance (Reputation-Weighted):
 *    18. proposePoolParameterChange: Users (with sufficient reputation) propose changes.
 *    19. voteOnProposal: Users vote on active proposals.
 *    20. executeProposal: Executes a successful proposal.
 *
 * VII. Emergency & Maintenance:
 *    21. emergencyWithdrawAdmin: Allows admin to withdraw funds in emergencies.
 *    22. upgradeToNewContract: Placeholder for upgradability (requires proxy).
 *    23. setRolePermissions: Admin function to grant or revoke roles.
 */
contract EcoSenseNexus is Ownable, ReentrancyGuard, Pausable {
    using SafeMath for uint256;

    // --- I. Core Structures & State Variables ---

    // Struct for an Impact Investment Pool
    struct Pool {
        uint256 id;
        string name;
        bytes32 targetImpactMetric; // Identifier for the type of impact (e.g., keccak256("carbon_capture"))
        uint256 currentImpactScore; // Aggregate score based on associated oracle feeds
        uint256 baseAPR;            // Base Annual Percentage Rate (e.g., 500 for 5%)
        uint256 parametricFactor;   // Multiplier based on real-world impact data (e.g., 1000 for 1x)
        uint256 maxCapacity;        // Max tokens that can be staked in this pool
        uint256 currentStaked;      // Current total staked tokens in the pool
        uint256 lastRewardCalcTime; // Last time rewards were calculated/updated for the pool
        bool isActive;              // True if the pool is active and accepting deposits
        bool isDeprecated;          // True if the pool is being phased out (only withdrawals allowed)
        address rewardToken;        // The token distributed as rewards
        address acceptedStakeToken; // The token accepted for staking in this pool
        bytes32[] associatedOracleIds; // IDs of oracle feeds relevant to this pool's impact
    }

    // Struct for an Oracle Data Feed
    struct OracleFeed {
        bytes32 id;                // Unique identifier for the oracle feed
        string source;             // Human-readable source description (e.g., "Chainlink Carbon Data")
        uint256 lastReportedValue; // Last value reported by the oracle
        uint256 lastUpdatedTimestamp; // Timestamp of the last update
        uint256 updateFrequency;   // Expected update frequency in seconds (for data freshness checks)
        uint256 impactWeight;      // How much this oracle's data influences overall pool impact score (e.g., 1-100)
    }

    // Struct for a Governance Proposal
    struct Proposal {
        uint256 id;
        uint256 poolId;            // The pool targeted by this proposal (0 for general proposals)
        bytes32 paramKey;          // Identifier for the parameter to change (e.g., keccak256("baseAPR"))
        uint256 newValue;          // The proposed new value
        uint256 proposerScore;     // Eco-Reputation score of the proposer at the time of proposal
        uint256 votesFor;
        uint256 votesAgainst;
        uint256 totalVoters;       // Total unique reputable voters
        uint256 minReputationToVote; // Minimum reputation score required to vote on this proposal
        uint256 votingDeadline;    // Timestamp when voting ends
        bool executed;
        bool cancelled;
        enum State { Pending, Active, Succeeded, Failed, Expired } currentState;
    }

    // Mappings for core data
    mapping(uint256 => Pool) public pools;
    mapping(address => uint256) public ecoReputationScores; // User's non-transferable reputation score
    mapping(bytes32 => OracleFeed) public oracleDataFeeds;
    mapping(uint256 => mapping(address => uint256)) public userStakes; // poolId => userAddress => stakedAmount
    mapping(uint256 => mapping(address => uint256)) public pendingRewards; // poolId => userAddress => pendingReward
    mapping(uint256 => mapping(address => uint256)) public userLastDepositTime; // poolId => userAddress => lastDepositTimestamp (for reputation)
    mapping(uint256 => Proposal) public activeProposals;
    mapping(uint256 => mapping(address => bool)) public votedOnProposal; // proposalId => userAddress => hasVoted

    // Counters for unique IDs
    uint256 public nextPoolId = 1;
    bytes32 public nextOracleId = keccak256(abi.encodePacked("ORACLE_0")); // Start with a hash
    uint256 public nextProposalId = 1;

    // Minimum reputation to propose or vote
    uint256 public minReputationToPropose = 100;
    uint256 public minReputationToVote = 10;
    uint256 public constant VOTING_PERIOD = 3 days; // Default voting period

    // --- Roles (Using Ownable as simplified AccessControl) ---
    // In a real system, AccessControl.sol would be used for distinct roles like:
    // bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    // bytes32 public constant ORACLE_UPDATER_ROLE = keccak256("ORACLE_UPDATER_ROLE");
    // bytes32 public constant GOVERNOR_ROLE = keccak256("GOVERNOR_ROLE");

    // Events
    event PoolCreated(uint256 indexed poolId, string name, address acceptedStakeToken, address rewardToken);
    event PoolParametersUpdated(uint256 indexed poolId, uint256 newBaseAPR, uint256 newMaxCapacity);
    event PoolPaused(uint256 indexed poolId);
    event PoolUnpaused(uint256 indexed poolId);
    event PoolDeprecated(uint256 indexed poolId);
    event Deposited(uint256 indexed poolId, address indexed user, uint256 amount);
    event Withdrew(uint256 indexed poolId, address indexed user, uint256 amount);
    event RewardsClaimed(uint256 indexed poolId, address indexed user, uint256 amount);
    event OracleFeedRegistered(bytes32 indexed oracleId, string source);
    event OracleDataUpdated(bytes32 indexed oracleId, uint256 newValue, uint256 timestamp);
    event ParametricAdjustmentTriggered(uint256 indexed poolId, uint256 newParametricFactor, uint256 newImpactScore);
    event EcoReputationUpdated(address indexed user, uint256 newScore, string reason);
    event ProposalCreated(uint256 indexed proposalId, uint256 indexed poolId, bytes32 paramKey, uint256 newValue, address proposer);
    event Voted(uint256 indexed proposalId, address indexed voter, bool voteFor);
    event ProposalExecuted(uint256 indexed proposalId, uint256 poolId);
    event EmergencyFundsWithdrawn(address indexed token, uint256 amount);

    constructor() Ownable(msg.sender) Pausable() {
        // Initial setup can include registering initial admin/governor roles if AccessControl is used.
    }

    // --- Modifiers ---
    modifier onlyOracleUpdater() {
        // In a real scenario, this would check AccessControl.hasRole(ORACLE_UPDATER_ROLE, msg.sender)
        require(msg.sender == owner(), "EcoSenseNexus: Not an oracle updater"); // Simplified
        _;
    }

    modifier onlyGovernor() {
        // In a real scenario, this would check AccessControl.hasRole(GOVERNOR_ROLE, msg.sender)
        require(msg.sender == owner(), "EcoSenseNexus: Not a governor"); // Simplified
        _;
    }

    modifier onlyActivePool(uint256 _poolId) {
        require(pools[_poolId].isActive, "EcoSenseNexus: Pool is not active");
        _;
    }

    modifier onlyReputable(uint256 _minReputation) {
        require(ecoReputationScores[msg.sender] >= _minReputation, "EcoSenseNexus: Insufficient reputation");
        _;
    }

    // --- II. Core Pool Management ---

    /**
     * @dev Creates a new impact investment pool.
     * @param _name The human-readable name of the pool.
     * @param _targetImpactMetric A unique identifier for the type of impact this pool targets.
     * @param _baseAPR The base Annual Percentage Rate (e.g., 500 for 5%).
     * @param _maxCapacity The maximum tokens that can be staked in this pool.
     * @param _rewardToken The address of the ERC20 token distributed as rewards.
     * @param _acceptedStakeToken The address of the ERC20 token accepted for staking.
     * @param _associatedOracleIds An array of oracle IDs whose data influences this pool's impact score.
     */
    function createEcoImpactPool(
        string memory _name,
        bytes32 _targetImpactMetric,
        uint256 _baseAPR,
        uint256 _maxCapacity,
        address _rewardToken,
        address _acceptedStakeToken,
        bytes32[] memory _associatedOracleIds
    ) external onlyOwner nonReentrant {
        require(_baseAPR > 0, "EcoSenseNexus: Base APR must be positive");
        require(_maxCapacity > 0, "EcoSenseNexus: Max capacity must be positive");
        require(_rewardToken != address(0), "EcoSenseNexus: Reward token cannot be zero address");
        require(_acceptedStakeToken != address(0), "EcoSenseNexus: Accepted stake token cannot be zero address");
        require(_associatedOracleIds.length > 0, "EcoSenseNexus: Must associate with at least one oracle feed");

        uint256 newPoolId = nextPoolId++;
        pools[newPoolId] = Pool({
            id: newPoolId,
            name: _name,
            targetImpactMetric: _targetImpactMetric,
            currentImpactScore: 1000, // Initial impact score (e.g., 100%)
            baseAPR: _baseAPR,
            parametricFactor: 1000,   // Initial parametric factor (1x)
            maxCapacity: _maxCapacity,
            currentStaked: 0,
            lastRewardCalcTime: block.timestamp,
            isActive: true,
            isDeprecated: false,
            rewardToken: _rewardToken,
            acceptedStakeToken: _acceptedStakeToken,
            associatedOracleIds: _associatedOracleIds
        });

        emit PoolCreated(newPoolId, _name, _acceptedStakeToken, _rewardToken);
    }

    /**
     * @dev Allows adjustment of a pool's base APR and maximum capacity.
     *      Can be called by admin or executed via governance proposal.
     * @param _poolId The ID of the pool to update.
     * @param _newBaseAPR The new base Annual Percentage Rate.
     * @param _newMaxCapacity The new maximum capacity.
     */
    function updatePoolParameters(
        uint256 _poolId,
        uint256 _newBaseAPR,
        uint256 _newMaxCapacity
    ) external onlyOwner nonReentrant { // In a full system, this would be onlyGovernor or proposal-driven
        require(pools[_poolId].id != 0, "EcoSenseNexus: Pool does not exist");
        require(_newBaseAPR > 0, "EcoSenseNexus: New base APR must be positive");
        require(_newMaxCapacity > 0, "EcoSenseNexus: New max capacity must be positive");

        pools[_poolId].baseAPR = _newBaseAPR;
        pools[_poolId].maxCapacity = _newMaxCapacity;

        emit PoolParametersUpdated(_poolId, _newBaseAPR, _newMaxCapacity);
    }

    /**
     * @dev Pauses a specific pool, preventing new deposits and withdrawals.
     * @param _poolId The ID of the pool to pause.
     */
    function pauseEcoImpactPool(uint256 _poolId) external onlyOwner nonReentrant {
        require(pools[_poolId].id != 0, "EcoSenseNexus: Pool does not exist");
        require(pools[_poolId].isActive, "EcoSenseNexus: Pool is already paused");
        pools[_poolId].isActive = false;
        emit PoolPaused(_poolId);
    }

    /**
     * @dev Unpauses a previously paused pool.
     * @param _poolId The ID of the pool to unpause.
     */
    function unpauseEcoImpactPool(uint256 _poolId) external onlyOwner nonReentrant {
        require(pools[_poolId].id != 0, "EcoSenseNexus: Pool does not exist");
        require(!pools[_poolId].isActive, "EcoSenseNexus: Pool is already active");
        pools[_poolId].isActive = true;
        emit PoolUnpaused(_poolId);
    }

    /**
     * @dev Marks a pool as deprecated. New deposits are prevented, but withdrawals are still allowed.
     *      Funds should eventually be migrated out of deprecated pools.
     * @param _poolId The ID of the pool to deprecate.
     */
    function deprecateEcoImpactPool(uint256 _poolId) external onlyOwner nonReentrant {
        require(pools[_poolId].id != 0, "EcoSenseNexus: Pool does not exist");
        require(!pools[_poolId].isDeprecated, "EcoSenseNexus: Pool is already deprecated");
        pools[_poolId].isDeprecated = true;
        pools[_poolId].isActive = false; // Deprecated pools cannot accept new deposits
        emit PoolDeprecated(_poolId);
    }

    // --- III. Oracle & Adaptive Logic Integration ---

    /**
     * @dev Registers a new oracle data feed that the contract can consume.
     * @param _source Human-readable source description (e.g., "Chainlink Carbon Data").
     * @param _initialValue Initial value reported by the oracle.
     * @param _updateFrequency Expected update frequency in seconds.
     * @param _impactWeight How much this oracle's data influences overall pool impact score (e.g., 1-100).
     */
    function registerOracleFeed(
        string memory _source,
        uint256 _initialValue,
        uint256 _updateFrequency,
        uint256 _impactWeight
    ) external onlyOwner nonReentrant {
        bytes32 oracleHashId = keccak256(abi.encodePacked("ORACLE_", nextOracleId)); // Simple hash for ID
        nextOracleId = keccak256(abi.encodePacked(oracleHashId, block.timestamp)); // Update for next ID

        oracleDataFeeds[oracleHashId] = OracleFeed({
            id: oracleHashId,
            source: _source,
            lastReportedValue: _initialValue,
            lastUpdatedTimestamp: block.timestamp,
            updateFrequency: _updateFrequency,
            impactWeight: _impactWeight
        });
        emit OracleFeedRegistered(oracleHashId, _source);
    }

    /**
     * @dev Authorized oracles push new environmental/impact data.
     *      This function triggers an update to the relevant oracle feed's data.
     * @param _oracleId The ID of the oracle feed to update.
     * @param _newValue The new value reported by the oracle.
     */
    function updateEnvironmentalOracleData(bytes32 _oracleId, uint256 _newValue) external onlyOracleUpdater nonReentrant {
        require(oracleDataFeeds[_oracleId].id != 0, "EcoSenseNexus: Oracle feed not registered");
        require(_newValue > 0, "EcoSenseNexus: Oracle value must be positive");

        oracleDataFeeds[_oracleId].lastReportedValue = _newValue;
        oracleDataFeeds[_oracleId].lastUpdatedTimestamp = block.timestamp;

        // Optionally, trigger specific pool adjustments if this oracle directly affects one
        // For simplicity, `triggerAdaptiveParamAdjustment` is a separate call or keeper triggered.

        emit OracleDataUpdated(_oracleId, _newValue, block.timestamp);
    }

    /**
     * @dev Internal function to calculate a pool's aggregate impact score based on its associated oracles.
     *      This simulates the "Adaptive Logic Engine" processing data.
     * @param _poolId The ID of the pool.
     * @return The new calculated aggregate impact score.
     */
    function _calculateAggregateImpactScore(uint256 _poolId) internal view returns (uint256) {
        Pool storage pool = pools[_poolId];
        uint256 totalWeightedValue = 0;
        uint256 totalWeight = 0;

        for (uint256 i = 0; i < pool.associatedOracleIds.length; i++) {
            bytes32 oracleId = pool.associatedOracleIds[i];
            OracleFeed storage oracle = oracleDataFeeds[oracleId];
            if (oracle.id != 0 && (block.timestamp.sub(oracle.lastUpdatedTimestamp) <= oracle.updateFrequency.mul(2))) {
                // Only consider recent and valid oracle data
                totalWeightedValue = totalWeightedValue.add(oracle.lastReportedValue.mul(oracle.impactWeight));
                totalWeight = totalWeight.add(oracle.impactWeight);
            }
        }

        if (totalWeight == 0) {
            return pool.currentImpactScore; // No valid oracle data, return current score
        }
        return totalWeightedValue.div(totalWeight); // Weighted average
    }

    /**
     * @dev Triggers the "Adaptive Logic Engine" for a specific pool.
     *      This function re-evaluates the pool's `parametricFactor` based on
     *      the latest aggregate impact score derived from its associated oracles.
     *      This mimics an on-chain "AI agent" adapting parameters.
     *      Can be called by admin or a scheduled keeper bot.
     * @param _poolId The ID of the pool to adjust.
     */
    function triggerAdaptiveParamAdjustment(uint256 _poolId) external onlyOwner nonReentrant {
        require(pools[_poolId].id != 0, "EcoSenseNexus: Pool does not exist");

        Pool storage pool = pools[_poolId];
        uint256 newAggregateImpactScore = _calculateAggregateImpactScore(_poolId);

        // Adaptive Logic Algorithm:
        // This is a simplified example. A real "AI agent" logic would be more complex.
        // It could involve:
        // - Comparing current impact score to historical trends.
        // - Setting thresholds for positive/negative adjustments.
        // - Considering overall market conditions or pool utilization.
        // For demonstration, let's say higher impact score -> higher parametric factor.
        // A baseline of 1000 means 1x.
        uint256 oldParametricFactor = pool.parametricFactor;
        uint256 oldImpactScore = pool.currentImpactScore;

        if (newAggregateImpactScore > oldImpactScore) {
            // Impact is improving: increase parametric factor, but with a cap
            pool.parametricFactor = oldParametricFactor.add(newAggregateImpactScore.sub(oldImpactScore).div(10)); // Scale up
            if (pool.parametricFactor > 2000) pool.parametricFactor = 2000; // Cap at 2x
        } else if (newAggregateImpactScore < oldImpactScore) {
            // Impact is declining: decrease parametric factor, with a floor
            pool.parametricFactor = oldParametricFactor.sub(oldImpactScore.sub(newAggregateImpactScore).div(10)); // Scale down
            if (pool.parametricFactor < 500) pool.parametricFactor = 500; // Floor at 0.5x
        }
        // If impact score is stable, factor remains stable.

        pool.currentImpactScore = newAggregateImpactScore;

        emit ParametricAdjustmentTriggered(_poolId, pool.parametricFactor, newAggregateImpactScore);
    }

    /**
     * @dev A view function to retrieve historical oracle data points. (Conceptual)
     *      In a real scenario, this data might be stored in a separate, more gas-efficient
     *      storage pattern (e.g., array of structs or mapping of timestamp to value)
     *      or be purely for off-chain analysis. For this example, it's illustrative.
     * @param _oracleId The ID of the oracle.
     * @param _timestamp The specific timestamp to query (simplified to return current).
     * @return The oracle value at or near the given timestamp.
     */
    function getHistoricalOracleData(bytes32 _oracleId, uint256 _timestamp)
        external
        view
        returns (uint256 value, uint256 reportedTimestamp)
    {
        // This is a placeholder. Storing extensive historical data on-chain is expensive.
        // For demonstration, it just returns the latest known value and its timestamp.
        require(oracleDataFeeds[_oracleId].id != 0, "EcoSenseNexus: Oracle feed not registered");
        return (oracleDataFeeds[_oracleId].lastReportedValue, oracleDataFeeds[_oracleId].lastUpdatedTimestamp);
    }

    // --- IV. User Interaction & Staking ---

    /**
     * @dev Allows users to deposit accepted tokens into a specified impact pool.
     *      Updates the user's eco-reputation based on their initial commitment.
     * @param _poolId The ID of the pool to deposit into.
     * @param _amount The amount of tokens to deposit.
     */
    function depositIntoPool(uint256 _poolId, uint256 _amount)
        external
        nonReentrant
        onlyActivePool(_poolId)
        whenNotPaused
    {
        require(pools[_poolId].id != 0, "EcoSenseNexus: Pool does not exist");
        require(_amount > 0, "EcoSenseNexus: Deposit amount must be positive");
        require(pools[_poolId].currentStaked.add(_amount) <= pools[_poolId].maxCapacity, "EcoSenseNexus: Pool at max capacity");

        // Transfer stake token from user to contract
        IERC20(pools[_poolId].acceptedStakeToken).transferFrom(msg.sender, address(this), _amount);

        // Calculate and add pending rewards based on previous stake duration
        _updatePendingRewards(msg.sender, _poolId);

        userStakes[_poolId][msg.sender] = userStakes[_poolId][msg.sender].add(_amount);
        pools[_poolId].currentStaked = pools[_poolId].currentStaked.add(_amount);
        userLastDepositTime[_poolId][msg.sender] = block.timestamp; // Update last deposit time for reputation calc

        // Initial reputation bump for new contribution
        _updateEcoReputation(msg.sender, _poolId, _amount.div(100), "Deposit initiated"); // Small bump for participation

        emit Deposited(_poolId, msg.sender, _amount);
    }

    /**
     * @dev Allows users to withdraw their staked tokens from a pool.
     *      Triggers recalculation and update of the user's eco-reputation
     *      based on staking duration and the pool's measured impact during that period.
     * @param _poolId The ID of the pool to withdraw from.
     * @param _amount The amount of tokens to withdraw.
     */
    function withdrawFromPool(uint256 _poolId, uint256 _amount) external nonReentrant whenNotPaused {
        require(pools[_poolId].id != 0, "EcoSenseNexus: Pool does not exist");
        require(userStakes[_poolId][msg.sender] >= _amount, "EcoSenseNexus: Insufficient staked amount");
        require(_amount > 0, "EcoSenseNexus: Withdraw amount must be positive");

        // Calculate and add pending rewards before withdrawal
        _updatePendingRewards(msg.sender, _poolId);

        userStakes[_poolId][msg.sender] = userStakes[_poolId][msg.sender].sub(_amount);
        pools[_poolId].currentStaked = pools[_poolId].currentStaked.sub(_amount);

        // Update Eco-Reputation based on duration and pool's impact during stake period
        uint256 duration = block.timestamp.sub(userLastDepositTime[_poolId][msg.sender]);
        // For simplicity, impact delta here is based on the pool's current impact score.
        // A more complex system would store historical pool impact scores per user stake period.
        uint256 impactDelta = pools[_poolId].currentImpactScore.div(100).mul(duration.div(1 days)); // Scale by duration and current impact
        _updateEcoReputation(msg.sender, _poolId, impactDelta, "Withdrawal completed, assessed impact");

        // Reset last deposit time if stake is fully withdrawn, or update if partial.
        if (userStakes[_poolId][msg.sender] == 0) {
            delete userLastDepositTime[_poolId][msg.sender];
        } else {
            userLastDepositTime[_poolId][msg.sender] = block.timestamp;
        }

        IERC20(pools[_poolId].acceptedStakeToken).transfer(msg.sender, _amount);
        emit Withdrew(_poolId, msg.sender, _amount);
    }

    /**
     * @dev Allows users to claim accumulated rewards from a pool separately.
     * @param _poolId The ID of the pool to claim from.
     */
    function claimRewards(uint256 _poolId) external nonReentrant whenNotPaused {
        require(pools[_poolId].id != 0, "EcoSenseNexus: Pool does not exist");

        _updatePendingRewards(msg.sender, _poolId); // Ensure rewards are up-to-date
        uint256 amount = pendingRewards[_poolId][msg.sender];
        require(amount > 0, "EcoSenseNexus: No rewards to claim");

        pendingRewards[_poolId][msg.sender] = 0;
        IERC20(pools[_poolId].rewardToken).transfer(msg.sender, amount);

        // Small reputation boost for claiming rewards, incentivizing engagement
        _updateEcoReputation(msg.sender, _poolId, amount.div(100), "Rewards claimed");

        emit RewardsClaimed(_poolId, msg.sender, amount);
    }

    /**
     * @dev Internal helper function to calculate and update a user's pending rewards.
     * @param _user The address of the user.
     * @param _poolId The ID of the pool.
     */
    function _updatePendingRewards(address _user, uint256 _poolId) internal {
        Pool storage pool = pools[_poolId];
        uint256 stakedAmount = userStakes[_poolId][_user];

        if (stakedAmount == 0) {
            return;
        }

        uint256 timeElapsed = block.timestamp.sub(pool.lastRewardCalcTime);

        // Avoid re-calculating for the same block or if no time has passed.
        if (timeElapsed == 0) {
            return;
        }

        // Calculate actual APR factoring in parametric factor
        // (baseAPR * parametricFactor / 1000) (where 1000 is 1x for parametric factor)
        uint256 effectiveAPR = pool.baseAPR.mul(pool.parametricFactor).div(1000); // Scale parametricFactor (e.g., 1000 = 1x)

        // Rewards = stakedAmount * effectiveAPR * timeElapsed / (365 days * 10000 for APR basis points)
        uint252 newRewards = stakedAmount
            .mul(effectiveAPR)
            .mul(timeElapsed)
            .div(365 days)
            .div(10000); // 10000 for basis points (100 * 100)

        pendingRewards[_poolId][_user] = pendingRewards[_poolId][_user].add(newRewards);
        pool.lastRewardCalcTime = block.timestamp; // Update for the pool for next calculation
    }

    /**
     * @dev Gets the estimated pending rewards for a user in a specific pool.
     * @param _poolId The ID of the pool.
     * @param _user The address of the user.
     * @return The estimated reward amount.
     */
    function getEstimatedRewards(uint256 _poolId, address _user) public view returns (uint256) {
        if (pools[_poolId].id == 0) return 0;
        if (userStakes[_poolId][_user] == 0) return pendingRewards[_poolId][_user];

        // This is a view function, so it can't modify state (`_updatePendingRewards`).
        // It calculates rewards based on current state, but doesn't persist them.
        uint256 stakedAmount = userStakes[_poolId][_user];
        uint256 timeElapsed = block.timestamp.sub(userLastDepositTime[_poolId][_user]); // Use user's last deposit time for calculation

        uint256 effectiveAPR = pools[_poolId].baseAPR.mul(pools[_poolId].parametricFactor).div(1000);

        uint256 currentPeriodRewards = stakedAmount
            .mul(effectiveAPR)
            .mul(timeElapsed)
            .div(365 days)
            .div(10000);

        return pendingRewards[_poolId][_user].add(currentPeriodRewards);
    }

    /**
     * @dev Gets the amount of tokens a user has staked in a specific pool.
     * @param _poolId The ID of the pool.
     * @param _user The address of the user.
     * @return The staked amount.
     */
    function getUserStakedAmount(uint256 _poolId, address _user) external view returns (uint256) {
        return userStakes[_poolId][_user];
    }

    // --- V. Eco-Reputation System ---

    /**
     * @dev Retrieves a user's current non-transferable Eco-Reputation Score.
     * @param _user The address of the user.
     * @return The Eco-Reputation Score.
     */
    function getEcoReputationScore(address _user) external view returns (uint256) {
        return ecoReputationScores[_user];
    }

    /**
     * @dev Internal function to update a user's Eco-Reputation Score.
     *      The score is dynamically adjusted based on:
     *      - `_impactDelta`: A value reflecting the positive/negative impact
     *        of their interaction (e.g., based on pool performance, duration of stake).
     *      - `_reason`: A string describing why the reputation was updated.
     * @param _user The address of the user whose reputation is updated.
     * @param _poolId The pool ID related to the action (0 if not pool-specific).
     * @param _impactDelta The change in reputation score (positive for gain, negative for loss).
     * @param _reason A description of the update.
     */
    function _updateEcoReputation(
        address _user,
        uint256 _poolId, // Can be 0 if not pool-specific
        int256 _impactDelta, // Use int256 to allow both positive and negative changes
        string memory _reason
    ) internal {
        uint256 currentScore = ecoReputationScores[_user];
        uint256 newScore;

        if (_impactDelta > 0) {
            newScore = currentScore.add(uint256(_impactDelta));
        } else {
            uint256 absDelta = uint256(-_impactDelta);
            if (currentScore > absDelta) {
                newScore = currentScore.sub(absDelta);
            } else {
                newScore = 0; // Cannot go below zero
            }
        }
        ecoReputationScores[_user] = newScore;
        emit EcoReputationUpdated(_user, newScore, _reason);
    }

    /**
     * @dev Admin function to reduce a user's reputation score for malicious behavior or non-compliance.
     * @param _user The address of the user whose reputation will be slashed.
     * @param _amount The amount by which to reduce the reputation.
     */
    function slashEcoReputation(address _user, uint256 _amount) external onlyOwner nonReentrant {
        require(ecoReputationScores[_user] >= _amount, "EcoSenseNexus: Slash amount exceeds current reputation");
        ecoReputationScores[_user] = ecoReputationScores[_user].sub(_amount);
        emit EcoReputationUpdated(_user, ecoReputationScores[_user], "Reputation slashed by admin");
    }

    // --- VI. Decentralized Governance ---

    /**
     * @dev Allows users with a minimum `ecoReputationScore` to propose changes to pool parameters.
     * @param _poolId The ID of the pool to target (0 for general proposals).
     * @param _paramKey The identifier for the parameter to change (e.g., keccak256("baseAPR")).
     * @param _newValue The proposed new value for the parameter.
     */
    function proposePoolParameterChange(
        uint256 _poolId,
        bytes32 _paramKey,
        uint256 _newValue
    ) external onlyReputable(minReputationToPropose) nonReentrant {
        require(pools[_poolId].id != 0 || _poolId == 0, "EcoSenseNexus: Pool does not exist"); // 0 for general proposals
        require(_paramKey != bytes32(0), "EcoSenseNexus: Parameter key cannot be empty");

        uint256 proposalId = nextProposalId++;
        activeProposals[proposalId] = Proposal({
            id: proposalId,
            poolId: _poolId,
            paramKey: _paramKey,
            newValue: _newValue,
            proposerScore: ecoReputationScores[msg.sender], // Snapshot proposer's score
            votesFor: 0,
            votesAgainst: 0,
            totalVoters: 0,
            minReputationToVote: minReputationToVote,
            votingDeadline: block.timestamp.add(VOTING_PERIOD),
            executed: false,
            cancelled: false,
            currentState: Proposal.State.Active
        });

        emit ProposalCreated(proposalId, _poolId, _paramKey, _newValue, msg.sender);
    }

    /**
     * @dev Allows users (with sufficient reputation) to vote on active proposals.
     *      Voting power is effectively weighted by `ecoReputationScore` if `_updateEcoReputation` is called after voting.
     * @param _proposalId The ID of the proposal to vote on.
     * @param _voteFor True for a 'for' vote, false for an 'against' vote.
     */
    function voteOnProposal(uint256 _proposalId, bool _voteFor)
        external
        onlyReputable(minReputationToVote)
        nonReentrant
    {
        Proposal storage proposal = activeProposals[_proposalId];
        require(proposal.id != 0, "EcoSenseNexus: Proposal does not exist");
        require(proposal.currentState == Proposal.State.Active, "EcoSenseNexus: Proposal is not active");
        require(block.timestamp <= proposal.votingDeadline, "EcoSenseNexus: Voting period has ended");
        require(!votedOnProposal[_proposalId][msg.sender], "EcoSenseNexus: Already voted on this proposal");

        if (_voteFor) {
            proposal.votesFor = proposal.votesFor.add(ecoReputationScores[msg.sender]); // Reputation-weighted vote
        } else {
            proposal.votesAgainst = proposal.votesAgainst.add(ecoReputationScores[msg.sender]); // Reputation-weighted vote
        }
        proposal.totalVoters = proposal.totalVoters.add(1); // Count unique voters
        votedOnProposal[_proposalId][msg.sender] = true;

        // Small reputation boost for participating in governance
        _updateEcoReputation(msg.sender, 0, 1, "Voted on proposal"); // 0 for general proposal

        emit Voted(_proposalId, msg.sender, _voteFor);
    }

    /**
     * @dev Executes a successful proposal if quorum and majority conditions are met.
     *      This can be called by anyone after the voting deadline.
     * @param _proposalId The ID of the proposal to execute.
     */
    function executeProposal(uint256 _proposalId) external nonReentrant {
        Proposal storage proposal = activeProposals[_proposalId];
        require(proposal.id != 0, "EcoSenseNexus: Proposal does not exist");
        require(!proposal.executed, "EcoSenseNexus: Proposal already executed");
        require(!proposal.cancelled, "EcoSenseNexus: Proposal cancelled");
        require(block.timestamp > proposal.votingDeadline, "EcoSenseNexus: Voting period not ended");

        uint256 totalVotes = proposal.votesFor.add(proposal.votesAgainst);

        // Simple quorum: at least 10% of total possible reputation (conceptual)
        // For simplicity, let's say a fixed threshold for `totalVoters` or a percentage of `proposerScore`
        uint256 requiredQuorum = proposal.proposerScore.div(2); // Example: 50% of proposer's score
        if (totalVotes < requiredQuorum) {
            proposal.currentState = Proposal.State.Failed;
            return;
        }

        // Majority: For votes must be > Against votes
        if (proposal.votesFor > proposal.votesAgainst) {
            proposal.currentState = Proposal.State.Succeeded;
            proposal.executed = true;

            // Apply the proposed change
            if (proposal.paramKey == keccak256(abi.encodePacked("baseAPR"))) {
                pools[proposal.poolId].baseAPR = proposal.newValue;
            } else if (proposal.paramKey == keccak256(abi.encodePacked("maxCapacity"))) {
                pools[proposal.poolId].maxCapacity = proposal.newValue;
            } else {
                revert("EcoSenseNexus: Unknown parameter key for execution");
            }

            emit ProposalExecuted(proposalId, proposal.poolId);
        } else {
            proposal.currentState = Proposal.State.Failed;
        }
    }

    // --- VII. Emergency & Maintenance ---

    /**
     * @dev Allows the owner to withdraw specific ERC20 tokens in case of an emergency (e.g., contract bug, exploit).
     * @param _tokenAddress The address of the ERC20 token to withdraw.
     * @param _amount The amount of tokens to withdraw.
     */
    function emergencyWithdrawAdmin(address _tokenAddress, uint256 _amount) external onlyOwner nonReentrant {
        require(_amount > 0, "EcoSenseNexus: Amount must be positive");
        IERC20(_tokenAddress).transfer(owner(), _amount);
        emit EmergencyFundsWithdrawn(_tokenAddress, _amount);
    }

    /**
     * @dev Placeholder for upgradability. This contract assumes it will be deployed
     *      behind a proxy (like UUPS or Transparent Proxy).
     *      The actual upgrade logic is handled by the proxy contract.
     *      This function is just a marker for an upgradeable contract.
     *      The `_newImplementation` address would be the address of the new version of this contract.
     */
    function upgradeToNewContract(address _newImplementation) external onlyOwner {
        // This function would typically be empty in an upgradeable implementation
        // or contain `_authorizeUpgrade` if using UUPS.
        // It's here to signify the intent of upgradability.
        // The actual call to upgrade is made on the proxy contract.
        require(_newImplementation != address(0), "EcoSenseNexus: New implementation cannot be zero address");
        // No logic here as the proxy handles the actual upgrade.
    }

    /**
     * @dev Sets a specific role (conceptual: e.g., ORACLE_UPDATER_ROLE, GOVERNOR_ROLE)
     *      to an account. In a real system, `AccessControl.grantRole` would be used.
     * @param _role The role to set (e.g., keccak256("ORACLE_UPDATER_ROLE")).
     * @param _account The address to grant the role to.
     */
    function setRolePermissions(bytes32 _role, address _account) external onlyOwner {
        // Conceptual. In a real project using OpenZeppelin AccessControl:
        // _grantRole(_role, _account);
        // For this example, roles are simplified to onlyOwner checks.
        revert("EcoSenseNexus: Role management is conceptual, use AccessControl for production");
    }

    /**
     * @dev Returns the details of a specific pool.
     * @param _poolId The ID of the pool.
     * @return All details of the pool.
     */
    function getPoolDetails(uint256 _poolId)
        external
        view
        returns (
            uint256 id,
            string memory name,
            bytes32 targetImpactMetric,
            uint256 currentImpactScore,
            uint256 baseAPR,
            uint256 parametricFactor,
            uint256 maxCapacity,
            uint256 currentStaked,
            bool isActive,
            bool isDeprecated,
            address rewardToken,
            address acceptedStakeToken
        )
    {
        Pool storage p = pools[_poolId];
        require(p.id != 0, "EcoSenseNexus: Pool does not exist");
        return (
            p.id,
            p.name,
            p.targetImpactMetric,
            p.currentImpactScore,
            p.baseAPR,
            p.parametricFactor,
            p.maxCapacity,
            p.currentStaked,
            p.isActive,
            p.isDeprecated,
            p.rewardToken,
            p.acceptedStakeToken
        );
    }

    /**
     * @dev Returns the total amount of tokens currently staked in a specific pool.
     * @param _poolId The ID of the pool.
     * @return The total staked amount.
     */
    function getTotalStakedInPool(uint256 _poolId) external view returns (uint256) {
        require(pools[_poolId].id != 0, "EcoSenseNexus: Pool does not exist");
        return pools[_poolId].currentStaked;
    }
}
```