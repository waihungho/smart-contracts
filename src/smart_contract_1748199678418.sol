Okay, let's design a smart contract that represents a collaborative, on-chain digital canvas. Users can own "blocks" of this canvas as NFTs, and within their blocks, they can "paint" pixels using a defined color palette. We can add interesting features like block auctions, reveal mechanics, locking, and the ability to mint "snapshot" NFTs of the canvas state.

This concept combines NFTs, on-chain data storage (for pixels), collaborative elements, a simple auction mechanism, and dynamic state changes.

Here's the outline and summary:

**Outline:**

1.  **License and Pragma**
2.  **Imports:** ERC721, ERC721Enumerable (for supply/enumeration), ERC2981 (Royalties), ReentrancyGuard, Ownable.
3.  **Error Definitions**
4.  **Structs:** `Auction` (for block bidding).
5.  **State Variables:**
    *   Canvas dimensions (`canvasWidth`, `canvasHeight`).
    *   Block dimensions (`blockWidth`, `blockHeight`).
    *   Total blocks (`totalBlocks`).
    *   Color Palette (`colorPalette`).
    *   Block data mapping (`blockPixelColors`, `blockRevealed`, `blockLocked`, `blockLastModified`, `blockMetadataURI`).
    *   Auction data mapping (`blockAuctions`).
    *   Mapping for tracking auction proceeds (`auctionProceeds`).
    *   Snapshot NFT counter (`snapshotCounter`).
    *   Snapshot metadata mapping (`snapshotMetadataURI`).
    *   Canvas global metadata URI (`canvasMetadataURI`).
    *   Default royalty information (`defaultRoyaltyRecipient`, `defaultRoyaltyBasisPoints`).
    *   Reentrancy Guard.
    *   Ownable for administrative functions.
6.  **Events:** `BlockPainted`, `BlockRevealed`, `BlockLocked`, `BidPlaced`, `AuctionSettled`, `SnapshotMinted`, `PaletteColorAdded`, `DonationReceived`.
7.  **Modifiers:** `onlyBlockOwner`, `whenBlockNotLocked`, `whenBlockIsRevealed`.
8.  **Constructor:** Initializes canvas, blocks, palette, and owner.
9.  **ERC721 Standard Functions:** (Implemented via inheritance, potentially overridden for custom logic like `tokenURI`).
10. **ERC2981 Standard Function:** `royaltyInfo`.
11. **Core Canvas/Block Interaction Functions:**
    *   `paintPixel`
    *   `bulkPaintPixels`
    *   `revealBlock`
    *   `lockBlock` / `unlockBlock`
    *   `setBlockMetadataURI`
12. **Palette Management Functions:**
    *   `addPaletteColor`
13. **Auction Functions:**
    *   `startBlockAuction`
    *   `placeBid`
    *   `cancelBid`
    *   `finalizeAuction`
    *   `withdrawAuctionProceeds`
14. **Snapshot Functions:**
    *   `mintCanvasSnapshotNFT`
15. **Administrative/Global Functions:**
    *   `setCanvasMetadataURI`
    *   `setDefaultRoyalty`
    *   `donateToCanvas`
    *   `withdrawDonations`
16. **View/Helper Functions:**
    *   `getCanvasDimensions`
    *   `getBlockDimensions`
    *   `getTotalBlocks`
    *   `getColorPalette`
    *   `getBlockPixelColors`
    *   `getBlockRevealedStatus`
    *   `getBlockLockedStatus`
    *   `getBlockLastModified`
    *   `getBlockMetadataURI`
    *   `getCanvasMetadataURI`
    *   `getAuctionInfo`
    *   `getSnapshotMetadataURI`
    *   `getTotalSnapshots`
    *   `coordinateToBlockId`
    *   `blockIdToCoordinate`
    *   `pixelCoordinateToBlockAndPixelIndex`
    *   `getPendingAuctionProceeds`

---

**Function Summary:**

