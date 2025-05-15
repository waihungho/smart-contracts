Okay, let's design a smart contract that combines elements of soulbound tokens (SBTs), dynamic NFTs, time-based staking, and an evolving "Era" system. We'll call it `ChronicleBound`.

The core idea is that users stake a base token to earn non-transferable "Chronicle Points". These points represent a user's accumulated interaction and commitment. Users can spend these points to "forge" a unique, dynamic NFT ("Chronicle Fragment") that is *soulbound* to their address (cannot be transferred). The properties (like "Level" or "Aura") of this Fragment NFT are not static metadata but are dynamically calculated based on the user's current Chronicle Points, staking duration, and the current global "Era" of the contract. Users can also "bond" their fragments to earn additional rewards or unlock future features. The contract owner can advance the Era, changing staking rates and potentially fragment properties.

This design is advanced because it involves:
1.  **Soulbound Tokens:** Non-transferability for points and NFTs representing progression/identity.
2.  **Dynamic NFTs:** NFT properties are not static, but calculated on-chain based on evolving state.
3.  **Time-Based Staking:** Earning is proportional to amount *and* duration.
4.  **Evolving State (Eras):** Contract logic and rates change over time.
5.  **Interconnected Systems:** Points earned from staking are used to forge NFTs, which can then be bonded for more points/rewards.

We will need at least 20 functions to cover all these interactions and views.

---

### **Smart Contract Outline: ChronicleBound**

**Contract Name:** `ChronicleBound`

**Inherits:** `Ownable` (from OpenZeppelin for basic access control)
**Interfaces:** `IERC20` (for interacting with the staked token)

**Core Concepts:**
*   **Staking:** Users deposit tokens to earn Chronicle Points.
*   **Chronicle Points:** Non-transferable (SBT-like) points representing user engagement.
*   **Chronicle Fragments:** Dynamic, soulbound NFTs forged using points. Their properties are derived from user state and contract era.
*   **Fragment Bonding:** Users can lock Fragments to earn additional rewards.
*   **Eras:** Global contract state that affects rates and properties, advanced by the owner.

**State Variables:**
*   Staked token address.
*   Mapping for user stakes (amount, start time).
*   Mapping for user Chronicle Points.
*   Mapping for Fragments (struct containing ID, owner, bonded status).
*   Counter for total fragments.
*   Mapping for bonded fragments.
*   Current global Era.
*   Era start timestamps.
*   Mapping for staking point rates per Era.
*   Mapping for bonding point rates per Era.
*   Cost to forge a fragment (in Chronicle Points).

**Events:**
*   `Staked`
*   `Unstaked`
*   `PointsClaimed`
*   `FragmentForged`
*   `FragmentBonded`
*   `FragmentUnbonded`
*   `BondingRewardsClaimed`
*   `EraAdvanced`
*   `StakingRateUpdated`
*   `BondingRateUpdated`
*   `ForgeCostUpdated`

**Errors:**
*   Custom errors for insufficient balance, insufficient points, invalid fragment ID, already bonded, not bonded, not owner, not approved, etc.

**Function Categories & Summary:**

1.  **Admin (Owner-only):** (5 functions)
    *   `advanceEra`: Moves the contract to the next Era.
    *   `updateStakingRateForEra`: Sets the point earning rate for staking in a specific Era.
    *   `updateBondingRateForEra`: Sets the point earning rate for bonded fragments in a specific Era.
    *   `updateFragmentForgeCost`: Sets the Chronicle Point cost to forge a Fragment.
    *   `withdrawAdminBalance`: Owner can withdraw any non-staked token balance sent to the contract (e.g., accidental sends).

2.  **Staking:** (6 functions)
    *   `stake`: Deposits tokens to start or add to a stake.
    *   `unstake`: Withdraws staked tokens and claims pending points.
    *   `claimStakingPoints`: Claims pending points without unstaking.
    *   `calculatePendingStakingPoints`: View function to calculate points earned since last interaction.
    *   `getUserStakeAmount`: View user's current staked amount.
    *   `getUserStakeStartTime`: View user's stake start timestamp.

3.  **Chronicle Points (SBT):** (1 function - primarily earned via staking/bonding)
    *   `getUserChroniclePoints`: View user's current non-transferable points.

