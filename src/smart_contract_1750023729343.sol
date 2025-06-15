Okay, let's design a smart contract that goes beyond standard token or simple NFT contracts. We'll create a system for "AuraBound Assets" - dynamic NFTs that can be staked to earn a reward token, and whose attributes can be influenced by user interaction while staked, potentially affecting yield or unlocking abilities.

This incorporates:
*   **Dynamic NFTs:** Attributes stored on-chain that can change.
*   **Staking:** Locking NFTs in the contract to earn yield.
*   **Dual Token System:** ERC-721 NFTs and ERC-20 reward token.
*   **Interactive Staking:** Users can spend resources (like the reward token) to influence their staked NFT's attributes.
*   **Dynamic Yield:** Reward rate potentially influenced by NFT attributes or staking duration.
*   **Delegation:** Users can delegate interaction rights for their staked NFTs.
*   **Upgrade Mechanics:** Simple on-chain upgrade system.
*   **Role-Based Access:** Owner/potentially governance functions.
*   **Basic Security:** Pausability, Reentrancy Guard.

This contract will manage the ERC721 logic for the dynamic attributes and staking state, and interact with a separate ERC20 reward token contract (whose address is provided).

---

## Smart Contract Outline: AuraBound Assets

This contract implements a system for dynamic, stakeable Non-Fungible Tokens (AuraBound Assets) that interact with a separate ERC-20 reward token.

1.  **License and Pragmas**
2.  **Imports:** ERC721, ERC20 (interface), Ownable, ReentrancyGuard, Pausable.
3.  **Error Handling:** Custom errors for clarity.
4.  **State Variables:**
    *   ERC-721 core storage (inherited).
    *   Dynamic NFT Attributes (mappings).
    *   Staking Information (structs and mappings).
    *   Reward Token Address.
    *   Reward Rate Parameters.
    *   Interaction Cooldowns.
    *   Upgrade Costs.
    *   Delegation Mapping.
    *   Counters.
5.  **Events:** Significant state changes (Mint, Stake, Unstake, ClaimReward, AttributeChange, Upgrade, ParameterUpdate, Delegate).
6.  **Modifiers:** Custom checks (e.g., `onlyStakedOwnerOrDelegate`, `whenAssetNotStaked`).
7.  **Constructor:** Initializes contract with token names, symbols, reward token address, and base parameters.
8.  **ERC721 Overrides:** Internal overrides to handle staking status during transfers.
9.  **Core Functionality:**
    *   Minting new assets.
    *   Staking assets.
    *   Unstaking assets.
    *   Claiming earned rewards.
    *   Querying pending rewards.
10. **Dynamic Interaction Functions (require staking):**
    *   `channelAura`: Consume 'Charge' attribute for potential benefit.
    *   `refineAffinity`: Spend reward tokens to attempt changing 'Affinity'.
11. **Upgrade Functionality:**
    *   `upgradeAsset`: Spend resources to improve NFT stats/level.
12. **Delegation Functionality:**
    *   `delegateInteractionRights`: Allow another address to use interaction functions on your staked assets.
    *   `revokeInteractionRights`: Remove delegation.
13. **Admin/Governance Functions:**
    *   Set reward rate parameters.
    *   Set interaction cooldowns.
    *   Set upgrade costs.
    *   Set base URI for metadata.
    *   Pause/Unpause critical functions.
    *   Emergency withdrawal of tokens.
14. **Query Functions (View/Pure):**
    *   Get asset attributes.
    *   Get staking information.
    *   Get staked token IDs for an owner.
    *   Calculate dynamic reward rate.
    *   Get interaction delegate.

## Function Summary

