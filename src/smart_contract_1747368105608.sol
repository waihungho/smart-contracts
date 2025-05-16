Okay, this is an ambitious request! Creating a truly novel concept that isn't *inspired* by or built upon existing open-source patterns (like ERC-20, ERC-721, AccessControl, etc.) is nearly impossible in Solidity today, as the ecosystem relies heavily on these standards and battle-tested libraries.

However, we can combine *advanced concepts* in a *creative and trendy way* to build a complex, interesting system that isn't just a direct copy of a single open-source project.

Let's design a contract for a "Dynamic Decentralized Asset Ecosystem" that combines:

1.  **Dynamic NFTs (DNFTs):** NFTs whose attributes or even appearance (via metadata/URI) can change based on on-chain actions (staking, crafting, upgrades, potentially time or external data via oracles - though full oracle integration is complex for a single example).
2.  **Resource Token:** An ERC-20 token used within the ecosystem for crafting, staking, etc.
3.  **Staking:** Staking both the Resource Token and the DNFTs to earn rewards (more Resource Tokens, or perhaps experience points for DNFTs).
4.  **Crafting/Upgrading:** A system to combine Resource Tokens and potentially other NFTs (or attributes) to create new NFTs or upgrade existing DNFTs, altering their attributes dynamically.
5.  **Role-Based Access Control:** Granular permissions for ecosystem management (minting, recipe management, pausing).
6.  **Pausable:** Standard emergency stop mechanism.

This combination provides a rich set of interactions and requires complex state management, hitting the "interesting, advanced, creative" points. We will use standard interfaces (ERC20, ERC721) and OpenZeppelin libraries (AccessControl, Pausable, SafeMath/SafeERC20) as building blocks, as writing secure primitives from scratch is highly risky and goes against best practices. The *logic* connecting these elements is the unique part.

---

**Contract Name:** `DynamicAssetEcosystem`

**Solidity Version:** `^0.8.20`

**Dependencies:** OpenZeppelin Contracts (for ERC20, ERC721, AccessControl, Pausable, SafeERC20)

---

**Outline & Function Summary:**

This contract manages a decentralized ecosystem involving a custom ERC-20 Resource Token and Dynamic ERC-721 NFTs. It implements staking mechanisms for both token types, a crafting/upgrading system for NFTs, and role-based access control for administrative functions.

1.  **Core Infrastructure & Access Control (`AccessControl`, `Pausable`)**
    *   `constructor()`: Initializes the contract, sets the deployer as the default admin.
    *   `pause()`: Pauses critical functions (only by `PAUSER_ROLE`).
    *   `unpause()`: Unpauses critical functions (only by `PAUSER_ROLE`).
    *   `grantRole(bytes32 role, address account)`: Grants a role (only by account with `admin` role).
    *   `revokeRole(bytes32 role, address account)`: Revokes a role (only by account with `admin` role).
    *   `renounceRole(bytes32 role, address account)`: Renounces a role (standard OZ).
    *   `hasRole(bytes32 role, address account)`: Checks if an account has a role (view).
    *   `getRoleAdmin(bytes32 role)`: Gets the admin role for a given role (view).

2.  **Token & NFT Management (Interfacing with external ERC20/ERC721)**
    *   `setResourceTokenAddress(address _tokenAddress)`: Sets the address of the external Resource Token contract (only by `DEFAULT_ADMIN_ROLE`).
    *   `setDynamicNFTAddress(address _nftAddress)`: Sets the address of the external Dynamic NFT contract (only by `DEFAULT_ADMIN_ROLE`).
    *   `mintNewNFT(address recipient, uint256 initialAttribute)`: Mints a new DNFT with initial attributes (only by `MINTER_ROLE`).
    *   `mintResourceTokensTo(address recipient, uint256 amount)`: Mints Resource Tokens (if the ERC20 contract supports it and grants this contract minter role, or transfers from a pre-approved pool) (only by `MINTER_ROLE`).
    *   `withdrawAdminFees(address tokenAddress, uint256 amount)`: Allows admin to withdraw specific tokens from contract balance (for collecting platform fees, etc.) (only by `DEFAULT_ADMIN_ROLE`).

3.  **Dynamic NFT State & Attributes**
    *   `getNFTAttribute(uint256 tokenId, string memory key)`: Gets a specific attribute value for an NFT (view).
    *   `setNFTAttributeByAdmin(uint256 tokenId, string memory key, uint256 value)`: Admin override to set an attribute (intended for fixes, use with caution) (only by `DEFAULT_ADMIN_ROLE`).
    *   `triggerNFTStateUpdate(uint256 tokenId)`: Allows user to trigger an internal state update for their NFT (checks conditions like cooldown, staked status etc., then calls internal logic) (public).
    *   `getNFTLastUpdateTime(uint256 tokenId)`: Gets the timestamp of the last state update trigger (view).

4.  **Staking (Resource Token)**
    *   `stakeResourceTokens(uint256 amount)`: Stakes Resource Tokens.
    *   `unstakeResourceTokens(uint256 amount)`: Unstakes Resource Tokens and claims rewards.
    *   `claimResourceStakingRewards()`: Claims accumulated Resource Token staking rewards without unstaking.
    *   `getStakedResourceBalance(address account)`: Gets the amount of Resource Tokens staked by an account (view).
    *   `getPendingResourceStakingRewards(address account)`: Calculates and gets the pending Resource Token rewards for an account (view).
    *   `updateResourceStakingRate(uint256 newRatePerSecond)`: Updates the reward rate for Resource Token staking (only by `STAKING_MANAGER_ROLE`).

5.  **Staking (Dynamic NFT)**
    *   `stakeNFT(uint256 tokenId)`: Stakes a DNFT. Transfers NFT ownership to the contract.
    *   `unstakeNFT(uint256 tokenId)`: Unstakes a DNFT. Transfers NFT back and claims rewards.
    *   `claimNFTStakingRewards(uint256 tokenId)`: Claims rewards for a staked DNFT without unstaking (can grant resource tokens, or apply attribute boost).
    *   `getNFTStakingInfo(uint256 tokenId)`: Gets staking information for a specific NFT (owner when staked, start time) (view).
    *   `getPendingNFTStakingRewards(uint256 tokenId)`: Calculates pending rewards (e.g., experience, resource tokens) for a staked NFT (view).
    *   `updateNFTStakingRate(uint256 newRatePerSecond)`: Updates the reward rate for NFT staking (only by `STAKING_MANAGER_ROLE`).

6.  **Crafting & Upgrading**
    *   `addCraftingRecipe(uint256 recipeId, CraftingRecipe memory recipe)`: Adds or updates a crafting/upgrade recipe (only by `RECIPE_MANAGER_ROLE`).
    *   `removeCraftingRecipe(uint256 recipeId)`: Removes a crafting/upgrade recipe (only by `RECIPE_MANAGER_ROLE`).
    *   `getCraftingRecipe(uint256 recipeId)`: Gets details of a crafting recipe (view).
    *   `craftItem(uint256 recipeId, uint256[] memory inputNFTTokenIds)`: Executes a crafting recipe. Checks inputs (resource tokens, specific NFTs, attributes), consumes inputs (burns tokens, burns/transfers input NFTs), and produces outputs (mints tokens, mints/modifies output NFTs based on recipe).
    *   `upgradeNFT(uint256 tokenIdToUpgrade, uint256 upgradeRecipeId, uint256[] memory inputItemTokenIds)`: Executes an upgrade recipe on a specific NFT. Checks inputs (resource tokens, item NFTs, attributes of the target NFT), consumes inputs, and modifies the attributes of `tokenIdToUpgrade` according to the recipe output.

