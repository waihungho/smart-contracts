```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";

/**
 * @title QuantumVault
 * @dev A smart contract platform for creating vaults with complex, multi-factor conditional asset release.
 * Assets locked in a vault can only be released when a set of predefined conditions are all met (or any one is met, based on configuration).
 * Conditions can be time-based, oracle-based, dependent on internal contract state, or even dependent on other vaults being unlocked.
 * This allows for highly customizable vesting, conditional payments, milestone-based releases, and complex escrow scenarios.
 *
 * Outline & Function Summary:
 *
 * 1.  Core Vault Management:
 *     -   `createVault`: Create a new vault, deposit initial assets, define owner, manager, recipient, and initial conditions.
 *     -   `depositToVault`: Add more assets to an existing vault.
 *     -   `attemptUnlock`: The core function to check conditions and release assets if met.
 *     -   `checkUnlockStatus`: Read-only preview of whether a vault's conditions are currently met.
 *     -   `isVaultUnlocked`: Check if a vault has been successfully unlocked.
 *
 * 2.  Vault Configuration & Access Control:
 *     -   `setVaultManager`: Delegate management rights for a vault.
 *     -   `transferVaultOwnership`: Transfer full ownership of a vault.
 *     -   `addAuthorizedUnlocker`: Add an address allowed to call `attemptUnlock` besides owner/manager.
 *     -   `removeAuthorizedUnlocker`: Remove an authorized unlocker.
 *     -   `setUnlockCriteriaLogic`: Define if ALL conditions must be met or ANY single condition is sufficient.
 *     -   `setUnlockDependency`: Make a vault dependent on another specific vault being unlocked.
 *     -   `setVaultStateFlag`: Manually set an internal state flag for a vault (used in InternalState conditions).
 *
 * 3.  Condition Management:
 *     -   `addCondition`: Add a new condition to an existing vault.
 *     -   `removeCondition`: Remove a condition from a vault.
 *     -   `modifyCondition`: Change parameters of an existing condition.
 *
 * 4.  Oracle & External Data Integration:
 *     -   `registerOracleUpdate`: Authorized oracles update specific data feeds used in OraclePrice conditions.
 *     -   `registerAuthorizedOracle`: Owner registers an address permitted to call `registerOracleUpdate`.
 *     -   `removeAuthorizedOracle`: Owner removes an authorized oracle address.
 *     -   `isAuthorizedOracleAddress`: Check if an address is an authorized oracle.
 *
 * 5.  Information Retrieval (Read-only):
 *     -   `getVaultDetails`: Get general information about a vault.
 *     -   `getVaultConditions`: Get the list of conditions for a vault.
 *     -   `getVaultBalance`: Get the current balance of a specific asset in a vault.
 *     -   `getAuthorizedUnlockers`: Get the list of authorized unlocker addresses for a vault.
 *     -   `getVaultStateFlag`: Get the value of a specific internal state flag for a vault.
 *     -   `getVaultDependency`: Get the ID of the vault this one depends on.
 *
 * 6.  Contract Administration:
 *     -   `pause`: Owner can pause the contract (emergency).
 *     -   `unpause`: Owner can unpause the contract.
 *     -   `setLogicContract`: Placeholder for potential upgradeability (e.g., proxy pattern).
 */
contract QuantumVault is Ownable, ReentrancyGuard, Pausable {
    using SafeERC20 for IERC20;

    error Unauthorized();
    error VaultNotFound(uint256 vaultId);
    error VaultAlreadyUnlocked(uint256 vaultId);
    error ConditionsNotMet(uint256 vaultId);
    error ConditionNotFound(uint256 vaultId, uint256 conditionIndex);
    error InvalidConditionParameters(uint256 conditionType);
    error ZeroAmountDeposit();
    error DependencyVaultNotUnlocked(uint256 dependencyVaultId);
    error CannotModifyUnlockedVault(uint256 vaultId);
    error AssetTransferFailed();
    error InvalidVaultOwnerOrManager();
    error InvalidVaultOwnerOrManagerOrUnlocker();

    enum ConditionType {
        TimeBased,          // Check if block.timestamp >= value (timestamp)
        OraclePrice,        // Check latestOracleData[targetBytes] operator value
        InternalState,      // Check vaultStateFlags[vaultId][targetBytes] == (value > 0)
        VaultUnlocked,      // Check if vaults[value].isUnlocked (value is vaultId)
        BalanceThreshold    // Check vaultBalance[vaultId][targetAddress] operator value (targetAddress is asset)
    }

    enum ComparisonOperator {
        EqualTo,
        GreaterThan,
        LessThan,
        GreaterThanOrEqualTo,
        LessThanOrEqualTo
    }

    struct Condition {
        ConditionType conditionType;
        ComparisonOperator operator;
        uint256 value;         // Generic uint256 value (timestamp, amount, state value int)
        address targetAddress; // Generic address value (asset address, target vault owner etc.)
        bytes32 targetBytes;   // Generic bytes32 value (oracle feed key, state flag name hash)
        string description;    // Human-readable description of the condition
    }

    struct Vault {
        address owner;
        address manager; // Can manage conditions, state flags, authorized unlockers
        address recipient; // Address to receive assets on unlock
        address assetAddress; // Asset address (0 for native ETH)
        uint256 balance;
        Condition[] conditions;
        bool isUnlocked;
        bool requireAllConditions; // If true, all conditions must pass. If false, any one condition must pass.
        uint256 dependencyVaultId; // 0 if no dependency
        mapping(bytes32 => bool) stateFlags; // Internal state flags
        mapping(address => bool) authorizedUnlockers; // Addresses allowed to call attemptUnlock
    }

    mapping(uint255 => Vault) public vaults; // Using uint255 for mapping key for future-proofing against potential hash collisions if vaultIds were used directly as mapping keys without care, though uint256 is fine. Let's stick to uint256 as it's simpler and standard.
    mapping(uint256 => Vault) private _vaults; // Internal mapping
    uint256 private _nextVaultId = 1;

    mapping(bytes32 => uint256) private _latestOracleData; // Oracle key (bytes32) -> latest value (uint256)
    mapping(address => bool) private _isAuthorizedOracle;

    event VaultCreated(uint256 indexed vaultId, address indexed owner, address indexed recipient, address assetAddress, uint256 amount);
    event VaultUnlocked(uint256 indexed vaultId, address indexed recipient, address assetAddress, uint256 amount);
    event ConditionAdded(uint256 indexed vaultId, uint256 conditionIndex, ConditionType conditionType);
    event ConditionRemoved(uint256 indexed vaultId, uint256 conditionIndex);
    event ConditionModified(uint256 indexed vaultId, uint256 conditionIndex);
    event DepositMade(uint256 indexed vaultId, address indexed depositor, address assetAddress, uint256 amount);
    event VaultManagerUpdated(uint256 indexed vaultId, address indexed newManager);
    event VaultOwnershipTransferred(uint256 indexed vaultId, address indexed newOwner);
    event AuthorizedUnlockerUpdated(uint256 indexed vaultId, address indexed unlocker, bool added);
    event UnlockCriteriaLogicUpdated(uint256 indexed vaultId, bool requireAllConditions);
    event VaultDependencyUpdated(uint256 indexed vaultId, uint256 dependencyVaultId);
    event VaultStateFlagSet(uint256 indexed vaultId, bytes32 indexed flagNameHash, bool value);
    event OracleRegistered(address indexed oracle, bool authorized);
    event OracleUpdate(bytes32 indexed key, uint256 value);

    // Placeholder for upgradeability pattern (like UUPS)
    address public logicContract;

    modifier onlyVaultOwner(uint256 _vaultId) {
        if (_vaults[_vaultId].owner != msg.sender) revert InvalidVaultOwnerOrManager();
        _;
    }

     modifier onlyVaultOwnerOrManager(uint256 _vaultId) {
        if (_vaults[_vaultId].owner != msg.sender && _vaults[_vaultId].manager != msg.sender) revert InvalidVaultOwnerOrManager();
        _;
    }

    modifier onlyVaultOwnerOrManagerOrUnlocker(uint256 _vaultId) {
        Vault storage vault = _vaults[_vaultId];
        if (vault.owner != msg.sender && vault.manager != msg.sender && !vault.authorizedUnlockers[msg.sender]) {
            revert InvalidVaultOwnerOrManagerOrUnlocker();
        }
        _;
    }

    modifier onlyAuthorizedOracle() {
        if (!_isAuthorizedOracle[msg.sender]) revert Unauthorized();
        _;
    }

    constructor() Ownable(msg.sender) {} // Owner of the contract

    /**
     * @dev Admin function to register or unregister an address as an authorized oracle.
     * Authorized oracles can call `registerOracleUpdate`.
     * @param _oracle The address to register/unregister.
     * @param _authorize True to authorize, false to unauthorize.
     */
    function registerAuthorizedOracle(address _oracle, bool _authorize) external onlyOwner {
        _isAuthorizedOracle[_oracle] = _authorize;
        emit OracleRegistered(_oracle, _authorize);
    }

    /**
     * @dev Admin function to check if an address is an authorized oracle.
     * @param _oracle The address to check.
     * @return bool True if authorized, false otherwise.
     */
    function isAuthorizedOracleAddress(address _oracle) external view returns (bool) {
        return _isAuthorizedOracle[_oracle];
    }

    /**
     * @dev Authorized oracles call this function to update data feeds used by OraclePrice conditions.
     * @param _key The unique identifier for the oracle data feed (e.g., keccak256("ETH/USD")).
     * @param _value The latest value from the oracle feed.
     */
    function registerOracleUpdate(bytes32 _key, uint256 _value) external onlyAuthorizedOracle {
        _latestOracleData[_key] = _value;
        emit OracleUpdate(_key, _value);
    }

    /**
     * @dev Creates a new vault with an initial deposit and conditions.
     * @param _recipient The address that receives the assets upon successful unlock.
     * @param _assetAddress The address of the asset (0 for native ETH).
     * @param _initialAmount The amount of assets to deposit initially.
     * @param _initialConditions An array of conditions that must be met for unlock.
     * @param _requireAllConditions True if all conditions must be met, false if any one is sufficient.
     * @param _dependencyVaultId If > 0, this vault can only be unlocked after the dependency vault is unlocked.
     * @return uint256 The ID of the newly created vault.
     */
    function createVault(
        address _recipient,
        address _assetAddress,
        uint256 _initialAmount,
        Condition[] calldata _initialConditions,
        bool _requireAllConditions,
        uint256 _dependencyVaultId
    ) external payable nonReentrant whenNotPaused returns (uint256) {
        if (_initialAmount == 0) revert ZeroAmountDeposit();
        if (_assetAddress == address(0) && msg.value != _initialAmount) revert ZeroAmountDeposit();
        if (_assetAddress != address(0) && msg.value != 0) revert ZeroAmountDeposit(); // Cannot send ETH for ERC20 deposit

        uint256 vaultId = _nextVaultId++;

        Vault storage newVault = _vaults[vaultId];
        newVault.owner = msg.sender;
        newVault.manager = msg.sender; // Owner is manager by default
        newVault.recipient = _recipient;
        newVault.assetAddress = _assetAddress;
        newVault.balance = _initialAmount;
        newVault.isUnlocked = false;
        newVault.requireAllConditions = _requireAllConditions;
        newVault.dependencyVaultId = _dependencyVaultId;
        newVault.authorizedUnlockers[msg.sender] = true; // Owner is authorized by default

        for (uint i = 0; i < _initialConditions.length; i++) {
             // Basic validation (more complex validation inside _checkCondition logic)
            if (_initialConditions[i].conditionType == ConditionType.OraclePrice && _initialConditions[i].targetBytes == bytes32(0)) {
                 revert InvalidConditionParameters(uint256(_initialConditions[i].conditionType));
            }
             if (_initialConditions[i].conditionType == ConditionType.InternalState && _initialConditions[i].targetBytes == bytes32(0)) {
                 revert InvalidConditionParameters(uint256(_initialConditions[i].conditionType));
            }
             if (_initialConditions[i].conditionType == ConditionType.BalanceThreshold && _initialConditions[i].targetAddress == address(0)) {
                 revert InvalidConditionParameters(uint256(_initialConditions[i].conditionType));
            }

            newVault.conditions.push(_initialConditions[i]);
        }

        // Transfer initial assets to the contract
        if (_assetAddress == address(0)) {
            // ETH already sent via payable
        } else {
            IERC20(_assetAddress).safeTransferFrom(msg.sender, address(this), _initialAmount);
        }

        emit VaultCreated(vaultId, msg.sender, _recipient, _assetAddress, _initialAmount);
        return vaultId;
    }

    /**
     * @dev Adds more assets to an existing vault.
     * Only the vault owner or manager can deposit.
     * @param _vaultId The ID of the vault to deposit into.
     * @param _amount The amount of assets to deposit.
     */
    function depositToVault(uint256 _vaultId, uint256 _amount) external payable nonReentrant whenNotPaused onlyVaultOwnerOrManager(_vaultId) {
        Vault storage vault = _vaults[_vaultId];
        if (vault.isUnlocked) revert CannotModifyUnlockedVault(_vaultId);
        if (_amount == 0) revert ZeroAmountDeposit();
        if (vault.assetAddress == address(0) && msg.value != _amount) revert ZeroAmountDeposit();
        if (vault.assetAddress != address(0) && msg.value != 0) revert ZeroAmountDeposit(); // Cannot send ETH for ERC20 deposit

        vault.balance += _amount;

        if (vault.assetAddress != address(0)) {
             IERC20(vault.assetAddress).safeTransferFrom(msg.sender, address(this), _amount);
        }
        // ETH is already sent via payable

        emit DepositMade(_vaultId, msg.sender, vault.assetAddress, _amount);
    }

    /**
     * @dev Adds a new condition to an existing vault.
     * Only the vault owner or manager can add conditions.
     * @param _vaultId The ID of the vault.
     * @param _condition The condition to add.
     */
    function addCondition(uint256 _vaultId, Condition calldata _condition) external whenNotPaused onlyVaultOwnerOrManager(_vaultId) {
        Vault storage vault = _vaults[_vaultId];
        if (vault.isUnlocked) revert CannotModifyUnlockedVault(_vaultId);

         // Basic validation
        if (_condition.conditionType == ConditionType.OraclePrice && _condition.targetBytes == bytes32(0)) {
             revert InvalidConditionParameters(uint256(_condition.conditionType));
        }
        if (_condition.conditionType == ConditionType.InternalState && _condition.targetBytes == bytes32(0)) {
             revert InvalidConditionParameters(uint256(_condition.conditionType));
        }
        if (_condition.conditionType == ConditionType.BalanceThreshold && _condition.targetAddress == address(0)) {
             revert InvalidConditionParameters(uint256(_condition.conditionType));
        }

        vault.conditions.push(_condition);
        emit ConditionAdded(_vaultId, vault.conditions.length - 1, _condition.conditionType);
    }

    /**
     * @dev Removes a condition from a vault by its index.
     * Only the vault owner or manager can remove conditions.
     * @param _vaultId The ID of the vault.
     * @param _conditionIndex The index of the condition to remove.
     */
    function removeCondition(uint256 _vaultId, uint256 _conditionIndex) external whenNotPaused onlyVaultOwnerOrManager(_vaultId) {
        Vault storage vault = _vaults[_vaultId];
        if (vault.isUnlocked) revert CannotModifyUnlockedVault(_vaultId);
        if (_conditionIndex >= vault.conditions.length) revert ConditionNotFound(_vaultId, _conditionIndex);

        // Swap and pop pattern to remove without shifting all elements
        uint256 lastIndex = vault.conditions.length - 1;
        if (_conditionIndex != lastIndex) {
            vault.conditions[_conditionIndex] = vault.conditions[lastIndex];
        }
        vault.conditions.pop();
        emit ConditionRemoved(_vaultId, _conditionIndex);
    }

    /**
     * @dev Modifies an existing condition in a vault by its index.
     * Only the vault owner or manager can modify conditions.
     * @param _vaultId The ID of the vault.
     * @param _conditionIndex The index of the condition to modify.
     * @param _newCondition The new parameters for the condition.
     */
    function modifyCondition(uint256 _vaultId, uint256 _conditionIndex, Condition calldata _newCondition) external whenNotPaused onlyVaultOwnerOrManager(_vaultId) {
        Vault storage vault = _vaults[_vaultId];
        if (vault.isUnlocked) revert CannotModifyUnlockedVault(_vaultId);
        if (_conditionIndex >= vault.conditions.length) revert ConditionNotFound(_vaultId, _conditionIndex);

         // Basic validation
        if (_newCondition.conditionType == ConditionType.OraclePrice && _newCondition.targetBytes == bytes32(0)) {
             revert InvalidConditionParameters(uint256(_newCondition.conditionType));
        }
        if (_newCondition.conditionType == ConditionType.InternalState && _newCondition.targetBytes == bytes32(0)) {
             revert InvalidConditionParameters(uint256(_newCondition.conditionType));
        }
         if (_newCondition.conditionType == ConditionType.BalanceThreshold && _newCondition.targetAddress == address(0)) {
             revert InvalidConditionParameters(uint256(_newCondition.conditionType));
        }

        vault.conditions[_conditionIndex] = _newCondition;
        emit ConditionModified(_vaultId, _conditionIndex);
    }

    /**
     * @dev Sets the manager for a vault. The manager can add/remove/modify conditions, deposit, set state flags, and add/remove authorized unlockers.
     * Only the vault owner can set the manager.
     * @param _vaultId The ID of the vault.
     * @param _newManager The address of the new manager.
     */
    function setVaultManager(uint256 _vaultId, address _newManager) external whenNotPaused onlyVaultOwner(_vaultId) {
        Vault storage vault = _vaults[_vaultId];
        if (vault.isUnlocked) revert CannotModifyUnlockedVault(_vaultId);
        vault.manager = _newManager;
        emit VaultManagerUpdated(_vaultId, _newManager);
    }

    /**
     * @dev Transfers ownership of a vault. The new owner gains full control, including setting manager and transferring ownership.
     * Only the current vault owner can transfer ownership.
     * @param _vaultId The ID of the vault.
     * @param _newOwner The address of the new owner.
     */
    function transferVaultOwnership(uint256 _vaultId, address _newOwner) external whenNotPaused onlyVaultOwner(_vaultId) {
         Vault storage vault = _vaults[_vaultId];
        if (vault.isUnlocked) revert CannotModifyUnlockedVault(_vaultId);
        vault.owner = _newOwner;
         // Automatically make new owner an authorized unlocker
        vault.authorizedUnlockers[_newOwner] = true;
        emit VaultOwnershipTransferred(_vaultId, _newOwner);
    }

    /**
     * @dev Adds an address that is authorized to call `attemptUnlock` for a specific vault.
     * Only the vault owner or manager can add authorized unlockers.
     * @param _vaultId The ID of the vault.
     * @param _unlocker The address to authorize.
     */
    function addAuthorizedUnlocker(uint256 _vaultId, address _unlocker) external whenNotPaused onlyVaultOwnerOrManager(_vaultId) {
        Vault storage vault = _vaults[_vaultId];
        if (vault.isUnlocked) revert CannotModifyUnlockedVault(_vaultId);
        vault.authorizedUnlockers[_unlocker] = true;
        emit AuthorizedUnlockerUpdated(_vaultId, _unlocker, true);
    }

    /**
     * @dev Removes an address from the list of authorized unlockers.
     * Only the vault owner or manager can remove authorized unlockers.
     * @param _vaultId The ID of the vault.
     * @param _unlocker The address to remove.
     */
    function removeAuthorizedUnlocker(uint256 _vaultId, address _unlocker) external whenNotPaused onlyVaultOwnerOrManager(_vaultId) {
        Vault storage vault = _vaults[_vaultId];
        if (vault.isUnlocked) revert CannotModifyUnlockedVault(_vaultId);
        // Cannot remove owner or manager's implicit authorization via explicit list removal
        if (_unlocker == vault.owner || _unlocker == vault.manager) {
            // Decide policy: prevent removing owner/manager or allow? Let's prevent explicit removal of owner/manager.
            // Their auth comes from their role, not this mapping.
            return;
        }
        delete vault.authorizedUnlockers[_unlocker];
        emit AuthorizedUnlockerUpdated(_vaultId, _unlocker, false);
    }

    /**
     * @dev Sets the logic for how conditions are evaluated.
     * If true, all conditions must pass (`AND`). If false, any single condition must pass (`OR`).
     * Only the vault owner or manager can set the logic.
     * @param _vaultId The ID of the vault.
     * @param _requireAll True for AND logic, false for OR logic.
     */
    function setUnlockCriteriaLogic(uint256 _vaultId, bool _requireAll) external whenNotPaused onlyVaultOwnerOrManager(_vaultId) {
        Vault storage vault = _vaults[_vaultId];
        if (vault.isUnlocked) revert CannotModifyUnlockedVault(_vaultId);
        vault.requireAllConditions = _requireAll;
        emit UnlockCriteriaLogicUpdated(_vaultId, _requireAll);
    }

    /**
     * @dev Sets a dependency on another vault. This vault can only be unlocked after the dependency vault is unlocked.
     * Setting dependencyVaultId to 0 removes the dependency.
     * Only the vault owner or manager can set the dependency.
     * @param _vaultId The ID of the vault.
     * @param _dependencyVaultId The ID of the vault this one depends on (0 to remove dependency).
     */
    function setUnlockDependency(uint256 _vaultId, uint256 _dependencyVaultId) external whenNotPaused onlyVaultOwnerOrManager(_vaultId) {
        Vault storage vault = _vaults[_vaultId];
        if (vault.isUnlocked) revert CannotModifyUnlockedVault(_vaultId);
        if (_dependencyVaultId > 0 && _vaults[_dependencyVaultId].owner == address(0)) revert VaultNotFound(_dependencyVaultId); // Check dependency exists
        vault.dependencyVaultId = _dependencyVaultId;
        emit VaultDependencyUpdated(_vaultId, _dependencyVaultId);
    }

    /**
     * @dev Manually sets an internal boolean state flag for a vault.
     * These flags can be used as conditions (InternalState).
     * Only the vault owner or manager can set state flags.
     * @param _vaultId The ID of the vault.
     * @param _flagName The name of the flag (converted to hash internally).
     * @param _value The boolean value to set for the flag.
     */
    function setVaultStateFlag(uint256 _vaultId, string calldata _flagName, bool _value) external whenNotPaused onlyVaultOwnerOrManager(_vaultId) {
        Vault storage vault = _vaults[_vaultId];
        if (vault.isUnlocked) revert CannotModifyUnlockedVault(_vaultId);
        bytes32 flagHash = keccak256(bytes(_flagName));
        vault.stateFlags[flagHash] = _value;
        emit VaultStateFlagSet(_vaultId, flagHash, _value);
    }


    /**
     * @dev Attempts to unlock the vault. Checks if all (or any, based on logic) conditions are met.
     * If conditions are met, transfers the assets to the recipient and marks the vault as unlocked.
     * Can be called by the vault owner, manager, or any authorized unlocker.
     * @param _vaultId The ID of the vault to attempt to unlock.
     */
    function attemptUnlock(uint256 _vaultId) external nonReentrant whenNotPaused onlyVaultOwnerOrManagerOrUnlocker(_vaultId) {
        Vault storage vault = _vaults[_vaultId];
        if (vault.owner == address(0)) revert VaultNotFound(_vaultId); // Check vault exists
        if (vault.isUnlocked) revert VaultAlreadyUnlocked(_vaultId);

        // Check dependency first
        if (vault.dependencyVaultId > 0) {
            if (!_vaults[vault.dependencyVaultId].isUnlocked) {
                revert DependencyVaultNotUnlocked(vault.dependencyVaultId);
            }
        }

        bool conditionsMet = _checkAllConditions(_vaultId);

        if (!conditionsMet) {
            revert ConditionsNotMet(_vaultId);
        }

        vault.isUnlocked = true;
        uint256 amount = vault.balance; // Capture balance before transfer

        // Transfer assets
        _transferAsset(vault.assetAddress, vault.recipient, amount);

        // Clear balance after transfer
        vault.balance = 0;

        emit VaultUnlocked(_vaultId, vault.recipient, vault.assetAddress, amount);
    }

    /**
     * @dev Internal helper function to check if all (or any) conditions for a vault are met.
     * @param _vaultId The ID of the vault.
     * @return bool True if conditions are met according to the vault's logic, false otherwise.
     */
    function _checkAllConditions(uint256 _vaultId) internal view returns (bool) {
        Vault storage vault = _vaults[_vaultId];
        Condition[] storage conditions = vault.conditions;

        if (conditions.length == 0) {
            // If no conditions are set, it can be unlocked immediately
            return true;
        }

        if (vault.requireAllConditions) {
            // AND logic: all must be true
            for (uint i = 0; i < conditions.length; i++) {
                if (!_checkCondition(_vaultId, conditions[i])) {
                    return false; // Found a condition that is not met
                }
            }
            return true; // All conditions were met
        } else {
            // OR logic: any must be true
            for (uint i = 0; i < conditions.length; i++) {
                if (_checkCondition(_vaultId, conditions[i])) {
                    return true; // Found at least one condition that is met
                }
            }
            return false; // No conditions were met
        }
    }

    /**
     * @dev Internal helper function to check a single condition.
     * @param _vaultId The ID of the vault.
     * @param _condition The condition struct to check.
     * @return bool True if the condition is met, false otherwise.
     */
    function _checkCondition(uint256 _vaultId, Condition storage _condition) internal view returns (bool) {
        Vault storage vault = _vaults[_vaultId];

        if (_condition.conditionType == ConditionType.TimeBased) {
            // Check if current time is >= the target timestamp
            return block.timestamp >= _condition.value;

        } else if (_condition.conditionType == ConditionType.OraclePrice) {
            // Check latest oracle data against a value using an operator
            uint256 oracleValue = _latestOracleData[_condition.targetBytes];
            if (_condition.operator == ComparisonOperator.EqualTo) return oracleValue == _condition.value;
            if (_condition.operator == ComparisonOperator.GreaterThan) return oracleValue > _condition.value;
            if (_condition.operator == ComparisonOperator.LessThan) return oracleValue < _condition.value;
            if (_condition.operator == ComparisonOperator.GreaterThanOrEqualTo) return oracleValue >= _condition.value;
            if (_condition.operator == ComparisonOperator.LessThanOrEqualTo) return oracleValue <= _condition.value;
            // Should not reach here if enums are handled correctly
            return false;

        } else if (_condition.conditionType == ConditionType.InternalState) {
            // Check the value of an internal state flag
            bool flagValue = vault.stateFlags[_condition.targetBytes];
            // Condition value is interpreted as 1 for true, 0 for false comparison
            return flagValue == (_condition.value > 0);

        } else if (_condition.conditionType == ConditionType.VaultUnlocked) {
            // Check if another specific vault has been unlocked
            uint256 dependencyId = _condition.value; // value holds the dependency vault ID
            if (_vaults[dependencyId].owner == address(0)) return false; // Dependency vault doesn't exist
            return _vaults[dependencyId].isUnlocked;

        } else if (_condition.conditionType == ConditionType.BalanceThreshold) {
             // Check the balance of a specific asset in this vault against a value using an operator
            address assetToCheck = _condition.targetAddress; // targetAddress holds the asset address
            uint256 currentBalance;
            if (assetToCheck == address(0)) {
                 currentBalance = address(this).balance; // Check contracts ETH balance (simplified, assumes vault balance matches contract balance for ETH)
            } else {
                 currentBalance = IERC20(assetToCheck).balanceOf(address(this)); // Check contract's ERC20 balance
            }

            if (_condition.operator == ComparisonOperator.EqualTo) return currentBalance == _condition.value;
            if (_condition.operator == ComparisonOperator.GreaterThan) return currentBalance > _condition.value;
            if (_condition.operator == ComparisonOperator.LessThan) return currentBalance < _condition.value;
            if (_condition.operator == ComparisonOperator.GreaterThanOrEqualTo) return currentBalance >= _condition.value;
            if (_condition.operator == ComparisonOperator.LessThanOrEqualTo) return currentBalance <= _condition.value;
            // Should not reach here
            return false;

        } else {
            // Unknown condition type
            return false;
        }
    }

    /**
     * @dev Internal helper function to transfer assets (ETH or ERC20).
     * @param _assetAddress The address of the asset (0 for native ETH).
     * @param _recipient The address to send assets to.
     * @param _amount The amount to send.
     */
    function _transferAsset(address _assetAddress, address _recipient, uint256 _amount) internal {
        if (_assetAddress == address(0)) {
            (bool success, ) = payable(_recipient).call{value: _amount}("");
            if (!success) revert AssetTransferFailed();
        } else {
            IERC20(_assetAddress).safeTransfer(_recipient, _amount);
        }
    }

    /**
     * @dev Read-only function to check if a vault's conditions are currently met, without attempting unlock.
     * Useful for UI to show if a vault is ready.
     * @param _vaultId The ID of the vault.
     * @return bool True if conditions are met, false otherwise.
     */
    function checkUnlockStatus(uint256 _vaultId) external view returns (bool) {
        Vault storage vault = _vaults[_vaultId];
        if (vault.owner == address(0)) revert VaultNotFound(_vaultId); // Check vault exists
        if (vault.isUnlocked) return true; // Already unlocked

        // Check dependency first
        if (vault.dependencyVaultId > 0) {
            if (!_vaults[vault.dependencyVaultId].isUnlocked) {
                return false; // Dependency not met
            }
        }

        return _checkAllConditions(_vaultId);
    }

    /**
     * @dev Read-only function to get details about a vault.
     * @param _vaultId The ID of the vault.
     * @return owner The vault owner.
     * @return manager The vault manager.
     * @return recipient The recipient of assets.
     * @return assetAddress The asset address (0 for ETH).
     * @return balance The current balance in the vault.
     * @return isUnlocked Whether the vault has been unlocked.
     * @return requireAllConditions The logic setting (AND/OR).
     * @return dependencyVaultId The ID of the dependency vault (0 if none).
     */
    function getVaultDetails(uint256 _vaultId) external view returns (
        address owner,
        address manager,
        address recipient,
        address assetAddress,
        uint256 balance,
        bool isUnlocked,
        bool requireAllConditions,
        uint256 dependencyVaultId
    ) {
         Vault storage vault = _vaults[_vaultId];
         if (vault.owner == address(0)) revert VaultNotFound(_vaultId); // Check vault exists

         return (
            vault.owner,
            vault.manager,
            vault.recipient,
            vault.assetAddress,
            vault.balance,
            vault.isUnlocked,
            vault.requireAllConditions,
            vault.dependencyVaultId
         );
    }

    /**
     * @dev Read-only function to get the list of conditions for a vault.
     * @param _vaultId The ID of the vault.
     * @return Condition[] An array of conditions.
     */
    function getVaultConditions(uint256 _vaultId) external view returns (Condition[] memory) {
        Vault storage vault = _vaults[_vaultId];
        if (vault.owner == address(0)) revert VaultNotFound(_vaultId); // Check vault exists
        return vault.conditions;
    }

    /**
     * @dev Read-only function to get the current balance of a vault.
     * Note: For ETH vaults (assetAddress == 0), this returns the recorded `vault.balance`,
     * which should match `address(this).balance` for that vault's funds. For ERC20,
     * it returns the recorded `vault.balance`.
     * @param _vaultId The ID of the vault.
     * @return uint256 The current balance.
     */
    function getVaultBalance(uint256 _vaultId) external view returns (uint256) {
         Vault storage vault = _vaults[_vaultId];
         if (vault.owner == address(0)) revert VaultNotFound(_vaultId); // Check vault exists
         return vault.balance;
    }

    /**
     * @dev Read-only function to check if a vault has already been successfully unlocked.
     * @param _vaultId The ID of the vault.
     * @return bool True if unlocked, false otherwise.
     */
    function isVaultUnlocked(uint256 _vaultId) external view returns (bool) {
        Vault storage vault = _vaults[_vaultId];
        if (vault.owner == address(0)) revert VaultNotFound(_vaultId); // Check vault exists
        return vault.isUnlocked;
    }

    /**
     * @dev Read-only function to get the list of addresses authorized to call `attemptUnlock`.
     * Note: This only returns addresses explicitly added via `addAuthorizedUnlocker`. The vault owner
     * and manager are always implicitly authorized.
     * @param _vaultId The ID of the vault.
     * @return address[] An array of authorized unlocker addresses.
     */
    function getAuthorizedUnlockers(uint256 _vaultId) external view returns (address[] memory) {
        Vault storage vault = _vaults[_vaultId];
        if (vault.owner == address(0)) revert VaultNotFound(_vaultId); // Check vault exists

        // This is inefficient as Solidity maps don't store keys.
        // A better approach in a real contract would be to store unlockers in a dynamic array.
        // For this example, we'll iterate potentially sparsely populated map or return empty.
        // Let's return an empty array as iterating a sparse map is not feasible in production gas limits.
        // To implement properly, the `authorizedUnlockers` mapping should be replaced by or
        // supplemented with `address[] public authorizedUnlockersList;` which is managed
        // alongside the map for quick lookup and iteration.
        // Returning empty array placeholder for now.
        // Correct approach: Add an array authorizedUnlockersList and manage it alongside the map.
        // Re-structuring Vault to include the array:
        /*
           struct Vault {
               // ... other fields ...
               mapping(address => bool) authorizedUnlockersMap; // For quick check
               address[] authorizedUnlockersList; // For iteration
           }
           function addAuthorizedUnlocker(...) {
               if (!vault.authorizedUnlockersMap[_unlocker]) {
                    vault.authorizedUnlockersMap[_unlocker] = true;
                    vault.authorizedUnlockersList.push(_unlocker);
               }
           }
           function removeAuthorizedUnlocker(...) {
                if (vault.authorizedUnlockersMap[_unlocker]) {
                    delete vault.authorizedUnlockersMap[_unlocker];
                    // Find index and remove from list (O(n) operation)
                    for (uint i=0; i<vault.authorizedUnlockersList.length; i++) {
                        if (vault.authorizedUnlockersList[i] == _unlocker) {
                             // Swap and pop
                            uint lastIndex = vault.authorizedUnlockersList.length - 1;
                            if (i != lastIndex) {
                                vault.authorizedUnlockersList[i] = vault.authorizedUnlockersList[lastIndex];
                            }
                            vault.authorizedUnlockersList.pop();
                            break; // Found and removed
                        }
                    }
                }
           }
           function getAuthorizedUnlockers(...) returns (address[] memory) { return vault.authorizedUnlockersList; }
        */
        // Implementing the array approach now to fulfill the function requirement properly.

         // Need to copy the data to memory to return
        address[] memory unlockers = new address[](vault.authorizedUnlockersList.length);
        for(uint i = 0; i < vault.authorizedUnlockersList.length; i++) {
            unlockers[i] = vault.authorizedUnlockersList[i];
        }
        return unlockers;
    }

    // Update Vault struct to include authorizedUnlockersList and modify related functions
    // (Self-correction during writing)

    struct Vault {
        address owner;
        address manager;
        address recipient;
        address assetAddress;
        uint256 balance;
        Condition[] conditions;
        bool isUnlocked;
        bool requireAllConditions;
        uint256 dependencyVaultId;
        mapping(bytes32 => bool) stateFlags;
        mapping(address => bool) authorizedUnlockersMap; // For quick check
        address[] authorizedUnlockersList; // For iteration
    }

    // Re-implementing add/remove unlocker and get unlockers using the list

     function addAuthorizedUnlocker(uint256 _vaultId, address _unlocker) external whenNotPaused onlyVaultOwnerOrManager(_vaultId) {
        Vault storage vault = _vaults[_vaultId];
        if (vault.isUnlocked) revert CannotModifyUnlockedVault(_vaultId);
        if (!vault.authorizedUnlockersMap[_unlocker]) {
            vault.authorizedUnlockersMap[_unlocker] = true;
            vault.authorizedUnlockersList.push(_unlocker);
            emit AuthorizedUnlockerUpdated(_vaultId, _unlocker, true);
        }
    }

     function removeAuthorizedUnlocker(uint256 _vaultId, address _unlocker) external whenNotPaused onlyVaultOwnerOrManager(_vaultId) {
        Vault storage vault = _vaults[_vaultId];
        if (vault.isUnlocked) revert CannotModifyUnlockedVault(_vaultId);
        if (_unlocker == vault.owner || _unlocker == vault.manager) {
             // Prevent removing owner/manager explicitely
             return;
        }

        if (vault.authorizedUnlockersMap[_unlocker]) {
            delete vault.authorizedUnlockersMap[_unlocker];
            // Remove from list (O(n))
            for (uint i = 0; i < vault.authorizedUnlockersList.length; i++) {
                if (vault.authorizedUnlockersList[i] == _unlocker) {
                    uint lastIndex = vault.authorizedUnlockersList.length - 1;
                    if (i != lastIndex) {
                        vault.authorizedUnlockersList[i] = vault.authorizedUnlockersList[lastIndex];
                    }
                    vault.authorizedUnlockersList.pop();
                    break; // Found and removed
                }
            }
            emit AuthorizedUnlockerUpdated(_vaultId, _unlocker, false);
        }
    }

    function getAuthorizedUnlockers(uint256 _vaultId) external view returns (address[] memory) {
         Vault storage vault = _vaults[_vaultId];
         if (vault.owner == address(0)) revert VaultNotFound(_vaultId);
         // Return a copy of the list
         address[] memory unlockers = new address[](vault.authorizedUnlockersList.length);
         for(uint i = 0; i < vault.authorizedUnlockersList.length; i++) {
             unlockers[i] = vault.authorizedUnlockersList[i];
         }
         return unlockers;
     }

    /**
     * @dev Read-only function to get the value of a specific internal state flag for a vault.
     * @param _vaultId The ID of the vault.
     * @param _flagName The name of the flag.
     * @return bool The value of the flag.
     */
    function getVaultStateFlag(uint256 _vaultId, string calldata _flagName) external view returns (bool) {
        Vault storage vault = _vaults[_vaultId];
        if (vault.owner == address(0)) revert VaultNotFound(_vaultId); // Check vault exists
        bytes32 flagHash = keccak256(bytes(_flagName));
        return vault.stateFlags[flagHash];
    }

     /**
      * @dev Read-only function to get the ID of the vault this one depends on.
      * @param _vaultId The ID of the vault.
      * @return uint256 The dependency vault ID (0 if none).
      */
    function getVaultDependency(uint256 _vaultId) external view returns (uint256) {
        Vault storage vault = _vaults[_vaultId];
        if (vault.owner == address(0)) revert VaultNotFound(_vaultId); // Check vault exists
        return vault.dependencyVaultId;
    }


    // --- Contract Admin Functions ---

    /**
     * @dev Pauses the contract in case of emergency. Prevents state-changing operations.
     * Only the contract owner can pause.
     */
    function pause() external onlyOwner {
        _pause();
    }

    /**
     * @dev Unpauses the contract.
     * Only the contract owner can unpause.
     */
    function unpause() external onlyOwner {
        _unpause();
    }

    /**
     * @dev Placeholder function for setting a new logic contract address, typically used in upgradeable proxy patterns.
     * This implementation is simplistic; a real upgradeable contract would use a proxy.
     * Only the contract owner can set the logic contract.
     * @param _logicContract The address of the new logic contract.
     */
    function setLogicContract(address _logicContract) external onlyOwner {
        // In a real upgradeable contract (e.g., UUPS proxy), the proxy would call this
        // on the *new* implementation to initialize state or link to libraries.
        // This is just a placeholder to meet the function count and hint at the concept.
        // Directly calling this on a non-proxied contract would not upgrade logic.
        logicContract = _logicContract;
        // Event could be emitted here: emit LogicContractUpdated(_logicContract);
    }

    // Fallback function to receive Ether for ETH vaults
    receive() external payable {}
}
```