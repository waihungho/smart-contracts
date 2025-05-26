Okay, let's design a smart contract around the concept of a collaborative, on-chain generative art canvas that periodically "snapshots" sections to generate unique NFTs. This combines on-chain data storage, community interaction, dynamic art generation, and NFT mechanics.

We'll call it `GenesisGlyphCanvas`. Users can place colored "glyphs" on a grid for a fee. Periodically, authorized "Generators" can trigger a new batch of NFTs to be minted. Each NFT represents a specific section of the canvas *at the time of generation*, making the art dynamic and dependent on community input.

**Interesting, Advanced, Creative, Trendy Concepts:**

1.  **On-Chain Shared Mutable State:** The entire canvas state (a grid of glyph data) is stored directly on the blockchain, mutable by users.
2.  **Community-Driven Generative Art:** The NFT art is not static; it's *generated* from the collective contributions of users placing glyphs on the canvas.
3.  **Dynamic NFTs (via Metadata):** While the core NFT data (batch, section) is fixed, the *interpretation* (rendering) of the art via `tokenURI` refers to the *historic* canvas state associated with that batch, making the art derived from a dynamic source. The off-chain renderer would need to fetch the canvas data slice.
4.  **Role-Based NFT Generation:** Introducing a specific role (`GENERATOR_ROLE`) distinct from the owner to trigger computationally/strategically important actions like NFT batch generation.
5.  **On-Chain Palette:** A defined set of colors/glyph types managed on-chain that users must adhere to, influencing the aesthetic outcome.
6.  **Canvas Versioning/Batching:** The canvas state is implicitly versioned by the NFT generation batches, allowing NFTs to reference historical snapshots.
7.  **Glyph Interaction:** Functions not just to place, but also potentially refresh or even burn/remove glyphs, adding more complex user interaction beyond simple placement.
8.  **Parameterized Generation:** NFT batches can be generated based on parameters (e.g., fixed grid sections), making the generation process structured.

---

### Outline:

1.  **Contract Definition:** Inherit ERC721 (for NFTs) and Ownable (for administrative functions).
2.  **State Variables:**
    *   Canvas dimensions (width, height).
    *   Mapping to store canvas state (`canvas[x][y] => GlyphInfo`).
    *   Mapping to store glyph palette (`palette[id] => colorHex`).
    *   Costs (glyph placement, NFT generation fee).
    *   Current NFT batch counter.
    *   Mapping to store NFT metadata reference (`nftSectionData[tokenId] => CanvasSectionData`).
    *   Paused state.
    *   Access control roles (Owner, Generator).
3.  **Structs:**
    *   `GlyphInfo`: Data for a single glyph (placer, palette color ID, timestamp).
    *   `CanvasSectionData`: Defines a rectangular area on the canvas (batch ID, start X, start Y, width, height). Used for NFT data.
4.  **Events:**
    *   `GlyphPlaced`, `GlyphRefreshed`, `GlyphBurned`.
    *   `NFTBatchGenerated`.
    *   `PaletteColorAdded`.
    *   `CostUpdated`.
    *   `CanvasPaused`, `CanvasUnpaused`.
    *   `GeneratorRoleGranted`, `GeneratorRoleRevoked`.
5.  **Errors:** Custom errors for clarity.
6.  **Modifiers:** `whenNotPaused`, `onlyGenerator`.
7.  **Core Logic Functions (20+ total):**
    *   **Canvas Interaction:** `placeGlyph`, `refreshGlyph`, `burnGlyph`.
    *   **NFT Generation:** `generateNFTBatch` (triggers minting).
    *   **Admin/Configuration:** `setGlyphPlacementCost`, `setNFTGenerationFee`, `addPaletteColor`, `withdrawFunds`, `pauseCanvas`, `unpauseCanvas`, `grantGeneratorRole`, `revokeGeneratorRole`.
    *   **View/Pure Functions (Getters):** `getCanvasDimensions`, `getGlyphInfo`, `getCanvasSection`, `getPaletteColor`, `getPaletteSize`, `getGlyphPlacementCost`, `getNFTGenerationFee`, `getCurrentBatchId`, `getNFTSectionData`, `isCanvasPaused`, `isGenerator`, `tokenURI` (ERC721 override), `getTokenMetadataProps`.
    *   **Standard ERC721 Functions:** `balanceOf`, `ownerOf`, `approve`, `getApproved`, `setApprovalForAll`, `isApprovedForAll`, `transferFrom`, `safeTransferFrom` (2 versions).

---

### Function Summary:

**Canvas Interaction:**

