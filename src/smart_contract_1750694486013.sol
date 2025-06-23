Okay, let's design a sophisticated and creative smart contract called "QuantumLeapProtocol". This protocol will involve staking a native ERC-20 token ("ChronoToken"), receiving a dynamic ERC-721 NFT ("TemporalShard") representing the staked position and accumulated yield, and using another type of NFT ("DimensionKey") to unlock yield boosts and features. It will also include mechanics like merging/splitting staked positions (represented by NFTs) and a simulated external "Temporal Flux" factor affecting yield.

This combines concepts like:
*   Staking with ERC-721 representation
*   Dynamic NFTs (metadata changes based on state)
*   Layered access/utility NFTs (DimensionKeys)
*   Complex state transitions (merging/splitting NFTs representing staked positions)
*   Simulated external factor influence (Temporal Flux)
*   Yield calculation mechanics
*   Basic owner/governance controls

It avoids direct duplication of standard DeFi protocols (lending, AMM, simple staking) or NFT marketplaces, focusing on a novel combination of mechanics centered around staked position NFTs.

---

**QuantumLeapProtocol Smart Contract**

**Outline:**

1.  **Pragma & Imports:** Specify Solidity version and necessary interfaces (ERC20, ERC721, Ownable).
2.  **Errors:** Custom errors for specific failure conditions.
3.  **Events:** Define events for core actions (stake, unstake, claim, merge, split, key application, parameter changes).
4.  **State Variables:** Store protocol configuration, user data (staked amounts, timestamps), NFT data (linked keys), counters, pausable states, fee information, temporal flux state.
5.  **Structs:** Define structures to hold data for `TemporalShard` NFTs.
6.  **Interfaces:** (Optional, but good practice if interacting with external contracts like ChronoToken and DimensionKey if they were separate contracts deployed elsewhere. For this example, we might simulate them or assume they are standard implementations).
7.  **Libraries:** (None strictly needed for this logic in modern Solidity).
8.  **Owner/Access Control:** Use `Ownable` for administrative functions.
9.  **Pausable:** Mechanism to pause critical actions.
10. **TemporalShard Logic (ERC721):** Implement ERC721 standard functions, override `tokenURI` to provide dynamic metadata based on shard state.
11. **DimensionKey Logic (ERC721):** Implement ERC721 standard functions for DimensionKeys (simulated or assumed external).
12. **Core Protocol Logic:**
    *   Staking (`stake`)
    *   Unstaking (`unstake`)
    *   Yield Calculation (`getAccumulatedYield`, internal helper)
    *   Yield Claiming (`claimYield`)
    *   Temporal Shard Management (`mergeTemporalShards`, `splitTemporalShard`)
    *   Dimension Key Interaction (`applyDimensionKey`, `removeDimensionKey`, `mintDimensionKey` - governed eligibility)
    *   Temporal Flux Mechanism (`getTemporalFluxRate`, `updateTemporalFluxRate` - simulated)
13. **Parameter Governance/Owner Functions:** Functions for the owner to set yield rates, boost amounts, minimums, fees, eligibility, and pause states.
14. **View Functions:** Functions to query contract state, user stakes, shard properties, etc.

**Function Summary (Total > 20):**

*   **Core Staking/Yield:**
    1.  `stake(uint256 amount)`: Allows users to stake `ChronoToken` and receive a new `TemporalShard` NFT representing the staked position.
    2.  `unstake(uint256 shardId)`: Allows the owner of a `TemporalShard` to unstake the associated `ChronoToken` amount and burn the shard. Includes yield calculation and distribution.
    3.  `claimYield(uint256 shardId)`: Allows the owner of a `TemporalShard` to claim the accumulated yield for that specific shard without unstaking the principal.
    4.  `getAccumulatedYield(uint256 shardId) view`: Calculates and returns the yield accumulated for a specific shard since the last action (stake, claim, merge, split).
    5.  `getStakedAmount(uint256 shardId) view`: Returns the amount of `ChronoToken` staked within a specific `TemporalShard`.

*   **Temporal Shard Management:**
    6.  `mergeTemporalShards(uint256[] calldata shardIds)`: Allows a user to merge multiple `TemporalShard` NFTs they own into a single new shard, combining their staked amounts. Yield is auto-claimed before merging.
    7.  `splitTemporalShard(uint256 shardId, uint256[] calldata amounts)`: Allows a user to split a single `TemporalShard` into multiple new shards with specified stake amounts (summing to the original). Yield is auto-claimed before splitting.
    8.  `getShardProperties(uint256 shardId) view`: Returns key properties of a `TemporalShard` (staked amount, stake timestamp, linked key ID).
    9.  `tokenURI(uint256 shardId) override view`: ERC721 standard function overridden to generate dynamic metadata URL based on the shard's state (`getShardProperties`).

*   **Dimension Key Interaction:**
    10. `mintDimensionKey()`: Allows users who meet certain criteria (e.g., owner-whitelisted) to mint a `DimensionKey` NFT.
    11. `applyDimensionKey(uint256 shardId, uint256 keyId)`: Allows a user to link a `DimensionKey` they own to a `TemporalShard` they own, applying a yield boost to that shard.
    12. `removeDimensionKey(uint256 shardId)`: Allows a user to unlink a `DimensionKey` from a `TemporalShard`, removing the yield boost. The key becomes available to be linked elsewhere.
    13. `getLinkedDimensionKey(uint256 shardId) view`: Returns the ID of the `DimensionKey` currently linked to a `TemporalShard` (0 if none).

*   **Temporal Flux Mechanism:**
    14. `getTemporalFluxRate() view`: Returns the current `Temporal Flux` multiplier affecting yield calculation.
    15. `updateTemporalFluxRate()`: (Owner/Keeper function) Simulates an external event by recalculating and updating the `Temporal Flux` rate based on protocol state (e.g., total staked).

