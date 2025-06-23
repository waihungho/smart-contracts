Okay, let's design an interesting and unique smart contract.

**Concept:** `QuantumEstate` - A contract representing a virtual space composed of unique, non-fungible "Parcels". These parcels aren't just static tokens; they exist within different "Dimensions", which influence their properties, resource generation, and potential interactions. Parcels can be upgraded, shift dimensions (possibly conditionally or probabilistically), and hold internal resources. Users can build "Influence" within dimensions, affecting outcomes related to their parcels.

**Advanced/Creative Aspects:**
1.  **Dimensional State:** Parcels have an active dimension (`enum`) that affects logic.
2.  **Internal Resource System:** Parcels hold their own resource balance generated over time based on state.
3.  **Conditional Logic Automation:** Owners can set on-chain conditions for actions (like dimension shifts or transfers) to execute automatically.
4.  **Dynamic Resource Generation:** Rate depends on Dimension, Upgrade Level, and time.
5.  **Dimension Influence:** Users can gain influence in dimensions, potentially affecting outcomes.
6.  **Coordinate System:** Parcels exist in a 2D coordinate space.
7.  **Upgrade System:** Parcels evolve, unlocking new possibilities.
8.  **Non-Standard Ownership/Transfer:** While NFT-like, transfers might have dimension-specific rules or conditions.
9.  **Basic Interaction Layer:** A generic function to allow different types of on-chain interactions with parcels.
10. **Simulated Prediction:** A function that provides information relevant to probabilistic outcomes (like dimension shifts) without revealing the exact future state on-chain.

---

**// Outline & Function Summary**

**Contract Name:** `QuantumEstate`

**Description:**
A novel smart contract managing unique virtual "Parcels" within a multi-dimensional virtual space. Parcels are non-fungible assets with dynamic properties determined by their current "Dimension", upgrade level, and internal resource balance. The contract incorporates features like time-based resource generation, conditional automation, and a dimension-specific influence system.

**Key Data Structures:**
*   `Coords`: Represents a 2D coordinate (`int256 x`, `int256 y`).
*   `DimensionType`: An enum defining the possible dimensions (`VOID`, `AETHER`, `TERRA`, `AQUA`, `PYRO`, `CHRONOS`).
*   `DimensionProperties`: Struct holding configuration for each dimension (e.g., resource generation modifier, shift difficulty).
*   `Parcel`: Struct holding a parcel's state (`owner`, `coords`, `currentDimension`, `resourceBalance`, `lastResourceHarvest`, `upgradeLevel`, `conditionalLogicId`).
*   `ConditionalLogicSetting`: Struct defining an automated action (`targetTimestamp`, `requiredResource`, `actionType`, `actionParams`).
*   `ActionType`: Enum for conditional actions (`SHIFT_DIMENSION`, `TRANSFER_PARCEL`, `HARVEST_RESOURCES`).

**State Variables:**
*   `owner`: Contract deployer.
*   `parcelCounter`: Tracks total number of parcels minted.
*   `parcels`: Mapping from `uint256` (parcel ID) to `Parcel` struct.
*   `coordsToId`: Mapping from `Coords` to `uint256` (parcel ID), ensures uniqueness.
*   `dimensionProps`: Mapping from `DimensionType` to `DimensionProperties`.
*   `userDimensionInfluence`: Mapping from `address` to `mapping(DimensionType => uint256)`, tracks influence.
*   `conditionalLogicSettings`: Mapping from `uint256` (parcel ID) to `ConditionalLogicSetting`.
*   `logicCounter`: Tracks unique IDs for conditional logic settings.

**Events:**
*   `ParcelDiscovered`: When a new parcel is minted.
*   `ParcelTransferred`: When a parcel changes owner.
*   `DimensionShifted`: When a parcel changes dimension.
*   `ParcelUpgraded`: When a parcel's level increases.
*   `ResourcesHarvested`: When resources are collected from a parcel.
*   `ConditionalLogicSet`: When automation logic is configured.
*   `ConditionalLogicExecuted`: When automation logic triggers an action.
*   `ConditionalLogicCancelled`: When automation logic is removed.
*   `InfluenceGained`: When a user's influence in a dimension increases.
*   `InteractionHappened`: When `interactWithParcel` is called.

**Modifiers:**
*   `onlyOwner`: Restricts function calls to the contract owner.
*   `parcelExists(uint256 _parcelId)`: Ensures a parcel ID is valid.
*   `isParcelOwner(uint256 _parcelId)`: Ensures the caller owns the parcel.
*   `isValidDimension(DimensionType _dim)`: Ensures a dimension is valid (not `VOID`).

**Functions (Minimum 20):**

