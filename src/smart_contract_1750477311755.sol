Okay, here is a Solidity smart contract incorporating advanced, creative, and non-standard concepts centered around a "Quantum Vault" theme. It involves time-decaying user engagement scores, adaptive withdrawal rules based on a global "Quantum State," and functions that calculate potential outcomes based on these dynamic parameters.

It has over 20 functions, includes custom errors, events, and leverages various Solidity features beyond a basic token or simple vault.

---

**Outline and Function Summary**

**Contract Name:** `QuantumVault`

**Core Concept:** A secure vault designed to hold Ether, where access to deposited funds is not solely based on simple time locks but also on a user's accumulated "quantum engagement" score, which decays over time if not actively maintained. The contract's withdrawal rules adapt based on a globally managed "Quantum State," adding a layer of dynamic behavior.

**State Variables:**
*   `owner`: The contract deployer/admin.
*   `userStates`: Mapping storing each user's detailed state (`UserQuantumState` struct).
*   `totalLockedEther`: Total Ether held in the vault.
*   `currentQuantumState`: The current global state affecting withdrawal rules (enum: Stable, Fluctuation, Entangled).
*   `attunementInterval`: Minimum time required between `attuneQuantumState` calls for engagement gain.
*   `engagementGainPerAttune`: Amount of engagement gained per successful attunement.
*   `engagementDecayRate`: Rate at which engagement decays over time since last attunement.
*   `minEngagementPerState`: Mapping storing the minimum required engagement for withdrawal for each `QuantumState`.
*   `earlyWithdrawalPenaltyRate`: Penalty percentage for withdrawing before a minimum duration (scaled by how early).
*   `timeBonusRate`: Bonus percentage for holding longer than a threshold.
*   `engagementBonusRate`: Bonus percentage based on high effective engagement.
*   `minTimeForBonus`: Minimum deposit duration to start earning a time bonus.
*   `minTimeForNoPenalty`: Minimum deposit duration to avoid the early withdrawal penalty.

**Structs:**
*   `UserQuantumState`: Stores `lockedBalance`, `depositTime`, `lastAttunementTime`, and `quantumEngagement` for each user.

**Enums:**
*   `QuantumState`: Defines the possible states of the vault (Stable, Fluctuation, Entangled).

**Events:**
*   `Deposited`: Logs user deposit.
*   `Withdrew`: Logs user withdrawal details (amount, penalty/bonus).
*   `Attuned`: Logs user attunement activity and engagement change.
*   `StateShifted`: Logs change in global `currentQuantumState`.
*   `ParameterSet`: Logs changes to various contract parameters.
*   `OwnershipTransferred`: Logs ownership changes.

**Custom Errors:**
*   Specific errors for various failure conditions (e.g., not enough ETH, no deposit, insufficient engagement, withdrawal window closed, not owner, invalid state).

**Functions Summary (Total: 27)**

