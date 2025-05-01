Okay, here is a Solidity smart contract called `CryptoCanvas`.

**Concept:** This contract simulates a digital canvas where users can paint individual pixels. The core advanced concept is **dynamic pixel state based on time and interaction**: pixels "decay" over time, fading towards a default color unless actively "protected" by the last painter (or anyone paying the protection fee). This creates a constantly evolving piece of collaborative digital art and an economic model around maintaining pixel vibrancy.

**Why it's potentially interesting/advanced/creative:**

1.  **Dynamic, Time-Based State:** Pixel colors are not static. Their current color is calculated *on-the-fly* based on the time elapsed since they were last painted or protected and a defined decay rate. This is different from typical static data storage in NFTs or tokens.
2.  **Derived State:** The "true" current color is a *derived* property, not directly stored. It's computed from stored base data (`lastColor`, `lastTimestamp`, `protectionEndTime`) and the current block timestamp.
3.  **Spatial Interaction:** The contract operates on a 2D grid, adding a spatial dimension to user interaction.
4.  **Resource Management / Economic Model:** Users spend Ether (or a hypothetical token) to paint and protect pixels, creating an in-contract economy centered around influencing and preserving parts of the canvas.
5.  **Collaborative and Competitive:** Users collaborate to build the canvas but can also paint over each other's work or compete to protect specific areas.
6.  **No Standard Token/NFT:** While pixels could theoretically be NFTs, this contract manages them as dynamic state within a single contract, avoiding the overhead of millions of individual tokens and allowing for decay logic more easily.

**Outline and Function Summary:**

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title CryptoCanvas
 * @dev A smart contract simulating a dynamic, time-decaying digital canvas.
 *      Users can paint pixels, and these pixels fade over time unless protected.
 *      Presents an advanced concept of derived state and time-based data decay.
 */
