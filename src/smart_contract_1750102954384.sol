Okay, here is a smart contract idea that aims for advanced concepts, creativity, and avoids direct copy-pasting of standard open-source implementations.

**Concept:** **Aetherium Chronicle (Dynamic Trait & Capability System)**

This contract acts as a decentralized, on-chain "chronicle" for users. It tracks predefined "Actions" performed by addresses (recorded by trusted entities or integrated systems). These actions dynamically influence user "Traits" (numerical scores like 'reliability', 'engagement', 'contribution_index'). Based on these dynamic traits meeting certain thresholds, users automatically unlock "Capabilities" or permissions within the ecosystem the Chronicle governs. The contract itself can facilitate "Permitted Actions" which are internal logic executions or external calls gated by these capabilities. It's a form of on-chain reputation/identity system that's dynamic and capability-driven, not based on transferable tokens.

**Advanced/Creative Aspects:**

1.  **Dynamic, Non-Transferable Traits:** Traits are scores tied to addresses, changing based on actions, potentially decaying over time. Not tokens.
2.  **Automated Capability Management:** Capabilities are automatically granted/revoked based on current trait values, evaluated upon state changes (like recording an action or applying decay).
3.  **Conditional Execution (`executePermittedAction`):** A core function that allows *anyone* to request an action, but the action only proceeds *if* the caller possesses the required capability, potentially routing execution to registered module contracts.
4.  **Action & Trait Configuration:** Admins can define new action types and trait types and how they interact, allowing the system to evolve.
5.  **Timed Trait Decay:** Traits can be configured to decay over time, requiring continued participation/positive actions to maintain status. (Requires external keeper or user trigger for gas).
6.  **Module Integration:** The contract can register external contract addresses as "modules" to which `executePermittedAction` can delegate specific logic based on capability.

---

**Outline and Function Summary:**

**I. Core Data Structures**
    *   `ActionType`: Defines a type of action and its effects on traits.
    *   `TraitType`: Defines a type of trait, including its decay properties.
    *   `Capability`: Defines a permission requiring specific trait thresholds.
    *   `UserProfile`: Stores a user's current traits, unlocked capabilities, and optional metadata.

**II. State Variables**
    *   Mappings for `actionTypes`, `traitTypes`, `capabilities`.
    *   Mapping for `userProfiles`.
    *   Mapping to track admin addresses.
    *   Mapping to track registered module addresses.
    *   Counters for unique IDs.
    *   Owner address.
    *   Pause flag.
    *   Mapping to store the last decay application timestamp per user (simplified decay trigger).

**III. Events**
    *   Notifications for significant state changes (Action Recorded, Trait Changed, Capability Status Changed, etc.).

**IV. Modifiers**
    *   `onlyOwner`: Restricts access to the contract owner.
    *   `onlyAdmin`: Restricts access to owner and defined admins.
    *   `whenNotPaused`: Prevents execution when the contract is paused.
    *   `whenPaused`: Allows execution only when paused.

