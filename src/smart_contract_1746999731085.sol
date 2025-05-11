Okay, here is a Solidity smart contract called `InfiniteCanvas`. It represents a theoretically infinite 2D grid where users can claim and own rectangular "tiles". These tiles are dynamic, have customizable properties, require fuel to exist and be modified, and can be traded. It incorporates concepts like programmable permissions, on-chain state evolution, a simple marketplace, and hooks for off-chain rendering and interaction logic.

It aims to be creative and avoid direct duplication by combining spatial ownership, dynamic data, maintenance mechanics (fuel), and owner-controlled modification permissions/fees within a single contract structure, distinct from standard NFT or simple land contracts.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol"; // Just for interface awareness, not fully ERC721 compliant structure

/**
 * @title InfiniteCanvas
 * @dev A smart contract representing a dynamic, collaborative, and theoretically infinite 2D canvas
 *      composed of claimable, ownable, and programmable tiles.
 *
 * Outline:
 * 1. State Variables: Core contract state, tile data, ownership, marketplace, configurations.
 * 2. Structs & Enums: Definitions for Tile data, Sale listings, Fuel configuration, and Permissions.
 * 3. Events: Emissions for key state changes.
 * 4. Modifiers: Custom access control and state checks.
 * 5. Constructor: Initialization of the contract owner and initial settings.
 * 6. Tile Management (Claiming & Core): Functions for claiming new regions and checking overlaps.
 * 7. Tile Ownership & Transfer: Standard ownership transfer functions (ERC721-like).
 * 8. Tile Data & State Modification: Functions for owners/permitted users to change tile data and settings.
 * 9. Tile Fuel & Maintenance: Functions to add fuel and configuration.
 * 10. Marketplace: Functions to list, buy, cancel, and update tile sales.
 * 11. Query & View Functions: Functions to retrieve tile data, ownership, and market listings.
 * 12. Advanced/Configuration: Functions for setting contract-wide parameters, pausing, and withdrawal.
 * 13. Internal Helper Functions: Logic reused within the contract (e.g., overlap check, fuel drain).
 *
 * Function Summary:
 * - constructor(): Initializes the contract owner and default parameters.
 * - claimTile(): Allows a user to claim a new, non-overlapping tile region for a price.
 * - transferTile(): Transfers ownership of a tile to another address.
 * - approveTileTransfer(): Approves an address to transfer a specific tile on behalf of the owner.
 * - transferTileFrom(): Transfers a tile from one address to another using a prior approval.
 * - modifyTileData(): Allows the tile owner or an approved modifier to change the tile's data, consuming fuel.
 * - setModificationPermissions(): Allows the tile owner to set who can modify their tile data and under what conditions.
 * - setModificationFee(): Allows the tile owner to set the fee required for modification if permissions are set accordingly.
 * - addApprovedModifier(): Allows the tile owner to add an address to the list of approved modifiers for their tile.
 * - removeApprovedModifier(): Allows the tile owner to remove an address from the approved modifiers list.
 * - addFuel(): Allows anyone to add fuel to a specific tile, potentially extending its lifespan or modification capacity.
 * - setFuelConfig(): Allows the contract owner to configure fuel consumption rates and costs.
 * - listTileForSale(): Allows a tile owner to list their tile for sale at a specified price.
 * - buyTile(): Allows a user to buy a listed tile, transferring ownership and funds.
 * - cancelListing(): Allows a tile owner to cancel an active sale listing for their tile.
 * - setListingPrice(): Allows a tile owner to change the price of an active sale listing.
 * - getTile(): Retrieves all detailed data for a specific tile ID.
 * - getTilesByOwner(): Retrieves an array of tile IDs owned by a given address.
 * - getTotalSupply(): Returns the total number of tiles ever claimed.
 * - isOverlapping(): A view function to check if a given coordinate region overlaps with any existing tile.
 * - getTileAtCoordinate(): A view function to find the ID of a tile (if any) that contains a specific coordinate.
 * - getTilesInRegion(): A view function to find IDs of tiles that intersect with a given bounding box. (Potentially gas-heavy)
 * - setClaimPrice(): Allows the contract owner to set the price for claiming a new tile.
 * - renounceOwnership(): Allows the contract owner to renounce ownership (from Ownable).
 * - pause(): Allows the contract owner to pause the contract (from Pausable).
 * - unpause(): Allows the contract owner to unpause the contract (from Pausable).
 * - withdrawFees(): Allows the contract owner to withdraw collected fees from tile claims, modifications, and sales.
 * - setAdjacentInteractionRule(): Allows a tile owner to set arbitrary bytes representing a rule for how their tile interacts with neighbors (logic interpreted off-chain).
 * - triggerAdjacentInteraction(): Allows anyone to trigger an event signaling off-chain renderers/logic to process adjacency rules for a tile and its neighbors (pays gas for event).
 * - getListing(): Retrieves the sale details for a specific tile ID.
 * - getApproved(): Retrieves the address approved to transfer a specific tile (ERC721-like).
 */

