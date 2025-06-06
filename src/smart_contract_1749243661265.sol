Okay, here is a Solidity smart contract implementing a "Meta Pixel Canvas" concept. It's a fixed-size grid where users can own, color, and interact with individual pixels, featuring dynamic pricing, pixel decay, color palette governance, delegation, and reporting mechanisms.

This concept combines elements of NFTs (pixel ownership), collaborative art, economics (dynamic pricing), and decentralized governance (color proposals). It aims to be more complex and distinct than standard ERC20/ERC721 templates or simple game mechanics.

---

**Outline & Function Summary:**

**Concept:** A fixed-size digital canvas represented on-chain, where users can buy ownership of individual pixels, set their colors, and interact with the system through dynamic pricing, pixel decay, and community color palette proposals.

**State Variables:**
*   `width`, `height`: Dimensions of the canvas.
*   `pixels`: Mapping storing `PixelData` for each pixel (owner, color, timestamp, report count).
*   `pixelPriceBase`: Base cost to buy/claim a pixel.
*   `decayPeriod`: Time after which a pixel starts decaying.
*   `decayClaimFee`: Fee to claim a decayed pixel.
*   `allowedColors`: List of colors users can use.
*   `colorProposalCounter`: Counter for color proposals.
*   `colorProposals`: Mapping storing details of color proposals.
*   `colorProposalVotes`: Mapping tracking votes for each proposal.
*   `colorProposalVotingPeriod`: Duration for color proposal voting.
*   `canvasFees`: Accumulated ETH fees.
*   `owner`: Contract administrator.
*   `paused`: State indicating if drawing is paused.

**Structs:**
*   `PixelData`: Stores info for a single pixel (owner, color, last update time, report count).
*   `ColorProposal`: Stores details for a color proposal (proposer, color, creation time, votes for, votes against, state).

**Enums:**
*   `ProposalState`: States for color proposals (Pending, Passed, Failed, Executed, Cancelled).

**Events:**
*   `PixelSet`: Emitted when a pixel's color or owner changes.
*   `OwnershipTransferred`: Emitted when admin ownership changes.
*   `FeesWithdrawn`: Emitted when fees are withdrawn.
*   `ColorAdded`: Emitted when a color is added to the palette.
*   `ColorRemoved`: Emitted when a color is removed from the palette.
*   `PixelOwnershipTransferred`: Emitted when a pixel's ownership is transferred.
*   `PixelDelegationSet`: Emitted when drawing delegation is set.
*   `PixelReported`: Emitted when a pixel is reported.
*   `PriceBaseSet`: Emitted when the base pixel price is updated.
*   `DecayConfigSet`: Emitted when decay parameters are updated.
*   `CanvasPaused`: Emitted when the canvas is paused/unpaused.
*   `ColorProposalCreated`: Emitted when a color proposal is initiated.
*   `ColorVoted`: Emitted when a vote is cast on a proposal.
*   `ColorProposalTallied`: Emitted after a proposal's voting period ends.
*   `ColorProposalExecuted`: Emitted when a successful proposal is actioned.

**Functions (Total: 26+):**

