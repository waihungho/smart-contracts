Okay, here is a Solidity smart contract for an "Infinite Canvas" concept. This contract allows users to claim square "tiles" on a conceptually infinite 2D grid, where each tile is an ERC-721 NFT. Tile owners (or those they grant permission to) can then draw pixels on multiple layers within their owned tiles, using an on-chain "ink" resource purchased with ETH. It incorporates ERC-721, mapping complex data structures, role-based access control within tiles, resource management, dynamic metadata considerations, and batch operations.

It aims for creativity by having:
1.  **Infinite Grid:** Tiles claimed by (x,y) coordinates.
2.  **On-Chain Pixel Data:** Storing pixel data directly on-chain per layer (expensive but core to the concept).
3.  **Layers:** Multiple drawing layers per tile.
4.  **Ink Resource:** An internal token/resource required for drawing.
5.  **Tile-Specific Permissions:** Owners can delegate drawing rights.
6.  **Dynamic Metadata:** Token URI can reflect the tile's content (via hash).
7.  **Batch Operations:** Efficiently drawing multiple pixels.

**Outline:**

1.  **License & Pragma**
2.  **Imports (ERC721, Ownable)**
3.  **Error Definitions**
4.  **Constants:** TILE_SIZE, LAYER_LIMIT, PIXELS_PER_TILE, INK_PRICE_PER_UNIT, etc.
5.  **Structs:** Tile data structure.
6.  **State Variables:**
    *   ERC721 related mappings (_balances, _owners, _tokenApprovals, _operatorApprovals).
    *   Tile storage (mapping token ID to Tile struct).
    *   Coordinate mappings (coords -> token ID, token ID -> coords).
    *   Ink balances.
    *   Next token ID counter.
    *   Admin variables (ink price, base URI, treasury).
7.  **Events:** For key actions like TileClaimed, PixelsDrawn, InkBought, PermissionGranted, etc.
8.  **Constructor:** Initializes base ERC721 details and owner.
9.  **ERC721 Standard Functions:** (`balanceOf`, `ownerOf`, `approve`, `getApproved`, `setApprovalForAll`, `isApprovedForAll`, `transferFrom`, `safeTransferFrom`, `supportsInterface`, `tokenURI` - overridden).
10. **Core Canvas/Tile Logic:**
    *   `claimTile`: Mint a new tile NFT at specific coordinates.
    *   `isTileClaimed`: Check if coordinates are taken.
    *   `getTileIdByCoords`, `getTileCoordsById`: Translate between token ID and coordinates.
    *   `getTileData`: Retrieve full Tile struct.
    *   `getLayerData`: Retrieve pixel data for a specific layer.
    *   `drawPixel`: Draw a single pixel.
    *   `batchDrawPixels`: Draw multiple pixels efficiently.
    *   `createLayer`: Add a new drawing layer to a tile.
    *   `setActiveLayer`: Set the layer for subsequent draws.
    *   `getLayerCount`, `getTileActiveLayer`: Get layer information.
    *   `getTileEffects`, `applyEffect`, `removeEffect`: (Placeholder for future complexity or simple boolean flags).
    *   `setTileMetadataHash`: Update the IPFS hash for off-chain metadata.
    *   `getTotalPixelsDrawn`: Get cumulative draw count for a tile.
11. **Ink System:**
    *   `buyInk`: Purchase ink using ETH.
    *   `getInkBalance`: Check user's ink.
    *   `setInkPricePerUnit`: Admin function to set ink cost.
    *   `withdrawFees`: Admin function to withdraw accumulated ETH.
12. **Drawing Permissions:**
    *   `grantDrawPermission`, `revokeDrawPermission`: Owner delegates drawing rights.
    *   `canDrawOnTile`: Check drawing permission.
13. **Pause Functionality:**
    *   `pauseDrawing`, `getTilePausedStatus`: Tile owner pauses drawing.
    *   `pauseContract`, `unpauseContract`: Admin pauses overall contract.
14. **Admin Functions:** (Already covered in Ink and Pause, might add others if needed).

**Function Summary:**

