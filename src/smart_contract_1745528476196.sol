Okay, here is a smart contract implementing a concept called "Chronicle Protocol". This protocol allows users to stake an ERC20 token to earn "Reputation" over time. Based on their accumulated Reputation, users can mint a special Soulbound-like ERC721 NFT called a "Chronicle". The Chronicle NFT's level and properties are dynamic and tied to the user's current Reputation. The NFT is initially non-transferable (soulbound) but can become transferable if the user meets certain high-tier reputation and staking duration milestones, adding a layer of achievement and potential future value. It includes features like early unstaking with a fee, dynamic reputation calculation, and administrative controls.

This combines elements of staking, dynamic NFTs, reputation systems, and conditional transferability in a non-standard way.

---

**Chronicle Protocol Smart Contract**

**Outline:**

1.  **Contract Definition:** Inherits ERC721 (for Chronicles), Ownable, Pausable.
2.  **Structs:**
    *   `StakeDetails`: Stores information about a user's stake.
3.  **State Variables:**
    *   `stakingToken`: Address of the ERC20 token accepted for staking.
    *   `stakeCounter`: Counter for unique stake IDs.
    *   `stakes`: Mapping from stake ID to `StakeDetails`.
    *   `userStakes`: Mapping from user address to an array of their active stake IDs.
    *   `chronicleCounter`: Counter for unique Chronicle NFT token IDs.
    *   `userChronicle`: Mapping from user address to their unique Chronicle NFT token ID (1 per user).
    *   `reputationThresholds`: Mapping from Chronicle Level (uint) to the required Reputation (uint).
    *   `reputationMultiplierPerSecond`: Constant multiplier for reputation calculation.
    *   `unstakeFeeRate`: Percentage fee on early unstaking (e.g., 100 = 1%).
    *   `protocolFees`: Mapping from token address to collected fees.
    *   `isChronicleTransferLocked`: Mapping from Chronicle NFT token ID to boolean indicating if it's locked.
    *   `chronicleUnlockReputationThreshold`: Reputation needed to *potentially* unlock transfer.
    *   `chronicleUnlockTotalStakedDuration`: Total cumulative duration needed across all stakes to *potentially* unlock transfer.
4.  **Events:**
    *   `Staked`: When a user stakes tokens.
    *   `Unstaked`: When a user unstakes tokens.
    *   `EarlyUnstakeFeePaid`: When a fee is paid for early unstaking.
    *   `ReputationUpdated`: When a user's calculated reputation changes.
    *   `ChronicleMinted`: When a Chronicle NFT is minted.
    *   `ChronicleLevelUpgraded`: When a Chronicle NFT's level increases.
    *   `ChronicleTransferUnlocked`: When a Chronicle NFT becomes transferable.
    *   `ProtocolFeesWithdrawn`: When admin withdraws fees.
5.  **Modifiers:**
    *   `whenNotPaused`: Standard Pausable modifier.
    *   `whenPaused`: Standard Pausable modifier.
6.  **Constructor:** Initializes contract owner, sets staking token, reputation thresholds, unlock conditions.
7.  **Staking Functions:**
    *   `stake(uint256 amount, uint256 durationInSeconds)`: Stakes ERC20 tokens for a specified duration.
    *   `unstake(uint256 stakeId)`: Allows user to unstake after duration ends. Calculates and potentially updates reputation.
    *   `exitStakeEarly(uint256 stakeId)`: Allows user to unstake before duration ends, paying a fee.
    *   `extendStakeDuration(uint256 stakeId, uint256 additionalDurationInSeconds)`: Extends the lock duration of an existing stake.
    *   `compoundStake(uint256 stakeId, uint256 additionalAmount)`: Adds more tokens to an existing active stake, adjusting its end time proportionally.
8.  **Reputation Functions:**
    *   `getUserReputation(address user)`: Dynamically calculates a user's current reputation based on active stakes (time * amount).
    *   `calculateReputationGain(uint256 stakeId)`: Calculates the reputation earned by a *completed* stake. (Note: The primary `getUserReputation` is based on *active* stakes for dynamic status).
    *   `syncReputationAndChronicle(address user)`: Triggers recalculation of reputation and potentially updates the user's Chronicle level if they have one.
9.  **Chronicle NFT Functions (Integrated ERC721 Logic):**
    *   `mintChronicle()`: Allows user to mint their unique Chronicle NFT if eligible (meets Level 1 reputation).
    *   `burnChronicle(uint256 tokenId)`: Allows owner to burn their Chronicle.
    *   `getChronicleLevel(uint256 tokenId)`: Gets the current dynamic level of a Chronicle based on the owner's reputation.
    *   `isChronicleTransferLocked(uint256 tokenId)`: Checks if a specific Chronicle NFT is currently transfer-locked.
    *   `checkChronicleUnlockConditions(uint256 tokenId)`: Internal helper to check if global unlock conditions are met for a token.
    *   `unlockChronicleTransfer(uint256 tokenId)`: Allows the owner to unlock transferability if conditions are met.
    *   `_beforeTokenTransfer(...)`: Overridden ERC721 hook to enforce transfer lock.
