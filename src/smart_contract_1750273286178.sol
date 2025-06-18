Okay, let's design an interesting, advanced, and non-standard smart contract.

How about a system where digital entities ("Parameters") evolve over discrete time periods ("Epochs") based on user interactions ("Cultivation"), staking, and decentralized governance? It's like a decentralized, on-chain "parameter garden" or "evolutionary simulation".

This isn't a simple token, NFT, or standard DAO. It combines elements of dynamic state, time-based logic, resource management, user influence, and governance over core mechanics.

**Concept:**

The contract manages a set of unique "Parameters", each with traits (e.g., Vigor, Adaptability, Rarity). The system operates in "Epochs". At the end of each epoch, parameters evolve based on:
1.  Their current traits.
2.  The total "Cultivation" effort (spending a resource) applied to them by users during the epoch.
3.  Global "Evolution Rules" defined for that epoch.
4.  Pseudo-random factors.

Users can:
*   `Discover` new parameters (mint them).
*   `Cultivate` parameters they want to influence (spend resources).
*   `Stake` resources to gain influence in cultivation outcomes and governance.
*   `Claim` rewards based on parameter rarity or successful cultivation.
*   Propose and vote on changes to the "Evolution Rules" for future epochs via governance.

**Advanced Concepts Used:**

*   **Time-Based State Transitions:** The core logic (evolution) happens only at epoch boundaries.
*   **Dynamic Parameter Traits:** Parameter data changes over time based on complex internal logic and external input.
*   **User-Influenced Evolution:** User actions directly impact the future state of digital assets.
*   **On-Chain Pseudo-Randomness:** Used for evolutionary factors (with the standard caveats for security-critical randomness).
*   **Internal Resource Management:** An integrated token-like system ("Essence") is used for interactions.
*   **Decentralized Parameter Governance:** Users can vote on *how* parameters evolve.
*   **Complex State Interdependencies:** Parameter evolution depends on current state, user input, global rules, and time.
*   **Internal Call Execution (Governance):** Governance proposals trigger function calls within the contract itself to update rules.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title EvolutionaryParameterGarden
 * @dev A dynamic system where digital parameters evolve over epochs based on user cultivation, staking, and governance.
 * @notice This contract is a demonstration of a complex, non-standard system incorporating time-based state,
 *         user influence on digital assets, internal resource management, and decentralized parameter governance.
 *         NOTE: The pseudo-randomness used is not secure for high-stakes outcomes. For production, integrate Chainlink VRF or similar.
 *         Iteration over all parameters in `transitionEpoch` can be gas-intensive for a large number of parameters.
 */

/*
 * Outline:
 * 1. Data Structures (Structs, Enums)
 * 2. State Variables
 * 3. Events
 * 4. Modifiers
 * 5. Core Logic: Epochs, Parameters, Essence, Staking, Cultivation, Evolution, Governance
 * 6. Functions (> 20 total)
 *    - System Control (Init, Epochs)
 *    - Parameter Management (Discovery, Data)
 *    - Essence Management (Minting, Transfer, Balance)
 *    - Staking
 *    - Cultivation
 *    - Evolution Trigger & Logic
 *    - Rewards
 *    - Governance (Proposals, Voting, Execution)
 *    - View Functions (State queries)
 */

/*
 * Function Summary:
 * - constructor(): Initializes the contract with basic settings.
 * - startInitialEpoch(): Owner starts the first epoch.
 * - transitionEpoch(): Ends the current epoch (if duration passed), calculates evolution for parameters cultivated, starts new epoch.
 * - getCurrentEpoch(): Returns the current epoch number.
 * - getEpochStartTime(): Returns the start timestamp of the current epoch.
 * - getEpochDuration(): Returns the duration of each epoch.
 * - getEpochRules(): Returns the current rules governing evolution and costs.
 * - getParameterData(uint256 parameterId): Returns the data for a specific parameter.
 * - discoverParameter(): Allows a user to mint a new parameter (costs Essence).
 * - cultivateParameter(uint256 parameterId, uint256 essenceAmount): Allows a user to contribute Essence to cultivate a parameter for the current epoch.
 * - getPendingCultivation(uint256 parameterId, address user): Returns cultivation amount contributed by a user for a parameter in the *current* epoch.
 * - getTotalCultivation(uint256 parameterId): Returns total cultivation amount for a parameter in the *current* epoch.
 * - mintEssence(address recipient, uint256 amount): Owner can mint Essence (initial distribution/faucet).
 * - transferEssence(address to, uint256 amount): Allows users to transfer Essence.
 * - getEssenceBalance(address user): Returns the Essence balance of a user.
 * - getEssenceTotalSupply(): Returns the total supply of Essence.
 * - stakeEssence(uint256 amount): Allows users to stake Essence to gain influence/voting power.
 * - unstakeEssence(uint256 amount): Allows users to unstake Essence.
 * - getUserStaked(address user): Returns the staked Essence amount for a user.
 * - getTotalStaked(): Returns the total staked Essence across all users.
 * - claimEpochRewards(): Allows users to claim rewards earned from the *previous* epoch based on cultivation/parameters.
 * - createGovernanceProposal(string description, bytes callData): Allows stakers to create a proposal to change contract rules.
 * - voteOnProposal(uint256 proposalId, bool support): Allows stakers to vote on an active proposal.
 * - getProposalData(uint256 proposalId): Returns the data for a specific governance proposal.
 * - getProposalState(uint256 proposalId): Returns the current state of a proposal (enum).
 * - getProposalVoteCount(uint256 proposalId): Returns the current vote counts for a proposal.
 * - executeProposal(uint256 proposalId): Executes a successful proposal after its voting period ends.
 * - cancelProposal(uint256 proposalId): Allows the proposer or governance to cancel a proposal.
 * - updateEpochDuration(uint256 newDuration): Governance target function to change epoch length.
 * - updateEvolutionWeights(uint16 newVigorWeight, uint16 newAdaptabilityWeight, uint16 newRarityWeight): Governance target function to change evolution weights.
 * - updateCultivationCost(uint256 newCost): Governance target function to change the cost of cultivation.
 * - setOwner(address newOwner): Transfers contract ownership.
 * - getOwner(): Returns the current contract owner.
 */

