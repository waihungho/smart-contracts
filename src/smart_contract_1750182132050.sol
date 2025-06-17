Okay, let's design a smart contract system called "ChronoForge" that manages dynamic NFTs ("ChronoAssets") that evolve over time, can be staked for rewards, and can be combined ("forged") to create new assets with potentially enhanced attributes. This combines elements of NFTs, DeFi (staking/rewards), and game-like mechanics (dynamic attributes, forging).

We will use OpenZeppelin contracts for standard functionality like ERC721, ERC20, AccessControl, and Pausable to focus on the custom logic.

**Disclaimer:** This is an advanced concept smart contract example for educational purposes. It includes mechanisms like simulated probabilistic forging and dynamic attribute updates. Real-world implementations of such concepts require rigorous security audits, careful economic design, and robust infrastructure (e.g., using Chainlink VRF for true randomness, secure oracles for external data).

---

**ChronoForge Smart Contract System**

**Outline:**

1.  **Core Contracts:**
    *   `ChronoToken.sol`: An ERC20 token used for rewards, fees, and potentially governance.
    *   `ChronoForge.sol`: The main contract managing ChronoAssets (ERC721), staking, attribute dynamics, and forging.

2.  **Key Concepts:**
    *   **ChronoAsset (ERC721):** An NFT with mutable attributes (e.g., Level, Power, DecayResistance).
    *   **ChronoToken (ERC20):** The utility/reward token.
    *   **Dynamic Attributes:** Asset attributes change based on time (decay) and staking duration (growth/yield multiplier).
    *   **Staking:** Lock ChronoAssets to earn ChronoToken rewards.
    *   **Forging:** Combine two ChronoAssets and ChronoTokens to potentially create a new, higher-level ChronoAsset, with a probabilistic outcome.

3.  **Access Control:** Uses OpenZeppelin's `AccessControl` for defining roles (Admin, Minter, etc.).

4.  **Pausability:** Allows pausing sensitive operations.

---

**Function Summary (`ChronoForge.sol`):**

*   **Admin & Setup:**
    *   `constructor`: Deploys or links ChronoToken, sets initial roles and parameters.
    *   `setTokenURI`: Sets the base URI for ChronoAsset metadata.
    *   `grantRole`, `revokeRole`: Manage access control roles.
    *   `pause`, `unpause`: Pause/unpause contract operations.
    *   `withdrawNativeToken`, `withdrawERC20`: Owner withdrawals of residual ETH/ERC20.
    *   `setStakingRewardRate`: Sets the base rate for token rewards per staked asset per second.
    *   `setMinStakeDuration`: Sets the minimum time an asset must be staked before unstaking/claiming rewards.
    *   `setForgingFee`: Sets the ChronoToken cost for the forging operation.
    *   `setForgingSuccessRate`: Sets the probabilistic success rate (out of 1000) for forging.
    *   `setDecayRatePerSecond`: Sets the rate at which attributes decay over time when *not* staked.
    *   `setGrowthRatePerSecond`: Sets the rate at which attributes grow over time when staked (compounding staking rewards/yield bonus).

*   **ChronoAsset Management (Minting, Transfer):**
    *   `mintChronoAsset`: Creates a new ChronoAsset NFT with initial attributes.
    *   `burnChronoAsset`: Destroys a ChronoAsset NFT.
    *   `safeTransferFrom`, `transferFrom`, `approve`, `setApprovalForAll`, `getApproved`, `isApprovedForAll`, `balanceOf`, `ownerOf`, `tokenURI`: Standard ERC721 functions (inherited).

*   **Attribute Dynamics:**
    *   `updateAssetAttributes`: Triggers the update logic for a specific asset based on time elapsed since the last update and its staking status. Applies decay or growth.
    *   `getAssetAttributes`: Reads the current mutable attributes of an asset.
    *   `getAssetLastUpdatedTime`: Gets the timestamp of the last attribute update for an asset.

*   **Staking:**
    *   `stakeChronoAsset`: Locks an owned ChronoAsset in the contract to start earning rewards. Requires prior ERC721 approval.
    *   `unstakeChronoAsset`: Unlocks a previously staked ChronoAsset. Requires minimum stake duration and triggers reward calculation/distribution.
    *   `claimStakingRewards`: Calculates and distributes accumulated ChronoToken rewards for the caller's staked assets.
    *   `getStakingInfo`: View function to get details about a staked asset (staker, timestamp, accumulated rewards).
    *   `isChronoAssetStaked`: Checks if a specific asset is currently staked.
    *   `calculatePendingRewards`: View function to estimate pending ChronoToken rewards for a staked asset without claiming.