1.  `constructor(uint256 _canvasWidth, uint256 _canvasHeight, uint256 _blockWidth, uint256 _blockHeight, uint24[] memory initialPalette, address initialOwner)`: Initializes the canvas dimensions, block dimensions, mints all block NFTs to the initial owner, and sets the initial color palette.
2.  `paintPixel(uint256 blockId, uint256 pixelIndex, uint8 colorIndex)`: Allows the owner of a block to change the color of a specific pixel within that block using a color from the palette. Requires the block to be revealed and not locked.
3.  `bulkPaintPixels(uint256 blockId, uint256[] memory pixelIndices, uint8[] memory colorIndices)`: A gas-optimized function for a block owner to paint multiple pixels in one transaction. Requires arrays to be of the same length.
4.  `revealBlock(uint256 blockId)`: Allows the contract owner (or potentially block owner, depending on logic) to 'reveal' a block, making it mutable and visible. Can add conditions later (e.g., time passed, payment). Currently owner-only for simple example.
5.  `lockBlock(uint256 blockId)`: Allows the block owner to lock their block temporarily, preventing any pixel changes.
6.  `unlockBlock(uint256 blockId)`: Allows the block owner to unlock their block.
7.  `setBlockMetadataURI(uint256 blockId, string memory uri)`: Allows the block owner to set a metadata URI for their specific block NFT.
8.  `addPaletteColor(uint24 rgb)`: Allows the contract owner to add a new color to the global palette.
9.  `startBlockAuction(uint256 blockId, uint256 minBidAmount, uint64 duration)`: Allows the block owner to put their block up for auction.
10. `placeBid(uint256 blockId) payable`: Allows users to place a bid on a block currently in auction. Automatically refunds the previous highest bidder if outbid.
11. `cancelBid(uint256 blockId)`: Allows the current highest bidder to cancel their bid before the auction ends, if the block owner hasn't accepted it (simple model) or if the auction logic allows. Here, assumes simple auction where bids are locked until finalized. This version cancels only if *they* are the current bidder and auction is still active.
12. `finalizeAuction(uint256 blockId)`: Anyone can call this after an auction ends. It transfers block ownership to the highest bidder and marks the proceeds for withdrawal by the previous owner.
13. `withdrawAuctionProceeds()`: Allows addresses who previously sold blocks via auction to withdraw their accumulated ETH proceeds.
14. `mintCanvasSnapshotNFT(string memory metadataUri)`: Allows anyone to mint a non-transferable (or separate ERC721) NFT representing a snapshot of the entire canvas's current state. The metadata URI would link to off-chain data describing the state. *Self-correction:* Let's simplify; this contract just *records* the snapshot metadata on-chain with an ID. A separate contract/system could mint actual NFTs based on this data. This function mints a *snapshot ID*.
15. `setCanvasMetadataURI(string memory uri)`: Allows the contract owner to set a global metadata URI for the entire canvas project.
16. `setDefaultRoyalty(address recipient, uint96 basisPoints)`: Allows the contract owner to set the default royalty percentage for secondary sales of block NFTs (used by marketplaces implementing ERC2981).
17. `donateToCanvas() payable`: Allows anyone to donate ETH to the contract, potentially for funding future features or community initiatives.
18. `withdrawDonations(address recipient, uint256 amount)`: Allows the contract owner to withdraw donated ETH.
19. `getCanvasDimensions() view`: Returns the width and height of the canvas in pixels.
20. `getBlockDimensions() view`: Returns the width and height of individual blocks in pixels.
21. `getTotalBlocks() view`: Returns the total number of block NFTs in the canvas.
22. `getColorPalette() view`: Returns the array of available colors (RGB uint24 values).
23. `getBlockPixelColors(uint256 blockId) view`: Returns the array of color indices representing the pixels within a specific block.
24. `getBlockRevealedStatus(uint256 blockId) view`: Returns true if the block is revealed, false otherwise.
25. `getBlockLockedStatus(uint256 blockId) view`: Returns true if the block is locked, false otherwise.
26. `getBlockLastModified(uint256 blockId) view`: Returns the timestamp of the last time a pixel was painted in the block.
27. `getBlockMetadataURI(uint256 blockId) view`: Returns the metadata URI for a specific block NFT.
28. `getCanvasMetadataURI() view`: Returns the global metadata URI for the canvas project.
29. `getAuctionInfo(uint256 blockId) view`: Returns the current state of the auction for a specific block (bidder, amount, end time).
30. `getSnapshotMetadataURI(uint256 snapshotId) view`: Returns the metadata URI associated with a specific canvas snapshot ID.
31. `getTotalSnapshots() view`: Returns the total number of canvas snapshots recorded.
32. `coordinateToBlockId(uint256 x, uint256 y) view`: Helper function: converts global pixel coordinates (x, y) to the corresponding block ID.
33. `blockIdToCoordinate(uint256 blockId) view`: Helper function: converts a block ID to the global pixel coordinates of its top-left corner.
34. `pixelCoordinateToBlockAndPixelIndex(uint256 x, uint256 y) view`: Helper function: converts global pixel coordinates (x, y) to the block ID and the local pixel index within that block.
35. `getPendingAuctionProceeds(address owner) view`: Returns the amount of ETH pending withdrawal for a specific address from finalized auctions.
36. `royaltyInfo(uint256 tokenId, uint256 salePrice) view`: Standard ERC2981 function. Returns the recipient and amount of royalties for a given token sale. (TokenId here is the blockId).
37. `supportsInterface(bytes4 interfaceId) view`: Standard ERC165 function to declare supported interfaces (ERC721, ERC2981).

