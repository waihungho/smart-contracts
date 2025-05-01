Okay, let's design a smart contract concept around a collaborative, dynamic on-chain art piece. We'll call it **CryptoCanvas**.

The idea is a large, multi-layered pixel canvas where users can 'paint' pixels by paying a fee. Each successful painting action mints a unique NFT representing that 'brush stroke' on the canvas, capturing its history and giving the painter provenance and potential rights related to that specific action. The canvas itself can be affected by time-based "environmental" effects triggered on-chain.

This concept incorporates:
*   **NFTs:** Each contribution is an ERC721 token (Brush Stroke).
*   **Dynamic State:** The canvas state changes over time through painting and effects.
*   **Collaboration:** Multiple users contribute to a single shared asset.
*   **Layering:** Adds complexity and artistic potential.
*   **On-chain Effects:** Introduces an element of dynamic evolution and potential unpredictability.
*   **Provenance:** Brush Stroke NFTs record the history of the canvas.
*   **Economy:** Fees collected go to a treasury.
*   **Royalty Standard (ERC2981):** Royalties on Brush Stroke NFT sales.

---

**Outline and Function Summary: CryptoCanvas**

**Concept:** A multi-layered pixel canvas on the blockchain where users pay to paint pixels, minting an NFT for each stroke. The canvas is a shared, evolving asset influenced by user actions and timed environmental effects.

**Inherits:**
*   `ERC721Enumerable.sol`: For Brush Stroke NFTs (allows enumerating tokens owned by an address or total supply).
*   `ERC2981.sol`: For NFT royalties.
*   `Ownable.sol`: For administrative control.

**State Variables:**
*   `canvasState`: Stores the color for each pixel (x, y) on each layer.
*   `layerConfigs`: Stores properties for each layer (name, cost multiplier, etc.).
*   `brushStrokeDetails`: Stores details for each minted Brush Stroke NFT (location, color, layer, timestamp, painter).
*   `_nextTokenId`: Counter for Brush Stroke NFTs.
*   `canvasWidth`, `canvasHeight`: Dimensions of the canvas.
*   `paintingFee`: Base cost to paint a pixel.
*   `treasury`: Address to receive painting fees.
*   `paused`: Flag to pause painting.
*   `lastEnvironmentalEffectTime`: Timestamp of the last effect application.
*   `environmentalEffectInterval`: Time between environmental effects.
*   `environmentalEffectParams`: Parameters for the active environmental effect.
*   `_royaltyInfo`: ERC2981 royalty details.

**Events:**
*   `PixelPainted`: Emitted when a pixel color is successfully updated.
*   `BrushStrokeMinted`: Emitted when a new Brush Stroke NFT is minted.
*   `PaintingFeeUpdated`: Emitted when the painting fee changes.
*   `TreasuryUpdated`: Emitted when the treasury address changes.
*   `LayerAdded`: Emitted when a new layer is defined.
*   `LayerPropertiesUpdated`: Emitted when a layer's properties change.
*   `CanvasResized`: Emitted when canvas dimensions change.
*   `PaintingPaused`: Emitted when painting is paused.
*   `PaintingUnpaused`: Emitted when painting is unpaused.
*   `EnvironmentalEffectTriggered`: Emitted when an environmental effect is applied.
*   `RoyaltyInfoUpdated`: Emitted when royalty information changes.

**Functions (20+ Required):**