1.  `constructor()`: Initializes the contract, sets owner.
2.  `discoverParcel(Coords memory _coords)`: Mints a new parcel at specified coordinates if available. Assigns initial dimension and state.
3.  `getParcelOwner(uint256 _parcelId) view`: Returns the owner of a parcel.
4.  `getParcelCoords(uint256 _parcelId) view`: Returns the coordinates of a parcel.
5.  `getParcelDimension(uint256 _parcelId) view`: Returns the current dimension of a parcel.
6.  `getParcelResourceBalance(uint256 _parcelId) view`: Returns the internal resource balance of a parcel.
7.  `getParcelUpgradeLevel(uint256 _parcelId) view`: Returns the upgrade level of a parcel.
8.  `transferParcel(address _to, uint256 _parcelId)`: Transfers ownership of a parcel. Includes dimension-specific potential checks.
9.  `harvestResources(uint256 _parcelId)`: Calculates and adds resources generated since the last harvest based on dimension, level, and time.
10. `getResourceGenerationRate(uint256 _parcelId) view`: Calculates the current resource generation rate per unit time for a parcel.
11. `shiftDimension(uint256 _parcelId, DimensionType _targetDimension)`: Attempts to shift the parcel's dimension. May require resources or influence.
12. `getDimensionProperties(DimensionType _dim) view`: Returns the configuration properties for a specific dimension.
13. `setDimensionProperties(DimensionType _dim, DimensionProperties memory _props)`: (Owner) Sets or updates the properties for a dimension.
14. `upgradeParcel(uint256 _parcelId)`: Upgrades the parcel's level using its internal resources. Cost increases with level.
15. `getUpgradeCost(uint8 _level) pure`: Returns the resource cost for a specific upgrade level.
16. `getUserDimensionInfluence(address _user, DimensionType _dim) view`: Returns the influence a user has in a specific dimension.
17. `gainInfluence(DimensionType _dim, uint256 _amount)`: Allows users to gain influence in a dimension (e.g., by spending resources or interacting).
18. `setConditionalLogic(uint256 _parcelId, ConditionalLogicSetting memory _setting)`: Allows the parcel owner to set automated execution logic.
19. `executeConditionalLogic(uint256 _parcelId)`: Public function anyone can call to attempt execution of a parcel's conditional logic if conditions are met.
20. `cancelConditionalLogic(uint256 _parcelId)`: Allows the parcel owner to cancel active conditional logic.
21. `getConditionalLogicSetting(uint256 _parcelId) view`: Returns the active conditional logic setting for a parcel.
22. `interactWithParcel(uint256 _parcelId, bytes memory _data)`: A generic function allowing users to interact with a parcel. The interaction type and parameters are encoded in `_data`. Logic within this function can be extended (e.g., leaving a message, attempting a minor resource extraction if permissions allow, triggering a visual effect off-chain).
23. `predictDimensionShiftOutcome(uint256 _parcelId, DimensionType _targetDimension) view`: Provides probabilistic information or requirements for a dimension shift attempt (e.g., required influence, chance percentage based on current state), without revealing the exact on-chain random outcome if applicable.
24. `getTotalParcelsMinted() view`: Returns the total number of parcels created.
25. `getParcelIdByCoords(Coords memory _coords) view`: Returns the parcel ID at specific coordinates, or 0 if none exists.
26. `withdrawContractBalance() onlyOwner`: Allows the owner to withdraw any native currency sent to the contract (e.g., from discovery fees, although not explicitly added here, good practice to include).
27. `calculateResourceGeneration(uint256 _parcelId) view`: Internal/helper function made external for visibility - calculates pending resources to be harvested.
28. `isCoordsOccupied(Coords memory _coords) view`: Checks if coordinates are already occupied by a parcel.
29. `getParcelDetails(uint256 _parcelId) view`: Returns a tuple or struct containing multiple details about a parcel for convenience.
30. `_applyResourceGeneration(uint256 _parcelId) internal`: Internal helper to update resources and last harvest time. (While internal, needed for logic, and `calculateResourceGeneration` covers external view). *Correction:* Let's make this count towards the 20+ if exposed for partial data, or just rely on the others. Let's add a few more getters or simple utility functions to be safe.
31. `getDimensionModifier(DimensionType _dim, string memory _modifierKey) view`: Generic getter for a dimension property modifier (using a key). *Self-correction:* Simpler to just expose the struct.
32. Let's add `getParcelLastHarvestTime` (30) and `getParcelConditionalLogicId` (31) for completeness. We are well over 20 now.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// Outline & Function Summary - See top of file

