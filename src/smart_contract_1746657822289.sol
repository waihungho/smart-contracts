Okay, here is a smart contract concept called "EternalCanvas" that combines elements of on-chain generative art, dynamic NFTs, ownership, and decentralized governance through palette proposals. It aims for creativity and uses several mappings and custom logic to differentiate itself from standard templates.

**Concept:** The contract manages a fixed-size digital canvas (a grid of pixels). Each pixel is represented by a unique ERC-721 token. Owners of these pixel tokens can change the color of their owned pixel. The canvas state is stored entirely on-chain. The contract includes features like:
1.  **On-chain Ownership & Painting:** ERC-721 tokens representing pixels that can be painted by their owners.
2.  **On-chain Palettes:** Pre-defined and community-proposed color palettes stored and managed on-chain.
3.  **Dynamic Pixels:** Pixels "decay" over time if not repainted, potentially becoming reclaimable by others.
4.  **Generative Elements:** Palettes or initial canvas state could have generative aspects (though simplified here). On-chain metadata generation.
5.  **Decentralized Palette Governance:** Users can propose new color palettes, and a simple voting mechanism allows approval (managed by a 'Governor' address in this simplified example, could be a DAO).
6.  **On-chain Metadata:** Generates ERC-721 metadata JSON directly on-chain containing pixel state.

**Outline:**

1.  **Contract Definition:** Inherits minimal ERC-721 functions implemented manually.
2.  **Constants:** Canvas dimensions, decay threshold.
3.  **State Variables:**
    *   Pixel data mapping (`tokenId` to `PixelData` struct).
    *   Palette data mapping (`paletteId` to `Palette` struct).
    *   Palette proposal data mapping (`proposalId` to `PaletteProposal` struct).
    *   Voting status mapping (`proposalId` => `voterAddress` => `voted?`).
    *   Counts for palettes, proposals, minted tokens.
    *   Current active palette ID.
    *   Governor address.
    *   Standard ERC-721 mappings (`_owners`, `_balances`, `_tokenApprovals`, `_operatorApprovals`).
4.  **Structs:** `PixelData`, `Palette`, `PaletteProposal`.
5.  **Events:** For key actions like minting, painting, palette changes, proposals, voting, decay.
6.  **ERC-721 Core Functions:** Implement necessary public/external functions (`balanceOf`, `ownerOf`, `transferFrom`, `safeTransferFrom`, etc.) and internal helpers (`_safeMint`, `_burn`).
7.  **Canvas & Pixel Management Functions:** Minting, painting, getting pixel data, coordinate conversions.
8.  **Palette Management Functions:** Defining, selecting, getting palettes.
9.  **Dynamic & Decay Functions:** Checking decay status, refreshing pixels, reclaiming decayed pixels.
10. **Palette Governance Functions:** Proposing palettes, voting on proposals, executing proposals.
11. **Metadata Function:** Generating on-chain token URI.
12. **View/Helper Functions:** Getting counts, dimensions, checking ownership, etc.
13. **Internal Helpers:** Coordinate calculations, access control checks.

**Function Summary:**

1.  `constructor(uint256 canvasWidth, uint256 canvasHeight, address governorAddress)`: Initializes canvas dimensions, governor, and base ERC721.
2.  `tokenToCoordinates(uint256 tokenId)`: Converts a token ID to (x, y) coordinates.
3.  `coordinatesToToken(uint256 x, uint256 y)`: Converts (x, y) coordinates to a token ID.
4.  `getCanvasDimensions()`: Returns the canvas width and height.
5.  `isPixelOwned(uint256 x, uint256 y)`: Checks if a pixel at given coordinates is owned.
6.  `mintPixel(uint256 x, uint256 y)`: Mints the pixel token at (x, y) to the caller, if unowned.
7.  `getPixelData(uint256 tokenId)`: Returns the color, last painted time, and minted time for a pixel.
8.  `getPixelColor(uint256 tokenId)`: Returns the color of a pixel.
9.  `paintPixel(uint256 tokenId, bytes3 color)`: Allows the owner or approved address to paint a pixel with any color.
10. `definePalette(string calldata name, bytes3[] calldata colors)`: Governor defines a new official color palette.
11. `selectActivePalette(uint256 paletteId)`: Governor selects the palette currently available for `paintPixelWithPalette`.
12. `paintPixelWithPalette(uint256 tokenId, uint256 paletteColorIndex)`: Allows the owner or approved address to paint a pixel using a color from the active palette.
13. `getPaletteColors(uint256 paletteId)`: Returns the colors in a specific palette.
14. `getCurrentPaletteId()`: Returns the ID of the currently active palette.
15. `checkPixelDecay(uint256 tokenId)`: Checks if a pixel has decayed (passed the threshold since last painted).
16. `refreshPixel(uint256 tokenId)`: Resets the decay timer for a pixel (only owner/approved).
17. `reclaimDecayedPixel(uint256 tokenId)`: Allows anyone to claim ownership of a pixel that has decayed past a certain extended period.
18. `proposePalette(string calldata name, bytes3[] calldata colors)`: Allows any user to propose a new color palette for voting.
19. `voteOnPalette(uint256 proposalId, bool vote)`: Allows the Governor (or potentially token holders in a more complex setup) to vote on a palette proposal.
20. `executePaletteProposal(uint256 proposalId)`: Governor executes a palette proposal if it has passed voting criteria.
21. `getTokenURI(uint256 tokenId)`: Generates and returns an on-chain data URI for the pixel's metadata.
22. `burnPixel(uint256 tokenId)`: Allows the owner to burn their pixel token, resetting its state.
23. `getDecayThreshold()`: Returns the current decay threshold time.
24. `getPaletteCount()`: Returns the total number of defined palettes.
25. `getPaletteProposalCount()`: Returns the total number of palette proposals.
26. `getPaletteProposal(uint256 proposalId)`: Returns details of a specific palette proposal.
27. `getPaletteProposalVoteCount(uint256 proposalId)`: Returns the current vote counts for a proposal.
28. `isGovernor(address account)`: Checks if an address is the Governor.
    *(Note: Standard ERC721 functions like `balanceOf`, `ownerOf`, `getApproved`, `isApprovedForAll` also count towards the function total, bringing it well over 20)*.

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title EternalCanvas
 * @dev An on-chain collaborative pixel art canvas where each pixel is a dynamic NFT.
 *      Features on-chain storage, dynamic decay, community palette proposals, and on-chain metadata.
 */
