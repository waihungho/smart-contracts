Okay, let's create a smart contract concept called "Eternal Canvas".

**Concept:** A persistent, large digital canvas represented on the blockchain. Users can purchase ownership of individual pixels or small blocks of pixels and then paint them. Other users can also paint pixels they *don't* own, but they must pay a fee to the pixel's owner. This creates an on-chain economy and a dynamically evolving piece of collaborative, persistent art.

**Advanced/Creative Aspects:**
1.  **On-chain Dynamic State:** The core data (pixel colors and ownership) lives entirely on-chain and changes based on user interaction.
2.  **Micro-Economy:** Users earn passive income (fees) from others painting their owned pixels.
3.  **Delegated Permissions:** Owners can delegate painting rights to other addresses.
4.  **Batch Operations:** Functions for buying or painting multiple pixels in a single transaction for gas efficiency.
5.  **Palette Management:** Curated color palette controlled by the contract owner (or a future DAO).
6.  **Persistent Ownership:** Pixel ownership, once bought, is permanent unless transferred or renounced.

Let's structure the contract.

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
// For simplicity and reducing dependencies, we'll use a basic Ownable implementation.
// If deploying, consider using the standard @openzeppelin/contracts/access/Ownable.sol

// --- Contract: EternalCanvas ---
// A persistent, pixel-based digital canvas on the blockchain.
// Users can buy ownership of pixels and paint them.
// Non-owners can paint pixels by paying a fee to the owner.

// --- Outline ---
// 1. State Variables: Define canvas dimensions, pixel data (color & owner), pricing, palette, fees.
// 2. Events: Announce key actions like painting, ownership changes, price updates.
// 3. Structs: Define a struct to return pixel data cleanly.
// 4. Constructor: Initialize canvas size, initial prices, and palette.
// 5. Core Pixel Interaction Functions:
//    - buyPixelOwnership: Purchase ownership of a pixel.
//    - paintPixel: Change the color of a pixel (requires ownership or payment).
//    - paintPixels: Batch version of paintPixel.
//    - transferPixelOwnership: Transfer ownership of a pixel.
//    - renouncePixelOwnership: Give up ownership.
// 6. Delegation Functions:
//    - setPaintPermission: Allow/disallow another address to paint your pixel.
//    - canDelegatePaint: Check if an address has delegated paint permission for a pixel.
// 7. Getters (Read-Only Functions):
//    - getCanvasWidth, getCanvasHeight, getTotalPixels: Canvas dimensions.
//    - getPixelColor, getPixelOwner, getPixelData: Individual pixel info.
//    - getPixelsData: Batch pixel info.
//    - getPalette, getPaletteSize, getPaletteColor: Color palette info.
//    - getOwnershipPrice, getPaintingPrice: Current pricing.
//    - getContractBalance, getFeeRecipient: Contract state & finance info.
// 8. Admin/Owner Functions (onlyOwner):
//    - updateOwnershipPrice, updatePaintingPrice: Modify costs.
//    - addPaletteColor, removePaletteColor: Manage the allowed colors.
//    - setFeeRecipient: Change where contract fees go.
//    - withdrawFees: Withdraw accumulated contract fees.

// --- Function Summary (Total: 29 functions) ---
// Core Actions (7):
// 1. constructor(...)
// 2. buyPixelOwnership(uint256 _pixelIndex): Purchase ownership of a pixel. Pays msg.value.
// 3. paintPixel(uint256 _pixelIndex, uint8 _colorIndex): Paint a single pixel. Requires ownership or pays paintingPrice to owner.
// 4. paintPixels(uint256[] _pixelIndexes, uint8[] _colorIndexes): Paint multiple pixels in batch. Handles ownership/payment per pixel.
// 5. transferPixelOwnership(uint256 _pixelIndex, address _newOwner): Transfer ownership of a pixel to another address.
// 6. batchTransferOwnership(uint256[] _pixelIndexes, address _newOwner): Transfer ownership of multiple pixels to one address.
// 7. renouncePixelOwnership(uint256 _pixelIndex): Relinquish ownership of a pixel.

// Delegation (2):
// 8. setPaintPermission(uint256 _pixelIndex, address _delegate, bool _allowed): Grant or revoke paint permission for a specific pixel to a delegate.
// 9. canDelegatePaint(uint256 _pixelIndex, address _delegate): Check if a delegate has paint permission for a pixel.

