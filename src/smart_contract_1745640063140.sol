Okay, here is a Solidity smart contract concept called "EternalCanvas".

This contract represents a platform for creating and managing unique, collaborative digital canvases. Each canvas is an ERC721 token. Users can "paint" small patches on the canvas by paying a fee, permanently (or semi-permanently) altering its state. The canvas's visual state is not stored fully on-chain due to gas costs, but the *data* about each painted patch (position, color, painter, timestamp) is. Off-chain renderers can use this data to visualize the canvas.

The contract incorporates concepts like:
*   **Tokenized Collective Art:** The canvas itself is an NFT, but its content is a result of multiple user interactions.
*   **Dynamic State:** The NFT's underlying data (patch information) changes over time.
*   **Micro-Contributions:** Users contribute small, paid-for modifications.
*   **Economic Incentives:** Fees for painting potentially benefit the canvas owner.
*   **On-chain Data Storage for Off-chain Rendering:** Storing patch data economically to allow external visualization.

---

**EternalCanvas Smart Contract Outline & Function Summary**

**Contract Name:** `EternalCanvas`

**Core Concept:** A factory contract for creating and managing ERC721 tokens representing unique digital canvases. Users can paint patches on these canvases by paying a fee, altering the on-chain state that describes the canvas.

**Inherits:** `ERC721`, `Ownable` (for basic admin functions, deployer is initial owner)

**Key Features:**
*   Create multiple distinct canvas NFTs.
*   Define canvas dimensions, patch size, and painting fee per canvas.
*   Users paint patches by specifying canvas ID, coordinates, and color, paying the required fee.
*   Patch data (color, painter address, timestamp) is stored on-chain.
*   Canvas owner can withdraw accrued painting fees.
*   Patch owners can transfer "credit" for their painted patch.
*   Helpers for converting between coordinates and patch IDs.
*   On-chain data available for off-chain rendering of canvases.

**State Variables:**
*   `canvases`: Mapping from `tokenId` to `Canvas` struct. Stores parameters for each canvas.
*   `canvasTokenIds`: Array storing `tokenId`s in creation order.
*   `canvasCount`: Counter for total canvases created.
*   `patchData`: Nested mapping `patchData[canvasTokenId][patchId]` to `Patch` struct. Stores data for each painted patch.
*   `patchCounter`: Mapping `patchCounter[canvasTokenId]` to count painted patches per canvas.
*   `painterPatchCount`: Mapping `painterPatchCount[painter][canvasTokenId]` to count patches painted by a specific address on a specific canvas.
*   `canvasPaintingFee`: Mapping `canvasPaintingFee[canvasTokenId]` to store the current fee to paint a patch on that canvas.

**Structs:**
*   `Canvas`: Stores `width`, `height`, `patchSize`, `creationTimestamp`.
*   `Patch`: Stores `color`, `painter`, `paintingTimestamp`.

**Events:**
*   `CanvasCreated`: Emitted when a new canvas NFT is minted.
*   `PatchPainted`: Emitted when a patch is successfully painted/updated.
*   `PaintingFeeUpdated`: Emitted when the painting fee for a canvas changes.
*   `PatchOwnershipTransferred`: Emitted when the credit for a painted patch is transferred.
*   `FeesWithdrawn`: Emitted when the canvas owner withdraws fees.

**Functions (Minimum 20+ total including inherited ERC721):**

1.  `constructor()`: Initializes the ERC721 contract name and symbol.
2.  `createCanvas(uint256 width, uint256 height, uint256 patchSize, uint256 initialPaintingFee)`:
    *   Creates a new canvas NFT with specified dimensions and initial fee.
    *   Mints the new canvas token to the caller (the deployer/owner).
    *   Stores canvas parameters.
    *   Increments canvas count and adds token ID to list.
    *   Emits `CanvasCreated` and `Transfer` events.
    *   *Access:* `onlyOwner`.
