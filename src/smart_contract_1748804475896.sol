Okay, here is a Solidity smart contract incorporating several advanced, creative, and trendy concepts like dynamic NFTs tied to staking duration, yield delegation, parameterized treasury management, and batch operations.

This contract, let's call it "ChronoForge," simulates a system where users stake an ERC-20 token ($TIME) linked to a specific ERC-721 NFT ("Chronicle Shard"). The longer a Shard is staked, the more it "ages," increasing its level and potentially boosting yield or unlocking other features. It also includes a treasury for collected fees and a mechanism for users to delegate the yield benefits of their staked Shard to another address.

**Concepts Covered:**

1.  **Dynamic NFTs:** ERC-721 NFTs whose attributes (level, age) change based on on-chain interactions (staking duration).
2.  **NFT-Gated Staking/Yield:** Staking an ERC-20 token is tied to owning and staking a specific NFT.
3.  **Time-Based Progression:** NFT attribute (level/age) increases based on cumulative staking time.
4.  **Tiered Benefits:** NFT level unlocks different yield rates or features. (Simulated by yield multiplier).
5.  **Yield Delegation:** Ability for a staker to grant the right to claim yield to a different address.
6.  **Parameterized Protocol:** Key rates and thresholds are configurable by the owner/governance.
7.  **Treasury Management:** Collection of fees (e.g., unstaking) into a contract-managed treasury, with controlled withdrawal.
8.  **Batch Operations:** Example function for claiming yield across multiple user assets in one transaction.
9.  **Pausable:** Standard safety mechanism to halt sensitive operations.
10. **Ownable:** Standard access control for administrative functions.

**Outline and Function Summary:**

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// Outline:
// 1. Interfaces (ERC20, ERC721)
// 2. Libraries (SafeERC20 - optional but good practice)
// 3. Imports (Ownable, Pausable from OpenZeppelin)
// 4. State Variables (Addresses, Parameters, Mappings, Structs)
// 5. Events
// 6. Structs (ShardAttributes, StakingInfo)
// 7. Modifiers
// 8. Constructor
// 9. Admin & Parameter Functions
// 10. Shard Forging (Minting) Functions
// 11. Staking Functions (ERC20 linked to ERC721)
// 12. Yield & Delegation Functions
// 13. Treasury Functions
// 14. Dynamic NFT Logic (Internal / View)
// 15. View & Query Functions

// Function Summary:
// Admin & Parameter Functions:
// 1.  constructor(address _timeToken, address _shardNFT, uint256[] memory _levelThresholds) - Initializes contract, sets token addresses, initial thresholds.
// 2.  transferOwnership(address newOwner) - Transfers contract ownership (Ownable).
// 3.  renounceOwnership() - Renounces contract ownership (Ownable).
// 4.  pause() - Pauses protocol operations (Pausable).
// 5.  unpause() - Unpauses protocol operations (Pausable).
// 6.  setYieldRate(uint256 _newRate) - Sets the base yield rate (per second per token).
// 7.  setLevelThresholds(uint256[] memory _newThresholds) - Sets total staked duration needed for each Shard level.
// 8.  setForgingFee(uint256 _newFee) - Sets the TIME token fee to forge a new Shard.
// 9.  setUnstakingFeeRate(uint256 _newRate) - Sets the percentage fee applied to unstaked amount.
// 10. setCooldownDuration(uint48 _newDuration) - Sets the unstaking cooldown period.

// Shard Forging (Minting) Functions:
// 11. forgeShard() - Allows a user to mint a new Chronicle Shard NFT by paying a TIME fee.

// Staking Functions:
// 12. stakeTIME(uint256 shardId, uint256 amount) - Stakes a specified amount of TIME token linked to a specific Shard NFT. Requires Shard ownership and ERC20 approval.
// 13. unstakeTIME(uint256 shardId) - Unstakes TIME token associated with a Shard after a cooldown period. Calculates and applies unstaking fee.
// 14. emergencyUnstake(uint256 shardId) - Allows unstaking immediately, bypassing cooldown but potentially with a higher penalty (conceptually, not fully implemented complex penalty).

// Yield & Delegation Functions:
// 15. calculatePendingYield(uint256 shardId) - View function to calculate yield accrued for a specific Shard stake.
// 16. claimYield(uint256 shardId) - Claims accrued yield for a specific Shard stake (caller must be owner or delegate).
// 17. batchClaimYield(uint256[] memory shardIds) - Claims yield for multiple Shards in one transaction.
// 18. delegateShardBenefit(uint256 shardId, address delegatee) - Delegates the right to claim yield for a Shard to another address.
// 19. revokeShardBenefitDelegation(uint256 shardId) - Revokes yield delegation for a Shard.

