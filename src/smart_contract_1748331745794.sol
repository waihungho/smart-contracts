Okay, here is a Solidity smart contract concept for a "CryptoArtCanvas". This contract focuses on creating a shared digital canvas where users can contribute pixels, the resulting artwork is represented as a dynamic NFT, which can then be fractionalized. It includes features for dynamic styling and a basic community voting mechanism for styles.

This contract attempts to combine several trending and advanced concepts:
1.  **Collaborative/Generative Art:** Users contribute to a single piece.
2.  **Dynamic NFTs:** The NFT's appearance (via metadata) changes based on the on-chain state (pixels, applied style).
3.  **Fractionalization:** The high-value NFT can be split into ERC-20 shares.
4.  **Community Governance:** Users can vote on how the canvas is displayed (styling).
5.  **On-chain State Management:** Storing and updating canvas pixel data on-chain.
6.  **Royalty Distribution:** Mechanism for contributors to potentially claim shares from future sales/royalties (simplified model).
7.  **Advanced Geometry/Math:** A gradient filling function.

**Disclaimer:** This contract is a conceptual example and is complex. Deploying and managing such a system on a live blockchain like Ethereum Mainnet would require significant gas optimization, robust error handling, off-chain infrastructure (for rendering the dynamic NFT metadata/image), and thorough security audits. The fractionalization mechanism shown is simplified.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/Math.sol"; // For min/max

// --- Outline ---
// 1. Imports & Errors
// 2. Structs & Enums
// 3. State Variables
// 4. Events
// 5. Modifiers
// 6. Constructor & Initialization
// 7. Admin Functions
// 8. Canvas Interaction (Painting/Erasing)
// 9. Gradient Function (Advanced)
// 10. Viewing Canvas State
// 11. NFT Standard Functions (ERC721)
// 12. NFT Lifecycle
// 13. Fractionalization Functions
// 14. Dynamic Styling & Voting Functions
// 15. Royalty Distribution Functions
// 16. Canvas Status Functions

// --- Function Summary ---
// --- Admin Functions ---
// 1. initializeCanvas(uint256 _width, uint256 _height, uint256 _pixelPrice): Sets up canvas dimensions and initial pixel price (only once).
// 2. setPixelPrice(uint256 _newPrice): Updates the price per pixel.
// 3. withdrawFunds(address payable _recipient, uint256 _amount): Allows owner to withdraw contract balance.
// 4. pauseCanvas(): Pauses pixel painting functions.
// 5. unpauseCanvas(): Unpauses pixel painting functions.
// 6. setBaseURI(string memory _newBaseURI): Sets the base URI for NFT metadata.
// 7. setCanvasStatus(CanvasStatus _status): Sets the overall status of the canvas lifecycle.
// 8. setFractionalToken(address _fractionalToken): Sets the address of the ERC20 token used for fractionalization.
// 9. allowPublicVoting(bool _enabled): Toggles whether public can vote on styles.

// --- Canvas Interaction (Painting/Erasing) ---
// 10. addPixel(uint256 x, uint256 y, bytes3 colorData): Paints a single pixel.
// 11. addPixels(uint256[] calldata xCoords, uint256[] calldata yCoords, bytes3[] calldata colorData): Paints multiple pixels in a batch.
// 12. fillArea(uint256 x1, uint256 y1, uint256 x2, uint256 y2, bytes3 colorData): Fills a rectangular area with a single color.
// 13. addColorGradient(uint256 x1, uint256 y1, uint256 x2, uint256 y2, bytes3 color1, bytes3 color2): Fills a rectangular area with a linear color gradient (advanced).
// 14. erasePixel(uint256 x, uint256 y): Erases a pixel (sets to default blank color).

// --- Viewing Canvas State ---
// 15. getPixelInfo(uint256 x, uint256 y): Gets color, contributor, and timestamp for a pixel.
// 16. getTotalPixelsPainted(): Gets the total number of non-blank pixels.
// 17. getPixelCountByContributor(address _contributor): Gets the number of pixels painted by a specific address.
// 18. getCanvasDimensions(): Gets the width and height of the canvas.
// 19. getCanvasStatus(): Gets the current status of the canvas.

// --- NFT Standard Functions (ERC721) ---
// 20. tokenURI(uint256 tokenId): Returns the metadata URI for the canvas NFT (ERC721 standard).
// 21. supportsInterface(bytes4 interfaceId): Checks if the contract supports an ERC interface (ERC721 standard).

// --- NFT Lifecycle ---
// 22. mintCanvasNFT(): Mints the single canvas NFT (callable by owner after init).
// 23. getTokenId(): Gets the ID of the canvas NFT.

// --- Fractionalization Functions ---
// 24. splitCanvasNFT(): Splits the owned canvas NFT into fractional ERC20 tokens. Requires fractionalToken address to be set and NFT to be owned by contract.
// 25. redeemCanvasNFT(uint256 amount): Allows burning fractional tokens to potentially redeem the original NFT (simplified logic: burns tokens, requires burning TOTAL_SUPPLY to pull NFT out).
// 26. getFractionalToken(): Gets the address of the fractional ERC20 token contract.

