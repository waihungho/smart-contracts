Okay, here is a Solidity smart contract implementing a system I'll call "DynRep Stake & Achieve".

It combines several concepts:
1.  **Custom Token:** A non-standard ERC-20-like token implementation.
2.  **Dynamic NFT:** An NFT (`AchievementNFT`) whose attributes update based on user activity (specifically, staking duration and amount).
3.  **Dynamic Staking Yield:** Staking yield is influenced by the user's `AchievementNFT` attributes.
4.  **Dynamic Unstake Fees:** Early unstaking incurs a fee, which is reduced based on the `AchievementNFT` attributes and stake duration.
5.  **Achievement System:** Users earn/upgrade their `AchievementNFT` by meeting staking thresholds.
6.  **Manual Implementation:** Avoids direct inheritance from standard libraries like OpenZeppelin (for ERC-20/ERC-721 core logic) to meet the "no duplication" constraint for *standard* open source components.

---

**Smart Contract: DynRepStakeAchieve**

**Concept:** A system combining staking with a dynamic, achievement-based NFT that influences staking rewards and penalties. Users stake a custom token (`DRT`) to earn yield. Achieving staking duration and amount milestones awards and upgrades a unique `AchievementNFT` per user. The level/attributes of this NFT dynamically affect the yield rate received and the early unstake fee applied.

**Outline:**

1.  **Errors:** Custom errors for clarity and gas efficiency.
2.  **Events:** Log key actions (token transfers, approvals, staking, unstaking, claims, NFT mint/update, parameter changes).
3.  **Structs:** Define data structures for Stake Info and NFT Attributes.
4.  **State Variables:**
    *   Token state (`_balances`, `_allowances`, `_totalSupply`, etc.)
    *   NFT state (`_ownersNFT`, `_balancesNFT`, `_tokenApprovalsNFT`, `_operatorApprovalsNFT`, `_nextTokenIdNFT`, NFT metadata)
    *   Staking state (`_stakes`, `_stakedAmounts`, `_lastRewardUpdateTime`, `_totalStaked`)
    *   Achievement state (`_userAchievementNFT`, achievement thresholds)
    *   Dynamic parameters (base yield, bonus multipliers, base fee, fee reduction multipliers, minimum stake duration/amount for achievement)
    *   Owner and Pausability state.
5.  **Modifiers:** `onlyOwner`, `whenNotPaused`, `whenPaused`.
6.  **Constructor:** Initializes tokens, owner, base parameters.
7.  **Token Functions (Custom ERC-20-like):** Basic transfer, approve, balance, supply, allowance.
8.  **NFT Functions (Custom ERC-721-like):** Basic ownership, balance, transfer, approval. Includes internal mint/transfer helpers.
9.  **Achievement/Reputation Logic:**
    *   Internal helpers to check/award/update NFTs based on stake progress.
    *   Public function for users to explicitly trigger attribute sync.
10. **Staking Functions:** Stake tokens, unstake tokens (with dynamic fee), claim rewards.
11. **View/Calculation Functions:** Calculate pending rewards, calculate dynamic unstake fee, get dynamic yield rate, get stake info, get NFT attributes, get user's NFT ID.
12. **Parameter Setting Functions:** Owner functions to adjust base yield, bonus multipliers, base fee, fee reductions, achievement thresholds.
13. **Utility/Admin Functions:** Pause/unpause staking, rescue lost tokens, renounce ownership.

**Function Summary (Approx. 28 Functions):**

