Okay, here is a Solidity smart contract for a "Dynamic NFT Avatar". This contract represents an NFT whose metadata (appearance, traits, status) changes based on on-chain interactions, progression (like gaining XP and leveling up), and applied effects.

It combines standard ERC721 features with custom logic for dynamic state, on-chain metadata generation, configuration, and avatar-to-avatar interactions. It aims for complexity beyond basic NFTs or simple state changes.

**Core Concepts:**

1.  **ERC721 Standard:** Implements the core non-fungible token standard.
2.  **Dynamic On-Chain Metadata:** The `tokenURI` is generated on-chain and reflects the current state (Level, XP, Traits, Components, Status Effects). Uses Base64 encoding for data URI.
3.  **Progression System:** Avatars gain Experience Points (XP) and Level Up based on defined thresholds. Leveling affects traits.
4.  **Traits:** Avatars have numerical traits (e.g., Strength, Intelligence) that can be modified by leveling or other interactions.
5.  **Components:** Avatars can have abstract "components" attached (e.g., 'Hat', 'Weapon'), represented by IDs. These affect the metadata.
6.  **Status Effects:** Temporary effects can be applied with expiry times. Affects metadata and can influence interactions.
7.  **Avatar Interaction:** A function allows one avatar to interact with another, potentially causing state changes on one or both.
8.  **Configurability:** Owner can set mint price, max supply, level-up thresholds, and base URI.
9.  **Access Control:** Uses `Ownable` for administrative functions. State changes are generally limited to the token owner or specific functions.

**Outline:**

1.  **License Identifier & Pragma**
2.  **Imports**
3.  **Error Definitions**
4.  **Structs**
    *   `Trait`
    *   `Component`
    *   `StatusEffect`
    *   `TokenState` (for querying all dynamic data)
5.  **Events**
    *   Standard ERC721 events (implicitly handled by OpenZeppelin)
    *   `LevelUp`
    *   `XPIncreased`
    *   `TraitChanged`
    *   `ComponentAdded`
    *   `ComponentRemoved`
    *   `StatusEffectApplied`
    *   `StatusEffectRemoved`
    *   `AvatarInteracted`
    *   `ConfigUpdated`
6.  **State Variables**
    *   `_nextTokenId` (Counter)
    *   `_maxSupply`
    *   `_mintPrice`
    *   `_baseURI`
    *   `_avatarLevels` (mapping tokenId -> level)
    *   `_avatarXP` (mapping tokenId -> xp)
    *   `_levelXPThresholds` (mapping level -> xp required for next level)
    *   `_avatarTraits` (mapping tokenId -> mapping traitType -> value)
    *   `_avatarComponents` (mapping tokenId -> mapping componentType -> componentId)
    *   `_avatarStatusEffects` (mapping tokenId -> mapping effectType -> endTimestamp)
    *   `_ownerTokenIds` (mapping owner -> list of tokenIds) - Helper for `getOwnerAvatarIds`
7.  **Constructor**
8.  **Standard ERC721 Functions (Inherited/Overridden)**
    *   `supportsInterface` (Inherited)
    *   `balanceOf` (Inherited)
    *   `ownerOf` (Inherited)
    *   `safeTransferFrom` (Inherited)
    *   `transferFrom` (Inherited)
    *   `approve` (Inherited)
    *   `setApprovalForAll` (Inherited)
    *   `getApproved` (Inherited)
    *   `isApprovedForAll` (Inherited)
    *   `tokenURI` (Overridden) - Generates dynamic metadata
9.  **Minting**
    *   `publicMint`
10. **Configuration & Admin (Owner-only)**
    *   `setMaxSupply`
    *   `setMintPrice`
    *   `setBaseURI`
    *   `setLevelXPThreshold`
    *   `setTrait` (Admin override)
    *   `withdraw`
11. **Dynamic State Management (User/System Callable)**
    *   `gainXP`
    *   `levelUpIfReady`
    *   `addComponent`
    *   `removeComponent`
    *   `applyStatusEffect`
    *   `removeStatusEffect`
    *   `interactWithAvatar`
    *   `burn` (Allows token owner to burn their token)
12. **Internal Helper Functions**
    *   `_mint` (Override for internal tracking)
    *   `_burn` (Override for internal tracking)
    *   `_transfer` (Override for internal tracking)
    *   `_levelUp` (Performs level up logic)
    *   `_checkTokenOwnershipOrApproved`
    *   `_getTokenOwnerAddress` (Helper)
13. **Query Functions (View/Pure)**
    *   `getTrait`
    *   `getAllTraits`
    *   `getComponent`
    *   `getAllComponents`
    *   `getStatusEffectEndTime`
    *   `getActiveStatusEffects`
    *   `isStatusEffectActive`
    *   `getLevelXPThreshold`
    *   `getTokenState`
    *   `getOwnerAvatarIds`

**Function Summary:**

