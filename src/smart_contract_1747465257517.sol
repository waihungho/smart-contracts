Okay, here is a smart contract concept called "Infinite Canvas", designed to be a collaborative, tokenized digital space. It incorporates several advanced concepts like dynamic NFTs, layered data, on-chain provenance for digital assets, a form of collaborative interaction, and a moderation layer.

It's non-standard and aims for creativity by turning each pixel/tile into an ownable, mutable NFT that can hold different types of linked data.

---

**Contract Name:** `InfiniteCanvas`

**Concept:** An "infinite" grid of tiles (represented by `int256` coordinates) where each tile can be owned as an ERC721 token. Owners (or approved users) can place content on their tiles, add descriptive text, link external data via a content hash, and add annotations. The contract manages tile ownership, state, costs, and basic moderation for annotations.

**Advanced/Creative Concepts Used:**
1.  **Infinite (Theoretical) Grid:** Uses `int256` coordinates and sparse storage (`mapping`) to allow for theoretically infinite expansion, limited only by blockchain storage costs.
2.  **Dynamic NFTs:** Each tile is an ERC721 token whose associated data (color, text, content hash, link, locked status) can be changed by the owner or approved users. The NFT state is mutable post-minting.
3.  **Layered Tile Data:** A tile can hold core visual data (color), descriptive text, an external data link (`contentHash`), and a separate layer of user-added annotations.
4.  **Content Addressable Storage Linkage:** Includes a `contentHash` field, allowing owners to link their tile to data stored off-chain (like IPFS) in a verifiable way, making the on-chain NFT a pointer to a richer asset.
5.  **Collaborative (Limited):** Users can add annotations to *any* tile, creating a collaborative commenting layer (subject to moderation).
6.  **Time-Based Locking:** Tile owners can lock their tiles temporarily, preventing updates.
7.  **Basic On-chain Moderation:** Introduces annotation moderators who can remove annotations.

---

**Outline:**

1.  **Dependencies:** ERC721, Ownable (from OpenZeppelin).
2.  **State Variables:**
    *   `tokenIdCounter`: Counter for unique tile token IDs.
    *   `tiles`: Mapping from token ID to `TileData` struct.
    *   `coordsToTokenId`: Mapping from `(x,y)` coordinates to token ID.
    *   `tokenIdToCoords`: Mapping from token ID to `(x,y)` coordinates.
    *   `annotations`: Mapping from token ID to a list of annotation structs.
    *   `annotationModerators`: Mapping of addresses allowed to moderate annotations.
    *   `tileLocks`: Mapping from token ID to unlock timestamp.
    *   `tileLinks`: Mapping from token ID to external URL.
    *   `mintCost`: Cost to mint a new tile.
    *   `updateCost`: Cost to update an existing tile.
    *   `paused`: Boolean to pause interactions.
3.  **Structs:**
    *   `TileData`: Stores tile attributes (`x`, `y`, `color`, `text`, `contentHash`).
    *   `Annotation`: Stores annotation details (`annotator`, `message`, `timestamp`).
4.  **Events:**
    *   `TileMinted`: When a new tile NFT is created.
    *   `TileUpdated`: When a tile's data is changed.
    *   `AnnotationAdded`: When an annotation is added.
    *   `AnnotationRemoved`: When an annotation is removed.
    *   `TileLocked`: When a tile is locked.
    *   `LinkSet`: When an external link is added to a tile.
    *   `MintCostSet`: When the mint cost is updated.
    *   `UpdateCostSet`: When the update cost is updated.
    *   `Paused`: When the contract is paused/unpaused.
    *   `FundsWithdrawn`: When funds are withdrawn by the owner.
    *   `ModeratorAdded`: When a moderator is added.
    *   `ModeratorRemoved`: When a moderator is removed.
5.  **Modifiers:**
    *   `whenNotPaused`: Ensures function runs only when not paused.
    *   `onlyOwnerOrApproved`: Ensures caller is the token owner or approved/operator.
    *   `onlyModerator`: Ensures caller is an annotation moderator.
    *   `tileExists`: Ensures a tile exists at the given coordinates.
    *   `tileNotLocked`: Ensures a tile is not currently locked.
