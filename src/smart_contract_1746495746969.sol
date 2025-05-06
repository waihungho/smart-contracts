Okay, here is a Solidity smart contract designed with a unique concept: a "Quantum Quarry" simulation game combining elements of resource production, upgrades, crafting, global research, and time-based mechanics, implemented without directly inheriting from standard ERC-20 or ERC-721 libraries (simulating their state internally for novelty as requested by "don't duplicate open source," though a real dApp would likely use standards).

It features multiple interconnected mechanics and aims for complexity beyond typical examples.

---

**Smart Contract: QuantumQuarry**

**Concept:**
A simulation game where users deploy "Quarries" (represented by unique IDs/NFT-like properties managed internally) in specific "Locations" to extract different types of "Exotic Matter" (EM - represented by fungible token-like balances managed internally). Quarries produce EM over time based on their level, efficiency, location properties, and global events (Anomalies). Users can upgrade their Quarries, discover new resources through global research, craft new EM types from existing ones, and manage their operations.

**Outline:**

1.  **State Variables:** Define Quarry, Location, ResourceType, Recipe, and Anomaly structures. Mappings to store instances and user balances/ownership. Admin addresses. Counters for unique IDs.
2.  **Events:** Declare events for key actions (Minting Quarry, Harvesting, Upgrading, Crafting, Research, Anomaly).
3.  **Modifiers:** Admin-only checks.
4.  **Core Logic:**
    *   Admin Functions: Setting game parameters, adding resource types, recipes, locations, triggering anomalies.
    *   User Functions:
        *   Quarry Management: Deploying, transferring, scraping, pausing/resuming.
        *   Production: Calculating pending resources, harvesting.
        *   Upgrades: Improving quarry properties (efficiency, capacity, resources unlocked).
        *   Crafting: Combining resources based on recipes.
        *   Research: Contributing to global research progress to unlock new resources (admin action required to finalize unlock).
    *   Read Functions: Retrieving details about quarries, locations, resources, recipes, user balances, production rates.

**Function Summary (26 functions):**

1.  `constructor()`: Initializes the contract owner and fuel token address.
2.  `addAdmin(address _newAdmin)`: Grants admin privileges to an address (Owner only).
3.  `removeAdmin(address _adminToRemove)`: Revokes admin privileges (Owner only).
4.  `setFuelTokenAddress(address _fuelToken)`: Sets the address of the external ERC-20 token used for fueling (Admin only).
5.  `createTokenType(string memory _name, string memory _symbol)`: Defines a new type of Exotic Matter token (Admin only).
6.  `setLocationParameters(uint256 _locationId, uint256 _baseRate, uint256 _capacity, uint256[] memory _availableResourceIds)`: Sets/updates parameters for a location (Admin only).
7.  `grantLocationAccess(uint256 _locationId, address _user, bool _hasAccess)`: Grants or revokes a user's access to deploy quarries in a specific location (Admin only).
8.  `deployQuarry(uint256 _locationId)`: Mints a new Quarry and assigns it to a location and the caller. Requires location access.
9.  `transferQuarry(address _to, uint256 _quarryId)`: Transfers ownership of a Quarry NFT (Caller must be owner).
10. `scrapeQuarry(uint256 _quarryId)`: Burns a Quarry NFT, returning a portion of its potential value/upgrade costs as resources.
11. `calculatePendingResources(uint256 _quarryId)`: Calculates the current accumulated resources for a specific quarry without harvesting.
12. `harvestQuarry(uint256 _quarryId)`: Claims accumulated resources from a specific quarry. Updates production time and user balances.
13. `harvestAllQuarries()`: Claims accumulated resources from all quarries owned by the caller.
14. `upgradeQuarryEfficiency(uint256 _quarryId, uint256 _resourceTypeId, uint256 _amount)`: Spends a resource type to increase a quarry's production efficiency for specific resources.
15. `upgradeQuarryCapacity(uint256 _quarryId, uint256 _resourceTypeId, uint256 _amount)`: Spends a resource type to increase a quarry's maximum pending resource capacity.
16. `unlockResourceAtQuarry(uint256 _quarryId, uint256 _resourceTypeId)`: Spends resources to enable a quarry to produce a specific resource type available at its location.
17. `addCraftingRecipe(uint256[] memory _inputResourceIds, uint256[] memory _inputAmounts, uint256 _outputResourceId, uint256 _outputAmount)`: Defines a new crafting recipe (Admin only).
18. `craftResource(uint256 _recipeId)`: Executes a crafting recipe, consuming input resources and minting output resources for the caller.
19. `contributeToResearch(uint256 _resourceTypeId, uint256 _amount)`: Spends a resource type to contribute to the global research pool for unlocking that resource type.
20. `unlockGlobalResource(uint256 _resourceTypeId)`: Admin action to make a resource type *globally* available in designated locations, potentially triggered by research progress.
21. `setAnomalyParameters(uint256 _anomalyId, string memory _name, uint256 _startTime, uint256 _duration, uint256 _locationId, int256 _rateModifier)`: Defines or updates an anomaly's effects (Admin only).
22. `triggerAnomaly(uint256 _anomalyId)`: Activates a predefined anomaly (Admin only).
23. `refuelQuarry(uint256 _quarryId, uint256 _amount)`: Spends Quantum Fuel tokens (simulated) to increase a quarry's fuel level, maintaining production efficiency.
24. `pauseQuarryProduction(uint256 _quarryId)`: Temporarily pauses a quarry's resource production.
25. `resumeQuarryProduction(uint256 _quarryId)`: Resumes a paused quarry's production.
26. `getQuarryProductionRate(uint256 _quarryId, uint256 _resourceTypeId)`: Calculates the current effective production rate for a specific resource type on a quarry, considering all modifiers (location, upgrades, fuel, anomaly).

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title QuantumQuarry
 * @dev A smart contract simulation game featuring resource extraction, upgrades,
 *      crafting, research, and time-based production using unique internal token/NFT state.
 *      Designed with multiple interconnected mechanics and custom state management
 *      instead of standard library inheritance for uniqueness.
 *
 * Concept:
 * Users deploy "Quarries" (internal NFT-like IDs) in "Locations" to extract
 * different "Exotic Matter" (EM - internal fungible token balances).
 * Quarries produce EM over time based on properties, location, fuel, and global Anomalies.
 * Users can upgrade Quarries, discover new resources via global Research,
 * craft new EM types, and manage operations.
 *
 * Outline:
 * 1. State Variables: Structs for Quarry, Location, ResourceType, Recipe, Anomaly.
 *    Mappings for data storage (Quarries, Balances, Locations, etc.). Counters. Admin addresses.
 * 2. Events: Signalling key state changes (Minting, Harvesting, Crafting, etc.).
 * 3. Modifiers: Access control (Admin, Owner).
 * 4. Core Logic:
 *    - Admin Functions: Setup and modification of game parameters (Resources, Locations, Recipes, Anomalies).
 *    - User Functions: Interact with Quarries (Deploy, Transfer, Scrape, Harvest),
 *      Upgrade Quarries, Craft resources, Contribute to global Research.
 *    - Read Functions: Querying contract state (Quarry details, balances, rates, etc.).
 *
 * Function Summary (26 functions):
 * (See detailed summary above code block for full descriptions)
 *
 * 1. constructor()
 * 2. addAdmin()
 * 3. removeAdmin()
 * 4. setFuelTokenAddress()
 * 5. createTokenType()
 * 6. setLocationParameters()
 * 7. grantLocationAccess()
 * 8. deployQuarry()
 * 9. transferQuarry()
 * 10. scrapeQuarry()
 * 11. calculatePendingResources()
 * 12. harvestQuarry()
 * 13. harvestAllQuarries()
 * 14. upgradeQuarryEfficiency()
 * 15. upgradeQuarryCapacity()
 * 16. unlockResourceAtQuarry()
 * 17. addCraftingRecipe()
 * 18. craftResource()
 * 19. contributeToResearch()
 * 20. unlockGlobalResource()
 * 21. setAnomalyParameters()
 * 22. triggerAnomaly()
 * 23. refuelQuarry()
 * 24. pauseQuarryProduction()
 * 25. resumeQuarryProduction()
 * 26. getQuarryProductionRate()
 */
