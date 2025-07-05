Okay, let's create a smart contract concept around "MetaMorph Assets" – a registry that manages modules which can dynamically change the *state* or *characteristics* of registered assets (like NFTs), based on on-chain or off-chain conditions verifiable on-chain.

This concept is creative because it separates the asset itself from its potential future states and the logic that governs those state changes. It's advanced/trendy because it involves modularity, dynamic NFTs/assets, and potentially integrates with external data/oracles via the modules. It's not a standard token, marketplace, or simple access control contract.

We'll call this contract `MetaMorphRegistry`.

**Concept:**

The `MetaMorphRegistry` is a central hub for managing `Morph Modules`. `Morph Modules` are external smart contracts that implement a specific interface (`IMorphModule`). These modules contain the logic to transform, update, or query the state of a registered asset. An asset (identified by a unique `assetId`, potentially an NFT token ID) can be *bound* to one or more registered `Morph Modules`. Users or authorized entities can then trigger morphing processes on the asset using its bound modules, potentially passing in data (e.g., conditions, parameters). The registry ensures the module is valid, bound, and callable.

**Outline:**

1.  ** SPDX-License-Identifier & Pragma**
2.  ** Imports** (for Context, AccessControl, ERC165)
3.  ** Interfaces** (`IMorphModule`)
4.  ** Events**
    *   ModuleRegistered, ModuleUnregistered, ModuleInfoUpdated, ModuleStatusChanged
    *   AssetModuleBound, AssetModuleUnbound
    *   MorphExecuted, MorphBatchExecuted, MorphExecutedWithCondition
    *   ModuleExecutionPaused, ModuleExecutionUnpaused
5.  ** Structs** (`ModuleInfo`)
6.  ** State Variables**
    *   Mapping for registered modules (`_isModuleRegistered`)
    *   Mapping for module information (`_moduleInfo`)
    *   Array to track registered module addresses (for iteration/counting) (`_registeredModuleAddresses`)
    *   Mapping for asset-module bindings (`_assetModuleBindings`)
    *   Mapping to track paused module execution (`_isModuleExecutionPaused`)
    *   Access Control role for module registration (`REGISTRAR_ROLE`)
7.  ** Constructor** (Initializes Access Control)
8.  ** Modifiers** (Optional, can use `require` statements)
9.  ** ERC165 Support** (`supportsInterface`)
10. ** Module Management Functions** (Register, unregister, update, status, query)
11. ** Asset-Module Binding Functions** (Bind, unbind, query binding)
12. ** Morph Execution Functions** (Execute, batch execute, execute with condition, query state)
13. ** Execution Control Functions** (Pause/unpause module execution)
14. ** Access Control / Role Management Functions** (Inherited from AccessControl, potentially exposed/wrapped)

**Function Summary:**

Here are 20+ functions, categorized:

**Module Management:**

1.  `registerMorphModule(address moduleAddress, ModuleInfo info)`: Registers a new `Morph Module` address with associated metadata. Requires `REGISTRAR_ROLE`.
2.  `unregisterMorphModule(address moduleAddress)`: Unregisters an existing `Morph Module`. Requires `REGISTRAR_ROLE`. Also unbinds it from all assets (costly!). *Alternative: Mark as inactive instead of full unregister.* Let's implement deactivation instead for safety/history.
3.  `updateModuleInfo(address moduleAddress, ModuleInfo info)`: Updates the metadata for a registered module. Requires `REGISTRAR_ROLE` or potentially module owner (if we track that). Let's stick to `REGISTRAR_ROLE` for simplicity in this contract.
4.  `setModuleStatus(address moduleAddress, bool active)`: Sets the active status of a registered module. Inactive modules cannot be bound or executed. Requires `REGISTRAR_ROLE`.
5.  `getModuleInfo(address moduleAddress)`: Retrieves the `ModuleInfo` for a registered module.
6.  `isModuleRegistered(address moduleAddress)`: Checks if an address is registered as a module (regardless of status).
7.  `isModuleActive(address moduleAddress)`: Checks if a module is registered *and* active.
8.  `getRegisteredModuleCount()`: Returns the total number of registered modules (including inactive ones).
9.  `getModuleAddressAtIndex(uint256 index)`: Gets the address of a registered module by its index in the internal array. (Note: Iterating arrays is gas-intensive).

**Asset-Module Binding:**

10. `bindModuleToAsset(uint256 assetId, address moduleAddress)`: Binds a registered and active `Morph Module` to a specific asset ID. Caller might need to be the asset owner or approved. For this registry, we'll allow anyone to *attempt* to bind, but the module or asset contract might have its own checks. The registry just tracks the binding.
11. `unbindModuleFromAsset(uint256 assetId, address moduleAddress)`: Unbinds a module from an asset. Caller might need permissions (asset owner/approved).
12. `isModuleBoundToAsset(uint256 assetId, address moduleAddress)`: Checks if a specific module is bound to an asset.
13. `getBoundModulesForAsset(uint256 assetId)`: Returns a list of addresses of modules currently bound to an asset. (Note: Iterating mappings/dynamic arrays can be gas-intensive). *Alternative: Return a struct with count and first N modules.* Let's return an array for now, noting gas costs.
14. `bindBatchModulesToAsset(uint256 assetId, address[] moduleAddresses)`: Binds multiple modules to an asset in a single transaction.
15. `unbindBatchModulesFromAsset(uint256 assetId, address[] moduleAddresses)`: Unbinds multiple modules from an asset.