*   **`constructor(string name, string symbol, uint256 initialMaxSupply, uint256 initialMintPrice, string initialBaseURI)`**: Initializes the contract with name, symbol, supply, price, and base URI.
*   **`supportsInterface(bytes4 interfaceId)`**: Standard ERC165 interface support (inherited).
*   **`balanceOf(address owner)`**: Returns count of tokens owned by an address (inherited).
*   **`ownerOf(uint256 tokenId)`**: Returns the owner of a token (inherited).
*   **`safeTransferFrom(address from, address to, uint256 tokenId)`**: Transfers token, checks if recipient can receive (inherited).
*   **`safeTransferFrom(address from, address to, uint256 tokenId, bytes data)`**: Transfers token with data, checks if recipient can receive (inherited).
*   **`transferFrom(address from, address to, uint256 tokenId)`**: Transfers token (inherited).
*   **`approve(address to, uint256 tokenId)`**: Approves an address to transfer a specific token (inherited).
*   **`setApprovalForAll(address operator, bool approved)`**: Approves/disapproves operator for all tokens (inherited).
*   **`getApproved(uint256 tokenId)`**: Returns the approved address for a token (inherited).
*   **`isApprovedForAll(address owner, address operator)`**: Returns if operator is approved for all tokens of an owner (inherited).
*   **`tokenURI(uint256 tokenId)`**: **(Overridden)** Generates and returns a data URI containing on-chain JSON metadata based on the token's current state (level, xp, traits, components, status effects).
*   **`publicMint()`**: Allows anyone to mint a new avatar token by paying the mint price, subject to max supply. Initializes the token's dynamic state.
*   **`setMaxSupply(uint256 supply)`**: **(Owner-only)** Sets the maximum number of tokens that can be minted.
*   **`setMintPrice(uint256 price)`**: **(Owner-only)** Sets the price (in wei) required to mint a token.
*   **`setBaseURI(string uri)`**: **(Owner-only)** Sets the base URI for metadata (used as a prefix, though `tokenURI` generates fully on-chain data now, this could be a fallback or prefix for `image` data).
*   **`setLevelXPThreshold(uint256 level, uint256 xpNeeded)`**: **(Owner-only)** Configures the amount of XP required to reach a specific level.
*   **`setTrait(uint256 tokenId, string traitType, uint256 value)`**: **(Owner-only)** Allows the owner to directly set a specific trait value for an avatar.
*   **`withdraw()`**: **(Owner-only)** Withdraws contract balance (from minting fees) to the owner.
*   **`gainXP(uint256 tokenId, uint256 amount)`**: Allows the token owner (or approved) to add XP to an avatar. Emits `XPIncreased`. Does NOT automatically level up.
*   **`levelUpIfReady(uint256 tokenId)`**: Allows the token owner (or approved) to trigger a level-up attempt. Checks if the avatar's XP meets the threshold for the next level. If so, increments level, potentially adjusts XP, modifies traits, and emits `LevelUp`.
*   **`addComponent(uint256 tokenId, string componentType, uint256 componentId)`**: Allows the token owner (or approved) to attach a component to the avatar. Replaces existing component of the same type. Emits `ComponentAdded`.
*   **`removeComponent(uint256 tokenId, string componentType)`**: Allows the token owner (or approved) to remove a component from the avatar. Emits `ComponentRemoved`.
*   **`applyStatusEffect(uint256 tokenId, string effectType, uint256 durationSeconds)`**: Allows the token owner (or approved) to apply a status effect that lasts for a specified duration. Overwrites existing effect of the same type. Emits `StatusEffectApplied`.
*   **`removeStatusEffect(uint256 tokenId, string effectType)`**: Allows the token owner (or approved) to manually remove an active status effect. Emits `StatusEffectRemoved`.
*   **`interactWithAvatar(uint256 tokenIdA, uint256 tokenIdB, string interactionType)`**: Allows an owner (of tokenIdA) to trigger an interaction with another avatar (tokenIdB). This is a placeholder; the internal logic could be complex (e.g., transfer XP, apply status, change traits based on `interactionType`). Currently, it adds a simple status effect to both. Emits `AvatarInteracted`.
*   **`burn(uint256 tokenId)`**: Allows the token owner (or approved) to burn their avatar token. Removes all associated dynamic state.
*   **`getTrait(uint256 tokenId, string traitType)`**: **(View)** Returns the value of a specific trait for an avatar.
*   **`getAllTraits(uint256 tokenId)`**: **(View)** Returns all traits and their values for an avatar as a list of structs.
*   **`getComponent(uint256 tokenId, string componentType)`**: **(View)** Returns the ID of a specific component type attached to an avatar.
*   **`getAllComponents(uint256 tokenId)`**: **(View)** Returns all components and their IDs for an avatar as a list of structs.
*   **`getStatusEffectEndTime(uint256 tokenId, string effectType)`**: **(View)** Returns the expiry timestamp of a specific status effect.
*   **`getActiveStatusEffects(uint256 tokenId)`**: **(View)** Returns all currently active status effects (those not expired based on `block.timestamp`) for an avatar.
*   **`isStatusEffectActive(uint256 tokenId, string effectType)`**: **(View)** Checks if a specific status effect is currently active.
*   **`getLevelXPThreshold(uint256 level)`**: **(View)** Returns the XP needed to reach a given level.
*   **`getTokenState(uint256 tokenId)`**: **(View)** Returns a struct containing all dynamic state data (level, xp, traits, components, status effects) for an avatar.
*   **`getOwnerAvatarIds(address owner)`**: **(View)** Returns an array of all token IDs owned by a specific address.

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Base64.sol";

