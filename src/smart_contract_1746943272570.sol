Okay, let's design a smart contract based on an "Infinite Canvas" concept. Users own "patches" of this canvas as NFTs and can paint pixels within their patches using an in-contract resource ("ink"). We'll add some advanced features like layered painting (owned vs. temporary graffiti), pixel effects, custom pixel properties, and the conceptual ability to combine/split patches.

This combines NFTs, on-chain state for visual data (though limited by gas/storage), resource management, and dynamic, user-modifiable content. The goal is a complex, interactive digital asset managed on-chain.

---

## Smart Contract: InfiniteCanvas

**Description:**

A decentralized, collaborative digital canvas where users own rectangular "patches" as ERC721 NFTs. Owners of patches can paint individual pixels within their owned area using an internal resource called "Ink". The canvas supports layered painting (permanent owned paint, temporary graffiti) and allows owners to set custom properties and apply visual effects to their pixels. The contract manages patch ownership, pixel data, ink balances, and defines the rules of interaction.

**Outline:**

1.  **License & Pragma**
2.  **Imports (ERC721, SafeMath)**
3.  **Errors (Custom Errors)**
4.  **Events**
5.  **Structs:**
    *   `PixelData`: Permanent pixel state (color, owner patch ID, paint block).
    *   `GraffitiData`: Temporary graffiti state (color, painter, fade block).
    *   `EffectData`: Temporary effect state (effect ID, fade block).
    *   `PixelPropertyData`: Custom key-value property for a pixel.
    *   `PatchCoords`: Defines coordinates for a patch NFT.
6.  **State Variables:**
    *   Admin address.
    *   Canvas dimensions (`canvasWidth`, `canvasHeight`).
    *   Patch dimensions (`patchWidth`, `patchHeight`).
    *   Mappings for canvas data (`pixels`, `graffiti`, `effects`, `pixelProperties`).
    *   Mapping for user ink balances (`userInk`).
    *   Mappings for patch NFT data (`patchCoordinates`, `patchTokenIdCounter`).
    *   Costs and parameters (`patchMintPrice`, `inkPrice`, `pixelInkCost`, `graffitiInkCost`, `effectInkCost`, `graffitiFadeBlocks`, `effectFadeBlocks`).
7.  **Modifiers:**
    *   `onlyAdmin`: Restricts function access to the admin.
    *   `onlyPatchOwner`: Restricts function access to the owner of the patch covering specific coordinates.
    *   `isValidCoord`: Ensures coordinates are within canvas bounds.
8.  **Constructor:** Initializes canvas, patch dimensions, and initial costs.
9.  **Admin Functions (8):**
    *   `setAdmin`
    *   `setPatchMintPrice`
    *   `setInkPrice`
    *   `setPixelInkCost`
    *   `setGraffitiInkCost`
    *   `setEffectInkCost`
    *   `setGraffitiFadeBlocks`
    *   `setEffectFadeBlocks`
    *   `withdrawEther`
10. **Patch (NFT) Functions (Custom + ERC721 Overrides):**
    *   `mintPatch`: Mint a new patch NFT at available coordinates.
    *   `getPatchCoordinates`: Get coordinates for a given patch token ID.
    *   `_getPatchIdAtCoords`: Internal helper to find patch ID for given coords.
    *   `combinePatches`: (Complex) Merge two adjacent patches owned by caller.
    *   `splitPatch`: (Complex) Split a patch into two, caller keeps one, gets new NFT for the other.
    *   `tokenURI`: ERC721 metadata endpoint.
    *   *(ERC721 Overrides)*: `supportsInterface`, `balanceOf`, `ownerOf`, `transferFrom`, `safeTransferFrom`, `approve`, `setApprovalForAll`, `getApproved`, `isApprovedForAll`. (Adding these explicitly gets us ~7 more functions).
11. **Canvas Interaction Functions (Painting, Graffiti, Effects, Properties) (9):**
    *   `buyInk`: Purchase ink with Ether.
    *   `paintPixel`: Paint a single pixel within owned patch (uses pixel ink).
    *   `paintPixels`: Paint multiple pixels in a batch (uses pixel ink).
    *   `graffitiPixel`: Paint a pixel anywhere (uses graffiti ink, temporary).
    *   `applyPixelEffect`: Apply a temporary effect to an owned pixel (uses effect ink).
    *   `setPixelProperty`: Set a custom property for a pixel in an owned patch.
    *   `clearGraffiti`: Manually clear graffiti at a coordinate (no cost, state reset).
    *   `clearEffect`: Manually clear effect at a coordinate (no cost, state reset).
    *   `clearPixelProperty`: Clear custom property at a coordinate (no cost, state reset).
