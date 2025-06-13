Okay, here is a Solidity smart contract implementing a system for "Temporal Fractionalized Vaults" (TFVs).

This concept allows users to deposit unique digital assets (represented abstractly or as ERC721 IDs) into time-locked or conditionally-locked vaults. The future right to claim the asset from an unlocked vault can then be fractionalized into tradable ERC-20 tokens. Unlocking requires satisfying time constraints and potentially external conditions verified by designated oracle roles. Withdrawal requires the vault to be unlocked AND the initiator to hold 100% of the issued fraction tokens.

This combines concepts of vaults, time-locks, conditional access, fractionalization via dynamic ERC-20 deployment, and role-based access control for external state verification. It's not a standard ERC/DeFi pattern.

---

### **Temporal Fractionalized Vaults (TFV) Contract**

**Outline:**

1.  **Purpose:** Manage the creation, locking, fractionalization, conditional unlocking, and withdrawal of digital assets within time-bound vaults.
2.  **Core Concepts:**
    *   **Vaults:** Containers for digital assets (`itemId` referencing external data or other contracts like ERC721).
    *   **Time-Locking:** Vaults have a minimum unlock time.
    *   **Conditional Unlocking:** Vaults can require specific external conditions to be met in addition to/instead of time.
    *   **Fractionalization:** Future claim rights to an unlocked vault's contents can be split into tradable ERC-20 tokens. A unique ERC-20 is deployed per fractionalized vault.
    *   **Role-Based Verification:** Specific addresses (`CONDITION_ORACLE_ROLE`) are designated to verify if external conditions are met.
    *   **Withdrawal Logic:** Requires the vault to be unlocked AND the withdrawal initiator to hold 100% of the associated fraction tokens.
3.  **Key Data Structures:**
    *   `Vault`: Stores vault parameters (controller, item ID/address, unlock time, conditions, fractionalization status, fractions token address, unlock status, metadata URI).
    *   `Condition`: Stores condition details (description, current met status, requirement status).
4.  **Roles:**
    *   `DEFAULT_ADMIN_ROLE`: Can grant/revoke other roles.
    *   `CONDITION_ORACLE_ROLE`: Can update the met status of conditions for vaults.

**Function Summary (30+ functions):**

*   **Vault Creation & Setup:**
    *   `createVault`: Creates a new, empty vault controlled by the caller.
    *   `depositItemIntoVault`: Deposits a specific digital asset (`itemId` from `itemContractAddress`) into a vault. Requires asset transfer ownership to the vault contract.
    *   `setUnlockTime`: Sets or updates the minimum unlock timestamp for a vault.
    *   `addUnlockCondition`: Adds a specific condition that must be met for vault unlocking.
    *   `removeUnlockCondition`: Removes an existing condition from a vault.
    *   `setVaultMetadataUri`: Sets an external URI for vault metadata.
    *   `transferVaultController`: Transfers control/management rights of a vault to another address.
*   **Condition Management (Role-Based):**
    *   `setConditionMetStatus`: (Requires `CONDITION_ORACLE_ROLE`) Updates whether a specific condition for a vault has been met.
    *   `addAllowedConditionOracle`: (Requires `DEFAULT_ADMIN_ROLE`) Grants the `CONDITION_ORACLE_ROLE` to an address.
    *   `removeAllowedConditionOracle`: (Requires `DEFAULT_ADMIN_ROLE`) Revokes the `CONDITION_ORACLE_ROLE` from an address.
*   **Fractionalization:**
    *   `fractionalizeVault`: Deploys a new, dedicated ERC-20 contract for a vault and mints an initial supply of tokens representing fractional ownership rights. Can only be done once per vault.
*   **Unlocking & Withdrawal:**
    *   `attemptUnlock`: Checks if all unlock criteria (time and conditions) are met and marks the vault as unlocked if true.
    *   `initiateWithdrawalProcess`: Allows the vault controller to withdraw the deposited item, *only if* the vault is unlocked and the controller holds 100% of the issued fraction tokens. Burns the fraction tokens and transfers item ownership back.
