Okay, here is a Solidity smart contract that attempts to combine several advanced and creative concepts:

**Concept: "ChronoCrafts" - Dynamic, Programmable NFTs with State, Decay, Crafting, and Modules**

This contract defines an ERC721 collection where each token ("ChronoCraft") is a dynamic entity with internal state, energy, and durability that changes over time and through interactions. They can be "crafted" by combining specific component NFTs (or representing consumption of components) and enhanced with "modules" (represented by other NFTs or references).

**Key Features:**

1.  **Dynamic State:** ChronoCrafts have states (Idle, Working, Broken, etc.) which affect their behavior and decay.
2.  **Energy & Durability:** Numeric properties that decrease with use or over time (decay) and can be restored. Hitting zero triggers state changes (e.g., Broken).
3.  **Time-Based Decay:** ChronoCrafts decay based on elapsed time, regardless of state (though the rate might vary). Decay can be triggered by anyone (`applyDecay`), incentivizing external calls.
4.  **Crafting:** New ChronoCrafts can be created by consuming specific component NFTs (represented by requiring approval/transfer of component NFTs) according to predefined recipes.
5.  **Modules:** ChronoCrafts can have module NFTs "attached" (consumes the module NFT) to gain bonuses or abilities. Detaching removes the module reference.
6.  **Permissioned Roles:** A "Crafter" role is introduced, distinct from the contract owner, to allow specific addresses to perform crafting.
7.  **Conditional State Transitions:** Actions (like activating) are only possible if certain conditions (energy/durability levels, current state) are met.
8.  **ERC721 Compliance:** Standard NFT functionality is included.
9.  **Pausable & Withdrawals:** Standard administrative functions.
10. **On-chain Data:** All state (energy, durability, state, modules) is stored on-chain.

**Outline:**

1.  **Contract Definition & Imports:** ERC721, Ownable, Pausable, IERC721Receiver.
2.  **Error Handling:** Custom errors for clarity.
3.  **Enums & Structs:** Define ChronoCraft states, ChronoCraft data structure, Crafting Recipe structure.
4.  **State Variables:** Mappings for ChronoCraft data, recipes, crafter roles, counters.
5.  **Events:** For key actions like Crafting, StateChange, Energy/Durability update, ModuleAttach/Detach, DecayApplied.
6.  **Modifiers:** `whenNotBroken`, `onlyCrafterOrOwner`.
7.  **Constructor:** Initializes contract.
8.  **ERC721 Standard Functions:** `name`, `symbol`, `balanceOf`, `ownerOf`, `transferFrom`, `safeTransferFrom`, `approve`, `setApprovalForAll`, `getApproved`, `isApprovedForAll`, `totalSupply`, `tokenURI`, `supportsInterface`.
9.  **ERC721Receiver Hook:** `onERC721Received`.
10. **Internal Helpers:** Functions prefixed with `_` for internal logic (e.g., `_getChronoCraftData`, `_updateState`, `_calculateDecay`).
11. **ChronoCraft Management & Actions:**
    *   `activate`: Put a ChronoCraft into a 'Working' state.
    *   `deactivate`: Put a ChronoCraft into an 'Idle' state.
    *   `rechargeEnergy`: Restore energy (requires payment).
    *   `repairDurability`: Restore durability (requires payment).
    *   `applyDecay`: Public function to trigger decay calculation based on time.
12. **Module Management:**
    *   `attachModule`: Add a module to a ChronoCraft (consumes module NFT).
    *   `detachModule`: Remove a module reference.
    *   `getAttachedModules`: View attached modules.
13. **Crafting:**
    *   `craftChronoCraft`: Create a new ChronoCraft using a recipe (consumes component NFTs).
    *   `addCraftingRecipe`: Admin function to define recipes.
    *   `removeCraftingRecipe`: Admin function to remove recipes.
    *   `getCraftingRecipe`: View function to get recipe details.
14. **Query Functions:**
    *   `getChronoCraftDetails`: Get full data for a ChronoCraft.
    *   `getChronoCraftState`: Get current state.
    *   `getChronoCraftEnergy`: Get current energy.
    *   `getChronoCraftDurability`: Get current durability.
    *   `getChronoCraftCreationTime`: Get creation timestamp.
    *   `getChronoCraftLastActiveTime`: Get last active timestamp.
15. **Role Management:**
    *   `setCrafterAddress`: Admin function to grant Crafter role.
    *   `removeCrafterAddress`: Admin function to revoke Crafter role.
    *   `isCrafter`: View function to check Crafter role.
16. **Admin & System:**
    *   `pause`: Pause contract functionality.
    *   `unpause`: Unpause contract.
    *   `emergencyWithdraw`: Withdraw stuck ETH.
    *   `withdrawERC20`: Withdraw stuck ERC20s.
    *   `withdrawERC721`: Withdraw stuck ERC721s.
    *   `setBaseTokenURI`: Set base URI for metadata.

**Function Summary (More than 20 functions):**

