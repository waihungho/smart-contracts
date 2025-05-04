Okay, let's design an advanced, creative, and trendy smart contract concept. How about a "Decentralized Ephemeral Art Canvas"?

This contract will represent a collaborative digital canvas stored on the blockchain. Users can "place" small digital tiles (like pixels or small blocks) on this canvas. Each tile has an owner and an expiration time. If a tile isn't "refreshed" by its owner (or a delegate) before it expires, it disappears from the active canvas state, making the space available for someone else. The entire canvas state is represented by a single, dynamic ERC721 NFT (token ID 0), reflecting the collective, ever-changing artwork.

This combines:
1.  **NFTs:** A single, dynamic NFT representing the entire evolving artwork.
2.  **On-chain Data:** Storing the state of individual tiles directly on the blockchain.
3.  **Ephemerality/Time-based Mechanics:** Tiles decay over time, requiring interaction (refreshing).
4.  **Collaboration/Competition:** Users contribute, maintain, and potentially compete for space.
5.  **Delegation:** Owners can delegate refresh/placement rights.
6.  **Configuration:** Admin controls for canvas parameters and tile types.
7.  **Fees:** A small fee for placing/refreshing tiles, collected by the contract owner (or managed by future governance).

It avoids simply duplicating standard DeFi or NFT minting contracts by focusing on dynamic, interactive, and time-sensitive on-chain state that constitutes a collective digital asset.

---

## Smart Contract: Decentralized Ephemeral Art Canvas

**Concept:** A dynamic, on-chain digital canvas where users place time-limited tiles. Tiles decay unless refreshed. The cumulative state is represented by a single ERC721 NFT.

**Outline:**

1.  **State Variables:**
    *   Canvas dimensions (width, height).
    *   Tile data (position, owner, color/data, expiration time, tile type, internal ID).
    *   Mappings for quick lookup (position -> tile ID, tile ID -> tile data).
    *   Configuration parameters (costs, decay times, tile types).
    *   Counters for tile IDs and total placed tiles.
    *   Collected fees.
    *   Delegation mapping.
    *   ERC721 metadata base URI.
    *   Canvas NFT (Token ID 0).

2.  **Structs:**
    *   `Tile`: Holds data for an individual tile.
    *   `TileTypeConfig`: Defines cost and decay for different tile types.

3.  **Events:** Signify major actions (tile placed, refreshed, removed, params updated, withdrawal).

4.  **Modifiers:** Restrict access (e.g., `onlyOwner`, `isActiveTileOwnerOrDelegate`).

5.  **Core Functions:**
    *   Placing new tiles (`placeTile`, `batchPlaceTiles`).
    *   Refreshing existing tiles (`refreshTile`, `batchRefreshTiles`).
    *   Removing tiles (`removeTile`, `batchRemoveTiles`).
    *   Modifying tile data (`setTileData`).

6.  **Delegation Functions:**
    *   Granting/revoking placement/refresh permissions for specific positions/tile IDs.

7.  **Configuration Functions (Admin/Owner):**
    *   Setting canvas dimensions, tile costs, decay times, tile type definitions, base URI.
    *   Withdrawing collected fees.

8.  **View/Pure Functions:**
    *   Retrieving tile information by ID or position.
    *   Checking tile status (active, expired).
    *   Getting canvas parameters and tile type info.
    *   Counting tiles.
    *   ERC721 standard functions (`tokenURI`, `ownerOf`, `balanceOf`, etc. for Token ID 0).

9.  **ERC721 Integration:** The contract *is* an ERC721, managing only token ID 0.

10. **Ownable Integration:** For administrative controls.

**Function Summary (20+ Functions):**

