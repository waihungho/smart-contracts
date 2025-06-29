Okay, here is a Solidity smart contract for a concept I call "CryptoCanvas". It's a shared digital canvas where users can collaboratively paint pixels, but with added dynamics like pixel decay, ownership rights, permissions, and a simple on-chain proposal system for parameter changes.

It incorporates:
1.  **Grid Management:** Storing state for a large number of pixels.
2.  **Time-Based Dynamics:** Pixels "decay" and require refreshing, adding a game-like element.
3.  **Micro-Ownership/Rights:** Users gain the right to refresh/transfer their painted pixels.
4.  **Permissions:** Granting specific addresses permission to paint *your* pixels.
5.  **Batch Operations:** Optimizing actions by allowing users to paint multiple pixels at once.
6.  **Simple On-Chain Governance/Proposals:** A mechanism for users to propose changes to canvas parameters, which the admin can then enact based on community sentiment (represented by 'support' votes).
7.  **Treasury Management:** Handling collected funds.

It avoids being a direct copy of common patterns like standard ERC721/ERC20, simple DAOs, or basic escrow contracts.

---

## Smart Contract: CryptoCanvas

**Concept:** A shared, fixed-size digital canvas where users can pay to color individual pixels. Pixels require refreshing over time to maintain their color and ownership rights. A simple on-chain proposal system allows users to suggest changes to core parameters.

**Core Features:**
*   Users paint pixels by sending the required ETH.
*   Painted pixels grant the painter temporary "refresh rights" and ownership representation.
*   Pixels decay over time; expired pixels can be claimed by anyone.
*   Owners can refresh their pixels (extend freshness) or transfer their rights.
*   Owners can grant permission to other addresses to paint their specific pixel(s).
*   Users can propose changes to canvas parameters (pixel price, decay rate, etc.).
*   Other users can "support" proposals.
*   The contract administrator (owner) can enact proposals that have community support.
*   Batch functions for painting multiple pixels efficiently.
*   Treasury to collect painting fees.

**Function Summary:**

**Core Painting & Pixel Management:**
1.  `constructor()`: Initializes the canvas dimensions, default parameters, and admin.
2.  `paintPixel(uint16 x, uint16 y, bytes3 color)`: Paints a single pixel, checks payment, updates state, sets owner/timestamp.
3.  `batchPaintPixels(uint16[] calldata x, uint16[] calldata y, bytes3[] calldata colors)`: Paints multiple pixels in a single transaction.
4.  `refreshPixel(uint16 x, uint16 y)`: Refreshes the freshness timer for an owned pixel (requires payment).
5.  `claimExpiredPixel(uint16 x, uint16 y)`: Paints an expired pixel, setting new owner/timestamp.
6.  `resetPixel(uint16 x, uint16 y)`: Allows the owner to reset their pixel to the default state.
7.  `transferPixelRight(uint16 x, uint16 y, address newOwner)`: Transfers the ownership/refresh right of a pixel to another address.
8.  `setPixelFreshnessDurationByOwner(uint16 x, uint16 y, uint32 duration)`: Allows an owner to set a custom freshness duration for their pixel (might cost extra).
9.  `grantPaintPermission(uint16 x, uint16 y, address grantee)`: Grants a specific address permission to paint a pixel the caller owns.
10. `revokePaintPermission(uint16 x, uint16 y)`: Revokes paint permission for a pixel.
11. `paintPixelWithPermission(uint16 x, uint16 y, bytes3 color)`: Paints a pixel using a previously granted permission.

**Parameter Proposals & Governance (Simple):**
12. `proposeParameterChange(uint8 paramType, uint256 newValue, string memory description)`: Creates a proposal to change a canvas parameter. Requires a deposit.
13. `supportParameterChange(uint256 proposalId)`: Adds support to an existing proposal.
14. `enactProposedParameterChange(uint256 proposalId)`: (Admin Only) Enacts a proposed parameter change and refunds the proposer's deposit.
15. `cancelProposal(uint256 proposalId)`: (Admin Only) Cancels a proposal.
16. `withdrawProposalDeposit(uint256 proposalId)`: Allows proposer to withdraw deposit if proposal was enacted or cancelled by admin.

**Admin & Treasury:**
17. `setTreasury(address newTreasury)`: (Admin Only) Sets the address for fee collection.
18. `withdrawFunds(uint256 amount)`: (Admin Only) Withdraws funds from the contract treasury.
19. `setProposalDeposit(uint256 amount)`: (Admin Only) Sets the required deposit amount for new proposals.