**Morph Execution & Querying:**

16. `executeMorph(uint256 assetId, address moduleAddress, bytes calldata morphData)`: Triggers the `execute` function on a specific module for a given asset. Requires the module to be registered, active, not paused, and bound to the asset. `morphData` is passed to the module.
17. `executeBatchMorphs(uint256 assetId, address[] moduleAddresses, bytes[] calldata morphDatas)`: Executes multiple morphs for an asset using corresponding modules and data.
18. `executeMorphWithCondition(uint256 assetId, address moduleAddress, bytes calldata morphData, address conditionModule, bytes calldata conditionData)`: Executes a morph *only if* the `checkCondition` function on a separate `conditionModule` (must also be registered, active, not paused) returns true when called with `assetId` and `conditionData`.
19. `queryAssetMorphState(uint256 assetId, address moduleAddress, bytes calldata queryData)`: Calls the `queryState` function on a specific module for an asset to retrieve dynamic state information without triggering a state-changing morph. Requires the module to be registered, active, and bound.
20. `simulateMorphExecution(uint256 assetId, address moduleAddress, bytes calldata morphData)`: Calls a hypothetical `simulate` function on the module (if the module interface includes one) to allow clients to preview the outcome of a morph without execution. Requires the module to be registered, active, and bound.

**Execution Control:**

21. `pauseModuleExecution(address moduleAddress)`: Temporarily pauses execution calls (`execute`, `executeBatch`, `executeWithCondition`) for a specific module. Binding/unbinding is still allowed. Requires `REGISTRAR_ROLE`.
22. `unpauseModuleExecution(address moduleAddress)`: Unpauses execution for a module. Requires `REGISTRAR_ROLE`.
23. `isModuleExecutionPaused(address moduleAddress)`: Checks if a module's execution is currently paused.

**Access Control (Inherited from OpenZeppelin's AccessControl):**

24. `grantRole(bytes32 role, address account)`: Grants a role to an account. (e.g., granting `REGISTRAR_ROLE`).
25. `revokeRole(bytes32 role, address account)`: Revokes a role from an account.
26. `renounceRole(bytes32 role, address account)`: Allows an account to remove its own role.
27. `hasRole(bytes32 role, address account)`: Checks if an account has a specific role.

This structure provides a flexible system where different types of "morphing" logic can be plugged in as separate contracts, and assets can subscribe to these capabilities dynamically.

Let's write the code.

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Context} from "@openzeppelin/contracts/utils/Context.sol";
import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {ERC165} from "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";

// --- Outline ---
// 1. SPDX-License-Identifier & Pragma
// 2. Imports
// 3. Interfaces (IMorphModule)
// 4. Events
// 5. Structs (ModuleInfo)
// 6. State Variables
// 7. Constructor
// 8. ERC165 Support
// 9. Module Management Functions
// 10. Asset-Module Binding Functions
// 11. Morph Execution Functions
// 12. Execution Control Functions
// 13. Access Control / Role Management Functions (Inherited)

// --- Function Summary ---
// Module Management:
// 1. registerMorphModule(address moduleAddress, ModuleInfo info): Registers a new Morph Module. (REGISTRAR_ROLE)
// 2. setModuleStatus(address moduleAddress, bool active): Sets the active status of a module. (REGISTRAR_ROLE)
// 3. updateModuleInfo(address moduleAddress, ModuleInfo info): Updates metadata for a module. (REGISTRAR_ROLE)
// 4. getModuleInfo(address moduleAddress): Retrieves module metadata.
// 5. isModuleRegistered(address moduleAddress): Checks if an address is registered.
// 6. isModuleActive(address moduleAddress): Checks if a module is registered and active.
// 7. getRegisteredModuleCount(): Returns the total number of registered modules.
// 8. getModuleAddressAtIndex(uint256 index): Gets module address by index. (Gas consideration)
//
// Asset-Module Binding:
// 9. bindModuleToAsset(uint256 assetId, address moduleAddress): Binds a module to an asset.
// 10. unbindModuleFromAsset(uint256 assetId, address moduleAddress): Unbinds a module from an asset.
// 11. isModuleBoundToAsset(uint256 assetId, address moduleAddress): Checks binding status.
// 12. getBoundModulesForAsset(uint256 assetId): Gets list of bound modules for an asset. (Gas consideration)
// 13. bindBatchModulesToAsset(uint256 assetId, address[] moduleAddresses): Binds multiple modules.
// 14. unbindBatchModulesFromAsset(uint256 assetId, address[] moduleAddresses): Unbinds multiple modules.
//
// Morph Execution & Querying:
// 15. executeMorph(uint256 assetId, address moduleAddress, bytes calldata morphData): Executes a morph via a bound module.
// 16. executeBatchMorphs(uint256 assetId, address[] moduleAddresses, bytes[] calldata morphDatas): Executes multiple morphs.
// 17. executeMorphWithCondition(uint256 assetId, address moduleAddress, bytes calldata morphData, address conditionModule, bytes calldata conditionData): Executes morph conditionally.
// 18. queryAssetMorphState(uint256 assetId, address moduleAddress, bytes calldata queryData): Queries asset state via a module. (view function)
// 19. simulateMorphExecution(uint256 assetId, address moduleAddress, bytes calldata morphData): Calls simulation function on module. (view function)
//
// Execution Control:
// 20. pauseModuleExecution(address moduleAddress): Pauses execution for a module. (REGISTRAR_ROLE)
// 21. unpauseModuleExecution(address moduleAddress): Unpauses execution. (REGISTRAR_ROLE)
// 22. isModuleExecutionPaused(address moduleAddress): Checks if module execution is paused.
//
// Access Control (Inherited):
// 23. grantRole(bytes32 role, address account)
// 24. revokeRole(bytes32 role, address account)
// 25. renounceRole(bytes32 role, address account)
// 26. hasRole(bytes32 role, address account)
// 27. SupportsInterface (ERC165)

