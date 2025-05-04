Okay, here is a Solidity smart contract concept for an "Adaptive Asset System". This system involves Non-Fungible Tokens (NFTs) that can evolve over time and gain dynamic traits or skills based on their interactions or state within the contract, such as being staked.

This concept aims to be advanced by:
1.  **Dynamic State:** NFTs whose properties (traits/skills) can change *after* minting, based on on-chain logic.
2.  **Staking Integration:** Staking not just for yield, but as a trigger/catalyst for evolution.
3.  **On-chain Trait/Skill Management:** Defining and assigning traits/skills directly within the contract state.
4.  **Adaptation Logic:** A system that checks conditions and applies changes.
5.  **Modular Traits/Skills:** Ability for the owner to define different types of traits and skills.

It avoids duplicating standard ERC-20/ERC-721 (beyond the base interface), basic staking for yield only, or simple mint/transfer contracts. The complexity comes from managing the *dynamic state* and the *adaptation triggers*.

---

**Outline and Function Summary:**

**Contract Name:** `AdaptiveAssetSystem`

**Core Concept:** An ERC721 token where each token represents an Asset that can evolve over time and based on its state (e.g., staked). Assets gain traits (permanent properties) and skills (temporary or conditional abilities).

**Key Features:**
*   ERC721 Compliance (Minting, Transfer, Ownership).
*   Dynamic Asset State (Traits, Skills, Last Adaptation Time, Staking Status).
*   Adaptation Trigger (`triggerAdaptationCheck`) callable by the token owner to check for and apply evolutionary changes.
*   Staking mechanism where staking duration influences adaptation.
*   Owner-managed configuration for defining Traits, Skills, and Adaptation Rules.
*   Metadata updates reflective of the asset's current state.

**Function Categories:**

1.  **ERC721 Standard Functions (11 functions):**
    *   `balanceOf(address owner)`: Get the number of tokens owned by an address.
    *   `ownerOf(uint256 tokenId)`: Get the owner of a specific token.
    *   `safeTransferFrom(address from, address to, uint256 tokenId)`: Safely transfer a token.
    *   `safeTransferFrom(address from, address to, uint256 tokenId, bytes data)`: Safely transfer with data.
    *   `transferFrom(address from, address to, uint256 tokenId)`: Transfer a token (less safe).
    *   `approve(address to, uint256 tokenId)`: Approve an address to manage a token.
    *   `getApproved(uint256 tokenId)`: Get the approved address for a token.
    *   `setApprovalForAll(address operator, bool approved)`: Set approval for an operator for all tokens.
    *   `isApprovedForAll(address owner, address operator)`: Check if an operator is approved for all tokens.
    *   `supportsInterface(bytes4 interfaceId)`: Check if the contract supports an interface (ERC165).
    *   `tokenURI(uint256 tokenId)`: Get the metadata URI for a token.

2.  **Core Asset & Adaptation Functions (5 functions):**
    *   `mint(address to)`: Mint a new Asset token to an address.
    *   `getAssetDetails(uint256 tokenId)`: View detailed state of an Asset (traits, skills, etc.).
    *   `getAssetTraits(uint256 tokenId)`: View the list of traits an Asset possesses.
    *   `getAssetSkills(uint256 tokenId)`: View the list of skills an Asset possesses.
    *   `triggerAdaptationCheck(uint256 tokenId)`: Callable by owner/approved to trigger an adaptation check and apply changes based on rules and state (time, staking, etc.).

3.  **Staking Functions (4 functions):**
    *   `stakeAsset(uint256 tokenId)`: Stake an Asset token (must be owner).
    *   `unstakeAsset(uint256 tokenId)`: Unstake an Asset token.
    *   `getStakedAssets(address owner)`: View the list of tokens an owner has staked.
    *   `isAssetStaked(uint256 tokenId)`: Check if a specific Asset token is staked.