1.  `constructor(uint256 initialWidth, uint256 initialHeight, string memory name, string memory symbol)`: Deploys the contract, sets initial dimensions, mints token ID 0 (the canvas NFT), and sets ERC721 name/symbol.
2.  `placeTile(uint256 x, uint256 y, bytes32 tileData, uint8 tileTypeIndex) payable`: Places a new tile at specified coordinates. Requires payment based on `tileTypeIndex` cost. Overwrites expired tiles or empty spots. Sets owner, data, type, and calculates expiration.
3.  `refreshTile(uint256 tileId) payable`: Extends the life of an active tile by adding default decay time to its expiration. Requires payment and caller to be owner or delegate.
4.  `removeTile(uint256 tileId)`: Permanently removes a tile from the canvas. Requires caller to be owner or delegate.
5.  `setTileData(uint256 tileId, bytes32 newTileData)`: Modifies the data/color of an existing tile. Requires caller to be owner or delegate.
6.  `batchPlaceTiles(uint256[] calldata xCoords, uint256[] calldata yCoords, bytes32[] calldata tileDataArray, uint8[] calldata tileTypeIndices) payable`: Places multiple new tiles in a single transaction.
7.  `batchRefreshTiles(uint256[] calldata tileIds) payable`: Refreshes multiple tiles in a single transaction.
8.  `batchRemoveTiles(uint256[] calldata tileIds)`: Removes multiple tiles in a single transaction.
9.  `delegatePlacementPermission(address delegatee, uint256 x, uint256 y)`: Allows the caller (if they own the tile at x,y or the spot is empty and they have general canvas rights - *simplification: owner can delegate for their spots*) to grant `delegatee` permission to place/refresh *at that specific position*. (Alternative: delegate permission for a specific tile ID if tile exists). Let's go with position-based delegation for simplicity when placing.
10. `revokeDelegatePlacementPermission(address delegatee, uint256 x, uint256 y)`: Revokes the delegation.
11. `getDelegatePermission(address delegator, address delegatee, uint256 x, uint256 y) view returns (bool)`: Checks if `delegatee` has permission delegated by `delegator` for position (x,y).
12. `setTileTypeInfo(uint8 tileTypeIndex, uint256 cost, uint256 decayDuration) onlyOwner`: Sets or updates the configuration for a specific tile type.
13. `setCanvasDimensions(uint256 newWidth, uint256 newHeight) onlyOwner`: Sets new canvas dimensions (careful with existing tiles outside bounds - maybe disallow reducing size or prune tiles). Let's add a safety requiring new size >= old size or a migration plan (too complex for this example, let's just allow increase).
14. `setTileCost(uint8 tileTypeIndex, uint256 newCost) onlyOwner`: Updates the placement/refresh cost for a tile type.
15. `setDefaultDecayTime(uint8 tileTypeIndex, uint256 newDecayDuration) onlyOwner`: Updates the default decay duration for a tile type.
16. `setBaseURI(string memory newBaseURI) onlyOwner`: Sets the base URI for the ERC721 token metadata.
17. `withdrawFunds(address payable recipient, uint256 amount) onlyOwner`: Allows the contract owner to withdraw collected fees.
18. `getTileInfoById(uint256 tileId) view returns (uint256 x, uint256 y, address owner, bytes32 tileData, uint256 expirationTimestamp, uint8 tileTypeIndex, bool active)`: Retrieves all information for a given tile ID. Returns `active` status derived from timestamp.
19. `getTileIdAtPosition(uint256 x, uint256 y) view returns (uint256)`: Gets the internal tile ID located at a specific position (0 if empty).
20. `getTileInfoAtPosition(uint256 x, uint256 y) view returns (uint256 tileId, address owner, bytes32 tileData, uint256 expirationTimestamp, uint8 tileTypeIndex, bool active)`: Combines lookup by position and retrieving info. Returns default/zero values if empty.
21. `isTileActive(uint256 tileId) view returns (bool)`: Checks if a tile exists and its expiration time is in the future.
22. `getTilesByOwner(address ownerAddress) view returns (uint256[] memory)`: Returns an array of tile IDs owned by a specific address (Note: Can be gas-intensive for many tiles).
23. `getCanvasDimensions() view returns (uint256 width, uint256 height)`: Returns current canvas size.
24. `getTileTypeInfo(uint8 tileTypeIndex) view returns (uint256 cost, uint256 decayDuration)`: Returns config for a tile type.
25. `getCurrentTileCount() view returns (uint256)`: Returns the number of *currently active* tiles.
26. `getTotalTilesPlaced() view returns (uint256)`: Returns the total number of tiles ever placed (including expired/removed ones).
27. `getLastActivityTime() view returns (uint256)`: Timestamp of the last `placeTile` or `refreshTile` action.
28. `tokenURI(uint256 tokenId) view returns (string memory)`: ERC721 metadata URI for the canvas NFT (token ID 0).
29. `ownerOf(uint256 tokenId) view returns (address)`: ERC721 standard - returns owner of token ID 0.
30. `transferFrom(address from, address to, uint256 tokenId)`: ERC721 standard - allows transferring ownership of token ID 0.
31. `approve(address to, uint256 tokenId)`: ERC721 standard - approves an address to transfer token ID 0.
32. `setApprovalForAll(address operator, bool approved)`: ERC721 standard - approves/revokes operator for all tokens (only token 0 exists).
33. `getApproved(uint256 tokenId) view returns (address)`: ERC721 standard - gets approved address for token ID 0.
34. `isApprovedForAll(address owner, address operator) view returns (bool)`: ERC721 standard - checks if operator is approved for owner's tokens (only token 0).

*(Self-correction: Need to add standard Ownable functions to the count if using Ownable)*
35. `renounceOwnership()`: Ownable - Renounce ownership of the contract.
36. `transferOwnership(address newOwner)`: Ownable - Transfer ownership of the contract.

That's 36 functions, easily exceeding the 20 minimum.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

// Outline:
// 1. State Variables for Canvas dimensions, tile data, configuration, fees, delegation.
// 2. Structs for Tile data and Tile Type configuration.
// 3. Events for major actions.
// 4. Modifiers for access control.
// 5. Core functions for placing, refreshing, removing, and setting tile data (single and batch).
// 6. Delegation functions for position-based permissions.
// 7. Configuration functions (admin only).
// 8. View/Pure functions for retrieving state and configuration.
// 9. Integration with ERC721 for the single canvas NFT (Token ID 0).
// 10. Integration with Ownable for admin control.

