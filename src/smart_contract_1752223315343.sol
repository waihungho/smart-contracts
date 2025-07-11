Okay, let's create a smart contract that represents a dynamic NFT ecosystem where NFTs (called "Realms") can evolve, generate resources, and interact with crafting/upgrading mechanics using an internal resource token ("Essence"). This incorporates concepts like dynamic NFTs, internal resource management, crafting/upgrading systems, and time-based mechanics within a single contract.

It will not duplicate standard OpenZeppelin implementations directly for the core game logic, though it will inherit standard interfaces like ERC721 and Ownable.

**Outline and Function Summary:**

**Contract Name:** `NFTRealm`

**Description:**
`NFTRealm` is a smart contract that manages unique Non-Fungible Tokens (NFTs) called "Realms". Realms are dynamic assets that can evolve over time and through player interaction. The contract also manages an internal, non-transferable resource token called "Essence", which is crucial for crafting upgrades and interacting with Realms. Owners can harvest Essence from their Realms and use it to craft "Modules" or upgrade their Realms. Modules can be attached to Realms to boost their attributes, making Realms dynamic and strategic assets.

**Key Concepts:**
1.  **Realms:** ERC721 NFTs with dynamic attributes (Level, XP, Power, Module Slots, Attached Modules).
2.  **Essence:** An internal resource token, managed by the contract, used for crafting and upgrades. User balances are tracked. *Note: This isn't a separate ERC20 token, but an internal balance system.*
3.  **Modules:** Craftable items (represented by data structures within the contract, identified by unique IDs) that can be attached to Realms to provide bonuses and change attributes. Each module instance is unique and "owned" by the user who crafted it.
4.  **Dynamic Attributes:** Realm attributes like Power and available Module Slots change based on Level and attached Modules.
5.  **Time-Based Mechanics:** Realms passively accumulate harvestable Essence and Experience Points (XP) over time.

**Function Summary (25+ Functions):**

*   **NFT Core (ERC721 Standard Implementation):**
    1.  `constructor()`: Initializes the contract, sets name/symbol, and designates the initial owner.
    2.  `approve()`: Grants approval for a specific token ID.
    3.  `getApproved()`: Gets the approved address for a single token ID.
    4.  `setApprovalForAll()`: Sets approval for an operator address for all tokens.
    5.  `isApprovedForAll()`: Queries if an address is an authorized operator for another address.
    6.  `transferFrom()`: Transfers ownership of a token.
    7.  `safeTransferFrom()`: Safer transfer function.
    8.  `ownerOf()`: Returns the owner of a specific token ID.
    9.  `balanceOf()`: Returns the number of tokens owned by an address.
    10. `supportsInterface()`: Standard ERC165 interface check.

*   **NFTRealm Specific:**
    11. `mintRealm(address to)`: Mints a new Realm NFT to a specific address with base attributes.
    12. `burnRealm(uint256 tokenId)`: Burns (destroys) a Realm NFT. Requires owner or approved.
    13. `tokenURI(uint256 tokenId)`: Generates dynamic metadata URI for a Realm based on its current attributes.
    14. `getRealmAttributes(uint256 tokenId)`: Returns the current attributes of a specific Realm.
    15. `calculateRealmPower(uint256 tokenId)`: Calculates the effective power of a Realm including bonuses from attached modules. (View Function)
    16. `getRealmAttachedModules(uint256 tokenId)`: Returns the list of Module instance IDs attached to a Realm. (View Function)

*   **Essence Resource Management:**
    17. `getEssenceBalance(address account)`: Returns the Essence balance of an account. (View Function)
    18. `transferEssence(address recipient, uint256 amount)`: Transfers Essence from the caller's balance to another account.
    19. `mintEssenceToUser(address recipient, uint256 amount)`: (Admin/System) Mints new Essence and adds it to a user's balance.
    20. `burnEssence(uint256 amount)`: Burns (destroys) Essence from the caller's balance.

