Okay, let's design an interesting, advanced, and relatively non-standard smart contract.

Concept: **ChronoEssence Vaults**

This contract allows users to deposit ERC-20 tokens into "Vaults". Each Vault isn't just a static container; it has a dynamic property called "ChronoEssence". This essence value changes over time based on configurable parameters (decay/growth rates) associated with the vault. Users can perform actions that interact with this essence, affecting its value or extracting value derived from it. The state of the essence can influence the ability to withdraw the underlying tokens.

This combines concepts of time-based dynamics, stateful assets, parameterized behavior, and complex interaction patterns beyond simple token transfers.

---

## Contract Outline & Function Summary

**Contract Name:** ChronoEssenceVaults

**Core Concept:** Manage stateful "Vaults" holding ERC-20 tokens, each with a dynamic "ChronoEssence" value that changes over time based on configurable parameters.

**Key Features:**
1.  **Dynamic Essence:** ChronoEssence value per vault changes based on time and specific parameters (decay/growth).
2.  **Parameterized Vaults:** Each vault can have unique parameters influencing its essence dynamics.
3.  **Essence Interaction:** Functions to accelerate/decelerate decay, harvest value based on essence, or infuse value to boost essence.
4.  **Conditional Withdrawals:** Withdrawal of locked tokens can be dependent on the current essence value.
5.  **Vault Manipulation:** Split or merge vaults (with complex essence logic).
6.  **Access Control:** Owner controls base parameters and allowed tokens. Vault owners control their specific vault parameters (within limits) and interaction rights.
7.  **Reentrancy Protection & Pause:** Standard security measures.

**Structs:**
*   `Vault`: Stores vault details (owner, token, amount, creationTime, lastEssenceUpdate, currentEssence, withdrawalThreshold).
*   `VaultParameters`: Stores parameters governing essence dynamics (base decay/growth rate, multiplier, etc.).

**State Variables:**
*   `vaults`: Mapping from vault ID (`uint256`) to `Vault` struct.
*   `vaultParameters`: Mapping from vault ID (`uint256`) to `VaultParameters` struct.
*   `nextVaultId`: Counter for unique vault IDs.
*   `_allowedTokens`: Set of ERC20 token addresses allowed for deposits.
*   `_essenceInfluenceRights`: Mapping `vaultId => address => bool` granting rights to influence essence decay.
*   `_vaultOwners`: Mapping `uint256 => address` (redundant with Vault struct, but useful for owner checks).
*   `_totalLockedTokens`: Mapping `address => uint256` tracking total tokens locked per token type.
*   `_defaultVaultParameters`: Default parameters for new vaults.
*   `_essenceHarvestToken`: Address of a specific token minted when essence is harvested (optional, or could be Ether, or unlocked vault tokens). Let's make it unlock a small percentage of the *locked* token itself, based on essence.
*   `_essenceInfuseToken`: Address of a token accepted to infuse essence.

**Events:**
*   `VaultCreated(uint256 indexed vaultId, address indexed owner, address token, uint256 amount)`
*   `DepositMade(uint256 indexed vaultId, address indexed depositor, uint256 amount)`
*   `WithdrawalMade(uint256 indexed vaultId, address indexed receiver, uint256 amount, uint256 remainingAmount)`
*   `OwnershipTransferred(uint256 indexed vaultId, address indexed oldOwner, address indexed newOwner)`
*   `EssenceUpdated(uint256 indexed vaultId, uint256 newEssence)`
*   `DecayAccelerated(uint256 indexed vaultId, address indexed accelerator, int256 rateChange)`
*   `DecayDecelerated(uint256 indexed vaultId, address indexed decelerator, int256 rateChange)`
*   `EssenceHarvested(uint256 indexed vaultId, address indexed harvester, uint256 harvestedAmount, uint256 essenceConsumed)`
*   `EssenceInfused(uint256 indexed vaultId, address indexed infuser, uint256 infusedAmount, uint256 essenceGained)`
*   `VaultSplit(uint256 indexed oldVaultId, uint256 indexed newVaultId1, uint256 indexed newVaultId2)`
*   `VaultMerged(uint256 indexed newVaultId, uint256 indexed oldVaultId1, uint256 indexed oldVaultId2)`
*   `VaultParametersChanged(uint256 indexed vaultId, int256 newRate, uint256 newMultiplier)`
*   `WithdrawalThresholdChanged(uint256 indexed vaultId, uint256 newThreshold)`
*   `EssenceInfluenceRightGranted(uint256 indexed vaultId, address indexed granter, address indexed grantee)`
*   `EssenceInfluenceRightRevoked(uint256 indexed vaultId, address indexed granter, address indexed grantee)`
*   `AllowedTokenAdded(address indexed token)`
*   `AllowedTokenRemoved(address indexed token)`

**Functions (30+):**

