Okay, let's create an interesting and advanced smart contract concept. How about a dynamic, layered digital canvas where users can paint pixels, and each painting action mints a dynamic NFT representing that contribution? This combines NFTs, collaborative art, dynamic state, and layered graphics concepts on-chain.

Let's call it `CryptoCanvas`.

Here's the outline and function summary, followed by the Solidity code.

---

**Smart Contract Name:** `CryptoCanvas`

**Concept:** A decentralized, dynamic, and layered digital canvas where users can paint pixels on specific layers. Each distinct painting action mints a unique ERC721 "Stroke" NFT representing that specific contribution (color, location, layer, timestamp, painter). The final canvas state is a composite of all layers, rendered on-the-fly.

**Advanced/Creative Concepts:**

1.  **Layered Canvas:** Multiple independent layers exist, owned and managed separately. The final image is a composite.
2.  **Dynamic NFT (Stroke):** NFTs represent *actions* (painting a pixel on a layer at a time) rather than static images. Their potential value/meaning could be derived from their position, layer, age, or whether they are still visible in the composite.
3.  **On-Chain State:** The canvas state (pixel colors on layers) is stored directly in contract storage (though retrieval of the full canvas is handled by iterating layers).
4.  **Role-Based Layer Management:** Layer owners/admins can manage their specific layers.
5.  **Composite Rendering Logic:** A function calculates the final color of any pixel by iterating through layers based on predefined rules (e.g., top-down override).
6.  **Gamified Elements:** Highlighting owned strokes adds a curated visibility layer.

**Outline:**

1.  **State Variables:** Dimensions, pixel data (base layer), layer data, stroke data (NFTs), counters, fees, paused status, admin roles.
2.  **Events:** For painting, layer creation, stroke minting, ownership changes, etc.
3.  **Modifiers:** For access control (owner, layer admin, paused).
4.  **Structs:** `Layer`, `Stroke`.
5.  **Core Canvas/Pixel Functions:** Painting, getting composite pixel color, getting canvas section.
6.  **Layer Management Functions:** Create, transfer ownership, set properties, list layers.
7.  **Stroke (NFT) Functions:** Get details, get tokenURI, enumeration helpers. (Inherits standard ERC721 functions).
8.  **Highlighting/Gamification Functions:** Add/remove highlights, get highlighted strokes.
9.  **Admin/Utility Functions:** Setup, pause/unpause, withdraw fees, set costs, total counts.

**Function Summary (20+ Functions):**