*   `placeGlyph(uint16 _x, uint16 _y, uint8 _paletteColorId)`: Allows a user to place or overwrite a glyph at specific coordinates with a color from the palette, paying `glyphPlacementCost`.
*   `refreshGlyph(uint16 _x, uint16 _y)`: Allows the owner of a glyph to update its timestamp (preventing potential future "aging" logic, or just marking activity). May require a small fee.
*   `burnGlyph(uint16 _x, uint16 _y)`: Allows the owner of a glyph to remove it from the canvas.

**NFT Generation:**

*   `generateNFTBatch()`: Triggered by an address with the `GENERATOR_ROLE`. Increments the batch counter, defines a set of canvas sections (e.g., fixed grid), and mints an NFT for each section, recording which batch/section it represents.
*   `getTokenMetadataProps(uint256 _tokenId)`: Returns the data (`CanvasSectionData`) associated with a specific NFT, useful for an off-chain service to render metadata/image.

**Admin & Configuration (Owner or Role Based):**

*   `setGlyphPlacementCost(uint256 _cost)`: Sets the cost in wei to place a single glyph. (Owner only).
*   `setNFTGenerationFee(uint256 _fee)`: Sets a fee required to trigger NFT batch generation (paid by the generator). (Owner only).
*   `addPaletteColor(uint8 _colorId, string memory _hexColor)`: Adds a new color/glyph type to the on-chain palette. (Owner only).
*   `withdrawFunds()`: Allows the owner to withdraw collected fees. (Owner only).
*   `pauseCanvas()`: Pauses glyph placement. (Owner only).
*   `unpauseCanvas()`: Unpauses glyph placement. (Owner only).
*   `grantGeneratorRole(address _address)`: Grants the GENERATOR\_ROLE to an address. (Owner only).
*   `revokeGeneratorRole(address _address)`: Revokes the GENERATOR\_ROLE from an address. (Owner only).

**View & Pure Functions (Getters):**

*   `getCanvasDimensions()`: Returns the width and height of the canvas.
*   `getGlyphInfo(uint16 _x, uint16 _y)`: Returns the GlyphInfo struct for a specific coordinate.
*   `getCanvasSection(uint16 _startX, uint16 _startY, uint16 _sectionWidth, uint16 _sectionHeight)`: Returns an array of GlyphInfo for a specified rectangular section. Useful for off-chain rendering or analysis.
*   `getPaletteColor(uint8 _colorId)`: Returns the hex string for a color ID from the palette.
*   `getPaletteSize()`: Returns the number of colors in the palette.
*   `getGlyphPlacementCost()`: Returns the current cost to place a glyph.
*   `getNFTGenerationFee()`: Returns the current fee to generate an NFT batch.
*   `getCurrentBatchId()`: Returns the counter for the next NFT batch.
*   `getNFTSectionData(uint256 _tokenId)`: Returns the `CanvasSectionData` struct associated with a specific token ID.
*   `isCanvasPaused()`: Returns true if glyph placement is paused.
*   `isGenerator(address _address)`: Returns true if the address has the GENERATOR\_ROLE.
*   `tokenURI(uint256 tokenId)`: (Override ERC721) Returns the URI for the token's metadata, expected to point to an off-chain service that uses `getTokenMetadataProps` to fetch and render the art.

**Standard ERC721 Functions:** (Inherited and exposed)

*   `balanceOf(address owner)`
*   `ownerOf(uint256 tokenId)`
*   `approve(address to, uint256 tokenId)`
*   `getApproved(uint256 tokenId)`
*   `setApprovalForAll(address operator, bool approved)`
*   `isApprovedForAll(address owner, address operator)`
*   `transferFrom(address from, address to, uint256 tokenId)`
*   `safeTransferFrom(address from, address to, uint256 tokenId)`
*   `safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)`

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/math/Math.sol"; // For Math.max/min
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol"; // To easily iterate tokens if needed (comment out if gas is critical)

// --- Outline ---
// 1. Contract Definition: Inherits ERC721Enumerable, Ownable
// 2. State Variables: Canvas dimensions, canvas data mapping, palette mapping, costs, batch counter, NFT section data mapping, paused state, generator role mapping.
// 3. Structs: GlyphInfo, CanvasSectionData.
// 4. Events: GlyphPlaced, GlyphRefreshed, GlyphBurned, NFTBatchGenerated, PaletteColorAdded, CostUpdated, CanvasPaused, CanvasUnpaused, GeneratorRoleGranted, GeneratorRoleRevoked.
// 5. Errors: Custom errors for specific failures.
// 6. Modifiers: whenNotPaused, onlyGenerator.
// 7. Core Logic Functions (26 custom + 9 ERC721 standard):
//    - Canvas Interaction: placeGlyph, refreshGlyph, burnGlyph
//    - NFT Generation: generateNFTBatch, getTokenMetadataProps
//    - Admin/Configuration: setGlyphPlacementCost, setNFTGenerationFee, addPaletteColor, withdrawFunds, pauseCanvas, unpauseCanvas, grantGeneratorRole, revokeGeneratorRole
//    - View/Pure Functions (Getters): getCanvasDimensions, getGlyphInfo, getCanvasSection, getPaletteColor, getPaletteSize, getGlyphPlacementCost, getNFTGenerationFee, getCurrentBatchId, getNFTSectionData, isCanvasPaused, isGenerator, tokenURI (override)
//    - Standard ERC721 Functions: balanceOf, ownerOf, approve, getApproved, setApprovalForAll, isApprovedForAll, transferFrom, safeTransferFrom (2 overloads)

