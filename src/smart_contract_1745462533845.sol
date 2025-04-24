Okay, this is an exciting challenge! Let's design a smart contract protocol around a dynamic, evolving system influenced by user interaction and time.

**Concept:** The **HyperCube Protocol** - A system representing interconnected "dimensions" where users can "attune" (stake) tokens to influence the state of these dimensions and earn rewards based on complex, dynamic resonance factors. Dimensions have inherent properties like "drift" and "resonance," which change over time and based on total user attunement. The protocol progresses through "epochs," each potentially altering the fundamental rules or parameters, introducing an element of dynamic strategy.

**Advanced Concepts Used:**
1.  **Dynamic State:** Dimension properties (`currentResonanceState`) change deterministically based on time (`drift`) and user actions (`resonance`).
2.  **Complex Reward Calculation:** Rewards are based on user stake, dimension state, dimension properties (weight), time, and base protocol rates.
3.  **Epoch-Based Rules:** Protocol parameters can change upon transitioning to a new epoch, driven by time.
4.  **On-Chain Parameterization:** Many aspects of the protocol are governed by on-chain parameters adjustable by governance/owner.
5.  **Internal Accounting:** User balances and attunements are managed internally before token withdrawal.
6.  **Deterministic "Evolution":** The state evolves predictably based on defined rules.

**Non-Duplicate Claim:** While elements like staking/pooling and dynamic parameters exist, the specific combination of interconnected dimensions with quantifiable drift/resonance state, user attunement driving deterministic state changes across these dimensions, and epoch-based rule evolution in this abstract "HyperCube" structure is intended to be a novel synthesis for a single smart contract example, distinct from standard DeFi farms, NFT mechanics, or governance contracts.

---

### HyperCube Protocol Smart Contract Outline & Function Summary

**Outline:**

1.  **SPDX License & Pragma**
2.  **Imports:** ERC20 (for the stake/reward token), Ownable, Context.
3.  **Error Definitions:** Custom errors for clarity.
4.  **Constants:** `RATE_SCALE`, `STATE_SCALE` for fixed-point arithmetic simulation.
5.  **Structs:**
    *   `Dimension`: Stores properties and current state of a dimension.
    *   `UserDimensionAttunement`: Stores a user's stake and last interaction time per dimension.
6.  **State Variables:**
    *   Core protocol state (`resonanceToken`, `numberOfDimensions`, `baseResonanceRate`, `protocolFeeRate`, `protocolFeesCollected`).
    *   Epoch state (`currentEpoch`, `epochStartTime`, `epochDuration`).
    *   Dimension data (`dimensions` mapping).
    *   User attunement data (`userAttunements` mapping).
    *   Total attunement per dimension (`totalAttunementPerDimension` mapping).
    *   User internal reward balances (`userResonanceRewards` mapping).
    *   Mapping to track if a dimension ID exists.
7.  **Events:** For key actions (attune, unattune, claim, state update, epoch transition, fee withdrawal).
8.  **Modifiers:** `onlyOwner`, `whenNotPaused` (manual check, not Pausable import).
9.  **Constructor:** Initializes protocol parameters, token address, and owner.
10. **Internal Helper Functions:**
    *   `_dimensionExists`: Check if a dimension ID is valid.
    *   `_updateDimensionState`: Calculates and applies state changes (drift + resonance) for a dimension.
    *   `_calculatePendingRewards`: Calculates rewards earned by a user in a dimension since last interaction.
    *   `_applyEpochRules`: Applies parameter changes based on the current epoch (placeholder logic).
    *   `_updateDimensionStateAndCalculateRewards`: Combines state update and reward calculation for a user in a specific dimension.
11. **User Interaction Functions:**
    *   `attuneToDimension`: Stake tokens in a dimension.
    *   `unattuneFromDimension`: Unstake tokens from a dimension.
    *   `claimResonanceRewards`: Withdraw earned rewards.
12. **Protocol State Management Functions:**
    *   `transitionToNextEpoch`: Advances the protocol to the next epoch if duration elapsed.
    *   `triggerDimensionStateUpdate`: (Optional, Public) Allows anyone to trigger a state update for a dimension (potentially incentivized). *Decided to make update internal for simplicity triggered by user actions.*
13. **Admin/Governance Functions:**
    *   `addDimension`: Add a new dimension (only before users attune?).
    *   `setDimensionProperties`: Update parameters for an existing dimension.
    *   `removeDimension`: Remove a dimension (handle existing attunements?). *Simplify: Disallow removing if attuned.*
    *   `setBaseResonanceRate`: Set the global base reward rate.
    *   `setProtocolFeeRate`: Set the percentage of rewards taken as protocol fees.
    *   `setEpochParameters`: Set duration and initial properties for future epochs.
    *   `withdrawProtocolFees`: Withdraw accumulated protocol fees.
    *   `transferOwnership`: Standard Ownable transfer.
