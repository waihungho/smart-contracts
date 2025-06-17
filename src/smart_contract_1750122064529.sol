Okay, let's create a contract that combines elements of generative art, dynamic NFTs, on-chain data manipulation, and user-driven interaction without directly duplicating standard open-source templates like pure ERC721/1155 marketplaces, staking, or simple games.

We'll build a "CryptoMosaics" contract where each NFT represents a digital "tile" with unique on-chain properties. These properties are partially generated deterministically at minting and can also be influenced by a global "environment factor" and user actions over time. Users can collect tiles and propose on-chain "mosaic assemblies" using their owned tiles, which can then be evaluated.

---

**Outline and Function Summary**

**Contract Name:** `CryptoMosaics`

**Concept:** An ERC721 contract for collecting dynamic, generative "tiles". Tiles have on-chain properties that can change based on a global state and user interactions. Users can propose on-chain arrangements of their owned tiles (mosaics).

**Core Features:**

1.  **Generative & Dynamic Tiles:**
    *   Tiles have on-chain data (color, pattern, shape index, coordinates) generated deterministically upon minting based on factors like token ID, minter, block data.
    *   A global "environment factor" influences the *displayed* or *interpreted* properties of tiles, making them dynamic over time.
    *   Users can perform actions (`exploreTileEnhancement`, `rerollTileProperty`) that subtly alter tile properties or grant benefits.
2.  **On-Chain Mosaic Assembly:**
    *   Users can submit proposals detailing an arrangement of their *owned* tiles using their coordinates.
    *   These proposals are stored on-chain.
    *   Proposals can potentially be evaluated or referenced.
3.  **Modular Design:**
    *   Uses libraries for safe transfers.
    *   Inherits basic ERC721 and Ownable patterns but adds significant custom logic.
4.  **Advanced Concepts:**
    *   Deterministic property generation based on multiple on-chain data points.
    *   Dynamic state calculation (`getTileDynamicProperties`).
    *   On-chain data structures for complex objects (Tiles, Mosaic Proposals).
    *   User interaction affecting state (`exploreTileEnhancement`, `rerollTileProperty`).
    *   Global state influencing individual token properties (`globalEnvironmentFactor`).

**Function Categories:**

1.  **ERC721 Standard Functions:** (9 functions)
    *   Standard functions required by ERC721 for ownership, transfers, and approvals.
2.  **Minting & Creation:** (3 functions)
    *   Functions for creating new tiles, generating their initial properties.
3.  **Tile Data & Properties:** (3 functions)
    *   View functions to inspect tile properties (base and dynamic).
4.  **Dynamic State & Interaction:** (4 functions)
    *   Functions to get/update the global environment factor and for user interactions affecting tiles.
5.  **Mosaic Assembly & Proposals:** (4 functions)
    *   Functions for users to propose and retrieve mosaic assemblies.
6.  **Admin & Configuration:** (5 functions)
    *   Functions for contract owner to manage settings, pause, withdraw, etc.
7.  **Utility:** (2 functions)
    *   Standard ownership transfer functions.

**Function Summary (Total: 30+ functions):**

*   `constructor()`: Initializes contract, sets owner, initial settings.
*   `supportsInterface(bytes4 interfaceId)`: ERC165 standard check.
*   `balanceOf(address owner)`: Returns number of tokens owned by `owner`.
*   `ownerOf(uint256 tokenId)`: Returns owner of `tokenId`.
*   `safeTransferFrom(address from, address to, uint256 tokenId)`: Safe transfer.
*   `safeTransferFrom(address from, address to, uint256 tokenId, bytes data)`: Safe transfer with data.
*   `transferFrom(address from, address to, uint256 tokenId)`: Unsafe transfer.
*   `approve(address to, uint256 tokenId)`: Approve address to spend token.
*   `getApproved(uint256 tokenId)`: Get approved address for token.
*   `setApprovalForAll(address operator, bool approved)`: Approve/disapprove operator for all tokens.
*   `isApprovedForAll(address owner, address operator)`: Check if operator is approved for owner.
*   `tokenURI(uint256 tokenId)`: Returns the metadata URI for a tile.