**V. Functions**

    *   **Admin & Configuration (>= 10 functions):**
        1.  `initialize()`: Sets the initial owner and admin(s).
        2.  `grantAdminRole(address _admin)`: Grants admin privileges.
        3.  `revokeAdminRole(address _admin)`: Revokes admin privileges.
        4.  `defineActionType(string memory _name, TraitEffect[] memory _effects)`: Creates a new type of action that can be recorded.
        5.  `updateActionType(uint256 _actionTypeId, string memory _newName, TraitEffect[] memory _newEffects)`: Modifies an existing action type's configuration.
        6.  `defineTraitType(string memory _name, uint256 _decayRate, uint256 _decayInterval)`: Creates a new type of trait with decay properties.
        7.  `updateTraitType(uint256 _traitTypeId, string memory _newName, uint256 _newDecayRate, uint256 _newDecayInterval)`: Modifies an existing trait type's configuration.
        8.  `defineCapability(string memory _name, TraitThreshold[] memory _requiredThresholds)`: Creates a new capability requiring specific trait values.
        9.  `updateCapability(uint256 _capabilityId, string memory _newName, TraitThreshold[] memory _newRequiredThresholds)`: Modifies an existing capability's requirements.
        10. `setModuleAddress(bytes32 _moduleKey, address _moduleAddress)`: Registers an external contract address under a specific key for use in `executePermittedAction`.
        11. `removeModuleAddress(bytes32 _moduleKey)`: Deregisters a module address.
        12. `pause()`: Pauses user interactions (like recording actions).
        13. `unpause()`: Unpauses user interactions.
        14. `grantManualCapability(address _user, uint256 _capabilityId)`: Admin manually grants a capability (overriding trait requirements).
        15. `revokeManualCapability(address _user, uint256 _capabilityId)`: Admin manually revokes a capability.
        *(Total: 15 Admin/Config functions)*

    *   **User Interaction & Core Logic (>= 5 functions):**
        16. `recordAction(address _user, uint256 _actionTypeId)`: Records an action for a user, triggers trait updates and capability re-evaluation. (Likely called by integrated systems or authorized roles).
        17. `updateUserMetadata(string memory _metadata)`: Allows a user to update their associated metadata string.
        18. `executePermittedAction(uint256 _capabilityId, bytes32 _moduleKey, bytes memory _callData)`: Allows a caller to attempt to trigger logic (potentially in a module contract) *if* they possess the specified capability.
        19. `applyDecay(address _user)`: Allows a user (or keeper/admin) to trigger the time-based decay calculation for their traits.
        20. `predictTraitChange(address _user, uint256 _actionTypeId)`: Simulates the effect of recording a specific action on a user's current traits *without* altering state.

    *   **Query Functions (>= 5 functions):**
        21. `queryUserTraits(address _user)`: Gets the current trait values for a user.
        22. `queryUserCapabilities(address _user)`: Gets the status of all capabilities (unlocked/locked) for a user.
        23. `checkCapability(address _user, uint256 _capabilityId)`: Checks if a user has a specific capability unlocked.
        24. `queryActionConfiguration(uint256 _actionTypeId)`: Retrieves details of a specific action type.
        25. `queryTraitConfiguration(uint256 _traitTypeId)`: Retrieves details of a specific trait type.
        26. `queryCapabilityConfiguration(uint256 _capabilityId)`: Retrieves details of a specific capability.
        27. `queryUserMetadata(address _user)`: Retrieves the user's metadata string.
        28. `queryModuleAddress(bytes32 _moduleKey)`: Retrieves the address registered for a module key.
        *(Total: 8 Query functions)*

    *   **Internal/Helper Functions:**
        *   `_reevaluateCapabilities(address _user)`: Helper to check and update capability status based on current traits.
        *   `_applyDecayLogic(address _user)`: Helper to calculate and apply trait decay since the last update.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title Aetherium Chronicle
 * @dev A dynamic, non-transferable trait and capability system based on recorded actions.
 * Users accrue traits based on actions, and these traits automatically grant/revoke capabilities.
 * Capabilities can gate execution of specific logic or interactions with registered modules.
 */