1.  `constructor`: Deploys the contract, setting names, symbols, reward token address, and initial parameters.
2.  `mint(address to, uint256 initialAffinity, uint256 initialCharge)`: Mints a new AuraBound Asset to `to` with initial attributes.
3.  `stake(uint256 tokenId)`: Allows the owner of `tokenId` to stake it in the contract, making it non-transferable externally and starting reward accumulation.
4.  `unstake(uint256 tokenId)`: Allows the original staker (or delegate) to unstake `tokenId`, transferring it back and stopping reward accumulation. May have time locks or fees.
5.  `claimRewards(uint256[] calldata tokenIds)`: Claims pending reward tokens for a list of staked assets owned by the caller.
6.  `getPendingRewards(uint256 tokenId) view`: Calculates the current pending reward tokens for a single staked `tokenId`.
7.  `getStakedTokenIdsForOwner(address owner) view`: Returns an array of token IDs currently staked by a specific address.
8.  `getStakeInfo(uint256 tokenId) view`: Returns details about the staking status of `tokenId` (staked, staker, start time).
9.  `getAssetAttributes(uint256 tokenId) view`: Returns the current dynamic attributes (Affinity, Charge, Level, etc.) for `tokenId`.
10. `calculateDynamicRewardRate(uint256 tokenId) view`: Calculates the current per-second reward rate for `tokenId` based on its attributes and global parameters.
11. `channelAura(uint256 tokenId)`: Allows the staker (or delegate) to use a staked asset's 'Channel Aura' ability. Consumes 'Charge', potentially affects state or yield temporarily. Subject to cooldown.
12. `refineAffinity(uint256 tokenId)`: Allows the staker (or delegate) to use a staked asset's 'Refine Affinity' ability. Requires spending reward tokens (or other resource). Attempts to change 'Affinity' attribute with a success chance. Subject to cooldown.
13. `upgradeAsset(uint256 tokenId)`: Allows the owner to upgrade `tokenId` (when *not* staked). Requires spending resources (e.g., reward tokens, other NFTs). Increases asset level and potentially max attributes.
14. `setRewardRateParams(uint256 baseRate, uint256 affinityMultiplier, uint256 chargeMultiplier)`: Owner/Admin function to update parameters affecting the dynamic reward rate calculation.
15. `setInteractionCooldowns(uint256 channelAuraCooldown, uint256 refineAffinityCooldown)`: Owner/Admin function to set cooldown durations for interaction abilities.
16. `setUpgradeCosts(uint256 rewardTokenCost)`: Owner/Admin function to set the cost of upgrading an asset.
17. `updateBaseURI(string memory newBaseURI)`: Owner function to update the base URI for metadata (off-chain attribute representation).
18. `pauseContract()`: Owner/Admin function to pause core functions (minting, staking, unstaking, interactions, claiming).
19. `unpauseContract()`: Owner/Admin function to unpause the contract.
20. `emergencyWithdrawERC20(address tokenAddress, uint256 amount)`: Owner function to withdraw unintended ERC20 tokens stuck in the contract (e.g., wrong token sent).
21. `emergencyWithdrawERC721(address tokenAddress, uint256 tokenId)`: Owner function to withdraw unintended ERC721 tokens stuck in the contract.
22. `delegateInteractionRights(uint256 tokenId, address delegatee)`: Allows the owner of a *staked* asset to grant `delegatee` permission to use `channelAura` and `refineAffinity` on that specific token.
23. `revokeInteractionRights(uint256 tokenId)`: Allows the owner of a *staked* asset to revoke any existing delegation for `tokenId`.
24. `getInteractionDelegate(uint256 tokenId) view`: Returns the address currently delegated interaction rights for `tokenId`.
25. `_calculateRewards(uint256 tokenId, uint256 endTime) internal view`: Internal helper to calculate rewards up to a specific time.

This gives us 25 functions, covering the core logic, dynamic aspects, interactions, delegation, upgrades, and admin controls.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol"; // Using SafeMath for simple arithmetic

// --- Smart Contract Outline: AuraBound Assets ---
// This contract implements a system for dynamic, stakeable Non-Fungible Tokens (AuraBound Assets)
// that interact with a separate ERC-20 reward token.
// 1. License and Pragmas
// 2. Imports
// 3. Error Handling
// 4. State Variables (including dynamic attributes, staking info, parameters)
// 5. Events
// 6. Modifiers
// 7. Constructor
// 8. ERC721 Overrides (Handling staking status)
// 9. Core Functionality (Mint, Stake, Unstake, Claim, Query Rewards/Stake Info)
// 10. Dynamic Interaction Functions (Channel Aura, Refine Affinity)
// 11. Upgrade Functionality (Upgrade Asset)
// 12. Delegation Functionality (Delegate, Revoke, Get Delegate)
// 13. Admin/Governance Functions (Set parameters, pause, emergency withdraw)
// 14. Query Functions (Get Attributes, Calculate Rate, Get Staked IDs)
// 15. Internal Helper Functions

