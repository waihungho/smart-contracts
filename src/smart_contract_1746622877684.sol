Okay, let's create a smart contract that implements a "Decentralized Art Layering Protocol". This contract will manage base ERC721 tokens that users own, and allow them to attach "layers" to these tokens. These layers are also managed within the contract and can have unique properties, supplies, and costs. The final NFT art will be a composition of the base and its attached layers, reflected dynamically in the token URI.

This combines ERC721, on-chain data management for layers, dynamic metadata, unique asset types (layers within the NFT), and protocol management features.

**Concept:** Decentralized Art Layering Protocol (DALP)
*   Users mint a base NFT.
*   Admins create different layer "templates" (e.g., backgrounds, hats, effects) with specific costs and limited supplies.
*   Users can purchase and attach instances of these layer templates to their owned base NFTs.
*   Layers are represented as structured data attached to the base token ID.
*   The `tokenURI` function dynamically generates metadata based on the base token and all its attached layers, pointing to an off-chain service that renders the combined art.
*   Users can remove layers, transfer layer instances between their own tokens, and even reorder layers.

---

**Outline:**

1.  **License and Pragma**
2.  **Imports** (ERC721Enumerable, Ownable, Strings, SafeMath - though less needed in modern Solidity)
3.  **Errors** (Custom errors for clarity)
4.  **Enums** (LayerType)
5.  **Structs** (LayerTemplate, LayerInstance)
6.  **State Variables**
    *   Contract Owner, Paused state
    *   Token counters (base, layer template, layer instance)
    *   Mappings for base token data (handled by ERC721)
    *   Mappings for layer templates
    *   Mappings for layer instances
    *   Mapping linking base token ID to its attached layer *instance* IDs (ordered)
    *   Base token URI prefix
7.  **Events**
    *   Protocol events (Paused, Unpaused, FundsWithdrawn)
    *   NFT events (Minted - specific for base)
    *   Layer Template events (Created, Updated, PriceUpdated, SupplyUpdated)
    *   Layer Instance events (Added, Removed, Transferred, Reordered)
8.  **Constructor**
9.  **Modifiers** (Ownable, Paused)
10. **ERC721 Standard Functions (Overridden)**
    *   `tokenURI` (Dynamic metadata generation)
11. **Admin/Protocol Management Functions (Owned)**
    *   `pause`
    *   `unpause`
    *   `withdrawFunds`
    *   `createLayerTemplate`
    *   `updateLayerTemplate` (Metadata URI/Type only)
    *   `setLayerTemplatePrice`
    *   `setLayerTemplateMaxSupply`
    *   `setBaseTokenURI`
    *   `transferOwnership` (from Ownable)
12. **User/Core Interaction Functions**
    *   `mintBaseToken`
    *   `addLayerToToken`
    *   `removeLayerFromToken`
    *   `transferLayerInstance` (Transfer a layer instance between *owned* tokens)
    *   `reorderLayers`
    *   `burnLayerInstance`
    *   `burnBaseTokenAndLayers`
13. **View Functions (Read Only)**
    *   `getBaseTokenCount` (Alias for totalSupply)
    *   `getLayerTemplateCount`
    *   `getLayerInstanceCount`
    *   `getLayerTemplateInfo`
    *   `getLayerInstanceInfo`
    *   `getLayersOfToken` (Return layer *instance* IDs in order)
    *   `getAvailableLayerTemplates` (List all template IDs)
    *   `isLayerTemplateAvailable` (Check supply)
    *   `composePreviewURI` (Simulate tokenURI for a custom layer combo - advanced)
    *   `getBaseTokenURI`
    *   `isPaused`
14. **Internal Helper Functions**
    *   `_generateTokenURI`
    *   `_addLayerInstanceToToken` (Internal logic for adding)
    *   `_removeLayerInstanceFromToken` (Internal logic for removing)
    *   `_existsLayerTemplate`
    *   `_existsLayerInstance`

---

**Function Summary (27+ Functions):**

