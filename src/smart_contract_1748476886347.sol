Okay, let's design a smart contract system focusing on a "Fractal Reserve" concept. The idea is to create a decentralized reserve currency (`FRC`) backed by a diverse treasury of approved assets. The "fractal" aspect comes from a dynamic index token (`FRI`) that represents a proportional share of the treasury's *composition*, allowing users to interact with the underlying reserve structure directly.

This involves:
1.  A native reserve token (`FRC`).
2.  A treasury holding various approved ERC-20 tokens.
3.  A bonding mechanism for users to sell approved tokens to the treasury for discounted `FRC`.
4.  A staking mechanism for users to earn yield on `FRC`.
5.  A "Fractal Index" token (`FRI`) that can be minted by depositing a basket of treasury assets (in correct proportions) and redeemed for the underlying assets.
6.  Governance to manage parameters, approved assets, and index composition.

We'll use OpenZeppelin contracts for standard features like ERC20, Ownable, and Pausable to keep the focus on the core logic while ensuring best practices for common patterns.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

// --- Outline and Function Summary ---
//
// 1. Contract Overview:
//    - FractalReserve: Core contract managing FRC token, treasury, bonding, staking, and FRI token.
//    - FRC: The native reserve token (implemented within FractalReserve).
//    - FRI: The Fractal Index token representing a proportional share of the treasury composition (implemented within FractalReserve).
//    - Treasury: Holds approved ERC-20 tokens.
//    - Governance: Owner/Governor role to manage critical parameters.
//    - Pausable: Mechanism to pause critical operations in emergencies.
//    - ReentrancyGuard: Prevents reentrancy attacks on state-changing external calls.
//
// 2. State Variables:
//    - Core token details (name, symbol, decimals - for FRC & FRI).
//    - Total supply of FRC and FRI.
//    - Mappings for FRC and FRI balances.
//    - Governor address.
//    - Approved reserve assets mapping (token address => bool).
//    - Bond terms mapping (token address => struct BondTerms).
//    - User bond info mapping (user address => token address => struct UserBond).
//    - Staking info mapping (user address => struct UserStake).
//    - Global staking state (total staked FRC, last update time).
//    - Index composition mapping (token address => target weight).
//    - Total target index weight (for validation).
//
// 3. FRC Token Functions (Internal, via ERC20 inheritance):
//    - transfer, transferFrom, approve, allowance, balanceOf, totalSupply
//    - _mint: Mints FRC (used by bonding, staking rewards).
//    - _burn: Burns FRC (potentially used by governance/index redemption).
//
// 4. FRI Token Functions (Internal, via ERC20-like implementation):
//    - _mintFRI: Mints FRI token (used by mintIndex).
//    - _burnFRI: Burns FRI token (used by redeemIndex).
//    - balanceOfFRI: Get user's FRI balance.
//    - totalSupplyFRI: Get total FRI supply.
//
// 5. Governance & Access Control:
//    - constructor: Initializes contract, sets owner, governor, initial FRC/FRI params.
//    - setGovernor: Sets the address of the governor (can manage parameters, treasury).
//    - addReserveAsset: Allows governor to add a new approved reserve token.
//    - removeReserveAsset: Allows governor to remove a reserve token.
//    - setBondTerms: Allows governor to set bonding parameters for an asset.
//    - setStakingRate: Allows governor to set the rate of FRC rewards per staked FRC per second.
//    - setIndexComposition: Allows governor to set the target weights for the Fractal Index.
//    - treasuryWithdraw: Allows governor to withdraw assets from the treasury (e.g., for operations, rebalancing).
//    - pause: Owner/Governor can pause critical functions.
//    - unpause: Owner/Governor can unpause critical functions.
//
// 6. Treasury Functions:
//    - treasuryDeposit: Allows governor to deposit assets directly into the treasury (not via bonding).
//    - getTreasuryTokenBalance: View balance of a specific token in the treasury.
//    - getTreasuryValue (View): Calculates total value of treasury (requires Oracle integration - conceptually shown).
//
// 7. Bonding Functions:
//    - createBond: User initiates a bond by transferring approved reserve asset to the contract.
//    - calculateBondPayout: View function to estimate FRC payout for a given bond amount and terms.
//    - claimBond: User claims vested FRC from their active bond.
//    - getUserBond: View function to get details about a user's bond for a specific asset.
//
// 8. Staking Functions:
//    - stake: User deposits FRC into the staking pool.
//    - unstake: User withdraws staked FRC.
//    - claimStakingRewards: User claims accumulated staking rewards (FRC).
//    - calculateStakingRewards: View function to estimate accrued staking rewards for a user.
//    - getUserStake: View function to get details about a user's stake.
//
// 9. Fractal Index Functions:
//    - mintIndex: User deposits the required basket of reserve assets to mint FRI tokens.
//    - redeemIndex: User burns FRI tokens to receive a proportional basket of reserve assets from the treasury.
//    - getIndexComposition: View function to get the current target index weights.
//    - calculateIndexMintAmounts: View function to calculate required input token amounts to mint N FRI.
//    - calculateIndexRedeemAmounts: View function to calculate output token amounts when redeeming N FRI.
//    - getFRIPrice (View): Calculates the 'value' of 1 FRI based on current treasury holdings and index weights (requires Oracle integration - conceptually shown).
//
// 10. Utility & View Functions:
//     - getReserveAssets: View list of approved reserve assets.
//     - getBondTerms: View bond terms for a specific asset.
//     - getFRCPrice (View): Calculates the 'value' of 1 FRC based on treasury value and FRC supply (requires Oracle integration - conceptually shown).
//     - etc. (General getters for state variables)
//
// --- End of Outline and Summary ---