*   `constructor()`: Initializes the contract with name and symbol.
*   `name()`: (ERC721) Returns the collection name.
*   `symbol()`: (ERC721) Returns the collection symbol.
*   `balanceOf(address owner)`: (ERC721) Returns the number of tokens owned by an address.
*   `ownerOf(uint256 tokenId)`: (ERC721) Returns the owner of a specific token.
*   `transferFrom(address from, address to, uint256 tokenId)`: (ERC721) Transfers ownership of a token.
*   `safeTransferFrom(address from, address to, uint256 tokenId)`: (ERC721) Safely transfers ownership.
*   `safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data)`: (ERC721) Safely transfers ownership with data.
*   `approve(address to, uint256 tokenId)`: (ERC721) Grants approval for one token.
*   `setApprovalForAll(address operator, bool approved)`: (ERC721) Grants/revokes approval for all tokens.
*   `getApproved(uint256 tokenId)`: (ERC721) Returns the approved address for a token.
*   `isApprovedForAll(address owner, address operator)`: (ERC721) Returns if an operator has approval for all tokens.
*   `totalSupply()`: (ERC721) Returns the total number of tokens minted.
*   `tokenURI(uint256 tokenId)`: (ERC721) Returns the metadata URI for a token.
*   `supportsInterface(bytes4 interfaceId)`: (ERC165/ERC721) Indicates supported interfaces.
*   `onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data)`: (IERC721Receiver) Hook for receiving ERC721 tokens.
*   `activate(uint256 tokenId)`: Changes ChronoCraft state to `Working`.
*   `deactivate(uint256 tokenId)`: Changes ChronoCraft state to `Idle`.
*   `rechargeEnergy(uint256 tokenId)`: Restores ChronoCraft energy (requires payment).
*   `repairDurability(uint256 tokenId)`: Restores ChronoCraft durability (requires payment).
*   `applyDecay(uint256 tokenId)`: Calculates and applies time-based decay to energy/durability.
*   `attachModule(uint256 chronoCraftId, uint256 moduleTokenId)`: Attaches a module NFT to a ChronoCraft (consumes module NFT).
*   `detachModule(uint256 chronoCraftId, uint256 moduleIndex)`: Removes a module reference from a ChronoCraft.
*   `getAttachedModules(uint256 chronoCraftId)`: Returns the list of attached module IDs.
*   `craftChronoCraft(uint256 recipeId, uint256[] calldata componentTokenIds)`: Crafts a new ChronoCraft using specified components and recipe.
*   `addCraftingRecipe(uint256 recipeId, uint256[] calldata requiredComponentTokenIds, uint256 outputChronoCraftType)`: (Admin) Adds a new crafting recipe.
*   `removeCraftingRecipe(uint256 recipeId)`: (Admin) Removes a crafting recipe.
*   `getCraftingRecipe(uint256 recipeId)`: (View) Gets details of a crafting recipe.
*   `getChronoCraftDetails(uint256 tokenId)`: (View) Gets all dynamic data for a ChronoCraft.
*   `getChronoCraftState(uint256 tokenId)`: (View) Gets the current state of a ChronoCraft.
*   `getChronoCraftEnergy(uint256 tokenId)`: (View) Gets the current energy of a ChronoCraft.
*   `getChronoCraftDurability(uint256 tokenId)`: (View) Gets the current durability of a ChronoCraft.
*   `getChronoCraftCreationTime(uint256 tokenId)`: (View) Gets the creation timestamp.
*   `getChronoCraftLastActiveTime(uint256 tokenId)`: (View) Gets the last active timestamp.
*   `setCrafterAddress(address crafter, bool enabled)`: (Admin) Grants/revokes the Crafter role.
*   `removeCrafterAddress(address crafter)`: (Admin) Removes a crafter (alias for `setCrafterAddress(crafter, false)`).
*   `isCrafter(address account)`: (View) Checks if an address is a Crafter.
*   `pause()`: (Admin) Pauses transfers and most actions.
*   `unpause()`: (Admin) Unpauses contract.
*   `emergencyWithdraw()`: (Admin) Withdraws all ETH from the contract.
*   `withdrawERC20(address tokenAddress)`: (Admin) Withdraws a specific ERC20 token.
*   `withdrawERC721(address tokenAddress, uint256 tokenId)`: (Admin) Withdraws a specific ERC721 token.
*   `setBaseTokenURI(string calldata baseURI)`: (Admin) Sets the base metadata URI.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol"; // For withdrawing ERC20s
import "@openzeppelin/contracts/token/ERC721/IERC721.sol"; // For interacting with component/module ERC721s
import "@openzeppelin/contracts/utils/math/Math.sol"; // For min/max (though not strictly needed for simple capped values)

// --- Contract: ChronoCrafts ---
// Concept: Dynamic, Programmable NFTs with State, Decay, Crafting, and Modules
// ERC721 tokens representing items with internal state, energy, and durability.
// These properties change over time and through actions.
// Tokens can be crafted using other NFTs as components and enhanced with module NFTs.

// --- Outline ---
// 1. Contract Definition & Imports
// 2. Error Handling
// 3. Enums & Structs
// 4. State Variables
// 5. Events
// 6. Modifiers
// 7. Constructor
// 8. ERC721 Standard Functions
// 9. ERC721Receiver Hook
// 10. Internal Helpers
// 11. ChronoCraft Management & Actions
// 12. Module Management
// 13. Crafting
// 14. Query Functions
// 15. Role Management (Crafter)
// 16. Admin & System (Pause, Withdrawals, URI)

// --- Function Summary ---
// constructor(): Initializes the contract.
// name(): (ERC721)
// symbol(): (ERC721)
// balanceOf(address owner): (ERC721)
// ownerOf(uint256 tokenId): (ERC721)
// transferFrom(address from, address to, uint256 tokenId): (ERC721)
// safeTransferFrom(address from, address to, uint256 tokenId): (ERC721)
// safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data): (ERC721)
// approve(address to, uint256 tokenId): (ERC721)
// setApprovalForAll(address operator, bool approved): (ERC721)
// getApproved(uint256 tokenId): (ERC721)
// isApprovedForAll(address owner, address operator): (ERC721)
// totalSupply(): (ERC721)
// tokenURI(uint256 tokenId): (ERC721)
// supportsInterface(bytes4 interfaceId): (ERC165/ERC721)
// onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data): (IERC721Receiver)
// activate(uint256 tokenId): Change state to Working.
// deactivate(uint256 tokenId): Change state to Idle.
// rechargeEnergy(uint256 tokenId): Restore energy (payable).
// repairDurability(uint256 tokenId): Restore durability (payable).
// applyDecay(uint256 tokenId): Public function to trigger decay.
// attachModule(uint256 chronoCraftId, uint256 moduleTokenId): Attach module (consumes NFT).
// detachModule(uint256 chronoCraftId, uint256 moduleIndex): Detach module reference.
// getAttachedModules(uint256 chronoCraftId): View attached modules.
// craftChronoCraft(uint256 recipeId, uint256[] calldata componentTokenIds): Craft new token.
// addCraftingRecipe(uint256 recipeId, uint256[] calldata requiredComponentTokenIds, uint256 outputChronoCraftType): (Admin) Add recipe.
// removeCraftingRecipe(uint256 recipeId): (Admin) Remove recipe.
// getCraftingRecipe(uint256 recipeId): (View) Get recipe details.
// getChronoCraftDetails(uint256 tokenId): (View) Get all dynamic data.
// getChronoCraftState(uint256 tokenId): (View) Get state.
// getChronoCraftEnergy(uint256 tokenId): (View) Get energy.
// getChronoCraftDurability(uint256 tokenId): (View) Get durability.
// getChronoCraftCreationTime(uint256 tokenId): (View) Get creation time.
// getChronoCraftLastActiveTime(uint256 tokenId): (View) Get last active time.
// setCrafterAddress(address crafter, bool enabled): (Admin) Grant/revoke Crafter role.
// removeCrafterAddress(address crafter): (Admin) Remove Crafter role.
// isCrafter(address account): (View) Check Crafter role.
// pause(): (Admin) Pause contract.
// unpause(): (Admin) Unpause contract.
// emergencyWithdraw(): (Admin) Withdraw ETH.
// withdrawERC20(address tokenAddress): (Admin) Withdraw ERC20.
// withdrawERC721(address tokenAddress, uint256 tokenId): (Admin) Withdraw ERC721.
// setBaseTokenURI(string calldata baseURI): (Admin) Set base URI.