*   `mintTile()`: Mints a new tile to the caller, generates properties, requires payment.
*   `batchMintTiles(uint256 count)`: Mints multiple tiles, requires payment per tile.
*   `previewMintProperties(uint256 potentialTokenId, address minter)`: Pure function to preview potential properties for a future mint.

*   `getTileProperties(uint256 tokenId)`: Returns the base on-chain properties of a tile.
*   `getTileDynamicProperties(uint256 tokenId)`: Returns properties adjusted by the current global environment factor.
*   `getGlobalEnvironmentFactor()`: Returns the current global environmental factor.

*   `updateGlobalEnvironmentFactor(uint256 newFactor)`: Owner function to change the global environment factor. (Could be more complex in a real DApp, e.g., DAO vote, price feed).
*   `exploreTileEnhancement(uint256 tokenId)`: User calls to potentially trigger a small positive or negative change to a tile's base properties or grant a bonus (gas consuming, adds a random element).
*   `rerollTileProperty(uint256 tokenId, uint8 propertyIndex)`: Allows owner to spend gas/fee to reroll a single base property of their tile.
*   `getLastEnhancementBlock(uint256 tokenId)`: Get block number of last `exploreTileEnhancement`.

*   `proposeMosaicAssembly(uint256[] memory tileIds, uint16[] memory xCoords, uint16[] memory yCoords)`: User submits an array of owned tile IDs and their desired {x, y} coordinates for a mosaic proposal. Stores this on-chain.
*   `getMosaicAssembly(uint256 proposalId)`: Retrieve a specific mosaic proposal details.
*   `getUserMosaicProposals(address user)`: Get all proposal IDs submitted by a user.
*   `getTotalMosaicProposals()`: Get the total number of proposals submitted.

*   `setMintPrice(uint256 price)`: Owner sets the price for minting a tile.
*   `setMaxSupply(uint256 supply)`: Owner sets the maximum number of tiles that can exist.
*   `withdrawFunds()`: Owner withdraws accumulated ETH.
*   `pauseMinting()`: Owner pauses tile minting.
*   `unpauseMinting()`: Owner unpauses tile minting.

*   `transferOwnership(address newOwner)`: Transfers contract ownership.
*   `renounceOwnership()`: Renounces contract ownership (dangerous).

---

**Smart Contract Source Code**

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";

