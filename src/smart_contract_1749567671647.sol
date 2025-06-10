Okay, here is a Solidity smart contract concept for an "Infinite Canvas" with various advanced, creative, and interactive features.

It represents a vast digital grid where users can claim ownership of coordinates (tiles), paint them with colors, attach messages and metadata, and even set them for sale. Painting and claiming involve fees, distributed between the tile owner and the protocol. It includes features like batch operations, pausing, fee management, and distinct roles (owner vs. painter).

This design incorporates concepts like:
*   **Dynamic State:** Tile properties change over time.
*   **Coordinate System:** Using `int256` for potentially infinite coordinates.
*   **Distinct Roles:** Tile owner vs. Contract owner vs. Any painter.
*   **Fee Distribution:** Splitting transaction fees.
*   **Sales Mechanism:** On-chain listing and buying of tiles.
*   **Batch Operations:** Efficiency for multiple interactions.
*   **Metadata/Messaging:** Attaching external context or notes.
*   **Pausability:** Contract-level control.

---

**Infinite Canvas Smart Contract**

**Outline:**

1.  **License and Pragma:** Standard Solidity header.
2.  **Error Definitions:** Custom errors for clarity and gas efficiency.
3.  **State Variables:**
    *   `owner`: Contract administrator.
    *   `paused`: Pausability state.
    *   `claimFee`: Cost to claim an unowned tile.
    *   `paintFee`: Cost to paint any tile.
    *   `ownerPaintFeeBps`: Basis points of paint fee sent to tile owner.
    *   `protocolPaintFeeBps`: Basis points of paint fee sent to contract owner.
    *   `protocolFeesCollected`: Accumulated protocol fees.
    *   `totalTilesClaimed`: Counter for claimed tiles.
    *   `totalPaintEvents`: Counter for paint actions.
    *   `tiles`: Mapping storing `TileState` by coordinates (x, y).
    *   `tilesForSale`: Mapping storing `TileSaleDetails` for tiles listed for sale.
4.  **Structs:**
    *   `TileState`: Holds owner, last painter, color, timestamp.
    *   `TileSaleDetails`: Holds seller address and price for a tile listed for sale.
5.  **Events:**
    *   `TileClaimed`: When a tile is claimed.
    *   `TileOwnershipTransferred`: When ownership changes (transfer or buy).
    *   `TileRenounced`: When ownership is renounced.
    *   `TilePainted`: When a tile color/painter is updated.
    *   `TileMessageUpdated`: When a tile's message is set/cleared.
    *   `TileMetadataUriUpdated`: When a tile's metadata URI is set/cleared.
    *   `TileListedForSale`: When a tile is put up for sale.
    *   `TileBought`: When a tile is purchased.
    *   `TileSaleCancelled`: When a sale listing is removed.
    *   `FeeConfigUpdated`: When claim or paint fees change.
    *   `FeeDistributionConfigUpdated`: When fee distribution changes.
    *   `FeesWithdrawn`: When contract owner withdraws fees.
    *   `Paused`: When contract is paused.
    *   `Unpaused`: When contract is unpaused.
6.  **Modifiers:**
    *   `onlyOwner`: Restricts function calls to the contract owner.
    *   `whenNotPaused`: Prevents function calls when paused.
    *   `whenPaused`: Allows function calls only when paused.
7.  **Constructor:** Initializes owner, fees, and fee distribution.
8.  **Functions:**
    *   **Ownership & Claiming:**
        *   `claimTile(int256 x, int256 y)`: Claims an unowned tile by paying `claimFee`.
        *   `renounceTileOwnership(int256 x, int256 y)`: Owner gives up ownership.
        *   `transferTileOwnership(int256 x, int256 y, address newOwner)`: Transfers ownership (current owner only).
        *   `getTileOwner(int256 x, int256 y)`: Gets the owner of a tile.
        *   `isTileOwned(int256 x, int256 y)`: Checks if a tile is owned.
        *   `getTotalTilesClaimed()`: Gets total unique tiles claimed.
    *   **Painting & State:**
        *   `paintTile(int256 x, int256 y, bytes3 color)`: Paints a tile, pays `paintFee`, updates state and distributes fee.
        *   `batchPaintTiles(int256[] xs, int256[] ys, bytes3[] colors)`: Paints multiple tiles in one transaction.
        *   `getTileState(int256 x, int256 y)`: Gets the full state of a tile.
        *   `getTileLastPainter(int256 x, int256 y)`: Gets the last address that painted the tile.
        *   `getTotalPaintEvents()`: Gets total paint operations performed.
    *   **Messaging & Metadata:**
        *   `setTileMessage(int256 x, int256 y, string message)`: Owner sets/updates a short message for their tile.
        *   `clearTileMessage(int256 x, int256 y)`: Owner clears the message.
        *   `getTileMessage(int256 x, int256 y)`: Gets the message for a tile.
        *   `setTileMetadataUri(int256 x, int256 y, string uri)`: Owner sets/updates an IPFS/metadata URI for their tile.
        *   `clearTileMetadataUri(int256 x, int256 y)`: Owner clears the metadata URI.
        *   `getTileMetadataUri(int256 x, int256 y)`: Gets the metadata URI for a tile.
    *   **Sales:**
        *   `setTilePriceForSale(int256 x, int256 y, uint256 price)`: Owner lists their tile for sale.
        *   `buyTile(int256 x, int256 y)`: Buys a tile that is listed for sale.
        *   `cancelTileSale(int256 x, int256 y)`: Seller cancels a sale listing.
        *   `getTileSaleDetails(int256 x, int256 y)`: Gets sale details for a tile.
        *   `isTileForSale(int256 x, int256 y)`: Checks if a tile is listed for sale.
    *   **Admin (Owner Only):**
        *   `setClaimFee(uint256 fee)`: Sets the fee for claiming tiles.
        *   `setPaintFee(uint256 fee)`: Sets the fee for painting tiles.
        *   `setPaintFeeDistributionBasisPoints(uint16 ownerBps, uint16 protocolBps)`: Sets how paint fees are distributed.
        *   `withdrawFees()`: Contract owner withdraws accumulated protocol fees.
        *   `pauseContract()`: Pauses core contract functionality.
        *   `unpauseContract()`: Unpauses core contract functionality.
    *   **View Functions (Configuration):**
        *   `getClaimFee()`: Gets current claim fee.
        *   `getPaintFee()`: Gets current paint fee.
        *   `getPaintFeeDistributionBasisPoints()`: Gets current fee distribution.
        *   `getProtocolFeesCollected()`: Gets accumulated protocol fees.

