Okay, let's create a smart contract that manages a dynamic, generative digital canvas on-chain. Users will own "Plots" (custom NFTs) on this canvas, interact with cells within their plots using a custom token "Essence," and influence the overall canvas "Vibrancy." The canvas itself will have state that can be interpreted off-chain for visualization.

This concept involves:
1.  **Custom NFT-like Plots:** Not standard ERC721, but similar ownership and data mapping for areas of the canvas. Dynamic properties based on interaction.
2.  **Custom Fungible Token:** "Essence" used for interactions. Not standard ERC20, but similar balance tracking and transfer logic.
3.  **Shared State Grid:** The core canvas state, updated by users.
4.  **Dynamic Parameter:** "Vibrancy" of the canvas, affected by interactions and time.
5.  **Generative Potential:** The on-chain state serves as a seed/input for off-chain generative art interpretation.
6.  **Simple Governance:** Plot owners can propose/vote on certain canvas parameters.

This avoids direct duplication of standard ERC20/ERC721 contracts while using similar underlying patterns, and adds unique state management, interaction logic, and a generative focus.

---

**EtherealCanvas Smart Contract: Outline and Function Summary**

**Contract Name:** `EtherealCanvas`

**Description:** A decentralized platform managing a shared, evolving digital canvas. Users acquire 'Plots' (custom NFTs) on this grid, using 'Essence' (a custom fungible token) to interact with and modify the cells within their plots. User activity influences the overall canvas 'Vibrancy,' and the canvas state serves as input for potential off-chain generative art. Plot owners have limited governance capabilities.

**Outline:**

1.  **State Variables:** Defines dimensions, costs, tokens, plots, canvas state, vibrancy, governance.
2.  **Events:** Announces key actions (minting, transfers, updates, etc.).
3.  **Modifiers:** Controls access (owner, plot owner, proposal state).
4.  **Error Handling:** Custom errors for clarity.
5.  **Structs:** Defines complex data types (PlotInfo, Proposal).
6.  **Core Logic (Internal Functions):** Helpers for state updates, checks, etc.
7.  **Constructor:** Initializes contract state.
8.  **Ownership & Access Control:** Standard owner functions.
9.  **Plot Management (Custom NFTs):** Minting, transferring, merging, retrieving info.
10. **Canvas Interaction:** Updating cells (color, pattern), resetting areas within plots.
11. **Essence Token Management (Custom Fungible):** Balances, transfers, approval, minting/burning related to activity.
12. **Canvas State & Vibrancy:** Retrieving cell state, getting vibrancy, simulating vibrancy decay.
13. **Governance:** Creating proposals, voting, executing proposals.
14. **Utility/Emergency:** Emergency withdrawal.

**Function Summary:**

