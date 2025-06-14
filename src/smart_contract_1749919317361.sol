Okay, here is a Solidity smart contract concept called `InfiniteCanvas`. It's designed around a persistent, shared 2D grid where users can "paint" pixels and claim ownership of regions. It incorporates elements of digital art, property ownership, and NFT-like mechanics, aiming for creative state management and interaction patterns that go beyond standard token or simple contract examples.

It includes:
1.  **Persistent State:** Storing pixel data (color, owner, timestamp) on-chain.
2.  **Dynamic Ownership:** Pixel ownership transfers on paint.
3.  **Region Ownership:** ERC-721-like tokens representing claimed areas of the canvas.
4.  **Spatial Permissions:** Region owners can grant painting rights within their area.
5.  **Configurable Fees:** Dynamic fees for painting and claiming regions.
6.  **Curated Palette:** Contract can restrict allowed colors.
7.  **Basic ERC721 Implementation:** Manual implementation of core ERC-721 logic for regions.

This contract avoids directly inheriting standard OpenZeppelin ERC-721 contracts (though it uses `Ownable` for admin control, which is a common and generally accepted pattern for setting parameters). The core logic for managing tokens (regions) and the canvas state is implemented directly within the contract.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol"; // Using the interface standard
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol"; // For safe transfer checks (optional for this example, but good practice)
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol"; // Using the metadata interface standard

// Outline:
// - State variables for canvas pixels, regions, fees, colors, permissions, and ERC721 data.
// - Ownable pattern for administrative functions.
// - Structs for Pixel and Region data.
// - Mappings for storing pixel data, region data, coordinate-to-region mapping, ERC721 ownership/approvals, colors, and paint permissions.
// - Events for key actions.
// - Constructor to initialize settings.
// - Core Functions: paintPixel, getPixel(s).
// - Region Functions (ERC721-like): claimRegion, getRegion, transferRegion, approveRegion, ownerOfRegion, etc.
// - Permission Functions: grant/revoke/check paint permissions.
// - Configuration Functions: set fees, manage colors, withdraw fees.
// - Utility Functions: check color, get region by coordinates.
// - ERC165 support for interface detection (specifically ERC721 and ERC721Metadata).

// Function Summary:
// - paintPixel(x, y, color): Paint a single pixel on the canvas, requires payment, updates ownership.
// - getPixel(x, y): Retrieve data for a single pixel.
// - getPixels(coords): Retrieve data for multiple pixels efficiently.
// - setPaintFee(fee): Owner function to set the fee for painting a pixel.
// - getPaintFee(): Get the current paint fee.
// - claimRegion(x, y, width, height): Claim ownership of a rectangular region as an NFT (Region token), requires payment per pixel.
// - getRegion(regionId): Retrieve data for a claimed region.
// - setClaimFeePerPixel(fee): Owner function to set the per-pixel fee for claiming a region.
// - getClaimFeePerPixel(): Get the current claim fee per pixel.
// - withdrawFees(recipient): Owner function to withdraw collected fees.
// - addAllowedColor(color): Owner function to add a color to the allowed palette.
// - removeAllowedColor(color): Owner function to remove a color from the allowed palette.
// - isColorAllowed(color): Check if a specific color is currently allowed.
// - grantPaintPermission(user, regionId): Region owner grants painting permission within their region to another user.
// - revokePaintPermission(user, regionId): Region owner revokes painting permission within their region.
// - checkPaintPermission(user, regionId): Check if a user has painting permission for a region.
// - getRegionIdByCoordinates(x, y): Get the ID of the region that contains the given coordinates, if any.
// - setRegionName(regionId, name): Region owner sets a name for their region.
// - setRegionMetadataURI(regionId, uri): Region owner sets an off-chain metadata URI for their region NFT.
// - setBaseMetadataURIRegion(uri): Owner function to set a base URI for region metadata (fallback).
// - ownerOfRegion(regionId): ERC721: Get the owner of a region token.
// - balanceOfRegions(owner): ERC721: Get the number of region tokens owned by an address.
// - transferFromRegion(from, to, regionId): ERC721: Transfer a region token (internal, use safeTransferFromRegion).
// - safeTransferFromRegion(from, to, regionId): ERC721: Safely transfer a region token.
// - approveRegion(to, regionId): ERC721: Approve another address to transfer a specific region token.
// - getApprovedRegion(regionId): ERC721: Get the approved address for a region token.
// - setApprovalForAllRegions(operator, approved): ERC721: Approve or disapprove an operator for all region tokens.
// - isApprovedForAllRegions(owner, operator): ERC721: Check if an operator is approved for all region tokens by an owner.
// - getTokenURIRegion(regionId): ERC721Metadata: Get the metadata URI for a region token.
// - supportsInterface(interfaceId): ERC165: Indicate support for ERC721 and ERC721Metadata interfaces.