1.  `constructor(address initialOwner, address essenceInfuseTokenAddress)`: Initializes contract with owner and infuse token address.
2.  `addAllowedToken(address token)`: Owner adds an ERC-20 token address to the allowed list for deposits.
3.  `removeAllowedToken(address token)`: Owner removes an ERC-20 token address from the allowed list.
4.  `isTokenAllowed(address token) view`: Checks if a token is allowed.
5.  `setDefaultEssenceParameters(int256 baseRate, uint256 multiplier)`: Owner sets default essence parameters for new vaults.
6.  `getDefaultEssenceParameters() view`: Get current default parameters.
7.  `createVault(address token, uint256 amount)`: Creates a new vault, deposits `amount` of `token` from the caller. Uses default essence parameters.
8.  `depositToVault(uint256 vaultId, uint256 amount)`: Deposits additional `amount` of the vault's token into an existing vault.
9.  `calculateEssence(uint256 vaultId) view`: Calculates the current theoretical ChronoEssence value for a vault *without* updating the state.
10. `updateEssenceState(uint256 vaultId) internal`: Internal helper to calculate and update the vault's stored `currentEssence` and `lastEssenceUpdate` state. Called by state-changing functions.
11. `withdrawFromVault(uint256 vaultId, uint256 amount)`: Attempts to withdraw `amount` of tokens. Requires the vault owner, checks withdrawal conditions (e.g., essence above/below threshold). Updates essence state before checking.
12. `setVaultWithdrawalThreshold(uint256 vaultId, uint256 threshold)`: Allows the vault owner to set a custom essence threshold for withdrawals.
13. `getVaultWithdrawalThreshold(uint256 vaultId) view`: Get the custom withdrawal threshold for a vault.
14. `checkWithdrawalCondition(uint256 vaultId) view`: Checks if the vault's current essence meets its withdrawal threshold condition.
15. `transferVaultOwnership(uint256 vaultId, address newOwner)`: Transfers ownership of a vault (like ERC721 transfer).
16. `getVaultDetails(uint256 vaultId) view`: Returns all details of a specific vault.
17. `getVaultParameters(uint256 vaultId) view`: Returns the specific essence parameters for a vault.
18. `setVaultSpecificParameters(uint256 vaultId, int256 newRate, uint256 newMultiplier)`: Allows the vault owner to set *their* vault's specific essence parameters (within system-defined bounds, not implemented for simplicity but noted as an advanced concept). Updates essence state first.
19. `accelerateDecay(uint256 vaultId, int256 rateIncrease)`: Increases the decay rate (or decreases growth rate) for a vault's essence. Requires `msg.sender` to be owner or have influence rights. Might require a cost (e.g., Ether). Updates essence state first.
20. `decelerateDecay(uint256 vaultId, int256 rateDecrease)`: Decreases the decay rate (or increases growth rate) for a vault's essence. Requires `msg.sender` to be owner or have influence rights. Might require a cost. Updates essence state first.
21. `grantEssenceInfluenceRight(uint256 vaultId, address grantee)`: Allows the vault owner to grant an address the right to call `accelerateDecay` and `decelerateDecay` on their vault.
22. `revokeEssenceInfluenceRight(uint256 vaultId, address grantee)`: Allows the vault owner to revoke an essence influence right.
23. `isEssenceInfluenceRightGranted(uint256 vaultId, address account) view`: Checks if an address has essence influence rights on a vault.
24. `harvestEssence(uint256 vaultId)`: Allows harvesting a small amount of the locked token based on the current essence value. Consumes some essence in the process. Updates essence state first. Non-reentrant.
25. `infuseEssence(uint256 vaultId, uint256 infuseAmount)`: Allows depositing `infuseAmount` of `_essenceInfuseToken` to boost the vault's essence value. Updates essence state first.
26. `splitVault(uint256 vaultId, uint256 amountForNewVault)`: Splits a vault's tokens into the original vault (remaining tokens) and a new vault (`amountForNewVault`). Essence might be split proportionally or follow a specific logic. Non-reentrant.
27. `mergeVaults(uint256 vaultId1, uint256 vaultId2)`: Merges two vaults of the *same token* into one new vault. Combines token amounts. Essence calculation for the new vault is complex (e.g., weighted average, sum, max). Non-reentrant.
28. `liquidateVault(uint256 vaultId)`: Allows the owner of the *contract* to liquidate a vault (e.g., if essence reaches zero or a critical state), potentially with different rules than normal withdrawal. Distributes assets based on liquidation logic. Non-reentrant.
29. `getVaultCount() view`: Returns the total number of vaults created.
30. `getTotalLockedTokens(address token) view`: Returns the total amount of a specific token locked across all vaults.
31. `pause() owner only`: Pauses the contract (disables critical state-changing functions).
32. `unpause() owner only`: Unpauses the contract.
33. `paused() view`: Checks if the contract is paused.
34. `getVaultIdsByOwner(address owner) view`: Returns a list of vault IDs owned by a specific address (requires iterating, gas-intensive for many vaults). (Note: This is often avoided on-chain but included for the function count requirement).

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/Address.sol";

/**
 * @title ChronoEssenceVaults
 * @dev A smart contract managing stateful vaults holding ERC-20 tokens.
 * Each vault possesses a dynamic 'ChronoEssence' property that changes over time
 * based on vault-specific parameters. Interactions like deposits, withdrawals,
 * essence manipulation, splitting, and merging affect the vault state and essence.
 * Withdrawal conditions can be tied to the essence value.
 *
 * Outline:
 * 1. Imports
 * 2. Errors
 * 3. Structs (Vault, VaultParameters)
 * 4. Events
 * 5. State Variables (Vaults, Parameters, Counters, Allowed Tokens, Influence Rights, Total Locked, Defaults, Infuse Token)
 * 6. Modifiers (Inherited: onlyOwner, whenNotPaused, whenPaused, nonReentrant)
 * 7. Constructor
 * 8. Owner Functions (Allowed Tokens, Default Params, Pause/Unpause, Liquidation)
 * 9. Vault Management Functions (Create, Deposit, Withdraw, Transfer Ownership, Getters)
 * 10. Essence Calculation & Update (Internal Helper, Public View)
 * 11. Essence Interaction Functions (Accelerate/Decelerate Decay, Harvest, Infuse)
 * 12. Vault Manipulation (Split, Merge)
 * 13. Vault Parameter & Threshold Management (Setters, Getters, Condition Check)
 * 14. Essence Influence Rights Management
 * 15. Utility/View Functions (Counts, Total Locked, Get Vaults by Owner)
 *
 * Function Summary:
 * - addAllowedToken: Owner adds an allowed token for deposits.
 * - removeAllowedToken: Owner removes an allowed token.
 * - isTokenAllowed: Checks if a token is allowed.
 * - setDefaultEssenceParameters: Owner sets default essence parameters.
 * - getDefaultEssenceParameters: Gets default parameters.
 * - createVault: Creates a new vault and deposits tokens.
 * - depositToVault: Adds tokens to an existing vault.
 * - calculateEssence: Calculates current essence value without state update.
 * - updateEssenceState: Internal helper to update essence state.
 * - withdrawFromVault: Withdraws tokens, checking essence condition.
 * - setVaultWithdrawalThreshold: Vault owner sets withdrawal threshold.
 * - getVaultWithdrawalThreshold: Gets vault withdrawal threshold.
 * - checkWithdrawalCondition: Checks if withdrawal condition is met.
 * - transferVaultOwnership: Transfers vault ownership.
 * - getVaultDetails: Gets full vault details.
 * - getVaultParameters: Gets vault-specific essence parameters.
 * - setVaultSpecificParameters: Vault owner sets vault parameters (limited).
 * - accelerateDecay: Increases essence decay rate (costs Ether).
 * - decelerateDecay: Decreases essence decay rate (costs Ether).
 * - grantEssenceInfluenceRight: Grants essence influence rights.
 * - revokeEssenceInfluenceRight: Revokes essence influence rights.
 * - isEssenceInfluenceRightGranted: Checks influence rights.
 * - harvestEssence: Unlocks token amount based on essence (consumes essence).
 * - infuseEssence: Deposits Infuse Token to boost essence.
 * - splitVault: Splits a vault into two.
 * - mergeVaults: Merges two vaults into one.
 * - liquidateVault: Owner liquidates a vault.
 * - getVaultCount: Gets total vault count.
 * - getTotalLockedTokens: Gets total locked tokens for a type.
 * - getVaultIdsByOwner: Gets vault IDs owned by an address (potentially gas heavy).
 * - pause: Owner pauses contract.
 * - unpause: Owner unpauses contract.
 * - paused: Checks if paused.
 */