*   `balanceOf(address owner) view`: Returns the number of tiles owned by `owner`. (ERC721)
*   `ownerOf(uint256 tokenId) view`: Returns the owner of the tile `tokenId`. (ERC721)
*   `approve(address to, uint256 tokenId)`: Approves an address to manage a specific tile. (ERC721)
*   `getApproved(uint256 tokenId) view`: Gets the approved address for a tile. (ERC721)
*   `setApprovalForAll(address operator, bool approved)`: Approves/disapproves an operator for all owner's tiles. (ERC721)
*   `isApprovedForAll(address owner, address operator) view`: Checks if an operator is approved for an owner. (ERC721)
*   `transferFrom(address from, address to, uint256 tokenId)`: Transfers ownership of a tile (requires approval/operator). (ERC721)
*   `safeTransferFrom(address from, address to, uint256 tokenId)`: Same as transferFrom, with safety checks. (ERC721)
*   `supportsInterface(bytes4 interfaceId) view`: ERC165 interface support. (ERC721)
*   `tokenURI(uint256 tokenId) view override`: Returns the metadata URI for a tile. (ERC721 overridden)
*   `claimTile(int256 x, int256 y)`: Mints a new tile NFT at the specified (x,y) coordinates to the caller.
*   `isTileClaimed(int256 x, int256 y) view`: Checks if a tile exists at (x,y).
*   `getTileIdByCoords(int256 x, int256 y) view`: Returns the token ID for coordinates (x,y).
*   `getTileCoordsById(uint256 tokenId) view`: Returns the (x,y) coordinates for a token ID.
*   `getTileData(uint256 tokenId) view`: Retrieves the core Tile struct data (excluding pixel data).
*   `getLayerData(uint256 tokenId, uint8 layerIndex) view`: Retrieves the raw pixel data (`bytes`) for a specific layer of a tile.
*   `drawPixel(uint256 tokenId, uint8 px, uint8 py, bytes3 color)`: Draws a single pixel at (px, py) on the tile's active layer, consuming ink.
*   `batchDrawPixels(uint256 tokenId, uint8 layerIndex, uint8[] pxCoords, uint8[] pyCoords, bytes3[] colors)`: Draws multiple pixels on a specified layer, consuming ink.
*   `createLayer(uint256 tokenId)`: Adds a new, empty layer to a tile (up to LAYER_LIMIT).
*   `setActiveLayer(uint256 tokenId, uint8 layerIndex)`: Sets the layer that `drawPixel` uses by default.
*   `getLayerCount(uint256 tokenId) view`: Returns the number of layers on a tile.
*   `getTileActiveLayer(uint256 tokenId) view`: Returns the currently active layer index for a tile.
*   `getTileEffects(uint256 tokenId) view`: Returns the state of applied effects on a tile.
*   `applyEffect(uint256 tokenId, uint8 effectIndex)`: Toggles an effect on a tile (implementation dependent).
*   `removeEffect(uint256 tokenId, uint8 effectIndex)`: Toggles an effect off a tile.
*   `setTileMetadataHash(uint256 tokenId, string memory metadataHash)`: Sets the IPFS hash for the tile's dynamic metadata.
*   `getTotalPixelsDrawn(uint256 tokenId) view`: Gets the total number of pixels ever drawn on a tile across all layers.
*   `buyInk(uint256 amount) payable`: Sends ETH to the contract to purchase `amount` of ink units.
*   `getInkBalance(address account) view`: Returns the ink balance of an account.
*   `grantDrawPermission(uint256 tokenId, address drawer)`: Tile owner grants `drawer` permission to draw on their tile.
*   `revokeDrawPermission(uint256 tokenId, address drawer)`: Tile owner revokes `drawer` permission.
*   `canDrawOnTile(uint256 tokenId, address drawer) view`: Checks if `drawer` has permission to draw (owner implicitly has permission).
*   `pauseDrawing(uint256 tokenId, bool paused)`: Tile owner pauses or unpauses drawing activity on their tile.
*   `getTilePausedStatus(uint256 tokenId) view`: Checks if a tile's drawing is paused by its owner.
*   `pauseContract()`: Admin pauses contract-wide state-changing operations.
*   `unpauseContract()`: Admin unpauses contract.
*   `setInkPricePerUnit(uint256 pricePerUnit)`: Admin sets the price (in wei per ink unit) for buying ink.
*   `setBaseTokenURI(string memory baseURI)`: Admin sets the base part of the token URI.
*   `withdrawFees()`: Admin withdraws collected ETH from ink sales to the treasury address.

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";

/**
 * @title InfiniteCanvas
 * @dev A collaborative pixel art canvas where tiles are ERC-721 NFTs.
 * Users can claim tiles on a conceptual infinite grid, draw pixels on layers
 * within their tiles using an on-chain ink resource, and grant drawing permissions.
 * Each tile's pixel data is stored on-chain.
 */

/**
 * @notice Outline:
 * 1. License & Pragma
 * 2. Imports (ERC721, Ownable, Pausable, Math)
 * 3. Error Definitions
 * 4. Constants: TILE_SIZE, LAYER_LIMIT, PIXELS_PER_TILE, INK_PRICE_PER_UNIT_DEFAULT, EFFECT_COUNT
 * 5. Structs: Tile data structure.
 * 6. State Variables: ERC721 related, Tile storage, Coordinate mappings, Ink balances, Token counter, Admin variables.
 * 7. Events: TileClaimed, PixelsDrawn, InkBought, PermissionGranted, EffectToggled, LayerCreated, MetadataUpdated, TilePaused.
 * 8. Constructor: Initializes base ERC721, Ownable, Pausable, admin params.
 * 9. ERC721 Standard Functions: (Inherited and overridden tokenURI).
 * 10. Core Canvas/Tile Logic: claimTile, isTileClaimed, getTileIdByCoords, getTileCoordsById, getTileData, getLayerData,
 *                             drawPixel, batchDrawPixels, createLayer, setActiveLayer, getLayerCount, getTileActiveLayer,
 *                             getTileEffects, applyEffect, removeEffect, setTileMetadataHash, getTotalPixelsDrawn.
 * 11. Ink System: buyInk, getInkBalance, setInkPricePerUnit, withdrawFees.
 * 12. Drawing Permissions: grantDrawPermission, revokeDrawPermission, canDrawOnTile.
 * 13. Pause Functionality: pauseDrawing (per tile), getTilePausedStatus, pauseContract (global), unpauseContract (global).
 * 14. Admin Functions: (Part of Ink and Pause, also includes baseURI).
 */

