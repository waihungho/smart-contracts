Okay, let's create a smart contract called `QuantumVault`. This contract will be a time-locked vault for a specific ERC-20 token, featuring dynamic phases, an internal "Energy" points system based on stake duration, conditional withdrawals, stake merging, and other advanced concepts. It's designed to be more complex and engaging than a standard timelock.

**Concept:** The `QuantumVault` represents a system where tokens are locked across different "Phases" of operation. The rules for withdrawal, penalties, and reward (Energy) accrual change depending on the current Phase and how long the user's assets have been staked. It simulates complex state changes and time-dependent interactions.

---

**QuantumVault Smart Contract**

**Outline:**

1.  **State Variables:** Define key parameters, addresses, counters, mappings for users/stakes, current phase, phase timings, fees, etc.
2.  **Enums:** Define the possible phases of the contract and stake statuses.
3.  **Structs:** Define the structure to hold details about each individual stake (deposit).
4.  **Events:** Define events to signal important actions like deposits, withdrawals, phase transitions, energy claims, etc.
5.  **Modifiers:** Custom modifiers for access control and state checks.
6.  **Constructor:** Initialize the contract with the staking token address and initial parameters.
7.  **Phase Management:** Functions to get the current phase and potentially transition between phases.
8.  **Staking (Deposit):** Function for users to deposit tokens and create a stake.
9.  **Withdrawal:** Functions for users to withdraw stakes based on conditions, potentially with penalties or bonuses. Includes a function for emergency withdrawal.
10. **Energy System:** Functions related to the internal "Energy" points: claiming accumulated energy, checking claimable energy.
11. **Stake Management:** Functions to view user stakes, get stake details, check unlock status, and a function to merge existing stakes.
12. **View/Pure Functions:** Functions to retrieve contract state, calculate potential outcomes, and get user-specific information.
13. **Owner/Admin Functions:** Functions for the contract owner to set parameters, manage phases, and perform administrative tasks.
14. **Safety Features:** Pause/unpause functionality.

**Function Summary (27 Functions):**

1.  `constructor()`: Initializes the contract with the staking token address and initial owner.
2.  `deposit(uint256 _amount)`: Allows users to deposit the staking token and create a new time-locked stake.
3.  `withdrawStake(uint256 _stakeId)`: Allows a user to withdraw a specific stake if its lock time has passed and the contract phase allows. Calculates and applies bonuses/penalties.
4.  `cancelStake(uint256 _stakeId)`: Allows a user to withdraw a stake before its lock time expires, incurring a significant penalty. Only available in specific phases.
5.  `emergencyWithdraw(uint256 _stakeId)`: Allows the owner (or specific role) to enable emergency withdrawals for a limited time, often with a penalty. (Implementation will require owner permission).
6.  `claimEnergy()`: Allows a user to claim accumulated Energy points based on their active stakes' duration and current phase multipliers.
7.  `mergeStakes(uint256[] memory _stakeIds)`: Allows a user to merge multiple active stakes into a single new stake.
8.  `transitionToNextPhase()`: Allows the owner to advance the contract to the next operational phase. Requires specific conditions (e.g., time elapsed).
9.  `setLockDuration(uint256 _duration)`: Owner function to set the default lock duration for new stakes.
10. `setPhaseDuration(Phase _phase, uint256 _duration)`: Owner function to set the required time duration for a specific phase before transitioning.
11. `setPenaltyRate(uint256 _rate)`: Owner function to set the percentage penalty for early withdrawals (`cancelStake`).
12. `setEnergyMultiplier(Phase _phase, uint256 _multiplier)`: Owner function to set the Energy accrual multiplier for a specific phase.
13. `setMergeLockDuration(uint256 _duration)`: Owner function to set the lock duration for stakes created via merging.
14. `setEmergencyWithdrawPenalty(uint256 _rate)`: Owner function to set the penalty for emergency withdrawals.
15. `enableEmergencyWithdraw(uint256 _duration)`: Owner function to activate the emergency withdrawal mode for a limited time.
16. `disableEmergencyWithdraw()`: Owner function to deactivate the emergency withdrawal mode.
17. `pause()`: Owner function to pause certain contract operations (e.g., deposits, withdrawals).
18. `unpause()`: Owner function to unpause the contract.
19. `transferOwnership(address newOwner)`: Transfers contract ownership.
20. `renounceOwnership()`: Renounces contract ownership (sends to address(0)).
21. `getCurrentPhase()`: View function returning the current operational phase of the contract.
22. `getStakeDetails(uint256 _stakeId)`: View function returning the details of a specific stake.
23. `getUserStakes(address _user)`: View function returning an array of stake IDs belonging to a user.
24. `getTotalLocked()`: View function returning the total amount of staking tokens currently locked in all active stakes.
25. `getTotalDepositedByUser(address _user)`: View function returning the total initial deposit amount from a user across all their stakes (active, cancelled, withdrawn, merged).
26. `previewWithdrawal(uint256 _stakeId)`: Pure/View function calculating the potential withdrawal amount for a stake based on current rules, without performing the withdrawal.
27. `previewEnergyClaim()`: Pure/View function calculating the amount of Energy points a user can currently claim across all their active stakes.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

