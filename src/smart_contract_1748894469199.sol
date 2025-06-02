Okay, here is a smart contract concept called `CryptoPixelCanvas`. It combines several advanced/trendy concepts:

1.  **NFTs (ERC721):** Users own specific rectangular areas of a large pixel canvas as NFTs.
2.  **On-Chain Dynamic State:** The entire canvas pixel data (color, last painted time) is stored on-chain. Pixels *decay* over time if not repainted, encouraging interaction and creating a dynamic visual state.
3.  **Delegation:** NFT owners can delegate the right to paint *their* pixels to other addresses without transferring ownership.
4.  **On-Chain Governance (Simple):** NFT holders can propose and vote on changes to core canvas parameters (like decay rate, epoch duration).
5.  **Epochs:** The canvas operates in timed epochs, which can potentially trigger changes or mark governance periods.
6.  **Internal Marketplace:** Owners can list their owned pixel areas (NFTs) for sale directly within the contract.

This combination is reasonably novel; while individual components exist, their integration into a dynamic, governed, pixel-level art canvas owned via area-based NFTs with painting delegation is a creative blend.

---

**Contract: `CryptoPixelCanvas`**

**Outline & Function Summary:**

*   **Purpose:** A decentralized, collaborative pixel art canvas where users own rectangular areas as NFTs, paint pixels within their areas, manage decay, delegate painting rights, participate in governance, and trade areas.
*   **Core Concepts:** ERC721 ownership of canvas areas, dynamic on-chain pixel state with time-based decay, delegation of paint permissions, simple on-chain parameter governance, timed epochs, internal NFT marketplace.
*   **Inherits:** ERC721Enumerable, Ownable (from OpenZeppelin).
*   **State Variables:**
    *   `canvas`: Stores `PixelState` for each coordinate (`row`, `col`).
    *   `areaCoords`: Maps `tokenId` to its rectangular coordinates.
    *   `pixelToTokenId`: Maps coordinates (`row`, `col`) to the `tokenId` that owns it.
    *   `delegatedPainters`: Tracks which addresses are delegated painters for a given `tokenId`.
    *   `canvasWidth`, `canvasHeight`: Dimensions of the canvas.
    *   `genesisTimestamp`: Time of contract deployment.
    *   `currentEpoch`: Current epoch number.
    *   `epochEndTime`: Timestamp when the current epoch ends.
    *   `governanceParameters`: Struct holding governable parameters (decay rate, epoch duration, fees, etc.).
    *   `proposals`: Stores active and past governance proposals.
    *   `nextProposalId`: Counter for proposals.
    *   `areaListings`: Stores active marketplace listings for area NFTs.
    *   `nextAreaTokenId`: Counter for minting new area NFTs.
*   **Structs:**
    *   `PixelState`: Stores color (`bytes3`) and `lastPaintedTimestamp` for a pixel.
    *   `AreaCoords`: Stores `startRow`, `startCol`, `endRow`, `endCol` for an area NFT.
    *   `CurrentParams`: Stores active governable parameters.
    *   `Proposal`: Details of a governance proposal (description, target parameter, new value, voting period, votes, status, voters).
    *   `Listing`: Details of an area NFT listing (seller, price, active status).
*   **Events:** Informational events for actions (Mint, Paint, Delegate, Revoke, Propose, Vote, ExecuteProposal, List, Buy, CancelListing, EpochAdvanced).
*   **Modifiers:**
    *   `onlyAreaOwner`: Restricts access to the owner of a specific area NFT.
    *   `requireOwnerOrDelegate`: Restricts access to the owner or a delegated painter for an area.
    *   `requireWithinArea`: Checks if a given coordinate is within the bounds of a specific area NFT.
    *   `requireWithinCanvas`: Checks if a given coordinate is within the canvas bounds.
