Okay, let's design an interesting and advanced smart contract. We'll combine elements of staking, reputation systems, dynamic NFTs, and decay mechanisms.

**Concept:**

A system where users stake tokens to earn non-transferable reputation points. Users can also mint a unique NFT that is linked to their reputation score. The NFT's attributes (like level or utility multiplier) dynamically change based on the owner's reputation score within the system. The reputation score also decays slowly over time if the user is inactive (not staking or claiming). There will also be a system for owner-attested "challenges" that grant bonus reputation.

**Contract Name:** `ChronicleForgeAndReputationNexus`

**Advanced Concepts Used:**

1.  **Dynamic On-Chain NFT Attributes:** NFT properties (Level, Multiplier) stored and updated *on-chain* based on external factors (user reputation).
2.  **Decaying Reputation Score:** A user's reputation score decreases over time if not actively maintained through staking or claiming.
3.  **Staking with Dynamic Accrual:** Reputation accrual rate is influenced by the linked dynamic NFT.
4.  **Linked ERC721/Reputation:** A single ERC721 NFT is tied to a user's reputation within the contract, and its utility is linked to the *current owner's* reputation in *this specific system*. Transferring the NFT means the new owner's reputation determines its dynamic state/utility.
5.  **Owner-Attested Challenges:** A simple mechanism for off-chain actions or achievements to grant on-chain reputation.
6.  **Withdrawal Fee Treasury:** A basic fee mechanism to collect funds from stake withdrawals.
7.  **Pausability and Ownership:** Standard but essential patterns.

**Outline & Function Summary:**

1.  **State Variables:**
    *   Mappings to track staked amounts, last staking/claim time, total reputation points, user NFT IDs, NFT ownership linkage.
    *   Structs for Challenge data and User state information (staked amount, start time, last update, accrued unclaimed points, total claimed points).
    *   Addresses for the staking token and treasury.
    *   Parameters for reputation accrual rates, decay rates, NFT level thresholds, withdrawal fees.
    *   Counters for NFT IDs and Challenge IDs.

2.  **Events:**
    *   `Staked`: Logs user, amount, total staked.
    *   `Withdrawn`: Logs user, amount, fee.
    *   `NFTMinted`: Logs user and new token ID.
    *   `ReputationClaimed`: Logs user, points claimed, new total reputation.
    *   `ReputationDecayed`: Logs user, points decayed, new total reputation.
    *   `LevelUp`: Logs user, token ID, new level.
    *   `ChallengeAdded`: Logs challenge ID and details.
    *   `ChallengeCompleted`: Logs user and challenge ID.
    *   `ParametersUpdated`: Generic event for owner configuration changes.

3.  **Modifiers:**
    *   `onlyOwner`: Restricts function access to the contract owner.
    *   `whenNotPaused`: Prevents execution if the contract is paused.
    *   `whenPaused`: Allows execution only if the contract is paused.
    *   `userHasNFT`: Requires the calling user to own an NFT linked to this system.

4.  **Constructor:**
    *   Initializes contract owner, staking token address, and treasury address.

5.  **Reputation & Staking Logic:**
    *   `stake(uint256 amount)`: Deposit `StakeToken`. Updates user's staking state, accrues any pending reputation *before* restaking.
    *   `withdraw(uint256 amount)`: Withdraw `StakeToken`. Calculates withdrawal fee, transfers tokens, updates staking state, accrues pending reputation *before* withdrawal.
    *   `getCurrentReputationPoints(address user)`: *View function*. Calculates the user's real-time reputation points including accrued but unclaimed points, applying potential decay. Does *not* modify state.
    *   `claimReputationPoints()`: Finalizes accrued reputation points for the caller. Applies decay and updates the user's total reputation state. Triggers NFT level updates if thresholds are crossed.
    *   `getClaimableReputationPoints(address user)`: *View function*. Calculates points accrued since the last update/claim for a user.
    *   `_calculateAccruedReputation(address user)`: *Internal*. Calculates reputation earned based on staking duration, amount, and multiplier since last update.
    *   `_applyDecay(address user)`: *Internal*. Calculates and applies reputation decay based on inactivity duration and decay rate.
    *   `getTotalStaked(address user)`: *View function*. Gets the current staked amount for a user.
    *   `getTotalSystemStaked()`: *View function*. Gets the total amount staked in the contract.