4.  **Chronicle Fragments (Dynamic Soulbound NFT):** (6 functions)
    *   `forgeFragment`: Spends Chronicle Points to mint a new, soulbound Fragment NFT.
    *   `getFragmentOwner`: Returns owner of a fragment (always the original minter). Overrides ERC721 `ownerOf` behavior conceptually by enforcing soulbound nature.
    *   `getFragmentProperties`: Dynamically calculates and returns properties (Level, Aura, etc.) of a Fragment based on user state and Era.
    *   `getFragmentURI`: Returns a metadata URI (can point to a service that uses `getFragmentProperties` to generate dynamic metadata).
    *   `getTotalFragmentsMinted`: View total number of fragments minted.
    *   `getUserFragments`: View list of Fragment IDs owned by a user.

5.  **Fragment Bonding:** (4 functions)
    *   `bondFragment`: Locks a Fragment to enable bonding rewards.
    *   `unbondFragment`: Unlocks a bonded Fragment.
    *   `isFragmentBonded`: View function to check if a Fragment is bonded.
    *   `calculatePendingBondingRewards`: View function to calculate bonding points earned for a specific fragment.

6.  **Rewards Claiming:** (1 function - shared)
    *   `claimBondingRewards`: Claims accumulated bonding points for specified bonded fragments.

7.  **Era & Rates:** (4 functions)
    *   `getCurrentEra`: View the current global Era.
    *   `getEraStartTime`: View the timestamp when the current Era began.
    *   `getStakingRate`: View the current staking point rate per unit of token per unit of time.
    *   `getBondingRate`: View the current bonding point rate per fragment per unit of time.

**Total Functions:** 5 (Admin) + 6 (Staking) + 1 (Points View) + 6 (Fragment) + 4 (Bonding) + 1 (Claiming) + 4 (Era Views) = **27 Functions**. This meets the requirement of at least 20.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Metadata.sol"; // Using interface for clarity on NFT aspects, though implementation is soulbound.
import "@openzeppelin/contracts/utils/math/SafeMath.sol"; // Useful for calculations

// Custom Errors for gas efficiency
error ChronicleBound__InsufficientStake(uint256 currentStake, uint256 requested);
error ChronicleBound__InsufficientPoints(uint256 currentPoints, uint256 requested);
error ChronicleBound__FragmentDoesNotExist(uint256 fragmentId);
error ChronicleBound__FragmentNotOwner(uint256 fragmentId, address caller);
error ChronicleBound__FragmentAlreadyBonded(uint256 fragmentId);
error ChronicleBound__FragmentNotBonded(uint256 fragmentId);
error ChronicleBound__EraNotAdvanced();
error ChronicleBound__ZeroAddressStakeToken();
error ChronicleBound__RateMustBePositive();
error ChronicleBound__ForgeCostMustBePositive();
error ChronicleBound__NoRewardsToClaim();
error ChronicleBound__AdminWithdrawFailed();


// Interface for basic ERC721 functions we conceptually implement (mostly views)
interface IChronicleFragment is IERC721Metadata {
    function ownerOf(uint256 tokenId) external view returns (address owner); // We will enforce non-transferability
    function tokenURI(uint256 tokenId) external view returns (string memory);
    // No transfer, approve, setApprovalForAll functions for soulbound
}


