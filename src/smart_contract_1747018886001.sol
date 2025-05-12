Okay, let's design a smart contract that simulates an "Autonomous On-Chain Ecosystem Entity" (AOCE). This entity has various attributes that change over time (decay/regeneration), influenced by user interactions (feeding, stimulating, etc.), and can evolve through phases based on reaching certain thresholds defined by rules. It incorporates dynamic parameters, time-based mechanics, and configurable evolution logic, aiming for complexity beyond standard token or simple DeFi patterns.

It's important to note that simulating complex systems purely on-chain can be gas-intensive and has limitations regarding true randomness or off-chain interactions. This design focuses on the on-chain state management and rule-based transitions.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";

// --- Contract: Autonomous On-Chain Ecosystem Entity (AOCE) ---
//
// A smart contract simulating a digital entity whose state (attributes) evolves over time
// based on internal dynamics (decay/regeneration), external interactions (user contributions),
// and configurable rules. The entity can transition through different evolutionary phases.
//
// --- Outline ---
// 1. State Variables: Defines the entity's core attributes, phase, time tracking, and configuration parameters.
// 2. Structs: Defines data structures for entity state, phase configuration, evolution rules, and parameters.
// 3. Events: Logs significant actions like state updates, interactions, and phase evolution.
// 4. Modifiers: Custom modifiers for access control and state checks.
// 5. Core Logic (Internal): Functions for applying time-based dynamics and state updates.
// 6. Interaction Functions (External/Public): Allows users to interact and influence the entity's state.
// 7. Evolution Functions (External/Public): Manages the entity's transition between phases.
// 8. Configuration Functions (Owner-only): Allows the owner to set parameters, rules, and phase configurations.
// 9. Utility/View Functions (External/Public): Provides ways to query the entity's state and configuration.
// 10. Access Control & Withdrawal: Standard owner functions.
// 11. Receive/Fallback: Allows the contract to receive ETH.
//
// --- Function Summary ---
//
// CORE DYNAMICS & INTERACTION
// 1. pulse(): Updates the entity's state based on elapsed time since the last update. Anyone can call.
// 2. feed(): Users contribute ETH to increase specific "vitality" attributes (e.g., Health, Energy). Cost scales.
// 3. stimulate(): Users contribute ETH to increase "complexity" attributes (e.g., Complexity, MutationPotential). Cost scales.
// 4. influenceAttribute(): Users contribute ETH to specifically boost or reduce a chosen attribute, with dynamic impact.
// 5. registerInteraction(): Internal helper to record interaction time and contribute to influence pool.
// 6. calculateDynamicCost(): Internal helper to determine cost of interactions based on state.
//
// EVOLUTION
// 7. checkEvolutionReadiness(): View function to see if the entity meets criteria to evolve to the next phase.
// 8. triggerEvolution(): Allows the owner or authorized caller to evolve the entity to the next phase if ready.
// 9. addEvolutionRule(): Owner function to add a rule required for evolution readiness.
// 10. removeEvolutionRule(): Owner function to remove an evolution rule.
// 11. checkRuleCondition(): Internal helper to evaluate a single evolution rule.
// 12. evaluateEvolutionRules(): Internal helper to check all evolution rules.
//
// CONFIGURATION (Owner-only)
// 13. setBaseParameters(): Set default decay, regen, and influence multipliers.
// 14. setPhaseConfig(): Configure parameters (decay/regen/influence overrides, visual data) for a specific phase.
// 15. setDefaultInteractionCost(): Set the base cost for user interactions.
// 16. resetEntity(): Reset the entity to its initial state (Phase 0).
//
// UTILITY & VIEW
// 17. getCurrentState(): Get the current values of all entity attributes.
// 18. getLastUpdateTime(): Get the timestamp of the last state update.
// 19. getCurrentPhase(): Get the entity's current evolutionary phase ID.
// 20. getBaseParameters(): Get the current default decay, regen, and influence multipliers.
// 21. getPhaseConfig(): Get the configuration for a specific evolutionary phase.
// 22. getEvolutionRuleCount(): Get the total number of configured evolution rules.
// 23. getEvolutionRule(): Get the details of a specific evolution rule by index.
// 24. getInfluencePoolBalance(): Get the total ETH collected from interactions.
// 25. getInfluenceCost(): Get the current dynamic cost for standard interactions (`feed`, `stimulate`).
// 26. getTimeSinceLastUpdate(): Get the time elapsed since the last state update (helper for UI).
// 27. getEvolutionProgressPercentage(): Get an estimated percentage of evolution readiness based on current rules.
// 28. getPhaseSpecificParameters(): Get the effective parameters (decay, regen, influence) for the current phase.
// 29. predictFutureStateSimple(): View function to estimate state at a future time based *only* on decay/regen.
// 30. getSupportedAttributeCount(): Get the number of attributes the entity has.
// 31. getSupportedAttributeName(): Get the name string for a given attribute index.
// 32. getLastInteractionTime(): Get the timestamp of the last user interaction.
// 33. getAttributeNames(): Get the array of all attribute names.
// 34. getAttributeMinMax(): Get the min and max possible value for attributes.
//
// ACCESS & WITHDRAWAL
// 35. withdrawFees(): Owner function to withdraw ETH collected in the influence pool.
//
// RECEIVE ETH
// 36. receive(): Fallback function to receive plain ETH transfers.

