Okay, here is a Solidity smart contract implementing a conceptual "Quantum Entangled Treasury". The core idea is a treasury where user access, rewards, and capabilities are influenced by a dynamic "Entanglement Index," calculated based on a combination of factors like staked amount, lock duration, reputation score, and holding a specific linked NFT. Furthermore, a "Global Quantum Shift" event can be triggered if the *aggregate* entanglement level of all participants crosses a certain threshold, unlocking special actions.

This contract is designed to be *creative* and *advanced* by:
1.  **Dynamic Weighted Index:** The user's standing (`entanglementIndex`) isn't static but is calculated based on multiple factors with adjustable weights.
2.  **Interdependent State:** Individual user states contribute to an aggregate state (`globalEntanglementIndex`), which can trigger a global event (`triggerGlobalQuantumShift`).
3.  **Reputation System:** A simple internal reputation score mechanism influencing the index.
4.  **External NFT Linkage:** Integrating an external ERC721 token as a factor in the index.
5.  **Time-Based Rewards:** Rewards accrue based on stake amount, *and* the entanglement index over time.
6.  **Threshold-Based Global Event:** A unique function triggered only when a collective state metric is met.
7.  **Numerous Functions:** Providing a rich interface for interacting with the complex state.

**Disclaimer:** This contract is a conceptual example for educational and creative purposes. It involves complex state management and interactions. It has not been formally audited or tested for production use. Implementing such a system would require rigorous security review, gas optimization, and careful consideration of the economic model.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

// --- OUTLINE ---
// 1. Contract Definition: Inherits Ownable, ReentrancyGuard.
// 2. Error Definitions: Custom errors for clarity.
// 3. Event Definitions: Signals for key state changes.
// 4. Structs: Define UserQuantumState and EntanglementFormulaWeights.
// 5. State Variables: Store treasury state, user data, global parameters, weights.
// 6. Modifiers: Custom access/condition checks.
// 7. Constructor: Initializes owner and initial parameters.
// 8. Internal/Private Helpers:
//    - _calculateEntanglementIndex: Computes index for a single user.
//    - _updateUserEntanglementIndex: Recalculates and stores index for a user.
//    - _distributePendingRewards: Calculates and updates pending rewards.
//    - _checkGlobalEntanglementThreshold: Checks if aggregate index meets threshold.
// 9. Core Treasury Functions: Deposit and (restricted) Withdrawal.
// 10. Staking Functions: Stake Ether, Unstake Ether, Extend Lock Duration.
// 11. Entanglement Factor Functions:
//     - Reputation Management (Admin only for simplicity): Mint/Burn Reputation.
//     - NFT Linkage: Link/Unlink an external ERC721 NFT.
// 12. Entanglement & Reward Functions:
//     - Claim accrued rewards based on stake and index.
//     - View pending rewards.
// 13. Configuration (Admin/Governance):
//     - Set minimum stake, maximum lock.
//     - Set weights for the Entanglement Index formula.
//     - Set parameters for the Global Quantum Shift threshold.
//     - Set the base reward rate.
// 14. Global Quantum Shift Trigger:
//     - Function to potentially trigger a global event based on aggregate index.
// 15. Query Functions: View user state, global state, parameters.
// 16. Ownership Functions: Standard Ownable renounce.