1.  `constructor(uint256 initialWidth, uint256 initialHeight, uint256 basePaintingFee, address initialTreasury)`: Initializes canvas dimensions, fee, treasury, adds a default layer, and sets up NFT metadata.
2.  `paintPixel(uint256 x, uint256 y, uint256 layer, bytes3 color)`: Allows a user to paint a specific pixel on a specific layer. Requires payment, updates canvas state, and mints a Brush Stroke NFT. Handles bounds checks, layer validity, and fee calculation.
3.  `getPixelColor(uint256 x, uint256 y, uint256 layer)`: View function to get the current color of a specific pixel on a specific layer.
4.  `getBrushStrokeDetails(uint256 tokenId)`: View function to get the detailed information (location, color, timestamp, painter) for a given Brush Stroke NFT.
5.  `checkAndApplyEnvironmentalEffect()`: Allows anyone to trigger a check if the environmental effect interval has passed. If so, it applies the effect to a limited, pseudo-random area of the canvas state. (Note: True randomness is challenging on-chain, this uses `block.timestamp` and `block.difficulty`/`blockhash` as a simple seed).
6.  `getCanvasDimensions()`: View function returning the canvas width and height.
7.  `getPaintingFee()`: View function returning the current base painting fee.
8.  `getTotalLayers()`: View function returning the total number of layers defined.
9.  `getLayerProperties(uint256 layer)`: View function returning the properties (name, cost multiplier) for a specific layer.
10. `getTotalBrushStrokes()`: View function returning the total supply of Brush Stroke NFTs minted (`_nextTokenId`).
11. `getBrushStrokeCountByPainter(address painter)`: View function returning the number of Brush Stroke NFTs owned by a specific address. (Uses ERC721Enumerable `balanceOf`).
12. `getLastPaintedBrushStrokeId(uint256 x, uint256 y, uint256 layer)`: View function returning the token ID of the most recent Brush Stroke applied to a specific pixel on a specific layer. (Requires state variable tracking this). *Self-correction: Storing last ID per pixel/layer is gas-intensive on paint. Let's remove this and rely on off-chain indexing of `PixelPainted` events.* Instead, add a simple query about the *last overall* painted pixel.
12. `getLastPaintedPixelInfo()`: View function returning details (coordinates, layer, timestamp, painter, tokenId) of the very last pixel painted on the canvas. (Requires storing this info).
13. `setPaintingFee(uint256 newFee)`: Owner-only function to update the base painting fee.
14. `setTreasury(address newTreasury)`: Owner-only function to update the treasury address.
15. `addLayer(string memory name, uint256 paintingCostMultiplier)`: Owner-only function to define a new layer with specific properties.
16. `setLayerProperties(uint256 layer, string memory name, uint256 paintingCostMultiplier)`: Owner-only function to modify properties of an existing layer.
17. `resizeCanvas(uint256 newWidth, uint256 newHeight)`: Owner-only function to change canvas dimensions. Warns that existing state outside new bounds might be lost/inaccessible.
18. `pausePainting()`: Owner-only function to pause painting activity.
19. `unpausePainting()`: Owner-only function to unpause painting activity.
20. `withdrawFunds()`: Owner-only function to withdraw accumulated fees from the contract balance to the treasury.
21. `setEnvironmentalEffectInterval(uint256 interval)`: Owner-only function to set the time duration between environmental effects.
22. `setEnvironmentalEffectParams(uint256 params)`: Owner-only function to set parameters influencing the environmental effect logic. (Simplified as a single uint256).
23. `supportsInterface(bytes4 interfaceId)`: ERC165 standard implementation for interface detection (ERC721, ERC2981, ERC721Enumerable).
24. `tokenURI(uint256 tokenId)`: ERC721 standard function. Generates metadata URI for a Brush Stroke NFT, potentially linking to off-chain storage or an on-chain description based on `brushStrokeDetails`.
25. `royaltyInfo(uint256 tokenId, uint256 salePrice)`: ERC2981 standard function. Returns the receiver and amount of royalties for a Brush Stroke NFT sale.
26. `setRoyaltyInfo(address receiver, uint96 feeNumerator)`: Owner-only function to configure ERC2981 royalty details.
27. `_baseURI()`: Internal function to provide the base URI for token metadata. Can be set by owner.
    *   *Inherited ERC721/ERC721Enumerable functions:* `balanceOf`, `ownerOf`, `approve`, `getApproved`, `setApprovalForAll`, `isApprovedForAll`, `transferFrom`, `safeTransferFrom`, `totalSupply`, `tokenByIndex`, `tokenOfOwnerByIndex`. (These add significantly to the 20+ count).

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol"; // Using URIStorage for baseURI simplicity
import "@openzeppelin/contracts/token/ERC2981/ERC2981.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

// Outline and Function Summary: CryptoCanvas
// Concept: A multi-layered pixel canvas on the blockchain where users pay to paint pixels, minting an NFT for each stroke.
// The canvas is a shared, evolving asset influenced by user actions and timed environmental effects.

// Inherits: ERC721Enumerable, ERC2981, Ownable, ERC721URIStorage

// State Variables:
// - canvasState: Stores the color for each pixel (x, y) on each layer.
// - layerConfigs: Stores properties for each layer (name, cost multiplier, etc.).
// - brushStrokeDetails: Stores details for each minted Brush Stroke NFT (location, color, layer, timestamp, painter).
// - _nextTokenId: Counter for Brush Stroke NFTs.
// - canvasWidth, canvasHeight: Dimensions of the canvas.
// - paintingFee: Base cost to paint a pixel.
// - treasury: Address to receive painting fees.
// - paused: Flag to pause painting.
// - lastEnvironmentalEffectTime: Timestamp of the last effect application.
// - environmentalEffectInterval: Time between environmental effects.
// - environmentalEffectParams: Parameters for the active environmental effect.
// - _royaltyInfo: ERC2981 royalty details.
// - _baseTokenURI: Base URI for NFT metadata.
// - lastPaintedPixelInfo: Stores info about the last painted pixel for easy lookup.

