Okay, let's design a smart contract that represents a *dynamic, evolving digital ecosystem* living on the blockchain, influenced by user interactions and time. It's not a standard token or NFT, but rather a system with internal state that changes, and users can interact to influence this state and potentially extract unique data or value based on the current state.

We'll call it `GenesisPulse`. The core concept is that it has an internal "pulse" or "heartbeat" that changes its state variables (`energyLevel`, `complexityFactor`, `resonanceIndex`). Users can interact by providing "stimulus" (paying ETH or spending internal "energy") to influence these state variables. The contract evolves over time (epochs) and based on these interactions. Users can also trigger a "manifestation" which generates unique data or value based on the contract's state at that specific moment.

This concept combines elements of:
*   **Generative Art/Data:** The state variables and a seed can be used to generate unique outputs.
*   **Algorithmic Systems:** State transitions follow defined rules.
*   **Gamified Interaction:** Users "play" with the system state.
*   **Time-Based Evolution:** State changes occur inherently over time.

It aims to be different from typical ERC-20/ERC-721 by focusing on the *dynamic state* and the *interaction-driven evolution* as the core mechanism, rather than static asset representation or simple value transfer/staking.

---

## Smart Contract: `GenesisPulse`

### Outline:

1.  **Concept:** A dynamic, evolving on-chain ecosystem state (`Pulse`) influenced by time and user interactions.
2.  **Core Mechanics:**
    *   **Pulse:** An internal time-based process that naturally changes the state (decays energy, drifts complexity/resonance).
    *   **State Variables:** Represent the ecosystem's current condition (`epoch`, `energyLevel`, `complexityFactor`, `resonanceIndex`, `generationSeed`).
    *   **User Stimulus:** Users interact via `injectVitality`, `alignResonance`, `amplifyComplexity`, `crystallizeMomentum` functions, paying ETH or spending internal energy/state. These trigger the pulse logic and apply specific state changes.
    *   **Manifestation:** Users can `crystallizeMomentum` to get a unique data signature based on the state at that moment.
    *   **Evolution:** State changes based on elapsed time (pulse) and user actions (stimulus).
3.  **Access Control:** Owner manages core parameters and can withdraw funds.
4.  **Events:** Log significant state changes and interactions.
5.  **Error Handling:** Custom errors for clarity.

### Function Summary:

*   **State Management & Core Logic:**
    *   `_triggerPulseLogic()`: Internal. Updates state based on time elapsed and calculates number of pulses since last update.
    *   `_calculateGenerationSeed()`: Internal/View. Deterministically calculates a seed based on block data and state.
*   **User Interaction (Stimulus & Manifestation):**
    *   `injectVitality()`: External, Payable. Increases `energyLevel`, costs ETH. Triggers pulse logic.
    *   `alignResonance()`: External. Adjusts `resonanceIndex`, potentially costs `energyLevel`. Triggers pulse logic.
    *   `amplifyComplexity()`: External. Adjusts `complexityFactor`, potentially costs `energyLevel`. Triggers pulse logic.
    *   `crystallizeMomentum()`: External, Payable. Triggers pulse logic, calculates/returns a unique `Manifestation` struct based on the *new* state. Costs ETH and/or `energyLevel`.
*   **View & Query Functions:**
    *   `getCurrentState()`: External, View. Returns all core state variables.
    *   `getPulseParameters()`: External, View. Returns owner-configurable pulse parameters.
    *   `getUserCooldown()`: External, View. Returns time left until a user can interact again.
    *   `getEpoch()`: External, View. Returns the current epoch number.
    *   `getEnergyLevel()`: External, View. Returns the current energy level.
    *   `getComplexityFactor()`: External, View. Returns the current complexity factor.
    *   `getResonanceIndex()`: External, View. Returns the current resonance index.
    *   `getGenerationSeed()`: External, View. Returns the current generation seed.
    *   `calculatePotentialEnergyDecay()`: External, View. Calculates energy decay based on arbitrary time duration.
    *   `calculateCurrentPulseFrequency()`: External, View. Calculates the *effective* pulse frequency based on current energy.
    *   `previewManifestation()`: External, View. Calculates the `Manifestation` data *without* changing state.
    *   `getManifestationCost()`: External, View. Returns the current cost to `crystallizeMomentum`.