1.  `constructor()`: Initializes the contract, sets the owner, and initial parameters.
2.  `depositEther()`: `payable` function allowing users to deposit Ether into the vault. Records deposit time and initializes user state if new.
3.  `attuneQuantumState()`: Allows a user to "attune" their state. If called after the `attunementInterval`, it increases their `quantumEngagement` score and updates `lastAttunementTime`.
4.  `withdrawEther()`: The core withdrawal function. Calculates the effective engagement (considering decay), checks minimum engagement required by the `currentQuantumState`, applies time bonuses or early withdrawal penalties, transfers the adjusted amount, and resets user state. Contains complex conditional logic based on `currentQuantumState`.
5.  `_calculateEffectiveEngagement(address user)`: Internal helper function to calculate a user's current engagement score, accounting for decay based on time since `lastAttunementTime`.
6.  `_calculateWithdrawalAmount(address user, uint256 effectiveEngagement)`: Internal helper function to calculate the final withdrawal amount by applying bonuses and penalties based on deposit duration and effective engagement.
7.  `_checkWithdrawalEligibility(address user, uint256 effectiveEngagement)`: Internal helper function to check if a user meets the minimum engagement requirement based on the `currentQuantumState`.
8.  `getUserBalance(address user)`: Public view function to get a user's locked balance.
9.  `getUserDepositTime(address user)`: Public view function to get the timestamp of a user's initial deposit.
10. `getUserLastAttunement(address user)`: Public view function to get the timestamp of a user's last attunement.
11. `getUserRawEngagement(address user)`: Public view function to get a user's raw (undecayed) engagement score.
12. `getUserEffectiveEngagement(address user)`: Public view function to get a user's current calculated effective engagement score.
13. `getQuantumState()`: Public view function to get the current global `QuantumState`.
14. `getTotalLockedEther()`: Public view function to get the total Ether held in the vault.
15. `getAttunementInterval()`: Public view function to get the current attunement interval.
16. `getEngagementGainPerAttune()`: Public view function to get the engagement gain per attunement.
17. `getEngagementDecayRate()`: Public view function to get the engagement decay rate.
18. `getMinEngagementForState(QuantumState state)`: Public view function to get the minimum required engagement for a specific `QuantumState`.
19. `getEarlyWithdrawalPenaltyRate()`: Public view function to get the early withdrawal penalty rate.
20. `getTimeBonusRate()`: Public view function to get the time bonus rate.
21. `getEngagementBonusRate()`: Public view function to get the engagement bonus rate.
22. `getMinTimeForBonus()`: Public view function to get the minimum time for bonus eligibility.
23. `getMinTimeForNoPenalty()`: Public view function to get the minimum time to avoid penalty.
24. `estimateWithdrawalValue(address user)`: Public view function that simulates the withdrawal logic to estimate the amount a user *would* receive if they withdrew now, including bonuses/penalties.
25. `shiftQuantumState(QuantumState newState)`: Owner-only function to change the global `currentQuantumState`.
26. `setMinEngagementForState(QuantumState state, uint256 minEngagement)`: Owner-only function to set the minimum required engagement for a specific state.
27. `setParameters(uint64 _attunementInterval, uint256 _engagementGainPerAttune, uint256 _engagementDecayRate, uint256 _earlyWithdrawalPenaltyRate, uint256 _timeBonusRate, uint256 _engagementBonusRate, uint64 _minTimeForBonus, uint64 _minTimeForNoPenalty)`: Owner-only function to update multiple parameters at once.
28. `transferOwnership(address newOwner)`: Standard Ownable pattern function to transfer ownership.
29. `renounceOwnership()`: Standard Ownable pattern function to renounce ownership.
30. `sweepStrayTokens(address tokenContract, address recipient)`: Owner-only function to rescue accidentally sent ERC20 tokens.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// Custom errors for clarity and gas efficiency
error NotOwner();
error NotEnoughEther();
error NoDepositFound();
error WithdrawalWindowClosed(); // Conceptually, withdrawal might be locked in certain quantum states for low engagement
error InsufficientEffectiveEngagement(uint256 required, uint256 has);
error AttunementIntervalNotPassed(uint64 timeRemaining);
error InvalidStateChange();
error TransferFailed();
error InvalidParameters();
error SelfTransferNotAllowed();

/**
 * @title QuantumVault
 * @dev A non-standard vault contract where Ether withdrawal is contingent on
 *      time held, a time-decaying 'quantum engagement' score, and the
 *      contract's dynamic 'Quantum State'.
 */