*   **Functions (Categorized):**
    *   **NFT & Ownership (Inherited ERC721Enumerable):** (11 functions)
        1.  `balanceOf(address owner)`: Get balance.
        2.  `ownerOf(uint256 tokenId)`: Get owner.
        3.  `approve(address to, uint256 tokenId)`: Approve transfer.
        4.  `getApproved(uint256 tokenId)`: Get approved address.
        5.  `setApprovalForAll(address operator, bool approved)`: Set approval for all tokens.
        6.  `isApprovedForAll(address owner, address operator)`: Check approval for all.
        7.  `transferFrom(address from, address to, uint256 tokenId)`: Transfer token.
        8.  `safeTransferFrom(address from, address to, uint256 tokenId)`: Safe transfer.
        9.  `safeTransferFrom(address from, address to, uint256 tokenId, bytes data)`: Safe transfer with data.
        10. `totalSupply()`: Total number of minted NFTs.
        11. `tokenByIndex(uint256 index)`: Get token ID by index (enumeration).
        12. `tokenOfOwnerByIndex(address owner, uint256 index)`: Get token ID by index for owner (enumeration).
    *   **Canvas & Painting (Custom):** (At least 7 functions)
        13. `mintArea(uint256 startRow, uint256 startCol, uint256 endRow, uint256 endCol)`: Mint a new area NFT for the caller. Charges a mint fee.
        14. `paintPixel(uint256 tokenId, uint256 row, uint256 col, bytes3 color)`: Paint a single pixel within the owned area. Checks permissions, updates state, charges paint fee.
        15. `paintMultiplePixels(uint256 tokenId, uint256[] calldata rows, uint256[] calldata cols, bytes3[] calldata colors)`: Paint multiple pixels in one transaction.
        16. `getPixelState(uint256 row, uint256 col)`: Get raw `PixelState` (color and timestamp) for a pixel.
        17. `getPixelColor(uint256 row, uint256 col)`: Get the *decayed* color of a pixel based on current time and decay parameters. Pure view function.
        18. `getAreaDetails(uint256 tokenId)`: Get the coordinates of an area NFT.
        19. `getCanvasDimensions()`: Get current canvas width and height.
    *   **Delegation (Custom):** (At least 3 functions)
        20. `delegatePaint(uint256 tokenId, address delegatee)`: Grant painting permission for an area to another address.
        21. `revokeDelegatePaint(uint256 tokenId, address delegatee)`: Revoke painting permission.
        22. `isPaintDelegated(uint256 tokenId, address delegatee)`: Check if an address is delegated for an area.
    *   **Governance (Custom):** (At least 4 functions)
        23. `proposeParameterChange(string memory description, uint8 paramIndex, uint256 newValue)`: Create a proposal to change a governable parameter.
        24. `vote(uint256 proposalId, bool support)`: Cast a vote (1 NFT = 1 vote).
        25. `executeProposal(uint256 proposalId)`: Execute a successful proposal after the voting period ends and quorum is met.
        26. `getProposal(uint256 proposalId)`: Get details of a proposal.
    *   **Epochs (Custom):** (At least 2 functions)
        27. `getCurrentEpoch()`: Get the current epoch number.
        28. `advanceEpoch()`: Allows anyone to trigger the advancement of the epoch if the current one has ended.
    *   **Marketplace (Custom):** (At least 4 functions)
        29. `listAreaForSale(uint256 tokenId, uint256 price)`: List an owned area NFT for sale.
        30. `buyArea(uint256 tokenId)`: Buy a listed area NFT.
        31. `cancelAreaListing(uint256 tokenId)`: Cancel an active listing.
        32. `getAreaListing(uint256 tokenId)`: Get details of a listing.
    *   **Utility/Admin (Custom):** (At least 2 functions)
        33. `withdrawFees(address payable recipient)`: Owner can withdraw accumulated contract balance (from mint/paint fees).
        34. `getGovernanceParameters()`: Get the currently active governable parameters.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/Math.sol"; // For min/max in decay calculation