/**
 * @title IMorphModule
 * @dev Interface for pluggable Morph Modules.
 * Modules define the specific logic for how an asset can morph or how its state is determined.
 * The registry calls functions on implementations of this interface.
 */
interface IMorphModule {
    /**
     * @dev Executes a state-changing morph operation on an asset.
     * @param assetId The ID of the asset to morph (e.g., NFT token ID).
     * @param morphData Arbitrary data passed from the registry caller to the module,
     *                  containing parameters for the morphing logic.
     * @return success True if the morph executed successfully.
     * @return returnData Arbitrary data returned by the module (e.g., new state hash, results).
     */
    function execute(uint256 assetId, bytes calldata morphData) external returns (bool success, bytes memory returnData);

    /**
     * @dev Checks if a condition is met for an asset. Used by executeMorphWithCondition.
     * @param assetId The ID of the asset.
     * @param conditionData Arbitrary data for the condition check logic.
     * @return met True if the condition is met, false otherwise.
     */
    function checkCondition(uint256 assetId, bytes calldata conditionData) external view returns (bool met);

    /**
     * @dev Queries the current or potential state of an asset without state changes.
     * @param assetId The ID of the asset.
     * @param queryData Arbitrary data for the state query logic.
     * @return stateData Arbitrary data representing the queried state.
     */
    function queryState(uint256 assetId, bytes calldata queryData) external view returns (bytes memory stateData);

    /**
     * @dev Simulates a morph execution without state changes. Optional function for modules.
     * @param assetId The ID of the asset.
     * @param morphData Arbitrary data for the simulation logic.
     * @return success True if the simulation was conceptually successful.
     * @return returnData Arbitrary data representing the simulated outcome.
     */
    function simulate(uint256 assetId, bytes calldata morphData) external view returns (bool success, bytes memory returnData);