**View Functions (Querying State):**
20. `getPixel(uint16 x, uint16 y) view returns (Pixel memory)`: Gets complete data for a single pixel.
21. `getMultiplePixels(uint16[] calldata x, uint16[] calldata y) view returns (Pixel[] memory)`: Gets data for multiple pixels.
22. `getCanvasDimensions() view returns (uint16 width, uint16 height)`: Gets the canvas size.
23. `getPixelFreshnessExpiry(uint16 x, uint16 y) view returns (uint40 expiryTimestamp)`: Calculates the timestamp when a pixel expires.
24. `isPixelFresh(uint16 x, uint16 y) view returns (bool)`: Checks if a pixel is currently fresh.
25. `getPaintPermission(uint16 x, uint16 y) view returns (address)`: Gets the address currently permitted to paint the pixel (0x0 if none).
26. `getProposal(uint256 proposalId) view returns (Proposal memory)`: Gets details of a specific proposal.
27. `getProposalCount() view returns (uint256)`: Gets the total number of proposals created.
28. `getProposalDepositAmount() view returns (uint256)`: Gets the current required deposit for proposals.
29. `getPixelPrice() view returns (uint256)`: Gets the current price to paint a pixel.
30. `getDefaultFreshnessDuration() view returns (uint32)`: Gets the default freshness duration for new pixels.
31. `getDefaultColor() view returns (bytes3)`: Gets the default color for empty or expired pixels.
32. `getTreasury() view returns (address)`: Gets the treasury address.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

// --- Smart Contract: CryptoCanvas ---
// Concept: A shared digital canvas where users can collaboratively paint pixels with dynamics like decay, ownership, permissions, and proposals.
// Outline & Function Summary provided above the code block.

