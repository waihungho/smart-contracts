Okay, here is a Solidity smart contract incorporating several advanced, creative, and trendy concepts, focusing on a dynamic, stateful asset called "QuantumFlow".

This contract is not a standard ERC-20 or ERC-721. Instead, it manages an internal balance for each user, where this balance has a dynamic state (Momentum, Potential, Phase) that evolves over time and through user interactions. It also includes staking with separate state evolution, conditional actions, and integration with a verifiable random function (VRF) for unpredictable events.

---

# QuantumFlow Smart Contract

This contract manages a unique type of dynamic asset called "QuantumFlow". Users deposit a BaseToken to acquire QuantumFlow balance. Unlike traditional tokens, each user's QuantumFlow balance has an associated state (Momentum, Potential, Phase) that changes based on time, user interactions, and potential random fluctuations.

## Outline:

1.  **License & Version Pragma**
2.  **Imports:** Standard libraries for ownership, reentrancy protection, safe token interaction, and Chainlink VRF consumer.
3.  **Errors:** Custom error definitions for clarity.
4.  **Enums:** Define different phases of the QuantumFlow state.
5.  **Structs:** Define the structure for user-specific QuantumFlow state.
6.  **State Variables:**
    *   Admin/Ownership
    *   Pausability
    *   Base Token Address
    *   User State Mappings (Active and Staked balances/states)
    *   Dynamic Parameters (Accrual rates, Phase thresholds, Potential reward rate)
    *   VRF Configuration (KeyHash, Fee, Coordinator Address, Request mapping)
    *   Counters (VRF request ID)
7.  **Events:** Log key actions and state changes.
8.  **Constants:** Define fixed parameters like initial rates or phase names.
9.  **Constructor:** Initialize the contract with Base Token and VRF details.
10. **Modifiers:** `whenNotPaused`, `onlyVRFCoordinator`.
11. **Internal Helpers:**
    *   `_updateUserFlowState`: Core logic to calculate time-based accrual and update state parameters (Momentum, Potential, Phase). Called by functions interacting with user state.
    *   `_calculatePotentialFromMomentum`: Calculates Potential from Momentum using a defined function.
    *   `_checkAndTransitionPhase`: Checks if phase thresholds are met and transitions phase if necessary.
    *   `_beforeStateUpdate`: Placeholder for pre-state-update hooks.
    *   `_afterStateUpdate`: Placeholder for post-state-update hooks.
12. **Core User Functions:**
    *   `depositBaseToken`: Deposit BaseToken to receive QuantumFlow (initialize state).
    *   `redeemQuantumFlow`: Redeem QuantumFlow for BaseToken (conditional on state/phase).
    *   `pulsate`: User action to actively boost Momentum of active balance.
    *   `anchorFlow`: Stake active QuantumFlow balance (moves to staked state mapping).
    *   `releaseAnchored`: Unstake staked QuantumFlow balance (moves back to active state mapping).
    *   `triggerPhaseTransition`: Attempt to manually trigger a phase transition based on current state.
    *   `dischargePotential`: Convert accumulated Potential into a reward (e.g., BaseToken), reducing Potential.
    *   `requestQuantumFluctuation`: Initiate a VRF request for a potential random event.
13. **VRF Callback Function:**
    *   `fulfillRandomness`: Handles the result from Chainlink VRF and executes the random event logic.
14. **View Functions:**
    *   `balanceOf`: Get active QuantumFlow balance.
    *   `stakedBalanceOf`: Get staked QuantumFlow balance.
    *   `getUserFlowState`: Get full state (balance, momentum, potential, phase) for active balance.
    *   `getStakedFlowState`: Get full state for staked balance.
    *   `calculatePotentialFromMomentum`: Simulate potential calculation for arbitrary momentum.
    *   `getPhaseThresholds`: Get the thresholds for each phase.
    *   `getAccrualRates`: Get the momentum accrual rates (active vs. staked, passive vs. active).
    *   `getBaseTokenAddress`: Get the address of the Base Token.
    *   `getVRFParams`: Get the VRF configuration parameters.
    *   `isPaused`: Check pause status.
    *   `getPotentialRewardRate`: Get the rate at which Potential is converted to BaseToken.
    *   `getPhaseName`: Get the string name for a phase enum value.
15. **Admin/Owner Functions:**
    *   `setBaseToken`: Set the Base Token address.
    *   `setVRFCoordinator`: Set the VRF Coordinator address.
    *   `setVRFKeyHash`: Set the VRF Key Hash.
    *   `setVRFFee`: Set the VRF fee.
    *   `setPotentialRewardRate`: Set the rate for potential discharge rewards.
    *   `pause`: Pause contract operations.
    *   `unpause`: Unpause contract operations.
    *   `recoverERC20`: Recover accidentally sent ERC-20 tokens.

## Function Summary:

1.  `constructor(address _baseToken, address vrfCoordinator, bytes32 keyHash, uint256 fee)`: Initializes the contract with required addresses and VRF parameters.
2.  `depositBaseToken(uint256 amount)`: User deposits `amount` of `_baseToken`. This amount is recorded as the user's active QuantumFlow balance, and their state is initialized/updated.
3.  `redeemQuantumFlow(uint256 amount)`: User requests to redeem `amount` of their active QuantumFlow balance for `_baseToken`. Requires the user's state (specifically phase) to be `Inert`. Updates state and transfers BaseToken.
4.  `pulsate()`: User action (potentially costly, or limited frequency). Boosts the Momentum of the user's active QuantumFlow state. Calls `_updateUserFlowState`.
5.  `anchorFlow(uint256 amount)`: User stakes `amount` of their active QuantumFlow balance. Moves balance from active to staked mapping and updates both states via `_updateUserFlowState`.
6.  `releaseAnchored(uint256 amount)`: User unstakes `amount` of their staked QuantumFlow balance. Moves balance from staked to active mapping and updates both states via `_updateUserFlowState`.
7.  `triggerPhaseTransition()`: User attempts to manually check and trigger a phase transition for their active state. Calls `_updateUserFlowState` which includes phase check logic.
8.  `dischargePotential(uint256 amountOfPotentialToDischarge)`: User converts `amountOfPotentialToDischarge` from their active state's Potential into a reward (BaseToken). Potential is reduced, BaseToken is transferred. Calls `_updateUserFlowState`.
9.  `requestQuantumFluctuation()`: Initiates a request to the VRF Coordinator for a random number. Requires LINK token payment (handled by VRFConsumerBase). Logs the request ID.
10. `fulfillRandomness(bytes32 requestId, uint256 randomness)`: VRF Coordinator callback. Uses the `randomness` to potentially trigger a random event for a user's state (e.g., spontaneous phase shift, potential boost, temporary rate change).
11. `balanceOf(address account)`: View function. Returns the active QuantumFlow balance for `account`. Calls `_updateUserFlowState` (simulated) to get current balance after potential redemptions/stakes, *without* saving state.
12. `stakedBalanceOf(address account)`: View function. Returns the staked QuantumFlow balance for `account`. Similar to `balanceOf`.
13. `getUserFlowState(address account)`: View function. Returns the detailed state (`balance`, `momentum`, `potential`, `phase`, `lastUpdateTime`) for the `account`'s active balance. Calls `_updateUserFlowState` (simulated) for current values.
14. `getStakedFlowState(address account)`: View function. Returns the detailed state for the `account`'s staked balance. Calls `_updateUserFlowState` (simulated).
15. `calculatePotentialFromMomentum(uint256 momentum)`: View function. Calculates the theoretical potential for a given momentum value.
16. `getPhaseThresholds()`: View function. Returns the momentum/potential thresholds required for each phase transition.
17. `getAccrualRates()`: View function. Returns the passive and active momentum accrual rates for active and staked balances.
18. `getBaseTokenAddress()`: View function. Returns the address of the Base Token used for deposits/redemptions.
19. `getVRFParams()`: View function. Returns the configured VRF coordinator address, key hash, and fee.
20. `isPaused()`: View function. Returns the current pause status.
21. `getPotentialRewardRate()`: View function. Returns the amount of BaseToken rewarded per unit of Potential discharged.
22. `getPhaseName(Phase phase)`: View function. Returns the string representation of a `Phase` enum value.
23. `setBaseToken(address _baseToken)`: Owner function. Sets the address of the Base Token.
24. `setVRFCoordinator(address _vrfCoordinator)`: Owner function. Sets the VRF Coordinator address.
25. `setVRFKeyHash(bytes32 _keyHash)`: Owner function. Sets the VRF Key Hash.
26. `setVRFFee(uint256 _fee)`: Owner function. Sets the VRF fee for VRF requests.
27. `setPotentialRewardRate(uint256 _rate)`: Owner function. Sets the rate for converting Potential to BaseToken during discharge.
28. `pause()`: Owner function. Pauses core contract operations (deposits, redemptions, pulsate, anchor, release, discharge, VRF request).
29. `unpause()`: Owner function. Unpauses contract operations.
30. `recoverERC20(address tokenAddress, uint256 amount)`: Owner function. Allows the owner to recover any ERC-20 tokens accidentally sent to the contract address (except the BaseToken itself, which is managed).

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";

/// @title QuantumFlow Smart Contract
/// @author YourNameHere (or a Pseudonym)
/// @notice This contract manages a unique dynamic asset called QuantumFlow.
/// QuantumFlow balances for each user have a state (Momentum, Potential, Phase)
/// that evolves over time, through interactions, staking, and random events.
/// It integrates VRF for unpredictable fluctuations.