// Outline and Function Summary
//
// Contract Name: CryptoMosaics
// Concept: An ERC721 contract for collecting dynamic, generative "tiles".
// Tiles have on-chain properties that can change based on a global state
// and user interactions. Users can propose on-chain arrangements of their owned
// tiles (mosaics).
//
// Core Features:
// 1. Generative & Dynamic Tiles: Tiles have on-chain data (color, pattern, shape, coords)
//    generated deterministically at minting and influenced by a global "environment factor".
// 2. On-Chain Mosaic Assembly: Users can submit proposals for arranging owned tiles, stored on-chain.
// 3. Modular Design: Uses libraries and standard inheritance, but heavily customized logic.
// 4. Advanced Concepts: Deterministic generation, dynamic state calculation, complex data structures,
//    user interaction affecting state, global state influencing tokens.
//
// Function Categories:
// 1. ERC721 Standard Functions: (9 functions) Standard ERC721 operations.
// 2. Minting & Creation: (3 functions) Functions to create new tiles.
// 3. Tile Data & Properties: (3 functions) View functions for tile properties.
// 4. Dynamic State & Interaction: (4 functions) Global state management and user tile interaction.
// 5. Mosaic Assembly & Proposals: (4 functions) Creating and retrieving mosaic proposals.
// 6. Admin & Configuration: (5 functions) Owner controls for settings.
// 7. Utility: (2 functions) Ownership management.
//
// Function Summary (Total: 30+ functions):
// - constructor(): Initializes contract.
// - supportsInterface(bytes4 interfaceId): ERC165 standard.
// - balanceOf(address owner): ERC721 standard.
// - ownerOf(uint256 tokenId): ERC721 standard.
// - safeTransferFrom(address from, address to, uint256 tokenId): ERC721 standard.
// - safeTransferFrom(address from, address to, uint256 tokenId, bytes data): ERC721 standard.
// - transferFrom(address from, address to, uint256 tokenId): ERC721 standard.
// - approve(address to, uint256 tokenId): ERC721 standard.
// - getApproved(uint256 tokenId): ERC721 standard.
// - setApprovalForAll(address operator, bool approved): ERC721 standard.
// - isApprovedForAll(address owner, address operator): ERC721 standard.
// - tokenURI(uint256 tokenId): ERC721 standard (returns base URI).
// - mintTile(): Mints a new tile to caller, generates properties, requires payment.
// - batchMintTiles(uint256 count): Mints multiple tiles, requires payment.
// - previewMintProperties(uint256 potentialTokenId, address minter): Pure function to preview properties.
// - getTileProperties(uint256 tokenId): Returns base on-chain properties.
// - getTileDynamicProperties(uint256 tokenId): Returns properties adjusted by global environment.
// - getGlobalEnvironmentFactor(): Returns current global environmental factor.
// - updateGlobalEnvironmentFactor(uint256 newFactor): Owner changes global environment.
// - exploreTileEnhancement(uint256 tokenId): User interaction, might change tile properties/grant bonus.
// - rerollTileProperty(uint256 tokenId, uint8 propertyIndex): Allows owner to reroll a tile property.
// - getLastEnhancementBlock(uint256 tokenId): Get block of last enhancement interaction.
// - proposeMosaicAssembly(uint256[] memory tileIds, uint16[] memory xCoords, uint16[] memory yCoords): User submits an assembly proposal.
// - getMosaicAssembly(uint256 proposalId): Retrieve a specific proposal.
// - getUserMosaicProposals(address user): Get proposal IDs by user.
// - getTotalMosaicProposals(): Get total number of proposals.
// - setMintPrice(uint256 price): Owner sets mint price.
// - setMaxSupply(uint256 supply): Owner sets max tile supply.
// - withdrawFunds(): Owner withdraws ETH.
// - pauseMinting(): Owner pauses minting.
// - unpauseMinting(): Owner unpauses minting.
// - transferOwnership(address newOwner): Standard ownership transfer.
// - renounceOwnership(): Standard ownership renounce.

error InvalidPropertyIndex();
error MintingPaused();
error MaxSupplyReached();
error InsufficientPayment();
error InvalidBatchCount();
error TileDoesNotExist();
error NotTileOwner();
error InvalidMosaicData();
error NotEnoughTilesForMosaic();
error DuplicateTileInMosaic();
error TileNotInProposal(uint256 proposalId, uint256 tileId);
error RerollLimitReached();
error InvalidRerollPrice();
error PropertyIndexOutOfRange();

