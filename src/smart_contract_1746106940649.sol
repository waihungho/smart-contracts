Okay, here is a Solidity smart contract implementing a "Dynamic Skill-Bound Composable Asset System". This contract represents unique digital assets (like NFTs) that can evolve over time. They have dynamic traits, gain skills, earn experience to level up, can have components attached to them, and incorporate time-based mechanics.

It combines elements of dynamic NFTs, skill systems, progression, and composability beyond standard token specifications. It aims to be creative and includes > 20 functions.

**Smart Contract: DynamicSkillBoundAssetSystem**

**Concept:** A system for managing unique digital assets (tokens) that possess dynamic properties (traits), skills, experience, level, and slots for attaching components. The assets evolve based on on-chain interactions, some of which may be gated by time.

**Key Features:**
*   **Unique Assets:** ERC721-like ownership model.
*   **Dynamic Traits:** String-based traits that can be updated post-minting.
*   **Skill System:** Assets can learn and level up specific skills.
*   **Progression:** Experience points (XP) lead to asset level-ups.
*   **Composability:** Assets have predefined slots where 'components' (represented by IDs) can be attached/detached.
*   **Time-Based Mechanics:** Actions can be gated by cooldowns based on the last interaction time.
*   **Role-Based Permissions:** Specific addresses can be granted permission to update skills for assets they don't own (e.g., a connected game contract).

**Outline:**
1.  **License and Pragma:** Standard Solidity setup.
2.  **Imports:** ERC165 for interface detection, Ownable for contract administration.
3.  **Error Definitions:** Custom errors for clearer revert reasons.
4.  **Data Structures:**
    *   `AssetData`: Struct holding the core state of an asset (level, XP, creation time, last interaction time).
    *   Mappings for traits, skills, and components.
    *   Mappings for standard ERC721 state (owners, approvals, operators).
    *   State variables for total supply, base URI, cooldown duration, and skill permission addresses.
5.  **Events:** Signaling key state changes (Mint, Burn, Transfer, TraitUpdate, SkillUpdate, LevelUp, ComponentAttach, ComponentDetach, PermissionChange).
6.  **Modifiers:** Custom modifiers for access control (`onlyOwner`, `onlyApprovedOrOwner`, `onlySkillPermission`).
7.  **Constructor:** Initializes the contract owner and default cooldown.
8.  **Internal Helper Functions:** Functions for internal logic (e.g., updating last interaction time, basic ERC721 transfers).
9.  **ERC721 Standard Functions:** Implementation of the required ERC721 interface functions.
10. **Asset Management Functions:** Minting and burning assets.
11. **Dynamic Trait Functions:** Setting and getting trait values.
12. **Skill System Functions:** Learning, increasing, and getting skill levels.
13. **Progression Functions:** Adding experience, getting level, checking/performing level-ups.
14. **Composable Slot Functions:** Attaching, detaching, and getting components in slots.
15. **Time-Based Functions:** Getting last interaction time, checking cooldown status.
16. **Administrative Functions:** Setting base URI, managing skill permissions, setting cooldown.
17. **ERC165 Interface Detection:** Implementing `supportsInterface`.

**Function Summary:**

*   **Standard ERC721 (9 functions):**
    *   `balanceOf(address owner) view`: Get the number of tokens owned by an address.
    *   `ownerOf(uint256 tokenId) view`: Get the owner of a specific token.
    *   `approve(address to, uint256 tokenId)`: Approve another address to transfer a specific token.
    *   `getApproved(uint256 tokenId) view`: Get the approved address for a specific token.
    *   `setApprovalForAll(address operator, bool approved)`: Grant or revoke approval for an operator to manage all of the caller's tokens.
    *   `isApprovedForAll(address owner, address operator) view`: Check if an operator is approved for an owner.
    *   `transferFrom(address from, address to, uint256 tokenId)`: Transfer token from one address to another (requires approval/ownership).
    *   `safeTransferFrom(address from, address to, uint256 tokenId)`: Safe transfer (checks if recipient can receive ERC721).
    *   `safeTransferFrom(address from, address to, uint256 tokenId, bytes data)`: Safe transfer with data.

*   **Asset Management (2 functions):**
    *   `mint(address to, uint256 tokenId)`: Mint a new asset to an address.
    *   `burn(uint256 tokenId)`: Burn an asset.

*   **Dynamic Traits (3 functions):**
    *   `setDynamicTrait(uint256 tokenId, string traitName, string traitValue)`: Set or update a dynamic trait for an asset.
    *   `getDynamicTrait(uint256 tokenId, string traitName) view`: Get the value of a specific dynamic trait.
    *   `getDynamicTraitKeys(uint256 tokenId) view`: Get a list of all dynamic trait names set for an asset.