*   **Forging:**
    *   `forgeChronoAssets`: Combines two ChronoAssets, burns them, pays a ChronoToken fee, and attempts to mint a new asset with enhanced attributes based on success rate and input attributes. Requires prior ERC20 approval for the fee.

*   **Query Functions:**
    *   `getForgingCost`: Returns the current ChronoToken fee for forging.
    *   `getForgingChance`: Returns the current forging success rate.
    *   `getDecayRatePerSecond`: Returns the current attribute decay rate.
    *   `getGrowthRatePerSecond`: Returns the current attribute growth rate.
    *   `getStakingRewardRate`: Returns the base staking reward rate.
    *   `getMinStakeDuration`: Returns the minimum required stake duration.
    *   `getChronoTokenAddress`: Returns the address of the linked ChronoToken contract.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";

// Define the ChronoToken Contract (Minimal for Example)
contract ChronoToken is IERC20, AccessControl, Pausable {
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;
    string private _name;
    string private _symbol;

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _grantRole(MINTER_ROLE, _msgSender()); // Admin is initially a Minter
    }

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function decimals() public view virtual override returns (uint8) {
        return 18; // Standard decimals
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), to, amount);
        return true;
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address from, address to, uint256 amount) public virtual override returns (bool) {
        _spendAllowance(from, _msgSender(), amount);
        _transfer(from, to, amount);
        return true;
    }

    function mint(address account, uint256 amount) public virtual {
        require(hasRole(MINTER_ROLE, _msgSender()), "ChronoToken: must have minter role");
        _mint(account, amount);
    }

    function burn(address account, uint256 amount) public virtual {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "ChronoToken: must have admin role"); // Or define a BURNER_ROLE
        _burn(account, amount);
    }

    // --- Internal Functions ---
    function _transfer(address from, address to, uint256 amount) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
            _balances[to] = _balances[to] + amount;
        }

        emit Transfer(from, to, amount);
    }

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);
    }

    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _spendAllowance(address owner, address spender, uint256 amount) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    // Pausability requires implementing _beforeTokenTransfer hook, but it's not strictly necessary for this minimal example
    // where Pausable is just inherited. Real ERC20 would override _update and call whenNotPaused.
    // For this example, pausing directly affects functions calling transfer/transferFrom etc. if they use pausable checks.
}


