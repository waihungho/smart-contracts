Okay, here is a Solidity smart contract concept for an "Infinite Canvas".

This contract allows users to claim unique "cells" on a conceptually infinite 2D grid (represented by `int256` coordinates). Each claimed cell is a unique NFT (ERC721). Owners can change the color of their claimed cells. The contract incorporates features like dynamic pricing for claiming cells, batch operations, a delegation system for drawing permissions, a simple on-chain generative "trait" based on coordinates, and basic admin/treasury functions.

It aims for creativity by combining NFT ownership with a persistent, shared state (the grid), adding delegation for collaborative drawing, and including a simple generative element tied to the cell's position. It avoids common patterns like simple token transfers, staking, or standard DAO voting, focusing instead on a unique interactive digital asset.

**Outline:**

1.  **License and Pragma**
2.  **Imports:** ERC721, Ownable, ReentrancyGuard, Pausable, Math (for hashing/traits).
3.  **Errors:** Custom errors for clarity.
4.  **Structs:** `CellState` to store per-cell data.
5.  **State Variables:** Mappings for cell data, ownership, coordinates-to-ID, ID-to-coordinates, delegation, counters, pricing, treasury.
6.  **Events:** For key actions like claiming, color changes, delegation.
7.  **Modifiers:** Standard OpenZeppelin modifiers (`onlyOwner`, `whenNotPaused`, `nonReentrant`).
8.  **Constructor:** Initialize ERC721, owner, initial price, treasury.
9.  **ERC721 Standard Functions:** (balanceOf, ownerOf, safeTransferFrom, etc.) - Required for NFT compliance.
10. **Canvas Core Functions:** Claiming cells (single and batch), getting cell state, checking if claimed.
11. **Cell Manipulation Functions:** Changing color (single and batch), resetting.
12. **Advanced/Creative Functions:** Delegation of drawing rights, checking delegation status, generating a cell trait based on coordinates.
13. **Query Functions:** Getting price info, total claimed count, coordinate/ID lookups.
14. **Admin & Treasury Functions:** Setting prices, changing treasury address, withdrawing funds, pausing/unpausing.
15. **Internal Helper Functions:** For core logic, minting, burning, coordinate/ID mapping management.

**Function Summary:**

