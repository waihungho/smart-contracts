Okay, here is a Solidity smart contract implementing a creative and relatively advanced concept: an **Evolutionary Yield NFT Staking Pool**.

This contract allows users to stake an approved ERC-20 token to earn yield, similar to traditional yield farming. However, instead of receiving a simple LP token or just having their balance tracked, they receive a *dynamic* NFT. This NFT represents their specific staking position and its traits (like "level", "duration", "reward multiplier") can *evolve* on-chain based on factors like stake duration, amount, and accumulated rewards.

It includes features like:
1.  **Yield Staking:** Standard deposit, withdraw, claim.
2.  **Dynamic NFTs (ERC721):** An NFT represents the stake. Its metadata/traits can change.
3.  **On-Chain Trait Calculation:** Traits are derived from the staking position's history.
4.  **NFT Merging:** Combine two staking positions/NFTs into a single, potentially higher-level NFT.
5.  **NFT Splitting:** Split a staking position/NFT into two.
6.  **Position Delegation:** Delegate management (stake/claim) or trait updates of an NFT position to another address.
7.  **Role-Based Access Control:** Specific roles for admin, trait updaters, etc.
8.  **Pausable:** Ability to pause core actions.
9.  **Early Unstake Fee:** A configurable fee applied if unstaking before a minimum duration, which could also affect NFT traits.

This concept combines DeFi staking with dynamic NFTs and adds complex on-chain mechanics (merge/split, delegation, trait evolution) that go beyond typical implementations.

---

### Smart Contract: Evolutionary Yield NFT Staking Pool

**Outline:**