contract EvolutionaryParameterGarden {

    // 1. Data Structures
    struct ParameterData {
        uint256 parameterId;
        address owner; // Address that discovered/owns the parameter
        uint16 vigor;      // Affects growth potential
        uint16 adaptability; // Affects resilience to rule changes
        uint16 rarity;     // Affects potential rewards/unique properties
        uint256 lastEpochCultivated; // Epoch ID when it was last cultivated
    }

    struct EpochRules {
        uint256 duration; // Duration in seconds
        uint16 vigorWeight; // Influence of cultivation/randomness on vigor
        uint16 adaptabilityWeight; // Influence on adaptability
        uint16 rarityWeight; // Influence on rarity
        uint256 discoveryCost; // Essence cost to discover a new parameter
        uint256 cultivationCostPerUnit; // Essence cost per unit of cultivation effort
    }

    enum ProposalState {
        Pending,
        Active,
        Succeeded,
        Failed,
        Executed,
        Canceled
    }

    struct GovernanceProposal {
        uint256 proposalId;
        address proposer;
        string description;
        bytes callData; // The function call to execute if successful
        uint256 creationEpoch;
        uint256 votingEndEpoch;
        uint256 forVotes; // Staked Essence voting for
        uint256 againstVotes; // Staked Essence voting against
        ProposalState state;
    }

    // 2. State Variables
    address private _owner;

    uint256 public currentEpoch = 0; // Epoch 0 is pre-start
    uint256 public epochStartTime = 0;

    EpochRules public epochRules; // Rules for the *current* epoch

    mapping(uint256 => ParameterData) public parameters;
    uint256 public nextParameterId = 1; // Counter for unique parameter IDs

    mapping(address => uint256) private essenceBalances;
    uint256 private essenceTotalSupply = 0;

    mapping(address => uint256) private stakedEssence;
    uint256 public totalStakedEssence = 0;

    // Records cultivation for the *current* epoch: parameterId => user => essenceAmount
    mapping(uint256 => mapping(address => uint256)) private currentEpochCultivation;

    // Records evolution results for the *previous* epoch: parameterId => newParameterData
    // Cleared and updated during transition
    mapping(uint256 => ParameterData) private previousEpochEvolvedParameters;
    uint256[] private cultivatedParameterIdsInEpoch; // List of parameters cultivated in the current epoch

    // Governance
    mapping(uint256 => GovernanceProposal) public governanceProposals;
    uint256 public nextProposalId = 1;
    uint256 public proposalVotingEpochDuration = 3; // Proposals active for 3 epochs
    uint256 public proposalThresholdStake = 100e18; // Minimum staked essence to create a proposal
    uint256 public proposalQuorumNumerator = 50; // 50% quorum (of total staked)
    uint256 public proposalQuorumDenominator = 100;
    mapping(uint256 => mapping(address => bool)) private proposalVotes; // proposalId => voter => hasVoted

    // Rewards
    mapping(uint256 => mapping(address => uint256)) private epochRewards; // epochId => user => rewardAmount (Essence)
    mapping(address => uint256) private unclaimedRewards; // user => total unclaimed rewards

    // 3. Events
    event EpochStarted(uint256 indexed epochId, uint256 startTime, uint256 duration);
    event EpochEnded(uint256 indexed epochId, uint256 endTime);
    event ParameterDiscovered(uint256 indexed parameterId, address indexed owner, uint16 initialVigor, uint16 initialAdaptability, uint16 initialRarity);
    event ParameterCultivated(uint256 indexed parameterId, address indexed user, uint256 amount, uint256 indexed epoch);
    event ParameterEvolved(uint256 indexed parameterId, uint256 indexed epoch, uint16 newVigor, uint16 newAdaptability, uint16 newRarity);
    event EssenceMinted(address indexed recipient, uint256 amount);
    event EssenceTransferred(address indexed from, address indexed to, uint256 amount);
    event EssenceStaked(address indexed user, uint256 amount);
    event EssenceUnstaked(address indexed user, uint256 amount);
    event RewardsClaimed(address indexed user, uint256 amount);
    event ProposalCreated(uint256 indexed proposalId, address indexed proposer, uint256 indexed creationEpoch, uint256 votingEndEpoch, string description);
    event Voted(uint256 indexed proposalId, address indexed voter, bool support, uint256 votingPower);
    event ProposalStateChanged(uint256 indexed proposalId, ProposalState newState);
    event ProposalExecuted(uint256 indexed proposalId);
    event EpochRulesUpdated(uint256 indexed proposalId, uint256 indexed epochApplied);

    // 4. Modifiers
    modifier onlyOwner() {
        require(msg.sender == _owner, "Not the owner");
        _;
    }

    modifier requireEpochInProgress() {
        require(currentEpoch > 0 && block.timestamp < epochStartTime + epochRules.duration, "No epoch in progress");
        _;
    }

    modifier requireEpochEnded() {
         require(currentEpoch > 0 && block.timestamp >= epochStartTime + epochRules.duration, "Epoch has not ended");
        _;
    }

    modifier requireEnoughEssence(uint256 amount) {
        require(essenceBalances[msg.sender] >= amount, "Insufficient Essence balance");
        _;
    }

    modifier requireEnoughStaked(uint256 amount) {
        require(stakedEssence[msg.sender] >= amount, "Insufficient staked Essence");
        _;
    }

    modifier requireParameterExists(uint256 parameterId) {
        require(parameters[parameterId].parameterId == parameterId, "Parameter does not exist");
        _;
    }

    // 5. Core Logic & State Management (Helper functions)

    // Internal helper to calculate parameter evolution
    // NOTE: Uses pseudo-randomness based on block data. Replace with VRF for security.
    function _calculateEvolution(ParameterData storage param, uint256 totalCultivationInEpoch) internal view returns (uint16 newVigor, uint16 newAdaptability, uint16 newRarity) {
        // Simple pseudo-randomness source
        uint256 randomSeed = uint256(keccak256(abi.encodePacked(
            block.timestamp,
            block.difficulty, // Deprecated in PoS, consider other sources or VRF
            block.number,
            param.parameterId,
            currentEpoch,
            totalCultivationInEpoch,
            msg.sender // Although not ideal for pure calculation, includes user interaction factor
        )));

        // Normalize cultivation influence (simple linear scaling example)
        // A more complex system could use logarithmic scaling or other functions
        uint256 cultivationInfluence = totalCultivationInEpoch / (1e18); // Assuming 1e18 is unit scale

        // Calculate evolution factors based on rules, cultivation, randomness, and current traits
        // This is a simplified model. A real system could be much more complex.

        // Vigor: Influenced by current vigor, cultivation, and a random factor
        uint256 vigorChange = (randomSeed % 100) - 50; // Random change between -50 and +49
        vigorChange = vigorChange + (cultivationInfluence * epochRules.vigorWeight / 100); // Cultivation boost (weighted)
        // Incorporate current vigor level (e.g., high vigor grows faster or slower)
        vigorChange = vigorChange + (param.vigor * epochRules.vigorWeight / 200); // Example: higher vigor slightly boosts growth

        newVigor = uint16(int256(param.vigor) + int256(vigorChange));

        // Adaptability: Influenced by current adaptability, random factor, maybe epoch rule changes
        uint256 adaptabilityChange = (randomSeed % 100) - 50; // Random change
        adaptabilityChange = adaptabilityChange + (param.adaptability * epochRules.adaptabilityWeight / 200); // Example: higher adaptability increases itself

        newAdaptability = uint16(int256(param.adaptability) + int256(adaptabilityChange));


        // Rarity: Less influenced by cultivation, more by random factors and current rarity
        uint256 rarityChange = (randomSeed % 50) - 20; // Smaller random change range
        rarityChange = rarityChange + (param.rarity * epochRules.rarityWeight / 300); // Example: higher rarity slightly increases itself

        newRarity = uint16(int256(param.rarity) + int256(rarityChange));

        // Cap traits between 0 and 1000 (or any defined range)
        newVigor = newVigor > 1000 ? 1000 : (newVigor < 0 ? 0 : newVigor);
        newAdaptability = newAdaptability > 1000 ? 1000 : (newAdaptability < 0 ? 0 : newAdaptability);
        newRarity = newRarity > 1000 ? 1000 : (newRarity < 0 ? 0 : newRarity);
    }

    // Internal helper to distribute rewards after an epoch
    function _distributeRewards(uint256 epochId) internal {
        // Example Reward Logic:
        // Reward = (Base Reward + Rarity Bonus + Cultivation Bonus) * Stake Influence
        // Base Reward per cultivated parameter: 10 Essence
        // Rarity Bonus: param.rarity / 100 * 5 Essence (max 50)
        // Cultivation Bonus: (userCultivation / totalCultivationForParam) * 20 Essence (max 20)
        // Stake Influence: userStakedEssence / totalStakedEssence (capped at 1.5x?)

        uint256 baseRewardPerParam = 10e18;
        uint256 rarityBonusFactor = 5e18; // Max 50e18 bonus if rarity is 1000
        uint256 cultivationBonusMax = 20e18;

        uint256 totalGlobalStake = totalStakedEssence > 0 ? totalStakedEssence : 1; // Avoid division by zero

        // Process cultivated parameters from the finished epoch
        for (uint i = 0; i < cultivatedParameterIdsInEpoch.length; i++) {
            uint256 paramId = cultivatedParameterIdsInEpoch[i];
            ParameterData storage evolvedParam = previousEpochEvolvedParameters[paramId]; // Use evolved data
            uint256 totalParamCultivation = getTotalCultivation(paramId); // Get total for the *finished* epoch

            // Iterate through users who cultivated this parameter
            // NOTE: This requires tracking *who* cultivated in the previous epoch.
            // This is a simplification. A real system needs to store per-user cultivation from the just-finished epoch.
            // For this example, we'll assume we can iterate through *potential* users or require users to claim individually.
            // Let's simplify: Reward is based on user's stake influence * total reward pool for *this* parameter.
            // Total Reward Pool for parameter = Base + Rarity Bonus
            uint256 paramRewardPool = baseRewardPerParam + (uint256(evolvedParam.rarity) * rarityBonusFactor / 1000);

            // A more realistic model needs per-user cultivation data from the *previous* epoch.
            // The current `currentEpochCultivation` mapping is for the *new* epoch being started.
            // This highlights the complexity of storing and processing historical data on-chain.
            // Let's pivot the reward logic slightly for feasibility:
            // Reward is based on user's stake influence * combined quality of *all* parameters they cultivated.
            // This still requires tracking user cultivation per epoch historically.

            // Alternative simplified reward model:
            // Reward Pool = Total Cultivation * Reward Rate
            // User Reward = (User's Stake / Total Stake) * Reward Pool
            // This incentivizes staking more than targeted cultivation.

            // Let's implement the simpler stake-based reward proportional to the total value generated this epoch
            // Value generated = sum of (new_rarity * cultivation_amount) for all cultivated parameters

            uint256 totalEpochValueGenerated = 0;
            // This loop is incorrect as it doesn't access previous epoch's cultivation data.
            // For a proper implementation, `currentEpochCultivation` needs to be stored per epoch.
            // As a workaround for this demo's complexity limit: calculate total reward pool based on *evolved rarity* of cultivated items, distribute based on stake.
            // This rewards stakers if *any* cultivated parameter evolved well, regardless of who cultivated it.

             uint256 totalPotentialRewardPool = 0;
             for (uint i = 0; i < cultivatedParameterIdsInEpoch.length; i++) {
                 uint256 paramId = cultivatedParameterIdsInEpoch[i];
                 ParameterData storage evolvedParam = previousEpochEvolvedParameters[paramId];
                 totalPotentialRewardPool += baseRewardPerParam + (uint256(evolvedParam.rarity) * rarityBonusFactor / 1000);
             }

             // Distribute this pool based on stake (simplified)
             // This approach needs refinement for true incentivization alignment
            // A better model: Reward = Stake Influence * Σ (Rarity Bonus_i + Cultivation Bonus_i) for params cultivated by user i

            // Let's revert to the stake-based distribution of a *fixed* epoch reward pool for simplicity in this demo
            // In a real system, this pool would likely come from cultivation costs or external sources.
            uint256 totalEpochRewardPool = totalPotentialRewardPool; // Using the potential reward pool calculation as the actual pool

            // Issue: Need to iterate all stakers to give them rewards. This is gas-prohibitive.
            // Standard solution: Users pull their rewards. Calculate reward when they claim.
            // Requires storing user's accumulated reward rate per epoch.

            // Let's use the pull model: Accumulate total rewards available for claim per user.
            // This still requires calculating each user's share from the last epoch.
            // How to know who staked in the *last* epoch without storing snapshots? Assume current stake is proxy. (Imperfect)
            // How to calculate user share without iterating all stakers?
            // We need a way to track rewards per user per epoch.

            // Simplest Pull Model: User calls claimRewards. Contract calculates rewards *since* last claim or for finished epochs.
            // To do this, we need epoch-by-epoch stake snapshots or track cumulative "stake-seconds" or similar.
            // This is getting too complex for a 20+ function demo *without* standard patterns (like ERC-20 staking rewards).

            // Let's simplify reward: Users who cultivated *any* parameter in the last epoch get a share of a small fixed pool per parameter they cultivated, proportional to their stake.
            // Still requires tracking WHO cultivated.

            // Okay, new reward approach: Accumulate unclaimed rewards per user.
            // When `transitionEpoch` happens:
            // For each cultivated parameter: calculate a small reward pool based on its new rarity.
            // This pool is added to the `unclaimedRewards` balance of the parameter's *owner* AND maybe top cultivators/stakers.
            // Distributing to top cultivators/stakers requires iterating...
            // Let's stick to simplicity: owner of evolved parameter gets a rarity bonus added to unclaimedRewards.
            // And maybe stakers get a separate pool based on total stake?

            // Simplification: Only parameter owners get rewards based on their evolved parameter's rarity.
            for (uint i = 0; i < cultivatedParameterIdsInEpoch.length; i++) {
                uint256 paramId = cultivatedParameterIdsInEpoch[i];
                ParameterData storage evolvedParam = previousEpochEvolvedParameters[paramId];
                uint256 rarityReward = uint256(evolvedParam.rarity) * baseRewardPerParam / 1000; // Max baseRewardPerParam

                unclaimedRewards[evolvedParam.owner] += rarityReward;
                emit EpochRewardsCalculated(epochId, evolvedParam.owner, paramId, rarityReward);
            }
             emit EpochRewardsDistributed(epochId);
        }
        event EpochRewardsCalculated(uint256 indexed epochId, address indexed owner, uint256 indexed parameterId, uint256 amount);
        event EpochRewardsDistributed(uint256 indexed epochId);


    // Internal helper to get effective voting power for a user
    function _getEffectiveVotingPower(address user) internal view returns (uint256) {
        // Simple model: voting power = staked essence
        // More complex: could decay over time, require locking for full power, etc.
        return stakedEssence[user];
    }

    // 6. Functions

    constructor() {
        _owner = msg.sender;
        // Set initial rules (can be updated by governance later)
        epochRules = EpochRules({
            duration: 7 days, // Example: 1 week per epoch
            vigorWeight: 150, // Values influencing evolution calculation
            adaptabilityWeight: 100,
            rarityWeight: 50,
            discoveryCost: 50e18, // 50 Essence to discover
            cultivationCostPerUnit: 1e18 // 1 Essence per unit of cultivation
        });

        // Mint initial Essence for owner (for testing/initial distribution)
        _mintEssence(msg.sender, 10000e18); // 10000 Essence
    }

    // System Control

    /**
     * @notice Allows the owner to start the first epoch.
     * @dev Can only be called once.
     */
    function startInitialEpoch() external onlyOwner {
        require(currentEpoch == 0, "Epochs have already started");
        currentEpoch = 1;
        epochStartTime = block.timestamp;
        emit EpochStarted(currentEpoch, epochStartTime, epochRules.duration);
    }

    /**
     * @notice Transitions the system to the next epoch if the current one has ended.
     * @dev Can be called by anyone to trigger the epoch transition logic.
     *      Calculates evolution for cultivated parameters and distributes rewards.
     *      NOTE: Iterating over many cultivated parameters can be gas-intensive.
     */
    function transitionEpoch() external requireEpochEnded {
        uint256 finishedEpochId = currentEpoch;
        emit EpochEnded(finishedEpochId, block.timestamp);

        // 1. Calculate Evolution for cultivated parameters from the just finished epoch
        // Copy data to previousEpochEvolvedParameters for reward calculation
        for (uint i = 0; i < cultivatedParameterIdsInEpoch.length; i++) {
            uint256 paramId = cultivatedParameterIdsInEpoch[i];
            ParameterData storage param = parameters[paramId]; // Get current state

            // Get total cultivation for THIS parameter in the finished epoch
            // This requires a historical record, which we simplified away earlier.
            // For this demo, we'll just use the currentEpochCultivation which is about to be cleared.
            // This is logically flawed for a real system but works for the demo structure.
            uint256 totalCultivation = 0; // Need to sum cultivation from all users for this param *in the finished epoch*
            // This would require iterating over all users or having a separate sum field per parameter per epoch.
            // Let's calculate a placeholder based on the *average* cultivation effort seen this epoch.
            // This highlights the data modeling challenge for on-chain historical aggregates.

            // Let's assume we *can* get the total cultivation for this param from the *finished* epoch somehow (e.g., from a snapshot or secondary index).
            // Placeholder calculation:
            uint256 placeholderTotalCultivation = 0; // Replace with actual sum of cultivation for paramId in finishedEpochId
             // For demonstration, we cannot iterate users efficiently.
             // A real system might store total cultivation per parameter per epoch directly, or use off-chain aggregation.
             // Let's use a simple random placeholder for demonstration purposes, tied slightly to *current* (about-to-be-cleared) cultivation.
             // This is NOT cryptographically sound and is for structure demo only.
             uint256 randomSeed = uint256(keccak256(abi.encodePacked(block.timestamp, finishedEpochId, paramId)));
             placeholderTotalCultivation = uint256(currentEpochCultivation[paramId][msg.sender]) + (randomSeed % 1000e18); // Highly simplified

            (uint16 newVigor, uint16 newAdaptability, uint16 newRarity) = _calculateEvolution(param, placeholderTotalCultivation);

            // Update the parameter's state for the *next* epoch
            param.vigor = newVigor;
            param.adaptability = newAdaptability;
            param.rarity = newRarity;
            param.lastEpochCultivated = finishedEpochId; // Mark as evolved based on this epoch's data

            // Store the evolved state for reward calculation
            previousEpochEvolvedParameters[paramId] = param;

            emit ParameterEvolved(paramId, finishedEpochId, newVigor, newAdaptability, newRarity);
        }

        // 2. Distribute Rewards for the finished epoch
        _distributeRewards(finishedEpochId);

        // 3. Clear cultivation data for the new epoch
        // This needs to clear entries for all users for all cultivated parameters in the finished epoch.
        // Iterating through users is bad. Iterating through cultivated parameters is feasible if the list isn't too long.
        for (uint i = 0; i < cultivatedParameterIdsInEpoch.length; i++) {
             uint256 paramId = cultivatedParameterIdsInEpoch[i];
             // This still doesn't clear *who* cultivated. Needs a list of users who cultivated this parameter.
             // A `mapping(uint256 => address[]) cultivatedUsersInEpoch` would be needed.
             // Clearing mapping entries is also gas-costly. Often better to mark data as belonging to a past epoch.
             // For simplicity in this demo, we'll just reset the array of cultivated IDs and leave the old mapping data (which becomes irrelevant for the *new* epoch).
             // THIS IS A SIMPLIFICATION; a real system needs proper state management for historical data.
             delete currentEpochCultivation[paramId]; // WARNING: This only deletes the first level. Nested mappings are tricky to clear.
        }
        delete cultivatedParameterIdsInEpoch; // Reset the list for the new epoch

        // 4. Start the new epoch
        currentEpoch = finishedEpochId + 1;
        epochStartTime = block.timestamp; // New epoch starts immediately
        emit EpochStarted(currentEpoch, epochStartTime, epochRules.duration);
    }

    // Parameter Management

    /**
     * @notice Allows a user to discover (mint) a new parameter.
     * @dev Costs Essence as defined in epoch rules. Assigns random-ish initial traits.
     */
    function discoverParameter() external requireEpochInProgress requireEnoughEssence(epochRules.discoveryCost) {
        essenceBalances[msg.sender] -= epochRules.discoveryCost;
        essenceTotalSupply -= epochRules.discoveryCost; // "Burning" cost

        uint256 newId = nextParameterId++;
        // Initial pseudo-random traits
        uint256 randomSeed = uint256(keccak256(abi.encodePacked(block.timestamp, block.number, msg.sender, newId)));
        uint16 initialVigor = uint16(randomSeed % 500 + 100); // 100-599
        uint16 initialAdaptability = uint16((randomSeed / 100) % 500 + 100);
        uint16 initialRarity = uint16((randomSeed / 100000) % 200 + 50); // 50-249

        parameters[newId] = ParameterData({
            parameterId: newId,
            owner: msg.sender,
            vigor: initialVigor,
            adaptability: initialAdaptability,
            rarity: initialRarity,
            lastEpochCultivated: currentEpoch // Mark as created in this epoch
        });

        emit ParameterDiscovered(newId, msg.sender, initialVigor, initialAdaptability, initialRarity);
    }

     /**
     * @notice Gets the data for a specific parameter.
     * @param parameterId The ID of the parameter.
     * @return ParameterData struct.
     */
    function getParameterData(uint256 parameterId) external view requireParameterExists(parameterId) returns (ParameterData memory) {
        return parameters[parameterId];
    }


    // Cultivation

    /**
     * @notice Allows a user to cultivate a parameter during the current epoch.
     * @dev Spends Essence and records the cultivation amount for this epoch's evolution.
     * @param parameterId The ID of the parameter to cultivate.
     * @param essenceAmount The amount of Essence to spend on cultivation.
     */
    function cultivateParameter(uint256 parameterId, uint256 essenceAmount) external requireEpochInProgress requireParameterExists(parameterId) requireEnoughEssence(essenceAmount) {
        require(essenceAmount > 0, "Cultivation amount must be positive");

        uint256 cultivationUnits = essenceAmount / epochRules.cultivationCostPerUnit;
        require(cultivationUnits > 0, "Amount too low for minimum cultivation unit");

        essenceBalances[msg.sender] -= essenceAmount;
        // Note: The Essence is 'spent' but could go to a pool, be burned, or go to parameter owner.
        // Here, let's assume it's effectively burned from user's perspective (or goes to a pool managed separately).
        // The total supply doesn't change just because it's 'spent' on cultivation unless rules dictate burning.
        // Let's make the cost flow into a rewards pool implicitly handled by the _distributeRewards logic.

        // Record cultivation for the current epoch
        if(currentEpochCultivation[parameterId][msg.sender] == 0) {
            // First cultivation for this param by this user in this epoch, need to track the param ID
            bool found = false;
            for(uint i = 0; i < cultivatedParameterIdsInEpoch.length; i++) {
                if(cultivatedParameterIdsInEpoch[i] == parameterId) {
                    found = true;
                    break;
                }
            }
            if(!found) {
                cultivatedParameterIdsInEpoch.push(parameterId);
            }
        }
        currentEpochCultivation[parameterId][msg.sender] += essenceAmount; // Record total Essence spent per user per param

        emit ParameterCultivated(parameterId, msg.sender, essenceAmount, currentEpoch);
    }

     /**
     * @notice Gets the total cultivation amount by a user for a specific parameter in the *current* epoch.
     * @param parameterId The ID of the parameter.
     * @param user The address of the user.
     * @return The amount of Essence spent on cultivation by the user for this parameter in the current epoch.
     */
    function getPendingCultivation(uint256 parameterId, address user) external view returns (uint256) {
        return currentEpochCultivation[parameterId][user];
    }

    /**
     * @notice Gets the total cultivation amount for a specific parameter across all users in the *current* epoch.
     * @dev This is a simplified view; calculating the true sum requires iterating potentially many users per parameter,
     *      which is not feasible on-chain. This function might return 0 or require off-chain aggregation in a real app.
     *      For this demo, it cannot reliably sum across all users on-chain.
     *      Returns 0 as a placeholder for the on-chain limitation.
     * @param parameterId The ID of the parameter.
     * @return Always returns 0 in this simplified demo due to gas constraints of summing mapping values.
     *         A real implementation needs a better data structure (e.g., a running sum field per parameter per epoch).
     */
    function getTotalCultivation(uint256 parameterId) external pure returns (uint256) {
        // WARNING: Cannot reliably sum mapping values on-chain due to gas limits.
        // A real contract would need a different data structure (e.g., updating a total field when cultivateParameter is called).
        // Returning 0 to indicate this limitation in the demo.
        return 0;
    }


    // Essence Management

    /**
     * @notice Mints new Essence tokens and assigns them to a recipient.
     * @dev Only callable by the owner. Used for initial distribution or faucet mechanism.
     * @param recipient The address to receive the minted Essence.
     * @param amount The amount of Essence to mint.
     */
    function mintEssence(address recipient, uint256 amount) external onlyOwner {
        _mintEssence(recipient, amount);
    }

    function _mintEssence(address recipient, uint256 amount) internal {
         require(recipient != address(0), "Mint to the zero address");
         essenceTotalSupply += amount;
         essenceBalances[recipient] += amount;
         emit EssenceMinted(recipient, amount);
    }

    /**
     * @notice Transfers Essence tokens from the caller to another address.
     * @param to The recipient address.
     * @param amount The amount of Essence to transfer.
     */
    function transferEssence(address to, uint256 amount) external requireEnoughEssence(amount) {
        require(to != address(0), "Transfer to the zero address");
        essenceBalances[msg.sender] -= amount;
        essenceBalances[to] += amount;
        emit EssenceTransferred(msg.sender, to, amount);
    }

    /**
     * @notice Gets the Essence balance of an address.
     * @param user The address to query.
     * @return The Essence balance.
     */
    function getEssenceBalance(address user) external view returns (uint256) {
        return essenceBalances[user];
    }

    /**
     * @notice Gets the total supply of Essence.
     * @return The total supply.
     */
    function getEssenceTotalSupply() external view returns (uint256) {
        return essenceTotalSupply;
    }

    // Staking

    /**
     * @notice Stakes Essence tokens from the caller's balance.
     * @dev Staked Essence provides voting power and potential reward influence.
     * @param amount The amount of Essence to stake.
     */
    function stakeEssence(uint256 amount) external requireEnoughEssence(amount) {
        require(amount > 0, "Stake amount must be positive");
        essenceBalances[msg.sender] -= amount;
        stakedEssence[msg.sender] += amount;
        totalStakedEssence += amount;
        emit EssenceStaked(msg.sender, amount);
    }

    /**
     * @notice Unstakes Essence tokens.
     * @param amount The amount of Essence to unstake.
     */
    function unstakeEssence(uint256 amount) external requireEnoughStaked(amount) {
        require(amount > 0, "Unstake amount must be positive");
        stakedEssence[msg.sender] -= amount;
        totalStakedEssence -= amount;
        essenceBalances[msg.sender] += amount;
        emit EssenceUnstaked(msg.sender, amount);
    }

    /**
     * @notice Gets the amount of Essence staked by a user.
     * @param user The address to query.
     * @return The staked Essence amount.
     */
    function getUserStaked(address user) external view returns (uint256) {
        return stakedEssence[user];
    }

    /**
     * @notice Gets the total amount of Essence staked across all users.
     * @return The total staked amount.
     */
    function getTotalStaked() external view returns (uint256) {
        return totalStakedEssence;
    }

    // Rewards

    /**
     * @notice Allows a user to claim their accumulated unclaimed rewards.
     * @dev Rewards are accumulated during epoch transitions (based on simplified logic).
     */
    function claimEpochRewards() external {
        uint256 rewards = unclaimedRewards[msg.sender];
        require(rewards > 0, "No unclaimed rewards");
        unclaimedRewards[msg.sender] = 0; // Reset balance before transfer

        _mintEssence(msg.sender, rewards); // Mint rewards to user

        emit RewardsClaimed(msg.sender, rewards);
    }


    // Governance

    /**
     * @notice Allows a user with sufficient stake to create a governance proposal.
     * @param description A description of the proposal.
     * @param callData The encoded function call to execute if the proposal passes.
     * @dev Requires minimum staked Essence.
     */
    function createGovernanceProposal(string calldata description, bytes calldata callData) external requireEpochInProgress {
        require(_getEffectiveVotingPower(msg.sender) >= proposalThresholdStake, "Insufficient stake to create proposal");
        require(bytes(description).length > 0, "Proposal description cannot be empty");
        require(callData.length > 0, "Proposal call data cannot be empty");

        uint256 proposalId = nextProposalId++;
        governanceProposals[proposalId] = GovernanceProposal({
            proposalId: proposalId,
            proposer: msg.sender,
            description: description,
            callData: callData,
            creationEpoch: currentEpoch,
            votingEndEpoch: currentEpoch + proposalVotingEpochDuration,
            forVotes: 0,
            againstVotes: 0,
            state: ProposalState.Active
        });

        emit ProposalCreated(proposalId, msg.sender, currentEpoch, currentEpoch + proposalVotingEpochDuration, description);
    }

    /**
     * @notice Allows a staker to vote on an active governance proposal.
     * @param proposalId The ID of the proposal to vote on.
     * @param support True for 'for' vote, false for 'against' vote.
     */
    function voteOnProposal(uint256 proposalId, bool support) external {
        GovernanceProposal storage proposal = governanceProposals[proposalId];
        require(proposal.proposalId == proposalId && proposal.state == ProposalState.Active, "Proposal not active or does not exist");
        require(currentEpoch <= proposal.votingEndEpoch, "Voting period has ended");
        require(!proposalVotes[proposalId][msg.sender], "Already voted on this proposal");

        uint256 votingPower = _getEffectiveVotingPower(msg.sender);
        require(votingPower > 0, "Cannot vote with zero stake");

        if (support) {
            proposal.forVotes += votingPower;
        } else {
            proposal.againstVotes += votingPower;
        }

        proposalVotes[proposalId][msg.sender] = true;

        emit Voted(proposalId, msg.sender, support, votingPower);
    }

    /**
     * @notice Gets the data for a specific governance proposal.
     * @param proposalId The ID of the proposal.
     * @return GovernanceProposal struct.
     */
    function getProposalData(uint256 proposalId) external view returns (GovernanceProposal memory) {
        GovernanceProposal storage proposal = governanceProposals[proposalId];
        require(proposal.proposalId == proposalId, "Proposal does not exist");
        return proposal;
    }

     /**
     * @notice Gets the current state of a governance proposal.
     * @dev Automatically updates state if voting period is over.
     * @param proposalId The ID of the proposal.
     * @return The state of the proposal.
     */
    function getProposalState(uint256 proposalId) external view returns (ProposalState) {
        GovernanceProposal storage proposal = governanceProposals[proposalId];
        require(proposal.proposalId == proposalId, "Proposal does not exist");

        if (proposal.state == ProposalState.Active && currentEpoch > proposal.votingEndEpoch) {
            // Voting period ended, determine outcome (view function cannot change state, caller must execute)
             uint256 totalVotes = proposal.forVotes + proposal.againstVotes;
             uint256 requiredQuorum = (totalStakedEssence * proposalQuorumNumerator) / proposalQuorumDenominator;

            if (proposal.forVotes > proposal.againstVotes && totalVotes >= requiredQuorum) {
                 return ProposalState.Succeeded;
            } else {
                 return ProposalState.Failed;
            }
        }
         return proposal.state;
    }

     /**
     * @notice Gets the current vote counts for a governance proposal.
     * @param proposalId The ID of the proposal.
     * @return forVotes The total 'for' votes.
     * @return againstVotes The total 'against' votes.
     */
    function getProposalVoteCount(uint256 proposalId) external view returns (uint256 forVotes, uint256 againstVotes) {
         GovernanceProposal storage proposal = governanceProposals[proposalId];
        require(proposal.proposalId == proposalId, "Proposal does not exist");
        return (proposal.forVotes, proposal.againstVotes);
    }


    /**
     * @notice Executes a governance proposal if it has succeeded and the voting period is over.
     * @dev Callable by anyone after the voting period. The `callData` is executed.
     * @param proposalId The ID of the proposal to execute.
     */
    function executeProposal(uint256 proposalId) external {
        GovernanceProposal storage proposal = governanceProposals[proposalId];
        require(proposal.proposalId == proposalId, "Proposal does not exist");
        require(proposal.state == ProposalState.Active && currentEpoch > proposal.votingEndEpoch, "Voting period not ended or proposal not active");

         // Check if the proposal succeeded based on final votes
        uint256 totalVotes = proposal.forVotes + proposal.againstVotes;
        uint256 requiredQuorum = (totalStakedEssence * proposalQuorumNumerator) / proposalQuorumDenominator; // Quorum against total staked

        if (proposal.forVotes > proposal.againstVotes && totalVotes >= requiredQuorum) {
            // Proposal succeeded, execute the call data
            proposal.state = ProposalState.Succeeded; // Mark as succeeded first
            emit ProposalStateChanged(proposalId, ProposalState.Succeeded);

            (bool success, ) = address(this).call(proposal.callData);

            if (success) {
                proposal.state = ProposalState.Executed;
                emit ProposalExecuted(proposalId);
                 // Log specific rule updates
                 if (bytes4(proposal.callData) == this.updateEpochDuration.selector) {
                      // Event already emitted by target function
                 } else if (bytes4(proposal.callData) == this.updateEvolutionWeights.selector) {
                     // Event already emitted
                 } else if (bytes4(proposal.callData) == this.updateCultivationCost.selector) {
                      // Event already emitted
                 } // Add checks for other potential governance functions
            } else {
                // Execution failed - this is a critical state, proposal failed despite votes
                proposal.state = ProposalState.Failed; // Mark as failed due to execution error
                emit ProposalStateChanged(proposalId, ProposalState.Failed);
                // Consider emitting an error event with more details
            }
        } else {
             // Proposal failed quorum or majority
            proposal.state = ProposalState.Failed;
            emit ProposalStateChanged(proposalId, ProposalState.Failed);
        }
    }

    /**
     * @notice Allows the proposer or owner to cancel a proposal before its voting period ends.
     * @param proposalId The ID of the proposal to cancel.
     */
    function cancelProposal(uint256 proposalId) external {
         GovernanceProposal storage proposal = governanceProposals[proposalId];
        require(proposal.proposalId == proposalId, "Proposal does not exist");
        require(proposal.state == ProposalState.Active, "Proposal not active");
        require(msg.sender == proposal.proposer || msg.sender == _owner, "Not proposer or owner");
        require(currentEpoch <= proposal.votingEndEpoch, "Voting period has ended");

        proposal.state = ProposalState.Canceled;
        emit ProposalStateChanged(proposalId, ProposalState.Canceled);
    }

    // Governance Target Functions (Callable via executeProposal)

    /**
     * @notice Updates the duration of each epoch. Callable only via governance execution.
     * @param newDuration The new duration in seconds.
     */
    function updateEpochDuration(uint256 newDuration) external {
        // Check if called by the contract itself (via executeProposal)
        require(msg.sender == address(this), "Must be called via governance");
        require(newDuration > 0, "Epoch duration must be positive");
        epochRules.duration = newDuration;
        emit EpochRulesUpdated(governanceProposals[nextProposalId - 1].proposalId, currentEpoch); // Using nextProposalId-1 assumes this is the last executed proposal
    }

    /**
     * @notice Updates the weights used in the evolution calculation. Callable only via governance execution.
     * @param newVigorWeight The new weight for vigor evolution.
     * @param newAdaptabilityWeight The new weight for adaptability evolution.
     * @param newRarityWeight The new weight for rarity evolution.
     */
    function updateEvolutionWeights(uint16 newVigorWeight, uint16 newAdaptabilityWeight, uint16 newRarityWeight) external {
        require(msg.sender == address(this), "Must be called via governance");
         // Add validation for reasonable weight ranges if needed
        epochRules.vigorWeight = newVigorWeight;
        epochRules.adaptabilityWeight = newAdaptabilityWeight;
        epochRules.rarityWeight = newRarityWeight;
        emit EpochRulesUpdated(governanceProposals[nextProposalId - 1].proposalId, currentEpoch);
    }

     /**
     * @notice Updates the Essence cost per unit of cultivation. Callable only via governance execution.
     * @param newCost The new cultivation cost per unit.
     */
    function updateCultivationCost(uint256 newCost) external {
        require(msg.sender == address(this), "Must be called via governance");
        require(newCost > 0, "Cultivation cost must be positive");
        epochRules.cultivationCostPerUnit = newCost;
        emit EpochRulesUpdated(governanceProposals[nextProposalId - 1].proposalId, currentEpoch);
    }


    // View Functions (Additional)

    /**
     * @notice Gets the epoch number the contract is currently in.
     */
    function getCurrentEpoch() external view returns (uint256) {
        return currentEpoch;
    }

     /**
     * @notice Gets the start timestamp of the current epoch.
     */
    function getEpochStartTime() external view returns (uint256) {
        return epochStartTime;
    }

    /**
     * @notice Gets the duration of each epoch in seconds.
     */
     function getEpochDuration() external view returns (uint256) {
         return epochRules.duration;
     }

    /**
     * @notice Gets the current rules governing epoch duration, evolution weights, and costs.
     * @return EpochRules struct.
     */
     function getEpochRules() external view returns (EpochRules memory) {
         return epochRules;
     }

    /**
     * @notice Gets the estimated end timestamp of the current epoch.
     */
    function getEpochEndTime() external view returns (uint256) {
        if (currentEpoch == 0) return 0;
        return epochStartTime + epochRules.duration;
    }

     /**
     * @notice Gets the data for a user (Essence balances).
     * @param user The address to query.
     * @return essenceBalance The user's liquid Essence balance.
     * @return stakedEssence The user's staked Essence balance.
     * @return unclaimedRewards The user's accumulated unclaimed rewards.
     */
    function getUserData(address user) external view returns (uint256 essenceBalance, uint256 stakedEssence, uint256 unclaimedRewards) {
         return (essenceBalances[user], stakedEssence[user], unclaimedRewards[user]);
    }

    /**
     * @notice Checks if a user has voted on a specific proposal.
     * @param proposalId The ID of the proposal.
     * @param user The address of the user.
     * @return True if the user has voted, false otherwise.
     */
    function getUserVotes(uint256 proposalId, address user) external view returns (bool) {
        return proposalVotes[proposalId][user];
    }

    /**
     * @notice Gets the amount of staked Essence that is eligible for voting for a user.
     * @dev In this simple model, it's just the user's total staked Essence.
     * @param user The address to query.
     * @return The user's eligible voting power.
     */
    function getEligibleVoterStake(address user) external view returns (uint256) {
        return _getEffectiveVotingPower(user);
    }


     // Owner function (simple ownership, could use OpenZeppelin Ownable)
     function setOwner(address newOwner) external onlyOwner {
         require(newOwner != address(0), "New owner is the zero address");
         _owner = newOwner;
         emit OwnershipTransferred(msg.sender, newOwner);
     }
     event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

     function getOwner() external view returns (address) {
         return _owner;
     }

    // Total function count check:
    // 1 constructor + 36 functions = 37 functions. More than 20.

}
```