// Error definitions
error InvalidTokenId();
error MaxSupplyReached();
error InsufficientPayment();
error NotTokenOwnerOrApproved();
error NotEnoughXPToLevelUp();
error ComponentNotFound();
error StatusEffectNotFound();
error InteractionCannotBeSelf();


// Structs for dynamic state components
struct Trait {
    string traitType;
    uint256 value;
}

struct Component {
    string componentType;
    uint256 componentId; // Could be token ID of another NFT, or a simple identifier
}

struct StatusEffect {
    string effectType;
    uint256 endTime; // Unix timestamp
}

// Struct to return full state
struct TokenState {
    uint256 level;
    uint256 xp;
    Trait[] traits;
    Component[] components;
    StatusEffect[] statusEffects; // Includes expired ones; use getActiveStatusEffects for current
}


// Events
event LevelUp(uint256 indexed tokenId, uint256 newLevel, uint256 remainingXP);
event XPIncreased(uint256 indexed tokenId, uint256 oldXP, uint256 newXP, uint256 amount);
event TraitChanged(uint256 indexed tokenId, string indexed traitType, uint256 oldValue, uint256 newValue);
event ComponentAdded(uint256 indexed tokenId, string indexed componentType, uint256 componentId);
event ComponentRemoved(uint256 indexed tokenId, string indexed componentType, uint256 oldComponentId);
event StatusEffectApplied(uint256 indexed tokenId, string indexed effectType, uint256 durationSeconds, uint256 endTime);
event StatusEffectRemoved(uint256 indexed tokenId, string indexed effectType);
event AvatarInteracted(uint256 indexed tokenIdA, uint256 indexed tokenIdB, string interactionType);
event ConfigUpdated(string indexed configKey, string value);