1.  `constructor`: Initializes canvas dimensions, admin, and initial parameters.
2.  `buyAndSetPixel`: Allows a user to buy an unowned or decayed pixel and set its color. Requires ETH payment.
3.  `changeOwnedPixelColor`: Allows a pixel owner (or delegate) to change the color of their owned pixel. Might have a small fee or be free.
4.  `transferPixelOwnership`: Allows a pixel owner to transfer ownership of a specific pixel to another address.
5.  `delegatePixelDrawing`: Allows a pixel owner to authorize another address to change the color of their pixel(s).
6.  `revokePixelDrawingDelegation`: Allows a pixel owner to remove drawing authorization from a delegate.
7.  `getPixelInfo`: (View) Returns the owner, color, last updated time, and report count for a given pixel coordinate.
8.  `getPixelPrice`: (View) Calculates and returns the current price to buy/claim a pixel, considering decay status.
9.  `getCanvasStateBatch`: (View) Returns the state (owner, color) of a batch of pixels within a specified range. Useful for off-chain rendering.
10. `addAllowedColor`: (Admin) Adds a new color to the list of permissible colors.
11. `removeAllowedColor`: (Admin) Removes an existing color from the list.
12. `getAllowedColors`: (View) Returns the array of all currently allowed colors.
13. `setPixelPriceBase`: (Admin) Sets the base price for buying/claiming pixels.
14. `setDecayConfig`: (Admin) Configures the decay period and claim fee.
15. `checkPixelDecayStatus`: (View) Checks if a pixel is currently in a decayed state and claimable.
16. `claimDecayedPixel`: Allows a user to claim ownership of a pixel that has passed its decay period. Requires payment of the decay claim fee.
17. `proposeNewColor`: Allows any user to propose adding a new color to the palette. Requires a bond or fee. Starts a voting period.
18. `voteOnColorProposal`: Allows users to vote 'for' or 'against' an active color proposal.
19. `tallyColorProposalVotes`: Can be called by anyone after the voting period ends to tally votes and update the proposal state.
20. `executeColorProposal`: Can be called by anyone if a color proposal has passed, adding the new color to the palette.
21. `cancelColorProposal`: (Admin) Allows admin to cancel an active or pending color proposal.
22. `reportPixelContent`: Allows users to report a pixel for inappropriate content, incrementing its report count.
23. `getPixelReportCount`: (View) Returns the current report count for a specific pixel.
24. `withdrawFees`: (Admin) Allows the contract admin to withdraw accumulated ETH fees.
25. `pause`: (Admin) Pauses drawing actions on the canvas.
26. `unpause`: (Admin) Unpauses drawing actions.
27. `transferOwnership`: (Admin) Transfers the contract administrator role.
28. `isAllowedColor`: (Internal View) Checks if a color is in the allowed palette.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title MetaPixelCanvas
/// @author Your Name/Team (Example Implementation)
/// @dev A smart contract for a collaborative digital canvas where users can buy, own, and color pixels.
/// Features include dynamic pricing, pixel decay, color palette governance, delegation, and reporting.

