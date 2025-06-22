Okay, let's design a smart contract that represents an evolving, collaborative digital art canvas where portions of the canvas are owned as NFTs, users can paint on their owned plots using a scarce resource ("Ink"), and actions are recorded as historical layers.

This contract, which we'll call `CryptoCanvasChronicles`, combines concepts of:
1.  **ERC-721 (Plots):** Owning specific rectangular regions of a larger canvas grid.
2.  **Internal Resource Management (Ink):** A non-transferable (within the contract) resource required for actions like painting, subdividing, or modifying plots.
3.  **Layered/Historical State:** Each painting action adds a new layer to a plot's history, allowing for complex visual evolution and potential rollback.
4.  **Dynamic Canvas Structure:** Plots can be subdivided or potentially merged.
5.  **Controlled Actions:** Certain actions require Ink and are subject to contract rules.
6.  **Chronicle/History Tracking:** All significant modifications are permanently recorded.

It avoids simple ERC-20, basic ERC-721 minting/transfer, standard staking, basic escrow, or prediction markets.

---

## Contract Outline: `CryptoCanvasChronicles`

A smart contract managing a grid-based digital canvas where regions are owned as NFTs (Plots). Users spend an internal resource (Ink) to paint or modify their plots, creating a historical record of changes.

1.  **State Variables:**
    *   Canvas dimensions.
    *   Mapping of Plot ID to Plot Data (coordinates, owner, latest state pointer, history length).
    *   Mapping of Plot ID to Historical Entries (array of painting actions).
    *   Mapping of user address to Ink balance.
    *   Ink costs for various actions.
    *   Total fees collected.
    *   Plot counter (for ERC-721).
    *   Pause state.
    *   Owner address.

2.  **Structs:**
    *   `PlotData`: Stores details for a specific plot NFT.
    *   `PlotHistoryEntry`: Stores details of a painting action on a plot.

3.  **Events:**
    *   Indicate significant actions: Canvas initialization, plot minting, transfer, subdivision, merging, painting, history changes, ink distribution/spending, fee collection.

4.  **Functions (>= 20):** Categorized below.

---

## Function Summary:

*   **Initialization & Configuration (Admin Only):**
    *   `initializeCanvas`: Sets up the canvas dimensions and initial parameters.
    *   `mintInitialPlots`: Mints the initial set of plots, assigning them to the owner or predefined addresses.
    *   `setInkCostForAction`: Sets the Ink cost for a specific action type.
    *   `pauseContract`: Pauses paint/subdivide/merge/history modification actions.
    *   `unpauseContract`: Unpauses the contract.
    *   `withdrawFees`: Allows owner to withdraw collected ETH/fees.

*   **Plot Management (ERC-721 Standard & Extended):**
    *   `balanceOf(address owner)`: Returns the number of plots owned by an address (ERC-721).
    *   `ownerOf(uint256 tokenId)`: Returns the owner of a specific plot (ERC-721).
    *   `transferFrom(address from, address to, uint256 tokenId)`: Transfers plot ownership (ERC-721).
    *   `approve(address to, uint256 tokenId)`: Approves an address to transfer a specific plot (ERC-721).
    *   `setApprovalForAll(address operator, bool approved)`: Approves an operator for all plots (ERC-721).
    *   `getApproved(uint256 tokenId)`: Returns the approved address for a plot (ERC-721).
    *   `isApprovedForAll(address owner, address operator)`: Checks if an operator is approved (ERC-721).
    *   `tokenURI(uint256 tokenId)`: Returns the metadata URI for a plot (ERC-721 Metadata).
    *   `getPlotInfo(uint256 plotId)`: Gets detailed data about a plot (coordinates, owner, etc.).
    *   `getPlotCoordinates(uint256 plotId)`: Gets just the coordinates and dimensions of a plot.
    *   `subdividePlot(uint256 parentPlotId, uint16 newPlotCount, uint16[] newPlotWidths, uint16[] newPlotHeights)`: Allows an owner to subdivide a plot into smaller ones they will own. (Requires Ink). *Simplified parameters for demonstration.*
    *   `mergePlots(uint256[] plotIdsToMerge)`: Allows an owner to merge adjacent plots they own. (Requires Ink). *Simplified for demonstration.*

*   **Canvas Interaction & History:**
    *   `paintPlot(uint256 plotId, bytes calldata paintData)`: Paints on a specific plot. Requires ownership and Ink. Adds a new history entry.
    *   `getLatestPlotState(uint256 plotId)`: Gets the data of the most recent painting action on a plot.
    *   `getPlotHistoryLength(uint256 plotId)`: Returns the number of historical painting layers for a plot.
    *   `getPlotHistoryEntry(uint256 plotId, uint256 historyIndex)`: Retrieves a specific historical painting entry for a plot.
    *   `revertPlotToHistory(uint256 plotId, uint256 historyIndex)`: Reverts the plot's latest state to a past history entry (Expensive Ink cost).
    *   `clearPlotHistory(uint256 plotId)`: Clears all historical painting entries for a plot (Expensive Ink cost).