*(Note: Functions like `balanceOf`, `ownerOf`, `transferFrom`, `approve`, etc., are inherited from ERC721 base implementation and are also part of the contract's capabilities)*

Let's write the Solidity code based on this.

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol"; // To get total supply and enumerate
import "@openzeppelin/contracts/token/common/ERC2981.sol"; // For NFT Royalties
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

// Outline:
// 1. License and Pragma
// 2. Imports: ERC721, ERC721Enumerable, ERC2981, ReentrancyGuard, Ownable, Counters, SafeMath
// 3. Error Definitions
// 4. Structs: Auction
// 5. State Variables: Canvas/Block dims, Total blocks, Palette, Block data mappings, Auction data, Proceeds, Snapshots, Global metadata, Royalty info, ReentrancyGuard, Ownable
// 6. Events: BlockPainted, BlockRevealed, BlockLocked, BidPlaced, AuctionSettled, SnapshotMinted, PaletteColorAdded, DonationReceived
// 7. Modifiers: onlyBlockOwner, whenBlockNotLocked, whenBlockIsRevealed
// 8. Constructor: Initialize canvas, blocks, palette, owner.
// 9. ERC721 Standard Functions: (Inherited/Overridden)
// 10. ERC2981 Standard Function: royaltyInfo, supportsInterface
// 11. Core Canvas/Block Interaction Functions: paintPixel, bulkPaintPixels, revealBlock, lockBlock/unlockBlock, setBlockMetadataURI
// 12. Palette Management Functions: addPaletteColor
// 13. Auction Functions: startBlockAuction, placeBid, cancelBid, finalizeAuction, withdrawAuctionProceeds, getAuctionInfo, getPendingAuctionProceeds
// 14. Snapshot Functions: mintCanvasSnapshotNFT, getSnapshotMetadataURI, getTotalSnapshots
// 15. Administrative/Global Functions: setCanvasMetadataURI, setDefaultRoyalty, donateToCanvas, withdrawDonations
// 16. View/Helper Functions: Various getters and coordinate converters

// Function Summary:
// 1. constructor: Initializes the canvas, blocks (NFTs), palette, and contract owner.
// 2. paintPixel: Changes a single pixel color in an owned block.
// 3. bulkPaintPixels: Changes multiple pixel colors efficiently in an owned block.
// 4. revealBlock: Marks a block as revealed (e.g., for dynamic visibility).
// 5. lockBlock: Prevents pixel changes in a block.
// 6. unlockBlock: Allows pixel changes in a locked block.
// 7. setBlockMetadataURI: Sets metadata URI for a specific block NFT.
// 8. addPaletteColor: Adds a new color to the global palette (Admin).
// 9. startBlockAuction: Puts an owned block up for auction.
// 10. placeBid: Places a bid on an auctioned block.
// 11. cancelBid: Cancels your outstanding bid on a block.
// 12. finalizeAuction: Finalizes an ended auction, transfers ownership and marks proceeds.
// 13. withdrawAuctionProceeds: Allows sellers to withdraw ETH from finalized auctions.
// 14. mintCanvasSnapshotNFT: Records a snapshot of the canvas state with metadata.
// 15. setCanvasMetadataURI: Sets global metadata URI for the canvas project (Admin).
// 16. setDefaultRoyalty: Sets default royalty for block NFTs (Admin).
// 17. donateToCanvas: Allows users to donate ETH.
// 18. withdrawDonations: Allows admin to withdraw donations.
// 19. getCanvasDimensions: Returns canvas size.
// 20. getBlockDimensions: Returns block size.
// 21. getTotalBlocks: Returns total number of blocks (NFTs).
// 22. getColorPalette: Returns all available palette colors.
// 23. getBlockPixelColors: Returns pixel data for a block.
// 24. getBlockRevealedStatus: Returns if a block is revealed.
// 25. getBlockLockedStatus: Returns if a block is locked.
// 26. getBlockLastModified: Returns last modified timestamp for a block.
// 27. getBlockMetadataURI: Returns metadata URI for a block.
// 28. getCanvasMetadataURI: Returns global canvas metadata URI.
// 29. getAuctionInfo: Returns current auction details for a block.
// 30. getSnapshotMetadataURI: Returns metadata URI for a snapshot.
// 31. getTotalSnapshots: Returns total number of recorded snapshots.
// 32. coordinateToBlockId: Converts global pixel coords to block ID.
// 33. blockIdToCoordinate: Converts block ID to top-left global pixel coords.
// 34. pixelCoordinateToBlockAndPixelIndex: Converts global pixel coords to block ID and local pixel index.
// 35. getPendingAuctionProceeds: Returns withdrawable auction ETH for an address.
// 36. royaltyInfo: Standard ERC2981 royalty lookup.
// 37. supportsInterface: Standard ERC165 interface support check.
// (Plus standard ERC721 functions: balanceOf, ownerOf, getApproved, isApprovedForAll, approve, setApprovalForAll, transferFrom, safeTransferFrom)

contract CryptoCanvas is ERC721Enumerable, ERC2981, ReentrancyGuard, Ownable {
    using SafeMath for uint256;
    using Counters for Counters.Counter;

    // --- Error Definitions ---
    error InvalidDimensions();
    error InvalidBlockId();
    error PixelIndexOutOfBlockBounds();
    error InvalidColorIndex();
    error BlockNotRevealed();
    error BlockLocked();
    error AuctionAlreadyExists();
    error AuctionNotActive();
    error BidTooLow(uint256 minAmount);
    error NotCurrentBidder();
    error AuctionStillActive();
    error AuctionHasNoBidder();
    error NoProceedsToWithdraw();
    error InvalidRoyaltyBasisPoints();
    error InvalidWithdrawalAmount();

    // --- State Variables ---
    uint256 public immutable canvasWidth;
    uint256 public immutable canvasHeight;
    uint256 public immutable blockWidth;
    uint256 public immutable blockHeight;
    uint256 public immutable totalBlocks;

    // Palette: Array of RGB colors stored as uint24 (3 bytes). Max 2^24 colors.
    // We use uint8 as index into this palette for pixel data to save gas. Max 256 colors.
    uint24[] private _colorPalette;

    // Block Data
    // Mapping from block ID to an array of palette color indices.
    // The size of the array is blockWidth * blockHeight.
    mapping(uint256 => uint8[]) private _blockPixelColors;
    mapping(uint256 => bool) private _blockRevealed;
    mapping(uint256 => bool) private _blockLocked;
    mapping(uint256 => uint64) private _blockLastModifiedTimestamp; // Using uint64 for timestamp fits block.timestamp
    mapping(uint256 => string) private _blockMetadataURIs; // ERC721 tokenURI will likely point here

    // Auction Data
    struct Auction {
        address payable seller;
        uint256 minBidAmount;
        uint256 currentBid;
        address bidder;
        uint64 endTime;
        bool active;
    }
    mapping(uint256 => Auction) private _blockAuctions;
    mapping(address => uint256) private _auctionProceeds; // ETH owed to sellers

    // Snapshot Data (Recording canvas states)
    Counters.Counter private _snapshotCounter;
    mapping(uint256 => string) private _snapshotMetadataURIs;

    // Global Canvas Data
    string private _canvasMetadataURI;

    // Default Royalty Info
    address private _defaultRoyaltyRecipient;
    uint96 private _defaultRoyaltyBasisPoints;

    // --- Events ---
    event BlockPainted(uint256 indexed blockId, address indexed by, uint64 timestamp);
    event BlockRevealed(uint256 indexed blockId, uint64 timestamp);
    event BlockLocked(uint256 indexed blockId, bool locked, uint64 timestamp);
    event BidPlaced(uint256 indexed blockId, address indexed bidder, uint256 amount, uint64 endTime);
    event AuctionSettled(uint256 indexed blockId, address indexed winner, uint256 finalBid, uint64 timestamp);
    event SnapshotMinted(uint256 indexed snapshotId, address indexed minter, string metadataUri);
    event PaletteColorAdded(uint8 indexed colorIndex, uint24 rgb);
    event DonationReceived(address indexed donor, uint256 amount);
    event DonationWithdrawn(address indexed recipient, uint256 amount);
    event AuctionProceedsWithdrawn(address indexed seller, uint256 amount);

    // --- Modifiers ---
    modifier onlyBlockOwner(uint256 blockId) {
        if (ownerOf(blockId) != msg.sender) {
            revert ERC721OwnableInvalidWithOwner(msg.sender, ownerOf(blockId)); // Use ERC721 standard error if possible
        }
        _;
    }

    modifier whenBlockNotLocked(uint256 blockId) {
        if (_blockLocked[blockId]) {
            revert BlockLocked();
        }
        _;
    }

    modifier whenBlockIsRevealed(uint256 blockId) {
        if (!_blockRevealed[blockId]) {
            revert BlockNotRevealed();
        }
        _;
    }

    // --- Constructor ---
    constructor(
        uint256 _canvasWidth,
        uint256 _canvasHeight,
        uint256 _blockWidth,
        uint256 _blockHeight,
        uint24[] memory initialPalette,
        address initialOwner
    )
        ERC721("CryptoCanvasBlock", "CCBLOCK") // ERC721Enumerable will append these
        ERC721Enumerable() // Add enumerable capabilities
        ERC2981() // Add royalty capabilities
        Ownable(msg.sender)
    {
        if (_canvasWidth == 0 || _canvasHeight == 0 || _blockWidth == 0 || _blockHeight == 0 ||
            _canvasWidth % _blockWidth != 0 || _canvasHeight % _blockHeight != 0) {
            revert InvalidDimensions();
        }

        canvasWidth = _canvasWidth;
        canvasHeight = _canvasHeight;
        blockWidth = _blockWidth;
        blockHeight = _blockHeight;

        uint256 blocksPerRow = canvasWidth / blockWidth;
        uint256 blocksPerColumn = canvasHeight / blockHeight;
        totalBlocks = blocksPerRow * blocksPerColumn;

        // Initialize palette
        _colorPalette = initialPalette;
        // Check palette size limit
        if (_colorPalette.length > 256) {
             // This check should ideally be before assigning, or adjust _blockPixelColors to use uint16/uint32
             // Sticking to uint8 indexing limits palette to 256 colors.
             revert InvalidColorIndex(); // Re-using error, should be InvalidPaletteSize or similar
        }


        // Mint all blocks to the initial owner
        for (uint256 i = 0; i < totalBlocks; ++i) {
            _safeMint(initialOwner, i);
            // Initialize pixel data with default color (e.g., first color in palette or transparent/0)
            _blockPixelColors[i] = new uint8[](blockWidth * blockHeight); // Defaults to 0s
            _blockRevealed[i] = false; // Start as unrevealed
            _blockLocked[i] = false; // Start unlocked
            _blockLastModifiedTimestamp[i] = uint64(block.timestamp);
        }

        // Set a default royalty recipient (can be changed later)
        _defaultRoyaltyRecipient = address(0); // Set to zero initially
        _defaultRoyaltyBasisPoints = 0; // Set to zero initially

        // Transfer ownership if initialOwner is different from msg.sender
        // This allows deploying and transferring ownership in one step if desired.
        if (msg.sender != initialOwner) {
             transferOwnership(initialOwner);
        } else {
             // If initialOwner is msg.sender, keep msg.sender as owner.
             // Ownable constructor already sets msg.sender as owner.
        }
    }

    // --- ERC721 Overrides ---
    // ERC721Enumerable needs _beforeTokenTransfer hook for index tracking
    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    // ERC721Enumerable needs these overrides
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable, ERC2981) // Add ERC2981 support check
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    // tokenURI is usually external metadata, but we can link to a service
    // or compose it using on-chain data + _blockMetadataURIs
    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721)
        returns (string memory)
    {
        if (!_exists(tokenId)) revert ERC721NonexistentToken(tokenId);

        // Construct a URI that points to metadata for this specific block ID.
        // This could be a base URI + block ID, and an off-chain service
        // would generate the JSON metadata based on the block's state.
        string memory base = _baseURI();
        string memory custom = _blockMetadataURIs[tokenId];

        if (bytes(custom).length > 0) {
             return string(abi.encodePacked(base, tokenId.toString(), "/", custom));
        } else {
             return string(abi.encodePacked(base, tokenId.toString()));
        }
    }

     // Simple base URI - often set by owner
    string private _baseTokenURI;

    function _baseURI() internal view override returns (string memory) {
        return _baseTokenURI;
    }

    // Set base URI (Admin function)
    function setBaseTokenURI(string memory baseURI) public onlyOwner {
        _baseTokenURI = baseURI;
    }


    // --- ERC2981 Royalty Implementation ---
    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        public
        view
        override(ERC2981)
        returns (address receiver, uint256 royaltyAmount)
    {
        // We use a default royalty for all blocks, but could implement per-token logic if needed.
        receiver = _defaultRoyaltyRecipient;
        // Calculate royalty amount: (salePrice * basisPoints) / 10000
        royaltyAmount = salePrice.mul(_defaultRoyaltyBasisPoints).div(10000);
        return (receiver, royaltyAmount);
    }

    // --- Core Canvas/Block Interaction Functions ---

    // 2. paintPixel: Changes a single pixel color in an owned block.
    function paintPixel(uint256 blockId, uint256 pixelIndex, uint8 colorIndex)
        external
        onlyBlockOwner(blockId)
        whenBlockIsRevealed(blockId)
        whenBlockNotLocked(blockId)
    {
        if (blockId >= totalBlocks) revert InvalidBlockId();
        if (pixelIndex >= blockWidth * blockHeight) revert PixelIndexOutOfBlockBounds();
        if (colorIndex >= _colorPalette.length && colorIndex != 0) { // Allow 0 index if palette is empty or for default/transparent
             revert InvalidColorIndex();
        }

        _blockPixelColors[blockId][pixelIndex] = colorIndex;
        _blockLastModifiedTimestamp[blockId] = uint64(block.timestamp);

        emit BlockPainted(blockId, msg.sender, uint64(block.timestamp));
    }

    // 3. bulkPaintPixels: Changes multiple pixel colors efficiently in an owned block.
    function bulkPaintPixels(uint256 blockId, uint256[] memory pixelIndices, uint8[] memory colorIndices)
        external
        onlyBlockOwner(blockId)
        whenBlockIsRevealed(blockId)
        whenBlockNotLocked(blockId)
    {
        if (blockId >= totalBlocks) revert InvalidBlockId();
        if (pixelIndices.length != colorIndices.length) revert InvalidDimensions(); // Or a more specific error
        uint256 blockPixelCount = blockWidth * blockHeight;

        for (uint256 i = 0; i < pixelIndices.length; ++i) {
            if (pixelIndices[i] >= blockPixelCount) revert PixelIndexOutOfBlockBounds();
            if (colorIndices[i] >= _colorPalette.length && colorIndices[i] != 0) revert InvalidColorIndex(); // Allow 0 index
            _blockPixelColors[blockId][pixelIndices[i]] = colorIndices[i];
        }

        _blockLastModifiedTimestamp[blockId] = uint64(block.timestamp);
        emit BlockPainted(blockId, msg.sender, uint64(block.timestamp)); // Maybe a separate event for bulk?
    }

    // 4. revealBlock: Marks a block as revealed. Admin-only for now.
    function revealBlock(uint256 blockId) public onlyOwner {
        if (blockId >= totalBlocks) revert InvalidBlockId();
        if (_blockRevealed[blockId]) return; // Already revealed

        _blockRevealed[blockId] = true;
        emit BlockRevealed(blockId, uint64(block.timestamp));
    }

    // 5. lockBlock: Prevents pixel changes in a block. Block owner only.
    function lockBlock(uint256 blockId) external onlyBlockOwner(blockId) {
        if (blockId >= totalBlocks) revert InvalidBlockId();
        if (_blockLocked[blockId]) return; // Already locked

        _blockLocked[blockId] = true;
        emit BlockLocked(blockId, true, uint64(block.timestamp));
    }

    // 6. unlockBlock: Allows pixel changes in a locked block. Block owner only.
    function unlockBlock(uint256 blockId) external onlyBlockOwner(blockId) {
        if (blockId >= totalBlocks) revert InvalidBlockId();
        if (!_blockLocked[blockId]) return; // Already unlocked

        _blockLocked[blockId] = false;
        emit BlockLocked(blockId, false, uint64(block.timestamp));
    }

    // 7. setBlockMetadataURI: Sets metadata URI for a specific block NFT. Block owner only.
    function setBlockMetadataURI(uint256 blockId, string memory uri) external onlyBlockOwner(blockId) {
         if (blockId >= totalBlocks) revert InvalidBlockId();
        _blockMetadataURIs[blockId] = uri;
    }

    // --- Palette Management Functions ---

    // 8. addPaletteColor: Adds a new color to the global palette. Admin only.
    function addPaletteColor(uint24 rgb) public onlyOwner {
        if (_colorPalette.length >= 256) {
             // Palette is full for uint8 indexing
             revert InvalidPaletteSize(); // Custom error needed here
        }
        _colorPalette.push(rgb);
        emit PaletteColorAdded(uint8(_colorPalette.length - 1), rgb);
    }

    // --- Auction Functions ---

    // 9. startBlockAuction: Puts an owned block up for auction. Block owner only.
    function startBlockAuction(uint256 blockId, uint256 minBidAmount, uint64 duration)
        external
        onlyBlockOwner(blockId)
    {
        if (blockId >= totalBlocks) revert InvalidBlockId();
        if (_blockAuctions[blockId].active) revert AuctionAlreadyExists();
        if (duration == 0) revert InvalidDimensions(); // Use a better error

        _blockAuctions[blockId] = Auction({
            seller: payable(msg.sender),
            minBidAmount: minBidAmount,
            currentBid: 0,
            bidder: address(0),
            endTime: uint64(block.timestamp) + duration,
            active: true
        });

        emit BidPlaced(blockId, address(0), 0, _blockAuctions[blockId].endTime); // Initial bid is 0
    }

    // 10. placeBid: Places a bid on an auctioned block. Payable.
    function placeBid(uint256 blockId) external payable nonReentrant {
        Auction storage auction = _blockAuctions[blockId];
        if (!auction.active || block.timestamp >= auction.endTime) revert AuctionNotActive();
        if (msg.value <= auction.currentBid || msg.value < auction.minBidAmount) {
             revert BidTooLow(auction.currentBid > 0 ? auction.currentBid : auction.minBidAmount);
        }

        // Refund previous bidder
        if (auction.bidder != address(0)) {
             (bool success, ) = payable(auction.bidder).call{value: auction.currentBid}("");
             require(success, "Refund failed"); // Simple check, can improve
        }

        // Place new bid
        auction.currentBid = msg.value;
        auction.bidder = msg.sender;

        emit BidPlaced(blockId, msg.sender, msg.value, auction.endTime);
    }

    // 11. cancelBid: Allows the current highest bidder to cancel their bid.
    // Note: In a simple auction, bids are usually locked. This implementation
    // allows cancellation only by the *current* bidder if the auction is *still active*.
    // A more common pattern requires the seller to accept/cancel, or only allows withdrawal
    // of *outbid* amounts. This provides a specific cancellation mechanic.
    function cancelBid(uint256 blockId) external nonReentrant {
        Auction storage auction = _blockAuctions[blockId];
        if (!auction.active || block.timestamp >= auction.endTime) revert AuctionNotActive();
        if (auction.bidder != msg.sender) revert NotCurrentBidder();
        if (auction.currentBid == 0) return; // No bid to cancel

        uint256 bidAmount = auction.currentBid;

        // Clear bid
        auction.currentBid = 0;
        auction.bidder = address(0);

        // Refund bidder
        (bool success, ) = payable(msg.sender).call{value: bidAmount}("");
        require(success, "Refund failed");

        emit BidPlaced(blockId, address(0), 0, auction.endTime); // Reset bid to 0
    }


    // 12. finalizeAuction: Finalizes an ended auction. Anyone can call after endTime.
    function finalizeAuction(uint256 blockId) external nonReentrant {
        Auction storage auction = _blockAuctions[blockId];
        if (!auction.active) revert AuctionNotActive();
        if (block.timestamp < auction.endTime) revert AuctionStillActive();
        if (auction.bidder == address(0) || auction.currentBid == 0) revert AuctionHasNoBidder();
         // Check if bid meets minimum (should be guaranteed by placeBid logic, but double check)
        if (auction.currentBid < auction.minBidAmount) revert BidTooLow(auction.minBidAmount);


        address winner = auction.bidder;
        uint256 finalBid = auction.currentBid;
        address payable seller = auction.seller;

        // Mark auction as inactive BEFORE transfers to prevent reentrancy
        auction.active = false;
        // Clear auction data
        delete _blockAuctions[blockId];


        // Transfer block ownership (ERC721 transfer)
        _safeTransfer(seller, winner, blockId);

        // Record proceeds for seller to withdraw later
        _auctionProceeds[seller] = _auctionProceeds[seller].add(finalBid);

        emit AuctionSettled(blockId, winner, finalBid, uint64(block.timestamp));
        emit AuctionProceedsWithdrawn(seller, finalBid); // Emit withdrawal event immediately (conceptually)
                                                         // The actual ETH is held until withdrawAuctionProceeds is called.
    }

    // 13. withdrawAuctionProceeds: Allows sellers to withdraw ETH from finalized auctions.
    function withdrawAuctionProceeds() external nonReentrant {
        uint256 amount = _auctionProceeds[msg.sender];
        if (amount == 0) revert NoProceedsToWithdraw();

        _auctionProceeds[msg.sender] = 0;

        (bool success, ) = payable(msg.sender).call{value: amount}("");
        if (!success) {
            // If transfer fails, revert and put the amount back
            _auctionProceeds[msg.sender] = amount;
            revert("Withdrawal failed"); // Use a custom error
        }

        emit AuctionProceedsWithdrawn(msg.sender, amount);
    }

    // 35. getPendingAuctionProceeds: Returns withdrawable auction ETH for an address.
    function getPendingAuctionProceeds(address owner) external view returns (uint256) {
        return _auctionProceeds[owner];
    }

    // --- Snapshot Functions ---

    // 14. mintCanvasSnapshotNFT: Records a snapshot of the canvas state with metadata.
    // This function only records the event and metadata on-chain.
    // A separate system would generate the image/data and host the metadata.
    function mintCanvasSnapshotNFT(string memory metadataUri) external {
        uint256 snapshotId = _snapshotCounter.current();
        _snapshotCounter.increment();

        _snapshotMetadataURIs[snapshotId] = metadataUri;

        // Could potentially mint a separate ERC721 here representing the snapshot
        // For simplicity, we just record the ID and URI in this contract.

        emit SnapshotMinted(snapshotId, msg.sender, metadataUri);
    }

    // 30. getSnapshotMetadataURI: Returns metadata URI for a snapshot.
    function getSnapshotMetadataURI(uint256 snapshotId) external view returns (string memory) {
        if (snapshotId >= _snapshotCounter.current()) revert InvalidBlockId(); // Use a better error
        return _snapshotMetadataURIs[snapshotId];
    }

    // 31. getTotalSnapshots: Returns total number of recorded snapshots.
    function getTotalSnapshots() external view returns (uint256) {
        return _snapshotCounter.current();
    }

    // --- Administrative/Global Functions ---

    // 15. setCanvasMetadataURI: Sets global metadata URI for the canvas project (Admin).
    function setCanvasMetadataURI(string memory uri) public onlyOwner {
        _canvasMetadataURI = uri;
    }

    // 16. setDefaultRoyalty: Sets default royalty for block NFTs (Admin).
    function setDefaultRoyalty(address recipient, uint96 basisPoints) public onlyOwner {
         if (basisPoints > 10000) revert InvalidRoyaltyBasisPoints(); // 100% is 10000 basis points
        _defaultRoyaltyRecipient = recipient;
        _defaultRoyaltyBasisPoints = basisPoints;
    }

    // 17. donateToCanvas: Allows users to donate ETH.
    function donateToCanvas() external payable {
        if (msg.value == 0) revert InvalidWithdrawalAmount(); // Re-using error, should be InvalidDonationAmount
        emit DonationReceived(msg.sender, msg.value);
    }

    // 18. withdrawDonations: Allows admin to withdraw donations.
    function withdrawDonations(address recipient, uint256 amount) external onlyOwner nonReentrant {
        if (amount == 0) revert InvalidWithdrawalAmount();
        if (address(this).balance < amount) revert InvalidWithdrawalAmount(); // Not enough balance

        (bool success, ) = payable(recipient).call{value: amount}("");
        require(success, "Withdrawal failed");

        emit DonationWithdrawn(recipient, amount);
    }


    // --- View/Helper Functions ---

    // 19. getCanvasDimensions: Returns canvas size.
    function getCanvasDimensions() external view returns (uint256 width, uint256 height) {
        return (canvasWidth, canvasHeight);
    }

    // 20. getBlockDimensions: Returns block size.
    function getBlockDimensions() external view returns (uint256 width, uint256 height) {
        return (blockWidth, blockHeight);
    }

    // 21. getTotalBlocks: Returns total number of blocks (NFTs).
    function getTotalBlocks() external view returns (uint256) {
        return totalBlocks;
    }

    // 22. getColorPalette: Returns all available palette colors.
    function getColorPalette() external view returns (uint24[] memory) {
        return _colorPalette;
    }

    // 23. getBlockPixelColors: Returns pixel data for a block.
    function getBlockPixelColors(uint256 blockId) external view returns (uint8[] memory) {
        if (blockId >= totalBlocks) revert InvalidBlockId();
        return _blockPixelColors[blockId];
    }

    // 24. getBlockRevealedStatus: Returns if a block is revealed.
    function getBlockRevealedStatus(uint256 blockId) external view returns (bool) {
        if (blockId >= totalBlocks) revert InvalidBlockId();
        return _blockRevealed[blockId];
    }

    // 25. getBlockLockedStatus: Returns if a block is locked.
    function getBlockLockedStatus(uint256 blockId) external view returns (bool) {
        if (blockId >= totalBlocks) revert InvalidBlockId();
        return _blockLocked[blockId];
    }

    // 26. getBlockLastModified: Returns last modified timestamp for a block.
    function getBlockLastModified(uint256 blockId) external view returns (uint64) {
        if (blockId >= totalBlocks) revert InvalidBlockId();
        return _blockLastModifiedTimestamp[blockId];
    }

    // 27. getBlockMetadataURI: Returns metadata URI for a block.
    function getBlockMetadataURI(uint256 blockId) external view returns (string memory) {
         if (blockId >= totalBlocks) revert InvalidBlockId();
        return _blockMetadataURIs[blockId];
    }

    // 28. getCanvasMetadataURI: Returns global canvas metadata URI.
    function getCanvasMetadataURI() external view returns (string memory) {
        return _canvasMetadataURI;
    }

    // 29. getAuctionInfo: Returns current auction details for a block.
    function getAuctionInfo(uint256 blockId) external view returns (Auction memory) {
        if (blockId >= totalBlocks) revert InvalidBlockId();
        return _blockAuctions[blockId];
    }

    // 32. coordinateToBlockId: Converts global pixel coords (top-left origin) to block ID.
    function coordinateToBlockId(uint256 x, uint256 y) external view returns (uint256) {
        if (x >= canvasWidth || y >= canvasHeight) revert InvalidDimensions(); // Use a better error

        uint256 blockX = x / blockWidth;
        uint256 blockY = y / blockHeight;
        uint256 blocksPerRow = canvasWidth / blockWidth;

        return blockY * blocksPerRow + blockX;
    }

    // 33. blockIdToCoordinate: Converts block ID to top-left global pixel coords.
    function blockIdToCoordinate(uint256 blockId) external view returns (uint256 x, uint256 y) {
        if (blockId >= totalBlocks) revert InvalidBlockId();

        uint256 blocksPerRow = canvasWidth / blockWidth;
        uint256 blockY = blockId / blocksPerRow;
        uint256 blockX = blockId % blocksPerRow;

        x = blockX * blockWidth;
        y = blockY * blockHeight;
    }

    // 34. pixelCoordinateToBlockAndPixelIndex: Converts global pixel coords to block ID and local pixel index.
    function pixelCoordinateToBlockAndPixelIndex(uint256 x, uint256 y) external view returns (uint256 blockId, uint256 pixelIndex) {
         if (x >= canvasWidth || y >= canvasHeight) revert InvalidDimensions(); // Use a better error

        blockId = coordinateToBlockId(x, y);

        // Coordinates within the block
        uint256 localX = x % blockWidth;
        uint256 localY = y % blockHeight;

        pixelIndex = localY * blockWidth + localX;
    }


    // --- Internal/Private Helpers (if needed, not counted in the 20+ public list) ---
    // Example: Internal version of coordinateToBlockId, etc. Not strictly needed if publics suffice.
}
```

**Explanation and Advanced Concepts:**

1.  **On-Chain State for Visuals:** The core concept is storing the pixel data (`_blockPixelColors`) directly on-chain, associated with NFTs. While storing every pixel of a large image is prohibitive, storing indexed colors for smaller blocks owned by NFTs is feasible and interesting.
2.  **Multi-Layered Asset:** The canvas is a single conceptual asset, but its control and modification are distributed among owners of its constituent "block" NFTs. This creates a collaborative or competitive dynamic.
3.  **Dynamic NFTs:** The block NFTs (`CCBLOCK`) are dynamic. Their associated on-chain data (`_blockPixelColors`, `_blockRevealed`, `_blockLocked`, `_blockLastModifiedTimestamp`) changes over time based on user interaction. The `tokenURI` could be made to reflect this changing state.
4.  **Integrated Auction System:** A simple Dutch or English auction is built directly into the contract for transferring block ownership, without relying on external marketplaces (though external marketplaces could still list these NFTs and use the `royaltyInfo`). It includes bidding, cancellation, and finalization.
5.  **Palette System:** Using a color palette (`_colorPalette`) and storing only the `uint8` index per pixel significantly reduces storage costs compared to storing full RGB (`uint24` or `uint256`) for every pixel.
6.  **Reveal Mechanism:** The `_blockRevealed` status adds a dynamic element. Blocks can start hidden and be revealed later, perhaps based on time, a milestone, or a separate user action/payment.
7.  **Locking Mechanism:** The `_blockLocked` status allows block owners to temporarily freeze their block, protecting their art/design from being painted over.
8.  **Snapshot Recording:** The `mintCanvasSnapshotNFT` function doesn't mint a traditional image NFT itself, but records a timestamp and metadata URI on-chain. This allows for creating a history of the canvas state, and external services can generate visuals for these historical snapshots using the recorded on-chain pixel data from that time (retrievable via view functions if the contract state was versioned, or by querying past events/state).
9.  **Gas Optimization:** Using `uint8` for color indices, `uint64` for timestamps, storing pixel data in arrays per block rather than one massive canvas array, and providing `bulkPaintPixels` are attempts at mitigating the high cost of on-chain storage and state changes.
10. **ERC2981 Royalties:** Standard implementation allows marketplaces to respect creator royalties on secondary sales of the block NFTs.
11. **ReentrancyGuard:** Essential for safe handling of ETH transfers in the auction and withdrawal functions.
12. **Coordinate Helpers:** Functions to convert between global pixel coordinates, block IDs, and local pixel indices make it easier for front-ends or off-chain systems to interact with the canvas data.

This contract is a relatively complex example demonstrating several advanced concepts beyond a simple token or standard NFT mint. It represents a shared, dynamic digital asset governed by individual NFT ownership and rules enforced on-chain.