// --- Contract: CryptoPixelCanvas ---
//
// Purpose: A decentralized, collaborative pixel art canvas where users own rectangular areas as NFTs,
// paint pixels within their areas, manage decay, delegate painting rights, participate in governance,
// and trade areas.
//
// Core Concepts:
// - ERC721 ownership of canvas areas.
// - Dynamic on-chain pixel state with time-based decay.
// - Delegation of paint permissions.
// - Simple on-chain parameter governance.
// - Timed epochs.
// - Internal NFT marketplace for areas.
//
// Inherits: ERC721Enumerable, Ownable, ReentrancyGuard
//
// State Variables:
// - canvas: Stores PixelState for each coordinate (row, col).
// - areaCoords: Maps tokenId to its rectangular coordinates.
// - pixelToTokenId: Maps coordinates (row, col) to the tokenId that owns it.
// - delegatedPainters: Tracks which addresses are delegated painters for a given tokenId.
// - canvasWidth, canvasHeight: Dimensions of the canvas.
// - genesisTimestamp: Time of contract deployment.
// - currentEpoch: Current epoch number.
// - epochEndTime: Timestamp when the current epoch ends.
// - governanceParameters: Struct holding governable parameters (decay rate, epoch duration, fees, etc.).
// - proposals: Stores active and past governance proposals.
// - nextProposalId: Counter for proposals.
// - areaListings: Stores active marketplace listings for area NFTs.
// - nextAreaTokenId: Counter for minting new area NFTs.
//
// Structs:
// - PixelState: color (bytes3), lastPaintedTimestamp (uint64).
// - AreaCoords: startRow, startCol, endRow, endCol (uint256).
// - CurrentParams: Stores active governable parameters.
// - Proposal: description (string), targetParamIndex (uint8), newValue (uint256),
//             startTime (uint64), endTime (uint64), yesVotes (uint256), noVotes (uint256),
//             executed (bool), voters (mapping(address => bool)).
// - Listing: seller (address), price (uint256), active (bool).
//
// Events:
// - Mint(address owner, uint256 tokenId, uint256 startRow, uint256 startCol, uint256 endRow, uint256 endCol)
// - Paint(uint256 tokenId, uint256 row, uint256 col, bytes3 color)
// - Delegate(uint256 tokenId, address owner, address delegatee)
// - RevokeDelegate(uint256 tokenId, address owner, address delegatee)
// - Propose(uint256 proposalId, address proposer, string description)
// - Vote(uint256 proposalId, address voter, bool support)
// - ExecuteProposal(uint256 proposalId, bool success)
// - EpochAdvanced(uint256 newEpoch, uint64 newEpochEndTime)
// - List(uint256 tokenId, address seller, uint256 price)
// - Buy(uint256 tokenId, address buyer, uint256 price)
// - CancelListing(uint256 tokenId)
// - FeeWithdrawal(address recipient, uint256 amount)
//
// Modifiers:
// - onlyAreaOwner: Requires msg.sender to be the owner of the token.
// - requireOwnerOrDelegate: Requires msg.sender to be the owner or a delegated painter for the token.
// - requireWithinArea: Checks if coordinates are within the area bounds.
// - requireWithinCanvas: Checks if coordinates are within total canvas bounds.
//
// Function Summary (Total: 34+ functions including inherited ERC721):
//
// --- NFT & Ownership (Inherited ERC721Enumerable + Custom) ---
// 1.  balanceOf(address owner) external view returns (uint256)
// 2.  ownerOf(uint256 tokenId) external view returns (address)
// 3.  approve(address to, uint256 tokenId) external
// 4.  getApproved(uint256 tokenId) external view returns (address)
// 5.  setApprovalForAll(address operator, bool approved) external
// 6.  isApprovedForAll(address owner, address operator) external view returns (bool)
// 7.  transferFrom(address from, address to, uint256 tokenId) external
// 8.  safeTransferFrom(address from, address to, uint256 tokenId) external
// 9.  safeTransferFrom(address from, address to, uint256 tokenId, bytes data) external
// 10. totalSupply() external view returns (uint256)
// 11. tokenByIndex(uint256 index) external view returns (uint256)
// 12. tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256)
// 13. mintArea(uint256 startRow, uint256 startCol, uint256 endRow, uint256 endCol) external payable
// 14. getTotalMintedAreas() external view returns (uint256) - (Alias for totalSupply)
//
// --- Canvas & Painting (Custom) ---
// 15. paintPixel(uint256 tokenId, uint256 row, uint256 col, bytes3 color) external payable requireOwnerOrDelegate requireWithinArea requireWithinCanvas
// 16. paintMultiplePixels(uint256 tokenId, uint256[] calldata rows, uint256[] calldata cols, bytes3[] calldata colors) external payable requireOwnerOrDelegate requireWithinArea requireWithinCanvas
// 17. getPixelState(uint256 row, uint256 col) public view returns (PixelState memory)
// 18. getPixelColor(uint256 row, uint256 col) public view returns (bytes3 decayedColor) // Applies decay calculation
// 19. getAreaDetails(uint256 tokenId) public view returns (AreaCoords memory)
// 20. getCanvasDimensions() external view returns (uint256 width, uint256 height)
//
// --- Delegation (Custom) ---
// 21. delegatePaint(uint256 tokenId, address delegatee) external onlyAreaOwner
// 22. revokeDelegatePaint(uint256 tokenId, address delegatee) external onlyAreaOwner
// 23. isPaintDelegated(uint256 tokenId, address delegatee) public view returns (bool)
//
// --- Governance (Custom) ---
// 24. proposeParameterChange(string memory description, uint8 paramIndex, uint256 newValue) external
// 25. vote(uint256 proposalId, bool support) external
// 26. executeProposal(uint256 proposalId) external
// 27. getProposal(uint256 proposalId) public view returns (Proposal memory)
//
// --- Epochs (Custom) ---
// 28. getCurrentEpoch() external view returns (uint256)
// 29. advanceEpoch() external
// 30. getEpochEndTime() external view returns (uint64)
//
// --- Marketplace (Custom) ---
// 31. listAreaForSale(uint256 tokenId, uint256 price) external onlyAreaOwner nonReentrant
// 32. buyArea(uint256 tokenId) external payable nonReentrant
// 33. cancelAreaListing(uint256 tokenId) external nonReentrant
// 34. getAreaListing(uint256 tokenId) public view returns (Listing memory)
//
// --- Utility/Admin (Custom) ---
// 35. withdrawFees(address payable recipient) external onlyOwner nonReentrant
// 36. getGovernanceParameters() external view returns (CurrentParams memory)

