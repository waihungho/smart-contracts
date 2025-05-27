Okay, here is a Solidity smart contract concept called `EtherealCanvas`. It's designed to be a collaborative, dynamic NFT art project with several advanced and creative features, aiming to avoid direct duplication of common open-source patterns beyond standard interfaces like ERC721 and Ownable.

The core idea is a large digital canvas divided into small plots. Users can claim empty plots, paint pixels on their claimed plots (for a fee), and the plots themselves are tradeable NFTs. The canvas evolves over time, with features like aging pixels and community voting to 'freeze' sections.

---

**Outline:**

1.  **SPDX-License-Identifier & Pragma:** Standard header.
2.  **Imports:** ERC721, Ownable, StringUtils (for tokenURI).
3.  **Error Definitions:** Custom errors for clarity.
4.  **State Variables:**
    *   Canvas and Plot Dimensions.
    *   Plot Data Storage (mapping from token ID to struct).
    *   Fee Configuration.
    *   Aging Configuration.
    *   Voting Configuration.
    *   Color Palette.
    *   Base Token URI.
    *   Internal Counters and Mappings (for ERC721 state).
5.  **Structs:**
    *   `PlotState`: Represents the state of a single plot (owner, colors, timestamp, votes, etc.).
6.  **Events:**
    *   `PlotClaimed`, `PlotPainted`, `PlotTransferred`.
    *   `PlotFrozen`, `PlotUnfrozen`.
    *   `FreezeVoteCast`, `FreezeVoteRevoked`.
    *   `CanvasSettingsUpdated`, `FeeSettingsUpdated`.
    *   `MuseEffectApplied`.
7.  **Modifiers:**
    *   `onlyPlotOwner`: Restricts access to the plot owner.
    *   `onlyPlotExists`: Ensures the token ID corresponds to a valid plot.
    *   `onlyPlotNotFrozen`: Prevents actions on frozen plots.
    *   `onlyPlotNotLocked`: Prevents actions on plots locked by aging/recency.
8.  **Constructor:** Initializes canvas dimensions, plot size, initial fees, aging settings, voting threshold, and allowed colors.
9.  **Canvas & Plot Information (Read Functions):**
    *   `getCanvasDimensions`
    *   `getPlotSize`
    *   `getTotalPlots` (Total possible plots on the canvas)
    *   `getTotalPlotsClaimed` (Same as ERC721 totalSupply)
    *   `getPlotState` (Full struct data)
    *   `getPlotColorData` (Only the pixel color data)
    *   `getPlotCoordsFromTokenId`
    *   `getTokenIdFromPlotCoords`
10. **User Actions (Write Functions):**
    *   `claimPlot`: Claim an unowned plot by coordinates, pays a fee.
    *   `paintPlot`: Paint pixels on an owned, non-frozen, non-locked plot, pays a fee.
11. **Advanced Features:**
    *   `getPlotAgingState`: Calculates a score/state based on last painted time.
    *   `calculateCurrentPaintFee`: Dynamic fee calculation (e.g., based on aging state).
    *   `voteToFreezePlot`: User casts a vote to freeze a plot (prevents painting/transfer).
    *   `revokePlotFreezeVote`: User removes their vote.
    *   `executeFreezePlot`: Anyone can call this if a plot reaches the vote threshold to formally freeze it.
    *   `unfreezePlot` (Owner/community decision): Unfreezes a plot.
    *   `getPlotVoteCount`: Gets current freeze votes for a plot.
    *   `getPlotVoters`: Gets list of addresses who voted to freeze.
    *   `musePaintRandomPlot`: Owner-triggered function applies an algorithmic color change to a random *owned* plot. (Note: randomness on-chain is tricky, use blockhash or similar for example).
12. **Fee Management:**
    *   `getClaimFee`
    *   `getPaintFeeBase`
    *   `getFreezeVoteThreshold`
    *   `withdrawFees` (Owner only)
13. **Owner/Admin Functions:**
    *   `setClaimFee`
    *   `setPaintFeeBase`
    *   `setFreezeVoteThreshold`
    *   `setPlotAgingRate`
    *   `setPlotLockDuration`
    *   `setAllowedColors`
    *   `setBaseTokenURI`
    *   `setCanvasFrozen` (Owner can temporarily freeze the entire canvas)
14. **ERC721 Standard Implementations/Overrides:**
    *   `balanceOf`
    *   `ownerOf`
    *   `transferFrom`
    *   `safeTransferFrom`
    *   `approve`
    *   `setApprovalForAll`
    *   `getApproved`
    *   `isApprovedForAll`
    *   `tokenURI` (Generates dynamic metadata including aging/freeze state and link to pixel data)
15. **Internal/Helper Functions:**
    *   `_coordsToTokenId`
    *   `_tokenIdToCoords`
    *   `_plotExists`
    *   `_isPlotOwnedBy`
    *   `_isPlotFrozen`
    *   `_isPlotLocked` (Checks aging/recency lock)
    *   `_isValidColorPalette` (Helper for `setAllowedColors`)
    *   `_requireValidColorData` (Helper for `paintPlot`)
    *   `_applyMuseEffect` (Internal logic for muse function)
    *   `_burn` (ERC721 internal)
    *   `_mint` (ERC721 internal)
    *   `_transfer` (ERC721 internal)

**Function Summary:**