// Function Summary (20+ Functions):
// 1.  constructor(uint256 initialWidth, uint256 initialHeight, string memory name, string memory symbol)
// 2.  placeTile(uint256 x, uint256 y, bytes32 tileData, uint8 tileTypeIndex) payable
// 3.  refreshTile(uint256 tileId) payable
// 4.  removeTile(uint256 tileId)
// 5.  setTileData(uint256 tileId, bytes32 newTileData)
// 6.  batchPlaceTiles(uint256[] calldata xCoords, uint256[] calldata yCoords, bytes32[] calldata tileDataArray, uint8[] calldata tileTypeIndices) payable
// 7.  batchRefreshTiles(uint256[] calldata tileIds) payable
// 8.  batchRemoveTiles(uint256[] calldata tileIds)
// 9.  delegatePlacementPermission(address delegatee, uint256 x, uint256 y)
// 10. revokeDelegatePlacementPermission(address delegatee, uint256 x, uint256 y)
// 11. getDelegatePermission(address delegator, address delegatee, uint256 x, uint256 y) view
// 12. setTileTypeInfo(uint8 tileTypeIndex, uint256 cost, uint256 decayDuration) onlyOwner
// 13. setCanvasDimensions(uint256 newWidth, uint256 newHeight) onlyOwner
// 14. setTileCost(uint8 tileTypeIndex, uint256 newCost) onlyOwner
// 15. setDefaultDecayTime(uint8 tileTypeIndex, uint256 newDecayDuration) onlyOwner
// 16. setBaseURI(string memory newBaseURI) onlyOwner
// 17. withdrawFunds(address payable recipient, uint256 amount) onlyOwner
// 18. getTileInfoById(uint256 tileId) view
// 19. getTileIdAtPosition(uint256 x, uint256 y) view
// 20. getTileInfoAtPosition(uint256 x, uint256 y) view
// 21. isTileActive(uint256 tileId) view
// 22. getTilesByOwner(address ownerAddress) view
// 23. getCanvasDimensions() view
// 24. getTileTypeInfo(uint8 tileTypeIndex) view
// 25. getCurrentTileCount() view
// 26. getTotalTilesPlaced() view
// 27. getLastActivityTime() view
// 28. tokenURI(uint256 tokenId) view (ERC721 Standard)
// 29. ownerOf(uint256 tokenId) view (ERC721 Standard)
// 30. transferFrom(address from, address to, uint256 tokenId) (ERC721 Standard)
// 31. approve(address to, uint256 tokenId) (ERC721 Standard)
// 32. setApprovalForAll(address operator, bool approved) (ERC721 Standard)
// 33. getApproved(uint256 tokenId) view (ERC721 Standard)
// 34. isApprovedForAll(address owner, address operator) view (ERC721 Standard)
// 35. renounceOwnership() (Ownable Standard)
// 36. transferOwnership(address newOwner) (Ownable Standard)


