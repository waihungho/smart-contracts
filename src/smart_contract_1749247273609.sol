Okay, let's create a smart contract concept around a "Crypto Canvas" - a dynamic, interactive, and collaborative NFT. The core idea is an ERC721 token that represents a large grid (the canvas). Users don't just *own* the canvas NFT; they can *interact* with it by "painting" individual cells (pixels) within the grid. This interaction has costs, can involve partial ownership of cells, and the canvas's appearance (metadata) changes dynamically based on the state of its cells.

This incorporates:
1.  **ERC721 Standard:** Core NFT functionality.
2.  **Dynamic Metadata:** The `tokenURI` points to data that changes based on on-chain state.
3.  **Partial Ownership/Contribution:** Users interact with specific cells, potentially gaining temporary or permanent rights over them.
4.  **Economic Model:** Costs for painting, potential fee distribution.
5.  **Time-Based Effects:** Concepts like color decay or time-limited effects.
6.  **Advanced State Management:** Storing and updating the state of many individual cells within the contract.
7.  **Batch Operations:** Efficiently updating multiple cells.

Let's outline the contract and its functions.

---

**Contract Name:** `CryptoCanvas`

**Concept:** An ERC721 NFT where each token represents a dynamic, programmable grid (canvas). Users can "paint" individual cells within the grid by paying a fee. The state of the cells (color, effects, owner) determines the appearance of the NFT's metadata. Canvas owners configure dimensions and costs, and can earn fees. Cell owners might gain rights or a share of future painting fees on their cells.

**Advanced Concepts Used:**
*   Dynamic NFT Metadata driven by complex on-chain state.
*   Partial/Delegated ownership of sub-components (cells) within the main NFT asset.
*   On-chain state hash for metadata integrity and caching.
*   Fee distribution mechanisms.
*   Configurable parameters per NFT instance.
*   Batch operations for efficiency.

**Outline & Function Summary:**

**I. Contract Core & Standards (`ERC721`, `Ownable`)**
*   Basic ERC721 functionality (minting, transferring, ownership).
*   Owner controls core contract settings and can mint new canvases.

**II. Canvas Creation & Configuration**
*   Functions for the contract owner to create new canvas NFTs with specific dimensions and initial parameters.
*   Functions for the *canvas owner* (the holder of the canvas NFT) to update certain configurations of *their* canvas.

**III. Cell Interaction & Painting**
*   The primary user interaction: painting specific cells.
*   Handling payment, updating cell state (color, last painted time, painter).
*   Batch painting for multiple cells.

**IV. Cell State & Ownership Management**
*   Functions to query the state of individual cells (color, owner, effect, etc.).
*   Mechanism for transferring ownership of individual cells *within* a canvas.
*   Tracking fees accrued per cell owner.

**V. Advanced Features & Effects**
*   Applying special effects to cells (e.g., lock, sparkle, decay modifier).
*   Triggering state changes based on time (e.g., decay).
*   Locking/unlocking cells to prevent painting.

**VI. Query Functions**
*   Reading canvas configurations.
*   Reading total supply and canvas metadata base URI.
*   Generating a hash representing the current state of a canvas's cells (for metadata).

**VII. Withdrawal Functions**
*   Canvas owner withdrawing accrued fees.
*   Cell owners withdrawing accrued fees.

**Function List (Targeting >= 20 unique public/external functions):**