3.  `setPaintingFee(uint256 canvasTokenId, uint256 newFee)`:
    *   Allows the owner of a specific canvas NFT to set the painting fee for that canvas.
    *   Ensures the caller is the owner of the `canvasTokenId`.
    *   Updates `canvasPaintingFee` for the canvas.
    *   Emits `PaintingFeeUpdated`.
    *   *Access:* `public` (requires `require(ownerOf(canvasTokenId) == msg.sender, "Not canvas owner");`)
4.  `paintPatch(uint256 canvasTokenId, uint256 patchX, uint256 patchY, uint32 color)`:
    *   `payable` function.
    *   Allows a user to paint a patch at specific coordinates (`patchX`, `patchY`) with a `color`.
    *   Requires the `msg.value` to be exactly the current `canvasPaintingFee` for the canvas.
    *   Validates coordinates are within canvas bounds based on `patchSize`.
    *   Calculates the unique `patchId` from coordinates.
    *   If painting an unpainted patch, increments `patchCounter` for the canvas and `painterPatchCount` for the painter.
    *   Stores/updates `patchData` (color, painter, timestamp).
    *   Emits `PatchPainted`.
    *   *Access:* `public` (payable).
5.  `withdrawFees(uint256 canvasTokenId)`:
    *   Allows the owner of a specific canvas NFT to withdraw accumulated ETH fees for that canvas.
    *   Ensures the caller is the owner of the `canvasTokenId`.
    *   Calculates the fees associated with patches painted *on this specific canvas*. (Implementation note: This requires tracking fees per canvas, or the simpler approach is contract-level withdrawal for *all* fees by the contract owner, which is less flexible for canvas owners). Let's go with tracking per canvas implicitly: fees paid for canvas X go into the contract balance, and the owner of canvas X can withdraw up to the amount paid for patches on canvas X, minus potentially a platform cut. *Refinement:* A simpler approach: The contract holds all ETH. `createCanvas` could take a cut percentage for the contract deployer, and the rest goes to the canvas owner on withdrawal. Let's implement withdrawal by canvas owner for fees paid *for their canvas*. Need to track earned balance per canvas. *Alternative Refinement:* Track total contract balance, and let the *contract owner* withdraw a platform fee, and *canvas owners* withdraw fees paid *specifically for their canvas*. Let's use the latter: separate withdrawal for contract owner and canvas owner.
6.  `withdrawPlatformFees()`:
    *   Allows the contract deployer/owner (`Ownable`) to withdraw a platform cut from fees.
    *   Requires a mechanism to track the platform's share. (Let's skip the platform cut complexity for 20+ functions and keep it simple: canvas owners get the full painting fee associated with their canvas). So, refine `withdrawFees` to withdraw fees *paid for that specific canvas* by the canvas owner.
7.  `withdrawFees(uint256 canvasTokenId)` (Revised):
    *   Allows the owner of `canvasTokenId` to withdraw the balance of ETH sent to the contract for painting patches *on this canvas*.
    *   Requires tracking the balance per canvas. Add a mapping `canvasBalance[canvasTokenId]` -> uint256.
    *   Transfers `canvasBalance[canvasTokenId]` to the canvas owner.
    *   Resets `canvasBalance[canvasTokenId]` to 0.
    *   Emits `FeesWithdrawn`.
    *   *Access:* `public` (requires `require(ownerOf(canvasTokenId) == msg.sender, "Not canvas owner");`)
8.  `transferPatchOwnership(uint256 canvasTokenId, uint256 patchX, uint256 patchY, address newOwner)`:
    *   Allows the current painter of a patch (`patchData[canvasTokenId][patchId].painter`) to transfer the "credit" for that patch to another address.
    *   Does *not* change the patch's color or timestamp, only updates the `painter` field in `patchData`.
    *   Requires `msg.sender` to be the current `painter` of the specified patch.
    *   Updates `painterPatchCount` for both old and new painters.
    *   Emits `PatchOwnershipTransferred`.
    *   *Access:* `public`.
9.  `getCanvasData(uint256 canvasTokenId)`:
    *   Returns the `Canvas` struct containing dimensions and creation timestamp for a given canvas token ID.
    *   *Access:* `public view`.
