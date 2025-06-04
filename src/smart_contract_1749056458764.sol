Okay, let's create a smart contract for a collaborative, dynamic, on-chain "CryptoCanvas". This contract will manage a grid of pixels where users can buy ownership, change colors, and trade pixels. It incorporates concepts like dynamic pricing, transfer fees, batch operations, and admin controls, without strictly following standard interfaces like ERC721, making it a custom asset type tied to the grid structure.

---

**Outline & Function Summary**

**Contract:** `CryptoCanvas`

**Concept:** A fixed-size grid (canvas) where each pixel is a unique, ownable, and mutable asset. Users can buy pixels, change their color, and transfer ownership. The price of pixels increases dynamically based on sales. A small fee is applied to transfers.

**Key Features:**
*   **Grid-Based Asset:** Pixels are identified by coordinates (x, y) which map to a unique ID.
*   **Dynamic Pricing:** The cost to buy a pixel increases with the total number of pixels sold.
*   **Transfer Fees:** A percentage fee is charged on pixel transfers, collected by the contract.
*   **On-Chain State:** Pixel ownership, color, and timestamps are stored on the blockchain.
*   **Batch Operations:** Functions for buying/changing colors of multiple pixels in a single transaction.
*   **Admin Controls:** Owner can set pricing parameters, withdraw funds, and manage reserved pixels.
*   **Reserved Pixels:** Administrator can mark specific pixels as not buyable/transferable by normal users.

**Data Structures:**
*   `PixelData`: Struct to store the owner, color (uint32 representing RGB), last update time, and creation time for each pixel.

**State Variables:**
*   `width`, `height`: Dimensions of the canvas grid.
*   `pixels`: Mapping from pixel ID (uint256) to `PixelData`.
*   `ownedPixelCount`: Mapping from address to the number of pixels they own.
*   `totalPixelsSold`: Counter for total unique pixels ever sold.
*   `basePrice`: Starting price for the first pixel.
*   `priceIncrement`: Amount added to the price per pixel sold.
*   `transferFeeBasisPoints`: Fee percentage on transfers (e.g., 100 = 1%).
*   `owner`: The contract deployer/administrator.
*   `reservedPixels`: Mapping to track reserved pixel IDs.

**Events:**
*   `PixelBought(uint256 indexed pixelId, address indexed owner, uint32 color, uint256 price)`
*   `PixelColorChanged(uint256 indexed pixelId, address indexed owner, uint32 newColor)`
*   `PixelTransferred(uint256 indexed pixelId, address indexed from, address indexed to, uint16 feeBasisPoints)`
*   `OwnershipTransferred(address indexed previousOwner, address indexed newOwner)`
*   `PixelReserved(uint256 indexed pixelId)`
*   `PixelUnreserved(uint256 indexed pixelId)`

**Function Summary (29 Functions):**

*   **Constructor:** Initializes the canvas dimensions, owner, and initial pricing.
*   **View/Pure Functions (Read-only):**
    1.  `canvasWidth()`: Get canvas width.
    2.  `canvasHeight()`: Get canvas height.
    3.  `getBasePrice()`: Get current base price.
    4.  `getPriceIncrement()`: Get current price increment.
    5.  `getTransferFeeBasisPoints()`: Get current transfer fee.
    6.  `getTotalPixelsSold()`: Get total count of pixels ever sold.
    7.  `getPixelData(uint256 pixelId)`: Get all data for a pixel by ID.
    8.  `getPixelDataByCoords(uint32 x, uint32 y)`: Get all data for a pixel by coordinates.
    9.  `isPixelOwned(uint256 pixelId)`: Check if a pixel is owned.
    10. `getPixelOwner(uint256 pixelId)`: Get the owner of a pixel.
    11. `getPixelColor(uint256 pixelId)`: Get the color of a pixel.
    12. `getPixelLastUpdateTime(uint256 pixelId)`: Get last update time.
    13. `getPixelCreationTime(uint256 pixelId)`: Get creation time.
    14. `getOwnedPixelCount(address account)`: Get the number of pixels owned by an address.
    15. `getCurrentPixelPrice(uint32 x, uint32 y)`: Calculate the dynamic price for buying a specific pixel. (Note: price is global, but function takes coords for interface consistency).
    16. `isPixelReserved(uint33 x, uint33 y)`: Check if a pixel is reserved by admin.
    17. `getPixelId(uint33 x, uint33 y)`: Helper to get pixel ID from coordinates.