*   **Realm Interaction (Essence & Time-Based):**
    21. `harvestEssenceFromRealm(uint256 tokenId)`: Calculates accumulated Essence and XP for a Realm based on time passed, adds to user's Essence balance and Realm's XP, and updates harvest time.
    22. `calculateHarvestableEssence(uint256 tokenId)`: Calculates how much Essence has accumulated since the last harvest. (View Function)
    23. `calculateRealmAccumulatedXP(uint256 tokenId)`: Calculates how much XP has accumulated since the last harvest. (View Function)

*   **Crafting & Modules:**
    24. `craftModule(uint256 moduleTypeId)`: Crafts a new Module instance of a specific type, deducting Essence and assigning ownership of the instance to the caller.
    25. `upgradeModule(uint256 moduleId)`: Upgrades a specific Module instance's level, costing Essence.
    26. `getModuleAttributes(uint256 moduleId)`: Returns the attributes of a specific crafted Module instance. (View Function)
    27. `getModuleTypeBaseAttributes(uint256 moduleTypeId)`: Returns the base attributes for a specific Module Type. (View Function)

*   **Realm & Module Attachment:**
    28. `attachModuleToRealm(uint256 realmId, uint256 moduleId)`: Attaches a crafted Module instance owned by the caller to one of their Realms, occupying a module slot.
    29. `detachModuleFromRealm(uint256 realmId, uint256 moduleId)`: Detaches a Module instance from a Realm.

*   **Upgrading Realms:**
    30. `upgradeRealmLevel(uint256 tokenId)`: Upgrades a Realm's level, costing Essence and potentially requiring certain XP thresholds.

*   **Admin & Configuration (Requires Owner Role):**
    31. `setBaseURI(string newURI)`: Sets the base URI for token metadata.
    32. `setEssenceHarvestRate(uint256 rate)`: Sets the Essence per hour rate for Realms.
    33. `setXPRate(uint256 rate)`: Sets the XP per hour rate for Realms.
    34. `setModuleCraftingCost(uint256 moduleTypeId, uint256 cost)`: Sets the Essence cost to craft a specific Module Type.
    35. `setModuleUpgradeCost(uint256 moduleTypeId, uint256 costPerLevel)`: Sets the base Essence cost per level to upgrade a Module Type.
    36. `setRealmUpgradeCost(uint256 level, uint256 cost)`: Sets the Essence cost to upgrade a Realm to a specific level.
    37. `setModuleTypeAttributes(uint256 moduleTypeId, uint256[] attributeValues)`: Configures the base attributes for a Module Type. (Example: `[powerBonus, harvestBonus]`)
    38. `setPause(bool paused)`: Pauses or unpauses core contract interactions.
    39. `transferAdmin(address newAdmin)`: Transfers the contract admin/owner role.

**Advanced/Creative Concepts Implemented:**
*   **Dynamic NFTs:** Realm attributes change based on actions (harvesting, upgrading, attaching modules). Metadata `tokenURI` must reflect this dynamic state.
*   **Internal Resource Economy:** Essence is managed within the contract, creating a closed loop for crafting and upgrades.
*   **Layered Upgrades:** Realms can be upgraded, *and* Modules can be upgraded, adding complexity to development strategy.
*   **Component-Based NFTs:** Realms gain attributes from attached Modules, making the combination of assets strategic.
*   **Time-Based Passive Accumulation:** Users are rewarded for holding Realms over time with harvestable resources and XP.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol"; // Useful for getUserRealms
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

// Outline and Function Summary provided above the code block.

