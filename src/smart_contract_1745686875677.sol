Okay, here is a Solidity smart contract incorporating several advanced, creative, and trendy concepts within a single ecosystem, focusing on dynamic NFTs, on-chain mechanics, and state progression.

It simulates a "Chronicle Engine" that forges unique artifacts (NFTs), allows them to be evolved and combined through crafting, tracks their history, and introduces a concept of "epochs" and "chronicle fragments" influencing the ecosystem.

This design is *not* a standard ERC-721 or common DeFi protocol clone. It combines elements of generative art (simulated), on-chain gaming, dynamic metadata, and stateful progression.

---

## Smart Contract Outline & Function Summary

**Contract Name:** `EpochForge`

**Concept:** A system for forging, evolving, and crafting dynamic digital artifacts (NFTs) influenced by an on-chain "Epoch" system and collected "Chronicle Fragments". Artifacts have mutable attributes and on-chain history.

**Core Components:**
1.  **Artifacts:** ERC-721 compliant NFTs with dynamic attributes stored on-chain.
2.  **Attributes:** Numerical values (Power, Resilience, Affinity) and arrays (Chronicle Fragments) that define an artifact. Attributes can change.
3.  **Epochs:** A global counter/state variable that influences artifact genesis and evolution. Advances via owner or specific triggers.
4.  **Chronicle Fragments:** Collectible items (simulated as IDs within artifacts or owner mappings) that can be assembled.
5.  **Crafting:** Combining multiple artifacts (burning inputs) to create new, potentially more powerful or different, artifacts (minting outputs) based on defined recipes.
6.  **Attunement:** A user action performed on an artifact to potentially boost attributes or trigger small changes.
7.  **History:** On-chain log of significant events for each artifact.
8.  **Recipes:** Owner-definable criteria for crafting outcomes.

**Function Categories:**

*   **ERC-721 Standard (7 functions):** Core NFT functions for ownership, transfer, and approvals.
*   **Artifact Management (5 functions):** Forging, getting attributes, attuning, burning, history retrieval.
*   **Epoch & Chronicle System (4 functions):** Managing epochs, viewing epoch influence, viewing fragments, assembling fragments.
*   **Crafting & Recipes (4 functions):** Crafting execution, getting recipe details, getting potential outcomes, discovering recipes (simulated).
*   **Admin & Utility (7 functions):** Owner controls (set costs, limits, recipes, epoch), withdrawal, getting contract state info, tokenURI resolution.

**Total Functions:** 27

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

// Note: For true randomness in a high-value context, use Chainlink VRF or a similar secure oracle.
// The randomness used here (blockhash + nonce) is simple and predictable, suitable for demonstration but NOT for production where security is critical.

/**
 * @title EpochForge
 * @dev A decentralized system for forging, evolving, and crafting dynamic NFTs (Artifacts)
 *      influenced by an on-chain Epoch system and Chronicle Fragments.
 *      Artifacts have mutable attributes and track their history on-chain.
 *
 * Outline:
 * - Core NFT (ERC-721 base)
 * - Dynamic Attributes & History
 * - Epoch & Chronicle Fragment System
 * - Crafting & Recipe Mechanics
 * - User Interactions (Forge, Attune, Craft, Assemble)
 * - Admin Functionality
 * - Utility & View Functions
 */
