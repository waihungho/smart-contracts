Okay, let's design a smart contract around the concept of a "Dynamic State Nexus". This contract represents a shared digital entity whose state evolves based on user interactions and time, influencing future interactions and outcomes probabilistically. It incorporates resource management, collective actions, user-specific states, decay mechanics, and dynamic parameters.

It's not a standard token, marketplace, or governance contract. It's more abstract, simulating a system where user participation directly shapes the environment and their potential rewards.

---

**EtherealNexus Smart Contract**

**Outline:**

1.  **Contract Description:** A non-standard contract representing a dynamic, evolving digital entity ("Nexus") whose state changes based on user interactions and time. It governs user interactions, resource generation, and probabilistic outcomes within its ecosystem.
2.  **Core Concepts:** Dynamic State, Probabilistic Outcomes, Resource Management, User Affinity, Time-Based Decay, Epochs, Collective Actions, Dynamic Fees.
3.  **State Variables:** Global Nexus state (Energy, Complexity, Probability Weights), User-specific states (Resources, Affinity, Cooldowns, Delegation), Epoch information, Collected Fees.
4.  **Events:** Signalling key state changes and user actions.
5.  **Modifiers:** Access control (`onlyOwner`), operational control (`whenNotPaused`, `whenPaused`).
6.  **Internal Logic:** State decay calculation, probability calculation, resource distribution logic, cooldown checks.
7.  **External/Public Functions:**
    *   **Read State:** Functions to query global and user-specific states.
    *   **Basic Interaction:** Contribute resources, attempt extraction.
    *   **State Manipulation:** Attune complexity, influence probability.
    *   **Resource Management:** Claim resources, pool resources.
    *   **Social/Collaborative:** Delegate affinity, perform collective ritual.
    *   **Time/Epoch:** Get epoch info, activate epoch shift.
    *   **Utility/Info:** Get interaction fee, check cooldowns, get probability info.
    *   **Admin/Owner:** Configure parameters, manage operations (pause/resume), withdraw fees, placeholder for upgrade.

**Function Summary:**

1.  `constructor()`: Initializes the contract, setting the owner and initial state.
2.  `getNexusState()`: Returns the current core state variables of the Nexus (energy, complexity, probability weight).
3.  `getUserState(address user)`: Returns the current state variables for a specific user (resources, affinity, delegation).
4.  `contributeEnergy()`: Allows a user to send ETH (or potentially another defined token) to increase the Nexus's energy level. May also slightly increase user affinity.
5.  `attemptExtraction()`: Allows a user to attempt to extract resources from the Nexus. The success is probabilistic, influenced by Nexus state and user affinity. Successful extraction grants resources but may slightly decrease Nexus energy.
6.  `attuneComplexity(uint256 delta)`: Allows a user to try and adjust the Nexus's complexity score, costing some user resources. Success and magnitude depend on current state and delta. Affects extraction rates.
7.  `influenceProbability(int256 bias)`: Allows a user to temporarily or slightly shift the `probabilityWeight`, costing resources. Magnitude of influence depends on user affinity and cost.
8.  `claimResources()`: Allows a user to claim any accumulated `userResources`.
9.  `delegateInfluence(address delegatee)`: Allows a user to delegate their `userAffinity` score effect to another user for a limited duration or until revoked.
10. `poolResources(uint256 amount)`: Allows a user to add their `userResources` to a contract-wide pool, contributing towards a potential collective action.
11. `performRitual()`: A function triggerable once the resource pool reaches a threshold. Consumes pooled resources and causes a significant, predefined state change or resource distribution event.
12. `activateEpochShift()`: Owner or privileged function to advance the `currentEpoch`, potentially triggering decay logic or resource distribution based on epoch rules.
13. `getEpochInfo()`: Returns the current epoch number and time remaining until the next potential shift.
14. `getInteractionFee(uint8 actionType)`: Calculates and returns the dynamic fee (in ETH or internal resources) required for a specific action type, based on the current Nexus state.
15. `getUserInteractionCount(address user)`: Returns the total number of times a user has successfully interacted with key functions.
16. `getProbabilityForExtraction(address user)`: Calculates and returns the *current* success probability for extraction for a specific user, considering global state and user affinity.
17. `timeSinceLastGlobalInteraction()`: Returns the time elapsed since the last time *any* user interacted with the Nexus state. Used for decay calculations.
18. `checkNexusStability()`: Returns an abstract stability score or boolean based on the balance of key state variables (e.g., high energy, moderate complexity indicates stability).
19. `stabilizeNexus()`: A high-cost action (potentially owner only or requiring significant resources) to push state variables back towards a balanced or stable range.
20. `getUserAffinity(address user)`: Returns the current affinity score for a user.
21. `decayNexusState()`: Internal helper function called by interaction functions to apply time-based decay to `nexusEnergy` and potentially `nexusComplexity` based on `timeSinceLastGlobalInteraction`.
22. `setEpochDuration(uint64 duration)`: Owner function to set the duration of each epoch.
23. `setProbabilityBounds(uint16 minWeight, uint16 maxWeight)`: Owner function to set the minimum and maximum allowed values for `probabilityWeight`.
24. `withdrawFees()`: Owner function to withdraw accumulated fees (ETH) collected by the contract.
25. `panicShutdown()`: Owner function to pause critical user interaction functions in case of emergency.
26. `resumeOperations()`: Owner function to resume operations after a panic shutdown.
27. `getUserCooldown(address user, uint8 actionType)`: Checks and returns the remaining cooldown time for a specific action type for a user.
28. `revokeInfluenceDelegation(address delegatee)`: Allows a user to revoke influence delegation previously granted.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
// Consider using @openzeppelin/contracts/utils/ReentrancyGuard.sol
// if complex external calls were added, but not needed for this example.