contract NFTRealm is ERC721Enumerable, Ownable, Pausable {
    using Counters for Counters.Counter;
    using Strings for uint256;

    // --- Data Structures ---

    struct RealmAttributes {
        uint256 level;
        uint256 xp;
        uint256 power; // Base power + module bonuses
        uint256 lastHarvestTime; // Timestamp for Essence and XP accumulation
        uint256 moduleSlots; // How many modules can be attached
        uint256[] attachedModules; // List of Module instance IDs attached
    }

    // Represents a specific crafted Module instance
    struct Module {
        uint256 id; // Unique ID for this instance
        uint256 moduleTypeId; // Reference to the base type config
        uint256 level;
        address owner; // Who crafted/owns this module instance
        bool isAttached; // Is it currently attached to a Realm?
        uint256 attachedRealmId; // The Realm it's attached to (0 if not attached)
    }

    // Configuration for a Module Type
    struct ModuleTypeConfig {
        uint256 craftingCost;
        uint256 upgradeCostPerLevel;
        uint256[] baseAttributes; // Example: [powerBonus, harvestBonusMultiplier]
    }

    // --- State Variables ---

    // NFT Realm data
    mapping(uint256 => RealmAttributes) private _realmAttributes;
    Counters.Counter private _realmIds;

    // Essence token data (internal balance)
    mapping(address => uint256) private _essenceBalances;

    // Module instance data
    mapping(uint256 => Module) private _modules;
    Counters.Counter private _moduleIds;

    // Module Type configuration
    mapping(uint256 => ModuleTypeConfig) private _moduleTypeConfigs;
    uint256[] public supportedModuleTypes; // List of available module types

    // Configuration parameters
    string private _baseTokenURI;
    uint256 private _essenceHarvestRatePerHour = 10; // Essence per hour per Realm
    uint256 private _xpRatePerHour = 5; // XP per hour per Realm
    mapping(uint256 => uint256) private _realmUpgradeCosts; // Cost to reach a specific level

    // --- Events ---

    event RealmMinted(address indexed owner, uint256 indexed tokenId);
    event RealmBurned(address indexed owner, uint256 indexed tokenId);
    event EssenceTransferred(address indexed from, address indexed to, uint256 amount);
    event EssenceMinted(address indexed recipient, uint256 amount);
    event EssenceBurned(address indexed burner, uint256 amount);
    event EssenceHarvested(uint256 indexed tokenId, address indexed owner, uint256 amount, uint256 xpGained);
    event ModuleCrafted(uint256 indexed moduleId, address indexed owner, uint256 moduleTypeId);
    event ModuleUpgraded(uint256 indexed moduleId, uint256 newLevel);
    event RealmUpgraded(uint256 indexed tokenId, uint256 newLevel);
    event ModuleAttached(uint256 indexed realmId, uint256 indexed moduleId);
    event ModuleDetached(uint256 indexed realmId, uint256 indexed moduleId);
    event BaseURIUpdated(string newURI);
    event EssenceHarvestRateUpdated(uint256 newRate);
    event XPRateUpdated(uint256 newRate);
    event ModuleTypeConfigUpdated(uint256 indexed moduleTypeId);
    event RealmUpgradeCostUpdated(uint256 indexed level, uint256 cost);
    event AdminTransferred(address indexed previousAdmin, address indexed newAdmin);

    // --- Modifiers ---

    modifier onlyRealmOwner(uint256 tokenId) {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "NFTRealm: Caller is not realm owner or approved");
        _;
    }

    modifier onlyModuleOwner(uint256 moduleId) {
        require(_modules[moduleId].owner == _msgSender(), "NFTRealm: Caller is not module owner");
        _;
    }

    modifier realmExists(uint256 tokenId) {
        require(_exists(tokenId), "NFTRealm: Realm does not exist");
        _;
    }

    modifier moduleExists(uint256 moduleId) {
        require(_modules[moduleId].id != 0, "NFTRealm: Module does not exist");
        _;
    }

    modifier hasEnoughEssence(uint256 amount) {
        require(_essenceBalances[_msgSender()] >= amount, "NFTRealm: Not enough essence");
        _;
    }

    // --- Constructor ---

    constructor() ERC721("NFTRealm", "RLM") Ownable(_msgSender()) Pausable() {
        // Initial setup can be done here or via admin functions post-deployment
        // e.g., setting initial harvest rate, module types, etc.
    }

    // --- Standard ERC721 Overrides (Required for ERC721Enumerable) ---

    function supportsInterface(bytes4 interfaceId) public view override(ERC721Enumerable, ERC721) returns (bool) {
        return interfaceId == type(ERC721Enumerable).interfaceId || super.supportsInterface(interfaceId);
    }

    function tokenURI(uint256 tokenId) public view override(ERC721, ERC721Enumerable) realmExists(tokenId) returns (string memory) {
        require(_baseTokenURI.length > 0, "NFTRealm: Base URI not set");
        string memory realmIdStr = tokenId.toString();

        // In a real application, this would likely call an external API or
        // another contract to generate the full, dynamic JSON metadata based on
        // getRealmAttributes(tokenId) and getRealmAttachedModules(tokenId).
        // For this example, we'll just return a placeholder URI.
        return string(abi.encodePacked(_baseTokenURI, realmIdStr, "/metadata"));
    }

    // --- NFTRealm Specific Functions ---

    /// @notice Mints a new Realm NFT to a specific address.
    /// @param to The address to mint the Realm to.
    function mintRealm(address to) public onlyOwner whenNotPaused returns (uint256) {
        _realmIds.increment();
        uint256 newItemId = _realmIds.current();

        _safeMint(to, newItemId);

        // Assign base attributes to the new Realm
        _realmAttributes[newItemId] = RealmAttributes({
            level: 1,
            xp: 0,
            power: 100, // Base power
            lastHarvestTime: block.timestamp,
            moduleSlots: 1, // Initial slot
            attachedModules: new uint256[](0)
        });

        emit RealmMinted(to, newItemId);
        return newItemId;
    }

    /// @notice Burns (destroys) a Realm NFT.
    /// @param tokenId The ID of the Realm to burn.
    function burnRealm(uint256 tokenId) public onlyRealmOwner(tokenId) whenNotPaused realmExists(tokenId) {
        address owner = ownerOf(tokenId);

        // Detach any attached modules before burning the Realm
        RealmAttributes storage realm = _realmAttributes[tokenId];
        uint256[] memory attachedMods = realm.attachedModules;
        for (uint256 i = 0; i < attachedMods.length; i++) {
            uint256 moduleId = attachedMods[i];
            Module storage module = _modules[moduleId];
            module.isAttached = false;
            module.attachedRealmId = 0;
        }
        delete realm.attachedModules;

        // Note: This does NOT decrement _realmIds counter. Token IDs are permanently gone.
        _burn(tokenId);
        delete _realmAttributes[tokenId]; // Clean up attributes

        emit RealmBurned(owner, tokenId);
    }

    /// @notice Gets the current attributes of a specific Realm.
    /// @param tokenId The ID of the Realm.
    /// @return The RealmAttributes struct.
    function getRealmAttributes(uint256 tokenId) public view realmExists(tokenId) returns (RealmAttributes memory) {
        return _realmAttributes[tokenId];
    }

    /// @notice Calculates the effective power of a Realm including base power and module bonuses.
    /// @param tokenId The ID of the Realm.
    /// @return The calculated power.
    function calculateRealmPower(uint256 tokenId) public view realmExists(tokenId) returns (uint256) {
        RealmAttributes storage realm = _realmAttributes[tokenId];
        uint256 totalPower = realm.power; // Start with base power

        for (uint256 i = 0; i < realm.attachedModules.length; i++) {
            uint256 moduleId = realm.attachedModules[i];
            Module storage module = _modules[moduleId];
            ModuleTypeConfig storage typeConfig = _moduleTypeConfigs[module.moduleTypeId];

            // Assume baseAttributes[0] is powerBonus
            if (typeConfig.baseAttributes.length > 0) {
                 // Simple example: Bonus scales with module level
                 totalPower += typeConfig.baseAttributes[0] * module.level;
            }
            // Add more attribute calculations here based on module type configuration
        }
        return totalPower;
    }

    /// @notice Gets the list of Module instance IDs currently attached to a Realm.
    /// @param tokenId The ID of the Realm.
    /// @return An array of module instance IDs.
    function getRealmAttachedModules(uint256 tokenId) public view realmExists(tokenId) returns (uint256[] memory) {
        return _realmAttributes[tokenId].attachedModules;
    }

    // --- Essence Resource Management ---

    /// @notice Gets the Essence balance of an account.
    /// @param account The address to check.
    /// @return The Essence balance.
    function getEssenceBalance(address account) public view returns (uint256) {
        return _essenceBalances[account];
    }

    /// @notice Transfers Essence from the caller's balance to another account.
    /// @param recipient The address to transfer Essence to.
    /// @param amount The amount of Essence to transfer.
    function transferEssence(address recipient, uint256 amount) public whenNotPaused hasEnoughEssence(amount) {
        require(recipient != address(0), "NFTRealm: transfer to the zero address");

        _essenceBalances[_msgSender()] -= amount;
        _essenceBalances[recipient] += amount;

        emit EssenceTransferred(_msgSender(), recipient, amount);
    }

    /// @notice Mints new Essence and adds it to a user's balance (Admin/System function).
    /// @param recipient The address to mint Essence for.
    /// @param amount The amount of Essence to mint.
    function mintEssenceToUser(address recipient, uint256 amount) public onlyOwner whenNotPaused {
        require(recipient != address(0), "NFTRealm: mint to the zero address");

        _essenceBalances[recipient] += amount;

        emit EssenceMinted(recipient, amount);
    }

    /// @notice Burns (destroys) Essence from the caller's balance.
    /// @param amount The amount of Essence to burn.
    function burnEssence(uint256 amount) public whenNotPaused hasEnoughEssence(amount) {
        _essenceBalances[_msgSender()] -= amount;

        emit EssenceBurned(_msgSender(), amount);
    }

    // --- Realm Interaction (Essence & Time-Based) ---

    /// @notice Calculates accumulated Essence for a Realm based on time passed.
    /// @param tokenId The ID of the Realm.
    /// @return The amount of harvestable Essence.
    function calculateHarvestableEssence(uint256 tokenId) public view realmExists(tokenId) returns (uint256) {
        RealmAttributes storage realm = _realmAttributes[tokenId];
        uint256 timeElapsed = block.timestamp - realm.lastHarvestTime;
        uint256 effectiveHarvestRate = _essenceHarvestRatePerHour; // Start with base rate

        // Example: Apply module bonuses to harvest rate
        for (uint256 i = 0; i < realm.attachedModules.length; i++) {
            uint256 moduleId = realm.attachedModules[i];
            Module storage module = _modules[moduleId];
            ModuleTypeConfig storage typeConfig = _moduleTypeConfigs[module.moduleTypeId];

            // Assume baseAttributes[1] is harvestBonusMultiplier (e.g., 100 for 1x, 150 for 1.5x)
             if (typeConfig.baseAttributes.length > 1) {
                 effectiveHarvestRate = (effectiveHarvestRate * typeConfig.baseAttributes[1] * module.level) / 100; // Simple scaling example
             }
        }


        // Convert per hour rate to per second
        uint256 harvestable = (timeElapsed * effectiveHarvestRate) / 3600; // 3600 seconds in an hour
        return harvestable;
    }

     /// @notice Calculates accumulated XP for a Realm based on time passed.
    /// @param tokenId The ID of the Realm.
    /// @return The amount of accumulated XP.
    function calculateRealmAccumulatedXP(uint256 tokenId) public view realmExists(tokenId) returns (uint256) {
        RealmAttributes storage realm = _realmAttributes[tokenId];
        uint256 timeElapsed = block.timestamp - realm.lastHarvestTime;
        uint256 xp = (timeElapsed * _xpRatePerHour) / 3600; // XP per second
        return xp;
    }


    /// @notice Harvests accumulated Essence and grants XP from a Realm.
    /// @param tokenId The ID of the Realm to harvest from.
    function harvestEssenceFromRealm(uint256 tokenId) public onlyRealmOwner(tokenId) whenNotPaused realmExists(tokenId) {
        RealmAttributes storage realm = _realmAttributes[tokenId];

        uint256 harvestableEssence = calculateHarvestableEssence(tokenId);
        uint256 accumulatedXP = calculateRealmAccumulatedXP(tokenId);

        require(harvestableEssence > 0 || accumulatedXP > 0, "NFTRealm: Nothing to harvest or gain");

        if (harvestableEssence > 0) {
            _essenceBalances[_msgSender()] += harvestableEssence;
        }
        if (accumulatedXP > 0) {
             realm.xp += accumulatedXP;
        }

        realm.lastHarvestTime = block.timestamp; // Reset harvest timer

        emit EssenceHarvested(tokenId, _msgSender(), harvestableEssence, accumulatedXP);
    }


    // --- Crafting & Modules ---

    /// @notice Crafts a new Module instance of a specific type.
    /// @param moduleTypeId The ID of the module type to craft.
    /// @return The ID of the newly crafted Module instance.
    function craftModule(uint256 moduleTypeId) public whenNotPaused {
        ModuleTypeConfig storage typeConfig = _moduleTypeConfigs[moduleTypeId];
        require(typeConfig.craftingCost > 0, "NFTRealm: Module type not supported or crafting cost not set");
        require(_essenceBalances[_msgSender()] >= typeConfig.craftingCost, "NFTRealm: Not enough essence to craft module");

        _essenceBalances[_msgSender()] -= typeConfig.craftingCost;

        _moduleIds.increment();
        uint256 newModuleInstanceId = _moduleIds.current();

        _modules[newModuleInstanceId] = Module({
            id: newModuleInstanceId,
            moduleTypeId: moduleTypeId,
            level: 1,
            owner: _msgSender(),
            isAttached: false,
            attachedRealmId: 0
        });

        emit ModuleCrafted(newModuleInstanceId, _msgSender(), moduleTypeId);
        return newModuleInstanceId;
    }

    /// @notice Upgrades a specific Module instance's level.
    /// @param moduleId The ID of the Module instance to upgrade.
    function upgradeModule(uint256 moduleId) public whenNotPaused moduleExists(moduleId) onlyModuleOwner(moduleId) {
        Module storage module = _modules[moduleId];
        ModuleTypeConfig storage typeConfig = _moduleTypeConfigs[module.moduleTypeId];

        uint256 cost = typeConfig.upgradeCostPerLevel * module.level; // Cost increases with level
        require(_essenceBalances[_msgSender()] >= cost, "NFTRealm: Not enough essence to upgrade module");

        _essenceBalances[_msgSender()] -= cost;
        module.level++;

        // If attached, update realm power (requires re-calculating and possibly storing)
        if (module.isAttached) {
             RealmAttributes storage realm = _realmAttributes[module.attachedRealmId];
             realm.power = calculateRealmPower(module.attachedRealmId); // Recalculate realm power
        }


        emit ModuleUpgraded(moduleId, module.level);
    }

     /// @notice Gets the attributes of a specific crafted Module instance.
     /// @param moduleId The ID of the Module instance.
     /// @return The Module struct.
     function getModuleAttributes(uint256 moduleId) public view moduleExists(moduleId) returns (Module memory) {
         return _modules[moduleId];
     }

    /// @notice Gets the base attributes configuration for a specific Module Type.
    /// @param moduleTypeId The ID of the Module Type.
    /// @return The ModuleTypeConfig struct.
     function getModuleTypeBaseAttributes(uint256 moduleTypeId) public view returns (ModuleTypeConfig memory) {
         require(_moduleTypeConfigs[moduleTypeId].craftingCost > 0 || _moduleTypeConfigs[moduleTypeId].upgradeCostPerLevel > 0, "NFTRealm: Module type config not set");
         return _moduleTypeConfigs[moduleTypeId];
     }

    // --- Realm & Module Attachment ---

    /// @notice Attaches a crafted Module instance owned by the caller to one of their Realms.
    /// @param realmId The ID of the Realm.
    /// @param moduleId The ID of the Module instance to attach.
    function attachModuleToRealm(uint256 realmId, uint256 moduleId) public whenNotPaused onlyRealmOwner(realmId) moduleExists(moduleId) onlyModuleOwner(moduleId) {
        RealmAttributes storage realm = _realmAttributes[realmId];
        Module storage module = _modules[moduleId];

        require(!module.isAttached, "NFTRealm: Module is already attached");
        require(realm.attachedModules.length < realm.moduleSlots, "NFTRealm: No available module slots on this realm");

        // Add module ID to realm's attached list
        realm.attachedModules.push(moduleId);

        // Update module state
        module.isAttached = true;
        module.attachedRealmId = realmId;

        // Recalculate realm power
        realm.power = calculateRealmPower(realmId);

        emit ModuleAttached(realmId, moduleId);
    }

    /// @notice Detaches a Module instance from a Realm.
    /// @param realmId The ID of the Realm.
    /// @param moduleId The ID of the Module instance to detach.
    function detachModuleFromRealm(uint256 realmId, uint256 moduleId) public whenNotPaused onlyRealmOwner(realmId) moduleExists(moduleId) {
         // Check if the module is actually attached to this realm
         Module storage module = _modules[moduleId];
         require(module.isAttached && module.attachedRealmId == realmId, "NFTRealm: Module not attached to this realm");

         RealmAttributes storage realm = _realmAttributes[realmId];
         uint256[] storage attachedMods = realm.attachedModules;

         // Find and remove the module ID from the array
         bool found = false;
         for (uint256 i = 0; i < attachedMods.length; i++) {
             if (attachedMods[i] == moduleId) {
                 // Swap the found element with the last element
                 attachedMods[i] = attachedMods[attachedMods.length - 1];
                 // Remove the last element (which is now the target module ID)
                 attachedMods.pop();
                 found = true;
                 break;
             }
         }
         require(found, "NFTRealm: Module not found in realm's attached list"); // Should not happen if module.attachedRealmId was correct


        // Update module state
        module.isAttached = false;
        module.attachedRealmId = 0;

        // Recalculate realm power
        realm.power = calculateRealmPower(realmId);

        emit ModuleDetached(realmId, moduleId);
    }

    // --- Upgrading Realms ---

    /// @notice Upgrades a Realm's level.
    /// @param tokenId The ID of the Realm to upgrade.
    function upgradeRealmLevel(uint256 tokenId) public whenNotPaused onlyRealmOwner(tokenId) realmExists(tokenId) {
        RealmAttributes storage realm = _realmAttributes[tokenId];
        uint256 nextLevel = realm.level + 1;
        uint256 upgradeCost = _realmUpgradeCosts[nextLevel];

        require(upgradeCost > 0, "NFTRealm: Upgrade cost not set for next level");
        require(_essenceBalances[_msgSender()] >= upgradeCost, "NFTRealm: Not enough essence to upgrade realm");
        // Optional: Add XP requirements here: require(realm.xp >= requiredXPForLevel[nextLevel], "NFTRealm: Not enough XP");

        _essenceBalances[_msgSender()] -= upgradeCost;
        realm.level = nextLevel;
        // Increase module slots or other base attributes upon level up
        realm.moduleSlots++; // Example: gain one slot per level
        realm.power += 50; // Example: gain some base power per level

        // Power is re-calculated in attach/detach, might need a separate refresh function or recalculate here too
        // realm.power = calculateRealmPower(tokenId); // Re-calculating here is safer after base changes

        emit RealmUpgraded(tokenId, nextLevel);
    }

    // --- Admin & Configuration (Requires Owner Role) ---

    /// @notice Sets the base URI for token metadata.
    /// @param newURI The new base URI.
    function setBaseURI(string memory newURI) public onlyOwner {
        _baseTokenURI = newURI;
        emit BaseURIUpdated(newURI);
    }

    /// @notice Sets the Essence per hour rate for Realms.
    /// @param rate The new rate (Essence per hour).
    function setEssenceHarvestRate(uint256 rate) public onlyOwner {
        _essenceHarvestRatePerHour = rate;
        emit EssenceHarvestRateUpdated(rate);
    }

     /// @notice Sets the XP per hour rate for Realms.
    /// @param rate The new rate (XP per hour).
    function setXPRate(uint256 rate) public onlyOwner {
        _xpRatePerHour = rate;
        emit XPRateUpdated(rate);
    }


    /// @notice Sets the Essence cost to craft a specific Module Type.
    /// @param moduleTypeId The ID of the module type.
    /// @param cost The new crafting cost.
    function setModuleCraftingCost(uint256 moduleTypeId, uint256 cost) public onlyOwner {
        _moduleTypeConfigs[moduleTypeId].craftingCost = cost;
        bool found = false;
        for(uint i=0; i<supportedModuleTypes.length; i++){
            if(supportedModuleTypes[i] == moduleTypeId){
                found = true;
                break;
            }
        }
        if(!found && cost > 0){ // Add to supported types if setting cost > 0 and not already there
             supportedModuleTypes.push(moduleTypeId);
        } else if (found && cost == 0) {
             // Optional: Remove from supportedModuleTypes if cost is set to 0
             // (Requires iterating and managing the array, skipping for simplicity here)
        }

        emit ModuleTypeConfigUpdated(moduleTypeId);
    }

    /// @notice Sets the base Essence cost per level to upgrade a Module Type.
    /// @param moduleTypeId The ID of the module type.
    /// @param costPerLevel The new base cost per level.
    function setModuleUpgradeCost(uint256 moduleTypeId, uint256 costPerLevel) public onlyOwner {
        _moduleTypeConfigs[moduleTypeId].upgradeCostPerLevel = costPerLevel;
         bool found = false;
        for(uint i=0; i<supportedModuleTypes.length; i++){
            if(supportedModuleTypes[i] == moduleTypeId){
                found = true;
                break;
            }
        }
         if(!found && costPerLevel > 0){ // Add to supported types if setting cost > 0 and not already there
             supportedModuleTypes.push(moduleTypeId);
        }
        emit ModuleTypeConfigUpdated(moduleTypeId);
    }

    /// @notice Configures the base attributes for a Module Type.
    /// @param moduleTypeId The ID of the module type.
    /// @param attributeValues The array of base attribute values (e.g., [powerBonus, harvestBonusMultiplier]).
    function setModuleTypeAttributes(uint256 moduleTypeId, uint256[] memory attributeValues) public onlyOwner {
        _moduleTypeConfigs[moduleTypeId].baseAttributes = attributeValues;
         bool found = false;
        for(uint i=0; i<supportedModuleTypes.length; i++){
            if(supportedModuleTypes[i] == moduleTypeId){
                found = true;
                break;
            }
        }
         if(!found && attributeValues.length > 0){ // Add to supported types if setting attributes > 0 and not already there
             supportedModuleTypes.push(moduleTypeId);
        }
        emit ModuleTypeConfigUpdated(moduleTypeId);
    }


    /// @notice Sets the Essence cost to upgrade a Realm to a specific level.
    /// @param level The target level (e.g., 2 for the first upgrade).
    /// @param cost The new upgrade cost.
    function setRealmUpgradeCost(uint256 level, uint256 cost) public onlyOwner {
        require(level > 1, "NFTRealm: Cannot set upgrade cost for level 1");
        _realmUpgradeCosts[level] = cost;
        emit RealmUpgradeCostUpdated(level, cost);
    }


    /// @notice Pauses or unpauses core contract interactions.
    /// @param paused True to pause, false to unpause.
    function setPause(bool paused) public onlyOwner {
        if (paused) {
            _pause();
        } else {
            _unpause();
        }
    }

     /// @notice Transfers the contract admin/owner role.
     /// @param newAdmin The address of the new admin.
     function transferAdmin(address newAdmin) public onlyOwner {
         require(newAdmin != address(0), "NFTRealm: new admin is the zero address");
         address previousAdmin = owner();
         transferOwnership(newAdmin);
         emit AdminTransferred(previousAdmin, newAdmin);
     }
}
```