*   **`constructor(...)`**: Deploys the contract, setting initial parameters like canvas size, plot size, fees, aging rules, and color palette.
*   **`getCanvasDimensions() view returns (uint16 width, uint16 height)`**: Returns the overall width and height of the canvas in pixels.
*   **`getPlotSize() view returns (uint16 size)`**: Returns the size (width/height) of individual square plots in pixels.
*   **`getTotalPlots() view returns (uint256 total)`**: Returns the total number of possible plots on the canvas.
*   **`getTotalPlotsClaimed() view returns (uint256 total)`**: Returns the current number of plots that have been claimed (total minted NFTs).
*   **`getPlotState(uint256 tokenId) view returns (PlotState)`**: Returns the comprehensive state information for a specific plot token ID.
*   **`getPlotColorData(uint256 tokenId) view returns (uint8[256] colorData)`**: Returns the on-chain pixel color data for a plot. Each `uint8` is an index in the allowed color palette.
*   **`getPlotCoordsFromTokenId(uint256 tokenId) pure returns (uint16 x, uint16 y)`**: Calculates the top-left pixel coordinates of a plot given its token ID.
*   **`getTokenIdFromPlotCoords(uint16 x, uint16 y) pure returns (uint256 tokenId)`**: Calculates the token ID for a plot given its top-left pixel coordinates.
*   **`getClaimFee() view returns (uint256 fee)`**: Returns the current fee required to claim an unowned plot.
*   **`getPaintFeeBase() view returns (uint256 fee)`**: Returns the base fee required to paint on an owned plot.
*   **`getFreezeVoteThreshold() view returns (uint256 count)`**: Returns the number of distinct user votes required to freeze a plot.
*   **`getPlotAgingState(uint256 tokenId) view returns (uint256 agingScore)`**: Calculates and returns a score representing how 'aged' a plot is based on the time since it was last painted and the configured aging rate.
*   **`calculateCurrentPaintFee(uint256 tokenId) view returns (uint256 currentFee)`**: Calculates the actual fee to paint a specific plot, potentially factoring in the base fee and its current aging state (e.g., cheaper to paint older plots).
*   **`getAllowedColors() view returns (bytes3 allowedColors)`**: Returns the bytes representing the allowed RGB color palette. Each 3 bytes is an RGB color.
*   **`claimPlot(uint16 x, uint16 y) payable`**: Allows a user to claim ownership of an unowned plot at the given coordinates. Requires sending the `_claimFee`. Mints a new ERC721 token.
*   **`paintPlot(uint256 tokenId, uint8[256] newColorData) payable`**: Allows the owner of `tokenId` to change its pixel colors. Requires sending the calculated painting fee. Updates the plot's color data and last painted timestamp.
*   **`voteToFreezePlot(uint256 tokenId)`**: Allows a user to cast a vote to freeze the specified plot. Multiple votes from the same user on the same plot don't count extra.
*   **`revokePlotFreezeVote(uint256 tokenId)`**: Allows a user to remove their previously cast vote to freeze the specified plot.
*   **`executeFreezePlot(uint256 tokenId)`**: Can be called by anyone if `tokenId` has reached or exceeded the required `_freezeVoteThreshold` votes. Formally marks the plot as frozen, preventing painting and transfers.
*   **`unfreezePlot(uint256 tokenId)`**: Owner-only function (or potentially a community decision mechanism added later) to unfreeze a frozen plot.
*   **`getPlotVoteCount(uint256 tokenId) view returns (uint256 count)`**: Returns the current number of distinct votes to freeze a plot.
*   **`getPlotVoters(uint256 tokenId) view returns (address[] memory voters)`**: Returns an array of addresses that have voted to freeze the plot. (Note: potentially gas intensive for many voters).
*   **`musePaintRandomPlot() onlyOwner`**: Owner-only function. Selects a random *claimed* plot and applies a simple, algorithmic color transformation (e.g., color shift, inversion) to its pixels. Demonstrates dynamic contract-initiated changes.
*   **`setClaimFee(uint256 newFee) onlyOwner`**: Allows the owner to update the fee for claiming a plot.
*   **`setPaintFeeBase(uint256 newFee) onlyOwner`**: Allows the owner to update the base fee for painting a plot.
*   **`setFreezeVoteThreshold(uint256 newThreshold) onlyOwner`**: Allows the owner to update the number of votes needed to freeze a plot.
*   **`setPlotAgingRate(uint256 secondsPerScoreUnit) onlyOwner`**: Allows the owner to configure the rate at which plots 'age'.
*   **`setPlotLockDuration(uint256 duration) onlyOwner`**: Allows the owner to set a time duration after painting during which a plot cannot be repainted or potentially transferred (prevents instant griefing).
*   **`setAllowedColors(bytes3 newAllowedColors) onlyOwner`**: Allows the owner to change the palette of colors that can be used for painting.
*   **`setBaseTokenURI(string memory baseURI) onlyOwner`**: Sets the base URI for the metadata server.
*   **`setCanvasFrozen(bool frozen) onlyOwner`**: Allows the owner to temporarily freeze/unfreeze the entire canvas (prevents *all* painting/claiming actions).
*   **`withdrawFees() onlyOwner`**: Allows the owner to withdraw accumulated Ether from fees.
*   **`balanceOf(address owner) override view returns (uint256)`**: ERC721 standard. Returns the number of plots owned by an address.
*   **`ownerOf(uint256 tokenId) override view returns (address)`**: ERC721 standard. Returns the owner of a plot.
*   **`transferFrom(address from, address to, uint256 tokenId) override`**: ERC721 standard. Transfers ownership of a plot. Subject to `onlyPlotNotFrozen` and `onlyPlotNotLocked` checks.
*   **`safeTransferFrom(address from, address to, uint256 tokenId) override`**: ERC721 standard. Transfers ownership safely. Subject to `onlyPlotNotFrozen` and `onlyPlotNotLocked` checks.
*   **`safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) override`**: ERC721 standard. Transfers ownership safely with data. Subject to checks.
*   **`approve(address to, uint256 tokenId) override`**: ERC721 standard. Approves an address to transfer a plot.
*   **`setApprovalForAll(address operator, bool approved) override`**: ERC721 standard. Sets approval for an operator address for all plots.
*   **`getApproved(uint256 tokenId) override view returns (address operator)`**: ERC721 standard. Gets the approved address for a plot.
*   **`isApprovedForAll(address owner, address operator) override view returns (bool)`**: ERC721 standard. Checks if an operator is approved for all plots by an owner.
*   **`tokenURI(uint256 tokenId) override view returns (string memory)`**: ERC721 standard. Generates and returns a dynamic JSON metadata URI for a plot, including its state, aging, freeze status, and a link to external pixel data/image rendering service.
*   **`totalSupply() override view returns (uint256)`**: ERC721 standard. Returns the total number of claimed plots.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Base64.sol"; // Useful for potentially embedding small data or indicating data presence

// Custom errors for gas efficiency and clarity
error EtherealCanvas__PlotAlreadyClaimed(uint16 x, uint16 y);
error EtherealCanvas__PlotNotFound(uint256 tokenId);
error EtherealCanvas__NotPlotOwner();
error EtherealCanvas__InvalidCoordinates();
error EtherealCanvas__InsufficientPayment(uint256 requiredFee);
error EtherealCanvas__PaymentOverGenerous(uint256 requiredFee); // Prevent accidental large payments
error EtherealCanvas__InvalidColorDataLength();
error EtherealCanvas__ColorNotAllowed(uint8 colorIndex);
error EtherealCanvas__PlotIsFrozen();
error EtherealCanvas__PlotIsLocked(); // Locked by aging/recency rule
error EtherealCanvas__AlreadyVotedToFreeze();
error EtherealCanvas__NotVotedToFreeze();
error EtherealCanvas__FreezeVoteThresholdNotMet();
error EtherealCanvas__PlotNotFrozen();
error EtherealCanvas__CanvasFrozen();
error EtherealCanvas__MuseNotEnabled();
error EtherealCanvas__InvalidPaletteLength();