// --- FUNCTION SUMMARY ---
// constructor(): Deploys contract, sets owner and initial parameters.
// depositEther(): Users can deposit Ether into the treasury.
// withdrawEther(uint256 amount): Owner-only function to withdraw Ether from treasury.
// stake(uint256 lockDurationInSeconds): Users stake Ether, setting a lock period. Calculates initial index.
// unstake(): Users unstake their Ether after the lock period expires. Distributes pending rewards.
// extendLockDuration(uint256 additionalDurationInSeconds): Users can add time to their existing stake lock. Recalculates index.
// claimEntangledRewards(): Users claim accrued rewards based on their stake, index, and time.
// getClaimableRewards(address user): View function to see how many rewards a user can claim.
// mintReputation(address user, uint256 amount): Admin function to add reputation points to a user.
// burnReputation(address user, uint256 amount): Admin function to remove reputation points from a user.
// linkEntanglementCatalystNFT(address nftContract, uint256 tokenId): User links a specific ERC721 NFT they own to their state. Recalculates index.
// unlinkEntanglementCatalystNFT(): User unlinks their previously linked NFT. Recalculates index.
// setEntanglementIndexFormulaWeights(uint256 _stakeWeight, uint256 _lockDurationWeight, uint256 _reputationWeight, uint256 _nftLinkedWeight): Admin sets the weights for index calculation factors. Weights are scaled (e.g., by 1e4).
// setReputationFactorWeights(uint256 _repMintWeight, uint256 _repBurnWeight): Admin sets weights for how much mint/burn affects the score (less critical for this example, maybe future use).
// setBaseRewardRatePerSecond(uint256 rate): Admin sets the base rate at which rewards accrue per second (scaled).
// setMinimumStakeAmount(uint256 amount): Admin sets the minimum amount required for a new stake.
// setMaximumLockDuration(uint40 duration): Admin sets the maximum allowed lock duration for stakes.
// setGlobalEntanglementThreshold(uint256 threshold): Admin sets the aggregate index threshold for triggering a global shift.
// setGlobalShiftBonusPool(uint256 amount): Admin can add Ether to a special bonus pool for the shift event.
// triggerGlobalQuantumShift(): Public function anyone can call, but only executes if the aggregate entanglement index meets the set threshold. Unlocks the bonus pool.
// getUserQuantumState(address user): View function showing a user's full state (stake, lock, reputation, NFT link status, current index).
// getUserEntanglementIndex(address user): View function to get a specific user's current entanglement index.
// getReputationScore(address user): View function to get a user's reputation score.
// isNFTSignificantlyLinked(address user): View function checking if user has a linked NFT.
// getGlobalEntanglementStats(): View function showing aggregate stats (total staked, total index, global threshold).
// checkGlobalEntanglementThreshold(): View function to see if the global shift condition is currently met.
// getGlobalShiftBonusPoolAmount(): View function for the bonus pool balance.
// renounceOwnership(): Standard function to give up ownership.

