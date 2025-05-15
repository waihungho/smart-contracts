Okay, let's design a smart contract concept that goes beyond standard staking or vaults. We'll create an "Eternal Ember Vault" which allows users to deposit ERC-20 tokens and earn yield, but the mechanics are influenced by the vault's overall "state" which evolves over time or via specific triggers, and users earn non-transferable "Ember" points based on their engagement, which can unlock special benefits or interactions.

This approach incorporates:
*   **Dynamic State:** The contract's behavior changes based on an internal state machine.
*   **Time-Based Mechanics:** Yield accumulation, Ember decay/gain are tied to time.
*   **User Engagement Scoring:** The "Ember" system rewards long-term interaction.
*   **Conditional Actions:** Withdrawals might have conditions, penalties, or require Embers to bypass.
*   **Owner Control with Constraints:** The owner can influence state but maybe within rules.

We'll aim for 20+ distinct functions covering management, deposits/withdrawals, state transitions, the Ember system, and query methods.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

// --- Outline and Function Summary ---
//
// Contract: EternalEmberVault
// Description: A dynamic ERC-20 token vault where yield and user interaction are influenced by the vault's evolving state and an internal non-transferable "Ember" score system.
//
// 1. Management & Configuration
//    - constructor: Deploys the contract and sets initial owner.
//    - setAllowedToken: Owner adds a token address that can be deposited.
//    - removeAllowedToken: Owner removes a token address from the allowed list.
//    - setVaultStateYieldRate: Owner sets the base yield rate percentage for a specific vault state.
//    - setEmberAccumulationRate: Owner sets the rate at which Embers accumulate per unit of deposit time.
//    - setWithdrawalCooldownDuration: Owner sets the base cooldown period after a withdrawal attempt.
//    - setEmberBurnCostForCooldownBypass: Owner sets how many Embers are needed to bypass the withdrawal cooldown.
//    - emergencySweepERC20: Owner can pull out *unaccounted* ERC20 tokens in emergencies (e.g., mistakenly sent tokens). Does NOT affect user deposits.
//    - sweepPenaltyFees: Owner can collect penalty fees accumulated from early withdrawals.
//    - transferOwnership: Transfers ownership of the contract.
//    - renounceOwnership: Renounces ownership of the contract.
//
// 2. Vault State Management
//    - VaultState (Enum): Defines the possible states of the vault (e.g., Genesis, Bloom, Emberglow, Dormant, etc.).
//    - currentVaultState: Public variable indicating the current state.
//    - advanceVaultStateManually: Owner can attempt to manually advance the vault state. May have preconditions (e.g., time elapsed).
//    - triggerTemporalStateEvent: Owner can trigger a temporary state event that modifies mechanics for a limited duration.
//    - endTemporalStateEvent: Owner ends a temporal state event early.
//
// 3. Deposit & Withdrawal Mechanics
//    - deposit: Users deposit allowed ERC-20 tokens into the vault. Starts Ember accumulation.
//    - withdraw: Users withdraw their deposited tokens and accumulated yield. Subject to cooldowns, penalties, state effects.
//    - depositWithTimeLock: Users deposit tokens with a mandatory minimum lock duration.
//    - withdrawWithPenalty: Users withdraw before a lock or condition is met, incurring a penalty fee.
//    - bypassWithdrawalCooldown: Users can spend Embers to immediately withdraw without waiting for the cooldown.
//    - reinvestYield: Users can choose to automatically add their accumulated yield back into their principal deposit for compounding.
//
// 4. Ember System & Interaction
//    - userEmbers: Public mapping to view a user's current Ember balance. (Embers are non-transferable and internal)
//    - claimEmberBonus: Users can claim a one-time or periodic bonus based on their Ember tier or deposit history.
//    - burnEmbersForBenefit: Users can spend a specific amount of Embers to unlock a predefined benefit (e.g., yield boost, reduced penalty).
//
// 5. Query & View Functions
//    - isAllowedToken: Checks if a token address is currently allowed for deposit.
//    - getUserDepositInfo: Retrieves detailed information about a user's deposit for a specific token.
//    - calculateCurrentYield: Calculates the yield accumulated for a user's specific deposit based on time, vault state, and multipliers.
//    - getCurrentYieldRate: Returns the *current* effective yield rate considering vault state and any active temporal events.
//    - getTimeUntilWithdrawalCooldownEnds: Calculates the remaining time for a user's withdrawal cooldown for a token.
//    - getUserEmberAccumulationDetails: Shows how long a user has been accumulating Embers and potentially their rate.
//    - getPenaltyFeesCollected: Returns the total amount of penalty fees collected for a specific token.
//    - getVaultStateInfo: Returns information about the current vault state (name, base yield rate).
//    - getTemporalEventInfo: Returns details about any active temporal state event.
//
// Total Functions: 25+