/// @title EtherealCanvas - A Collaborative, Dynamic NFT Art Canvas
/// @author [Your Name/Alias]
/// @notice This contract implements a shared digital canvas where users claim plots as NFTs and contribute to the art by painting pixels.
/// It includes dynamic features like plot aging, community voting to freeze plots, and an owner-triggered 'muse' function.
/// @dev Plots are represented as ERC721 tokens. Pixel data is stored on-chain using indices into an allowed color palette.
/// Metadata for plots is generated dynamically via tokenURI.
contract EtherealCanvas is ERC721, Ownable {
    using Strings for uint256;

    // --- Constants & Configuration ---
    uint16 public immutable CANVAS_WIDTH; // Total width of the canvas in pixels
    uint16 public immutable CANVAS_HEIGHT; // Total height of the canvas in pixels
    uint16 public immutable PLOT_SIZE; // Width/height of a single square plot in pixels (e.g., 16)
    uint256 public immutable TOTAL_PLOT_PIXELS; // PLOT_SIZE * PLOT_SIZE

    uint256 private _claimFee; // Fee to claim an unowned plot (in wei)
    uint256 private _paintFeeBase; // Base fee to paint on an owned plot (in wei)

    uint256 private _plotAgingRate; // Seconds required for the aging state to increase by 1
    uint256 private _plotLockDuration; // Seconds after painting before a plot can be painted/transferred again

    uint256 private _freezeVoteThreshold; // Number of distinct votes required to freeze a plot
    bool private _isCanvasFrozen; // Owner can temporarily freeze all actions

    bytes3 private _allowedColors; // 3 bytes representing the allowed RGB color. Up to 255 colors possible. 0xRRGGBB. Indexing byte by byte.
                                   // Example: 0xFF0000_00FF00_0000FF -> Red (index 0), Green (index 1), Blue (index 2)

    string private _baseTokenURI; // Base URI for the metadata server (e.g., ipfs://.../ or https://...)

    bool private _museEnabled; // Toggle for the muse function

    // --- State Storage ---
    struct PlotState {
        address owner; // Current owner of the plot (redundant with ERC721 owner, but convenient)
        uint256 lastPaintedTime; // Timestamp when the plot was last painted
        uint8[256] colorData; // On-chain pixel data (indices into _allowedColors) - Assuming PLOT_SIZE 16x16 = 256 pixels
        uint256 freezeVotes; // Number of distinct addresses that voted to freeze this plot
        mapping(address => bool) hasVotedToFreeze; // Track addresses that voted
        address[] votersToFreeze; // List of addresses that voted (for easier querying)
        bool isFrozen; // If true, painting and transferring are restricted
        address lastPainter; // Address that last painted the plot
    }

    // Maps token ID (derived from plot coordinates) to its state
    mapping(uint256 => PlotState) private _plots;

    // ERC721 related mappings are handled by the OpenZeppelin library

    // --- Events ---
    event PlotClaimed(uint256 indexed tokenId, address indexed owner, uint16 x, uint16 y);
    event PlotPainted(uint256 indexed tokenId, address indexed painter, uint256 feePaid, uint256 lastPaintedTime);
    event PlotTransferred(uint256 indexed tokenId, address indexed from, address indexed to); // ERC721 standard uses Transfer event
    event PlotFrozen(uint256 indexed tokenId, uint256 voteCount);
    event PlotUnfrozen(uint256 indexed tokenId);
    event FreezeVoteCast(uint256 indexed tokenId, address indexed voter);
    event FreezeVoteRevoked(uint256 indexed tokenId, address indexed voter);
    event CanvasSettingsUpdated(uint16 canvasWidth, uint16 canvasHeight, uint16 plotSize);
    event FeeSettingsUpdated(uint256 claimFee, uint256 paintFeeBase);
    event AgingSettingsUpdated(uint256 agingRate, uint256 lockDuration);
    event VotingSettingsUpdated(uint256 freezeVoteThreshold);
    event AllowedColorsUpdated(bytes3 allowedColors);
    event BaseTokenURIUpdated(string baseTokenURI);
    event CanvasFrozenStateChanged(bool isFrozen);
    event MuseEnabledStateChanged(bool isEnabled);
    event MuseEffectApplied(uint256 indexed tokenId, uint256 randomness);

    // --- Modifiers ---
    modifier onlyPlotOwner(uint256 tokenId) {
        if (ownerOf(tokenId) != msg.sender) {
            revert EtherealCanvas__NotPlotOwner();
        }
        _;
    }

    modifier onlyPlotExists(uint256 tokenId) {
         if (_plots[tokenId].owner == address(0) && !_exists(tokenId)) { // Check both internal state and OZ state
             revert EtherealCanvas__PlotNotFound(tokenId);
         }
         _;
    }

     modifier onlyPlotNotFrozen(uint256 tokenId) {
        if (_plots[tokenId].isFrozen) {
            revert EtherealCanvas__PlotIsFrozen();
        }
        _;
    }

    modifier onlyPlotNotLocked(uint256 tokenId) {
        if (block.timestamp < _plots[tokenId].lastPaintedTime + _plotLockDuration) {
            revert EtherealCanvas__PlotIsLocked();
        }
        _;
    }

    modifier onlyCanvasNotFrozen() {
        if (_isCanvasFrozen) {
            revert EtherealCanvas__CanvasFrozen();
        }
        _;
    }


    // --- Constructor ---
    /// @param _canvasWidthPx The width of the canvas in pixels. Must be a multiple of _plotSizePx.
    /// @param _canvasHeightPx The height of the canvas in pixels. Must be a multiple of _plotSizePx.
    /// @param _plotSizePx The width/height of a square plot in pixels. Max 16 for current colorData storage.
    /// @param initialClaimFee The fee to claim a plot.
    /// @param initialPaintFeeBase The base fee to paint a plot.
    /// @param initialAgingRate Seconds for 1 unit of aging score increase.
    /// @param initialLockDuration Seconds a plot is locked after painting.
    /// @param initialFreezeVoteThreshold Votes needed to freeze.
    /// @param initialAllowedColors Initial RGB color palette (bytes3).
    constructor(
        uint16 _canvasWidthPx,
        uint16 _canvasHeightPx,
        uint16 _plotSizePx,
        uint256 initialClaimFee,
        uint256 initialPaintFeeBase,
        uint256 initialAgingRate,
        uint256 initialLockDuration,
        uint256 initialFreezeVoteThreshold,
        bytes3 initialAllowedColors
    )
        ERC721("EtherealCanvasPlot", "ECP")
        Ownable(msg.sender)
    {
        // Basic validation
        require(_plotSizePx > 0, "Plot size must be > 0");
        require(_canvasWidthPx > 0 && _canvasHeightPx > 0, "Canvas dimensions must be > 0");
        require(_canvasWidthPx % _plotSizePx == 0, "Canvas width must be multiple of plot size");
        require(_canvasHeightPx % _plotSizePx == 0, "Canvas height must be multiple of plot size");
        require(_plotSizePx * _plotSizePx <= 256, "Plot size * Plot size must be <= 256 for uint8[256] storage");
        require(initialAllowedColors.length % 3 == 0, "Allowed colors must be multiples of 3 bytes (RGB)");

        CANVAS_WIDTH = _canvasWidthPx;
        CANVAS_HEIGHT = _canvasHeightPx;
        PLOT_SIZE = _plotSizePx;
        TOTAL_PLOT_PIXELS = uint256(PLOT_SIZE) * PLOT_SIZE;

        _claimFee = initialClaimFee;
        _paintFeeBase = initialPaintFeeBase;
        _plotAgingRate = initialAgingRate;
        _plotLockDuration = initialLockDuration;
        _freezeVoteThreshold = initialFreezeVoteThreshold;
        _allowedColors = initialAllowedColors;

        _isCanvasFrozen = false;
        _museEnabled = false; // Muse starts disabled

        // Initialize empty color data for default
        uint8[256] memory emptyColorData; // All zeros by default (index 0 of palette)
        for (uint256 i = 0; i < TOTAL_PLOT_PIXELS; i++) {
             emptyColorData[i] = 0; // Ensure all pixels are index 0 initially
        }

        // Canvas settings updated event
        emit CanvasSettingsUpdated(CANVAS_WIDTH, CANVAS_HEIGHT, PLOT_SIZE);
        emit FeeSettingsUpdated(_claimFee, _paintFeeBase);
        emit AgingSettingsUpdated(_plotAgingRate, _plotLockDuration);
        emit VotingSettingsUpdated(_freezeVoteThreshold);
        emit AllowedColorsUpdated(_allowedColors);
    }

    // --- Canvas & Plot Information (Read Functions) ---

    /// @notice Returns the total width and height of the canvas in pixels.
    function getCanvasDimensions() public view returns (uint16 width, uint16 height) {
        return (CANVAS_WIDTH, CANVAS_HEIGHT);
    }

    /// @notice Returns the size (width and height) of a single square plot in pixels.
    function getPlotSize() public view returns (uint16 size) {
        return PLOT_SIZE;
    }

    /// @notice Returns the total number of possible plots on the canvas.
    function getTotalPlots() public view returns (uint256 total) {
        return (uint256(CANVAS_WIDTH) / PLOT_SIZE) * (uint256(CANVAS_HEIGHT) / PLOT_SIZE);
    }

    /// @notice Returns the current number of plots that have been claimed (minted).
    /// @dev Same as ERC721 totalSupply(). Included for clarity related to the canvas.
    function getTotalPlotsClaimed() public view returns (uint256 total) {
        return totalSupply();
    }

    /// @notice Returns the comprehensive state information for a specific plot token ID.
    /// @param tokenId The token ID of the plot.
    /// @return The PlotState struct containing all its properties.
    function getPlotState(uint256 tokenId) public view onlyPlotExists(tokenId) returns (PlotState memory) {
        PlotState storage state = _plots[tokenId];
        // Return a memory copy, excluding the voters mapping as it's not directly readable
        return PlotState({
            owner: state.owner,
            lastPaintedTime: state.lastPaintedTime,
            colorData: state.colorData,
            freezeVotes: state.freezeVotes,
            hasVotedToFreeze: state.hasVotedToFreeze, // Mapping won't be accessible directly in return struct
            votersToFreeze: new address[](0), // Return empty array as mapping state isn't returned directly
            isFrozen: state.isFrozen,
            lastPainter: state.lastPainter
        });
    }

    /// @notice Returns the on-chain pixel color data for a plot.
    /// @param tokenId The token ID of the plot.
    /// @return An array of uint8 where each value is an index into the allowed color palette.
    function getPlotColorData(uint256 tokenId) public view onlyPlotExists(tokenId) returns (uint8[256] memory colorData) {
        return _plots[tokenId].colorData;
    }

    /// @notice Calculates the top-left pixel coordinates of a plot given its token ID.
    /// @param tokenId The token ID of the plot.
    /// @return x The x-coordinate (column) of the top-left pixel.
    /// @return y The y-coordinate (row) of the top-left pixel.
    function getPlotCoordsFromTokenId(uint256 tokenId) public pure returns (uint16 x, uint16 y) {
        uint256 plotsPerRow = uint256(CANVAS_WIDTH) / PLOT_SIZE;
        uint16 plotX = uint16(tokenId % plotsPerRow);
        uint16 plotY = uint16(tokenId / plotsPerRow);
        return (plotX * PLOT_SIZE, plotY * PLOT_SIZE);
    }

    /// @notice Calculates the token ID for a plot given its top-left pixel coordinates.
    /// @param x The x-coordinate (column) of the top-left pixel. Must be a multiple of PLOT_SIZE.
    /// @param y The y-coordinate (row) of the top-left pixel. Must be a multiple of PLOT_SIZE.
    /// @return The token ID of the plot.
    function getTokenIdFromPlotCoords(uint16 x, uint16 y) public pure returns (uint256 tokenId) {
        if (x % PLOT_SIZE != 0 || y % PLOT_SIZE != 0 || x >= CANVAS_WIDTH || y >= CANVAS_HEIGHT) {
             revert EtherealCanvas__InvalidCoordinates();
        }
        uint256 plotsPerRow = uint256(CANVAS_WIDTH) / PLOT_SIZE;
        return (uint256(y) / PLOT_SIZE) * plotsPerRow + (uint256(x) / PLOT_SIZE);
    }

    /// @notice Returns the current fee to claim an unowned plot.
    function getClaimFee() public view returns (uint256 fee) {
        return _claimFee;
    }

    /// @notice Returns the base fee to paint on an owned plot.
    function getPaintFeeBase() public view returns (uint256 fee) {
        return _paintFeeBase;
    }

    /// @notice Returns the number of distinct votes required to freeze a plot.
    function getFreezeVoteThreshold() public view returns (uint256 count) {
        return _freezeVoteThreshold;
    }

     /// @notice Returns the time duration after painting during which a plot is locked.
    function getPlotLockDuration() public view returns (uint256 duration) {
        return _plotLockDuration;
    }

    /// @notice Returns the configured rate at which plots 'age'.
    function getPlotAgingRate() public view returns (uint256 rate) {
        return _plotAgingRate;
    }

    /// @notice Returns the current allowed RGB color palette.
    /// @return A bytes3 value representing the palette. Each 3 bytes is an RGB color.
    function getAllowedColors() public view returns (bytes3 allowedColors) {
        return _allowedColors;
    }

    /// @notice Returns the current state of the global canvas freeze.
    function isCanvasFrozen() public view returns (bool frozen) {
        return _isCanvasFrozen;
    }

     /// @notice Returns the current state of the muse function toggle.
    function isMuseEnabled() public view returns (bool enabled) {
        return _museEnabled;
    }

    // --- User Actions (Write Functions) ---

    /// @notice Allows a user to claim ownership of an unowned plot at the given coordinates.
    /// @dev Mints a new ERC721 token to the caller. Requires paying the `_claimFee`.
    /// @param x The x-coordinate (column) of the plot's top-left pixel. Must be a multiple of PLOT_SIZE.
    /// @param y The y-coordinate (row) of the plot's top-left pixel. Must be a multiple of PLOT_SIZE.
    function claimPlot(uint16 x, uint16 y) public payable onlyCanvasNotFrozen {
        uint256 tokenId = getTokenIdFromPlotCoords(x, y); // Will revert on invalid coords

        if (_plots[tokenId].owner != address(0)) {
            revert EtherealCanvas__PlotAlreadyClaimed(x, y);
        }

        uint256 requiredFee = _claimFee;
        if (msg.value < requiredFee) {
            revert EtherealCanvas__InsufficientPayment(requiredFee);
        }
         if (msg.value > requiredFee) {
            revert EtherealCanvas__PaymentOverGenerous(requiredFee);
        }

        // Initialize plot state
        _plots[tokenId].owner = msg.sender;
        _plots[tokenId].lastPaintedTime = block.timestamp; // Initialize last painted time
        _plots[tokenId].lastPainter = msg.sender; // Claimant is the first painter

        // Default color data (index 0 from palette)
        for (uint256 i = 0; i < TOTAL_PLOT_PIXELS; i++) {
             _plots[tokenId].colorData[i] = 0;
        }

        // Mint the ERC721 token
        _safeMint(msg.sender, tokenId);

        emit PlotClaimed(tokenId, msg.sender, x, y);
    }

    /// @notice Allows the owner of a plot to change its pixel colors.
    /// @dev Requires paying the calculated painting fee. Updates the plot's color data and timestamp.
    /// @param tokenId The token ID of the plot to paint.
    /// @param newColorData An array of uint8 representing the new pixel colors (indices into the allowed palette).
    function paintPlot(uint256 tokenId, uint8[256] memory newColorData) public payable onlyCanvasNotFrozen onlyPlotExists(tokenId) onlyPlotOwner(tokenId) onlyPlotNotFrozen(tokenId) onlyPlotNotLocked(tokenId) {
        if (newColorData.length != TOTAL_PLOT_PIXELS) {
             revert EtherealCanvas__InvalidColorDataLength();
        }

        // Validate color indices against allowed palette
        uint256 paletteSize = _allowedColors.length / 3;
        for (uint256 i = 0; i < TOTAL_PLOT_PIXELS; i++) {
            if (newColorData[i] >= paletteSize) {
                revert EtherealCanvas__ColorNotAllowed(newColorData[i]);
            }
        }

        uint256 requiredFee = calculateCurrentPaintFee(tokenId);
         if (msg.value < requiredFee) {
            revert EtherealCanvas__InsufficientPayment(requiredFee);
        }
         if (msg.value > requiredFee) {
            revert EtherealCanvas__PaymentOverGenerous(requiredFee);
        }

        // Update plot state
        _plots[tokenId].colorData = newColorData;
        _plots[tokenId].lastPaintedTime = block.timestamp;
        _plots[tokenId].lastPainter = msg.sender;

        emit PlotPainted(tokenId, msg.sender, msg.value, block.timestamp);
    }


    // --- Advanced Features ---

    /// @notice Calculates a score representing how 'aged' a plot is based on the time since last painted.
    /// @dev Higher score means older/more aged. Based on `_plotAgingRate`. Max score is capped to prevent overflow.
    /// @param tokenId The token ID of the plot.
    /// @return The aging score. Returns 0 for unowned plots or if aging rate is 0.
    function getPlotAgingState(uint256 tokenId) public view onlyPlotExists(tokenId) returns (uint256 agingScore) {
        PlotState storage state = _plots[tokenId];
        if (state.owner == address(0) || _plotAgingRate == 0 || block.timestamp <= state.lastPaintedTime) {
            return 0;
        }
        uint256 timeElapsed = block.timestamp - state.lastPaintedTime;
        // Cap the aging score to prevent potential overflow issues in future calculations,
        // or just return the raw division result. Let's return the raw result for now.
        return timeElapsed / _plotAgingRate;
    }

    /// @notice Calculates the current fee to paint a specific plot.
    /// @dev The fee is the base fee, potentially modified by aging (e.g., cheaper to paint older plots).
    /// @param tokenId The token ID of the plot.
    /// @return The current required fee to paint this plot.
    function calculateCurrentPaintFee(uint256 tokenId) public view onlyPlotExists(tokenId) returns (uint256 currentFee) {
        // Simple example: Fee decreases linearly with aging score, minimum 1 wei
        uint256 agingScore = getPlotAgingState(tokenId);
        uint256 feeReduction = (_paintFeeBase * agingScore) / 1000; // Example: 0.1% reduction per aging point
        uint256 calculatedFee = _paintFeeBase > feeReduction ? _paintFeeBase - feeReduction : 1; // Don't go below 1 wei
        return calculatedFee;

        // More complex examples could involve:
        // - Capped aging reduction
        // - Fee increases for very recently painted plots (beyond lock duration)
        // - Global factors (total painted plots, time since contract launch)
        // - External factors (via oracle, complex)
    }

    /// @notice Allows a user to cast a vote to freeze the specified plot.
    /// @dev A plot with enough votes can be formally frozen by anyone calling `executeFreezePlot`.
    /// @param tokenId The token ID of the plot to vote for.
    function voteToFreezePlot(uint256 tokenId) public onlyPlotExists(tokenId) onlyPlotNotFrozen(tokenId) {
        PlotState storage state = _plots[tokenId];
        if (state.hasVotedToFreeze[msg.sender]) {
            revert EtherealCanvas__AlreadyVotedToFreeze();
        }

        state.hasVotedToFreeze[msg.sender] = true;
        state.votersToFreeze.push(msg.sender);
        state.freezeVotes++;

        emit FreezeVoteCast(tokenId, msg.sender);
    }

    /// @notice Allows a user to remove their previously cast vote to freeze the specified plot.
    /// @param tokenId The token ID of the plot.
    function revokePlotFreezeVote(uint256 tokenId) public onlyPlotExists(tokenId) onlyPlotNotFrozen(tokenId) {
         PlotState storage state = _plots[tokenId];
        if (!state.hasVotedToFreeze[msg.sender]) {
            revert EtherealCanvas__NotVotedToFreeze();
        }

        state.hasVotedToFreeze[msg.sender] = false;
        state.freezeVotes--;

        // Remove voter from the array (quadratic complexity, potentially gas-intensive for many voters)
        // For production, consider a more gas-efficient method if many voters are expected.
        // For simplicity in this example, we iterate and remove.
        for (uint i = 0; i < state.votersToFreeze.length; i++) {
            if (state.votersToFreeze[i] == msg.sender) {
                state.votersToFreeze[i] = state.votersToFreeze[state.votersToFreeze.length - 1];
                state.votersToFreeze.pop();
                break; // Assume only one vote per address
            }
        }

        emit FreezeVoteRevoked(tokenId, msg.sender);
    }


    /// @notice Can be called by anyone to formally freeze a plot if it has met the vote threshold.
    /// @dev A frozen plot cannot be painted or transferred (except maybe by owner/governance).
    /// @param tokenId The token ID of the plot to potentially freeze.
    function executeFreezePlot(uint256 tokenId) public onlyPlotExists(tokenId) onlyPlotNotFrozen(tokenId) {
         PlotState storage state = _plots[tokenId];
         if (state.freezeVotes < _freezeVoteThreshold) {
             revert EtherealCanvas__FreezeVoteThresholdNotMet();
         }

         state.isFrozen = true;

         // Optional: Clear votes after freezing? Or keep them recorded? Keeping for now.

         emit PlotFrozen(tokenId, state.freezeVotes);
    }

    /// @notice Owner-only function (or potentially a community decision) to unfreeze a plot.
    /// @param tokenId The token ID of the plot to unfreeze.
    function unfreezePlot(uint256 tokenId) public onlyPlotExists(tokenId) onlyOwner {
        PlotState storage state = _plots[tokenId];
        if (!state.isFrozen) {
             revert EtherealCanvas__PlotNotFrozen();
        }

        state.isFrozen = false;
        state.freezeVotes = 0; // Reset votes upon unfreezing
        // Clear voters array (again, potentially gas intensive)
        delete state.votersToFreeze;
        // Clear the mapping state for each voter (also potentially gas intensive)
         // More efficient way: just iterate through the *saved* voter addresses before deleting the array
         // For simplicity here, we rely on `delete state.votersToFreeze;` removing array contents and the mapping logic handles checks against empty array implicitly.
         // A proper implementation might need to loop through the *old* `votersToFreeze` before deleting it to clear the `hasVotedToFreeze` mapping explicitly for each address.

        emit PlotUnfrozen(tokenId);
    }


    /// @notice Gets the current count of distinct addresses that have voted to freeze a plot.
    /// @param tokenId The token ID of the plot.
    /// @return The number of votes.
    function getPlotVoteCount(uint256 tokenId) public view onlyPlotExists(tokenId) returns (uint256 count) {
        return _plots[tokenId].freezeVotes;
    }

     /// @notice Gets the list of addresses that have voted to freeze a plot.
    /// @dev Be cautious with this function for plots with many voters, as it might consume significant gas to return a large array.
    /// @param tokenId The token ID of the plot.
    /// @return An array of addresses that voted.
    function getPlotVoters(uint256 tokenId) public view onlyPlotExists(tokenId) returns (address[] memory voters) {
         // Return a copy of the voters array
         return _plots[tokenId].votersToFreeze;
    }

    /// @notice Owner-only function. Applies an algorithmic color transformation to a random claimed plot.
    /// @dev Uses blockhash for pseudo-randomness (not cryptographically secure). Intended for owner to trigger creative prompts.
    function musePaintRandomPlot() public onlyOwner onlyMuseEnabled onlyCanvasNotFrozen {
        uint256 totalClaimed = totalSupply();
        if (totalClaimed == 0) {
            // No plots claimed, nothing to do
            return;
        }

        // Basic pseudo-randomness using block data
        uint256 randSeed = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, msg.sender, totalClaimed)));
        uint256 randomIndex = randSeed % totalClaimed;

        // Find the token ID at the random index (requires iterating through all tokens)
        // This is highly inefficient for a large number of tokens (O(N)).
        // A more efficient approach would use enumerable ERC721 or track token IDs in a dynamic array,
        // but OpenZeppelin's ERC721Enumerable adds significant complexity and gas cost to core operations.
        // For this example, we'll use tokenByIndex from ERC721Enumerable (requires adding import and inheritance).
        // Let's add ERC721Enumerable for this feature.
        // If not using ERC721Enumerable, a different "random" plot selection method would be needed,
        // e.g., picking a random coordinate and checking if it's owned.

         // === Let's add ERC721Enumerable temporarily for this ===
         // (Requires changing contract definition and import)
         // For this example, we'll simulate finding a random owned token ID without full E721Enumerable
         // as adding it requires implementing many more functions/state.
         // A simpler (but less truly random) approach: select a random coordinate and check if owned.
         // If not owned, try the next coordinate until an owned one is found (with a safety limit).

        uint256 maxPlots = getTotalPlots();
        uint256 startTokenId = randSeed % maxPlots;
        uint256 tokenIdToAffect = 0;
        uint256 checkLimit = maxPlots > 100 ? 100 : maxPlots; // Limit checks to prevent excessive gas

        for (uint256 i = 0; i < checkLimit; i++) {
            uint256 currentTokenId = (startTokenId + i) % maxPlots;
            if (_plots[currentTokenId].owner != address(0)) { // Check if claimed
                 // Also check if it's not frozen and not locked
                 if (!_plots[currentTokenId].isFrozen && block.timestamp >= _plots[currentTokenId].lastPaintedTime + _plotLockDuration) {
                    tokenIdToAffect = currentTokenId;
                    break;
                 }
            }
        }

        if (tokenIdToAffect == 0) {
            // Couldn't find a suitable plot to apply muse effect within limit
            return;
        }

        _applyMuseEffect(tokenIdToAffect, randSeed); // Pass seed for deterministic effect based on seed

        emit MuseEffectApplied(tokenIdToAffect, randSeed);
    }

    /// @dev Internal function to apply the muse effect logic.
    /// @param tokenId The plot to affect.
    /// @param seed A random seed influencing the effect.
    function _applyMuseEffect(uint256 tokenId, uint256 seed) internal {
        PlotState storage state = _plots[tokenId];
        uint8[256] memory currentColors = state.colorData;
        uint256 paletteSize = _allowedColors.length / 3;

        // Simple effect: Shift all colors by a random amount
        uint8 shiftAmount = uint8(seed % paletteSize);

        for(uint256 i = 0; i < TOTAL_PLOT_PIXELS; i++) {
            currentColors[i] = (currentColors[i] + shiftAmount) % uint8(paletteSize);
        }

        state.colorData = currentColors;
        state.lastPaintedTime = block.timestamp; // Update timestamp
        state.lastPainter = address(this); // Contract is the painter

        // More complex effects could involve:
        // - Applying different effects based on the seed
        // - Affecting only certain pixels
        // - Inverting colors, swapping colors, etc.
        // - Generating simple patterns
    }

    /// @notice Returns whether the muse function is currently enabled.
    function getMuseEnabled() public view returns (bool) {
        return _museEnabled;
    }


    // --- Fee Management ---

    /// @notice Allows the owner to withdraw accumulated Ether from fees.
    function withdrawFees() public onlyOwner {
        (bool success, ) = payable(owner()).call{value: address(this).balance}("");
        require(success, "Withdrawal failed");
    }

    // --- Owner/Admin Functions ---

    /// @notice Allows the owner to update the fee for claiming a plot.
    function setClaimFee(uint256 newFee) public onlyOwner {
        _claimFee = newFee;
        emit FeeSettingsUpdated(_claimFee, _paintFeeBase);
    }

    /// @notice Allows the owner to update the base fee for painting a plot.
    function setPaintFeeBase(uint256 newFee) public onlyOwner {
        _paintFeeBase = newFee;
        emit FeeSettingsUpdated(_claimFee, _paintFeeBase);
    }

    /// @notice Allows the owner to update the number of votes needed to freeze a plot.
    function setFreezeVoteThreshold(uint256 newThreshold) public onlyOwner {
        _freezeVoteThreshold = newThreshold;
        emit VotingSettingsUpdated(_freezeVoteThreshold);
    }

    /// @notice Allows the owner to configure the rate at which plots 'age'.
    function setPlotAgingRate(uint256 secondsPerScoreUnit) public onlyOwner {
        _plotAgingRate = secondsPerScoreUnit;
        emit AgingSettingsUpdated(_plotAgingRate, _plotLockDuration);
    }

     /// @notice Allows the owner to set a time duration after painting during which a plot cannot be repainted or potentially transferred.
    function setPlotLockDuration(uint256 duration) public onlyOwner {
        _plotLockDuration = duration;
        emit AgingSettingsUpdated(_plotAgingRate, _plotLockDuration);
    }


    /// @notice Allows the owner to change the palette of colors that can be used for painting.
    /// @dev The input must be a bytes3 value (3 bytes) representing the new palette. E.g., 0xFF0000 (Red), 0x00FF00 (Green), 0x0000FF (Blue).
    /// @param newAllowedColors The new bytes3 representing the allowed palette.
    function setAllowedColors(bytes3 newAllowedColors) public onlyOwner {
         if (newAllowedColors.length % 3 != 0) {
             revert EtherealCanvas__InvalidPaletteLength();
         }
        _allowedColors = newAllowedColors;
        emit AllowedColorsUpdated(_allowedColors);
    }

    /// @notice Allows the owner to set the base URI for the metadata server.
    /// @dev This URI will be prefixed to the token ID to form the full metadata URL for `tokenURI`.
    function setBaseTokenURI(string memory baseURI) public onlyOwner {
        _baseTokenURI = baseURI;
        emit BaseTokenURIUpdated(_baseTokenURI);
    }

    /// @notice Allows the owner to temporarily freeze or unfreeze all user painting and claiming actions on the canvas.
    /// @param frozen If true, canvas actions are frozen. If false, they are unfrozen.
    function setCanvasFrozen(bool frozen) public onlyOwner {
        _isCanvasFrozen = frozen;
        emit CanvasFrozenStateChanged(_isCanvasFrozen);
    }

     /// @notice Allows the owner to enable or disable the muse function.
    function setMuseEnabled(bool enabled) public onlyOwner {
        _museEnabled = enabled;
        emit MuseEnabledStateChanged(_museEnabled);
    }


    // --- ERC721 Standard Implementations/Overrides ---

    /// @dev See {ERC721-balanceOf}.
    function balanceOf(address owner) public view override returns (uint256) {
        return super.balanceOf(owner);
    }

    /// @dev See {ERC721-ownerOf}.
    function ownerOf(uint256 tokenId) public view override returns (address) {
         address owner = super.ownerOf(tokenId);
         if (owner == address(0) && _plots[tokenId].owner != address(0)) {
              // This case shouldn't happen if _safeMint is used correctly,
              // but provides a fallback check against internal state.
              // Ideally, super.ownerOf(tokenId) should be the source of truth.
              // Let's rely on super.ownerOf. If it returns address(0), the token doesn't exist by ERC721 standard.
         }
        return owner;
    }

     /// @dev See {ERC721-transferFrom}.
    /// @dev Added modifiers to prevent transfer of frozen or locked plots.
    function transferFrom(address from, address to, uint256 tokenId) public override onlyPlotExists(tokenId) onlyPlotNotFrozen(tokenId) onlyPlotNotLocked(tokenId) {
        super.transferFrom(from, to, tokenId);
         // Update owner in custom state if needed (though ERC721 handles primary ownership)
         // _plots[tokenId].owner = to; // ERC721 handles this. No need to duplicate state.
        emit PlotTransferred(tokenId, from, to);
    }

    /// @dev See {ERC721-safeTransferFrom}.
    /// @dev Added modifiers to prevent transfer of frozen or locked plots.
    function safeTransferFrom(address from, address to, uint256 tokenId) public override onlyPlotExists(tokenId) onlyPlotNotFrozen(tokenId) onlyPlotNotLocked(tokenId) {
        super.safeTransferFrom(from, to, tokenId);
         // _plots[tokenId].owner = to; // ERC721 handles this
        emit PlotTransferred(tokenId, from, to);
    }

    /// @dev See {ERC721-safeTransferFrom}.
    /// @dev Added modifiers to prevent transfer of frozen or locked plots.
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public override onlyPlotExists(tokenId) onlyPlotNotFrozen(tokenId) onlyPlotNotLocked(tokenId) {
        super.safeTransferFrom(from, to, tokenId, data);
         // _plots[tokenId].owner = to; // ERC721 handles this
        emit PlotTransferred(tokenId, from, to);
    }

    /// @dev See {ERC721-approve}.
    function approve(address to, uint256 tokenId) public override onlyPlotOwner(tokenId) onlyPlotExists(tokenId) {
        super.approve(to, tokenId);
    }

    /// @dev See {ERC721-setApprovalForAll}.
    function setApprovalForAll(address operator, bool approved) public override {
        super.setApprovalForAll(operator, approved);
    }

     /// @dev See {ERC721-getApproved}.
    function getApproved(uint256 tokenId) public view override returns (address) {
        // No need for onlyPlotExists here, ERC721 handles non-existent token check
        return super.getApproved(tokenId);
    }

    /// @dev See {ERC721-isApprovedForAll}.
    function isApprovedForAll(address owner, address operator) public view override returns (bool) {
        return super.isApprovedForAll(owner, operator);
    }

    /// @dev See {ERC721-tokenURI}.
    /// @notice Generates dynamic metadata for a plot token.
    /// @dev The JSON metadata includes details like coordinates, owner, timestamps, state (frozen, aging),
    /// and links to an external service to render the image based on the on-chain `colorData`.
    function tokenURI(uint256 tokenId) public view override onlyPlotExists(tokenId) returns (string memory) {
        // Metadata standard: https://eips.ethereum.org/EIPS/eip-721#metadata
        PlotState storage state = _plots[tokenId];
        (uint16 x, uint16 y) = getPlotCoordsFromTokenId(tokenId);

        uint256 agingState = getPlotAgingState(tokenId);
        uint256 currentPaintFee = calculateCurrentPaintFee(tokenId);

        // Build the JSON string
        string memory json = string(abi.encodePacked(
            '{"name": "Ethereal Canvas Plot #', tokenId.toString(),
            '", "description": "A ', PLOT_SIZE.toString(), 'x', PLOT_SIZE.toString(),
            ' pixel plot on the collaborative Ethereal Canvas. Owned by ',
            Strings.toHexString(uint160(state.owner)),
            '.", "image": "', _baseTokenURI, tokenId.toString(), '/image.png', // Link to external image renderer
            '", "attributes": [',
                '{"trait_type": "X", "value": ', x.toString(), '},',
                '{"trait_type": "Y", "value": ', y.toString(), '},',
                '{"trait_type": "Canvas Width", "value": ', CANVAS_WIDTH.toString(), '},',
                '{"trait_type": "Canvas Height", "value": ', CANVAS_HEIGHT.toString(), '},',
                '{"trait_type": "Plot Size", "value": ', PLOT_SIZE.toString(), '},',
                '{"trait_type": "Last Painted", "value": ', state.lastPaintedTime.toString(), '},',
                '{"trait_type": "Aging State", "value": ', agingState.toString(), '},',
                '{"trait_type": "Current Paint Fee (wei)", "value": ', currentPaintFee.toString(), '},',
                '{"trait_type": "Is Frozen", "value": ', state.isFrozen ? "true" : "false", '},',
                '{"trait_type": "Freeze Votes", "value": ', state.freezeVotes.toString(), '}',
            ']}'
        ));

        // Optional: Embed a small base64 representation of the data or a hash
        // string memory colorDataHash = string(abi.encodePacked('"colorDataHash": "', Base64.encode(bytes(keccak256(abi.encodePacked(state.colorData)))), '"'));
        // Insert colorDataHash before the closing curly brace or in attributes if needed.

        // Prepend data URI scheme
        return string(abi.encodePacked("data:application/json;base64,", Base64.encode(bytes(json))));
    }

    /// @dev Helper to check if a plot exists based on internal state.
    function _plotExists(uint256 tokenId) internal view returns (bool) {
        // Primary check should be ERC721's internal _exists, but checking internal state adds a layer
        return _plots[tokenId].owner != address(0);
    }

    /// @dev Helper to check if sender is the plot owner based on internal state.
    function _isPlotOwnedBy(uint256 tokenId, address account) internal view returns (bool) {
        // Rely on ERC721 ownerOf for canonical ownership
        return ownerOf(tokenId) == account;
    }

    /// @dev Helper to check if a plot is frozen based on internal state.
    function _isPlotFrozen(uint256 tokenId) internal view returns (bool) {
        return _plots[tokenId].isFrozen;
    }

    /// @dev Helper to check if a plot is locked based on recency of painting.
     function _isPlotLocked(uint256 tokenId) internal view returns (bool) {
         return block.timestamp < _plots[tokenId].lastPaintedTime + _plotLockDuration;
     }

    /// @dev Internal overrides for ERC721 transfer logic to potentially update local state.
    /// Note: OpenZeppelin's ERC721 handles the core state (_owners, _balances).
    /// Updating `_plots[tokenId].owner` here is redundant with OpenZeppelin's state
    /// and could lead to inconsistencies if not perfectly synchronized.
    /// It's safer *not* to update _plots[tokenId].owner here and rely solely on ownerOf().
    /*
    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize) internal override {
         super._beforeTokenTransfer(from, to, tokenId, batchSize);
         if (from != address(0)) { // Transferring from an existing owner
             // Optional: Update internal state if needed, but rely on ownerOf()
         }
         if (to != address(0)) { // Transferring to a new owner
              // Optional: Update internal state
         }
     }
     */
}
```