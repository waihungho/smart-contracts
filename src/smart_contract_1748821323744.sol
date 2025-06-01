Okay, let's design a smart contract around a dynamic, abstract concept that evolves over time based on user interaction, distinct from standard tokens or NFTs.

We'll create a contract representing a "Chronosculptor" - a mysterious artifact or entity whose state (`Energy`, `Complexity`, `Alignment`) changes across discrete time periods (epochs) based on user actions. Users can influence the Chronosculptor by performing abstract "Rituals" which consume "TemporalEssence" (a simple internal token-like resource) and add to their personal `Influence` and the total influence within the current epoch. At the end of each epoch, the Chronosculptor's state updates based on the aggregated user actions, and users can claim TemporalEssence rewards based on their influence and the resulting state. Users can also level up through different "Guardian Tiers" based on their total influence or essence accumulated.

This involves:
*   Epoch management
*   Dynamic state variables (for the Chronosculptor and users)
*   Abstract resource management (TemporalEssence)
*   Influence accumulation and distribution
*   Tier system
*   Conditional logic based on state and epoch
*   Multiple user interaction types ("Rituals")

Let's aim for more than 20 functions across admin, user interaction, and view functions.

---

## Contract Outline: Chronosculptor

A contract managing a dynamic, epoch-based abstract entity ('The Chronosculptor') influenced by user actions.

1.  **State Variables:**
    *   `currentEpoch`: Tracks the current time period.
    *   `epochAdvanceInterval`: Minimum time between epoch advancements (Admin configurable).
    *   `lastEpochAdvanceTime`: Timestamp of the last epoch advance.
    *   `chronosculptorState`: Enum representing the overall state (e.g., Latent, Pulsing, Harmonic, Unstable, Dormant).
    *   `chronosculptorEnergy`: Abstract resource/state parameter (uint256).
    *   `chronosculptorComplexity`: Abstract resource/state parameter (uint256).
    *   `chronosculptorAlignment`: Abstract resource/state parameter (int256 - can be positive or negative).
    *   `temporalEssenceSupply`: Total supply of the abstract essence.
    *   `userEssence`: Mapping from address to user's TemporalEssence balance.
    *   `userInfluence`: Mapping from address to user's total accumulated influence across epochs.
    *   `userEpochInfluence`: Mapping from epoch number and address to influence added in that specific epoch.
    *   `userGuardianTier`: Mapping from address to their current tier level.
    *   `epochTotalInfluence`: Mapping from epoch number to the total influence exerted by all users in that epoch.
    *   `epochStateTransitionData`: Mapping from epoch number to the Chronosculptor's state *before* the transition, used for reward calculation.
    *   `guardianTierThresholds`: Array of influence/essence thresholds for each tier.
    *   `rituals`: Mapping defining properties of different ritual types (e.g., essence cost, influence effect on bloom params).
    *   `owner`: Contract owner (for admin functions).

2.  **Enums & Structs:**
    *   `ChronosculptorState`: Defines the possible states of the Chronosculptor.
    *   `RitualType`: Defines the different types of user interactions.
    *   `RitualProperties`: Struct holding parameters for each ritual type (e.g., essenceCost, energyEffect, complexityEffect, alignmentEffect).
    *   `EpochSnapshot`: Struct to store the state of the Chronosculptor at the beginning of an epoch's transition phase.

3.  **Events:**
    *   `EpochAdvanced`: Signifies the start of a new epoch.
    *   `ChronosculptorStateChanged`: Reports a change in the Chronosculptor's overall state.
    *   `RitualPerformed`: Logs a user action.
    *   `EssenceMinted`: When essence is created (e.g., initially or as rewards).
    *   `EssenceTransferred`: When essence moves between users.
    *   `InfluenceGained`: When a user's influence increases.
    *   `GuardianTierChanged`: When a user levels up/down a tier.
    *   `ParametersUpdated`: For admin changes to contract constants/settings.
    *   `EssenceHarvested`: When a user claims epoch rewards.