1.  **Pragma and Imports:** Specify Solidity version and import necessary OpenZeppelin contracts (ERC721, AccessControl, Pausable, Ownable - or AccessControl alone, let's use AccessControl for better role management, ERC721, Pausable). Import SafeERC20.
2.  **Errors:** Custom error definitions.
3.  **Events:** Events for key actions (Deposit, Withdraw, Claim, Merge, Split, TraitUpdate, Delegation).
4.  **Interfaces:** (None explicitly needed beyond inherited ERC721, AccessControl, Pausable).
5.  **Structs:** Define structs for `StakingPosition` and `NFTTraits`.
6.  **Constants:** Define role bytes32 constants.
7.  **State Variables:**
    *   Approved Staking Token address (`stakingToken`).
    *   Reward Token address (`rewardToken`).
    *   Mapping from tokenId to `StakingPosition`.
    *   Mapping from tokenId to `NFTTraits`.
    *   Mapping for management delegation (`tokenId => address`).
    *   Mapping for trait update delegation (`tokenId => address`).
    *   Next available token ID counter.
    *   Total staked amount.
    *   Reward rate per second (or other time unit).
    *   Fee rate (basis points).
    *   Minimum stake duration for no fee.
    *   Role definitions (`AccessControl`).
8.  **Constructor:** Initialize tokens, roles, initial parameters.
9.  **Modifiers:** `onlyStakerOrDelegatedManager`, `onlyTraitUpdaterOrDelegated`.
10. **Internal Helper Functions:**
    *   `_calculateRewards`: Calculate pending rewards for a position.
    *   `_updatePositionRewardTime`: Update last reward time and add pending rewards to balance.
    *   `_updateNFTTraits`: Logic to calculate/set traits based on position data.
    *   `_mintPosition`: Internal function to mint NFT and create position.
    *   `_burnPosition`: Internal function to burn NFT and remove position.
    *   `_getFee`: Calculate early unstake fee.
11. **External/Public Functions (Core Logic):**
    *   `deposit`: Stake tokens, mint NFT position.
    *   `withdraw`: Unstake tokens, burn NFT if full withdraw.
    *   `claimRewards`: Claim accumulated rewards.
    *   `compoundRewards`: Claim and restake rewards into the same position.
12. **External/Public Functions (View/Getters):**
    *   `getPendingRewards`: View function for rewards.
    *   `getStakedAmount`: View function for amount staked in a specific NFT position.
    *   `getTotalStaked`: View total tokens staked in the contract.
    *   `getNFTTraits`: View function for current traits of an NFT.
    *   `calculateEarlyUnstakeFee`: View potential fee.
    *   `getDelegatedManager`: Get delegated manager for an NFT.
    *   `getDelegatedTraitUpdater`: Get delegated trait updater for an NFT.
13. **External/Public Functions (Advanced/Creative):**
    *   `updateNFTTraits`: Manually trigger trait update (requires role/delegation).
    *   `mergeNFTs`: Merge two staking positions/NFTs.
    *   `splitNFT`: Split one staking position/NFT into two.
    *   `delegatePositionManagement`: Delegate stake/claim/compound actions for an NFT.
    *   `revokePositionManagementDelegation`: Revoke management delegation.
    *   `delegateTraitUpdate`: Delegate permission to update traits for an NFT.
    *   `revokeTraitUpdateDelegation`: Revoke trait update delegation.
14. **External/Public Functions (Admin/Roles/Pausable):**
    *   `setRewardRate`: Set the global reward rate.
    *   `setFeeRate`: Set the early unstake fee rate.
    *   `setMinStakeDuration`: Set minimum duration for no fee.
    *   `grantRole`: Admin grants role.
    *   `revokeRole`: Admin revokes role.
    *   `renounceRole`: User renounces role.
    *   `pause`: Pause actions.
    *   `unpause`: Unpause actions.
    *   `emergencyAdminWithdraw`: Admin can withdraw tokens in emergency.
    *   `withdrawAdminFees`: Admin can withdraw collected fees.
15. **ERC721 & AccessControl Overrides/Implementations:**
    *   `tokenURI`: Generate metadata JSON (including traits).
    *   `supportsInterface`: ERC165 standard.
    *   Override `_beforeTokenTransfer` or similar if needed for logic around transfer of staked NFTs (e.g., transfer might transfer the stake too, which is standard ERC721 behavior for staked NFTs).
    *   Implement `_authorizeUpgrade` if using UUPS proxies (optional, not included in this example for simplicity).

**Function Summary (27+ Functions):**

1.  `constructor()`: Initializes the contract, sets token addresses, grants default admin role.
2.  `deposit(uint256 amount)`: Stakes `amount` of `stakingToken` for the caller, mints a new unique NFT representing the position.
3.  `withdraw(uint256 tokenId, uint256 amount)`: Unstakes `amount` from the position represented by `tokenId`. Applies early unstake fee if applicable. Burns the NFT if the remaining stake is zero.
4.  `claimRewards(uint256 tokenId)`: Calculates and transfers pending `rewardToken` to the owner (or delegated manager) of the `tokenId`.
5.  `compoundRewards(uint256 tokenId)`: Calculates and restakes pending `rewardToken` back into the position represented by `tokenId`, increasing the staked amount.
6.  `getPendingRewards(uint256 tokenId)`: Pure view function calculating the current pending rewards for a position without side effects.
7.  `getStakedAmount(uint256 tokenId)`: View function returning the amount of `stakingToken` currently staked in a specific NFT position.
8.  `getTotalStaked()`: View function returning the total amount of `stakingToken` staked across all positions in the contract.
9.  `getNFTTraits(uint256 tokenId)`: View function returning the current calculated traits for a specific NFT position.
10. `calculateEarlyUnstakeFee(uint256 tokenId, uint256 amountToWithdraw)`: View function to estimate the fee for withdrawing a specific amount from a position at the current time.
11. `updateNFTTraits(uint256 tokenId)`: Explicitly triggers the on-chain calculation and update of the traits for a specific NFT. Callable by the owner, delegated trait updater, or admin.
12. `mergeNFTs(uint256 tokenId1, uint256 tokenId2)`: Merges the staking positions of `tokenId1` and `tokenId2` into `tokenId1`. Requires caller to own or manage both. Burns `tokenId2`.
13. `splitNFT(uint256 tokenId, uint256 amountToSplit)`: Splits `amountToSplit` from the stake of `tokenId` into a new position with a newly minted NFT. Requires caller to own or manage `tokenId`.
14. `delegatePositionManagement(uint256 tokenId, address manager)`: Delegates the ability to call `withdraw`, `claimRewards`, and `compoundRewards` for `tokenId` to `manager`. Callable only by the NFT owner.
15. `revokePositionManagementDelegation(uint256 tokenId)`: Removes any existing management delegation for `tokenId`. Callable only by the NFT owner.
16. `delegateTraitUpdate(uint256 tokenId, address updater)`: Delegates the ability to call `updateNFTTraits` for `tokenId` to `updater`. Callable only by the NFT owner.
17. `revokeTraitUpdateDelegation(uint256 tokenId)`: Removes any existing trait update delegation for `tokenId`. Callable only by the NFT owner.
18. `getDelegatedManager(uint256 tokenId)`: View function to see who is delegated to manage a specific NFT position.
19. `getDelegatedTraitUpdater(uint256 tokenId)`: View function to see who is delegated to update traits for a specific NFT position.
20. `setRewardRate(uint256 newRate)`: Admin function to set the reward rate (e.g., per second).
21. `setFeeRate(uint16 newFeeRateBp)`: Admin function to set the early unstake fee rate in basis points (e.g., 100 = 1%).
22. `setMinStakeDuration(uint256 newDuration)`: Admin function to set the minimum stake duration required to avoid the early unstake fee.
23. `grantRole(bytes32 role, address account)`: Admin function to grant a role (e.g., `TRAIT_UPDATER_ROLE`) to an address. (Inherited from AccessControl)
24. `revokeRole(bytes32 role, address account)`: Admin function to revoke a role. (Inherited from AccessControl)
25. `renounceRole(bytes32 role)`: Allows an account to remove a role from themselves. (Inherited from AccessControl)
26. `pause()`: Admin function to pause staking, withdrawing, claiming, compounding, merging, and splitting. (Inherited from Pausable)
27. `unpause()`: Admin function to unpause actions. (Inherited from Pausable)
28. `emergencyAdminWithdraw(address tokenAddress, uint256 amount)`: Admin function to withdraw stuck tokens (ERC20) from the contract in emergency (use with caution).
29. `withdrawAdminFees(address recipient)`: Admin function to withdraw accumulated fees (e.g., from early unstake) to a recipient.
30. `tokenURI(uint256 tokenId)`: Standard ERC721 function to get the metadata URI for an NFT. (Inherited from ERC721, overridden here).
31. `supportsInterface(bytes4 interfaceId)`: Standard ERC165 function. (Inherited from ERC721 and AccessControl).
32. `name()`: Standard ERC721 function. (Inherited from ERC721)
33. `symbol()`: Standard ERC721 function. (Inherited from ERC721)
34. `balanceOf(address owner)`: Standard ERC721 function. (Inherited from ERC721)
35. `ownerOf(uint256 tokenId)`: Standard ERC721 function. (Inherited from ERC721)
36. `approve(address to, uint256 tokenId)`: Standard ERC721 function. (Inherited from ERC721)
37. `getApproved(uint256 tokenId)`: Standard ERC721 function. (Inherited from ERC721)
38. `setApprovalForAll(address operator, bool approved)`: Standard ERC721 function. (Inherited from ERC721)
39. `isApprovedForAll(address owner, address operator)`: Standard ERC721 function. (Inherited from ERC721)
40. `transferFrom(address from, address to, uint256 tokenId)`: Standard ERC721 function. (Inherited from ERC721)
41. `safeTransferFrom(address from, address to, uint256 tokenId)`: Standard ERC721 function (2 variants). (Inherited from ERC721)
    *   *(Note: Many standard ERC721/AccessControl/Pausable functions are inherited, contributing to the total count well over 20, while the custom logic provides the unique features).*

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Base64.sol";
import "@openzeppelin/contracts/utils/math/Math.sol"; // For min/max if needed, or use built-in

// --- Outline ---
// 1. Pragma and Imports
// 2. Errors
// 3. Events
// 4. Structs
// 5. Constants (Roles)
// 6. State Variables
// 7. Constructor
// 8. Modifiers
// 9. Internal Helper Functions
// 10. External/Public Functions (Core Logic)
// 11. External/Public Functions (View/Getters)
// 12. External/Public Functions (Advanced/Creative)
// 13. External/Public Functions (Admin/Roles/Pausable)
// 14. ERC721 & AccessControl Overrides/Implementations

// --- Function Summary (30+ Functions) ---
// 1. constructor(address _stakingToken, address _rewardToken)
// 2. deposit(uint256 amount) - Stake tokens, mint NFT position
// 3. withdraw(uint256 tokenId, uint256 amount) - Unstake tokens, burn NFT if zero stake, handle fee
// 4. claimRewards(uint256 tokenId) - Claim accumulated rewards for a position
// 5. compoundRewards(uint256 tokenId) - Claim and restake rewards into same position
// 6. getPendingRewards(uint256 tokenId) - View function for rewards
// 7. getStakedAmount(uint256 tokenId) - View function for amount staked in an NFT position
// 8. getTotalStaked() - View function for total tokens staked in the contract
// 9. getNFTTraits(uint256 tokenId) - View function for current traits of an NFT
// 10. calculateEarlyUnstakeFee(uint256 tokenId, uint256 amountToWithdraw) - View potential fee
// 11. updateNFTTraits(uint256 tokenId) - Manually trigger trait update (requires role/delegation)
// 12. mergeNFTs(uint256 tokenId1, uint256 tokenId2) - Merge two staking positions/NFTs
// 13. splitNFT(uint256 tokenId, uint256 amountToSplit) - Split one staking position/NFT into two
// 14. delegatePositionManagement(uint256 tokenId, address manager) - Delegate stake/claim/compound actions
// 15. revokePositionManagementDelegation(uint256 tokenId) - Revoke management delegation
// 16. delegateTraitUpdate(uint256 tokenId, address updater) - Delegate trait update permission
// 17. revokeTraitUpdateDelegation(uint256 tokenId) - Revoke trait update delegation
// 18. getDelegatedManager(uint256 tokenId) - View delegated manager
// 19. getDelegatedTraitUpdater(uint256 tokenId) - View delegated trait updater
// 20. setRewardRate(uint256 newRate) - Admin set reward rate
// 21. setFeeRate(uint16 newFeeRateBp) - Admin set early unstake fee rate (basis points)
// 22. setMinStakeDuration(uint256 newDuration) - Admin set min duration for no fee
// 23. grantRole(bytes32 role, address account) - Admin grant role (Inherited AccessControl)
// 24. revokeRole(bytes32 role, address account) - Admin revoke role (Inherited AccessControl)
// 25. renounceRole(bytes32 role) - User renounce role (Inherited AccessControl)
// 26. pause() - Admin pause actions (Inherited Pausable)
// 27. unpause() - Admin unpause actions (Inherited Pausable)
// 28. emergencyAdminWithdraw(address tokenAddress, uint256 amount) - Admin withdraw stuck tokens
// 29. withdrawAdminFees(address recipient) - Admin withdraw accumulated fees
// 30. tokenURI(uint256 tokenId) - ERC721 metadata URI (Override)
// 31. supportsInterface(bytes4 interfaceId) - ERC165 standard (Inherited)
// 32. name() - ERC721 standard (Inherited)
// 33. symbol() - ERC721 standard (Inherited)
// 34. balanceOf(address owner) - ERC721 standard (Inherited)
// 35. ownerOf(uint256 tokenId) - ERC721 standard (Inherited)
// 36. approve(address to, uint256 tokenId) - ERC721 standard (Inherited)
// 37. getApproved(uint256 tokenId) - ERC721 standard (Inherited)
// 38. setApprovalForAll(address operator, bool approved) - ERC721 standard (Inherited)
// 39. isApprovedForAll(address owner, address operator) - ERC721 standard (Inherited)
// 40. transferFrom(address from, address to, uint256 tokenId) - ERC721 standard (Inherited)
// 41. safeTransferFrom(address from, address to, uint256 tokenId) - ERC721 standard (2 variants) (Inherited)

contract EvolutionaryYieldNFTStake is ERC721, AccessControl, Pausable {
    using SafeERC20 for IERC20;
    using Counters for Counters.Counter;
    using Strings for uint256;

    bytes32 public constant TRAIT_UPDATER_ROLE = keccak256("TRAIT_UPDATER_ROLE");
    bytes32 public constant FEE_COLLECTOR_ROLE = keccak256("FEE_COLLECTOR_ROLE"); // Admin by default can collect fees

    // --- Errors ---
    error InvalidAmount();
    error ERC20TransferFailed();
    error NotStakerOrDelegatedManager();
    error NotTraitUpdaterOrDelegated();
    error InvalidTokenId();
    error TokenIdNotOwnedByCaller();
    error TokenIdNotOwnedByAddress(address owner, uint256 tokenId);
    error InsufficientStake();
    error ZeroStakeAfterWithdraw();
    error CannotMergeSelf();
    error TokensMustBeOwnedBySameAccount();
    error SplitAmountTooLarge();
    error ZeroAddressNotAllowed();
    error NothingToWithdraw();

    // --- Events ---
    event Staked(address indexed staker, uint256 tokenId, uint256 amount);
    event Unstaked(address indexed staker, uint256 tokenId, uint256 amount, uint256 feePaid);
    event RewardsClaimed(address indexed staker, uint256 tokenId, uint256 rewardAmount);
    event RewardsCompounded(address indexed staker, uint256 tokenId, uint256 rewardAmount);
    event NFTTraitsUpdated(uint256 indexed tokenId, NFTTraits traits);
    event PositionMerged(uint256 indexed tokenId1, uint256 indexed tokenId2, uint256 newTokenId); // newTokenId will be tokenId1
    event PositionSplit(uint256 indexed originalTokenId, uint256 indexed newTokenId, uint256 splitAmount);
    event ManagementDelegated(uint256 indexed tokenId, address indexed delegator, address indexed manager);
    event TraitUpdateDelegated(uint256 indexed tokenId, address indexed delegator, address indexed updater);
    event FeeCollected(address indexed recipient, uint256 amount);
    event RewardRateUpdated(uint256 oldRate, uint256 newRate);
    event FeeRateUpdated(uint16 oldRate, uint16 newRate);
    event MinStakeDurationUpdated(uint256 oldDuration, uint256 newDuration);


    // --- Structs ---
    struct StakingPosition {
        address owner; // Current owner of the NFT
        uint256 amount;
        uint256 startTime;
        uint256 lastRewardTime;
        uint256 unclaimedRewards; // Rewards accumulated since last claim/compound
    }

    // Example dynamic traits - these would evolve
    struct NFTTraits {
        uint8 level; // Based on duration and amount
        uint16 durationMultiplierBp; // Bonus based on stake duration (basis points)
        uint8 rewardBoostPercentage; // Percentage boost on yield
        uint256 totalCompounded; // Total rewards compounded into this position
    }

    // --- State Variables ---
    IERC20 public immutable stakingToken;
    IERC20 public immutable rewardToken;

    mapping(uint256 => StakingPosition) private _stakingPositions;
    mapping(uint256 => NFTTraits) private _nftTraits;

    mapping(uint256 => address) private _delegatedManager; // tokenId => manager address
    mapping(uint256 => address) private _delegatedTraitUpdater; // tokenId => trait updater address

    Counters.Counter private _nextTokenId;
    uint256 public totalStaked;

    uint256 public rewardRatePerSecond; // Rewards issued per second per unit of stake (e.g., per 1e18)
    uint16 public earlyUnstakeFeeRateBp; // Fee rate in basis points (e.g., 100 = 1%)
    uint256 public minStakeDuration; // Minimum duration in seconds to avoid fee

    uint256 public accumulatedFees;

    // --- Constructor ---
    constructor(address _stakingToken, address _rewardToken)
        ERC721("EvolutionaryYieldNFT", "EYNFT")
        Pausable()
        AccessControl()
    {
        if (_stakingToken == address(0) || _rewardToken == address(0)) revert ZeroAddressNotAllowed();

        stakingToken = IERC20(_stakingToken);
        rewardToken = IERC20(_rewardToken);

        // Grant the deployer the default admin role
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        // Grant admin the trait updater and fee collector roles initially
        _grantRole(TRAIT_UPDATER_ROLE, msg.sender);
        _grantRole(FEE_COLLECTOR_ROLE, msg.sender);

        rewardRatePerSecond = 1000; // Example: 1000 wei of reward token per second per 1e18 staked
        earlyUnstakeFeeRateBp = 500; // Example: 5% fee
        minStakeDuration = 90 days; // Example: Minimum 90 days stake
    }

    // --- Modifiers ---
    modifier onlyStakerOrDelegatedManager(uint256 tokenId) {
        address owner = ownerOf(tokenId); // ERC721 ownerOf
        address manager = _delegatedManager[tokenId];
        if (msg.sender != owner && msg.sender != manager) {
            revert NotStakerOrDelegatedManager();
        }
        _;
    }

     modifier onlyTraitUpdaterOrDelegated(uint256 tokenId) {
        address owner = ownerOf(tokenId); // ERC721 ownerOf
        address updater = _delegatedTraitUpdater[tokenId];
        // Also allow anyone with the TRAIT_UPDATER_ROLE or the DEFAULT_ADMIN_ROLE
        if (msg.sender != owner &&
            msg.sender != updater &&
            !hasRole(TRAIT_UPDATER_ROLE, msg.sender) &&
            !hasRole(DEFAULT_ADMIN_ROLE, msg.sender))
        {
             revert NotTraitUpdaterOrDelegated();
        }
        _;
    }


    // --- Internal Helper Functions ---

    // Calculates rewards since last update, updates position, and returns the amount earned
    function _updatePositionRewardTime(uint256 tokenId) internal {
        StakingPosition storage pos = _stakingPositions[tokenId];
        if (pos.amount == 0) {
            pos.lastRewardTime = block.timestamp; // Reset time if stake is zero
            return;
        }

        uint256 timeElapsed = block.timestamp - pos.lastRewardTime;
        if (timeElapsed > 0) {
            uint256 rewardsEarned = (pos.amount * rewardRatePerSecond * timeElapsed) / (1 ether); // Assumes rewardRatePerSecond is per 1e18 unit
            pos.unclaimedRewards += rewardsEarned;
            pos.lastRewardTime = block.timestamp;
            // Optionally trigger trait update on reward accumulation
            // _updateNFTTraits(tokenId); // This might be too frequent, better to trigger manually or on action
        }
    }

    // Calculates rewards without updating position state
    function _calculateRewards(uint256 tokenId) internal view returns (uint256) {
        StakingPosition storage pos = _stakingPositions[tokenId];
        if (pos.amount == 0) return 0;

        uint256 timeElapsed = block.timestamp - pos.lastRewardTime;
        uint256 rewardsEarned = (pos.amount * rewardRatePerSecond * timeElapsed) / (1 ether);
        return pos.unclaimedRewards + rewardsEarned;
    }

    // Logic for updating NFT traits based on staking position
    function _updateNFTTraits(uint256 tokenId) internal {
        StakingPosition storage pos = _stakingPositions[tokenId];
        NFTTraits storage traits = _nftTraits[tokenId];

        // Example Trait Logic:
        // Level based on duration & amount
        uint256 totalDuration = block.timestamp - pos.startTime;
        uint8 newLevel = 0;
        if (pos.amount > 0 && totalDuration > 0) {
            uint256 durationFactor = totalDuration / (1 days); // Days staked
            uint256 amountFactor = pos.amount / (1 ether); // Staked amount in whole tokens (adjust based on token decimals)
            // Simple example: Level increases with log of duration and amount
            if (durationFactor > 0 && amountFactor > 0) {
                 // A more complex, non-linear function would be better
                 newLevel = uint8(Math.min(255, (durationFactor * amountFactor) / 1000 + (durationFactor / 30) + (amountFactor / 10)));
                 if (newLevel > 100) newLevel = 100 + (newLevel - 100) / 5; // Cap and slow down growth at high levels
            }
        }
        traits.level = newLevel;

        // Duration Multiplier (e.g., bonus yield for long stakes)
        traits.durationMultiplierBp = uint16(Math.min(1000, (totalDuration / (30 days)) * 50)); // Up to 10% bonus (1000bp) every 30 days
        // This multiplier could be used *outside* the contract when calculating effective yield or applied to `rewardRatePerSecond` calculation internally.
        // For simplicity here, traits are just data. Applying them to yield happens *outside* the contract or requires more complex internal reward calculation.

        // Reward Boost (percentage) - could be based on level or external factors
        traits.rewardBoostPercentage = uint8(Math.min(25, traits.level / 4)); // Up to 25% boost based on level

        // totalCompounded is updated in compoundRewards function

        emit NFTTraitsUpdated(tokenId, traits);
    }

    // Internal function to handle minting and position creation
    function _mintPosition(address to, uint256 amount) internal returns (uint256 newTokenId) {
         if (to == address(0)) revert ZeroAddressNotAllowed();
         if (amount == 0) revert InvalidAmount();

        _nextTokenId.increment();
        newTokenId = _nextTokenId.current();

        _mint(to, newTokenId);

        uint256 currentTime = block.timestamp;
        _stakingPositions[newTokenId] = StakingPosition({
            owner: to, // Note: owner is stored here for convenience, but `ownerOf(tokenId)` is authoritative after transfers
            amount: amount,
            startTime: currentTime,
            lastRewardTime: currentTime,
            unclaimedRewards: 0
        });

        // Initialize traits
        _nftTraits[newTokenId] = NFTTraits({
             level: 0,
             durationMultiplierBp: 0,
             rewardBoostPercentage: 0,
             totalCompounded: 0
        });

        _updateNFTTraits(newTokenId); // Set initial traits

        totalStaked += amount;
        emit Staked(to, newTokenId, amount);
    }

    // Internal function to handle burning and position cleanup
    function _burnPosition(uint256 tokenId) internal {
        StakingPosition storage pos = _stakingPositions[tokenId];
        if (pos.amount > 0) {
             // This should only be called when amount is 0, or logic needs adjustment
             // Ensure all funds are accounted for before burning a position
             revert InsufficientStake(); // Or handle releasing remaining funds
        }

        // Ensure no pending rewards are left before burning (they should be claimed/compounded first)
        // This check might need refinement based on exact desired flow.
        // If withdrawal burns, unclaimed rewards are typically claimed with withdrawal.
        // If burn is separate, rewards should be claimed first.
        // For this flow (burn on full withdraw), unclaimed rewards are handled in withdraw.

        address currentOwner = ownerOf(tokenId); // Get current owner via ERC721 standard

        _burn(tokenId); // ERC721 burn

        // Delete state associated with the position
        delete _stakingPositions[tokenId];
        delete _nftTraits[tokenId];
        delete _delegatedManager[tokenId]; // Remove delegations
        delete _delegatedTraitUpdater[tokenId];

        // totalStaked is updated in withdraw/merge
    }

    // Calculate early unstake fee
    function _getFee(uint256 tokenId, uint256 amountToWithdraw) internal view returns (uint256 feeAmount) {
         StakingPosition storage pos = _stakingPositions[tokenId];
         uint256 timeStaked = block.timestamp - pos.startTime;

         if (timeStaked >= minStakeDuration) {
             return 0; // No fee if staked long enough
         }

         // Fee is calculated on the *amount being withdrawn*
         feeAmount = (amountToWithdraw * earlyUnstakeFeeRateBp) / 10000; // Fee rate is in basis points
    }


    // --- External/Public Functions (Core Logic) ---

    /// @notice Stakes tokens and mints a new NFT representing the position.
    /// @param amount The amount of staking tokens to stake.
    function deposit(uint256 amount) external payable whenNotPaused {
        if (amount == 0) revert InvalidAmount();

        stakingToken.safeTransferFrom(msg.sender, address(this), amount);

        uint256 newTokenId = _mintPosition(msg.sender, amount);

        // No need to update totalStaked here, it's done in _mintPosition
        // No need to update rewards here, _mintPosition initializes lastRewardTime
    }

    /// @notice Unstakes tokens from a specific NFT position.
    /// @param tokenId The ID of the NFT position to unstake from.
    /// @param amount The amount to unstake. Use type(uint256).max for full withdraw.
    function withdraw(uint256 tokenId, uint256 amount) external whenNotPaused onlyStakerOrDelegatedManager(tokenId) {
        StakingPosition storage pos = _stakingPositions[tokenId];
        if (pos.amount == 0) revert InsufficientStake();

        // Ensure the caller or delegate is the owner/manager AND is interacting with a valid position
        // The `onlyStakerOrDelegatedManager` modifier checks ownership/delegation.
        // Check if tokenId exists and belongs to _stakingPositions.
        // The initial deposit creates the position, so checking pos.amount > 0 is sufficient.
        // If the NFT was transferred, the `ownerOf(tokenId)` check in the modifier works.

        // Update rewards first
        _updatePositionRewardTime(tokenId);

        uint256 availableRewards = pos.unclaimedRewards;
        pos.unclaimedRewards = 0; // Rewards are claimed/forfeited on withdrawal

        // Calculate actual amount to withdraw (handle full withdrawal case)
        uint256 amountToWithdraw = amount;
        if (amount == type(uint256).max || amount > pos.amount) {
            amountToWithdraw = pos.amount;
        }
        if (amountToWithdraw == 0) revert InvalidAmount();
        if (amountToWithdraw > pos.amount) revert InsufficientStake(); // Should be caught by type(uint256).max handling, but double check

        uint256 feeAmount = _getFee(tokenId, amountToWithdraw);
        uint256 tokensToSend = amountToWithdraw - feeAmount;

        // Update staking position
        pos.amount -= amountToWithdraw;

        // Update total staked amount
        totalStaked -= amountToWithdraw; // Deduct total withdrawn including fee amount from contract's perspective

        // Transfer tokens back to the owner of the NFT (not the caller if delegated!)
        address recipient = ownerOf(tokenId);
        if (tokensToSend > 0) {
            stakingToken.safeTransfer(recipient, tokensToSend);
        }

        // Handle fee
        if (feeAmount > 0) {
             accumulatedFees += feeAmount;
             // The fee amount stays in the contract, available for admin to withdraw
        }

        emit Unstaked(recipient, tokenId, amountToWithdraw, feeAmount);

        // If the position is now empty, burn the NFT
        if (pos.amount == 0) {
            _burnPosition(tokenId);
        } else {
             // Update traits if partial withdrawal
             _updateNFTTraits(tokenId);
        }

         // Optionally transfer unclaimed rewards to recipient as well?
         // Current logic forfeits unclaimed rewards on withdrawal.
         // Alternative: Transfer availableRewards to recipient here.
         if (availableRewards > 0) {
             // rewardToken.safeTransfer(recipient, availableRewards);
             // emit RewardsClaimed(recipient, tokenId, availableRewards);
             // DECISION: Let's make rewards separate. User should claim rewards *before* withdrawing if they want them.
             // Or modify this to include unclaimedRewards in the transfer, but it complicates things.
             // Sticking to forfeiting rewards on withdraw for this version.
         }
    }


    /// @notice Claims accumulated rewards for a specific NFT position.
    /// @param tokenId The ID of the NFT position to claim rewards for.
    function claimRewards(uint256 tokenId) external whenNotPaused onlyStakerOrDelegatedManager(tokenId) {
        // Ensure caller is owner or delegated manager
        // The `onlyStakerOrDelegatedManager` modifier checks this.

        _updatePositionRewardTime(tokenId); // Calculate latest rewards

        StakingPosition storage pos = _stakingPositions[tokenId];
        uint256 rewardsToClaim = pos.unclaimedRewards;

        if (rewardsToClaim == 0) revert NothingToWithdraw();

        pos.unclaimedRewards = 0;

        // Transfer rewards to the owner of the NFT (not the caller if delegated!)
        address recipient = ownerOf(tokenId);
        rewardToken.safeTransfer(recipient, rewardsToClaim);

        emit RewardsClaimed(recipient, tokenId, rewardsToClaim);
        // Optionally trigger trait update after claiming, as total earned might be a trait factor
        // _updateNFTTraits(tokenId); // Maybe too frequent, update on compound/action instead
    }

    /// @notice Claims and restakes accumulated rewards back into the same NFT position.
    /// @param tokenId The ID of the NFT position to compound rewards for.
    function compoundRewards(uint256 tokenId) external whenNotPaused onlyStakerOrDelegatedManager(tokenId) {
        // Ensure caller is owner or delegated manager
        // The `onlyStakerOrDelegatedManager` modifier checks this.

        _updatePositionRewardTime(tokenId); // Calculate latest rewards

        StakingPosition storage pos = _stakingPositions[tokenId];
        uint256 rewardsToCompound = pos.unclaimedRewards;

        if (rewardsToCompound == 0) revert NothingToWithdraw();

        pos.unclaimedRewards = 0;
        pos.amount += rewardsToCompound; // Add rewards to the staked amount
        // totalStaked is already correct as rewards are generated from existing stake,
        // just changing their status from 'unclaimed' to 'staked'.

        _nftTraits[tokenId].totalCompounded += rewardsToCompound; // Track total compounded

        emit RewardsCompounded(ownerOf(tokenId), tokenId, rewardsToCompound);

        _updateNFTTraits(tokenId); // Update traits after compounding
    }


    // --- External/Public Functions (View/Getters) ---

    /// @notice Gets the current pending rewards for a specific NFT position.
    /// @param tokenId The ID of the NFT position.
    /// @return The amount of pending rewards.
    function getPendingRewards(uint256 tokenId) external view returns (uint256) {
         _validateTokenId(tokenId);
         return _calculateRewards(tokenId);
    }

    /// @notice Gets the amount staked in a specific NFT position.
    /// @param tokenId The ID of the NFT position.
    /// @return The staked amount.
    function getStakedAmount(uint256 tokenId) external view returns (uint256) {
         _validateTokenId(tokenId);
         return _stakingPositions[tokenId].amount;
    }

    /// @notice Gets the total amount of staking tokens staked in the contract.
    /// @return The total staked amount.
    function getTotalStaked() external view returns (uint256) {
         return totalStaked;
    }

    /// @notice Gets the current calculated traits for a specific NFT position.
    /// @param tokenId The ID of the NFT position.
    /// @return The NFTTraits struct.
    function getNFTTraits(uint256 tokenId) external view returns (NFTTraits memory) {
         _validateTokenId(tokenId);
         return _nftTraits[tokenId];
    }

    /// @notice Calculates the potential early unstake fee for a specific withdrawal amount.
    /// @param tokenId The ID of the NFT position.
    /// @param amountToWithdraw The hypothetical amount to withdraw.
    /// @return The calculated fee amount.
    function calculateEarlyUnstakeFee(uint256 tokenId, uint256 amountToWithdraw) external view returns (uint256) {
         _validateTokenId(tokenId);
         return _getFee(tokenId, amountToWithdraw);
    }

    /// @notice Gets the address delegated to manage a specific NFT position.
    /// @param tokenId The ID of the NFT position.
    /// @return The delegated manager address (or zero address if none).
    function getDelegatedManager(uint256 tokenId) external view returns (address) {
         _validateTokenId(tokenId);
         return _delegatedManager[tokenId];
    }

    /// @notice Gets the address delegated to update traits for a specific NFT position.
    /// @param tokenId The ID of the NFT position.
    /// @return The delegated trait updater address (or zero address if none).
    function getDelegatedTraitUpdater(uint256 tokenId) external view returns (address) {
         _validateTokenId(tokenId);
         return _delegatedTraitUpdater[tokenId];
    }

     function _validateTokenId(uint256 tokenId) internal view {
         if (!_exists(tokenId)) revert InvalidTokenId();
         // Although _stakingPositions owner field exists, the true owner is via ERC721 `ownerOf`.
         // We rely on `ownerOf` for permission checks.
         // We check if the position exists in our internal mapping, which implies it was minted by this contract.
         if (_stakingPositions[tokenId].amount == 0 && _stakingPositions[tokenId].startTime == 0) revert InvalidTokenId(); // Basic check if it's an active position
     }


    // --- External/Public Functions (Advanced/Creative) ---

    /// @notice Manually triggers the on-chain calculation and update of traits for an NFT.
    /// @dev Callable by the NFT owner, delegated trait updater, or accounts with TRAIT_UPDATER_ROLE or DEFAULT_ADMIN_ROLE.
    /// @param tokenId The ID of the NFT to update.
    function updateNFTTraits(uint256 tokenId) external whenNotPaused onlyTraitUpdaterOrDelegated(tokenId) {
        _validateTokenId(tokenId);
        // Update rewards first, as they might influence traits
        _updatePositionRewardTime(tokenId);
        _updateNFTTraits(tokenId);
        // Event is emitted inside _updateNFTTraits
    }

    /// @notice Merges the staking positions of two NFTs into the first NFT.
    /// @dev The caller must own or be delegated manager for both NFTs. The second NFT is burned.
    /// @param tokenId1 The ID of the target NFT to merge into.
    /// @param tokenId2 The ID of the NFT to merge from (will be burned).
    function mergeNFTs(uint256 tokenId1, uint256 tokenId2) external whenNotPaused {
        _validateTokenId(tokenId1);
        _validateTokenId(tokenId2);

        if (tokenId1 == tokenId2) revert CannotMergeSelf();

        // Check if caller can manage both positions
        address owner1 = ownerOf(tokenId1);
        address manager1 = _delegatedManager[tokenId1];
        bool canManage1 = (msg.sender == owner1 || msg.sender == manager1);

        address owner2 = ownerOf(tokenId2);
        address manager2 = _delegatedManager[tokenId2];
        bool canManage2 = (msg.sender == owner2 || msg.sender == manager2);

        if (!canManage1 || !canManage2) revert NotStakerOrDelegatedManager();

        // Ensure both NFTs are owned by the *same* account (the account that will own the merged NFT)
        if (owner1 != owner2) revert TokensMustBeOwnedBySameAccount();
        address finalOwner = owner1; // The owner of both becomes the owner of the merged NFT

        StakingPosition storage pos1 = _stakingPositions[tokenId1];
        StakingPosition storage pos2 = _stakingPositions[tokenId2];

        if (pos1.amount == 0 && pos2.amount == 0) revert InsufficientStake();

        // Update rewards for both positions before merging
        _updatePositionRewardTime(tokenId1);
        _updatePositionRewardTime(tokenId2);

        // Combine stake and unclaimed rewards
        uint256 mergedAmount = pos1.amount + pos2.amount;
        uint256 mergedUnclaimedRewards = pos1.unclaimedRewards + pos2.unclaimedRewards;

        // Determine new startTime (e.g., minimum of the two to reward longer combined stake)
        uint256 newStartTime = Math.min(pos1.startTime, pos2.startTime);

        // Update tokenId1's position
        pos1.amount = mergedAmount;
        pos1.unclaimedRewards = mergedUnclaimedRewards;
        pos1.startTime = newStartTime;
        pos1.lastRewardTime = block.timestamp; // Reset last reward time

        // Update tokenId1's traits based on combined position
        // We could also combine traits in a more complex way (e.g., sum levels, average multipliers)
        // For simplicity, let's recalculate based on the new combined position state.
        _nftTraits[tokenId1].totalCompounded += _nftTraits[tokenId2].totalCompounded; // Add compounded amounts
        _updateNFTTraits(tokenId1);

        // Clear tokenId2's position data and burn the NFT
        delete _stakingPositions[tokenId2];
        delete _nftTraits[tokenId2];
        delete _delegatedManager[tokenId2];
        delete _delegatedTraitUpdater[tokenId2];

        _burn(tokenId2); // Burn the second NFT

        // totalStaked remains the same as we combined existing stake

        emit PositionMerged(tokenId1, tokenId2, tokenId1); // Indicate tokenId2 was merged into tokenId1
    }

    /// @notice Splits a portion of the stake from an NFT position into a new NFT position.
    /// @dev The caller must own or be delegated manager for the original NFT.
    /// @param tokenId The ID of the NFT position to split from.
    /// @param amountToSplit The amount of stake to move to the new NFT.
    /// @return The ID of the newly minted NFT representing the split position.
    function splitNFT(uint256 tokenId, uint256 amountToSplit) external whenNotPaused returns (uint256 newTokenId) {
        _validateTokenId(tokenId);

        // Check if caller can manage the position
        address originalOwner = ownerOf(tokenId);
        address manager = _delegatedManager[tokenId];
        bool canManage = (msg.sender == originalOwner || msg.sender == manager);
        if (!canManage) revert NotStakerOrDelegatedManager();

        StakingPosition storage pos = _stakingPositions[tokenId];

        if (amountToSplit == 0) revert InvalidAmount();
        if (amountToSplit >= pos.amount) revert SplitAmountTooLarge(); // Must leave *some* amount in original

        // Update rewards for the original position before splitting
        _updatePositionRewardTime(tokenId);

        // Calculate proportion of unclaimed rewards to split
        uint256 originalUnclaimed = pos.unclaimedRewards;
        // Be careful with division - could lose precision. Distribute proportionally or keep all with original?
        // Keeping all unclaimed rewards with the original NFT is simpler.
        uint256 unclaimedToSplit = 0; // Or calculate: (originalUnclaimed * amountToSplit) / pos.amount;
        pos.unclaimedRewards -= unclaimedToSplit; // If distributing proportionally

        // Create the new position and mint a new NFT for the split amount
        _nextTokenId.increment();
        newTokenId = _nextTokenId.current();

        _mint(originalOwner, newTokenId); // New NFT belongs to the original owner

        uint256 currentTime = block.timestamp;
        _stakingPositions[newTokenId] = StakingPosition({
            owner: originalOwner,
            amount: amountToSplit,
            startTime: pos.startTime, // New position inherits original start time
            lastRewardTime: currentTime, // New position starts rewards from now
            unclaimedRewards: unclaimedToSplit // If distributing, otherwise 0
        });

        // Initialize traits for the new NFT
         _nftTraits[newTokenId] = NFTTraits({
             level: 0, // Recalculate based on its new state
             durationMultiplierBp: 0,
             rewardBoostPercentage: 0,
             totalCompounded: 0 // Starts at 0
         });
        _updateNFTTraits(newTokenId); // Set initial traits for the new NFT

        // Update the original position
        pos.amount -= amountToSplit;
        // pos.unclaimedRewards already updated if distributing
        pos.lastRewardTime = currentTime; // Original position also resets last reward time

        // Update traits for the original NFT
        _updateNFTTraits(tokenId);

        // totalStaked remains the same

        emit PositionSplit(tokenId, newTokenId, amountToSplit);

        return newTokenId;
    }

    /// @notice Delegates management (withdraw, claim, compound) for a specific NFT position to another address.
    /// @dev Callable only by the owner of the NFT.
    /// @param tokenId The ID of the NFT position to delegate.
    /// @param manager The address to delegate management to. Use address(0) to revoke.
    function delegatePositionManagement(uint256 tokenId, address manager) external whenNotPaused {
        _validateTokenId(tokenId);
        if (ownerOf(tokenId) != msg.sender) revert TokenIdNotOwnedByCaller();

        _delegatedManager[tokenId] = manager;
        emit ManagementDelegated(tokenId, msg.sender, manager);
    }

    /// @notice Revokes management delegation for a specific NFT position.
    /// @dev Callable only by the owner of the NFT.
    /// @param tokenId The ID of the NFT position.
    function revokePositionManagementDelegation(uint256 tokenId) external whenNotPaused {
         _validateTokenId(tokenId);
         if (ownerOf(tokenId) != msg.sender) revert TokenIdNotOwnedByCaller();

         delete _delegatedManager[tokenId];
         emit ManagementDelegated(tokenId, msg.sender, address(0)); // Emit event indicating revocation
    }

    /// @notice Delegates permission to trigger trait updates for a specific NFT position.
    /// @dev Callable only by the owner of the NFT.
    /// @param tokenId The ID of the NFT position.
    /// @param updater The address to delegate trait update permission to. Use address(0) to revoke.
    function delegateTraitUpdate(uint256 tokenId, address updater) external whenNotPaused {
        _validateTokenId(tokenId);
        if (ownerOf(tokenId) != msg.sender) revert TokenIdNotOwnedByCaller();

        _delegatedTraitUpdater[tokenId] = updater;
        emit TraitUpdateDelegated(tokenId, msg.sender, updater);
    }

     /// @notice Revokes trait update delegation for a specific NFT position.
     /// @dev Callable only by the owner of the NFT.
     /// @param tokenId The ID of the NFT position.
     function revokeTraitUpdateDelegation(uint256 tokenId) external whenNotPaused {
         _validateTokenId(tokenId);
         if (ownerOf(tokenId) != msg.sender) revert TokenIdNotOwnedByCaller();

         delete _delegatedTraitUpdater[tokenId];
         emit TraitUpdateDelegated(tokenId, msg.sender, address(0)); // Emit event indicating revocation
     }


    // --- External/Public Functions (Admin/Roles/Pausable) ---

    /// @notice Admin function to set the global reward rate per second per unit of stake.
    /// @dev Only accounts with DEFAULT_ADMIN_ROLE can call this. Rate is per 1e18 staked.
    /// @param newRate The new reward rate.
    function setRewardRate(uint256 newRate) external onlyRole(DEFAULT_ADMIN_ROLE) {
        emit RewardRateUpdated(rewardRatePerSecond, newRate);
        rewardRatePerSecond = newRate;
    }

    /// @notice Admin function to set the early unstake fee rate in basis points.
    /// @dev Only accounts with DEFAULT_ADMIN_ROLE can call this. 100 = 1%. Max 10000 (100%).
    /// @param newFeeRateBp The new fee rate in basis points.
    function setFeeRate(uint16 newFeeRateBp) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (newFeeRateBp > 10000) revert InvalidAmount(); // Fee cannot exceed 100%
        emit FeeRateUpdated(earlyUnstakeFeeRateBp, newFeeRateBp);
        earlyUnstakeFeeRateBp = newFeeRateBp;
    }

    /// @notice Admin function to set the minimum stake duration required to avoid the early unstake fee.
    /// @dev Only accounts with DEFAULT_ADMIN_ROLE can call this. Duration is in seconds.
    /// @param newDuration The new minimum duration in seconds.
    function setMinStakeDuration(uint256 newDuration) external onlyRole(DEFAULT_ADMIN_ROLE) {
         emit MinStakeDurationUpdated(minStakeDuration, newDuration);
         minStakeDuration = newDuration;
    }

    // Inherited from AccessControl: grantRole, revokeRole, renounceRole, hasRole

    // Inherited from Pausable: pause, unpause, paused
    function pause() external onlyRole(DEFAULT_ADMIN_ROLE) {
        _pause();
    }

    function unpause() external onlyRole(DEFAULT_ADMIN_ROLE) {
        _unpause();
    }

    /// @notice Admin function to withdraw any token stuck in the contract (excluding staked/reward tokens).
    /// @dev Use with extreme caution. Only callable by DEFAULT_ADMIN_ROLE.
    /// @param tokenAddress The address of the token to withdraw.
    /// @param amount The amount to withdraw.
    function emergencyAdminWithdraw(address tokenAddress, uint256 amount) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (tokenAddress == address(stakingToken) || tokenAddress == address(rewardToken)) {
             // Prevent admin from withdrawing core staking/reward tokens using this function.
             // Total staked tokens should only decrease via `withdraw`.
             // Reward tokens held for distribution should only be transferred via `claimRewards`/`compoundRewards`.
             revert InvalidAmount(); // Or a specific error like CannotWithdrawCoreTokens
        }
        IERC20(tokenAddress).safeTransfer(msg.sender, amount);
    }

    /// @notice Admin function to withdraw accumulated fees.
    /// @dev Fees are collected from early unstakes. Only callable by FEE_COLLECTOR_ROLE or DEFAULT_ADMIN_ROLE.
    /// @param recipient The address to send the fees to.
    function withdrawAdminFees(address recipient) external onlyRole(FEE_COLLECTOR_ROLE) {
        if (recipient == address(0)) revert ZeroAddressNotAllowed();
        uint256 fees = accumulatedFees;
        if (fees == 0) revert NothingToWithdraw();
        accumulatedFees = 0;
        stakingToken.safeTransfer(recipient, fees); // Fees are collected in stakingToken
        emit FeeCollected(recipient, fees);
    }


    // --- ERC721 & AccessControl Overrides/Implementations ---

    // Override to provide token metadata
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        _validateTokenId(tokenId); // Ensure token exists and is managed by this contract

        // Always update rewards and traits before generating URI for freshest data
        // Note: This `view` function cannot change state, so it can't call _updatePositionRewardTime or _updateNFTTraits state-changing versions.
        // The traits returned here are the *last calculated* traits.
        // A dapp/frontend should call `updateNFTTraits` explicitly before fetching URI for critical trait updates.
        // However, we can calculate the *current* pending rewards and effective duration for the URI.
        StakingPosition memory pos = _stakingPositions[tokenId];
        NFTTraits memory traits = _nftTraits[tokenId];

        uint256 currentPendingRewards = _calculateRewards(tokenId); // Calculate current rewards
        uint256 currentDuration = block.timestamp - pos.startTime; // Calculate current duration

        string memory name = string(abi.encodePacked("EYNFT #", tokenId.toString()));
        string memory description = string(abi.encodePacked(
            "An Evolutionary Yield NFT representing a staking position.\n",
            "Staked Amount: ", pos.amount.toString(), "\n",
            "Pending Rewards: ", currentPendingRewards.toString(), "\n",
            "Staked Since: ", pos.startTime.toString(), "\n", // Unix timestamp
            "Current Duration: ", currentDuration.toString(), " seconds\n",
            "Level: ", traits.level.toString(), "\n",
            "Duration Multiplier: ", traits.durationMultiplierBp.toString(), " bp\n",
            "Reward Boost: ", traits.rewardBoostPercentage.toString(), " %\n",
            "Total Compounded: ", traits.totalCompounded.toString()
        ));

        // Create a simple JSON structure for the metadata
        // More complex metadata with images could be done by uploading JSON to IPFS
        // and returning an ipfs:// URI. This is a data:// URI for simplicity.
        string memory json = string(abi.encodePacked(
            '{"name": "', name, '",',
            '"description": "', description, '",',
            '"image": "data:image/svg+xml;base64,...",', // Placeholder for image data
            '"attributes": [',
                '{"trait_type": "Level", "value": ', traits.level.toString(), '},',
                '{"trait_type": "Staked Amount", "value": ', pos.amount.toString(), '},',
                '{"trait_type": "Staked Duration (s)", "value": ', currentDuration.toString(), '},',
                '{"trait_type": "Pending Rewards", "value": ', currentPendingRewards.toString(), '},',
                '{"trait_type": "Total Compounded", "value": ', traits.totalCompounded.toString(), '},',
                '{"trait_type": "Duration Multiplier (bp)", "value": ', traits.durationMultiplierBp.toString(), '},',
                '{"trait_type": "Reward Boost (%)", "value": ', traits.rewardBoostPercentage.toString(), '}',
            ']}'
        ));

        // Encode JSON as base64
        string memory base64Json = Base64.encode(bytes(json));

        return string(abi.encodePacked("data:application/json;base64,", base64Json));
    }

    // Override required by AccessControl and ERC721 for ERC165 support
    function supportsInterface(bytes4 interfaceId) public view override(ERC721, AccessControl) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    // Override ERC721 transfer functions if specific logic is needed *before* transfer
    // Standard ERC721 transfer logic transfers ownership of the token ID.
    // In this contract, transferring the token ID also transfers the *staking position* associated with it.
    // This is the standard behavior for staked NFTs like those in Uniswap V3 Positions.
    // No special logic is needed *before* transfer unless we wanted to block transfers under certain conditions,
    // like while a delegation is active (which might be a good idea).
    // Let's add a check to prevent transfer if management delegation is active.

    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize) internal override {
         super._beforeTokenTransfer(from, to, tokenId, batchSize);

         // Check only applies when a token is being transferred from a non-zero address
         if (from != address(0)) {
              // Prevent transferring an NFT if management delegation is active
              if (_delegatedManager[tokenId] != address(0)) {
                   revert InvalidTokenId(); // Use a relevant error, e.g., DelegationActiveCannotTransfer
              }
              // Prevent transferring an NFT if trait update delegation is active
               if (_delegatedTraitUpdater[tokenId] != address(0)) {
                   revert InvalidTokenId(); // Use a relevant error, e.g., DelegationActiveCannotTransfer
              }

             // Ensure the owner field in our internal struct matches the actual owner before transfer
             // This helps maintain consistency, although ownerOf is the source of truth.
             // This check is primarily for debugging/safety if internal owner tracking was used more heavily.
             // If the NFT owner changes, the _stakingPositions[tokenId].owner *should* ideally also be updated,
             // but relying solely on ownerOf() is safer. For this design, let's stick to ownerOf().
             // StakingPosition struct has owner field, but it's initialized on mint and not updated on transfer.
             // It's safer to remove pos.owner and rely purely on ownerOf() for checks.
             // Let's modify StakingPosition struct to remove `owner` field.
             // (Self-correction: removing `owner` from struct means I need to look up ownerOf() everywhere.
             // Keeping it for data visibility in storage, but logic must use ownerOf()).
             // Let's add the check anyway as a safety measure if needed for future features.
             // Check if the internal owner field matches the *actual* owner before transfer out.
             // This implies the internal `owner` field *should* be updated on transfer - but ERC721 transfer doesn't have hooks for that easily.
             // Relying on `ownerOf(tokenId)` for all authorization checks is simpler and standard.
             // So, no need to check `_stakingPositions[tokenId].owner` here. The delegation checks are sufficient.
         }

         // When transferring *to* a non-zero address, update the owner in our internal struct
         // This requires an internal state update, which ERC721::_beforeTokenTransfer doesn't easily expose the *new* owner mid-transfer.
         // The simplest approach is to accept that _stakingPositions[tokenId].owner might become stale after transfer,
         // and always use ownerOf(tokenId) for permissions.
         // Alternatively, use _afterTokenTransfer to update the owner field in the struct.

         // Let's implement _afterTokenTransfer to update the internal owner field.
    }

    function _afterTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize) internal override {
        super._afterTokenTransfer(from, to, tokenId, batchSize);

        // Update the owner in our internal staking position struct
        // Note: If transferring from address(0) (mint), the owner was set in _mintPosition.
        // If transferring to address(0) (burn), the position is deleted in _burnPosition.
        // This hook is primarily for transfers between non-zero addresses.
        if (from != address(0) && to != address(0)) {
            _stakingPositions[tokenId].owner = to; // Update the stored owner
            // Note: Delegations are *not* transferred. New owner must re-delegate.
            delete _delegatedManager[tokenId];
            delete _delegatedTraitUpdater[tokenId];
        }
    }
}
```