1.  `constructor()`: Initializes the contract, mints initial DRT tokens, sets owner and initial parameters.
2.  `transfer(address to, uint256 amount)`: Sends DRT tokens from the caller to `to`.
3.  `transferFrom(address from, address to, uint256 amount)`: Sends DRT tokens from `from` to `to` using allowance.
4.  `approve(address spender, uint256 amount)`: Sets `spender`'s allowance over caller's DRT tokens.
5.  `balanceOf(address account)`: Returns the DRT balance of `account`.
6.  `totalSupply()`: Returns the total supply of DRT tokens.
7.  `allowance(address owner, address spender)`: Returns the allowance `spender` has over `owner`'s DRT tokens.
8.  `stake(uint256 amount)`: Stakes `amount` of DRT tokens from the caller. Records stake info and triggers achievement check/update.
9.  `unstake(uint256 amount)`: Unstakes `amount` of DRT tokens. Calculates and applies dynamic unstake fee, calculates and pays rewards, updates stake info, and triggers achievement check/update.
10. `claimRewards()`: Claims accrued staking rewards without unstaking principal. Updates stake info and triggers achievement check/update.
11. `calculatePendingRewards(address account)`: *View* function. Calculates pending DRT rewards for `account` based on their stake and NFT attributes.
12. `calculateDynamicUnstakeFee(address account, uint256 amountToUnstake)`: *View* function. Calculates the potential DRT fee for unstaking `amountToUnstake` for `account`, based on their stake duration and NFT attributes.
13. `getStakeInfo(address account)`: *View* function. Returns detailed information about `account`'s current stake.
14. `getDynamicYieldRate(address account)`: *View* function. Returns the effective annual yield rate percentage for `account` based on their `AchievementNFT`.
15. `getAchievementNFTAttributes(address account)`: *View* function. Returns the attributes (level, achieved duration/amount) of `account`'s `AchievementNFT`.
16. `getUserAchievementNFTId(address account)`: *View* function. Returns the token ID of the `AchievementNFT` owned by `account` (0 if none).
17. `syncAchievementAttributes()`: Allows a user to explicitly trigger an update of their `AchievementNFT` attributes based on their current staking progress.
18. `setBaseYieldRate(uint256 newRate)`: *Owner* function. Sets the base annual percentage yield for staking.
19. `setYieldBonusMultiplier(uint8 attributeLevel, uint256 bonusPercentage)`: *Owner* function. Sets the additional annual percentage yield bonus granted for a specific `AchievementNFT` attribute level.
20. `setBaseUnstakeFeePercentage(uint256 percentage)`: *Owner* function. Sets the base percentage fee for early unstaking.
21. `setUnstakeFeeReductionMultiplier(uint8 attributeLevel, uint256 reductionPercentage)`: *Owner* function. Sets the percentage point reduction in the early unstake fee for a specific `AchievementNFT` attribute level.
22. `setAchievementThresholds(uint256 minStakeAmount, uint256 minStakeDuration)`: *Owner* function. Sets the minimum stake amount and duration required to initially earn an `AchievementNFT`.
23. `setAchievementLevelThreshold(uint8 level, uint256 amountThreshold, uint256 durationThreshold)`: *Owner* function. Sets the staking amount and duration thresholds required to reach a specific `AchievementNFT` level.
24. `getTotalStakedSupply()`: *View* function. Returns the total amount of DRT tokens currently staked in the contract.
25. `pauseStaking()`: *Owner* function. Pauses staking, unstaking, and claiming rewards.
26. `unpauseStaking()`: *Owner* function. Unpauses staking operations.
27. `rescueERC20(address tokenAddress, uint256 amount)`: *Owner* function. Allows the owner to rescue any supported ERC20 tokens accidentally sent to the contract.
28. `renounceOwnership()`: *Owner* function. Relinquishes ownership of the contract.