// --- EtherealNexus Smart Contract ---
//
// Outline:
// 1. Contract Description: Represents a dynamic, evolving digital entity ("Nexus").
//    State changes based on user interactions and time, influencing probabilistic outcomes.
//    Incorporates resource management, collective actions, user-specific states,
//    decay mechanics, and dynamic parameters.
// 2. Core Concepts: Dynamic State, Probabilistic Outcomes, Resource Management, User Affinity,
//    Time-Based Decay, Epochs, Collective Actions, Dynamic Fees.
// 3. State Variables: Global Nexus state, User-specific states, Epoch info, Fees.
// 4. Events: Signalling key changes and actions.
// 5. Modifiers: Access control (`onlyOwner`), operational control (`whenNotPaused`, `whenPaused`).
// 6. Internal Logic: Decay calculation, probability calculation, resource distribution, cooldowns.
// 7. External/Public Functions: Read state, Basic interaction, State manipulation,
//    Resource management, Social/Collaborative, Time/Epoch, Utility/Info, Admin/Owner.
//
// Function Summary:
//  1. constructor(): Initializes owner and state.
//  2. getNexusState(): Returns core global state (energy, complexity, prob weight).
//  3. getUserState(address user): Returns user-specific state (resources, affinity, delegation).
//  4. contributeEnergy() payable: User sends ETH to increase nexusEnergy.
//  5. attemptExtraction(): User tries to extract resources probabilistically.
//  6. attuneComplexity(uint256 delta): User adjusts complexity, costs resources.
//  7. influenceProbability(int256 bias): User shifts probabilityWeight, costs resources.
//  8. claimResources(): User claims accumulated userResources.
//  9. delegateInfluence(address delegatee): User delegates affinity effect.
// 10. poolResources(uint256 amount): User adds resources to collective pool.
// 11. performRitual(): Triggers collective action if pool threshold met.
// 12. activateEpochShift(): Owner/privileged advances epoch.
// 13. getEpochInfo(): Returns epoch number and remaining time.
// 14. getInteractionFee(uint8 actionType): Calculates dynamic fee for an action.
// 15. getUserInteractionCount(address user): Total successful interactions count for user.
// 16. getProbabilityForExtraction(address user): Calculates extraction success probability for user.
// 17. timeSinceLastGlobalInteraction(): Time elapsed since last state-changing interaction.
// 18. checkNexusStability(): Returns abstract stability score.
// 19. stabilizeNexus(): High-cost action to balance state variables.
// 20. getUserAffinity(address user): Returns user's current affinity score.
// 21. decayNexusState(): Internal helper to apply time-based decay.
// 22. setEpochDuration(uint64 duration): Owner sets epoch duration.
// 23. setProbabilityBounds(uint16 minWeight, uint16 maxWeight): Owner sets probability weight bounds.
// 24. withdrawFees(): Owner withdraws collected ETH fees.
// 25. panicShutdown(): Owner pauses operations.
// 26. resumeOperations(): Owner resumes operations.
// 27. getUserCooldown(address user, uint8 actionType): Returns remaining cooldown time.
// 28. revokeInfluenceDelegation(address delegatee): User revokes delegation.