1.  `constructor(uint256 _width, uint256 _height)`: Initializes the canvas dimensions and base layer. Mints initial layer 0 (base layer) to the deployer.
2.  `paintPixel(uint256 _layerId, uint256 _x, uint256 _y, bytes3 _color)`: Allows a user to paint a pixel at `(_x, _y)` on `_layerId` with `_color`. Requires payment. Mints a new "Stroke" NFT for this action.
3.  `getPixelColor(uint256 _x, uint256 _y)`: Returns the final composite color of the pixel at `(_x, _y)` by iterating through layers from base upwards.
4.  `getCanvasSection(uint256 _x1, uint256 _y1, uint256 _x2, uint256 _y2)`: Returns an array of composite colors for a rectangular section of the canvas.
5.  `getCanvasDimensions()`: Returns the width and height of the canvas.
6.  `getPixelCost()`: Returns the current cost in Wei to paint a single pixel.
7.  `setBasePixelCost(uint256 _cost)`: Owner sets the base cost for painting.
8.  `createLayer(string calldata _name, bool _isPublic, address _initialOwner)`: Allows authorized users (owner or others based on policy) to create a new layer. Requires payment for non-owner creation.
9.  `transferLayerOwnership(uint256 _layerId, address _newOwner)`: Transfers ownership of a specific layer. Requires current owner or contract owner.
10. `setLayerName(uint256 _layerId, string calldata _name)`: Sets the name of a layer. Requires layer owner or contract owner.
11. `setLayerPublicStatus(uint256 _layerId, bool _isPublic)`: Sets whether a layer is public (anyone can paint) or private (only layer owner/admins can paint). Requires layer owner or contract owner.
12. `getLayerInfo(uint256 _layerId)`: Returns details about a layer (name, owner, public status).
13. `listLayers()`: Returns an array of all existing layer IDs.
14. `getLayerAdmin(uint256 _layerId, address _account)`: Checks if an account has admin privileges on a specific layer. (Requires role management within the struct or a separate mapping). *Let's implement simple layer owner/contract owner checks first.*
15. `isLayerPublic(uint256 _layerId)`: Returns the public status of a layer.
16. `tokenURI(uint256 tokenId)`: (Overrides ERC721) Returns the metadata URI for a Stroke NFT. Includes details like coordinates, color, layer, timestamp, and painter. Generates on-chain JSON.
17. `getStrokeDetails(uint256 tokenId)`: Returns the structured data for a specific Stroke NFT.
18. `getStrokeCount()`: Returns the total number of Stroke NFTs minted.
19. `getStrokesOwnedBy(address _painter)`: Returns an array of Stroke token IDs owned by a specific address. (Leverages ERC721Enumerable).
20. `getPainterStrokeCount(address _painter)`: Returns the number of Stroke NFTs owned by an address. (Leverages ERC721Enumerable).
21. `highlightStroke(uint256 _tokenId)`: Allows the owner of a Stroke NFT to mark it as highlighted. Requires payment.
22. `removeHighlight(uint256 _tokenId)`: Allows the owner of a Stroke NFT to unmark it as highlighted.
23. `getHighlightedStrokes()`: Returns an array of all token IDs that are currently highlighted.
24. `setHighlightFee(uint256 _fee)`: Owner sets the fee for highlighting a stroke.
25. `getHighlightFee()`: Returns the current highlight fee.
26. `pauseContract()`: Owner pauses all painting and layer creation interactions.
27. `unpauseContract()`: Owner unpauses the contract.
28. `withdrawFees()`: Owner withdraws accumulated Ether fees.
29. `setCanvasPixelColorAdmin(uint256 _layerId, uint256 _x, uint256 _y, bytes3 _color)`: Owner can set a pixel color on a specific layer directly (for moderation/fixes). Does *not* mint a Stroke NFT.
30. `getTotalFeesCollected()`: Returns the total fees collected by the contract.

*(Note: ERC721 standard functions like `ownerOf`, `balanceOf`, `approve`, `setApprovalForAll`, `transferFrom`, `safeTransferFrom` are inherited, adding at least 6 more functions, easily exceeding the 20 required)*

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Base64.sol";

/// @title CryptoCanvas
/// @dev A dynamic, layered digital canvas where users paint pixels. Each paint action mints a Stroke NFT.
/// @author Your Name/Alias

// --- Outline ---
// State Variables: Canvas dimensions, base layer pixels, layer data, stroke data (NFTs), counters, fees, paused status.
// Events: PixelPainted, LayerCreated, LayerOwnershipTransferred, StrokeMinted, StrokeHighlighted, FeesWithdrawn.
// Modifiers: paused, notPaused, onlyOwner, onlyLayerOwnerOrAdmin.
// Structs: Layer, Stroke.
// Core Canvas/Pixel Functions: paintPixel, getPixelColor, getCanvasSection, getCanvasDimensions, getPixelCost.
// Layer Management Functions: createLayer, transferLayerOwnership, setLayerName, setLayerPublicStatus, getLayerInfo, listLayers, isLayerPublic.
// Stroke (NFT) Functions: tokenURI, getStrokeDetails, getStrokeCount, getStrokesOwnedBy, getPainterStrokeCount. (Inherits ERC721 standard functions).
// Highlighting/Gamification Functions: highlightStroke, removeHighlight, getHighlightedStrokes, setHighlightFee, getHighlightFee.
// Admin/Utility Functions: constructor, pauseContract, unpauseContract, withdrawFees, setBasePixelCost, setCanvasPixelColorAdmin, getTotalFeesCollected.