4.  **Admin/Configuration Functions (9 functions):**
    *   `createTraitType(uint256 traitId, string calldata name, string calldata description, uint256 rarity)`: Define a new type of Trait (owner only).
    *   `updateTraitType(uint256 traitId, string calldata name, string calldata description, uint256 rarity)`: Update details of an existing Trait type (owner only).
    *   `createSkillType(uint256 skillId, string calldata name, string calldata description, uint256 duration)`: Define a new type of Skill (owner only).
    *   `updateSkillType(uint256 skillId, string calldata name, string calldata description, uint256 duration)`: Update details of an existing Skill type (owner only).
    *   `setBaseURI(string calldata baseURI_)`: Set the base URI for token metadata (owner only).
    *   `setAdaptationCooldown(uint256 cooldownSeconds)`: Set the minimum time between adaptation checks per asset (owner only).
    *   `setAdaptationRule(uint256 ruleId, bytes calldata ruleData)`: Define a new complex adaptation rule (e.g., stake duration yields specific trait/skill, owner only). *This is simplified in the code; complex rules might need more sophisticated data structures or helper contracts.*
    *   `grantTrait(uint256 tokenId, uint256 traitId)`: Force-add a trait to an asset (owner only, e.g., for events).
    *   `grantSkill(uint256 tokenId, uint256 skillId)`: Force-add a skill to an asset (owner only).

5.  **Helper/View Functions (3 functions):**
    *   `getTotalSupply()`: Get the total number of tokens minted.
    *   `getTraitDetails(uint256 traitId)`: View details of a specific Trait type.
    *   `getSkillDetails(uint256 skillId)`: View details of a specific Skill type.

**Total Functions:** 11 + 5 + 4 + 9 + 3 = **32 functions**.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol"; // For tokenURI interface

// --- Outline and Function Summary ---
// Contract Name: AdaptiveAssetSystem
// Core Concept: An ERC721 token where each token represents an Asset that can evolve over time and based on its state (e.g., staked). Assets gain traits (permanent properties) and skills (temporary or conditional abilities).
// Key Features:
// * ERC721 Compliance (Minting, Transfer, Ownership).
// * Dynamic Asset State (Traits, Skills, Last Adaptation Time, Staking Status).
// * Adaptation Trigger (`triggerAdaptationCheck`) callable by the token owner to check for and apply evolutionary changes.
// * Staking mechanism where staking duration influences adaptation.
// * Owner-managed configuration for defining Traits, Skills, and Adaptation Rules.
// * Metadata updates reflective of the asset's current state.

// Function Categories:

// 1. ERC721 Standard Functions (11 functions):
//    - balanceOf(address owner)
//    - ownerOf(uint256 tokenId)
//    - safeTransferFrom(address from, address to, uint256 tokenId)
//    - safeTransferFrom(address from, address to, uint256 tokenId, bytes data)
//    - transferFrom(address from, address to, uint256 tokenId)
//    - approve(address to, uint256 tokenId)
//    - getApproved(uint256 tokenId)
//    - setApprovalForAll(address operator, bool approved)
//    - isApprovedForAll(address owner, address operator)
//    - supportsInterface(bytes4 interfaceId) (Inherited/Overridden)
//    - tokenURI(uint256 tokenId)

// 2. Core Asset & Adaptation Functions (5 functions):
//    - mint(address to)
//    - getAssetDetails(uint256 tokenId)
//    - getAssetTraits(uint256 tokenId)
//    - getAssetSkills(uint256 tokenId)
//    - triggerAdaptationCheck(uint256 tokenId)

// 3. Staking Functions (4 functions):
//    - stakeAsset(uint256 tokenId)
//    - unstakeAsset(uint256 tokenId)
//    - getStakedAssets(address owner)
//    - isAssetStaked(uint256 tokenId)

