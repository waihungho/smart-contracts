Okay, let's design a smart contract around a concept of "Dynamic Generative Assets" or "Procedural Genesis Units" (PGUs). These aren't just static NFTs; they are entities with evolving states, traits, and abilities based on on-chain interactions and time.

The key advanced concepts will include:
1.  **Dynamic State & Evolution:** Assets change over time and through actions.
2.  **Packed Data:** Using bit manipulation (`uint256`, `uint32`) to store multiple traits/flags efficiently in a single storage slot, saving gas.
3.  **Time-Based Mechanics:** Implementing energy regeneration or decay based on block timestamps.
4.  **Complex Interaction:** Defining rules for how assets interact with each other, leading to state changes on multiple assets.
5.  **Asset Fusion/Burning:** A mechanism to combine assets, destroying inputs and potentially creating a new or enhanced output.
6.  **Modular Abilities/Traits:** Attaching "mods" or attributes that change asset behavior, represented by data within the asset struct.
7.  **Pseudo-Generative Elements:** Initial traits derived from creation parameters (seed).

This contract will inherit from ERC721 for ownership and transferability, and add the custom PGU logic.

---

### Smart Contract: ProceduralGenesisUnits

**Outline:**

1.  ** SPDX License & Pragma**
2.  ** Imports** (ERC721, Ownable, Pausable)
3.  ** Error Definitions**
4.  ** Events**
5.  ** Structs** (PGU data structure)
6.  ** Constants & Packed Data Bitmasks**
7.  ** State Variables**
8.  ** Mappings** (Standard ERC721 mappings, plus PGU data mapping)
9.  ** Modifiers** (`whenNotPaused`, internal helpers)
10. ** Constructor** (Initializes base contract parameters)
11. ** ERC721 Standard Function Overrides** (Ensure PGU data integrity on transfer/burn)
12. ** Internal Core Logic Helpers** (`_updateEnergy`, `_grantXP`, `_checkLevelUp`, `_applyModEffects`, `_generateGenesisTraits`, `_packTraits`, `_unpackTraits`, `_packStatusFlags`, `_unpackStatusFlags`)
13. ** PGU Creation & Management** (`mintGenesisUnit`, `fusePGUs`)
14. ** PGU State & Information (View Functions)** (Get various details about a PGU)
15. ** PGU Actions & Evolution (State-Changing Functions)** (`performAction`, `levelUp`, `addMod`, `removeMod`, `interactWithPGU`, `refuelEnergyExplicit`)
16. ** Configuration Functions** (Owner-only settings)
17. ** Utility Functions** (`withdrawBalance`, Pausability)

**Function Summary (Highlighting Custom/Advanced Functions):**

1.  `constructor()`: Deploys the contract, sets initial owner and configuration defaults.
2.  `balanceOf(address owner)`: (ERC721 Standard) Returns the number of tokens owned by an address.
3.  `ownerOf(uint256 tokenId)`: (ERC721 Standard) Returns the owner of a specific token ID.
4.  `approve(address to, uint256 tokenId)`: (ERC721 Standard) Approves another address to transfer a specific token.
5.  `getApproved(uint256 tokenId)`: (ERC721 Standard) Returns the approved address for a token.
6.  `setApprovalForAll(address operator, bool approved)`: (ERC721 Standard) Approves or revokes approval for an operator for all tokens.
7.  `isApprovedForAll(address owner, address operator)`: (ERC721 Standard) Checks if an operator is approved for all tokens of an owner.
8.  `transferFrom(address from, address to, uint256 tokenId)`: (ERC721 Standard) Transfers a token (requires approval).
9.  `safeTransferFrom(address from, address to, uint256 tokenId)`: (ERC721 Standard) Transfers a token safely (checks if recipient can receive ERC721).
10. `safeTransferFrom(address from, address to, uint256 tokenId, bytes data)`: (ERC721 Standard) Safe transfer with additional data.
11. `mintGenesisUnit(address owner, uint256 genesisSeed)`: **(Custom)** Mints a *new* PGU token for `owner`, initializing its state based on the `genesisSeed`. Requires owner/minter role.
12. `fusePGUs(uint256 pguId1, uint256 pguId2)`: **(Advanced Custom)** A core interaction. Burns `pguId1`, potentially transferring a portion of its XP, traits, or mods to `pguId2`, enhancing `pguId2`. Requires ownership/approval of both.
13. `getPGUState(uint256 tokenId)`: **(Custom View)** Returns the current *dynamic* state of a PGU: level, xp, energy, last energy update, mods, status flags. Automatically updates energy based on time before returning.
14. `getGenesisTraits(uint256 tokenId)`: **(Custom View)** Returns the *immutable* genesis traits of a PGU (packed uint256).
15. `getDynamicTraits(uint256 tokenId)`: **(Custom View)** Returns the current *mutable* dynamic traits of a PGU (packed uint256).
16. `getPGUEnergyState(uint256 tokenId)`: **(Custom View)** Returns the current energy and the timestamp of the last energy update. Includes the potential energy regeneration that *could* occur by now.
17. `getPGUStatsComputed(uint256 tokenId)`: **(Custom View)** Computes derived statistics or combat power based on level, dynamic traits, and active mods. *Requires implementing specific computation logic.*
18. `getModSlots(uint256 tokenId)`: **(Custom View)** Returns the current number of used mod slots and the maximum available slots for a PGU.
19. `getMod(uint256 tokenId, uint8 slotId)`: **(Custom View)** Returns the mod ID equipped in a specific slot for a PGU.
20. `getStatusFlags(uint256 tokenId)`: **(Custom View)** Returns the packed uint32 representing the current status flags of a PGU.
21. `performAction(uint256 tokenId, uint8 actionType, bytes calldata actionData)`: **(Advanced Custom)** A PGU performs a generic action. Consumes energy, grants XP, potentially alters dynamic traits based on `actionType` and `actionData`.
22. `levelUp(uint256 tokenId)`: **(Custom)** Allows a PGU owner to consume accumulated XP to increase the PGU's level, potentially gaining mod slots or increasing energy cap.
23. `addMod(uint256 tokenId, uint8 slotId, uint256 modId)`: **(Advanced Custom)** Equips a specific `modId` into a `slotId` on the PGU. Requires an available slot and potentially consumes a resource (not implemented explicitly as separate tokens here for simplicity, just uses `modId`). Updates dynamic traits based on the mod.
24. `removeMod(uint256 tokenId, uint8 slotId)`: **(Custom)** Removes the mod from a specific slot, potentially reverting dynamic trait effects.
25. `interactWithPGU(uint256 pguIdA, uint256 pguIdB, uint8 interactionType)`: **(Advanced Custom)** Two PGUs interact. Logic depends on their types, traits, and the `interactionType`. Can consume energy from both, change XP, dynamic traits, or status flags on both.
26. `refuelEnergyExplicit(uint256 tokenId)`: **(Custom)** Explicitly triggers energy regeneration based on elapsed time. While implicitly done by state access, this allows an owner to force the update.
27. `setEnergyRegenParams(uint16 rate, uint48 intervalSeconds)`: (Owner Config) Sets the rate and interval for PGU energy regeneration.
28. `setXPPerLevel(uint64[] memory xpLevels)`: (Owner Config) Sets the cumulative XP required for each level.
29. `setModSlotsPerLevel(uint8[] memory modSlotsByLevel)`: (Owner Config) Sets the maximum mod slots available at each level.
30. `setInteractionMatrix(uint8 interactionType, uint256 encodedRules)`: (Owner Config) Configures the complex rules/outcomes for `interactWithPGU`. `encodedRules` would be a packed representation of outcome probabilities/effects. (Simplified placeholder).
31. `withdrawBalance()`: (Owner Utility) Allows the contract owner to withdraw any Ether sent to the contract (e.g., from future minting fees).
32. `pause()`: (Pausable Standard) Pauses contract state-changing functions.
33. `unpause()`: (Pausable Standard) Unpauses contract.