*   **Governance/Owner Functions:**
    16. `setBaseYieldRate(uint256 rate)`: Allows the owner to set the base annual yield rate (scaled).
    17. `setDimensionKeyYieldBoost(uint256 boost)`: Allows the owner to set the multiplier boost provided by a `DimensionKey`.
    18. `setTemporalFluxFactor(uint256 factor)`: Allows the owner to set a factor influencing how the `Temporal Flux` rate is calculated.
    19. `setMinimumStakeAmount(uint256 amount)`: Allows the owner to set the minimum `ChronoToken` amount required for a new stake.
    20. `setMinimumStakeDuration(uint256 duration)`: Allows the owner to set a minimum duration before staked yield can be claimed or unstaked (optional, adds complexity, let's add it).
    21. `setKeyMintEligibility(address user, bool eligible)`: Allows the owner to whitelist/blacklist addresses eligible to mint `DimensionKey` NFTs.
    22. `pauseStaking(bool paused)`: Allows the owner to pause/unpause new staking.
    23. `pauseUnstaking(bool paused)`: Allows the owner to pause/unpause unstaking.
    24. `setFeeRate(uint256 rate)`: Allows the owner to set a fee percentage applied to yield claims or unstakes.
    25. `withdrawFees(address token, uint256 amount)`: Allows the owner to withdraw collected fees for a specific token.

*   **Standard ERC721 Functions (for TemporalShard & DimensionKey - implicitly included):**
    26. `balanceOf(address owner) view` (for both Shard and Key)
    27. `ownerOf(uint256 tokenId) view` (for both Shard and Key)
    28. `transferFrom(address from, address to, uint256 tokenId)` (for both Shard and Key - *Note: Transferring Shards transfers the staked position!*)
    29. `safeTransferFrom(...)` (variants, for both Shard and Key)
    30. `approve(address to, uint256 tokenId)` (for both Shard and Key)
    31. `getApproved(uint256 tokenId) view` (for both Shard and Key)
    32. `setApprovalForAll(address operator, bool approved)` (for both Shard and Key)
    33. `isApprovedForAll(address owner, address operator) view` (for both Shard and Key)
    *(These standard functions bring the total well over 20, even without counting ERC20 basics for ChronoToken).*

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/Math.sol"; // For min/max

// --- QuantumLeapProtocol Smart Contract ---
// Outline:
// 1. Pragma & Imports
// 2. Errors
// 3. Events
// 4. State Variables
// 5. Structs
// 6. Interfaces (Simulated/Referenced)
// 7. Libraries (None specific needed)
// 8. Owner/Access Control (Using Ownable)
// 9. Pausable Mechanism (Using Pausable)
// 10. TemporalShard Logic (ERC721 extension with dynamic properties)
// 11. DimensionKey Logic (ERC721 extension)
// 12. Core Protocol Logic (Staking, Unstaking, Yield, Merge, Split, Key Ops, Flux)
// 13. Parameter Governance/Owner Functions
// 14. View Functions

// Function Summary (> 20 unique protocol functions + standard ERC721/ERC20):
// - Core Staking/Yield: stake, unstake, claimYield, getAccumulatedYield, getStakedAmount
// - Temporal Shard Management: mergeTemporalShards, splitTemporalShard, getShardProperties, tokenURI (dynamic)
// - Dimension Key Interaction: mintDimensionKey, applyDimensionKey, removeDimensionKey, getLinkedDimensionKey
// - Temporal Flux Mechanism: getTemporalFluxRate, updateTemporalFluxRate
// - Governance/Owner: setBaseYieldRate, setDimensionKeyYieldBoost, setTemporalFluxFactor, setMinimumStakeAmount, setMinimumStakeDuration, setKeyMintEligibility, pauseStaking, pauseUnstaking, setFeeRate, withdrawFees
// - Standard ERC721 (Implicit for TemporalShard & DimensionKey): balanceOf, ownerOf, transferFrom, safeTransferFrom, approve, getApproved, setApprovalForAll, isApprovedForAll (adds >7 more)

// ChronoToken ERC-20 Interface (Assuming it exists)
interface IChronoToken is IERC20 {
    // Potentially add specific ChronoToken functions here if needed
}

// DimensionKey ERC-721 Interface (Assuming it exists)
interface IDimensionKey is IERC721 {
     // Potentially add specific DimensionKey functions here if needed
}

// --- Main Protocol Contract ---
contract QuantumLeapProtocol is Ownable, Pausable, ERC721 {
    // --- Errors ---
    error InvalidAmount();
    error InsufficientBalance();
    error StakingPaused();
    error UnstakingPaused();
    error NotOwnerOfShard();
    error ShardNotFound();
    error MinimumStakeDurationNotMet();
    error MinimumStakeAmountNotMet(uint256 required);
    error KeyNotFound();
    error NotOwnerOfKey();
    error KeyAlreadyLinked();
    error KeyNotLinkedToShard();
    error CannotMergeSingleShard();
    error CannotMergeNonOwnedShards();
    error CannotSplitIntoZeroAmount();
    error SplitAmountsMismatch();
    error KeyMintNotEligible();
    error InvalidFeeRate();
    error NoFeesCollected();

    // --- Events ---
    event Staked(address indexed user, uint256 shardId, uint256 amount, uint256 timestamp);
    event Unstaked(address indexed user, uint256 shardId, uint256 amount, uint256 yieldClaimed, uint256 timestamp);
    event YieldClaimed(address indexed user, uint256 shardId, uint256 yieldAmount, uint256 timestamp);
    event ShardsMerged(address indexed user, uint256[] mergedShardIds, uint256 newShardId, uint256 totalAmount, uint256 timestamp);
    event ShardSplit(address indexed user, uint256 originalShardId, uint256[] newShardIds, uint256[] newAmounts, uint256 timestamp);
    event DimensionKeyMinted(address indexed user, uint256 keyId, uint256 timestamp);
    event DimensionKeyApplied(address indexed user, uint256 shardId, uint256 keyId, uint256 timestamp);
    event DimensionKeyRemoved(address indexed user, uint256 shardId, uint256 keyId, uint256 timestamp);
    event TemporalFluxRateUpdated(uint256 oldRate, uint256 newRate, uint256 timestamp);
    event BaseYieldRateUpdated(uint256 oldRate, uint256 newRate);
    event DimensionKeyYieldBoostUpdated(uint256 oldBoost, uint256 newBoost);
    event TemporalFluxFactorUpdated(uint256 oldFactor, uint256 newFactor);
    event MinimumStakeAmountUpdated(uint256 oldAmount, uint256 newAmount);
    event MinimumStakeDurationUpdated(uint256 oldDuration, uint256 newDuration);
    event KeyMintEligibilityUpdated(address indexed user, bool eligible);
    event FeeRateUpdated(uint256 oldRate, uint256 newRate);
    event FeesWithdrawn(address indexed token, address indexed receiver, uint256 amount);

    // --- State Variables ---
    IChronoToken public immutable chronoToken;
    IDimensionKey public immutable dimensionKeyNFT;

    // --- TemporalShard data ---
    struct TemporalShardData {
        uint256 amount;          // Amount of ChronoToken staked in this shard
        uint48 stakeTimestamp;   // Timestamp when this shard was created (stake, merge, split)
        uint48 lastYieldClaimTimestamp; // Timestamp of last yield claim or state change
        uint256 accumulatedYield; // Yield accrued since last claim/change (in scaled units)
        uint256 linkedKeyId;     // ID of the DimensionKey linked to this shard (0 if none)
        address owner;           // Current owner (cached for quick lookup, ERC721 state is source of truth)
    }
    mapping(uint256 => TemporalShardData) private _shardData;
    using Counters for Counters.Counter;
    Counters.Counter private _temporalShardIds;

    // --- DimensionKey Data ---
    mapping(uint256 => bool) private _dimensionKeyExists; // Simple check if a key ID is valid (assuming external ERC721)
    mapping(uint256 => uint256) private _keyLinkedToShard; // Key ID => Shard ID it's linked to (0 if none)
    mapping(address => bool) private _isKeyMintEligible; // Whitelist for minting keys

    // --- Protocol Parameters ---
    uint256 public baseYieldRate; // Base APY, scaled (e.g., 5e16 for 5%)
    uint256 public dimensionKeyYieldBoost; // Multiplier boost for shards with linked keys (e.g., 1.2e18 for 1.2x)
    uint256 public temporalFluxRate; // Current flux multiplier (simulated external factor, e.g., 1e18 for 1x)
    uint256 public temporalFluxFactor; // Factor influencing flux calculation (e.g., sensitivity to TVL)
    uint256 public minimumStakeAmount; // Minimum ChronoToken to stake per shard
    uint256 public minimumStakeDuration; // Minimum time a shard must exist before yield can be claimed/unstaked
    uint256 public feeRate; // Percentage fee on yield claims/unstakes (e.g., 1e16 for 1%)
    mapping(address => uint256) public collectedFees; // Mapping of token address to collected fees

    // --- Constants ---
    uint256 private constant SCALE = 1e18; // Standard scaling factor
    uint256 private constant SECONDS_IN_YEAR = 31536000; // Approximately

    // --- Constructor ---
    constructor(address _chronoToken, address _dimensionKeyNFT)
        ERC721("TemporalShard", "TS")
        Ownable(msg.sender) // Sets the contract creator as the initial owner
    {
        chronoToken = IChronoToken(_chronoToken);
        dimensionKeyNFT = IDimensionKey(_dimensionKeyNFT);

        // Initial parameters (can be changed by owner)
        baseYieldRate = 5e16; // 5% APY
        dimensionKeyYieldBoost = 1.2e18; // 1.2x boost
        temporalFluxRate = SCALE; // Start at 1x flux
        temporalFluxFactor = 1e15; // Example factor for flux calculation
        minimumStakeAmount = 1e18; // 1 ChronoToken minimum
        minimumStakeDuration = 0; // No minimum duration initially
        feeRate = 0; // No fees initially
    }

    // --- Modifiers ---
    modifier onlyShardOwner(uint256 _shardId) {
        if (ownerOf(_shardId) != msg.sender) {
            revert NotOwnerOfShard();
        }
        _;
    }

    modifier onlyKeyOwner(uint256 _keyId) {
         // Assuming dimensionKeyNFT has standard ownerOf
        if (dimensionKeyNFT.ownerOf(_keyId) != msg.sender) {
            revert NotOwnerOfKey();
        }
        _;
    }

    // --- Pausable Overrides ---
    function pauseStaking(bool paused) public onlyOwner {
        if (paused) _pause(); else _unpause();
        emit Paused(address(0)); // Use generic Paused event
    }

    function pauseUnstaking(bool paused) public onlyOwner {
         // We need a separate pausable state for unstaking, or manage it manually
         // Let's add manual flags for staking/unstaking pause
         _unstakingPaused = paused;
         emit Paused(address(0)); // Use generic Paused event
    }
     bool private _unstakingPaused = false; // Manual flag

    // --- Core Protocol Logic ---

    /// @notice Stakes ChronoToken and mints a new TemporalShard NFT.
    /// @param amount The amount of ChronoToken to stake.
    function stake(uint256 amount) external whenNotPaused {
        if (amount == 0) revert InvalidAmount();
        if (amount < minimumStakeAmount) revert MinimumStakeAmountNotMet(minimumStakeAmount);

        if (chronoToken.balanceOf(msg.sender) < amount) revert InsufficientBalance();

        _temporalShardIds.increment();
        uint256 newShardId = _temporalShardIds.current();
        uint48 currentTimestamp = uint48(block.timestamp);

        // Transfer tokens to contract
        bool success = chronoToken.transferFrom(msg.sender, address(this), amount);
        if (!success) revert InsufficientBalance(); // More specific error if transfer fails

        // Mint the TemporalShard NFT
        _mint(msg.sender, newShardId);

        // Store shard data
        _shardData[newShardId] = TemporalShardData({
            amount: amount,
            stakeTimestamp: currentTimestamp,
            lastYieldClaimTimestamp: currentTimestamp,
            accumulatedYield: 0, // Start with 0 accumulated yield
            linkedKeyId: 0, // No key linked initially
            owner: msg.sender // Cache owner
        });

        emit Staked(msg.sender, newShardId, amount, currentTimestamp);
    }

    /// @notice Unstakes the ChronoToken from a TemporalShard and burns the NFT.
    /// Claims pending yield automatically.
    /// @param shardId The ID of the TemporalShard to unstake.
    function unstake(uint256 shardId) external onlyShardOwner(shardId) {
        if (_unstakingPaused) revert UnstakingPaused();
        if (!_shardData[shardId].owner.isInitialized) revert ShardNotFound(); // Check if shard exists

        TemporalShardData storage shard = _shardData[shardId];
        if (block.timestamp < shard.stakeTimestamp + minimumStakeDuration) revert MinimumStakeDurationNotMet();

        uint256 amountToUnstake = shard.amount;

        // Calculate and claim yield before burning
        uint256 yieldAmount = _calculateAndClaimYield(shardId);

        // Burn the NFT
        _burn(shardId);

        // Clear shard data
        delete _shardData[shardId];

        // Transfer principal back to user
        bool successPrincipal = chronoToken.transfer(msg.sender, amountToUnstake);
        // Transfer yield (already calculated and possibly transferred in _calculateAndClaimYield)
        // successYield is handled within _calculateAndClaimYield

        if (!successPrincipal) {
             // This is a critical failure, contract holds tokens but cannot send.
             // In a real protocol, this would need more robust error handling,
             // potentially leaving funds in the contract or triggering a multi-sig recovery.
             // For this example, we'll just revert, but acknowledge the edge case.
             revert InsufficientBalance(); // Should not happen if balance is sufficient
         }

        emit Unstaked(msg.sender, shardId, amountToUnstake, yieldAmount, block.timestamp);
    }

    /// @notice Claims the accumulated yield for a specific TemporalShard.
    /// @param shardId The ID of the TemporalShard.
    function claimYield(uint256 shardId) external onlyShardOwner(shardId) {
         if (!_shardData[shardId].owner.isInitialized) revert ShardNotFound(); // Check if shard exists

        TemporalShardData storage shard = _shardData[shardId];
        if (block.timestamp < shard.stakeTimestamp + minimumStakeDuration) revert MinimumStakeDurationNotMet();

        uint256 yieldAmount = _calculateAndClaimYield(shardId);

        if (yieldAmount > 0) {
             emit YieldClaimed(msg.sender, shardId, yieldAmount, block.timestamp);
         }
    }

    /// @notice Internal function to calculate yield and handle transfer/fee logic.
    /// Updates shard's accumulated yield and timestamp.
    /// @param shardId The ID of the TemporalShard.
    /// @return The amount of yield claimed (after fees).
    function _calculateAndClaimYield(uint256 shardId) internal returns (uint256) {
        TemporalShardData storage shard = _shardData[shardId];
        uint256 currentTimestamp = block.timestamp;

        // Add newly accrued yield to accumulated yield
        uint256 newlyAccrued = _calculateAccruedYield(shardId, shard.lastYieldClaimTimestamp, currentTimestamp);
        shard.accumulatedYield += newlyAccrued;

        uint256 totalYield = shard.accumulatedYield;
        if (totalYield == 0) {
             shard.lastYieldClaimTimestamp = uint48(currentTimestamp);
             return 0; // Nothing to claim
         }

        // Calculate fee
        uint256 feeAmount = (totalYield * feeRate) / SCALE;
        uint256 yieldAfterFee = totalYield - feeAmount;

        // Reset accumulated yield after calculation
        shard.accumulatedYield = 0;
        shard.lastYieldClaimTimestamp = uint48(currentTimestamp);

        // Collect fee
        if (feeAmount > 0) {
            collectedFees[address(chronoToken)] += feeAmount;
        }

        // Transfer yield to user
        if (yieldAfterFee > 0) {
            bool successYield = chronoToken.transfer(shard.owner, yieldAfterFee);
             if (!successYield) {
                // This is problematic. Yield was calculated but couldn't be sent.
                // In a production system, this might use a pull mechanism or
                // queue the yield for later claim. For this example,
                // we'll re-add the amount back to accumulatedYield and potentially revert.
                // A simpler approach is to just revert on transfer failure in examples.
                 shard.accumulatedYield += yieldAfterFee; // Put it back
                 revert InsufficientBalance(); // Should indicate contract lacks ChronoToken to pay yield
             }
        }

        return yieldAfterFee;
    }

    /// @notice Internal helper to calculate yield accrued between two timestamps.
    /// @param shardId The ID of the TemporalShard.
    /// @param fromTimestamp The starting timestamp.
    /// @param toTimestamp The ending timestamp.
    /// @return The amount of yield accrued (scaled).
    function _calculateAccruedYield(uint256 shardId, uint256 fromTimestamp, uint256 toTimestamp) internal view returns (uint256) {
        if (fromTimestamp >= toTimestamp) {
            return 0;
        }
        TemporalShardData storage shard = _shardData[shardId];
        uint256 duration = toTimestamp - fromTimestamp;
        uint256 amount = shard.amount;

        uint256 currentFlux = temporalFluxRate;
        uint256 currentBoost = shard.linkedKeyId > 0 ? dimensionKeyYieldBoost : SCALE; // Apply boost if key is linked

        // Yield = Amount * Rate * Duration * Flux * Boost / (SCALE * SECONDS_IN_YEAR * SCALE * SCALE)
        // Simplified: Amount * Rate * Duration / SECONDS_IN_YEAR * Flux * Boost / (SCALE * SCALE)
        // Use SafeMath if needed, but 0.8+ handles overflow check
        uint256 yield = (amount * baseYieldRate * duration) / SECONDS_IN_YEAR;
        yield = (yield * currentFlux) / SCALE;
        yield = (yield * currentBoost) / SCALE;

        return yield;
    }


    /// @notice Merges multiple TemporalShard NFTs into a single new shard.
    /// Requires ownership of all input shards. Automatically claims yield.
    /// @param shardIds An array of TemporalShard IDs to merge.
    function mergeTemporalShards(uint256[] calldata shardIds) external whenNotPaused onlyShardOwner(shardIds[0]) {
        if (shardIds.length <= 1) revert CannotMergeSingleShard();

        uint256 totalAmount = 0;
        // Auto-claim yield and sum amounts
        for (uint i = 0; i < shardIds.length; i++) {
            uint256 currentShardId = shardIds[i];
            // Ensure owner of all shards is the caller
            if (ownerOf(currentShardId) != msg.sender) revert CannotMergeNonOwnedShards();
             if (!_shardData[currentShardId].owner.isInitialized) revert ShardNotFound(); // Check if shard exists

            // Claim yield before merging
            _calculateAndClaimYield(currentShardId); // Handles transfer + update last timestamp

            totalAmount += _shardData[currentShardId].amount;
        }

        _temporalShardIds.increment();
        uint256 newShardId = _temporalShardIds.current();
        uint48 currentTimestamp = uint48(block.timestamp);

        // Mint the new merged shard
        _mint(msg.sender, newShardId);

        // Store new shard data
        _shardData[newShardId] = TemporalShardData({
            amount: totalAmount,
            stakeTimestamp: currentTimestamp, // New timestamp for the merged shard
            lastYieldClaimTimestamp: currentTimestamp, // New timestamp for yield calculation
            accumulatedYield: 0,
            linkedKeyId: 0, // Merged shard starts with no key linked
            owner: msg.sender // Cache owner
        });

        // Burn the old shards
        for (uint i = 0; i < shardIds.length; i++) {
            _burn(shardIds[i]);
             delete _shardData[shardIds[i]]; // Clear old data
        }

        emit ShardsMerged(msg.sender, shardIds, newShardId, totalAmount, currentTimestamp);
    }

    /// @notice Splits a single TemporalShard NFT into multiple new shards.
    /// Requires ownership of the original shard. Automatically claims yield.
    /// @param shardId The ID of the TemporalShard to split.
    /// @param amounts An array of amounts for the new shards. Sum must equal the original shard's amount.
    function splitTemporalShard(uint256 shardId, uint256[] calldata amounts) external whenNotPaused onlyShardOwner(shardId) {
        if (amounts.length == 0) revert CannotSplitIntoZeroAmount();
        if (!_shardData[shardId].owner.isInitialized) revert ShardNotFound(); // Check if shard exists

        TemporalShardData storage originalShard = _shardData[shardId];
        uint256 originalAmount = originalShard.amount;
        uint256 totalNewAmount = 0;
        for (uint i = 0; i < amounts.length; i++) {
            if (amounts[i] == 0) revert CannotSplitIntoZeroAmount();
            totalNewAmount += amounts[i];
        }

        if (totalNewAmount != originalAmount) revert SplitAmountsMismatch();

        // Claim yield from the original shard before splitting
        _calculateAndClaimYield(shardId); // Handles transfer + update last timestamp

        // Burn the original shard
        _burn(shardId);
        delete _shardData[shardId]; // Clear old data

        uint48 currentTimestamp = uint48(block.timestamp);
        uint256[] memory newShardIds = new uint256[](amounts.length);

        // Mint the new shards
        for (uint i = 0; i < amounts.length; i++) {
            _temporalShardIds.increment();
            uint256 newShardId = _temporalShardIds.current();
            newShardIds[i] = newShardId;

            _mint(msg.sender, newShardId);

            _shardData[newShardId] = TemporalShardData({
                amount: amounts[i],
                stakeTimestamp: currentTimestamp, // New timestamp for split shards
                lastYieldClaimTimestamp: currentTimestamp, // New timestamp for yield calculation
                accumulatedYield: 0,
                linkedKeyId: 0, // Split shards start with no key linked
                owner: msg.sender // Cache owner
            });
        }

        emit ShardSplit(msg.sender, shardId, newShardIds, amounts, currentTimestamp);
    }

    /// @notice Allows eligible users to mint a DimensionKey NFT.
    function mintDimensionKey() external whenNotPaused {
        if (!_isKeyMintEligible[msg.sender] && owner() != msg.sender) revert KeyMintNotEligible(); // Only owner or whitelisted can mint

        // Assume DimensionKeyNFT contract has a mint function callable by this protocol contract
        // In a real scenario, this would be an external call to dimensionKeyNFT.mint(msg.sender);
        // For this example, we'll simulate it by just noting eligibility.
        // A more complete example would require DimensionKeyNFT contract definition and interface.

        // Simulate minting - In a real scenario, you'd interact with the DimensionKeyNFT contract
        // Let's assume DimensionKeyNFT has a function like `safeMint(address to)`
        // This requires the DimensionKeyNFT contract to grant Minter role to this contract address.
        // dimensionKeyNFT.safeMint(msg.sender);
        // Assuming the mint function returns the new key ID:
        // uint256 newKeyId = dimensionKeyNFT.safeMint(msg.sender);
        // _dimensionKeyExists[newKeyId] = true; // Track existence if it's external and we need to check it

        // **SIMULATION Placeholder:** Generate a dummy key ID for example purposes
        // This simulation is not secure or standard for NFT minting.
        // A real implementation MUST interact with a proper ERC721 contract for DimensionKeys.
        uint256 simulatedKeyId = block.timestamp % 1000 + _temporalShardIds.current(); // Dummy ID generation
        if (_dimensionKeyExists[simulatedKeyId]) simulatedKeyId += 1000; // Avoid collision in simulation
        _dimensionKeyExists[simulatedKeyId] = true; // Mark as 'minted' in simulation

        emit DimensionKeyMinted(msg.sender, simulatedKeyId, block.timestamp);
        // In a real system, the event should emit the actual minted key ID from the NFT contract call
    }


    /// @notice Links a DimensionKey NFT to a TemporalShard NFT to apply a yield boost.
    /// Requires ownership of both the key and the shard.
    /// @param shardId The ID of the TemporalShard.
    /// @param keyId The ID of the DimensionKey.
    function applyDimensionKey(uint256 shardId, uint256 keyId) external whenNotPaused onlyShardOwner(shardId) onlyKeyOwner(keyId) {
        if (!_shardData[shardId].owner.isInitialized) revert ShardNotFound(); // Check if shard exists
        // Check if key exists and is not already linked
        // In a real scenario, you'd call dimensionKeyNFT.exists(keyId) or similar
        // if (!_dimensionKeyExists[keyId]) revert KeyNotFound(); // Simulation check
        // if (_keyLinkedToShard[keyId] != 0) revert KeyAlreadyLinked(); // Check if already linked elsewhere

        TemporalShardData storage shard = _shardData[shardId];
        if (shard.linkedKeyId != 0) revert KeyAlreadyLinked(); // Check if this shard already has a key

        // Calculate and claim yield *before* applying key, so boost applies from now on
        _calculateAndClaimYield(shardId);

        // Link the key
        shard.linkedKeyId = keyId;
        _keyLinkedToShard[keyId] = shardId;

        // Note: Transferring ownership of the DimensionKey NFT while it's linked
        // would transfer the right to *remove* it, but the boost stays with the shard.
        // The new key owner would need to unlink it first if they wanted to use it elsewhere.
        // Or, add logic here to require key owner == shard owner at time of boost.
        // Current logic: only original applier (or current shard/key owner if transfer is allowed) can remove.

        emit DimensionKeyApplied(msg.sender, shardId, keyId, block.timestamp);
    }

    /// @notice Unlinks a DimensionKey NFT from a TemporalShard.
    /// Requires ownership of the shard. The key becomes available to be linked elsewhere.
    /// @param shardId The ID of the TemporalShard.
    function removeDimensionKey(uint256 shardId) external onlyShardOwner(shardId) {
         if (!_shardData[shardId].owner.isInitialized) revert ShardNotFound(); // Check if shard exists

        TemporalShardData storage shard = _shardData[shardId];
        uint256 linkedKeyId = shard.linkedKeyId;

        if (linkedKeyId == 0) revert KeyNotLinkedToShard();

        // Calculate and claim yield *before* removing key, so boost is accounted for up to now
        _calculateAndClaimYield(shardId);

        // Unlink the key
        shard.linkedKeyId = 0;
        _keyLinkedToShard[linkedKeyId] = 0;

        emit DimensionKeyRemoved(msg.sender, shardId, linkedKeyId, block.timestamp);
    }

    /// @notice Recalculates and updates the Temporal Flux rate.
    /// This function simulates an external process affecting the protocol yield.
    /// Can be called by the owner or a designated keeper.
    function updateTemporalFluxRate() external onlyOwner { // Or configure a keeper role
        // Simulate flux based on Total Value Locked (TVL) or other factors
        // TVL simulation: sum of all staked amounts.
        uint256 currentTVL = 0;
        uint256 totalShards = _temporalShardIds.current();
        // Note: Iterating over all shards in state is gas-expensive.
        // A real system might store total TVL separately and update it on stake/unstake.
        // For this example, we iterate over existing shard IDs up to the current counter.
        // This is inefficient but demonstrates the concept.
        for(uint256 i = 1; i <= totalShards; i++) {
             // Check if the shard ID exists and is not burned (shardData[i].owner should be valid)
             // ownerOf(i) is more reliable check if NFT exists and is owned by someone (including this contract temporarily)
             // Checking _shardData[i].owner.isInitialized is a check on our internal data structure
             // Let's check our internal data as it reflects the active positions
             if(_shardData[i].owner.isInitialized) {
                 currentTVL += _shardData[i].amount;
             }
         }


        // Simple flux calculation example: Flux increases slightly with TVL
        // newFlux = SCALE + (currentTVL * temporalFluxFactor) / SCALE
        uint256 newFlux = SCALE + (currentTVL * temporalFluxFactor) / SCALE;

        uint256 oldRate = temporalFluxRate;
        temporalFluxRate = newFlux;

        emit TemporalFluxRateUpdated(oldRate, newFlux, block.timestamp);
    }

    // --- Governance/Owner Functions ---

    /// @notice Sets the base annual yield rate. Only callable by owner.
    /// @param rate The new base rate (scaled by SCALE).
    function setBaseYieldRate(uint256 rate) external onlyOwner {
        uint256 oldRate = baseYieldRate;
        baseYieldRate = rate;
        emit BaseYieldRateUpdated(oldRate, rate);
    }

    /// @notice Sets the yield boost multiplier for shards with linked DimensionKeys. Only callable by owner.
    /// @param boost The new boost multiplier (scaled by SCALE).
    function setDimensionKeyYieldBoost(uint256 boost) external onlyOwner {
        uint256 oldBoost = dimensionKeyYieldBoost;
        dimensionKeyYieldBoost = boost;
        emit DimensionKeyYieldBoostUpdated(oldBoost, boost);
    }

    /// @notice Sets the factor used in Temporal Flux calculation. Only callable by owner.
    /// @param factor The new flux factor (scaled by SCALE).
    function setTemporalFluxFactor(uint256 factor) external onlyOwner {
        uint256 oldFactor = temporalFluxFactor;
        temporalFluxFactor = factor;
        emit TemporalFluxFactorUpdated(oldFactor, factor);
    }

    /// @notice Sets the minimum ChronoToken amount required for a new stake. Only callable by owner.
    /// @param amount The new minimum stake amount (in ChronoToken units).
    function setMinimumStakeAmount(uint256 amount) external onlyOwner {
        uint256 oldAmount = minimumStakeAmount;
        minimumStakeAmount = amount;
        emit MinimumStakeAmountUpdated(oldAmount, amount);
    }

     /// @notice Sets the minimum duration a shard must exist before yield can be claimed/unstaked. Only callable by owner.
    /// @param duration The new minimum duration in seconds.
    function setMinimumStakeDuration(uint256 duration) external onlyOwner {
        uint256 oldDuration = minimumStakeDuration;
        minimumStakeDuration = duration;
        emit MinimumStakeDurationUpdated(oldDuration, duration);
    }

    /// @notice Sets eligibility for an address to mint DimensionKey NFTs. Only callable by owner.
    /// @param user The address to set eligibility for.
    /// @param eligible Whether the user is eligible or not.
    function setKeyMintEligibility(address user, bool eligible) external onlyOwner {
        _isKeyMintEligible[user] = eligible;
        emit KeyMintEligibilityUpdated(user, eligible);
    }

    /// @notice Sets the fee percentage applied to yield claims/unstakes. Only callable by owner.
    /// @param rate The fee rate (scaled by SCALE, e.g., 1e16 for 1%). Max 1e18 (100%).
    function setFeeRate(uint256 rate) external onlyOwner {
        if (rate > SCALE) revert InvalidFeeRate(); // Fee rate cannot exceed 100%
        uint256 oldRate = feeRate;
        feeRate = rate;
        emit FeeRateUpdated(oldRate, rate);
    }

    /// @notice Allows the owner to withdraw collected fees for a specific token.
    /// @param token The address of the token (e.g., ChronoToken) from which to withdraw fees.
    /// @param amount The amount to withdraw.
    function withdrawFees(address token, uint256 amount) external onlyOwner {
        if (amount == 0) revert InvalidAmount();
        if (collectedFees[token] < amount) revert NoFeesCollected();

        collectedFees[token] -= amount;
        // Assuming the token address is the ChronoToken address for fees
        IChronoToken(token).transfer(owner(), amount);

        emit FeesWithdrawn(token, owner(), amount);
    }

    // --- View Functions ---

    /// @notice Returns the accumulated yield for a specific TemporalShard without claiming.
    /// @param shardId The ID of the TemporalShard.
    /// @return The total accumulated yield (scaled).
    function getAccumulatedYield(uint256 shardId) public view returns (uint256) {
         if (!_shardData[shardId].owner.isInitialized) revert ShardNotFound(); // Check if shard exists

        TemporalShardData storage shard = _shardData[shardId];
        uint256 newlyAccrued = _calculateAccruedYield(shardId, shard.lastYieldClaimTimestamp, block.timestamp);
        return shard.accumulatedYield + newlyAccrued;
    }

    /// @notice Returns the staked amount for a TemporalShard.
    /// @param shardId The ID of the TemporalShard.
    /// @return The staked amount (in ChronoToken units).
    function getStakedAmount(uint256 shardId) public view returns (uint256) {
        if (!_shardData[shardId].owner.isInitialized) revert ShardNotFound();
        return _shardData[shardId].amount;
    }

    /// @notice Returns key properties of a TemporalShard.
    /// @param shardId The ID of the TemporalShard.
    /// @return amount The staked amount.
    /// @return stakeTimestamp The timestamp when the shard was created/last state changed.
    /// @return linkedKeyId The ID of the linked DimensionKey (0 if none).
    /// @return accumulatedYield The yield accumulated but not yet claimed.
    function getShardProperties(uint256 shardId) public view returns (uint256 amount, uint256 stakeTimestamp, uint256 linkedKeyId, uint256 accumulatedYield) {
        if (!_shardData[shardId].owner.isInitialized) revert ShardNotFound();
        TemporalShardData storage shard = _shardData[shardId];
        return (
            shard.amount,
            shard.stakeTimestamp,
            shard.linkedKeyId,
            getAccumulatedYield(shardId) // Use the view function to get current yield
        );
    }

    /// @notice Returns the ID of the DimensionKey linked to a TemporalShard.
    /// @param shardId The ID of the TemporalShard.
    /// @return The linked DimensionKey ID (0 if none).
    function getLinkedDimensionKey(uint256 shardId) public view returns (uint256) {
         if (!_shardData[shardId].owner.isInitialized) return 0; // Return 0 if shard doesn't exist or has no key
        return _shardData[shardId].linkedKeyId;
    }

    /// @notice Returns the current Temporal Flux rate multiplier.
    /// @return The flux rate (scaled by SCALE).
    function getTemporalFluxRate() public view returns (uint256) {
        return temporalFluxRate;
    }

    /// @notice Checks if an address is eligible to mint DimensionKey NFTs.
    /// @param user The address to check.
    /// @return True if eligible, false otherwise.
    function isKeyMintEligible(address user) public view returns (bool) {
        return _isKeyMintEligible[user];
    }

     /// @notice Checks if unstaking is paused.
    /// @return True if paused, false otherwise.
    function isUnstakingPaused() public view returns (bool) {
        return _unstakingPaused;
    }

    /// @notice Returns the total fees collected for a specific token.
    /// @param token The token address.
    /// @return The total collected fees.
    function getProtocolFeesCollected(address token) public view returns (uint256) {
        return collectedFees[token];
    }


    // --- ERC721 Overrides for Dynamic Metadata ---

    /// @notice Returns the URI for metadata of a TemporalShard NFT.
    /// This function is overridden to generate dynamic metadata based on shard state.
    /// In a real application, this would point to an off-chain metadata server
    /// that reads the shard's properties via a contract API and generates a JSON file.
    /// For this example, it returns a placeholder string indicating dynamism.
    /// @param shardId The ID of the TemporalShard.
    /// @return A string representing the metadata URI.
    function tokenURI(uint256 shardId) public view override returns (string memory) {
        // Check if shard exists (ownerOf would revert if not)
        // _shardData[shardId].owner.isInitialized also works as it's deleted on burn
        if (!_exists(shardId)) {
             revert ERC721NonexistentToken(shardId);
        }

        // In a real application, construct a URL like:
        // string memory base = "https://your-metadata-server.com/api/shards/";
        // return string(abi.encodePacked(base, Strings.toString(shardId)));

        // The metadata server at this URL would then call getShardProperties(shardId)
        // and format the data into ERC721 metadata JSON.

        // Example of how properties *could* influence metadata attributes:
        (uint256 amount, uint256 stakeTimestamp, uint256 linkedKeyId, uint256 currentYield) = getShardProperties(shardId);

        // Dummy dynamic URI for demonstration
        // A real implementation would require a separate metadata server
        return string(abi.encodePacked(
            "data:application/json;base64,",
            Base64.encode(bytes(abi.encodePacked(
                '{"name": "Temporal Shard #', Strings.toString(shardId), '",',
                '"description": "Represents a staked position in the QuantumLeapProtocol.",',
                '"attributes": [',
                    '{"trait_type": "Staked Amount", "value": "', Strings.toString(amount), '"},',
                    '{"trait_type": "Staked Since", "value": "', Strings.toString(stakeTimestamp), '"},',
                    '{"trait_type": "Accumulated Yield (approx)", "value": "', Strings.toString(currentYield), '"},',
                    '{"trait_type": "Dimension Key Linked", "value": ', linkedKeyId > 0 ? 'true' : 'false', '}',
                    linkedKeyId > 0 ? string(abi.encodePacked(',{"trait_type": "Linked Key ID", "value": "', Strings.toString(linkedKeyId), '"}')) : '',
                    // Add more dynamic attributes based on state: duration, yield rate, flux rate, etc.
                ']}'
            )))
        ));
    }

    // --- Standard ERC721 Functions (Implemented by inheriting ERC721) ---
    // balanceOf(address owner) view
    // ownerOf(uint256 tokenId) view
    // transferFrom(address from, address to, uint256 tokenId)
    // safeTransferFrom(...) variants
    // approve(address to, uint256 tokenId)
    // getApproved(uint256 tokenId) view
    // setApprovalForAll(address operator, bool approved)
    // isApprovedForAll(address owner, address operator) view

    // Override transfer hooks to update cached owner and handle key linking logic
    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize) internal override {
        super._beforeTokenTransfer(from, to, tokenId, batchSize); // Handles ERC721Enumerable if used

        // Handle TemporalShard transfers
        if (from != address(0) && to != address(0)) { // Only on actual transfer, not mint/burn
            // Check if this is a TemporalShard transfer
            // A more robust check might involve checking if tokenId is within our shard ID range or a mapping
            // For this example, assume any transfer is a shard transfer for simplicity
            // This needs refinement if DimensionKeys are also handled by this same contract or logic.
            // Let's refine: Check if the tokenId exists in our shardData mapping
            if (_shardData[tokenId].owner.isInitialized) {
                // Update cached owner
                _shardData[tokenId].owner = to;
                // Yield is *not* automatically claimed on transfer.
                // The new owner inherits the pending yield.
                // The lastYieldClaimTimestamp remains, so yield continues calculating for the new owner.
            }
             // If this was a DimensionKey transfer, we might need to do something here too
             // e.g., prevent transfer if linked, or manage the _keyLinkedToShard mapping.
             // For now, assume DimensionKeys are external and transferable freely,
             // the link check happens in apply/remove functions.
        } else if (from == address(0) && to != address(0)) { // Mint
             if (_shardData[tokenId].owner.isInitialized) {
                 _shardData[tokenId].owner = to; // Cache owner on mint
             }
        } else if (from != address(0) && to == address(0)) { // Burn
             // If it's a TemporalShard being burned (unstake, merge, split)
             if (_shardData[tokenId].owner.isInitialized) {
                 // Unlink any associated DimensionKey before burning the shard
                 uint256 linkedKeyId = _shardData[tokenId].linkedKeyId;
                 if (linkedKeyId != 0) {
                      _keyLinkedToShard[linkedKeyId] = 0; // Unlink key
                      // Note: The key NFT itself is NOT burned, just unlinked from the shard.
                 }
                 // Data is deleted in unstake/merge/split functions
             }
        }
    }
}