contract InfiniteCanvas is Ownable, Pausable {

    // --- 1. State Variables ---

    uint256 private _tileIdCounter; // Counter for unique tile IDs
    mapping(uint256 => Tile) public tiles; // Maps tile ID to Tile struct
    mapping(address => uint256[]) private _ownerTiles; // Maps owner address to array of tile IDs
    mapping(uint256 => TileSale) public tileSales; // Maps tile ID to Sale struct for marketplace
    mapping(uint256 => address) private _tileApprovals; // Maps tile ID to approved address (ERC721-like)

    uint256 public claimPrice; // Price in wei to claim a new tile
    uint256 public totalFeesCollected; // Total fees accumulated in the contract

    // Configuration for fuel mechanics
    FuelConfig public fuelConfig;

    // Store bytes representing adjacency rules per tile (interpreted off-chain)
    mapping(uint256 => bytes) public adjacentInteractionRules;


    // --- 2. Structs & Enums ---

    enum ModificationPermission {
        OwnerOnly,
        AnyoneFree,
        AnyonePaid,
        ApprovedOnly,
        ApprovedOrPaid
    }

    struct Tile {
        uint256 id;
        address owner;
        int128 x1; // Coordinates (can be negative for infinite concept)
        int128 y1;
        int128 x2; // x2 must be > x1, y2 must be > y1
        int128 y2;
        bytes data; // Programmable data (color, text, metadata hash, etc.)
        uint64 creationTime; // Timestamp of creation
        uint64 lastModifiedTime; // Timestamp of last data modification
        uint256 fuel; // Current fuel level
        ModificationPermission modificationPermissions; // Who can modify
        uint256 modificationFee; // Fee to modify if required
        mapping(address => bool) approvedModifiers; // List for ApprovedOnly/ApprovedOrPaid
    }

    struct TileSale {
        bool isListed;
        uint256 price;
        address seller; // Store seller to handle potential ownership changes while listed
    }

    struct FuelConfig {
        uint256 fuelPerWei; // How much fuel 1 wei buys
        uint256 claimFuelCost; // Fuel cost to claim a tile
        uint256 modifyFuelCost; // Fuel cost per modification
        uint256 fuelDrainPerSecond; // Fuel drained per tile per second (conceptually, calculated based on time delta)
    }

    // --- 3. Events ---

    event TileClaimed(uint256 indexed tileId, address indexed owner, int128 x1, int128 y1, int128 x2, int128 y2, uint256 initialFuel);
    event TileTransferred(uint256 indexed tileId, address indexed from, address indexed to);
    event TileModified(uint256 indexed tileId, address indexed modifier, bytes newData, uint256 fuelConsumed);
    event TileFuelAdded(uint256 indexed tileId, address indexed sender, uint256 amount);
    event TileListed(uint256 indexed tileId, address indexed seller, uint256 price);
    event TileBought(uint256 indexed tileId, address indexed buyer, uint256 price);
    event TileListingCancelled(uint256 indexed tileId);
    event TileListingPriceUpdated(uint256 indexed tileId, uint256 newPrice);
    event ModificationPermissionsUpdated(uint256 indexed tileId, ModificationPermission newPermissions);
    event ModificationFeeUpdated(uint256 indexed tileId, uint256 newFee);
    event ApprovedModifierAdded(uint256 indexed tileId, address indexed modifierAddress);
    event ApprovedModifierRemoved(uint256 indexed tileId, address indexed modifierAddress);
    event AdjacentInteractionRuleSet(uint256 indexed tileId, bytes rule);
    event AdjacentInteractionTriggered(uint256 indexed tileId, address indexed trigger, bytes rule, uint256[] neighborTileIds); // Event to signal off-chain logic
    event FuelConfigUpdated(FuelConfig newConfig);
    event ClaimPriceUpdated(uint256 newPrice);
    event FeesWithdrawn(address indexed recipient, uint256 amount);

    // --- 4. Modifiers ---

    modifier onlyTileOwner(uint256 tileId) {
        require(tiles[tileId].owner == msg.sender, "InfiniteCanvas: Sender is not tile owner");
        _;
    }

    modifier onlyApprovedModifierOrOwner(uint256 tileId) {
        Tile storage tile = tiles[tileId];
        bool isOwner = tile.owner == msg.sender;
        bool isApproved = tile.approvedModifiers[msg.sender];
        require(isOwner || isApproved, "InfiniteCanvas: Not owner or approved modifier");
        _;
    }

    modifier whenTileExists(uint256 tileId) {
        require(tiles[tileId].owner != address(0), "InfiniteCanvas: Tile does not exist");
        _;
    }


    // --- 5. Constructor ---

    constructor(uint256 _initialClaimPrice, FuelConfig memory _initialFuelConfig) Ownable(msg.sender) Pausable(false) {
        claimPrice = _initialClaimPrice;
        fuelConfig = _initialFuelConfig;
        _tileIdCounter = 0;
    }

    // --- 6. Tile Management (Claiming & Core) ---

    /**
     * @dev Allows a user to claim a new, non-overlapping rectangular region on the canvas.
     * The coordinates are inclusive bounds. x2 must be >= x1 and y2 >= y1.
     * Pays the `claimPrice` and consumes `claimFuelCost`.
     * @param x1 The minimum x-coordinate.
     * @param y1 The minimum y-coordinate.
     * @param x2 The maximum x-coordinate.
     * @param y2 The maximum y-coordinate.
     */
    function claimTile(int128 x1, int128 y1, int128 x2, int128 y2) public payable whenNotPaused returns (uint256 newTileId) {
        require(x1 <= x2 && y1 <= y2, "InfiniteCanvas: Invalid coordinates");
        require(msg.value >= claimPrice, "InfiniteCanvas: Insufficient claim price");
        require(!_isOverlapping(x1, y1, x2, y2), "InfiniteCanvas: Claimed region overlaps with existing tile");
        require(fuelConfig.claimFuelCost > 0, "InfiniteCanvas: Claim fuel cost must be > 0"); // Must cost fuel to claim

        uint256 requiredFuel = fuelConfig.claimFuelCost;
        uint256 paidFuel = msg.value * fuelConfig.fuelPerWei; // Fuel gained from excess payment
        uint256 initialFuel = paidFuel >= requiredFuel ? paidFuel - requiredFuel : 0; // Consume claim cost first

        _tileIdCounter++;
        newTileId = _tileIdCounter;

        tiles[newTileId] = Tile({
            id: newTileId,
            owner: msg.sender,
            x1: x1,
            y1: y1,
            x2: x2,
            y2: y2,
            data: "", // Initially empty data
            creationTime: uint64(block.timestamp),
            lastModifiedTime: uint64(block.timestamp),
            fuel: initialFuel,
            modificationPermissions: ModificationPermission.OwnerOnly, // Default permission
            modificationFee: 0
        });

        _ownerTiles[msg.sender].push(newTileId);

        // Collect claim price + any extra payment not converted to fuel
        uint256 excessPayment = msg.value - (initialFuel / fuelConfig.fuelPerWei);
        totalFeesCollected += excessPayment;

        emit TileClaimed(newTileId, msg.sender, x1, y1, x2, y2, initialFuel);
    }

    // --- 7. Tile Ownership & Transfer ---

    /**
     * @dev Transfers ownership of a tile.
     * @param to The address to transfer ownership to.
     * @param tileId The ID of the tile to transfer.
     */
    function transferTile(address to, uint256 tileId) public virtual whenTileExists(tileId) whenNotPaused onlyTileOwner(tileId) {
        require(to != address(0), "InfiniteCanvas: transfer to the zero address");

        _transfer(msg.sender, to, tileId);
    }

    /**
     * @dev Approves another address to transfer a tile.
     * @param to The address to approve.
     * @param tileId The ID of the tile to approve.
     */
    function approveTileTransfer(address to, uint256 tileId) public virtual whenTileExists(tileId) whenNotPaused onlyTileOwner(tileId) {
        _approve(to, tileId);
    }

    /**
     * @dev Transfers ownership of a tile from one address to another, using an approval.
     * @param from The current owner of the tile.
     * @param to The address to transfer ownership to.
     * @param tileId The ID of the tile to transfer.
     */
    function transferTileFrom(address from, address to, uint256 tileId) public virtual whenTileExists(tileId) whenNotPaused {
        require(_isApprovedOrOwner(_msgSender(), tileId), "InfiniteCanvas: transfer caller is not owner nor approved");
        require(from == tiles[tileId].owner, "InfiniteCanvas: from address is not tile owner");
        require(to != address(0), "InfiniteCanvas: transfer to the zero address");

        _transfer(from, to, tileId);
    }

    // ERC721-like helper for approval check
    function _isApprovedOrOwner(address spender, uint256 tileId) internal view returns (bool) {
        address owner = tiles[tileId].owner;
        return (spender == owner || getApproved(tileId) == spender);
    }

    // ERC721-like helper for approval
    function _approve(address to, uint256 tileId) internal {
        _tileApprovals[tileId] = to;
        // emit Approval(tiles[tileId].owner, to, tileId); // Could add custom Approval event
    }

    // Internal transfer logic
    function _transfer(address from, address to, uint256 tileId) internal {
        require(tiles[tileId].owner == from, "InfiniteCanvas: Transfer from wrong owner");

        // Remove from old owner's list (simplified: could be inefficient for large arrays)
        // A linked list mapping or a more complex structure would be better for production
        uint256[] storage ownerTilesList = _ownerTiles[from];
        for (uint i = 0; i < ownerTilesList.length; i++) {
            if (ownerTilesList[i] == tileId) {
                ownerTilesList[i] = ownerTilesList[ownerTilesList.length - 1];
                ownerTilesList.pop();
                break;
            }
        }

        // Clear any active listing and approval
        delete tileSales[tileId];
        delete _tileApprovals[tileId]; // Clear approval on transfer

        // Update tile owner
        tiles[tileId].owner = to;

        // Add to new owner's list (simplified)
        _ownerTiles[to].push(tileId);

        emit TileTransferred(tileId, from, to);
    }


    // --- 8. Tile Data & State Modification ---

    /**
     * @dev Allows modification of tile data based on configured permissions and fuel.
     * Consumes `modifyFuelCost` and potentially requires payment based on permissions.
     * @param tileId The ID of the tile to modify.
     * @param newData The new byte data for the tile.
     */
    function modifyTileData(uint256 tileId, bytes calldata newData) public payable whenTileExists(tileId) whenNotPaused {
        Tile storage tile = tiles[tileId];

        // Check permissions and handle payment
        bool canModify = false;
        uint256 requiredPayment = 0;

        if (msg.sender == tile.owner) {
            canModify = true; // Owner can always modify (subject to fuel)
        } else {
            ModificationPermission perms = tile.modificationPermissions;
            bool isApproved = tile.approvedModifiers[msg.sender];

            if (perms == ModificationPermission.AnyoneFree) {
                canModify = true;
            } else if (perms == ModificationPermission.AnyonePaid) {
                canModify = true;
                requiredPayment = tile.modificationFee;
            } else if (perms == ModificationPermission.ApprovedOnly) {
                canModify = isApproved;
            } else if (perms == ModificationPermission.ApprovedOrPaid) {
                canModify = isApproved || msg.value >= tile.modificationFee;
                if (!isApproved && msg.value >= tile.modificationFee) {
                    requiredPayment = tile.modificationFee;
                }
            }
            // OwnerOnly case already handled by the initial 'if'
        }

        require(canModify, "InfiniteCanvas: Caller does not have permission to modify this tile");

        // Handle required payment
        if (requiredPayment > 0) {
            require(msg.value >= requiredPayment, "InfiniteCanvas: Insufficient payment for modification");
            if (requiredPayment > 0) {
                 // Send payment to tile owner (assuming tile owner configured the fee)
                (bool success, ) = payable(tile.owner).call{value: requiredPayment}("");
                require(success, "InfiniteCanvas: Payment to tile owner failed");
            }
            // Any excess payment is not currently handled (sent back to sender by default)
        } else {
            // If no payment is required, ensure no payment was sent accidentally
            require(msg.value == 0, "InfiniteCanvas: Payment sent but not required for this modification");
        }


        // Check and consume fuel
        uint256 fuelCost = fuelConfig.modifyFuelCost;
        require(tile.fuel >= fuelCost, "InfiniteCanvas: Not enough fuel to modify tile");
        _drainFuel(tileId, fuelCost); // Consume fuel for modification

        // Update tile data and timestamp
        tile.data = newData;
        tile.lastModifiedTime = uint64(block.timestamp);

        emit TileModified(tileId, msg.sender, newData, fuelCost);
    }

    /**
     * @dev Allows the tile owner to set modification permissions for their tile.
     * @param tileId The ID of the tile.
     * @param newPermissions The new modification permissions.
     */
    function setModificationPermissions(uint256 tileId, ModificationPermission newPermissions) public whenTileExists(tileId) whenNotPaused onlyTileOwner(tileId) {
        tiles[tileId].modificationPermissions = newPermissions;
        emit ModificationPermissionsUpdated(tileId, newPermissions);
    }

    /**
     * @dev Allows the tile owner to set the modification fee if permissions require payment.
     * @param tileId The ID of the tile.
     * @param newFee The new modification fee in wei.
     */
    function setModificationFee(uint256 tileId, uint256 newFee) public whenTileExists(tileId) whenNotPaused onlyTileOwner(tileId) {
        tiles[tileId].modificationFee = newFee;
        emit ModificationFeeUpdated(tileId, newFee);
    }

    /**
     * @dev Allows the tile owner to add an address to the approved modifiers list.
     * @param tileId The ID of the tile.
     * @param modifierAddress The address to approve.
     */
    function addApprovedModifier(uint256 tileId, address modifierAddress) public whenTileExists(tileId) whenNotPaused onlyTileOwner(tileId) {
        require(modifierAddress != address(0), "InfiniteCanvas: Cannot approve zero address");
        tiles[tileId].approvedModifiers[modifierAddress] = true;
        emit ApprovedModifierAdded(tileId, modifierAddress);
    }

    /**
     * @dev Allows the tile owner to remove an address from the approved modifiers list.
     * @param tileId The ID of the tile.
     * @param modifierAddress The address to remove approval from.
     */
    function removeApprovedModifier(uint256 tileId, address modifierAddress) public whenTileExists(tileId) whenNotPaused onlyTileOwner(tileId) {
        tiles[tileId].approvedModifiers[modifierAddress] = false;
        emit ApprovedModifierRemoved(tileId, modifierAddress);
    }

    // --- 9. Tile Fuel & Maintenance ---

    /**
     * @dev Allows anyone to add fuel to a tile by sending ETH.
     * The ETH is converted to fuel based on `fuelPerWei`.
     * @param tileId The ID of the tile to add fuel to.
     */
    function addFuel(uint256 tileId) public payable whenTileExists(tileId) whenNotPaused {
        require(msg.value > 0, "InfiniteCanvas: Must send ETH to add fuel");
        uint256 addedFuel = msg.value * fuelConfig.fuelPerWei;
        tiles[tileId].fuel += addedFuel;
        // The ETH sent for fuel is 'burned' in terms of withdrawal, fueling the contract's operation conceptually.
        // Alternatively, could add it to totalFeesCollected if meant to be withdrawable. Let's "burn" it for now.
        // totalFeesCollected += msg.value; // Uncomment if fuel payments should be withdrawable fees
        emit TileFuelAdded(tileId, msg.sender, addedFuel);
    }

     /**
      * @dev Allows the contract owner to set the fuel configuration parameters.
      * @param newConfig The new FuelConfig struct.
      */
    function setFuelConfig(FuelConfig memory newConfig) public onlyOwner {
        require(newConfig.fuelPerWei > 0, "InfiniteCanvas: fuelPerWei must be > 0");
        fuelConfig = newConfig;
        emit FuelConfigUpdated(newConfig);
    }

    /**
     * @dev Internal function to drain fuel from a tile.
     * This is called by actions that cost fuel (claim, modify).
     * Time-based drain is conceptual and handled off-chain by interpreting last activity/fuel level.
     * @param tileId The ID of the tile.
     * @param amount The amount of fuel to drain.
     */
    function _drainFuel(uint256 tileId, uint256 amount) internal {
        require(tiles[tileId].fuel >= amount, "InfiniteCanvas: Insufficient fuel");
        tiles[tileId].fuel -= amount;
        // Note: A more advanced system could track fuel consumption based on time delta
        // since last interaction, but that adds complexity to every tile interaction.
        // The current model simply costs fuel *per action*. Off-chain renderers
        // could visually represent decay based on `fuelDrainPerSecond` and `lastModifiedTime`/`creationTime`/`fuel`.
    }

    /**
     * @dev Gets the current fuel level of a tile.
     * While time-based drain isn't enforced on-chain per block, off-chain logic
     * can use this function and the fuel config to estimate the *effective* fuel.
     * @param tileId The ID of the tile.
     * @return The current fuel level.
     */
    function checkFuelLevel(uint256 tileId) public view whenTileExists(tileId) returns (uint256) {
        // Note: This returns the on-chain stored fuel. Off-chain logic should
        // calculate current effective fuel based on time elapsed and fuelConfig.
        return tiles[tileId].fuel;
    }


    // --- 10. Marketplace ---

    /**
     * @dev Allows the tile owner to list their tile for sale. Clears any existing approval.
     * @param tileId The ID of the tile to list.
     * @param price The sale price in wei.
     */
    function listTileForSale(uint256 tileId, uint256 price) public whenTileExists(tileId) whenNotPaused onlyTileOwner(tileId) {
        require(price > 0, "InfiniteCanvas: Sale price must be greater than 0");

        // Cancel any existing approval before listing
        delete _tileApprovals[tileId];

        tileSales[tileId] = TileSale({
            isListed: true,
            price: price,
            seller: msg.sender // Store seller to verify on buy
        });

        emit TileListed(tileId, msg.sender, price);
    }

    /**
     * @dev Allows a user to buy a listed tile.
     * @param tileId The ID of the tile to buy.
     */
    function buyTile(uint256 tileId) public payable whenTileExists(tileId) whenNotPaused {
        TileSale storage listing = tileSales[tileId];
        require(listing.isListed, "InfiniteCanvas: Tile is not listed for sale");
        require(msg.value >= listing.price, "InfiniteCanvas: Insufficient payment");
        require(msg.sender != listing.seller, "InfiniteCanvas: Cannot buy your own tile");
        require(tiles[tileId].owner == listing.seller, "InfiniteCanvas: Listing is stale, owner changed");

        uint256 salePrice = listing.price;
        address seller = listing.seller;

        // Transfer ownership
        _transfer(seller, msg.sender, tileId);

        // Transfer payment to seller
        (bool success, ) = payable(seller).call{value: salePrice}("");
        require(success, "InfiniteCanvas: Payment to seller failed");

        // Remove listing
        delete tileSales[tileId];

        emit TileBought(tileId, msg.sender, salePrice);

        // Refund excess payment if any
        if (msg.value > salePrice) {
            (bool refundSuccess, ) = payable(msg.sender).call{value: msg.value - salePrice}("");
            require(refundSuccess, "InfiniteCanvas: Refund failed");
        }
    }

    /**
     * @dev Allows the seller (original lister) or current owner to cancel a sale listing.
     * @param tileId The ID of the tile.
     */
    function cancelListing(uint256 tileId) public whenTileExists(tileId) whenNotPaused {
        TileSale storage listing = tileSales[tileId];
        require(listing.isListed, "InfiniteCanvas: Tile is not listed for sale");
        // Allow either the original lister or the current owner to cancel
        require(msg.sender == listing.seller || msg.sender == tiles[tileId].owner, "InfiniteCanvas: Not seller or owner");

        delete tileSales[tileId];

        emit TileListingCancelled(tileId);
    }

     /**
      * @dev Allows the seller (original lister) or current owner to update the price of a listing.
      * @param tileId The ID of the tile.
      * @param newPrice The new sale price in wei.
      */
    function setListingPrice(uint256 tileId, uint256 newPrice) public whenTileExists(tileId) whenNotPaused {
        TileSale storage listing = tileSales[tileId];
        require(listing.isListed, "InfiniteCanvas: Tile is not listed for sale");
         // Allow either the original lister or the current owner to update price
        require(msg.sender == listing.seller || msg.sender == tiles[tileId].owner, "InfiniteCanvas: Not seller or owner");
        require(newPrice > 0, "InfiniteCanvas: Sale price must be greater than 0");

        listing.price = newPrice;
        // Note: seller address is not updated here, buyTile checks current owner vs seller.

        emit TileListingPriceUpdated(tileId, newPrice);
    }


    // --- 11. Query & View Functions ---

    /**
     * @dev Retrieves all details for a specific tile ID.
     * @param tileId The ID of the tile.
     * @return A tuple containing all tile properties.
     */
    function getTile(uint256 tileId) public view whenTileExists(tileId) returns (
        uint256 id,
        address owner,
        int128 x1,
        int128 y1,
        int128 x2,
        int128 y2,
        bytes memory data,
        uint64 creationTime,
        uint64 lastModifiedTime,
        uint256 fuel,
        ModificationPermission modificationPermissions,
        uint256 modificationFee
    ) {
        Tile storage tile = tiles[tileId];
        return (
            tile.id,
            tile.owner,
            tile.x1,
            tile.y1,
            tile.x2,
            tile.y2,
            tile.data,
            tile.creationTime,
            tile.lastModifiedTime,
            tile.fuel,
            tile.modificationPermissions,
            tile.modificationFee
        );
    }

    /**
     * @dev Retrieves the list of tile IDs owned by a specific address.
     * @param owner The address to query.
     * @return An array of tile IDs. Note: This can be gas-heavy for owners with many tiles.
     */
    function getTilesByOwner(address owner) public view returns (uint256[] memory) {
        return _ownerTiles[owner];
    }

    /**
     * @dev Returns the total number of tiles that have been claimed.
     */
    function getTotalSupply() public view returns (uint256) {
        return _tileIdCounter;
    }

    /**
     * @dev Checks if a proposed rectangular region overlaps with any existing tile.
     * This function iterates through all existing tiles and can be gas-heavy
     * if the number of tiles is very large. For production, consider off-chain checks
     * or a spatial indexing approach if feasible on-chain.
     * @param checkX1 The minimum x-coordinate of the region to check.
     * @param checkY1 The minimum y-coordinate of the region to check.
     * @param checkX2 The maximum x-coordinate of the region to check.
     * @param checkY2 The maximum y-coordinate of the region to check.
     * @return True if there is an overlap, false otherwise.
     */
    function isOverlapping(int128 checkX1, int128 checkY1, int128 checkX2, int128 checkY2) public view returns (bool) {
       return _isOverlapping(checkX1, checkY1, checkX2, checkY2);
    }

    /**
     * @dev Finds the ID of a tile that contains a specific coordinate (x, y).
     * Iterates through all tiles. Can be gas-heavy.
     * @param x The x-coordinate.
     * @param y The y-coordinate.
     * @return The ID of the tile containing the coordinate, or 0 if none found.
     */
    function getTileAtCoordinate(int128 x, int128 y) public view returns (uint256) {
        for (uint256 i = 1; i <= _tileIdCounter; i++) {
            Tile storage tile = tiles[i];
             if (tile.owner != address(0) && // Check if tile exists (not deleted/zeroed)
                 x >= tile.x1 && x <= tile.x2 &&
                 y >= tile.y1 && y <= tile.y2) {
                return i;
            }
        }
        return 0; // Indicate no tile found
    }

    /**
     * @dev Finds the IDs of tiles that intersect with a given bounding box.
     * Iterates through all tiles. Can be very gas-heavy depending on the number of tiles.
     * @param regionX1 The minimum x-coordinate of the query region.
     * @param regionY1 The minimum y-coordinate of the query region.
     * @param regionX2 The maximum x-coordinate of the query region.
     * @param regionY2 The maximum y-coordinate of the query region.
     * @return An array of tile IDs that intersect the region.
     */
    function getTilesInRegion(int128 regionX1, int128 regionY1, int128 regionX2, int128 regionY2) public view returns (uint256[] memory) {
        require(regionX1 <= regionX2 && regionY1 <= regionY2, "InfiniteCanvas: Invalid query region coordinates");
        uint256[] memory intersectingTiles = new uint256[](0); // Initialize an empty dynamic array

        // Pre-allocate a potentially large array (might hit gas limits) or use a loop and push (more gas efficient for small results)
        // Let's use a loop and push for better gas characteristics on average cases.
        uint256 count = 0;
        uint256[] memory tempTileIds = new uint256[](_tileIdCounter); // Max possible size

        for (uint256 i = 1; i <= _tileIdCounter; i++) {
            Tile storage tile = tiles[i];
             if (tile.owner != address(0)) { // Check if tile exists
                // Check for intersection: regions *don't* overlap if one is entirely to the left/right/above/below the other
                bool overlaps = !(regionX2 < tile.x1 || regionX1 > tile.x2 || regionY2 < tile.y1 || regionY1 > tile.y2);
                if (overlaps) {
                   if (count < tempTileIds.length) { // Avoid out of bounds if _tileIdCounter was manipulated unexpectedly
                       tempTileIds[count] = i;
                       count++;
                   }
                }
            }
        }

        // Copy results to a correctly sized array
        uint256[] memory result = new uint256[](count);
        for(uint j = 0; j < count; j++) {
            result[j] = tempTileIds[j];
        }
        return result;
    }

     /**
      * @dev Retrieves the sale listing details for a specific tile.
      * @param tileId The ID of the tile.
      * @return isListed, price, seller.
      */
    function getListing(uint256 tileId) public view returns (bool isListed, uint256 price, address seller) {
         TileSale storage listing = tileSales[tileId];
         return (listing.isListed, listing.price, listing.seller);
    }

    /**
     * @dev Get the approved address for a single tile ID. ERC721-like view.
     * @param tileId The ID of the tile.
     * @return The approved address, or address(0) if none set.
     */
    function getApproved(uint256 tileId) public view whenTileExists(tileId) returns (address) {
        return _tileApprovals[tileId];
    }


    // --- 12. Advanced/Configuration ---

    /**
     * @dev Allows the contract owner to set the price for claiming a new tile.
     * @param price The new claim price in wei.
     */
    function setClaimPrice(uint256 price) public onlyOwner {
        claimPrice = price;
        emit ClaimPriceUpdated(price);
    }

    /**
     * @dev Allows the tile owner to set a byte string representing a rule for how their tile
     * interacts with neighbors. The interpretation of this rule is off-chain.
     * This stores programmable metadata on-chain related to inter-tile behavior.
     * @param tileId The ID of the tile.
     * @param rule The byte string representing the interaction rule.
     */
    function setAdjacentInteractionRule(uint256 tileId, bytes calldata rule) public whenTileExists(tileId) whenNotPaused onlyTileOwner(tileId) {
        adjacentInteractionRules[tileId] = rule;
        emit AdjacentInteractionRuleSet(tileId, rule);
    }

    /**
     * @dev Allows anyone to trigger an event signaling off-chain logic to process
     * adjacency rules for a tile and its immediate neighbors. Pays gas to emit the event.
     * The contract does NOT execute the interaction logic itself.
     * @param tileId The ID of the tile to trigger interaction for.
     */
    function triggerAdjacentInteraction(uint256 tileId) public whenTileExists(tileId) whenNotPaused {
        bytes memory rule = adjacentInteractionRules[tileId];

        // Find neighbor tile IDs (simplified search for immediate 8 neighbors)
        // This simple search can be gas-heavy if there are many tiles and finding neighbors
        // requires iterating a large portion of the canvas.
        Tile storage centerTile = tiles[tileId];
        uint256[] memory neighborIds = new uint256[](8); // Max 8 immediate neighbors
        uint256 neighborCount = 0;

        // Check coordinates around the center tile. This is a simplified approach;
        // a robust implementation might need a spatial index or iterate differently.
        // This version iterates *all* tiles to see if they touch or are adjacent.
        for (uint256 i = 1; i <= _tileIdCounter; i++) {
            if (i == tileId || tiles[i].owner == address(0)) continue; // Skip self and non-existent tiles

            Tile storage neighborTile = tiles[i];

            // Check for adjacency/touching: Not separated horizontally AND not separated vertically
            bool isAdjacent = !(centerTile.x2 < neighborTile.x1 - 1 || centerTile.x1 > neighborTile.x2 + 1 ||
                                 centerTile.y2 < neighborTile.y1 - 1 || centerTile.y1 > neighborTile.y2 + 1);

            if (isAdjacent) {
                 if (neighborCount < neighborIds.length) {
                    neighborIds[neighborCount] = i;
                    neighborCount++;
                 } else {
                     // If more than 8 neighbors touch (e.g., complex shapes), resize array
                     // Or simplify logic to only look at tiles that *share an edge*, not just touch corners.
                     // For this example, we'll cap at 8 or grow if necessary (more complex)
                     // Let's make it a fixed size for simplicity in this example.
                 }
            }
        }
        // Create a correctly sized array for the event
        uint256[] memory finalNeighborIds = new uint256[](neighborCount);
        for(uint j=0; j < neighborCount; j++) {
            finalNeighborIds[j] = neighborIds[j];
        }


        // Emit event for off-chain listeners
        emit AdjacentInteractionTriggered(tileId, msg.sender, rule, finalNeighborIds);
    }


    /**
     * @dev Allows the contract owner to withdraw accumulated fees.
     * Fees come from claim price payments and potentially future sources.
     */
    function withdrawFees() public onlyOwner {
        uint256 amount = totalFeesCollected;
        require(amount > 0, "InfiniteCanvas: No fees to withdraw");
        totalFeesCollected = 0;

        (bool success, ) = payable(owner()).call{value: amount}("");
        require(success, "InfiniteCanvas: Fee withdrawal failed");

        emit FeesWithdrawn(owner(), amount);
    }

    // --- 13. Internal Helper Functions ---

    /**
     * @dev Internal helper to check if a proposed region overlaps with any existing tile.
     * This function iterates through all existing tiles.
     */
    function _isOverlapping(int128 checkX1, int128 checkY1, int128 checkX2, int128 checkY2) internal view returns (bool) {
        // Iterate through all existing tiles (from 1 to current counter)
        for (uint256 i = 1; i <= _tileIdCounter; i++) {
            Tile storage tile = tiles[i];

            // A tile exists if its owner is not address(0)
            if (tile.owner != address(0)) {
                // Check for overlap: Two rectangles overlap if they are *not* separated
                // They are separated if one is entirely to the left of the other,
                // or entirely to the right, or entirely below, or entirely above.
                bool separated = (checkX2 < tile.x1 || checkX1 > tile.x2 || checkY2 < tile.y1 || checkY1 > tile.y2);
                if (!separated) {
                    return true; // Overlap found
                }
            }
        }
        return false; // No overlap found
    }

     // Override pausable functions to add whenNotPaused modifier where needed
    function pause() public override onlyOwner whenNotPaused {
        _pause();
    }

    function unpause() public override onlyOwner whenPaused {
        _unpause();
    }

    // The default Context._msgSender() is fine here.
    // No need to override unless we were integrating with a different context provider.
    // function _msgSender() internal view virtual override returns (address) { return Context.msgSender(); }

}
```