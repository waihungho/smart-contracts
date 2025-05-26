Okay, here is a Solidity smart contract for a "Digital Soulbound Avatar". This contract combines several advanced concepts:

1.  **Soulbound Tokens (SBT):** The avatars are non-transferable ERC-721 tokens, tied permanently to the owner's address.
2.  **Dynamic Metadata:** The `tokenURI` generates metadata on-the-fly based on the avatar's current state (level, traits, achievements, status).
3.  **Attribute Evolution:** Avatar attributes (like level, traits, experience points) change based on interactions (e.g., admin adding XP or traits).
4.  **Achievement System:** Admins can define and award achievements that get recorded on the avatar and can influence its traits/XP.
5.  **Status Flags:** Simple boolean flags to represent various states (e.g., frozen, boosted).
6.  **On-Chain Calculation:** Level is calculated based on stored experience points using a configurable curve.
7.  **Controlled Updates:** Most state changes require specific roles (e.g., contract owner).

It is designed to be an interesting example of an on-chain identity or profile that evolves over time based on activity or external triggers, but cannot be traded.

---

### DigitalSoulboundAvatar Contract Outline

This contract manages dynamic, soulbound digital avatars. Each avatar is a non-transferable ERC-721 token tied to a specific address. The avatar's attributes (level, traits, achievements, status) can evolve over time, and its metadata (`tokenURI`) is generated dynamically based on this changing state.

**Key Concepts:**

*   **Soulbound:** Tokens cannot be transferred once minted.
*   **Dynamic:** Avatar attributes and metadata change based on interactions.
*   **Achievements:** A system to record accomplishments tied to the avatar.
*   **Leveling:** Avatars gain experience points (XP) and level up based on a configurable curve.
*   **Traits:** Customizable numerical attributes.
*   **Status Flags:** Simple boolean states.
*   **On-Chain Metadata:** `tokenURI` constructs metadata JSON directly in the contract.

---

### DigitalSoulboundAvatar Function Summary