14. **Query (View/Pure) Functions:**
    *   `getDimensionProperties`: Get properties of a dimension.
    *   `getUserAttunementInDimension`: Get user's stake in a dimension.
    *   `getTotalAttunementInDimension`: Get total stake in a dimension.
    *   `getUserPendingRewards`: Get total pending rewards for a user across all dimensions.
    *   `getCurrentEpoch`: Get the current epoch number.
    *   `getEpochEndTime`: Get the timestamp for the end of the current epoch.
    *   `getBaseResonanceRate`: Get the current base reward rate.
    *   `getProtocolFeeRate`: Get the current protocol fee rate.
    *   `getResonanceTokenAddress`: Get the address of the stake/reward token.
    *   `getNumberOfDimensions`: Get the total number of active dimensions.
    *   `getCurrentDimensionState`: Get the current resonance state of a dimension.
    *   `getDimensionLastUpdateTime`: Get the last time a dimension's state was updated.
    *   `calculateEstimatedRewardsForDuration`: Estimate potential rewards for a user over a future duration (pure).
    *   `getProtocolFeesCollected`: Get the total fees collected.
    *   `isDimensionActive`: Check if a dimension ID is currently active.

**Total Functions (Counting Public/External/Internal functions used externally or as helpers):** Constructor (1) + Internal Helpers used by external (4) + User Interaction (3) + Protocol State (1) + Admin/Governance (8) + Query (15) = **32 Functions.** This meets the requirement of at least 20.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Context.sol";

// Custom errors
error HyperCube__InvalidDimension(uint256 dimensionId);
error HyperCube__DimensionAlreadyExists(uint256 dimensionId);
error HyperCube__DimensionNotEmpty(uint256 dimensionId);
error HyperCube__InsufficientAttunement();
error HyperCube__EpochNotEnded();
error HyperCube__EpochParametersAlreadySet();
error HyperCube__EpochParametersNotSet();
error HyperCube__ZeroAddressNotAllowed();
error HyperCube__InvalidRate();
error HyperCube__InvalidEpochDuration();
error HyperCube__CalculationOverflow(); // Generic overflow check needed for complex math

/**
 * @title HyperCubeProtocol
 * @dev A dynamic protocol based on interconnected dimensions where users attune tokens
 *      to influence dimension states and earn rewards based on resonance.
 *      The protocol evolves through epochs with changing parameters.
 *
 * Outline:
 * 1. SPDX License & Pragma
 * 2. Imports (IERC20, Ownable, Context)
 * 3. Custom Errors
 * 4. Constants (RATE_SCALE, STATE_SCALE)
 * 5. Structs (Dimension, UserDimensionAttunement)
 * 6. State Variables (protocol config, epoch state, mappings for data)
 * 7. Events
 * 8. Modifiers (onlyOwner)
 * 9. Constructor
 * 10. Internal Helper Functions (_dimensionExists, _updateDimensionState, _calculatePendingRewards, _applyEpochRules, _updateDimensionStateAndCalculateRewards)
 * 11. User Interaction Functions (attuneToDimension, unattuneFromDimension, claimResonanceRewards)
 * 12. Protocol State Management Functions (transitionToNextEpoch)
 * 13. Admin/Governance Functions (addDimension, setDimensionProperties, removeDimension, setBaseResonanceRate, setProtocolFeeRate, setEpochParameters, withdrawProtocolFees, transferOwnership)
 * 14. Query (View/Pure) Functions (getDimensionProperties, getUserAttunementInDimension, getTotalAttunementInDimension, getUserPendingRewards, getCurrentEpoch, getEpochEndTime, getBaseResonanceRate, getProtocolFeeRate, getResonanceTokenAddress, getNumberOfDimensions, getCurrentDimensionState, getDimensionLastUpdateTime, calculateEstimatedRewardsForDuration, getProtocolFeesCollected, isDimensionActive)
 */