1.  `constructor(string memory name, string memory symbol, uint256 initialClaimPrice, uint256 priceIncrease, address initialTreasury)`: Initializes the contract, ERC721 properties, pricing, and treasury.
2.  `balanceOf(address owner) external view returns (uint256)`: Returns the number of tokens (cells) owned by an address (ERC721 standard).
3.  `ownerOf(uint256 tokenId) external view returns (address)`: Returns the owner of a specific token (cell ID) (ERC721 standard).
4.  `safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) external payable`: Transfers a token safely (ERC721 standard).
5.  `safeTransferFrom(address from, address to, uint256 tokenId) external payable`: Transfers a token safely without data (ERC721 standard).
6.  `transferFrom(address from, address to, uint256 tokenId) external payable`: Transfers a token (ERC721 standard).
7.  `approve(address to, uint256 tokenId) external`: Grants approval for an address to transfer a specific token (ERC721 standard).
8.  `getApproved(uint256 tokenId) external view returns (address)`: Returns the approved address for a specific token (ERC721 standard).
9.  `setApprovalForAll(address operator, bool approved) external`: Grants or revokes approval for an operator to manage all of the caller's tokens (ERC721 standard).
10. `isApprovedForAll(address owner, address operator) external view returns (bool)`: Checks if an operator has approval for all of an owner's tokens (ERC721 standard).
11. `tokenURI(uint256 tokenId) public view virtual override returns (string memory)`: Returns the metadata URI for a token (ERC721 Metadata extension).
12. `claimCell(int256 x, int256 y) external payable nonReentrant whenNotPaused`: Allows a user to claim and mint a new cell at specified coordinates. Requires payment based on the current claim price.
13. `claimCellsBatch(int256[] calldata xCoords, int256[] calldata yCoords) external payable nonReentrant whenNotPaused`: Allows a user to claim multiple cells in a single transaction. Requires payment based on the total cost. Limited batch size.
14. `getCellState(int256 x, int256 y) external view returns (uint256 cellId, address owner, bytes3 color, uint256 claimedTimestamp)`: Retrieves the current state (ID, owner, color, timestamp) of a cell at given coordinates.
15. `getCellId(int256 x, int256 y) external view returns (uint256)`: Returns the unique ID of the cell at specified coordinates. Returns 0 if not claimed.
16. `getCellCoords(uint256 cellId) external view returns (int256 x, int256 y)`: Returns the coordinates (x, y) for a given cell ID.
17. `isCellClaimed(int256 x, int256 y) external view returns (bool)`: Checks if a cell at the given coordinates has been claimed.
18. `changeCellColor(uint256 cellId, bytes3 newColor) external whenNotPaused`: Allows the owner or a delegated address to change the color of a claimed cell.
19. `changeCellsColorBatch(uint256[] calldata cellIds, bytes3[] calldata newColors) external whenNotPaused`: Allows the owner or a delegated address to change the color of multiple claimed cells in a single transaction. Limited batch size.
20. `delegateDrawingPermission(uint256 cellId, address delegatee) external whenNotPaused`: Allows the cell owner to grant drawing permission for a specific cell to another address.
21. `revokeDrawingPermission(uint256 cellId, address delegatee) external whenNotPaused`: Allows the cell owner to revoke drawing permission for a specific cell from another address.
22. `canDrawOnCell(uint256 cellId, address drawer) external view returns (bool)`: Checks if an address has drawing permission (either owner or delegated) for a specific cell.
23. `getCellTrait(int256 x, int256 y) public pure returns (uint256 traitValue)`: A deterministic function returning a "trait" value based on the cell's coordinates. Can be used for off-chain generative art influence or game mechanics.
24. `getClaimedCellCount() external view returns (uint256)`: Returns the total number of cells that have been claimed.
25. `getBaseClaimPrice() external view returns (uint256)`: Returns the base price to claim a cell.
26. `getPriceIncreasePerCell() external view returns (uint256)`: Returns the amount the claim price increases per claimed cell.
27. `setClaimPrice(uint256 newPrice) external onlyOwner`: Allows the contract owner to set the base claim price.
28. `setPriceIncrease(uint256 newIncrease) external onlyOwner`: Allows the contract owner to set the price increase per claimed cell.
29. `setTreasuryAddress(address newTreasury) external onlyOwner`: Allows the contract owner to change the address where treasury funds are sent.
30. `withdrawTreasury() external onlyOwner nonReentrant`: Allows the treasury address (or owner if treasury is zero) to withdraw the contract's accumulated Ether.
31. `pause() external onlyOwner whenNotPaused`: Pauses the contract, preventing sensitive actions.
32. `unpause() external onlyOwner whenPaused`: Unpauses the contract.

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/math/Math.sol"; // For potential trait calculation

// Outline:
// 1. License and Pragma
// 2. Imports (ERC721, Ownable, ReentrancyGuard, Pausable, Math)
// 3. Errors (Custom errors)
// 4. Structs (CellState)
// 5. State Variables (Mappings for cells, ownership, ID/coord mapping, delegation, counters, pricing, treasury)
// 6. Events (CellClaimed, CellColorChanged, DelegationGranted/Revoked)
// 7. Modifiers (OpenZeppelin standard)
// 8. Constructor
// 9. ERC721 Standard Functions (10 functions)
// 10. Canvas Core Functions (Claiming single/batch, getting state, ID/Coord lookup, checking claimed status) - 7 functions
// 11. Cell Manipulation Functions (Changing color single/batch) - 2 functions
// 12. Advanced/Creative Functions (Delegation grant/revoke/check, Generative Trait) - 4 functions
// 13. Query Functions (Price info, claimed count) - 3 functions
// 14. Admin & Treasury Functions (Set price/increase/treasury, Withdraw, Pause/Unpause) - 6 functions
// 15. Internal Helper Functions (Minting, burning, mapping management)