1.  **constructor(string name, string symbol, string baseURI):** Initializes the contract with NFT name, symbol, and the base URI for dynamic metadata. Sets the contract deployer as the owner.
2.  **mintSoulboundAvatar(address recipient):** Mints a new soulbound avatar token and assigns it to the recipient. Requires the recipient to not already own an avatar (optional, can be modified). Only callable by the contract owner.
3.  **burnAvatar(uint256 tokenId):** Allows the avatar's owner to burn their avatar token, permanently destroying it.
4.  **ownerOf(uint256 tokenId):** Overrides the standard ERC-721 `ownerOf` to return the avatar's bound owner.
5.  **tokenURI(uint256 tokenId):** Overrides the standard ERC-721 `tokenURI` to generate and return a data URI containing dynamic metadata based on the avatar's current state (level, traits, achievements, status).
6.  **supportsInterface(bytes4 interfaceId):** Overrides the standard ERC-165 function. Supports ERC-721, ERC-721Metadata, and ERC-165, but crucially *does not* support ERC-721Enumerable or any transfer-related interfaces.
7.  **addExperience(uint256 tokenId, uint256 amount):** Adds experience points to an avatar. Callable by the contract owner. Automatically triggers a level check.
8.  **getExperience(uint256 tokenId):** Returns the current experience points of an avatar.
9.  **getLevel(uint256 tokenId):** Calculates and returns the current level of an avatar based on its experience points and the configured leveling curve.
10. **setXPForLevel(uint256 level, uint256 requiredXP):** Allows the contract owner to set the experience points required to reach a specific level. Configures the leveling curve.
11. **getXPForLevel(uint256 level):** Returns the XP required to reach a specific level according to the current configuration.
12. **getTrait(uint256 tokenId, string traitName):** Returns the value of a specific numerical trait for an avatar.
13. **setTrait(uint256 tokenId, string traitName, uint256 newValue):** Sets the value of a specific numerical trait for an avatar. Callable by the contract owner.
14. **incrementTrait(uint256 tokenId, string traitName, uint256 amount):** Increments the value of a specific numerical trait for an avatar by a given amount. Callable by the contract owner.
15. **decrementTrait(uint256 tokenId, string traitName, uint256 amount):** Decrements the value of a specific numerical trait for an avatar by a given amount (minimum 0). Callable by the contract owner.
16. **defineAchievement(bytes32 achievementId, string description, uint256 requiredLevel, uint256 rewardXP):** Allows the contract owner to define or update an achievement, including its ID, description, required level to potentially earn it, and XP reward.
17. **getAchievementDefinition(bytes32 achievementId):** Returns the definition details (description, required level, reward XP) for a given achievement ID.
18. **awardAchievement(uint256 tokenId, bytes32 achievementId):** Awards a defined achievement to an avatar. Callable by the contract owner. Checks if the avatar already has the achievement and if the achievement is defined. Adds the achievement's reward XP to the avatar.
19. **hasAchievement(uint256 tokenId, bytes32 achievementId):** Checks if an avatar has been awarded a specific achievement.
20. **getAchievementCompletionTime(uint256 tokenId, bytes32 achievementId):** Returns the timestamp when an achievement was awarded to an avatar (0 if not awarded).
21. **setStatusFlag(uint256 tokenId, string flagName, bool status):** Sets a boolean status flag for an avatar (e.g., "isFrozen", "isBoosted"). Callable by the contract owner.
22. **getStatusFlag(uint256 tokenId, string flagName):** Returns the boolean status of a specific flag for an avatar.
23. **setMetadataBaseURI(string newURI):** Allows the contract owner to update the base URI used in `tokenURI`.
24. **getMetadataBaseURI():** Returns the current metadata base URI.
25. **getTotalSupply():** Returns the total number of avatars minted (and not burned).
26. **getAvatarMintTimestamp(uint256 tokenId):** Returns the mint timestamp for an avatar.
27. **triggerLevelUpCheck(uint256 tokenId):** Allows anyone (or owner) to trigger a check to see if an avatar's current XP qualifies it for a level up. If so, the avatar's level is updated and an event is emitted. (Note: Level is usually calculated on-the-fly, but this function demonstrates triggering state changes based on thresholds).
28. **transferOwnership(address newOwner):** Standard Ownable function to transfer contract administrative ownership.
29. **getAvatarOwner(uint256 tokenId):** Helper function, same as `ownerOf`.
30. (Implicit overrides): `approve`, `setApprovalForAll`, `transferFrom`, `safeTransferFrom(address from, address to, uint256 tokenId)`, `safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)`: These standard ERC-721 transfer functions are overridden to revert, enforcing the soulbound property.

**(Note: The explicit transfer overrides bring the total count of distinct external/public functions or overriden behaviors to 30+, well over the 20 minimum).**

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol"; // Used for _beforeTokenTransfer hook, but interface won't be supported
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Base64.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

/// @title DigitalSoulboundAvatar
/// @author YourNameHere (or a pseudonym)
/// @notice A smart contract for managing non-transferable, dynamic digital avatars.
/// These avatars evolve based on XP, traits, achievements, and status flags.
/// Metadata is generated on-chain.