// Define the different operational phases of the vault
enum Phase {
    Initialization,    // Setup phase, limited operations
    DepositPhase,      // Users can deposit tokens
    ActivePhase,       // Main phase for staking, rewards accrue
    StabilizationPhase,// Withdrawal conditions might change, rewards may slow
    Expired            // Contract is winding down, only withdrawals allowed (maybe with final rules)
}

// Define the status of a stake
enum StakeStatus {
    Active,
    Withdrawn,
    Cancelled,
    Merged
}

// Structure to hold details for each individual stake
struct StakeDetails {
    address owner;
    uint256 amount;       // Initial deposited amount
    uint256 startTime;    // Timestamp when the stake was created
    uint256 lockDuration; // Duration in seconds the stake is locked
    StakeStatus status;   // Current status of the stake
    uint256 lastEnergyClaimTime; // Timestamp of the last energy claim for this stake
    uint256 claimedEnergy;       // Total energy claimed from this stake
}

contract QuantumVault is Ownable, Pausable, ReentrancyGuard {

    IERC20 public immutable stakingToken; // The ERC-20 token being staked

    Phase public currentPhase;             // Current operational phase
    uint256 public lastPhaseTransitionTime; // Timestamp of the last phase change

    // Phase configurations
    mapping(Phase => uint256) public phaseDurations; // Duration required for each phase
    mapping(Phase => uint256) public phaseEnergyMultipliers; // Multiplier for energy accrual in each phase

    uint256 public defaultLockDuration = 365 days; // Default lock duration for new stakes
    uint256 public earlyWithdrawPenaltyRate = 10; // % penalty (e.g., 10 for 10%)
    uint256 public mergeLockDuration = 730 days; // Lock duration for stakes created by merging

    // Stake storage
    uint256 private nextStakeId = 1; // Counter for unique stake IDs
    mapping(uint256 => StakeDetails) public stakes; // Map stake ID to its details
    mapping(address => uint256[]) public userStakeIds; // Map user address to their stake IDs

    // Energy System
    uint256 public energyPerSecondPerToken = 1; // Base rate of energy accrual (e.g., 1 Energy per second per token)
    mapping(address => uint256) public userTotalClaimedEnergy; // Total Energy claimed by a user

    // Emergency Withdrawal
    bool public emergencyWithdrawActive = false;
    uint256 public emergencyWithdrawEndTime;
    uint256 public emergencyWithdrawPenaltyRate = 20; // % penalty

    // Events
    event Deposit(address indexed user, uint256 stakeId, uint256 amount, uint256 lockDuration, uint256 timestamp);
    event Withdrawal(address indexed user, uint256 stakeId, uint256 amount, uint256 timestamp, uint256 effectiveAmount);
    event CancelStake(address indexed user, uint256 stakeId, uint256 amount, uint256 timestamp, uint256 refundedAmount);
    event EmergencyWithdraw(address indexed user, uint256 stakeId, uint256 amount, uint256 timestamp, uint256 refundedAmount);
    event PhaseTransition(Phase indexed oldPhase, Phase indexed newPhase, uint256 timestamp);
    event EnergyClaim(address indexed user, uint256 amount, uint256 timestamp);
    event StakeMerged(address indexed user, uint256[] mergedStakeIds, uint256 newStakeId, uint256 totalAmount, uint256 timestamp);
    event ParameterUpdated(string parameterName, uint256 oldValue, uint256 newValue);
    event EmergencyWithdrawEnabled(uint256 endTime);
    event EmergencyWithdrawDisabled();

    // --- Modifiers ---

    modifier onlyPhase(Phase _phase) {
        require(currentPhase == _phase, "QV: Not allowed in current phase");
        _;
    }

    modifier onlyPhases(Phase[] memory _phases) {
        bool allowed = false;
        for (uint i = 0; i < _phases.length; i++) {
            if (currentPhase == _phases[i]) {
                allowed = true;
                break;
            }
        }
        require(allowed, "QV: Not allowed in current phase");
        _;
    }

    modifier whenEmergencyWithdrawActive() {
        require(emergencyWithdrawActive && block.timestamp <= emergencyWithdrawEndTime, "QV: Emergency withdrawal not active");
        _;
    }

    // --- Constructor ---

    constructor(address _stakingTokenAddress) Ownable(msg.sender) Pausable(false) {
        stakingToken = IERC20(_stakingTokenAddress);
        currentPhase = Phase.Initialization;
        lastPhaseTransitionTime = block.timestamp;

        // Set some initial default phase durations (can be changed by owner)
        phaseDurations[Phase.Initialization] = 7 days;
        phaseDurations[Phase.DepositPhase] = 30 days;
        phaseDurations[Phase.ActivePhase] = 365 days; // Main phase, can be very long
        phaseDurations[Phase.StabilizationPhase] = 90 days;
        // Expired phase duration isn't typically time-bound, it's a final state

        // Set some initial default energy multipliers (can be changed by owner)
        phaseEnergyMultipliers[Phase.Initialization] = 0;
        phaseEnergyMultipliers[Phase.DepositPhase] = 1; // Energy accrues during deposit phase
        phaseEnergyMultipliers[Phase.ActivePhase] = 5; // Higher accrual in active phase
        phaseEnergyMultipliers[Phase.StabilizationPhase] = 2; // Slower accrual in stabilization
        phaseEnergyMultipliers[Phase.Expired] = 0; // No accrual in expired phase
    }

    // --- Phase Management ---

    /**
     * @dev Gets the current operational phase of the vault. Automatically transitions if time has passed.
     * @return The current Phase enum.
     */
    function getCurrentPhase() public view returns (Phase) {
        // This function *cannot* change state if it's view/pure.
        // We rely on `transitionToNextPhase` being called.
        // However, we can calculate what the next phase *should* be.
        if (currentPhase == Phase.Expired) {
            return Phase.Expired;
        }

        uint256 timeInCurrentPhase = block.timestamp - lastPhaseTransitionTime;
        uint256 requiredDuration = phaseDurations[currentPhase];

        if (requiredDuration > 0 && timeInCurrentPhase >= requiredDuration) {
            // Logic here would transition the phase, but can't in a view function.
            // The actual state change must happen via `transitionToNextPhase`.
            // This function primarily returns the *current* state variable.
            // For a dynamic contract, a pattern is to have a callable `updatePhase` or similar.
            // Let's assume `transitionToNextPhase` is called periodically.
        }
        return currentPhase;
    }

    /**
     * @dev Owner function to transition the contract to the next phase.
     * Requires that the minimum duration for the current phase has passed (unless currentPhase is Initialization).
     */
    function transitionToNextPhase() external onlyOwner {
        require(currentPhase != Phase.Expired, "QV: Contract is already expired");

        Phase nextPhase = currentPhase;
        uint256 timeInCurrent = block.timestamp - lastPhaseTransitionTime;
        uint256 requiredDuration = phaseDurations[currentPhase];

        // Allow transition from Initialization immediately if needed for setup,
        // otherwise enforce duration for other phases.
        if (currentPhase != Phase.Initialization && requiredDuration > 0 && timeInCurrent < requiredDuration) {
             revert("QV: Not enough time elapsed in current phase");
        }

        if (currentPhase == Phase.Initialization) {
            nextPhase = Phase.DepositPhase;
        } else if (currentPhase == Phase.DepositPhase) {
            nextPhase = Phase.ActivePhase;
        } else if (currentPhase == Phase.ActivePhase) {
            nextPhase = Phase.StabilizationPhase;
        } else if (currentPhase == Phase.StabilizationPhase) {
            nextPhase = Phase.Expired;
        }
        // Expired phase is terminal

        require(nextPhase != currentPhase, "QV: No valid phase transition available yet");

        Phase oldPhase = currentPhase;
        currentPhase = nextPhase;
        lastPhaseTransitionTime = block.timestamp;
        emit PhaseTransition(oldPhase, currentPhase, block.timestamp);
    }

    // --- Staking (Deposit) ---

    /**
     * @dev Allows users to deposit tokens and create a new stake.
     * Requires the current phase to be DepositPhase or ActivePhase.
     * @param _amount The amount of tokens to deposit.
     */
    function deposit(uint256 _amount) external whenNotPaused nonReentrant onlyPhases(new Phase[]{Phase.DepositPhase, Phase.ActivePhase}) {
        require(_amount > 0, "QV: Deposit amount must be greater than zero");

        // Transfer tokens from the user to the contract
        require(stakingToken.transferFrom(msg.sender, address(this), _amount), "QV: Token transfer failed");

        uint256 stakeId = nextStakeId++;
        stakes[stakeId] = StakeDetails({
            owner: msg.sender,
            amount: _amount,
            startTime: block.timestamp,
            lockDuration: defaultLockDuration,
            status: StakeStatus.Active,
            lastEnergyClaimTime: block.timestamp,
            claimedEnergy: 0
        });

        userStakeIds[msg.sender].push(stakeId);

        emit Deposit(msg.sender, stakeId, _amount, defaultLockDuration, block.timestamp);
    }

    // --- Withdrawal ---

    /**
     * @dev Allows a user to withdraw a specific stake if its lock time has passed.
     * @param _stakeId The ID of the stake to withdraw.
     */
    function withdrawStake(uint256 _stakeId) external whenNotPaused nonReentrant onlyPhases(new Phase[]{Phase.ActivePhase, Phase.StabilizationPhase, Phase.Expired}) {
        StakeDetails storage stake = stakes[_stakeId];
        require(stake.owner == msg.sender, "QV: Not your stake");
        require(stake.status == StakeStatus.Active, "QV: Stake is not active");
        require(block.timestamp >= stake.startTime + stake.lockDuration, "QV: Lock time not yet passed");

        // Calculate any potential bonus/penalty based on phase or duration (optional advanced logic)
        // For this version, we'll keep it simple and just return the full amount after lock time.
        uint256 amountToTransfer = stake.amount;

        // Claim any pending energy for this stake before withdrawing
        _claimEnergyForStake(_stakeId);

        stake.status = StakeStatus.Withdrawn;

        require(stakingToken.transfer(msg.sender, amountToTransfer), "QV: Token transfer failed");

        emit Withdrawal(msg.sender, _stakeId, stake.amount, block.timestamp, amountToTransfer);
    }

    /**
     * @dev Allows a user to cancel a stake before its lock time expires, incurring a penalty.
     * Only available in specific phases.
     * @param _stakeId The ID of the stake to cancel.
     */
    function cancelStake(uint256 _stakeId) external whenNotPaused nonReentrant onlyPhases(new Phase[]{Phase.DepositPhase, Phase.ActivePhase, Phase.StabilizationPhase}) {
        StakeDetails storage stake = stakes[_stakeId];
        require(stake.owner == msg.sender, "QV: Not your stake");
        require(stake.status == StakeStatus.Active, "QV: Stake is not active");
        require(block.timestamp < stake.startTime + stake.lockDuration, "QV: Lock time already passed, use withdrawStake");

        uint256 penaltyAmount = (stake.amount * earlyWithdrawPenaltyRate) / 100;
        uint256 amountToTransfer = stake.amount - penaltyAmount;

        // Claim any pending energy for this stake before cancelling
        _claimEnergyForStake(_stakeId);

        stake.status = StakeStatus.Cancelled;

        require(stakingToken.transfer(msg.sender, amountToTransfer), "QV: Token transfer failed");

        emit CancelStake(msg.sender, _stakeId, stake.amount, block.timestamp, amountToTransfer);
    }

     /**
     * @dev Owner can activate emergency withdrawal mode, allowing users to withdraw with a penalty.
     * @param _duration Duration in seconds for emergency withdrawal to be active.
     */
    function enableEmergencyWithdraw(uint256 _duration) external onlyOwner {
        require(_duration > 0, "QV: Duration must be positive");
        emergencyWithdrawActive = true;
        emergencyWithdrawEndTime = block.timestamp + _duration;
        emit EmergencyWithdrawEnabled(emergencyWithdrawEndTime);
    }

    /**
     * @dev Owner can disable emergency withdrawal mode.
     */
    function disableEmergencyWithdraw() external onlyOwner {
        emergencyWithdrawActive = false;
        emergencyWithdrawEndTime = 0;
        emit EmergencyWithdrawDisabled();
    }

     /**
     * @dev Allows a user to withdraw a specific stake during an emergency withdrawal period.
     * Incurs the emergency withdrawal penalty.
     * @param _stakeId The ID of the stake to withdraw.
     */
    function emergencyWithdraw(uint256 _stakeId) external whenNotPaused nonReentrant whenEmergencyWithdrawActive {
         StakeDetails storage stake = stakes[_stakeId];
        require(stake.owner == msg.sender, "QV: Not your stake");
        require(stake.status == StakeStatus.Active, "QV: Stake is not active");

        // Penalty applies regardless of lock time during emergency
        uint256 penaltyAmount = (stake.amount * emergencyWithdrawPenaltyRate) / 100;
        uint256 amountToTransfer = stake.amount - penaltyAmount;

        // Claim any pending energy for this stake before emergency withdrawing
        _claimEnergyForStake(_stakeId);

        stake.status = StakeStatus.Withdrawn; // Mark as withdrawn, effectively ending the stake

        require(stakingToken.transfer(msg.sender, amountToTransfer), "QV: Token transfer failed");

        emit EmergencyWithdraw(msg.sender, _stakeId, stake.amount, block.timestamp, amountToTransfer);
     }


    // --- Energy System ---

    /**
     * @dev Calculates the potential pending Energy for a specific stake.
     * @param _stakeId The ID of the stake.
     * @return The calculated pending Energy amount.
     */
    function _calculatePendingEnergy(uint256 _stakeId) internal view returns (uint256) {
        StakeDetails storage stake = stakes[_stakeId];
        if (stake.status != StakeStatus.Active || phaseEnergyMultipliers[currentPhase] == 0) {
            return 0;
        }

        // Time elapsed since stake started OR last claim, whichever is later
        uint256 calculationStartTime = stake.lastEnergyClaimTime > stake.startTime ? stake.lastEnergyClaimTime : stake.startTime;
        uint256 timeElapsed = block.timestamp - calculationStartTime;

        // Prevent potential re-accrual if timestamp hasn't advanced
        if (timeElapsed == 0) {
             return 0;
        }

        // Energy = amount * time_elapsed * multiplier / base_rate_divisor (implicit 1 / energyPerSecondPerToken)
        uint256 potentialEnergy = (stake.amount * timeElapsed * phaseEnergyMultipliers[currentPhase]) / energyPerSecondPerToken;

        return potentialEnergy;
    }

    /**
     * @dev Internal function to calculate and update claimed energy for a single stake.
     * Updates stake's last claim time and adds to total claimed.
     * @param _stakeId The ID of the stake.
     */
    function _claimEnergyForStake(uint256 _stakeId) internal {
        StakeDetails storage stake = stakes[_stakeId];
        uint256 pendingEnergy = _calculatePendingEnergy(_stakeId);

        if (pendingEnergy > 0) {
            // Add pending energy to claimed, update last claim time
            stake.claimedEnergy += pendingEnergy;
            userTotalClaimedEnergy[stake.owner] += pendingEnergy;
            stake.lastEnergyClaimTime = block.timestamp;
        }
    }


    /**
     * @dev Allows a user to claim all accumulated Energy points from their active stakes.
     */
    function claimEnergy() external whenNotPaused nonReentrant onlyPhases(new Phase[]{Phase.DepositPhase, Phase.ActivePhase, Phase.StabilizationPhase}) {
        uint256 totalPendingEnergy = 0;
        address user = msg.sender;

        uint256[] storage stakeIds = userStakeIds[user];
        for (uint i = 0; i < stakeIds.length; i++) {
            uint256 stakeId = stakeIds[i];
            if (stakes[stakeId].status == StakeStatus.Active) {
                totalPendingEnergy += _calculatePendingEnergy(stakeId);
                 // Update stake's claimed energy and last claim time immediately
                stakes[stakeId].claimedEnergy += _calculatePendingEnergy(stakeId); // Recalculate just in case
                stakes[stakeId].lastEnergyClaimTime = block.timestamp;
            }
        }

        require(totalPendingEnergy > 0, "QV: No energy to claim");

        // Update user's total claimed energy
        userTotalClaimedEnergy[user] += totalPendingEnergy;

        emit EnergyClaim(user, totalPendingEnergy, block.timestamp);
    }

    /**
     * @dev Calculates the total amount of Energy points a user can currently claim across all their active stakes.
     * @return The total claimable Energy amount.
     */
    function previewEnergyClaim() external view returns (uint256) {
        uint256 totalPendingEnergy = 0;
        address user = msg.sender;

        uint256[] storage stakeIds = userStakeIds[user];
        for (uint i = 0; i < stakeIds.length; i++) {
            uint256 stakeId = stakeIds[i];
            if (stakes[stakeId].status == StakeStatus.Active) {
                 totalPendingEnergy += _calculatePendingEnergy(stakeId);
            }
        }
        return totalPendingEnergy;
    }


    // --- Stake Management ---

    /**
     * @dev Retrieves the details for a specific stake.
     * @param _stakeId The ID of the stake.
     * @return A StakeDetails struct containing the stake information.
     */
    function getStakeDetails(uint256 _stakeId) external view returns (StakeDetails memory) {
        require(_stakeId > 0 && _stakeId < nextStakeId, "QV: Invalid stake ID");
        return stakes[_stakeId];
    }

     /**
     * @dev Retrieves the list of stake IDs belonging to a specific user.
     * @param _user The address of the user.
     * @return An array of stake IDs.
     */
    function getUserStakes(address _user) external view returns (uint256[] memory) {
        return userStakeIds[_user];
    }

    /**
     * @dev Checks if a specific stake is eligible for withdrawal based on its lock time.
     * Does not check phase eligibility or stake status.
     * @param _stakeId The ID of the stake.
     * @return True if lock time has passed, false otherwise.
     */
    function isStakeUnlockable(uint256 _stakeId) external view returns (bool) {
        require(_stakeId > 0 && _stakeId < nextStakeId, "QV: Invalid stake ID");
        StakeDetails storage stake = stakes[_stakeId];
        // Check only lock duration, not status or phase
        return block.timestamp >= stake.startTime + stake.lockDuration;
    }

    /**
     * @dev Allows a user to merge multiple active stakes into a single new stake.
     * The new stake's amount is the sum of the merged stakes, and it gets a new lock duration.
     * Only allowed in specific phases.
     * @param _stakeIds An array of stake IDs belonging to the caller to merge.
     */
    function mergeStakes(uint256[] memory _stakeIds) external whenNotPaused nonReentrant onlyPhases(new Phase[]{Phase.ActivePhase, Phase.StabilizationPhase}) {
        require(_stakeIds.length > 1, "QV: Need at least 2 stakes to merge");

        uint256 totalAmount = 0;
        address user = msg.sender;

        // Validate and sum up amounts from active stakes belonging to the user
        for (uint i = 0; i < _stakeIds.length; i++) {
            uint256 stakeId = _stakeIds[i];
            require(stakeId > 0 && stakeId < nextStakeId, "QV: Invalid stake ID in list");
            StakeDetails storage stake = stakes[stakeId];
            require(stake.owner == user, "QV: Stake not owned by caller");
            require(stake.status == StakeStatus.Active, "QV: Stake must be active to merge");

            // Claim energy for each stake being merged before marking it
             _claimEnergyForStake(stakeId);

            totalAmount += stake.amount;
            stake.status = StakeStatus.Merged; // Mark the stake as merged
        }

        require(totalAmount > 0, "QV: Total amount must be greater than zero after merging");

        // Create the new merged stake
        uint256 newStakeId = nextStakeId++;
         stakes[newStakeId] = StakeDetails({
            owner: user,
            amount: totalAmount,
            startTime: block.timestamp, // New start time for the merged stake
            lockDuration: mergeLockDuration, // Fixed lock duration for merged stakes
            status: StakeStatus.Active,
            lastEnergyClaimTime: block.timestamp,
            claimedEnergy: 0 // New stake starts with 0 claimed energy
        });

        userStakeIds[user].push(newStakeId);

        emit StakeMerged(user, _stakeIds, newStakeId, totalAmount, block.timestamp);
    }

    // --- View/Pure Functions ---

    /**
     * @dev Calculates the potential withdrawal amount for a stake based on its status and lock time.
     * Does not perform the withdrawal. Accounts for potential penalties.
     * @param _stakeId The ID of the stake.
     * @return The amount of tokens that would be transferred on withdrawal or cancellation.
     */
    function previewWithdrawal(uint256 _stakeId) external view returns (uint256) {
        require(_stakeId > 0 && _stakeId < nextStakeId, "QV: Invalid stake ID");
        StakeDetails storage stake = stakes[_stakeId];

        if (stake.status != StakeStatus.Active) {
            return 0; // Cannot withdraw inactive stakes
        }

        if (block.timestamp >= stake.startTime + stake.lockDuration) {
            // Lock time passed, no penalty
            return stake.amount;
        } else {
            // Lock time not passed, apply cancellation penalty
            uint256 penaltyAmount = (stake.amount * earlyWithdrawPenaltyRate) / 100;
            return stake.amount - penaltyAmount;
        }
         // Note: Emergency withdrawal penalty is separate and requires `whenEmergencyWithdrawActive` context.
         // This function only previews standard withdrawal or cancellation.
    }

    /**
     * @dev Gets the total amount of staking tokens currently locked in all active stakes.
     * @return The total locked supply.
     */
    function getTotalLocked() external view returns (uint256) {
        return stakingToken.balanceOf(address(this));
    }

     /**
     * @dev Gets the total initial deposit amount made by a user across all their stakes (regardless of status).
     * @param _user The address of the user.
     * @return The sum of initial deposit amounts.
     */
    function getTotalDepositedByUser(address _user) external view returns (uint256) {
        uint256 total = 0;
         uint256[] storage stakeIds = userStakeIds[_user];
        for (uint i = 0; i < stakeIds.length; i++) {
            total += stakes[stakeIds[i]].amount;
        }
        return total;
     }

    /**
     * @dev Gets the timestamp when a specific stake was created.
     * @param _stakeId The ID of the stake.
     * @return The creation timestamp.
     */
    function getStakeCreationTime(uint256 _stakeId) external view returns (uint256) {
         require(_stakeId > 0 && _stakeId < nextStakeId, "QV: Invalid stake ID");
         return stakes[_stakeId].startTime;
    }

    /**
     * @dev Gets the timestamp when a specific phase transition occurred.
     * @param _phase The phase to check the transition time for. (Note: This currently only stores the *last* transition time. A mapping `Phase => uint256` could store *each* phase start time if needed historically, but the current structure only tracks the start of the `currentPhase`). Let's adjust to return `lastPhaseTransitionTime` if the phase matches `currentPhase`, or a placeholder otherwise, or add the mapping. Adding the mapping `phaseStartTimes`.
     */
    mapping(Phase => uint256) private phaseStartTimes;
    // Update constructor and transition function to set these.
    // In constructor: phaseStartTimes[Phase.Initialization] = block.timestamp;
    // In transitionToNextPhase: phaseStartTimes[nextPhase] = block.timestamp;

    function getPhaseStartTime(Phase _phase) external view returns (uint256) {
         // If the phase is the current one, return lastPhaseTransitionTime.
         // If we stored all phase start times:
         return phaseStartTimes[_phase]; // Assuming mapping is populated
    }
     // Need to fix constructor and transitionToNextPhase to populate phaseStartTimes.

    /**
     * @dev Calculates the cumulative total duration across all active stakes for a user.
     * Useful for potential future mechanics like seniority bonuses.
     * @param _user The address of the user.
     * @return The total cumulative time in seconds.
     */
    function getCumulativeStakeTime(address _user) external view returns (uint256) {
        uint256 totalTime = 0;
        uint256[] storage stakeIds = userStakeIds[_user];
        for (uint i = 0; i < stakeIds.length; i++) {
            uint256 stakeId = stakeIds[i];
            if (stakes[stakeId].status == StakeStatus.Active) {
                 // Time since stake started or merge occurred
                uint256 startTime = stakes[stakeId].startTime;
                totalTime += (block.timestamp - startTime);
            }
        }
        return totalTime;
    }

    // --- Owner/Admin Functions ---

    /**
     * @dev Owner function to set the default lock duration for *new* stakes.
     * Does not affect existing stakes.
     * @param _duration The new default lock duration in seconds.
     */
    function setLockDuration(uint256 _duration) external onlyOwner {
        require(_duration > 0, "QV: Lock duration must be positive");
        uint256 oldDuration = defaultLockDuration;
        defaultLockDuration = _duration;
        emit ParameterUpdated("defaultLockDuration", oldDuration, defaultLockDuration);
    }

     /**
     * @dev Owner function to set the required time duration for a specific phase before the next transition is possible.
     * @param _phase The phase to set the duration for.
     * @param _duration The new required duration in seconds. Set to 0 for no time requirement.
     */
    function setPhaseDuration(Phase _phase, uint256 _duration) external onlyOwner {
        // Cannot set duration for the Expired phase as it's terminal
        require(_phase != Phase.Expired, "QV: Cannot set duration for Expired phase");
        uint256 oldDuration = phaseDurations[_phase];
        phaseDurations[_phase] = _duration;
        emit ParameterUpdated(string(abi.encodePacked("phaseDurations[", uint256(_phase), "]")), oldDuration, _duration);
    }

    /**
     * @dev Owner function to set the percentage penalty applied for canceling a stake early.
     * @param _rate The penalty rate as a percentage (e.g., 10 for 10%). Max 100.
     */
    function setPenaltyRate(uint256 _rate) external onlyOwner {
        require(_rate <= 100, "QV: Penalty rate cannot exceed 100%");
        uint256 oldRate = earlyWithdrawPenaltyRate;
        earlyWithdrawPenaltyRate = _rate;
        emit ParameterUpdated("earlyWithdrawPenaltyRate", oldRate, earlyWithdrawPenaltyRate);
    }

    /**
     * @dev Owner function to set the Energy accrual multiplier for a specific phase.
     * A multiplier of 0 means no energy accrues in that phase.
     * @param _phase The phase to set the multiplier for.
     * @param _multiplier The new multiplier.
     */
    function setEnergyMultiplier(Phase _phase, uint256 _multiplier) external onlyOwner {
        uint256 oldMultiplier = phaseEnergyMultipliers[_phase];
        phaseEnergyMultipliers[_phase] = _multiplier;
        emit ParameterUpdated(string(abi.encodePacked("phaseEnergyMultipliers[", uint256(_phase), "]")), oldMultiplier, _multiplier);
    }

    /**
     * @dev Owner function to set the lock duration for stakes created via merging.
     * @param _duration The new lock duration in seconds.
     */
    function setMergeLockDuration(uint256 _duration) external onlyOwner {
        require(_duration > 0, "QV: Merge lock duration must be positive");
        uint256 oldDuration = mergeLockDuration;
        mergeLockDuration = _duration;
        emit ParameterUpdated("mergeLockDuration", oldDuration, mergeLockDuration);
    }

     /**
     * @dev Owner function to set the percentage penalty for emergency withdrawals.
     * @param _rate The penalty rate as a percentage (e.g., 20 for 20%). Max 100.
     */
    function setEmergencyWithdrawPenalty(uint256 _rate) external onlyOwner {
        require(_rate <= 100, "QV: Emergency penalty rate cannot exceed 100%");
        uint256 oldRate = emergencyWithdrawPenaltyRate;
        emergencyWithdrawPenaltyRate = _rate;
        emit ParameterUpdated("emergencyWithdrawPenaltyRate", oldRate, emergencyWithdrawPenaltyRate);
    }

    // --- Safety Features ---

    /**
     * @dev See {Pausable-pause}.
     * Only owner can pause. Certain critical functions are blocked when paused.
     */
    function pause() external onlyOwner whenNotPaused {
        _pause();
    }

    /**
     * @dev See {Pausable-unpause}.
     * Only owner can unpause.
     */
    function unpause() external onlyOwner whenPaused {
        _unpause();
    }

    // --- Fixes and Initializations for `phaseStartTimes` ---
    // Update constructor to initialize phaseStartTimes
    // Update transitionToNextPhase to record the start time of the new phase

    constructor(address _stakingTokenAddress) Ownable(msg.sender) Pausable(false) {
        stakingToken = IERC20(_stakingTokenAddress);
        currentPhase = Phase.Initialization;
        lastPhaseTransitionTime = block.timestamp;
        phaseStartTimes[Phase.Initialization] = block.timestamp; // Record start of Init phase

        // Set some initial default phase durations (can be changed by owner)
        phaseDurations[Phase.Initialization] = 7 days;
        phaseDurations[Phase.DepositPhase] = 30 days;
        phaseDurations[Phase.ActivePhase] = 365 days; // Main phase, can be very long
        phaseDurations[Phase.StabilizationPhase] = 90 days;

        // Set some initial default energy multipliers (can be changed by owner)
        phaseEnergyMultipliers[Phase.Initialization] = 0;
        phaseEnergyMultipliers[Phase.DepositPhase] = 1; // Energy accrues during deposit phase
        phaseEnergyMultipliers[Phase.ActivePhase] = 5; // Higher accrual in active phase
        phaseEnergyMultipliers[Phase.StabilizationPhase] = 2; // Slower accrual in stabilization
        phaseEnergyMultipliers[Phase.Expired] = 0; // No accrual in expired phase
    }

     function transitionToNextPhase() external onlyOwner {
        require(currentPhase != Phase.Expired, "QV: Contract is already expired");

        Phase nextPhase = currentPhase;
        uint256 timeInCurrent = block.timestamp - lastPhaseTransitionTime;
        uint256 requiredDuration = phaseDurations[currentPhase];

        if (currentPhase != Phase.Initialization && requiredDuration > 0 && timeInCurrent < requiredDuration) {
             revert("QV: Not enough time elapsed in current phase");
        }

        if (currentPhase == Phase.Initialization) {
            nextPhase = Phase.DepositPhase;
        } else if (currentPhase == Phase.DepositPhase) {
            nextPhase = Phase.ActivePhase;
        } else if (currentPhase == Phase.ActivePhase) {
            nextPhase = Phase.StabilizationPhase;
        } else if (currentPhase == Phase.StabilizationPhase) {
            nextPhase = Phase.Expired;
        }
        // Expired phase is terminal

        require(nextPhase != currentPhase, "QV: No valid phase transition available yet");

        Phase oldPhase = currentPhase;
        currentPhase = nextPhase;
        lastPhaseTransitionTime = block.timestamp;
        phaseStartTimes[currentPhase] = block.timestamp; // Record start of the *new* phase
        emit PhaseTransition(oldPhase, currentPhase, block.timestamp);
    }

     // Add `getUserTotalClaimedEnergy` getter
     function getUserTotalClaimedEnergy(address _user) external view returns(uint256) {
        return userTotalClaimedEnergy[_user];
     }

     // Add `getStakeStatus` getter
     function getStakeStatus(uint256 _stakeId) external view returns(StakeStatus) {
         require(_stakeId > 0 && _stakeId < nextStakeId, "QV: Invalid stake ID");
         return stakes[_stakeId].status;
     }

     // Add `getEmergencyWithdrawStatus` getter
     function getEmergencyWithdrawStatus() external view returns(bool active, uint256 endTime) {
         return (emergencyWithdrawActive && block.timestamp <= emergencyWithdrawEndTime, emergencyWithdrawEndTime);
     }
}
```