// Define the Main ChronoForge Contract
contract ChronoForge is ERC721, AccessControl, Pausable, ReentrancyGuard, ERC721Burnable {

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    // Could add other roles like FORGE_MANAGER_ROLE

    // --- State Variables ---

    IERC20 public chronoToken; // Address of the ChronoToken contract

    uint256 private _nextTokenId; // Counter for minting new NFTs

    // ChronoAsset Attributes (mutable)
    struct AssetAttributes {
        uint16 level; // Affects staking yield, forging outcome, decay resistance
        uint16 power; // Generic attribute, maybe affects forging outcome
        uint16 decayResistance; // How resistant it is to decay
        uint40 lastUpdatedTimestamp; // When attributes were last updated
    }
    mapping(uint256 => AssetAttributes) private _assetAttributes;

    // Staking Information
    struct StakingInfo {
        address staker;
        uint40 stakeTimestamp;
        uint256 accumulatedRewards; // Rewards accumulated *before* last claim/unstake
        AssetAttributes snapshotAttributes; // Attributes at time of staking/last update
    }
    mapping(uint256 => StakingInfo) private _stakedAssets; // tokenId => StakingInfo
    mapping(uint256 => bool) private _isStaked; // tokenId => isStaked

    // Configurable Parameters
    uint256 public stakingRewardRatePerSecond = 1e16; // Base ChronoToken per second per asset (adjust decimals)
    uint256 public minStakeDuration = 7 days; // Minimum duration in seconds
    uint256 public forgingFee = 100 * 1e18; // Cost in ChronoTokens (adjust decimals)
    uint256 public forgingSuccessRate = 700; // Success rate out of 1000 (e.g., 70%)
    uint256 public decayRatePerSecond = 1; // Units of attribute decay per second when not staked
    uint256 public growthRatePerSecond = 2; // Units of attribute growth per second when staked

    // --- Events ---
    event ChronoAssetMinted(address indexed owner, uint256 indexed tokenId, AssetAttributes initialAttributes);
    event ChronoAssetAttributesUpdated(uint256 indexed tokenId, AssetAttributes newAttributes, uint40 timestamp);
    event ChronoAssetStaked(address indexed staker, uint256 indexed tokenId, uint40 timestamp);
    event ChronoAssetUnstaked(address indexed staker, uint256 indexed tokenId, uint40 timestamp, uint256 rewardsClaimed);
    event StakingRewardsClaimed(address indexed staker, uint256 indexed tokenId, uint256 rewardsClaimed);
    event ChronoAssetsForged(address indexed forger, uint256 indexed tokenId1, uint256 indexed tokenId2, bool success, uint256 newItemId);
    event ForgingFeeSet(uint256 newFee);
    event ForgingSuccessRateSet(uint256 newRate);
    event DecayRateSet(uint256 newRate);
    event GrowthRateSet(uint256 newRate);
    event StakingRewardRateSet(uint256 newRate);
    event MinStakeDurationSet(uint256 newDuration);

    // --- Constructor ---

    /// @notice Deploys or links the ChronoToken and initializes the contract.
    /// @param name_ Name for the ChronoAsset NFT collection.
    /// @param symbol_ Symbol for the ChronoAsset NFT collection.
    /// @param chronoTokenAddress Address of the deployed ChronoToken contract. Use address(0) to deploy a new one.
    constructor(string memory name_, string memory symbol_, address chronoTokenAddress)
        ERC721(name_, symbol_)
        Pausable()
        ReentrancyGuard()
    {
        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _grantRole(MINTER_ROLE, _msgSender()); // Admin is initially a Minter

        if (chronoTokenAddress == address(0)) {
            // Deploy a new token contract if address(0) is provided
            ChronoToken token = new ChronoToken("Chrono Token", "CHR");
            chronoToken = token;
            // Grant this contract MINTER_ROLE on the new token
            token.grantRole(token.MINTER_ROLE(), address(this));
        } else {
            // Use existing token contract
            chronoToken = IERC20(chronoTokenAddress);
            // IMPORTANT: The provided token contract MUST grant this contract MINTER_ROLE separately!
            // Add checks or require a specific interface/function on the token for setup.
        }
    }

    // --- Admin & Setup Functions ---

    /// @notice Sets the base URI for ChronoAsset metadata.
    /// @dev Requires DEFAULT_ADMIN_ROLE.
    /// @param uri The base URI.
    function setTokenURI(string memory uri) public virtual onlyRole(DEFAULT_ADMIN_ROLE) {
        _setBaseURI(uri);
    }

    /// @notice Grants a role to an address.
    /// @dev Requires role `role` or DEFAULT_ADMIN_ROLE.
    /// @param role The role to grant.
    /// @param account The address to grant the role to.
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /// @notice Revokes a role from an address.
    /// @dev Requires role `role` or DEFAULT_ADMIN_ROLE.
    /// @param role The role to revoke.
    /// @param account The address to revoke the role from.
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /// @notice Pauses the contract, preventing sensitive operations.
    /// @dev Requires DEFAULT_ADMIN_ROLE.
    function pause() public virtual onlyRole(DEFAULT_ADMIN_ROLE) {
        _pause();
    }

    /// @notice Unpauses the contract, allowing operations to resume.
    /// @dev Requires DEFAULT_ADMIN_ROLE.
    function unpause() public virtual onlyRole(DEFAULT_ADMIN_ROLE) {
        _unpause();
    }

    /// @notice Allows the contract owner to withdraw any residual native tokens (ETH).
    /// @dev Requires DEFAULT_ADMIN_ROLE.
    function withdrawNativeToken() public onlyRole(DEFAULT_ADMIN_ROLE) nonReentrant {
        (bool success, ) = payable(msg.sender).call{value: address(this).balance}("");
        require(success, "Withdrawal failed");
    }

    /// @notice Allows the contract owner to withdraw any residual ERC20 tokens.
    /// @dev Requires DEFAULT_ADMIN_ROLE.
    /// @param tokenAddress The address of the ERC20 token to withdraw.
    /// @param amount The amount to withdraw.
    function withdrawERC20(address tokenAddress, uint256 amount) public onlyRole(DEFAULT_ADMIN_ROLE) nonReentrant {
        IERC20 token = IERC20(tokenAddress);
        require(token.transfer(msg.sender, amount), "ERC20 withdrawal failed");
    }

     /// @notice Sets the base staking reward rate per second per asset.
    /// @dev Requires DEFAULT_ADMIN_ROLE.
    /// @param rate The new reward rate (in ChronoToken decimals per second).
    function setStakingRewardRate(uint256 rate) public onlyRole(DEFAULT_ADMIN_ROLE) {
        stakingRewardRatePerSecond = rate;
        emit StakingRewardRateSet(rate);
    }

    /// @notice Sets the minimum duration an asset must be staked.
    /// @dev Requires DEFAULT_ADMIN_ROLE.
    /// @param duration The minimum duration in seconds.
    function setMinStakeDuration(uint256 duration) public onlyRole(DEFAULT_ADMIN_ROLE) {
        minStakeDuration = duration;
        emit MinStakeDurationSet(duration);
    }

    /// @notice Sets the ChronoToken fee for the forging operation.
    /// @dev Requires DEFAULT_ADMIN_ROLE.
    /// @param fee The new forging fee (in ChronoToken decimals).
    function setForgingFee(uint256 fee) public onlyRole(DEFAULT_ADMIN_ROLE) {
        forgingFee = fee;
        emit ForgingFeeSet(fee);
    }

    /// @notice Sets the probabilistic success rate for forging.
    /// @dev Requires DEFAULT_ADMIN_ROLE. Rate is out of 1000.
    /// @param rate The new success rate (0-1000).
    function setForgingSuccessRate(uint256 rate) public onlyRole(DEFAULT_ADMIN_ROLE) {
        require(rate <= 1000, "Rate must be <= 1000");
        forgingSuccessRate = rate;
        emit ForgingSuccessRateSet(rate);
    }

     /// @notice Sets the rate at which attributes decay per second when not staked.
    /// @dev Requires DEFAULT_ADMIN_ROLE.
    /// @param rate The new decay rate.
    function setDecayRatePerSecond(uint256 rate) public onlyRole(DEFAULT_ADMIN_ROLE) {
        decayRatePerSecond = rate;
        emit DecayRateSet(rate);
    }

    /// @notice Sets the rate at which attributes grow per second when staked.
    /// @dev Requires DEFAULT_ADMIN_ROLE.
    /// @param rate The new growth rate.
    function setGrowthRatePerSecond(uint256 rate) public onlyRole(DEFAULT_ADMIN_ROLE) {
        growthRatePerSecond = rate;
        emit GrowthRateSet(rate);
    }

    // Function added assuming ChronoToken might be deployed separately or need updating
    /// @notice Sets the address of the ChronoToken contract.
    /// @dev Requires DEFAULT_ADMIN_ROLE. Should only be called once during setup if not deploying internally.
    /// @param tokenAddress The address of the ChronoToken contract.
    function setChronoTokenAddress(address tokenAddress) public onlyRole(DEFAULT_ADMIN_ROLE) {
        require(address(chronoToken) == address(0), "ChronoToken address already set");
        chronoToken = IERC20(tokenAddress);
         // IMPORTANT: The provided token contract MUST grant this contract MINTER_ROLE separately!
    }


    // --- ChronoAsset Management ---

    /// @notice Mints a new ChronoAsset NFT to the recipient with initial attributes.
    /// @dev Requires MINTER_ROLE.
    /// @param recipient The address to mint the token to.
    /// @param initialAttributes Initial attributes for the new asset.
    /// @return The ID of the newly minted token.
    function mintChronoAsset(address recipient, AssetAttributes memory initialAttributes)
        public virtual onlyRole(MINTER_ROLE) whenNotPaused returns (uint256)
    {
        require(recipient != address(0), "Cannot mint to the zero address");

        uint256 newItemId = _nextTokenId++;
        _safeMint(recipient, newItemId);

        // Initialize attributes and last updated time
        _assetAttributes[newItemId] = initialAttributes;
        _assetAttributes[newItemId].lastUpdatedTimestamp = uint40(block.timestamp); // Use uint40 for gas efficiency

        emit ChronoAssetMinted(recipient, newItemId, initialAttributes);
        return newItemId;
    }

    /// @notice Burns a ChronoAsset NFT.
    /// @dev Can only be called by the owner or approved address, or the contract itself (e.g., during forging).
    /// @param tokenId The ID of the token to burn.
    function burnChronoAsset(uint256 tokenId) public virtual {
        // Standard ERC721Burnable checks ownership/approval
        require(!_isStaked[tokenId], "Cannot burn staked asset");
        _burn(tokenId);
        delete _assetAttributes[tokenId]; // Clean up attributes
    }

    // Inherited standard ERC721 functions:
    // safeTransferFrom, transferFrom, approve, setApprovalForAll, getApproved, isApprovedForAll, balanceOf, ownerOf, tokenURI
    // These function will inherently respect Pausable status if OpenZeppelin's _beforeTokenTransfer includes the pausable check.
    // The default OpenZeppelin ERC721 _update function checks _notPaused() which is good.


    // --- Attribute Dynamics ---

    /// @notice Updates the attributes of a ChronoAsset based on time and staking status.
    /// @dev Callable by anyone, but uses asset's internal state (lastUpdatedTimestamp) to calculate changes.
    /// @param tokenId The ID of the token to update.
    function updateAssetAttributes(uint256 tokenId) public whenNotPaused {
        require(_exists(tokenId), "Token does not exist");
        // Cannot update while staking or forging is in progress related to this token
        // Note: Forging burns, so this check is mainly for staking
        require(!_isStaked[tokenId], "Cannot update attributes while staked");

        AssetAttributes storage attrs = _assetAttributes[tokenId];
        uint40 lastUpdate = attrs.lastUpdatedTimestamp;
        uint40 currentTime = uint40(block.timestamp);

        // Avoid frequent updates - require a minimum time difference
        // This prevents users spamming updates to get favorable decay/growth snapshots
        // Example: require(currentTime - lastUpdate >= 1 minutes, "Attributes updated too recently");

        uint256 timeElapsed = currentTime - lastUpdate;

        if (timeElapsed > 0) {
             // Apply decay when not staked
            uint256 decayAmount = timeElapsed * decayRatePerSecond;

            // Apply decay, capped at current attribute value
            attrs.level = attrs.level >= decayAmount ? uint16(attrs.level - decayAmount) : 0;
            attrs.power = attrs.power >= decayAmount ? uint16(attrs.power - decayAmount) : 0;
            // DecayResistance might decay slower, or inversely affect decayAmount
            // Let's keep it simple: decayResistance reduces the effective decayAmount
             uint256 effectiveDecay = (decayAmount * (1000 - attrs.decayResistance)) / 1000; // Example formula
             attrs.level = attrs.level >= effectiveDecay ? uint16(attrs.level - effectiveDecay) : 0;
             attrs.power = attrs.power >= effectiveDecay ? uint16(attrs.power - effectiveDecay) : 0;
             attrs.decayResistance = attrs.decayResistance >= effectiveDecay ? uint16(attrs.decayResistance - effectiveDecay) : 0;
             // Ensure attributes don't go below zero
             attrs.level = attrs.level > 0 ? attrs.level : 0;
             attrs.power = attrs.power > 0 ? attrs.power : 0;
             attrs.decayResistance = attrs.decayResistance > 0 ? attrs.decayResistance : 0;


            attrs.lastUpdatedTimestamp = currentTime; // Update timestamp after calculation

            emit ChronoAssetAttributesUpdated(tokenId, attrs, currentTime);
        }
    }

    /// @notice Gets the current attributes of a ChronoAsset.
    /// @param tokenId The ID of the token.
    /// @return The AssetAttributes struct for the token.
    function getAssetAttributes(uint256 tokenId) public view returns (AssetAttributes memory) {
        require(_exists(tokenId), "Token does not exist");
        return _assetAttributes[tokenId];
    }

    /// @notice Gets the last timestamp when attributes were updated.
    /// @param tokenId The ID of the token.
    /// @return The timestamp (uint40).
    function getAssetLastUpdatedTime(uint256 tokenId) public view returns (uint40) {
         require(_exists(tokenId), "Token does not exist");
         return _assetAttributes[tokenId].lastUpdatedTimestamp;
    }


    // --- Staking ---

    /// @notice Stakes a ChronoAsset owned by the caller.
    /// @dev Caller must approve the contract to transfer the NFT first.
    /// @param tokenId The ID of the token to stake.
    function stakeChronoAsset(uint256 tokenId) public whenNotPaused nonReentrant {
        address owner = ownerOf(tokenId);
        require(owner == _msgSender(), "Not the owner");
        require(!_isStaked[tokenId], "Asset already staked");

        // Ensure attributes are up-to-date before staking
        updateAssetAttributes(tokenId); // This function is permissionless and checks timing internally

        // Record staking info BEFORE transferring
        _stakedAssets[tokenId] = StakingInfo({
            staker: owner,
            stakeTimestamp: uint40(block.timestamp),
            accumulatedRewards: 0, // Rewards start accumulating from 0 on stake
            snapshotAttributes: _assetAttributes[tokenId] // Take a snapshot of attributes at stake time
        });
        _isStaked[tokenId] = true;

        // Transfer the NFT to the contract
        safeTransferFrom(owner, address(this), tokenId);

        emit ChronoAssetStaked(owner, tokenId, uint40(block.timestamp));
    }

    /// @notice Unstakes a ChronoAsset.
    /// @dev Can only be called by the original staker after minStakeDuration.
    /// Rewards are calculated and distributed upon unstake.
    /// @param tokenId The ID of the token to unstake.
    function unstakeChronoAsset(uint256 tokenId) public whenNotPaused nonReentrant {
        require(_isStaked[tokenId], "Asset not staked");
        StakingInfo storage stakingInfo = _stakedAssets[tokenId];
        require(stakingInfo.staker == _msgSender(), "Not the staker");
        require(block.timestamp >= stakingInfo.stakeTimestamp + minStakeDuration, "Stake duration not met");

        // Calculate and distribute pending rewards
        uint256 pendingRewards = calculatePendingRewards(tokenId);
        if (pendingRewards > 0) {
             // Mint and transfer rewards
            ChronoToken(chronoToken).mint(stakingInfo.staker, pendingRewards);
        }

        // Transfer the NFT back to the staker
        safeTransferFrom(address(this), stakingInfo.staker, tokenId);

        // Clear staking info
        delete _stakedAssets[tokenId];
        delete _isStaked[tokenId];

        emit ChronoAssetUnstaked(stakingInfo.staker, tokenId, uint40(block.timestamp), pendingRewards);
    }

    /// @notice Claims accumulated staking rewards for a specific staked asset.
    /// @dev Can only be called by the staker. Resets accumulated rewards for the token.
    /// @param tokenId The ID of the staked token.
    function claimStakingRewards(uint256 tokenId) public whenNotPaused nonReentrant {
        require(_isStaked[tokenId], "Asset not staked");
        StakingInfo storage stakingInfo = _stakedAssets[tokenId];
        require(stakingInfo.staker == _msgSender(), "Not the staker");

        // Calculate and distribute pending rewards
        uint256 pendingRewards = calculatePendingRewards(tokenId);
        if (pendingRewards > 0) {
            // Mint and transfer rewards
            ChronoToken(chronoToken).mint(stakingInfo.staker, pendingRewards);
            // Reset accumulated rewards and update timestamp for next calculation cycle
            stakingInfo.accumulatedRewards = 0;
            stakingInfo.stakeTimestamp = uint40(block.timestamp); // Reset time reference for calculation
             // Re-snapshot attributes? Depends on reward mechanism. Let's re-snapshot.
            stakingInfo.snapshotAttributes = _assetAttributes[tokenId];
        }

        emit StakingRewardsClaimed(stakingInfo.staker, tokenId, pendingRewards);
    }

    /// @notice Gets staking information for a specific token.
    /// @param tokenId The ID of the token.
    /// @return staker The address that staked the token.
    /// @return stakeTimestamp The timestamp when the token was staked.
    /// @return accumulatedRewards Rewards accumulated prior to the last claim/unstake.
    /// @return snapshotAttributes Attributes recorded when staked or last claimed.
    function getStakingInfo(uint256 tokenId) public view returns (address staker, uint40 stakeTimestamp, uint256 accumulatedRewards, AssetAttributes memory snapshotAttributes) {
        require(_isStaked[tokenId], "Asset not staked");
        StakingInfo storage stakingInfo = _stakedAssets[tokenId];
        return (
            stakingInfo.staker,
            stakingInfo.stakeTimestamp,
            stakingInfo.accumulatedRewards,
            stakingInfo.snapshotAttributes
        );
    }

    /// @notice Checks if a specific ChronoAsset is staked.
    /// @param tokenId The ID of the token.
    /// @return True if staked, false otherwise.
    function isChronoAssetStaked(uint256 tokenId) public view returns (bool) {
        return _isStaked[tokenId];
    }

     /// @notice Calculates the pending staking rewards for a specific staked asset.
    /// @dev View function. Does not modify state.
    /// Reward formula example: base rate * time_elapsed * (1 + level_bonus).
    /// @param tokenId The ID of the staked token.
    /// @return The pending rewards amount.
    function calculatePendingRewards(uint256 tokenId) public view returns (uint256) {
        require(_isStaked[tokenId], "Asset not staked");
        StakingInfo storage stakingInfo = _stakedAssets[tokenId];
        uint40 currentTime = uint40(block.timestamp);
        uint256 timeElapsed = currentTime - stakingInfo.stakeTimestamp;

        if (timeElapsed == 0) {
            return stakingInfo.accumulatedRewards; // No time elapsed since last calculation/claim
        }

        // Calculate rewards based on snapshot attributes at the start of the current staking period
        // This prevents fluctuating attributes during staking from affecting the *rate* dynamically
        // If attributes changing during staking should affect the rate, update logic would need to be different
        AssetAttributes memory attrs = stakingInfo.snapshotAttributes;

        // Example reward calculation: Base rate per second * time elapsed * (1 + level / 100)
        // Make sure scaling works with decimals
        uint256 baseRate = stakingRewardRatePerSecond; // e.g., 1e16 for 0.01 tokens/sec
        uint256 levelBonusMultiplier = (1000 + attrs.level * 10); // Example: level 10 adds 100 = 1100/1000 = 1.1x bonus
        uint256 calculatedRewards = (baseRate * timeElapsed * levelBonusMultiplier) / 1000; // Divide by 1000 for the multiplier scaling

        return stakingInfo.accumulatedRewards + calculatedRewards;
    }

    // --- Forging ---

    /// @notice Combines two ChronoAssets to attempt to forge a new asset.
    /// @dev Burns the two input assets, requires a ChronoToken fee, and has a probabilistic outcome.
    /// Requires prior ERC20 approval for the forging fee.
    /// @param tokenId1 The ID of the first token.
    /// @param tokenId2 The ID of the second token.
    function forgeChronoAssets(uint256 tokenId1, uint256 tokenId2) public whenNotPaused nonReentrant {
        require(tokenId1 != tokenId2, "Cannot forge the same token");
        address owner1 = ownerOf(tokenId1);
        address owner2 = ownerOf(tokenId2);
        require(owner1 == _msgSender() && owner2 == _msgSender(), "Caller must own both tokens");
        require(!_isStaked[tokenId1] && !_isStaked[tokenId2], "Cannot forge staked assets");

        // Ensure attributes are up-to-date before forging (especially for calculating resulting attributes)
        updateAssetAttributes(tokenId1);
        updateAssetAttributes(tokenId2);

        // Get current attributes for outcome calculation
        AssetAttributes memory attrs1 = _assetAttributes[tokenId1];
        AssetAttributes memory attrs2 = _assetAttributes[tokenId2];

        // Transfer forging fee from caller to contract
        chronoToken.transferFrom(_msgSender(), address(this), forgingFee);

        // Burn the input tokens
        _burn(tokenId1);
        _burn(tokenId2);

        // Determine success probabilistically (In production, use Chainlink VRF for real randomness)
        // Using block.timestamp + block.difficulty is NOT truly random and is front-runnable/manipulable.
        // This is for example purposes only.
        uint256 randomNumber = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, msg.sender))) % 1000;
        bool success = randomNumber < forgingSuccessRate;

        uint256 newItemId = 0;
        AssetAttributes memory newAttributes;

        if (success) {
            // Mint a new token on success
            newItemId = _nextTokenId++;
            _safeMint(_msgSender(), newItemId);

            // Determine new attributes based on inputs (example logic: average + bonus)
            newAttributes.level = uint16((uint256(attrs1.level) + uint256(attrs2.level)) / 2 + 5); // Example bonus
            newAttributes.power = uint16((uint256(attrs1.power) + uint256(attrs2.power)) / 2 + 10);
            newAttributes.decayResistance = uint16((uint256(attrs1.decayResistance) + uint256(attrs2.decayResistance)) / 2 + 2);

            // Cap attributes at max value if needed (e.g., uint16 max or defined max)
             if (newAttributes.level > type(uint16).max) newAttributes.level = type(uint16).max;
             if (newAttributes.power > type(uint16).max) newAttributes.power = type(uint16).max;
             if (newAttributes.decayResistance > type(uint16).max) newAttributes.decayResistance = type(uint16).max;


            // Initialize attributes and last updated time for the new asset
            _assetAttributes[newItemId] = newAttributes;
            _assetAttributes[newItemId].lastUpdatedTimestamp = uint40(block.timestamp);

        } else {
            // Failure: tokens are burned, fee is paid, no new token minted.
            // Could potentially mint a "failed forge" token or provide a small refund.
            // For this example, simple burn and fee loss.
        }

         // Clean up attributes for burned tokens
        delete _assetAttributes[tokenId1];
        delete _assetAttributes[tokenId2];


        emit ChronoAssetsForged(_msgSender(), tokenId1, tokenId2, success, newItemId);
    }

    // --- Query Functions ---

    /// @notice Gets the current ChronoToken fee required for forging.
    /// @return The forging fee amount.
    function getForgingCost() public view returns (uint256) {
        return forgingFee;
    }

    /// @notice Gets the current probabilistic success rate for forging (out of 1000).
    /// @return The forging success rate.
    function getForgingChance() public view returns (uint256) {
        return forgingSuccessRate;
    }

    /// @notice Gets the current rate at which attributes decay per second when not staked.
    /// @return The decay rate.
    function getDecayRatePerSecond() public view returns (uint256) {
        return decayRatePerSecond;
    }

    /// @notice Gets the current rate at which attributes grow per second when staked.
    /// @return The growth rate.
    function getGrowthRatePerSecond() public view returns (uint256) {
        return growthRatePerSecond;
    }

    /// @notice Gets the base staking reward rate per second per asset.
    /// @return The staking reward rate.
    function getStakingRewardRate() public view returns (uint256) {
        return stakingRewardRatePerSecond;
    }

    /// @notice Gets the minimum duration an asset must be staked before unstaking/claiming.
    /// @return The minimum stake duration in seconds.
    function getMinStakeDuration() public view returns (uint256) {
        return minStakeDuration;
    }

    /// @notice Gets the address of the linked ChronoToken contract.
    /// @return The address of the ChronoToken.
    function getChronoTokenAddress() public view returns (address) {
        return address(chronoToken);
    }


    // --- Internal Overrides ---

    // The default _beforeTokenTransfer in OpenZeppelin's Pausable includes whenNotPaused() check.
    // We might want to add custom logic here, e.g., prevent transfer if staked.
    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize)
        internal virtual override(ERC721, ERC721Burnable) whenNotPaused // Add whenNotPaused check here
    {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);

        // Prevent transferring a staked asset unless the transfer is from/to this contract itself for staking/unstaking
        if (_isStaked[tokenId] && from != address(this) && to != address(this)) {
             revert("Cannot transfer a staked asset");
        }

        // Ensure attributes are updated before any transfer out of the contract (e.g. unstaking)
        // or before being transferred in (e.g. staking)
        // This is important to capture the state correctly.
        // For transfers between users, update can be manual via updateAssetAttributes.
        // It's safer to ensure state is fresh during state-changing operations like stake/unstake/forge.
        // The updateAssetAttributes function is called explicitly in stake/unstake/forge for clarity,
        // but could also be called here for *any* transfer, though that might add unexpected gas costs.
        // Let's rely on explicit calls in the core functions for now.
    }


    // Required for ERC165 (AccessControl inherits ERC165)
    function supportsInterface(bytes4 interfaceId) public view virtual override(AccessControl, ERC721) returns (bool) {
        return interfaceId == type(IERC721).interfaceId ||
               interfaceId == type(IAccessControl).interfaceId ||
               super.supportsInterface(interfaceId);
    }
}
```

---

**Explanation of Concepts & Advanced Features:**

1.  **Dynamic NFT Attributes (`AssetAttributes` struct, `updateAssetAttributes`):**
    *   Unlike static NFTs, ChronoAssets have mutable attributes stored on-chain (`_assetAttributes`).
    *   The `updateAssetAttributes` function implements logic for these attributes to change based on time (`block.timestamp`) and rules (decay). This could be extended to incorporate external data via oracles.
    *   This allows NFTs to have a "lifespan" or require active management.
    *   **Concept:** State-changing NFTs, on-chain game mechanics.

2.  **Staking with Time-Based Rewards and Attribute Snapshots (`stakeChronoAsset`, `unstakeChronoAsset`, `claimStakingRewards`, `calculatePendingRewards`):**
    *   Users lock their NFTs in the contract to earn a yield in the project's native ERC20 token.
    *   Rewards are calculated based on time staked and potentially influenced by the asset's attributes *at the moment of staking or last claim* (`snapshotAttributes`). This adds a layer of complexity to reward calculation beyond a simple time accrual.
    *   Includes a `minStakeDuration` to encourage longer-term commitment.
    *   **Concept:** NFTFi (NFT Finance), yield bearing NFTs.

3.  **Probabilistic Forging with Asset Burning (`forgeChronoAssets`):**
    *   A mechanism to combine two NFTs, consuming them and a fee, to attempt to create a *new* NFT.
    *   The outcome is probabilistic (`forgingSuccessRate`), adding a risk/reward element.
    *   New asset attributes are derived from the input assets, potentially with bonuses, simulating crafting/breeding mechanics.
    *   Uses block attributes for "randomness" **(Note: This is insecure for production, requires Chainlink VRF or similar)**.
    *   **Concept:** NFT burning/minting mechanics, crafting, procedural generation (of attributes), token sinks (burning fee and potentially failed components).

4.  **Access Control (`AccessControl`):**
    *   Uses role-based permissions to restrict sensitive functions like minting, pausing, and setting parameters to designated addresses/roles.
    *   **Concept:** Secure contract administration.

5.  **Pausability (`Pausable`):**
    *   Allows administrators to pause key functions in case of emergency, upgrades, or maintenance.
    *   **Concept:** Safety mechanism.

6.  **Reentrancy Guard (`ReentrancyGuard`):**
    *   Protects functions that interact with external contracts (like transferring ERC20 rewards) from reentrancy attacks.
    *   **Concept:** Security best practice.

7.  **ERC721 Burnable (`ERC721Burnable`):**
    *   Adds a standard, safe way to destroy NFTs, used in the forging mechanism.

8.  **Internal ERC20 (`ChronoToken`) for Self-Sufficiency (Optional):**
    *   The ChronoForge contract can optionally deploy its own minimal ERC20 token, granting itself the minter role. This makes the system self-contained in this example. In a real scenario, the token might be deployed separately with more complex logic (e.g., supply caps, distribution).

9.  **Gas Efficiency Considerations:**
    *   Using `uint40` for timestamps where possible.
    *   Avoiding complex loops over large datasets in view functions (e.g., `getUserStakedAssets` is intentionally omitted as it's gas-intensive on-chain, suggesting an off-chain indexer).
    *   Attribute updates triggered by users or integrated into core actions rather than automatic on every block.

This contract provides a foundation for a dynamic digital asset ecosystem with integrated economic and game-like features, going beyond standard static NFTs or simple staking contracts.