12. **Query Functions (8):**
    *   `getCanvasDimensions`: Get canvas width and height.
    *   `getPatchDimensions`: Get default patch width and height.
    *   `getPixelData`: Get permanent pixel data.
    *   `getGraffitiData`: Get temporary graffiti data.
    *   `getPixelEffect`: Get temporary effect data.
    *   `getPixelProperty`: Get custom pixel property data.
    *   `getUserInkBalance`: Get ink balance for an address.
    *   `isCoordOwned`: Check if a coordinate is part of an owned patch.

**Function Summary:**

*   **Admin:**
    *   `setAdmin(address newAdmin)`: Sets the contract administrator. `onlyAdmin`.
    *   `setPatchMintPrice(uint256 price)`: Sets the ETH price to mint a new patch NFT. `onlyAdmin`.
    *   `setInkPrice(uint256 price)`: Sets the ETH price per unit of Ink. `onlyAdmin`.
    *   `setPixelInkCost(uint256 cost)`: Sets Ink cost per pixel for permanent paint. `onlyAdmin`.
    *   `setGraffitiInkCost(uint256 cost)`: Sets Ink cost per pixel for temporary graffiti. `onlyAdmin`.
    *   `setEffectInkCost(uint256 cost)`: Sets Ink cost per pixel for applying effects. `onlyAdmin`.
    *   `setGraffitiFadeBlocks(uint66 blocks)`: Sets how many blocks graffiti lasts. `onlyAdmin`.
    *   `setEffectFadeBlocks(uint66 blocks)`: Sets how many blocks effects last. `onlyAdmin`.
    *   `withdrawEther()`: Allows admin to withdraw collected ETH. `onlyAdmin`.
*   **Patch (NFT):**
    *   `mintPatch(uint256 x, uint256 y)`: Mints a new patch NFT covering the patch area starting at (x,y). Requires payment of `patchMintPrice`. Area must be available. Updates pixel ownership for that area.
    *   `getPatchCoordinates(uint256 tokenId)`: Returns the (x1, y1, x2, y2) coordinates for a given patch NFT ID.
    *   `combinePatches(uint256 tokenId1, uint256 tokenId2)`: (Conceptual/Complex) Allows owner to merge two adjacent patches they own into a single larger patch. Burns one NFT, updates coordinates of the other, potentially mints a new, larger NFT representing the combined area depending on implementation strategy. Requires careful state management and gas optimization.
    *   `splitPatch(uint256 tokenId, uint256 xSplit, uint256 ySplit)`: (Conceptual/Complex) Allows owner to split a patch into two smaller valid patch areas. Burns the original NFT, mints a new NFT for one of the split areas, updates coordinates/ownership for both resulting areas. Requires complex coordinate and ownership logic.
    *   `tokenURI(uint256 tokenId)`: Returns the metadata URI for a patch NFT.
    *   *(ERC721 Overrides)*: Standard ERC721 functions (`supportsInterface`, `balanceOf`, `ownerOf`, `transferFrom`, `safeTransferFrom`, `approve`, `setApprovalForAll`, `getApproved`, `isApprovedForAll`).
*   **Canvas Interaction:**
    *   `buyInk()`: User sends ETH to purchase Ink. Amount received depends on `inkPrice`.
    *   `paintPixel(uint256 x, uint256 y, uint32 color)`: Paints a single pixel at (x,y) with `color`. Requires caller to own the patch covering (x,y) and have `pixelInkCost` available Ink. Updates permanent pixel data.
    *   `paintPixels(uint256[] calldata xCoords, uint256[] calldata yCoords, uint32[] calldata colors)`: Paints multiple pixels in a batch. All coordinates must be within patches owned by the caller. Requires total Ink cost. Gas efficient for multiple updates vs single calls.
    *   `graffitiPixel(uint256 x, uint256 y, uint32 color)`: Paints a temporary pixel at (x,y) with `color`. Can be done anywhere (no patch ownership required). Requires `graffitiInkCost` available Ink. Data includes fade block.
    *   `applyPixelEffect(uint256 x, uint256 y, uint16 effectId)`: Applies a temporary effect (`effectId`) to the pixel at (x,y). Requires caller to own the patch covering (x,y) and have `effectInkCost` available Ink. Data includes fade block.
    *   `setPixelProperty(uint256 x, uint256 y, bytes32 key, bytes value)`: Sets a custom key-value property for the pixel at (x,y). Requires caller to own the patch covering (x,y). Overwrites previous property for that key.
    *   `clearGraffiti(uint256 x, uint256 y)`: Resets the graffiti data for a pixel.
    *   `clearEffect(uint256 x, uint256 y)`: Resets the effect data for a pixel.
    *   `clearPixelProperty(uint256 x, uint256 y, bytes32 key)`: Clears a specific custom property for a pixel.