**(Note: ERC-721 standard functions like `ownerOf`, `balanceOf`, `transferFrom`, `approve`, `getApproved`, `setApprovalForAll`, `isApprovedForAll` are also implemented manually to fulfill the "no open source duplication" requirement for core standards, adding to the function count. I've summarized the key user-facing/unique ones above but will include the others in the code for completeness as they are part of the NFT logic.)**

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title DynRepStakeAchieve
 * @author YourNameHere
 * @notice A smart contract implementing a dynamic staking and achievement system.
 * Users stake a custom token (DRT) to earn yield, influenced by a dynamically
 * updating Achievement NFT earned through staking milestones. Early unstake fees
 * are also dynamically reduced based on the NFT level and stake duration.
 */

// --- Custom Error Definitions ---
error InsufficientBalance(uint256 requested, uint256 available);
error InsufficientAllowance(uint256 requested, uint256 available);
error ZeroAddress();
error TransferFailed();
error ApprovalFailed();
error StakeAmountZero();
error UnstakeAmountZero();
error NotStaked();
error StakingPaused();
error NFTNotFound();
error InvalidNFTId();
error NotNFTOwner();
error NotApprovedOrOwner();
error CannotSelfApprove();
error AchievementThresholdsNotSet(uint8 level);
error TokenRescueFailed();


// --- Events ---
event Transfer(address indexed from, address indexed to, uint256 value);
event Approval(address indexed owner, address indexed spender, uint256 value);

event Staked(address indexed user, uint256 amount, uint256 totalStaked);
event Unstaked(address indexed user, uint256 amount, uint256 rewardsPaid, uint256 feePaid, uint256 remainingStake);
event RewardsClaimed(address indexed user, uint256 rewardsPaid, uint256 remainingStake);

event AchievementNFTMinted(address indexed user, uint256 indexed tokenId);
event AchievementNFTAttributesUpdated(uint256 indexed tokenId, uint8 newLevel, uint256 achievedDuration, uint256 achievedAmount);

event TransferNFT(address indexed from, address indexed to, uint256 indexed tokenId);
event ApprovalNFT(address indexed owner, address indexed approved, uint256 indexed tokenId);
event ApprovalForAllNFT(address indexed owner, address indexed operator, bool approved);

event BaseYieldRateUpdated(uint256 newRate);
event YieldBonusMultiplierUpdated(uint8 indexed level, uint256 bonusPercentage);
event BaseUnstakeFeePercentageUpdated(uint256 newPercentage);
event UnstakeFeeReductionMultiplierUpdated(uint8 indexed level, uint256 reductionPercentage);
event AchievementThresholdsUpdated(uint256 minStakeAmount, uint256 minStakeDuration);
event AchievementLevelThresholdUpdated(uint8 indexed level, uint256 amountThreshold, uint256 durationThreshold);

event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
event Paused(address account);
event Unpaused(address account);


// --- Data Structures ---

struct StakeInfo {
    uint256 amount;          // Total amount staked by the user
    uint64 startTime;        // Timestamp when the user first staked
    uint256 claimedRewards;  // Total rewards claimed by the user
    uint64 lastRewardCalcTime; // Last time rewards were calculated/claimed for this user
}

struct AchievementAttributes {
    uint8 level;
    uint64 stakeDurationAchieved; // Max duration (in seconds) ever reached while staking
    uint256 stakeAmountAchieved; // Max amount ever staked simultaneously
}

struct AchievementLevelThreshold {
    uint256 amountThreshold;
    uint64 durationThreshold; // In seconds
}


// --- Core Contract ---
contract DynRepStakeAchieve {

    // --- State Variables (Token) ---
    string public constant name = "Dynamic Reputation Token";
    string public constant symbol = "DRT";
    uint8 public constant decimals = 18;

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    uint256 private _totalSupply;


    // --- State Variables (NFT - AchievementNFT) ---
    string public constant nameNFT = "Achievement NFT";
    string public constant symbolNFT = "ACHV";

    mapping(uint256 => address) private _ownersNFT;
    mapping(address => uint256) private _balancesNFT;
    mapping(uint256 => address) private _tokenApprovalsNFT;
    mapping(address => mapping(address => bool)) private _operatorApprovalsNFT;
    mapping(uint256 => AchievementAttributes) private _nftAttributes; // tokenId => attributes
    mapping(address => uint256) private _userAchievementNFT; // user address => tokenId (assuming one per user)
    uint256 private _nextTokenIdNFT = 1; // Start token IDs from 1

    string private _baseTokenURI = ""; // Base URI for NFT metadata


    // --- State Variables (Staking) ---
    mapping(address => StakeInfo) private _stakes;
    uint256 private _totalStaked;


    // --- State Variables (Achievements & Dynamic Parameters) ---
    mapping(uint8 => AchievementLevelThreshold) private _achievementLevelThresholds;
    uint256 private _minStakeAmountForNFT; // Minimum amount required to get the first NFT
    uint64 private _minStakeDurationForNFT; // Minimum duration required to get the first NFT

    uint256 private _baseYieldRate = 0; // Annual Percentage Yield (APY) base rate in percentage points (e.g., 500 for 5%)
    mapping(uint8 => uint256) private _yieldBonusMultipliers; // Additional APY percentage points based on NFT level
    uint256 private _baseUnstakeFeePercentage = 1000; // Base early unstake fee percentage points (e.g., 1000 for 10%)
    mapping(uint8 => uint256) private _unstakeFeeReductionMultipliers; // Percentage point reduction in fee based on NFT level

    uint64 private constant SECONDS_PER_YEAR = 365 days; // Approximation


    // --- State Variables (Admin) ---
    address private _owner;
    bool private _paused = false;


    // --- Modifiers ---
    modifier onlyOwner() {
        if (msg.sender != _owner) revert OwnableUnauthorized(msg.sender);
        _;
    }

    modifier whenNotPaused() {
        if (_paused) revert StakingPaused();
        _;
    }

    modifier whenPaused() {
        if (!_paused) revert StakingPaused(); // Custom error for unpause when not paused?
        _;
    }

    // Custom OwnableUnauthorized error (mimicking OpenZeppelin)
    error OwnableUnauthorized(address account);


    // --- Constructor ---
    constructor(uint256 initialSupply) {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);

        // Mint initial supply to the owner
        _totalSupply = initialSupply;
        _balances[_owner] = initialSupply;
        emit Transfer(address(0), _owner, initialSupply);

        // Set some initial dummy achievement thresholds
        _achievementLevelThresholds[1] = AchievementLevelThreshold(100 ether, 30 days);
        _achievementLevelThresholds[2] = AchievementLevelThreshold(500 ether, 90 days);
        _achievementLevelThresholds[3] = AchievementLevelThreshold(1000 ether, 180 days);
        // Set minimums for first NFT
        _minStakeAmountForNFT = 1 ether;
        _minStakeDurationForNFT = 7 days;

        // Set some initial yield/fee parameters
        _baseYieldRate = 200; // 2% APY base
        _yieldBonusMultipliers[1] = 100; // +1% for Level 1 NFT (total 3%)
        _yieldBonusMultipliers[2] = 300; // +3% for Level 2 NFT (total 5%)
        _yieldBonusMultipliers[3] = 600; // +6% for Level 3 NFT (total 8%)

        _baseUnstakeFeePercentage = 1000; // 10% fee
        _unstakeFeeReductionMultipliers[1] = 200; // -2% fee reduction (total 8%)
        _unstakeFeeReductionMultipliers[2] = 500; // -5% fee reduction (total 5%)
        _unstakeFeeReductionMultipliers[3] = 800; // -8% fee reduction (total 2%)
    }


    // --- Token Functions (Custom ERC-20-like) ---

    function transfer(address to, uint256 amount) public returns (bool) {
        if (to == address(0)) revert ZeroAddress();
        uint256 senderBalance = _balances[msg.sender];
        if (senderBalance < amount) revert InsufficientBalance(amount, senderBalance);

        _balances[msg.sender] = senderBalance - amount;
        _balances[to] += amount;
        emit Transfer(msg.sender, to, amount);
        return true;
    }

    function transferFrom(address from, address to, uint256 amount) public returns (bool) {
        if (from == address(0) || to == address(0)) revert ZeroAddress();
        uint256 senderAllowance = _allowances[from][msg.sender];
        if (senderAllowance < amount) revert InsufficientAllowance(amount, senderAllowance);
        uint256 fromBalance = _balances[from];
        if (fromBalance < amount) revert InsufficientBalance(amount, fromBalance);

        unchecked { // Allowance can only decrease
            _allowances[from][msg.sender] = senderAllowance - amount;
        }
        _balances[from] = fromBalance - amount;
        _balances[to] += amount;
        emit Transfer(from, to, amount);
        return true;
    }

    function approve(address spender, uint256 amount) public returns (bool) {
        if (spender == address(0)) revert ZeroAddress();
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }

    // --- Internal Token Helpers (Used by staking/fees) ---

    function _transfer(address from, address to, uint256 amount) internal {
        if (from == address(0) || to == address(0)) revert ZeroAddress();
        uint256 senderBalance = _balances[from];
        if (senderBalance < amount) revert InsufficientBalance(amount, senderBalance);

        _balances[from] = senderBalance - amount;
        _balances[to] += amount;
        emit Transfer(from, to, amount);
    }


    // --- NFT Functions (Custom ERC-721-like) ---

    // ERC-721 Standard Views
    function balanceOfNFT(address owner) public view returns (uint256) {
        if (owner == address(0)) revert ZeroAddress();
        return _balancesNFT[owner];
    }

    function ownerOfNFT(uint256 tokenId) public view returns (address) {
        address owner = _ownersNFT[tokenId];
        if (owner == address(0)) revert InvalidNFTId(); // Or NotValidTokenId?
        return owner;
    }

    function getApprovedNFT(uint256 tokenId) public view returns (address) {
        if (!_existsNFT(tokenId)) revert InvalidNFTId();
        return _tokenApprovalsNFT[tokenId];
    }

    function isApprovedForAllNFT(address owner, address operator) public view returns (bool) {
        return _operatorApprovalsNFT[owner][operator];
    }

    // ERC-721 Standard Transactions
    function approveNFT(address to, uint256 tokenId) public {
        address owner = ownerOfNFT(tokenId); // Checks if tokenId exists
        if (msg.sender != owner && !isApprovedForAllNFT(owner, msg.sender)) {
            revert NotApprovedOrOwner();
        }
        if (to == owner) revert CannotSelfApprove();

        _tokenApprovalsNFT[tokenId] = to;
        emit ApprovalNFT(owner, to, tokenId);
    }

    function setApprovalForAllNFT(address operator, bool approved) public {
        if (operator == msg.sender) revert CannotSelfApprove();
        _operatorApprovalsNFT[msg.sender][operator] = approved;
        emit ApprovalForAllNFT(msg.sender, operator, approved);
    }

    function transferFromNFT(address from, address to, uint256 tokenId) public {
        _transferNFT(from, to, tokenId);
    }

    // --- Internal NFT Helpers ---

    function _existsNFT(uint256 tokenId) internal view returns (bool) {
        return _ownersNFT[tokenId] != address(0);
    }

    function _safeMintNFT(address to, uint256 tokenId) internal {
        if (to == address(0)) revert ZeroAddress();
        if (_existsNFT(tokenId)) revert InvalidNFTId(); // Should not happen with sequential ids

        _ownersNFT[tokenId] = to;
        _balancesNFT[to] += 1;
        // No Transfer event on mint according to ERC-721 spec, but useful for tracking
        // emit TransferNFT(address(0), to, tokenId);
        emit AchievementNFTMinted(to, tokenId);
    }

    function _transferNFT(address from, address to, uint256 tokenId) internal {
         if (_ownersNFT[tokenId] != from) revert NotNFTOwner(); // Check ownership
         if (to == address(0)) revert ZeroAddress();

         // Check approval
         if (msg.sender != from && !isApprovedForAllNFT(from, msg.sender) && _tokenApprovalsNFT[tokenId] != msg.sender) {
             revert NotApprovedOrOwner();
         }

         // Clear approval for the token
         _tokenApprovalsNFT[tokenId] = address(0);

         unchecked { // Balance can only decrease for 'from'
            _balancesNFT[from] -= 1;
         }
         _ownersNFT[tokenId] = to;
         _balancesNFT[to] += 1;

         emit TransferNFT(from, to, tokenId);
    }


    // --- Achievement/Reputation Logic ---

    function _checkAndAwardAchievement(address user) internal {
        // Check if the user has an NFT already
        if (_userAchievementNFT[user] == 0) {
            StakeInfo storage stake = _stakes[user];
            // Check if minimum thresholds are met for first NFT
            if (stake.amount >= _minStakeAmountForNFT && (block.timestamp - stake.startTime) >= _minStakeDurationForNFT) {
                uint256 newId = _nextTokenIdNFT++;
                _safeMintNFT(user, newId);
                _userAchievementNFT[user] = newId;
                // Initialize attributes
                 _nftAttributes[newId] = AchievementAttributes({
                    level: 0, // Start at level 0 before checking thresholds
                    stakeDurationAchieved: block.timestamp - stake.startTime,
                    stakeAmountAchieved: stake.amount
                });
                _updateAchievementAttributes(user); // Immediately check for level 1+
            }
        } else {
             // User already has an NFT, just update attributes
             _updateAchievementAttributes(user);
        }
    }

    function _updateAchievementAttributes(address user) internal {
        uint256 tokenId = _userAchievementNFT[user];
        if (tokenId == 0) return; // No NFT to update

        StakeInfo storage stake = _stakes[user];
        AchievementAttributes storage attributes = _nftAttributes[tokenId];

        uint64 currentDuration = block.timestamp - stake.startTime;
        uint256 currentAmount = stake.amount;

        bool updated = false;

        // Update achieved duration/amount if current is higher
        if (currentDuration > attributes.stakeDurationAchieved) {
            attributes.stakeDurationAchieved = currentDuration;
            updated = true;
        }
        if (currentAmount > attributes.stakeAmountAchieved) {
            attributes.stakeAmountAchieved = currentAmount;
            updated = true;
        }

        // Check for level upgrades based on *achieved* thresholds
        uint8 currentLevel = attributes.level;
        uint8 newLevel = currentLevel;

        // Iterate through levels (starting from current + 1) to find the highest achieved
        for (uint8 level = currentLevel + 1; level <= 255; ++level) { // Max level 255
            AchievementLevelThreshold memory threshold = _achievementLevelThresholds[level];
            if (threshold.amountThreshold == 0 && threshold.durationThreshold == 0) {
                 // No threshold set for this level, stop checking higher levels
                 break;
            }
            // To reach a new level, BOTH achieved duration and amount must meet the threshold for that level
            if (attributes.stakeAmountAchieved >= threshold.amountThreshold && attributes.stakeDurationAchieved >= threshold.durationThreshold) {
                 newLevel = level;
            } else {
                 // Threshold for this level not met, cannot reach this or higher levels
                 break;
            }
        }

        if (newLevel > currentLevel) {
            attributes.level = newLevel;
            updated = true;
        }

        if (updated) {
             emit AchievementNFTAttributesUpdated(tokenId, attributes.level, attributes.stakeDurationAchieved, attributes.stakeAmountAchieved);
        }
    }

    /**
     * @notice Allows a user to explicitly trigger an update of their Achievement NFT attributes.
     * Useful if attributes aren't auto-updated frequently enough or if the user
     * believes they have met a new milestone since the last stake/unstake/claim action.
     * Can only be called if the user has an Achievement NFT.
     */
    function syncAchievementAttributes() public {
        if (_userAchievementNFT[msg.sender] == 0) revert NFTNotFound();
        _updateAchievementAttributes(msg.sender);
    }

     /**
      * @notice Returns the attributes of a user's Achievement NFT.
      * @param account The address of the user.
      * @return attributes The AchievementAttributes struct for the user's NFT.
      */
     function getAchievementNFTAttributes(address account) public view returns (AchievementAttributes memory attributes) {
         uint256 tokenId = _userAchievementNFT[account];
         if (tokenId == 0) revert NFTNotFound();
         return _nftAttributes[tokenId];
     }

     /**
      * @notice Returns the token ID of a user's Achievement NFT.
      * @param account The address of the user.
      * @return tokenId The token ID, or 0 if the user has no Achievement NFT.
      */
     function getUserAchievementNFTId(address account) public view returns (uint256 tokenId) {
         return _userAchievementNFT[account];
     }


    // --- Staking Functions ---

    /**
     * @notice Stakes DRT tokens into the contract.
     * @param amount The amount of DRT to stake.
     */
    function stake(uint256 amount) public whenNotPaused {
        if (amount == 0) revert StakeAmountZero();
        if (_balances[msg.sender] < amount) revert InsufficientBalance(amount, _balances[msg.sender]);

        StakeInfo storage stake = _stakes[msg.sender];

        // Calculate and accrue rewards before adding new stake
        _calculateAndAccrueRewards(msg.sender);

        _transfer(msg.sender, address(this), amount);

        if (stake.amount == 0) {
            // First time staking for this user
            stake.startTime = uint64(block.timestamp);
        }
        stake.amount += amount;
        stake.lastRewardCalcTime = uint64(block.timestamp); // Reset calculation time

        _totalStaked += amount;

        _checkAndAwardAchievement(msg.sender); // Check/award/update NFT after stake

        emit Staked(msg.sender, amount, stake.amount);
    }

    /**
     * @notice Unstakes DRT tokens from the contract.
     * @param amount The amount of DRT to unstake.
     */
    function unstake(uint256 amount) public whenNotPaused {
        if (amount == 0) revert UnstakeAmountZero();
        StakeInfo storage stake = _stakes[msg.sender];
        if (stake.amount == 0) revert NotStaked();
        if (stake.amount < amount) revert InsufficientBalance(amount, stake.amount); // Should be stake.amount

        // Calculate and accrue rewards before unstaking
        _calculateAndAccrueRewards(msg.sender);

        uint256 rewardsToPay = _stakes[msg.sender].claimedRewards; // Accrued rewards are added to claimedRewards

        // Calculate dynamic early unstake fee
        uint256 feeAmount = _calculateDynamicUnstakeFee(msg.sender, amount);

        uint256 amountToReturn = amount - feeAmount;
        uint256 totalToSend = amountToReturn + rewardsToPay;

        _stakes[msg.sender].amount -= amount;
        _stakes[msg.sender].claimedRewards = 0; // Rewards are paid out

        _totalStaked -= amount; // Deduct full unstake amount from total staked

        _transfer(address(this), msg.sender, totalToSend); // Send back principal (minus fee) + rewards

        // Update stake start time if remaining stake > 0 (optional, depends on logic)
        // For simplicity, let's keep the original start time for remaining stake
        // If stake.amount becomes 0, the struct is essentially reset for future stakes

        _checkAndAwardAchievement(msg.sender); // Check/award/update NFT after unstake

        emit Unstaked(msg.sender, amount, rewardsToPay, feeAmount, stake.amount);
    }

    /**
     * @notice Claims pending staking rewards without unstaking principal.
     */
    function claimRewards() public whenNotPaused {
        StakeInfo storage stake = _stakes[msg.sender];
        if (stake.amount == 0) revert NotStaked();

        _calculateAndAccrueRewards(msg.sender);

        uint256 rewardsToPay = stake.claimedRewards;
        if (rewardsToPay == 0) return; // No rewards to claim

        stake.claimedRewards = 0; // Reset claimed rewards

        // Transfer rewards
        _transfer(address(this), msg.sender, rewardsToPay);

        _checkAndAwardAchievement(msg.sender); // Check/award/update NFT after claim

        emit RewardsClaimed(msg.sender, rewardsToPay, stake.amount);
    }


    // --- View/Calculation Functions ---

    /**
     * @notice Internal helper to calculate rewards since last calculation time and add to claimed.
     * Updates lastRewardCalcTime.
     * @param account The address of the staker.
     */
    function _calculateAndAccrueRewards(address account) internal {
        StakeInfo storage stake = _stakes[account];
        if (stake.amount == 0) return; // No stake, no rewards

        uint64 lastCalcTime = stake.lastRewardCalcTime;
        uint64 currentTime = uint64(block.timestamp);

        // Avoid calculating rewards for time already calculated
        if (currentTime <= lastCalcTime) return;

        uint256 timeElapsed = currentTime - lastCalcTime;
        if (timeElapsed == 0) return;

        uint256 currentStake = stake.amount;
        uint256 yieldRate = _getDynamicYieldRate(account); // Get APY in percentage points

        // Reward = stake * (yieldRate / 10000) * (timeElapsed / SECONDS_PER_YEAR)
        // Using fixed point arithmetic: (stake * yieldRate * timeElapsed) / (10000 * SECONDS_PER_YEAR)
        // To prevent overflow, rearrange: (stake * yieldRate / 10000) * (timeElapsed / SECONDS_PER_YEAR)
        // Or better: (stake * yieldRate * timeElapsed) / SECONDS_PER_YEAR / 10000

        // Need to be careful with division order and potential precision loss.
        // Let's multiply first, then divide, using 10**decimals for precision if needed.
        // DRT has 18 decimals. Yield rate is in percentage points (e.g., 500 = 5%).
        // Raw rate = yieldRate / 10000.
        // Daily rate = Raw rate / 365.
        // Reward per second = stake * (yieldRate / 10000) / SECONDS_PER_YEAR
        // Total reward = stake * (yieldRate / 10000) * (timeElapsed / SECONDS_PER_YEAR)
        // Let's scale yieldRate by 1e18 before calculation to handle precision
        // yieldRate_scaled = yieldRate * 1e18 (this gives percentage points scaled)
        // Annual reward = stake * (yieldRate_scaled / 1e18) / 10000
        // Reward per second = stake * (yieldRate_scaled / 1e18) / 10000 / SECONDS_PER_YEAR
        // Total reward = stake * (yieldRate_scaled / 1e18) / 10000 / SECONDS_PER_YEAR * timeElapsed

        // Simpler: Use a large multiplier to preserve precision during multiplication
        // reward = (stake * yieldRate * timeElapsed * 1e18) / (10000 * SECONDS_PER_YEAR) / 1e18
        // Let's use 1e18 as a fixed-point multiplier for yield rate
        uint256 reward = (currentStake * yieldRate * timeElapsed) / (SECONDS_PER_YEAR * 10000);

        stake.claimedRewards += reward;
        stake.lastRewardCalcTime = currentTime;
    }


    /**
     * @notice View function. Calculates the pending DRT rewards for an account.
     * Does not modify state.
     * @param account The address of the staker.
     * @return The amount of pending rewards.
     */
    function calculatePendingRewards(address account) public view returns (uint256) {
        StakeInfo storage stake = _stakes[account];
        if (stake.amount == 0) return 0;

        uint64 lastCalcTime = stake.lastRewardCalcTime;
        uint64 currentTime = uint64(block.timestamp);

        if (currentTime <= lastCalcTime) return stake.claimedRewards; // Return already accrued rewards

        uint256 timeElapsed = currentTime - lastCalcTime;
        if (timeElapsed == 0) return stake.claimedRewards;

        uint256 currentStake = stake.amount;
        uint256 yieldRate = _getDynamicYieldRate(account);

        uint256 calculatedReward = (currentStake * yieldRate * timeElapsed) / (SECONDS_PER_YEAR * 10000);

        return stake.claimedRewards + calculatedReward;
    }

    /**
     * @notice View function. Calculates the dynamic early unstake fee for a specific amount.
     * Fee is reduced based on stake duration and NFT level.
     * @param account The address of the staker.
     * @param amountToUnstake The amount the user intends to unstake.
     * @return The calculated fee amount in DRT.
     */
    function calculateDynamicUnstakeFee(address account, uint256 amountToUnstake) public view returns (uint256) {
        StakeInfo storage stake = _stakes[account];
        if (stake.amount == 0 || amountToUnstake == 0) return 0;
        if (amountToUnstake > stake.amount) amountToUnstake = stake.amount; // Cap to current stake

        // Minimum duration before fees start to reduce significantly
        // Let's use a fixed "no fee" duration or a scaled reduction.
        // Simple approach: Fee reduces linearly with duration, capped by NFT level.
        // Or, fee is base fee percentage MINUS reduction percentage from NFT level,
        // applied if duration is below a certain threshold (e.g., minStakeDurationForNFT or higher).

        // Let's make it: Fee is BaseFeePercentage - (ReductionForNFTLevel)
        // This percentage is applied IF the stake duration is less than the duration threshold for the user's CURRENT NFT Level.
        // If stake duration EXCEEDS the duration threshold for their current level, the fee is 0.
        // If they have no NFT or level 0, the max base fee applies if duration < minStakeDurationForNFT.

        uint64 currentDuration = uint64(block.timestamp) - stake.startTime;
        uint8 currentLevel = 0;
        if (_userAchievementNFT[account] != 0) {
            currentLevel = _nftAttributes[_userAchievementNFT[account]].level;
        }

        // Default to minimum threshold duration if level threshold isn't set or level 0
        uint64 durationThresholdForFeeReduction = _minStakeDurationForNFT;
        if (currentLevel > 0 && _achievementLevelThresholds[currentLevel].durationThreshold > 0) {
            durationThresholdForFeeReduction = _achievementLevelThresholds[currentLevel].durationThreshold;
        }

        // If duration is long enough, no fee
        if (currentDuration >= durationThresholdForFeeReduction) {
            return 0;
        }

        // Duration is NOT long enough, calculate fee
        uint256 effectiveFeePercentage = _baseUnstakeFeePercentage; // Start with base
        uint256 reduction = _unstakeFeeReductionMultipliers[currentLevel]; // Get reduction for level

        if (reduction > 0) {
             // Apply reduction, but ensure percentage doesn't go below 0 (or a minimum floor)
             effectiveFeePercentage = effectiveFeePercentage > reduction ? effectiveFeePercentage - reduction : 0;
             // Optional: set a minimum fee percentage floor (e.g., 1%)
             // uint256 minFeeFloor = 100; // 1%
             // if (effectiveFeePercentage < minFeeFloor) effectiveFeePercentage = minFeeFloor;
        }


        // Fee Amount = (amountToUnstake * effectiveFeePercentage) / 10000 (since percentage is in basis points)
        return (amountToUnstake * effectiveFeePercentage) / 10000;
    }

    /**
     * @notice View function. Returns the current effective annual yield rate percentage for a staker.
     * Influenced by the user's Achievement NFT attributes.
     * @param account The address of the staker.
     * @return The effective annual yield rate in percentage points (e.g., 500 = 5%).
     */
    function getDynamicYieldRate(address account) public view returns (uint256) {
        return _getDynamicYieldRate(account);
    }

    /**
     * @notice Internal helper to calculate dynamic yield rate.
     * @param account The address of the staker.
     * @return The effective annual yield rate in percentage points.
     */
    function _getDynamicYieldRate(address account) internal view returns (uint256) {
        uint256 rate = _baseYieldRate;
        if (_userAchievementNFT[account] != 0) {
            uint8 level = _nftAttributes[_userAchievementNFT[account]].level;
            rate += _yieldBonusMultipliers[level];
        }
        return rate;
    }

    /**
     * @notice View function. Returns the stake information for an account.
     * @param account The address of the staker.
     * @return The StakeInfo struct for the account.
     */
    function getStakeInfo(address account) public view returns (StakeInfo memory) {
        return _stakes[account];
    }

    /**
     * @notice View function. Returns the total amount of DRT tokens currently staked in the contract.
     * @return The total staked supply.
     */
    function getTotalStakedSupply() public view returns (uint256) {
        return _totalStaked;
    }


    // --- Parameter Setting Functions (Owner Only) ---

    /**
     * @notice Owner function. Sets the base annual percentage yield (APY) for staking.
     * @param newRate The new base APY in percentage points (e.g., 500 for 5%).
     */
    function setBaseYieldRate(uint256 newRate) public onlyOwner {
        _baseYieldRate = newRate;
        emit BaseYieldRateUpdated(newRate);
    }

    /**
     * @notice Owner function. Sets the additional APY bonus for a specific Achievement NFT attribute level.
     * @param attributeLevel The NFT attribute level.
     * @param bonusPercentage The additional APY percentage points granted for this level.
     */
    function setYieldBonusMultiplier(uint8 attributeLevel, uint256 bonusPercentage) public onlyOwner {
        _yieldBonusMultipliers[attributeLevel] = bonusPercentage;
        emit YieldBonusMultiplierUpdated(attributeLevel, bonusPercentage);
    }

    /**
     * @notice Owner function. Sets the base percentage fee for early unstaking.
     * @param percentage The base fee percentage points (e.g., 1000 for 10%).
     */
    function setBaseUnstakeFeePercentage(uint256 percentage) public onlyOwner {
        _baseUnstakeFeePercentage = percentage;
        emit BaseUnstakeFeePercentageUpdated(percentage);
    }

    /**
     * @notice Owner function. Sets the percentage point reduction in the early unstake fee for a specific NFT level.
     * @param attributeLevel The NFT attribute level.
     * @param reductionPercentage The fee reduction percentage points for this level.
     */
    function setUnstakeFeeReductionMultiplier(uint8 attributeLevel, uint256 reductionPercentage) public onlyOwner {
        _unstakeFeeReductionMultipliers[attributeLevel] = reductionPercentage;
        emit UnstakeFeeReductionMultiplierUpdated(attributeLevel, reductionPercentage);
    }

     /**
      * @notice Owner function. Sets the minimum stake amount and duration required to initially earn an Achievement NFT.
      * @param minStakeAmount The minimum amount in DRT (with 18 decimals).
      * @param minStakeDuration The minimum duration in seconds.
      */
     function setAchievementThresholds(uint256 minStakeAmount, uint64 minStakeDuration) public onlyOwner {
         _minStakeAmountForNFT = minStakeAmount;
         _minStakeDurationForNFT = minStakeDuration;
         emit AchievementThresholdsUpdated(minStakeAmount, minStakeDuration);
     }

    /**
     * @notice Owner function. Sets the staking amount and duration thresholds required to reach a specific Achievement NFT level.
     * @param level The NFT level (e.g., 1, 2, 3...). Level 0 is initial state.
     * @param amountThreshold The amount threshold for this level (with 18 decimals).
     * @param durationThreshold The duration threshold for this level (in seconds).
     */
    function setAchievementLevelThreshold(uint8 level, uint256 amountThreshold, uint64 durationThreshold) public onlyOwner {
        if (level == 0) revert InvalidNFTId(); // Level 0 is initial, no specific threshold to set
        _achievementLevelThresholds[level] = AchievementLevelThreshold(amountThreshold, durationThreshold);
        emit AchievementLevelThresholdUpdated(level, amountThreshold, durationThreshold);
    }

    /**
     * @notice Owner function. Sets the base URI for Achievement NFT metadata.
     * @param baseURI The new base URI.
     */
    function setNFTMetadataURI(string memory baseURI) public onlyOwner {
        _baseTokenURI = baseURI;
    }

    /**
     * @notice Returns the token URI for a given Achievement NFT ID.
     * @param tokenId The NFT token ID.
     * @return The URI for the NFT metadata.
     */
    function tokenURINFT(uint256 tokenId) public view returns (string memory) {
        if (!_existsNFT(tokenId)) revert InvalidNFTId();
        // In a real application, you'd likely concatenate baseURI with tokenId
        // and potentially a suffix, or fetch dynamic data for the URI endpoint.
        // For this example, just returning the base URI for simplicity.
         return _baseTokenURI;
    }


    // --- Utility/Admin Functions ---

    /**
     * @notice Owner function. Pauses staking, unstaking, and claiming rewards.
     */
    function pauseStaking() public onlyOwner whenNotPaused {
        _paused = true;
        emit Paused(msg.sender);
    }

    /**
     * @notice Owner function. Unpauses staking operations.
     */
    function unpauseStaking() public onlyOwner whenPaused {
        _paused = false;
        emit Unpaused(msg.sender);
    }

    /**
     * @notice Owner function. Allows the owner to rescue any ERC20 tokens
     * accidentally sent to the contract, excluding the contract's own token.
     * @param tokenAddress The address of the ERC20 token to rescue.
     * @param amount The amount of tokens to rescue.
     */
    function rescueERC20(address tokenAddress, uint256 amount) public onlyOwner {
        // Prevent rescuing the contract's own token
        if (tokenAddress == address(this)) revert TokenRescueFailed();

        // Use low-level call or interface for safety without external imports
        // Define a minimal ERC20 interface locally
        (bool success, bytes memory data) = tokenAddress.call(abi.encodeWithSelector(bytes4(keccak256("transfer(address,uint256)")), _owner, amount));

        if (!success || (data.length > 0 && !abi.decode(data, (bool)))) {
            revert TokenRescueFailed();
        }
    }


    /**
     * @notice Owner function. Relinquishes ownership of the contract.
     * Future calls to onlyOwner will fail.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    // Fallback function to receive Ether (optional, depends if contract should hold ETH)
    receive() external payable {}
    fallback() external payable {}
}
```