1.  `constructor()`: Initializes contract owner and base token URI prefix.
2.  `totalSupply()`: Returns the total number of Canvas NFTs created. (Standard ERC721 Supply)
3.  `balanceOf(address owner)`: Returns number of NFTs owned by an address. (Standard ERC721)
4.  `ownerOf(uint256 tokenId)`: Returns the owner of a specific NFT. (Standard ERC721)
5.  `transferFrom(address from, address to, uint256 tokenId)`: Transfers NFT ownership. (Standard ERC721)
6.  `safeTransferFrom(address from, address to, uint256 tokenId)`: Safe transfer NFT ownership. (Standard ERC721)
7.  `safeTransferFrom(address from, address to, uint256 tokenId, bytes data)`: Safe transfer NFT ownership with data. (Standard ERC721)
8.  `approve(address to, uint256 tokenId)`: Approves an address to transfer a specific NFT. (Standard ERC721)
9.  `setApprovalForAll(address operator, bool approved)`: Approves/revokes operator for all NFTs. (Standard ERC721)
10. `getApproved(uint256 tokenId)`: Gets the approved address for a single NFT. (Standard ERC721)
11. `isApprovedForAll(address owner, address operator)`: Checks if operator is approved for all NFTs. (Standard ERC721)
12. `tokenURI(uint256 tokenId)`: Returns the metadata URI for a canvas NFT. (Custom logic based on state)
13. `renounceOwnership()`: Renounces contract ownership (Ownable).
14. `transferOwnership(address newOwner)`: Transfers contract ownership (Ownable).
15. `createCanvas(uint16 _width, uint16 _height, uint256 _paintingCost, uint64 _decayRate, uint32 _initialColor)`: Creates a new Canvas NFT with specified configuration (Contract Owner only).
16. `updateCanvasConfig(uint256 _canvasId, uint256 _newPaintingCost, uint64 _newDecayRate)`: Allows the *Canvas Owner* to update some config parameters for their canvas.
17. `paintCell(uint256 _canvasId, uint16 _cellX, uint16 _cellY, uint32 _color)`: Paints a single cell on a canvas. Pays painting cost, updates cell state. Sender becomes cell owner.
18. `batchPaintCells(uint256 _canvasId, uint16[] calldata _cellX, uint16[] calldata _cellY, uint32[] calldata _colors)`: Paints multiple cells on a canvas in a single transaction. Requires array lengths match.
19. `transferCell(uint256 _canvasId, uint16 _cellX, uint16 _cellY, address _to)`: Transfers ownership of a specific cell to another address (requires current cell owner permission or canvas owner override).
20. `applyCellEffect(uint256 _canvasId, uint16 _cellX, uint16 _cellY, uint8 _effectId, uint64 _duration)`: Applies a special effect to a cell (e.g., locking, visual effect ID). Might require canvas owner or cell owner permission depending on effect.
21. `removeCellEffect(uint256 _canvasId, uint16 _cellX, uint16 _cellY, uint8 _effectId)`: Removes a specific effect from a cell.
22. `lockCell(uint256 _canvasId, uint16 _cellX, uint16 _cellY, uint64 _duration)`: Locks a cell, preventing it from being painted for a duration (Canvas Owner or Cell Owner).
23. `unlockCell(uint256 _canvasId, uint16 _cellX, uint16 _cellY)`: Unlocks a cell (Canvas Owner or Cell Owner).
24. `triggerDecay(uint256 _canvasId, uint16[] calldata _cellX, uint16[] calldata _cellY)`: Allows anyone to trigger decay calculation for specified cells, potentially updating state based on time and decay rate. Could reward the caller for gas.
25. `withdrawCanvasFees(uint256 _canvasId)`: Allows the Canvas Owner to withdraw fees collected from painting on their canvas.
26. `withdrawCellOwnerFees(uint256 _canvasId, uint16 _cellX, uint16 _cellY)`: Allows a Cell Owner to withdraw fees accrued specifically to their cell (if fee distribution logic exists).
27. `getCanvasDimensions(uint256 _canvasId)`: Returns the width and height of a canvas.
28. `getCellState(uint256 _canvasId, uint16 _cellX, uint16 _cellY)`: Returns the full state of a cell (color, owner, effects, timestamps).
29. `getCellOwner(uint256 _canvasId, uint16 _cellX, uint16 _cellY)`: Returns the current owner of a specific cell.
30. `getCanvasConfig(uint256 _canvasId)`: Returns the full configuration of a canvas (cost, decay rate, etc.).
31. `getCanvasStateHash(uint256 _canvasId)`: Calculates and returns a hash representing the combined state of all cells on a canvas. Used for metadata caching.
32. `isCellLocked(uint256 _canvasId, uint16 _cellX, uint16 _cellY)`: Checks if a specific cell is currently locked.
33. `getCellLastPaintedTime(uint256 _canvasId, uint16 _cellX, uint16 _cellY)`: Returns the timestamp the cell was last painted.
34. `getTokenUriBase()`: Returns the base URI prefix used for metadata.
35. `setTokenUriBase(string memory _newTokenUriBase)`: Sets the base URI prefix (Contract Owner only).
36. `getCellEffect(uint256 _canvasId, uint16 _cellX, uint16 _cellY)`: Returns the current effect ID and duration for a cell.

*(Note: Standard ERC721 functions like `supportsInterface` are assumed but not explicitly listed in the >20 count)*

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/Math.sol"; // For min function potentially
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

// Outline:
// I. Contract Core & Standards (ERC721, Ownable)
//    - Base NFT functionality, ownership.
// II. Canvas Creation & Configuration
//    - Create new canvases with specific properties.
//    - Update canvas properties (by canvas owner).
// III. Cell Interaction & Painting
//    - Paint individual cells with associated cost.
//    - Paint multiple cells efficiently.
// IV. Cell State & Ownership Management
//    - Store and retrieve cell state (color, owner, effects, time).
//    - Transfer ownership of individual cells.
// V. Advanced Features & Effects
//    - Apply time-based or state-based effects to cells.
//    - Lock/unlock cells.
//    - Mechanism for decay/time-based updates.
// VI. Query Functions
//    - Retrieve canvas/cell configuration and state.
//    - Generate state hash for metadata.
// VII. Withdrawal Functions
//    - Allow canvas and cell owners to claim earned fees.