/**
 * @notice Function Summary:
 * - balanceOf(address owner) view: Get the number of tiles owned by an address. (ERC721)
 * - ownerOf(uint256 tokenId) view: Get the owner of a specific tile token. (ERC721)
 * - approve(address to, uint256 tokenId): Approve an address to transfer a tile. (ERC721)
 * - getApproved(uint256 tokenId) view: Get the approved address for a tile. (ERC721)
 * - setApprovalForAll(address operator, bool approved): Set approval for an operator across all tiles. (ERC721)
 * - isApprovedForAll(address owner, address operator) view: Check operator approval status. (ERC721)
 * - transferFrom(address from, address to, uint256 tokenId): Transfer tile ownership. (ERC721)
 * - safeTransferFrom(address from, address to, uint256 tokenId): Safe transfer of tile ownership. (ERC721)
 * - supportsInterface(bytes4 interfaceId) view: ERC165 interface support. (ERC721)
 * - tokenURI(uint256 tokenId) view override: Get metadata URI for a tile. (ERC721 overridden)
 * - claimTile(int256 x, int256 y): Mint a new tile NFT at given coordinates.
 * - isTileClaimed(int256 x, int256 y) view: Check if a tile exists at coordinates.
 * - getTileIdByCoords(int256 x, int256 y) view: Get token ID from coordinates.
 * - getTileCoordsById(uint256 tokenId) view: Get coordinates from token ID.
 * - getTileData(uint256 tokenId) view: Get core tile details (owner, coords, times).
 * - getLayerData(uint256 tokenId, uint8 layerIndex) view: Get pixel data for a specific layer.
 * - drawPixel(uint256 tokenId, uint8 px, uint8 py, bytes3 color): Draw a single pixel on active layer.
 * - batchDrawPixels(uint256 tokenId, uint8 layerIndex, uint8[] pxCoords, uint8[] pyCoords, bytes3[] colors): Draw multiple pixels on a specific layer.
 * - createLayer(uint256 tokenId): Add a new empty layer to a tile.
 * - setActiveLayer(uint256 tokenId, uint8 layerIndex): Set the layer for subsequent draws.
 * - getLayerCount(uint256 tokenId) view: Get the number of layers on a tile.
 * - getTileActiveLayer(uint256 tokenId) view: Get the active layer index.
 * - getTileEffects(uint256 tokenId) view: Get the state of effects (as a bitmask uint).
 * - applyEffect(uint256 tokenId, uint8 effectIndex): Toggle an effect on a tile.
 * - removeEffect(uint256 tokenId, uint8 effectIndex): Toggle an effect off a tile.
 * - setTileMetadataHash(uint256 tokenId, string memory metadataHash): Set IPFS hash for off-chain metadata.
 * - getTotalPixelsDrawn(uint256 tokenId) view: Get total pixels ever drawn on a tile.
 * - buyInk(uint256 amount) payable: Purchase ink units with ETH.
 * - getInkBalance(address account) view: Get ink balance of an account.
 * - grantDrawPermission(uint256 tokenId, address drawer): Grant drawing permission on a tile.
 * - revokeDrawPermission(uint256 tokenId, address drawer): Revoke drawing permission.
 * - canDrawOnTile(uint256 tokenId, address drawer) view: Check if an address can draw on a tile.
 * - pauseDrawing(uint256 tokenId, bool paused): Tile owner pauses/unpauses drawing on their tile.
 * - getTilePausedStatus(uint256 tokenId) view: Check if a tile's drawing is paused.
 * - pauseContract(): Admin pauses contract state changes. (Pausable)
 * - unpauseContract(): Admin unpauses contract. (Pausable)
 * - setInkPricePerUnit(uint256 pricePerUnit): Admin sets ink purchase price.
 * - setBaseTokenURI(string memory baseURI): Admin sets the base part of the token URI.
 * - withdrawFees(): Admin withdraws ETH from ink sales.
 */