contract QuantumFlow is Ownable, ReentrancyGuard, VRFConsumerBase {
    using SafeERC20 for IERC20;

    // --- Errors ---
    error QuantumFlow__InvalidAmount();
    error QuantumFlow__InsufficientBalance();
    error QuantumFlow__InsufficientStakedBalance();
    error QuantumFlow__RedemptionNotAllowedInCurrentPhase(Phase currentPhase);
    error QuantumFlow__CannotDischargeInsufficientPotential();
    error QuantumFlow__PhaseTransitionThresholdNotMet(Phase currentPhase);
    error QuantumFlow__Paused();
    error QuantumFlow__NotPaused();
    error QuantumFlow__VRFRequestFailed();
    error QuantumFlow__InvalidVRFConfig();
    error QuantumFlow__RecoverBaseTokenNotAllowed();

    // --- Enums ---
    /// @dev Defines the different phases of QuantumFlow state.
    enum Phase {
        Inert, // Stable, low energy state. Redemption might be restricted to this phase.
        Oscillating, // Accumulating momentum, more reactive.
        Entangled, // High potential, interconnected state. Benefits/risks may apply.
        Critical // Peak state, potential for discharge or collapse.
    }

    // --- Structs ---
    /// @dev Stores the dynamic state associated with a user's QuantumFlow balance.
    struct UserFlowState {
        uint256 balance; // The amount of QuantumFlow (equivalent BaseToken)
        uint256 momentum; // Represents accumulated activity/energy
        uint256 potential; // Derived from momentum, can be discharged
        Phase phase; // Current state phase
        uint48 lastUpdateTime; // Timestamp of the last state update (max ~2^48 seconds, > 8 million years)
    }

    // --- State Variables ---

    // Core State Mappings
    mapping(address => UserFlowState) private s_activeFlowState;
    mapping(address => UserFlowState) private s_stakedFlowState;

    // Asset
    IERC20 private s_baseToken;

    // Parameters (Can be made adjustable by owner if needed, but fixed for this example)
    uint256 public constant PASSIVE_MOMENTUM_PER_SECOND_ACTIVE = 1; // Rate of momentum accrual for active balance per second per unit of balance
    uint256 public constant PASSIVE_MOMENTUM_PER_SECOND_STAKED = 3; // Rate of momentum accrual for staked balance per second per unit of balance (Staking bonus)
    uint256 public constant PULSATE_MOMENTUM_BOOST_PER_UNIT = 100; // Momentum boost per unit of balance on pulsate action
    uint256 private s_potentialRewardRate = 1e17; // Amount of BaseToken (in smallest units) per unit of Potential discharged (e.g., 0.1 BaseToken per Potential unit)

    // Phase Thresholds (Momentum based, need calibration)
    uint256 public constant THRESHOLD_INERT_TO_OSCILLATING = 1000;
    uint256 public constant THRESHOLD_OSCILLATING_TO_ENTANGLED = 5000;
    uint256 public constant THRESHOLD_ENTANGLED_TO_CRITICAL = 10000;
    uint256 public constant THRESHOLD_CRITICAL_TO_OSCILLATING_DECAY = 8000; // Decay threshold from Critical
    uint256 public constant THRESHOLD_ENTANGLED_TO_OSCILLATING_DECAY = 4000; // Decay threshold from Entangled
    uint256 public constant THRESHOLD_OSCILLATING_TO_INERT_DECAY = 500; // Decay threshold from Oscillating

    // VRF Configuration (Chainlink)
    bytes32 private s_keyHash;
    uint256 private s_fee;
    // Map VRF request ID to the requesting user's address
    mapping(bytes32 => address) private s_vrfRequests;
    uint256 private s_vrfRequestIdCounter = 0; // Simple counter for uniqueness

    // Pausability
    bool private s_paused = false;

    // --- Events ---
    event Deposited(address indexed user, uint256 amount, uint256 newBalance);
    event Redeemed(address indexed user, uint256 amount, uint256 newBalance);
    event Pulsated(address indexed user, uint256 momentumBoost, uint256 newMomentum);
    event Anchored(address indexed user, uint256 amount, uint256 newActiveBalance, uint256 newStakedBalance);
    event ReleaseAnchored(address indexed user, uint256 amount, uint256 newStakedBalance, uint256 newActiveBalance);
    event PotentialDischarged(address indexed user, uint256 potentialAmount, uint256 baseTokenAmount, uint256 newPotential);
    event PhaseTransitioned(address indexed user, Phase oldPhase, Phase newPhase);
    event FluctuationRequested(address indexed user, bytes32 indexed requestId, uint256 fee);
    event FluctuationOutcome(bytes32 indexed requestId, uint256 randomness, address indexed user, string outcomeDescription);
    event Paused(address account);
    event Unpaused(address account);
    event Recovered(address indexed tokenAddress, address indexed to, uint256 amount);

    // --- Constants (for view functions or readability) ---
    // Phase names for easier interpretation
    string[] public constant PHASE_NAMES = ["Inert", "Oscillating", "Entangled", "Critical"];

    // --- Constructor ---
    /// @param _baseToken Address of the ERC-20 token used for deposits and redemptions.
    /// @param vrfCoordinator Address of the Chainlink VRF Coordinator contract.
    /// @param keyHash The Chainlink VRF Key Hash.
    /// @param fee The fee (in LINK) required for a VRF request.
    constructor(
        address _baseToken,
        address vrfCoordinator,
        bytes32 keyHash,
        uint256 fee
    ) VRFConsumerBase(vrfCoordinator) Ownable(msg.sender) {
        require(address(_baseToken) != address(0), "BaseToken address cannot be zero");
        s_baseToken = IERC20(_baseToken);
        s_keyHash = keyHash;
        s_fee = fee;
    }

    // --- Modifiers ---
    modifier whenNotPaused() {
        if (s_paused) revert QuantumFlow__Paused();
        _;
    }

    // --- Internal Helpers ---

    /// @dev Internal function to calculate time-based accrual and update a user's state.
    /// Must be called before reading or modifying a user's s_activeFlowState or s_stakedFlowState.
    /// @param state User's state struct reference (either active or staked).
    function _updateUserFlowState(UserFlowState storage state) internal {
        uint48 currentTime = uint48(block.timestamp);
        uint48 timeElapsed = currentTime - state.lastUpdateTime;

        if (timeElapsed > 0 && state.balance > 0) {
            uint256 passiveRate = state.phase == Phase.Inert ? PASSIVE_MOMENTUM_PER_SECOND_ACTIVE : (state.phase == Phase.Critical ? PASSIVE_MOMENTUM_PER_SECOND_STAKED : PASSIVE_MOMENTUM_PER_SECOND_ACTIVE); // Example: different rates per phase or staked vs active

            // Simple Linear Momentum Accrual: momentum += balance * rate * time
             // To prevent overflow, do calculation carefully.
             // Let's assume balance and rates are reasonable, focus on time overflow check first (already done by uint48)
             // Check intermediate multiplication results
            uint256 timeElapsedUint = timeElapsed;
            uint256 balanceUint = state.balance;
            uint256 passiveRateUint = passiveRate;

            // Calculate passive momentum gain safely
            uint256 passiveMomentumGain = (balanceUint / 1e18) * passiveRateUint * timeElapsedUint; // Example: scale balance if it represents scaled value
            if (balanceUint > 0 && passiveRateUint > 0 && timeElapsedUint > 0) {
                 // A potentially safer way for scaled values without division then multiplication if balance is scaled:
                 // passiveMomentumGain = (balanceUint * passiveRateUint / 1e18) * timeElapsedUint; -- prone to intermediate overflow
                 // Better: passiveMomentumGain = (balanceUint / 1e18) * (passiveRateUint * timeElapsedUint); -- better if rates/time aren't huge
                 // Or use a fixed point library if needed for precision.
                 // For simplicity here, assume balance is large enough, rates/time small enough for uint256.
                 // If balance is token balance (e.g. 1e18 units), need to consider scaling.
                 // Let's assume passiveRate is based per 1e18 units of balance.
                 passiveMomentumGain = (balanceUint * passiveRateUint * timeElapsedUint) / (1e18); // Scale rate by 1e18 denominator if rate is per 1e18 units

                 // Check for potential overflow before adding
                 if (state.momentum > type(uint256).max - passiveMomentumGain) {
                     state.momentum = type(uint256).max; // Cap momentum at max uint256
                 } else {
                     state.momentum += passiveMomentumGain;
                 }
            }


            // Update Potential (Example: simple linear relation, could be sqrt, log, sigmoid, etc.)
            // state.potential = _calculatePotentialFromMomentum(state.momentum); // Recalculate fully

            // Update time
            state.lastUpdateTime = currentTime;

            // Check and potentially transition phase
            _checkAndTransitionPhase(state);
        } else if (state.balance > 0 && state.lastUpdateTime == 0) {
             // Handle initial state update right after deposit/anchor
             state.lastUpdateTime = currentTime;
             _checkAndTransitionPhase(state); // Check initial phase
        }
        // Note: Potential is not recalculated here based on momentum change,
        // only during active actions like pulsate, discharge, or triggered transition.
        // This adds a layer of user interaction required to 'crystallize' momentum into potential.
    }


    /// @dev Calculates Potential from Momentum. Example: simple linear function.
    /// Can be more complex (e.g., non-linear) to represent energy conversion mechanics.
    /// @param momentum The momentum value.
    /// @return The calculated potential value.
    function _calculatePotentialFromMomentum(uint256 momentum) internal pure returns (uint256) {
        // Example: Potential is simply a fraction of Momentum, or based on thresholds
        // A more complex function could be:
        // if momentum < THRESHOLD_OSCILLATING_TO_ENTANGLED, potential = 0
        // if momentum >= THRESHOLD_OSCILLATING_TO_ENTANGLED, potential = (momentum - THRESHOLD_OSCILLATING_TO_ENTANGLED) / 10
        return momentum / 10; // Simple linear example
    }

    /// @dev Checks momentum/potential thresholds and transitions phase if necessary.
    /// Assumes momentum and potential are already updated.
    /// @param state User's state struct reference.
    function _checkAndTransitionPhase(UserFlowState storage state) internal {
        Phase oldPhase = state.phase;
        Phase newPhase = oldPhase; // Assume no change initially

        uint256 currentMomentum = state.momentum;
        // uint256 currentPotential = state.potential; // Use potential for phase transitions too?

        // Check upward transitions
        if (oldPhase == Phase.Inert && currentMomentum >= THRESHOLD_INERT_TO_OSCILLATING) {
            newPhase = Phase.Oscillating;
        } else if (oldPhase == Phase.Oscillating && currentMomentum >= THRESHOLD_OSCILLATING_TO_ENTANGLED) {
            newPhase = Phase.Entangled;
        } else if (oldPhase == Phase.Entangled && currentMomentum >= THRESHOLD_ENTANGLED_TO_CRITICAL) {
            newPhase = Phase.Critical;
        }

        // Check downward transitions (decay)
        // Note: Order matters if multiple thresholds are crossed simultaneously.
        // We check highest phases first for downward transitions.
        if (oldPhase == Phase.Critical && currentMomentum < THRESHOLD_CRITICAL_TO_OSCILLATING_DECAY) {
             newPhase = Phase.Entangled; // Can decay multiple steps if momentum drops significantly
             if (currentMomentum < THRESHOLD_ENTANGLED_TO_OSCILLATING_DECAY) {
                 newPhase = Phase.Oscillating;
                 if (currentMomentum < THRESHOLD_OSCILLATING_TO_INERT_DECAY) {
                     newPhase = Phase.Inert;
                 }
             }
        } else if (oldPhase == Phase.Entangled && currentMomentum < THRESHOLD_ENTANGLED_TO_OSCILLATING_DECAY) {
             newPhase = Phase.Oscillating;
             if (currentMomentum < THRESHOLD_OSCILLATING_TO_INERT_DECAY) {
                 newPhase = Phase.Inert;
             }
        } else if (oldPhase == Phase.Oscillating && currentMomentum < THRESHOLD_OSCILLATING_TO_INERT_DECAY) {
            newPhase = Phase.Inert;
        }

        if (newPhase != oldPhase) {
            state.phase = newPhase;
            emit PhaseTransitioned(msg.sender, oldPhase, newPhase);
        }
    }

    /// @dev Placeholder for logic executed just before a user's state is updated.
    /// @param account The user's address.
    /// @param stateType "active" or "staked".
    /// @param state The state struct reference.
    function _beforeStateUpdate(address account, string memory stateType, UserFlowState storage state) internal view {
        // Future use: Implement hooks, checks, or pre-calculations here
    }

    /// @dev Placeholder for logic executed just after a user's state is updated.
    /// @param account The user's address.
    /// @param stateType "active" or "staked".
    /// @param state The state struct reference.
    function _afterStateUpdate(address account, string memory stateType, UserFlowState storage state) internal view {
        // Future use: Implement hooks, checks, or post-calculations here
    }

    // --- Core User Functions ---

    /// @notice Deposits BaseToken to acquire QuantumFlow balance and initialize/update state.
    /// @param amount The amount of BaseToken to deposit.
    function depositBaseToken(uint256 amount) external nonReentrant whenNotPaused {
        if (amount == 0) revert QuantumFlow__InvalidAmount();

        // Ensure the contract can pull the tokens
        s_baseToken.safeTransferFrom(msg.sender, address(this), amount);

        // Update user's active flow state
        UserFlowState storage state = s_activeFlowState[msg.sender];

        _beforeStateUpdate(msg.sender, "active", state);

        // Update balance FIRST, then update state based on new balance
        state.balance += amount;

        // Initialize state if first deposit, otherwise update time/accruals
        if (state.lastUpdateTime == 0) {
             state.lastUpdateTime = uint48(block.timestamp);
             state.phase = Phase.Inert; // Start in Inert phase
             state.momentum = 0;
             state.potential = 0;
        } else {
             _updateUserFlowState(state); // Update based on elapsed time and new balance
        }


        _afterStateUpdate(msg.sender, "active", state);

        emit Deposited(msg.sender, amount, state.balance);
    }

    /// @notice Redeems QuantumFlow balance for BaseToken. Restricted by current phase.
    /// @dev Only allowed when the user's active state is `Inert`.
    /// @param amount The amount of QuantumFlow balance to redeem.
    function redeemQuantumFlow(uint256 amount) external nonReentrant whenNotPaused {
        if (amount == 0) revert QuantumFlow__InvalidAmount();
        UserFlowState storage state = s_activeFlowState[msg.sender];

        _beforeStateUpdate(msg.sender, "active", state);
        _updateUserFlowState(state); // Update state based on elapsed time BEFORE checking conditions
        _afterStateUpdate(msg.sender, "active", state); // Hooks *after* update but *before* conditional check/transfer

        if (state.balance < amount) revert QuantumFlow__InsufficientBalance();
        if (state.phase != Phase.Inert) revert QuantumFlow__RedemptionNotAllowedInCurrentPhase(state.phase);

        // Update balance
        state.balance -= amount;

        // Since balance changed, recalculate state parameters based on remaining balance
        // Note: Momentum/Potential decay or reset might be desirable on partial redemption.
        // For simplicity, we just update the state based on the new balance *from this point*.
        // A more complex model might require burning momentum/potential on redemption.
        _updateUserFlowState(state); // Update state again based on new balance

        // Transfer BaseToken back to the user
        s_baseToken.safeTransfer(msg.sender, amount);

        emit Redeemed(msg.sender, amount, state.balance);
    }

    /// @notice Performs a "Pulsate" action, actively boosting the Momentum of the active balance.
    /// @dev This action accelerates the state evolution. May have costs or cooldowns in a real system.
    function pulsate() external whenNotPaused {
        UserFlowState storage state = s_activeFlowState[msg.sender];
        if (state.balance == 0) revert QuantumFlow__InsufficientBalance();

        _beforeStateUpdate(msg.sender, "active", state);
        _updateUserFlowState(state); // Update state based on time first

        uint256 momentumBoost = (state.balance * PULSATE_MOMENTUM_BOOST_PER_UNIT) / (1e18); // Scale boost by 1e18 balance units

        // Check for potential overflow before adding
         if (state.momentum > type(uint256).max - momentumBoost) {
             state.momentum = type(uint256).max; // Cap momentum at max uint256
         } else {
             state.momentum += momentumBoost;
         }

        // Recalculate Potential based on the new Momentum
        state.potential = _calculatePotentialFromMomentum(state.momentum);

        // Re-check phase after momentum/potential update
        _checkAndTransitionPhase(state);

        _afterStateUpdate(msg.sender, "active", state);

        emit Pulsated(msg.sender, momentumBoost, state.momentum);
    }

    /// @notice Stakes a portion of the active QuantumFlow balance.
    /// @dev Staked balance might have different state evolution parameters (e.g., higher passive accrual).
    /// @param amount The amount of active balance to stake.
    function anchorFlow(uint256 amount) external whenNotPaused {
        if (amount == 0) revert QuantumFlow__InvalidAmount();
        UserFlowState storage activeState = s_activeFlowState[msg.sender];
        UserFlowState storage stakedState = s_stakedFlowState[msg.sender];

        _beforeStateUpdate(msg.sender, "active", activeState);
        _updateUserFlowState(activeState); // Update active state before staking
        _afterStateUpdate(msg.sender, "active", activeState);

        if (activeState.balance < amount) revert QuantumFlow__InsufficientBalance();

        // Move balance from active to staked
        activeState.balance -= amount;
        stakedState.balance += amount;

        // Initialize staked state if first anchor, otherwise update
        _beforeStateUpdate(msg.sender, "staked", stakedState);
        if (stakedState.lastUpdateTime == 0) {
            stakedState.lastUpdateTime = uint48(block.timestamp);
            stakedState.phase = activeState.phase; // Inherit phase from active? Or start fresh? Let's inherit for continuity.
            stakedState.momentum = activeState.momentum * stakedState.balance / (stakedState.balance + activeState.balance); // Example: distribute momentum proportionally
             stakedState.potential = _calculatePotentialFromMomentum(stakedState.momentum);
        } else {
             // Merge logic: How to combine existing staked state with incoming active state?
             // Option 1: Weighted average of momentum/potential based on balances.
             // Option 2: Staked state continues its path, new staked amount gets initial state, states don't merge. (More complex to track multiple staked states)
             // Option 3 (Simple): Update staked state based on time, then just add the new balance amount. Momentum/potential from the active state is effectively 'lost' upon staking (or requires explicit transfer/merge logic).
             // Let's use a simple approach for this example: The staked state updates based on its *total* balance, the momentum/potential added from the incoming amount is zero initially or calculated simply.
             // Let's go with Option 1 (Weighted Average for simplicity here) - but this is a design choice.
             uint256 totalOldStaked = stakedState.balance - amount; // Staked balance *before* adding `amount`
             if (totalOldStaked > 0) {
                  stakedState.momentum = (stakedState.momentum * totalOldOldStaked + activeState.momentum * amount) / stakedState.balance;
                  stakedState.potential = (stakedState.potential * totalOldOldStaked + activeState.potential * amount) / stakedState.balance;
             } else { // First time staking
                 stakedState.momentum = activeState.momentum;
                 stakedState.potential = activeState.potential;
                 stakedState.phase = activeState.phase;
             }
             _updateUserFlowState(stakedState); // Update based on time and new balance
        }
         _afterStateUpdate(msg.sender, "staked", stakedState);


        // Update the active state again based on the reduced balance
        _updateUserFlowState(activeState);
         _afterStateUpdate(msg.sender, "active", activeState);


        emit Anchored(msg.sender, amount, activeState.balance, stakedState.balance);
    }


    /// @notice Unstakes a portion of the staked QuantumFlow balance.
    /// @param amount The amount of staked balance to release.
    function releaseAnchored(uint256 amount) external whenNotPaused {
        if (amount == 0) revert QuantumFlow__InvalidAmount();
        UserFlowState storage activeState = s_activeFlowState[msg.sender];
        UserFlowState storage stakedState = s_stakedFlowState[msg.sender];

        _beforeStateUpdate(msg.sender, "staked", stakedState);
        _updateUserFlowState(stakedState); // Update staked state before releasing
        _afterStateUpdate(msg.sender, "staked", stakedState);


        if (stakedState.balance < amount) revert QuantumFlow__InsufficientStakedBalance();

        // Move balance from staked to active
        stakedState.balance -= amount;
        activeState.balance += amount;

        // Merge logic: How to combine incoming staked state with existing active state?
        // Similar options as anchoring. Simple approach: Update active state based on time, then just add the new balance amount.
        _beforeStateUpdate(msg.sender, "active", activeState);
        if (activeState.lastUpdateTime == 0) {
             activeState.lastUpdateTime = uint48(block.timestamp);
             activeState.phase = stakedState.phase; // Inherit phase? Or start fresh? Inherit.
             activeState.momentum = stakedState.momentum * activeState.balance / (stakedState.balance + activeState.balance); // Example: distribute momentum proportionally
             activeState.potential = _calculatePotentialFromMomentum(activeState.momentum);
        } else {
             // Weighted Average (Similar to Anchor Flow Option 1)
             uint256 totalOldActive = activeState.balance - amount; // Active balance *before* adding `amount`
             if (totalOldActive > 0) {
                  activeState.momentum = (activeState.momentum * totalOldActive + stakedState.momentum * amount) / activeState.balance;
                  activeState.potential = (activeState.potential * totalOldActive + stakedState.potential * amount) / activeState.balance;
             } else { // Was empty active balance
                  activeState.momentum = stakedState.momentum;
                  activeState.potential = stakedState.potential;
                  activeState.phase = stakedState.phase;
             }
            _updateUserFlowState(activeState); // Update based on time and new balance
        }
         _afterStateUpdate(msg.sender, "active", activeState);


        // Update the staked state again based on the reduced balance
        _updateUserFlowState(stakedState);
        _afterStateUpdate(msg.sender, "staked", stakedState);


        emit ReleaseAnchored(msg.sender, amount, stakedState.balance, activeState.balance);
    }

    /// @notice Attempts to manually trigger a phase transition for the active state.
    /// @dev Calls the internal update function which includes the phase check logic.
    function triggerPhaseTransition() external whenNotPaused {
        UserFlowState storage state = s_activeFlowState[msg.sender];
        if (state.balance == 0) revert QuantumFlow__InsufficientBalance();

        _beforeStateUpdate(msg.sender, "active", state);
        _updateUserFlowState(state); // This helper performs the actual phase transition check
        _afterStateUpdate(msg.sender, "active", state);

        // No specific check needed here, _updateUserFlowState handles it internally and emits event
    }

    /// @notice Converts accumulated Potential in the active state into a BaseToken reward.
    /// @dev Reduces Potential amount and transfers corresponding BaseToken. Requires sufficient Potential.
    /// @param amountOfPotentialToDischarge The amount of potential to convert.
    function dischargePotential(uint256 amountOfPotentialToDischarge) external nonReentrant whenNotPaused {
        if (amountOfPotentialToDischarge == 0) revert QuantumFlow__InvalidAmount();
        UserFlowState storage state = s_activeFlowState[msg.sender];
         if (state.balance == 0) revert QuantumFlow__InsufficientBalance(); // Cannot discharge if balance is 0

        _beforeStateUpdate(msg.sender, "active", state);
        _updateUserFlowState(state); // Update state first

        if (state.potential < amountOfPotentialToDischarge) revert QuantumFlow__CannotDischargeInsufficientPotential();

        // Calculate reward amount
        uint256 baseTokenReward = (amountOfPotentialToDischarge * s_potentialRewardRate) / (1e18); // Example: scale rate by 1e18 denominator

        // Reduce Potential
        state.potential -= amountOfPotentialToDischarge;

        // Recalculate Momentum (Example: Discharging potential might reduce momentum)
        // state.momentum = state.momentum > amountOfPotentialToDischarge ? state.momentum - amountOfPotentialToDischarge : 0;

        // Re-check phase after state changes
        _checkAndTransitionPhase(state);

         _afterStateUpdate(msg.sender, "active", state);

        // Transfer reward
        if (baseTokenReward > 0) {
             // Check contract's BaseToken balance before transferring
             require(s_baseToken.balanceOf(address(this)) >= baseTokenReward, "Contract has insufficient BaseToken for reward");
            s_baseToken.safeTransfer(msg.sender, baseTokenReward);
        }


        emit PotentialDischarged(msg.sender, amountOfPotentialToDischarge, baseTokenReward, state.potential);
    }

    /// @notice Requests a verifiable random number from Chainlink VRF.
    /// @dev This triggers a random event potentially affecting the user's state.
    /// Requires the user to pre-fund the contract with LINK for the fee (handled by VRFConsumerBase).
    function requestQuantumFluctuation() external nonReentrant whenNotPaused {
         if (s_keyHash == bytes32(0) || s_fee == 0 || VRFCoordinator() == address(0)) revert QuantumFlow__InvalidVRFConfig();

        // Store the user's address associated with the request ID
        bytes32 requestId = rawFulfillRandomness(s_keyHash, s_vrfRequestIdCounter); // Request randomness
        s_vrfRequests[requestId] = msg.sender;
        s_vrfRequestIdCounter++; // Increment counter for next request

        emit FluctuationRequested(msg.sender, requestId, s_fee);
    }

    /// @notice Callback function used by VRF Coordinator to return randomness.
    /// @dev This function is automatically called by the VRF Coordinator contract. DO NOT CALL DIRECTLY.
    /// Implements the random event logic based on the randomness provided.
    /// @param requestId The ID of the VRF request.
    /// @param randomness The verifiable random number.
    function fulfillRandomness(bytes32 requestId, uint256 randomness) internal override {
        // Ensure this request ID is valid and hasn't been fulfilled
        address requestingUser = s_vrfRequests[requestId];
        require(requestingUser != address(0), "Request ID not found");

        // Remove the request from the mapping to prevent double fulfillment
        delete s_vrfRequests[requestId];

        // --- Random Event Logic ---
        UserFlowState storage state = s_activeFlowState[requestingUser];
         // It's crucial to update state based on time before applying random effects
        _beforeStateUpdate(requestingUser, "active", state);
        _updateUserFlowState(state);
        _afterStateUpdate(requestingUser, "active", state);


        uint256 randomMod = randomness % 100; // Use modulo for different outcomes (e.g., 0-99)
        string memory outcomeDescription;

        if (randomMod < 20) { // 20% chance
            // Outcome: Minor Potential Boost
            uint256 potentialBoost = (state.balance * 50) / 1e18; // Example boost
            state.potential += potentialBoost;
            outcomeDescription = "Minor Potential Boost";
             // Momentum might also increase or stay same
        } else if (randomMod < 30) { // 10% chance
            // Outcome: Significant Momentum Spike
            uint256 momentumBoost = (state.balance * 500) / 1e18; // Example boost
             if (state.momentum > type(uint256).max - momentumBoost) {
                 state.momentum = type(uint256).max; // Cap
             } else {
                 state.momentum += momentumBoost;
             }
             state.potential = _calculatePotentialFromMomentum(state.momentum); // Recalculate potential
            outcomeDescription = "Significant Momentum Spike";
        } else if (randomMod < 35) { // 5% chance
             // Outcome: Forced Phase Transition (e.g., immediately advance one phase if possible)
             Phase oldPhase = state.phase;
             if (state.phase == Phase.Inert && state.momentum >= THRESHOLD_INERT_TO_OSCILLATING) {
                 state.phase = Phase.Oscillating;
                 outcomeDescription = "Forced Phase Transition: Inert -> Oscillating";
             } else if (state.phase == Phase.Oscillating && state.momentum >= THRESHOLD_OSCILLATING_TO_ENTANGLED) {
                  state.phase = Phase.Entangled;
                  outcomeDescription = "Forced Phase Transition: Oscillating -> Entangled";
             } else if (state.phase == Phase.Entangled && state.momentum >= THRESHOLD_ENTANGLED_TO_CRITICAL) {
                 state.phase = Phase.Critical;
                 outcomeDescription = "Forced Phase Transition: Entangled -> Critical";
             } else {
                 // If criteria not met for upward transition, maybe a downward decay?
                 // Or just a null event or a small boost instead. Let's do a small boost if no transition.
                 uint256 potentialBoost = (state.balance * 10) / 1e18;
                 state.potential += potentialBoost;
                 outcomeDescription = "Phase transition attempted but thresholds not met. Small Potential Boost.";
             }
             if (state.phase != oldPhase && bytes(outcomeDescription).length == 0) { // If phase changed but description wasn't set above
                 outcomeDescription = string(abi.encodePacked("Forced Phase Transition: ", getPhaseName(oldPhase), " -> ", getPhaseName(state.phase)));
                  emit PhaseTransitioned(requestingUser, oldPhase, state.phase); // Emit phase transition event
             } else if (bytes(outcomeDescription).length == 0) {
                  outcomeDescription = "No Phase Transition Triggered (Thresholds not met)";
             }


        } else if (randomMod < 40) { // 5% chance
            // Outcome: Partial Potential Discharge (uncontrolled, but maybe rewarded)
            uint256 dischargeAmount = state.potential / 5; // Discharge 20% of potential
            if (dischargeAmount > 0) {
                 uint256 baseTokenReward = (dischargeAmount * s_potentialRewardRate) / (1e18); // Scale rate by 1e18
                 state.potential -= dischargeAmount;
                 if (baseTokenReward > 0) {
                      // Check contract's BaseToken balance before transferring
                      if (s_baseToken.balanceOf(address(this)) >= baseTokenReward) {
                         s_baseToken.safeTransfer(requestingUser, baseTokenReward);
                         outcomeDescription = string(abi.encodePacked("Partial Potential Discharge & Reward (", Strings.toString(baseTokenReward), " BaseToken)"));
                      } else {
                         outcomeDescription = "Partial Potential Discharge (Insufficient BaseToken for reward)";
                      }
                 } else {
                      outcomeDescription = "Partial Potential Discharge (No Reward)";
                 }
                 emit PotentialDischarged(requestingUser, dischargeAmount, baseTokenReward, state.potential);
            } else {
                 outcomeDescription = "Partial Potential Discharge (No Potential to discharge)";
            }
             // Re-check phase after state changes
             _checkAndTransitionPhase(state);

        } else { // 60% chance (or whatever remains)
            // Outcome: Minor State Fluctuation (small momentum gain/loss, or nothing significant)
             if (randomMod % 2 == 0) { // 30% gain
                 uint256 momentumChange = (state.balance * 10) / 1e18;
                 if (state.momentum > type(uint256).max - momentumChange) state.momentum = type(uint256).max; else state.momentum += momentumChange;
                 outcomeDescription = "Minor Momentum Gain";
             } else { // 30% loss
                 uint256 momentumChange = (state.balance * 5) / 1e18;
                 state.momentum = state.momentum > momentumChange ? state.momentum - momentumChange : 0;
                 outcomeDescription = "Minor Momentum Fluctuation (Loss)";
             }
              state.potential = _calculatePotentialFromMomentum(state.momentum); // Recalculate potential
             _checkAndTransitionPhase(state); // Check phase after fluctuation
        }

         // Final state update after random event
        _afterStateUpdate(requestingUser, "active", state);


        emit FluctuationOutcome(requestId, randomness, requestingUser, outcomeDescription);
    }


    // --- View Functions ---

    /// @notice Returns the active QuantumFlow balance for an account.
    /// @dev Note: Does not update state before returning. For current state details, use `getUserFlowState`.
    /// @param account The address to query.
    /// @return The active balance.
    function balanceOf(address account) public view returns (uint256) {
        // While _updateUserFlowState is needed for *dynamic* state (momentum, potential, phase),
        // the balance itself only changes via deposit/redeem/anchor/release functions.
        // So returning the stored balance here is sufficient and avoids state-changing calls in view.
        return s_activeFlowState[account].balance;
    }

    /// @notice Returns the staked QuantumFlow balance for an account.
    /// @dev Note: Does not update state before returning. For current state details, use `getStakedFlowState`.
    /// @param account The address to query.
    /// @return The staked balance.
    function stakedBalanceOf(address account) public view returns (uint256) {
        return s_stakedFlowState[account].balance;
    }

    /// @notice Returns the detailed state (balance, momentum, potential, phase, last update time)
    /// for the user's *active* QuantumFlow balance, calculated based on elapsed time.
    /// @param account The address to query.
    /// @return state The UserFlowState struct for the active balance.
    function getUserFlowState(address account) public view returns (UserFlowState memory state) {
         state = s_activeFlowState[account];
         // Simulate state update for view functions - DO NOT MODIFY STORAGE
         uint48 currentTime = uint48(block.timestamp);
         uint48 timeElapsed = currentTime - state.lastUpdateTime;

         if (timeElapsed > 0 && state.balance > 0) {
             uint256 passiveRate = state.phase == Phase.Inert ? PASSIVE_MOMENTUM_PER_SECOND_ACTIVE : (state.phase == Phase.Critical ? PASSIVE_MOMENTUM_PER_SECOND_STAKED : PASSIVE_MOMENTUM_PER_SECOND_ACTIVE); // Use active rate here

              uint256 timeElapsedUint = timeElapsed;
              uint256 balanceUint = state.balance;
              uint256 passiveRateUint = passiveRate;

              uint256 passiveMomentumGain = (balanceUint * passiveRateUint * timeElapsedUint) / (1e18);

              // Simulate momentum increase
              state.momentum += passiveMomentumGain;

              // Simulate potential recalculation (if needed, based on _updateUserFlowState logic)
              // state.potential = _calculatePotentialFromMomentum(state.momentum);

              // Simulate phase transition check
              // This is complex in a view function as it requires checking thresholds
              // A simpler approach for view is to just show the *current* state derived from updated momentum
              // and let the user call triggerPhaseTransition() to potentially move phase.
              // For a sophisticated view, you would re-implement _checkAndTransitionPhase logic here without state modification.
              // Let's recalculate potential and show the phase based on *that* potential/momentum for the view.
              state.potential = _calculatePotentialFromMomentum(state.momentum);
              // Re-check and set state.phase in the memory struct based on thresholds
              // This is slightly redundant with _checkAndTransitionPhase but required for accurate view.
                if (state.phase == Phase.Inert && state.momentum >= THRESHOLD_INERT_TO_OSCILLATING) state.phase = Phase.Oscillating;
                if (state.phase == Phase.Oscillating && state.momentum >= THRESHOLD_OSCILLATING_TO_ENTANGLED) state.phase = Phase.Entangled;
                if (state.phase == Phase.Entangled && state.momentum >= THRESHOLD_ENTANGLED_TO_CRITICAL) state.phase = Phase.Critical;

                if (state.phase == Phase.Critical && state.momentum < THRESHOLD_CRITICAL_TO_OSCILLATING_DECAY) state.phase = Phase.Entangled;
                if (state.phase == Phase.Entangled && state.momentum < THRESHOLD_ENTANGLED_TO_OSCILLATING_DECAY) state.phase = Phase.Oscillating;
                if (state.phase == Phase.Oscillating && state.momentum < THRESHOLD_OSCILLATING_TO_INERT_DECAY) state.phase = Phase.Inert;

             state.lastUpdateTime = currentTime; // Simulate update time in memory struct
         }
         return state;
    }

     /// @notice Returns the detailed state (balance, momentum, potential, phase, last update time)
    /// for the user's *staked* QuantumFlow balance, calculated based on elapsed time.
    /// @param account The address to query.
    /// @return state The UserFlowState struct for the staked balance.
    function getStakedFlowState(address account) public view returns (UserFlowState memory state) {
        state = s_stakedFlowState[account];
         // Simulate state update for view functions - DO NOT MODIFY STORAGE
         uint48 currentTime = uint48(block.timestamp);
         uint48 timeElapsed = currentTime - state.lastUpdateTime;

         if (timeElapsed > 0 && state.balance > 0) {
             uint256 passiveRate = PASSIVE_MOMENTUM_PER_SECOND_STAKED; // Use staked rate here

              uint256 timeElapsedUint = timeElapsed;
              uint256 balanceUint = state.balance;
              uint256 passiveRateUint = passiveRate;

              uint256 passiveMomentumGain = (balanceUint * passiveRateUint * timeElapsedUint) / (1e18);

              // Simulate momentum increase
              state.momentum += passiveMomentumGain;

               // Simulate potential recalculation (if needed)
              // state.potential = _calculatePotentialFromMomentum(state.momentum);

              // Simulate phase transition check (similar logic as getUserFlowState view)
               state.potential = _calculatePotentialFromMomentum(state.momentum);
               if (state.phase == Phase.Inert && state.momentum >= THRESHOLD_INERT_TO_OSCILLATING) state.phase = Phase.Oscillating;
                if (state.phase == Phase.Oscillating && state.momentum >= THRESHOLD_OSCILLATING_TO_ENTANGLED) state.phase = Phase.Entangled;
                if (state.phase == Phase.Entangled && state.momentum >= THRESHOLD_ENTANGLED_TO_CRITICAL) state.phase = Phase.Critical;

                if (state.phase == Phase.Critical && state.momentum < THRESHOLD_CRITICAL_TO_OSCILLATING_DECAY) state.phase = Phase.Entangled;
                if (state.phase == Phase.Entangled && state.momentum < THRESHOLD_ENTANGLED_TO_OSCILLATING_DECAY) state.phase = Phase.Oscillating;
                if (state.phase == Phase.Oscillating && state.momentum < THRESHOLD_OSCILLATING_TO_INERT_DECAY) state.phase = Phase.Inert;

             state.lastUpdateTime = currentTime; // Simulate update time
         }
         return state;
    }

    /// @notice View function to calculate Potential from Momentum.
    /// @param momentum The momentum value.
    /// @return The calculated potential value.
    function calculatePotentialFromMomentum(uint256 momentum) public pure returns (uint256) {
        return _calculatePotentialFromMomentum(momentum);
    }

    /// @notice View function to get the phase transition thresholds.
    /// @return inertToOscillating Threshold for Inert to Oscillating.
    /// @return oscillatingToEntangled Threshold for Oscillating to Entangled.
    /// @return entangledToCritical Threshold for Entangled to Critical.
    /// @return criticalToOscillatingDecay Decay threshold from Critical.
    /// @return entangledToOscillatingDecay Decay threshold from Entangled.
    /// @return oscillatingToInertDecay Decay threshold from Oscillating.
    function getPhaseThresholds() public pure returns (
        uint256 inertToOscillating,
        uint256 oscillatingToEntangled,
        uint256 entangledToCritical,
        uint256 criticalToOscillatingDecay,
        uint256 entangledToOscillatingDecay,
        uint256 oscillatingToInertDecay
    ) {
        return (
            THRESHOLD_INERT_TO_OSCILLATING,
            THRESHOLD_OSCILLATING_TO_ENTANGLED,
            THRESHOLD_ENTANGLED_TO_CRITICAL,
            THRESHOLD_CRITICAL_TO_OSCILLATING_DECAY,
            THRESHOLD_ENTANGLED_TO_OSCILLATING_DECAY,
            THRESHOLD_OSCILLATING_TO_INERT_DECAY
        );
    }

    /// @notice View function to get the momentum accrual rates.
    /// @return passiveActive Passive rate for active balance.
    /// @return passiveStaked Passive rate for staked balance.
    /// @return pulsateBoost Active boost per unit on pulsate.
    function getAccrualRates() public pure returns (uint256 passiveActive, uint256 passiveStaked, uint256 pulsateBoost) {
        return (PASSIVE_MOMENTUM_PER_SECOND_ACTIVE, PASSIVE_MOMENTUM_PER_SECOND_STAKED, PULSATE_MOMENTUM_BOOST_PER_UNIT);
    }

    /// @notice View function to get the Base Token address.
    /// @return The address of the Base Token.
    function getBaseTokenAddress() public view returns (address) {
        return address(s_baseToken);
    }

     /// @notice View function to get the VRF configuration parameters.
     /// @return coordinator The VRF Coordinator address.
     /// @return keyHash The VRF Key Hash.
     /// @return fee The VRF request fee.
     function getVRFParams() public view returns (address coordinator, bytes32 keyHash, uint256 fee) {
         return (VRFCoordinator(), s_keyHash, s_fee);
     }

    /// @notice View function to check if the contract is paused.
    /// @return True if paused, false otherwise.
    function isPaused() public view returns (bool) {
        return s_paused;
    }

    /// @notice View function to get the rate for converting Potential to BaseToken.
    /// @return The potential reward rate.
    function getPotentialRewardRate() public view returns (uint256) {
        return s_potentialRewardRate;
    }

    /// @notice Returns the string name for a given Phase enum value.
    /// @param phase The Phase enum value.
    /// @return The string name of the phase.
    function getPhaseName(Phase phase) public pure returns (string memory) {
        if (uint256(phase) < PHASE_NAMES.length) {
            return PHASE_NAMES[uint256(phase)];
        }
        return "Unknown Phase"; // Should not happen with valid enum
    }


    // --- Admin/Owner Functions ---

    /// @notice Sets the address of the Base Token. Only callable by the owner.
    /// @param _baseToken The new address for the Base Token.
    function setBaseToken(address _baseToken) external onlyOwner {
        require(address(_baseToken) != address(0), "BaseToken address cannot be zero");
        s_baseToken = IERC20(_baseToken);
    }

    /// @notice Sets the Chainlink VRF Coordinator address. Only callable by the owner.
    /// @param _vrfCoordinator The new VRF Coordinator address.
    function setVRFCoordinator(address _vrfCoordinator) external onlyOwner {
         rawSetVRFCoordinator(_vrfCoordinator); // Use VRFConsumerBase function
    }

    /// @notice Sets the Chainlink VRF Key Hash. Only callable by the owner.
    /// @param _keyHash The new VRF Key Hash.
    function setVRFKeyHash(bytes32 _keyHash) external onlyOwner {
        s_keyHash = _keyHash;
    }

    /// @notice Sets the fee required for VRF requests. Only callable by the owner.
    /// @param _fee The new fee amount (in LINK).
    function setVRFFee(uint256 _fee) external onlyOwner {
        s_fee = _fee;
    }

    /// @notice Sets the rate for converting Potential to BaseToken during discharge. Only callable by the owner.
    /// @param _rate The new potential reward rate (in BaseToken smallest units per Potential unit).
    function setPotentialRewardRate(uint256 _rate) external onlyOwner {
        s_potentialRewardRate = _rate;
    }

    /// @notice Pauses core contract operations. Only callable by the owner.
    function pause() external onlyOwner whenNotPaused {
        s_paused = true;
        emit Paused(msg.sender);
    }

    /// @notice Unpauses core contract operations. Only callable by the owner.
    function unpause() external onlyOwner {
        if (!s_paused) revert QuantumFlow__NotPaused();
        s_paused = false;
        emit Unpaused(msg.sender);
    }

    /// @notice Allows the owner to recover accidentally sent ERC-20 tokens.
    /// @dev Cannot be used to recover the BaseToken itself, as that is managed.
    /// @param tokenAddress The address of the ERC-20 token to recover.
    /// @param amount The amount of tokens to recover.
    function recoverERC20(address tokenAddress, uint256 amount) external onlyOwner nonReentrant {
        if (tokenAddress == address(s_baseToken)) revert QuantumFlow__RecoverBaseTokenNotAllowed(); // Prevent recovering the managed BaseToken
        IERC20 token = IERC20(tokenAddress);
        token.safeTransfer(owner(), amount);
        emit Recovered(tokenAddress, owner(), amount);
    }

    // --- Receive/Fallback (Optional but Good Practice) ---
    // receive() external payable {
    //     // Potentially handle receiving native currency (ETH).
    //     // If you want to allow users to deposit ETH instead of an ERC-20,
    //     // this would need to be significantly expanded.
    // }

    // fallback() external payable {
    //     // Handle calls to undefined functions.
    // }
}
```