*   **Transaction Functions (State-changing):**
    18. `buyPixel(uint33 x, uint33 y, uint32 color)`: Buy an unowned pixel and set its initial color. Pays dynamic price.
    19. `changePixelColor(uint33 x, uint33 y, uint32 newColor)`: Change the color of a pixel you own.
    20. `transferPixel(uint33 x, uint33 y, address recipient)`: Transfer ownership of a pixel to another address. Payer (sender) pays the transfer fee.
    21. `buyAndSetColorBatch(uint33[] calldata xCoords, uint33[] calldata yCoords, uint32[] calldata colors)`: Buy multiple pixels and set their colors in one transaction. Pays combined price.
    22. `changeColorBatch(uint33[] calldata xCoords, uint33[] calldata yCoords, uint32[] calldata colors)`: Change the colors of multiple owned pixels in one transaction.
*   **Admin Functions (onlyOwner):**
    23. `setBasePrice(uint256 newPrice)`: Set the base price for new pixels.
    24. `setPriceIncrement(uint256 newIncrement)`: Set the price increment per pixel sold.
    25. `setTransferFeeBasisPoints(uint16 newFee)`: Set the transfer fee percentage.
    26. `withdrawFunds()`: Withdraw accumulated contract balance (from sales and fees) to the owner.
    27. `reservePixel(uint33 x, uint33 y)`: Mark a pixel as reserved (cannot be bought/transferred by users).
    28. `unreservePixel(uint33 x, uint33 y)`: Unmark a pixel, making it available.
    29. `forceTransferPixel(uint33 x, uint33 y, address recipient)`: Admin can force transfer a pixel (e.g., for moderation).
    30. `forceChangePixelColor(uint33 x, uint33 y, uint32 newColor)`: Admin can force change a pixel's color (e.g., for moderation).

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title CryptoCanvas
 * @dev A smart contract managing a collaborative pixel grid.
 * Users can buy, color, and transfer ownership of pixels, with dynamic pricing and transfer fees.
 */