// Helper library for Base64 encoding (from OpenZeppelin or similar)
// Needed for the dynamic tokenURI example
library Base64 {
    string internal constant TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    function encode(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return "";

        // load the table into memory
        string memory table = TABLE;

        // allocate the result
        bytes memory tableBytes = bytes(table);
        uint256 encodedLen = 4 * ((data.length + 2) / 3);
        bytes memory result = new bytes(encodedLen);

        // byte by byte
        unchecked {
            for (uint256 i = 0; i < data.length; i += 3) {
                uint256 chunk;
                bytes1 b1;
                bytes1 b2;
                bytes1 b3;

                if (i + 2 < data.length) {
                    chunk = (uint256(uint8(data[i])) << 16) | (uint256(uint8(data[i + 1])) << 8) | uint256(uint8(data[i + 2]));
                    b1 = tableBytes[(chunk >> 18) & 0x3F];
                    b2 = tableBytes[(chunk >> 12) & 0x3F];
                    b3 = tableBytes[(chunk >> 6) & 0x3F];
                    result[i / 3 * 4] = b1;
                    result[i / 3 * 4 + 1] = b2;
                    result[i / 3 * 4 + 2] = b3;
                    result[i / 3 * 4 + 3] = tableBytes[chunk & 0x3F];
                } else if (i + 1 < data.length) {
                    chunk = (uint256(uint8(data[i])) << 16) | (uint256(uint8(data[i + 1])) << 8);
                    b1 = tableBytes[(chunk >> 18) & 0x3F];
                    b2 = tableBytes[(chunk >> 12) & 0x3F];
                    b3 = tableBytes[(chunk >> 6) & 0x3F];
                    result[i / 3 * 4] = b1;
                    result[i / 3 * 4 + 1] = b2;
                    result[i / 3 * 4 + 2] = b3;
                    result[i / 3 * 4 + 3] = bytes1(0x3d); // Pad with '='
                } else {
                    chunk = uint256(uint8(data[i])) << 16;
                    b1 = tableBytes[(chunk >> 18) & 0x3F];
                    b2 = tableBytes[(chunk >> 12) & 0x3F];
                    result[i / 3 * 4] = b1;
                    result[i / 3 * 4 + 1] = b2;
                    result[i / 3 * 4 + 2] = bytes1(0x3d); // Pad with '=='
                    result[i / 3 * 4 + 3] = bytes1(0x3d);
                }
            }
        }

        return string(result);
    }

     // Minimal helper for checking if a struct address member is initialized (non-zero)
     library AddressUtils {
         function isInitialized(address account) internal pure returns (bool) {
             return account != address(0);
         }
     }
     using AddressUtils for address;
}