6.  **Functions (20+):**
    *   **ERC721 Standard Functions (9):** (Inherited from OpenZeppelin)
        1.  `name()`
        2.  `symbol()`
        3.  `balanceOf(address owner)`
        4.  `ownerOf(uint256 tokenId)`
        5.  `transferFrom(address from, address to, uint256 tokenId)`
        6.  `safeTransferFrom(address from, address to, uint256 tokenId)`
        7.  `approve(address to, uint256 tokenId)`
        8.  `getApproved(uint256 tokenId)`
        9.  `setApprovalForAll(address operator, bool _approved)`
        10. `isApprovedForAll(address owner, address operator)`
    *   **Tile Interaction Functions (8):**
        11. `mintTile(int256 x, int256 y, uint32 color, string memory text, bytes32 contentHash)`: Mints a new tile NFT at (x,y), sets initial data. Requires `mintCost`.
        12. `updateTileData(int256 x, int256 y, uint32 color, string memory text, bytes32 contentHash)`: Updates data for an existing tile. Requires `updateCost`. Callable by owner or approved.
        13. `addAnnotationToTile(int256 x, int256 y, string memory message)`: Adds a message annotation to a tile.
        14. `removeTileAnnotation(int256 x, int256 y, uint256 annotationIndex)`: Removes a specific annotation by index. Callable by owner or moderator.
        15. `lockTile(int256 x, int256 y, uint256 durationSeconds)`: Locks a tile preventing updates for a duration. Callable by owner or approved.
        16. `setTileLink(int256 x, int256 y, string memory url)`: Sets an external URL for a tile. Callable by owner or approved.
        17. `transferTile(int256 x, int256 y, address to)`: Transfers ownership of a tile NFT using coordinates. (Wrapper for ERC721 `safeTransferFrom`).
        18. `burnTile(int256 x, int256 y)`: Burns the tile NFT. Callable by owner. (Wrapper for ERC721 `_burn`).
    *   **Query Functions (8):**
        19. `getTileData(int256 x, int256 y)`: Returns the core `TileData` struct for a tile.
        20. `getTileTokenId(int256 x, int256 y)`: Returns the token ID for given coordinates.
        21. `getTileCoordinates(uint256 tokenId)`: Returns the coordinates for a given token ID.
        22. `getTileAnnotations(int256 x, int256 y)`: Returns all annotations for a tile.
        23. `getTileLockStatus(int256 x, int256 y)`: Returns the unlock timestamp for a tile.
        24. `getTileLink(int256 x, int256 y)`: Returns the external URL for a tile.
        25. `doesTileExist(int256 x, int256 y)`: Checks if a tile has been minted.
        26. `isTileLocked(int256 x, int256 y)`: Checks if a tile is currently locked.
    *   **Admin/Config Functions (6):**
        27. `setMintCost(uint256 _mintCost)`: Sets the cost to mint a tile. (Owner only).
        28. `setUpdateCost(uint256 _updateCost)`: Sets the cost to update a tile. (Owner only).
        29. `pauseCanvas(bool _paused)`: Pauses/unpauses interactions. (Owner only).
        30. `withdrawFunds(address payable recipient)`: Withdraws contract balance. (Owner only).
        31. `addAnnotationModerator(address moderator)`: Adds an address as an annotation moderator. (Owner only).
        32. `removeAnnotationModerator(address moderator)`: Removes an address as an annotation moderator. (Owner only).
    *   **Moderator Check Function (1):**
        33. `isAnnotationModerator(address account)`: Checks if an address is a moderator. (Public/View).

Total functions: 10 (inherited) + 8 (tile interaction) + 8 (query) + 6 (admin) + 1 (check) = **33 functions**.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

// Note on data types:
// int256 for coordinates allows for addressing tiles in any quadrant.
// uint32 for color allows for standard 0xRRGGBB or 0xAARRGGBB format.
// bytes32 for contentHash is suitable for IPFS CIDs (after decoding) or other fixed-size content identifiers.