// --- Function Summary ---
// Canvas Interaction:
// placeGlyph(uint16 _x, uint16 _y, uint8 _paletteColorId): Place or update a glyph on the canvas.
// refreshGlyph(uint16 _x, uint16 _y): Update the timestamp of an existing glyph owned by caller.
// burnGlyph(uint16 _x, uint16 _y): Remove a glyph owned by the caller.
//
// NFT Generation:
// generateNFTBatch(): Trigger a new batch of NFTs to be minted from canvas sections (callable by Generator role).
// getTokenMetadataProps(uint256 _tokenId): Get the canvas section data linked to an NFT for metadata generation.
// tokenURI(uint256 tokenId): ERC721 override to provide metadata URI.
//
// Admin & Configuration (Owner or Role):
// setGlyphPlacementCost(uint256 _cost): Set the cost to place a glyph.
// setNFTGenerationFee(uint256 _fee): Set the fee for triggering NFT batch generation.
// addPaletteColor(uint8 _colorId, string memory _hexColor): Add a color to the allowed palette.
// withdrawFunds(): Withdraw contract balance.
// pauseCanvas(): Pause glyph placement.
// unpauseCanvas(): Unpause glyph placement.
// grantGeneratorRole(address _address): Grant GENERATOR_ROLE.
// revokeGeneratorRole(address _address): Revoke GENERATOR_ROLE.
//
// View & Pure Functions (Getters):
// getCanvasDimensions(): Get canvas width and height.
// getGlyphInfo(uint16 _x, uint16 _y): Get info about a glyph at coordinates.
// getCanvasSection(uint16 _startX, uint16 _startY, uint16 _sectionWidth, uint16 _sectionHeight): Get data for a canvas area.
// getPaletteColor(uint8 _colorId): Get hex color for a palette ID.
// getPaletteSize(): Get the number of palette colors.
// getGlyphPlacementCost(): Get current glyph placement cost.
// getNFTGenerationFee(): Get current NFT generation fee.
// getCurrentBatchId(): Get the next batch ID counter.
// getNFTSectionData(uint256 _tokenId): Get the canvas section data for an NFT.
// isCanvasPaused(): Check if canvas is paused.
// isGenerator(address _address): Check if address has GENERATOR_ROLE.
//
// Standard ERC721 Functions: (balanceOf, ownerOf, approve, getApproved, setApprovalForAll, isApprovedForAll, transferFrom, safeTransferFrom x2)