*   **Owner/Admin Functions:**
    *   `setPulseBaseFrequency()`: External. Sets the base pulse frequency (affects decay rate).
    *   `setEnergyDecayRate()`: External. Sets the rate energy decays per pulse.
    *   `setComplexityGrowthFactor()`: External. Sets how energy influences complexity.
    *   `setResonanceInfluence()`: External. Sets how `alignResonance` affects the index.
    *   `setStimulusCooldown()`: External. Sets the cooldown period for user interactions.
    *   `setManifestationCost()`: External. Sets the ETH/energy cost for manifestation.
    *   `withdrawETH()`: External. Allows owner to withdraw collected ETH.
    *   `transferOwnership()`: External. Transfers contract ownership.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol"; // Although 0.8+ has overflow checks, SafeMath can be good practice for complex calculations or explicit intent.

// Use SafeMath for clarity and robustness in calculations
using SafeMath for uint256;

/// @title GenesisPulse
/// @dev A smart contract representing a dynamic, evolving digital ecosystem state influenced by time and user interactions.
/// @author Your Name/Alias

contract GenesisPulse is Ownable {

    /*───────────────────
    | State Variables
    ───────────────────*/

    // Core State Variables
    uint256 public epoch;           // Represents the contract's age or generation
    uint256 public energyLevel;     // Represents the system's internal vitality (scaled value, e.g., 1e18 = 1 unit)
    uint256 public complexityFactor; // Represents the structural complexity (scaled value)
    uint256 public resonanceIndex;  // Represents interaction harmony/alignment (scaled value)
    uint256 public generationSeed;  // Seed used for potential external generative processes

    // Time Variables
    uint256 public lastPulseTime;   // Timestamp of the last state update pulse

    // Owner-Configurable Pulse Parameters (Scaled values, e.g., 1e18 = 1 unit/second/etc.)
    uint256 public pulseBaseFrequency; // Base pulse frequency (how often decay/drift *can* happen) - lower number means slower pulse
    uint256 public energyDecayRate;    // Amount of energy lost per pulse
    uint256 public complexityGrowthFactor; // How much complexity grows per unit of energy above a threshold
    uint256 public resonanceInfluence; // How much 'alignResonance' affects resonanceIndex

    // Interaction Parameters
    uint256 public stimulusCooldown;       // Minimum time between any user interactions
    mapping(address => uint256) public userLastInteractionTime; // Last timestamp user interacted

    // Cost Parameters (Scaled values)
    uint256 public manifestationEthCost;   // ETH cost to trigger manifestation
    uint256 public manifestationEnergyCost; // Energy cost to trigger manifestation

    /*───────────────────
    | Structures
    ───────────────────*/

    /// @notice Represents a snapshot of the GenesisPulse state at a specific moment, used in manifestation.
    struct Manifestation {
        uint256 epoch;
        uint256 energyLevel;
        uint256 complexityFactor;
        uint256 resonanceIndex;
        uint256 generationSeed;
        bytes32 uniqueSignature; // A hash derived from the snapshot data
    }

    /*───────────────────
    | Events
    ───────────────────*/

    /// @dev Emitted when the contract state pulses, updating core variables.
    event Pulsed(uint256 newEpoch, uint256 newEnergy, uint256 newComplexity, uint256 newResonance, uint256 newSeed, uint256 pulsesExecuted);

    /// @dev Emitted when a user injects vitality.
    event VitalityInjected(address indexed user, uint256 amountEth, uint256 newEnergy);

    /// @dev Emitted when a user aligns resonance.
    event ResonanceAligned(address indexed user, uint256 energySpent, uint256 newResonance);

    /// @dev Emitted when a user amplifies complexity.
    event ComplexityAmplified(address indexed user, uint256 energySpent, uint256 newComplexity);

    /// @dev Emitted when a user crystallizes a manifestation.
    event MomentumCrystallized(address indexed user, Manifestation manifestationData);

    /// @dev Emitted when owner updates a pulse parameter.
    event PulseParameterUpdated(string paramName, uint256 newValue);

    /// @dev Emitted when owner updates an interaction parameter.
    event InteractionParameterUpdated(string paramName, uint256 newValue);

    /// @dev Emitted when owner withdraws ETH.
    event EthWithdrawn(address indexed owner, uint256 amount);

    /*───────────────────
    | Errors
    ───────────────────*/

    /// @dev Custom error indicating an action is called before the cooldown period ends.
    error CooldownNotElapsed(uint256 timeRemaining);

    /// @dev Custom error indicating insufficient ETH was sent.
    error InsufficientEth(uint256 required, uint256 sent);

    /// @dev Custom error indicating insufficient energy level for an action.
    error InsufficientEnergy(uint256 required, uint256 current);

    /// @dev Custom error indicating a parameter value is out of allowed range.
    error InvalidParameter(string paramName, uint256 value);


    /*───────────────────
    | Constructor
    ───────────────────*/

    /// @dev Initializes the contract with basic parameters and the owner.
    /// @param _pulseBaseFrequency Initial base pulse frequency (higher value = faster base pulse). e.g., 1 = every second.
    /// @param _energyDecayRate Initial energy decay per pulse.
    /// @param _complexityGrowthFactor Initial factor for complexity growth based on energy.
    /// @param _resonanceInfluence Initial influence of alignResonance action.
    /// @param _stimulusCooldown Initial cooldown period for user actions.
    /// @param _manifestationEthCost Initial ETH cost for manifestation.
    /// @param _manifestationEnergyCost Initial energy cost for manifestation.
    constructor(
        uint256 _pulseBaseFrequency, // e.g., 10 seconds = 10
        uint256 _energyDecayRate,    // e.g., 1e17 (0.1 unit)
        uint256 _complexityGrowthFactor, // e.g., 1e16 (0.01 unit)
        uint256 _resonanceInfluence, // e.g., 5e17 (0.5 unit)
        uint256 _stimulusCooldown,   // e.g., 60 seconds
        uint256 _manifestationEthCost, // e.g., 1 ether
        uint256 _manifestationEnergyCost // e.g., 1e18 (1 unit)
    ) Ownable(msg.sender) {
        // Initial state
        epoch = 0;
        energyLevel = 1e18; // Start with 1 unit of energy
        complexityFactor = 0;
        resonanceIndex = 0;
        generationSeed = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, msg.sender))); // Initial pseudo-random seed

        // Set initial time
        lastPulseTime = block.timestamp;

        // Set initial parameters
        pulseBaseFrequency = _pulseBaseFrequency;
        energyDecayRate = _energyDecayRate;
        complexityGrowthFactor = _complexityGrowthFactor;
        resonanceInfluence = _resonanceInfluence;
        stimulusCooldown = _stimulusCooldown;
        manifestationEthCost = _manifestationEthCost;
        manifestationEnergyCost = _manifestationEnergyCost;

        // Basic parameter validation
        if (pulseBaseFrequency == 0) revert InvalidParameter("pulseBaseFrequency", 0);
    }

    /*───────────────────
    | Internal Logic
    ───────────────────*/

    /// @dev Internal function to trigger the state pulse logic based on elapsed time.
    /// This function is called at the beginning of any state-changing user interaction.
    function _triggerPulseLogic() internal {
        uint256 timeElapsed = block.timestamp.sub(lastPulseTime);
        // Calculate how many pulses should have occurred
        // Use safe division, handle potential large time elapsed causing overflow in multiplication if not careful
        // Assuming pulseBaseFrequency is in seconds, and timeElapsed is in seconds.
        // numPulses = timeElapsed / pulseBaseFrequency
        uint256 numPulses = timeElapsed.div(pulseBaseFrequency);

        if (numPulses > 0) {
            uint256 pulsesExecuted = numPulses;
            if (epoch.add(pulsesExecuted) < epoch) { // Prevent epoch overflow just in case of extremely large numPulses
                 pulsesExecuted = type(uint256).max.sub(epoch); // Cap pulses executed at max possible
            }


            // Update state for each pulse (simplified aggregate update)
            // Decay energy: energyLevel = energyLevel - (energyDecayRate * numPulses)
            // Use checked arithmetic via SafeMath
            energyLevel = energyLevel > energyDecayRate.mul(pulsesExecuted) ? energyLevel.sub(energyDecayRate.mul(pulsesExecuted)) : 0;

            // Complexity drift: If energy is high, complexity increases; if low, it decays.
            // Simplified: Complexity slowly drifts towards a value based on energy relative to a threshold
            // Let's make it simpler: Complexity has a slow decay, but grows faster if energy is high.
            uint256 complexityDecay = complexityFactor > complexityGrowthFactor.mul(pulsesExecuted) ? complexityGrowthFactor.mul(pulsesExecuted).div(10) : complexityFactor; // Small decay
            complexityFactor = complexityFactor.sub(complexityDecay); // Apply decay

            uint256 energyThreshold = 5e17; // Example threshold (0.5 units)
            if (energyLevel > energyThreshold) {
                 uint256 growthPotential = energyLevel.sub(energyThreshold).div(1e18).mul(complexityGrowthFactor); // Growth proportional to energy above threshold
                 complexityFactor = complexityFactor.add(growthPotential.mul(pulsesExecuted));
            }


            // Resonance drift: Slowly drifts back to a neutral state (e.g., 0)
            // Let's simplify: Resonance slowly decays towards zero magnitude
            uint256 resonanceDecay = resonanceIndex > resonanceInfluence.mul(pulsesExecuted).div(20) ? resonanceInfluence.mul(pulsesExecuted).div(20) : resonanceIndex;
            resonanceIndex = resonanceIndex.sub(resonanceDecay); // Only decays positive values this way, needs fix for negative potential values
             // Assuming resonanceIndex is uint and always positive for simplicity. If it could be negative, would need int256.
             // For uint: resonance decays towards 0.
             // resonanceIndex = resonanceIndex > resonanceDecay ? resonanceIndex.sub(resonanceDecay) : 0; // Corrected decay for uint

            // Update epoch
            epoch = epoch.add(pulsesExecuted);

            // Update generation seed (incorporate new block data and current state)
            generationSeed = uint256(keccak256(abi.encodePacked(
                generationSeed,
                block.timestamp,
                block.difficulty,
                energyLevel,
                complexityFactor,
                resonanceIndex,
                epoch
            )));

            lastPulseTime = block.timestamp;

            emit Pulsed(epoch, energyLevel, complexityFactor, resonanceIndex, generationSeed, pulsesExecuted);
        }
    }

     /// @dev Deterministically calculates a seed value based on various factors including current state.
     /// @return A unique uint256 seed.
    function _calculateGenerationSeed() internal view returns (uint256) {
        // Incorporate state variables and recent block data
        return uint256(keccak256(abi.encodePacked(
            generationSeed, // Use the current contract seed
            block.timestamp,
            block.number,
            block.difficulty, // Note: block.difficulty is 0 on PoS
            tx.origin,
            msg.sender,
            energyLevel,
            complexityFactor,
            resonanceIndex,
            epoch
        )));
    }

    /// @dev Checks if the user has passed their cooldown period.
    function _checkCooldown() internal view {
        if (block.timestamp < userLastInteractionTime[msg.sender].add(stimulusCooldown)) {
            revert CooldownNotElapsed(userLastInteractionTime[msg.sender].add(stimulusCooldown).sub(block.timestamp));
        }
    }

     /// @dev Updates the user's last interaction time.
    function _updateUserCooldown() internal {
        userLastInteractionTime[msg.sender] = block.timestamp;
    }


    /*───────────────────
    | Core Interaction Functions
    ───────────────────*/

    /// @notice Inject vitality into the GenesisPulse ecosystem by sending ETH.
    /// This increases the energy level. Triggers pulse logic first.
    /// @dev Requires msg.value > 0 and checks user cooldown.
    function injectVitality() external payable {
        _checkCooldown();
        _triggerPulseLogic(); // Update state based on time before applying user action

        if (msg.value == 0) revert InsufficientEth(1, 0);

        // Scale ETH to energy (e.g., 1 ETH = 1 unit of energy = 1e18 scaled)
        uint256 energyAdded = msg.value; // Simple 1:1 ETH to scaled energy for now

        energyLevel = energyLevel.add(energyAdded);
        _updateUserCooldown();

        emit VitalityInjected(msg.sender, msg.value, energyLevel);
    }

    /// @notice Align resonance with the GenesisPulse ecosystem.
    /// This action influences the resonance index. Costs internal energy.
    /// @dev Requires sufficient energyLevel and checks user cooldown.
    /// @param amount Influence amount to attempt to apply (scaled).
    function alignResonance(uint256 amount) external {
        _checkCooldown();
        _triggerPulseLogic(); // Update state based on time before applying user action

        uint256 cost = amount.div(resonanceInfluence); // Cost depends on influence factor
        if (energyLevel < cost) revert InsufficientEnergy(cost, energyLevel);

        energyLevel = energyLevel.sub(cost);
        resonanceIndex = resonanceIndex.add(amount); // Simplistic addition for now

        _updateUserCooldown();
        emit ResonanceAligned(msg.sender, cost, resonanceIndex);
    }

    /// @notice Amplify complexity within the GenesisPulse ecosystem.
    /// This action influences the complexity factor. Costs internal energy.
    /// @dev Requires sufficient energyLevel and checks user cooldown.
    /// @param amount Influence amount to attempt to apply (scaled).
    function amplifyComplexity(uint256 amount) external {
        _checkCooldown();
        _triggerPulseLogic(); // Update state based on time before applying user action

        uint256 cost = amount.div(complexityGrowthFactor).mul(2); // Cost depends on growth factor (higher factor = cheaper)
        if (energyLevel < cost) revert InsufficientEnergy(cost, energyLevel);

        energyLevel = energyLevel.sub(cost);
        complexityFactor = complexityFactor.add(amount); // Simplistic addition for now

        _updateUserCooldown();
        emit ComplexityAmplified(msg.sender, cost, complexityFactor);
    }

    /// @notice Crystallize a moment's state into a Manifestation.
    /// This triggers a final pulse update, calculates the unique manifestation data based on the final state of that epoch,
    /// and returns the data structure. Costs ETH and/or energy.
    /// @dev Requires sufficient ETH (if any) and sufficient energy (if any), and checks user cooldown.
    /// @return Manifestation struct containing the state snapshot and a unique signature.
    function crystallizeMomentum() external payable returns (Manifestation memory) {
        _checkCooldown();
        _triggerPulseLogic(); // Final state update before manifestation

        // Check costs
        if (msg.value < manifestationEthCost) revert InsufficientEth(manifestationEthCost, msg.value);
        if (energyLevel < manifestationEnergyCost) revert InsufficientEnergy(manifestationEnergyCost, energyLevel);

        // Deduct costs
        energyLevel = energyLevel.sub(manifestationEnergyCost);
        // ETH is automatically collected by the contract as it's payable

        // Capture the state for the manifestation
        Manifestation memory manifestation = Manifestation({
            epoch: epoch,
            energyLevel: energyLevel,
            complexityFactor: complexityFactor,
            resonanceIndex: resonanceIndex,
            generationSeed: _calculateGenerationSeed(), // Calculate a new seed for this specific manifestation moment
            uniqueSignature: bytes32(0) // Placeholder for calculation
        });

        // Calculate the unique signature based on the captured data
        manifestation.uniqueSignature = keccak256(abi.encodePacked(
            manifestation.epoch,
            manifestation.energyLevel,
            manifestation.complexityFactor,
            manifestation.resonanceIndex,
            manifestation.generationSeed,
            msg.sender, // Include sender to make it user-specific
            block.timestamp // Include time for uniqueness
        ));

        _updateUserCooldown();
        emit MomentumCrystallized(msg.sender, manifestation);

        return manifestation;
    }

    /*───────────────────
    | View & Query Functions
    ───────────────────*/

    /// @notice Gets the current state variables of the GenesisPulse.
    /// @dev Does NOT trigger a pulse update. State might be slightly outdated depending on `lastPulseTime`.
    /// @return A tuple containing the current epoch, energyLevel, complexityFactor, resonanceIndex, and generationSeed.
    function getCurrentState() external view returns (uint256, uint256, uint256, uint256, uint256) {
        return (epoch, energyLevel, complexityFactor, resonanceIndex, generationSeed);
    }

    /// @notice Gets the owner-configurable pulse parameters.
    /// @return A tuple containing pulseBaseFrequency, energyDecayRate, complexityGrowthFactor, and resonanceInfluence.
    function getPulseParameters() external view returns (uint256, uint256, uint256, uint256) {
        return (pulseBaseFrequency, energyDecayRate, complexityGrowthFactor, resonanceInfluence);
    }

    /// @notice Gets the time remaining until the user's interaction cooldown ends.
    /// @param user The address of the user.
    /// @return The number of seconds remaining in the cooldown. Returns 0 if no cooldown or cooldown elapsed.
    function getUserCooldown(address user) external view returns (uint256) {
        uint256 cooldownEnd = userLastInteractionTime[user].add(stimulusCooldown);
        if (block.timestamp < cooldownEnd) {
            return cooldownEnd.sub(block.timestamp);
        } else {
            return 0;
        }
    }

    /// @notice Returns the current epoch number.
    function getEpoch() external view returns (uint256) {
        return epoch;
    }

    /// @notice Returns the current energy level.
    function getEnergyLevel() external view returns (uint256) {
        return energyLevel;
    }

    /// @notice Returns the current complexity factor.
    function getComplexityFactor() external view returns (uint256) {
        return complexityFactor;
    }

    /// @notice Returns the current resonance index.
    function getResonanceIndex() external view returns (uint256) {
        return resonanceIndex;
    }

    /// @notice Returns the current generation seed.
    function getGenerationSeed() external view returns (uint256) {
        return generationSeed;
    }


    /// @notice Calculates the potential energy decay over a given time duration.
    /// @param duration Seconds into the future to calculate decay.
    /// @return The amount of energy that would decay during that duration, assuming current parameters.
    function calculatePotentialEnergyDecay(uint256 duration) external view returns (uint256) {
        // Assuming pulseBaseFrequency > 0
        uint256 potentialPulses = duration.div(pulseBaseFrequency);
        return energyDecayRate.mul(potentialPulses);
    }

    /// @notice Calculates the effective current pulse frequency based on pulseBaseFrequency.
    /// @return The current pulse frequency in seconds.
    function calculateCurrentPulseFrequency() external view returns (uint256) {
        // For simplicity, the effective frequency is just the base frequency.
        // More complex logic could make frequency dynamic based on state (e.g., higher energy = faster pulse)
        return pulseBaseFrequency;
    }

    /// @notice Previews the manifestation data based on the *current* state without triggering a state change or costing anything.
    /// This is useful for off-chain clients to see what they might get.
    /// @dev Does NOT trigger a pulse update. State might be slightly outdated.
    /// @return Manifestation struct based on the current state snapshot.
    function previewManifestation() external view returns (Manifestation memory) {
         // Note: this uses the CURRENT state, not the state *after* an implicit pulse update
        Manifestation memory manifestation = Manifestation({
            epoch: epoch,
            energyLevel: energyLevel,
            complexityFactor: complexityFactor,
            resonanceIndex: resonanceIndex,
            generationSeed: _calculateGenerationSeed(), // Calculate a new seed for this specific preview moment
            uniqueSignature: bytes32(0)
        });

         manifestation.uniqueSignature = keccak256(abi.encodePacked(
            manifestation.epoch,
            manifestation.energyLevel,
            manifestation.complexityFactor,
            manifestation.resonanceIndex,
            manifestation.generationSeed,
            msg.sender,
            block.timestamp
        ));

        return manifestation;
    }

    /// @notice Gets the current ETH cost for crystallizing a manifestation.
    function getManifestationCostEth() external view returns (uint256) {
        return manifestationEthCost;
    }

     /// @notice Gets the current Energy cost for crystallizing a manifestation.
    function getManifestationCostEnergy() external view returns (uint256) {
        return manifestationEnergyCost;
    }


    /*───────────────────
    | Owner/Admin Functions
    ───────────────────*/

    /// @notice Sets the base pulse frequency. Affects how often state decays/drifts.
    /// @dev Only callable by the owner.
    /// @param _newFrequency The new base frequency in seconds. Must be > 0.
    function setPulseBaseFrequency(uint256 _newFrequency) external onlyOwner {
        if (_newFrequency == 0) revert InvalidParameter("pulseBaseFrequency", 0);
        pulseBaseFrequency = _newFrequency;
        emit PulseParameterUpdated("pulseBaseFrequency", _newFrequency);
    }

    /// @notice Sets the energy decay rate per pulse.
    /// @dev Only callable by the owner.
    /// @param _newRate The new energy decay rate (scaled).
    function setEnergyDecayRate(uint256 _newRate) external onlyOwner {
        energyDecayRate = _newRate;
        emit PulseParameterUpdated("energyDecayRate", _newRate);
    }

    /// @notice Sets the complexity growth factor influenced by energy.
    /// @dev Only callable by the owner.
    /// @param _newFactor The new complexity growth factor (scaled).
    function setComplexityGrowthFactor(uint256 _newFactor) external onlyOwner {
        complexityGrowthFactor = _newFactor;
        emit PulseParameterUpdated("complexityGrowthFactor", _newFactor);
    }

    /// @notice Sets the influence amount for the `alignResonance` action.
    /// @dev Only callable by the owner.
    /// @param _newInfluence The new resonance influence value (scaled).
    function setResonanceInfluence(uint256 _newInfluence) external onlyOwner {
        resonanceInfluence = _newInfluence;
        emit PulseParameterUpdated("resonanceInfluence", _newInfluence);
    }

    /// @notice Sets the cooldown period between any user interactions.
    /// @dev Only callable by the owner.
    /// @param _newCooldown The new cooldown period in seconds.
    function setStimulusCooldown(uint256 _newCooldown) external onlyOwner {
        stimulusCooldown = _newCooldown;
        emit InteractionParameterUpdated("stimulusCooldown", _newCooldown);
    }

    /// @notice Sets the ETH and energy costs for crystallizing a manifestation.
    /// @dev Only callable by the owner.
    /// @param _newEthCost The new ETH cost in wei.
    /// @param _newEnergyCost The new energy cost (scaled).
    function setManifestationCost(uint256 _newEthCost, uint256 _newEnergyCost) external onlyOwner {
        manifestationEthCost = _newEthCost;
        manifestationEnergyCost = _newEnergyCost;
        emit InteractionParameterUpdated("manifestationEthCost", _newEthCost);
        emit InteractionParameterUpdated("manifestationEnergyCost", _newEnergyCost);
    }

    /// @notice Allows the owner to withdraw accumulated ETH.
    /// @dev Only callable by the owner.
    function withdrawETH() external onlyOwner {
        uint256 balance = address(this).balance;
        if (balance > 0) {
            // Use a low-level call to avoid issues with the receiving contract
            (bool success, ) = payable(owner()).call{value: balance}("");
            if (!success) {
                // Revert if withdrawal fails to prevent ETH from being stuck
                revert("ETH withdrawal failed");
            }
            emit EthWithdrawn(owner(), balance);
        }
    }

    // The Ownable contract provides transferOwnership

    /*───────────────────
    | Receive/Fallback
    ───────────────────*/

    /// @dev Function to receive ETH without an explicit function call.
    /// Can be used as an alternative way to inject vitality, adding ETH to the contract balance.
    /// Note: This does NOT trigger _triggerPulseLogic or affect energyLevel directly,
    /// unless combined with an explicit `injectVitality` call afterwards.
    /// Consider making this function explicitly call `injectVitality` if receiving ETH should *always* be vitality injection.
    /// As written, it just adds ETH to the balance for later withdrawal by owner.
    receive() external payable {
        // Simply receive ETH into the contract balance
        // Add an event if desired: emit EthReceived(msg.sender, msg.value);
    }

    // Fallback function could be added if needed for calls to undefined functions,
    // but generally receive() is sufficient for ETH transfer.
    // fallback() external payable { ... }
}
```

---

**Explanation of Advanced Concepts and Creativity:**

1.  **Dynamic, Evolving State:** The core idea isn't a static asset or simple balance. The state (`energyLevel`, `complexityFactor`, `resonanceIndex`) is constantly changing based on time and interactions, creating a dynamic system.
2.  **Implicit Pulse Logic:** The state updates (`_triggerPulseLogic`) are not triggered manually by the owner or a dedicated function call that someone has to pay for regularly. Instead, the logic is executed *at the beginning of every state-changing user interaction*. This is more gas-efficient and ensures that the state relevant to a user's action is always up-to-date based on the time elapsed since the *last* interaction, across *all* users.
3.  **Interaction-Driven Evolution:** User actions (`injectVitality`, `alignResonance`, `amplifyComplexity`) directly influence different facets of the ecosystem's state, allowing users to "steer" its evolution within the bounds of the contract's rules.
4.  **Algorithmic Manifestation:** The `crystallizeMomentum` function doesn't mint a standard token. It calculates a unique data structure (`Manifestation`) based on the complex, dynamic state at that specific moment. This output data can then be interpreted off-chain (e.g., to generate art, music, stats) or used as a unique identifier. The `generationSeed` incorporates various on-chain factors for pseudo-randomness tied to the chain's state.
5.  **Interconnected State Variables:** The design suggests (though implementation is simplified here) that `energyLevel` affects the *rate* complexity changes, `resonanceIndex` influences interaction effects, etc., creating feedback loops in the system's evolution.
6.  **Scaled Arithmetic:** Using large uint256 values (like `1e18`) to represent fractional units (like 1.0 or 0.5) allows for more precise calculations of decay, growth, and costs within the integer-only environment of the EVM, without resorting to complex fixed-point libraries (though SafeMath is used for basic safety).
7.  **Custom Errors:** Using `revert` with custom errors provides more gas-efficient and informative error messages compared to simple `require` strings.

This contract provides a framework for a blockchain-native interactive experience where users engage with a living, breathing digital entity rather than just trading or holding static items. The value or interest could lie in witnessing and influencing the ecosystem's evolution and capturing unique "moments" (manifestations) from its lifecycle.