*   **Ink Management:**
    *   `getUserInkBalance(address user)`: Returns the Ink balance of a user.
    *   `adminDistributeInk(address[] users, uint256[] amounts)`: Admin function to distribute Ink (e.g., for events, rewards).
    *   `getInkCostForAction(bytes32 actionType)`: Returns the current Ink cost for a named action.

*   **Querying Canvas State:**
    *   `getCanvasDimensions()`: Returns the total width and height of the canvas grid.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol"; // Optional, but useful for getting all plots
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

// Outline:
// - State variables for canvas, plots, history, ink, costs, fees, state.
// - Structs for PlotData and PlotHistoryEntry.
// - Events for tracking actions.
// - ERC-721 implementation for Plot NFTs.
// - Internal resource (Ink) management.
// - Layered history tracking for plots.
// - Functions for admin (setup, config), plot management (mint, transfer, get, subdivide, merge),
//   canvas interaction (paint, history access/modification), ink management, and queries.

// Function Summary:
// - initializeCanvas: Set canvas size, initial params (Admin).
// - mintInitialPlots: Mint initial plot NFTs (Admin).
// - setInkCostForAction: Set Ink cost for specific actions (Admin).
// - pauseContract: Pause critical actions (Admin).
// - unpauseContract: Unpause contract (Admin).
// - withdrawFees: Withdraw collected fees (Admin).
// - balanceOf: Get plot count for owner (ERC-721).
// - ownerOf: Get owner of plot (ERC-721).
// - transferFrom: Transfer plot (ERC-721).
// - approve: Approve transfer (ERC-721).
// - setApprovalForAll: Approve operator (ERC-721).
// - getApproved: Get approved address (ERC-721).
// - isApprovedForAll: Check operator approval (ERC-721).
// - tokenURI: Get metadata URI (ERC-721 Metadata).
// - getPlotInfo: Get plot details (coords, owner, etc.).
// - getPlotCoordinates: Get plot coordinates and dimensions.
// - subdividePlot: Split a plot into smaller ones (Owner, requires Ink, Pausable).
// - mergePlots: Merge adjacent plots (Owner, requires Ink, Pausable).
// - paintPlot: Add a painting layer to a plot (Owner, requires Ink, Pausable).
// - getLatestPlotState: Get the most recent painting data for a plot.
// - getPlotHistoryLength: Get number of history entries for a plot.
// - getPlotHistoryEntry: Get a specific history entry for a plot.
// - revertPlotToHistory: Revert plot state to history (Owner, requires Ink, Pausable).
// - clearPlotHistory: Clear plot history (Owner, requires Ink, Pausable).
// - getUserInkBalance: Get user's Ink balance.
// - adminDistributeInk: Distribute Ink to users (Admin).
// - getInkCostForAction: Get current Ink cost for an action.
// - getCanvasDimensions: Get canvas total size.