contract CryptoPixelCanvas is ERC721Enumerable, Ownable, ReentrancyGuard {

    // --- Structs ---
    struct PixelState {
        bytes3 color; // RGB color (e.g., 0xff0000 for red)
        uint64 lastPaintedTimestamp; // Timestamp when pixel was last painted
    }

    struct AreaCoords {
        uint256 startRow;
        uint256 startCol;
        uint256 endRow;
        uint256 endCol;
    }

    struct CurrentParams {
        uint64 epochDuration; // Duration of an epoch in seconds
        uint64 decayInterval; // Time interval (seconds) for color decay steps
        uint8 decayPerStep;   // Amount (0-255) each RGB component decays per interval
        uint256 mintFee;      // Fee to mint a new area NFT
        uint256 paintFee;     // Fee per pixel painted
        uint256 minAreaSize;  // Minimum number of pixels in an area
    }

    struct Proposal {
        string description;
        uint8 targetParamIndex; // Index corresponding to a parameter in CurrentParams
        uint256 newValue;       // The proposed new value
        uint64 startTime;       // Timestamp when proposal was created
        uint64 endTime;         // Timestamp when voting ends
        uint256 yesVotes;       // Accumulated votes for 'yes'
        uint256 noVotes;        // Accumulated votes for 'no'
        bool executed;          // Whether the proposal has been executed
        mapping(address => bool) voters; // Addresses that have already voted
    }

    struct Listing {
        address payable seller; // Address of the seller
        uint256 price;          // Price in wei
        bool active;            // Is the listing active?
    }

    // --- State Variables ---
    mapping(uint256 row => mapping(uint256 col => PixelState)) public canvas;
    mapping(uint256 tokenId => AreaCoords) public areaCoords;
    mapping(uint256 row => mapping(uint256 col => uint256)) public pixelToTokenId;
    mapping(uint256 tokenId => mapping(address delegatee => bool)) public delegatedPainters;

    uint256 public canvasWidth;
    uint256 public canvasHeight;
    uint64 public genesisTimestamp;
    uint256 public currentEpoch;
    uint64 public epochEndTime;
    CurrentParams public governanceParameters;

    mapping(uint256 proposalId => Proposal) public proposals;
    uint256 public nextProposalId;

    mapping(uint256 tokenId => Listing) public areaListings;
    uint256 private nextAreaTokenId; // Start token IDs from 1

    // --- Events ---
    event Mint(address indexed owner, uint256 indexed tokenId, uint256 startRow, uint256 startCol, uint256 endRow, uint256 endCol);
    event Paint(uint256 indexed tokenId, uint256 row, uint256 col, bytes3 color);
    event Delegate(uint256 indexed tokenId, address indexed owner, address indexed delegatee);
    event RevokeDelegate(uint256 indexed tokenId, address indexed owner, address indexed delegatee);
    event Propose(uint256 indexed proposalId, address indexed proposer, string description);
    event Vote(uint256 indexed proposalId, address indexed voter, bool support);
    event ExecuteProposal(uint256 indexed proposalId, bool success);
    event EpochAdvanced(uint256 indexed newEpoch, uint64 newEpochEndTime);
    event List(uint256 indexed tokenId, address indexed seller, uint256 price);
    event Buy(uint256 indexed tokenId, address indexed buyer, uint256 price);
    event CancelListing(uint256 indexed tokenId);
    event FeeWithdrawal(address indexed recipient, uint256 amount);

    // --- Modifiers ---
    modifier onlyAreaOwner(uint256 tokenId) {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "Not owner or approved");
        _;
    }

    modifier requireOwnerOrDelegate(uint256 tokenId) {
        address owner = ownerOf(tokenId);
        require(_msgSender() == owner || delegatedPainters[tokenId][_msgSender()], "Not owner or delegated painter");
        _;
    }

    modifier requireWithinArea(uint256 tokenId, uint256 row, uint256 col) {
        AreaCoords memory coords = areaCoords[tokenId];
        require(row >= coords.startRow && row <= coords.endRow && col >= coords.startCol && col <= coords.endCol, "Coordinate outside area bounds");
        _;
    }

    modifier requireWithinCanvas(uint256 row, uint256 col) {
        require(row < canvasHeight && col < canvasWidth, "Coordinate outside canvas bounds");
        _;
    }

    // --- Constructor ---
    constructor(uint256 _canvasWidth, uint256 _canvasHeight, CurrentParams memory _initialParams)
        ERC721Enumerable("CryptoPixelCanvas", "CPC")
        Ownable(msg.sender) // Owner initially set to deployer
    {
        require(_canvasWidth > 0 && _canvasHeight > 0, "Canvas dimensions must be positive");
        require(_initialParams.epochDuration > 0, "Epoch duration must be positive");
        require(_initialParams.decayInterval > 0 || _initialParams.decayPerStep == 0, "Decay interval must be positive if decay per step is > 0");
        require(_initialParams.minAreaSize > 0, "Min area size must be positive");

        canvasWidth = _canvasWidth;
        canvasHeight = _canvasHeight;
        genesisTimestamp = uint64(block.timestamp);
        currentEpoch = 1;
        epochEndTime = uint64(block.timestamp) + _initialParams.epochDuration;
        governanceParameters = _initialParams;
        nextAreaTokenId = 1; // Start token IDs from 1

        // Initialize canvas pixels to black (0,0,0) or some default color if needed
        // This is implicitly handled by mapping default values, but explicitly setting could be done here (expensive)
        // For simplicity, default PixelState { bytes3(0), 0 } is used. Decay will act towards (0,0,0).
    }

    // --- Canvas & Painting Functions ---

    /// @notice Mints a new rectangular area NFT for the caller.
    /// @param startRow The starting row (inclusive).
    /// @param startCol The starting column (inclusive).
    /// @param endRow The ending row (inclusive).
    /// @param endCol The ending column (inclusive).
    function mintArea(uint256 startRow, uint256 startCol, uint256 endRow, uint256 endCol) external payable {
        require(msg.value >= governanceParameters.mintFee, "Insufficient mint fee");
        requireWithinCanvas(startRow, startCol);
        requireWithinCanvas(endRow, endCol);
        require(endRow >= startRow && endCol >= startCol, "Invalid area coordinates");

        uint256 areaSize = (endRow - startRow + 1) * (endCol - startCol + 1);
        require(areaSize >= governanceParameters.minAreaSize, "Area size too small");

        // Check for overlap with existing areas
        for (uint256 r = startRow; r <= endRow; ++r) {
            for (uint256 c = startCol; c <= endCol; ++c) {
                require(pixelToTokenId[r][c] == 0, "Area overlaps with existing token");
            }
        }

        uint256 tokenId = nextAreaTokenId++;
        _safeMint(msg.sender, tokenId);

        areaCoords[tokenId] = AreaCoords(startRow, startCol, endRow, endCol);

        // Map pixels to the new token ID
        for (uint256 r = startRow; r <= endRow; ++r) {
            for (uint256 c = startCol; c <= endCol; ++c) {
                pixelToTokenId[r][c] = tokenId;
            }
        }

        emit Mint(msg.sender, tokenId, startRow, startCol, endRow, endCol);
    }

    /// @notice Paints a single pixel within an owned area.
    /// @param tokenId The ID of the area NFT.
    /// @param row The row coordinate of the pixel.
    /// @param col The column coordinate of the pixel.
    /// @param color The new color for the pixel (RGB).
    function paintPixel(uint256 tokenId, uint256 row, uint256 col, bytes3 color)
        external
        payable
        requireOwnerOrDelegate(tokenId)
        requireWithinArea(tokenId, row, col)
        requireWithinCanvas(row, col)
    {
        require(msg.value >= governanceParameters.paintFee, "Insufficient paint fee");

        canvas[row][col].color = color;
        canvas[row][col].lastPaintedTimestamp = uint64(block.timestamp);

        emit Paint(tokenId, row, col, color);
    }

    /// @notice Paints multiple pixels within an owned area in a single transaction.
    /// @param tokenId The ID of the area NFT.
    /// @param rows An array of row coordinates.
    /// @param cols An array of column coordinates.
    /// @param colors An array of colors (RGB) corresponding to the coordinates.
    function paintMultiplePixels(uint256 tokenId, uint256[] calldata rows, uint256[] calldata cols, bytes3[] calldata colors)
        external
        payable
        requireOwnerOrDelegate(tokenId)
    {
        require(rows.length == cols.length && rows.length == colors.length, "Input arrays must have the same length");
        require(rows.length > 0, "No pixels to paint");
        require(msg.value >= governanceParameters.paintFee * rows.length, "Insufficient paint fee");

        for (uint i = 0; i < rows.length; i++) {
            uint256 row = rows[i];
            uint256 col = cols[i];
            bytes3 color = colors[i];

            requireWithinArea(tokenId, row, col);
            requireWithinCanvas(row, col);

            canvas[row][col].color = color;
            canvas[row][col].lastPaintedTimestamp = uint64(block.timestamp);

            // Emit event for each pixel, or emit a batch event
            // Batch event is more gas-efficient, but less granular for indexing
            // Sticking with individual events for clarity, consider batching for gas opt.
            emit Paint(tokenId, row, col, color);
        }
    }

    /// @notice Gets the raw pixel state (color and last painted timestamp).
    /// @param row The row coordinate.
    /// @param col The column coordinate.
    /// @return PixelState struct containing color and lastPaintedTimestamp.
    function getPixelState(uint256 row, uint256 col) public view requireWithinCanvas(row, col) returns (PixelState memory) {
        return canvas[row][col];
    }

    /// @notice Gets the current, decayed color of a pixel.
    /// @param row The row coordinate.
    /// @param col The column coordinate.
    /// @return The decayed color as bytes3.
    function getPixelColor(uint256 row, uint256 col) public view requireWithinCanvas(row, col) returns (bytes3 decayedColor) {
        PixelState memory state = canvas[row][col];
        bytes3 originalColor = state.color;
        uint64 lastPainted = state.lastPaintedTimestamp;
        uint64 currentTime = uint64(block.timestamp);

        if (governanceParameters.decayPerStep == 0 || governanceParameters.decayInterval == 0) {
            return originalColor; // No decay configured
        }

        // Calculate time elapsed since last paint
        uint64 timeElapsed = currentTime - lastPainted;

        // Calculate how many decay steps have occurred
        uint256 decaySteps = timeElapsed / governanceParameters.decayInterval;

        // Calculate total decay amount for each color component
        uint256 totalDecayAmount = decaySteps * governanceParameters.decayPerStep;

        // Apply decay to each color component (decay towards black 0x000000)
        uint8 r = uint8(originalColor[0]);
        uint8 g = uint8(originalColor[1]);
        uint8 b = uint8(originalColor[2]);

        r = uint8(Math.max(0, int256(r) - int256(totalDecayAmount)));
        g = uint8(Math.max(0, int256(g) - int256(totalDecayAmount)));
        b = uint8(Math.max(0, int256(b) - int256(totalDecayAmount)));

        return bytes3(r, g, b);
    }

    /// @notice Gets the coordinates for a given area NFT.
    /// @param tokenId The ID of the area NFT.
    /// @return AreaCoords struct.
    function getAreaDetails(uint256 tokenId) public view returns (AreaCoords memory) {
        require(_exists(tokenId), "Token does not exist");
        return areaCoords[tokenId];
    }

    /// @notice Gets the total dimensions of the canvas.
    /// @return width The canvas width.
    /// @return height The canvas height.
    function getCanvasDimensions() external view returns (uint256 width, uint256 height) {
        return (canvasWidth, canvasHeight);
    }

    // --- Delegation Functions ---

    /// @notice Delegates paint permission for an area NFT to another address.
    /// @param tokenId The ID of the area NFT.
    /// @param delegatee The address to delegate painting rights to.
    function delegatePaint(uint256 tokenId, address delegatee) external onlyAreaOwner(tokenId) {
        delegatedPainters[tokenId][delegatee] = true;
        emit Delegate(tokenId, _msgSender(), delegatee);
    }

    /// @notice Revokes paint permission for an area NFT from a delegated address.
    /// @param tokenId The ID of the area NFT.
    /// @param delegatee The address to revoke painting rights from.
    function revokeDelegatePaint(uint256 tokenId, address delegatee) external onlyAreaOwner(tokenId) {
        delegatedPainters[tokenId][delegatee] = false;
        emit RevokeDelegate(tokenId, _msgSender(), delegatee);
    }

    /// @notice Checks if an address is a delegated painter for an area.
    /// @param tokenId The ID of the area NFT.
    /// @param delegatee The address to check.
    /// @return True if the address is delegated, false otherwise.
    function isPaintDelegated(uint256 tokenId, address delegatee) public view returns (bool) {
        return delegatedPainters[tokenId][delegatee];
    }

    // --- Governance Functions ---

    /// @notice Proposes a change to a governable parameter. Only NFT holders can propose.
    /// @param description A description of the proposal.
    /// @param paramIndex The index of the parameter to change (0=epochDuration, 1=decayInterval, 2=decayPerStep, 3=mintFee, 4=paintFee, 5=minAreaSize).
    /// @param newValue The proposed new value for the parameter.
    function proposeParameterChange(string memory description, uint8 paramIndex, uint256 newValue) external {
        require(balanceOf(_msgSender()) > 0, "Must hold at least one NFT to propose");
        require(paramIndex <= 5, "Invalid parameter index"); // Ensure index is valid

        uint256 proposalId = nextProposalId++;
        uint64 currentTime = uint64(block.timestamp);
        uint64 votingEndTime = currentTime + governanceParameters.epochDuration; // Voting lasts one epoch

        proposals[proposalId] = Proposal({
            description: description,
            targetParamIndex: paramIndex,
            newValue: newValue,
            startTime: currentTime,
            endTime: votingEndTime,
            yesVotes: 0,
            noVotes: 0,
            executed: false,
            voters: new mapping(address => bool)()
        });

        emit Propose(proposalId, _msgSender(), description);
    }

    /// @notice Casts a vote on an active proposal. 1 NFT = 1 vote. Votes are weighted by NFT count at time of voting.
    /// @param proposalId The ID of the proposal to vote on.
    /// @param support True for a 'yes' vote, false for a 'no' vote.
    function vote(uint256 proposalId, bool support) external {
        Proposal storage proposal = proposals[proposalId];
        require(proposal.startTime > 0, "Proposal does not exist");
        require(block.timestamp < proposal.endTime, "Voting period has ended");
        require(!proposal.executed, "Proposal has already been executed");

        uint256 voterTokenCount = balanceOf(_msgSender());
        require(voterTokenCount > 0, "Must hold at least one NFT to vote");
        require(!proposal.voters[_msgSender()], "Already voted on this proposal");

        proposal.voters[_msgSender()] = true;

        if (support) {
            proposal.yesVotes += voterTokenCount;
        } else {
            proposal.noVotes += voterTokenCount;
        }

        emit Vote(proposalId, _msgSender(), support);
    }

    /// @notice Executes a proposal if the voting period has ended, it passed (majority), and meets a simple quorum (e.g., >0 total votes).
    /// Anyone can call this after the voting period.
    /// @param proposalId The ID of the proposal to execute.
    function executeProposal(uint256 proposalId) external {
        Proposal storage proposal = proposals[proposalId];
        require(proposal.startTime > 0, "Proposal does not exist");
        require(block.timestamp >= proposal.endTime, "Voting period has not ended");
        require(!proposal.executed, "Proposal already executed");

        uint256 totalVotes = proposal.yesVotes + proposal.noVotes;
        bool success = false;

        // Simple quorum: require at least one vote
        // Simple majority: yes votes > no votes
        if (totalVotes > 0 && proposal.yesVotes > proposal.noVotes) {
            // Proposal passed, apply the change
            if (proposal.targetParamIndex == 0) {
                governanceParameters.epochDuration = uint64(proposal.newValue);
            } else if (proposal.targetParamIndex == 1) {
                governanceParameters.decayInterval = uint64(proposal.newValue);
            } else if (proposal.targetParamIndex == 2) {
                 // Requires newValue <= 255
                require(proposal.newValue <= 255, "Decay per step value too high (max 255)");
                governanceParameters.decayPerStep = uint8(proposal.newValue);
            } else if (proposal.targetParamIndex == 3) {
                governanceParameters.mintFee = proposal.newValue;
            } else if (proposal.targetParamIndex == 4) {
                governanceParameters.paintFee = proposal.newValue;
            } else if (proposal.targetParamIndex == 5) {
                 governanceParameters.minAreaSize = proposal.newValue;
            }
             // Add more cases here for other governable parameters

            success = true;
        }

        proposal.executed = true;
        emit ExecuteProposal(proposalId, success);
    }

    /// @notice Gets details of a governance proposal.
    /// @param proposalId The ID of the proposal.
    /// @return Proposal struct.
    function getProposal(uint256 proposalId) public view returns (Proposal memory) {
         // Note: Mapping values (like voters) are not returned directly from memory struct.
         // You'd need separate functions if you wanted voter lists.
        Proposal memory proposal = proposals[proposalId];
         require(proposal.startTime > 0, "Proposal does not exist"); // Basic existence check

        return proposal;
    }

     /// @notice Gets the currently active governable parameters.
     /// @return CurrentParams struct.
    function getGovernanceParameters() external view returns (CurrentParams memory) {
        return governanceParameters;
    }

    // --- Epoch Functions ---

    /// @notice Gets the current epoch number.
    /// @return The current epoch.
    function getCurrentEpoch() external view returns (uint256) {
        return currentEpoch;
    }

    /// @notice Gets the timestamp when the current epoch ends.
    /// @return The epoch end timestamp.
    function getEpochEndTime() external view returns (uint64) {
        return epochEndTime;
    }


    /// @notice Advances the epoch if the current epoch duration has passed.
    /// Anyone can call this to trigger the transition.
    function advanceEpoch() external {
        require(block.timestamp >= epochEndTime, "Epoch has not ended yet");

        currentEpoch++;
        // Use the potentially updated epoch duration from governance
        epochEndTime = uint64(block.timestamp) + governanceParameters.epochDuration;

        // Potential future logic: Trigger global canvas changes, distribute rewards, etc.

        emit EpochAdvanced(currentEpoch, epochEndTime);
    }

    // --- Marketplace Functions ---

    /// @notice Lists an owned area NFT for sale.
    /// @param tokenId The ID of the area NFT to list.
    /// @param price The price in wei.
    function listAreaForSale(uint256 tokenId, uint256 price) external onlyAreaOwner(tokenId) nonReentrant {
        require(price > 0, "Price must be greater than 0");
        require(_isApprovedOrOwner(address(this), tokenId), "Contract not approved to transfer token");

        areaListings[tokenId] = Listing({
            seller: payable(_msgSender()),
            price: price,
            active: true
        });

        emit List(tokenId, _msgSender(), price);
    }

    /// @notice Buys a listed area NFT.
    /// @param tokenId The ID of the area NFT to buy.
    function buyArea(uint256 tokenId) external payable nonReentrant {
        Listing storage listing = areaListings[tokenId];
        require(listing.active, "Token not listed for sale");
        require(msg.value >= listing.price, "Insufficient payment");
        require(listing.seller != address(0), "Listing corrupted"); // Should not happen if active
        require(listing.seller != _msgSender(), "Cannot buy your own token");

        // Deactivate listing immediately
        listing.active = false;

        // Transfer NFT to buyer
        _safeTransfer(listing.seller, _msgSender(), tokenId, ""); // Use internal _safeTransfer from ERC721

        // Transfer payment to seller
        // Use call to prevent reentrancy issues from seller's fallback function
        (bool sent, ) = listing.seller.call{value: msg.value}("");
        require(sent, "ETH transfer failed"); // Revert if payment fails after NFT transfer

        emit Buy(tokenId, _msgSender(), listing.price);
    }

    /// @notice Cancels an active listing for an owned area NFT.
    /// @param tokenId The ID of the area NFT.
    function cancelAreaListing(uint256 tokenId) external nonReentrant {
        Listing storage listing = areaListings[tokenId];
        require(listing.active, "Token not listed or already sold/cancelled");
        require(listing.seller == _msgSender(), "Not the seller of this listing");

        listing.active = false;
        // No ETH transfer needed, seller just gets token back (which they already own)

        emit CancelListing(tokenId);
    }

    /// @notice Gets details of an area NFT listing.
    /// @param tokenId The ID of the area NFT.
    /// @return Listing struct.
    function getAreaListing(uint256 tokenId) public view returns (Listing memory) {
         require(_exists(tokenId), "Token does not exist");
        return areaListings[tokenId];
    }

    // --- Utility/Admin Functions ---

    /// @notice Allows the contract owner to withdraw accumulated fees (mint and paint fees).
    /// @param recipient The address to send the fees to.
    function withdrawFees(address payable recipient) external onlyOwner nonReentrant {
        uint256 balance = address(this).balance;
        require(balance > 0, "No balance to withdraw");

        (bool sent, ) = recipient.call{value: balance}("");
        require(sent, "Fee withdrawal failed");

        emit FeeWithdrawal(recipient, balance);
    }

    /// @notice Gets the total number of area NFTs minted.
    /// @return The total supply.
    function getTotalMintedAreas() external view returns (uint256) {
        return totalSupply();
    }

    // --- Internal/Helper Functions (Overridden or used by modifiers/public fns) ---

    // Override ERC721 transfer hooks to update pixelToTokenId mapping
    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize) internal override {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);

        // If transferring from a non-zero address (not minting)
        if (from != address(0)) {
            AreaCoords memory coords = areaCoords[tokenId];
            // Update pixel ownership mapping for the area
             for (uint256 r = coords.startRow; r <= coords.endRow; ++r) {
                for (uint256 c = coords.startCol; c <= coords.endCol; ++c) {
                     // This should only happen when transferring a token that owns pixels
                     // If a pixel was previously owned by this token, update its owner
                    if (pixelToTokenId[r][c] == tokenId) {
                         pixelToTokenId[r][c] = to;
                    }
                }
            }
        }
        // Note: If minting to a non-zero address, pixelToTokenId is set in mintArea.
        // If burning (to address(0)), pixelToTokenId entries for the area would remain pointing to the burned token ID.
        // This is acceptable for this design - pixelToTokenId tracks *historical* or *current* owner;
        // ownerOf is the definitive ownership check. Painting requires *current* owner/delegate.
        // For simplicity, leaving historical mapping entries is okay. If needed, they could be reset to 0 on burn (expensive).
    }
}
```