*   **Query:**
    *   `getCanvasDimensions()`: Returns the total width and height of the canvas.
    *   `getPatchDimensions()`: Returns the standard width and height of a mintable patch.
    *   `getPixelData(uint256 x, uint256 y)`: Returns the permanent `PixelData` for a coordinate.
    *   `getGraffitiData(uint256 x, uint256 y)`: Returns the temporary `GraffitiData` for a coordinate. Checks fade block.
    *   `getPixelEffect(uint256 x, uint256 y)`: Returns the temporary `EffectData` for a coordinate. Checks fade block.
    *   `getPixelProperty(uint256 x, uint256 y, bytes32 key)`: Returns the value of a custom property for a coordinate.
    *   `getUserInkBalance(address user)`: Returns the Ink balance for a user address.
    *   `isCoordOwned(uint256 x, uint256 y)`: Returns true if the coordinate is within a currently owned patch.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol"; // Using Ownable for admin pattern
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

// Outline:
// 1. License & Pragma
// 2. Imports (ERC721, SafeMath)
// 3. Errors (Custom Errors)
// 4. Events
// 5. Structs
// 6. State Variables
// 7. Modifiers
// 8. Constructor
// 9. Admin Functions (8)
// 10. Patch (NFT) Functions (Custom + ERC721 Overrides) (~10)
// 11. Canvas Interaction Functions (Painting, Graffiti, Effects, Properties) (9)
// 12. Query Functions (8)
// Total functions: 8 + ~10 + 9 + 8 = ~35+

// Function Summary:
// Admin Functions:
// - setAdmin(address newAdmin): Sets the contract administrator.
// - setPatchMintPrice(uint256 price): Sets ETH price for minting a patch.
// - setInkPrice(uint256 price): Sets ETH price per unit of Ink.
// - setPixelInkCost(uint256 cost): Sets Ink cost for permanent paint.
// - setGraffitiInkCost(uint256 cost): Sets Ink cost for temporary graffiti.
// - setEffectInkCost(uint256 cost): Sets Ink cost for applying effects.
// - setGraffitiFadeBlocks(uint66 blocks): Sets graffiti duration in blocks.
// - setEffectFadeBlocks(uint66 blocks): Sets effect duration in blocks.
// - withdrawEther(): Allows admin to withdraw contract balance.
// Patch (NFT) Functions:
// - mintPatch(uint256 x, uint256 y): Mints a new patch NFT at specified coords (pays ETH).
// - getPatchCoordinates(uint256 tokenId): Gets coords for a patch NFT.
// - _getPatchIdAtCoords(uint256 x, uint256 y): Internal helper to find patch ID for coords.
// - combinePatches(uint256 tokenId1, uint256 tokenId2): Merges two adjacent owned patches (burns one NFT). (Conceptual)
// - splitPatch(uint256 tokenId, uint256 xSplit, uint256 ySplit): Splits an owned patch into two (burns one, mints one). (Conceptual)
// - tokenURI(uint256 tokenId): ERC721 metadata URI (includes patch coords).
// - Supports standard ERC721Enumerable functions (balanceOf, ownerOf, transferFrom, safeTransferFrom, approve, setApprovalForAll, getApproved, isApprovedForAll, tokenOfOwnerByIndex, tokenByIndex, totalSupply). (7+3 = 10)
// Canvas Interaction Functions:
// - buyInk(): Purchase Ink with sent ETH.
// - paintPixel(uint256 x, uint256 y, uint32 color): Paint one pixel in owned patch (uses Ink).
// - paintPixels(uint256[] calldata xCoords, uint256[] calldata yCoords, uint32[] calldata colors): Batch paint pixels in owned patches (uses Ink).
// - graffitiPixel(uint256 x, uint256 y, uint32 color): Paint temporary graffiti anywhere (uses graffiti Ink).
// - applyPixelEffect(uint256 x, uint256 y, uint16 effectId): Apply temporary effect to owned pixel (uses effect Ink).
// - setPixelProperty(uint256 x, uint256 y, bytes32 key, bytes value): Set custom property for owned pixel.
// - clearGraffiti(uint256 x, uint256 y): Clear graffiti data.
// - clearEffect(uint256 x, uint256 y): Clear effect data.
// - clearPixelProperty(uint256 x, uint256 y, bytes32 key): Clear specific pixel property.
// Query Functions:
// - getCanvasDimensions(): Get canvas width/height.
// - getPatchDimensions(): Get default patch width/height.
// - getPixelData(uint256 x, uint256 y): Get permanent pixel data.
// - getGraffitiData(uint256 x, uint256 y): Get temporary graffiti data (checks fade).
// - getPixelEffect(uint256 x, uint256 y): Get temporary effect data (checks fade).
// - getPixelProperty(uint256 x, uint256 y, bytes32 key): Get custom pixel property data.
// - getUserInkBalance(address user): Get Ink balance.
// - isCoordOwned(uint256 x, uint256 y): Check if coordinate is in an owned patch.