contract CryptoCanvasChronicles is ERC721, Ownable, Pausable {
    using Counters for Counters.Counter;
    using SafeMath for uint256;

    // --- State Variables ---

    uint16 public canvasWidth;
    uint16 public canvasHeight;
    bool private _isCanvasInitialized = false; // Flag to prevent re-initialization

    Counters.Counter private _plotIdCounter;

    // Plot Data: Stores non-history specific details and the latest state
    struct PlotData {
        uint16 x;
        uint16 y;
        uint16 width;
        uint16 height;
        address owner; // Stored here for quick lookup, but ERC721 also tracks this
        bytes latestPaintData; // The data of the most recent painting action
        uint256 historyLength; // Number of entries in the history array
        string metadataURI; // Optional URI for external metadata
    }
    mapping(uint256 => PlotData) public plots;

    // Plot History: Stores the sequence of painting actions
    struct PlotHistoryEntry {
        bytes paintData; // The data painted in this layer
        address painter; // Who painted this layer
        uint66 timestamp; // When it was painted (using uint66 to save space, max ~2.1e18 fits)
    }
    mapping(uint256 => PlotHistoryEntry[]) private plotHistory; // plotId => array of history entries

    // Ink Balances
    mapping(address => uint256) private inkBalances;
    uint256 public totalInkSupply = 0;

    // Ink Costs for various actions
    mapping(bytes32 => uint256) private inkCosts;
    // Action types defined as constants (using bytes32 for keys)
    bytes32 public constant ACTION_PAINT = "paint";
    bytes32 public constant ACTION_SUBDIVIDE = "subdivide";
    bytes32 public constant ACTION_MERGE = "merge";
    bytes32 public constant ACTION_REVERT_HISTORY = "revert_history";
    bytes32 public constant ACTION_CLEAR_HISTORY = "clear_history";

    // Collected Fees (e.g., a percentage of Ink spent, or direct ETH/ERC20 if implemented)
    // For this example, let's assume fees are collected in ETH directly on some actions,
    // or Ink could be sent to a treasury address (not implemented here).
    uint256 public totalFeesCollected = 0; // Example: accumulate ETH sent with certain calls

    // --- Events ---

    event CanvasInitialized(uint16 width, uint16 height, address indexed owner);
    event PlotMinted(uint256 indexed plotId, address indexed owner, uint16 x, uint16 y, uint16 width, uint16 height);
    event PlotTransferred(uint256 indexed plotId, address indexed from, address indexed to);
    event PlotSubdivided(uint256 indexed parentPlotId, uint256[] indexed newPlotIds);
    event PlotsMerged(uint256[] indexed mergedPlotIds, uint256 indexed newPlotId);
    event PlotPainted(uint256 indexed plotId, address indexed painter, uint256 historyIndex, bytes paintData);
    event PlotHistoryReverted(uint256 indexed plotId, address indexed user, uint256 indexed revertedToIndex);
    event PlotHistoryCleared(uint256 indexed plotId, address indexed user);
    event InkDistributed(address indexed user, uint256 amount);
    event InkSpent(address indexed user, bytes32 indexed actionType, uint256 amount);
    event InkCostUpdated(bytes32 indexed actionType, uint256 newCost);
    event FeesWithdrawn(address indexed recipient, uint256 amount);

    // --- Constructor & Initialization ---

    constructor() ERC721("CryptoCanvasPlot", "CCP") Ownable(msg.sender) {}

    /// @notice Initializes the canvas dimensions and sets the initial owner.
    /// Can only be called once by the contract deployer.
    /// @param width The width of the canvas grid.
    /// @param height The height of the canvas grid.
    function initializeCanvas(uint16 width, uint16 height) external onlyOwner {
        require(!_isCanvasInitialized, "Canvas already initialized");
        require(width > 0 && height > 0, "Canvas dimensions must be positive");

        canvasWidth = width;
        canvasHeight = height;
        _isCanvasInitialized = true;

        emit CanvasInitialized(width, height, msg.sender);
    }

    /// @notice Mints an initial set of plots. Can only be called once after initialization.
    /// This is a simplified example; a real implementation might have more complex initial distribution.
    /// @param initialPlotOwners Addresses to mint plots to.
    /// @param plotDetails An array of {x, y, width, height} structs for the initial plots.
    function mintInitialPlots(address[] calldata initialPlotOwners, PlotData[] calldata plotDetails) external onlyOwner {
         require(_isCanvasInitialized, "Canvas not initialized");
         require(_plotIdCounter.current() == 0, "Initial plots already minted");
         require(initialPlotOwners.length == plotDetails.length, "Owner count must match plot detail count");

         for (uint i = 0; i < initialPlotOwners.length; i++) {
             _plotIdCounter.increment();
             uint256 newPlotId = _plotIdCounter.current();
             address plotOwner = initialPlotOwners[i];
             PlotData memory plotData = plotDetails[i];

             require(plotData.x + plotData.width <= canvasWidth, "Plot x-boundary out of bounds");
             require(plotData.y + plotData.height <= canvasHeight, "Plot y-boundary out of bounds");
             require(plotData.width > 0 && plotData.height > 0, "Plot dimensions must be positive");

             plots[newPlotId] = PlotData({
                 x: plotData.x,
                 y: plotData.y,
                 width: plotData.width,
                 height: plotData.height,
                 owner: plotOwner, // Redundant with ERC721 owner, but convenient
                 latestPaintData: "", // Initial state is empty
                 historyLength: 0,
                 metadataURI: ""
             });

             _safeMint(plotOwner, newPlotId);

             emit PlotMinted(newPlotId, plotOwner, plotData.x, plotData.y, plotData.width, plotData.height);
         }
    }

    /// @notice Sets the Ink cost for a specific action.
    /// @param actionType The identifier for the action (e.g., ACTION_PAINT).
    /// @param cost The amount of Ink required for this action.
    function setInkCostForAction(bytes32 actionType, uint256 cost) external onlyOwner {
        inkCosts[actionType] = cost;
        emit InkCostUpdated(actionType, cost);
    }

    /// @notice Pauses actions that modify the canvas or history.
    function pauseContract() external onlyOwner {
        _pause();
    }

    /// @notice Unpauses the contract, allowing previously paused actions.
    function unpauseContract() external onlyOwner {
        _unpause();
    }

    /// @notice Allows the owner to withdraw collected ETH fees.
    function withdrawFees() external onlyOwner {
        uint256 amount = totalFeesCollected;
        require(amount > 0, "No fees to withdraw");

        totalFeesCollected = 0; // Reset before sending
        (bool success, ) = payable(owner()).call{value: amount}("");
        require(success, "ETH transfer failed");

        emit FeesWithdrawn(owner(), amount);
    }

    // --- Plot Management (ERC-721 Overrides & Extensions) ---

    // ERC721 standard functions are inherited: balanceOf, ownerOf, transferFrom, approve, setApprovalForAll, getApproved, isApprovedForAll.
    // We only need to override transferFrom/safeTransferFrom if we add custom checks beyond ownership/approval.
    // For this example, standard ERC721 logic suffices for transfers.

    // --- Override `_update` from ERC721 to emit custom transfer event ---
    function _update(address to, uint256 tokenId, address auth) internal override returns (address) {
        address from = ownerOf(tokenId); // Use ownerOf here as _ownerOf might not be set yet during minting
        address newOwner = super._update(to, tokenId, auth); // Call parent

        // Update the owner field in our custom PlotData struct for convenience
        if (plots[tokenId].x != 0 || plots[tokenId].y != 0) { // Check if plot data exists (i.e., it's not a zero ID transfer or during destruction)
             plots[tokenId].owner = newOwner; // Update owner in custom struct
        }

        if (from != address(0)) { // Only emit for actual transfers, not initial mints
             emit PlotTransferred(tokenId, from, newOwner);
        }
        return newOwner;
    }


    /// @notice Gets detailed data about a specific plot NFT.
    /// @param plotId The ID of the plot.
    /// @return A struct containing plot information.
    function getPlotInfo(uint256 plotId) public view returns (PlotData memory) {
        require(_exists(plotId), "Plot does not exist");
        return plots[plotId];
    }

    /// @notice Gets just the coordinates and dimensions of a specific plot.
    /// @param plotId The ID of the plot.
    /// @return x The x-coordinate.
    /// @return y The y-coordinate.
    /// @return width The width.
    /// @return height The height.
    function getPlotCoordinates(uint256 plotId) public view returns (uint16 x, uint16 y, uint16 width, uint16 height) {
        require(_exists(plotId), "Plot does not exist");
        PlotData storage plot = plots[plotId];
        return (plot.x, plot.y, plot.width, plot.height);
    }

    /// @notice Allows a plot owner to subdivide their plot into new, smaller plots.
    /// This is a simplified model; real geometry/boundary checks are complex on-chain.
    /// Assumes valid subdivision parameters are provided by the caller (e.g., from a UI).
    /// Requires Ink based on ACTION_SUBDIVIDE cost.
    /// @param parentPlotId The ID of the plot to subdivide.
    /// @param newPlotCount The number of new plots to create.
    /// @param newPlotWidths Array of widths for the new plots.
    /// @param newPlotHeights Array of heights for the new plots. (Simplified: assumes new plots tile the parent area)
    /// @dev In a real system, complex geometric checks would be needed to ensure new plots tile the parent and stay within canvas bounds.
    function subdividePlot(uint256 parentPlotId, uint16 newPlotCount, uint16[] calldata newPlotWidths, uint16[] calldata newPlotHeights)
        external
        whenNotPaused
    {
        require(_exists(parentPlotId), "Parent plot does not exist");
        require(ownerOf(parentPlotId) == msg.sender, "Not parent plot owner");
        require(newPlotCount > 1, "Must subdivide into at least 2 plots");
        require(newPlotCount == newPlotWidths.length && newPlotCount == newPlotHeights.length, "Parameter array lengths mismatch");
        // Basic size check (simplified): sum of new areas <= parent area
        // A real implementation needs exact tiling check
        uint256 parentArea = uint256(plots[parentPlotId].width) * plots[parentPlotId].height;
        uint256 newTotalArea = 0;
        for(uint i=0; i < newPlotCount; i++) {
             require(newPlotWidths[i] > 0 && newPlotHeights[i] > 0, "New plot dimensions must be positive");
             newTotalArea = newTotalArea.add(uint256(newPlotWidths[i]) * newPlotHeights[i]);
        }
        require(newTotalArea <= parentArea, "New plots exceed parent area"); // Simplified check

        // Check Ink cost
        uint256 cost = inkCosts[ACTION_SUBDIVIDE];
        _spendInk(msg.sender, cost, ACTION_SUBDIVIDE);

        address parentOwner = msg.sender; // The owner is the caller
        PlotData memory parentPlotData = plots[parentPlotId]; // Copy parent data before potentially clearing it

        // Mark parent plot as 'subdivided' or potentially burn it (more complex geometry if burned)
        // For simplicity, let's assume the parent plot remains but is now 'abstracted' or conceptually replaced.
        // Or, we could burn the parent and mint all new ones. Burning is cleaner.
        _burn(parentPlotId); // Burn the parent NFT

        uint256[] memory newPlotIds = new uint256[newPlotCount];
        uint16 currentX = parentPlotData.x; // Simplified coordinate tracking

        for (uint i = 0; i < newPlotCount; i++) {
            _plotIdCounter.increment();
            uint256 newPlotId = _plotIdCounter.current();
            newPlotIds[i] = newPlotId;

            uint16 newPlotX = currentX; // Simplified: just place new plots sequentially
            uint16 newPlotY = parentPlotData.y; // Simplified: same Y as parent
            uint16 newPlotW = newPlotWidths[i];
            uint16 newPlotH = newPlotHeights[i]; // Simplified: assume same height as parent for this layout model

             plots[newPlotId] = PlotData({
                 x: newPlotX,
                 y: newPlotY,
                 width: newPlotW,
                 height: newPlotH,
                 owner: parentOwner,
                 latestPaintData: "", // New plots start fresh
                 historyLength: 0,
                 metadataURI: ""
             });

            _safeMint(parentOwner, newPlotId);

            // Simplified: Update currentX for next plot
            currentX = currentX + newPlotW;

             emit PlotMinted(newPlotId, parentOwner, newPlotX, newPlotY, newPlotW, newPlotH);
        }

        emit PlotSubdivided(parentPlotId, newPlotIds);
    }

     /// @notice Allows a plot owner to merge multiple adjacent plots they own into one larger plot.
     /// This is a simplified model; real geometry/adjacency checks are complex on-chain.
     /// Assumes valid, adjacent plots are provided by the caller that form a single rectangle.
     /// Requires Ink based on ACTION_MERGE cost.
     /// @param plotIdsToMerge The IDs of the plots to merge.
     /// @dev Complex geometric checks needed to verify adjacency and rectangular formation.
    function mergePlots(uint256[] calldata plotIdsToMerge)
        external
        whenNotPaused
    {
        require(plotIdsToMerge.length > 1, "Must merge at least 2 plots");

        address merger = msg.sender;
        uint256 cost = inkCosts[ACTION_MERGE];
        _spendInk(merger, cost, ACTION_MERGE);

        // Basic ownership check for all plots
        for(uint i = 0; i < plotIdsToMerge.length; i++) {
            require(_exists(plotIdsToMerge[i]), "One or more plots do not exist");
            require(ownerOf(plotIdsToMerge[i]) == merger, "Not owner of all plots to merge");
        }

        // Simplified: Burn all but the first plot, update the first plot's dimensions.
        // A real implementation would calculate the combined bounding box and ensure no gaps.
        uint256 newPlotId = plotIdsToMerge[0]; // The first plot becomes the resulting merged plot
        PlotData storage mergedPlotData = plots[newPlotId]; // Reference to the plot data

        // Simplified calculation of new bounding box (assuming they form a rectangle).
        // This needs proper implementation involving min/max x/y and sum of widths/heights.
        // For demonstration, we'll just assume the caller guarantees validity.
        // Example: A real check would look at all plot coordinates and dimensions
        // to compute the minimum x, minimum y, maximum (x+width), maximum (y+height)
        // and verify that the sum of the areas of plotsToMerge equals the area of the computed bounding box.
        // simplified for demo: just update width/height based on adding one neighbor
        if (plotIdsToMerge.length == 2) {
             PlotData storage plot2 = plots[plotIdsToMerge[1]];
             if (mergedPlotData.x + mergedPlotData.width == plot2.x && mergedPlotData.y == plot2.y && mergedPlotData.height == plot2.height) {
                  mergedPlotData.width = mergedPlotData.width + plot2.width;
             } else if (mergedPlotData.y + mergedPlotData.height == plot2.y && mergedPlotData.x == plot2.x && mergedPlotData.width == plot2.width) {
                  mergedPlotData.height = mergedPlotData.height + plot2.height;
             } else {
                  revert("Simplified merge requires specific adjacency");
             }
             _burn(plotIdsToMerge[1]); // Burn the second plot
        } else {
             // More complex merge logic needed for > 2 plots
             revert("Merge of > 2 plots not implemented in simplified demo");
        }


        // History consideration: Should the new plot's history merge? For simplicity, let's clear it or keep the history of the primary plot.
        // Keeping the history of the primary plot seems more reasonable for a "chronicle".
        // plotHistory[newPlotId] remains as is.

        // Burn the other plots in the list (starting from the second one)
        for(uint i = 1; i < plotIdsToMerge.length; i++) {
            _burn(plotIdsToMerge[i]);
        }

        emit PlotsMerged(plotIdsToMerge, newPlotId);
    }

    // --- Canvas Interaction & History ---

    /// @notice Allows the plot owner to 'paint' a new layer on their plot.
    /// Requires Ink based on ACTION_PAINT cost.
    /// @param plotId The ID of the plot to paint on.
    /// @param paintData Arbitrary bytes representing the painting data (e.g., color, pattern ID).
    function paintPlot(uint256 plotId, bytes calldata paintData)
        external
        whenNotPaused
    {
        require(_exists(plotId), "Plot does not exist");
        require(ownerOf(plotId) == msg.sender, "Not plot owner");
        require(paintData.length > 0, "Paint data cannot be empty");

        // Check Ink cost
        uint256 cost = inkCosts[ACTION_PAINT];
        _spendInk(msg.sender, cost, ACTION_PAINT);

        PlotData storage plot = plots[plotId];

        // Save the *previous* state to history before updating the latest state
        if (plot.latestPaintData.length > 0) {
             PlotHistoryEntry memory previousEntry = PlotHistoryEntry({
                  paintData: plot.latestPaintData,
                  painter: plot.owner, // Note: The owner at the time of painting is recorded
                  timestamp: uint66(block.timestamp) // Use uint66 for timestamp
             });
             plotHistory[plotId].push(previousEntry);
             plot.historyLength = plotHistory[plotId].length; // Update history length counter
        }


        // Update the latest state
        plot.latestPaintData = paintData;

        // Emit event. History index is the index *after* pushing the previous state.
        emit PlotPainted(plotId, msg.sender, plot.historyLength, paintData);
    }

    /// @notice Gets the data of the most recent painting action on a plot.
    /// This is stored directly in the PlotData struct for quick access.
    /// @param plotId The ID of the plot.
    /// @return The latest painting data bytes.
    function getLatestPlotState(uint256 plotId) public view returns (bytes memory) {
        require(_exists(plotId), "Plot does not exist");
        return plots[plotId].latestPaintData;
    }

    /// @notice Returns the number of historical painting layers stored for a plot.
    /// @param plotId The ID of the plot.
    /// @return The number of history entries.
    function getPlotHistoryLength(uint256 plotId) public view returns (uint256) {
        require(_exists(plotId), "Plot does not exist");
        // Return the counter stored in PlotData for efficiency
        return plots[plotId].historyLength;
    }

    /// @notice Retrieves a specific historical painting entry for a plot.
    /// @param plotId The ID of the plot.
    /// @param historyIndex The index of the history entry (0-based).
    /// @return paintData The painting data bytes for this entry.
    /// @return painter The address that performed this action.
    /// @return timestamp The timestamp of the action.
    function getPlotHistoryEntry(uint256 plotId, uint256 historyIndex) public view returns (bytes memory paintData, address painter, uint66 timestamp) {
        require(_exists(plotId), "Plot does not exist");
        require(historyIndex < plots[plotId].historyLength, "History index out of bounds"); // Use historyLength from PlotData

        PlotHistoryEntry storage entry = plotHistory[plotId][historyIndex];
        return (entry.paintData, entry.painter, entry.timestamp);
    }

    /// @notice Allows the plot owner to revert the plot's latest state to a past history entry.
    /// This action is expensive in terms of Ink.
    /// All history *after* the reverted-to index is removed.
    /// @param plotId The ID of the plot.
    /// @param historyIndex The index in the history array to revert *to*.
    function revertPlotToHistory(uint256 plotId, uint256 historyIndex)
        external
        whenNotPaused
    {
        require(_exists(plotId), "Plot does not exist");
        require(ownerOf(plotId) == msg.sender, "Not plot owner");
        require(historyIndex < plots[plotId].historyLength, "History index out of bounds"); // Reverting *to* an existing entry

        uint256 cost = inkCosts[ACTION_REVERT_HISTORY];
        _spendInk(msg.sender, cost, ACTION_REVERT_HISTORY);

        PlotData storage plot = plots[plotId];
        PlotHistoryEntry storage targetEntry = plotHistory[plotId][historyIndex];

        // Set the latest state to the data from the target history entry
        plot.latestPaintData = targetEntry.paintData;

        // Remove all history entries *after* the target index
        // This is inefficient for large history arrays
        for (uint i = plots[plotId].historyLength - 1; i > historyIndex; i--) {
            plotHistory[plotId].pop();
        }
        // Remove the target entry itself and subsequent entries (if the user wanted to revert *before* that entry, they'd pick historyIndex-1)
        // Or, keep the target entry and truncate after it? The prompt says "revert *to* history", implying the target becomes the latest.
        // Let's keep the target entry and remove everything after it.
        plotHistory[plotId].pop(); // Remove the entry *at* historyIndex (which we just copied to latestStateData)
         // This requires careful index management if using pop. A better way is just shrinking the array length.
         // For simplicity in demo, let's just set the length and rely on EVM cleanup.
        assembly {
            let historyArraySlot := add(plotHistory.slot, plotId) // Calculate storage slot for map value
            let historyArrayPtr := sload(historyArraySlot) // Get pointer to the array
            sstore(historyArrayPtr, historyIndex) // Set array length to historyIndex (removing entries from index historyIndex onwards)
        }
        plots[plotId].historyLength = historyIndex; // Update the counter

        // After reverting, the history entry that was *just* promoted to latestStateData isn't in the history array anymore.
        // The history now ends *before* the reverted-to state.
        // The next paint action will push the *new* latest state (which is the reverted state) as the *first* history entry.

        emit PlotHistoryReverted(plotId, msg.sender, historyIndex);
    }


    /// @notice Allows the plot owner to clear all historical painting entries for a plot.
    /// This action is expensive in terms of Ink.
    /// @param plotId The ID of the plot.
    function clearPlotHistory(uint256 plotId)
        external
        whenNotPaused
    {
        require(_exists(plotId), "Plot does not exist");
        require(ownerOf(plotId) == msg.sender, "Not plot owner");
        require(plots[plotId].historyLength > 0, "Plot history is already empty");

        uint256 cost = inkCosts[ACTION_CLEAR_HISTORY];
        _spendInk(msg.sender, cost, ACTION_CLEAR_HISTORY);

        // Clearing the dynamic array in storage
         delete plotHistory[plotId];
         plots[plotId].historyLength = 0; // Reset the counter

        emit PlotHistoryCleared(plotId, msg.sender);
    }

    // --- Ink Management ---

    /// @notice Returns the current Ink balance for a user.
    /// @param user The address of the user.
    /// @return The user's Ink balance.
    function getUserInkBalance(address user) public view returns (uint256) {
        return inkBalances[user];
    }

    /// @notice Allows the contract owner to distribute Ink to users.
    /// Used for initial distribution, event rewards, etc.
    /// @param users Array of addresses to receive Ink.
    /// @param amounts Array of corresponding Ink amounts.
    function adminDistributeInk(address[] calldata users, uint256[] calldata amounts) external onlyOwner {
        require(users.length == amounts.length, "Array lengths must match");

        for (uint i = 0; i < users.length; i++) {
            require(users[i] != address(0), "Cannot distribute to zero address");
            inkBalances[users[i]] = inkBalances[users[i]].add(amounts[i]);
            totalInkSupply = totalInkSupply.add(amounts[i]);
            emit InkDistributed(users[i], amounts[i]);
        }
    }

    /// @notice Internal function to spend Ink from a user's balance.
    /// Updates balances and emits event.
    /// @param user The user spending Ink.
    /// @param amount The amount of Ink to spend.
    /// @param actionType The type of action the Ink is spent on.
    function _spendInk(address user, uint256 amount, bytes32 actionType) internal {
        require(inkBalances[user] >= amount, "Insufficient Ink balance");
        inkBalances[user] = inkBalances[user].sub(amount);
        // Note: totalInkSupply doesn't change unless Ink is burned/minted, which we don't do on spend here.
        emit InkSpent(user, actionType, amount);

        // Optionally, collect fees in Ink or ETH here.
        // Example: If ACTION_PAINT cost 10 Ink, maybe 1 Ink goes to a treasury.
        // This example just deducts the full cost.
    }

    /// @notice Gets the current Ink cost for a specific action type.
    /// @param actionType The identifier for the action.
    /// @return The required Ink amount.
    function getInkCostForAction(bytes32 actionType) public view returns (uint256) {
        return inkCosts[actionType];
    }

    // --- Querying Canvas State ---

    /// @notice Returns the overall dimensions of the canvas grid.
    /// @return width The canvas width.
    /// @return height The canvas height.
    function getCanvasDimensions() public view returns (uint16 width, uint16 height) {
        require(_isCanvasInitialized, "Canvas not initialized");
        return (canvasWidth, canvasHeight);
    }

     // --- ERC721 Metadata ---

    /// @notice Returns the metadata URI for a specific plot NFT.
    /// Owner can set this, or it can be generated based on plot attributes/history.
    /// @param tokenId The ID of the plot.
    /// @return The metadata URI string.
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721: URI query for nonexistent token");
        // Can return a fixed base URI + token ID, or use the custom field
        string memory customURI = plots[tokenId].metadataURI;
        if (bytes(customURI).length > 0) {
            return customURI;
        }
        // Fallback or generate a dynamic URI based on state if preferred
        return super.tokenURI(tokenId); // Defaults to baseURI if set
    }

    /// @notice Allows the plot owner to set a custom metadata URI for their plot.
    /// @param plotId The ID of the plot.
    /// @param uri The URI string.
    function setPlotMetadataURI(uint256 plotId, string calldata uri) external {
        require(_exists(plotId), "Plot does not exist");
        require(ownerOf(plotId) == msg.sender, "Not plot owner");
        plots[plotId].metadataURI = uri;
        // No event in ERC721 standard for metadata update, but could add one.
    }

    // --- ERC165 Support ---

    function supportsInterface(bytes4 interfaceId) public view override returns (bool) {
        // Support ERC721, ERC721Metadata, ERC165
        return interfaceId == type(IERC721).interfaceId
            || interfaceId == type(IERC721Metadata).interfaceId
            || interfaceId == type(IERC165).interfaceId
            || super.supportsInterface(interfaceId);
    }

    // --- Fallback/Receive (Optional, for ETH fees if implemented) ---
     // This example collects ETH in withdrawFees, so a receive/fallback is needed
     receive() external payable {
         // Any received ETH is added to the fees collected balance
         totalFeesCollected = totalFeesCollected.add(msg.value);
     }

     fallback() external payable {
          totalFeesCollected = totalFeesCollected.add(msg.value);
     }
}
```

---

**Explanation of Advanced/Creative Concepts:**

1.  **Hybrid ERC-721 with Custom Data:** The `plots` mapping stores extensive custom data (`PlotData` struct) directly linked to the ERC-721 token ID, going beyond just ownership and token URI. This includes spatial coordinates, dimensions, the latest state, and a history counter.
2.  **Internal, Action-Specific Resource (Ink):** Instead of a separate ERC-20 token, "Ink" is an internal balance managed within the contract. It's not freely transferable between users (except via admin distribution or potentially future mechanics like trading *for* ink), but is consumed by specific actions. This creates an economy internal to the canvas interactions.
3.  **On-Chain History/Layers:** The `plotHistory` mapping stores an array of past states (`PlotHistoryEntry`) for each plot. Each paint action pushes the *previous* state to this array before updating the `latestPaintData`. This builds a permanent, verifiable chronicle of how each plot evolved.
4.  **History Manipulation Mechanics:**
    *   `getPlotHistoryLength` and `getPlotHistoryEntry` allow querying the past.
    *   `revertPlotToHistory` introduces a unique mechanic allowing owners to jump back in time on their plot, at a cost. This permanently removes all history *after* the chosen point, altering the timeline. This uses low-level assembly for efficient array truncation (though still gas-intensive for large histories).
    *   `clearPlotHistory` is another costly action to erase the past entirely.
5.  **Dynamic Plot Geometry (Conceptual):** `subdividePlot` and `mergePlots` functions allow the underlying NFT "shape" and count to change based on owner actions. This is conceptually advanced; the actual on-chain geometry validation (ensuring splits/merges are valid rectangles, tile correctly, stay within bounds) is highly complex and simplified in this example, assuming validity is handled off-chain by the caller/UI.
6.  **Action Cost Configuration:** `setInkCostForAction` makes the economic model flexible, allowing the owner/admin to tune the difficulty/cost of different actions based on the desired game mechanics or artistic flow. Using `bytes32` keys makes it extensible.
7.  **Pausable Actions:** Implementing `Pausable` allows the admin to halt user-initiated modification actions (`paint`, `subdivide`, `merge`, `revert`, `clear`) in case of issues, upgrades, or during specific events.
8.  **Explicit Fee Collection:** The contract includes a basic mechanism (`totalFeesCollected`, `withdrawFees`, `receive`/`fallback`) to collect ETH sent with transactions, which could be tied to certain actions as a fee model.
9.  **ERC-721 Metadata Extension:** `setPlotMetadataURI` allows plot owners to link external metadata specific to their plot, potentially reflecting its history or current state, beyond the standard ERC-721 base URI.
10. **History Timestamping:** Each history entry records the `block.timestamp` when the action occurred, adding a temporal dimension to the chronicle.

This contract is significantly more complex than basic ERC-721 mint-and-transfer contracts and introduces state-changing mechanics beyond simple ownership updates, focusing on user interaction with a shared, evolving digital asset. The history tracking and manipulation features, combined with resource management and dynamic geometry (even if simplified), make it a creative and advanced concept.