*   **Skill System (4 functions):**
    *   `learnSkill(uint256 tokenId, string skillName)`: Add a new skill to an asset (initial level 1).
    *   `increaseSkillLevel(uint256 tokenId, string skillName)`: Increase the level of an existing skill by 1.
    *   `getSkillLevel(uint256 tokenId, string skillName) view`: Get the level of a specific skill.
    *   `getSkillKeys(uint256 tokenId) view`: Get a list of all skill names learned by an asset.

*   **Progression (4 functions):**
    *   `addExperience(uint256 tokenId, uint256 amount)`: Add experience points to an asset.
    *   `getLevel(uint256 tokenId) view`: Get the current level of an asset based on its experience.
    *   `checkLevelUp(uint256 tokenId) view`: Check if an asset has enough XP to level up.
    *   `levelUp(uint256 tokenId)`: Perform the level-up action for an asset (if eligible).

*   **Composable Slots (3 functions):**
    *   `attachComponent(uint256 tokenId, string slotName, uint256 componentId)`: Attach a component ID to a named slot on an asset.
    *   `detachComponent(uint256 tokenId, string slotName)`: Detach the component from a named slot.
    *   `getComponentInSlot(uint256 tokenId, string slotName) view`: Get the component ID in a specific slot.

*   **Time-Based Mechanics (3 functions):**
    *   `getLastInteractionTime(uint256 tokenId) view`: Get the timestamp of the last significant interaction with an asset.
    *   `canPerformAction(uint256 tokenId) view`: Check if the asset is out of its cooldown period since the last interaction.
    *   `getCooldownDuration() view`: Get the current global cooldown duration.

*   **Administrative (4 functions):**
    *   `setBaseURI(string baseURI)`: Set the base URI for token metadata.
    *   `grantSkillPermission(address account)`: Grant an address permission to update skills on *any* asset.
    *   `revokeSkillPermission(address account)`: Revoke skill permission from an address.
    *   `setCooldownDuration(uint256 duration)`: Set the global cooldown duration.

*   **Utility (1 function):**
    *   `tokenURI(uint256 tokenId) view`: Get the full metadata URI for a token. (Standard ERC721 optional, but useful).

*   **Interface Detection (1 function):**
    *   `supportsInterface(bytes4 interfaceId) view`: Standard ERC165 function to declare supported interfaces.

**Total Functions:** 9 (ERC721) + 2 (Asset Mgmt) + 3 (Traits) + 4 (Skills) + 4 (Progression) + 3 (Components) + 3 (Time) + 4 (Admin) + 1 (URI) + 1 (ERC165) = **34 Functions**

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC165/ERC165.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

// Outline:
// 1. License and Pragma
// 2. Imports
// 3. Error Definitions
// 4. Data Structures & State Variables
// 5. Events
// 6. Modifiers
// 7. Constructor
// 8. Internal Helper Functions
// 9. ERC721 Standard Functions
// 10. Asset Management Functions (Mint/Burn)
// 11. Dynamic Trait Functions
// 12. Skill System Functions
// 13. Progression Functions (XP/Level)
// 14. Composable Slot Functions
// 15. Time-Based Functions
// 16. Administrative Functions
// 17. ERC165 Interface Detection

// Function Summary:
// - Standard ERC721: balanceOf, ownerOf, approve, getApproved, setApprovalForAll, isApprovedForAll, transferFrom, safeTransferFrom(x2) (9 functions)
// - Asset Management: mint, burn (2 functions)
// - Dynamic Traits: setDynamicTrait, getDynamicTrait, getDynamicTraitKeys (3 functions)
// - Skill System: learnSkill, increaseSkillLevel, getSkillLevel, getSkillKeys (4 functions)
// - Progression: addExperience, getLevel, checkLevelUp, levelUp (4 functions)
// - Composable Slots: attachComponent, detachComponent, getComponentInSlot (3 functions)
// - Time-Based: getLastInteractionTime, canPerformAction, getCooldownDuration (3 functions)
// - Administrative: setBaseURI, grantSkillPermission, revokeSkillPermission, setCooldownDuration (4 functions)
// - Utility: tokenURI (1 function)
// - Interface Detection: supportsInterface (1 function)
// Total: 34 functions (plus internal helpers)


