Okay, here is a Solidity smart contract for a concept called "Infinite Canvas". This contract allows users to claim ownership of pixel coordinates on a conceptually infinite 2D plane, set their color, transfer them, delegate drawing rights, and manages different pixel types with varying properties (like color cooldowns). It includes batch operations, administrative controls, and uses a coordinate-to-hash mapping for the "infinite" plane storage.

It's not a standard ERC-721 (though pixels could potentially be wrapped as NFTs off-chain using the tokenURI functions), ERC-20, or typical governance/DeFi contract. It's a custom application logic centered around collaborative digital property management on a grid.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

// Outline & Function Summary
//
// Contract Name: InfiniteCanvas
// Purpose: Manages ownership and state of individual pixel coordinates on a conceptually infinite 2D grid.
// Users can claim, color, transfer, and delegate control over pixels.
// The contract includes pixel types with custom rules, batch operations, and administrative features.
//
// Modules:
// 1. Core Pixel Data & Mapping: Stores pixel data via a hash of (x, y) coordinates.
// 2. Pixel Types: Defines different configurations for pixels (fees, cooldowns).
// 3. Ownership & Access Control: Manages pixel ownership, drawing delegation, and contract administration (using Ownable + custom admin roles).
// 4. Actions: Functions for claiming, coloring, transferring, delegating pixels.
// 5. Batch Operations: Functions for performing actions on multiple pixels at once.
// 6. Views & Utility: Functions to retrieve pixel data, contract state, calculate hashes, etc.
// 7. Admin Functions: Functions for managing global settings, pixel types, and withdrawing funds.
// 8. Potential NFT Integration: Functions to derive a unique token ID and URI from pixel coordinates/data.
//
// State Variables:
// - pixels: Mapping from bytes32 (hash of x, y) to PixelData struct.
// - pixelTypes: Mapping from uint256 (type ID) to PixelType struct.
// - pixelTypeCount: Counter for unique pixel types.
// - globalPixelClaimFee: Default fee to claim a standard pixel.
// - pixelsClaimedCount: Total number of unique pixels ever claimed.
// - _admins: Mapping from address to bool for custom admin roles.
// - baseURI: Base URI for potential token metadata.
//
// Structs:
// - PixelData: Stores owner, color, pixel type ID, last color timestamp, delegated drawer, and metadata URI.
// - PixelType: Stores properties like name, claim fee, and color cooldown.
//
// Events:
// - PixelClaimed: Emitted when a new pixel is claimed.
// - PixelColorSet: Emitted when a pixel's color is changed.
// - PixelTransferred: Emitted when pixel ownership changes.
// - DrawingRightsDelegated: Emitted when drawing rights are delegated.
// - DrawingRightsRevoked: Emitted when drawing rights are revoked.
// - PixelBurned: Emitted when a pixel is burned.
// - PixelTypeAdded: Emitted when a new pixel type is added.
// - PixelTypeUpdated: Emitted when a pixel type is updated.
// - AdminAdded: Emitted when an address is granted admin rights.
// - AdminRemoved: Emitted when an address's admin rights are revoked.
//
// Modifiers:
// - onlyOwnerOrAdmin: Restricts access to the contract owner or a designated admin.
// - whenPixelExists: Ensures a pixel at the given coordinates exists.
// - whenPixelNotExists: Ensures no pixel exists at the given coordinates.
//
// Functions (>= 20):
// 1. constructor(): Initializes owner and sets initial global claim fee.
// 2. coordsToHash(int256 x, int256 y): Internal pure function to generate a unique hash for pixel coordinates.
// 3. claimPixel(int256 x, int256 y, uint256 pixelTypeId): Allows msg.sender to claim a new pixel at (x, y) of a specific type by paying the fee.
// 4. setPixelColor(int256 x, int256 y, bytes3 color): Allows the pixel owner to set its color (respecting cooldown).
// 5. transferPixelOwnership(int256 x, int256 y, address newOwner): Allows the pixel owner to transfer it.
// 6. delegateDrawingRights(int256 x, int256 y, address delegate): Allows the pixel owner to delegate color-setting rights.
// 7. revokeDrawingRights(int256 x, int256 y): Allows the pixel owner to revoke delegation.
// 8. setPixelColorDelegated(int256 x, int256 y, bytes3 color): Allows a delegated address to set the pixel color (respecting cooldown).
// 9. burnPixel(int256 x, int256 y): Allows the pixel owner to permanently remove it.
// 10. claimBatchPixels(int256[] xCoords, int256[] yCoords, uint256 pixelTypeId): Claims multiple pixels in a batch.
// 11. setPixelColorBatch(int256[] xCoords, int256[] yCoords, bytes3[] colors): Sets colors for multiple owned pixels.
// 12. transferBatchPixels(int256[] xCoords, int256[] yCoords, address newOwner): Transfers multiple owned pixels to one address.
// 13. setPixelColorDelegatedBatch(int256[] xCoords, int256[] yCoords, bytes3[] colors): Sets colors for multiple delegated pixels.
// 14. addPixelType(string memory name, uint256 claimFee, uint256 colorCooldownSeconds): Admin adds a new pixel type.
// 15. updatePixelType(uint256 typeId, string memory name, uint256 claimFee, uint256 colorCooldownSeconds): Admin updates an existing pixel type.
// 16. setGlobalPixelClaimFee(uint256 fee): Admin sets the default claim fee.
// 17. withdrawFunds(address payable recipient, uint256 amount): Admin withdraws accumulated fees.
// 18. addAdmin(address admin): Owner grants admin rights.
// 19. removeAdmin(address admin): Owner revokes admin rights.
// 20. isAdmin(address account): Checks if an address is an admin.
// 21. getPixelData(int256 x, int256 y): Views all data for a pixel.
// 22. getPixelOwner(int256 x, int256 y): Views the owner of a pixel.
// 23. getPixelColor(int256 x, int256 y): Views the color of a pixel.
// 24. getPixelLastColorTimestamp(int256 x, int256 y): Views the last color timestamp.
// 25. getDelegatedDrawingRight(int256 x, int256 y): Views the delegated drawer address.
// 26. getPixelType(uint256 typeId): Views data for a pixel type.
// 27. getTotalPixelsClaimed(): Views the total count of claimed pixels.
// 28. getTotalPixelTypes(): Views the total count of pixel types.
// 29. getGlobalPixelClaimFee(): Views the global pixel claim fee.
// 30. canPixelBeColored(int256 x, int256 y, address caller): Checks if a specific address can color a pixel now (considering ownership, delegation, and cooldown).
// 31. setPixelMetadataUri(int256 x, int256 y, string memory uri): Allows owner to set metadata URI for a pixel.
// 32. getPixelMetadataUri(int256 x, int256 y): Views metadata URI for a pixel.
// 33. pixelCoordsToTokenId(int256 x, int256 y): Helper to derive a unique token ID from coordinates.
// 34. getTokenURI(int256 x, int256 y): Gets the potential token URI for a pixel.
// 35. setBaseURI(string memory _baseURI): Admin sets the base URI for metadata.
// ... and more potential views/helpers depending on specific needs. (Already have 35+ listed above).