// Events:
// - PixelPainted: Emitted when a pixel color is successfully updated.
// - BrushStrokeMinted: Emitted when a new Brush Stroke NFT is minted.
// - PaintingFeeUpdated: Emitted when the painting fee changes.
// - TreasuryUpdated: Emitted when the treasury address changes.
// - LayerAdded: Emitted when a new layer is defined.
// - LayerPropertiesUpdated: Emitted when a layer's properties change.
// - CanvasResized: Emitted when canvas dimensions change.
// - PaintingPaused: Emitted when painting is paused.
// - PaintingUnpaused: Emitted when painting is unpaused.
// - EnvironmentalEffectTriggered: Emitted when an environmental effect is applied.
// - RoyaltyInfoUpdated: Emitted when royalty information changes.
// - BaseTokenURIUpdated: Emitted when the base token URI changes.

// Functions (20+ Required):
// 1.  constructor: Initializes contract state.
// 2.  paintPixel: Allows users to paint and mint Brush Stroke NFT.
// 3.  getPixelColor: Gets color at a specific canvas location and layer. (View)
// 4.  getBrushStrokeDetails: Gets details of a Brush Stroke NFT. (View)
// 5.  checkAndApplyEnvironmentalEffect: Triggers environmental effect based on time.
// 6.  getCanvasDimensions: Gets canvas width and height. (View)
// 7.  getPaintingFee: Gets the base painting fee. (View)
// 8.  getTotalLayers: Gets the number of defined layers. (View)
// 9.  getLayerProperties: Gets properties for a specific layer. (View)
// 10. getTotalBrushStrokes: Gets the total number of Brush Stroke NFTs minted. (View)
// 11. getBrushStrokeCountByPainter: Gets the number of NFTs owned by an address (ERC721Enumerable balanceOf). (View)
// 12. getLastPaintedPixelInfo: Gets details of the very last pixel painted. (View)
// 13. setPaintingFee: Updates the base painting fee (Owner).
// 14. setTreasury: Updates the treasury address (Owner).
// 15. addLayer: Defines a new canvas layer (Owner).
// 16. setLayerProperties: Modifies properties of an existing layer (Owner).
// 17. resizeCanvas: Changes canvas dimensions (Owner).
// 18. pausePainting: Pauses painting (Owner).
// 19. unpausePainting: Unpauses painting (Owner).
// 20. withdrawFunds: Withdraws contract balance to treasury (Owner).
// 21. setEnvironmentalEffectInterval: Sets time between effects (Owner).
// 22. setEnvironmentalEffectParams: Sets parameters for effects (Owner).
// 23. supportsInterface: ERC165 standard. (View)
// 24. tokenURI: ERC721 metadata URI generation. (View)
// 25. royaltyInfo: ERC2981 royalty details calculation. (View)
// 26. setRoyaltyInfo: Configures ERC2981 royalties (Owner).
// 27. setBaseTokenURI: Sets the base URI for token metadata (Owner).
// 28. balanceOf: ERC721Enumerable standard. (View)
// 29. ownerOf: ERC721 standard. (View)
// 30. getApproved: ERC721 standard. (View)
// 31. isApprovedForAll: ERC721 standard. (View)
// 32. approve: ERC721 standard.
// 33. setApprovalForAll: ERC721 standard.
// 34. transferFrom: ERC721 standard.
// 35. safeTransferFrom: ERC721 standard.
// 36. totalSupply: ERC721Enumerable standard. (View)
// 37. tokenByIndex: ERC721Enumerable standard. (View)
// 38. tokenOfOwnerByIndex: ERC721Enumerable standard. (View)
// 39. getEnvironmentalEffectInterval: Gets the effect interval. (View)
// 40. getEnvironmentalEffectParams: Gets the effect parameters. (View)
// 41. getLastEnvironmentalEffectTime: Gets the last effect timestamp. (View)