contract ChronicleBound is Ownable, IChronicleFragment {
    using SafeMath for uint256;

    IERC20 immutable i_stakedToken;

    // --- State Variables ---

    // Staking State
    mapping(address => uint256) private s_userStake;
    mapping(address => uint256) private s_userStakeStartTime; // Timestamp when stake started/last changed

    // Point State (Soulbound)
    mapping(address => uint256) private s_userChroniclePoints;
    mapping(address => uint256) private s_userLastPointCalculationTime; // Timestamp of last point calculation for staking

    // Fragment State (Dynamic Soulbound NFT)
    struct Fragment {
        uint256 id;
        address owner; // The address that forged it (cannot be transferred)
        bool isBonded;
        uint256 bondedStartTime; // Timestamp when bonding started
        uint256 lastBondingRewardClaimTime; // Timestamp of last bonding reward claim
    }
    uint256 private s_fragmentCounter;
    mapping(uint256 => Fragment) private s_fragments;
    mapping(address => uint256[]) private s_userFragments; // List of fragment IDs owned by a user

    // Era State
    uint256 private s_currentEra = 1;
    mapping(uint256 => uint256) private s_eraStartTime; // Timestamp when an Era started

    // Rates & Costs (Configurable by Owner)
    mapping(uint256 => uint256) private s_stakingRatePerEra; // Points per token per second (adjust scale!)
    mapping(uint256 => uint256) private s_bondingRatePerEra; // Points per fragment per second (adjust scale!)
    uint256 private s_fragmentForgeCost; // Chronicle Points required to forge a fragment

    // --- Events ---
    event Staked(address indexed user, uint256 amount, uint256 newTotalStake);
    event Unstaked(address indexed user, uint256 amount, uint256 newTotalStake, uint256 claimedPoints);
    event PointsClaimed(address indexed user, uint256 claimedPoints, uint256 newTotalPoints);
    event FragmentForged(address indexed owner, uint256 indexed fragmentId, uint256 pointsSpent, uint256 remainingPoints);
    event FragmentBonded(address indexed owner, uint256 indexed fragmentId);
    event FragmentUnbonded(address indexed owner, uint256 indexed fragmentId, uint256 claimedBondingRewards);
    event BondingRewardsClaimed(address indexed owner, uint256 indexed fragmentId, uint256 claimedPoints, uint256 newTotalPoints);
    event EraAdvanced(uint256 oldEra, uint256 newEra, uint256 timestamp);
    event StakingRateUpdated(uint256 era, uint256 newRate);
    event BondingRateUpdated(uint256 era, uint256 newRate);
    event ForgeCostUpdated(uint256 newCost);

    // --- Constructor ---
    constructor(address stakedTokenAddress, uint256 initialStakingRate, uint256 initialBondingRate, uint256 initialForgeCost) Ownable(msg.sender) {
        if (stakedTokenAddress == address(0)) {
            revert ChronicleBound__ZeroAddressStakeToken();
        }
        if (initialStakingRate == 0) {
             revert ChronicleBound__RateMustBePositive();
        }
         if (initialBondingRate == 0) {
             revert ChronicleBound__RateMustBePositive();
        }
         if (initialForgeCost == 0) {
             revert ChronicleBound__ForgeCostMustBePositive();
        }


        i_stakedToken = IERC20(stakedTokenAddress);

        s_eraStartTime[s_currentEra] = block.timestamp;
        s_stakingRatePerEra[s_currentEra] = initialStakingRate;
        s_bondingRatePerEra[s_currentEra] = initialBondingRate;
        s_fragmentForgeCost = initialForgeCost;
    }

    // --- Admin Functions ---

    /// @notice Advances the contract to the next Era. Only owner can call.
    /// @dev This locks in rates for the previous era and starts the clock for the new one.
    function advanceEra() external onlyOwner {
        s_currentEra = s_currentEra.add(1);
        s_eraStartTime[s_currentEra] = block.timestamp;
        // Default rates for new era can be set here, or rely on owner calling updateRate functions after.
        // For simplicity, new era inherits previous era's rate until updated.
        s_stakingRatePerEra[s_currentEra] = s_stakingRatePerEra[s_currentEra.sub(1)];
        s_bondingRatePerEra[s_currentEra] = s_bondingRatePerEra[s_currentEra.sub(1)];

        emit EraAdvanced(s_currentEra.sub(1), s_currentEra, block.timestamp);
    }

    /// @notice Updates the staking point earning rate for a specific Era. Only owner can call.
    /// @param era The era to update the rate for.
    /// @param rate The new staking rate (points per token per second, scale matters!). Must be > 0.
    function updateStakingRateForEra(uint256 era, uint256 rate) external onlyOwner {
         if (rate == 0) {
             revert ChronicleBound__RateMustBePositive();
        }
        s_stakingRatePerEra[era] = rate;
        emit StakingRateUpdated(era, rate);
    }

    /// @notice Updates the bonding point earning rate for a specific Era. Only owner can call.
    /// @param era The era to update the rate for.
    /// @param rate The new bonding rate (points per fragment per second, scale matters!). Must be > 0.
    function updateBondingRateForEra(uint256 era, uint256 rate) external onlyOwner {
         if (rate == 0) {
             revert ChronicleBound__RateMustBePositive();
        }
        s_bondingRatePerEra[era] = rate;
        emit BondingRateUpdated(era, rate);
    }

    /// @notice Updates the Chronicle Point cost to forge a Fragment. Only owner can call.
    /// @param cost The new cost in Chronicle Points. Must be > 0.
    function updateFragmentForgeCost(uint256 cost) external onlyOwner {
         if (cost == 0) {
             revert ChronicleBound__ForgeCostMustBePositive();
        }
        s_fragmentForgeCost = cost;
        emit ForgeCostUpdated(cost);
    }

    /// @notice Allows the owner to withdraw any tokens accidentally sent to the contract (excluding staked tokens).
    /// @param tokenAddress The address of the token to withdraw.
    /// @param amount The amount to withdraw.
    function withdrawAdminBalance(address tokenAddress, uint256 amount) external onlyOwner {
        if (tokenAddress == address(i_stakedToken)) {
            // Prevent withdrawing staked tokens using this function
            // A specific recovery mechanism for lost staked tokens (e.g., contract upgrade) would be separate and complex.
             revert("ChronicleBound: Cannot withdraw staked token using this function");
        }
         IERC20 token = IERC20(tokenAddress);
         bool success = token.transfer(owner(), amount);
         if (!success) {
            revert ChronicleBound__AdminWithdrawFailed();
         }
    }

    // --- Staking Functions ---

    /// @notice Stakes tokens in the contract to earn Chronicle Points.
    /// @dev Requires the user to approve this contract to spend the tokens beforehand.
    /// @param amount The amount of tokens to stake.
    function stake(uint256 amount) external {
        uint256 pendingPoints = _calculatePendingStakingPoints(msg.sender);
        s_userChroniclePoints[msg.sender] = s_userChroniclePoints[msg.sender].add(pendingPoints);
        s_userLastPointCalculationTime[msg.sender] = block.timestamp;

        uint256 currentStake = s_userStake[msg.sender];
        s_userStake[msg.sender] = currentStake.add(amount);

        // Update stake start time only if it was previously 0 (first stake) or if unstaked fully.
        // If adding to an existing stake, the start time remains, essentially averaging the duration implicitly.
        // A more complex system would average stake time weighted by amount. Keeping it simpler here.
        if (currentStake == 0) {
             s_userStakeStartTime[msg.sender] = block.timestamp;
        }

        // Transfer tokens from user to contract
        bool success = i_stakedToken.transferFrom(msg.sender, address(this), amount);
        if (!success) {
             revert("ChronicleBound: Token transfer failed during stake");
        }

        emit Staked(msg.sender, amount, s_userStake[msg.sender]);
    }

    /// @notice Unstakes tokens and claims pending Chronicle Points.
    /// @param amount The amount of tokens to unstake.
    function unstake(uint256 amount) external {
        uint256 currentStake = s_userStake[msg.sender];
        if (currentStake < amount) {
             revert ChronicleBound__InsufficientStake(currentStake, amount);
        }

        uint256 pendingPoints = _calculatePendingStakingPoints(msg.sender);
        s_userChroniclePoints[msg.sender] = s_userChroniclePoints[msg.sender].add(pendingPoints);
        s_userLastPointCalculationTime[msg.sender] = block.timestamp;
        uint256 claimedPoints = pendingPoints; // Points added during this unstake

        s_userStake[msg.sender] = currentStake.sub(amount);

        // If user unstakes everything, reset stake start time
        if (s_userStake[msg.sender] == 0) {
            s_userStakeStartTime[msg.sender] = 0; // Or block.timestamp, depends on desired re-stake behavior
        }

        // Transfer tokens from contract back to user
        bool success = i_stakedToken.transfer(msg.sender, amount);
        if (!success) {
             revert("ChronicleBound: Token transfer failed during unstake");
        }

        emit Unstaked(msg.sender, amount, s_userStake[msg.sender], claimedPoints);
    }

     /// @notice Claims pending Chronicle Points from staking without changing the stake amount.
    function claimStakingPoints() external {
        uint256 pendingPoints = _calculatePendingStakingPoints(msg.sender);
        if (pendingPoints == 0) {
             revert ChronicleBound__NoRewardsToClaim();
        }
        s_userChroniclePoints[msg.sender] = s_userChroniclePoints[msg.sender].add(pendingPoints);
        s_userLastPointCalculationTime[msg.sender] = block.timestamp;

        emit PointsClaimed(msg.sender, pendingPoints, s_userChroniclePoints[msg.sender]);
    }

    /// @notice Calculates the points earned from staking since the last calculation time.
    /// @param user The address of the user.
    /// @return The amount of pending Chronicle Points.
    function calculatePendingStakingPoints(address user) public view returns (uint256) {
        return _calculatePendingStakingPoints(user);
    }

     /// @notice Gets the current staked amount for a user.
    /// @param user The address of the user.
    /// @return The amount of tokens the user has staked.
    function getUserStakeAmount(address user) external view returns (uint256) {
        return s_userStake[user];
    }

    /// @notice Gets the timestamp when a user's current stake began or was last reset.
    /// @param user The address of the user.
    /// @return The timestamp (seconds since epoch).
    function getUserStakeStartTime(address user) external view returns (uint256) {
        return s_userStakeStartTime[user];
    }


    // --- Chronicle Points (SBT) ---

     /// @notice Gets the total Chronicle Points for a user. These points are soulbound.
    /// @param user The address of the user.
    /// @return The total Chronicle Points accumulated by the user.
    function getUserChroniclePoints(address user) external view returns (uint256) {
        return s_userChroniclePoints[user];
    }

    // Note: No transfer function for Chronicle Points - they are soulbound.

    // --- Chronicle Fragments (Dynamic Soulbound NFT) ---

    /// @notice Spends Chronicle Points to forge a new Chronicle Fragment NFT.
    /// @dev The Fragment is soulbound to the caller's address.
    function forgeFragment() external {
        uint256 requiredPoints = s_fragmentForgeCost;
        if (s_userChroniclePoints[msg.sender] < requiredPoints) {
            revert ChronicleBound__InsufficientPoints(s_userChroniclePoints[msg.sender], requiredPoints);
        }

        // Consume points
        s_userChroniclePoints[msg.sender] = s_userChroniclePoints[msg.sender].sub(requiredPoints);

        // Mint new fragment
        s_fragmentCounter = s_fragmentCounter.add(1);
        uint256 newFragmentId = s_fragmentCounter;

        s_fragments[newFragmentId] = Fragment({
            id: newFragmentId,
            owner: msg.sender, // Soulbound: Owner is fixed
            isBonded: false,
            bondedStartTime: 0,
            lastBondingRewardClaimTime: 0
        });

        // Add fragment to user's list
        s_userFragments[msg.sender].push(newFragmentId);

        emit FragmentForged(msg.sender, newFragmentId, requiredPoints, s_userChroniclePoints[msg.sender]);
    }

    /// @notice Returns the owner of a specific Fragment.
    /// @dev Implements ERC721 `ownerOf` behavior but enforces soulbound nature.
    /// @param fragmentId The ID of the fragment.
    /// @return The address of the owner (minter).
    function ownerOf(uint256 fragmentId) public view override returns (address owner) {
        _requireValidFragment(fragmentId);
        return s_fragments[fragmentId].owner;
    }

    /// @notice Dynamically calculates and returns the properties of a Fragment.
    /// @dev Properties like Level, Aura are derived from user state and current Era.
    /// @param fragmentId The ID of the fragment.
    /// @return fragmentLevel The calculated level.
    /// @return fragmentAura The calculated aura intensity (example property).
    function getFragmentProperties(uint256 fragmentId) public view returns (uint256 fragmentLevel, uint256 fragmentAura) {
        _requireValidFragment(fragmentId);
        address fragmentOwner = s_fragments[fragmentId].owner;
        uint256 ownerPoints = s_userChroniclePoints[fragmentOwner].add(_calculatePendingStakingPoints(fragmentOwner));
        uint256 currentStake = s_userStake[fragmentOwner];
        uint256 stakeStartTime = s_userStakeStartTime[fragmentOwner];
        uint256 timeStaked = stakeStartTime == 0 ? 0 : block.timestamp.sub(stakeStartTime);
        uint256 era = s_currentEra; // Properties are based on the current era

        // Example Dynamic Logic:
        // Level is based on total points (more points = higher level)
        // Aura is based on current stake and time staked (more stake for longer = stronger aura)
        fragmentLevel = ownerPoints.div(1000).add(1); // 1000 points per level, start at 1
        fragmentAura = currentStake.mul(timeStaked).div(1e18).div(3600).add(1); // Example: scale by staked amount * time, adjust scale. Add 1 to avoid 0 aura.

        // Add complexity based on Era? e.g., Era 2 grants a multiplier
        if (era > 1) {
            fragmentLevel = fragmentLevel.mul(era); // Example: Level gets boost in later eras
        }

        // Cap levels/auras if desired
        if (fragmentLevel > 100) fragmentLevel = 100;
        if (fragmentAura > 255) fragmentAura = 255; // Like a byte value

        return (fragmentLevel, fragmentAura);
    }

    /// @notice Returns the metadata URI for a Fragment.
    /// @dev Points to an external service that generates dynamic JSON metadata using `getFragmentProperties`.
    /// @param fragmentId The ID of the fragment.
    /// @return uri The metadata URI.
    function tokenURI(uint256 fragmentId) public view override returns (string memory uri) {
         _requireValidFragment(fragmentId);
         // In a real dapp, this would typically point to an API endpoint like
         // "https://yourdapp.com/api/metadata/chroniclefragment/123"
         // The API would fetch properties from getFragmentProperties(fragmentId) and build the JSON.
         return string(abi.encodePacked("ipfs://some_base_uri/", Strings.toString(fragmentId), "/metadata")); // Example placeholder
    }

    /// @notice Gets the total number of Chronicle Fragments minted.
    /// @return The total count of fragments.
    function getTotalFragmentsMinted() external view returns (uint256) {
        return s_fragmentCounter;
    }

     /// @notice Gets the list of Fragment IDs owned by a user.
    /// @param user The address of the user.
    /// @return An array of fragment IDs.
    /// @dev Note: This can be gas-intensive for users with many fragments. DApps might use pagination off-chain.
    function getUserFragments(address user) external view returns (uint256[] memory) {
        return s_userFragments[user];
    }


    // --- Fragment Bonding ---

    /// @notice Bonds a Chronicle Fragment. Bonded fragments may earn additional rewards.
    /// @param fragmentId The ID of the fragment to bond.
    function bondFragment(uint256 fragmentId) external {
        _requireValidFragment(fragmentId);
        if (s_fragments[fragmentId].owner != msg.sender) {
             revert ChronicleBound__FragmentNotOwner(fragmentId, msg.sender);
        }
        if (s_fragments[fragmentId].isBonded) {
             revert ChronicleBound__FragmentAlreadyBonded(fragmentId);
        }

        Fragment storage fragment = s_fragments[fragmentId];
        fragment.isBonded = true;
        fragment.bondedStartTime = block.timestamp;
        fragment.lastBondingRewardClaimTime = block.timestamp; // Start tracking rewards from now

        emit FragmentBonded(msg.sender, fragmentId);
    }

    /// @notice Unbonds a Chronicle Fragment and claims any pending bonding rewards for it.
    /// @param fragmentId The ID of the fragment to unbond.
    function unbondFragment(uint256 fragmentId) external {
         _requireValidFragment(fragmentId);
        if (s_fragments[fragmentId].owner != msg.sender) {
             revert ChronicleBound__FragmentNotOwner(fragmentId, msg.sender);
        }
        if (!s_fragments[fragmentId].isBonded) {
             revert ChronicleBound__FragmentNotBonded(fragmentId);
        }

        uint256 pendingRewards = _calculatePendingBondingRewards(fragmentId);
        s_userChroniclePoints[msg.sender] = s_userChroniclePoints[msg.sender].add(pendingRewards);

        Fragment storage fragment = s_fragments[fragmentId];
        fragment.isBonded = false;
        fragment.bondedStartTime = 0; // Reset
        fragment.lastBondingRewardClaimTime = 0; // Reset

        emit UnbondFragment(msg.sender, fragmentId, pendingRewards);
    }

     /// @notice Checks if a Fragment is currently bonded.
    /// @param fragmentId The ID of the fragment.
    /// @return True if bonded, false otherwise.
    function isFragmentBonded(uint256 fragmentId) external view returns (bool) {
         if (fragmentId == 0 || fragmentId > s_fragmentCounter) {
             // Return false for non-existent IDs without reverting
             return false;
         }
        return s_fragments[fragmentId].isBonded;
    }

    /// @notice Calculates the bonding rewards earned for a specific bonded fragment since the last claim.
    /// @param fragmentId The ID of the fragment.
    /// @return The amount of pending bonding points.
    function calculatePendingBondingRewards(uint256 fragmentId) public view returns (uint256) {
         if (fragmentId == 0 || fragmentId > s_fragmentCounter) {
             return 0; // No rewards for non-existent fragments
         }
         Fragment storage fragment = s_fragments[fragmentId];
         if (!fragment.isBonded) {
             return 0; // No rewards if not bonded
         }

        // Calculate points earned based on elapsed time and current bonding rate
        uint256 lastClaim = fragment.lastBondingRewardClaimTime;
        uint256 currentTime = block.timestamp;
        if (currentTime <= lastClaim) {
            return 0; // No time elapsed since last claim or bond
        }

        uint256 timeElapsed = currentTime.sub(lastClaim);
        uint256 currentBondingRate = s_bondingRatePerEra[s_currentEra]; // Use current era's rate

        // Points = Rate * Time (Rate is points per fragment per second)
        uint256 earnedPoints = currentBondingRate.mul(timeElapsed);

        return earnedPoints;
    }

    /// @notice Claims pending bonding rewards for a list of bonded fragments owned by the caller.
    /// @param fragmentIds The list of fragment IDs to claim rewards for.
    function claimBondingRewards(uint256[] calldata fragmentIds) external {
        uint256 totalClaimedPoints = 0;
        for (uint i = 0; i < fragmentIds.length; i++) {
            uint256 fragmentId = fragmentIds[i];
             _requireValidFragment(fragmentId);
            if (s_fragments[fragmentId].owner != msg.sender) {
                // Skip fragments not owned by the caller, do not revert the whole transaction
                continue;
            }
            if (!s_fragments[fragmentId].isBonded) {
                 // Skip non-bonded fragments
                 continue;
            }

            uint256 pendingRewards = _calculatePendingBondingRewards(fragmentId);

            if (pendingRewards > 0) {
                 s_userChroniclePoints[msg.sender] = s_userChroniclePoints[msg.sender].add(pendingRewards);
                 s_fragments[fragmentId].lastBondingRewardClaimTime = block.timestamp; // Update last claim time
                 totalClaimedPoints = totalClaimedPoints.add(pendingRewards);

                 emit BondingRewardsClaimed(msg.sender, fragmentId, pendingRewards, s_userChroniclePoints[msg.sender]);
            }
        }

        if (totalClaimedPoints == 0) {
             revert ChronicleBound__NoRewardsToClaim();
        }
    }


    // --- Era & Rates Views ---

    /// @notice Gets the current global Era number.
    function getCurrentEra() external view returns (uint256) {
        return s_currentEra;
    }

    /// @notice Gets the timestamp when a specific Era began.
    /// @param era The era number.
    function getEraStartTime(uint256 era) external view returns (uint256) {
        return s_eraStartTime[era];
    }

    /// @notice Gets the staking point rate for the current Era.
    /// @return The staking rate (points per token per second).
    function getStakingRate() external view returns (uint256) {
        return s_stakingRatePerEra[s_currentEra];
    }

    /// @notice Gets the bonding point rate for the current Era.
    /// @return The bonding rate (points per fragment per second).
    function getBondingRate() external view returns (uint256) {
        return s_bondingRatePerEra[s_currentEra];
    }

    /// @notice Gets the current Chronicle Point cost to forge a Fragment.
    function getFragmentForgeCost() external view returns (uint256) {
        return s_fragmentForgeCost;
    }


    // --- Internal Helper Functions ---

    /// @dev Calculates the points earned from staking since the last calculation time for a user.
    /// @param user The address of the user.
    /// @return The amount of pending Chronicle Points.
    function _calculatePendingStakingPoints(address user) internal view returns (uint256) {
        uint256 currentStake = s_userStake[user];
        uint256 stakeStartTime = s_userStakeStartTime[user];
        uint256 lastCalcTime = s_userLastPointCalculationTime[user];

        // If no stake or no time tracked, no points pending
        if (currentStake == 0 || stakeStartTime == 0 || lastCalcTime == 0 || block.timestamp <= lastCalcTime) {
            return 0;
        }

        // Calculate time elapsed since last calculation
        uint256 timeElapsed = block.timestamp.sub(lastCalcTime);

        // Get the rate for the current era
        uint256 currentStakingRate = s_stakingRatePerEra[s_currentEra];

        // Points earned = Stake Amount * Rate * Time Elapsed
        // Need to be careful with precision/scaling if Rate is small
        // Assuming rate is scaled appropriately (e.g., points * 1e18 per token per second)
        uint256 earnedPoints = currentStake.mul(currentStakingRate).mul(timeElapsed);

        return earnedPoints;
    }

     /// @dev Requires that a fragment ID is valid (greater than 0 and less than or equal to the total minted count).
    function _requireValidFragment(uint256 fragmentId) internal view {
        if (fragmentId == 0 || fragmentId > s_fragmentCounter) {
            revert ChronicleBound__FragmentDoesNotExist(fragmentId);
        }
    }


    // --- ERC721 Optional/Excluded Functions (Soulbound) ---
    // We explicitly do *not* implement or override transferFrom, safeTransferFrom, approve, getApproved, isApprovedForAll, setApprovalForAll
    // as the tokens are designed to be soulbound (non-transferable).
    // Implementing IChronicleFragment mostly for clarity on the NFT aspects and view functions.
    // A full ERC721 implementation would involve mappings like _owners, _tokenApprovals, _operatorApprovals.
    // Here, owner is stored directly in the Fragment struct and never changes after minting.
    // Standard ERC721 events like Transfer would not be emitted for these tokens as they cannot be transferred.

    // Override to prevent transfers (optional if not inheriting full ERC721, but good practice if interface is implemented)
    // function _transfer(address from, address to, uint256 tokenId) internal virtual override {
    //    revert("ChronicleBound: Fragments are soulbound and cannot be transferred.");
    // }
}