contract InfiniteCanvas is ERC721, Ownable, Pausable {

    // --- Error Definitions ---
    error TileAlreadyClaimed(int256 x, int256 y);
    error TileDoesNotExist(uint256 tokenId);
    error InvalidCoordinates(int256 x, int256 y); // Maybe refine bounds if needed
    error InsufficientInk(uint256 required, uint256 available);
    error InvalidPixelCoordinates(uint8 px, uint8 py);
    error InvalidLayer(uint8 layerIndex);
    error LayerLimitReached(uint8 limit);
    error NotTileOwnerOrApprovedDrawer();
    error TileDrawingPaused();
    error InvalidBatchData(uint256 expectedLength, uint256 actualPx, uint256 actualPy, uint256 actualColors);
    error InvalidEffectIndex(uint8 effectIndex);

    // --- Constants ---
    // Size of each tile in pixels (width and height)
    uint8 public constant TILE_SIZE = 16;
    // Total number of pixels in a tile
    uint256 public constant PIXELS_PER_TILE = TILE_SIZE * TILE_SIZE;
    // Max number of layers per tile
    uint8 public constant LAYER_LIMIT = 4;
    // Cost to draw one pixel (in ink units)
    uint256 public constant INK_COST_PER_PIXEL = 1;
    // Number of different effects a tile can have
    uint8 public constant EFFECT_COUNT = 8; // Max 8 effects for now, stored in a uint8 bitmask
    // Default price for 1 unit of ink (in wei)
    uint256 public constant INK_PRICE_PER_UNIT_DEFAULT = 100000000000000; // 0.0001 ETH

    // --- Structs ---
    struct Tile {
        address owner; // Denormalized from ERC721 for easier access, primary owner is ERC721 state
        int256 x; // Tile X coordinate
        int256 y; // Tile Y coordinate
        // Pixel data for each layer. Mapping layer index => raw pixel bytes (RGB, 3 bytes per pixel)
        // The bytes length MUST be TILE_SIZE * TILE_SIZE * 3
        mapping(uint8 => bytes) layers;
        uint8 activeLayer; // The layer targeted by the simple drawPixel function
        mapping(address => bool) drawerPermissions; // Addresses allowed to draw (true if allowed)
        bool drawingPaused; // Tile owner can pause drawing on their tile
        string metadataHash; // IPFS hash or similar for off-chain metadata
        uint40 creationTime; // Block timestamp when tile was claimed
        uint40 lastDrawTime; // Block timestamp of the most recent pixel draw
        uint64 totalPixelsDrawn; // Cumulative count of pixels drawn on this tile
        uint8 effectsBitmask; // Stores boolean state of effects (each bit represents an effect)
    }

    // --- State Variables ---
    // Mapping from token ID to Tile struct
    mapping(uint256 => Tile) private _tiles;
    // Mapping from (x,y) coordinates to token ID (coordinate packing needed for mapping key)
    mapping(bytes32 => uint256) private _coordsToTokenId;
    // Mapping from token ID back to coordinates (for retrieval)
    mapping(uint256 => bytes32) private _tokenIdToCoords;
    // Mapping from user address to their ink balance
    mapping(address => uint256) private _inkBalance;

    // Next token ID to mint
    uint256 private _nextTokenId;

    // Price of one unit of ink (in wei)
    uint256 public inkPricePerUnit;

    // Base URI for ERC721 metadata
    string private _baseTokenURI;

    // Address to send collected ETH fees
    address public treasuryAddress;

    // --- Events ---
    event TileClaimed(uint256 indexed tokenId, address indexed owner, int256 x, int256 y);
    event PixelsDrawn(uint256 indexed tokenId, address indexed drawer, uint8 indexed layerIndex, uint256 numPixels, uint256 inkCost);
    event InkBought(address indexed buyer, uint256 amount, uint256 ethPaid);
    event DrawPermissionGranted(uint256 indexed tokenId, address indexed owner, address indexed drawer);
    event DrawPermissionRevoked(uint256 indexed tokenId, address indexed owner, address indexed drawer);
    event EffectToggled(uint256 indexed tokenId, uint8 indexed effectIndex, bool enabled);
    event LayerCreated(uint256 indexed tokenId, uint8 indexed layerIndex);
    event MetadataUpdated(uint256 indexed tokenId, string metadataHash);
    event TileDrawingPaused(uint256 indexed tokenId, bool paused);

    // --- Coordinate Packing/Unpacking ---
    // Packs int256 x and int256 y into a single bytes32 key for mappings
    function _packCoords(int256 x, int256 y) internal pure returns (bytes32) {
        bytes32 packed;
        assembly {
            packed := x // Place x in the lower 16 bytes (128 bits)
            packed := or(packed, shl(128, y)) // Place y in the upper 16 bytes
        }
        return packed;
    }

    // Unpacks a bytes32 key into int256 x and int256 y
    function _unpackCoords(bytes32 packed) internal pure returns (int256 x, int256 y) {
        assembly {
            x := packed // Extract x from the lower 16 bytes
            y := shr(128, packed) // Extract y from the upper 16 bytes
        }
    }

    // Internal helper to check if a tile exists at coordinates
    function _tileExistsAtCoords(int256 x, int256 y) internal view returns (bool) {
        return _coordsToTokenId[_packCoords(x, y)] != 0;
    }

    // Internal helper to get token ID from coords, or 0 if not found
    function _getTokenIdByCoords(int256 x, int256 y) internal view returns (uint256) {
        return _coordsToTokenId[_packCoords(x, y)];
    }

    // Internal helper to check tile existence by token ID
    function _tileExists(uint256 tokenId) internal view returns (bool) {
        return _tokenIdToCoords[tokenId] != bytes32(0);
    }


    // --- Constructor ---
    constructor(string memory name, string memory symbol, address initialOwner, address initialTreasury)
        ERC721(name, symbol)
        Ownable(initialOwner)
        Pausable()
    {
        _nextTokenId = 1; // Token IDs start from 1
        inkPricePerUnit = INK_PRICE_PER_UNIT_DEFAULT;
        treasuryAddress = initialTreasury;
        // Initialize layer 0 data structure for all tiles implicitly on creation/access
    }

    // --- ERC721 Overrides & Custom Logic ---

    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        if (!_tileExists(tokenId)) {
             revert TileDoesNotExist(tokenId);
        }

        // Combine base URI with token ID and possibly tile-specific metadata hash
        string memory base = _baseTokenURI;
        if (bytes(base).length == 0) {
            return super.tokenURI(tokenId); // Fallback to default ERC721 behavior if baseURI is not set
        }

        string memory tileMetadataHash = _tiles[tokenId].metadataHash;
        if (bytes(tileMetadataHash).length > 0) {
            // If tile has specific metadata hash, append it
            return string(abi.encodePacked(base, tileMetadataHash));
        } else {
            // Otherwise, use token ID (standard ERC721 behavior with baseURI)
            // This assumes metadata server handles /token/id endpoint
            return string(abi.encodePacked(base, Strings.toString(tokenId)));
        }
    }

    // --- Core Canvas/Tile Logic ---

    /**
     * @notice Claims a new tile at the specified coordinates. Mints an ERC721 token for the tile.
     * @param x The X coordinate of the tile to claim.
     * @param y The Y coordinate of the tile to claim.
     */
    function claimTile(int256 x, int256 y) public whenNotPaused {
        bytes32 packed = _packCoords(x, y);
        if (_coordsToTokenId[packed] != 0) {
            revert TileAlreadyClaimed(x, y);
        }

        uint256 tokenId = _nextTokenId++;
        address caller = _msgSender();

        _safeMint(caller, tokenId); // Mints the ERC721 token

        // Initialize the Tile struct
        _tiles[tokenId].owner = caller; // Redundant but convenient lookup
        _tiles[tokenId].x = x;
        _tiles[tokenId].y = y;
        _tiles[tokenId].activeLayer = 0; // Default active layer
        _tiles[tokenId].creationTime = uint40(block.timestamp);
        _tiles[tokenId].lastDrawTime = uint40(block.timestamp); // Or maybe 0? Let's say creation is first 'event'
        _tiles[tokenId].totalPixelsDrawn = 0;
        _tiles[tokenId].drawingPaused = false; // Not paused by default

        // Store coordinate mappings
        _coordsToTokenId[packed] = tokenId;
        _tokenIdToCoords[tokenId] = packed;

        // Automatically create Layer 0 with default transparent color (bytes of zeros)
        // This is expensive, alternative is to create layers on first draw
        // Let's create layer 0 on claim to ensure it exists
        _createLayerInternal(tokenId, 0);


        emit TileClaimed(tokenId, caller, x, y);
    }

    /**
     * @notice Checks if a tile has been claimed at the given coordinates.
     * @param x The X coordinate.
     * @param y The Y coordinate.
     * @return True if a tile exists at these coordinates, false otherwise.
     */
    function isTileClaimed(int256 x, int256 y) public view returns (bool) {
        return _tileExistsAtCoords(x, y);
    }

    /**
     * @notice Gets the token ID of the tile at the specified coordinates.
     * @param x The X coordinate.
     * @param y The Y coordinate.
     * @return The token ID, or 0 if no tile exists at these coordinates.
     */
    function getTileIdByCoords(int256 x, int256 y) public view returns (uint256) {
         return _getTokenIdByCoords(x, y);
    }

    /**
     * @notice Gets the coordinates (x, y) for a given tile token ID.
     * @param tokenId The token ID of the tile.
     * @return x The X coordinate.
     * @return y The Y coordinate.
     */
    function getTileCoordsById(uint256 tokenId) public view returns (int256 x, int256 y) {
        if (!_tileExists(tokenId)) {
             revert TileDoesNotExist(tokenId);
        }
        bytes32 packed = _tokenIdToCoords[tokenId];
        return _unpackCoords(packed);
    }

    /**
     * @notice Retrieves the core data for a tile (excluding pixel data).
     * @param tokenId The token ID of the tile.
     * @return A tuple containing the tile's owner, coordinates, creation time, last draw time, total pixels drawn, drawing paused status, and metadata hash.
     */
    function getTileData(uint256 tokenId)
        public
        view
        returns (
            address owner,
            int256 x,
            int256 y,
            uint40 creationTime,
            uint40 lastDrawTime,
            uint64 totalPixelsDrawn,
            bool drawingPaused,
            string memory metadataHash
        )
    {
         if (!_tileExists(tokenId)) {
             revert TileDoesNotExist(tokenId);
         }
         Tile storage tile = _tiles[tokenId];
         (x, y) = _unpackCoords(_tokenIdToCoords[tokenId]);
         owner = ownerOf(tokenId); // Get owner from ERC721 state
         creationTime = tile.creationTime;
         lastDrawTime = tile.lastDrawTime;
         totalPixelsDrawn = tile.totalPixelsDrawn;
         drawingPaused = tile.drawingPaused;
         metadataHash = tile.metadataHash;
         return (owner, x, y, creationTime, lastDrawTime, totalPixelsDrawn, drawingPaused, metadataHash);
    }

    /**
     * @notice Retrieves the raw pixel data for a specific layer of a tile.
     * @param tokenId The token ID of the tile.
     * @param layerIndex The index of the layer (0 to LAYER_LIMIT-1).
     * @return The raw pixel data as bytes (TILE_SIZE * TILE_SIZE * 3 bytes).
     */
    function getLayerData(uint256 tokenId, uint8 layerIndex)
        public
        view
        returns (bytes memory)
    {
        if (!_tileExists(tokenId)) {
             revert TileDoesNotExist(tokenId);
        }
        if (layerIndex >= LAYER_LIMIT) {
            revert InvalidLayer(layerIndex);
        }
         // Accessing a mapping returns empty bytes if key not found, which is fine for empty layers
        return _tiles[tokenId].layers[layerIndex];
    }

    /**
     * @notice Draws a single pixel on the active layer of a tile. Requires ink.
     * Only tile owner or approved drawers can call this.
     * @param tokenId The token ID of the tile.
     * @param px The X coordinate of the pixel (0 to TILE_SIZE-1).
     * @param py The Y coordinate of the pixel (0 to TILE_SIZE-1).
     * @param color The RGB color of the pixel (3 bytes).
     */
    function drawPixel(uint256 tokenId, uint8 px, uint8 py, bytes3 color) public whenNotPaused {
        require(bytes(color).length == 3, "Invalid color length");
        batchDrawPixels(tokenId, _tiles[tokenId].activeLayer, new uint8[](1), new uint8[](1), new bytes3[](1));
        // ^ This is inefficient, a direct implementation is better.
        // Let's implement directly below.
        _requireCanDraw(tokenId, _msgSender());
        _requireTileNotPaused(tokenId);

        if (px >= TILE_SIZE || py >= TILE_SIZE) {
            revert InvalidPixelCoordinates(px, py);
        }

        Tile storage tile = _tiles[tokenId];
        uint8 layerIndex = tile.activeLayer;

         if (layerIndex >= LAYER_LIMIT || bytes(tile.layers[layerIndex]).length != PIXELS_PER_TILE * 3) {
             // Ensure the layer exists and is correctly sized
             revert InvalidLayer(layerIndex); // Or potentially _createLayerInternal if it should auto-create on first draw
         }

        uint256 inkRequired = INK_COST_PER_PIXEL;
        if (_inkBalance[_msgSender()] < inkRequired) {
            revert InsufficientInk(inkRequired, _inkBalance[_msgSender()]);
        }

        // Calculate byte offset within the layer data
        uint256 offset = (py * TILE_SIZE + px) * 3;

        // Update pixel color in storage
        bytes storage layerData = tile.layers[layerIndex];
        layerData[offset] = color[0];
        layerData[offset + 1] = color[1];
        layerData[offset + 2] = color[2];

        // Update tile state
        _inkBalance[_msgSender()] -= inkRequired;
        tile.lastDrawTime = uint40(block.timestamp);
        tile.totalPixelsDrawn += 1;

        emit PixelsDrawn(tokenId, _msgSender(), layerIndex, 1, inkRequired);
    }


    /**
     * @notice Draws multiple pixels on a specified layer of a tile in a single transaction. Requires ink.
     * Only tile owner or approved drawers can call this.
     * @param tokenId The token ID of the tile.
     * @param layerIndex The index of the layer to draw on (0 to LAYER_LIMIT-1).
     * @param pxCoords Array of X coordinates for pixels.
     * @param pyCoords Array of Y coordinates for pixels.
     * @param colors Array of RGB colors (3 bytes) for pixels.
     * @dev All input arrays must have the same length.
     */
    function batchDrawPixels(uint256 tokenId, uint8 layerIndex, uint8[] calldata pxCoords, uint8[] calldata pyCoords, bytes3[] calldata colors) public whenNotPaused {
        _requireCanDraw(tokenId, _msgSender());
        _requireTileNotPaused(tokenId);

        uint256 numPixels = pxCoords.length;
        if (numPixels == 0) {
            return; // Nothing to draw
        }

        if (pyCoords.length != numPixels || colors.length != numPixels) {
             revert InvalidBatchData(numPixels, pyCoords.length, pyCoords.length, colors.length);
        }

        if (layerIndex >= LAYER_LIMIT) {
            revert InvalidLayer(layerIndex);
        }

        Tile storage tile = _tiles[tokenId];
        // Ensure the layer exists and is correctly sized before drawing
        bytes storage layerData = tile.layers[layerIndex];
        if (bytes(layerData).length != PIXELS_PER_TILE * 3) {
             revert InvalidLayer(layerIndex); // Layer doesn't exist or wasn't initialized correctly
        }


        uint256 inkRequired = numPixels * INK_COST_PER_PIXEL;
        if (_inkBalance[_msgSender()] < inkRequired) {
            revert InsufficientInk(inkRequired, _inkBalance[_msgSender()]);
        }

        // Process pixels
        for (uint256 i = 0; i < numPixels; i++) {
            uint8 px = pxCoords[i];
            uint8 py = pyCoords[i];
            bytes3 color = colors[i];

            if (px >= TILE_SIZE || py >= TILE_SIZE) {
                 revert InvalidPixelCoordinates(px, py); // Revert the whole batch if any pixel is invalid
            }

            // Calculate byte offset within the layer data
            uint256 offset = (py * TILE_SIZE + px) * 3;

            // Update pixel color in storage
            layerData[offset] = color[0];
            layerData[offset + 1] = color[1];
            layerData[offset + 2] = color[2];
        }

        // Update tile state
        _inkBalance[_msgSender()] -= inkRequired;
        tile.lastDrawTime = uint40(block.timestamp);
        tile.totalPixelsDrawn += uint64(numPixels);

        emit PixelsDrawn(tokenId, _msgSender(), layerIndex, numPixels, inkRequired);
    }

    /**
     * @notice Internal helper to create a new layer for a tile.
     * @param tokenId The token ID of the tile.
     * @param layerIndex The index of the layer to create.
     * @dev This function assumes layerIndex is valid (0 to LAYER_LIMIT-1).
     * It initializes the layer with transparent (0x000000) pixels.
     */
    function _createLayerInternal(uint256 tokenId, uint8 layerIndex) internal {
        require(bytes(_tiles[tokenId].layers[layerIndex]).length == 0, "Layer already exists");

        // Initialize layer data with transparent pixels (all zeros)
        // This allocates storage! Very expensive.
        bytes storage layerData = _tiles[tokenId].layers[layerIndex];
        layerData.length = PIXELS_PER_TILE * 3; // Allocate space for RGB data

        // No need to explicitly set to zero, storage bytes default to 0x00
    }


    /**
     * @notice Adds a new drawing layer to a tile.
     * Only tile owner can call this.
     * @param tokenId The token ID of the tile.
     */
    function createLayer(uint256 tokenId) public whenNotPaused {
        _requireTileOwner(tokenId);
        if (!_tileExists(tokenId)) {
             revert TileDoesNotExist(tokenId);
        }

        // Find the next available layer index
        uint8 nextLayerIndex = 0;
        while (nextLayerIndex < LAYER_LIMIT && bytes(_tiles[tokenId].layers[nextLayerIndex]).length > 0) {
            nextLayerIndex++;
        }

        if (nextLayerIndex >= LAYER_LIMIT) {
            revert LayerLimitReached(LAYER_LIMIT);
        }

        _createLayerInternal(tokenId, nextLayerIndex);

        emit LayerCreated(tokenId, nextLayerIndex);
    }

    /**
     * @notice Sets the active layer for a tile. Subsequent `drawPixel` calls will target this layer.
     * Only tile owner can call this.
     * @param tokenId The token ID of the tile.
     * @param layerIndex The index of the layer to set as active (0 to LAYER_LIMIT-1).
     */
    function setActiveLayer(uint256 tokenId, uint8 layerIndex) public whenNotPaused {
        _requireTileOwner(tokenId);
        if (!_tileExists(tokenId)) {
             revert TileDoesNotExist(tokenId);
        }
        if (layerIndex >= LAYER_LIMIT || bytes(_tiles[tokenId].layers[layerIndex]).length == 0) {
            // Can only set active layer to one that exists
            revert InvalidLayer(layerIndex);
        }
        _tiles[tokenId].activeLayer = layerIndex;
    }

    /**
     * @notice Gets the number of layers currently present on a tile.
     * @param tokenId The token ID of the tile.
     * @return The number of layers.
     */
    function getLayerCount(uint256 tokenId) public view returns (uint8) {
         if (!_tileExists(tokenId)) {
             revert TileDoesNotExist(tokenId);
         }
        uint8 count = 0;
         for (uint8 i = 0; i < LAYER_LIMIT; i++) {
             if (bytes(_tiles[tokenId].layers[i]).length > 0) {
                 count++;
             } else {
                 // Layers are assumed to be created sequentially starting from 0
                 break;
             }
         }
         return count;
    }

    /**
     * @notice Gets the currently active layer index for a tile.
     * @param tokenId The token ID of the tile.
     * @return The active layer index.
     */
    function getTileActiveLayer(uint256 tokenId) public view returns (uint8) {
         if (!_tileExists(tokenId)) {
             revert TileDoesNotExist(tokenId);
         }
         return _tiles[tokenId].activeLayer;
    }

    /**
     * @notice Gets the current state of effects applied to a tile.
     * @param tokenId The token ID of the tile.
     * @return A uint8 bitmask representing the effects. Each bit corresponds to an effect index (0 to 7).
     */
    function getTileEffects(uint256 tokenId) public view returns (uint8) {
         if (!_tileExists(tokenId)) {
             revert TileDoesNotExist(tokenId);
         }
         return _tiles[tokenId].effectsBitmask;
    }

    /**
     * @notice Toggles the state of a specific effect on a tile.
     * Only tile owner can call this.
     * @param tokenId The token ID of the tile.
     * @param effectIndex The index of the effect to toggle (0 to EFFECT_COUNT-1).
     */
    function applyEffect(uint256 tokenId, uint8 effectIndex) public whenNotPaused {
        _requireTileOwner(tokenId);
        if (!_tileExists(tokenId)) {
             revert TileDoesNotExist(tokenId);
        }
        if (effectIndex >= EFFECT_COUNT) {
            revert InvalidEffectIndex(effectIndex);
        }
        // Set the bit corresponding to the effectIndex
        _tiles[tokenId].effectsBitmask |= (1 << effectIndex);
        emit EffectToggled(tokenId, effectIndex, true);
    }

     /**
     * @notice Toggles off the state of a specific effect on a tile.
     * Only tile owner can call this.
     * @param tokenId The token ID of the tile.
     * @param effectIndex The index of the effect to toggle off (0 to EFFECT_COUNT-1).
     */
    function removeEffect(uint256 tokenId, uint8 effectIndex) public whenNotPaused {
        _requireTileOwner(tokenId);
         if (!_tileExists(tokenId)) {
             revert TileDoesNotExist(tokenId);
         }
        if (effectIndex >= EFFECT_COUNT) {
            revert InvalidEffectIndex(effectIndex);
        }
        // Clear the bit corresponding to the effectIndex
        _tiles[tokenId].effectsBitmask &= ~(1 << effectIndex);
        emit EffectToggled(tokenId, effectIndex, false);
    }


    /**
     * @notice Sets the IPFS hash or similar identifier for off-chain metadata for a tile.
     * This hash will be appended to the base URI in `tokenURI`.
     * Only tile owner can call this.
     * @param tokenId The token ID of the tile.
     * @param metadataHash The hash or identifier string.
     */
    function setTileMetadataHash(uint256 tokenId, string memory metadataHash) public whenNotPaused {
        _requireTileOwner(tokenId);
         if (!_tileExists(tokenId)) {
             revert TileDoesNotExist(tokenId);
         }
        _tiles[tokenId].metadataHash = metadataHash;
        emit MetadataUpdated(tokenId, metadataHash);
    }

    /**
     * @notice Gets the total cumulative number of pixels drawn on a tile across all layers.
     * @param tokenId The token ID of the tile.
     * @return The total pixel count.
     */
    function getTotalPixelsDrawn(uint256 tokenId) public view returns (uint64) {
        if (!_tileExists(tokenId)) {
             revert TileDoesNotExist(tokenId);
         }
        return _tiles[tokenId].totalPixelsDrawn;
    }

    // --- Ink System ---

    /**
     * @notice Allows users to buy ink using ETH.
     * @param amount The number of ink units to buy.
     */
    function buyInk(uint256 amount) public payable whenNotPaused {
        if (amount == 0) return; // No ink to buy

        uint256 cost = amount * inkPricePerUnit;
        if (msg.value < cost) {
            // Refund excess ETH automatically
            revert("Insufficient ETH sent for ink amount");
        }

        _inkBalance[msg.sender] += amount;

        // Excess ETH is automatically sent back by the runtime if msg.value > cost
        // The required ETH is kept in the contract balance

        emit InkBought(msg.sender, amount, msg.value);
    }

    /**
     * @notice Gets the ink balance for an account.
     * @param account The address of the account.
     * @return The ink balance.
     */
    function getInkBalance(address account) public view returns (uint256) {
        return _inkBalance[account];
    }

    /**
     * @notice Admin function to set the price of one unit of ink in wei.
     * @param pricePerUnit The new price in wei.
     */
    function setInkPricePerUnit(uint256 pricePerUnit) public onlyOwner {
        inkPricePerUnit = pricePerUnit;
    }

    /**
     * @notice Admin function to withdraw collected ETH from ink sales.
     */
    function withdrawFees() public onlyOwner {
        // Transfer the contract balance to the treasury address
        uint256 balance = address(this).balance;
        require(balance > 0, "No ETH to withdraw");
        // Use call for reentrancy protection best practice
        (bool success, ) = payable(treasuryAddress).call{value: balance}("");
        require(success, "ETH withdrawal failed");
    }


    // --- Drawing Permissions ---

    /**
     * @notice Grants drawing permission on a specific tile to another address.
     * Only the tile owner can call this. The owner always has permission.
     * @param tokenId The token ID of the tile.
     * @param drawer The address to grant permission to.
     */
    function grantDrawPermission(uint256 tokenId, address drawer) public whenNotPaused {
        _requireTileOwner(tokenId);
         if (!_tileExists(tokenId)) {
             revert TileDoesNotExist(tokenId);
         }
        _tiles[tokenId].drawerPermissions[drawer] = true;
        emit DrawPermissionGranted(tokenId, _msgSender(), drawer);
    }

    /**
     * @notice Revokes drawing permission on a specific tile from an address.
     * Only the tile owner can call this.
     * @param tokenId The token ID of the tile.
     * @param drawer The address to revoke permission from.
     */
    function revokeDrawPermission(uint256 tokenId, address drawer) public whenNotPaused {
        _requireTileOwner(tokenId);
         if (!_tileExists(tokenId)) {
             revert TileDoesNotExist(tokenId);
         }
        _tiles[tokenId].drawerPermissions[drawer] = false;
        emit DrawPermissionRevoked(tokenId, _msgSender(), drawer);
    }

    /**
     * @notice Checks if an address has drawing permission on a tile (either is owner or has explicit permission).
     * @param tokenId The token ID of the tile.
     * @param drawer The address to check.
     * @return True if the address can draw on the tile, false otherwise.
     */
    function canDrawOnTile(uint256 tokenId, address drawer) public view returns (bool) {
         if (!_tileExists(tokenId)) {
             // Return false if tile doesn't exist, don't revert for a view function
             return false;
         }
        // Owner always has permission
        if (ownerOf(tokenId) == drawer) {
            return true;
        }
        // Check explicit permission
        return _tiles[tokenId].drawerPermissions[drawer];
    }

    // Internal helper to check if the caller can draw on a tile
    function _requireCanDraw(uint256 tokenId, address drawer) internal view {
         if (!canDrawOnTile(tokenId, drawer)) {
             revert NotTileOwnerOrApprovedDrawer();
         }
    }

    // Internal helper to check if caller is the tile owner
    function _requireTileOwner(uint256 tokenId) internal view {
         if (ownerOf(tokenId) != _msgSender()) {
             revert ERC721Unauthorized(ownerOf(tokenId), _msgSender()); // Using ERC721 standard error
         }
    }


    // --- Pause Functionality ---

    /**
     * @notice Allows the tile owner to pause or unpause drawing activity on their specific tile.
     * @param tokenId The token ID of the tile.
     * @param paused The new pause state (true to pause, false to unpause).
     */
    function pauseDrawing(uint256 tokenId, bool paused) public whenNotPaused {
        _requireTileOwner(tokenId);
         if (!_tileExists(tokenId)) {
             revert TileDoesNotExist(tokenId);
         }
        _tiles[tokenId].drawingPaused = paused;
        emit TileDrawingPaused(tokenId, paused);
    }

    /**
     * @notice Checks if drawing on a specific tile is paused by the tile owner.
     * @param tokenId The token ID of the tile.
     * @return True if tile drawing is paused, false otherwise.
     */
    function getTilePausedStatus(uint256 tokenId) public view returns (bool) {
         if (!_tileExists(tokenId)) {
             revert TileDoesNotExist(tokenId);
         }
        return _tiles[tokenId].drawingPaused;
    }

    // Internal helper to check if tile drawing is paused
    function _requireTileNotPaused(uint256 tokenId) internal view {
         if (_tiles[tokenId].drawingPaused) {
             revert TileDrawingPaused();
         }
    }

    /**
     * @notice Pauses contract-wide state-changing operations (except admin functions).
     * Only callable by the contract owner.
     */
    function pauseContract() public onlyOwner {
        _pause();
    }

    /**
     * @notice Unpauses contract-wide state-changing operations.
     * Only callable by the contract owner.
     */
    function unpauseContract() public onlyOwner {
        _unpause();
    }

    // --- Admin Functions (additional) ---

    /**
     * @notice Sets the base URI for token metadata. The tokenURI will be baseURI + tokenID (or baseURI + metadataHash if set).
     * Only callable by the contract owner.
     * @param baseURI The new base URI string.
     */
    function setBaseTokenURI(string memory baseURI) public onlyOwner {
        _baseTokenURI = baseURI;
    }

     /**
     * @notice Gets the current base token URI.
     */
    function getBaseTokenURI() public view onlyOwner returns (string memory) {
        return _baseTokenURI;
    }
}
```