10. `getPatchData(uint256 canvasTokenId, uint256 patchX, uint256 patchY)`:
    *   Returns the `Patch` struct containing color, painter, and timestamp for a given patch by coordinates.
    *   Returns empty/default values if the patch hasn't been painted.
    *   *Access:* `public view`.
11. `getPaintingFee(uint256 canvasTokenId)`:
    *   Returns the current fee required to paint a patch on a specific canvas.
    *   *Access:* `public view`.
12. `getPatchId(uint256 canvasTokenId, uint256 patchX, uint256 patchY)`:
    *   Helper function to calculate the unique `patchId` (a single integer) from 2D coordinates (`patchX`, `patchY`). Uses canvas `width`.
    *   *Access:* `public view pure` (could be pure, but needs canvas width, so maybe view). Let's pass width as parameter or retrieve it. Retrieving width from state makes it `view`.
13. `getPatchCoordinates(uint256 canvasTokenId, uint256 patchId)`:
    *   Helper function to convert a `patchId` back to 2D coordinates (`patchX`, `patchY`). Uses canvas `width`.
    *   *Access:* `public view pure`. Same logic as `getPatchId`.
14. `getCanvasPatchCount(uint256 canvasTokenId)`:
    *   Returns the total number of patches that have been painted at least once on a specific canvas.
    *   *Access:* `public view`.
15. `getPainterPatchCountOnCanvas(address painter, uint256 canvasTokenId)`:
    *   Returns the number of patches currently "owned" (last painted or had credit transferred to) by a specific `painter` on a given `canvasTokenId`.
    *   *Access:* `public view`.
16. `getCanvasCount()`:
    *   Returns the total number of canvases created by the contract.
    *   *Access:* `public view`.
17. `getCanvasTokenIdByIndex(uint256 index)`:
    *   Returns the token ID of a canvas based on its creation index (0-based). Useful for iterating canvases off-chain.
    *   *Access:* `public view`.
18. `getContractBalance()`:
    *   Returns the total ETH balance held by the contract. This balance represents accumulated painting fees before withdrawal by canvas owners.
    *   *Access:* `public view`.
19. `tokenURI(uint256 tokenId)`:
    *   ERC721 standard function. Returns a URI pointing to the JSON metadata for the canvas token.
    *   This URI would ideally point to an off-chain service that generates metadata including a link to an image render of the *current* canvas state based on the on-chain patch data.
    *   Could include a hash of the patch data state or a state version to help the off-chain service cache and update.
    *   *Access:* `public view override`.
20. `supportsInterface(bytes4 interfaceId)`:
    *   ERC165 standard. Indicates which interfaces the contract implements (ERC721, ERC165).
    *   *Access:* `public view override`.
21. `safeTransferFrom(address from, address to, uint256 tokenId)`: ERC721 Standard
22. `safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)`: ERC721 Standard
23. `transferFrom(address from, address to, uint256 tokenId)`: ERC721 Standard
24. `approve(address to, uint256 tokenId)`: ERC721 Standard
25. `setApprovalForAll(address operator, bool approved)`: ERC721 Standard
26. `getApproved(uint256 tokenId)`: ERC721 Standard
27. `isApprovedForAll(address owner, address operator)`: ERC721 Standard
28. `balanceOf(address owner)`: ERC721 Standard
29. `ownerOf(uint256 tokenId)`: ERC721 Standard

**(Total: 29 functions including 9 standard ERC721 functions)**