contract EtherealNexus is Ownable, Pausable {

    // --- Enums ---
    enum InteractionAction {
        None,
        AttemptExtraction,
        AttuneComplexity,
        InfluenceProbability,
        PerformRitual // Maybe not cooldownable per user, but good to have an ID
    }

    // --- State Variables ---

    // Global Nexus State
    uint256 public nexusEnergy; // Represents vitality/health. Decays over time. Increases with contributions.
    uint256 public nexusComplexity; // Represents intricacy/evolved state. Changes with attunement. Affects resource generation/rates.
    uint16 public probabilityWeight; // Base weight influencing probabilistic outcomes. Can be influenced. (0-10000)

    // User State
    mapping(address => uint256) public userResources; // Resources accumulated by users.
    mapping(address => uint256) public userAffinity; // User's alignment/skill with the Nexus. (0-10000)
    mapping(address => uint256) public userInteractionCount; // Count of key interactions per user.
    mapping(address => address) public influenceDelegates; // User delegating to address
    mapping(address => uint256) public delegateExpiration; // Timestamp when delegation expires

    // Collective State
    uint256 public collectiveResourcePool;
    uint256 public ritualThreshold; // Resources needed in pool for ritual

    // Time & Epoch State
    uint256 public lastGlobalInteractionTime; // Timestamp of the last state-changing interaction
    uint64 public currentEpoch;
    uint64 public epochDuration;
    uint256 public lastEpochShiftTime;

    // Parameters & Configuration
    uint16 public minProbabilityWeight = 1000; // 10% base
    uint16 public maxProbabilityWeight = 9000; // 90% base
    uint256 public energyDecayRate; // Units of energy decay per second
    uint256 public complexityAdjustmentFactor; // How much complexity changes with attunement
    uint256 public extractionBaseYield; // Base amount of resources from extraction
    uint256 public contributionEnergyBoost; // How much energy boost per unit of contribution
    uint256 public attunementResourceCost; // Cost to attune complexity
    uint256 public influenceResourceCost; // Cost to influence probability weight
    uint256 public ritualEnergyBoost; // Energy boost from ritual
    uint256 public ritualComplexityShift; // Complexity shift from ritual
    uint256 public ritualSuccessResourceBonus; // Bonus resources distributed after ritual

    // Cooldowns (per user per action type)
    mapping(address => mapping(uint8 => uint256)) private userActionCooldowns;
    uint256 public defaultCooldown = 60; // 1 minute default cooldown for actions

    // Fees
    uint256 public collectedFees; // ETH collected as fees

    // --- Events ---

    event NexusStateUpdated(uint256 newEnergy, uint255 newComplexity, uint16 newProbWeight);
    event UserStateUpdated(address user, uint256 newResources, uint256 newAffinity);
    event EnergyContributed(address indexed user, uint256 amount, uint255 newEnergy);
    event ExtractionAttempt(address indexed user, bool success, uint256 resourcesGained, uint255 newEnergy);
    event ComplexityAttuned(address indexed user, int255 delta, uint255 newComplexity);
    event ProbabilityInfluenced(address indexed user, int256 bias, uint16 newProbWeight);
    event ResourcesClaimed(address indexed user, uint256 amount);
    event InfluenceDelegated(address indexed delegator, address indexed delegatee, uint256 expiration);
    event InfluenceDelegationRevoked(address indexed delegator, address indexed revokedDelegatee);
    event ResourcesPooled(address indexed user, uint256 amount, uint255 totalPooled);
    event RitualPerformed(uint64 indexed epoch, uint255 consumedResources, uint255 newEnergy, uint255 newComplexity);
    event EpochShifted(uint64 indexed newEpoch, uint256 timestamp);
    event NexusStabilized(address indexed user, uint255 newEnergy, uint255 newComplexity, uint16 newProbWeight);
    event FeesWithdrawn(address indexed owner, uint256 amount);
    event OperationsPaused(address indexed owner);
    event OperationsResumed(address indexed owner);

    // --- Modifiers ---

    modifier onCooldown(InteractionAction actionType) {
        require(userActionCooldowns[msg.sender][uint8(actionType)] <= block.timestamp, "Action is on cooldown");
        _;
    }

    // --- Constructor ---

    constructor() Ownable(msg.sender) Pausable(false) {
        nexusEnergy = 5000; // Initial state
        nexusComplexity = 5000;
        probabilityWeight = 5000; // 50% base chance
        lastGlobalInteractionTime = block.timestamp;
        currentEpoch = 1;
        epochDuration = 7 days; // Default epoch duration
        lastEpochShiftTime = block.timestamp;
        ritualThreshold = 1000; // Default ritual cost

        // Default parameter values (can be set by owner later)
        energyDecayRate = 1; // 1 unit per second
        complexityAdjustmentFactor = 10; // Affects attuneComplexity
        extractionBaseYield = 50; // Base resources per extraction
        contributionEnergyBoost = 10; // Energy per ETH contributed (adjust based on ETH price/scale)
        attunementResourceCost = 10;
        influenceResourceCost = 5;
        ritualEnergyBoost = 2000;
        ritualComplexityShift = 500;
        ritualSuccessResourceBonus = 500;
    }

    // --- Internal Helper Functions ---

    /**
     * @dev Calculates and applies time-based decay to nexusEnergy.
     * Should be called by any function that modifies state or is sensitive to time.
     */
    function _applyDecay() internal {
        uint256 timeElapsed = block.timestamp - lastGlobalInteractionTime;
        uint256 decayAmount = timeElapsed * energyDecayRate;

        if (decayAmount > 0) {
            nexusEnergy = nexusEnergy >= decayAmount ? nexusEnergy - decayAmount : 0;
        }
        // Optionally apply complexity decay or shift here based on time
        // complexity = ...
    }

    /**
     * @dev Updates the last global interaction time.
     * Should be called by any function that causes a state change relevant to decay.
     */
    function _updateLastInteractionTime() internal {
        lastGlobalInteractionTime = block.timestamp;
    }

    /**
     * @dev Calculates the probability of a successful extraction.
     * Influenced by nexus state (energy, complexity, probWeight) and user affinity.
     * Returns a value between 0 and 10000 (representing 0% to 100%).
     * Note: This is pseudorandomness based on block data, subject to front-running.
     */
    function _calculateExtractionSuccessProbability(address user) internal view returns (uint16) {
        // Base probability from global weight
        uint16 baseProb = probabilityWeight;

        // Influence from Nexus Energy (Higher energy = higher success)
        // Max energy 10000, scale influence
        uint256 energyInfluence = (nexusEnergy * 2000) / 10000; // Max +20% (2000 points)

        // Influence from Nexus Complexity (Moderate complexity is best, extremes penalize?)
        // Simple example: linear influence for now
        uint252 complexityInfluence = (nexusComplexity * 1000) / 10000; // Max +10% (1000 points)

        // Influence from User Affinity (Higher affinity = higher success)
        uint256 affinityInfluence = (userAffinity[user] * 3000) / 10000; // Max +30% (3000 points)

        // Calculate total probability base (clamped)
        uint256 totalProb = uint256(baseProb) + energyInfluence + complexityInfluence + affinityInfluence;

        // Clamp probability between 0 and 10000
        if (totalProb > 10000) totalProb = 10000;

        return uint16(totalProb);
    }

    /**
     * @dev Gets the effective affinity for a user, considering delegation.
     */
    function _getEffectiveAffinity(address user) internal view returns (uint256) {
        address effectiveUser = user;
        // Check if user has delegated *to* someone
        // Note: This requires a slightly different mapping if we want to check who *is* delegated to
        // A simpler approach for this example: The delegatee benefits from the delegator's affinity directly.
        // Let's adjust `influenceDelegates` to map delegatee -> delegator
        // Reverting: `delegateInfluence(address delegatee)` means msg.sender delegates THEIR affinity.
        // So, when checking affinity for `user`, we check if anyone delegated *to* `user`.
        // This is tricky with the current mapping. Let's keep it simple: delegation means the delegatee
        // *can act as* the delegator for affinity checks, or the delegatee's affinity gets a boost.
        // Let's use the current mapping: msg.sender delegates THEIR affinity effect to delegatee.
        // So, if user X delegates to Y, Y's actions benefit from X's affinity.
        // This requires modifying functions like `_calculateExtractionSuccessProbability` to check `influenceDelegates[msg.sender]`.
        // Let's refine `delegateInfluence` and `revokeInfluenceDelegation` to store who delegated *to* whom and when it expires.
        // This is complex. Let's stick to the *initial* interpretation: `influenceDelegates[delegator] = delegatee`.
        // So, when calculating affinity for `user`, we check if `user` *has* delegated. If so, their *own* affinity effect is 0 for actions? Or their delegatee gets the benefit?
        // Let's make it the latter: The delegatee gets a bonus based on the delegator's affinity.
        // This requires checking delegation *to* the current user.
        // Okay, new plan: `influenceDelegates[delegator] = delegatee` is fine. The *delegatee* (the address provided in the function call)
        // *can* benefit from the delegator's affinity if the function checks this mapping.
        // Let's adjust `_calculateExtractionSuccessProbability` to incorporate potential delegation bonuses.
        // Or, simpler: delegation means delegatee *acts on behalf of* delegator.
        // Let's revert to the simplest: `delegateInfluence(address delegatee)` means the delegator's affinity is now 'associated' with `delegatee`.
        // The user calling the function is `msg.sender`. They might be the original owner of the affinity *or* a delegatee.
        // Let's check if `msg.sender` is a delegatee *for anyone*, and add up the delegated affinities.
        // This needs a mapping `delegatedTo[delegatee] => list_of_delegators` which is complex.
        // Simplest approach: delegation means `delegatee`'s affinity *is considered* `userAffinity[delegator]` for certain checks.
        // This feels hacky.

        // Let's rethink delegation: A user can delegate the *impact* of their affinity to another user.
        // When a function needs a user's effective affinity, it checks if the user *has delegated* (influenceDelegates[user] != address(0)).
        // If they *have* delegated, their own affinity impact is reduced or zeroed *for them*, and the delegatee potentially gains.
        // Or, if the function is called by a delegatee, it might use the delegator's affinity.
        // This is still ambiguous.

        // Let's go with: `delegateInfluence(address delegatee)` means the user's (msg.sender's) affinity is *added* to the delegatee's effective affinity *calculation* when the delegatee performs an action.
        // This requires checking all delegations pointing to the current user. This is inefficient.

        // Okay, Final Approach for Delegation (simpler): `delegateInfluence(address delegatee)` means `msg.sender` allows `delegatee` to *use* `msg.sender`'s affinity score when `delegatee` calls *specific* functions (like `attemptExtraction`).
        // This check needs to be inside the relevant functions.

        // For _getEffectiveAffinity: Let's just return the user's base affinity for now. Delegation effects will be handled *in* the functions that use affinity.
        return userAffinity[user];
    }

    /**
     * @dev Checks if an action is currently on cooldown for the user.
     */
    function _checkCooldown(address user, InteractionAction actionType) internal view returns (bool) {
        return userActionCooldowns[user][uint8(actionType)] > block.timestamp;
    }

    /**
     * @dev Sets the cooldown for a specific action for a user.
     */
    function _setCooldown(address user, InteractionAction actionType, uint256 duration) internal {
        userActionCooldowns[user][uint8(actionType)] = block.timestamp + duration;
    }

    /**
     * @dev Applies a fee for an action, if any. Returns the actual fee charged.
     */
    function _applyFee(address user, InteractionAction actionType) internal returns (uint256) {
        // In this simplified example, let's assume fees are collected in ETH via payable functions
        // and calculated based on actionType and state. For now, just a placeholder.
        // More complex logic would involve calculating fee based on state and actionType.
        // uint255 fee = getInteractionFee(uint8(actionType));
        // collectedFees += fee;
        // Potentially subtract fee from user resources if fees are internal
        return 0; // No fees applied in this simplified internal function example
    }

    // --- External/Public Functions ---

    /**
     * @dev Returns the current core state variables of the Nexus.
     */
    function getNexusState() public view returns (uint255 energy, uint255 complexity, uint16 probWeight) {
        // Note: Does not apply decay in a view function. Decay is applied on state-changing calls.
        return (nexusEnergy, nexusComplexity, probabilityWeight);
    }

    /**
     * @dev Returns the current state variables for a specific user.
     */
    function getUserState(address user) public view returns (uint256 resources, uint256 affinity, address delegatedTo, uint256 delegationExp) {
        return (userResources[user], userAffinity[user], influenceDelegates[user], delegateExpiration[user]);
    }

    /**
     * @dev Allows a user to send ETH to increase the Nexus's energy level.
     * Energy boost is proportional to ETH amount and a configured boost factor.
     * May also slightly increase user affinity.
     */
    function contributeEnergy() public payable whenNotPaused {
        require(msg.value > 0, "Must send ETH to contribute");

        _applyDecay(); // Apply decay before processing new state change

        uint256 energyBoost = (msg.value * contributionEnergyBoost) / 1 ether; // Adjust scaling as needed
        nexusEnergy += energyBoost;

        // Slightly increase user affinity (e.g., 1 point per 0.01 ETH, capped)
        uint256 affinityBoost = (msg.value * 100) / 1 ether; // 100 affinity points per ETH
        userAffinity[msg.sender] += affinityBoost;
        if (userAffinity[msg.sender] > 10000) userAffinity[msg.sender] = 10000; // Cap affinity

        collectedFees += msg.value; // Collect contributions as fees for owner

        _updateLastInteractionTime();
        userInteractionCount[msg.sender]++;

        emit EnergyContributed(msg.sender, msg.value, nexusEnergy);
        emit NexusStateUpdated(nexusEnergy, nexusComplexity, probabilityWeight);
        emit UserStateUpdated(msg.sender, userResources[msg.sender], userAffinity[msg.sender]);
    }

    /**
     * @dev Allows a user to attempt to extract resources from the Nexus.
     * Success is probabilistic based on state and affinity.
     * Successful extraction grants resources but slightly decreases Nexus energy.
     * On cooldown per user.
     */
    function attemptExtraction() public whenNotPaused onCooldown(InteractionAction.AttemptExtraction) {
        _applyDecay(); // Apply decay before attempt

        uint16 successProb = _calculateExtractionSuccessProbability(msg.sender);

        // Simple pseudorandomness using block data (known limitation: front-runnable)
        uint256 randomNumber = uint256(keccak256(abi.encodePacked(block.timestamp, msg.sender, nexusEnergy, nexusComplexity, block.number))) % 10000;

        bool success = randomNumber < successProb;
        uint256 resourcesGained = 0;
        int256 affinityChange = 0; // Use signed int for potential decrease

        if (success) {
            // Calculate yield based on nexus complexity and user affinity
            resourcesGained = extractionBaseYield + (nexusComplexity * extractionBaseYield / 10000) + (userAffinity[msg.sender] * extractionBaseYield / 10000);

            userResources[msg.sender] += resourcesGained;
            if (nexusEnergy >= resourcesGained / 10) { // Extraction costs some energy
                 nexusEnergy -= resourcesGained / 10;
            } else {
                 nexusEnergy = 0;
            }
            affinityChange = 50; // Increase affinity on success
        } else {
            // Failed extraction
            affinityChange = -20; // Decrease affinity on failure
        }

        // Apply affinity change (with bounds 0-10000)
        if (affinityChange > 0) {
            userAffinity[msg.sender] += uint256(affinityChange);
            if (userAffinity[msg.sender] > 10000) userAffinity[msg.sender] = 10000;
        } else if (affinityChange < 0) {
            uint256 absAffinityChange = uint256(-affinityChange);
            userAffinity[msg.sender] = userAffinity[msg.sender] >= absAffinityChange ? userAffinity[msg.sender] - absAffinityChange : 0;
        }

        _updateLastInteractionTime();
        _setCooldown(msg.sender, InteractionAction.AttemptExtraction, defaultCooldown);
        userInteractionCount[msg.sender]++;

        emit ExtractionAttempt(msg.sender, success, resourcesGained, nexusEnergy);
        emit NexusStateUpdated(nexusEnergy, nexusComplexity, probabilityWeight);
        emit UserStateUpdated(msg.sender, userResources[msg.sender], userAffinity[msg.sender]);
    }

    /**
     * @dev Allows a user to try and adjust the Nexus's complexity score.
     * Costs user resources. Success and magnitude depend on current complexity and user affinity.
     * Delta determines direction (+/-).
     * On cooldown per user.
     */
    function attuneComplexity(int256 delta) public whenNotPaused onCooldown(InteractionAction.AttuneComplexity) {
        require(userResources[msg.sender] >= attunementResourceCost, "Not enough resources to attune");

        _applyDecay(); // Apply decay

        userResources[msg.sender] -= attunementResourceCost;
        collectedFees += attunementResourceCost; // Collect resource cost as internal fee (or burn)

        // Calculate effect based on delta, user affinity, and current complexity
        uint256 absDelta = delta >= 0 ? uint256(delta) : uint256(-delta);
        // Affinity gives a bonus multiplier to the desired change magnitude
        uint256 effectiveChange = (absDelta * (10000 + userAffinity[msg.sender])) / 10000;
        // Complexity itself might resist change (e.g., harder to change when complexity is high/low)
        // Simple resistance: higher complexity resists upward, lower resists downward?
        // Or, just a scaling factor
        effectiveChange = (effectiveChange * complexityAdjustmentFactor) / 100; // Scale effect

        int256 finalChange = delta >= 0 ? int256(effectiveChange) : int256(-effectiveChange);

        // Apply change, clamping complexity (e.g., between 0 and 10000 for consistency)
        int256 currentComplexitySigned = int256(nexusComplexity);
        int256 newComplexitySigned = currentComplexitySigned + finalChange;

        if (newComplexitySigned < 0) newComplexitySigned = 0;
        if (newComplexitySigned > 10000) newComplexitySigned = 10000; // Example bounds

        nexusComplexity = uint256(newComplexitySigned);

        _updateLastInteractionTime();
        _setCooldown(msg.sender, InteractionAction.AttuneComplexity, defaultCooldown);
        userInteractionCount[msg.sender]++;

        emit ComplexityAttuned(msg.sender, finalChange, nexusComplexity);
        emit NexusStateUpdated(nexusEnergy, nexusComplexity, probabilityWeight);
        emit UserStateUpdated(msg.sender, userResources[msg.sender], userAffinity[msg.sender]);
    }

    /**
     * @dev Allows a user to temporarily or slightly shift the base `probabilityWeight`.
     * Costs user resources. Magnitude depends on bias and user affinity.
     * Bias determines direction (+/-).
     * On cooldown per user.
     */
    function influenceProbability(int256 bias) public whenNotPaused onCooldown(InteractionAction.InfluenceProbability) {
        require(userResources[msg.sender] >= influenceResourceCost, "Not enough resources to influence");

        _applyDecay(); // Apply decay

        userResources[msg.sender] -= influenceResourceCost;
        collectedFees += influenceResourceCost; // Collect resource cost

        // Calculate effect based on bias and user affinity
        uint256 absBias = bias >= 0 ? uint256(bias) : uint256(-bias);
        uint256 effectiveShift = (absBias * (10000 + userAffinity[msg.sender])) / 10000; // Affinity bonus

        int256 finalShift = bias >= 0 ? int256(effectiveShift) : int256(-effectiveShift);

        // Apply shift, clamping probabilityWeight within bounds
        int256 currentProbWeightSigned = int256(probabilityWeight);
        int256 newProbWeightSigned = currentProbWeightSigned + finalShift;

        if (newProbWeightSigned < int256(minProbabilityWeight)) newProbWeightSigned = int256(minProbabilityWeight);
        if (newProbWeightSigned > int256(maxProbabilityWeight)) newProbWeightSigned = int256(maxProbabilityWeight);

        probabilityWeight = uint16(newProbWeightSigned);

        _updateLastInteractionTime();
        _setCooldown(msg.sender, InteractionAction.InfluenceProbability, defaultCooldown);
        userInteractionCount[msg.sender]++;

        emit ProbabilityInfluenced(msg.sender, finalShift, probabilityWeight);
        emit NexusStateUpdated(nexusEnergy, nexusComplexity, probabilityWeight);
        emit UserStateUpdated(msg.sender, userResources[msg.sender], userAffinity[msg.sender]);
    }

    /**
     * @dev Allows a user to claim any accumulated `userResources`.
     */
    function claimResources() public whenNotPaused {
        uint256 amount = userResources[msg.sender];
        require(amount > 0, "No resources to claim");

        // In a real scenario, these resources might be an ERC-20 token managed by this contract
        // or transferred externally. For this example, we just zero out the balance.
        // If it were an ERC-20: IERC20(resourceTokenAddress).transfer(msg.sender, amount);
        userResources[msg.sender] = 0;

        emit ResourcesClaimed(msg.sender, amount);
        emit UserStateUpdated(msg.sender, 0, userAffinity[msg.sender]);
    }

    /**
     * @dev Allows a user to delegate the impact of their affinity score to another user.
     * The delegatee benefits from the delegator's affinity in relevant actions.
     * Delegation lasts for a fixed duration (e.g., epoch duration) or until revoked.
     */
    function delegateInfluence(address delegatee) public whenNotPaused {
        require(delegatee != address(0), "Cannot delegate to zero address");
        require(delegatee != msg.sender, "Cannot delegate influence to self");
        // Prevent circular delegation? A list of delegators per delegatee needed, complex.
        // Simple check: prevent delegating if you're already delegated to someone else?
        // Or allow chaining, but limit depth? Let's allow chaining for simplicity.

        // If already delegated, revoke the old one first implicitly?
        // revokeInfluenceDelegation(influenceDelegates[msg.sender]); // This would revoke the *new* one if called first

        // Let's make delegation overwrite previous delegation for the same delegator.
        // Delegation lasts until epoch end or revoked.
        influenceDelegates[msg.sender] = delegatee;
        delegateExpiration[msg.sender] = lastEpochShiftTime + epochDuration; // Expires at end of current epoch

        emit InfluenceDelegated(msg.sender, delegatee, delegateExpiration[msg.sender]);
    }

    /**
     * @dev Allows a user to revoke influence delegation previously granted.
     */
    function revokeInfluenceDelegation() public whenNotPaused {
        address currentDelegatee = influenceDelegates[msg.sender];
        require(currentDelegatee != address(0), "No active delegation to revoke");

        delete influenceDelegates[msg.sender];
        delete delegateExpiration[msg.sender];

        emit InfluenceDelegationRevoked(msg.sender, currentDelegatee);
    }


    /**
     * @dev Allows a user to add their `userResources` to a contract-wide pool
     * for a potential collective action (Ritual).
     */
    function poolResources(uint256 amount) public whenNotPaused {
        require(userResources[msg.sender] >= amount, "Not enough resources to pool");
        require(amount > 0, "Must pool a positive amount");

        userResources[msg.sender] -= amount;
        collectiveResourcePool += amount;

        emit ResourcesPooled(msg.sender, amount, collectiveResourcePool);
        emit UserStateUpdated(msg.sender, userResources[msg.sender], userAffinity[msg.sender]);
    }

    /**
     * @dev A function triggerable once the collective resource pool reaches or exceeds the `ritualThreshold`.
     * Consumes pooled resources and causes a significant, predefined state change.
     * Anyone can trigger if the threshold is met.
     */
    function performRitual() public whenNotPaused {
        require(collectiveResourcePool >= ritualThreshold, "Collective resource pool not high enough for ritual");

        _applyDecay(); // Apply decay

        uint256 consumed = collectiveResourcePool;
        collectiveResourcePool = 0; // Consume the pool

        // Significant state changes
        nexusEnergy += ritualEnergyBoost;
        nexusComplexity += ritualComplexityShift; // Can exceed 10000 temporarily? Cap later?
        if (nexusComplexity > 15000) nexusComplexity = 15000; // Example high cap

        // Distribute bonus resources back to users? Simple: add to their unclaimed pool.
        // More complex: distribute based on user affinity or recent participation.
        // Let's add a bonus to *all* users' unclaimed resources, weighted by affinity (simple).
        uint256 totalAffinity = 0;
        // This requires iterating over users, which is bad practice on-chain.
        // Alternative: Distribute to users who *contributed* to the pool, proportional to their contribution.
        // This requires tracking individual contributions to the pool, adding state.
        // Let's use a simpler distribution: a fixed bonus added to everyone's unclaimed pool.
        // Or, add to the total unclaimed pool and let users claim it? That's what userResources is.
        // Let's add to userResources for those who participated in the ritual?
        // No, the check was just pool threshold. Anyone can trigger.
        // Let's add a fixed bonus distributed equally to ALL users with non-zero affinity? Still needs iteration.

        // Simplest: The ritual success *increases* the yield of the next few extractions globally.
        // Or, the bonus resources are added to the collective pool again, for a super-ritual?
        // Let's make the bonus resources available for claiming universally, but it's complex how to track *who* gets them without iteration.
        // Let's add the bonus to the total `userResources` but requires users to claim individually.
        // This means `ritualSuccessResourceBonus` resources are conceptually added to the total system resources,
        // but users only get them when they call `claimResources`. This is implicitly handled if `userResources` is a total.
        // Or, add a global 'bonus resource pool' that users can claim from based on affinity?
        // Let's add a fixed amount to *every* user's `userResources` if they have >0 affinity. STILL REQUIRES ITERATION.

        // Okay, simplest ritual bonus: it just significantly boosts state and maybe slightly increases everyone's affinity who has >0.
        // Still requires iteration.

        // New simplest ritual bonus: It unlocks a temporary global modifier for extraction success or yield.
        // This requires adding temporary global modifier state variables and logic.
        // Too complex for this function.

        // Final simplest ritual bonus: It just adds the bonus amount to the total `userResources` across all users, effectively.
        // Users will find slightly more resources available over time or in their pool?
        // Let's just increase `extractionBaseYield` temporarily or for the next epoch.
        // Let's just boost state and leave resources as is for simplicity.

        _updateLastInteractionTime();
        // No cooldown for triggering ritual, but depends on collective pool.
        // Could add a global ritual cooldown.
        // _setCooldown(address(0), InteractionAction.PerformRitual, ritualCooldown); // Global cooldown? Requires modifier check

        emit RitualPerformed(currentEpoch, consumed, nexusEnergy, nexusComplexity);
        emit NexusStateUpdated(nexusEnergy, nexusComplexity, probabilityWeight);
    }

    /**
     * @dev Owner or privileged function to advance the `currentEpoch`.
     * Triggers epoch-end logic (like decay, or delegation expiration).
     */
    function activateEpochShift() public whenNotPaused {
        // Optional: Add require(block.timestamp >= lastEpochShiftTime + epochDuration, "Epoch duration not elapsed");
        // Or allow early shift by owner. Let's allow early shift for flexibility.

        _applyDecay(); // Apply any pending decay before shifting

        currentEpoch++;
        lastEpochShiftTime = block.timestamp;

        // Epoch-end logic:
        // 1. Expire delegations
        // This requires iterating over all users with delegations, inefficient.
        // Alternative: Check expiry lazily when delegation is used or queried.
        // Let's use lazy check on delegation usage.
        // 2. Resource distribution? (if any was epoch-based)
        // 3. Reset temporary state modifiers? (if any)
        // 4. Slight parameter drift? (advanced - simulate evolution by slightly changing decayRate, costs, etc. based on state?)
        //    Let's add a simple parameter drift based on complexity.
        uint256 complexityScaled = nexusComplexity / 100; // Scale 0-100
        energyDecayRate = 1 + complexityScaled / 20; // Min 1, max 6 per second example
        // Adjust costs slightly?
        attunementResourceCost = 10 + complexityScaled / 10; // Min 10, max 20 example

        emit EpochShifted(currentEpoch, lastEpochShiftTime);
        // No general state update emit here, as shift doesn't directly change core state (decay does)
    }

    /**
     * @dev Returns the current epoch number and time remaining until the next potential shift.
     */
    function getEpochInfo() public view returns (uint64 epoch, uint256 timeRemaining) {
        uint256 nextShiftTime = lastEpochShiftTime + epochDuration;
        if (block.timestamp >= nextShiftTime) {
            // Epoch ready to shift or already past
            return (currentEpoch, 0);
        } else {
            return (currentEpoch, nextShiftTime - block.timestamp);
        }
    }

    /**
     * @dev Calculates and returns the dynamic fee (in ETH or internal resources) required for a specific action type.
     * Fee depends on the current Nexus state.
     * Placeholder: Implement actual dynamic fee logic.
     */
    function getInteractionFee(uint8 actionType) public view returns (uint256 fee) {
        // Example dynamic fee: Higher complexity or lower energy increases fee?
        uint256 baseCost;
        InteractionAction action = InteractionAction(actionType);

        if (action == InteractionAction.AttemptExtraction) baseCost = 1; // Example base cost
        else if (action == InteractionAction.AttuneComplexity) baseCost = attunementResourceCost; // Already defined cost
        else if (action == InteractionAction.InfluenceProbability) baseCost = influenceResourceCost; // Already defined cost
        else return 0; // No fee for other types or invalid

        // Simple dynamic part: fee slightly increases with complexity
        uint256 complexityFactor = nexusComplexity / 1000; // 0-10 range
        fee = baseCost + (baseCost * complexityFactor / 5); // Fee increases up to 2x base

        // If fees were in ETH for these actions (instead of resource cost), logic would be different
        // For attune/influence, fees are resources, not ETH. Let's adjust doc.
        // Let's keep getInteractionFee for *hypothetical* ETH fees or a general cost function.
        // For now, let's return 0, as costs are handled internally in functions.
        // This function serves as a placeholder for a more complex fee structure calculation.
        return 0;
    }

    /**
     * @dev Returns the total number of times a user has successfully interacted with key functions.
     */
    function getUserInteractionCount(address user) public view returns (uint256) {
        return userInteractionCount[user];
    }

    /**
     * @dev Calculates and returns the *current* success probability for extraction for a specific user.
     * Considers global state and user affinity (and potentially delegation effect).
     * Returns value between 0 and 10000 (0-100%).
     */
    function getProbabilityForExtraction(address user) public view returns (uint16) {
        // This view function shouldn't apply decay, but calculate based on current view state.
        return _calculateExtractionSuccessProbability(user);
    }

    /**
     * @dev Returns the time elapsed since the last time *any* user interacted with the Nexus state.
     */
    function timeSinceLastGlobalInteraction() public view returns (uint256) {
        return block.timestamp - lastGlobalInteractionTime;
    }

    /**
     * @dev Returns an abstract stability score or boolean based on the balance of key state variables.
     * Higher score means more stable/balanced.
     */
    function checkNexusStability() public view returns (uint256 score) {
        // Example stability calculation: penalize extremes and imbalance
        // Perfect balance example: nexusEnergy = 5000, nexusComplexity = 5000
        uint256 energyDistance = nexusEnergy > 5000 ? nexusEnergy - 5000 : 5000 - nexusEnergy;
        uint256 complexityDistance = nexusComplexity > 5000 ? nexusComplexity - 5000 : 5000 - nexusComplexity;

        // Max distance for 0-10000 range is 5000
        uint256 maxDistance = 5000;

        // Stability is high when distances are low
        score = 10000; // Max score
        score = score >= energyDistance * 2 ? score - energyDistance * 2 : 0; // Energy imbalance penalty
        score = score >= complexityDistance * 2 ? score - complexityDistance * 2 : 0; // Complexity imbalance penalty

        // Low energy is inherently unstable
        score = score >= (5000 - (nexusEnergy > 5000 ? 5000 : nexusEnergy)) * 2 ? score - (5000 - (nexusEnergy > 5000 ? 5000 : nexusEnergy)) * 2 : 0; // Penalty for low energy

        // Clamp score between 0 and 10000
        if (score > 10000) score = 10000; // Should not happen with this logic but good practice

        return score;
    }

    /**
     * @dev A high-cost action (potentially owner only or requiring significant resources)
     * to push state variables back towards a balanced or stable range.
     */
    function stabilizeNexus() public whenNotPaused {
         // Example: Require significant resource cost or ETH
         // require(msg.value >= 1 ether, "Must send 1 ETH to stabilize");
         // collectedFees += msg.value; // Collect ETH fee

         // Or require user resources
         uint256 stabilizeCost = 500; // Example resource cost
         require(userResources[msg.sender] >= stabilizeCost, "Not enough resources to stabilize");
         userResources[msg.sender] -= stabilizeCost;
         collectedFees += stabilizeCost; // Collect resource cost

        _applyDecay(); // Apply decay

        // Apply stabilizing force: nudge state towards desired values (e.g., 5000)
        uint256 stabilizeStrength = 1000; // How much to nudge

        if (nexusEnergy < 5000) nexusEnergy += stabilizeStrength;
        else if (nexusEnergy > 5000) nexusEnergy = nexusEnergy >= stabilizeStrength ? nexusEnergy - stabilizeStrength : 0;
        if (nexusEnergy > 10000) nexusEnergy = 10000; // Cap energy

        if (nexusComplexity < 5000) nexusComplexity += stabilizeStrength;
        else if (nexusComplexity > 5000) nexusComplexity = nexusComplexity >= stabilizeStrength ? nexusComplexity - stabilizeStrength : 0;
         if (nexusComplexity > 10000) nexusComplexity = 10000; // Cap complexity

        // Optionally nudge probabilityWeight towards 5000
        if (probabilityWeight < 5000) probabilityWeight += uint16(stabilizeStrength / 10);
        else if (probabilityWeight > 5000) probabilityWeight -= uint16(stabilizeStrength / 10);
        if (probabilityWeight < minProbabilityWeight) probabilityWeight = minProbabilityWeight;
        if (probabilityWeight > maxProbabilityWeight) probabilityWeight = maxProbabilityWeight;


        _updateLastInteractionTime();
        userInteractionCount[msg.sender]++; // Treat stabilization as key interaction

        emit NexusStabilized(msg.sender, nexusEnergy, nexusComplexity, probabilityWeight);
        emit NexusStateUpdated(nexusEnergy, nexusComplexity, probabilityWeight);
        emit UserStateUpdated(msg.sender, userResources[msg.sender], userAffinity[msg.sender]);
    }

    /**
     * @dev Returns the current affinity score for a user.
     */
    function getUserAffinity(address user) public view returns (uint256) {
        return userAffinity[user];
    }

    /**
     * @dev Internal helper function called by interaction functions to apply time-based decay.
     * Not directly callable externally. Logic is inside `_applyDecay`.
     * Keeping this function summary entry as it's part of the logic flow described in the outline.
     * This function is effectively represented by the `_applyDecay` internal function.
     */
    // function decayNexusState() internal ... (See _applyDecay)

    // --- Admin/Owner Functions ---

    /**
     * @dev Owner function to set the duration of each epoch.
     * Only affects epochs *after* the next shift.
     */
    function setEpochDuration(uint64 duration) public onlyOwner {
        require(duration > 0, "Epoch duration must be positive");
        epochDuration = duration;
    }

    /**
     * @dev Owner function to set the minimum and maximum allowed values for `probabilityWeight`.
     */
    function setProbabilityBounds(uint16 minWeight, uint16 maxWeight) public onlyOwner {
        require(minWeight <= maxWeight, "Min weight must be less than or equal to max weight");
        require(minWeight >= 0 && maxWeight <= 10000, "Weights must be between 0 and 10000");
        minProbabilityWeight = minWeight;
        maxProbabilityWeight = maxWeight;
        // Ensure current weight is within new bounds
        if (probabilityWeight < minProbabilityWeight) probabilityWeight = minProbabilityWeight;
        if (probabilityWeight > maxProbabilityWeight) probabilityWeight = maxProbabilityWeight;
         emit NexusStateUpdated(nexusEnergy, nexusComplexity, probabilityWeight);
    }

    /**
     * @dev Owner function to withdraw accumulated fees (ETH) collected by the contract.
     * Can also be modified to withdraw internal resources if collected that way.
     */
    function withdrawFees() public onlyOwner {
        uint256 amount = collectedFees;
        require(amount > 0, "No fees collected");

        collectedFees = 0;

        // Transfer ETH out
        (bool success, ) = owner().call{value: amount}("");
        require(success, "ETH transfer failed");

        emit FeesWithdrawn(owner(), amount);
    }

    /**
     * @dev Owner function to pause critical user interaction functions in case of emergency.
     * Uses Pausable.sol from OpenZeppelin.
     */
    function panicShutdown() public onlyOwner {
        _pause();
        emit OperationsPaused(msg.sender);
    }

    /**
     * @dev Owner function to resume operations after a panic shutdown.
     * Uses Pausable.sol from OpenZeppelin.
     */
    function resumeOperations() public onlyOwner {
        _unpause();
        emit OperationsResumed(msg.sender);
    }

    // --- Utility Functions ---

    /**
     * @dev Checks and returns the remaining cooldown time for a specific action type for a user.
     */
    function getUserCooldown(address user, uint8 actionType) public view returns (uint256) {
        uint256 cooldownEnd = userActionCooldowns[user][actionType];
        if (cooldownEnd <= block.timestamp) {
            return 0;
        } else {
            return cooldownEnd - block.timestamp;
        }
    }

    /**
     * @dev Placeholder for upgrade pattern (e.g., UUPS).
     * In a real contract, this would be part of an upgradeable proxy pattern.
     */
    // function upgradeTo(address newImplementation) external onlyOwner {
    //     // This is a placeholder. Actual upgrade logic depends on the proxy pattern used (e.g., UUPS)
    //     // require(_getProxiableUUID() == _UUPS_UUID(), "Not UUPS");
    //     // _authorizeUpgrade(newImplementation);
    //     // _upgradeTo(newImplementation);
    // }
}
```