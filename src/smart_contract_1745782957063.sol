Okay, here is a Solidity smart contract implementing a "ChronoGuardians: Dynamic Reputation & Staking Protocol". This protocol combines staking, reputation mechanics, and dynamic NFTs that visually evolve based on user activity and reputation. It aims to be creative by linking these concepts in a way that isn't just a standard staking pool or a static NFT collection.

It includes logic for:
1.  **Staking:** Users stake an ERC-20 token (`StakeToken`).
2.  **Time-Based Accrual:** Users earn both `StakeToken` rewards and a separate `ReputationToken` based on the amount staked and duration. Accruals are calculated on interactions (stake, unstake, claim).
3.  **Reputation System:** Users accumulate `ReputationToken`. This token represents their standing in the protocol.
4.  **Dynamic NFT Integration:** Each staker can mint a unique `GuardianNFT` (ERC-721). This NFT's visual attributes (represented by its metadata URI) are designed to change based on the user's staking duration and earned reputation/experience, facilitated by interactions with a hypothetical `GuardianNFT` contract.
5.  **NFT Forging:** Users can burn their `ReputationToken` to 'forge' their NFT, giving it a direct boost in experience or level, influencing its appearance.
6.  **Simple Delegation:** A basic function for users to signal delegation of their reputation/voting power (though full voting logic is outside the scope of just this contract).
7.  **Owner Controls:** Functions for the protocol owner to set parameters and manage the system.

This contract interacts with external ERC-20 and ERC-721 contracts (which you would deploy separately). The "dynamic" aspect of the NFT relies on the external `GuardianNFT` contract being designed to update its state/metadata based on calls from this staking contract (specifically `forgeBoost`) and potentially based on on-chain data queries (like `getLevel`, `getExperience`, `tokenURI` fetching state *from* the NFT contract).

**Outline & Function Summary**

```
// ChronoGuardians Staking & Reputation Protocol
// This contract allows users to stake StakeToken, earn StakeToken rewards and ReputationToken,
// and interact with a dynamic GuardianNFT whose appearance evolves based on staking activity and reputation.

// Outline:
// 1. Interfaces: IERC20, IERC721, IGuardianNFT (for interacting with external tokens and the dynamic NFT contract).
// 2. Custom Errors: Defined for clarity and gas efficiency.
// 3. Events: To signal important state changes.
// 4. State Variables: Storing token addresses, rates, user data, total stats, pause status.
// 5. UserStakeInfo Struct: Holds all relevant data for each user (staked amount, reputation, NFT ID, accrual info, etc.).
// 6. Modifiers: onlyOwner, whenNotPaused, whenPaused.
// 7. Internal Helpers:
//    - _updateUserAccruals: Calculates and updates pending rewards and reputation based on time.
//    - _calculateAccrual: Pure function to calculate rewards/reputation for a specific duration.
//    - _requireLinkedNFT: Checks if a user has minted and holds the linked NFT.
// 8. Core Staking Functions:
//    - constructor: Initializes the contract with token addresses.
//    - stake: Allows users to deposit StakeToken and start staking.
//    - unstake: Allows users to withdraw staked StakeToken and claim accrued rewards/reputation.
// 9. Claiming Functions:
//    - claimRewards: Claims only pending StakeToken rewards.
//    - claimReputation: Claims only pending ReputationToken.
//    - exitStakingAndClaimAll: Unstakes all tokens and claims all rewards/reputation in one call.
// 10. Dynamic NFT Interaction Functions:
//     - mintGuardianNFT: Allows a user to mint their unique GuardianNFT associated with their staking profile.
//     - forgeNFT: Allows a user to burn ReputationToken to boost their linked GuardianNFT's state/appearance.
// 11. Reputation & Governance Functions:
//     - delegateReputation: Allows a user to delegate their voting power (based on reputation) to another address.
// 12. View Functions (Public / External Pure/View):
//     - getUserStakeInfo: Gets a user's complete staking and reputation data struct.
//     - getUserStakedBalance: Gets the amount of StakeToken staked by a user.
//     - getUserReputation: Gets the amount of ReputationToken earned by a user.
//     - getUserNFTId: Gets the token ID of the GuardianNFT linked to a user.
//     - getNFTLevel: Calls the GuardianNFT contract to get the level of a user's NFT.
//     - getNFTExperience: Calls the GuardianNFT contract to get the experience of a user's NFT.
//     - getNFTMetadataURI: Calls the GuardianNFT contract to get the dynamic metadata URI for a user's NFT.
//     - calculatePendingRewards: Calculates StakeToken rewards accrued since the last update/claim.
//     - calculatePendingReputation: Calculates ReputationToken accrued since the last update/claim.
//     - getEffectiveVotingPower: Gets a user's current voting power (simplified).
//     - getTokenAddresses: Gets the addresses of the StakeToken, ReputationToken, and GuardianNFT contracts.
//     - getTotalStaked: Gets the total amount of StakeToken staked in the contract.
//     - getTotalReputation: Gets the total amount of ReputationToken held by users in the protocol.
//     - getRewardRate: Gets the current StakeToken reward rate per staked token per second.
//     - getReputationRate: Gets the current ReputationToken accrual rate per staked token per second.
//     - getPauseStatus: Gets the current pause status of staking.
// 13. Owner-Only Functions:
//     - setRewardRate: Sets the StakeToken reward rate.
//     - setReputationRate: Sets the ReputationToken accrual rate.
//     - grantReputation: Grants ReputationToken to a specific user (e.g., for contributions).
//     - burnUserReputation: Burns ReputationToken from a specific user (e.g., for penalties).
//     - setTokenAddresses: Allows updating the addresses of the dependent token contracts.
//     - pauseStaking: Pauses staking/unstaking/claiming.
//     - unpauseStaking: Unpauses staking/unstaking/claiming.
//     - recoverERC20: Allows owner to recover misplaced ERC20 tokens (excluding protocol tokens).

// Function Summary (20+ functions demonstrated):
// 1. constructor
// 2. stake
// 3. unstake
// 4. claimRewards
// 5. claimReputation
// 6. exitStakingAndClaimAll
// 7. mintGuardianNFT
// 8. forgeNFT
// 9. delegateReputation
// 10. getUserStakeInfo (View)
// 11. getUserStakedBalance (View)
// 12. getUserReputation (View)
// 13. getUserNFTId (View)
// 14. getNFTLevel (View, calls external)
// 15. getNFTExperience (View, calls external)
// 16. getNFTMetadataURI (View, calls external)
// 17. calculatePendingRewards (View)
// 18. calculatePendingReputation (View)
// 19. getEffectiveVotingPower (View)
// 20. getTokenAddresses (View)
// 21. getTotalStaked (View)
// 22. getTotalReputation (View)
// 23. getRewardRate (View)
// 24. getReputationRate (View)
// 25. getPauseStatus (View)
// 26. setRewardRate (Owner)
// 27. setReputationRate (Owner)
// 28. grantReputation (Owner)
// 29. burnUserReputation (Owner)
// 30. setTokenAddresses (Owner)
// 31. pauseStaking (Owner)
// 32. unpauseStaking (Owner)
// 33. recoverERC20 (Owner)
```

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