contract CryptoCanvas {

    // --- Data Structures ---
    /**
     * @dev Struct representing a single pixel on the canvas.
     * @param color The last set color (packed RGB: 0xRRGGBB).
     * @param lastTimestamp The timestamp when the pixel was last painted or protected.
     * @param protectionEndTime The timestamp until which the pixel is protected from decay.
     * @param lastPainter The address that last painted this pixel.
     */
    struct Pixel {
        uint32 color; // Packed RGB: 0xRRGGBB
        uint64 lastTimestamp; // Timestamp of last paint/protection
        uint64 protectionEndTime; // Timestamp until protection is active
        address lastPainter; // Address that last painted this pixel
    }

    // --- State Variables ---
    uint24 public immutable canvasWidth; // Width of the canvas grid
    uint24 public immutable canvasHeight; // Height of the canvas grid
    uint256 public paintCost; // Cost to paint one pixel (in Wei)
    uint256 public protectCostPerSecond; // Cost to protect one pixel per second (in Wei)
    uint64 public defaultDecayRate; // Rate at which color components decay per second
    uint32 public defaultPixelColor; // The color pixels decay towards (packed RGB)
    uint256 public protectionMultiplier; // Multiplier for decay rate when protected (e.g., 0 = no decay, 1 = normal decay, <1 slow, >1 fast) - Note: set to 0 for simple "stop decay" model, use 1 for no effect.
    address public admin; // Address with administrative privileges
    bool public pausedPainting; // Flag to pause all painting actions
    bool public pausedProtection; // Flag to pause all protection actions

    // Mapping to store pixel data: x => y => Pixel data
    mapping(uint24 x => mapping(uint24 y => Pixel)) private pixels;
    uint256 private totalPixelsPaintedCount; // Simple counter for total paint actions


    // --- Events ---
    event PixelPainted(uint24 indexed x, uint24 indexed y, uint32 color, address indexed painter, uint64 timestamp);
    event PixelProtected(uint24 indexed x, uint24 indexed y, uint64 duration, address indexed protector, uint64 timestamp);
    event PixelReclaimed(uint24 indexed x, uint24 indexed y, address indexed reclaimer, uint64 timestamp);
    event FeesWithdrawn(address indexed recipient, uint256 amount);
    event PaintCostUpdated(uint256 newCost);
    event ProtectCostUpdated(uint256 newCostPerSecond);
    event DefaultDecayRateUpdated(uint64 newRate);
    event DefaultPixelColorUpdated(uint32 newColor);
    event ProtectionMultiplierUpdated(uint256 newMultiplier);
    event AdminUpdated(address indexed oldAdmin, address indexed newAdmin);
    event PaintingPaused();
    event PaintingUnpaused();
    event ProtectionPaused();
    event ProtectionUnpaused();


    // --- Modifiers ---
    modifier onlyAdmin() {
        require(msg.sender == admin, "CryptoCanvas: Only admin can call this function");
        _;
    }

    modifier whenNotPausedPainting() {
        require(!pausedPainting, "CryptoCanvas: Painting is currently paused");
        _;
    }

     modifier whenNotPausedProtection() {
        require(!pausedProtection, "CryptoCanvas: Protection is currently paused");
        _;
    }

    modifier isValidCoordinate(uint24 x, uint24 y) {
        require(x < canvasWidth && y < canvasHeight, "CryptoCanvas: Invalid coordinate");
        _;
    }

    modifier isValidColor(uint8 r, uint8 g, uint8 b) {
         // Basic check, RGB components are 0-255 by uint8 type
         _;
    }


    // --- Constructor ---
    /**
     * @dev Constructor to initialize the canvas dimensions and admin.
     * @param _canvasWidth The width of the canvas grid.
     * @param _canvasHeight The height of the canvas grid.
     * @param _paintCost Initial cost to paint one pixel (in Wei).
     * @param _protectCostPerSecond Initial cost to protect one pixel per second (in Wei).
     * @param _defaultDecayRate Initial rate of color decay per second.
     * @param _defaultPixelColor Initial default color (packed RGB).
     * @param _protectionMultiplier Multiplier for decay when protected (0 for no decay).
     */
    constructor(
        uint24 _canvasWidth,
        uint24 _canvasHeight,
        uint256 _paintCost,
        uint256 _protectCostPerSecond,
        uint64 _defaultDecayRate,
        uint32 _defaultPixelColor,
        uint256 _protectionMultiplier
    ) {
        require(_canvasWidth > 0 && _canvasHeight > 0, "CryptoCanvas: Canvas dimensions must be positive");
        canvasWidth = _canvasWidth;
        canvasHeight = _canvasHeight;
        admin = msg.sender;
        paintCost = _paintCost;
        protectCostPerSecond = _protectCostPerSecond;
        defaultDecayRate = _defaultDecayRate;
        defaultPixelColor = _defaultPixelColor;
        protectionMultiplier = _protectionMultiplier;
        pausedPainting = false;
        pausedProtection = false;
        totalPixelsPaintedCount = 0;
    }


    // --- Internal Helper Functions ---

    /**
     * @dev Packs individual RGB color components into a single uint32.
     * @param r Red component (0-255).
     * @param g Green component (0-255).
     * @param b Blue component (0-255).
     * @return The packed color as uint32 (0xRRGGBB).
     */
    function _packColor(uint8 r, uint8 g, uint8 b) internal pure returns (uint32) {
        return (uint32(r) << 16) | (uint32(g) << 8) | uint32(b);
    }

    /**
     * @dev Unpacks a uint32 color into individual RGB components.
     * @param packedColor The packed color (0xRRGGBB).
     * @return r Red component (0-255).
     * @return g Green component (0-255).
     * @return b Blue component (0-255).
     */
    function _unpackColor(uint32 packedColor) internal pure returns (uint8 r, uint8 g, uint8 b) {
        r = uint8((packedColor >> 16) & 0xFF);
        g = uint8((packedColor >> 8) & 0xFF);
        b = uint8(packedColor & 0xFF);
    }

    /**
     * @dev Calculates the current color of a pixel considering decay.
     * @param x The x-coordinate of the pixel.
     * @param y The y-coordinate of the pixel.
     * @return The current color of the pixel as uint32 (0xRRGGBB).
     */
    function _calculateCurrentColor(uint24 x, uint24 y) internal view returns (uint32) {
        Pixel storage pixel = pixels[x][y];
        uint32 initialColor = pixel.color;
        uint32 targetColor = defaultPixelColor;

        // If pixel hasn't been painted, its color is the default
        if (pixel.lastPainter == address(0)) {
            return targetColor;
        }

        // Calculate time elapsed since decay started (after protection ends)
        uint64 decayStartTime = pixel.protectionEndTime > block.timestamp ? pixel.protectionEndTime : block.timestamp;
        uint64 timeElapsedSinceDecay = (decayStartTime > pixel.lastTimestamp) ? (decayStartTime - pixel.lastTimestamp) : 0;


        // If protection is active, adjust decay rate
        uint64 effectiveDecayRate = defaultDecayRate;
        if (pixel.protectionEndTime > block.timestamp) {
             // Simple multiplier effect: decay_rate = default_decay_rate * protection_multiplier
             // Need to handle potential overflow if defaultDecayRate is large
             // For simplicity, let's assume protectionMultiplier 0 = no decay, 1 = full decay, etc.
             // Or, if multiplier is a percentage (e.g., 0-100), effectiveRate = defaultRate * multiplier / 100
             // Let's use multiplier 0-1000 for fixed point 0.0-1.0
             effectiveDecayRate = (defaultDecayRate * protectionMultiplier) / 1000; // assuming multiplier 0-1000, 1000 = 1.0
        } else {
             // If protection expired, time elapsed should be since protection ended
             timeElapsedSinceDecay = block.timestamp - pixel.protectionEndTime;
        }

         // Decay calculation: move towards the default color based on time and rate
        (uint8 r1, uint8 g1, uint8 b1) = _unpackColor(initialColor);
        (uint8 r2, uint8 g2, uint8 b2) = _unpackColor(targetColor);

        // Calculate decay amount for each component
        // Decay amount is capped to not overshoot the target color
        uint256 decayAmount = uint256(timeElapsedSinceDecay) * effectiveDecayRate;

        uint8 currentR = _applyDecay(r1, r2, decayAmount);
        uint8 currentG = _applyDecay(g1, g2, decayAmount);
        uint8 currentB = _applyDecay(b1, b2, decayAmount);

        return _packColor(currentR, currentG, currentB);
    }

    /**
     * @dev Applies decay to a single color component.
     * @param initial Initial component value.
     * @param target Target component value (default color component).
     * @param decayAmount The total decay amount to apply based on time and rate.
     * @return The decayed component value.
     */
    function _applyDecay(uint8 initial, uint8 target, uint256 decayAmount) internal pure returns (uint8) {
        int256 diff = int256(target) - int256(initial);
        if (diff == 0) {
            return initial; // Already at target
        }

        // Decay moves value towards target
        if (diff > 0) { // Need to increase value
            uint256 increaseAmount = decayAmount > uint256(diff) ? uint256(diff) : decayAmount;
            return uint8(int256(initial) + increaseAmount);
        } else { // Need to decrease value
            uint256 decreaseAmount = decayAmount > uint256(-diff) ? uint256(-diff) : decayAmount;
            return uint8(int256(initial) - decreaseAmount);
        }
    }


    // --- Painting Functions ---

    /**
     * @dev Paints a single pixel on the canvas.
     * @param x The x-coordinate of the pixel.
     * @param y The y-coordinate of the pixel.
     * @param r Red component (0-255).
     * @param g Green component (0-255).
     * @param b Blue component (0-255).
     */
    function paintPixel(uint24 x, uint24 y, uint8 r, uint8 g, uint8 b)
        external
        payable
        whenNotPausedPainting()
        isValidCoordinate(x, y)
        isValidColor(r, g, b)
    {
        require(msg.value >= paintCost, "CryptoCanvas: Insufficient payment for paint");

        Pixel storage pixel = pixels[x][y];
        pixel.color = _packColor(r, g, b);
        pixel.lastTimestamp = uint64(block.timestamp);
        // Painting also applies initial protection (resets protection timer)
        // Maybe paint provides some base protection duration automatically?
        // Let's make protection separate to simplify cost calculation.
        // Painting just sets the color and painter. Protection resets the protection timer.
        pixel.protectionEndTime = uint64(block.timestamp); // Protection ends immediately unless protectPixel is called

        // Handle fees: excess payment is returned
        if (msg.value > paintCost) {
            payable(msg.sender).transfer(msg.value - paintCost);
        }

        // If this is the first time this pixel is painted, increment the counter
        if (pixel.lastPainter == address(0)) {
             totalPixelsPaintedCount++;
        }
        pixel.lastPainter = msg.sender;


        emit PixelPainted(x, y, pixel.color, msg.sender, uint64(block.timestamp));
    }

    /**
     * @dev Paints multiple pixels in a single transaction.
     * @param xCoords Array of x-coordinates.
     * @param yCoords Array of y-coordinates.
     * @param rComponents Array of red components.
     * @param gComponents Array of green components.
     * @param bComponents Array of blue components.
     */
    function batchPaintPixels(
        uint24[] calldata xCoords,
        uint24[] calldata yCoords,
        uint8[] calldata rComponents,
        uint8[] calldata gComponents,
        uint8[] calldata bComponents
    )
        external
        payable
        whenNotPausedPainting()
    {
        require(xCoords.length == yCoords.length &&
                xCoords.length == rComponents.length &&
                xCoords.length == gComponents.length &&
                xCoords.length == bComponents.length, "CryptoCanvas: Array length mismatch");
        require(xCoords.length > 0, "CryptoCanvas: Empty arrays");

        uint256 totalCost = paintCost * xCoords.length;
        require(msg.value >= totalCost, "CryptoCanvas: Insufficient payment for batch paint");

        for (uint i = 0; i < xCoords.length; i++) {
            uint24 x = xCoords[i];
            uint24 y = yCoords[i];
            uint8 r = rComponents[i];
            uint8 g = gComponents[i];
            uint8 b = bComponents[i];

            require(x < canvasWidth && y < canvasHeight, "CryptoCanvas: Invalid coordinate in batch");
            // No need to check isValidColor, uint8 handles 0-255

            Pixel storage pixel = pixels[x][y];
            pixel.color = _packColor(r, g, b);
            pixel.lastTimestamp = uint64(block.timestamp);
            pixel.protectionEndTime = uint64(block.timestamp); // Protection ends immediately

             // If this is the first time this pixel is painted, increment the counter
            if (pixel.lastPainter == address(0)) {
                totalPixelsPaintedCount++;
            }
            pixel.lastPainter = msg.sender;

            emit PixelPainted(x, y, pixel.color, msg.sender, uint64(block.timestamp));
        }

        // Handle fees: excess payment is returned
        uint256 excessPayment = msg.value - totalCost;
        if (excessPayment > 0) {
             payable(msg.sender).transfer(excessPayment);
        }
    }


    // --- Protection Functions ---

    /**
     * @dev Extends the protection time for a pixel, preventing or slowing decay.
     * @param x The x-coordinate of the pixel.
     * @param y The y-coordinate of the pixel.
     * @param duration The duration in seconds to extend protection.
     */
    function protectPixel(uint24 x, uint24 y, uint64 duration)
        external
        payable
        whenNotPausedProtection()
        isValidCoordinate(x, y)
    {
        require(duration > 0, "CryptoCanvas: Protection duration must be positive");

        uint256 cost = uint256(duration) * protectCostPerSecond;
        require(msg.value >= cost, "CryptoCanvas: Insufficient payment for protection");

        Pixel storage pixel = pixels[x][y];

        // Calculate the *new* protection end time. Extend from the current time,
        // OR extend from the *existing* protection end time if it's in the future.
        uint64 currentProtectionEnd = pixel.protectionEndTime;
        uint64 effectiveStartTime = currentProtectionEnd > block.timestamp ? currentProtectionEnd : uint64(block.timestamp);

        // Check for overflow before adding duration
        uint64 newProtectionEnd;
        if (effectiveStartTime > type(uint64).max - duration) {
             newProtectionEnd = type(uint64).max; // Cap at max uint64
        } else {
             newProtectionEnd = effectiveStartTime + duration;
        }

        pixel.protectionEndTime = newProtectionEnd;
        pixel.lastTimestamp = uint64(block.timestamp); // Update last interaction timestamp

        // Handle fees: excess payment is returned
        if (msg.value > cost) {
            payable(msg.sender).transfer(msg.value - cost);
        }

        emit PixelProtected(x, y, duration, msg.sender, uint64(block.timestamp));
    }

     /**
     * @dev Protects multiple pixels in a single transaction.
     * @param xCoords Array of x-coordinates.
     * @param yCoords Array of y-coordinates.
     * @param durations Array of durations in seconds to extend protection for each pixel.
     */
    function batchProtectPixels(
        uint24[] calldata xCoords,
        uint24[] calldata yCoords,
        uint64[] calldata durations
    )
        external
        payable
        whenNotPausedProtection()
    {
        require(xCoords.length == yCoords.length && xCoords.length == durations.length, "CryptoCanvas: Array length mismatch");
        require(xCoords.length > 0, "CryptoCanvas: Empty arrays");

        uint256 totalCost = 0;
        for (uint i = 0; i < xCoords.length; i++) {
             require(durations[i] > 0, "CryptoCanvas: Protection duration must be positive in batch");
             uint256 costForPixel = uint256(durations[i]) * protectCostPerSecond;
             totalCost = totalCost + costForPixel; // Add costs, check for overflow later if needed
             // Overflow check: If totalCost exceeds msg.value at any point, it will revert on the final require
             // Or more robustly: require(costForPixel <= type(uint256).max - totalCost, "Total cost overflow"); before adding
        }

        require(msg.value >= totalCost, "CryptoCanvas: Insufficient payment for batch protection");

        for (uint i = 0; i < xCoords.length; i++) {
            uint24 x = xCoords[i];
            uint24 y = yCoords[i];
            uint64 duration = durations[i];

            require(x < canvasWidth && y < canvasHeight, "CryptoCanvas: Invalid coordinate in batch");

            Pixel storage pixel = pixels[x][y];

            uint64 currentProtectionEnd = pixel.protectionEndTime;
            uint64 effectiveStartTime = currentProtectionEnd > block.timestamp ? currentProtectionEnd : uint64(block.timestamp);

            uint64 newProtectionEnd;
             if (effectiveStartTime > type(uint64).max - duration) {
                 newProtectionEnd = type(uint64).max;
             } else {
                 newProtectionEnd = effectiveStartTime + duration;
            }

            pixel.protectionEndTime = newProtectionEnd;
            pixel.lastTimestamp = uint64(block.timestamp);

            emit PixelProtected(x, y, duration, msg.sender, uint64(block.timestamp));
        }

        // Handle fees: excess payment is returned
        uint256 excessPayment = msg.value - totalCost;
        if (excessPayment > 0) {
             payable(msg.sender).transfer(excessPayment);
        }
    }

    /**
     * @dev Allows anyone to 'reclaim' a fully decayed pixel by setting it to the default color.
     *      Intended to help reset abandoned pixels. Costs a small fee.
     * @param x The x-coordinate of the pixel.
     * @param y The y-coordinate of the pixel.
     */
    function reclaimPixel(uint24 x, uint24 y)
        external
        payable
        whenNotPausedPainting() // Reclaiming is like painting with default color
        isValidCoordinate(x, y)
    {
        // Decide on the criteria for "fully decayed".
        // Option 1: Protection expired and color is very close to default. (Complex to check 'very close')
        // Option 2: Protection expired. (Simpler)
        // Let's use Option 2 for simplicity.
        Pixel storage pixel = pixels[x][y];
        require(pixel.protectionEndTime < block.timestamp, "CryptoCanvas: Pixel is still protected");

        // Reclaim cost could be fixed or zero. Let's make it a small fixed cost.
        uint256 reclaimFee = paintCost / 10; // Example: 10% of paint cost
        require(msg.value >= reclaimFee, "CryptoCanvas: Insufficient payment for reclaim");

        // Reset the pixel to default state (except for painter, which is updated)
        pixel.color = defaultPixelColor;
        pixel.lastTimestamp = uint64(block.timestamp);
        pixel.protectionEndTime = uint64(block.timestamp); // No initial protection
        pixel.lastPainter = msg.sender; // Reclaimer becomes the new 'last painter' for state tracking

         // If this is the first time this pixel is painted (ever), increment the counter - but reclaim implies it was painted before.
         // So no increment on reclaim.

        // Handle fees: excess payment is returned
        if (msg.value > reclaimFee) {
            payable(msg.sender).transfer(msg.value - reclaimFee);
        }

        emit PixelReclaimed(x, y, msg.sender, uint64(block.timestamp));
    }


    // --- View/Read Functions ---

    /**
     * @dev Gets the raw stored data for a pixel (before decay calculation).
     * @param x The x-coordinate of the pixel.
     * @param y The y-coordinate of the pixel.
     * @return A tuple containing the pixel's raw color, last timestamp, protection end time, and last painter.
     */
    function getRawPixelData(uint24 x, uint24 y)
        external
        view
        isValidCoordinate(x, y)
        returns (uint32 color, uint64 lastTimestamp, uint64 protectionEndTime, address lastPainter)
    {
        Pixel storage pixel = pixels[x][y];
        return (pixel.color, pixel.lastTimestamp, pixel.protectionEndTime, pixel.lastPainter);
    }

     /**
     * @dev Gets the calculated current color of a pixel, accounting for decay.
     * @param x The x-coordinate of the pixel.
     * @param y The y-coordinate of the pixel.
     * @return The current color of the pixel as uint32 (0xRRGGBB).
     */
    function getCurrentPixelColor(uint24 x, uint24 y)
        external
        view
        isValidCoordinate(x, y)
        returns (uint32)
    {
        return _calculateCurrentColor(x, y);
    }

    /**
     * @dev Gets comprehensive information about a pixel, including its calculated current color.
     * @param x The x-coordinate of the pixel.
     * @param y The y-coordinate of the pixel.
     * @return A tuple containing the pixel's current color, raw stored color, last timestamp, protection end time, and last painter.
     */
    function getPixelInfo(uint24 x, uint24 y)
        external
        view
        isValidCoordinate(x, y)
        returns (uint32 currentColor, uint32 storedColor, uint64 lastTimestamp, uint64 protectionEndTime, address lastPainter)
    {
         Pixel storage pixel = pixels[x][y];
         currentColor = _calculateCurrentColor(x, y);
         storedColor = pixel.color;
         lastTimestamp = pixel.lastTimestamp;
         protectionEndTime = pixel.protectionEndTime;
         lastPainter = pixel.lastPainter;
    }

    /**
     * @dev Gets the current color for a range of pixels. Useful for frontends to fetch chunks of the canvas.
     *      Note: Can be gas-intensive for large ranges.
     * @param startX The starting x-coordinate (inclusive).
     * @param startY The starting y-coordinate (inclusive).
     * @param endX The ending x-coordinate (inclusive).
     * @param endY The ending y-coordinate (inclusive).
     * @return An array of packed uint32 colors for the specified range, row by row.
     */
    function getPixelColorsRange(uint24 startX, uint24 startY, uint24 endX, uint24 endY)
        external
        view
        returns (uint32[] memory)
    {
        require(startX <= endX && startY <= endY, "CryptoCanvas: Invalid range coordinates");
        require(endX < canvasWidth && endY < canvasHeight, "CryptoCanvas: Range out of bounds");

        uint256 numPixels = uint256(endX - startX + 1) * uint256(endY - startY + 1);
        uint32[] memory colors = new uint32[](numPixels);
        uint256 index = 0;
        for (uint24 y = startY; y <= endY; y++) {
            for (uint24 x = startX; x <= endX; x++) {
                colors[index] = _calculateCurrentColor(x, y);
                index++;
            }
        }
        return colors;
    }

     /**
     * @dev Gets the last painter of a specific pixel.
     * @param x The x-coordinate of the pixel.
     * @param y The y-coordinate of the pixel.
     * @return The address of the last painter. Returns address(0) if never painted.
     */
    function getPixelPainter(uint24 x, uint24 y)
         external
         view
         isValidCoordinate(x, y)
         returns (address)
    {
         return pixels[x][y].lastPainter;
    }

    /**
     * @dev Returns the total count of pixels that have been painted at least once.
     *      Note: Reclaiming a pixel does not increment this counter.
     * @return The total number of unique pixels painted.
     */
    function getTotalPixelsPaintedCount() external view returns (uint256) {
        return totalPixelsPaintedCount;
    }


    // --- Admin Functions ---

    /**
     * @dev Sets the cost to paint one pixel. Only callable by admin.
     * @param _paintCost The new cost in Wei.
     */
    function setPaintCost(uint256 _paintCost) external onlyAdmin {
        require(_paintCost > 0, "CryptoCanvas: Paint cost must be positive");
        paintCost = _paintCost;
        emit PaintCostUpdated(_paintCost);
    }

    /**
     * @dev Sets the cost to protect one pixel per second. Only callable by admin.
     * @param _protectCostPerSecond The new cost per second in Wei.
     */
    function setProtectCostPerSecond(uint256 _protectCostPerSecond) external onlyAdmin {
        require(_protectCostPerSecond > 0, "CryptoCanvas: Protect cost per second must be positive");
        protectCostPerSecond = _protectCostPerSecond;
        emit ProtectCostUpdated(_protectCostPerSecond);
    }

    /**
     * @dev Sets the default decay rate per second for color components. Only callable by admin.
     * @param _defaultDecayRate The new decay rate. Higher values mean faster decay.
     */
    function setDefaultDecayRate(uint64 _defaultDecayRate) external onlyAdmin {
        defaultDecayRate = _defaultDecayRate;
        emit DefaultDecayRateUpdated(_defaultDecayRate);
    }

     /**
     * @dev Sets the color pixels decay towards. Only callable by admin.
     * @param r Red component (0-255).
     * @param g Green component (0-255).
     * @param b Blue component (0-255).
     */
    function setDefaultPixelColor(uint8 r, uint8 g, uint8 b) external onlyAdmin isValidColor(r, g, b) {
        defaultPixelColor = _packColor(r, g, b);
        emit DefaultPixelColorUpdated(defaultPixelColor);
    }

    /**
     * @dev Sets the multiplier affecting decay rate when a pixel is protected. Only callable by admin.
     *      Use 0 for no decay when protected, 1000 for normal decay rate.
     * @param _protectionMultiplier The new multiplier (e.g., 0-1000, representing 0-1.0).
     */
    function setProtectionMultiplier(uint256 _protectionMultiplier) external onlyAdmin {
        require(_protectionMultiplier <= 1000, "CryptoCanvas: Protection multiplier cannot exceed 1000 (1.0)");
        protectionMultiplier = _protectionMultiplier;
        emit ProtectionMultiplierUpdated(_protectionMultiplier);
    }

    /**
     * @dev Sets a new admin address. Only callable by current admin.
     * @param _newAdmin The address of the new admin.
     */
    function setAdminAddress(address payable _newAdmin) external onlyAdmin {
        require(_newAdmin != address(0), "CryptoCanvas: New admin address cannot be zero");
        address oldAdmin = admin;
        admin = _newAdmin;
        emit AdminUpdated(oldAdmin, _newAdmin);
    }

    /**
     * @dev Allows the admin to withdraw accumulated Ether fees from the contract.
     * @param recipient The address to send the fees to.
     */
    function withdrawFees(address payable recipient) external onlyAdmin {
        uint256 balance = address(this).balance;
        require(balance > 0, "CryptoCanvas: No fees to withdraw");
        require(recipient != address(0), "CryptoCanvas: Recipient cannot be zero address");

        // It's safer to use call than transfer/send for withdrawal
        (bool success, ) = recipient.call{value: balance}("");
        require(success, "CryptoCanvas: Fee withdrawal failed");

        emit FeesWithdrawn(recipient, balance);
    }

    /**
     * @dev Pauses all painting actions. Only callable by admin.
     */
    function pausePainting() external onlyAdmin {
        require(!pausedPainting, "CryptoCanvas: Painting is already paused");
        pausedPainting = true;
        emit PaintingPaused();
    }

    /**
     * @dev Unpauses painting actions. Only callable by admin.
     */
    function unpausePainting() external onlyAdmin {
        require(pausedPainting, "CryptoCanvas: Painting is not paused");
        pausedPainting = false;
        emit PaintingUnpaused();
    }

    /**
     * @dev Pauses all protection actions. Only callable by admin.
     */
    function pauseProtection() external onlyAdmin {
        require(!pausedProtection, "CryptoCanvas: Protection is already paused");
        pausedProtection = true;
        emit ProtectionPaused();
    }

    /**
     * @dev Unpauses protection actions. Only callable by admin.
     */
    function unpauseProtection() external onlyAdmin {
        require(pausedProtection, "CryptoCanvas: Protection is not paused");
        pausedProtection = false;
        emit ProtectionUnpaused();
    }


    // --- General Getters (Public/External) ---

    function getCanvasDimensions() external view returns (uint24 width, uint24 height) {
        return (canvasWidth, canvasHeight);
    }

    function getPaintCost() external view returns (uint256) {
        return paintCost;
    }

    function getProtectCostPerSecond() external view returns (uint256) {
        return protectCostPerSecond;
    }

    function getDefaultDecayRate() external view returns (uint64) {
        return defaultDecayRate;
    }

     function getDefaultPixelColor() external view returns (uint32) {
        return defaultPixelColor;
    }

    function getProtectionMultiplier() external view returns (uint256) {
        return protectionMultiplier;
    }

    function getAdminAddress() external view returns (address) {
        return admin;
    }

    function getContractBalance() external view returns (uint256) {
        return address(this).balance;
    }

    function isPaintingPaused() external view returns (bool) {
        return pausedPainting;
    }

    function isProtectionPaused() external view returns (bool) {
        return pausedProtection;
    }

    // Fallback function to receive Ether if sent without calling a specific function
    receive() external payable {}
    fallback() external payable {}

}
```

**Function Summary (Detailed List):**

1.  `constructor`: Initializes canvas dimensions, admin address, initial costs, decay settings, and multiplier.
2.  `paintPixel`: Allows a user to set the color of a single pixel at a given coordinate, paying `paintCost`. Updates last painter and timestamp. Emits `PixelPainted`.
3.  `batchPaintPixels`: Allows a user to paint multiple pixels in a single transaction, paying the total cost. Improves gas efficiency for multiple actions. Emits `PixelPainted` for each pixel.
4.  `protectPixel`: Allows a user to extend the protection time for a pixel by a specified duration, paying `duration * protectCostPerSecond`. This prevents or slows decay until the new `protectionEndTime`. Emits `PixelProtected`.
5.  `batchProtectPixels`: Allows a user to protect multiple pixels with specified durations in a single transaction. Improves gas efficiency. Emits `PixelProtected` for each pixel.
6.  `reclaimPixel`: Allows anyone to reset a pixel to the `defaultPixelColor` if its protection has expired. Costs a small fee. Updates the last painter to the reclaimer. Emits `PixelReclaimed`.
7.  `getRawPixelData`: Reads the raw stored data for a single pixel (color, timestamps, painter) without calculating decay.
8.  `getCurrentPixelColor`: Calculates and returns the current color of a pixel *including* the decay effect based on time. Uses the internal `_calculateCurrentColor`.
9.  `getPixelInfo`: Provides a comprehensive view of a pixel, including both the *calculated current color* and the *raw stored data*.
10. `getPixelColorsRange`: Retrieves the *calculated current colors* for all pixels within a specified rectangular range. Useful for frontends.
11. `getPixelPainter`: Returns the address of the last account that painted a specific pixel.
12. `getTotalPixelsPaintedCount`: Returns the count of unique pixel coordinates that have been painted at least once since deployment.
13. `setPaintCost`: Admin function to update the `paintCost`. Emits `PaintCostUpdated`.
14. `setProtectCostPerSecond`: Admin function to update the `protectCostPerSecond`. Emits `ProtectCostUpdated`.
15. `setDefaultDecayRate`: Admin function to update the speed at which pixels decay. Emits `DefaultDecayRateUpdated`.
16. `setDefaultPixelColor`: Admin function to update the color pixels decay towards. Emits `DefaultPixelColorUpdated`.
17. `setProtectionMultiplier`: Admin function to update the decay multiplier when a pixel is under protection. Emits `ProtectionMultiplierUpdated`.
18. `setAdminAddress`: Admin function to transfer admin privileges to a new address. Emits `AdminUpdated`.
19. `withdrawFees`: Admin function to withdraw the collected Ether balance from the contract to a specified recipient. Emits `FeesWithdrawn`.
20. `pausePainting`: Admin function to temporarily halt all `paintPixel` and `batchPaintPixels` calls. Emits `PaintingPaused`.
21. `unpausePainting`: Admin function to re-enable painting calls. Emits `PaintingUnpaused`.
22. `pauseProtection`: Admin function to temporarily halt all `protectPixel` and `batchProtectPixels` calls. Emits `ProtectionPaused`.
23. `unpauseProtection`: Admin function to re-enable protection calls. Emits `ProtectionUnpaused`.
24. `getCanvasDimensions`: Returns the width and height of the canvas.
25. `getPaintCost`: Returns the current cost to paint a pixel.
26. `getProtectCostPerSecond`: Returns the current cost to protect a pixel per second.
27. `getDefaultDecayRate`: Returns the current default decay rate.
28. `getDefaultPixelColor`: Returns the current default pixel color (packed).
29. `getProtectionMultiplier`: Returns the current protection multiplier.
30. `getAdminAddress`: Returns the current admin address.
31. `getContractBalance`: Returns the current Ether balance held by the contract (collected fees).
32. `isPaintingPaused`: Returns the current status of the painting pause flag.
33. `isProtectionPaused`: Returns the current status of the protection pause flag.
34. `receive()`: Fallback function to accept incoming Ether transfers.
35. `fallback()`: Fallback function to accept incoming Ether transfers sent with data.

This contract provides a foundation for a dynamic, interactive, and economically driven collaborative art project on-chain, utilizing time-based state changes and derived data as its core advanced concept.