// --- Function Summary ---
// 1.  constructor(string, string, address, string) - Deploys, sets base config.
// 2.  mint(address, uint256, uint256) - Mints a new asset with initial attributes.
// 3.  stake(uint256) - Stakes asset, transferring to contract, starts rewards.
// 4.  unstake(uint256) - Unstakes asset, transfers back, stops rewards.
// 5.  claimRewards(uint256[]) - Claims pending rewards for multiple staked assets.
// 6.  getPendingRewards(uint256) view - Calculates pending rewards for one asset.
// 7.  getStakedTokenIdsForOwner(address) view - Lists token IDs staked by owner.
// 8.  getStakeInfo(uint256) view - Gets detailed stake info for asset.
// 9.  getAssetAttributes(uint256) view - Gets dynamic attributes for asset.
// 10. calculateDynamicRewardRate(uint256) view - Calculates current reward rate for asset.
// 11. channelAura(uint256) - Interacts with staked asset: consumes Charge, potentially affects state/yield.
// 12. refineAffinity(uint256) - Interacts with staked asset: spends resource, attempts to change Affinity.
// 13. upgradeAsset(uint256) - Upgrades non-staked asset: spends resource, improves level/stats.
// 14. setRewardRateParams(uint256, uint256, uint256) - Admin: sets params for dynamic rate.
// 15. setInteractionCooldowns(uint256, uint256) - Admin: sets cooldowns for interactions.
// 16. setUpgradeCosts(uint256) - Admin: sets cost for upgrading.
// 17. updateBaseURI(string) - Admin: sets base URI for metadata.
// 18. pauseContract() - Admin: pauses core contract functions.
// 19. unpauseContract() - Admin: unpauses contract.
// 20. emergencyWithdrawERC20(address, uint256) - Admin: withdraws specified ERC20.
// 21. emergencyWithdrawERC721(address, uint256) - Admin: withdraws specified ERC721.
// 22. delegateInteractionRights(uint256, address) - Owner: delegates interaction rights for staked asset.
// 23. revokeInteractionRights(uint256) - Owner: revokes interaction delegation for staked asset.
// 24. getInteractionDelegate(uint256) view - Gets delegate address for staked asset.
// 25. _calculateRewards(uint256, uint256) internal view - Helper: calculates rewards between times.