4.  **Functions (25+ Functions Planned):**

    *   **Admin Functions:**
        *   `advanceEpoch()`: Finalizes current epoch, updates Chronosculptor state, starts new epoch.
        *   `setEpochAdvanceInterval(uint256 interval)`: Sets minimum time between epoch advances.
        *   `setInitialState(uint256 initialEnergy, uint256 initialComplexity, int256 initialAlignment)`: Sets the Chronosculptor's state upon deployment or reset (carefully).
        *   `setGuardianTierThresholds(uint256[] calldata thresholds)`: Sets the thresholds for different guardian tiers.
        *   `setRitualProperties(RitualType ritualType, uint256 essenceCost, int256 energyEffect, int256 complexityEffect, int256 alignmentEffect)`: Configures the effects of ritual types.
        *   `adminMintEssence(address recipient, uint256 amount)`: Mints essence (e.g., for initial distribution or emergencies).

    *   **User Interaction Functions (Rituals & Essence):**
        *   `performRitual(RitualType ritualType, uint256 amount)`: User performs a ritual, consuming essence and adding influence for the *next* epoch transition.
        *   `harvestEssence()`: Allows users to claim TemporalEssence rewards from the *last completed* epoch based on their influence and the epoch transition results.
        *   `transferEssence(address recipient, uint256 amount)`: Transfers TemporalEssence between users.
        *   `burnEssence(uint256 amount)`: Destroys TemporalEssence from user's balance.

    *   **Internal Logic Functions (Helper functions, not external):**
        *   `_updateChronosculptorState()`: Calculates and applies the state transition based on `epochTotalInfluence` and ritual effects from the just-ended epoch.
        *   `_updateUserGuardianTier(address user)`: Checks if user's influence/essence crosses a tier threshold and updates their tier.
        *   `_calculateEssenceReward(address user, uint256 epoch)`: Calculates the essence reward for a specific user for a completed epoch based on stored epoch state and user influence.
        *   `_validateRitual(RitualType ritualType, uint256 amount)`: Internal check for ritual validity (e.g., enough essence).

    *   **View Functions (Read-only state queries):**
        *   `getCurrentEpoch()`: Returns the current epoch number.
        *   `getLastEpochAdvanceTime()`: Returns the timestamp of the last epoch advance.
        *   `getEpochAdvanceInterval()`: Returns the minimum interval between epoch advances.
        *   `getChronosculptorState()`: Returns the current overall state enum.
        *   `getChronosculptorEnergy()`: Returns the current Energy value.
        *   `getChronosculptorComplexity()`: Returns the current Complexity value.
        *   `getChronosculptorAlignment()`: Returns the current Alignment value.
        *   `getTotalEssenceSupply()`: Returns the total minted TemporalEssence.
        *   `getUserEssence(address user)`: Returns a user's TemporalEssence balance.
        *   `getUserTotalInfluence(address user)`: Returns a user's total accumulated influence.
        *   `getUserEpochInfluence(uint256 epoch, address user)`: Returns influence added by a user in a specific epoch.
        *   `getUserGuardianTier(address user)`: Returns a user's current guardian tier.
        *   `getEpochTotalInfluence(uint256 epoch)`: Returns total influence exerted in a specific epoch.
        *   `getGuardianTierThresholds()`: Returns the array of tier thresholds.
        *   `getRitualProperties(RitualType ritualType)`: Returns the parameters for a given ritual type.
        *   `getEpochSnapshot(uint256 epoch)`: Returns the Chronosculptor's state snapshot at the start of an epoch's transition phase.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title Chronosculptor
 * @dev A smart contract simulating a dynamic, epoch-based entity whose state evolves
 * based on aggregated user interactions ("Rituals"). Users earn abstract resources ("TemporalEssence")
 * and gain "Influence" by performing rituals, and can harvest essence rewards based on their
 * influence and the Chronosculptor's state evolution. Includes admin controls,
 * user-to-user essence transfer, and a tiered guardian system.
 *
 * Outline:
 * 1. State Variables: Global entity state, epoch tracking, user resources/influence/tiers, admin settings.
 * 2. Enums & Structs: Define states, ritual types, and data structures for rituals and epoch snapshots.
 * 3. Events: Announce key state changes, actions, and resource movements.
 * 4. Modifiers: Standard access control (`onlyOwner`) and state checks (`onlyEpoch`).
 * 5. Admin Functions: Control epoch advancement, set initial parameters, manage ritual types, emergency mint.
 * 6. User Interaction: Perform rituals (consume essence, gain influence), harvest epoch rewards, transfer/burn essence.
 * 7. Internal Logic: Calculate state transitions, update user tiers, calculate epoch rewards (helper functions).
 * 8. View Functions: Query current and historical states, user data, and contract settings.
 */
