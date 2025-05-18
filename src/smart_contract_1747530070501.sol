Okay, let's design a smart contract representing a "SoulBound Skill Tree". This contract will manage non-transferable tokens (SBTs) that represent learned skills or achievements. Users can accumulate these skills, which might unlock certain 'abilities' or prove their qualifications on-chain.

Here's the outline and function summary, followed by the Solidity code.

---

**Outline:**

1.  **Contract Definition:** Inherits from ERC721Enumerable and AccessControl.
2.  **Custom Errors:** Specific errors for clearer reverts.
3.  **Events:** To signal important actions (skill definition, granting, etc.).
4.  **Structs:** Define the structure for a `SkillDefinition`.
5.  **State Variables:** Mappings and arrays to store skill definitions, user skills, token data, roles, etc.
6.  **Access Control Roles:** Define roles for administrators.
7.  **Constructor:** Initializes roles and potentially the base token URI.
8.  **ERC721 Overrides (Soulbound Logic):** Implement non-transferability and custom token URI.
9.  **Admin Functions:** Functions executable only by specific roles (defining/updating skills, granting/revoking skills, managing roles, setting metadata).
10. **User/Query Functions:** Functions for users or anyone to query skill details, user skills, eligibility, and unlocked abilities.
11. **Internal Helper Functions:** Logic reused within the contract (e.g., checking prerequisites, managing user skill lists).

**Function Summary:**

*   **`constructor(string name_, string symbol_, string baseTokenURI_)`**: Initializes the contract, sets ERC721 name/symbol, base URI, and grants the deployer default admin role.
*   **`defineSkill(uint256 skillId, string calldata name, string calldata description, uint256[] calldata prerequisites, string[] calldata effects)`**: (Admin) Defines a new skill with its metadata, dependencies, and associated effects/abilities.
*   **`updateSkillMetadata(uint256 skillId, string calldata name, string calldata description)`**: (Admin) Updates the name and description of an existing skill definition.
*   **`updateSkillPrerequisites(uint256 skillId, uint256[] calldata prerequisites)`**: (Admin) Updates the prerequisite skill IDs for an existing skill definition.
*   **`updateSkillEffects(uint256 skillId, string[] calldata effects)`**: (Admin) Updates the effects/abilities associated with an existing skill definition.
*   **`grantSkill(address to, uint256 skillId)`**: (Admin) Grants a specific skill token to an address, checking if prerequisites are met and the skill definition is active. Mints a new SBT.
*   **`revokeSkill(address from, uint256 skillId)`**: (Admin) Revokes a previously granted skill token instance from an address by marking it inactive. (Does not burn the token for history, but disables its effects/`hasSkill` check).
*   **`isSkillActive(uint256 skillId)`**: (Query) Checks if a skill definition is currently active (can be granted).
*   **`hasSkill(address user, uint256 skillId)`**: (Query) Checks if a user actively holds an instance of a specific skill (granted and not revoked).
*   **`getSkillsOwnedBy(address user)`**: (Query) Returns a list of skill IDs the user actively holds.
*   **`isEligibleToLearn(address user, uint256 skillId)`**: (Query) Checks if a user meets all the prerequisites for a given skill definition.
*   **`getSkillDetails(uint256 skillId)`**: (Query) Returns the full details of a skill definition (name, description, prereqs, effects, active status).
*   **`getSkillEffects(uint256 skillId)`**: (Query) Returns just the list of effect strings for a skill definition.
*   **`checkAbility(address user, string calldata ability)`**: (Query) Checks if a user possesses *any* active skill that grants a specific named ability.
*   **`getAllSkillDefinitions()`**: (Query) Returns a list of all defined skill IDs in the system.
*   **`getTotalSkillDefinitions()`**: (Query) Returns the total count of defined skills.
*   **`updateBaseTokenURI(string calldata baseTokenURI_)`**: (Admin) Updates the base URI used for generating token metadata URIs.
*   **`tokenURI(uint256 tokenId)`**: (ERC721 Override) Returns the metadata URI for a specific skill token instance. Looks up the skill ID from the token ID and constructs the URI.
*   **`ownerOf(uint256 tokenId)`**: (ERC721 Override) Returns the owner of a skill token.
*   **`balanceOf(address owner)`**: (ERC721 Override) Returns the number of skill tokens owned by an address.
*   **`totalSupply()`**: (ERC721 Override) Returns the total number of skill token instances minted.
*   **`tokenByIndex(uint256 index)`**: (ERC721 Enumerable Override) Returns the token ID at a given index (for global enumeration).
*   **`tokenOfOwnerByIndex(address owner, uint256 index)`**: (ERC721 Enumerable Override) Returns the token ID at a given index for a specific owner (for owner enumeration).
*   **`transferFrom(address from, address to, uint256 tokenId)`**: (ERC721 Override) Reverts - tokens are soulbound.
*   **`safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data)`**: (ERC721 Override) Reverts - tokens are soulbound.
*   **`safeTransferFrom(address from, address to, uint256 tokenId)`**: (ERC721 Override) Reverts - tokens are soulbound.
*   **`approve(address to, uint256 tokenId)`**: (ERC721 Override) Reverts - tokens are soulbound.
*   **`setApprovalForAll(address operator, bool approved)`**: (ERC721 Override) Reverts - tokens are soulbound.
*   **`getApproved(uint256 tokenId)`**: (ERC721 Override) Reverts or returns zero address.
*   **`isApprovedForAll(address owner, address operator)`**: (ERC721 Override) Reverts or returns false.
*   **`grantRole(bytes32 role, address account)`**: (Admin) Grants a specific role to an address (from AccessControl).
*   **`revokeRole(bytes32 role, address account)`**: (Admin) Revokes a specific role from an address (from AccessControl).
*   **`renounceRole(bytes32 role)`**: (User) Renounces a role held by the caller (from AccessControl).
*   **`getRoleAdmin(bytes32 role)`**: (Query) Returns the admin role for a given role (from AccessControl).
*   **`hasRole(bytes32 role, address account)`**: (Query) Checks if an account has a specific role (from AccessControl).
*   **`supportsInterface(bytes4 interfaceId)`**: (Query) Standard ERC165 interface support check.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Base64.sol";