contract CryptoCanvas is Ownable, ReentrancyGuard {

    // --- State Variables ---

    uint16 public immutable canvasWidth;
    uint16 public immutable canvasHeight;

    struct Pixel {
        bytes3 color; // Stores R, G, B bytes (e.g., 0xFF0000 for red)
        address owner; // Address that last painted the pixel
        uint40 timestamp; // Timestamp when the pixel was last painted/refreshed
        uint32 freshnessDuration; // How long this pixel remains "fresh" from its timestamp
    }

    // Mapping: pixel index (y * width + x) => Pixel data
    mapping(uint256 => Pixel) private pixels;

    // Mapping: pixel index => address granted paint permission
    mapping(uint256 => address) private pixelPaintPermissions;

    // Parameters
    uint256 public pixelPrice; // Cost to paint a pixel (in wei)
    bytes3 public defaultColor; // Color of expired or unpainted pixels
    uint32 public defaultFreshnessDuration; // Default duration pixels stay fresh (in seconds)

    // Treasury
    address public treasury; // Address where fees are sent

    // Proposal System
    enum ParameterType { PixelPrice, DefaultFreshnessDuration, DefaultColor }

    struct Proposal {
        address proposer;
        ParameterType paramType;
        uint256 newValueUint; // Value if paramType is PixelPrice or DefaultFreshnessDuration
        bytes3 newValueBytes3; // Value if paramType is DefaultColor
        string description; // Human-readable description
        uint256 supportCount; // Number of addresses who supported this proposal
        bool enacted; // True if the proposal has been enacted by the admin
        bool cancelled; // True if the proposal has been cancelled by the admin
        uint256 deposit; // Amount deposited by the proposer
    }

    // Mapping: proposalId => Proposal data
    mapping(uint256 => Proposal) private proposals;
    uint256 private nextProposalId = 1;
    uint256 public proposalDeposit; // Required deposit to create a proposal

    // --- Events ---

    event PixelPainted(uint16 x, uint16 y, bytes3 color, address indexed owner, uint40 timestamp, uint32 freshnessDuration);
    event PixelRefreshed(uint16 x, uint16 y, address indexed owner, uint40 timestamp, uint32 newFreshnessDuration);
    event PixelReset(uint16 x, uint16 y, address indexed owner);
    event PixelRightTransferred(uint16 x, uint16 y, address indexed oldOwner, address indexed newOwner);
    event PaintPermissionGranted(uint16 x, uint16 y, address indexed owner, address indexed grantee);
    event PaintPermissionRevoked(uint16 x, uint16 y, address indexed owner, address indexed grantee);
    event PixelPaintedWithPermission(uint16 x, uint16 y, bytes3 color, address indexed owner, address indexed painter, uint40 timestamp);

    event ParameterChangeProposed(uint256 indexed proposalId, address indexed proposer, uint8 paramType, uint256 newValueUint, bytes3 newValueBytes3);
    event ProposalSupported(uint256 indexed proposalId, address indexed supporter);
    event ParameterChangeEnacted(uint256 indexed proposalId, uint8 paramType, uint256 newValueUint, bytes3 newValueBytes3);
    event ProposalCancelled(uint256 indexed proposalId, address indexed admin);
    event ProposalDepositWithdrawn(uint256 indexed proposalId, address indexed recipient, uint256 amount);

    event FundsWithdrawn(address indexed treasury, uint256 amount);
    event TreasuryUpdated(address indexed oldTreasury, address indexed newTreasury);
    event PixelPriceUpdated(uint256 oldPrice, uint256 newPrice);
    event DefaultFreshnessDurationUpdated(uint32 oldDuration, uint32 newDuration);
    event DefaultColorUpdated(bytes3 oldColor, bytes3 newColor);
    event ProposalDepositUpdated(uint256 oldDeposit, uint256 newDeposit);

    // --- Modifiers ---

    modifier onlyPixelOwner(uint16 x, uint16 y) {
        require(pixels[getIndex(x, y)].owner == msg.sender, "CryptoCanvas: Not pixel owner");
        _;
    }

    modifier onlyPixelPermitted(uint16 x, uint16 y) {
        require(pixelPaintPermissions[getIndex(x, y)] == msg.sender, "CryptoCanvas: Not pixel permitted");
        _;
    }

    // --- Constructor ---

    /// @notice Initializes the CryptoCanvas contract.
    /// @param _width The width of the canvas grid.
    /// @param _height The height of the canvas grid.
    /// @param _pixelPrice The initial price to paint a pixel (in wei).
    /// @param _defaultColor The default color of empty/expired pixels.
    /// @param _defaultFreshnessDuration The default time (in seconds) pixels remain fresh.
    /// @param _treasury The address to send collected fees to.
    /// @param _proposalDeposit The initial required deposit for proposals.
    constructor(
        uint16 _width,
        uint16 _height,
        uint256 _pixelPrice,
        bytes3 _defaultColor,
        uint32 _defaultFreshnessDuration,
        address _treasury,
        uint256 _proposalDeposit
    ) Ownable(msg.sender) {
        require(_width > 0 && _height > 0, "CryptoCanvas: Invalid dimensions");
        require(_treasury != address(0), "CryptoCanvas: Invalid treasury address");

        canvasWidth = _width;
        canvasHeight = _height;
        pixelPrice = _pixelPrice;
        defaultColor = _defaultColor;
        defaultFreshnessDuration = _defaultFreshnessDuration;
        treasury = _treasury;
        proposalDeposit = _proposalDeposit;

        // No need to explicitly initialize all pixels; mapping defaults handle it.
        // Default color/owner/timestamp will be zero/address(0).
    }

    // --- Internal Helpers ---

    /// @dev Calculates the linear index for a given pixel coordinate.
    function getIndex(uint16 x, uint16 y) internal view returns (uint256) {
        require(x < canvasWidth && y < canvasHeight, "CryptoCanvas: Coordinates out of bounds");
        return uint256(y) * canvasWidth + x;
    }

    /// @dev Checks if a pixel at the given index is currently fresh.
    function _isPixelFresh(uint256 index) internal view returns (bool) {
        Pixel storage pixel = pixels[index];
        return pixel.owner != address(0) && block.timestamp <= uint256(pixel.timestamp) + pixel.freshnessDuration;
    }

    /// @dev Internal function to paint or update a pixel.
    function _updatePixel(uint16 x, uint16 y, bytes3 color, address owner, uint32 duration) internal {
        uint256 index = getIndex(x, y);
        Pixel storage pixel = pixels[index];

        pixel.color = color;
        pixel.owner = owner;
        pixel.timestamp = uint40(block.timestamp);
        pixel.freshnessDuration = duration;

        emit PixelPainted(x, y, color, owner, pixel.timestamp, pixel.freshnessDuration);
    }

    /// @dev Internal function to refresh a pixel's timer.
    function _refreshPixel(uint16 x, uint16 y, uint32 newDuration) internal {
        uint256 index = getIndex(x, y);
        Pixel storage pixel = pixels[index];

        pixel.timestamp = uint40(block.timestamp);
        pixel.freshnessDuration = newDuration; // Allows changing duration upon refresh too

        emit PixelRefreshed(x, y, pixel.owner, pixel.timestamp, pixel.freshnessDuration);
    }


    // --- Core Painting & Pixel Management Functions ---

    /// @notice Paints a single pixel on the canvas.
    /// @param x The x-coordinate of the pixel.
    /// @param y The y-coordinate of the pixel.
    /// @param color The desired color (bytes3 RGB).
    function paintPixel(uint16 x, uint16 y, bytes3 color) public payable nonReentrant {
        uint256 index = getIndex(x, y); // Checks bounds
        require(msg.value >= pixelPrice, "CryptoCanvas: Insufficient funds");

        bool wasFresh = _isPixelFresh(index);
        address currentOwner = pixels[index].owner;

        // Allow painting over fresh pixels ONLY if you are the owner
        require(!wasFresh || currentOwner == msg.sender, "CryptoCanvas: Pixel is fresh and owned by someone else");

        _updatePixel(x, y, color, msg.sender, defaultFreshnessDuration);

        // Send excess funds back if any, otherwise send exact price to treasury
        uint256 price = pixelPrice;
        if (msg.value > price) {
            (bool success, ) = payable(msg.sender).call{value: msg.value - price}("");
            require(success, "CryptoCanvas: Failed to refund excess funds");
        }
        (bool success, ) = payable(treasury).call{value: price}("");
        require(success, "CryptoCanvas: Failed to send funds to treasury");
    }

     /// @notice Paints multiple pixels on the canvas in a batch.
     /// @dev This function can be gas-intensive depending on the array sizes. Limit batch size.
     /// @param x The x-coordinates of the pixels.
     /// @param y The y-coordinates of the pixels.
     /// @param colors The desired colors for each pixel.
     function batchPaintPixels(uint16[] calldata x, uint16[] calldata y, bytes3[] calldata colors) public payable nonReentrant {
         require(x.length == y.length && x.length == colors.length, "CryptoCanvas: Array length mismatch");
         // Add a reasonable limit to prevent OOG errors for very large batches
         require(x.length > 0 && x.length <= 50, "CryptoCanvas: Invalid batch size");

         uint256 totalCost = uint256(x.length) * pixelPrice;
         require(msg.value >= totalCost, "CryptoCanvas: Insufficient funds for batch");

         for (uint i = 0; i < x.length; i++) {
             uint16 currentX = x[i];
             uint16 currentY = y[i];
             uint256 index = getIndex(currentX, currentY); // Checks bounds for each coordinate

             bool wasFresh = _isPixelFresh(index);
             address currentOwner = pixels[index].owner;

             // Allow painting over fresh pixels ONLY if you are the owner
             require(!wasFresh || currentOwner == msg.sender, "CryptoCanvas: Batch contains fresh pixel owned by someone else");

             _updatePixel(currentX, currentY, colors[i], msg.sender, defaultFreshnessDuration);

             // Reset paint permission when ownership changes
             delete pixelPaintPermissions[index]; // Default value (address(0))
         }

         // Send excess funds back
         if (msg.value > totalCost) {
             (bool success, ) = payable(msg.sender).call{value: msg.value - totalCost}("");
             require(success, "CryptoCanvas: Failed to refund excess funds");
         }
         // Send total cost to treasury
         (bool success, ) = payable(treasury).call{value: totalCost}("");
         require(success, "CryptoCanvas: Failed to send funds to treasury");
     }


    /// @notice Refreshes the freshness duration of a pixel owned by the caller.
    /// @dev This costs the same as painting the pixel.
    /// @param x The x-coordinate of the pixel.
    /// @param y The y-coordinate of the pixel.
    function refreshPixel(uint16 x, uint16 y) public payable nonReentrant onlyPixelOwner(x, y) {
        uint256 index = getIndex(x, y); // Checks bounds
        require(msg.value >= pixelPrice, "CryptoCanvas: Insufficient funds to refresh");
        // Note: Refreshing by owner *always* works, even if technically expired (it's their right)

        _refreshPixel(x, y, pixels[index].freshnessDuration); // Keep existing duration on refresh by owner

        // Send funds to treasury
        uint256 price = pixelPrice;
         if (msg.value > price) {
            (bool success, ) = payable(msg.sender).call{value: msg.value - price}("");
            require(success, "CryptoCanvas: Failed to refund excess funds");
        }
        (bool success, ) = payable(treasury).call{value: price}("");
        require(success, "CryptoCanvas: Failed to send funds to treasury");
    }

    /// @notice Allows anyone to paint a pixel that is no longer fresh (has expired).
    /// @dev This costs the same as painting the pixel. It effectively "claims" the pixel.
    /// @param x The x-coordinate of the pixel.
    /// @param y The y-coordinate of the pixel.
    function claimExpiredPixel(uint16 x, uint16 y) public payable nonReentrant {
        uint256 index = getIndex(x, y); // Checks bounds
        require(msg.value >= pixelPrice, "CryptoCanvas: Insufficient funds to claim");
        require(!_isPixelFresh(index), "CryptoCanvas: Pixel is still fresh");

        // Get current state before updating
        Pixel memory currentPixel = pixels[index];

        // Paint with the current color, but set the new owner and freshness
        _updatePixel(x, y, currentPixel.color, msg.sender, defaultFreshnessDuration);

         // Send excess funds back
         uint256 price = pixelPrice;
         if (msg.value > price) {
             (bool success, ) = payable(msg.sender).call{value: msg.value - price}("");
             require(success, "CryptoCanvas: Failed to refund excess funds");
         }
         // Send total cost to treasury
         (bool success, ) = payable(treasury).call{value: price}("");
         require(success, "CryptoCanvas: Failed to send funds to treasury");

         // Reset paint permission when ownership changes
         delete pixelPaintPermissions[index]; // Default value (address(0))
    }

    /// @notice Allows the owner of a pixel to reset it to the default color and state.
    /// @param x The x-coordinate of the pixel.
    /// @param y The y-coordinate of the pixel.
    function resetPixel(uint16 x, uint16 y) public onlyPixelOwner(x, y) {
         uint256 index = getIndex(x, y); // Checks bounds
         address owner = pixels[index].owner;

         // Reset pixel state
         delete pixels[index]; // This sets color to 0x000000, owner to address(0), timestamp/duration to 0

         // Set default color explicitly after delete
         pixels[index].color = defaultColor;

         emit PixelReset(x, y, owner);

         // Reset paint permission
         delete pixelPaintPermissions[index];
    }

    /// @notice Transfers the refresh right/ownership representation of a pixel to another address.
    /// @param x The x-coordinate of the pixel.
    /// @param y The y-coordinate of the pixel.
    /// @param newOwner The address to transfer the right to.
    function transferPixelRight(uint16 x, uint16 y, address newOwner) public onlyPixelOwner(x, y) {
        uint256 index = getIndex(x, y); // Checks bounds
        require(newOwner != address(0), "CryptoCanvas: Cannot transfer to zero address");
        require(newOwner != msg.sender, "CryptoCanvas: Cannot transfer to self");

        address oldOwner = pixels[index].owner;
        pixels[index].owner = newOwner;

        emit PixelRightTransferred(x, y, oldOwner, newOwner);

        // Transferring ownership right should also reset paint permissions
        delete pixelPaintPermissions[index];
    }

    /// @notice Allows the owner of a pixel to set a custom freshness duration.
    /// @dev This might require an additional payment based on the contract's logic (not implemented here for simplicity, but could be added).
    /// @param x The x-coordinate of the pixel.
    /// @param y The y-coordinate of the pixel.
    /// @param duration The new custom freshness duration in seconds.
    function setPixelFreshnessDurationByOwner(uint16 x, uint16 y, uint32 duration) public onlyPixelOwner(x, y) {
        uint256 index = getIndex(x, y); // Checks bounds
        require(duration > 0, "CryptoCanvas: Duration must be positive");
        // Add payment check here if custom duration costs extra

        pixels[index].freshnessDuration = duration;
        // Note: This does *not* refresh the timer, just changes the *duration* for future refreshes/paints.
        // Call refreshPixel separately to reset the timer.
        emit PixelRefreshed(x, y, pixels[index].owner, pixels[index].timestamp, duration); // Emitting this as it represents a parameter change
    }

    /// @notice Grants paint permission for a specific pixel to another address.
    /// @param x The x-coordinate of the pixel.
    /// @param y The y-coordinate of the pixel.
    /// @param grantee The address to grant permission to. Set to address(0) to revoke.
    function grantPaintPermission(uint16 x, uint16 y, address grantee) public onlyPixelOwner(x, y) {
        uint256 index = getIndex(x, y); // Checks bounds
        pixelPaintPermissions[index] = grantee;
        emit PaintPermissionGranted(x, y, msg.sender, grantee);
    }

    /// @notice Revokes paint permission for a specific pixel.
    /// @param x The x-coordinate of the pixel.
    /// @param y The y-coordinate of the pixel.
    function revokePaintPermission(uint16 x, uint16 y) public onlyPixelOwner(x, y) {
        uint256 index = getIndex(x, y); // Checks bounds
        // Check if there was a grantee to revoke from (optional)
        // require(pixelPaintPermissions[index] != address(0), "CryptoCanvas: No permission granted");
        delete pixelPaintPermissions[index];
        emit PaintPermissionRevoked(x, y, msg.sender, address(0));
    }

    /// @notice Allows an address with paint permission to paint a specific pixel.
    /// @dev This costs the same as painting the pixel normally.
    /// @param x The x-coordinate of the pixel.
    /// @param y The y-coordinate of the pixel.
    /// @param color The desired color (bytes3 RGB).
    function paintPixelWithPermission(uint16 x, uint16 y, bytes3 color) public payable nonReentrant onlyPixelPermitted(x, y) {
         uint256 index = getIndex(x, y); // Checks bounds
         require(msg.value >= pixelPrice, "CryptoCanvas: Insufficient funds");

         // The pixel's owner should remain the same when painted by a permitted address
         address owner = pixels[index].owner;
         require(owner != address(0), "CryptoCanvas: Pixel has no owner"); // Must be an owned pixel to have a permission

         _updatePixel(x, y, color, owner, pixels[index].freshnessDuration); // Keep original owner & duration

         // Send excess funds back if any, otherwise send exact price to treasury
         uint256 price = pixelPrice;
         if (msg.value > price) {
            (bool success, ) = payable(msg.sender).call{value: msg.value - price}("");
            require(success, "CryptoCanvas: Failed to refund excess funds");
         }
         (bool success, ) = payable(treasury).call{value: price}("");
         require(success, "CryptoCanvas: Failed to send funds to treasury");

         // Permission remains after painting
    }

    // --- Parameter Proposals & Governance (Simple) ---

    /// @notice Allows a user to propose a change to a canvas parameter.
    /// @param paramType The type of parameter to change (enum ParameterType).
    /// @param newValueUint The new value (used for PixelPrice or DefaultFreshnessDuration).
    /// @param newValueBytes3 The new value (used for DefaultColor).
    /// @param description A human-readable description of the proposal.
    function proposeParameterChange(uint8 paramType, uint256 newValueUint, bytes3 newValueBytes3, string memory description) public payable nonReentrant {
        require(msg.value >= proposalDeposit, "CryptoCanvas: Insufficient deposit");
        require(bytes(description).length > 0, "CryptoCanvas: Description cannot be empty");

        ParameterType pType = ParameterType(paramType);
        // Basic validation for specific types
        if (pType == ParameterType.PixelPrice) {
             require(newValueUint > 0, "CryptoCanvas: Price must be positive");
        } else if (pType == ParameterType.DefaultFreshnessDuration) {
             require(newValueUint > 0, "CryptoCanvas: Duration must be positive");
        }
        // Note: Add more sophisticated validation if needed (e.g., max price, max duration, valid color format)

        uint256 proposalId = nextProposalId++;
        proposals[proposalId] = Proposal({
            proposer: msg.sender,
            paramType: pType,
            newValueUint: newValueUint,
            newValueBytes3: newValueBytes3,
            description: description,
            supportCount: 0,
            enacted: false,
            cancelled: false,
            deposit: proposalDeposit // Record the deposit amount at the time of proposal
        });

        // Send excess funds back
         if (msg.value > proposalDeposit) {
            (bool success, ) = payable(msg.sender).call{value: msg.value - proposalDeposit}("");
            require(success, "CryptoCanvas: Failed to refund excess deposit funds");
         }

        emit ParameterChangeProposed(proposalId, msg.sender, paramType, newValueUint, newValueBytes3);
    }

    /// @notice Allows a user to add their support to an existing proposal.
    /// @param proposalId The ID of the proposal to support.
    function supportParameterChange(uint256 proposalId) public {
        Proposal storage proposal = proposals[proposalId];
        require(proposal.proposer != address(0), "CryptoCanvas: Proposal does not exist");
        require(!proposal.enacted && !proposal.cancelled, "CryptoCanvas: Proposal is no longer active");

        // Prevent supporting the same proposal multiple times (requires more state storage, omitted for simplicity,
        // but could use a mapping mapping(uint256 => mapping(address => bool)) public hasSupported; )
        // For this example, supportCount is just a simple counter.

        proposal.supportCount++;

        emit ProposalSupported(proposalId, msg.sender);
    }

    /// @notice (Admin Only) Enacts a proposed parameter change.
    /// @dev Admin decides which proposal to enact, potentially based on supportCount off-chain.
    /// @param proposalId The ID of the proposal to enact.
    function enactProposedParameterChange(uint256 proposalId) public onlyOwner nonReentrant {
        Proposal storage proposal = proposals[proposalId];
        require(proposal.proposer != address(0), "CryptoCanvas: Proposal does not exist");
        require(!proposal.enacted && !proposal.cancelled, "CryptoCanvas: Proposal already enacted or cancelled");
        // Optional: require minimum support count here: require(proposal.supportCount >= minSupportNeeded, "CryptoCanvas: Not enough support");

        proposal.enacted = true;

        if (proposal.paramType == ParameterType.PixelPrice) {
            uint256 oldPrice = pixelPrice;
            pixelPrice = proposal.newValueUint;
            emit PixelPriceUpdated(oldPrice, pixelPrice);
        } else if (proposal.paramType == ParameterType.DefaultFreshnessDuration) {
            uint32 oldDuration = defaultFreshnessDuration;
            defaultFreshnessDuration = uint32(proposal.newValueUint);
            emit DefaultFreshnessDurationUpdated(oldDuration, defaultFreshnessDuration);
        } else if (proposal.paramType == ParameterType.DefaultColor) {
            bytes3 oldColor = defaultColor;
            defaultColor = proposal.newValueBytes3;
            emit DefaultColorUpdated(oldColor, defaultColor);
        }
        // Note: Add new ParameterTypes here if the enum is extended

        // Refund the proposer's deposit
        uint256 depositAmount = proposal.deposit;
        if (depositAmount > 0) {
            (bool success, ) = payable(proposal.proposer).call{value: depositAmount}("");
            // We don't require success here, as the proposal is enacted regardless.
            // The proposer can use withdrawProposalDeposit to claim if this fails.
            if (success) {
                 emit ProposalDepositWithdrawn(proposalId, proposal.proposer, depositAmount);
            }
        }


        emit ParameterChangeEnacted(proposalId, uint8(proposal.paramType), proposal.newValueUint, proposal.newValueBytes3);
    }

    /// @notice (Admin Only) Cancels an active proposal.
    /// @param proposalId The ID of the proposal to cancel.
    function cancelProposal(uint256 proposalId) public onlyOwner {
        Proposal storage proposal = proposals[proposalId];
        require(proposal.proposer != address(0), "CryptoCanvas: Proposal does not exist");
        require(!proposal.enacted && !proposal.cancelled, "CryptoCanvas: Proposal already enacted or cancelled");

        proposal.cancelled = true;

        emit ProposalCancelled(proposalId, msg.sender);
        // Proposer can withdraw deposit via withdrawProposalDeposit
    }

    /// @notice Allows the proposer or admin to withdraw the deposit for an enacted or cancelled proposal.
    /// @param proposalId The ID of the proposal.
    function withdrawProposalDeposit(uint256 proposalId) public nonReentrant {
        Proposal storage proposal = proposals[proposalId];
        require(proposal.proposer != address(0), "CryptoCanvas: Proposal does not exist");
        require(msg.sender == proposal.proposer || msg.sender == owner(), "CryptoCanvas: Not authorized to withdraw deposit");
        require(proposal.enacted || proposal.cancelled, "CryptoCanvas: Proposal not yet enacted or cancelled");
        require(proposal.deposit > 0, "CryptoCanvas: No deposit to withdraw");

        uint256 depositAmount = proposal.deposit;
        proposal.deposit = 0; // Prevent double withdrawal

        (bool success, ) = payable(msg.sender).call{value: depositAmount}("");
        require(success, "CryptoCanvas: Failed to withdraw deposit");

        emit ProposalDepositWithdrawn(proposalId, msg.sender, depositAmount);
    }

    // --- Admin & Treasury Functions ---

    /// @notice (Admin Only) Sets the address where collected fees are sent.
    /// @param newTreasury The new treasury address.
    function setTreasury(address newTreasury) public onlyOwner {
        require(newTreasury != address(0), "CryptoCanvas: Invalid treasury address");
        address oldTreasury = treasury;
        treasury = newTreasury;
        emit TreasuryUpdated(oldTreasury, newTreasury);
    }

    /// @notice (Admin Only) Allows withdrawing funds from the contract's balance to the treasury.
    /// @param amount The amount to withdraw.
    function withdrawFunds(uint256 amount) public onlyOwner nonReentrant {
        require(amount > 0, "CryptoCanvas: Amount must be positive");
        require(address(this).balance >= amount, "CryptoCanvas: Insufficient contract balance");

        (bool success, ) = payable(treasury).call{value: amount}("");
        require(success, "CryptoCanvas: Failed to withdraw funds");

        emit FundsWithdrawn(treasury, amount);
    }

    /// @notice (Admin Only) Sets the required deposit amount for new proposals.
    /// @param amount The new required deposit amount (in wei).
    function setProposalDeposit(uint256 amount) public onlyOwner {
        uint256 oldDeposit = proposalDeposit;
        proposalDeposit = amount;
        emit ProposalDepositUpdated(oldDeposit, proposalDeposit);
    }

    // --- View Functions ---

    /// @notice Gets the total number of pixels on the canvas.
    /// @return The total number of pixels.
    function getTotalPixels() public view returns (uint256) {
        return uint256(canvasWidth) * canvasHeight;
    }

    /// @notice Gets the data for a single pixel.
    /// @param x The x-coordinate.
    /// @param y The y-coordinate.
    /// @return A Pixel struct containing color, owner, timestamp, and freshnessDuration.
    function getPixel(uint16 x, uint16 y) public view returns (Pixel memory) {
        uint256 index = getIndex(x, y); // Checks bounds
        Pixel storage pixel = pixels[index];

        // If owner is address(0), it's effectively an empty/default pixel
        if (pixel.owner == address(0)) {
            return Pixel({
                 color: defaultColor, // Return default color
                 owner: address(0),
                 timestamp: 0,
                 freshnessDuration: 0
            });
        }
        return pixel;
    }

    /// @notice Gets data for multiple pixels in a batch.
    /// @param x The x-coordinates.
    /// @param y The y-coordinates.
    /// @return An array of Pixel structs.
    function getMultiplePixels(uint16[] calldata x, uint16[] calldata y) public view returns (Pixel[] memory) {
        require(x.length == y.length, "CryptoCanvas: Array length mismatch");
        Pixel[] memory result = new Pixel[](x.length);
        for (uint i = 0; i < x.length; i++) {
             uint256 index = getIndex(x[i], y[i]); // Checks bounds for each coordinate
             Pixel storage pixel = pixels[index];

             if (pixel.owner == address(0)) {
                result[i] = Pixel({
                     color: defaultColor,
                     owner: address(0),
                     timestamp: 0,
                     freshnessDuration: 0
                });
             } else {
                 result[i] = pixel;
             }
        }
        return result;
    }

    /// @notice Gets the timestamp when a pixel's current freshness expires.
    /// @param x The x-coordinate.
    /// @param y The y-coordinate.
    /// @return The expiry timestamp, or 0 if the pixel has no owner/timestamp.
    function getPixelFreshnessExpiry(uint16 x, uint16 y) public view returns (uint40 expiryTimestamp) {
         uint256 index = getIndex(x, y); // Checks bounds
         Pixel storage pixel = pixels[index];
         if (pixel.owner == address(0)) {
             return 0;
         }
         return uint40(uint256(pixel.timestamp) + pixel.freshnessDuration);
    }

    /// @notice Checks if a pixel is currently fresh.
    /// @param x The x-coordinate.
    /// @param y The y-coordinate.
    /// @return True if the pixel is fresh, false otherwise.
    function isPixelFresh(uint16 x, uint16 y) public view returns (bool) {
        uint256 index = getIndex(x, y); // Checks bounds
        return _isPixelFresh(index);
    }

     /// @notice Gets the address currently holding paint permission for a pixel.
     /// @param x The x-coordinate.
     /// @param y The y-coordinate.
     /// @return The address with paint permission, or address(0) if none granted.
     function getPaintPermission(uint16 x, uint16 y) public view returns (address) {
         uint256 index = getIndex(x, y); // Checks bounds
         return pixelPaintPermissions[index];
     }

    /// @notice Gets the data for a specific proposal.
    /// @param proposalId The ID of the proposal.
    /// @return A Proposal struct.
    function getProposal(uint256 proposalId) public view returns (Proposal memory) {
        require(proposals[proposalId].proposer != address(0), "CryptoCanvas: Proposal does not exist");
        return proposals[proposalId];
    }

    /// @notice Gets the total number of proposals created.
    /// @return The total count of proposals.
    function getProposalCount() public view returns (uint256) {
        return nextProposalId - 1;
    }

    /// @notice Gets the current required deposit amount for new proposals.
    /// @return The required deposit amount in wei.
    function getProposalDepositAmount() public view returns (uint256) {
        return proposalDeposit;
    }

     /// @notice Gets the current price to paint a pixel.
     /// @return The pixel price in wei.
     function getPixelPrice() public view returns (uint256) {
         return pixelPrice;
     }

     /// @notice Gets the current default freshness duration.
     /// @return The default freshness duration in seconds.
     function getDefaultFreshnessDuration() public view returns (uint32) {
         return defaultFreshnessDuration;
     }

     /// @notice Gets the current default color.
     /// @return The default color (bytes3 RGB).
     function getDefaultColor() public view returns (bytes3) {
         return defaultColor;
     }

     /// @notice Gets the current treasury address.
     /// @return The treasury address.
     function getTreasury() public view returns (address) {
         return treasury;
     }

    // Optional: Receive function to accept ETH sent without calling a specific function (e.g., for treasury top-up)
    receive() external payable {
        // Funds sent directly can be considered a donation to the treasury or
        // left in the contract balance to be withdrawn later by the admin.
        // For this example, we'll just let it increase the contract balance.
    }

    // Optional: Fallback function
    fallback() external payable {
        // Revert if someone sends ETH to a non-existent function
        revert("CryptoCanvas: Invalid function call");
    }
}
```