6.  **NFT Logic (ERC721):**
    *   `mintChronicleForgeNFT()`: Mints a new unique NFT for the caller if they don't already have one linked.
    *   `burnNFT(uint256 tokenId)`: Allows the NFT owner to burn their linked NFT. Requires the NFT to be linked to the caller.
    *   `getNFTLevel(uint256 tokenId)`: *View function*. Calculates the dynamic level of a specific NFT based on its *current owner's* total reputation points in the system.
    *   `getNFTMultiplier(uint256 tokenId)`: *View function*. Calculates the dynamic reputation multiplier of a specific NFT based on its *current owner's* total reputation points and level.
    *   `getNFTAttributes(uint256 tokenId)`: *View function*. Returns both level and multiplier for a specific NFT.
    *   `getUserNFTId(address user)`: *View function*. Returns the token ID of the NFT linked to a user, or 0 if none.
    *   `getUserNFTAttributes(address user)`: *View function*. Returns the level and multiplier for the NFT linked to a user.
    *   `tokenURI(uint256 tokenId)`: *Override*. Returns a metadata URI for the NFT. This should ideally point to a dynamic service that reflects the on-chain attributes (level, multiplier).

7.  **Challenge Logic:**
    *   `addChallenge(string calldata description, uint256 reputationReward)`: *Owner only*. Defines a new challenge.
    *   `completeChallengeByOwner(address user, uint256 challengeId)`: *Owner only*. Attests that a specific user completed a specific challenge, granting the reputation reward. Prevents duplicate completion.
    *   `getChallengeDetails(uint256 challengeId)`: *View function*. Get description and reward for a challenge.
    *   `getChallengeCompletionStatus(address user, uint256 challengeId)`: *View function*. Checks if a user has completed a specific challenge.

8.  **Configuration (Owner-only):**
    *   `setReputationLevelThresholds(uint256[] calldata _thresholds)`: Sets the reputation points required for each NFT level.
    *   `setBaseReputationAccrualRate(uint256 ratePerTokenPerSecond)`: Sets the base rate of reputation earned per staked token per second.
    *   `setReputationDecayParameters(uint256 ratePerSecond, uint256 inactivityThreshold)`: Sets the decay rate and the inactivity duration before decay starts.
    *   `setWithdrawalFeeRate(uint256 feeBips)`: Sets the fee rate for stake withdrawals (in basis points).
    *   `setNFTBaseMultiplier(uint256 baseMultiplierBips)`: Sets the base multiplier for reputation accrual provided by an NFT at level 0.
    *   `setNFTLevelMultiplierBonus(uint256 bonusPerLevelBips)`: Sets the additional multiplier bonus per NFT level.

9.  **Treasury Logic:**
    *   `withdrawTreasury(uint256 amount)`: *Owner only*. Withdraws collected withdrawal fees from the contract balance.

10. **Pausability:**
    *   `pause()`: *Owner only*. Pauses core contract functions (staking, claiming, minting, challenge completion).
    *   `unpause()`: *Owner only*. Unpauses the contract.

11. **Internal/Helper Functions:**
    *   `_updateReputationAndState(address user)`: Internal helper to calculate/apply accrual and decay.
    *   `_getNFTLevelForReputation(uint256 reputation)`: Pure helper to determine level from reputation points using thresholds.
    *   `_getNFTMultiplierForLevel(uint256 level)`: Pure helper to determine multiplier from level using base and bonus rates.
    *   Overrides for ERC721 transfer hooks (`_beforeTokenTransfer`, `_afterTokenTransfer`) if needed for system linkage - *Let's simplify and have the getters calculate based on current holder's state*.

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";

/**
 * @title ChronicleForgeAndReputationNexus
 * @dev A smart contract combining token staking, a dynamic and decaying reputation system,
 * linked ERC721 NFTs with attributes based on reputation, and challenge completion.
 *
 * Outline:
 * 1. State Variables: Stores contract state including user data, staking info, reputation, NFT linkage,
 *    challenge data, configuration parameters, and token addresses.
 * 2. Events: Logs significant actions like staking, withdrawal, NFT minting, reputation changes, etc.
 * 3. Modifiers: Access control (onlyOwner, Pausable) and custom checks (userHasNFT).
 * 4. Constructor: Initializes owner, token addresses.
 * 5. Reputation & Staking Logic: Functions for staking, withdrawing, claiming reputation, and calculating
 *    reputation accrual/decay.
 * 6. NFT Logic (ERC721): Functions for minting, burning, and retrieving dynamic NFT attributes based on reputation.
 * 7. Challenge Logic: Functions for owner to add challenges and attest user completion, granting reputation.
 * 8. Configuration: Owner-only functions to set system parameters (rates, thresholds, fees).
 * 9. Treasury Logic: Owner-only function to withdraw collected fees.
 * 10. Pausability: Owner-only functions to pause/unpause core operations.
 * 11. Internal/Helper Functions: Logic for calculations (_calculateAccruedReputation, _applyDecay)
 *     and dynamic attribute determination (_getNFTLevelForReputation, _getNFTMultiplierForLevel).
 */