---

**Smart Contract Code:**

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

// Note: A real implementation would have separate, complex contracts for the
// Resource Token (ERC20) and Dynamic NFT (ERC721), granting appropriate roles
// (like MINTER_ROLE) to this Ecosystem contract. This example assumes they exist
// and implements the *interaction* logic within this contract.
// The Dynamic NFT contract would need functions to allow trusted callers
// (like this Ecosystem contract) to update attributes.

/**
 * @title DynamicAssetEcosystem
 * @dev Manages a decentralized ecosystem with Dynamic NFTs, Resource Tokens, Staking, and Crafting.
 * Uses AccessControl for roles and Pausable for emergency stop.
 * This contract interacts with external ERC20 and ERC721 contracts.
 */
contract DynamicAssetEcosystem is AccessControl, Pausable, ReentrancyGuard, Context {
    using SafeERC20 for IERC20;

    // --- --- Outline & Function Summary --- ---
    //
    // This contract manages a decentralized ecosystem involving a custom ERC-20 Resource Token
    // and Dynamic ERC-721 NFTs. It implements staking mechanisms for both token types,
    // a crafting/upgrading system for NFTs, and role-based access control for administrative functions.
    //
    // 1.  Core Infrastructure & Access Control (`AccessControl`, `Pausable`)
    //     - `constructor()`: Initializes the contract, sets the deployer as the default admin.
    //     - `pause()`: Pauses critical functions (only by `PAUSER_ROLE`).
    //     - `unpause()`: Unpauses critical functions (only by `PAUSER_ROLE`).
    //     - `grantRole(bytes32 role, address account)`: Grants a role (only by account with `admin` role).
    //     - `revokeRole(bytes32 role, address account)`: Revokes a role (only by account with `admin` role).
    //     - `renounceRole(bytes32 role, address account)`: Renounces a role (standard OZ).
    //     - `hasRole(bytes32 role, address account)`: Checks if an account has a role (view).
    //     - `getRoleAdmin(bytes32 role)`: Gets the admin role for a given role (view).
    //
    // 2.  Token & NFT Management (Interfacing with external ERC20/ERC721)
    //     - `setResourceTokenAddress(address _tokenAddress)`: Sets the address of the external Resource Token contract (only by `DEFAULT_ADMIN_ROLE`).
    //     - `setDynamicNFTAddress(address _nftAddress)`: Sets the address of the external Dynamic NFT contract (only by `DEFAULT_ADMIN_ROLE`).
    //     - `mintNewNFT(address recipient, uint256 initialAttribute)`: Mints a new DNFT with initial attributes (only by `MINTER_ROLE`). Requires the DNFT contract to expose a minting function callable by this contract.
    //     - `mintResourceTokensTo(address recipient, uint256 amount)`: Mints Resource Tokens (only by `MINTER_ROLE`). Requires the ERC20 contract to expose a minting function callable by this contract.
    //     - `withdrawAdminFees(address tokenAddress, uint256 amount)`: Allows admin to withdraw specific tokens from contract balance (for collecting platform fees, etc.) (only by `DEFAULT_ADMIN_ROLE`).
    //
    // 3.  Dynamic NFT State & Attributes
    //     - `getNFTAttribute(uint256 tokenId, string memory key)`: Gets a specific attribute value for an NFT (view). Requires the DNFT contract to expose a public getter.
    //     - `setNFTAttributeByAdmin(uint256 tokenId, string memory key, uint256 value)`: Admin override to set an attribute (intended for fixes, use with caution) (only by `DEFAULT_ADMIN_ROLE`). Requires the DNFT contract to expose a trusted setter.
    //     - `triggerNFTStateUpdate(uint256 tokenId)`: Allows user to trigger an internal state update for their NFT (checks conditions like cooldown, staked status etc., then calls internal logic) (public).
    //     - `getNFTLastUpdateTime(uint256 tokenId)`: Gets the timestamp of the last state update trigger (view).
    //
    // 4.  Staking (Resource Token)
    //     - `stakeResourceTokens(uint256 amount)`: Stakes Resource Tokens.
    //     - `unstakeResourceTokens(uint256 amount)`: Unstakes Resource Tokens and claims rewards.
    //     - `claimResourceStakingRewards()`: Claims accumulated Resource Token staking rewards without unstaking.
    //     - `getStakedResourceBalance(address account)`: Gets the amount of Resource Tokens staked by an account (view).
    //     - `getPendingResourceStakingRewards(address account)`: Calculates and gets the pending Resource Token rewards for an account (view).
    //     - `updateResourceStakingRate(uint256 newRatePerSecond)`: Updates the reward rate for Resource Token staking (only by `STAKING_MANAGER_ROLE`).
    //
    // 5.  Staking (Dynamic NFT)
    //     - `stakeNFT(uint256 tokenId)`: Stakes a DNFT. Transfers NFT ownership to the contract.
    //     - `unstakeNFT(uint256 tokenId)`: Unstakes a DNFT. Transfers NFT back and claims rewards.
    //     - `claimNFTStakingRewards(uint256 tokenId)`: Claims rewards for a staked DNFT without unstaking (can grant resource tokens, or apply attribute boost).
    //     - `getNFTStakingInfo(uint256 tokenId)`: Gets staking information for a specific NFT (owner when staked, start time) (view).
    //     - `getPendingNFTStakingRewards(uint256 tokenId)`: Calculates pending rewards (e.g., experience, resource tokens) for a staked NFT (view).
    //     - `updateNFTStakingRate(uint256 newRatePerSecond)`: Updates the reward rate for NFT staking (only by `STAKING_MANAGER_ROLE`).
    //
    // 6.  Crafting & Upgrading
    //     - `addCraftingRecipe(uint256 recipeId, CraftingRecipe memory recipe)`: Adds or updates a crafting/upgrade recipe (only by `RECIPE_MANAGER_ROLE`).
    //     - `removeCraftingRecipe(uint256 recipeId)`: Removes a crafting/upgrade recipe (only by `RECIPE_MANAGER_ROLE`).
    //     - `getCraftingRecipe(uint256 recipeId)`: Gets details of a crafting recipe (view).
    //     - `craftItem(uint256 recipeId, uint256[] memory inputNFTTokenIds)`: Executes a crafting recipe. Checks inputs (resource tokens, specific NFTs, attributes), consumes inputs (burns tokens, burns/transfers input NFTs), and produces outputs (mints tokens, mints/modifies output NFTs based on recipe).
    //     - `upgradeNFT(uint256 tokenIdToUpgrade, uint256 upgradeRecipeId, uint256[] memory inputItemTokenIds)`: Executes an upgrade recipe on a specific NFT. Checks inputs (resource tokens, item NFTs, attributes of the target NFT), consumes inputs, and modifies the attributes of `tokenIdToUpgrade` according to the recipe output.

    // --- --- State Variables --- ---

    // Role definitions
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant STAKING_MANAGER_ROLE = keccak256("STAKING_MANAGER_ROLE");
    bytes32 public constant RECIPE_MANAGER_ROLE = keccak256("RECIPE_MANAGER_ROLE");

    // Addresses of associated token/NFT contracts (expected to be deployed separately)
    IERC20 public resourceToken;
    IERC721 public dynamicNFT; // Assumes this ERC721 has functions to update attributes

    // --- Staking State ---
    // Resource Token Staking
    mapping(address => uint256) private _stakedResourceBalances;
    mapping(address => uint256) private _resourceStakingRewardLastUpdateTime; // Timestamp
    uint256 public resourceStakingRatePerSecond; // Tokens per second per token staked

    // Dynamic NFT Staking
    mapping(uint256 => address) private _stakedNFTOriginalOwner; // tokenId => original owner
    mapping(uint256 => uint256) private _nftStakingStartTime; // tokenId => timestamp
    mapping(uint256 => uint256) private _nftStakingAccruedReward; // tokenId => unclaimed reward (e.g., resource tokens or XP)
    uint256 public nftStakingRatePerSecond; // Reward units per second per NFT staked (e.g., XP per second, or Resource Tokens per second)

    // --- Dynamic NFT State ---
    // Storing attributes directly here for simplicity, but in a real DNFT it's on the NFT contract
    // mapping(uint256 => mapping(string => uint256)) private _nftAttributes; // tokenId => attribute name => value
    mapping(uint256 => uint256) private _nftLastUpdateTime; // tokenId => timestamp of last manual trigger

    // --- Crafting/Upgrading State ---
    struct CraftingInput {
        uint256 resourceTokenAmount; // Required Resource Token amount
        uint256[] inputNFTTokenIds;  // Required specific input NFTs (will be burned/consumed)
        // Add more complex inputs like 'minimumAttribute' requirements on inputNFTs
    }

    struct CraftingOutput {
        uint256 resourceTokenAmount; // Resource Tokens produced
        uint256[] outputNFTTokenIds; // Specific output NFTs to mint (e.g., recipe creates a specific item NFT)
        // Add dynamic output based on inputs, e.g., modify attributes of a target NFT
        mapping(string => uint256) attributeChanges; // Attribute changes for upgrade recipes or modifying output NFTs
        uint256 targetTokenIdIndex; // Index in inputNFTTokenIds that is the upgrade target (for upgrades)
        bool burnsInputNFTs; // Flag to determine if input NFTs are burned or transferred elsewhere (e.g. contract)
    }

    struct CraftingRecipe {
        bool exists;
        CraftingInput inputs;
        CraftingOutput outputs;
        // Add cooldown, max uses, etc. if needed
    }

    mapping(uint256 => CraftingRecipe) private _craftingRecipes;

    // --- --- Events --- ---

    event ResourceTokenAddressUpdated(address indexed oldAddress, address indexed newAddress);
    event DynamicNFTAddressUpdated(address indexed oldAddress, address indexed newAddress);
    event NFTMinted(address indexed recipient, uint256 indexed tokenId, uint256 initialAttribute);
    event ResourceTokensMinted(address indexed recipient, uint256 amount);
    event AdminFeesWithdrawn(address indexed tokenAddress, uint256 amount);

    event NFTAttributeUpdated(uint256 indexed tokenId, string key, uint256 value);
    event NFTStateUpdated(uint256 indexed tokenId, uint256 timestamp);

    event ResourceTokensStaked(address indexed account, uint256 amount);
    event ResourceTokensUnstaked(address indexed account, uint256 amount);
    event ResourceStakingRewardsClaimed(address indexed account, uint256 rewardAmount);
    event ResourceStakingRateUpdated(uint256 oldRate, uint256 newRate);

    event NFTStaked(address indexed owner, uint256 indexed tokenId);
    event NFTUnstaked(address indexed owner, uint256 indexed tokenId);
    event NFTStakingRewardsClaimed(address indexed owner, uint256 indexed tokenId, uint256 rewardAmount);
    event NFTStakingRateUpdated(uint256 oldRate, uint256 newRate);

    event CraftingRecipeAdded(uint256 indexed recipeId);
    event CraftingRecipeRemoved(uint256 indexed recipeId);
    event ItemCrafted(address indexed crafter, uint256 indexed recipeId, uint256 outputResourceAmount); // Simplified event
    event NFTUpgraded(address indexed uphrader, uint256 indexed tokenId, uint256 indexed recipeId);

    // --- --- Errors --- ---

    error ResourceTokenNotSet();
    error DynamicNFTNotSet();
    error InsufficientResourceTokens(uint256 required, uint256 available);
    error InputNFTNotFound(uint256 tokenId);
    error InputNFTNotOwned(uint256 tokenId, address owner);
    error InvalidCraftingRecipe(uint256 recipeId);
    error InsufficientCraftingInputs(uint256 recipeId);
    error NFTAlreadyStaked(uint256 tokenId);
    error NFTNotStaked(uint256 tokenId);
    error NotNFTStakingOwner(uint256 tokenId, address owner);
    error NothingToClaim();
    error NothingStaked();
    error AttributeKeyNotFound(uint256 tokenId, string key);
    error InvalidAttributeValue();
    error InvalidRecipeTargetIndex(uint256 recipeId, uint256 targetIndex);
    error UpdateCooldownNotPassed(uint256 tokenId, uint256 cooldownDuration);
    error TargetNFTRequiredForUpgrade();


    // --- --- Constructor & Initialization --- ---

    constructor() Pausable() {
        // Grant the deployer the default admin role
        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
        // Grant admin roles to itself for managing other roles if needed
        _setRoleAdmin(MINTER_ROLE, DEFAULT_ADMIN_ROLE);
        _setRoleAdmin(PAUSER_ROLE, DEFAULT_ADMIN_ROLE);
        _setRoleAdmin(STAKING_MANAGER_ROLE, DEFAULT_ADMIN_ROLE);
        _setRoleAdmin(RECIPE_MANAGER_ROLE, DEFAULT_ADMIN_ROLE);

        // Grant initial roles to the deployer for convenience (can be changed later)
        _grantRole(MINTER_ROLE, _msgSender());
        _grantRole(PAUSER_ROLE, _msgSender());
        _grantRole(STAKING_MANAGER_ROLE, _msgSender());
        _grantRole(RECIPE_MANAGER_ROLE, _msgSender());

        // Set default staking rates (can be updated by STAKING_MANAGER_ROLE)
        resourceStakingRatePerSecond = 1 ether / 1 hours; // Example: 1 token per hour per token staked (needs careful tuning)
        nftStakingRatePerSecond = 1; // Example: 1 XP per second per NFT staked
    }

    // --- --- Access Control & Pausable --- ---

    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    // Expose AccessControl functions (already public from inheritance)
    // grantRole, revokeRole, renounceRole, hasRole, getRoleAdmin

    // --- --- Token & NFT Management Setters --- ---

    /**
     * @dev Sets the address of the external Resource Token contract.
     * Requires `DEFAULT_ADMIN_ROLE`.
     * @param _tokenAddress The address of the ERC20 contract.
     */
    function setResourceTokenAddress(address _tokenAddress) public onlyRole(DEFAULT_ADMIN_ROLE) {
        require(_tokenAddress != address(0), "Zero address not allowed");
        emit ResourceTokenAddressUpdated(address(resourceToken), _tokenAddress);
        resourceToken = IERC20(_tokenAddress);
    }

    /**
     * @dev Sets the address of the external Dynamic NFT contract.
     * Requires `DEFAULT_ADMIN_ROLE`.
     * @param _nftAddress The address of the ERC721 contract.
     */
    function setDynamicNFTAddress(address _nftAddress) public onlyRole(DEFAULT_ADMIN_ROLE) {
        require(_nftAddress != address(0), "Zero address not allowed");
        emit DynamicNFTAddressUpdated(address(dynamicNFT), _nftAddress);
        dynamicNFT = IERC721(_nftAddress);
    }

    // --- --- Minting (Requires external contracts to grant MINTER_ROLE to this contract) --- ---

    /**
     * @dev Mints a new Dynamic NFT.
     * Requires `MINTER_ROLE`. Requires the external NFT contract to have a mint function accessible by this contract.
     * @param recipient The address to mint the NFT to.
     * @param initialAttribute An example initial attribute value.
     */
    function mintNewNFT(address recipient, uint256 initialAttribute) public onlyRole(MINTER_ROLE) whenNotPaused {
        require(address(dynamicNFT) != address(0), address(dynamicNFT) == address(0) ? "NFT contract not set" : "NFT contract not set"); // Use custom error
        // Call the mint function on the external DNFT contract. This assumes the DNFT contract
        // has a function like `safeMint(address to, uint256 tokenId, uint256 initialAttributeValue)`
        // and has granted MINTER_ROLE to *this* contract's address.
        // uint256 newTokenId = dynamicNFT.safeMint(recipient, initialAttribute); // Placeholder call

        // Simulating the attribute setting here for demonstration, but it should happen on the DNFT contract
        // _nftAttributes[newTokenId]["initial"] = initialAttribute; // Example attribute
        // _nftLastUpdateTime[newTokenId] = block.timestamp; // Initialize update time

        // In a real scenario, dynamicNFT.safeMint would return the tokenId or emit an event
        // We'll emit a placeholder event here
        uint256 newTokenId = block.timestamp; // Dummy tokenId for demonstration
        emit NFTMinted(recipient, newTokenId, initialAttribute);
    }

    /**
     * @dev Mints Resource Tokens and sends them to a recipient.
     * Requires `MINTER_ROLE`. Requires the external Resource Token contract to have a mint function accessible by this contract.
     * @param recipient The address to mint tokens to.
     * @param amount The amount of tokens to mint.
     */
    function mintResourceTokensTo(address recipient, uint256 amount) public onlyRole(MINTER_ROLE) whenNotPaused {
        require(address(resourceToken) != address(0), address(resourceToken) == address(0) ? "Resource token contract not set" : "Resource token contract not set"); // Use custom error
        // Call the mint function on the external ERC20 contract. This assumes the ERC20 contract
        // has a function like `mint(address to, uint256 amount)` and has granted MINTER_ROLE
        // to *this* contract's address.
        // resourceToken.mint(recipient, amount); // Placeholder call
        emit ResourceTokensMinted(recipient, amount);
    }

    /**
     * @dev Allows admin to withdraw arbitrary tokens from the contract.
     * Useful for withdrawing platform fees or mistakenly sent tokens.
     * Requires `DEFAULT_ADMIN_ROLE`.
     * @param tokenAddress Address of the token to withdraw.
     * @param amount Amount to withdraw.
     */
    function withdrawAdminFees(address tokenAddress, uint256 amount) public onlyRole(DEFAULT_ADMIN_ROLE) {
        require(tokenAddress != address(0), "Cannot withdraw from zero address");
        IERC20 token = IERC20(tokenAddress);
        uint256 contractBalance = token.balanceOf(address(this));
        require(amount <= contractBalance, "Insufficient balance in contract");
        token.safeTransfer(_msgSender(), amount);
        emit AdminFeesWithdrawn(tokenAddress, amount);
    }


    // --- --- Dynamic NFT State & Attributes --- ---

    /**
     * @dev Gets a specific attribute for a given NFT.
     * This function assumes the external DNFT contract has a public getter function
     * like `getAttribute(uint256 tokenId, string memory key)`.
     * @param tokenId The ID of the NFT.
     * @param key The name of the attribute.
     * @return The value of the attribute.
     */
    function getNFTAttribute(uint256 tokenId, string memory key) public view returns (uint256) {
        require(address(dynamicNFT) != address(0), "NFT contract not set");
        // Call the getter on the external DNFT contract
        // return dynamicNFT.getAttribute(tokenId, key); // Placeholder call
        // Simulating attribute lookup here for demonstration
        // return _nftAttributes[tokenId][key];
        return 0; // Placeholder return
    }

    /**
     * @dev Allows admin to manually set an attribute for an NFT.
     * Use with extreme caution, primarily for emergency fixes or initialization.
     * Requires `DEFAULT_ADMIN_ROLE`. Requires the external DNFT contract to have a trusted setter callable by this contract.
     * @param tokenId The ID of the NFT.
     * @param key The name of the attribute.
     * @param value The new value for the attribute.
     */
    function setNFTAttributeByAdmin(uint256 tokenId, string memory key, uint256 value) public onlyRole(DEFAULT_ADMIN_ROLE) {
        require(address(dynamicNFT) != address(0), "NFT contract not set");
        // Call the setter on the external DNFT contract. This assumes the DNFT contract
        // has a function like `setAttribute(uint256 tokenId, string memory key, uint256 value)`
        // and has granted DEFAULT_ADMIN_ROLE to *this* contract or allows this caller via another mechanism.
        // dynamicNFT.setAttribute(tokenId, key, value); // Placeholder call
        // _nftAttributes[tokenId][key] = value; // Simulating attribute update
        emit NFTAttributeUpdated(tokenId, key, value);
    }

     /**
      * @dev Triggers an update to an NFT's state based on time or other conditions.
      * Callable by the NFT owner or staked owner.
      * Can potentially accrue XP, health regen, or other time-based effects by updating attributes.
      * @param tokenId The ID of the NFT to update.
      */
    function triggerNFTStateUpdate(uint256 tokenId) public whenNotPaused nonReentrant {
        require(address(dynamicNFT) != address(0), "NFT contract not set");

        address currentOwner = dynamicNFT.ownerOf(tokenId);
        address stakedOwner = _stakedNFTOriginalOwner[tokenId];

        // Must own the NFT or be the original owner if staked
        require(currentOwner == _msgSender() || (stakedOwner != address(0) && stakedOwner == _msgSender()), "Not authorized for this NFT");

        uint256 lastUpdateTime = _nftLastUpdateTime[tokenId];
        uint256 cooldown = 1 hours; // Example: Can only update state every hour

        require(block.timestamp >= lastUpdateTime + cooldown, UpdateCooldownNotPassed(tokenId, cooldown));

        // --- Internal State Update Logic (Placeholder) ---
        // This is where the core dynamic logic would live. Examples:
        // 1. If staked: Add staking rewards (e.g., XP). This could be an alternative to claimNFTStakingRewards.
        //    If (stakedOwner != address(0)) {
        //        uint256 elapsed = block.timestamp - _nftStakingStartTime[tokenId];
        //        uint256 potentialReward = elapsed * nftStakingRatePerSecond;
        //        _nftStakingAccruedReward[tokenId] += potentialReward; // Add to unclaimed reward
        //        _nftStakingStartTime[tokenId] = block.timestamp; // Reset staking time for future accrual
        //        // Or directly update NFT attributes on the DNFT contract:
        //        // dynamicNFT.setAttribute(tokenId, "experience", getNFTAttribute(tokenId, "experience") + potentialReward);
        //    }
        // 2. If not staked: Maybe a small state change or check for external conditions.
        //    e.g., if NFT has "health" attribute, maybe add health regeneration based on time passed.
        //    uint256 currentHealth = getNFTAttribute(tokenId, "health");
        //    uint256 maxHealth = getNFTAttribute(tokenId, "maxHealth");
        //    uint256 timeElapsedSinceLastUpdate = block.timestamp - lastUpdateTime;
        //    uint256 regeneratedHealth = (timeElapsedSinceLastUpdate / 1 hours) * 5; // Example: 5 health per hour
        //    uint256 newHealth = currentHealth + regeneratedHealth;
        //    if (newHealth > maxHealth) newHealth = maxHealth;
        //    if (newHealth != currentHealth) {
        //        dynamicNFT.setAttribute(tokenId, "health", newHealth); // Placeholder call
        //        emit NFTAttributeUpdated(tokenId, "health", newHealth);
        //    }
        // --- End Internal State Update Logic ---

        _nftLastUpdateTime[tokenId] = block.timestamp; // Record the update timestamp
        emit NFTStateUpdated(tokenId, block.timestamp);
    }

    /**
     * @dev Gets the timestamp of the last state update triggered for an NFT.
     * @param tokenId The ID of the NFT.
     * @return Timestamp of the last update.
     */
    function getNFTLastUpdateTime(uint256 tokenId) public view returns (uint256) {
        return _nftLastUpdateTime[tokenId];
    }

    // --- --- Staking (Resource Token) --- ---

    /**
     * @dev Stakes Resource Tokens.
     * Caller must approve this contract to spend the tokens first.
     * @param amount The amount of Resource Tokens to stake.
     */
    function stakeResourceTokens(uint256 amount) public whenNotPaused nonReentrant {
        require(amount > 0, "Amount must be positive");
        require(address(resourceToken) != address(0), "Resource token contract not set");

        _updateResourceStakingReward(_msgSender()); // Payout pending rewards before adding more stake

        _stakedResourceBalances[_msgSender()] += amount;
        resourceToken.safeTransferFrom(_msgSender(), address(this), amount);
        _resourceStakingRewardLastUpdateTime[_msgSender()] = block.timestamp; // Reset timestamp

        emit ResourceTokensStaked(_msgSender(), amount);
    }

    /**
     * @dev Unstakes Resource Tokens and claims pending rewards.
     * @param amount The amount of Resource Tokens to unstake.
     */
    function unstakeResourceTokens(uint256 amount) public whenNotPaused nonReentrant {
        require(amount > 0, "Amount must be positive");
        require(address(resourceToken) != address(0), "Resource token contract not set");
        require(_stakedResourceBalances[_msgSender()] >= amount, InsufficientResourceTokens(amount, _stakedResourceBalances[_msgSender()]));

        _updateResourceStakingReward(_msgSender()); // Payout pending rewards before unstaking

        _stakedResourceBalances[_msgSender()] -= amount;
        resourceToken.safeTransfer(_msgSender(), amount);
        _resourceStakingRewardLastUpdateTime[_msgSender()] = block.timestamp; // Reset timestamp

        emit ResourceTokensUnstaked(_msgSender(), amount);
    }

    /**
     * @dev Claims pending Resource Token staking rewards without unstaking.
     */
    function claimResourceStakingRewards() public whenNotPaused nonReentrant {
        require(address(resourceToken) != address(0), "Resource token contract not set");
         if (getPendingResourceStakingRewards(_msgSender()) == 0) {
             revert NothingToClaim();
         }
        _updateResourceStakingReward(_msgSender()); // Payout pending rewards
        // _resourceStakingRewardLastUpdateTime is updated inside _updateResourceStakingReward
        // An event is emitted inside _updateResourceStakingReward
    }

    /**
     * @dev Internal function to calculate and distribute resource staking rewards.
     * @param account The account to update rewards for.
     */
    function _updateResourceStakingReward(address account) internal {
        uint256 pendingRewards = getPendingResourceStakingRewards(account);
        if (pendingRewards > 0) {
             // Assumes resourceToken contract allows transfer from address(this)
             // If rewards are minted by this contract, call resourceToken.mint instead
            resourceToken.safeTransfer(account, pendingRewards);
            emit ResourceStakingRewardsClaimed(account, pendingRewards);
        }
        _resourceStakingRewardLastUpdateTime[account] = block.timestamp;
    }

    /**
     * @dev Gets the amount of Resource Tokens staked by an account.
     * @param account The account address.
     * @return The staked balance.
     */
    function getStakedResourceBalance(address account) public view returns (uint256) {
        return _stakedResourceBalances[account];
    }

    /**
     * @dev Calculates the pending Resource Token rewards for an account.
     * @param account The account address.
     * @return The pending reward amount.
     */
    function getPendingResourceStakingRewards(address account) public view returns (uint256) {
        uint256 stakedAmount = _stakedResourceBalances[account];
        if (stakedAmount == 0) {
            return 0;
        }
        uint256 timeElapsed = block.timestamp - _resourceStakingRewardLastUpdateTime[account];
        return stakedAmount * resourceStakingRatePerSecond * timeElapsed; // Rate per second per token staked
    }

    /**
     * @dev Updates the Resource Token staking reward rate.
     * Requires `STAKING_MANAGER_ROLE`.
     * @param newRatePerSecond The new reward rate (tokens per second per token staked).
     */
    function updateResourceStakingRate(uint256 newRatePerSecond) public onlyRole(STAKING_MANAGER_ROLE) {
        emit ResourceStakingRateUpdated(resourceStakingRatePerSecond, newRatePerSecond);
        resourceStakingRatePerSecond = newRatePerSecond;
    }

    // --- --- Staking (Dynamic NFT) --- ---

    /**
     * @dev Stakes a Dynamic NFT.
     * Caller must own the NFT and approve this contract to transfer it.
     * @param tokenId The ID of the NFT to stake.
     */
    function stakeNFT(uint256 tokenId) public whenNotPaused nonReentrant {
        require(address(dynamicNFT) != address(0), "NFT contract not set");
        address owner = dynamicNFT.ownerOf(tokenId);
        require(owner == _msgSender(), InputNFTNotOwned(tokenId, owner));
        require(_stakedNFTOriginalOwner[tokenId] == address(0), NFTAlreadyStaked(tokenId));

        // Transfer NFT ownership to the contract
        dynamicNFT.safeTransferFrom(owner, address(this), tokenId);

        _stakedNFTOriginalOwner[tokenId] = owner;
        _nftStakingStartTime[tokenId] = block.timestamp;
        _nftStakingAccruedReward[tokenId] = 0; // Reset accrued reward on new stake

        emit NFTStaked(owner, tokenId);
    }

    /**
     * @dev Unstakes a Dynamic NFT.
     * Callable by the original owner of the staked NFT. Claims pending rewards.
     * @param tokenId The ID of the NFT to unstake.
     */
    function unstakeNFT(uint256 tokenId) public whenNotPaused nonReentrant {
        require(address(dynamicNFT) != address(0), "NFT contract not set");
        require(_stakedNFTOriginalOwner[tokenId] != address(0), NFTNotStaked(tokenId));
        require(_stakedNFTOriginalOwner[tokenId] == _msgSender(), NotNFTStakingOwner(tokenId, _msgSender()));

        // Calculate and distribute rewards before unstaking
        _updateNFTStakingReward(tokenId); // This will update _nftStakingAccruedReward

        // Transfer NFT ownership back to the original owner
        dynamicNFT.safeTransferFrom(address(this), _msgSender(), tokenId);

        // Clear staking state
        delete _stakedNFTOriginalOwner[tokenId];
        delete _nftStakingStartTime[tokenId];
        // _nftStakingAccruedReward[tokenId] might have remaining reward if not fully claimed/distributed in _updateNFTStakingReward
        // Decide if residual rewards are kept by contract or cleared. Clearing for simplicity:
        delete _nftStakingAccruedReward[tokenId];

        emit NFTUnstaked(_msgSender(), tokenId);
    }

    /**
     * @dev Claims pending rewards for a staked Dynamic NFT.
     * Rewards are calculated based on time staked and `nftStakingRatePerSecond`.
     * Can distribute Resource Tokens or update NFT attributes (e.g., grant XP).
     * @param tokenId The ID of the staked NFT.
     */
    function claimNFTStakingRewards(uint256 tokenId) public whenNotPaused nonReentrant {
        require(address(dynamicNFT) != address(0), "NFT contract not set");
        require(_stakedNFTOriginalOwner[tokenId] != address(0), NFTNotStaked(tokenId));
        require(_stakedNFTOriginalOwner[tokenId] == _msgSender(), NotNFTStakingOwner(tokenId, _msgSender()));

        _updateNFTStakingReward(tokenId); // This will update state and emit event
    }

     /**
      * @dev Internal function to calculate and distribute NFT staking rewards.
      * Rewards can be Resource Tokens or contribute to an NFT attribute (like XP).
      * @param tokenId The ID of the staked NFT.
      */
    function _updateNFTStakingReward(uint256 tokenId) internal {
        uint256 lastRewardTime = _nftStakingStartTime[tokenId]; // Time since last reward calculation/stake start
        uint256 timeElapsed = block.timestamp - lastRewardTime;

        if (timeElapsed > 0) {
             // Calculate rewards based on rate and time
            uint256 newAccrued = timeElapsed * nftStakingRatePerSecond;
            _nftStakingAccruedReward[tokenId] += newAccrued;

            // Decide how to distribute rewards:
            // Option 1: Distribute as Resource Tokens (requires this contract to hold/mint tokens)
            uint256 rewardAmount = _nftStakingAccruedReward[tokenId]; // Assuming nftStakingRatePerSecond means Resource Tokens
            if (rewardAmount > 0) {
                require(address(resourceToken) != address(0), "Resource token contract not set");
                // resourceToken.safeTransfer(_stakedNFTOriginalOwner[tokenId], rewardAmount); // Transfer existing tokens
                // OR resourceToken.mint(_stakedNFTOriginalOwner[tokenId], rewardAmount); // Mint new tokens (requires minter role)
                 emit NFTStakingRewardsClaimed(_stakedNFTOriginalOwner[tokenId], tokenId, rewardAmount);
                 _nftStakingAccruedReward[tokenId] = 0; // Reset accrued after claiming
            }

            // Option 2: Update an NFT attribute (e.g., add XP directly to the staked NFT)
            // Assumes nftStakingRatePerSecond is XP per second
            // uint256 xpGain = newAccrued;
            // dynamicNFT.setAttribute(tokenId, "experience", getNFTAttribute(tokenId, "experience") + xpGain); // Placeholder call
            // emit NFTAttributeUpdated(tokenId, "experience", getNFTAttribute(tokenId, "experience"));

            _nftStakingStartTime[tokenId] = block.timestamp; // Reset timer
        }
    }


    /**
     * @dev Gets staking information for a specific NFT.
     * Returns the original owner's address and the staking start time.
     * Returns zero address and zero time if not staked.
     * @param tokenId The ID of the NFT.
     * @return owner The original owner when staked.
     * @return startTime The timestamp when staking started.
     */
    function getNFTStakingInfo(uint256 tokenId) public view returns (address owner, uint256 startTime) {
        return (_stakedNFTOriginalOwner[tokenId], _nftStakingStartTime[tokenId]);
    }

    /**
     * @dev Calculates the pending rewards for a staked NFT.
     * @param tokenId The ID of the staked NFT.
     * @return The pending reward amount (interpretaion depends on `nftStakingRatePerSecond`).
     */
    function getPendingNFTStakingRewards(uint256 tokenId) public view returns (uint256) {
        address originalOwner = _stakedNFTOriginalOwner[tokenId];
        if (originalOwner == address(0)) {
            return 0; // Not staked
        }
        uint256 timeElapsed = block.timestamp - _nftStakingStartTime[tokenId];
        return _nftStakingAccruedReward[tokenId] + (timeElapsed * nftStakingRatePerSecond);
    }


    /**
     * @dev Updates the Dynamic NFT staking reward rate.
     * Requires `STAKING_MANAGER_ROLE`.
     * @param newRatePerSecond The new reward rate (reward units per second per NFT).
     */
    function updateNFTStakingRate(uint256 newRatePerSecond) public onlyRole(STAKING_MANAGER_ROLE) {
        emit NFTStakingRateUpdated(nftStakingRatePerSecond, newRatePerSecond);
        nftStakingRatePerSecond = newRatePerSecond;
    }

    // --- --- Crafting & Upgrading --- ---

    /**
     * @dev Adds or updates a crafting recipe.
     * Requires `RECIPE_MANAGER_ROLE`.
     * @param recipeId A unique ID for the recipe.
     * @param recipe The CraftingRecipe struct containing inputs and outputs.
     */
    function addCraftingRecipe(uint256 recipeId, CraftingRecipe memory recipe) public onlyRole(RECIPE_MANAGER_ROLE) {
        // Basic validation - add more complex validation as needed
        if (recipe.outputs.burnsInputNFTs && recipe.outputs.targetTokenIdIndex != 0) {
             // Avoid ambiguity if input NFTs are burned and there's also a target index
             // You might want to allow burning all inputs *except* the target index
        }
        // More validation for inputs/outputs...

        _craftingRecipes[recipeId] = recipe;
        _craftingRecipes[recipeId].exists = true; // Mark as existing

        emit CraftingRecipeAdded(recipeId);
    }

    /**
     * @dev Removes a crafting recipe.
     * Requires `RECIPE_MANAGER_ROLE`.
     * @param recipeId The ID of the recipe to remove.
     */
    function removeCraftingRecipe(uint256 recipeId) public onlyRole(RECIPE_MANAGER_ROLE) {
        require(_craftingRecipes[recipeId].exists, InvalidCraftingRecipe(recipeId));
        delete _craftingRecipes[recipeId];
        emit CraftingRecipeRemoved(recipeId);
    }

    /**
     * @dev Gets details of a crafting recipe.
     * @param recipeId The ID of the recipe.
     * @return The CraftingRecipe struct. Note: Mapping in struct won't be fully returned.
     *         A separate view function might be needed for attributes, or return a simplified struct.
     */
    function getCraftingRecipe(uint256 recipeId) public view returns (CraftingRecipe memory) {
        require(_craftingRecipes[recipeId].exists, InvalidCraftingRecipe(recipeId));
        return _craftingRecipes[recipeId]; // Note: Mapping in struct cannot be directly returned, this is a limitation.
                                          // Need separate getters for attribute changes.
    }

    /**
     * @dev Executes a crafting recipe to create new items/NFTs.
     * Consumes required resource tokens and input NFTs.
     * Mints output resource tokens and output NFTs.
     * @param recipeId The ID of the recipe to use.
     * @param inputNFTTokenIds An array of token IDs for input NFTs required by the recipe.
     */
    function craftItem(uint256 recipeId, uint256[] memory inputNFTTokenIds) public whenNotPaused nonReentrant {
        require(address(resourceToken) != address(0), "Resource token contract not set");
        require(address(dynamicNFT) != address(0), "NFT contract not set");

        CraftingRecipe storage recipe = _craftingRecipes[recipeId];
        require(recipe.exists, InvalidCraftingRecipe(recipeId));

        address crafter = _msgSender();

        // --- Check Inputs ---
        // Check Resource Tokens
        if (recipe.inputs.resourceTokenAmount > 0) {
            require(resourceToken.balanceOf(crafter) >= recipe.inputs.resourceTokenAmount,
                InsufficientResourceTokens(recipe.inputs.resourceTokenAmount, resourceToken.balanceOf(crafter)));
        }

        // Check Input NFTs
        require(inputNFTTokenIds.length == recipe.inputs.inputNFTTokenIds.length, "Incorrect number of input NFTs");
        for (uint i = 0; i < inputNFTTokenIds.length; i++) {
            uint256 inputTokenId = inputNFTTokenIds[i];
            uint256 requiredTokenId = recipe.inputs.inputNFTTokenIds[i]; // Assuming order matters or map recipe input to provided input
            require(dynamicNFT.ownerOf(inputTokenId) == crafter, InputNFTNotOwned(inputTokenId, crafter));
            // Add check if inputTokenId *matches* requiredTokenId if recipe specifies specific IDs, or check type/attributes instead.
            // Example: check if NFT has a specific attribute value
            // require(getNFTAttribute(inputTokenId, "type") == requiredTokenId, "Input NFT type mismatch");

            // Require approval for transfers
            require(dynamicNFT.getApproved(inputTokenId) == address(this) || dynamicNFT.isApprovedForAll(crafter, address(this)),
                "NFT transfer not approved");
        }

        // Add checks for required attributes on input NFTs if any...
        // Example: require(getNFTAttribute(inputNFTTokenIds[0], "durability") > 10, "Input NFT durability too low");


        // --- Consume Inputs ---
        // Consume Resource Tokens
        if (recipe.inputs.resourceTokenAmount > 0) {
            resourceToken.safeTransferFrom(crafter, address(this), recipe.inputs.resourceTokenAmount);
        }

        // Consume Input NFTs
        for (uint i = 0; i < inputNFTTokenIds.length; i++) {
             if (recipe.outputs.burnsInputNFTs) {
                // Requires the external DNFT contract to have a burn function accessible by this contract
                // dynamicNFT.burn(inputNFTTokenIds[i]); // Placeholder call
             } else {
                 // Transfer to contract or a specific address if not burned
                 dynamicNFT.safeTransferFrom(crafter, address(this), inputNFTTokenIds[i]);
             }
        }

        // --- Produce Outputs ---
        // Mint Resource Tokens
        if (recipe.outputs.resourceTokenAmount > 0) {
             // resourceToken.mint(crafter, recipe.outputs.resourceTokenAmount); // Requires minter role on token
        }

        // Mint Output NFTs
        for (uint i = 0; i < recipe.outputs.outputNFTTokenIds.length; i++) {
            uint256 outputTokenIdTemplate = recipe.outputs.outputNFTTokenIds[i];
             // This implies recipe output specifies *which* type of NFT to mint.
             // The DNFT contract would need a function like `mintBasedOnTemplate(address to, uint256 templateId)`
             // uint256 newOutputNFTId = dynamicNFT.mintBasedOnTemplate(crafter, outputTokenIdTemplate); // Placeholder call

            // Apply any attribute changes defined in the output to the newly minted NFT(s)
            // This requires iterating over the recipe.outputs.attributeChanges mapping (not possible directly)
            // The Recipe struct design needs adjustment if attribute changes are complex outcomes for new items.
            // For simplicity, let's assume simple item crafting doesn't change attributes much,
            // or it's handled by the minting template on the DNFT contract.
        }

        emit ItemCrafted(crafter, recipeId, recipe.outputs.resourceTokenAmount); // Emit event with relevant data
    }

    /**
     * @dev Executes an upgrade recipe to modify an existing NFT's attributes.
     * Consumes required resource tokens and input item NFTs.
     * Modifies the attributes of the target NFT (`tokenIdToUpgrade`).
     * @param tokenIdToUpgrade The ID of the NFT to upgrade. Must be owned by the caller.
     * @param upgradeRecipeId The ID of the upgrade recipe to use.
     * @param inputItemTokenIds An array of token IDs for input item NFTs required by the recipe (these will be consumed).
     */
    function upgradeNFT(uint256 tokenIdToUpgrade, uint256 upgradeRecipeId, uint256[] memory inputItemTokenIds) public whenNotPaused nonReentrant {
        require(address(resourceToken) != address(0), "Resource token contract not set");
        require(address(dynamicNFT) != address(0), "NFT contract not set");

        CraftingRecipe storage recipe = _craftingRecipes[upgradeRecipeId];
        require(recipe.exists, InvalidCraftingRecipe(upgradeRecipeId));
        require(recipe.outputs.targetTokenIdIndex < inputItemTokenIds.length, InvalidRecipeTargetIndex(upgradeRecipeId, recipe.outputs.targetTokenIdIndex));
        require(inputItemTokenIds[recipe.outputs.targetTokenIdIndex] == tokenIdToUpgrade, TargetNFTRequiredForUpgrade());


        address uphrader = _msgSender();

        // Check ownership of the NFT to upgrade
        require(dynamicNFT.ownerOf(tokenIdToUpgrade) == uphrader, InputNFTNotOwned(tokenIdToUpgrade, uphrader));

        // --- Check Inputs (Similar to craftItem) ---
        // Check Resource Tokens
        if (recipe.inputs.resourceTokenAmount > 0) {
             require(resourceToken.balanceOf(uphrader) >= recipe.inputs.resourceTokenAmount,
                InsufficientResourceTokens(recipe.inputs.resourceTokenAmount, resourceToken.balanceOf(uphrader)));
        }

        // Check Input Item NFTs (excluding the target NFT)
        // The `inputItemTokenIds` array contains *all* inputs, including the target NFT at a specific index
        uint256[] memory actualInputItems = new uint256[](inputItemTokenIds.length - 1);
        uint256 itemIndex = 0;
        for (uint i = 0; i < inputItemTokenIds.length; i++) {
             uint256 inputTokenId = inputItemTokenIds[i];
             require(dynamicNFT.ownerOf(inputTokenId) == uphrader, InputNFTNotOwned(inputTokenId, uphrader));

            if (i != recipe.outputs.targetTokenIdIndex) {
                actualInputItems[itemIndex] = inputTokenId;
                 itemIndex++;
                // Require approval for item NFT transfers/burns
                 require(dynamicNFT.getApproved(inputTokenId) == address(this) || dynamicNFT.isApprovedForAll(uphrader, address(this)),
                    "Input item NFT transfer not approved");
            }
        }

        // Add checks for required attributes on input Item NFTs or the target NFT
        // Example: require(getNFTAttribute(tokenIdToUpgrade, "level") >= 5, "NFT level too low for upgrade");


        // --- Consume Inputs ---
        // Consume Resource Tokens
        if (recipe.inputs.resourceTokenAmount > 0) {
             resourceToken.safeTransferFrom(uphrader, address(this), recipe.inputs.resourceTokenAmount);
        }

        // Consume Input Item NFTs (burn or transfer)
        for (uint i = 0; i < actualInputItems.length; i++) {
             uint256 inputTokenId = actualInputItems[i];
              if (recipe.outputs.burnsInputNFTs) {
                // Requires burn function on DNFT contract
                // dynamicNFT.burn(inputTokenId); // Placeholder call
             } else {
                dynamicNFT.safeTransferFrom(uphrader, address(this), inputTokenId);
             }
        }

        // --- Apply Outputs (Modify target NFT attributes) ---
        // This requires iterating over the attributeChanges mapping in the recipe's output
        // Since mappings in memory structs are not supported, you'd likely pass attribute changes
        // as separate arrays or a more complex struct/data structure to the recipe.
        // Assuming a simplified approach where `attributeChanges` mapping is accessible/represented differently:

        // Example of applying attribute changes:
        // For each key-value pair in recipe.outputs.attributeChanges:
        // dynamicNFT.setAttribute(tokenIdToUpgrade, key, value); // Placeholder call
        // emit NFTAttributeUpdated(tokenIdToUpgrade, key, value);

        emit NFTUpgraded(uphrader, tokenIdToUpgrade, upgradeRecipeId);
    }

    // --- --- ERC721 Support (Required for receiving NFTs) --- ---

    /**
     * @dev See {IERC721Receiver-onERC721Received}.
     * This function is called by ERC721 contracts when an NFT is transferred to this contract.
     * It's essential for staking functionality.
     */
    function onERC721Received(address operator, address from, uint256 tokenId, bytes memory data) public virtual returns (bytes4) {
        // Optional: Add checks here if you only want to allow receiving NFTs
        // from specific senders or as part of specific operations (like staking).
        // Example: require(_stakedNFTOriginalOwner[tokenId] != address(0), "Only receive staked NFTs");
        return this.onERC721Received.selector;
    }

    // Fallback function to prevent receiving unintended Ether
    receive() external payable {
        revert("Direct ether transfers are not allowed");
    }

    fallback() external payable {
        revert("Direct calls or ether transfers are not allowed");
    }
}
```

**Explanation of Advanced Concepts & Design Choices:**

1.  **Dynamic NFTs:** The concept is handled by having the `DynamicAssetEcosystem` contract interact with a separate (hypothetical) `DynamicNFT` contract. This `DynamicNFT` contract would hold the actual attribute data in its own state and expose trusted functions (`setAttribute`, `getAttribute`, `mint`, `burn`) that *only* this `DynamicAssetEcosystem` contract (or accounts with specific roles granted by the DNFT contract) can call. This modularity is a key advanced pattern. The `triggerNFTStateUpdate` function allows user interaction to initiate attribute changes based on ecosystem logic (like time elapsed).
2.  **Separation of Concerns:** The ERC-20 and ERC-721 logic is kept in separate, external contracts. This contract focuses solely on the *ecosystem logic* (staking, crafting, attribute changes based on this logic). This makes the system more modular, easier to upgrade (if using proxies for the external tokens/NFTs), and safer.
3.  **Role-Based Access Control:** Using OpenZeppelin's `AccessControl` provides a robust and standard way to manage permissions for sensitive operations like minting, pausing, recipe management, and setting token/NFT addresses.
4.  **Staking for Multiple Asset Types:** The contract manages two separate staking mechanisms: one for the fungible Resource Token and one for the non-fungible Dynamic NFTs. This adds complexity in tracking different states (`_stakedResourceBalances`, `_stakedNFTOriginalOwner`, `_nftStakingStartTime`, `_nftStakingAccruedReward`) and calculating different reward types or rates.
5.  **Staking Reward Calculation:** Rewards are calculated based on time elapsed since the last update/stake action. This is a common staking pattern. The `_updateResourceStakingReward` and `_updateNFTStakingReward` internal helpers handle the calculation and distribution logic, which is called before unstaking or claiming.
6.  **Complex Crafting/Upgrading Logic:** The `CraftingRecipe` struct and the `craftItem`/`upgradeNFT` functions demonstrate complex input/output handling:
    *   Requires consuming both fungible (`resourceTokenAmount`) and non-fungible (`inputNFTTokenIds`) assets.
    *   Requires checking ownership and approval for input NFTs.
    *   Requires potentially checking *attributes* of input NFTs (commented placeholder).
    *   Outputs can include minting new Resource Tokens or new NFTs.
    *   Crucially for *upgrading*, the output involves modifying the attributes of a *specific input NFT* (`tokenIdToUpgrade`), requiring interaction with the external DNFT contract's trusted setter.
    *   The `CraftingRecipe` struct's design highlights a Solidity limitation (mappings in memory structs) and implies the need for careful external state management (e.g., how attribute changes are represented and applied).
7.  **`nonReentrant` Guard:** Used on functions that involve external calls (`safeTransferFrom`, `safeTransfer`) to prevent reentrancy attacks, especially important in staking and crafting where assets are moved.
8.  **Custom Errors:** Using `error` instead of `require` strings is more gas-efficient and provides clearer error messages off-chain (Solidity 0.8+ feature).
9.  **Pausable:** Standard but crucial security pattern for complex contracts to allow pausing operations in case of vulnerabilities or unexpected behavior.
10. **ERC721Receiver Implementation:** Required to safely receive NFTs when they are staked (`onERC721Received`).

This contract serves as a blueprint for a complex, interacting asset ecosystem, demonstrating how standard components and patterns can be combined in novel ways to create advanced on-chain logic. It assumes the existence and proper configuration of external ERC-20 and Dynamic ERC-721 contracts that grant necessary permissions to this ecosystem contract.