// --- Dynamic Styling & Voting Functions ---
// 27. applyStyleFilter(uint256 _styleId): Owner or via vote result applies a visual style filter ID (influences off-chain rendering).
// 28. getAppliedStyle(): Gets the currently applied style ID.
// 29. proposeStyle(uint256 _styleId, bytes32 _descriptionHash): Allows eligible users to propose a new style ID for voting.
// 30. voteForStyle(uint256 _styleId): Allows eligible users to vote for a proposed style.
// 31. finalizeStyleVote(uint256 _styleId): Owner can finalize the vote for a specific style if certain conditions (e.g., time elapsed, threshold met off-chain) are met, applying the style.
// 32. getVoteCountForStyle(uint256 _styleId): Gets the current vote count for a proposed style.
// 33. getProposedStyles(): Gets the list of proposed style IDs.

// --- Royalty Distribution Functions ---
// 34. claimRoyalties(): Allows a contributor to claim their share of accumulated royalties.
// 35. getContributorWeight(address _contributor): Calculates a contributor's weight (e.g., based on pixel count) for royalty distribution.

contract CryptoArtCanvas is ERC721, Ownable, ReentrancyGuard {

    // --- 1. Imports & Errors ---
    error CanvasNotInitialized();
    error CanvasAlreadyInitialized();
    error InvalidCoordinates(uint256 x, uint256 y);
    error CanvasPaused();
    error InsufficientPayment(uint256 required, uint256 provided);
    error ArrayLengthMismatch();
    error InvalidArea(uint256 x1, uint256 y1, uint256 x2, uint256 y2);
    error NFTAlreadyMinted();
    error NFTNotMinted();
    error NFTSplit();
    error NFTNotSplit();
    error FractionalTokenNotSet();
    error NotEnoughFractionalTokens();
    error StyleNotProposed();
    error VotingNotEnabled();
    error AlreadyVoted(uint256 styleId);
    error NoRoyaltiesToClaim();

    // --- 2. Structs & Enums ---
    struct Pixel {
        bytes3 color; // RGB color data (e.g., 0xFF0000 for red)
        address contributor;
        uint64 timestamp;
    }

    struct ProposedStyle {
        bytes32 descriptionHash; // Hash referencing off-chain details about the style
        uint64 proposalTimestamp;
        uint256 votes;
    }

    enum CanvasStatus {
        Uninitialized,
        PaintingOpen,
        PaintingPaused,
        MintingReady,
        NFTSplit,
        VotingOpen,
        Completed // Final state, no more changes allowed
    }

    // --- 3. State Variables ---
    uint256 public canvasWidth;
    uint256 public canvasHeight;
    uint256 public pixelPrice;
    bool public initialized;
    bool public paused;
    uint256 public totalPixelsPainted; // Count of non-default pixels
    string public baseTokenURI; // Base URI for the dynamic NFT metadata
    uint256 public constant CANVAS_TOKEN_ID = 1; // Assuming only one main canvas NFT

    // Canvas data: mapping from combined index (y * width + x) to Pixel struct
    mapping(uint256 => Pixel) public canvasPixels;

    // Track pixel count per contributor for royalty calculation
    mapping(address => uint256) public contributorPixelCount;

    // Accumulated funds for royalties (simplified model)
    mapping(address => uint256) public unclaimedRoyalties;

    // Fractionalization
    IERC20 public fractionalToken; // Address of the ERC20 token for fractional ownership
    bool public nftSplit; // True if the canvas NFT has been split into fractional tokens

    // Dynamic Styling
    uint256 public currentStyleId; // ID of the currently applied visual style (influences off-chain rendering)
    mapping(uint256 => ProposedStyle) public proposedStyles; // Styles proposed for voting
    uint256[] public proposedStyleIds; // List of proposed style IDs
    mapping(address => mapping(uint256 => bool)) public hasVotedForStyle; // Track user votes per style
    bool public votingEnabled; // Flag to enable/disable public voting

    CanvasStatus public canvasStatus;

    // --- 4. Events ---
    event CanvasInitialized(uint256 width, uint256 height, uint256 pixelPrice);
    event PixelPainted(uint256 x, uint256 y, bytes3 color, address contributor, uint256 timestamp);
    event PixelsPainted(uint256 count, address contributor, uint256 timestamp);
    event AreaFilled(uint256 x1, uint256 y1, uint256 x2, uint256 y2, address contributor, uint256 timestamp);
    event ColorGradientAdded(uint256 x1, uint256 y1, uint256 x2, uint256 y2, bytes3 color1, bytes3 color2, address contributor, uint256 timestamp);
    event PixelErased(uint256 x, uint256 y, address contributor, uint256 timestamp);
    event CanvasPaused();
    event CanvasUnpaused();
    event CanvasNFTMinted(uint256 tokenId);
    event CanvasNFTSplit(uint256 tokenId, address fractionalToken);
    event CanvasNFTRedeemed(uint256 tokenId, address fractionalToken);
    event StyleProposed(uint256 styleId, bytes32 descriptionHash, address proposer);
    event StyleVoted(uint256 styleId, address voter);
    event StyleApplied(uint256 styleId, address applicator);
    event RoyaltiesClaimed(address contributor, uint256 amount);
    event CanvasStatusChanged(CanvasStatus newStatus);

    // --- 5. Modifiers ---
    modifier canvasInitialized() {
        if (!initialized) revert CanvasNotInitialized();
        _;
    }

    modifier canvasNotInitialized() {
        if (initialized) revert CanvasAlreadyInitialized();
        _;
    }

    modifier whenNotPaused() {
        if (paused) revert CanvasPaused();
        _;
    }

    modifier whenPaused() {
        if (!paused) revert CanvasPaused();
        _;
    }

    modifier canvasIs(CanvasStatus status) {
        if (canvasStatus != status) revert CanvasStatusChanged(status); // Revert with expected status
        _;
    }

    modifier nftMinted() {
        if (ownerOf(CANVAS_TOKEN_ID) == address(0)) revert NFTNotMinted();
        _;
    }

    modifier nftNotSplit() {
        if (nftSplit) revert NFTSplit();
        _;
    }

    modifier nftIsSplit() {
        if (!nftSplit) revert NFTNotSplit();
        _;
    }

    // --- 6. Constructor & Initialization ---
    constructor(string memory name, string memory symbol) ERC721(name, symbol) Ownable(msg.sender) {
        initialized = false;
        paused = false;
        totalPixelsPainted = 0;
        canvasStatus = CanvasStatus.Uninitialized;
        nftSplit = false;
        votingEnabled = false;
        currentStyleId = 0; // Default style ID (e.g., raw pixels)
    }

    /// @notice Sets up the canvas dimensions and initial pixel price. Can only be called once.
    /// @param _width The width of the canvas.
    /// @param _height The height of the canvas.
    /// @param _pixelPrice The price to paint a single pixel (in wei).
    function initializeCanvas(uint256 _width, uint256 _height, uint256 _pixelPrice) external onlyOwner canvasNotInitialized {
        if (_width == 0 || _height == 0) revert InvalidCoordinates(0, 0);
        canvasWidth = _width;
        canvasHeight = _height;
        pixelPrice = _pixelPrice;
        initialized = true;
        canvasStatus = CanvasStatus.PaintingOpen;
        emit CanvasInitialized(_width, _height, _pixelPrice);
    }

    // --- 7. Admin Functions ---
    /// @notice Updates the price to paint a single pixel.
    /// @param _newPrice The new price per pixel (in wei).
    function setPixelPrice(uint256 _newPrice) external onlyOwner canvasInitialized {
        pixelPrice = _newPrice;
    }

    /// @notice Allows the owner to withdraw accumulated funds from the contract.
    /// @param _recipient The address to send the funds to.
    /// @param _amount The amount of funds to withdraw.
    function withdrawFunds(address payable _recipient, uint256 _amount) external onlyOwner {
        if (_amount > address(this).balance) revert InsufficientPayment(_amount, address(this).balance); // Using InsufficientPayment error type for balance check
        (bool success, ) = _recipient.call{value: _amount}("");
        require(success, "Withdrawal failed");
    }

    /// @notice Pauses the pixel painting functions.
    function pauseCanvas() external onlyOwner canvasInitialized whenNotPaused {
        paused = true;
        emit CanvasPaused();
    }

    /// @notice Unpauses the pixel painting functions.
    function unpauseCanvas() external onlyOwner canvasInitialized whenPaused {
        paused = false;
        emit CanvasUnpaused();
    }

    /// @notice Sets the base URI for the NFT metadata. This is crucial for dynamic NFTs.
    /// @param _newBaseURI The new base URI. The off-chain service should handle this.
    function setBaseURI(string memory _newBaseURI) external onlyOwner {
        baseTokenURI = _newBaseURI;
    }

    /// @notice Sets the overall status of the canvas lifecycle.
    /// @param _status The new canvas status.
    function setCanvasStatus(CanvasStatus _status) external onlyOwner {
         canvasStatus = _status;
         emit CanvasStatusChanged(_status);
    }

     /// @notice Sets the address of the ERC20 token used for fractional ownership.
     /// @param _fractionalToken The address of the ERC20 contract.
    function setFractionalToken(address _fractionalToken) external onlyOwner {
        fractionalToken = IERC20(_fractionalToken);
    }

    /// @notice Toggles public voting on proposed styles.
    /// @param _enabled True to enable, False to disable.
    function allowPublicVoting(bool _enabled) external onlyOwner {
        votingEnabled = _enabled;
    }


    // --- 8. Canvas Interaction (Painting/Erasing) ---
    /// @notice Paints a single pixel on the canvas.
    /// @param x The x-coordinate (0-indexed).
    /// @param y The y-coordinate (0-indexed).
    /// @param colorData The RGB color data (3 bytes).
    function addPixel(uint256 x, uint256 y, bytes3 colorData) external payable nonReentrant canvasInitialized whenNotPaused canvasIs(CanvasStatus.PaintingOpen) {
        if (x >= canvasWidth || y >= canvasHeight) revert InvalidCoordinates(x, y);
        if (msg.value < pixelPrice) revert InsufficientPayment(pixelPrice, msg.value);

        uint256 index = y * canvasWidth + x;
        Pixel storage pixel = canvasPixels[index];

        // If this pixel was previously blank, increment total count and contributor count
        if (pixel.contributor == address(0)) { // Assuming address(0) means blank/initial state
             totalPixelsPainted++;
             contributorPixelCount[msg.sender]++;
        } else if (pixel.contributor != msg.sender) {
             // If repainting a pixel owned by someone else, decrement their count
             contributorPixelCount[pixel.contributor]--;
             contributorPixelCount[msg.sender]++;
        }
        // Note: If repainting your own pixel, counts don't change.

        pixel.color = colorData;
        pixel.contributor = msg.sender;
        pixel.timestamp = uint64(block.timestamp);

        // Refund excess payment
        if (msg.value > pixelPrice) {
            (bool success, ) = payable(msg.sender).call{value: msg.value - pixelPrice}("");
            require(success, "Refund failed");
        }

        emit PixelPainted(x, y, colorData, msg.sender, block.timestamp);
    }

    /// @notice Paints multiple pixels in a single transaction.
    /// @param xCoords Array of x-coordinates.
    /// @param yCoords Array of y-coordinates.
    /// @param colorData Array of RGB color data.
    function addPixels(uint256[] calldata xCoords, uint256[] calldata yCoords, bytes3[] calldata colorData) external payable nonReentrant canvasInitialized whenNotPaused canvasIs(CanvasStatus.PaintingOpen) {
        if (xCoords.length != yCoords.length || xCoords.length != colorData.length) revert ArrayLengthMismatch();
        uint256 numPixels = xCoords.length;
        uint256 totalCost = numPixels * pixelPrice;
        if (msg.value < totalCost) revert InsufficientPayment(totalCost, msg.value);

        for (uint256 i = 0; i < numPixels; i++) {
            uint256 x = xCoords[i];
            uint256 y = yCoords[i];
            bytes3 color = colorData[i];

            if (x >= canvasWidth || y >= canvasHeight) revert InvalidCoordinates(x, y); // Fail fast on invalid input

            uint256 index = y * canvasWidth + x;
            Pixel storage pixel = canvasPixels[index];

            // Update counts similar to addPixel
             if (pixel.contributor == address(0)) {
                 totalPixelsPainted++;
                 contributorPixelCount[msg.sender]++;
             } else if (pixel.contributor != msg.sender) {
                  contributorPixelCount[pixel.contributor]--;
                  contributorPixelCount[msg.sender]++;
             }

            pixel.color = color;
            pixel.contributor = msg.sender;
            pixel.timestamp = uint64(block.timestamp);

            // Note: Events per pixel in a batch might exceed gas limits.
            // Emitting a single event for the batch.
        }

         // Refund excess payment
        if (msg.value > totalCost) {
            (bool success, ) = payable(msg.sender).call{value: msg.value - totalCost}("");
            require(success, "Refund failed");
        }

        emit PixelsPainted(numPixels, msg.sender, block.timestamp);
    }

    /// @notice Fills a rectangular area with a single color.
    /// @param x1 Top-left x-coordinate.
    /// @param y1 Top-left y-coordinate.
    /// @param x2 Bottom-right x-coordinate.
    /// @param y2 Bottom-right y-coordinate.
    /// @param colorData The RGB color data.
    function fillArea(uint256 x1, uint256 y1, uint256 x2, uint256 y2, bytes3 colorData) external payable nonReentrant canvasInitialized whenNotPaused canvasIs(CanvasStatus.PaintingOpen) {
        if (x1 > x2 || y1 > y2 || x2 >= canvasWidth || y2 >= canvasHeight) revert InvalidArea(x1, y1, x2, y2);

        uint256 numPixels = (x2 - x1 + 1) * (y2 - y1 + 1);
        uint256 totalCost = numPixels * pixelPrice;
        if (msg.value < totalCost) revert InsufficientPayment(totalCost, msg.value);

        for (uint256 y = y1; y <= y2; y++) {
            for (uint256 x = x1; x <= x2; x++) {
                uint256 index = y * canvasWidth + x;
                Pixel storage pixel = canvasPixels[index];

                 // Update counts similar to addPixel
                if (pixel.contributor == address(0)) {
                    totalPixelsPainted++;
                    contributorPixelCount[msg.sender]++;
                } else if (pixel.contributor != msg.sender) {
                     contributorPixelCount[pixel.contributor]--;
                     contributorPixelCount[msg.sender]++;
                }

                pixel.color = colorData;
                pixel.contributor = msg.sender;
                pixel.timestamp = uint64(block.timestamp);
            }
        }

         // Refund excess payment
        if (msg.value > totalCost) {
            (bool success, ) = payable(msg.sender).call{value: msg.value - totalCost}("");
            require(success, "Refund failed");
        }

        emit AreaFilled(x1, y1, x2, y2, msg.sender, block.timestamp);
    }

    // --- 9. Gradient Function (Advanced) ---
    /// @notice Fills a rectangular area with a linear color gradient. (More advanced, involves on-chain color math)
    /// @param x1 Top-left x-coordinate.
    /// @param y1 Top-left y-coordinate.
    /// @param x2 Bottom-right x-coordinate.
    /// @param y2 Bottom-right y-coordinate.
    /// @param color1 The starting RGB color.
    /// @param color2 The ending RGB color.
    function addColorGradient(uint256 x1, uint256 y1, uint256 x2, uint256 y2, bytes3 color1, bytes3 color2) external payable nonReentrant canvasInitialized whenNotPaused canvasIs(CanvasStatus.PaintingOpen) {
        if (x1 > x2 || y1 > y2 || x2 >= canvasWidth || y2 >= canvasHeight) revert InvalidArea(x1, y1, x2, y2);

        uint256 numPixels = (x2 - x1 + 1) * (y2 - y1 + 1);
        uint256 totalCost = numPixels * pixelPrice;
        if (msg.value < totalCost) revert InsufficientPayment(totalCost, msg.value);

        // Calculate color differences
        int256 rDiff = int256(uint8(color2[0])) - int256(uint8(color1[0]));
        int256 gDiff = int256(uint8(color2[1])) - int256(uint8(color1[1]));
        int256 bDiff = int256(uint8(color2[2])) - int256(uint8(color1[2]));

        uint256 width = x2 - x1 + 1;
        uint256 height = y2 - y1 + 1;

        // Choose the dominant dimension for gradient direction (e.g., horizontal)
        bool horizontalGradient = width >= height;
        uint256 gradientLength = horizontalGradient ? width : height;

        if (gradientLength == 0) gradientLength = 1; // Avoid division by zero for 1x1 area

        for (uint256 y = y1; y <= y2; y++) {
            for (uint256 x = x1; x <= x2; x++) {
                uint256 index = y * canvasWidth + x;
                Pixel storage pixel = canvasPixels[index];

                 // Update counts similar to addPixel
                if (pixel.contributor == address(0)) {
                    totalPixelsPainted++;
                    contributorPixelCount[msg.sender]++;
                } else if (pixel.contributor != msg.sender) {
                     contributorPixelCount[pixel.contributor]--;
                     contributorPixelCount[msg.sender]++;
                }

                // Calculate interpolation fraction based on position
                uint256 pos = horizontalGradient ? (x - x1) : (y - y1);
                // Use large multiplier for fixed-point like division
                uint256 fraction10000 = (pos * 10000) / gradientLength;

                // Calculate interpolated color components
                uint8 r = uint8(int256(uint8(color1[0])) + (rDiff * int256(fraction10000)) / 10000);
                uint8 g = uint8(int256(uint8(color1[1])) + (gDiff * int256(fraction10000)) / 10000);
                uint8 b = uint8(int256(uint8(color1[2])) + (bDiff * int256(fraction10000)) / 10000);

                bytes3 interpolatedColor = bytes3(bytes.concat(bytes1(r), bytes1(g), bytes1(b)));

                pixel.color = interpolatedColor;
                pixel.contributor = msg.sender;
                pixel.timestamp = uint64(block.timestamp);
            }
        }

         // Refund excess payment
        if (msg.value > totalCost) {
            (bool success, ) = payable(msg.sender).call{value: msg.value - totalCost}("");
            require(success, "Refund failed");
        }

        emit ColorGradientAdded(x1, y1, x2, y2, color1, color2, msg.sender, block.timestamp);
    }

    /// @notice Erases a pixel (sets its color to default and clears contributor). Costs pixelPrice.
    /// @param x The x-coordinate.
    /// @param y The y-coordinate.
    function erasePixel(uint256 x, uint256 y) external payable nonReentrant canvasInitialized whenNotPaused canvasIs(CanvasStatus.PaintingOpen) {
        if (x >= canvasWidth || y >= canvasHeight) revert InvalidCoordinates(x, y);
        if (msg.value < pixelPrice) revert InsufficientPayment(pixelPrice, msg.value);

        uint256 index = y * canvasWidth + x;
        Pixel storage pixel = canvasPixels[index];

        // Only decrease counts if it wasn't already blank
        if (pixel.contributor != address(0)) {
            totalPixelsPainted--;
            contributorPixelCount[pixel.contributor]--;
        }

        pixel.color = bytes3(0); // Default "blank" color
        pixel.contributor = address(0);
        pixel.timestamp = uint64(block.timestamp);

         // Refund excess payment
        if (msg.value > pixelPrice) {
            (bool success, ) = payable(msg.sender).call{value: msg.value - pixelPrice}("");
            require(success, "Refund failed");
        }

        emit PixelErased(x, y, msg.sender, block.timestamp);
    }


    // --- 10. Viewing Canvas State ---
    /// @notice Gets the details of a specific pixel.
    /// @param x The x-coordinate.
    /// @param y The y-coordinate.
    /// @return color The RGB color.
    /// @return contributor The address of the last contributor.
    /// @return timestamp The timestamp of the last update.
    function getPixelInfo(uint256 x, uint256 y) external view canvasInitialized returns (bytes3 color, address contributor, uint64 timestamp) {
         if (x >= canvasWidth || y >= canvasHeight) revert InvalidCoordinates(x, y);
         uint256 index = y * canvasWidth + x;
         Pixel storage pixel = canvasPixels[index];
         return (pixel.color, pixel.contributor, pixel.timestamp);
    }

    /// @notice Gets the total number of non-blank pixels painted on the canvas.
    /// @return The count of pixels.
    function getTotalPixelsPainted() external view returns (uint256) {
        return totalPixelsPainted;
    }

    /// @notice Gets the number of pixels painted by a specific contributor.
    /// @param _contributor The address of the contributor.
    /// @return The count of pixels painted by the contributor.
    function getPixelCountByContributor(address _contributor) external view returns (uint256) {
        return contributorPixelCount[_contributor];
    }

    /// @notice Gets the dimensions of the canvas.
    /// @return width The canvas width.
    /// @return height The canvas height.
    function getCanvasDimensions() external view returns (uint256 width, uint256 height) {
        return (canvasWidth, canvasHeight);
    }

    /// @notice Gets the current status of the canvas lifecycle.
    /// @return The current status enum value.
    function getCanvasStatus() external view returns (CanvasStatus) {
        return canvasStatus;
    }


    // --- 11. NFT Standard Functions (ERC721) ---
     /// @notice Returns the metadata URI for a specific token ID (only CANVAS_TOKEN_ID is valid).
     /// The off-chain service at baseTokenURI is expected to serve dynamic metadata based on the contract state.
     /// @param tokenId The ID of the NFT.
     /// @return The URI for the NFT metadata JSON.
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        if (tokenId != CANVAS_TOKEN_ID || ownerOf(tokenId) == address(0)) {
            revert ERC721TokenNotFound(tokenId);
        }
        // The off-chain renderer needs baseTokenURI, tokenId, and potentially connect to read contract state
        // Example: "ipfs://[somehash]/1.json" or "https://api.mycanvas.xyz/metadata/1"
        // The off-chain service for baseTokenURI must handle the dynamic rendering based on canvas state (pixels, style).
        return string(abi.encodePacked(baseTokenURI, Strings.toString(tokenId)));
    }

     /// @notice Checks if the contract supports a given interface. Required for ERC721 compliance.
     /// @param interfaceId The interface ID to check.
     /// @return True if the interface is supported, false otherwise.
    function supportsInterface(bytes4 interfaceId) public view override(ERC721, Ownable) returns (bool) {
         return interfaceId == type(IERC721).interfaceId ||
               interfaceId == type(IERC165).interfaceId ||
               interfaceId == type(Ownable).interfaceId || // OpenZeppelin Ownable adds this
               super.supportsInterface(interfaceId);
    }

    // --- 12. NFT Lifecycle ---
    /// @notice Mints the single Canvas NFT. Callable by the owner after initialization.
    function mintCanvasNFT() external onlyOwner canvasInitialized nftNotMinted {
        _safeMint(owner(), CANVAS_TOKEN_ID); // Mint the NFT to the owner
        canvasStatus = CanvasStatus.MintingReady; // Or NFTOwnedByAdmin, etc.
        emit CanvasNFTMinted(CANVAS_TOKEN_ID);
    }

    /// @notice Gets the ID of the main canvas NFT.
    /// @return The NFT token ID.
    function getTokenId() external pure returns (uint256) {
        return CANVAS_TOKEN_ID;
    }

    // --- 13. Fractionalization Functions ---
    /// @notice Splits the Canvas NFT into fractional ERC20 tokens. Requires the contract to own the NFT.
    /// The ERC20 contract must be set and must have minting capabilities callable by this contract.
    function splitCanvasNFT() external onlyOwner nftMinted nftNotSplit canvasInitialized {
        if (ownerOf(CANVAS_TOKEN_ID) != owner()) revert OwnableInvalidAproval(owner(), ownerOf(CANVAS_TOKEN_ID)); // Check if owner still holds NFT
        if (address(fractionalToken) == address(0)) revert FractionalTokenNotSet();

        // Transfer NFT to this contract (acting as a vault)
        transferFrom(owner(), address(this), CANVAS_TOKEN_ID);

        // Mint total supply of fractional tokens to the owner
        // Requires the fractional ERC20 contract to have a mint function accessible by this contract
        // Example: IERC20Mintable(fractionalToken).mint(owner(), TOTAL_SUPPLY_FRACTIONAL_TOKENS);
        // **Note:** This requires an ERC20 contract that has a mint function callable by this contract address.
        // The specific ERC20 implementation (like using OpenZeppelin's ERC20Capped or custom) is external.
        // For this example, we'll assume such a function exists on the `fractionalToken` address.
        // A realistic implementation would need to define the total supply and how minting/burning works.
        // Let's assume a hypothetical mint function signature for now.
        // Be careful with the actual implementation based on your ERC20 contract.
        // For simplicity, let's assume the fractional token has a fixed supply minted initially or a minting function.
        // A common pattern is that the fractional ERC20 is deployed specifically for this NFT,
        // and its supply represents 100% ownership.
        // We will NOT implement the actual minting here as it depends on the specific ERC20 contract,
        // but mark the NFT as split. The ERC20 is expected to handle its own supply and distribution.
        // A simpler model: The ERC20 is pre-minted/deployed. This function just locks the NFT.
        // Let's go with the simpler model for this concept: Lock the NFT here.

        nftSplit = true;
        canvasStatus = CanvasStatus.NFTSplit;
        emit CanvasNFTSplit(CANVAS_TOKEN_ID, address(fractionalToken));
    }

    /// @notice Allows users to redeem the original NFT by burning fractional tokens.
    /// Simplified logic: Requires burning the *entire* total supply of fractional tokens to withdraw the NFT.
    /// This function assumes the fractional ERC20 has a `burnFrom` function or equivalent approval mechanism.
    /// @param amount The amount of fractional tokens to burn (must be total supply in this simplified model).
    function redeemCanvasNFT(uint256 amount) external nonReentrant nftIsSplit canvasInitialized {
        if (address(fractionalToken) == address(0)) revert FractionalTokenNotSet();

        // Requires approval beforehand: msg.sender must have approved this contract to spend `amount` tokens
        // The amount should ideally be the total supply of the fractional token to fully reconstitute the NFT.
        // We need the fractional token's total supply or a mechanism to check if `amount` represents 100% ownership.
        // For simplicity, let's assume `amount` must be the exact supply.
        // This contract doesn't know the total supply of the external ERC20 unless it's passed or the ERC20 is queried.
        // Let's query the total supply of the ERC20 for this simplified example.
        uint256 totalFractionalSupply = fractionalToken.totalSupply();
        if (amount != totalFractionalSupply) revert NotEnoughFractionalTokens();

        // Burn the tokens. Requires msg.sender to have approved this contract.
        // This burn mechanism depends heavily on the ERC20 contract.
        // A common pattern is `fractionalToken.burnFrom(msg.sender, amount);`
        // Let's assume `transferFrom` to `address(0)` acts as burning if supported by the ERC20.
        // Make sure your ERC20 implementation handles this correctly or use a dedicated burn function.
        bool success = fractionalToken.transferFrom(msg.sender, address(0), amount);
        require(success, "Fractional token burn failed");

        // Transfer NFT back to the redeemer
        _transfer(address(this), msg.sender, CANVAS_TOKEN_ID);

        nftSplit = false; // Canvas NFT is no longer split
        canvasStatus = CanvasStatus.MintingReady; // Or NFTOwnedByUser
        emit CanvasNFTRedeemed(CANVAS_TOKEN_ID, address(fractionalToken));
    }

    /// @notice Gets the address of the ERC20 token used for fractional ownership.
    /// @return The address of the fractional token contract.
    function getFractionalToken() external view returns (address) {
        return address(fractionalToken);
    }


    // --- 14. Dynamic Styling & Voting Functions ---
    /// @notice Applies a visual style filter ID to the canvas. Influences off-chain rendering via metadata.
    /// Can be called by owner or triggered by a finalized style vote.
    /// @param _styleId The ID of the style to apply.
    function applyStyleFilter(uint256 _styleId) public onlyOwner { // Made public so owner can call directly, or another internal function (like finalizeVote) can call it
        currentStyleId = _styleId;
        // This change modifies the on-chain state, the off-chain renderer should pick this up when tokenURI is called.
        emit StyleApplied(_styleId, msg.sender);
    }

    /// @notice Gets the ID of the currently applied visual style filter.
    /// @return The applied style ID.
    function getAppliedStyle() external view returns (uint256) {
        return currentStyleId;
    }

    /// @notice Allows users (e.g., contributors or NFT owners) to propose a new style ID for voting.
    /// This is a simplified proposal mechanism. More complex systems might require stakes or specific roles.
    /// @param _styleId The ID of the style being proposed.
    /// @param _descriptionHash Hash referencing off-chain details about the style (e.g., IPFS hash of style definition).
    function proposeStyle(uint256 _styleId, bytes32 _descriptionHash) external canvasInitialized {
        // Check if style ID is already proposed
        if (proposedStyles[_styleId].proposalTimestamp != 0) {
             // Style already proposed, maybe update description hash? Or just revert? Revert for simplicity.
             revert(); // Simple revert, could add custom error
        }
        // Prevent proposing default style 0
        if (_styleId == 0) revert(); // Cannot propose default style

        proposedStyles[_styleId] = ProposedStyle({
            descriptionHash: _descriptionHash,
            proposalTimestamp: uint64(block.timestamp),
            votes: 0
        });
        proposedStyleIds.push(_styleId); // Keep track of proposed IDs
        emit StyleProposed(_styleId, _descriptionHash, msg.sender);
    }

    /// @notice Allows users to vote for a proposed style. Voting must be enabled.
    /// Simplified: 1 address = 1 vote per style. Could be weighted by pixel count or NFT ownership.
    /// @param _styleId The ID of the style to vote for.
    function voteForStyle(uint256 _styleId) external canvasInitialized {
        if (!votingEnabled) revert VotingNotEnabled();
        if (proposedStyles[_styleId].proposalTimestamp == 0) revert StyleNotProposed();
        if (hasVotedForStyle[msg.sender][_styleId]) revert AlreadyVoted(_styleId);

        proposedStyles[_styleId].votes++;
        hasVotedForStyle[msg.sender][_styleId] = true;
        emit StyleVoted(_styleId, msg.sender);
    }

    /// @notice Finalizes the vote for a specific style and applies it if certain conditions met (e.g., owner call, or threshold check).
    /// Simplified: Only owner can call and explicitly finalize. A real DAO would have on-chain threshold logic.
    /// @param _styleId The ID of the style to finalize the vote for.
    function finalizeStyleVote(uint256 _styleId) external onlyOwner canvasInitialized {
         if (proposedStyles[_styleId].proposalTimestamp == 0) revert StyleNotProposed();

         // In a real system, add checks here:
         // - Has enough time passed since proposal/voting opened?
         // - Did the style reach a certain vote threshold?
         // For this example, the owner makes the executive decision to finalize and apply.

         applyStyleFilter(_styleId); // Apply the style

         // Optional: Reset votes for this style, or clear all proposed styles
         // proposedStyles[_styleId].votes = 0; // Or remove the style from proposedStyles list
         // proposedStyleIds = new uint256[](0); // Clear all proposals (simplistic)
    }

    /// @notice Gets the current vote count for a proposed style.
    /// @param _styleId The ID of the style.
    /// @return The number of votes.
    function getVoteCountForStyle(uint256 _styleId) external view canvasInitialized returns (uint256) {
         if (proposedStyles[_styleId].proposalTimestamp == 0) revert StyleNotProposed();
         return proposedStyles[_styleId].votes;
    }

    /// @notice Gets the list of currently proposed style IDs.
    /// @return An array of proposed style IDs.
    function getProposedStyles() external view returns (uint256[] memory) {
        return proposedStyleIds;
    }


    // --- 15. Royalty Distribution Functions ---
    /// @notice Allows a contributor to claim their share of accumulated royalties.
    /// Simplified model: Pays out a proportion of the *current* contract balance based on pixel count weight.
    /// This assumes funds are sent to the contract from somewhere (e.g., secondary NFT sales via a marketplace that sends royalties here).
    function claimRoyalties() external nonReentrant canvasInitialized {
        uint256 contributorPixels = contributorPixelCount[msg.sender];
        if (contributorPixels == 0) revert NoRoyaltiesToClaim(); // Only contributors can claim

        // Calculate share based on current proportion of pixels
        // Note: This can fluctuate if pixels are added/erased.
        // A fairer system might snapshot pixel counts at the time funds arrive,
        // or calculate based on contribution *value* (ETH spent).
        // This simplified version distributes from the *current* contract balance proportionally.
        // Also, funds need to *get* into the contract first (e.g., from NFT sales).
        // Let's assume funds are here.

        uint256 totalActivePixels = totalPixelsPainted; // Use non-blank count
        if (totalActivePixels == 0) revert NoRoyaltiesToClaim(); // No pixels, no royalties

        uint256 contractBalance = address(this).balance;
        // Avoid division by zero if totalActivePixels is 0, handled above.
        // Calculate share: (contributorPixels / totalActivePixels) * contractBalance
        // Using fixed-point math approach to avoid floating point and precision loss
        // share = (contributorPixels * contractBalance) / totalActivePixels
        uint256 royaltyAmount = (contributorPixels * contractBalance) / totalActivePixels;

        if (royaltyAmount == 0) revert NoRoyaltiesToClaim();

        // Track claimed amount? Or just deduct from balance implicitly via transfer.
        // Let's deduct implicitly. The `unclaimedRoyalties` mapping could be used in a different model
        // where specific royalty events add to a user's balance, and claim deducts.
        // In *this* simplified model, any balance in the contract is available proportionally.
        // To make it more like a true "unclaimed" balance, the contract would need to track
        // incoming royalty funds specifically and add them to `unclaimedRoyalties[contributor]`
        // based on their weight *at that moment*. This is complex.
        // Let's revise: `unclaimedRoyalties` tracks the *total ETH sent* earmarked for royalties.
        // Admin needs a function to mark incoming ETH as royalty pool.
        // OR, just distribute *any* ETH balance proportionally. Let's do that for simplicity.

        // Transfer the calculated amount
        (bool success, ) = payable(msg.sender).call{value: royaltyAmount}("");
        require(success, "Royalty claim failed");

        // In a more complex model with `unclaimedRoyalties` mapping:
        // uint256 claimable = unclaimedRoyalties[msg.sender];
        // if (claimable == 0) revert NoRoyaltiesToClaim();
        // unclaimedRoyalties[msg.sender] = 0;
        // (bool success, ) = payable(msg.sender).call{value: claimable}("");
        // require(success, "Royalty claim failed");
        // emit RoyaltiesClaimed(msg.sender, claimable);

        emit RoyaltiesClaimed(msg.sender, royaltyAmount);
    }

    /// @notice Gets a contributor's "weight" for royalty distribution (based on current pixel count).
    /// Used off-chain to estimate potential royalties.
    /// @param _contributor The address of the contributor.
    /// @return The number of pixels they currently control.
    function getContributorWeight(address _contributor) external view returns (uint256) {
        return contributorPixelCount[_contributor];
    }

    // --- 16. Canvas Status Functions ---
    // getCanvasStatus is already implemented in section 10.

    // Fallback/Receive to allow receiving ETH for royalties or other purposes
    receive() external payable {}
    fallback() external payable {}
}
```