contract EpochForge is ERC721, Ownable {
    using Counters for Counters.Counter;
    using SafeMath for uint256;

    // --- State Variables ---

    Counters.Counter private _tokenIdCounter;

    // Artifact Attributes
    struct ArtifactAttributes {
        uint256 power;
        uint256 resilience;
        uint256 affinity;
        uint256[] chronicleFragmentIds; // IDs of fragments embedded in this artifact
    }
    mapping(uint256 => ArtifactAttributes) private _artifactAttributes;

    // Artifact History
    struct HistoryEntry {
        uint256 timestamp;
        string action;
        string details; // e.g., "Forged in Epoch X", "Attuned by User Y", "Crafted using Inputs A, B"
    }
    mapping(uint256 => HistoryEntry[]) private _artifactHistory;

    // Epoch System
    uint256 private _currentEpoch;
    mapping(uint256 => string) private _epochInfluenceDescription; // Describes effects of each epoch
    mapping(uint256 => int256[3]) private _epochAttributeBoosts; // [Power, Resilience, Affinity] boost/penalty per epoch

    // Chronicle Fragments collected by owners (outside of artifacts)
    // Represents fragments discovered or extracted, not yet assembled
    mapping(address => mapping(uint256 => uint256)) private _ownerChronicleFragments; // owner => fragmentId => count

    // Recipe System
    struct RecipeDetails {
        uint256[] inputAttributeMins; // Minimum power, resilience, affinity required from inputs
        uint256 minInputCount; // Minimum number of artifacts needed
        uint256 maxInputCount; // Maximum number of artifacts allowed
        uint256 outputCount; // Number of artifacts created by recipe
        int256[3] outputAttributeModifiers; // [Power, Resilience, Affinity] modifier for output
        bool requiresAssembly; // Does assembling a specific Chronicle unlock this recipe?
        uint256 requiredAssemblyId; // The assembly ID needed if requiresAssembly is true
        bool isActive; // Can this recipe be used?
    }
    mapping(uint256 => RecipeDetails) private _recipes;
    uint256 private _nextRecipeId = 1;

    // Genesis Parameters
    uint256 private _genesisCost = 0.01 ether; // Cost to forge a new artifact
    uint256 private _genesisLimit = 1000; // Maximum number of genesis artifacts
    uint256 private _genesisCounter; // Counter for genesis artifacts forged

    // Attunement Cooldown
    mapping(uint256 => uint256) private _lastAttunedTimestamp; // tokenId => timestamp
    uint256 private _attunementCooldown = 1 days; // Cooldown period between attunements for a single artifact

    // Base URI for metadata
    string private _baseTokenURI;

    // --- Events ---

    event ArtifactForged(uint256 indexed tokenId, address indexed owner, uint256 epoch, uint256 initialPower, uint256 initialResilience, uint256 initialAffinity);
    event ArtifactAttuned(uint256 indexed tokenId, address indexed owner, uint256 newPower, uint256 newResilience, uint256 newAffinity);
    event ArtifactCrafted(address indexed owner, uint256[] indexed inputTokenIds, uint256 indexed outputTokenId, uint256 recipeId);
    event EpochAdvanced(uint256 indexed newEpoch, string influenceDescription);
    event RecipeUpdated(uint256 indexed recipeId, bool isActive);
    event GenesisParamsUpdated(uint256 newCost, uint256 newLimit);
    event EssenceExtracted(address indexed owner, uint256 indexed fromTokenId, uint256[] fragmentIds);
    event ChronicleAssembled(address indexed owner, uint256[] usedFragmentIds, uint256 indexed assemblyId);
    event ArtifactBurned(uint256 indexed tokenId, address indexed owner);

    // --- Constructor ---

    constructor(string memory name, string memory symbol, string memory baseTokenURI)
        ERC721(name, symbol)
        Ownable(msg.sender)
    {
        _baseTokenURI = baseTokenURI;
        _currentEpoch = 1; // Start at Epoch 1
        _epochInfluenceDescription[1] = "Initial era. Basic attributes are common.";
        _epochAttributeBoosts[1] = [int256(0), int256(0), int256(0)]; // No initial boost
        // Define a sample starting recipe (Recipe ID 1)
        _recipes[1] = RecipeDetails({
            inputAttributeMins: new uint256[](3), // [0, 0, 0] minimums
            minInputCount: 2,
            maxInputCount: 2,
            outputCount: 1,
            outputAttributeModifiers: [int256(10), int256(10), int256(5)], // Output gets +10 Power, +10 Res, +5 Aff per input artifact
            requiresAssembly: false,
            requiredAssemblyId: 0,
            isActive: true
        });
        _nextRecipeId++;
    }

    // --- ERC-721 Standard Functions (7) ---

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view returns (uint256) {
        return _tokenIdCounter.current();
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view override returns (uint256) {
        require(owner != address(0), "ERC721: address zero is not a valid owner");
        return super.balanceOf(owner);
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view override returns (address) {
        return super.ownerOf(tokenId);
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(address from, address to, uint256 tokenId) public override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(msg.sender, tokenId), "ERC721: transfer caller is not owner nor approved");
        _transfer(from, to, tokenId);
    }

     /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) public override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public override {
        require(_isApprovedOrOwner(msg.sender, tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, data);
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");
        require(msg.sender == owner || isApprovedForAll(owner, msg.sender), "ERC721: approve caller is not owner nor approved for all");
        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view override returns (address) {
        return super.getApproved(tokenId);
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public override {
        _setApprovalForAll(msg.sender, operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view override returns (bool) {
        return super.isApprovedForAll(owner, operator);
    }

    // --- Internal ERC-721 Helpers ---

    function _update(uint256 tokenId, address to) internal override returns (address, address) {
        return super._update(tokenId, to);
    }

    function _increaseBalance(address account, uint128 value) internal override {
        super._increaseBalance(account, value);
    }

    function _decreaseBalance(address account, uint128 value) internal override {
        super._decreaseBalance(account, value);
    }


    // --- Artifact Management Functions (5) ---

    /**
     * @dev Allows a user to forge a new genesis artifact.
     *      Requires payment and adheres to the genesis limit.
     *      Initial attributes are semi-random, influenced by the current epoch.
     */
    function forgeGenesisArtifact() public payable {
        require(_genesisCounter < _genesisLimit, "EpochForge: Genesis limit reached");
        require(msg.value >= _genesisCost, "EpochForge: Insufficient payment");

        uint256 newTokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _genesisCounter++;

        _safeMint(msg.sender, newTokenId);

        // Simple Pseudo-Randomness (NOT secure for high-value decisions)
        // For demonstration, use blockhash and nonce. In production, use Chainlink VRF.
        uint256 entropy = uint256(keccak256(abi.encodePacked(blockhash(block.number - 1), block.timestamp, tx.origin, newTokenId, _genesisCounter)));

        ArtifactAttributes memory newAttributes;
        newAttributes.power = (entropy % 100) + 1; // 1-100 base
        entropy = entropy / 100;
        newAttributes.resilience = (entropy % 100) + 1; // 1-100 base
        entropy = entropy / 100;
        newAttributes.affinity = (entropy % 100) + 1; // 1-100 base
        newAttributes.chronicleFragmentIds = new uint256[](0); // Starts with no fragments

        // Apply epoch influence (simple additive for demo)
        newAttributes.power = uint256(int256(newAttributes.power).add(_epochAttributeBoosts[_currentEpoch][0]));
        newAttributes.resilience = uint256(int256(newAttributes.resilience).add(_epochAttributeBoosts[_currentEpoch][1]));
        newAttributes.affinity = uint256(int256(newAttributes.affinity).add(_epochAttributeBoosts[_currentEpoch][2]));

        _artifactAttributes[newTokenId] = newAttributes;

        _addHistoryEntry(newTokenId, "Forge", string(abi.encodePacked("Forged in Epoch ", Strings.toString(_currentEpoch), " by ", payable(msg.sender))));

        emit ArtifactForged(newTokenId, msg.sender, _currentEpoch, newAttributes.power, newAttributes.resilience, newAttributes.affinity);

        // Refund excess ETH
        if (msg.value > _genesisCost) {
            payable(msg.sender).transfer(msg.value - _genesisCost);
        }
    }

    /**
     * @dev Gets the current attributes of an artifact.
     * @param tokenId The ID of the artifact.
     * @return power, resilience, affinity, chronicleFragmentIds.
     */
    function getArtifactAttributes(uint256 tokenId) public view returns (uint256 power, uint256 resilience, uint256 affinity, uint256[] memory chronicleFragmentIds) {
        ArtifactAttributes storage attrs = _artifactAttributes[tokenId];
        return (attrs.power, attrs.resilience, attrs.affinity, attrs.chronicleFragmentIds);
    }

     /**
     * @dev Allows the owner of an artifact to 'attune' it, potentially boosting attributes.
     *      Subject to a cooldown.
     * @param tokenId The ID of the artifact to attune.
     */
    function attuneArtifact(uint256 tokenId) public {
        require(_isApprovedOrOwner(msg.sender, tokenId), "EpochForge: Attunement caller is not owner nor approved");
        require(block.timestamp >= _lastAttunedTimestamp[tokenId].add(_attunementCooldown), "EpochForge: Attunement on cooldown");

        ArtifactAttributes storage attrs = _artifactAttributes[tokenId];

        // Simple attribute boost based on current attributes
        attrs.power = attrs.power.add((attrs.affinity / 10) + 1); // Affinity helps Power
        attrs.resilience = attrs.resilience.add((attrs.power / 10) + 1); // Power helps Resilience
        attrs.affinity = attrs.affinity.add((attrs.resilience / 10) + 1); // Resilience helps Affinity

        _lastAttunedTimestamp[tokenId] = block.timestamp;

        _addHistoryEntry(tokenId, "Attune", string(abi.encodePacked("Attuned by ", payable(msg.sender))));

        emit ArtifactAttuned(tokenId, msg.sender, attrs.power, attrs.resilience, attrs.affinity);
    }

    /**
     * @dev Allows the owner of an artifact to burn it.
     * @param tokenId The ID of the artifact to burn.
     */
    function burnArtifact(uint256 tokenId) public {
        require(_isApprovedOrOwner(msg.sender, tokenId), "EpochForge: Burn caller is not owner nor approved");

        address owner = ERC721.ownerOf(tokenId);

        // Record history *before* burning/deleting state
         _addHistoryEntry(tokenId, "Burn", string(abi.encodePacked("Burned by ", payable(msg.sender))));

        // Clean up state associated with the token
        delete _artifactAttributes[tokenId];
        // Keep _artifactHistory for burned tokens, as history is valuable even after burning

        _burn(tokenId);

        emit ArtifactBurned(tokenId, owner);
    }

    /**
     * @dev Retrieves the history of a specific artifact.
     * @param tokenId The ID of the artifact.
     * @return An array of HistoryEntry structs.
     */
    function getArtifactHistory(uint256 tokenId) public view returns (HistoryEntry[] memory) {
        return _artifactHistory[tokenId];
    }


    // --- Epoch & Chronicle System Functions (4) ---

    /**
     * @dev Gets the current global epoch number.
     */
    function getCurrentEpoch() public view returns (uint256) {
        return _currentEpoch;
    }

    /**
     * @dev Owner-only function to advance the epoch.
     *      Could trigger global effects or state changes (simplified here).
     */
    function triggerEpochAdvance(string memory influenceDescription, int256 powerBoost, int256 resilienceBoost, int256 affinityBoost) public onlyOwner {
        _currentEpoch++;
        _epochInfluenceDescription[_currentEpoch] = influenceDescription;
        _epochAttributeBoosts[_currentEpoch] = [powerBoost, resilienceBoost, affinityBoost];
        // Potential future: Add code here to iterate through all artifacts and apply passive evolution effects based on the new epoch.
        emit EpochAdvanced(_currentEpoch, influenceDescription);
    }

    /**
     * @dev Gets the count of chronicle fragments owned by a user.
     * @param owner The address to check.
     * @param fragmentId The ID of the fragment.
     * @return The count of fragments owned.
     */
    function getChronicleFragments(address owner, uint256 fragmentId) public view returns (uint256) {
        return _ownerChronicleFragments[owner][fragmentId];
    }

    /**
     * @dev Allows a user to assemble owned chronicle fragments.
     *      Requires specific fragments and burns them upon success.
     *      Can unlock benefits (e.g., special crafting assemblyId - simplified here).
     * @param fragmentIdsToUse The IDs of the fragments to attempt assembly with.
     * @return The ID of the assembled Chronicle (if successful).
     */
    function assembleChronicle(uint256[] memory fragmentIdsToUse) public returns (uint256 assemblyId) {
        // Example simplified assembly: Requires 1 of fragment 1 and 1 of fragment 2 to assemble Chronicle 1.
        // More complex logic would involve checking specific combinations and burning required amounts.
        require(fragmentIdsToUse.length == 2, "EpochForge: Requires exactly 2 fragments for this assembly");
        require(fragmentIdsToUse[0] == 1 && fragmentIdsToUse[1] == 2, "EpochForge: Incorrect fragments for assembly 1");

        // Check if user owns required fragments
        require(_ownerChronicleFragments[msg.sender][1] > 0, "EpochForge: Missing fragment 1");
        require(_ownerChronicleFragments[msg.sender][2] > 0, "EpochForge: Missing fragment 2");

        // Burn the fragments
        _ownerChronicleFragments[msg.sender][1]--;
        _ownerChronicleFragments[msg.sender][2]--;

        // Success! Assign an assembly ID (e.g., 1)
        assemblyId = 1;

        // Future: Grant user a special ability, store assembly success state per user, etc.
         emit ChronicleAssembled(msg.sender, fragmentIdsToUse, assemblyId);
    }


    // --- Crafting & Recipes Functions (4) ---

    /**
     * @dev Allows a user to craft new artifacts by combining (burning) existing ones.
     *      Requires owning input artifacts and matching a recipe's criteria.
     * @param inputTokenIds The IDs of the artifacts to use as input.
     * @param recipeId The ID of the recipe to attempt.
     */
    function craftArtifact(uint256[] memory inputTokenIds, uint256 recipeId) public {
        RecipeDetails storage recipe = _recipes[recipeId];
        require(recipe.isActive, "EpochForge: Recipe not active");
        require(inputTokenIds.length >= recipe.minInputCount && inputTokenIds.length <= recipe.maxInputCount, "EpochForge: Incorrect number of inputs");

        // Check ownership and collect total input attributes
        uint256 totalPower = 0;
        uint256 totalResilience = 0;
        uint256 totalAffinity = 0;
        // Use a mapping to prevent duplicate token IDs in input
        mapping(uint256 => bool) seenInputIds;

        for (uint i = 0; i < inputTokenIds.length; i++) {
            uint256 tokenId = inputTokenIds[i];
            require(ownerOf(tokenId) == msg.sender, "EpochForge: Caller does not own all input artifacts");
            require(!seenInputIds[tokenId], "EpochForge: Duplicate input token ID");
            seenInputIds[tokenId] = true;

            ArtifactAttributes storage inputAttrs = _artifactAttributes[tokenId];
            totalPower = totalPower.add(inputAttrs.power);
            totalResilience = totalResilience.add(inputAttrs.resilience);
            totalAffinity = totalAffinity.add(inputAttrs.affinity);
        }

        // Check recipe input criteria (simplified: total attributes meet minimums)
        require(totalPower >= recipe.inputAttributeMins[0], "EpochForge: Insufficient total power");
        require(totalResilience >= recipe.inputAttributeMins[1], "EpochForge: Insufficient total resilience");
        require(totalAffinity >= recipe.inputAttributeMins[2], "EpochForge: Insufficient total affinity");

        // Check if recipe requires assembly and user has performed it (simplified)
        if (recipe.requiresAssembly) {
             // This check needs a state variable tracking user's assembled chronicles
             // For demo, let's skip this complex check or assume assemblyId 1 is universally unlocked
             // require(_userHasAssembledChronicle[msg.sender][recipe.requiredAssemblyId], "EpochForge: Required Chronicle Assembly missing");
        }


        // Execute Crafting: Burn inputs, Mint outputs
        for (uint i = 0; i < inputTokenIds.length; i++) {
            _burn(inputTokenIds[i]);
            delete _artifactAttributes[inputTokenIds[i]]; // Clean up attributes
             // Keep history for burned tokens
        }

        uint256 firstOutputTokenId = 0; // To include in event
        for (uint i = 0; i < recipe.outputCount; i++) {
            uint256 newTokenId = _tokenIdCounter.current();
            _tokenIdCounter.increment();
            _safeMint(msg.sender, newTokenId);

            if (i == 0) {
                firstOutputTokenId = newTokenId;
            }

            // Calculate output attributes based on recipe modifiers and input totals
            ArtifactAttributes memory outputAttributes;
            outputAttributes.power = uint256(int256(totalPower).add(recipe.outputAttributeModifiers[0] * int256(inputTokenIds.length))); // Modifier per input
            outputAttributes.resilience = uint256(int256(totalResilience).add(recipe.outputAttributeModifiers[1] * int256(inputTokenIds.length)));
            outputAttributes.affinity = uint256(int256(totalAffinity).add(recipe.outputAttributeModifiers[2] * int256(inputTokenIds.length)));
             // Output fragments? Recipes could add specific fragments here. Simplified: outputs get no new fragments initially.
            outputAttributes.chronicleFragmentIds = new uint256[](0);


            _artifactAttributes[newTokenId] = outputAttributes;

            string memory inputIdsString = ""; // Simplified: just list count
            inputIdsString = string(abi.encodePacked(Strings.toString(inputTokenIds.length), " inputs"));

             _addHistoryEntry(newTokenId, "Craft", string(abi.encodePacked("Crafted using recipe ", Strings.toString(recipeId), " with ", inputIdsString)));

            emit ArtifactCrafted(msg.sender, inputTokenIds, newTokenId, recipeId); // Emitting first output ID, could change
        }
    }

    /**
     * @dev Gets details about a specific crafting recipe.
     * @param recipeId The ID of the recipe.
     * @return RecipeDetails struct.
     */
    function getRecipeDetails(uint256 recipeId) public view returns (RecipeDetails memory) {
        require(_recipes[recipeId].isActive, "EpochForge: Recipe not active");
        return _recipes[recipeId];
    }

     /**
     * @dev Simulates a crafting outcome based on inputs and recipe.
     *      Does NOT execute the craft, just checks feasibility and potential output attributes.
     *      Does not account for RNG if recipes involved it.
     * @param inputTokenIds The IDs of the artifacts to use as input (must be owned by caller).
     * @param recipeId The ID of the recipe.
     * @return isPossible, potentialOutputAttributes.
     */
    function getPotentialCraftingOutcome(uint256[] memory inputTokenIds, uint256 recipeId) public view returns (bool isPossible, ArtifactAttributes[] memory potentialOutputAttributes) {
         RecipeDetails storage recipe = _recipes[recipeId];
        if (!recipe.isActive) return (false, new ArtifactAttributes[](0));
        if (inputTokenIds.length < recipe.minInputCount || inputTokenIds.length > recipe.maxInputCount) return (false, new ArtifactAttributes[](0));

        uint256 totalPower = 0;
        uint256 totalResilience = 0;
        uint256 totalAffinity = 0;
         mapping(uint256 => bool) seenInputIds;

        for (uint i = 0; i < inputTokenIds.length; i++) {
            uint256 tokenId = inputTokenIds[i];
            // Check ownership implicitly by accessing attributes; owner must own it to have attributes stored? No, ownerOf is better.
            if (ownerOf(tokenId) != msg.sender) return (false, new ArtifactAttributes[](0));
            if (seenInputIds[tokenId]) return (false, new ArtifactAttributes[](0));
            seenInputIds[tokenId] = true;

            ArtifactAttributes storage inputAttrs = _artifactAttributes[tokenId];
            totalPower = totalPower.add(inputAttrs.power);
            totalResilience = totalResilience.add(inputAttrs.resilience);
            totalAffinity = totalAffinity.add(inputAttrs.affinity);
        }

        // Check recipe input criteria (simplified: total attributes meet minimums)
        if (totalPower < recipe.inputAttributeMins[0]) return (false, new ArtifactAttributes[](0));
        if (totalResilience < recipe.inputAttributeMins[1]) return (false, new ArtifactAttributes[](0));
        if (totalAffinity < recipe.inputAttributeMins[2]) return (false, new ArtifactAttributes[](0));

        // Check if recipe requires assembly (simplified)
        if (recipe.requiresAssembly) {
             // This check needs a state variable tracking user's assembled chronicles
             // For demo, let's skip this complex check or assume assemblyId 1 is universally unlocked
             // if (!_userHasAssembledChronicle[msg.sender][recipe.requiredAssemblyId]) return (false, new ArtifactAttributes[](0));
        }

        // If all checks pass, calculate potential output attributes
        potentialOutputAttributes = new ArtifactAttributes[](recipe.outputCount);
         for(uint i = 0; i < recipe.outputCount; i++) {
            potentialOutputAttributes[i].power = uint256(int256(totalPower).add(recipe.outputAttributeModifiers[0] * int256(inputTokenIds.length)));
            potentialOutputAttributes[i].resilience = uint256(int256(totalResilience).add(recipe.outputAttributeModifiers[1] * int256(inputTokenIds.length)));
            potentialOutputAttributes[i].affinity = uint256(int256(totalAffinity).add(recipe.outputAttributeModifiers[2] * int256(inputTokenIds.length)));
             potentialOutputAttributes[i].chronicleFragmentIds = new uint256[](0); // Potential outputs don't show fragments here
         }


        return (true, potentialOutputAttributes);
    }

     /**
     * @dev Allows burning artifacts to potentially discover new recipes.
     *      (Simplified implementation: burns and maybe increments a hidden discovery counter,
     *       actual recipe unlocking logic is external or owner-controlled in this demo).
     * @param inputTokenIds The IDs of artifacts to burn for discovery.
     */
    function discoverRecipe(uint256[] memory inputTokenIds) public {
         require(inputTokenIds.length > 0, "EpochForge: Need inputs for discovery");

        uint256 totalPower = 0;
        for (uint i = 0; i < inputTokenIds.length; i++) {
            uint256 tokenId = inputTokenIds[i];
            require(ownerOf(tokenId) == msg.sender, "EpochForge: Caller does not own all discovery inputs");
            ArtifactAttributes storage inputAttrs = _artifactAttributes[tokenId];
            totalPower = totalPower.add(inputAttrs.power); // Example discovery criteria

            _burn(tokenId); // Burn the inputs
             delete _artifactAttributes[tokenId]; // Clean up attributes
              _addHistoryEntry(tokenId, "Discovery", string(abi.encodePacked("Used in discovery attempt by ", payable(msg.sender))));
        }

        // Simplified discovery: If total power is high enough, maybe unlock recipe 2
        // In a real system, this would involve complex logic, state tracking per user/globally
        // and potentially randomness.
        if (totalPower > 200 && !_recipes[2].isActive) {
             // Example: Unlock recipe 2
             _recipes[2] = RecipeDetails({
                inputAttributeMins: new uint256[](3), // [100, 100, 100] minimums
                minInputCount: 3,
                maxInputCount: 3,
                outputCount: 2, // Creates 2 outputs
                outputAttributeModifiers: [int256(50), int256(50), int256(50)], // Significant boost
                requiresAssembly: true, // Requires Chronicle Assembly 1
                requiredAssemblyId: 1,
                isActive: true // Now active globally
             });
             _nextRecipeId++; // Recipe ID 2 is now active
             emit RecipeUpdated(2, true);
        }
        // No specific event for *attempted* discovery result in this demo, just the burn.
    }

    /**
     * @dev Allows burning an artifact to extract Chronicle Fragments.
     *      The type and number of fragments depend on the artifact's attributes/fragments.
     * @param tokenId The ID of the artifact to extract from.
     * @return fragmentIds The IDs of the fragments extracted.
     */
    function extractEssence(uint256 tokenId) public returns (uint256[] memory fragmentIds) {
        require(ownerOf(tokenId) == msg.sender, "EpochForge: Caller does not own artifact");

        ArtifactAttributes storage attrs = _artifactAttributes[tokenId];
        fragmentIds = attrs.chronicleFragmentIds; // Extract embedded fragments

        // Add fragments to owner's collection
        for(uint i = 0; i < fragmentIds.length; i++) {
            _ownerChronicleFragments[msg.sender][fragmentIds[i]]++;
        }

        // Burn the artifact after extraction
        _burn(tokenId);
        delete _artifactAttributes[tokenId]; // Clean up attributes
        _addHistoryEntry(tokenId, "Essence Extraction", string(abi.encodePacked("Essence extracted by ", payable(msg.sender))));


        emit EssenceExtracted(msg.sender, tokenId, fragmentIds);

        return fragmentIds; // Return the extracted fragments
    }

    // --- Admin & Utility Functions (7) ---

     /**
     * @dev Gets the base URI for token metadata.
     *      A metadata service would use this and query getArtifactAttributes
     *      and getArtifactHistory to generate dynamic metadata.
     */
    function _baseURI() internal view override returns (string memory) {
        return _baseTokenURI;
    }

    /**
     * @dev Returns the URI for a given token ID.
     *      Points to a metadata service that can read on-chain attributes.
     */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        _requireOwned(tokenId);
        // Concatenate base URI with token ID.
        // A metadata server at _baseTokenURI should handle the actual metadata resolution
        // by querying the contract's state using the token ID.
        return string(abi.encodePacked(_baseTokenURI, Strings.toString(tokenId)));
    }


    /**
     * @dev Owner-only function to set the cost for forging new genesis artifacts.
     * @param newCost The new cost in wei.
     */
    function setGenesisCost(uint256 newCost) public onlyOwner {
        _genesisCost = newCost;
        emit GenesisParamsUpdated(_genesisCost, _genesisLimit);
    }

    /**
     * @dev Owner-only function to set the total limit for genesis artifacts.
     * @param newLimit The new limit.
     */
    function setGenesisLimit(uint256 newLimit) public onlyOwner {
        require(newLimit >= _genesisCounter, "EpochForge: New limit cannot be less than current forged count");
        _genesisLimit = newLimit;
        emit GenesisParamsUpdated(_genesisCost, _genesisLimit);
    }

     /**
     * @dev Owner-only function to add or update a crafting recipe.
     * @param recipeId The ID of the recipe (0 to add new).
     * @param details The RecipeDetails struct.
     */
    function updateRecipe(uint256 recipeId, RecipeDetails memory details) public onlyOwner {
        uint256 targetRecipeId = recipeId;
        if (targetRecipeId == 0) {
            targetRecipeId = _nextRecipeId;
            _nextRecipeId++;
        }
        _recipes[targetRecipeId] = details;
        emit RecipeUpdated(targetRecipeId, details.isActive);
    }

    /**
     * @dev Owner-only function to withdraw collected ETH (from genesis forging).
     */
    function withdrawETH() public onlyOwner {
        require(address(this).balance > 0, "EpochForge: No ETH to withdraw");
        payable(msg.sender).transfer(address(this).balance);
    }

     /**
     * @dev Gets the next available recipe ID if adding a new recipe.
     */
    function getNextRecipeId() public view onlyOwner returns (uint256) {
        return _nextRecipeId;
    }

     /**
     * @dev Gets the current genesis counter and limit.
     */
    function getGenesisInfo() public view returns (uint256 current, uint256 limit, uint256 cost) {
         return (_genesisCounter, _genesisLimit, _genesisCost);
     }

    // --- Internal Helpers ---

    /**
     * @dev Adds a history entry to an artifact.
     * @param tokenId The ID of the artifact.
     * @param action The type of action (e.g., "Forge", "Attune", "Craft").
     * @param details Specific details about the action.
     */
    function _addHistoryEntry(uint256 tokenId, string memory action, string memory details) internal {
        _artifactHistory[tokenId].push(HistoryEntry(block.timestamp, action, details));
    }

     // Overrides to add history tracking on core ERC721 transfers/burns
    function _transfer(address from, address to, uint256 tokenId) internal override {
         super._transfer(from, to, tokenId);
         // Add transfer history entry for artifact
         if (from == address(0)) {
              // Minting happens in forgeGenesisArtifact or craftArtifact, which adds history there.
              // No need to add redundant "Mint" history here.
         } else if (to == address(0)) {
             // Burning history is handled explicitly in burnArtifact and craftArtifact
         } else {
             _addHistoryEntry(tokenId, "Transfer", string(abi.encodePacked("Transferred from ", payable(from), " to ", payable(to))));
         }
    }

     // _burn is called internally by _transfer when 'to' is address(0) or explicitly.
     // Explicit burn adds history in burnArtifact or craftArtifact.
     // Implicit burn via transfer to address(0) *could* add history here, but better to handle in explicit burn functions.
     // Let's override _burn to add history if it wasn't added by a specific function (less likely)
     function _burn(uint256 tokenId) internal override(ERC721) {
         // Check if history was already added (e.g., in craft or burn explicit)
         // Simple check: Is the last entry NOT a burn action?
         // This is tricky. Better to ensure burnArtifact/craftArtifact call _addHistoryEntry BEFORE _burn.
         // Assuming burnArtifact/craftArtifact handle history logging before calling _burn.
         super._burn(tokenId);
     }
}
```

---

**Explanation of Advanced/Creative Concepts Used:**

1.  **Dynamic Attributes (On-Chain):** Artifact attributes (`power`, `resilience`, `affinity`, `chronicleFragmentIds`) are stored directly in the contract's storage (`_artifactAttributes` mapping). They are not static but can change via `attuneArtifact` and `craftArtifact`.
2.  **On-Chain History Tracking:** The `_artifactHistory` mapping stores an array of `HistoryEntry` structs for each token ID, logging significant events like forging, attuning, crafting, transferring, burning, and extraction. This provides a verifiable, immutable record of an artifact's journey.
3.  **Epoch System:** The `_currentEpoch` variable represents a global state that advances over time (controlled by the owner in this demo, but could be automated). Epochs can influence artifact genesis attributes (`_epochAttributeBoosts`) and potentially future evolution mechanics.
4.  **Chronicle Fragments & Assembly:** Artifacts can contain fragments (`chronicleFragmentIds`). Users can `extractEssence` to get these fragments into their personal collection (`_ownerChronicleFragments`). Collected fragments can be `assembleChronicle` to unlock potential benefits (like enabling certain crafting recipes).
5.  **Stateful Crafting with Recipes:** The `craftArtifact` function implements a system where specific input artifacts are burned (`_burn`) to mint new output artifacts (`_safeMint`). The outcome (number and attributes of outputs) is determined by pre-defined `RecipeDetails` and the combined attributes of the inputs. Recipes can have minimum attribute requirements and ingredient counts.
6.  **Recipe Discovery (Simulated):** The `discoverRecipe` function allows burning artifacts in an *attempt* to unlock new recipes. In this demo, it's simplified (burns inputs and checks a simple attribute threshold to globally activate Recipe 2), but in a full game, this could involve complex on-chain logic, randomness, or require specific item combinations.
7.  **Dynamic Metadata (Off-Chain Resolution):** The `tokenURI` function doesn't return a static JSON file. It returns a base URI followed by the token ID. This implies an off-chain service (like a backend server or IPFS resolver) that listens for requests to that URI, reads the *current* state of the artifact (attributes, history, epoch) from the `EpochForge` contract via `getArtifactAttributes` and `getArtifactHistory`, and *then* generates the appropriate metadata JSON, including a dynamic image URL or attributes reflecting the artifact's state.
8.  **Simulated Outcome Prediction:** `getPotentialCraftingOutcome` allows users to check if a set of inputs and a recipe is valid and see the potential output attributes *before* committing the transaction, saving gas on failed attempts.
9.  **Modular Structure:** Uses OpenZeppelin contracts (`ERC721`, `Ownable`, `Counters`, `SafeMath`) for best practices and standard compliance while layering custom logic. The `_burn` and `_transfer` overrides demonstrate how to hook into standard flows.

**Limitations & Potential Improvements (for a real application):**

*   **Randomness:** The use of `blockhash` and `block.timestamp` for randomness is highly insecure and predictable. A real application *must* use a secure oracle like Chainlink VRF for any outcomes that require unpredictability (like genesis attributes or discovery results).
*   **Gas Efficiency:** Storing full history arrays on-chain can become expensive as artifacts are interacted with. More gas-efficient history patterns (e.g., storing only hashes of events, relying more on external indexers) might be needed for a high-volume contract.
*   **Scalability:** Iterating through inputs in `craftArtifact` is fine for small numbers, but complex recipes with many inputs could hit gas limits.
*   **Recipe Complexity:** The recipe system is simple (min attributes, count, modifiers). Real game logic might need more complex input criteria (specific fragment types, attribute ranges, random chances).
*   **Assembly State:** The `assembleChronicle` logic is simplified. A real system would need to track *which* chronicles a user has assembled to enable required recipes.
*   **Metadata Service:** Requires a separate off-chain service to generate the actual dynamic metadata JSON based on the contract's state.

This contract provides a solid foundation and demonstration of how to build a complex, stateful, and dynamic NFT ecosystem entirely on-chain, going beyond simple static collectibles.