This setup provides a rich state and interaction model for NFTs, going beyond simple ownership and metadata.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol"; // Optional but good practice

// Custom Errors
error PGU_NotFound(uint256 tokenId);
error PGU_NotOwnerOrApproved(address caller, uint256 tokenId);
error PGU_InsufficientEnergy(uint256 tokenId, uint16 required, uint16 available);
error PGU_NotEnoughXPForLevelUp(uint256 tokenId, uint64 required, uint64 available);
error PGU_InvalidModSlot(uint8 slotId, uint8 maxSlots);
error PGU_ModSlotOccupied(uint8 slotId, uint256 existingModId);
error PGU_ModSlotEmpty(uint8 slotId);
error PGU_SamePGUInteraction(uint256 tokenId);
error PGU_FusionRequiresTwoDistinctPGUs(uint256 pguId1, uint256 pguId2);
error PGU_FusionInputsNotValid(uint256 pguId1, uint256 pguId2);
error PGU_InvalidActionType(uint8 actionType);
error PGU_InvalidInteractionType(uint8 interactionType);
error PGU_LevelArrayMismatch();

// Events
event PGUMinted(uint256 indexed tokenId, address indexed owner, uint256 genesisSeed);
event PGUActionPerformed(uint256 indexed tokenId, uint8 indexed actionType, uint16 energyConsumed, uint64 xpGained);
event PGULoaded(uint256 indexed tokenId, uint64 currentXP, uint16 currentLevel, uint16 currentEnergy); // Emitted when state is loaded after updateEnergy
event PGULevelUp(uint256 indexed tokenId, uint16 oldLevel, uint16 newLevel, uint8 newModSlots);
event PGUFused(uint256 indexed burnedPguId, uint256 indexed targetPguId, uint64 xpTransferred, uint256 traitsTransferred);
event ModAdded(uint256 indexed tokenId, uint8 indexed slotId, uint256 modId);
event ModRemoved(uint256 indexed tokenId, uint8 indexed slotId, uint256 removedModId);
event PGUDynamicTraitsChanged(uint256 indexed tokenId, uint256 oldTraits, uint256 newTraits);
event PGUStatusFlagsChanged(uint256 indexed tokenId, uint32 oldFlags, uint32 newFlags);

