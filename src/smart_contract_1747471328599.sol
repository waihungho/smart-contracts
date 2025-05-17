Okay, let's create a smart contract called "DigitalAlchemist" that represents a system where users can collect basic "Elements" (NFTs) and combine them through a crafting process (Alchemy) to create new, unique "Compounds" or "Artifacts" (also NFTs). These Compounds can potentially evolve or have dynamic properties based on their creation recipe or future interactions. We'll manage different item types (Elements, Compounds, Failed Experiments) under a single ERC-721 contract.

This concept incorporates:
1.  **Dynamic NFTs:** Compounds have mutable attributes.
2.  **On-chain Crafting/Procedural Generation:** Outcomes (success/failure, resulting attributes) determined by on-chain logic based on inputs and stored recipes.
3.  **Multiple Item Types:** Managing different *kinds* of digital assets (Elements, Compounds, Failures) within one contract instance.
4.  **Recipe System:** Owner-managed recipes for crafting outcomes.
5.  **Consumable Inputs:** Alchemy consumes input NFTs.
6.  **Distinct Failure State:** A specific NFT type for failed crafting attempts.

We will ensure it has at least 20 functions by including standard ERC-721 functions, ownership/pausability, and a variety of custom functions for the core alchemy logic, item management, and querying.

---

**Contract Name:** DigitalAlchemist

**Concept:** A system where users own basic digital "Elements" (ERC-721 NFTs) and can combine them via "Alchemy" to create new, distinct "Compounds" or "Artifacts" (also ERC-721 NFTs with dynamic attributes). Failed attempts yield "Failed Experiments" NFTs. The contract manages different types of items under a single ERC-721 collection based on defined recipes.

**Outline:**

1.  **Imports:** ERC721, Ownable, Pausable, ReentrancyGuard.
2.  **Enums:** Define item types (Element, Compound, FailedExperiment) and base element types (Fire, Water, Earth, Air, Aether, etc.).
3.  **Structs:** Define data structures for Item attributes (`Attribute`), full Item data (`ItemData`), and Recipes (`Recipe`).
4.  **State Variables:** Mappings for item data (`_itemData`), recipes (`_recipes`), counters for item types (`_mintedCounts`), next token ID, base URI for metadata, recipe counter.
5.  **Events:** Alchemy success/failure, item mutation, recipe added/removed, etc.
6.  **Modifiers:** Standard `onlyOwner`, `whenNotPaused`, `whenPaused`, `nonReentrant`.
7.  **Constructor:** Initialize ERC-721 name, symbol, and owner.
8.  **ERC-721 Standard Functions:** Implement/override standard ERC-721 methods (`balanceOf`, `ownerOf`, `getApproved`, `isApprovedForAll`, `approve`, `setApprovalForAll`, `transferFrom`, `safeTransferFrom`, `supportsInterface`). Override `tokenURI` to point to external metadata service reading on-chain data.
9.  **Internal/Helper Functions:** `_safeMint`, `_burn`, `_beforeTokenTransfer`, `_generateRecipeHash`, `_buildTokenURI`.
10. **Core Alchemy Functions:** `performAlchemy`.
11. **Recipe Management (Owner-only):** `addRecipe`, `removeRecipe`, `getRecipeInputElements`, `getRecipeOutputAttributes`.
12. **Item Management/Query Functions:** `mintElement`, `burnItem` (restricted), `getItemType`, `getItemElementType`, `getItemAttributes`, `getItemCreationRecipeHash`, `getTotalSupply`, `getMintedCountByItemType`.
13. **Dynamic State/Mutation Functions:** `mutateCompound` (restricted).
14. **Access Control & Utility:** `pause`, `unpause`, `setBaseTokenURI`, `getBaseTokenURI`.

**Function Summary:**