// Getters (13):
// 10. getCanvasWidth(): Returns the width of the canvas.
// 11. getCanvasHeight(): Returns the height of the canvas.
// 12. getTotalPixels(): Returns the total number of pixels on the canvas (width * height).
// 13. getPixelColor(uint256 _pixelIndex): Returns the color index of a pixel.
// 14. getPixelOwner(uint256 _pixelIndex): Returns the owner address of a pixel (address(0) if unowned).
// 15. getPixelData(uint256 _pixelIndex): Returns color index and owner for a pixel.
// 16. getPixelsData(uint256[] _pixelIndexes): Returns color index and owner for multiple pixels.
// 17. getPalette(): Returns the full array of allowed colors (RGB uint24).
// 18. getPaletteSize(): Returns the number of colors in the palette.
// 19. getPaletteColor(uint8 _index): Returns a specific color from the palette by index.
// 20. getOwnershipPrice(): Returns the current price to buy pixel ownership.
// 21. getPaintingPrice(): Returns the current price for a non-owner to paint a pixel.
// 22. getFeeRecipient(): Returns the address that receives contract fees.

// Admin/Owner Functions (7):
// 23. updateOwnershipPrice(uint256 _newPrice): Update the price to buy pixel ownership.
// 24. updatePaintingPrice(uint256 _newPrice): Update the price for non-owners to paint.
// 25. addPaletteColor(uint24 _color): Add a new color to the allowed palette.
// 26. removePaletteColor(uint8 _index): Remove a color from the palette.
// 27. setFeeRecipient(address _recipient): Set the address to receive contract fees.
// 28. withdrawFees(): Withdraw accumulated contract fees sent to the fee recipient.
// 29. transferOwnership(address _newOwner): Transfer contract ownership (from Ownable).