// Function Summary:
// 1. constructor()
// 2. totalSupply()
// 3. balanceOf(address owner)
// 4. ownerOf(uint256 tokenId)
// 5. transferFrom(address from, address to, uint256 tokenId)
// 6. safeTransferFrom(address from, address to, uint256 tokenId)
// 7. safeTransferFrom(address from, address to, uint256 tokenId, bytes data)
// 8. approve(address to, uint256 tokenId)
// 9. setApprovalForAll(address operator, bool approved)
// 10. getApproved(uint256 tokenId)
// 11. isApprovedForAll(address owner, address operator)
// 12. tokenURI(uint256 tokenId)
// 13. renounceOwnership()
// 14. transferOwnership(address newOwner)
// 15. createCanvas(uint16 _width, uint16 _height, uint256 _paintingCost, uint64 _decayRate, uint32 _initialColor)
// 16. updateCanvasConfig(uint256 _canvasId, uint256 _newPaintingCost, uint64 _newDecayRate)
// 17. paintCell(uint256 _canvasId, uint16 _cellX, uint16 _cellY, uint32 _color)
// 18. batchPaintCells(uint256 _canvasId, uint16[] calldata _cellX, uint16[] calldata _cellY, uint32[] calldata _colors)
// 19. transferCell(uint256 _canvasId, uint16 _cellX, uint16 _cellY, address _to)
// 20. applyCellEffect(uint256 _canvasId, uint16 _cellX, uint16 _cellY, uint8 _effectId, uint64 _duration)
// 21. removeCellEffect(uint256 _canvasId, uint16 _cellX, uint16 _cellY, uint8 _effectId)
// 22. lockCell(uint256 _canvasId, uint16 _cellX, uint16 _cellY, uint64 _duration)
// 23. unlockCell(uint256 _canvasId, uint16 _cellX, uint16 _cellY)
// 24. triggerDecay(uint256 _canvasId, uint16[] calldata _cellX, uint16[] calldata _cellY)
// 25. withdrawCanvasFees(uint256 _canvasId)
// 26. withdrawCellOwnerFees(uint256 _canvasId, uint16 _cellX, uint16 _cellY)
// 27. getCanvasDimensions(uint256 _canvasId)
// 28. getCellState(uint256 _canvasId, uint16 _cellX, uint16 _cellY)
// 29. getCellOwner(uint256 _canvasId, uint16 _cellX, uint16 _cellY)
// 30. getCanvasConfig(uint256 _canvasId)
// 31. getCanvasStateHash(uint256 _canvasId)
// 32. isCellLocked(uint256 _canvasId, uint16 _cellX, uint16 _cellY)
// 33. getCellLastPaintedTime(uint256 _canvasId, uint16 _cellX, uint16 _cellY)
// 34. getTokenUriBase()
// 35. setTokenUriBase(string memory _newTokenUriBase)
// 36. getCellEffect(uint256 _canvasId, uint16 _cellX, uint16 _cellY)