contract InfiniteCanvas is ERC721Enumerable, Ownable {
    using SafeMath for uint256;
    using Strings for uint256;

    // --- Errors ---
    error InvalidCoordinates();
    error CoordinatesOccupied();
    error InsufficientPayment();
    error InvalidPatchSize();
    error NotPatchOwner();
    error InsufficientInk();
    error ArraysLengthMismatch();
    error InvalidPatchIds(); // For combine/split
    error PatchesNotAdjacentOrOverlap(); // For combine
    error InvalidSplitCoords(); // For split

    // --- Events ---
    event PatchMinted(uint256 indexed tokenId, address indexed owner, uint256 x, uint256 y, uint256 width, uint256 height);
    event InkPurchased(address indexed buyer, uint256 amountETH, uint256 amountInk);
    event PixelPainted(uint256 indexed patchId, uint256 x, uint256 y, uint32 color);
    event PixelsPainted(uint256 indexed patchId, uint256 count);
    event GraffitiPainted(address indexed painter, uint256 x, uint256 y, uint32 color, uint66 fadeBlock);
    event EffectApplied(uint256 indexed patchId, uint256 x, uint256 y, uint16 effectId, uint66 fadeBlock);
    event PropertySet(uint256 indexed patchId, uint256 x, uint256 y, bytes32 key);
    event GraffitiCleared(uint256 x, uint256 y);
    event EffectCleared(uint256 x, uint256 y);
    event PropertyCleared(uint256 x, uint256 y, bytes32 key);
    event PatchesCombined(uint256 indexed newTokenId, uint256 indexed oldTokenId1, uint256 indexed oldTokenId2); // Conceptual
    event PatchSplit(uint256 indexed oldTokenId, uint256 indexed newTokenId1, uint256 indexed newTokenId2); // Conceptual
    event EtherWithdrawn(address indexed to, uint256 amount);

    // --- Structs ---
    struct PixelData {
        uint32 color; // e.g., 0xAARRGGBB
        uint256 ownerPatchId; // Token ID of the patch that permanently owns this pixel
        uint64 paintBlock; // Block number when this pixel was last painted
    }

    struct GraffitiData {
        uint32 color;
        address painter;
        uint66 fadeBlock; // Block number after which graffiti is considered faded
    }

    struct EffectData {
        uint16 effectId; // Identifier for the type of effect
        uint66 fadeBlock; // Block number after which effect is considered faded
    }

    struct PixelPropertyData {
        bytes value; // Store arbitrary data
        // Note: Key is the mapping key (bytes32)
    }

    struct PatchCoords {
        uint256 x1; // Top-left x
        uint256 y1; // Top-left y
        uint256 x2; // Bottom-right x
        uint256 y2; // Bottom-right y
    }

    // --- State Variables ---
    uint256 public immutable canvasWidth;
    uint256 public immutable canvasHeight;
    uint256 public immutable patchWidth;
    uint256 public immutable patchHeight;

    // Canvas State: Mapping (x => y => data)
    mapping(uint256 => mapping(uint256 => PixelData)) private pixels;
    mapping(uint256 => mapping(uint256 => GraffitiData)) private graffiti;
    mapping(uint256 => mapping(uint256 => EffectData)) private effects;
    mapping(uint256 => mapping(uint256 => mapping(bytes32 => PixelPropertyData))) private pixelProperties; // x => y => key => data

    // Ink Balances
    mapping(address => uint256) private userInk;

    // Patch (NFT) Data
    mapping(uint256 => PatchCoords) private patchCoordinates; // tokenId => coords
    uint256 private patchTokenIdCounter; // Next available token ID

    // Costs and Parameters
    uint256 public patchMintPrice; // in wei
    uint256 public inkPrice;       // in wei per unit of ink
    uint256 public pixelInkCost;   // Ink cost per pixel for permanent paint
    uint256 public graffitiInkCost;// Ink cost per pixel for temporary graffiti
    uint256 public effectInkCost;  // Ink cost per pixel for applying effects

    uint66 public graffitiFadeBlocks; // Blocks until graffiti fades
    uint66 public effectFadeBlocks;   // Blocks until effect fades

    // --- Constructor ---
    constructor(
        uint256 _canvasWidth,
        uint256 _canvasHeight,
        uint256 _patchWidth,
        uint256 _patchHeight,
        uint256 _patchMintPrice,
        uint256 _inkPrice,
        uint256 _pixelInkCost,
        uint256 _graffitiInkCost,
        uint256 _effectInkCost,
        uint66 _graffitiFadeBlocks,
        uint66 _effectFadeBlocks
    ) ERC721("Infinite Canvas Patch", "ICPATCH") Ownable(msg.sender) {
        if (_canvasWidth == 0 || _canvasHeight == 0 || _patchWidth == 0 || _patchHeight == 0) {
             revert InvalidPatchSize(); // Or a more general InvalidConfig
        }
        if (_canvasWidth % _patchWidth != 0 || _canvasHeight % _patchHeight != 0) {
            revert InvalidPatchSize(); // Canvas must be divisible by patch size for simple logic
        }

        canvasWidth = _canvasWidth;
        canvasHeight = _canvasHeight;
        patchWidth = _patchWidth;
        patchHeight = _patchHeight;

        patchMintPrice = _patchMintPrice;
        inkPrice = _inkPrice;
        pixelInkCost = _pixelInkCost;
        graffitiInkCost = _graffitiInkCost;
        effectInkCost = _effectInkCost;

        graffitiFadeBlocks = _graffitiFadeBlocks;
        effectFadeBlocks = _effectFadeBlocks;

        patchTokenIdCounter = 1; // Start token IDs from 1
    }

    // --- Modifiers ---
    modifier onlyAdmin() {
        _checkOwner(); // Using Ownable's _checkOwner
        _;
    }

    modifier isValidCoord(uint256 x, uint256 y) {
        if (x >= canvasWidth || y >= canvasHeight) {
            revert InvalidCoordinates();
        }
        _;
    }

    modifier onlyPatchOwner(uint256 x, uint256 y) {
        uint256 patchId = pixels[x][y].ownerPatchId;
        if (patchId == 0) { // Pixel not owned by any patch yet
             revert NotPatchOwner();
        }
        if (_ownerOf(patchId) != msg.sender) {
            revert NotPatchOwner();
        }
        _;
    }

    // --- Admin Functions (8) ---

    function setAdmin(address newAdmin) public onlyAdmin {
        transferOwnership(newAdmin); // Using Ownable's transferOwnership
    }

    function setPatchMintPrice(uint256 price) public onlyAdmin {
        patchMintPrice = price;
    }

    function setInkPrice(uint256 price) public onlyAdmin {
        inkPrice = price;
    }

    function setPixelInkCost(uint256 cost) public onlyAdmin {
        pixelInkCost = cost;
    }

    function setGraffitiInkCost(uint256 cost) public onlyAdmin {
        graffitiInkCost = cost;
    }

    function setEffectInkCost(uint256 cost) public onlyAdmin {
        effectInkCost = cost;
    }

    function setGraffitiFadeBlocks(uint66 blocks) public onlyAdmin {
        graffitiFadeBlocks = blocks;
    }

    function setEffectFadeBlocks(uint66 blocks) public onlyAdmin {
        effectFadeBlocks = blocks;
    }

    function withdrawEther() public onlyAdmin {
        uint256 balance = address(this).balance;
        if (balance > 0) {
            (bool success, ) = payable(msg.sender).call{value: balance}("");
            if (!success) {
                // Consider emitting an event or having a recovery mechanism
                // This failure might require manual intervention or a more robust withdrawal pattern
            } else {
                emit EtherWithdrawn(msg.sender, balance);
            }
        }
    }

    // --- Patch (NFT) Functions (Custom + ERC721 Overrides) ---

    function mintPatch(uint256 x, uint256 y) public payable isValidCoord(x, y) {
        if (x % patchWidth != 0 || y % patchHeight != 0) {
            revert InvalidCoordinates(); // Must be top-left corner of a valid patch grid cell
        }

        uint256 x2 = x + patchWidth - 1;
        uint256 y2 = y + patchHeight - 1;

        if (x2 >= canvasWidth || y2 >= canvasHeight) {
             revert InvalidCoordinates(); // Patch exceeds canvas bounds
        }

        // Check if any pixel in the proposed patch area is already owned
        for (uint256 cx = x; cx <= x2; cx++) {
            for (uint256 cy = y; cy <= y2; cy++) {
                if (pixels[cx][cy].ownerPatchId != 0) {
                    revert CoordinatesOccupied();
                }
            }
        }

        if (msg.value < patchMintPrice) {
            revert InsufficientPayment();
        }

        uint256 newTokenId = patchTokenIdCounter;
        patchTokenIdCounter++;

        // Mint the NFT
        _safeMint(msg.sender, newTokenId);

        // Store patch coordinates
        patchCoordinates[newTokenId] = PatchCoords(x, y, x2, y2);

        // Update pixel ownership for the area
        for (uint256 cx = x; cx <= x2; cx++) {
            for (uint256 cy = y; cy <= y2; cy++) {
                pixels[cx][cy].ownerPatchId = newTokenId;
            }
        }

        // Refund any excess payment
        if (msg.value > patchMintPrice) {
            (bool success, ) = payable(msg.sender).call{value: msg.value - patchMintPrice}("");
            require(success, "Refund failed"); // Or handle more gracefully
        }

        emit PatchMinted(newTokenId, msg.sender, x, y, patchWidth, patchHeight);
    }

    function getPatchCoordinates(uint256 tokenId) public view returns (uint256 x1, uint256 y1, uint256 x2, uint256 y2) {
        PatchCoords storage coords = patchCoordinates[tokenId];
        // Return 0s if token does not exist (standard for non-existent mappings)
        return (coords.x1, coords.y1, coords.x2, coords.y2);
    }

    // Internal helper to get patch ID at coordinates - relies on pixel ownership data
    function _getPatchIdAtCoords(uint256 x, uint256 y) internal view isValidCoord(x, y) returns (uint256) {
         return pixels[x][y].ownerPatchId;
    }

    // ERC721Enumerable overrides
    function supportsInterface(bytes4 interfaceId) public view override(ERC721Enumerable, ERC721) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function _baseURI() internal pure override returns (string memory) {
        return "ipfs://YOUR_METADATA_BASE_URI/"; // Replace with your base URI
    }

    function tokenURI(uint256 tokenId) public view override(ERC721) returns (string memory) {
        if (!_exists(tokenId)) {
            revert ERC721DoesNotExist(tokenId);
        }
        // Note: ERC721Enumerable does not require overriding _baseURI or tokenURI.
        // We override tokenURI here to add custom metadata logic.
        // A real implementation would likely fetch data from IPFS based on tokenId
        // and include patch coordinates and other relevant state in the metadata.
        // For this example, we'll return a placeholder.
        return string(abi.encodePacked(_baseURI(), tokenId.toString()));
    }

    // --- Conceptual/Complex Patch Management Functions ---
    // These are highly complex due to on-chain state updates for potentially large pixel areas
    // and managing multiple NFT token IDs. Implementation needs careful gas planning.

    function combinePatches(uint256 tokenId1, uint256 tokenId2) public {
        // Placeholder for complex logic
        // Check if tokens exist and are owned by caller
        // Check if patches are adjacent and form a valid new rectangular patch aligned with the grid
        // Calculate new combined coordinates
        // Mint new token OR update coords of one existing token
        // Transfer ownership of all pixels in the combined area to the new token ID
        // Burn one or both old tokens
        // Emit PatchesCombined event

        revert InvalidPatchIds(); // Not implemented in this example
        // emit PatchesCombined(...);
    }

    function splitPatch(uint256 tokenId, uint256 xSplit, uint256 ySplit) public {
        // Placeholder for complex logic
        // Check if token exists and is owned by caller
        // Check if xSplit/ySplit define valid split points within the patch that result in valid new patch grid cells
        // Calculate new coordinates for the 2+ resulting patches
        // Mint new token(s) for the new patch areas
        // Transfer ownership of pixels to the new token(s)
        // Burn the old token
        // Emit PatchSplit event

        revert InvalidSplitCoords(); // Not implemented in this example
        // emit PatchSplit(...);
    }


    // --- Canvas Interaction Functions (9) ---

    function buyInk() public payable {
        if (msg.value == 0 || inkPrice == 0) {
            revert InsufficientPayment(); // Or just return if 0 value
        }
        uint256 inkAmount = msg.value / inkPrice;
        userInk[msg.sender] += inkAmount;
        emit InkPurchased(msg.sender, msg.value, inkAmount);
    }

    function paintPixel(uint256 x, uint256 y, uint32 color) public isValidCoord(x, y) onlyPatchOwner(x, y) {
        if (userInk[msg.sender] < pixelInkCost) {
            revert InsufficientInk();
        }

        userInk[msg.sender] -= pixelInkCost;
        pixels[x][y].color = color;
        pixels[x][y].paintBlock = uint64(block.number); // Store block number for "freshness" or history
        // ownerPatchId is already set by mintPatch

        emit PixelPainted(pixels[x][y].ownerPatchId, x, y, color);
    }

    function paintPixels(uint256[] calldata xCoords, uint256[] calldata yCoords, uint32[] calldata colors) public {
        if (xCoords.length != yCoords.length || xCoords.length != colors.length) {
            revert ArraysLengthMismatch();
        }

        uint256 totalCost = uint256(xCoords.length) * pixelInkCost;
        if (userInk[msg.sender] < totalCost) {
            revert InsufficientInk();
        }

        userInk[msg.sender] -= totalCost;

        uint256 patchId = 0; // Assuming all pixels are in the same patch for gas efficiency, or need per-pixel check
        uint64 currentBlock = uint64(block.number);

        for (uint256 i = 0; i < xCoords.length; i++) {
            uint256 x = xCoords[i];
            uint256 y = yCoords[i];
            uint32 color = colors[i];

            // Basic coord check
            if (x >= canvasWidth || y >= canvasHeight) {
                revert InvalidCoordinates();
            }

            // Ensure ownership - checking once per batch is gas cheaper,
            // but requires all coords to be in the *same* patch.
            // A more robust version would check ownership for *each* pixel,
            // which is much more expensive. Let's assume same patch for simplicity.
             uint256 currentPatchId = pixels[x][y].ownerPatchId;
             if (currentPatchId == 0 || _ownerOf(currentPatchId) != msg.sender) {
                  revert NotPatchOwner(); // Or identify which coord failed
             }
             if (patchId == 0) patchId = currentPatchId; // Set for first pixel
             else if (patchId != currentPatchId) revert NotPatchOwner(); // All pixels must be in the same patch


            pixels[x][y].color = color;
            pixels[x][y].paintBlock = currentBlock;
            // ownerPatchId is already set
        }

        if(patchId != 0) emit PixelsPainted(patchId, xCoords.length);
    }


    function graffitiPixel(uint256 x, uint256 y, uint32 color) public isValidCoord(x, y) {
        if (userInk[msg.sender] < graffitiInkCost) {
            revert InsufficientInk();
        }

        userInk[msg.sender] -= graffitiInkCost;
        graffiti[x][y] = GraffitiData(color, msg.sender, uint66(block.number + graffitiFadeBlocks));

        emit GraffitiPainted(msg.sender, x, y, color, graffiti[x][y].fadeBlock);
    }

    function applyPixelEffect(uint256 x, uint256 y, uint16 effectId) public isValidCoord(x, y) onlyPatchOwner(x, y) {
         if (userInk[msg.sender] < effectInkCost) {
            revert InsufficientInk();
        }

        userInk[msg.sender] -= effectInkCost;
        effects[x][y] = EffectData(effectId, uint66(block.number + effectFadeBlocks));

        emit EffectApplied(pixels[x][y].ownerPatchId, x, y, effectId, effects[x][y].fadeBlock);
    }

    function setPixelProperty(uint256 x, uint256 y, bytes32 key, bytes calldata value) public isValidCoord(x, y) onlyPatchOwner(x, y) {
        pixelProperties[x][y][key] = PixelPropertyData(value);
        emit PropertySet(pixels[x][y].ownerPatchId, x, y, key);
    }

    function clearGraffiti(uint256 x, uint256 y) public isValidCoord(x,y) {
        // Allow anyone to clear faded graffiti, or only the painter/patch owner?
        // Let's allow anyone to clear faded graffiti, owner/painter can clear anytime.
        GraffitiData storage gData = graffiti[x][y];
        if (gData.fadeBlock > 0 && (gData.fadeBlock < block.number || msg.sender == gData.painter || (pixels[x][y].ownerPatchId != 0 && _ownerOf(pixels[x][y].ownerPatchId) == msg.sender))) {
            delete graffiti[x][y];
            emit GraffitiCleared(x, y);
        }
        // If gData.fadeBlock is 0, there's no graffiti to clear
    }

    function clearEffect(uint256 x, uint256 y) public isValidCoord(x, y) onlyPatchOwner(x, y) {
        delete effects[x][y];
        emit EffectCleared(x, y);
    }

    function clearPixelProperty(uint256 x, uint256 y, bytes32 key) public isValidCoord(x, y) onlyPatchOwner(x, y) {
        delete pixelProperties[x][y][key];
        emit PropertyCleared(x, y, key);
    }


    // --- Query Functions (8) ---

    function getCanvasDimensions() public view returns (uint256 width, uint256 height) {
        return (canvasWidth, canvasHeight);
    }

    function getPatchDimensions() public view returns (uint256 width, uint256 height) {
        return (patchWidth, patchHeight);
    }

    function getPixelData(uint256 x, uint256 y) public view isValidCoord(x, y) returns (uint32 color, uint256 ownerPatchId, uint64 paintBlock) {
        PixelData storage data = pixels[x][y];
        return (data.color, data.ownerPatchId, data.paintBlock);
    }

    function getGraffitiData(uint256 x, uint256 y) public view isValidCoord(x, y) returns (uint32 color, address painter, uint66 fadeBlock, bool faded) {
        GraffitiData storage data = graffiti[x][y];
        bool isFaded = data.fadeBlock > 0 && block.number >= data.fadeBlock;
        return (data.color, data.painter, data.fadeBlock, isFaded);
    }

     function getPixelEffect(uint256 x, uint256 y) public view isValidCoord(x, y) returns (uint16 effectId, uint66 fadeBlock, bool faded) {
        EffectData storage data = effects[x][y];
        bool isFaded = data.fadeBlock > 0 && block.number >= data.fadeBlock;
        return (data.effectId, data.fadeBlock, isFaded);
    }

    function getPixelProperty(uint256 x, uint256 y, bytes32 key) public view isValidCoord(x, y) returns (bytes memory value) {
        PixelPropertyData storage data = pixelProperties[x][y][key];
        return data.value;
    }

    function getUserInkBalance(address user) public view returns (uint256) {
        return userInk[user];
    }

    function isCoordOwned(uint256 x, uint256 y) public view isValidCoord(x, y) returns (bool) {
        return pixels[x][y].ownerPatchId != 0;
    }

    // --- Internal/Helper Functions ---
    // Using OpenZeppelin's _ownerOf for ERC721 owner check

    // The _beforeTokenTransfer hook could be used to update pixel ownership
    // when patches are transferred, combined, or split, but this is complex
    // due to iterating pixels on transfer. For simplicity, this example
    // implies ownership changes in mint/combine/split but doesn't fully
    // implement the pixel-level ownership transfer on ERC721 transfer.
    // A production contract would need to handle this, likely requiring
    // custom transfer logic or off-chain processing triggered by events.
    // function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize) internal override {
    //     super._beforeTokenTransfer(from, to, tokenId, batchSize);
    //     // Logic to update pixel ownership here is highly gas-intensive
    // }
}
```