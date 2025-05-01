Okay, here is a Solidity smart contract concept based on a "Commitment-Based Evolution" system. It involves users committing tokens for periods, earning non-transferable "Essence" based on their commitment, and using that Essence to unlock unique "Traits" that can provide various benefits within the system. This is *not* a standard ERC20 staking pool or yield farm; the focus is on the dynamic accumulation of Essence and the unlocking of Traits as a form of progression or evolution linked to commitment.

It aims for creativity by introducing non-transferable points (Essence) used for internal progression (Traits) rather than just yield. It's advanced by managing dynamic state per user (unlocked traits) and potentially complex Essence calculation based on multiple stakes and time. It's trendy by incorporating concepts related to digital identity/soulbound-like elements (non-transferable Essence) and gamified mechanics (evolution, traits).

This contract is a conceptual example. A production system would require significantly more robust error handling, security checks, gas optimizations, and potentially external libraries (like OpenZeppelin's full suite, especially for ERC20 and AccessControl).

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title CommitmentEssenceEvolution
 * @dev A smart contract system where users commit tokens for periods to earn non-transferable Essence.
 *      Essence can be used to unlock Traits, providing unique benefits or status within the system.
 *      This contract includes a basic internal ERC20 token implementation for demonstration.
 *
 * Outline:
 * 1. Basic ERC20 Token Implementation (COMMIT Token).
 * 2. Staking Mechanism: Users lock COMMIT tokens for specific durations.
 * 3. Essence System: Non-transferable points earned over time based on active stakes.
 * 4. Trait System: Unlockable features using accumulated Essence.
 * 5. Admin/Parameter Management: Functions for the contract owner to configure system parameters and trait types.
 * 6. Query Functions: Read-only functions to check state.
 *
 * Function Summary (Minimum 20):
 * - Token Functions (Basic ERC20 - Internal Implementation):
 *   - constructor: Initializes the token details and minter role.
 *   - name: Returns token name.
 *   - symbol: Returns token symbol.
 *   - decimals: Returns token decimals.
 *   - totalSupply: Returns total supply.
 *   - balanceOf: Returns account balance.
 *   - transfer: Transfers tokens.
 *   - approve: Approves spending.
 *   - allowance: Returns allowance.
 *   - transferFrom: Transfers tokens using allowance.
 *   - mint (Admin): Mints new tokens.
 *   - burn (User): Burns tokens from own balance.
 *
 * - Staking Functions:
 *   - stake: Locks COMMIT tokens for a specified duration to earn Essence.
 *   - unstake: Initiates the unstaking process after the lock-up period ends.
 *   - claimStakedTokens: Claims staked tokens after successful unstaking.
 *
 * - Essence Functions:
 *   - claimEssence: Calculates and distributes accumulated Essence based on active stakes and time.
 *   - getUserEssence: Returns the current non-claimable essence for a user.
 *
 * - Trait Functions:
 *   - addTraitType (Admin): Defines a new trait type with its Essence cost and potential effects (represented by type/value).
 *   - updateTraitCost (Admin): Updates the Essence cost of an existing trait type.
 *   - removeTraitType (Admin): Removes a trait type (careful with existing unlocked traits).
 *   - unlockTrait: Spends user's Essence to unlock a specific trait.
 *   - getUserTraits: Returns a list of trait IDs unlocked by a user.
 *   - getTraitDetails: Returns details of a specific trait type.
 *   - getAvailableTraits: Returns IDs of all currently defined trait types.
 *   - hasTrait: Checks if a user has unlocked a specific trait.
 *
 * - Admin/Parameter Functions:
 *   - setStakingMultiplier: Sets the essence multiplier for a specific staking duration tier.
 *   - setEssencePerStakeMultiplier: Sets the base multiplier for essence calculation based on stake amount.
 *
 * - Query Functions (Helpers/Views):
 *   - getUserStakes: Returns details of all stakes for a user.
 *   - getStakeDetails: Returns details for a specific stake ID.
 *   - getPendingEssence: Calculates potential Essence gain since last claim/interaction based on active stakes.
 *   - getStakingMultiplier: Returns the multiplier for a given duration tier.
 *
 * Total Functions: 12 (Token) + 3 (Staking) + 2 (Essence) + 8 (Trait) + 2 (Admin Params) + 4 (Query) = 31 functions.
 */

// Minimal internal ERC20 implementation for demonstration
contract BasicERC20 {
    string public name;
    string public symbol;
    uint8 public immutable decimals = 18;
    uint256 private _totalSupply;
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    address public minter; // Basic admin role for minting

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    constructor(string memory name_, string memory symbol_, uint256 initialSupply) {
        name = name_;
        symbol = symbol_;
        minter = msg.sender; // Owner is initially the minter
        _mint(msg.sender, initialSupply); // Mint initial supply to the deployer
    }

    modifier onlyMinter() {
        require(msg.sender == minter, "Caller is not the minter");
        _;
    }

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    function transfer(address to, uint256 value) public returns (bool) {
        _transfer(msg.sender, to, value);
        return true;
    }

    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 value) public returns (bool) {
        _approve(msg.sender, spender, value);
        return true;
    }

    function transferFrom(address from, address to, uint256 value) public returns (bool) {
        _transfer(from, to, value);
        uint256 currentAllowance = _allowances[from][msg.sender];
        require(currentAllowance >= value, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(from, msg.sender, currentAllowance - value);
        }
        return true;
    }

    function _transfer(address from, address to, uint256 value) internal {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        uint256 fromBalance = _balances[from];
        require(fromBalance >= value, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - value;
            _balances[to] += value;
        }

        emit Transfer(from, to, value);
    }

    function _mint(address account, uint256 value) internal onlyMinter {
        require(account != address(0), "ERC20: mint to the zero address");
        _totalSupply += value;
        _balances[account] += value;
        emit Transfer(address(0), account, value);
    }

    function _burn(address account, uint256 value) internal {
        require(account != address(0), "ERC20: burn from the zero address");
        uint256 accountBalance = _balances[account];
        require(accountBalance >= value, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - value;
        }
        _totalSupply -= value;
        emit Transfer(account, address(0), value);
    }

    // Expose a burn function for users to reduce their balance
    function burn(uint256 amount) public {
        _burn(msg.sender, amount);
    }
}