// Treasury Functions:
// 20. depositToTreasury(uint256 amount) - Allows depositing TIME tokens directly into the contract's treasury.
// 21. withdrawFromTreasury(address recipient, uint256 amount) - Allows owner/governance to withdraw TIME from the treasury.

// Dynamic NFT Logic (Internal / View):
// 22. _updateShardStakedDuration(uint256 shardId) - Internal function to update a Shard's total staked duration.
// 23. getShardLevel(uint256 shardId) - View function to get the current level of a Shard based on its total staked duration.
// 24. _calculateShardYieldMultiplier(uint256 shardId) - Internal/View helper to get yield boost based on level. (Conceptual, simple example)

// View & Query Functions:
// 25. getShardAttributes(uint256 shardId) - View function to get all dynamic attributes of a Shard.
// 26. getStakingInfo(uint256 shardId) - View function to get staking details for a Shard.
// 27. getYieldRate() - View function for current base yield rate.
// 28. getLevelThresholds() - View function for current level thresholds.
// 29. getForgingFee() - View function for current forging fee.
// 30. getUnstakingFeeRate() - View function for current unstaking fee rate.
// 31. getCooldownDuration() - View function for unstaking cooldown duration.
// 32. getCooldownEndTime(uint256 shardId) - View function for the unstaking cooldown end time for a specific Shard.
// 33. getTreasuryBalance() - View function for the contract's TIME balance.
// 34. getTokenAddresses() - View function for addresses of TIME and Shard contracts.
// 35. isShardStaked(uint256 shardId) - View function to check if a Shard is currently staked.
// 36. getShardBenefitDelegatee(uint256 shardId) - View function to get the address delegated to claim yield for a Shard.