// Simple Ownable implementation (or use @openzeppelin/contracts/access/Ownable.sol)
contract BasicOwnable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), msg.sender);
    }

    modifier onlyOwner() {
        require(_owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}


contract EternalCanvas is BasicOwnable {

    // --- State Variables ---
    uint16 public immutable canvasWidth;
    uint16 public immutable canvasHeight;
    uint256 private immutable totalPixels;

    // Pixel data: Index -> Color Index
    // uint8 is used assuming a palette of max 256 colors
    mapping(uint256 => uint8) private pixelColors;

    // Pixel ownership: Index -> Owner Address
    // address(0) means unowned
    mapping(uint256 => address) private pixelOwners;

    // Delegation: Owner Address -> Pixel Index -> Delegate Address -> Allowed (bool)
    mapping(address => mapping(uint256 => mapping(address => bool))) private paintDelegations;

    // Allowed colors (RGB as uint24)
    uint24[] private palette;

    // Pricing in Wei
    uint256 private ownershipPrice; // Price to buy ownership of one pixel
    uint256 private paintingPrice;  // Price for non-owner to paint one pixel

    // Address to send contract fees (from non-owner painting)
    address private feeRecipient;

    // --- Events ---
    event PixelPainted(uint256 indexed pixelIndex, uint8 indexed colorIndex, address indexed painter, address indexed owner, uint256 feePaid);
    event PixelOwnershipBought(uint256 indexed pixelIndex, address indexed newOwner, uint256 pricePaid);
    event PixelOwnershipTransferred(uint256 indexed pixelIndex, address indexed oldOwner, address indexed newOwner);
    event PixelOwnershipRenounced(uint256 indexed pixelIndex, address indexed oldOwner);
    event PaintPermissionSet(uint256 indexed pixelIndex, address indexed owner, address indexed delegate, bool allowed);
    event OwnershipPriceUpdated(uint256 indexed oldPrice, uint256 indexed newPrice);
    event PaintingPriceUpdated(uint256 indexed oldPrice, uint256 indexed newPrice);
    event PaletteColorAdded(uint8 indexed colorIndex, uint24 indexed color);
    event PaletteColorRemoved(uint8 indexed colorIndex, uint24 indexed color);
    event FeeRecipientUpdated(address indexed oldRecipient, address indexed newRecipient);
    event FeesWithdrawn(address indexed recipient, uint256 indexed amount);

    // --- Structs ---
    struct PixelData {
        uint8 colorIndex;
        address owner;
    }

    // --- Constructor ---
    constructor(uint16 _width, uint16 _height, uint256 _initialOwnershipPrice, uint256 _initialPaintingPrice, uint24[] memory _initialPalette) {
        require(_width > 0 && _height > 0, "Canvas dimensions must be positive");
        require(_initialPalette.length > 0, "Palette cannot be empty");
        require(_initialPalette.length <= 256, "Palette max size is 256");

        canvasWidth = _width;
        canvasHeight = _height;
        totalPixels = uint256(_width) * uint256(_height);

        ownershipPrice = _initialOwnershipPrice;
        paintingPrice = _initialPaintingPrice;
        palette = _initialPalette;
        feeRecipient = msg.sender; // Default fee recipient is the contract owner
    }

    // --- Internal Helpers ---
    function _isValidPixelIndex(uint256 _index) internal view returns (bool) {
        return _index < totalPixels;
    }

    function _isValidColorIndex(uint8 _index) internal view returns (bool) {
        return _index < palette.length;
    }

    function _getPixelOwner(uint256 _pixelIndex) internal view returns (address) {
        // Default mapping value for address is address(0)
        return pixelOwners[_pixelIndex];
    }

    function _getPixelColor(uint256 _pixelIndex) internal view returns (uint8) {
        // Default mapping value for uint8 is 0.
        // Assuming palette[0] is a default/background color (e.g., black or white).
        return pixelColors[_pixelIndex];
    }

    // --- Core Pixel Interaction Functions ---

    /**
     * @notice Allows msg.sender to buy ownership of a specific pixel.
     * @param _pixelIndex The index of the pixel (0 to totalPixels - 1).
     * @dev Pixel must not already be owned. Requires sending exactly `ownershipPrice` Wei.
     */
    function buyPixelOwnership(uint256 _pixelIndex) public payable {
        require(_isValidPixelIndex(_pixelIndex), "Invalid pixel index");
        require(_getPixelOwner(_pixelIndex) == address(0), "Pixel is already owned");
        require(msg.value == ownershipPrice, "Incorrect ownership price sent");

        pixelOwners[_pixelIndex] = msg.sender;

        // Send the payment for ownership to the contract owner (or fee recipient?)
        // Let's send ownership purchase fees to the feeRecipient as well.
        (bool success, ) = payable(feeRecipient).call{value: msg.value}("");
        require(success, "Payment failed");

        emit PixelOwnershipBought(_pixelIndex, msg.sender, msg.value);
    }

    /**
     * @notice Allows msg.sender to paint a specific pixel with a color from the palette.
     * @param _pixelIndex The index of the pixel.
     * @param _colorIndex The index of the color in the palette.
     * @dev If msg.sender is the owner of the pixel or has delegated permission, painting is free (gas only).
     *      Otherwise, requires sending `paintingPrice` Wei, which is sent to the pixel owner.
     */
    function paintPixel(uint256 _pixelIndex, uint8 _colorIndex) public payable {
        require(_isValidPixelIndex(_pixelIndex), "Invalid pixel index");
        require(_isValidColorIndex(_colorIndex), "Invalid color index");

        address currentOwner = _getPixelOwner(_pixelIndex);
        bool isOwner = currentOwner == msg.sender;
        bool isDelegate = false;
        if (currentOwner != address(0)) {
           isDelegate = paintDelegations[currentOwner][_pixelIndex][msg.sender];
        }


        uint256 fee = 0;
        address feeDestination = address(0);

        if (isOwner || isDelegate) {
            // Painting is free (gas only) for owner or delegate
            require(msg.value == 0, "Owner/Delegate should send 0 value");
        } else {
            // Not owner, require payment
            require(currentOwner != address(0), "Cannot paint unowned pixel without permission (only owners benefit)");
            require(msg.value >= paintingPrice, "Insufficient payment for painting");

            fee = paintingPrice;
            feeDestination = currentOwner;

            if (msg.value > paintingPrice) {
                 // Refund excess ether
                (bool successRefund, ) = payable(msg.sender).call{value: msg.value - paintingPrice}("");
                require(successRefund, "Refund failed");
            }

            // Send fee to the pixel owner
            (bool successPayment, ) = payable(feeDestination).call{value: fee}("");
            require(successPayment, "Fee payment to owner failed");
        }

        pixelColors[_pixelIndex] = _colorIndex;

        emit PixelPainted(_pixelIndex, _colorIndex, msg.sender, currentOwner, fee);
    }

    /**
     * @notice Allows msg.sender to paint multiple pixels in a single transaction.
     * @param _pixelIndexes An array of pixel indices to paint.
     * @param _colorIndexes An array of color indices corresponding to the pixels.
     * @dev The lengths of _pixelIndexes and _colorIndexes must match. Handles ownership/payment logic for each pixel individually.
     *      The total value sent must be sufficient for all pixels requiring payment. Excess will be refunded.
     */
    function paintPixels(uint256[] memory _pixelIndexes, uint8[] memory _colorIndexes) public payable {
        require(_pixelIndexes.length == _colorIndexes.length, "Array lengths must match");
        require(_pixelIndexes.length > 0, "Must provide at least one pixel to paint");

        uint256 totalRequiredFee = 0;
        address[] memory ownersToPay = new address[](_pixelIndexes.length);
        uint256[] memory feesToPay = new uint256[](_pixelIndexes.length);
        uint256 paymentsCount = 0;

        // First pass: Validate inputs and calculate total fee required and owner payments
        for (uint i = 0; i < _pixelIndexes.length; i++) {
            uint256 pixelIndex = _pixelIndexes[i];
            uint8 colorIndex = _colorIndexes[i];

            require(_isValidPixelIndex(pixelIndex), "Invalid pixel index in batch");
            require(_isValidColorIndex(colorIndex), "Invalid color index in batch");

            address currentOwner = _getPixelOwner(pixelIndex);
            bool isOwner = currentOwner == msg.sender;
            bool isDelegate = false;
             if (currentOwner != address(0)) {
                isDelegate = paintDelegations[currentOwner][pixelIndex][msg.sender];
            }


            if (!isOwner && !isDelegate) {
                 require(currentOwner != address(0), "Cannot paint unowned pixel without permission in batch");
                totalRequiredFee += paintingPrice;
                // Store owner and fee to pay in a separate array to avoid reentrancy issues
                ownersToPay[paymentsCount] = currentOwner;
                feesToPay[paymentsCount] = paintingPrice;
                paymentsCount++;
            }
        }

        require(msg.value >= totalRequiredFee, "Insufficient total payment for batch painting");

        // Refund excess ether BEFORE making external calls
        if (msg.value > totalRequiredFee) {
             (bool successRefund, ) = payable(msg.sender).call{value: msg.value - totalRequiredFee}("");
             require(successRefund, "Batch refund failed"); // Should not fail if value > 0
        }

        // Second pass: Apply colors and make payments
        for (uint i = 0; i < _pixelIndexes.length; i++) {
            uint256 pixelIndex = _pixelIndexes[i];
            uint8 colorIndex = _colorIndexes[i];
             address currentOwner = _getPixelOwner(pixelIndex);
            bool isOwner = currentOwner == msg.sender;
            bool isDelegate = false;
             if (currentOwner != address(0)) {
                isDelegate = paintDelegations[currentOwner][pixelIndex][msg.sender];
            }

            uint256 feePaid = 0;
            address feeDestination = address(0);

            if (!isOwner && !isDelegate) {
                 // Find the corresponding payment data from the first pass
                 // This assumes the order of payments corresponds to the order of pixels requiring payment
                 // A more robust way might involve a map or a more complex data structure,
                 // but given the check logic, a simple counter works here.
                 // Note: In a real-world scenario, careful handling of potential payment failures is needed.
                 // For this example, we assume payments will succeed after the refund.
                 // A more production-ready version might accumulate failed payments and handle them differently.

                 // Simple approach for this example: track which payment corresponds to which pixel
                 // This requires the ownersToPay/feesToPay arrays to be exactly the size of _pixelIndexes
                 // and non-owner pixels processed sequentially.
                 // A safer way: iterate paymentsCount times and find the owner/fee.
                 // Let's do the simpler version for code clarity in this example.

                // Find the payment for this pixel - this loop is simple but potentially inefficient
                // for very large batches if many pixels require payment.
                // A mapping or pre-calculated indices would be better for truly massive batches.
                for(uint j = 0; j < paymentsCount; j++){
                    if (ownersToPay[j] == currentOwner && feesToPay[j] == paintingPrice) {
                        // Mark this payment as used (e.g., set fee to 0) and use it
                         feePaid = feesToPay[j];
                         feeDestination = ownersToPay[j];
                         feesToPay[j] = 0; // Mark as used
                         ownersToPay[j] = address(0); // Mark as used
                         break; // Found the payment for this pixel
                    }
                }
                 // The actual payment is handled by the `call` below.
                 // This assumes all required payments were included in the totalRequiredFee
                 // and the call will process them from the contract's balance.
                 // This is a simplification. A proper batch payment would iterate paymentsCount
                 // times and make individual calls *after* validating and refunding.
                 // Let's adjust the payment logic to be safer.
            }

             // Apply the color change regardless of payment method (owner/delegate or paid)
            pixelColors[pixelIndex] = colorIndex;

            // Emit event AFTER state change
            // Note: The feePaid value here is just what *should* have been paid based on logic,
            // not necessarily confirmation the transfer succeeded in the batch loop.
            // In a production system, you might emit events only after transfers succeed.
            emit PixelPainted(pixelIndex, colorIndex, msg.sender, currentOwner, feePaid);
        }

        // Now, iterate through the gathered payments and make the calls.
        // This pattern (gather calls -> make calls) prevents reentrancy.
         for(uint i = 0; i < paymentsCount; i++){
            if(ownersToPay[i] != address(0) && feesToPay[i] > 0){ // Ensure it's a valid payment entry
                 (bool successPayment, ) = payable(ownersToPay[i]).call{value: feesToPay[i]}("");
                 // Note: In a production contract, handling failed individual payments in a batch
                 // would be necessary (e.g., reverting the whole batch or logging failures).
                 require(successPayment, "Batch fee payment failed for one owner"); // Basic failure handling
            }
        }
    }


    /**
     * @notice Transfers ownership of a pixel to another address.
     * @param _pixelIndex The index of the pixel.
     * @param _newOwner The address to transfer ownership to.
     * @dev Only the current owner can transfer ownership. Cannot transfer to address(0).
     */
    function transferPixelOwnership(uint256 _pixelIndex, address _newOwner) public {
        require(_isValidPixelIndex(_pixelIndex), "Invalid pixel index");
        require(_getPixelOwner(_pixelIndex) == msg.sender, "Only pixel owner can transfer");
        require(_newOwner != address(0), "Cannot transfer to zero address");

        address oldOwner = msg.sender;
        pixelOwners[_pixelIndex] = _newOwner;

        // Clear any existing delegations for this pixel by the old owner
        // Note: This clears ALL delegates for this pixel under the old owner's mapping.
        // If granular control is needed per delegate, a different structure is required.
        delete paintDelegations[oldOwner][_pixelIndex];


        emit PixelOwnershipTransferred(_pixelIndex, oldOwner, _newOwner);
    }

     /**
     * @notice Transfers ownership of multiple pixels to another address.
     * @param _pixelIndexes An array of pixel indices to transfer.
     * @param _newOwner The address to transfer ownership to.
     * @dev Only the current owner can transfer ownership of their pixels in the batch.
     *      Pixels in the list not owned by msg.sender will cause the transaction to revert.
     *      Cannot transfer to address(0).
     */
    function batchTransferOwnership(uint256[] memory _pixelIndexes, address _newOwner) public {
        require(_pixelIndexes.length > 0, "Must provide at least one pixel to transfer");
        require(_newOwner != address(0), "Cannot transfer to zero address");

        address oldOwner = msg.sender;

        for (uint i = 0; i < _pixelIndexes.length; i++) {
            uint256 pixelIndex = _pixelIndexes[i];
            require(_isValidPixelIndex(pixelIndex), "Invalid pixel index in batch");
            require(_getPixelOwner(pixelIndex) == oldOwner, "Cannot batch transfer pixel not owned by caller");

            pixelOwners[pixelIndex] = _newOwner;
            // Clear delegations for each transferred pixel
            delete paintDelegations[oldOwner][pixelIndex];

             emit PixelOwnershipTransferred(pixelIndex, oldOwner, _newOwner);
        }
    }


    /**
     * @notice Renounces ownership of a pixel, making it unowned and available for purchase again.
     * @param _pixelIndex The index of the pixel.
     * @dev Only the current owner can renounce ownership.
     */
    function renouncePixelOwnership(uint256 _pixelIndex) public {
        require(_isValidPixelIndex(_pixelIndex), "Invalid pixel index");
        require(_getPixelOwner(_pixelIndex) == msg.sender, "Only pixel owner can renounce");

        address oldOwner = msg.sender;
        pixelOwners[_pixelIndex] = address(0);

         // Clear any existing delegations for this pixel by the old owner
        delete paintDelegations[oldOwner][_pixelIndex];

        emit PixelOwnershipRenounced(_pixelIndex, oldOwner);
    }

    // --- Delegation Functions ---

     /**
     * @notice Sets or revokes paint permission for a delegate on a specific pixel owned by msg.sender.
     * @param _pixelIndex The index of the pixel.
     * @param _delegate The address to grant or revoke permission.
     * @param _allowed True to grant permission, false to revoke.
     * @dev Only the pixel owner can set delegation.
     */
    function setPaintPermission(uint256 _pixelIndex, address _delegate, bool _allowed) public {
         require(_isValidPixelIndex(_pixelIndex), "Invalid pixel index");
         require(_getPixelOwner(_pixelIndex) == msg.sender, "Only pixel owner can set delegation");
         require(_delegate != address(0), "Cannot set delegation for zero address");

         paintDelegations[msg.sender][_pixelIndex][_delegate] = _allowed;

         emit PaintPermissionSet(_pixelIndex, msg.sender, _delegate, _allowed);
    }

    /**
     * @notice Checks if a delegate has paint permission for a specific pixel.
     * @param _pixelIndex The index of the pixel.
     * @param _delegate The address to check.
     * @return bool True if the delegate has permission, false otherwise.
     */
    function canDelegatePaint(uint256 _pixelIndex, address _delegate) public view returns (bool) {
         require(_isValidPixelIndex(_pixelIndex), "Invalid pixel index");
         address currentOwner = _getPixelOwner(_pixelIndex);
         if (currentOwner == address(0)) return false; // Cannot delegate on unowned pixel
         return paintDelegations[currentOwner][_pixelIndex][_delegate];
    }


    // --- Getters (Read-Only) ---

    function getCanvasWidth() public view returns (uint16) {
        return canvasWidth;
    }

    function getCanvasHeight() public view returns (uint16) {
        return canvasHeight;
    }

    function getTotalPixels() public view returns (uint256) {
        return totalPixels;
    }

    function getPixelColor(uint256 _pixelIndex) public view returns (uint8) {
        require(_isValidPixelIndex(_pixelIndex), "Invalid pixel index");
        return _getPixelColor(_pixelIndex);
    }

    function getPixelOwner(uint256 _pixelIndex) public view returns (address) {
        require(_isValidPixelIndex(_pixelIndex), "Invalid pixel index");
        return _getPixelOwner(_pixelIndex);
    }

    function getPixelData(uint256 _pixelIndex) public view returns (PixelData memory) {
        require(_isValidPixelIndex(_pixelIndex), "Invalid pixel index");
        return PixelData({
            colorIndex: _getPixelColor(_pixelIndex),
            owner: _getPixelOwner(_pixelIndex)
        });
    }

     /**
     * @notice Gets color index and owner for multiple pixels.
     * @param _pixelIndexes An array of pixel indices.
     * @return PixelData[] An array of PixelData structs for the requested pixels.
     * @dev Useful for clients to fetch batches of data.
     */
    function getPixelsData(uint256[] memory _pixelIndexes) public view returns (PixelData[] memory) {
        PixelData[] memory data = new PixelData[](_pixelIndexes.length);
        for (uint i = 0; i < _pixelIndexes.length; i++) {
            uint256 pixelIndex = _pixelIndexes[i];
            require(_isValidPixelIndex(pixelIndex), "Invalid pixel index in batch query");
             data[i] = PixelData({
                colorIndex: _getPixelColor(pixelIndex),
                owner: _getPixelOwner(pixelIndex)
            });
        }
        return data;
    }


    function getPalette() public view returns (uint24[] memory) {
        return palette;
    }

    function getPaletteSize() public view returns (uint8) {
        return uint8(palette.length);
    }

     function getPaletteColor(uint8 _index) public view returns (uint24) {
        require(_isValidColorIndex(_index), "Invalid palette index");
        return palette[_index];
    }

    function getOwnershipPrice() public view returns (uint256) {
        return ownershipPrice;
    }

    function getPaintingPrice() public view returns (uint256) {
        return paintingPrice;
    }

    function getFeeRecipient() public view returns (address) {
        return feeRecipient;
    }

     /**
     * @notice Returns the current Ether balance of the contract.
     * @dev This balance accumulates any unspent ether or fees not yet withdrawn.
     *      Note: Ownership purchase fees are sent directly to the feeRecipient,
     *      so this balance primarily represents unwithdrawn painting fees
     *      and any accidental transfers.
     */
    function getContractBalance() public view returns (uint256) {
        return address(this).balance;
    }


    // --- Admin/Owner Functions ---

    /**
     * @notice Updates the price to buy ownership of a pixel.
     * @param _newPrice The new price in Wei.
     * @dev Only contract owner can call this.
     */
    function updateOwnershipPrice(uint256 _newPrice) public onlyOwner {
        uint256 oldPrice = ownershipPrice;
        ownershipPrice = _newPrice;
        emit OwnershipPriceUpdated(oldPrice, _newPrice);
    }

    /**
     * @notice Updates the price for a non-owner to paint a pixel.
     * @param _newPrice The new price in Wei.
     * @dev Only contract owner can call this.
     */
    function updatePaintingPrice(uint256 _newPrice) public onlyOwner {
         uint256 oldPrice = paintingPrice;
        paintingPrice = _newPrice;
        emit PaintingPriceUpdated(oldPrice, _newPrice);
    }

     /**
     * @notice Adds a new color to the allowed palette.
     * @param _color The new color (RGB as uint24).
     * @dev Only contract owner can call this. Palette size is limited to 256.
     */
    function addPaletteColor(uint24 _color) public onlyOwner {
        require(palette.length < 256, "Palette is full");
        palette.push(_color);
        emit PaletteColorAdded(uint8(palette.length - 1), _color);
    }

     /**
     * @notice Removes a color from the allowed palette by index.
     * @param _index The index of the color to remove.
     * @dev Only contract owner can call this. Cannot remove the last color.
     *      Note: Removing colors shifts subsequent indices. Existing pixel data
     *      using removed color indices will now point to different colors or default to 0
     *      if the index becomes out of bounds. Use with caution.
     */
    function removePaletteColor(uint8 _index) public onlyOwner {
        require(_isValidColorIndex(_index), "Invalid palette index");
        require(palette.length > 1, "Cannot remove the last color"); // Keep at least one color

        uint24 removedColor = palette[_index];

        // Shift elements to fill the gap
        for (uint i = _index; i < palette.length - 1; i++) {
            palette[i] = palette[i + 1];
        }
        palette.pop();

        emit PaletteColorRemoved(_index, removedColor);
    }


    /**
     * @notice Sets the address that receives contract fees.
     * @param _recipient The new fee recipient address.
     * @dev Only contract owner can call this. Cannot be the zero address.
     */
    function setFeeRecipient(address _recipient) public onlyOwner {
        require(_recipient != address(0), "Fee recipient cannot be zero address");
        address oldRecipient = feeRecipient;
        feeRecipient = _recipient;
        emit FeeRecipientUpdated(oldRecipient, _recipient);
    }

    /**
     * @notice Allows the fee recipient to withdraw the contract's balance.
     * @dev Only the current fee recipient can call this.
     *      Note: This withdraws *all* available balance. Ownership fees are typically
     *      sent directly upon purchase, so this is mainly for accumulated painting fees.
     */
    function withdrawFees() public {
        require(msg.sender == feeRecipient, "Only the fee recipient can withdraw fees");
        uint256 balance = address(this).balance;
        require(balance > 0, "No fees to withdraw");

        (bool success, ) = payable(feeRecipient).call{value: balance}("");
        require(success, "Fee withdrawal failed");

        emit FeesWithdrawn(feeRecipient, balance);
    }

    // Function from Ownable
    // 29. transferOwnership(address _newOwner) - Inherited from BasicOwnable

    // Receive function to accept direct Ether transfers (optional, but good practice)
    // Allows the contract to receive ETH if sent directly, though fees go to owners/recipient.
    receive() external payable {}
    fallback() external payable {}
}
```