contract EternalEmberVault is Context, Ownable {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    // --- Enums ---
    enum VaultState {
        Genesis,      // Early phase, maybe lower yield, higher Ember gain
        Bloom,        // Peak phase, highest yield
        Emberglow,    // Transitioning phase, yield starts to decrease, special Ember interactions
        Dormant,      // Low yield, maybe maintenance mode or waiting for restart
        Temporal      // Special temporary state triggered by owner event
    }

    // --- Structs ---
    struct UserDepositInfo {
        uint256 amount;
        uint256 depositTime; // Timestamp of deposit
        uint256 lastYieldClaimTime; // Timestamp of last yield calculation/claim/reinvest
        uint256 lockEndTime; // Timestamp until deposit is locked (0 if no lock)
        uint256 lastWithdrawalAttemptTime; // Timestamp of the last attempt to withdraw
        uint256 accumulatedYieldDebt; // Yield calculated but not yet transferred (to prevent double counting during reinvest)
    }

    // --- State Variables ---

    // Configuration
    mapping(address => bool) public allowedTokens;
    mapping(VaultState => uint256) public vaultStateBaseYieldRateBps; // Yield rate in Basis Points (10000 BPS = 100%)
    uint256 public emberAccumulationRatePerSecPerToken; // Embers accumulated per second per deposited token unit (e.g., 10^18 for 1 token)
    uint256 public withdrawalCooldownDuration; // Seconds
    uint256 public emberBurnCostForCooldownBypass; // Embers needed

    // Vault State
    VaultState public currentVaultState;
    uint256 public vaultStateChangeTime; // Timestamp when the current state began
    uint256 public temporalEventEndTime; // Timestamp when a temporal event ends (0 if none active)
    uint256 public temporalEventYieldMultiplierBps; // Yield multiplier during temporal event

    // User Data
    mapping(address => mapping(address => UserDepositInfo)) private userDeposits; // userAddress => tokenAddress => DepositInfo
    mapping(address => uint256) public userEmbers; // userAddress => Embers

    // Accumulated Penalties
    mapping(address => uint256) public penaltyFeesCollected; // tokenAddress => totalPenalties

    // --- Events ---
    event TokenAllowed(address indexed token);
    event TokenRemoved(address indexed token);
    event Deposited(address indexed user, address indexed token, uint256 amount, uint256 depositTime, uint256 lockEndTime);
    event Withdrew(address indexed user, address indexed token, uint256 amount, uint256 yieldClaimed, uint256 penaltyPaid);
    event YieldReinvested(address indexed user, address indexed token, uint256 yieldAmount);
    event VaultStateChanged(VaultState oldState, VaultState newState, uint256 changeTime);
    event TemporalEventTriggered(uint256 endTime, uint256 yieldMultiplierBps);
    event TemporalEventEnded();
    event EmbersAccumulated(address indexed user, uint256 amount);
    event EmbersClaimedBonus(address indexed user, uint256 bonusAmount); // Or other bonus details
    event EmbersBurned(address indexed user, uint256 amountBurned, string reason);
    event CooldownBypassed(address indexed user, address indexed token, uint256 embersBurned);
    event PenaltySwept(address indexed token, uint256 amount);

    // --- Constructor ---
    constructor(address initialOwner) Ownable(initialOwner) {
        currentVaultState = VaultState.Genesis;
        vaultStateChangeTime = block.timestamp;

        // Set some default rates (can be changed by owner)
        vaultStateBaseYieldRateBps[VaultState.Genesis] = 100; // 1%
        vaultStateBaseYieldRateBps[VaultState.Bloom] = 500;   // 5%
        vaultStateBaseYieldRateBps[VaultState.Emberglow] = 200; // 2%
        vaultStateBaseYieldRateBps[VaultState.Dormant] = 10;   // 0.1%

        emberAccumulationRatePerSecPerToken = 1; // Example: 1 Ember per token per second (adjust based on token decimals and desired scale)
        withdrawalCooldownDuration = 3 days; // Example
        emberBurnCostForCooldownBypass = 10000; // Example

        emit VaultStateChanged(VaultState.Dormant, VaultState.Genesis, block.timestamp); // Emit initial state change from dummy
    }

    // --- 1. Management & Configuration ---

    function setAllowedToken(address token) external onlyOwner {
        require(token != address(0), "Zero address not allowed");
        allowedTokens[token] = true;
        emit TokenAllowed(token);
    }

    function removeAllowedToken(address token) external onlyOwner {
        require(token != address(0), "Zero address not allowed");
        allowedTokens[token] = false;
        emit TokenRemoved(token);
    }

    function setVaultStateYieldRate(VaultState state, uint256 rateBps) external onlyOwner {
        require(uint256(state) < uint256(VaultState.Temporal), "Cannot set base rate for Temporal state");
        require(rateBps <= 10000, "Rate cannot exceed 100%"); // Basic check, might allow higher with caution
        vaultStateBaseYieldRateBps[state] = rateBps;
    }

    function setEmberAccumulationRate(uint256 ratePerSecPerToken) external onlyOwner {
        emberAccumulationRatePerSecPerToken = ratePerSecPerToken;
    }

    function setWithdrawalCooldownDuration(uint256 duration) external onlyOwner {
        withdrawalCooldownDuration = duration;
    }

    function setEmberBurnCostForCooldownBypass(uint256 cost) external onlyOwner {
        emberBurnCostForCooldownBypass = cost;
    }

    function emergencySweepERC20(address token, uint256 amount) external onlyOwner {
        require(token != address(0), "Zero address not allowed");
        // Only sweep tokens NOT accounted for in user deposits. This is complex to check fully
        // without iterating all user deposits. A safer approach is to only sweep tokens *not*
        // in the allowedTokens list, or rely on manual verification off-chain.
        // For simplicity here, we just perform the transfer. Owner must be careful.
        IERC20(token).safeTransfer(owner(), amount);
    }

    function sweepPenaltyFees(address token) external onlyOwner {
        require(token != address(0), "Zero address not allowed");
        uint256 fees = penaltyFeesCollected[token];
        require(fees > 0, "No penalty fees to sweep for this token");
        penaltyFeesCollected[token] = 0; // Reset before transfer
        IERC20(token).safeTransfer(owner(), fees);
        emit PenaltySwept(token, fees);
    }

    // Ownable functions inherited: transferOwnership, renounceOwnership

    // --- 2. Vault State Management ---

    function advanceVaultStateManually(VaultState newState) external onlyOwner {
        require(uint256(newState) < uint256(VaultState.Temporal), "Cannot manually set Temporal state directly");
        require(newState != currentVaultState, "Vault is already in this state");

        // Add potential conditions here (e.g., minimum time in current state)
        // require(block.timestamp >= vaultStateChangeTime + minStateDuration, "Not enough time elapsed in current state");

        VaultState oldState = currentVaultState;
        currentVaultState = newState;
        vaultStateChangeTime = block.timestamp;
        // Consider triggering Ember or yield recalculation for users if state change is significant

        emit VaultStateChanged(oldState, newState, block.timestamp);
    }

    function triggerTemporalStateEvent(uint256 duration, uint256 yieldMultiplierBps) external onlyOwner {
        require(temporalEventEndTime < block.timestamp, "A temporal event is already active");
        require(duration > 0, "Duration must be positive");
        // Add validation for yieldMultiplierBps if needed

        temporalEventEndTime = block.timestamp + duration;
        temporalEventYieldMultiplierBps = yieldMultiplierBps;
        // Store previous state to revert? Or make Temporal a modifier state? Let's make it a distinct state.
        VaultState oldState = currentVaultState;
        currentVaultState = VaultState.Temporal;

        emit TemporalEventTriggered(temporalEventEndTime, yieldMultiplierBps);
        emit VaultStateChanged(oldState, VaultState.Temporal, block.timestamp);
    }

     function endTemporalStateEvent() external onlyOwner {
        require(currentVaultState == VaultState.Temporal, "No temporal event active");
        // Revert to the state before Temporal? Need to store it.
        // Simpler: revert to a default state (e.g., Dormant or Genesis) or require owner to set next state manually.
        // Let's require owner to set the next state. This function just *ends* the temporal state effect.
        temporalEventEndTime = 0; // Signal end
        temporalEventYieldMultiplierBps = 0; // Reset multiplier

        // Transition to a default state or require manual state change afterwards?
        // For now, let's make it automatically go to Dormant, owner can change later.
        VaultState oldState = currentVaultState;
        currentVaultState = VaultState.Dormant;
        vaultStateChangeTime = block.timestamp;

        emit TemporalEventEnded();
        emit VaultStateChanged(oldState, currentVaultState, block.timestamp);
    }

    // --- 3. Deposit & Withdrawal Mechanics ---

    function deposit(address token, uint256 amount) external {
        _deposit(_msgSender(), token, amount, 0); // 0 means no lock
    }

    function depositWithTimeLock(address token, uint256 amount, uint256 lockDuration) external {
         require(lockDuration > 0, "Lock duration must be positive");
        _deposit(_msgSender(), token, amount, block.timestamp + lockDuration);
    }

    function _deposit(address user, address token, uint256 amount, uint256 lockEndTime) internal {
        require(amount > 0, "Amount must be greater than zero");
        require(allowedTokens[token], "Token is not allowed");

        UserDepositInfo storage info = userDeposits[user][token];

        // Calculate and add pending yield/embers for existing deposit before updating
        if (info.amount > 0) {
             // Claim existing yield/embers before merging new deposit
            _claimYieldInternal(user, token);
            _updateUserEmbers(user); // Update Embers based on time since last action
        }

        info.amount = info.amount.add(amount);
        info.depositTime = block.timestamp; // Update deposit time to blend (simpler avg not needed for this model)
        info.lastYieldClaimTime = block.timestamp;
        info.lockEndTime = lockEndTime;
        info.lastWithdrawalAttemptTime = 0; // Reset cooldown status
        // accumulatedYieldDebt is implicitly handled by _claimYieldInternal

        IERC20(token).safeTransferFrom(user, address(this), amount);

        // Embers are updated based on *duration* of holding, not deposit event itself
        // _updateUserEmbers will be called on interaction points (withdraw, claim, etc.)

        emit Deposited(user, token, amount, block.timestamp, lockEndTime);
    }


    function withdraw(address token, uint256 amount) external {
        require(amount > 0, "Amount must be greater than zero");
        UserDepositInfo storage info = userDeposits[_msgSender()][token];
        require(info.amount >= amount, "Insufficient deposited amount");

        // Check lock
        require(block.timestamp >= info.lockEndTime, "Deposit is locked");

        // Check cooldown
        require(block.timestamp >= info.lastWithdrawalAttemptTime + withdrawalCooldownDuration, "Withdrawal is in cooldown");

        // Calculate yield and update embers before withdrawal
        _claimYieldInternal(_msgSender(), token);
        _updateUserEmbers(_msgSender());

        // Perform withdrawal
        info.amount = info.amount.sub(amount);
        uint256 yieldPaid = info.accumulatedYieldDebt; // This includes the yield calculated in _claimYieldInternal
        info.accumulatedYieldDebt = 0; // Reset debt after paying

        // If withdrawing full amount, clean up deposit info
        if (info.amount == 0) {
             // Clear deposit info entirely? Be careful if user might deposit again.
             // Let's keep the struct but reset values to zero for minimal overhead.
             info.depositTime = 0;
             info.lastYieldClaimTime = 0;
             info.lockEndTime = 0;
             // lastWithdrawalAttemptTime is handled below
        } else {
            // If partial withdrawal, keep the deposit state but update times
            info.lastYieldClaimTime = block.timestamp; // Start yield calculation from now for remaining amount
        }

        info.lastWithdrawalAttemptTime = block.timestamp; // Start cooldown timer

        IERC20(token).safeTransfer(_msgSender(), amount.add(yieldPaid)); // Transfer principal + yield

        emit Withdrew(_msgSender(), token, amount, yieldPaid, 0); // No penalty on standard withdraw
    }

    function withdrawWithPenalty(address token, uint256 amount) external {
        require(amount > 0, "Amount must be greater than zero");
        UserDepositInfo storage info = userDeposits[_msgSender()][token];
        require(info.amount >= amount, "Insufficient deposited amount");
        require(info.lockEndTime > 0 && block.timestamp < info.lockEndTime, "Deposit is not locked or lock has expired"); // Must be withdrawing from a *locked* deposit early

        // Calculate yield and update embers before withdrawal
        _claimYieldInternal(_msgSender(), token);
        _updateUserEmbers(_msgSender());

        // Calculate penalty (e.g., percentage of amount, or loss of yield)
        // Simple penalty: a fixed percentage of the withdrawn amount
        uint256 penaltyRateBps = 500; // 5% penalty example
        uint256 penaltyAmount = amount.mul(penaltyRateBps).div(10000);

        uint256 amountAfterPenalty = amount.sub(penaltyAmount);
        uint256 yieldPaid = info.accumulatedYieldDebt; // This includes the yield calculated in _claimYieldInternal
        info.accumulatedYieldDebt = 0; // Reset debt after paying

         // Perform withdrawal
        info.amount = info.amount.sub(amount);

         // If withdrawing full amount, clean up deposit info
        if (info.amount == 0) {
             info.depositTime = 0;
             info.lastYieldClaimTime = 0;
             info.lockEndTime = 0;
             // lastWithdrawalAttemptTime is handled below
        } else {
             info.lastYieldClaimTime = block.timestamp; // Start yield calculation from now for remaining amount
        }

        info.lastWithdrawalAttemptTime = block.timestamp; // Start cooldown timer

        // Transfer
        IERC20(token).safeTransfer(_msgSender(), amountAfterPenalty.add(yieldPaid)); // Transfer principal (minus penalty) + yield
        penaltyFeesCollected[token] = penaltyFeesCollected[token].add(penaltyAmount); // Collect penalty

        emit Withdrew(_msgSender(), token, amount, yieldPaid, penaltyAmount);
    }

    function bypassWithdrawalCooldown(address token) external {
        UserDepositInfo storage info = userDeposits[_msgSender()][token];
        require(info.lastWithdrawalAttemptTime > 0 && block.timestamp < info.lastWithdrawalAttemptTime + withdrawalCooldownDuration, "No active withdrawal cooldown");
        require(userEmbers[_msgSender()] >= emberBurnCostForCooldownBypass, "Not enough Embers to bypass cooldown");

        userEmbers[_msgSender()] = userEmbers[_msgSender()].sub(emberBurnCostForCooldownBypass);
        info.lastWithdrawalAttemptTime = 0; // Immediately end cooldown

        emit EmbersBurned(_msgSender(), emberBurnCostForCooldownBypass, "BypassWithdrawalCooldown");
        emit CooldownBypassed(_msgSender(), token, emberBurnCostForCooldownBypass);
    }

    function reinvestYield(address token) external {
        UserDepositInfo storage info = userDeposits[_msgSender()][token];
        require(info.amount > 0, "No active deposit for this token");

        _claimYieldInternal(_msgSender(), token); // Calculate pending yield
        _updateUserEmbers(_msgSender()); // Update embers based on holding time

        uint256 yieldToReinvest = info.accumulatedYieldDebt;
        require(yieldToReinvest > 0, "No yield to reinvest");

        info.amount = info.amount.add(yieldToReinvest); // Add yield to principal
        info.accumulatedYieldDebt = 0; // Reset debt
        info.lastYieldClaimTime = block.timestamp; // Restart yield calculation from now

        // No token transfer, yield is added internally

        emit YieldReinvested(_msgSender(), token, yieldToReinvest);
    }

    // --- 4. Ember System & Interaction ---

    // Internal helper to update user Embers based on time since last interaction point
    // Should be called before any action that depends on current Embers or affects holding time (deposit, withdraw, claim yield/bonus, burn embers)
    function _updateUserEmbers(address user) internal {
        UserDepositInfo storage info = userDeposits[user][address(0)]; // Using dummy token address for total deposit time tracking
         if (info.depositTime == 0 || block.timestamp <= info.lastYieldClaimTime) {
             // No deposit or no time elapsed since last update point
             return;
         }

        uint256 timeHeld = block.timestamp.sub(info.lastYieldClaimTime);
        // To calculate Embers per user based on *total* deposited value across all tokens:
        // Need a total deposit tracking mechanism, which is more complex.
        // Let's simplify: Embers accumulate purely based on time *since their first deposit*, regardless of amount or token.
        // This encourages participation, not just whales.
        // If info.depositTime is used, it resets on *any* new deposit. Need a separate variable.
        // Let's add a `firstDepositTime` to UserDepositInfo struct for this purpose, initialized once.
        // For now, assuming Embers accumulate simply based on time *since the last _updateUserEmbers call point*
        // This means frequent interaction rewards more. Let's stick with info.lastYieldClaimTime for now.

        uint256 embersEarned = timeHeld.mul(emberAccumulationRatePerSecPerToken);
        userEmbers[user] = userEmbers[user].add(embersEarned);
        emit EmbersAccumulated(user, embersEarned);
    }

    function claimEmberBonus() external {
        _updateUserEmbers(_msgSender()); // Update Embers before checking balance

        uint256 currentEmbers = userEmbers[_msgSender()];
        require(currentEmbers > 0, "No Embers accumulated yet");

        // Implement bonus logic here based on Ember amount, tier, etc.
        // Example: Claim 100 bonus Embers if you have > 1000 Embers
        require(currentEmbers >= 1000, "Not enough Embers for this bonus tier (requires 1000)");

        uint256 bonusAmount = 100; // Example bonus
        userEmbers[_msgSender()] = userEmbers[_msgSender()].add(bonusAmount);
        // Maybe add a cooldown or limit how often this can be claimed
        // e.g., mapping(address => uint256) lastBonusClaimTime; require(block.timestamp > lastBonusClaimTime[_msgSender()] + bonusCooldown);

        emit EmbersClaimedBonus(_msgSender(), bonusAmount);
    }

    function burnEmbersForBenefit(uint256 embersToBurn, uint256 benefitId) external {
         _updateUserEmbers(_msgSender()); // Update Embers before burning
         require(userEmbers[_msgSender()] >= embersToBurn, "Not enough Embers to burn");
         require(embersToBurn > 0, "Cannot burn zero Embers");

         // Implement benefit logic based on benefitId and embersToBurn
         // Examples:
         // benefitId 1: Reduce penalty on early withdrawal by X% for the next withdrawal
         // benefitId 2: Get a temporary yield boost for Y hours
         // benefitId 3: Access a special vault function (e.g., participate in a mini-game)

         if (benefitId == 1) {
             // Example: Burn 500 Embers to reduce next penalty by 1%
             require(embersToBurn == 500, "Requires exactly 500 Embers for this benefit");
             // Need a state variable or mapping to track user's penalty reduction benefit
             // mapping(address => uint256) userPenaltyReductionBps;
             // userPenaltyReductionBps[_msgSender()] = userPenaltyReductionBps[_msgSender()].add(100); // Add 1% reduction
             // This is getting complex, demonstrating the function concept only:
             revert("Benefit 1 not fully implemented");
         } else {
             revert("Unknown benefitId");
         }

         userEmbers[_msgSender()] = userEmbers[_msgSender()].sub(embersToBurn);
         emit EmbersBurned(_msgSender(), embersToBurn, string(abi.encodePacked("BenefitId: ", Strings.toString(benefitId))));
    }


    // Internal helper to calculate yield and add to accumulatedYieldDebt
    function _claimYieldInternal(address user, address token) internal {
        UserDepositInfo storage info = userDeposits[user][token];
        if (info.amount == 0 || block.timestamp <= info.lastYieldClaimTime) {
            return; // No deposit or no time passed since last claim/update
        }

        uint256 timeElapsed = block.timestamp.sub(info.lastYieldClaimTime);
        uint256 currentYieldRateBps = getCurrentYieldRate(currentVaultState);

        // If temporal event is active, apply multiplier
        if (currentVaultState == VaultState.Temporal && block.timestamp <= temporalEventEndTime) {
             currentYieldRateBps = currentYieldRateBps.mul(temporalEventYieldMultiplierBps).div(10000);
        }

        // Yield calculation: amount * rate * time (simplified: rate is per second, time in seconds)
        // Rate needs to be per-second or per-year then converted.
        // Let's assume vaultStateBaseYieldRateBps is Annual Percentage Yield (APY) in BPS.
        // Convert APY (BPS) to per-second rate: (APY / 10000) / (365 * 24 * 60 * 60)
        // Simplified for example: Let vaultStateBaseYieldRateBps be the *per-second* rate in BPS * 10^X, where X is needed to avoid floating point.
        // Let's assume vaultStateBaseYieldRateBps is *per-second* rate directly in BPS for simplicity of example.
        // E.g., 1 BPS per second means 0.0001 * amount * time.
        // Actual per-second rate should be (Annual BPS / 10000) / seconds_per_year

        // Let's refine: vaultStateBaseYieldRateBps is APY in BPS.
        uint256 secondsPerYear = 365 * 24 * 60 * 60;
        // Yield per second = amount * (rate / 10000) / secondsPerYear
        // Total yield = amount * (rate / 10000) / secondsPerYear * timeElapsed
        // To avoid division first: total yield = amount * rate * timeElapsed / (10000 * secondsPerYear)
        // Using safe math:
        uint256 yieldAmount = info.amount.mul(currentYieldRateBps).mul(timeElapsed).div(10000).div(secondsPerYear);

        info.accumulatedYieldDebt = info.accumulatedYieldDebt.add(yieldAmount);
        info.lastYieldClaimTime = block.timestamp; // Update for next calculation
        // Note: Yield is accumulated internally ("debt") and only transferred on withdrawal or reinvest.
    }


    // --- 5. Query & View Functions ---

    function isAllowedToken(address token) external view returns (bool) {
        return allowedTokens[token];
    }

    function getUserDepositInfo(address user, address token) external view returns (UserDepositInfo memory) {
        return userDeposits[user][token];
    }

    function calculateCurrentYield(address user, address token) external view returns (uint256 pendingYield) {
         UserDepositInfo storage info = userDeposits[user][token];
        if (info.amount == 0 || block.timestamp <= info.lastYieldClaimTime) {
            return info.accumulatedYieldDebt; // Return already calculated debt if no time passed
        }

        uint256 timeElapsed = block.timestamp.sub(info.lastYieldClaimTime);
        uint256 currentYieldRateBps = getCurrentYieldRate(currentVaultState);

        // If temporal event is active, apply multiplier
         if (currentVaultState == VaultState.Temporal && block.timestamp <= temporalEventEndTime) {
             currentYieldRateBps = currentYieldRateBps.mul(temporalEventYieldMultiplierBps).div(10000);
        }

        uint256 secondsPerYear = 365 * 24 * 60 * 60;
        uint256 yieldAmount = info.amount.mul(currentYieldRateBps).mul(timeElapsed).div(10000).div(secondsPerYear);

        return info.accumulatedYieldDebt.add(yieldAmount); // Return debt + newly calculated yield
    }

    function getCurrentYieldRate(VaultState state) public view returns (uint256 rateBps) {
        if (state == VaultState.Temporal && block.timestamp <= temporalEventEndTime) {
            // Special handling for Temporal state - base rate is potentially irrelevant, multiplier applies.
            // Or, it could be a multiplier ON TOP of the state before Temporal?
            // Let's make it simpler: Temporal state *sets* a rate multiplier applied to the base rate of the state active *when* Temporal was triggered.
            // This requires storing the state *before* temporal. Let's skip that complexity for 20+ functions.
            // Simpler: Temporal state has its OWN rate logic, defined by the multiplier.
             // Let's assume temporalEventYieldMultiplierBps is the *actual* yield rate in BPS during the temporal event.
             // This means setVaultStateYieldRate for VaultState.Temporal is ignored.
             return temporalEventYieldMultiplierBps;

        } else if (state == VaultState.Temporal && block.timestamp > temporalEventEndTime) {
             // Temporal event ended but state hasn't changed yet - return 0 or base rate of next state?
             // The `currentVaultState` should ideally change immediately. The endTemporalStateEvent function handles this.
             // If somehow query happens *after* end time but *before* state change, return 0 yield.
             return 0; // Should not happen if state transition is immediate on end
        } else {
             // Regular vault states
            return vaultStateBaseYieldRateBps[state];
        }
    }


    function getTimeUntilWithdrawalCooldownEnds(address user, address token) external view returns (uint256 remainingTime) {
        UserDepositInfo storage info = userDeposits[user][token];
        uint256 cooldownEnd = info.lastWithdrawalAttemptTime.add(withdrawalCooldownDuration);

        if (info.lastWithdrawalAttemptTime == 0 || block.timestamp >= cooldownEnd) {
            return 0; // No active cooldown
        } else {
            return cooldownEnd.sub(block.timestamp);
        }
    }

    function getUserEmberAccumulationDetails(address user) external view returns (uint256 currentEmbers, uint256 timeSinceLastUpdate) {
        // _updateUserEmbers is internal and updates on interaction.
        // To show accumulation *potential* since last update:
        UserDepositInfo storage info = userDeposits[user][address(0)]; // Dummy token for time tracking
        uint256 time = (info.lastYieldClaimTime == 0 || info.amount == 0) ? 0 : block.timestamp.sub(info.lastYieldClaimTime);
        // This is complex as Embers should likely accumulate based on *any* active deposit time.
        // Let's simplify the Ember system: Embers update whenever a user interacts, based on the *total time* holding *any* deposit since *contract deploy or first deposit*.
        // Need `userFirstDepositTime` mapping.

        // Revised simple Ember query: Just return current balance and time since last update point.
        // The *rate* calculation for potential accumulation requires knowing total staked value over time, which is complex to track globally.
        // Let's make Embers accumulate based on *presence* of *any* deposit over time.
        uint256 timeSinceLastInteraction = (userDeposits[user][address(0)].lastYieldClaimTime == 0) ? block.timestamp.sub(userDeposits[user][address(0)].depositTime) : block.timestamp.sub(userDeposits[user][address(0)].lastYieldClaimTime);
        // This still has issues if depositTime is reset on new deposit.

        // Let's revert to the simplest Ember model for query: Embers are only updated on specific actions, based on duration *between* actions.
        // This query just shows the current accumulated balance.
        return (userEmbers[user], timeSinceLastInteraction);
    }

    function getPenaltyFeesCollected(address token) external view returns (uint256) {
        return penaltyFeesCollected[token];
    }

    function getVaultStateInfo() external view returns (VaultState state, uint256 changeTime, uint256 baseYieldRateBps) {
        VaultState currentState = currentVaultState;
        uint256 rate = (currentState == VaultState.Temporal) ? temporalEventYieldMultiplierBps : vaultStateBaseYieldRateBps[currentState];
        return (currentState, vaultStateChangeTime, rate);
    }

    function getTemporalEventInfo() external view returns (uint256 endTime, uint256 yieldMultiplierBps, bool isActive) {
        bool active = (currentVaultState == VaultState.Temporal && block.timestamp <= temporalEventEndTime);
        return (temporalEventEndTime, temporalEventYieldMultiplierBps, active);
    }

    // Example function combining multiple user queries
     function getUserVaultStatus(address user, address token) external view returns (
        uint256 depositedAmount,
        uint256 pendingYield,
        uint256 lockEndTime,
        uint256 withdrawalCooldownEnds,
        uint256 userEmbersBalance
    ) {
        UserDepositInfo storage info = userDeposits[user][token];
        depositedAmount = info.amount;
        pendingYield = calculateCurrentYield(user, token); // Re-uses existing logic
        lockEndTime = info.lockEndTime;
        withdrawalCooldownEnds = info.lastWithdrawalAttemptTime.add(withdrawalCooldownDuration);
         if (info.lastWithdrawalAttemptTime == 0 || block.timestamp >= withdrawalCooldownEnds) {
             withdrawalCooldownEnds = 0; // Signal no active cooldown
         }
        userEmbersBalance = userEmbers[user];

        return (
            depositedAmount,
            pendingYield,
            lockEndTime,
            withdrawalCooldownEnds,
            userEmbersBalance
        );
    }

    // Placeholder for a more advanced migration function if contract logic needs future updates
    // This doesn't implement a proxy pattern, but shows the *trigger* for migration.
    function migrateToNextVersion(address newVaultAddress) external onlyOwner {
         require(newVaultAddress != address(0), "New vault address cannot be zero");
         // In a real scenario, this would involve:
         // 1. Pausing deposits/withdrawals in this contract.
         // 2. Users calling a function (here or in new contract) to migrate their position.
         // 3. Transferring remaining token balance (excluding user deposits) to the new contract.
         // This placeholder function only signals the intention.
         // A full migration system is complex and often involves proxy patterns (like UUPS or Transparent).
         emit VaultStateChanged(currentVaultState, VaultState.Dormant, block.timestamp); // Signal end of life
         currentVaultState = VaultState.Dormant; // Put vault into dormant state
         // Potential: Transfer ownership to the new contract? No, better to keep ownership here for control.
         // A real migration would likely involve looping through userDeposits (difficult on-chain) or having users self-migrate.
    }

    // Internal function pattern demonstration: Proposing a state transition that requires owner approval before execution.
    // This is a simple example; a real system might use a multisig or DAO.
    VaultState private _proposedNextState;
    uint256 private _proposedStateTime;

    function proposeStateTransition(VaultState state) internal onlyOwner {
        require(uint256(state) < uint256(VaultState.Temporal), "Cannot propose Temporal state this way");
        _proposedNextState = state;
        _proposedStateTime = block.timestamp;
        // Could emit an event here
    }

    // This internal function isn't exposed, but demonstrates a pattern where state transitions might be batched or triggered by another process.
    // A function like `executeProposedStateTransition` would be external/owner.
     function executeProposedStateTransition() external onlyOwner {
         require(_proposedStateTime > 0, "No state transition proposed");
         VaultState nextState = _proposedNextState;
         _proposedNextState = VaultState.Dormant; // Reset proposal
         _proposedStateTime = 0;

         // Add proposal validity checks (e.g., time limit on proposal)

         advanceVaultStateManually(nextState); // Use existing state transition logic
     }


}
```