// Outline:
// 1. Contract Definition (Inherits ERC721Enumerable, AccessControl)
// 2. Custom Errors
// 3. Events
// 4. Structs (SkillDefinition)
// 5. State Variables
// 6. Access Control Roles
// 7. Constructor
// 8. ERC721 Overrides (Soulbound Logic)
// 9. Admin Functions (define/update skills, grant/revoke skills, manage roles, set metadata)
// 10. User/Query Functions (check skills, eligibility, abilities, get details)
// 11. Internal Helper Functions

// Function Summary:
// - constructor(string name_, string symbol_, string baseTokenURI_)
// - defineSkill(uint256 skillId, string calldata name, string calldata description, uint256[] calldata prerequisites, string[] calldata effects) (Admin)
// - updateSkillMetadata(uint256 skillId, string calldata name, string calldata description) (Admin)
// - updateSkillPrerequisites(uint256 skillId, uint256[] calldata prerequisites) (Admin)
// - updateSkillEffects(uint256 skillId, string[] calldata effects) (Admin)
// - grantSkill(address to, uint256 skillId) (Admin)
// - revokeSkill(address from, uint256 skillId) (Admin)
// - isSkillActive(uint256 skillId) (Query)
// - hasSkill(address user, uint256 skillId) (Query)
// - getSkillsOwnedBy(address user) (Query)
// - isEligibleToLearn(address user, uint256 skillId) (Query)
// - getSkillDetails(uint256 skillId) (Query)
// - getSkillEffects(uint256 skillId) (Query)
// - checkAbility(address user, string calldata ability) (Query)
// - getAllSkillDefinitions() (Query)
// - getTotalSkillDefinitions() (Query)
// - updateBaseTokenURI(string calldata baseTokenURI_) (Admin)
// - tokenURI(uint256 tokenId) (ERC721 Override)
// - ownerOf(uint256 tokenId) (ERC721 Override)
// - balanceOf(address owner) (ERC721 Override)
// - totalSupply() (ERC721 Override)
// - tokenByIndex(uint256 index) (ERC721 Enumerable Override)
// - tokenOfOwnerByIndex(address owner, uint256 index) (ERC721 Enumerable Override)
// - transferFrom / safeTransferFrom (ERC721 Overrides) -> Revert (Soulbound)
// - approve / setApprovalForAll (ERC721 Overrides) -> Revert (Soulbound)
// - getApproved / isApprovedForAll (ERC721 Overrides) -> Revert/Zero (Soulbound)
// - grantRole / revokeRole / renounceRole / getRoleAdmin / hasRole (AccessControl)
// - supportsInterface (ERC165)