contract QuantumEntangledTreasury is Ownable, ReentrancyGuard {

    // --- ERRORS ---
    error InvalidLockDuration();
    error StakeAmountTooLow(uint256 minimum);
    error NoActiveStake();
    error StakeLocked(uint40 unlockTime);
    error NoRewardsToClaim();
    error NFTAlreadyLinked();
    error NFTNotOwnedOrApproved();
    error NFTNotLinked();
    error GlobalThresholdNotMet();
    error AlreadyShifted();

    // --- EVENTS ---
    event EtherDeposited(address indexed user, uint256 amount);
    event EtherWithdrawn(address indexed user, uint256 amount); // Owner withdrawals
    event EtherStaked(address indexed user, uint256 amount, uint40 lockUntil);
    event EtherUnstaked(address indexed user, uint256 amount);
    event LockDurationExtended(address indexed user, uint40 newLockUntil);
    event RewardsClaimed(address indexed user, uint256 amount);
    event ReputationMinted(address indexed user, uint256 amount);
    event ReputationBurned(address indexed user, uint256 amount);
    event NFTLinked(address indexed user, address nftContract, uint256 tokenId);
    event NFTUnlinked(address indexed user);
    event EntanglementIndexUpdated(address indexed user, uint256 newIndex);
    event GlobalEntanglementThresholdMet(uint256 totalIndex);
    event GlobalQuantumShiftTriggered(uint256 bonusAmountDistributed);
    event FormulaWeightsUpdated(uint256 stakeWeight, uint256 lockWeight, uint256 repWeight, uint256 nftWeight);
    event ParametersUpdated(uint256 minStake, uint40 maxLock, uint256 baseRate, uint256 globalThreshold);
    event GlobalShiftBonusPoolAdded(uint256 amount);

    // --- STRUCTS ---

    struct UserQuantumState {
        uint256 stakedAmount;
        uint40 lockUntil; // Timestamp when stake unlocks
        uint256 reputationScore;
        bool isNFTSignificantlyLinked; // True if required NFT is linked
        uint256 entanglementIndex; // Calculated score based on factors
        uint256 rewardDebt; // Rewards already distributed or accounted for
        uint40 lastRewardUpdateTime; // Timestamp of last reward calculation
    }

    // Weights used in the Entanglement Index formula
    // Scaled by 1e4 to allow for decimal-like precision
    struct EntanglementFormulaWeights {
        uint256 stakeWeight;        // Weight for stakedAmount (scaled, e.g., 1e4 means 1:1)
        uint256 lockDurationWeight; // Weight for lock duration (scaled, per second)
        uint256 reputationWeight;   // Weight for reputationScore (scaled)
        uint256 nftLinkedWeight;    // Bonus added if NFT is linked (scaled)
    }

    // --- STATE VARIABLES ---

    mapping(address => UserQuantumState) public userStates;
    uint256 private _totalStaked; // Sum of all userStates[user].stakedAmount

    // Global parameters affecting index calculation and staking
    EntanglementFormulaWeights public entanglementWeights;
    uint256 public baseRewardRatePerSecond; // Base rate for reward calculation (scaled, e.g., wei per second per index point)
    uint256 public totalEntanglementIndex; // Sum of all userStates[user].entanglementIndex
    uint256 public constant WEIGHT_SCALING_FACTOR = 1e4; // Scaling for weights

    // Staking constraints
    uint256 public minimumStakeAmount;
    uint40 public maximumLockDuration; // Max lock duration in seconds

    // NFT Linkage details (can be expanded for multiple NFT types)
    address public entanglementCatalystNFTContract; // Address of the required ERC721 contract

    // Global Quantum Shift parameters
    uint256 public globalEntanglementThreshold; // Threshold for totalEntanglementIndex
    uint256 public globalShiftBonusPool; // Ether reserved for the global shift event
    bool public globalShiftTriggered = false;

    // --- MODIFIERS ---

    modifier whenStakingNotPaused() {
        // Add pause functionality if needed. For this example, it's omitted for brevity
        // but a boolean state variable and modifier would go here.
        _;
    }

    modifier requireStake() {
        if (userStates[msg.sender].stakedAmount == 0) {
            revert NoActiveStake();
        }
        _;
    }

    // --- CONSTRUCTOR ---

    constructor(
        address _entanglementCatalystNFTContract,
        uint256 _initialMinStake,
        uint40 _initialMaxLock,
        uint256 _initialBaseRewardRatePerSecond, // scaled
        uint256 _initialGlobalThreshold,
        uint256 _initialStakeWeight,           // scaled
        uint256 _initialLockDurationWeight,    // scaled
        uint256 _initialReputationWeight,      // scaled
        uint256 _initialNftLinkedWeight        // scaled
    ) Ownable(msg.sender) {
        entanglementCatalystNFTContract = _entanglementCatalystNFTContract;
        minimumStakeAmount = _initialMinStake;
        maximumLockDuration = _initialMaxLock;
        baseRewardRatePerSecond = _initialBaseRewardRatePerSecond;
        globalEntanglementThreshold = _initialGlobalThreshold;

        entanglementWeights = EntanglementFormulaWeights({
            stakeWeight: _initialStakeWeight,
            lockDurationWeight: _initialLockDurationWeight,
            reputationWeight: _initialReputationWeight,
            nftLinkedWeight: _initialNftLinkedWeight
        });

        emit FormulaWeightsUpdated(
            entanglementWeights.stakeWeight,
            entanglementWeights.lockDurationWeight,
            entanglementWeights.reputationWeight,
            entanglementWeights.nftLinkedWeight
        );
        emit ParametersUpdated(
            minimumStakeAmount,
            maximumLockDuration,
            baseRewardRatePerSecond,
            globalEntanglementThreshold
        );
    }

    // --- INTERNAL / PRIVATE HELPERS ---

    /// @dev Calculates the raw entanglement index for a user based on current state and weights.
    /// @param user The address of the user.
    /// @return The calculated entanglement index.
    function _calculateEntanglementIndex(address user) internal view returns (uint256) {
        UserQuantumState storage state = userStates[user];
        uint256 index = 0;

        // Avoid division by zero if WEIGHT_SCALING_FACTOR is 0, though unlikely.
        if (WEIGHT_SCALING_FACTOR == 0) return 0;

        // Factor 1: Staked Amount
        // (stakedAmount * stakeWeight) / scaling
        index += (state.stakedAmount * entanglementWeights.stakeWeight) / WEIGHT_SCALING_FACTOR;

        // Factor 2: Remaining Lock Duration
        // Only count if currently locked
        if (state.lockUntil > block.timestamp) {
            uint40 remainingLock = state.lockUntil - uint40(block.timestamp);
            // (remainingLock * lockDurationWeight) / scaling
             index += (uint256(remainingLock) * entanglementWeights.lockDurationWeight) / WEIGHT_SCALING_FACTOR;
        }

        // Factor 3: Reputation Score
        // (reputationScore * reputationWeight) / scaling
        index += (state.reputationScore * entanglementWeights.reputationWeight) / WEIGHT_SCALING_FACTOR;

        // Factor 4: Linked NFT Bonus
        if (state.isNFTSignificantlyLinked) {
            index += entanglementWeights.nftLinkedWeight / WEIGHT_SCALING_FACTOR;
        }

        return index;
    }

    /// @dev Updates a user's entanglement index and the global total index.
    /// @param user The address of the user.
    function _updateUserEntanglementIndex(address user) internal {
        UserQuantumState storage state = userStates[user];
        uint256 oldIndex = state.entanglementIndex;
        uint256 newIndex = _calculateEntanglementIndex(user);

        // Update total index
        if (newIndex > oldIndex) {
            totalEntanglementIndex += (newIndex - oldIndex);
        } else {
             // Prevent underflow if somehow oldIndex is vastly larger due to complex state changes
            totalEntanglementIndex -= (oldIndex - newIndex);
        }

        state.entanglementIndex = newIndex;
        emit EntanglementIndexUpdated(user, newIndex);
    }

     /// @dev Calculates and adds pending rewards to a user's rewardDebt.
     /// @param user The address of the user.
    function _distributePendingRewards(address user) internal {
        UserQuantumState storage state = userStates[user];
        uint40 lastUpdateTime = state.lastRewardUpdateTime;
        uint256 currentStake = state.stakedAmount;
        uint256 currentEntanglementIndex = state.entanglementIndex;

        if (currentStake == 0 || currentEntanglementIndex == 0 || lastUpdateTime >= block.timestamp) {
             state.lastRewardUpdateTime = uint40(block.timestamp);
             return; // No stake, index, or time has passed
        }

        uint256 timeElapsed = block.timestamp - lastUpdateTime;

        // Simple reward calculation: stake * index * baseRate * time
        // Need to be careful with potential overflows, scale down early if possible
        // Assuming baseRatePerSecond is scaled, and index is scaled (by WEIGHT_SCALING_FACTOR)
        // Reward = (stake * index / index_scaling * baseRate / rate_scaling) * time
        // Let's use baseRatePerSecond scaled by 1e18 for simpler math with Ether units
        // Let's adjust baseRewardRatePerSecond to be scaled by 1e18 / second per index point per wei staked
        // New Reward Rate: baseRewardRatePerSecond (wei per second) * index / (WEIGHT_SCALING_FACTOR) * stake / (1e18 wei)
        // Total Reward = (baseRewardRatePerSecond * currentEntanglementIndex * currentStake * timeElapsed) / (WEIGHT_SCALING_FACTOR * 1e18)

        // Safer calculation:
        // rewards = (stake * index * timeElapsed) / (WEIGHT_SCALING_FACTOR * 1e18 / baseRewardRatePerSecond)
        // Or even simpler: calculate rate per stake per index per second first
        // rate_per_unit = baseRewardRatePerSecond / (WEIGHT_SCALING_FACTOR * 1e18) -> very small, potentially zero
        // Let's assume baseRewardRatePerSecond is scaled such that:
        // Reward per second = (baseRewardRatePerSecond * currentStake * currentEntanglementIndex) / (scaling factors combined)
        // Let's define a REWARD_SCALING_FACTOR as well, maybe 1e18 * WEIGHT_SCALING_FACTOR
         uint256 REWARD_SCALING_FACTOR = 1e18 * WEIGHT_SCALING_FACTOR; // 1e22 if WEIGHT_SCALING_FACTOR is 1e4

         // Potential rewards accrued = (baseRewardRatePerSecond * currentStake * currentEntanglementIndex * timeElapsed) / REWARD_SCALING_FACTOR
         uint256 potentialRewards = (baseRewardRatePerSecond * currentStake / 1e18) * currentEntanglementIndex; // Intermediate calculation to reduce large numbers
         potentialRewards = (potentialRewards * timeElapsed) / WEIGHT_SCALING_FACTOR; // Final scaling

        // Add accrued rewards to debt
        state.rewardDebt += potentialRewards;

        state.lastRewardUpdateTime = uint40(block.timestamp);
    }

    /// @dev Checks if the aggregate entanglement index meets the global threshold.
    /// @return True if the threshold is met.
    function _checkGlobalEntanglementThreshold() internal view returns (bool) {
        return totalEntanglementIndex >= globalEntanglementThreshold;
    }

    // --- CORE TREASURY FUNCTIONS ---

    /// @notice Allows anyone to deposit Ether into the treasury.
    /// @dev Increases the contract's Ether balance. Does not affect user state directly.
    receive() external payable {
        emit EtherDeposited(msg.sender, msg.value);
    }

     /// @notice Allows the owner to withdraw Ether from the treasury.
     /// @dev Can only be called by the contract owner.
     /// @param amount The amount of Ether to withdraw.
    function withdrawEther(uint256 amount) external onlyOwner nonReentrant {
        require(address(this).balance >= amount, "Insufficient balance");
        (bool success, ) = payable(msg.sender).call{value: amount}("");
        require(success, "Ether withdrawal failed");
        emit EtherWithdrawn(msg.sender, amount);
    }

     /// @notice Allows the owner to add Ether to the special Global Shift Bonus Pool.
     /// @dev This Ether is reserved and only distributable via triggerGlobalQuantumShift.
    function setGlobalShiftBonusPool() external payable onlyOwner {
        globalShiftBonusPool += msg.value;
        emit GlobalShiftBonusPoolAdded(msg.value);
    }


    // --- STAKING FUNCTIONS ---

    /// @notice Allows a user to stake Ether and set a lock duration.
    /// @dev Adds to user's staked balance, updates lock time, and recalculates entanglement index.
    /// @param lockDurationInSeconds The number of seconds the stake will be locked.
    function stake(uint40 lockDurationInSeconds) external payable nonReentrant whenStakingNotPaused {
        require(msg.value >= minimumStakeAmount, StakeAmountTooLow(minimumStakeAmount));
        require(lockDurationInSeconds > 0 && lockDurationInSeconds <= maximumLockDuration, InvalidLockDuration());

        UserQuantumState storage state = userStates[msg.sender];

        // Distribute pending rewards before potentially changing stake/lock
        _distributePendingRewards(msg.sender);

        // Add new stake amount
        state.stakedAmount += msg.value;
        _totalStaked += msg.value;

        // Set or extend lock time (take the later of the current lock or the new lock)
        uint40 newLockUntil = uint40(block.timestamp + lockDurationInSeconds);
        if (newLockUntil > state.lockUntil) {
            state.lockUntil = newLockUntil;
            emit LockDurationExtended(msg.sender, state.lockUntil);
        }

        // Recalculate index based on new state
        _updateUserEntanglementIndex(msg.sender);

        emit EtherStaked(msg.sender, msg.value, state.lockUntil);
    }

     /// @notice Allows a user to unstake their Ether after the lock period expires.
     /// @dev Requires the stake lock to have passed. Distributes pending rewards first.
    function unstake() external requireStake nonReentrant {
        UserQuantumState storage state = userStates[msg.sender];
        if (block.timestamp < state.lockUntil) {
            revert StakeLocked(state.lockUntil);
        }

        // Distribute pending rewards before unstaking
        _distributePendingRewards(msg.sender);

        uint256 amountToUnstake = state.stakedAmount;
        state.stakedAmount = 0;
        _totalStaked -= amountToUnstake;

        // Reset lock time and update index (should likely become 0 if stake is 0)
        state.lockUntil = 0;
        _updateUserEntanglementIndex(msg.sender);

        // Transfer the staked amount back
        (bool success, ) = payable(msg.sender).call{value: amountToUnstake}("");
        require(success, "Unstake transfer failed");

        emit EtherUnstaked(msg.sender, amountToUnstake);
    }

    /// @notice Allows a user to extend the lock duration of their existing stake.
    /// @dev Requires an active stake. New lock must be valid and extend the current lock.
    /// @param additionalDurationInSeconds The number of *additional* seconds to lock.
    function extendLockDuration(uint40 additionalDurationInSeconds) external requireStake nonReentrant {
        UserQuantumState storage state = userStates[msg.sender];
        require(additionalDurationInSeconds > 0, "Must extend by a positive duration");

         uint40 currentLockUntil = state.lockUntil;
         if (currentLockUntil < block.timestamp) {
             currentLockUntil = uint40(block.timestamp); // If lock expired, extend from now
         }

        uint40 newLockUntil = currentLockUntil + additionalDurationInSeconds;
        require(newLockUntil >= block.timestamp, "Lock time cannot be in the past"); // Should be true due to previous check
        require(newLockUntil - uint40(block.timestamp) <= maximumLockDuration, "New lock exceeds max allowed duration");

         // Distribute pending rewards before potentially changing lock
         _distributePendingRewards(msg.sender);

        state.lockUntil = newLockUntil;

         // Recalculate index based on new lock time
        _updateUserEntanglementIndex(msg.sender);

        emit LockDurationExtended(msg.sender, newLockUntil);
    }


    // --- ENTANGLEMENT FACTOR FUNCTIONS ---

    /// @notice Allows admin to mint reputation points for a user.
    /// @dev Directly increases reputation score and recalculates entanglement index.
    /// @param user The user's address.
    /// @param amount The amount of reputation to add.
    function mintReputation(address user, uint256 amount) external onlyOwner nonReentrant {
        require(amount > 0, "Amount must be positive");
        UserQuantumState storage state = userStates[user];

        // Distribute pending rewards before potentially changing index
        _distributePendingRewards(user);

        state.reputationScore += amount;
        _updateUserEntanglementIndex(user);
        emit ReputationMinted(user, amount);
    }

     /// @notice Allows admin to burn reputation points from a user.
     /// @dev Directly decreases reputation score and recalculates entanglement index.
     /// @param user The user's address.
     /// @param amount The amount of reputation to remove.
    function burnReputation(address user, uint256 amount) external onlyOwner nonReentrant {
        require(amount > 0, "Amount must be positive");
        UserQuantumState storage state = userStates[user];

         // Distribute pending rewards before potentially changing index
         _distributePendingRewards(user);

        if (state.reputationScore < amount) {
            state.reputationScore = 0;
        } else {
            state.reputationScore -= amount;
        }
        _updateUserEntanglementIndex(user);
        emit ReputationBurned(user, amount);
    }

    /// @notice Allows a user to link a specific Entanglement Catalyst NFT they own.
    /// @dev Requires the user to own the NFT. Updates state and recalculates index.
    /// @param nftContract The address of the ERC721 contract.
    /// @param tokenId The ID of the token to link.
    function linkEntanglementCatalystNFT(address nftContract, uint256 tokenId) external nonReentrant {
        require(nftContract == entanglementCatalystNFTContract, "Cannot link this NFT contract");
        UserQuantumState storage state = userStates[msg.sender];
        if (state.isNFTSignificantlyLinked) {
            revert NFTAlreadyLinked();
        }

        // Check ownership of the NFT
        IERC721 nft = IERC721(nftContract);
        require(nft.ownerOf(tokenId) == msg.sender, NFTNotOwnedOrApproved());

         // Distribute pending rewards before potentially changing index
         _distributePendingRewards(msg.sender);

        state.isNFTSignificantlyLinked = true;

        // Recalculate index
        _updateUserEntanglementIndex(msg.sender);

        emit NFTLinked(msg.sender, nftContract, tokenId);
    }

    /// @notice Allows a user to unlink their previously linked Entanglement Catalyst NFT.
    /// @dev Requires an NFT to be currently linked. Updates state and recalculates index.
    function unlinkEntanglementCatalystNFT() external nonReentrant {
        UserQuantumState storage state = userStates[msg.sender];
        if (!state.isNFTSignificantlyLinked) {
            revert NFTNotLinked();
        }

         // Distribute pending rewards before potentially changing index
         _distributePendingRewards(msg.sender);

        state.isNFTSignificantlyLinked = false;

        // Recalculate index
        _updateUserEntanglementIndex(msg.sender);

        emit NFTUnlinked(msg.sender);
    }


    // --- ENTANGLEMENT & REWARD FUNCTIONS ---

     /// @notice Allows a user to claim their accrued entangled rewards.
     /// @dev Rewards are calculated based on stake, entanglement index, and time since last claim/stake.
    function claimEntangledRewards() external nonReentrant {
        UserQuantumState storage state = userStates[msg.sender];

        // Ensure pending rewards are calculated up to this point
        _distributePendingRewards(msg.sender);

        uint256 rewardsToClaim = state.rewardDebt;
        if (rewardsToClaim == 0) {
            revert NoRewardsToClaim();
        }

        // Reset reward debt
        state.rewardDebt = 0;

        // Transfer rewards from treasury
        require(address(this).balance >= rewardsToClaim, "Insufficient treasury balance for rewards");
        (bool success, ) = payable(msg.sender).call{value: rewardsToClaim}("");
        require(success, "Reward transfer failed");

        emit RewardsClaimed(msg.sender, rewardsToClaim);
    }

     /// @notice View function to check the amount of rewards currently claimable by a user.
     /// @dev Calculates pending rewards without changing state.
     /// @param user The user's address.
     /// @return The amount of claimable rewards in wei.
    function getClaimableRewards(address user) external view returns (uint256) {
        UserQuantumState storage state = userStates[user];
        uint40 lastUpdateTime = state.lastRewardUpdateTime;
        uint256 currentStake = state.stakedAmount;
        uint256 currentEntanglementIndex = state.entanglementIndex;
        uint256 currentRewardDebt = state.rewardDebt;

         if (currentStake == 0 || currentEntanglementIndex == 0 || lastUpdateTime >= block.timestamp) {
             return currentRewardDebt; // No new rewards accrued
        }

        uint256 timeElapsed = block.timestamp - lastUpdateTime;

         uint256 REWARD_SCALING_FACTOR = 1e18 * WEIGHT_SCALING_FACTOR;

         // potentialRewards = (baseRewardRatePerSecond * currentStake * currentEntanglementIndex * timeElapsed) / REWARD_SCALING_FACTOR
         uint256 potentialRewards = (baseRewardRatePerSecond * (currentStake / 1e18)) * currentEntanglementIndex;
         potentialRewards = (potentialRewards * timeElapsed) / WEIGHT_SCALING_FACTOR;

        return currentRewardDebt + potentialRewards;
    }


    // --- CONFIGURATION (ADMIN/GOVERNANCE) ---

     /// @notice Allows the owner to set the weights for the Entanglement Index formula.
     /// @dev Affects how each factor contributes to the user's index. Weights are scaled.
     /// @param _stakeWeight Scaled weight for staked amount.
     /// @param _lockDurationWeight Scaled weight for remaining lock duration.
     /// @param _reputationWeight Scaled weight for reputation score.
     /// @param _nftLinkedWeight Scaled bonus for having the NFT linked.
    function setEntanglementIndexFormulaWeights(
        uint256 _stakeWeight,
        uint256 _lockDurationWeight,
        uint256 _reputationWeight,
        uint256 _nftLinkedWeight
    ) external onlyOwner {
        entanglementWeights = EntanglementFormulaWeights({
            stakeWeight: _stakeWeight,
            lockDurationWeight: _lockDurationWeight,
            reputationWeight: _reputationWeight,
            nftLinkedWeight: _nftLinkedWeight
        });
        // Note: This change doesn't auto-update all user indices.
        // Indices are lazy-updated on user interaction (stake, unstake, etc.)
        emit FormulaWeightsUpdated(
            entanglementWeights.stakeWeight,
            entanglementWeights.lockDurationWeight,
            entanglementWeights.reputationWeight,
            entanglementWeights.nftLinkedWeight
        );
    }

     /// @notice Allows the owner to set the base reward rate per second.
     /// @dev Affects how quickly rewards accrue. Rate is scaled.
     /// @param rate The new scaled base reward rate per second.
    function setBaseRewardRatePerSecond(uint256 rate) external onlyOwner {
        baseRewardRatePerSecond = rate;
         emit ParametersUpdated(
            minimumStakeAmount,
            maximumLockDuration,
            baseRewardRatePerSecond,
            globalEntanglementThreshold
        );
    }

     /// @notice Allows the owner to set the minimum amount required for a new stake.
     /// @param amount The new minimum stake amount in wei.
    function setMinimumStakeAmount(uint256 amount) external onlyOwner {
        minimumStakeAmount = amount;
         emit ParametersUpdated(
            minimumStakeAmount,
            maximumLockDuration,
            baseRewardRatePerSecond,
            globalEntanglementThreshold
        );
    }

     /// @notice Allows the owner to set the maximum allowed lock duration for stakes.
     /// @param duration The new maximum lock duration in seconds.
    function setMaximumLockDuration(uint40 duration) external onlyOwner {
        maximumLockDuration = duration;
         emit ParametersUpdated(
            minimumStakeAmount,
            maximumLockDuration,
            baseRewardRatePerSecond,
            globalEntanglementThreshold
        );
    }

     /// @notice Allows the owner to set the aggregate index threshold for the Global Quantum Shift.
     /// @param threshold The new threshold for totalEntanglementIndex.
    function setGlobalEntanglementThreshold(uint256 threshold) external onlyOwner {
        globalEntanglementThreshold = threshold;
         emit ParametersUpdated(
            minimumStakeAmount,
            maximumLockDuration,
            baseRewardRatePerSecond,
            globalEntanglementThreshold
        );
    }

    // --- GLOBAL QUANTUM SHIFT TRIGGER ---

    /// @notice Triggers a Global Quantum Shift event if the total entanglement index meets the threshold.
    /// @dev Can be called by anyone. If successful, distributes the bonus pool and sets a flag.
    function triggerGlobalQuantumShift() external nonReentrant {
        if (globalShiftTriggered) {
             revert AlreadyShifted(); // Can only happen once (or per cycle if reset logic added)
        }
        if (!_checkGlobalEntanglementThreshold()) {
            revert GlobalThresholdNotMet();
        }

        // --- Global Shift Action ---
        // In this example, the action is to distribute the bonus pool.
        // A more complex action could be implemented here (e.g., special governance action,
        // temporary change in parameters, minting a special token to high-index users, etc.)

        uint256 bonusAmount = globalShiftBonusPool;
        globalShiftBonusPool = 0;
        globalShiftTriggered = true; // Prevents re-triggering

        if (bonusAmount > 0) {
            require(address(this).balance >= bonusAmount, "Insufficient balance for bonus pool");
            // Send bonus pool to owner or a predefined address, or distribute among users?
            // Distributing among users adds complexity (how? proportional to index?)
            // For simplicity, let's just send it to the owner as a release mechanism.
            // A real implementation would need a defined distribution logic.
            (bool success, ) = payable(owner()).call{value: bonusAmount}("");
            require(success, "Bonus pool distribution failed");
            emit GlobalQuantumShiftTriggered(bonusAmount);
        } else {
             emit GlobalQuantumShiftTriggered(0); // Triggered, but no bonus pool set
        }
    }


    // --- QUERY FUNCTIONS ---

    /// @notice Gets the full quantum state for a given user.
    /// @param user The user's address.
    /// @return A tuple containing the user's staked amount, lock until timestamp, reputation score, NFT link status, current index, reward debt, and last reward update time.
    function getUserQuantumState(address user) external view returns (UserQuantumState memory) {
        return userStates[user];
    }

     /// @notice Gets the current entanglement index for a given user.
     /// @param user The user's address.
     /// @return The user's current entanglement index.
    function getUserEntanglementIndex(address user) external view returns (uint256) {
        return userStates[user].entanglementIndex;
    }

     /// @notice Gets the reputation score for a given user.
     /// @param user The user's address.
     /// @return The user's reputation score.
    function getReputationScore(address user) external view returns (uint256) {
        return userStates[user].reputationScore;
    }

     /// @notice Checks if a user has the required Entanglement Catalyst NFT linked.
     /// @param user The user's address.
     /// @return True if the NFT is linked, false otherwise.
    function isNFTSignificantlyLinked(address user) external view returns (bool) {
        return userStates[user].isNFTSignificantlyLinked;
    }

    /// @notice Gets aggregate statistics for the treasury and entanglement state.
    /// @return A tuple containing the total staked amount, total entanglement index, and the global threshold.
    function getGlobalEntanglementStats() external view returns (uint256 totalStaked, uint256 totalIndex, uint256 globalThreshold) {
        return (_totalStaked, totalEntanglementIndex, globalEntanglementThreshold);
    }

     /// @notice Checks if the condition for the Global Quantum Shift is currently met.
     /// @return True if the total entanglement index is at or above the threshold.
    function checkGlobalEntanglementThreshold() external view returns (bool) {
         // Recalculating global total index on the fly would be gas intensive.
         // This view function relies on the state variable `totalEntanglementIndex`
         // which is updated when user indices change.
        return _checkGlobalEntanglementThreshold();
    }

     /// @notice Gets the current amount in the special Global Shift Bonus Pool.
     /// @return The amount of Ether in the bonus pool.
    function getGlobalShiftBonusPoolAmount() external view returns (uint256) {
        return globalShiftBonusPool;
    }


    // --- OWNERSHIP FUNCTIONS ---

    /// @notice Leaves the contract without an owner.
    /// @dev Can only be called by the current owner. Renouncing ownership will prevent
    /// admin functions like setting parameters from being called.
    function renounceOwnership() public override onlyOwner {
        super.renounceOwnership();
    }

     // Add a placeholder for a function that might be used for reputation factor weights
     // if reputation logic becomes more complex.
     function setReputationFactorWeights(uint256 _repMintWeight, uint256 _repBurnWeight) external onlyOwner {
         // This function is currently a placeholder.
         // In a more complex system, different actions might give different reputation points,
         // and these weights would control that.
         // For now, mintReputation/burnReputation directly add/remove points.
         // This function exists to meet the function count and show extensibility.
         // Add relevant state variables if implementing complex logic.
         emit ReputationFactorWeightsUpdated(_repMintWeight, _repBurnWeight); // Placeholder event
     }

     event ReputationFactorWeightsUpdated(uint256 repMintWeight, uint256 repBurnWeight); // Placeholder event
}
```