contract DynamicNFTAvatar is ERC721, Ownable {
    using Counters for Counters.Counter;
    using Strings for uint256;

    Counters.Counter private _nextTokenId;

    uint256 private _maxSupply;
    uint256 private _mintPrice;
    string private _baseURI; // Optional base for image or external metadata, though tokenURI is on-chain

    // --- Dynamic State Mappings ---
    mapping(uint256 => uint256) private _avatarLevels;
    mapping(uint256 => uint256) private _avatarXP;

    // level => xp required for the *next* level (e.g., _levelXPThresholds[1] is XP needed to reach level 2)
    mapping(uint256 => uint256) private _levelXPThresholds;

    // tokenId => traitType => value
    mapping(uint256 => mapping(string => uint256)) private _avatarTraits;

    // tokenId => componentType => componentId
    mapping(uint256 => mapping(string => uint256)) private _avatarComponents;

    // tokenId => effectType => endTime (timestamp)
    mapping(uint256 => mapping(string => uint256)) private _avatarStatusEffects;

    // --- Utility Mapping for getOwnerAvatarIds ---
    mapping(address => uint256[]) private _ownerTokenIds;
    mapping(uint256 => uint256) private _tokenIdIndexInOwnerArray;


    constructor(
        string memory name,
        string memory symbol,
        uint256 initialMaxSupply,
        uint256 initialMintPrice,
        string memory initialBaseURI
    )
        ERC721(name, symbol)
        Ownable(msg.sender)
    {
        _maxSupply = initialMaxSupply;
        _mintPrice = initialMintPrice;
        _baseURI = initialBaseURI;

        // Set some default leveling thresholds (example)
        _levelXPThresholds[1] = 100;
        _levelXPThresholds[2] = 250;
        _levelXPThresholds[3] = 500;
        _levelXPThresholds[4] = 1000;
        // Add more levels as needed...
    }

    // --- Configuration & Admin Functions ---

    /// @notice Sets the maximum number of tokens that can be minted.
    /// @param supply The new maximum supply.
    function setMaxSupply(uint256 supply) external onlyOwner {
        _maxSupply = supply;
        emit ConfigUpdated("maxSupply", supply.toString());
    }

    /// @notice Sets the price (in wei) required to mint a token.
    /// @param price The new mint price in wei.
    function setMintPrice(uint256 price) external onlyOwner {
        _mintPrice = price;
        emit ConfigUpdated("mintPrice", price.toString());
    }

    /// @notice Sets the base URI (used internally, potentially for image/external link prefixes).
    /// @param uri The new base URI string.
    function setBaseURI(string calldata uri) external onlyOwner {
        _baseURI = uri;
        emit ConfigUpdated("baseURI", uri);
    }

    /// @notice Configures the amount of XP required to reach a specific level.
    /// @param level The level you are defining the threshold FOR (i.e., XP needed to reach 'level').
    /// @param xpNeeded The amount of XP required to reach 'level'.
    function setLevelXPThreshold(uint256 level, uint256 xpNeeded) external onlyOwner {
        require(level > 0, "Level must be positive");
        _levelXPThresholds[level] = xpNeeded;
        emit ConfigUpdated(string(abi.encodePacked("levelXPThreshold-", level.toString())), xpNeeded.toString());
    }

    /// @notice Allows the owner to directly set a specific trait value for an avatar (admin override).
    /// @param tokenId The ID of the avatar token.
    /// @param traitType The type of trait (e.g., "Strength", "Agility").
    /// @param value The new value for the trait.
    function setTrait(uint256 tokenId, string calldata traitType, uint256 value) external onlyOwner {
        require(_exists(tokenId), "Token does not exist");
        uint256 oldValue = _avatarTraits[tokenId][traitType];
        _avatarTraits[tokenId][traitType] = value;
        emit TraitChanged(tokenId, traitType, oldValue, value);
    }

    /// @notice Withdraws the contract balance (from minting fees) to the owner.
    function withdraw() external onlyOwner {
        (bool success,) = payable(owner()).call{value: address(this).balance}("");
        require(success, "Withdraw failed");
    }

    // --- Minting Function ---

    /// @notice Allows anyone to mint a new avatar token by paying the mint price.
    /// @dev Initializes level to 1, XP to 0, and default traits/components/status.
    function publicMint() external payable {
        if (totalSupply() >= _maxSupply) {
            revert MaxSupplyReached();
        }
        if (msg.value < _mintPrice) {
            revert InsufficientPayment();
        }

        uint256 newTokenId = _nextTokenId.current();
        _nextTokenId.increment();

        _safeMint(msg.sender, newTokenId);

        // Initialize dynamic state
        _avatarLevels[newTokenId] = 1;
        _avatarXP[newTokenId] = 0;
        // Add default traits here if needed, e.g.:
        // _avatarTraits[newTokenId]["Strength"] = 1;
        // _avatarTraits[newTokenId]["Intelligence"] = 1;

        // Default components/status can also be set here

        // Refund excess payment
        if (msg.value > _mintPrice) {
            payable(msg.sender).transfer(msg.value - _mintPrice);
        }
    }

    // --- Dynamic State Management Functions ---

    /// @notice Allows adding XP to an avatar. Can be called by owner or approved.
    /// @dev This function only increases XP and emits an event. Leveling up is a separate step (`levelUpIfReady`).
    /// @param tokenId The ID of the avatar token.
    /// @param amount The amount of XP to add.
    function gainXP(uint256 tokenId, uint256 amount) external {
        _checkTokenOwnershipOrApproved(tokenId);
        require(_exists(tokenId), InvalidTokenId());

        uint256 oldXP = _avatarXP[tokenId];
        uint256 newXP = oldXP + amount; // unchecked is fine as XP can grow large

        _avatarXP[tokenId] = newXP;
        emit XPIncreased(tokenId, oldXP, newXP, amount);
    }

    /// @notice Allows an owner/approved to trigger a level-up check.
    /// @dev If the avatar's current XP meets or exceeds the threshold for the next level, it levels up.
    /// @param tokenId The ID of the avatar token.
    function levelUpIfReady(uint256 tokenId) external {
        _checkTokenOwnershipOrApproved(tokenId);
        require(_exists(tokenId), InvalidTokenId());

        uint256 currentLevel = _avatarLevels[tokenId];
        uint256 currentXP = _avatarXP[tokenId];
        uint256 xpNeeded = _levelXPThresholds[currentLevel];

        if (xpNeeded == 0 || currentXP < xpNeeded) {
            revert NotEnoughXPToLevelUp();
        }

        _levelUp(tokenId);
    }

    /// @dev Internal helper function to perform the actual level up logic.
    /// @param tokenId The ID of the avatar token.
    function _levelUp(uint256 tokenId) internal {
        uint256 currentLevel = _avatarLevels[tokenId];
        uint256 currentXP = _avatarXP[tokenId];
        uint256 xpNeeded = _levelXPThresholds[currentLevel];

        // Check again in case called internally without the public check
        require(xpNeeded > 0 && currentXP >= xpNeeded, "Level up conditions not met internally");

        _avatarLevels[tokenId] = currentLevel + 1;
        _avatarXP[tokenId] = currentXP - xpNeeded; // Deduct required XP

        // --- Apply Level Up Effects ---
        // Example: Boost a trait
        uint256 oldStrength = _avatarTraits[tokenId]["Strength"];
        _avatarTraits[tokenId]["Strength"] = oldStrength + 1; // Gain 1 Strength per level
        emit TraitChanged(tokenId, "Strength", oldStrength, _avatarTraits[tokenId]["Strength"]);

        // More complex trait boosts, adding components, etc., can be added here

        emit LevelUp(tokenId, currentLevel + 1, _avatarXP[tokenId]);
    }


    /// @notice Adds a component to an avatar. Can be called by owner or approved.
    /// @dev Replaces any existing component of the same type.
    /// @param tokenId The ID of the avatar token.
    /// @param componentType The type of component (e.g., "Hat", "Weapon", "Armor").
    /// @param componentId The ID representing the specific component (could be another NFT's ID or just a number).
    function addComponent(uint256 tokenId, string calldata componentType, uint256 componentId) external {
        _checkTokenOwnershipOrApproved(tokenId);
        require(_exists(tokenId), InvalidTokenId());
        // Optional: Add checks here if componentId references a valid external asset/token

        uint256 oldComponentId = _avatarComponents[tokenId][componentType];
        _avatarComponents[tokenId][componentType] = componentId;
        emit ComponentAdded(tokenId, componentType, componentId);
        if (oldComponentId != 0) { // 0 could signify no component was there
            emit ComponentRemoved(tokenId, componentType, oldComponentId);
        }
    }

    /// @notice Removes a component from an avatar. Can be called by owner or approved.
    /// @param tokenId The ID of the avatar token.
    /// @param componentType The type of component to remove.
    function removeComponent(uint256 tokenId, string calldata componentType) external {
        _checkTokenOwnershipOrApproved(tokenId);
        require(_exists(tokenId), InvalidTokenId());

        uint256 oldComponentId = _avatarComponents[tokenId][componentType];
        if (oldComponentId == 0) { // Check if a component of this type exists
             revert ComponentNotFound();
        }

        delete _avatarComponents[tokenId][componentType];
        emit ComponentRemoved(tokenId, componentType, oldComponentId);
    }

    /// @notice Applies a status effect to an avatar. Can be called by owner or approved.
    /// @dev Overwrites existing effect of the same type. Duration is in seconds from `block.timestamp`.
    /// @param tokenId The ID of the avatar token.
    /// @param effectType The type of status effect (e.g., "Poison", "StrengthBuff", "Stun").
    /// @param durationSeconds The duration of the effect in seconds.
    function applyStatusEffect(uint256 tokenId, string calldata effectType, uint256 durationSeconds) external {
        _checkTokenOwnershipOrApproved(tokenId);
        require(_exists(tokenId), InvalidTokenId());
        require(durationSeconds > 0, "Duration must be positive");

        uint256 endTime = block.timestamp + durationSeconds;
        _avatarStatusEffects[tokenId][effectType] = endTime;
        emit StatusEffectApplied(tokenId, effectType, durationSeconds, endTime);
    }

    /// @notice Manually removes a status effect from an avatar. Can be called by owner or approved.
    /// @param tokenId The ID of the avatar token.
    /// @param effectType The type of status effect to remove.
    function removeStatusEffect(uint256 tokenId, string calldata effectType) external {
        _checkTokenOwnershipOrApproved(tokenId);
        require(_exists(tokenId), InvalidTokenId());

        if (_avatarStatusEffects[tokenId][effectType] == 0) { // Check if effect exists
            revert StatusEffectNotFound();
        }

        delete _avatarStatusEffects[tokenId][effectType];
        emit StatusEffectRemoved(tokenId, effectType);
    }

    /// @notice Allows an owner of tokenIdA to trigger an interaction with tokenIdB.
    /// @dev Example implementation: Applies a temporary status effect to both avatars.
    /// More complex logic (e.g., transferring XP, changing traits based on interactionType) could be added here.
    /// @param tokenIdA The ID of the interacting avatar (must be owned/approved by msg.sender).
    /// @param tokenIdB The ID of the target avatar.
    /// @param interactionType A string describing the type of interaction (e.g., "Friendly", "Challenge", "Trade").
    function interactWithAvatar(uint256 tokenIdA, uint256 tokenIdB, string calldata interactionType) external {
        _checkTokenOwnershipOrApproved(tokenIdA); // Ensure sender controls A
        require(_exists(tokenIdA), InvalidTokenId());
        require(_exists(tokenIdB), InvalidTokenId());
        require(tokenIdA != tokenIdB, InteractionCannotBeSelf());

        // --- Example Interaction Logic ---
        // Apply a "RecentlyInteracted" status effect to both for a short duration
        uint256 interactionDuration = 1 hours;
        _avatarStatusEffects[tokenIdA]["RecentlyInteracted"] = block.timestamp + interactionDuration;
        _avatarStatusEffects[tokenIdB]["RecentlyInteracted"] = block.timestamp + interactionDuration;

        // You could add more complex logic here:
        // - If interactionType is "Challenge", maybe roll some stats from traits and apply Win/Loss status/XP
        // - If interactionType is "Trade", could integrate with external token logic (requires interfaces)
        // - If interactionType is "GiftXP", could transfer XP from A to B (requires A having enough XP)

        emit AvatarInteracted(tokenIdA, tokenIdB, interactionType);
        // Emitting status effect applied events for the internal changes
        emit StatusEffectApplied(tokenIdA, "RecentlyInteracted", interactionDuration, block.timestamp + interactionDuration);
        emit StatusEffectApplied(tokenIdB, "RecentlyInteracted", interactionDuration, block.timestamp + interactionDuration);
    }

    /// @notice Allows the owner or approved address to burn their avatar token.
    /// @dev Also clears all associated dynamic state.
    /// @param tokenId The ID of the avatar token to burn.
    function burn(uint256 tokenId) external {
        _checkTokenOwnershipOrApproved(tokenId);
        _burn(tokenId); // Calls the overridden _burn function
    }

    // --- Internal ERC721 Overrides for State Tracking ---

    /// @dev Overrides the internal _mint function to also track tokens per owner.
    function _mint(address to, uint256 tokenId) internal override {
        super._mint(to, tokenId);
        _ownerTokenIds[to].push(tokenId);
        _tokenIdIndexInOwnerArray[tokenId] = _ownerTokenIds[to].length - 1;
    }

    /// @dev Overrides the internal _burn function to also clear dynamic state and track tokens per owner.
    function _burn(uint256 tokenId) internal override {
        require(_exists(tokenId), InvalidTokenId());

        address owner = ownerOf(tokenId); // Get owner before burning
        super._burn(tokenId);

        // Clear dynamic state
        delete _avatarLevels[tokenId];
        delete _avatarXP[tokenId];
        // Clearing mappings of mappings requires iterating keys, which is gas intensive.
        // For this example, we just delete the main mapping entry.
        // A real-world scenario might require tracking active traits/components/status effects
        // in lists to iterate and delete individually, or accept gas cost/complexity.
        // For simplicity here, we assume deleting the outer key is sufficient logically after burn.
        // delete _avatarTraits[tokenId]; // This doesn't work recursively
        // delete _avatarComponents[tokenId]; // This doesn't work recursively
        // delete _avatarStatusEffects[tokenId]; // This doesn't work recursively

        // Removing from _ownerTokenIds tracking array
        uint256 lastIndex = _ownerTokenIds[owner].length - 1;
        uint256 tokenToMove = _ownerTokenIds[owner][lastIndex];
        uint256 removedTokenIndex = _tokenIdIndexInOwnerArray[tokenId];

        if (removedTokenIndex != lastIndex) {
            _ownerTokenIds[owner][removedTokenIndex] = tokenToMove;
            _tokenIdIndexInOwnerArray[tokenToMove] = removedTokenIndex;
        }
        _ownerTokenIds[owner].pop();
        delete _tokenIdIndexInOwnerArray[tokenId];
    }

    /// @dev Overrides the internal _transfer function to track tokens per owner.
    function _transfer(address from, address to, uint256 tokenId) internal override {
         require(_exists(tokenId), InvalidTokenId()); // Ensure token exists
        super._transfer(from, to, tokenId);

        // Remove from old owner's array
        uint256 lastIndexFrom = _ownerTokenIds[from].length - 1;
        uint256 tokenToMoveFrom = _ownerTokenIds[from][lastIndexFrom];
        uint256 removedTokenIndexFrom = _tokenIdIndexInOwnerArray[tokenId];

        if (removedTokenIndexFrom != lastIndexFrom) {
            _ownerTokenIds[from][removedTokenIndexFrom] = tokenToMoveFrom;
            _tokenIdIndexInOwnerArray[tokenToMoveFrom] = removedTokenIndexFrom;
        }
        _ownerTokenIds[from].pop();
        delete _tokenIdIndexInOwnerArray[tokenId];

        // Add to new owner's array
        _ownerTokenIds[to].push(tokenId);
        _tokenIdIndexInOwnerArray[tokenId] = _ownerTokenIds[to].length - 1;
    }


    // --- Metadata and Query Functions ---

    /// @dev See {IERC721Metadata-tokenURI}.
    /// @notice Generates on-chain JSON metadata for the token, reflecting its current dynamic state.
    /// @param tokenId The ID of the avatar token.
    /// @return A data URI string containing the Base64 encoded JSON metadata.
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        uint256 level = _avatarLevels[tokenId];
        uint256 xp = _avatarXP[tokenId];

        // Build the attributes array based on dynamic state
        string memory attributesJson = "[";

        // Add Level and XP as attributes
        attributesJson = string(abi.encodePacked(attributesJson, '{"trait_type": "Level", "value": ', level.toString(), '},'));
        attributesJson = string(abi.encodePacked(attributesJson, '{"trait_type": "XP", "value": ', xp.toString(), '},'));

        // Add Traits
        // Note: Iterating through all possible trait strings is inefficient/impossible.
        // In a real system, you'd track active traits in a list per token, or use
        // a more complex mapping structure that allows iteration.
        // For this example, we'll hardcode a few potential trait types to demonstrate.
        string[] memory traitTypes = new string[](2); // Example hardcoded types
        traitTypes[0] = "Strength";
        traitTypes[1] = "Intelligence";

        for (uint i = 0; i < traitTypes.length; i++) {
            uint256 value = _avatarTraits[tokenId][traitTypes[i]];
             // Only include if value is not zero (assuming 0 is default/unset)
            if (value > 0) {
                 attributesJson = string(abi.encodePacked(attributesJson, '{"trait_type": "', traitTypes[i], '", "value": ', value.toString(), '},'));
            }
        }


        // Add Components
        // Similar iteration challenge as traits. Hardcode example types.
        string[] memory componentTypes = new string[](2); // Example hardcoded types
        componentTypes[0] = "Hat";
        componentTypes[1] = "Weapon";

        for (uint i = 0; i < componentTypes.length; i++) {
             uint256 componentId = _avatarComponents[tokenId][componentTypes[i]];
             // Only include if componentId is not zero
            if (componentId > 0) {
                attributesJson = string(abi.encodePacked(attributesJson, '{"trait_type": "', componentTypes[i], ' ID", "value": ', componentId.toString(), ', "display_type": "number"},')); // Using number display_type for IDs
            }
        }

         // Add Status Effects (only active ones)
        // This requires iterating through stored effects and checking expiry.
        // A proper implementation would need a list of active effect types per token.
        // For this example, we will just add a generic "Status" attribute if ANY effect is active.
        // A better approach would involve tracking effect types in a dynamic array per token.
        // Due to limitations of iterating map keys/dynamic arrays within the strict gas limits
        // of tokenURI, this part is complex for a simple example.
        // Let's demonstrate by *attempting* to list a couple known types if active.
         string[] memory effectTypes = new string[](2); // Example hardcoded types
         effectTypes[0] = "RecentlyInteracted";
         effectTypes[1] = "StrengthBuff"; // Example from applyStatusEffect

         string memory activeEffectsString = "";
         for(uint i = 0; i < effectTypes.length; i++) {
             if(isStatusEffectActive(tokenId, effectTypes[i])) {
                 if(bytes(activeEffectsString).length > 0) {
                     activeEffectsString = string(abi.encodePacked(activeEffectsString, ", "));
                 }
                 activeEffectsString = string(abi.encodePacked(activeEffectsString, effectTypes[i]));
             }
         }

         if (bytes(activeEffectsString).length > 0) {
              attributesJson = string(abi.encodePacked(attributesJson, '{"trait_type": "Active Status Effects", "value": "', activeEffectsString, '"},'));
         }


        // Remove the trailing comma if attributes were added
        if (bytes(attributesJson).length > 1) { // Check if it's more than just "["
             assembly {
                // Remove the last two bytes (",")
                mstore(add(attributesJson, add(32, sub(bytes(attributesJson).length, 2))), 0)
                mstore(attributesJson, sub(bytes(attributesJson).length, 2))
            }
        }
        attributesJson = string(abi.encodePacked(attributesJson, "]")); // Close the attributes array

        // Basic JSON Structure
        string memory json = string(abi.encodePacked(
            '{"name": "Dynamic Avatar #', tokenId.toString(), '",',
            '"description": "An avatar evolving on-chain! Level: ', level.toString(), ', XP: ', xp.toString(), '",',
            // Replace with actual image URI if available, or a placeholder
            '"image": "', _baseURI, tokenId.toString(), '.png",',
            '"attributes": ', attributesJson,
            '}'
        ));

        // Encode JSON as Base64
        string memory base64Json = Base64.encode(bytes(json));

        // Return as data URI
        return string(abi.encodePacked("data:application/json;base64,", base64Json));
    }

    /// @notice Returns the value of a specific trait for an avatar.
    /// @param tokenId The ID of the avatar token.
    /// @param traitType The type of trait (e.g., "Strength").
    /// @return The value of the trait, or 0 if not set.
    function getTrait(uint256 tokenId, string calldata traitType) external view returns (uint256) {
        require(_exists(tokenId), InvalidTokenId());
        return _avatarTraits[tokenId][traitType];
    }

    /// @notice Returns all traits and their values for an avatar.
    /// @dev Note: This function can only return traits if you know the types in advance.
    /// Due to mapping limitations, getting *all* keys isn't efficient/possible on-chain.
    /// This implementation returns values for a few *known* trait types for demonstration.
    /// A real system might track active traits in a list.
    /// @param tokenId The ID of the avatar token.
    /// @return An array of Trait structs.
    function getAllTraits(uint256 tokenId) external view returns (Trait[] memory) {
        require(_exists(tokenId), InvalidTokenId());

        // Example: return values for hardcoded trait types
        string[] memory traitTypes = new string[](2);
        traitTypes[0] = "Strength";
        traitTypes[1] = "Intelligence";

        Trait[] memory traits = new Trait[](traitTypes.length);
        for (uint i = 0; i < traitTypes.length; i++) {
            traits[i] = Trait({
                traitType: traitTypes[i],
                value: _avatarTraits[tokenId][traitTypes[i]]
            });
        }
        return traits;
    }

    /// @notice Returns the ID of a specific component type attached to an avatar.
    /// @param tokenId The ID of the avatar token.
    /// @param componentType The type of component (e.g., "Hat").
    /// @return The ID of the component, or 0 if not attached.
    function getComponent(uint256 tokenId, string calldata componentType) external view returns (uint256) {
        require(_exists(tokenId), InvalidTokenId());
        return _avatarComponents[tokenId][componentType];
    }

     /// @notice Returns all components and their IDs for an avatar.
     /// @dev Similar to `getAllTraits`, this relies on knowing component types beforehand.
     /// @param tokenId The ID of the avatar token.
     /// @return An array of Component structs.
    function getAllComponents(uint256 tokenId) external view returns (Component[] memory) {
        require(_exists(tokenId), InvalidTokenId());

         // Example: return values for hardcoded component types
        string[] memory componentTypes = new string[](2);
        componentTypes[0] = "Hat";
        componentTypes[1] = "Weapon";

        Component[] memory components = new Component[](componentTypes.length);
        for (uint i = 0; i < componentTypes.length; i++) {
            components[i] = Component({
                componentType: componentTypes[i],
                componentId: _avatarComponents[tokenId][componentTypes[i]]
            });
        }
        return components;
    }

    /// @notice Returns the expiry timestamp of a specific status effect.
    /// @param tokenId The ID of the avatar token.
    /// @param effectType The type of status effect (e.g., "Poison").
    /// @return The expiry timestamp, or 0 if the effect is not active or doesn't exist.
    function getStatusEffectEndTime(uint256 tokenId, string calldata effectType) external view returns (uint256) {
        require(_exists(tokenId), InvalidTokenId());
        return _avatarStatusEffects[tokenId][effectType];
    }

    /// @notice Checks if a specific status effect is currently active.
    /// @param tokenId The ID of the avatar token.
    /// @param effectType The type of status effect.
    /// @return True if the effect exists and its end time is in the future, false otherwise.
    function isStatusEffectActive(uint256 tokenId, string calldata effectType) public view returns (bool) {
        require(_exists(tokenId), InvalidTokenId());
        uint256 endTime = _avatarStatusEffects[tokenId][effectType];
        return endTime > 0 && block.timestamp < endTime;
    }

     /// @notice Returns all currently active status effects for an avatar.
     /// @dev Similar to `getAllTraits`, this relies on knowing effect types beforehand.
     /// @param tokenId The ID of the avatar token.
     /// @return An array of StatusEffect structs.
    function getActiveStatusEffects(uint256 tokenId) external view returns (StatusEffect[] memory) {
        require(_exists(tokenId), InvalidTokenId());

        // Example: check for hardcoded effect types
        string[] memory effectTypes = new string[](2);
        effectTypes[0] = "RecentlyInteracted";
        effectTypes[1] = "StrengthBuff";

        StatusEffect[] memory activeEffects = new StatusEffect[](effectTypes.length);
        uint256 count = 0;
        for (uint i = 0; i < effectTypes.length; i++) {
            if (isStatusEffectActive(tokenId, effectTypes[i])) {
                activeEffects[count] = StatusEffect({
                    effectType: effectTypes[i],
                    endTime: _avatarStatusEffects[tokenId][effectTypes[i]]
                });
                count++;
            }
        }

        // Resize array to only include active effects
        StatusEffect[] memory result = new StatusEffect[](count);
        for (uint i = 0; i < count; i++) {
            result[i] = activeEffects[i];
        }
        return result;
    }


    /// @notice Returns the XP needed to reach a given level.
    /// @param level The level to query the threshold for.
    /// @return The required XP. Returns 0 if no threshold is set for that level.
    function getLevelXPThreshold(uint256 level) external view returns (uint256) {
        require(level > 0, "Level must be positive");
        return _levelXPThresholds[level];
    }

    /// @notice Returns a struct containing all relevant dynamic state data for an avatar.
    /// @dev Note: For traits, components, and status effects, this function relies on
    /// iterating through known types due to mapping limitations.
    /// @param tokenId The ID of the avatar token.
    /// @return A TokenState struct.
    function getTokenState(uint256 tokenId) external view returns (TokenState memory) {
        require(_exists(tokenId), InvalidTokenId());

        // This bundles up all the individual getter calls
        return TokenState({
            level: _avatarLevels[tokenId],
            xp: _avatarXP[tokenId],
            traits: getAllTraits(tokenId), // Calls the helper view function
            components: getAllComponents(tokenId), // Calls the helper view function
            statusEffects: getActiveStatusEffects(tokenId) // Calls the helper view function
        });
    }

     /// @notice Returns an array of all token IDs owned by a specific address.
     /// @param owner The address to query.
     /// @return An array of token IDs.
    function getOwnerAvatarIds(address owner) external view returns (uint256[] memory) {
        return _ownerTokenIds[owner];
    }


    // --- Internal Helper Functions ---

    /// @dev Checks if the message sender is the owner or an approved operator for the token.
    /// @param tokenId The ID of the token.
    function _checkTokenOwnershipOrApproved(uint256 tokenId) internal view {
        address owner = ownerOf(tokenId);
        if (msg.sender != owner && !isApprovedForAll(owner, msg.sender)) {
            revert NotTokenOwnerOrApproved();
        }
    }

    /// @dev Gets the owner address of a token, used by internal functions before super._burn
    /// potentially clears ownership state.
    /// @param tokenId The ID of the token.
    /// @return The owner's address.
     function _getTokenOwnerAddress(uint256 tokenId) internal view returns (address) {
        // This helper is less critical with OZ >= 4.7 where _burn doesn't clear owner immediately,
        // but is good practice or needed with older versions/custom _burn.
        // In this case, super._burn() in the override happens *before* we access ownerOf(),
        // so we MUST use the internal state if ownerOf were to be cleared instantly.
        // OZ's _owner mapping is internal, so we'd need to access it directly or trust super() behavior.
        // Sticking to ownerOf() for clarity, assuming OZ handles it correctly.
        return ownerOf(tokenId);
     }
}
```