contract SoulBoundSkillTree is ERC721Enumerable, AccessControl {
    using Counters for Counters.Counter;
    using Strings for uint256;

    // --- 2. Custom Errors ---
    error SkillAlreadyDefined(uint256 skillId);
    error SkillNotFound(uint256 skillId);
    error PrerequisiteNotMet(uint256 prerequisiteSkillId);
    error SkillGrantFailed(string reason);
    error TransferNotAllowed(); // For soulbound tokens
    error SkillNotOwned(address user, uint256 skillId);

    // --- 3. Events ---
    event SkillDefined(uint256 indexed skillId, string name);
    event SkillMetadataUpdated(uint256 indexed skillId, string name, string description);
    event SkillPrerequisitesUpdated(uint256 indexed skillId, uint256[] prerequisites);
    event SkillEffectsUpdated(uint256 indexed skillId, string[] effects);
    event SkillGranted(address indexed user, uint256 indexed skillId, uint256 indexed tokenId);
    event SkillRevoked(address indexed user, uint256 indexed skillId, uint256 indexed tokenId);
    event AbilityUnlocked(address indexed user, string ability);

    // --- 6. Access Control Roles ---
    bytes32 public constant DEFAULT_ADMIN_ROLE = keccak256("DEFAULT_ADMIN_ROLE");
    bytes32 public constant SKILL_DEFINER_ROLE = keccak256("SKILL_DEFINER_ROLE"); // Role to define and update skill definitions
    bytes32 public constant SKILL_GRANTER_ROLE = keccak256("SKILL_GRANTER_ROLE"); // Role to grant and revoke skills to users

    // --- 4. Structs ---
    struct SkillDefinition {
        string name;
        string description;
        uint256[] prerequisites;
        string[] effects; // e.g., ["CanAccessLevel2", "CanProposeFeature"]
        bool exists;      // Helper to check if a skillId is defined
        bool isActive;    // Can this skill be granted? (Allows soft deactivation)
    }

    // --- 5. State Variables ---
    // Maps skill ID to its definition
    mapping(uint256 => SkillDefinition) private _skillDefinitions;
    // List of all defined skill IDs
    uint256[] private _definedSkillIds;

    // Maps user address to a list of skill IDs they own *actively*
    mapping(address => uint256[] private) _ownerSkillIds;
    // Helper mapping for quick check if user owns a skill ID actively
    mapping(address => mapping(uint256 => bool)) private _ownerHasActiveSkill;

    // Maps a token ID to the skill ID it represents
    mapping(uint256 => uint256) private _skillIdByTokenId;
    // Maps a user address and skill ID to the specific token ID they own
    mapping(address => mapping(uint256 => uint256)) private _tokenIdByOwnerAndSkill;


    // Counter for unique token IDs
    Counters.Counter private _tokenIds;

    // Base URI for token metadata (can be updated)
    string private _baseTokenURI;

    // --- 7. Constructor ---
    constructor(string memory name_, string memory symbol_, string memory baseTokenURI_)
        ERC721(name_, symbol_)
    {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(SKILL_DEFINER_ROLE, msg.sender);
        _grantRole(SKILL_GRANTER_ROLE, msg.sender);
        _baseTokenURI = baseTokenURI_;
    }

    // --- 8. ERC721 Overrides (Soulbound Logic) ---

    // Make tokens non-transferable
    function transferFrom(address from, address to, uint256 tokenId) public pure override {
        revert TransferNotAllowed();
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public pure override {
        revert TransferNotAllowed();
    }

     function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public pure override {
        revert TransferNotAllowed();
    }

    function approve(address to, uint256 tokenId) public pure override {
        revert TransferNotAllowed();
    }

    function setApprovalForAll(address operator, bool approved) public pure override {
        revert TransferNotAllowed();
    }

    // Override to reflect soulbound nature
    function getApproved(uint256 tokenId) public view override returns (address) {
        // Revert or return zero address - reverting is more explicit
        revert TransferNotAllowed();
    }

    function isApprovedForAll(address owner, address operator) public view override returns (bool) {
        // Revert or return false
        revert TransferNotAllowed();
    }

    // Override tokenURI to generate metadata specific to the skill
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        if (!_exists(tokenId)) {
            revert ERC721NonexistentToken(tokenId);
        }

        uint256 skillId = _skillIdByTokenId[tokenId];
        SkillDefinition storage skill = _skillDefinitions[skillId];

        // Simple metadata JSON for demonstration.
        // In practice, this might point to an IPFS hash or a service that generates the JSON.
        string memory json = string(abi.encodePacked(
            '{"name": "', skill.name, ' (Skill #', skillId.toString(), ')",',
            '"description": "', skill.description, '",',
            '"attributes": [',
            '{"trait_type": "Skill ID", "value": ', skillId.toString(), '}',
            ']',
             // Add effects as attributes? Or another field? Let's keep it simple for the URI.
            '}'
        ));

        // Encode JSON to Base64 data URI
        string memory base64Json = Base64.encode(bytes(json));

        return string(abi.encodePacked("data:application/json;base64,", base64Json));
    }


    // --- 9. Admin Functions ---

    function defineSkill(
        uint256 skillId,
        string calldata name,
        string calldata description,
        uint256[] calldata prerequisites,
        string[] calldata effects
    ) external onlyRole(SKILL_DEFINER_ROLE) {
        if (_skillDefinitions[skillId].exists) {
            revert SkillAlreadyDefined(skillId);
        }

        _skillDefinitions[skillId] = SkillDefinition({
            name: name,
            description: description,
            prerequisites: prerequisites,
            effects: effects,
            exists: true,
            isActive: true // New skills are active by default
        });
        _definedSkillIds.push(skillId);

        emit SkillDefined(skillId, name);
    }

    function updateSkillMetadata(
        uint256 skillId,
        string calldata name,
        string calldata description
    ) external onlyRole(SKILL_DEFINER_ROLE) {
        if (!_skillDefinitions[skillId].exists) {
            revert SkillNotFound(skillId);
        }
        SkillDefinition storage skill = _skillDefinitions[skillId];
        skill.name = name;
        skill.description = description;

        emit SkillMetadataUpdated(skillId, name, description);
    }

    function updateSkillPrerequisites(
        uint256 skillId,
        uint256[] calldata prerequisites
    ) external onlyRole(SKILL_DEFINER_ROLE) {
        if (!_skillDefinitions[skillId].exists) {
            revert SkillNotFound(skillId);
        }
        SkillDefinition storage skill = _skillDefinitions[skillId];
        skill.prerequisites = prerequisites;

        emit SkillPrerequisitesUpdated(skillId, prerequisites);
    }

    function updateSkillEffects(
        uint256 skillId,
        string[] calldata effects
    ) external onlyRole(SKILL_DEFINER_ROLE) {
        if (!_skillDefinitions[skillId].exists) {
            revert SkillNotFound(skillId);
        }
        SkillDefinition storage skill = _skillDefinitions[skillId];
        skill.effects = effects;

        emit SkillEffectsUpdated(skillId, effects);
    }

     // Admin can deactivate a skill definition so it cannot be granted anymore
    function deactivateSkillDefinition(uint256 skillId) external onlyRole(SKILL_DEFINER_ROLE) {
        if (!_skillDefinitions[skillId].exists) {
            revert SkillNotFound(skillId);
        }
        _skillDefinitions[skillId].isActive = false;
        // Note: Existing skill instances held by users remain, but new ones cannot be minted.
        // Effects from existing instances are still checked via hasSkill which uses _ownerHasActiveSkill
        // We could add logic here to also mark existing instances as inactive if needed, but let's keep it simple.
    }

    // Admin can reactivate a skill definition
    function activateSkillDefinition(uint256 skillId) external onlyRole(SKILL_DEFINER_ROLE) {
        if (!_skillDefinitions[skillId].exists) {
            revert SkillNotFound(skillId);
        }
         _skillDefinitions[skillId].isActive = true;
    }


    function grantSkill(address to, uint256 skillId) external onlyRole(SKILL_GRANTER_ROLE) {
        SkillDefinition storage skill = _skillDefinitions[skillId];

        if (!skill.exists || !skill.isActive) {
            revert SkillGrantFailed("Skill not found or not active");
        }
        if (_ownerHasActiveSkill[to][skillId]) {
             revert SkillGrantFailed("User already has this skill");
        }
        if (!_checkPrerequisites(to, skillId)) {
             revert SkillGrantFailed("Prerequisites not met");
        }

        _tokenIds.increment();
        uint256 newTokenId = _tokenIds.current();

        // Mint the ERC721 token
        _safeMint(to, newTokenId);

        // Link the token ID to the skill ID
        _skillIdByTokenId[newTokenId] = skillId;
        // Link owner+skill ID to the token ID (since a user gets one instance per skill)
        _tokenIdByOwnerAndSkill[to][skillId] = newTokenId;

        // Update owner's skill list and active status
        _ownerSkillIds[to].push(skillId);
        _ownerHasActiveSkill[to][skillId] = true;

        emit SkillGranted(to, skillId, newTokenId);

        // Emit AbilityUnlocked events for each effect granted by this skill
        for (uint i = 0; i < skill.effects.length; i++) {
             emit AbilityUnlocked(to, skill.effects[i]);
        }
    }

    // Revoking marks the skill instance as inactive for the user.
    // The token is NOT burned to preserve history, but `hasSkill` and `checkAbility` will reflect the revocation.
    function revokeSkill(address from, uint256 skillId) external onlyRole(SKILL_GRANTER_ROLE) {
        if (!_skillDefinitions[skillId].exists) {
            revert SkillNotFound(skillId);
        }
        if (!_ownerHasActiveSkill[from][skillId]) {
            revert SkillNotOwned(from, skillId);
        }

        // Mark the skill instance as inactive for the user
        _ownerHasActiveSkill[from][skillId] = false;

        // We need to remove the skillId from the _ownerSkillIds array
        // This is potentially gas-intensive if the array is large.
        // A more gas-efficient approach might involve a mapping `_ownerSkillIndexes[address][uint256 skillId] -> uint256 index`
        // to facilitate quick removal by swapping the last element with the one to be removed.
        // Let's implement the swap-and-pop method for better gas efficiency.
        uint256[] storage skills = _ownerSkillIds[from];
        uint256 len = skills.length;
        uint256 indexToRemove = len; // Use len as a sentinel value

        // Find the index of the skillId to remove
        for (uint i = 0; i < len; i++) {
            if (skills[i] == skillId) {
                indexToRemove = i;
                break;
            }
        }

        // If found, remove using swap-and-pop
        if (indexToRemove < len) {
            // If it's not the last element, swap it with the last one
            if (indexToRemove != len - 1) {
                skills[indexToRemove] = skills[len - 1];
            }
            // Remove the last element
            skills.pop();
        }
        // Note: If skillId wasn't found in the array but _ownerHasActiveSkill was true,
        // there's an inconsistency. The _ownerHasActiveSkill check should prevent this.


        // Find the tokenId for this owner and skill, and emit event
        uint256 revokedTokenId = _tokenIdByOwnerAndSkill[from][skillId];

        emit SkillRevoked(from, skillId, revokedTokenId);

        // Note: Effects from this skill are now considered inactive by checkAbility.
        // We don't need to emit "AbilityLost" events unless we track abilities globally.
        // checkAbility recalculates on the fly.
    }

    function updateBaseTokenURI(string calldata baseTokenURI_) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _baseTokenURI = baseTokenURI_;
    }

    // --- 10. User/Query Functions ---

    function isSkillActive(uint256 skillId) public view returns (bool) {
         return _skillDefinitions[skillId].exists && _skillDefinitions[skillId].isActive;
    }

    function hasSkill(address user, uint256 skillId) public view returns (bool) {
        // Check if the skill instance exists AND is marked as active for the user
        return _ownerHasActiveSkill[user][skillId];
    }

    function getSkillsOwnedBy(address user) public view returns (uint256[] memory) {
         // Return the list of skills marked as active for the user
         // The _ownerSkillIds array only contains skills currently marked active by grant/revoke
        return _ownerSkillIds[user];
    }


    function isEligibleToLearn(address user, uint256 skillId) public view returns (bool) {
        return _checkPrerequisites(user, skillId);
    }

    function getSkillDetails(uint256 skillId) public view returns (
        string memory name,
        string memory description,
        uint256[] memory prerequisites,
        string[] memory effects,
        bool exists,
        bool isActive
    ) {
        SkillDefinition storage skill = _skillDefinitions[skillId];
        if (!skill.exists) {
             revert SkillNotFound(skillId);
        }
        return (
            skill.name,
            skill.description,
            skill.prerequisites,
            skill.effects,
            skill.exists,
            skill.isActive
        );
    }

    function getSkillEffects(uint256 skillId) public view returns (string[] memory) {
        if (!_skillDefinitions[skillId].exists) {
             revert SkillNotFound(skillId);
        }
        return _skillDefinitions[skillId].effects;
    }

    // Checks if a user has any active skill that grants a specific ability string
    function checkAbility(address user, string calldata ability) public view returns (bool) {
        uint265[] memory userSkills = _ownerSkillIds[user]; // Get list of active skill IDs for user
        for (uint i = 0; i < userSkills.length; i++) {
            uint256 skillId = userSkills[i];
            // Double-check skill definition exists (should always for skills in _ownerSkillIds)
            // And check the effects of the active skill instance
            if (_skillDefinitions[skillId].exists && _ownerHasActiveSkill[user][skillId]) {
                 string[] memory effects = _skillDefinitions[skillId].effects;
                 for (uint j = 0; j < effects.length; j++) {
                     if (keccak256(abi.encodePacked(effects[j])) == keccak256(abi.encodePacked(ability))) {
                         return true; // Found a skill granting this ability
                     }
                 }
            }
        }
        return false; // Ability not found among active skills
    }

    function getAllSkillDefinitions() public view returns (uint256[] memory) {
        return _definedSkillIds;
    }

    function getTotalSkillDefinitions() public view returns (uint256) {
        return _definedSkillIds.length;
    }

    // --- 11. Internal Helper Functions ---

    // Internal check for skill prerequisites
    function _checkPrerequisites(address user, uint256 skillId) internal view returns (bool) {
        SkillDefinition storage skill = _skillDefinitions[skillId];
        // If skill doesn't exist or is not active, prerequisites check implicitly fails for granting
        // but this function is only called by grantSkill which already checks exists/isActive
        // However, it could be used elsewhere, so let's add the check.
        if (!skill.exists) {
            // Technically this shouldn't happen if called correctly, but for robustness:
            return false;
        }

        uint256[] memory prereqs = skill.prerequisites;
        for (uint i = 0; i < prereqs.length; i++) {
            uint256 prereqId = prereqs[i];
            // User must *actively* have the prerequisite skill
            if (!_ownerHasActiveSkill[user][prereqId]) {
                 // Revert here for clearer error during grant, otherwise return false
                 // Returning false allows external eligibility checks without reverting
                 // Let's return false, grantSkill will handle the revert.
                return false;
            }
        }
        return true; // All prerequisites met
    }


    // --- Standard ERC721 and AccessControl Functions (included in count) ---

    // ERC721Enumerable overrides use internal state managed by OpenZeppelin.
    // No need to redefine ownerOf, balanceOf, totalSupply, tokenByIndex, tokenOfOwnerByIndex
    // unless we had custom logic beyond the standard enumerable implementation,
    // which we don't need since our soulbound logic is in transfer/approve.

    // AccessControl functions are directly available:
    // grantRole(bytes32 role, address account)
    // revokeRole(bytes32 role, address account)
    // renounceRole(bytes32 role)
    // getRoleAdmin(bytes32 role)
    // hasRole(bytes32 role, address account)

    // ERC165 support (required for interfaces)
    function supportsInterface(bytes4 interfaceId) public view override(ERC721Enumerable, AccessControl) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}