1.  `constructor()`: Initializes the contract with base URI.
2.  `pause()`: Admin function to pause core actions.
3.  `unpause()`: Admin function to unpause core actions.
4.  `withdrawFunds()`: Admin function to withdraw collected funds.
5.  `createLayerTemplate()`: Admin function to define a new type of layer.
6.  `updateLayerTemplate()`: Admin function to update layer template metadata/type.
7.  `setLayerTemplatePrice()`: Admin function to set/update a layer template's cost.
8.  `setLayerTemplateMaxSupply()`: Admin function to set/update a layer template's max mintable instances.
9.  `setBaseTokenURI()`: Admin function to set the base URI for tokens before layers.
10. `transferOwnership()`: Admin function to transfer contract ownership (from Ownable).
11. `mintBaseToken()`: Allows anyone (unless paused) to mint a new base NFT.
12. `addLayerToToken()`: Allows a token owner to purchase and attach a layer instance to their token.
13. `removeLayerFromToken()`: Allows a token owner to remove a specific layer instance from their token.
14. `transferLayerInstance()`: Allows a token owner to move a layer instance from one of their tokens to another of their tokens.
15. `reorderLayers()`: Allows a token owner to change the rendering order of attached layers.
16. `burnLayerInstance()`: Allows a token owner to burn a specific layer instance attached to their token.
17. `burnBaseTokenAndLayers()`: Allows a token owner to burn their base token and all attached layers.
18. `getBaseTokenCount()`: Returns the total number of base tokens minted (wrapper for `totalSupply`).
19. `getLayerTemplateCount()`: Returns the total number of unique layer templates.
20. `getLayerInstanceCount()`: Returns the total number of layer instances ever created.
21. `getLayerTemplateInfo()`: Returns details about a specific layer template.
22. `getLayerInstanceInfo()`: Returns details about a specific layer instance.
23. `getLayersOfToken()`: Returns the ordered list of layer *instance* IDs attached to a base token.
24. `getAvailableLayerTemplates()`: Returns a list of all existing layer template IDs.
25. `isLayerTemplateAvailable()`: Checks if a specific layer template has remaining supply to be added.
26. `composePreviewURI()`: Generates a *preview* tokenURI for a hypothetical combination of layers on a base token.
27. `getBaseTokenURI()`: Returns the current base URI prefix.
28. `isPaused()`: Returns the current paused state.
    *   *Inherited ERC721/Enumerable functions:* `balanceOf`, `ownerOf`, `approve`, `getApproved`, `setApprovalForAll`, `isApprovedForAll`, `transferFrom`, `safeTransferFrom` (x2), `tokenURI` (override), `tokenOfOwnerByIndex`, `tokenByIndex`. (Adds ~10 more functions).

This structure and function list clearly exceed the 20-function requirement and cover the advanced, creative, and trendy concepts discussed.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Context.sol"; // Added for _msgSender()

// --- Outline ---
// 1. License and Pragma
// 2. Imports
// 3. Errors (Custom errors for clarity)
// 4. Enums (LayerType)
// 5. Structs (LayerTemplate, LayerInstance)
// 6. State Variables
// 7. Events
// 8. Constructor
// 9. Modifiers
// 10. ERC721 Standard Functions (Overridden)
// 11. Admin/Protocol Management Functions (Owned)
// 12. User/Core Interaction Functions
// 13. View Functions (Read Only)
// 14. Internal Helper Functions

// --- Function Summary ---
// - constructor(): Initializes contract, sets base URI.
// - pause(): Admin: Pauses core user interactions.
// - unpause(): Admin: Unpauses core user interactions.
// - withdrawFunds(): Admin: Collects Ether sent for layers.
// - createLayerTemplate(): Admin: Defines a new type of layer with properties.
// - updateLayerTemplate(): Admin: Updates layer template metadata/type.
// - setLayerTemplatePrice(): Admin: Sets/updates layer template cost.
// - setLayerTemplateMaxSupply(): Admin: Sets/updates layer template max supply.
// - setBaseTokenURI(): Admin: Sets the base URI for tokens before layers.
// - transferOwnership(): Admin: Transfers contract ownership (from Ownable).
// - mintBaseToken(): User: Mints a new base NFT.
// - addLayerToToken(): User: Purchases and attaches a layer instance to their token.
// - removeLayerFromToken(): User: Removes a specific layer instance from their token.
// - transferLayerInstance(): User: Moves a layer instance between their own tokens.
// - reorderLayers(): User: Changes the rendering order of layers on their token.
// - burnLayerInstance(): User: Burns a specific layer instance from their token.
// - burnBaseTokenAndLayers(): User: Burns their base token and all attached layers.
// - getBaseTokenCount(): View: Total base tokens minted (totalSupply).
// - getLayerTemplateCount(): View: Total unique layer templates defined.
// - getLayerInstanceCount(): View: Total layer instances ever created.
// - getLayerTemplateInfo(): View: Details of a specific layer template.
// - getLayerInstanceInfo(): View: Details of a specific layer instance.
// - getLayersOfToken(): View: Ordered list of layer instance IDs on a token.
// - getAvailableLayerTemplates(): View: List of all layer template IDs.
// - isLayerTemplateAvailable(): View: Checks if a layer template has supply remaining.
// - composePreviewURI(): View: Generates a hypothetical tokenURI for previewing layers.
// - getBaseTokenURI(): View: Returns the current base URI prefix.
// - isPaused(): View: Returns current paused state.
// - tokenURI(uint256 tokenId): Overridden ERC721: Dynamically generates metadata URI.
// - Inherited (ERC721Enumerable + Ownable): balanceOf, ownerOf, approve, getApproved, setApprovalForAll, isApprovedForAll, transferFrom, safeTransferFrom (x2), totalSupply, tokenOfOwnerByIndex, tokenByIndex.