contract InfiniteCanvas is Ownable, IERC721, IERC721Metadata {
    using Math for uint256;

    struct Pixel {
        address owner; // Address that last painted the pixel
        uint24 color;  // RGB color (e.g., 0xFF0000 for red)
        uint64 timestamp; // Timestamp of last paint action
    }

    struct Region {
        uint256 id;
        int256 x;
        int256 y;
        uint256 width;
        uint256 height;
        address owner; // Current owner address (redundant with regionOwners mapping, but useful for struct)
        string name;
        string metadataURI;
    }

    // --- State Variables ---

    // Canvas state: map (x, y) coordinates to Pixel data.
    // Using a nested mapping allows for sparse storage of an "infinite" canvas.
    mapping(int256 => mapping(int256 => Pixel)) private pixels;

    // Region state: map region ID to Region data.
    mapping(uint256 => Region) private regions;
    uint256 private nextRegionId = 1; // Start region IDs from 1

    // Map pixel coordinates to the ID of the region they belong to (0 if none).
    mapping(int256 => mapping(int256 => uint256)) private pixelToRegionId;

    // ERC721 state for Regions
    mapping(uint256 => address) private regionOwners; // Region ID => Owner Address
    mapping(address => uint256) private regionBalances; // Owner Address => Count of Regions owned
    mapping(uint256 => address) private regionTokenApprovals; // Region ID => Approved Address
    mapping(address => mapping(address => bool)) private regionOperatorApprovals; // Owner Address => Operator Address => Is ApprovedForAll

    // Configuration
    uint256 private paintFee = 0.0001 ether; // Default fee to paint a pixel
    uint256 private claimFeePerPixel = 0.001 ether; // Default fee per pixel to claim a region
    uint256 private totalFeesCollected;

    // Allowed colors (basic palette management)
    mapping(uint24 => bool) private allowedColors;

    // Per-region paint permissions: regionId => userAddress => hasPermission
    mapping(uint256 => mapping(address => bool)) private regionPaintPermissions;

    string private baseMetadataURIRegion;

    // --- Events ---

    event PixelPainted(int256 x, int256 y, uint24 color, address indexed owner, uint64 timestamp);
    event RegionClaimed(uint256 indexed regionId, address indexed owner, int256 x, int256 y, uint256 width, uint256 height);
    event PaintPermissionGranted(uint256 indexed regionId, address indexed granter, address indexed user);
    event PaintPermissionRevoked(uint256 indexed regionId, address indexed granter, address indexed user);
    event FeesWithdrawn(address indexed recipient, uint256 amount);
    event ColorAdded(uint24 color);
    event ColorRemoved(uint24 color);
    event PaintFeeUpdated(uint256 oldFee, uint256 newFee);
    event ClaimFeeUpdated(uint256 oldFee, uint256 newFee);
    event RegionNameUpdated(uint256 indexed regionId, string name);
    event RegionMetadataURIUpdated(uint256 indexed regionId, string uri);

    // ERC721 Events (standard)
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    // --- Constructor ---

    constructor(address initialOwner) Ownable(initialOwner) {
        // Add some initial allowed colors (e.g., basic RGB and grayscale)
        allowedColors[0x000000] = true; // Black
        allowedColors[0xFFFFFF] = true; // White
        allowedColors[0xFF0000] = true; // Red
        allowedColors[0x00FF00] = true; // Green
        allowedColors[0x0000FF] = true; // Blue
        allowedColors[0x808080] = true; // Gray
        // You can add more colors here
    }

    // --- Core Canvas Functions ---

    /// @notice Paints a single pixel on the canvas. Requires `paintFee`.
    /// @param x The x-coordinate of the pixel.
    /// @param y The y-coordinate of the pixel.
    /// @param color The RGB color (uint24) to paint.
    function paintPixel(int256 x, int256 y, uint24 color) public payable {
        require(msg.value >= paintFee, "InfiniteCanvas: Insufficient paint fee");
        require(allowedColors[color], "InfiniteCanvas: Color not allowed");

        uint256 regionId = pixelToRegionId[x][y];
        if (regionId != 0) {
            // Pixel is part of a region
            address regionOwner = regionOwners[regionId];
            // Check if the sender is the region owner OR has paint permission OR is approved for all by the region owner
            bool hasPermission = (msg.sender == regionOwner) ||
                                 regionPaintPermissions[regionId][msg.sender] ||
                                 isApprovedForAllRegions(regionOwner, msg.sender);

            require(hasPermission, "InfiniteCanvas: No paint permission for this region");
        }

        Pixel storage pixel = pixels[x][y];
        pixel.owner = msg.sender;
        pixel.color = color;
        pixel.timestamp = uint64(block.timestamp);

        totalFeesCollected += msg.value;

        emit PixelPainted(x, y, color, msg.sender, pixel.timestamp);
    }

    /// @notice Retrieves the data for a single pixel.
    /// @param x The x-coordinate of the pixel.
    /// @param y The y-coordinate of the pixel.
    /// @return pixelData The Pixel struct data (owner, color, timestamp). Returns default values if pixel hasn't been painted.
    function getPixel(int256 x, int256 y) public view returns (Pixel memory pixelData) {
        return pixels[x][y];
    }

     /// @notice Retrieves the owner of a single pixel.
    /// @param x The x-coordinate of the pixel.
    /// @param y The y-coordinate of the pixel.
    /// @return owner The address that last painted the pixel.
    function getPixelOwner(int256 x, int256 y) public view returns (address owner) {
        return pixels[x][y].owner;
    }

    /// @notice Retrieves the color of a single pixel.
    /// @param x The x-coordinate of the pixel.
    /// @param y The y-coordinate of the pixel.
    /// @return color The color (uint24) of the pixel.
    function getPixelColor(int256 x, int256 y) public view returns (uint24 color) {
        return pixels[x][y].color;
    }

     /// @notice Retrieves the timestamp of the last paint action for a single pixel.
    /// @param x The x-coordinate of the pixel.
    /// @param y The y-coordinate of the pixel.
    /// @return timestamp The timestamp (uint64) of the last paint.
    function getPixelTimestamp(int256 x, int256 y) public view returns (uint64 timestamp) {
        return pixels[x][y].timestamp;
    }


    /// @notice Retrieves data for multiple pixels in one call.
    /// @param coords An array of [x, y] coordinate pairs.
    /// @return pixelData An array of Pixel structs corresponding to the input coordinates.
    function getPixels(int256[] calldata coords) public view returns (Pixel[] memory pixelData) {
        require(coords.length % 2 == 0, "InfiniteCanvas: Coordinates array must have even length");
        pixelData = new Pixel[](coords.length / 2);
        for (uint i = 0; i < coords.length; i += 2) {
            pixelData[i/2] = pixels[coords[i]][coords[i+1]];
        }
        return pixelData;
    }

    // --- Configuration Functions (Owner Only) ---

    /// @notice Sets the fee required to paint a single pixel. Only callable by the contract owner.
    /// @param fee The new paint fee in wei.
    function setPaintFee(uint256 fee) public onlyOwner {
        require(fee != paintFee, "InfiniteCanvas: New paint fee is same as current");
        emit PaintFeeUpdated(paintFee, fee);
        paintFee = fee;
    }

    /// @notice Gets the current fee required to paint a single pixel.
    /// @return The current paint fee in wei.
    function getPaintFee() public view returns (uint256) {
        return paintFee;
    }

    /// @notice Sets the fee required per pixel to claim a region. Only callable by the contract owner.
    /// @param fee The new claim fee per pixel in wei.
    function setClaimFeePerPixel(uint256 fee) public onlyOwner {
        require(fee != claimFeePerPixel, "InfiniteCanvas: New claim fee is same as current");
         emit ClaimFeeUpdated(claimFeePerPixel, fee);
        claimFeePerPixel = fee;
    }

    /// @notice Gets the current fee required per pixel to claim a region.
    /// @return The current claim fee per pixel in wei.
    function getClaimFeePerPixel() public view returns (uint256) {
        return claimFeePerPixel;
    }

    /// @notice Allows the contract owner to withdraw collected fees.
    /// @param recipient The address to send the fees to.
    function withdrawFees(address payable recipient) public onlyOwner {
        uint256 amount = totalFeesCollected;
        require(amount > 0, "InfiniteCanvas: No fees collected to withdraw");
        totalFeesCollected = 0;
        (bool success, ) = recipient.call{value: amount}("");
        require(success, "InfiniteCanvas: Fee withdrawal failed");
        emit FeesWithdrawn(recipient, amount);
    }

    /// @notice Adds a color to the list of allowed colors for painting. Only callable by the contract owner.
    /// @param color The uint24 RGB color to allow.
    function addAllowedColor(uint24 color) public onlyOwner {
        require(!allowedColors[color], "InfiniteCanvas: Color is already allowed");
        allowedColors[color] = true;
        emit ColorAdded(color);
    }

    /// @notice Removes a color from the list of allowed colors for painting. Only callable by the contract owner.
    /// @param color The uint24 RGB color to disallow.
    function removeAllowedColor(uint24 color) public onlyOwner {
        require(allowedColors[color], "InfiniteCanvas: Color is not allowed");
        allowedColors[color] = false;
        emit ColorRemoved(color);
    }

    /// @notice Checks if a specific color is currently allowed for painting.
    /// @param color The uint24 RGB color to check.
    /// @return True if the color is allowed, false otherwise.
    function isColorAllowed(uint24 color) public view returns (bool) {
        return allowedColors[color];
    }

     /// @notice Sets the base URI for region NFT metadata. Only callable by the contract owner.
    /// @param uri The base URI string.
    function setBaseMetadataURIRegion(string memory uri) public onlyOwner {
        baseMetadataURIRegion = uri;
    }

    // --- Region Functions (ERC721-like) ---

    /// @notice Claims a rectangular region of the canvas as an NFT (Region token). Requires payment.
    /// @param x The x-coordinate of the top-left corner of the region.
    /// @param y The y-coordinate of the top-left corner of the region.
    /// @param width The width of the region (must be > 0).
    /// @param height The height of the region (must be > 0).
    /// @return The ID of the newly claimed region token.
    function claimRegion(int256 x, int256 y, uint256 width, uint256 height) public payable returns (uint256) {
        require(width > 0 && height > 0, "InfiniteCanvas: Region dimensions must be positive");
        uint256 numberOfPixels = width.mul(height);
        uint256 requiredFee = numberOfPixels.mul(claimFeePerPixel);
        require(msg.value >= requiredFee, "InfiniteCanvas: Insufficient claim fee");

        // Check if any pixel in the proposed region is already part of another region
        for (int256 i = 0; i < int256(width); i++) {
            for (int256 j = 0; j < int256(height); j++) {
                 // Using int256 coordinates for mapping
                if (pixelToRegionId[x + i][y + j] != 0) {
                    revert("InfiniteCanvas: Region overlaps with an existing claimed region");
                }
            }
        }

        uint256 regionId = nextRegionId++;
        address regionOwner = msg.sender;

        regions[regionId] = Region({
            id: regionId,
            x: x,
            y: y,
            width: width,
            height: height,
            owner: regionOwner, // Store owner in struct for convenience
            name: "", // Default empty name
            metadataURI: "" // Default empty URI
        });

        // Update pixel-to-region mapping for all pixels in the region
        for (int256 i = 0; i < int256(width); i++) {
            for (int256 j = 0; j < int256(height); j++) {
                 pixelToRegionId[x + i][y + j] = regionId;
            }
        }

        // Update ERC721 ownership state
        _mintRegion(regionOwner, regionId);

        totalFeesCollected += msg.value;

        emit RegionClaimed(regionId, regionOwner, x, y, width, height);
        return regionId;
    }

    /// @notice Retrieves the data for a claimed region.
    /// @param regionId The ID of the region token.
    /// @return regionData The Region struct data. Returns default values if region ID does not exist.
    function getRegion(uint256 regionId) public view returns (Region memory regionData) {
        require(_existsRegion(regionId), "InfiniteCanvas: Region does not exist");
        return regions[regionId];
    }

    /// @notice Gets the region ID associated with a specific pixel coordinate.
    /// @param x The x-coordinate of the pixel.
    /// @param y The y-coordinate of the pixel.
    /// @return The region ID (0 if the pixel is not part of any claimed region).
    function getRegionIdByCoordinates(int256 x, int256 y) public view returns (uint256) {
        return pixelToRegionId[x][y];
    }

    /// @notice Allows the region owner to set a name for their region.
    /// @param regionId The ID of the region token.
    /// @param name The name to set.
    function setRegionName(uint256 regionId, string memory name) public {
        require(_existsRegion(regionId), "InfiniteCanvas: Region does not exist");
        require(regionOwners[regionId] == msg.sender, "InfiniteCanvas: Sender is not the region owner");
        regions[regionId].name = name;
        emit RegionNameUpdated(regionId, name);
    }

    /// @notice Allows the region owner to set an off-chain metadata URI for their region NFT.
    /// @param regionId The ID of the region token.
    /// @param uri The URI to set.
    function setRegionMetadataURI(uint256 regionId, string memory uri) public {
        require(_existsRegion(regionId), "InfiniteCanvas: Region does not exist");
        require(regionOwners[regionId] == msg.sender, "InfiniteCanvas: Sender is not the region owner");
        regions[regionId].metadataURI = uri;
        emit RegionMetadataURIUpdated(regionId, uri);
    }


    // --- Permission Functions ---

    /// @notice Grants painting permission for a specific region to a user. Only callable by the region owner.
    /// Permission allows painting within the region even if the user doesn't own it.
    /// @param user The address to grant permission to.
    /// @param regionId The ID of the region token.
    function grantPaintPermission(address user, uint256 regionId) public {
        require(_existsRegion(regionId), "InfiniteCanvas: Region does not exist");
        require(regionOwners[regionId] == msg.sender, "InfiniteCanvas: Sender is not the region owner");
        require(user != address(0), "InfiniteCanvas: Cannot grant permission to the zero address");
        require(user != msg.sender, "InfiniteCanvas: Cannot grant permission to self");

        regionPaintPermissions[regionId][user] = true;
        emit PaintPermissionGranted(regionId, msg.sender, user);
    }

    /// @notice Revokes painting permission for a specific region from a user. Only callable by the region owner.
    /// @param user The address to revoke permission from.
    /// @param regionId The ID of the region token.
    function revokePaintPermission(address user, uint256 regionId) public {
        require(_existsRegion(regionId), "InfiniteCanvas: Region does not exist");
        require(regionOwners[regionId] == msg.sender, "InfiniteCanvas: Sender is not the region owner");
        require(user != address(0), "InfiniteCanvas: Cannot revoke permission from the zero address");

        regionPaintPermissions[regionId][user] = false;
        emit PaintPermissionRevoked(regionId, msg.sender, user);
    }

    /// @notice Checks if a user has explicit painting permission for a specific region.
    /// Note: This doesn't check for region ownership or ApprovedForAll status.
    /// @param user The address to check permission for.
    /// @param regionId The ID of the region token.
    /// @return True if the user has explicit paint permission for the region, false otherwise.
    function checkPaintPermission(address user, uint256 regionId) public view returns (bool) {
        require(_existsRegion(regionId), "InfiniteCanvas: Region does not exist");
        return regionPaintPermissions[regionId][user];
    }

    // --- Basic ERC721 Implementation for Regions ---
    // Implemented manually to avoid direct inheritance of OpenZeppelin standard contracts,
    // while still adhering to the ERC721 and ERC721Metadata interfaces.

    /// @inheritdoc IERC721
    function ownerOf(uint256 regionId) public view override returns (address) {
        address owner = regionOwners[regionId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }

    /// @inheritdoc IERC721
    function balanceOf(address owner) public view override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return regionBalances[owner];
    }

    /// @inheritdoc IERC721
    function transferFrom(address from, address to, uint256 regionId) public override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwnerRegion(msg.sender, regionId), "ERC721: transfer caller is not owner nor approved");
        _transferRegion(from, to, regionId);
    }

    /// @inheritdoc IERC721
    function safeTransferFrom(address from, address to, uint256 regionId) public override {
        safeTransferFrom(from, to, regionId, "");
    }

    /// @inheritdoc IERC721
    function safeTransferFrom(address from, address to, uint256 regionId, bytes memory data) public override {
        require(_isApprovedOrOwnerRegion(msg.sender, regionId), "ERC721: transfer caller is not owner nor approved");
        _safeTransferRegion(from, to, regionId, data);
    }

    /// @inheritdoc IERC721
    function approve(address to, uint256 regionId) public override {
        address owner = regionOwners[regionId];
        require(msg.sender == owner || isApprovedForAllRegions(owner, msg.sender), "ERC721: approve caller is not owner nor approved for all");
        _approveRegion(to, regionId);
    }

    /// @inheritdoc IERC721
    function getApproved(uint255 regionId) public view override returns (address) {
         require(_existsRegion(regionId), "ERC721: approved query for nonexistent token");
         return regionTokenApprovals[regionId];
    }

    /// @inheritdoc IERC721
    function setApprovalForAll(address operator, bool approved) public override {
        _setApprovalForAllRegions(msg.sender, operator, approved);
    }

     /// @inheritdoc IERC721
    function isApprovedForAll(address owner, address operator) public view override returns (bool) {
        return isApprovedForAllRegions(owner, operator);
    }

    /// @notice Helper function to check if an operator is approved for all regions by an owner.
    function isApprovedForAllRegions(address owner, address operator) public view returns (bool) {
         return regionOperatorApprovals[owner][operator];
    }

    /// @inheritdoc IERC721Metadata
    function tokenURI(uint256 regionId) public view override returns (string memory) {
        require(_existsRegion(regionId), "ERC721Metadata: URI query for nonexistent token");
        string memory customURI = regions[regionId].metadataURI;
        if (bytes(customURI).length > 0) {
            return customURI;
        }
        // Fallback to base URI + token ID
        // Note: This is a simplified example. Proper URI construction might need more logic.
        if (bytes(baseMetadataURIRegion).length == 0) {
             return ""; // No metadata if base URI not set
        }
         // Basic URI construction: baseURI + regionId
        return string(abi.encodePacked(baseMetadataURIRegion, regionId.toString()));
    }

    /// @notice Internal function to mint a new region token.
    /// @dev Assumes checks for existence and permissions are done by caller.
    function _mintRegion(address to, uint256 regionId) internal {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_existsRegion(regionId), "ERC721: token already minted");

        regionOwners[regionId] = to;
        regionBalances[to]++;

        emit Transfer(address(0), to, regionId);
    }

    /// @notice Internal function to transfer a region token.
    /// @dev Assumes checks for ownership and permissions are done by caller.
    function _transferRegion(address from, address to, uint256 regionId) internal {
        require(regionOwners[regionId] == from, "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, regionId);

        // Clear approvals
        _approveRegion(address(0), regionId);

        // Update ownership
        regionBalances[from]--;
        regionOwners[regionId] = to;
        regionBalances[to]++;

        // Update owner in the Region struct itself
        regions[regionId].owner = to;

        _afterTokenTransfer(from, to, regionId);

        emit Transfer(from, to, regionId);
    }

    /// @notice Internal function to safely transfer a region token, checking receiver support.
    function _safeTransferRegion(address from, address to, uint256 regionId, bytes memory data) internal {
        _transferRegion(from, to, regionId);
        require(_checkOnERC721Received(from, to, regionId, data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /// @notice Internal function to approve an address for a specific region token.
    function _approveRegion(address to, uint256 regionId) internal {
         regionTokenApprovals[regionId] = to;
         emit Approval(regionOwners[regionId], to, regionId);
    }

    /// @notice Internal function to set approval for an operator for all tokens of an owner.
    function _setApprovalForAllRegions(address owner, address operator, bool approved) internal {
        require(owner != operator, "ERC721: approve to caller");
        regionOperatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /// @notice Internal helper to check if a region token exists.
    function _existsRegion(uint256 regionId) internal view returns (bool) {
        return regionOwners[regionId] != address(0);
    }

    /// @notice Internal helper to check if an address is the owner of a region or approved for it.
    function _isApprovedOrOwnerRegion(address spender, uint256 regionId) internal view returns (bool) {
        address owner = regionOwners[regionId];
        // Check if region exists and spender is not the zero address
        return (owner != address(0) && spender != address(0) && (spender == owner || getApprovedRegion(regionId) == spender || isApprovedForAllRegions(owner, spender)));
    }

    /// @notice Internal helper to check if the receiver address is a smart contract that implements IERC721Receiver.
    function _checkOnERC721Received(address from, address to, uint256 regionId, bytes memory data) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(msg.sender, from, regionId, data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    /// @solidity exclusive
                    revert(string(reason));
                }
            }
        } else {
            return true; // EOA can always receive tokens
        }
    }

     /// @notice Internal hook that is called before any token transfer, including minting and burning.
     /// @param from The sender address (address(0) for minting).
     /// @param to The recipient address (address(0) for burning).
     /// @param tokenId The ID of the token being transferred.
    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual {}

     /// @notice Internal hook that is called after any token transfer, including minting and burning.
     /// @param from The sender address (address(0) for minting).
     /// @param to The recipient address (address(0) for burning).
     /// @param tokenId The ID of the token being transferred.
    function _afterTokenTransfer(address from, address to, uint256 tokenId) internal virtual {}


    // --- ERC165 Support ---

    /// @inheritdoc ERC165
    function supportsInterface(bytes4 interfaceId) public view override returns (bool) {
        return interfaceId == type(IERC721).interfaceId ||
               interfaceId == type(IERC721Metadata).interfaceId ||
               super.supportsInterface(interfaceId); // Support Ownable interface if imported from OZ
    }
}

library ToString {
    /// @notice Converts a uint256 to a string.
    function toString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }
}
```