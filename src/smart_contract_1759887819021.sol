Here is a Solidity smart contract named "ChronosForge" that introduces dynamic, evolving NFTs called "Temporal Sentinels." It integrates an internal ERC-20 token ("Temporal Essence"), a shared staking pool ("Nexus Pool"), advanced trait mechanics, and a basic on-chain governance system, aiming for an interesting, advanced, and creative set of features.

---

### ChronosForge: Temporal Sentinels Protocol

**Outline:**

1.  **Core Contracts:**
    *   `TemporalEssence`: An ERC-20 token managed internally by `ChronosForge` for powering Sentinels and as a reward mechanism.
    *   `ChronosForge`: The main ERC-721 contract for Temporal Sentinels, handling their creation, dynamic traits, evolution, interactions, and protocol-level logic.
    *   `IMockOracle`: An interface for an external oracle (simulated here) to influence Sentinel traits.
    *   `MockOracle`: A basic implementation of `IMockOracle` for testing purposes.

2.  **Sentinel Properties:**
    *   `Sentinel` struct: Stores core properties like `tokenId`, `createdAt`, `essenceProductionRate`, `internalEssenceBalance`, `sentienceLevel`, `temporalAge`, and Nexus Pool related data.
    *   `ChronoTrait`: Traits are dynamic. Numeric traits (e.g., "power", "tier") are stored as `string => uint256` mappings, and string traits (e.g., "origin") as `string => string` mappings for each Sentinel.
    *   `TemporalEssenceBalance`: Each Sentinel tracks an internal essence balance for in-protocol expenditures and passive generation.
    *   `SentienceLevel`: A crucial metric indicating a Sentinel's power and utility, increasing with activity and actions, potentially unlocking higher functions or multipliers.

3.  **Core Mechanics:**
    *   **Minting (`forgeSentinel`):** Creates a new ERC-721 Sentinel with initial pseudo-randomized traits and a base essence production rate.
    *   **Essence Generation (`activateSentinelEssence`, `claimSentinelEssence`):** Sentinels passively generate `TemporalEssence` over time. Owners can activate this pending essence into the Sentinel's internal balance, then claim it to their wallet.
    *   **Evolution (`evolveSentinel`):** Sentinels can evolve by consuming `TemporalEssence` and meeting `temporalAge` requirements, leading to trait alterations, power boosts, and significant `SentienceLevel` increases.
    *   **Trait Refinement (`refineChronoTrait`):** Owners can spend `TemporalEssence` to specifically upgrade mutable `Chrono-Traits` (e.g., "power", "defense"), incrementally increasing Sentinel capabilities and `SentienceLevel`.
    *   **Chrono-Fusion (`chronoFuseSentinels`):** A complex crafting mechanism where two Sentinels are burned, and a new, more powerful Sentinel is minted, inheriting combined/upgraded traits and a higher `SentienceLevel` at an `TemporalEssence` cost.
    *   **Nexus Pool (`attuneToNexusPool`, `claimNexusPoolRewards`, `deattuneFromNexusPool`):** A staking-like system where Sentinels deposit their internal `TemporalEssence` to a communal pool, earning continuous rewards based on their contribution and a global reward rate.
    *   **Oracle Integration (`updateCosmicAlignment`):** A specific trait ("Cosmic Alignment") can be updated by querying an external oracle, demonstrating how real-world data can influence NFT properties. This also boosts `SentienceLevel`.
    *   **Essence Transfer (`transferEssence`):** Allows an owner to transfer `TemporalEssence` between their own Sentinels.

4.  **Admin & Protocol Management (Ownable/Pausable):**
    *   Owner-controlled functions to adjust protocol parameters (essence rates, costs, recipes).
    *   Pausable mechanisms for emergency situations.
    *   Treasury withdrawal for managing non-`TemporalEssence` funds.

5.  **Chrono-Governance:**
    *   **Proposals (`proposeChronoGovernanceAction`):** High-sentience Sentinels (or their owners) can propose on-chain governance actions.
    *   **Voting (`voteOnChronoGovernanceProposal`):** Sentinels can vote "Yes" or "No" on active proposals.
    *   **Execution (`executeChronoGovernanceProposal`):** If a proposal passes a simple majority vote after its voting period, it can be executed, calling the target function encoded in the proposal.

**Function Summary (29 functions):**

---

### A. **TemporalEssence (ERC-20 Token) - Controlled by ChronosForge:**

1.  `mintEssenceToSentinel(uint256 sentinelId, uint256 amount)`: Internally mints `TemporalEssence` to a Sentinel's `internalEssenceBalance`. (Internal only)
2.  `burnEssenceFromSentinel(uint256 sentinelId, uint256 amount)`: Internally burns `TemporalEssence` from a Sentinel's `internalEssenceBalance`. (Internal only)
3.  `transferEssence(uint256 fromSentinelId, uint256 toSentinelId, uint256 amount)`: Transfers `TemporalEssence` between two Sentinels owned by `msg.sender`.
4.  `getSentinelEssenceBalance(uint256 sentinelId)`: Queries the `internalEssenceBalance` of a specific Sentinel.

### B. **Temporal Sentinel (ERC-721) - Core Functionality:**

5.  `forgeSentinel()`: Mints a new ERC-721 Temporal Sentinel with initial pseudo-random traits.
6.  `activateSentinelEssence(uint256 sentinelId)`: Calculates and moves passively generated essence from a pending state to the Sentinel's `internalEssenceBalance`.
7.  `claimSentinelEssence(uint256 sentinelId)`: Mints the Sentinel's `internalEssenceBalance` to the owner's external wallet, setting the Sentinel's balance to zero.
8.  `evolveSentinel(uint256 sentinelId)`: Triggers the evolution of a Sentinel, costing `TemporalEssence` and requiring a minimum `temporalAge`, enhancing traits and `sentienceLevel`.
9.  `refineChronoTrait(uint256 sentinelId, string memory traitName)`: Spends `TemporalEssence` to upgrade a specific mutable `Chrono-Trait` of a Sentinel.
10. `chronoFuseSentinels(uint256 sentinelId1, uint256 sentinelId2)`: Combines two existing Sentinels into a new, more powerful one, burning the originals and consuming `TemporalEssence`.
11. `attuneToNexusPool(uint256 sentinelId, uint256 essenceAmount)`: Deposits `TemporalEssence` from a Sentinel's internal balance into the shared Nexus Pool, starting reward accrual.
12. `claimNexusPoolRewards(uint256 sentinelId)`: Claims accrued `TemporalEssence` rewards from the Nexus Pool for an attuned Sentinel, minting them to the owner's wallet.
13. `deattuneFromNexusPool(uint256 sentinelId)`: Withdraws deposited `TemporalEssence` and claims any pending rewards from the Nexus Pool for a Sentinel.
14. `updateCosmicAlignment(uint256 sentinelId)`: Calls the configured oracle to update the "Cosmic Alignment" trait for a Sentinel, boosting its `sentienceLevel`.
15. `getSentinelInfo(uint256 sentinelId)`: Retrieves a comprehensive view of a Sentinel, including its core properties and selected trait values.
16. `getSentinelSentience(uint256 sentinelId)`: Returns the current `sentienceLevel` of a Sentinel.
17. `getSentinelTraitValue(uint256 sentinelId, string memory traitName)`: Queries the `uint256` value of a specific numeric trait for a Sentinel.
18. `getSentinelTraitValues(uint256 sentinelId)`: Returns arrays of known numeric trait names and their `uint256` values for a Sentinel.