contract MetaPixelCanvas {

    // --- State Variables ---

    uint256 public immutable width;
    uint256 public immutable height;
    uint256 public constant MAX_COORDINATE_VALUE = type(uint128).max; // Limit dimensions to prevent overflow issues with pixel index

    struct PixelData {
        address owner;
        bytes3 color; // RGB color (e.g., 0xFF0000 for red)
        uint64 lastUpdateTime; // Timestamp of last modification
        uint32 reportCount; // Counter for content reports
        mapping(address => bool) delegates; // Addresses allowed to draw on this pixel
    }

    // Use uint128 for the index to save space, calculated as y * width + x
    mapping(uint128 => PixelData) public pixels;

    uint256 public pixelPriceBase; // Base cost in Wei to buy or claim a pixel
    uint256 public decayPeriod; // Time in seconds after which a pixel starts decaying
    uint256 public decayClaimFee; // Fee in Wei to claim a decayed pixel (could be different from base price)

    bytes3[] public allowedColors; // List of colors users can set

    uint256 public colorProposalCounter;
    struct ColorProposal {
        address proposer;
        bytes3 newColor;
        uint64 creationTime;
        uint256 votesFor;
        uint256 votesAgainst;
        ProposalState state;
    }
    mapping(uint256 => ColorProposal) public colorProposals;
    mapping(uint256 => mapping(address => bool)) public colorProposalVotes; // proposalId => voter => hasVoted
    uint256 public colorProposalVotingPeriod = 7 days; // Default voting period

    uint256 public canvasFees; // Accumulated ETH fees

    address payable public owner; // Admin address
    bool public paused; // Pause flag

    enum ProposalState {
        Pending,    // Voting is active
        Passed,     // Votes met threshold, ready to execute
        Failed,     // Votes did not meet threshold
        Executed,   // Color added to palette
        Cancelled   // Admin cancelled proposal
    }

    // --- Events ---

    event PixelSet(uint256 indexed x, uint256 indexed y, address indexed owner, bytes3 color, uint64 timestamp);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event FeesWithdrawn(address indexed to, uint256 amount);
    event ColorAdded(bytes3 color);
    event ColorRemoved(bytes3 color);
    event PixelOwnershipTransferred(uint256 indexed x, uint256 indexed y, address indexed from, address indexed to);
    event PixelDelegationSet(uint256 indexed x, uint256 indexed y, address indexed delegate, bool allowed);
    event PixelReported(uint256 indexed x, uint256 indexed y, address indexed reporter);
    event PriceBaseSet(uint256 newPriceBase);
    event DecayConfigSet(uint256 newDecayPeriod, uint256 newDecayClaimFee);
    event CanvasPaused(bool _paused);
    event ColorProposalCreated(uint256 indexed proposalId, address indexed proposer, bytes3 color, uint64 creationTime, uint64 votingEndTime);
    event ColorVoted(uint256 indexed proposalId, address indexed voter, bool indexed voteFor); // true for 'for', false for 'against'
    event ColorProposalTallied(uint256 indexed proposalId, ProposalState newState, uint256 votesFor, uint256 votesAgainst);
    event ColorProposalExecuted(uint256 indexed proposalId, bytes3 color);
    event ColorProposalCancelled(uint256 indexed proposalId, address indexed canceller);

    // --- Modifiers ---

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can call this function");
        _;
    }

    modifier whenNotPaused() {
        require(!paused, "Canvas is paused");
        _;
    }

    modifier pixelExists(uint256 x, uint256 y) {
        require(x < width && y < height, "Pixel coordinates out of bounds");
        _;
    }

    // --- Constructor ---

    constructor(uint256 _width, uint256 _height, uint256 _pixelPriceBase, uint256 _decayPeriod, uint256 _decayClaimFee, bytes3[] memory _initialColors) {
        require(_width > 0 && _height > 0 && _width <= MAX_COORDINATE_VALUE && _height <= MAX_COORDINATE_VALUE, "Invalid dimensions");
        require(_initialColors.length > 0, "Initial colors cannot be empty");

        width = _width;
        height = _height;
        pixelPriceBase = _pixelPriceBase;
        decayPeriod = _decayPeriod;
        decayClaimFee = _decayClaimFee;
        allowedColors = _initialColors; // Simple initial population

        owner = payable(msg.sender);
        paused = false;

        // Initialize default pixel data (owner 0x0, color 0x0, etc.) is handled by default mapping behavior
    }

    // --- Core Pixel Interaction Functions ---

    /// @dev Calculates the unique index for a pixel coordinate.
    /// @param x The x-coordinate of the pixel.
    /// @param y The y-coordinate of the pixel.
    /// @return The unique index of the pixel.
    function getPixelIndex(uint256 x, uint256 y) internal view returns (uint128) {
        require(x < width && y < height, "Index out of bounds");
        return uint128(y * width + x);
    }

    /// @dev Converts a pixel index back to coordinates.
    /// @param index The unique index of the pixel.
    /// @return x The x-coordinate.
    /// @return y The y-coordinate.
    function getPixelCoords(uint128 index) internal view returns (uint256 x, uint256 y) {
         require(index < width * height, "Index out of bounds");
         x = index % width;
         y = index / width;
    }


    /// @notice Allows a user to buy an unowned or decayed pixel and set its color.
    /// @param x The x-coordinate of the pixel.
    /// @param y The y-coordinate of the pixel.
    /// @param color The color to set (must be in allowedColors).
    function buyAndSetPixel(uint256 x, uint256 y, bytes3 color)
        external
        payable
        whenNotPaused
        pixelExists(x, y)
    {
        require(isAllowedColor(color), "Color not allowed");

        uint128 pixelIndex = getPixelIndex(x, y);
        PixelData storage pixel = pixels[pixelIndex];

        bool isDecayed = checkPixelDecayStatus(x, y);
        bool isUnowned = pixel.owner == address(0);

        uint256 requiredPrice;
        if (isUnowned) {
            requiredPrice = pixelPriceBase;
        } else if (isDecayed) {
            requiredPrice = decayClaimFee;
        } else {
            revert("Pixel is currently owned and not decayed");
        }

        require(msg.value >= requiredPrice, "Insufficient ETH sent");

        // Refund any excess ETH
        if (msg.value > requiredPrice) {
            payable(msg.sender).transfer(msg.value - requiredPrice);
        }

        // Add requiredPrice to canvas fees
        canvasFees += requiredPrice;

        // Update pixel data
        pixel.owner = msg.sender;
        pixel.color = color;
        pixel.lastUpdateTime = uint64(block.timestamp);
        pixel.reportCount = 0; // Reset report count on buy/claim
        // Clear delegates on new ownership
        delete pixel.delegates;

        emit PixelSet(x, y, msg.sender, color, pixel.lastUpdateTime);
    }

    /// @notice Allows a pixel owner or authorized delegate to change the color of their owned pixel.
    /// @param x The x-coordinate of the pixel.
    /// @param y The y-coordinate of the pixel.
    /// @param color The color to set (must be in allowedColors).
    function changeOwnedPixelColor(uint256 x, uint256 y, bytes3 color)
        external
        whenNotPaused
        pixelExists(x, y)
    {
        uint128 pixelIndex = getPixelIndex(x, y);
        PixelData storage pixel = pixels[pixelIndex];

        require(pixel.owner != address(0), "Pixel is unowned");
        require(msg.sender == pixel.owner || pixel.delegates[msg.sender], "Caller is not owner or authorized delegate");
        require(isAllowedColor(color), "Color not allowed");

        // Optional: Add a small fee here if needed
        // If fee required: payable(msg.sender).transfer(fee); canvasFees += fee;

        pixel.color = color;
        pixel.lastUpdateTime = uint64(block.timestamp);

        emit PixelSet(x, y, pixel.owner, color, pixel.lastUpdateTime);
    }

    /// @notice Allows a pixel owner to transfer ownership of a specific pixel to another address.
    /// @param x The x-coordinate of the pixel.
    /// @param y The y-coordinate of the pixel.
    /// @param to The address to transfer ownership to.
    function transferPixelOwnership(uint256 x, uint256 y, address to)
        external
        whenNotPaused
        pixelExists(x, y)
    {
        uint128 pixelIndex = getPixelIndex(x, y);
        PixelData storage pixel = pixels[pixelIndex];

        require(pixel.owner != address(0), "Pixel is unowned");
        require(msg.sender == pixel.owner, "Caller is not the pixel owner");
        require(to != address(0), "Cannot transfer to zero address");

        address from = pixel.owner;
        pixel.owner = to;
        // Keep color and lastUpdateTime, clear delegates
        delete pixel.delegates;

        emit PixelOwnershipTransferred(x, y, from, to);
    }

    /// @notice Allows a pixel owner to authorize another address to change the color of their pixel.
    /// @param x The x-coordinate of the pixel.
    /// @param y The y-coordinate of the pixel.
    /// @param delegate The address to authorize.
    /// @param allowed True to grant permission, false to revoke.
    function delegatePixelDrawing(uint256 x, uint256 y, address delegate, bool allowed)
        external
        whenNotPaused
        pixelExists(x, y)
    {
        uint128 pixelIndex = getPixelIndex(x, y);
        PixelData storage pixel = pixels[pixelIndex];

        require(pixel.owner != address(0), "Pixel is unowned");
        require(msg.sender == pixel.owner, "Caller is not the pixel owner");
        require(delegate != address(0), "Cannot delegate to zero address");
        require(delegate != msg.sender, "Cannot delegate to self");

        pixel.delegates[delegate] = allowed;

        emit PixelDelegationSet(x, y, delegate, allowed);
    }

    // Note: revokePixelDrawingDelegation can simply be calling delegatePixelDrawing with allowed=false

    // --- View Functions ---

    /// @notice Returns the information of a specific pixel.
    /// @param x The x-coordinate.
    /// @param y The y-coordinate.
    /// @return owner The owner of the pixel.
    /// @return color The color of the pixel.
    /// @return lastUpdateTime The timestamp of the last update.
    /// @return reportCount The current report count.
    function getPixelInfo(uint256 x, uint256 y)
        external
        view
        pixelExists(x, y)
        returns (address owner, bytes3 color, uint64 lastUpdateTime, uint32 reportCount)
    {
        uint128 pixelIndex = getPixelIndex(x, y);
        PixelData storage pixel = pixels[pixelIndex];
        return (pixel.owner, pixel.color, pixel.lastUpdateTime, pixel.reportCount);
    }

    /// @notice Calculates the current price to buy or claim a specific pixel.
    /// @param x The x-coordinate.
    /// @param y The y-coordinate.
    /// @return The price in Wei.
    function getPixelPrice(uint256 x, uint256 y)
        public
        view
        pixelExists(x, y)
        returns (uint256)
    {
        uint128 pixelIndex = getPixelIndex(x, y);
        PixelData storage pixel = pixels[pixelIndex];

        if (pixel.owner == address(0)) {
            return pixelPriceBase; // Unowned pixel cost is base price
        } else {
            // Owned pixel price depends on decay status
            bool isDecayed = checkPixelDecayStatus(x, y);
            if (isDecayed) {
                return decayClaimFee; // Decayed pixel claim fee
            } else {
                return 0; // Owned and not decayed -> cannot be bought, price is effectively infinite for purchase
                // Note: Change color might have a small fee, but that's handled in changeOwnedPixelColor
            }
        }
    }

     /// @notice Checks if a pixel is currently in a decayed state and eligible for claiming.
    /// @param x The x-coordinate.
    /// @param y The y-coordinate.
    /// @return True if the pixel is decayed and claimable, false otherwise.
    function checkPixelDecayStatus(uint256 x, uint256 y)
        public
        view
        pixelExists(x, y)
        returns (bool)
    {
        uint128 pixelIndex = getPixelIndex(x, y);
        PixelData storage pixel = pixels[pixelIndex];

        // A pixel decays if it has an owner, but hasn't been updated for longer than the decay period.
        return pixel.owner != address(0) && decayPeriod > 0 && (block.timestamp - pixel.lastUpdateTime >= decayPeriod);
    }

    /// @notice Allows a user to claim ownership of a pixel that has decayed.
    /// @param x The x-coordinate.
    /// @param y The y-coordinate.
    /// @param color The color to set (must be in allowedColors).
    function claimDecayedPixel(uint256 x, uint256 y, bytes3 color)
        external
        payable
        whenNotPaused
        pixelExists(x, y)
    {
        uint128 pixelIndex = getPixelIndex(x, y);
        PixelData storage pixel = pixels[pixelIndex];

        require(pixel.owner != address(0), "Pixel is unowned, use buyAndSetPixel"); // Must have been owned
        require(checkPixelDecayStatus(x, y), "Pixel is not currently decayed"); // Must be decayed
        require(isAllowedColor(color), "Color not allowed");

        uint256 requiredPrice = decayClaimFee;
        require(msg.value >= requiredPrice, "Insufficient ETH sent to claim decayed pixel");

         // Refund any excess ETH
        if (msg.value > requiredPrice) {
            payable(msg.sender).transfer(msg.value - requiredPrice);
        }

        // Add requiredPrice to canvas fees
        canvasFees += requiredPrice;

        // Update pixel data - same logic as buyAndSetPixel for new ownership
        address oldOwner = pixel.owner; // Store old owner if needed for history/events, though ownership is lost
        pixel.owner = msg.sender;
        pixel.color = color;
        pixel.lastUpdateTime = uint64(block.timestamp);
        pixel.reportCount = 0; // Reset report count on claim
        delete pixel.delegates; // Clear delegates on new ownership

        emit PixelSet(x, y, msg.sender, color, pixel.lastUpdateTime);
        // Could emit PixelOwnershipTransferred(x, y, oldOwner, msg.sender); if tracking transition from decay
    }


    /// @notice Retrieves the state of a batch of pixels.
    /// @param startX The starting x-coordinate (inclusive).
    /// @param startY The starting y-coordinate (inclusive).
    /// @param endX The ending x-coordinate (inclusive).
    /// @param endY The ending y-coordinate (inclusive).
    /// @return A struct array containing data for each pixel in the batch.
    /// @dev This is for fetching portions of the canvas. Ensure the batch size is manageable for transactions/gas limits.
    function getCanvasStateBatch(uint256 startX, uint256 startY, uint256 endX, uint256 endY)
        external
        view
        returns (PixelData[] memory)
    {
        require(startX < width && startY < height, "Start coordinates out of bounds");
        require(endX < width && endY < height, "End coordinates out of bounds");
        require(startX <= endX && startY <= endY, "Invalid batch range");

        uint256 numRows = endY - startY + 1;
        uint256 numCols = endX - startX + 1;
        uint256 totalPixels = numRows * numCols;

        // Safety limit to prevent excessive gas usage on view calls
        require(totalPixels <= 10000, "Batch size too large (max 10000 pixels)"); // Adjust limit as needed

        PixelData[] memory batch = new PixelData[](totalPixels);
        uint256 batchIndex = 0;

        for (uint256 y = startY; y <= endY; y++) {
            for (uint256 x = startX; x <= endX; x++) {
                uint128 pixelIndex = getPixelIndex(x, y);
                PixelData storage pixel = pixels[pixelIndex];
                batch[batchIndex] = pixel; // Copies the struct data
                // Explicitly copy delegates mapping? No, mappings within structs in storage cannot be returned easily this way.
                // If delegate info is needed off-chain, a separate view function for a single pixel's delegates is better.
                batchIndex++;
            }
        }

        return batch;
    }

    /// @notice Gets the drawing delegation status for a specific pixel and delegate.
    /// @param x The x-coordinate.
    /// @param y The y-coordinate.
    /// @param delegate The address to check.
    /// @return True if the delegate is allowed to draw on this pixel, false otherwise.
    function getPixelDelegation(uint256 x, uint256 y, address delegate)
        external
        view
        pixelExists(x, y)
        returns (bool)
    {
        uint128 pixelIndex = getPixelIndex(x, y);
        return pixels[pixelIndex].delegates[delegate];
    }


    // --- Admin Functions ---

    /// @notice Allows the owner to set the base price for buying unowned pixels.
    /// @param newPriceBase The new base price in Wei.
    function setPixelPriceBase(uint256 newPriceBase) external onlyOwner {
        pixelPriceBase = newPriceBase;
        emit PriceBaseSet(newPriceBase);
    }

    /// @notice Allows the owner to set the decay period and claim fee.
    /// @param newDecayPeriod The new decay period in seconds. Set to 0 to disable decay.
    /// @param newDecayClaimFee The new fee in Wei to claim a decayed pixel.
    function setDecayConfig(uint256 newDecayPeriod, uint256 newDecayClaimFee) external onlyOwner {
        decayPeriod = newDecayPeriod;
        decayClaimFee = newDecayClaimFee;
        emit DecayConfigSet(newDecayPeriod, newDecayClaimFee);
    }


    /// @notice Adds a color to the list of allowed colors.
    /// @param color The color to add (RGB bytes3).
    function addAllowedColor(bytes3 color) external onlyOwner {
        require(!isAllowedColor(color), "Color already allowed");
        allowedColors.push(color);
        emit ColorAdded(color);
    }

    /// @notice Removes a color from the list of allowed colors.
    /// @param color The color to remove (RGB bytes3).
    function removeAllowedColor(bytes3 color) external onlyOwner {
        bool found = false;
        for (uint i = 0; i < allowedColors.length; i++) {
            if (allowedColors[i] == color) {
                // Swap with last element and pop
                allowedColors[i] = allowedColors[allowedColors.length - 1];
                allowedColors.pop();
                found = true;
                break;
            }
        }
        require(found, "Color not found in allowed list");
        emit ColorRemoved(color);
    }

    /// @notice Retrieves the list of allowed colors.
    /// @return An array of bytes3 representing the allowed colors.
    function getAllowedColors() external view returns (bytes3[] memory) {
        return allowedColors;
    }

    /// @notice Pauses drawing activity on the canvas.
    function pause() external onlyOwner {
        require(!paused, "Canvas is already paused");
        paused = true;
        emit CanvasPaused(true);
    }

    /// @notice Unpauses drawing activity on the canvas.
    function unpause() external onlyOwner {
        require(paused, "Canvas is not paused");
        paused = false;
        emit CanvasPaused(false);
    }

    /// @notice Allows the owner to withdraw accumulated ETH fees.
    /// @param to The address to send the fees to.
    function withdrawFees(address payable to) external onlyOwner {
        uint256 amount = canvasFees;
        require(amount > 0, "No fees to withdraw");
        canvasFees = 0;
        to.transfer(amount);
        emit FeesWithdrawn(to, amount);
    }

    /// @notice Transfers ownership of the contract to a new address.
    /// @param newOwner The address of the new owner.
    function transferOwnership(address payable newOwner) external onlyOwner {
        require(newOwner != address(0), "New owner cannot be the zero address");
        address oldOwner = owner;
        owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }

    // --- Color Palette Governance Functions ---

    /// @notice Allows any user to propose adding a new color to the allowed palette.
    /// @param color The color to propose.
    /// @dev Requires a bond or fee? (Not implemented in this example, but common practice).
    /// @return The ID of the created proposal.
    function proposeNewColor(bytes3 color) external whenNotPaused returns (uint256 proposalId) {
        require(!isAllowedColor(color), "Color is already allowed");
        // Optional: Require a fee or bond here

        proposalId = ++colorProposalCounter;
        ColorProposal storage proposal = colorProposals[proposalId];
        proposal.proposer = msg.sender;
        proposal.newColor = color;
        proposal.creationTime = uint64(block.timestamp);
        proposal.state = ProposalState.Pending;
        // votesFor and votesAgainst start at 0

        emit ColorProposalCreated(proposalId, msg.sender, color, proposal.creationTime, proposal.creationTime + uint64(colorProposalVotingPeriod));
    }

    /// @notice Allows users to vote on an active color proposal.
    /// @param proposalId The ID of the proposal to vote on.
    /// @param voteFor True to vote for the proposal, false to vote against.
    function voteOnColorProposal(uint256 proposalId, bool voteFor) external {
        ColorProposal storage proposal = colorProposals[proposalId];
        require(proposal.state == ProposalState.Pending, "Proposal is not in pending state");
        require(block.timestamp < proposal.creationTime + colorProposalVotingPeriod, "Voting period has ended");
        require(!colorProposalVotes[proposalId][msg.sender], "Already voted on this proposal");

        colorProposalVotes[proposalId][msg.sender] = true;

        if (voteFor) {
            proposal.votesFor++;
        } else {
            proposal.votesAgainst++;
        }

        emit ColorVoted(proposalId, msg.sender, voteFor);
    }

     /// @notice Can be called by anyone to tally votes for a proposal after the voting period ends.
     /// @param proposalId The ID of the proposal to tally.
     function tallyColorProposalVotes(uint256 proposalId) external {
         ColorProposal storage proposal = colorProposals[proposalId];
         require(proposal.state == ProposalState.Pending, "Proposal is not in pending state");
         require(block.timestamp >= proposal.creationTime + colorProposalVotingPeriod, "Voting period has not ended yet");

         // Define success criteria (simple majority of actual votes cast)
         uint256 totalVotes = proposal.votesFor + proposal.votesAgainst;
         // Add a minimum participation threshold if desired: require(totalVotes > MIN_VOTES, "Not enough votes");

         if (proposal.votesFor > proposal.votesAgainst) {
             proposal.state = ProposalState.Passed;
         } else {
             proposal.state = ProposalState.Failed;
         }

         emit ColorProposalTallied(proposalId, proposal.state, proposal.votesFor, proposal.votesAgainst);
     }

     /// @notice Can be called by anyone to execute a proposal that has passed.
     /// @param proposalId The ID of the proposal to execute.
     function executeColorProposal(uint256 proposalId) external {
         ColorProposal storage proposal = colorProposals[proposalId];
         require(proposal.state == ProposalState.Passed, "Proposal has not passed");
         require(!isAllowedColor(proposal.newColor), "Color is already allowed"); // Double-check

         allowedColors.push(proposal.newColor);
         proposal.state = ProposalState.Executed;

         emit ColorAdded(proposal.newColor);
         emit ColorProposalExecuted(proposalId, proposal.newColor);
     }

     /// @notice Allows the admin to cancel any color proposal.
     /// @param proposalId The ID of the proposal to cancel.
     function cancelColorProposal(uint256 proposalId) external onlyOwner {
        ColorProposal storage proposal = colorProposals[proposalId];
        require(proposal.state == ProposalState.Pending || proposal.state == ProposalState.Passed || proposal.state == ProposalState.Failed, "Proposal is already in a final state (Executed/Cancelled)");

        proposal.state = ProposalState.Cancelled;

        // Optional: Refund bond to proposer if bonded

        emit ColorProposalCancelled(proposalId, msg.sender);
     }

    /// @notice Gets details about a specific color proposal.
    /// @param proposalId The ID of the proposal.
    /// @return proposer The proposer's address.
    /// @return newColor The color being proposed.
    /// @return creationTime The timestamp of creation.
    /// @return votingEndTime The timestamp when voting ends.
    /// @return votesFor The number of 'for' votes.
    /// @return votesAgainst The number of 'against' votes.
    /// @return state The current state of the proposal.
     function getColorProposal(uint256 proposalId)
        external
        view
        returns (address proposer, bytes3 newColor, uint64 creationTime, uint64 votingEndTime, uint256 votesFor, uint256 votesAgainst, ProposalState state)
    {
        ColorProposal storage proposal = colorProposals[proposalId];
        require(proposal.creationTime > 0, "Proposal does not exist"); // Check if proposalId is valid

        return (
            proposal.proposer,
            proposal.newColor,
            proposal.creationTime,
            proposal.creationTime + uint64(colorProposalVotingPeriod),
            proposal.votesFor,
            proposal.votesAgainst,
            proposal.state
        );
    }

    // --- Reporting Functions ---

    /// @notice Allows users to report a pixel for inappropriate content.
    /// @param x The x-coordinate.
    /// @param y The y-coordinate.
    /// @dev This is a simple counter. Off-chain moderation or further on-chain governance is needed to act on reports.
    function reportPixelContent(uint256 x, uint256 y)
        external
        whenNotPaused
        pixelExists(x, y)
    {
        uint128 pixelIndex = getPixelIndex(x, y);
        pixels[pixelIndex].reportCount++;
        emit PixelReported(x, y, msg.sender);
    }

    /// @notice Gets the current report count for a specific pixel.
    /// @param x The x-coordinate.
    /// @param y The y-coordinate.
    /// @return The report count.
    function getPixelReportCount(uint256 x, uint256 y)
        external
        view
        pixelExists(x, y)
        returns (uint32)
    {
        uint128 pixelIndex = getPixelIndex(x, y);
        return pixels[pixelIndex].reportCount;
    }


    // --- Internal Helper Functions ---

    /// @dev Checks if a given color is in the allowed palette.
    /// @param color The color to check.
    /// @return True if the color is allowed, false otherwise.
    function isAllowedColor(bytes3 color) internal view returns (bool) {
        for (uint i = 0; i < allowedColors.length; i++) {
            if (allowedColors[i] == color) {
                return true;
            }
        }
        return false;
    }

    // --- Receive/Fallback ---
    // Allows the contract to receive ETH directly if sent without calling a specific function
    receive() external payable {
        // You could potentially add rules here for direct deposits if needed
        // For this contract, we mainly expect ETH with buyAndSetPixel or claimDecayedPixel
        // Any accidental sends without calling those functions will just add to canvasFees
        canvasFees += msg.value;
    }

    // Note on Gas Limits: Storing and retrieving a large number of pixels or delegates
    // can hit gas limits. Functions like `getCanvasStateBatch` include a safety limit.
    // Iterating through all pixels or all delegates in a public/external function is generally avoided.
    // Events are crucial for off-chain indexing of the full canvas state and ownership lists.
}
```