contract QuantumQuarry {

    address public owner;
    address[] public admins;
    address public quantumFuelToken; // Address of an external ERC-20 used for fuel (simulated interaction)

    // --- State Structures ---

    struct ResourceType {
        string name;
        string symbol;
        uint256 totalSupply;
    }

    struct Location {
        uint256 baseRate; // Base production rate per quarry per unit time (e.g., per second)
        uint256 capacity; // Max resources a quarry can hold before harvest is needed
        uint256[] availableResourceIds; // Resource types producible at this location
        // Future: Slot count, special properties
    }

    struct Quarry {
        uint256 id;
        address owner;
        uint256 locationId;
        uint256 deploymentTime; // Timestamp of deployment
        uint256 lastHarvestTime; // Timestamp of last harvest
        uint256 lastProductionCalcTime; // Timestamp of last time production was calculated/state updated
        mapping(uint256 => uint256) efficiency; // Efficiency multiplier per resource type (e.g., 1000 = 1x)
        uint256 capacityModifier; // Additional capacity beyond location base
        mapping(uint256 => bool) unlockedResources; // Resources this specific quarry can produce
        uint256 fuelLevel; // Current fuel level
        bool paused; // Is production paused?
    }

    struct Recipe {
        uint256 id;
        uint256[] inputResourceIds;
        uint256[] inputAmounts;
        uint256 outputResourceId;
        uint256 outputAmount;
    }

     struct Anomaly {
        uint256 id;
        string name;
        uint256 startTime;
        uint256 duration; // Duration in seconds
        uint256 locationId; // -1 for global, specific ID for location-bound
        int256 rateModifier; // Modifier applied to production rate (can be positive or negative)
        bool active; // Is this anomaly currently active?
    }

    // --- State Variables ---

    uint256 private _nextQuarryId = 1;
    uint256 private _nextResourceTypeId = 0;
    uint256 private _nextRecipeId = 0;
    uint256 private _nextLocationId = 0;
    uint256 private _nextAnomalyId = 0;


    mapping(uint256 => Quarry) public quarries;
    mapping(address => uint256[]) public userQuarries; // User address => list of quarry IDs

    mapping(uint256 => ResourceType) public resourceTypes;
    mapping(address => mapping(uint256 => uint256)) public resourceBalances; // user address => resourceTypeId => balance

    mapping(uint256 => Location) public locations;
    mapping(uint256 => mapping(address => bool)) public locationAccess; // locationId => user address => has access

    mapping(uint256 => Recipe) public recipes;

    mapping(uint256 => uint256) public globalResearchProgress; // resourceTypeId => total research points contributed

    Anomaly public currentAnomaly; // Only one anomaly active at a time for simplicity

    // --- Events ---

    event AdminAdded(address indexed admin);
    event AdminRemoved(address indexed admin);
    event FuelTokenSet(address indexed fuelToken);
    event TokenTypeCreated(uint256 indexed resourceTypeId, string name, string symbol);
    event LocationParametersSet(uint256 indexed locationId, uint256 baseRate, uint256 capacity);
    event LocationAccessGranted(uint256 indexed locationId, address indexed user);
    event LocationAccessRevoked(uint256 indexed locationId, address indexed user);

    event QuarryDeployed(uint256 indexed quarryId, address indexed owner, uint256 indexed locationId);
    event QuarryTransferred(uint256 indexed quarryId, address indexed from, address indexed to);
    event QuarryScraped(uint256 indexed quarryId, address indexed owner);
    event QuarryProductionPaused(uint256 indexed quarryId);
    event QuarryProductionResumed(uint256 indexed quarryId);

    event ResourcesHarvested(uint256 indexed quarryId, address indexed owner, uint256 resourceTypeId, uint256 amount);
    event AllResourcesHarvested(address indexed owner, uint256 totalQuarriesHarvested);

    event QuarryEfficiencyUpgraded(uint256 indexed quarryId, uint256 indexed resourceTypeId, uint256 newEfficiency);
    event QuarryCapacityUpgraded(uint256 indexed quarryId, uint256 newCapacity);
    event QuarryResourceUnlocked(uint256 indexed quarryId, uint256 indexed resourceTypeId);
    event QuarryRefueled(uint256 indexed quarryId, uint256 amount);

    event CraftingRecipeAdded(uint256 indexed recipeId, uint256 outputResourceId, uint256 outputAmount);
    event ResourceCrafted(uint256 indexed recipeId, address indexed crafter, uint256 outputResourceId, uint256 outputAmount);

    event ResearchContributed(address indexed user, uint256 indexed resourceTypeId, uint256 amount);
    event GlobalResourceUnlocked(uint256 indexed resourceTypeId);

    event AnomalyParametersSet(uint256 indexed anomalyId, string name, uint256 startTime, uint256 duration);
    event AnomalyTriggered(uint256 indexed anomalyId, string name, uint256 startTime);

    // --- Modifiers ---

    modifier onlyOwner() {
        require(msg.sender == owner, "QQ: Only owner");
        _;
    }

    modifier onlyAdmin() {
        bool isAdmin = (msg.sender == owner);
        if (!isAdmin) {
            for (uint i = 0; i < admins.length; i++) {
                if (admins[i] == msg.sender) {
                    isAdmin = true;
                    break;
                }
            }
        }
        require(isAdmin, "QQ: Only admin");
        _;
    }

    modifier onlyQuarryOwner(uint256 _quarryId) {
        require(quarries[_quarryId].owner == msg.sender, "QQ: Not quarry owner");
        _;
    }

    // --- Constructor ---

    constructor(address _fuelToken) {
        owner = msg.sender;
        quantumFuelToken = _fuelToken;
    }

    // --- Admin Functions ---

    /**
     * @dev Adds an admin address.
     * @param _newAdmin The address to add as admin.
     */
    function addAdmin(address _newAdmin) public onlyOwner {
        for (uint i = 0; i < admins.length; i++) {
            require(admins[i] != _newAdmin, "QQ: Already an admin");
        }
        admins.push(_newAdmin);
        emit AdminAdded(_newAdmin);
    }

    /**
     * @dev Removes an admin address. Cannot remove the owner.
     * @param _adminToRemove The address to remove from admins.
     */
    function removeAdmin(address _adminToRemove) public onlyOwner {
        require(_adminToRemove != owner, "QQ: Cannot remove owner");
        for (uint i = 0; i < admins.length; i++) {
            if (admins[i] == _adminToRemove) {
                admins[i] = admins[admins.length - 1];
                admins.pop();
                emit AdminRemoved(_adminToRemove);
                return;
            }
        }
        revert("QQ: Not an admin");
    }

    /**
     * @dev Sets the address of the external Quantum Fuel token.
     * @param _fuelToken The address of the fuel token contract.
     */
    function setFuelTokenAddress(address _fuelToken) public onlyAdmin {
        quantumFuelToken = _fuelToken;
        emit FuelTokenSet(_fuelToken);
    }

    /**
     * @dev Creates a new type of Exotic Matter token.
     * @param _name The name of the resource type.
     * @param _symbol The symbol of the resource type.
     * @return The unique ID of the new resource type.
     */
    function createTokenType(string memory _name, string memory _symbol) public onlyAdmin returns (uint256) {
        uint256 resourceTypeId = _nextResourceTypeId++;
        resourceTypes[resourceTypeId] = ResourceType(_name, _symbol, 0);
        emit TokenTypeCreated(resourceTypeId, _name, _symbol);
        return resourceTypeId;
    }

    /**
     * @dev Sets or updates parameters for a location.
     * @param _locationId The ID of the location.
     * @param _baseRate The base production rate for quarries in this location (per second).
     * @param _capacity The base max resources a quarry in this location can hold.
     * @param _availableResourceIds The array of resource type IDs available at this location.
     */
    function setLocationParameters(uint256 _locationId, uint256 _baseRate, uint256 _capacity, uint256[] memory _availableResourceIds) public onlyAdmin {
        if (_locationId >= _nextLocationId) {
            _nextLocationId = _locationId + 1;
        }
        locations[_locationId] = Location(_baseRate, _capacity, _availableResourceIds);
        emit LocationParametersSet(_locationId, _baseRate, _capacity);
    }

    /**
     * @dev Grants or revokes a user's access to deploy quarries in a location.
     * @param _locationId The ID of the location.
     * @param _user The user address.
     * @param _hasAccess True to grant, false to revoke.
     */
    function grantLocationAccess(uint256 _locationId, address _user, bool _hasAccess) public onlyAdmin {
         require(_locationId < _nextLocationId, "QQ: Location does not exist");
        locationAccess[_locationId][_user] = _hasAccess;
        if (_hasAccess) {
            emit LocationAccessGranted(_locationId, _user);
        } else {
            emit LocationAccessRevoked(_locationId, _user);
        }
    }

    /**
     * @dev Adds a crafting recipe.
     * @param _inputResourceIds Array of input resource type IDs.
     * @param _inputAmounts Array of corresponding input amounts.
     * @param _outputResourceId The output resource type ID.
     * @param _outputAmount The output amount.
     * @return The ID of the newly added recipe.
     */
    function addCraftingRecipe(uint256[] memory _inputResourceIds, uint256[] memory _inputAmounts, uint256 _outputResourceId, uint256 _outputAmount) public onlyAdmin returns (uint256) {
        require(_inputResourceIds.length == _inputAmounts.length, "QQ: Input mismatch");
        require(_outputResourceId < _nextResourceTypeId, "QQ: Invalid output resource");
        require(_outputAmount > 0, "QQ: Output amount must be positive");

        uint256 recipeId = _nextRecipeId++;
        recipes[recipeId] = Recipe(recipeId, _inputResourceIds, _inputAmounts, _outputResourceId, _outputAmount);
        emit CraftingRecipeAdded(recipeId, _outputResourceId, _outputAmount);
        return recipeId;
    }

    /**
     * @dev Sets or updates parameters for an anomaly.
     * @param _anomalyId The ID of the anomaly.
     * @param _name The name of the anomaly.
     * @param _startTime The start timestamp (0 for immediate activation upon trigger).
     * @param _duration The duration in seconds (0 for indefinite).
     * @param _locationId The location ID (-1 for global).
     * @param _rateModifier The production rate modifier (positive for boost, negative for hindrance).
     * @return The ID of the anomaly.
     */
    function setAnomalyParameters(uint256 _anomalyId, string memory _name, uint256 _startTime, uint256 _duration, uint256 _locationId, int256 _rateModifier) public onlyAdmin returns (uint256) {
         if (_anomalyId >= _nextAnomalyId) {
            _nextAnomalyId = _anomalyId + 1;
        }
        // Anomaly struct stored temporarily, triggered by triggerAnomaly
        // Simplified: only one anomaly active at a time, overwrite currentAnomaly
        // A more complex version would manage a list of potential/active anomalies
        currentAnomaly = Anomaly(_anomalyId, _name, _startTime, _duration, _locationId, _rateModifier, false);
        emit AnomalyParametersSet(_anomalyId, _name, _startTime, _duration);
        return _anomalyId;
    }

     /**
     * @dev Activates a predefined anomaly. Overwrites any currently active anomaly.
     * @param _anomalyId The ID of the anomaly to trigger. (Actually triggers the anomaly currently stored in `currentAnomaly` if its ID matches - simplistic approach)
     */
    function triggerAnomaly(uint256 _anomalyId) public onlyAdmin {
        // In this simplified model, we just activate the 'currentAnomaly' state.
        // A real system would look up _anomalyId in a list/mapping.
        require(currentAnomaly.id == _anomalyId, "QQ: Anomaly parameters not set for this ID");
        currentAnomaly.active = true;
        currentAnomaly.startTime = block.timestamp; // Start now if not explicitly set future
        emit AnomalyTriggered(currentAnomaly.id, currentAnomaly.name, currentAnomaly.startTime);
    }

    /**
     * @dev Unlocks a resource type globally, making it producible in locations
     *      where it's listed as available. Typically called by Admin after
     *      sufficient global research contribution.
     * @param _resourceTypeId The ID of the resource type to unlock.
     */
    function unlockGlobalResource(uint256 _resourceTypeId) public onlyAdmin {
        require(_resourceTypeId < _nextResourceTypeId, "QQ: Invalid resource type");
        // In this simplistic version, the resource being in Location.availableResourceIds
        // is the main unlock condition. This function could, in a more complex game,
        // update location parameters or a global availability map.
        // For now, it simply signifies that "research paid off" via an event.
        emit GlobalResourceUnlocked(_resourceTypeId);
    }


    // --- User Functions ---

    /**
     * @dev Mints a new Quarry NFT-like item for the caller and assigns it to a location.
     * @param _locationId The ID of the location to deploy the quarry.
     * @return The ID of the newly deployed quarry.
     */
    function deployQuarry(uint256 _locationId) public returns (uint256) {
        require(_locationId < _nextLocationId, "QQ: Location does not exist");
        require(locationAccess[_locationId][msg.sender], "QQ: No access to this location");

        uint256 quarryId = _nextQuarryId++;
        Quarry storage newQuarry = quarries[quarryId];

        newQuarry.id = quarryId;
        newQuarry.owner = msg.sender;
        newQuarry.locationId = _locationId;
        newQuarry.deploymentTime = block.timestamp;
        newQuarry.lastHarvestTime = block.timestamp;
        newQuarry.lastProductionCalcTime = block.timestamp;
        newQuarry.capacityModifier = 0;
        newQuarry.fuelLevel = 0;
        newQuarry.paused = false;

        // Initialize efficiency for all potential resource types at 1x (1000)
         Location storage loc = locations[_locationId];
         for(uint i=0; i < loc.availableResourceIds.length; i++){
            newQuarry.efficiency[loc.availableResourceIds[i]] = 1000; // Start at 1x efficiency
         }


        userQuarries[msg.sender].push(quarryId);

        emit QuarryDeployed(quarryId, msg.sender, _locationId);
        return quarryId;
    }

    /**
     * @dev Transfers ownership of a Quarry to another address.
     * @param _to The address to transfer the quarry to.
     * @param _quarryId The ID of the quarry to transfer.
     */
    function transferQuarry(address _to, uint256 _quarryId) public onlyQuarryOwner(_quarryId) {
        require(_to != address(0), "QQ: Transfer to zero address");
        require(_to != msg.sender, "QQ: Cannot transfer to self");

        // Harvest any pending resources before transferring
        harvestQuarry(_quarryId);

        address from = msg.sender;
        Quarry storage quarry = quarries[_quarryId];

        // Remove from sender's list
        uint256[] storage senderQuarries = userQuarries[from];
        for (uint i = 0; i < senderQuarries.length; i++) {
            if (senderQuarries[i] == _quarryId) {
                senderQuarries[i] = senderQuarries[senderQuarries.length - 1];
                senderQuarries.pop();
                break;
            }
        }

        // Add to receiver's list
        userQuarries[_to].push(_quarryId);
        quarry.owner = _to;

        emit QuarryTransferred(_quarryId, from, _to);
    }

    /**
     * @dev Scrapes a Quarry, burning the NFT-like item and potentially returning
     *      some resources based on its state/upgrades (simplified).
     * @param _quarryId The ID of the quarry to scrape.
     */
    function scrapeQuarry(uint256 _quarryId) public onlyQuarryOwner(_quarryId) {
        // Harvest any pending resources before scraping
        harvestQuarry(_quarryId);

        address ownerAddress = msg.sender;
        Quarry storage quarry = quarries[_quarryId];

        // Simulate resource return based on upgrades (simple example: return 10% of fuel level as fuel token)
        // A real implementation would calculate based on spent upgrade resources etc.
        uint256 fuelRefund = quarry.fuelLevel / 10; // Example refund

        if (fuelRefund > 0 && quantumFuelToken != address(0)) {
             // Simulate external ERC20 transfer (requires actual ERC20 interface and allowance)
             // This is a placeholder. Real code needs:
             // IERC20 fuelTokenContract = IERC20(quantumFuelToken);
             // fuelTokenContract.transfer(ownerAddress, fuelRefund);
             // For this simulation, we'll just emit an event.
             emit ResourcesHarvested(_quarryId, ownerAddress, type(uint256).max, fuelRefund); // Use max ID for Fuel for this sim
        }

        // Remove from owner's list
         uint256[] storage ownerQuarries = userQuarries[ownerAddress];
        for (uint i = 0; i < ownerQuarries.length; i++) {
            if (ownerQuarries[i] == _quarryId) {
                ownerQuarries[i] = ownerQuarries[ownerQuarries.length - 1];
                ownerQuarries.pop();
                break;
            }
        }

        delete quarries[_quarryId]; // "Burn" the quarry state

        emit QuarryScraped(_quarryId, ownerAddress);
    }

    /**
     * @dev Calculates the currently accumulated resources for a specific quarry
     *      since the last harvest or production calculation. Does NOT harvest.
     * @param _quarryId The ID of the quarry.
     * @return A mapping of resource type ID to pending amount.
     */
    function calculatePendingResources(uint256 _quarryId) public view returns (mapping(uint256 => uint256) memory) {
        Quarry storage quarry = quarries[_quarryId];
        require(quarry.owner != address(0), "QQ: Quarry does not exist");

        // Helper function to avoid code duplication
        return _calculateProduction(quarry);
    }

    /**
     * @dev Internal helper to calculate production based on time passed.
     * @param quarry The quarry struct reference.
     * @return A mapping of resource type ID to accumulated amount.
     */
    function _calculateProduction(Quarry storage quarry) internal view returns (mapping(uint256 => uint256) memory) {
         mapping(uint256 => uint256) memory pendingResources;

         if (quarry.paused) {
             return pendingResources; // No production if paused
         }

         // Calculate time passed since last calculation/harvest, capped by anomaly duration if active
         uint256 timeElapsed = block.timestamp - quarry.lastProductionCalcTime;

         // Adjust timeElapsed based on anomaly end if applicable
         if (currentAnomaly.active && currentAnomaly.startTime > 0 && currentAnomaly.duration > 0) {
             uint256 anomalyEndTime = currentAnomaly.startTime + currentAnomaly.duration;
             if (block.timestamp > anomalyEndTime) {
                 // Anomaly ended, calculate production only up to anomaly end time
                 timeElapsed = anomalyEndTime - quarry.lastProductionCalcTime;
                 if (block.timestamp - timeElapsed > anomalyEndTime) {
                     // If current calc time is past anomaly end, reset timeElapsed to 0
                     timeElapsed = 0;
                 }
             }
         }


         if (timeElapsed == 0) {
             return pendingResources; // No time passed or already calculated
         }

         Location storage loc = locations[quarry.locationId];
         uint256 maxCapacity = loc.capacity + quarry.capacityModifier;


         for(uint i=0; i < loc.availableResourceIds.length; i++){
            uint256 resourceTypeId = loc.availableResourceIds[i];

            if(quarry.unlockedResources[resourceTypeId]) {
                 uint256 baseRate = loc.baseRate;
                 uint256 efficiency = quarry.efficiency[resourceTypeId]; // Defaults to 0 if not set, should be initialized to 1000
                 uint256 fuelEfficiencyMultiplier = (quarry.fuelLevel > 0) ? 1000 : 500; // Example: 50% efficiency without fuel

                 // Apply anomaly modifier if applicable
                 int256 totalRateModifier = 0;
                 if (currentAnomaly.active &&
                     (currentAnomaly.locationId == uint256(-1) || currentAnomaly.locationId == quarry.locationId)) {
                     totalRateModifier = currentAnomaly.rateModifier;
                 }

                 // Calculate current effective rate
                 // Rate = BaseRate * (Efficiency/1000) * (FuelMultiplier/1000)
                 // Then apply totalRateModifier (+/-)
                 uint256 effectiveRate = (baseRate * efficiency / 1000 * fuelEfficiencyMultiplier / 1000);

                 // Apply anomaly modifier safely (handle potential negative results)
                 if (totalRateModifier != 0) {
                     if (totalRateModifier > 0) {
                         effectiveRate += uint256(totalRateModifier);
                     } else {
                         uint256 decrease = uint256(-totalRateModifier);
                         effectiveRate = effectiveRate > decrease ? effectiveRate - decrease : 0;
                     }
                 }


                 uint256 produced = effectiveRate * timeElapsed; // Production in this time frame

                 // Clamp production by capacity - this is tricky with incremental updates.
                 // A better way is to store 'pending' and add to it, then cap on harvest.
                 // For simplicity here, we calculate total potential production and cap it.
                 // This isn't strictly correct for state updates over time but works for 'calculate pending'.
                 // A more accurate system would update state periodically or use integral calculation.
                 // Let's calculate total production *since last harvest/reset* and cap it.
                 uint256 totalPotentialProductionSinceHarvest = effectiveRate * (block.timestamp - quarry.lastHarvestTime);
                 pendingResources[resourceTypeId] = totalPotentialProductionSinceHarvest > maxCapacity ? maxCapacity : totalPotentialProductionSinceHarvest;
            }
         }
         return pendingResources;
    }


    /**
     * @dev Claims accumulated resources from a specific quarry.
     * @param _quarryId The ID of the quarry to harvest.
     */
    function harvestQuarry(uint256 _quarryId) public onlyQuarryOwner(_quarryId) {
        Quarry storage quarry = quarries[_quarryId];
        mapping(uint256 => uint256) memory pending = _calculateProduction(quarry);

        quarry.lastProductionCalcTime = block.timestamp; // Update calc time before harvest
        quarry.lastHarvestTime = block.timestamp; // Reset harvest time

        Location storage loc = locations[quarry.locationId];
        for(uint i=0; i < loc.availableResourceIds.length; i++){
           uint256 resourceTypeId = loc.availableResourceIds[i];
           uint256 amount = pending[resourceTypeId];

           if(amount > 0) {
                resourceBalances[msg.sender][resourceTypeId] += amount;
                resourceTypes[resourceTypeId].totalSupply += amount; // Update total supply for this type
                emit ResourcesHarvested(_quarryId, msg.sender, resourceTypeId, amount);
           }
        }

        // Decrease fuel level based on time elapsed since last calc (whether production occurred or not)
        uint256 timeElapsedForFuel = block.timestamp - quarry.lastProductionCalcTime; // Use time since last calc
        uint256 fuelConsumption = timeElapsedForFuel; // Example: 1 fuel per second
        if (quarry.fuelLevel >= fuelConsumption) {
            quarry.fuelLevel -= fuelConsumption;
        } else {
            quarry.fuelLevel = 0;
        }
    }

    /**
     * @dev Claims accumulated resources from all quarries owned by the caller.
     */
    function harvestAllQuarries() public {
        uint256[] storage userQuarryIds = userQuarries[msg.sender];
        uint256 harvestedCount = 0;
        for (uint i = 0; i < userQuarryIds.length; i++) {
            uint256 quarryId = userQuarryIds[i];
            // Ensure the quarry still exists and is owned by msg.sender (safety check, though userQuarries mapping implies ownership)
            if (quarries[quaryId].owner == msg.sender) {
                 harvestQuarry(quarryId); // This internally calculates and distributes
                 harvestedCount++;
            }
        }
         emit AllResourcesHarvested(msg.sender, harvestedCount);
    }


    /**
     * @dev Spends a resource type to increase a quarry's production efficiency
     *      for a specific resource type.
     * @param _quarryId The ID of the quarry.
     * @param _resourceTypeId The ID of the resource type whose efficiency is being upgraded.
     * @param _amount The amount of resource to spend for the upgrade.
     */
    function upgradeQuarryEfficiency(uint256 _quarryId, uint256 _resourceTypeId, uint256 _amount) public onlyQuarryOwner(_quarryId) {
        require(_resourceTypeId < _nextResourceTypeId, "QQ: Invalid resource type");
        require(_amount > 0, "QQ: Upgrade amount must be positive");
        require(resourceBalances[msg.sender][_resourceTypeId] >= _amount, "QQ: Insufficient resources");

        // Simulate resource burning (requires actual ERC20 burn or transferFrom)
        // For this simulation, just deduct from internal balance
        resourceBalances[msg.sender][_resourceTypeId] -= _amount;
        resourceTypes[_resourceTypeId].totalSupply -= _amount; // Update total supply

        // Example upgrade logic: Every 100 resource spent adds 10 efficiency points (1000 is 1x)
        // Efficiency cap could be added
        quarries[_quarryId].efficiency[_resourceTypeId] += (_amount / 100) * 10;

        emit QuarryEfficiencyUpgraded(_quarryId, _resourceTypeId, quarries[_quarryId].efficiency[_resourceTypeId]);
    }

    /**
     * @dev Spends a resource type to increase a quarry's maximum pending resource capacity.
     * @param _quarryId The ID of the quarry.
     * @param _resourceTypeId The ID of the resource type to spend for the upgrade.
     * @param _amount The amount of resource to spend.
     */
    function upgradeQuarryCapacity(uint256 _quarryId, uint256 _resourceTypeId, uint256 _amount) public onlyQuarryOwner(_quarryId) {
         require(_resourceTypeId < _nextResourceTypeId, "QQ: Invalid resource type");
        require(_amount > 0, "QQ: Upgrade amount must be positive");
        require(resourceBalances[msg.sender][_resourceTypeId] >= _amount, "QQ: Insufficient resources");

        // Simulate resource burning
        resourceBalances[msg.sender][_resourceTypeId] -= _amount;
        resourceTypes[_resourceTypeId].totalSupply -= _amount;

        // Example upgrade logic: Every 50 resource spent adds 500 capacity
        quarries[_quarryId].capacityModifier += (_amount / 50) * 500;

        emit QuarryCapacityUpgraded(_quarryId, quarries[_quarryId].capacityModifier);
    }

    /**
     * @dev Spends resources to enable a quarry to produce a specific resource type
     *      that is available at its location but not yet unlocked for this quarry.
     * @param _quarryId The ID of the quarry.
     * @param _resourceTypeId The ID of the resource type to unlock.
     */
    function unlockResourceAtQuarry(uint256 _quarryId, uint256 _resourceTypeId) public onlyQuarryOwner(_quarryId) {
        require(_resourceTypeId < _nextResourceTypeId, "QQ: Invalid resource type");
        require(!quarries[_quarryId].unlockedResources[_resourceTypeId], "QQ: Resource already unlocked");

        Location storage loc = locations[quarries[_quaryId].locationId];
        bool availableAtLocation = false;
        for(uint i=0; i < loc.availableResourceIds.length; i++){
            if(loc.availableResourceIds[i] == _resourceTypeId) {
                availableAtLocation = true;
                break;
            }
        }
        require(availableAtLocation, "QQ: Resource not available at this location");

        // Example unlock cost: Requires 1000 units of the resource itself
        uint256 unlockCost = 1000; // Example cost
         require(resourceBalances[msg.sender][_resourceTypeId] >= unlockCost, "QQ: Insufficient resources to unlock");

        // Simulate resource burning
        resourceBalances[msg.sender][_resourceTypeId] -= unlockCost;
        resourceTypes[_resourceTypeId].totalSupply -= unlockCost;

        quarries[_quarryId].unlockedResources[_resourceTypeId] = true;

        emit QuarryResourceUnlocked(_quarryId, _resourceTypeId);
    }

    /**
     * @dev Executes a crafting recipe, consuming input resources and minting output resources.
     * @param _recipeId The ID of the recipe to execute.
     */
    function craftResource(uint256 _recipeId) public {
        require(_recipeId < _nextRecipeId, "QQ: Invalid recipe ID");
        Recipe storage recipe = recipes[_recipeId];

        // Check input resources
        for (uint i = 0; i < recipe.inputResourceIds.length; i++) {
            require(resourceBalances[msg.sender][recipe.inputResourceIds[i]] >= recipe.inputAmounts[i], "QQ: Insufficient input resources");
        }

        // Consume input resources
        for (uint i = 0; i < recipe.inputResourceIds.length; i++) {
            resourceBalances[msg.sender][recipe.inputResourceIds[i]] -= recipe.inputAmounts[i];
             resourceTypes[recipe.inputResourceIds[i]].totalSupply -= recipe.inputAmounts[i]; // Update total supply
        }

        // Mint output resources
        resourceBalances[msg.sender][recipe.outputResourceId] += recipe.outputAmount;
        resourceTypes[recipe.outputResourceId].totalSupply += recipe.outputAmount; // Update total supply

        emit ResourceCrafted(_recipeId, msg.sender, recipe.outputResourceId, recipe.outputAmount);
    }

    /**
     * @dev Contributes resources to the global research pool for a specific resource type.
     *      Higher contributions by the community might lead admins to unlock resources.
     * @param _resourceTypeId The ID of the resource type to research.
     * @param _amount The amount of resource to contribute.
     */
    function contributeToResearch(uint256 _resourceTypeId, uint256 _amount) public {
        require(_resourceTypeId < _nextResourceTypeId, "QQ: Invalid resource type");
        require(_amount > 0, "QQ: Contribution amount must be positive");
        require(resourceBalances[msg.sender][_resourceTypeId] >= _amount, "QQ: Insufficient resources");

        // Simulate resource burning for research
        resourceBalances[msg.sender][_resourceTypeId] -= _amount;
        resourceTypes[_resourceTypeId].totalSupply -= _amount; // Update total supply

        globalResearchProgress[_resourceTypeId] += _amount;

        emit ResearchContributed(msg.sender, _resourceTypeId, _amount);
    }

    /**
     * @dev Spends external Quantum Fuel tokens to increase a quarry's internal fuel level.
     *      (Simulates interaction with an external ERC-20).
     * @param _quarryId The ID of the quarry to refuel.
     * @param _amount The amount of Quantum Fuel tokens to spend.
     */
    function refuelQuarry(uint256 _quarryId, uint256 _amount) public onlyQuarryOwner(_quarryId) {
        require(quantumFuelToken != address(0), "QQ: Fuel token address not set");
        require(_amount > 0, "QQ: Fuel amount must be positive");

        // --- SIMULATED EXTERNAL TOKEN TRANSFER ---
        // In a real contract, you would use IERC20 and call transferFrom here.
        // require(IERC20(quantumFuelToken).transferFrom(msg.sender, address(this), _amount), "QQ: Fuel transfer failed");
        // For this example, we assume the transfer succeeded and just update the internal state.
        // The user *must* have approved this contract to spend _amount of FuelToken *before* calling this function.
        // This is a key part of external token interaction.
        // --- END SIMULATION ---

        // Update quarry fuel level (simplified: 1 fuel token = 1 fuel level unit)
        quarries[_quarryId].fuelLevel += _amount;

        emit QuarryRefueled(_quarryId, _amount);
    }

    /**
     * @dev Pauses the resource production of a specific quarry.
     * @param _quarryId The ID of the quarry to pause.
     */
    function pauseQuarryProduction(uint256 _quarryId) public onlyQuarryOwner(_quarryId) {
        Quarry storage quarry = quarries[_quarryId];
        require(!quarry.paused, "QQ: Quarry already paused");

        // Calculate and bank pending resources before pausing
        harvestQuarry(_quarryId); // Ensures resources are claimed up to the pause moment

        quarry.paused = true;
        emit QuarryProductionPaused(_quarryId);
    }

    /**
     * @dev Resumes the resource production of a paused quarry.
     * @param _quarryId The ID of the quarry to resume.
     */
    function resumeQuarryProduction(uint256 _quarryId) public onlyQuarryOwner(_quarryId) {
         Quarry storage quarry = quarries[_quarryId];
        require(quarry.paused, "QQ: Quarry not paused");

        quarry.paused = false;
        // Reset last production calc time to now to start calculating from resume time
        quarry.lastProductionCalcTime = block.timestamp;
        quarry.lastHarvestTime = block.timestamp; // Also reset harvest time to prevent large pending accumulation on next harvest

        emit QuarryProductionResumed(_quarryId);
    }


    // --- Read Functions ---

    /**
     * @dev Gets the detailed state of a specific quarry.
     * @param _quarryId The ID of the quarry.
     * @return Quarry struct details.
     */
    function getQuarryDetails(uint256 _quarryId) public view returns (
        uint256 id,
        address owner,
        uint256 locationId,
        uint256 deploymentTime,
        uint256 lastHarvestTime,
        uint256 lastProductionCalcTime,
        mapping(uint256 => uint256) memory efficiency,
        uint256 capacityModifier,
        mapping(uint256 => bool) memory unlockedResources,
        uint256 fuelLevel,
        bool paused
    ) {
         Quarry storage quarry = quarries[_quarryId];
         require(quarry.owner != address(0), "QQ: Quarry does not exist"); // Check if quarry exists

         // Copy mapping data to memory for returning
         Location storage loc = locations[quarry.locationId];
         mapping(uint256 => uint256) memory eff;
         mapping(uint256 => bool) memory unlocked;

         for(uint i=0; i < loc.availableResourceIds.length; i++){
             uint256 resId = loc.availableResourceIds[i];
             eff[resId] = quarry.efficiency[resId];
             unlocked[resId] = quarry.unlockedResources[resId];
         }


         return (
             quarry.id,
             quarry.owner,
             quarry.locationId,
             quarry.deploymentTime,
             quarry.lastHarvestTime,
             quarry.lastProductionCalcTime,
             eff,
             quarry.capacityModifier,
             unlocked,
             quarry.fuelLevel,
             quarry.paused
         );
    }

    /**
     * @dev Lists all quarry IDs owned by a user.
     * @param _user The address of the user.
     * @return An array of quarry IDs.
     */
    function getUserQuarries(address _user) public view returns (uint256[] memory) {
        return userQuarries[_user];
    }

    /**
     * @dev Gets the current balance of a specific resource type for a user.
     * @param _user The user address.
     * @param _resourceTypeId The ID of the resource type.
     * @return The balance amount.
     */
    function getResourceBalance(address _user, uint256 _resourceTypeId) public view returns (uint256) {
        require(_resourceTypeId < _nextResourceTypeId, "QQ: Invalid resource type");
        return resourceBalances[_user][_resourceTypeId];
    }

     /**
     * @dev Gets the total supply of a specific resource type.
     * @param _resourceTypeId The ID of the resource type.
     * @return The total supply amount.
     */
    function getTotalSupply(uint256 _resourceTypeId) public view returns (uint256) {
         require(_resourceTypeId < _nextResourceTypeId, "QQ: Invalid resource type");
        return resourceTypes[_resourceTypeId].totalSupply;
    }

    /**
     * @dev Gets the details of a specific resource type.
     * @param _resourceTypeId The ID of the resource type.
     * @return ResourceType details (name, symbol, total supply).
     */
    function getResourceTypeDetails(uint256 _resourceTypeId) public view returns (string memory name, string memory symbol, uint256 totalSupply) {
         require(_resourceTypeId < _nextResourceTypeId, "QQ: Invalid resource type");
         ResourceType storage resType = resourceTypes[_resourceTypeId];
         return (resType.name, resType.symbol, resType.totalSupply);
    }


    /**
     * @dev Gets the details of a specific crafting recipe.
     * @param _recipeId The ID of the recipe.
     * @return Recipe details (inputs, output).
     */
    function getRecipeDetails(uint256 _recipeId) public view returns (uint256[] memory inputResourceIds, uint256[] memory inputAmounts, uint256 outputResourceId, uint256 outputAmount) {
        require(_recipeId < _nextRecipeId, "QQ: Invalid recipe ID");
        Recipe storage recipe = recipes[_recipeId];
        return (recipe.inputResourceIds, recipe.inputAmounts, recipe.outputResourceId, recipe.outputAmount);
    }

    /**
     * @dev Gets the details of a location.
     * @param _locationId The ID of the location.
     * @return Location details (base rate, capacity, available resources).
     */
    function getLocationDetails(uint256 _locationId) public view returns (uint256 baseRate, uint256 capacity, uint256[] memory availableResourceIds) {
         require(_locationId < _nextLocationId, "QQ: Location does not exist");
        Location storage loc = locations[_locationId];
        return (loc.baseRate, loc.capacity, loc.availableResourceIds);
    }

    /**
     * @dev Checks if a user has access to a specific location.
     * @param _locationId The ID of the location.
     * @param _user The user address.
     * @return True if the user has access, false otherwise.
     */
    function hasLocationAccess(uint256 _locationId, address _user) public view returns (bool) {
        require(_locationId < _nextLocationId, "QQ: Location does not exist");
        return locationAccess[_locationId][_user];
    }

    /**
     * @dev Gets the current effective production rate for a specific resource type on a quarry.
     *      Considers base rate, efficiency, fuel, and active anomaly.
     * @param _quarryId The ID of the quarry.
     * @param _resourceTypeId The ID of the resource type.
     * @return The calculated production rate per second.
     */
    function getQuarryProductionRate(uint256 _quarryId, uint256 _resourceTypeId) public view returns (uint256) {
        Quarry storage quarry = quarries[_quarryId];
        require(quarry.owner != address(0), "QQ: Quarry does not exist");
        require(_resourceTypeId < _nextResourceTypeId, "QQ: Invalid resource type");
        require(quarry.unlockedResources[_resourceTypeId], "QQ: Resource not unlocked on quarry");

        if (quarry.paused) {
             return 0; // No production if paused
        }

        Location storage loc = locations[quarry.locationId];
        bool availableAtLocation = false;
         for(uint i=0; i < loc.availableResourceIds.length; i++){
            if(loc.availableResourceIds[i] == _resourceTypeId) {
                availableAtLocation = true;
                break;
            }
        }
        require(availableAtLocation, "QQ: Resource not available at this location");


        uint256 baseRate = loc.baseRate;
        uint256 efficiency = quarry.efficiency[_resourceTypeId];
        uint256 fuelEfficiencyMultiplier = (quarry.fuelLevel > 0) ? 1000 : 500; // Example: 50% efficiency without fuel

        int256 totalRateModifier = 0;
        // Check if anomaly is active and applies to this quarry's location or is global
        if (currentAnomaly.active &&
            block.timestamp >= currentAnomaly.startTime &&
            (currentAnomaly.duration == 0 || block.timestamp < currentAnomaly.startTime + currentAnomaly.duration) &&
            (currentAnomaly.locationId == uint256(-1) || currentAnomaly.locationId == quarry.locationId)) {
             totalRateModifier = currentAnomaly.rateModifier;
         }


        uint256 effectiveRate = (baseRate * efficiency / 1000 * fuelEfficiencyMultiplier / 1000);

         if (totalRateModifier > 0) {
             effectiveRate += uint256(totalRateModifier);
         } else {
             uint256 decrease = uint256(-totalRateModifier);
             effectiveRate = effectiveRate > decrease ? effectiveRate - decrease : 0;
         }

         return effectiveRate;
    }

    /**
     * @dev Gets the current anomaly details if active.
     * @return Anomaly struct details (id, name, start time, duration, location, rate modifier, active status).
     */
    function getAnomalyDetails() public view returns (uint256 id, string memory name, uint256 startTime, uint256 duration, uint256 locationId, int256 rateModifier, bool active) {
        // Check if anomaly is currently active based on start time and duration
        bool isActive = currentAnomaly.active &&
                        block.timestamp >= currentAnomaly.startTime &&
                        (currentAnomaly.duration == 0 || block.timestamp < currentAnomaly.startTime + currentAnomaly.duration);

        return (
            currentAnomaly.id,
            currentAnomaly.name,
            currentAnomaly.startTime,
            currentAnomaly.duration,
            currentAnomaly.locationId,
            currentAnomaly.rateModifier,
            isActive
        );
    }

     /**
     * @dev Gets the current global research progress for a resource type.
     * @param _resourceTypeId The ID of the resource type.
     * @return The total research points contributed.
     */
    function getGlobalResearchProgress(uint256 _resourceTypeId) public view returns (uint256) {
        require(_resourceTypeId < _nextResourceTypeId, "QQ: Invalid resource type");
        return globalResearchProgress[_resourceTypeId];
    }

     /**
     * @dev Gets the next available Quarry ID (useful for frontends anticipating).
     */
    function getNextQuarryId() public view returns (uint256) {
        return _nextQuarryId;
    }
}
```