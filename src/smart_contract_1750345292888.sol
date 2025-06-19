Okay, here is a Solidity smart contract concept called "ChronoVault". This contract focuses on dynamic staking based on time, evolution, delegation, and a unique "System Energy" parameter that influences rewards. It aims to be distinct from standard staking contracts by introducing state-dependent mechanics and interaction types.

It includes advanced concepts like:
1.  **Time-Weighted Evolution:** Staked positions (TimeLock Units or TLUs) gain "evolution levels" over time, unlocking enhanced features and rewards.
2.  **Dynamic Rewards:** Reward rates are influenced by the TLU's evolution level and a system-wide `systemEnergy` parameter.
3.  **Partial Delegation:** Users can delegate specific rights (like claiming rewards) for their staked positions to other addresses.
4.  **State-Dependent Penalties:** Early withdrawal penalties decrease as the position approaches maturity.
5.  **Bonding to Existing Position:** Users can add more tokens to an existing TLU, affecting its future evolution trajectory.
6.  **Restaking Rewards:** An auto-compounding-like feature to restake earned rewards into a new TLU.
7.  **System Energy Mechanic:** A parameter controlled by governance or external logic (simulated here via governance) that acts as a global multiplier on reward rates, adding a layer of external influence.
8.  **Transferable Staked Positions:** Allowing ownership of the TLU itself to be transferred.

This contract uses two ERC-20 tokens: a `PotentialToken` (what users stake) and a `RewardToken` (what rewards are paid in). Interfaces for these are assumed.

---

**Smart Contract: ChronoVault**

**Outline:**

1.  **Pragma and Imports:** Specify Solidity version and necessary interfaces (ERC20).
2.  **Error Definitions:** Custom errors for clarity and gas efficiency.
3.  **Interfaces:** Basic ERC20 interfaces for staked and reward tokens.
4.  **State Variables:** Define contract owner, governance address, token addresses, global parameters (rates, energy), and sequence counters.
5.  **Structs:** Define the `TimeLockUnit` struct to hold details about each staked position.
6.  **Mappings:**
    *   `timeLockUnits`: Maps TLU ID to the `TimeLockUnit` struct.
    *   `userTLUs`: Maps user address to a list of their TLU IDs.
    *   `penaltyCollected`: Tracks accumulated penalties in `PotentialToken`.
7.  **Events:** Define events for key actions (TLU creation, claiming, withdrawal, delegation, parameter updates, etc.).
8.  **Modifiers:** Access control modifiers (`onlyGovernance`, `onlyTLUOwner`, `onlyTLUOwnerOrDelegatee`, `onlyActiveTLU`).
9.  **Internal Helpers:** Functions for calculations (evolution level, penalties, rewards).
10. **Constructor:** Initializes governance and potential token address.
11. **Governance/Admin Functions (min 6 functions):** Set token addresses, update parameters, manage system energy, collect penalties.
12. **TLU Management Functions (min 8 functions):** Create, extend, withdraw, claim rewards, bond more, transfer ownership, restake.
13. **Delegation Functions (min 3 functions):** Delegate, revoke delegation, claim using delegation.
14. **View Functions (min 3 functions):** Get TLU details, get user's TLUs, get system state.

**Function Summary (>= 20 Functions):**

1.  `constructor(address _potentialToken, address _rewardToken, address _governance)`: Initializes the contract, setting token addresses and governance.
2.  `setGovernance(address _newGovernance)`: **Governance** - Transfers governance ownership.
3.  `setPotentialToken(address _token)`: **Governance** - Sets the address of the staked token.
4.  `setRewardToken(address _token)`: **Governance** - Sets the address of the reward token.
5.  `updateBaseEvolutionRate(uint256 _rate)`: **Governance** - Updates the base rate for TLU evolution calculation.
6.  `updateEarlyWithdrawalPenaltyRate(uint256 _rate)`: **Governance** - Updates the percentage rate used for calculating early withdrawal penalties.
7.  `updateRewardMultiplierRates(uint256[] calldata _evolutionMultipliers, uint256 _systemEnergyMultiplier)`: **Governance** - Updates reward multipliers based on evolution level and system energy.
8.  `distributeSystemEnergy(uint256 _amount)`: **Governance** - Increases the global `systemEnergy`.
9.  `consumeSystemEnergy(uint256 _amount)`: **Governance** - Decreases the global `systemEnergy`.
10. `collectPenalties()`: **Governance** - Allows governance to withdraw collected penalty tokens.
11. `createTLU(uint256 _amount, uint256 _durationSeconds)`: Creates a new TimeLock Unit by staking `_amount` of `PotentialToken` for `_durationSeconds`. Requires token approval.
12. `extendTLUDuration(uint256 _tluId, uint256 _extraDurationSeconds)`: Extends the lock duration of an existing active TLU.
13. `bondMoreToTLU(uint256 _tluId, uint256 _extraAmount)`: Adds `_extraAmount` of `PotentialToken` to an existing active TLU, recalculating its effective start time and resetting evolution level based on the weighted average. Requires token approval.
14. `withdrawTLU(uint256 _tluId)`: Allows the TLU owner to withdraw their staked amount. Applies early withdrawal penalty if before maturity. Deactivates the TLU.
15. `claimTLURewards(uint256 _tluId)`: Allows the TLU owner or delegatee to claim accumulated `RewardToken` rewards for an active TLU. Updates the last claim time.
16. `transferTLUOwnership(uint256 _tluId, address _newOwner)`: Allows the TLU owner to transfer the ownership of an active TLU to another address.
17. `delegateClaimRight(uint256 _tluId, address _delegatee)`: Allows the TLU owner to set an address that can claim rewards for this TLU.
18. `revokeClaimRight(uint256 _tluId)`: Allows the TLU owner to remove any previously set claim delegatee.
19. `claimDelegatedTLURewards(uint256 _tluId)`: Allows the assigned delegatee to claim rewards for a specific TLU.
20. `restakeClaimedRewards(uint256 _tluId, uint256 _newDurationSeconds)`: Claims rewards for the specified TLU and immediately stakes them into a *new* TLU with the specified duration. Requires contract to have approval for reward tokens (e.g., from a reward distribution mechanism).
21. `getTLU(uint256 _tluId)`: **View** - Returns the details of a specific TimeLock Unit.
22. `getUserTLUs(address _user)`: **View** - Returns the list of TLU IDs owned by a specific user.
23. `getTLUEvolutionLevel(uint256 _tluId)`: **View** - Calculates and returns the current evolution level of a TLU based on its age and the base rate.
24. `getClaimableRewards(uint256 _tluId)`: **View** - Calculates and returns the current claimable `RewardToken` amount for a TLU since the last claim.
25. `calculateEarlyWithdrawalPenalty(uint256 _tluId)`: **View** - Calculates the potential penalty amount if the TLU were withdrawn now.
26. `getSystemEnergy()`: **View** - Returns the current global `systemEnergy` value.
27. `getPenaltyCollected()`: **View** - Returns the total amount of `PotentialToken` collected from penalties.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol"; // Using Ownable for Governance pattern simplicity
import "@openzeppelin/contracts/utils/math/SafeMath.sol"; // SafeMath is often useful for token calculations