*   `constructor(string memory name, string memory symbol, string memory baseTokenURI_)`: Initializes the contract, sets name, symbol, and base metadata URI.
*   `_safeMint(address to, uint256 tokenId)`: Internal function to mint a token safely (ERC721 standard helper).
*   `_burn(uint256 tokenId)`: Internal function to burn a token (ERC721 standard helper).
*   `_beforeTokenTransfer(address from, address to, uint256 tokenId)`: Internal hook called before token transfers (ERC721 standard override). Updates internal state like owner counts and potentially dynamic attributes based on transfer history (future extension).
*   `supportsInterface(bytes4 interfaceId)`: Standard ERC-165 interface check.
*   `balanceOf(address owner) view returns (uint256)`: ERC-721 standard: Returns the number of tokens owned by an address.
*   `ownerOf(uint256 tokenId) view returns (address)`: ERC-721 standard: Returns the owner of a token.
*   `getApproved(uint256 tokenId) view returns (address operator)`: ERC-721 standard: Returns the approved address for a token.
*   `setApprovalForAll(address operator, bool approved)`: ERC-721 standard: Sets approval for all tokens owned by the caller.
*   `isApprovedForAll(address owner, address operator) view returns (bool)`: ERC-721 standard: Checks if an operator is approved for all tokens of an owner.
*   `approve(address operator, uint256 tokenId)`: ERC-721 standard: Approves an address to manage a specific token.
*   `transferFrom(address from, address to, uint256 tokenId)`: ERC-721 standard: Transfers a token.
*   `safeTransferFrom(address from, address to, uint256 tokenId)`: ERC-721 standard: Safely transfers a token.
*   `safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)`: ERC-721 standard: Safely transfers a token with data.
*   `tokenURI(uint256 tokenId) view returns (string memory)`: ERC-721 standard override: Returns the metadata URI for a token, constructed using the base URI and token ID. External services read on-chain data via other view functions.
*   `pause()`: Owner-only: Pauses contract functions that modify state (alchemy, minting, transfers - controlled by `whenNotPaused` modifier).
*   `unpause()`: Owner-only: Unpauses the contract.
*   `setBaseTokenURI(string memory baseTokenURI_)`: Owner-only: Sets the base URI for token metadata.
*   `getBaseTokenURI() view returns (string memory)`: View function: Returns the current base URI.
*   `_generateRecipeHash(uint256[] memory inputTokenIds) pure returns (bytes32)`: Internal pure helper: Generates a unique hash for a set of input token IDs, used to look up recipes. Sorts inputs for consistency.
*   `addRecipe(uint256[] memory inputElementTypes, Attribute[] memory outputAttributes)`: Owner-only: Defines a new valid alchemy recipe, mapping a sorted set of input element types to a set of output attributes for the resulting Compound.
*   `removeRecipe(uint256[] memory inputElementTypes)`: Owner-only: Removes an existing recipe.
*   `getRecipeInputElements(bytes32 recipeHash) view returns (uint256[] memory)`: View function: Returns the required element types for a given recipe hash.
*   `getRecipeOutputAttributes(bytes32 recipeHash) view returns (Attribute[] memory)`: View function: Returns the resulting attributes for a given recipe hash.
*   `mintElement(address to, uint256 elementType)`: Owner-only: Mints a new Element token of a specific type to an address.
*   `performAlchemy(uint256[] memory inputTokenIds)`: Allows a user to attempt alchemy by combining owned Element tokens. Checks inputs, finds recipe, burns inputs, and mints either a Compound (success) or Failed Experiment (failure) based on recipe existence.
*   `burnItem(uint256 tokenId)`: Internal function, potentially exposed with strict access control (not fully implemented here beyond internal use) or kept internal for system use (like alchemy).
*   `getItemType(uint256 tokenId) view returns (ItemType)`: View function: Returns the broad type of an item (Element, Compound, FailedExperiment).
*   `getItemElementType(uint256 tokenId) view returns (uint256)`: View function: If the item is an Element, returns its specific element type ID.
*   `getItemAttributes(uint256 tokenId) view returns (Attribute[] memory)`: View function: If the item is a Compound or Failed Experiment, returns its current attributes.
*   `getItemCreationRecipeHash(uint256 tokenId) view returns (bytes32)`: View function: If the item was created via alchemy, returns the recipe hash used.
*   `getTotalSupply() view returns (uint256)`: View function: Returns the total number of all tokens minted (Elements, Compounds, Failed Experiments).
*   `getMintedCountByItemType(ItemType itemType) view returns (uint256)`: View function: Returns the total count of tokens minted for a specific item type.
*   `mutateCompound(uint256 tokenId, Attribute[] memory newAttributes)`: Owner-only: Allows the owner to change the attributes of a specific Compound token. This is the simplest form of dynamic mutation trigger. (Could be extended to be time-based, event-based, etc.)