// Minimal Mock ERC20 for testing purposes
contract MockERC20 is IERC20 {
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 private _totalSupply;
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    constructor(string memory name_, string memory symbol_, uint8 decimals_, uint256 initialSupply) {
        name = name_;
        symbol = symbol_;
        decimals = decimals_;
        _totalSupply = initialSupply;
        _balances[msg.sender] = initialSupply; // Mint initial supply to deployer
    }

    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        uint256 currentAllowance = _allowances[sender][msg.sender];
        _approve(sender, msg.sender, currentAllowance.sub(amount));
        return true;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        _balances[sender] = senderBalance.sub(amount);
        _balances[recipient] = _balances[recipient].add(amount);

        emit Transfer(sender, recipient, amount);
    }

    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
}

// Need SafeMath and Strings utility from OpenZeppelin
// SafeMath is deprecated in 0.8+, use built-in checked arithmetic, but included here as it was explicitly imported.
// Strings is useful for tokenURI
import "@openzeppelin/contracts/utils/Strings.sol";
```

---

**Explanation of Key Parts and Advanced Concepts:**

1.  **Soulbound Nature (`s_userChroniclePoints`, `Fragment.owner`):**
    *   Chronicle Points are simply stored in a mapping `s_userChroniclePoints`. There is no `transfer` function for these points. They are permanently linked to the user's address.
    *   Fragment NFTs have an `owner` field in their struct, set during minting. Crucially, there are *no* public `transferFrom`, `safeTransferFrom`, `approve`, or `setApprovalForAll` functions. This prevents the ownership from ever changing, making them soulbound. The `ownerOf` function simply returns the address stored during minting.

2.  **Dynamic NFT Properties (`getFragmentProperties`):**
    *   Instead of storing properties like "level" or "aura" directly on the NFT struct or in static metadata, they are *calculated every time* `getFragmentProperties` is called.
    *   This calculation uses current, live data from the contract state (`s_userChroniclePoints`, `s_userStake`, `s_userStakeStartTime`, `s_currentEra`).
    *   This means an NFT's appearance or utility (as interpreted by a frontend or other contracts) can change dynamically based on the owner's ongoing engagement (staking, earning points) and the global state (Era).

3.  **Time-Based Staking Rewards (`_calculatePendingStakingPoints`):**
    *   Staking reward calculation considers the amount staked (`currentStake`), the time elapsed since the last calculation (`timeElapsed`), and the rate for the *current* era (`currentStakingRate`).
    *   The `s_userLastPointCalculationTime` ensures points are only calculated for the duration since the user last interacted with their stake (`stake`, `unstake`, `claimStakingPoints`).

4.  **Evolving Era System (`s_currentEra`, `advanceEra`, `updateStakingRateForEra`, `updateBondingRateForEra`):**
    *   The contract tracks a global `s_currentEra`.
    *   The owner can call `advanceEra` to move to the next stage. This is a simple way to introduce phases into the contract's lifecycle.
    *   Staking and bonding rates are stored *per era* in mappings (`s_stakingRatePerEra`, `s_bondingRatePerEra`). This allows the contract's economic parameters to be adjusted over time, potentially increasing rewards in later eras to incentivize continued participation.
    *   Fragment properties (`getFragmentProperties`) can also incorporate the current era into their calculation logic.

5.  **Interconnected Mechanics:**
    *   Staking -> Earns Chronicle Points
    *   Chronicle Points -> Used to Forge Fragments
    *   Fragments -> Can be Bonded
    *   Bonded Fragments -> Earn *more* Chronicle Points (or potentially other rewards in a more complex version)
    *   User State (Stake, Points) + Global State (Era) -> Affects Fragment Properties

6.  **Gas Efficiency & Security:**
    *   Using custom errors instead of revert strings.
    *   Using OpenZeppelin's `Ownable` for secure access control.
    *   Using OpenZeppelin's `SafeMath` (though checked arithmetic is built-in since 0.8, it's shown as imported).
    *   Avoiding loops over potentially large data sets in public functions where possible (e.g., warning on `getUserFragments`, calculating points only on user interaction).

This contract provides a framework for a gamified progression system on-chain, where user engagement translates into unique, non-transferable digital assets whose characteristics evolve over time, influenced by both individual actions and global contract cycles.