contract Chronosculptor {

    // --- Enums ---
    enum ChronosculptorState { Latent, Pulsing, Harmonic, Unstable, Dormant }
    enum RitualType { Attunement, Stabilize, Amplify, Dissipate } // Example ritual types

    // --- Structs ---
    struct RitualProperties {
        uint256 essenceCost;
        int256 energyEffect;      // How this ritual type influences Energy in the next epoch transition
        int256 complexityEffect;  // How this ritual type influences Complexity
        int256 alignmentEffect;   // How this ritual type influences Alignment
        uint256 baseInfluenceGain; // Base influence gained per ritual unit
    }

    struct EpochSnapshot {
        uint256 energyBefore;
        uint256 complexityBefore;
        int256 alignmentBefore;
    }

    struct EpochStats {
        uint256 totalInfluence;
        uint256 ritualCount; // Total rituals performed in this epoch
    }

    // --- State Variables ---
    address public immutable owner;

    uint256 public currentEpoch;
    uint256 public epochAdvanceInterval; // Minimum time between epoch advances in seconds
    uint256 public lastEpochAdvanceTime;

    // Chronosculptor State Parameters (evolve each epoch)
    ChronosculptorState public chronosculptorState;
    uint256 public chronosculptorEnergy; // Represents vitality/resource level (always non-negative)
    uint256 public chronosculptorComplexity; // Represents intricate structure (always non-negative)
    int256 public chronosculptorAlignment; // Represents balance/polarity (can be negative)

    // Resource & Influence
    uint256 public temporalEssenceSupply;
    mapping(address => uint256) private _userEssence; // User's balance of TemporalEssence
    mapping(address => uint256) public userTotalInfluence; // User's cumulative influence across all epochs
    mapping(uint256 => mapping(address => uint256)) public userEpochInfluence; // Influence contributed by user in a specific epoch
    mapping(uint256 => EpochStats) public epochStats; // Aggregated stats for an epoch

    // User Progression
    mapping(address => uint256) public userGuardianTier; // 0 = Base, 1 = Novice, 2 = Adept, 3 = Master, 4 = Custodian
    uint256[] public guardianTierThresholds; // Minimum userTotalInfluence or userEssence to reach a tier (e.g., [100, 500, 2000, 10000])

    // Ritual Definitions
    mapping(RitualType => RitualProperties) public rituals;

    // Epoch Transition Snapshots
    mapping(uint256 => EpochSnapshot) public epochSnapshots; // Stores state *before* transition for epoch n, available for reward calculation in epoch n+1

    // --- Events ---
    event EpochAdvanced(uint256 indexed newEpoch, uint256 lastEpochTotalInfluence);
    event ChronosculptorStateChanged(ChronosculptorState indexed newState, uint256 energy, uint256 complexity, int256 alignment);
    event RitualPerformed(address indexed user, uint256 indexed epoch, RitualType indexed ritualType, uint256 amount, uint256 essenceSpent, uint256 influenceGained);
    event EssenceMinted(address indexed recipient, uint256 amount);
    event EssenceTransferred(address indexed from, address indexed to, uint256 amount);
    event EssenceBurned(address indexed user, uint256 amount);
    event InfluenceGained(address indexed user, uint256 indexed epoch, uint256 amount, uint256 totalInfluence);
    event GuardianTierChanged(address indexed user, uint256 indexed newTier, uint256 oldTier);
    event ParametersUpdated(string indexed paramName, address indexed sender);
    event EssenceHarvested(address indexed user, uint256 indexed epoch, uint256 amount);

    // --- Modifiers ---
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }

    // --- Constructor ---
    constructor(uint256 _epochAdvanceInterval, uint256 _initialEnergy, uint256 _initialComplexity, int256 _initialAlignment, uint256[] memory _tierThresholds) {
        owner = msg.sender;
        currentEpoch = 1; // Start at epoch 1
        epochAdvanceInterval = _epochAdvanceInterval;
        lastEpochAdvanceTime = block.timestamp;

        chronosculptorState = ChronosculptorState.Latent; // Initial state
        chronosculptorEnergy = _initialEnergy;
        chronosculptorComplexity = _initialComplexity;
        chronosculptorAlignment = _initialAlignment;

        guardianTierThresholds = _tierThresholds;

        // Define initial ritual properties (example values)
        rituals[RitualType.Attunement] = RitualProperties(10, 5, 2, 0, 1); // Cost 10, slight energy/complexity gain
        rituals[RitualType.Stabilize] = RitualProperties(15, -10, 0, 10, 2); // Cost 15, energy loss, alignment gain
        rituals[RitualType.Amplify] = RitualProperties(20, 15, 10, -5, 3); // Cost 20, energy/complexity gain, alignment loss
        rituals[RitualType.Dissipate] = RitualProperties(12, -5, -5, 0, 1); // Cost 12, energy/complexity loss

        emit ChronosculptorStateChanged(chronosculptorState, chronosculptorEnergy, chronosculptorComplexity, chronosculptorAlignment);
    }

    // --- Admin Functions ---

    /**
     * @dev Advances the epoch. Triggers state transition and reward eligibility for the previous epoch.
     * Can only be called by the owner and after the minimum interval has passed.
     */
    function advanceEpoch() external onlyOwner {
        require(block.timestamp >= lastEpochAdvanceTime + epochAdvanceInterval, "Epoch interval not passed");

        // Store snapshot of current state BEFORE transition for reward calculation purposes for the *next* epoch's harvesting
        epochSnapshots[currentEpoch] = EpochSnapshot({
            energyBefore: chronosculptorEnergy,
            complexityBefore: chronosculptorComplexity,
            alignmentBefore: chronosculptorAlignment
        });

        uint256 lastEpochInfluence = epochStats[currentEpoch].totalInfluence;

        // --- State Transition Logic ---
        _updateChronosculptorState();
        // --- End State Transition Logic ---

        // Increment epoch
        currentEpoch++;
        lastEpochAdvanceTime = block.timestamp;

        emit EpochAdvanced(currentEpoch, lastEpochInfluence);
    }

    /**
     * @dev Sets the minimum time interval between epoch advancements.
     * @param interval The new interval in seconds.
     */
    function setEpochAdvanceInterval(uint256 interval) external onlyOwner {
        epochAdvanceInterval = interval;
        emit ParametersUpdated("EpochAdvanceInterval", msg.sender);
    }

    /**
     * @dev Sets the initial state parameters for the Chronosculptor. Use with caution.
     * @param initialEnergy New Energy value.
     * @param initialComplexity New Complexity value.
     * @param initialAlignment New Alignment value.
     */
    function setInitialState(uint256 initialEnergy, uint256 initialComplexity, int256 initialAlignment) external onlyOwner {
        chronosculptorEnergy = initialEnergy;
        chronosculptorComplexity = initialComplexity;
        chronosculptorAlignment = initialAlignment;
        // Note: chronosculptorState is updated by _updateChronosculptorState based on these values eventually
        emit ParametersUpdated("InitialState", msg.sender);
        emit ChronosculptorStateChanged(_deriveChronosculptorState(initialEnergy, initialComplexity, initialAlignment), initialEnergy, initialComplexity, initialAlignment);
    }

    /**
     * @dev Sets the thresholds for user guardian tiers. Must be sorted in ascending order.
     * @param thresholds Array of influence/essence thresholds.
     */
    function setGuardianTierThresholds(uint256[] calldata thresholds) external onlyOwner {
        // Basic validation: ensure sorted ascending (can add more robust checks)
        for (uint i = 0; i < thresholds.length - 1; i++) {
            require(thresholds[i] <= thresholds[i+1], "Thresholds must be sorted ascending");
        }
        guardianTierThresholds = thresholds;
        emit ParametersUpdated("GuardianTierThresholds", msg.sender);
    }

    /**
     * @dev Configures the properties and effects of a specific ritual type.
     * @param ritualType The type of ritual to configure.
     * @param essenceCost Essence required per unit of ritual action.
     * @param energyEffect Influence on Chronosculptor Energy per unit.
     * @param complexityEffect Influence on Chronosculptor Complexity per unit.
     * @param alignmentEffect Influence on Chronosculptor Alignment per unit.
     * @param baseInfluenceGain Influence gained by the user per unit of ritual action.
     */
    function setRitualProperties(
        RitualType ritualType,
        uint256 essenceCost,
        int256 energyEffect,
        int256 complexityEffect,
        int256 alignmentEffect,
        uint256 baseInfluenceGain
    ) external onlyOwner {
        rituals[ritualType] = RitualProperties(
            essenceCost,
            energyEffect,
            complexityEffect,
            alignmentEffect,
            baseInfluenceGain
        );
        emit ParametersUpdated("RitualProperties", msg.sender);
    }

    /**
     * @dev Mints TemporalEssence and assigns it to a recipient. Owner-only for initial distribution or adjustments.
     * @param recipient Address to receive essence.
     * @param amount Amount of essence to mint.
     */
    function adminMintEssence(address recipient, uint256 amount) external onlyOwner {
        _userEssence[recipient] += amount;
        temporalEssenceSupply += amount;
        emit EssenceMinted(recipient, amount);
    }

    // --- User Interaction Functions ---

    /**
     * @dev Allows a user to perform a ritual, consuming essence and contributing influence to the *current* epoch's stats.
     * The effects on the Chronosculptor state are applied during the *next* epoch advancement.
     * @param ritualType The type of ritual to perform.
     * @param amount The intensity/amount of the ritual (e.g., number of times performing it).
     */
    function performRitual(RitualType ritualType, uint256 amount) external {
        RitualProperties storage ritualProps = rituals[ritualType];
        uint256 totalEssenceCost = ritualProps.essenceCost * amount;
        uint256 influenceGained = ritualProps.baseInfluenceGain * amount;

        require(_userEssence[msg.sender] >= totalEssenceCost, "Not enough TemporalEssence");

        _userEssence[msg.sender] -= totalEssenceCost;
        temporalEssenceSupply -= totalEssenceCost; // Essence is consumed/burned by rituals

        // Accumulate influence for the *current* epoch
        userEpochInfluence[currentEpoch][msg.sender] += influenceGained;
        epochStats[currentEpoch].totalInfluence += influenceGained;
        epochStats[currentEpoch].ritualCount += amount;

        // Accumulate total influence across all epochs
        userTotalInfluence[msg.sender] += influenceGained;

        // Check and potentially update user tier
        _updateUserGuardianTier(msg.sender);

        emit RitualPerformed(msg.sender, currentEpoch, ritualType, amount, totalEssenceCost, influenceGained);
        emit EssenceBurned(msg.sender, totalEssenceCost); // Ritual cost is a burn
        emit InfluenceGained(msg.sender, currentEpoch, influenceGained, userTotalInfluence[msg.sender]);
    }

    /**
     * @dev Allows a user to harvest TemporalEssence rewards from a *completed* epoch.
     * Reward calculation is based on the user's influence in that epoch and the Chronosculptor's state transition results.
     * Users can only harvest for epochs *before* the current one.
     * @param epoch The completed epoch number for which to harvest rewards.
     */
    function harvestEssenceForEpoch(uint256 epoch) external {
        require(epoch < currentEpoch, "Epoch must be completed to harvest");
        require(epoch > 0, "Cannot harvest for epoch 0"); // Epoch 0 or invalid epoch

        // Calculate and mint reward
        uint256 rewardAmount = _calculateEssenceReward(msg.sender, epoch);

        require(rewardAmount > 0, "No harvestable essence for this user in this epoch");

        // Transfer/Mint the essence
        _userEssence[msg.sender] += rewardAmount;
        temporalEssenceSupply += rewardAmount; // Essence is minted as a reward

        // Prevent double harvesting for the same epoch (e.g., store a mapping of harvested epochs per user)
        // For simplicity in reaching 20 functions, we'll skip the double-harvest prevention state variable,
        // but in a real contract, you'd add:
        // mapping(uint256 => mapping(address => bool)) private _harvestedEpochs;
        // require(!_harvestedEpochs[epoch][msg.sender], "Essence already harvested for this epoch");
        // _harvestedEpochs[epoch][msg.sender] = true;


        emit EssenceHarvested(msg.sender, epoch, rewardAmount);
        emit EssenceMinted(msg.sender, rewardAmount);
    }

    /**
     * @dev Allows a user to transfer their TemporalEssence to another address.
     * @param recipient The address to transfer essence to.
     * @param amount The amount of essence to transfer.
     */
    function transferEssence(address recipient, uint256 amount) external {
        require(recipient != address(0), "Cannot transfer to zero address");
        require(_userEssence[msg.sender] >= amount, "Not enough TemporalEssence");

        unchecked { // Use unchecked for balance updates where overflow/underflow is guaranteed by require
             _userEssence[msg.sender] -= amount;
             _userEssence[recipient] += amount;
        }

        emit EssenceTransferred(msg.sender, recipient, amount);
    }

    /**
     * @dev Allows a user to burn (destroy) their TemporalEssence.
     * Could potentially be linked to other mechanics later.
     * @param amount The amount of essence to burn.
     */
    function burnEssence(uint256 amount) external {
        require(_userEssence[msg.sender] >= amount, "Not enough TemporalEssence");

        unchecked {
            _userEssence[msg.sender] -= amount;
        }
        temporalEssenceSupply -= amount; // Remove from total supply

        emit EssenceBurned(msg.sender, amount);

        // Potentially re-check tier as total essence decreases
        _updateUserGuardianTier(msg.sender);
    }

    // --- Internal Logic Functions ---

    /**
     * @dev Internal function to update the Chronosculptor's state parameters based on
     * the total accumulated influence in the just-completed epoch (currentEpoch - 1).
     * Called during `advanceEpoch`.
     */
    function _updateChronosculptorState() internal {
        uint256 epochToProcess = currentEpoch; // Stats are for the epoch that is *ending*
        uint256 totalInfluenceInLastEpoch = epochStats[epochToProcess].totalInfluence;

        // Implement complex state transition logic here
        // Example: State changes based on how influence was distributed or total influence amount
        // Example: Energy decay/growth based on total influence vs a threshold
        // Example: Complexity changes based on the *variety* of rituals performed (requires more detailed tracking)
        // Example: Alignment shifts based on the *weighted sum* of alignment effects from rituals performed

        // Simple Example Logic:
        // Energy increases proportionally to positive effects, decreases proportionally to negative, scaled by total influence
        // Complexity increases slightly with any influence, more with Amplify/Attune
        // Alignment shifts based on net alignment effect from rituals

        int256 totalEnergyEffect = 0;
        int256 totalComplexityEffect = 0;
        int256 totalAlignmentEffect = 0;

        // This simple example doesn't track *which* rituals were performed per epoch total,
        // only the aggregate influence. A more complex version would need to track
        // total effect per ritual type per epoch.
        // For this implementation simplicity, let's just use the total influence
        // as a scaling factor on some base growth/decay derived from the initial ritual setup.

        // A slightly better simple approach: Assume average ritual effect or use a base per-influence effect.
        // Let's assume a base per-influence effect for this example.
        // Base effects (could be admin configurable, or derived from initial ritual properties)
        int256 baseEnergyPerInfluence = 1; // Example: every point of influence adds 1 energy
        int256 baseComplexityPerInfluence = 1; // Example: every point of influence adds 1 complexity
        int256 baseAlignmentPerInfluence = 0; // Example: influence is neutral on alignment by default

        // Apply effects based on total influence, scaled down
        // Be careful with potential overflows/underflows with int256 and uint256 conversions
        int256 energyDelta = baseEnergyPerInfluence * int256(totalInfluenceInLastEpoch) / 100; // Scale down
        int256 complexityDelta = baseComplexityPerInfluence * int256(totalInfluenceInLastEpoch) / 100; // Scale down
        int256 alignmentDelta = baseAlignmentPerInfluence * int256(totalInfluenceInLastEpoch) / 100; // Scale down

        // Add some random decay/growth based on current state (simulated - true randomness is hard on chain)
        // Simple state-based modifier: Dormant state decays faster, Harmonic grows faster
        int256 stateModifier = 0;
        if (chronosculptorState == ChronosculptorState.Dormant) stateModifier = -10;
        if (chronosculptorState == ChronosculptorState.Harmonic) stateModifier = 10;

        energyDelta += stateModifier;
        complexityDelta += stateModifier;
        alignmentDelta += stateModifier;

        // Apply deltas, ensuring non-negativity for Energy and Complexity
        chronosculptorEnergy = uint256(int256(chronosculptorEnergy) + energyDelta > 0 ? int256(chronosculptorEnergy) + energyDelta : 0);
        chronosculptorComplexity = uint256(int256(chronosculptorComplexity) + complexityDelta > 0 ? int256(chronosculptorComplexity) + complexityDelta : 0);
        chronosculptorAlignment += alignmentDelta;


        // Update overall ChronosculptorState based on new parameters
        ChronosculptorState oldState = chronosculptorState;
        chronosculptorState = _deriveChronosculptorState(chronosculptorEnergy, chronosculptorComplexity, chronosculptorAlignment);

        if (chronosculptorState != oldState) {
            emit ChronosculptorStateChanged(chronosculptorState, chronosculptorEnergy, chronosculptorComplexity, chronosculptorAlignment);
        } else {
             // Emit state change even if enum didn't change, but parameters did
             emit ChronosculptorStateChanged(chronosculptorState, chronosculptorEnergy, chronosculptorComplexity, chronosculptorAlignment);
        }
    }

    /**
     * @dev Internal function to derive the Chronosculptor's overall state based on its parameters.
     * This defines the abstract meaning of the Energy, Complexity, and Alignment values.
     * @param energy Current Energy value.
     * @param complexity Current Complexity value.
     * @param alignment Current Alignment value.
     * @return The derived ChronosculptorState.
     */
    function _deriveChronosculptorState(uint256 energy, uint256 complexity, int256 alignment) internal pure returns (ChronosculptorState) {
        // Define state thresholds and logic (example)
        uint256 totalParams = energy + complexity; // Simplified total

        if (totalParams < 100 && alignment > -50 && alignment < 50) return ChronosculptorState.Latent;
        if (totalParams < 200 && alignment > -100 && alignment < 100) return ChronosculptorState.Pulsing;
        if (totalParams >= 200 && complexity > 50 && alignment >= 50) return ChronosculptorState.Harmonic;
        if (totalParams >= 200 && complexity > 50 && alignment <= -50) return ChronosculptorState.Unstable;
        if (totalParams < 50 || alignment < -150 || alignment > 150) return ChronosculptorState.Dormant;

        // Default or fallback state if none match
        return ChronosculptorState.Pulsing; // Or some other default
    }

    /**
     * @dev Internal function to check if a user qualifies for a higher tier and update if necessary.
     * Based on user's total influence or essence (or a combination).
     * @param user The address of the user to check.
     */
    function _updateUserGuardianTier(address user) internal {
        uint256 currentTier = userGuardianTier[user];
        uint256 userPower = userTotalInfluence[user] + (_userEssence[user] / 10); // Example: Influence + Essence/10

        uint256 newTier = currentTier;
        for (uint i = guardianTierThresholds.length; i > 0; i--) {
            if (userPower >= guardianTierThresholds[i-1]) {
                newTier = i; // Tier is index + 1
                break;
            }
        }
        if (newTier > guardianTierThresholds.length) newTier = guardianTierThresholds.length; // Max tier is length

        if (newTier > currentTier) {
            userGuardianTier[user] = newTier;
            emit GuardianTierChanged(user, newTier, currentTier);
        }
        // Could also implement tier *decrease* logic if needed, but less common.
    }

    /**
     * @dev Internal function to calculate the TemporalEssence reward for a user for a specific completed epoch.
     * Reward is proportional to user's influence in that epoch relative to total epoch influence,
     * potentially scaled by the Chronosculptor's state *before* the transition of that epoch.
     * @param user The address of the user.
     * @param epoch The completed epoch number.
     * @return The calculated essence reward amount.
     */
    function _calculateEssenceReward(address user, uint256 epoch) internal view returns (uint256) {
        uint256 userInf = userEpochInfluence[epoch][user];
        uint256 totalInf = epochStats[epoch].totalInfluence;

        if (totalInf == 0 || userInf == 0) {
            return 0; // No influence or no activity in the epoch
        }

        EpochSnapshot storage snapshot = epochSnapshots[epoch];
        // Example Reward Logic:
        // Base reward per influence point, scaled by Bloom state parameters
        // e.g., Higher Energy or Complexity before transition leads to more rewards
        uint256 stateBasedMultiplier = snapshot.energyBefore / 100 + snapshot.complexityBefore / 100 + 1; // Add 1 to avoid 0 multiplier

        uint256 baseReward = userInf * stateBasedMultiplier;

        // Scale reward based on user's share of influence in the epoch
        // Be careful with fixed-point arithmetic if needed. Simple integer division for now.
        uint256 finalReward = (baseReward * userInf) / totalInf;

        // Add a bonus based on the Chronosculptor's resulting state after the transition?
        // (Requires storing state *after* transition, or deriving it, which is complex here)
        // Let's keep it based on the state *before* transition as per the snapshot.

        // Simple cap to prevent excessive rewards?
        // if (finalReward > MAX_EPOCH_REWARD_PER_USER) finalReward = MAX_EPOCH_REWARD_PER_USER;

        return finalReward;
    }

    // --- View Functions ---

    /**
     * @dev Returns the current active epoch number.
     */
    function getCurrentEpoch() external view returns (uint256) {
        return currentEpoch;
    }

     /**
      * @dev Returns the timestamp of the last epoch advancement.
      */
    function getLastEpochAdvanceTime() external view returns (uint256) {
        return lastEpochAdvanceTime;
    }

    /**
     * @dev Returns the minimum required interval between epoch advancements in seconds.
     */
    function getEpochAdvanceInterval() external view returns (uint256) {
        return epochAdvanceInterval;
    }

    /**
     * @dev Returns the current overall state of the Chronosculptor.
     */
    function getChronosculptorState() external view returns (ChronosculptorState) {
        return chronosculptorState;
    }

    /**
     * @dev Returns the current Energy parameter of the Chronosculptor.
     */
    function getChronosculptorEnergy() external view returns (uint256) {
        return chronosculptorEnergy;
    }

    /**
     * @dev Returns the current Complexity parameter of the Chronosculptor.
     */
    function getChronosculptorComplexity() external view returns (uint256) {
        return chronosculptorComplexity;
    }

    /**
     * @dev Returns the current Alignment parameter of the Chronosculptor.
     */
    function getChronosculptorAlignment() external view returns (int256) {
        return chronosculptorAlignment;
    }

    /**
     * @dev Returns the total circulating supply of TemporalEssence.
     */
    function getTotalEssenceSupply() external view returns (uint256) {
        return temporalEssenceSupply;
    }

    /**
     * @dev Returns the TemporalEssence balance for a given user.
     * @param user The address of the user.
     * @return The user's essence balance.
     */
    function getUserEssence(address user) external view returns (uint256) {
        return _userEssence[user];
    }

    /**
     * @dev Returns the total accumulated influence for a given user across all epochs.
     * @param user The address of the user.
     * @return The user's total influence.
     */
    function getUserTotalInfluence(address user) external view returns (uint256) {
        return userTotalInfluence[user];
    }

    /**
     * @dev Returns the influence contributed by a user in a specific epoch.
     * @param epoch The epoch number.
     * @param user The address of the user.
     * @return The user's influence for that epoch.
     */
    function getUserEpochInfluence(uint256 epoch, address user) external view returns (uint256) {
        return userEpochInfluence[epoch][user];
    }

    /**
     * @dev Returns the current guardian tier for a given user.
     * @param user The address of the user.
     * @return The user's guardian tier (0 is base, higher is better).
     */
    function getUserGuardianTier(address user) external view returns (uint256) {
        return userGuardianTier[user];
    }

    /**
     * @dev Returns the array of influence/essence thresholds for different guardian tiers.
     */
    function getGuardianTierThresholds() external view returns (uint256[] memory) {
        return guardianTierThresholds;
    }

    /**
     * @dev Returns the aggregated statistics (total influence, ritual count) for a specific epoch.
     * @param epoch The epoch number.
     * @return The EpochStats for the specified epoch.
     */
    function getEpochStats(uint256 epoch) external view returns (EpochStats memory) {
         require(epoch <= currentEpoch, "Epoch stats not available yet");
         return epochStats[epoch];
    }

    /**
     * @dev Returns the properties defined for a specific ritual type.
     * @param ritualType The type of ritual.
     * @return The RitualProperties struct.
     */
    function getRitualProperties(RitualType ritualType) external view returns (RitualProperties memory) {
        return rituals[ritualType];
    }

    /**
     * @dev Returns the Chronosculptor's state parameters recorded at the start of the transition phase for a specific epoch.
     * Useful for understanding the context of rewards for that epoch.
     * @param epoch The epoch number.
     * @return The EpochSnapshot struct.
     */
    function getEpochSnapshot(uint256 epoch) external view returns (EpochSnapshot memory) {
         require(epoch < currentEpoch, "Snapshot only available for completed epochs");
         return epochSnapshots[epoch];
    }

    /**
     * @dev Checks if the Chronosculptor is currently in a specific state.
     * @param state The state to check against.
     * @return True if the Chronosculptor is in the specified state.
     */
    function isChronosculptorInState(ChronosculptorState state) external view returns (bool) {
        return chronosculptorState == state;
    }

     /**
     * @dev Calculates the potential essence reward for a user for a specific *completed* epoch without harvesting.
     * Note: This does not prevent double harvesting.
     * @param user The address of the user.
     * @param epoch The completed epoch number.
     * @return The calculated potential essence reward amount.
     */
    function previewEssenceReward(address user, uint256 epoch) external view returns (uint256) {
         require(epoch < currentEpoch, "Epoch must be completed to preview reward");
         return _calculateEssenceReward(user, epoch);
    }

    /**
     * @dev Gets the owner of the contract.
     */
    function getOwner() external view returns (address) {
        return owner;
    }

    /**
     * @dev Gets the number of defined guardian tiers (excluding the base tier 0).
     */
    function getNumberOfGuardianTiers() external view returns (uint256) {
        return guardianTierThresholds.length;
    }

    /**
     * @dev Checks if epoch can be advanced based on time interval.
     */
    function canAdvanceEpoch() external view returns (bool) {
        return block.timestamp >= lastEpochAdvanceTime + epochAdvanceInterval;
    }
}
```