1.  `constructor(uint256 initialCanvasWidth, uint256 initialCanvasHeight, uint256 initialEssenceSupply)`: Initializes the canvas dimensions, mints initial Essence supply to the deployer, sets owner.
2.  `setCanvasDimensions(uint256 newWidth, uint256 newHeight)`: Owner-only. Sets new canvas dimensions (with constraints if plots exist).
3.  `setBaseInteractionCost(uint256 cost)`: Owner-only. Sets the base cost in Essence for cell interactions.
4.  `grantPatternPermission(uint8 patternId, bool allowed)`: Owner-only. Grants or revokes permission for a specific pattern ID to be used on the canvas.
5.  `mintPlot(uint256 x, uint256 y, uint256 width, uint256 height)`: Allows a user to mint a new plot at given coordinates and size, if available and cost is paid in Essence.
6.  `transferPlot(address to, uint256 plotTokenId)`: Allows a plot owner to transfer their plot to another address.
7.  `mergePlots(uint256 plotTokenId1, uint256 plotTokenId2)`: Allows a user to merge two adjacent plots they own into a single larger plot.
8.  `getPlotOwner(uint256 plotTokenId)`: Returns the owner of a specific plot token ID.
9.  `getPlotInfo(uint256 plotTokenId)`: Returns the coordinates, dimensions, and owner of a specific plot.
10. `getUserPlots(address user)`: *Helper View (Potentially Gas Intensive)* Returns an array of plot token IDs owned by a user. (Note: Efficiently tracking this on-chain is hard; off-chain indexing is better). *Alternative: Return total number of plots and require off-chain lookup.* Let's keep it simple and acknowledge the cost or change it. *Refinement: Let's just provide `getPlotOwner` and rely on off-chain indexing for user inventories.* Need a replacement function... how about getting total plots minted?
11. `getTotalPlotsMinted()`: Returns the total number of plot tokens minted.
12. `updateCellColor(uint256 plotTokenId, uint256 cellX, uint256 cellY, uint8 color)`: Allows a plot owner to change the color of a cell within their plot's boundaries. Costs Essence and affects Vibrancy.
13. `applyPattern(uint256 plotTokenId, uint8 patternId, uint8 color)`: Allows a plot owner to apply an allowed pattern within their plot's boundaries. Costs more Essence and affects Vibrancy more significantly.
14. `resetPlotArea(uint256 plotTokenId)`: Allows a plot owner to reset all cells within their plot to a default state. Costs Essence.
15. `balanceOfEssence(address account)`: Returns the Essence balance of an account.
16. `transferEssence(address recipient, uint256 amount)`: Transfers Essence from the caller to a recipient.
17. `approveEssence(address spender, uint256 amount)`: Approves a spender to withdraw Essence from the caller's balance.
18. `transferFromEssence(address sender, address recipient, uint256 amount)`: Transfers Essence from a sender's balance (if approved) to a recipient.
19. `claimEssenceForActivity()`: Allows users to claim accumulated Essence rewards based on their activity (e.g., interactions count, plot size, time owned). (Mechanism needs design; let's keep it abstract for now, perhaps a simple claimable balance based on interactions). *Refinement: Make interactions *cost* Essence, and owner collects. Let's add a function to *mint* Essence for staking plots instead.*
20. `stakePlotForEssence(uint256 plotTokenId)`: Allows a plot owner to stake their plot to earn passive Essence over time.
21. `unstakePlot(uint256 plotTokenId)`: Allows a plot owner to unstake their plot and claim earned Essence.
22. `getCanvasCellState(uint256 x, uint256 y)`: Returns the state (color, pattern ID) of a specific cell on the canvas.
23. `getCanvasVibrancy()`: Returns the current global canvas vibrancy score.
24. `decayCanvasVibrancy()`: Allows anyone to call and trigger a decay of the canvas vibrancy based on elapsed time, encouraging activity.
25. `createParameterChangeProposal(string description, uint8 paramType, uint256 newValue)`: Allows a plot owner to create a proposal to change a canvas parameter. Requires minimum plot area owned.
26. `voteOnProposal(uint256 proposalId, bool support)`: Allows a plot owner to vote on an active proposal. Voting power based on owned plot area.
27. `executeProposal(uint256 proposalId)`: Executes a successful proposal if the voting period is over and quorum/majority conditions are met.
28. `getProposalState(uint256 proposalId)`: Returns the current state and details of a proposal.
29. `emergencyWithdraw(address token, uint256 amount)`: Owner-only. Allows withdrawal of arbitrary tokens stuck in the contract (e.g., accidentally sent ERC20s).
30. `withdrawCollectedEssence(address recipient)`: Owner-only. Allows the owner to withdraw Essence collected from interaction fees.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title EtherealCanvas
 * @dev A decentralized platform managing a shared, evolving digital canvas.
 * Users acquire 'Plots' (custom NFTs) on this grid, using 'Essence' (a custom fungible token)
 * to interact with and modify the cells within their plots. User activity influences the
 * overall canvas 'Vibrancy,' and the canvas state serves as input for potential off-chain
 * generative art. Plot owners have limited governance capabilities.
 */
contract EtherealCanvas {

    // --- State Variables ---

    address public owner;

    // Canvas dimensions and state
    uint256 public canvasWidth;
    uint256 public canvasHeight;
    // Mapping from x coordinate to y coordinate to cell state (packed color and pattern ID)
    mapping(uint256 => mapping(uint256 => uint16)) private canvasGrid; // color (8 bits) | patternId (8 bits)

    uint256 public baseInteractionCost; // Cost in Essence per cell interaction
    uint256 public patternApplicationMultiplier = 5; // Multiplier for pattern cost

    // Canvas Vibrancy (0-10000 range, higher = more vibrant/recent activity)
    uint256 public canvasVibrancy = 5000; // Initial vibrancy
    uint256 private lastVibrancyDecayTimestamp;
    uint256 public vibrancyDecayRatePerSecond = 1; // How much vibrancy decays per second

    // Essence Token (Custom Fungible)
    string public constant ESSENCE_NAME = "Essence of Creation";
    string public constant ESSENCE_SYMBOL = "ESS";
    uint8 public constant ESSENCE_DECIMALS = 18; // Standard 18 decimals
    uint256 private _totalSupplyEssence;
    mapping(address => uint256) private _essenceBalances;
    mapping(address => mapping(address => uint256)) private _essenceAllowances; // For transferFrom

    // Plot Management (Custom NFT-like)
    struct PlotInfo {
        address owner;
        uint256 x;
        uint256 y;
        uint256 width;
        uint256 height;
        uint256 stakedTimestamp; // 0 if not staked, timestamp if staked
    }
    uint256 private nextPlotTokenId = 1;
    mapping(uint256 => PlotInfo) private _plotData;
    mapping(uint256 => bool) private _plotExists; // Helps track existence easily

    // Approved Patterns
    mapping(uint8 => bool) public allowedPatterns; // patternId => isAllowed

    // Governance
    struct Proposal {
        string description;
        uint256 proposalId;
        address proposer;
        uint8 paramType; // 1: BaseInteractionCost, 2: PatternMultiplier, 3: VibrancyDecayRate, ... (add more types)
        uint256 newValue;
        uint256 createTimestamp;
        uint256 endTimestamp; // Voting ends
        uint256 votesFor; // Voting power (based on staked plot area)
        uint256 votesAgainst; // Voting power
        bool executed;
        mapping(address => bool) hasVoted; // Ensure users only vote once per proposal
        uint256 requiredVotePowerForExecution; // Total staked area required for execution
    }
    uint256 public nextProposalId = 1;
    mapping(uint256 => Proposal) public proposals;
    uint256 public votingPeriodDuration = 3 days; // Duration for voting
    uint256 public minPlotAreaForProposal = 100; // Minimum area of staked plots to create a proposal
    uint256 public executionThresholdNumerator = 2; // Majority required (e.g., 2/3 = 66.7%)
    uint256 public executionThresholdDenominator = 3;
    uint256 public minStakedAreaForQuorum = 500; // Minimum total staked area needed for a vote to be valid

    uint256 public totalStakedArea = 0; // Sum of area of all staked plots

    // --- Events ---

    event PlotMinted(address indexed owner, uint256 indexed plotTokenId, uint256 x, uint256 y, uint256 width, uint256 height);
    event PlotTransferred(address indexed from, address indexed to, uint256 indexed plotTokenId);
    event PlotsMerged(address indexed owner, uint256 indexed plotTokenId1, uint256 indexed plotTokenId2, uint256 newPlotTokenId);
    event CellUpdated(uint256 indexed plotTokenId, uint256 x, uint256 y, uint16 newState);
    event PlotAreaReset(uint256 indexed plotTokenId);

    event EssenceTransfer(address indexed from, address indexed to, uint256 value);
    event EssenceApproval(address indexed owner, address indexed spender, uint256 value);
    event EssenceClaimed(address indexed account, uint256 amount); // For staking rewards
    event PlotStaked(uint256 indexed plotTokenId, address indexed owner, uint256 stakedArea);
    event PlotUnstaked(uint256 indexed plotTokenId, address indexed owner, uint256 earnedEssence);

    event VibrancyDecayed(uint256 newVibrancy);
    event ParameterChangeProposalCreated(uint256 indexed proposalId, address indexed proposer, uint8 paramType, uint256 newValue, uint256 endTimestamp);
    event Voted(uint256 indexed proposalId, address indexed voter, bool support, uint256 votingPower);
    event ProposalExecuted(uint256 indexed proposalId);

    // --- Modifiers ---

    modifier onlyOwner() {
        require(msg.sender == owner, "EC: Not owner");
        _;
    }

    modifier onlyPlotOwner(uint256 plotTokenId) {
        require(_plotData[plotTokenId].owner == msg.sender, "EC: Not plot owner");
        _;
    }

    // --- Error Handling (Custom Errors) ---

    error ECCanvasOutOfBounds();
    error ECPlotOverlap();
    error ECPlotDoesNotExist();
    error ECPlotAlreadyExists();
    error ECPlotNotOwned();
    error ECPlotMergeInvalid(); // e.g., not adjacent, different owners, already merged
    error ECCellNotInPlot();

    error ECCustomTokenInsufficientBalance();
    error ECCustomTokenInsufficientAllowance();

    error ECPatternNotAllowed();

    error ECVibrancyCannotDecayYet();

    error ECProposalInvalidParamType();
    error ECProposalVoteAlreadyCast();
    error ECProposalDoesNotExist();
    error ECProposalVotingNotActive();
    error ECProposalVotingPeriodActive();
    error ECProposalNotExecutable();
    error ECProposalAlreadyExecuted();
    error ECProposalNotEnoughStakedArea();

    // --- Structs ---
    // Defined above in State Variables section for PlotInfo and Proposal

    // --- Core Logic (Internal Helpers) ---

    function _isCellInBounds(uint256 x, uint256 y) internal view returns (bool) {
        return x < canvasWidth && y < canvasHeight;
    }

    function _isPlotAreaAvailable(uint256 x, uint256 y, uint256 width, uint256 height) internal view returns (bool) {
        if (!_isCellInBounds(x, y) || !_isCellInBounds(x + width - 1, y + height - 1)) {
            return false; // Area outside canvas bounds
        }

        // Simple (gas-intensive) check for overlaps with existing plots
        // In a real scenario with many plots, this would need optimization (e.g., quadtree off-chain)
        // For demonstration, we iterate over potential plot token IDs up to the next minted ID.
        // This is highly inefficient for a large number of plots.
        uint256 currentPlotId = 1;
        while (currentPlotId < nextPlotTokenId) {
            if (_plotExists[currentPlotId]) {
                PlotInfo storage existingPlot = _plotData[currentPlotId];
                // Check for overlap: [x, x+width) overlaps with [existingPlot.x, existingPlot.x+existingPlot.width)
                // AND [y, y+height) overlaps with [existingPlot.y, existingPlot.y+existingPlot.height)
                bool xOverlap = (x < existingPlot.x + existingPlot.width) && (existingPlot.x < x + width);
                bool yOverlap = (y < existingPlot.y + existingPlot.height) && (existingPlot.y < y + height);
                if (xOverlap && yOverlap) {
                    return false; // Overlap found
                }
            }
            currentPlotId++;
        }
        return true; // No overlap
    }

    function _encodeCellState(uint8 color, uint8 patternId) internal pure returns (uint16) {
        return (uint16(color) << 8) | uint16(patternId);
    }

    function _decodeCellState(uint16 state, bytes1 field) internal pure returns (uint8) {
        if (field == "color") {
            return uint8(state >> 8);
        } else if (field == "patternId") {
            return uint8(state & 0xFF);
        }
        revert("EC: Invalid decode field"); // Should not happen with internal calls
    }

    function _updateVibrancy(uint256 change) internal {
        // Ensure vibrancy does not exceed 10000
        canvasVibrancy = Math.min(canvasVibrancy + change, 10000);
        // Note: Decay happens via decayCanvasVibrancy function
    }

    function _decayVibrancy() internal {
        uint256 currentTime = block.timestamp;
        uint256 timeElapsed = currentTime - lastVibrancyDecayTimestamp;
        uint256 decayAmount = timeElapsed * vibrancyDecayRatePerSecond;

        if (decayAmount > 0) {
             // Ensure vibrancy does not drop below 0
            canvasVibrancy = (canvasVibrancy > decayAmount) ? canvasVibrancy - decayAmount : 0;
            lastVibrancyDecayTimestamp = currentTime;
            emit VibrancyDecayed(canvasVibrancy);
        }
    }

    // --- Constructor ---

    /**
     * @dev Initializes the EtherealCanvas contract.
     * @param initialCanvasWidth The width of the canvas grid.
     * @param initialCanvasHeight The height of the canvas grid.
     * @param initialEssenceSupply The total supply of Essence to be minted initially to the deployer.
     */
    constructor(uint256 initialCanvasWidth, uint256 initialCanvasHeight, uint256 initialEssenceSupply) {
        owner = msg.sender;
        canvasWidth = initialCanvasWidth;
        canvasHeight = initialCanvasHeight;
        lastVibrancyDecayTimestamp = block.timestamp;

        // Mint initial Essence supply to owner
        _mintEssence(msg.sender, initialEssenceSupply);

        // Default pattern 0 (no pattern) is always allowed
        allowedPatterns[0] = true;
    }

    // --- Ownership & Access Control ---

    /**
     * @notice Transfers ownership of the contract to a new address.
     * @param newOwner The address of the new owner.
     */
    function setOwner(address newOwner) external onlyOwner {
        require(newOwner != address(0), "EC: New owner is zero address");
        owner = newOwner;
    }

    // --- Configuration (Owner Only) ---

    /**
     * @notice Sets the dimensions of the canvas.
     * @dev Can only be set if no plots have been minted yet, to avoid breaking plot coordinates.
     * @param newWidth The new canvas width.
     * @param newHeight The new canvas height.
     */
    function setCanvasDimensions(uint256 newWidth, uint256 newHeight) external onlyOwner {
         require(nextPlotTokenId == 1, "EC: Cannot change dimensions after plots minted");
         require(newWidth > 0 && newHeight > 0, "EC: Dimensions must be positive");
         canvasWidth = newWidth;
         canvasHeight = newHeight;
    }

    /**
     * @notice Sets the base cost in Essence for interacting with a single cell.
     * @param cost The new base cost.
     */
    function setBaseInteractionCost(uint256 cost) external onlyOwner {
        baseInteractionCost = cost;
    }

     /**
     * @notice Sets the multiplier for applying patterns compared to simple color updates.
     * @param multiplier The new pattern application multiplier.
     */
    function setPatternApplicationMultiplier(uint256 multiplier) external onlyOwner {
        patternApplicationMultiplier = multiplier;
    }

    /**
     * @notice Grants or revokes permission for a specific pattern ID to be used.
     * Pattern ID 0 (no pattern) cannot be revoked.
     * @param patternId The ID of the pattern.
     * @param allowed Whether the pattern is allowed (true) or disallowed (false).
     */
    function grantPatternPermission(uint8 patternId, bool allowed) external onlyOwner {
        require(patternId != 0, "EC: Pattern 0 permission is fixed");
        allowedPatterns[patternId] = allowed;
    }

    // --- Plot Management (Custom NFTs) ---

    /**
     * @notice Mints a new Plot token representing an area on the canvas.
     * @dev Requires payment in Essence. The area must be within bounds and not overlap existing plots.
     * @param x The starting X coordinate (top-left).
     * @param y The starting Y coordinate (top-left).
     * @param width The width of the plot.
     * @param height The height of the plot.
     */
    function mintPlot(uint256 x, uint256 y, uint256 width, uint256 height) external {
        require(width > 0 && height > 0, "EC: Plot dimensions must be positive");
        if (!_isCellInBounds(x, y) || !_isCellInBounds(x + width - 1, y + height - 1)) {
             revert ECCanvasOutOfBounds();
        }
        if (!_isPlotAreaAvailable(x, y, width, height)) {
            revert ECPlotOverlap();
        }

        // Calculate mint cost (example: based on area)
        uint256 area = width * height;
        uint256 mintCost = area * baseInteractionCost; // Example cost model

        _transferEssence(msg.sender, address(this), mintCost); // User pays Essence to the contract

        uint256 newTokenId = nextPlotTokenId++;
        _plotData[newTokenId] = PlotInfo({
            owner: msg.sender,
            x: x,
            y: y,
            width: width,
            height: height,
            stakedTimestamp: 0 // Initially not staked
        });
        _plotExists[newTokenId] = true;

        emit PlotMinted(msg.sender, newTokenId, x, y, width, height);
    }

    /**
     * @notice Transfers ownership of a Plot token.
     * @param to The address to transfer the plot to.
     * @param plotTokenId The ID of the plot token to transfer.
     */
    function transferPlot(address to, uint256 plotTokenId) external onlyPlotOwner(plotTokenId) {
        require(to != address(0), "EC: Transfer to zero address");
        PlotInfo storage plot = _plotData[plotTokenId];
        require(plot.stakedTimestamp == 0, "EC: Cannot transfer staked plot"); // Must unstake first

        address from = msg.sender;
        plot.owner = to;

        emit PlotTransferred(from, to, plotTokenId);
    }

    /**
     * @notice Merges two adjacent plots owned by the caller into a single larger plot.
     * @dev The two plots must share an entire side and form a rectangular region.
     * The smaller token ID plot is conceptually 'burned' and the larger token ID plot is updated.
     * @param plotTokenId1 The ID of the first plot.
     * @param plotTokenId2 The ID of the second plot.
     */
    function mergePlots(uint256 plotTokenId1, uint256 plotTokenId2) external {
        // Ensure both plots exist and are owned by the caller
        require(_plotExists[plotTokenId1], "EC: Plot 1 does not exist");
        require(_plotExists[plotTokenId2], "EC: Plot 2 does not exist");
        require(plotTokenId1 != plotTokenId2, "EC: Cannot merge plot with itself");
        require(_plotData[plotTokenId1].owner == msg.sender, "EC: Caller does not own Plot 1");
        require(_plotData[plotTokenId2].owner == msg.sender, "EC: Caller does not own Plot 2");
        require(_plotData[plotTokenId1].stakedTimestamp == 0 && _plotData[plotTokenId2].stakedTimestamp == 0, "EC: Cannot merge staked plots");

        PlotInfo storage plot1 = _plotData[plotTokenId1];
        PlotInfo storage plot2 = _plotData[plotTokenId2];

        uint256 x1 = plot1.x; uint256 y1 = plot1.y; uint256 w1 = plot1.width; uint256 h1 = plot1.height;
        uint256 x2 = plot2.x; uint256 y2 = plot2.y; uint256 w2 = plot2.width; uint256 h2 = plot2.height;

        bool adjacent = false;
        uint256 newX, newY, newWidth, newHeight;

        // Check if plot2 is directly to the right of plot1
        if (x1 + w1 == x2 && y1 == y2 && h1 == h2) {
            adjacent = true;
            newX = x1;
            newY = y1;
            newWidth = w1 + w2;
            newHeight = h1;
        }
        // Check if plot1 is directly to the right of plot2
        else if (x2 + w2 == x1 && y1 == y2 && h1 == h2) {
            adjacent = true;
            newX = x2;
            newY = y2;
            newWidth = w1 + w2;
            newHeight = h1;
        }
        // Check if plot2 is directly below plot1
        else if (y1 + h1 == y2 && x1 == x2 && w1 == w2) {
             adjacent = true;
             newX = x1;
             newY = y1;
             newWidth = w1;
             newHeight = h1 + h2;
        }
        // Check if plot1 is directly below plot2
         else if (y2 + h2 == y1 && x1 == x2 && w1 == w2) {
             adjacent = true;
             newX = x1;
             newY = y2;
             newWidth = w1;
             newHeight = h1 + h2;
        }

        require(adjacent, "EC: Plots are not adjacent or do not form a rectangle");

        // Determine which plot ID to keep (e.g., the lower one)
        uint256 plotToUpdateId = plotTokenId1 < plotTokenId2 ? plotTokenId1 : plotTokenId2;
        uint256 plotToBurnId = plotTokenId1 < plotTokenId2 ? plotTokenId2 : plotTokenId1;

        // Update the chosen plot's info
        PlotInfo storage plotToUpdate = _plotData[plotToUpdateId];
        plotToUpdate.x = newX;
        plotToUpdate.y = newY;
        plotToUpdate.width = newWidth;
        plotToUpdate.height = newHeight;

        // Remove the other plot
        delete _plotData[plotToBurnId];
        _plotExists[plotToBurnId] = false;
        // Note: Cell data on canvasGrid remains, it's not deleted per plot.

        emit PlotsMerged(msg.sender, plotTokenId1, plotTokenId2, plotToUpdateId);
    }

    /**
     * @notice Gets the owner of a specific Plot token ID.
     * @param plotTokenId The ID of the plot token.
     * @return The address of the plot owner.
     */
    function getPlotOwner(uint256 plotTokenId) external view returns (address) {
        require(_plotExists[plotTokenId], "EC: Plot does not exist");
        return _plotData[plotTokenId].owner;
    }

    /**
     * @notice Gets the information about a specific Plot token.
     * @param plotTokenId The ID of the plot token.
     * @return owner The address of the plot owner.
     * @return x The starting X coordinate.
     * @return y The starting Y coordinate.
     * @return width The width of the plot.
     * @return height The height of the plot.
     * @return isStaked Whether the plot is currently staked.
     */
    function getPlotInfo(uint256 plotTokenId) external view returns (address owner, uint256 x, uint256 y, uint256 width, uint256 height, bool isStaked) {
        require(_plotExists[plotTokenId], "EC: Plot does not exist");
        PlotInfo storage plot = _plotData[plotTokenId];
        return (plot.owner, plot.x, plot.y, plot.width, plot.height, plot.stakedTimestamp > 0);
    }

    /**
     * @notice Returns the total number of plot tokens that have been minted.
     */
    function getTotalPlotsMinted() external view returns (uint256) {
        return nextPlotTokenId - 1;
    }


    // --- Canvas Interaction ---

    /**
     * @notice Updates the color of a single cell within a plot.
     * @param plotTokenId The ID of the plot.
     * @param cellX The X coordinate of the cell (absolute canvas coordinate).
     * @param cellY The Y coordinate of the cell (absolute canvas coordinate).
     * @param color The new color value (0-255).
     */
    function updateCellColor(uint256 plotTokenId, uint256 cellX, uint256 cellY, uint8 color) external onlyPlotOwner(plotTokenId) {
        PlotInfo storage plot = _plotData[plotTokenId];

        // Check if cell is within plot boundaries
        if (cellX < plot.x || cellX >= plot.x + plot.width || cellY < plot.y || cellY >= plot.y + plot.height) {
            revert ECCellNotInPlot();
        }

        _transferEssence(msg.sender, address(this), baseInteractionCost); // Pay interaction cost

        // Get existing state, update color, keep pattern
        uint16 currentState = canvasGrid[cellX][cellY];
        uint8 currentPatternId = _decodeCellState(currentState, "patternId");
        uint16 newState = _encodeCellState(color, currentPatternId);
        canvasGrid[cellX][cellY] = newState;

        _updateVibrancy(10); // Increase vibrancy slightly
         _decayVibrancy(); // Apply decay based on time passed since last interaction/decay

        emit CellUpdated(plotTokenId, cellX, cellY, newState);
    }

    /**
     * @notice Applies a pattern to all cells within a plot's boundaries.
     * @param plotTokenId The ID of the plot.
     * @param patternId The ID of the pattern to apply.
     * @param color The base color for the pattern.
     */
    function applyPattern(uint256 plotTokenId, uint8 patternId, uint8 color) external onlyPlotOwner(plotTokenId) {
        require(allowedPatterns[patternId], "EC: Pattern not allowed");

        PlotInfo storage plot = _plotData[plotTokenId];
        uint256 area = plot.width * plot.height;
        uint256 cost = baseInteractionCost * area * patternApplicationMultiplier;

        _transferEssence(msg.sender, address(this), cost); // Pay interaction cost

        // Apply pattern (simplified: just updates patternId and color for all cells)
        // A more advanced version would modify colors based on the pattern logic
        uint16 newState = _encodeCellState(color, patternId);
         for (uint256 x = plot.x; x < plot.x + plot.width; x++) {
            for (uint256 y = plot.y; y < plot.y + plot.height; y++) {
                 canvasGrid[x][y] = newState;
             }
         }

        _updateVibrancy(area * 50); // Increase vibrancy significantly based on area/pattern
         _decayVibrancy(); // Apply decay

        // Emit a single event or per cell? Per cell can be expensive. Let's emit a plot area reset style event.
         emit PlotAreaReset(plotTokenId); // Using this event to signify bulk update for off-chain indexers
         // Potentially add a dedicated event for pattern application if needed off-chain
    }

    /**
     * @notice Resets all cells within a plot's boundaries to a default state (e.g., color 0, no pattern).
     * @param plotTokenId The ID of the plot.
     */
    function resetPlotArea(uint256 plotTokenId) external onlyPlotOwner(plotTokenId) {
        PlotInfo storage plot = _plotData[plotTokenId];
        uint256 area = plot.width * plot.height;
        uint256 cost = baseInteractionCost * area / 2; // Example cost: half of per-cell cost

        _transferEssence(msg.sender, address(this), cost); // Pay interaction cost

        uint16 defaultState = _encodeCellState(0, 0); // Color 0, Pattern 0
         for (uint256 x = plot.x; x < plot.x + plot.width; x++) {
            for (uint256 y = plot.y; y < plot.y + plot.height; y++) {
                 canvasGrid[x][y] = defaultState;
             }
         }

        _updateVibrancy(area * 5); // Slight vibrancy increase
         _decayVibrancy(); // Apply decay

        emit PlotAreaReset(plotTokenId);
    }


    // --- Essence Token Management (Custom Fungible) ---
    // Implementing basic ERC20-like functions internally, not inheriting

    /**
     * @notice Returns the total supply of Essence tokens.
     */
    function totalSupplyEssence() external view returns (uint256) {
        return _totalSupplyEssence;
    }

    /**
     * @notice Returns the balance of Essence tokens for a given account.
     * @param account The address to query the balance of.
     * @return The amount of Essence owned by the account.
     */
    function balanceOfEssence(address account) public view returns (uint256) {
        return _essenceBalances[account];
    }

    /**
     * @notice Transfers Essence tokens from the caller to a recipient.
     * @param recipient The address to transfer tokens to.
     * @param amount The amount of tokens to transfer.
     * @return A boolean indicating success.
     */
    function transferEssence(address recipient, uint256 amount) external returns (bool) {
        _transferEssence(msg.sender, recipient, amount);
        return true;
    }

    /**
     * @notice Approves a spender to spend a specified amount of Essence on behalf of the caller.
     * @param spender The address authorized to spend.
     * @param amount The maximum amount the spender can spend.
     * @return A boolean indicating success.
     */
    function approveEssence(address spender, uint256 amount) external returns (bool) {
        _essenceAllowances[msg.sender][spender] = amount;
        emit EssenceApproval(msg.sender, spender, amount);
        return true;
    }

    /**
     * @notice Transfers Essence tokens from a sender to a recipient using the allowance mechanism.
     * @param sender The address from which tokens are transferred.
     * @param recipient The address to transfer tokens to.
     * @param amount The amount of tokens to transfer.
     * @return A boolean indicating success.
     */
    function transferFromEssence(address sender, address recipient, uint256 amount) external returns (bool) {
        uint256 currentAllowance = _essenceAllowances[sender][msg.sender];
        if (currentAllowance < amount) {
            revert ECCustomTokenInsufficientAllowance();
        }
        // Decrease allowance (avoiding potential reentrancy if recipient is this contract)
        _essenceAllowances[sender][msg.sender] = currentAllowance - amount;

        _transferEssence(sender, recipient, amount);
        return true;
    }

    /**
     * @dev Internal function to transfer Essence tokens.
     */
    function _transferEssence(address sender, address recipient, uint256 amount) internal {
        if (_essenceBalances[sender] < amount) {
            revert ECCustomTokenInsufficientBalance();
        }
        _essenceBalances[sender] -= amount;
        _essenceBalances[recipient] += amount;
        emit EssenceTransfer(sender, recipient, amount);
    }

    /**
     * @dev Internal function to mint Essence tokens.
     */
    function _mintEssence(address account, uint256 amount) internal {
        require(account != address(0), "EC: Mint to zero address");
        _totalSupplyEssence += amount;
        _essenceBalances[account] += amount;
        emit EssenceTransfer(address(0), account, amount);
    }

    /**
     * @dev Internal function to burn Essence tokens.
     */
    function _burnEssence(address account, uint256 amount) internal {
         if (_essenceBalances[account] < amount) {
            revert ECCustomTokenInsufficientBalance();
        }
        _essenceBalances[account] -= amount;
        _totalSupplyEssence -= amount;
        emit EssenceTransfer(account, address(0), amount);
    }

    /**
     * @notice Allows a plot owner to stake their plot to earn passive Essence.
     * @param plotTokenId The ID of the plot token to stake.
     */
    function stakePlotForEssence(uint256 plotTokenId) external onlyPlotOwner(plotTokenId) {
         PlotInfo storage plot = _plotData[plotTokenId];
         require(plot.stakedTimestamp == 0, "EC: Plot already staked");

         plot.stakedTimestamp = block.timestamp;
         uint256 area = plot.width * plot.height;
         totalStakedArea += area;

         emit PlotStaked(plotTokenId, msg.sender, area);
    }

     /**
     * @notice Allows a plot owner to unstake their plot and claim accumulated Essence.
     * @param plotTokenId The ID of the plot token to unstake.
     */
    function unstakePlot(uint256 plotTokenId) external onlyPlotOwner(plotTokenId) {
        PlotInfo storage plot = _plotData[plotTokenId];
        require(plot.stakedTimestamp > 0, "EC: Plot is not staked");

        uint256 area = plot.width * plot.height;
        uint256 timeStaked = block.timestamp - plot.stakedTimestamp;

        // Simple reward calculation: Essence = area * timeStaked * some_rate (example)
        // A more sophisticated model might consider total staked area, network activity, etc.
        // Let's use a simplified rate like 1 Essence per area per day (86400 seconds) scaled down
        uint256 rewardRate = 100; // Example: 100 Essence units per area per day * 1e18 / 86400 (scaled)
        uint256 earnedEssence = (area * timeStaked * rewardRate) / (1 days / 1e18); // Scale back up

        plot.stakedTimestamp = 0; // Mark as unstaked
        totalStakedArea -= area;

        if (earnedEssence > 0) {
            // Mint new Essence for staking rewards
            _mintEssence(msg.sender, earnedEssence);
            emit EssenceClaimed(msg.sender, earnedEssence);
        }

         emit PlotUnstaked(plotTokenId, msg.sender, earnedEssence);
    }


    // --- Canvas State & Vibrancy ---

    /**
     * @notice Gets the state (color and pattern ID) of a specific cell on the canvas.
     * @param x The X coordinate of the cell.
     * @param y The Y coordinate of the cell.
     * @return color The color of the cell (0-255).
     * @return patternId The pattern ID applied to the cell (0-255).
     */
    function getCanvasCellState(uint256 x, uint256 y) external view returns (uint8 color, uint8 patternId) {
        if (!_isCellInBounds(x, y)) {
            revert ECCanvasOutOfBounds();
        }
        uint16 state = canvasGrid[x][y];
        return (_decodeCellState(state, "color"), _decodeCellState(state, "patternId"));
    }

    /**
     * @notice Gets the current global canvas vibrancy score.
     */
    function getCanvasVibrancy() external view returns (uint256) {
        return canvasVibrancy;
    }

     /**
     * @notice Triggers a decay of the canvas vibrancy based on elapsed time since the last decay.
     * Can be called by anyone. Rewards incentivized off-chain keepers.
     */
    function decayCanvasVibrancy() external {
        _decayVibrancy();
    }

    // --- Governance ---

    /**
     * @notice Allows a user owning sufficient staked plot area to create a parameter change proposal.
     * @param description A description of the proposal.
     * @param paramType The type of parameter to change (see Proposal struct comments).
     * @param newValue The new value proposed for the parameter.
     */
    function createParameterChangeProposal(string calldata description, uint8 paramType, uint256 newValue) external {
        require(bytes(description).length > 0, "EC: Description cannot be empty");
        require(paramType > 0, "EC: Invalid parameter type"); // paramType 0 is reserved/invalid

        uint256 callerStakedArea = 0;
        uint256 currentPlotId = 1;
        // Calculate staked area owned by caller (gas-intensive loop!)
         while (currentPlotId < nextPlotTokenId) {
            if (_plotExists[currentPlotId] && _plotData[currentPlotId].owner == msg.sender && _plotData[currentPlotId].stakedTimestamp > 0) {
                callerStakedArea += _plotData[currentPlotId].width * _plotData[currentPlotId].height;
            }
            currentPlotId++;
        }
        require(callerStakedArea >= minPlotAreaForProposal, "EC: Not enough staked plot area to propose");

        uint256 proposalId = nextProposalId++;
        proposals[proposalId] = Proposal({
            description: description,
            proposalId: proposalId,
            proposer: msg.sender,
            paramType: paramType,
            newValue: newValue,
            createTimestamp: block.timestamp,
            endTimestamp: block.timestamp + votingPeriodDuration,
            votesFor: 0,
            votesAgainst: 0,
            executed: false,
            hasVoted: mapping(address => bool){}, // Initialize empty mapping
            requiredVotePowerForExecution: totalStakedArea // Snapshot total staked area at proposal creation
        });

        emit ParameterChangeProposalCreated(proposalId, msg.sender, paramType, newValue, proposals[proposalId].endTimestamp);
    }

    /**
     * @notice Allows a staked plot owner to vote on an active proposal.
     * @param proposalId The ID of the proposal to vote on.
     * @param support True for yes vote, false for no vote.
     */
    function voteOnProposal(uint256 proposalId, bool support) external {
        Proposal storage proposal = proposals[proposalId];
        if (proposal.proposalId == 0) revert ECProposalDoesNotExist(); // Check if proposal exists
        if (block.timestamp > proposal.endTimestamp) revert ECProposalVotingNotActive();
        if (proposal.hasVoted[msg.sender]) revert ECProposalVoteAlreadyCast();

        uint256 voterStakedArea = 0;
         uint256 currentPlotId = 1;
         // Calculate staked area owned by caller (gas-intensive loop!)
         while (currentPlotId < nextPlotTokenId) {
            if (_plotExists[currentPlotId] && _plotData[currentPlotId].owner == msg.sender && _plotData[currentPlotId].stakedTimestamp > 0) {
                voterStakedArea += _plotData[currentPlotId].width * _plotData[currentPlotId].height;
            }
            currentPlotId++;
        }
        require(voterStakedArea > 0, "EC: Must have staked plot area to vote");

        if (support) {
            proposal.votesFor += voterStakedArea;
        } else {
            proposal.votesAgainst += voterStakedArea;
        }
        proposal.hasVoted[msg.sender] = true;

        emit Voted(proposalId, msg.sender, support, voterStakedArea);
    }

     /**
     * @notice Executes a proposal if the voting period is over, quorum is met, and it passed.
     * Can be called by anyone.
     * @param proposalId The ID of the proposal to execute.
     */
    function executeProposal(uint256 proposalId) external {
        Proposal storage proposal = proposals[proposalId];
        if (proposal.proposalId == 0) revert ECProposalDoesNotExist();
        if (proposal.executed) revert ECProposalAlreadyExecuted();
        if (block.timestamp <= proposal.endTimestamp) revert ECProposalVotingPeriodActive();

        uint256 totalVotes = proposal.votesFor + proposal.votesAgainst;

        // Check quorum: Ensure sufficient staked area participated in the vote
        if (totalVotes < minStakedAreaForQuorum) {
            revert ECProposalNotExecutable(); // Quorum not met
        }

        // Check majority: Votes for must meet the threshold of required vote power
        uint256 requiredVotesFor = (proposal.requiredVotePowerForExecution * executionThresholdNumerator) / executionThresholdDenominator;

        if (proposal.votesFor < requiredVotesFor) {
             revert ECProposalNotExecutable(); // Majority not met
        }

        // --- Execute the proposal ---
        bool success = false;
        if (proposal.paramType == 1) { // BaseInteractionCost
             baseInteractionCost = proposal.newValue;
             success = true;
        } else if (proposal.paramType == 2) { // PatternMultiplier
             patternApplicationMultiplier = proposal.newValue;
             success = true;
        } else if (proposal.paramType == 3) { // VibrancyDecayRate
             vibrancyDecayRatePerSecond = proposal.newValue;
             success = true;
        }
        // Add more param types here as needed

        require(success, "EC: Proposal parameter type not implemented"); // Should not happen if paramType is valid

        proposal.executed = true;
        emit ProposalExecuted(proposalId);
    }

    /**
     * @notice Gets the current state and details of a proposal.
     * @param proposalId The ID of the proposal.
     * @return description The proposal description.
     * @return proposer The address that created the proposal.
     * @return paramType The type of parameter being changed.
     * @return newValue The proposed new value.
     * @return createTimestamp The timestamp when the proposal was created.
     * @return endTimestamp The timestamp when voting ends.
     * @return votesFor The total voting power for the proposal.
     * @return votesAgainst The total voting power against the proposal.
     * @return executed Whether the proposal has been executed.
     * @return totalRequiredVotePower The total staked area at proposal creation (for majority calculation).
     */
    function getProposalState(uint256 proposalId) external view returns (
        string memory description,
        address proposer,
        uint8 paramType,
        uint256 newValue,
        uint256 createTimestamp,
        uint256 endTimestamp,
        uint256 votesFor,
        uint256 votesAgainst,
        bool executed,
        uint256 totalRequiredVotePower
    ) {
        Proposal storage proposal = proposals[proposalId];
        if (proposal.proposalId == 0) revert ECProposalDoesNotExist();

        return (
            proposal.description,
            proposal.proposer,
            proposal.paramType,
            proposal.newValue,
            proposal.createTimestamp,
            proposal.endTimestamp,
            proposal.votesFor,
            proposal.votesAgainst,
            proposal.executed,
            proposal.requiredVotePowerForExecution
        );
    }

    // --- Canvas State View Functions (Additional) ---

    /**
     * @notice Gets the raw uint16 state of a specific cell.
     * @param x The X coordinate of the cell.
     * @param y The Y coordinate of the cell.
     * @return The raw uint16 cell state (color << 8 | patternId).
     */
    function getCanvasCellRawState(uint256 x, uint256 y) external view returns (uint16) {
         if (!_isCellInBounds(x, y)) {
            revert ECCanvasOutOfBounds();
        }
        return canvasGrid[x][y];
    }

    // --- Utility/Emergency ---

    /**
     * @notice Allows the owner to withdraw any stuck ERC20 tokens sent to the contract.
     * Does not allow withdrawing native token (ETH) or the contract's own Essence token.
     * @param token The address of the ERC20 token contract.
     * @param amount The amount to withdraw.
     */
    function emergencyWithdraw(address token, uint256 amount) external onlyOwner {
        require(token != address(0) && token != address(this), "EC: Cannot withdraw native token or contract's own token");

        // Basic ERC20 transfer pattern
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb00000000000000000000000000000000000000000000000000000000, owner, amount));
        require(success, "EC: ERC20 transfer failed");

        // Optional: Add checks for return data if the token contract returns boolean
        if (data.length == 32) {
            require(abi.decode(data, (bool)), "EC: ERC20 transfer returned false");
        }
    }

    /**
     * @notice Allows the owner to withdraw collected Essence fees from the contract balance.
     * @param recipient The address to send the Essence to.
     */
    function withdrawCollectedEssence(address recipient) external onlyOwner {
        uint256 balance = _essenceBalances[address(this)];
        _transferEssence(address(this), recipient, balance);
    }

    // Helper function (requires OpenZeppelin's SafeMath or Solidity 0.8+ check)
    // Solidity 0.8+ has built-in overflow/underflow checks for arithmetic operations
    // using SafeMath for clarity/habit or older Solidity versions might be necessary
    // Using standard operators is fine for 0.8+
    library Math {
        function min(uint256 a, uint256 b) internal pure returns (uint256) {
            return a < b ? a : b;
        }
    }
}
```

**Explanation of Advanced/Creative/Trendy Concepts:**

1.  **Custom NFT-like Plots:** Instead of a standard ERC721 implementation, `PlotInfo` struct and mappings (`_plotData`, `_plotExists`, owner lookup within `PlotInfo`) are used. This allows for non-standard NFT properties like `x`, `y`, `width`, `height`, and `stakedTimestamp` directly within the asset's data structure managed by the contract. The `mergePlots` function provides a unique mechanic not found in standard ERC721s.
2.  **Custom Fungible Token (`Essence`):** Basic balance tracking and transfer logic (`_essenceBalances`, `_totalSupplyEssence`, `_transferEssence`) are implemented internally rather than inheriting ERC20. This gives full control over token mechanics, like tying minting (`_mintEssence`) to specific actions (`unstakePlot`) and burning (`_burnEssence` - though not used explicitly in the public functions here, the pattern is there) to other potential future features. Using `transferFromEssence` allows for spending by approved addresses, useful for interactions if we restructure costs.
3.  **Shared State Grid (`canvasGrid`):** A central `mapping` represents the dynamic state of the canvas. User actions directly modify this shared state, making it a collaborative/competitive environment. Packing color and pattern ID into a single `uint16` per cell is a gas-saving technique.
4.  **Dynamic Parameter (`canvasVibrancy`):** The `canvasVibrancy` state variable adds a global dynamic property. It's affected by positive user interactions (`_updateVibrancy`) and decays over time (`decayCanvasVibrancy`). This adds a game-like element, potentially influencing future interaction costs, rewards, or generative output.
5.  **Generative Potential:** While the contract doesn't *render* art, the `canvasGrid` state (color and pattern ID per cell) provides a complex, evolving on-chain data structure. This data can be queried (`getCanvasCellState`, `getCanvasCellRawState`) by off-chain applications to deterministically generate visual art, music, or other outputs based on the contract's state at any given block height. This separates the expensive computation/rendering from the verifiable state storage.
6.  **Simple Governance:** The `Proposal` struct and associated functions (`createParameterChangeProposal`, `voteOnProposal`, `executeProposal`, `getProposalState`) implement a basic on-chain governance system. Voting power is tied directly to ownership of staked plot area, linking asset ownership to protocol control in a custom way. This allows stakeholders to collectively modify contract parameters.
7.  **Packing State:** Using `uint16` to store both color (8 bits) and pattern ID (8 bits) for each cell (`canvasGrid`) is a common gas optimization technique for dense grid data.
8.  **Staking Mechanic:** Users can stake their Plots (`stakePlotForEssence`) to earn `Essence` passively (`unstakePlot`), adding a yield-farming-like element tied to the non-fungible assets.

This contract goes beyond basic token transfers and storage by implementing intertwined custom tokenomics (Essence), unique dynamic digital assets (Plots with properties and merge capabilities), a shared interactive state (Canvas Grid), a global dynamic parameter (Vibrancy), and a simple governance mechanism linked to asset ownership, all designed to potentially drive off-chain generative experiences.

**Note on Gas and Scalability:** The `_isPlotAreaAvailable`, `createParameterChangeProposal`, and `voteOnProposal` functions contain loops that iterate up to `nextPlotTokenId`. This is highly inefficient and will consume excessive gas as the number of plots increases. In a production system, spatial indexing (like quadtrees) and managing plot lists per user would ideally be done off-chain, relying on events for updates. The current implementation is illustrative of the *concept* on-chain but demonstrates a common scalability challenge. Similarly, applying patterns loops through cells, which is fine for small plots but could be costly for large ones.

The governance voting power calculation within `createParameterChangeProposal` and `voteOnProposal` is also highly gas-intensive due to iterating through *all* minted plots to find staked ones owned by the caller. A more scalable approach would require users to explicitly register/update their staked area balance or use a system where voting power is calculated off-chain and submitted with a proof.