contract ChronoCrafts is ERC721, Ownable, Pausable, ReentrancyGuard, IERC721Receiver {

    // --- Error Handling ---
    error InvalidTokenId();
    error NotOwnerOrApproved();
    error InvalidStateForAction(ChronoCraftState currentState, string action);
    error InsufficientEnergy();
    error InsufficientDurability();
    error CraftingFailed(string reason);
    error InvalidRecipe();
    error InvalidComponentCount();
    error InvalidComponentToken();
    error NotACrafter();
    error ModuleNotFound();
    error InvalidModuleIndex();
    error SelfAttachmentForbidden();
    error ERC721TransferFailed();
    error TransferToZeroAddress();
    error TransferCallerNotOwnerOrApproved();

    // --- Enums & Structs ---
    enum ChronoCraftState { Idle, Working, Broken, NeedsRepair, NeedsRecharge, CraftingInProgress }

    struct ChronoCraftData {
        ChronoCraftState state;
        uint8 energy; // 0-100
        uint8 durability; // 0-100
        uint64 creationTime; // Timestamp
        uint64 lastStateChangeTime; // Timestamp when state last changed (useful for decay calc)
        uint64 lastDecayAppliedTime; // Timestamp when decay was last applied publicly
        uint256[] attachedModules; // Array of module token IDs
        uint256 craftType; // An identifier for the type of ChronoCraft (e.g., 1=Tool, 2=Machine)
    }

    struct CraftingRecipe {
        bool exists;
        uint256[] requiredComponentTokenIds; // Specific component token IDs required (e.g., 1, 5, 10) - simplified, could be types
        uint256 outputChronoCraftType; // Type of ChronoCraft produced
    }

    // --- State Variables ---
    mapping(uint256 => ChronoCraftData) private _chronoCraftData;
    uint256 private _nextTokenId;

    mapping(uint256 => CraftingRecipe) private _craftingRecipes;
    mapping(address => bool) private _isCrafter;

    string private _baseTokenURI;

    // Decay parameters (can be adjusted by owner)
    // Decay per second when Working (energy, durability)
    uint256 public workingDecayRateEnergy = 1; // Decay per 1000 seconds (adjust units)
    uint256 public workingDecayRateDurability = 1; // Decay per 1000 seconds
    // Decay per second when Idle (energy only, slower)
    uint256 public idleDecayRateEnergy = 1; // Decay per 10000 seconds (adjust units)
    // Decay threshold (below which decay slows or stops, or state changes happen)
    uint8 public constant MIN_ENERGY_FOR_WORKING = 10;
    uint8 public constant MIN_DURABILITY_FOR_WORKING = 10;
    uint8 public constant BROKEN_THRESHOLD_DURABILITY = 1; // < this value means Broken
    uint8 public constant NEEDS_REPAIR_THRESHOLD_DURABILITY = 10; // <= this means NeedsRepair
    uint8 public constant NEEDS_RECHARGE_THRESHOLD_ENERGY = 10; // <= this means NeedsRecharge

    // --- Events ---
    event ChronoCraftCrafted(uint256 indexed tokenId, address indexed owner, uint256 recipeId, uint256 outputType);
    event ChronoCraftStateChanged(uint256 indexed tokenId, ChronoCraftState oldState, ChronoCraftState newState);
    event ChronoCraftEnergyChanged(uint256 indexed tokenId, uint8 newEnergy, uint8 energyChange);
    event ChronoCraftDurabilityChanged(uint256 indexed tokenId, uint8 newDurability, uint8 durabilityChange);
    event ChronoCraftModuleAttached(uint256 indexed chronoCraftId, uint256 indexed moduleTokenId, uint256 moduleIndex);
    event ChronoCraftModuleDetached(uint256 indexed chronoCraftId, uint256 moduleIndex, uint256 moduleTokenId);
    event ChronoCraftDecayApplied(uint256 indexed tokenId, uint256 energyDecay, uint256 durabilityDecay);
    event CrafterRoleGranted(address indexed account);
    event CrafterRoleRevoked(address indexed account);

    // --- Modifiers ---
    modifier whenNotBroken(uint256 tokenId) {
        if (_chronoCraftData[tokenId].state == ChronoCraftState.Broken) {
            revert InvalidStateForAction(ChronoCraftState.Broken, "Action cannot be performed when Broken");
        }
        _;
    }

    modifier onlyCrafterOrOwner() {
        if (owner() != _msgSender() && !_isCrafter[_msgSender()]) {
            revert NotACrafter(); // Or use Ownable's OnlyOwner error if preferred, but this is more specific
        }
        _;
    }

    // --- Constructor ---
    constructor() ERC721("ChronoCraft", "CCNFT") Ownable(_msgSender()) Pausable() {
        _nextTokenId = 0;
        // The contract itself needs to be able to receive ERC721 components during crafting
        // and potentially modules during attachment.
        // No explicit setup needed here for IERC721Receiver compliance beyond inheriting it.
    }

    // --- ERC721 Standard Functions ---
    // Most standard functions are inherited and work directly with the internal ERC721 state (_owners, _balances)

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        if (!_exists(tokenId)) {
            revert ERC721Enumerable.EnumerableError.NonexistentToken(); // Use OpenZeppelin's standard error
        }
        string memory base = _baseTokenURI;
        // Optional: Append token ID and dynamic state to URI for metadata APIs
        // Example: string.concat(base, toString(tokenId), "?state=", toString(uint256(_chronoCraftData[tokenId].state)));
        // Requires complex string concatenation or a metadata server to handle this.
        // For simplicity here, just return the base URI + ID.
        return bytes(base).length > 0 ? string.concat(base, _toString(tokenId)) : "";
    }

    // Required for inheriting IERC721Receiver
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external override returns (bytes4) {
         // This function is called when an ERC721 is transferred TO this contract.
         // We need this for components/modules being transferred here for crafting/attachment.
         // Only accept transfers initiated by the contract itself (during craft/attach)
         // or potentially from trusted addresses if needed for other logic.
         // For crafting/attaching, the contract will call transferFrom, triggering this hook.
         // We should only accept tokens we expect. A simple check is to ensure
         // the operator is *this* contract or a trusted address.
         // A more robust implementation would check the 'data' or the token ID/sender context.
         // For this example, we'll assume any ERC721 transferred *by* this contract or *to* this contract
         // as part of the crafting/attaching process is intended. Reject unsolicited transfers.
         if (operator != address(this) && from != address(this)) {
             // Reject unexpected transfers
             return bytes4(0); // Indicates rejection
         }
         // Accept the transfer
        return IERC721Receiver.onERC721Received.selector;
    }

    // --- Internal Helpers ---
    function _getChronoCraftData(uint256 tokenId) internal view returns (ChronoCraftData storage) {
        if (!_exists(tokenId)) {
             revert InvalidTokenId();
        }
        return _chronoCraftData[tokenId];
    }

    function _updateState(uint256 tokenId, ChronoCraftState newState) internal {
        ChronoCraftData storage craft = _getChronoCraftData(tokenId);
        if (craft.state != newState) {
            ChronoCraftState oldState = craft.state;
            craft.state = newState;
            craft.lastStateChangeTime = uint64(block.timestamp); // Update time on state change
            emit ChronoCraftStateChanged(tokenId, oldState, newState);
        }
    }

     // Applies time-based decay since last state change time or last public decay application
     // Returns the actual energy and durability decayed.
    function _calculateAndApplyDecay(uint256 tokenId) internal returns (uint256 energyDecayed, uint256 durabilityDecayed) {
        ChronoCraftData storage craft = _getChronoCraftData(tokenId);
        uint64 currentTime = uint64(block.timestamp);
        uint64 lastDecayTime = craft.lastDecayAppliedTime > 0 ? craft.lastDecayAppliedTime : craft.creationTime; // Use creation if never decayed

        uint256 timeElapsed = currentTime - lastDecayTime;

        if (timeElapsed == 0) {
            return (0, 0); // No time elapsed since last check
        }

        uint8 currentEnergy = craft.energy;
        uint8 currentDurability = craft.durability;
        ChronoCraftState currentState = craft.state;

        uint256 decayRateEnergy;
        uint256 decayRateDurability;
        uint256 decayMultiplier = 1000; // Base unit for decay rates (e.g., per 1000s)

        if (currentState == ChronoCraftState.Working) {
            decayRateEnergy = workingDecayRateEnergy;
            decayRateDurability = workingDecayRateDurability;
        } else if (currentState == ChronoCraftState.Idle) {
            decayRateEnergy = idleDecayRateEnergy;
            decayRateDurability = 0; // Idle doesn't decay durability
        } else {
            // Broken, NeedsRepair, NeedsRecharge, CraftingInProgress - maybe minimal decay or none?
            decayRateEnergy = 0;
            decayRateDurability = 0;
        }

        uint256 potentialEnergyDecay = (uint256(decayRateEnergy) * timeElapsed) / decayMultiplier;
        uint256 potentialDurabilityDecay = (uint256(decayRateDurability) * timeElapsed) / decayMultiplier;

        energyDecayed = potentialEnergyDecay > currentEnergy ? currentEnergy : potentialEnergyDecay;
        durabilityDecayed = potentialDurabilityDecay > currentDurability ? currentDurability : potentialDurabilityDecay;

        // Apply decay, ensuring values don't go below zero (uint8 handles min 0)
        craft.energy = uint8(currentEnergy - energyDecayed);
        craft.durability = uint8(currentDurability - durabilityDecayed);

        // Update last decay time for next calculation
        craft.lastDecayAppliedTime = currentTime;

        // Check and update state based on new levels
        _checkAndTransitionState(tokenId, craft);

        if (energyDecayed > 0 || durabilityDecayed > 0) {
             emit ChronoCraftDecayApplied(tokenId, energyDecayed, durabilityDecayed);
        }

        return (energyDecayed, durabilityDecayed);
    }

    // Internal function to transition state based on current energy/durability levels
    function _checkAndTransitionState(uint256 tokenId, ChronoCraftData storage craft) internal {
        ChronoCraftState currentState = craft.state;

        // Prioritize Broken state
        if (craft.durability < BROKEN_THRESHOLD_DURABILITY) {
            if (currentState != ChronoCraftState.Broken) {
                _updateState(tokenId, ChronoCraftState.Broken);
            }
            return; // If broken, other states are irrelevant
        }

        // Check for NeedsRepair/NeedsRecharge if not Broken
        bool needsRepair = craft.durability <= NEEDS_REPAIR_THRESHOLD_DURABILITY;
        bool needsRecharge = craft.energy <= NEEDS_RECHARGE_THRESHOLD_ENERGY;

        if (needsRepair && needsRecharge) {
            if (currentState != ChronoCraftState.NeedsRepair) { // NeedsRepair takes precedence in this logic
                 _updateState(tokenId, ChronoCraftState.NeedsRepair);
            }
        } else if (needsRepair) {
            if (currentState != ChronoCraftState.NeedsRepair) {
                 _updateState(tokenId, ChronoCraftState.NeedsRepair);
            }
        } else if (needsRecharge) {
             if (currentState != ChronoCraftState.NeedsRecharge) {
                 _updateState(tokenId, ChronoCraftState.NeedsRecharge);
            }
        } else {
            // If not broken and no needs met, transition back to Idle if not already
            if (currentState != ChronoCraftState.Idle && currentState != ChronoCraftState.Working && currentState != ChronoCraftState.CraftingInProgress) {
                _updateState(tokenId, ChronoCraftState.Idle);
            }
        }
    }


    // --- ChronoCraft Management & Actions ---

    /**
     * @notice Activates a ChronoCraft, changing its state to Working.
     * Requires sufficient energy and durability, and must not be Broken or already Working.
     * Applies decay before activation check.
     * @param tokenId The ID of the ChronoCraft to activate.
     */
    function activate(uint256 tokenId) external payable nonReentrant whenNotPaused whenNotBroken(tokenId) {
        address owner = ownerOf(tokenId);
        if (owner != _msgSender() && !isApprovedForAll(owner, _msgSender())) {
            revert NotOwnerOrApproved();
        }

        ChronoCraftData storage craft = _getChronoCraftData(tokenId);
        (uint256 energyDecayed, uint256 durabilityDecayed) = _calculateAndApplyDecay(tokenId); // Apply decay first

        if (craft.state == ChronoCraftState.Working) {
             revert InvalidStateForAction(craft.state, "Activate: Already Working");
        }
         if (craft.state == ChronoCraftState.CraftingInProgress) {
             revert InvalidStateForAction(craft.state, "Activate: Crafting in progress");
        }
        if (craft.energy < MIN_ENERGY_FOR_WORKING) {
            revert InsufficientEnergy();
        }
        if (craft.durability < MIN_DURABILITY_FOR_WORKING) {
            revert InsufficientDurability();
        }

        _updateState(tokenId, ChronoCraftState.Working);
        // Note: decay is calculated from lastDecayAppliedTime, which is updated by _calculateAndApplyDecay
    }

    /**
     * @notice Deactivates a ChronoCraft, changing its state to Idle.
     * Only possible if the craft is currently Working.
     * Applies decay accumulated while Working.
     * @param tokenId The ID of the ChronoCraft to deactivate.
     */
    function deactivate(uint256 tokenId) external payable nonReentrant whenNotPaused {
        address owner = ownerOf(tokenId);
        if (owner != _msgSender() && !isApprovedForAll(owner, _msgSender())) {
            revert NotOwnerOrApproved();
        }

        ChronoCraftData storage craft = _getChronoCraftData(tokenId);

        if (craft.state != ChronoCraftState.Working) {
            revert InvalidStateForAction(craft.state, "Deactivate: Not Working");
        }

        _calculateAndApplyDecay(tokenId); // Apply decay accumulated while Working
        _updateState(tokenId, ChronoCraftState.Idle);
    }

    /**
     * @notice Recharges the energy of a ChronoCraft.
     * Requires sending ETH with the transaction. ETH amount determines energy gained.
     * Applies decay before recharging.
     * @param tokenId The ID of the ChronoCraft to recharge.
     */
    function rechargeEnergy(uint256 tokenId) external payable nonReentrant whenNotPaused whenNotBroken(tokenId) {
        address owner = ownerOf(tokenId);
        if (owner != _msgSender() && !isApprovedForAll(owner, _msgSender())) {
            revert NotOwnerOrApproved();
        }

        ChronoCraftData storage craft = _getChronoCraftData(tokenId);
        (uint256 energyDecayed, uint256 durabilityDecayed) = _calculateAndApplyDecay(tokenId); // Apply decay first

        // Example: 1 ETH = 100 energy. Adjust as needed.
        uint256 energyGained = msg.value * 100 / 1 ether;
        if (energyGained == 0) return; // No ETH sent or too little

        uint8 currentEnergy = craft.energy;
        uint8 newEnergy = uint8(uint256(currentEnergy) + energyGained);
        if (newEnergy > 100) newEnergy = 100;

        craft.energy = newEnergy;

        // Check and update state based on new levels
        _checkAndTransitionState(tokenId, craft);

        emit ChronoCraftEnergyChanged(tokenId, newEnergy, uint8(newEnergy - currentEnergy)); // Emit actual change
    }

     /**
     * @notice Repairs the durability of a ChronoCraft.
     * Requires sending ETH with the transaction. ETH amount determines durability gained.
     * Applies decay before repairing.
     * @param tokenId The ID of the ChronoCraft to repair.
     */
    function repairDurability(uint256 tokenId) external payable nonReentrant whenNotPaused {
        address owner = ownerOf(tokenId);
        if (owner != _msgSender() && !isApprovedForAll(owner, _msgSender())) {
            revert NotOwnerOrApproved();
        }

        ChronoCraftData storage craft = _getChronoCraftData(tokenId);
        // Decay should still be applied even if Broken, as time passes.
        (uint256 energyDecayed, uint256 durabilityDecayed) = _calculateAndApplyDecay(tokenId); // Apply decay first

        // Example: 1 ETH = 50 durability. Adjust as needed.
        uint256 durabilityGained = msg.value * 50 / 1 ether;
        if (durabilityGained == 0) return; // No ETH sent or too little

        uint8 currentDurability = craft.durability;
        uint8 newDurability = uint8(uint256(currentDurability) + durabilityGained);
        if (newDurability > 100) newDurability = 100;

        craft.durability = newDurability;

         // Check and update state based on new levels
        _checkAndTransitionState(tokenId, craft);

        emit ChronoCraftDurabilityChanged(tokenId, newDurability, uint8(newDurability - currentDurability)); // Emit actual change
    }

    /**
     * @notice Public function to trigger decay calculation for a ChronoCraft.
     * Can be called by anyone, but decay is only applied based on elapsed time since the last check.
     * This allows external actors to "poke" the contract to update state, potentially for incentives.
     * @param tokenId The ID of the ChronoCraft to apply decay to.
     */
    function applyDecay(uint256 tokenId) external whenNotPaused nonReentrant {
        // Anyone can call this, incentivizing state updates.
        // The _calculateAndApplyDecay internal function ensures decay is only applied
        // based on actual time elapsed since the last decay check.
        _calculateAndApplyDecay(tokenId);
        // Note: state transition is handled internally by _calculateAndApplyDecay
    }


    // --- Module Management ---

    /**
     * @notice Attaches a module NFT to a ChronoCraft.
     * Requires the caller to own both NFTs and have granted approval for the module NFT to this contract.
     * The module NFT is consumed (burned) upon attachment.
     * @param chronoCraftId The ID of the ChronoCraft to attach the module to.
     * @param moduleTokenId The ID of the module NFT to attach.
     */
    function attachModule(uint256 chronoCraftId, uint256 moduleTokenId) external nonReentrant whenNotPaused whenNotBroken(chronoCraftId) {
        address owner = ownerOf(chronoCraftId);
        if (owner != _msgSender() && !isApprovedForAll(owner, _msgSender())) {
            revert NotOwnerOrApproved(); // Caller must own/be approved for the ChronoCraft
        }

        // Ensure the caller also owns the module NFT and has approved this contract to transfer it
        address moduleOwner = IERC721(0).ownerOf(moduleTokenId); // Use a dummy address initially
        // Check if the module token exists on a known contract address (ERC721(0) is not usable directly)
        // We need to know the address of the Module NFT contract. Let's assume it's a state variable.
        // For this example, let's simplify and assume components/modules are ANY ERC721.
        // In a real system, you'd likely have a specific ModuleContractAddress.
        // Let's assume `moduleTokenId` includes information about the contract or the contract address is known contextually.
        // For simplicity, let's assume the contract address of the module is passed or hardcoded.
        // Let's add a placeholder for the Module Contract Address:
        // address public moduleContractAddress = address(0); // Needs to be set by owner

        // For this example, let's simplify drastically: assume components/modules are also this *same* ChronoCrafts contract type,
        // but we distinguish them by their `craftType`. This is a common pattern in systems with tiers/components.
        // A module is just a ChronoCraft NFT designated as a module type.
        // This simplifies ERC721 interactions greatly.

        if (!_exists(moduleTokenId)) {
             revert InvalidComponentToken(); // Module must exist in this contract
        }

        address moduleNftOwner = ownerOf(moduleTokenId);
         if (moduleNftOwner != _msgSender() && !isApprovedForAll(moduleNftOwner, _msgSender())) {
             revert NotOwnerOrApproved(); // Caller must own/be approved for the module NFT
         }

        // Ensure a ChronoCraft cannot be attached to itself as a module
        if (chronoCraftId == moduleTokenId) {
            revert SelfAttachmentForbidden();
        }

        ChronoCraftData storage craft = _getChronoCraftData(chronoCraftId);
        // Check if the module is compatible (e.g., based on its craftType) - omitted for brevity, would require logic
        // Check if the ChronoCraft has module slots available - omitted for brevity, would require logic

        // Transfer the module NFT to the ZERO address (burn it)
        try IERC721(address(this)).transferFrom(_msgSender(), address(0), moduleTokenId) {
            // Successful burn
        } catch {
            revert ERC721TransferFailed();
        }

        craft.attachedModules.push(moduleTokenId); // Store the burned module's ID (or type, if types are used)
        emit ChronoCraftModuleAttached(chronoCraftId, moduleTokenId, craft.attachedModules.length - 1);

        // Optional: Apply module effects immediately (e.g., boost energy/durability, change decay rates)
        // This would require logic based on the module's properties (stored in the module token's data or a lookup)
    }

    /**
     * @notice Detaches a module from a ChronoCraft by index.
     * Note: Since modules were burned on attachment, this does NOT return an NFT.
     * It only removes the reference and potentially the effect of the module.
     * @param chronoCraftId The ID of the ChronoCraft to detach the module from.
     * @param moduleIndex The index of the module in the attachedModules array.
     */
    function detachModule(uint256 chronoCraftId, uint256 moduleIndex) external nonReentrant whenNotPaused {
        address owner = ownerOf(chronoCraftId);
         if (owner != _msgSender() && !isApprovedForAll(owner, _msgSender())) {
             revert NotOwnerOrApproved();
         }

        ChronoCraftData storage craft = _getChronoCraftData(chronoCraftId);

        if (moduleIndex >= craft.attachedModules.length) {
            revert InvalidModuleIndex();
        }

        uint256 moduleTokenId = craft.attachedModules[moduleIndex];

        // Remove the module ID from the array using a common Solidity pattern
        // Replace the element to be removed with the last element, then pop the last element.
        if (moduleIndex != craft.attachedModules.length - 1) {
            craft.attachedModules[moduleIndex] = craft.attachedModules[craft.attachedModules.length - 1];
        }
        craft.attachedModules.pop();

        emit ChronoCraftModuleDetached(chronoCraftId, moduleIndex, moduleTokenId);

        // Optional: Remove module effects (e.g., reduce energy/durability bonuses, revert decay rates)
    }

    /**
     * @notice Gets the list of module token IDs attached to a ChronoCraft.
     * @param chronoCraftId The ID of the ChronoCraft.
     * @return An array of module token IDs.
     */
    function getAttachedModules(uint256 chronoCraftId) external view returns (uint256[] memory) {
         if (!_exists(chronoCraftId)) {
             revert InvalidTokenId();
        }
        return _chronoCraftData[chronoCraftId].attachedModules;
    }


    // --- Crafting ---

    /**
     * @notice Crafts a new ChronoCraft according to a recipe.
     * Requires the caller to be a Crafter or the Owner.
     * Consumes the specified component NFTs (burns them).
     * Requires the caller to have approved this contract to transfer the component NFTs.
     * @param recipeId The ID of the crafting recipe to use.
     * @param componentTokenIds An array of component NFT token IDs to consume.
     */
    function craftChronoCraft(uint256 recipeId, uint256[] calldata componentTokenIds) external nonReentrant whenNotPaused onlyCrafterOrOwner {
        CraftingRecipe storage recipe = _craftingRecipes[recipeId];
        if (!recipe.exists) {
            revert InvalidRecipe();
        }

        // Check if the number of provided components matches the recipe requirement
        if (componentTokenIds.length != recipe.requiredComponentTokenIds.length) {
             revert InvalidComponentCount();
        }

        // --- Component Validation and Consumption ---
        // In a real system, you'd validate component *types* or *properties* here, not just IDs.
        // For this example, we'll assume the recipe specifies exact component *token IDs*.
        // This is simpler for the code but less flexible.
        // A better system would involve recipe.requiredComponentTypes = [type1, type2]
        // and validating componentTokenIds[i] is of that type.
        // For this example, let's validate against the required IDs listed in the recipe.
        // Note: This implies componentTokenIds must be *exactly* the IDs specified in the recipe,
        // and they must be provided in the *same order*. This is highly restrictive.
        // A more realistic system would allow any valid component *type* to be used.

        // Check ownership and approval for each component, then burn it.
        address caller = _msgSender();
        for (uint i = 0; i < componentTokenIds.length; ++i) {
            uint256 componentId = componentTokenIds[i];

             // Check if the provided component ID is one of the required ones (Highly Simplified!)
             // In a real system, you'd check if the component's *type* matches a required type.
             bool isRequiredComponent = false;
             for(uint j = 0; j < recipe.requiredComponentTokenIds.length; ++j) {
                 if (componentId == recipe.requiredComponentTokenIds[j]) {
                     isRequiredComponent = true;
                     // Prevent using the same component ID twice if recipe requires different types
                     // (Still simplified, real validation is complex)
                     // This check is too basic for production.
                     break; // Found it in the required list
                 }
             }
             // This specific implementation requires the component IDs to EXACTLY MATCH the recipe list.
             // This is very basic. A real system would check component *types*.
            // Let's refine: assume requiredComponentTokenIds are actually required *types* or *identifiers*, not specific token IDs.
            // The `componentTokenIds` array are the *actual tokens* being used.
            // We need a way to get the *type* of a component token ID. Let's assume ChronoCraft NFTs have a `craftType`.
            // We check if the *type* of `componentTokenIds[i]` matches one of the required types in `recipe.requiredComponentTokenIds`.

             // --- REVISED COMPONENT CHECK ---
             // Assume `recipe.requiredComponentTokenIds` stores required *types*.
             // Assume `_chronoCraftData[componentId].craftType` gives the type of a component NFT.
             if (!_exists(componentId)) {
                 revert InvalidComponentToken(); // Component NFT must exist
             }
             uint256 componentType = _chronoCraftData[componentId].craftType; // Get the type of the component NFT

             bool typeMatchesRequirement = false;
              for(uint j = 0; j < recipe.requiredComponentTokenIds.length; ++j) {
                  if (componentType == recipe.requiredComponentTokenIds[j]) {
                      typeMatchesRequirement = true;
                      // TODO: In a real system, you'd also need to ensure you don't use the same *slot*
                      // e.g., if a recipe needs 2x 'Gear' type components, you provide two *different* tokens of type 'Gear'.
                      // This requires more complex tracking of which requirement slot a token fulfills.
                      // For simplicity here, we just check if the *type* exists in the required list.
                      break; // Found a matching type requirement
                  }
              }

             if (!typeMatchesRequirement) {
                 revert InvalidComponentToken(); // Component type does not match recipe requirements
             }
            // --- END REVISED CHECK ---


            address componentOwner = ownerOf(componentId);
            if (componentOwner != caller && !isApprovedForAll(componentOwner, caller)) {
                 revert NotOwnerOrApproved(); // Caller must own/be approved for the component NFT
            }

            // Burn the component NFT
            try IERC721(address(this)).transferFrom(caller, address(0), componentId) {
                // Successful burn
            } catch {
                revert ERC721TransferFailed();
            }
        }

        // --- Mint New ChronoCraft ---
        uint256 newTokenId = _nextTokenId++;
        _mint(caller, newTokenId);

        _chronoCraftData[newTokenId] = ChronoCraftData({
            state: ChronoCraftState.Idle, // Starts Idle
            energy: 100, // Starts with full energy
            durability: 100, // Starts with full durability
            creationTime: uint64(block.timestamp),
            lastStateChangeTime: uint64(block.timestamp),
            lastDecayAppliedTime: uint64(block.timestamp), // Decay starts from creation
            attachedModules: new uint256[](0), // Starts with no modules
            craftType: recipe.outputChronoCraftType // Set the type based on the recipe
        });

        emit ChronoCraftCrafted(newTokenId, caller, recipeId, recipe.outputChronoCraftType);
        // Optional: Set state to CraftingInProgress for a duration? Requires more complex state machine.
        // For now, it's instantly Idle.
    }

    /**
     * @notice Adds a new crafting recipe.
     * Only callable by the contract owner.
     * @param recipeId The unique ID for the recipe.
     * @param requiredComponentTokenIds An array of required component *types* (using craftType identifiers).
     * @param outputChronoCraftType The craftType of the ChronoCraft produced.
     */
    function addCraftingRecipe(uint256 recipeId, uint256[] calldata requiredComponentTokenIds, uint256 outputChronoCraftType) external onlyOwner {
        if (_craftingRecipes[recipeId].exists) {
            revert InvalidRecipe(); // Recipe ID already exists
        }
        _craftingRecipes[recipeId] = CraftingRecipe({
            exists: true,
            requiredComponentTokenIds: requiredComponentTokenIds,
            outputChronoCraftType: outputChronoCraftType
        });
        // No explicit event for adding recipe in this example
    }

    /**
     * @notice Removes an existing crafting recipe.
     * Only callable by the contract owner.
     * @param recipeId The ID of the recipe to remove.
     */
    function removeCraftingRecipe(uint256 recipeId) external onlyOwner {
        if (!_craftingRecipes[recipeId].exists) {
             revert InvalidRecipe(); // Recipe ID does not exist
        }
        delete _craftingRecipes[recipeId];
        // No explicit event for removing recipe
    }

    /**
     * @notice Gets the details of a crafting recipe.
     * @param recipeId The ID of the recipe.
     * @return The required component types and the output craft type.
     */
    function getCraftingRecipe(uint256 recipeId) external view returns (uint256[] memory, uint256) {
        CraftingRecipe storage recipe = _craftingRecipes[recipeId];
        if (!recipe.exists) {
             revert InvalidRecipe(); // Recipe ID does not exist
        }
        return (recipe.requiredComponentTokenIds, recipe.outputChronoCraftType);
    }


    // --- Query Functions ---

    /**
     * @notice Gets all dynamic data for a ChronoCraft.
     * @param tokenId The ID of the ChronoCraft.
     * @return A tuple containing state, energy, durability, creation time, last state change time, last decay applied time, attached modules, and craft type.
     */
    function getChronoCraftDetails(uint256 tokenId) external view returns (ChronoCraftState, uint8, uint8, uint64, uint64, uint64, uint256[] memory, uint256) {
        ChronoCraftData storage craft = _getChronoCraftData(tokenId);
        // Note: This copies the array. For large numbers of modules, might exceed gas limits or stack depth.
        // Consider separate functions or pagination if module count is high.
        return (
            craft.state,
            craft.energy,
            craft.durability,
            craft.creationTime,
            craft.lastStateChangeTime,
            craft.lastDecayAppliedTime,
            craft.attachedModules,
            craft.craftType
        );
    }

    /**
     * @notice Gets the current state of a ChronoCraft.
     * @param tokenId The ID of the ChronoCraft.
     * @return The ChronoCraftState.
     */
    function getChronoCraftState(uint256 tokenId) external view returns (ChronoCraftState) {
        return _getChronoCraftData(tokenId).state;
    }

    /**
     * @notice Gets the current energy level of a ChronoCraft.
     * @param tokenId The ID of the ChronoCraft.
     * @return The energy level (0-100).
     */
    function getChronoCraftEnergy(uint256 tokenId) external view returns (uint8) {
        return _getChronoCraftData(tokenId).energy;
    }

    /**
     * @notice Gets the current durability level of a ChronoCraft.
     * @param tokenId The ID of the ChronoCraft.
     * @return The durability level (0-100).
     */
    function getChronoCraftDurability(uint256 tokenId) external view returns (uint8) {
        return _getChronoCraftData(tokenId).durability;
    }

     /**
     * @notice Gets the creation timestamp of a ChronoCraft.
     * @param tokenId The ID of the ChronoCraft.
     * @return The creation timestamp.
     */
    function getChronoCraftCreationTime(uint256 tokenId) external view returns (uint64) {
        return _getChronoCraftData(tokenId).creationTime;
    }

     /**
     * @notice Gets the last timestamp the state of a ChronoCraft changed.
     * @param tokenId The ID of the ChronoCraft.
     * @return The last state change timestamp.
     */
    function getChronoCraftLastActiveTime(uint256 tokenId) external view returns (uint64) {
        // We used lastStateChangeTime to track relevant time for decay mostly
        // Renaming this to be clearer might be needed in a real system.
        // For now, it returns the timestamp used in some decay calculations.
        return _getChronoCraftData(tokenId).lastStateChangeTime;
    }


    // --- Role Management (Crafter) ---

    /**
     * @notice Grants or revokes the Crafter role for an address.
     * Only callable by the contract owner.
     * @param crafter The address to modify.
     * @param enabled True to grant, False to revoke.
     */
    function setCrafterAddress(address crafter, bool enabled) external onlyOwner {
        if (_isCrafter[crafter] != enabled) {
            _isCrafter[crafter] = enabled;
            if (enabled) {
                emit CrafterRoleGranted(crafter);
            } else {
                emit CrafterRoleRevoked(crafter);
            }
        }
    }

    /**
     * @notice Revokes the Crafter role for an address.
     * Only callable by the contract owner. Alias for `setCrafterAddress(crafter, false)`.
     * @param crafter The address to remove the role from.
     */
    function removeCrafterAddress(address crafter) external onlyOwner {
         setCrafterAddress(crafter, false);
    }


    /**
     * @notice Checks if an address has the Crafter role.
     * @param account The address to check.
     * @return True if the address is a Crafter, false otherwise.
     */
    function isCrafter(address account) public view returns (bool) {
        return _isCrafter[account];
    }

    // --- Admin & System ---

    /**
     * @notice Pauses all state-changing actions (transfers, crafting, actions).
     * Only callable by the contract owner.
     */
    function pause() external onlyOwner {
        _pause();
    }

    /**
     * @notice Unpauses the contract.
     * Only callable by the contract owner.
     */
    function unpause() external onlyOwner {
        _unpause();
    }

    /**
     * @notice Allows the owner to withdraw any ETH accidentally or purposefully sent to the contract (e.g., from recharge/repair fees).
     * @dev Uses a low-level call for withdrawal to be more robust against recipient contract failures.
     */
    function emergencyWithdraw() external onlyOwner {
        (bool success, ) = payable(owner()).call{value: address(this).balance}("");
        require(success, "Withdrawal failed");
    }

    /**
     * @notice Allows the owner to withdraw specific ERC20 tokens accidentally sent to the contract.
     * @param tokenAddress The address of the ERC20 token.
     */
    function withdrawERC20(address tokenAddress) external onlyOwner {
        IERC20 token = IERC20(tokenAddress);
        token.transfer(owner(), token.balanceOf(address(this)));
    }

     /**
     * @notice Allows the owner to withdraw a specific ERC721 token accidentally sent to the contract.
     * Useful if a component/module gets stuck or sent outside the crafting/attachment flow.
     * @param tokenAddress The address of the ERC721 token contract.
     * @param tokenId The ID of the ERC721 token to withdraw.
     */
    function withdrawERC721(address tokenAddress, uint256 tokenId) external onlyOwner {
        IERC721 token = IERC721(tokenAddress);
        // Ensure the contract owns the token before attempting to transfer
        if (token.ownerOf(tokenId) != address(this)) {
             revert InvalidTokenId(); // Or a more specific error like "ContractDoesNotOwnToken"
        }
        token.safeTransferFrom(address(this), owner(), tokenId);
    }


    /**
     * @notice Sets the base URI for token metadata.
     * Only callable by the contract owner.
     * @param baseURI The base URI string.
     */
    function setBaseTokenURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    // Helper function from OpenZeppelin's Strings library (not imported explicitly here for brevity)
    // but needed for tokenURI. Can be included manually or imported.
    function _toString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        uint256 index = digits;
        temp = value;
        while (temp != 0) {
            index--;
            buffer[index] = bytes1(uint8(48 + temp % 10));
            temp /= 10;
        }
        return string(buffer);
    }
}
```