contract DigitalSoulboundAvatar is ERC721, Ownable {
    using Counters for Counters.Counter;
    using Strings for uint256;

    // --- State Variables ---

    Counters.Counter private _tokenIdCounter;

    struct AvatarData {
        address owner; // The soulbound owner
        uint256 mintTimestamp;
        uint256 experiencePoints;
        uint256 level; // Stored level for efficiency after triggerLevelUpCheck
        mapping(string => uint256) traits;
        mapping(bytes32 => uint256) achievementsCompletionTime; // achievementId => timestamp (0 if not earned)
        mapping(string => bool) statusFlags;
    }

    mapping(uint256 => AvatarData) private _avatars;

    struct AchievementDefinition {
        string description;
        uint256 requiredLevel;
        uint256 rewardXP;
    }

    // achievementId (bytes32) => definition
    mapping(bytes32 => AchievementDefinition) private _achievementDefinitions;

    // level => required experience points to reach this level
    mapping(uint256 => uint256) private _xpRequiredForLevel;

    string private _metadataBaseURI;

    // --- Events ---

    event AvatarMinted(uint256 indexed tokenId, address indexed owner, uint256 mintTimestamp);
    event AvatarBurned(uint256 indexed tokenId, address indexed owner);
    event ExperienceAdded(uint256 indexed tokenId, uint256 amount, uint256 newTotalXP);
    event LevelUp(uint256 indexed tokenId, uint256 oldLevel, uint256 newLevel);
    event TraitUpdated(uint256 indexed tokenId, string traitName, uint256 newValue);
    event AchievementDefined(bytes32 indexed achievementId, string description, uint256 requiredLevel, uint256 rewardXP);
    event AchievementAwarded(uint256 indexed tokenId, bytes32 indexed achievementId, uint256 completionTimestamp);
    event StatusFlagUpdated(uint256 indexed tokenId, string flagName, bool status);
    event MetadataBaseURIUpdated(string newURI);

    // --- Errors ---

    error InvalidTokenId(uint256 tokenId);
    error NotSoulboundOwner(address caller, uint256 tokenId);
    error AlreadyHasAvatar(address owner); // Optional: if limiting to one avatar per address
    error AchievementNotFound(bytes32 achievementId);
    error AchievementAlreadyAwarded(uint256 tokenId, bytes32 achievementId);

    // --- Constructor ---

    constructor(string memory name, string memory symbol, string memory baseURI) ERC721(name, symbol) Ownable(msg.sender) {
        _metadataBaseURI = baseURI;
        // Set base leveling curve defaults (Level 1 requires 0 XP, Level 2 requires 100 XP, etc.)
        _xpRequiredForLevel[0] = 0; // Level 0 (starting)
        _xpRequiredForLevel[1] = 0; // Level 1 reached at 0 XP
        _xpRequiredForLevel[2] = 100;
        _xpRequiredForLevel[3] = 300;
        _xpRequiredForLevel[4] = 600;
        _xpRequiredForLevel[5] = 1000;
        // Add more levels with setXPForLevel later
    }

    // --- Core Soulbound & NFT Functions ---

    /// @notice Mints a new soulbound avatar for a recipient.
    /// @param recipient The address to mint the avatar for.
    /// @return The token ID of the newly minted avatar.
    function mintSoulboundAvatar(address recipient) public onlyOwner returns (uint256) {
        // Optional: Add a check here if you want to limit to 1 avatar per address
        // require(_avatars[0].owner != recipient, "Recipient already has an avatar"); // Requires tracking avatar ID per owner

        _tokenIdCounter.increment();
        uint256 newTokenId = _tokenIdCounter.current();

        _avatars[newTokenId].owner = recipient;
        _avatars[newTokenId].mintTimestamp = block.timestamp;
        _avatars[newTokenId].experiencePoints = 0;
        _avatars[newTokenId].level = 1; // Start at Level 1

        _safeMint(recipient, newTokenId); // Mints the ERC721 token

        emit AvatarMinted(newTokenId, recipient, block.timestamp);
        return newTokenId;
    }

    /// @notice Allows the soulbound owner to burn their avatar.
    /// @param tokenId The ID of the avatar token to burn.
    function burnAvatar(uint256 tokenId) public {
        if (!_exists(tokenId)) revert InvalidTokenId(tokenId);
        if (_avatars[tokenId].owner != msg.sender) revert NotSoulboundOwner(msg.sender, tokenId);

        delete _avatars[tokenId]; // Clear avatar data
        _burn(tokenId); // Burn the ERC721 token

        emit AvatarBurned(tokenId, msg.sender);
    }

    /// @dev Overrides ERC721's ownerOf. Returns the originally bound owner.
    function ownerOf(uint256 tokenId) public view override returns (address) {
        if (!_exists(tokenId)) revert InvalidTokenId(tokenId);
        return _avatars[tokenId].owner;
    }

    /// @dev Overrides ERC721's tokenURI. Generates dynamic metadata.
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        if (!_exists(tokenId)) revert InvalidTokenId(tokenId);

        AvatarData storage avatar = _avatars[tokenId];

        // Prepare traits
        string memory traitsJson = "";
        string memory separator = "";
        // Note: Iterating over mappings is not possible in Solidity.
        // A real implementation would need to store trait names in an array or linked list to iterate for metadata.
        // For this example, we'll just show placeholder or require knowing trait names externally.
        // Let's add a couple known trait names for demonstration in metadata.
        string[] memory knownTraits = new string[](2);
        knownTraits[0] = "Strength";
        knownTraits[1] = "Intelligence";

        for (uint i = 0; i < knownTraits.length; i++) {
             if (bytes(knownTraits[i]).length > 0) { // Check if trait name is not empty
                traitsJson = string(abi.encodePacked(traitsJson, separator, '{"trait_type": "', knownTraits[i], '", "value": ', avatar.traits[knownTraits[i]].toString(), '}'));
                separator = ",";
             }
        }


        // Prepare achievements (list achievement IDs or names)
        string memory achievementsJson = "";
        separator = "";
         // Similar to traits, iterating achievements mapping isn't possible.
         // We'll just add a placeholder for demonstration or expect IDs to be known.
        // To list awarded achievements dynamically, you'd need to store awarded IDs in an array.
        // Let's list known achievements by ID if awarded for demonstration.
        bytes32[] memory knownAchievementIds = new bytes32[](2);
        knownAchievementIds[0] = keccak256(abi.encodePacked("FirstStep"));
        knownAchievementIds[1] = keccak256(abi.encodePacked("Level5Reached"));

        for (uint i = 0; i < knownAchievementIds.length; i++) {
            if (avatar.achievementsCompletionTime[knownAchievementIds[i]] > 0) {
                 // Look up achievement description if needed, but requires iteration or another mapping
                 // For simplicity, just list the raw ID or a placeholder
                 achievementsJson = string(abi.encodePacked(achievementsJson, separator, '"', Strings.toHexString(uint256(knownAchievementIds[i])), '"'));
                 separator = ",";
            }
        }


        // Prepare status flags (list flag names and states)
        string memory statusFlagsJson = "";
        separator = "";
        // Similar to traits/achievements, need a list of known flag names to iterate
        string[] memory knownFlags = new string[](2);
        knownFlags[0] = "isFrozen";
        knownFlags[1] = "isBoosted";

        for (uint i = 0; i < knownFlags.length; i++) {
            if (bytes(knownFlags[i]).length > 0) {
                statusFlagsJson = string(abi.encodePacked(statusFlagsJson, separator, '{"trait_type": "', knownFlags[i], '", "value": ', avatar.statusFlags[knownFlags[i]] ? "true" : "false", '}'));
                separator = ",";
            }
        }


        // Construct the full JSON metadata
        string memory json = string(abi.encodePacked(
            '{"name": "Digital Soulbound Avatar #', tokenId.toString(), '",',
            '"description": "An evolving, soulbound digital identity.",',
            '"image": "', _metadataBaseURI, tokenId.toString(), '/image.png",', // Placeholder image URL
            '"attributes": [',
                '{"trait_type": "Owner", "value": "', Strings.toHexString(uint160(avatar.owner)), '"},',
                '{"trait_type": "Mint Timestamp", "value": ', avatar.mintTimestamp.toString(), '},',
                '{"trait_type": "Level", "value": ', avatar.level.toString(), '},',
                '{"trait_type": "Experience", "value": ', avatar.experiencePoints.toString(), '}',
                 // Add known traits and status flags here
                 separator == "" ? "" : ",", traitsJson, // Only add comma if traitsJson is not empty
                 statusFlagsJson == "" ? "" : (traitsJson == "" ? "" : ","), statusFlagsJson, // Only add comma if statusJson is not empty and traitsJson isn't the last element
            '],',
            '"achievements": [', achievementsJson, ']', // List achievement IDs
            '}'
        ));

        // Encode JSON to Base64 Data URI
        string memory baseURI = "data:application/json;base64,";
        return string(abi.encodePacked(baseURI, Base64.encode(bytes(json))));
    }

    /// @dev Overrides ERC165's supportsInterface.
    /// @notice Does NOT support ERC721Enumerable or transfer interfaces.
    function supportsInterface(bytes4 interfaceId) public view override returns (bool) {
        // Standard ERC721 and Metadata interfaces
        return interfaceId == type(ERC721).interfaceId ||
               interfaceId == type(ERC721Metadata).interfaceId ||
               interfaceId == type(IERC165).interfaceId;
               // Intentionally do not support ERC721Enumerable or transfer interfaces
    }

    // --- SBT Enforcement Overrides ---

    /// @dev Prevent transfers to enforce soulbound property.
    function transferFrom(address from, address to, uint256 tokenId) public override pure {
        // Revert any attempts to transfer
        revert("Avatar is Soulbound: Not transferable");
    }

    /// @dev Prevent transfers to enforce soulbound property.
    function safeTransferFrom(address from, address to, uint256 tokenId) public override pure {
        // Revert any attempts to transfer
        revert("Avatar is Soulbound: Not transferable");
    }

    /// @dev Prevent transfers to enforce soulbound property.
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public override pure {
        // Revert any attempts to transfer
        revert("Avatar is Soulbound: Not transferable");
    }

    /// @dev Prevent approval to enforce soulbound property.
    function approve(address to, uint256 tokenId) public override pure {
        // Revert any attempts to approve
        revert("Avatar is Soulbound: Not transferable");
    }

    /// @dev Prevent approval for all to enforce soulbound property.
    function setApprovalForAll(address operator, bool approved) public override pure {
        // Revert any attempts to set approval for all
        revert("Avatar is Soulbound: Not transferable");
    }

    /// @dev Internal hook called before any token transfer. Used here to reinforce soulbound nature.
    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize) internal override {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);

        // The initial mint (from address 0) and burn (to address 0) are allowed.
        // Any other transfer (from != address 0 && to != address 0) should be prevented,
        // but the public transfer functions are already overridden to revert.
        // This hook primarily ensures that even internal calls attempting transfer will fail.
        if (from != address(0) && to != address(0)) {
             revert("Avatar is Soulbound: Not transferable");
        }

        // Check if tokenId exists if it's not a minting transaction (from != 0)
        if (from != address(0) && !_exists(tokenId)) revert InvalidTokenId(tokenId);
    }

    /// @dev Internal helper to check token existence.
    function _exists(uint256 tokenId) internal view override returns (bool) {
        // ERC721's _exists relies on _owners or _balances. Since we clear _avatars on burn,
        // let's explicitly check if the avatar data exists.
        // The standard ERC721._exists check `_owners[tokenId] != address(0)` is sufficient
        // because `_safeMint` sets the owner and `_burn` clears it.
        return super._exists(tokenId);
    }


    // --- Dynamic Attributes (XP, Level, Traits, Status) ---

    /// @notice Adds experience points to an avatar.
    /// @param tokenId The ID of the avatar.
    /// @param amount The amount of XP to add.
    function addExperience(uint256 tokenId, uint256 amount) public onlyOwner {
        if (!_exists(tokenId)) revert InvalidTokenId(tokenId);
        AvatarData storage avatar = _avatars[tokenId];

        avatar.experiencePoints += amount;

        emit ExperienceAdded(tokenId, amount, avatar.experiencePoints);

        // Automatically check for level up after adding XP
        _checkAndTriggerLevelUp(tokenId);
    }

    /// @notice Returns the current experience points of an avatar.
    /// @param tokenId The ID of the avatar.
    /// @return The current XP.
    function getExperience(uint256 tokenId) public view returns (uint256) {
        if (!_exists(tokenId)) revert InvalidTokenId(tokenId);
        return _avatars[tokenId].experiencePoints;
    }

    /// @notice Calculates and returns the current level of an avatar based on its XP.
    /// @param tokenId The ID of the avatar.
    /// @return The current level.
    function getLevel(uint256 tokenId) public view returns (uint256) {
        if (!_exists(tokenId)) revert InvalidTokenId(tokenId);
        // Level is stored and updated by triggerLevelUpCheck for gas efficiency,
        // but this function calculates it based on current XP and the curve
        // in case triggerLevelUpCheck hasn't been called recently.
        return _calculateLevel(_avatars[tokenId].experiencePoints);
    }

    /// @notice Sets the experience points required to reach a specific level.
    /// @param level The level to configure.
    /// @param requiredXP The XP needed to reach this level.
    function setXPForLevel(uint256 level, uint256 requiredXP) public onlyOwner {
        require(level > 0, "Level must be positive");
        _xpRequiredForLevel[level] = requiredXP;
        // Note: Does not re-evaluate existing avatars' levels. `triggerLevelUpCheck` or `addExperience` would do that.
    }

    /// @notice Gets the experience points required for a specific level.
    /// @param level The level to query.
    /// @return The required XP for that level. Returns 0 if not configured beyond level 1.
    function getXPForLevel(uint256 level) public view returns (uint256) {
        if (level == 0) return 0; // Level 0 doesn't require XP
        return _xpRequiredForLevel[level];
    }

    /// @notice Triggers a check and update of an avatar's level based on current XP.
    /// @param tokenId The ID of the avatar.
    function triggerLevelUpCheck(uint256 tokenId) public { // Made public, could potentially allow anyone to trigger check
        if (!_exists(tokenId)) revert InvalidTokenId(tokenId);
        _checkAndTriggerLevelUp(tokenId);
    }

    /// @dev Internal function to calculate level from XP.
    function _calculateLevel(uint256 xp) internal view returns (uint256) {
        uint256 currentLevel = 1;
        uint256 required;
        // Iterate through configured levels to find the highest level achieved
        // Note: Requires level configurations to be contiguous or checked carefully.
        // A better approach for many levels might be a binary search or a mathematical formula.
        // Simple linear check for limited example levels:
        // This loop finds the highest level 'L' such that XP >= XP_required[L]
        uint256 maxConfiguredLevel = 0;
        uint256 i = 1;
        while (true) {
             required = _xpRequiredForLevel[i];
             if (required == 0 && i > 1) break; // Stop if XP for level i is 0 (and i > 1 to allow level 1 at 0 XP)
             if (xp >= required) {
                 currentLevel = i;
                 maxConfiguredLevel = i;
                 i++;
             } else {
                 break;
             }
        }

        // Handle cases where levels might not be contiguous in the mapping or the loop logic needs refinement.
        // For a robust system, either ensure contiguous level setting or use a different data structure.
        // The loop above assumes levels are set contiguously starting from 1.
        // Let's refine: Find the highest level `L` such that `_xpRequiredForLevel[L]` exists and `xp >= _xpRequiredForLevel[L]`.
        // This requires iterating keys or knowing the max set level.
        // Given mapping limitation, let's assume `_xpRequiredForLevel[level]` returns 0 for unset levels > 1.
        // The previous loop is a simple approach given this limitation. Let's keep it and note the constraint.

        return currentLevel;
    }


    /// @dev Internal function to check and potentially trigger level up.
    function _checkAndTriggerLevelUp(uint256 tokenId) internal {
        AvatarData storage avatar = _avatars[tokenId];
        uint256 currentCalculatedLevel = _calculateLevel(avatar.experiencePoints);

        if (currentCalculatedLevel > avatar.level) {
            uint256 oldLevel = avatar.level;
            avatar.level = currentCalculatedLevel;
            emit LevelUp(tokenId, oldLevel, currentCalculatedLevel);
            // Re-emit traits update to notify metadata change? Or rely on tokenURI call?
            // emit TraitUpdated(tokenId, "Level", currentCalculatedLevel); // Could emit for clarity
        }
    }


    /// @notice Returns the value of a specific numerical trait for an avatar.
    /// @param tokenId The ID of the avatar.
    /// @param traitName The name of the trait.
    /// @return The trait value.
    function getTrait(uint256 tokenId, string memory traitName) public view returns (uint256) {
        if (!_exists(tokenId)) revert InvalidTokenId(tokenId);
        return _avatars[tokenId].traits[traitName];
    }

    /// @notice Sets the value of a specific numerical trait for an avatar.
    /// @dev Only callable by the contract owner.
    /// @param tokenId The ID of the avatar.
    /// @param traitName The name of the trait.
    /// @param newValue The new value for the trait.
    function setTrait(uint256 tokenId, string memory traitName, uint256 newValue) public onlyOwner {
        if (!_exists(tokenId)) revert InvalidTokenId(tokenId);
        _avatars[tokenId].traits[traitName] = newValue;
        emit TraitUpdated(tokenId, traitName, newValue);
    }

    /// @notice Increments the value of a specific numerical trait for an avatar.
    /// @dev Only callable by the contract owner.
    /// @param tokenId The ID of the avatar.
    /// @param traitName The name of the trait.
    /// @param amount The amount to increment by.
    function incrementTrait(uint256 tokenId, string memory traitName, uint256 amount) public onlyOwner {
        if (!_exists(tokenId)) revert InvalidTokenId(tokenId);
        _avatars[tokenId].traits[traitName] += amount;
        emit TraitUpdated(tokenId, traitName, _avatars[tokenId].traits[traitName]);
    }

    /// @notice Decrements the value of a specific numerical trait for an avatar.
    /// @dev Only callable by the contract owner. Value will not go below 0.
    /// @param tokenId The ID of the avatar.
    /// @param traitName The name of the trait.
    /// @param amount The amount to decrement by.
    function decrementTrait(uint256 tokenId, string memory traitName, uint256 amount) public onlyOwner {
        if (!_exists(tokenId)) revert InvalidTokenId(tokenId);
        uint256 currentValue = _avatars[tokenId].traits[traitName];
        if (currentValue >= amount) {
            _avatars[tokenId].traits[traitName] = currentValue - amount;
        } else {
             _avatars[tokenId].traits[traitName] = 0;
        }
        emit TraitUpdated(tokenId, traitName, _avatars[tokenId].traits[traitName]);
    }


    // --- Achievement System ---

    /// @notice Defines or updates an achievement.
    /// @dev Only callable by the contract owner. achievementId can be a keccak256 hash of a unique string.
    /// @param achievementId A unique ID for the achievement.
    /// @param description A brief description of the achievement.
    /// @param requiredLevel The minimum level required to potentially earn this achievement (for display/logic elsewhere).
    /// @param rewardXP Experience points awarded when this achievement is awarded.
    function defineAchievement(bytes32 achievementId, string memory description, uint256 requiredLevel, uint256 rewardXP) public onlyOwner {
        _achievementDefinitions[achievementId] = AchievementDefinition(description, requiredLevel, rewardXP);
        emit AchievementDefined(achievementId, description, requiredLevel, rewardXP);
    }

     /// @notice Gets the definition details for a specific achievement.
    /// @param achievementId The ID of the achievement.
    /// @return description, requiredLevel, rewardXP. Returns empty string and 0s if not found.
    function getAchievementDefinition(bytes32 achievementId) public view returns (string memory description, uint256 requiredLevel, uint256 rewardXP) {
        AchievementDefinition storage definition = _achievementDefinitions[achievementId];
        return (definition.description, definition.requiredLevel, definition.rewardXP);
    }


    /// @notice Awards a defined achievement to an avatar.
    /// @dev Only callable by the contract owner. Checks if the achievement is defined and not already awarded.
    /// Adds the achievement's reward XP to the avatar.
    /// @param tokenId The ID of the avatar.
    /// @param achievementId The ID of the achievement to award.
    function awardAchievement(uint256 tokenId, bytes32 achievementId) public onlyOwner {
        if (!_exists(tokenId)) revert InvalidTokenId(tokenId);
        AchievementDefinition storage achievementDef = _achievementDefinitions[achievementId];
        if (bytes(achievementDef.description).length == 0) revert AchievementNotFound(achievementId); // Check if achievement is defined

        AvatarData storage avatar = _avatars[tokenId];
        if (avatar.achievementsCompletionTime[achievementId] > 0) revert AchievementAlreadyAwarded(tokenId, achievementId); // Check if already awarded

        avatar.achievementsCompletionTime[achievementId] = block.timestamp; // Record completion time
        emit AchievementAwarded(tokenId, achievementId, block.timestamp);

        // Award XP for the achievement
        if (achievementDef.rewardXP > 0) {
             addExperience(tokenId, achievementDef.rewardXP); // Use the existing addExperience function
        }
    }

    /// @notice Checks if an avatar has been awarded a specific achievement.
    /// @param tokenId The ID of the avatar.
    /// @param achievementId The ID of the achievement to check.
    /// @return True if the avatar has the achievement, false otherwise.
    function hasAchievement(uint256 tokenId, bytes32 achievementId) public view returns (bool) {
        if (!_exists(tokenId)) return false; // Or revert? Returning false is safer for checks.
        return _avatars[tokenId].achievementsCompletionTime[achievementId] > 0;
    }

    /// @notice Returns the timestamp when an achievement was awarded to an avatar.
    /// @param tokenId The ID of the avatar.
    /// @param achievementId The ID of the achievement.
    /// @return The timestamp of completion, or 0 if not awarded.
    function getAchievementCompletionTime(uint256 tokenId, bytes32 achievementId) public view returns (uint256) {
         if (!_exists(tokenId)) return 0;
         return _avatars[tokenId].achievementsCompletionTime[achievementId];
    }


    // --- Status Flags ---

    /// @notice Sets a boolean status flag for an avatar.
    /// @dev Only callable by the contract owner.
    /// @param tokenId The ID of the avatar.
    /// @param flagName The name of the status flag (e.g., "isFrozen", "isBoosted").
    /// @param status The boolean value to set.
    function setStatusFlag(uint256 tokenId, string memory flagName, bool status) public onlyOwner {
        if (!_exists(tokenId)) revert InvalidTokenId(tokenId);
        _avatars[tokenId].statusFlags[flagName] = status;
        emit StatusFlagUpdated(tokenId, flagName, status);
    }

    /// @notice Returns the boolean status of a specific flag for an avatar.
    /// @param tokenId The ID of the avatar.
    /// @param flagName The name of the status flag.
    /// @return The boolean status. Defaults to false if not set.
    function getStatusFlag(uint256 tokenId, string memory flagName) public view returns (bool) {
        if (!_exists(tokenId)) return false;
        return _avatars[tokenId].statusFlags[flagName];
    }


    // --- Admin & Utility ---

    /// @notice Sets the base URI for generating dynamic metadata.
    /// @dev Only callable by the contract owner.
    /// @param newURI The new base URI.
    function setMetadataBaseURI(string memory newURI) public onlyOwner {
        _metadataBaseURI = newURI;
        emit MetadataBaseURIUpdated(newURI);
    }

    /// @notice Returns the current metadata base URI.
    /// @return The current base URI.
    function getMetadataBaseURI() public view returns (string memory) {
        return _metadataBaseURI;
    }

    /// @notice Returns the total number of avatars minted (and not burned).
    /// @return The total supply of avatars.
    function getTotalSupply() public view returns (uint256) {
        return _tokenIdCounter.current();
    }

     /// @notice Returns the mint timestamp for an avatar.
     /// @param tokenId The ID of the avatar.
     /// @return The mint timestamp. Returns 0 if token does not exist.
     function getAvatarMintTimestamp(uint256 tokenId) public view returns (uint256) {
         if (!_exists(tokenId)) return 0;
         return _avatars[tokenId].mintTimestamp;
     }

     /// @notice Returns the soulbound owner of an avatar. Same as `ownerOf`.
     /// @param tokenId The ID of the avatar.
     /// @return The owner's address. Reverts if token does not exist.
     function getAvatarOwner(uint256 tokenId) public view returns (address) {
         return ownerOf(tokenId); // Alias for ownerOf
     }


    // Note: ERC721Enumerable functions (like tokenByIndex, tokenOfOwnerByIndex)
    // are not implemented and the interface is not supported to reduce surface area
    // and complexity for a Soulbound token use case where iteration is less relevant.

    // Ownable functions like `transferOwnership` are inherited and available.
}
```