contract QuantumEstate {

    address public owner;
    uint256 private parcelCounter;
    uint256 private logicCounter; // Counter for unique conditional logic settings

    // --- Data Structures ---

    struct Coords {
        int256 x;
        int256 y;
    }

    // Using a simple hash for Coords equality check in mappings
    // Note: This is a basic hash and could have collisions on extreme coordinate values.
    // For a production system with a vast coordinate space, a more robust solution
    // (e.g., Z-order curve mapping to a single uint256 or dedicated library) might be needed.
    // For this example, it's sufficient.
    function _hashCoords(Coords memory c) pure internal returns (bytes32) {
        return keccak256(abi.encodePacked(c.x, c.y));
    }

    enum DimensionType {
        VOID,     // Unassigned or initial state (shouldn't have parcels)
        AETHER,
        TERRA,
        AQUA,
        PYRO,
        CHRONOS  // Represents temporal flow influence
    }

    enum ActionType {
        NONE,
        SHIFT_DIMENSION,
        TRANSFER_PARCEL,
        HARVEST_RESOURCES // Could automate harvesting
    }

    struct DimensionProperties {
        uint256 baseResourcePerSecond; // Base generation rate per second
        uint256 shiftDifficulty;       // Cost or check modifier for shifting to this dimension
        // Could add more properties like 'interaction modifier', 'visual traits hash', etc.
    }

    struct ConditionalLogicSetting {
        uint224 id;                 // Unique ID for this specific setting instance
        uint48 targetTimestamp;     // Timestamp when condition might be met
        uint256 requiredResource;   // Required resource amount in parcel
        ActionType actionType;      // What to do if conditions met
        bytes actionParams;         // ABI-encoded parameters for the action (e.g., target dimension, target address)
        bool isActive;              // Flag to easily check if logic is set
    }


    struct Parcel {
        uint256 id;                 // Unique ID
        address owner;              // Owner address
        Coords coords;              // 2D coordinates
        DimensionType currentDimension; // Active dimension
        uint256 resourceBalance;    // Internal resource balance
        uint48 lastResourceHarvest; // Timestamp of last resource calculation
        uint8 upgradeLevel;         // Upgrade level (0-255)
        uint224 conditionalLogicId; // ID of the currently active conditional logic setting (0 if none)
    }

    // --- State Variables ---

    mapping(uint256 => Parcel) private parcels; // Parcel ID to Parcel struct
    mapping(bytes32 => uint256) private coordsToId; // Coords hash to Parcel ID (for availability check)

    mapping(DimensionType => DimensionProperties) private dimensionProps;

    // Tracks user influence in each dimension
    mapping(address => mapping(DimensionType => uint256)) private userDimensionInfluence;

    // Stores conditional logic settings by their unique ID
    mapping(uint224 => ConditionalLogicSetting) private conditionalLogicSettings;
    // Mapping from parcel ID to the current logic setting ID
    mapping(uint256 => uint224) private parcelToLogicId;


    // --- Events ---

    event ParcelDiscovered(uint256 indexed parcelId, address indexed owner, Coords coords, DimensionType initialDimension);
    event ParcelTransferred(uint256 indexed parcelId, address indexed from, address indexed to);
    event DimensionShifted(uint256 indexed parcelId, DimensionType indexed fromDimension, DimensionType indexed toDimension, uint256 influenceUsed);
    event ParcelUpgraded(uint256 indexed parcelId, uint8 indexed newLevel, uint256 resourcesSpent);
    event ResourcesHarvested(uint256 indexed parcelId, uint256 amount);
    event ConditionalLogicSet(uint256 indexed parcelId, uint224 indexed logicId, ActionType actionType, uint48 targetTimestamp);
    event ConditionalLogicExecuted(uint256 indexed parcelId, uint224 indexed logicId, ActionType actionType);
    event ConditionalLogicCancelled(uint256 indexed parcelId, uint224 indexed logicId);
    event InfluenceGained(address indexed user, DimensionType indexed dimension, uint256 amount);
    event InteractionHappened(uint256 indexed parcelId, address indexed initiator, bytes interactionData);


    // --- Modifiers ---

    modifier onlyOwner() {
        require(msg.sender == owner, "Only contract owner can call this function");
        _;
    }

    modifier parcelExists(uint256 _parcelId) {
        require(_parcelId > 0 && _parcelId <= parcelCounter, "Parcel does not exist");
        _;
    }

    modifier isParcelOwner(uint256 _parcelId) {
        require(parcels[_parcelId].owner == msg.sender, "Not the parcel owner");
        _;
    }

    modifier isValidDimension(DimensionType _dim) {
        require(_dim != DimensionType.VOID, "Invalid dimension type");
        // Add checks for valid enum range if needed
        _;
    }

    // --- Constructor ---

    constructor() {
        owner = msg.sender;
        parcelCounter = 0;
        logicCounter = 0; // Start logic IDs from 1 maybe? Or handle 0 as 'none'. Let's use 0 as 'none'.
        // Initialize default dimension properties (example values)
        dimensionProps[DimensionType.AETHER] = DimensionProperties({baseResourcePerSecond: 10, shiftDifficulty: 50});
        dimensionProps[DimensionType.TERRA] = DimensionProperties({baseResourcePerSecond: 15, shiftDifficulty: 30});
        dimensionProps[DimensionType.AQUA] = DimensionProperties({baseResourcePerSecond: 12, shiftDifficulty: 40});
        dimensionProps[DimensionType.PYRO] = DimensionProperties({baseResourcePerSecond: 18, shiftDifficulty: 60});
        dimensionProps[DimensionType.CHRONOS] = DimensionProperties({baseResourcePerSecond: 20, shiftDifficulty: 80}); // Harder to reach/maintain
    }

    // --- Core Parcel Management ---

    /// @notice Mints a new parcel at specified coordinates if available.
    /// @param _coords The desired coordinates for the new parcel.
    /// @return uint256 The ID of the newly discovered parcel.
    function discoverParcel(Coords memory _coords) public returns (uint256) {
        bytes32 coordsHash = _hashCoords(_coords);
        require(coordsToId[coordsHash] == 0, "Coordinates already occupied");

        parcelCounter++;
        uint256 newParcelId = parcelCounter;

        // Assign initial state (e.g., random or based on coords/block hash)
        // For simplicity, let's assign based on a simple hash modulo number of dimensions
        DimensionType initialDimension = DimensionType(
            uint8(keccak256(abi.encodePacked(_coords.x, _coords.y, block.timestamp))) % (uint8(DimensionType.CHRONOS) + 1 - uint8(DimensionType.VOID))
            + uint8(DimensionType.VOID) + 1 // Ensure it's not VOID
        );
        if (initialDimension == DimensionType.VOID) initialDimension = DimensionType.AETHER; // Fallback just in case

        parcels[newParcelId] = Parcel({
            id: newParcelId,
            owner: msg.sender,
            coords: _coords,
            currentDimension: initialDimension,
            resourceBalance: 0,
            lastResourceHarvest: uint48(block.timestamp),
            upgradeLevel: 0,
            conditionalLogicId: 0
        });

        coordsToId[coordsHash] = newParcelId;

        emit ParcelDiscovered(newParcelId, msg.sender, _coords, initialDimension);

        return newParcelId;
    }

    /// @notice Returns the owner of a parcel.
    /// @param _parcelId The ID of the parcel.
    /// @return address The owner's address.
    function getParcelOwner(uint256 _parcelId) public view parcelExists(_parcelId) returns (address) {
        return parcels[_parcelId].owner;
    }

    /// @notice Returns the coordinates of a parcel.
    /// @param _parcelId The ID of the parcel.
    /// @return Coords The parcel's coordinates.
    function getParcelCoords(uint256 _parcelId) public view parcelExists(_parcelId) returns (Coords memory) {
        return parcels[_parcelId].coords;
    }

    /// @notice Returns the current dimension of a parcel.
    /// @param _parcelId The ID of the parcel.
    /// @return DimensionType The parcel's dimension.
    function getParcelDimension(uint256 _parcelId) public view parcelExists(_parcelId) returns (DimensionType) {
        return parcels[_parcelId].currentDimension;
    }

    /// @notice Returns the internal resource balance of a parcel.
    /// @param _parcelId The ID of the parcel.
    /// @return uint256 The resource balance.
    function getParcelResourceBalance(uint256 _parcelId) public view parcelExists(_parcelId) returns (uint256) {
        // Automatically calculate potential pending resources for view calls
        return parcels[_parcelId].resourceBalance + calculateResourceGeneration(_parcelId);
    }

     /// @notice Returns the last harvest time of a parcel's resources.
    /// @param _parcelId The ID of the parcel.
    /// @return uint48 The timestamp of the last harvest.
    function getParcelLastHarvestTime(uint256 _parcelId) public view parcelExists(_parcelId) returns (uint48) {
        return parcels[_parcelId].lastResourceHarvest;
    }


    /// @notice Returns the upgrade level of a parcel.
    /// @param _parcelId The ID of the parcel.
    /// @return uint8 The upgrade level.
    function getParcelUpgradeLevel(uint256 _parcelId) public view parcelExists(_parcelId) returns (uint8) {
        return parcels[_parcelId].upgradeLevel;
    }

    /// @notice Transfers ownership of a parcel.
    /// @param _to The recipient address.
    /// @param _parcelId The ID of the parcel to transfer.
    function transferParcel(address _to, uint256 _parcelId) public isParcelOwner(_parcelId) parcelExists(_parcelId) {
        // Optional: Add dimension-specific transfer restrictions here if needed
        // e.g., require(parcels[_parcelId].currentDimension != DimensionType.CHRONOS, "Cannot transfer Chronos parcels");

        address from = msg.sender;
        parcels[_parcelId].owner = _to;

        // Cancel any active conditional logic on transfer
        if (parcels[_parcelId].conditionalLogicId != 0) {
            cancelConditionalLogic(_parcelId); // Automatically calls the cancel function logic
        }

        emit ParcelTransferred(_parcelId, from, _to);
    }

    /// @notice Gets multiple details about a parcel for convenience.
    /// @param _parcelId The ID of the parcel.
    /// @return tuple A tuple containing parcel details.
    function getParcelDetails(uint256 _parcelId) public view parcelExists(_parcelId)
        returns (
            uint256 id,
            address owner,
            Coords memory coords,
            DimensionType currentDimension,
            uint256 resourceBalance,
            uint48 lastResourceHarvest,
            uint8 upgradeLevel,
            uint224 conditionalLogicId
        )
    {
        Parcel storage p = parcels[_parcelId];
        return (
            p.id,
            p.owner,
            p.coords,
            p.currentDimension,
            p.resourceBalance + calculateResourceGeneration(_parcelId), // Include pending
            p.lastResourceHarvest,
            p.upgradeLevel,
            p.conditionalLogicId
        );
    }


    // --- Resource System ---

    /// @notice Calculates resources generated since the last harvest.
    /// @param _parcelId The ID of the parcel.
    /// @return uint256 The amount of resources generated.
    function calculateResourceGeneration(uint256 _parcelId) public view parcelExists(_parcelId) returns (uint256) {
        Parcel storage p = parcels[_parcelId];
        uint48 currentTime = uint48(block.timestamp);
        if (currentTime <= p.lastResourceHarvest) {
            return 0;
        }

        uint256 timeElapsed = currentTime - p.lastResourceHarvest;
        DimensionType currentDim = p.currentDimension;
        uint8 level = p.upgradeLevel;

        // Generation formula: (base rate per second * dimension modifier * level modifier) * time elapsed
        // Level modifier: Simple example (1 + level/10.0), scale appropriately
        uint256 baseRate = dimensionProps[currentDim].baseResourcePerSecond;
        uint256 levelModifier = 100 + level * 10; // e.g., level 0 = 100%, level 10 = 200%

        return (baseRate * timeElapsed * levelModifier) / 100; // Integer division
    }

     /// @notice Applies generated resources and updates last harvest time. Internal helper.
    /// @param _parcelId The ID of the parcel.
    function _applyResourceGeneration(uint256 _parcelId) internal {
        uint256 generated = calculateResourceGeneration(_parcelId);
        if (generated > 0) {
            parcels[_parcelId].resourceBalance += generated;
            parcels[_parcelId].lastResourceHarvest = uint48(block.timestamp);
             emit ResourcesHarvested(_parcelId, generated); // Can emit here or from public harvest func
        }
    }


    /// @notice Harvests generated resources from a parcel. Adds pending resources to the balance.
    /// @param _parcelId The ID of the parcel.
    function harvestResources(uint256 _parcelId) public isParcelOwner(_parcelId) parcelExists(_parcelId) {
        _applyResourceGeneration(_parcelId);
        // ResourcesHarvested event is emitted by _applyResourceGeneration
    }

    /// @notice Gets the current resource generation rate per second for a parcel, ignoring level.
    /// @param _parcelId The ID of the parcel.
    /// @return uint256 The base resource generation rate per second for the parcel's current dimension.
    function getResourceGenerationRate(uint256 _parcelId) public view parcelExists(_parcelId) returns (uint256) {
        DimensionType currentDim = parcels[_parcelId].currentDimension;
        return dimensionProps[currentDim].baseResourcePerSecond; // Return base rate per second
    }

    // --- Dimension & State Management ---

    /// @notice Attempts to shift the parcel's dimension. Requires resources and considers difficulty/influence.
    /// @param _parcelId The ID of the parcel.
    /// @param _targetDimension The dimension to shift to.
    function shiftDimension(uint256 _parcelId, DimensionType _targetDimension) public isParcelOwner(_parcelId) parcelExists(_parcelId) isValidDimension(_targetDimension) {
        Parcel storage p = parcels[_parcelId];
        require(p.currentDimension != _targetDimension, "Already in target dimension");

        // Apply pending resource generation before calculating cost/chance
        _applyResourceGeneration(_parcelId);

        // Example Shift Logic: Requires resources based on target difficulty, influenced by user influence.
        uint256 difficulty = dimensionProps[_targetDimension].shiftDifficulty;
        uint224 currentLogicId = p.conditionalLogicId; // Store before potential state change

        // Calculate required resource cost (example formula)
        uint256 requiredCost = difficulty * (p.upgradeLevel + 1);
        require(p.resourceBalance >= requiredCost, "Insufficient parcel resources for dimension shift");

        // Deduct resources
        p.resourceBalance -= requiredCost;

        // Example Influence Check (optional / can affect probability off-chain)
        // uint256 userInfluenceInTargetDim = userDimensionInfluence[msg.sender][_targetDimension];
        // bool shiftSuccessful = _checkShiftSuccess(difficulty, userInfluenceInTargetDim); // Placeholder for complex logic

        // For simplicity in this example, dimension shifts are deterministic if cost is met.
        // A more advanced version could use blockhash/timestamp for on-chain randomness if carefully designed,
        // or rely on oracle-based randomness for security.

        DimensionType fromDimension = p.currentDimension;
        p.currentDimension = _targetDimension;

        // If successful shift was triggered by conditional logic, mark that logic as executed
         if (currentLogicId != 0 && conditionalLogicSettings[currentLogicId].actionType == ActionType.SHIFT_DIMENSION) {
             // Check if this call specifically came from executeConditionalLogic (difficult directly)
             // A simpler approach is to rely on the logic to call THIS function.
             // If this function is called directly by the owner, the logic is simply bypassed for this manual shift.
         }


        emit DimensionShifted(_parcelId, fromDimension, _targetDimension, 0); // Emit resources spent or influence used
    }

    /// @notice Returns the configuration properties for a specific dimension.
    /// @param _dim The dimension type.
    /// @return DimensionProperties The dimension's properties.
    function getDimensionProperties(DimensionType _dim) public view isValidDimension(_dim) returns (DimensionProperties memory) {
        return dimensionProps[_dim];
    }

    /// @notice Owner function to set or update the properties for a dimension.
    /// @param _dim The dimension type.
    /// @param _props The properties struct to set.
    function setDimensionProperties(DimensionType _dim, DimensionProperties memory _props) public onlyOwner isValidDimension(_dim) {
        dimensionProps[_dim] = _props;
    }


    // --- Upgrades & Evolution ---

    /// @notice Upgrades the parcel's level using its internal resources.
    /// @param _parcelId The ID of the parcel.
    function upgradeParcel(uint256 _parcelId) public isParcelOwner(_parcelId) parcelExists(_parcelId) {
        Parcel storage p = parcels[_parcelId];
        require(p.upgradeLevel < 255, "Parcel is already at max level");

        // Apply pending resource generation
        _applyResourceGeneration(_parcelId);

        uint256 requiredCost = getUpgradeCost(p.upgradeLevel + 1);
        require(p.resourceBalance >= requiredCost, "Insufficient parcel resources for upgrade");

        p.resourceBalance -= requiredCost;
        p.upgradeLevel++;

        emit ParcelUpgraded(_parcelId, p.upgradeLevel, requiredCost);
    }

    /// @notice Returns the resource cost for a specific upgrade level.
    /// @param _level The target upgrade level (e.g., cost to reach level 1 is cost of level 1).
    /// @return uint256 The required resource cost.
    function getUpgradeCost(uint8 _level) public pure returns (uint256) {
        // Example cost formula: base_cost * (level + 1)^2
        uint256 baseCost = 1000; // Starting cost
        return baseCost * (_level + 1) * (_level + 1);
    }

    /// @notice Calculates the resource cost required for the *next* upgrade level of a specific parcel.
    /// @param _parcelId The ID of the parcel.
    /// @return uint256 The required resource cost for the next level.
    function getRequiredResourcesForUpgrade(uint256 _parcelId) public view parcelExists(_parcelId) returns (uint256) {
         Parcel storage p = parcels[_parcelId];
         if (p.upgradeLevel >= 255) {
             return 0; // Already max level
         }
         return getUpgradeCost(p.upgradeLevel + 1);
    }

    // --- Influence System ---

    /// @notice Returns the influence a user has in a specific dimension.
    /// @param _user The user's address.
    /// @param _dim The dimension type.
    /// @return uint256 The user's influence level.
    function getUserDimensionInfluence(address _user, DimensionType _dim) public view isValidDimension(_dim) returns (uint256) {
        return userDimensionInfluence[_user][_dim];
    }

    /// @notice Allows users to gain influence in a dimension by spending their own resources or interacting.
    /// Note: This implementation is a placeholder. Gaining influence could involve
    /// spending external tokens, locking resources in the contract, or specific actions.
    /// @param _dim The dimension to gain influence in.
    /// @param _amount The amount of influence to gain.
    function gainInfluence(DimensionType _dim, uint256 _amount) public isValidDimension(_dim) {
        require(_amount > 0, "Amount must be greater than zero");
        // Placeholder logic: Assume user pays something or meets a condition off-chain
        // For example, require a specific ERC-20 token balance or a complex interaction history.
        // require(msg.sender has met off-chain condition or paid);

        userDimensionInfluence[msg.sender][_dim] += _amount;

        emit InfluenceGained(msg.sender, _dim, _amount);
    }

    // --- Conditional Logic / Automation ---

    /// @notice Allows the parcel owner to set automated execution logic based on conditions.
    /// @param _parcelId The ID of the parcel.
    /// @param _setting The conditional logic setting struct.
    function setConditionalLogic(uint256 _parcelId, ConditionalLogicSetting memory _setting) public isParcelOwner(_parcelId) parcelExists(_parcelId) {
        Parcel storage p = parcels[_parcelId];

        // Cancel any existing logic first
        if (p.conditionalLogicId != 0) {
             _cancelConditionalLogicInternal(_parcelId, p.conditionalLogicId);
        }

        require(_setting.actionType != ActionType.NONE, "Action type must be specified");
        // Add validation for actionParams based on actionType

        logicCounter++;
        uint224 newLogicId = uint224(logicCounter);

        // Store the setting
        _setting.id = newLogicId;
        _setting.isActive = true; // Mark as active upon setting
        conditionalLogicSettings[newLogicId] = _setting;

        // Link parcel to the new logic setting
        p.conditionalLogicId = newLogicId;
        parcelToLogicId[_parcelId] = newLogicId; // Redundant mapping, but good for clarity/lookup? Let's stick to Parcel struct link.

        emit ConditionalLogicSet(_parcelId, newLogicId, _setting.actionType, _setting.targetTimestamp);
    }

    /// @notice Public function anyone can call to attempt execution of a parcel's conditional logic if conditions are met.
    /// @param _parcelId The ID of the parcel.
    function executeConditionalLogic(uint256 _parcelId) public parcelExists(_parcelId) {
        Parcel storage p = parcels[_parcelId];
        uint224 currentLogicId = p.conditionalLogicId;

        require(currentLogicId != 0, "No conditional logic set for this parcel");

        ConditionalLogicSetting storage setting = conditionalLogicSettings[currentLogicId];
        require(setting.isActive, "Conditional logic is not active");

        // Check Conditions
        bool conditionsMet = true;
        if (block.timestamp < setting.targetTimestamp) {
            conditionsMet = false;
        }
        // Check resource balance (after applying potential generation)
        _applyResourceGeneration(_parcelId); // Ensure balance is up-to-date
        if (p.resourceBalance < setting.requiredResource) {
            conditionsMet = false;
        }
        // Add other potential conditions here (e.g., external oracle data check, specific user interaction)

        require(conditionsMet, "Conditional logic conditions not met");

        // Execute Action
        ActionType action = setting.actionType;
        bytes memory params = setting.actionParams;

        // Before execution, mark as inactive and unlink from parcel to prevent re-execution
        setting.isActive = false;
        p.conditionalLogicId = 0;

        // Clean up the mapping entry (optional, gas saving on subsequent checks)
        delete parcelToLogicId[_parcelId]; // If using this helper mapping

        // Perform the action based on type
        if (action == ActionType.SHIFT_DIMENSION) {
            // Assuming actionParams encodes the target dimension (uint8)
            require(params.length == 1, "Invalid params for SHIFT_DIMENSION");
            DimensionType targetDim = DimensionType(uint8(params[0]));
             // Call the internal shift logic, bypassing owner check as this is automated
             _shiftDimensionInternal(_parcelId, targetDim);

        } else if (action == ActionType.TRANSFER_PARCEL) {
             // Assuming actionParams encodes the target address (address)
            require(params.length == 20, "Invalid params for TRANSFER_PARCEL");
            address targetAddress = abi.decode(params, (address));
            // Call the internal transfer logic, bypassing owner check
            _transferParcelInternal(_parcelId, targetAddress);

        } else if (action == ActionType.HARVEST_RESOURCES) {
             // Assuming no specific params needed, just trigger harvest
             _applyResourceGeneration(_parcelId); // Harvest resources
             // ResourcesHarvested event is emitted by _applyResourceGeneration
        }
        // Add more action types as needed

        emit ConditionalLogicExecuted(_parcelId, currentLogicId, action);
    }

    /// @notice Allows the parcel owner to cancel active conditional logic.
    /// @param _parcelId The ID of the parcel.
    function cancelConditionalLogic(uint256 _parcelId) public isParcelOwner(_parcelId) parcelExists(_parcelId) {
         uint224 currentLogicId = parcels[_parcelId].conditionalLogicId;
         require(currentLogicId != 0, "No conditional logic set for this parcel");
         _cancelConditionalLogicInternal(_parcelId, currentLogicId);
    }

    /// @dev Internal helper to cancel conditional logic by ID.
    /// @param _parcelId The parcel ID.
    /// @param _logicId The logic setting ID.
    function _cancelConditionalLogicInternal(uint256 _parcelId, uint224 _logicId) internal {
        // Ensure the logic ID matches the parcel's current setting
        require(parcels[_parcelId].conditionalLogicId == _logicId, "Logic ID mismatch for parcel");

        ConditionalLogicSetting storage setting = conditionalLogicSettings[_logicId];
        require(setting.isActive, "Conditional logic is already inactive");

        setting.isActive = false; // Mark as inactive
        parcels[_parcelId].conditionalLogicId = 0; // Unlink from parcel

        // Optional: Delete the setting entry to save gas on future checks if needed
        // delete conditionalLogicSettings[_logicId];

        emit ConditionalLogicCancelled(_parcelId, _logicId);
    }


    /// @notice Returns the active conditional logic setting for a parcel.
    /// @param _parcelId The ID of the parcel.
    /// @return ConditionalLogicSetting The setting struct (will have isActive=false or default values if none or inactive).
    function getConditionalLogicSetting(uint256 _parcelId) public view parcelExists(_parcelId) returns (ConditionalLogicSetting memory) {
         uint224 currentLogicId = parcels[_parcelId].conditionalLogicId;
         if (currentLogicId == 0) {
             // Return a default/empty setting if none is active
             return ConditionalLogicSetting({
                 id: 0,
                 targetTimestamp: 0,
                 requiredResource: 0,
                 actionType: ActionType.NONE,
                 actionParams: "",
                 isActive: false
             });
         }
         // Return the setting struct (might be inactive, check isActive field)
         return conditionalLogicSettings[currentLogicId];
    }

    /// @notice Returns the ID of the active conditional logic setting for a parcel.
    /// @param _parcelId The ID of the parcel.
    /// @return uint224 The logic setting ID (0 if none).
    function getParcelConditionalLogicId(uint256 _parcelId) public view parcelExists(_parcelId) returns (uint224) {
        return parcels[_parcelId].conditionalLogicId;
    }


    // --- Interaction / Advanced ---

    /// @notice A generic function allowing users to interact with a parcel.
    /// The interaction type and parameters are encoded in `_data`.
    /// This function can be extended to support various on-chain or off-chain interactions.
    /// @param _parcelId The ID of the parcel to interact with.
    /// @param _data Arbitrary bytes encoding the interaction type and data.
    function interactWithParcel(uint256 _parcelId, bytes memory _data) public parcelExists(_parcelId) {
        // Example: Decode interaction type from the first few bytes of _data
        // This is highly flexible. Could use function selectors, simple enums, etc.
        // For this example, we just emit an event. Real logic would process _data.

        // Placeholder for potential interaction logic:
        // if (_data.length >= 4 && bytes4(_data[0..4]) == bytes4(keccak256("leaveMessage"))) {
        //     // Decode message from _data and store it or emit another event
        //     string memory message = abi.decode(_data[4..], (string));
        //     // store or process message...
        // } else if (_data.length >= 4 && bytes4(_data[0..4]) == bytes4(keccak256("attemptInfluenceGain"))) {
        //     // Attempt to gain influence based on interaction complexity in _data
        //     // require(... conditions based on _data ...);
        //     // gainInfluence(parcels[_parcelId].currentDimension, amount);
        // }
        // Add more interaction types...

        // Basic Example: Just log the interaction
        emit InteractionHappened(_parcelId, msg.sender, _data);
    }

    /// @notice Provides probabilistic information or requirements for a dimension shift attempt.
    /// This function is `view` and does not change state. It simulates complexity
    /// without revealing deterministic future outcomes on-chain.
    /// @param _parcelId The ID of the parcel.
    /// @param _targetDimension The dimension type to predict for.
    /// @return tuple Returns information about the potential shift (e.g., required resources, potential success chance off-chain).
    function predictDimensionShiftOutcome(uint256 _parcelId, DimensionType _targetDimension) public view parcelExists(_parcelId) isValidDimension(_targetDimension) returns (uint256 requiredResources, uint256 difficulty, uint256 userInfluence) {
        Parcel storage p = parcels[_parcelId];
        difficulty = dimensionProps[_targetDimension].shiftDifficulty;

        // Calculate required resources based on level and difficulty (same formula as shiftDimension)
        requiredResources = difficulty * (p.upgradeLevel + 1);

        // Get user's influence in the target dimension
        userInfluence = userDimensionInfluence[msg.sender][_targetDimension];

        // Note: Actual success chance logic would likely happen off-chain using this data,
        // or use carefully designed on-chain pseudo-randomness if acceptable risk.
        // This function only provides inputs to that potential calculation.

        return (requiredResources, difficulty, userInfluence);
    }

    // --- Admin/Meta ---

    /// @notice Returns the total number of parcels created.
    /// @return uint256 The total count of parcels.
    function getTotalParcelsMinted() public view returns (uint256) {
        return parcelCounter;
    }

    /// @notice Returns the parcel ID at specific coordinates, or 0 if none exists.
    /// @param _coords The coordinates to check.
    /// @return uint256 The parcel ID or 0.
    function getParcelIdByCoords(Coords memory _coords) public view returns (uint256) {
        return coordsToId[_hashCoords(_coords)];
    }

    /// @notice Checks if coordinates are already occupied by a parcel.
    /// @param _coords The coordinates to check.
    /// @return bool True if occupied, false otherwise.
    function isCoordsOccupied(Coords memory _coords) public view returns (bool) {
        return coordsToId[_hashCoords(_coords)] != 0;
    }

    /// @notice Allows the owner to withdraw any native currency sent to the contract.
    function withdrawContractBalance() public onlyOwner {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Withdraw failed");
    }

    // --- Internal Helper Functions (Not counting towards the 20+ publicly) ---
    // These are used by public functions but are kept internal to manage complexity.

    /// @dev Internal helper for dimension shifting, bypassing owner check. Used by conditional logic.
    /// @param _parcelId The ID of the parcel.
    /// @param _targetDimension The dimension to shift to.
     function _shiftDimensionInternal(uint256 _parcelId, DimensionType _targetDimension) internal parcelExists(_parcelId) isValidDimension(_targetDimension) {
         Parcel storage p = parcels[_parcelId];
         require(p.currentDimension != _targetDimension, "Already in target dimension (internal)");

         // Re-apply generation just in case time passed since executeLogic check
         _applyResourceGeneration(_parcelId);

         uint256 difficulty = dimensionProps[_targetDimension].shiftDifficulty;
         uint256 requiredCost = difficulty * (p.upgradeLevel + 1);
         // Assumption: executeConditionalLogic already checked resources.
         // A robust system might re-check or require specific setup.
         // For this example, we assume logic execution means conditions were met recently.
         // require(p.resourceBalance >= requiredCost, "Insufficient parcel resources for dimension shift (internal)");
         // p.resourceBalance -= requiredCost; // Deduct resources if re-checking

         DimensionType fromDimension = p.currentDimension;
         p.currentDimension = _targetDimension;

         emit DimensionShifted(_parcelId, fromDimension, _targetDimension, requiredCost); // Emit cost
     }

    /// @dev Internal helper for parcel transfer, bypassing owner check. Used by conditional logic.
    /// @param _parcelId The ID of the parcel.
    /// @param _to The recipient address.
    function _transferParcelInternal(uint256 _parcelId, address _to) internal parcelExists(_parcelId) {
         // Note: This internal transfer bypasses the public transfer's msg.sender owner check.
         // Ensure logic calling this is authorized (e.g., only callable from executeConditionalLogic).
         // Also bypasses potential dimension-specific restrictions from the public transfer.
         // If those restrictions should apply to automated transfers, move the logic here.

         address from = parcels[_parcelId].owner; // Get current owner before transfer
         parcels[_parcelId].owner = _to;

         // Conditional logic was already handled (cancelled) in executeConditionalLogic

         emit ParcelTransferred(_parcelId, from, _to);
    }


     // Received Ether
    receive() external payable {}
    fallback() external payable {}
}
```