// 4. Admin/Configuration Functions (9 functions):
//    - createTraitType(uint256 traitId, string calldata name, string calldata description, uint256 rarity)
//    - updateTraitType(uint256 traitId, string calldata name, string calldata description, uint256 rarity)
//    - createSkillType(uint256 skillId, string calldata name, string calldata description, uint256 duration)
//    - updateSkillType(uint256 skillId, string calldata name, string calldata description, uint256 duration)
//    - setBaseURI(string calldata baseURI_)
//    - setAdaptationCooldown(uint256 cooldownSeconds)
//    - setAdaptationRule(uint256 ruleId, bytes calldata ruleData) // Simplified rule structure
//    - grantTrait(uint256 tokenId, uint256 traitId)
//    - grantSkill(uint256 tokenId, uint256 skillId)

// 5. Helper/View Functions (3 functions):
//    - getTotalSupply()
//    - getTraitDetails(uint256 traitId)
//    - getSkillDetails(uint256 skillId)

// Total Functions: 32+ (counting internal helpers)

// --- Contract Implementation ---

contract AdaptiveAssetSystem is ERC721, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;

    struct Trait {
        string name;
        string description;
        uint256 rarity; // e.g., 1 for Common, 10 for Legendary
        bool exists; // To check if a traitId is defined
    }

    struct Skill {
        string name;
        string description;
        uint256 duration; // Duration in seconds the skill lasts (0 for permanent until removed)
        bool exists; // To check if a skillId is defined
    }

    // Represents the dynamic state of an individual Asset token
    struct AssetData {
        uint256 lastAdaptationCheck; // Timestamp of the last check
        uint256 lastStakeTime;       // Timestamp when the asset was last staked
        bool isStaked;               // Is the asset currently staked?
        uint256[] traitIds;          // List of trait IDs the asset has
        uint256[] skillIds;          // List of skill IDs the asset has
        // Add more dynamic data here as needed (e.g., XP, level, combat stats)
    }

    // --- State Variables ---

    mapping(uint256 => AssetData) private _assetData;
    mapping(uint256 => Trait) private _traitTypes;
    mapping(uint256 => Skill) private _skillTypes;

    mapping(address => uint256[]) private _stakedAssetsByOwner;
    mapping(uint256 => bool) private _isTokenStaked; // Helper for faster lookup

    string private _baseTokenURI;
    uint256 private _adaptationCooldown = 1 days; // Minimum time between adaptation checks per asset

    // Simplified representation of adaptation rules.
    // In a real system, this would be more complex, perhaps mapping conditions to trait/skill grants.
    // Example: ruleId 1 might be "Grant Trait X if staked for 30 days".
    // For this example, we'll use a basic mapping for simplicity and illustrate the concept.
    // bytes ruleData would encode the specific conditions and outcomes.
    mapping(uint256 => bytes) private _adaptationRules; // ruleId => encoded_rule_data

    // --- Events ---

    event AssetMinted(uint256 indexed tokenId, address indexed owner);
    event AdaptationApplied(uint256 indexed tokenId, uint256 timestamp);
    event TraitAddedToAsset(uint256 indexed tokenId, uint256 indexed traitId);
    event SkillAddedToAsset(uint256 indexed tokenId, uint256 indexed skillId);
    event SkillRemovedFromAsset(uint256 indexed tokenId, uint256 indexed skillId); // For timed skills
    event AssetStaked(uint256 indexed tokenId, address indexed owner, uint256 timestamp);
    event AssetUnstaked(uint256 indexed tokenId, address indexed owner, uint256 timestamp);
    event TraitTypeCreated(uint256 indexed traitId, string name);
    event SkillTypeCreated(uint256 indexed skillId, string name);
    event AdaptationRuleSet(uint256 indexed ruleId, bytes ruleData);

    // --- Constructor ---

    constructor(string memory name, string memory symbol) ERC721(name, symbol) Ownable(msg.sender) {}

    // --- ERC721 Overrides (to integrate staking logic) ---

    /// @dev See {ERC721-_update}. Prevents transfer/approval while staked.
    function _update(address to, uint256 tokenId, address auth) internal override returns (address) {
        require(!_assetData[tokenId].isStaked, "Asset: Staked assets cannot be transferred");
        return super._update(to, tokenId, auth);
    }

    /// @dev See {ERC721-_approve}. Prevents approval while staked.
    function _approve(address to, uint256 tokenId) internal override {
        require(!_assetData[tokenId].isStaked, "Asset: Staked assets cannot be approved");
        super._approve(to, tokenId);
    }

    /// @dev See {IERC721Metadata-tokenURI}. Appends token ID to base URI.
    /// This is where off-chain metadata logic would combine base URI with on-chain state.
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        if (!_exists(tokenId)) {
            revert ERC721NonexistentToken(tokenId);
        }
        // In a real application, the metadata server at _baseTokenURI/tokenId
        // would fetch the on-chain data using getAssetDetails(tokenId)
        // and generate a dynamic JSON metadata including traits and skills.
        return string(abi.encodePacked(_baseTokenURI, Strings.toString(tokenId)));
    }

    // --- Core Asset & Adaptation Functions ---

    /// @notice Mints a new Asset token. Only callable by the contract owner.
    /// Initializes basic asset data.
    function mint(address to) public onlyOwner {
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();

        _safeMint(to, tokenId);

        // Initialize dynamic data
        _assetData[tokenId] = AssetData({
            lastAdaptationCheck: block.timestamp,
            lastStakeTime: 0,
            isStaked: false,
            traitIds: new uint256[](0),
            skillIds: new uint256[](0)
            // Initialize other dynamic data here
        });

        emit AssetMinted(tokenId, to);
    }

    /// @notice Gets the detailed dynamic state of a specific Asset token.
    /// @param tokenId The ID of the token.
    /// @return AssetData struct containing all dynamic state.
    function getAssetDetails(uint256 tokenId) public view returns (AssetData memory) {
        require(_exists(tokenId), "Asset: token does not exist");
        return _assetData[tokenId];
    }

    /// @notice Gets the list of trait IDs for a specific Asset token.
    /// @param tokenId The ID of the token.
    /// @return An array of trait IDs.
    function getAssetTraits(uint256 tokenId) public view returns (uint256[] memory) {
        require(_exists(tokenId), "Asset: token does not exist");
        return _assetData[tokenId].traitIds;
    }

    /// @notice Gets the list of skill IDs for a specific Asset token.
    /// @param tokenId The ID of the token.
    /// @return An array of skill IDs.
    function getAssetSkills(uint256 tokenId) public view returns (uint256[] memory) {
        require(_exists(tokenId), "Asset: token does not exist");
        return _assetData[tokenId].skillIds;
    }

    /// @notice Triggers an adaptation check for a specific Asset token.
    /// Can only be called by the token owner or approved address.
    /// Checks if enough time has passed since the last check and applies
    /// adaptation rules based on current state (e.g., stake duration).
    /// @param tokenId The ID of the token to check.
    function triggerAdaptationCheck(uint256 tokenId) public {
        require(_exists(tokenId), "Asset: token does not exist");
        require(ownerOf(tokenId) == _msgSender() || getApproved(tokenId) == _msgSender() || isApprovedForAll(ownerOf(tokenId), _msgSender()), "Asset: Caller is not owner nor approved");

        AssetData storage asset = _assetData[tokenId];
        require(block.timestamp >= asset.lastAdaptationCheck + _adaptationCooldown, "Asset: Adaptation cooldown not passed");

        // --- Adaptation Logic ---
        // This is where the core logic lives.
        // Check various conditions and apply changes.

        uint256 timeSinceLastCheck = block.timestamp - asset.lastAdaptationCheck;

        // Example Rule: Grant a specific trait/skill if staked for a long time since last check
        if (asset.isStaked && asset.lastStakeTime > 0) {
             uint256 stakedDurationSinceLastCheck = block.timestamp - max(asset.lastStakeTime, asset.lastAdaptationCheck); // Duration staked within the check period

             // Example rule: if staked duration since last check is >= 30 days (rough example)
             // This would ideally reference _adaptationRules data
             if (stakedDurationSinceLastCheck >= 30 days) {
                 // Example: Attempt to add a specific trait (e.g., Trait ID 1)
                 // Need to check if Trait ID 1 exists and asset doesn't already have it
                 uint256 potentialTraitId = 1; // This comes from rules config
                 if (_traitTypes[potentialTraitId].exists && !_hasTrait(tokenId, potentialTraitId)) {
                     _addTraitToAsset(tokenId, potentialTraitId);
                 }
             }
             // Add more complex staking-based rules here
        }

        // Example Rule: Time-based passive skill gain (e.g., gain Skill ID 2 every 7 days of existence)
        // This would check total time existed or time since last check
        // Simplified: just an example of a time trigger
         if (timeSinceLastCheck >= 7 days) {
              uint256 potentialSkillId = 2; // From rules config
              if (_skillTypes[potentialSkillId].exists && !_hasSkill(tokenId, potentialSkillId)) {
                   _addSkillToAsset(tokenId, potentialSkillId); // Maybe grant a timed skill
              }
         }


        // --- End Adaptation Logic ---

        // Update last adaptation check time
        asset.lastAdaptationCheck = block.timestamp;

        // Handle removal of expired temporary skills (simplified example)
        // A more robust system might need to track skill expiry timestamps per asset.
        // For this example, we'll skip automatic expiry within this function to keep it simpler.
        // Expiry checks could happen off-chain or in specific skill-related functions.

        emit AdaptationApplied(tokenId, block.timestamp);
    }

    // --- Staking Functions ---

    /// @notice Stakes an Asset token. Caller must be the owner.
    /// Prevents transferring staked assets.
    /// @param tokenId The ID of the token to stake.
    function stakeAsset(uint256 tokenId) public {
        require(_exists(tokenId), "Asset: token does not exist");
        require(ownerOf(tokenId) == _msgSender(), "Asset: Caller is not owner");
        require(!_assetData[tokenId].isStaked, "Asset: Asset is already staked");

        _assetData[tokenId].isStaked = true;
        _assetData[tokenId].lastStakeTime = block.timestamp;
        _isTokenStaked[tokenId] = true; // Update helper mapping

        // Add to staked assets list for the owner (can be inefficient for many tokens)
        _stakedAssetsByOwner[_msgSender()].push(tokenId);

        // Revoke any existing approvals for the token
        approve(address(0), tokenId);

        emit AssetStaked(tokenId, _msgSender(), block.timestamp);
    }

    /// @notice Unstakes an Asset token. Caller must be the owner.
    /// @param tokenId The ID of the token to unstake.
    function unstakeAsset(uint256 tokenId) public {
        require(_exists(tokenId), "Asset: token does not exist");
        require(ownerOf(tokenId) == _msgSender(), "Asset: Caller is not owner");
        require(_assetData[tokenId].isStaked, "Asset: Asset is not staked");

        _assetData[tokenId].isStaked = false;
        _assetData[tokenId].lastStakeTime = 0; // Reset stake time
        _isTokenStaked[tokenId] = false; // Update helper mapping

        // Remove from staked assets list for the owner (can be inefficient)
        // Finding the index and removing requires iteration or a more complex mapping.
        // For simplicity, we'll leave the potential "null" spot in the array.
        // A better way is to use a mapping like address => mapping(uint256 => uint256) position and track size.
        // Or simply iterate in getStakedAssets to filter out non-staked ones.
        // For this example, we'll skip the removal from the array to keep code shorter.

        emit AssetUnstaked(tokenId, _msgSender(), block.timestamp);
    }

    /// @notice Gets the list of tokens an owner has staked.
    /// NOTE: This function might return token IDs that were unstaked due to
    /// the simplified removal logic in `unstakeAsset`. Filtering needs to be
    /// done by checking `isAssetStaked(tokenId)`.
    /// @param owner The address of the owner.
    /// @return An array of token IDs.
    function getStakedAssets(address owner) public view returns (uint256[] memory) {
         // In a real application with many tokens, this might need pagination
         // or an off-chain index.
         uint256[] memory staked = new uint256[](_stakedAssetsByOwner[owner].length);
         uint256 count = 0;
         for(uint i = 0; i < _stakedAssetsByOwner[owner].length; i++){
             uint256 tokenId = _stakedAssetsByOwner[owner][i];
             if(_isTokenStaked[tokenId]) { // Filter out unstaked ones
                 staked[count] = tokenId;
                 count++;
             }
         }
         assembly { // Trim the array
             mstore(staked, count)
         }
         return staked;
    }

    /// @notice Checks if a specific Asset token is currently staked.
    /// @param tokenId The ID of the token.
    /// @return True if staked, false otherwise.
    function isAssetStaked(uint256 tokenId) public view returns (bool) {
        return _isTokenStaked[tokenId];
    }


    // --- Admin/Configuration Functions ---

    /// @notice Defines a new type of Trait. Callable by the owner.
    /// @param traitId A unique identifier for the trait.
    /// @param name The name of the trait.
    /// @param description A description of the trait.
    /// @param rarity The rarity level (higher is rarer).
    function createTraitType(uint256 traitId, string calldata name, string calldata description, uint256 rarity) public onlyOwner {
        require(!_traitTypes[traitId].exists, "Trait: Trait ID already exists");
        _traitTypes[traitId] = Trait(name, description, rarity, true);
        emit TraitTypeCreated(traitId, name);
    }

    /// @notice Updates an existing Trait type. Callable by the owner.
    /// @param traitId The ID of the trait to update.
    /// @param name The new name.
    /// @param description The new description.
    /// @param rarity The new rarity level.
    function updateTraitType(uint256 traitId, string calldata name, string calldata description, uint256 rarity) public onlyOwner {
        require(_traitTypes[traitId].exists, "Trait: Trait ID does not exist");
        _traitTypes[traitId].name = name;
        _traitTypes[traitId].description = description;
        _traitTypes[traitId].rarity = rarity;
        // emit event if needed
    }

    /// @notice Defines a new type of Skill. Callable by the owner.
    /// @param skillId A unique identifier for the skill.
    /// @param name The name of the skill.
    /// @param description A description of the skill.
    /// @param duration The duration in seconds the skill lasts (0 for permanent until removed by rule).
    function createSkillType(uint256 skillId, string calldata name, string calldata description, uint256 duration) public onlyOwner {
        require(!_skillTypes[skillId].exists, "Skill: Skill ID already exists");
        _skillTypes[skillId] = Skill(name, description, duration, true);
        emit SkillTypeCreated(skillId, name);
    }

    /// @notice Updates an existing Skill type. Callable by the owner.
    /// @param skillId The ID of the skill to update.
    /// @param name The new name.
    /// @param description The new description.
    /// @param duration The new duration.
    function updateSkillType(uint256 skillId, string calldata name, string calldata description, uint256 duration) public onlyOwner {
         require(_skillTypes[skillId].exists, "Skill: Skill ID does not exist");
         _skillTypes[skillId].name = name;
         _skillTypes[skillId].description = description;
         _skillTypes[skillId].duration = duration;
         // emit event if needed
    }

    /// @notice Sets the base URI for token metadata. Callable by the owner.
    /// @param baseURI_ The base URI string.
    function setBaseURI(string calldata baseURI_) public onlyOwner {
        _baseTokenURI = baseURI_;
    }

    /// @notice Sets the cooldown duration for triggering adaptation checks per asset. Callable by the owner.
    /// @param cooldownSeconds The cooldown in seconds.
    function setAdaptationCooldown(uint256 cooldownSeconds) public onlyOwner {
        _adaptationCooldown = cooldownSeconds;
    }

    /// @notice Sets or updates an adaptation rule. Callable by the owner.
    /// ruleData is a placeholder for complex rule logic.
    /// @param ruleId The ID of the rule.
    /// @param ruleData Encoded data representing the rule's conditions and effects.
    function setAdaptationRule(uint256 ruleId, bytes calldata ruleData) public onlyOwner {
        _adaptationRules[ruleId] = ruleData;
        emit AdaptationRuleSet(ruleId, ruleData);
    }

    /// @notice Grants a specific trait to an asset. Callable by the owner (e.g., for manual correction or events).
    /// Does nothing if the asset already has the trait.
    /// @param tokenId The ID of the asset.
    /// @param traitId The ID of the trait to grant.
    function grantTrait(uint256 tokenId, uint256 traitId) public onlyOwner {
        require(_exists(tokenId), "Asset: token does not exist");
        require(_traitTypes[traitId].exists, "Trait: Trait ID does not exist");
        _addTraitToAsset(tokenId, traitId);
    }

    /// @notice Grants a specific skill to an asset. Callable by the owner.
    /// Does nothing if the asset already has the skill.
    /// @param tokenId The ID of the asset.
    /// @param skillId The ID of the skill to grant.
    function grantSkill(uint256 tokenId, uint256 skillId) public onlyOwner {
        require(_exists(tokenId), "Asset: token does not exist");
        require(_skillTypes[skillId].exists, "Skill: Skill ID does not exist");
        _addSkillToAsset(tokenId, skillId);
    }

    // --- Helper/View Functions ---

    /// @notice Gets the total number of tokens minted.
    /// @return The total supply.
    function getTotalSupply() public view returns (uint256) {
        return _tokenIdCounter.current();
    }

    /// @notice Gets the details of a specific Trait type.
    /// @param traitId The ID of the trait type.
    /// @return Trait struct details.
    function getTraitDetails(uint256 traitId) public view returns (Trait memory) {
        require(_traitTypes[traitId].exists, "Trait: Trait ID does not exist");
        return _traitTypes[traitId];
    }

    /// @notice Gets the details of a specific Skill type.
    /// @param skillId The ID of the skill type.
    /// @return Skill struct details.
    function getSkillDetails(uint256 skillId) public view returns (Skill memory) {
        require(_skillTypes[skillId].exists, "Skill: Skill ID does not exist");
        return _skillTypes[skillId];
    }

    // --- Internal Helper Functions ---

    /// @dev Internal function to add a trait to an asset's state.
    /// Checks if the asset already has the trait.
    function _addTraitToAsset(uint256 tokenId, uint256 traitId) internal {
        AssetData storage asset = _assetData[tokenId];
        // Check if the asset already has this trait
        for (uint i = 0; i < asset.traitIds.length; i++) {
            if (asset.traitIds[i] == traitId) {
                return; // Asset already has this trait
            }
        }
        asset.traitIds.push(traitId);
        emit TraitAddedToAsset(tokenId, traitId);
    }

    /// @dev Internal function to add a skill to an asset's state.
    /// Checks if the asset already has the skill.
    function _addSkillToAsset(uint256 tokenId, uint256 skillId) internal {
        AssetData storage asset = _assetData[tokenId];
         // Check if the asset already has this skill
        for (uint i = 0; i < asset.skillIds.length; i++) {
            if (asset.skillIds[i] == skillId) {
                return; // Asset already has this skill
            }
        }
        asset.skillIds.push(skillId);
        emit SkillAddedToAsset(tokenId, skillId);
    }

    /// @dev Internal function to remove a skill from an asset's state.
    /// (Simplified removal - does not maintain order)
    function _removeSkillFromAsset(uint256 tokenId, uint256 skillId) internal {
         AssetData storage asset = _assetData[tokenId];
         uint256 len = asset.skillIds.length;
         for (uint i = 0; i < len; i++) {
             if (asset.skillIds[i] == skillId) {
                 // Replace with last element and pop
                 asset.skillIds[i] = asset.skillIds[len - 1];
                 asset.skillIds.pop();
                 emit SkillRemovedFromAsset(tokenId, skillId);
                 return;
             }
         }
    }

    /// @dev Internal function to check if an asset has a specific trait.
    function _hasTrait(uint256 tokenId, uint256 traitId) internal view returns (bool) {
        AssetData memory asset = _assetData[tokenId];
        for (uint i = 0; i < asset.traitIds.length; i++) {
            if (asset.traitIds[i] == traitId) {
                return true;
            }
        }
        return false;
    }

     /// @dev Internal function to check if an asset has a specific skill.
    function _hasSkill(uint256 tokenId, uint256 skillId) internal view returns (bool) {
        AssetData memory asset = _assetData[tokenId];
        for (uint i = 0; i < asset.skillIds.length; i++) {
            if (asset.skillIds[i] == skillId) {
                return true;
            }
        }
        return false;
    }

    // Add other internal helper functions for complex adaptation rule processing here
    // e.g., _processAdaptationRule(uint256 tokenId, uint256 ruleId, bytes memory ruleData)

    // --- Fallback and Receive Functions (Optional, but good practice) ---
    // receive() external payable {}
    // fallback() external payable {}

}
```

**Explanation and Creative Aspects:**

1.  **Dynamic State (`AssetData` struct):** The key is that `_assetData` mapping stores mutable data for each token ID, separate from the immutable properties often associated with NFTs at mint. This allows the asset to change over time.
2.  **Trait vs. Skill:** Introduced two types of properties: `Trait` (intended to be permanent, granted through adaptation or admin) and `Skill` (potentially temporary, with a `duration` field). While the automatic expiry logic for skills isn't fully implemented (that would add significant complexity, perhaps needing per-skill timestamps or a background process/oracle), the structure is there.
3.  **Adaptation Trigger (`triggerAdaptationCheck`):** Instead of adaptation happening automatically on a block or based on an oracle, it's *user-initiated*. This is a common pattern in games or yield farming to save gas; the user pays the gas to claim rewards or trigger state changes. The function checks cooldowns and then runs the core (simplified) adaptation logic.
4.  **Staking as Catalyst:** The `stakeAsset` and `unstakeAsset` functions modify the `isStaked` status and `lastStakeTime`. The `triggerAdaptationCheck` function *uses* the staking duration (`lastStakeTime`) as one of the conditions for applying changes. This is more advanced than just staking for a token reward; staking *changes the asset itself*.
5.  **Owner-Configurable Adaptation:** The `createTraitType`, `createSkillType`, and `setAdaptationRule` functions allow the contract owner to define the "game mechanics" or "evolution rules" after deployment. This makes the system flexible and not hardcoded to a single adaptation path. `setAdaptationRule` is a placeholder, as encoding complex rules in `bytes` and interpreting them on-chain is non-trivial but represents the concept of owner-defined evolution logic.
6.  **Metadata (`tokenURI`):** The `tokenURI` function is designed to point to a service that reads the *current* on-chain state (`getAssetDetails`) and generates metadata (including traits and skills) reflecting the asset's evolution. This is standard practice for dynamic NFTs.
7.  **Avoiding Open Source Duplication:** While using OpenZeppelin libraries is standard and good practice, the *logic* of having an ERC721 with a dynamic `AssetData` struct whose contents (specifically trait/skill arrays) are mutated by user-triggered adaptation checks based on internal state like staking duration and time, managed by owner-defined rules, is a specific combination not found in standard ERC-721, basic staking contracts, or simple PFP NFT templates.

This contract provides a framework for an evolving, interactive NFT system. The core adaptation logic within `triggerAdaptationCheck` and the interpretation of `_adaptationRules` would be the most complex parts to expand upon for a production system, but the structure with 30+ functions covering the core requirements is present.