contract CryptoMosaics is ERC721, Ownable, ReentrancyGuard {
    using Counters for Counters.Counter;
    using Strings for uint256;
    using Math for uint256; // For common math operations

    Counters.Counter private _tokenIdCounter;
    uint256 private _maxSupply;
    uint256 private _mintPrice;
    bool private _mintingPaused = false;

    // Struct to define the immutable/base properties of a tile
    struct TileProperties {
        uint8 colorPaletteIndex; // Index referencing a conceptual color palette
        uint8 patternIndex;      // Index referencing a conceptual pattern set
        uint8 shapeIndex;        // Index referencing a conceptual shape set
        // Coordinates within a conceptual grid, assigned at minting, can be hints
        uint16 mintGridX;
        uint16 mintGridY;
        uint8 rerollCount; // How many times properties have been rerolled
    }

    // Mapping from token ID to its base properties
    mapping(uint256 => TileProperties) private _tileProperties;

    // Global state variable influencing tile appearance/interpretation
    uint256 private _globalEnvironmentFactor;

    // Mapping to track the last block a tile was 'enhanced'
    mapping(uint256 => uint256) private _lastEnhancementBlock;

    // Struct for a user's proposed mosaic assembly
    struct MosaicProposal {
        address proposer;
        uint256 timestamp;
        uint256[] tileIds; // IDs of tiles used in this assembly
        struct Coordinates {
            uint16 x;
            uint16 y;
        }
        Coordinates[] relativeCoords; // Relative position {x, y} for each tileId
        // Add more potential fields: e.g., description, name, status (pending, approved, etc.)
    }

    // Array to store all mosaic proposals
    MosaicProposal[] private _mosaicProposals;

    // Mapping from user address to an array of their proposal IDs
    mapping(address => uint256[]) private _userMosaicProposals;

    // Configuration for rerolling properties
    uint256 private _rerollPrice = 0.01 ether; // Price to reroll one property
    uint8 private constant MAX_REROLLS_PER_TILE = 3; // Limit on rerolls per tile

    // Events
    event TileMinted(uint256 indexed tokenId, address indexed minter, TileProperties properties);
    event GlobalEnvironmentUpdated(uint256 oldFactor, uint256 newFactor);
    event TileEnhanced(uint256 indexed tokenId, address indexed enchanter, uint256 blockNumber);
    event TilePropertyRerolled(uint256 indexed tokenId, uint8 indexed propertyIndex, uint8 newPropertyValue);
    event MosaicProposed(uint256 indexed proposalId, address indexed proposer, uint256[] tileIds);
    event MintPriceUpdated(uint256 newPrice);
    event MaxSupplyUpdated(uint256 newSupply);
    event MintingPausedStatus(bool isPaused);

    // --- Constructor ---
    constructor(string memory name, string memory symbol, uint256 maxSupply, uint256 initialMintPrice)
        ERC721(name, symbol)
        Ownable(msg.sender)
    {
        _maxSupply = maxSupply;
        _mintPrice = initialMintPrice;
        _globalEnvironmentFactor = block.timestamp; // Initialize with something dynamic
    }

    // --- ERC721 Standard Functions ---
    // These are mostly inherited or boilerplate, added here for clarity of the 20+ count

    // supportInterface is automatically handled by OpenZeppelin's ERC721 base

    // balanceOf, ownerOf, transferFrom, safeTransferFrom (both versions),
    // approve, getApproved, setApprovalForAll, isApprovedForAll are all
    // handled by inheriting ERC721.
    // We only need to override _update and _increaseBalance for ERC721 tracking
    // which are handled internally by OZ's ERC721 using _beforeTokenTransfer hook.

    // tokenURI can be overridden to point to metadata service if needed.
    // Default OZ ERC721 baseURI uses a virtual function, we can set it.
    // function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
    //     _requireMinted(tokenId);
    //     string memory baseURI = _baseURI();
    //     return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    // }
    // virtual function _baseURI() internal view virtual returns (string memory) {
    //    // Return your base URI here
    //    return "ipfs://YOUR_METADATA_CID/";
    // }

    // --- Internal Helper for Property Generation ---
    // Deterministically generates initial properties based on seed data.
    // The seed should incorporate block-specific randomness if desired,
    // combined with predictable elements like tokenId and minter address.
    function _generateTileProperties(uint256 tokenId, address minter, uint256 seed)
        internal
        pure
        returns (TileProperties memory)
    {
        // Combine seed data for a unique hash
        bytes32 hash = keccak256(abi.encodePacked(tokenId, minter, seed, block.timestamp, block.difficulty));

        // Use parts of the hash to derive properties
        // Using bitwise operations and modulo for distribution
        uint256 h = uint256(hash);

        uint8 color = uint8((h >> 240) % 256); // Use first byte for color
        uint8 pattern = uint8((h >> 232) % 100); // Use next byte for pattern (example max 100)
        uint8 shape = uint8((h >> 224) % 50);   // Use next byte for shape (example max 50)

        // Simple pseudo-random grid position (example grid 100x100)
        uint16 gridX = uint16((h >> 216) % 100);
        uint16 gridY = uint16((h >> 208) % 100);

        return TileProperties({
            colorPaletteIndex: color,
            patternIndex: pattern,
            shapeIndex: shape,
            mintGridX: gridX,
            mintGridY: gridY,
            rerollCount: 0 // Starts at 0 rerolls
        });
    }

    // --- Minting & Creation ---

    function mintTile() external payable nonReentrant whenNotPaused {
        if (_tokenIdCounter.current() >= _maxSupply) revert MaxSupplyReached();
        if (msg.value < _mintPrice) revert InsufficientPayment();

        _tokenIdCounter.increment();
        uint256 newTokenId = _tokenIdCounter.current();

        // Use current block hash + timestamp + msg.sender + tokenId as seed for generation
        uint256 seed = uint256(keccak256(abi.encodePacked(block.timestamp, blockhash(block.number - 1), msg.sender, newTokenId)));
        TileProperties memory properties = _generateTileProperties(newTokenId, msg.sender, seed);

        _tileProperties[newTokenId] = properties;

        _safeMint(msg.sender, newTokenId);

        emit TileMinted(newTokenId, msg.sender, properties);

        // Refund excess payment if any
        if (msg.value > _mintPrice) {
            payable(msg.sender).transfer(msg.value - _mintPrice);
        }
    }

    function batchMintTiles(uint256 count) external payable nonReentrant whenNotPaused {
        if (count == 0 || count > 10) revert InvalidBatchCount(); // Limit batch size
        uint256 totalPrice = count * _mintPrice;
        if (msg.value < totalPrice) revert InsufficientPayment();
        if (_tokenIdCounter.current() + count > _maxSupply) revert MaxSupplyReached();

        uint256 refund = msg.value - totalPrice;

        for (uint i = 0; i < count; i++) {
            _tokenIdCounter.increment();
            uint256 newTokenId = _tokenIdCounter.current();

            // Seed includes loop index to ensure variety within batch
            uint256 seed = uint256(keccak256(abi.encodePacked(block.timestamp, blockhash(block.number - 1), msg.sender, newTokenId, i)));
            TileProperties memory properties = _generateTileProperties(newTokenId, msg.sender, seed);

            _tileProperties[newTokenId] = properties;

            _safeMint(msg.sender, newTokenId);

            emit TileMinted(newTokenId, msg.sender, properties);
        }

        // Refund excess payment
        if (refund > 0) {
            payable(msg.sender).transfer(refund);
        }
    }

    function previewMintProperties(uint256 potentialTokenId, address minter)
        public
        view
        pure
        returns (TileProperties memory)
    {
        // This is a *pure* function simulating the generation logic.
        // The seed here won't be the exact seed used during minting
        // (as it lacks the specific block data and timestamp of the future mint),
        // but provides a close approximation for preview purposes.
        // Using fixed placeholder block data for pure function compatibility.
        uint256 simulatedBlockTimestamp = 1678886400; // Example timestamp
        bytes32 simulatedBlockHash = 0x1234567890123456789012345678901234567890123456789012345678901234; // Example hash
        uint256 simulatedBlockDifficulty = 1000000; // Example difficulty

        uint256 seed = uint256(keccak256(abi.encodePacked(simulatedBlockTimestamp, simulatedBlockHash, minter, potentialTokenId)));
        return _generateTileProperties(potentialTokenId, minter, seed);
    }


    // --- Tile Data & Properties ---

    function getTileProperties(uint256 tokenId)
        public
        view
        returns (TileProperties memory)
    {
        if (!_exists(tokenId)) revert TileDoesNotExist();
        return _tileProperties[tokenId];
    }

    function getTileDynamicProperties(uint256 tokenId)
        public
        view
        returns (TileProperties memory dynamicProperties)
    {
        if (!_exists(tokenId)) revert TileDoesNotExist();
        TileProperties storage baseProperties = _tileProperties[tokenId];

        // --- Dynamic Calculation Logic ---
        // This is where the 'globalEnvironmentFactor' influences the interpretation
        // of base properties. This logic can be arbitrarily complex.
        // Example: Shift colors based on the environment factor
        dynamicProperties.colorPaletteIndex = uint8((baseProperties.colorPaletteIndex + _globalEnvironmentFactor) % 256);
        dynamicProperties.patternIndex = uint8((baseProperties.patternIndex + (_globalEnvironmentFactor / 10)) % 100); // Different scaling
        dynamicProperties.shapeIndex = baseProperties.shapeIndex; // Shape might not be dynamic
        dynamicProperties.mintGridX = baseProperties.mintGridX; // Mint coords are fixed
        dynamicProperties.mintGridY = baseProperties.mintGridY;
        dynamicProperties.rerollCount = baseProperties.rerollCount; // Reroll count is fixed

        // Add more complex interactions here, e.g.,
        // - If global factor is high, certain patterns are brighter
        // - If global factor is low, certain shapes appear cracked
        // - Use last enhancement block to introduce aging/weathering effects
        // uint256 blocksSinceEnhancement = block.number - _lastEnhancementBlock[tokenId];
        // if (blocksSinceEnhancement > 1000) {
        //    dynamicProperties.colorPaletteIndex = dynamicProperties.colorPaletteIndex / 2; // Fades
        // }
    }

    function getGlobalEnvironmentFactor() public view returns (uint256) {
        return _globalEnvironmentFactor;
    }

    // --- Dynamic State & Interaction ---

    function updateGlobalEnvironmentFactor(uint256 newFactor) external onlyOwner {
        emit GlobalEnvironmentUpdated(_globalEnvironmentFactor, newFactor);
        _globalEnvironmentFactor = newFactor;
    }

    function exploreTileEnhancement(uint256 tokenId) external nonReentrant {
        if (ownerOf(tokenId) != msg.sender) revert NotTileOwner();

        // Simple gas-consuming action, potentially tied to block randomness
        // This requires gas but might not always result in a direct change
        // The outcome could be weighted by time since last exploration, etc.
        uint256 randomness = uint256(keccak256(abi.encodePacked(block.timestamp, blockhash(block.number - 1), msg.sender, tokenId)));

        // Example logic: 10% chance to slightly shift color
        if (randomness % 10 == 0) {
             TileProperties storage properties = _tileProperties[tokenId];
             // Shift color by a small random amount (+/- 1 to 5)
             int8 shift = int8((randomness % 10) - 5); // results in -5 to 4
             properties.colorPaletteIndex = uint8(int16(properties.colorPaletteIndex) + shift); // Use int16 to handle negative shifts safely

             emit TilePropertyRerolled(tokenId, 0, properties.colorPaletteIndex); // Property index 0 for color
        }

        _lastEnhancementBlock[tokenId] = block.number;
        emit TileEnhanced(tokenId, msg.sender, block.number);

        // Could potentially consume another token type, require minimum time elapsed, etc.
    }

    function rerollTileProperty(uint256 tokenId, uint8 propertyIndex) external payable nonReentrant {
        if (ownerOf(tokenId) != msg.sender) revert NotTileOwner();
        if (msg.value < _rerollPrice) revert InvalidRerollPrice();

        TileProperties storage properties = _tileProperties[tokenId];
        if (properties.rerollCount >= MAX_REROLLS_PER_TILE) revert RerollLimitReached();

        // Simple logic: Reroll based on a new seed involving current block data and reroll count
        uint256 seed = uint256(keccak256(abi.encodePacked(block.timestamp, blockhash(block.number - 1), msg.sender, tokenId, propertyIndex, properties.rerollCount)));
        uint256 h = uint256(keccak256(abi.encodePacked(seed))); // Hash the seed

        uint8 newPropertyValue;
        bool success = false;

        // Reroll logic based on propertyIndex
        if (propertyIndex == 0) { // Reroll ColorPaletteIndex
            newPropertyValue = uint8((h >> 240) % 256);
            properties.colorPaletteIndex = newPropertyValue;
            success = true;
        } else if (propertyIndex == 1) { // Reroll PatternIndex
             newPropertyValue = uint8((h >> 232) % 100); // Example max 100
             properties.patternIndex = newPropertyValue;
             success = true;
        } else if (propertyIndex == 2) { // Reroll ShapeIndex
             newPropertyValue = uint8((h >> 224) % 50); // Example max 50
             properties.shapeIndex = newPropertyValue;
             success = true;
        } else {
            revert PropertyIndexOutOfRange(); // Or a specific index error
        }

        if (success) {
             properties.rerollCount++;
             emit TilePropertyRerolled(tokenId, propertyIndex, newPropertyValue);
        }

        // Refund excess payment if any
        if (msg.value > _rerollPrice) {
            payable(msg.sender).transfer(msg.value - _rerollPrice);
        }
    }

     function getLastEnhancementBlock(uint256 tokenId) public view returns (uint256) {
         if (!_exists(tokenId)) revert TileDoesNotExist();
         return _lastEnhancementBlock[tokenId];
     }


    // --- Mosaic Assembly & Proposals ---

    function proposeMosaicAssembly(
        uint256[] memory tileIds,
        uint16[] memory xCoords,
        uint16[] memory yCoords
    ) external {
        if (tileIds.length == 0 || tileIds.length != xCoords.length || tileIds.length != yCoords.length) {
            revert InvalidMosaicData();
        }

        if (tileIds.length < 2) revert NotEnoughTilesForMosaic(); // Minimum 2 tiles for a mosaic

        // Check ownership and for duplicates
        bytes32 seenTokensHash = 0; // Simple way to detect duplicates in a small array
        for (uint i = 0; i < tileIds.length; i++) {
            if (ownerOf(tileIds[i]) != msg.sender) revert NotTileOwner();
            bytes32 currentTokenHash = keccak256(abi.encodePacked(tileIds[i]));
            if ((seenTokensHash & currentTokenHash) != 0) { // Checks if any bit is set in both hashes
                 // This is a very basic check and can have collisions.
                 // For larger arrays, use a mapping or a more robust method.
                 // Given the constraint of storing on-chain, we'll assume
                 // mosaics aren't extremely large or that collisions are acceptable risk,
                 // or require a helper function that costs more gas for robust check.
                 // Let's use a simple mapping for a proper check.
                 mapping(uint256 => bool) seenTokens;
                 for(uint j=0; j < i; j++) {
                     if(seenTokens[tileIds[j]]) revert DuplicateTileInMosaic();
                     seenTokens[tileIds[j]] = true;
                 }
                 if(seenTokens[tileIds[i]]) revert DuplicateTileInMosaic();
                 seenTokens[tileIds[i]] = true;

            }
             seenTokensHash ^= currentTokenHash; // Toggle bits
        }


        MosaicProposal.Coordinates[] memory relativeCoords = new MosaicProposal.Coordinates[](tileIds.length);
        for (uint i = 0; i < tileIds.length; i++) {
            relativeCoords[i] = MosaicProposal.Coordinates(xCoords[i], yCoords[i]);
        }

        uint256 proposalId = _mosaicProposals.length; // Proposal ID is array index

        _mosaicProposals.push(MosaicProposal(
            msg.sender,
            block.timestamp,
            tileIds,
            relativeCoords
        ));

        _userMosaicProposals[msg.sender].push(proposalId);

        emit MosaicProposed(proposalId, msg.sender, tileIds);

        // Note: Storing the full tile IDs and coordinates on-chain for
        // potentially large mosaics can be very gas-intensive.
        // An alternative is to store only a hash of the proposal data,
        // and require off-chain data to be presented for verification.
        // For this example, we store it fully to demonstrate the concept.
    }

    function getMosaicAssembly(uint256 proposalId)
        public
        view
        returns (
            address proposer,
            uint256 timestamp,
            uint256[] memory tileIds,
            MosaicProposal.Coordinates[] memory relativeCoords
        )
    {
        if (proposalId >= _mosaicProposals.length) revert InvalidMosaicData(); // Using same error for index OOB
        MosaicProposal storage proposal = _mosaicProposals[proposalId];
        return (
            proposal.proposer,
            proposal.timestamp,
            proposal.tileIds,
            proposal.relativeCoords
        );
    }

    function getUserMosaicProposals(address user) public view returns (uint256[] memory) {
        return _userMosaicProposals[user];
    }

    function getTotalMosaicProposals() public view returns (uint256) {
        return _mosaicProposals.length;
    }

    // Note: Evaluation logic (e.g., judging based on tile properties, layout)
    // would likely be complex and potentially involve off-chain computation
    // and a trusted party or DAO voting recorded on-chain.
    // Adding a placeholder function:
    // function evaluateMosaicAssembly(uint256 proposalId, uint256 score) external onlyOwner {
    //     // Simple example: Owner assigns a score
    //     if (proposalId >= _mosaicProposals.length) revert InvalidMosaicData();
    //     // Store score, emit event etc.
    //     // Complex evaluation could read tile properties, check for color harmony, etc.
    // }


    // --- Admin & Configuration ---

    function setMintPrice(uint256 price) external onlyOwner {
        _mintPrice = price;
        emit MintPriceUpdated(price);
    }

    function setMaxSupply(uint256 supply) external onlyOwner {
        // Can only increase or set if current supply is 0
        if (supply < _tokenIdCounter.current()) revert MaxSupplyReached(); // Or a more specific error
        _maxSupply = supply;
        emit MaxSupplyUpdated(supply);
    }

    function withdrawFunds() external onlyOwner nonReentrant {
        uint256 balance = address(this).balance;
        if (balance > 0) {
            payable(msg.sender).transfer(balance);
        }
    }

    function pauseMinting() external onlyOwner {
        _mintingPaused = true;
        emit MintingPausedStatus(true);
    }

    function unpauseMinting() external onlyOwner {
        _mintingPaused = false;
        emit MintingPausedStatus(false);
    }

    // --- Utility ---

    // transferOwnership and renounceOwnership inherited from Ownable

    // Internal utility to check minting pause status
    modifier whenNotPaused() {
        if (_mintingPaused) revert MintingPaused();
        _;
    }

    // Helper function to require a tile exists (already in OZ ERC721 _exists)
    // _requireMinted(tokenId) is used internally by OZ ERC721 functions.

    // Helper to get property name by index for UI/metadata generation (pure function)
    // function getPropertyName(uint8 propertyIndex) public pure returns (string memory) {
    //     if (propertyIndex == 0) return "colorPaletteIndex";
    //     if (propertyIndex == 1) return "patternIndex";
    //     if (propertyIndex == 2) return "shapeIndex";
    //     if (propertyIndex == 3) return "mintGridX";
    //     if (propertyIndex == 4) return "mintGridY";
    //     if (propertyIndex == 5) return "rerollCount";
    //     return "Unknown";
    // }
}
```