10. **Admin Functions (Only Owner):**
    *   `setStakingToken(address _stakingToken)`: Sets the accepted staking token.
    *   `setReputationThreshold(uint256 level, uint256 requiredReputation)`: Sets reputation needed for a specific Chronicle level.
    *   `setChronicleUnlockConditions(uint256 reputationThreshold, uint256 totalStakedDuration)`: Sets global conditions for unlocking Chronicle transfer.
    *   `setUnstakeFeeRate(uint256 rate)`: Sets the early unstake fee rate.
    *   `withdrawProtocolFees(address tokenAddress, uint256 amount)`: Withdraws collected protocol fees.
    *   `pauseProtocol()`: Pauses staking and minting.
    *   `unpauseProtocol()`: Unpauses staking and minting.
    *   `adminBurnChronicle(uint256 tokenId)`: Admin can burn any Chronicle NFT.
11. **Query Functions:**
    *   `getUserStakes(address user)`: Gets the list of active stake IDs for a user.
    *   `getStakeDetails(uint256 stakeId)`: Gets details of a specific stake.
    *   `getReputationThreshold(uint256 level)`: Gets the reputation needed for a level.
    *   `getUserChronicleId(address user)`: Gets the Chronicle token ID for a user (or 0 if none).
    *   `canMintChronicle(address user)`: Checks if a user is eligible to mint a Chronicle.
    *   `getProtocolFees(address tokenAddress)`: Gets the total fees collected for a token.
    *   `getTokenURI(uint256 tokenId)`: Overridden ERC721 function for metadata.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol"; // Needed for safeTransferFrom
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

/**
 * @title Chronicle Protocol
 * @dev A staking protocol issuing dynamic, soulbound-like NFTs based on reputation.
 * Users stake ERC20 to earn reputation over time. Reputation unlocks levels
 * for a unique Chronicle NFT (ERC721) which is initially non-transferable,
 * becoming unlocked under specific high-tier conditions.
 */