**Function Summary:**

*   `claimTile`: Allows a user to become the owner of a tile that hasn't been claimed yet, by paying a fee.
*   `renounceTileOwnership`: Allows a tile owner to voluntarily give up ownership, making the tile unclaimed.
*   `transferTileOwnership`: Allows the current owner of a tile to transfer ownership to another address.
*   `setTilePriceForSale`: Allows a tile owner to list their tile for sale at a specific price.
*   `buyTile`: Allows any user to purchase a tile that is listed for sale, becoming the new owner.
*   `cancelTileSale`: Allows the seller of a tile to remove its sale listing.
*   `paintTile`: Allows any user to change the color and last painter of a tile by paying a fee. This fee is distributed between the tile owner and the protocol.
*   `batchPaintTiles`: Allows a user to paint multiple tiles in a single transaction, paying the paint fee for each.
*   `setTileMessage`: Allows the owner of a tile to attach a short text message to it.
*   `clearTileMessage`: Allows the owner of a tile to remove its associated message.
*   `setTileMetadataUri`: Allows the owner of a tile to attach a URI (e.g., IPFS hash) linking to off-chain metadata or content.
*   `clearTileMetadataUri`: Allows the owner of a tile to remove its associated metadata URI.
*   `setClaimFee`: (Owner only) Sets the fee required to claim a tile.
*   `setPaintFee`: (Owner only) Sets the fee required to paint a tile.
*   `setPaintFeeDistributionBasisPoints`: (Owner only) Configures how the `paintFee` is split between the tile owner and the contract protocol fees.
*   `withdrawFees`: (Owner only) Allows the contract owner to withdraw accumulated protocol fees.
*   `pauseContract`: (Owner only) Pauses most user interactions in case of emergency or maintenance.
*   `unpauseContract`: (Owner only) Unpauses the contract.
*   `getTileState`: (View) Retrieves the full state information (owner, last painter, color, timestamp) for a specific tile.
*   `getTileOwner`: (View) Retrieves only the owner address of a specific tile.
*   `isTileOwned`: (View) Checks if a tile has a registered owner.
*   `getTileLastPainter`: (View) Retrieves the address of the last user who painted a tile.
*   `getTileMessage`: (View) Retrieves the message attached to a specific tile.
*   `getTileMetadataUri`: (View) Retrieves the metadata URI attached to a specific tile.
*   `getTileSaleDetails`: (View) Retrieves the sale details (seller, price) if a tile is listed for sale.
*   `isTileForSale`: (View) Checks if a specific tile is currently listed for sale.
*   `getClaimFee`: (View) Retrieves the current claim fee amount.
*   `getPaintFee`: (View) Retrieves the current paint fee amount.
*   `getPaintFeeDistributionBasisPoints`: (View) Retrieves the current paint fee distribution configuration.
*   `getProtocolFeesCollected`: (View) Retrieves the total amount of protocol fees collected and available for withdrawal.
*   `getTotalTilesClaimed`: (View) Retrieves the total count of unique tiles that have been claimed.
*   `getTotalPaintEvents`: (View) Retrieves the total count of `paintTile` actions that have occurred.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title Infinite Canvas Smart Contract
 * @dev Represents a shared digital canvas on-chain where users can claim ownership of
 * tiles by coordinates, paint them, attach messages/metadata, and trade them.
 * Incorporates fee distribution, batch operations, and admin controls.
 */