---
```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol"; // Not directly used, but represents potential for advanced concepts like signed messages for off-chain triggers/oracles. Included just to hint at advanced possibilities without full implementation.
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol"; // Not directly used, but represents potential for whitelist mints, recipe proofs, etc. Included just to hint.

// Outline:
// 1. Imports
// 2. Enums (ItemType, ElementType)
// 3. Structs (Attribute, ItemData, Recipe)
// 4. State Variables (Mappings, counters, base URI)
// 5. Events
// 6. Modifiers (from imported contracts)
// 7. Constructor
// 8. ERC-721 Standard Implementations/Overrides
// 9. Internal/Helper Functions (_generateRecipeHash, _buildTokenURI, _safeMint, _burn, _beforeTokenTransfer)
// 10. Core Alchemy Function (performAlchemy)
// 11. Recipe Management (Owner-only) (addRecipe, removeRecipe, getRecipeInputElements, getRecipeOutputAttributes)
// 12. Item Management/Query (mintElement, getItemType, getItemElementType, getItemAttributes, getItemCreationRecipeHash, getTotalSupply, getMintedCountByItemType)
// 13. Dynamic State/Mutation (mutateCompound)
// 14. Access Control & Utility (pause, unpause, setBaseTokenURI, getBaseTokenURI)

// Function Summary:
// - constructor: Initializes contract with name, symbol, base URI.
// - supportsInterface: ERC-165 standard.
// - balanceOf: ERC-721 standard: Get owner token count.
// - ownerOf: ERC-721 standard: Get token owner.
// - getApproved: ERC-721 standard: Get approved address for token.
// - setApprovalForAll: ERC-721 standard: Set operator approval for all tokens.
// - isApprovedForAll: ERC-721 standard: Check operator approval status.
// - approve: ERC-721 standard: Approve single token.
// - transferFrom: ERC-721 standard: Transfer token.
// - safeTransferFrom (2 overloads): ERC-721 standard: Safely transfer token.
// - tokenURI: ERC-721 standard override: Get metadata URI for token.
// - pause: Owner-only: Pause state-changing functions.
// - unpause: Owner-only: Unpause state-changing functions.
// - setBaseTokenURI: Owner-only: Set base metadata URI.
// - getBaseTokenURI: Get current base metadata URI.
// - _generateRecipeHash: Internal: Deterministically hash input element types for recipe lookup.
// - addRecipe: Owner-only: Define a new alchemy recipe.
// - removeRecipe: Owner-only: Remove an existing recipe.
// - getRecipeInputElements: View: Get input element types for a recipe hash.
// - getRecipeOutputAttributes: View: Get output attributes for a recipe hash.
// - mintElement: Owner-only: Mint a base Element token.
// - performAlchemy: Public: Combine owned Element tokens to create a Compound or Failed Experiment.
// - burnItem: Internal helper: Burn a token (used by alchemy).
// - getItemType: View: Get the type (Element/Compound/Failed) of a token.
// - getItemElementType: View: Get the specific element type for an Element token.
// - getItemAttributes: View: Get dynamic attributes for Compound/Failed tokens.
// - getItemCreationRecipeHash: View: Get the recipe hash used to create a Compound/Failed token.
// - getTotalSupply: View: Get total number of all tokens minted.
// - getMintedCountByItemType: View: Get count of tokens for a specific type.
// - mutateCompound: Owner-only: Modify attributes of a Compound token (manual dynamic trigger).

contract DigitalAlchemist is ERC721, Ownable, Pausable, ReentrancyGuard {
    using Strings for uint256;

    // 2. Enums
    enum ItemType {
        None,
        Element,
        Compound,
        FailedExperiment
    }

    enum ElementType {
        None, // 0
        Fire, // 1
        Water, // 2
        Earth, // 3
        Air, // 4
        Aether // 5 (Example additional element)
        // Add more element types as needed
    }

    // 3. Structs
    struct Attribute {
        string trait_type;
        string value;
    }

    struct ItemData {
        ItemType itemType;
        uint256 elementType; // Only relevant for ItemType.Element
        Attribute[] attributes; // Relevant for ItemType.Compound and ItemType.FailedExperiment
        bytes32 creationRecipeHash; // Relevant for ItemType.Compound and ItemType.FailedExperiment
        uint256 mintedTimestamp; // Timestamp when the item was minted
        // Potential for more dynamic state:
        // uint256 lastAlchemyAttemptTimestamp; // Could track cooldowns
        // uint256 transferCount; // Could affect mutation
        // uint256 generation; // e.g., 1st gen elements, 2nd gen compounds, etc.
    }

    struct Recipe {
        uint256[] inputElementTypes; // Sorted list of required ElementType IDs
        Attribute[] outputAttributes; // Attributes of the resulting Compound
        bool exists; // Simple flag to check if recipe exists
    }

    // 4. State Variables
    mapping(uint256 => ItemData) private _itemData;
    // Map a hash of sorted input ElementType IDs to a Recipe
    mapping(bytes32 => Recipe) private _recipes;
    // Map recipe hash back to element types for lookup
    mapping(bytes32 => uint265[]) private _recipeInputTypes;
    mapping(ItemType => uint256) private _mintedCounts;
    uint256 private _nextTokenId;
    string private _baseTokenURI;

    // 5. Events
    event ElementMinted(address indexed owner, uint256 indexed tokenId, uint256 elementType);
    event AlchemySuccess(address indexed owner, bytes32 indexed recipeHash, uint256[] inputTokenIds, uint256 indexed outputTokenId);
    event AlchemyFailure(address indexed owner, bytes32 attemptedRecipeHash, uint256[] inputTokenIds, uint256 indexed outputTokenId);
    event CompoundMutated(uint256 indexed tokenId, Attribute[] newAttributes);
    event RecipeAdded(bytes32 indexed recipeHash, uint256[] inputElementTypes);
    event RecipeRemoved(bytes32 indexed recipeHash);

    // 7. Constructor
    constructor(string memory name, string memory symbol, string memory baseTokenURI_)
        ERC721(name, symbol)
        Ownable(msg.sender)
    {
        _baseTokenURI = baseTokenURI_;
        _nextTokenId = 1; // Start token IDs from 1
        // Initialize minted counts
        _mintedCounts[ItemType.Element] = 0;
        _mintedCounts[ItemType.Compound] = 0;
        _mintedCounts[ItemType.FailedExperiment] = 0;
        _mintedCounts[ItemType.None] = 0; // Should remain 0
    }

    // 8. ERC-721 Standard Implementations/Overrides
    // ERC721 takes care of most standard functions like ownerOf, balanceOf, transferFrom, etc.
    // We need to override tokenURI and potentially _beforeTokenTransfer

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        if (!_exists(tokenId)) {
            revert ERC721NonexistentToken(tokenId);
        }
        // External service will read on-chain data (via view functions below) using this ID
        // and combine it with the base URI.
        return _buildTokenURI(tokenId);
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize)
        internal
        override(ERC721)
        virtual
    {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);

        // Example: could track transfer count for dNFT mechanics
        // if (_itemData[tokenId].itemType == ItemType.Compound) {
        //     _itemData[tokenId].transferCount++;
        //     // Trigger mutation based on transferCount here if desired
        // }
    }

    // 9. Internal/Helper Functions
    function _generateRecipeHash(uint256[] memory inputElementTypes) internal pure returns (bytes32) {
        // Sort inputs deterministically before hashing
        uint256[] memory sortedInputs = new uint256[](inputElementTypes.length);
        for (uint i = 0; i < inputElementTypes.length; i++) {
            sortedInputs[i] = inputElementTypes[i];
        }
        // Simple bubble sort - caution with large arrays (gas!)
        // For real production, consider a more efficient sort or limit inputs.
        // Or hash pairs iteratively: hash(hash(input1, input2), input3)...
        // Let's keep it simple for the example, assuming small number of inputs.
        for (uint i = 0; i < sortedInputs.length; i++) {
            for (uint j = 0; j < sortedInputs.length - i - 1; j++) {
                if (sortedInputs[j] > sortedInputs[j+1]) {
                    uint256 temp = sortedInputs[j];
                    sortedInputs[j] = sortedInputs[j+1];
                    sortedInputs[j+1] = temp;
                }
            }
        }

        return keccak256(abi.encodePacked(sortedInputs));
    }

    function _buildTokenURI(uint256 tokenId) internal view returns (string memory) {
         // Base URI + token ID. External service fetches data via view functions.
        return string(abi.encodePacked(_baseTokenURI, tokenId.toString()));
    }

    // Override internal mint/burn to update our item data
    function _safeMint(address to, uint256 tokenId) internal override {
        super._safeMint(to, tokenId);
        // Item data is set right after minting in the mint functions
    }

     function _burn(uint256 tokenId) internal override {
        require(_exists(tokenId), "ERC721: token already burned");
        ItemType typeToBurn = _itemData[tokenId].itemType;
        delete _itemData[tokenId]; // Clean up item data
        if (typeToBurn != ItemType.None) {
            _mintedCounts[typeToBurn]--;
        }
        super._burn(tokenId);
    }


    // 10. Core Alchemy Function
    function performAlchemy(uint256[] memory inputTokenIds)
        public
        nonReentrant
        whenNotPaused
    {
        require(inputTokenIds.length > 0, "Alchemy: No inputs provided");

        address owner = msg.sender;
        uint256[] memory inputElementTypes = new uint256[](inputTokenIds.length);

        // 1. Validate inputs and collect element types
        for (uint i = 0; i < inputTokenIds.length; i++) {
            uint256 tokenId = inputTokenIds[i];
            require(ownerOf(tokenId) == owner, "Alchemy: Caller does not own input token");
            require(_itemData[tokenId].itemType == ItemType.Element, "Alchemy: Input must be an Element");
            inputElementTypes[i] = _itemData[tokenId].elementType;
        }

        // 2. Generate recipe hash based on input types
        bytes32 recipeHash = _generateRecipeHash(inputElementTypes);

        // 3. Look up recipe
        Recipe storage recipe = _recipes[recipeHash];

        uint256 outputTokenId = _nextTokenId++;
        ItemType outputItemType;
        Attribute[] memory outputAttributes;

        // 4. Burn input tokens
        for (uint i = 0; i < inputTokenIds.length; i++) {
            _burn(inputTokenIds[i]);
        }

        // 5. Determine outcome and mint output token
        if (recipe.exists) {
            // Success: Mint a Compound
            outputItemType = ItemType.Compound;
            outputAttributes = recipe.outputAttributes; // Copy attributes

            _safeMint(owner, outputTokenId); // Mints the token via ERC721

            _itemData[outputTokenId] = ItemData({
                itemType: outputItemType,
                elementType: ElementType.None, // Compounds don't have a single element type
                attributes: outputAttributes,
                creationRecipeHash: recipeHash,
                mintedTimestamp: block.timestamp
                // Initialize other potential dynamic state here
            });

            _mintedCounts[outputItemType]++;

            emit AlchemySuccess(owner, recipeHash, inputTokenIds, outputTokenId);

        } else {
            // Failure: Mint a Failed Experiment
            outputItemType = ItemType.FailedExperiment;
            // Define default attributes for failure
            outputAttributes = new Attribute[](1);
            outputAttributes[0] = Attribute("Outcome", "Failed Experiment");
            // Add more failure specific attributes if desired

            _safeMint(owner, outputTokenId); // Mints the token via ERC721

            _itemData[outputTokenId] = ItemData({
                itemType: outputItemType,
                elementType: ElementType.None,
                attributes: outputAttributes,
                creationRecipeHash: recipeHash, // Store attempted recipe hash
                mintedTimestamp: block.timestamp
                // Initialize other potential dynamic state here
            });

            _mintedCounts[outputItemType]++;

            emit AlchemyFailure(owner, recipeHash, inputTokenIds, outputTokenId);
        }
    }


    // 11. Recipe Management (Owner-only)
    function addRecipe(uint256[] memory inputElementTypes, Attribute[] memory outputAttributes)
        public
        onlyOwner
        whenNotPaused // Recipes can only be added/removed when not paused to prevent issues with active alchemy
    {
        require(inputElementTypes.length > 0, "Recipe: Inputs must be provided");
         // Basic validation for element types
        for (uint i = 0; i < inputElementTypes.length; i++) {
             require(inputElementTypes[i] > uint256(ElementType.None), "Recipe: Invalid element type ID");
        }

        bytes32 recipeHash = _generateRecipeHash(inputElementTypes);
        require(!_recipes[recipeHash].exists, "Recipe: Recipe already exists");

        _recipes[recipeHash] = Recipe({
            inputElementTypes: inputElementTypes, // Store the original (sorted) types
            outputAttributes: outputAttributes,
            exists: true
        });
        _recipeInputTypes[recipeHash] = inputElementTypes; // Store mapping back for lookup

        emit RecipeAdded(recipeHash, inputElementTypes);
    }

    function removeRecipe(uint256[] memory inputElementTypes)
        public
        onlyOwner
        whenNotPaused
    {
         require(inputElementTypes.length > 0, "Recipe: Inputs must be provided");
        bytes32 recipeHash = _generateRecipeHash(inputElementTypes);
        require(_recipes[recipeHash].exists, "Recipe: Recipe does not exist");

        delete _recipes[recipeHash];
        delete _recipeInputTypes[recipeHash];

        emit RecipeRemoved(recipeHash);
    }

    function getRecipeInputElements(bytes32 recipeHash) public view returns (uint256[] memory) {
         require(_recipes[recipeHash].exists, "Recipe: Recipe does not exist");
         return _recipeInputTypes[recipeHash];
    }

     function getRecipeOutputAttributes(bytes32 recipeHash) public view returns (Attribute[] memory) {
         require(_recipes[recipeHash].exists, "Recipe: Recipe does not exist");
         // Return a copy of the attributes
         Attribute[] memory attributes = new Attribute[](_recipes[recipeHash].outputAttributes.length);
         for(uint i = 0; i < attributes.length; i++){
             attributes[i] = _recipes[recipeHash].outputAttributes[i];
         }
         return attributes;
    }


    // 12. Item Management/Query Functions
    function mintElement(address to, uint256 elementType)
        public
        onlyOwner
        whenNotPaused
    {
        require(elementType > uint265(ElementType.None), "Mint: Invalid element type");
        uint256 tokenId = _nextTokenId++;
        _safeMint(to, tokenId);

        _itemData[tokenId] = ItemData({
            itemType: ItemType.Element,
            elementType: elementType,
            attributes: new Attribute[](0), // Elements have no mutable attributes initially
            creationRecipeHash: bytes32(0), // Elements are not created via alchemy
            mintedTimestamp: block.timestamp
            // Initialize other potential dynamic state here
        });

        _mintedCounts[ItemType.Element]++;

        emit ElementMinted(to, tokenId, elementType);
    }

    // Internal function to burn an item, used by alchemy
    // Could add a public version with strict checks if needed for specific game mechanics
    // function burnItem(uint256 tokenId) internal { ... } // Already implemented in _burn override


    function getItemType(uint256 tokenId) public view returns (ItemType) {
        require(_exists(tokenId), "Query: Token does not exist");
        return _itemData[tokenId].itemType;
    }

    function getItemElementType(uint256 tokenId) public view returns (uint256) {
        require(_exists(tokenId), "Query: Token does not exist");
        require(_itemData[tokenId].itemType == ItemType.Element, "Query: Token is not an Element");
        return _itemData[tokenId].elementType;
    }

    function getItemAttributes(uint256 tokenId) public view returns (Attribute[] memory) {
        require(_exists(tokenId), "Query: Token does not exist");
        require(_itemData[tokenId].itemType == ItemType.Compound || _itemData[tokenId].itemType == ItemType.FailedExperiment, "Query: Token has no attributes");
        // Return a copy of the attributes
         Attribute[] memory attributes = new Attribute[](_itemData[tokenId].attributes.length);
         for(uint i = 0; i < attributes.length; i++){
             attributes[i] = _itemData[tokenId].attributes[i];
         }
         return attributes;
    }

    function getItemCreationRecipeHash(uint256 tokenId) public view returns (bytes32) {
        require(_exists(tokenId), "Query: Token does not exist");
        require(_itemData[tokenId].itemType == ItemType.Compound || _itemData[tokenId].itemType == ItemType.FailedExperiment, "Query: Token not created by alchemy");
        return _itemData[tokenId].creationRecipeHash;
    }

    function getTotalSupply() public view returns (uint256) {
        // _nextTokenId is the ID for the *next* token, so total minted is _nextTokenId - 1
        // However, _burn decreases the ERC721 count, so using the base ERC721 count is more accurate for *existing* tokens.
        // If you need *total ever minted* including burned, use _nextTokenId - 1 (if starting from 1)
        // Let's return current supply as ERC721.totalSupply() is not standard/reliable. Summing our counts:
        return _mintedCounts[ItemType.Element] + _mintedCounts[ItemType.Compound] + _mintedCounts[ItemType.FailedExperiment];
    }

    function getMintedCountByItemType(ItemType itemType) public view returns (uint256) {
         require(itemType != ItemType.None, "Query: Invalid item type");
         return _mintedCounts[itemType];
    }


    // 13. Dynamic State/Mutation Functions
    function mutateCompound(uint256 tokenId, Attribute[] memory newAttributes)
        public
        onlyOwner // Simple trigger, could be expanded
        whenNotPaused // Mutation logic should respect pause state
    {
        require(_exists(tokenId), "Mutate: Token does not exist");
        require(_itemData[tokenId].itemType == ItemType.Compound, "Mutate: Token is not a Compound");

        _itemData[tokenId].attributes = newAttributes; // Overwrite attributes

        // Potentially add logic here to update based on old vs new attributes
        // Example: If 'Corrupted' attribute is added, change visual properties
        // This logic happens off-chain based on the updated state.

        emit CompoundMutated(tokenId, newAttributes);
    }


    // 14. Access Control & Utility
    function setBaseTokenURI(string memory baseTokenURI_) public onlyOwner {
        _baseTokenURI = baseTokenURI_;
    }

    function getBaseTokenURI() public view returns (string memory) {
        return _baseTokenURI;
    }

    // --- Potential Future Functions (Not included in the >20 count for this example) ---
    // - addCatalystType(uint256 catalystId, Attribute[] memory effects): Define types of catalysts.
    // - performAlchemy(uint256[] memory inputTokenIds, uint256 optionalCatalystId): Alchemy with catalysts.
    // - disassembleCompound(uint256 compoundTokenId): Break a compound back into (some) elements.
    // - triggerTimeBasedMutation(uint256 tokenId): Allows anyone to trigger mutation if time conditions met (gas).
    // - triggerInteractionMutation(uint256 tokenId, address otherContract): Mutation based on interaction.
    // - batchMintElements(address[] memory to, uint256[] memory elementTypes): Mint multiple elements.
    // - updateItemAttribute(uint256 tokenId, string memory traitType, string memory newValue): Change specific attribute.
    // - getItemAttribute(uint256 tokenId, string memory traitType) view returns (string memory value): Get specific attribute value.
    // - getOwnedItemsByType(address owner, ItemType itemType) view returns (uint256[] memory): Get all tokens of a specific type owned by an address.
    // - getRecipeByHash(bytes32 recipeHash) view returns (uint256[] memory inputElementTypes, Attribute[] memory outputAttributes): Get full recipe data.
    // - getAllRecipeHashes() view returns (bytes32[] memory): Get list of all known recipe hashes.
    // - delegateAlchemy(address delegate, bool enabled): Allow another address to perform alchemy on your behalf.
}
```