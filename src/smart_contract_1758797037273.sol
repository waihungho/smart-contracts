Okay, this is an exciting challenge! I'll design a smart contract called "Aethelgard" (meaning "noble enclosure" or "noble protection" in Old English) that aims to be a self-optimizing, adaptive, and reputation-driven protocol. It blends dynamic NFTs, gamified DeFi, and a novel approach to decentralized governance and resource allocation.

The core idea is a living ecosystem where unique, evolving digital entities called "CognitoShards" represent a participant's on-chain reputation and influence. These shards are dynamic, responding to user activity, external oracle data, and community governance. The system itself adapts its parameters over time through epoch-based adjustments decided by governance and informed by system metrics.

---

## Aethelgard Protocol: Dynamic Genesis Engine

### Outline

1.  **Core Contracts & Interfaces:**
    *   `IAETH` (ERC-20 token for utility and governance).
    *   `Aethelgard` (Main protocol contract, ERC-721 for CognitoShards).
    *   `ICogitoOracle` (Interface for a custom oracle feeding data into Aethelgard).

2.  **Key Concepts:**
    *   **CognitoShards (ERC-721):** Dynamic NFTs representing on-chain reputation and influence. They have mutable attributes (Affinities, Experience Points) that evolve, decay, merge, and can be forged.
    *   **AETH Token (ERC-20):** Utility token for staking, minting Shards, participating in Trials, and governance.
    *   **Epochs:** The protocol operates in discrete epochs. Key parameters (e.g., shard decay rate, trial difficulty) can be adjusted per epoch by governance.
    *   **Affinities:** Core attributes of a CognitoShard (e.g., Wisdom, Resilience, Activity) that determine its influence and eligibility for certain actions.
    *   **Experience Points (SEP):** Earned through staking, contributions, and Trials. Used for forging/merging Shards and boosting Affinities.
    *   **Trials:** Gamified, on-chain challenges that require specific Shard Affinities or AETH stakes, rewarding participants with SEP and AETH.
    *   **Dynamic Governance:** AETH and high-tier Shard holders propose and vote on parameter changes and protocol upgrades.
    *   **External Oracle Integration:** Feeds dynamic, external data (e.g., "global sentiment," "market volatility") to influence Shard evolution or Trial conditions.

### Function Summary

**I. Core System Management & Setup (5 functions)**
1.  `constructor`: Initializes core contract settings, token addresses, and initial epoch parameters.
2.  `updateCoreAddress`: Allows governance to update addresses of critical external components (e.g., `IAETH`, `ICogitoOracle`).
3.  `pauseProtocol`: Pauses sensitive protocol operations (e.g., minting, staking, trials) in emergencies.
4.  `unpauseProtocol`: Unpauses protocol operations.
5.  `advanceEpoch`: Initiates a new protocol epoch, applying new parameters.

**II. AETH Token Interaction & Staking (4 functions)**
6.  `stakeAETH`: Allows users to stake AETH tokens, earning SEP and AETH rewards over time.
7.  `unstakeAETH`: Allows users to unstake AETH and claim accumulated rewards.
8.  `claimStakingRewards`: Claims only AETH staking rewards without unstaking.
9.  `distributeAETHToStakers`: Governance or automated function to top up the AETH reward pool for stakers.

**III. CognitoShard (ERC-721) Lifecycle & Evolution (9 functions)**
10. `mintCognitoShard`: Mints a new foundational CognitoShard for AETH, initializing its Affinities.
11. `evolveShardAffinities`: (Internal/Triggered) Updates a Shard's attributes based on activity, time, and oracle data.
12. `forgeShard`: Creates a higher-tier Shard by consuming AETH and SEP, potentially modifying Affinities.
13. `mergeShards`: Combines two existing CognitoShards, burning one and enhancing the other with combined SEP/Affinities.
14. `attestContribution`: Registers a user's on-chain contribution (e.g., governance vote, trial completion) for SEP.
15. `decayShardInfluence`: (Internal/Triggered) Periodically reduces a Shard's passive SEP/Affinities if inactive.
16. `getShardAttributes`: Public view function to get a Shard's current dynamic attributes.
17. `getShardInfluenceScore`: Calculates a dynamic influence score for a Shard based on its Affinities and SEP.
18. `tokenURI`: Overrides ERC721 `tokenURI` to return dynamic metadata reflecting Shard evolution.

**IV. Trials & Gamified Interactions (3 functions)**
19. `createTrial`: Governance creates a new on-chain challenge (Trial) with specific requirements and rewards.
20. `participateInTrial`: Allows users with eligible Shards and/or AETH to join an active Trial.
21. `completeTrial`: (Callback/Verifier) Marks a Trial as completed for a participant, distributing rewards and SEP.

**V. Oracle & External Data Integration (2 functions)**
22. `updateOracleData`: (Callback from `ICogitoOracle`) Receives and processes external, dynamic data (e.g., "global sentiment").
23. `getLatestOracleData`: Public view function to retrieve the last updated external data point.

**VI. Governance & Adaptive Parameters (4 functions)**
24. `proposeParameterChange`: Allows eligible users to propose changes to protocol parameters for the next epoch.
25. `voteOnProposal`: Allows AETH and Shard holders to vote on active proposals.
26. `executeParameterChange`: Executes an approved proposal, applying the changes to the next epoch's parameters.
27. `getEpochParameters`: Retrieves the current epoch's active parameters.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

// --- Interfaces ---

interface IAETH is IERC20 {
    function mint(address to, uint256 amount) external;
    function burn(uint256 amount) external;
}

// Minimal interface for an external oracle that pushes data to Aethelgard
interface ICogitoOracle {
    function getLatestData() external view returns (uint256);
    // Potentially add more complex functions like requestData, fulfillData, etc.
    // For this example, we'll assume it just pushes updates via `updateOracleData`
}

// --- Main Aethelgard Contract ---