/**
 * @title ChronoVault
 * @dev A smart contract for dynamic, time-weighted staking with evolution, delegation, and a system energy mechanic.
 * Users stake PotentialToken into TimeLock Units (TLUs) which evolve over time,
 * granting increased RewardToken claim rates. Claiming can be delegated.
 * Early withdrawals incur penalties. A global System Energy parameter
 * influences reward rates.
 *
 * Outline:
 * 1. Pragma and Imports
 * 2. Error Definitions
 * 3. Interfaces (IERC20)
 * 4. State Variables
 * 5. Structs (TimeLockUnit)
 * 6. Mappings
 * 7. Events
 * 8. Modifiers
 * 9. Internal Helpers (Calculations)
 * 10. Constructor
 * 11. Governance/Admin Functions
 * 12. TLU Management Functions
 * 13. Delegation Functions
 * 14. View Functions
 *
 * Function Summary:
 * 1. constructor(address _potentialToken, address _rewardToken, address _governance)
 * 2. setGovernance(address _newGovernance): Governance
 * 3. setPotentialToken(address _token): Governance
 * 4. setRewardToken(address _token): Governance
 * 5. updateBaseEvolutionRate(uint256 _rate): Governance
 * 6. updateEarlyWithdrawalPenaltyRate(uint256 _rate): Governance
 * 7. updateRewardMultiplierRates(uint256[] calldata _evolutionMultipliers, uint256 _systemEnergyMultiplier): Governance
 * 8. distributeSystemEnergy(uint256 _amount): Governance
 * 9. consumeSystemEnergy(uint256 _amount): Governance
 * 10. collectPenalties(): Governance
 * 11. createTLU(uint256 _amount, uint256 _durationSeconds)
 * 12. extendTLUDuration(uint256 _tluId, uint256 _extraDurationSeconds)
 * 13. bondMoreToTLU(uint256 _tluId, uint256 _extraAmount)
 * 14. withdrawTLU(uint256 _tluId)
 * 15. claimTLURewards(uint256 _tluId)
 * 16. transferTLUOwnership(uint256 _tluId, address _newOwner)
 * 17. delegateClaimRight(uint256 _tluId, address _delegatee)
 * 18. revokeClaimRight(uint256 _tluId)
 * 19. claimDelegatedTLURewards(uint256 _tluId)
 * 20. restakeClaimedRewards(uint256 _tluId, uint256 _newDurationSeconds)
 * 21. getTLU(uint256 _tluId): View
 * 22. getUserTLUs(address _user): View
 * 23. getTLUEvolutionLevel(uint256 _tluId): View
 * 24. getClaimableRewards(uint256 _tluId): View
 * 25. calculateEarlyWithdrawalPenalty(uint256 _tluId): View
 * 26. getSystemEnergy(): View
 * 27. getPenaltyCollected(): View
 */