contract InfiniteCanvas is Ownable, ReentrancyGuard {

    struct PixelData {
        address owner;
        bytes3 color; // Stored as 3 bytes (R, G, B)
        uint256 pixelTypeId;
        uint40 lastColorTimestamp; // Using uint40 is sufficient for Unix timestamps, saves gas
        address delegatedDrawer; // Address allowed to set color on behalf of the owner
        string metadataUri; // Optional URI for additional pixel data/art linked off-chain
    }

    struct PixelType {
        string name;
        uint256 claimFee; // Fee in wei to claim a pixel of this type
        uint256 colorCooldownSeconds; // Time in seconds before color can be changed again
    }

    // Mapping from hash of (x, y) coordinates to pixel data
    mapping(bytes32 => PixelData) private pixels;

    // Mapping to track existence, useful for batch operations check
    mapping(bytes32 => bool) private pixelExists;

    // Pixel types
    mapping(uint256 => PixelType) private pixelTypes;
    uint256 public pixelTypeCount; // Starts at 0, first type will be 1

    // Global settings
    uint256 public globalPixelClaimFee;
    uint256 public pixelsClaimedCount;

    // Custom admin roles (besides the Ownable owner)
    mapping(address => bool) private _admins;

    // Base URI for potential token metadata (if pixels were NFTs)
    string public baseURI;

    // Events
    event PixelClaimed(int256 x, int256 y, uint256 pixelTypeId, address indexed owner, uint256 claimFee);
    event PixelColorSet(int256 x, int256 y, bytes3 color, address indexed caller);
    event PixelTransferred(int256 x, int256 y, address indexed oldOwner, address indexed newOwner);
    event DrawingRightsDelegated(int256 x, int256 y, address indexed owner, address indexed delegate);
    event DrawingRightsRevoked(int256 x, int256 y, address indexed owner, address indexed delegate);
    event PixelBurned(int256 x, int256 y, address indexed owner);
    event PixelTypeAdded(uint256 typeId, string name, uint256 claimFee, uint256 colorCooldownSeconds);
    event PixelTypeUpdated(uint256 typeId, string name, uint256 claimFee, uint256 colorCooldownSeconds);
    event GlobalPixelClaimFeeUpdated(uint256 oldFee, uint256 newFee);
    event FundsWithdrawn(address indexed recipient, uint256 amount);
    event AdminAdded(address indexed admin);
    event AdminRemoved(address indexed admin);
    event PixelMetadataUriUpdated(int256 x, int256 y, string uri);
    event BaseURIUpdated(string newBaseURI);

    // Modifiers
    modifier onlyOwnerOrAdmin() {
        require(owner() == msg.sender || _admins[msg.sender], "Only owner or admin");
        _;
    }

    modifier whenPixelExists(int256 x, int256 y) {
        require(pixelExists[coordsToHash(x, y)], "Pixel does not exist");
        _;
    }

    modifier whenPixelNotExists(int256 x, int256 y) {
        require(!pixelExists[coordsToHash(x, y)], "Pixel already exists");
        _;
    }

    // 1. constructor()
    constructor(uint256 _initialGlobalClaimFee) Ownable(msg.sender) {
        globalPixelClaimFee = _initialGlobalClaimFee;
        // Add a default pixel type (type 1)
        _addPixelType("Default Pixel", _initialGlobalClaimFee, 0); // Default has 0 cooldown
    }

    // 2. coordsToHash(int256 x, int256 y)
    // Internal pure function to generate a unique hash for pixel coordinates.
    // Uses abi.encodePacked which is gas efficient for hashing primitive types.
    function coordsToHash(int256 x, int256 y) pure internal returns (bytes32) {
        return keccak256(abi.encodePacked(x, y));
    }

    // 3. claimPixel(int256 x, int256 y, uint256 pixelTypeId)
    // Allows msg.sender to claim a new pixel at (x, y) of a specific type.
    function claimPixel(int256 x, int256 y, uint256 pixelTypeId)
        external
        payable
        nonReentrant
        whenPixelNotExists(x, y)
    {
        require(pixelTypeId > 0 && pixelTypeId <= pixelTypeCount, "Invalid pixel type ID");
        PixelType storage pType = pixelTypes[pixelTypeId];
        uint256 fee = pType.claimFee > 0 ? pType.claimFee : globalPixelClaimFee;
        require(msg.value >= fee, "Insufficient funds to claim pixel");

        bytes32 pixelHash = coordsToHash(x, y);
        pixels[pixelHash] = PixelData({
            owner: msg.sender,
            color: bytes3(0), // Default color (black)
            pixelTypeId: pixelTypeId,
            lastColorTimestamp: 0,
            delegatedDrawer: address(0), // No delegation initially
            metadataUri: ""
        });
        pixelExists[pixelHash] = true;
        pixelsClaimedCount++;

        // Refund any excess ETH
        if (msg.value > fee) {
            payable(msg.sender).transfer(msg.value - fee);
        }

        emit PixelClaimed(x, y, pixelTypeId, msg.sender, fee);
    }

    // 4. setPixelColor(int256 x, int256 y, bytes3 color)
    // Allows the pixel owner to set its color, respecting the cooldown.
    function setPixelColor(int256 x, int256 y, bytes3 color) external whenPixelExists(x, y) {
        bytes32 pixelHash = coordsToHash(x, y);
        PixelData storage pixel = pixels[pixelHash];

        require(pixel.owner == msg.sender, "Not pixel owner");
        require(canColor(pixel), "Color cooldown active");

        pixel.color = color;
        pixel.lastColorTimestamp = uint40(block.timestamp);

        emit PixelColorSet(x, y, color, msg.sender);
    }

    // 5. transferPixelOwnership(int256 x, int256 y, address newOwner)
    // Allows the pixel owner to transfer it to a new address.
    function transferPixelOwnership(int256 x, int256 y, address newOwner) external whenPixelExists(x, y) {
        require(newOwner != address(0), "New owner cannot be zero address");

        bytes32 pixelHash = coordsToHash(x, y);
        PixelData storage pixel = pixels[pixelHash];

        require(pixel.owner == msg.sender, "Not pixel owner");

        address oldOwner = pixel.owner;
        pixel.owner = newOwner;
        pixel.delegatedDrawer = address(0); // Revoke delegation on transfer

        emit PixelTransferred(x, y, oldOwner, newOwner);
    }

    // 6. delegateDrawingRights(int256 x, int256 y, address delegate)
    // Allows the pixel owner to delegate color-setting rights to another address.
    function delegateDrawingRights(int256 x, int256 y, address delegate) external whenPixelExists(x, y) {
         bytes32 pixelHash = coordsToHash(x, y);
         PixelData storage pixel = pixels[pixelHash];

         require(pixel.owner == msg.sender, "Not pixel owner");
         require(delegate != msg.sender, "Cannot delegate to yourself");
         // Allow delegating to address(0) to revoke

         pixel.delegatedDrawer = delegate;

         emit DrawingRightsDelegated(x, y, msg.sender, delegate);
    }

    // 7. revokeDrawingRights(int256 x, int256 y)
    // Allows the pixel owner to revoke any existing delegation.
    function revokeDrawingRights(int256 x, int256 y) external whenPixelExists(x, y) {
        bytes32 pixelHash = coordsToHash(x, y);
        PixelData storage pixel = pixels[pixelHash];

        require(pixel.owner == msg.sender, "Not pixel owner");
        require(pixel.delegatedDrawer != address(0), "No drawing rights delegated");

        address revokedDelegate = pixel.delegatedDrawer;
        pixel.delegatedDrawer = address(0);

        emit DrawingRightsRevoked(x, y, msg.sender, revokedDelegate);
    }

    // 8. setPixelColorDelegated(int256 x, int256 y, bytes3 color)
    // Allows a delegated address to set the pixel color, respecting the cooldown.
    function setPixelColorDelegated(int256 x, int256 y, bytes3 color) external whenPixelExists(x, y) {
        bytes32 pixelHash = coordsToHash(x, y);
        PixelData storage pixel = pixels[pixelHash];

        require(pixel.delegatedDrawer == msg.sender, "Not the delegated drawer");
        require(canColor(pixel), "Color cooldown active");

        pixel.color = color;
        pixel.lastColorTimestamp = uint40(block.timestamp);

        emit PixelColorSet(x, y, color, msg.sender);
    }

    // 9. burnPixel(int256 x, int256 y)
    // Allows the pixel owner to permanently remove/destroy the pixel data.
    function burnPixel(int256 x, int256 y) external whenPixelExists(x, y) {
        bytes32 pixelHash = coordsToHash(x, y);
        PixelData storage pixel = pixels[pixelHash];

        require(pixel.owner == msg.sender, "Not pixel owner");

        address burner = pixel.owner;
        delete pixels[pixelHash];
        pixelExists[pixelHash] = false;
        pixelsClaimedCount--;

        emit PixelBurned(x, y, burner);
    }

    // 10. claimBatchPixels(int256[] xCoords, int256[] yCoords, uint256 pixelTypeId)
    // Claims multiple new pixels in a batch. Requires payment for all.
    function claimBatchPixels(int256[] memory xCoords, int256[] memory yCoords, uint256 pixelTypeId)
        external
        payable
        nonReentrant
    {
        require(xCoords.length == yCoords.length, "Array lengths must match");
        require(xCoords.length > 0, "Arrays cannot be empty");
        require(pixelTypeId > 0 && pixelTypeId <= pixelTypeCount, "Invalid pixel type ID");

        PixelType storage pType = pixelTypes[pixelTypeId];
        uint256 feePerPixel = pType.claimFee > 0 ? pType.claimFee : globalPixelClaimFee;
        uint256 totalFee = feePerPixel * xCoords.length;
        require(msg.value >= totalFee, "Insufficient funds to claim all pixels");

        bytes32 pixelHash;
        for (uint i = 0; i < xCoords.length; i++) {
            pixelHash = coordsToHash(xCoords[i], yCoords[i]);
            require(!pixelExists[pixelHash], "Pixel already exists");

            pixels[pixelHash] = PixelData({
                owner: msg.sender,
                color: bytes3(0),
                pixelTypeId: pixelTypeId,
                lastColorTimestamp: 0,
                delegatedDrawer: address(0),
                metadataUri: ""
            });
            pixelExists[pixelHash] = true;
            pixelsClaimedCount++;

            emit PixelClaimed(xCoords[i], yCoords[i], pixelTypeId, msg.sender, feePerPixel);
        }

        // Refund any excess ETH
        if (msg.value > totalFee) {
            payable(msg.sender).transfer(msg.value - totalFee);
        }
    }

    // 11. setPixelColorBatch(int256[] xCoords, int256[] yCoords, bytes3[] colors)
    // Sets colors for multiple owned pixels in a batch.
    function setPixelColorBatch(int256[] memory xCoords, int256[] memory yCoords, bytes3[] memory colors)
        external
    {
        require(xCoords.length == yCoords.length && xCoords.length == colors.length, "Array lengths must match");
        require(xCoords.length > 0, "Arrays cannot be empty");

        bytes32 pixelHash;
        for (uint i = 0; i < xCoords.length; i++) {
            pixelHash = coordsToHash(xCoords[i], yCoords[i]);
            require(pixelExists[pixelHash], "Pixel does not exist"); // Ensure pixel exists
            PixelData storage pixel = pixels[pixelHash];
            require(pixel.owner == msg.sender, "Not owner of all pixels in batch"); // Ensure owner owns all

            require(canColor(pixel), "Color cooldown active for pixel in batch");

            pixel.color = colors[i];
            pixel.lastColorTimestamp = uint40(block.timestamp);

            emit PixelColorSet(xCoords[i], yCoords[i], colors[i], msg.sender);
        }
    }

    // 12. transferBatchPixels(int256[] xCoords, int256[] yCoords, address newOwner)
    // Transfers multiple owned pixels to one address in a batch.
    function transferBatchPixels(int256[] memory xCoords, int256[] memory yCoords, address newOwner)
        external
    {
        require(xCoords.length == yCoords.length, "Array lengths must match");
        require(xCoords.length > 0, "Arrays cannot be empty");
        require(newOwner != address(0), "New owner cannot be zero address");

        bytes32 pixelHash;
        for (uint i = 0; i < xCoords.length; i++) {
            pixelHash = coordsToHash(xCoords[i], yCoords[i]);
            require(pixelExists[pixelHash], "Pixel does not exist"); // Ensure pixel exists
            PixelData storage pixel = pixels[pixelHash];
            require(pixel.owner == msg.sender, "Not owner of all pixels in batch"); // Ensure owner owns all

            address oldOwner = pixel.owner;
            pixel.owner = newOwner;
            pixel.delegatedDrawer = address(0); // Revoke delegation on transfer

            emit PixelTransferred(xCoords[i], yCoords[i], oldOwner, newOwner);
        }
    }

    // 13. setPixelColorDelegatedBatch(int256[] xCoords, int256[] yCoords, bytes3[] colors)
    // Allows a delegated address to set colors for multiple delegated pixels in a batch.
    function setPixelColorDelegatedBatch(int256[] memory xCoords, int256[] memory yCoords, bytes3[] memory colors)
        external
    {
        require(xCoords.length == yCoords.length && xCoords.length == colors.length, "Array lengths must match");
        require(xCoords.length > 0, "Arrays cannot be empty");

        bytes32 pixelHash;
        for (uint i = 0; i < xCoords.length; i++) {
            pixelHash = coordsToHash(xCoords[i], yCoords[i]);
            require(pixelExists[pixelHash], "Pixel does not exist"); // Ensure pixel exists
            PixelData storage pixel = pixels[pixelHash];
            require(pixel.delegatedDrawer == msg.sender, "Not delegated drawer for all pixels in batch"); // Ensure delegated for all

            require(canColor(pixel), "Color cooldown active for pixel in batch");

            pixel.color = colors[i];
            pixel.lastColorTimestamp = uint40(block.timestamp);

            emit PixelColorSet(xCoords[i], yCoords[i], colors[i], msg.sender);
        }
    }

    // Internal helper to check color cooldown
    function canColor(PixelData storage pixel) internal view returns (bool) {
        if (pixel.pixelTypeId == 0) return false; // Should not happen if typeId is 1-indexed

        PixelType storage pType = pixelTypes[pixel.pixelTypeId];
        return pixel.lastColorTimestamp + pType.colorCooldownSeconds <= block.timestamp;
    }

    // --- Admin Functions ---

    // Internal helper for adding pixel types to manage ID counter
    function _addPixelType(string memory name, uint256 claimFee, uint256 colorCooldownSeconds) internal {
         pixelTypeCount++;
         pixelTypes[pixelTypeCount] = PixelType({
             name: name,
             claimFee: claimFee,
             colorCooldownSeconds: colorCooldownSeconds
         });
         emit PixelTypeAdded(pixelTypeCount, name, claimFee, colorCooldownSeconds);
    }

    // 14. addPixelType(string memory name, uint256 claimFee, uint256 colorCooldownSeconds)
    // Admin adds a new pixel type.
    function addPixelType(string memory name, uint256 claimFee, uint256 colorCooldownSeconds)
        external
        onlyOwnerOrAdmin
    {
        _addPixelType(name, claimFee, colorCooldownSeconds);
    }

    // 15. updatePixelType(uint256 typeId, string memory name, uint256 claimFee, uint256 colorCooldownSeconds)
    // Admin updates an existing pixel type.
    function updatePixelType(uint256 typeId, string memory name, uint256 claimFee, uint256 colorCooldownSeconds)
        external
        onlyOwnerOrAdmin
    {
        require(typeId > 0 && typeId <= pixelTypeCount, "Invalid pixel type ID");
        pixelTypes[typeId] = PixelType({
            name: name,
            claimFee: claimFee,
            colorCooldownSeconds: colorCooldownSeconds
        });
        emit PixelTypeUpdated(typeId, name, claimFee, colorCooldownSeconds);
    }

    // 16. setGlobalPixelClaimFee(uint256 fee)
    // Admin sets the default claim fee for pixels (used if type-specific fee is 0).
    function setGlobalPixelClaimFee(uint256 fee) external onlyOwnerOrAdmin {
        uint256 oldFee = globalPixelClaimFee;
        globalPixelClaimFee = fee;
        emit GlobalPixelClaimFeeUpdated(oldFee, fee);
    }

    // 17. withdrawFunds(address payable recipient, uint256 amount)
    // Admin withdraws accumulated contract funds.
    function withdrawFunds(address payable recipient, uint256 amount) external onlyOwnerOrAdmin nonReentrant {
        require(amount > 0, "Amount must be greater than 0");
        require(address(this).balance >= amount, "Insufficient contract balance");
        recipient.transfer(amount);
        emit FundsWithdrawn(recipient, amount);
    }

    // 18. addAdmin(address admin)
    // Owner grants admin rights to an address.
    function addAdmin(address admin) external onlyOwner {
        require(admin != address(0), "Cannot add zero address as admin");
        require(!_admins[admin], "Address is already an admin");
        _admins[admin] = true;
        emit AdminAdded(admin);
    }

    // 19. removeAdmin(address admin)
    // Owner revokes admin rights from an address.
    function removeAdmin(address admin) external onlyOwner {
        require(admin != address(0), "Cannot remove zero address as admin");
        require(_admins[admin], "Address is not an admin");
        _admins[admin] = false;
        emit AdminRemoved(admin);
    }

    // 20. isAdmin(address account)
    // Checks if an address has admin rights.
    function isAdmin(address account) public view returns (bool) {
        return _admins[account];
    }

    // --- Views ---

    // 21. getPixelData(int256 x, int256 y)
    // Views all data for a pixel. Returns default struct if pixel doesn't exist.
    function getPixelData(int256 x, int256 y) public view returns (PixelData memory) {
        bytes32 pixelHash = coordsToHash(x, y);
        // Return the default zero-initialized struct if the pixel doesn't exist.
        // Callers should check pixelExists[pixelHash] if they need to know if it's a claimed pixel.
        return pixels[pixelHash];
    }

     // 22. getPixelOwner(int256 x, int256 y)
    // Views the owner of a pixel. Returns address(0) if pixel doesn't exist.
    function getPixelOwner(int256 x, int256 y) public view returns (address) {
        bytes32 pixelHash = coordsToHash(x, y);
        return pixels[pixelHash].owner;
    }

    // 23. getPixelColor(int256 x, int256 y)
    // Views the color of a pixel. Returns bytes3(0) if pixel doesn't exist.
    function getPixelColor(int256 x, int256 y) public view returns (bytes3) {
        bytes32 pixelHash = coordsToHash(x, y);
        return pixels[pixelHash].color;
    }

    // 24. getPixelLastColorTimestamp(int256 x, int256 y)
    // Views the last color timestamp. Returns 0 if pixel doesn't exist.
    function getPixelLastColorTimestamp(int256 x, int256 y) public view returns (uint40) {
        bytes32 pixelHash = coordsToHash(x, y);
        return pixels[pixelHash].lastColorTimestamp;
    }

    // 25. getDelegatedDrawingRight(int256 x, int256 y)
    // Views the delegated drawer address. Returns address(0) if none delegated or pixel doesn't exist.
    function getDelegatedDrawingRight(int256 x, int256 y) public view returns (address) {
        bytes32 pixelHash = coordsToHash(x, y);
        return pixels[pixelHash].delegatedDrawer;
    }

     // 26. getPixelType(uint256 typeId)
    // Views data for a pixel type.
    function getPixelType(uint256 typeId) public view returns (PixelType memory) {
        require(typeId > 0 && typeId <= pixelTypeCount, "Invalid pixel type ID");
        return pixelTypes[typeId];
    }

    // 27. getTotalPixelsClaimed()
    // Views the total count of unique pixels ever claimed.
    function getTotalPixelsClaimed() public view returns (uint256) {
        return pixelsClaimedCount;
    }

    // 28. getTotalPixelTypes()
    // Views the total count of pixel types.
    function getTotalPixelTypes() public view returns (uint256) {
        return pixelTypeCount;
    }

    // 29. getGlobalPixelClaimFee()
    // Views the default pixel claim fee.
    function getGlobalPixelClaimFee() public view returns (uint256) {
        return globalPixelClaimFee;
    }

    // 30. canPixelBeColored(int256 x, int256 y, address caller)
    // Checks if a specific address can color a pixel now (considering ownership, delegation, and cooldown).
    function canPixelBeColored(int256 x, int256 y, address caller) public view returns (bool) {
        bytes32 pixelHash = coordsToHash(x, y);
        if (!pixelExists[pixelHash]) {
            return false; // Pixel must exist to be colored
        }
        PixelData storage pixel = pixels[pixelHash];
        bool hasPermission = (pixel.owner == caller || pixel.delegatedDrawer == caller);
        if (!hasPermission) {
            return false; // Caller must be owner or delegated
        }
        return canColor(pixel); // Check cooldown
    }

    // 31. setPixelMetadataUri(int256 x, int256 y, string memory uri)
    // Allows the pixel owner to set a metadata URI for their pixel.
    function setPixelMetadataUri(int256 x, int256 y, string memory uri) external whenPixelExists(x, y) {
        bytes32 pixelHash = coordsToHash(x, y);
        PixelData storage pixel = pixels[pixelHash];
        require(pixel.owner == msg.sender, "Not pixel owner");
        pixel.metadataUri = uri;
        emit PixelMetadataUriUpdated(x, y, uri);
    }

    // 32. getPixelMetadataUri(int256 x, int256 y)
    // Views the metadata URI for a pixel.
    function getPixelMetadataUri(int256 x, int256 y) public view whenPixelExists(x, y) returns (string memory) {
        bytes32 pixelHash = coordsToHash(x, y);
        return pixels[pixelHash].metadataUri;
    }

    // --- Potential NFT / Token Integration ---

    // 33. pixelCoordsToTokenId(int256 x, int256 y)
    // Pure function to deterministically generate a unique uint256 token ID from coordinates.
    // This allows representing pixels as potential NFTs if needed.
    function pixelCoordsToTokenId(int256 x, int256 y) pure public returns (uint256) {
        // This conversion is just one way to map (x, y) to a uint256.
        // It needs to be unique for each (x, y) pair within the practical bounds.
        // A simple approach: combine the raw bytes of x and y and hash, then convert.
        // Ensure int256 values are within a reasonable range for uniqueness/practicality.
        // For true uniqueness across the full int256 range, the hash approach is better.
        // Using the hash of the packed coordinates is a good ID.
        bytes32 hash = coordsToHash(x, y);
        return uint256(hash);
    }

    // Note: tokenIdToPixelCoords would be difficult/impossible on-chain from the hash.
    // This suggests token ID lookup would mainly be one-way (coords -> ID) or rely on an off-chain indexer for ID -> coords lookup.

    // 34. getTokenURI(int256 x, int256 y)
    // Gets the potential token URI for a pixel. Combines baseURI with pixel ID.
    // This function assumes the pixel exists and is claimed.
    function getTokenURI(int256 x, int256 y) public view whenPixelExists(x, y) returns (string memory) {
        // The token ID is derived from coordinates
        uint256 tokenId = pixelCoordsToTokenId(x, y);

        // Combine base URI with the token ID or pixel-specific URI
        string memory pixelSpecificURI = pixels[coordsToHash(x,y)].metadataUri;

        if (bytes(pixelSpecificURI).length > 0) {
            return pixelSpecificURI; // Prioritize pixel-specific URI if set
        }

        if (bytes(baseURI).length == 0) {
             return ""; // No base URI or pixel-specific URI set
        }

        // Simple concatenation of baseURI and tokenId string representation
        // This requires a helper to convert uint256 to string, or rely on the renderer
        // Let's return a placeholder showing the ID structure
        // A common pattern is baseURI + tokenId + ".json"
        // For this example, we'll just show the base URI and the concept.
        // Actual implementation needs uint to string conversion or specific off-chain handling.

        // A more realistic approach often relies on an API gateway at the baseURI/tokenId route
        // Return baseURI or handle string concatenation off-chain / with a library
        // Example: return string(abi.encodePacked(baseURI, Strings.toString(tokenId))); requires OpenZeppelin Strings

        // For simplicity in this example, just return baseURI if set and no pixel-specific URI
        return baseURI;
    }

    // 35. setBaseURI(string memory _baseURI)
    // Admin sets the base URI for potential pixel token metadata.
    function setBaseURI(string memory _baseURI) external onlyOwnerOrAdmin {
        baseURI = _baseURI;
        emit BaseURIUpdated(_baseURI);
    }

    // Fallback to receive ether for claims
    receive() external payable {
        // This fallback function exists only to allow the contract to receive Ether,
        // which is necessary for the `claimPixel` and `claimBatchPixels` functions.
        // No action is taken here other than receiving the Ether.
    }

    // Added check for pixel existence utility function
    function checkPixelExists(int256 x, int256 y) public view returns (bool) {
        return pixelExists[coordsToHash(x, y)];
    }

    // A few more helper views to reach >20 functions and provide more detail
    function getPixelTypeId(int256 x, int256 y) public view whenPixelExists(x, y) returns (uint256) {
        return pixels[coordsToHash(x, y)].pixelTypeId;
    }

    function getPixelClaimFee(int256 x, int256 y) public view whenPixelExists(x, y) returns (uint256) {
         bytes32 pixelHash = coordsToHash(x, y);
         uint256 typeId = pixels[pixelHash].pixelTypeId;
         if (typeId == 0) return 0; // Should not happen for claimed pixels
         PixelType storage pType = pixelTypes[typeId];
         return pType.claimFee > 0 ? pType.claimFee : globalPixelClaimFee;
    }

     function getPixelColorCooldown(int256 x, int256 y) public view whenPixelExists(x, y) returns (uint256) {
         bytes32 pixelHash = coordsToHash(x, y);
         uint256 typeId = pixels[pixelHash].pixelTypeId;
         if (typeId == 0) return 0; // Should not happen for claimed pixels
         PixelType storage pType = pixelTypes[typeId];
         return pType.colorCooldownSeconds;
    }

    function getTimeUntilNextColor(int256 x, int256 y) public view whenPixelExists(x, y) returns (uint256) {
        bytes32 pixelHash = coordsToHash(x, y);
        PixelData storage pixel = pixels[pixelHash];
        uint256 cooldown = getPixelColorCooldown(x, y);
        uint256 nextColorTime = pixel.lastColorTimestamp + cooldown;

        if (block.timestamp >= nextColorTime) {
            return 0; // Cooldown is over
        } else {
            return nextColorTime - block.timestamp;
        }
    }

    // Admin function to force set pixel color (bypass rules)
    function forceSetPixelColor(int256 x, int256 y, bytes3 color) external onlyOwnerOrAdmin whenPixelExists(x, y) {
         bytes32 pixelHash = coordsToHash(x, y);
         PixelData storage pixel = pixels[pixelHash];
         pixel.color = color;
         pixel.lastColorTimestamp = uint40(block.timestamp); // Update timestamp even on force
         emit PixelColorSet(x, y, color, msg.sender); // Use msg.sender (admin)
    }

    // Admin function to force transfer pixel ownership (bypass owner)
    function forceTransferPixelOwnership(int256 x, int256 y, address newOwner) external onlyOwnerOrAdmin whenPixelExists(x, y) {
         bytes32 pixelHash = coordsToHash(x, y);
         PixelData storage pixel = pixels[pixelHash];
         require(newOwner != address(0), "New owner cannot be zero address");

         address oldOwner = pixel.owner;
         pixel.owner = newOwner;
         pixel.delegatedDrawer = address(0); // Revoke delegation on transfer

         emit PixelTransferred(x, y, oldOwner, newOwner); // Emitting with original owner, though admin forced
    }
}
```