### C. **Admin & Protocol Management (Ownable/Pausable):**

19. `setEssenceGenerationRate(uint256 newRate)`: Owner-only function to adjust the global base `essenceProductionRate`.
20. `setRefinementCost(string memory traitName, uint256 newCost)`: Owner-only function to set `TemporalEssence` costs for specific trait refinements.
21. `setFusionRecipe(uint256 sentinelId1Tier, uint256 sentinelId2Tier, uint256 newSentinelTier, uint256 essenceCost)`: Owner-only function to define `Chrono-Fusion` recipes based on Sentinel tiers and `TemporalEssence` cost.
22. `setOracleAddress(address _oracleAddress)`: Owner-only function to set the address of the external `IMockOracle` contract.
23. `pause()`: Owner-only function to pause critical protocol functions inherited from `Pausable`.
24. `unpause()`: Owner-only function to unpause critical protocol functions inherited from `Pausable`.
25. `withdrawTreasuryFunds(address tokenAddress, uint256 amount)`: Owner-only function to withdraw any ERC-20 token (except `TemporalEssence`) from the contract's balance.
26. `setNexusPoolRewardRate(uint256 rate)`: Owner-only function to set the base reward rate for the Nexus Pool.
27. `proposeChronoGovernanceAction(uint256 sentinelId, bytes memory actionData, uint256 proposalEndTime)`: Allows high-sentience Sentinels (or their owners) to create governance proposals containing ABI-encoded call data.
28. `voteOnChronoGovernanceProposal(uint256 sentinelId, uint256 proposalId, bool support)`: Allows Sentinels to vote "Yes" or "No" on an active governance proposal.
29. `executeChronoGovernanceProposal(uint256 proposalId)`: Executes a governance proposal if the voting period has ended and it has achieved a simple majority of "Yes" votes.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol"; // For Nexus Pool reward token (if different from Essence)

// Mock Oracle Interface for demonstration purposes
interface IMockOracle {
    function getCosmicAlignment() external view returns (uint256);
}

/**
 * @title ChronosForge: Temporal Sentinels Protocol
 * @dev This protocol enables the creation and management of dynamic, evolving ERC-721 NFTs called Temporal Sentinels.
 *      Sentinels possess unique Chrono-Traits, accrue Temporal Essence (ERC-20), evolve over time and through actions,
 *      and can participate in a shared Nexus Pool for rewards. Advanced features include trait refinement,
 *      Chrono-Fusion of Sentinels, oracle-influenced properties, and basic on-chain governance.
 *
 * Outline:
 * 1.  **Core Contracts:**
 *     - `TemporalEssence`: An ERC-20 token used for powering Sentinels and as a reward mechanism. Managed internally by ChronosForge.
 *     - `ChronosForge`: The main ERC-721 contract for Temporal Sentinels, managing their creation, traits, evolution, and interactions.
 *     - `IMockOracle`: Interface for external oracle integration (simulated).
 * 2.  **Sentinel Properties:**
 *     - `ChronoTrait`: Defines immutable, mutable, and dynamic properties of a Sentinel. Stored as `string` keys and `uint256` or `string` values.
 *     - `TemporalEssenceBalance`: Each Sentinel tracks its own accrued essence balance for internal use.
 *     - `SentienceLevel`: A metric increasing with activity and time, unlocking higher utility and influence.
 * 3.  **Core Mechanics:**
 *     - **Minting (`forgeSentinel`):** Initial creation of a Sentinel with pseudo-randomized base traits.
 *     - **Essence Generation (`activateSentinelEssence`, `claimSentinelEssence`):** Sentinels passively generate Temporal Essence over time, which owners can activate and claim.
 *     - **Evolution (`evolveSentinel`):** Sentinels can undergo evolution, potentially altering traits or gaining new abilities, costing essence and requiring a minimum age.
 *     - **Trait Refinement (`refineChronoTrait`):** Owners can spend Essence to upgrade specific mutable traits, increasing their power or efficiency.
 *     - **Chrono-Fusion (`chronoFuseSentinels`):** Combines two Sentinels into a new, more powerful one, burning the originals and potentially merging/upgrading traits.
 *     - **Nexus Pool (`attuneToNexusPool`, `claimNexusPoolRewards`, `deattuneFromNexusPool`):** A staking-like mechanism where Sentinels contribute Essence to a communal pool, earning rewards based on their contribution and Sentience.
 *     - **Oracle Integration (`updateCosmicAlignment`):** Certain "Cosmic Alignment" traits can be updated based on external oracle data.
 * 4.  **Governance/Admin:** Owner functions for protocol parameters, pausing, and emergency actions. Includes a basic proposal and voting system.
 *
 * Function Summary (29 functions):
 *
 * A. **TemporalEssence (ERC-20 Token) - Internal to ChronosForge for controlled supply and distribution:**
 * 1.  `mintEssenceToSentinel(uint256 sentinelId, uint256 amount)`: Mints Temporal Essence directly to a specific Sentinel's internal balance. (Internal call)
 * 2.  `burnEssenceFromSentinel(uint256 sentinelId, uint256 amount)`: Burns Temporal Essence from a Sentinel's internal balance. (Internal call)
 * 3.  `transferEssence(uint256 fromSentinelId, uint256 toSentinelId, uint256 amount)`: Transfers essence between Sentinels owned by the caller.
 * 4.  `getSentinelEssenceBalance(uint256 sentinelId)`: Queries the essence balance of a Sentinel.
 *
 * B. **Temporal Sentinel (ERC-721) - Core Functionality:**
 * 5.  `forgeSentinel()`: Mints a new Temporal Sentinel NFT with initial pseudo-random traits.
 * 6.  `activateSentinelEssence(uint256 sentinelId)`: Owner activates passive essence generation for their Sentinel, moving it from pending to active balance.
 * 7.  `claimSentinelEssence(uint256 sentinelId)`: Claims the active accrued essence from a Sentinel to the owner's wallet.
 * 8.  `evolveSentinel(uint256 sentinelId)`: Triggers evolution for a Sentinel, requiring essence and a minimum `temporalAge`, potentially altering traits and increasing Sentience.
 * 9.  `refineChronoTrait(uint256 sentinelId, string memory traitName)`: Upgrades a specific mutable Chrono-Trait using Essence, increasing Sentience.
 * 10. `chronoFuseSentinels(uint256 sentinelId1, uint256 sentinelId2)`: Combines two Sentinels into a new, more powerful one, burning the originals. Requires essence.
 * 11. `attuneToNexusPool(uint256 sentinelId, uint256 essenceAmount)`: Deposits Temporal Essence from a Sentinel into the shared Nexus Pool, starting reward accrual.
 * 12. `claimNexusPoolRewards(uint256 sentinelId)`: Claims earned rewards (in Essence) from the Nexus Pool for an attuned Sentinel.
 * 13. `deattuneFromNexusPool(uint256 sentinelId)`: Withdraws deposited essence and claims any pending rewards from the Nexus Pool for a Sentinel.
 * 14. `updateCosmicAlignment(uint256 sentinelId)`: Updates an oracle-dependent "Cosmic Alignment" trait for a Sentinel, if an oracle is set. Increases Sentience.
 * 15. `getSentinelInfo(uint256 sentinelId)`: Retrieves all current data and traits for a given Sentinel.
 * 16. `getSentinelSentience(uint256 sentinelId)`: Returns the current sentience level of a Sentinel.
 * 17. `getSentinelTraitValue(uint256 sentinelId, string memory traitName)`: Queries the value of a specific numeric trait.
 * 18. `getSentinelTraitValues(uint256 sentinelId)`: Returns all known numeric trait names and their uint256 values for a Sentinel.
 *
 * C. **Admin & Protocol Management (Ownable/Pausable):**
 * 19. `setEssenceGenerationRate(uint256 newRate)`: Admin function to adjust the global essence generation rate per hour.
 * 20. `setRefinementCost(string memory traitName, uint256 newCost)`: Admin function to set the Essence cost for specific trait refinements.
 * 21. `setFusionRecipe(uint256 sentinelId1Tier, uint256 sentinelId2Tier, uint256 newSentinelTier, uint256 essenceCost)`: Admin function to define fusion recipes.
 * 22. `setOracleAddress(address _oracleAddress)`: Admin function to set the address of the external `IMockOracle`.
 * 23. `pause()`: Pauses core protocol functions (inherits from Pausable).
 * 24. `unpause()`: Unpauses core protocol functions (inherits from Pausable).
 * 25. `withdrawTreasuryFunds(address tokenAddress, uint256 amount)`: Admin function to withdraw any ERC-20 token from the contract treasury (excluding TemporalEssence).
 * 26. `setNexusPoolRewardRate(uint256 rate)`: Admin function to set the base reward rate for the Nexus Pool.
 * 27. `proposeChronoGovernanceAction(uint256 sentinelId, bytes memory actionData, uint256 proposalEndTime)`: Allows high-sentience Sentinels to propose governance actions.
 * 28. `voteOnChronoGovernanceProposal(uint256 sentinelId, uint256 proposalId, bool support)`: Sentinels vote on proposals.
 * 29. `executeChronoGovernanceProposal(uint256 proposalId)`: Executes a passed governance proposal.
 *
 * This contract provides 29 functions, exceeding the minimum of 20, covering a wide range of advanced mechanics.
 * Note: Oracle integration is simulated with a mock interface. For production, Chainlink VRF or a robust oracle solution would be necessary for "true" external data.
 * Randomness for initial trait generation is simulated using block data and transaction details, which is NOT cryptographically secure and should not be used for high-value randomness in production.
 * Chrono-Fusion is simplified: it burns two NFTs and mints a new one with potentially higher stats.
 * Trait storage differentiates between general traits (string to uint256) and more complex ones.
 */