contract ChronoVault is Ownable {
    using SafeMath for uint256;

    // --- Error Definitions ---
    error ZeroAddress();
    error InvalidAmount();
    error InvalidDuration();
    error TLUDoesNotExist(uint256 tluId);
    error TLUInactive(uint256 tluId);
    error NotTLUOwner(uint256 tluId);
    error NotTLUOwnerOrDelegatee(uint256 tluId);
    error TLUNotMatured();
    error PenaltyGreaterThanAmount();
    error CannotDelegateSelf();
    error NotDelegatee(uint256 tluId);
    error EvolutionRateZero();
    error SystemEnergyBounds();
    error ArrayLengthMismatch();

    // --- State Variables ---
    IERC20 public potentialToken; // Token users stake
    IERC20 public rewardToken;    // Token distributed as rewards

    uint256 public nextTLUId = 1; // Counter for unique TLU IDs

    address public governance; // Address with administrative privileges

    uint256 public baseEvolutionRate = 86400; // Time in seconds for 1 evolution level (e.g., 1 day)
    uint256 public earlyWithdrawalPenaltyRate = 1000; // Basis points (1000 = 10%)

    // Multipliers for reward calculation based on evolution level
    // evolutionMultiplierRates[0] for level 0, [1] for level 1, etc.
    uint256[] public evolutionMultiplierRates;
    uint256 public systemEnergyMultiplier = 1e18; // Base multiplier (1e18 = 1x)
    uint256 public systemEnergy = 1e18;          // Current global system energy (starts at 1x multiplier)
    uint256 public constant MAX_SYSTEM_ENERGY = 2e18; // Max system energy (2x multiplier)

    uint256 public penaltyCollected; // Total PotentialToken collected from penalties

    // --- Structs ---
    struct TimeLockUnit {
        address staker;           // The original staker (owner can be transferred)
        uint256 amount;           // Amount of PotentialToken staked
        uint256 startTime;        // Timestamp when the TLU was created or last bonded more
        uint256 duration;         // Total duration from startTime
        uint256 lastClaimTime;    // Timestamp of the last reward claim
        bool isActive;            // Whether the TLU is still active (not withdrawn)
        address delegatedClaimer; // Address allowed to claim rewards (0x0 if none)
        uint256 effectiveStartTime; // Used for weighted average calculation when bonding
    }

    // --- Mappings ---
    mapping(uint256 => TimeLockUnit) public timeLockUnits;
    mapping(address => uint256[]) private userTLUs; // Not public to save gas iterating, provide helper function

    // --- Events ---
    event TLUCreated(uint256 indexed tluId, address indexed staker, uint256 amount, uint256 duration, uint256 startTime);
    event TLUExtended(uint256 indexed tluId, uint256 newDuration);
    event TLUAmountBonded(uint256 indexed tluId, uint256 extraAmount, uint256 newTotalAmount, uint256 newEffectiveStartTime);
    event TLUWithdrawn(uint256 indexed tluId, address indexed staker, uint256 amount, uint256 penaltyAmount);
    event TLURewardsClaimed(uint256 indexed tluId, address indexed stakerOrDelegatee, uint256 rewardAmount);
    event TLUOwnershipTransferred(uint256 indexed tluId, address indexed oldOwner, address indexed newOwner);
    event TLULastClaimTimeUpdated(uint256 indexed tluId, uint256 lastClaimTime);
    event ClaimRightDelegated(uint256 indexed tluId, address indexed delegator, address indexed delegatee);
    event ClaimRightRevoked(uint256 indexed tluId, address indexed delegator);
    event RestakeRewards(uint256 indexed oldTluId, uint256 indexed newTluId, uint256 restakedAmount, uint256 newDuration);
    event SystemEnergyUpdated(uint256 oldEnergy, uint256 newEnergy);
    event GovernanceTransferred(address indexed previousGovernor, address indexed newGovernor);
    event PotentialTokenSet(address indexed token);
    event RewardTokenSet(address indexed token);
    event BaseEvolutionRateUpdated(uint256 rate);
    event EarlyWithdrawalPenaltyRateUpdated(uint256 rate);
    event RewardMultiplierRatesUpdated();
    event PenaltyCollected(uint256 amount);


    // --- Modifiers ---
    modifier onlyGovernance() {
        if (msg.sender != governance) {
            revert OwnableUnauthorizedAccount(msg.sender); // Using Ownable's error
        }
        _;
    }

    modifier onlyTLUOwner(uint256 _tluId) {
        if (timeLockUnits[_tluId].staker != msg.sender) {
            revert NotTLUOwner(_tluId);
        }
        _;
    }

    modifier onlyTLUOwnerOrDelegatee(uint256 _tluId) {
        TimeLockUnit storage tlu = timeLockUnits[_tluId];
        if (tlu.staker != msg.sender && tlu.delegatedClaimer != msg.sender) {
            revert NotTLUOwnerOrDelegatee(_tluId);
        }
        _;
    }

    modifier onlyActiveTLU(uint256 _tluId) {
        if (!timeLockUnits[_tluId].isActive) {
            revert TLUInactive(_tluId);
        }
        _;
    }

    // --- Constructor ---
    constructor(address _potentialToken, address _rewardToken, address _governance) Ownable(msg.sender) {
        if (_potentialToken == address(0) || _rewardToken == address(0) || _governance == address(0)) {
            revert ZeroAddress();
        }
        potentialToken = IERC20(_potentialToken);
        rewardToken = IERC20(_rewardToken);
        governance = _governance;

        // Set initial default multiplier rates (e.g., level 0 = 1x, level 1 = 1.2x, level 2 = 1.5x, ...)
        // Represented in 1e18 scale (1x = 1e18)
        evolutionMultiplierRates = [1e18, 1_200_000_000_000_000_000, 1_500_000_000_000_000_000]; // Example: 1x, 1.2x, 1.5x

        // Renounce ownership from deployer and transfer to governance
        // (Optional, but good practice if governance takes over fully)
        // renounceOwnership(); // Note: Ownable requires separate transferOwnership -> acceptOwnership flow for safety
        // For simplicity here, constructor sets governance directly.
        emit GovernanceTransferred(msg.sender, _governance);
    }

    // --- Internal Helpers ---

    /**
     * @dev Calculates the current evolution level of a TLU based on its age and base rate.
     * Uses effectiveStartTime for age calculation after bonding.
     */
    function _calculateCurrentEvolutionLevel(uint256 _tluId) internal view returns (uint256) {
        TimeLockUnit storage tlu = timeLockUnits[_tluId];
        if (baseEvolutionRate == 0) {
             // Or return a specific level, depending on desired behavior
            revert EvolutionRateZero();
        }
        uint256 elapsed = block.timestamp - tlu.effectiveStartTime;
        return elapsed / baseEvolutionRate;
    }

    /**
     * @dev Calculates the potential penalty for early withdrawal.
     * Penalty decreases linearly as maturity is approached.
     */
    function _calculateEarlyWithdrawalPenalty(uint256 _tluId) internal view returns (uint256) {
        TimeLockUnit storage tlu = timeLockUnits[_tluId];
        uint256 maturityTime = tlu.startTime.add(tlu.duration);
        if (block.timestamp >= maturityTime) {
            return 0; // No penalty after maturity
        }

        uint256 totalDuration = tlu.duration;
        if (totalDuration == 0) {
            return tlu.amount.mul(earlyWithdrawalPenaltyRate).div(10000); // Handle 0 duration case (shouldn't happen with validation)
        }

        uint256 timeRemaining = maturityTime - block.timestamp;
        // Penalty is proportional to the time remaining
        // Penalty = (amount * penaltyRateBP / 10000) * (timeRemaining / totalDuration)
        uint256 basePenalty = tlu.amount.mul(earlyWithdrawalPenaltyRate).div(10000);
        return basePenalty.mul(timeRemaining).div(totalDuration);
    }

    /**
     * @dev Calculates the claimable RewardToken amount for a TLU.
     * Rate is based on staked amount, time since last claim, evolution level, and system energy.
     * Rewards are calculated incrementally based on the *average* evolution level during the claim period.
     * This simplified version uses the evolution level *at the time of claiming* for the whole period.
     * A more complex version would integrate over time.
     */
    function _calculateClaimableRewards(uint256 _tluId) internal view returns (uint256) {
        TimeLockUnit storage tlu = timeLockUnits[_tluId];
        if (tlu.amount == 0 || tlu.effectiveStartTime == 0 || address(rewardToken) == address(0)) {
            return 0; // No rewards possible
        }

        uint256 rewardsAccrualStartTime = tlu.lastClaimTime > tlu.effectiveStartTime ? tlu.lastClaimTime : tlu.effectiveStartTime;
        if (block.timestamp <= rewardsAccrualStartTime) {
            return 0; // No time has passed since last claim or start
        }

        uint256 timeElapsedSinceLastClaim = block.timestamp - rewardsAccrualStartTime;

        // Get evolution multiplier
        uint256 currentEvolutionLevel = _calculateCurrentEvolutionLevel(_tluId);
        uint256 evolutionMultiplier = 1e18; // Default 1x if level is beyond defined multipliers
        if (currentEvolutionLevel < evolutionMultiplierRates.length) {
            evolutionMultiplier = evolutionMultiplierRates[currentEvolutionLevel];
        } else if (evolutionMultiplierRates.length > 0) {
             // If level exceeds max defined, use the max defined level's multiplier
             evolutionMultiplier = evolutionMultiplierRates[evolutionMultiplierRates.length - 1];
        }


        // Calculate reward rate components (example logic)
        // This is a simplified example. Real systems might use per-second rates.
        // Rate is influenced by staked amount, time, evolution, and system energy.
        // Example: rewards = amount * (timeElapsed / some_time_unit) * evolutionMultiplier * systemEnergyMultiplier
        // Let's use a rate based on amount, time elapsed, evolution and system energy multipliers.
        // (Amount / 1e18) * timeElapsed * (evolutionMultiplier / 1e18) * (systemEnergyMultiplier / 1e18) * (systemEnergy / 1e18) * some_base_reward_rate
        // Simplified: Amount * timeElapsed * EvolutionMultiplier * SystemEnergyMultiplier * SystemEnergy / (1e18 * 1e18 * 1e18 * baseRateScaling)
        // Let's define a base reward rate factor, e.g., 1 token per unit time per staked token at base multipliers.
        // Needs careful scaling to avoid overflow and match token decimals. Assume 1e18 scaling for multipliers.
        // baseRewardRatePerSecondUnit is an abstract concept here, depends on token decimals and desired speed.
        // Let's assume reward is proportional to staked amount and time elapsed, scaled by multipliers.
        // Rewards = amount * timeElapsed * evolutionMultiplier * systemEnergy * systemEnergyMultiplier / (1e18 * 1e18 * 1e18 * 1000) // Example scaling

        // A more concrete example scaling factor:
        // Let's say base reward rate is 1 RewardToken per 1000 PotentialToken per Day at base multipliers (1e18).
        // Scaling factor: (1e18 / 1000) * (1e18 / 86400)  -- adjusted for time in seconds
        // Amount is in token decimals (e.g., 1e18 per token)
        // Rewards = (amount * timeElapsed * evolutionMultiplier * systemEnergy * systemEnergyMultiplier) / (1e18 * 1e18 * 1e18 * SCALING_FACTOR)
        // Let's just use a simple proportional scaling for demonstration:
        // rewards = amount * timeElapsed * evolutionMultiplier * systemEnergy * systemEnergyMultiplier / (1e18 * 1e18 * 1e18 * 1e18 * 1000) // adjust scaling factor

        // Let's simplify the calculation for demonstration, avoiding multiple large divisions.
        // Suppose a reward rate unit is `RewardToken per staked PotentialToken per second` at base multiplier.
        // We need to combine amount, time, and three 1e18-scaled multipliers.
        // rewards = (amount * timeElapsed * evolutionMultiplier / 1e18) * (systemEnergy / 1e18) * (systemEnergyMultiplier / 1e18) * base_reward_rate_scaled_per_second

        // To avoid massive numbers before division, rearrange:
        // rewards = (amount * timeElapsed * evolutionMultiplier) / 1e18 * (systemEnergy * systemEnergyMultiplier / (1e18 * 1e18)) * base_rate_scaled_per_second

        // Let's define a BASE_REWARD_POINTS_PER_SECOND_PER_TOKEN, eg 100 (meaning 0.01% APY roughly, adjust for decimals)
        // rewards = amount * timeElapsed * evolutionMultiplier * systemEnergy * systemEnergyMultiplier * BASE_REWARD_POINTS_PER_SECOND_PER_TOKEN / (1e18 * 1e18 * 1e18 * 10000) // 10000 for points scaling

        // Let's use a slightly simpler approach, scale everything back to 1e18 after calculation steps
        // rewards = (amount * timeElapsed / 1e18) * (evolutionMultiplier / 1e18) * (systemEnergy / 1e18) * (systemEnergyMultiplier / 1e18) * BASE_RATE_FACTOR;
        // Multiply first, divide later:
        // rewards = (amount * timeElapsed);
        // rewards = (rewards / 1e18) * evolutionMultiplier; // need to handle scaling carefully
        // Using UQ112x112 or similar fixed point would be better, but let's stick to integer math
        // Assume all multipliers (evolution, systemEnergy, systemEnergyMultiplier) are 1e18 scaled.
        // Base reward points might be per second per token.
        // Let's define BASE_REWARD_RATE = 1e18 / (365 * 86400) * (1e18/10000); // 1 token per 10000 staked token per year, scaled
        // Let's use a fixed point style calculation without UQ libraries for demo:
        // `amount` is uint, `timeElapsed` is uint, multipliers are 1e18 scaled.
        // reward_per_second = (amount * evolutionMultiplier / 1e18) * (systemEnergy * systemEnergyMultiplier / 1e18) * BASE_RATE_POINTS / 10000
        // Total rewards = reward_per_second * timeElapsed
        // This requires careful division ordering to maintain precision.
        // Let's assume a simple base rate factor (e.g., 1e18 for 1x over some abstract unit of time)
        // Rewards = amount * timeElapsed * evolutionMultiplier * systemEnergy * systemEnergyMultiplier / (1e18 * 1e18 * 1e18 * 1e18 * SCALING_UNIT)
        // SCALING_UNIT depends on how amount/time/rate units align. Let's use 1e18 as a general scaling unit.

        // Rewards = amount * timeElapsed * evolutionMultiplier * systemEnergy * systemEnergyMultiplier / (1e18**4) needs 128-bit
        // Rewards = amount / 1e6 * timeElapsed / 1e6 * evolutionMultiplier / 1e6 * systemEnergy / 1e6 * systemEnergyMultiplier / 1e6 * some_factor / 1e6

        // Simplified Calculation (may lose precision, better with FixedPoint):
        // Calculate combined multiplier: (evolution * systemEnergy * systemEnergyMultiplier) / (1e18 * 1e18) -- assumes systemEnergyMultiplier is also 1e18 scaled
        uint256 combinedMultiplier = evolutionMultiplier.mul(systemEnergy).div(1e18).mul(systemEnergyMultiplier).div(1e18);
        // Rewards proportional to (amount * timeElapsed) * combinedMultiplier
        // rewards = (amount * timeElapsed).mul(combinedMultiplier).div(1e18) * BASE_REWARD_RATE_PER_SECOND_PER_TOKEN_SCALED;
        // Let's use a simple base rate, e.g., 1e18 reward tokens per 1e18 staked token per 365 days at base multipliers
        // BASE_RATE = 1e18 / (365 * 86400)
        // Rewards = amount * timeElapsed * combinedMultiplier * BASE_RATE / (1e18 * 1e18)
        // Rewards = (amount.mul(timeElapsed)).mul(combinedMultiplier).mul(1e18 / (365 * 86400)).div(1e18).div(1e18);

        // Even simpler: Use reward points per token per second per base multiplier unit (1e18)
        // Points per second = (amount * evolutionMultiplier * systemEnergy * systemEnergyMultiplier) / (1e18 * 1e18 * 1e18);
        // Total points = points per second * timeElapsed
        // Total rewards = Total points * REWARD_TOKEN_DECIMAL_SCALING / POINTS_SCALING

        // Let's define a simple base points per token per second at 1x multipliers (1e18)
        uint256 baseRewardPointsPerTokenPerSec = 1; // 1 point per token per sec at 1x/1x/1x
        // Total points = amount * timeElapsed * (evolution / 1e18) * (systemEnergy / 1e18) * (systemEnergyMultiplier / 1e18) * baseRewardPointsPerTokenPerSec
        // Total points = (amount * timeElapsed * evolutionMultiplier * systemEnergy * systemEnergyMultiplier) / (1e18 * 1e18 * 1e18) * baseRewardPointsPerTokenPerSec
        // Using SafeMath for uint256:
        uint256 rewardPoints = tlu.amount.mul(timeElapsed).div(1e18).mul(evolutionMultiplier).div(1e18).mul(systemEnergy).div(1e18).mul(systemEnergyMultiplier).div(1e18).mul(baseRewardPointsPerTokenPerSec);

        // Convert points to reward tokens. Assume 1 point = 1 wei of RewardToken for simplicity.
        return rewardPoints; // Needs adjustment for reward token decimals if not 1e18
         // If reward token has 18 decimals and 1 point = 1e0 wei, then return rewardPoints
         // If reward token has 6 decimals and 1 point = 1e0 wei, need to scale down

         // Let's assume 1 point represents 10^-X RewardTokens, or adjust calculation based on RewardToken decimals.
         // For demo, let's assume 1 point is 1 RewardToken (assuming 1e18 decimals for RewardToken)
         // This requires amount, timeElapsed, and multipliers to be combined and scaled correctly.
         // A robust calculation requires fixed-point math or careful handling of 1e18 units.

         // A safer simplified calculation using multiplication first where possible:
         // Assume base reward rate factor `R` such that reward = Amount * Time * Mult_e * Mult_se * Mult_sem * R
         // R would be small, e.g. 1e18 / (365 days * 86400 sec * 1e18 * 1e18 * 1e18) if multipliers are 1e18 scaled.
         // Let's use a simplified points system again, where 1 point = 1e6 of RewardToken wei
         // Base reward rate: 1e6 points per 1e18 staked token per second at base multipliers
         uint256 basePointsRate = 1e6; // 1 point = 1e6 wei
         // Total points = amount * timeElapsed * (evo_mult/1e18) * (sys_energy/1e18) * (sys_energy_mult/1e18) * basePointsRate / 1e18
         // Total points = (amount * timeElapsed * evolutionMultiplier * systemEnergy * systemEnergyMultiplier * basePointsRate) / (1e18 * 1e18 * 1e18 * 1e18)
         // This still requires 128-bit multiplication.

         // Let's step back and make the reward logic simple for clarity, even if less precise:
         // Rewards per second = (amount / 1e18) * (evolutionMultiplier / 1e18) * (systemEnergy / 1e18) * (systemEnergyMultiplier / 1e18) * BASE_RATE_PER_TOKEN_PER_SECOND (e.g. 1e12 for 1e-6 RewardToken)
         // Total Rewards = Rewards per second * timeElapsed
         // Total Rewards = (amount * evolutionMultiplier * systemEnergy * systemEnergyMultiplier * timeElapsed * BASE_RATE_PER_TOKEN_PER_SECOND) / (1e18 * 1e18 * 1e18 * 1e18)

         // Let's use a simple base rate `REWARD_PER_SECOND_PER_TOKEN_AT_BASE_MULTIPLIERS` scaled by 1e18
         // e.g., 1e18 / (365 * 86400) gives roughly 3e10, meaning 3e-8 reward token per staked token per sec
         uint256 BASE_RATE_PER_SECOND_SCALED = 1e18 / (365 * 86400); // 1 reward token per staked token per year (scaled)
         // Rewards = amount * timeElapsed * evolutionMultiplier * systemEnergy * systemEnergyMultiplier * BASE_RATE_PER_SECOND_SCALED / (1e18 * 1e18 * 1e18 * 1e18)
         // Need to multiply `amount` by `timeElapsed` and by all 1e18-scaled multipliers, then divide by (1e18)^4.
         // This requires 128-bit math unless values are small.
         // Example with uint256 only, requires careful division:
         uint256 temp = tlu.amount.div(1e6); // Reduce scale for intermediate calcs
         temp = temp.mul(timeElapsed).div(1e6);
         temp = temp.mul(evolutionMultiplier).div(1e9); // Divide by part of 1e18
         temp = temp.mul(systemEnergy).div(1e9);
         temp = temp.mul(systemEnergyMultiplier).div(1e9);
         temp = temp.mul(BASE_RATE_PER_SECOND_SCALED).div(1e9); // Final division parts

         // Let's simplify drastically for the demo contract's reward logic:
         // Reward rate is simply proportional to amount, time, evolution level, and system energy.
         // Let `reward_points_per_second_per_token_at_base = 100`
         // Total points = amount * timeElapsed * getEvolutionLevel * systemEnergy (scaled as integer levels) * basePointsRate
         // This needs discrete evolution levels, not continuous multiplier. Let's stick to multiplier.

         // Simpler multiplier application: Reward = amount * timeElapsed * combined_multiplier / 1e18
         // Combined_multiplier = (evolution * system * system_mult) / (1e18 * 1e18)
         // Rewards = amount * timeElapsed * (evo_mult * sys * sys_mult / 1e36)
         // Rewards = (amount * timeElapsed) * evo_mult / 1e18 * sys / 1e18 * sys_mult / 1e18
         // Use a base reward rate factor R (small number like 1e-12)
         // Rewards = amount * timeElapsed * evo_mult * sys * sys_mult * R / (1e18 * 1e18 * 1e18 * 1e18)
         // Or, scale R up: R_scaled = R * 1e18
         // Rewards = amount * timeElapsed * evo_mult * sys * sys_mult * R_scaled / (1e18 * 1e18 * 1e18 * 1e18 * 1e18)
         // Let's define a base rate per token per second, scaled by 1e18
         // Example: 1e18 RewardToken per 1e18 PotentialToken per Year @ base multipliers
         // Rate per second = 1e18 / (365 * 86400) ~ 31709792
         uint256 baseRatePerSecScaled = 31709792; // Approx 1 token/yr per staked token

         // Rewards = (amount * timeElapsed * evolutionMultiplier * systemEnergy * systemEnergyMultiplier) / (1e18 * 1e18 * 1e18) * baseRatePerSecScaled / 1e18
         // Using only uint256:
         uint256 rewardAmount = tlu.amount.mul(timeElapsed).div(1e18) // Scale amount by time
                               .mul(evolutionMultiplier).div(1e18)    // Apply evolution multiplier
                               .mul(systemEnergy).div(1e18)           // Apply system energy
                               .mul(systemEnergyMultiplier).div(1e18) // Apply energy multiplier
                               .mul(baseRatePerSecScaled).div(1e18);  // Apply base rate

        return rewardAmount;
    }

    // --- Governance/Admin Functions ---

    /**
     * @dev Transfers governance ownership. Can only be called by current governance.
     * @param _newGovernance The address of the new governance.
     */
    function setGovernance(address _newGovernance) external onlyGovernance {
        if (_newGovernance == address(0)) revert ZeroAddress();
        emit GovernanceTransferred(governance, _newGovernance);
        governance = _newGovernance;
    }

    /**
     * @dev Sets the address of the PotentialToken (staked token). Can only be called by governance.
     * Should typically only be called once during setup.
     * @param _token The address of the PotentialToken contract.
     */
    function setPotentialToken(address _token) external onlyGovernance {
        if (_token == address(0)) revert ZeroAddress();
        potentialToken = IERC20(_token);
        emit PotentialTokenSet(_token);
    }

    /**
     * @dev Sets the address of the RewardToken. Can only be called by governance.
     * Should typically only be called once during setup.
     * @param _token The address of the RewardToken contract.
     */
    function setRewardToken(address _token) external onlyGovernance {
        if (_token == address(0)) revert ZeroAddress();
        rewardToken = IERC20(_token);
        emit RewardTokenSet(_token);
    }

    /**
     * @dev Updates the base time rate for TLU evolution. Can only be called by governance.
     * @param _rate The new base time in seconds for 1 evolution level. Must be > 0.
     */
    function updateBaseEvolutionRate(uint256 _rate) external onlyGovernance {
        if (_rate == 0) revert InvalidDuration(); // Or a specific error like EvolutionRateZero()
        baseEvolutionRate = _rate;
        emit BaseEvolutionRateUpdated(_rate);
    }

    /**
     * @dev Updates the early withdrawal penalty rate in basis points. Can only be called by governance.
     * @param _rate The new penalty rate in basis points (e.g., 1000 for 10%).
     */
    function updateEarlyWithdrawalPenaltyRate(uint256 _rate) external onlyGovernance {
        earlyWithdrawalPenaltyRate = _rate;
        emit EarlyWithdrawalPenaltyRateUpdated(_rate);
    }

    /**
     * @dev Updates the reward multiplier rates for different evolution levels and the system energy multiplier.
     * Can only be called by governance.
     * @param _evolutionMultipliers An array of multipliers (1e18 scaled) for evolution levels 0, 1, 2...
     * @param _systemEnergyMultiplier The multiplier (1e18 scaled) applied alongside systemEnergy.
     */
    function updateRewardMultiplierRates(uint256[] calldata _evolutionMultipliers, uint256 _systemEnergyMultiplier) external onlyGovernance {
        evolutionMultiplierRates = _evolutionMultipliers;
        systemEnergyMultiplier = _systemEnergyMultiplier;
        emit RewardMultiplierRatesUpdated();
    }

    /**
     * @dev Increases the global system energy. Can only be called by governance.
     * System energy caps at MAX_SYSTEM_ENERGY.
     * @param _amount The amount to increase system energy by.
     */
    function distributeSystemEnergy(uint256 _amount) external onlyGovernance {
        uint256 oldEnergy = systemEnergy;
        systemEnergy = systemEnergy.add(_amount);
        if (systemEnergy > MAX_SYSTEM_ENERGY) {
            systemEnergy = MAX_SYSTEM_ENERGY;
        }
        emit SystemEnergyUpdated(oldEnergy, systemEnergy);
    }

    /**
     * @dev Decreases the global system energy. Can only be called by governance.
     * System energy cannot go below 0.
     * @param _amount The amount to decrease system energy by.
     */
    function consumeSystemEnergy(uint256 _amount) external onlyGovernance {
        uint256 oldEnergy = systemEnergy;
         if (_amount > systemEnergy) {
            systemEnergy = 0;
        } else {
            systemEnergy = systemEnergy.sub(_amount);
        }
        emit SystemEnergyUpdated(oldEnergy, systemEnergy);
    }

    /**
     * @dev Collects accumulated PotentialToken penalties. Can only be called by governance.
     */
    function collectPenalties() external onlyGovernance {
        uint256 amountToCollect = penaltyCollected;
        if (amountToCollect == 0) return;

        penaltyCollected = 0;
        // Governance receives the penalty tokens
        bool success = potentialToken.transfer(governance, amountToCollect);
        if (!success) {
             // Revert and potentially restore penaltyCollected if transfer fails unexpectedly
             // For simplicity here, we'll just revert.
             revert ERC20TransferFailed(governance, amountToCollect); // Using OpenZeppelin error
        }

        emit PenaltyCollected(amountToCollect);
    }

    // --- TLU Management Functions ---

    /**
     * @dev Creates a new TimeLock Unit by staking PotentialToken.
     * User must approve this contract to spend the _amount first.
     * @param _amount The amount of PotentialToken to stake.
     * @param _durationSeconds The duration in seconds for the lock. Must be > 0.
     */
    function createTLU(uint256 _amount, uint256 _durationSeconds) external {
        if (_amount == 0) revert InvalidAmount();
        if (_durationSeconds == 0) revert InvalidDuration();
        if (address(potentialToken) == address(0)) revert ZeroAddress(); // Tokens must be set

        uint256 tluId = nextTLUId++;
        uint256 currentTime = block.timestamp;

        // Transfer tokens from user to contract
        bool success = potentialToken.transferFrom(msg.sender, address(this), _amount);
        if (!success) {
            revert ERC20TransferFromFailed(msg.sender, address(this), _amount); // Using OpenZeppelin error
        }

        timeLockUnits[tluId] = TimeLockUnit({
            staker: msg.sender,
            amount: _amount,
            startTime: currentTime,
            duration: _durationSeconds,
            lastClaimTime: currentTime, // Rewards start accruing immediately
            isActive: true,
            delegatedClaimer: address(0), // No delegate initially
            effectiveStartTime: currentTime // Initially same as startTime
        });

        userTLUs[msg.sender].push(tluId);

        emit TLUCreated(tluId, msg.sender, _amount, _durationSeconds, currentTime);
    }

    /**
     * @dev Extends the lock duration of an existing active TLU.
     * Can only be called by the TLU owner.
     * @param _tluId The ID of the TLU to extend.
     * @param _extraDurationSeconds The extra duration in seconds to add. Must be > 0.
     */
    function extendTLUDuration(uint256 _tluId, uint256 _extraDurationSeconds) external onlyTLUOwner(_tluId) onlyActiveTLU(_tluId) {
        if (_extraDurationSeconds == 0) revert InvalidDuration();
        TimeLockUnit storage tlu = timeLockUnits[_tluId];
        tlu.duration = tlu.duration.add(_extraDurationSeconds);
        // Note: startTime and effectiveStartTime are NOT updated by extension,
        // which means evolution continues based on the original effective start time.
        emit TLUExtended(_tluId, tlu.duration);
    }

    /**
     * @dev Adds more PotentialToken to an existing active TLU.
     * Recalculates the effectiveStartTime based on a weighted average,
     * potentially resetting or affecting the evolution trajectory.
     * Can only be called by the TLU owner.
     * User must approve this contract to spend _extraAmount first.
     * @param _tluId The ID of the TLU to bond to.
     * @param _extraAmount The extra amount of PotentialToken to add. Must be > 0.
     */
    function bondMoreToTLU(uint256 _tluId, uint256 _extraAmount) external onlyTLUOwner(_tluId) onlyActiveTLU(_tluId) {
         if (_extraAmount == 0) revert InvalidAmount();
         if (address(potentialToken) == address(0)) revert ZeroAddress(); // Tokens must be set

         TimeLockUnit storage tlu = timeLockUnits[_tluId];
         uint256 oldAmount = tlu.amount;
         uint256 oldEffectiveStartTime = tlu.effectiveStartTime;
         uint256 currentTime = block.timestamp;

         // Transfer tokens from user to contract
         bool success = potentialToken.transferFrom(msg.sender, address(this), _extraAmount);
         if (!success) {
             revert ERC20TransferFromFailed(msg.sender, address(this), _extraAmount);
         }

         // Recalculate effective start time as a weighted average based on amount and time
         // new_effective_start_time = (old_amount * old_effective_start_time + extra_amount * current_time) / (old_amount + extra_amount)
         // This calculation needs careful scaling.
         // Let's simplify slightly for uint256, assuming 1e18 scale isn't needed for time itself
         uint256 newTotalAmount = oldAmount.add(_extraAmount);
         uint256 weightedStartTimeSum = oldAmount.mul(oldEffectiveStartTime).add(_extraAmount.mul(currentTime));
         uint256 newEffectiveStartTime = weightedStartTimeSum.div(newTotalAmount);

         tlu.amount = newTotalAmount;
         tlu.effectiveStartTime = newEffectiveStartTime;
         // Evolution level calculation will now be based on the new effectiveStartTime
         // lastClaimTime is NOT reset, allows claiming prior rewards before bonding

         emit TLUAmountBonded(_tluId, _extraAmount, newTotalAmount, newEffectiveStartTime);
    }

    /**
     * @dev Allows the TLU owner to withdraw their staked amount.
     * Applies an early withdrawal penalty if before maturity.
     * Deactivates the TLU. Rewards are forfeited upon withdrawal.
     * @param _tluId The ID of the TLU to withdraw.
     */
    function withdrawTLU(uint256 _tluId) external onlyTLUOwner(_tluId) onlyActiveTLU(_tluId) {
        TimeLockUnit storage tlu = timeLockUnits[_tluId];
        uint256 maturityTime = tlu.startTime.add(tlu.duration);
        uint256 amountToReturn = tlu.amount;
        uint256 penalty = 0;

        if (block.timestamp < maturityTime) {
            penalty = _calculateEarlyWithdrawalPenalty(_tluId);
            if (penalty > amountToReturn) revert PenaltyGreaterThanAmount(); // Should not happen with calculation logic, but safety check
            amountToReturn = amountToReturn.sub(penalty);
            penaltyCollected = penaltyCollected.add(penalty);
        }

        // Mark TLU as inactive *before* transferring tokens to prevent reentrancy with token callbacks
        tlu.isActive = false;
        tlu.amount = 0; // Zero out amount after withdrawal

        // Transfer staked amount back to the owner
        if (amountToReturn > 0) {
             bool success = potentialToken.transfer(tlu.staker, amountToReturn);
             if (!success) {
                 // Consider emergency recovery for tokens if transfer fails
                 // For simplicity here, we'll just revert.
                 revert ERC20TransferFailed(tlu.staker, amountToReturn);
             }
        }


        emit TLUWithdrawn(_tluId, tlu.staker, amountToReturn, penalty);
        // Note: TLU ID is not removed from user's list for simplicity, filtering inactive is needed client-side.
        // For gas efficiency on chain lookup, could maintain a separate list of active TLUs per user.
    }

    /**
     * @dev Allows the TLU owner or delegated claimer to claim accumulated RewardToken rewards.
     * Rewards are calculated from lastClaimTime to block.timestamp.
     * Updates the last claim time for the TLU.
     * @param _tluId The ID of the TLU to claim rewards for.
     */
    function claimTLURewards(uint256 _tluId) external onlyTLUOwnerOrDelegatee(_tluId) onlyActiveTLU(_tluId) {
        // This function logic is shared with claimDelegatedTLURewards,
        // only the permission check differs.
        _processClaim(_tluId);
    }

    /**
     * @dev Allows the TLU owner to transfer ownership of an active TLU to another address.
     * The new owner gains all rights to manage the TLU (withdraw, extend, bond, delegate, claim).
     * @param _tluId The ID of the TLU to transfer.
     * @param _newOwner The address of the new owner. Must not be zero address.
     */
    function transferTLUOwnership(uint256 _tluId, address _newOwner) external onlyTLUOwner(_tluId) onlyActiveTLU(_tluId) {
        if (_newOwner == address(0)) revert ZeroAddress();
        TimeLockUnit storage tlu = timeLockUnits[_tluId];
        address oldOwner = tlu.staker;

        // Remove TLU from old owner's list (less gas-efficient implementation)
        // More gas efficient: require client-side filtering or maintain separate active lists.
        // For this demo, let's assume client-side filtering is acceptable.
        // In a production system, managing the userTLUs mapping on transfer is complex and costly.

        tlu.staker = _newOwner;
        // Add TLU to new owner's list (less gas-efficient implementation)
        userTLUs[_newOwner].push(_tluId);

        emit TLUOwnershipTransferred(_tluId, oldOwner, _newOwner);
    }

    /**
     * @dev Claims rewards for a TLU and immediately restakes them into a new TLU.
     * Requires the contract to have allowance for `RewardToken` (e.g., from a separate distributor).
     * Can only be called by the TLU owner.
     * @param _tluId The ID of the TLU to claim and restake from.
     * @param _newDurationSeconds The duration for the new TLU created from restaked rewards. Must be > 0.
     */
    function restakeClaimedRewards(uint256 _tluId, uint256 _newDurationSeconds) external onlyTLUOwner(_tluId) onlyActiveTLU(_tluId) {
        if (_newDurationSeconds == 0) revert InvalidDuration();
        if (address(potentialToken) == address(0) || address(rewardToken) == address(0)) revert ZeroAddress(); // Tokens must be set

        TimeLockUnit storage tlu = timeLockUnits[_tluId];

        // Calculate claimable rewards
        uint256 rewardsToClaim = _calculateClaimableRewards(_tluId);
        if (rewardsToClaim == 0) return; // Nothing to restake

        // Update last claim time *before* token transfer
        tlu.lastClaimTime = block.timestamp;
        emit TLULastClaimTimeUpdated(_tluId, tlu.lastClaimTime);

        // Note: The reward tokens would typically be in a separate pool or distributed by another mechanism.
        // This function assumes the ChronoVault contract *receives* the reward tokens (e.g., pulled from a reward pool contract).
        // A realistic implementation would involve calling a RewardDistributor contract to get the rewards.
        // For this demo, we'll simulate receiving rewards - requiring prior setup where *this contract*
        // is approved by the reward source or receives tokens push-style.
        // Transfer rewards *to this contract*. This is a simplification; usually rewards go to user.
        // To restake, the reward tokens need to end up in the contract's balance or be minted/acquired by the contract.
        // Let's assume rewards are sent *to this contract* before this function is called, or the rewardToken.transferFrom logic is used if a reward pool contract has allowance.

        // Transfer rewards from the source (e.g., Reward Pool contract) to this contract
        // Requires the source to have approved this contract.
        // If the source is msg.sender (user), they'd need to transfer RewardToken to ChronoVault first.
        // This flow is complex. Simplest demo: Assume RewardToken is sent to ChronoVault and exists in its balance.
        // Or, assume a separate contract `RewardPool` exists with a `claimAndSend(uint256 amount, address recipient)` function.
        // Let's assume a simplified model where the `RewardToken` contract itself grants allowance to ChronoVault to pull from a "pool". This is unconventional.
        // A more standard approach: User calls RewardPool.claim(tluId) -> RewardPool sends REWARD_TOKEN to user -> User approves ChronoVault -> User calls ChronoVault.restake(amount, duration) -> ChronoVault.transferFrom(user, this, amount).
        // This requires two transactions. Let's stick to the model where the contract pulls, but acknowledge it's simplified.
        // Let's assume a function `rewardToken.transferFrom(rewardPoolAddress, address(this), rewardsToClaim)` was called prior or is part of a larger tx/system.
        // For the sake of keeping this contract self-contained for demo, let's *simulate* receiving rewards by just using the calculated amount.

        uint256 amountToRestake = rewardsToClaim;
        if (amountToRestake == 0) return; // Still nothing to restake after recalculation check

        uint256 newTluId = nextTLUId++;
        uint256 currentTime = block.timestamp;

        timeLockUnits[newTluId] = TimeLockUnit({
            staker: tlu.staker, // New TLU owned by original TLU owner
            amount: amountToRestake,
            startTime: currentTime,
            duration: _newDurationSeconds,
            lastClaimTime: currentTime,
            isActive: true,
            delegatedClaimer: address(0),
            effectiveStartTime: currentTime
        });

        userTLUs[tlu.staker].push(newTluId); // Add new TLU to owner's list

        emit RestakeRewards(_tluId, newTluId, amountToRestake, _newDurationSeconds);
        // Note: RewardToken tokens must actually exist in the contract's balance for this restake to be valid.
        // In a real system, tokens come from a reward source.
        // This function effectively converts claimable rewards (conceptual) into staked tokens (actual).
    }

    // --- Delegation Functions ---

    /**
     * @dev Allows the TLU owner to delegate the right to claim rewards for a specific TLU.
     * The delegatee can only call `claimDelegatedTLURewards`.
     * @param _tluId The ID of the TLU to delegate for.
     * @param _delegatee The address to delegate claiming rights to. Set to address(0) to revoke.
     */
    function delegateClaimRight(uint256 _tluId, address _delegatee) external onlyTLUOwner(_tluId) onlyActiveTLU(_tluId) {
        if (_delegatee == msg.sender) revert CannotDelegateSelf();
        TimeLockUnit storage tlu = timeLockUnits[_tluId];
        tlu.delegatedClaimer = _delegatee;
        emit ClaimRightDelegated(_tluId, msg.sender, _delegatee);
    }

    /**
     * @dev Revokes any existing claim delegation for a TLU.
     * Can only be called by the TLU owner.
     * @param _tluId The ID of the TLU to revoke delegation for.
     */
    function revokeClaimRight(uint256 _tluId) external onlyTLUOwner(_tluId) onlyActiveTLU(_tluId) {
        TimeLockUnit storage tlu = timeLockUnits[_tluId];
        if (tlu.delegatedClaimer == address(0)) return; // No delegation to revoke
        tlu.delegatedClaimer = address(0);
        emit ClaimRightRevoked(_tluId, msg.sender);
    }

    /**
     * @dev Allows the assigned delegatee to claim accumulated RewardToken rewards for a TLU.
     * @param _tluId The ID of the TLU to claim rewards for.
     */
    function claimDelegatedTLURewards(uint256 _tluId) external onlyActiveTLU(_tluId) {
        TimeLockUnit storage tlu = timeLockUnits[_tluId];
        if (tlu.delegatedClaimer != msg.sender || msg.sender == address(0)) {
            revert NotDelegatee(_tluId);
        }
        _processClaim(_tluId);
    }

    /**
     * @dev Internal function to process reward claims, used by claimTLURewards and claimDelegatedTLURewards.
     * @param _tluId The ID of the TLU.
     */
    function _processClaim(uint256 _tluId) internal onlyActiveTLU(_tluId) {
        if (address(rewardToken) == address(0)) revert ZeroAddress(); // Reward token must be set

        TimeLockUnit storage tlu = timeLockUnits[_tluId];
        uint256 claimableRewards = _calculateClaimableRewards(_tluId);

        if (claimableRewards == 0) return; // No rewards to claim

        // Update last claim time *before* token transfer
        tlu.lastClaimTime = block.timestamp;
        emit TLULastClaimTimeUpdated(_tluId, tlu.lastClaimTime);

        // Transfer rewards from contract to the staker
        // This assumes the contract has sufficient RewardToken balance.
        // Reward tokens would typically be sent to the contract via a reward distribution mechanism.
        bool success = rewardToken.transfer(tlu.staker, claimableRewards);
        if (!success) {
            // Consider emergency recovery for tokens if transfer fails
            // For simplicity here, we'll just revert.
            revert ERC20TransferFailed(tlu.staker, claimableRewards);
        }

        emit TLURewardsClaimed(_tluId, msg.sender, claimableRewards);
    }


    // --- View Functions ---

    /**
     * @dev Returns the details of a specific TimeLock Unit.
     * @param _tluId The ID of the TLU.
     * @return TimeLockUnit struct details.
     */
    function getTLU(uint256 _tluId) public view returns (TimeLockUnit memory) {
        // Read from public mapping, no extra check needed beyond existence
        return timeLockUnits[_tluId];
    }

    /**
     * @dev Returns the list of TLU IDs owned by a specific user.
     * Note: This list may contain inactive TLUs that require client-side filtering.
     * @param _user The address of the user.
     * @return An array of TLU IDs owned by the user.
     */
    function getUserTLUs(address _user) public view returns (uint256[] memory) {
        return userTLUs[_user];
    }

     /**
     * @dev Calculates and returns the current evolution level of a TLU based on its effective age.
     * @param _tluId The ID of the TLU.
     * @return The current evolution level (integer).
     */
    function getTLUEvolutionLevel(uint256 _tluId) public view returns (uint256) {
         if (_tluId == 0 || timeLockUnits[_tluId].effectiveStartTime == 0) revert TLUDoesNotExist(_tluId);
         return _calculateCurrentEvolutionLevel(_tluId);
    }

    /**
     * @dev Calculates and returns the current claimable RewardToken amount for a TLU.
     * Rewards are calculated from lastClaimTime to block.timestamp based on current state.
     * @param _tluId The ID of the TLU.
     * @return The amount of RewardToken currently claimable.
     */
    function getClaimableRewards(uint256 _tluId) public view returns (uint256) {
        if (_tluId == 0 || !timeLockUnits[_tluId].isActive) revert TLUInactive(_tluId); // Check existence and activity
        return _calculateClaimableRewards(_tluId);
    }

    /**
     * @dev Calculates the potential penalty amount if a TLU were withdrawn now.
     * Returns 0 if the TLU is already matured.
     * @param _tluId The ID of the TLU.
     * @return The potential penalty amount in PotentialToken.
     */
    function calculateEarlyWithdrawalPenalty(uint256 _tluId) public view returns (uint256) {
         if (_tluId == 0 || !timeLockUnits[_tluId].isActive) revert TLUInactive(_tluId); // Check existence and activity
         return _calculateEarlyWithdrawalPenalty(_tluId);
    }

    /**
     * @dev Returns the current global system energy value.
     * @return The current system energy (1e18 scaled).
     */
    function getSystemEnergy() public view returns (uint256) {
        return systemEnergy;
    }

    /**
     * @dev Returns the total amount of PotentialToken collected from early withdrawal penalties.
     * @return The total collected penalty amount.
     */
    function getPenaltyCollected() public view returns (uint256) {
        return penaltyCollected;
    }

    // Added missing Ownable error for completeness as it's imported
    error OwnableUnauthorizedAccount(address account);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    // Added missing ERC20 errors for completeness
    error ERC20TransferFailed(address to, uint256 amount);
    error ERC20TransferFromFailed(address from, address to, uint256 amount);
}
```