// --- Function Summary ---
// constructor(uint256 _width, uint256 _height): Initializes canvas.
// paintPixel(uint256 _layerId, uint256 _x, uint256 _y, bytes3 _color): Paints a pixel on a layer, mints Stroke NFT.
// getPixelColor(uint256 _x, uint256 _y): Gets composite color at pixel.
// getCanvasSection(uint256 _x1, uint256 _y1, uint256 _x2, uint256 _y2): Gets composite colors for a canvas section.
// getCanvasDimensions(): Gets canvas width and height.
// getPixelCost(): Gets current pixel painting cost.
// setBasePixelCost(uint256 _cost): Owner sets base pixel cost.
// createLayer(string calldata _name, bool _isPublic, address _initialOwner): Creates a new layer.
// transferLayerOwnership(uint256 _layerId, address _newOwner): Transfers layer ownership.
// setLayerName(uint256 _layerId, string calldata _name): Sets layer name.
// setLayerPublicStatus(uint256 _layerId, bool _isPublic): Sets layer public/private status.
// getLayerInfo(uint256 _layerId): Gets layer details.
// listLayers(): Gets list of all layer IDs.
// isLayerPublic(uint256 _layerId): Checks if layer is public.
// tokenURI(uint256 tokenId): Gets metadata URI for a Stroke NFT.
// getStrokeDetails(uint256 tokenId): Gets structured data for a Stroke NFT.
// getStrokeCount(): Gets total minted strokes.
// getStrokesOwnedBy(address _painter): Gets Stroke token IDs owned by address.
// getPainterStrokeCount(address _painter): Gets number of strokes owned by address.
// highlightStroke(uint256 _tokenId): Highlights owned Stroke NFT.
// removeHighlight(uint256 _tokenId): Removes highlight from owned Stroke NFT.
// getHighlightedStrokes(): Gets list of highlighted Stroke NFTs.
// setHighlightFee(uint256 _fee): Owner sets highlight fee.
// getHighlightFee(): Gets highlight fee.
// pauseContract(): Owner pauses contract interactions.
// unpauseContract(): Owner unpauses contract.
// withdrawFees(): Owner withdraws collected fees.
// setCanvasPixelColorAdmin(uint256 _layerId, uint256 _x, uint256 _y, bytes3 _color): Owner overrides pixel color on a layer (no NFT mint).
// getTotalFeesCollected(): Gets total collected fees.
// (+ ERC721 Standard Functions: ownerOf, balanceOf, approve, setApprovalForAll, transferFrom, safeTransferFrom, etc.)