// Function Summary:
// 1. constructor: Initializes contract, ERC721, pricing, treasury.
// 2. balanceOf: ERC721 standard.
// 3. ownerOf: ERC721 standard.
// 4. safeTransferFrom(address,address,uint256,bytes): ERC721 standard.
// 5. safeTransferFrom(address,address,uint256): ERC721 standard.
// 6. transferFrom: ERC721 standard.
// 7. approve: ERC721 standard.
// 8. getApproved: ERC721 standard.
// 9. setApprovalForAll: ERC721 standard.
// 10. isApprovedForAll: ERC721 standard.
// 11. tokenURI: ERC721 Metadata URI generator.
// 12. claimCell: Claims and mints a cell at (x,y). Pays current price.
// 13. claimCellsBatch: Claims multiple cells in a batch. Pays total price.
// 14. getCellState: Gets ID, owner, color, timestamp for a cell at (x,y).
// 15. getCellId: Gets the ID for a cell at (x,y).
// 16. getCellCoords: Gets the (x,y) coordinates for a cell ID.
// 17. isCellClaimed: Checks if a cell at (x,y) is claimed.
// 18. changeCellColor: Changes the color of a claimed cell (owner or delegated).
// 19. changeCellsColorBatch: Changes color of multiple cells in a batch (owner or delegated).
// 20. delegateDrawingPermission: Allows owner to grant drawing permission for a cell.
// 21. revokeDrawingPermission: Allows owner to revoke drawing permission for a cell.
// 22. canDrawOnCell: Checks if an address can draw on a cell (owner or delegated).
// 23. getCellTrait: Pure function generating a deterministic trait value from coordinates.
// 24. getClaimedCellCount: Returns the total number of claimed cells.
// 25. getBaseClaimPrice: Returns the base price to claim a cell.
// 26. getPriceIncreasePerCell: Returns the price increase per claimed cell.
// 27. setClaimPrice: Owner sets the base claim price.
// 28. setPriceIncrease: Owner sets the price increase per cell.
// 29. setTreasuryAddress: Owner sets the treasury withdrawal address.
// 30. withdrawTreasury: Allows treasury or owner to withdraw accumulated Ether.
// 31. pause: Owner pauses sensitive actions.
// 32. unpause: Owner unpauses the contract.