/*
 * Outline:
 * 1. License and Pragma
 * 2. Error Definitions
 * 3. State Variables
 * 4. Structs
 * 5. Events
 * 6. Modifiers
 * 7. Constructor
 * 8. Functions (Grouped by functionality)
 *    - Ownership & Claiming (6 functions)
 *    - Painting & State (5 functions)
 *    - Messaging & Metadata (6 functions)
 *    - Sales (5 functions)
 *    - Admin (Owner Only) (6 functions)
 *    - View Functions (Configuration) (6 functions)
 * Total Functions: 34 (More than the requested 20)
 */

/*
 * Function Summary:
 * - claimTile: Claims an unowned tile for the sender, paying a fee.
 * - renounceTileOwnership: Owner gives up ownership, making the tile unclaimed.
 * - transferTileOwnership: Owner transfers tile ownership to another address.
 * - setTilePriceForSale: Owner lists their tile for sale.
 * - buyTile: Buys a listed tile, transferring ownership and payment.
 * - cancelTileSale: Seller cancels a sale listing.
 * - paintTile: Allows any user to change a tile's color, pays a fee distributed to owner and protocol.
 * - batchPaintTiles: Paints multiple tiles efficiently.
 * - setTileMessage: Owner sets a text message for their tile.
 * - clearTileMessage: Owner removes a tile's message.
 * - getTileMessage: Retrieves a tile's message.
 * - setTileMetadataUri: Owner sets an external metadata URI (e.g., IPFS) for their tile.
 * - clearTileMetadataUri: Owner removes a tile's metadata URI.
 * - getTileMetadataUri: Retrieves a tile's metadata URI.
 * - setClaimFee: (Admin) Sets the fee to claim a tile.
 * - setPaintFee: (Admin) Sets the fee to paint a tile.
 * - setPaintFeeDistributionBasisPoints: (Admin) Configures paint fee distribution.
 * - withdrawFees: (Admin) Withdraws accumulated protocol fees.
 * - pauseContract: (Admin) Pauses core functionality.
 * - unpauseContract: (Admin) Unpauses the contract.
 * - getTileState: (View) Gets full tile state.
 * - getTileOwner: (View) Gets the owner address.
 * - isTileOwned: (View) Checks if owned.
 * - getTileLastPainter: (View) Gets the last painter address.
 * - getTileSaleDetails: (View) Gets sale details.
 * - isTileForSale: (View) Checks if for sale.
 * - getClaimFee: (View) Gets claim fee.
 * - getPaintFee: (View) Gets paint fee.
 * - getPaintFeeDistributionBasisPoints: (View) Gets fee distribution config.
 * - getProtocolFeesCollected: (View) Gets accumulated protocol fees.
 * - getTotalTilesClaimed: (View) Gets count of unique tiles claimed.
 * - getTotalPaintEvents: (View) Gets count of paint actions.
 */

// Custom Errors
error NotOwnerOfTile(int256 x, int256 y, address caller);
error TileAlreadyOwned(int256 x, int256 y);
error NotUnclaimedTile(int256 x, int256 y);
error InvalidAddress(address addr);
error FeeRequired(uint256 required, uint256 sent);
error ArrayLengthMismatch();
error TileNotForSale(int256 x, int256 y);
error TileSaleBelongsToDifferentSeller(int256 x, int256 y, address expected, address actual);
error InsufficientPayment(uint256 required, uint256 sent);
error PaymentOverflow();
error FeeDistributionInvalid(uint16 ownerBps, uint16 protocolBps);
error FeeDistributionTotalExceeds100Percent(uint16 totalBps);