---
```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";

// Outline:
// - Contract Name: EternalCanvas
// - Core Concept: Factory for ERC721 canvases users can paint on.
// - Inherits: ERC721, Ownable
// - State Variables: canvases, canvasTokenIds, canvasCount, patchData,
//                    patchCounter, painterPatchCount, canvasPaintingFee, canvasBalance
// - Structs: Canvas, Patch
// - Events: CanvasCreated, PatchPainted, PaintingFeeUpdated, PatchOwnershipTransferred, FeesWithdrawn
// - Functions: (See detailed summary below)

// Function Summary:
// 1. constructor(): Initializes ERC721 name/symbol.
// 2. createCanvas(uint256 width, uint256 height, uint256 patchSize, uint256 initialPaintingFee): Creates and mints a new canvas NFT. (Owner)
// 3. setPaintingFee(uint256 canvasTokenId, uint256 newFee): Sets painting fee for a canvas. (Canvas Owner)
// 4. paintPatch(uint256 canvasTokenId, uint256 patchX, uint256 patchY, uint32 color): Paint a patch on a canvas, payable. (Any user)
// 5. withdrawFees(uint256 canvasTokenId): Withdraw accumulated painting fees for a canvas. (Canvas Owner)
// 6. transferPatchOwnership(uint256 canvasTokenId, uint256 patchX, uint256 patchY, address newOwner): Transfer credit for a painted patch. (Current Patch Painter)
// 7. getCanvasData(uint256 canvasTokenId): Get canvas dimensions and creation time. (View)
// 8. getPatchData(uint256 canvasTokenId, uint256 patchX, uint256 patchY): Get data for a specific patch. (View)
// 9. getPaintingFee(uint256 canvasTokenId): Get current painting fee for a canvas. (View)
// 10. getPatchId(uint256 canvasTokenId, uint256 patchX, uint256 patchY): Convert coords to patch ID. (View)
// 11. getPatchCoordinates(uint256 canvasTokenId, uint256 patchId): Convert patch ID to coords. (View)
// 12. getCanvasPatchCount(uint256 canvasTokenId): Get count of painted patches on a canvas. (View)
// 13. getPainterPatchCountOnCanvas(address painter, uint256 canvasTokenId): Get count of patches painted by an address on a canvas. (View)
// 14. getCanvasCount(): Get total number of canvases. (View)
// 15. getCanvasTokenIdByIndex(uint256 index): Get canvas token ID by index. (View)
// 16. getContractBalance(): Get contract's total ETH balance. (View)
// 17. tokenURI(uint256 tokenId): Get metadata URI for a canvas token. (View, ERC721 Override)
// 18. supportsInterface(bytes4 interfaceId): ERC165 support. (View, ERC721 Override)
// 19. safeTransferFrom(address from, address to, uint256 tokenId): ERC721 Standard
// 20. safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data): ERC721 Standard
// 21. transferFrom(address from, address to, uint256 tokenId): ERC721 Standard
// 22. approve(address to, uint256 tokenId): ERC721 Standard
// 23. setApprovalForAll(address operator, bool approved): ERC721 Standard
// 24. getApproved(uint256 tokenId): ERC721 Standard
// 25. isApprovedForAll(address owner, address operator): ERC721 Standard
// 26. balanceOf(address owner): ERC721 Standard
// 27. ownerOf(uint256 tokenId): ERC721 Standard

contract EternalCanvas is ERC721, Ownable {
    using Counters for Counters.Counter;

    struct Canvas {
        uint256 width;
        uint256 height;
        uint256 patchSize; // e.g., 8x8 pixels represented by one patch
        uint256 creationTimestamp;
    }

    struct Patch {
        uint32 color; // Stored as a single uint32 (e.g., 0xRRGGBB)
        address painter; // The address that last painted or was credited for this patch
        uint64 paintingTimestamp; // Timestamp when this patch was last painted
        bool isPainted; // Flag to indicate if patch data exists
    }

    // Mapping from tokenId to Canvas struct
    mapping(uint256 => Canvas) public canvases;

    // Array to keep track of canvas token IDs in creation order
    uint256[] private _canvasTokenIds;
    Counters.Counter private _canvasCount;

    // Nested mapping from canvasTokenId -> patchId -> Patch struct
    mapping(uint256 => mapping(uint256 => Patch)) private _patchData;

    // Mapping from canvasTokenId to count of patches painted at least once
    mapping(uint256 => uint256) private _canvasPatchCounter;

    // Mapping from painter address -> canvasTokenId -> count of patches currently credited to this painter
    mapping(address => mapping(uint256 => uint256)) private _painterPatchCount;

    // Mapping from canvasTokenId to the current fee to paint a patch
    mapping(uint256 => uint256) private _canvasPaintingFee;

    // Mapping from canvasTokenId to accumulated ETH balance from painting fees
    mapping(uint256 => uint256) private _canvasBalance;


    event CanvasCreated(uint256 indexed tokenId, uint256 width, uint256 height, uint256 patchSize, uint256 initialPaintingFee, address indexed owner);
    event PatchPainted(uint256 indexed canvasTokenId, uint256 indexed patchId, uint32 color, address indexed painter, uint64 timestamp);
    event PaintingFeeUpdated(uint256 indexed canvasTokenId, uint256 oldFee, uint256 newFee, address indexed updater);
    event PatchOwnershipTransferred(uint256 indexed canvasTokenId, uint256 indexed patchId, address indexed oldPainter, address indexed newPainter);
    event FeesWithdrawn(uint256 indexed canvasTokenId, uint256 amount, address indexed receiver);

    constructor() ERC721("EternalCanvas", "ETERNAL") Ownable(msg.sender) {
        // Initial contract setup
    }

    // --- Canvas Management (Owner/Canvas Owner) ---

    /// @notice Creates a new canvas ERC721 token. Only callable by the contract deployer.
    /// @param width The width of the canvas in abstract units (number of patches).
    /// @param height The height of the canvas in abstract units (number of patches).
    /// @param patchSize The side length of a patch in pixel units (for off-chain rendering).
    /// @param initialPaintingFee The fee required to paint one patch on this canvas.
    /// @return tokenId The token ID of the newly created canvas.
    function createCanvas(uint256 width, uint256 height, uint256 patchSize, uint256 initialPaintingFee) public onlyOwner returns (uint256) {
        require(width > 0 && height > 0, "Canvas dimensions must be positive");
        require(patchSize > 0, "Patch size must be positive");

        _canvasCount.increment();
        uint256 newTokenId = _canvasCount.current();
        address canvasOwner = msg.sender; // Deployer is initial owner

        canvases[newTokenId] = Canvas({
            width: width,
            height: height,
            patchSize: patchSize,
            creationTimestamp: block.timestamp
        });
        _canvasTokenIds.push(newTokenId);
        _canvasPaintingFee[newTokenId] = initialPaintingFee;
        _canvasBalance[newTokenId] = 0; // Initialize canvas balance

        _mint(canvasOwner, newTokenId);

        emit CanvasCreated(newTokenId, width, height, patchSize, initialPaintingFee, canvasOwner);

        return newTokenId;
    }

    /// @notice Allows the owner of a canvas NFT to set the painting fee for that canvas.
    /// @param canvasTokenId The token ID of the canvas.
    /// @param newFee The new fee required to paint a patch on this canvas.
    function setPaintingFee(uint256 canvasTokenId, uint256 newFee) public {
        require(_exists(canvasTokenId), "Canvas does not exist");
        require(ownerOf(canvasTokenId) == msg.sender, "Not canvas owner");

        uint256 oldFee = _canvasPaintingFee[canvasTokenId];
        _canvasPaintingFee[canvasTokenId] = newFee;

        emit PaintingFeeUpdated(canvasTokenId, oldFee, newFee, msg.sender);
    }

    /// @notice Allows the owner of a canvas NFT to withdraw accumulated painting fees for that canvas.
    /// Fees are accumulated in the contract's balance and tracked per canvas.
    /// @param canvasTokenId The token ID of the canvas.
    function withdrawFees(uint256 canvasTokenId) public {
        require(_exists(canvasTokenId), "Canvas does not exist");
        require(ownerOf(canvasTokenId) == msg.sender, "Not canvas owner");

        uint256 balanceToWithdraw = _canvasBalance[canvasTokenId];
        require(balanceToWithdraw > 0, "No fees to withdraw for this canvas");

        _canvasBalance[canvasTokenId] = 0;

        (bool success, ) = payable(msg.sender).call{value: balanceToWithdraw}("");
        require(success, "ETH transfer failed");

        emit FeesWithdrawn(canvasTokenId, balanceToWithdraw, msg.sender);
    }

    // --- User Interaction (Painting) ---

    /// @notice Paints a patch on a canvas at specific coordinates with a given color.
    /// This is a payable function, requiring the current painting fee to be sent.
    /// @param canvasTokenId The token ID of the canvas to paint on.
    /// @param patchX The X coordinate of the patch (0-indexed).
    /// @param patchY The Y coordinate of the patch (0-indexed).
    /// @param color The color to paint the patch, encoded as a uint32 (e.g., 0xRRGGBB).
    function paintPatch(uint256 canvasTokenId, uint256 patchX, uint256 patchY, uint32 color) public payable {
        Canvas storage canvas = canvases[canvasTokenId];
        require(canvas.width > 0, "Canvas does not exist or is invalid"); // Check if canvas exists
        require(patchX < canvas.width && patchY < canvas.height, "Coordinates out of bounds");

        uint256 requiredFee = _canvasPaintingFee[canvasTokenId];
        require(msg.value == requiredFee, "Incorrect painting fee sent");

        uint256 patchId = getPatchId(canvasTokenId, patchX, patchY);

        // Check if this is the first time this specific patch is painted on this canvas
        bool isFirstPaint = !_patchData[canvasTokenId][patchId].isPainted;

        // Decrement count for the old painter if the patch existed and was painted by someone else
        address oldPainter = _patchData[canvasTokenId][patchId].painter;
        if (!isFirstPaint && oldPainter != address(0) && oldPainter != msg.sender) {
             // Safely decrement count if the old painter isn't the new painter (overwriting)
             // Note: This assumes the count is always positive when oldPainter is set.
             // If an address could be set to 0 after painting, more complex checks are needed.
             // For this model, the painter is only updated, not cleared, unless transferred to 0x0.
             // Let's assume oldPainter != 0x0 means they had credit.
            if (_painterPatchCount[oldPainter][canvasTokenId] > 0) {
                _painterPatchCount[oldPainter][canvasTokenId]--;
            }
        }


        _patchData[canvasTokenId][patchId] = Patch({
            color: color,
            painter: msg.sender,
            paintingTimestamp: uint64(block.timestamp),
            isPainted: true // Mark as painted
        });

        if (isFirstPaint) {
            _canvasPatchCounter[canvasTokenId]++;
        }

        // Increment count for the new painter
        _painterPatchCount[msg.sender][canvasTokenId]++;

        // Add received fee to the canvas's balance for withdrawal by the canvas owner
        _canvasBalance[canvasTokenId] += msg.value;

        emit PatchPainted(canvasTokenId, patchId, color, msg.sender, uint64(block.timestamp));
    }

    /// @notice Allows the current 'painter' (the address stored in the Patch struct) of a specific patch
    /// to transfer that credit to another address. This doesn't change the visual state,
    /// but updates who is recorded as the contributor.
    /// @param canvasTokenId The token ID of the canvas.
    /// @param patchX The X coordinate of the patch.
    /// @param patchY The Y coordinate of the patch.
    /// @param newOwner The address to transfer the patch ownership credit to.
    function transferPatchOwnership(uint256 canvasTokenId, uint256 patchX, uint256 patchY, address newOwner) public {
        Canvas storage canvas = canvases[canvasTokenId];
        require(canvas.width > 0, "Canvas does not exist or is invalid");
        require(patchX < canvas.width && patchY < canvas.height, "Coordinates out of bounds");
        require(newOwner != address(0), "Cannot transfer to the zero address");

        uint256 patchId = getPatchId(canvasTokenId, patchX, patchY);
        Patch storage patch = _patchData[canvasTokenId][patchId];

        require(patch.isPainted, "Patch has not been painted");
        require(patch.painter == msg.sender, "Not the current patch owner");

        address oldPainter = patch.painter;
        patch.painter = newOwner; // Update the recorded painter

        // Update patch counts for both old and new painters
        if (_painterPatchCount[oldPainter][canvasTokenId] > 0) {
            _painterPatchCount[oldPainter][canvasTokenId]--;
        }
        _painterPatchCount[newOwner][canvasTokenId]++;

        emit PatchOwnershipTransferred(canvasTokenId, patchId, oldPainter, newOwner);
    }

    // --- Querying (View Functions) ---

    /// @notice Gets the data for a specific canvas token.
    /// @param canvasTokenId The token ID of the canvas.
    /// @return width The width of the canvas.
    /// @return height The height of the canvas.
    /// @return patchSize The size of patches on the canvas.
    /// @return creationTimestamp The timestamp when the canvas was created.
    function getCanvasData(uint256 canvasTokenId) public view returns (uint256 width, uint256 height, uint256 patchSize, uint256 creationTimestamp) {
        Canvas storage canvas = canvases[canvasTokenId];
        require(canvas.width > 0, "Canvas does not exist");
        return (canvas.width, canvas.height, canvas.patchSize, canvas.creationTimestamp);
    }

    /// @notice Gets the data for a specific patch on a canvas.
    /// @param canvasTokenId The token ID of the canvas.
    /// @param patchX The X coordinate of the patch.
    /// @param patchY The Y coordinate of the patch.
    /// @return color The color of the patch (0 if not painted).
    /// @return painter The address that painted the patch (address(0) if not painted).
    /// @return paintingTimestamp The timestamp when the patch was painted (0 if not painted).
    /// @return isPainted True if the patch has been painted at least once.
    function getPatchData(uint255 canvasTokenId, uint256 patchX, uint256 patchY) public view returns (uint32 color, address painter, uint64 paintingTimestamp, bool isPainted) {
        Canvas storage canvas = canvases[canvasTokenId];
        require(canvas.width > 0, "Canvas does not exist");
        require(patchX < canvas.width && patchY < canvas.height, "Coordinates out of bounds");

        uint256 patchId = getPatchId(canvasTokenId, patchX, patchY);
        Patch storage patch = _patchData[canvasTokenId][patchId];

        return (patch.color, patch.painter, patch.paintingTimestamp, patch.isPainted);
    }

    /// @notice Gets the current painting fee for a specific canvas.
    /// @param canvasTokenId The token ID of the canvas.
    /// @return The current fee to paint a patch on this canvas.
    function getPaintingFee(uint256 canvasTokenId) public view returns (uint256) {
        require(_exists(canvasTokenId), "Canvas does not exist");
        return _canvasPaintingFee[canvasTokenId];
    }

    /// @notice Calculates the unique ID for a patch based on its coordinates and canvas width.
    /// @param canvasTokenId The token ID of the canvas (used to get width).
    /// @param patchX The X coordinate of the patch.
    /// @param patchY The Y coordinate of the patch.
    /// @return The unique ID for the patch.
    function getPatchId(uint256 canvasTokenId, uint256 patchX, uint256 patchY) public view returns (uint256) {
         Canvas storage canvas = canvases[canvasTokenId];
         require(canvas.width > 0, "Canvas does not exist"); // Ensure width is valid
         require(patchX < canvas.width && patchY < canvas.height, "Coordinates out of bounds");
         return patchY * canvas.width + patchX;
    }

    /// @notice Calculates the coordinates for a patch based on its unique ID and canvas width.
    /// @param canvasTokenId The token ID of the canvas (used to get width).
    /// @param patchId The unique ID of the patch.
    /// @return patchX The X coordinate of the patch.
    /// @return patchY The Y coordinate of the patch.
    function getPatchCoordinates(uint256 canvasTokenId, uint256 patchId) public view returns (uint256 patchX, uint256 patchY) {
         Canvas storage canvas = canvases[canvasTokenId];
         require(canvas.width > 0, "Canvas does not exist"); // Ensure width is valid
         require(patchId < canvas.width * canvas.height, "Patch ID out of bounds for canvas size");
         patchY = patchId / canvas.width;
         patchX = patchId % canvas.width;
    }

    /// @notice Gets the total count of patches that have been painted at least once on a canvas.
    /// @param canvasTokenId The token ID of the canvas.
    /// @return The number of unique patches painted on the canvas.
    function getCanvasPatchCount(uint256 canvasTokenId) public view returns (uint256) {
        require(_exists(canvasTokenId), "Canvas does not exist");
        return _canvasPatchCounter[canvasTokenId];
    }

    /// @notice Gets the number of patches currently associated with a specific painter on a specific canvas.
    /// This count increases when they paint a patch or receive patch ownership, and decreases when
    /// someone paints over their patch or they transfer ownership.
    /// @param painter The address whose patch count is requested.
    /// @param canvasTokenId The token ID of the canvas.
    /// @return The number of patches credited to the painter on this canvas.
    function getPainterPatchCountOnCanvas(address painter, uint256 canvasTokenId) public view returns (uint256) {
         require(_exists(canvasTokenId), "Canvas does not exist");
         return _painterPatchCount[painter][canvasTokenId];
    }

    /// @notice Gets the total number of canvas NFTs created by this contract.
    /// @return The total count of canvases.
    function getCanvasCount() public view returns (uint256) {
        return _canvasCount.current();
    }

    /// @notice Gets the token ID of a canvas by its creation index.
    /// Useful for iterating through all canvases off-chain.
    /// @param index The 0-based index of the canvas in creation order.
    /// @return The token ID at the specified index.
    function getCanvasTokenIdByIndex(uint256 index) public view returns (uint256) {
        require(index < _canvasTokenIds.length, "Index out of bounds");
        return _canvasTokenIds[index];
    }

    /// @notice Gets the total ETH balance currently held by the contract.
    /// This balance represents accumulated painting fees before withdrawal.
    /// @return The contract's total ETH balance.
    function getContractBalance() public view returns (uint256) {
        return address(this).balance;
    }


    // --- ERC721 Overrides & Standards ---

    /// @notice Returns the URI for the metadata of a canvas token.
    /// This function is crucial for NFTs and should point to a service
    /// that generates the metadata JSON, including image URL, based on the
    /// on-chain patch data for the given canvasTokenId.
    /// For this example, it returns a placeholder URI. A real implementation
    /// would use IPFS or a dedicated metadata service.
    /// @param tokenId The token ID of the canvas.
    /// @return string The URI pointing to the token metadata.
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        // In a real dApp, this would point to an off-chain service
        // e.g., ipfs://.../{tokenId} or https://api.mycanvasdapp.com/metadata/{tokenId}
        // The off-chain service would query the contract state (patchData)
        // for this tokenId and render an image and generate the JSON metadata.
        // To help caching, you might include a hash of the canvas state or a version:
        // e.g., https://api.mycanvasdapp.com/metadata/{tokenId}?state_hash={keccak256(abi.encodePacked(...))}
        // Calculating a state hash on-chain is gas-prohibitive for many patches.
        // A simpler approach is to just pass the token ID and let the off-chain
        // service decide how to handle state updates.
        return string(abi.encodePacked("ipfs://placeholder/", Strings.toString(tokenId)));
    }

    // The rest are standard ERC721 functions implemented by OpenZeppelin
    // 19. safeTransferFrom(address from, address to, uint256 tokenId)
    // 20. safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
    // 21. transferFrom(address from, address to, uint256 tokenId)
    // 22. approve(address to, uint256 tokenId)
    // 23. setApprovalForAll(address operator, bool approved)
    // 24. getApproved(uint256 tokenId)
    // 25. isApprovedForAll(address owner, address operator)
    // 26. balanceOf(address owner)
    // 27. ownerOf(uint256 tokenId)
    // 28. supportsInterface(bytes4 interfaceId) is also included via ERC721

}
```