contract ChronicleProtocol is ERC721, Ownable, Pausable {
    using Counters for Counters.Counter;
    using SafeMath for uint256;
    using Strings for uint256;

    // --- Structs ---

    /**
     * @dev Stores details for each staking position.
     */
    struct StakeDetails {
        address owner;
        uint256 amount;
        uint256 startTime;
        uint256 endTime;
        uint256 initialDuration; // Store original duration for unlock calculation
        bool isActive;
    }

    // --- State Variables ---

    IERC20 public stakingToken; // The ERC20 token accepted for staking

    Counters.Counter private _stakeIds; // Counter for generating unique stake IDs
    mapping(uint256 => StakeDetails) public stakes; // Mapping from stake ID to details
    mapping(address => uint256[]) private _userActiveStakes; // Mapping from user to their active stake IDs

    Counters.Counter private _chronicleIds; // Counter for generating unique Chronicle NFT IDs
    mapping(address => uint256) public userChronicle; // Mapping from user to their Chronicle NFT ID (0 if none)

    mapping(uint256 => uint256) public reputationThresholds; // Mapping from Chronicle Level => Required Reputation
    uint256 public constant REPUTATION_MULTIPLIER_PER_SECOND_PER_TOKEN = 1e12; // Adjust sensitivity: amount * time * multiplier
    // e.g., 1 token staked for 1 sec gives 1e12 reputation

    uint256 public unstakeFeeRate; // Percentage points (e.g., 100 = 1%) for early exit fee
    mapping(address => uint256) public protocolFees; // Mapping from token address => collected fees

    mapping(uint256 => bool) private _isChronicleTransferLocked; // True if NFT transfer is locked
    uint256 public chronicleUnlockReputationThreshold; // Reputation needed to potentially unlock transfer
    uint256 public chronicleUnlockTotalStakedDuration; // Total cumulative duration needed across all stakes to potentially unlock transfer (in seconds)

    // --- Events ---

    event Staked(address indexed user, uint256 stakeId, uint256 amount, uint256 durationInSeconds, uint256 startTime, uint256 endTime);
    event Unstaked(address indexed user, uint256 stakeId, uint256 amount, uint256 endTime, uint256 actualUnstakeTime);
    event EarlyUnstakeFeePaid(address indexed user, uint256 stakeId, uint256 feeAmount, uint256 remainingAmount);
    event ReputationCalculated(address indexed user, uint256 reputation);
    event ChronicleMinted(address indexed user, uint256 tokenId);
    event ChronicleLevelUpgraded(uint256 indexed tokenId, uint256 oldLevel, uint256 newLevel);
    event ChronicleTransferUnlocked(uint256 indexed tokenId);
    event ProtocolFeesWithdrawn(address indexed tokenAddress, uint256 amount);
    event ChronicleBurned(uint256 indexed tokenId);

    // --- Modifiers ---

    modifier onlyChronicleOwner(uint256 tokenId) {
        require(_exists(tokenId), "Chronicle: token doesn't exist");
        require(ownerOf(tokenId) == msg.sender, "Chronicle: not token owner");
        _;
    }

    // --- Constructor ---

    constructor(address _stakingToken, string memory name, string memory symbol)
        ERC721(name, symbol)
        Ownable(msg.sender) // Initialize Ownable with deployer as owner
    {
        require(_stakingToken != address(0), "Constructor: Staking token address cannot be zero");
        stakingToken = IERC20(_stakingToken);

        // Set some initial reasonable thresholds (can be adjusted by owner)
        reputationThresholds[1] = 1e18; // Example: Level 1 needs 1e18 reputation
        reputationThresholds[2] = 5e18; // Example: Level 2 needs 5e18 reputation
        reputationThresholds[3] = 1e19; // Example: Level 3 needs 1e19 reputation
        reputationThresholds[4] = 2e19;
        reputationThresholds[5] = 5e19;

        // Set initial unlock conditions (can be adjusted by owner)
        chronicleUnlockReputationThreshold = 5e19; // Example: Need Level 5 reputation
        chronicleUnlockTotalStakedDuration = 365 * 24 * 60 * 60; // Example: Need cumulative 1 year staked duration
    }

    // --- Staking Functions ---

    /**
     * @dev Stakes ERC20 tokens for a specified duration to earn reputation.
     * Requires user to approve this contract to spend `amount` tokens.
     * @param amount The amount of staking tokens to stake.
     * @param durationInSeconds The duration in seconds the tokens will be locked. Must be > 0.
     */
    function stake(uint256 amount, uint256 durationInSeconds) external whenNotPaused {
        require(amount > 0, "Stake: Amount must be greater than 0");
        require(durationInSeconds > 0, "Stake: Duration must be greater than 0");

        // Transfer tokens from the user to the contract
        require(stakingToken.transferFrom(msg.sender, address(this), amount), "Stake: Token transfer failed");

        _stakeIds.increment();
        uint256 newStakeId = _stakeIds.current();
        uint256 currentTime = block.timestamp;
        uint256 endTime = currentTime.add(durationInSeconds);

        stakes[newStakeId] = StakeDetails({
            owner: msg.sender,
            amount: amount,
            startTime: currentTime,
            endTime: endTime,
            initialDuration: durationInSeconds, // Store original duration
            isActive: true
        });

        _userActiveStakes[msg.sender].push(newStakeId);

        emit Staked(msg.sender, newStakeId, amount, durationInSeconds, currentTime, endTime);
    }

    /**
     * @dev Allows a user to unstake their tokens after the staking duration has ended.
     * The stake becomes inactive, and tokens are transferred back.
     * @param stakeId The ID of the stake to unstake.
     */
    function unstake(uint256 stakeId) external whenNotPaused {
        StakeDetails storage stake = stakes[stakeId];
        require(stake.owner == msg.sender, "Unstake: Not your stake");
        require(stake.isActive, "Unstake: Stake is not active");
        require(block.timestamp >= stake.endTime, "Unstake: Staking period not over yet. Use exitStakeEarly.");

        stake.isActive = false; // Mark stake as inactive

        // Remove stakeId from user's active stakes array (can be optimized)
        uint256[] storage activeStakes = _userActiveStakes[msg.sender];
        for (uint i = 0; i < activeStakes.length; i++) {
            if (activeStakes[i] == stakeId) {
                // Swap with last element and pop
                activeStakes[i] = activeStakes[activeStakes.length - 1];
                activeStakes.pop();
                break;
            }
        }

        // Transfer tokens back to the user
        require(stakingToken.transfer(msg.sender, stake.amount), "Unstake: Token transfer back failed");

        emit Unstaked(msg.sender, stakeId, stake.amount, stake.endTime, block.timestamp);

        // Automatically check/sync reputation and chronicle after unstaking
        syncReputationAndChronicle(msg.sender);
    }

    /**
     * @dev Allows a user to exit their stake before the duration ends, paying a fee.
     * The fee is a percentage of the staked amount and goes to the protocol.
     * @param stakeId The ID of the stake to exit early.
     */
    function exitStakeEarly(uint256 stakeId) external whenNotPaused {
        StakeDetails storage stake = stakes[stakeId];
        require(stake.owner == msg.sender, "ExitEarly: Not your stake");
        require(stake.isActive, "ExitEarly: Stake is not active");
        require(block.timestamp < stake.endTime, "ExitEarly: Staking period already over. Use unstake.");

        stake.isActive = false; // Mark stake as inactive

         // Remove stakeId from user's active stakes array (can be optimized)
        uint256[] storage activeStakes = _userActiveStakes[msg.sender];
        for (uint i = 0; i < activeStakes.length; i++) {
            if (activeStakes[i] == stakeId) {
                // Swap with last element and pop
                activeStakes[i] = activeStakes[activeStakes.length - 1];
                activeStakes.pop();
                break;
            }
        }

        uint256 feeAmount = stake.amount.mul(unstakeFeeRate).div(10000); // unstakeFeeRate is in basis points (100 = 1%)
        uint256 remainingAmount = stake.amount.sub(feeAmount);

        // Collect fee
        protocolFees[address(stakingToken)] = protocolFees[address(stakingToken)].add(feeAmount);
        emit EarlyUnstakeFeePaid(msg.sender, stakeId, feeAmount, remainingAmount);

        // Transfer remaining tokens back
        require(stakingToken.transfer(msg.sender, remainingAmount), "ExitEarly: Token transfer back failed");

        emit Unstaked(msg.sender, stakeId, remainingAmount, stake.endTime, block.timestamp);

        // Automatically check/sync reputation and chronicle after exiting stake
        syncReputationAndChronicle(msg.sender);
    }

     /**
     * @dev Extends the staking duration for an active stake.
     * Note: This does not change the amount, only the end time.
     * @param stakeId The ID of the stake to extend.
     * @param additionalDurationInSeconds The additional duration to add to the end time.
     */
    function extendStakeDuration(uint256 stakeId, uint256 additionalDurationInSeconds) external whenNotPaused {
        StakeDetails storage stake = stakes[stakeId];
        require(stake.owner == msg.sender, "ExtendDuration: Not your stake");
        require(stake.isActive, "ExtendDuration: Stake is not active");
        require(additionalDurationInSeconds > 0, "ExtendDuration: Additional duration must be greater than 0");

        stake.endTime = stake.endTime.add(additionalDurationInSeconds);
        // Decide if initialDuration should be updated here. If unlock condition uses *initial* lock, don't update.
        // If unlock condition uses *total* time locked eventually, maybe update? Let's use a separate track for total time locked.
        // For now, initialDuration remains the original lock time. Total duration needs calculation from history.

        emit Staked(msg.sender, stakeId, stake.amount, additionalDurationInSeconds, block.timestamp, stake.endTime); // Re-using event to indicate state change
    }

     /**
     * @dev Adds more tokens to an existing active stake, effectively compounding the stake.
     * The end time is recalculated proportionally to the new total amount and original duration.
     * Requires user to approve this contract to spend `additionalAmount` tokens.
     * @param stakeId The ID of the stake to compound.
     * @param additionalAmount The additional amount of staking tokens to add.
     */
    function compoundStake(uint256 stakeId, uint256 additionalAmount) external whenNotPaused {
        StakeDetails storage stake = stakes[stakeId];
        require(stake.owner == msg.sender, "Compound: Not your stake");
        require(stake.isActive, "Compound: Stake is not active");
        require(additionalAmount > 0, "Compound: Additional amount must be greater than 0");

        // Transfer tokens from the user to the contract
        require(stakingToken.transferFrom(msg.sender, address(this), additionalAmount), "Compound: Token transfer failed");

        uint256 currentTotalAmount = stake.amount;
        uint256 newTotalAmount = currentTotalAmount.add(additionalAmount);
        uint256 timeRemaining = stake.endTime.sub(block.timestamp);
        uint256 timeElapsed = block.timestamp.sub(stake.startTime);
        uint256 originalDuration = stake.initialDuration;

        // Recalculate the new end time based on the weighted average of time already passed and new capital
        // This is a complex decision. A simple approach: just add the amount, keep the *remaining* time.
        // Or: Calculate equivalent duration for the *additional* amount at the original rate.
        // Let's use a simpler rule: Add amount, keep the END TIME. This means the "rate" of reputation earning increases.
        // If we kept the original "rate", the duration would extend significantly.
        // Decision: Keep the end time as is. Adding more tokens increases the 'amount' factor in reputation calculation going forward.
        // This incentivizes adding to long-term stakes.

        // Update stake details
        stake.amount = newTotalAmount;

        emit Staked(msg.sender, stakeId, additionalAmount, timeRemaining, block.timestamp, stake.endTime); // Re-using event
    }


    // --- Reputation Functions ---

    /**
     * @dev Dynamically calculates a user's current reputation based on their active stakes.
     * Reputation = Sum (amount * time_elapsed_in_stake * REPUTATION_MULTIPLIER) for all active stakes.
     * This value is calculated on-the-fly and is not stored directly.
     * @param user The address of the user.
     * @return The calculated reputation for the user.
     */
    function getUserReputation(address user) public view returns (uint256) {
        uint256 totalReputation = 0;
        uint256 currentTime = block.timestamp;

        uint256[] memory activeStakes = _userActiveStakes[user];
        for (uint i = 0; i < activeStakes.length; i++) {
            uint256 stakeId = activeStakes[i];
            StakeDetails storage stake = stakes[stakeId];

            // Only consider active stakes that haven't ended yet (though _userActiveStakes should only have these)
            if (stake.isActive && currentTime < stake.endTime) {
                uint256 timeElapsed = currentTime.sub(stake.startTime);
                 // Reputation earned up to now from this stake
                totalReputation = totalReputation.add(
                    stake.amount.mul(timeElapsed).mul(REPUTATION_MULTIPLIER_PER_SECOND_PER_TOKEN)
                );
            }
        }
        // Note: Reputation from *completed* stakes is not included in this dynamic calculation.
        // This model rewards current, active commitment. An alternative could store cumulative reputation.
        // Sticking with dynamic for the "trendy/advanced" aspect tied to real-time commitment.

        emit ReputationCalculated(user, totalReputation); // Note: Event in view function is only logged off-chain during simulation/trace
        return totalReputation;
    }

    /**
     * @dev Calculates the reputation earned by a *single completed* stake.
     * Used potentially for historical data or if we later add cumulative reputation.
     * Currently, getUserReputation focuses on *active* stakes.
     * @param stakeId The ID of the completed stake.
     * @return The total reputation earned from that stake's full duration.
     */
    function calculateReputationGain(uint256 stakeId) public view returns (uint256) {
         StakeDetails storage stake = stakes[stakeId];
         // Calculate reputation earned over the *actual* duration it was staked until end time
         uint256 actualDuration = stake.endTime.sub(stake.startTime); // Or min(endTime, actualUnstakeTime) if we track that
         return stake.amount.mul(actualDuration).mul(REPUTATION_MULTIPLIER_PER_SECOND_PER_TOKEN);
    }

     /**
     * @dev Forces a recalculation of the user's reputation and checks/updates their Chronicle level.
     * Can be called by the user or potentially off-chain keepers.
     * @param user The address of the user to sync.
     */
    function syncReputationAndChronicle(address user) public {
        uint256 currentReputation = getUserReputation(user);

        uint256 tokenId = userChronicle[user];
        if (tokenId != 0) {
            // User has a Chronicle, check for level upgrade
            uint256 currentLevel = getChronicleLevel(tokenId);
            uint256 newLevel = currentLevel;

            // Find the highest level threshold met
            for (uint256 level = currentLevel + 1; level <= 10; level++) { // Check up to a reasonable max level (e.g., 10)
                if (reputationThresholds[level] > 0 && currentReputation >= reputationThresholds[level]) {
                    newLevel = level;
                } else {
                    // Threshold not met for this level, and likely not for higher levels either (assuming thresholds are increasing)
                    break;
                }
            }

            if (newLevel > currentLevel) {
                 // Level upgraded - Note: Metadata is likely dynamic via `tokenURI` and reflects level
                 emit ChronicleLevelUpgraded(tokenId, currentLevel, newLevel);
            }

            // Check if unlock conditions are met
             if (_isChronicleTransferLocked[tokenId]) {
                if (checkChronicleUnlockConditions(tokenId)) {
                    // Conditions met, Chronicle can now be unlocked by the owner calling unlockChronicleTransfer
                    // We don't auto-unlock, the user must claim it.
                }
             }
        }
    }

    // --- Chronicle NFT Functions (Integrated ERC721 Logic) ---

    /**
     * @dev Allows a user to mint their unique Chronicle NFT if they meet the Level 1 reputation threshold
     * and do not already own a Chronicle.
     */
    function mintChronicle() external whenNotPaused {
        require(userChronicle[msg.sender] == 0, "Chronicle: User already has a Chronicle");

        uint256 requiredReputationForLevel1 = reputationThresholds[1];
        require(requiredReputationForLevel1 > 0, "Chronicle: Level 1 reputation threshold not set");

        uint256 userRep = getUserReputation(msg.sender);
        require(userRep >= requiredReputationForLevel1, "Chronicle: Not enough reputation to mint");

        _chronicleIds.increment();
        uint256 newItemId = _chronicleIds.current();

        _safeMint(msg.sender, newItemId);
        userChronicle[msg.sender] = newItemId;
        _isChronicleTransferLocked[newItemId] = true; // Initially locked

        emit ChronicleMinted(msg.sender, newItemId);

        // Automatically sync level after minting
        syncReputationAndChronicle(msg.sender);
    }

    /**
     * @dev Allows the owner of a Chronicle NFT to burn it.
     * @param tokenId The ID of the Chronicle NFT to burn.
     */
    function burnChronicle(uint256 tokenId) external onlyChronicleOwner(tokenId) {
        require(_exists(tokenId), "Chronicle: token doesn't exist");

        address tokenOwner = ownerOf(tokenId);
        require(tokenOwner == msg.sender, "Chronicle: Not token owner");

        // Clear mappings before burning
        userChronicle[tokenOwner] = 0;
        delete _isChronicleTransferLocked[tokenId]; // Remove lock status

        _burn(tokenId);
        emit ChronicleBurned(tokenId);
    }

     /**
     * @dev Gets the current dynamic level of a Chronicle NFT based on its owner's reputation.
     * The level is determined by the highest reputation threshold met by the owner's current dynamic reputation.
     * @param tokenId The ID of the Chronicle NFT.
     * @return The level of the Chronicle (0 if no levels met, up to max configured).
     */
    function getChronicleLevel(uint256 tokenId) public view returns (uint256) {
        require(_exists(tokenId), "Chronicle: token doesn't exist");
        address tokenOwner = ownerOf(tokenId);
        uint256 userReputation = getUserReputation(tokenOwner);

        uint256 currentLevel = 0;
         // Iterate through thresholds to find the highest level met
        for (uint256 level = 1; level <= 10; level++) { // Check up to a reasonable max level (e.g., 10)
            if (reputationThresholds[level] > 0 && userReputation >= reputationThresholds[level]) {
                currentLevel = level;
            } else if (reputationThresholds[level] == 0 && level > 1){
                // Stop if thresholds are not set consecutively (optional, assumes 1,2,3... are set)
                 // Or just continue checking if thresholds might be sparse
            } else if (reputationThresholds[level] > 0 && userReputation < reputationThresholds[level]) {
                // Assuming thresholds are increasing, can stop early
                 if(currentLevel > 0) break; // If already met level 1 or higher, stop. If not, keep checking lower levels (unlikely needed with current logic)
            }
        }
        return currentLevel;
    }

     /**
     * @dev Checks if a specific Chronicle NFT is currently transfer-locked.
     * @param tokenId The ID of the Chronicle NFT.
     * @return True if locked, false otherwise.
     */
    function isChronicleTransferLocked(uint256 tokenId) public view returns (bool) {
        return _isChronicleTransferLocked[tokenId];
    }

     /**
     * @dev Internal helper to check if the global conditions for unlocking Chronicle transfer are met for a token's owner.
     * Conditions: Owner must have specific reputation AND specific cumulative staked duration.
     * @param tokenId The ID of the Chronicle NFT.
     * @return True if conditions met, false otherwise.
     */
    function checkChronicleUnlockConditions(uint256 tokenId) internal view returns (bool) {
        require(_exists(tokenId), "Chronicle: token doesn't exist");
        address tokenOwner = ownerOf(tokenId);

        // Condition 1: Reputation Threshold
        uint256 userReputation = getUserReputation(tokenOwner);
        if (userReputation < chronicleUnlockReputationThreshold) {
            return false;
        }

        // Condition 2: Cumulative Staked Duration across *all* past and active stakes
        uint256 totalStakedDurationSeconds = 0;
         // Need to iterate through ALL stakes ever created by the user to sum durations
         // This is inefficient if a user has many stakes. A better design would track cumulative duration.
         // For this example, we'll iterate. In production, store cumulative duration.
        for (uint256 i = 1; i <= _stakeIds.current(); i++) {
             StakeDetails storage stake = stakes[i];
             if (stake.owner == tokenOwner) {
                 if (stake.isActive) {
                     // For active stakes, add duration passed so far
                      totalStakedDurationSeconds = totalStakedDurationSeconds.add(block.timestamp.sub(stake.startTime));
                 } else {
                     // For inactive (completed or early exit) stakes, add the duration they were actually staked
                     // Need to track actual unstake time or use endTime if completed normally
                     // Let's simplify and use initialDuration if completed, or time elapsed if exited early (less accurate)
                     // More accurately, track start and end/exit time for *every* stake.
                     // For this example, let's use the initialDuration for completed stakes.
                     // This is a simplification. Realistically, track start and end timestamps for EVERY state change.
                     if (block.timestamp >= stake.endTime) { // Assume completed normally
                         totalStakedDurationSeconds = totalStakedDurationSeconds.add(stake.initialDuration);
                     } else { // Assume exited early - calculate time elapsed
                         totalStakedDurationSeconds = totalStakedDurationSeconds.add(stake.endTime.sub(stake.startTime)); // Use end-start time as a proxy for total potential duration contributing
                     }
                 }
             }
         }


        if (totalStakedDurationSeconds < chronicleUnlockTotalStakedDuration) {
            return false;
        }

        // Both conditions met
        return true;
    }

     /**
     * @dev Allows the owner of a Chronicle NFT to unlock its transferability if the global conditions are met.
     * @param tokenId The ID of the Chronicle NFT.
     */
    function unlockChronicleTransfer(uint256 tokenId) external onlyChronicleOwner(tokenId) {
        require(_isChronicleTransferLocked[tokenId], "Chronicle: token is not locked");
        require(checkChronicleUnlockConditions(tokenId), "Chronicle: Unlock conditions not met yet");

        _isChronicleTransferLocked[tokenId] = false;
        emit ChronicleTransferUnlocked(tokenId);
    }

    /**
     * @dev ERC721 hook. Prevents transfer if the Chronicle is locked.
     */
    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize)
        internal
        override(ERC721)
    {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);

        // Prevent transfer if locked, unless it's a burn (transfer to address(0))
        if (from != address(0) && to != address(0)) { // Not a mint or a burn
            if (_isChronicleTransferLocked[tokenId]) {
                revert("Chronicle: Token transfer is locked");
            }
        }

        // When transferring *to* a user, update their userChronicle mapping
        if (to != address(0)) {
             // Check if the recipient already has a chronicle - should not happen via standard transfer if 1 per user
             require(userChronicle[to] == 0 || userChronicle[to] == tokenId, "Chronicle: Recipient already has a Chronicle");
             userChronicle[to] = tokenId;
        }

        // When transferring *from* a user, clear their userChronicle mapping
        if (from != address(0)) {
             userChronicle[from] = 0; // The user no longer owns this Chronicle
        }
    }

    // --- Admin Functions (Only Owner) ---

    /**
     * @dev Sets the address of the staking token accepted by the protocol.
     * Can only be called once unless the current token is address(0).
     * @param _stakingToken The address of the ERC20 token.
     */
    function setStakingToken(address _stakingToken) external onlyOwner {
        require(_stakingToken != address(0), "Admin: Staking token address cannot be zero");
        // Optionally add a check if it's already set to prevent changing after deployment
        // require(address(stakingToken) == address(0), "Admin: Staking token already set");
        stakingToken = IERC20(_stakingToken);
    }

    /**
     * @dev Sets the minimum reputation required for a specific Chronicle level.
     * @param level The Chronicle level (e.g., 1, 2, 3).
     * @param requiredReputation The minimum reputation needed.
     */
    function setReputationThreshold(uint256 level, uint256 requiredReputation) external onlyOwner {
        require(level > 0, "Admin: Level must be greater than 0");
        reputationThresholds[level] = requiredReputation;
    }

     /**
     * @dev Sets the global conditions required for a Chronicle NFT to be eligible for unlocking transferability.
     * @param reputationThreshold The minimum reputation required.
     * @param totalStakedDuration The minimum cumulative staked duration across all stakes (in seconds).
     */
    function setChronicleUnlockConditions(uint256 reputationThreshold, uint256 totalStakedDuration) external onlyOwner {
        chronicleUnlockReputationThreshold = reputationThreshold;
        chronicleUnlockTotalStakedDuration = totalStakedDuration;
    }

    /**
     * @dev Sets the percentage fee for early unstaking.
     * Rate is in basis points (e.g., 100 = 1%).
     * @param rate The fee rate in basis points (0-10000).
     */
    function setUnstakeFeeRate(uint256 rate) external onlyOwner {
        require(rate <= 10000, "Admin: Fee rate cannot exceed 100%");
        unstakeFeeRate = rate;
    }

    /**
     * @dev Allows the owner to withdraw collected protocol fees for a specific token.
     * @param tokenAddress The address of the token fees were collected in.
     * @param amount The amount to withdraw.
     */
    function withdrawProtocolFees(address tokenAddress, uint256 amount) external onlyOwner {
        require(amount > 0, "Admin: Amount must be greater than 0");
        require(protocolFees[tokenAddress] >= amount, "Admin: Not enough fees collected");

        protocolFees[tokenAddress] = protocolFees[tokenAddress].sub(amount);
        IERC20 token = IERC20(tokenAddress);
        require(token.transfer(msg.sender, amount), "Admin: Fee withdrawal failed");

        emit ProtocolFeesWithdrawn(tokenAddress, amount);
    }

    /**
     * @dev Pauses staking and minting functions.
     */
    function pauseProtocol() external onlyOwner whenNotPaused {
        _pause();
    }

    /**
     * @dev Unpauses staking and minting functions.
     */
    function unpauseProtocol() external onlyOwner whenPaused {
        _unpause();
    }

     /**
     * @dev Allows the owner to burn any Chronicle NFT (e.g., for moderation).
     * @param tokenId The ID of the Chronicle NFT to burn.
     */
    function adminBurnChronicle(uint256 tokenId) external onlyOwner {
        require(_exists(tokenId), "Chronicle: token doesn't exist");

        address tokenOwner = ownerOf(tokenId);

        // Clear mappings before burning
        userChronicle[tokenOwner] = 0;
        delete _isChronicleTransferLocked[tokenId];

        _burn(tokenId);
        emit ChronicleBurned(tokenId); // Re-use event
    }

    // --- Query Functions ---

     /**
     * @dev Gets the list of active stake IDs for a given user.
     * @param user The address of the user.
     * @return An array of active stake IDs.
     */
    function getUserStakes(address user) external view returns (uint256[] memory) {
        return _userActiveStakes[user];
    }

    /**
     * @dev Gets the details of a specific stake.
     * @param stakeId The ID of the stake.
     * @return A StakeDetails struct containing the stake information.
     */
    function getStakeDetails(uint256 stakeId) external view returns (StakeDetails memory) {
        return stakes[stakeId];
    }

     /**
     * @dev Gets the reputation threshold required for a specific Chronicle level.
     * @param level The Chronicle level.
     * @return The required reputation. Returns 0 if no threshold is set for the level.
     */
    function getReputationThreshold(uint256 level) external view returns (uint256) {
        return reputationThresholds[level];
    }

    /**
     * @dev Gets the Chronicle NFT token ID owned by a user.
     * @param user The address of the user.
     * @return The token ID, or 0 if the user does not own a Chronicle.
     */
    function getUserChronicleId(address user) external view returns (uint256) {
        return userChronicle[user];
    }

     /**
     * @dev Checks if a user is currently eligible to mint a Chronicle NFT.
     * Eligibility requires not already owning a Chronicle and meeting the Level 1 reputation threshold.
     * @param user The address of the user.
     * @return True if eligible to mint, false otherwise.
     */
    function canMintChronicle(address user) external view returns (bool) {
        uint256 requiredReputationForLevel1 = reputationThresholds[1];
        if (requiredReputationForLevel1 == 0) return false; // Cannot mint if threshold not set

        return userChronicle[user] == 0 && getUserReputation(user) >= requiredReputationForLevel1;
    }

     /**
     * @dev Gets the total amount of fees collected for a specific token.
     * @param tokenAddress The address of the token.
     * @return The total collected fees for the token.
     */
    function getProtocolFees(address tokenAddress) external view returns (uint256) {
        return protocolFees[tokenAddress];
    }

    /**
     * @dev Overridden ERC721 function to provide metadata URI for a token.
     * This could point to a metadata server that dynamically generates metadata
     * including the Chronicle's level based on getChronicleLevel.
     * @param tokenId The ID of the Chronicle NFT.
     * @return The URI pointing to the token's metadata.
     */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
         require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
         // Example: return a base URI + token ID + query parameter for level
         // In a real app, a server at base URI would read token state (level) and generate metadata JSON.
         // string memory base = "ipfs://YOUR_BASE_URI/"; // Replace with your metadata server/ipfs base URI
         // string memory level = getChronicleLevel(tokenId).toString();
         // return string(abi.encodePacked(base, tokenId.toString(), "?level=", level));

         // For this example, let's return a placeholder based on level
         uint256 level = getChronicleLevel(tokenId);
         string memory base = "ipfs://placeholder_uri/"; // Replace with your metadata server/ipfs base URI
         return string(abi.encodePacked(base, "chronicle_", level.toString(), ".json"));
    }

    // --- ERC721 Boilerplate Overrides (Mostly handled by inheritance and _beforeTokenTransfer) ---

    // The following functions are inherited from ERC721.
    // balanceOf, ownerOf, safeTransferFrom, transferFrom, approve, getApproved,
    // setApprovalForAll, isApprovedForAll, supportsInterface
    // Their behavior is modified by the _beforeTokenTransfer hook for the transfer lock.

    // Indicate support for ERC721 and ERC721Metadata interfaces
    function supportsInterface(bytes4 interfaceId) public view override(ERC721, IERC165) returns (bool) {
        return interfaceId == type(IERC721).interfaceId ||
               interfaceId == type(IERC721Metadata).interfaceId ||
               super.supportsInterface(interfaceId);
    }
}
```