contract CryptoCanvas is ERC721URIStorage, Ownable, ReentrancyGuard {
    using Counters for Counters.Counter;
    Counters.Counter private _canvasIds;

    // --- Data Structures ---

    struct CanvasConfig {
        uint16 width; // Number of cells horizontally
        uint16 height; // Number of cells vertically
        uint256 paintingCost; // Cost to paint one cell (in native currency, e.g., wei)
        uint64 decayRate; // How fast color decays over time (e.g., units per hour/day - interpreted by renderer)
        // Add more config like max batch size, allowed effects, etc.
    }

    struct CellState {
        uint32 color; // RGB color (e.g., 0xFF0000 for red)
        address owner; // Address of the last painter, potentially cell owner
        uint64 lastPaintedTime; // Timestamp of the last paint operation
        uint8 effectId; // ID representing a special effect (0 = none)
        uint64 effectEndTime; // Timestamp when the effect ends
        bool isLocked; // If true, painting is disabled
        uint64 lockedUntil; // Timestamp when lock ends
    }

    // --- State Variables ---

    // Mapping from canvasId to its configuration
    mapping(uint256 => CanvasConfig) private _canvasConfigs;

    // Mapping from canvasId => cellIndex => CellState
    // cellIndex = y * width + x
    mapping(uint256 => mapping(uint256 => CellState)) private _cellStates;

    // Mapping from canvasId => address => accrued fees (native currency)
    // Fees for the main canvas owner
    mapping(uint256 => uint256) private _canvasOwnerFees;

    // Mapping from canvasId => cellIndex => address => accrued fees (native currency)
    // Fees for individual cell owners (if applicable based on painting logic)
    mapping(uint256 => mapping(uint256 => mapping(address => uint256))) private _cellOwnerFees;

    // Base URI for metadata, append canvasId
    string private _tokenUriBase;

    // --- Events ---

    event CanvasCreated(uint256 indexed canvasId, uint16 width, uint16 height, address indexed creator);
    event CanvasConfigUpdated(uint256 indexed canvasId, uint256 newPaintingCost, uint64 newDecayRate);
    event CellPainted(uint256 indexed canvasId, uint16 indexed cellX, uint16 indexed cellY, address indexed painter, uint32 color, uint256 cost);
    event CellOwnershipTransferred(uint256 indexed canvasId, uint16 indexed cellX, uint16 indexed cellY, address indexed from, address indexed to);
    event CellEffectApplied(uint256 indexed canvasId, uint16 indexed cellX, uint16 indexed cellY, uint8 effectId, uint64 duration);
    event CellEffectRemoved(uint256 indexed canvasId, uint16 indexed cellX, uint16 indexed cellY, uint8 effectId);
    event CellLocked(uint256 indexed canvasId, uint16 indexed cellX, uint16 indexed cellY, uint64 duration);
    event CellUnlocked(uint256 indexed canvasId, uint16 indexed cellX, uint16 indexed cellY);
    event DecayTriggered(uint256 indexed canvasId, uint256[] cellIndices);
    event CanvasFeesWithdrawn(uint256 indexed canvasId, address indexed owner, uint256 amount);
    event CellOwnerFeesWithdrawn(uint256 indexed canvasId, uint16 indexed cellX, uint16 indexed cellY, address indexed owner, uint256 amount);

    // --- Modifiers ---

    modifier onlyCanvasOwner(uint256 _canvasId) {
        require(_exists(_canvasId), "Canvas does not exist");
        require(ownerOf(_canvasId) == msg.sender, "Caller is not the canvas owner");
        _;
    }

    modifier onlyCellOwnerOrCanvasOwner(uint256 _canvasId, uint16 _cellX, uint16 _cellY) {
        require(_exists(_canvasId), "Canvas does not exist");
        require(
            _getCellOwner(_canvasId, _cellX, _cellY) == msg.sender || ownerOf(_canvasId) == msg.sender,
            "Caller is not cell or canvas owner"
        );
        _;
    }

    // --- Constructor ---

    constructor(string memory name, string memory symbol, string memory initialTokenUriBase)
        ERC721(name, symbol)
        Ownable(msg.sender)
    {
        _tokenUriBase = initialTokenUriBase;
    }

    // --- ERC721 Overrides (Required for ERC721URIStorage) ---

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721URIStorage: URI query for nonexistent token");
        // The actual metadata JSON and image will be hosted off-chain (e.g., IPFS, dedicated server)
        // The URI should typically contain the canvas ID and potentially a state hash
        // to allow metadata caching while ensuring it updates when the state changes.
        // Example: ipfs://.../{canvasId}/{stateHash}.json or https://api.mycanvas.xyz/metadata/{canvasId}/{stateHash}
        // For this example, we'll just use the base URI + ID + state hash.
        // A real implementation would have an off-chain service that listens for state changes
        // or computes the metadata based on the state hash from the contract.
        bytes memory hashBytes = abi.encodePacked(getCanvasStateHash(tokenId));
        string memory stateHashStr = Base64.encode(hashBytes); // Simple encoding for hash in URL
        return string(abi.encodePacked(_tokenUriBase, Strings.toString(tokenId), "/", stateHashStr));
    }

    // --- Contract Owner Functions ---

    // 15. Creates a new Canvas NFT
    function createCanvas(
        uint16 _width,
        uint16 _height,
        uint256 _paintingCost,
        uint64 _decayRate,
        uint32 _initialColor
    ) external onlyOwner returns (uint256) {
        require(_width > 0 && _height > 0, "Dimensions must be positive");
        _canvasIds.increment();
        uint256 newItemId = _canvasIds.current();

        _mint(msg.sender, newItemId);

        _canvasConfigs[newItemId] = CanvasConfig({
            width: _width,
            height: _height,
            paintingCost: _paintingCost,
            decayRate: _decayRate
        });

        // Initialize all cells with the initial color
        uint256 totalCells = uint256(_width) * _height;
        for (uint256 i = 0; i < totalCells; i++) {
            _cellStates[newItemId][i] = CellState({
                color: _initialColor,
                owner: address(0), // No initial owner
                lastPaintedTime: uint64(block.timestamp),
                effectId: 0,
                effectEndTime: 0,
                isLocked: false,
                lockedUntil: 0
            });
        }

        emit CanvasCreated(newItemId, _width, _height, msg.sender);
        return newItemId;
    }

    // 35. Sets the base URI for token metadata (Contract Owner)
    function setTokenUriBase(string memory _newTokenUriBase) external onlyOwner {
        _tokenUriBase = _newTokenUriBase;
    }

    // --- Canvas Owner Functions ---

    // 16. Allows the canvas owner to update specific configuration parameters
    function updateCanvasConfig(
        uint256 _canvasId,
        uint256 _newPaintingCost,
        uint64 _newDecayRate
    ) external onlyCanvasOwner(_canvasId) {
        CanvasConfig storage config = _canvasConfigs[_canvasId];
        config.paintingCost = _newPaintingCost;
        config.decayRate = _newDecayRate;

        emit CanvasConfigUpdated(_canvasId, _newPaintingCost, _newDecayRate);
    }

    // 22. Locks a cell, preventing painting (Canvas Owner or Cell Owner)
    function lockCell(uint256 _canvasId, uint16 _cellX, uint16 _cellY, uint64 _duration) external onlyCellOwnerOrCanvasOwner(_canvasId, _cellX, _cellY) {
        uint256 cellIndex = uint256(_cellY) * _canvasConfigs[_canvasId].width + _cellX;
        CellState storage cell = _cellStates[_canvasId][cellIndex];

        cell.isLocked = true;
        cell.lockedUntil = uint64(block.timestamp) + _duration;

        emit CellLocked(_canvasId, _cellX, _cellY, _duration);
    }

    // 23. Unlocks a cell (Canvas Owner or Cell Owner)
    function unlockCell(uint256 _canvasId, uint16 _cellX, uint16 _cellY) external onlyCellOwnerOrCanvasOwner(_canvasId, _cellX, _cellY) {
        uint256 cellIndex = uint256(_cellY) * _canvasConfigs[_canvasId].width + _cellX;
        CellState storage cell = _cellStates[_canvasId][cellIndex];

        cell.isLocked = false;
        cell.lockedUntil = 0; // Or a past timestamp

        emit CellUnlocked(_canvasId, _cellX, _cellY);
    }

    // 20. Apply a special effect to a cell (Requires Canvas Owner or specific permission)
    function applyCellEffect(
        uint256 _canvasId,
        uint16 _cellX,
        uint16 _cellY,
        uint8 _effectId,
        uint64 _duration
    ) external onlyCanvasOwner(_canvasId) { // Simplified: only canvas owner can apply effects
        uint256 cellIndex = uint256(_cellY) * _canvasConfigs[_canvasId].width + _cellX;
        require(_isValidCell(_canvasId, _cellX, _cellY), "Invalid cell coordinates");

        CellState storage cell = _cellStates[_canvasId][cellIndex];
        cell.effectId = _effectId;
        cell.effectEndTime = uint64(block.timestamp) + _duration;

        emit CellEffectApplied(_canvasId, _cellX, _cellY, _effectId, _duration);
    }

     // 21. Remove a specific effect from a cell (Requires Canvas Owner)
     function removeCellEffect(uint256 _canvasId, uint16 _cellX, uint16 _cellY, uint8 _effectId) external onlyCanvasOwner(_canvasId) {
        uint256 cellIndex = uint256(_cellY) * _canvasConfigs[_canvasId].width + _cellX;
        require(_isValidCell(_canvasId, _cellX, _cellY), "Invalid cell coordinates");

        CellState storage cell = _cellStates[_canvasId][cellIndex];
        // Only remove if it's the *current* effect and hasn't expired
        if (cell.effectId == _effectId && cell.effectEndTime > block.timestamp) {
             cell.effectId = 0;
             cell.effectEndTime = 0;
             emit CellEffectRemoved(_canvasId, _cellX, _cellY, _effectId);
        }
     }


    // 25. Allows the canvas owner to withdraw fees collected on their canvas
    function withdrawCanvasFees(uint256 _canvasId) external nonReentrant onlyCanvasOwner(_canvasId) {
        uint256 amount = _canvasOwnerFees[_canvasId];
        require(amount > 0, "No fees to withdraw");

        _canvasOwnerFees[_canvasId] = 0;
        (bool success, ) = payable(msg.sender).call{value: amount}("");
        require(success, "Fee withdrawal failed");

        emit CanvasFeesWithdrawn(_canvasId, msg.sender, amount);
    }


    // --- User Interaction Functions ---

    // 17. Paints a single cell on a canvas
    function paintCell(uint256 _canvasId, uint16 _cellX, uint16 _cellY, uint32 _color) external payable nonReentrant {
        CanvasConfig storage config = _canvasConfigs[_canvasId];
        require(_exists(_canvasId), "Canvas does not exist");
        require(_isValidCell(_canvasId, _cellX, _cellY), "Invalid cell coordinates");

        uint256 cellIndex = uint256(_cellY) * config.width + _cellX;
        CellState storage cell = _cellStates[_canvasId][cellIndex];

        require(!cell.isLocked || cell.lockedUntil < block.timestamp, "Cell is locked");
        require(msg.value >= config.paintingCost, "Insufficient payment");

        // Transfer cost - simplified: canvas owner gets all, could split with cell owner
        uint256 feeShareForCanvasOwner = msg.value; // Example: 100% to canvas owner
        // uint256 feeShareForCellOwner = 0; // Example: 0% to cell owner
        // If splitting:
        // uint256 feeShareForCellOwner = msg.value * cellOwnerShareBasisPoints / 10000;
        // uint256 feeShareForCanvasOwner = msg.value - feeShareForCellOwner;

        // Accrue fees (actual transfer happens on withdrawal)
        _canvasOwnerFees[_canvasId] += feeShareForCanvasOwner;
        // If splitting:
        // if (cell.owner != address(0)) {
        //     _cellOwnerFees[_canvasId][cellIndex][cell.owner] += feeShareForCellOwner;
        // } else {
        //    // Handle fees for unowned cells, maybe send to canvas owner or burn
        //    _canvasOwnerFees[_canvasId] += feeShareForCellOwner;
        // }


        // Refund excess payment
        if (msg.value > config.paintingCost) {
            payable(msg.sender).transfer(msg.value - config.paintingCost);
        }

        // Update cell state
        cell.color = _color;
        cell.owner = msg.sender; // The painter becomes the cell owner
        cell.lastPaintedTime = uint64(block.timestamp);
        // Reset temporary effects on paint? Depends on desired behavior.

        emit CellPainted(_canvasId, _cellX, _cellY, msg.sender, _color, config.paintingCost);
    }

    // 18. Paints multiple cells in a single transaction
    function batchPaintCells(
        uint256 _canvasId,
        uint16[] calldata _cellX,
        uint16[] calldata _cellY,
        uint32[] calldata _colors
    ) external payable nonReentrant {
        CanvasConfig storage config = _canvasConfigs[_canvasId];
        require(_exists(_canvasId), "Canvas does not exist");
        require(_cellX.length == _cellY.length && _cellX.length == _colors.length, "Input array lengths must match");
        require(_cellX.length > 0, "Arrays cannot be empty");
        // Add limit on batch size to prevent hitting block gas limit
        uint265 maxBatchSize = 50; // Example limit
        require(_cellX.length <= maxBatchSize, "Batch size exceeds limit");


        uint256 totalCost = uint256(_cellX.length) * config.paintingCost;
        require(msg.value >= totalCost, "Insufficient payment for batch");

        uint256 totalFeeShareForCanvasOwner = 0;
        // uint256 totalFeeShareForCellOwners = 0; // If splitting fees

        for (uint256 i = 0; i < _cellX.length; i++) {
            uint16 cellX = _cellX[i];
            uint16 cellY = _cellY[i];
            uint32 color = _colors[i];

            require(_isValidCell(_canvasId, cellX, cellY), "Invalid cell coordinates in batch");

            uint256 cellIndex = uint256(cellY) * config.width + cellX;
            CellState storage cell = _cellStates[_canvasId][cellIndex];

            require(!cell.isLocked || cell.lockedUntil < block.timestamp, "One or more cells locked");

            // Calculate fee shares per cell (simplified: canvas owner gets all)
            uint256 feeShareForCanvasOwner = config.paintingCost;
            // uint256 feeShareForCellOwner = 0;

            totalFeeShareForCanvasOwner += feeShareForCanvasOwner;
            // if splitting:
            // totalFeeShareForCellOwners += feeShareForCellOwner;
            // if (cell.owner != address(0)) {
            //     _cellOwnerFees[_canvasId][cellIndex][cell.owner] += feeShareForCellOwner;
            // } else {
            //    _canvasOwnerFees[_canvasId] += feeShareForCellOwner;
            // }


            // Update cell state
            cell.color = color;
            cell.owner = msg.sender; // The painter becomes the cell owner
            cell.lastPaintedTime = uint64(block.timestamp);
            // Reset temporary effects?

            emit CellPainted(_canvasId, cellX, cellY, msg.sender, color, config.paintingCost);
        }

        // Accrue total fees
        _canvasOwnerFees[_canvasId] += totalFeeShareForCanvasOwner;
        // If splitting:
        // _canvasOwnerFees[_canvasId] += totalFeeShareForCanvasOwner; // Already added above inside loop

        // Refund excess payment
        if (msg.value > totalCost) {
            payable(msg.sender).transfer(msg.value - totalCost);
        }
    }

    // 19. Transfers ownership of a specific cell. Can only be called by current cell owner or canvas owner.
    function transferCell(uint256 _canvasId, uint16 _cellX, uint16 _cellY, address _to) external {
         require(_exists(_canvasId), "Canvas does not exist");
         require(_isValidCell(_canvasId, _cellX, _cellY), "Invalid cell coordinates");
         require(_to != address(0), "Transfer to zero address");

         uint256 cellIndex = uint256(_cellY) * _canvasConfigs[_canvasId].width + _cellX;
         CellState storage cell = _cellStates[_canvasId][cellIndex];

         // Check if caller is the cell owner or the canvas owner
         address currentCellOwner = cell.owner;
         address canvasOwner = ownerOf(_canvasId);

         require(msg.sender == currentCellOwner || msg.sender == canvasOwner, "Not authorized to transfer cell");

         // Important: Decide what happens to accrued fees for the cell's old owner.
         // Option A (simple): Fees stay with the old owner, claimable later via withdrawCellOwnerFees.
         // Option B: Transfer fees to the new owner. (More complex state management required)
         // Option C: Payout fees to the old owner immediately on transfer.

         // For this example, let's use Option A: fees stay with the old owner.
         // The `_cellOwnerFees` mapping already handles this implicitly by being keyed by `address`.

         cell.owner = _to; // Update cell owner

         emit CellOwnershipTransferred(_canvasId, _cellX, _cellY, currentCellOwner, _to);
    }

    // 24. Allows anyone to trigger decay for specified cells.
    // This doesn't auto-run, relies on external calls (potentially incentivized)
    // The actual "decay" might primarily be visual in the metadata renderer,
    // but this function could update an on-chain state like "decay accumulation"
    // or modify the color based on time.
    // For simplicity, let's just emit an event indicating decay *should* be
    // processed by an off-chain renderer, using the last painted time and decay rate.
    // A more complex version could adjust `cell.color` here based on time delta.
    function triggerDecay(uint256 _canvasId, uint16[] calldata _cellX, uint16[] calldata _cellY) external {
        require(_exists(_canvasId), "Canvas does not exist");
        require(_cellX.length == _cellY.length, "Input array lengths must match");
        // Could add gas compensation logic here for the caller

        uint256[] memory cellIndices = new uint256[](_cellX.length);
        for (uint256 i = 0; i < _cellX.length; i++) {
             require(_isValidCell(_canvasId, _cellX[i], _cellY[i]), "Invalid cell coordinates in batch");
             cellIndices[i] = uint256(_cellY[i]) * _canvasConfigs[_canvasId].width + _cellX[i];
             // Optional: add logic to modify cell state here if on-chain decay is desired
             // e.g., decrease color value based on time since lastPaintedTime and decayRate
             // uint64 timePassed = uint64(block.timestamp) - _cellStates[_canvasId][cellIndices[i]].lastPaintedTime;
             // applyDecayToColor(_cellStates[_canvasId][cellIndices[i]].color, timePassed, _canvasConfigs[_canvasId].decayRate);
        }

        emit DecayTriggered(_canvasId, cellIndices);
    }

    // 26. Allows a cell owner to withdraw their accrued fees
    function withdrawCellOwnerFees(uint256 _canvasId, uint16 _cellX, uint16 _cellY) external nonReentrant {
        require(_exists(_canvasId), "Canvas does not exist");
        require(_isValidCell(_canvasId, _cellX, _cellY), "Invalid cell coordinates");

        uint265 cellIndex = uint256(_cellY) * _canvasConfigs[_canvasId].width + _cellX;
        address currentUser = msg.sender;
        uint256 amount = _cellOwnerFees[_canvasId][cellIndex][currentUser];
        require(amount > 0, "No fees to withdraw for this cell");

        _cellOwnerFees[_canvasId][cellIndex][currentUser] = 0;
        (bool success, ) = payable(currentUser).call{value: amount}("");
        require(success, "Cell owner fee withdrawal failed");

        emit CellOwnerFeesWithdrawn(_canvasId, _cellX, _cellY, currentUser, amount);
    }


    // --- Query Functions ---

    // 2. Returns the total number of Canvas NFTs created
    function totalSupply() public view returns (uint256) {
        return _canvasIds.current();
    }

    // 27. Returns the dimensions of a specific canvas
    function getCanvasDimensions(uint256 _canvasId) public view returns (uint16 width, uint16 height) {
        require(_exists(_canvasId), "Canvas does not exist");
        CanvasConfig storage config = _canvasConfigs[_canvasId];
        return (config.width, config.height);
    }

    // 28. Returns the full state struct of a cell
    function getCellState(uint256 _canvasId, uint16 _cellX, uint16 _cellY) public view returns (CellState memory) {
        require(_exists(_canvasId), "Canvas does not exist");
        require(_isValidCell(_canvasId, _cellX, _cellY), "Invalid cell coordinates");
        uint265 cellIndex = uint256(_cellY) * _canvasConfigs[_canvasId].width + _cellX;
        return _cellStates[_canvasId][cellIndex];
    }

    // 29. Returns the current owner of a specific cell
    function getCellOwner(uint256 _canvasId, uint16 _cellX, uint16 _cellY) public view returns (address) {
        require(_exists(_canvasId), "Canvas does not exist");
        require(_isValidCell(_canvasId, _cellX, _cellY), "Invalid cell coordinates");
        uint265 cellIndex = uint256(_cellY) * _canvasConfigs[_canvasId].width + _cellX;
        return _cellStates[_canvasId][cellIndex].owner;
    }

    // 30. Returns the full configuration struct of a canvas
    function getCanvasConfig(uint256 _canvasId) public view returns (CanvasConfig memory) {
        require(_exists(_canvasId), "Canvas does not exist");
        return _canvasConfigs[_canvasId];
    }

    // 31. Calculates a hash based on the current state of all cells in a canvas
    // This hash changes if any cell's state (color, owner, effect, lock status) changes.
    // Used by off-chain systems to know when cached metadata is stale.
    // Note: Calculating hash of *all* cells for a large canvas might hit gas limits.
    // A better approach for very large canvases might hash sections, or rely on
    // an off-chain service monitoring events.
    // For demonstration, we iterate a reasonable number of cells.
    // A production system might require different state representation or hashing approach.
    function getCanvasStateHash(uint256 _canvasId) public view returns (bytes32) {
         require(_exists(_canvasId), "Canvas does not exist");
         CanvasConfig storage config = _canvasConfigs[_canvasId];
         uint256 totalCells = uint256(config.width) * config.height;

         // Hashing a large amount of data on-chain is gas-intensive.
         // Limit the number of cells considered for the hash or use a different state representation.
         // For this example, we'll hash a limited number or a derived state representation.
         // A full hash requires iterating all cells, which is bad for large grids.
         // Let's demonstrate hashing based on recent changes or a summary state.
         // Simpler example: Hash the canvas config + a few key cell states + total paints/last paint time on canvas.
         // This is a simplification; a true state hash for a dynamic image is complex.
         // A robust solution might involve merklizing cell states.
         bytes32 hash = keccak256(abi.encodePacked(
             config.width,
             config.height,
             config.paintingCost,
             config.decayRate,
             // Add a few sample cell states or summary data
             _cellStates[_canvasId][0].color,
             _cellStates[_canvasId][0].owner,
             _cellStates[_canvasId][0].lastPaintedTime,
             _cellStates[_canvasId][totalCells / 2].color, // Middle cell
             _cellStates[_canvasId][totalCells - 1].color // Last cell
             // ... potentially other summary data like total paint count on canvas
         ));

         // A more accurate hash would require iterating through all cell states,
         // which is only feasible for small canvases or off-chain calculation.
         // For very large canvases, the metadata URI would likely point to
         // an off-chain renderer/API that queries the contract state directly
         // or relies on blockchain events to update its view.
         // The stateHash could then be based on event logs or a state root if using a Merkle tree.

         return hash;
    }


    // 32. Checks if a specific cell is currently locked
    function isCellLocked(uint256 _canvasId, uint16 _cellX, uint16 _cellY) public view returns (bool) {
        require(_exists(_canvasId), "Canvas does not exist");
        require(_isValidCell(_canvasId, _cellX, _cellY), "Invalid cell coordinates");
        uint265 cellIndex = uint256(_cellY) * _canvasConfigs[_canvasId].width + _cellX;
        CellState storage cell = _cellStates[_canvasId][cellIndex];
        return cell.isLocked && cell.lockedUntil >= block.timestamp;
    }

    // 33. Returns the timestamp a cell was last painted
    function getCellLastPaintedTime(uint256 _canvasId, uint16 _cellX, uint16 _cellY) public view returns (uint64) {
        require(_exists(_canvasId), "Canvas does not exist");
        require(_isValidCell(_canvasId, _cellX, _cellY), "Invalid cell coordinates");
        uint265 cellIndex = uint256(_cellY) * _canvasConfigs[_canvasId].width + _cellX;
        return _cellStates[_canvasId][cellIndex].lastPaintedTime;
    }

    // 34. Returns the base URI prefix for token metadata
    function getTokenUriBase() public view returns (string memory) {
        return _tokenUriBase;
    }

    // 36. Returns the current effect details for a cell
    function getCellEffect(uint256 _canvasId, uint16 _cellX, uint16 _cellY) public view returns (uint8 effectId, uint64 effectEndTime) {
        require(_exists(_canvasId), "Canvas does not exist");
        require(_isValidCell(_canvasId, _cellX, _cellY), "Invalid cell coordinates");
        uint256 cellIndex = uint256(_cellY) * _canvasConfigs[_canvasId].width + _cellX;
        CellState storage cell = _cellStates[_canvasId][cellIndex];
        // Only return effect if still active
        if (cell.effectEndTime >= block.timestamp) {
             return (cell.effectId, cell.effectEndTime);
        } else {
             return (0, 0); // No active effect
        }
    }


    // --- Internal / Helper Functions ---

    // Helper to check if coordinates are within canvas bounds
    function _isValidCell(uint256 _canvasId, uint16 _cellX, uint16 _cellY) internal view returns (bool) {
        CanvasConfig storage config = _canvasConfigs[_canvasId];
        return _cellX < config.width && _cellY < config.height;
    }

    // Helper function to get cell index from coordinates
    // function _getCellIndex(uint256 _canvasId, uint16 _cellX, uint16 _cellY) internal view returns (uint256) {
    //      return uint256(_cellY) * _canvasConfigs[_canvasId].width + _cellX;
    // }

    // Add other internal helpers as needed, e.g., for fee splitting calculation, decay math etc.
    // uint32 internal pure function applyDecayToColor(uint32 _color, uint64 _timePassed, uint64 _decayRate) {
    //    // Example simple decay: reduce R, G, B components by a rate based on time
    //    // This is computationally expensive and complex on-chain for meaningful visual results.
    //    // Better handled by off-chain renderer using lastPaintedTime and decayRate.
    //    // For demonstration, this logic is commented out.
    //    return _color; // No on-chain color modification by decay in this version
    // }


}

// Basic Base64 encoder utility for including state hash in URI.
// From https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Base64.sol
library Base64 {
    bytes constant private TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    function encode(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return "";

        // load the table into memory
        bytes memory table = TABLE;

        // allocate the resulting bytes object
        bytes memory buffer = new bytes(((data.length * 4 + 2) / 3));

        // index for buffer
        uint256 index = 0;

        for (uint256 i = 0; i < data.length; i += 3) {
            // retrieve byte[i] and byte[i+1]
            uint256 input = (uint256(data[i]) << 16) + (data.length > i + 1 ? uint256(data[i + 1]) << 8 : 0) + (data.length > i + 2 ? uint256(data[i + 2]) : 0);

            // populate buffer with the appropriate characters from the table
            buffer[index++] = table[(input >> 18) & 0x3F];
            buffer[index++] = table[(input >> 12) & 0x3F];
            buffer[index++] = data.length > i + 1 ? table[(input >> 6) & 0x3F] : bytes1('=');
            buffer[index++] = data.length > i + 2 ? table[input & 0x3F] : bytes1('=');
        }

        // Convert buffer to string
        return string(buffer);
    }
}
```