contract CryptoCanvas is ERC721Enumerable, Ownable, Pausable {
    using Counters for Counters.Counter;

    uint256 public immutable canvasWidth;
    uint256 public immutable canvasHeight;

    // Layer 0 is the base layer, always public, owned by contract owner.
    // Subsequent layers can have different owners and public status.
    struct Layer {
        string name;
        address owner;
        bool isPublic;
        // Mapping of pixel index (y * width + x) to color override for this layer
        mapping(uint256 => bytes3) pixelOverrides;
        // Keep track of set pixel indices on this layer for iteration (optional optimization, but mapping keys aren't iterable)
        // For simpler implementation, we iterate layers and check mapping existence in getPixelColor.
    }

    mapping(uint256 => Layer) public layers;
    Counters.Counter private _layerCounter;

    // Stroke NFT represents a single pixel painting action on a layer
    struct Stroke {
        uint256 tokenId;
        uint256 layerId;
        uint256 x;
        uint256 y;
        bytes3 color; // Color applied by this stroke
        uint256 timestamp;
        address painter;
        uint256 pricePaid; // Wei paid for this specific stroke action
    }

    mapping(uint256 => Stroke) public strokes;
    Counters.Counter private _strokeCounter;

    uint256 public basePixelCost;
    uint256 public highlightFee;
    uint256 public totalFeesCollected;

    // Keep track of highlighted stroke token IDs
    mapping(uint256 => bool) private _isHighlighted;
    uint256[] private _highlightedStrokeIds; // Array to list highlighted strokes

    event PixelPainted(uint256 indexed layerId, uint256 indexed x, uint256 indexed y, bytes3 color, uint256 indexed tokenId, address painter);
    event LayerCreated(uint256 indexed layerId, string name, address indexed owner, bool isPublic);
    event LayerOwnershipTransferred(uint256 indexed layerId, address indexed previousOwner, address indexed newOwner);
    event StrokeHighlighted(uint256 indexed tokenId, address indexed owner);
    event StrokeHighlightRemoved(uint256 indexed tokenId, address indexed owner);
    event FeesWithdrawn(uint256 amount, address indexed recipient);

    // --- Modifiers ---
    modifier onlyLayerOwner(uint256 _layerId) {
        require(layers[_layerId].owner == msg.sender, "Not layer owner");
        _;
    }

    modifier onlyLayerOwnerOrContractOwner(uint256 _layerId) {
        require(layers[_layerId].owner == msg.sender || owner() == msg.sender, "Not layer or contract owner");
        _;
    }

    modifier validCoordinates(uint256 _x, uint256 _y) {
        require(_x < canvasWidth && _y < canvasHeight, "Invalid coordinates");
        _;
    }

    modifier layerExists(uint256 _layerId) {
        require(_layerId < _layerCounter.current(), "Layer does not exist");
        _;
    }

    // --- Constructor ---
    constructor(uint256 _width, uint256 _height)
        ERC721("CryptoCanvasStroke", "CCS")
        Ownable(msg.sender)
        Pausable()
    {
        require(_width > 0 && _height > 0, "Canvas dimensions must be positive");
        canvasWidth = _width;
        canvasHeight = _height;

        // Create the base layer (Layer 0)
        _createLayer("Base Layer", true, msg.sender); // Layer 0 is public, owned by contract owner
        basePixelCost = 0.0001 ether; // Default cost
        highlightFee = 0.001 ether; // Default highlight fee
    }

    // --- Core Canvas/Pixel Functions ---

    /// @notice Allows a user to paint a pixel on a specific layer. Mints a Stroke NFT for this action.
    /// @param _layerId The ID of the layer to paint on.
    /// @param _x The X coordinate (0 to width-1).
    /// @param _y The Y coordinate (0 to height-1).
    /// @param _color The RGB color as a bytes3 (e.g., 0xff0000 for red).
    function paintPixel(uint256 _layerId, uint256 _x, uint256 _y, bytes3 _color)
        external
        payable
        notPaused
        validCoordinates(_x, _y)
        layerExists(_layerId)
    {
        Layer storage layer = layers[_layerId];
        require(layer.isPublic || layer.owner == msg.sender, "Layer is private and you are not the owner");
        require(msg.value >= basePixelCost, "Insufficient payment to paint pixel");

        uint256 pixelIndex = _y * canvasWidth + _x;
        uint256 newTokenId = _strokeCounter.current();

        // Store stroke details
        strokes[newTokenId] = Stroke({
            tokenId: newTokenId,
            layerId: _layerId,
            x: _x,
            y: _y,
            color: _color,
            timestamp: block.timestamp,
            painter: msg.sender,
            pricePaid: msg.value
        });

        // Update the layer's pixel override
        layer.pixelOverrides[pixelIndex] = _color;

        // Mint the Stroke NFT to the painter
        _safeMint(msg.sender, newTokenId);
        _strokeCounter.increment();

        totalFeesCollected += msg.value;

        emit PixelPainted(_layerId, _x, _y, _color, newTokenId, msg.sender);
    }

    /// @notice Gets the final composite color of a pixel by rendering layers top-down.
    /// @param _x The X coordinate (0 to width-1).
    /// @param _y The Y coordinate (0 to height-1).
    /// @return The composite color as bytes3. Returns 0x000000 if no color is set on any layer (effectively transparent/black).
    function getPixelColor(uint256 _x, uint256 _y)
        public
        view
        validCoordinates(_x, _y)
        returns (bytes3)
    {
        uint256 pixelIndex = _y * canvasWidth + _x;
        bytes3 finalColor = 0x000000; // Default background color (can be transparent concept)

        // Iterate through layers from base (0) upwards
        uint256 totalLayers = _layerCounter.current();
        for (uint256 i = 0; i < totalLayers; ++i) {
            // Check if this layer has an override for this pixel
            bytes3 memory layerColor = layers[i].pixelOverrides[pixelIndex];
            // Assuming 0x000000 implies no override or transparency for simplicity in this example
            // In a real system, transparency would need a fourth byte (alpha) or a separate mechanism.
            // Here, any explicit color set (non-zero bytes3) overrides lower layers.
            if (layerColor != 0x000000) {
                 finalColor = layerColor;
                 // Optimization: if a color is fully opaque (conceptually, assuming non-zero implies opaque), stop checking lower layers.
                 // For true transparency, you'd blend colors based on alpha channels.
            }
        }

        return finalColor;
    }

    /// @notice Gets the composite colors for a rectangular section of the canvas.
    /// @param _x1 The starting X coordinate (inclusive).
    /// @param _y1 The starting Y coordinate (inclusive).
    /// @param _x2 The ending X coordinate (exclusive).
    /// @param _y2 The ending Y coordinate (exclusive).
    /// @return An array of composite colors for the section.
    function getCanvasSection(uint256 _x1, uint256 _y1, uint256 _x2, uint256 _y2)
        external
        view
        returns (bytes3[] memory)
    {
        require(_x1 < _x2 && _y1 < _y2, "Invalid section coordinates");
        require(_x2 <= canvasWidth && _y2 <= canvasHeight, "Section out of bounds");

        uint256 sectionWidth = _x2 - _x1;
        uint256 sectionHeight = _y2 - _y1;
        bytes3[] memory sectionColors = new bytes3[](sectionWidth * sectionHeight);

        uint256 index = 0;
        for (uint256 y = _y1; y < _y2; ++y) {
            for (uint256 x = _x1; x < _x2; ++x) {
                sectionColors[index] = getPixelColor(x, y);
                unchecked { index++; }
            }
        }
        return sectionColors;
    }

    /// @notice Gets the dimensions of the canvas.
    /// @return The width and height of the canvas.
    function getCanvasDimensions() external view returns (uint256 width, uint256 height) {
        return (canvasWidth, canvasHeight);
    }

    /// @notice Gets the current cost to paint a single pixel.
    /// @return The cost in Wei.
    function getPixelCost() external view returns (uint256) {
        return basePixelCost;
    }

    /// @notice Owner sets the base cost for painting a pixel.
    /// @param _cost The new base cost in Wei.
    function setBasePixelCost(uint256 _cost) external onlyOwner {
        basePixelCost = _cost;
    }

    // --- Layer Management Functions ---

    /// @notice Internal helper to create a layer.
    function _createLayer(string memory _name, bool _isPublic, address _initialOwner) internal returns (uint256) {
         uint256 newLayerId = _layerCounter.current();
         layers[newLayerId] = Layer({
             name: _name,
             owner: _initialOwner,
             isPublic: _isPublic
             // pixelOverrides mapping is initialized empty
         });
         _layerCounter.increment();
         emit LayerCreated(newLayerId, _name, _initialOwner, _isPublic);
         return newLayerId;
    }

    /// @notice Creates a new layer. Owner can create any layer for free. Others can create public layers for a fee.
    /// @param _name The name of the new layer.
    /// @param _isPublic Whether the layer is public (anyone can paint) or private (only owner/admins).
    /// @param _initialOwner The initial owner of the layer.
    function createLayer(string calldata _name, bool _isPublic, address _initialOwner)
        external
        payable
        notPaused
        returns (uint256)
    {
        // Policy: Owner creates for free, others pay a fee (e.g., 1 ether) for public layers only.
        bool isOwner = msg.sender == owner();
        uint256 creationFee = 0;
        if (!isOwner) {
            require(_isPublic, "Only owner can create private layers");
            creationFee = 1 ether; // Example fee
            require(msg.value >= creationFee, "Insufficient payment for layer creation");
        }

        uint256 newLayerId = _createLayer(_name, _isPublic, _initialOwner);

        // Collect fee if applicable
        if (creationFee > 0) {
            totalFeesCollected += msg.value; // Collect potentially excess payment too
        }

        return newLayerId;
    }

    /// @notice Transfers ownership of a layer.
    /// @param _layerId The ID of the layer.
    /// @param _newOwner The address of the new owner.
    function transferLayerOwnership(uint256 _layerId, address _newOwner)
        external
        notPaused
        layerExists(_layerId)
        onlyLayerOwnerOrContractOwner(_layerId)
    {
        address oldOwner = layers[_layerId].owner;
        layers[_layerId].owner = _newOwner;
        emit LayerOwnershipTransferred(_layerId, oldOwner, _newOwner);
    }

    /// @notice Sets the name of a layer.
    /// @param _layerId The ID of the layer.
    /// @param _name The new name.
    function setLayerName(uint256 _layerId, string calldata _name)
        external
        notPaused
        layerExists(_layerId)
        onlyLayerOwnerOrContractOwner(_layerId)
    {
        layers[_layerId].name = _name;
    }

    /// @notice Sets whether a layer is public (anyone can paint) or private (only owner/admins). Layer 0 must remain public.
    /// @param _layerId The ID of the layer.
    /// @param _isPublic The new public status.
    function setLayerPublicStatus(uint256 _layerId, bool _isPublic)
        external
        notPaused
        layerExists(_layerId)
        onlyLayerOwnerOrContractOwner(_layerId)
    {
        require(_layerId != 0, "Base layer (0) cannot be made private");
        layers[_layerId].isPublic = _isPublic;
    }


    /// @notice Gets details about a specific layer.
    /// @param _layerId The ID of the layer.
    /// @return name The layer's name.
    /// @return owner The layer's owner address.
    /// @return isPublic Whether the layer is public.
    function getLayerInfo(uint256 _layerId)
        external
        view
        layerExists(_layerId)
        returns (string memory name, address owner, bool isPublic)
    {
        Layer storage layer = layers[_layerId];
        return (layer.name, layer.owner, layer.isPublic);
    }

    /// @notice Gets an array of all existing layer IDs.
    /// @return An array of layer IDs.
    function listLayers() external view returns (uint256[] memory) {
        uint256 totalLayers = _layerCounter.current();
        uint256[] memory layerIds = new uint256[](totalLayers);
        for (uint256 i = 0; i < totalLayers; ++i) {
            layerIds[i] = i;
        }
        return layerIds;
    }

     /// @notice Checks if a layer is public.
     /// @param _layerId The ID of the layer.
     /// @return True if the layer is public, false otherwise.
    function isLayerPublic(uint256 _layerId) public view layerExists(_layerId) returns (bool) {
        return layers[_layerId].isPublic;
    }


    // --- Stroke (NFT) Functions ---

    /// @notice Generates metadata URI for a Stroke NFT.
    /// @dev Overrides ERC721's tokenURI. Generates on-chain Base64 encoded JSON.
    /// @param tokenId The ID of the stroke token.
    /// @return The metadata URI.
    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (string memory)
    {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        Stroke storage stroke = strokes[tokenId];
        Layer storage layer = layers[stroke.layerId];

        // Construct JSON metadata
        string memory json = string(abi.encodePacked(
            '{"name": "CryptoCanvas Stroke #', toString(tokenId), '",',
            '"description": "Pixel stroke at (', toString(stroke.x), ',', toString(stroke.y),
            ') on layer ', toString(stroke.layerId), ' (', layer.name, ')",',
            '"image": "data:image/svg+xml;base64,', // Minimal SVG representing the pixel
            Base64.encode(bytes(abi.encodePacked(
                '<svg xmlns="http://www.w3.org/2000/svg" width="100" height="100">',
                '<rect width="100" height="100" fill="#', bytesToHex(stroke.color), '"/>', // Represent the color
                '</svg>'
            ))),
            '",',
            '"attributes": [',
                '{"trait_type": "X", "value": ', toString(stroke.x), '},',
                '{"trait_type": "Y", "value": ', toString(stroke.y), '},',
                '{"trait_type": "Layer ID", "value": ', toString(stroke.layerId), '},',
                '{"trait_type": "Layer Name", "value": "', layer.name, '"},',
                '{"trait_type": "Color", "value": "#', bytesToHex(stroke.color), '"},',
                '{"trait_type": "Painter", "value": "', toString(stroke.painter), '"},',
                '{"trait_type": "Timestamp", "value": ', toString(stroke.timestamp), '}',
            ']}'
        ));

        // Encode JSON to Base64 and prefix with data URI scheme
        return string(abi.encodePacked("data:application/json;base64,", Base64.encode(bytes(json))));
    }

    /// @notice Gets the structured details of a specific Stroke NFT.
    /// @param tokenId The ID of the stroke token.
    /// @return The Stroke struct.
    function getStrokeDetails(uint256 tokenId) external view returns (Stroke memory) {
        require(_exists(tokenId), "Stroke does not exist");
        return strokes[tokenId];
    }

    /// @notice Gets the total number of Stroke NFTs that have been minted.
    /// @return The total count.
    function getStrokeCount() external view returns (uint256) {
        return _strokeCounter.current();
    }

    /// @notice Gets an array of Stroke token IDs owned by a specific painter address.
    /// @dev Uses ERC721Enumerable's tokenOfOwnerByIndex.
    /// @param _painter The address of the painter.
    /// @return An array of token IDs.
    function getStrokesOwnedBy(address _painter) external view returns (uint256[] memory) {
        uint256 balance = balanceOf(_painter);
        uint256[] memory tokenIds = new uint256[](balance);
        for (uint256 i = 0; i < balance; i++) {
            tokenIds[i] = tokenOfOwnerByIndex(_painter, i);
        }
        return tokenIds;
    }

     /// @notice Gets the number of Stroke NFTs owned by a specific painter address.
     /// @param _painter The address of the painter.
     /// @return The number of strokes owned.
    function getPainterStrokeCount(address _painter) external view returns (uint256) {
        return balanceOf(_painter);
    }

    // --- Highlighting/Gamification Functions ---

    /// @notice Allows the owner of a Stroke NFT to mark it as highlighted.
    /// @param _tokenId The ID of the stroke token to highlight.
    function highlightStroke(uint256 _tokenId) external payable notPaused {
        require(ownerOf(_tokenId) == msg.sender, "Not token owner");
        require(!_isHighlighted[_tokenId], "Stroke already highlighted");
        require(msg.value >= highlightFee, "Insufficient payment for highlighting");

        _isHighlighted[_tokenId] = true;
        _highlightedStrokeIds.push(_tokenId); // Add to array for listing

        totalFeesCollected += msg.value;
        emit StrokeHighlighted(_tokenId, msg.sender);
    }

    /// @notice Allows the owner of a highlighted Stroke NFT to unmark it.
    /// @param _tokenId The ID of the stroke token to remove highlight from.
    function removeHighlight(uint256 _tokenId) external notPaused {
        require(ownerOf(_tokenId) == msg.sender, "Not token owner");
        require(_isHighlighted[_tokenId], "Stroke is not highlighted");

        _isHighlighted[_tokenId] = false;

        // Remove from the highlightedStrokeIds array
        // This is O(n) and could be optimized with a mapping if needed for very large numbers of highlights
        for (uint256 i = 0; i < _highlightedStrokeIds.length; ++i) {
            if (_highlightedStrokeIds[i] == _tokenId) {
                // Swap with the last element and pop
                _highlightedStrokeIds[i] = _highlightedStrokeIds[_highlightedStrokeIds.length - 1];
                _highlightedStrokeIds.pop();
                break; // Found and removed
            }
        }

        emit StrokeHighlightRemoved(_tokenId, msg.sender);
    }

    /// @notice Gets an array of all token IDs that are currently highlighted.
    /// @return An array of highlighted stroke token IDs.
    function getHighlightedStrokes() external view returns (uint256[] memory) {
        // Return a copy to prevent external modification of the internal array
        return _highlightedStrokeIds;
    }

    /// @notice Owner sets the fee for highlighting a stroke.
    /// @param _fee The new highlight fee in Wei.
    function setHighlightFee(uint256 _fee) external onlyOwner {
        highlightFee = _fee;
    }

    /// @notice Gets the current fee for highlighting a stroke.
    /// @return The fee in Wei.
    function getHighlightFee() external view returns (uint256) {
        return highlightFee;
    }


    // --- Admin/Utility Functions ---

    /// @notice Owner pauses contract interactions (painting, layer creation, highlighting).
    function pauseContract() external onlyOwner {
        _pause();
    }

    /// @notice Owner unpauses contract interactions.
    function unpauseContract() external onlyOwner {
        _unpause();
    }

    /// @notice Owner withdraws collected fees.
    function withdrawFees() external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No fees to withdraw");
        totalFeesCollected = 0; // Reset collected amount tracker (actual balance decreases)

        (bool success, ) = owner().call{value: balance}("");
        require(success, "Fee withdrawal failed");

        emit FeesWithdrawn(balance, owner());
    }

     /// @notice Owner can set a pixel color on a specific layer directly (e.g., for moderation). Does NOT mint an NFT.
     /// @param _layerId The ID of the layer.
     /// @param _x The X coordinate.
     /// @param _y The Y coordinate.
     /// @param _color The RGB color.
    function setCanvasPixelColorAdmin(uint256 _layerId, uint256 _x, uint256 _y, bytes3 _color)
        external
        onlyOwner
        validCoordinates(_x, _y)
        layerExists(_layerId)
    {
        uint256 pixelIndex = _y * canvasWidth + _x;
        layers[_layerId].pixelOverrides[pixelIndex] = _color;
        // No event specific to admin override here, as it's not a 'PixelPainted' by a user.
        // Could add a separate event like AdminPixelSet if needed for auditability.
    }


    /// @notice Gets the total fees collected by the contract.
    /// @return The total collected fees in Wei.
    function getTotalFeesCollected() external view returns (uint256) {
        return totalFeesCollected;
    }

     /// @notice Gets the total number of layers created.
     /// @return The total count.
    function getTotalLayers() external view returns (uint256) {
        return _layerCounter.current();
    }

    // --- Internal Helpers ---

    /// @dev Helper function to convert bytes3 (RGB) to a hex string for metadata.
    function bytesToHex(bytes3 b) internal pure returns (string memory) {
        bytes memory hexAlphabet = "0123456789abcdef";
        bytes memory s = new bytes(6);
        for (uint i = 0; i < 3; i++) {
            uint8 byteValue = uint8(b[i]);
            s[i * 2] = hexAlphabet[byteValue >> 4];
            s[i * 2 + 1] = hexAlphabet[byteValue & 0x0f];
        }
        return string(s);
    }

    /// @dev Helper function to convert a uint256 to a string.
    function toString(uint256 value) internal pure returns (string memory) {
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
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

     /// @dev Helper function to convert an address to a string.
    function toString(address account) internal pure returns (string memory) {
        bytes32 value = bytes32(uint256(uint160(account)));
        bytes memory alphabet = "0123456789abcdef";

        bytes memory str = new bytes(42);
        str[0] = '0';
        str[1] = 'x';
        for (uint i = 0; i < 20; i++) {
            str[2 + i * 2] = alphabet[uint8(value[i + 12] >> 4)];
            str[3 + i * 2] = alphabet[uint8(value[i + 12] & 0x0f)];
        }
        return string(str);
    }

    // The following functions are overrides required by Solidity.
    // They are implemented by ERC721Enumerable but listed here for clarity.
    // function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721Enumerable) returns (bool) {
    //     return super.supportsInterface(interfaceId);
    // }

    // function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize) internal override(ERC721, ERC721Enumerable) {
    //     super._beforeTokenTransfer(from, to, tokenId, batchSize);
    // }

    // function _afterTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize) internal override(ERC721, ERC721Enumerable) {
    //     super._afterTokenTransfer(from, to, tokenId, batchSize);
    // }

    // function _update(address to, uint256 tokenId, address auth) internal override(ERC721, ERC721Enumerable) returns (address) {
    //     return super._update(to, tokenId, auth);
    // }

     // function _increaseBalance(address account, uint256 value) internal override(ERC721, ERC721Enumerable) {
    //    super._increaseBalance(account, value);
    // }
}
```