// Minimal interface for the dynamic GuardianNFT contract
interface IGuardianNFT is IERC721 {
    // Function to mint a new NFT linked to a staker address
    function mint(address to) external returns (uint256 tokenId);

    // Function called by the Staking contract to boost the NFT's state (experience/level)
    function forgeBoost(uint256 tokenId, uint256 boostAmount) external;

    // View functions to query the NFT's dynamic state
    function getLevel(uint256 tokenId) external view returns (uint8);
    function getExperience(uint256 tokenId) external view returns (uint256);

    // ERC721 metadata function (should potentially be dynamic)
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

contract ChronoGuardians is Ownable, Pausable {
    using SafeERC20 for IERC20;

    // --- State Variables ---

    IERC20 public stakeToken;
    IERC20 public reputationToken;
    IGuardianNFT public guardianNFT;

    // Rates are scaled (e.g., per staked token per second, multiplied by 1e18)
    uint256 public rewardRatePerSecond; // StakeToken rewards
    uint256 public reputationRatePerSecond; // ReputationToken accrual

    struct UserStakeInfo {
        uint256 stakedAmount;       // Amount of StakeToken staked by the user
        uint64 lastUpdateTime;      // Timestamp of the last update (stake, unstake, claim)
        uint256 unclaimedRewards;   // StakeToken rewards accrued but not yet claimed
        uint256 unclaimedReputation; // ReputationToken accrued but not yet claimed
        uint256 reputation;         // Total ReputationToken earned and held by the user (claimed + unclaimed)
        uint256 nftTokenId;         // The token ID of the linked GuardianNFT (0 if none)
        address reputationDelegate; // Address user has delegated reputation to (0x0 if none)
    }

    mapping(address => UserStakeInfo) public userStakeInfo;

    uint256 public totalStakedAmount;
    uint256 public totalReputationAmount; // Total reputation across all users

    // --- Events ---

    event Staked(address indexed user, uint256 amount, uint256 newBalance);
    event Unstaked(address indexed user, uint256 amount, uint256 newBalance);
    event RewardsClaimed(address indexed user, uint256 amount);
    event ReputationClaimed(address indexed user, uint256 amount);
    event NFTMinted(address indexed user, uint256 tokenId);
    event NFTForged(address indexed user, uint256 tokenId, uint256 reputationBurned);
    event ReputationDelegated(address indexed delegator, address indexed delegatee);
    event RewardRateUpdated(uint256 newRate);
    event ReputationRateUpdated(uint256 newRate);
    event ReputationGranted(address indexed user, uint256 amount, address indexed granter);
    event ReputationBurned(address indexed user, uint256 amount, address indexed burner);

    // --- Custom Errors ---

    error InvalidTokenAddress();
    error AmountMustBeGreaterThanZero();
    error NoStakedBalance();
    error StakingActive(); // User must unstake before doing X (e.g., certain NFT actions, though not enforced heavily here)
    error NFTAlreadyMinted();
    error NFTNotMinted();
    error ReputationTooLow(uint256 required, uint256 has);
    error InsufficientReputation(uint256 required, uint256 has); // More specific than ReputationTooLow
    error InvalidAmount();
    error CannotRecoverProtocolToken();

    // --- Constructor ---

    constructor(address _stakeToken, address _reputationToken, address _guardianNFT) Ownable(msg.sender) {
        if (_stakeToken == address(0) || _reputationToken == address(0) || _guardianNFT == address(0)) {
            revert InvalidTokenAddress();
        }
        stakeToken = IERC20(_stakeToken);
        reputationToken = IERC20(_reputationToken);
        guardianNFT = IGuardianNFT(_guardianNFT);

        // Set initial rates (example values)
        rewardRatePerSecond = 1e16; // Example: 0.01 StakeToken per staked token per second (adjust scaling)
        reputationRatePerSecond = 5e15; // Example: 0.005 ReputationToken per staked token per second (adjust scaling)
    }

    // --- Internal Helpers ---

    /// @dev Updates a user's unclaimed rewards and reputation based on time passed.
    function _updateUserAccruals(address _user) internal {
        UserStakeInfo storage userInfo = userStakeInfo[_user];
        uint64 currentTime = uint64(block.timestamp);
        uint64 lastTime = userInfo.lastUpdateTime;
        uint256 staked = userInfo.stakedAmount;

        if (staked > 0 && currentTime > lastTime) {
            uint256 timeElapsed = currentTime - lastTime;
            uint256 rewards = _calculateAccrual(staked, timeElapsed, rewardRatePerSecond);
            uint256 reputationAccrued = _calculateAccrual(staked, timeElapsed, reputationRatePerSecond);

            userInfo.unclaimedRewards += rewards;
            userInfo.unclaimedReputation += reputationAccrued;
            userInfo.reputation += reputationAccrued; // Reputation adds to total pool immediately
            totalReputationAmount += reputationAccrued; // Update total reputation

            userInfo.lastUpdateTime = currentTime;
        } else if (staked == 0 && lastTime > 0) {
             // If staked balance dropped to 0, finalize accruals up to that point
             // (This should already be handled in unstake, but as a safeguard)
             userInfo.lastUpdateTime = currentTime;
        } else if (staked > 0 && lastTime == 0) {
             // First stake, set lastUpdateTime
             userInfo.lastUpdateTime = currentTime;
        }
        // If staked == 0 and lastTime == 0, do nothing
    }

    /// @dev Calculates accrued amount based on staked amount, time, and rate.
    /// @param _stakedAmount The amount staked.
    /// @param _timeElapsed The time duration in seconds.
    /// @param _rate The accrual rate per staked token per second (scaled).
    /// @return The calculated accrued amount.
    function _calculateAccrual(uint256 _stakedAmount, uint256 _timeElapsed, uint256 _rate) internal pure returns (uint256) {
        if (_stakedAmount == 0 || _timeElapsed == 0 || _rate == 0) {
            return 0;
        }
        // Calculation: stakedAmount * timeElapsed * rate / 1e18 (rate scaling)
        // Use intermediate variables to prevent overflow if stakedAmount * timeElapsed is very large
        uint256 accrued = (_stakedAmount / 1e18) * _timeElapsed * _rate;
        // Add remaining part if division resulted in truncation
        accrued += ((_stakedAmount % 1e18) * _timeElapsed * _rate) / 1e18;

        return accrued;
         // A safer approach might involve using full 1e18 multiplication first, then division:
         // return (_stakedAmount * _timeElapsed * _rate) / (1e18 * 1e18);
         // Or simplify rate to be per token per second * 1e18, then:
         // return (_stakedAmount * _timeElapsed * _rate) / (1e18); // This matches the initial intent of rate scaling
         // Let's assume rates are scaled such that the simple calculation works without massive intermediate numbers
         // Or, better yet, use a library for fixed-point math for precision.
         // For this example, we'll use the simpler calculation assuming rates are adjusted for precision.
         // Assuming rate is already scaled such that (staked * rate) is per second,
         // and stakedAmount is in token base units (1e18).
         // Let rate be (value per token per second) * 1e18
         // Accrual = stakedAmount (base units) * timeElapsed (s) * rate (value/token/s * 1e18) / 1e18 (token base units) / 1e18 (rate scaling)
         // Accrual = (stakedAmount * timeElapsed * rate) / 1e36
         // Or if rate is (value per base unit * s) * 1e18
         // Accrual = stakedAmount * timeElapsed * rate / 1e18
         // Let's assume `rewardRatePerSecond` and `reputationRatePerSecond` are the *amount* of the respective token (in base units)
         // earned *per unit of StakeToken (in base units)* per second.
         // So, 1e16 StakeToken / 1e18 StakeToken / second = 0.0001 StakeToken per StakeToken per second.
         // Total rewards = stakedAmount * timeElapsed * rate / 1e18
         return (_stakedAmount * _timeElapsed * _rate) / (1e18); // This seems the most standard interpretation
    }


    /// @dev Internal helper to check if a user has a linked NFT and still owns it.
    function _requireLinkedNFT(address _user) internal view {
        UserStakeInfo storage userInfo = userStakeInfo[_user];
        if (userInfo.nftTokenId == 0) {
            revert NFTNotMinted();
        }
        // Verify the user still owns the registered NFT
        if (guardianNFT.ownerOf(userInfo.nftTokenId) != _user) {
             // This is an important check! If they transferred it, it's no longer linked for dynamic updates.
             // Could potentially burn the link here, but requires non-view state change.
             // For now, just revert if they don't own it when trying to do NFT-related actions.
             revert NFTNotMinted(); // Re-using error, implies NFT is not effectively linked
        }
    }

    // --- Core Staking Functions ---

    /// @notice Stakes `_amount` of StakeToken.
    /// @param _amount The amount of StakeToken to stake.
    function stake(uint256 _amount) external payable whenNotPaused {
        if (_amount == 0) revert AmountMustBeGreaterThanZero();

        address user = _msgSender();
        _updateUserAccruals(user); // Update pending rewards/reputation before staking more

        uint256 currentStaked = userStakeInfo[user].stakedAmount;
        userStakeInfo[user].stakedAmount += _amount;
        totalStakedAmount += _amount;

        // Transfer tokens to the contract
        stakeToken.safeTransferFrom(user, address(this), _amount);

        emit Staked(user, _amount, userStakeInfo[user].stakedAmount);
    }

    /// @notice Unstakes `_amount` of StakeToken and claims all pending rewards/reputation.
    /// @param _amount The amount of StakeToken to unstake.
    function unstake(uint256 _amount) external whenNotPaused {
        address user = _msgSender();
        UserStakeInfo storage userInfo = userStakeInfo[user];

        if (userInfo.stakedAmount == 0) revert NoStakedBalance();
        if (_amount == 0) revert AmountMustBeGreaterThanZero();
        if (_amount > userInfo.stakedAmount) revert InvalidAmount();

        _updateUserAccruals(user); // Finalize accruals before unstaking

        // Transfer staked amount back
        userInfo.stakedAmount -= _amount;
        totalStakedAmount -= _amount;
        stakeToken.safeTransfer(user, _amount);

        // Claim all pending rewards and reputation
        uint256 rewardsToClaim = userInfo.unclaimedRewards;
        uint256 reputationToClaim = userInfo.unclaimedReputation;

        userInfo.unclaimedRewards = 0;
        userInfo.unclaimedReputation = 0;

        if (rewardsToClaim > 0) {
            stakeToken.safeTransfer(user, rewardsToClaim);
            emit RewardsClaimed(user, rewardsToClaim);
        }
        if (reputationToClaim > 0) {
            reputationToken.safeTransfer(user, reputationToClaim);
            emit ReputationClaimed(user, reputationToClaim);
        }

        // If user unstaked their entire balance, reset lastUpdateTime
        if (userInfo.stakedAmount == 0) {
             userInfo.lastUpdateTime = uint64(block.timestamp); // Or set to 0, convention varies. Setting to now is safer for future stakes.
        }

        emit Unstaked(user, _amount, userInfo.stakedAmount);
    }

    // --- Claiming Functions ---

    /// @notice Claims only pending StakeToken rewards.
    function claimRewards() external whenNotPaused {
        address user = _msgSender();
        UserStakeInfo storage userInfo = userStakeInfo[user];

        _updateUserAccruals(user); // Calculate up to now

        uint256 rewardsToClaim = userInfo.unclaimedRewards;
        if (rewardsToClaim == 0) return;

        userInfo.unclaimedRewards = 0; // Reset unclaimed rewards

        stakeToken.safeTransfer(user, rewardsToClaim);

        emit RewardsClaimed(user, rewardsToClaim);
    }

    /// @notice Claims only pending ReputationToken.
    function claimReputation() external whenNotPaused {
        address user = _msgSender();
        UserStakeInfo storage userInfo = userStakeInfo[user];

        _updateUserAccruals(user); // Calculate up to now

        uint256 reputationToClaim = userInfo.unclaimedReputation;
        if (reputationToClaim == 0) return;

        userInfo.unclaimedReputation = 0; // Reset unclaimed reputation

        reputationToken.safeTransfer(user, reputationToClaim);

        emit ReputationClaimed(user, reputationToClaim);
    }

    /// @notice Unstakes all StakeToken and claims all pending rewards and reputation in one transaction.
    function exitStakingAndClaimAll() external whenNotPaused {
        address user = _msgSender();
        UserStakeInfo storage userInfo = userStakeInfo[user];
        uint256 stakedAmount = userInfo.stakedAmount;

        if (stakedAmount == 0) revert NoStakedBalance();

        _updateUserAccruals(user); // Finalize all accruals

        // Claim all pending rewards and reputation
        uint256 rewardsToClaim = userInfo.unclaimedRewards;
        uint256 reputationToClaim = userInfo.unclaimedReputation;

        userInfo.unclaimedRewards = 0;
        userInfo.unclaimedReputation = 0;

        if (rewardsToClaim > 0) {
            stakeToken.safeTransfer(user, rewardsToClaim);
            emit RewardsClaimed(user, rewardsToClaim);
        }
        if (reputationToClaim > 0) {
            reputationToken.safeTransfer(user, reputationToClaim);
            emit ReputationClaimed(user, reputationToClaim);
        }

        // Unstake all amount
        userInfo.stakedAmount = 0;
        totalStakedAmount -= stakedAmount;
        stakeToken.safeTransfer(user, stakedAmount);
        userInfo.lastUpdateTime = uint64(block.timestamp); // Reset time

        emit Unstaked(user, stakedAmount, 0); // Emit unstake event for the full amount
    }


    // --- Dynamic NFT Interaction Functions ---

    /// @notice Allows a user to mint their unique GuardianNFT linked to their staking profile.
    /// Requires a minimum staked amount or reputation threshold (example check).
    function mintGuardianNFT() external whenNotPaused {
        address user = _msgSender();
        UserStakeInfo storage userInfo = userStakeInfo[user];

        if (userInfo.nftTokenId != 0) {
            revert NFTAlreadyMinted();
        }

        // Example requirement: must have staked at least 100 StakeToken (adjust threshold and scaling)
        uint256 minStakeRequirement = 100 * (10 ** uint256(stakeToken.decimals()));
        if (userInfo.stakedAmount < minStakeRequirement) {
            revert ReputationTooLow(minStakeRequirement, userInfo.stakedAmount); // Re-using error for simiplicity
        }
        // Or require minimum reputation:
        // if (userInfo.reputation < minReputationRequirement) revert ReputationTooLow(...);

        // Mint the NFT via the external contract
        uint256 newTokenId = guardianNFT.mint(user);
        userInfo.nftTokenId = newTokenId;

        emit NFTMinted(user, newTokenId);
    }

    /// @notice Allows a user to burn `_amount` of ReputationToken to 'forge' their linked GuardianNFT,
    /// boosting its state/appearance.
    /// @param _amount The amount of ReputationToken to burn for forging.
    function forgeNFT(uint256 _amount) external whenNotPaused {
        address user = _msgSender();
        UserStakeInfo storage userInfo = userStakeInfo[user];

        _requireLinkedNFT(user); // Ensure user has a linked NFT and still owns it.

        if (_amount == 0) revert AmountMustBeGreaterThanZero();

        // Ensure user has enough ReputationToken (claimed + unclaimed is tracked in userInfo.reputation)
        if (userInfo.reputation < _amount) {
             revert InsufficientReputation(_amount, userInfo.reputation);
        }

        // Update accruals before burning reputation
        _updateUserAccruals(user);

        // Burn reputation from user's balance
        userInfo.reputation -= _amount;
        totalReputationAmount -= _amount; // Deduct from total supply as well

        // Call the GuardianNFT contract to apply the forge boost
        // The NFT contract should interpret _amount and apply it as experience/level boost
        guardianNFT.forgeBoost(userInfo.nftTokenId, _amount);

        emit NFTForged(user, userInfo.nftTokenId, _amount);
        emit ReputationBurned(user, _amount, address(this)); // Also emit reputation burn event
    }

    // --- Reputation & Governance Functions ---

    /// @notice Allows a user to delegate their voting power (based on reputation) to another address.
    /// Note: This contract only records the delegation target. Actual voting logic would reside elsewhere,
    /// reading this delegation mapping.
    /// @param _delegatee The address to delegate reputation to.
    function delegateReputation(address _delegatee) external {
        address user = _msgSender();
        // Optional: Could add a check that _delegatee is not address(0) or self

        // Update accruals before delegation to ensure user's current reputation is reflected
        _updateUserAccruals(user);

        userStakeInfo[user].reputationDelegate = _delegatee;

        emit ReputationDelegated(user, _delegatee);
    }

    // --- View Functions (Public / External Pure/View) ---

    /// @notice Gets a user's complete staking and reputation data struct.
    /// @param _user The address of the user.
    /// @return UserStakeInfo struct for the user.
    function getUserStakeInfo(address _user) external view returns (UserStakeInfo memory) {
        // Note: This view does NOT call _updateUserAccruals, so unclaimed amounts
        // and reputation shown here are only updated as of the user's last interaction.
        // Use calculatePendingRewards/Reputation for real-time estimate.
        return userStakeInfo[_user];
    }


    /// @notice Gets the amount of StakeToken staked by a user.
    /// @param _user The address of the user.
    /// @return The staked StakeToken amount.
    function getUserStakedBalance(address _user) external view returns (uint256) {
        return userStakeInfo[_user].stakedAmount;
    }

    /// @notice Gets the amount of ReputationToken earned and held by a user.
    /// @param _user The address of the user.
    /// @return The user's total ReputationToken amount (claimed + pending).
    function getUserReputation(address _user) external view returns (uint256) {
        // Note: This returns total earned reputation as recorded by the contract
        // Use calculatePendingReputation to see how much is *currently* claimable.
        return userStakeInfo[_user].reputation;
    }

    /// @notice Gets the token ID of the GuardianNFT linked to a user's staking profile.
    /// @param _user The address of the user.
    /// @return The NFT token ID, or 0 if no NFT is linked.
    function getUserNFTId(address _user) external view returns (uint256) {
        return userStakeInfo[_user].nftTokenId;
    }

    /// @notice Calls the GuardianNFT contract to get the level of a user's linked NFT.
    /// Requires the user to have a linked NFT that they still own.
    /// @param _user The address of the user.
    /// @return The level of the user's GuardianNFT.
    function getNFTLevel(address _user) external view returns (uint8) {
        _requireLinkedNFT(_user); // Checks if linked and owned
        return guardianNFT.getLevel(userStakeInfo[_user].nftTokenId);
    }

    /// @notice Calls the GuardianNFT contract to get the experience points of a user's linked NFT.
    /// Requires the user to have a linked NFT that they still own.
    /// @param _user The address of the user.
    /// @return The experience points of the user's GuardianNFT.
    function getNFTExperience(address _user) external view returns (uint256) {
        _requireLinkedNFT(_user); // Checks if linked and owned
        return guardianNFT.getExperience(userStakeInfo[_user].nftTokenId);
    }

    /// @notice Calls the GuardianNFT contract to get the dynamic metadata URI for a user's linked NFT.
    /// Requires the user to have a linked NFT that they still own.
    /// @param _user The address of the user.
    /// @return The metadata URI of the user's GuardianNFT.
    function getNFTMetadataURI(address _user) external view returns (string memory) {
        _requireLinkedNFT(_user); // Checks if linked and owned
        return guardianNFT.tokenURI(userStakeInfo[_user].nftTokenId);
    }

    /// @notice Calculates the StakeToken rewards accrued since the user's last update time.
    /// This is a real-time calculation and does not modify state.
    /// @param _user The address of the user.
    /// @return The amount of pending StakeToken rewards.
    function calculatePendingRewards(address _user) external view returns (uint256) {
        UserStakeInfo storage userInfo = userStakeInfo[_user];
        uint256 staked = userInfo.stakedAmount;
        uint64 lastTime = userInfo.lastUpdateTime;
        uint64 currentTime = uint64(block.timestamp);

        if (staked > 0 && currentTime > lastTime) {
            uint256 timeElapsed = currentTime - lastTime;
            uint256 rewards = _calculateAccrual(staked, timeElapsed, rewardRatePerSecond);
            return userInfo.unclaimedRewards + rewards;
        }
        return userInfo.unclaimedRewards;
    }

    /// @notice Calculates the ReputationToken accrued since the user's last update time.
    /// This is a real-time calculation and does not modify state.
    /// @param _user The address of the user.
    /// @return The amount of pending ReputationToken.
    function calculatePendingReputation(address _user) external view returns (uint256) {
        UserStakeInfo storage userInfo = userStakeInfo[_user];
        uint256 staked = userInfo.stakedAmount;
        uint64 lastTime = userInfo.lastUpdateTime;
        uint64 currentTime = uint64(block.timestamp);

        if (staked > 0 && currentTime > lastTime) {
            uint256 timeElapsed = currentTime - lastTime;
            uint256 reputationAccrued = _calculateAccrual(staked, timeElapsed, reputationRatePerSecond);
            return userInfo.unclaimedReputation + reputationAccrued;
        }
        return userInfo.unclaimedReputation;
    }

     /// @notice Gets the amount of unclaimed StakeToken rewards stored in the user's struct.
     /// Note: This shows the amount calculated *as of the last state-changing interaction*, not real-time.
     /// Use `calculatePendingRewards` for real-time.
     /// @param _user The address of the user.
     /// @return The amount of unclaimed StakeToken rewards.
     function getUnclaimedRewards(address _user) external view returns (uint256) {
         return userStakeInfo[_user].unclaimedRewards;
     }

     /// @notice Gets the amount of unclaimed ReputationToken stored in the user's struct.
     /// Note: This shows the amount calculated *as of the last state-changing interaction*, not real-time.
     /// Use `calculatePendingReputation` for real-time.
     /// @param _user The address of the user.
     /// @return The amount of unclaimed ReputationToken.
     function getUnclaimedReputation(address _user) external view returns (uint256) {
         return userStakeInfo[_user].unclaimedReputation;
     }

    /// @notice Gets a user's current voting power.
    /// (Simplified: Currently just returns their total accumulated reputation).
    /// In a real DAO, this might factor in staked amount, delegation, lock-up periods, etc.
    /// @param _user The address of the user.
    /// @return The user's effective voting power.
    function getEffectiveVotingPower(address _user) external view returns (uint256) {
        // Could factor in delegation:
        // address delegatee = userStakeInfo[_user].reputationDelegate;
        // if (delegatee == address(0)) return userStakeInfo[_user].reputation;
        // else return userStakeInfo[_user].reputation + getUserReputation(delegatee); // Or sum up delegated power... this gets complex
        // Simple: just return the user's own reputation
        return userStakeInfo[_user].reputation;
    }

    /// @notice Gets the addresses of the StakeToken, ReputationToken, and GuardianNFT contracts.
    /// @return stakeTokenAddress, reputationTokenAddress, guardianNFTAddress
    function getTokenAddresses() external view returns (address, address, address) {
        return (address(stakeToken), address(reputationToken), address(guardianNFT));
    }

    /// @notice Gets the total amount of StakeToken staked in the contract.
    /// @return The total staked StakeToken amount.
    function getTotalStaked() external view returns (uint256) {
        return totalStakedAmount;
    }

    /// @notice Gets the total amount of ReputationToken accumulated across all users in the protocol.
    /// This includes claimed and unclaimed amounts held within the protocol's state.
    /// It does NOT include ReputationToken transferred out of the protocol.
    /// @return The total ReputationToken amount managed by the protocol.
    function getTotalReputation() external view returns (uint256) {
        return totalReputationAmount;
    }

    /// @notice Gets the current StakeToken reward rate per staked token per second (scaled).
    /// @return The current reward rate.
    function getRewardRate() external view returns (uint256) {
        return rewardRatePerSecond;
    }

    /// @notice Gets the current ReputationToken accrual rate per staked token per second (scaled).
    /// @return The current reputation rate.
    function getReputationRate() external view returns (uint256) {
        return reputationRatePerSecond;
    }

    /// @notice Gets the current pause status of staking.
    /// @return True if staking is paused, false otherwise.
    function getPauseStatus() external view returns (bool) {
        return paused();
    }

     /// @notice Gets the last time a user's staking/reputation accruals were updated.
     /// @param _user The address of the user.
     /// @return The timestamp of the last update.
     function getUserLastUpdateTime(address _user) external view returns (uint64) {
         return userStakeInfo[_user].lastUpdateTime;
     }


    // --- Owner-Only Functions ---

    /// @notice Sets the StakeToken reward rate per staked token per second (scaled).
    /// Only callable by the owner.
    /// @param _newRate The new reward rate.
    function setRewardRate(uint256 _newRate) external onlyOwner {
        rewardRatePerSecond = _newRate;
        emit RewardRateUpdated(_newRate);
    }

    /// @notice Sets the ReputationToken accrual rate per staked token per second (scaled).
    /// Only callable by the owner.
    /// @param _newRate The new reputation rate.
    function setReputationRate(uint256 _newRate) external onlyOwner {
        reputationRatePerSecond = _newRate;
        emit ReputationRateUpdated(_newRate);
    }

    /// @notice Grants ReputationToken to a specific user.
    /// This can be used for rewarding contributions, bounties, etc.
    /// Increases the user's total reputation and the protocol's total reputation.
    /// Only callable by the owner.
    /// @param _user The address of the user to grant reputation to.
    /// @param _amount The amount of ReputationToken to grant.
    function grantReputation(address _user, uint256 _amount) external onlyOwner {
        if (_amount == 0) revert AmountMustBeGreaterThanZero();
        if (_user == address(0)) revert InvalidAmount();

        // Optional: update accruals before granting, though less critical here as it's a direct grant.
        // _updateUserAccruals(_user);

        userStakeInfo[_user].reputation += _amount;
        totalReputationAmount += _amount;

        // Note: This does not transfer tokens from the contract to the user.
        // It increases their internal reputation balance managed by this contract.
        // Actual tokens would be minted by the ReputationToken contract or handled separately.
        // For this example, we assume ReputationToken balance is managed internally.
        // If ReputationToken is a standard ERC20 where balance is external, this function
        // would need to mint tokens or transfer from an owner-controlled supply.
        // Sticking to internal reputation balance for this example's complexity.

        emit ReputationGranted(_user, _amount, _msgSender());
    }

    /// @notice Burns ReputationToken from a specific user's balance.
    /// Can be used for penalties or correcting errors.
    /// Decreases the user's total reputation and the protocol's total reputation.
    /// Only callable by the owner.
    /// @param _user The address of the user whose reputation to burn.
    /// @param _amount The amount of ReputationToken to burn.
    function burnUserReputation(address _user, uint256 _amount) external onlyOwner {
        if (_amount == 0) revert AmountMustBeGreaterThanZero();
        if (_user == address(0)) revert InvalidAmount();

        UserStakeInfo storage userInfo = userStakeInfo[_user];
        if (userInfo.reputation < _amount) {
             revert InsufficientReputation(_amount, userInfo.reputation);
        }

        // Optional: update accruals before burning
        // _updateUserAccruals(_user);

        userInfo.reputation -= _amount;
        totalReputationAmount -= _amount;

        emit ReputationBurned(_user, _amount, _msgSender());
    }

     /// @notice Sets the addresses of the StakeToken, ReputationToken, and GuardianNFT contracts.
     /// Use with caution, as changing token addresses could break functionality if not handled correctly.
     /// Only callable by the owner.
     /// @param _stakeToken The address of the StakeToken contract.
     /// @param _reputationToken The address of the ReputationToken contract.
     /// @param _guardianNFT The address of the GuardianNFT contract.
     function setTokenAddresses(address _stakeToken, address _reputationToken, address _guardianNFT) external onlyOwner {
         if (_stakeToken == address(0) || _reputationToken == address(0) || _guardianNFT == address(0)) {
             revert InvalidTokenAddress();
         }
         stakeToken = IERC20(_stakeToken);
         reputationToken = IERC20(_reputationToken);
         guardianNFT = IGuardianNFT(_guardianNFT);
     }

    /// @notice Pauses staking, unstaking, and claiming functions.
    /// Only callable by the owner.
    function pauseStaking() external onlyOwner {
        _pause();
    }

    /// @notice Unpauses staking, unstaking, and claiming functions.
    /// Only callable by the owner.
    function unpauseStaking() external onlyOwner {
        _unpause();
    }

    /// @notice Allows the owner to recover ERC20 tokens sent accidentally to the contract,
    /// excluding the StakeToken, ReputationToken, and any tokens explicitly intended
    /// to be held by the contract (like rewards).
    /// @param tokenAddress The address of the ERC20 token to recover.
    /// @param amount The amount of tokens to recover.
    function recoverERC20(address tokenAddress, uint256 amount) external onlyOwner {
        if (tokenAddress == address(stakeToken) || tokenAddress == address(reputationToken) || tokenAddress == address(0)) {
            revert CannotRecoverProtocolToken();
        }
        IERC20(tokenAddress).safeTransfer(owner(), amount);
    }
}
```

**Explanation of Concepts & Creativity:**

1.  **Time-Based Accrual & Unclaimed Balances:** This is a standard pattern for staking, but crucial for calculating dynamic rewards and reputation accurately based on duration. The `_updateUserAccruals` helper ensures that pending amounts are calculated and added to `unclaimedRewards` and `unclaimedReputation` in the `UserStakeInfo` struct every time a user interacts with the core functions (`stake`, `unstake`, `claimRewards`, `claimReputation`, `forgeNFT`, `exitStakingAndClaimAll`).
2.  **ReputationToken Mechanics:** The contract uses an internal `reputation` balance per user, which is increased by staking over time and can be directly manipulated by the owner (`grantReputation`, `burnUserReputation`). This internal balance is also what's claimed as `ReputationToken` ERC-20s. This creates a separate, protocol-specific metric beyond just staked value.
3.  **Dynamic NFT Integration (`IGuardianNFT`):** The most creative part is the concept of the `GuardianNFT`. This contract doesn't *manage* the NFT state/metadata itself but *interacts* with an external ERC-721 contract (`IGuardianNFT`) that is designed to be dynamic.
    *   `mintGuardianNFT`: This function allows users to claim their unique NFT. Crucially, the NFT contract's `mint` function is called, and the returned token ID is stored, linking a specific NFT to the user's staking profile in *this* contract's state.
    *   `forgeNFT`: This function explicitly links the `ReputationToken` to the NFT's appearance. Burning reputation calls a specific `forgeBoost` function on the `IGuardianNFT` contract. The idea is that the NFT contract interprets this boost (e.g., adds experience points, triggers a level-up calculation) which in turn affects its `tokenURI` (metadata), changing its appearance.
    *   View Functions (`getNFTLevel`, `getNFTExperience`, `getNFTMetadataURI`): These functions demonstrate how external applications would query the *dynamic state* of the NFT by calling back to the `IGuardianNFT` contract using the linked `nftTokenId`. The `tokenURI` function is the standard ERC-721 way to get metadata, but in a dynamic NFT, this URI should point to a service that generates metadata reflecting the NFT's current level, experience, etc.
    *   `_requireLinkedNFT`: This internal helper is vital. It not only checks if a user has a linked NFT ID but also verifies that the user *still owns* that specific NFT token ID by calling `guardianNFT.ownerOf()`. If they've transferred it, the link is broken for actions that require owning the NFT, preventing transferred NFTs from continuing to benefit from the original staker's actions.
4.  **Delegation (Simple):** While basic, including `delegateReputation` shows how a staking/reputation contract can include hooks for future governance integrations, allowing users to assign their voting power. `getEffectiveVotingPower` is a placeholder but shows where the calculation based on delegation might happen.
5.  **Modularity:** By interacting with external token and NFT contracts via interfaces, the system is more modular. The specific logic of how the NFT levels up or changes appearance is contained within the `IGuardianNFT` contract, keeping the staking contract focused on staking, reputation, and the triggers for NFT dynamics.
6.  **Error Handling & Events:** Using custom errors and detailed events is standard good practice in modern Solidity development for clarity and frontend integration.
7.  **Pausable:** Including the `Pausable` pattern from OpenZeppelin is crucial for being able to pause sensitive operations in case of upgrades or emergencies.

This contract provides a foundation for a dynamic ecosystem where user engagement in staking directly influences their standing (reputation) and the visual representation of their status (dynamic NFT), linked by a conscious "forging" action burning their earned reputation.