contract CryptoCanvas {

    // --- Data Structures ---

    struct PixelData {
        address owner;
        uint32 color; // e.g., 0xRRGGBB
        uint65 lastUpdateTime; // Using uint65 to potentially store larger timestamps if needed, or just block.timestamp (uint40-48 range usually)
        uint65 creationTime;
    }

    // --- State Variables ---

    uint32 public immutable canvasWidth;
    uint32 public immutable canvasHeight;

    mapping(uint256 => PixelData) private pixels; // pixelId => PixelData
    mapping(address => uint256) private ownedPixelCount; // owner => count
    mapping(uint256 => bool) private reservedPixels; // pixelId => isReserved

    uint256 public totalPixelsSold; // Counter for dynamic pricing

    uint256 public basePrice; // Base price for the first pixel
    uint256 public priceIncrement; // Price increases by this amount per pixel sold

    // Fee applied when a pixel is transferred (basis points, e.g., 100 = 1%)
    uint16 public transferFeeBasisPoints; // Max 10000 (100%)

    address payable public owner;

    // --- Events ---

    event PixelBought(uint256 indexed pixelId, address indexed owner, uint32 color, uint256 price);
    event PixelColorChanged(uint256 indexed pixelId, address indexed owner, uint32 newColor);
    event PixelTransferred(uint256 indexed pixelId, address indexed from, address indexed to, uint26 feePaid); // feePaid is the amount paid by 'from'
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event PixelReserved(uint256 indexed pixelId);
    event PixelUnreserved(uint256 indexed pixelId);

    // --- Modifiers ---

    modifier onlyOwner() {
        require(msg.sender == owner, "Not the contract owner");
        _;
    }

    modifier pixelExists(uint32 x, uint32 y) {
        require(x < canvasWidth && y < canvasHeight, "Pixel coordinates out of bounds");
        _;
    }

    // --- Constructor ---

    constructor(uint32 _width, uint32 _height, uint256 _basePrice, uint256 _priceIncrement, uint16 _transferFeeBasisPoints) {
        require(_width > 0 && _height > 0, "Canvas dimensions must be positive");
        require(_transferFeeBasisPoints <= 10000, "Transfer fee must be <= 10000 basis points (100%)");

        canvasWidth = _width;
        canvasHeight = _height;
        basePrice = _basePrice;
        priceIncrement = _priceIncrement;
        transferFeeBasisPoints = _transferFeeBasisPoints;
        owner = payable(msg.sender);
        totalPixelsSold = 0; // Initialize
    }

    // --- Internal/Pure Helper Functions ---

    /**
     * @dev Calculates the unique ID for a pixel based on its coordinates.
     */
    function _pixelId(uint33 x, uint33 y) internal pure returns (uint256) {
        // Using uint33 to prevent overflow during multiplication if width/height are large
        // and intermediate calculation x + y * width exceeds uint32 max.
        // Final result fits in uint256.
        return uint256(x) + uint256(y) * uint256(canvasWidth);
    }

    /**
     * @dev Checks if a pixel ID corresponds to a reserved pixel.
     */
    function _isPixelReserved(uint256 pixelId) internal view returns (bool) {
        return reservedPixels[pixelId];
    }

    // --- View/Pure Functions (Read-only) ---

    /**
     * @dev Get canvas width.
     */
    // function canvasWidth() external view returns (uint32) is already public

    /**
     * @dev Get canvas height.
     */
    // function canvasHeight() external view returns (uint32) is already public

    /**
     * @dev Get current base price for new pixels.
     */
    // function getBasePrice() external view returns (uint256) is already public

    /**
     * @dev Get current price increment per pixel sold.
     */
    // function getPriceIncrement() external view returns (uint256) is already public

    /**
     * @dev Get current transfer fee in basis points.
     */
    // function getTransferFeeBasisPoints() external view returns (uint16) is already public

    /**
     * @dev Get total count of unique pixels ever sold.
     */
    // function getTotalPixelsSold() external view returns (uint256) is already public

    /**
     * @dev Gets all data for a pixel by its unique ID.
     * @param pixelId The unique ID of the pixel.
     * @return PixelData struct containing owner, color, last update time, creation time.
     */
    function getPixelData(uint256 pixelId) external view returns (PixelData memory) {
         // No bounds check needed here, assumes pixelId was generated correctly
        return pixels[pixelId];
    }

    /**
     * @dev Gets all data for a pixel by its coordinates.
     * @param x The x-coordinate of the pixel.
     * @param y The y-coordinate of the pixel.
     * @return PixelData struct containing owner, color, last update time, creation time.
     */
    function getPixelDataByCoords(uint33 x, uint33 y) external view pixelExists(uint32(x), uint32(y)) returns (PixelData memory) {
        return pixels[_pixelId(x, y)];
    }

    /**
     * @dev Checks if a pixel is currently owned.
     * @param pixelId The unique ID of the pixel.
     * @return bool True if owned, false otherwise.
     */
    function isPixelOwned(uint256 pixelId) external view returns (bool) {
        // An owned pixel has a non-zero owner address
        return pixels[pixelId].owner != address(0);
    }

    /**
     * @dev Gets the owner of a pixel by ID. Returns address(0) if not owned.
     * @param pixelId The unique ID of the pixel.
     * @return address The owner's address.
     */
    function getPixelOwner(uint256 pixelId) external view returns (address) {
        return pixels[pixelId].owner;
    }

     /**
     * @dev Gets the color of a pixel by ID. Returns 0 if not owned or color never set.
     * @param pixelId The unique ID of the pixel.
     * @return uint32 The pixel color.
     */
    function getPixelColor(uint256 pixelId) external view returns (uint32) {
        return pixels[pixelId].color;
    }

    /**
     * @dev Gets the last update time (color change or transfer) of a pixel by ID.
     * @param pixelId The unique ID of the pixel.
     * @return uint65 The timestamp.
     */
    function getPixelLastUpdateTime(uint256 pixelId) external view returns (uint65) {
        return pixels[pixelId].lastUpdateTime;
    }

    /**
     * @dev Gets the initial creation time (when first bought) of a pixel by ID.
     * @param pixelId The unique ID of the pixel.
     * @return uint65 The timestamp.
     */
    function getPixelCreationTime(uint256 pixelId) external view returns (uint65) {
        return pixels[pixelId].creationTime;
    }

    /**
     * @dev Gets the number of pixels owned by a specific account.
     * @param account The address to check.
     * @return uint256 The count of owned pixels.
     */
    function getOwnedPixelCount(address account) external view returns (uint256) {
        return ownedPixelCount[account];
    }

    /**
     * @dev Calculates the current dynamic price to buy a pixel.
     * Price increases linearly with the total number of pixels sold.
     * @param x The x-coordinate (used for interface consistency, price is global).
     * @param y The y-coordinate (used for interface consistency, price is global).
     * @return uint256 The price in wei.
     */
    function getCurrentPixelPrice(uint33 x, uint33 y) external view pixelExists(uint32(x), uint32(y)) returns (uint256) {
        // Dynamic price calculation: basePrice + (totalPixelsSold * priceIncrement)
        // This simple model makes every subsequent pixel slightly more expensive globally.
        return basePrice + (totalPixelsSold * priceIncrement);
    }

    /**
     * @dev Checks if a pixel is reserved by the administrator.
     * Reserved pixels cannot be bought or transferred by normal users.
     * @param x The x-coordinate of the pixel.
     * @param y The y-coordinate of the pixel.
     * @return bool True if reserved, false otherwise.
     */
    function isPixelReserved(uint33 x, uint33 y) external view pixelExists(uint32(x), uint32(y)) returns (bool) {
        return reservedPixels[_pixelId(x, y)];
    }

     /**
     * @dev Helper to get pixel ID from coordinates.
     * @param x The x-coordinate.
     * @param y The y-coordinate.
     * @return uint256 The unique pixel ID.
     */
    function getPixelId(uint33 x, uint33 y) external pure pixelExists(uint32(x), uint32(y)) returns (uint256) {
        return _pixelId(x, y);
    }


    // --- Transaction Functions (State-changing) ---

    /**
     * @dev Allows a user to buy an unowned pixel and set its initial color.
     * Pays the current dynamic price.
     * @param x The x-coordinate of the pixel.
     * @param y The y-coordinate of the pixel.
     * @param color The initial color to set (0xRRGGBB).
     */
    function buyPixel(uint33 x, uint33 y, uint32 color) external payable pixelExists(uint32(x), uint32(y)) {
        uint256 pixelId = _pixelId(x, y);

        require(pixels[pixelId].owner == address(0), "Pixel is already owned");
        require(!_isPixelReserved(pixelId), "Pixel is reserved");

        uint256 currentPrice = basePrice + (totalPixelsSold * priceIncrement);
        require(msg.value >= currentPrice, "Insufficient payment to buy pixel");

        // Refund any excess payment
        if (msg.value > currentPrice) {
            payable(msg.sender).transfer(msg.value - currentPrice);
        }

        // Assign ownership and update pixel data
        pixels[pixelId].owner = msg.sender;
        pixels[pixelId].color = color;
        pixels[pixelId].creationTime = uint65(block.timestamp);
        pixels[pixelId].lastUpdateTime = uint65(block.timestamp);

        ownedPixelCount[msg.sender]++;
        totalPixelsSold++;

        emit PixelBought(pixelId, msg.sender, color, currentPrice);
    }

    /**
     * @dev Allows the owner of a pixel to change its color.
     * @param x The x-coordinate of the pixel.
     * @param y The y-coordinate of the pixel.
     * @param newColor The new color to set (0xRRGGBB).
     */
    function changePixelColor(uint33 x, uint33 y, uint32 newColor) external pixelExists(uint32(x), uint32(y)) {
        uint256 pixelId = _pixelId(x, y);
        PixelData storage pixel = pixels[pixelId];

        require(pixel.owner == msg.sender, "Not the pixel owner");

        pixel.color = newColor;
        pixel.lastUpdateTime = uint65(block.timestamp);

        emit PixelColorChanged(pixelId, msg.sender, newColor);
    }

    /**
     * @dev Transfers ownership of a pixel to another address.
     * The sender (current owner) pays a transfer fee to the contract.
     * @param x The x-coordinate of the pixel.
     * @param y The y-coordinate of the pixel.
     * @param recipient The address to transfer ownership to.
     */
    function transferPixel(uint33 x, uint33 y, address recipient) external payable pixelExists(uint32(x), uint32(y)) {
        uint256 pixelId = _pixelId(x, y);
        PixelData storage pixel = pixels[pixelId];

        require(pixel.owner == msg.sender, "Not the pixel owner");
        require(recipient != address(0), "Cannot transfer to the zero address");
        require(recipient != msg.sender, "Cannot transfer to yourself");
         require(!_isPixelReserved(pixelId), "Pixel is reserved and cannot be transferred by users");


        uint256 feeAmount = 0;
        if (transferFeeBasisPoints > 0) {
            // Fee is calculated based on a nominal value (e.g., current price of a new pixel)
            // or simply as a flat rate, or based on msg.value if ETH is sent with transfer.
            // Let's implement a simple fee based on a percentage of `msg.value` sent *with* the transfer call.
            // This allows flexibility - sender can pay the fee explicitly.
            // If msg.value is 0, fee is 0, unless a flat fee is desired.
            // Let's make the fee *required* to be sent with the transaction, calculated based on a *notional* value (like basePrice), or just a simple percentage of sent ETH.
            // Alternative: sender MUST send a fee amount with the transaction, and the contract verifies it's enough.
            // Let's go with: sender must send *at least* the calculated fee amount with the transaction. The fee is calculated based on basePrice for simplicity.
            uint256 notionalValue = basePrice; // Could be more complex, e.g., currentPrice
            feeAmount = (notionalValue * transferFeeBasisPoints) / 10000;
            require(msg.value >= feeAmount, "Insufficient fee payment");

             // Refund any excess fee payment
            if (msg.value > feeAmount) {
                 payable(msg.sender).transfer(msg.value - feeAmount);
            }
        }

        // Decrement sender's count
        ownedPixelCount[msg.sender]--;

        // Update ownership
        pixel.owner = recipient;
        pixel.lastUpdateTime = uint65(block.timestamp);

        // Increment recipient's count
        ownedPixelCount[recipient]++;

        emit PixelTransferred(pixelId, msg.sender, recipient, transferFeeBasisPoints);
    }

    /**
     * @dev Allows a user to buy multiple unowned pixels and set their initial colors in one transaction.
     * Pays the combined dynamic price for all pixels.
     * @param xCoords Array of x-coordinates.
     * @param yCoords Array of y-coordinates.
     * @param colors Array of initial colors (0xRRGGBB).
     */
    function buyAndSetColorBatch(uint33[] calldata xCoords, uint33[] calldata yCoords, uint32[] calldata colors) external payable {
        require(xCoords.length == yCoords.length && xCoords.length == colors.length, "Array lengths must match");
        require(xCoords.length > 0, "Batch cannot be empty");

        uint256 totalRequiredPayment = 0;
        uint256 currentTotalSold = totalPixelsSold; // Capture current state for pricing

        for (uint i = 0; i < xCoords.length; i++) {
            uint33 x = xCoords[i];
            uint33 y = yCoords[i];
            uint32 color = colors[i];

            require(x < canvasWidth && y < canvasHeight, "Pixel coordinates out of bounds in batch");

            uint256 pixelId = _pixelId(x, y);

            require(pixels[pixelId].owner == address(0), "Pixel already owned in batch");
            require(!_isPixelReserved(pixelId), "Pixel is reserved in batch");

            // Calculate price based on totalPixelsSold *before* this pixel purchase
            // This makes the pricing deterministic within the batch based on the contract state
            totalRequiredPayment += basePrice + ((currentTotalSold + i) * priceIncrement);
        }

        require(msg.value >= totalRequiredPayment, "Insufficient payment for batch purchase");

         // Refund any excess payment
        if (msg.value > totalRequiredPayment) {
            payable(msg.sender).transfer(msg.value - totalRequiredPayment);
        }

        // Process purchases and updates
        for (uint i = 0; i < xCoords.length; i++) {
            uint33 x = xCoords[i];
            uint33 y = yCoords[i];
            uint32 color = colors[i];
            uint256 pixelId = _pixelId(x, y);

            pixels[pixelId].owner = msg.sender;
            pixels[pixelId].color = color;
            pixels[pixelId].creationTime = uint65(block.timestamp);
            pixels[pixelId].lastUpdateTime = uint65(block.timestamp);

            ownedPixelCount[msg.sender]++;
            // Increment totalPixelsSold for *each* successful purchase in the batch
            totalPixelsSold++;

            // Price event uses the price at the time of *this specific pixel* purchase within the batch
            uint256 priceAtPurchase = basePrice + ((currentTotalSold + i) * priceIncrement);
            emit PixelBought(pixelId, msg.sender, color, priceAtPurchase);
        }
    }

     /**
     * @dev Allows the owner of multiple pixels to change their colors in one transaction.
     * @param xCoords Array of x-coordinates.
     * @param yCoords Array of y-coordinates.
     * @param colors Array of new colors (0xRRGGBB).
     */
    function changeColorBatch(uint33[] calldata xCoords, uint33[] calldata yCoords, uint32[] calldata colors) external {
        require(xCoords.length == yCoords.length && xCoords.length == colors.length, "Array lengths must match");
        require(xCoords.length > 0, "Batch cannot be empty");

        for (uint i = 0; i < xCoords.length; i++) {
            uint33 x = xCoords[i];
            uint33 y = yCoords[i];
            uint32 newColor = colors[i];

            require(x < canvasWidth && y < canvasHeight, "Pixel coordinates out of bounds in batch");

            uint256 pixelId = _pixelId(x, y);
            PixelData storage pixel = pixels[pixelId];

            require(pixel.owner == msg.sender, "Not the owner of a pixel in batch");

            pixel.color = newColor;
            pixel.lastUpdateTime = uint65(block.timestamp);

            emit PixelColorChanged(pixelId, msg.sender, newColor);
        }
    }


    // --- Admin Functions (onlyOwner) ---

    /**
     * @dev Admin function to set the base price for new pixels.
     * @param newPrice The new base price in wei.
     */
    function setBasePrice(uint256 newPrice) external onlyOwner {
        basePrice = newPrice;
    }

    /**
     * @dev Admin function to set the price increment per pixel sold.
     * @param newIncrement The new price increment in wei.
     */
    function setPriceIncrement(uint256 newIncrement) external onlyOwner {
        priceIncrement = newIncrement;
    }

    /**
     * @dev Admin function to set the transfer fee percentage in basis points.
     * @param newFee The new fee in basis points (0-10000).
     */
    function setTransferFeeBasisPoints(uint16 newFee) external onlyOwner {
        require(newFee <= 10000, "Transfer fee must be <= 10000 basis points (100%)");
        transferFeeBasisPoints = newFee;
    }

    /**
     * @dev Admin function to withdraw the accumulated contract balance (from sales and fees).
     */
    function withdrawFunds() external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No funds to withdraw");

        // Use call instead of transfer/send for better gas handling
        (bool success, ) = owner.call{value: balance}("");
        require(success, "Withdrawal failed");
    }

    /**
     * @dev Admin function to reserve a pixel, preventing users from buying or transferring it.
     * @param x The x-coordinate of the pixel.
     * @param y The y-coordinate of the pixel.
     */
    function reservePixel(uint33 x, uint33 y) external onlyOwner pixelExists(uint32(x), uint32(y)) {
        uint256 pixelId = _pixelId(x, y);
        require(!_isPixelReserved(pixelId), "Pixel is already reserved");
        // If the pixel is owned, this makes it 'stuck' with the current owner unless admin force transfers it.
        // It cannot be bought if unowned, or transferred by the owner if owned.
        reservedPixels[pixelId] = true;
        emit PixelReserved(pixelId);
    }

    /**
     * @dev Admin function to unreserve a pixel, making it available for users.
     * @param x The x-coordinate of the pixel.
     * @param y The y-coordinate of the pixel.
     */
    function unreservePixel(uint33 x, uint33 y) external onlyOwner pixelExists(uint32(x), uint32(y)) {
        uint256 pixelId = _pixelId(x, y);
        require(_isPixelReserved(pixelId), "Pixel is not reserved");
        reservedPixels[pixelId] = false;
         emit PixelUnreserved(pixelId);
    }

     /**
     * @dev Admin function to force transfer a pixel to a recipient, regardless of current ownership or reserved status.
     * Useful for moderation, resolving disputes, or assigning reserved pixels.
     * @param x The x-coordinate of the pixel.
     * @param y The y-coordinate of the pixel.
     * @param recipient The address to transfer ownership to.
     */
    function forceTransferPixel(uint33 x, uint33 y, address recipient) external onlyOwner pixelExists(uint32(x), uint32(y)) {
        uint256 pixelId = _pixelId(x, y);
        PixelData storage pixel = pixels[pixelId];
        address currentOwner = pixel.owner;

        require(recipient != address(0), "Cannot transfer to the zero address");

        if (currentOwner != address(0)) {
            ownedPixelCount[currentOwner]--;
        } else {
            // If unowned, this counts as a new pixel 'sold' by admin action for pricing purposes
            // Or we can decide it doesn't affect totalPixelsSold if it's an admin action.
            // Let's not increment totalPixelsSold for forced transfers.
            // If you force transfer an unowned pixel, it becomes owned without affecting the dynamic price.
        }


        pixel.owner = recipient;
        pixel.lastUpdateTime = uint65(block.timestamp);
         if (pixel.creationTime == 0) { // Set creation time if it's the first time this pixel is assigned an owner
             pixel.creationTime = uint65(block.timestamp);
         }


        ownedPixelCount[recipient]++;

        // Note: This emits a slightly different event or just uses the standard one
        // Standard event implies a user-initiated transfer with fee.
        // Let's emit the standard event, but feePaid will be 0.
        emit PixelTransferred(pixelId, currentOwner, recipient, 0);
    }

     /**
     * @dev Admin function to force change the color of a pixel, regardless of current ownership.
     * Useful for moderation or setting colors on reserved/unowned pixels.
     * @param x The x-coordinate of the pixel.
     * @param y The y-coordinate of the pixel.
     * @param newColor The new color to set (0xRRGGBB).
     */
    function forceChangePixelColor(uint33 x, uint33 y, uint32 newColor) external onlyOwner pixelExists(uint32(x), uint32(y)) {
         uint256 pixelId = _pixelId(x, y);
         PixelData storage pixel = pixels[pixelId];

         pixel.color = newColor;
         pixel.lastUpdateTime = uint65(block.timestamp);

         emit PixelColorChanged(pixelId, pixel.owner, newColor); // Emits with current owner (could be address(0))
    }

    // Fallback function to receive ETH if sent without calling a specific function
    // ETH sent here accumulates in the contract balance.
    receive() external payable {}
    fallback() external payable {}
}
```