// Helper library for converting numbers to strings (from OpenZeppelin or similar)
// Needed for the dynamic tokenURI example
library Strings {
    function toString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        unchecked {
            while (value != 0) {
                digits--;
                buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
                value /= 10;
            }
        }
        return string(buffer);
    }
}

// Note: This code assumes the ChronoToken and DimensionKeyNFT ERC-20 and ERC-721
// contracts are deployed separately and their addresses are provided to the
// constructor. For full testability, you would need to include mock
// implementations of IChronoToken and IDimensionKey.
// The DimensionKey minting logic is simulated and would need real interaction
// with the DimensionKeyNFT contract in a production environment, ensuring
// appropriate access control is granted to the QuantumLeapProtocol contract
// on the DimensionKeyNFT contract.
```

**Explanation of Advanced Concepts:**

1.  **Dynamic ERC-721 Metadata (`tokenURI` override):** The `TemporalShard` NFT's metadata isn't static. The `tokenURI` function is overridden to generate a data URL (or point to a server that generates one) that includes the *current* state of the staked position (amount, duration, yield, linked key). This allows platforms displaying the NFT (like marketplaces or wallets) to show up-to-date information directly from the contract state.
2.  **Staked Position as NFT:** Instead of just tracking staked amounts in a mapping, the staked position itself is tokenized as a `TemporalShard`. This makes the position a transferable, composable asset. Transferring the NFT transfers the ownership of the underlying staked ChronoToken and the right to claim yield.
3.  **Layered Access/Utility NFTs (`DimensionKey`):** `DimensionKey` NFTs provide a distinct layer of functionality – they act as boosters for yield when linked to a `TemporalShard`. This introduces a second type of NFT with a specific utility within the protocol, creating potential for tiered access, unique strategies, or a separate economic model for keys.
4.  **Complex State Transitions (Merge/Split):** The `mergeTemporalShards` and `splitTemporalShard` functions demonstrate non-trivial logic where multiple NFTs are burned and new ones are minted, representing the restructuring of underlying staked positions. This requires careful management of the staked amounts, timestamps, and yield accumulation across the transition. Yield is calculated and "cashed out" before the merge/split to simplify the state of the new shards.
5.  **Simulated External Factor (`TemporalFlux`):** The `temporalFluxRate` and `updateTemporalFluxRate` function simulate an external influence on the protocol's yield. In a real-world scenario, `updateTemporalFluxRate` might be triggered by an oracle based on market conditions, total value locked (TVL), or other arbitrary data. This adds a layer of dynamic response to the protocol's economics. The example uses a simplified TVL calculation (though inefficient for very large numbers of shards, demonstrating the concept).
6.  **Structured Data & Mappings:** Using a `struct TemporalShardData` within a mapping keeps all relevant information for each NFT organized. Using `uint48` for timestamps saves gas compared to `uint256` where possible, acknowledging gas optimization concerns in complex contracts.
7.  **Internal Yield Calculation & State Management:** The `_calculateAccruedYield` and `_calculateAndClaimYield` internal functions handle the complex yield calculation logic, including prorating by time, applying boosts/flux, tracking last claim timestamps, and handling fees, before updating the contract's state.
8.  **Modular Design:** While everything is in one file for demonstration, separating ERC20/ERC721 implementations and potentially abstracting core staking/yield logic would improve modularity and testability in a larger project. Using interfaces (`IChronoToken`, `IDimensionKey`) points towards this modular approach even when included in one file.
9.  **Error Handling & Events:** Using custom `error` types and comprehensive `event` emissions provides clarity on contract execution flow, state changes, and debugging.
10. **Pausable & Owner Controls:** Basic `Ownable` and `Pausable` patterns provide essential administrative controls for emergency situations or parameter tuning, crucial for managing a complex protocol.

This contract demonstrates a combination of features that go beyond simple token staking or standard NFT functionalities, creating a unique protocol with layered digital assets and dynamic economic parameters.