contract DecentralizedArtLayeringProtocol is ERC721Enumerable, Ownable {
    using Strings for uint256;
    using SafeMath for uint256; // Still useful for array manipulation

    // --- Errors ---
    error Error_ProtocolPaused();
    error Error_Unauthorized();
    error Error_TokenNotFound();
    error Error_NotTokenOwnerOrApproved();
    error Error_InvalidLayerTemplateId();
    error Error_LayerTemplateMaxSupplyReached();
    error Error_InsufficientPayment();
    error Error_InvalidLayerInstanceId();
    error Error_LayerInstanceNotAttachedToToken();
    error Error_LayerOrderInvalid();
    error Error_CannotTransferToDifferentOwner();
    error Error_CannotTransferLayerToItself();
    error Error_CannotReorderEmptyLayers();
    error Error_ReorderArrayMismatch();

    // --- Enums ---
    enum LayerType { Unknown, Background, Base, Accessory, Clothing, Effect, Frame }

    // --- Structs ---
    struct LayerTemplate {
        uint256 id;
        string name;
        string metadataURI; // Base URI for this layer type
        LayerType layerType;
        uint256 price; // Price in Ether
        uint256 maxSupply; // Max instances that can be created
        uint256 currentSupply; // Instances already created
        bool exists; // Helper to check if struct is initialized
    }

    struct LayerInstance {
        uint256 id;
        uint256 templateId;
        uint256 attachedTokenId;
        uint64 attachmentTimestamp;
        bool exists; // Helper to check if struct is initialized
    }

    // --- State Variables ---
    bool private _paused;

    uint256 private _nextTokenId; // For base tokens
    uint256 private _nextLayerTemplateId;
    uint256 private _nextLayerInstanceId;

    // Mapping from LayerTemplate ID to LayerTemplate struct
    mapping(uint256 => LayerTemplate) private _layerTemplates;
    // Mapping from LayerInstance ID to LayerInstance struct
    mapping(uint256 => LayerInstance) private _layerInstances;
    // Mapping from Base Token ID to an ordered list of LayerInstance IDs
    mapping(uint256 => uint256[]) private _baseTokenLayers;

    // Base URI prefix for token metadata endpoint
    // Example: "https://api.mydapp.com/metadata/" -> final URI: "https://api.mydapp.com/metadata/123"
    string private _baseTokenURI;

    // --- Events ---
    event ProtocolPaused(address account);
    event ProtocolUnpaused(address account);
    event FundsWithdrawn(address indexed owner, uint256 amount);

    event BaseTokenMinted(address indexed owner, uint256 indexed tokenId);

    event LayerTemplateCreated(
        uint256 indexed templateId,
        string name,
        LayerType layerType,
        uint256 price,
        uint256 maxSupply
    );
    event LayerTemplateUpdated(uint256 indexed templateId, string metadataURI, LayerType layerType);
    event LayerTemplatePriceUpdated(uint256 indexed templateId, uint256 newPrice);
    event LayerTemplateSupplyUpdated(uint256 indexed templateId, uint256 newMaxSupply);

    event LayerInstanceAdded(uint256 indexed tokenId, uint256 indexed layerInstanceId, uint256 indexed templateId);
    event LayerInstanceRemoved(uint256 indexed tokenId, uint256 indexed layerInstanceId);
    event LayerInstanceTransferred(uint256 indexed fromTokenId, uint256 indexed toTokenId, uint256 indexed layerInstanceId);
    event LayerOrderReordered(uint256 indexed tokenId);
    event LayerInstanceBurned(uint256 indexed layerInstanceId);
    event BaseTokenAndLayersBurned(uint256 indexed tokenId);


    // --- Constructor ---
    constructor(string memory name, string memory symbol, string memory baseUri)
        ERC721(name, symbol)
        Ownable(msg.sender)
    {
        _baseTokenURI = baseUri;
        _nextTokenId = 0;
        _nextLayerTemplateId = 1; // Start template IDs from 1
        _nextLayerInstanceId = 1; // Start instance IDs from 1
        _paused = false;
    }

    // --- Modifiers ---
    modifier whenNotPaused() {
        if (_paused) revert Error_ProtocolPaused();
        _;
    }

    // --- ERC721 Standard Functions (Overridden) ---

    /// @dev See {IERC721Metadata-tokenURI}.
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        // Check if token exists
        if (!_exists(tokenId)) {
             revert Error_TokenNotFound();
        }
        // Delegate to internal helper for dynamic generation
        return _generateTokenURI(tokenId);
    }

    // --- Admin/Protocol Management Functions (Owned) ---

    /// @dev Pauses all non-admin functions. Only callable by owner.
    function pause() public onlyOwner {
        _paused = true;
        emit ProtocolPaused(msg.sender);
    }

    /// @dev Unpauses the protocol. Only callable by owner.
    function unpause() public onlyOwner {
        _paused = false;
        emit ProtocolUnpaused(msg.sender);
    }

    /// @dev Withdraws all accumulated Ether from layer purchases to the owner.
    /// Only callable by owner.
    function withdrawFunds() public onlyOwner {
        uint256 balance = address(this).balance;
        if (balance > 0) {
            (bool success, ) = payable(owner()).call{value: balance}("");
            require(success, "Transfer failed.");
            emit FundsWithdrawn(owner(), balance);
        }
    }

    /// @dev Creates a new layer template that users can add to their tokens.
    /// Only callable by owner.
    /// @param name The name of the layer template.
    /// @param metadataURI The URI pointing to the metadata/asset for this layer type.
    /// @param layerType The type of layer (e.g., Background, Accessory).
    /// @param price The price in Ether to add an instance of this layer.
    /// @param maxSupply The maximum number of instances that can be created from this template.
    function createLayerTemplate(
        string memory name,
        string memory metadataURI,
        LayerType layerType,
        uint256 price,
        uint256 maxSupply
    ) public onlyOwner {
        uint256 templateId = _nextLayerTemplateId++;
        _layerTemplates[templateId] = LayerTemplate({
            id: templateId,
            name: name,
            metadataURI: metadataURI,
            layerType: layerType,
            price: price,
            maxSupply: maxSupply,
            currentSupply: 0,
            exists: true
        });

        emit LayerTemplateCreated(templateId, name, layerType, price, maxSupply);
    }

    /// @dev Updates the metadata URI and layer type of an existing layer template.
    /// Only callable by owner.
    /// @param templateId The ID of the layer template to update.
    /// @param metadataURI The new URI for the layer template.
    /// @param layerType The new type for the layer.
    function updateLayerTemplate(
        uint256 templateId,
        string memory metadataURI,
        LayerType layerType
    ) public onlyOwner {
        if (!_existsLayerTemplate(templateId)) {
            revert Error_InvalidLayerTemplateId();
        }
        _layerTemplates[templateId].metadataURI = metadataURI;
        _layerTemplates[templateId].layerType = layerType;

        emit LayerTemplateUpdated(templateId, metadataURI, layerType);
    }

    /// @dev Sets the price for adding an instance of an existing layer template.
    /// Only callable by owner.
    /// @param templateId The ID of the layer template.
    /// @param newPrice The new price in Ether.
    function setLayerTemplatePrice(uint256 templateId, uint256 newPrice) public onlyOwner {
        if (!_existsLayerTemplate(templateId)) {
            revert Error_InvalidLayerTemplateId();
        }
        _layerTemplates[templateId].price = newPrice;
        emit LayerTemplatePriceUpdated(templateId, newPrice);
    }

    /// @dev Sets the maximum supply for adding instances of an existing layer template.
    /// Only callable by owner. Can increase or decrease supply, but not below current supply.
    /// @param templateId The ID of the layer template.
    /// @param newMaxSupply The new maximum supply.
    function setLayerTemplateMaxSupply(uint256 templateId, uint256 newMaxSupply) public onlyOwner {
        LayerTemplate storage template = _layerTemplates[templateId];
        if (!template.exists) {
            revert Error_InvalidLayerTemplateId();
        }
        if (newMaxSupply < template.currentSupply) {
            // Note: This prevents reducing supply below already minted instances.
            // Alternative could be to allow, but prevent *new* mints until below newMaxSupply.
             revert Error_LayerTemplateMaxSupplyReached(); // Use this error for simplicity
        }
        template.maxSupply = newMaxSupply;
        emit LayerTemplateSupplyUpdated(templateId, newMaxSupply);
    }

    /// @dev Sets the base URI prefix for token metadata.
    /// Only callable by owner.
    /// @param baseUri The new base URI prefix.
    function setBaseTokenURI(string memory baseUri) public onlyOwner {
        _baseTokenURI = baseUri;
    }

    // transferOwnership is inherited from Ownable

    // --- User/Core Interaction Functions ---

    /// @dev Mints a new base token to the caller.
    /// @param to The address to mint the token to.
    function mintBaseToken(address to) public whenNotPaused {
        uint256 newTokenId = _nextTokenId++;
        _safeMint(to, newTokenId);
        emit BaseTokenMinted(to, newTokenId);
    }

    /// @dev Adds an instance of a layer template to a base token.
    /// Requires payment matching the layer template price.
    /// Caller must be the token owner or approved operator.
    /// @param tokenId The ID of the base token to add the layer to.
    /// @param templateId The ID of the layer template to add.
    function addLayerToToken(uint256 tokenId, uint256 templateId) public payable whenNotPaused {
        // Check ownership/approval
        if (_ownerOf(tokenId) != _msgSender() && !isApprovedForAll(_ownerOf(tokenId), _msgSender())) {
            revert Error_NotTokenOwnerOrApproved();
        }
        // Check token existence
        if (!_exists(tokenId)) {
             revert Error_TokenNotFound();
        }

        LayerTemplate storage template = _layerTemplates[templateId];
        if (!template.exists) {
            revert Error_InvalidLayerTemplateId();
        }
        if (template.currentSupply >= template.maxSupply && template.maxSupply != 0) { // maxSupply 0 means unlimited
            revert Error_LayerTemplateMaxSupplyReached();
        }
        if (msg.value < template.price) {
            revert Error_InsufficientPayment();
        }

        // Create new layer instance
        uint256 instanceId = _nextLayerInstanceId++;
        _layerInstances[instanceId] = LayerInstance({
            id: instanceId,
            templateId: templateId,
            attachedTokenId: tokenId,
            attachmentTimestamp: uint64(block.timestamp),
            exists: true
        });

        // Add instance ID to the token's layer list
        _baseTokenLayers[tokenId].push(instanceId);

        // Update template supply
        template.currentSupply++;

        // Refund any excess payment (if msg.value > price)
        if (msg.value > template.price) {
            (bool success, ) = payable(_msgSender()).call{value: msg.value - template.price}("");
            require(success, "Refund failed.");
        }

        emit LayerInstanceAdded(tokenId, instanceId, templateId);
        // Note: No need to emit Transfer event for layers, they are not separate ERC721s.
        // This is a state change within the base token's metadata.
        // We could potentially emit an `MetadataUpdate(tokenId)` event if ERC721 contract supported it.
        // For now, consumers should re-fetch tokenURI on LayerInstanceAdded/Removed/Reordered.
    }

     /// @dev Removes a layer instance from a base token.
    /// Caller must be the token owner or approved operator.
    /// @param tokenId The ID of the base token.
    /// @param layerInstanceId The ID of the specific layer instance to remove.
    function removeLayerFromToken(uint256 tokenId, uint256 layerInstanceId) public whenNotPaused {
        // Check ownership/approval
        if (_ownerOf(tokenId) != _msgSender() && !isApprovedForAll(_ownerOf(tokenId), _msgSender())) {
            revert Error_NotTokenOwnerOrApproved();
        }
        // Check token existence
         if (!_exists(tokenId)) {
             revert Error_TokenNotFound();
        }

        // Check layer instance existence and attachment
        LayerInstance storage instance = _layerInstances[layerInstanceId];
        if (!instance.exists) {
            revert Error_InvalidLayerInstanceId();
        }
        if (instance.attachedTokenId != tokenId) {
            revert Error_LayerInstanceNotAttachedToToken();
        }

        // Remove the instance ID from the token's layer list
        uint256[] storage layers = _baseTokenLayers[tokenId];
        bool found = false;
        for (uint i = 0; i < layers.length; i++) {
            if (layers[i] == layerInstanceId) {
                // Swap and pop to remove efficiently
                layers[i] = layers[layers.length - 1];
                layers.pop();
                found = true;
                break;
            }
        }
        // This should always be true if attachedTokenId check passed, but double-checking
        if (!found) {
             revert Error_LayerInstanceNotAttachedToToken(); // Should not happen
        }

        // Decrement template supply (optional, depending on protocol design - let's decrement)
        // Could also choose to NOT decrement if removal doesn't free up a "slot"
        // Let's decrement, assuming removal makes a "slot" available again for a new instance
        LayerTemplate storage template = _layerTemplates[instance.templateId];
        if (template.currentSupply > 0) {
             template.currentSupply--;
        }

        // "Burn" the layer instance data
        delete _layerInstances[layerInstanceId];

        emit LayerInstanceRemoved(tokenId, layerInstanceId);
    }

    /// @dev Transfers a layer instance from one base token (owned by caller) to another base token (owned by caller).
    /// Caller must be the owner of both tokens.
    /// @param fromTokenId The ID of the token to remove the layer from.
    /// @param layerInstanceId The ID of the specific layer instance to transfer.
    /// @param toTokenId The ID of the token to add the layer to.
    function transferLayerInstance(uint256 fromTokenId, uint256 layerInstanceId, uint256 toTokenId) public whenNotPaused {
        address sender = _msgSender();
        // Check ownership of both tokens
        if (_ownerOf(fromTokenId) != sender || _ownerOf(toTokenId) != sender) {
            revert Error_NotTokenOwnerOrApproved(); // Using this error as it implies ownership failure
        }
         // Check token existence
         if (!_exists(fromTokenId)) {
             revert Error_TokenNotFound(); // fromTokenId
         }
          if (!_exists(toTokenId)) {
             revert Error_TokenNotFound(); // toTokenId
         }
        // Cannot transfer a layer to the same token it's already on (effectively)
        if (fromTokenId == toTokenId) {
             revert Error_CannotTransferLayerToItself();
        }

        // Check layer instance existence and attachment to fromToken
        LayerInstance storage instance = _layerInstances[layerInstanceId];
        if (!instance.exists) {
            revert Error_InvalidLayerInstanceId();
        }
        if (instance.attachedTokenId != fromTokenId) {
            revert Error_LayerInstanceNotAttachedToToken();
        }

        // --- Perform the transfer logic ---
        // 1. Remove from fromToken's layer list
        uint256[] storage fromLayers = _baseTokenLayers[fromTokenId];
        bool found = false;
        for (uint i = 0; i < fromLayers.length; i++) {
            if (fromLayers[i] == layerInstanceId) {
                fromLayers[i] = fromLayers[fromLayers.length - 1];
                fromLayers.pop();
                found = true;
                break;
            }
        }
         if (!found) {
             revert Error_LayerInstanceNotAttachedToToken(); // Should not happen
         }

        // 2. Add to toToken's layer list
        _baseTokenLayers[toTokenId].push(layerInstanceId);

        // 3. Update the layer instance's attachedTokenId
        instance.attachedTokenId = toTokenId;
        instance.attachmentTimestamp = uint64(block.timestamp); // Update timestamp on transfer? Or keep original? Let's update.

        // Note: Template supply is NOT affected by transferring an instance.

        emit LayerInstanceTransferred(fromTokenId, toTokenId, layerInstanceId);
         // Emit MetadataUpdate events for both tokens? Or rely on consumers watching events?
         // Relying on consumers watching LayerInstanceTransferred is standard.
    }

    /// @dev Reorders the attached layers on a base token.
    /// Caller must be the token owner or approved operator.
    /// @param tokenId The ID of the base token.
    /// @param newOrderLayerInstanceIds An array of layer instance IDs in the desired new order.
    function reorderLayers(uint256 tokenId, uint256[] memory newOrderLayerInstanceIds) public whenNotPaused {
        // Check ownership/approval
        if (_ownerOf(tokenId) != _msgSender() && !isApprovedForAll(_ownerOf(tokenId), _msgSender())) {
            revert Error_NotTokenOwnerOrApproved();
        }
         // Check token existence
         if (!_exists(tokenId)) {
             revert Error_TokenNotFound();
        }

        uint256[] storage currentLayers = _baseTokenLayers[tokenId];

        if (currentLayers.length == 0) {
             revert Error_CannotReorderEmptyLayers();
        }
        if (currentLayers.length != newOrderLayerInstanceIds.length) {
             revert Error_ReorderArrayMismatch(); // New order length must match current count
        }

        // Check if the newOrderLayerInstanceIds array contains exactly the same instances
        // as the current layers for this token, just potentially in a different order.
        // Using a frequency map or sorting could work, but for simplicity, we'll iterate and check existence.
        // Create a temporary mapping of existing layer instance IDs for quick lookup.
        mapping(uint255 => bool) tempExisting; // Use 255 to avoid potential collision with max uint256
         for(uint i=0; i < currentLayers.length; i++) {
             tempExisting[currentLayers[i]] = true;
         }

        for (uint i = 0; i < newOrderLayerInstanceIds.length; i++) {
            uint256 instanceId = newOrderLayerInstanceIds[i];
            // Check if instance exists and is attached to this token
            if (!_layerInstances[instanceId].exists || _layerInstances[instanceId].attachedTokenId != tokenId) {
                revert Error_LayerOrderInvalid(); // Contains invalid or unattached instance ID
            }
            // Mark as seen in the new order array to detect duplicates or missing
            if (!tempExisting[instanceId]) {
                 revert Error_LayerOrderInvalid(); // Contains an instance not originally attached
            }
            delete tempExisting[instanceId]; // Remove it from temp map as we've seen it
        }

        // After iterating, the tempExisting map should be empty if all original layers were present
        // in the newOrderLayerInstanceIds array.
        // This check ensures no layers were missed or duplicated in the new order array.
         uint counter = 0;
         assembly {
             let ptr := sload(tempExisting.slot) // Get pointer to the mapping's data
             // Iterate until the pointer is 0 (end of mapping entries)
             for {} iszero(iszero(ptr)) {} {
                 ptr := sload(ptr) // Move to next entry
                 counter := add(counter, 1) // Increment counter
             }
         }
         if (counter > 0) {
             revert Error_ReorderArrayMismatch(); // New order is missing some original layers
         }


        // Update the layer list with the new order
        _baseTokenLayers[tokenId] = newOrderLayerInstanceIds;

        emit LayerOrderReordered(tokenId);
    }

    /// @dev Allows a token owner to burn a specific layer instance attached to their token.
    /// This permanently removes the layer instance and it cannot be recovered or transferred.
    /// Caller must be the token owner or approved operator.
    /// @param tokenId The ID of the base token.
    /// @param layerInstanceId The ID of the specific layer instance to burn.
    function burnLayerInstance(uint256 tokenId, uint256 layerInstanceId) public whenNotPaused {
         // Check ownership/approval
        if (_ownerOf(tokenId) != _msgSender() && !isApprovedForAll(_ownerOf(tokenId), _msgSender())) {
            revert Error_NotTokenOwnerOrApproved();
        }
         // Check token existence
         if (!_exists(tokenId)) {
             revert Error_TokenNotFound();
        }

        // Check layer instance existence and attachment
        LayerInstance storage instance = _layerInstances[layerInstanceId];
        if (!instance.exists) {
            revert Error_InvalidLayerInstanceId();
        }
        if (instance.attachedTokenId != tokenId) {
            revert Error_LayerInstanceNotAttachedToToken();
        }

        // Remove from the token's layer list
        uint256[] storage layers = _baseTokenLayers[tokenId];
        bool found = false;
         for (uint i = 0; i < layers.length; i++) {
            if (layers[i] == layerInstanceId) {
                // Swap and pop to remove efficiently
                layers[i] = layers[layers.length - 1];
                layers.pop();
                found = true;
                break;
            }
        }
        if (!found) {
             revert Error_LayerInstanceNotAttachedToToken(); // Should not happen
         }


        // Decrement template supply (as a burned instance is gone forever)
        LayerTemplate storage template = _layerTemplates[instance.templateId];
        if (template.currentSupply > 0) {
             template.currentSupply--;
        }

        // Delete the layer instance data
        delete _layerInstances[layerInstanceId];

        emit LayerInstanceBurned(layerInstanceId);
        emit LayerInstanceRemoved(tokenId, layerInstanceId); // Also emit removed event for consistency
    }

    /// @dev Allows a token owner to burn their base token and all attached layers.
    /// Caller must be the token owner or approved operator.
    /// @param tokenId The ID of the base token to burn.
    function burnBaseTokenAndLayers(uint256 tokenId) public whenNotPaused {
         // Check ownership/approval
        if (_ownerOf(tokenId) != _msgSender() && !isApprovedForAll(_ownerOf(tokenId), _msgSender())) {
            revert Error_NotTokenOwnerOrApproved();
        }
         // Check token existence
         if (!_exists(tokenId)) {
             revert Error_TokenNotFound();
        }

        // Get all layer instance IDs attached to this token
        uint256[] memory layerInstanceIdsToBurn = new uint256[](_baseTokenLayers[tokenId].length);
        for(uint i = 0; i < _baseTokenLayers[tokenId].length; i++) {
             layerInstanceIdsToBurn[i] = _baseTokenLayers[tokenId][i];
        }

        // Clear the layers array for this token first to avoid re-entrancy risk (though low here)
        delete _baseTokenLayers[tokenId];

        // Burn each attached layer instance
        for (uint i = 0; i < layerInstanceIdsToBurn.length; i++) {
             uint256 instanceId = layerInstanceIdsToBurn[i];
             LayerInstance storage instance = _layerInstances[instanceId];
             if (instance.exists && instance.attachedTokenId == tokenId) { // Check exists and still attached (should be)
                 // Decrement template supply
                 LayerTemplate storage template = _layerTemplates[instance.templateId];
                 if (template.currentSupply > 0) {
                     template.currentSupply--;
                 }
                 // Delete the layer instance data
                 delete _layerInstances[instanceId];
                 emit LayerInstanceBurned(instanceId);
                 emit LayerInstanceRemoved(tokenId, instanceId);
             }
        }

        // Burn the base token itself
        _burn(tokenId);

        emit BaseTokenAndLayersBurned(tokenId);
    }


    // --- View Functions (Read Only) ---

    /// @dev Returns the total number of base tokens minted. Alias for ERC721Enumerable's totalSupply.
    function getBaseTokenCount() public view returns (uint256) {
        return totalSupply();
    }

    /// @dev Returns the total number of unique layer templates created.
    function getLayerTemplateCount() public view returns (uint256) {
        return _nextLayerTemplateId - 1; // Since IDs start from 1
    }

    /// @dev Returns the total number of layer instances ever created (including burned ones if counter isn't adjusted, but deleted from storage).
    /// Note: This counts how many instance IDs have been issued, not how many currently exist.
    function getLayerInstanceCount() public view returns (uint256) {
        return _nextLayerInstanceId - 1; // Since IDs start from 1
    }

    /// @dev Returns information about a specific layer template.
    /// @param templateId The ID of the layer template.
    /// @return LayerTemplate struct data.
    function getLayerTemplateInfo(uint256 templateId) public view returns (LayerTemplate memory) {
        if (!_existsLayerTemplate(templateId)) {
            revert Error_InvalidLayerTemplateId();
        }
        return _layerTemplates[templateId];
    }

    /// @dev Returns information about a specific layer instance.
    /// @param instanceId The ID of the layer instance.
    /// @return LayerInstance struct data.
    function getLayerInstanceInfo(uint256 instanceId) public view returns (LayerInstance memory) {
        if (!_existsLayerInstance(instanceId)) {
            revert Error_InvalidLayerInstanceId();
        }
        return _layerInstances[instanceId];
    }

    /// @dev Returns the ordered list of layer instance IDs attached to a base token.
    /// @param tokenId The ID of the base token.
    /// @return An array of layer instance IDs.
    function getLayersOfToken(uint256 tokenId) public view returns (uint256[] memory) {
         if (!_exists(tokenId)) {
             revert Error_TokenNotFound();
        }
        return _baseTokenLayers[tokenId];
    }

    /// @dev Returns a list of all existing layer template IDs.
    /// @return An array of layer template IDs.
    function getAvailableLayerTemplates() public view returns (uint256[] memory) {
        uint256 count = getLayerTemplateCount();
        uint256[] memory templateIds = new uint256[](count);
        for (uint i = 0; i < count; i++) {
            templateIds[i] = i + 1; // Assuming sequential IDs starting from 1
        }
        return templateIds;
    }

    /// @dev Checks if a specific layer template has remaining supply available to be added.
    /// @param templateId The ID of the layer template.
    /// @return True if supply is available or unlimited, false otherwise.
    function isLayerTemplateAvailable(uint256 templateId) public view returns (bool) {
        LayerTemplate storage template = _layerTemplates[templateId];
        if (!template.exists) {
            return false;
        }
        return template.maxSupply == 0 || template.currentSupply < template.maxSupply;
    }

    /// @dev Generates a *preview* tokenURI for a hypothetical combination of layers.
    /// This function does not modify state and can be used off-chain to preview art.
    /// It constructs a URI similar to `tokenURI` but with provided layer template IDs.
    /// NOTE: This requires the off-chain metadata service to support processing a list of template IDs
    /// for a preview, perhaps via a query parameter like `?layers=[templateId1,templateId2,...]`.
    /// The structure here assumes a simple base URI + /preview + list of template IDs format.
    /// A more robust implementation might pass a JSON object or a different format.
    /// The example format is simplified for demonstration.
    /// @param baseTokenId The ID of the base token (used for context in the URI, might not need to exist).
    /// @param layerTemplateIds The array of layer template IDs to include in the preview, in desired order.
    /// @return A string representing the preview token URI.
    function composePreviewURI(uint256 baseTokenId, uint256[] memory layerTemplateIds) public view returns (string memory) {
        // Basic validation that templates exist
        for (uint i = 0; i < layerTemplateIds.length; i++) {
            if (!_existsLayerTemplate(layerTemplateIds[i])) {
                 revert Error_InvalidLayerTemplateId();
            }
        }

        // Construct the preview URI
        // Example format: baseURI + "preview/" + tokenId + "?layers=" + templateId1 + "," + templateId2 + ...
        string memory previewPrefix = string.concat(_baseTokenURI, "preview/");
        string memory tokenIdStr = baseTokenId.toString();
        string memory layersQuery = "?layers=";
        string[] memory templateIdStrs = new string[](layerTemplateIds.length);

        for (uint i = 0; i < layerTemplateIds.length; i++) {
            templateIdStrs[i] = layerTemplateIds[i].toString();
        }

        string memory joinedTemplateIds = "";
        if (templateIdStrs.length > 0) {
             joinedTemplateIds = templateIdStrs[0];
             for (uint i = 1; i < templateIdStrs.length; i++) {
                 joinedTemplateIds = string.concat(joinedTemplateIds, ",", templateIdStrs[i]);
             }
        }

        return string.concat(previewPrefix, tokenIdStr, layersQuery, joinedTemplateIds);
    }


    /// @dev Returns the current base URI prefix.
    function getBaseTokenURI() public view returns (string memory) {
        return _baseTokenURI;
    }

    /// @dev Returns the current paused state of the protocol.
    function isPaused() public view returns (bool) {
        return _paused;
    }


    // --- Internal Helper Functions ---

    /// @dev Internal function to generate the dynamic token URI.
    /// Called by the public `tokenURI` function.
    /// This constructs a URL that includes the token ID and potentially lists
    /// the attached layer instance IDs, allowing an off-chain service
    /// to query the contract for layer details and compose the final metadata/image.
    /// Example: "https://api.mydapp.com/metadata/123?layers=456,789,1011"
    function _generateTokenURI(uint256 tokenId) internal view returns (string memory) {
        // Base metadata URI points to an off-chain endpoint
        string memory base = _baseTokenURI;
        string memory id = tokenId.toString();

        // Append token ID to the base URI
        string memory uri = string.concat(base, id);

        // Get attached layer instance IDs
        uint256[] memory layerInstanceIds = _baseTokenLayers[tokenId];

        // If there are layers, append them as a query parameter for the off-chain service
        if (layerInstanceIds.length > 0) {
            string memory layersQuery = "?layers=";
            string[] memory instanceIdStrs = new string[](layerInstanceIds.length);

            for (uint i = 0; i < layerInstanceIds.length; i++) {
                instanceIdStrs[i] = layerInstanceIds[i].toString();
            }

            string memory joinedInstanceIds = instanceIdStrs[0];
            for (uint i = 1; i < instanceIdStrs.length; i++) {
                joinedInstanceIds = string.concat(joinedInstanceIds, ",", instanceIdStrs[i]);
            }

            uri = string.concat(uri, layersQuery, joinedInstanceIds);
        }

        return uri;
    }

     /// @dev Internal check if a layer template ID exists.
     function _existsLayerTemplate(uint256 templateId) internal view returns (bool) {
         return _layerTemplates[templateId].exists;
     }

     /// @dev Internal check if a layer instance ID exists.
     function _existsLayerInstance(uint256 instanceId) internal view returns (bool) {
         return _layerInstances[instanceId].exists;
     }


    // The following ERC721 standard functions are inherited from ERC721Enumerable:
    // - balanceOf(address owner)
    // - ownerOf(uint256 tokenId)
    // - approve(address to, uint256 tokenId)
    // - getApproved(uint256 tokenId)
    // - setApprovalForAll(address operator, bool approved)
    // - isApprovedForAll(address owner, address operator)
    // - transferFrom(address from, address to, uint256 tokenId)
    // - safeTransferFrom(address from, address to, uint256 tokenId) (two versions)
    // - totalSupply()
    // - tokenOfOwnerByIndex(address owner, uint256 index)
    // - tokenByIndex(uint256 index)

    // _burn(uint256 tokenId) and _safeMint(address to, uint256 tokenId) are also used internally.
}

library SafeMath {
    // Used this simple library for array index manipulation safety as pop() isn't bounds checked directly
    // This specific implementation is less critical in 0.8+ due to overflow checks,
    // but the concept of safe array handling remains relevant.
    // For pop(), we just need to ensure length > 0 before attempting.
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }
     // Add other arithmetic functions if needed, but for this use case, sub is sufficient.
}
```