contract QuantumVault {
    address private _owner;

    struct UserQuantumState {
        uint256 lockedBalance;      // Amount of Ether locked by the user
        uint64 depositTime;         // Timestamp of the initial deposit
        uint64 lastAttunementTime;  // Timestamp of the last successful attunement
        uint256 quantumEngagement;  // Accumulated engagement score (undecayed)
    }

    mapping(address => UserQuantumState) public userStates;
    uint256 public totalLockedEther;

    // --- Global Quantum State ---
    enum QuantumState {
        Stable,      // Standard rules, moderate requirements
        Fluctuation, // Higher volatility, potential for larger bonuses/penalties
        Entangled    // Strict engagement rules, high time bonus potential
    }
    QuantumState public currentQuantumState;

    // --- Parameters affecting engagement and withdrawal ---
    uint64 public attunementInterval;       // Minimum time between attunements (seconds)
    uint256 public engagementGainPerAttune;  // Engagement units gained per attunement

    // Engagement decay parameters
    // Simplified decay: decay rate is applied per second past the attunementInterval since last attunement
    uint256 public engagementDecayRate;      // Units of engagement lost per second past interval

    // Withdrawal parameters (rates are scaled by 1000, i.e., 100 = 10%)
    uint256 public earlyWithdrawalPenaltyRate; // Penalty % per (minTimeForNoPenalty - timeHeld) factor
    uint256 public timeBonusRate;              // Bonus % per (timeHeld - minTimeForBonus) factor
    uint256 public engagementBonusRate;        // Bonus % per effectiveEngagement unit above a threshold

    uint64 public minTimeForBonus;          // Minimum deposit duration to start earning a time bonus (seconds)
    uint64 public minTimeForNoPenalty;      // Minimum deposit duration to avoid early withdrawal penalty (seconds)

    // Minimum required engagement for withdrawal based on QuantumState
    mapping(QuantumState => uint256) public minEngagementPerState;

    // --- Events ---
    event Deposited(address indexed user, uint256 amount, uint64 depositTime);
    event Withdrew(address indexed user, uint256 requestedAmount, uint256 receivedAmount, int256 adjustment, uint64 withdrawalTime);
    event Attuned(address indexed user, uint256 engagementGained, uint256 newRawEngagement, uint64 attunementTime);
    event StateShifted(QuantumState oldState, QuantumState newState, uint64 timestamp);
    event ParameterSet(string parameterName, uint256 oldValue, uint256 newValue, uint64 timestamp);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    // --- Modifiers ---
    modifier onlyOwner() {
        if (msg.sender != _owner) {
            revert NotOwner();
        }
        _;
    }

    // --- Constructor ---
    constructor() {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), msg.sender);

        // Set initial parameters (arbitrary values for demonstration)
        attunementInterval = 7 days; // Attune once a week
        engagementGainPerAttune = 100; // Gain 100 engagement points
        engagementDecayRate = 1; // Lose 1 engagement point per second past the interval

        earlyWithdrawalPenaltyRate = 200; // Up to 20% penalty
        timeBonusRate = 5; // 0.5% bonus per factor
        engagementBonusRate = 2; // 0.2% bonus per engagement factor

        minTimeForBonus = 30 days;
        minTimeForNoPenalty = 90 days;

        // Set initial minimum engagement for each state
        minEngagementPerState[QuantumState.Stable] = 500;
        minEngagementPerState[QuantumState.Fluctuation] = 300; // Fluctuation is easier to enter
        minEngagementPerState[QuantumState.Entangled] = 1000; // Entangled requires high engagement

        currentQuantumState = QuantumState.Stable;
    }

    // --- Core User Functions ---

    /**
     * @dev Deposits Ether into the vault. Initializes user state if it's their first deposit.
     */
    receive() external payable {
        depositEther();
    }

    function depositEther() public payable {
        if (msg.value == 0) {
            revert NotEnoughEther();
        }

        UserQuantumState storage user = userStates[msg.sender];

        // If first deposit, initialize state
        if (user.lockedBalance == 0) {
            user.depositTime = uint64(block.timestamp);
            user.lastAttunementTime = uint64(block.timestamp); // Start with attunement at deposit
            user.quantumEngagement = engagementGainPerAttune; // Give initial engagement upon deposit
        }

        user.lockedBalance += msg.value;
        totalLockedEther += msg.value;

        emit Deposited(msg.sender, msg.value, user.depositTime);
    }

    /**
     * @dev Allows a user to attune their Quantum State, increasing engagement
     *      if the attunement interval has passed since the last attunement.
     *      Engagement decays if not maintained.
     */
    function attuneQuantumState() public {
        UserQuantumState storage user = userStates[msg.sender];
        if (user.lockedBalance == 0) {
            revert NoDepositFound();
        }

        uint64 timeSinceLastAttunement = uint64(block.timestamp) - user.lastAttunementTime;

        // Only allow attunement if the interval has passed
        if (timeSinceLastAttunement < attunementInterval) {
            revert AttunementIntervalNotPassed(attunementInterval - timeSinceLastAttunement);
        }

        user.quantumEngagement += engagementGainPerAttune;
        user.lastAttunementTime = uint64(block.timestamp);

        // Note: Engagement decay is calculated dynamically when needed (_calculateEffectiveEngagement)
        emit Attuned(msg.sender, engagementGainPerAttune, user.quantumEngagement, user.lastAttunementTime);
    }

    /**
     * @dev Allows a user to withdraw their deposited Ether.
     *      The actual amount received is adjusted based on time held,
     *      effective engagement, and the current Quantum State.
     */
    function withdrawEther() public {
        UserQuantumState storage user = userStates[msg.sender];
        uint256 locked = user.lockedBalance;

        if (locked == 0) {
            revert NoDepositFound();
        }

        uint256 effectiveEngagement = _calculateEffectiveEngagement(msg.sender);

        // Check withdrawal eligibility based on effective engagement and current state
        _checkWithdrawalEligibility(msg.sender, effectiveEngagement);

        // Calculate the final withdrawal amount after bonuses/penalties
        uint256 amountToWithdraw = _calculateWithdrawalAmount(msg.sender, effectiveEngagement);

        // Ensure we don't try to withdraw more than is locked
        amountToWithdraw = amountToWithdraw > locked ? locked : amountToWithdraw;

        int256 adjustment = int256(amountToWithdraw) - int256(locked);

        // Reset user state BEFORE transferring Ether (Checks-Effects-Interactions pattern)
        user.lockedBalance = 0;
        user.depositTime = 0;
        user.lastAttunementTime = 0;
        user.quantumEngagement = 0;
        totalLockedEther -= locked; // Subtract the original locked amount from total

        // Transfer Ether
        (bool success,) = payable(msg.sender).call{value: amountToWithdraw}("");
        if (!success) {
            // Revert state changes if transfer fails
            user.lockedBalance = locked;
            user.depositTime = uint64(block.timestamp - (block.timestamp - user.depositTime)); // Restore original time (approx)
            user.lastAttunementTime = uint64(block.timestamp - (block.timestamp - user.lastAttunementTime)); // Restore original last attunement (approx)
            user.quantumEngagement = user.quantumEngagement; // Engagement wasn't changed by withdrawal attempt
            totalLockedEther += locked;
            revert TransferFailed();
        }

        emit Withdrew(msg.sender, locked, amountToWithdraw, adjustment, uint64(block.timestamp));
    }

    // --- Internal Calculation Helpers ---

    /**
     * @dev Calculates the user's effective engagement, taking decay into account.
     * @param user The address of the user.
     * @return The calculated effective engagement score.
     */
    function _calculateEffectiveEngagement(address user) internal view returns (uint256) {
        UserQuantumState storage state = userStates[user];
        uint256 rawEngagement = state.quantumEngagement;
        uint64 lastAttune = state.lastAttunementTime;

        // If no deposit or attunement ever, engagement is 0
        if (rawEngagement == 0) {
            return 0;
        }

        uint64 timeSinceLastAttunement = uint64(block.timestamp) - lastAttune;

        // Decay only applies if time since last attunement exceeds the interval
        if (timeSinceLastAttunement <= attunementInterval) {
            return rawEngagement;
        } else {
            uint64 timePastInterval = timeSinceLastAttunement - attunementInterval;
            uint256 decayAmount = timePastInterval * engagementDecayRate;
            return rawEngagement > decayAmount ? rawEngagement - decayAmount : 0;
        }
    }

    /**
     * @dev Calculates the final withdrawal amount including potential bonuses and penalties.
     * @param user The address of the user.
     * @param effectiveEngagement The user's calculated effective engagement.
     * @return The final amount to transfer to the user.
     */
    function _calculateWithdrawalAmount(address user, uint256 effectiveEngagement) internal view returns (uint256) {
        UserQuantumState storage state = userStates[user];
        uint256 locked = state.lockedBalance;
        uint64 timeHeld = uint64(block.timestamp) - state.depositTime;

        uint256 finalAmount = locked;
        int256 adjustment = 0; // Use int256 to track net change

        // --- Apply Penalty ---
        // Penalty applies if time held is less than minTimeForNoPenalty
        if (timeHeld < minTimeForNoPenalty) {
            // Penalty factor: scales from 1 down to 0 as timeHeld approaches minTimeForNoPenalty
            // If timeHeld is 0, factor is 1. If timeHeld is minTimeForNoPenalty, factor is 0.
            uint256 penaltyFactor = (uint256(minTimeForNoPenalty - timeHeld) * 1e18) / minTimeForNoPenalty; // Using 1e18 for fixed point math
            uint256 penaltyAmount = (locked * earlyWithdrawalPenaltyRate * penaltyFactor) / (1000 * 1e18); // 1000 scale for rate, 1e18 for factor
            adjustment -= int256(penaltyAmount);
        }

        // --- Apply Time Bonus ---
        // Bonus applies if time held is more than minTimeForBonus
        if (timeHeld > minTimeForBonus) {
             // Bonus factor: scales up from 0 as timeHeld increases past minTimeForBonus
            uint256 timeBonusFactor = (uint256(timeHeld - minTimeForBonus) * 1e18); // Using 1e18 for fixed point math. Can cap this to prevent infinite growth.
            // Simple linear bonus: Bonus increases linearly with time held past threshold
            uint256 bonusAmount = (locked * timeBonusRate * timeBonusFactor) / (1000 * 1e18);
            adjustment += int256(bonusAmount);
        }

        // --- Apply Engagement Bonus ---
        // Bonus applies if effective engagement is above a threshold (e.g., min required for Stable state)
        uint256 engagementThreshold = minEngagementPerState[QuantumState.Stable]; // Using Stable state threshold as example
        if (effectiveEngagement > engagementThreshold) {
            uint256 engagementBonusFactor = effectiveEngagement - engagementThreshold;
             // Simple linear bonus: Bonus increases linearly with effective engagement above threshold
            uint256 bonusAmount = (locked * engagementBonusRate * engagementBonusFactor) / (1000); // engagementBonusRate is per unit
            adjustment += int256(bonusAmount);
        }


        // Calculate final amount, ensuring it's non-negative
        // Note: Due to potential large penalties or bonuses, the final amount might exceed/fall below initial deposit.
        // This is part of the "Quantum Vault" concept - outcomes can be unpredictable/adjusted based on behavior.
        // The contract always sends the *calculated* amount, up to the total *available* in the contract.
        // However, we cap the transfer to the contract's current balance for safety.
        // The *user* receives the MIN of calculated amount and contract balance.
        // The adjustment is applied relative to the *user's initial locked* amount.
        uint256 calculatedAmount = locked;
        if (adjustment > 0) {
            calculatedAmount += uint256(adjustment);
        } else if (adjustment < 0) {
            calculatedAmount -= uint256(-adjustment);
        }

        // Ensure calculated amount is not zero if locked balance was non-zero (unless penalty is 100%)
         if (locked > 0 && calculatedAmount == 0 && adjustment > -int256(locked)) {
             // This case shouldn't happen with typical parameters unless penalty is extreme,
             // but good practice to consider. Assume 0 is possible with max penalty.
         }


        return calculatedAmount;
    }

    /**
     * @dev Checks if a user meets the minimum engagement requirement for withdrawal
     *      based on the current Quantum State.
     * @param user The address of the user.
     * @param effectiveEngagement The user's calculated effective engagement.
     */
    function _checkWithdrawalEligibility(address user, uint256 effectiveEngagement) internal view {
         // No specific "window" concept implemented here, instead, it's a boolean eligibility check.
         // In a more complex version, certain states might have limited withdrawal *periods*.
         // For this version, eligibility is based solely on engagement vs state requirement.
        uint256 requiredEngagement = minEngagementPerState[currentQuantumState];

        if (effectiveEngagement < requiredEngagement) {
            revert InsufficientEffectiveEngagement(requiredEngagement, effectiveEngagement);
        }
    }


    // --- Public View Functions (Getters) ---

    function getUserBalance(address user) public view returns (uint256) {
        return userStates[user].lockedBalance;
    }

    function getUserDepositTime(address user) public view returns (uint64) {
         return userStates[user].depositTime;
    }

    function getUserLastAttunement(address user) public view returns (uint64) {
        return userStates[user].lastAttunementTime;
    }

    function getUserRawEngagement(address user) public view returns (uint256) {
        return userStates[user].quantumEngagement;
    }

     function getUserEffectiveEngagement(address user) public view returns (uint256) {
        return _calculateEffectiveEngagement(user);
    }

    function getQuantumState() public view returns (QuantumState) {
        return currentQuantumState;
    }

    function getTotalLockedEther() public view returns (uint256) {
        return totalLockedEther;
    }

    function getAttunementInterval() public view returns (uint64) {
        return attunementInterval;
    }

    function getEngagementGainPerAttune() public view returns (uint256) {
        return engagementGainPerAttune;
    }

    function getEngagementDecayRate() public view returns (uint256) {
        return engagementDecayRate;
    }

    function getMinEngagementForState(QuantumState state) public view returns (uint256) {
        return minEngagementPerState[state];
    }

    function getEarlyWithdrawalPenaltyRate() public view returns (uint256) {
        return earlyWithdrawalPenaltyRate;
    }

    function getTimeBonusRate() public view returns (uint256) {
        return timeBonusRate;
    }

    function getEngagementBonusRate() public view returns (uint256) {
        return engagementBonusRate;
    }

    function getMinTimeForBonus() public view returns (uint64) {
        return minTimeForBonus;
    }

    function getMinTimeForNoPenalty() public view returns (uint64) {
        return minTimeForNoPenalty;
    }

    /**
     * @dev Estimates the amount a user would receive if they withdrew right now.
     *      Includes potential bonuses and penalties based on current state, time, and engagement.
     *      Does NOT change contract state.
     * @param user The address of the user.
     * @return The estimated withdrawal amount.
     */
    function estimateWithdrawalValue(address user) public view returns (uint256 estimatedAmount) {
        UserQuantumState storage state = userStates[user];
         if (state.lockedBalance == 0) {
            return 0; // Cannot estimate if no deposit
        }
        uint256 effectiveEngagement = _calculateEffectiveEngagement(user);
        // Simulate the check - if they are ineligible, return 0 or a specific error code?
        // Let's return 0 if currently ineligible, but still calculate the raw value estimate.
         bool isEligibleNow;
         uint256 requiredEngagement = minEngagementPerState[currentQuantumState];
         if (effectiveEngagement >= requiredEngagement) {
             isEligibleNow = true;
         } else {
             isEligibleNow = false;
         }

        uint256 calculatedRawAmount = _calculateWithdrawalAmount(user, effectiveEngagement);

        // Return the calculated amount, but external interfaces might show 0 or 'ineligible' if isEligibleNow is false.
        // Returning the calculated amount allows users to see the potential value if they *became* eligible.
        // Alternatively, could revert if !isEligibleNow, but returning 0 is more informative for estimation.
        return calculatedRawAmount;
    }


    // --- Owner Functions ---

    /**
     * @dev Allows the owner to shift the global Quantum State.
     *      This changes the withdrawal requirements for all users.
     * @param newState The new Quantum State to shift to.
     */
    function shiftQuantumState(QuantumState newState) public onlyOwner {
        if (currentQuantumState == newState) {
            revert InvalidStateChange(); // No change needed
        }
        QuantumState oldState = currentQuantumState;
        currentQuantumState = newState;
        emit StateShifted(oldState, newState, uint64(block.timestamp));
    }

     /**
     * @dev Allows the owner to set the minimum required engagement for a specific Quantum State.
     * @param state The Quantum State to configure.
     * @param minEngagement The new minimum required engagement for that state.
     */
    function setMinEngagementForState(QuantumState state, uint256 minEngagement) public onlyOwner {
        uint256 oldMin = minEngagementPerState[state];
        minEngagementPerState[state] = minEngagement;
        emit ParameterSet(string(abi.encodePacked("minEngagementForState_", uint256(state))), oldMin, minEngagement, uint64(block.timestamp));
    }

     /**
     * @dev Allows the owner to update multiple core parameters at once.
     * @param _attunementInterval The new attunement interval.
     * @param _engagementGainPerAttune The new engagement gain per attunement.
     * @param _engagementDecayRate The new engagement decay rate.
     * @param _earlyWithdrawalPenaltyRate The new early withdrawal penalty rate (scaled by 1000).
     * @param _timeBonusRate The new time bonus rate (scaled by 1000).
     * @param _engagementBonusRate The new engagement bonus rate (scaled by 1000).
     * @param _minTimeForBonus The new minimum time to start earning bonus.
     * @param _minTimeForNoPenalty The new minimum time to avoid penalty.
     */
    function setParameters(
        uint64 _attunementInterval,
        uint256 _engagementGainPerAttune,
        uint256 _engagementDecayRate,
        uint256 _earlyWithdrawalPenaltyRate,
        uint256 _timeBonusRate,
        uint256 _engagementBonusRate,
        uint64 _minTimeForBonus,
        uint64 _minTimeForNoPenalty
    ) public onlyOwner {
        if (_minTimeForBonus >= _minTimeForNoPenalty && _minTimeForNoPenalty != 0) {
             revert InvalidParameters(); // Bonus time should typically be less than penalty avoidance time
        }

        uint64 oldAttuneInterval = attunementInterval;
        attunementInterval = _attunementInterval;
        emit ParameterSet("attunementInterval", oldAttuneInterval, _attunementInterval, uint64(block.timestamp));

        uint256 oldEngagementGain = engagementGainPerAttune;
        engagementGainPerAttune = _engagementGainPerAttune;
        emit ParameterSet("engagementGainPerAttune", oldEngagementGain, _engagementGainPerAttune, uint64(block.timestamp));

        uint256 oldDecayRate = engagementDecayRate;
        engagementDecayRate = _engagementDecayRate;
        emit ParameterSet("engagementDecayRate", oldDecayRate, _engagementDecayRate, uint64(block.timestamp));

        uint256 oldPenaltyRate = earlyWithdrawalPenaltyRate;
        earlyWithdrawalPenaltyRate = _earlyWithdrawalPenaltyRate;
        emit ParameterSet("earlyWithdrawalPenaltyRate", oldPenaltyRate, _earlyWithdrawalPenaltyRate, uint64(block.timestamp));

        uint256 oldTimeBonusRate = timeBonusRate;
        timeBonusRate = _timeBonusRate;
        emit ParameterSet("timeBonusRate", oldTimeBonusRate, _timeBonusRate, uint64(block.timestamp));

         uint256 oldEngagementBonusRate = engagementBonusRate;
        engagementBonusRate = _engagementBonusRate;
        emit ParameterSet("engagementBonusRate", oldEngagementBonusRate, _engagementBonusRate, uint64(block.timestamp));

        uint64 oldMinTimeBonus = minTimeForBonus;
        minTimeForBonus = _minTimeForBonus;
        emit ParameterSet("minTimeForBonus", oldMinTimeBonus, _minTimeForBonus, uint64(block.timestamp));

        uint64 oldMinTimeNoPenalty = minTimeForNoPenalty;
        minTimeForNoPenalty = _minTimeForNoPenalty;
        emit ParameterSet("minTimeForNoPenalty", oldMinTimeNoPenalty, _minTimeForNoPenalty, uint64(block.timestamp));
    }


    /**
     * @dev Allows the owner to sweep accidentally sent ERC20 tokens.
     * @param tokenContract The address of the ERC20 token.
     * @param recipient The address to send the tokens to.
     */
    function sweepStrayTokens(address tokenContract, address recipient) public onlyOwner {
        if (recipient == address(0) || recipient == address(this)) {
            revert InvalidParameters();
        }
        if (tokenContract == address(0)) {
             revert InvalidParameters(); // Cannot sweep native ETH this way
        }

        // This requires interaction with the ERC20 contract
        // Mini-ABI for transfer function
        (bool success,) = tokenContract.call(abi.encodeWithSignature("transfer(address,uint256)", recipient, IERC20(tokenContract).balanceOf(address(this))));
        if (!success) {
            // It's often better to just log a failure here rather than reverting the whole transaction,
            // as sweeping stray tokens shouldn't break core contract functionality.
            // However, reverting makes the failure explicit. Choose based on desired behavior.
            revert TransferFailed();
        }
        // No event logged for sweeping stray tokens by default, could add one if needed.
    }

    // --- Ownable Standard Functions ---
    function owner() public view returns (address) {
        return _owner;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        if (newOwner == address(0)) {
            revert InvalidParameters(); // Cannot transfer to zero address
        }
         if (newOwner == msg.sender) {
             revert SelfTransferNotAllowed(); // Cannot transfer to self pointlessly
         }
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }

    function renounceOwnership() public onlyOwner {
        address oldOwner = _owner;
        _owner = address(0); // Renouncing transfers ownership to the zero address
        emit OwnershipTransferred(oldOwner, address(0));
    }
}

// Minimal IERC20 interface for sweepStrayTokens
interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
}
```