contract FractalReserve is ERC20, Ownable, Pausable, ReentrancyGuard {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    // --- State Variables ---

    // Governance
    address public governor;
    address private pendingGovernor;
    uint256 private constant GOVERNOR_TRANSFER_DELAY = 2 days; // Delay for governor transfer acceptance
    uint256 private governorTransferInitiatedTime;

    // Reserve Assets
    mapping(address => bool) public isReserveAsset;
    address[] public reserveAssetsList; // To easily iterate or list approved assets

    // Bonding
    struct BondTerms {
        uint256 discountBps; // Discount in basis points (e.g., 1000 for 10%)
        uint256 vestingPeriod; // Vesting duration in seconds
        uint256 totalCapacity; // Max amount of asset allowed for bonding
        uint256 currentCapacityUsed; // Current amount bonded
        uint256 minBondAmount; // Minimum amount for a bond
    }
    mapping(address => BondTerms) public bondTerms; // asset => terms

    struct UserBond {
        uint256 amount; // Amount of reserve asset bonded
        uint256 startTimestamp; // When the bond started
        uint256 payoutFRC; // Total FRC to be received
        uint256 claimedAmount; // FRC already claimed
    }
    mapping(address => mapping(address => UserBond)) public userBonds; // user => asset => bond

    // Staking
    struct UserStake {
        uint256 amount; // Amount of FRC staked
        uint256 rewardPerTokenPaid; // Reward debt tracking for user
        uint256 lastStakeUpdateTime; // Timestamp of last stake/unstake/claim
    }
    mapping(address => UserStake) public userStakes; // user => stake info

    uint256 public totalStakedFRC;
    uint256 public rewardRatePerFRCPerSecond; // Rate of FRC rewards per staked FRC per second
    uint256 public lastRewardUpdateTime;
    uint256 public rewardPerTokenStored; // Accumulator for rewards calculation

    // Fractal Index (FRI)
    string public constant FRI_NAME = "Fractal Reserve Index";
    string public constant FRI_SYMBOL = "FRI";
    uint8 public constant FRI_DECIMALS = 18; // Assuming same decimals as FRC
    uint256 private _totalSupplyFRI;
    mapping(address => uint256) private _balancesFRI;

    mapping(address => uint256) public indexCompositionWeights; // asset => weight (e.g., 5000 for 50%)
    uint256 public totalIndexWeight; // Sum of all weights, should ideally be 10000

    // Oracle (Placeholder - requires external integration)
    // address public oracleAddress; // Address of a price oracle contract

    // --- Events ---
    event GovernorSet(address indexed newGovernor);
    event GovernorTransferProposed(address indexed pendingGovernor);
    event GovernorTransferAccepted(address indexed newGovernor);
    event ReserveAssetAdded(address indexed asset);
    event ReserveAssetRemoved(address indexed asset);
    event BondTermsSet(address indexed asset, uint256 discountBps, uint256 vestingPeriod, uint256 totalCapacity, uint256 minBondAmount);
    event BondCreated(address indexed user, address indexed asset, uint256 amount, uint256 payoutFRC);
    event BondClaimed(address indexed user, address indexed asset, uint256 claimedAmount, uint256 remainingPayout);
    event Staked(address indexed user, uint256 amount);
    event Unstaked(address indexed user, uint256 amount);
    event StakingRewardsClaimed(address indexed user, uint256 amount);
    event StakingRateSet(uint256 newRate);
    event IndexCompositionSet(address indexed asset, uint256 weight);
    event IndexMinted(address indexed user, uint256 amountFRI, uint256[] amountsDeposited);
    event IndexRedeemed(address indexed user, uint256 amountFRI, uint256[] amountsReceived);
    event TreasuryDeposited(address indexed caller, address indexed asset, uint256 amount);
    event TreasuryWithdraw(address indexed caller, address indexed asset, uint256 amount);

    // --- Constructor ---
    constructor(
        string memory name,
        string memory symbol,
        uint256 initialSupplyFRC, // Can be 0 for a pure reserve, or initial mint for founders/DAO
        address initialGovernor
    ) ERC20(name, symbol) Ownable(msg.sender) Pausable(false) {
        governor = initialGovernor;
        // Optionally mint initial supply for distribution/liquidity
        if (initialSupplyFRC > 0) {
            _mint(msg.sender, initialSupplyFRC);
        }
        emit GovernorSet(governor);
    }

    // --- Access Control Modifiers ---
    modifier onlyGovernor() {
        require(msg.sender == governor, "Not authorized: Governor role required");
        _;
    }

    modifier onlyGovernorOrOwner() {
        require(msg.sender == governor || msg.sender == owner(), "Not authorized: Governor or Owner role required");
        _;
    }

    // --- Governance & Access Control Functions ---

    /// @notice Initiates the transfer of the governor role to a new address.
    /// @param _pendingGovernor The address to transfer the governor role to.
    function proposeGovernorTransfer(address _pendingGovernor) external onlyOwner {
        require(_pendingGovernor != address(0), "New governor cannot be the zero address");
        pendingGovernor = _pendingGovernor;
        governorTransferInitiatedTime = block.timestamp;
        emit GovernorTransferProposed(_pendingGovernor);
    }

    /// @notice Accepts the governor role transfer. Must be called by the pending governor after the delay.
    function acceptGovernorTransfer() external {
        require(msg.sender == pendingGovernor, "Not the pending governor");
        require(block.timestamp >= governorTransferInitiatedTime + GOVERNOR_TRANSFER_DELAY, "Governor transfer delay not passed");
        governor = pendingGovernor;
        pendingGovernor = address(0);
        emit GovernorTransferAccepted(governor);
    }

    /// @notice Allows the governor to add a new approved reserve asset.
    /// @param asset The address of the ERC-20 token to add.
    function addReserveAsset(address asset) external onlyGovernor whenNotPaused {
        require(asset != address(0), "Asset cannot be zero address");
        require(!isReserveAsset[asset], "Asset is already approved");
        isReserveAsset[asset] = true;
        reserveAssetsList.push(asset);
        emit ReserveAssetAdded(asset);
    }

    /// @notice Allows the governor to remove an approved reserve asset.
    /// @param asset The address of the ERC-20 token to remove.
    /// @dev Removes from the list but doesn't affect existing bonds/index composition until updated.
    function removeReserveAsset(address asset) external onlyGovernor whenNotPaused {
        require(asset != address(0), "Asset cannot be zero address");
        require(isReserveAsset[asset], "Asset is not approved");
        isReserveAsset[asset] = false;
        // Simple removal from list - could be optimized for gas if list is huge
        for (uint i = 0; i < reserveAssetsList.length; i++) {
            if (reserveAssetsList[i] == asset) {
                reserveAssetsList[i] = reserveAssetsList[reserveAssetsList.length - 1];
                reserveAssetsList.pop();
                break;
            }
        }
        emit ReserveAssetRemoved(asset);
    }

    /// @notice Allows the governor to set the terms for bonding a specific reserve asset.
    /// @param asset The address of the reserve token.
    /// @param discountBps Discount in basis points (100 = 1%).
    /// @param vestingPeriod_ Vesting duration in seconds.
    /// @param totalCapacity_ Max total amount of this asset that can be bonded.
    /// @param minBondAmount_ Minimum amount per single bond.
    function setBondTerms(address asset, uint256 discountBps, uint256 vestingPeriod_, uint256 totalCapacity_, uint256 minBondAmount_) external onlyGovernor whenNotPaused {
        require(isReserveAsset[asset], "Asset must be approved");
        require(discountBps <= 10000, "Discount cannot be more than 100%");
        require(totalCapacity_ >= bondTerms[asset].currentCapacityUsed, "New capacity cannot be less than current usage");

        bondTerms[asset] = BondTerms({
            discountBps: discountBps,
            vestingPeriod: vestingPeriod_,
            totalCapacity: totalCapacity_,
            currentCapacityUsed: bondTerms[asset].currentCapacityUsed, // Preserve current usage
            minBondAmount: minBondAmount_
        });
        emit BondTermsSet(asset, discountBps, vestingPeriod_, totalCapacity_, minBondAmount_);
    }

    /// @notice Allows the governor to set the global staking reward rate.
    /// @param newRate The new FRC reward rate per staked FRC per second.
    function setStakingRate(uint256 newRate) external onlyGovernor whenNotPaused {
        updateStakingRewards(); // Update rewards before changing rate
        rewardRatePerFRCPerSecond = newRate;
        emit StakingRateSet(newRate);
    }

    /// @notice Sets the target composition weights for the Fractal Index (FRI).
    /// @param assets Array of asset addresses.
    /// @param weights Array of corresponding weights. Must sum to totalIndexWeight (e.g., 10000).
    /// @dev Clears previous composition. Weights are per 10000 (basis points representation).
    function setIndexComposition(address[] calldata assets, uint256[] calldata weights) external onlyGovernor whenNotPaused {
        require(assets.length == weights.length, "Assets and weights length mismatch");
        uint256 newTotalWeight = 0;

        // Validate assets and calculate new total weight
        for (uint i = 0; i < assets.length; i++) {
            require(isReserveAsset[assets[i]], "Asset must be approved for index");
            newTotalWeight = newTotalWeight.add(weights[i]);
        }
        require(newTotalWeight > 0, "Total weight must be greater than 0"); // Allow partial indices if desired
        // Optional: require(newTotalWeight == 10000, "Total weight must sum to 10000"); // For a full representation

        // Clear old composition
        for (uint i = 0; i < reserveAssetsList.length; i++) {
             indexCompositionWeights[reserveAssetsList[i]] = 0;
        }

        // Set new composition
        for (uint i = 0; i < assets.length; i++) {
            indexCompositionWeights[assets[i]] = weights[i];
            emit IndexCompositionSet(assets[i], weights[i]);
        }
        totalIndexWeight = newTotalWeight;
    }

    /// @notice Allows the governor to withdraw approved assets from the treasury.
    /// @param asset The address of the token to withdraw.
    /// @param amount The amount to withdraw.
    function treasuryWithdraw(address asset, uint256 amount) external onlyGovernor whenNotPaused nonReentrant {
        require(isReserveAsset[asset] || asset == address(this), "Asset must be approved or FRC"); // Allow withdrawing FRC itself if needed
        require(amount > 0, "Withdraw amount must be greater than 0");
        IERC20 token = IERC20(asset);
        uint256 balance = token.balanceOf(address(this));
        require(balance >= amount, "Insufficient balance in treasury");

        token.safeTransfer(governor, amount); // Send to governor
        emit TreasuryWithdraw(governor, asset, amount);

        // If withdrawing FRC, burn it to reduce supply and maintain backing ratio
        if (asset == address(this)) {
            _burn(address(this), amount); // Burn FRC withdrawn from treasury
        }
    }

    /// @notice Pauses the contract. Can only be called by owner or governor.
    function pause() external onlyGovernorOrOwner whenNotPaused {
        _pause();
    }

    /// @notice Unpauses the contract. Can only be called by owner or governor.
    function unpause() external onlyGovernorOrOwner whenPaused {
        _unpause();
    }

    // --- Treasury Functions ---

    /// @notice Allows the governor to deposit approved assets directly into the treasury.
    /// @param asset The address of the token to deposit.
    /// @param amount The amount to deposit.
    /// @dev Requires prior approval by the governor for the contract to pull tokens.
    function treasuryDeposit(address asset, uint256 amount) external onlyGovernor whenNotPaused nonReentrant {
        require(isReserveAsset[asset], "Asset must be approved");
        require(amount > 0, "Deposit amount must be greater than 0");
        IERC20 token = IERC20(asset);
        token.safeTransferFrom(msg.sender, address(this), amount);
        emit TreasuryDeposited(msg.sender, asset, amount);
    }

    /// @notice Gets the balance of a specific token held in the contract's treasury.
    /// @param asset The address of the token.
    /// @return The balance of the token in the treasury.
    function getTreasuryTokenBalance(address asset) public view returns (uint256) {
        return IERC20(asset).balanceOf(address(this));
    }

    // --- Bonding Functions ---

    /// @notice Initiates a bond by depositing a reserve asset. Requires prior approval.
    /// @param asset The address of the reserve token being bonded.
    /// @param amount The amount of the reserve token to bond.
    function createBond(address asset, uint256 amount) external whenNotPaused nonReentrant {
        BondTerms storage terms = bondTerms[asset];
        require(isReserveAsset[asset], "Asset is not bondable");
        require(terms.vestingPeriod > 0, "Bonding not active for this asset");
        require(amount >= terms.minBondAmount, "Amount below minimum bond");
        require(terms.currentCapacityUsed.add(amount) <= terms.totalCapacity, "Bond capacity exceeded");

        UserBond storage userBond = userBonds[msg.sender][asset];
        require(userBond.amount == 0, "User already has an active bond for this asset"); // Simple: one bond per asset per user

        // Transfer asset to treasury
        IERC20 token = IERC20(asset);
        token.safeTransferFrom(msg.sender, address(this), amount);

        // Calculate payout FRC based on current terms
        uint256 assetDecimals = IERC20(asset).decimals();
        uint256 frcDecimals = decimals(); // FRC decimals
        uint256 scaledAmount = amount; // Assume 18 decimals for calculation for simplicity, adjust if needed

        // Adjust scaled amount based on decimals difference for calculation
        if (assetDecimals > frcDecimals) {
             scaledAmount = scaledAmount / (10**(assetDecimals - frcDecimals));
        } else if (assetDecimals < frcDecimals) {
             scaledAmount = scaledAmount * (10**(frcDecimals - assetDecimals));
        }
         // Note: This is a simplified payout calculation. Real systems use oracles/TWAPs.
         // Here we assume a 1:1 'base' value comparison for simplicity, modified by discount.
         // A proper implementation needs reliable pricing feeds.
         uint256 basePayout = scaledAmount; // Simplified: 1 unit of asset = 1 unit FRC value before discount
         uint256 discountedPayout = basePayout.mul(10000 - terms.discountBps) / 10000;
         uint256 payoutFRC = discountedPayout; // FRC amount to mint

        userBond.amount = amount;
        userBond.startTimestamp = block.timestamp;
        userBond.payoutFRC = payoutFRC;
        userBond.claimedAmount = 0;

        bondTerms[asset].currentCapacityUsed = terms.currentCapacityUsed.add(amount);

        emit BondCreated(msg.sender, asset, amount, payoutFRC);
    }

    /// @notice Claims vested FRC from an active bond.
    /// @param asset The address of the reserve token used for the bond.
    function claimBond(address asset) external whenNotPaused nonReentrant {
        UserBond storage userBond = userBonds[msg.sender][asset];
        BondTerms storage terms = bondTerms[asset];
        require(userBond.amount > 0, "No active bond for this asset");
        require(terms.vestingPeriod > 0, "Bonding is not active or has ended");

        uint256 totalPayout = userBond.payoutFRC;
        uint256 claimedAmount = userBond.claimedAmount;
        uint256 vestedAmount = calculateBondVestedAmount(msg.sender, asset);
        uint256 claimableAmount = vestedAmount.sub(claimedAmount);

        require(claimableAmount > 0, "No vested amount to claim");

        // Mint FRC and transfer to user
        _mint(msg.sender, claimableAmount);

        userBond.claimedAmount = claimedAmount.add(claimableAmount);

        // If fully vested and claimed, reset bond
        if (userBond.claimedAmount >= totalPayout) {
             bondTerms[asset].currentCapacityUsed = bondTerms[asset].currentCapacityUsed.sub(userBond.amount); // Reduce usage
             delete userBonds[msg.sender][asset];
             emit BondClaimed(msg.sender, asset, claimableAmount, 0);
        } else {
             emit BondClaimed(msg.sender, asset, claimableAmount, totalPayout.sub(userBond.claimedAmount));
        }
    }

     /// @notice Calculates the amount of FRC vested for a specific bond.
    /// @param user The address of the user.
    /// @param asset The address of the reserve token.
    /// @return The total vested FRC amount.
    function calculateBondVestedAmount(address user, address asset) public view returns (uint256) {
        UserBond storage userBond = userBonds[user][asset];
        BondTerms storage terms = bondTerms[asset];

        if (userBond.amount == 0 || terms.vestingPeriod == 0) {
            return 0;
        }

        uint256 elapsed = block.timestamp.sub(userBond.startTimestamp);
        if (elapsed >= terms.vestingPeriod) {
            return userBond.payoutFRC; // Fully vested
        } else {
            return userBond.payoutFRC.mul(elapsed) / terms.vestingPeriod;
        }
    }

    /// @notice Calculates the estimated FRC payout for bonding a given amount of asset.
    /// @param asset The address of the reserve token.
    /// @param amount The amount of the reserve token to bond.
    /// @return Estimated FRC payout.
    /// @dev This is a theoretical calculation based on current terms, actual payout might vary slightly due to capacity limits.
    function calculateBondPayout(address asset, uint256 amount) public view returns (uint256) {
        BondTerms storage terms = bondTerms[asset];
        require(isReserveAsset[asset], "Asset is not bondable");
        require(terms.vestingPeriod > 0, "Bonding not active for this asset");

        uint256 assetDecimals = IERC20(asset).decimals();
        uint256 frcDecimals = decimals(); // FRC decimals
        uint256 scaledAmount = amount;

        if (assetDecimals > frcDecimals) {
             scaledAmount = scaledAmount / (10**(assetDecimals - frcDecimals));
        } else if (assetDecimals < frcDecimals) {
             scaledAmount = scaledAmount * (10**(frcDecimals - assetDecimals));
        }

        uint256 basePayout = scaledAmount; // Simplified base value
        uint256 discountedPayout = basePayout.mul(10000 - terms.discountBps) / 10000;

        return discountedPayout;
    }

    // --- Staking Functions ---

    /// @notice Updates the global staking state and a user's staking state.
    /// @param user Address of the user (optional, updates global if address(0)).
    function updateStakingRewards() internal {
        uint256 timeElapsed = block.timestamp.sub(lastRewardUpdateTime);
        if (timeElapsed > 0 && totalStakedFRC > 0 && rewardRatePerFRCPerSecond > 0) {
            uint256 reward = totalStakedFRC.mul(rewardRatePerFRCPerSecond).mul(timeElapsed);
            // Potential FRC minting for rewards - cap this or ensure treasury backing?
            // For simplicity here, we mint. A real system needs a more robust reward source/limit.
            _mint(address(this), reward); // Mint to the contract, then distribute
            rewardPerTokenStored = rewardPerTokenStored.add(reward.mul(1e18) / totalStakedFRC); // Use 1e18 for high precision
        }
        lastRewardUpdateTime = block.timestamp;
    }

    /// @notice Calculates the pending staking rewards for a user.
    /// @param user The address of the user.
    /// @return The amount of pending FRC rewards.
    function calculateStakingRewards(address user) public view returns (uint256) {
        UserStake storage userStake = userStakes[user];
        uint256 currentRewardPerToken = rewardPerTokenStored;
        if (totalStakedFRC > 0) {
            uint256 timeElapsed = block.timestamp.sub(lastRewardUpdateTime);
             uint256 pendingReward = totalStakedFRC.mul(rewardRatePerFRCPerSecond).mul(timeElapsed);
             currentRewardPerToken = currentRewardPerToken.add(pendingReward.mul(1e18) / totalStakedFRC);
        }
        return userStake.amount.mul(currentRewardPerToken.sub(userStake.rewardPerTokenPaid)) / 1e18;
    }

    /// @notice Stakes FRC tokens. Requires prior approval.
    /// @param amount The amount of FRC to stake.
    function stake(uint256 amount) external whenNotPaused nonReentrant {
        require(amount > 0, "Amount must be greater than 0");
        updateStakingRewards(); // Update rewards before staking

        UserStake storage userStake = userStakes[msg.sender];
        uint256 pending = calculateStakingRewards(msg.sender);

        // Add pending rewards to user's stake before updating state (acts like auto-compounding)
        if (pending > 0) {
             userStake.amount = userStake.amount.add(pending);
             _mint(msg.sender, pending); // Mint rewards directly to user's wallet before they stake
             // Update rewardPaid to reflect claimed rewards
             userStake.rewardPerTokenPaid = rewardPerTokenStored; // User claims up to this point implicitly
             emit StakingRewardsClaimed(msg.sender, pending);
        }

        // Transfer FRC to the contract (staking pool)
        IERC20(address(this)).safeTransferFrom(msg.sender, address(this), amount);

        userStake.amount = userStake.amount.add(amount);
        userStake.rewardPerTokenPaid = rewardPerTokenStored;
        userStake.lastStakeUpdateTime = block.timestamp;
        totalStakedFRC = totalStakedFRC.add(amount);

        emit Staked(msg.sender, amount);
    }

    /// @notice Unstakes FRC tokens.
    /// @param amount The amount of FRC to unstake.
    function unstake(uint256 amount) external whenNotPaused nonReentrant {
        require(amount > 0, "Amount must be greater than 0");
        UserStake storage userStake = userStakes[msg.sender];
        require(userStake.amount >= amount, "Insufficient staked amount");

        updateStakingRewards(); // Update rewards before unstaking

         uint256 pending = calculateStakingRewards(msg.sender);

        // Add pending rewards to user's stake before unstaking
        if (pending > 0) {
             userStake.amount = userStake.amount.add(pending);
             _mint(msg.sender, pending); // Mint rewards directly to user's wallet
             userStake.rewardPerTokenPaid = rewardPerTokenStored; // User claims up to this point implicitly
             emit StakingRewardsClaimed(msg.sender, pending);
        }

        // Transfer FRC back to user
        IERC20(address(this)).safeTransfer(msg.sender, amount);

        userStake.amount = userStake.amount.sub(amount);
        userStake.rewardPerTokenPaid = rewardPerTokenStored; // Recalculate debt based on new stake
        userStake.lastStakeUpdateTime = block.timestamp;
        totalStakedFRC = totalStakedFRC.sub(amount);

        emit Unstaked(msg.sender, amount);
    }

     /// @notice Claims accumulated staking rewards.
    function claimStakingRewards() external whenNotPaused nonReentrant {
         updateStakingRewards(); // Update rewards before claiming
         UserStake storage userStake = userStakes[msg.sender];
         uint256 pending = calculateStakingRewards(msg.sender); // Should be 0 after updateStakingRewards if called immediately

        require(pending > 0, "No rewards to claim");

         // Mint rewards directly to user's wallet
         _mint(msg.sender, pending);
         userStake.rewardPerTokenPaid = rewardPerTokenStored; // Update debt

         emit StakingRewardsClaimed(msg.sender, pending);
    }

    /// @notice Gets the staking information for a user.
    /// @param user The address of the user.
    /// @return stakedAmount The amount of FRC staked.
    /// @return pendingRewards The amount of pending FRC rewards.
    function getUserStake(address user) public view returns (uint256 stakedAmount, uint256 pendingRewards) {
        UserStake storage userStake = userStakes[user];
        return (userStake.amount, calculateStakingRewards(user));
    }


    // --- Fractal Index (FRI) Functions ---

    /// @notice Internal function to mint FRI tokens.
    function _mintFRI(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: mint to the zero address");
        _totalSupplyFRI = _totalSupplyFRI.add(amount);
        _balancesFRI[account] = _balancesFRI[account].add(amount);
        // No standard ERC20 Mint event for custom token, could add custom one
    }

    /// @notice Internal function to burn FRI tokens.
    function _burnFRI(address account, uint256 amount) internal {
         require(account != address(0), "ERC20: burn from the zero address");
        uint256 accountBalance = _balancesFRI[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        _balancesFRI[account] = accountBalance.sub(amount);
        _totalSupplyFRI = _totalSupplyFRI.sub(amount);
         // No standard ERC20 Burn event for custom token, could add custom one
    }

    /// @notice Gets the FRI balance of an address.
    function balanceOfFRI(address account) public view returns (uint256) {
        return _balancesFRI[account];
    }

     /// @notice Gets the total supply of FRI tokens.
    function totalSupplyFRI() public view returns (uint256) {
        return _totalSupplyFRI;
    }

    /// @notice Mints FRI tokens by depositing required reserve assets. Requires prior approvals.
    /// @param amountFRI The amount of FRI to mint.
    /// @param maxAmountsIn Max amount of each asset the user is willing to deposit (slippage control).
    /// @dev Input assets and amounts must match the current index composition and totalIndexWeight.
    /// The user needs to approve *each* required asset for the contract BEFORE calling this function.
    function mintIndex(uint256 amountFRI, uint256[] calldata maxAmountsIn) external whenNotPaused nonReentrant {
        require(amountFRI > 0, "Amount must be greater than 0");
        require(totalIndexWeight > 0, "Index composition not set");
        require(reserveAssetsList.length <= maxAmountsIn.length, "Max amounts array too short"); // Should be at least enough for all defined assets

        address[] memory assetsToDeposit = new address[](reserveAssetsList.length);
        uint256[] memory requiredAmounts = new uint256[](reserveAssetsList.length);
        uint256[] memory actualAmountsDeposited = new uint256[](reserveAssetsList.length);

        uint assetCount = 0;
        for (uint i = 0; i < reserveAssetsList.length; i++) {
            address asset = reserveAssetsList[i];
            uint256 weight = indexCompositionWeights[asset];
            if (weight > 0) {
                // Calculate required amount for this asset
                 uint256 required = amountFRI.mul(weight) / totalIndexWeight; // Scale by weight and total weight
                 requiredAmounts[assetCount] = required;
                 assetsToDeposit[assetCount] = asset;

                 // Transfer asset from user to treasury
                 require(maxAmountsIn[i] >= required, "Slippage/Max amount exceeded for asset");
                 IERC20 token = IERC20(asset);
                 token.safeTransferFrom(msg.sender, address(this), required);
                 actualAmountsDeposited[assetCount] = required; // In this simple model, actual = required

                 assetCount++; // Increment if asset is part of composition
            }
        }

        // Adjust dynamic arrays to actual size
        assembly {
            mstore(assetsToDeposit, assetCount)
            mstore(requiredAmounts, assetCount)
             mstore(actualAmountsDeposited, assetCount)
        }

        // Mint FRI to the user
        _mintFRI(msg.sender, amountFRI);

        emit IndexMinted(msg.sender, amountFRI, actualAmountsDeposited);
    }

    /// @notice Redeems FRI tokens for the underlying reserve assets.
    /// @param amountFRI The amount of FRI to burn.
    /// @param minAmountsOut Minimum amount of each asset the user expects to receive (slippage control).
    /// @dev Output assets and amounts are based on the current index composition and *treasury balances*.
    function redeemIndex(uint256 amountFRI, uint256[] calldata minAmountsOut) external whenNotPaused nonReentrant {
        require(amountFRI > 0, "Amount must be greater than 0");
        require(balanceOfFRI(msg.sender) >= amountFRI, "Insufficient FRI balance");
        require(totalIndexWeight > 0, "Index composition not set");
        require(reserveAssetsList.length <= minAmountsOut.length, "Min amounts array too short");

        _burnFRI(msg.sender, amountFRI); // Burn FRI first

        address[] memory assetsToReceive = new address[](reserveAssetsList.length);
        uint256[] memory expectedAmounts = new uint256[](reserveAssetsList.length);
        uint256[] memory actualAmountsReceived = new uint256[](reserveAssetsList.length);

        uint assetCount = 0;
         for (uint i = 0; i < reserveAssetsList.length; i++) {
            address asset = reserveAssetsList[i];
            uint256 weight = indexCompositionWeights[asset];
            if (weight > 0) {
                 // Calculate proportional share based on treasury balance *and* index weight
                 // This makes redemption dynamic based on actual treasury composition and target weights
                 uint256 treasuryBalance = getTreasuryTokenBalance(asset);
                 // The amount received is proportional to (amountFRI / totalFRISupply) * treasuryBalance * (assetWeight / totalIndexWeight)?
                 // No, that's complex. Simplest is: amount Received = (amountFRI * target_proportion * total_treasury_value) / total_FRI_supply.
                 // Or, even simpler: amountReceived = (amountFRI / TotalFRISupply) * Treasury[asset].balance. This ignores target weights.
                 // Let's make it based on TARGET weight relative to treasury balance.
                 // Receive amount is (amountFRI * weight / totalIndexWeight) * (Treasury[asset].balance / equivalent_value_of_FRC) ? Still too complex.
                 // Simplest: AmountReceived = (AmountFRI / TotalFRIFRI) * TotalTreasuryValue_in_Asset_Units? No.
                 // Let's assume the *target* composition is used for mint/redeem, but capped by treasury balance.
                 // AmountReceived = min( Treasury[asset].balance,  amountFRI * weight / totalIndexWeight * VALUE_FACTOR )
                 // A simpler model: AmountReceived = min(Treasury[asset].balance, amountFRI * (Treasury[asset].balance / TotalFRISupply) ) - This is not target weight.
                 // Let's use target weights for calculation, but cap by actual balance:
                 // AmountReceived = (amountFRI * weight / totalIndexWeight) * BaseAssetAmountPerFRI
                 // How to get BaseAssetAmountPerFRI? Total Treasury Value / Total FRI Supply. Requires Oracle.
                 // Let's simulate the value calculation based on a hypothetical 'base unit' for each asset and FRI.
                 // Value of 1 FRI = Sum (weight_i * Value(asset_i)) / TotalIndexWeight. Minting requires this value basket.
                 // Redeeming gives back this value basket.
                 // Required input for mint = amountFRI * (weight_i / totalIndexWeight) * BaseValueRatio?
                 // Okay, let's simplify: Minting N FRI requires N units of asset i for each weight[i]. Total units needed = Sum(N * weight[i]). No, weights are fractions.
                 // Correct approach: Minting `amountFRI` FRI requires depositing assets such that their *value* equals `amountFRI` * `ValuePerFRI`.
                 // ValuePerFRI = Total Treasury Value / Total FRI Supply. Needs oracle.
                 // Let's simplify again: Minting `amountFRI` FRI requires depositing `amountFRI` * `weight[i]` / `totalIndexWeight` units of asset `i` * SCALING_FACTOR.
                 // Let's assume 1 FRI conceptually represents Total Treasury Value / Total FRI Supply.
                 // To redeem `amountFRI`, you get `amountFRI` * (Treasury[asset].balance / TotalFRI.totalSupply) units of *each* asset *with weight > 0*.
                 // This is simple proportionality. It *doesn't* enforce the target weights, it just gives a slice of the *current* treasury.
                 // Let's do that simpler proportionality, as it doesn't require oracles directly, just current balances and supplies.

                // Amount of this asset to receive = (amountFRI / total FRI supply) * current treasury balance of this asset
                // Handle division by zero if total FRI supply is 0
                uint256 amountToReceive = 0;
                if (_totalSupplyFRI > 0) {
                     amountToReceive = amountFRI.mul(treasuryBalance) / _totalSupplyFRI;
                }

                 expectedAmounts[assetCount] = amountToReceive;
                 assetsToReceive[assetCount] = asset;

                 // Transfer asset from treasury to user
                 require(getTreasuryTokenBalance(asset) >= amountToReceive, "Insufficient treasury balance for redemption"); // Should not happen if calculation is correct relative to total supply
                 require(minAmountsOut[i] <= amountToReceive, "Slippage/Min amount not met for asset");

                 IERC20 token = IERC20(asset);
                 token.safeTransfer(msg.sender, amountToReceive);
                 actualAmountsReceived[assetCount] = amountToReceive;

                 assetCount++;
            }
        }

         // Adjust dynamic arrays to actual size
        assembly {
            mstore(assetsToReceive, assetCount)
            mstore(expectedAmounts, assetCount)
             mstore(actualAmountsReceived, assetCount)
        }

        emit IndexRedeemed(msg.sender, amountFRI, actualAmountsReceived);
    }


    /// @notice Calculates the required amounts of assets to deposit for minting a given amount of FRI.
    /// @param amountFRI The amount of FRI to mint.
    /// @return assets Array of asset addresses.
    /// @return requiredAmounts Array of required amounts for each asset.
    /// @dev Based on current target index composition.
    function calculateIndexMintAmounts(uint256 amountFRI) public view returns (address[] memory assets, uint256[] memory requiredAmounts) {
        require(totalIndexWeight > 0, "Index composition not set");

        uint assetCount = 0;
        for (uint i = 0; i < reserveAssetsList.length; i++) {
            if (indexCompositionWeights[reserveAssetsList[i]] > 0) {
                assetCount++;
            }
        }

        assets = new address[](assetCount);
        requiredAmounts = new uint256[](assetCount);

        uint currentAssetIndex = 0;
        for (uint i = 0; i < reserveAssetsList.length; i++) {
             address asset = reserveAssetsList[i];
            uint256 weight = indexCompositionWeights[asset];
            if (weight > 0) {
                // Amount needed = (amountFRI * weight / totalIndexWeight) * SCALING_FACTOR?
                // Let's assume 1 FRI corresponds to 1 unit of total weight value * initial scaling factor.
                // Required = amountFRI * weight / totalIndexWeight * InitialFRIValuePerWeightUnit
                // Simplification: Just use the weights as direct proportions * unit amount.
                // To mint N FRI, need (N * weight[i] / totalIndexWeight) * ArbitraryUnitPerFRI
                // Let's assume the 'ArbitraryUnitPerFRI' is 1e18 for simplicity (like decimals).
                // Required = amountFRI * weight[i] / totalIndexWeight * 1e18 / (10**assetDecimals)?
                 // Need to handle decimals. Let's assume all calculations are done in 18 decimals, then scale.
                 uint256 frcDecimals = decimals(); // Assuming FRI has same decimals
                 uint256 scaledAmountFRI = amountFRI; // Already in 18 decimals
                 uint256 assetDecimals = IERC20(asset).decimals();

                 uint256 requiredAmountScaled = scaledAmountFRI.mul(weight) / totalIndexWeight; // Amount in 18 decimals equivalent

                 // Scale back to asset decimals
                 uint256 requiredAmount = requiredAmountScaled;
                 if (frcDecimals > assetDecimals) {
                     requiredAmount = requiredAmount / (10**(frcDecimals - assetDecimals));
                 } else if (frcDecimals < assetDecimals) {
                     requiredAmount = requiredAmount * (10**(assetDecimals - frcDecimals));
                 }

                assets[currentAssetIndex] = asset;
                requiredAmounts[currentAssetIndex] = requiredAmount;
                currentAssetIndex++;
            }
        }
        return (assets, requiredAmounts);
    }

     /// @notice Calculates the amounts of assets received when redeeming a given amount of FRI.
    /// @param amountFRI The amount of FRI to redeem.
    /// @return assets Array of asset addresses.
    /// @return amountsReceived Array of amounts received for each asset.
    /// @dev Based on current *treasury balances* and total FRI supply.
    function calculateIndexRedeemAmounts(uint256 amountFRI) public view returns (address[] memory assets, uint256[] memory amountsReceived) {
         require(_totalSupplyFRI > 0, "Total FRI supply is zero"); // Cannot redeem if no FRI exists

         uint assetCount = 0;
        for (uint i = 0; i < reserveAssetsList.length; i++) {
            // Include all assets in the treasury for proportional redemption, regardless of current index weight
            if (getTreasuryTokenBalance(reserveAssetsList[i]) > 0) { // Only include assets actually in treasury
                 assetCount++;
            }
        }

        assets = new address[](assetCount);
        amountsReceived = new uint256[](assetCount);

         uint currentAssetIndex = 0;
        for (uint i = 0; i < reserveAssetsList.length; i++) {
             address asset = reserveAssetsList[i];
             uint256 treasuryBalance = getTreasuryTokenBalance(asset);
             if (treasuryBalance > 0) {
                 // Amount to receive = (amountFRI / total FRI supply) * current treasury balance of this asset
                 uint256 amount = amountFRI.mul(treasuryBalance) / _totalSupplyFRI;

                 assets[currentAssetIndex] = asset;
                 amountsReceived[currentAssetIndex] = amount;
                 currentAssetIndex++;
             }
        }
        return (assets, amountsReceived);
    }

    // --- Utility & View Functions ---

     /// @notice Gets the current list of approved reserve assets.
    function getReserveAssets() public view returns (address[] memory) {
        uint count = 0;
        for (uint i = 0; i < reserveAssetsList.length; i++) {
            if (isReserveAsset[reserveAssetsList[i]]) {
                count++;
            }
        }
        address[] memory activeAssets = new address[](count);
        uint activeIndex = 0;
        for (uint i = 0; i < reserveAssetsList.length; i++) {
            if (isReserveAsset[reserveAssetsList[i]]) {
                activeAssets[activeIndex] = reserveAssetsList[i];
                activeIndex++;
            }
        }
        return activeAssets;
    }

    /// @notice Gets the bond terms for a specific asset.
    function getBondTerms(address asset) public view returns (uint256 discountBps, uint256 vestingPeriod, uint256 totalCapacity, uint256 currentCapacityUsed, uint256 minBondAmount) {
        BondTerms storage terms = bondTerms[asset];
        return (terms.discountBps, terms.vestingPeriod, terms.totalCapacity, terms.currentCapacityUsed, terms.minBondAmount);
    }

    /// @notice Gets the bond information for a user and asset.
    function getUserBond(address user, address asset) public view returns (uint256 amount, uint256 startTimestamp, uint256 payoutFRC, uint256 claimedAmount, uint256 vestedAmount, uint256 claimableAmount) {
         UserBond storage userBond = userBonds[user][asset];
         uint256 currentVested = calculateBondVestedAmount(user, asset);
         return (
             userBond.amount,
             userBond.startTimestamp,
             userBond.payoutFRC,
             userBond.claimedAmount,
             currentVested,
             currentVested.sub(userBond.claimedAmount)
         );
    }

    // --- Oracle Dependent Views (Conceptual) ---
    // These functions require a separate oracle contract to provide reliable asset prices.
    // Implementation details of oracle interaction are omitted for brevity but are crucial in reality.

    /// @notice Calculates the total value of the treasury in a common base currency (e.g., USD or ETH).
    /// @dev Requires a price oracle for each reserve asset. Returns 0 if no oracle is integrated or prices are unavailable.
    function getTreasuryValue() public view returns (uint256) {
        uint256 totalValue = 0;
        // Placeholder: In a real contract, iterate through reserveAssetsList,
        // get balance of each asset in treasury, query oracle for asset price,
        // multiply balance by price, sum up.
        // Example (pseudocode):
        // for asset in reserveAssetsList:
        //   if isReserveAsset[asset]:
        //     balance = getTreasuryTokenBalance(asset)
        //     price = oracle.getPrice(asset) // Requires oracle interaction
        //     totalValue += balance * price / price_scale // handle decimals and scales
        return totalValue; // Returns 0 in this conceptual placeholder
    }

     /// @notice Calculates the implied value of 1 FRC based on treasury backing.
    /// @dev Requires getTreasuryValue to be functional. Returns 0 if total supply is 0 or treasury value is 0.
    function getFRCPrice() public view returns (uint256) {
        uint256 supply = totalSupply();
        if (supply == 0) {
            return 0;
        }
        uint256 treasuryValue = getTreasuryValue(); // In base currency (e.g., USD)
        // Implied price = total treasury value / total FRC supply
        // Need to handle decimals carefully depending on base currency and FRC decimals
        // Example (pseudocode assuming treasuryValue is scaled to 18 decimals base unit):
        // return treasuryValue.mul(1e18) / supply; // Scale FRC supply to 18 decimals if needed
        return 0; // Returns 0 in this conceptual placeholder
    }

    /// @notice Calculates the implied value of 1 FRI based on its proportional claim on treasury assets.
    /// @dev Requires getTreasuryValue and total FRI supply. Returns 0 if total FRI supply is 0 or treasury value is 0.
    function getFRIPrice() public view returns (uint256) {
        uint256 friSupply = totalSupplyFRI();
        if (friSupply == 0) {
            return 0;
        }
        uint256 treasuryValue = getTreasuryValue(); // In base currency (e.g., USD)
        // Implied price = total treasury value / total FRI supply
        // Need to handle decimals carefully depending on base currency and FRI decimals
        // Example (pseudocode assuming treasuryValue is scaled to 18 decimals base unit):
        // return treasuryValue.mul(1e18) / friSupply; // Scale FRI supply to 18 decimals if needed
        return 0; // Returns 0 in this conceptual placeholder
    }

    // --- Overrides for Pausable ---
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal override whenNotPaused {
        super._beforeTokenTransfer(from, to, amount);
    }

    // Note: Pausable only affects ERC20 transfers by default.
    // We use `whenNotPaused` modifier on state-changing functions to control other operations.

    // --- ERC20 Overrides (Optional, can rely on OpenZeppelin base) ---
    // function transfer(address to, uint256 amount) public virtual override returns (bool) { ... }
    // function transferFrom(address from, address to, uint256 amount) public virtual override returns (bool) { ... }
    // etc.
    // The inherited implementations are fine, just ensure Pausable is applied via _beforeTokenTransfer.
    // Custom logic would go here if needed for special FRC transfer rules.

    // --- ERC20-like Functions for FRI (Internal state management) ---
    // balanceOfFRI and totalSupplyFRI already added above.
    // No transfer/approve/allowance for FRI in this simplified model, it's managed by contract functions only.
}
```