contract AutonomousOnChainEntity is Ownable {

    // --- Structs ---

    struct EntityState {
        uint256[] attributes; // e.g., Health, Energy, Complexity, MutationPotential, Age
        uint256 currentPhase;
    }

    struct Parameters {
        int256[] decayRates; // How much each attribute decays per second (can be negative for growth)
        int256[] regenRates; // How much each attribute regenerates per second (can be negative for decay)
        uint256[] influenceMultipliers; // How much user ETH influences each attribute (per wei)
    }

    struct PhaseConfig {
        string name; // e.g., "Seedling", "Juvenile", "Mature"
        string description;
        Parameters phaseParameters; // Override base parameters for this phase (use max(0, value) if negative means "use base")
        bool useBaseDecay; // If true, use baseParameters.decayRates instead of phaseParameters.decayRates
        bool useBaseRegen; // If true, use baseParameters.regenRates instead of phaseParameters.regenRates
        bool useBaseInfluence; // If true, use baseParameters.influenceMultipliers instead of phaseParameters.influenceMultipliers
        bool isFinalPhase; // If true, entity cannot evolve further
    }

    // Enum for rule comparison types
    enum RuleComparison {
        GreaterThan, // >
        LessThan, // <
        EqualTo, // ==
        GreaterThanOrEqualTo, // >=
        LessThanOrEqualTo // <=
    }

    struct EvolutionRule {
        uint256 attributeIndex; // Index of the attribute being checked
        RuleComparison comparison; // Type of comparison
        uint256 value; // Value to compare against
    }

    // --- State Variables ---

    EntityState public entityState;
    uint256 public lastUpdateTime;
    uint256 public lastInteractionTime;
    uint256 public influencePool; // Accumulated ETH from user interactions

    // Configuration Parameters (base values)
    Parameters public baseParameters;
    uint256 public defaultInteractionCost; // Base cost in wei for interactions

    // Phase Configurations (Mapping phase ID to its config)
    mapping(uint256 => PhaseConfig) public phaseConfigs;
    uint256 public totalPhasesConfigured; // Tracks the highest configured phase ID + 1

    // Evolution Rules (Rules entity must satisfy to evolve)
    EvolutionRule[] public evolutionRules;

    // Entity Attributes (Names for clarity)
    string[] private _attributeNames;
    uint256 public immutable ATTRIBUTE_COUNT;
    uint256 public immutable ATTRIBUTE_MAX_VALUE = 1000;
    uint256 public immutable ATTRIBUTE_MIN_VALUE = 0;

    // Mapping for attribute names (index -> name) for easier lookup
    mapping(uint256 => string) private attributeNameMap;

    // --- Events ---

    event StateUpdated(uint256 indexed phase, uint256[] newState, uint256 timeElapsed);
    event Interaction(address indexed user, string interactionType, uint256 ethAmount, uint256[] newState);
    event PhaseEvolved(uint256 indexed oldPhase, uint256 indexed newPhase, uint256[] newState);
    event ParametersUpdated(string paramType);
    event PhaseConfigUpdated(uint256 indexed phase);
    event EvolutionRuleAdded(uint256 indexed ruleIndex, uint256 attributeIndex, RuleComparison comparison, uint256 value);
    event EvolutionRuleRemoved(uint256 indexed ruleIndex);
    event EntityReset(uint256[] initialState);
    event FeesWithdrawn(address indexed owner, uint256 amount);
    event EntityReceivedETH(address indexed sender, uint256 amount);

    // --- Modifiers ---

    modifier onlyWhenReadyForEvolution() {
        require(checkEvolutionReadiness(), "AOCE: Not ready for evolution");
        _;
    }

    // --- Constructor ---

    constructor(address initialOwner, string[] memory attributeNames) Ownable(initialOwner) {
        require(attributeNames.length > 0, "AOCE: Must define attributes");

        _attributeNames = attributeNames;
        ATTRIBUTE_COUNT = _attributeNames.length;

        // Initialize attribute name map
        for (uint i = 0; i < ATTRIBUTE_COUNT; i++) {
            attributeNameMap[i] = _attributeNames[i];
        }

        // Initialize entity state with default values (e.g., ATTRIBUTE_MAX_VALUE / 2)
        entityState.attributes = new uint256[](ATTRIBUTE_COUNT);
        for (uint i = 0; i < ATTRIBUTE_COUNT; i++) {
            entityState.attributes[i] = ATTRIBUTE_MAX_VALUE / 2;
        }
        entityState.currentPhase = 0;

        lastUpdateTime = block.timestamp;
        lastInteractionTime = block.timestamp; // Assume initial state is like an interaction occurred

        // Initialize base parameters (can be set later by owner)
        baseParameters.decayRates = new int256[](ATTRIBUTE_COUNT);
        baseParameters.regenRates = new int256[](ATTRIBUTE_COUNT);
        baseParameters.influenceMultipliers = new uint256[](ATTRIBUTE_COUNT);
        // Default: No decay, no regen, no influence
        for (uint i = 0; i < ATTRIBUTE_COUNT; i++) {
             baseParameters.decayRates[i] = 0;
             baseParameters.regenRates[i] = 0;
             baseParameters.influenceMultipliers[i] = 0;
        }

        // Default interaction cost (can be set later by owner)
        defaultInteractionCost = 0.001 ether; // Example: 0.001 ETH

        // Initialize Phase 0 configuration (can be updated by owner)
        PhaseConfig memory initialPhase;
        initialPhase.name = "Genesis";
        initialPhase.description = "The initial state of the entity.";
        initialPhase.phaseParameters = baseParameters; // Use base parameters initially
        initialPhase.useBaseDecay = true;
        initialPhase.useBaseRegen = true;
        initialPhase.useBaseInfluence = true;
        initialPhase.isFinalPhase = false;
        phaseConfigs[0] = initialPhase;
        totalPhasesConfigured = 1;

        emit StateUpdated(entityState.currentPhase, entityState.attributes, 0);
    }

    // --- Core Logic (Internal) ---

    /**
     * @dev Internal function to update the entity's state based on elapsed time.
     * Applies decay and regeneration based on the current phase's effective parameters.
     * Clamps attribute values between MIN_VALUE and MAX_VALUE.
     * @return timeElapsed The actual time duration applied in the update.
     */
    function _updateStateInternal() internal returns (uint256 timeElapsed) {
        uint256 currentTime = block.timestamp;
        timeElapsed = currentTime - lastUpdateTime;

        if (timeElapsed == 0) {
            return 0; // No time has passed, no update needed
        }

        // Get effective parameters for the current phase
        Parameters memory effectiveParams = getPhaseSpecificParametersInternal();

        for (uint i = 0; i < ATTRIBUTE_COUNT; i++) {
            // Calculate change from decay/regen
            int256 decayChange = effectiveParams.decayRates[i] * int256(timeElapsed);
            int256 regenChange = effectiveParams.regenRates[i] * int256(timeElapsed);

            // Apply changes, ensuring we don't overflow/underflow uint256 prematurely
            int256 currentAttr = int256(entityState.attributes[i]);
            int256 newAttr = currentAttr - decayChange + regenChange;

            // Clamp values
            if (newAttr < int256(ATTRIBUTE_MIN_VALUE)) {
                entityState.attributes[i] = ATTRIBUTE_MIN_VALUE;
            } else if (newAttr > int256(ATTRIBUTE_MAX_VALUE)) {
                entityState.attributes[i] = ATTRIBUTE_MAX_VALUE;
            } else {
                entityState.attributes[i] = uint256(newAttr);
            }
        }

        lastUpdateTime = currentTime;
        emit StateUpdated(entityState.currentPhase, entityState.attributes, timeElapsed);
        return timeElapsed;
    }

    /**
     * @dev Internal helper to get the effective parameters for the current phase,
     * considering phase-specific overrides and base parameters.
     */
    function getPhaseSpecificParametersInternal() internal view returns (Parameters memory) {
        PhaseConfig storage currentConfig = phaseConfigs[entityState.currentPhase];
        Parameters memory effectiveParams;
        effectiveParams.decayRates = new int256[](ATTRIBUTE_COUNT);
        effectiveParams.regenRates = new int256[](ATTRIBUTE_COUNT);
        effectiveParams.influenceMultipliers = new uint256[](ATTRIBUTE_COUNT);

        for (uint i = 0; i < ATTRIBUTE_COUNT; i++) {
            effectiveParams.decayRates[i] = currentConfig.useBaseDecay ? baseParameters.decayRates[i] : currentConfig.phaseParameters.decayRates[i];
            effectiveParams.regenRates[i] = currentConfig.useBaseRegen ? baseParameters.regenRates[i] : currentConfig.phaseParameters.regenRates[i];
            effectiveParams.influenceMultipliers[i] = currentConfig.useBaseInfluence ? baseParameters.influenceMultipliers[i] : currentConfig.phaseParameters.influenceMultipliers[i];
        }
        return effectiveParams;
    }


    // --- Interaction Functions (External/Public) ---

    /**
     * @notice Pushes the entity's state forward based on elapsed time.
     * Can be called by anyone to 'refresh' the state on-chain.
     */
    function pulse() external {
        _updateStateInternal();
    }

    /**
     * @notice Users contribute ETH to increase attributes typically associated with vitality (e.g., Health, Energy).
     * Requires sending at least the dynamic interaction cost.
     * Excess ETH is added to the influence pool.
     * @param attributeIndices The indices of attributes to influence.
     * @param influenceAmounts The amount of influence points to apply to each attribute.
     *        Note: ETH sent translates into influence points based on multiplier and attributeIndex.
     *        The user specifies *how many* influence points they want to apply to *which* attribute,
     *        and the contract checks if the ETH sent is sufficient based on dynamic cost and multipliers.
     */
    function feed(uint256[] calldata attributeIndices, uint256[] calldata influenceAmounts) external payable {
        require(attributeIndices.length == influenceAmounts.length, "AOCE: Mismatched input lengths");
        require(msg.value >= calculateDynamicCost(), "AOCE: Insufficient ETH sent");

        _updateStateInternal(); // Update state before applying influence

        Parameters memory effectiveParams = getPhaseSpecificParametersInternal();
        uint256 totalCost = 0;

        for (uint i = 0; i < attributeIndices.length; i++) {
            uint256 attrIndex = attributeIndices[i];
            require(attrIndex < ATTRIBUTE_COUNT, "AOCE: Invalid attribute index");

            uint256 influencePoints = influenceAmounts[i];
            uint256 multiplier = effectiveParams.influenceMultipliers[attrIndex];

            if (multiplier == 0) continue; // Cannot influence if multiplier is zero

            // Calculate required ETH for this specific influence amount
            // cost = influencePoints / multiplier (rounded up)
            uint256 requiredEth = (influencePoints + multiplier - 1) / multiplier;
            totalCost = totalCost + requiredEth;

            // Apply influence (add to attribute)
            // Handle potential overflow before adding
            uint256 currentAttr = entityState.attributes[attrIndex];
            uint256 maxPossible = ATTRIBUTE_MAX_VALUE - currentAttr;
            uint256 pointsToAdd = Math.min(influencePoints, maxPossible);

            entityState.attributes[attrIndex] = entityState.attributes[attrIndex] + pointsToAdd;
        }

        require(msg.value >= totalCost, "AOCE: Insufficient ETH sent for requested influence");

        // Add remaining ETH to influence pool
        influencePool = influencePool + (msg.value - totalCost);

        registerInteraction();
        emit Interaction(msg.sender, "Feed", msg.value, entityState.attributes);
        emit StateUpdated(entityState.currentPhase, entityState.attributes, 0); // Log final state after influence
    }

    /**
     * @notice Users contribute ETH to increase attributes typically associated with complexity (e.g., Complexity, MutationPotential).
     * Functions similarly to `feed` but might target different attributes conceptually.
     * Requires sending at least the dynamic interaction cost.
     * Excess ETH is added to the influence pool.
     * @param attributeIndices The indices of attributes to influence.
     * @param influenceAmounts The amount of influence points to apply to each attribute.
     */
    function stimulate(uint256[] calldata attributeIndices, uint256[] calldata influenceAmounts) external payable {
         require(attributeIndices.length == influenceAmounts.length, "AOCE: Mismatched input lengths");
        require(msg.value >= calculateDynamicCost(), "AOCE: Insufficient ETH sent");

        _updateStateInternal(); // Update state before applying influence

        Parameters memory effectiveParams = getPhaseSpecificParametersInternal();
        uint256 totalCost = 0;

        for (uint i = 0; i < attributeIndices.length; i++) {
            uint256 attrIndex = attributeIndices[i];
            require(attrIndex < ATTRIBUTE_COUNT, "AOCE: Invalid attribute index");

            uint256 influencePoints = influenceAmounts[i];
             uint256 multiplier = effectiveParams.influenceMultipliers[attrIndex];

            if (multiplier == 0) continue; // Cannot influence if multiplier is zero

            uint256 requiredEth = (influencePoints + multiplier - 1) / multiplier;
            totalCost = totalCost + requiredEth;

            // Apply influence (add to attribute)
            uint256 currentAttr = entityState.attributes[attrIndex];
            uint256 maxPossible = ATTRIBUTE_MAX_VALUE - currentAttr;
            uint256 pointsToAdd = Math.min(influencePoints, maxPossible);

            entityState.attributes[attrIndex] = entityState.attributes[attrIndex] + pointsToAdd;
        }

        require(msg.value >= totalCost, "AOCE: Insufficient ETH sent for requested influence");
        influencePool = influencePool + (msg.value - totalCost);

        registerInteraction();
        emit Interaction(msg.sender, "Stimulate", msg.value, entityState.attributes);
        emit StateUpdated(entityState.currentPhase, entityState.attributes, 0); // Log final state after influence
    }

     /**
     * @notice Allows users to attempt to influence a *single* specific attribute, potentially with a higher multiplier
     * or different logic based on the implementation's design for this function vs feed/stimulate.
     * For this example, it works similar to feed/stimulate but focuses on a single attribute.
     * Requires sending at least the dynamic interaction cost.
     * Excess ETH is added to the influence pool.
     * @param attributeIndex The index of the attribute to influence.
     * @param influenceAmount The amount of influence points to apply.
     */
    function influenceAttribute(uint256 attributeIndex, uint256 influenceAmount) external payable {
        require(attributeIndex < ATTRIBUTE_COUNT, "AOCE: Invalid attribute index");
        require(msg.value >= calculateDynamicCost(), "AOCE: Insufficient ETH sent");

        _updateStateInternal(); // Update state before applying influence

        Parameters memory effectiveParams = getPhaseSpecificParametersInternal();
        uint256 multiplier = effectiveParams.influenceMultipliers[attributeIndex];

        if (multiplier == 0) {
             influencePool = influencePool + msg.value; // Refund if cannot influence
             emit Interaction(msg.sender, "InfluenceAttribute_Refund", msg.value, entityState.attributes);
             registerInteraction();
             return; // Cannot influence if multiplier is zero
        }

        uint256 requiredEth = (influenceAmount + multiplier - 1) / multiplier;
        require(msg.value >= requiredEth, "AOCE: Insufficient ETH sent for requested influence amount");

        // Apply influence (add to attribute)
        uint256 currentAttr = entityState.attributes[attributeIndex];
        uint256 maxPossible = ATTRIBUTE_MAX_VALUE - currentAttr;
        uint256 pointsToAdd = Math.min(influenceAmount, maxPossible);

        entityState.attributes[attributeIndex] = entityState.attributes[attributeIndex] + pointsToAdd;

        // Add remaining ETH to influence pool
        influencePool = influencePool + (msg.value - requiredEth);

        registerInteraction();
        emit Interaction(msg.sender, "InfluenceAttribute", msg.value, entityState.attributes);
        emit StateUpdated(entityState.currentPhase, entityState.attributes, 0); // Log final state after influence
    }

    /**
     * @dev Internal function to update the last interaction time.
     */
    function registerInteraction() internal {
        lastInteractionTime = block.timestamp;
    }

    /**
     * @notice Calculates the current dynamic cost required for standard user interactions (`feed`, `stimulate`, `influenceAttribute`).
     * This cost could potentially be influenced by the entity's state (e.g., higher cost when state is critical).
     * Current implementation is simple, just returns the default cost. Can be extended.
     * @return costInWei The required ETH amount in wei.
     */
    function calculateDynamicCost() public view returns (uint256 costInWei) {
        // Example of dynamic cost: base cost + small amount based on current phase * complexity
        // return defaultInteractionCost + (entityState.currentPhase * 1 ether / 100) + (entityState.attributes[1] / 100); // Assuming complexity is attribute 1
        return defaultInteractionCost; // Simple implementation for now
    }


    // --- Evolution Functions (External/Public) ---

    /**
     * @notice Checks if the entity currently meets all conditions defined in the evolution rules
     * and if a configuration exists for the next phase.
     * Does NOT update state or trigger evolution.
     * @return bool True if the entity is ready to evolve, false otherwise.
     */
    function checkEvolutionReadiness() public view returns (bool) {
        // Entity cannot evolve if it's in a final phase or no next phase is configured
        if (entityState.currentPhase >= totalPhasesConfigured - 1) {
             // Check if current phase config is final
             if (phaseConfigs[entityState.currentPhase].isFinalPhase) return false;
             // Check if next phase config exists
             if (phaseConfigs[entityState.currentPhase + 1].name == "") return false; // Simple check if config exists
        }

        return evaluateEvolutionRules();
    }

    /**
     * @notice Triggers the evolution of the entity to the next phase.
     * Requires the entity to be ready for evolution based on `checkEvolutionReadiness`.
     * Can be called by the owner or potentially other authorized addresses.
     * @dev Note: The design assumes evolution is manual trigger by owner/privileged role
     * once criteria are met. Could be changed to automatic within `pulse` or interactions
     * but adds complexity and gas costs to those functions.
     */
    function triggerEvolution() external onlyOwner onlyWhenReadyForEvolution {
        _updateStateInternal(); // Ensure state is updated before evolution criteria check

        uint256 oldPhase = entityState.currentPhase;
        uint256 newPhase = oldPhase + 1;

        // Optional: Apply transformation rules for the new phase? (e.g., reset some attributes)
        // For simplicity, just update the phase and attributes carry over.
        // Could add logic here based on newPhase config.

        entityState.currentPhase = newPhase;
        lastUpdateTime = block.timestamp; // Reset update time for the new phase's dynamics

        emit PhaseEvolved(oldPhase, newPhase, entityState.attributes);
        emit StateUpdated(entityState.currentPhase, entityState.attributes, 0);
    }

    /**
     * @notice Owner function to add a new rule that must be met for the entity to evolve.
     * Rules are checked against the entity's current attributes.
     * @param attributeIndex The index of the attribute to check.
     * @param comparison The comparison type (e.g., GreaterThan, LessThan).
     * @param value The value to compare the attribute against.
     */
    function addEvolutionRule(uint256 attributeIndex, RuleComparison comparison, uint256 value) external onlyOwner {
        require(attributeIndex < ATTRIBUTE_COUNT, "AOCE: Invalid attribute index");
        evolutionRules.push(EvolutionRule({
            attributeIndex: attributeIndex,
            comparison: comparison,
            value: value
        }));
        emit EvolutionRuleAdded(evolutionRules.length - 1, attributeIndex, comparison, value);
    }

    /**
     * @notice Owner function to remove an evolution rule by its index.
     * @param ruleIndex The index of the rule to remove.
     */
    function removeEvolutionRule(uint256 ruleIndex) external onlyOwner {
        require(ruleIndex < evolutionRules.length, "AOCE: Invalid rule index");
        // Simple removal by swapping with the last element (order doesn't matter)
        EvolutionRule memory ruleToRemove = evolutionRules[ruleIndex];
        evolutionRules[ruleIndex] = evolutionRules[evolutionRules.length - 1];
        evolutionRules.pop();
        emit EvolutionRuleRemoved(ruleIndex);
    }

    /**
     * @dev Internal helper function to check if a single rule condition is met.
     */
    function checkRuleCondition(uint256 attributeValue, EvolutionRule memory rule) internal pure returns (bool) {
        if (rule.comparison == RuleComparison.GreaterThan) {
            return attributeValue > rule.value;
        } else if (rule.comparison == RuleComparison.LessThan) {
            return attributeValue < rule.value;
        } else if (rule.comparison == RuleComparison.EqualTo) {
            return attributeValue == rule.value;
        } else if (rule.comparison == RuleComparison.GreaterThanOrEqualTo) {
            return attributeValue >= rule.value;
        } else if (rule.comparison == RuleComparison.LessThanOrEqualTo) {
            return attributeValue <= rule.value;
        }
        return false; // Should not happen with valid enum
    }

    /**
     * @dev Internal helper function to evaluate all evolution rules against the current state.
     * @return bool True if all rules are met, false otherwise.
     */
    function evaluateEvolutionRules() internal view returns (bool) {
        if (evolutionRules.length == 0) {
            return true; // If no rules are set, entity is always ready
        }
        for (uint i = 0; i < evolutionRules.length; i++) {
            EvolutionRule memory rule = evolutionRules[i];
            uint256 attributeValue = entityState.attributes[rule.attributeIndex];
            if (!checkRuleCondition(attributeValue, rule)) {
                return false; // At least one rule is not met
            }
        }
        return true; // All rules are met
    }


    // --- Configuration Functions (Owner-only) ---

    /**
     * @notice Owner function to set the base decay rates, regeneration rates, and influence multipliers.
     * These apply unless overridden by a phase-specific configuration.
     * @param decayRates Array of decay rates (per second). Use negative for growth.
     * @param regenRates Array of regeneration rates (per second). Use negative for decay.
     * @param influenceMultipliers Array of influence multipliers (influence points per wei).
     */
    function setBaseParameters(int256[] calldata decayRates, int256[] calldata regenRates, uint256[] calldata influenceMultipliers) external onlyOwner {
        require(decayRates.length == ATTRIBUTE_COUNT && regenRates.length == ATTRIBUTE_COUNT && influenceMultipliers.length == ATTRIBUTE_COUNT, "AOCE: Mismatched array lengths");
        baseParameters.decayRates = decayRates;
        baseParameters.regenRates = regenRates;
        baseParameters.influenceMultipliers = influenceMultipliers;
        emit ParametersUpdated("Base");
    }

    /**
     * @notice Owner function to configure or update a specific evolutionary phase.
     * Allows setting phase-specific parameters or using base parameters.
     * Automatically updates `totalPhasesConfigured` if a new highest phase is set.
     * @param phaseId The ID of the phase to configure.
     * @param config The PhaseConfig struct containing the configuration.
     */
    function setPhaseConfig(uint256 phaseId, PhaseConfig calldata config) external onlyOwner {
        require(config.phaseParameters.decayRates.length == 0 || config.phaseParameters.decayRates.length == ATTRIBUTE_COUNT, "AOCE: Phase decay rates length mismatch");
        require(config.phaseParameters.regenRates.length == 0 || config.phaseParameters.regenRates.length == ATTRIBUTE_COUNT, "AOCE: Phase regen rates length mismatch");
        require(config.phaseParameters.influenceMultipliers.length == 0 || config.phaseParameters.influenceMultipliers.length == ATTRIBUTE_COUNT, "AOCE: Phase influence multipliers length mismatch");

        // Copy config data
        PhaseConfig storage currentConfig = phaseConfigs[phaseId];
        currentConfig.name = config.name;
        currentConfig.description = config.description;
        currentConfig.isFinalPhase = config.isFinalPhase;

        // Deep copy parameters if provided, otherwise they'll be empty arrays and `useBase` flags handle it
        if (config.phaseParameters.decayRates.length == ATTRIBUTE_COUNT) currentConfig.phaseParameters.decayRates = config.phaseParameters.decayRates;
        if (config.phaseParameters.regenRates.length == ATTRIBUTE_COUNT) currentConfig.phaseParameters.regenRates = config.phaseParameters.regenRates;
        if (config.phaseParameters.influenceMultipliers.length == ATTRIBUTE_COUNT) currentConfig.phaseParameters.influenceMultipliers = config.phaseParameters.influenceMultipliers;

        currentConfig.useBaseDecay = config.useBaseDecay;
        currentConfig.useBaseRegen = config.useBaseRegen;
        currentConfig.useBaseInfluence = config.useBaseInfluence;

        if (phaseId >= totalPhasesConfigured) {
            totalPhasesConfigured = phaseId + 1;
        }

        emit PhaseConfigUpdated(phaseId);
    }

    /**
     * @notice Owner function to set the base cost required for user interactions (feed, stimulate, influenceAttribute).
     * This is the minimum ETH required to call these functions.
     * @param costInWei The new default interaction cost in wei.
     */
    function setDefaultInteractionCost(uint256 costInWei) external onlyOwner {
        defaultInteractionCost = costInWei;
        emit ParametersUpdated("InteractionCost");
    }

     /**
     * @notice Owner function to reset the entity's state back to its initial values (Phase 0).
     * This can be used to restart the simulation.
     */
    function resetEntity() external onlyOwner {
        entityState.currentPhase = 0;
        for (uint i = 0; i < ATTRIBUTE_COUNT; i++) {
            entityState.attributes[i] = ATTRIBUTE_MAX_VALUE / 2; // Reset to initial values
        }
        lastUpdateTime = block.timestamp;
        lastInteractionTime = block.timestamp;
        influencePool = 0; // Reset influence pool
        // Note: Parameters, phase configs, and evolution rules are NOT reset

        emit EntityReset(entityState.attributes);
        emit StateUpdated(entityState.currentPhase, entityState.attributes, 0);
    }


    // --- Utility/View Functions (External/Public) ---

    /**
     * @notice Returns the current state of the entity's attributes.
     * @dev Does NOT update state before returning. Call `pulse()` first for the absolute latest state.
     * @return attributes_ The current values of all attributes.
     */
    function getCurrentState() external view returns (uint256[] memory attributes_) {
        return entityState.attributes;
    }

     /**
     * @notice Returns the timestamp of the last time the entity's state was updated by time progression.
     */
    function getLastUpdateTime() external view returns (uint256) {
        return lastUpdateTime;
    }

     /**
     * @notice Returns the timestamp of the last time a user interaction occurred (`feed`, `stimulate`, `influenceAttribute`).
     */
    function getLastInteractionTime() external view returns (uint256) {
        return lastInteractionTime;
    }

    /**
     * @notice Returns the entity's current evolutionary phase ID.
     */
    function getCurrentPhase() external view returns (uint256) {
        return entityState.currentPhase;
    }

    /**
     * @notice Returns the base (default) parameters for decay, regeneration, and influence.
     * @return decayRates_ Array of decay rates.
     * @return regenRates_ Array of regeneration rates.
     * @return influenceMultipliers_ Array of influence multipliers.
     */
    function getBaseParameters() external view returns (int256[] memory decayRates_, int256[] memory regenRates_, uint256[] memory influenceMultipliers_) {
        return (baseParameters.decayRates, baseParameters.regenRates, baseParameters.influenceMultipliers);
    }

    /**
     * @notice Returns the configuration details for a specific evolutionary phase.
     * @param phaseId The ID of the phase to query.
     * @return config The PhaseConfig struct for the requested phase.
     */
    function getPhaseConfig(uint256 phaseId) external view returns (PhaseConfig memory config) {
         // Return default empty struct if phaseId hasn't been configured explicitly
         if (phaseConfigs[phaseId].name == "" && phaseId != 0) {
            return config; // Return zero-initialized struct
         }
         // Deep copy the parameters array from storage
         PhaseConfig storage storedConfig = phaseConfigs[phaseId];
         config.name = storedConfig.name;
         config.description = storedConfig.description;
         config.isFinalPhase = storedConfig.isFinalPhase;
         config.useBaseDecay = storedConfig.useBaseDecay;
         config.useBaseRegen = storedConfig.useBaseRegen;
         config.useBaseInfluence = storedConfig.useBaseInfluence;

         // Copy parameter arrays if they exist
         if (storedConfig.phaseParameters.decayRates.length > 0) {
             config.phaseParameters.decayRates = storedConfig.phaseParameters.decayRates;
         } else {
             config.phaseParameters.decayRates = new int256[](0); // Return empty array if not configured
         }
         if (storedConfig.phaseParameters.regenRates.length > 0) {
             config.phaseParameters.regenRates = storedConfig.phaseParameters.regenRates;
         } else {
             config.phaseParameters.regenRates = new int256[](0);
         }
          if (storedConfig.phaseParameters.influenceMultipliers.length > 0) {
             config.phaseParameters.influenceMultipliers = storedConfig.phaseParameters.influenceMultipliers;
         } else {
             config.phaseParameters.influenceMultipliers = new uint256[](0);
         }
         return config;
    }


    /**
     * @notice Returns the total number of evolution rules currently configured.
     */
    function getEvolutionRuleCount() external view returns (uint256) {
        return evolutionRules.length;
    }

    /**
     * @notice Returns the details of a specific evolution rule by its index.
     * @param index The index of the rule.
     * @return attributeIndex_ The index of the attribute checked by the rule.
     * @return comparison_ The comparison type of the rule.
     * @return value_ The value the attribute is compared against.
     */
    function getEvolutionRule(uint256 index) external view returns (uint256 attributeIndex_, RuleComparison comparison_, uint256 value_) {
        require(index < evolutionRules.length, "AOCE: Invalid rule index");
        EvolutionRule storage rule = evolutionRules[index];
        return (rule.attributeIndex, rule.comparison, rule.value);
    }

    /**
     * @notice Returns the total amount of ETH collected in the influence pool from user interactions.
     */
    function getInfluencePoolBalance() external view returns (uint256) {
        return influencePool;
    }

    /**
     * @notice Returns the current required ETH cost for standard user interactions (`feed`, `stimulate`, `influenceAttribute`).
     * @return costInWei The cost in wei.
     */
    function getInfluenceCost() external view returns (uint256) {
        return calculateDynamicCost();
    }

    /**
     * @notice Returns the time elapsed in seconds since the entity's state was last updated by time progression.
     */
    function getTimeSinceLastUpdate() external view returns (uint256) {
        return block.timestamp - lastUpdateTime;
    }

    /**
     * @notice Provides an estimated percentage of how close the entity is to meeting evolution rules.
     * This is a simplified metric (e.g., average percentage of rules met). Can be complex.
     * @dev Simple implementation: counts how many rules are met and returns percentage of total rules.
     * @return percentage The estimated readiness percentage (0-100).
     */
    function getEvolutionProgressPercentage() external view returns (uint256 percentage) {
        if (evolutionRules.length == 0) {
            return 100; // Always ready if no rules
        }
        uint256 metRulesCount = 0;
        for (uint i = 0; i < evolutionRules.length; i++) {
            EvolutionRule memory rule = evolutionRules[i];
            uint256 attributeValue = entityState.attributes[rule.attributeIndex];
            if (checkRuleCondition(attributeValue, rule)) {
                metRulesCount++;
            }
        }
        return (metRulesCount * 100) / evolutionRules.length;
    }

     /**
     * @notice Returns the effective parameters (decay, regen, influence) applied to the entity
     * in its current evolutionary phase. These account for phase-specific overrides.
     * @return decayRates_ Array of decay rates.
     * @return regenRates_ Array of regeneration rates.
     * @return influenceMultipliers_ Array of influence multipliers.
     */
    function getPhaseSpecificParameters() external view returns (int256[] memory decayRates_, int256[] memory regenRates_, uint256[] memory influenceMultipliers_) {
        Parameters memory effectiveParams = getPhaseSpecificParametersInternal();
        return (effectiveParams.decayRates, effectiveParams.regenRates, effectiveParams.influenceMultipliers);
    }

    /**
     * @notice Attempts to predict the entity's state at a future timestamp, assuming NO user interactions occur
     * and NO phase evolution happens. This is a simplified view for estimation.
     * @param futureTimestamp The timestamp in the future to predict.
     * @return predictedAttributes The predicted attribute values.
     */
    function predictFutureStateSimple(uint256 futureTimestamp) external view returns (uint256[] memory predictedAttributes) {
        require(futureTimestamp >= lastUpdateTime, "AOCE: Future timestamp must be >= last update time");
        uint256 timeElapsed = futureTimestamp - lastUpdateTime;

        predictedAttributes = new uint256[](ATTRIBUTE_COUNT);
        Parameters memory effectiveParams = getPhaseSpecificParametersInternal();

        for (uint i = 0; i < ATTRIBUTE_COUNT; i++) {
            int256 decayChange = effectiveParams.decayRates[i] * int256(timeElapsed);
            int256 regenChange = effectiveParams.regenRates[i] * int256(timeElapsed);

            int256 currentAttr = int256(entityState.attributes[i]);
            int256 predictedAttr = currentAttr - decayChange + regenChange;

             // Clamp values in prediction
            if (predictedAttr < int256(ATTRIBUTE_MIN_VALUE)) {
                predictedAttributes[i] = ATTRIBUTE_MIN_VALUE;
            } else if (predictedAttr > int256(ATTRIBUTE_MAX_VALUE)) {
                predictedAttributes[i] = ATTRIBUTE_MAX_VALUE;
            } else {
                predictedAttributes[i] = uint256(predictedAttr);
            }
        }
        return predictedAttributes;
    }

    /**
     * @notice Returns the total number of attributes the entity has.
     */
    function getSupportedAttributeCount() external view returns (uint256) {
        return ATTRIBUTE_COUNT;
    }

    /**
     * @notice Returns the name string for a given attribute index.
     * @param index The attribute index.
     * @return name The name of the attribute.
     */
    function getSupportedAttributeName(uint256 index) external view returns (string memory name) {
         require(index < ATTRIBUTE_COUNT, "AOCE: Invalid attribute index");
         return attributeNameMap[index];
    }

     /**
     * @notice Returns the array of all attribute names.
     * @return names The array of attribute names.
     */
    function getAttributeNames() external view returns (string[] memory names) {
        // Return a copy to avoid state modification issues if _attributeNames was public
        names = new string[](ATTRIBUTE_COUNT);
        for(uint i = 0; i < ATTRIBUTE_COUNT; i++){
            names[i] = _attributeNames[i];
        }
        return names;
    }

    /**
     * @notice Returns the minimum and maximum possible values for attributes.
     * @return min The minimum value.
     * @return max The maximum value.
     */
    function getAttributeMinMax() external view returns (uint256 min, uint256 max) {
        return (ATTRIBUTE_MIN_VALUE, ATTRIBUTE_MAX_VALUE);
    }


    // --- Access Control & Withdrawal ---

    /**
     * @notice Allows the contract owner to withdraw accumulated ETH from the influence pool.
     */
    function withdrawFees() external onlyOwner {
        uint256 amount = influencePool;
        require(amount > 0, "AOCE: No fees to withdraw");
        influencePool = 0;
        (bool success, ) = payable(owner()).call{value: amount}("");
        require(success, "AOCE: Fee withdrawal failed");
        emit FeesWithdrawn(owner(), amount);
    }

    // --- Receive ETH ---

    /**
     * @notice Allows the contract to receive plain ETH transfers.
     * These transfers are added to the influence pool.
     */
    receive() external payable {
        influencePool = influencePool + msg.value;
        emit EntityReceivedETH(msg.sender, msg.value);
    }

    // --- Fallback (Optional but good practice) ---
    fallback() external payable {
        influencePool = influencePool + msg.value;
        emit EntityReceivedETH(msg.sender, msg.value);
    }
}
```

---

**Explanation of Advanced/Creative/Trendy Concepts Used:**

1.  **Autonomous State Machine:** The core idea is an entity whose state (`entityState.attributes`) changes automatically over time via decay and regeneration, independent of direct user actions (though *influenced* by parameters set by the owner and interactions). The `pulse()` function is a mechanism for anyone to trigger this time-based update on-chain.
2.  **Time-Based Dynamics:** Attributes decay or regenerate based on the time elapsed since the last state update (`lastUpdateTime`). This introduces a dynamic element where idleness (lack of `pulse()` calls) still affects the state.
3.  **Pull-Based State Updates:** The time-based decay/regen is calculated only when specific functions (`pulse`, interaction functions, `triggerEvolution`) are called. This is necessary on a blockchain where continuous background processes aren't feasible.
4.  **Dynamic Parameters:** Decay rates, regeneration rates, and influence multipliers are not fixed constants but stored variables (`baseParameters`, `phaseConfigs`).
5.  **Evolutionary Phases:** The entity can transition through discrete phases (`currentPhase`). Each phase can have its *own* set of parameters that override the base parameters, allowing the entity's behavior and dynamics to change drastically as it evolves. This introduces a narrative and distinct stages to the simulation.
6.  **Rule-Based Evolution:** Evolution is not automatic but triggered when a set of owner-defined `EvolutionRule`s are met. These rules check attribute values against defined conditions, allowing for complex prerequisites for advancing phases.
7.  **Configurable Rules and Phases:** The owner can add/remove evolution rules and define/update configurations for any future phase (`setPhaseConfig`, `addEvolutionRule`, `removeEvolutionRule`). This makes the entity's evolution path and dynamics highly customizable *after* deployment.
8.  **Dynamic Interaction Costs:** The cost for users to interact (`feed`, `stimulate`, `influenceAttribute`) can be determined by a `calculateDynamicCost` function. While simple here, it can be expanded to depend on the entity's current state, phase, network conditions, etc., adding a strategic layer for users.
9.  **Influence Pool:** User contributions are pooled, allowing the owner to potentially direct funds (e.g., for maintenance of the system off-chain, or distributing rewards in a more complex setup not included here).
10. **Attribute System:** Uses a flexible array of attributes (`attributes`) rather than fixed named variables, allowing for easier expansion or modification of the entity's characteristics (though attribute names are stored separately for clarity).
11. **Predictive State View (`predictFutureStateSimple`):** Provides a basic lookahead function (though limited to decay/regen) allowing users or interfaces to estimate the entity's state without committing a transaction.
12. **Separation of Base vs. Phase Parameters:** Allows for a global default behavior with specific overrides for distinct life stages.

This contract provides a framework for building a complex, evolving digital organism or system entirely on-chain, offering more intricate mechanics than typical token or basic DeFi contracts.