    /**
     * @dev Standard ERC165 interface support. Module should indicate support for IMorphModule.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}


/**
 * @title MetaMorphRegistry
 * @dev A registry for managing dynamic "Morph Modules" that can alter or query
 *      the state of registered assets (e.g., NFTs). Assets can be bound to
 *      multiple modules to inherit dynamic capabilities.
 */
contract MetaMorphRegistry is Context, AccessControl, ERC165 {

    // --- Constants ---

    bytes32 public constant REGISTRAR_ROLE = keccak256("REGISTRAR_ROLE");

    // --- Events ---

    /**
     * @dev Emitted when a new module is registered.
     * @param moduleAddress The address of the registered module contract.
     * @param registrar The address that registered the module.
     */
    event ModuleRegistered(address indexed moduleAddress, address indexed registrar);

    /**
     * @dev Emitted when module metadata is updated.
     * @param moduleAddress The address of the module.
     * @param updater The address that updated the info.
     */
    event ModuleInfoUpdated(address indexed moduleAddress, address indexed updater);

    /**
     * @dev Emitted when a module's active status changes.
     * @param moduleAddress The address of the module.
     * @param active The new active status.
     * @param updater The address that changed the status.
     */
    event ModuleStatusChanged(address indexed moduleAddress, bool active, address indexed updater);

    /**
     * @dev Emitted when a module is bound to an asset.
     * @param assetId The ID of the asset.
     * @param moduleAddress The address of the module.
     * @param binder The address that performed the binding.
     */
    event AssetModuleBound(uint256 indexed assetId, address indexed moduleAddress, address indexed binder);

    /**
     * @dev Emitted when a module is unbound from an asset.
     * @param assetId The ID of the asset.
     * @param moduleAddress The address of the module.
     * @param unbinder The address that performed the unbinding.
     */
    event AssetModuleUnbound(uint256 indexed assetId, address indexed moduleAddress, address indexed unbinder);

    /**
     * @dev Emitted when a morph is executed via a module.
     * @param assetId The ID of the asset.
     * @param moduleAddress The address of the module.
     * @param executor The address that triggered the execution.
     * @param success True if the module call was successful.
     * @param returnData Data returned by the module's execute function.
     */
    event MorphExecuted(uint256 indexed assetId, address indexed moduleAddress, address indexed executor, bool success, bytes returnData);

     /**
     * @dev Emitted when a batch of morphs is executed.
     * @param assetId The ID of the asset.
     * @param moduleAddresses The addresses of the modules executed.
     * @param executor The address that triggered the execution.
     */
    event MorphBatchExecuted(uint256 indexed assetId, address[] moduleAddresses, address indexed executor);

    /**
     * @dev Emitted when morph execution for a module is paused or unpaused.
     * @param moduleAddress The address of the module.
     * @param paused The new paused status.
     * @param pauser The address that changed the pause status.
     */
    event ModuleExecutionPaused(address indexed moduleAddress, bool paused, address indexed pauser);


    // --- Structs ---

    /**
     * @dev Metadata associated with a registered Morph Module.
     * Can include human-readable name, description, version, etc.
     */
    struct ModuleInfo {
        string name;
        string description;
        uint256 version;
        address moduleOwner; // Optional: Creator/owner of the module contract itself
    }

    // --- State Variables ---

    // Mapping to check if a module address is registered
    mapping(address => bool) private _isModuleRegistered;

    // Mapping to store module information
    mapping(address => ModuleInfo) private _moduleInfo;

    // Array to store registered module addresses for iteration (handle gas costs for large arrays)
    address[] private _registeredModuleAddresses;

    // Mapping to track active status of modules
    mapping(address => bool) private _isModuleActive;

    // Mapping to track modules bound to each assetId: assetId => moduleAddress => isBound
    mapping(uint256 => mapping(address => bool)) private _assetModuleBindings;

    // Mapping to track which modules have execution paused
    mapping(address => bool) private _isModuleExecutionPaused;

    // --- Constructor ---

    /**
     * @dev Initializes the contract and grants the deployer the DEFAULT_ADMIN_ROLE
     * and the REGISTRAR_ROLE.
     */
    constructor() payable {
        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _grantRole(REGISTRAR_ROLE, _msgSender());
        _registerInterface(type(IMorphModule).interfaceId); // Register support for the module interface (internal for this contract)
        _registerInterface(type(AccessControl).interfaceId);
        _registerInterface(type(ERC165).interfaceId);
    }

    // --- ERC165 Support ---

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view override(AccessControl, ERC165) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    // --- Internal/Helper Functions ---

    /**
     * @dev Internal function to check if a module is valid for operations (registered, active, not paused).
     */
    function _isModuleValidForExecution(address moduleAddress) internal view returns (bool) {
        return _isModuleRegistered[moduleAddress] &&
               _isModuleActive[moduleAddress] &&
               !_isModuleExecutionPaused[moduleAddress];
    }

     /**
     * @dev Internal function to check if a module is valid for binding (registered, active).
     */
    function _isModuleValidForBinding(address moduleAddress) internal view returns (bool) {
        return _isModuleRegistered[moduleAddress] && _isModuleActive[moduleAddress];
    }


    // --- Module Management Functions ---

    /**
     * @dev Registers a new Morph Module address with associated information.
     * Only accounts with the `REGISTRAR_ROLE` can call this.
     * Reverts if the module address is zero or already registered.
     * It is expected that the `moduleAddress` points to a contract implementing `IMorphModule`.
     * @param moduleAddress The address of the Morph Module contract.
     * @param info Metadata for the module.
     */
    function registerMorphModule(address moduleAddress, ModuleInfo memory info)
        public
        onlyRole(REGISTRAR_ROLE)
    {
        require(moduleAddress != address(0), "MetaMorph: Zero address module");
        require(!_isModuleRegistered[moduleAddress], "MetaMorph: Module already registered");

        // Optional: Check if moduleAddress implements IMorphModule using ERC165
        // try IERC165(moduleAddress).supportsInterface(type(IMorphModule).interfaceId) returns (bool isSupported) {
        //     require(isSupported, "MetaMorph: Module must implement IMorphModule");
        // } catch {
        //     revert("MetaMorph: Module contract must support ERC165");
        // }

        _isModuleRegistered[moduleAddress] = true;
        _isModuleActive[moduleAddress] = true; // New modules are active by default
        _moduleInfo[moduleAddress] = info;
        _registeredModuleAddresses.push(moduleAddress); // Add to array for iteration

        emit ModuleRegistered(moduleAddress, _msgSender());
    }

    /**
     * @dev Sets the active status of a registered module.
     * Inactive modules cannot be bound to new assets or executed.
     * Only accounts with the `REGISTRAR_ROLE` can call this.
     * @param moduleAddress The address of the module.
     * @param active The new active status (true for active, false for inactive).
     */
    function setModuleStatus(address moduleAddress, bool active)
        public
        onlyRole(REGISTRAR_ROLE)
    {
        require(_isModuleRegistered[moduleAddress], "MetaMorph: Module not registered");
        require(_isModuleActive[moduleAddress] != active, "MetaMorph: Module status already set");

        _isModuleActive[moduleAddress] = active;
        // Optional: Unbind module from all assets if setting to inactive (costly!)
        // For simplicity, we'll just prevent new bindings and executions.

        emit ModuleStatusChanged(moduleAddress, active, _msgSender());
    }

    /**
     * @dev Updates the metadata information for a registered module.
     * Only accounts with the `REGISTRAR_ROLE` can call this.
     * @param moduleAddress The address of the module.
     * @param info The updated metadata.
     */
    function updateModuleInfo(address moduleAddress, ModuleInfo memory info)
        public
        onlyRole(REGISTRAR_ROLE)
    {
        require(_isModuleRegistered[moduleAddress], "MetaMorph: Module not registered");

        _moduleInfo[moduleAddress] = info;

        emit ModuleInfoUpdated(moduleAddress, _msgSender());
    }

    /**
     * @dev Retrieves the metadata for a registered module.
     * @param moduleAddress The address of the module.
     * @return ModuleInfo The metadata struct.
     */
    function getModuleInfo(address moduleAddress) public view returns (ModuleInfo memory) {
        require(_isModuleRegistered[moduleAddress], "MetaMorph: Module not registered");
        return _moduleInfo[moduleAddress];
    }

    /**
     * @dev Checks if an address is registered as a module.
     * @param moduleAddress The address to check.
     * @return bool True if registered, false otherwise.
     */
    function isModuleRegistered(address moduleAddress) public view returns (bool) {
        return _isModuleRegistered[moduleAddress];
    }

     /**
     * @dev Checks if a module is registered AND currently active.
     * @param moduleAddress The address to check.
     * @return bool True if registered and active, false otherwise.
     */
    function isModuleActive(address moduleAddress) public view returns (bool) {
        return _isModuleActive[moduleAddress];
    }

    /**
     * @dev Returns the total number of registered modules (active or inactive).
     * @return uint256 The count of registered modules.
     */
    function getRegisteredModuleCount() public view returns (uint256) {
        return _registeredModuleAddresses.length;
    }

    /**
     * @dev Gets the address of a registered module by its index.
     * Note: Iterating through this array might be gas-intensive if the number of modules is very large.
     * @param index The index in the internal list.
     * @return address The module address.
     */
    function getModuleAddressAtIndex(uint256 index) public view returns (address) {
        require(index < _registeredModuleAddresses.length, "MetaMorph: Index out of bounds");
        return _registeredModuleAddresses[index];
    }

    // --- Asset-Module Binding Functions ---

    /**
     * @dev Binds a registered and active module to an asset ID.
     * This contract doesn't enforce asset ownership, assuming that control over
     * binding is handled off-chain or by other systems (e.g., the asset contract itself).
     * Anyone can call this, but the recipient of the morph call (the asset owner/contract)
     * might reject calls from non-bound modules, or the module might check context.
     * Reverts if the module is not registered or not active.
     * @param assetId The ID of the asset (e.g., NFT token ID).
     * @param moduleAddress The address of the module to bind.
     */
    function bindModuleToAsset(uint256 assetId, address moduleAddress) public {
        require(_isModuleValidForBinding(moduleAddress), "MetaMorph: Module not registered or not active");
        require(!_assetModuleBindings[assetId][moduleAddress], "MetaMorph: Module already bound to asset");

        _assetModuleBindings[assetId][moduleAddress] = true;

        emit AssetModuleBound(assetId, moduleAddress, _msgSender());
    }

    /**
     * @dev Unbinds a module from an asset ID.
     * Similar to binding, this contract doesn't enforce asset ownership for unbinding.
     * @param assetId The ID of the asset.
     * @param moduleAddress The address of the module to unbind.
     */
    function unbindModuleFromAsset(uint256 assetId, address moduleAddress) public {
        require(_assetModuleBindings[assetId][moduleAddress], "MetaMorph: Module not bound to asset");

        _assetModuleBindings[assetId][moduleAddress] = false;

        emit AssetModuleUnbound(assetId, moduleAddress, _msgSender());
    }

    /**
     * @dev Checks if a specific module is bound to an asset.
     * @param assetId The ID of the asset.
     * @param moduleAddress The address of the module.
     * @return bool True if bound, false otherwise.
     */
    function isModuleBoundToAsset(uint256 assetId, address moduleAddress) public view returns (bool) {
        return _assetModuleBindings[assetId][moduleAddress];
    }

    /**
     * @dev Returns a list of module addresses currently bound to an asset.
     * Note: This function iterates through all registered modules and checks binding.
     * It can be gas-intensive if the number of registered modules is very large.
     * Consider alternative patterns if this needs to scale significantly.
     * @param assetId The ID of the asset.
     * @return address[] An array of bound module addresses.
     */
    function getBoundModulesForAsset(uint256 assetId) public view returns (address[] memory) {
        address[] memory boundModules = new address[](_registeredModuleAddresses.length);
        uint256 count = 0;
        // Iterate through all registered modules and check binding for the asset
        for (uint256 i = 0; i < _registeredModuleAddresses.length; i++) {
            address moduleAddress = _registeredModuleAddresses[i];
            if (_assetModuleBindings[assetId][moduleAddress]) {
                boundModules[count] = moduleAddress;
                count++;
            }
        }
        // Resize the array to fit only the bound modules
        address[] memory result = new address[](count);
        for (uint256 i = 0; i < count; i++) {
            result[i] = boundModules[i];
        }
        return result;
    }

     /**
     * @dev Binds multiple modules to an asset ID in a single transaction.
     * Reverts if any module is not registered or not active, or if any is already bound.
     * @param assetId The ID of the asset.
     * @param moduleAddresses The addresses of the modules to bind.
     */
    function bindBatchModulesToAsset(uint256 assetId, address[] calldata moduleAddresses) public {
        for (uint256 i = 0; i < moduleAddresses.length; i++) {
            address moduleAddress = moduleAddresses[i];
            require(_isModuleValidForBinding(moduleAddress), "MetaMorph: Module not valid for binding");
            require(!_assetModuleBindings[assetId][moduleAddress], "MetaMorph: Module already bound");
        }

        for (uint256 i = 0; i < moduleAddresses.length; i++) {
             _assetModuleBindings[assetId][moduleAddresses[i]] = true;
        }

        // Emit individual events for each binding for better logging
        for (uint256 i = 0; i < moduleAddresses.length; i++) {
             emit AssetModuleBound(assetId, moduleAddresses[i], _msgSender());
        }
    }

    /**
     * @dev Unbinds multiple modules from an asset ID in a single transaction.
     * Reverts if any module is not bound.
     * @param assetId The ID of the asset.
     * @param moduleAddresses The addresses of the modules to unbind.
     */
    function unbindBatchModulesFromAsset(uint256 assetId, address[] calldata moduleAddresses) public {
         for (uint256 i = 0; i < moduleAddresses.length; i++) {
            require(_assetModuleBindings[assetId][moduleAddresses[i]], "MetaMorph: Module not bound");
        }

        for (uint256 i = 0; i < moduleAddresses.length; i++) {
             _assetModuleBindings[assetId][moduleAddresses[i]] = false;
        }

         // Emit individual events for each unbinding
        for (uint256 i = 0; i < moduleAddresses.length; i++) {
             emit AssetModuleUnbound(assetId, moduleAddresses[i], _msgSender());
        }
    }


    // --- Morph Execution & Querying Functions ---

    /**
     * @dev Triggers the execution of a specific morph module for an asset.
     * The module must be registered, active, not paused, and bound to the asset.
     * Calls the `execute` function on the target module contract.
     * @param assetId The ID of the asset.
     * @param moduleAddress The address of the module to execute.
     * @param morphData Arbitrary data to pass to the module's execute function.
     * @return bool success The success status returned by the module's execute function.
     * @return bytes memory returnData The return data from the module's execute function.
     */
    function executeMorph(uint256 assetId, address moduleAddress, bytes calldata morphData)
        public
        returns (bool success, bytes memory returnData)
    {
        require(_assetModuleBindings[assetId][moduleAddress], "MetaMorph: Module not bound to asset");
        require(_isModuleValidForExecution(moduleAddress), "MetaMorph: Module not valid for execution");

        // Call the module contract
        (success, returnData) = IMorphModule(moduleAddress).execute(assetId, morphData);

        emit MorphExecuted(assetId, moduleAddress, _msgSender(), success, returnData);
    }

    /**
     * @dev Executes a batch of morph modules for an asset.
     * Each module must be registered, active, not paused, and bound to the asset.
     * Reverts if any module in the batch is invalid or not bound.
     * Note: Each module call is independent. If one fails, the others *may* still execute
     * depending on Solidity's low-level call behavior or if using interface calls.
     * Using interface calls here means if *any* call reverts, the whole transaction reverts.
     * If independent execution is needed, use low-level calls and handle success/failure individually.
     * We'll use interface calls for safety/simplicity assuming atomicity is desired.
     * @param assetId The ID of the asset.
     * @param moduleAddresses An array of module addresses to execute.
     * @param morphDatas An array of data corresponding to each module. Must have same length.
     */
    function executeBatchMorphs(uint256 assetId, address[] calldata moduleAddresses, bytes[] calldata morphDatas)
        public
    {
        require(moduleAddresses.length == morphDatas.length, "MetaMorph: Module/Data array length mismatch");

        // Pre-check all modules
        for (uint256 i = 0; i < moduleAddresses.length; i++) {
            address moduleAddress = moduleAddresses[i];
            require(_assetModuleBindings[assetId][moduleAddress], "MetaMorph: Module not bound to asset");
            require(_isModuleValidForExecution(moduleAddress), "MetaMorph: Module not valid for execution");
        }

        // Execute sequentially
        for (uint256 i = 0; i < moduleAddresses.length; i++) {
            address moduleAddress = moduleAddresses[i];
            bytes calldata morphData = morphDatas[i];
            // If independent execution is needed, use low-level call here:
            // (bool success, bytes memory returnData) = moduleAddress.call(abi.encodeWithSelector(IMorphModule.execute.selector, assetId, morphData));
            // emit MorphExecuted(...) // Emit event for each call result
            IMorphModule(moduleAddress).execute(assetId, morphData); // Using interface call - will revert batch if any fails
            // If using interface call, the event below covers the batch execution success
        }

        emit MorphBatchExecuted(assetId, moduleAddresses, _msgSender());
         // Note: Individual MorphExecuted events are NOT emitted when using the single batch event
         // If granular events are needed, the low-level call approach inside the loop is better.
    }


    /**
     * @dev Executes a morph module only if a condition checked by another module is met.
     * Both the execution module and the condition module must be registered, active, not paused,
     * and bound to the asset.
     * Calls `checkCondition` on `conditionModule` first, then `execute` on `moduleAddress` if true.
     * @param assetId The ID of the asset.
     * @param moduleAddress The address of the module to execute.
     * @param morphData Arbitrary data for the execution module.
     * @param conditionModule The address of the module to check the condition.
     * @param conditionData Arbitrary data for the condition module.
     * @return bool success True if the condition was met AND the execution module call succeeded.
     * @return bytes memory returnData The return data from the execution module (empty if condition not met).
     */
    function executeMorphWithCondition(
        uint256 assetId,
        address moduleAddress,
        bytes calldata morphData,
        address conditionModule,
        bytes calldata conditionData
    ) public returns (bool success, bytes memory returnData) {
        require(_assetModuleBindings[assetId][moduleAddress], "MetaMorph: Exec module not bound");
        require(_isModuleValidForExecution(moduleAddress), "MetaMorph: Exec module not valid");
        require(_assetModuleBindings[assetId][conditionModule], "MetaMorph: Condition module not bound");
        // Note: We allow calling checkCondition on a paused module, assuming condition checks are state-less queries.
        // If condition checks should also be paused, add: require(!_isModuleExecutionPaused[conditionModule], "MetaMorph: Condition module paused");
         require(_isModuleRegistered[conditionModule] && _isModuleActive[conditionModule], "MetaMorph: Condition module not valid");


        bool conditionMet;
        try IMorphModule(conditionModule).checkCondition(assetId, conditionData) returns (bool met) {
            conditionMet = met;
        } catch {
             // Consider how to handle failures in condition check (revert or assume false)
             // Reverting is safer if condition checks are critical.
             revert("MetaMorph: Failed to call condition module checkCondition");
        }


        success = false; // Assume failure unless execution happens and succeeds
        returnData = bytes(""); // Assume empty return data unless execution happens

        if (conditionMet) {
            // Condition met, now execute the target morph module
             (success, returnData) = IMorphModule(moduleAddress).execute(assetId, morphData);
        }

        // Note: Event emitted only if execution was attempted (i.e., conditionMet is true)
        if (conditionMet) {
             emit MorphExecuted(assetId, moduleAddress, _msgSender(), success, returnData);
        }
         // No specific event for 'condition not met' currently

        return (conditionMet && success, returnData); // Return true only if condition was met AND execution succeeded
    }

    /**
     * @dev Queries the state of an asset using a specific bound module.
     * Calls the `queryState` view function on the target module contract.
     * Module must be registered, active, and bound. Pause status is ignored for view calls.
     * @param assetId The ID of the asset.
     * @param moduleAddress The address of the module to query.
     * @param queryData Arbitrary data to pass to the module's queryState function.
     * @return bytes memory stateData The state data returned by the module.
     */
    function queryAssetMorphState(uint256 assetId, address moduleAddress, bytes calldata queryData)
        public
        view
        returns (bytes memory stateData)
    {
        require(_assetModuleBindings[assetId][moduleAddress], "MetaMorph: Module not bound to asset");
        // Note: Allowing queryState for paused modules, as it's a view function.
        require(_isModuleRegistered[moduleAddress] && _isModuleActive[moduleAddress], "MetaMorph: Module not valid for query");

        // Call the module contract's view function
        // Using try/catch for safer external view calls
        try IMorphModule(moduleAddress).queryState(assetId, queryData) returns (bytes memory data) {
            stateData = data;
        } catch {
             revert("MetaMorph: Failed to call module queryState");
        }
    }

    /**
     * @dev Calls the `simulate` function on a specific bound module for an asset.
     * This allows clients to preview the outcome of a morph without state changes.
     * Module must be registered, active, and bound. Pause status is ignored for view calls.
     * Reverts if the module does not implement the `simulate` function or the call fails.
     * @param assetId The ID of the asset.
     * @param moduleAddress The address of the module to simulate.
     * @param morphData Arbitrary data to pass to the module's simulate function.
     * @return bool success The success status returned by the module's simulate function.
     * @return bytes memory returnData The return data from the module's simulate function.
     */
     function simulateMorphExecution(uint256 assetId, address moduleAddress, bytes calldata morphData)
        public
        view
        returns (bool success, bytes memory returnData)
    {
        require(_assetModuleBindings[assetId][moduleAddress], "MetaMorph: Module not bound to asset");
        // Note: Allowing simulate for paused modules, as it's a view function.
        require(_isModuleRegistered[moduleAddress] && _isModuleActive[moduleAddress], "MetaMorph: Module not valid for simulate");

        // Call the module contract's simulate function
        // Using low-level call here because simulate is an optional part of the interface
        // and we need to handle potential lack of implementation gracefully (or revert as done here).
        (success, returnData) = moduleAddress.staticcall(abi.encodeWithSelector(IMorphModule.simulate.selector, assetId, morphData));
        require(success, "MetaMorph: Failed to call module simulate (or function not implemented)");

        return (success, returnData);
    }


    // --- Execution Control Functions ---

    /**
     * @dev Pauses the execution calls (`execute`, `executeBatch`, `executeWithCondition`)
     * for a specific module. Binding and querying are still allowed.
     * Only accounts with the `REGISTRAR_ROLE` can call this.
     * @param moduleAddress The address of the module to pause.
     */
    function pauseModuleExecution(address moduleAddress) public onlyRole(REGISTRAR_ROLE) {
        require(_isModuleRegistered[moduleAddress], "MetaMorph: Module not registered");
        require(!_isModuleExecutionPaused[moduleAddress], "MetaMorph: Module execution already paused");

        _isModuleExecutionPaused[moduleAddress] = true;

        emit ModuleExecutionPaused(moduleAddress, true, _msgSender());
    }

    /**
     * @dev Unpauses execution calls for a specific module.
     * Only accounts with the `REGISTRAR_ROLE` can call this.
     * @param moduleAddress The address of the module to unpause.
     */
    function unpauseModuleExecution(address moduleAddress) public onlyRole(REGISTRAR_ROLE) {
        require(_isModuleRegistered[moduleAddress], "MetaMorph: Module not registered");
        require(_isModuleExecutionPaused[moduleAddress], "MetaMorph: Module execution not paused");

        _isModuleExecutionPaused[moduleAddress] = false;

        emit ModuleExecutionPaused(moduleAddress, false, _msgSender());
    }

    /**
     * @dev Checks if execution calls for a specific module are paused.
     * @param moduleAddress The address of the module.
     * @return bool True if paused, false otherwise.
     */
    function isModuleExecutionPaused(address moduleAddress) public view returns (bool) {
        return _isModuleExecutionPaused[moduleAddress];
    }

    // --- Access Control Functions (Inherited from AccessControl) ---
    // These are standard and not listed explicitly in the summary count,
    // but they are part of the contract's functionality provided by the library.
    // grantRole, revokeRole, renounceRole, hasRole, _setupRole are available.
    // We've used `onlyRole(REGISTRAR_ROLE)` above.
    // The constructor grants DEFAULT_ADMIN_ROLE and REGISTRAR_ROLE to the deployer.
}
```

**Explanation of Advanced/Trendy Concepts Used:**

1.  **Modularity:** The core idea is modularity. The `MetaMorphRegistry` is agnostic to the specific "morphing" logic, which resides in external `IMorphModule` contracts. This allows for a diverse ecosystem of modules to be developed and plugged in.
2.  **Dynamic Assets:** This contract provides the *framework* for dynamic assets. An asset (like an NFT) bound to these modules can have its characteristics (metadata, visual representation, in-game stats) changed or determined dynamically by calling the bound modules. The module itself would contain the logic for *how* the state changes or is queried.
3.  **Separation of Concerns:** The asset (e.g., an ERC-721 contract) can be kept relatively simple, holding only the core ownership and possibly basic static metadata. The dynamic behavior is delegated to the modules managed by the registry.
4.  **Conditional Execution:** The `executeMorphWithCondition` function introduces a layer of on-chain logic where the execution of one module depends on the outcome of a check performed by *another* module. This allows for complex interaction patterns (e.g., "morph only if the weather module says it's raining").
5.  **State Querying:** The `queryAssetMorphState` function allows external parties or the asset itself to query the *current* dynamic state determined by a module *without* triggering a state change. This is crucial for displaying dynamic metadata or in-game stats.
6.  **Simulation (Optional):** The `simulateMorphExecution` function provides a standard way for UIs or other contracts to preview the outcome of a potential morph without actually executing it, improving user experience.
7.  **Role-Based Access Control:** Using OpenZeppelin's `AccessControl` provides a secure and flexible way to manage who can perform critical operations like registering modules. `REGISTRAR_ROLE` is a custom role defined for this purpose.
8.  **ERC-165 Interface Detection:** The contract declares support for ERC-165 and mentions the possibility of checking if registered modules also support the `IMorphModule` interface, promoting interoperability and robustness (though the explicit check is commented out for brevity, it's a good practice).
9.  **Batch Operations:** Including `bindBatchModulesToAsset` and `unbindBatchModulesFromAsset` allows for efficiency when setting up multiple modules for an asset. `executeBatchMorphs` allows triggering multiple effects simultaneously.

This contract serves as a sophisticated framework, enabling the creation of assets and ecosystems with complex, evolving behaviors governed by external, specialized logic modules.