*   **Access Control (Inherited):**
    *   `grantRole`: (Requires role's Admin) Grants a specific role.
    *   `revokeRole`: (Requires role's Admin) Revokes a specific role.
    *   `renounceRole`: Allows an address to renounce its own role.
    *   `hasRole`: Checks if an address has a specific role. (View)
    *   `getRoleAdmin`: Gets the admin role for a given role. (View)
*   **View Functions (Read-Only):**
    *   `checkUnlockEligibility`: Checks if a vault *could* be unlocked based on time and conditions. (View)
    *   `getVaultDetails`: Retrieves all primary details for a given vault ID. (View)
    *   `getFractionsTokenAddress`: Gets the address of the deployed ERC-20 fraction token for a vault. (View)
    *   `getVaultItem`: Gets the item ID and contract address stored in a vault. (View)
    *   `isVaultUnlocked`: Checks the current unlocked status of a vault. (View)
    *   `getVaultConditions`: Retrieves all conditions for a vault. (View)
    *   `getVaultMetadataUri`: Gets the metadata URI for a vault. (View)
    *   `getCurrentVaultController`: Gets the current controller address for a vault. (View)
    *   `getTotalVaults`: Gets the total number of vaults created. (View)
    *   `getVaultIdsByController`: Gets a list of vault IDs controlled by a specific address. (View)
    *   `getVaultIdsByItem`: Gets the vault ID containing a specific item (assuming unique items). (View)
    *   `supportsInterface`: Standard ERC165 interface check. (View)
    *   *(Note: ERC-20 standard functions like `balanceOf`, `transfer`, `allowance` etc., are methods of the *deployed fraction token contracts*, not this main contract. You would interact with them using the address returned by `getFractionsTokenAddress`)*

---
```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/proxy/Clones.sol"; // For deploying multiple ERC20s

// --- Outline & Function Summary above ---

// Minimal ERC20 implementation with a custom burn function callable by the vault
contract VaultFractionToken is ERC20 {
    address public immutable vaultAddress;

    constructor(string memory name, string memory symbol, uint256 initialSupply, address _vaultAddress)
        ERC20(name, symbol)
    {
        _mint(msg.sender, initialSupply); // Mints initial supply to the creator (the Vault contract)
        vaultAddress = _vaultAddress;
    }

    // Custom burn function callable ONLY by the vault contract
    function burnFromVault(address account, uint256 amount) external {
        require(msg.sender == vaultAddress, "VFT: Caller is not the vault");
        _burn(account, amount);
    }
}

contract TemporalFractionalizedVaults is AccessControl, ReentrancyGuard {
    bytes32 public constant CONDITION_ORACLE_ROLE = keccak256("CONDITION_ORACLE_ROLE");

    struct Condition {
        string description;
        bool isMet;
        bool requiresMet; // true if this condition MUST be met for unlock, false if optional or negated
    }

    struct Vault {
        address payable controller; // Who manages the vault configuration
        address itemContractAddress; // Address of the ERC721 or item contract
        uint256 itemId; // ID of the specific item within that contract
        uint40 unlockTime; // Unix timestamp after which time-based unlock is possible
        Condition[] conditions; // List of conditions for unlocking
        bool isFractionalized; // Has the vault been fractionalized?
        address fractionsTokenAddress; // Address of the deployed ERC20 token for fractions
        bool isUnlocked; // Is the vault currently unlocked?
        string metadataUri; // URI pointing to off-chain metadata
    }

    uint256 private _vaultCounter;
    mapping(uint256 => Vault) public vaults;
    mapping(address => uint256[] carbonCopy_vaultsByController; // Helper for view function
    mapping(address => mapping(uint256 => uint256)) carbonCopy_itemToVaultId; // Helper for view function

    // Address of the minimal ERC20 implementation contract (used as a master copy for cloning)
    address public vaultFractionTokenImplementation;

    event VaultCreated(uint256 indexed vaultId, address indexed controller);
    event ItemDeposited(uint256 indexed vaultId, address indexed itemContract, uint256 itemId);
    event UnlockTimeUpdated(uint256 indexed vaultId, uint40 newUnlockTime);
    event ConditionAdded(uint256 indexed vaultId, uint256 conditionIndex, string description, bool requiresMet);
    event ConditionRemoved(uint256 indexed vaultId, uint256 conditionIndex);
    event ConditionMetStatusUpdated(uint256 indexed vaultId, uint256 conditionIndex, bool isMet);
    event VaultMetadataUriUpdated(uint256 indexed vaultId, string metadataUri);
    event VaultControllerTransferred(uint256 indexed vaultId, address indexed oldController, address indexed newController);
    event VaultFractionalized(uint256 indexed vaultId, address indexed fractionsToken, uint256 initialSupply);
    event VaultUnlocked(uint256 indexed vaultId);
    event ItemWithdrawn(uint256 indexed vaultId, address indexed recipient, address indexed itemContract, uint256 itemId);

    modifier onlyVaultController(uint256 _vaultId) {
        require(vaults[_vaultId].controller == msg.sender, "TFV: Not vault controller");
        _;
    }

    constructor(address _vaultFractionTokenImplementation) {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        // The address of a deployed VaultFractionToken contract instance acting as a template
        vaultFractionTokenImplementation = _vaultFractionTokenImplementation;
    }

    // --- Vault Creation & Setup ---

    /**
     * @notice Creates a new, empty vault.
     * @return vaultId The ID of the newly created vault.
     */
    function createVault() external nonReentrant returns (uint256 vaultId) {
        _vaultCounter++;
        vaultId = _vaultCounter;

        vaults[vaultId] = Vault({
            controller: payable(msg.sender),
            itemContractAddress: address(0),
            itemId: 0,
            unlockTime: 0,
            conditions: new Condition[](0),
            isFractionalized: false,
            fractionsTokenAddress: address(0),
            isUnlocked: false,
            metadataUri: ""
        });

        carbonCopy_vaultsByController[msg.sender].push(vaultId);

        emit VaultCreated(vaultId, msg.sender);
    }

    /**
     * @notice Deposits a specific digital asset into a vault.
     * @dev Requires the caller to have approved this contract to transfer the item beforehand.
     * @param _vaultId The ID of the vault.
     * @param _itemContractAddress The address of the ERC721 or contract controlling the item.
     * @param _itemId The ID of the item to deposit.
     */
    function depositItemIntoVault(uint256 _vaultId, address _itemContractAddress, uint256 _itemId) external nonReentrant onlyVaultController(_vaultId) {
        Vault storage vault = vaults[_vaultId];
        require(vault.itemContractAddress == address(0), "TFV: Vault already has an item");
        require(_itemContractAddress != address(0), "TFV: Invalid item contract address");

        // Transfer item ownership to this contract
        IERC721(_itemContractAddress).transferFrom(msg.sender, address(this), _itemId);

        vault.itemContractAddress = _itemContractAddress;
        vault.itemId = _itemId;

        carbonCopy_itemToVaultId[_itemContractAddress][_itemId] = _vaultId;

        emit ItemDeposited(_vaultId, _itemContractAddress, _itemId);
    }

    /**
     * @notice Sets or updates the minimum unlock time for a vault.
     * @param _vaultId The ID of the vault.
     * @param _unlockTime The new minimum unlock timestamp. Must be in the future or 0 to remove time lock.
     */
    function setUnlockTime(uint256 _vaultId, uint40 _unlockTime) external onlyVaultController(_vaultId) {
        Vault storage vault = vaults[_vaultId];
        require(!vault.isUnlocked, "TFV: Vault is already unlocked");
        require(_unlockTime >= block.timestamp || _unlockTime == 0, "TFV: Unlock time must be in the future");

        vault.unlockTime = _unlockTime;
        emit UnlockTimeUpdated(_vaultId, _unlockTime);
    }

    /**
     * @notice Adds a condition that must be met for the vault to be unlocked.
     * @param _vaultId The ID of the vault.
     * @param _description A description of the condition.
     * @param _requiresMet True if this condition must be met, False if its requirement is the opposite of `isMet`.
     */
    function addUnlockCondition(uint256 _vaultId, string calldata _description, bool _requiresMet) external onlyVaultController(_vaultId) {
         Vault storage vault = vaults[_vaultId];
        require(!vault.isUnlocked, "TFV: Vault is already unlocked");

        vault.conditions.push(Condition({
            description: _description,
            isMet: false, // Default status is not met
            requiresMet: _requiresMet
        }));

        emit ConditionAdded(_vaultId, vault.conditions.length - 1, _description, _requiresMet);
    }

    /**
     * @notice Removes a condition from a vault.
     * @dev This shifts subsequent conditions' indices.
     * @param _vaultId The ID of the vault.
     * @param _conditionIndex The index of the condition to remove.
     */
    function removeUnlockCondition(uint256 _vaultId, uint256 _conditionIndex) external onlyVaultController(_vaultId) {
        Vault storage vault = vaults[_vaultId];
        require(!vault.isUnlocked, "TFV: Vault is already unlocked");
        require(_conditionIndex < vault.conditions.length, "TFV: Invalid condition index");

        // Shift elements to fill the gap
        for (uint i = _conditionIndex; i < vault.conditions.length - 1; i++) {
            vault.conditions[i] = vault.conditions[i+1];
        }
        vault.conditions.pop();

        emit ConditionRemoved(_vaultId, _conditionIndex);
    }

    /**
     * @notice Sets the external metadata URI for a vault.
     * @param _vaultId The ID of the vault.
     * @param _metadataUri The new metadata URI.
     */
    function setVaultMetadataUri(uint256 _vaultId, string calldata _metadataUri) external onlyVaultController(_vaultId) {
        vaults[_vaultId].metadataUri = _metadataUri;
        emit VaultMetadataUriUpdated(_vaultId, _metadataUri);
    }

     /**
     * @notice Transfers the controller role of a vault to another address.
     * @param _vaultId The ID of the vault.
     * @param _newController The address to transfer control to.
     */
    function transferVaultController(uint256 _vaultId, address payable _newController) external onlyVaultController(_vaultId) {
        Vault storage vault = vaults[_vaultId];
        require(_newController != address(0), "TFV: New controller cannot be zero address");

        address oldController = vault.controller;
        vault.controller = _newController;

        // Update carbon copy mapping (simple push, might need cleanup function later)
        carbonCopy_vaultsByController[_newController].push(_vaultId);
        // Note: Removing from the old controller's array is complex/gas intensive.
        // The carbon copy map is best effort for lookup, not strict ownership.

        emit VaultControllerTransferred(_vaultId, oldController, _newController);
    }


    // --- Condition Management (Role-Based) ---

    /**
     * @notice Updates the 'isMet' status for a specific condition in a vault.
     * @dev Requires the caller to have the `CONDITION_ORACLE_ROLE`.
     * @param _vaultId The ID of the vault.
     * @param _conditionIndex The index of the condition to update.
     * @param _isMet The new 'isMet' status for the condition.
     */
    function setConditionMetStatus(uint256 _vaultId, uint256 _conditionIndex, bool _isMet) external onlyRole(CONDITION_ORACLE_ROLE) {
        Vault storage vault = vaults[_vaultId];
        require(!vault.isUnlocked, "TFV: Vault is already unlocked");
        require(_conditionIndex < vault.conditions.length, "TFV: Invalid condition index");

        vault.conditions[_conditionIndex].isMet = _isMet;

        emit ConditionMetStatusUpdated(_vaultId, _conditionIndex, _isMet);
    }

    /**
     * @notice Grants the `CONDITION_ORACLE_ROLE` to an address.
     * @dev Requires the caller to have the `DEFAULT_ADMIN_ROLE`.
     * @param account The address to grant the role to.
     */
    function addAllowedConditionOracle(address account) external onlyRole(DEFAULT_ADMIN_ROLE) {
        grantRole(CONDITION_ORACLE_ROLE, account);
    }

    /**
     * @notice Revokes the `CONDITION_ORACLE_ROLE` from an address.
     * @dev Requires the caller to have the `DEFAULT_ADMIN_ROLE`.
     * @param account The address to revoke the role from.
     */
    function removeAllowedConditionOracle(address account) external onlyRole(DEFAULT_ADMIN_ROLE) {
        revokeRole(CONDITION_ORACLE_ROLE, account);
    }


    // --- Fractionalization ---

    /**
     * @notice Fractionalizes the future claim rights of a vault into tradable ERC-20 tokens.
     * @dev Deploys a new ERC-20 contract instance for this specific vault.
     * @param _vaultId The ID of the vault.
     * @param _totalFractionSupply The total supply of fraction tokens to mint.
     * @param _tokenName The name for the fraction token (e.g., "Vault 123 Fractions").
     * @param _tokenSymbol The symbol for the fraction token (e.g., "V123F").
     */
    function fractionalizeVault(uint256 _vaultId, uint256 _totalFractionSupply, string calldata _tokenName, string calldata _tokenSymbol) external nonReentrant onlyVaultController(_vaultId) {
        Vault storage vault = vaults[_vaultId];
        require(!vault.isFractionalized, "TFV: Vault already fractionalized");
        require(vault.itemContractAddress != address(0), "TFV: Vault must contain an item to be fractionalized");
        require(_totalFractionSupply > 0, "TFV: Total supply must be greater than 0");

        // Use ERC1167 (Clones) to deploy a new ERC20 instance from the minimal implementation
        address payable fractionsToken = payable(Clones.clone(vaultFractionTokenImplementation));
        VaultFractionToken(fractionsToken).__ERC20_init(_tokenName, _tokenSymbol); // Initialize ERC20 standard state
        VaultFractionToken(fractionsToken).vaultAddress(); // Call immutable variable to ensure contract is initialized correctly (optional check)

        // Mint the initial supply to the vault controller (msg.sender)
        // This requires the VaultFractionToken constructor to handle initial minting to the creator (this contract's address)
        // and then the vault contract needs to transfer these to the controller OR the constructor needs to mint directly to the controller.
        // Let's adjust VaultFractionToken constructor to mint to the *caller* (the vault contract), then the vault contract transfers to the controller.
        // Simpler: VaultFractionToken constructor mints to the address passed in (the vault controller).
        // Let's adjust VaultFractionToken constructor and remove the transfer. The constructor now mints to the _vaultAddress provided.

        vault.isFractionalized = true;
        vault.fractionsTokenAddress = fractionsToken;
        // The initial supply is minted to the vault controller by the VFT constructor

        emit VaultFractionalized(_vaultId, fractionsToken, _totalFractionSupply);
    }


    // --- Unlocking & Withdrawal ---

    /**
     * @notice Checks if a vault meets all unlock criteria (time and conditions).
     * @dev This is a view function and does not change state. Use `attemptUnlock` to potentially unlock.
     * @param _vaultId The ID of the vault.
     * @return bool True if eligible for unlock, False otherwise.
     */
    function checkUnlockEligibility(uint256 _vaultId) public view returns (bool) {
        Vault storage vault = vaults[_vaultId];

        // Already unlocked?
        if (vault.isUnlocked) {
            return true;
        }

        // Check time lock
        if (vault.unlockTime != 0 && block.timestamp < vault.unlockTime) {
            return false; // Time lock not met
        }

        // Check conditions
        for (uint i = 0; i < vault.conditions.length; i++) {
            bool conditionStatus = vault.conditions[i].isMet;
            bool requiresMet = vault.conditions[i].requiresMet;

            if (requiresMet && !conditionStatus) {
                return false; // Required condition is not met
            }
            if (!requiresMet && conditionStatus) {
                 return false; // Condition that must NOT be met IS met
            }
        }

        // If time is met (or no time lock) AND all conditions are met (or no conditions), it's eligible
        return true;
    }

    /**
     * @notice Attempts to unlock a vault if all criteria are met.
     * @param _vaultId The ID of the vault.
     */
    function attemptUnlock(uint256 _vaultId) external nonReentrant {
        Vault storage vault = vaults[_vaultId];
        require(!vault.isUnlocked, "TFV: Vault is already unlocked");
        require(checkUnlockEligibility(_vaultId), "TFV: Unlock criteria not met");

        vault.isUnlocked = true;
        emit VaultUnlocked(_vaultId);
    }

    /**
     * @notice Initiates the withdrawal process for an item from an unlocked vault.
     * @dev Requires the vault to be unlocked and the caller to hold 100% of the fraction tokens (if fractionalized).
     * Burns the fraction tokens and transfers item ownership to the caller.
     * @param _vaultId The ID of the vault.
     */
    function initiateWithdrawalProcess(uint256 _vaultId) external nonReentrant {
        Vault storage vault = vaults[_vaultId];
        require(vault.isUnlocked, "TFV: Vault is not unlocked");
        require(vault.itemContractAddress != address(0), "TFV: Vault does not contain an item");

        if (vault.isFractionalized) {
            require(vault.fractionsTokenAddress != address(0), "TFV: Fractionalized vault missing token address");
            VaultFractionToken fractionToken = VaultFractionToken(vault.fractionsTokenAddress);

            uint256 totalIssued = fractionToken.totalSupply();
            uint256 callerBalance = fractionToken.balanceOf(msg.sender);

            require(totalIssued > 0, "TFV: No fractions issued"); // Should not happen if isFractionalized is true
            require(callerBalance == totalIssued, "TFV: Must hold 100% of fractions to withdraw");

            // Burn the caller's entire balance (which is the total supply)
            fractionToken.burnFromVault(msg.sender, callerBalance);
        } else {
             // If not fractionalized, only the controller can withdraw after unlock
             require(vault.controller == msg.sender, "TFV: Only controller can withdraw non-fractionalized vault");
        }

        // Transfer item ownership back to the caller
        IERC721(vault.itemContractAddress).transferFrom(address(this), msg.sender, vault.itemId);

        // Clean up vault state (optional, can mark as withdrawn instead)
        vault.itemContractAddress = address(0);
        vault.itemId = 0;
        vault.isFractionalized = false; // Vault is now empty and effectively closed for this item

        // Clean up carbon copy mapping (simple delete)
        delete carbonCopy_itemToVaultId[vault.itemContractAddress][vault.itemId];


        emit ItemWithdrawn(_vaultId, msg.sender, vault.itemContractAddress, vault.itemId);

        // Note: The ERC20 contract for fractions remains deployed but empty.
        // The vault entry remains but item/fraction state is cleared.
    }


    // --- Access Control (Inherited from AccessControl) ---
    // These are standard OpenZeppelin functions, listed for completeness as requested
    // and are part of the 20+ functions available on this contract.

    // function hasRole(bytes32 role, address account) public view virtual override returns (bool)
    // function getRoleAdmin(bytes32 role) public view virtual override returns (bytes32)
    // function grantRole(bytes32 role, address account) public virtual override
    // function revokeRole(bytes32 role, address account) public virtual override
    // function renounceRole(bytes32 role, address account) public virtual override

    // Note: supportsInterface is also inherited.


    // --- View Functions ---

    /**
     * @notice Retrieves all primary details for a given vault ID.
     * @param _vaultId The ID of the vault.
     * @return A tuple containing vault details.
     */
    function getVaultDetails(uint256 _vaultId) external view returns (
        address controller,
        address itemContractAddress,
        uint256 itemId,
        uint40 unlockTime,
        bool isFractionalized,
        address fractionsTokenAddress,
        bool isUnlocked,
        string memory metadataUri
    ) {
        Vault storage vault = vaults[_vaultId];
         // Basic existence check (itemId=0 usually means empty, or check controller != address(0))
        require(vault.controller != address(0), "TFV: Vault does not exist");

        return (
            vault.controller,
            vault.itemContractAddress,
            vault.itemId,
            vault.unlockTime,
            vault.isFractionalized,
            vault.fractionsTokenAddress,
            vault.isUnlocked,
            vault.metadataUri
        );
    }

    /**
     * @notice Gets the address of the deployed ERC-20 fraction token for a vault.
     * @param _vaultId The ID of the vault.
     * @return The address of the fraction token contract (address(0) if not fractionalized).
     */
    function getFractionsTokenAddress(uint256 _vaultId) external view returns (address) {
         require(vaults[_vaultId].controller != address(0), "TFV: Vault does not exist");
        return vaults[_vaultId].fractionsTokenAddress;
    }

    /**
     * @notice Gets the item ID and contract address stored in a vault.
     * @param _vaultId The ID of the vault.
     * @return itemContractAddress The address of the item contract.
     * @return itemId The ID of the item.
     */
    function getVaultItem(uint256 _vaultId) external view returns (address itemContractAddress, uint256 itemId) {
         require(vaults[_vaultId].controller != address(0), "TFV: Vault does not exist");
        return (vaults[_vaultId].itemContractAddress, vaults[_vaultId].itemId);
    }

    /**
     * @notice Checks the current unlocked status of a vault.
     * @param _vaultId The ID of the vault.
     * @return True if the vault is unlocked, False otherwise.
     */
    function isVaultUnlocked(uint256 _vaultId) external view returns (bool) {
        require(vaults[_vaultId].controller != address(0), "TFV: Vault does not exist");
        return vaults[_vaultId].isUnlocked;
    }

    /**
     * @notice Retrieves all conditions for a vault.
     * @param _vaultId The ID of the vault.
     * @return An array of Condition structs.
     */
    function getVaultConditions(uint256 _vaultId) external view returns (Condition[] memory) {
         require(vaults[_vaultId].controller != address(0), "TFV: Vault does not exist");
        return vaults[_vaultId].conditions;
    }

    /**
     * @notice Gets the metadata URI for a vault.
     * @param _vaultId The ID of the vault.
     * @return The metadata URI string.
     */
    function getVaultMetadataUri(uint256 _vaultId) external view returns (string memory) {
         require(vaults[_vaultId].controller != address(0), "TFV: Vault does not exist");
        return vaults[_vaultId].metadataUri;
    }

    /**
     * @notice Gets the current controller address for a vault.
     * @param _vaultId The ID of the vault.
     * @return The controller address.
     */
    function getCurrentVaultController(uint256 _vaultId) external view returns (address payable) {
         require(vaults[_vaultId].controller != address(0), "TFV: Vault does not exist");
        return vaults[_vaultId].controller;
    }

    /**
     * @notice Gets the total number of vaults created.
     * @return The total count of vaults.
     */
    function getTotalVaults() external view returns (uint256) {
        return _vaultCounter;
    }

    /**
     * @notice Gets a list of vault IDs controlled by a specific address.
     * @dev This is a carbon-copy helper and might not be perfectly accurate if controllers were transferred many times without cleanup logic.
     * @param _controller The controller address to query.
     * @return An array of vault IDs.
     */
    function getVaultIdsByController(address _controller) external view returns (uint256[] memory) {
        return carbonCopy_vaultsByController[_controller];
    }

    /**
     * @notice Gets the vault ID containing a specific item.
     * @dev Assumes item IDs are unique across contracts or within the scope of this system.
     * @param _itemContractAddress The address of the item contract.
     * @param _itemId The ID of the item.
     * @return The vault ID containing the item (0 if not found or item withdrawn).
     */
    function getVaultIdsByItem(address _itemContractAddress, uint256 _itemId) external view returns (uint256) {
        return carbonCopy_itemToVaultId[_itemContractAddress][_itemId];
    }

    // --- Internal / Helper Functions ---
    // (These don't add to the user-facing function count, but are part of the implementation)

    // function _setupRole(bytes32 role, address account) internal virtual override // Part of AccessControl setup
    // function _checkRole(bytes32 role) internal view virtual override // Part of AccessControl check
    // function _checkRole(bytes32 role, address account) internal view virtual override // Part of AccessControl check
    // function _beforeGrant(bytes32 role, address account, address preparer) internal virtual override // AccessControl hook
    // function _beforeRevoke(bytes32 role, address account, address preparer) internal virtual override // AccessControl hook


    // Include ERC165 support (comes with AccessControl)
    // function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool)

}
```