```

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol"; // Good practice for ERC20 interactions

contract ChronoForgeProtocol is Ownable, Pausable {
    using SafeERC20 for IERC20;

    // --- State Variables ---

    IERC20 public immutable timeToken;
    IERC721 public immutable shardNFT;

    uint256 public yieldRatePerSecondPerToken; // Yield rate (e.g., 1e18 for 1 token yield per token staked per second, scaled by decimals)
    uint265[] private levelThresholds; // Total cumulative staked duration (seconds) required for each level
    uint256 public forgingFee; // Fee in TIME tokens to forge a new Shard
    uint256 public unstakingFeeRate; // Percentage fee (scaled by 10000, e.g., 100 = 1%) on unstaked amount
    uint48 public cooldownDuration; // Duration in seconds for unstaking cooldown

    struct ShardAttributes {
        uint256 creationTime; // Timestamp when the Shard was forged
        uint265 totalStakeDuration; // Cumulative seconds this Shard has been actively staked
        uint256 lastStakeStartTime; // Timestamp when the current stake period began (0 if not staked)
        address currentStaker; // Address currently staking this Shard (address(0) if not staked)
    }

    struct StakingInfo {
        uint256 stakedAmount; // Amount of TIME staked
        uint256 yieldClaimedAmount; // Total yield claimed for this stake (conceptual tracking, not strict per period)
        uint48 lastYieldClaimTime; // Timestamp of the last yield claim
        uint48 cooldownEndTime; // Timestamp when unstaking cooldown ends
    }

    mapping(uint256 => ShardAttributes) public shardAttributes; // shardId => attributes
    mapping(uint256 => StakingInfo) public stakingInfo; // shardId => staking details
    mapping(uint256 => address) private shardBenefitDelegates; // shardId => address allowed to claim yield

    // Keep track of total staked amount for overall protocol metrics
    uint256 private _totalStakedTIME;

    // --- Events ---

    event ShardForged(uint256 indexed shardId, address indexed owner, uint256 feePaid);
    event Staked(uint256 indexed shardId, address indexed staker, uint256 amount, uint256 currentTotalStaked);
    event Unstaked(uint256 indexed shardId, address indexed staker, uint256 amount, uint256 feePaid, uint256 currentTotalStaked);
    event YieldClaimed(uint256 indexed shardId, address indexed claimant, uint256 amount);
    event ShardBenefitDelegated(uint256 indexed shardId, address indexed delegator, address indexed delegatee);
    event ShardBenefitDelegationRevoked(uint256 indexed shardId, address indexed delegator);
    event TreasuryDeposit(address indexed sender, uint256 amount);
    event TreasuryWithdrawal(address indexed recipient, uint256 amount);
    event ParameterSet(string parameterName, uint256 value); // Generic event for parameter changes
    event LevelThresholdsSet(uint256[] thresholds);
    event CooldownStarted(uint256 indexed shardId, uint48 endTime);

    // --- Structs (Defined above with state variables for clarity) ---

    // --- Modifiers ---

    modifier whenShardExists(uint256 shardId) {
        require(shardAttributes[shardId].creationTime > 0, "CF: Shard does not exist");
        _;
    }

    // --- Constructor ---

    constructor(address _timeToken, address _shardNFT, uint265[] memory _levelThresholds)
        Ownable(msg.sender)
        Pausable()
    {
        require(_timeToken != address(0), "CF: Invalid TIME token address");
        require(_shardNFT != address(0), "CF: Invalid Shard NFT address");
        require(_levelThresholds.length > 0, "CF: Level thresholds cannot be empty");

        timeToken = IERC20(_timeToken);
        shardNFT = IERC721(_shardNFT);
        levelThresholds = _levelThresholds;

        // Set initial parameters (can be 0, admin sets later)
        yieldRatePerSecondPerToken = 0;
        forgingFee = 0;
        unstakingFeeRate = 0;
        cooldownDuration = 0;
    }

    // --- Admin & Parameter Functions ---

    // Ownable provides transferOwnership and renounceOwnership
    // Pausable provides pause and unpause

    /// @notice Sets the base yield rate per second per token staked.
    /// @param _newRate The new base rate (scaled by TIME token decimals).
    function setYieldRate(uint256 _newRate) public onlyOwner whenNotPaused {
        yieldRatePerSecondPerToken = _newRate;
        emit ParameterSet("YieldRatePerSecondPerToken", _newRate);
    }

    /// @notice Sets the cumulative staked duration thresholds for different Shard levels.
    /// @param _newThresholds An array of durations in seconds. Index i corresponds to the threshold for level i+1.
    function setLevelThresholds(uint265[] memory _newThresholds) public onlyOwner whenNotPaused {
        require(_newThresholds.length > 0, "CF: Level thresholds cannot be empty");
        levelThresholds = _newThresholds;
        emit LevelThresholdsSet(_newThresholds);
    }

    /// @notice Sets the fee in TIME token required to forge a new Shard.
    /// @param _newFee The new forging fee.
    function setForgingFee(uint256 _newFee) public onlyOwner whenNotPaused {
        forgingFee = _newFee;
        emit ParameterSet("ForgingFee", _newFee);
    }

    /// @notice Sets the percentage fee applied to unstaked amount, transferred to the treasury.
    /// @param _newRate The new unstaking fee rate, scaled by 10000 (e.g., 100 = 1%). Max 10000 (100%).
    function setUnstakingFeeRate(uint256 _newRate) public onlyOwner whenNotPaused {
        require(_newRate <= 10000, "CF: Unstaking fee rate cannot exceed 100%");
        unstakingFeeRate = _newRate;
        emit ParameterSet("UnstakingFeeRate", _newRate);
    }

    /// @notice Sets the duration of the unstaking cooldown period in seconds.
    /// @param _newDuration The new cooldown duration.
    function setCooldownDuration(uint48 _newDuration) public onlyOwner whenNotPaused {
        cooldownDuration = _newDuration;
        emit ParameterSet("CooldownDuration", _newDuration);
    }

    // --- Shard Forging (Minting) Functions ---

    /// @notice Allows the caller to forge a new Chronicle Shard NFT by paying the forging fee in TIME.
    /// @dev Requires approval for the forgingFee amount of TIME token from the caller.
    function forgeShard() public whenNotPaused {
        uint256 fee = forgingFee;
        require(fee > 0, "CF: Forging fee is not set or is zero");

        // Transfer fee to this contract (treasury)
        timeToken.safeTransferFrom(msg.sender, address(this), fee);
        emit TreasuryDeposit(msg.sender, fee);

        // Mint a new Shard NFT to the caller.
        // Assumes the Shard NFT contract has a minting function callable by this protocol contract.
        // In a real scenario, the Shard NFT contract would likely have an `onlyMinter` role,
        // and this contract's address would be granted that role.
        // For this example, we'll simulate the call. A real implementation needs an interface
        // or specific contract type for the Shard NFT with a mint function like `mint(address to)`.
        // Assuming IERC721 has an extension or a custom interface allows minting.
        // Let's assume a simple `mint(address to)` function exists on the NFT contract for simplicity here.
        // NOTE: Standard IERC721 does NOT have a public mint function. This is a simplification
        // for the example. A real NFT contract would be designed to allow minting by specific addresses.
        // Let's simulate the minting using a placeholder function call.
        // uint256 newShardId = shardNFT.mint(msg.sender); // Placeholder call

        // --- Simulation: We don't have a mintable IERC721 here. ---
        // In a real scenario, you'd call shardNFT.mint(msg.sender) which returns the new ID.
        // For this example, let's use a simple counter for shardIds for simulation purposes.
        // This means this contract is the de facto minter and state manager,
        // but in reality, the Shard NFT state (like ownership) would be in the IERC721 contract.
        // We will use a simple counter `_nextShardId` for this example's internal state management
        // related to `shardAttributes`, but acknowledge true ownership is external.

        uint256 newShardId = _nextShardId++;
        shardAttributes[newShardId] = ShardAttributes({
            creationTime: block.timestamp,
            totalStakeDuration: 0,
            lastStakeStartTime: 0,
            currentStaker: address(0)
        });
        // In a real system, you would also call shardNFT.mint(msg.sender) here.

        emit ShardForged(newShardId, msg.sender, fee);
    }

    uint256 private _nextShardId = 1; // Simulation counter for Shard IDs

    // --- Staking Functions ---

    /// @notice Stakes a specified amount of TIME token, linking it to a specific Chronicle Shard.
    /// @dev Requires the caller to own the Shard and approve this contract for the TIME amount.
    /// @param shardId The ID of the Chronicle Shard NFT to link the stake to.
    /// @param amount The amount of TIME token to stake.
    function stakeTIME(uint256 shardId, uint256 amount) public whenNotPaused whenShardExists(shardId) {
        require(amount > 0, "CF: Amount must be greater than zero");
        require(shardNFT.ownerOf(shardId) == msg.sender, "CF: Caller must own the Shard NFT");
        require(shardAttributes[shardId].currentStaker == address(0), "CF: Shard is already staked");

        // Transfer TIME tokens from the user to the contract
        timeToken.safeTransferFrom(msg.sender, address(this), amount);

        // Update Shard attributes and staking info
        ShardAttributes storage sAttrs = shardAttributes[shardId];
        StakingInfo storage sInfo = stakingInfo[shardId];

        // Add duration from previous stake period if any
        _updateShardStakedDuration(shardId); // Adds time from previous stake if it was active

        sAttrs.lastStakeStartTime = block.timestamp;
        sAttrs.currentStaker = msg.sender;

        sInfo.stakedAmount = amount;
        sInfo.lastYieldClaimTime = uint48(block.timestamp); // Reset claim time on new stake
        // stakingInfo.yieldClaimedAmount is cumulative per stake, so it persists or resets based on design.
        // Let's reset it for a new stake for simplicity here.
        sInfo.yieldClaimedAmount = 0;
        sInfo.cooldownEndTime = 0; // Clear any old cooldown

        _totalStakedTIME += amount;

        emit Staked(shardId, msg.sender, amount, _totalStakedTIME);
    }

    /// @notice Unstakes the TIME token associated with a Shard after the cooldown period.
    /// @dev Caller must be the current staker and cooldown must be over.
    /// @param shardId The ID of the staked Shard NFT.
    function unstakeTIME(uint256 shardId) public whenNotPaused whenShardExists(shardId) {
        ShardAttributes storage sAttrs = shardAttributes[shardId];
        StakingInfo storage sInfo = stakingInfo[shardId];

        require(sAttrs.currentStaker == msg.sender, "CF: Caller is not the current staker");
        require(sInfo.stakedAmount > 0, "CF: No active stake for this Shard");
        require(block.timestamp >= sInfo.cooldownEndTime, "CF: Unstaking is under cooldown");

        // Ensure all pending yield is claimed before unstaking
        uint256 pendingYield = calculatePendingYield(shardId);
        if (pendingYield > 0) {
            _claimYieldInternal(shardId, sAttrs.currentStaker, pendingYield);
        }

        uint256 amountToUnstake = sInfo.stakedAmount;
        uint256 feeAmount = (amountToUnstake * unstakingFeeRate) / 10000;
        uint256 amountAfterFee = amountToUnstake - feeAmount;

        // Transfer unstaked amount back to user
        timeToken.safeTransfer(msg.sender, amountAfterFee);

        // Transfer fee to treasury
        if (feeAmount > 0) {
             timeToken.safeTransfer(address(this), feeAmount);
             emit TreasuryDeposit(address(this), feeAmount); // Treasury gets fee
        }

        // Finalize staked duration calculation
        _updateShardStakedDuration(shardId);

        // Reset staking info
        _totalStakedTIME -= sInfo.stakedAmount;
        delete stakingInfo[shardId]; // Clear the stake info for this shard
        sAttrs.lastStakeStartTime = 0; // Mark as not staked
        sAttrs.currentStaker = address(0); // Clear staker

        // Clear delegation upon unstake
        delete shardBenefitDelegates[shardId];
        emit ShardBenefitDelegationRevoked(shardId, msg.sender);


        emit Unstaked(shardId, msg.sender, amountToUnstake, feeAmount, _totalStakedTIME);
    }

    /// @notice Initiates the unstaking cooldown period for a staked Shard.
    /// @dev Caller must be the current staker. Cannot be called if already in cooldown or not staked.
    /// @param shardId The ID of the staked Shard NFT.
    function startUnstakingCooldown(uint256 shardId) public whenNotPaused whenShardExists(shardId) {
         ShardAttributes storage sAttrs = shardAttributes[shardId];
         StakingInfo storage sInfo = stakingInfo[shardId];

         require(sAttrs.currentStaker == msg.sender, "CF: Caller is not the current staker");
         require(sInfo.stakedAmount > 0, "CF: No active stake for this Shard");
         require(sInfo.cooldownEndTime == 0 || block.timestamp > sInfo.cooldownEndTime, "CF: Already in or finished cooldown");
         require(cooldownDuration > 0, "CF: Cooldown duration is zero");

         sInfo.cooldownEndTime = uint48(block.timestamp + cooldownDuration);
         emit CooldownStarted(shardId, sInfo.cooldownEndTime);
    }


     /// @notice Allows unstaking immediately, bypassing the standard cooldown. May have a higher penalty (feature not fully implemented, assumes standard penalty for this example).
     /// @dev Use with caution. Caller must be the current staker.
     /// @param shardId The ID of the staked Shard NFT.
    function emergencyUnstake(uint256 shardId) public whenNotPaused whenShardExists(shardId) {
        ShardAttributes storage sAttrs = shardAttributes[shardId];
        StakingInfo storage sInfo = stakingInfo[shardId];

        require(sAttrs.currentStaker == msg.sender, "CF: Caller is not the current staker");
        require(sInfo.stakedAmount > 0, "CF: No active stake for this Shard");

        // Emergency unstake bypasses cooldown. Penalty logic could be different here,
        // but for simplicity, we apply the standard fee.
        // A more advanced version could apply a higher fee or burn a portion.

        // Ensure all pending yield is claimed before unstaking
        uint256 pendingYield = calculatePendingYield(shardId);
        if (pendingYield > 0) {
            _claimYieldInternal(shardId, sAttrs.currentStaker, pendingYield);
        }

        uint256 amountToUnstake = sInfo.stakedAmount;
        uint256 feeAmount = (amountToUnstake * unstakingFeeRate) / 10000; // Use standard fee rate
        uint256 amountAfterFee = amountToUnstake - feeAmount;

        // Transfer unstaked amount back to user
        timeToken.safeTransfer(msg.sender, amountAfterFee);

         // Transfer fee to treasury
        if (feeAmount > 0) {
             timeToken.safeTransfer(address(this), feeAmount);
             emit TreasuryDeposit(address(this), feeAmount); // Treasury gets fee
        }

        // Finalize staked duration calculation
        _updateShardStakedDuration(shardId);

        // Reset staking info
        _totalStakedTIME -= sInfo.stakedAmount;
        delete stakingInfo[shardId]; // Clear the stake info for this shard
        sAttrs.lastStakeStartTime = 0; // Mark as not staked
        sAttrs.currentStaker = address(0); // Clear staker

        // Clear delegation upon unstake
        delete shardBenefitDelegates[shardId];
        emit ShardBenefitDelegationRevoked(shardId, msg.sender);

        emit Unstaked(shardId, msg.sender, amountToUnstake, feeAmount, _totalStakedTIME);
    }


    // --- Yield & Delegation Functions ---

    /// @notice Calculates the pending yield for a specific Shard's stake.
    /// @param shardId The ID of the Shard.
    /// @return The calculated yield amount.
    function calculatePendingYield(uint256 shardId) public view whenShardExists(shardId) returns (uint256) {
        StakingInfo storage sInfo = stakingInfo[shardId];
        ShardAttributes storage sAttrs = shardAttributes[shardId];

        if (sInfo.stakedAmount == 0 || sAttrs.lastStakeStartTime == 0) {
            return 0; // Not currently staked
        }

        uint256 lastClaim = sInfo.lastYieldClaimTime;
        uint256 currentTime = block.timestamp;

        // If current time is before last claim (shouldn't happen normally, but handle potential reorgs or clock issues)
        if (currentTime <= lastClaim) {
            return 0;
        }

        uint256 duration = currentTime - lastClaim;

        // Calculate yield based on staked amount, duration, base rate, and Shard level multiplier
        uint256 baseYield = (sInfo.stakedAmount * yieldRatePerSecondPerToken * duration) / 1e18; // Assuming TIME uses 18 decimals for rate scaling

        // Apply Shard level multiplier (simple example: level 0 = 1x, level 1 = 1.1x, level 2 = 1.2x etc.)
        uint256 shardLevel = getShardLevel(shardId);
        uint256 yieldMultiplier = 100 + (shardLevel * 10); // e.g. 100 for level 0, 110 for level 1, 120 for level 2 (scaled by 100)
        uint256 finalYield = (baseYield * yieldMultiplier) / 100; // Apply multiplier

        // NOTE: This calculation is simplified. Real yield farming can be more complex.
        // Potential issues: Yield calculation overflow, precision with decimals.
        // Using 0.8.20 helps with overflow checks by default. Scaled rates handle precision.

        return finalYield;
    }

    /// @notice Claims the accrued yield for a specific Shard stake.
    /// @dev Callable by the Shard owner or a delegated address.
    /// @param shardId The ID of the Shard.
    function claimYield(uint256 shardId) public whenNotPaused whenShardExists(shardId) {
        address owner = shardNFT.ownerOf(shardId); // Get current owner
        address delegatee = shardBenefitDelegates[shardId];
        address claimant = msg.sender;

        require(owner == claimant || delegatee == claimant, "CF: Caller is not Shard owner or delegatee");

        uint256 amount = calculatePendingYield(shardId);
        require(amount > 0, "CF: No yield to claim");

        _claimYieldInternal(shardId, claimant, amount);
    }

    /// @notice Internal function to handle the actual yield transfer and state update.
    /// @param shardId The ID of the Shard.
    /// @param recipient The address to send the yield to (owner or delegatee).
    /// @param amount The amount of yield to claim.
    function _claimYieldInternal(uint256 shardId, address recipient, uint256 amount) internal {
        StakingInfo storage sInfo = stakingInfo[shardId];

        // Transfer yield amount
        timeToken.safeTransfer(recipient, amount);

        // Update staking info
        sInfo.yieldClaimedAmount += amount; // Track total claimed per stake
        sInfo.lastYieldClaimTime = uint48(block.timestamp); // Reset claim timer

        emit YieldClaimed(shardId, recipient, amount);
    }


    /// @notice Claims accrued yield for multiple Shard stakes in a single transaction.
    /// @dev Caller must be the owner or delegatee for each respective Shard.
    /// @param shardIds An array of Shard IDs to claim yield for.
    function batchClaimYield(uint256[] memory shardIds) public whenNotPaused {
        for (uint i = 0; i < shardIds.length; i++) {
            uint256 shardId = shardIds[i];
            // Perform the same checks as single claimYield but handle potential failures gracefully or revert on any fail.
            // Reverting on first fail is safer for atomic operations.
             require(shardAttributes[shardId].creationTime > 0, "CF: Shard does not exist"); // WhenShardExists check
             address owner = shardNFT.ownerOf(shardId); // Get current owner
             address delegatee = shardBenefitDelegates[shardId];
             address claimant = msg.sender;

             require(owner == claimant || delegatee == claimant, "CF: Caller is not owner or delegatee for shard"); // Auth check

             uint256 amount = calculatePendingYield(shardId);
             if (amount > 0) {
                 _claimYieldInternal(shardId, claimant, amount);
             }
             // Note: Does not revert if amount is 0 for a shard, just skips.
        }
    }


    /// @notice Delegates the right to claim yield for a specific Shard to another address.
    /// @dev Only the current Shard owner can delegate.
    /// @param shardId The ID of the Shard.
    /// @param delegatee The address to delegate the claim right to. Set to address(0) to revoke.
    function delegateShardBenefit(uint256 shardId, address delegatee) public whenNotPaused whenShardExists(shardId) {
        require(shardNFT.ownerOf(shardId) == msg.sender, "CF: Caller must own the Shard NFT to delegate");
        require(delegatee != msg.sender, "CF: Cannot delegate benefit to self");

        shardBenefitDelegates[shardId] = delegatee;

        if (delegatee == address(0)) {
             emit ShardBenefitDelegationRevoked(shardId, msg.sender);
        } else {
             emit ShardBenefitDelegated(shardId, msg.sender, delegatee);
        }
    }

    /// @notice Revokes any existing yield delegation for a specific Shard.
    /// @dev Only the current Shard owner or the current delegatee can revoke.
    /// @param shardId The ID of the Shard.
    function revokeShardBenefitDelegation(uint256 shardId) public whenNotPaused whenShardExists(shardId) {
        address owner = shardNFT.ownerOf(shardId);
        address currentDelegatee = shardBenefitDelegates[shardId];

        require(owner == msg.sender || currentDelegatee == msg.sender, "CF: Caller is not Shard owner or current delegatee");
        require(currentDelegatee != address(0), "CF: No active delegation to revoke");

        delete shardBenefitDelegates[shardId];
        emit ShardBenefitDelegationRevoked(shardId, owner); // Emit with owner as delegator
    }

    // --- Treasury Functions ---

    /// @notice Allows any address to deposit TIME tokens into the contract's treasury.
    /// @dev Requires prior approval of the amount by the sender.
    /// @param amount The amount of TIME token to deposit.
    function depositToTreasury(uint256 amount) public whenNotPaused {
        require(amount > 0, "CF: Amount must be greater than zero");
        timeToken.safeTransferFrom(msg.sender, address(this), amount);
        emit TreasuryDeposit(msg.sender, amount);
    }

    /// @notice Allows the contract owner (or potentially a governance mechanism) to withdraw TIME from the treasury.
    /// @param recipient The address to send the funds to.
    /// @param amount The amount of TIME token to withdraw.
    function withdrawFromTreasury(address recipient, uint256 amount) public onlyOwner whenNotPaused {
        require(amount > 0, "CF: Amount must be greater than zero");
        require(recipient != address(0), "CF: Invalid recipient address");
        require(timeToken.balanceOf(address(this)) >= amount, "CF: Insufficient treasury balance");

        timeToken.safeTransfer(recipient, amount);
        emit TreasuryWithdrawal(recipient, amount);
    }

    // --- Dynamic NFT Logic (Internal / View) ---

    /// @notice Internal function to update the total staked duration of a Shard.
    /// @dev Called when a stake period ends (unstake, emergency unstake, new stake).
    /// @param shardId The ID of the Shard.
    function _updateShardStakedDuration(uint256 shardId) internal {
        ShardAttributes storage sAttrs = shardAttributes[shardId];

        // Check if the shard was actively staked
        if (sAttrs.lastStakeStartTime > 0) {
            uint256 stakeDuration = block.timestamp - sAttrs.lastStakeStartTime;
            sAttrs.totalStakeDuration += uint265(stakeDuration); // Add duration to cumulative
            // lastStakeStartTime is reset to 0 or new time in calling function (stake/unstake)
        }
    }

     /// @notice Calculates the level of a Shard based on its total cumulative staked duration.
     /// @param shardId The ID of the Shard.
     /// @return The level of the Shard (0 for base level).
    function getShardLevel(uint256 shardId) public view whenShardExists(shardId) returns (uint256) {
        uint265 duration = shardAttributes[shardId].totalStakeDuration;
        if (shardAttributes[shardId].lastStakeStartTime > 0) {
             // Add current stake duration if actively staked
             duration += uint265(block.timestamp - shardAttributes[shardId].lastStakeStartTime);
        }

        uint256 currentLevel = 0;
        for (uint i = 0; i < levelThresholds.length; i++) {
            if (duration >= levelThresholds[i]) {
                currentLevel = i + 1; // Level i+1 achieved if duration meets threshold i
            } else {
                break; // Durations are assumed to be increasing
            }
        }
        return currentLevel;
    }

    /// @notice Internal helper to calculate the yield multiplier based on Shard level.
    /// @param shardId The ID of the Shard.
    /// @return The yield multiplier (scaled by 100).
    function _calculateShardYieldMultiplier(uint256 shardId) internal view returns (uint256) {
         uint256 shardLevel = getShardLevel(shardId);
         // Simple linear multiplier: Level 0 = 100%, Level 1 = 110%, Level 2 = 120%, etc.
         return 100 + (shardLevel * 10);
    }


    // --- View & Query Functions ---

    /// @notice Gets the current attributes of a Chronicle Shard.
    /// @param shardId The ID of the Shard.
    /// @return creationTime The timestamp the Shard was forged.
    /// @return totalStakeDuration Cumulative time in seconds the Shard has been staked across all periods.
    /// @return lastStakeStartTime Timestamp the current stake period began (0 if not staked).
    /// @return currentStaker The address currently staking this Shard (address(0) if not staked).
    function getShardAttributes(uint256 shardId) public view whenShardExists(shardId)
        returns (uint256 creationTime, uint265 totalStakeDuration, uint256 lastStakeStartTime, address currentStaker)
    {
        ShardAttributes storage sAttrs = shardAttributes[shardId];
        return (sAttrs.creationTime, sAttrs.totalStakeDuration, sAttrs.lastStakeStartTime, sAttrs.currentStaker);
    }

    /// @notice Gets the current total "age" of a Shard, which is its cumulative staked duration in seconds.
    /// @param shardId The ID of the Shard.
    /// @return The total staked duration in seconds.
    function getShardAge(uint256 shardId) public view whenShardExists(shardId) returns (uint256) {
        uint265 duration = shardAttributes[shardId].totalStakeDuration;
         if (shardAttributes[shardId].lastStakeStartTime > 0) {
             // Include duration of the current active stake
             duration += uint265(block.timestamp - shardAttributes[shardId].lastStakeStartTime);
        }
        return duration;
    }


    /// @notice Gets the current staking information for a Shard.
    /// @param shardId The ID of the Shard.
    /// @return stakedAmount The amount of TIME staked.
    /// @return yieldClaimedAmount Total yield claimed for the current stake period.
    /// @return lastYieldClaimTime Timestamp of the last yield claim.
    /// @return cooldownEndTime Timestamp when the unstaking cooldown ends (0 if no cooldown active).
    function getStakingInfo(uint256 shardId) public view whenShardExists(shardId)
        returns (uint256 stakedAmount, uint256 yieldClaimedAmount, uint48 lastYieldClaimTime, uint48 cooldownEndTime)
    {
         StakingInfo storage sInfo = stakingInfo[shardId];
         return (sInfo.stakedAmount, sInfo.yieldClaimedAmount, sInfo.lastYieldClaimTime, sInfo.cooldownEndTime);
    }

    /// @notice Gets the current base yield rate.
    function getYieldRate() public view returns (uint256) {
        return yieldRatePerSecondPerToken;
    }

    /// @notice Gets the current level thresholds.
    function getLevelThresholds() public view returns (uint256[] memory) {
        return levelThresholds;
    }

    /// @notice Gets the current forging fee in TIME token.
    function getForgingFee() public view returns (uint256) {
        return forgingFee;
    }

    /// @notice Gets the current unstaking fee rate (scaled by 10000).
    function getUnstakingFeeRate() public view returns (uint256) {
        return unstakingFeeRate;
    }

    /// @notice Gets the current unstaking cooldown duration in seconds.
    function getCooldownDuration() public view returns (uint48) {
        return cooldownDuration;
    }

    /// @notice Gets the end timestamp of the unstaking cooldown for a specific Shard.
    /// @param shardId The ID of the Shard.
    /// @return The timestamp when cooldown ends (0 if no cooldown active).
    function getCooldownEndTime(uint256 shardId) public view whenShardExists(shardId) returns (uint48) {
        return stakingInfo[shardId].cooldownEndTime;
    }

    /// @notice Gets the current TIME token balance held by the contract (treasury).
    function getTreasuryBalance() public view returns (uint256) {
        return timeToken.balanceOf(address(this));
    }

    /// @notice Gets the addresses of the associated TIME token and Shard NFT contracts.
    function getTokenAddresses() public view returns (address timeTokenAddress, address shardNFTAddress) {
        return (address(timeToken), address(shardNFT));
    }

    /// @notice Checks if a specific Shard is currently staked.
    /// @param shardId The ID of the Shard.
    /// @return True if the Shard is currently staked, false otherwise.
    function isShardStaked(uint256 shardId) public view whenShardExists(shardId) returns (bool) {
        return shardAttributes[shardId].currentStaker != address(0);
    }

    /// @notice Gets the address currently delegated to claim yield for a Shard.
    /// @param shardId The ID of the Shard.
    /// @return The delegatee address (address(0) if no delegation).
    function getShardBenefitDelegatee(uint256 shardId) public view whenShardExists(shardId) returns (address) {
        return shardBenefitDelegates[shardId];
    }

    /// @notice Gets the total amount of TIME currently staked across all Shards in the protocol.
    function getTotalStakedTIME() public view returns (uint256) {
        return _totalStakedTIME;
    }

     // Note: Getting all Shard IDs owned by a user or all staked Shard IDs requires iterating
     // over the ERC721 or mapping state, which is not gas-efficient in Solidity.
     // This is typically handled off-chain by indexing events.
     // Adding a function like `getUserStakedShardIds` would involve a loop
     // and could hit gas limits quickly for users with many staked shards.
     // We omit it here to keep the contract practical for deployment.
     // If needed, a mapping like `mapping(address => uint256[]) userStakedShardIdsList`
     // could be maintained, adding complexity on stake/unstake.
}
```