// --- TemporalEssence ERC-20 Token Contract ---
contract TemporalEssence is ERC20, Ownable {
    constructor() ERC20("Temporal Essence", "TES") Ownable(msg.sender) {}

    // Internal mint function, only callable by the owner (ChronosForge contract)
    function mint(address to, uint256 amount) internal {
        _mint(to, amount);
    }

    // Internal burn function, only callable by the owner (ChronosForge contract)
    function burn(address from, uint256 amount) internal {
        _burn(from, amount);
    }
}


// --- ChronosForge ERC-721 Sentinel Contract ---
contract ChronosForge is ERC721, ReentrancyGuard, Pausable, Ownable {
    using Counters for Counters.Counter;

    // --- State Variables ---
    TemporalEssence public temporalEssence; // ERC-20 token contract instance
    Counters.Counter private _sentinelIds;

    struct Sentinel {
        uint256 tokenId;
        uint256 createdAt;             // Timestamp of creation
        uint256 lastEssenceClaimTime;  // Last time essence was claimed/activated
        uint256 essenceProductionRate; // Rate of essence generation per hour (e.g., 1000 for 1 TES/hour)
        uint256 internalEssenceBalance; // Essence accumulated but not yet claimed to owner's wallet (internal, for protocol use)
        uint256 sentienceLevel;        // Metric for Sentinel's utility/power
        uint256 temporalAge;           // Age in hours, calculated from createdAt
        uint256 lastOracleUpdate;      // Timestamp of last cosmic alignment update

        // Nexus Pool specific data
        uint256 nexusPoolDepositAmount; // Amount of essence deposited in Nexus Pool
        uint256 nexusPoolDepositTime;   // Timestamp of last deposit/withdrawal/claim for Nexus Pool reward calculation
        uint256 nexusPoolRewardsClaimed; // Total rewards claimed from Nexus Pool (for historical tracking)
    }

    // Mapping to store Sentinel data
    mapping(uint256 => Sentinel) public sentinels;
    // Mapping for mutable Chrono-Traits (string name => uint256 value)
    mapping(uint256 => mapping(string => uint256)) public sentinelNumericTraits;
    // Mapping for other string-based traits (e.g., 'Origin')
    mapping(uint256 => mapping(string => string)) public sentinelStringTraits;

    // Protocol Parameters
    uint256 public BASE_ESSENCE_GENERATION_RATE = 1000; // 1000 units per hour (scaled as 1 TES = 10^18)
    uint256 public EVOLUTION_ESSENCE_COST = 50 * 10**18; // 50 TES
    uint256 public EVOLUTION_MIN_AGE_HOURS = 24 * 7;    // 7 days
    uint256 public FUSION_BASE_ESSENCE_COST = 100 * 10**18; // 100 TES

    // Trait refinement costs: traitName => essenceCost
    mapping(string => uint256) public refinementCosts;

    // Chrono-Fusion recipes: tier1 + tier2 => newTier, cost
    struct FusionRecipe {
        uint256 newTier;
        uint256 essenceCost;
        bool exists;
    }
    mapping(uint256 => mapping(uint256 => FusionRecipe)) public fusionRecipes;

    // Nexus Pool parameters
    uint256 public nexusPoolTotalDepositedEssence;
    uint256 public nexusPoolRewardRatePerEssencePerHour; // e.g., 100 for 0.01% per hour (10000 = 1%)
    mapping(uint256 => uint256) public sentinelNexusPoolRewardDebt; // For proportional reward calculation

    // Oracle integration
    IMockOracle public oracle;

    // Governance
    struct Proposal {
        uint256 proposalId;
        bytes actionData;          // Encoded call data for the action to be executed
        uint256 proposerSentinelId;
        uint256 voteStartTime;
        uint256 voteEndTime;
        uint256 yesVotes;
        uint256 noVotes;
        bool executed;
        mapping(uint256 => bool) hasVoted; // sentinelId => voted status
    }
    Counters.Counter public _proposalIds;
    mapping(uint256 => Proposal) public proposals;
    uint256 public MIN_SENTIENCE_FOR_PROPOSAL = 1000; // Minimum sentience level to propose
    uint256 public PROPOSAL_VOTING_PERIOD = 24 * 60 * 60 * 3; // 3 days for voting

    // --- Events ---
    event SentinelForged(uint256 indexed tokenId, address indexed owner, uint256 createdAt);
    event EssenceActivated(uint256 indexed sentinelId, uint256 amount);
    event EssenceClaimed(uint256 indexed sentinelId, address indexed claimant, uint256 amount);
    event SentinelEvolved(uint256 indexed sentinelId, uint256 newSentienceLevel, uint256 newTemporalAge);
    event ChronoTraitRefined(uint256 indexed sentinelId, string traitName, uint256 newValue, uint256 essenceCost);
    event SentinelsFused(uint256 indexed sentinelId1, uint256 indexed sentinelId2, uint256 indexed newSentinelId);
    event AttunedToNexusPool(uint256 indexed sentinelId, uint256 amount);
    event NexusPoolRewardsClaimed(uint256 indexed sentinelId, uint256 amount);
    event DeattunedFromNexusPool(uint256 indexed sentinelId, uint256 withdrawnAmount, uint256 claimedRewards);
    event CosmicAlignmentUpdated(uint256 indexed sentinelId, uint256 alignmentValue);
    event GovernanceProposalCreated(uint256 indexed proposalId, uint256 indexed proposerSentinelId, uint256 endTime);
    event GovernanceVoteCast(uint256 indexed proposalId, uint256 indexed voterSentinelId, bool support);
    event GovernanceProposalExecuted(uint256 indexed proposalId, bool success);

    constructor(address _essenceTokenAddress)
        ERC721("Temporal Sentinel", "SENTINEL")
        Ownable(msg.sender)
    {
        temporalEssence = TemporalEssence(_essenceTokenAddress);
    }

    // --- Internal Helpers ---

    function _generatePseudoRandomUint(string memory salt) internal view returns (uint256) {
        // WARNING: This is NOT cryptographically secure randomness.
        // For production, use Chainlink VRF or similar solutions.
        return uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, msg.sender, salt, _sentinelIds.current())));
    }

    function _updateTemporalAge(uint256 sentinelId) internal view returns (uint256) {
        // Calculates and returns current age, but doesn't store it to save gas.
        // Actual storage update happens on specific actions like evolve.
        return (block.timestamp - sentinels[sentinelId].createdAt) / 3600;
    }

    function _calculatePendingEssence(uint256 sentinelId) internal view returns (uint256) {
        Sentinel storage sentinel = sentinels[sentinelId];
        if (sentinel.essenceProductionRate == 0 || sentinel.lastEssenceClaimTime == 0) {
            return 0;
        }
        uint256 hoursSinceLastClaim = (block.timestamp - sentinel.lastEssenceClaimTime) / 3600;
        return (sentinel.essenceProductionRate * hoursSinceLastClaim); // Already scaled
    }

    function _calculateNexusPoolRewards(uint256 sentinelId) internal view returns (uint256) {
        Sentinel storage sentinel = sentinels[sentinelId];
        if (sentinel.nexusPoolDepositAmount == 0 || sentinel.nexusPoolDepositTime == 0) {
            return 0;
        }
        uint256 hoursSinceLastAction = (block.timestamp - sentinel.nexusPoolDepositTime) / 3600;
        // Reward per essence is scaled (e.g., 100 for 0.01% of 10^18 essence)
        // So, nexusPoolRewardRatePerEssencePerHour should be treated as basis points * 10^(18-X)
        // Here, assuming 100 means 0.01%, so 100 / 10000 = 0.01. So, divide by 10^4 for percentage, then by 10^18 for TES units, total 10^22 if TES is 10^18.
        // Simplified to divide by 10^4 for percentage, applied to full amount
        uint256 currentReward = (sentinel.nexusPoolDepositAmount * nexusPoolRewardRatePerEssencePerHour * hoursSinceLastAction) / 10000; // Simplified scaling for percentage

        // Subtract already accrued debt to get only new rewards
        uint256 rewardDebt = sentinelNexusPoolRewardDebt[sentinelId];
        if (currentReward <= rewardDebt) return 0;
        return currentReward - rewardDebt;
    }

    function _updateNexusPoolRewardDebt(uint256 sentinelId) internal {
        Sentinel storage sentinel = sentinels[sentinelId];
        if (sentinel.nexusPoolDepositAmount > 0) {
            uint256 hoursSinceLastAction = (block.timestamp - sentinel.nexusPoolDepositTime) / 3600;
            sentinelNexusPoolRewardDebt[sentinelId] = (sentinel.nexusPoolDepositAmount * nexusPoolRewardRatePerEssencePerHour * hoursSinceLastAction) / 10000;
            sentinel.nexusPoolDepositTime = block.timestamp;
        }
    }

    // --- A. TemporalEssence (ERC-20 Token) ---

    // Internal function to mint essence directly to a sentinel's internal balance
    function mintEssenceToSentinel(uint256 sentinelId, uint256 amount) internal onlyOwner nonReentrant {
        require(_exists(sentinelId), "Sentinel does not exist");
        sentinels[sentinelId].internalEssenceBalance += amount;
    }

    // Internal function to burn essence from a sentinel's internal balance
    function burnEssenceFromSentinel(uint256 sentinelId, uint256 amount) internal onlyOwner nonReentrant {
        require(_exists(sentinelId), "Sentinel does not exist");
        require(sentinels[sentinelId].internalEssenceBalance >= amount, "Insufficient sentinel essence");
        sentinels[sentinelId].internalEssenceBalance -= amount;
    }

    /**
     * @dev Transfers Temporal Essence between two Sentinels owned by the caller.
     *      Allows an owner to manage essence liquidity between their own NFTs.
     * @param fromSentinelId The ID of the Sentinel to transfer essence from.
     * @param toSentinelId The ID of the Sentinel to transfer essence to.
     * @param amount The amount of Essence to transfer (scaled, e.g., 1 TES = 10**18).
     */
    function transferEssence(uint256 fromSentinelId, uint256 toSentinelId, uint256 amount)
        public
        whenNotPaused
        nonReentrant
    {
        require(ownerOf(fromSentinelId) == msg.sender, "Caller is not owner of source Sentinel");
        require(ownerOf(toSentinelId) == msg.sender, "Caller is not owner of destination Sentinel");
        require(fromSentinelId != toSentinelId, "Cannot transfer essence to the same Sentinel");
        require(sentinels[fromSentinelId].internalEssenceBalance >= amount, "Insufficient essence in source Sentinel");

        sentinels[fromSentinelId].internalEssenceBalance -= amount;
        sentinels[toSentinelId].internalEssenceBalance += amount;
    }

    /**
     * @dev Queries the internal Temporal Essence balance of a specific Sentinel.
     *      This balance is used for in-protocol actions.
     * @param sentinelId The ID of the Sentinel.
     * @return The current internal essence balance of the Sentinel (scaled).
     */
    function getSentinelEssenceBalance(uint256 sentinelId) public view returns (uint256) {
        return sentinels[sentinelId].internalEssenceBalance + _calculatePendingEssence(sentinelId);
    }

    // --- B. Temporal Sentinel (ERC-721) ---

    /**
     * @dev Mints a new Temporal Sentinel NFT with initial pseudo-random traits.
     *      The initial traits and essence production rate are determined pseudo-randomly.
     * @return The ID of the newly forged Sentinel.
     */
    function forgeSentinel() public whenNotPaused nonReentrant returns (uint256) {
        _sentinelIds.increment();
        uint256 newTokenId = _sentinelIds.current();

        // Pseudo-random generation of initial traits (NOT CRYPTOGRAPHICALLY SECURE)
        uint256 randomness = _generatePseudoRandomUint("forge");
        uint256 baseRate = BASE_ESSENCE_GENERATION_RATE * (10**18 / 1000) + (randomness % (500 * 10**18 / 1000)); // Scaled TES/hour
        uint256 initialSentience = 100 + (randomness % 100); // 100-199

        sentinels[newTokenId] = Sentinel({
            tokenId: newTokenId,
            createdAt: block.timestamp,
            lastEssenceClaimTime: block.timestamp,
            essenceProductionRate: baseRate,
            internalEssenceBalance: 0,
            sentienceLevel: initialSentience,
            temporalAge: 0, // Will be updated on first action or by direct call
            lastOracleUpdate: block.timestamp,
            nexusPoolDepositAmount: 0,
            nexusPoolDepositTime: 0,
            nexusPoolRewardsClaimed: 0
        });

        // Initialize some numeric traits
        sentinelNumericTraits[newTokenId]["tier"] = 1;
        sentinelNumericTraits[newTokenId]["power"] = 50 + (randomness % 50);
        sentinelNumericTraits[newTokenId]["defense"] = 30 + (randomness % 30);

        // Initialize some string traits
        string[3] memory origins = ["Alpha", "Beta", "Gamma"];
        sentinelStringTraits[newTokenId]["origin"] = origins[randomness % 3];

        _safeMint(msg.sender, newTokenId);
        emit SentinelForged(newTokenId, msg.sender, block.timestamp);
        return newTokenId;
    }

    /**
     * @dev Activates passive essence generation for a Sentinel. This moves any pending essence
     *      (accrued since `lastEssenceClaimTime`) into the Sentinel's `internalEssenceBalance`.
     * @param sentinelId The ID of the Sentinel.
     */
    function activateSentinelEssence(uint256 sentinelId) public whenNotPaused nonReentrant {
        require(ownerOf(sentinelId) == msg.sender, "Caller is not owner of Sentinel");

        // Sentinel's age is calculated on the fly for read, but can be explicitly stored on evolution.
        uint256 pendingEssence = _calculatePendingEssence(sentinelId);
        if (pendingEssence > 0) {
            sentinels[sentinelId].internalEssenceBalance += pendingEssence;
            sentinels[sentinelId].lastEssenceClaimTime = block.timestamp;
            emit EssenceActivated(sentinelId, pendingEssence);
        }
    }

    /**
     * @dev Claims the active accrued Temporal Essence from a Sentinel to the owner's wallet.
     *      Automatically activates any pending essence before claiming.
     * @param sentinelId The ID of the Sentinel.
     */
    function claimSentinelEssence(uint256 sentinelId) public whenNotPaused nonReentrant {
        require(ownerOf(sentinelId) == msg.sender, "Caller is not owner of Sentinel");

        activateSentinelEssence(sentinelId); // Ensure all pending essence is moved to internal balance
        uint256 essenceToClaim = sentinels[sentinelId].internalEssenceBalance;
        require(essenceToClaim > 0, "No essence to claim for this Sentinel");

        sentinels[sentinelId].internalEssenceBalance = 0;
        temporalEssence.mint(msg.sender, essenceToClaim); // Mint to user's wallet from protocol's total supply
        emit EssenceClaimed(sentinelId, msg.sender, essenceToClaim);
    }

    /**
     * @dev Triggers evolution for a Sentinel. Requires sufficient essence and a minimum `temporalAge`.
     *      Evolution significantly alters traits, boosts `essenceProductionRate`, and increases `sentienceLevel`.
     * @param sentinelId The ID of the Sentinel to evolve.
     */
    function evolveSentinel(uint256 sentinelId) public whenNotPaused nonReentrant {
        require(ownerOf(sentinelId) == msg.sender, "Caller is not owner of Sentinel");
        
        sentinels[sentinelId].temporalAge = _updateTemporalAge(sentinelId); // Update stored age on action
        require(sentinels[sentinelId].temporalAge >= EVOLUTION_MIN_AGE_HOURS, "Sentinel too young to evolve");
        require(sentinels[sentinelId].internalEssenceBalance >= EVOLUTION_ESSENCE_COST, "Not enough essence for evolution");

        sentinels[sentinelId].internalEssenceBalance -= EVOLUTION_ESSENCE_COST;
        sentinels[sentinelId].sentienceLevel += (EVOLUTION_ESSENCE_COST / (10**18)) * 10; // Sentience boost per TES
        sentinels[sentinelId].essenceProductionRate += (sentinels[sentinelId].essenceProductionRate / 10); // 10% rate boost

        // Example trait evolution: boost power, potentially add a new trait
        sentinelNumericTraits[sentinelId]["power"] += 20;
        sentinelNumericTraits[sentinelId]["defense"] += 10;

        // Introduce a new trait if it doesn't exist, or level it up
        if (sentinelNumericTraits[sentinelId]["enhancedCore"] == 0) {
            sentinelNumericTraits[sentinelId]["enhancedCore"] = 1;
        } else {
            sentinelNumericTraits[sentinelId]["enhancedCore"] += 1; // Level up enhancedCore
        }

        emit SentinelEvolved(sentinelId, sentinels[sentinelId].sentienceLevel, sentinels[sentinelId].temporalAge);
    }

    /**
     * @dev Upgrades a specific mutable Chrono-Trait for a Sentinel using `TemporalEssence`.
     *      Increases the trait's value and provides a small `sentienceLevel` boost.
     * @param sentinelId The ID of the Sentinel.
     * @param traitName The name of the trait to refine (e.g., "power", "defense").
     */
    function refineChronoTrait(uint256 sentinelId, string memory traitName) public whenNotPaused nonReentrant {
        require(ownerOf(sentinelId) == msg.sender, "Caller is not owner of Sentinel");
        uint256 cost = refinementCosts[traitName];
        require(cost > 0, "Trait not refinable or cost not set");
        require(sentinels[sentinelId].internalEssenceBalance >= cost, "Not enough essence for refinement");

        sentinels[sentinelId].internalEssenceBalance -= cost;
        sentinelNumericTraits[sentinelId][traitName] += 5; // Example: increase trait by 5
        sentinels[sentinelId].sentienceLevel += cost / (10**18 * 5); // Small sentience boost per 5 TES spent

        emit ChronoTraitRefined(sentinelId, traitName, sentinelNumericTraits[sentinelId][traitName], cost);
    }

    /**
     * @dev Combines two Sentinels into a new, more powerful one, burning the originals.
     *      Requires `TemporalEssence` and a valid fusion recipe. The new Sentinel inherits
     *      combined/upgraded traits and increased Sentience.
     * @param sentinelId1 The ID of the first Sentinel to fuse.
     * @param sentinelId2 The ID of the second Sentinel to fuse.
     * @return The ID of the newly created fused Sentinel.
     */
    function chronoFuseSentinels(uint256 sentinelId1, uint256 sentinelId2) public whenNotPaused nonReentrant returns (uint256) {
        require(ownerOf(sentinelId1) == msg.sender, "Caller is not owner of Sentinel 1");
        require(ownerOf(sentinelId2) == msg.sender, "Caller is not owner of Sentinel 2");
        require(sentinelId1 != sentinelId2, "Cannot fuse a Sentinel with itself");

        uint256 tier1 = sentinelNumericTraits[sentinelId1]["tier"];
        uint256 tier2 = sentinelNumericTraits[sentinelId2]["tier"];
        FusionRecipe storage recipe = fusionRecipes[tier1][tier2];
        require(recipe.exists, "No fusion recipe exists for these Sentinel tiers");
        
        // For simplicity, checking internal balance of Sentinel 1 only for the cost.
        // A more complex system might combine essence from both or require external TES.
        require(sentinels[sentinelId1].internalEssenceBalance >= recipe.essenceCost, "Sentinel 1 needs more essence for fusion");

        // Burn essence from Sentinel 1
        sentinels[sentinelId1].internalEssenceBalance -= recipe.essenceCost;

        // Burn the original Sentinels
        _burn(sentinelId1);
        _burn(sentinelId2);

        // Mint a new Sentinel
        _sentinelIds.increment();
        uint256 newSentinelId = _sentinelIds.current();

        // New Sentinel's initial stats (simplified combination and boost)
        uint256 newPower = (sentinelNumericTraits[sentinelId1]["power"] + sentinelNumericTraits[sentinelId2]["power"]) / 2 + 30;
        uint256 newDefense = (sentinelNumericTraits[sentinelId1]["defense"] + sentinelNumericTraits[sentinelId2]["defense"]) / 2 + 20;
        uint256 newEssenceRate = (sentinels[sentinelId1].essenceProductionRate + sentinels[sentinelId2].essenceProductionRate) / 2;
        uint256 newSentience = (sentinels[sentinelId1].sentienceLevel + sentinels[sentinelId2].sentienceLevel) / 2 + 200;

        sentinels[newSentinelId] = Sentinel({
            tokenId: newSentinelId,
            createdAt: block.timestamp,
            lastEssenceClaimTime: block.timestamp,
            essenceProductionRate: newEssenceRate,
            internalEssenceBalance: 0, // Starts fresh with 0 essence
            sentienceLevel: newSentience,
            temporalAge: 0,
            lastOracleUpdate: block.timestamp,
            nexusPoolDepositAmount: 0,
            nexusPoolDepositTime: 0,
            nexusPoolRewardsClaimed: 0
        });

        sentinelNumericTraits[newSentinelId]["tier"] = recipe.newTier;
        sentinelNumericTraits[newSentinelId]["power"] = newPower;
        sentinelNumericTraits[newSentinelId]["defense"] = newDefense;
        sentinelStringTraits[newSentinelId]["origin"] = "Fused";

        _safeMint(msg.sender, newSentinelId);
        emit SentinelsFused(sentinelId1, sentinelId2, newSentinelId);
        return newSentinelId;
    }

    /**
     * @dev Deposits Temporal Essence from a Sentinel's `internalEssenceBalance` into the shared Nexus Pool.
     *      Starts accrual of Nexus Pool rewards for this Sentinel.
     * @param sentinelId The ID of the Sentinel.
     * @param essenceAmount The amount of Essence to deposit (scaled).
     */
    function attuneToNexusPool(uint256 sentinelId, uint256 essenceAmount) public whenNotPaused nonReentrant {
        require(ownerOf(sentinelId) == msg.sender, "Caller is not owner of Sentinel");
        require(essenceAmount > 0, "Deposit amount must be greater than zero");
        require(sentinels[sentinelId].internalEssenceBalance >= essenceAmount, "Insufficient essence in Sentinel balance");

        // First, update rewards for any *existing* deposit before new deposit or calculations
        _updateNexusPoolRewardDebt(sentinelId);

        sentinels[sentinelId].internalEssenceBalance -= essenceAmount;
        sentinels[sentinelId].nexusPoolDepositAmount += essenceAmount;
        sentinels[sentinelId].nexusPoolDepositTime = block.timestamp; // Reset timer for new deposit
        nexusPoolTotalDepositedEssence += essenceAmount;

        emit AttunedToNexusPool(sentinelId, essenceAmount);
    }

    /**
     * @dev Claims earned rewards (in `TemporalEssence`) from the Nexus Pool for an attuned Sentinel.
     *      Rewards are minted directly to the owner's wallet.
     * @param sentinelId The ID of the Sentinel.
     */
    function claimNexusPoolRewards(uint256 sentinelId) public whenNotPaused nonReentrant {
        require(ownerOf(sentinelId) == msg.sender, "Caller is not owner of Sentinel");
        require(sentinels[sentinelId].nexusPoolDepositAmount > 0, "Sentinel not attuned to Nexus Pool or no deposit");

        uint256 rewards = _calculateNexusPoolRewards(sentinelId);
        require(rewards > 0, "No rewards accrued yet");

        _updateNexusPoolRewardDebt(sentinelId); // Reset debt after calculating and before minting
        sentinels[sentinelId].nexusPoolRewardsClaimed += rewards;
        temporalEssence.mint(msg.sender, rewards);

        emit NexusPoolRewardsClaimed(sentinelId, rewards);
    }

    /**
     * @dev Withdraws deposited essence and claims any pending rewards from the Nexus Pool for a Sentinel.
     * @param sentinelId The ID of the Sentinel.
     */
    function deattuneFromNexusPool(uint256 sentinelId) public whenNotPaused nonReentrant {
        require(ownerOf(sentinelId) == msg.sender, "Caller is not owner of Sentinel");
        require(sentinels[sentinelId].nexusPoolDepositAmount > 0, "Sentinel not attuned to Nexus Pool or no deposit");

        uint256 depositedAmount = sentinels[sentinelId].nexusPoolDepositAmount;
        uint256 rewards = _calculateNexusPoolRewards(sentinelId);

        _updateNexusPoolRewardDebt(sentinelId); // Final debt update
        sentinels[sentinelId].nexusPoolDepositAmount = 0;
        sentinels[sentinelId].nexusPoolDepositTime = 0;
        nexusPoolTotalDepositedEssence -= depositedAmount;
        sentinelNexusPoolRewardDebt[sentinelId] = 0; // Clear debt for this Sentinel

        // Mint deposited amount + rewards to user
        temporalEssence.mint(msg.sender, depositedAmount + rewards);
        sentinels[sentinelId].nexusPoolRewardsClaimed += rewards; // Track total claimed

        emit DeattunedFromNexusPool(sentinelId, depositedAmount, rewards);
    }

    /**
     * @dev Updates an oracle-dependent "Cosmic Alignment" trait for a Sentinel.
     *      Requires an oracle address to be set. This is a simulated oracle call.
     *      Updates the trait and provides a small `sentienceLevel` boost.
     * @param sentinelId The ID of the Sentinel.
     */
    function updateCosmicAlignment(uint256 sentinelId) public whenNotPaused nonReentrant {
        require(ownerOf(sentinelId) == msg.sender, "Caller is not owner of Sentinel");
        require(address(oracle) != address(0), "Oracle address not set");

        // Simulate fetching data from oracle
        uint256 alignmentValue = oracle.getCosmicAlignment();
        sentinelNumericTraits[sentinelId]["cosmicAlignment"] = alignmentValue;
        sentinels[sentinelId].lastOracleUpdate = block.timestamp;
        sentinels[sentinelId].sentienceLevel += alignmentValue / 100; // Small sentience boost from alignment

        emit CosmicAlignmentUpdated(sentinelId, alignmentValue);
    }

    /**
     * @dev Retrieves all current data and a selection of common traits for a given Sentinel.
     * @param sentinelId The ID of the Sentinel.
     * @return A tuple containing Sentinel struct data, and arrays of common numeric trait names
     *         and their `uint256` values, and common string trait names and their `string` values.
     */
    function getSentinelInfo(uint256 sentinelId)
        public
        view
        returns (
            Sentinel memory,
            string[] memory numericTraitNames,
            uint256[] memory numericTraitValues,
            string[] memory stringTraitNames,
            string[] memory stringTraitValues
        )
    {
        require(_exists(sentinelId), "Sentinel does not exist");
        Sentinel storage s = sentinels[sentinelId];

        // Create a temporary Sentinel struct to return with calculated dynamic values
        Sentinel memory currentSentinel = s;
        currentSentinel.internalEssenceBalance = s.internalEssenceBalance + _calculatePendingEssence(sentinelId); // Add pending to reported balance
        currentSentinel.temporalAge = _updateTemporalAge(sentinelId);
        // Nexus Pool rewards calculation is separate for privacy and gas efficiency in _calculateNexusPoolRewards

        // For demonstration, we explicitly list a few expected traits.
        // A more robust system might store a dynamic list of trait keys within the Sentinel struct
        // or have a global registry of discoverable traits.
        numericTraitNames = new string[](4);
        numericTraitValues = new uint256[](4);
        stringTraitNames = new string[](1);
        stringTraitValues = new string[](1);

        numericTraitNames[0] = "tier";
        numericTraitValues[0] = sentinelNumericTraits[sentinelId]["tier"];
        numericTraitNames[1] = "power";
        numericTraitValues[1] = sentinelNumericTraits[sentinelId]["power"];
        numericTraitNames[2] = "defense";
        numericTraitValues[2] = sentinelNumericTraits[sentinelId]["defense"];
        numericTraitNames[3] = "cosmicAlignment";
        numericTraitValues[3] = sentinelNumericTraits[sentinelId]["cosmicAlignment"];

        stringTraitNames[0] = "origin";
        stringTraitValues[0] = sentinelStringTraits[sentinelId]["origin"];

        return (
            currentSentinel,
            numericTraitNames,
            numericTraitValues,
            stringTraitNames,
            stringTraitValues
        );
    }

    /**
     * @dev Returns the current sentience level of a Sentinel.
     * @param sentinelId The ID of the Sentinel.
     * @return The sentience level.
     */
    function getSentinelSentience(uint256 sentinelId) public view returns (uint256) {
        require(_exists(sentinelId), "Sentinel does not exist");
        return sentinels[sentinelId].sentienceLevel;
    }

    /**
     * @dev Queries the `uint256` value of a specific numeric trait for a Sentinel.
     * @param sentinelId The ID of the Sentinel.
     * @param traitName The name of the trait (e.g., "power", "tier").
     * @return The `uint256` value of the trait. Returns 0 if not found or not a numeric trait.
     */
    function getSentinelTraitValue(uint256 sentinelId, string memory traitName) public view returns (uint256) {
        require(_exists(sentinelId), "Sentinel does not exist");
        return sentinelNumericTraits[sentinelId][traitName];
    }

    /**
     * @dev Returns all known numeric trait names and their `uint256` values for a Sentinel.
     *      This is a simplified implementation listing a predefined set of traits.
     * @param sentinelId The ID of the Sentinel.
     * @return Arrays of trait names and their corresponding `uint256` values.
     */
    function getSentinelTraitValues(uint256 sentinelId) public view returns (string[] memory, uint256[] memory) {
        require(_exists(sentinelId), "Sentinel does not exist");
        // This is a simplified approach, listing known traits.
        // A more advanced system might store traits in a dynamic array within the Sentinel struct
        // or have a global list of possible traits to iterate.
        string[] memory traitNames = new string[](4);
        uint256[] memory traitValues = new uint256[](4);

        traitNames[0] = "tier";
        traitValues[0] = sentinelNumericTraits[sentinelId]["tier"];
        traitNames[1] = "power";
        traitValues[1] = sentinelNumericTraits[sentinelId]["power"];
        traitNames[2] = "defense";
        traitValues[2] = sentinelNumericTraits[sentinelId]["defense"];
        traitNames[3] = "cosmicAlignment";
        traitValues[3] = sentinelNumericTraits[sentinelId]["cosmicAlignment"];

        return (traitNames, traitValues);
    }

    /**
     * @dev Admin function to update the base URI for Sentinel metadata.
     * @param baseURI_ The new base URI.
     */
    function setBaseURI(string memory baseURI_) public onlyOwner {
        _setBaseURI(baseURI_);
    }

    // --- C. Admin & Protocol Management (Ownable/Pausable) ---

    /**
     * @dev Admin function to adjust the global base essence generation rate per hour.
     * @param newRate The new base rate (e.g., 1000 for 1 TES/hour, scaled 10^18).
     */
    function setEssenceGenerationRate(uint256 newRate) public onlyOwner {
        BASE_ESSENCE_GENERATION_RATE = newRate;
    }

    /**
     * @dev Admin function to set the Essence cost for specific trait refinements.
     * @param traitName The name of the trait (e.g., "power", "defense").
     * @param newCost The new Essence cost in scaled units (e.g., 10 * 10**18 for 10 TES).
     */
    function setRefinementCost(string memory traitName, uint256 newCost) public onlyOwner {
        refinementCosts[traitName] = newCost;
    }

    /**
     * @dev Admin function to define or update Chrono-Fusion recipes.
     * @param sentinelId1Tier The tier of the first Sentinel.
     * @param sentinelId2Tier The tier of the second Sentinel.
     * @param newSentinelTier The tier of the resulting fused Sentinel.
     * @param essenceCost The Essence cost for this fusion recipe (scaled).
     */
    function setFusionRecipe(uint256 sentinelId1Tier, uint256 sentinelId2Tier, uint256 newSentinelTier, uint256 essenceCost) public onlyOwner {
        // Ensure tiers are ordered to prevent duplicate entries (e.g., 1,2 and 2,1)
        if (sentinelId1Tier > sentinelId2Tier) {
            (sentinelId1Tier, sentinelId2Tier) = (sentinelId2Tier, sentinelId1Tier);
        }
        fusionRecipes[sentinelId1Tier][sentinelId2Tier] = FusionRecipe({
            newTier: newSentinelTier,
            essenceCost: essenceCost,
            exists: true
        });
    }

    /**
     * @dev Admin function to set the address of the external oracle contract (e.g., Chainlink).
     * @param _oracleAddress The address of the `IMockOracle` contract.
     */
    function setOracleAddress(address _oracleAddress) public onlyOwner {
        require(_oracleAddress != address(0), "Oracle address cannot be zero");
        oracle = IMockOracle(_oracleAddress);
    }

    /**
     * @dev Pauses core protocol functions. Only callable by owner.
     */
    function pause() public onlyOwner {
        _pause();
    }

    /**
     * @dev Unpauses core protocol functions. Only callable by owner.
     */
    function unpause() public onlyOwner {
        _unpause();
    }

    /**
     * @dev Allows the owner to withdraw any ERC-20 tokens held by the contract,
     *      useful for managing the Nexus Pool treasury or emergency recovery.
     *      Cannot withdraw `TemporalEssence` directly via this, as it's managed by protocol logic.
     * @param tokenAddress The address of the ERC-20 token to withdraw.
     * @param amount The amount of tokens to withdraw.
     */
    function withdrawTreasuryFunds(address tokenAddress, uint256 amount) public onlyOwner nonReentrant {
        require(tokenAddress != address(temporalEssence), "Cannot withdraw TemporalEssence directly via this function (managed by protocol)");
        IERC20 token = IERC20(tokenAddress);
        require(token.transfer(msg.sender, amount), "Failed to withdraw treasury funds");
    }

    /**
     * @dev Admin function to set the base reward rate for the Nexus Pool.
     * @param rate The new reward rate (e.g., 100 for 0.01% per hour. Scaled, 10000 = 1%).
     */
    function setNexusPoolRewardRate(uint256 rate) public onlyOwner {
        nexusPoolRewardRatePerEssencePerHour = rate;
    }

    /**
     * @dev Allows high-sentience Sentinels (or their owners) to propose governance actions.
     *      The `actionData` should be ABI-encoded function call for this contract or a target contract.
     * @param sentinelId The ID of the Sentinel proposing the action.
     * @param actionData The ABI-encoded call data for the proposed action.
     * @param proposalEndTime Timestamp when voting ends.
     */
    function proposeChronoGovernanceAction(uint256 sentinelId, bytes memory actionData, uint256 proposalEndTime)
        public
        whenNotPaused
        nonReentrant
    {
        require(ownerOf(sentinelId) == msg.sender, "Caller is not owner of Sentinel");
        require(sentinels[sentinelId].sentienceLevel >= MIN_SENTIENCE_FOR_PROPOSAL, "Sentinel sentience too low to propose");
        require(proposalEndTime > block.timestamp, "Proposal end time must be in the future");
        require(proposalEndTime <= block.timestamp + PROPOSAL_VOTING_PERIOD, "Proposal voting period too long");
        require(actionData.length > 0, "Action data cannot be empty");

        _proposalIds.increment();
        uint256 proposalId = _proposalIds.current();

        proposals[proposalId] = Proposal({
            proposalId: proposalId,
            actionData: actionData,
            proposerSentinelId: sentinelId,
            voteStartTime: block.timestamp,
            voteEndTime: proposalEndTime,
            yesVotes: 0,
            noVotes: 0,
            executed: false,
            hasVoted: new mapping(uint256 => bool) // Initialize mapping for votes
        });

        emit GovernanceProposalCreated(proposalId, sentinelId, proposalEndTime);
    }

    /**
     * @dev Allows Sentinels to vote on active governance proposals.
     *      Currently, 1 Sentinel = 1 Vote. Could be weighted by sentience in a more advanced system.
     * @param sentinelId The ID of the Sentinel casting the vote.
     * @param proposalId The ID of the proposal to vote on.
     * @param support True for "Yes", False for "No".
     */
    function voteOnChronoGovernanceProposal(uint256 sentinelId, uint256 proposalId, bool support)
        public
        whenNotPaused
        nonReentrant
    {
        require(ownerOf(sentinelId) == msg.sender, "Caller is not owner of Sentinel");
        Proposal storage proposal = proposals[proposalId];
        require(proposal.proposalId != 0, "Proposal does not exist"); // Check if proposal initialized
        require(block.timestamp >= proposal.voteStartTime && block.timestamp <= proposal.voteEndTime, "Voting is not active for this proposal");
        require(!proposal.hasVoted[sentinelId], "Sentinel has already voted on this proposal");

        proposal.hasVoted[sentinelId] = true;
        if (support) {
            proposal.yesVotes += 1;
        } else {
            proposal.noVotes += 1;
        }

        emit GovernanceVoteCast(proposalId, sentinelId, support);
    }

    /**
     * @dev Executes a governance proposal if the voting period has ended and it passed by simple majority.
     *      The `actionData` within the proposal is executed as an internal call.
     * @param proposalId The ID of the proposal to execute.
     */
    function executeChronoGovernanceProposal(uint256 proposalId) public nonReentrant {
        Proposal storage proposal = proposals[proposalId];
        require(proposal.proposalId != 0, "Proposal does not exist");
        require(block.timestamp > proposal.voteEndTime, "Voting period has not ended");
        require(!proposal.executed, "Proposal already executed");
        require(proposal.yesVotes > proposal.noVotes, "Proposal did not pass (no simple majority)");

        proposal.executed = true;
        bool success = false;
        // The `actionData` should be intended for `this` contract or a specific target.
        // For simplicity, it calls a function on `this` contract.
        // A more advanced governance system would include a `targetAddress` in the Proposal struct.
        (success,) = address(this).call(proposal.actionData);
        require(success, "Execution of proposal failed");

        emit GovernanceProposalExecuted(proposalId, success);
    }

    // fallback and receive functions for Ether, if needed (not explicitly required by prompt)
    receive() external payable {}
    fallback() external payable {}
}


// --- Mock Oracle Contract for Testing ---
contract MockOracle is Ownable {
    uint256 public cosmicAlignmentValue;

    constructor() Ownable(msg.sender) {
        cosmicAlignmentValue = 100; // Default value
    }

    function setCosmicAlignment(uint256 _newValue) public onlyOwner {
        cosmicAlignmentValue = _newValue;
    }

    function getCosmicAlignment() external view returns (uint256) {
        return cosmicAlignmentValue;
    }
}
```