/// @title InfiniteCanvas
/// @dev A smart contract for a collaborative, infinite, tile-based digital canvas where each tile is an ownable, dynamic NFT.
contract InfiniteCanvas is ERC721, Ownable, ReentrancyGuard {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;

    struct TileData {
        int256 x;
        int256 y;
        uint32 color; // e.g., 0xRRGGBB or 0xAARRGGBB
        string text; // Short description or message
        bytes32 contentHash; // Hash linking to off-chain content (e.g., IPFS CID)
    }

    struct Annotation {
        address annotator;
        string message;
        uint256 timestamp;
    }

    // Mapping from token ID to TileData
    mapping(uint256 => TileData) public tiles;
    // Mapping from (x,y) coordinates to token ID (for quick lookup)
    mapping(int256 => mapping(int256 => uint256)) private _coordsToTokenId;
    // Mapping from token ID to (x,y) coordinates (redundant but useful query)
    mapping(uint256 => tuple(int256, int256)) private _tokenIdToCoords;

    // Mapping from token ID to a list of annotations
    // NOTE: Storing dynamic arrays in mappings like this can be gas-intensive for reads
    // and writes as the array grows. For production, consider a linked list pattern or
    // mapping(uint256 => mapping(uint256 => Annotation)) with a count.
    mapping(uint256 => Annotation[]) private _annotations;

    // Mapping of addresses allowed to moderate annotations
    mapping(address => bool) private _annotationModerators;

    // Mapping from token ID to unlock timestamp (0 if not locked)
    mapping(uint256 => uint256) private _tileLocks;

    // Mapping from token ID to external URL
    mapping(uint256 => string) private _tileLinks;

    uint256 public mintCost;
    uint256 public updateCost;
    bool public paused;

    // --- Events ---

    event TileMinted(uint256 indexed tokenId, int256 x, int256 y, address indexed owner, uint32 color, bytes32 contentHash);
    event TileUpdated(uint256 indexed tokenId, int256 x, int256 y, address indexed updater, uint32 color, string text, bytes32 contentHash);
    event AnnotationAdded(uint256 indexed tokenId, int256 x, int256 y, address indexed annotator, string message, uint256 timestamp);
    event AnnotationRemoved(uint256 indexed tokenId, int256 x, int256 y, address indexed remover, uint26 annotationIndex);
    event TileLocked(uint256 indexed tokenId, int256 x, int256 y, address indexed locker, uint256 unlockTimestamp);
    event LinkSet(uint256 indexed tokenId, int256 x, int256 y, address indexed setter, string url);
    event MintCostSet(uint256 indexed newCost);
    event UpdateCostSet(uint256 indexed newCost);
    event Paused(bool isPaused);
    event FundsWithdrawn(address indexed recipient, uint256 amount);
    event ModeratorAdded(address indexed moderator);
    event ModeratorRemoved(address indexed moderator);

    // --- Modifiers ---

    modifier whenNotPaused() {
        require(!paused, "Contract is paused");
        _;
    }

    // Checks if caller is the owner OR approved for the specific token OR approved for all
    modifier onlyOwnerOrApproved(uint256 tokenId) {
        address tokenOwner = ownerOf(tokenId); // ERC721 ownerOf check handles existence
        require(msg.sender == tokenOwner || getApproved(tokenId) == msg.sender || isApprovedForAll(tokenOwner, msg.sender),
                "Not tile owner or approved");
        _;
    }

    modifier onlyModerator() {
        require(_annotationModerators[msg.sender], "Not an annotation moderator");
        _;
    }

    modifier tileExists(int256 x, int256 y) {
        require(_coordsToTokenId[x][y] != 0, "Tile does not exist");
        _;
    }

    modifier tileExistsByTokenId(uint256 tokenId) {
         // ERC721 ownerOf requires valid token, implicitly checks existence
        ownerOf(tokenId);
        _;
    }


    modifier tileNotLocked(uint256 tokenId) {
        require(_tileLocks[tokenId] <= block.timestamp, "Tile is currently locked");
        _;
    }

    // --- Constructor ---

    /// @dev Constructor initializes the contract with a name, symbol, and initial costs.
    /// @param _name The name for the ERC721 token collection.
    /// @param _symbol The symbol for the ERC721 token collection.
    /// @param initialMintCost The initial cost in Wei to mint a new tile.
    /// @param initialUpdateCost The initial cost in Wei to update a tile's data.
    constructor(string memory _name, string memory _symbol, uint256 initialMintCost, uint256 initialUpdateCost) ERC721(_name, _symbol) Ownable(msg.sender) {
        mintCost = initialMintCost;
        updateCost = initialUpdateCost;
        paused = false; // Start not paused
        _annotationModerators[msg.sender] = true; // Owner is default moderator
    }

    // --- ERC721 Overrides (Mostly handled by OpenZeppelin) ---
    // We don't need explicit overrides for standard functions like name, symbol, balanceOf, etc.
    // OpenZeppelin's implementation is sufficient.
    // ownerOf, getApproved, isApprovedForAll are public by default.
    // transferFrom, safeTransferFrom, approve, setApprovalForAll are external by default.

    // --- Custom Tile Interaction Functions ---

    /// @dev Mints a new tile NFT at specified coordinates.
    /// @param x The x-coordinate of the tile.
    /// @param y The y-coordinate of the tile.
    /// @param color The color data for the tile (e.g., 0xRRGGBB).
    /// @param text A short text description or message for the tile.
    /// @param contentHash A bytes32 hash linking to off-chain content.
    function mintTile(int256 x, int256 y, uint32 color, string memory text, bytes32 contentHash) external payable whenNotPaused nonReentrant {
        require(_coordsToTokenId[x][y] == 0, "Tile already exists");
        require(msg.value >= mintCost, "Insufficient funds for minting");

        _tokenIdCounter.increment();
        uint256 newTokenId = _tokenIdCounter.current();

        _safeMint(msg.sender, newTokenId); // Mints the ERC721 token

        tiles[newTokenId] = TileData(x, y, color, text, contentHash);
        _coordsToTokenId[x][y] = newTokenId;
        _tokenIdToCoords[newTokenId] = tuple(x, y);

        emit TileMinted(newTokenId, x, y, msg.sender, color, contentHash);
        // Refund excess if any
        if (msg.value > mintCost) {
            payable(msg.sender).transfer(msg.value - mintCost);
        }
    }

    /// @dev Updates the data for an existing tile. Callable by tile owner or approved address.
    /// @param x The x-coordinate of the tile.
    /// @param y The y-coordinate of the tile.
    /// @param color The new color data.
    /// @param text The new text description.
    /// @param contentHash The new content hash.
    function updateTileData(int256 x, int256 y, uint32 color, string memory text, bytes32 contentHash) external payable whenNotPaused nonReentrant tileExists(x, y) {
        uint256 tokenId = _coordsToTokenId[x][y];
        // Checks ownership/approval and existence
        onlyOwnerOrApproved(tokenId);
        // Checks if tile is locked
        tileNotLocked(tokenId);
        require(msg.value >= updateCost, "Insufficient funds for updating");

        TileData storage tile = tiles[tokenId];
        tile.color = color;
        tile.text = text;
        tile.contentHash = contentHash;

        emit TileUpdated(tokenId, x, y, msg.sender, color, text, contentHash);
         // Refund excess if any
        if (msg.value > updateCost) {
            payable(msg.sender).transfer(msg.value - updateCost);
        }
    }

    /// @dev Adds an annotation message to an existing tile. Anyone can annotate.
    /// @param x The x-coordinate of the tile.
    /// @param y The y-coordinate of the tile.
    /// @param message The annotation message.
    function addAnnotationToTile(int256 x, int256 y, string memory message) external whenNotPaused tileExists(x, y) {
        uint256 tokenId = _coordsToTokenId[x][y];
        _annotations[tokenId].push(Annotation(msg.sender, message, block.timestamp));
        emit AnnotationAdded(tokenId, x, y, msg.sender, message, block.timestamp);
    }

    /// @dev Removes an annotation from a tile by index. Callable by tile owner or moderator.
    /// @param x The x-coordinate of the tile.
    /// @param y The y-coordinate of the tile.
    /// @param annotationIndex The index of the annotation to remove.
    function removeTileAnnotation(int256 x, int256 y, uint256 annotationIndex) external whenNotPaused tileExists(x, y) {
         uint256 tokenId = _coordsToTokenId[x][y];
        address tokenOwner = ownerOf(tokenId); // Checks token existence implicitly

        require(msg.sender == tokenOwner || _annotationModerators[msg.sender], "Not authorized to remove annotation");
        require(annotationIndex < _annotations[tokenId].length, "Invalid annotation index");

        // Basic removal by swapping with last and popping (order not preserved)
        uint256 lastIndex = _annotations[tokenId].length - 1;
        if (annotationIndex != lastIndex) {
            _annotations[tokenId][annotationIndex] = _annotations[tokenId][lastIndex];
        }
        _annotations[tokenId].pop();

        emit AnnotationRemoved(tokenId, x, y, msg.sender, uint26(annotationIndex)); // Cast to uint26, reasonable limit
    }

    /// @dev Locks a tile for a specified duration, preventing updates. Callable by tile owner or approved address.
    /// @param x The x-coordinate of the tile.
    /// @param y The y-coordinate of the tile.
    /// @param durationSeconds The duration in seconds the tile will be locked.
    function lockTile(int256 x, int256 y, uint256 durationSeconds) external whenNotPaused tileExists(x, y) {
        uint256 tokenId = _coordsToTokenId[x][y];
         // Checks ownership/approval and existence
        onlyOwnerOrApproved(tokenId);

        uint256 unlockTime = block.timestamp + durationSeconds;
        _tileLocks[tokenId] = unlockTime;

        emit TileLocked(tokenId, x, y, msg.sender, unlockTime);
    }

    /// @dev Sets an external URL link for a tile. Callable by tile owner or approved address.
    /// @param x The x-coordinate of the tile.
    /// @param y The y-coordinate of the tile.
    /// @param url The external URL string.
    function setTileLink(int256 x, int256 y, string memory url) external whenNotPaused tileExists(x, y) {
         uint256 tokenId = _coordsToTokenId[x][y];
         // Checks ownership/approval and existence
        onlyOwnerOrApproved(tokenId);

        _tileLinks[tokenId] = url;
        emit LinkSet(tokenId, x, y, msg.sender, url);
    }

    /// @dev Transfers ownership of a tile NFT using coordinates.
    /// @param x The x-coordinate of the tile.
    /// @param y The y-coordinate of the tile.
    /// @param to The recipient address.
    function transferTile(int256 x, int256 y, address to) external whenNotPaused tileExists(x, y) {
        uint256 tokenId = _coordsToTokenId[x][y];
        // ERC721 safeTransferFrom already checks owner/approved
        safeTransferFrom(msg.sender, to, tokenId);
        // Note: Tile data and annotations remain associated with the tokenId
    }

    /// @dev Burns a tile NFT, removing it from circulation. Callable by tile owner.
    /// Note: This effectively "deletes" the tile and its associated on-chain data (TileData, annotations, links, locks).
    /// @param x The x-coordinate of the tile.
    /// @param y The y-coordinate of the tile.
    function burnTile(int256 x, int256 y) external whenNotPaused tileExists(x, y) {
        uint256 tokenId = _coordsToTokenId[x][y];
        require(ownerOf(tokenId) == msg.sender, "Must be tile owner to burn");

        // Clean up associated data (this is important for gas efficiency and state tidiness)
        delete tiles[tokenId];
        delete _coordsToTokenId[x][y];
        delete _tokenIdToCoords[tokenId];
        delete _annotations[tokenId]; // Deletes the dynamic array
        delete _tileLocks[tokenId];
        delete _tileLinks[tokenId];

        _burn(tokenId); // Burns the ERC721 token

        // No specific event for burn beyond the standard ERC721 Transfer event (to address 0)
    }


    // --- Query Functions ---

    /// @dev Gets the core TileData struct for a tile at specified coordinates.
    /// @param x The x-coordinate.
    /// @param y The y-coordinate.
    /// @return The TileData struct.
    function getTileData(int256 x, int256 y) public view tileExists(x, y) returns (TileData memory) {
        uint256 tokenId = _coordsToTokenId[x][y];
        return tiles[tokenId];
    }

    /// @dev Gets the token ID for a tile at specified coordinates.
    /// @param x The x-coordinate.
    /// @param y The y-coordinate.
    /// @return The token ID, or 0 if the tile does not exist.
    function getTileTokenId(int256 x, int256 y) public view returns (uint256) {
        return _coordsToTokenId[x][y]; // Returns 0 if not set
    }

    /// @dev Gets the coordinates for a given token ID.
    /// @param tokenId The token ID.
    /// @return The (x,y) coordinates. Returns (0,0) if token ID is invalid or not a tile.
    function getTileCoordinates(uint256 tokenId) public view returns (int256, int256) {
        // We check existence implicitly by checking if the token ID has associated coords data
         if (_tokenIdToCoords[tokenId].f1 == 0 && _tokenIdToCoords[tokenId].f2 == 0 && _coordsToTokenId[0][0] != tokenId) {
             // This is a basic check. A more robust check might involve ERC721 ownerOf(tokenId)
             // but that could revert if the token ID is completely out of range.
             // Assuming 0,0 is a valid coord, need special handling or rely on _coordsToTokenId
             // The _coordsToTokenId mapping returning 0 for non-existent is more reliable
             // Let's use _coordsToTokenId to verify existence first
             (int256 x, int256 y) = _tokenIdToCoords[tokenId];
             if (_coordsToTokenId[x][y] != tokenId) {
                 // Mismatch means the token ID doesn't map correctly to coordinates
                 return (0, 0);
             }
             return (x, y);
         }
         return _tokenIdToCoords[tokenId];
    }


    /// @dev Gets all annotations for a tile.
    /// @param x The x-coordinate.
    /// @param y The y-coordinate.
    /// @return An array of Annotation structs.
    function getTileAnnotations(int256 x, int256 y) public view tileExists(x, y) returns (Annotation[] memory) {
        uint256 tokenId = _coordsToTokenId[x][y];
        return _annotations[tokenId];
    }

    /// @dev Gets the unlock timestamp for a tile.
    /// @param x The x-coordinate.
    /// @param y The y-coordinate.
    /// @return The unlock timestamp (0 if not locked).
    function getTileLockStatus(int256 x, int256 y) public view tileExists(x, y) returns (uint256) {
        uint256 tokenId = _coordsToTokenId[x][y];
        return _tileLocks[tokenId];
    }

    /// @dev Gets the external URL link for a tile.
    /// @param x The x-coordinate.
    /// @param y The y-coordinate.
    /// @return The URL string.
    function getTileLink(int256 x, int256 y) public view tileExists(x, y) returns (string memory) {
        uint256 tokenId = _coordsToTokenId[x][y];
        return _tileLinks[tokenId];
    }

     /// @dev Checks if a tile exists at the given coordinates.
    /// @param x The x-coordinate.
    /// @param y The y-coordinate.
    /// @return True if the tile exists, false otherwise.
    function doesTileExist(int256 x, int256 y) public view returns (bool) {
        // A token ID of 0 means no tile exists at these coordinates in our mapping
        return _coordsToTokenId[x][y] != 0;
    }

    /// @dev Checks if a tile is currently locked.
    /// @param x The x-coordinate.
    /// @param y The y-coordinate.
    /// @return True if the tile is locked, false otherwise.
    function isTileLocked(int256 x, int256 y) public view tileExists(x, y) returns (bool) {
        uint256 tokenId = _coordsToTokenId[x][y];
        return _tileLocks[tokenId] > block.timestamp;
    }

    // --- Admin/Config Functions ---

    /// @dev Sets the cost to mint a new tile. Only callable by contract owner.
    /// @param _mintCost The new mint cost in Wei.
    function setMintCost(uint256 _mintCost) external onlyOwner {
        mintCost = _mintCost;
        emit MintCostSet(_mintCost);
    }

    /// @dev Sets the cost to update an existing tile. Only callable by contract owner.
    /// @param _updateCost The new update cost in Wei.
    function setUpdateCost(uint256 _updateCost) external onlyOwner {
        updateCost = _updateCost;
        emit UpdateCostSet(_updateCost);
    }

    /// @dev Pauses or unpauses the contract, disabling most interactions. Only callable by contract owner.
    /// @param _paused True to pause, false to unpause.
    function pauseCanvas(bool _paused) external onlyOwner {
        paused = _paused;
        emit Paused(_paused);
    }

    /// @dev Allows the contract owner to withdraw the collected Ether.
    /// @param recipient The address to send the funds to.
    function withdrawFunds(address payable recipient) external onlyOwner nonReentrant {
        uint256 balance = address(this).balance;
        require(balance > 0, "No funds to withdraw");
        (bool success, ) = recipient.call{value: balance}("");
        require(success, "Withdrawal failed");
        emit FundsWithdrawn(recipient, balance);
    }

    /// @dev Adds an address to the list of annotation moderators. Only callable by contract owner.
    /// Moderators can remove any annotation.
    /// @param moderator The address to add as a moderator.
    function addAnnotationModerator(address moderator) external onlyOwner {
        require(moderator != address(0), "Invalid address");
        _annotationModerators[moderator] = true;
        emit ModeratorAdded(moderator);
    }

    /// @dev Removes an address from the list of annotation moderators. Only callable by contract owner.
    /// @param moderator The address to remove.
    function removeAnnotationModerator(address moderator) external onlyOwner {
        require(moderator != address(0), "Invalid address");
        _annotationModerators[moderator] = false;
        emit ModeratorRemoved(moderator);
    }

    // --- Moderator Check Function ---

    /// @dev Checks if an address is an annotation moderator.
    /// @param account The address to check.
    /// @return True if the address is a moderator, false otherwise.
    function isAnnotationModerator(address account) public view returns (bool) {
        return _annotationModerators[account];
    }

    // --- Internal/Utility Functions (Inherited or Helper) ---
    // OpenZeppelin provides necessary internal helpers like _safeMint, _burn, etc.
    // We don't need to explicitly list them as they are not part of the public ABI count requirement.

    // --- Fallback/Receive ---
    // No explicit receive or fallback function needed for standard operation, Ether is handled by payable functions.
}
```