contract Aethelgard is ERC721, Ownable, Pausable {
    using Counters for Counters.Counter;
    using Strings for uint256;

    // --- State Variables ---

    IAETH public aethToken; // The utility and governance token
    ICogitoOracle public cogitoOracle; // External oracle for dynamic data

    Counters.Counter private _shardTokenIds;
    Counters.Counter private _proposalIds;
    Counters.Counter private _trialIds;

    // --- CognitoShard Data Structure ---
    struct CognitoShard {
        uint256 lastEvolvedTimestamp; // Last time attributes were adjusted
        uint256 experiencePoints;     // SEP (Shard Experience Points)
        uint256 affinityWisdom;       // Affects governance weight, trial success chance
        uint256 affinityResilience;   // Affects decay resistance, trial reward multiplier
        uint256 affinityActivity;     // Affects SEP gain, eligibility for active trials
        uint256 contributionCount;    // Number of recorded contributions
        string shardType;             // e.g., "Seed", "Vanguard", "Luminary"
        uint255 metadataHash;         // A hash of current attributes for dynamic metadata proof
    }
    mapping(uint256 => CognitoShard) public cognitoShards;

    // --- Staking Data Structures ---
    struct StakerInfo {
        uint256 stakedAmount;
        uint256 rewardsClaimed;
        uint256 lastInteractionTime; // Timestamp of last stake/unstake/claim
        uint256 initialStakeTime;
    }
    mapping(address => StakerInfo) public stakers;
    uint256 public totalStakedAETH;
    uint256 public rewardsPerTokenStored; // For efficient reward calculation (like Compound's accounting)
    uint256 public lastRewardUpdateTimestamp; // Last time rewardsPerTokenStored was updated
    uint256 public constant REWARD_RATE_PER_SECOND = 100; // Example: 100 wei AETH per second per 1 AETH staked (very high for example)

    // --- Epoch & Parameters ---
    struct EpochParameters {
        uint256 epochDuration;          // How long an epoch lasts
        uint256 shardDecayRatePercent;  // % decay per epoch for inactive shards
        uint256 sepPerAETHStaked;       // SEP earned per AETH staked per epoch
        uint256 minAETHForMint;         // Cost to mint a new shard
        uint256 trialDifficultyMultiplier; // Multiplier for trial requirements/rewards
    }
    uint256 public currentEpoch = 0;
    uint256 public epochStartTime;
    mapping(uint256 => EpochParameters) public epochParams; // Parameters for each epoch
    EpochParameters public nextEpochParams; // Proposed parameters for the next epoch

    // --- Governance Data Structures ---
    enum ProposalState { Pending, Active, Succeeded, Failed, Executed }
    struct Proposal {
        uint256 id;
        address proposer;
        string description;
        bytes callData;       // Encoded function call for execution
        address target;       // Contract target for the callData
        uint256 voteStartTime;
        uint256 voteEndTime;
        uint256 votesFor;
        uint256 votesAgainst;
        mapping(address => bool) hasVoted; // Prevents double voting
        ProposalState state;
        bool executed;
    }
    mapping(uint256 => Proposal) public proposals;
    uint256 public proposalVoteDuration = 7 days; // How long a vote lasts
    uint256 public minAETHToPropose = 10_000 ether; // Example: 10,000 AETH
    uint256 public minShardInfluenceToPropose = 1000; // Min influence score to propose

    // --- Trials Data Structures ---
    enum TrialStatus { Pending, Active, Completed, Cancelled }
    struct Trial {
        uint256 id;
        string name;
        string description;
        uint256 rewardPoolAETH;      // AETH rewards for participants
        uint256 rewardPoolSEP;       // SEP rewards
        uint256 requiredWisdom;      // Min wisdom affinity to participate
        uint256 requiredResilience;  // Min resilience affinity
        uint256 requiredActivity;    // Min activity affinity
        uint256 requiredAETHStake;   // Optional AETH stake to participate
        uint256 maxParticipants;
        mapping(address => bool) participants; // Addresses that joined
        uint256 participantCount;
        TrialStatus status;
    }
    mapping(uint256 => Trial) public trials;

    // --- Oracle Data ---
    uint256 public latestOracleData; // Placeholder for data pushed by the oracle
    uint256 public lastOracleUpdateTimestamp;

    // --- Events ---
    event ShardMinted(address indexed owner, uint256 indexed tokenId, string shardType);
    event ShardEvolved(uint256 indexed tokenId, uint256 oldWisdom, uint256 newWisdom, uint256 oldResilience, uint256 newResilience, uint256 oldActivity, uint256 newActivity, uint256 newSEP);
    event ShardForged(uint256 indexed oldTokenId, uint256 indexed newTokenId, string newShardType);
    event ShardMerged(uint256 indexed primaryTokenId, uint256 indexed mergedTokenId, address indexed merger, string newShardType);
    event ContributionAttested(address indexed contributor, uint256 indexed shardTokenId, uint256 sepAwarded);

    event AETHStaked(address indexed staker, uint256 amount);
    event AETHUnstaked(address indexed staker, uint256 amount);
    event RewardsClaimed(address indexed staker, uint256 aethAmount, uint256 sepAmount);

    event EpochAdvanced(uint256 indexed newEpoch, uint256 newEpochStartTime);
    event ProtocolPaused(address indexed by);
    event ProtocolUnpaused(address indexed by);

    event ProposalCreated(uint256 indexed proposalId, address indexed proposer, string description);
    event VoteCast(uint256 indexed proposalId, address indexed voter, bool support);
    event ProposalExecuted(uint256 indexed proposalId);
    event ParameterChangeProposed(uint256 indexed proposalId, bytes callData, address target);

    event TrialCreated(uint256 indexed trialId, string name, uint256 rewardAETH, uint256 rewardSEP);
    event TrialParticipated(uint256 indexed trialId, address indexed participant, uint256 shardTokenId);
    event TrialCompleted(uint256 indexed trialId, address indexed participant, uint256 shardTokenId, uint256 aethReward, uint256 sepReward);

    event OracleDataUpdated(uint256 indexed data, uint256 timestamp);

    // --- Modifiers ---
    modifier onlyGovernance() {
        // For a full DAO, this would check against a governance contract's proposal outcome.
        // For this example, we'll allow the owner to represent governance.
        // In a real scenario, this would be `require(msg.sender == governanceContractAddress, "Not governance");`
        require(msg.sender == owner(), "Aethelgard: Caller is not governance");
        _;
    }

    modifier onlyOracle() {
        // Only the configured oracle contract can call this
        require(msg.sender == address(cogitoOracle), "Aethelgard: Caller is not the CogitoOracle");
        _;
    }

    // --- Constructor ---
    constructor(address _aethTokenAddress, address _cogitoOracleAddress)
        ERC721("Aethelgard CognitoShard", "CGS")
        Ownable(msg.sender) // Owner acts as initial governance
        Pausable()
    {
        require(_aethTokenAddress != address(0), "Aethelgard: AETH token address cannot be zero");
        require(_cogitoOracleAddress != address(0), "Aethelgard: Cogito Oracle address cannot be zero");
        aethToken = IAETH(_aethTokenAddress);
        cogitoOracle = ICogitoOracle(_cogitoOracleAddress);

        // Set initial epoch parameters for epoch 0
        epochParams[0] = EpochParameters({
            epochDuration: 7 days,
            shardDecayRatePercent: 5, // 5% decay per epoch if inactive
            sepPerAETHStaked: 100, // 100 SEP per AETH staked per epoch
            minAETHForMint: 100 ether,
            trialDifficultyMultiplier: 1
        });
        nextEpochParams = epochParams[0]; // Initialize next with current
        epochStartTime = block.timestamp;
        lastRewardUpdateTimestamp = block.timestamp;
    }

    // --- I. Core System Management & Setup ---

    /// @notice Allows governance to update addresses of critical external components.
    /// @param _aethToken New AETH token address.
    /// @param _cogitoOracle New Cogito Oracle address.
    function updateCoreAddress(address _aethToken, address _cogitoOracle) external onlyGovernance {
        require(_aethToken != address(0) && _cogitoOracle != address(0), "Aethelgard: Addresses cannot be zero");
        aethToken = IAETH(_aethToken);
        cogitoOracle = ICogitoOracle(_cogitoOracle);
    }

    /// @notice Pauses sensitive protocol operations in emergencies.
    /// @dev Can only be called by governance.
    function pauseProtocol() external onlyGovernance whenNotPaused {
        _pause();
        emit ProtocolPaused(msg.sender);
    }

    /// @notice Unpauses protocol operations.
    /// @dev Can only be called by governance.
    function unpauseProtocol() external onlyGovernance whenPaused {
        _unpause();
        emit ProtocolUnpaused(msg.sender);
    }

    /// @notice Initiates a new protocol epoch, applying new parameters.
    /// @dev Only callable by governance after current epoch duration.
    function advanceEpoch() external onlyGovernance {
        require(block.timestamp >= epochStartTime + epochParams[currentEpoch].epochDuration, "Aethelgard: Current epoch has not ended yet");

        currentEpoch++;
        epochParams[currentEpoch] = nextEpochParams; // Apply proposed params
        epochStartTime = block.timestamp;

        // Reset nextEpochParams to current for new proposals
        nextEpochParams = epochParams[currentEpoch];

        emit EpochAdvanced(currentEpoch, epochStartTime);
    }

    // --- II. AETH Token Interaction & Staking ---

    /// @dev Internal function to update rewards per token.
    function _updateRewardPerToken() internal {
        if (totalStakedAETH == 0) {
            lastRewardUpdateTimestamp = block.timestamp;
            return;
        }
        uint256 timeElapsed = block.timestamp - lastRewardUpdateTimestamp;
        rewardsPerTokenStored += (timeElapsed * REWARD_RATE_PER_SECOND * 1e18) / totalStakedAETH; // rewardsPerTokenStored is scaled
        lastRewardUpdateTimestamp = block.timestamp;
    }

    /// @notice Calculates pending AETH rewards for a staker.
    function _pendingAETHRewards(address _staker) internal view returns (uint256) {
        StakerInfo storage info = stakers[_staker];
        if (info.stakedAmount == 0) return 0;

        uint256 currentRewardsPerToken = rewardsPerTokenStored;
        if (totalStakedAETH > 0) { // If there's stake, calculate up to now
             uint256 timeElapsed = block.timestamp - lastRewardUpdateTimestamp;
             currentRewardsPerToken += (timeElapsed * REWARD_RATE_PER_SECOND * 1e18) / totalStakedAETH;
        }

        uint256 earned = (info.stakedAmount * currentRewardsPerToken) / 1e18; // Descale
        return earned - info.rewardsClaimed;
    }

    /// @notice Calculates pending SEP rewards for a staker.
    function _pendingSEPRewards(address _staker) internal view returns (uint256) {
        StakerInfo storage info = stakers[_staker];
        if (info.stakedAmount == 0) return 0;
        uint256 epochsPassedSinceStake = (block.timestamp - info.initialStakeTime) / epochParams[currentEpoch].epochDuration;
        return info.stakedAmount * epochParams[currentEpoch].sepPerAETHStaked * epochsPassedSinceStake; // Simplified SEP gain
    }

    /// @notice Stakes AETH tokens to earn rewards and SEP.
    /// @param _amount The amount of AETH to stake.
    function stakeAETH(uint256 _amount) external whenNotPaused {
        require(_amount > 0, "Aethelgard: Amount must be greater than zero");
        
        _updateRewardPerToken(); // Update global reward state
        
        StakerInfo storage info = stakers[msg.sender];
        if (info.stakedAmount > 0) {
            // Claim existing rewards before adding new stake to avoid complex re-calculation
            uint256 pendingAETH = _pendingAETHRewards(msg.sender);
            uint256 pendingSEP = _pendingSEPRewards(msg.sender);
            if (pendingAETH > 0 || pendingSEP > 0) {
                // Transfer AETH rewards and update SEP for Shards
                aethToken.transfer(msg.sender, pendingAETH);
                // For SEP, we'd need to have a way to associate it with a Shard
                // For now, assume it's just tracked for the user, or requires a `claimSEPToShard` func.
                // Simplified: SEP is just credited to the staker, can be used for forging/merging
                // A better design would be to let user assign SEP to a specific Shard
            }
            info.rewardsClaimed += pendingAETH; // Mark as claimed
            info.lastInteractionTime = block.timestamp;
        } else {
            info.initialStakeTime = block.timestamp;
        }

        aethToken.transferFrom(msg.sender, address(this), _amount);
        info.stakedAmount += _amount;
        totalStakedAETH += _amount;
        emit AETHStaked(msg.sender, _amount);
    }

    /// @notice Unstakes AETH tokens and claims accumulated rewards (AETH & SEP).
    /// @param _amount The amount of AETH to unstake.
    function unstakeAETH(uint256 _amount) external whenNotPaused {
        StakerInfo storage info = stakers[msg.sender];
        require(info.stakedAmount >= _amount, "Aethelgard: Insufficient staked amount");
        require(_amount > 0, "Aethelgard: Amount must be greater than zero");

        _updateRewardPerToken(); // Update global reward state

        uint256 pendingAETH = _pendingAETHRewards(msg.sender);
        uint256 pendingSEP = _pendingSEPRewards(msg.sender);

        if (pendingAETH > 0) {
            aethToken.transfer(msg.sender, pendingAETH);
            info.rewardsClaimed += pendingAETH;
        }
        // SEP handling: Simplification for now, SEP is just credited.
        // In a complex system, SEP would be tied to a Shard.
        // For this example, let's just emit an event indicating SEP reward.
        if (pendingSEP > 0) {
            // Logic to apply SEP to a shard or directly to user's SEP balance
            // For now, we'll just track user's SEP. A Shard specific SEP will be separate
        }

        aethToken.transfer(msg.sender, _amount);
        info.stakedAmount -= _amount;
        totalStakedAETH -= _amount;
        info.lastInteractionTime = block.timestamp;

        emit AETHUnstaked(msg.sender, _amount);
        emit RewardsClaimed(msg.sender, pendingAETH, pendingSEP); // Consolidate reward claims
    }

    /// @notice Claims only AETH and SEP staking rewards without unstaking any AETH.
    function claimStakingRewards() external whenNotPaused {
        _updateRewardPerToken();

        StakerInfo storage info = stakers[msg.sender];
        require(info.stakedAmount > 0, "Aethelgard: No AETH staked");

        uint256 pendingAETH = _pendingAETHRewards(msg.sender);
        uint256 pendingSEP = _pendingSEPRewards(msg.sender);

        require(pendingAETH > 0 || pendingSEP > 0, "Aethelgard: No rewards to claim");

        if (pendingAETH > 0) {
            aethToken.transfer(msg.sender, pendingAETH);
            info.rewardsClaimed += pendingAETH;
        }
        // SEP: Similar to unstake, SEP is credited
        info.lastInteractionTime = block.timestamp;

        emit RewardsClaimed(msg.sender, pendingAETH, pendingSEP);
    }

    /// @notice Allows governance to distribute AETH into the staking reward pool.
    /// @dev This function assumes AETH tokens are first sent to the contract.
    /// @param _amount The amount of AETH to add to the reward pool.
    function distributeAETHToStakers(uint256 _amount) external onlyGovernance {
        aethToken.transferFrom(msg.sender, address(this), _amount); // Governance sends AETH to contract
        _updateRewardPerToken(); // Update before new AETH is added
        // The `rewardsPerTokenStored` mechanism handles distribution
        // No explicit `add` needed, just ensures the pool has enough.
    }

    // --- III. CognitoShard (ERC-721) Lifecycle & Evolution ---

    /// @notice Mints a new foundational CognitoShard for AETH.
    /// @dev Requires AETH payment. Initial affinities are randomized or base values.
    /// @param _initialShardType The type of shard to mint (e.g., "Seed").
    function mintCognitoShard(string memory _initialShardType) external payable whenNotPaused {
        require(msg.value >= epochParams[currentEpoch].minAETHForMint, "Aethelgard: Insufficient AETH sent for minting");
        // For now, assume payment directly in native currency or use aethToken.transferFrom(msg.sender, address(this), epochParams[currentEpoch].minAETHForMint);

        _shardTokenIds.increment();
        uint256 newItemId = _shardTokenIds.current();

        // Transfer native currency payment to owner
        (bool success,) = owner().call{value: msg.value}("");
        require(success, "Aethelgard: Failed to transfer minting fee");

        cognitoShards[newItemId] = CognitoShard({
            lastEvolvedTimestamp: block.timestamp,
            experiencePoints: 0,
            affinityWisdom: 50, // Base values
            affinityResilience: 50,
            affinityActivity: 50,
            contributionCount: 0,
            shardType: _initialShardType,
            metadataHash: 0 // Will be updated on evolution
        });

        _safeMint(msg.sender, newItemId);
        _evolveShardState(newItemId); // Apply initial evolution based on current epoch/oracle data
        emit ShardMinted(msg.sender, newItemId, _initialShardType);
    }

    /// @notice Internal function to update a Shard's state and attributes.
    /// @dev Called periodically, after contributions, or when external data changes.
    ///      This is the core "dynamic" aspect.
    function _evolveShardState(uint256 _tokenId) internal {
        CognitoShard storage shard = cognitoShards[_tokenId];
        require(_exists(_tokenId), "Aethelgard: Shard does not exist");

        uint256 timeSinceLastEvolution = block.timestamp - shard.lastEvolvedTimestamp;
        uint256 epochsPassed = timeSinceLastEvolution / epochParams[currentEpoch].epochDuration;

        // Apply decay if inactive (simplified: based on last evolution)
        if (epochsPassed > 0) {
            uint256 decayAmount = (shard.experiencePoints * epochParams[currentEpoch].shardDecayRatePercent * epochsPassed) / 100;
            if (shard.experiencePoints > decayAmount) {
                shard.experiencePoints -= decayAmount;
            } else {
                shard.experiencePoints = 0;
            }
            // Decay affinities too, but with a floor
            shard.affinityWisdom = _decayValue(shard.affinityWisdom, epochParams[currentEpoch].shardDecayRatePercent, epochsPassed, 10);
            shard.affinityResilience = _decayValue(shard.affinityResilience, epochParams[currentEpoch].shardDecayRatePercent, epochsPassed, 10);
            shard.affinityActivity = _decayValue(shard.affinityActivity, epochParams[currentEpoch].shardDecayRatePercent, epochsPassed, 10);
        }

        // Influence from external oracle data (e.g., "global sentiment")
        // Example: If oracle data > threshold, boost Resilience, else boost Wisdom
        if (latestOracleData > 500 && shard.affinityResilience < 200) { // Max 200 affinity
            shard.affinityResilience += (latestOracleData / 100); // Small boost
        } else if (latestOracleData <= 500 && shard.affinityWisdom < 200) {
            shard.affinityWisdom += (1000 - latestOracleData) / 100; // Small boost
        }

        // Apply SEP to affinities (simplified: auto-apply to lowest affinity)
        uint256 sepToApply = shard.experiencePoints / 10; // 10% of SEP can be converted
        if (sepToApply > 0) {
            if (shard.affinityWisdom <= shard.affinityResilience && shard.affinityWisdom <= shard.affinityActivity) {
                shard.affinityWisdom += sepToApply;
            } else if (shard.affinityResilience <= shard.affinityActivity) {
                shard.affinityResilience += sepToApply;
            } else {
                shard.affinityActivity += sepToApply;
            }
            shard.experiencePoints -= sepToApply * 10; // Use up SEP
        }

        // Ensure affinities don't exceed a cap (e.g., 250)
        shard.affinityWisdom = _min(shard.affinityWisdom, 250);
        shard.affinityResilience = _min(shard.affinityResilience, 250);
        shard.affinityActivity = _min(shard.affinityActivity, 250);

        // Update metadata hash based on current attributes
        shard.metadataHash = uint255(keccak256(abi.encodePacked(
            shard.experiencePoints,
            shard.affinityWisdom,
            shard.affinityResilience,
            shard.affinityActivity,
            shard.shardType,
            latestOracleData // Incorporate oracle data into metadata hash
        )));

        shard.lastEvolvedTimestamp = block.timestamp;
        emit ShardEvolved(_tokenId, 0, shard.affinityWisdom, 0, shard.affinityResilience, 0, shard.affinityActivity, shard.experiencePoints);
    }

    /// @dev Helper for decay, ensuring a minimum floor.
    function _decayValue(uint256 value, uint256 decayRatePercent, uint256 epochs, uint256 floor) internal pure returns (uint256) {
        uint256 decayAmount = (value * decayRatePercent * epochs) / 100;
        if (value > decayAmount && (value - decayAmount) > floor) {
            return value - decayAmount;
        }
        return floor;
    }

    /// @dev Helper for min value.
    function _min(uint224 a, uint224 b) internal pure returns (uint224) {
        return a < b ? a : b;
    }

    /// @notice Allows a user to create a higher-tier Shard by consuming AETH and SEP.
    /// @dev This burns the old Shard and mints a new one with enhanced attributes.
    /// @param _oldTokenId The ID of the Shard to be forged.
    /// @param _newShardType The desired new type for the forged Shard (e.g., "Vanguard").
    function forgeShard(uint256 _oldTokenId, string memory _newShardType) external whenNotPaused {
        require(ownerOf(_oldTokenId) == msg.sender, "Aethelgard: Not owner of Shard");
        _evolveShardState(_oldTokenId); // Ensure state is up-to-date

        CognitoShard storage oldShard = cognitoShards[_oldTokenId];
        require(oldShard.experiencePoints >= 5000, "Aethelgard: Not enough SEP to forge (min 5000)"); // Example cost
        require(oldShard.affinityWisdom + oldShard.affinityResilience + oldShard.affinityActivity >= 200, "Aethelgard: Shard affinities too low to forge"); // Example requirement

        // Burn SEP and AETH (example cost)
        oldShard.experiencePoints -= 5000;
        // Assume AETH cost is transferred by user before calling this function
        // aethToken.transferFrom(msg.sender, address(this), 100 ether); // Example AETH cost

        _burn(_oldTokenId);
        delete cognitoShards[_oldTokenId];

        _shardTokenIds.increment();
        uint256 newItemId = _shardTokenIds.current();

        // New shard gets boosted attributes
        cognitoShards[newItemId] = CognitoShard({
            lastEvolvedTimestamp: block.timestamp,
            experiencePoints: oldShard.experiencePoints + 1000, // Retain some SEP, add bonus
            affinityWisdom: oldShard.affinityWisdom + 20,
            affinityResilience: oldShard.affinityResilience + 20,
            affinityActivity: oldShard.affinityActivity + 20,
            contributionCount: oldShard.contributionCount,
            shardType: _newShardType,
            metadataHash: 0
        });

        _safeMint(msg.sender, newItemId);
        _evolveShardState(newItemId); // Apply initial evolution for the new shard
        emit ShardForged(_oldTokenId, newItemId, _newShardType);
    }

    /// @notice Combines two existing CognitoShards, burning one and enhancing the other.
    /// @param _primaryTokenId The Shard that will be enhanced and remain.
    /// @param _secondaryTokenId The Shard that will be consumed (burned).
    function mergeShards(uint256 _primaryTokenId, uint256 _secondaryTokenId) external whenNotPaused {
        require(ownerOf(_primaryTokenId) == msg.sender, "Aethelgard: Not owner of primary Shard");
        require(ownerOf(_secondaryTokenId) == msg.sender, "Aethelgard: Not owner of secondary Shard");
        require(_primaryTokenId != _secondaryTokenId, "Aethelgard: Cannot merge a Shard with itself");

        _evolveShardState(_primaryTokenId);
        _evolveShardState(_secondaryTokenId);

        CognitoShard storage primaryShard = cognitoShards[_primaryTokenId];
        CognitoShard storage secondaryShard = cognitoShards[_secondaryTokenId];

        // Merge logic: Primary shard gains SEP and averaged/boosted affinities
        primaryShard.experiencePoints += (secondaryShard.experiencePoints / 2); // Transfer 50% SEP
        primaryShard.affinityWisdom = (primaryShard.affinityWisdom + secondaryShard.affinityWisdom) / 2 + 5; // Averaged + small boost
        primaryShard.affinityResilience = (primaryShard.affinityResilience + secondaryShard.affinityResilience) / 2 + 5;
        primaryShard.affinityActivity = (primaryShard.affinityActivity + secondaryShard.affinityActivity) / 2 + 5;
        primaryShard.contributionCount += secondaryShard.contributionCount;

        // Update shardType logic (e.g., if secondary is rare, primary might gain a suffix)
        if (keccak256(abi.encodePacked(secondaryShard.shardType)) == keccak256(abi.encodePacked("Rare"))) {
            primaryShard.shardType = string(abi.encodePacked(primaryShard.shardType, "-Infused"));
        } else {
            primaryShard.shardType = string(abi.encodePacked(primaryShard.shardType, "-Merged"));
        }

        _burn(_secondaryTokenId);
        delete cognitoShards[_secondaryTokenId];
        _evolveShardState(_primaryTokenId); // Re-evolve primary after merge
        emit ShardMerged(_primaryTokenId, _secondaryTokenId, msg.sender, primaryShard.shardType);
    }

    /// @notice Registers a user's on-chain contribution, awarding SEP to a specified Shard.
    /// @dev Example: After a governance vote, or a complex external task verified by an oracle.
    /// @param _shardTokenId The Shard to which SEP should be credited.
    /// @param _contributionDetails A hash or string describing the contribution.
    function attestContribution(uint256 _shardTokenId, string memory _contributionDetails) external whenNotPaused {
        require(ownerOf(_shardTokenId) == msg.sender, "Aethelgard: Not owner of Shard");
        _evolveShardState(_shardTokenId); // Ensure state is up-to-date

        CognitoShard storage shard = cognitoShards[_shardTokenId];
        uint256 sepAwarded = 100 + (uint256(keccak256(abi.encodePacked(_contributionDetails))) % 200); // Base + random SEP
        shard.experiencePoints += sepAwarded;
        shard.contributionCount++;
        shard.affinityActivity += 5; // Small boost to activity for contributing

        _evolveShardState(_shardTokenId); // Re-evolve after contribution
        emit ContributionAttested(msg.sender, _shardTokenId, sepAwarded);
    }

    /// @notice Internal function to periodically reduce a Shard's passive SEP/Affinities if inactive.
    /// @dev This is handled by `_evolveShardState` when it's called. This function simply makes sure it runs.
    ///      Could be called by a keeper network or as part of other user interactions.
    /// @param _tokenId The ID of the Shard to decay.
    function decayShardInfluence(uint256 _tokenId) external whenNotPaused {
        // Anyone can trigger decay for any shard to ensure system health
        // Could be incentivized in a real system
        _evolveShardState(_tokenId);
    }

    /// @notice Public view function to get a Shard's current dynamic attributes.
    /// @param _tokenId The ID of the Shard.
    /// @return experiencePoints, affinityWisdom, affinityResilience, affinityActivity, shardType, contributionCount
    function getShardAttributes(uint256 _tokenId) public view returns (uint256, uint256, uint256, uint256, string memory, uint256) {
        CognitoShard storage shard = cognitoShards[_tokenId];
        return (
            shard.experiencePoints,
            shard.affinityWisdom,
            shard.affinityResilience,
            shard.affinityActivity,
            shard.shardType,
            shard.contributionCount
        );
    }

    /// @notice Calculates a dynamic influence score for a Shard.
    /// @dev This score can be used for governance weight, trial eligibility, etc.
    /// @param _tokenId The ID of the Shard.
    /// @return influenceScore The calculated influence score.
    function getShardInfluenceScore(uint256 _tokenId) public view returns (uint256 influenceScore) {
        CognitoShard storage shard = cognitoShards[_tokenId];
        influenceScore = shard.experiencePoints / 100 // SEP contributes
            + shard.affinityWisdom * 2 // Wisdom contributes more
            + shard.affinityResilience * 1 // Resilience contributes
            + shard.affinityActivity * 1; // Activity contributes
        // Add a multiplier based on shardType for higher tiers
        if (keccak256(abi.encodePacked(shard.shardType)) == keccak256(abi.encodePacked("Luminary"))) {
            influenceScore *= 2;
        } else if (keccak256(abi.encodePacked(shard.shardType)) == keccak256(abi.encodePacked("Vanguard"))) {
            influenceScore *= 150; // 1.5x
            influenceScore /= 100;
        }
        return influenceScore;
    }

    /// @notice Overrides ERC721 `tokenURI` to return dynamic metadata reflecting Shard evolution.
    /// @dev This should point to an off-chain API that renders JSON metadata based on the Shard's current state.
    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        require(_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token");
        CognitoShard storage shard = cognitoShards[_tokenId];

        // A dynamic base URI that includes the metadata hash, ensuring unique URI per state
        // In a real dApp, the URI would be something like `https://api.aethelgard.xyz/shards/{_tokenId}/metadata/{shard.metadataHash}`
        // The off-chain server would then serve the JSON based on the latest state hash.
        return string(abi.encodePacked(
            "ipfs://aethelgard.io/shards/", _tokenId.toString(), "/", shard.metadataHash.toString()
        ));
    }


    // --- IV. Trials & Gamified Interactions ---

    /// @notice Governance creates a new on-chain challenge (Trial).
    /// @param _name Name of the trial.
    /// @param _description Description.
    /// @param _rewardAETH AETH to be rewarded.
    /// @param _rewardSEP SEP to be rewarded.
    /// @param _requiredWisdom Min wisdom to participate.
    /// @param _requiredResilience Min resilience to participate.
    /// @param _requiredActivity Min activity to participate.
    /// @param _requiredAETHStake Optional AETH stake to participate.
    /// @param _maxParticipants Max number of participants.
    function createTrial(
        string memory _name,
        string memory _description,
        uint256 _rewardAETH,
        uint256 _rewardSEP,
        uint256 _requiredWisdom,
        uint256 _requiredResilience,
        uint256 _requiredActivity,
        uint256 _requiredAETHStake,
        uint256 _maxParticipants
    ) external onlyGovernance whenNotPaused {
        _trialIds.increment();
        uint256 newTrialId = _trialIds.current();

        trials[newTrialId] = Trial({
            id: newTrialId,
            name: _name,
            description: _description,
            rewardPoolAETH: _rewardAETH,
            rewardPoolSEP: _rewardSEP,
            requiredWisdom: _requiredWisdom * epochParams[currentEpoch].trialDifficultyMultiplier,
            requiredResilience: _requiredResilience * epochParams[currentEpoch].trialDifficultyMultiplier,
            requiredActivity: _requiredActivity * epochParams[currentEpoch].trialDifficultyMultiplier,
            requiredAETHStake: _requiredAETHStake,
            maxParticipants: _maxParticipants,
            participants: mapping(address => bool)(), // Initialize empty map
            participantCount: 0,
            status: TrialStatus.Active
        });

        // Transfer AETH rewards from governance to contract for the trial pool
        aethToken.transferFrom(msg.sender, address(this), _rewardAETH);

        emit TrialCreated(newTrialId, _name, _rewardAETH, _rewardSEP);
    }

    /// @notice Allows users with eligible Shards and/or AETH to join an active Trial.
    /// @param _trialId The ID of the Trial to join.
    /// @param _shardTokenId The Shard used to participate (must be owned by msg.sender).
    function participateInTrial(uint256 _trialId, uint256 _shardTokenId) external payable whenNotPaused {
        Trial storage trial = trials[_trialId];
        require(trial.status == TrialStatus.Active, "Aethelgard: Trial is not active");
        require(trial.participantCount < trial.maxParticipants, "Aethelgard: Trial is full");
        require(ownerOf(_shardTokenId) == msg.sender, "Aethelgard: Not owner of Shard");
        require(!trial.participants[msg.sender], "Aethelgard: Already participated in this trial");

        _evolveShardState(_shardTokenId); // Ensure Shard is up-to-date
        CognitoShard storage shard = cognitoShards[_shardTokenId];

        // Check affinity requirements
        require(shard.affinityWisdom >= trial.requiredWisdom, "Aethelgard: Insufficient Wisdom affinity");
        require(shard.affinityResilience >= trial.requiredResilience, "Aethelgard: Insufficient Resilience affinity");
        require(shard.affinityActivity >= trial.requiredActivity, "Aethelgard: Insufficient Activity affinity");

        // Check AETH stake requirement
        if (trial.requiredAETHStake > 0) {
            require(msg.value >= trial.requiredAETHStake, "Aethelgard: Insufficient AETH stake for trial");
            // Transfer AETH stake to contract (held in escrow)
            // msg.value automatically sent, no explicit transferFrom needed if using payable.
        }

        trial.participants[msg.sender] = true;
        trial.participantCount++;
        emit TrialParticipated(_trialId, msg.sender, _shardTokenId);
    }

    /// @notice Marks a Trial as completed for a participant, distributing rewards and SEP.
    /// @dev This function would typically be called by an oracle or a verified off-chain system,
    ///      after validating the participant's completion of the trial challenge.
    /// @param _trialId The ID of the Trial.
    /// @param _participant The address of the participant who completed the trial.
    /// @param _shardTokenId The Shard used by the participant.
    function completeTrial(uint256 _trialId, address _participant, uint256 _shardTokenId) external onlyOracle whenNotPaused {
        Trial storage trial = trials[_trialId];
        require(trial.status == TrialStatus.Active, "Aethelgard: Trial is not active");
        require(trial.participants[_participant], "Aethelgard: Participant did not join this trial");
        require(ownerOf(_shardTokenId) == _participant, "Aethelgard: Shard not owned by participant");

        // Distribute AETH rewards
        aethToken.transfer(_participant, trial.rewardPoolAETH / trial.maxParticipants); // Simple even split

        // Distribute SEP rewards to the Shard
        _evolveShardState(_shardTokenId); // Ensure state is up-to-date
        CognitoShard storage shard = cognitoShards[_shardTokenId];
        shard.experiencePoints += trial.rewardPoolSEP / trial.maxParticipants;
        shard.affinityActivity += 10; // Boost activity for completing a trial
        _evolveShardState(_shardTokenId); // Re-evolve after reward

        // If AETH was staked, return it to the participant
        if (trial.requiredAETHStake > 0) {
            (bool success, ) = _participant.call{value: trial.requiredAETHStake}("");
            require(success, "Aethelgard: Failed to return trial stake");
        }

        emit TrialCompleted(_trialId, _participant, _shardTokenId, trial.rewardPoolAETH / trial.maxParticipants, trial.rewardPoolSEP / trial.maxParticipants);

        // Potentially close trial if max participants have completed or time limit reached
        // For simplicity, we just reward per completion.
    }


    // --- V. Oracle & External Data Integration ---

    /// @notice Callback function for the Cogito Oracle to push external, dynamic data.
    /// @dev Only callable by the configured `cogitoOracle` address.
    /// @param _data The latest uint256 data point from the oracle.
    function updateOracleData(uint256 _data) external onlyOracle {
        latestOracleData = _data;
        lastOracleUpdateTimestamp = block.timestamp;
        emit OracleDataUpdated(_data, block.timestamp);

        // Optionally, trigger evolution for a set of high-tier shards or all active shards here
        // For simplicity, individual shard evolution will pull this data when its `_evolveShardState` is called.
    }

    /// @notice Public view function to retrieve the last updated external data point.
    /// @return The latest uint256 data from the Cogito Oracle.
    function getLatestOracleData() public view returns (uint256) {
        return latestOracleData;
    }


    // --- VI. Governance & Adaptive Parameters ---

    /// @notice Allows eligible users to propose changes to protocol parameters for the next epoch.
    /// @param _description A brief description of the proposal.
    /// @param _target The target contract for the proposed change (this contract or another).
    /// @param _callData The encoded function call (e.g., `abi.encodeWithSelector(this.setNextEpochParameters.selector, ...)`)
    function proposeParameterChange(
        string memory _description,
        address _target,
        bytes memory _callData
    ) external whenNotPaused {
        require(_target != address(0), "Aethelgard: Target address cannot be zero");
        require(bytes(_description).length > 0, "Aethelgard: Description cannot be empty");

        // Eligibility: Min AETH stake OR min Shard influence
        uint256 userAETHBalance = aethToken.balanceOf(msg.sender);
        bool eligible = userAETHBalance >= minAETHToPropose;

        // Check for Shard influence if user doesn't have enough AETH
        if (!eligible) {
            uint256 totalInfluence = 0;
            uint256 balance = balanceOf(msg.sender);
            for (uint256 i = 0; i < balance; i++) {
                uint256 tokenId = tokenOfOwnerByIndex(msg.sender, i);
                totalInfluence += getShardInfluenceScore(tokenId);
            }
            eligible = totalInfluence >= minShardInfluenceToPropose;
        }
        require(eligible, "Aethelgard: Insufficient AETH or Shard influence to propose");

        _proposalIds.increment();
        uint256 newProposalId = _proposalIds.current();

        proposals[newProposalId] = Proposal({
            id: newProposalId,
            proposer: msg.sender,
            description: _description,
            callData: _callData,
            target: _target,
            voteStartTime: block.timestamp,
            voteEndTime: block.timestamp + proposalVoteDuration,
            votesFor: 0,
            votesAgainst: 0,
            hasVoted: mapping(address => bool)(),
            state: ProposalState.Active,
            executed: false
        });

        emit ProposalCreated(newProposalId, msg.sender, _description);
        emit ParameterChangeProposed(newProposalId, _callData, _target);
    }

    /// @notice Allows AETH and Shard holders to vote on active proposals.
    /// @param _proposalId The ID of the proposal to vote on.
    /// @param _support True for 'for', False for 'against'.
    function voteOnProposal(uint256 _proposalId, bool _support) external whenNotPaused {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.state == ProposalState.Active, "Aethelgard: Proposal not active");
        require(block.timestamp >= proposal.voteStartTime && block.timestamp <= proposal.voteEndTime, "Aethelgard: Voting period has ended or not started");
        require(!proposal.hasVoted[msg.sender], "Aethelgard: Already voted on this proposal");

        // Voting power calculation: Combine AETH stake and Shard influence
        uint256 votingPower = aethToken.balanceOf(msg.sender) / 100 ether; // 1 AETH stake = 1 voting power (example)
        uint256 balance = balanceOf(msg.sender);
        for (uint256 i = 0; i < balance; i++) {
            uint256 tokenId = tokenOfOwnerByIndex(msg.sender, i);
            votingPower += getShardInfluenceScore(tokenId) / 100; // Shard influence contributes
        }
        require(votingPower > 0, "Aethelgard: No voting power");

        if (_support) {
            proposal.votesFor += votingPower;
        } else {
            proposal.votesAgainst += votingPower;
        }
        proposal.hasVoted[msg.sender] = true;

        emit VoteCast(_proposalId, msg.sender, _support);
    }

    /// @notice Executes an approved proposal.
    /// @dev Only callable after the voting period ends and the proposal has succeeded.
    ///      Can only be called by Governance (Owner in this case).
    /// @param _proposalId The ID of the proposal to execute.
    function executeParameterChange(uint256 _proposalId) external onlyGovernance {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.state == ProposalState.Active, "Aethelgard: Proposal not active");
        require(block.timestamp > proposal.voteEndTime, "Aethelgard: Voting period has not ended");
        require(!proposal.executed, "Aethelgard: Proposal already executed");

        // Determine outcome (simple majority for this example)
        if (proposal.votesFor > proposal.votesAgainst) {
            proposal.state = ProposalState.Succeeded;
            // Execute the proposed function call
            (bool success,) = proposal.target.call(proposal.callData);
            require(success, "Aethelgard: Proposal execution failed");
            proposal.executed = true;
            emit ProposalExecuted(_proposalId);
        } else {
            proposal.state = ProposalState.Failed;
        }
    }

    /// @notice Special internal function called by governance proposals to update next epoch parameters.
    /// @dev This function is `internal` because it should only be called via a successful governance proposal.
    ///      It's designed to be the target of `proposeParameterChange`'s `_callData`.
    /// @param _epochDuration New epoch duration.
    /// @param _shardDecayRate New shard decay rate.
    /// @param _sepPerAETH New SEP per AETH staked.
    /// @param _minAETHForMint New min AETH for minting.
    /// @param _trialDifficultyMultiplier New trial difficulty multiplier.
    function setNextEpochParameters(
        uint256 _epochDuration,
        uint256 _shardDecayRate,
        uint256 _sepPerAETH,
        uint256 _minAETHForMint,
        uint256 _trialDifficultyMultiplier
    ) internal onlyGovernance { // `onlyGovernance` is checked by `executeParameterChange`'s `onlyGovernance` modifier
        // This function sets the parameters for the *next* epoch, not the current one.
        nextEpochParams = EpochParameters({
            epochDuration: _epochDuration,
            shardDecayRatePercent: _shardDecayRate,
            sepPerAETHStaked: _sepPerAETH,
            minAETHForMint: _minAETHForMint,
            trialDifficultyMultiplier: _trialDifficultyMultiplier
        });
        // No explicit event here, as `ProposalExecuted` will cover it.
    }

    /// @notice Retrieves the current epoch's active parameters.
    /// @return EpochParameters struct.
    function getEpochParameters() public view returns (EpochParameters memory) {
        return epochParams[currentEpoch];
    }
}
```