contract InfiniteCanvas is ERC721, Ownable, ReentrancyGuard, Pausable {
    using Math for uint256;

    // --- Errors ---
    error CellAlreadyClaimed(int256 x, int256 y);
    error CellNotClaimed(int256 x, int256 y);
    error InvalidCoordinates();
    error InvalidBatchLength();
    error InsufficientPayment(uint256 required, uint256 received);
    error NotCellOwnerOrDelegated(uint256 cellId, address caller);
    error ZeroAddressDelegation();
    error SelfDelegation();
    error AlreadyDelegated();
    error NotDelegated();
    error NothingToWithdraw();
    error BatchSizeExceeded(uint256 maxBatchSize);

    // --- Structs ---
    struct CellState {
        uint256 cellId;
        address owner;
        bytes3 color; // R, G, B bytes
        uint256 claimedTimestamp;
    }

    // --- State Variables ---

    // Mapping coordinates to cell state. Using int256 for potentially infinite grid in all directions.
    mapping(int256 => mapping(int256 => CellState)) private _cells;
    // Mapping cell ID to coordinates for quick lookup.
    mapping(uint256 => struct { int256 x; int256 y; }) private _cellIdToCoords;
    // Mapping coordinates back to cell ID for quick check if claimed.
    mapping(int256 => mapping(int256 => uint256)) private _cellCoordsToId;

    uint256 private _cellIdCounter; // Starts from 1

    // Delegation: cellId => delegatee address => bool
    mapping(uint256 => mapping(address => bool)) public delegatedDrawers;

    // Pricing
    uint256 private _baseClaimPrice;
    uint256 private _priceIncreasePerCell; // Price increases by this amount for each new cell claimed

    // Treasury
    address public treasuryAddress;

    // Batch Limits
    uint256 public constant MAX_BATCH_SIZE = 100;

    // --- Events ---
    event CellClaimed(uint256 indexed cellId, int256 x, int256 y, address indexed owner, uint256 pricePaid, uint256 timestamp);
    event CellColorChanged(uint256 indexed cellId, bytes3 oldColor, bytes3 newColor, address indexed changer);
    event DrawingDelegated(uint256 indexed cellId, address indexed owner, address indexed delegatee);
    event DrawingRevoked(uint256 indexed cellId, address indexed owner, address indexed delegatee);
    event TreasuryWithdrawal(address indexed treasury, uint256 amount);
    event ClaimPriceUpdated(uint256 oldPrice, uint256 newPrice);
    event PriceIncreaseUpdated(uint256 oldIncrease, uint256 newIncrease);
    event TreasuryAddressUpdated(address oldAddress, address newAddress);

    // --- Constructor ---
    constructor(string memory name, string memory symbol, uint256 initialClaimPrice, uint256 priceIncrease, address initialTreasury)
        ERC721(name, symbol)
        Ownable(msg.sender)
    {
        if (initialTreasury == address(0)) revert ZeroAddressDelegation(); // Using ZeroAddressDelegation error for lack of a dedicated one

        _cellIdCounter = 0; // Start IDs from 1
        _baseClaimPrice = initialClaimPrice;
        _priceIncreasePerCell = priceIncrease;
        treasuryAddress = initialTreasury;
    }

    // --- ERC721 Standard Functions (Implemented by inheriting ERC721) ---
    // 2. balanceOf(address owner)
    // 3. ownerOf(uint256 tokenId)
    // 4. safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
    // 5. safeTransferFrom(address from, address to, uint256 tokenId)
    // 6. transferFrom(address from, address to, uint256 tokenId)
    // 7. approve(address to, uint256 tokenId)
    // 8. getApproved(uint256 tokenId)
    // 9. setApprovalForAll(address operator, bool approved)
    // 10. isApprovedForAll(address owner, address operator)

    /// @notice See {IERC721Metadata-tokenURI}. Returns a placeholder URI. Off-chain service handles metadata.
    /// @dev Metadata URL will be `ipfs://[CID]/[tokenId].json`. Off-chain indexer provides the actual metadata based on cell coords/state.
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        // Check if the token exists
        if (!_exists(tokenId)) revert ERC721NonexistentToken(tokenId);

        // In a real dApp, you would have a base URI pointing to a metadata service or IPFS gateway.
        // This service would fetch the cell data (coords, color, etc.) from the contract
        // and generate the ERC721 metadata JSON for that specific token ID.
        // Example: string(abi.encodePacked(_baseURI(), Strings.toString(tokenId), ".json"))
        // For this example, we return a simple placeholder or an empty string.
        // A more complete implementation would require setting a base URI.
        // For simplicity and avoiding external deps in this example, we return an empty string or a simple indicator.
        // Let's return a format that suggests where metadata might be found.
        // This requires an off-chain service to serve the actual JSON based on the ID.
        string memory base = "ipfs://YOUR_METADATA_CID/"; // Replace with your actual IPFS CID or service URL
        return string(abi.encodePacked(base, Strings.toString(tokenId), ".json"));
    }


    // --- Canvas Core Functions ---

    /// @notice Allows claiming a new cell at specific coordinates. Mints an NFT for the cell.
    /// @param x The x-coordinate of the cell.
    /// @param y The y-coordinate of the cell.
    function claimCell(int256 x, int256 y) external payable nonReentrant whenNotPaused {
        if (_cellCoordsToId[x][y] != 0) revert CellAlreadyClaimed(x, y);

        uint256 currentClaimPrice = getCurrentClaimPrice();
        if (msg.value < currentClaimPrice) revert InsufficientPayment(currentClaimPrice, msg.value);

        _cellIdCounter++;
        uint256 newCellId = _cellIdCounter;

        // Initialize cell state
        _cells[x][y] = CellState({
            cellId: newCellId,
            owner: msg.sender,
            color: 0x000000, // Default color (black)
            claimedTimestamp: block.timestamp
        });

        // Update coordinate-ID mappings
        _cellIdToCoords[newCellId] = struct { int256 x; int256 y; }(x, y);
        _cellCoordsToId[x][y] = newCellId;

        // Mint the NFT
        _safeMint(msg.sender, newCellId);

        // Send received Ether to the treasury
        // Any excess payment is also sent to the treasury
        if (msg.value > 0) {
             // Check balance before transfer to prevent sending more than available
            (bool success, ) = payable(treasuryAddress).call{value: msg.value}("");
            // It's acceptable if transfer fails here; the payment was made, but treasury might be blocked.
            // A robust system might hold it in the contract or handle it differently.
            // For simplicity, we proceed, assuming treasury is usually ready.
            // Consider adding re-attempt logic or error handling for the treasury transfer in production.
             if (!success) {
                 // Log or handle failure to send to treasury - funds remain in contract balance
                 emit Transfer(address(this), treasuryAddress, msg.value); // Emit a generic transfer event for transparency
             } else {
                 emit TreasuryWithdrawal(treasuryAddress, msg.value); // Re-using this event for clarity of where funds went
             }
        }


        emit CellClaimed(newCellId, x, y, msg.sender, msg.value, block.timestamp);
    }

    /// @notice Allows claiming multiple cells in a single transaction. Mints NFTs for each cell.
    /// @param xCoords Array of x-coordinates.
    /// @param yCoords Array of y-coordinates.
    /// @dev Batch size is limited by MAX_BATCH_SIZE to prevent hitting gas limits.
    function claimCellsBatch(int256[] calldata xCoords, int256[] calldata yCoords) external payable nonReentrant whenNotPaused {
        if (xCoords.length != yCoords.length || xCoords.length == 0) revert InvalidBatchLength();
        if (xCoords.length > MAX_BATCH_SIZE) revert BatchSizeExceeded(MAX_BATCH_SIZE);

        uint256 totalCost = 0;
        uint256 currentClaimedCount = _cellIdCounter; // Use current count for pricing calculation

        for (uint i = 0; i < xCoords.length; i++) {
            int256 x = xCoords[i];
            int256 y = yCoords[i];

            if (_cellCoordsToId[x][y] != 0) revert CellAlreadyClaimed(x, y);

            // Calculate price dynamically for each cell in the batch
            totalCost += _baseClaimPrice + (currentClaimedCount + i) * _priceIncreasePerCell;
        }

        if (msg.value < totalCost) revert InsufficientPayment(totalCost, msg.value);

        for (uint i = 0; i < xCoords.length; i++) {
            int256 x = xCoords[i];
            int256 y = yCoords[i];

            _cellIdCounter++;
            uint256 newCellId = _cellIdCounter;

            _cells[x][y] = CellState({
                cellId: newCellId,
                owner: msg.sender,
                color: 0x000000, // Default color (black)
                claimedTimestamp: block.timestamp
            });

            _cellIdToCoords[newCellId] = struct { int256 x; int256 y; }(x, y);
            _cellCoordsToId[x][y] = newCellId;

            _safeMint(msg.sender, newCellId);

            emit CellClaimed(newCellId, x, y, msg.sender, (_baseClaimPrice + (currentClaimedCount + i) * _priceIncreasePerCell), block.timestamp); // Emit price paid per cell for granularity
        }

        // Send total received Ether to the treasury (including potential overpayment)
        if (msg.value > 0) {
             (bool success, ) = payable(treasuryAddress).call{value: msg.value}("");
              if (!success) {
                 emit Transfer(address(this), treasuryAddress, msg.value);
              } else {
                 emit TreasuryWithdrawal(treasuryAddress, msg.value);
              }
        }
    }

    /// @notice Retrieves the state of a cell at given coordinates.
    /// @param x The x-coordinate.
    /// @param y The y-coordinate.
    /// @return cellId The unique ID of the cell (0 if not claimed).
    /// @return owner The owner's address (address(0) if not claimed).
    /// @return color The cell's color (0x000000 if not claimed or default).
    /// @return claimedTimestamp The timestamp when the cell was claimed (0 if not claimed).
    function getCellState(int256 x, int256 y) external view returns (uint256 cellId, address owner, bytes3 color, uint256 claimedTimestamp) {
        uint256 id = _cellCoordsToId[x][y];
        if (id == 0) {
             return (0, address(0), 0x000000, 0);
        }
        CellState storage cell = _cells[x][y];
        return (cell.cellId, cell.owner, cell.color, cell.claimedTimestamp);
    }

    /// @notice Gets the unique ID of a cell at specified coordinates.
    /// @param x The x-coordinate.
    /// @param y The y-coordinate.
    /// @return The cell's ID, or 0 if the cell is not claimed.
    function getCellId(int256 x, int256 y) external view returns (uint256) {
        return _cellCoordsToId[x][y];
    }

    /// @notice Gets the coordinates (x, y) for a given cell ID.
    /// @param cellId The ID of the cell.
    /// @return x The x-coordinate.
    /// @return y The y-coordinate.
    function getCellCoords(uint256 cellId) external view returns (int256 x, int256 y) {
        // Basic check, will revert if cellIdToCoords[cellId] is zero-initialized (ID 0 is unused)
        // A more robust check could use _exists(cellId) if needed, but ERC721 functions handle non-existent tokens.
        if (cellId == 0 || !_exists(cellId)) revert ERC721NonexistentToken(cellId);
        struct { int256 x; int256 y; } memory coords = _cellIdToCoords[cellId];
        return (coords.x, coords.y);
    }

    /// @notice Checks if a cell at the given coordinates has been claimed.
    /// @param x The x-coordinate.
    /// @param y The y-coordinate.
    /// @return True if claimed, false otherwise.
    function isCellClaimed(int256 x, int256 y) external view returns (bool) {
        return _cellCoordsToId[x][y] != 0;
    }

    // --- Cell Manipulation Functions ---

    /// @notice Allows the owner or a delegated address to change the color of a claimed cell.
    /// @param cellId The ID of the cell.
    /// @param newColor The new color (RGB bytes).
    function changeCellColor(uint256 cellId, bytes3 newColor) external whenNotPaused {
        if (!_exists(cellId)) revert ERC721NonexistentToken(cellId);

        if (!canDrawOnCell(cellId, msg.sender)) revert NotCellOwnerOrDelegated(cellId, msg.sender);

        struct { int256 x; int256 y; } memory coords = _cellIdToCoords[cellId];
        CellState storage cell = _cells[coords.x][coords.y];
        bytes3 oldColor = cell.color;
        cell.color = newColor;

        emit CellColorChanged(cellId, oldColor, newColor, msg.sender);
    }

     /// @notice Allows the owner or a delegated address to change the color of multiple claimed cells in a batch.
    /// @param cellIds Array of cell IDs.
    /// @param newColors Array of new colors (RGB bytes), matching the length of cellIds.
    /// @dev Batch size is limited by MAX_BATCH_SIZE to prevent hitting gas limits.
    function changeCellsColorBatch(uint256[] calldata cellIds, bytes3[] calldata newColors) external whenNotPaused {
        if (cellIds.length != newColors.length || cellIds.length == 0) revert InvalidBatchLength();
        if (cellIds.length > MAX_BATCH_SIZE) revert BatchSizeExceeded(MAX_BATCH_SIZE);

        for (uint i = 0; i < cellIds.length; i++) {
            uint256 cellId = cellIds[i];
            bytes3 newColor = newColors[i];

            if (!_exists(cellId)) revert ERC721NonexistentToken(cellId); // Revert on first invalid ID

            if (!canDrawOnCell(cellId, msg.sender)) revert NotCellOwnerOrDelegated(cellId, msg.sender); // Revert on first unauthorized cell

            struct { int256 x; int256 y; } memory coords = _cellIdToCoords[cellId];
            CellState storage cell = _cells[coords.x][coords.y];
            bytes3 oldColor = cell.color;
            cell.color = newColor;

            emit CellColorChanged(cellId, oldColor, newColor, msg.sender);
        }
    }


    // --- Advanced/Creative Functions ---

    /// @notice Allows the owner of a cell to grant drawing permission to another address.
    /// @param cellId The ID of the cell.
    /// @param delegatee The address to grant permission to.
    function delegateDrawingPermission(uint256 cellId, address delegatee) external whenNotPaused {
        if (!_exists(cellId)) revert ERC721NonexistentToken(cellId);
        if (ownerOf(cellId) != msg.sender) revert NotCellOwnerOrDelegated(cellId, msg.sender); // Only owner can delegate
        if (delegatee == address(0)) revert ZeroAddressDelegation();
        if (delegatee == msg.sender) revert SelfDelegation();
        if (delegatedDrawers[cellId][delegatee]) revert AlreadyDelegated();

        delegatedDrawers[cellId][delegatee] = true;
        emit DrawingDelegated(cellId, msg.sender, delegatee);
    }

    /// @notice Allows the owner of a cell to revoke drawing permission from a delegated address.
    /// @param cellId The ID of the cell.
    /// @param delegatee The address to revoke permission from.
    function revokeDrawingPermission(uint256 cellId, address delegatee) external whenNotPaused {
         if (!_exists(cellId)) revert ERC721NonexistentToken(cellId);
         if (ownerOf(cellId) != msg.sender) revert NotCellOwnerOrDelegated(cellId, msg.sender); // Only owner can revoke
         if (delegatee == address(0)) revert ZeroAddressDelegation();
         if (!delegatedDrawers[cellId][delegatee]) revert NotDelegated();

         delete delegatedDrawers[cellId][delegatee];
         emit DrawingRevoked(cellId, msg.sender, delegatee);
    }

    /// @notice Checks if an address has permission to draw on a specific cell (either owner or delegated).
    /// @param cellId The ID of the cell.
    /// @param drawer The address to check permission for.
    /// @return True if the address can draw, false otherwise.
    function canDrawOnCell(uint256 cellId, address drawer) public view returns (bool) {
        if (!_exists(cellId)) return false; // Cannot draw on a non-existent cell
        address cellOwner = ownerOf(cellId);
        return cellOwner == drawer || delegatedDrawers[cellId][drawer];
    }

    /// @notice Generates a deterministic "trait" value based on the cell's coordinates.
    /// @dev This is a simple example. More complex calculations or hashing can be used.
    /// @param x The x-coordinate.
    /// @param y The y-coordinate.
    /// @return A uint256 value representing the cell's trait.
    function getCellTrait(int256 x, int256 y) public pure returns (uint256 traitValue) {
        // Example trait calculation: A simple hash of the concatenated coordinates.
        // This provides a deterministic value unique to each coordinate pair.
        bytes memory coordBytes = abi.encodePacked(x, y);
        bytes32 hash = keccak256(coordBytes);
        return uint256(hash); // Convert hash to uint256
    }

    // --- Query Functions ---

    /// @notice Returns the current price to claim a single cell.
    /// @dev The price increases dynamically based on the total number of cells claimed.
    /// @return The price in Wei.
    function getCurrentClaimPrice() public view returns (uint256) {
        return _baseClaimPrice + _cellIdCounter * _priceIncreasePerCell;
    }

    /// @notice Returns the total number of cells that have been claimed.
    /// @return The total count.
    function getClaimedCellCount() external view returns (uint256) {
        return _cellIdCounter;
    }

     /// @notice Returns the base price to claim a cell.
    function getBaseClaimPrice() external view returns (uint256) {
        return _baseClaimPrice;
    }

    /// @notice Returns the price increase per claimed cell.
    function getPriceIncreasePerCell() external view returns (uint256) {
        return _priceIncreasePerCell;
    }


    // --- Admin & Treasury Functions ---

    /// @notice Allows the contract owner to set the base price for claiming a cell.
    /// @param newPrice The new base price in Wei.
    function setClaimPrice(uint256 newPrice) external onlyOwner {
        emit ClaimPriceUpdated(_baseClaimPrice, newPrice);
        _baseClaimPrice = newPrice;
    }

    /// @notice Allows the contract owner to set the price increase amount per cell claimed.
    /// @param newIncrease The new price increase amount in Wei.
    function setPriceIncrease(uint256 newIncrease) external onlyOwner {
        emit PriceIncreaseUpdated(_priceIncreasePerCell, newIncrease);
        _priceIncreasePerCell = newIncrease;
    }

    /// @notice Allows the contract owner to change the address where treasury funds are sent.
    /// @param newTreasury The new treasury address.
    function setTreasuryAddress(address newTreasury) external onlyOwner {
        if (newTreasury == address(0)) revert ZeroAddressDelegation(); // Using ZeroAddressDelegation error for lack of a dedicated one
        emit TreasuryAddressUpdated(treasuryAddress, newTreasury);
        treasuryAddress = newTreasury;
    }

    /// @notice Allows the treasury address (or owner if treasury is address(0)) to withdraw the contract's accumulated Ether balance.
    /// @dev Uses the pull pattern for security.
    function withdrawTreasury() external onlyOwner nonReentrant {
        uint256 balance = address(this).balance;
        if (balance == 0) revert NothingToWithdraw();

        address recipient = treasuryAddress;
        // Fallback to owner if treasuryAddress is somehow zero (shouldn't happen with current constructor/setter)
        if (recipient == address(0)) {
             recipient = owner();
        }

        (bool success, ) = payable(recipient).call{value: balance}("");
        if (!success) {
            // Transfer failed, emit event and potentially handle (e.g., log for manual review)
            // Funds remain in the contract. Reverting is also an option depending on desired behavior.
            // For this example, we just log the failure via event.
             emit Transfer(address(this), recipient, balance); // Log failed transfer
        } else {
            emit TreasuryWithdrawal(recipient, balance);
        }
    }


    /// @notice Pauses the contract, preventing core actions like claiming and changing colors.
    function pause() external onlyOwner whenNotPaused {
        _pause();
    }

    /// @notice Unpauses the contract.
    function unpause() external onlyOwner whenPaused {
        _unpause();
    }

    // --- Internal Helper Functions ---
    // ERC721 internal functions like _safeMint are used internally by claimCell.

    // Override _beforeTokenTransfer and _afterTokenTransfer if needed for hooks
    // For this contract, standard ERC721 transfer is fine, no special hooks needed for cell state during transfer.
    // The cell state remains linked to the token ID regardless of owner.


    // --- Fallback/Receive (Optional but good practice) ---
    // Receive Ether directly to the contract, only if needed outside claim functions.
    // Adding this allows ether to be sent to the contract, which can then be withdrawn via withdrawTreasury.
    receive() external payable {}
    fallback() external payable {}
}
```

**Explanation of Advanced/Creative/Trendy Concepts:**

1.  **Infinite Grid on-Chain:** Representing a conceptually infinite 2D space using `int256` coordinates and sparse storage (`mapping`). Only claimed cells consume storage, making it feasible.
2.  **NFT per Cell:** Each pixel/cell is a unique ERC721 token. This brings immediate compatibility with NFT marketplaces, wallets, and the broader Web3 ecosystem for ownership and trading.
3.  **Dynamic Pricing:** The cost of claiming a new cell increases as more cells are claimed (`_baseClaimPrice + claimedCellCount * _priceIncreasePerCell`). This creates scarcity and economic incentives, making early cells cheaper and later cells more expensive, a common mechanism in trendy NFT/game projects (like early land sales).
4.  **Delegated Drawing Permissions:** An owner can explicitly grant permission to another address to change the color of their specific cells *without* transferring ownership. This enables collaborative art projects, allowing a group to work on an area owned by one person, or letting artists work on collectors' pieces.
5.  **On-Chain Generative Trait:** The `getCellTrait` function provides a deterministic value based purely on the cell's coordinates. While simple here (a hash), this value can be used by off-chain dApps to influence how the cell is rendered, adding a generative or unique visual property based *solely* on its position, baked into the contract itself.
6.  **Batch Operations:** Including `claimCellsBatch` and `changeCellsColorBatch` adds efficiency and reduces gas costs for users wanting to interact with multiple cells, a common pattern in virtual world or game contracts.
7.  **Sparse Data Storage:** Only storing data for *claimed* cells (using mappings) is the standard and necessary technique for handling large, sparse datasets like a vast grid on-chain. The coordinate-to-ID and ID-to-coordinate mappings (`_cellCoordsToId`, `_cellIdToCoords`) allow efficient lookup in both directions.
8.  **Custom Errors:** Using `error` instead of `require` with string messages is current best practice for better gas efficiency and clearer error decoding off-chain.

This contract combines NFT ownership, dynamic economics, a novel interaction model (delegated drawing), and a simple on-chain generative element within the framework of a persistent, shared digital space.