Okay, here is a Solidity smart contract concept called `OmniLayer`.

**Concept:** `OmniLayer` is a dynamic state and permissioning contract. It allows defining different "layers" of functionality or access for users. Users can "unlock" these layers by meeting specific, multi-part conditions managed or verified by the contract. The conditions can involve internal contract state (like a user's score or achievements), external data points verified by an oracle, or even requiring other layers to be unlocked. This allows for complex, personalized user journeys and access control based on verifiable criteria rather than just simple token balances or fixed roles.

**Interesting, Advanced, Creative, Trendy Aspects:**

1.  **Dynamic Layers & Conditions:** Layers and their unlocking criteria are defined and managed dynamically via administrative functions.
2.  **Multi-Part Complex Conditions:** Conditions can be composed of multiple criteria (internal score, external data, required layers, time-based) combined using AND/OR logic (implemented via condition groups).
3.  **Personalized State & Permissions:** Access to specific functions or variations in logic/parameters within functions can be tied to a user's currently unlocked layers.
4.  **Oracle Integration Mock:** Includes mechanisms to receive and validate external data points affecting conditions (simulated oracle role).
5.  **Internal Achievement System:** Includes a basic internal score system that can be incremented by trusted parties and used as a condition.
6.  **Layer Dependencies:** Layers can require other specific layers to be unlocked first.
7.  **Time-Based Conditions/Expiry:** Layers can have conditions tied to timestamps or potentially have expiry dates (though expiry logic isn't fully built out in this example to keep focus on unlocking, it's a natural extension).
8.  **Queryability:** Extensive view functions to query layer definitions, user status, and condition details.

**Non-Duplication Note:** While concepts like roles, conditions, and oracles exist in open source, the specific structure of defining `LayerDefinition` with complex, multi-part `LayerConditionGroup`s that combine internal state, external data (via mock oracle), required other layers, and time constraints to grant dynamic, personalized access/state is less common as a standalone, generic pattern compared to standard ERC-20/721, simple role systems, or basic yield farms. This contract focuses *specifically* on this dynamic credential/state management aspect.

---

### **OmniLayer Smart Contract**

**Outline:**

1.  **SPDX License & Pragmas**
2.  **Imports** (`Ownable`)
3.  **Constants & Enums** (Layer IDs, Condition Types, Operators)
4.  **Structs** (LayerCondition, LayerConditionGroup, LayerDefinition, UserLayerStatus)
5.  **State Variables** (Owner, Oracle, Layer Definitions, User Layer Status, User Internal Scores, User External Data, Paused Layers)
6.  **Events** (LayerUnlocked, LayerDefinitionUpdated, ConditionAdded, ConditionRemoved, LayerPaused, UserScoreUpdated, UserExternalDataUpdated)
7.  **Modifiers** (onlyOracle, onlyLayer, whenLayerActive)
8.  **Constructor**
9.  **Admin Functions** (Defining Layers, Conditions, Dependencies, Oracle, Pausing)
10. **Oracle/Trusted Caller Functions** (Updating internal state variables used in conditions)
11. **Core Logic Functions** (Attempting to unlock layers, checking conditions)
12. **Query Functions** (Getting definitions, user status, checking conditions)
13. **Example Layer-Dependent Function** (Demonstrating how layers affect functionality)
14. **Ownership Functions** (from Ownable)

**Function Summary:**

*   **`constructor(address initialOracle)`**: Initializes the contract, setting the owner and the initial oracle address.
*   **`setOracleAddress(address newOracle)`**: (Admin) Sets the address allowed to call oracle/trusted functions.
*   **`setLayerDefinition(bytes32 layerId, string name, string description)`**: (Admin) Defines or updates a layer's basic metadata.
*   **`addConditionToLayerGroup(bytes32 layerId, uint256 groupId, uint8 conditionType, int256 thresholdValue, bytes32 requiredLayerId, bytes32 externalDataKey)`**: (Admin) Adds a condition to a specific group within a layer's requirements. `groupId` allows ORing groups, while conditions *within* a group are ANDed.
*   **`removeConditionFromLayerGroup(bytes32 layerId, uint256 groupId, uint256 conditionIndexInGroup)`**: (Admin) Removes a specific condition from a group.
*   **`setLayerDependency(bytes32 layerId, bytes32 requiredLayerId, bool required)`**: (Admin) Sets or removes a dependency that `layerId` requires `requiredLayerId` to be unlocked first.
*   **`pauseLayer(bytes32 layerId)`**: (Admin) Pauses a specific layer, preventing it from being unlocked or used if the `whenLayerActive` modifier is used.
*   **`unpauseLayer(bytes32 layerId)`**: (Admin) Unpauses a specific layer.
*   **`incrementUserScore(address user, int256 amount)`**: (Oracle/Trusted) Increments a user's internal score. Usable in `SCORE_THRESHOLD` conditions.
*   **`setUserExternalData(address user, bytes32 dataKey, bytes32 dataValue)`**: (Oracle/Trusted) Sets a user's external data point. Usable in `EXTERNAL_DATA_MATCH` conditions.
*   **`attemptUnlockLayer(bytes32 layerId, bytes32[] externalProof)`**: (User callable) Attempts to unlock a layer for the caller. Checks definition, dependency, pause status, and all condition groups. `externalProof` is a placeholder for potential validation data needed for external conditions.
*   **`checkUserCondition(address user, LayerCondition calldata condition)`**: (Public View) Checks if a *single* given condition is met by a user. Useful for off-chain verification.
*   **`checkLayerConditions(address user, bytes32 layerId, bytes32[] externalProof)`**: (Public View) Checks if a user meets *all* requirements for a specific layer (dependency + *any* condition group being met). Returns `true` if unlockable.
*   **`getLayerDefinition(bytes32 layerId)`**: (Public View) Retrieves the definition and conditions for a layer.
*   **`getUserLayerStatus(address user, bytes32 layerId)`**: (Public View) Gets the unlocked status and timestamp for a user's specific layer.
*   **`hasLayer(address user, bytes32 layerId)`**: (Public View) Returns `true` if the user has successfully unlocked the specified layer.
*   **`isLayerActive(bytes32 layerId)`**: (Public View) Returns `true` if the layer exists, is unlocked for the user, and is not paused. (Note: Modifier `whenLayerActive` checks for a specific *user* holding an *unpaused* layer). This view just checks global pause state.
*   **`getLayerConditions(bytes32 layerId)`**: (Public View) Retrieves the condition groups defined for a layer.
*   **`getUserScore(address user)`**: (Public View) Gets a user's current internal score.
*   **`getUserExternalData(address user, bytes32 dataKey)`**: (Public View) Gets a specific external data point for a user.
*   **`performLayerSpecificAction(bytes32 requiredLayer)`**: (Example Function) Demonstrates how a function's execution might be restricted or modified based on the caller having a specific layer. Uses the `onlyLayer` modifier.
*   **`transferOwnership(address newOwner)`**: (Admin) Transfers ownership of the contract.
*   **`renounceOwnership()`**: (Admin) Renounces ownership (makes contract unmanaged).

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

// Outline:
// 1. SPDX License & Pragmas
// 2. Imports (Ownable, SafeMath)
// 3. Constants & Enums (Layer IDs, Condition Types, Operators)
// 4. Structs (LayerCondition, LayerConditionGroup, LayerDefinition, UserLayerStatus)
// 5. State Variables (Owner, Oracle, Layer Definitions, User Layer Status, User Internal Scores, User External Data, Paused Layers)
// 6. Events (LayerUnlocked, LayerDefinitionUpdated, ConditionAdded, ConditionRemoved, LayerPaused, UserScoreUpdated, UserExternalDataUpdated)
// 7. Modifiers (onlyOracle, onlyLayer, whenLayerActive)
// 8. Constructor
// 9. Admin Functions (Defining Layers, Conditions, Dependencies, Oracle, Pausing)
// 10. Oracle/Trusted Caller Functions (Updating internal state variables used in conditions)
// 11. Core Logic Functions (Attempting to unlock layers, checking conditions)
// 12. Query Functions (Getting definitions, user status, checking conditions)
// 13. Example Layer-Dependent Function (Demonstrating how layers affect functionality)
// 14. Ownership Functions (from Ownable)

// Function Summary:
// - constructor(address initialOracle): Initializes contract, sets owner and oracle.
// - setOracleAddress(address newOracle): (Admin) Sets the trusted oracle address.
// - setLayerDefinition(bytes32 layerId, string name, string description): (Admin) Defines or updates a layer's metadata.
// - addConditionToLayerGroup(bytes32 layerId, uint256 groupId, uint8 conditionType, int256 thresholdValue, bytes32 requiredLayerId, bytes32 externalDataKey): (Admin) Adds a condition to a group for a layer. Conditions in a group are ANDed, groups are ORed.
// - removeConditionFromLayerGroup(bytes32 layerId, uint256 groupId, uint256 conditionIndexInGroup): (Admin) Removes a condition from a group.
// - setLayerDependency(bytes32 layerId, bytes32 requiredLayerId, bool required): (Admin) Sets or removes a required prerequisite layer.
// - pauseLayer(bytes32 layerId): (Admin) Pauses unlocking/use of a specific layer.
// - unpauseLayer(bytes32 layerId): (Admin) Unpauses a specific layer.
// - incrementUserScore(address user, int256 amount): (Oracle/Trusted) Updates a user's internal score used for conditions.
// - setUserExternalData(address user, bytes32 dataKey, bytes32 dataValue): (Oracle/Trusted) Sets external data for a user used for conditions.
// - attemptUnlockLayer(bytes32 layerId, bytes32[] externalProof): (User callable) Attempts to unlock a layer, checking all requirements.
// - checkUserCondition(address user, LayerCondition calldata condition): (Public View) Checks if a *single* condition is met by a user.
// - checkLayerConditions(address user, bytes32 layerId, bytes32[] externalProof): (Public View) Checks if a user meets *all* requirements for a layer (dependency + any condition group).
// - getLayerDefinition(bytes32 layerId): (Public View) Gets a layer's definition and conditions.
// - getUserLayerStatus(address user, bytes32 layerId): (Public View) Gets a user's unlock status for a specific layer.
// - hasLayer(address user, bytes32 layerId): (Public View) Checks if a user has unlocked a layer.
// - isLayerActive(bytes32 layerId): (Public View) Checks if a layer is globally active (exists and not paused).
// - getLayerConditions(bytes32 layerId): (Public View) Gets all condition groups for a layer.
// - getUserScore(address user): (Public View) Gets a user's internal score.
// - getUserExternalData(address user, bytes32 dataKey): (Public View) Gets specific external data for a user.
// - performLayerSpecificAction(bytes32 requiredLayer): (Example) Function demonstrating layer-based access/logic.
// - transferOwnership(address newOwner): (Admin) Standard Ownable function.
// - renounceOwnership(): (Admin) Standard Ownable function.

contract OmniLayer is Ownable {
    using SafeMath for int256; // Using SafeMath for potential negative scores

    // --- Constants & Enums ---

    // Condition Types (Higher value means more complex/external)
    enum ConditionType {
        NONE,
        SCORE_THRESHOLD,          // Requires user's internal score >= thresholdValue
        EXTERNAL_DATA_MATCH,      // Requires user's external data[dataKey] == thresholdValue (interpreted as bytes32)
        HAS_LAYER,                // Requires user to have unlocked requiredLayerId
        TIME_AFTER,               // Requires current timestamp >= thresholdValue (interpreted as uint256)
        TIME_BEFORE               // Requires current timestamp <= thresholdValue (interpreted as uint256)
        // Add more types like TOKEN_BALANCE, NFT_OWNERSHIP etc. if needed
    }

    // Operators (currently only used for SCORE_THRESHOLD for simplicity)
    enum ConditionOperator {
        NONE,
        GREATER_THAN_OR_EQUAL, // >=
        LESS_THAN_OR_EQUAL,    // <=
        EQUAL                  // ==
        // Could add >, <, != etc.
    }

    // --- Structs ---

    struct LayerCondition {
        ConditionType conditionType;
        int256 thresholdValue; // Value used for SCORE_THRESHOLD, TIME_AFTER, TIME_BEFORE. Interpreted based on type.
        bytes32 requiredLayerId; // Used for HAS_LAYER
        bytes32 externalDataKey; // Key for EXTERNAL_DATA_MATCH
        // ConditionOperator operator; // Could add this if needed for more complex comparisons
    }

    struct LayerConditionGroup {
        LayerCondition[] conditions; // All conditions in this array must be met (AND)
    }

    struct LayerDefinition {
        string name;
        string description;
        mapping(uint256 => LayerConditionGroup) conditionGroups; // Groups are ORed. If ANY group is met, the layer conditions are satisfied.
        uint256[] conditionGroupIds; // To iterate over groups
        bytes32 requiredLayerDependency; // Another layer that must be unlocked first (checked IN ADDITION to groups)
        bool exists; // Flag to check if the layerId has been defined
    }

    struct UserLayerStatus {
        bool unlocked;
        uint40 unlockTimestamp; // Use uint40 for gas efficiency as timestamps are typically within 2^40 range
        // Could add expiryTimestamp here
    }

    // --- State Variables ---

    address public oracleAddress;

    // Layer Definitions
    mapping(bytes32 => LayerDefinition) public layerDefinitions;
    bytes32[] public definedLayerIds; // To iterate over all defined layers

    // User State
    mapping(address => mapping(bytes32 => UserLayerStatus)) public userLayerStatus;
    mapping(address => int256) private userScores; // Internal score system
    mapping(address => mapping(bytes32 => bytes32)) private userExternalData; // Data points verified by oracle

    // Layer Pause Status
    mapping(bytes32 => bool) public pausedLayers;

    // --- Events ---

    event LayerUnlocked(address indexed user, bytes32 indexed layerId, uint40 timestamp);
    event LayerDefinitionUpdated(bytes32 indexed layerId, string name, string description);
    event ConditionAdded(bytes32 indexed layerId, uint256 groupId, uint8 conditionType);
    event ConditionRemoved(bytes32 indexed layerId, uint256 groupId, uint256 index);
    event LayerDependencyUpdated(bytes32 indexed layerId, bytes32 indexed requiredLayerId, bool required);
    event LayerPaused(bytes32 indexed layerId, bool paused);
    event UserScoreUpdated(address indexed user, int256 newScore);
    event UserExternalDataUpdated(address indexed user, bytes32 indexed dataKey, bytes32 dataValue);

    // --- Modifiers ---

    modifier onlyOracle() {
        require(msg.sender == oracleAddress, "OmniLayer: Caller is not the oracle");
        _;
    }

    // Restricts a function to only callable by users who have a specific layer unlocked AND active
    modifier onlyLayer(bytes32 requiredLayerId) {
        require(userLayerStatus[msg.sender][requiredLayerId].unlocked, "OmniLayer: Requires layer unlocked");
        require(!pausedLayers[requiredLayerId], "OmniLayer: Required layer is paused");
        // Could add expiry check here if implemented
        _;
    }

     // Restricts a function based on the layer being globally unpaused
     modifier whenLayerActive(bytes32 layerId) {
         require(layerDefinitions[layerId].exists, "OmniLayer: Layer does not exist");
         require(!pausedLayers[layerId], "OmniLayer: Layer is paused");
         _;
     }


    // --- Constructor ---

    constructor(address initialOracle) Ownable(msg.sender) {
        require(initialOracle != address(0), "OmniLayer: Initial oracle cannot be zero address");
        oracleAddress = initialOracle;
    }

    // --- Admin Functions ---

    /// @notice Sets or updates the definition of a layer.
    /// @param layerId A unique identifier for the layer (e.g., keccak256("LEVEL_1_ACCESS")).
    /// @param name The human-readable name of the layer.
    /// @param description A brief description of the layer.
    function setLayerDefinition(bytes32 layerId, string memory name, string memory description) public onlyOwner {
        bool isNewLayer = !layerDefinitions[layerId].exists;
        layerDefinitions[layerId].name = name;
        layerDefinitions[layerId].description = description;
        layerDefinitions[layerId].exists = true;

        if (isNewLayer) {
            definedLayerIds.push(layerId);
        }

        emit LayerDefinitionUpdated(layerId, name, description);
    }

    /// @notice Adds a condition to a specific group for unlocking a layer.
    /// Conditions within a group are ANDed. Groups are ORed.
    /// @param layerId The ID of the layer to add the condition to.
    /// @param groupId The ID of the condition group (create new or add to existing).
    /// @param conditionType The type of condition (see `ConditionType` enum).
    /// @param thresholdValue Value used for SCORE_THRESHOLD, TIME_AFTER, TIME_BEFORE.
    /// @param requiredLayerId Required layer ID for HAS_LAYER condition.
    /// @param externalDataKey Key for EXTERNAL_DATA_MATCH condition.
    function addConditionToLayerGroup(
        bytes32 layerId,
        uint256 groupId,
        uint8 conditionType,
        int256 thresholdValue,
        bytes32 requiredLayerId,
        bytes32 externalDataKey
    ) public onlyOwner {
        require(layerDefinitions[layerId].exists, "OmniLayer: Layer not defined");
        ConditionType cType = ConditionType(conditionType);
        require(uint8(cType) >= uint8(ConditionType.SCORE_THRESHOLD), "OmniLayer: Invalid condition type"); // Check against first valid type

        LayerCondition memory newCondition;
        newCondition.conditionType = cType;
        newCondition.thresholdValue = thresholdValue;
        newCondition.requiredLayerId = requiredLayerId;
        newCondition.externalDataKey = externalDataKey;

        bool groupExists = false;
        for(uint i=0; i < layerDefinitions[layerId].conditionGroupIds.length; i++){
            if(layerDefinitions[layerId].conditionGroupIds[i] == groupId){
                groupExists = true;
                break;
            }
        }
        if(!groupExists){
            layerDefinitions[layerId].conditionGroupIds.push(groupId);
        }

        layerDefinitions[layerId].conditionGroups[groupId].conditions.push(newCondition);

        emit ConditionAdded(layerId, groupId, conditionType);
    }

    /// @notice Removes a condition from a specific group.
    /// @param layerId The ID of the layer.
    /// @param groupId The ID of the condition group.
    /// @param conditionIndexInGroup The index of the condition within the group's array.
    function removeConditionFromLayerGroup(
        bytes32 layerId,
        uint256 groupId,
        uint256 conditionIndexInGroup
    ) public onlyOwner {
        require(layerDefinitions[layerId].exists, "OmniLayer: Layer not defined");
        LayerConditionGroup storage group = layerDefinitions[layerId].conditionGroups[groupId];
        require(conditionIndexInGroup < group.conditions.length, "OmniLayer: Index out of bounds");

        // Shift elements to remove the condition
        for (uint i = conditionIndexInGroup; i < group.conditions.length - 1; i++) {
            group.conditions[i] = group.conditions[i + 1];
        }
        group.conditions.pop();

        // If the group becomes empty, remove its ID from the list of group IDs
        if (group.conditions.length == 0) {
             for(uint i=0; i < layerDefinitions[layerId].conditionGroupIds.length; i++){
                if(layerDefinitions[layerId].conditionGroupIds[i] == groupId){
                    // Shift group IDs
                    for(uint j=i; j < layerDefinitions[layerId].conditionGroupIds.length - 1; j++){
                        layerDefinitions[layerId].conditionGroupIds[j] = layerDefinitions[layerId].conditionGroupIds[j+1];
                    }
                    layerDefinitions[layerId].conditionGroupIds.pop();
                    break; // Found and removed the group ID
                }
            }
        }

        emit ConditionRemoved(layerId, groupId, conditionIndexInGroup);
    }


    /// @notice Sets or removes a dependency on another layer.
    /// The layer cannot be unlocked unless the requiredLayerId is already unlocked.
    /// @param layerId The layer requiring the dependency.
    /// @param requiredLayerId The layer that must be unlocked first.
    /// @param required Set to true to add dependency, false to remove.
    function setLayerDependency(bytes32 layerId, bytes32 requiredLayerId, bool required) public onlyOwner {
        require(layerDefinitions[layerId].exists, "OmniLayer: Layer not defined");
        require(layerId != requiredLayerId, "OmniLayer: Cannot depend on itself");
        require(!required || layerDefinitions[requiredLayerId].exists, "OmniLayer: Required dependency layer not defined");

        if (required) {
            layerDefinitions[layerId].requiredLayerDependency = requiredLayerId;
        } else {
             layerDefinitions[layerId].requiredLayerDependency = bytes32(0); // Represent no dependency
        }

        emit LayerDependencyUpdated(layerId, requiredLayerId, required);
    }

    /// @notice Pauses a layer, preventing new unlocks and potentially restricting use.
    /// @param layerId The ID of the layer to pause.
    function pauseLayer(bytes32 layerId) public onlyOwner {
        require(layerDefinitions[layerId].exists, "OmniLayer: Layer not defined");
        pausedLayers[layerId] = true;
        emit LayerPaused(layerId, true);
    }

    /// @notice Unpauses a layer.
    /// @param layerId The ID of the layer to unpause.
    function unpauseLayer(bytes32 layerId) public onlyOwner {
         require(layerDefinitions[layerId].exists, "OmniLayer: Layer not defined");
        pausedLayers[layerId] = false;
        emit LayerPaused(layerId, false);
    }

    // --- Oracle/Trusted Caller Functions ---

    /// @notice Increments a user's internal score. Can be negative.
    /// @dev Only callable by the designated oracle address.
    /// @param user The address of the user.
    /// @param amount The amount to add to the user's score (can be negative).
    function incrementUserScore(address user, int256 amount) public onlyOracle {
        userScores[user] = userScores[user].add(amount);
        emit UserScoreUpdated(user, userScores[user]);
    }

    /// @notice Sets an external data point for a user.
    /// @dev Only callable by the designated oracle address.
    /// @param user The address of the user.
    /// @param dataKey A key identifying the data point (e.g., keccak256("KYC_STATUS")).
    /// @param dataValue The value of the data point (e.g., keccak256("VERIFIED")).
    function setUserExternalData(address user, bytes32 dataKey, bytes32 dataValue) public onlyOracle {
        userExternalData[user][dataKey] = dataValue;
        emit UserExternalDataUpdated(user, dataKey, dataValue);
    }


    // --- Core Logic Functions ---

    /// @notice Attempts to unlock a specific layer for the caller.
    /// Checks if the layer is defined, not paused, dependency is met, and at least one condition group is met.
    /// @param layerId The ID of the layer to attempt to unlock.
    /// @param externalProof Placeholder for data needed by oracle-dependent conditions (e.g., signatures). Not used in current mock implementation.
    function attemptUnlockLayer(bytes32 layerId, bytes32[] memory externalProof) public whenLayerActive(layerId) {
        require(!userLayerStatus[msg.sender][layerId].unlocked, "OmniLayer: Layer already unlocked");

        // Check Dependency
        bytes32 dependency = layerDefinitions[layerId].requiredLayerDependency;
        if (dependency != bytes32(0)) {
            require(userLayerStatus[msg.sender][dependency].unlocked, "OmniLayer: Dependency layer not unlocked");
        }

        // Check Conditions (at least one group must be satisfied)
        require(checkLayerConditions(msg.sender, layerId, externalProof), "OmniLayer: Layer conditions not met");

        // Unlock the layer
        userLayerStatus[msg.sender][layerId].unlocked = true;
        userLayerStatus[msg.sender][layerId].unlockTimestamp = uint40(block.timestamp);

        emit LayerUnlocked(msg.sender, layerId, uint40(block.timestamp));
    }

    /// @notice Checks if a single condition is met by a user.
    /// @dev Public view function, useful for off-chain checks.
    /// @param user The user address.
    /// @param condition The condition struct to check.
    /// @return True if the condition is met, false otherwise.
    function checkUserCondition(address user, LayerCondition calldata condition) public view returns (bool) {
        ConditionType cType = condition.conditionType;

        if (cType == ConditionType.SCORE_THRESHOLD) {
            // Assuming GREATER_THAN_OR_EQUAL for simplicity based on current struct
             return userScores[user] >= condition.thresholdValue;
        } else if (cType == ConditionType.EXTERNAL_DATA_MATCH) {
            // Interpret thresholdValue as bytes32 for comparison
            bytes32 requiredValue;
            // Safe way to convert int256 to bytes32, handling potential sign issues conceptually
            // For this example, let's assume thresholdValue is only used for non-negative contexts or specific comparisons
            // A more robust implementation might use a dedicated bytes32 field for comparison values
             assembly {
                 requiredValue := condition.thresholdValue
             }
            return userExternalData[user][condition.externalDataKey] == requiredValue;

        } else if (cType == ConditionType.HAS_LAYER) {
            require(condition.requiredLayerId != bytes32(0), "OmniLayer: HAS_LAYER requires layer ID");
            return userLayerStatus[user][condition.requiredLayerId].unlocked;

        } else if (cType == ConditionType.TIME_AFTER) {
            require(condition.thresholdValue >= 0, "OmniLayer: TIME_AFTER requires non-negative timestamp");
            return block.timestamp >= uint256(condition.thresholdValue);

        } else if (cType == ConditionType.TIME_BEFORE) {
             require(condition.thresholdValue >= 0, "OmniLayer: TIME_BEFORE requires non-negative timestamp");
            return block.timestamp <= uint256(condition.thresholdValue);
        }
        // Add checks for other condition types here

        return false; // Invalid or NONE condition type
    }

     /// @notice Checks if a user meets all the requirements (dependency + conditions) for a layer.
     /// @dev Public view function, useful for off-chain checks before attempting unlock.
     /// @param user The user address.
     /// @param layerId The ID of the layer to check.
     /// @param externalProof Placeholder for oracle data.
     /// @return True if the layer is unlockable by the user, false otherwise.
     function checkLayerConditions(address user, bytes32 layerId, bytes32[] memory externalProof) public view returns (bool) {
         LayerDefinition storage layerDef = layerDefinitions[layerId];
         require(layerDef.exists, "OmniLayer: Layer not defined");
         require(!pausedLayers[layerId], "OmniLayer: Layer is paused");


         // Check Dependency
         bytes32 dependency = layerDef.requiredLayerDependency;
         if (dependency != bytes32(0)) {
             if (!userLayerStatus[user][dependency].unlocked) {
                 return false;
             }
         }

         // Check Condition Groups (OR logic between groups)
         bool anyGroupSatisfied = false;
         uint256 numGroups = layerDef.conditionGroupIds.length;

         // Handle case with no conditions explicitly defined (should technically not happen for unlockable layers)
         if (numGroups == 0) {
             return dependency == bytes32(0); // If no conditions, only dependency matters
         }

         for (uint i = 0; i < numGroups; i++) {
             uint256 groupId = layerDef.conditionGroupIds[i];
             LayerConditionGroup storage group = layerDef.conditionGroups[groupId];
             bool groupSatisfied = true;

             // Check Conditions within the group (AND logic within group)
             for (uint j = 0; j < group.conditions.length; j++) {
                 if (!checkUserCondition(user, group.conditions[j])) {
                     groupSatisfied = false;
                     break; // Condition in group not met, this group fails
                 }
             }

             if (groupSatisfied) {
                 anyGroupSatisfied = true;
                 break; // Found a satisfied group, no need to check others
             }
         }

         return anyGroupSatisfied;
     }


    // --- Query Functions ---

    /// @notice Gets the definition details for a layer.
    /// @param layerId The ID of the layer.
    /// @return name, description, requiredLayerDependency
    function getLayerDefinition(bytes32 layerId) public view returns (string memory name, string memory description, bytes32 requiredLayerDependency) {
        require(layerDefinitions[layerId].exists, "OmniLayer: Layer not defined");
        LayerDefinition storage def = layerDefinitions[layerId];
        return (def.name, def.description, def.requiredLayerDependency);
    }

    /// @notice Gets the unlocked status and timestamp for a user's layer.
    /// @param user The user address.
    /// @param layerId The ID of the layer.
    /// @return unlocked, unlockTimestamp
    function getUserLayerStatus(address user, bytes32 layerId) public view returns (bool unlocked, uint40 unlockTimestamp) {
        // No require(layerDefinitions[layerId].exists) here, as we can query status for undefined layers (will be false, 0)
        UserLayerStatus storage status = userLayerStatus[user][layerId];
        return (status.unlocked, status.unlockTimestamp);
    }

    /// @notice Checks if a user has unlocked a specific layer.
    /// @param user The user address.
    /// @param layerId The ID of the layer.
    /// @return True if unlocked, false otherwise.
    function hasLayer(address user, bytes32 layerId) public view returns (bool) {
         // No require(layerDefinitions[layerId].exists) here
        return userLayerStatus[user][layerId].unlocked;
    }

    /// @notice Checks if a layer is globally active (defined and not paused).
    /// Does NOT check if a specific user has unlocked it.
    /// @param layerId The ID of the layer.
    /// @return True if defined and not paused, false otherwise.
    function isLayerActive(bytes32 layerId) public view returns (bool) {
         return layerDefinitions[layerId].exists && !pausedLayers[layerId];
    }

    /// @notice Gets all condition groups and conditions for a layer.
    /// @param layerId The ID of the layer.
    /// @return An array of group IDs and a nested array of conditions for each group.
    function getLayerConditions(bytes32 layerId) public view returns (uint256[] memory groupIds, LayerCondition[][] memory conditionsByGroup) {
         require(layerDefinitions[layerId].exists, "OmniLayer: Layer not defined");
         groupIds = layerDefinitions[layerId].conditionGroupIds;
         conditionsByGroup = new LayerCondition[][](groupIds.length);

         for(uint i = 0; i < groupIds.length; i++){
             uint256 groupId = groupIds[i];
             LayerConditionGroup storage group = layerDefinitions[layerId].conditionGroups[groupId];
             conditionsByGroup[i] = new LayerCondition[](group.conditions.length);
             for(uint j = 0; j < group.conditions.length; j++){
                 conditionsByGroup[i][j] = group.conditions[j];
             }
         }
         return (groupIds, conditionsByGroup);
    }

    /// @notice Gets a user's current internal score.
    /// @param user The user address.
    /// @return The user's score.
    function getUserScore(address user) public view returns (int256) {
        return userScores[user];
    }

    /// @notice Gets a specific external data point for a user.
    /// @param user The user address.
    /// @param dataKey The key for the data point.
    /// @return The data value (bytes32).
    function getUserExternalData(address user, bytes32 dataKey) public view returns (bytes32) {
        return userExternalData[user][dataKey];
    }

     /// @notice Gets all defined layer IDs.
     /// @return An array of bytes32 layer IDs.
    function getDefinedLayerIds() public view returns (bytes32[] memory) {
        return definedLayerIds;
    }


    // --- Example Layer-Dependent Function ---

    /// @notice An example function that can only be called by users with a specific layer.
    /// The behavior or parameters could also vary based on WHICH layers the user has.
    /// @param requiredLayer The ID of the layer required to call this function.
    function performLayerSpecificAction(bytes32 requiredLayer) public onlyLayer(requiredLayer) {
        // Example logic: This user has 'requiredLayer' unlocked and it's not paused
        // You could add checks for other layers here too
        // if (hasLayer(msg.sender, keccak256("ADMIN_OVERRIDE_LAYER"))) {
        //    // User has admin override, perform action differently
        // } else {
        //    // Normal layer behavior
        // }

        // Placeholder for actual action
        emit ActionPerformedWithLayer(msg.sender, requiredLayer, block.timestamp);
    }

    event ActionPerformedWithLayer(address indexed user, bytes32 indexed layerId, uint256 timestamp);


    // --- Ownership Functions (from Ownable) ---
    // transferOwnership and renounceOwnership are inherited and marked as onlyOwner.
    // No need to redeclare unless modifying behavior.

}
```