/**
 * @title DynamicSkillBoundAssetSystem
 * @dev A smart contract for managing dynamic digital assets with skills, progression, and composability.
 * This contract is a conceptual implementation demonstrating advanced features beyond standard token interfaces.
 * It incorporates ERC721-like ownership but is not a full, optimized ERC721 library implementation.
 */
contract DynamicSkillBoundAssetSystem is ERC165, Ownable {
    using Strings for uint256;

    // --- Error Definitions ---
    error AssetDoesNotExist(uint256 tokenId);
    error AssetAlreadyExists(uint256 tokenId);
    error NotApprovedOrOwner(uint256 tokenId);
    error SkillAlreadyKnown(uint256 tokenId, string skillName);
    error SkillNotKnown(uint256 tokenId, string skillName);
    error InsufficientExperience(uint256 tokenId);
    error CooldownActive(uint256 tokenId, uint256 timeRemaining);
    error RequiresSkillPermission(address account);
    error SlotAlreadyOccupied(uint256 tokenId, string slotName);
    error SlotEmpty(uint256 tokenId, string slotName);
    error NotOwnerOrSkillPermitted(uint256 tokenId, address caller);


    // --- Data Structures ---
    struct AssetData {
        uint256 level;
        uint256 experience;
        uint256 creationTime;
        uint256 lastInteractionTime; // Timestamp of last significant state-changing action
        // Note: Traits, Skills, and Components are stored in separate mappings for potentially better gas efficiency on access
    }

    // --- State Variables ---
    uint256 private _totalSupply;
    string private _baseTokenURI;
    uint256 private _cooldownDuration; // Global cooldown duration in seconds

    // ERC721-like state
    mapping(uint256 => address) private _owners;
    mapping(address => uint256) private _balances;
    mapping(uint256 => address) private _tokenApprovals;
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    // Asset Data
    mapping(uint256 => AssetData) private _assetData;

    // Dynamic Traits: tokenId -> traitName -> traitValue
    mapping(uint256 => mapping(string => string)) private _assetTraits;
    // Helper to list trait keys (gas expensive to list all from mapping)
    mapping(uint256 => string[]) private _assetTraitKeys;

    // Skills: tokenId -> skillName -> level
    mapping(uint256 => mapping(string => uint256)) private _assetSkills;
    // Helper to list skill keys
    mapping(uint256 => string[]) private _assetSkillKeys;

    // Composable Slots: tokenId -> slotName -> componentId
    mapping(uint256 => mapping(string => uint256)) private _assetComponents;
    // Helper to list occupied slot names
    mapping(uint256 => string[]) private _assetOccupiedSlots;


    // Role-Based Permissions (for external game logic, etc.)
    mapping(address => bool) private _skillPermission;


    // --- Events ---
    event AssetMinted(address indexed to, uint256 indexed tokenId);
    event AssetBurned(uint256 indexed tokenId);
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    event TraitUpdated(uint256 indexed tokenId, string traitName, string traitValue);
    event SkillUpdated(uint256 indexed tokenId, string skillName, uint256 newLevel);
    event LevelUp(uint256 indexed tokenId, uint256 newLevel);
    event ExperienceAdded(uint256 indexed tokenId, uint256 newExperience);
    event ComponentAttached(uint256 indexed tokenId, string slotName, uint256 componentId);
    event ComponentDetached(uint256 indexed tokenId, string slotName, uint256 componentId);
    event SkillPermissionChanged(address indexed account, bool hasPermission);
    event CooldownDurationChanged(uint256 newDuration);


    // --- Modifiers ---
    modifier onlyApprovedOrOwner(uint256 tokenId) {
        _assertAssetExists(tokenId);
        address owner = _owners[tokenId];
        if (msg.sender != owner && _tokenApprovals[tokenId] != msg.sender && !_operatorApprovals[owner][msg.sender]) {
            revert NotApprovedOrOwner(tokenId);
        }
        _;
    }

     modifier onlyOwnerOrSkillPermitted(uint256 tokenId) {
        _assertAssetExists(tokenId);
        address owner = _owners[tokenId];
        if (msg.sender != owner && !_skillPermission[msg.sender]) {
            revert NotOwnerOrSkillPermitted(tokenId, msg.sender);
        }
        _;
    }

    modifier onlySkillPermission() {
        if (!_skillPermission[msg.sender] && msg.sender != owner()) { // Allow owner too
             revert RequiresSkillPermission(msg.sender);
        }
        _;
    }


    // --- Constructor ---
    constructor(uint256 initialCooldownSeconds) Ownable(msg.sender) {
        _cooldownDuration = initialCooldownSeconds;
    }


    // --- Internal Helper Functions ---

    /**
     * @dev Checks if a token exists. Reverts if it doesn't.
     */
    function _assertAssetExists(uint256 tokenId) internal view {
        if (_owners[tokenId] == address(0)) {
            revert AssetDoesNotExist(tokenId);
        }
    }

    /**
     * @dev Safely transfers a token.
     * @param from The current owner of the token.
     * @param to The address to transfer the token to.
     * @param tokenId The token ID to transfer.
     */
    function _safeTransfer(address from, address to, uint256 tokenId) internal {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, ""), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Safely transfers a token with data.
     * @param from The current owner of the token.
     * @param to The address to transfer the token to.
     * @param tokenId The token ID to transfer.
     * @param data Additional data to pass to the recipient contract.
     */
     function _safeTransfer(address from, address to, uint256 tokenId, bytes memory data) internal {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Transfers a token.
     * @param from The current owner of the token.
     * @param to The address to transfer the token to.
     * @param tokenId The token ID to transfer.
     */
    function _transfer(address from, address to, uint256 tokenId) internal {
        _assertAssetExists(tokenId);
        require(_owners[tokenId] == from, "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");

        // Clear approvals
        _tokenApprovals[tokenId] = address(0);

        _balances[from]--;
        _balances[to]++;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    /**
     * @dev Mints a new token.
     * @param to The address to mint the token to.
     * @param tokenId The token ID to mint.
     */
    function _mint(address to, uint256 tokenId) internal {
        require(to != address(0), "ERC721: mint to the zero address");
        if (_owners[tokenId] != address(0)) {
             revert AssetAlreadyExists(tokenId);
        }

        _balances[to]++;
        _owners[tokenId] = to;
        _totalSupply++;

        // Initialize asset data
        _assetData[tokenId] = AssetData({
            level: 1,
            experience: 0,
            creationTime: block.timestamp,
            lastInteractionTime: block.timestamp
        });

        emit AssetMinted(to, tokenId);
        emit Transfer(address(0), to, tokenId); // ERC721 mint standard event
    }

    /**
     * @dev Burns a token.
     * @param tokenId The token ID to burn.
     */
    function _burn(uint256 tokenId) internal {
        _assertAssetExists(tokenId);
        address owner = _owners[tokenId];

        // Clear approvals
        _tokenApprovals[tokenId] = address(0);
        // Note: Operator approvals remain, as they are per owner

        _balances[owner]--;
        delete _owners[tokenId];
        delete _assetData[tokenId];
        // Note: Traits, skills, components mappings will retain data for this ID,
        // but it won't be accessible via existing token functions. A cleaner
        // implementation might iterate and delete from nested mappings, but
        // that is gas-intensive. For simplicity here, we leave them.
        // In a real system, use a data structure optimized for deletion or
        // accept the minor data retention for burned tokens.

        _totalSupply--;

        emit AssetBurned(tokenId);
        emit Transfer(owner, address(0), tokenId); // ERC721 burn standard event
    }

     /**
     * @dev Internal function to update the last interaction time for an asset.
     * @param tokenId The token ID to update.
     */
    function _updateLastInteractionTime(uint256 tokenId) internal {
        _assertAssetExists(tokenId);
        _assetData[tokenId].lastInteractionTime = block.timestamp;
    }

    /**
     * @dev Internal function to check if a contract is an ERC721Receiver.
     * @param from Address token is transferred from.
     * @param to Address token is transferred to.
     * @param tokenId The token ID.
     * @param data Additional data.
     * @return bool True if the transfer is safe.
     */
    function _checkOnERC721Received(address from, address to, uint256 tokenId, bytes memory data) private returns (bool) {
        if (to.code.length == 0) {
            return true; // EOA accounts are always safe
        }
        try IERC721Receiver(to).onERC721Received(msg.sender, from, tokenId, data) returns (bytes4 retval) {
            return retval == IERC721Receiver.onERC721Received.selector;
        } catch (bytes memory reason) {
            if (reason.length == 0) {
                revert("ERC721: transfer to non ERC721Receiver implementer");
            } else {
                assembly {
                    revert(add(32, reason), mload(reason))
                }
            }
        }
    }


    // --- ERC721 Standard Functions ---

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view returns (uint256) {
        require(owner != address(0), "ERC721: address zero is not a valid owner");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view returns (address) {
        _assertAssetExists(tokenId);
        return _owners[tokenId];
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public payable {
        _assertAssetExists(tokenId);
        address owner = _owners[tokenId];
        require(msg.sender == owner || _operatorApprovals[owner][msg.sender], "ERC721: approve caller is not owner nor approved for all");
        _tokenApprovals[tokenId] = to;
        emit Approval(owner, to, tokenId);
    }

     /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view returns (address) {
         _assertAssetExists(tokenId);
        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public {
        _operatorApprovals[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(address from, address to, uint256 tokenId) public payable {
        _transferAllowed(from, tokenId);
        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) public payable {
        _transferAllowed(from, tokenId);
        _safeTransfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public payable {
         _transferAllowed(from, tokenId);
        _safeTransfer(from, to, tokenId, data);
    }

    /**
     * @dev Checks if the caller is allowed to transfer a token.
     * @param from The current owner.
     * @param tokenId The token ID.
     */
    function _transferAllowed(address from, uint256 tokenId) internal view {
        _assertAssetExists(tokenId);
        address owner = _owners[tokenId];
        require(from == owner, "ERC721: transfer from incorrect owner");
        require(msg.sender == owner || _tokenApprovals[tokenId] == msg.sender || _operatorApprovals[owner][msg.sender], "ERC721: transfer caller is not owner nor approved");
    }


    // --- Asset Management Functions ---

    /**
     * @dev Mints a new asset. Callable only by owner.
     * @param to The address to mint the asset to.
     * @param tokenId The ID of the asset to mint.
     */
    function mint(address to, uint256 tokenId) public onlyOwner {
        _mint(to, tokenId);
    }

    /**
     * @dev Burns an asset. Callable only by owner or approved.
     * @param tokenId The ID of the asset to burn.
     */
    function burn(uint256 tokenId) public onlyApprovedOrOwner(tokenId) {
        _burn(tokenId);
    }


    // --- Dynamic Trait Functions ---

    /**
     * @dev Sets or updates a dynamic trait for an asset.
     * Callable only by owner or approved address.
     * @param tokenId The ID of the asset.
     * @param traitName The name of the trait (e.g., "color", "mood").
     * @param traitValue The value of the trait.
     */
    function setDynamicTrait(uint256 tokenId, string memory traitName, string memory traitValue) public onlyApprovedOrOwner(tokenId) {
        _assertAssetExists(tokenId);
        // Add traitName to keys if it's new
        if (bytes(_assetTraits[tokenId][traitName]).length == 0) {
             // Check if traitName is already in the list to avoid duplicates (simple check)
            bool found = false;
            for(uint i = 0; i < _assetTraitKeys[tokenId].length; i++) {
                if (keccak256(bytes(_assetTraitKeys[tokenId][i])) == keccak256(bytes(traitName))) {
                    found = true;
                    break;
                }
            }
            if (!found) {
                 _assetTraitKeys[tokenId].push(traitName);
            }
        }
        _assetTraits[tokenId][traitName] = traitValue;
        _updateLastInteractionTime(tokenId); // Trait update is a significant interaction
        emit TraitUpdated(tokenId, traitName, traitValue);
    }

    /**
     * @dev Gets the value of a specific dynamic trait for an asset.
     * @param tokenId The ID of the asset.
     * @param traitName The name of the trait.
     * @return The value of the trait. Returns empty string if trait not set.
     */
    function getDynamicTrait(uint256 tokenId, string memory traitName) public view returns (string memory) {
        _assertAssetExists(tokenId);
        return _assetTraits[tokenId][traitName];
    }

    /**
     * @dev Gets a list of all dynamic trait names set for an asset.
     * Note: The order is not guaranteed and deleting traits is not supported here.
     * @param tokenId The ID of the asset.
     * @return An array of trait names.
     */
    function getDynamicTraitKeys(uint256 tokenId) public view returns (string[] memory) {
         _assertAssetExists(tokenId);
        return _assetTraitKeys[tokenId];
    }


    // --- Skill System Functions ---

    /**
     * @dev Adds a new skill to an asset with initial level 1.
     * Callable by owner, approved, or skill-permissioned address.
     * @param tokenId The ID of the asset.
     * @param skillName The name of the skill.
     */
    function learnSkill(uint256 tokenId, string memory skillName) public onlyOwnerOrSkillPermitted(tokenId) {
        _assertAssetExists(tokenId);
        if (_assetSkills[tokenId][skillName] > 0) {
            revert SkillAlreadyKnown(tokenId, skillName);
        }

        _assetSkills[tokenId][skillName] = 1;
         // Add skillName to keys if it's new
         bool found = false;
         for(uint i = 0; i < _assetSkillKeys[tokenId].length; i++) {
             if (keccak256(bytes(_assetSkillKeys[tokenId][i])) == keccak256(bytes(skillName))) {
                 found = true;
                 break;
             }
         }
         if (!found) {
              _assetSkillKeys[tokenId].push(skillName);
         }

        _updateLastInteractionTime(tokenId); // Learning a skill is significant
        emit SkillUpdated(tokenId, skillName, 1);
    }

    /**
     * @dev Increases the level of an existing skill by 1.
     * Callable by owner, approved, or skill-permissioned address.
     * @param tokenId The ID of the asset.
     * @param skillName The name of the skill.
     */
    function increaseSkillLevel(uint256 tokenId, string memory skillName) public onlyOwnerOrSkillPermitted(tokenId) {
        _assertAssetExists(tokenId);
        if (_assetSkills[tokenId][skillName] == 0) {
            revert SkillNotKnown(tokenId, skillName);
        }
        _assetSkills[tokenId][skillName]++;
        _updateLastInteractionTime(tokenId); // Skill increase is significant
        emit SkillUpdated(tokenId, skillName, _assetSkills[tokenId][skillName]);
    }

    /**
     * @dev Gets the level of a specific skill for an asset.
     * @param tokenId The ID of the asset.
     * @param skillName The name of the skill.
     * @return The level of the skill (0 if not known).
     */
    function getSkillLevel(uint256 tokenId, string memory skillName) public view returns (uint256) {
        _assertAssetExists(tokenId);
        return _assetSkills[tokenId][skillName];
    }

    /**
     * @dev Gets a list of all skill names known by an asset.
     * Note: The order is not guaranteed.
     * @param tokenId The ID of the asset.
     * @return An array of skill names.
     */
    function getSkillKeys(uint256 tokenId) public view returns (string[] memory) {
         _assertAssetExists(tokenId);
        return _assetSkillKeys[tokenId];
    }


    // --- Progression Functions ---

    /**
     * @dev Adds experience points to an asset.
     * Callable by owner, approved, or skill-permissioned address (as XP gain might be linked to actions).
     * @param tokenId The ID of the asset.
     * @param amount The amount of experience to add.
     */
    function addExperience(uint256 tokenId, uint256 amount) public onlyOwnerOrSkillPermitted(tokenId) {
        _assertAssetExists(tokenId);
        _assetData[tokenId].experience += amount;
        _updateLastInteractionTime(tokenId); // XP gain is significant
        emit ExperienceAdded(tokenId, _assetData[tokenId].experience);
    }

    /**
     * @dev Gets the current level of an asset based on its experience.
     * This function implements a simple XP-to-level formula (e.g., Level = floor(sqrt(XP))).
     * @param tokenId The ID of the asset.
     * @return The calculated level of the asset.
     */
    function getLevel(uint256 tokenId) public view returns (uint256) {
         _assertAssetExists(tokenId);
        // Simple example formula: Level = floor(sqrt(XP)) + 1
        // More complex formulas involving state could be used.
        // For simplicity, we keep level stored in struct and update on levelUp.
        // This getter just returns the stored level.
        return _assetData[tokenId].level;
    }

     /**
      * @dev Checks if an asset has enough experience to level up.
      * Implements the level-up requirement logic.
      * @param tokenId The ID of the asset.
      * @return True if the asset can level up, false otherwise.
      */
    function checkLevelUp(uint256 tokenId) public view returns (bool) {
        _assertAssetExists(tokenId);
        uint256 currentLevel = _assetData[tokenId].level;
        uint256 currentXP = _assetData[tokenId].experience;

        // Example level-up requirement: XP needed = Level * 100
        uint256 xpRequiredForNextLevel = currentLevel * 100;

        return currentXP >= xpRequiredForNextLevel;
    }

    /**
     * @dev Performs the level-up action for an asset.
     * Resets XP (or subtracts required amount) and increments level.
     * Callable by owner, approved, or skill-permissioned address.
     * @param tokenId The ID of the asset.
     */
    function levelUp(uint256 tokenId) public onlyOwnerOrSkillPermitted(tokenId) {
        _assertAssetExists(tokenId);
        require(checkLevelUp(tokenId), "Asset: Not enough experience to level up");

        uint256 currentLevel = _assetData[tokenId].level;
        uint256 xpRequired = currentLevel * 100; // Matching checkLevelUp logic

        _assetData[tokenId].level++;
        _assetData[tokenId].experience -= xpRequired; // Subtract required XP, keep remainder

        _updateLastInteractionTime(tokenId); // Level up is significant
        emit LevelUp(tokenId, _assetData[tokenId].level);
        emit ExperienceAdded(tokenId, _assetData[tokenId].experience); // Emit XP change after level up
    }


    // --- Composable Slot Functions ---

    /**
     * @dev Attaches a component ID to a specific named slot on an asset.
     * Requires the slot to be empty.
     * Callable by owner or approved.
     * @param tokenId The ID of the asset.
     * @param slotName The name of the slot (e.g., "head", "weapon", "armor").
     * @param componentId The ID of the component being attached.
     */
    function attachComponent(uint256 tokenId, string memory slotName, uint256 componentId) public onlyApprovedOrOwner(tokenId) {
        _assertAssetExists(tokenId);
        if (_assetComponents[tokenId][slotName] != 0) {
            revert SlotAlreadyOccupied(tokenId, slotName);
        }

        _assetComponents[tokenId][slotName] = componentId;

         // Add slotName to occupied list if new
         bool found = false;
         for(uint i = 0; i < _assetOccupiedSlots[tokenId].length; i++) {
             if (keccak256(bytes(_assetOccupiedSlots[tokenId][i])) == keccak256(bytes(slotName))) {
                 found = true;
                 break;
             }
         }
         if (!found) {
              _assetOccupiedSlots[tokenId].push(slotName);
         }

        _updateLastInteractionTime(tokenId); // Attaching component is significant
        emit ComponentAttached(tokenId, slotName, componentId);
    }

    /**
     * @dev Detaches the component from a specific named slot on an asset.
     * Requires the slot to be occupied.
     * Callable by owner or approved.
     * @param tokenId The ID of the asset.
     * @param slotName The name of the slot.
     */
    function detachComponent(uint256 tokenId, string memory slotName) public onlyApprovedOrOwner(tokenId) {
        _assertAssetExists(tokenId);
        uint256 currentComponentId = _assetComponents[tokenId][slotName];
        if (currentComponentId == 0) {
            revert SlotEmpty(tokenId, slotName);
        }

        delete _assetComponents[tokenId][slotName];

        // Note: Removing from _assetOccupiedSlots array is gas-intensive and complex.
        // For simplicity in this example, we leave the slotName in the array.
        // Checking `getComponentInSlot` is the definitive way to see if a slot is truly occupied.
        // A real implementation might use a linked list or other structure for slots
        // if frequent detachment/enumeration is critical and optimized.

        _updateLastInteractionTime(tokenId); // Detaching component is significant
        emit ComponentDetached(tokenId, slotName, currentComponentId);
    }

    /**
     * @dev Gets the component ID currently in a specific named slot for an asset.
     * @param tokenId The ID of the asset.
     * @param slotName The name of the slot.
     * @return The component ID (0 if the slot is empty).
     */
    function getComponentInSlot(uint256 tokenId, string memory slotName) public view returns (uint256) {
        _assertAssetExists(tokenId);
        return _assetComponents[tokenId][slotName];
    }

    /**
     * @dev Gets a list of names for slots that are currently occupied on an asset.
     * Note: This list might contain names of slots that were once occupied but now empty,
     * due to the limitation of deleting from dynamic arrays in mappings. Always verify
     * occupation status using `getComponentInSlot`.
     * @param tokenId The ID of the asset.
     * @return An array of occupied slot names.
     */
    function getOccupiedSlots(uint256 tokenId) public view returns (string[] memory) {
         _assertAssetExists(tokenId);
        return _assetOccupiedSlots[tokenId];
    }


    // --- Time-Based Functions ---

    /**
     * @dev Gets the timestamp of the last significant interaction with an asset.
     * This timestamp is updated by functions like addExperience, increaseSkillLevel, levelUp, etc.
     * @param tokenId The ID of the asset.
     * @return The Unix timestamp of the last interaction.
     */
    function getLastInteractionTime(uint256 tokenId) public view returns (uint256) {
        _assertAssetExists(tokenId);
        return _assetData[tokenId].lastInteractionTime;
    }

    /**
     * @dev Checks if an asset is out of its cooldown period since the last interaction.
     * Can be used to gate certain actions in external logic or within the contract.
     * @param tokenId The ID of the asset.
     * @return True if the cooldown has passed, false otherwise.
     */
    function canPerformAction(uint256 tokenId) public view returns (bool) {
        _assertAssetExists(tokenId);
        uint256 lastInteraction = _assetData[tokenId].lastInteractionTime;
        if (lastInteraction == 0) return true; // No interaction recorded means no cooldown
        return block.timestamp >= lastInteraction + _cooldownDuration;
    }

     /**
      * @dev Gets the current global cooldown duration in seconds.
      * @return The cooldown duration.
      */
    function getCooldownDuration() public view returns (uint256) {
        return _cooldownDuration;
    }


    // --- Administrative Functions ---

    /**
     * @dev Sets the base URI for token metadata.
     * Callable only by the owner.
     * @param baseURI The new base URI.
     */
    function setBaseURI(string memory baseURI) public onlyOwner {
        _baseTokenURI = baseURI;
    }

     /**
      * @dev Grants an address permission to update skills (learn/increase) on *any* asset.
      * This is useful for allowing external game logic contracts to affect assets.
      * Callable only by the owner.
      * @param account The address to grant permission to.
      */
    function grantSkillPermission(address account) public onlyOwner {
        require(account != address(0), "Grant Permission to zero address");
        _skillPermission[account] = true;
        emit SkillPermissionChanged(account, true);
    }

     /**
      * @dev Revokes skill update permission from an address.
      * Callable only by the owner.
      * @param account The address to revoke permission from.
      */
    function revokeSkillPermission(address account) public onlyOwner {
        _skillPermission[account] = false;
        emit SkillPermissionChanged(account, false);
    }

     /**
      * @dev Checks if an address has skill update permission.
      * @param account The address to check.
      * @return True if the account has permission, false otherwise.
      */
    function hasSkillPermission(address account) public view returns (bool) {
        return _skillPermission[account];
    }

    /**
     * @dev Sets the global cooldown duration for time-based mechanics.
     * Callable only by the owner.
     * @param duration The new cooldown duration in seconds.
     */
    function setCooldownDuration(uint256 duration) public onlyOwner {
        _cooldownDuration = duration;
        emit CooldownDurationChanged(duration);
    }


    // --- Utility Functions ---

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     * Returns the metadata URI for a token, combining the base URI and token ID.
     * Note: A real implementation might require an API to serve dynamic JSON based on asset state.
     */
    function tokenURI(uint256 tokenId) public view returns (string memory) {
        _assertAssetExists(tokenId);
        return bytes(_baseTokenURI).length > 0
            ? string(abi.encodePacked(_baseTokenURI, tokenId.toString()))
            : ""; // Return empty string if base URI is not set
    }


    // --- ERC165 Interface Detection ---

    /**
     * @dev See {ERC165-supportsInterface}.
     * Declares support for ERC165 and ERC721 interfaces.
     */
    function supportsInterface(bytes4 interfaceId) public view override(ERC165) returns (bool) {
        // ERC721 interface ID
        bytes4 interfaceIdERC721 = 0x80ac58cd;
        // ERC721Metadata interface ID (optional, but tokenURI implies it)
        bytes4 interfaceIdERC721Metadata = 0x5b5e139f;

        return interfaceId == type(IERC165).interfaceId ||
               interfaceId == interfaceIdERC721 ||
               interfaceId == interfaceIdERC721Metadata ||
               super.supportsInterface(interfaceId);
    }

    // Declare IERC721 and IERC721Metadata interfaces being supported
    // Note: The functions themselves are implemented above.
    // This section is just to satisfy the compiler/linter if needed for full interface compliance checks.
    // This specific contract does *not* inherit from OpenZeppelin's ERC721 base,
    // it implements the *interface* functions directly.
    // interface IERC721 {
    //     event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    //     event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    //     event ApprovalForAll(address indexed owner, address indexed operator, bool approved);
    //     function balanceOf(address owner) external view returns (uint256 balance);
    //     function ownerOf(uint256 tokenId) external view returns (address owner);
    //     function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
    //     function safeTransferFrom(address from, address to, uint256 tokenId) external;
    //     function transferFrom(address from, address to, uint256 tokenId) external;
    //     function approve(address to, uint256 tokenId) external;
    //     function getApproved(uint256 tokenId) external view returns (address operator);
    //     function setApprovalForAll(address operator, bool _approved) external;
    //     function isApprovedForAll(address owner, address operator) external view returns (bool);
    //     function supportsInterface(bytes4 interfaceId) external view returns (bool);
    // }
    // interface IERC721Metadata is IERC721 {
    //     function name() external view returns (string calldata); // Not implemented in this contract as per request not to duplicate OZ fully
    //     function symbol() external view returns (string calldata); // Not implemented
    //     function tokenURI(uint256 tokenId) external view returns (string calldata);
    // }
    // interface IERC721Receiver {
    //     function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external returns (bytes4);
    // }
}
```