contract AuraBoundAssets is ERC721, Ownable, ReentrancyGuard, Pausable {
    using Counters for Counters.Counter;
    using SafeMath for uint256;

    Counters.Counter private _tokenIdCounter;

    // --- Error Handling ---
    error NotStaked(uint256 tokenId);
    error AlreadyStaked(uint256 tokenId);
    error NotOwnerOfStaked(uint256 tokenId);
    error StakingPaused();
    error NotStakedOwnerOrDelegate(uint256 tokenId, address caller);
    error CooldownNotPassed(uint256 tokenId, uint256 remaining);
    error InsufficientResource(uint256 required, uint256 available);
    error AssetMustBeStaked(uint256 tokenId);
    error AssetMustNotBeStaked(uint256 tokenId);
    error DelegationAlreadyExists(uint256 tokenId);
    error NoActiveDelegation(uint256 tokenId);

    // --- State Variables ---

    // Dynamic NFT Attributes
    struct AssetAttributes {
        uint256 affinity; // Influences reward rate
        uint256 charge;   // Resource for interaction abilities
        uint256 level;    // Affects max stats, potential unlocks
        // Add more attributes as needed
        uint256 lastChannelAuraTime;
        uint256 lastRefineAffinityTime;
    }
    mapping(uint256 => AssetAttributes) private _assetAttributes;

    // Staking Information
    struct StakeInfo {
        address staker;
        uint64 stakeStartTime;
        uint128 accumulatedRewardsPerSecond; // Based on attributes at stake/last interaction time
        uint64 lastRewardClaimTime;
        bool isStaked;
    }
    mapping(uint256 => StakeInfo) private _stakeInfo;
    mapping(address => uint256[]) private _stakedTokensByOwner; // Helper for getStakedTokenIdsForOwner

    // Reward Token
    IERC20 public immutable rewardToken;

    // Reward Rate Parameters (Per Second) - Adjusted by admin/governance
    uint256 public baseRewardRatePerSecond;
    uint256 public affinityMultiplierPerSecond; // Rate increases per point of affinity
    // Add more multipliers if attributes other than affinity affect rate

    // Interaction Cooldowns (in seconds) - Adjusted by admin/governance
    uint256 public channelAuraCooldown;
    uint256 public refineAffinityCooldown;

    // Upgrade Costs - Adjusted by admin/governance
    uint256 public upgradeRewardTokenCost;

    // Delegation Mapping: tokenId => delegatee address for interaction rights
    mapping(uint256 => address) private _interactionDelegates;

    // --- Events ---
    event AssetMinted(uint256 indexed tokenId, address indexed owner, uint256 initialAffinity, uint256 initialCharge);
    event AssetStaked(uint256 indexed tokenId, address indexed staker, uint64 stakeStartTime);
    event AssetUnstaked(uint256 indexed tokenId, address indexed staker, uint64 unstakeTime);
    event RewardsClaimed(address indexed staker, uint256[] tokenIds, uint256 amount);
    event AssetAttributesChanged(uint256 indexed tokenId, string attributeName, uint256 oldValue, uint256 newValue);
    event AssetUpgraded(uint256 indexed tokenId, uint256 newLevel);
    event ParameterUpdated(string parameterName, uint256 oldValue, uint256 newValue);
    event InteractionDelegated(uint256 indexed tokenId, address indexed owner, address indexed delegatee);
    event InteractionRevoked(uint256 indexed tokenId, address indexed owner, address indexed revokedDelegatee);

    // --- Modifiers ---
    modifier onlyStaked(uint256 tokenId) {
        if (!_stakeInfo[tokenId].isStaked) revert NotStaked(tokenId);
        _;
    }

    modifier onlyStakedOwner(uint256 tokenId) {
        if (!_stakeInfo[tokenId].isStaked) revert NotStaked(tokenId);
        if (_stakeInfo[tokenId].staker != msg.sender) revert NotOwnerOfStaked(tokenId);
        _;
    }

    // Allows staker *or* delegated address to call
    modifier onlyStakedOwnerOrDelegate(uint256 tokenId) {
        if (!_stakeInfo[tokenId].isStaked) revert NotStaked(tokenId);
        bool isOwner = _stakeInfo[tokenId].staker == msg.sender;
        bool isDelegate = _interactionDelegates[tokenId] == msg.sender;
        if (!isOwner && !isDelegate) revert NotStakedOwnerOrDelegate(tokenId, msg.sender);
        _;
    }

    modifier whenAssetNotStaked(uint256 tokenId) {
        if (_stakeInfo[tokenId].isStaked) revert AssetMustNotBeStaked(tokenId);
        _;
    }

    // --- Constructor ---
    constructor(
        string memory name,
        string memory symbol,
        address _rewardTokenAddress,
        string memory baseURI
    ) ERC721(name, symbol) Ownable(msg.sender) Pausable(false) {
        require(_rewardTokenAddress != address(0), "Invalid reward token address");
        rewardToken = IERC20(_rewardTokenAddress);

        _setBaseURI(baseURI);

        // Set initial parameters (can be updated later by owner)
        baseRewardRatePerSecond = 1;       // Example: 1 token per second base
        affinityMultiplierPerSecond = 100; // Example: 100 tokens per second per affinity point
        channelAuraCooldown = 1 days;
        refineAffinityCooldown = 3 days;
        upgradeRewardTokenCost = 100000 ether; // Example: 100k reward tokens to upgrade
    }

    // --- ERC721 Overrides ---
    // Prevent transfer/approval for staked tokens
    function _update(address to, uint256 tokenId, address auth) internal override returns (address) {
         if (_stakeInfo[tokenId].isStaked) {
             // Allow transfers *from* this contract *to* the staker during unstake
             require(from(tokenId) == address(this), "Token is staked and cannot be transferred");
         }
        return super._update(to, tokenId, auth);
    }

    // Internal helper to get owner, needed since _ownerOf is internal in ERC721
    function from(uint256 tokenId) internal view returns (address) {
        return ERC721.ownerOf(tokenId);
    }

    // --- Core Functionality ---

    /// @notice Mints a new AuraBound Asset.
    /// @param to The address to mint the token to.
    /// @param initialAffinity The starting Affinity attribute value.
    /// @param initialCharge The starting Charge attribute value.
    function mint(address to, uint256 initialAffinity, uint256 initialCharge)
        external
        onlyOwner // Or a minter role modifier
        whenNotPaused
    {
        _tokenIdCounter.increment();
        uint256 newItemId = _tokenIdCounter.current();

        _safeMint(to, newItemId);

        _assetAttributes[newItemId] = AssetAttributes({
            affinity: initialAffinity,
            charge: initialCharge,
            level: 1, // Start at level 1
            lastChannelAuraTime: 0,
            lastRefineAffinityTime: 0
        });

        emit AssetMinted(newItemId, to, initialAffinity, initialCharge);
    }

    /// @notice Stakes an AuraBound Asset. Transfers token to contract, starts rewards.
    /// @param tokenId The ID of the token to stake.
    function stake(uint256 tokenId)
        external
        nonReentrant
        whenNotPaused
        whenAssetNotStaked(tokenId)
    {
        address owner = ownerOf(tokenId);
        require(owner == msg.sender, "Caller is not the owner");

        // Transfer the NFT to the contract
        safeTransferFrom(owner, address(this), tokenId);

        // Record staking information
        uint64 currentTime = uint64(block.timestamp);
        _stakeInfo[tokenId] = StakeInfo({
            staker: owner,
            stakeStartTime: currentTime,
            accumulatedRewardsPerSecond: uint128(calculateDynamicRewardRate(tokenId)), // Capture rate at stake time
            lastRewardClaimTime: currentTime, // Start calculation from now
            isStaked: true
        });

        // Add to staked tokens list for the staker
        _stakedTokensByOwner[owner].push(tokenId);

        emit AssetStaked(tokenId, owner, currentTime);
    }

    /// @notice Unstakes an AuraBound Asset. Transfers token back, stops rewards.
    /// @param tokenId The ID of the token to unstake.
    function unstake(uint256 tokenId)
        external
        nonReentrant
        whenNotPaused
        onlyStakedOwner(tokenId) // Only the original staker can unstake
    {
        StakeInfo storage stake = _stakeInfo[tokenId];
        uint256 staker = uint256(uint160(stake.staker)); // Use uint256 for findAndRemove

        // Claim any pending rewards before unstaking
        uint256 pending = _calculateRewards(tokenId, block.timestamp);
        if (pending > 0) {
             bool success = rewardToken.transfer(stake.staker, pending);
             require(success, "Reward token transfer failed");
             // Reset reward calculation basis for the period just ended
             stake.lastRewardClaimTime = uint64(block.timestamp);
             // Update accumulated rate based on *current* attributes *before* unstaking (if attributes changed while staked)
             // Alternatively, rate could be fixed at stake time. Let's update rate on unstake/claim for simplicity.
             stake.accumulatedRewardsPerSecond = uint128(calculateDynamicRewardRate(tokenId));
        }


        // Remove from staked tokens list
        _findAndRemoveStakedToken(msg.sender, tokenId); // msg.sender is verified staker by modifier

        // Clear staking information
        delete _stakeInfo[tokenId];
        delete _interactionDelegates[tokenId]; // Also revoke delegation on unstake

        // Transfer NFT back to staker
        // Use _safeTransfer to handle potential receiver contract logic
        _safeTransfer(address(this), msg.sender, tokenId);

        emit AssetUnstaked(tokenId, msg.sender, uint64(block.timestamp));
    }

    /// @notice Claims pending rewards for multiple staked assets.
    /// @param tokenIds An array of token IDs to claim rewards for.
    function claimRewards(uint256[] calldata tokenIds)
        external
        nonReentrant
        whenNotPaused
    {
        uint256 totalRewards = 0;
        address claimant = msg.sender; // Assume claimant is the staker or delegate

        for (uint i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            // Ensure token is staked and caller is the staker or delegate
            if (!_stakeInfo[tokenId].isStaked) continue; // Skip if not staked
            if (_stakeInfo[tokenId].staker != claimant && _interactionDelegates[tokenId] != claimant) continue; // Skip if not owner or delegate

            uint256 pending = _calculateRewards(tokenId, block.timestamp);

            if (pending > 0) {
                totalRewards = totalRewards.add(pending);
                // Update the last claim time for the individual stake
                _stakeInfo[tokenId].lastRewardClaimTime = uint64(block.timestamp);
                // Recalculate and update accumulated rate based on current attributes
                 _stakeInfo[tokenId].accumulatedRewardsPerSecond = uint128(calculateDynamicRewardRate(tokenId));
            }
        }

        if (totalRewards > 0) {
            bool success = rewardToken.transfer(claimant, totalRewards);
            require(success, "Reward token bulk transfer failed");
            emit RewardsClaimed(claimant, tokenIds, totalRewards);
        }
    }

    /// @notice Calculates the current pending reward tokens for a single staked asset.
    /// @param tokenId The ID of the staked token.
    /// @return The amount of pending reward tokens.
    function getPendingRewards(uint256 tokenId)
        public
        view
        onlyStaked(tokenId)
        returns (uint256)
    {
       return _calculateRewards(tokenId, block.timestamp);
    }

    /// @notice Gets an array of token IDs currently staked by a specific address.
    /// @param owner The address to query.
    /// @return An array of token IDs.
    function getStakedTokenIdsForOwner(address owner) public view returns (uint256[] memory) {
        return _stakedTokensByOwner[owner];
    }

    /// @notice Gets details about the staking status of a token.
    /// @param tokenId The ID of the token.
    /// @return A StakeInfo struct containing staker, start time, and status.
    function getStakeInfo(uint256 tokenId) public view returns (StakeInfo memory) {
        return _stakeInfo[tokenId];
    }

    /// @notice Gets the current dynamic attributes for a token.
    /// @param tokenId The ID of the token.
    /// @return An AssetAttributes struct.
    function getAssetAttributes(uint256 tokenId) public view returns (AssetAttributes memory) {
        return _assetAttributes[tokenId];
    }

     /// @notice Calculates the current per-second reward rate for a token based on its attributes.
     /// @param tokenId The ID of the token.
     /// @return The calculated reward rate per second.
    function calculateDynamicRewardRate(uint256 tokenId) public view returns (uint256) {
        AssetAttributes storage attrs = _assetAttributes[tokenId];
        uint256 rate = baseRewardRatePerSecond;
        rate = rate.add(attrs.affinity.mul(affinityMultiplierPerSecond));
        // Add more attribute-based multipliers here if needed
        return rate;
    }


    // --- Dynamic Interaction Functions (require staking) ---

    /// @notice Uses a staked asset's 'Channel Aura' ability. Consumes Charge.
    /// @param tokenId The ID of the staked token.
    function channelAura(uint256 tokenId)
        external
        nonReentrant // If this function could potentially lead to token transfers/external calls
        whenNotPaused
        onlyStakedOwnerOrDelegate(tokenId)
        onlyStaked(tokenId) // Redundant due to onlyStakedOwnerOrDelegate, but explicit
    {
        AssetAttributes storage attrs = _assetAttributes[tokenId];
        uint64 currentTime = uint64(block.timestamp);

        // Check cooldown
        uint256 timeSinceLast = currentTime - attrs.lastChannelAuraTime;
        if (timeSinceLast < channelAuraCooldown) {
            revert CooldownNotPassed(tokenId, channelAraftAuraCooldown - timeSinceLast);
        }

        // Require minimum charge to use
        uint256 chargeCost = 10; // Example cost
        if (attrs.charge < chargeCost) {
             revert InsufficientResource(chargeCost, attrs.charge);
        }

        // Apply effect: Consume charge
        uint256 oldCharge = attrs.charge;
        attrs.charge = attrs.charge.sub(chargeCost);
        attrs.lastChannelAuraTime = currentTime;

        emit AssetAttributesChanged(tokenId, "charge", oldCharge, attrs.charge);
        // Add other effects here: e.g., temporary reward boost, chance for attribute gain, etc.
        // If reward rate changes, update the accumulated rate in stakeInfo *immediately*
        // or ensure _calculateRewards uses current attributes. Let's update stakeInfo.
        _stakeInfo[tokenId].accumulatedRewardsPerSecond = uint128(calculateDynamicRewardRate(tokenId));
    }

    /// @notice Uses a staked asset's 'Refine Affinity' ability. Requires spending reward tokens.
    /// @param tokenId The ID of the staked token.
    function refineAffinity(uint256 tokenId)
        external
        nonReentrant // Important if reward token transfer fails before state update
        whenNotPaused
        onlyStakedOwnerOrDelegate(tokenId)
        onlyStaked(tokenId) // Redundant due to onlyStakedOwnerOrDelegate, but explicit
    {
        AssetAttributes storage attrs = _assetAttributes[tokenId];
        uint64 currentTime = uint64(block.timestamp);

        // Check cooldown
        uint256 timeSinceLast = currentTime - attrs.lastRefineAffinityTime;
        if (timeSinceLast < refineAffinityCooldown) {
            revert CooldownNotPassed(tokenId, refineAffinityCooldown - timeSinceLast);
        }

        // Require spending reward tokens
        uint256 refineCost = 50 ether; // Example cost in reward tokens
        address staker = _stakeInfo[tokenId].staker; // Resource must come from the staker, not delegate
        require(rewardToken.balanceOf(staker) >= refineCost, "Staker does not have enough reward tokens");

        // Transfer cost from staker
        // Note: This requires the staker to have approved THIS contract to spend reward tokens
        bool success = rewardToken.transferFrom(staker, address(this), refineCost);
        require(success, "Reward token transferFrom failed");

        // Apply effect: Attempt to change Affinity with a success chance
        // NOTE: Using blockhash is NOT truly random and can be manipulated by miners.
        // For production, use Chainlink VRF or similar verifiable randomness solution.
        uint256 randomNumber = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, msg.sender, tokenId))) % 100; // 0-99
        uint256 successChance = 60; // Example: 60% chance of success

        uint256 oldAffinity = attrs.affinity;
        if (randomNumber < successChance) {
            // Success: Increase Affinity (within a cap maybe?)
            attrs.affinity = attrs.affinity.add(1); // Example: +1 Affinity
            emit AssetAttributesChanged(tokenId, "affinity", oldAffinity, attrs.affinity);
             // Recalculate and update accumulated rate based on new attributes
            _stakeInfo[tokenId].accumulatedRewardsPerSecond = uint128(calculateDynamicRewardRate(tokenId));
        } else {
            // Failure: Maybe decrease Affinity or Charge as a penalty
            // For simplicity, let's just have no change on failure here.
            emit AssetAttributesChanged(tokenId, "affinity", oldAffinity, oldAffinity); // Still emit event for failed attempt
        }

        attrs.lastRefineAffinityTime = currentTime;
    }

    // --- Upgrade Functionality ---

    /// @notice Allows the owner to upgrade an asset (when not staked).
    /// @param tokenId The ID of the token to upgrade.
    function upgradeAsset(uint256 tokenId)
        external
        nonReentrant // If cost involves token transfers
        whenNotPaused
        whenAssetNotStaked(tokenId)
    {
        require(ownerOf(tokenId) == msg.sender, "Caller is not the owner");
        AssetAttributes storage attrs = _assetAttributes[tokenId];

        // Require spending reward tokens
        require(rewardToken.balanceOf(msg.sender) >= upgradeRewardTokenCost, "Not enough reward tokens to upgrade");

        // Transfer cost from owner
        // Requires owner to have approved THIS contract to spend reward tokens
        bool success = rewardToken.transferFrom(msg.sender, address(this), upgradeRewardTokenCost);
        require(success, "Reward token transferFrom failed for upgrade cost");

        // Apply upgrade effects
        uint256 oldLevel = attrs.level;
        attrs.level = attrs.level.add(1);
        // Example: Increase max charge capacity or refine affinity success chance based on level
        // This example is simple, actual implementation would need more complex state/logic

        emit AssetUpgraded(tokenId, attrs.level);
    }

    // --- Delegation Functionality ---

    /// @notice Allows the owner of a *staked* asset to delegate interaction rights to another address.
    /// @param tokenId The ID of the staked token.
    /// @param delegatee The address to delegate rights to. Address(0) clears delegation.
    function delegateInteractionRights(uint256 tokenId, address delegatee)
        external
        onlyStakedOwner(tokenId) // Only the staker can delegate
        whenNotPaused
    {
        address oldDelegate = _interactionDelegates[tokenId];
        if (delegatee != address(0) && oldDelegate != address(0)) revert DelegationAlreadyExists(tokenId);
        if (delegatee == address(0) && oldDelegate == address(0)) revert NoActiveDelegation(tokenId); // Can't revoke if none exists

        _interactionDelegates[tokenId] = delegatee;
        emit InteractionDelegated(tokenId, msg.sender, delegatee);
    }

    /// @notice Allows the owner of a *staked* asset to revoke any existing delegation.
    /// @param tokenId The ID of the staked token.
    function revokeInteractionRights(uint256 tokenId)
        external
        onlyStakedOwner(tokenId) // Only the staker can revoke
        whenNotPaused
    {
        address revokedDelegatee = _interactionDelegates[tokenId];
        if (revokedDelegatee == address(0)) revert NoActiveDelegation(tokenId);

        delete _interactionDelegates[tokenId];
        emit InteractionRevoked(tokenId, msg.sender, revokedDelegatee);
    }

    /// @notice Gets the address currently delegated interaction rights for a staked asset.
    /// @param tokenId The ID of the staked token.
    /// @return The delegatee address, or Address(0) if no delegation exists.
    function getInteractionDelegate(uint256 tokenId)
        public
        view
        onlyStaked(tokenId)
        returns (address)
    {
        return _interactionDelegates[tokenId];
    }


    // --- Admin/Governance Functions ---

    /// @notice Sets the parameters for the dynamic reward rate calculation.
    /// @param baseRate The new base reward rate per second.
    /// @param affinityMultiplier The new multiplier per affinity point per second.
    function setRewardRateParams(uint256 baseRate, uint256 affinityMultiplier) external onlyOwner {
        emit ParameterUpdated("baseRewardRatePerSecond", baseRewardRatePerSecond, baseRate);
        emit ParameterUpdated("affinityMultiplierPerSecond", affinityMultiplierPerSecond, affinityMultiplier);
        baseRewardRatePerSecond = baseRate;
        affinityMultiplierPerSecond = affinityMultiplier;
        // Note: This change affects future reward calculation periods.
        // Existing accumulatedRewardsPerSecond on stakes are updated on claim/unstake.
    }

    /// @notice Sets the cooldown durations for interaction abilities.
    /// @param _channelAuraCooldown Cooldown for Channel Aura (in seconds).
    /// @param _refineAffinityCooldown Cooldown for Refine Affinity (in seconds).
    function setInteractionCooldowns(uint256 _channelAuraCooldown, uint256 _refineAffinityCooldown) external onlyOwner {
         emit ParameterUpdated("channelAuraCooldown", channelAuraCooldown, _channelAuraCooldown);
         emit ParameterUpdated("refineAffinityCooldown", refineAffinityCooldown, _refineAffinityCooldown);
         channelAuraCooldown = _channelAuraCooldown;
         refineAffinityCooldown = _refineAffinityCooldown;
    }

     /// @notice Sets the cost of upgrading an asset in reward tokens.
     /// @param rewardTokenCost The new cost in reward tokens (with decimals).
     function setUpgradeCosts(uint256 rewardTokenCost) external onlyOwner {
         emit ParameterUpdated("upgradeRewardTokenCost", upgradeRewardTokenCost, rewardTokenCost);
         upgradeRewardTokenCost = rewardTokenCost;
     }


    /// @notice Updates the base URI for the NFT metadata.
    /// @param newBaseURI The new base URI string.
    function updateBaseURI(string memory newBaseURI) external onlyOwner {
        _setBaseURI(newBaseURI);
    }

    /// @notice Pauses core functions (minting, staking, unstaking, interactions, claiming).
    function pauseContract() external onlyOwner {
        _pause();
    }

    /// @notice Unpauses the contract.
    function unpauseContract() external onlyOwner {
        _unpause();
    }

    /// @notice Allows the owner to withdraw unintended ERC20 tokens.
    /// @param tokenAddress The address of the ERC20 token.
    /// @param amount The amount to withdraw.
    function emergencyWithdrawERC20(address tokenAddress, uint256 amount) external onlyOwner {
        require(tokenAddress != address(rewardToken), "Cannot withdraw reward token via emergency"); // Prevent draining reward pool
        IERC20 token = IERC20(tokenAddress);
        token.transfer(owner(), amount);
    }

    /// @notice Allows the owner to withdraw unintended ERC721 tokens.
    /// @param tokenAddress The address of the ERC721 token.
    /// @param tokenId The ID of the token to withdraw.
    function emergencyWithdrawERC721(address tokenAddress, uint256 tokenId) external onlyOwner {
         require(tokenAddress != address(this), "Cannot withdraw self via emergency"); // Prevent accidental self-locking
         ERC721 otherToken = ERC721(tokenAddress);
         otherToken.transferFrom(address(this), owner(), tokenId);
    }


    // --- Internal Helper Functions ---

    /// @dev Calculates rewards for a staked token between its last claim time and a specified end time.
    /// @param tokenId The ID of the staked token.
    /// @param endTime The timestamp up to which to calculate rewards.
    /// @return The calculated reward amount.
    function _calculateRewards(uint256 tokenId, uint256 endTime) internal view returns (uint256) {
        StakeInfo memory stake = _stakeInfo[tokenId];
        if (!stake.isStaked) return 0;

        uint256 lastClaimTime = stake.lastRewardClaimTime;
        // If end time is before or same as last claim time, no new rewards
        if (endTime <= lastClaimTime) return 0;

        uint256 duration = endTime - lastClaimTime;

        // Use the rate captured at the start of the period (last claim/stake time)
        // Or, recalculate based on current attributes? Let's use the captured rate for simplicity
        // and update the captured rate only on claim/unstake.
        uint256 rate = stake.accumulatedRewardsPerSecond;

        return rate.mul(duration);
    }

    /// @dev Finds and removes a tokenId from a staker's staked tokens array.
    /// @param staker The address of the staker.
    /// @param tokenIdToRemove The token ID to remove.
    function _findAndRemoveStakedToken(address staker, uint256 tokenIdToRemove) internal {
        uint256[] storage tokens = _stakedTokensByOwner[staker];
        uint256 len = tokens.length;
        for (uint i = 0; i < len; i++) {
            if (tokens[i] == tokenIdToRemove) {
                // Replace with the last element and pop
                tokens[i] = tokens[len - 1];
                tokens.pop();
                return;
            }
        }
        // Should not happen if logic is correct, but handle defensively
        revert("Token not found in staker's list");
    }

    // --- Pausable Overrides ---
    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
        // Allow transfers TO the contract for staking and FROM the contract for unstaking/emergency
        if (from != address(0) && to != address(this) && from != address(this)) {
             // Check if paused for regular transfers by owner/approved
             // Staked tokens are blocked by _update override anyway
             if (paused()) revert Pausable.EnforcedPause();
        }
    }

    // --- ERC721 Required Overrides (even if not used heavily due to staking) ---
    // The ERC721 standard functions like `ownerOf`, `balanceOf`, `transferFrom`, etc.
    // are inherited and handle basic ownership and transfer logic.
    // Our custom logic for staking manages the *state* of being staked and prevents
    // transfers *out* of the contract's ownership if the token is marked as staked.
    // The `_update` override is key to enforcing the "staked" state.

    // No need to explicitly list all 10-15 standard ERC721 functions here as they are inherited.
    // The *creative* functions are the ones we've defined above (mint, stake, unstake, claim, interactions, etc.)

}
```