contract AetheriumChronicle {

    // --- Outline & Function Summary ---
    // I. Core Data Structures
    //    - ActionType: Defines action effects on traits.
    //    - TraitType: Defines trait properties, including decay.
    //    - Capability: Defines permissions based on trait thresholds.
    //    - UserProfile: Stores user's current traits, capabilities, metadata.
    //    - TraitEffect: Struct for linking actions to trait changes.
    //    - TraitThreshold: Struct for linking capabilities to trait requirements.

    // II. State Variables
    //    - Mappings for actionTypes, traitTypes, capabilities, userProfiles, admins, modules.
    //    - Counters for unique IDs (nextActionId, nextTraitId, nextCapabilityId).
    //    - Owner address.
    //    - Pause flag (paused).
    //    - Mapping to store the last decay application timestamp per user (userLastDecayTimestamp).

    // III. Events
    //    - ActionRecorded: Emitted when an action is recorded.
    //    - TraitChanged: Emitted when a user's trait value changes.
    //    - CapabilityStatusChanged: Emitted when a user gains or loses a capability.
    //    - ActionTypeDefined/Updated, TraitTypeDefined/Updated, CapabilityDefined/Updated.
    //    - ModuleAddressSet/Removed.
    //    - Paused/Unpaused.
    //    - AdminRoleGranted/Revoked.
    //    - ManualCapabilityGranted/Revoked.
    //    - UserMetadataUpdated.

    // IV. Modifiers
    //    - onlyOwner: Restricts access to the contract owner.
    //    - onlyAdmin: Restricts access to owner and defined admins.
    //    - whenNotPaused: Prevents execution when contract is paused.
    //    - whenPaused: Allows execution only when paused.

    // V. Functions
    //    - Admin & Configuration (15 functions):
    //        1. initialize()
    //        2. grantAdminRole()
    //        3. revokeAdminRole()
    //        4. defineActionType()
    //        5. updateActionType()
    //        6. defineTraitType()
    //        7. updateTraitType()
    //        8. defineCapability()
    //        9. updateCapability()
    //        10. setModuleAddress()
    //        11. removeModuleAddress()
    //        12. pause()
    //        13. unpause()
    //        14. grantManualCapability()
    //        15. revokeManualCapability()
    //    - User Interaction & Core Logic (5 functions):
    //        16. recordAction()
    //        17. updateUserMetadata()
    //        18. executePermittedAction()
    //        19. applyDecay()
    //        20. predictTraitChange()
    //    - Query Functions (8 functions):
    //        21. queryUserTraits()
    //        22. queryUserCapabilities()
    //        23. checkCapability()
    //        24. queryActionConfiguration()
    //        25. queryTraitConfiguration()
    //        26. queryCapabilityConfiguration()
    //        27. queryUserMetadata()
    //        28. queryModuleAddress()
    //    - Internal/Helper Functions:
    //        - _reevaluateCapabilities()
    //        - _applyDecayLogic()

    // --- Data Structures ---

    struct TraitEffect {
        uint256 traitTypeId;
        int256 effect; // Can be positive or negative
    }

    struct ActionType {
        uint256 id;
        string name;
        TraitEffect[] traitEffects;
        bool exists; // Helper to check if ID is valid
    }

    struct TraitType {
        uint256 id;
        string name;
        uint256 decayRatePerInterval; // Amount to decay per interval
        uint256 decayInterval; // Time unit (e.g., blocks, seconds) for decay
        bool exists; // Helper to check if ID is valid
    }

    struct TraitThreshold {
        uint256 traitTypeId;
        int256 requiredMin; // Minimum trait value required
        int256 requiredMax; // Maximum trait value required (use type(int256).max for no upper bound)
    }

    struct Capability {
        uint256 id;
        string name;
        TraitThreshold[] requiredThresholds;
        bool exists; // Helper to check if ID is valid
    }

    struct UserProfile {
        mapping(uint256 => int256) traits; // traitTypeId => current value
        mapping(uint256 => bool) unlockedCapabilities; // capabilityId => unlocked status
        string metadata; // User-settable string
    }

    // --- State Variables ---

    address private owner;
    mapping(address => bool) private admins;
    bool private paused;

    mapping(uint256 => ActionType) private actionTypes;
    uint256 private nextActionId = 1;

    mapping(uint256 => TraitType) private traitTypes;
    uint256 private nextTraitId = 1;

    mapping(uint256 => Capability) private capabilities;
    uint256 private nextCapabilityId = 1;

    mapping(address => UserProfile) private userProfiles;

    // Store the last timestamp decay was applied for a user's traits
    mapping(address => uint256) private userLastDecayTimestamp;

    // Registered external module addresses
    mapping(bytes32 => address) private modules;

    // --- Events ---

    event Initialized(address indexed owner);
    event AdminRoleGranted(address indexed admin);
    event AdminRoleRevoked(address indexed admin);

    event Paused();
    event Unpaused();

    event ActionTypeDefined(uint256 indexed actionTypeId, string name);
    event ActionTypeUpdated(uint256 indexed actionTypeId, string name);
    event TraitTypeDefined(uint256 indexed traitTypeId, string name);
    event TraitTypeUpdated(uint256 indexed traitTypeId, string name);
    event CapabilityDefined(uint256 indexed capabilityId, string name);
    event CapabilityUpdated(uint256 indexed capabilityId, string name);

    event ActionRecorded(address indexed user, uint256 indexed actionTypeId, uint256 timestamp);
    event TraitChanged(address indexed user, uint256 indexed traitTypeId, int256 oldValue, int256 newValue);
    event CapabilityStatusChanged(address indexed user, uint256 indexed capabilityId, bool unlocked);
    event UserMetadataUpdated(address indexed user, string metadata);

    event ModuleAddressSet(bytes32 indexed key, address indexed moduleAddress);
    event ModuleAddressRemoved(bytes32 indexed key);

    event ManualCapabilityGranted(address indexed user, uint256 indexed capabilityId, address indexed admin);
    event ManualCapabilityRevoked(address indexed user, uint256 indexed capabilityId, address indexed admin);

    // --- Modifiers ---

    modifier onlyOwner() {
        require(msg.sender == owner, "AC: Not owner");
        _;
    }

    modifier onlyAdmin() {
        require(msg.sender == owner || admins[msg.sender], "AC: Not admin");
        _;
    }

    modifier whenNotPaused() {
        require(!paused, "AC: Paused");
        _;
    }

    modifier whenPaused() {
        require(paused, "AC: Not paused");
        _;
    }

    // --- Constructor & Initialization ---

    constructor() {
        // Owner is set during initialization via initialize function
        paused = false; // Contract starts unpaused
    }

    /**
     * @notice Initializes the contract, setting the owner and initial admin.
     * Can only be called once.
     * @param _owner The address to set as the contract owner.
     * @param _initialAdmin An optional address to grant initial admin role to.
     */
    function initialize(address _owner, address _initialAdmin) external {
        require(owner == address(0), "AC: Already initialized");
        owner = _owner;
        if (_initialAdmin != address(0)) {
            admins[_initialAdmin] = true;
            emit AdminRoleGranted(_initialAdmin);
        }
        emit Initialized(_owner);
    }

    // --- Admin & Configuration Functions ---

    /**
     * @notice Grants admin privileges to an address.
     * @param _admin The address to grant admin role to.
     */
    function grantAdminRole(address _admin) external onlyOwner {
        require(_admin != address(0), "AC: Zero address");
        require(!admins[_admin], "AC: Already admin");
        admins[_admin] = true;
        emit AdminRoleGranted(_admin);
    }

    /**
     * @notice Revokes admin privileges from an address.
     * @param _admin The address to revoke admin role from.
     */
    function revokeAdminRole(address _admin) external onlyOwner {
        require(admins[_admin], "AC: Not an admin");
        admins[_admin] = false;
        emit AdminRoleRevoked(_admin);
    }

    /**
     * @notice Defines a new type of action that can be recorded.
     * @param _name The name of the action type (e.g., "ParticipateInGovernance").
     * @param _effects An array defining how this action affects various traits.
     * @return The ID of the newly defined action type.
     */
    function defineActionType(string memory _name, TraitEffect[] memory _effects) external onlyAdmin returns (uint256) {
        uint256 actionId = nextActionId++;
        actionTypes[actionId] = ActionType({
            id: actionId,
            name: _name,
            traitEffects: _effects,
            exists: true
        });
        emit ActionTypeDefined(actionId, _name);
        return actionId;
    }

    /**
     * @notice Updates the configuration of an existing action type.
     * @param _actionTypeId The ID of the action type to update.
     * @param _newName The new name for the action type.
     * @param _newEffects The new array defining how this action affects traits.
     */
    function updateActionType(uint256 _actionTypeId, string memory _newName, TraitEffect[] memory _newEffects) external onlyAdmin {
        ActionType storage actionConfig = actionTypes[_actionTypeId];
        require(actionConfig.exists, "AC: Invalid action type ID");
        actionConfig.name = _newName;
        actionConfig.traitEffects = _newEffects; // Replaces existing effects
        emit ActionTypeUpdated(_actionTypeId, _newName);
    }

    /**
     * @notice Defines a new type of trait.
     * @param _name The name of the trait (e.g., "ReliabilityIndex").
     * @param _decayRatePerInterval The amount this trait decays per interval.
     * @param _decayInterval The time unit (in seconds) for decay calculation. Set to 0 for no decay.
     * @return The ID of the newly defined trait type.
     */
    function defineTraitType(string memory _name, uint256 _decayRatePerInterval, uint256 _decayInterval) external onlyAdmin returns (uint256) {
        uint256 traitId = nextTraitId++;
        traitTypes[traitId] = TraitType({
            id: traitId,
            name: _name,
            decayRatePerInterval: _decayRatePerInterval,
            decayInterval: _decayInterval,
            exists: true
        });
        emit TraitTypeDefined(traitId, _name);
        return traitId;
    }

    /**
     * @notice Updates the configuration of an existing trait type.
     * @param _traitTypeId The ID of the trait type to update.
     * @param _newName The new name for the trait type.
     * @param _newDecayRatePerInterval The new decay rate per interval.
     * @param _newDecayInterval The new decay interval in seconds. Set to 0 for no decay.
     */
    function updateTraitType(uint256 _traitTypeId, string memory _newName, uint256 _newDecayRatePerInterval, uint256 _newDecayInterval) external onlyAdmin {
        TraitType storage traitConfig = traitTypes[_traitTypeId];
        require(traitConfig.exists, "AC: Invalid trait type ID");
        traitConfig.name = _newName;
        traitConfig.decayRatePerInterval = _newDecayRatePerInterval;
        traitConfig.decayInterval = _newDecayInterval;
        emit TraitTypeUpdated(_traitTypeId, _newName);
    }

    /**
     * @notice Defines a new capability that users can unlock based on traits.
     * @param _name The name of the capability (e.g., "CanProposeUpgrade").
     * @param _requiredThresholds An array defining the trait value ranges required to unlock this capability.
     * @return The ID of the newly defined capability.
     */
    function defineCapability(string memory _name, TraitThreshold[] memory _requiredThresholds) external onlyAdmin returns (uint256) {
        uint256 capabilityId = nextCapabilityId++;
        capabilities[capabilityId] = Capability({
            id: capabilityId,
            name: _name,
            requiredThresholds: _requiredThresholds,
            exists: true
        });
        emit CapabilityDefined(capabilityId, _name);
        return capabilityId;
    }

    /**
     * @notice Updates the configuration of an existing capability.
     * @param _capabilityId The ID of the capability to update.
     * @param _newName The new name for the capability.
     * @param _newRequiredThresholds The new array defining the required trait ranges.
     */
    function updateCapability(uint256 _capabilityId, string memory _newName, TraitThreshold[] memory _newRequiredThresholds) external onlyAdmin {
        Capability storage capabilityConfig = capabilities[_capabilityId];
        require(capabilityConfig.exists, "AC: Invalid capability ID");
        capabilityConfig.name = _newName;
        capabilityConfig.requiredThresholds = _newRequiredThresholds; // Replaces existing thresholds
        // Note: This update does NOT automatically re-evaluate capabilities for all users.
        // Users will have their capabilities re-evaluated next time recordAction or applyDecay is called for them.
        emit CapabilityUpdated(_capabilityId, _newName);
    }

    /**
     * @notice Registers an external contract address as a module.
     * These modules can be targets for the `executePermittedAction` function.
     * @param _moduleKey A unique identifier (bytes32) for the module (e.g., `bytes32("GovernanceModule")`).
     * @param _moduleAddress The address of the external module contract.
     */
    function setModuleAddress(bytes32 _moduleKey, address _moduleAddress) external onlyAdmin {
        require(_moduleAddress != address(0), "AC: Zero address");
        modules[_moduleKey] = _moduleAddress;
        emit ModuleAddressSet(_moduleKey, _moduleAddress);
    }

    /**
     * @notice Removes a registered module address.
     * @param _moduleKey The key of the module to remove.
     */
    function removeModuleAddress(bytes32 _moduleKey) external onlyAdmin {
        require(modules[_moduleKey] != address(0), "AC: Module not registered");
        delete modules[_moduleKey];
        emit ModuleAddressRemoved(_moduleKey);
    }

    /**
     * @notice Pauses specific user interactions (like `recordAction`).
     * Prevents state changes triggered by actions.
     */
    function pause() external onlyAdmin whenNotPaused {
        paused = true;
        emit Paused();
    }

    /**
     * @notice Unpauses specific user interactions.
     */
    function unpause() external onlyAdmin whenPaused {
        paused = false;
        emit Unpaused();
    }

    /**
     * @notice Manually grants a capability to a user, bypassing trait requirements.
     * Use with caution, as this overrides the automatic system.
     * @param _user The address of the user.
     * @param _capabilityId The ID of the capability to grant.
     */
    function grantManualCapability(address _user, uint256 _capabilityId) external onlyAdmin {
        require(capabilities[_capabilityId].exists, "AC: Invalid capability ID");
        userProfiles[_user].unlockedCapabilities[_capabilityId] = true;
        emit ManualCapabilityGranted(_user, _capabilityId, msg.sender);
        // Note: This does not emit CapabilityStatusChanged event, as it's a manual override.
    }

    /**
     * @notice Manually revokes a capability from a user.
     * Use with caution, as this overrides the automatic system.
     * @param _user The address of the user.
     * @param _capabilityId The ID of the capability to revoke.
     */
    function revokeManualCapability(address _user, uint256 _capabilityId) external onlyAdmin {
         require(capabilities[_capabilityId].exists, "AC: Invalid capability ID");
        userProfiles[_user].unlockedCapabilities[_capabilityId] = false;
        emit ManualCapabilityRevoked(_user, _capabilityId, msg.sender);
        // Note: This does not emit CapabilityStatusChanged event, as it's a manual override.
    }

    // --- User Interaction & Core Logic Functions ---

    /**
     * @notice Records that a specific action occurred for a user.
     * This function applies the action's effects to the user's traits
     * and triggers a re-evaluation of the user's capabilities.
     * Expected to be called by authorized systems/contracts.
     * @param _user The address of the user who performed the action.
     * @param _actionTypeId The ID of the action type that occurred.
     */
    function recordAction(address _user, uint256 _actionTypeId) external onlyAdmin whenNotPaused {
        ActionType storage actionConfig = actionTypes[_actionTypeId];
        require(actionConfig.exists, "AC: Invalid action type ID");

        // Apply decay before applying new trait effects
        _applyDecayLogic(_user);

        UserProfile storage userProfile = userProfiles[_user];

        // Apply trait effects from the action
        for (uint i = 0; i < actionConfig.traitEffects.length; i++) {
            uint256 traitTypeId = actionConfig.traitEffects[i].traitTypeId;
            int256 effect = actionConfig.traitEffects[i].effect;

            require(traitTypes[traitTypeId].exists, "AC: Invalid trait type in action config");

            int256 oldValue = userProfile.traits[traitTypeId];
            int256 newValue = oldValue + effect;
            userProfile.traits[traitTypeId] = newValue;

            if (oldValue != newValue) {
                 emit TraitChanged(_user, traitTypeId, oldValue, newValue);
            }
        }

        // Re-evaluate capabilities based on new trait values
        _reevaluateCapabilities(_user);

        // Update last decay timestamp as traits were just updated
        userLastDecayTimestamp[_user] = block.timestamp;

        emit ActionRecorded(_user, _actionTypeId, block.timestamp);
    }

    /**
     * @notice Allows a user to update their associated metadata string.
     * @param _metadata The new metadata string for the user.
     */
    function updateUserMetadata(string memory _metadata) external whenNotPaused {
        userProfiles[msg.sender].metadata = _metadata;
        emit UserMetadataUpdated(msg.sender, _metadata);
    }

     /**
     * @notice Allows any address to trigger execution contingent on the caller possessing a specific capability.
     * If the caller has the capability, it can route execution to a registered module contract.
     * This function acts as a capability-gated entry point for various actions.
     * @param _capabilityId The ID of the capability required for execution.
     * @param _moduleKey The key of the registered module contract to call.
     * @param _callData The data payload for the call to the module contract.
     */
    function executePermittedAction(uint256 _capabilityId, bytes32 _moduleKey, bytes memory _callData) external whenNotPaused {
        require(checkCapability(msg.sender, _capabilityId), "AC: Capability not unlocked");

        address moduleAddress = modules[_moduleKey];
        require(moduleAddress != address(0), "AC: Module not registered");

        // Execute call on the registered module address
        (bool success, bytes memory returnData) = moduleAddress.call(_callData);

        // You might want to add error handling based on the success/returnData
        require(success, string(abi.encodePacked("AC: Module call failed: ", returnData)));

        // Optionally emit an event indicating a permitted action was executed
        // event PermittedActionExecuted(address indexed caller, uint256 indexed capabilityId, bytes32 indexed moduleKey);
        // emit PermittedActionExecuted(msg.sender, _capabilityId, _moduleKey);
    }

    /**
     * @notice Allows a user (or a keeper/admin) to trigger the application of trait decay for a specific user.
     * Traits decay based on time elapsed since the last decay or trait update.
     * @param _user The address of the user whose traits should decay.
     */
    function applyDecay(address _user) external whenNotPaused {
        // Anyone can call this to incentivize decay application, but it only does work if needed.
        // Could add a modifier like `onlyAdminOrSelf` if preferred.
        _applyDecayLogic(_user);
    }

    /**
     * @notice Simulates the effect of recording a specific action on a user's *current* traits without modifying state.
     * Useful for dApps to show users the potential impact of their actions.
     * @param _user The address of the user.
     * @param _actionTypeId The ID of the action type to simulate.
     * @return A mapping of traitTypeId to the predicted trait value after the action.
     */
    function predictTraitChange(address _user, uint256 _actionTypeId) external view returns (mapping(uint256 => int256) memory) {
         ActionType storage actionConfig = actionTypes[_actionTypeId];
        require(actionConfig.exists, "AC: Invalid action type ID");

        // Create a temporary copy of the user's current traits
        mapping(uint256 => int256) memory predictedTraits;
        // Note: Iterating through *all* possible trait types here is inefficient if there are many.
        // A better approach might be to pass the list of *relevant* trait type IDs.
        // For simplicity in this example, we'll iterate through defined trait types.
        uint256 currentTraitId = 1;
        while (traitTypes[currentTraitId].exists) {
             predictedTraits[currentTraitId] = userProfiles[_user].traits[currentTraitId];
             currentTraitId++;
        }


        // Apply trait effects from the action to the predicted traits
        for (uint i = 0; i < actionConfig.traitEffects.length; i++) {
            uint256 traitTypeId = actionConfig.traitEffects[i].traitTypeId;
            int256 effect = actionConfig.traitEffects[i].effect;
             require(traitTypes[traitTypeId].exists, "AC: Invalid trait type in action config"); // Should be checked on config creation, but good measure.
            predictedTraits[traitTypeId] += effect;
        }

        // Note: This simulation does NOT include decay logic for simplicity, as decay depends on time.
        // A more advanced version could simulate decay over a given future period as well.

        return predictedTraits;
    }


    // --- Query Functions ---

    /**
     * @notice Gets the current trait values for a specific user.
     * @param _user The address of the user.
     * @return A mapping of traitTypeId to trait value. Note: This returns a memory copy.
     * If a trait ID is not present, its value is 0.
     */
    function queryUserTraits(address _user) external view returns (mapping(uint256 => int256) memory) {
        // Apply decay logic internally in the view function for up-to-date view
        // Note: This calculates decay *on demand* for the query, which can be gas-intensive
        // if the decay logic is complex or many intervals have passed.
        // A robust system might require `applyDecay` to be called externally first.
        // For simplicity here, we'll skip decay calculation in the query to keep it cheap.
        // Call `applyDecay(_user)` before calling this function for the most accurate state.

        mapping(uint256 => int256) memory currentTraits;
        uint256 currentTraitId = 1;
        while (traitTypes[currentTraitId].exists) {
             currentTraits[currentTraitId] = userProfiles[_user].traits[currentTraitId];
             currentTraitId++;
        }
        return currentTraits;
    }

    /**
     * @notice Gets the status (unlocked/locked) of all capabilities for a specific user.
     * Note: This reflects the status as of the last state update (action or decay).
     * Call `applyDecay` before calling this function for the most up-to-date status if traits decay.
     * @param _user The address of the user.
     * @return A mapping of capabilityId to boolean status (true if unlocked).
     */
    function queryUserCapabilities(address _user) external view returns (mapping(uint256 => bool) memory) {
        mapping(uint256 => bool) memory currentCapabilities;
         uint256 currentCapabilityId = 1;
        while (capabilities[currentCapabilityId].exists) {
             currentCapabilities[currentCapabilityId] = userProfiles[_user].unlockedCapabilities[currentCapabilityId];
             currentCapabilityId++;
        }
        return currentCapabilities;
    }

    /**
     * @notice Checks if a specific user has a specific capability unlocked.
     * Note: This reflects the status as of the last state update (action or decay).
     * Call `applyDecay` before calling this function for the most up-to-date status if traits decay.
     * @param _user The address of the user.
     * @param _capabilityId The ID of the capability to check.
     * @return True if the user has the capability unlocked, false otherwise.
     */
    function checkCapability(address _user, uint256 _capabilityId) public view returns (bool) {
        require(capabilities[_capabilityId].exists, "AC: Invalid capability ID");
        return userProfiles[_user].unlockedCapabilities[_capabilityId];
    }

     /**
     * @notice Retrieves the configuration details for a specific action type.
     * @param _actionTypeId The ID of the action type.
     * @return The ActionType struct.
     */
    function queryActionConfiguration(uint256 _actionTypeId) external view returns (ActionType memory) {
        require(actionTypes[_actionTypeId].exists, "AC: Invalid action type ID");
        return actionTypes[_actionTypeId];
    }

    /**
     * @notice Retrieves the configuration details for a specific trait type.
     * @param _traitTypeId The ID of the trait type.
     * @return The TraitType struct.
     */
    function queryTraitConfiguration(uint256 _traitTypeId) external view returns (TraitType memory) {
        require(traitTypes[_traitTypeId].exists, "AC: Invalid trait type ID");
        return traitTypes[_traitTypeId];
    }

    /**
     * @notice Retrieves the configuration details for a specific capability.
     * @param _capabilityId The ID of the capability.
     * @return The Capability struct.
     */
    function queryCapabilityConfiguration(uint256 _capabilityId) external view returns (Capability memory) {
        require(capabilities[_capabilityId].exists, "AC: Invalid capability ID");
        return capabilities[_capabilityId];
    }

    /**
     * @notice Retrieves the metadata string for a specific user.
     * @param _user The address of the user.
     * @return The user's metadata string.
     */
    function queryUserMetadata(address _user) external view returns (string memory) {
        return userProfiles[_user].metadata;
    }

    /**
     * @notice Retrieves the address registered for a specific module key.
     * @param _moduleKey The key of the module.
     * @return The address of the registered module, or address(0) if not found.
     */
    function queryModuleAddress(bytes32 _moduleKey) external view returns (address) {
        return modules[_moduleKey];
    }

    // --- Internal/Helper Functions ---

    /**
     * @dev Re-evaluates the capabilities for a user based on their current trait values.
     * This function is called automatically after traits are updated.
     * @param _user The address of the user.
     */
    function _reevaluateCapabilities(address _user) internal {
        UserProfile storage userProfile = userProfiles[_user];
        uint256 capabilityId = 1;

        // Iterate through all defined capabilities
        while (capabilities[capabilityId].exists) {
            Capability storage capConfig = capabilities[capabilityId];
            bool currentlyUnlocked = userProfile.unlockedCapabilities[capabilityId];
            bool shouldBeUnlocked = true;

            // Check all required trait thresholds for this capability
            for (uint i = 0; i < capConfig.requiredThresholds.length; i++) {
                uint256 traitTypeId = capConfig.requiredThresholds[i].traitTypeId;
                int256 requiredMin = capConfig.requiredThresholds[i].requiredMin;
                int256 requiredMax = capConfig.requiredThresholds[i].requiredMax;

                // Check if the required trait type exists
                require(traitTypes[traitTypeId].exists, string(abi.encodePacked("AC: Capability config uses invalid trait type ID ", uint256(traitTypeId))));

                int256 userTraitValue = userProfile.traits[traitTypeId];

                // Check if the user's trait value is within the required range [requiredMin, requiredMax]
                if (userTraitValue < requiredMin || userTraitValue > requiredMax) {
                    shouldBeUnlocked = false;
                    break; // No need to check other thresholds if one fails
                }
            }

            // Update capability status if it has changed
            if (currentlyUnlocked != shouldBeUnlocked) {
                userProfile.unlockedCapabilities[capabilityId] = shouldBeUnlocked;
                emit CapabilityStatusChanged(_user, capabilityId, shouldBeUnlocked);
            }

            capabilityId++;
        }
    }

    /**
     * @dev Applies time-based decay to a user's traits based on the elapsed time
     * since the last trait update or decay application.
     * @param _user The address of the user.
     */
    function _applyDecayLogic(address _user) internal {
        uint256 lastDecayTime = userLastDecayTimestamp[_user];
        // If lastDecayTime is 0, it means the user hasn't had any trait updates yet, or decay hasn't been applied.
        // We treat the current block timestamp as the "start" time in this case, so elapsed time is 0.
        uint256 timeElapsed = (lastDecayTime == 0) ? 0 : block.timestamp - lastDecayTime;

        UserProfile storage userProfile = userProfiles[_user];
        uint256 traitTypeId = 1;
        bool traitsDecayed = false;

        // Iterate through all defined trait types
        while (traitTypes[traitTypeId].exists) {
            TraitType storage traitConfig = traitTypes[traitTypeId];

            if (traitConfig.decayInterval > 0 && timeElapsed > 0) {
                uint256 intervalsPassed = timeElapsed / traitConfig.decayInterval;
                if (intervalsPassed > 0) {
                     int256 decayAmount = int256(intervalsPassed * traitConfig.decayRatePerInterval);
                     int256 oldValue = userProfile.traits[traitTypeId];
                     int256 newValue = oldValue - decayAmount;

                     // Optional: Prevent decay below zero or a minimum floor if needed
                     // newValue = (newValue < MIN_TRAIT_VALUE) ? MIN_TRAIT_VALUE : newValue;

                     if (oldValue != newValue) {
                         userProfile.traits[traitTypeId] = newValue;
                         emit TraitChanged(_user, traitTypeId, oldValue, newValue);
                         traitsDecayed = true;
                     }
                }
            }
             traitTypeId++;
        }

        // Re-evaluate capabilities if any trait decayed
        if (traitsDecayed) {
            _reevaluateCapabilities(_user);
        }

        // Update the last decay timestamp if decay was potentially applied or traits were checked/updated
        userLastDecayTimestamp[_user] = block.timestamp;
    }

    /**
     * @notice Check if an address is an admin.
     * @param _address The address to check.
     * @return True if the address is an admin or the owner, false otherwise.
     */
    function isAdmin(address _address) external view returns (bool) {
        return _address == owner || admins[_address];
    }

     /**
     * @notice Get the current owner of the contract.
     * @return The address of the owner.
     */
    function getOwner() external view returns (address) {
        return owner;
    }

    /**
     * @notice Check if the contract is currently paused.
     * @return True if paused, false otherwise.
     */
    function isPaused() external view returns (bool) {
        return paused;
    }

    // Counting functions - potentially gas-intensive if there are many IDs
    // Added to meet the 20+ count with useful query functions, but be mindful of gas.

    /**
     * @notice Gets the total number of defined action types.
     * @return The count of action types.
     */
    function getActionTypeCount() external view returns (uint256) {
        return nextActionId - 1; // IDs are 1-based
    }

     /**
     * @notice Gets the total number of defined trait types.
     * @return The count of trait types.
     */
    function getTraitTypeCount() external view returns (uint256) {
        return nextTraitId - 1; // IDs are 1-based
    }

     /**
     * @notice Gets the total number of defined capabilities.
     * @return The count of capabilities.
     */
    function getCapabilityCount() external view returns (uint256) {
        return nextCapabilityId - 1; // IDs are 1-based
    }

    // Total Functions: 15 Admin + 5 Core Logic + 8 Query + 3 Simple Getters = 31+

    // Note on Gas & Scalability:
    // - Iterating through all trait types (_applyDecayLogic) or capabilities (_reevaluateCapabilities)
    //   can become expensive if their numbers grow very large. The current design assumes
    //   a manageable number of trait and capability types.
    // - Applying decay (`applyDecay`) is per-user and triggered externally (or by the user).
    //   A system managing decay for *all* users would need a different approach (e.g., batching,
    //   off-chain calculation with proofs, or a different decay model).
    // - `queryUserTraits` calculating decay on the fly in a view function is generally discouraged
    //   for production unless the decay logic is extremely simple or infrequent. It's better
    //   practice to ensure `applyDecay` is called regularly by a keeper network for active users.
    //   The current implementation omits the decay calculation in queries for gas efficiency.
    // - The `predictTraitChange` function copies relevant data to memory, which has gas costs proportional
    //   to the number of traits potentially affected by the action type.

}
```