contract CryptoCanvas is ERC721Enumerable, ERC2981, ERC721URIStorage, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _brushStrokeIds;

    // State storage: x => y => layer => color (RGB bytes3)
    mapping(uint256 x => mapping(uint256 y => mapping(uint256 layer => bytes3 color))) private _canvasState;

    struct LayerConfig {
        string name;
        uint256 paintingCostMultiplier; // Multiplier applied to basePaintingFee (e.g., 1000 = 1x)
    }
    LayerConfig[] public layerConfigs;

    struct BrushStroke {
        uint256 x;
        uint256 y;
        uint256 layer;
        bytes3 color;
        uint64 timestamp;
        address painter;
    }
    mapping(uint256 tokenId => BrushStroke) private _brushStrokeDetails;

    uint256 public canvasWidth;
    uint256 public canvasHeight;
    uint256 public paintingFee; // Base fee in wei
    address payable public treasury;

    bool public paused;

    uint256 public lastEnvironmentalEffectTime;
    uint256 public environmentalEffectInterval;
    uint256 public environmentalEffectParams; // Generic parameter for effects

    struct RoyaltyInfo {
        address receiver;
        uint96 feeNumerator; // e.g., 500 for 5% (500/10000)
    }
    RoyaltyInfo private _royaltyInfo;

    struct LastPaintedPixelInfo {
        bool exists; // To check if any pixel has been painted yet
        uint256 x;
        uint256 y;
        uint256 layer;
        bytes3 color;
        uint64 timestamp;
        address painter;
        uint256 tokenId;
    }
    LastPaintedPixelInfo public lastPaintedPixelInfo;


    // Events
    event PixelPainted(uint256 indexed tokenId, address indexed painter, uint256 x, uint256 y, uint256 layer, bytes3 color);
    event BrushStrokeMinted(uint256 indexed tokenId, address indexed painter, uint256 x, uint256 y, uint256 layer, bytes3 color);
    event PaintingFeeUpdated(uint256 oldFee, uint256 newFee);
    event TreasuryUpdated(address indexed oldTreasury, address indexed newTreasury);
    event LayerAdded(uint256 indexed layerId, string name, uint256 paintingCostMultiplier);
    event LayerPropertiesUpdated(uint256 indexed layerId, string name, uint256 paintingCostMultiplier);
    event CanvasResized(uint256 oldWidth, uint256 oldHeight, uint256 newWidth, uint256 newHeight);
    event PaintingPaused();
    event PaintingUnpaused();
    event EnvironmentalEffectTriggered(uint256 timestamp, uint256 effectType, uint256 effectParams, uint256 affectedX, uint256 affectedY, uint256 affectedSize); // Added affected area info
    event RoyaltyInfoUpdated(address indexed receiver, uint96 feeNumerator);
    event BaseTokenURIUpdated(string newURI);


    // 1. Constructor
    constructor(
        uint256 initialWidth,
        uint256 initialHeight,
        uint256 basePaintingFee,
        address payable initialTreasury,
        string memory name,
        string memory symbol
    ) ERC721(name, symbol) Ownable(msg.sender) {
        require(initialWidth > 0 && initialHeight > 0, "Invalid dimensions");
        require(initialTreasury != address(0), "Invalid treasury address");

        canvasWidth = initialWidth;
        canvasHeight = initialHeight;
        paintingFee = basePaintingFee;
        treasury = initialTreasury;
        paused = false;
        lastEnvironmentalEffectTime = block.timestamp; // Initialize effect timer
        environmentalEffectInterval = 7 days; // Default interval
        environmentalEffectParams = 0; // Default params

        // Add a default base layer
        layerConfigs.push(LayerConfig("Base Layer", 1000)); // Multiplier 1000 = 1x

        emit PaintingFeeUpdated(0, paintingFee);
        emit TreasuryUpdated(address(0), treasury);
        emit LayerAdded(0, "Base Layer", 1000);
    }

    // --- Core Painting & Interaction ---

    // 2. paintPixel
    /// @notice Paints a pixel on the canvas at specified coordinates and layer. Mints a Brush Stroke NFT.
    /// @param x X coordinate (0 to canvasWidth - 1).
    /// @param y Y coordinate (0 to canvasHeight - 1).
    /// @param layer Layer index (0 to totalLayers - 1).
    /// @param color RGB color bytes3 (e.g., 0xFF0000 for red).
    function paintPixel(uint256 x, uint256 y, uint256 layer, bytes3 color) external payable {
        require(!paused, "Painting is paused");
        require(x < canvasWidth && y < canvasHeight, "Coordinates out of bounds");
        require(layer < layerConfigs.length, "Invalid layer");

        uint256 cost = (paintingFee * layerConfigs[layer].paintingCostMultiplier) / 1000;
        require(msg.value >= cost, "Insufficient payment");

        // Send excess funds back
        if (msg.value > cost) {
            payable(msg.sender).transfer(msg.value - cost);
        }

        // Transfer painting fee to treasury
        (bool success, ) = treasury.call{value: cost}("");
        require(success, "Failed to send funds to treasury");

        // Update canvas state
        _canvasState[x][y][layer] = color;

        // Mint Brush Stroke NFT
        _brushStrokeIds.increment();
        uint256 newTokenId = _brushStrokeIds.current();

        _safeMint(msg.sender, newTokenId);

        _brushStrokeDetails[newTokenId] = BrushStroke({
            x: x,
            y: y,
            layer: layer,
            color: color,
            timestamp: uint64(block.timestamp),
            painter: msg.sender
        });

        // Update last painted pixel info
        lastPaintedPixelInfo = LastPaintedPixelInfo({
            exists: true,
            x: x,
            y: y,
            layer: layer,
            color: color,
            timestamp: uint64(block.timestamp),
            painter: msg.sender,
            tokenId: newTokenId
        });


        emit PixelPainted(newTokenId, msg.sender, x, y, layer, color);
        emit BrushStrokeMinted(newTokenId, msg.sender, x, y, layer, color);
    }

    // 3. getPixelColor
    /// @notice Gets the current color of a pixel on a specific layer.
    /// @param x X coordinate.
    /// @param y Y coordinate.
    /// @param layer Layer index.
    /// @return The color bytes3 (RGB). Returns 0x000000 (black) if never painted.
    function getPixelColor(uint256 x, uint256 y, uint256 layer) public view returns (bytes3) {
        require(x < canvasWidth && y < canvasHeight, "Coordinates out of bounds");
        require(layer < layerConfigs.length, "Invalid layer");
        return _canvasState[x][y][layer];
    }

    // 4. getBrushStrokeDetails
    /// @notice Gets the stored details for a Brush Stroke NFT.
    /// @param tokenId The ID of the Brush Stroke NFT.
    /// @return The BrushStroke struct containing its details.
    function getBrushStrokeDetails(uint256 tokenId) public view returns (BrushStroke memory) {
        require(_exists(tokenId), "Brush Stroke does not exist"); // Uses ERC721's _exists internal function
        return _brushStrokeDetails[tokenId];
    }

    // 5. checkAndApplyEnvironmentalEffect
    /// @notice Checks if the environmental effect interval has passed and applies the effect to a small random area.
    /// Can be called by anyone to potentially trigger the effect.
    function checkAndApplyEnvironmentalEffect() external {
        if (block.timestamp >= lastEnvironmentalEffectTime + environmentalEffectInterval) {
            lastEnvironmentalEffectTime = block.timestamp; // Update timestamp *before* applying

            // Simple pseudo-randomness based on block data and contract state
            uint256 seed = uint256(keccak256(abi.encodePacked(
                block.timestamp,
                block.difficulty,
                block.coinbase,
                _brushStrokeIds.current(), // Include contract state
                uint256(uint160(msg.sender)) // Include caller for uniqueness
            )));

            // Determine a random starting coordinate and a small effect size
            uint256 affectedX = seed % canvasWidth;
            uint256 affectedY = (seed / canvasWidth) % canvasHeight;
            uint256 affectedSize = 5; // Affect a 5x5 pixel area (adjust as needed)

            // Apply a simple effect (e.g., fade to grey or shift hue)
            // This is a placeholder for more complex effect logic
            for (uint256 x = 0; x < affectedSize; x++) {
                for (uint256 y = 0; y < affectedSize; y++) {
                     // Wrap coordinates around the canvas edges
                    uint256 currentX = (affectedX + x) % canvasWidth;
                    uint256 currentY = (affectedY + y) % canvasHeight;

                    for (uint256 layer = 0; layer < layerConfigs.length; layer++) {
                        bytes3 currentColor = _canvasState[currentX][currentY][layer];
                        // Example effect: Simple fade towards grey
                        // (r+g+b)/3 gives average brightness
                        uint256 avg = (uint256(uint8(currentColor[0])) + uint256(uint8(currentColor[1])) + uint256(uint8(currentColor[2]))) / 3;
                        bytes3 newColor = bytes3(uint8((uint256(uint8(currentColor[0])) + avg) / 2),
                                                 uint8((uint256(uint8(currentColor[1])) + avg) / 2),
                                                 uint8((uint256(uint8(currentColor[2])) + avg) / 2));
                        // Apply new color (this overwrite is part of the effect)
                        _canvasState[currentX][currentY][layer] = newColor;
                         // Note: This does *not* mint new BrushStroke NFTs for the effect changes.
                         // Effect changes are distinct from user painting.
                    }
                }
            }

            // Effect type 0 for simple decay, can be expanded later based on environmentalEffectParams
            emit EnvironmentalEffectTriggered(block.timestamp, 0, environmentalEffectParams, affectedX, affectedY, affectedSize);
        }
    }

    // --- View Functions ---

    // 6. getCanvasDimensions
    /// @notice Gets the current canvas dimensions.
    /// @return width The canvas width.
    /// @return height The canvas height.
    function getCanvasDimensions() public view returns (uint256 width, uint256 height) {
        return (canvasWidth, canvasHeight);
    }

    // 7. getPaintingFee
    /// @notice Gets the current base painting fee.
    /// @return The base painting fee in wei.
    function getPaintingFee() public view returns (uint256) {
        return paintingFee;
    }

    // 8. getTotalLayers
    /// @notice Gets the total number of layers defined on the canvas.
    /// @return The count of layers.
    function getTotalLayers() public view returns (uint256) {
        return layerConfigs.length;
    }

    // 9. getLayerProperties
    /// @notice Gets the properties for a specific layer.
    /// @param layer The layer index.
    /// @return name The layer name.
    /// @return paintingCostMultiplier The cost multiplier for this layer.
    function getLayerProperties(uint256 layer) public view returns (string memory name, uint256 paintingCostMultiplier) {
        require(layer < layerConfigs.length, "Invalid layer");
        return (layerConfigs[layer].name, layerConfigs[layer].paintingCostMultiplier);
    }

    // 10. getTotalBrushStrokes
    /// @notice Gets the total number of Brush Stroke NFTs minted.
    /// @return The total supply of NFTs.
    function getTotalBrushStrokes() public view returns (uint256) {
        return _brushStrokeIds.current();
    }

    // 11. getBrushStrokeCountByPainter (Inherited from ERC721Enumerable)
    /// @notice Gets the number of Brush Stroke NFTs owned by an address.
    /// @param painter The address to query.
    /// @return The number of NFTs owned by the address.
    // function balanceOf(address painter) public view override returns (uint256) { ... }

    // 12. getLastPaintedPixelInfo
    /// @notice Gets details about the most recently painted pixel.
    /// @return The LastPaintedPixelInfo struct. `exists` is false if no pixel has been painted yet.
    function getLastPaintedPixelInfo() public view returns (LastPaintedPixelInfo memory) {
        return lastPaintedPixelInfo;
    }


    // --- Admin Functions (Owner Only) ---

    // 13. setPaintingFee
    /// @notice Owner-only: Sets the base painting fee.
    /// @param newFee The new base painting fee in wei.
    function setPaintingFee(uint256 newFee) external onlyOwner {
        uint256 oldFee = paintingFee;
        paintingFee = newFee;
        emit PaintingFeeUpdated(oldFee, newFee);
    }

    // 14. setTreasury
    /// @notice Owner-only: Sets the treasury address where fees are sent.
    /// @param newTreasury The new treasury address.
    function setTreasury(address payable newTreasury) external onlyOwner {
        require(newTreasury != address(0), "Invalid treasury address");
        address oldTreasury = treasury;
        treasury = newTreasury;
        emit TreasuryUpdated(oldTreasury, newTreasury);
    }

    // 15. addLayer
    /// @notice Owner-only: Adds a new layer to the canvas.
    /// @param name The name of the new layer.
    /// @param paintingCostMultiplier The cost multiplier for this layer (e.g., 2000 for 2x cost).
    function addLayer(string memory name, uint256 paintingCostMultiplier) external onlyOwner {
        layerConfigs.push(LayerConfig(name, paintingCostMultiplier));
        emit LayerAdded(layerConfigs.length - 1, name, paintingCostMultiplier);
    }

    // 16. setLayerProperties
    /// @notice Owner-only: Modifies properties of an existing layer.
    /// @param layer The index of the layer to modify.
    /// @param name The new name for the layer.
    /// @param paintingCostMultiplier The new cost multiplier.
    function setLayerProperties(uint256 layer, string memory name, uint256 paintingCostMultiplier) external onlyOwner {
        require(layer < layerConfigs.length, "Invalid layer index");
        layerConfigs[layer] = LayerConfig(name, paintingCostMultiplier);
        emit LayerPropertiesUpdated(layer, name, paintingCostMultiplier);
    }

    // 17. resizeCanvas
    /// @notice Owner-only: Changes the canvas dimensions.
    /// @dev Warning: This function updates dimensions but does NOT migrate or delete existing pixel data.
    /// Pixels outside the new bounds will be inaccessible via `getPixelColor` and new pixels can be painted.
    /// Consider a migration strategy if state persistence is needed across resize.
    /// @param newWidth The new canvas width.
    /// @param newHeight The new canvas height.
    function resizeCanvas(uint256 newWidth, uint256 newHeight) external onlyOwner {
        require(newWidth > 0 && newHeight > 0, "Invalid new dimensions");
        uint256 oldWidth = canvasWidth;
        uint256 oldHeight = canvasHeight;
        canvasWidth = newWidth;
        canvasHeight = newHeight;
        emit CanvasResized(oldWidth, oldHeight, newWidth, newHeight);
    }

    // 18. pausePainting
    /// @notice Owner-only: Pauses painting functionality.
    function pausePainting() external onlyOwner {
        require(!paused, "Painting is already paused");
        paused = true;
        emit PaintingPaused();
    }

    // 19. unpausePainting
    /// @notice Owner-only: Unpauses painting functionality.
    function unpausePainting() external onlyOwner {
        require(paused, "Painting is not paused");
        paused = false;
        emit PaintingUnpaused();
    }

    // 20. withdrawFunds
    /// @notice Owner-only: Withdraws the contract's Ether balance to the treasury.
    function withdrawFunds() external onlyOwner {
        uint256 balance = address(this).balance;
        (bool success, ) = treasury.call{value: balance}("");
        require(success, "Withdrawal failed");
    }

    // 21. setEnvironmentalEffectInterval
    /// @notice Owner-only: Sets the time interval between environmental effect applications.
    /// @param interval The new interval in seconds.
    function setEnvironmentalEffectInterval(uint256 interval) external onlyOwner {
        environmentalEffectInterval = interval;
    }

     // 22. setEnvironmentalEffectParams
    /// @notice Owner-only: Sets a generic parameter for environmental effects.
    /// @param params The new parameter value. Interpretation depends on effect logic.
    function setEnvironmentalEffectParams(uint256 params) external onlyOwner {
        environmentalEffectParams = params;
    }

    // 26. setRoyaltyInfo
    /// @notice Owner-only: Sets the default royalty information for the NFT collection.
    /// @param receiver The address receiving royalties.
    /// @param feeNumerator The numerator for the royalty fee (denominator is 10000).
    function setRoyaltyInfo(address receiver, uint96 feeNumerator) external onlyOwner {
        _royaltyInfo = RoyaltyInfo(receiver, feeNumerator);
        emit RoyaltyInfoUpdated(receiver, feeNumerator);
    }

    // 27. setBaseTokenURI
    /// @notice Owner-only: Sets the base URI for token metadata.
    /// @param baseURI The new base URI string.
    function setBaseTokenURI(string memory baseURI) external onlyOwner {
        _setBaseURI(baseURI);
        emit BaseTokenURIUpdated(baseURI);
    }

    // --- ERC721, ERC2981 Overrides & View Functions ---

    // 23. supportsInterface (Overrides ERC721, ERC2981, ERC165)
    /// @notice ERC165: Queries whether a contract implements an interface.
    function supportsInterface(bytes4 interfaceId) public view override(ERC721Enumerable, ERC2981, ERC721URIStorage) returns (bool) {
        return interfaceId == type(ERC721).interfaceId ||
               interfaceId == type(ERC721Enumerable).interfaceId ||
               interfaceId == type(ERC2981).interfaceId ||
               interfaceId == type(ERC721URIStorage).interfaceId || // Add if using URIStorage directly
               super.supportsInterface(interfaceId);
    }

    // 24. tokenURI (Overrides ERC721URIStorage)
    /// @notice ERC721: Gets the metadata URI for a token.
    /// @param tokenId The token ID.
    /// @return The metadata URI.
    function tokenURI(uint256 tokenId) public view override(ERC721, ERC721URIStorage) returns (string memory) {
         require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        // Construct URI based on _baseURI and token ID, potentially appending file extension
        // Or, construct a data URI directly here if metadata is simple/on-chain
        // For this example, we'll rely on _baseURI pointing to off-chain metadata
        // and append the token ID and ".json".
        string memory base = _baseURI();
        return string(abi.encodePacked(base, Strings.toString(tokenId), ".json"));
    }

    // Internal helper function for base URI
    function _baseURI() internal view override(ERC721, ERC721URIStorage) returns (string memory) {
        // ERC721URIStorage manages _baseTokenURI internally
        return super._baseURI();
    }

    // 25. royaltyInfo (Overrides ERC2981)
    /// @notice ERC2981: Gets the royalty information for a token sale.
    /// @param tokenId The token ID.
    /// @param salePrice The price of the sale.
    /// @return receiver The address receiving the royalty.
    /// @return royaltyAmount The amount of royalty in wei.
    function royaltyInfo(uint256 tokenId, uint256 salePrice) public view override(ERC2981) returns (address receiver, uint256 royaltyAmount) {
        // _exists check is usually needed, but ERC2981 base doesn't require it
        // For simplicity, we use the collection-level royalty info
        receiver = _royaltyInfo.receiver;
        // Calculate royalty: salePrice * feeNumerator / 10000
        royaltyAmount = (salePrice * _royaltyInfo.feeNumerator) / 10000;
    }

    // 39. getEnvironmentalEffectInterval
    /// @notice Gets the current interval between environmental effects.
    /// @return The interval in seconds.
    function getEnvironmentalEffectInterval() public view returns (uint256) {
        return environmentalEffectInterval;
    }

     // 40. getEnvironmentalEffectParams
    /// @notice Gets the current parameter for environmental effects.
    /// @return The parameter value.
    function getEnvironmentalEffectParams() public view returns (uint256) {
        return environmentalEffectParams;
    }

    // 41. getLastEnvironmentalEffectTime
    /// @notice Gets the timestamp of the last environmental effect application.
    /// @return The timestamp in seconds.
    function getLastEnvironmentalEffectTime() public view returns (uint256) {
        return lastEnvironmentalEffectTime;
    }


    // --- Inherited ERC721Enumerable Functions (already count towards 20+) ---
    // 28. balanceOf(address owner) public view override returns (uint256)
    // 29. ownerOf(uint256 tokenId) public view override returns (address)
    // 30. getApproved(uint256 tokenId) public view override returns (address operator)
    // 31. isApprovedForAll(address owner, address operator) public view override returns (bool)
    // 32. approve(address to, uint256 tokenId) public override
    // 33. setApprovalForAll(address operator, bool _approved) public override
    // 34. transferFrom(address from, address to, uint256 tokenId) public override
    // 35. safeTransferFrom(address from, address to, uint256 tokenId) public override
    // 36. totalSupply() public view override returns (uint256)
    // 37. tokenByIndex(uint256 index) public view override returns (uint256)
    // 38. tokenOfOwnerByIndex(address owner, uint256 index) public view override returns (uint256)


    // Fallback function to receive Ether if paintPixel is not called (e.g., misdirected sends)
    // It will revert if not from owner attempting withdraw or if painting is not paused and not enough value
    receive() external payable {
        // Optional: handle unexpected deposits, e.g., by transferring to treasury
        // require(msg.sender == owner() || paused || msg.value >= paintingFee, "Unexpected ether received");
        // if (msg.sender != owner()) {
        //     (bool success, ) = treasury.call{value: msg.value}("");
        //     require(success, "Failed to send unexpected funds to treasury");
        // }
        // Or simply revert to indicate it's unexpected unless specific conditions met
        if (msg.sender != owner() && msg.value > 0) {
             revert("Unexpected Ether received");
        }
    }
}
```

**Explanation of Advanced/Creative Aspects:**

1.  **Layered Canvas State (`_canvasState`):** Instead of just one color per pixel, each pixel location `(x, y)` can have multiple `bytes3` colors stored, one for each `layer`. This allows for complex visual compositions where layers could represent foreground, background, textures, effects, etc. The interpretation of layers is left to front-end display logic, but the data structure supports it on-chain.
2.  **Brush Stroke NFTs (`BrushStroke`, `_brushStrokeDetails`, `ERC721Enumerable`):** Every successful `paintPixel` call mints a unique NFT. This NFT isn't just proof of *ownership* of a pixel, but proof of *having made a specific contribution* (a 'brush stroke') at a certain time, location, with a color. This creates a historical record and allows attributing specific artistic actions to individuals. `ERC721Enumerable` adds the ability to list all tokens owned by an address, useful for galleries or showcasing contributions.
3.  **Dynamic Environmental Effects (`checkAndApplyEnvironmentalEffect`, `lastEnvironmentalEffectTime`, `environmentalEffectInterval`, `environmentalEffectParams`):** This introduces an external, timed force that modifies the canvas state independent of direct user painting. The effect logic (`checkAndApplyEnvironmentalEffect`) is triggered by *any* user calling the function after the interval has passed. The effect applied is a simple placeholder (fading a random area to grey), but this could be expanded based on `environmentalEffectParams` to include complex on-chain generative art logic, color shifts, decay, growth patterns, etc., making the canvas an evolving entity. Applying the effect only to a *small random area* keeps the gas cost of this function manageable.
4.  **Provenance Tracking (`BrushStroke` struct details):** The details stored within the `BrushStroke` struct (x, y, layer, color, timestamp, painter) are immutable once minted. This provides strong provenance for every change ever made to the canvas state via user interaction.
5.  **Decentralized Effect Trigger:** `checkAndApplyEnvironmentalEffect` being callable by anyone incentivizes users (or bots) to keep the canvas evolving according to the environmental rules without requiring the owner to manually trigger it.
6.  **ERC2981 Royalties:** Standardized way for the contract or original painter (though here it's per-collection) to receive royalties when Brush Stroke NFTs are resold on marketplaces.

This contract provides a foundation for a complex, collaborative, and evolving on-chain art project, going beyond a simple static NFT collection or basic pixel board by introducing layers, contribution-based NFTs, and dynamic, time-driven effects.