contract ChronicleForgeAndReputationNexus is ERC721, Ownable, Pausable {
    using SafeERC20 for IERC20;
    using Counters for Counters.Counter;
    using Math for uint256; // For safe operations, specifically max/min

    IERC20 public immutable stakeToken;
    address public treasuryAddress;

    struct UserState {
        uint256 stakedAmount;
        uint256 stakeStartTime; // When they started staking (or last withdrew fully)
        uint256 lastReputationUpdateTime; // Last time reputation was calculated/state updated
        uint256 accruedUnclaimedReputation; // Reputation earned since last claim/update
        uint256 totalClaimedReputation; // Total reputation points finalized
        uint256 linkedNFTId; // 0 if no linked NFT
    }

    struct Challenge {
        string description;
        uint256 reputationReward;
        bool exists; // To check if a challengeId is valid
    }

    mapping(address => UserState) public userStates;
    mapping(address => uint256) public totalStakedByAddress; // Simple sum, UserState holds breakdown
    uint256 public totalSystemStaked;

    mapping(uint256 => Challenge) public challenges;
    mapping(uint256 => mapping(address => bool)) public challengeCompleted; // challengeId => user => completed?
    Counters.Counter private _challengeIds;

    // Dynamic NFT Level/Multiplier parameters
    uint256[] public reputationLevelThresholds; // Reputation points required for level 1, 2, 3...
    uint256 public nftBaseMultiplierBips = 10000; // Base multiplier (100% = 10000 basis points)
    uint256 public nftLevelMultiplierBonusBips = 1000; // Bonus multiplier per level (e.g., 10% per level)

    // Reputation accrual parameters
    uint256 public baseReputationAccrualRatePerTokenPerSecond; // How many points earned per staked token per second

    // Reputation decay parameters
    uint256 public reputationDecayRatePerSecond; // How many points decay per second inactive
    uint256 public inactivityThresholdForDecay; // Seconds of inactivity before decay starts

    // Withdrawal fee parameters
    uint256 public withdrawalFeeBips = 0; // Fee in basis points (e.g., 100 = 1%)

    // NFT Counter
    Counters.Counter private _tokenIds;

    // --- Events ---
    event Staked(address indexed user, uint256 amount, uint256 newTotalStaked);
    event Withdrawn(address indexed user, uint256 amount, uint256 feeAmount);
    event NFTMinted(address indexed user, uint256 indexed tokenId);
    event ReputationClaimed(address indexed user, uint256 claimedAmount, uint256 newTotalReputation);
    event ReputationDecayed(address indexed user, uint256 decayedAmount, uint256 newTotalReputation);
    event LevelUp(address indexed user, uint256 indexed tokenId, uint256 newLevel);
    event ChallengeAdded(uint256 indexed challengeId, string description, uint256 reputationReward);
    event ChallengeCompleted(address indexed user, uint256 indexed challengeId);
    event ParametersUpdated();

    // --- Modifiers ---
    modifier userHasNFT(address user) {
        require(userStates[user].linkedNFTId != 0, "User must have a linked NFT");
        _;
    }

    // --- Constructor ---
    constructor(address _stakeToken, address _treasuryAddress)
        ERC721("Chronicle Forge NFT", "CFN")
        Ownable(msg.sender)
        Pausable()
    {
        require(_stakeToken != address(0), "Invalid stake token address");
        require(_treasuryAddress != address(0), "Invalid treasury address");
        stakeToken = IERC20(_stakeToken);
        treasuryAddress = _treasuryAddress;

        // Set some reasonable defaults (can be changed by owner)
        baseReputationAccrualRatePerTokenPerSecond = 1; // 1 point per token per second
        reputationDecayRatePerSecond = 1; // 1 point decay per second
        inactivityThresholdForDecay = 30 days; // Decay starts after 30 days of inactivity
        reputationLevelThresholds = [100000, 500000, 1000000, 5000000]; // Example thresholds
    }

    // --- Pausability ---
    function pause() public onlyOwner whenNotPaused {
        _pause();
    }

    function unpause() public onlyOwner whenPaused {
        _unpause();
    }

    // --- Staking Logic ---

    /**
     * @dev Stakes `amount` of stakeToken. User must approve this contract first.
     * Accrues any pending reputation before updating state.
     * @param amount The amount of stakeToken to stake.
     */
    function stake(uint256 amount) public whenNotPaused {
        require(amount > 0, "Amount must be greater than 0");

        // Update reputation and state before changing stake
        _updateReputationAndState(msg.sender);

        uint256 currentStaked = userStates[msg.sender].stakedAmount;
        userStates[msg.sender].stakedAmount = currentStaked + amount;
        userStates[msg.sender].stakeStartTime = block.timestamp; // Reset timer on new stake
        userStates[msg.sender].lastReputationUpdateTime = block.timestamp; // Update last update time

        totalStakedByAddress[msg.sender] += amount;
        totalSystemStaked += amount;

        stakeToken.safeTransferFrom(msg.sender, address(this), amount);

        emit Staked(msg.sender, amount, userStates[msg.sender].stakedAmount);
    }

    /**
     * @dev Withdraws `amount` of stakeToken. Applies a withdrawal fee.
     * Accrues any pending reputation before updating state.
     * @param amount The amount of stakeToken to withdraw.
     */
    function withdraw(uint256 amount) public whenNotPaused {
        UserState storage userState = userStates[msg.sender];
        require(amount > 0, "Amount must be greater than 0");
        require(amount <= userState.stakedAmount, "Insufficient staked balance");

        // Update reputation and state before changing stake
        _updateReputationAndState(msg.sender);

        userState.stakedAmount -= amount;
        userState.lastReputationUpdateTime = block.timestamp; // Update last update time

        uint256 feeAmount = amount.mul(withdrawalFeeBips) / 10000;
        uint256 amountToUser = amount - feeAmount;

        totalStakedByAddress[msg.sender] -= amount;
        totalSystemStaked -= amount;

        if (userState.stakedAmount == 0) {
            userState.stakeStartTime = 0; // Reset stake start time if fully withdrawn
        }

        if (feeAmount > 0) {
            stakeToken.safeTransfer(treasuryAddress, feeAmount);
        }
        stakeToken.safeTransfer(msg.sender, amountToUser);

        emit Withdrawn(msg.sender, amountToUser, feeAmount);
    }

    /**
     * @dev Gets the currently staked amount for a user.
     * @param user The address of the user.
     * @return uint256 The staked amount.
     */
    function getTotalStaked(address user) public view returns (uint256) {
        return userStates[user].stakedAmount;
    }

    /**
     * @dev Gets the total amount staked across all users in the contract.
     * @return uint256 The total system staked amount.
     */
    function getTotalSystemStaked() public view returns (uint256) {
        return totalSystemStaked;
    }

    // --- Reputation Logic ---

    /**
     * @dev Calculates and returns the user's current effective reputation points,
     * including accrued but unclaimed points and applying decay. Does not modify state.
     * @param user The address of the user.
     * @return uint256 The user's current calculated reputation points.
     */
    function getCurrentReputationPoints(address user) public view returns (uint256) {
        UserState storage userState = userStates[user];
        uint256 currentTotal = userState.totalClaimedReputation + userState.accruedUnclaimedReputation;

        if (userState.lastReputationUpdateTime == 0) {
            return currentTotal; // No history, no decay or accrual to calculate
        }

        uint256 timeElapsedSinceLastUpdate = block.timestamp - userState.lastReputationUpdateTime;

        // Add accrued reputation
        uint256 accrued = 0;
        if (userState.stakedAmount > 0) {
            uint256 multiplier = getUserReputationMultiplier(user);
             // Accrual formula: stakedAmount * rate * time * multiplier / 10000
            accrued = userState.stakedAmount.mul(baseReputationAccrualRatePerTokenPerSecond).mul(timeElapsedSinceLastUpdate).mul(multiplier) / 10000;
        }

        currentTotal += accrued;

        // Apply decay if inactive
        if (userState.stakedAmount == 0 && userState.stakeStartTime == 0 && timeElapsedSinceLastUpdate > inactivityThresholdForDecay) {
             uint256 timeInactiveBeyondThreshold = timeElapsedSinceLastUpdate - inactivityThresholdForDecay;
             uint256 decayAmount = timeInactiveBeyondThreshold.mul(reputationDecayRatePerSecond);
             currentTotal = currentTotal > decayAmount ? currentTotal - decayAmount : 0;
        }

        return currentTotal;
    }

    /**
     * @dev Finalizes the user's accrued reputation points, applying decay,
     * and updates their total claimed reputation. Triggers NFT level update.
     */
    function claimReputationPoints() public whenNotPaused {
        _updateReputationAndState(msg.sender); // Calculate and finalize pending reputation/decay
    }

     /**
     * @dev Calculates and returns the user's reputation points accrued since the last state update/claim.
     * This is the `accruedUnclaimedReputation` stored in state, not the full current calculated amount.
     * Use `getCurrentReputationPoints` for the real-time value.
     * @param user The address of the user.
     * @return uint256 The accrued but unclaimed reputation points.
     */
    function getClaimableReputationPoints(address user) public view returns (uint256) {
         UserState storage userState = userStates[user];
         if (userState.lastReputationUpdateTime == 0) {
             return 0;
         }

         uint256 timeElapsedSinceLastUpdate = block.timestamp - userState.lastReputationUpdateTime;

         // Calculate *additional* accrued points since last update
         uint256 accrued = 0;
         if (userState.stakedAmount > 0) {
             uint256 multiplier = getUserReputationMultiplier(user);
             accrued = userState.stakedAmount.mul(baseReputationAccrualRatePerTokenPerSecond).mul(timeElapsedSinceLastUpdate).mul(multiplier) / 10000;
         }

         // Decay is *not* applied here, it's only applied during _updateReputationAndState
         return userState.accruedUnclaimedReputation + accrued;
    }


    /**
     * @dev Internal helper to calculate, apply, and finalize reputation accrual and decay.
     * Updates `totalClaimedReputation` and resets `accruedUnclaimedReputation`.
     * @param user The address of the user.
     */
    function _updateReputationAndState(address user) internal {
        UserState storage userState = userStates[user];
        uint256 currentTime = block.timestamp;

        if (userState.lastReputationUpdateTime == 0) {
             // First time update, initialize timestamp
             userState.lastReputationUpdateTime = currentTime;
             emit ReputationClaimed(user, 0, userState.totalClaimedReputation); // Log claim even if 0 for state tracking
             return;
         }

        uint256 timeElapsed = currentTime - userState.lastReputationUpdateTime;
        if (timeElapsed == 0) {
            // No time elapsed, nothing to update
             emit ReputationClaimed(user, 0, userState.totalClaimedReputation);
            return;
        }

        // Calculate accrued reputation
        uint256 accrued = 0;
        if (userState.stakedAmount > 0) {
            uint256 multiplier = getUserReputationMultiplier(user); // Get multiplier for the user's NFT
            accrued = userState.stakedAmount.mul(baseReputationAccrualRatePerTokenPerSecond).mul(timeElapsed).mul(multiplier) / 10000;
        }

        // Add newly accrued points to unclaimed
        userState.accruedUnclaimedReputation += accrued;

        // Apply decay if inactive (not staking and not just started staking)
        uint256 decayAmount = 0;
        if (userState.stakedAmount == 0 && userState.stakeStartTime == 0 && timeElapsed > inactivityThresholdForDecay) {
             uint256 timeInactiveBeyondThreshold = timeElapsed - inactivityThresholdForDecay;
             decayAmount = timeInactiveBeyondThreshold.mul(reputationDecayRatePerSecond);
             uint256 oldReputation = userState.totalClaimedReputation + userState.accruedUnclaimedReputation;
             uint256 newReputation = oldReputation > decayAmount ? oldReputation - decayAmount : 0;
             uint256 actualDecay = oldReputation - newReputation; // Amount actually decayed
             userState.totalClaimedReputation = newReputation; // Decay total
             userState.accruedUnclaimedReputation = 0; // Decay clears accrued

             emit ReputationDecayed(user, actualDecay, userState.totalClaimedReputation);

        } else {
             // If active or within threshold, just finalize accrued
             userState.totalClaimedReputation += userState.accruedUnclaimedReputation;
             userState.accruedUnclaimedReputation = 0;
        }

        userState.lastReputationUpdateTime = currentTime; // Update timestamp

        emit ReputationClaimed(user, accrued, userState.totalClaimedReputation); // Log reputation finalization/claim

        // Check and trigger NFT level update
        if (userState.linkedNFTId != 0) {
            uint256 currentLevel = _getNFTLevelForReputation(userState.totalClaimedReputation);
            // Note: We don't store the level explicitly on the NFT, only calculate it.
            // A real-world dynamic NFT might update metadata URL or on-chain traits here.
            // For this example, we'll just emit an event if the level changes implicitly.
             uint256 oldLevel = _getNFTLevelForReputation(userState.totalClaimedReputation - (accrued > decayAmount ? accrued - decayAmount : 0)); // Approximation of old level
             if (currentLevel > oldLevel) {
                  emit LevelUp(user, userState.linkedNFTId, currentLevel);
             }
        }
    }

    /**
     * @dev Gets the effective reputation multiplier for a user, considering their linked NFT.
     * @param user The address of the user.
     * @return uint256 The multiplier in basis points (e.g., 10000 for 1x).
     */
    function getUserReputationMultiplier(address user) public view returns (uint256) {
        uint256 nftId = userStates[user].linkedNFTId;
        if (nftId == 0 || ownerOf(nftId) != user) {
             // No linked NFT or NFT is not currently owned by the user
             return 10000; // Default multiplier (1x)
        }
         // Get the current reputation level of the NFT based on *this user's* reputation
        uint256 currentReputation = getCurrentReputationPoints(user); // Calculate effective current rep
        uint256 level = _getNFTLevelForReputation(currentReputation);
        return _getNFTMultiplierForLevel(level);
    }

    /**
     * @dev Gets the reputation decay information for a user.
     * @param user The address of the user.
     * @return uint256 decayRate, uint256 inactivityThreshold, uint256 timeSinceLastUpdate, bool isCurrentlyDecaying
     */
    function getReputationDecayInfo(address user) public view returns (uint256 rate, uint256 threshold, uint256 timeSinceLastUpdate, bool isCurrentlyDecaying) {
        UserState storage userState = userStates[user];
        timeSinceLastUpdate = 0;
        if (userState.lastReputationUpdateTime != 0) {
            timeSinceLastUpdate = block.timestamp - userState.lastReputationUpdateTime;
        }

        isCurrentlyDecaying = userState.stakedAmount == 0 && userState.stakeStartTime == 0 && timeSinceLastUpdate > inactivityThresholdForDecay;

        return (reputationDecayRatePerSecond, inactivityThresholdForDecay, timeSinceLastUpdate, isCurrentlyDecaying);
    }


    // --- NFT Logic (ERC721) ---

    /**
     * @dev Mints a new unique Chronicle Forge NFT for the caller.
     * Each user can only mint one NFT linked to the system.
     */
    function mintChronicleForgeNFT() public whenNotPaused {
        require(userStates[msg.sender].linkedNFTId == 0, "User already has a linked NFT");

        _tokenIds.increment();
        uint256 newTokenId = _tokenIds.current();

        _safeMint(msg.sender, newTokenId);
        userStates[msg.sender].linkedNFTId = newTokenId;

        emit NFTMinted(msg.sender, newTokenId);
    }

    /**
     * @dev Allows the NFT owner to burn their linked NFT.
     * @param tokenId The ID of the NFT to burn.
     */
    function burnNFT(uint256 tokenId) public userHasNFT(msg.sender) {
        require(ownerOf(tokenId) == msg.sender, "Must own the NFT to burn it");
        require(userStates[msg.sender].linkedNFTId == tokenId, "NFT is not linked to this user in the system");

        // Sever the link in the user state
        userStates[msg.sender].linkedNFTId = 0;

        _burn(tokenId);
    }

    /**
     * @dev Gets the dynamic level of an NFT based on its current owner's reputation.
     * Returns 0 if NFT doesn't exist or owner has no state in this contract.
     * @param tokenId The ID of the NFT.
     * @return uint256 The calculated NFT level.
     */
    function getNFTLevel(uint256 tokenId) public view returns (uint256) {
        address currentOwner = ownerOf(tokenId); // Will revert if tokenId doesn't exist

        // Get current owner's reputation in THIS system
        uint256 currentReputation = getCurrentReputationPoints(currentOwner);
        return _getNFTLevelForReputation(currentReputation);
    }

    /**
     * @dev Gets the dynamic reputation multiplier of an NFT based on its current owner's reputation level.
     * Returns base multiplier if NFT doesn't exist or owner has no state.
     * @param tokenId The ID of the NFT.
     * @return uint256 The calculated multiplier in basis points.
     */
    function getNFTMultiplier(uint256 tokenId) public view returns (uint256) {
         address currentOwner = ownerOf(tokenId); // Will revert if tokenId doesn't exist

         // Get current owner's reputation in THIS system
         uint256 currentReputation = getCurrentReputationPoints(currentOwner);
         uint256 level = _getNFTLevelForReputation(currentReputation);
         return _getNFTMultiplierForLevel(level);
    }

    /**
     * @dev Gets both dynamic attributes (level and multiplier) for an NFT.
     * @param tokenId The ID of the NFT.
     * @return uint256 level, uint256 multiplier
     */
    function getNFTAttributes(uint256 tokenId) public view returns (uint256 level, uint256 multiplier) {
         address currentOwner = ownerOf(tokenId); // Will revert if tokenId doesn't exist

         // Get current owner's reputation in THIS system
         uint256 currentReputation = getCurrentReputationPoints(currentOwner);
         level = _getNFTLevelForReputation(currentReputation);
         multiplier = _getNFTMultiplierForLevel(level);
         return (level, multiplier);
    }

    /**
     * @dev Gets the token ID of the NFT linked to a user in this system.
     * @param user The address of the user.
     * @return uint256 The linked token ID, or 0 if none.
     */
    function getUserNFTId(address user) public view returns (uint256) {
        uint256 nftId = userStates[user].linkedNFTId;
        if (nftId != 0 && ownerOf(nftId) == user) {
            return nftId;
        }
        return 0; // Return 0 if no linked NFT or user doesn't own it anymore
    }

     /**
     * @dev Gets both dynamic attributes (level and multiplier) for the NFT linked to a user.
     * Returns 0, 10000 if user has no linked NFT.
     * @param user The address of the user.
     * @return uint256 level, uint256 multiplier
     */
    function getUserNFTAttributes(address user) public view returns (uint256 level, uint256 multiplier) {
        uint256 nftId = userStates[user].linkedNFTId;
        if (nftId != 0 && ownerOf(nftId) == user) {
            uint256 currentReputation = getCurrentReputationPoints(user);
            level = _getNFTLevelForReputation(currentReputation);
            multiplier = _getNFTMultiplierForLevel(level);
            return (level, multiplier);
        }
        return (0, 10000); // Default: level 0, 1x multiplier
    }

    /**
     * @dev Internal pure function to calculate the NFT level based on reputation points.
     * @param reputation The reputation points.
     * @return uint256 The calculated level.
     */
    function _getNFTLevelForReputation(uint256 reputation) internal view returns (uint256) {
        uint256 level = 0;
        for (uint256 i = 0; i < reputationLevelThresholds.length; i++) {
            if (reputation >= reputationLevelThresholds[i]) {
                level = i + 1;
            } else {
                break; // Thresholds are assumed to be sorted
            }
        }
        return level;
    }

    /**
     * @dev Internal pure function to calculate the NFT multiplier based on level.
     * @param level The NFT level.
     * @return uint256 The multiplier in basis points.
     */
    function _getNFTMultiplierForLevel(uint256 level) internal view returns (uint256) {
        // Multiplier increases linearly with level
        return nftBaseMultiplierBips + level.mul(nftLevelMultiplierBonusBips);
    }

    /**
     * @dev Returns the metadata URI for a token. Points to a dynamic service.
     * Override ERC721 URIStorage behavior if needed, or point to a service
     * that uses the on-chain attributes (level/multiplier) to generate JSON.
     * For this example, it's a placeholder.
     */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        // In a real app, this would typically point to an API endpoint like:
        // string(abi.encodePacked("https://your-api-domain.com/metadata/", Strings.toString(tokenId)));
        // The API would look up the token's current owner, get their reputation and level/multiplier from this contract,
        // and generate the ERC721 metadata JSON dynamically.
        return string(abi.encodePacked("ipfs://<placeholder_CID>/", Strings.toString(tokenId), ".json"));
    }


    // --- Challenge Logic ---

    /**
     * @dev Owner adds a new challenge that users can complete for reputation.
     * @param description Brief description of the challenge.
     * @param reputationReward The reputation points granted upon completion.
     */
    function addChallenge(string calldata description, uint256 reputationReward) public onlyOwner {
        _challengeIds.increment();
        uint256 newChallengeId = _challengeIds.current();
        challenges[newChallengeId] = Challenge(description, reputationReward, true);
        emit ChallengeAdded(newChallengeId, description, reputationReward);
    }

    /**
     * @dev Owner attests that a user has completed a specific challenge, granting reputation.
     * Prevents duplicate completion for the same user/challenge.
     * @param user The address of the user who completed the challenge.
     * @param challengeId The ID of the challenge completed.
     */
    function completeChallengeByOwner(address user, uint256 challengeId) public onlyOwner whenNotPaused {
        require(challenges[challengeId].exists, "Challenge does not exist");
        require(!challengeCompleted[challengeId][user], "Challenge already completed by user");

        // Update user state with bonus reputation
        _updateReputationAndState(user); // Finalize pending reputation first
        userStates[user].totalClaimedReputation += challenges[challengeId].reputationReward;
        userStates[user].lastReputationUpdateTime = block.timestamp; // Update time as reputation changed

        challengeCompleted[challengeId][user] = true;

        emit ChallengeCompleted(user, challengeId);
         // Emit ReputationClaimed as reputation was added
        emit ReputationClaimed(user, challenges[challengeId].reputationReward, userStates[user].totalClaimedReputation);
    }

     /**
     * @dev Gets the details of a challenge.
     * @param challengeId The ID of the challenge.
     * @return string description, uint256 reputationReward, bool exists
     */
    function getChallengeDetails(uint256 challengeId) public view returns (string memory description, uint256 reputationReward, bool exists) {
        Challenge storage challenge = challenges[challengeId];
        return (challenge.description, challenge.reputationReward, challenge.exists);
    }

     /**
     * @dev Checks if a user has completed a specific challenge.
     * @param user The address of the user.
     * @param challengeId The ID of the challenge.
     * @return bool True if completed, false otherwise.
     */
    function getChallengeCompletionStatus(address user, uint256 challengeId) public view returns (bool) {
         return challengeCompleted[challengeId][user];
    }

    // --- Configuration (Owner-only) ---

    /**
     * @dev Sets the reputation points thresholds for each NFT level.
     * Must be sorted in ascending order. Level N requires >= thresholds[N-1] points.
     * An empty array means only level 0 is possible.
     * @param _thresholds An array of reputation points.
     */
    function setReputationLevelThresholds(uint256[] calldata _thresholds) public onlyOwner {
        for (uint i = 0; i < _thresholds.length - 1; i++) {
            require(_thresholds[i] < _thresholds[i+1], "Thresholds must be in ascending order");
        }
        reputationLevelThresholds = _thresholds;
        emit ParametersUpdated();
    }

    /**
     * @dev Sets the base rate of reputation accrual per staked token per second.
     * @param ratePerTokenPerSecond New base rate.
     */
    function setBaseReputationAccrualRate(uint256 ratePerTokenPerSecond) public onlyOwner {
        baseReputationAccrualRatePerTokenPerSecond = ratePerTokenPerSecond;
        emit ParametersUpdated();
    }

    /**
     * @dev Sets the reputation decay parameters.
     * @param ratePerSecond The rate at which reputation decays per second of inactivity.
     * @param inactivityThreshold The duration (in seconds) of inactivity before decay begins.
     */
    function setReputationDecayParameters(uint256 ratePerSecond, uint256 inactivityThreshold) public onlyOwner {
        reputationDecayRatePerSecond = ratePerSecond;
        inactivityThresholdForDecay = inactivityThreshold;
        emit ParametersUpdated();
    }

    /**
     * @dev Sets the withdrawal fee rate in basis points (100 = 1%).
     * @param feeBips The new fee rate.
     */
    function setWithdrawalFeeRate(uint256 feeBips) public onlyOwner {
        require(feeBips <= 10000, "Fee rate cannot exceed 100%");
        withdrawalFeeBips = feeBips;
        emit ParametersUpdated();
    }

    /**
     * @dev Sets the base reputation multiplier provided by the NFT at level 0 (in basis points).
     * @param baseMultiplierBips The base multiplier (e.g., 10000 for 1x).
     */
    function setNFTBaseMultiplier(uint256 baseMultiplierBips) public onlyOwner {
        nftBaseMultiplierBips = baseMultiplierBips;
        emit ParametersUpdated();
    }

     /**
     * @dev Sets the bonus reputation multiplier per NFT level (in basis points).
     * @param bonusPerLevelBips The bonus per level (e.g., 1000 for +10% per level).
     */
    function setNFTLevelMultiplierBonus(uint256 bonusPerLevelBips) public onlyOwner {
        nftLevelMultiplierBonusBips = bonusPerLevelBips;
        emit ParametersUpdated();
    }

    /**
     * @dev Sets the treasury address where withdrawal fees are sent.
     * @param _treasuryAddress The new treasury address.
     */
    function setTreasuryAddress(address _treasuryAddress) public onlyOwner {
        require(_treasuryAddress != address(0), "Invalid treasury address");
        treasuryAddress = _treasuryAddress;
        emit ParametersUpdated();
    }


    // --- Treasury Logic ---

    /**
     * @dev Owner can withdraw accumulated withdrawal fees from the contract.
     * Transfers balance of stakeToken held by the contract (excluding user stakes) to treasury.
     * In this simple model, it assumes all extra balance is fees.
     * A more complex model might track fees separately.
     */
    function withdrawTreasury(uint256 amount) public onlyOwner {
        uint256 contractBalance = stakeToken.balanceOf(address(this));
        uint256 withdrawableBalance = contractBalance - totalSystemStaked; // Assume anything beyond total staked is fees/earned

        uint256 amountToWithdraw = amount > withdrawableBalance ? withdrawableBalance : amount;

        require(amountToWithdraw > 0, "No withdrawable funds");

        stakeToken.safeTransfer(treasuryAddress, amountToWithdraw);
    }

    // --- ERC721 Overrides (Optional but good practice for clarity/hooks) ---
    // We don't need complex overrides here as the NFT utility is checked dynamically
    // based on the *current owner's* state in the contract, not on NFT transfer logic itself.
    // The `ownerOf` call in getters handles the current ownership.

     function supportsInterface(bytes4 interfaceId) public view override(ERC721, Ownable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

}
```