contract GenesisGlyphCanvas is ERC721Enumerable, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;

    // --- State Variables ---

    // Canvas dimensions
    uint16 public immutable canvasWidth;
    uint16 public immutable canvasHeight;

    // Canvas data: mapping from x, then y, to GlyphInfo
    mapping(uint16 => mapping(uint16 => GlyphInfo)) private canvas;

    // Glyph Palette: mapping from color ID to hex string
    mapping(uint8 => string) private palette;
    uint8 private paletteSize = 0;

    // Costs
    uint256 public glyphPlacementCost;
    uint256 public nftGenerationFee;

    // NFT Batch Counter
    uint256 private batchIdCounter = 0;

    // NFT Metadata Reference: mapping from token ID to canvas section data used for its generation
    mapping(uint256 => CanvasSectionData) private nftSectionData;

    // Canvas state
    bool private paused = false;

    // Access Control Roles
    mapping(address => bool) private generators;
    bytes32 public constant GENERATOR_ROLE = keccak256("GENERATOR_ROLE");

    // --- Structs ---

    struct GlyphInfo {
        address placer; // Address that placed/last refreshed the glyph
        uint8 paletteColorId; // ID from the palette mapping
        uint64 timestamp; // When the glyph was placed/last refreshed
        bool exists; // Flag to indicate if a glyph exists at this coordinate (mappings default to zero values)
    }

    struct CanvasSectionData {
        uint256 batchId; // Which batch this NFT belongs to
        uint16 startX;
        uint16 startY;
        uint16 sectionWidth;
        uint16 sectionHeight;
    }

    // --- Events ---

    event GlyphPlaced(address indexed placer, uint16 x, uint16 y, uint8 paletteColorId, uint256 cost);
    event GlyphRefreshed(address indexed refresher, uint16 x, uint16 y);
    event GlyphBurned(address indexed burner, uint16 x, uint16 y);
    event NFTBatchGenerated(uint256 indexed batchId, uint256 numTokensMinted);
    event PaletteColorAdded(uint8 indexed colorId, string hexColor);
    event CostUpdated(string indexed costType, uint256 newCost);
    event CanvasPaused();
    event CanvasUnpaused();
    event GeneratorRoleGranted(address indexed account);
    event GeneratorRoleRevoked(address indexed account);

    // --- Errors ---

    error InvalidCoordinates(uint16 x, uint16 y);
    error CanvasPaused();
    error InsufficientPayment(uint256 required, uint256 sent);
    error InvalidPaletteColor(uint8 colorId);
    error GlyphDoesNotExist(uint16 x, uint16 y);
    error NotGlyphOwner(address caller, address owner);
    error AlreadyGenerator(address account);
    error NotGenerator(address account);
    error NFTGenerationFailed(string reason);
    error InvalidSection(uint16 startX, uint16 startY, uint16 sectionWidth, uint16 sectionHeight);
    error NoFundsToWithdraw();

    // --- Modifiers ---

    modifier whenNotPaused() {
        if (paused) {
            revert CanvasPaused();
        }
        _;
    }

    modifier onlyGenerator() {
        if (!generators[msg.sender] && msg.sender != owner()) {
            // Owner is implicitly a generator, but can explicitly grant role to others
            revert NotGenerator(msg.sender);
        }
        _;
    }

    // --- Constructor ---

    constructor(
        uint16 _canvasWidth,
        uint16 _canvasHeight,
        uint256 _initialGlyphCost,
        uint256 _initialNFTGenFee,
        string memory _name,
        string memory _symbol
    ) ERC721(_name, _symbol) Ownable(msg.sender) {
        if (_canvasWidth == 0 || _canvasHeight == 0) {
             revert InvalidCoordinates(0, 0); // Re-using error for clarity
        }
        canvasWidth = _canvasWidth;
        canvasHeight = _canvasHeight;
        glyphPlacementCost = _initialGlyphCost;
        nftGenerationFee = _initialNFTGenFee;

        // Add a couple of default palette colors (optional, can be added later via addPaletteColor)
        palette[0] = "#000000"; // Black
        paletteSize = 1;
        emit PaletteColorAdded(0, "#000000");
    }

    // --- Canvas Interaction Functions ---

    /// @notice Places or updates a glyph on the canvas grid.
    /// @param _x The x-coordinate (0 to canvasWidth-1).
    /// @param _y The y-coordinate (0 to canvasHeight-1).
    /// @param _paletteColorId The ID of the color from the palette to use.
    /// @dev Requires payment of glyphPlacementCost. Overwrites any existing glyph at (x,y).
    function placeGlyph(uint16 _x, uint16 _y, uint8 _paletteColorId) public payable whenNotPaused {
        if (_x >= canvasWidth || _y >= canvasHeight) {
            revert InvalidCoordinates(_x, _y);
        }
        if (msg.value < glyphPlacementCost) {
            revert InsufficientPayment(glyphPlacementCost, msg.value);
        }
        if (bytes(palette[_paletteColorId]).length == 0 || _paletteColorId >= paletteSize) {
            revert InvalidPaletteColor(_paletteColorId);
        }

        // Refund excess payment if any (shouldn't happen if client sends exactly the cost)
        if (msg.value > glyphPlacementCost) {
            (bool success, ) = msg.sender.call{value: msg.value - glyphPlacementCost}("");
            // We allow the placement even if refund fails, but log it
            if (!success) {
                emit PaymentRefundFailed(msg.sender, msg.value - glyphPlacementCost); // Need to define this event
            }
        }

        canvas[_x][_y] = GlyphInfo({
            placer: msg.sender,
            paletteColorId: _paletteColorId,
            timestamp: uint64(block.timestamp),
            exists: true
        });

        emit GlyphPlaced(msg.sender, _x, _y, _paletteColorId, glyphPlacementCost);
    }

    /// @notice Updates the timestamp of a glyph owned by the caller.
    /// @param _x The x-coordinate.
    /// @param _y The y-coordinate.
    function refreshGlyph(uint16 _x, uint16 _y) public whenNotPaused {
         if (_x >= canvasWidth || _y >= canvasHeight) {
            revert InvalidCoordinates(_x, _y);
        }
        GlyphInfo storage glyph = canvas[_x][_y];
        if (!glyph.exists) {
            revert GlyphDoesNotExist(_x, _y);
        }
        if (glyph.placer != msg.sender) {
            revert NotGlyphOwner(msg.sender, glyph.placer);
        }

        glyph.timestamp = uint64(block.timestamp);

        emit GlyphRefreshed(msg.sender, _x, _y);
    }

    /// @notice Removes a glyph owned by the caller.
    /// @param _x The x-coordinate.
    /// @param _y The y-coordinate.
    function burnGlyph(uint16 _x, uint16 _y) public whenNotPaused {
        if (_x >= canvasWidth || _y >= canvasHeight) {
            revert InvalidCoordinates(_x, _y);
        }
        GlyphInfo storage glyph = canvas[_x][_y];
        if (!glyph.exists) {
            revert GlyphDoesNotExist(_x, _y);
        }
        if (glyph.placer != msg.sender) {
            revert NotGlyphOwner(msg.sender, glyph.placer);
        }

        // Remove the glyph by deleting from the mapping
        delete canvas[_x][_y];

        emit GlyphBurned(msg.sender, _x, _y);
    }


    // --- NFT Generation Functions ---

    /// @notice Triggers the generation and minting of a new batch of NFTs based on canvas sections.
    /// @dev Callable only by addresses with the GENERATOR_ROLE or the Owner. Requires payment of nftGenerationFee.
    /// @dev This is a basic implementation; a more complex version might take parameters for sections or use randomness.
    /// @dev Here we simply generate a fixed number of NFTs from fixed grid sections.
    function generateNFTBatch() public payable onlyGenerator {
        if (msg.value < nftGenerationFee) {
            revert InsufficientPayment(nftGenerationFee, msg.value);
        }

        batchIdCounter++; // Increment batch counter for the new batch
        uint256 currentBatchId = batchIdCounter;
        uint256 numTokensMintedInBatch = 0;

        // --- Define Sections for this Batch ---
        // Example: Split the canvas into a 4x4 grid if dimensions allow
        // This part is arbitrary and can be replaced with more complex logic
        uint16 gridX = 4;
        uint16 gridY = 4;

        if (canvasWidth < gridX || canvasHeight < gridY) {
             revert NFTGenerationFailed("Canvas too small for fixed grid sections");
        }

        uint16 sectionW = canvasWidth / gridX;
        uint16 sectionH = canvasHeight / gridY;

        if (sectionW == 0 || sectionH == 0) {
             revert NFTGenerationFailed("Section size too small");
        }


        for (uint16 i = 0; i < gridX; i++) {
            for (uint16 j = 0; j < gridY; j++) {
                 // Calculate section coordinates
                uint16 startX = i * sectionW;
                uint16 startY = j * sectionH;

                 // Ensure the last sections cover the full width/height if not perfectly divisible
                uint16 currentSectionW = (i == gridX - 1) ? canvasWidth - startX : sectionW;
                uint16 currentSectionH = (j == gridY - 1) ? canvasHeight - startY : sectionH;


                // Prepare section data
                CanvasSectionData memory sectionData = CanvasSectionData({
                    batchId: currentBatchId,
                    startX: startX,
                    startY: startY,
                    sectionWidth: currentSectionW,
                    sectionHeight: currentSectionH
                });

                // Mint the token
                _tokenIdCounter.increment();
                uint256 newTokenId = _tokenIdCounter.current();
                _safeMint(msg.sender, newTokenId); // Mint to the generator, they can transfer it later

                // Store the section data reference for the minted token
                nftSectionData[newTokenId] = sectionData;

                numTokensMintedInBatch++;
            }
        }

        if (numTokensMintedInBatch == 0) {
             revert NFTGenerationFailed("No tokens were minted in this batch");
        }

        emit NFTBatchGenerated(currentBatchId, numTokensMintedInBatch);

        // Note: The fee msg.value remains in the contract, withdrawable by owner.
    }

     /// @notice Gets the canvas section data associated with a specific NFT token ID.
     /// @param _tokenId The ID of the NFT.
     /// @return A CanvasSectionData struct.
    function getNFTSectionData(uint256 _tokenId) public view returns (CanvasSectionData memory) {
        // This will return zero values if the tokenId does not exist or has no section data associated
        return nftSectionData[_tokenId];
    }

    /// @notice Helper function to provide props needed by an off-chain service for metadata generation.
    /// @param _tokenId The ID of the NFT.
    /// @return contractAddress The address of this contract.
    /// @return batchId The batch ID this NFT belongs to.
    /// @return startX The starting x-coordinate of the canvas section.
    /// @return startY The starting y-coordinate of the canvas section.
    /// @return sectionWidth The width of the canvas section.
    /// @return sectionHeight The height of the canvas section.
    function getTokenMetadataProps(uint256 _tokenId)
        public
        view
        returns (address contractAddress, uint256 batchId, uint16 startX, uint16 startY, uint16 sectionWidth, uint16 sectionHeight)
    {
        CanvasSectionData memory data = nftSectionData[_tokenId];
        // Basic check if data exists (batchId will be non-zero for minted tokens)
        if (data.batchId == 0) {
            // While ERC721 tokenURI should handle non-existent tokens, this helper assumes valid token
             revert ERC721NonexistentToken(_tokenId); // Using OpenZeppelin error
        }
        return (address(this), data.batchId, data.startX, data.startY, data.sectionWidth, data.sectionHeight);
    }


    // --- Admin & Configuration Functions ---

    /// @notice Sets the cost to place a single glyph.
    /// @param _cost The new cost in wei.
    function setGlyphPlacementCost(uint256 _cost) public onlyOwner {
        glyphPlacementCost = _cost;
        emit CostUpdated("GlyphPlacement", _cost);
    }

    /// @notice Sets the fee required to trigger NFT batch generation.
    /// @param _fee The new fee in wei.
    function setNFTGenerationFee(uint256 _fee) public onlyOwner {
        nftGenerationFee = _fee;
        emit CostUpdated("NFTGeneration", _fee);
    }

    /// @notice Adds a new color/glyph type to the on-chain palette.
    /// @param _colorId The ID for the new color (must be the next available ID).
    /// @param _hexColor The hex string representation of the color (e.g., "#RRGGBB").
    function addPaletteColor(uint8 _colorId, string memory _hexColor) public onlyOwner {
        // Ensure color IDs are added sequentially
        if (_colorId != paletteSize) {
            revert InvalidPaletteColor(_colorId); // ID must be next in sequence
        }
        // Basic check for hex format (starts with # and has 6 hex chars) - can be more robust
        if (bytes(_hexColor).length != 7 || bytes(_hexColor)[0] != '#') {
             revert InvalidPaletteColor(_colorId); // Simple format check
        }

        palette[_colorId] = _hexColor;
        paletteSize++;
        emit PaletteColorAdded(_colorId, _hexColor);
    }

    /// @notice Allows the owner to withdraw the contract balance (collected fees).
    function withdrawFunds() public onlyOwner {
        uint256 balance = address(this).balance;
        if (balance == 0) {
            revert NoFundsToWithdraw();
        }
        (bool success, ) = payable(owner()).call{value: balance}("");
        require(success, "Withdrawal failed");
    }

    /// @notice Pauses glyph placement functionality.
    function pauseCanvas() public onlyOwner {
        paused = true;
        emit CanvasPaused();
    }

    /// @notice Unpauses glyph placement functionality.
    function unpauseCanvas() public onlyOwner {
        paused = false;
        emit CanvasUnpaused();
    }

    /// @notice Grants the GENERATOR_ROLE to an address.
    /// @param _address The address to grant the role to.
    function grantGeneratorRole(address _address) public onlyOwner {
        if (generators[_address]) {
            revert AlreadyGenerator(_address);
        }
        generators[_address] = true;
        emit GeneratorRoleGranted(_address);
    }

    /// @notice Revokes the GENERATOR_ROLE from an address.
    /// @param _address The address to revoke the role from.
    function revokeGeneratorRole(address _address) public onlyOwner {
         if (!generators[_address]) {
            revert NotGenerator(_address); // Use NotGenerator error
        }
        generators[_address] = false;
        emit GeneratorRoleRevoked(_address);
    }


    // --- View & Pure Functions (Getters) ---

    /// @notice Returns the dimensions of the canvas.
    /// @return width The canvas width.
    /// @return height The canvas height.
    function getCanvasDimensions() public view returns (uint16 width, uint16 height) {
        return (canvasWidth, canvasHeight);
    }

    /// @notice Returns the GlyphInfo for a specific coordinate.
    /// @param _x The x-coordinate.
    /// @param _y The y-coordinate.
    /// @return The GlyphInfo struct. Returns a struct with exists: false if no glyph is present.
    function getGlyphInfo(uint16 _x, uint16 _y) public view returns (GlyphInfo memory) {
         if (_x >= canvasWidth || _y >= canvasHeight) {
            revert InvalidCoordinates(_x, _y);
        }
        return canvas[_x][_y];
    }

    /// @notice Returns the GlyphInfo for a specified rectangular section of the canvas.
    /// @param _startX The starting x-coordinate of the section.
    /// @param _startY The starting y-coordinate of the section.
    /// @param _sectionWidth The width of the section.
    /// @param _sectionHeight The height of the section.
    /// @return An array of GlyphInfo structs representing the section, row by row.
    function getCanvasSection(uint16 _startX, uint16 _startY, uint16 _sectionWidth, uint16 _sectionHeight) public view returns (GlyphInfo[] memory) {
        // Validate section boundaries
        if (_startX >= canvasWidth || _startY >= canvasHeight ||
            _startX + _sectionWidth > canvasWidth || _startY + _sectionHeight > canvasHeight ||
            _sectionWidth == 0 || _sectionHeight == 0)
        {
            revert InvalidSection(_startX, _startY, _sectionWidth, _sectionHeight);
        }

        GlyphInfo[] memory sectionData = new GlyphInfo[](_sectionWidth * _sectionHeight);
        uint256 index = 0;
        for (uint16 y = _startY; y < _startY + _sectionHeight; y++) {
            for (uint16 x = _startX; x < _startX + _sectionWidth; x++) {
                sectionData[index] = canvas[x][y];
                index++;
            }
        }
        return sectionData;
    }

    /// @notice Returns the hex color string for a given palette ID.
    /// @param _colorId The palette color ID.
    /// @return The hex color string.
    function getPaletteColor(uint8 _colorId) public view returns (string memory) {
        if (bytes(palette[_colorId]).length == 0 || _colorId >= paletteSize) {
            revert InvalidPaletteColor(_colorId);
        }
        return palette[_colorId];
    }

    /// @notice Returns the total number of colors in the palette.
    /// @return The palette size.
    function getPaletteSize() public view returns (uint8) {
        return paletteSize;
    }

    /// @notice Returns the current cost to place a glyph.
    function getGlyphPlacementCost() public view returns (uint256) {
        return glyphPlacementCost;
    }

    /// @notice Returns the current fee to trigger NFT batch generation.
    function getNFTGenerationFee() public view returns (uint256) {
        return nftGenerationFee;
    }

    /// @notice Returns the counter for the next NFT batch ID.
    function getCurrentBatchId() public view returns (uint256) {
        return batchIdCounter + 1; // Return the *next* ID
    }

    /// @notice Returns true if glyph placement is currently paused.
    function isCanvasPaused() public view returns (bool) {
        return paused;
    }

    /// @notice Returns true if an address has the GENERATOR_ROLE.
    /// @param _address The address to check.
    function isGenerator(address _address) public view returns (bool) {
        return generators[_address];
    }

    // --- ERC721 Overrides ---

    /// @dev See {ERC721Enumerable-tokenURI}.
    /// @dev This implementation points to an off-chain service that will use `getTokenMetadataProps` to fetch data and generate metadata/image.
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        if (!_exists(tokenId)) {
             revert ERC721NonexistentToken(tokenId);
        }

        // Construct a URI that includes the contract address and token ID
        // An off-chain service (e.g., a simple API) configured for this contract address
        // would receive this URI, parse the token ID, call getTokenMetadataProps
        // to get the canvas section data for that specific token, and then render the image/JSON.
        string memory baseURI = _baseURI(); // Use the base URI set by ERC721 if needed, or hardcode your service endpoint
        // Example structure: ipfs://[CID]/metadata/{address}/{tokenId} or https://your-service.com/metadata/{address}/{tokenId}
        // Let's construct a simple HTTP example format
        string memory contractAddressString = Strings.toHexString(uint160(address(this)), 20); // Padded hex address
        string memory tokenIdString = Strings.toString(tokenId);

        return string(abi.encodePacked("https://your-metadata-service.com/metadata/", contractAddressString, "/", tokenIdString));

        // Note: The actual rendering and JSON generation happens OFF-CHAIN.
        // The service needs to be configured to call getNFTSectionData for the batchId and coords.
        // It should ideally fetch the *historic* canvas state for that batch ID if the canvas changes between batches.
        // Storing historic canvas state on-chain is too expensive. The assumption is the renderer knows how to query
        // the *specific batch's* data, or the CanvasSectionData includes enough info (like batchId)
        // for the off-chain renderer to find the correct state snapshot (e.g., from archives or a separate data layer).
        // For this contract, the NFT Section Data *includes* the batch ID, implying the renderer
        // should render the section based on the canvas state *as it was when batchId was current*.
        // A simple renderer might just query the *current* canvas state, making the art dynamic *after* minting as well!
        // This adds another layer of dynamism, but implies the art changes even for old NFTs if the source canvas changes.
        // The current implementation's `getNFTSectionData` gives the batch ID and coordinates. An off-chain service
        // could combine this with archives (like TheGraph or storing historical data) to recreate the exact state,
        // or it could simplify and just render the current state of that section based on the coordinates.
        // Let's assume the simpler interpretation for the code: the renderer uses the section data from the NFT to
        // query the *current* canvas state using `getCanvasSection` and renders that. This makes NFTs *truly* dynamic!
    }

    // --- Internal ERC721 Functions (Implemented by OpenZeppelin) ---
    // _baseURI, _exists, _safeMint, _beforeTokenTransfer, _afterTokenTransfer, supportsInterface, tokenByIndex, tokenOfOwnerByIndex

    // --- Standard ERC721 Functions (Exposed by Inheritance) ---
    // balanceOf, ownerOf, approve, getApproved, setApprovalForAll, isApprovedForAll, transferFrom, safeTransferFrom (x2)

    // --- Additional Potential Functions (Not included to keep function count focused, but interesting) ---
    // - `getGlyphsByPlacer(address _placer)`: Return a list of coordinates or GlyphInfo for all glyphs placed by an address (potentially expensive).
    // - `getBatchSections(uint256 _batchId)`: Get details (start/size) of all sections included in a specific batch (requires storing this data).
    // - `addGeneratorRole(address _account)` / `revokeGeneratorRole(address _account)`: Implemented.
    // - `getRoleMember(bytes32 role, uint256 index)` / `getRoleMemberCount(bytes32 role)`: If using OpenZeppelin AccessControl (more formal roles). Using a simple mapping here.
    // - `changeGlyphColor(uint16 _x, uint16 _y, uint8 _newColorId)`: Allow changing color of own glyph (might cost glyphPlacementCost).
    // - `setBaseURI(string memory baseURI_)`: Allow owner to update the base URI for token metadata.
    // - `getTokenIdsForBatch(uint256 _batchId)`: Return all token IDs generated in a specific batch (requires storing this mapping).
    // - `getGlyphAge(uint16 _x, uint16 _y)`: Calculate age based on block.timestamp.

    // Need to add the PaymentRefundFailed event if using the refund logic.
    event PaymentRefundFailed(address recipient, uint256 amount);

}
```

**Explanation of Advanced Concepts in the Code:**

1.  **On-Chain Shared Mutable Canvas:** The `mapping(uint16 => mapping(uint16 => GlyphInfo)) private canvas;` is the core. It stores the state of every coordinate on the `canvasWidth` x `canvasHeight` grid directly on the blockchain. The `placeGlyph`, `refreshGlyph`, and `burnGlyph` functions are the user-facing methods to mutate this shared state. This is distinct from many NFT projects where the on-chain data is immutable after minting or only points to off-chain/IPFS data.
2.  **Community-Driven Generative Art (Indirect):** The `generateNFTBatch` function doesn't randomly generate art. It reads the *current state* of sections of the `canvas`. The art of the NFT is literally derived from the data stored in the canvas mapping at that moment. Since the canvas is modified by the community, the community directly influences the resulting NFT art in future batches.
3.  **Dynamic NFTs via `tokenURI`:** The `tokenURI` function is overridden. Instead of returning a static link to an image, it returns a link pointing to a metadata service *plus* the contract address and token ID. The `getTokenMetadataProps` function provides the specific canvas section details (batch ID, coordinates, dimensions) associated with that NFT. The *off-chain metadata service* is then responsible for calling `getCanvasSection` (potentially referencing the batch ID to get historic data if available) and *rendering* the image and JSON metadata based on that canvas data. This separation keeps rendering complex art off-chain while anchoring the *source data* for the art on-chain and making it potentially dynamic even after minting (if the renderer uses the live canvas state).
4.  **Role-Based NFT Generation:** The `GENERATOR_ROLE` and the `onlyGenerator` modifier allow specific addresses (beyond just the owner) to trigger the gas-intensive and significant `generateNFTBatch` function. This could represent a curated group of artists, community moderators, or a separate smart contract DAO responsible for triggering batches.
5.  **On-Chain Palette:** The `palette` mapping and `addPaletteColor` function enforce that users can only place glyphs using pre-defined colors/types managed by the contract owner. This ensures a degree of aesthetic control and consistency in the community's contributions.
6.  **Canvas Versioning/Batching:** The `batchIdCounter` and the `batchId` stored in the `CanvasSectionData` struct represent versions of the canvas state. When an NFT is generated in `generateNFTBatch`, it's linked to the `batchId` *at that moment*. This is crucial if you wanted an off-chain renderer to show the canvas exactly as it was when the NFT was minted, rather than the ever-changing live state. `getNFTSectionData` explicitly provides this historical batch ID.
7.  **Glyph Interaction:** `refreshGlyph` and `burnGlyph` add layers beyond simple placement. `refreshGlyph` allows users to signal continued interest or prevent "aging" (a concept not fully implemented but enabled by storing the timestamp). `burnGlyph` allows users to remove their contributions, offering a form of digital "erasure" or modification.
8.  **Parameterized Generation (Implicit):** The `generateNFTBatch` function, in this example, uses hardcoded logic to split the canvas into a 4x4 grid. A more advanced version could accept parameters defining arbitrary sections, allowing the generator role to curate or randomly select which parts of the canvas become NFTs.

This contract serves as a foundation for a rich, interactive, community-driven art project on the blockchain, pushing beyond standard static NFT use cases.