contract EternalCanvas {

    // --- Constants ---
    uint256 public immutable CANVAS_WIDTH;
    uint256 public immutable CANVAS_HEIGHT;
    uint256 public constant PIXEL_COUNT = CANVAS_WIDTH * CANVAS_HEIGHT; // Calculated in constructor
    uint64 public constant DECAY_THRESHOLD = 30 days; // Time after which a pixel starts to decay significantly
    uint64 public constant RECLAIM_THRESHOLD = 90 days; // Time after which a decayed pixel can be reclaimed

    // --- State Variables ---

    // ERC721 Core
    mapping(uint256 => address) private _owners;
    mapping(address => uint256) private _balances;
    mapping(uint256 => address) private _tokenApprovals;
    mapping(address => mapping(address => bool)) private _operatorApprovals;
    uint256 private _mintedPixelsCount; // Keep track of total minted tokens

    // Pixel Data
    struct PixelData {
        bytes3 color;          // RGB color
        uint64 lastPainted;    // Timestamp of last paint/refresh
        uint66 mintedAt;       // Timestamp of minting
        bool exists;           // Explicit flag if data exists (handle burns)
    }
    mapping(uint256 => PixelData) private _pixelData; // tokenId => PixelData

    // Palettes
    struct Palette {
        string name;
        bytes3[] colors;
    }
    mapping(uint256 => Palette) private _palettes;
    uint256 private _paletteCount;
    uint256 private _currentPaletteId;

    // Palette Governance
    struct PaletteProposal {
        string name;
        bytes3[] colors;
        address proposer;
        uint64 proposalTime;
        uint256 votesYes;
        uint256 votesNo;
        bool executed;
        bool cancelled;
    }
    mapping(uint256 => PaletteProposal) private _paletteProposals;
    mapping(uint256 => mapping(address => bool)) private _proposalVotes; // proposalId => voterAddress => hasVoted?
    uint256 private _paletteProposalCount;

    // Access Control (Simple Governor)
    address public governor;

    // --- Events ---

    event PixelMinted(uint256 indexed tokenId, uint256 indexed x, uint256 indexed y, address indexed owner);
    event PixelPainted(uint256 indexed tokenId, bytes3 newColor, address indexed painter);
    event PixelRefreshed(uint256 indexed tokenId, address indexed refresher);
    event PixelBurned(uint256 indexed tokenId, address indexed owner);
    event PixelDecayedReclaimed(uint256 indexed tokenId, address indexed oldOwner, address indexed newOwner);

    event PaletteDefined(uint256 indexed paletteId, string name, bytes3[] colors, address indexed creator);
    event PaletteSelected(uint256 indexed paletteId, address indexed selector);
    event PaletteProposed(uint256 indexed proposalId, string name, bytes3[] colors, address indexed proposer);
    event PaletteVoted(uint256 indexed proposalId, address indexed voter, bool vote);
    event PaletteExecuted(uint256 indexed proposalId, uint256 indexed newPaletteId, address indexed executor);
    event PaletteCancelled(uint256 indexed proposalId, address indexed canceller);

    // ERC721 Events
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);


    // --- Modifiers ---
    modifier onlyGovernor() {
        require(msg.sender == governor, "EC: Only governor");
        _;
    }

    // --- Constructor ---
    constructor(uint256 canvasWidth, uint256 canvasHeight, address governorAddress) {
        require(canvasWidth > 0 && canvasHeight > 0, "EC: Invalid dimensions");
        CANVAS_WIDTH = canvasWidth;
        CANVAS_HEIGHT = canvasHeight;
        // PIXEL_COUNT is immutable and calculated here implicitly by using CANVAS_WIDTH and CANVAS_HEIGHT
        governor = governorAddress;
        _mintedPixelsCount = 0;
        _paletteCount = 0;
        _paletteProposalCount = 0;
        _currentPaletteId = 0; // Default to no palette or a base palette (can define palette 0 later)
    }

    // --- ERC721 View Functions (Minimal Implementation) ---

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view returns (uint256) {
        require(owner != address(0), "EC: Balance query for zero address");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "EC: Owner query for nonexistent token");
        return owner;
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view returns (address) {
        require(_owners[tokenId] != address(0), "EC: Approved query for nonexistent token");
        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    // --- Internal ERC721 Helpers ---

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *      Assumes token does not exist.
     */
    function _safeMint(address to, uint256 tokenId) internal {
        require(to != address(0), "EC: Mint to zero address");
        require(_owners[tokenId] == address(0), "EC: Token already minted");

        _balances[to]++;
        _owners[tokenId] = to;
        _mintedPixelsCount++;

        // Record initial pixel data upon mint
        _pixelData[tokenId] = PixelData({
            color: bytes3(0x000000), // Default initial color (black)
            lastPainted: uint64(block.timestamp),
            mintedAt: uint64(block.timestamp),
            exists: true
        });

        emit Transfer(address(0), to, tokenId);

        // ERC721Enumerable hook (if implemented) - would update token lists
        // ERC721URIStorage hook (if implemented) - would store token URI if needed
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`. Internal function without access checks.
     */
    function _transfer(address from, address to, uint256 tokenId) internal {
        require(ownerOf(tokenId) == from, "EC: Transfer from incorrect owner");
        require(to != address(0), "EC: Transfer to zero address");

        // Clear approvals
        _tokenApprovals[tokenId] = address(0);

        _balances[from]--;
        _balances[to]++;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    /**
     * @dev Burns `tokenId`. Internal function without access checks.
     */
    function _burn(uint256 tokenId) internal {
        address owner = ownerOf(tokenId); // Checks if token exists
        require(owner != address(0), "EC: Burn of nonexistent token");

        // Clear approvals
        _tokenApprovals[tokenId] = address(0);

        _balances[owner]--;
        _owners[tokenId] = address(0);
        _mintedPixelsCount--;

        // Remove or reset pixel data upon burn
        // Marking as non-existent is better than deleting for mapping gas costs
        _pixelData[tokenId].exists = false;
        // Consider resetting color/timestamps if it could be minted again later
        // For this contract, we'll assume burning makes it permanently unavailable or complex re-minting logic would be needed.
        // If it were re-mintable, you'd need to clear more state:
        // delete _pixelData[tokenId]; // This is gas intensive for the *first* delete of a slot

        emit PixelBurned(tokenId, owner);
    }


    // --- ERC721 External Functions (Minimal Implementation) ---

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(address from, address to, uint256 tokenId) public {
        require(_isApprovedOrOwner(msg.sender, tokenId), "EC: Transfer caller is not owner nor approved");
        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public {
        require(_isApprovedOrOwner(msg.sender, tokenId), "EC: Transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, data);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) public {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address approved, uint256 tokenId) public {
        address owner = ownerOf(tokenId);
        require(msg.sender == owner || isApprovedForAll(owner, msg.sender), "EC: Approval caller is not owner or operator");
        _approve(approved, tokenId);
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public {
        require(msg.sender != operator, "EC: Approve to caller");
        _operatorApprovals[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    // --- Internal ERC721 Approval Helpers ---

    function _approve(address approved, uint256 tokenId) internal {
        _tokenApprovals[tokenId] = approved;
        emit Approval(ownerOf(tokenId), approved, tokenId);
    }

    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view returns (bool) {
        address owner = ownerOf(tokenId);
        return (spender == owner || isApprovedForAll(owner, spender) || getApproved(tokenId) == spender);
    }

     /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} if `to` is a contract.
     */
    function _checkOnERC721Received(address from, address to, uint256 tokenId, bytes memory data) private {
        if (to.code.length > 0) {
            try IERC721Receiver(to).onERC721Received(msg.sender, from, tokenId, data) returns (bytes4 retval) {
                require(retval == IERC721Receiver.onERC721Received.selector, "EC: ERC721Receiver rejected transfer");
            } catch Error(string memory reason) {
                 revert(reason);
            } catch {
                revert("EC: ERC721Receiver transfer failed");
            }
        }
    }

    /**
     * @dev Safely transfers `tokenId` from `from` to `to`, checking if `to` is a contract.
     */
    function _safeTransfer(address from, address to, uint256 tokenId, bytes memory data) internal {
        _transfer(from, to, tokenId);
        _checkOnERC721Received(from, to, tokenId, data);
    }


    // --- Canvas & Pixel Management Functions ---

    /**
     * @dev Converts token ID to (x, y) coordinates.
     * @param tokenId The ID of the pixel token.
     * @return x The x-coordinate.
     * @return y The y-coordinate.
     */
    function tokenToCoordinates(uint256 tokenId) public view returns (uint256 x, uint256 y) {
        require(tokenId < PIXEL_COUNT, "EC: Token ID out of bounds");
        x = tokenId % CANVAS_WIDTH;
        y = tokenId / CANVAS_WIDTH;
    }

    /**
     * @dev Converts (x, y) coordinates to a token ID.
     * @param x The x-coordinate.
     * @param y The y-coordinate.
     * @return The corresponding token ID.
     */
    function coordinatesToToken(uint256 x, uint256 y) public view returns (uint256) {
        require(x < CANVAS_WIDTH && y < CANVAS_HEIGHT, "EC: Coordinates out of bounds");
        return y * CANVAS_WIDTH + x;
    }

    /**
     * @dev Returns the canvas dimensions.
     */
    function getCanvasDimensions() public view returns (uint256 width, uint256 height) {
        return (CANVAS_WIDTH, CANVAS_HEIGHT);
    }

    /**
     * @dev Checks if a pixel at given coordinates is owned (exists).
     * @param x The x-coordinate.
     * @param y The y-coordinate.
     * @return True if owned, false otherwise.
     */
    function isPixelOwned(uint256 x, uint256 y) public view returns (bool) {
        uint256 tokenId = coordinatesToToken(x, y);
        // Check internal data existence flag, which handles burns correctly
        return _pixelData[tokenId].exists && _owners[tokenId] != address(0);
    }

    /**
     * @dev Mints the pixel token at (x, y) to the caller.
     * @param x The x-coordinate.
     * @param y The y-coordinate.
     */
    function mintPixel(uint256 x, uint256 y) public {
        uint256 tokenId = coordinatesToToken(x, y);
        require(!isPixelOwned(x, y), "EC: Pixel already minted");
        // Cost to mint could be added here: require(msg.value >= mintFee, "EC: Insufficient mint fee");

        _safeMint(msg.sender, tokenId); // _safeMint initializes PixelData
        emit PixelMinted(tokenId, x, y, msg.sender);
    }

    /**
     * @dev Returns the data associated with a pixel token.
     * @param tokenId The ID of the pixel token.
     * @return pixelData The PixelData struct.
     */
    function getPixelData(uint256 tokenId) public view returns (PixelData memory) {
        require(_pixelData[tokenId].exists, "EC: Pixel data does not exist");
        return _pixelData[tokenId];
    }

     /**
     * @dev Returns the color of a pixel.
     * @param tokenId The ID of the pixel token.
     * @return The color as bytes3.
     */
    function getPixelColor(uint256 tokenId) public view returns (bytes3) {
        return getPixelData(tokenId).color; // Uses getPixelData to check existence
    }


    /**
     * @dev Allows the owner or approved address to paint a pixel.
     * @param tokenId The ID of the pixel token.
     * @param color The new color (RGB bytes3).
     */
    function paintPixel(uint256 tokenId, bytes3 color) public {
        require(_isApprovedOrOwner(msg.sender, tokenId), "EC: Not owner or approved");
        require(_pixelData[tokenId].exists, "EC: Pixel data does not exist");

        _pixelData[tokenId].color = color;
        _pixelData[tokenId].lastPainted = uint64(block.timestamp);

        emit PixelPainted(tokenId, color, msg.sender);
    }

    /**
     * @dev Returns the total number of minted pixels (tokens).
     */
    function getTotalMintedPixels() public view returns (uint256) {
        return _mintedPixelsCount;
    }

     /**
     * @dev Returns the owner of a pixel by its coordinates.
     * @param x The x-coordinate.
     * @param y The y-coordinate.
     * @return The address of the owner.
     */
    function getPixelOwner(uint256 x, uint256 y) public view returns (address) {
        uint256 tokenId = coordinatesToToken(x, y);
        return ownerOf(tokenId); // Will revert if token doesn't exist/is burned
    }


    // --- Palette Management Functions ---

    /**
     * @dev Allows the Governor to define a new official color palette.
     * @param name The name of the palette.
     * @param colors The array of bytes3 colors in the palette.
     */
    function definePalette(string calldata name, bytes3[] calldata colors) public onlyGovernor {
        require(colors.length > 0, "EC: Palette must have colors");
        _paletteCount++;
        _palettes[_paletteCount] = Palette({
            name: name,
            colors: colors
        });
        emit PaletteDefined(_paletteCount, name, colors, msg.sender);
    }

    /**
     * @dev Allows the Governor to select the active palette for paintPixelWithPalette.
     * @param paletteId The ID of the palette to make active.
     */
    function selectActivePalette(uint256 paletteId) public onlyGovernor {
        require(paletteId > 0 && paletteId <= _paletteCount, "EC: Invalid palette ID");
        _currentPaletteId = paletteId;
        emit PaletteSelected(paletteId, msg.sender);
    }

    /**
     * @dev Allows owner/approved to paint a pixel using a color from the active palette.
     * @param tokenId The ID of the pixel token.
     * @param paletteColorIndex The index of the color in the active palette.
     */
    function paintPixelWithPalette(uint256 tokenId, uint256 paletteColorIndex) public {
        require(_isApprovedOrOwner(msg.sender, tokenId), "EC: Not owner or approved");
         require(_pixelData[tokenId].exists, "EC: Pixel data does not exist");

        uint256 currentPaletteId = _currentPaletteId;
        require(currentPaletteId > 0 && currentPaletteId <= _paletteCount, "EC: No active palette selected");

        Palette storage activePalette = _palettes[currentPaletteId];
        require(paletteColorIndex < activePalette.colors.length, "EC: Invalid color index for palette");

        bytes3 selectedColor = activePalette.colors[paletteColorIndex];
        _pixelData[tokenId].color = selectedColor;
        _pixelData[tokenId].lastPainted = uint64(block.timestamp);

        emit PixelPainted(tokenId, selectedColor, msg.sender);
    }

    /**
     * @dev Returns the colors in a specific palette.
     * @param paletteId The ID of the palette.
     */
    function getPaletteColors(uint256 paletteId) public view returns (bytes3[] memory) {
        require(paletteId > 0 && paletteId <= _paletteCount, "EC: Invalid palette ID");
        return _palettes[paletteId].colors;
    }

    /**
     * @dev Returns the ID of the currently active palette.
     */
    function getCurrentPaletteId() public view returns (uint256) {
        return _currentPaletteId;
    }

     /**
     * @dev Returns the total number of defined palettes.
     */
    function getPaletteCount() public view returns (uint256) {
        return _paletteCount;
    }


    // --- Dynamic & Decay Functions ---

    /**
     * @dev Checks if a pixel has decayed based on the time since last painted.
     * @param tokenId The ID of the pixel token.
     * @return True if decayed, false otherwise.
     */
    function checkPixelDecay(uint256 tokenId) public view returns (bool) {
        if (!_pixelData[tokenId].exists) return true; // Burned pixels are effectively decayed
        return (block.timestamp - _pixelData[tokenId].lastPainted) >= DECAY_THRESHOLD;
    }

    /**
     * @dev Checks if a pixel is reclaimable based on the time since last painted.
     * @param tokenId The ID of the pixel token.
     * @return True if reclaimable, false otherwise.
     */
    function checkPixelReclaimable(uint256 tokenId) public view returns (bool) {
         if (!_pixelData[tokenId].exists) return false; // Burned pixels cannot be reclaimed
         return (block.timestamp - _pixelData[tokenId].lastPainted) >= RECLAIM_THRESHOLD;
    }


    /**
     * @dev Resets the decay timer for a pixel. Only owner/approved can do this.
     * @param tokenId The ID of the pixel token.
     */
    function refreshPixel(uint256 tokenId) public {
        require(_isApprovedOrOwner(msg.sender, tokenId), "EC: Not owner or approved");
        require(_pixelData[tokenId].exists, "EC: Pixel data does not exist");

        _pixelData[tokenId].lastPainted = uint64(block.timestamp);
        emit PixelRefreshed(tokenId, msg.sender);
    }

    /**
     * @dev Allows anyone to claim ownership of a pixel that has decayed past the reclaim threshold.
     *      This transfers the ERC721 token.
     * @param tokenId The ID of the pixel token.
     */
    function reclaimDecayedPixel(uint256 tokenId) public {
        require(_pixelData[tokenId].exists, "EC: Pixel data does not exist");
        require(ownerOf(tokenId) != address(0), "EC: Pixel is not owned"); // Make sure it wasn't burned

        require(checkPixelReclaimable(tokenId), "EC: Pixel not yet reclaimable");

        address oldOwner = ownerOf(tokenId);
        require(oldOwner != msg.sender, "EC: Cannot reclaim your own pixel");

        // Transfer ownership to the caller
        _transfer(oldOwner, msg.sender, tokenId);

        // Update pixel data for the new owner (acts as an automatic refresh)
        _pixelData[tokenId].lastPainted = uint64(block.timestamp);
        // mintedAt remains the original mint time

        emit PixelDecayedReclaimed(tokenId, oldOwner, msg.sender);
    }

     /**
     * @dev Returns the current decay threshold time.
     */
    function getDecayThreshold() public view returns (uint64) {
        return DECAY_THRESHOLD;
    }

    // --- Palette Governance Functions ---

    /**
     * @dev Allows any user to propose a new color palette for voting.
     * @param name The name of the proposed palette.
     * @param colors The array of bytes3 colors in the proposed palette.
     */
    function proposePalette(string calldata name, bytes3[] calldata colors) public {
        require(colors.length > 0, "EC: Proposed palette must have colors");

        _paletteProposalCount++;
        uint256 proposalId = _paletteProposalCount;

        _paletteProposals[proposalId] = PaletteProposal({
            name: name,
            colors: colors,
            proposer: msg.sender,
            proposalTime: uint64(block.timestamp),
            votesYes: 0,
            votesNo: 0,
            executed: false,
            cancelled: false
        });

        emit PaletteProposed(proposalId, name, colors, msg.sender);
    }

    /**
     * @dev Allows the Governor to vote on a palette proposal.
     *      (Simplified: only governor votes. Could be expanded to token holder voting).
     * @param proposalId The ID of the proposal to vote on.
     * @param vote True for Yes, False for No.
     */
    function voteOnPalette(uint256 proposalId, bool vote) public onlyGovernor {
        PaletteProposal storage proposal = _paletteProposals[proposalId];
        require(proposal.proposer != address(0), "EC: Proposal does not exist"); // Check existence
        require(!proposal.executed, "EC: Proposal already executed");
        require(!proposal.cancelled, "EC: Proposal cancelled");
        require(!_proposalVotes[proposalId][msg.sender], "EC: Already voted on this proposal");

        _proposalVotes[proposalId][msg.sender] = true;

        if (vote) {
            proposal.votesYes++;
        } else {
            proposal.votesNo++;
        }

        emit PaletteVoted(proposalId, msg.sender, vote);
    }

    /**
     * @dev Governor executes a palette proposal if it meets the voting criteria.
     *      (Simplified criteria: requires at least 1 Yes vote and 0 No votes from governor).
     * @param proposalId The ID of the proposal to execute.
     */
    function executePaletteProposal(uint256 proposalId) public onlyGovernor {
        PaletteProposal storage proposal = _paletteProposals[proposalId];
        require(proposal.proposer != address(0), "EC: Proposal does not exist");
        require(!proposal.executed, "EC: Proposal already executed");
        require(!proposal.cancelled, "EC: Proposal cancelled");

        // Simple execution criteria: Governor voted YES and no NO votes from governor
        require(proposal.votesYes > 0 && proposal.votesNo == 0, "EC: Proposal does not meet execution criteria");

        // Execute the proposal: define the new palette officially
        _paletteCount++;
        uint256 newPaletteId = _paletteCount;

        _palettes[newPaletteId] = Palette({
            name: proposal.name,
            colors: proposal.colors
        });

        proposal.executed = true; // Mark proposal as executed

        emit PaletteDefined(newPaletteId, proposal.name, proposal.colors, address(this)); // Emitted by contract
        emit PaletteExecuted(proposalId, newPaletteId, msg.sender);
    }

    /**
     * @dev Allows Governor to cancel a palette proposal.
     * @param proposalId The ID of the proposal to cancel.
     */
    function cancelPaletteProposal(uint256 proposalId) public onlyGovernor {
        PaletteProposal storage proposal = _paletteProposals[proposalId];
        require(proposal.proposer != address(0), "EC: Proposal does not exist");
        require(!proposal.executed, "EC: Proposal already executed");
        require(!proposal.cancelled, "EC: Proposal already cancelled");

        proposal.cancelled = true;
        emit PaletteCancelled(proposalId, msg.sender);
    }

    /**
     * @dev Returns details of a specific palette proposal.
     * @param proposalId The ID of the proposal.
     */
    function getPaletteProposal(uint256 proposalId) public view returns (PaletteProposal memory) {
        PaletteProposal storage proposal = _paletteProposals[proposalId];
        require(proposal.proposer != address(0), "EC: Proposal does not exist");
        return proposal;
    }

    /**
     * @dev Returns the vote counts for a palette proposal.
     * @param proposalId The ID of the proposal.
     */
    function getPaletteProposalVoteCount(uint256 proposalId) public view returns (uint256 yesVotes, uint256 noVotes) {
        PaletteProposal storage proposal = _paletteProposals[proposalId];
        require(proposal.proposer != address(0), "EC: Proposal does not exist");
        return (proposal.votesYes, proposal.votesNo);
    }

    /**
     * @dev Returns the total number of palette proposals made.
     */
    function getPaletteProposalCount() public view returns (uint256) {
        return _paletteProposalCount;
    }

    // --- On-chain Metadata Function ---

    /**
     * @dev Generates a Data URI for the token metadata on-chain.
     *      Note: On-chain string concatenation and JSON generation can be expensive.
     * @param tokenId The ID of the pixel token.
     * @return The Data URI string.
     */
    function tokenURI(uint256 tokenId) public view returns (string memory) {
        require(_pixelData[tokenId].exists, "EC: URI query for nonexistent token");

        address owner = ownerOf(tokenId);
        PixelData memory pixelData = _pixelData[tokenId];
        (uint256 x, uint256 y) = tokenToCoordinates(tokenId);

        string memory ownerString = addressToString(owner);
        string memory colorString = bytes3ToHexString(pixelData.color);
        string memory lastPaintedString = uint256ToString(pixelData.lastPainted);
        string memory mintedAtString = uint256ToString(pixelData.mintedAt);
        string memory xString = uint256ToString(x);
        string memory yString = uint256ToString(y);
        string memory decayedStatus = checkPixelDecay(tokenId) ? "true" : "false";
        string memory reclaimableStatus = checkPixelReclaimable(tokenId) ? "true" : "false";

        // Basic JSON structure as a string
        string memory json = string(abi.encodePacked(
            '{"name": "Eternal Canvas Pixel #', uint256ToString(tokenId), ' (', xString, ',', yString, ')",',
            '"description": "A pixel on the Eternal Canvas owned by ', ownerString, '.",',
            '"image": "data:image/svg+xml;base64,...",', // Placeholder: Could generate simple SVG base64
            '"attributes": [',
                '{"trait_type": "X", "value": ', xString, '},',
                '{"trait_type": "Y", "value": ', yString, '},',
                '{"trait_type": "Color", "value": "#', colorString, '"},',
                '{"trait_type": "Last Painted", "value": ', lastPaintedString, '},',
                '{"trait_type": "Minted At", "value": ', mintedAtString, '},',
                '{"trait_type": "Decayed", "value": ', decayedStatus, '},',
                 '{"trait_type": "Reclaimable", "value": ', reclaimableStatus, '}',
            ']}'
        ));

        // Encode JSON string to Base64 (requires a library or manual implementation)
        // For simplicity here, we'll return the JSON directly, or a placeholder data URI.
        // A real implementation would use an on-chain base64 encoder or point to an IPFS/HTTP URL.
        // Let's return a data URI prefix + the JSON string for the example structure.
        // THIS IS NOT PROPER BASE64 ENCODING OF JSON. It's illustrative.
        // Proper Base64 encoding of JSON requires significantly more complex on-chain logic or a library.
        // Returning the raw JSON with a data URI header is sometimes done for simplicity/cost.
        return string(abi.encodePacked("data:application/json;utf8,", json));
    }

    // --- Helper Functions for tokenURI (Minimalist, can be expanded) ---

    function addressToString(address _address) internal pure returns(string memory) {
        bytes32 _bytes = bytes32(uint256(_address));
        bytes memory __bytes = new bytes(40);
        for(uint8 j = 0; j < 20; j++) {
            uint8 temp = uint8(_bytes[j + 12]);
            uint8 char;
            char = temp % 16;
            char += 48;
            if (char > 57) char += 39;
            __bytes[2*j+1] = bytes1(char);
            temp = temp / 16;
            char = temp % 16;
            char += 48;
            if (char > 57) char += 39;
            __bytes[2*j] = bytes1(char);
        }
        return string(abi.encodePacked("0x", __bytes));
    }

    function uint256ToString(uint256 _uint256) internal pure returns(string memory) {
        if (_uint256 == 0) {
            return "0";
        }
        uint256 temp = _uint256;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (_uint256 != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(_uint256 % 10)));
            _uint256 /= 10;
        }
        return string(buffer);
    }

     function bytes3ToHexString(bytes3 _bytes) internal pure returns (string memory) {
        bytes memory buffer = new bytes(6);
        string memory hexDigits = "0123456789abcdef";

        buffer[0] = bytes1(hexDigits[uint8(_bytes[0]) >> 4]);
        buffer[1] = bytes1(hexDigits[uint8(_bytes[0]) & 0x0f]);
        buffer[2] = bytes1(hexDigits[uint8(_bytes[1]) >> 4]);
        buffer[3] = bytes1(hexDigits[uint8(_bytes[1]) & 0x0f]);
        buffer[4] = bytes1(hexDigits[uint8(_bytes[2]) >> 4]);
        buffer[5] = bytes1(hexDigits[uint8(_bytes[2]) & 0x0f]);

        return string(buffer);
    }


    // --- Other Functions ---

    /**
     * @dev Allows the owner to burn their pixel token.
     * @param tokenId The ID of the pixel token.
     */
    function burnPixel(uint256 tokenId) public {
         require(_isApprovedOrOwner(msg.sender, tokenId), "EC: Not owner or approved");
        _burn(tokenId); // Handles access check implicitly via _isApprovedOrOwner + ownerOf check in _burn
    }

    /**
     * @dev Checks if an address is the Governor.
     * @param account The address to check.
     * @return True if the account is the governor.
     */
    function isGovernor(address account) public view returns (bool) {
        return account == governor;
    }

    // Potential future functions (examples to reach >20 easily or add complexity):
    // 29. `setGovernor(address newGovernor)`: Transfer governor role (only current governor).
    // 30. `withdrawFunds()`: If minting/painting costs ETH, governor/owner can withdraw.
    // 31. `getPixelLastPainted(uint256 tokenId)`: View just the last painted time.
    // 32. `getPixelMintedAt(uint256 tokenId)`: View just the minted time.
    // 33. `mintRandomPixel()`: Find an unowned pixel and mint it (requires complex/gas-heavy logic or VRF).
    // 34. `batchMintPixels(uint256[] calldata tokenIds)`: Mint multiple pixels in one transaction (gas limits apply).
    // 35. `batchPaintPixels(uint256[] calldata tokenIds, bytes3[] calldata colors)`: Paint multiple pixels (gas limits apply).
    // 36. `getPixelsByOwner(address owner)`: ERC721Enumerable function (requires tracking all tokens).
    // 37. `tokenByIndex(uint256 index)`: ERC721Enumerable function.
    // 38. `totalSupply()`: ERC721Enumerable function, same as `_mintedPixelsCount`.
    // 39. `setDefaultColor(bytes3 color)`: Governor sets the default color for new pixels.
    // 40. `setDecayThreshold(uint64 newThreshold)`: Governor sets the decay threshold.
    // 41. `setReclaimThreshold(uint64 newThreshold)`: Governor sets the reclaim threshold.
    // 42. `getReclaimThreshold()`: Returns the current reclaim threshold time.
    // 43. `transferGovernor(address newGovernor)`: Governor transfers the role.
    // 44. `renounceGovernor()`: Governor renounces the role.
    // 45. `supportsInterface(bytes4 interfaceId)`: ERC165 support (standard for ERC721).

    // Implementing a few more simple ones to ensure >= 20 distinct concepts/access patterns beyond minimal ERC721

    function getPixelLastPainted(uint256 tokenId) public view returns (uint64) {
         require(_pixelData[tokenId].exists, "EC: Pixel data does not exist");
         return _pixelData[tokenId].lastPainted;
    }

    function getPixelMintedAt(uint256 tokenId) public view returns (uint64) {
         require(_pixelData[tokenId].exists, "EC: Pixel data does not exist");
         return _pixelData[tokenId].mintedAt;
    }

    function getReclaimThreshold() public view returns (uint64) {
        return RECLAIM_THRESHOLD;
    }

    function supportsInterface(bytes4 interfaceId) public view virtual returns (bool) {
        // Standard ERC721, ERC721Metadata, ERC165 interfaces
        return interfaceId == 0x80ac58cd || // ERC721
               interfaceId == 0x5b5e139f || // ERC721Metadata
               interfaceId == 0x01ffc9a7;   // ERC165
               // Add ERC721Enumerable (0x780e9d63) if implemented
    }

     // --- Standard ERC721 functions required by interface, already implemented above ---
    // function balanceOf(address owner) external view returns (uint256 balance);
    // function ownerOf(uint256 tokenId) external view returns (address owner);
    // function safeTransferFrom(address from, address to, uint256 tokenId) external;
    // function transferFrom(address from, address to, uint256 tokenId) external;
    // function approve(address to, uint256 tokenId) external;
    // function getApproved(uint256 tokenId) external view returns (address operator);
    // function setApprovalForAll(address operator, bool _approved) external;
    // function isApprovedForAll(address owner, address operator) external view returns (bool);
    // function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
    // function tokenURI(uint256 tokenId) external view returns (string memory); // ERC721Metadata

    // Including the standard ERC721 functions implemented brings the total well above 20 unique public/external functions.
    // Let's count the distinctly named external/public functions excluding pure ERC721 overrides unless they have custom logic:
    // 1. constructor
    // 2. tokenToCoordinates
    // 3. coordinatesToToken
    // 4. getCanvasDimensions
    // 5. isPixelOwned
    // 6. mintPixel
    // 7. getPixelData
    // 8. getPixelColor
    // 9. paintPixel
    // 10. getTotalMintedPixels
    // 11. getPixelOwner
    // 12. definePalette
    // 13. selectActivePalette
    // 14. paintPixelWithPalette
    // 15. getPaletteColors
    // 16. getCurrentPaletteId
    // 17. getPaletteCount
    // 18. checkPixelDecay
    // 19. checkPixelReclaimable
    // 20. refreshPixel
    // 21. reclaimDecayedPixel
    // 22. getDecayThreshold
    // 23. proposePalette
    // 24. voteOnPalette
    // 25. executePaletteProposal
    // 26. cancelPaletteProposal
    // 27. getPaletteProposal
    // 28. getPaletteProposalVoteCount
    // 29. getPaletteProposalCount
    // 30. tokenURI
    // 31. burnPixel
    // 32. isGovernor
    // 33. getPixelLastPainted
    // 34. getPixelMintedAt
    // 35. getReclaimThreshold
    // 36. supportsInterface
    // (+ the 8 standard ERC721 functions if they weren't listed explicitly in the summary)
    // Total: 36 distinct public/external functions beyond the basic ERC721 interface boilerplate name-checking.
}

// Dummy interface to satisfy _checkOnERC721Received
interface IERC721Receiver {
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external returns (bytes4);
}
```