contract CommitmentEssenceEvolution is BasicERC20 {
    // --- State Variables ---

    // Admin
    address public owner;

    // Staking
    struct Stake {
        uint256 id;
        address user;
        uint256 amount;
        uint64 stakeTime;
        uint64 duration; // in seconds
        uint64 unlockTime;
        bool claimed; // If staked tokens have been claimed
        uint256 lastEssenceClaimTime; // Per stake, for more accurate calculation
    }
    uint256 private _nextStakeId = 1;
    mapping(address => uint256[]) public userStakes; // User address => list of stake IDs
    mapping(uint256 => Stake) public stakes; // Stake ID => Stake details

    // Essence
    mapping(address => uint256) private _userEssence; // User address => Essence balance (non-transferable)

    // Essence Calculation Parameters
    // Staking duration tier (e.g., 30 days, 90 days) => Essence multiplier
    mapping(uint64 => uint256) public stakingDurationMultipliers;
    // Base multiplier for Essence calculation (e.g., 1e18 represents 1x, can be scaled)
    uint256 public essencePerStakeMultiplier = 1e18;

    // Traits (Evolution)
    struct Trait {
        uint256 id;
        string name;
        string description;
        uint256 essenceCost;
        uint8 traitType; // e.g., 0=EssenceBoost, 1=Discount, 2=SpecialAbility
        uint256 traitValue; // Value associated with the type (e.g., percentage boost, discount amount)
        bool active; // Can trait still be unlocked?
    }
    uint256 private _nextTraitId = 1;
    mapping(uint256 => Trait) public traitTypes; // Trait ID => Trait details
    mapping(address => mapping(uint256 => bool)) public userUnlockedTraits; // User address => Trait ID => Unlocked status

    // --- Events ---
    event Staked(address indexed user, uint256 stakeId, uint256 amount, uint64 duration, uint64 unlockTime);
    event Unstaked(address indexed user, uint256 stakeId, uint64 unlockTime);
    event StakedTokensClaimed(address indexed user, uint256 stakeId, uint256 amount);
    event EssenceClaimed(address indexed user, uint256 amount);
    event TraitUnlocked(address indexed user, uint256 traitId, uint256 essenceSpent);
    event TraitTypeAdded(uint256 traitId, string name, uint256 essenceCost, uint8 traitType, uint256 traitValue);
    event TraitTypeUpdated(uint256 traitId, uint256 newCost, bool activeStatus);
    event TraitTypeRemoved(uint256 traitId);
    event StakingMultiplierUpdated(uint64 duration, uint256 multiplier);
    event EssencePerStakeMultiplierUpdated(uint256 multiplier);

    // --- Modifiers ---
    modifier onlyOwner() {
        require(msg.sender == owner, "Caller is not the owner");
        _;
    }

    // --- Constructor ---
    constructor(string memory name_, string memory symbol_, uint256 initialSupply)
        BasicERC20(name_, symbol_, initialSupply)
    {
        owner = msg.sender; // Owner of this contract is also the owner of BasicERC20 minter role
        // Set initial staking duration multipliers (example values)
        stakingDurationMultipliers[30 * 1 days] = 1e18; // 30 days = 1x multiplier
        stakingDurationMultipliers[90 * 1 days] = 1.2e18; // 90 days = 1.2x multiplier
        stakingDurationMultipliers[180 * 1 days] = 1.5e18; // 180 days = 1.5x multiplier
        stakingDurationMultipliers[365 * 1 days] = 2e18; // 365 days = 2x multiplier
    }

    // --- Staking Functions ---

    /**
     * @dev Stakes a specified amount of tokens for a given duration.
     * @param amount The amount of tokens to stake.
     * @param duration The duration in seconds the tokens will be locked. Must be one of the predefined tiers.
     */
    function stake(uint256 amount, uint64 duration) external {
        require(amount > 0, "Stake amount must be greater than 0");
        require(stakingDurationMultipliers[duration] > 0, "Invalid staking duration");

        // Pull tokens from the user
        require(transferFrom(msg.sender, address(this), amount), "Token transfer failed");

        uint256 currentStakeId = _nextStakeId++;
        uint64 currentTime = uint64(block.timestamp);
        uint64 unlockTime = currentTime + duration;

        stakes[currentStakeId] = Stake({
            id: currentStakeId,
            user: msg.sender,
            amount: amount,
            stakeTime: currentTime,
            duration: duration,
            unlockTime: unlockTime,
            claimed: false,
            lastEssenceClaimTime: currentTime // Start essence calculation from now
        });

        userStakes[msg.sender].push(currentStakeId);

        emit Staked(msg.sender, currentStakeId, amount, duration, unlockTime);
    }

    /**
     * @dev Initiates the unstaking process. Can only be called after the initial lock-up period.
     * @param stakeId The ID of the stake to unstake.
     */
    function unstake(uint256 stakeId) external {
        Stake storage userStake = stakes[stakeId];
        require(userStake.user == msg.sender, "Not your stake");
        require(userStake.unlockTime > 0, "Stake does not exist or is invalid");
        require(!userStake.claimed, "Stake already claimed");
        require(block.timestamp >= userStake.unlockTime, "Stake is still locked");

        // No state change needed here other than potentially marking it ready for claim
        // We can simplify and just allow claiming directly after unlockTime
        // Let's adjust claimStakedTokens to handle this.
        // This function is technically not needed if claimStakedTokens checks time.
        // Retaining it for explicit 'unstake initiated' concept, but it does nothing state-changing.
        // In a more complex system, 'unstake' might start a cooling down period.
        // For this example, we'll make claimStakedTokens do the check.

        // Let's make this function useful: it will calculate and claim pending essence
        // before the stake is marked as fully ready for token claim.
        _claimEssenceForStake(msg.sender, stakeId);

        // Stake is now ready to be claimed via claimStakedTokens
        emit Unstaked(msg.sender, stakeId, userStake.unlockTime);
    }

    /**
     * @dev Claims the staked tokens after the unstaking period (lock-up duration) has passed.
     * @param stakeId The ID of the stake to claim.
     */
    function claimStakedTokens(uint256 stakeId) external {
        Stake storage userStake = stakes[stakeId];
        require(userStake.user == msg.sender, "Not your stake");
        require(userStake.unlockTime > 0, "Stake does not exist or is invalid");
        require(!userStake.claimed, "Stake already claimed");
        require(block.timestamp >= userStake.unlockTime, "Stake is still locked");

        // Ensure any pending essence is claimed before releasing tokens
        _claimEssenceForStake(msg.sender, stakeId);

        uint256 amountToClaim = userStake.amount;
        userStake.claimed = true; // Mark as claimed

        // Transfer tokens back to the user
        _transfer(address(this), msg.sender, amountToClaim);

        // Note: We don't delete the stake struct immediately for historical lookup
        // A production contract might need a cleanup mechanism or handle storage carefully.

        emit StakedTokensClaimed(msg.sender, stakeId, amountToClaim);
    }

    // --- Essence Functions ---

    /**
     * @dev Internal helper to calculate and claim essence for a single stake.
     * @param user The user address.
     * @param stakeId The ID of the stake.
     */
    function _claimEssenceForStake(address user, uint256 stakeId) internal {
        Stake storage userStake = stakes[stakeId];
        require(userStake.user == user, "Stake does not belong to user");
        require(!userStake.claimed, "Stake already claimed"); // Essence accumulates until tokens are claimed

        uint256 currentTime = block.timestamp;
        // Essence accumulation stops when the stake unlock time is reached,
        // or when tokens are claimed (whichever happens first effectively).
        // Let's cap accumulation at unlock time for simplicity.
        uint256 endTimeForCalculation = userStake.unlockTime > 0 && currentTime > userStake.unlockTime
                                       ? userStake.unlockTime : currentTime;

        uint256 startTimeForCalculation = userStake.lastEssenceClaimTime;

        if (endTimeForCalculation <= startTimeForCalculation) {
            return; // No time elapsed since last claim
        }

        uint256 timeElapsed = endTimeForCalculation - startTimeForCalculation;
        uint256 durationMultiplier = stakingDurationMultipliers[userStake.duration];
        // Essence calculation: amount * duration_multiplier * time_elapsed * base_multiplier / scaling_factor (for duration/time units)
        // Need scaling to prevent overflow and get meaningful units.
        // Let's assume 1 essence unit = 1e18.
        // Base essence gain: stake_amount * time_elapsed * some_rate
        // Applied multipliers: * duration_multiplier * essencePerStakeMultiplier
        // Rate unit: (essence per token per second). Let's scale by 1e18*1e18 for multipliers.
        // essence = (amount * time_elapsed * durationMultiplier * essencePerStakeMultiplier) / (1e18 * 1e18);
        // To avoid large intermediate values, rearrange and be careful:
        // Let's simplify the multipliers first: effectiveMultiplier = (durationMultiplier * essencePerStakeMultiplier) / 1e18;
        // Then: essence = (amount * time_elapsed * effectiveMultiplier) / 1e18;
        // Example: durationMultiplier = 1.2e18, essencePerStakeMultiplier = 1e18
        // effectiveMultiplier = (1.2e18 * 1e18) / 1e18 = 1.2e18
        // essence = (amount * time_elapsed * 1.2e18) / 1e18
        // This is (amount * time_elapsed * 1.2). This means 1 token staked for 1 second with 1.2x multiplier gives 1.2 essence units (1.2 * 1e18).
        // This requires 'amount' to be in 1e18 units (like standard ERC20).

        uint256 effectiveMultiplier = (durationMultiplier * essencePerStakeMultiplier) / (1e18); // Scale multipliers
        uint256 essenceGained = (userStake.amount * timeElapsed * effectiveMultiplier) / (1e18); // Scale amount/time

        if (essenceGained > 0) {
            _userEssence[user] += essenceGained;
            emit EssenceClaimed(user, essenceGained);
        }

        // Update last claim time for this specific stake
        userStake.lastEssenceClaimTime = endTimeForCalculation;
    }

    /**
     * @dev Claims accumulated Essence from all active stakes for the caller.
     * Accumulates Essence based on elapsed time since the last claim or stake creation.
     */
    function claimEssence() external {
        uint256 totalEssenceGained = 0;
        uint256[] storage stakesForUser = userStakes[msg.sender];

        for (uint i = 0; i < stakesForUser.length; i++) {
             uint256 stakeId = stakesForUser[i];
             Stake storage currentStake = stakes[stakeId];

             // Only calculate for stakes that haven't had their tokens claimed yet
             if (!currentStake.claimed) {
                uint256 currentEssenceBeforeClaim = _userEssence[msg.sender];
                _claimEssenceForStake(msg.sender, stakeId);
                uint256 essenceAfterClaim = _userEssence[msg.sender];
                totalEssenceGained += (essenceAfterClaim - currentEssenceBeforeClaim);
             }
        }

        // Note: Essence is added to user's balance within _claimEssenceForStake.
        // This function primarily iterates and triggers the per-stake calculation.
        // A dedicated event for total claimed in *this* transaction might be useful,
        // but emitting per-stake events within the loop provides more detail.
        // The TraitUnlocked event also shows Essence spend.
    }

    /**
     * @dev Gets the current non-transferable Essence balance for a user.
     * @param user The address of the user.
     * @return The user's current Essence balance.
     */
    function getUserEssence(address user) public view returns (uint256) {
        return _userEssence[user];
    }

    /**
     * @dev Calculates the potential Essence gained since the last claim time for all active stakes.
     * Does *not* update state or transfer Essence.
     * @param user The user address.
     * @return The amount of Essence pending claim.
     */
    function getPendingEssence(address user) public view returns (uint256) {
        uint256 pending = 0;
        uint256[] storage stakesForUser = userStakes[user];
        uint256 currentTime = block.timestamp;

        for (uint i = 0; i < stakesForUser.length; i++) {
            uint256 stakeId = stakesForUser[i];
            Stake storage currentStake = stakes[stakeId];

            if (!currentStake.claimed) {
                 uint256 endTimeForCalculation = currentStake.unlockTime > 0 && currentTime > currentStake.unlockTime
                                                ? currentStake.unlockTime : currentTime;

                 uint256 startTimeForCalculation = currentStake.lastEssenceClaimTime;

                 if (endTimeForCalculation > startTimeForCalculation) {
                     uint256 timeElapsed = endTimeForCalculation - startTimeForCalculation;
                     uint256 durationMultiplier = stakingDurationMultipliers[currentStake.duration];
                     uint256 effectiveMultiplier = (durationMultiplier * essencePerStakeMultiplier) / (1e18);
                     uint256 essenceGained = (currentStake.amount * timeElapsed * effectiveMultiplier) / (1e18);
                     pending += essenceGained;
                 }
            }
        }
        return pending;
    }


    // --- Trait (Evolution) Functions ---

    /**
     * @dev Adds a new trait type definition. Only callable by the owner.
     * @param name The name of the trait.
     * @param description The description of the trait.
     * @param essenceCost The Essence cost to unlock this trait.
     * @param traitType A numerical identifier for the trait's category/effect type.
     * @param traitValue A numerical value associated with the trait's effect.
     */
    function addTraitType(
        string memory name,
        string memory description,
        uint256 essenceCost,
        uint8 traitType,
        uint256 traitValue
    ) external onlyOwner {
        uint256 newTraitId = _nextTraitId++;
        traitTypes[newTraitId] = Trait({
            id: newTraitId,
            name: name,
            description: description,
            essenceCost: essenceCost,
            traitType: traitType,
            traitValue: traitValue,
            active: true // New traits are active by default
        });
        emit TraitTypeAdded(newTraitId, name, essenceCost, traitType, traitValue);
    }

    /**
     * @dev Updates the Essence cost or active status of an existing trait type. Only callable by the owner.
     * @param traitId The ID of the trait type to update.
     * @param newCost The new Essence cost.
     * @param activeStatus The new active status (true if unlockable, false otherwise).
     */
    function updateTraitCost(uint256 traitId, uint256 newCost, bool activeStatus) external onlyOwner {
        require(traitTypes[traitId].id != 0, "Trait does not exist");
        traitTypes[traitId].essenceCost = newCost;
        traitTypes[traitId].active = activeStatus;
        emit TraitTypeUpdated(traitId, newCost, activeStatus);
    }

    /**
     * @dev Removes a trait type definition, making it unavailable for unlocking. Only callable by the owner.
     * Does not affect users who have already unlocked it.
     * @param traitId The ID of the trait type to remove.
     */
    function removeTraitType(uint256 traitId) external onlyOwner {
        require(traitTypes[traitId].id != 0, "Trait does not exist");
        // Mark as inactive rather than deleting for historical reference
        traitTypes[traitId].active = false;
        emit TraitTypeRemoved(traitId);
    }

    /**
     * @dev Allows a user to unlock a specific trait using their accumulated Essence.
     * @param traitId The ID of the trait to unlock.
     */
    function unlockTrait(uint256 traitId) external {
        Trait storage traitDetails = traitTypes[traitId];
        require(traitDetails.id != 0 && traitDetails.active, "Trait does not exist or is not active");
        require(!userUnlockedTraits[msg.sender][traitId], "Trait already unlocked");
        require(_userEssence[msg.sender] >= traitDetails.essenceCost, "Insufficient Essence");

        // Deduct Essence
        unchecked {
            _userEssence[msg.sender] -= traitDetails.essenceCost;
        }

        // Mark trait as unlocked for the user
        userUnlockedTraits[msg.sender][traitId] = true;

        emit TraitUnlocked(msg.sender, traitId, traitDetails.essenceCost);
    }

    /**
     * @dev Returns a list of trait IDs unlocked by a specific user.
     * Note: This implementation iterates through all possible trait IDs.
     * For a very large number of traits, a more gas-efficient method might be needed.
     * @param user The address of the user.
     * @return An array of trait IDs unlocked by the user.
     */
    function getUserTraits(address user) public view returns (uint256[] memory) {
        uint256[] memory unlocked;
        uint256 count = 0;
        // Determine size first
        for (uint256 i = 1; i < _nextTraitId; i++) {
            if (userUnlockedTraits[user][i]) {
                count++;
            }
        }
        // Populate array
        unlocked = new uint256[](count);
        uint256 index = 0;
         for (uint256 i = 1; i < _nextTraitId; i++) {
            if (userUnlockedTraits[user][i]) {
                unlocked[index++] = i;
            }
        }
        return unlocked;
    }

     /**
     * @dev Gets details for a specific trait type.
     * @param traitId The ID of the trait type.
     * @return Trait details: name, description, essence cost, type, value, active status.
     */
    function getTraitDetails(uint256 traitId) public view returns (string memory, string memory, uint256, uint8, uint256, bool) {
        Trait storage trait = traitTypes[traitId];
        require(trait.id != 0, "Trait does not exist");
        return (trait.name, trait.description, trait.essenceCost, trait.traitType, trait.traitValue, trait.active);
    }

    /**
     * @dev Returns a list of all currently defined trait type IDs.
     * @return An array of all trait type IDs.
     */
    function getAvailableTraits() public view returns (uint256[] memory) {
        uint256[] memory available;
        uint256 count = 0;
        // Determine size first
        for (uint256 i = 1; i < _nextTraitId; i++) {
             // Only include active traits for availability list
            if (traitTypes[i].id != 0 && traitTypes[i].active) {
                count++;
            }
        }
        // Populate array
        available = new uint256[](count);
        uint256 index = 0;
         for (uint256 i = 1; i < _nextTraitId; i++) {
             if (traitTypes[i].id != 0 && traitTypes[i].active) {
                available[index++] = i;
            }
        }
        return available;
    }

    /**
     * @dev Checks if a user has unlocked a specific trait.
     * @param user The address of the user.
     * @param traitId The ID of the trait.
     * @return True if the user has unlocked the trait, false otherwise.
     */
    function hasTrait(address user, uint256 traitId) public view returns (bool) {
        return userUnlockedTraits[user][traitId];
    }


    // --- Admin/Parameter Functions ---

    /**
     * @dev Sets or updates the Essence multiplier for a specific staking duration tier. Only callable by the owner.
     * Adding a multiplier for a new duration creates a new tier. Setting multiplier to 0 effectively removes a tier.
     * @param duration The staking duration in seconds.
     * @param multiplier The new multiplier (e.g., 1e18 for 1x, 1.5e18 for 1.5x).
     */
    function setStakingMultiplier(uint64 duration, uint256 multiplier) external onlyOwner {
        require(duration > 0, "Duration must be positive");
        stakingDurationMultipliers[duration] = multiplier;
        emit StakingMultiplierUpdated(duration, multiplier);
    }

    /**
     * @dev Sets the base multiplier used in Essence calculation per stake amount. Only callable by the owner.
     * @param multiplier The new base multiplier (e.g., 1e18 for normal rate).
     */
    function setEssencePerStakeMultiplier(uint256 multiplier) external onlyOwner {
        essencePerStakeMultiplier = multiplier;
        emit EssencePerStakeMultiplierUpdated(multiplier);
    }

    // --- Query Functions (Helpers) ---

    /**
     * @dev Gets a list of stake IDs for a user.
     * @param user The address of the user.
     * @return An array of stake IDs for the user.
     */
    function getUserStakes(address user) public view returns (uint256[] memory) {
        return userStakes[user];
    }

     /**
     * @dev Gets details for a specific stake.
     * @param stakeId The ID of the stake.
     * @return Stake details: user, amount, stakeTime, duration, unlockTime, claimed status.
     */
    function getStakeDetails(uint256 stakeId) public view returns (address, uint256, uint64, uint64, uint64, bool) {
        Stake storage userStake = stakes[stakeId];
         require(userStake.id != 0, "Stake does not exist");
        return (userStake.user, userStake.amount, userStake.stakeTime, userStake.duration, userStake.unlockTime, userStake.claimed);
    }

    /**
     * @dev Gets the multiplier for a specific staking duration tier.
     * @param duration The staking duration in seconds.
     * @return The multiplier for the given duration, or 0 if no multiplier is set.
     */
    function getStakingMultiplier(uint64 duration) public view returns (uint256) {
        return stakingDurationMultipliers[duration];
    }
}
```