contract ProceduralGenesisUnits is ERC721, Ownable, Pausable {
    using SafeMath for uint64;
    using SafeMath for uint16;
    using SafeMath for uint48;

    // --- Structs ---

    struct PGU {
        uint256 genesisSeed; // Immutable seed used for initial trait generation
        uint48 creationTime; // Unix timestamp of creation (block.timestamp)
        uint16 level;
        uint64 xp;
        uint16 energy; // Current energy level
        uint48 lastEnergyUpdateTime; // Unix timestamp of last energy update
        mapping(uint8 => uint256) mods; // modSlotId => modId (simplified, modId is just an identifier)
        uint8 modSlots; // Max number of mods that can be equipped
        uint32 statusFlags; // Packed boolean flags (e.g., isBusy, isFueled)
        uint256 genesisTraits; // Packed immutable traits derived from seed
        uint256 dynamicTraits; // Packed mutable traits that change with level/actions/mods
    }

    // --- Constants for Packed Data (Example Bit Positions) ---
    // dynamicTraits (uint256)
    uint8 private constant TRAIT_ATTACK_BIT = 0; // Using 8 bits for each trait for range 0-255
    uint8 private constant TRAIT_DEFENSE_BIT = 8;
    uint8 private constant TRAIT_SPEED_BIT = 16;
    uint8 private constant TRAIT_INTELLIGENCE_BIT = 24;
    // Add more traits as needed, each using 8 bits: 32, 40, 48, ...

    // statusFlags (uint32)
    uint8 private constant FLAG_IS_BUSY_BIT = 0; // Using 1 bit for each flag
    uint8 private constant FLAG_IS_FUELED_BIT = 1;
    uint8 private constant FLAG_NEEDS_MAINTENANCE_BIT = 2;
    // Add more flags as needed: 3, 4, 5, ...

    // --- State Variables ---

    uint256 private _nextTokenId; // Counter for unique token IDs
    mapping(uint256 => PGU) private _pguData; // Mapping token ID to PGU struct

    // Configuration Parameters (Owner Settable)
    uint16 public ENERGY_REGEN_RATE = 1; // Energy points regenerated per interval
    uint48 public ENERGY_REGEN_INTERVAL_SECONDS = 3600; // Time in seconds for one regeneration step (1 hour)
    uint16 public constant MAX_ENERGY_BASE = 100; // Base max energy
    uint16 public constant ENERGY_PER_LEVEL_INCREASE = 10; // Max energy increase per level

    uint64[] public xpRequiredForLevel; // xpRequiredForLevel[level] = cumulative XP for that level
    uint8[] public modSlotsByLevel; // modSlotsByLevel[level] = max mod slots at that level

    // Simplified interaction matrix (Example: interactionType => encoded rule)
    mapping(uint8 => uint256) public interactionMatrix;

    // --- Constructor ---

    constructor(string memory name, string memory symbol)
        ERC721(name, symbol)
        Ownable(msg.sender)
    {
        _nextTokenId = 0;
        _setDefaultLevelingParams();
    }

    // --- ERC721 Overrides ---
    // Override hooks to ensure PGU data exists/is handled correctly on transfer/burn

    function _update(address to, uint256 tokenId, address auth) internal virtual override(ERC721) returns (address) {
        // Basic safety check, PGU data should exist for existing tokens
        require(_pguData[tokenId].creationTime != 0, "PGU data missing for token");
        // Call parent update logic
        return super._update(to, tokenId, auth);
    }

    // When a token is burned (e.g., via fusePGUs), remove its PGU data
    function _burn(uint256 tokenId) internal virtual override(ERC721) {
        super._burn(tokenId);
        // Remove PGU data associated with the burned token
        delete _pguData[tokenId];
    }

    // Consider overriding _beforeTokenTransfer if state needs resetting on transfer (e.g., removing 'isBusy' flag)
    // function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize) internal virtual override {}

    // --- Internal Core Logic Helpers ---

    // @dev Updates PGU energy based on time elapsed since last update.
    // Should be called at the beginning of any function that depends on or modifies energy.
    function _updateEnergy(uint256 tokenId) internal {
        PGU storage pgu = _pguData[tokenId];
        uint48 currentTime = uint48(block.timestamp);
        uint48 timeElapsed = currentTime - pgu.lastEnergyUpdateTime;

        if (timeElapsed == 0) {
             // No time has passed since last update
             return;
        }

        uint16 maxEnergy = MAX_ENERGY_BASE.add(pgu.level.mul(ENERGY_PER_LEVEL_INCREASE));
        uint16 potentialRegen = uint16(timeElapsed.div(ENERGY_REGEN_INTERVAL_SECONDS).mul(ENERGY_REGEN_RATE));

        if (potentialRegen > 0) {
            uint16 oldEnergy = pgu.energy;
            pgu.energy = pgu.energy.add(potentialRegen);
            if (pgu.energy > maxEnergy) {
                pgu.energy = maxEnergy;
            }
            pgu.lastEnergyUpdateTime = currentTime; // Update timestamp only if regen occurred

            if (pgu.energy != oldEnergy) {
                 emit PGULoaded(tokenId, pgu.xp, pgu.level, pgu.energy); // Indicate state update
            }
        } else {
             // If less than an interval has passed, just update timestamp without regen
             pgu.lastEnergyUpdateTime = currentTime;
        }
    }

    // @dev Grants XP to a PGU and checks for level up.
    function _grantXP(uint256 tokenId, uint64 amount) internal {
        PGU storage pgu = _pguData[tokenId];
        uint64 oldXP = pgu.xp;
        pgu.xp = pgu.xp.add(amount);

        if (pgu.xp >= xpRequiredForLevel[pgu.level]) {
            _checkLevelUp(tokenId); // Check if leveling up is possible
        }
        // No specific event for XP gain itself, LevelUp event covers the milestone
    }

    // @dev Checks if a PGU can level up and performs the level up if so.
    function _checkLevelUp(uint256 tokenId) internal {
        PGU storage pgu = _pguData[tokenId];
        uint16 oldLevel = pgu.level;

        while (pgu.level < xpRequiredForLevel.length - 1 && pgu.xp >= xpRequiredForLevel[pgu.level]) {
            pgu.level = pgu.level.add(1);
        }

        if (pgu.level > oldLevel) {
            uint8 newModSlots = modSlotsByLevel[pgu.level];
            pgu.modSlots = newModSlots; // Update mod slots to the value for the new level

            // Potential increase in max energy is handled dynamically by _updateEnergy

            emit PGULevelUp(tokenId, oldLevel, pgu.level, newModSlots);
        }
    }

    // @dev Applies effects of currently equipped mods to dynamic traits.
    // This could be called after adding/removing mods or before complex interactions.
    // For this example, we'll simplify: mods directly set/modify trait *values*
    // A more complex system might apply percentage bonuses etc.
    function _applyModEffects(uint256 tokenId) internal {
        PGU storage pgu = _pguData[tokenId];
        // Complex logic: Iterate through active mods, read their effects (hardcoded or from another mapping),
        // and modify pgu.dynamicTraits accordingly.
        // This is a placeholder. Actual implementation would require detailed mod data structures and rules.
        // For example:
        // uint256 currentDynamicTraits = pgu.dynamicTraits;
        // uint256 modifiedTraits = currentDynamicTraits;
        // for (uint8 i = 0; i < pgu.modSlots; i++) {
        //     uint256 modId = pgu.mods[i];
        //     if (modId > 0) {
        //         // Lookup mod effects for modId (e.g., from a mod data mapping)
        //         // Apply effects to modifiedTraits using bit manipulation
        //     }
        // }
        // pgu.dynamicTraits = modifiedTraits;
        // emit PGUDynamicTraitsChanged(tokenId, currentDynamicTraits, pgu.dynamicTraits);
        // --- Placeholder Logic ---
        // Simple example: Mod 1 adds 10 to Attack trait, Mod 2 adds 10 to Defense
        uint256 oldTraits = pgu.dynamicTraits;
        uint256 currentTraits = oldTraits;
        for (uint8 i = 0; i < pgu.modSlots; i++) {
             uint256 modId = pgu.mods[i];
             if (modId == 1) { // Example Mod 1
                 uint256 currentAttack = (_unpackTraits(currentTraits) >> TRAIT_ATTACK_BIT) & 0xFF;
                 currentAttack = currentAttack.add(10); // Add 10
                 if (currentAttack > 255) currentAttack = 255; // Cap at 255
                 currentTraits = (currentTraits & ~(0xFF << TRAIT_ATTACK_BIT)) | (currentAttack << TRAIT_ATTACK_BIT);
             } else if (modId == 2) { // Example Mod 2
                 uint256 currentDefense = (_unpackTraits(currentTraits) >> TRAIT_DEFENSE_BIT) & 0xFF;
                 currentDefense = currentDefense.add(10); // Add 10
                 if (currentDefense > 255) currentDefense = 255; // Cap at 255
                 currentTraits = (currentTraits & ~(0xFF << TRAIT_DEFENSE_BIT)) | (currentDefense << TRAIT_DEFENSE_BIT);
             }
             // Add more mod effects here...
        }
        pgu.dynamicTraits = currentTraits;
        if (pgu.dynamicTraits != oldTraits) {
             emit PGUDynamicTraitsChanged(tokenId, oldTraits, pgu.dynamicTraits);
        }
    }


    // @dev Generates initial genesis traits based on a seed.
    // This is a simplified deterministic generation. More complex versions could use VRF.
    function _generateGenesisTraits(uint256 genesisSeed) internal view returns (uint256) {
        uint256 traits = 0;
        bytes32 hash = keccak256(abi.encodePacked(genesisSeed, block.timestamp, block.difficulty, msg.sender));

        // Example: pack 4 x uint8 traits into a uint256
        traits |= uint256(uint8(uint256(hash) % 256)) << TRAIT_ATTACK_BIT; // Attack 0-255
        traits |= uint256(uint8((uint256(hash) / 256) % 256)) << TRAIT_DEFENSE_BIT; // Defense 0-255
        traits |= uint256(uint8((uint256(hash) / 65536) % 256)) << TRAIT_SPEED_BIT; // Speed 0-255
        traits |= uint256(uint8((uint256(hash) / 16777216) % 256)) << TRAIT_INTELLIGENCE_BIT; // Intelligence 0-255

        // Add more trait generation and packing here...

        return traits;
    }

    // @dev Packs multiple trait values (assumed uint8 for simplicity) into a single uint256.
    // Example: value1 (8 bits) | value2 (8 bits) << 8 | value3 (8 bits) << 16 | ...
    function _packTraits(uint8 trait1, uint8 trait2, uint8 trait3, uint8 trait4) internal pure returns (uint256) {
        uint256 packed = 0;
        packed |= uint256(trait1) << TRAIT_ATTACK_BIT; // Using defined bit positions
        packed |= uint256(trait2) << TRAIT_DEFENSE_BIT;
        packed |= uint256(trait3) << TRAIT_SPEED_BIT;
        packed |= uint256(trait4) << TRAIT_INTELLIGENCE_BIT;
        return packed;
    }

     // @dev Unpacks a uint256 into individual trait values (returns the original uint256 for manipulation)
     // Use bit masks and shifts on the returned value.
     function _unpackTraits(uint256 packedTraits) internal pure returns (uint256) {
         return packedTraits;
     }

    // @dev Packs boolean flags into a uint32.
    // Example: flag1 (1 bit) | flag2 (1 bit) << 1 | flag3 (1 bit) << 2 | ...
    function _packStatusFlags(bool isBusy, bool isFueled, bool needsMaintenance) internal pure returns (uint32) {
        uint32 packed = 0;
        if (isBusy) packed |= (1 << FLAG_IS_BUSY_BIT);
        if (isFueled) packed |= (1 << FLAG_IS_FUELED_BIT);
        if (needsMaintenance) packed |= (1 << FLAG_NEEDS_MAINTENANCE_BIT);
        return packed;
    }

    // @dev Unpacks a uint32 into individual boolean flags.
    // Use bit masks and checks on the returned value.
    function _unpackStatusFlags(uint32 packedFlags) internal pure returns (uint32) {
        return packedFlags;
    }

    // @dev Sets default leveling parameters
    function _setDefaultLevelingParams() internal {
         // Example XP curve: Level 0-4 = 100 XP each, Level 5-9 = 200 XP each, Level 10+ = 500 XP each
         // xpRequiredForLevel[n] is the CUMULATIVE xp needed to REACH level n
         xpRequiredForLevel = new uint64[](11); // Support levels 0 to 10 initially
         xpRequiredForLevel[0] = 0;
         xpRequiredForLevel[1] = 100;
         xpRequiredForLevel[2] = 200;
         xpRequiredForLevel[3] = 300;
         xpRequiredForLevel[4] = 400;
         xpRequiredForLevel[5] = 600; // Cumulative: 400 + 200
         xpRequiredForLevel[6] = 800;
         xpRequiredForLevel[7] = 1000;
         xpRequiredForLevel[8] = 1200;
         xpRequiredForLevel[9] = 1400;
         xpRequiredForLevel[10] = 1900; // Cumulative: 1400 + 500

         // Example Mod Slot curve: Level 0-1 = 1 slot, Level 2-4 = 2 slots, Level 5+ = 3 slots
         modSlotsByLevel = new uint8[](11);
         modSlotsByLevel[0] = 1;
         modSlotsByLevel[1] = 1;
         modSlotsByLevel[2] = 2;
         modSlotsByLevel[3] = 2;
         modSlotsByLevel[4] = 2;
         modSlotsByLevel[5] = 3;
         modSlotsByLevel[6] = 3;
         modSlotsByLevel[7] = 3;
         modSlotsByLevel[8] = 3;
         modSlotsByLevel[9] = 3;
         modSlotsByLevel[10] = 3; // Max 3 slots in this example
    }


    // --- PGU Creation & Management ---

    /// @notice Mints a new Procedural Genesis Unit token.
    /// @param owner The address that will own the new token.
    /// @param genesisSeed A seed value used to determine the PGU's initial traits.
    /// @dev Only callable by the contract owner. Increments internal token ID counter.
    function mintGenesisUnit(address owner, uint256 genesisSeed) external onlyOwner whenNotPaused {
        uint256 newTokenId = _nextTokenId++;
        _mint(owner, newTokenId);

        uint48 currentTime = uint48(block.timestamp);

        _pguData[newTokenId] = PGU({
            genesisSeed: genesisSeed,
            creationTime: currentTime,
            level: 0,
            xp: 0,
            energy: MAX_ENERGY_BASE, // Starts with full energy
            lastEnergyUpdateTime: currentTime,
            mods: new mapping(uint8 => uint256)(), // Initialize mapping
            modSlots: modSlotsByLevel[0], // Initial mod slots from config
            statusFlags: 0, // No flags set initially
            genesisTraits: _generateGenesisTraits(genesisSeed),
            dynamicTraits: 0 // Dynamic traits start at a base or 0 and are affected by level/mods
        });

        // Apply initial effects from level 0 and any implicit base stats
        // For simplicity, let's assume dynamic traits start at 0 and gain values from level/mods.
        // A more complex system might derive base dynamic traits from genesis traits.
        // Call apply mod effects even if no mods are equipped yet, if modSlotsByLevel[0] > 0
        // and there are base effects from having slots. Or base stats could be separate.
        // Let's keep dynamic traits starting at 0 and only changed by level/mods/actions explicitly.

        emit PGUMinted(newTokenId, owner, genesisSeed);
    }

    /// @notice Fuses two PGUs into one, burning the first PGU and transferring attributes to the second.
    /// @param pguId1 The ID of the PGU to be burned (the "sacrifice").
    /// @param pguId2 The ID of the PGU to be enhanced (the "target").
    /// @dev Requires caller to own or be approved for both tokens.
    /// The fusion logic is complex and simplified here. Actual rules would determine trait transfer, XP amount, etc.
    function fusePGUs(uint256 pguId1, uint256 pguId2) external whenNotPaused {
        if (pguId1 == pguId2) {
            revert PGU_FusionRequiresTwoDistinctPGUs(pguId1, pguId2);
        }

        address owner1 = ownerOf(pguId1);
        address owner2 = ownerOf(pguId2);

        if (msg.sender != owner1 && !isApprovedForAll(owner1, msg.sender) && getApproved(pguId1) != msg.sender) {
            revert PGU_NotOwnerOrApproved(msg.sender, pguId1);
        }
         if (msg.sender != owner2 && !isApprovedForAll(owner2, msg.sender) && getApproved(pguId2) != msg.sender) {
            revert PGU_NotOwnerOrApproved(msg.sender, pguId2);
        }

        PGU storage pgu1 = _pguData[pguId1];
        PGU storage pgu2 = _pguData[pguId2];

        if (pgu1.creationTime == 0 || pgu2.creationTime == 0) {
            revert PGU_FusionInputsNotValid(pguId1, pguId2);
        }

        // --- Fusion Logic (Example) ---
        // Transfer a percentage of XP from PGU1 to PGU2
        uint64 xpToTransfer = pgu1.xp.div(2); // Transfer 50% of XP
        _grantXP(pguId2, xpToTransfer); // Grants XP and checks for level up

        // Transfer some traits or combine them (highly simplified)
        // Example: Transfer Attack trait from pgu1 to pgu2 if pgu1's is higher
        uint256 traits1 = _unpackTraits(pgu1.dynamicTraits);
        uint256 traits2 = _unpackTraits(pgu2.dynamicTraits);

        uint8 attack1 = uint8((traits1 >> TRAIT_ATTACK_BIT) & 0xFF);
        uint8 attack2 = uint8((traits2 >> TRAIT_ATTACK_BIT) & 0xFF);

        uint256 traitsTransferred = 0; // Track what was transferred/modified

        if (attack1 > attack2) {
             // Set pgu2's attack trait to pgu1's attack trait value
            traits2 = (traits2 & ~(0xFF << TRAIT_ATTACK_BIT)) | (uint256(attack1) << TRAIT_ATTACK_BIT);
            traitsTransferred |= (uint256(attack1) << TRAIT_ATTACK_BIT); // Mark attack trait as transferred
        }
        // Add more trait fusion rules here...

        pgu2.dynamicTraits = traits2; // Update pgu2's dynamic traits
        _applyModEffects(pguId2); // Re-apply mod effects after potential trait change

        // Burn the sacrifice PGU
        _burn(pguId1);

        emit PGUFused(pguId1, pguId2, xpToTransfer, traitsTransferred);
        emit PGUDynamicTraitsChanged(pguId2, _pguData[pguId2].dynamicTraits, traits2); // Emit change for pgu2
    }

    // --- PGU State & Information (View Functions) ---

    /// @notice Gets the full dynamic state of a PGU. Automatically updates energy first.
    /// @param tokenId The ID of the PGU.
    /// @return level, xp, energy, lastEnergyUpdateTime, mods, modSlots, statusFlags, dynamicTraits
    function getPGUState(uint256 tokenId) external returns (
        uint16 level,
        uint64 xp,
        uint16 energy,
        uint48 lastEnergyUpdateTime,
        mapping(uint8 => uint256) storage mods, // Note: Can't return mapping directly, this is for internal use mainly
        uint8 modSlots,
        uint32 statusFlags,
        uint256 dynamicTraits
    ) {
        require(_pguData[tokenId].creationTime != 0, "PGU does not exist");
        _updateEnergy(tokenId); // Update energy based on time

        PGU storage pgu = _pguData[tokenId];
        level = pgu.level;
        xp = pgu.xp;
        energy = pgu.energy;
        lastEnergyUpdateTime = pgu.lastEnergyUpdateTime;
        // mods = pgu.mods; // Cannot return mapping directly
        modSlots = pgu.modSlots;
        statusFlags = pgu.statusFlags;
        dynamicTraits = pgu.dynamicTraits; // Note: This includes mod effects if applied dynamically

        // To return mods externally, you'd need separate functions like getMod or getAllMods (requires iteration).
        // Example for external:
        // function getPGUStateForDisplay(...) returns (...) {
        //    PGU storage pgu = _pguData[tokenId];
        //    _updateEnergy(tokenId);
        //    uint256[] memory equippedMods = new uint256[](pgu.modSlots);
        //    for(uint8 i=0; i < pgu.modSlots; i++) { equippedMods[i] = pgu.mods[i]; }
        //    return (pgu.level, pgu.xp, pgu.energy, ..., equippedMods, ...);
        // }
        // Returning the struct directly is fine for internal/contract use.
        revert("Cannot return mapping directly. Use helper views like getMod or getModSlots.");
    }


    /// @notice Gets the immutable genesis traits of a PGU.
    /// @param tokenId The ID of the PGU.
    /// @return Packed uint256 representing genesis traits.
    function getGenesisTraits(uint256 tokenId) external view returns (uint256) {
        require(_pguData[tokenId].creationTime != 0, "PGU does not exist");
        return _pguData[tokenId].genesisTraits;
    }

    /// @notice Gets the current mutable dynamic traits of a PGU.
    /// @param tokenId The ID of the PGU.
    /// @return Packed uint256 representing dynamic traits.
    function getDynamicTraits(uint256 tokenId) external view returns (uint256) {
        require(_pguData[tokenId].creationTime != 0, "PGU does not exist");
        // Note: This returns the stored dynamicTraits. If mod effects are applied dynamically on access/action,
        // this might not reflect the *fully* computed value unless _applyModEffects is called first (but it's a view).
        // For computed stats, use getPGUStatsComputed.
        return _pguData[tokenId].dynamicTraits;
    }


    /// @notice Gets the current energy state of a PGU. Updates energy first.
    /// @param tokenId The ID of the PGU.
    /// @return currentEnergy The energy level after regeneration.
    /// @return lastEnergyUpdateTime The timestamp of the last energy update.
    function getPGUEnergyState(uint256 tokenId) external returns (uint16 currentEnergy, uint48 lastEnergyUpdateTime) {
        require(_pguData[tokenId].creationTime != 0, "PGU does not exist");
        _updateEnergy(tokenId);
        PGU storage pgu = _pguData[tokenId];
        return (pgu.energy, pgu.lastEnergyUpdateTime);
    }

     /// @notice Computes derived statistics or power based on a PGU's current state.
     /// @param tokenId The ID of the PGU.
     /// @return A computed stat value (e.g., power score, attack value).
     /// @dev This is a placeholder. Implement complex calculation logic here.
     function getPGUStatsComputed(uint256 tokenId) external view returns (uint256 computedStat) {
         require(_pguData[tokenId].creationTime != 0, "PGU does not exist");
         PGU storage pgu = _pguData[tokenId];

         // --- Example Computed Stat Logic ---
         // Simple example: Power = (Level * 10) + (Dynamic Attack Trait * 2) + (Dynamic Defense Trait)
         uint256 dynamicTraits = _unpackTraits(pgu.dynamicTraits);
         uint8 attack = uint8((dynamicTraits >> TRAIT_ATTACK_BIT) & 0xFF);
         uint8 defense = uint8((dynamicTraits >> TRAIT_DEFENSE_BIT) & 0xFF);

         computedStat = uint256(pgu.level).mul(10)
                        .add(uint256(attack).mul(2))
                        .add(uint256(defense));

         // Add more complex factors: genesis traits, specific mods, status flags, etc.
         // Example: if FLAG_IS_FUELED is set, add a bonus
         if (((_unpackStatusFlags(pgu.statusFlags) >> FLAG_IS_FUELED_BIT) & 1) == 1) {
             computedStat = computedStat.add(50); // Fuel bonus
         }

         return computedStat;
     }

    /// @notice Gets the current and maximum mod slots for a PGU.
    /// @param tokenId The ID of the PGU.
    /// @return usedSlots The number of slots currently occupied.
    /// @return maxSlots The maximum number of slots available.
    function getModSlots(uint256 tokenId) external view returns (uint8 usedSlots, uint8 maxSlots) {
        require(_pguData[tokenId].creationTime != 0, "PGU does not exist");
        PGU storage pgu = _pguData[tokenId];

        uint8 currentUsed = 0;
        // Iterate through potential slots up to the max
        for (uint8 i = 0; i < pgu.modSlots; i++) {
            if (pgu.mods[i] != 0) { // Assuming modId 0 means empty slot
                currentUsed++;
            }
        }
        return (currentUsed, pgu.modSlots);
    }

    /// @notice Gets the mod ID equipped in a specific slot.
    /// @param tokenId The ID of the PGU.
    /// @param slotId The ID of the mod slot (0-indexed).
    /// @return The mod ID in the slot, or 0 if empty.
    function getMod(uint256 tokenId, uint8 slotId) external view returns (uint256) {
         require(_pguData[tokenId].creationTime != 0, "PGU does not exist");
         PGU storage pgu = _pguData[tokenId];
         if (slotId >= pgu.modSlots) {
             // Slot is out of bounds for this PGU's current level/max slots
             return 0; // Or revert? Returning 0 might be less disruptive for UI
         }
         return pgu.mods[slotId];
    }

    /// @notice Gets the packed status flags for a PGU.
    /// @param tokenId The ID of the PGU.
    /// @return Packed uint32 representing status flags.
    function getStatusFlags(uint256 tokenId) external view returns (uint32) {
         require(_pguData[tokenId].creationTime != 0, "PGU does not exist");
         return _pguData[tokenId].statusFlags;
    }


    // --- PGU Actions & Evolution (State-Changing Functions) ---

    /// @notice Allows a PGU to perform a defined action.
    /// @param tokenId The ID of the PGU performing the action.
    /// @param actionType The type of action being performed (determines energy cost, XP gain, trait changes).
    /// @param actionData Optional data specific to the action.
    /// @dev Requires caller to own or be approved for the token. Consumes energy.
    function performAction(uint256 tokenId, uint8 actionType, bytes calldata actionData) external whenNotPaused {
        address owner = ownerOf(tokenId);
        if (msg.sender != owner && !isApprovedForAll(owner, msg.sender) && getApproved(tokenId) != msg.sender) {
            revert PGU_NotOwnerOrApproved(msg.sender, tokenId);
        }
        require(_pguData[tokenId].creationTime != 0, "PGU does not exist");

        _updateEnergy(tokenId); // Regenerate energy based on time

        PGU storage pgu = _pguData[tokenId];

        // --- Action Logic (Example) ---
        uint16 energyCost;
        uint64 xpGain;
        // Add logic to determine cost/gain/trait changes based on actionType
        // This could be a large switch statement, lookup from a mapping, or derive from PGU state.
        if (actionType == 1) { // Example Action: Gather Resource
            energyCost = 10;
            xpGain = 50;
            // Example trait change: temporarily increase 'isBusy' flag
            uint32 oldFlags = pgu.statusFlags;
            pgu.statusFlags = _packStatusFlags(true, ((_unpackStatusFlags(oldFlags) >> FLAG_IS_FUELED_BIT) & 1) == 1, ((_unpackStatusFlags(oldFlags) >> FLAG_NEEDS_MAINTENANCE_BIT) & 1) == 1);
            emit PGUStatusFlagsChanged(tokenId, oldFlags, pgu.statusFlags);

        } else if (actionType == 2) { // Example Action: Explore Area
            energyCost = 25;
            xpGain = 120;
             // Example trait change: might affect Speed or Intelligence traits based on actionData
            // For instance, if actionData contains a seed, use it to determine a random outcome affecting traits.
             uint252 additionalXP = uint252(uint256(keccak256(actionData)) % 100); // Pseudo-random bonus
             xpGain = xpGain.add(additionalXP);

        } else {
            revert PGU_InvalidActionType(actionType);
        }

        if (pgu.energy < energyCost) {
            revert PGU_InsufficientEnergy(tokenId, energyCost, pgu.energy);
        }

        pgu.energy = pgu.energy.sub(energyCost);
        _grantXP(tokenId, xpGain);

        // Call _applyModEffects here if mods affect action outcomes or final traits
        _applyModEffects(tokenId);

        emit PGUActionPerformed(tokenId, actionType, energyCost, xpGain);
        emit PGULoaded(tokenId, pgu.xp, pgu.level, pgu.energy); // Indicate state update
    }

    /// @notice Triggers the level up process for a PGU if it has enough XP.
    /// @param tokenId The ID of the PGU.
    /// @dev Requires caller to own or be approved for the token.
    function levelUp(uint256 tokenId) external whenNotPaused {
        address owner = ownerOf(tokenId);
        if (msg.sender != owner && !isApprovedForAll(owner, msg.sender) && getApproved(tokenId) != msg.sender) {
            revert PGU_NotOwnerOrApproved(msg.sender, tokenId);
        }
        require(_pguData[tokenId].creationTime != 0, "PGU does not exist");

        PGU storage pgu = _pguData[tokenId];

        if (pgu.level >= xpRequiredForLevel.length - 1) {
             // Already at max defined level
             return; // Or revert? Silently doing nothing might be fine.
        }

        uint64 requiredXP = xpRequiredForLevel[pgu.level];
        if (pgu.xp < requiredXP) {
            revert PGU_NotEnoughXPForLevelUp(tokenId, requiredXP, pgu.xp);
        }

        // Deduct XP cost for the level up (cumulative vs cost per level depends on design)
        // Assuming xpRequiredForLevel is cumulative XP needed *to reach* the level,
        // the cost is the difference between current level requirement and next.
        uint64 cost = xpRequiredForLevel[pgu.level + 1].sub(xpRequiredForLevel[pgu.level]);
        pgu.xp = pgu.xp.sub(cost);

        // Level up happens inside _checkLevelUp, which is called by _grantXP.
        // Since we just deducted XP, _checkLevelUp won't auto-trigger from _grantXP here.
        // So we call it explicitly after deducting cost.
         _checkLevelUp(tokenId); // This updates level, modSlots, and emits LevelUp event.

        // Re-apply mod effects after level up, as mod slot count might have changed.
        _applyModEffects(tokenId);
    }

    /// @notice Adds a mod to a specific slot on a PGU.
    /// @param tokenId The ID of the PGU.
    /// @param slotId The slot ID (0-indexed) to add the mod to.
    /// @param modId The ID of the mod to add (non-zero).
    /// @dev Requires caller to own or be approved for the token. Requires an empty slot.
    function addMod(uint256 tokenId, uint8 slotId, uint256 modId) external whenNotPaused {
        address owner = ownerOf(tokenId);
        if (msg.sender != owner && !isApprovedForAll(owner, msg.sender) && getApproved(tokenId) != msg.sender) {
            revert PGU_NotOwnerOrApproved(msg.sender, tokenId);
        }
        require(_pguData[tokenId].creationTime != 0, "PGU does not exist");
        require(modId != 0, "Cannot add mod with ID 0 (reserved for empty)");

        PGU storage pgu = _pguData[tokenId];

        if (slotId >= pgu.modSlots) {
            revert PGU_InvalidModSlot(slotId, pgu.modSlots);
        }
        if (pgu.mods[slotId] != 0) {
            revert PGU_ModSlotOccupied(slotId, pgu.mods[slotId]);
        }

        pgu.mods[slotId] = modId;

        _applyModEffects(tokenId); // Re-calculate dynamic traits with the new mod

        emit ModAdded(tokenId, slotId, modId);
    }

    /// @notice Removes a mod from a specific slot on a PGU.
    /// @param tokenId The ID of the PGU.
    /// @param slotId The slot ID (0-indexed) to remove the mod from.
    /// @dev Requires caller to own or be approved for the token. Requires the slot to be occupied.
    function removeMod(uint256 tokenId, uint8 slotId) external whenNotPaused {
        address owner = ownerOf(tokenId);
        if (msg.sender != owner && !isApprovedForAll(owner, msg.sender) && getApproved(tokenId) != msg.sender) {
            revert PGU_NotOwnerOrApproved(msg.sender, tokenId);
        }
        require(_pguData[tokenId].creationTime != 0, "PGU does not exist");

        PGU storage pgu = _pguData[tokenId];

        if (slotId >= pgu.modSlots) {
            revert PGU_InvalidModSlot(slotId, pgu.modSlots);
        }
        if (pgu.mods[slotId] == 0) {
            revert PGU_ModSlotEmpty(slotId);
        }

        uint256 removedModId = pgu.mods[slotId];
        pgu.mods[slotId] = 0; // Set slot to empty

        _applyModEffects(tokenId); // Re-calculate dynamic traits without the mod

        emit ModRemoved(tokenId, slotId, removedModId);
    }


    /// @notice Allows two PGUs to interact with each other.
    /// @param pguIdA The ID of the first PGU.
    /// @param pguIdB The ID of the second PGU.
    /// @param interactionType The type of interaction (determines the rules and outcome).
    /// @dev Requires caller to own or be approved for *both* tokens. Can affect both PGUs.
    /// Interaction logic is highly complex and would rely on the interactionMatrix or similar rules.
    function interactWithPGU(uint256 pguIdA, uint256 pguIdB, uint8 interactionType) external whenNotPaused {
        if (pguIdA == pguIdB) {
            revert PGU_SamePGUInteraction(pguIdA);
        }

        address ownerA = ownerOf(pguIdA);
        address ownerB = ownerOf(pguIdB);

         if (msg.sender != ownerA && !isApprovedForAll(ownerA, msg.sender) && getApproved(pguIdA) != msg.sender) {
            revert PGU_NotOwnerOrApproved(msg.sender, pguIdA);
        }
         if (msg.sender != ownerB && !isApprovedForAll(ownerB, msg.sender) && getApproved(pguIdB) != msg.sender) {
            revert PGU_NotOwnerOrApproved(msg.sender, pguIdB);
        }

        require(_pguData[pguIdA].creationTime != 0, "PGU A does not exist");
        require(_pguData[pguIdB].creationTime != 0, "PGU B does not exist");

        _updateEnergy(pguIdA); // Update energy for both
        _updateEnergy(pguIdB);

        PGU storage pguA = _pguData[pguIdA];
        PGU storage pguB = _pguData[pguIdB];

        // --- Interaction Logic (Example) ---
        // This is where the complex rules based on interactionType, PGU states, etc., would go.
        // Referencing interactionMatrix: uint256 rules = interactionMatrix[interactionType];

        // Example Outcome: PGU A attacks PGU B
        uint16 energyCostA = 15; // Example costs
        uint16 energyCostB = 5;

        if (pguA.energy < energyCostA) revert PGU_InsufficientEnergy(pguIdA, energyCostA, pguA.energy);
        if (pguB.energy < energyCostB) revert PGU_InsufficientEnergy(pguIdB, energyCostB, pguB.energy);

        pguA.energy = pguA.energy.sub(energyCostA);
        pguB.energy = pguB.energy.sub(energyCostB);

        // Apply mod effects before interaction if they modify interaction power/defense
        _applyModEffects(pguIdA);
        _applyModEffects(pguIdB);

        uint256 traitsA = _unpackTraits(pguA.dynamicTraits);
        uint256 traitsB = _unpackTraits(pguB.dynamicTraits);

        uint8 attackA = uint8((traitsA >> TRAIT_ATTACK_BIT) & 0xFF);
        uint8 defenseB = uint8((traitsB >> TRAIT_DEFENSE_BIT) & 0xFF);

        uint64 xpGainA = 0;
        uint64 xpGainB = 0;
        uint256 oldTraitsA = pguA.dynamicTraits;
        uint256 oldTraitsB = pguB.dynamicTraits;

        // Simplified combat outcome:
        if (attackA > defenseB) {
            // A wins
            xpGainA = 80;
            xpGainB = 20; // Consolation XP
            // Maybe reduce a trait on B?
             uint8 newDefenseB = defenseB.sub(5); // Example trait reduction
             traitsB = (traitsB & ~(0xFF << TRAIT_DEFENSE_BIT)) | (uint256(newDefenseB) << TRAIT_DEFENSE_BIT);
             pguB.dynamicTraits = traitsB;

        } else {
            // B wins (or draw)
            xpGainA = 20;
            xpGainB = 80;
            // Maybe reduce a trait on A?
             uint8 newAttackA = attackA.sub(5);
             traitsA = (traitsA & ~(0xFF << TRAIT_ATTACK_BIT)) | (uint256(newAttackA) << TRAIT_ATTACK_BIT);
             pguA.dynamicTraits = traitsA;
        }

        _grantXP(pguIdA, xpGainA);
        _grantXP(pguIdB, xpGainB);

        // Emit trait changes if they occurred
        if (pguA.dynamicTraits != oldTraitsA) emit PGUDynamicTraitsChanged(pguIdA, oldTraitsA, pguA.dynamicTraits);
        if (pguB.dynamicTraits != oldTraitsB) emit PGUDynamicTraitsChanged(pguIdB, oldTraitsB, pguB.dynamicTraits);

        // More complex interactions could involve:
        // - Changing status flags on one or both
        // - Consuming/producing external resources (if integrated)
        // - Conditional outcomes based on genesis traits or mods

        emit PGUActionPerformed(pguIdA, interactionType, energyCostA, xpGainA); // Log action for A
        emit PGUActionPerformed(pguIdB, interactionType, energyCostB, xpGainB); // Log action for B
        emit PGULoaded(pguIdA, pguA.xp, pguA.level, pguA.energy); // Indicate state update for A
        emit PGULoaded(pguIdB, pguB.xp, pguB.level, pguB.energy); // Indicate state update for B

    }

    /// @notice Explicitly updates a PGU's energy based on elapsed time.
    /// @param tokenId The ID of the PGU.
    /// @dev Requires caller to own or be approved for the token. Useful to "top up" energy before an action if needed.
    function refuelEnergyExplicit(uint256 tokenId) external whenNotPaused {
        address owner = ownerOf(tokenId);
         if (msg.sender != owner && !isApprovedForAll(owner, msg.sender) && getApproved(tokenId) != msg.sender) {
            revert PGU_NotOwnerOrApproved(msg.sender, tokenId);
        }
        require(_pguData[tokenId].creationTime != 0, "PGU does not exist");
        _updateEnergy(tokenId); // This is enough, the internal function handles the logic.
        // PGULoaded event is emitted by _updateEnergy
    }


    // --- Configuration Functions (Owner-only) ---

    /// @notice Sets parameters for energy regeneration.
    /// @param rate The amount of energy regenerated per interval.
    /// @param intervalSeconds The duration of the regeneration interval in seconds.
    /// @dev Only callable by the contract owner.
    function setEnergyRegenParams(uint16 rate, uint48 intervalSeconds) external onlyOwner {
        ENERGY_REGEN_RATE = rate;
        ENERGY_REGEN_INTERVAL_SECONDS = intervalSeconds;
    }

    /// @notice Sets the cumulative XP required for each level.
    /// @param xpLevels Array where index is the level, and value is the total XP needed to reach that level.
    /// @dev Only callable by the contract owner. xpLevels[0] must be 0. Array must be increasing.
    function setXPPerLevel(uint64[] memory xpLevels) external onlyOwner {
         require(xpLevels.length > 0 && xpLevels[0] == 0, "Invalid XP array");
         for (uint i = 1; i < xpLevels.length; i++) {
             require(xpLevels[i] >= xpLevels[i-1], "XP levels must be non-decreasing");
         }
         xpRequiredForLevel = xpLevels;
         // Note: Existing PGUs will use the new curve on their next level up check.
    }

     /// @notice Sets the maximum mod slots available at each level.
     /// @param modSlotsByLevelArray Array where index is the level, and value is the number of slots.
     /// @dev Only callable by the contract owner. Array length should match or exceed XP levels array length.
     function setModSlotsPerLevel(uint8[] memory modSlotsByLevelArray) external onlyOwner {
         // It's good practice to ensure this array covers at least all levels defined in xpRequiredForLevel.
         require(modSlotsByLevelArray.length >= xpRequiredForLevel.length, "Mod slot array too short for defined XP levels");
         modSlotsByLevel = modSlotsByLevelArray;
         // Note: Existing PGUs will get the new mod slot count next time they level up.
         // Or you could add a function to update mod slots for all PGUs on config change (gas heavy).
     }


    /// @notice Sets a rule entry in the interaction matrix.
    /// @param interactionType The type of interaction being configured.
    /// @param encodedRules A packed value representing the rules/outcomes for this interaction type.
    /// @dev Only callable by the contract owner. The interpretation of encodedRules is application-specific.
    function setInteractionMatrix(uint8 interactionType, uint256 encodedRules) external onlyOwner {
        interactionMatrix[interactionType] = encodedRules;
        // Event could be useful here: event InteractionRulesUpdated(uint8 indexed interactionType, uint256 encodedRules);
    }

    // --- Utility Functions ---

    /// @notice Allows the contract owner to withdraw collected Ether.
    /// @dev Only callable by the contract owner.
    function withdrawBalance() external onlyOwner {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Withdraw failed");
    }

    /// @notice Pauses the contract.
    /// @dev Only callable by the contract owner. Inherited from Pausable.
    function pause() external onlyOwner {
        _pause();
    }

    /// @notice Unpauses the contract.
    /// @dev Only callable by the contract owner. Inherited from Pausable.
    function unpause() external onlyOwner {
        _unpause();
    }

    // The contract needs to receive Ether to allow `withdrawBalance` to work.
    // This requires a `receive` or `fallback` function.
    receive() external payable {}
    // fallback() external payable {} // Consider adding if you need to handle calls to undefined functions


    // --- Internal PGU Accessors for Read-Only Use ---
    // Useful if you need to pass PGU data around internally without modifying storage

    function _getPGU(uint256 tokenId) internal view returns (PGU memory) {
        require(_pguData[tokenId].creationTime != 0, "PGU does not exist");
        // Note: This returns a memory copy. Modifications to the returned struct will not persist.
        // Does NOT update energy automatically.
        return _pguData[tokenId];
    }

     // Function to iterate mods for external view (example)
     function getEquippedMods(uint256 tokenId) external view returns (uint256[] memory) {
         require(_pguData[tokenId].creationTime != 0, "PGU does not exist");
         PGU storage pgu = _pguData[tokenId];
         uint256[] memory equipped = new uint256[](pgu.modSlots);
         for (uint8 i = 0; i < pgu.modSlots; i++) {
             equipped[i] = pgu.mods[i];
         }
         return equipped;
     }
}
```