```

---

**Explanation of Advanced/Creative Concepts:**

1.  **Soulbound Tokens (SBT):** The core concept. ERC721 tokens are made non-transferable by overriding `transferFrom`, `safeTransferFrom`, `approve`, and `setApprovalForAll` to `revert`. This signifies ownership is tied to the address and cannot be given away or sold, suitable for representing inherent traits, reputation, or earned skills.
2.  **Skill Tree Structure:** Skills have defined `prerequisites`. The `grantSkill` function enforces this on-chain logic, preventing users from gaining a skill without having completed the necessary prior skills (`isEligibleToLearn` / `_checkPrerequisites`).
3.  **On-Chain Abilities/Effects:** Skills can grant specific `effects` (represented as strings). The `checkAbility` function allows other systems (or even other contracts if this were integrated) to query if a user has a specific capability unlocked by their skills. This moves beyond just token ownership to on-chain verification of *what* the token represents the user *can do*.
4.  **Role-Based Access Control (RBAC):** Instead of a single owner, `AccessControl` is used to define granular permissions (`SKILL_DEFINER_ROLE`, `SKILL_GRANTER_ROLE`). This is more decentralized and flexible for managing a complex system.
5.  **Enumerable ERC721:** Inheriting `ERC721Enumerable` adds functionality to list all token IDs or all token IDs owned by a user, which is useful for exploring the skill tree data off-chain or building UIs.
6.  **Custom TokenURI Generation:** The `tokenURI` function is overridden to generate a data URI containing basic JSON metadata directly on-chain. This includes the skill's name and ID, allowing wallets and explorers to potentially display information about the specific skill token.
7.  **Soft Revocation:** The `revokeSkill` function doesn't destroy the token (`_burn` is not used). Instead, it marks the user's instance of the skill as inactive using the `_ownerHasActiveSkill` mapping and removes it from the `_ownerSkillIds` list. The token still exists in the user's wallet history (queryable via ERC721Enumerable), but its effects and the `hasSkill` check are disabled. This preserves a historical record while controlling current active status.
8.  **Complex State Management:** Multiple mappings and arrays (`_skillDefinitions`, `_definedSkillIds`, `_ownerSkillIds`, `_ownerHasActiveSkill`, `_skillIdByTokenId`, `_tokenIdByOwnerAndSkill`) are used together to manage the relationships between skill definitions, individual skill token instances, and the users who own them, tracking both definition properties and user-specific status.
9.  **Gas Efficiency Consideration (Revocation):** The `revokeSkill` includes an optimized approach (swap-and-pop) for removing elements from the `_ownerSkillIds` array to mitigate gas costs associated with array modifications in Solidity.
10. **Structured Events:** Comprehensive events are emitted for various actions, making it easy for off-chain applications to track changes and update user interfaces or databases in real-time.
11. **Custom Errors:** Using `error` types provides more context and saves gas compared to traditional `require` with string messages.
12. **Structured Data:** Using a `struct SkillDefinition` groups related data cleanly.

This contract goes beyond basic token functionality by encoding specific application logic (skill dependencies, abilities, active status) directly into the smart contract's state and functions, managed by a flexible access control system and built on the foundation of non-transferable ERC721 tokens.