contract DecentralizedEphemeralArtCanvas is ERC721, Ownable, ReentrancyGuard {
    using Counters for Counters.Counter;

    // --- State Variables ---

    uint256 public canvasWidth;
    uint256 public canvasHeight;

    // Represents a single tile on the canvas
    struct Tile {
        uint256 x;
        uint256 y;
        address owner;
        bytes32 tileData;          // Arbitrary data, e.g., color hash, small image data
        uint256 expirationTimestamp;
        uint8 tileTypeIndex;       // Index referencing tileTypeConfigs
    }

    // Configuration for different tile types
    struct TileTypeConfig {
        uint256 cost;            // Cost to place or refresh this type of tile
        uint256 decayDuration;   // Time in seconds until this tile type expires
        bool exists;             // Flag to indicate if this tile type is configured
    }

    // Mapping from internal tile ID to Tile struct
    mapping(uint256 => Tile) public tiles;

    // Mapping from (x, y) position to internal tile ID (0 if position is empty or tile is expired)
    mapping(uint256 => mapping(uint256 => uint256)) private tilePositionIndex;

    // Mapping from tile type index to its configuration
    mapping(uint8 => TileTypeConfig) public tileTypeConfigs;

    // Mapping to track currently active tile IDs
    // Note: Tracking active tiles in an array/mapping is gas-intensive for large numbers.
    // This implementation relies on iterating tilePositionIndex or off-chain indexing via events.
    // currentActiveTileCount provides a general count.

    // Counters for tile IDs
    Counters.Counter private _tileIds;
    uint256 private _totalTilesPlaced; // Includes expired/removed

    // Delegation mapping: delegator => delegatee => x => y => bool (can place/refresh at this position)
    mapping(address => mapping(address => mapping(uint256 => mapping(uint256 => bool)))) public positionDelegates;

    // Timestamp of the last canvas activity (place or refresh)
    uint256 public lastActivityTime;

    // --- Constants ---
    uint256 private constant CANVAS_NFT_TOKEN_ID = 0; // The single token representing the canvas


    // --- Events ---

    event TilePlaced(uint256 indexed tileId, uint256 x, uint256 y, address indexed owner, bytes32 tileData, uint256 expirationTimestamp, uint8 tileTypeIndex);
    event TileRefreshed(uint256 indexed tileId, uint256 newExpirationTimestamp);
    event TileRemoved(uint256 indexed tileId, uint256 x, uint256 y, address indexed owner);
    event TileDataChanged(uint256 indexed tileId, bytes32 newTileData);
    event DelegationPermissionGranted(address indexed delegator, address indexed delegatee, uint256 x, uint256 y);
    event DelegationPermissionRevoked(address indexed delegator, address indexed delegatee, uint256 x, uint256 y);
    event TileTypeConfigUpdated(uint8 indexed tileTypeIndex, uint256 cost, uint256 decayDuration);
    event CanvasDimensionsUpdated(uint256 newWidth, uint256 newHeight);
    event FundsWithdrawn(address indexed recipient, uint256 amount);


    // --- Modifiers ---

    modifier onlyValidPosition(uint256 x, uint256 y) {
        require(x < canvasWidth && y < canvasHeight, "Position out of bounds");
        _;
    }

    modifier onlyConfiguredTileType(uint8 tileTypeIndex) {
        require(tileTypeConfigs[tileTypeIndex].exists, "Invalid tile type index");
        _;
    }

    modifier isActiveTileOwnerOrDelegate(uint256 tileId) {
        require(tiles[tileId].owner != address(0), "Tile does not exist");
        require(isTileActive(tileId), "Tile is not active");

        address tileOwner = tiles[tileId].owner;
        require(
            msg.sender == tileOwner || positionDelegates[tileOwner][msg.sender][tiles[tileId].x][tiles[tileId].y],
            "Not owner or delegate for this tile position"
        );
        _;
    }

    // --- Constructor ---

    /// @notice Deploys the Ephemeral Art Canvas contract and mints the single canvas NFT (Token ID 0).
    /// @param initialWidth The initial width of the canvas.
    /// @param initialHeight The initial height of the canvas.
    /// @param name ERC721 collection name.
    /// @param symbol ERC721 collection symbol.
    constructor(uint256 initialWidth, uint256 initialHeight, string memory name, string memory symbol)
        ERC721(name, symbol)
        Ownable(msg.sender) // Make deployer the initial owner
        ReentrancyGuard()
    {
        require(initialWidth > 0 && initialHeight > 0, "Canvas dimensions must be positive");
        canvasWidth = initialWidth;
        canvasHeight = initialHeight;

        // Mint the single ERC721 token representing the canvas to the contract owner
        _mint(msg.sender, CANVAS_NFT_TOKEN_ID);

        // Set a default tile type (index 0)
        tileTypeConfigs[0] = TileTypeConfig({
            cost: 0.001 ether,
            decayDuration: 1 days,
            exists: true
        });

        lastActivityTime = block.timestamp;
    }


    // --- Core Canvas Interaction Functions ---

    /// @notice Places a new tile or overwrites an expired tile at a specified position.
    /// @param x The x-coordinate.
    /// @param y The y-coordinate.
    /// @param tileData The data for the tile (e.g., color).
    /// @param tileTypeIndex The index of the tile type configuration to use.
    function placeTile(uint256 x, uint256 y, bytes32 tileData, uint8 tileTypeIndex)
        external
        payable
        nonReentrant
        onlyValidPosition(x, y)
        onlyConfiguredTileType(tileTypeIndex)
    {
        uint256 currentTileIdAtPos = tilePositionIndex[x][y];
        bool isPositionOccupied = currentTileIdAtPos != 0;
        bool currentTileIsActive = isPositionOccupied && isTileActive(currentTileIdAtPos);

        require(!currentTileIsActive, "Position is occupied by an active tile"); // Cannot overwrite active tiles this way

        TileTypeConfig storage typeConfig = tileTypeConfigs[tileTypeIndex];
        require(msg.value >= typeConfig.cost, "Insufficient payment");

        // If placing on an expired tile's spot, the old ID is effectively discarded from the position index.
        // The old Tile struct still exists in the `tiles` mapping but is marked inactive by timestamp.

        _tileIds.increment();
        uint256 newTileId = _tileIds.current();

        tiles[newTileId] = Tile({
            x: x,
            y: y,
            owner: msg.sender,
            tileData: tileData,
            expirationTimestamp: block.timestamp + typeConfig.decayDuration,
            tileTypeIndex: tileTypeIndex
        });

        tilePositionIndex[x][y] = newTileId; // Update position index to point to the new tile

        _totalTilesPlaced++;
        lastActivityTime = block.timestamp;

        emit TilePlaced(newTileId, x, y, msg.sender, tileData, tiles[newTileId].expirationTimestamp, tileTypeIndex);
    }

    /// @notice Extends the expiration time of an existing active tile.
    /// @param tileId The internal ID of the tile to refresh.
    function refreshTile(uint256 tileId)
        external
        payable
        nonReentrant
        isActiveTileOwnerOrDelegate(tileId)
    {
        Tile storage tile = tiles[tileId];
        TileTypeConfig storage typeConfig = tileTypeConfigs[tile.tileTypeIndex];

        require(msg.value >= typeConfig.cost, "Insufficient payment");

        // Extend expiration, ensuring it's at least `decayDuration` from now
        // This prevents stacking decay times indefinitely from the past timestamp
        tile.expirationTimestamp = block.timestamp + typeConfig.decayDuration;

        lastActivityTime = block.timestamp;

        emit TileRefreshed(tileId, tile.expirationTimestamp);
    }

    /// @notice Removes an existing active tile permanently.
    /// @param tileId The internal ID of the tile to remove.
    function removeTile(uint256 tileId)
        external
        nonReentrant
        isActiveTileOwnerOrDelegate(tileId)
    {
        Tile storage tile = tiles[tileId];

        // Remove from position index
        tilePositionIndex[tile.x][tile.y] = 0;

        // Emit event before potentially clearing the struct data
        emit TileRemoved(tileId, tile.x, tile.y, tile.owner);

        // Clear the tile data (optional, but good practice)
        delete tiles[tileId];

        // Note: currentActiveTileCount is not decremented here; it relies on isTileActive check.
        lastActivityTime = block.timestamp;
    }

    /// @notice Modifies the data (e.g., color) of an existing active tile.
    /// @param tileId The internal ID of the tile to modify.
    /// @param newTileData The new data for the tile.
    function setTileData(uint256 tileId, bytes32 newTileData)
        external
        nonReentrant
        isActiveTileOwnerOrDelegate(tileId)
    {
        tiles[tileId].tileData = newTileData;
        lastActivityTime = block.timestamp;
        emit TileDataChanged(tileId, newTileData);
    }

    // --- Batch Functions ---

    /// @notice Places multiple new tiles or overwrites expired tiles in a single transaction.
    function batchPlaceTiles(uint256[] calldata xCoords, uint256[] calldata yCoords, bytes32[] calldata tileDataArray, uint8[] calldata tileTypeIndices)
        external
        payable
        nonReentrant // Protects against reentrancy within the batch or with other calls
    {
        require(xCoords.length == yCoords.length && xCoords.length == tileDataArray.length && xCoords.length == tileTypeIndices.length, "Input arrays must have same length");
        require(xCoords.length > 0, "Input arrays cannot be empty");

        uint256 totalCost = 0;
        for (uint i = 0; i < xCoords.length; i++) {
             require(xCoords[i] < canvasWidth && yCoords[i] < canvasHeight, "Batch position out of bounds");
             require(tileTypeConfigs[tileTypeIndices[i]].exists, "Batch invalid tile type index");

             uint256 currentTileIdAtPos = tilePositionIndex[xCoords[i]][yCoords[i]];
             bool isPositionOccupied = currentTileIdAtPos != 0;
             bool currentTileIsActive = isPositionOccupied && isTileActive(currentTileIdAtPos);

             require(!currentTileIsActive, "Batch includes position occupied by active tile"); // Cannot overwrite active tiles

             totalCost += tileTypeConfigs[tileTypeIndices[i]].cost;
        }

        require(msg.value >= totalCost, "Insufficient payment for batch placement");

        for (uint i = 0; i < xCoords.length; i++) {
            _tileIds.increment();
            uint256 newTileId = _tileIds.current();
            uint8 tileTypeIndex = tileTypeIndices[i];
            TileTypeConfig storage typeConfig = tileTypeConfigs[tileTypeIndex];

             tiles[newTileId] = Tile({
                x: xCoords[i],
                y: yCoords[i],
                owner: msg.sender,
                tileData: tileDataArray[i],
                expirationTimestamp: block.timestamp + typeConfig.decayDuration,
                tileTypeIndex: tileTypeIndex
            });

            tilePositionIndex[xCoords[i]][yCoords[i]] = newTileId;

            _totalTilesPlaced++;
            emit TilePlaced(newTileId, xCoords[i], yCoords[i], msg.sender, tileDataArray[i], tiles[newTileId].expirationTimestamp, tileTypeIndex);
        }
         lastActivityTime = block.timestamp;
    }

    /// @notice Refreshes multiple tiles in a single transaction.
    function batchRefreshTiles(uint256[] calldata tileIds)
        external
        payable
        nonReentrant
    {
         require(tileIds.length > 0, "Input array cannot be empty");

         uint256 totalCost = 0;
         for (uint i = 0; i < tileIds.length; i++) {
             uint256 tileId = tileIds[i];
             require(tiles[tileId].owner != address(0), "Batch includes non-existent tile");
             require(isTileActive(tileId), "Batch includes non-active tile");
             require(
                 msg.sender == tiles[tileId].owner || positionDelegates[tiles[tileId].owner][msg.sender][tiles[tileId].x][tiles[tileId].y],
                 "Batch includes tile not owned or delegated to caller"
             );
             totalCost += tileTypeConfigs[tiles[tileId].tileTypeIndex].cost;
         }

         require(msg.value >= totalCost, "Insufficient payment for batch refresh");

         for (uint i = 0; i < tileIds.length; i++) {
             uint256 tileId = tileIds[i];
             Tile storage tile = tiles[tileId];
             TileTypeConfig storage typeConfig = tileTypeConfigs[tile.tileTypeIndex];

             tile.expirationTimestamp = block.timestamp + typeConfig.decayDuration;
             emit TileRefreshed(tileId, tile.expirationTimestamp);
         }
        lastActivityTime = block.timestamp;
    }

    /// @notice Removes multiple tiles in a single transaction.
     function batchRemoveTiles(uint256[] calldata tileIds)
        external
        nonReentrant
    {
        require(tileIds.length > 0, "Input array cannot be empty");

        for (uint i = 0; i < tileIds.length; i++) {
             uint256 tileId = tileIds[i];
             require(tiles[tileId].owner != address(0), "Batch includes non-existent tile");
             require(isTileActive(tileId), "Batch includes non-active tile"); // Only remove active tiles
             require(
                 msg.sender == tiles[tileId].owner || positionDelegates[tiles[tileId].owner][msg.sender][tiles[tileId].x][tiles[tileId].y],
                 "Batch includes tile not owned or delegated to caller"
             );
        }

         for (uint i = 0; i < tileIds.length; i++) {
             uint256 tileId = tileIds[i];
             Tile storage tile = tiles[tileId];

             tilePositionIndex[tile.x][tile.y] = 0;
             emit TileRemoved(tileId, tile.x, tile.y, tile.owner);
             delete tiles[tileId]; // Clear the data
         }
        lastActivityTime = block.timestamp;
    }


    // --- Delegation Functions ---

    /// @notice Grants or revokes placement/refresh permission for a specific canvas position.
    /// Caller must be the current owner of the position's tile (if active) or the contract owner.
    /// Note: Contract owner can delegate ANY position. Tile owner can delegate THEIR position.
    /// @param delegatee The address to grant/revoke permission to.
    /// @param x The x-coordinate.
    /// @param y The y-coordinate.
    function delegatePlacementPermission(address delegatee, uint256 x, uint256 y)
        external
        onlyValidPosition(x, y)
    {
        uint256 tileIdAtPos = tilePositionIndex[x][y];
        address positionOwner;

        if (tileIdAtPos != 0 && isTileActive(tileIdAtPos)) {
            positionOwner = tiles[tileIdAtPos].owner;
            require(msg.sender == positionOwner, "Caller is not owner of the active tile at this position");
        } else {
             // If position is empty or tile is expired, only contract owner can delegate for this spot's future owner
             // This requires the delegator mapping to handle address(0) or similar, or only allow delegation BY the owner.
             // Let's simplify: only the current tile owner can delegate for their position. If no tile, no delegation possible for that spot currently.
             revert("Cannot delegate permission for an empty or expired position unless you are the contract owner (not implemented yet)");
        }

        require(delegatee != address(0), "Delegatee cannot be zero address");
        require(delegatee != msg.sender, "Cannot delegate to yourself");

        positionDelegates[positionOwner][delegatee][x][y] = true; // Grant permission
        emit DelegationPermissionGranted(positionOwner, delegatee, x, y);
    }

     /// @notice Revokes placement/refresh permission for a specific canvas position.
     /// Caller must be the delegator (the address who originally granted the permission, which is the tile owner).
     /// @param delegatee The address whose permission is being revoked.
     /// @param x The x-coordinate.
     /// @param y The y-coordinate.
    function revokeDelegatePlacementPermission(address delegatee, uint256 x, uint256 y)
        external
        onlyValidPosition(x, y)
    {
        uint256 tileIdAtPos = tilePositionIndex[x][y];
        address positionOwner; // The address who would have granted the permission

        if (tileIdAtPos != 0 && isTileActive(tileIdAtPos)) {
             positionOwner = tiles[tileIdAtPos].owner;
             require(msg.sender == positionOwner, "Caller is not the owner of the active tile at this position");
        } else {
            // Same logic as delegation: only owner of an active tile can revoke for their spot.
             revert("Cannot revoke delegation for an empty or expired position unless you are the contract owner (not implemented yet)");
        }

        require(delegatee != address(0), "Delegatee cannot be zero address");
        require(positionDelegates[positionOwner][delegatee][x][y], "Delegatee does not have permission for this position");

        positionDelegates[positionOwner][delegatee][x][y] = false; // Revoke permission
        emit DelegationPermissionRevoked(positionOwner, delegatee, x, y);
    }

    /// @notice Checks if a delegatee has placement/refresh permission for a specific position delegated by a delegator.
    /// @param delegator The address who may have granted the permission (typically the tile owner).
    /// @param delegatee The address whose permission is being checked.
    /// @param x The x-coordinate.
    /// @param y The y-coordinate.
    /// @return bool True if the delegatee has permission, false otherwise.
    function getDelegatePermission(address delegator, address delegatee, uint256 x, uint256 y)
        public
        view
        onlyValidPosition(x, y)
        returns (bool)
    {
        return positionDelegates[delegator][delegatee][x][y];
    }


    // --- Configuration Functions (Owner Only) ---

    /// @notice Sets or updates the configuration for a specific tile type.
    /// @param tileTypeIndex The index of the tile type to configure (0-255).
    /// @param cost The cost in wei to place or refresh this tile type.
    /// @param decayDuration The duration in seconds this tile type stays active after placement/refresh.
    function setTileTypeInfo(uint8 tileTypeIndex, uint256 cost, uint256 decayDuration)
        external
        onlyOwner
    {
        tileTypeConfigs[tileTypeIndex] = TileTypeConfig({
            cost: cost,
            decayDuration: decayDuration,
            exists: true
        });
        emit TileTypeConfigUpdated(tileTypeIndex, cost, decayDuration);
    }

    /// @notice Sets new canvas dimensions. Can only increase size.
    /// @param newWidth The new width of the canvas.
    /// @param newHeight The new height of the canvas.
    function setCanvasDimensions(uint256 newWidth, uint256 newHeight)
        external
        onlyOwner
    {
        require(newWidth >= canvasWidth && newHeight >= canvasHeight, "New dimensions must be greater than or equal to current");
        require(newWidth > 0 && newHeight > 0, "New dimensions must be positive");

        canvasWidth = newWidth;
        canvasHeight = newHeight;
        emit CanvasDimensionsUpdated(newWidth, newHeight);
    }

    /// @notice Updates the placement/refresh cost for an existing tile type.
    /// @param tileTypeIndex The index of the tile type.
    /// @param newCost The new cost in wei.
    function setTileCost(uint8 tileTypeIndex, uint256 newCost)
        external
        onlyOwner
        onlyConfiguredTileType(tileTypeIndex)
    {
        tileTypeConfigs[tileTypeIndex].cost = newCost;
         emit TileTypeConfigUpdated(tileTypeIndex, newCost, tileTypeConfigs[tileTypeIndex].decayDuration);
    }

    /// @notice Updates the default decay duration for an existing tile type.
    /// @param tileTypeIndex The index of the tile type.
    /// @param newDecayDuration The new duration in seconds.
    function setDefaultDecayTime(uint8 tileTypeIndex, uint256 newDecayDuration)
        external
        onlyOwner
        onlyConfiguredTileType(tileTypeIndex)
    {
        tileTypeConfigs[tileTypeIndex].decayDuration = newDecayDuration;
        emit TileTypeConfigUpdated(tileTypeIndex, tileTypeConfigs[tileTypeIndex].cost, newDecayDuration);
    }

    /// @notice Sets the base URI for the canvas NFT metadata.
    /// @param newBaseURI The new base URI string.
    function setBaseURI(string memory newBaseURI) external onlyOwner {
        _setBaseURI(newBaseURI);
    }

    /// @notice Allows the contract owner to withdraw collected ether fees.
    /// @param recipient The address to send the funds to.
    /// @param amount The amount of wei to withdraw.
    function withdrawFunds(address payable recipient, uint256 amount) external onlyOwner nonReentrant {
        require(amount > 0, "Amount must be positive");
        require(address(this).balance >= amount, "Insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Withdrawal failed");

        emit FundsWithdrawn(recipient, amount);
    }


    // --- View and Pure Functions ---

    /// @notice Retrieves all information for a given tile ID.
    /// @param tileId The internal ID of the tile.
    /// @return x The x-coordinate.
    /// @return y The y-coordinate.
    /// @return owner The owner's address.
    /// @return tileData The tile's data.
    /// @return expirationTimestamp The timestamp when the tile expires.
    /// @return tileTypeIndex The index of the tile type.
    /// @return active True if the tile is currently active, false otherwise.
    function getTileInfoById(uint256 tileId)
        public
        view
        returns (
            uint256 x,
            uint256 y,
            address owner,
            bytes32 tileData,
            uint256 expirationTimestamp,
            uint8 tileTypeIndex,
            bool active
        )
    {
        // Check if tile exists by checking if owner is non-zero
        if (tiles[tileId].owner == address(0)) {
            return (0, 0, address(0), bytes32(0), 0, 0, false);
        }

        Tile storage tile = tiles[tileId];
        return (
            tile.x,
            tile.y,
            tile.owner,
            tile.tileData,
            tile.expirationTimestamp,
            tile.tileTypeIndex,
            isTileActive(tileId)
        );
    }

    /// @notice Gets the internal tile ID located at a specific canvas position.
    /// @param x The x-coordinate.
    /// @param y The y-coordinate.
    /// @return tileId The internal tile ID (0 if the position is empty or contains an expired tile).
    function getTileIdAtPosition(uint256 x, uint256 y)
        public
        view
        onlyValidPosition(x, y)
        returns (uint256 tileId)
    {
         uint256 id = tilePositionIndex[x][y];
         // Return 0 if the tile at this position is expired
         if (id != 0 && !isTileActive(id)) {
             return 0;
         }
         return id;
    }

    /// @notice Retrieves information for the tile located at a specific canvas position.
    /// @param x The x-coordinate.
    /// @param y The y-coordinate.
    /// @return tileId The internal tile ID (0 if empty/expired).
    /// @return owner The owner's address (address(0) if empty/expired).
    /// @return tileData The tile's data (0 if empty/expired).
    /// @return expirationTimestamp The timestamp when the tile expires (0 if empty/expired).
    /// @return tileTypeIndex The index of the tile type (0 if empty/expired).
    /// @return active True if the tile is currently active, false otherwise.
    function getTileInfoAtPosition(uint256 x, uint256 y)
        public
        view
        onlyValidPosition(x, y)
        returns (
            uint256 tileId,
            address owner,
            bytes32 tileData,
            uint256 expirationTimestamp,
            uint8 tileTypeIndex,
            bool active
        )
    {
        uint256 id = tilePositionIndex[x][y];
        if (id == 0 || !isTileActive(id)) {
             return (0, address(0), bytes32(0), 0, 0, false);
        }
         Tile storage tile = tiles[id];
         return (
             id,
             tile.owner,
             tile.tileData,
             tile.expirationTimestamp,
             tile.tileTypeIndex,
             true // Already checked isTileActive above
         );
    }


    /// @notice Checks if a tile with the given ID is currently active (exists and not expired).
    /// @param tileId The internal ID of the tile.
    /// @return bool True if the tile is active, false otherwise.
    function isTileActive(uint256 tileId) public view returns (bool) {
        // Check if tile exists (owner is non-zero means it was placed)
        // Then check if current block timestamp is before expiration
        return tiles[tileId].owner != address(0) && block.timestamp < tiles[tileId].expirationTimestamp;
    }

     /// @notice Returns an array of active tile IDs owned by a specific address.
     /// WARNING: This function can be very gas-intensive if an owner has many tiles.
     /// Intended for off-chain indexers or users with a reasonable number of tiles.
     /// @param ownerAddress The address whose tiles to retrieve.
     /// @return tileIds An array of active tile IDs owned by the address.
     function getTilesByOwner(address ownerAddress) public view returns (uint256[] memory) {
         uint256[] memory ownedTileIds = new uint256[](_totalTilesPlaced); // Max possible size
         uint256 count = 0;

         // Iterate through all potential tile IDs up to the current counter value
         // This is the gas-intensive part. A better pattern for production might involve pagination
         // or relying entirely on off-chain indexing via events.
         for (uint256 i = 1; i <= _tileIds.current(); i++) {
             // Check if tile exists, is active, and is owned by the address
             if (tiles[i].owner == ownerAddress && isTileActive(i)) {
                 ownedTileIds[count] = i;
                 count++;
             }
         }

         // Resize the array to the actual count
         uint256[] memory result = new uint256[](count);
         for (uint256 i = 0; i < count; i++) {
             result[i] = ownedTileIds[i];
         }
         return result;
     }

    /// @notice Returns the current canvas dimensions.
    /// @return width The canvas width.
    /// @return height The canvas height.
    function getCanvasDimensions() public view returns (uint256 width, uint256 height) {
        return (canvasWidth, canvasHeight);
    }

    /// @notice Returns the cost to place or refresh a specific tile type.
    /// @param tileTypeIndex The index of the tile type.
    /// @return cost The cost in wei.
    function getTileCost(uint8 tileTypeIndex) public view onlyConfiguredTileType(tileTypeIndex) returns (uint256) {
        return tileTypeConfigs[tileTypeIndex].cost;
    }

    /// @notice Returns the default decay duration for a specific tile type.
    /// @param tileTypeIndex The index of the tile type.
    /// @return decayDuration The duration in seconds.
    function getDefaultDecayTime(uint8 tileTypeIndex) public view onlyConfiguredTileType(tileTypeIndex) returns (uint256) {
        return tileTypeConfigs[tileTypeIndex].decayDuration;
    }

    /// @notice Retrieves the full configuration for a tile type.
    /// @param tileTypeIndex The index of the tile type.
    /// @return cost The cost in wei.
    /// @return decayDuration The duration in seconds.
    /// @return exists True if the tile type is configured.
    function getTileTypeInfo(uint8 tileTypeIndex) public view returns (uint256 cost, uint256 decayDuration, bool exists) {
        TileTypeConfig storage config = tileTypeConfigs[tileTypeIndex];
        return (config.cost, config.decayDuration, config.exists);
    }

    /// @notice Returns the current number of active tiles on the canvas.
    /// Note: This is an estimate based on iterating the position index and checking status.
    /// For potentially very large canvases, this might exceed gas limits.
    /// Off-chain counting via events is recommended for accuracy.
    /// @return count The number of active tiles.
    function getCurrentTileCount() public view returns (uint256 count) {
         count = 0;
         // This loop iterates through all positions, which can be gas-intensive
         for (uint256 x = 0; x < canvasWidth; x++) {
             for (uint256 y = 0; y < canvasHeight; y++) {
                 uint256 tileId = tilePositionIndex[x][y];
                 if (tileId != 0 && isTileActive(tileId)) {
                     count++;
                 }
             }
         }
         return count;
    }

    /// @notice Returns the total number of tiles ever placed (including expired and removed).
    /// @return count The total count.
    function getTotalTilesPlaced() public view returns (uint256) {
        return _totalTilesPlaced;
    }

    /// @notice Returns the timestamp of the last interaction (place or refresh) on the canvas.
    /// @return timestamp The last activity timestamp.
    function getLastActivityTime() public view returns (uint256) {
        return lastActivityTime;
    }

    // --- ERC721 Standard Functions (for CANVAS_NFT_TOKEN_ID only) ---
    // These functions are inherited and automatically apply to token ID 0

    /// @dev See {IERC721-tokenURI}. Overrides the default to point to the base URI.
    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721)
        returns (string memory)
    {
        require(_exists(tokenId), "ERC721: URI query for nonexistent token");
        require(tokenId == CANVAS_NFT_TOKEN_ID, "Only token ID 0 exists"); // Ensure only our canvas token is queried

        // The actual tokenURI would typically point to metadata describing the canvas
        // This could be a static JSON or an API endpoint that dynamically renders
        // the canvas state based on the contract's view functions (like getTileInfoAtPosition)
        return super.tokenURI(tokenId); // Uses the base URI set by setBaseURI
    }

    // The following ERC721 standard functions (ownerOf, transferFrom, approve, setApprovalForAll, getApproved, isApprovedForAll)
    // are inherited from OpenZeppelin's ERC721 and correctly manage the ownership and transfer of
    // the single token (ID 0) minted in the constructor. They implicitly enforce that only token ID 0
    // can be operated on, because _exists(tokenId) will only return true for CANVAS_NFT_TOKEN_ID.
    // They are included in the function count.

    // --- Ownable Standard Functions ---
    // renounceOwnership() and transferOwnership(address newOwner) are inherited from OpenZeppelin's Ownable
    // and manage the ownership of the contract itself (which is also the owner of token ID 0).
    // They are included in the function count.

    // --- Receive Ether ---
    // Contract needs to be able to receive ether payments for placing/refreshing tiles
    receive() external payable {}
}
```

**Explanation of Advanced/Creative Concepts:**

1.  **Dynamic On-Chain State:** The core art (`tiles` mapping) is not static metadata stored off-chain, but a living dataset directly in contract storage that changes based on user interaction and time.
2.  **Ephemerality:** The `expirationTimestamp` and `isTileActive` logic introduce a decay mechanic. This forces continuous engagement to maintain the artwork and creates a constantly evolving visual state, distinct from static NFTs.
3.  **Single Dynamic NFT:** Representing the *entire* collaborative, ephemeral artwork as a single token ID 0 is a creative twist. Ownership of this token could grant special privileges (like admin access, as implemented via `Ownable`), or simply represent stewardship of the collective piece. The `tokenURI` could potentially point to a dynamic renderer that visualizes the current on-chain state.
4.  **Configurable Tile Types:** Introducing different `TileTypeConfig` structs allows for variation in costs, decay rates, and intended use cases for different types of pixels/elements on the canvas, adding strategic depth.
5.  **Delegation:** `positionDelegates` allows tile owners (or potentially the canvas owner) to delegate the rights to manage specific spots. This is useful for guilds, automated refresh bots, or collaborative groups managing a section of the canvas.
6.  **Batch Operations:** `batchPlaceTiles`, `batchRefreshTiles`, `batchRemoveTiles` are practical advanced features for improving user experience and reducing transaction costs for multiple actions.
7.  **On-chain Data Interpretation (`bytes32 tileData`):** The contract doesn't interpret `tileData`. This allows flexibility for off-chain applications to decide what `bytes32` represents (e.g., a hex color code, an index into an emoji set, a hash of a larger image chunk). The contract provides the infrastructure; the interpretation layer is off-chain, which is a common and necessary pattern for complex on-chain data.

This contract is more than just a simple ERC721; it's an interactive, stateful application representing a unique digital asset with built-in mechanics driving user engagement and state change over time.