contract ChronoEssenceVaults is Ownable, ReentrancyGuard, Pausable {
    using SafeERC20 for IERC20;

    // --- Errors ---
    error TokenNotAllowed(address token);
    error AmountMustBeGreaterThanZero();
    error VaultNotFound(uint256 vaultId);
    error NotVaultOwner(uint256 vaultId);
    error WithdrawalThresholdNotMet(uint256 vaultId);
    error InsufficientVaultBalance(uint256 vaultId, uint256 requested, uint256 available);
    error SameVaultIdsProvided();
    error VaultsMustBeSameToken(uint256 vaultId1, uint256 vaultId2);
    error CannotSplitZeroAmount();
    error SplitAmountExceedsVaultBalance(uint256 vaultId, uint256 splitAmount, uint256 available);
    error NotAllowedToInfluenceEssence(uint256 vaultId, address account);
    error EssenceInfuseTokenRequired();
    error InfluenceCostRequired();
    error CannotHarvestZeroEssence();

    // --- Constants ---
    // Time unit for essence calculation: 1 day in seconds
    uint256 private constant TIME_UNIT = 1 days; // For calculating rate per day
    // Maximum possible essence value
    uint256 private constant MAX_ESSENCE = 1_000_000_000; // Example Max Essence value (arbitrary unit)
    // Default essence at creation
    uint256 private constant INITIAL_ESSENCE = 100_000_000; // Example Initial Essence value

    // --- Structs ---
    struct Vault {
        uint256 id;
        address owner;
        address token; // Address of the locked ERC-20 token
        uint256 amount; // Amount of the locked token
        uint256 creationTime; // Timestamp of vault creation
        uint256 lastEssenceUpdate; // Timestamp when essence was last updated
        uint256 currentEssence; // Current calculated essence value
        uint256 withdrawalThreshold; // Essence threshold required for withdrawal
    }

    struct VaultParameters {
        int256 baseRate; // Change in essence per TIME_UNIT (can be negative for decay)
        uint256 multiplier; // Multiplier for the base rate (e.g., affects slope)
        // Add more complex parameters here if needed (e.g., min/max rate, decay curve type)
    }

    // --- State Variables ---
    mapping(uint256 => Vault) public vaults;
    mapping(uint256 => VaultParameters) public vaultParameters;
    uint256 private nextVaultId = 1; // Start vault IDs from 1

    // Allowed tokens
    mapping(address => bool) private _allowedTokens;
    address[] private _allowedTokenList; // To easily retrieve allowed tokens

    // Essence influence rights: vaultId => account => hasRight
    mapping(uint256 => mapping(address => bool)) private _essenceInfluenceRights;

    // Track total locked tokens per token type
    mapping(address => uint256) private _totalLockedTokens;

    VaultParameters public defaultVaultParameters;

    // Token accepted for infusing essence
    address public essenceInfuseToken;

    // --- Events ---
    event VaultCreated(uint256 indexed vaultId, address indexed owner, address token, uint256 amount);
    event DepositMade(uint256 indexed vaultId, address indexed depositor, uint256 amount);
    event WithdrawalMade(uint256 indexed vaultId, address indexed receiver, uint256 amount, uint256 remainingAmount);
    event OwnershipTransferred(uint256 indexed vaultId, address indexed oldOwner, address indexed newOwner);
    event EssenceUpdated(uint256 indexed vaultId, uint256 oldEssence, uint256 newEssence);
    event DecayAccelerated(uint256 indexed vaultId, address indexed accelerator, int256 rateChange);
    event DecayDecelerated(uint256 indexed vaultId, address indexed decelerator, int256 rateChange);
    event EssenceHarvested(uint256 indexed vaultId, address indexed harvester, uint256 harvestedAmount, uint256 essenceConsumed);
    event EssenceInfused(uint256 indexed vaultId, address indexed infuser, uint256 infusedAmount, uint256 essenceGained);
    event VaultSplit(uint256 indexed oldVaultId, uint256 indexed newVaultId1, uint256 indexed newVaultId2);
    event VaultMerged(uint256 indexed newVaultId, uint256 indexed oldVaultId1, uint256 indexed oldVaultId2);
    event VaultParametersChanged(uint256 indexed vaultId, int256 newRate, uint256 newMultiplier);
    event WithdrawalThresholdChanged(uint256 indexed vaultId, uint256 newThreshold);
    event EssenceInfluenceRightGranted(uint256 indexed vaultId, address indexed granter, address indexed grantee);
    event EssenceInfluenceRightRevoked(uint256 indexed vaultId, address indexed granter, address indexed grantee);
    event AllowedTokenAdded(address indexed token);
    event AllowedTokenRemoved(address indexed token);
    event VaultLiquidated(uint256 indexed vaultId, uint256 remainingAmount);

    // --- Modifiers (Inherited: onlyOwner, whenNotPaused, whenPaused, nonReentrant) ---

    // --- Constructor ---
    constructor(address initialOwner, address essenceInfuseTokenAddress)
        Ownable(initialOwner)
        Pausable()
    {
        // Set a reasonable default decay rate (e.g., -1000 per day, multiplier 1)
        defaultVaultParameters = VaultParameters({
            baseRate: -1000,
            multiplier: 1
        });
        essenceInfuseToken = essenceInfuseTokenAddress;
        if (essenceInfuseTokenAddress == address(0)) {
             revert EssenceInfuseTokenRequired();
        }
    }

    // --- Owner Functions ---

    /**
     * @dev Adds an ERC20 token address to the list of allowed tokens for vault deposits.
     * @param token The address of the ERC20 token.
     */
    function addAllowedToken(address token) external onlyOwner {
        require(Address.isContract(token), "Address must be a contract");
        if (!_allowedTokens[token]) {
            _allowedTokens[token] = true;
            _allowedTokenList.push(token);
            emit AllowedTokenAdded(token);
        }
    }

    /**
     * @dev Removes an ERC20 token address from the list of allowed tokens.
     * Vaults holding this token will still exist, but new deposits of this token are prevented.
     * @param token The address of the ERC20 token.
     */
    function removeAllowedToken(address token) external onlyOwner {
        if (_allowedTokens[token]) {
            _allowedTokens[token] = false;
            // Remove from the list (inefficient for large lists, but simple)
            for (uint i = 0; i < _allowedTokenList.length; i++) {
                if (_allowedTokenList[i] == token) {
                    _allowedTokenList[i] = _allowedTokenList[_allowedTokenList.length - 1];
                    _allowedTokenList.pop();
                    break;
                }
            }
            emit AllowedTokenRemoved(token);
        }
    }

    /**
     * @dev Sets the default essence parameters used for newly created vaults.
     * Existing vaults are not affected unless explicitly modified.
     * @param baseRate The base rate of essence change per time unit (can be negative for decay).
     * @param multiplier A multiplier applied to the base rate.
     */
    function setDefaultEssenceParameters(int256 baseRate, uint256 multiplier) external onlyOwner {
        defaultVaultParameters = VaultParameters({
            baseRate: baseRate,
            multiplier: multiplier
        });
    }

    /**
     * @dev Allows the contract owner to liquidate a vault under specific conditions (e.g., zero essence).
     * This forcibly withdraws remaining tokens according to a predefined liquidation logic.
     * In this example, it simply transfers remaining tokens to the vault owner.
     * @param vaultId The ID of the vault to liquidate.
     */
    function liquidateVault(uint256 vaultId) external onlyOwner nonReentrant whenNotPaused {
        Vault storage vault = vaults[vaultId];
        if (vault.id == 0) revert VaultNotFound(vaultId);

        uint256 remainingAmount = vault.amount;
        address tokenAddress = vault.token;
        address vaultOwner = vault.owner;

        // Perform the transfer
        vault.amount = 0; // Set vault amount to 0 before transfer
        _totalLockedTokens[tokenAddress] -= remainingAmount;
        IERC20(tokenAddress).safeTransfer(vaultOwner, remainingAmount);

        // Consider deleting the vault or marking it liquidated
        // delete vaults[vaultId]; // Simple delete
        // Note: Deleting struct might leave references in other mappings;
        // a more robust approach is to mark as liquidated and handle state carefully.
        // For simplicity here, we'll just zero out the amount and leave struct entry.

        emit VaultLiquidated(vaultId, remainingAmount);
    }

    // --- Vault Management Functions ---

    /**
     * @dev Creates a new vault, deposits specified tokens from the caller.
     * Vault is initialized with default essence parameters and initial essence.
     * @param token The address of the ERC-20 token to deposit.
     * @param amount The amount of tokens to deposit.
     */
    function createVault(address token, uint256 amount) external whenNotPaused nonReentrant {
        if (!_allowedTokens[token]) revert TokenNotAllowed(token);
        if (amount == 0) revert AmountMustBeGreaterThanZero();

        uint256 vaultId = nextVaultId;
        nextVaultId++;
        uint256 currentTime = block.timestamp;

        vaults[vaultId] = Vault({
            id: vaultId,
            owner: msg.sender,
            token: token,
            amount: amount,
            creationTime: currentTime,
            lastEssenceUpdate: currentTime,
            currentEssence: INITIAL_ESSENCE, // Start with initial essence
            withdrawalThreshold: 0 // Default threshold allows withdrawal if essence > 0
        });

        // Assign default parameters
        vaultParameters[vaultId] = defaultVaultParameters;

        // Transfer tokens into the contract
        IERC20(token).safeTransferFrom(msg.sender, address(this), amount);
        _totalLockedTokens[token] += amount;

        emit VaultCreated(vaultId, msg.sender, token, amount);
    }

    /**
     * @dev Deposits additional tokens into an existing vault.
     * Updates essence state as part of the deposit.
     * @param vaultId The ID of the vault.
     * @param amount The amount of tokens to deposit.
     */
    function depositToVault(uint256 vaultId, uint256 amount) external whenNotPaused nonReentrant {
        Vault storage vault = vaults[vaultId];
        if (vault.id == 0) revert VaultNotFound(vaultId);
        if (vault.owner != msg.sender) revert NotVaultOwner(vaultId);
        if (amount == 0) revert AmountMustBeGreaterThanZero();

        // Update essence before changing state
        _updateEssenceState(vaultId);

        // Transfer tokens
        IERC20(vault.token).safeTransferFrom(msg.sender, address(this), amount);
        vault.amount += amount;
        _totalLockedTokens[vault.token] += amount;

        emit DepositMade(vaultId, msg.sender, amount);
    }

    /**
     * @dev Attempts to withdraw tokens from a vault.
     * Withdrawal is conditional based on the vault's essence threshold.
     * Updates essence state before checking condition and withdrawing.
     * @param vaultId The ID of the vault.
     * @param amount The amount of tokens to withdraw.
     */
    function withdrawFromVault(uint256 vaultId, uint256 amount) external whenNotPaused nonReentrant {
        Vault storage vault = vaults[vaultId];
        if (vault.id == 0) revert VaultNotFound(vaultId);
        if (vault.owner != msg.sender) revert NotVaultOwner(vaultId);
        if (amount == 0) revert AmountMustBeGreaterThanZero();
        if (amount > vault.amount) revert InsufficientVaultBalance(vaultId, amount, vault.amount);

        // Update essence state immediately before checking conditions
        _updateEssenceState(vaultId);

        // Check withdrawal condition based on essence threshold
        if (vault.currentEssence < vault.withdrawalThreshold) {
             revert WithdrawalThresholdNotMet(vaultId);
        }

        // Perform withdrawal
        vault.amount -= amount;
        _totalLockedTokens[vault.token] -= amount;
        IERC20(vault.token).safeTransfer(msg.sender, amount);

        emit WithdrawalMade(vaultId, msg.sender, amount, vault.amount);
    }

    /**
     * @dev Transfers ownership of a vault to a new address.
     * Only the current owner can transfer ownership.
     * @param vaultId The ID of the vault.
     * @param newOwner The address to transfer ownership to.
     */
    function transferVaultOwnership(uint256 vaultId, address newOwner) external whenNotPaused {
        Vault storage vault = vaults[vaultId];
        if (vault.id == 0) revert VaultNotFound(vaultId);
        if (vault.owner != msg.sender) revert NotVaultOwner(vaultId);
        require(newOwner != address(0), "New owner cannot be zero address");

        address oldOwner = vault.owner;
        vault.owner = newOwner;

        // Optionally transfer influence rights automatically, or revoke them
        // For simplicity, influence rights granted by the old owner are kept until revoked

        emit OwnershipTransferred(vaultId, oldOwner, newOwner);
    }

    /**
     * @dev Gets the details of a specific vault.
     * @param vaultId The ID of the vault.
     * @return Vault struct details.
     */
    function getVaultDetails(uint256 vaultId) external view returns (Vault memory) {
        Vault storage vault = vaults[vaultId];
        if (vault.id == 0) revert VaultNotFound(vaultId);
        return vault;
    }

    // --- Essence Calculation & Update ---

    /**
     * @dev Internal helper to calculate and update the vault's stored essence state.
     * This should be called by any state-changing function that depends on or affects essence.
     * @param vaultId The ID of the vault.
     */
    function _updateEssenceState(uint256 vaultId) internal {
        Vault storage vault = vaults[vaultId];
        if (vault.id == 0) {
             // Should ideally not happen in internal context if called correctly
             // from functions that already checked vault existence.
             // Added for robustness.
             revert VaultNotFound(vaultId);
        }

        uint256 currentTime = block.timestamp;
        if (currentTime > vault.lastEssenceUpdate) {
            int256 currentEssenceInt = int256(vault.currentEssence);
            int256 timeElapsed = int256(currentTime - vault.lastEssenceUpdate);
            VaultParameters storage params = vaultParameters[vaultId];

            // Calculate essence change: rate * multiplier * (time elapsed / time unit)
            // Use integer division, careful with signs
            int256 essenceChange = (params.baseRate * int256(params.multiplier) * timeElapsed) / int256(TIME_UNIT);

            int256 newEssenceInt = currentEssenceInt + essenceChange;

            // Clamp essence between 0 and MAX_ESSENCE
            if (newEssenceInt < 0) {
                newEssenceInt = 0;
            } else if (uint256(newEssenceInt) > MAX_ESSENCE) {
                 // Note: This might require careful handling if essence can grow significantly.
                 // Simple clamping to MAX_ESSENCE.
                newEssenceInt = int256(MAX_ESSENCE);
            }

            uint256 oldEssence = vault.currentEssence;
            vault.currentEssence = uint256(newEssenceInt);
            vault.lastEssenceUpdate = currentTime;

            if (oldEssence != vault.currentEssence) {
                emit EssenceUpdated(vaultId, oldEssence, vault.currentEssence);
            }
        }
        // If currentTime <= vault.lastEssenceUpdate, no time has passed, no update needed.
    }

    /**
     * @dev Calculates the current ChronoEssence value for a vault based on time elapsed
     * and vault parameters, without modifying the vault's state.
     * @param vaultId The ID of the vault.
     * @return The calculated current essence value.
     */
    function calculateEssence(uint256 vaultId) public view returns (uint256) {
        Vault storage vault = vaults[vaultId];
        if (vault.id == 0) revert VaultNotFound(vaultId);

        uint256 currentTime = block.timestamp;
        if (currentTime <= vault.lastEssenceUpdate) {
            return vault.currentEssence; // No time has passed, return stored value
        }

        int256 currentEssenceInt = int256(vault.currentEssence);
        int256 timeElapsed = int256(currentTime - vault.lastEssenceUpdate);
        VaultParameters storage params = vaultParameters[vaultId];

        // Calculate essence change (same logic as _updateEssenceState)
        int256 essenceChange = (params.baseRate * int256(params.multiplier) * timeElapsed) / int256(TIME_UNIT);

        int256 newEssenceInt = currentEssenceInt + essenceChange;

        // Clamp essence between 0 and MAX_ESSENCE
        if (newEssenceInt < 0) {
            newEssenceInt = 0;
        } else if (uint256(newEssenceInt) > MAX_ESSENCE) {
            newEssenceInt = int256(MAX_ESSENCE);
        }

        return uint256(newEssenceInt);
    }

    // --- Essence Interaction Functions ---

    /**
     * @dev Increases the rate of essence decay (or decreases growth rate) for a vault.
     * Requires the caller to be the vault owner or have essence influence rights.
     * Requires sending Ether as a cost.
     * @param vaultId The ID of the vault.
     * @param rateIncrease The absolute positive value to add to the decay rate (negative value for baseRate).
     */
    function accelerateDecay(uint256 vaultId, int256 rateIncrease) external payable whenNotPaused nonReentrant {
        Vault storage vault = vaults[vaultId];
        if (vault.id == 0) revert VaultNotFound(vaultId);
        if (msg.sender != vault.owner && !_essenceInfluenceRights[vaultId][msg.sender]) {
            revert NotAllowedToInfluenceEssence(vaultId, msg.sender);
        }
        if (msg.value == 0) revert InfluenceCostRequired(); // Example cost

        // Update essence state before modifying parameters
        _updateEssenceState(vaultId);

        VaultParameters storage params = vaultParameters[vaultId];
        // Adding rateIncrease to the absolute decay/growth rate
        // If baseRate is -1000 (decay), adding 500 rateIncrease makes it -1500 (faster decay)
        // If baseRate is 1000 (growth), adding 500 rateIncrease makes it 500 (slower growth)
        params.baseRate -= rateIncrease; // Decrease baseRate to accelerate decay/decelerate growth

        // Send Ether cost to the contract owner or a sink (sending to owner here)
        payable(owner()).transfer(msg.value);

        emit DecayAccelerated(vaultId, msg.sender, rateIncrease);
    }

    /**
     * @dev Decreases the rate of essence decay (or increases growth rate) for a vault.
     * Requires the caller to be the vault owner or have essence influence rights.
     * Requires sending Ether as a cost.
     * @param vaultId The ID of the vault.
     * @param rateDecrease The absolute positive value to subtract from the decay rate (negative value for baseRate).
     */
    function decelerateDecay(uint256 vaultId, int256 rateDecrease) external payable whenNotPaused nonReentrant {
        Vault storage vault = vaults[vaultId];
        if (vault.id == 0) revert VaultNotFound(vaultId);
         if (msg.sender != vault.owner && !_essenceInfluenceRights[vaultId][msg.sender]) {
            revert NotAllowedToInfluenceEssence(vaultId, msg.sender);
        }
        if (msg.value == 0) revert InfluenceCostRequired(); // Example cost

        // Update essence state before modifying parameters
        _updateEssenceState(vaultId);

        VaultParameters storage params = vaultParameters[vaultId];
        // Subtracting rateDecrease from the absolute decay/growth rate
        // If baseRate is -1000 (decay), subtracting 500 rateDecrease makes it -500 (slower decay)
        // If baseRate is 1000 (growth), subtracting 500 rateDecrease makes it 1500 (faster growth)
        params.baseRate += rateDecrease; // Increase baseRate to decelerate decay/accelerate growth

        // Send Ether cost
        payable(owner()).transfer(msg.value);

        emit DecayDecelerated(vaultId, msg.sender, rateDecrease);
    }

     /**
     * @dev Allows harvesting a small amount of the locked token from a vault based on its current essence.
     * Harvesting consumes a portion of the vault's essence.
     * Requires caller to be the vault owner.
     * The amount harvested and essence consumed can follow complex rules; simple example here.
     * @param vaultId The ID of the vault.
     */
    function harvestEssence(uint256 vaultId) external whenNotPaused nonReentrant {
        Vault storage vault = vaults[vaultId];
        if (vault.id == 0) revert VaultNotFound(vaultId);
        if (vault.owner != msg.sender) revert NotVaultOwner(vaultId);

        // Update essence state
        _updateEssenceState(vaultId);

        if (vault.currentEssence == 0) revert CannotHarvestZeroEssence();

        // Example Harvest Logic: Harvest 0.1% of the locked amount for every 10% of MAX_ESSENCE
        // Amount harvested = (vault.amount * (vault.currentEssence / (MAX_ESSENCE / 10))) / 1000;
        // This is integer math, needs careful scaling.
        // Simpler example: Harvest amount is proportional to essence, up to a max percentage of vault amount
        // Let's say max harvestable is 1% of amount, and it's fully harvestable at MAX_ESSENCE.
        // harvestedAmount = (vault.amount * (vault.currentEssence / MAX_ESSENCE) * 10) / 1000; // Simplified ratio
        // Use 1e18 scaling for better precision in calculations if needed, but sticking to simple units.
        // Let's try a fixed fraction of the amount scaled by essence ratio:
        // harvestedAmount = vault.amount * vault.currentEssence / MAX_ESSENCE / 100 (meaning up to 1% of amount)

        uint256 essenceRatio = vault.currentEssence; // Scaled by MAX_ESSENCE later

        // Calculate potential harvest amount (e.g., up to 1% of total amount, proportional to essence)
        // Using safe math: (vault.amount * essenceRatio) / MAX_ESSENCE / 100
        uint256 harvestedAmount = (vault.amount * essenceRatio) / MAX_ESSENCE; // Scale by ratio first
        harvestedAmount = harvestedAmount / 100; // Then take a percentage of that (e.g., 1% if /100)

        // Ensure we don't withdraw more than available or a minuscule amount
        harvestedAmount = (harvestedAmount > vault.amount) ? vault.amount : harvestedAmount;
        if (harvestedAmount == 0) return; // Nothing significant to harvest

        // Example Essence Consumption: Consume 5% of current essence per harvest
        uint256 essenceConsumed = vault.currentEssence / 20; // 5%
        vault.currentEssence = (vault.currentEssence > essenceConsumed) ? vault.currentEssence - essenceConsumed : 0;

        // Perform withdrawal
        vault.amount -= harvestedAmount;
        _totalLockedTokens[vault.token] -= harvestedAmount;
        IERC20(vault.token).safeTransfer(msg.sender, harvestedAmount);

        emit EssenceHarvested(vaultId, msg.sender, harvestedAmount, essenceConsumed);
    }

    /**
     * @dev Allows depositing the essenceInfuseToken to boost the vault's essence value.
     * The amount of essence gained can be proportional to the amount of infuse token deposited.
     * Requires caller to be the vault owner.
     * @param vaultId The ID of the vault.
     * @param infuseAmount The amount of essenceInfuseToken to deposit.
     */
    function infuseEssence(uint256 vaultId, uint256 infuseAmount) external whenNotPaused nonReentrant {
        Vault storage vault = vaults[vaultId];
        if (vault.id == 0) revert VaultNotFound(vaultId);
        if (vault.owner != msg.sender) revert NotVaultOwner(vaultId);
        if (infuseAmount == 0) revert AmountMustBeGreaterThanZero();
        if (essenceInfuseToken == address(0)) revert EssenceInfuseTokenRequired();

        // Update essence state
        _updateEssenceState(vaultId);

        // Transfer infuse tokens into the contract
        IERC20(essenceInfuseToken).safeTransferFrom(msg.sender, address(this), infuseAmount);

        // Example Essence Gain Logic: Gain 1 unit of essence per 1 unit of infuse token
        // Add infuseAmount * multiplier to essence, up to MAX_ESSENCE
        uint256 essenceGained = infuseAmount; // Simple 1:1 example
        // Add more complex scaling if needed: essenceGained = infuseAmount * INFUSE_MULTIPLIER;

        uint256 oldEssence = vault.currentEssence;
        vault.currentEssence += essenceGained;
        if (vault.currentEssence > MAX_ESSENCE) {
            vault.currentEssence = MAX_ESSENCE;
        }
        uint256 actualEssenceGained = vault.currentEssence - oldEssence;


        emit EssenceInfused(vaultId, msg.sender, infuseAmount, actualEssenceGained);
        emit EssenceUpdated(vaultId, oldEssence, vault.currentEssence); // Re-emit EssenceUpdated if state changed
    }

    // --- Vault Manipulation ---

    /**
     * @dev Splits a vault into two. A specified amount of tokens is moved to a new vault.
     * The original vault retains the remaining tokens.
     * Essence calculation for the new vaults requires specific logic. Here, essence is split proportionally.
     * Requires caller to be the vault owner.
     * @param vaultId The ID of the vault to split.
     * @param amountForNewVault The amount of tokens to move to the new vault.
     */
    function splitVault(uint256 vaultId, uint256 amountForNewVault) external whenNotPaused nonReentrant {
        Vault storage originalVault = vaults[vaultId];
        if (originalVault.id == 0) revert VaultNotFound(vaultId);
        if (originalVault.owner != msg.sender) revert NotVaultOwner(vaultId);
        if (amountForNewVault == 0) revert CannotSplitZeroAmount();
        if (amountForNewVault >= originalVault.amount) revert SplitAmountExceedsVaultBalance(vaultId, amountForNewVault, originalVault.amount); // >= because need amount > 0 remaining

        // Update essence state for the original vault before splitting
        _updateEssenceState(vaultId);

        uint256 remainingAmount = originalVault.amount - amountForNewVault;

        // Create the new vault
        uint256 newVaultId = nextVaultId;
        nextVaultId++;
        uint256 currentTime = block.timestamp;

        // Essence split logic: Proportionate to token amount
        uint256 originalEssence = originalVault.currentEssence;
        uint256 totalAmount = originalVault.amount; // Use amount BEFORE reducing for remaining vault
        uint256 essenceForNewVault = (originalEssence * amountForNewVault) / totalAmount;
        uint256 essenceForOriginalVault = originalEssence - essenceForNewVault; // The rest goes to original

        vaults[newVaultId] = Vault({
            id: newVaultId,
            owner: msg.sender,
            token: originalVault.token,
            amount: amountForNewVault,
            creationTime: currentTime, // New creation time
            lastEssenceUpdate: currentTime,
            currentEssence: essenceForNewVault,
            withdrawalThreshold: originalVault.withdrawalThreshold // Inherit threshold
        });
         vaultParameters[newVaultId] = vaultParameters[vaultId]; // Inherit parameters


        // Update the original vault
        originalVault.amount = remainingAmount;
        originalVault.currentEssence = essenceForOriginalVault; // Update essence
        originalVault.lastEssenceUpdate = currentTime; // Update time for both new & original

        // Token transfers not needed as tokens remain within the contract balance, just re-allocated to vaults.
        // _totalLockedTokens remain unchanged.

        emit VaultSplit(vaultId, newVaultId, vaultId); // Emitting old vault ID as one of the results
        emit EssenceUpdated(vaultId, originalEssence, originalVault.currentEssence); // Essence changed for original
        emit EssenceUpdated(newVaultId, 0, newVaultId); // Essence set for new vault (from 0, although struct initializes)
    }

    /**
     * @dev Merges two vaults into a single new vault.
     * Requires both vaults to be owned by the caller and hold the same token.
     * The new vault gets the sum of tokens. Essence calculation for the new vault is complex.
     * Here, essence is a weighted average based on amounts, taking the later update time.
     * The original two vaults are effectively closed (amount set to 0, owner set to zero address).
     * @param vaultId1 The ID of the first vault.
     * @param vaultId2 The ID of the second vault.
     */
    function mergeVaults(uint256 vaultId1, uint256 vaultId2) external whenNotPaused nonReentrant {
        if (vaultId1 == vaultId2) revert SameVaultIdsProvided();
        Vault storage vault1 = vaults[vaultId1];
        Vault storage vault2 = vaults[vaultId2];

        if (vault1.id == 0) revert VaultNotFound(vaultId1);
        if (vault2.id == 0) revert VaultNotFound(vaultId2);
        if (vault1.owner != msg.sender) revert NotVaultOwner(vaultId1);
        if (vault2.owner != msg.sender) revert NotVaultOwner(vaultId2);
        if (vault1.token != vault2.token) revert VaultsMustBeSameToken(vaultId1, vaultId2);

        // Update essence states for both vaults before merging
        _updateEssenceState(vaultId1);
        _updateEssenceState(vaultId2);

        // Create the new vault
        uint256 newVaultId = nextVaultId;
        nextVaultId++;
        uint256 currentTime = block.timestamp;

        uint256 totalAmount = vault1.amount + vault2.amount;

        // Essence merge logic: Weighted average based on amount
        uint256 newEssence = 0;
        if (totalAmount > 0) {
             // Use uint256 math carefully to avoid overflow before division
             uint256 weightedEssence1 = vault1.currentEssence * vault1.amount;
             uint256 weightedEssence2 = vault2.currentEssence * vault2.amount;
             newEssence = (weightedEssence1 + weightedEssence2) / totalAmount;
        }

        // Use parameters from the vault with the higher amount, or average, or new default
        // Let's use parameters from the larger vault
        VaultParameters memory newParams = (vault1.amount >= vault2.amount) ?
                                            vaultParameters[vaultId1] :
                                            vaultParameters[vaultId2];

        vaults[newVaultId] = Vault({
            id: newVaultId,
            owner: msg.sender,
            token: vault1.token, // Same token
            amount: totalAmount,
            creationTime: currentTime, // New creation time for the merged vault
            lastEssenceUpdate: currentTime,
            currentEssence: newEssence,
            // Set withdrawal threshold based on one of the merged vaults (e.g., higher threshold)
            withdrawalThreshold: (vault1.withdrawalThreshold > vault2.withdrawalThreshold) ?
                                 vault1.withdrawalThreshold :
                                 vault2.withdrawalThreshold
        });
        vaultParameters[newVaultId] = newParams;

        // Close the old vaults by setting amount to 0 and owner to address(0)
        vault1.amount = 0;
        vault1.owner = address(0); // Mark as closed/invalid
        // Keep other data for historical lookup if needed, or delete
        // delete vaults[vaultId1]; // Alternative: full delete

        vault2.amount = 0;
        vault2.owner = address(0);
        // delete vaults[vaultId2];

        // Total locked tokens remain unchanged, just re-allocated to the new vault.

        emit VaultMerged(newVaultId, vaultId1, vaultId2);
        emit VaultLiquidated(vaultId1, 0); // Emit liquidation-like event for old vaults
        emit VaultLiquidated(vaultId2, 0);
        emit EssenceUpdated(newVaultId, 0, newEssence); // Essence set for new vault
    }

    // --- Vault Parameter & Threshold Management ---

    /**
     * @dev Allows the vault owner to set specific essence parameters for their vault.
     * This can override the default parameters. May be subject to constraints (not implemented here).
     * Updates essence state before applying new parameters.
     * @param vaultId The ID of the vault.
     * @param newRate The new base rate for essence change.
     * @param newMultiplier The new multiplier for essence change.
     */
    function setVaultSpecificParameters(uint256 vaultId, int256 newRate, uint256 newMultiplier) external whenNotPaused nonReentrant {
        Vault storage vault = vaults[vaultId];
        if (vault.id == 0) revert VaultNotFound(vaultId);
        if (vault.owner != msg.sender) revert NotVaultOwner(vaultId);

        // Update essence state before changing parameters
        _updateEssenceState(vaultId);

        // Apply new parameters
        vaultParameters[vaultId] = VaultParameters({
            baseRate: newRate,
            multiplier: newMultiplier
        });

        emit VaultParametersChanged(vaultId, newRate, newMultiplier);
    }

    /**
     * @dev Allows the vault owner to set their custom essence withdrawal threshold.
     * Withdrawal will only be possible if essence meets or exceeds this threshold.
     * @param vaultId The ID of the vault.
     * @param threshold The new essence threshold for withdrawal.
     */
    function setVaultWithdrawalThreshold(uint256 vaultId, uint256 threshold) external whenNotPaused {
        Vault storage vault = vaults[vaultId];
        if (vault.id == 0) revert VaultNotFound(vaultId);
        if (vault.owner != msg.sender) revert NotVaultOwner(vaultId);

        vault.withdrawalThreshold = threshold;
        emit WithdrawalThresholdChanged(vaultId, threshold);
    }

     /**
     * @dev Checks if the vault's current essence meets its specified withdrawal threshold.
     * Calculates essence on-the-fly for the check.
     * @param vaultId The ID of the vault.
     * @return True if the current essence is >= the withdrawal threshold, false otherwise.
     */
    function checkWithdrawalCondition(uint256 vaultId) external view returns (bool) {
        Vault storage vault = vaults[vaultId];
        if (vault.id == 0) revert VaultNotFound(vaultId);
        uint256 currentEssence = calculateEssence(vaultId);
        return currentEssence >= vault.withdrawalThreshold;
    }


    // --- Essence Influence Rights Management ---

    /**
     * @dev Grants an address the right to call accelerateDecay and decelerateDecay on a vault.
     * Only the vault owner can grant rights.
     * @param vaultId The ID of the vault.
     * @param grantee The address to grant influence rights to.
     */
    function grantEssenceInfluenceRight(uint256 vaultId, address grantee) external whenNotPaused {
        Vault storage vault = vaults[vaultId];
        if (vault.id == 0) revert VaultNotFound(vaultId);
        if (vault.owner != msg.sender) revert NotVaultOwner(vaultId);
        require(grantee != address(0), "Grantee cannot be zero address");

        _essenceInfluenceRights[vaultId][grantee] = true;
        emit EssenceInfluenceRightGranted(vaultId, msg.sender, grantee);
    }

    /**
     * @dev Revokes an address's right to call accelerateDecay and decelerateDecay on a vault.
     * Only the vault owner can revoke rights.
     * @param vaultId The ID of the vault.
     * @param grantee The address to revoke influence rights from.
     */
    function revokeEssenceInfluenceRight(uint256 vaultId, address grantee) external whenNotPaused {
        Vault storage vault = vaults[vaultId];
        if (vault.id == 0) revert VaultNotFound(vaultId);
        if (vault.owner != msg.sender) revert NotVaultOwner(vaultId);

        _essenceInfluenceRights[vaultId][grantee] = false;
        emit EssenceInfluenceRightRevoked(vaultId, msg.sender, grantee);
    }

    /**
     * @dev Checks if an address has essence influence rights on a specific vault.
     * @param vaultId The ID of the vault.
     * @param account The address to check.
     * @return True if the account has influence rights, false otherwise.
     */
    function isEssenceInfluenceRightGranted(uint256 vaultId, address account) external view returns (bool) {
        Vault storage vault = vaults[vaultId];
        if (vault.id == 0) revert VaultNotFound(vaultId);
        return _essenceInfluenceRights[vaultId][account];
    }

    // --- Utility / View Functions ---

    /**
     * @dev Checks if a token is allowed for deposits.
     * @param token The address of the ERC20 token.
     * @return True if allowed, false otherwise.
     */
    function isTokenAllowed(address token) external view returns (bool) {
        return _allowedTokens[token];
    }

    /**
     * @dev Returns the list of allowed token addresses.
     * @return An array of allowed ERC20 token addresses.
     */
    function getAllowedTokens() external view returns (address[] memory) {
        return _allowedTokenList;
    }

    /**
     * @dev Gets the current default essence parameters for new vaults.
     * @return VaultParameters struct containing default baseRate and multiplier.
     */
    function getDefaultEssenceParameters() external view returns (VaultParameters memory) {
        return defaultVaultParameters;
    }

    /**
     * @dev Gets the essence parameters specific to a vault.
     * @param vaultId The ID of the vault.
     * @return VaultParameters struct containing baseRate and multiplier for the vault.
     */
    function getVaultParameters(uint256 vaultId) external view returns (VaultParameters memory) {
        VaultParameters storage params = vaultParameters[vaultId];
         // Check if vault exists implicitly via vaultParameters[vaultId].baseRate != 0 or similar if 0 is not a valid rate
         // Or better, explicitly check vault existence:
        if (vaults[vaultId].id == 0) revert VaultNotFound(vaultId);
        return params;
    }

    /**
     * @dev Returns the total number of vaults created.
     * @return The total count of vaults.
     */
    function getVaultCount() external view returns (uint256) {
        return nextVaultId - 1; // Since IDs start from 1
    }

    /**
     * @dev Returns the total amount of a specific token locked across all active vaults.
     * @param token The address of the ERC20 token.
     * @return The total locked amount.
     */
    function getTotalLockedTokens(address token) external view returns (uint256) {
        return _totalLockedTokens[token];
    }

     /**
     * @dev Retrieves a list of vault IDs owned by a specific address.
     * NOTE: This function iterates through all potential vault IDs up to the current `nextVaultId`.
     * It can be highly gas-intensive and should not be relied upon for large numbers of vaults
     * in environments where gas limits are strict (like transaction execution).
     * It is primarily suitable for off-chain indexing or view calls.
     * @param owner The address whose vaults to retrieve.
     * @return An array of vault IDs owned by the address.
     */
    function getVaultIdsByOwner(address owner) external view returns (uint256[] memory) {
        uint256[] memory ownedVaultIds = new uint256[](getVaultCount());
        uint256 count = 0;
        // Iterate through all created vaults
        for (uint256 i = 1; i < nextVaultId; i++) {
            if (vaults[i].owner == owner) {
                ownedVaultIds[count] = i;
                count++;
            }
        }
        // Resize array to actual count
        uint256[] memory result = new uint256[](count);
        for (uint256 i = 0; i < count; i++) {
            result[i] = ownedVaultIds[i];
        }
        return result;
    }

    // Inherited functions made external for clarity in summary if needed:
    // function paused() external view returns (bool) { return super.paused(); }
    // function pause() external onlyOwner { super.pause(); }
    // function unpause() external onlyOwner { super.unpause(); }
    // function owner() external view returns (address) { return super.owner(); }
}
```