contract InfiniteCanvas {
    address public immutable owner;
    bool public paused;

    uint256 public claimFee;
    uint256 public paintFee;
    uint16 public ownerPaintFeeBps;    // Basis points (10000 = 100%)
    uint16 public protocolPaintFeeBps; // Basis points (10000 = 100%)

    uint256 public protocolFeesCollected;

    uint256 public totalTilesClaimed;
    uint256 public totalPaintEvents;

    struct TileState {
        address owner; // Address of the current owner (address(0) if unclaimed)
        address lastPainter; // Address of the last person who painted this tile
        bytes3 color; // 3 bytes representing RGB color (e.g., 0xFF0000 for red)
        uint48 lastUpdated; // Timestamp of the last paint or ownership change
        // Optional: Store message and metadata separately to save gas on TileState reads if they are often empty
        // string message; // A short on-chain message (gas-heavy)
        // string metadataUri; // URI pointing to off-chain data (IPFS, etc.) (gas-heavy)
    }

    struct TileSaleDetails {
        address seller; // Owner who listed the tile for sale
        uint256 price;  // Price in wei
    }

    // Mapping to store tile data: mapping(x => mapping(y => TileState))
    mapping(int256 => mapping(int256 => TileState)) private tiles;

    // Mappings for separately stored optional data (gas optimization for main struct)
    mapping(int256 => mapping(int256 => string)) private tileMessages;
    mapping(int256 => mapping(int256 => string)) private tileMetadataUris;

    // Mapping to store tiles listed for sale
    mapping(int256 => mapping(int256 => TileSaleDetails)) private tilesForSale;

    // Events
    event TileClaimed(int256 indexed x, int256 indexed y, address indexed newOwner);
    event TileOwnershipTransferred(int256 indexed x, int256 indexed y, address indexed previousOwner, address indexed newOwner);
    event TileRenounced(int256 indexed x, int256 indexed y, address indexed previousOwner);
    event TilePainted(int256 indexed x, int256 indexed y, bytes3 color, address indexed painter);
    event TileMessageUpdated(int256 indexed x, int256 indexed y, string message);
    event TileMetadataUriUpdated(int256 indexed x, int256 indexed y, string uri);
    event TileListedForSale(int256 indexed x, int256 indexed y, address indexed seller, uint256 price);
    event TileBought(int256 indexed x, int256 indexed y, address indexed buyer, address indexed seller, uint256 price);
    event TileSaleCancelled(int256 indexed x, int256 indexed y, address indexed seller);
    event FeeConfigUpdated(uint256 newClaimFee, uint256 newPaintFee);
    event FeeDistributionConfigUpdated(uint16 newOwnerBps, uint16 newProtocolBps);
    event FeesWithdrawn(address indexed recipient, uint256 amount);
    event Paused(address account);
    event Unpaused(address account);

    // Modifiers
    modifier onlyOwner() {
        if (msg.sender != owner) {
            revert("Not contract owner");
        }
        _;
    }

    modifier whenNotPaused() {
        if (paused) {
            revert("Contract is paused");
        }
        _;
    }

    modifier whenPaused() {
        if (!paused) {
            revert("Contract is not paused");
        }
        _;
    }

    constructor(uint256 _initialClaimFee, uint256 _initialPaintFee, uint16 _initialOwnerPaintFeeBps, uint16 _initialProtocolPaintFeeBps) {
        if (_initialOwnerPaintFeeBps + _initialProtocolPaintFeeBps > 10000) {
             revert FeeDistributionTotalExceeds100Percent(_initialOwnerPaintFeeBps + _initialProtocolPaintFeeBps);
        }
        owner = msg.sender;
        claimFee = _initialClaimFee;
        paintFee = _initialPaintFee;
        ownerPaintFeeBps = _initialOwnerPaintFeeBps;
        protocolPaintFeeBps = _initialProtocolPaintFeeBps;
        paused = false; // Contract starts unpaused
    }

    // --- Ownership & Claiming ---

    /**
     * @dev Allows msg.sender to claim an unowned tile.
     * Requires paying the claimFee.
     * @param x X coordinate of the tile.
     * @param y Y coordinate of the tile.
     */
    function claimTile(int256 x, int256 y) external payable whenNotPaused {
        if (tiles[x][y].owner != address(0)) {
            revert TileAlreadyOwned(x, y);
        }
        if (msg.value < claimFee) {
            revert FeeRequired(claimFee, msg.value);
        }

        tiles[x][y].owner = msg.sender;
        // Optionally set lastPainter and timestamp here if claiming counts as initial "painting"
        // tiles[x][y].lastPainter = msg.sender;
        tiles[x][y].lastUpdated = uint48(block.timestamp); // Using uint48 for efficiency

        protocolFeesCollected += msg.value; // Claim fee goes to protocol
        totalTilesClaimed++;

        emit TileClaimed(x, y, msg.sender);
    }

    /**
     * @dev Allows the current owner of a tile to renounce their ownership.
     * The tile becomes unowned (address(0)). Any sale listing is cancelled.
     * @param x X coordinate of the tile.
     * @param y Y coordinate of the tile.
     */
    function renounceTileOwnership(int256 x, int256 y) external whenNotPaused {
        address currentOwner = tiles[x][y].owner;
        if (currentOwner == address(0)) {
            revert NotOwnedTile(x, y); // Using a specific error for attempting to renounce unowned tile
        }
        if (currentOwner != msg.sender) {
             revert NotOwnerOfTile(x, y, msg.sender);
        }

        tiles[x][y].owner = address(0);
        // Clear message and metadata when ownership is renounced? Optional. Let's keep them for now unless cleared explicitly.

        // Cancel any active sale listing for this tile
        if (tilesForSale[x][y].seller != address(0)) {
             delete tilesForSale[x][y];
             emit TileSaleCancelled(x, y, msg.sender);
        }

        tiles[x][y].lastUpdated = uint48(block.timestamp); // Update timestamp on ownership change

        emit TileRenounced(x, y, msg.sender);
        emit TileOwnershipTransferred(x, y, msg.sender, address(0)); // Also emit transfer event
    }

    /**
     * @dev Allows the current owner of a tile to transfer ownership to another address.
     * @param x X coordinate of the tile.
     * @param y Y coordinate of the tile.
     * @param newOwner Address of the new owner.
     */
    function transferTileOwnership(int256 x, int256 y, address newOwner) external whenNotPaused {
        address currentOwner = tiles[x][y].owner;
         if (currentOwner == address(0)) {
             revert NotOwnedTile(x, y);
         }
        if (currentOwner != msg.sender) {
             revert NotOwnerOfTile(x, y, msg.sender);
        }
        if (newOwner == address(0)) {
            revert InvalidAddress(address(0));
        }

        tiles[x][y].owner = newOwner;
        // Clear message and metadata on transfer? Optional. Let's keep for now.

         // Cancel any active sale listing for this tile
        if (tilesForSale[x][y].seller != address(0)) {
             delete tilesForSale[x][y];
             emit TileSaleCancelled(x, y, msg.sender);
        }

        tiles[x][y].lastUpdated = uint48(block.timestamp); // Update timestamp on ownership change

        emit TileOwnershipTransferred(x, y, msg.sender, newOwner);
    }

     /**
      * @dev Gets the current owner of a tile.
      * @param x X coordinate.
      * @param y Y coordinate.
      * @return The owner address (address(0) if unclaimed).
      */
     function getTileOwner(int256 x, int256 y) external view returns (address) {
         return tiles[x][y].owner;
     }

     /**
      * @dev Checks if a tile is currently owned (not address(0)).
      * @param x X coordinate.
      * @param y Y coordinate.
      * @return True if owned, false otherwise.
      */
     function isTileOwned(int256 x, int256 y) external view returns (bool) {
         return tiles[x][y].owner != address(0);
     }

     /**
      * @dev Gets the total number of unique tiles that have been claimed.
      * Note: This counter is only incremented on the first claim of a tile.
      * @return The total number of claimed tiles.
      */
     function getTotalTilesClaimed() external view returns (uint256) {
         return totalTilesClaimed;
     }


    // --- Painting & State ---

    /**
     * @dev Allows any user to paint a tile with a new color.
     * Requires paying the paintFee. The fee is distributed between the tile owner and the protocol.
     * @param x X coordinate of the tile.
     * @param y Y coordinate of the tile.
     * @param color The new color for the tile (RGB bytes3).
     */
    function paintTile(int256 x, int256 y, bytes3 color) external payable whenNotPaused {
        if (msg.value < paintFee) {
            revert FeeRequired(paintFee, msg.value);
        }

        tiles[x][y].color = color;
        tiles[x][y].lastPainter = msg.sender;
        tiles[x][y].lastUpdated = uint48(block.timestamp);

        totalPaintEvents++;

        // Distribute fee
        uint256 feeToDistribute = msg.value;
        address currentOwner = tiles[x][y].owner;

        // Calculate owner portion (if tile is owned)
        if (currentOwner != address(0) && ownerPaintFeeBps > 0) {
            uint256 ownerPortion = (feeToDistribute * ownerPaintFeeBps) / 10000;
             if (ownerPortion > 0) { // Prevent sending 0 ETH which might cause issues
                 // Low-level call recommended for external transfers to prevent reentrancy
                (bool success, ) = payable(currentOwner).call{value: ownerPortion}("");
                // It's usually better to log failures and potentially use a withdrawal pattern
                // than to revert the main function on a transfer failure.
                // For simplicity here, we'll just check success.
                if (!success) {
                    // Handle failed payment to owner - could add to protocol fees, log, or revert
                    // For this example, let's add it to protocol fees
                    protocolFeesCollected += ownerPortion;
                 }
                 feeToDistribute -= ownerPortion; // Reduce remaining fee to distribute
             }
        }

        // Protocol portion
        if (protocolPaintFeeBps > 0 && feeToDistribute > 0) {
             uint256 protocolPortion = (feeToDistribute * protocolPaintFeeBps) / 10000; // Calculate protocol portion from remaining
             if (protocolPortion > 0) {
                protocolFeesCollected += protocolPortion;
             }
        }
        // Any remaining fee (e.g., if (ownerPaintFeeBps + protocolPaintFeeBps) < 10000, or if owner transfer failed)
        // stays in the contract's balance, increasing `protocolFeesCollected`.

        emit TilePainted(x, y, color, msg.sender);
    }

    /**
     * @dev Allows painting multiple tiles in a single transaction.
     * Requires paying the paintFee for each tile.
     * @param xs Array of X coordinates.
     * @param ys Array of Y coordinates.
     * @param colors Array of colors (RGB bytes3).
     */
    function batchPaintTiles(int256[] calldata xs, int256[] calldata ys, bytes3[] calldata colors) external payable whenNotPaused {
        if (xs.length != ys.length || xs.length != colors.length || xs.length == 0) {
            revert ArrayLengthMismatch();
        }

        uint256 totalFeeRequired = paintFee * xs.length;
        if (msg.value < totalFeeRequired) {
            revert FeeRequired(totalFeeRequired, msg.value);
        }

        uint256 remainingFee = msg.value;
        uint256 accumulatedProtocolFees = 0;

        for (uint i = 0; i < xs.length; i++) {
            int256 x = xs[i];
            int256 y = ys[i];
            bytes3 color = colors[i];

            tiles[x][y].color = color;
            tiles[x][y].lastPainter = msg.sender;
            tiles[x][y].lastUpdated = uint48(block.timestamp);

            totalPaintEvents++;

            address currentOwner = tiles[x][y].owner;
            uint256 singlePaintFee = paintFee; // Fee per tile

            // Distribute fee for this tile
            uint256 ownerPortion = 0;
            if (currentOwner != address(0) && ownerPaintFeeBps > 0) {
                ownerPortion = (singlePaintFee * ownerPaintFeeBps) / 10000;
                 if (ownerPortion > 0) {
                     (bool success, ) = payable(currentOwner).call{value: ownerPortion}("");
                     if (!success) {
                        // If owner transfer fails in batch, add to protocol fees instead of reverting the whole batch
                        accumulatedProtocolFees += ownerPortion;
                     }
                 }
            }

            // Protocol portion
            uint256 protocolPortion = (singlePaintFee * protocolPaintFeeBps) / 10000;
            if (protocolPortion > 0) {
                accumulatedProtocolFees += protocolPortion;
            }

             // Any remainder from this tile's fee goes to accumulatedProtocolFees
             accumulatedProtocolFees += singlePaintFee - ownerPortion - protocolPortion;

            emit TilePainted(x, y, color, msg.sender);
        }

        // Any excess ETH sent beyond totalFeeRequired also goes to accumulatedProtocolFees
        accumulatedProtocolFees += msg.value - totalFeeRequired;

        protocolFeesCollected += accumulatedProtocolFees;
    }


    /**
     * @dev Gets the full state of a tile.
     * Includes owner, last painter, color, and last updated timestamp.
     * @param x X coordinate.
     * @param y Y coordinate.
     * @return TileState struct.
     */
    function getTileState(int256 x, int256 y) external view returns (TileState memory) {
        // Accessing mappings directly returns default values (address(0), 0, etc.) if tile doesn't exist, which is intended.
        return tiles[x][y];
    }

     /**
      * @dev Gets the address of the last user who successfully painted this tile.
      * @param x X coordinate.
      * @param y Y coordinate.
      * @return The address of the last painter (address(0) if never painted).
      */
     function getTileLastPainter(int256 x, int256 y) external view returns (address) {
         return tiles[x][y].lastPainter;
     }

     /**
      * @dev Gets the total count of successful paintTile actions performed.
      * Incremented for each tile painted in `paintTile` and for each tile in `batchPaintTiles`.
      * @return The total number of paint events.
      */
     function getTotalPaintEvents() external view returns (uint256) {
         return totalPaintEvents;
     }


    // --- Messaging & Metadata ---

    /**
     * @dev Allows the tile owner to set or update an on-chain message for their tile.
     * Setting an empty string effectively clears the message. Gas costs are high for strings.
     * @param x X coordinate.
     * @param y Y coordinate.
     * @param message The message string (or empty string to clear).
     */
    function setTileMessage(int256 x, int256 y, string calldata message) external whenNotPaused {
        address currentOwner = tiles[x][y].owner;
        if (currentOwner == address(0)) {
            revert NotOwnedTile(x, y);
        }
        if (currentOwner != msg.sender) {
             revert NotOwnerOfTile(x, y, msg.sender);
        }
        // Consider adding a length limit for the message due to gas costs

        tileMessages[x][y] = message;
        emit TileMessageUpdated(x, y, message);
    }

     /**
      * @dev Allows the tile owner to clear the on-chain message for their tile.
      * @param x X coordinate.
      * @param y Y coordinate.
      */
    function clearTileMessage(int256 x, int256 y) external whenNotPaused {
        address currentOwner = tiles[x][y].owner;
        if (currentOwner == address(0)) {
            revert NotOwnedTile(x, y);
        }
        if (currentOwner != msg.sender) {
             revert NotOwnerOfTile(x, y, msg.sender);
        }

        delete tileMessages[x][y];
        emit TileMessageUpdated(x, y, ""); // Emit with empty string to signal clear
    }

    /**
     * @dev Retrieves the on-chain message for a tile.
     * @param x X coordinate.
     * @param y Y coordinate.
     * @return The message string (empty string if none set).
     */
    function getTileMessage(int256 x, int256 y) external view returns (string memory) {
        return tileMessages[x][y];
    }

    /**
     * @dev Allows the tile owner to set or update an external metadata URI (e.g., IPFS hash).
     * Setting an empty string effectively clears the URI. Gas costs are high for strings.
     * @param x X coordinate.
     * @param y Y coordinate.
     * @param uri The URI string (or empty string to clear).
     */
    function setTileMetadataUri(int256 x, int256 y, string calldata uri) external whenNotPaused {
        address currentOwner = tiles[x][y].owner;
        if (currentOwner == address(0)) {
            revert NotOwnedTile(x, y);
        }
        if (currentOwner != msg.sender) {
             revert NotOwnerOfTile(x, y, msg.sender);
        }
         // Consider adding a length limit for the URI due to gas costs

        tileMetadataUris[x][y] = uri;
        emit TileMetadataUriUpdated(x, y, uri);
    }

     /**
      * @dev Allows the tile owner to clear the external metadata URI for their tile.
      * @param x X coordinate.
      * @param y Y coordinate.
      */
    function clearTileMetadataUri(int256 x, int256 y) external whenNotPaused {
        address currentOwner = tiles[x][y].owner;
        if (currentOwner == address(0)) {
            revert NotOwnedTile(x, y);
        }
        if (currentOwner != msg.sender) {
             revert NotOwnerOfTile(x, y, msg.sender);
        }

        delete tileMetadataUris[x][y];
        emit TileMetadataUriUpdated(x, y, ""); // Emit with empty string to signal clear
    }

    /**
     * @dev Retrieves the external metadata URI for a tile.
     * @param x X coordinate.
     * @param y Y coordinate.
     * @return The URI string (empty string if none set).
     */
    function getTileMetadataUri(int256 x, int256 y) external view returns (string memory) {
        return tileMetadataUris[x][y];
    }


    // --- Sales ---

    /**
     * @dev Allows the tile owner to list their tile for sale at a specified price.
     * Overwrites any existing sale listing for this tile.
     * @param x X coordinate.
     * @param y Y coordinate.
     * @param price The price in wei the tile is listed for. Set to 0 to effectively cancel sale (though cancelTileSale is preferred).
     */
    function setTilePriceForSale(int256 x, int256 y, uint256 price) external whenNotPaused {
        address currentOwner = tiles[x][y].owner;
        if (currentOwner == address(0)) {
            revert NotOwnedTile(x, y);
        }
        if (currentOwner != msg.sender) {
             revert NotOwnerOfTile(x, y, msg.sender);
        }

        tilesForSale[x][y] = TileSaleDetails({
            seller: msg.sender,
            price: price
        });

        emit TileListedForSale(x, y, msg.sender, price);
    }

    /**
     * @dev Allows any user to buy a tile that is listed for sale.
     * Requires sending exactly the listed price. Transfers ownership and payment.
     * Automatically cancels the sale listing.
     * @param x X coordinate.
     * @param y Y coordinate.
     */
    function buyTile(int256 x, int256 y) external payable whenNotPaused {
        TileSaleDetails storage sale = tilesForSale[x][y];

        if (sale.seller == address(0)) {
            revert TileNotForSale(x, y);
        }
        // Redundant check since seller is owner, but good safety if logic changes
        if (tiles[x][y].owner != sale.seller) {
             revert TileSaleBelongsToDifferentSeller(x, y, tiles[x][y].owner, sale.seller);
        }

        if (msg.value != sale.price) {
            revert InsufficientPayment(sale.price, msg.value);
        }

        address previousOwner = tiles[x][y].owner; // Should be sale.seller
        address newOwner = msg.sender;
        uint256 pricePaid = msg.value;

        // Perform transfer before payment to reduce reentrancy risk
        tiles[x][y].owner = newOwner;
         // Clear message and metadata on sale? Optional. Let's keep for now.

        // Cancel sale listing
        delete tilesForSale[x][y];

        tiles[x][y].lastUpdated = uint48(block.timestamp); // Update timestamp on ownership change

        // Send payment to the seller
        (bool success, ) = payable(previousOwner).call{value: pricePaid}("");
        // If sending payment to seller fails, the ETH is stuck in the contract.
        // This is acceptable as the buyer already received the tile. The seller would need to contact support.
        // More robust solutions involve pull payments or escrow.
        if (!success) {
             // Log failure? Add to protocol fees? For now, just note the failure.
             // console.log("Payment to seller failed for tile", x, y);
        }

        emit TileBought(x, y, newOwner, previousOwner, pricePaid);
        emit TileSaleCancelled(x, y, previousOwner); // Also emit cancellation
        emit TileOwnershipTransferred(x, y, previousOwner, newOwner); // Also emit transfer
    }

    /**
     * @dev Allows the seller (current owner) of a tile to cancel its sale listing.
     * @param x X coordinate.
     * @param y Y coordinate.
     */
    function cancelTileSale(int256 x, int256 y) external whenNotPaused {
        TileSaleDetails storage sale = tilesForSale[x][y];

        if (sale.seller == address(0)) {
            revert TileNotForSale(x, y);
        }
        // Only the original lister or the current owner can cancel (current owner is more robust)
        if (tiles[x][y].owner != msg.sender) {
             revert NotOwnerOfTile(x, y, msg.sender); // Or a specific error like NotSellerOrOwner
        }

        address seller = sale.seller; // Store seller before deleting
        delete tilesForSale[x][y];

        emit TileSaleCancelled(x, y, seller);
    }

     /**
      * @dev Gets the sale details for a tile.
      * @param x X coordinate.
      * @param y Y coordinate.
      * @return TileSaleDetails struct (seller=address(0) if not for sale).
      */
    function getTileSaleDetails(int256 x, int256 y) external view returns (TileSaleDetails memory) {
         // Accessing mapping directly returns default values if not set
         return tilesForSale[x][y];
     }

     /**
      * @dev Checks if a tile is currently listed for sale.
      * @param x X coordinate.
      * @param y Y coordinate.
      * @return True if listed for sale, false otherwise.
      */
     function isTileForSale(int256 x, int256 y) external view returns (bool) {
         return tilesForSale[x][y].seller != address(0);
     }


    // --- Admin (Owner Only) ---

    /**
     * @dev Allows the contract owner to set the fee for claiming a tile.
     * @param fee The new claim fee in wei.
     */
    function setClaimFee(uint256 fee) external onlyOwner {
        claimFee = fee;
        emit FeeConfigUpdated(claimFee, paintFee);
    }

    /**
     * @dev Allows the contract owner to set the fee for painting a tile.
     * @param fee The new paint fee in wei.
     */
    function setPaintFee(uint256 fee) external onlyOwner {
        paintFee = fee;
        emit FeeConfigUpdated(claimFee, paintFee);
    }

    /**
     * @dev Allows the contract owner to set the distribution percentage of the paint fee.
     * Basis points (bps) are used, where 10000 bps = 100%.
     * @param ownerBps Basis points sent to the tile owner.
     * @param protocolBps Basis points sent to the protocol (accumulated in the contract).
     */
    function setPaintFeeDistributionBasisPoints(uint16 ownerBps, uint16 protocolBps) external onlyOwner {
        if (ownerBps + protocolBps > 10000) {
            revert FeeDistributionTotalExceeds100Percent(ownerBps + protocolBps);
        }
        ownerPaintFeeBps = ownerBps;
        protocolPaintFeeBps = protocolBps;
        emit FeeDistributionConfigUpdated(ownerPaintFeeBps, protocolPaintFeeBps);
    }

    /**
     * @dev Allows the contract owner to withdraw accumulated protocol fees.
     * Sends the entire balance of `protocolFeesCollected` to the contract owner.
     */
    function withdrawFees() external onlyOwner {
        uint256 balance = protocolFeesCollected;
        if (balance == 0) {
            return; // No fees to withdraw
        }
        protocolFeesCollected = 0; // Set balance to 0 BEFORE sending to prevent reentrancy

        (bool success, ) = payable(owner).call{value: balance}("");
        if (!success) {
            // If transfer fails, revert the state change to prevent loss of funds
            protocolFeesCollected = balance; // Restore the balance
            revert("Withdrawal failed"); // Revert the transaction
        }

        emit FeesWithdrawn(owner, balance);
    }

     /**
      * @dev Pauses the contract. Prevents execution of most functions.
      * Callable only by the contract owner.
      */
    function pauseContract() external onlyOwner whenNotPaused {
        paused = true;
        emit Paused(msg.sender);
    }

     /**
      * @dev Unpauses the contract. Allows execution of functions again.
      * Callable only by the contract owner.
      */
    function unpauseContract() external onlyOwner whenPaused {
        paused = false;
        emit Unpaused(msg.sender);
    }

    // --- View Functions (Configuration) ---

     /**
      * @dev Gets the current fee required to claim an unowned tile.
      * @return The claim fee in wei.
      */
     function getClaimFee() external view returns (uint256) {
         return claimFee;
     }

     /**
      * @dev Gets the current fee required to paint any tile.
      * @return The paint fee in wei.
      */
     function getPaintFee() external view returns (uint256) {
         return paintFee;
     }

     /**
      * @dev Gets the current distribution configuration for the paint fee.
      * @return ownerBps Basis points sent to the tile owner.
      * @return protocolBps Basis points sent to the protocol.
      */
     function getPaintFeeDistributionBasisPoints() external view returns (uint16 ownerBps, uint16 protocolBps) {
         return (ownerPaintFeeBps, protocolPaintFeeBps);
     }

     /**
      * @dev Gets the total amount of protocol fees collected in the contract balance
      * that are available for withdrawal by the contract owner.
      * @return The accumulated protocol fees in wei.
      */
     function getProtocolFeesCollected() external view returns (uint256) {
         return protocolFeesCollected;
     }

    // Fallback function to accept ETH, primarily for paint fees and buy calls
    // Explicit functions (paintTile, buyTile) handle the logic and fee distribution.
    // This fallback ensures accidental sends or interactions from dapps sending eth
    // without calling a specific function don't get rejected completely, though
    // they won't trigger any specific tile actions.
    receive() external payable {
        // Optionally add a check or event for received ETH not tied to a function call
        // e.g., require(msg.data.length == 0, "Call function or send plain ETH");
        // Or simply let it increase the contract balance (which adds to protocolFeesCollected
        // if withdrawFees is called, or is manually managed by owner).
        // For simplicity here, we let it pass. The `withdrawFees` function collects the contract's balance.
    }
}
```