contract HyperCubeProtocol is Context, Ownable {

    // --- Constants ---
    // Scaling factor for rates (base rate, drift rate, resonance factor, fee rate) to handle decimals
    uint256 public constant RATE_SCALE = 1e18;
    // Scaling factor for dimension state to handle decimals
    uint256 public constant STATE_SCALE = 1e18;
     // Minimum dimension state (clamped)
    uint256 public constant MIN_DIMENSION_STATE = 0;
    // Maximum dimension state (clamped)
    uint256 public constant MAX_DIMENSION_STATE = 100 * STATE_SCALE; // State clamped between 0 and 100

    // --- Structs ---

    /**
     * @dev Represents a single dimension within the HyperCube.
     *      Properties influence its behavior and reward generation.
     */
    struct Dimension {
        string name; // Optional: Name for the dimension
        uint256 weight; // Weight multiplier for rewards (e.g., 1e18 for 1x)
        int256 driftRate; // Rate at which state changes passively per second (scaled by RATE_SCALE)
        int255 resonanceFactor; // Factor influencing how user attunement changes affect state (scaled by RATE_SCALE)
        uint256 currentResonanceState; // The current state of the dimension (scaled by STATE_SCALE)
        uint256 lastUpdateTime; // Timestamp of the last state update
        bool isActive; // Whether the dimension is currently active
    }

    /**
     * @dev Stores a user's attunement details for a specific dimension.
     */
    struct UserDimensionAttunement {
        uint256 attunementAmount; // Amount of tokens the user has attuned (staked)
        uint256 lastRewardClaimTime; // Timestamp of the last reward calculation/claim
    }

    // --- State Variables ---

    IERC20 public immutable resonanceToken; // The token used for attunement and rewards

    uint256 public numberOfDimensions; // Total count of active dimensions

    uint256 public baseResonanceRate; // Base rate for reward calculation per second per unit of state/attunement (scaled by RATE_SCALE)
    uint256 public protocolFeeRate; // Percentage of earned rewards taken as fee (e.g., 1e17 for 10%) (scaled by RATE_SCALE)
    uint256 public protocolFeesCollected; // Total fees collected by the protocol

    uint256 public currentEpoch; // Current epoch number (starts at 1)
    uint256 public epochStartTime; // Timestamp when the current epoch started
    uint256 public epochDuration; // Duration of each epoch in seconds

    mapping(uint256 => Dimension) private dimensions; // Stores data for each dimension ID
    mapping(uint256 => bool) private dimensionExists; // Tracks if a dimension ID is valid/active

    mapping(address => mapping(uint256 => UserDimensionAttunement)) private userAttunements; // User attunement per dimension
    mapping(uint256 => uint256) private totalAttunementPerDimension; // Total attunement in each dimension

    mapping(address => uint256) private userResonanceRewards; // Accumulated rewards per user (internal balance)

    // Parameters for future epochs - more complex epoch rules could be added here
    mapping(uint256 => uint256) private epochBaseRateMultiplier; // Multiplier for baseRate in a future epoch (scaled by RATE_SCALE)

    // --- Events ---

    event DimensionAdded(uint256 indexed dimensionId, string name, uint256 initialResonanceState, uint256 timestamp);
    event DimensionPropertiesUpdated(uint256 indexed dimensionId, string name, uint256 weight, int256 driftRate, int255 resonanceFactor, uint256 timestamp);
    event DimensionRemoved(uint256 indexed dimensionId, uint256 timestamp);
    event DimensionStateUpdated(uint256 indexed dimensionId, uint256 oldState, uint256 newState, uint256 timestamp);

    event Attune(address indexed user, uint256 indexed dimensionId, uint256 amount, uint256 newAttunementTotal, uint256 timestamp);
    event Unattune(address indexed user, uint256 indexed dimensionId, uint256 amount, uint256 newAttunementTotal, uint256 timestamp);
    event RewardsClaimed(address indexed user, uint256 amount, uint256 protocolFee, uint256 timestamp);

    event EpochTransitioned(uint256 indexed oldEpoch, uint256 indexed newEpoch, uint256 epochStartTime, uint256 timestamp);
    event ParametersUpdated(string name, uint256 oldValue, uint256 newValue, uint256 timestamp);
    event ProtocolFeesWithdrawn(address indexed recipient, uint256 amount, uint256 timestamp);


    // --- Constructor ---

    /**
     * @dev Initializes the HyperCube Protocol.
     * @param _resonanceToken Address of the ERC20 token used for attunement and rewards.
     * @param _baseResonanceRate Initial base reward rate.
     * @param _protocolFeeRate Initial protocol fee rate.
     * @param _epochDuration Duration of the first epoch in seconds.
     */
    constructor(
        address _resonanceToken,
        uint256 _baseResonanceRate,
        uint256 _protocolFeeRate,
        uint256 _epochDuration
    ) Ownable(msg.sender) {
        if (_resonanceToken == address(0)) revert HyperCube__ZeroAddressNotAllowed();
        if (_baseResonanceRate == 0) revert HyperCube__InvalidRate();
        if (_protocolFeeRate >= RATE_SCALE) revert HyperCube__InvalidRate(); // Fee rate should be less than 100%
         if (_epochDuration == 0) revert HyperCube__InvalidEpochDuration();

        resonanceToken = IERC20(_resonanceToken);
        baseResonanceRate = _baseResonanceRate;
        protocolFeeRate = _protocolFeeRate;
        epochDuration = _epochDuration;

        currentEpoch = 1;
        epochStartTime = block.timestamp;
        numberOfDimensions = 0; // Dimensions are added after deployment

        emit EpochTransitioned(0, currentEpoch, epochStartTime, block.timestamp); // Indicate start of first epoch
        emit ParametersUpdated("baseResonanceRate", 0, baseResonanceRate, block.timestamp);
        emit ParametersUpdated("protocolFeeRate", 0, protocolFeeRate, block.timestamp);
        emit ParametersUpdated("epochDuration", 0, epochDuration, block.timestamp);
    }

    // --- Internal Helper Functions ---

    /**
     * @dev Checks if a dimension with the given ID exists and is active.
     */
    function _dimensionExists(uint256 dimensionId) internal view returns (bool) {
        return dimensionExists[dimensionId] && dimensions[dimensionId].isActive;
    }

    /**
     * @dev Calculates and updates the resonance state of a dimension based on time elapsed and attunement changes.
     * @param dimensionId The ID of the dimension to update.
     * @param deltaTotalAttunement The change in total attunement since the last update (+ve for increase, -ve for decrease).
     */
    function _updateDimensionState(uint256 dimensionId, int256 deltaTotalAttunement) internal {
        Dimension storage dim = dimensions[dimensionId];
        uint256 currentTime = block.timestamp;
        uint256 timeElapsed = currentTime - dim.lastUpdateTime;

        if (timeElapsed == 0 && deltaTotalAttunement == 0) {
            // No state change needed
            return;
        }

        uint256 oldState = dim.currentResonanceState;

        // Calculate state change due to drift
        // stateChangeDueToDrift = driftRate * timeElapsed
        // Need to handle potential negative results for drift
        int256 stateChangeDueToDrift;
        if (dim.driftRate > 0) {
             if (timeElapsed > 0 && dim.driftRate > int256(type(uint256).max / timeElapsed)) revert HyperCube__CalculationOverflow();
             stateChangeDueToDrift = dim.driftRate * int256(timeElapsed);
        } else {
             if (timeElapsed > 0 && dim.driftRate < int256(type(uint256).min / timeElapsed)) revert HyperCube__CalculationOverflow();
            stateChangeDueToDrift = dim.driftRate * int256(timeElapsed);
        }


        // Calculate state change due to resonance from attunement changes
        // stateChangeDueToResonance = deltaTotalAttunement * resonanceFactor
         int256 stateChangeDueToResonance;
         if (deltaTotalAttunement > 0) {
             if (dim.resonanceFactor > 0 && deltaTotalAttunement > type(int255).max / dim.resonanceFactor) revert HyperCube__CalculationOverflow();
             stateChangeDueToResonance = deltaTotalAttunement * dim.resonanceFactor;
         } else if (deltaTotalAttunement < 0) {
              if (dim.resonanceFactor < 0 && deltaTotalAttunement < type(int255).max / dim.resonanceFactor) revert HyperCube__CalculationOverflow();
             stateChangeDueToResonance = deltaTotalAttunement * dim.resonanceFactor;
         }


        // Combine changes and apply to state
        // New state = old state + drift change + resonance change
        // Need to handle int256 addition/subtraction with uint256 state carefully.
        // Current state is uint256, scaled. Total change is int256, scaled.
        // Let's convert oldState to int256 for the calculation, then back to uint256 and clamp.

        int256 oldStateSigned = int256(oldState);
        int256 totalStateChange = stateChangeDueToDrift + stateChangeDueToResonance;
        int256 newStateSigned = oldStateSigned + totalStateChange;

        // Clamp the new state within bounds [MIN_DIMENSION_STATE, MAX_DIMENSION_STATE]
        uint256 newStateClamped;
        if (newStateSigned < int256(MIN_DIMENSION_STATE)) {
            newStateClamped = MIN_DIMENSION_STATE;
        } else if (newStateSigned > int256(MAX_DIMENSION_STATE)) {
            newStateClamped = MAX_DIMENSION_STATE;
        } else {
            newStateClamped = uint256(newStateSigned);
        }

        dim.currentResonanceState = newStateClamped;
        dim.lastUpdateTime = currentTime;

        emit DimensionStateUpdated(dimensionId, oldState, newStateClamped, currentTime);
    }

    /**
     * @dev Calculates the rewards accumulated by a user for a specific dimension.
     * @param user The address of the user.
     * @param dimensionId The ID of the dimension.
     * @return The amount of rewards earned since the last calculation.
     */
    function _calculatePendingRewards(address user, uint256 dimensionId) internal view returns (uint256) {
        UserDimensionAttunement storage userAtt = userAttunements[user][dimensionId];
        Dimension storage dim = dimensions[dimensionId];

        uint256 currentTime = block.timestamp;
        uint256 timeElapsed = currentTime - userAtt.lastRewardClaimTime;

        if (userAtt.attunementAmount == 0 || timeElapsed == 0 || dim.currentResonanceState == 0 || dim.weight == 0) {
            return 0;
        }

        // Reward calculation: attunement * state * weight * baseRate * time / (RATE_SCALE * STATE_SCALE * RATE_SCALE)
        // Scale: attunement (wei), state (scaled by STATE_SCALE), weight (scaled by RATE_SCALE), baseRate (scaled by RATE_SCALE), time (seconds)
        // Result needs to be in wei
        // (attunement * state) is wei * scaled. Divide by STATE_SCALE to get wei-equivalent state influence
        // (wei * scaled / STATE_SCALE) * weight is wei-equiv * scaled. Divide by RATE_SCALE
        // (wei-equiv * scaled / RATE_SCALE) * baseRate is wei-equiv * scaled. Divide by RATE_SCALE
        // Final: (attunement * dim.currentResonanceState / STATE_SCALE * dim.weight / RATE_SCALE * baseResonanceRate / RATE_SCALE * timeElapsed)

         uint256 rewards = userAtt.attunementAmount;
         rewards = (rewards * dim.currentResonanceState) / STATE_SCALE;
         rewards = (rewards * dim.weight) / RATE_SCALE;
         rewards = (rewards * baseResonanceRate) / RATE_SCALE;

         // Avoid overflow on final multiplication by timeElapsed
         if (timeElapsed > 0 && rewards > type(uint256).max / timeElapsed) revert HyperCube__CalculationOverflow();

         rewards = rewards * timeElapsed;

        return rewards;
    }

    /**
     * @dev Applies epoch-specific rules or parameter adjustments. (Placeholder for more complex logic)
     *      Currently, it checks if future epoch parameters are set and applies them.
     */
    function _applyEpochRules() internal {
        // In a more complex version, this could apply multipliers, change drift/resonance factors, etc.
        // Based on epochBaseRateMultiplier or other epoch-specific state.

        uint256 nextEpochBaseRateMultiplier = epochBaseRateMultiplier[currentEpoch + 1];
        if (nextEpochBaseRateMultiplier > 0) {
             // Apply multiplier and reset for next time
            baseResonanceRate = (baseResonanceRate * nextEpochBaseRateMultiplier) / RATE_SCALE;
            delete epochBaseRateMultiplier[currentEpoch + 1]; // Use multiplier only once
            emit ParametersUpdated("baseResonanceRate (Epoch Rule)", baseResonanceRate * RATE_SCALE / nextEpochBaseRateMultiplier, baseResonanceRate, block.timestamp);
        }

        // Could apply other rules here based on currentEpoch
        // e.g., if currentEpoch == 5, certain dimensions get boosted drift.
    }

     /**
      * @dev Updates dimension state and calculates pending rewards for a user before an action.
      * @param user The address of the user.
      * @param dimensionId The ID of the dimension.
      * @param deltaTotalAttunementChange The change in total attunement expected *after* the action.
      *        This is passed to _updateDimensionState to project the state change *before* reward calc for this user,
      *        but based on the *final* state after the action.
      *        *Correction*: State update should use the *current* state and *delta* to calculate the *new* state.
      *        Reward calculation uses the state *before* the user's action for the time elapsed *until* the action.
      *        So, the correct flow is:
      *        1. Calculate rewards based on state *before* this interaction, up to `block.timestamp`.
      *        2. Update user's `lastRewardClaimTime` to `block.timestamp`.
      *        3. Update dimension state using `deltaTotalAttunementChange`.
      */
     function _updateDimensionStateAndCalculateRewards(address user, uint256 dimensionId, int256 deltaTotalAttunementChange) internal {
         UserDimensionAttunement storage userAtt = userAttunements[user][dimensionId];

         // 1. Calculate rewards up to the current moment based on the state *before* this interaction
         uint256 pendingRewards = _calculatePendingRewards(user, dimensionId);
         if (pendingRewards > 0) {
             userResonanceRewards[user] += pendingRewards;
         }

         // 2. Update user's last reward calculation time to now
         userAtt.lastRewardClaimTime = block.timestamp;

         // 3. Update the dimension state based on the *expected* total attunement change from this action
         // The state update needs to know the 'delta' in total attunement caused by this user's action.
         // E.g., Attuning +amount means deltaTotalAttunementChange is +amount.
         // E.g., Unattuning -amount means deltaTotalAttunementChange is -amount.
         _updateDimensionState(dimensionId, deltaTotalAttunementChange);
     }

    // --- User Interaction Functions ---

    /**
     * @dev Allows a user to attune (stake) tokens to a specific dimension.
     *      Requires the user to approve this contract to spend the tokens first.
     * @param dimensionId The ID of the dimension to attune to.
     * @param amount The amount of tokens to attune.
     */
    function attuneToDimension(uint256 dimensionId, uint256 amount) external {
        if (!_dimensionExists(dimensionId)) revert HyperCube__InvalidDimension(dimensionId);
        if (amount == 0) return;

        address user = _msgSender();
        UserDimensionAttunement storage userAtt = userAttunements[user][dimensionId];
        Dimension storage dim = dimensions[dimensionId];

        // Calculate and update pending rewards before changing attunement
         // The delta change in total attunement from this action is +amount
        _updateDimensionStateAndCalculateRewards(user, dimensionId, int256(amount));

        // Transfer tokens from user to contract
        require(resonanceToken.transferFrom(user, address(this), amount), "Token transfer failed");

        // Update user's attunement
        userAtt.attunementAmount += amount;
         // Update total attunement for the dimension
        totalAttunementPerDimension[dimensionId] += amount;

        emit Attune(user, dimensionId, amount, userAtt.attunementAmount, block.timestamp);
    }

    /**
     * @dev Allows a user to unattune (unstake) tokens from a specific dimension.
     * @param dimensionId The ID of the dimension to unattune from.
     * @param amount The amount of tokens to unattune.
     */
    function unattuneFromDimension(uint256 dimensionId, uint256 amount) external {
         if (!_dimensionExists(dimensionId)) revert HyperCube__InvalidDimension(dimensionId);
        if (amount == 0) return;

        address user = _msgSender();
        UserDimensionAttunement storage userAtt = userAttunements[user][dimensionId];

        if (userAtt.attunementAmount < amount) revert HyperCube__InsufficientAttunement();

        // Calculate and update pending rewards before changing attunement
        // The delta change in total attunement from this action is -amount
        _updateDimensionStateAndCalculateRewards(user, dimensionId, -int256(amount));

        // Update user's attunement
        userAtt.attunementAmount -= amount;
        // Update total attunement for the dimension
        totalAttunementPerDimension[dimensionId] -= amount;

        // Transfer tokens from contract to user
        require(resonanceToken.transfer(user, amount), "Token transfer failed");

        emit Unattune(user, dimensionId, amount, userAtt.attunementAmount, block.timestamp);
    }

    /**
     * @dev Allows a user to claim their accumulated resonance rewards.
     *      This also updates the dimension state and calculates rewards up to the claim time.
     */
    function claimResonanceRewards() external {
        address user = _msgSender();
        uint256 totalPendingRewards = 0;

        // Calculate and accrue rewards for *all* dimensions the user is attuned to
        // This ensures state updates and reward calculations are current for all relevant dimensions
        for (uint256 i = 1; i <= numberOfDimensions; i++) { // Assuming dimension IDs start from 1
            if (_dimensionExists(i)) { // Only process active dimensions
                 UserDimensionAttunement storage userAtt = userAttunements[user][i];
                 if (userAtt.attunementAmount > 0) {
                     uint256 pendingRewards = _calculatePendingRewards(user, i);
                      if (pendingRewards > 0) {
                         userResonanceRewards[user] += pendingRewards;
                     }
                      // Update last claim time *after* calculating rewards
                     userAtt.lastRewardClaimTime = block.timestamp;

                     // State update based on zero attunement change for claim action
                     // State update is now handled *within* _updateDimensionStateAndCalculateRewards,
                     // which is called by attune/unattune. A claim doesn't change total attunement,
                     // but state should still drift forward. We can trigger state update here
                     // for dimensions the user interacts with, or rely on attune/unattune to do it.
                     // Let's rely on attune/unattune for state updates driven by attunement changes.
                     // State drift will happen naturally whenever state is checked/updated by any user action.
                 }
            }
        }

        totalPendingRewards = userResonanceRewards[user];

        if (totalPendingRewards == 0) {
            return; // No rewards to claim
        }

        // Calculate protocol fee
        uint256 protocolFee = (totalPendingRewards * protocolFeeRate) / RATE_SCALE;
        uint256 amountToUser = totalPendingRewards - protocolFee;

        // Reset user's internal balance
        userResonanceRewards[user] = 0;
        // Accumulate protocol fees
        protocolFeesCollected += protocolFee;

        // Transfer tokens to user
        if (amountToUser > 0) {
             require(resonanceToken.transfer(user, amountToUser), "Reward transfer failed");
        }

        emit RewardsClaimed(user, amountToUser, protocolFee, block.timestamp);
    }

    // --- Protocol State Management Functions ---

    /**
     * @dev Allows anyone to trigger the transition to the next epoch if the current one has ended.
     *      Can potentially include a small incentive for the caller in a production system.
     */
    function transitionToNextEpoch() external {
        if (block.timestamp < epochStartTime + epochDuration) {
            revert HyperCube__EpochNotEnded();
        }

        uint256 oldEpoch = currentEpoch;
        currentEpoch++;
        epochStartTime = block.timestamp; // New epoch starts now

        _applyEpochRules(); // Apply rules for the newly started epoch

        // State of dimensions continues to drift and resonate across epochs
        // No need to reset dimension states here unless epoch rules dictate it

        emit EpochTransitioned(oldEpoch, currentEpoch, epochStartTime, block.timestamp);
    }

    // --- Admin/Governance Functions (Only Owner) ---

    /**
     * @dev Adds a new dimension to the protocol.
     *      Can only be called by the owner.
     *      Dimensions can only be added before any user has attuned to *any* dimension,
     *      to keep dimension IDs stable or require complex migration logic.
     *      Let's simplify: allow adding anytime with a unique ID.
     * @param dimensionId The unique ID for the new dimension.
     * @param name The name of the dimension.
     * @param weight Reward weight multiplier for the dimension.
     * @param driftRate Rate of state change per second.
     * @param resonanceFactor Factor for attunement-driven state change.
     * @param initialResonanceState Starting state for the dimension.
     */
    function addDimension(
        uint256 dimensionId,
        string calldata name,
        uint256 weight,
        int256 driftRate,
        int255 resonanceFactor,
        uint256 initialResonanceState
    ) external onlyOwner {
        if (dimensionExists[dimensionId]) revert HyperCube__DimensionAlreadyExists(dimensionId);
         if (initialResonanceState > MAX_DIMENSION_STATE) revert HyperCube__InvalidRate(); // Using InvalidRate error for scaling bounds

        dimensions[dimensionId] = Dimension({
            name: name,
            weight: weight,
            driftRate: driftRate,
            resonanceFactor: resonanceFactor,
            currentResonanceState: initialResonanceState,
            lastUpdateTime: block.timestamp, // Set last update to now
            isActive: true
        });
        dimensionExists[dimensionId] = true;
        numberOfDimensions++;

        emit DimensionAdded(dimensionId, name, initialResonanceState, block.timestamp);
    }

    /**
     * @dev Sets properties for an existing dimension.
     *      Can only be called by the owner.
     * @param dimensionId The ID of the dimension to update.
     * @param name The name of the dimension.
     * @param weight Reward weight multiplier.
     * @param driftRate Rate of state change per second.
     * @param resonanceFactor Factor for attunement-driven state change.
     */
    function setDimensionProperties(
        uint256 dimensionId,
        string calldata name,
        uint256 weight,
        int256 driftRate,
        int255 resonanceFactor
    ) external onlyOwner {
        if (!_dimensionExists(dimensionId)) revert HyperCube__InvalidDimension(dimensionId);
         // Cannot change initial state here, only dynamic properties

        Dimension storage dim = dimensions[dimensionId];
        dim.name = name;
        dim.weight = weight;
        dim.driftRate = driftRate;
        dim.resonanceFactor = resonanceFactor;
        // State and lastUpdateTime are updated by user interactions/drift

        emit DimensionPropertiesUpdated(dimensionId, name, weight, driftRate, resonanceFactor, block.timestamp);
    }

     /**
      * @dev Removes an active dimension.
      *      Can only be called by the owner.
      *      Requires that no users are currently attuned to this dimension.
      * @param dimensionId The ID of the dimension to remove.
      */
    function removeDimension(uint256 dimensionId) external onlyOwner {
        if (!_dimensionExists(dimensionId)) revert HyperCube__InvalidDimension(dimensionId);
        if (totalAttunementPerDimension[dimensionId] > 0) revert HyperCube__DimensionNotEmpty(dimensionId);

        dimensions[dimensionId].isActive = false; // Mark as inactive
        dimensionExists[dimensionId] = false; // Also mark in the exists mapping
        numberOfDimensions--;

        // Data for this dimension ID will remain in storage but won't be accessible via _dimensionExists
        // Could delete storage slots here, but it's more gas intensive and not strictly necessary
        // as long as _dimensionExists is checked everywhere.

        emit DimensionRemoved(dimensionId, block.timestamp);
    }

    /**
     * @dev Sets the global base resonance rate.
     *      Can only be called by the owner.
     * @param _baseResonanceRate The new base reward rate (scaled by RATE_SCALE).
     */
    function setBaseResonanceRate(uint256 _baseResonanceRate) external onlyOwner {
        if (_baseResonanceRate == 0) revert HyperCube__InvalidRate();
        uint256 oldRate = baseResonanceRate;
        baseResonanceRate = _baseResonanceRate;
        emit ParametersUpdated("baseResonanceRate", oldRate, baseResonanceRate, block.timestamp);
    }

    /**
     * @dev Sets the protocol fee rate.
     *      Can only be called by the owner.
     * @param _protocolFeeRate The new protocol fee rate (scaled by RATE_SCALE, max is RATE_SCALE-1).
     */
    function setProtocolFeeRate(uint256 _protocolFeeRate) external onlyOwner {
        if (_protocolFeeRate >= RATE_SCALE) revert HyperCube__InvalidRate();
        uint256 oldRate = protocolFeeRate;
        protocolFeeRate = _protocolFeeRate;
        emit ParametersUpdated("protocolFeeRate", oldRate, protocolFeeFeeRate, block.timestamp);
    }

    /**
     * @dev Sets parameters that will be applied at the start of a future epoch.
     *      Can only be called by the owner.
     * @param epochNumber The epoch number these parameters apply to (must be > currentEpoch).
     * @param newEpochDuration The duration of the target epoch.
     * @param baseRateMultiplier Multiplier for the base rate in that epoch (scaled by RATE_SCALE).
     *        Set to 0 to not change the base rate.
     */
    function setEpochParameters(uint256 epochNumber, uint256 newEpochDuration, uint256 baseRateMultiplier) external onlyOwner {
        if (epochNumber <= currentEpoch) revert HyperCube__EpochParametersAlreadySet();
        if (newEpochDuration == 0) revert HyperCube__InvalidEpochDuration();

        epochDuration = newEpochDuration; // This sets the duration for the *next* epoch transition
        epochBaseRateMultiplier[epochNumber] = baseRateMultiplier; // Store multiplier for the specific epoch

        emit ParametersUpdated("epochDuration (Future)", epochDuration, newEpochDuration, block.timestamp);
        emit ParametersUpdated("epochBaseRateMultiplier (Future)", 0, baseRateMultiplier, block.timestamp); // No easy way to get old multiplier value here without another mapping
    }


    /**
     * @dev Allows the owner to withdraw accumulated protocol fees.
     * @param recipient Address to send the fees to.
     */
    function withdrawProtocolFees(address recipient) external onlyOwner {
        if (recipient == address(0)) revert HyperCube__ZeroAddressNotAllowed();
        uint256 amount = protocolFeesCollected;
        if (amount == 0) return;

        protocolFeesCollected = 0;
        require(resonanceToken.transfer(recipient, amount), "Fee withdrawal failed");

        emit ProtocolFeesWithdrawn(recipient, amount, block.timestamp);
    }

    // transferOwnership is inherited from Ownable

    // --- Query (View/Pure) Functions ---

    /**
     * @dev Gets the properties of a specific dimension.
     * @param dimensionId The ID of the dimension.
     * @return name, weight, driftRate, resonanceFactor, currentResonanceState, lastUpdateTime, isActive
     */
    function getDimensionProperties(uint256 dimensionId) external view returns (
        string memory name,
        uint256 weight,
        int256 driftRate,
        int255 resonanceFactor,
        uint256 currentResonanceState,
        uint256 lastUpdateTime,
        bool isActive
    ) {
        if (!dimensionExists[dimensionId]) revert HyperCube__InvalidDimension(dimensionId);
        Dimension storage dim = dimensions[dimensionId];
        return (
            dim.name,
            dim.weight,
            dim.driftRate,
            dim.resonanceFactor,
            dim.currentResonanceState,
            dim.lastUpdateTime,
            dim.isActive
        );
    }

     /**
      * @dev Gets a user's attunement amount and last reward claim time for a dimension.
      * @param user The address of the user.
      * @param dimensionId The ID of the dimension.
      * @return attunementAmount, lastRewardClaimTime
      */
    function getUserAttunementInDimension(address user, uint256 dimensionId) external view returns (uint256 attunementAmount, uint256 lastRewardClaimTime) {
        // No revert if dimension doesn't exist or user isn't attuned, just returns 0s
        UserDimensionAttunement storage userAtt = userAttunements[user][dimensionId];
        return (userAtt.attunementAmount, userAtt.lastRewardClaimTime);
    }

    /**
     * @dev Gets the total attunement amount for a specific dimension.
     * @param dimensionId The ID of the dimension.
     * @return The total attunement amount.
     */
    function getTotalAttunementInDimension(uint256 dimensionId) external view returns (uint256) {
         if (!dimensionExists[dimensionId]) revert HyperCube__InvalidDimension(dimensionId);
        return totalAttunementPerDimension[dimensionId];
    }

    /**
     * @dev Gets the total pending rewards for a user across all dimensions.
     *      Note: This calculates based on the *current* dimension states and time,
     *      but doesn't update state or accrue rewards internally.
     *      The actual claim might yield slightly different results due to state updates
     *      happening upon claiming.
     * @param user The address of the user.
     * @return The total estimated pending rewards.
     */
    function getUserPendingRewards(address user) external view returns (uint256) {
        uint256 totalPending = userResonanceRewards[user]; // Internal accrued rewards

        // Add rewards calculated since last internal update
        for (uint256 i = 1; i <= numberOfDimensions; i++) {
            if (_dimensionExists(i)) {
                 UserDimensionAttunement storage userAtt = userAttunements[user][i];
                 if (userAtt.attunementAmount > 0) {
                     totalPending += _calculatePendingRewards(user, i);
                 }
            }
        }
        return totalPending;
    }

    /**
     * @dev Gets the current epoch number.
     * @return The current epoch number.
     */
    function getCurrentEpoch() external view returns (uint256) {
        return currentEpoch;
    }

    /**
     * @dev Gets the timestamp when the current epoch ends.
     * @return The epoch end timestamp.
     */
    function getEpochEndTime() external view returns (uint256) {
        return epochStartTime + epochDuration;
    }

     /**
      * @dev Gets the current global base resonance rate.
      * @return The base resonance rate (scaled by RATE_SCALE).
      */
    function getBaseResonanceRate() external view returns (uint256) {
        return baseResonanceRate;
    }

    /**
     * @dev Gets the current protocol fee rate.
     * @return The protocol fee rate (scaled by RATE_SCALE).
     */
    function getProtocolFeeRate() external view returns (uint256) {
        return protocolFeeRate;
    }

    /**
     * @dev Gets the address of the Resonance Token.
     * @return The token contract address.
     */
    function getResonanceTokenAddress() external view returns (address) {
        return address(resonanceToken);
    }

    /**
     * @dev Gets the total number of active dimensions.
     * @return The count of active dimensions.
     */
    function getNumberOfDimensions() external view returns (uint256) {
        return numberOfDimensions;
    }

     /**
      * @dev Gets the current resonance state of a specific dimension.
      *      Note: This state might be slightly outdated if no interaction
      *      or state update has occurred recently for this dimension.
      *      A public triggerDimensionStateUpdate could make this more current.
      *      For now, state is only updated on user attune/unattune.
      * @param dimensionId The ID of the dimension.
      * @return The current resonance state (scaled by STATE_SCALE).
      */
    function getCurrentDimensionState(uint256 dimensionId) external view returns (uint256) {
         if (!dimensionExists[dimensionId]) revert HyperCube__InvalidDimension(dimensionId);
        return dimensions[dimensionId].currentResonanceState;
    }

    /**
     * @dev Gets the timestamp of the last time a dimension's state was updated.
     * @param dimensionId The ID of the dimension.
     * @return The timestamp of the last update.
     */
    function getDimensionLastUpdateTime(uint256 dimensionId) external view returns (uint256) {
         if (!dimensionExists[dimensionId]) revert HyperCube__InvalidDimension(dimensionId);
        return dimensions[dimensionId].lastUpdateTime;
    }

    /**
     * @dev Estimates potential rewards for a user in a dimension over a duration
     *      based on the *current* state and parameters. This is a pure function
     *      and does not account for future state changes (drift, resonance).
     * @param userAttunement Amount of tokens the user attunes (or currently has attuned).
     * @param dimensionState The current resonance state of the dimension.
     * @param dimensionWeight The weight of the dimension.
     * @param duration The duration in seconds to estimate rewards for.
     * @return The estimated potential rewards (before protocol fees).
     */
    function calculateEstimatedRewardsForDuration(
        uint256 userAttunement,
        uint256 dimensionState,
        uint256 dimensionWeight,
        uint256 duration
    ) external view returns (uint256) {
         if (userAttunement == 0 || dimensionState == 0 || dimensionWeight == 0 || duration == 0) return 0;

         // Same calculation as _calculatePendingRewards but with input parameters
         uint256 rewards = userAttunement;
         rewards = (rewards * dimensionState) / STATE_SCALE;
         rewards = (rewards * dimensionWeight) / RATE_SCALE;
         rewards = (rewards * baseResonanceRate) / RATE_SCALE;

         // Check for overflow before multiplying by duration
         if (duration > 0 && rewards > type(uint256).max / duration) revert HyperCube__CalculationOverflow();

         rewards = rewards * duration;

        return rewards;
    }

     /**
      * @dev Gets the total amount of protocol fees collected.
      * @return The total fees collected.
      */
    function getProtocolFeesCollected() external view returns (uint256) {
        return protocolFeesCollected;
    }

     /**
      * @dev Checks if a dimension ID is currently active.
      * @param dimensionId The ID of the dimension.
      * @return True if the dimension is active, false otherwise.
      */
    function isDimensionActive(uint256 dimensionId) external view returns (bool) {
        return _dimensionExists(dimensionId);
    }

    // Fallback function to prevent accidental ETH sends
    receive() external payable {
        revert("ETH not accepted");
    }

    fallback() external payable {
        revert("Invalid function call or ETH not accepted");
    }
}
```