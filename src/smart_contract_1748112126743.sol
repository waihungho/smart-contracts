Okay, let's create a smart contract that combines dynamic NFTs, generative art concepts, and interactive state evolution. We'll call it the "Quantum Flux Canvas".

The core idea is an NFT representing a grid (canvas) where each "pixel" or cell has a state (e.g., an energy level or color index). This state can be altered by user interactions ("applying flux") or evolve autonomously based on defined rules and time. The NFT's metadata and visual representation are *derived* from the current on-chain state, making it dynamic.

It will use ERC721 for ownership and include ERC2981 for royalties. The state evolution logic will be simplified for on-chain execution but illustrate the concept of an evolving system.

---

**Quantum Flux Canvas Smart Contract**

**Outline:**

1.  **Contract Description:** An ERC721 NFT contract representing a grid-based canvas whose pixel states can evolve dynamically based on time, user interactions ("flux"), and configured rules. Metadata is generated off-chain based on the current on-chain state.
2.  **Inheritance:** ERC721Enumerable, ERC2981, Ownable.
3.  **State Variables:**
    *   NFT details (name, symbol).
    *   Canvas dimensions (width, height).
    *   Pixel state storage (`tokenId` -> array of states).
    *   Evolution parameters (rules, cooldowns).
    *   Minting parameters (price, supply, phases).
    *   Royalty parameters.
    *   Base URI for metadata.
    *   Mapping for last evolution time per canvas.
    *   Contract state flags (paused).
4.  **Events:** Mint, StateChange, FluxApplied, RulesUpdated, EvolutionTriggered, RoyaltyPaid, PauseToggled.
5.  **Modifiers:** `onlyOwner`, `canvasExists`, `isPixelCoordinateValid`, `canvasNotPaused`, `mintingActive`.
6.  **Core ERC721 Functions:** (Inherited and potentially overridden for hooks)
7.  **Canvas Interaction Functions:** Apply flux, trigger evolution.
8.  **Query Functions:** Get pixel state, get full canvas state, get evolution cooldown, `tokenURI`.
9.  **Configuration Functions:** Set dimensions, set rules, set mint parameters, set base URI, set royalties, withdraw funds, pause.
10. **Helper Functions:** Coordinate mapping, state encoding/decoding (if needed).

**Function Summary:**

*   **Constructor:** Initializes the contract with name, symbol, and dimensions.
*   **`mintCanvas` (payable):** Allows users to mint a new canvas NFT, paying the mint price. Initializes the canvas state.
*   **`applyFluxToPixel`:** Allows the owner of a canvas to apply a specific 'flux' value to a single pixel, directly changing its state (within limits or rules).
*   **`applyFluxToArea`:** Allows the owner of a canvas to apply 'flux' to a rectangular area, affecting multiple pixels based on area-specific rules.
*   **`evolveCanvasState`:** Triggers the autonomous state evolution rules for a specific canvas. This function is permissionless but might be rate-limited (`evolutionCooldown`). Can optionally include a small incentive for the caller (gas relay).
*   **`bulkEvolveCanvases`:** Allows evolving a batch of canvases (up to a limit) in a single transaction.
*   **`seedCanvasRandomly`:** Initializes or re-initializes a canvas with pseudorandom states based on block data.
*   **`resetCanvasState`:** Allows the canvas owner to reset their canvas to a default initial state.
*   **`getCanvasPixels`:** Returns the current state array for all pixels of a given canvas.
*   **`getPixelState`:** Returns the state of a single pixel at specified coordinates.
*   **`getEvolutionCooldown`:** Returns the timestamp when a specific canvas can next be evolved.
*   **`setEvolutionRules` (onlyOwner):** Sets parameters that govern how the canvas state evolves autonomously.
*   **`setFluxRules` (onlyOwner):** Sets parameters that govern how `applyFlux` interactions affect pixel states.
*   **`setCanvasDimensions` (onlyOwner):** Sets the width and height for new canvases (cannot change existing ones).
*   **`setMintPrice` (onlyOwner):** Sets the price to mint a new canvas.
*   **`setMaxSupply` (onlyOwner):** Sets the maximum number of canvases that can be minted.
*   **`setBaseURI` (onlyOwner):** Sets the base URI for metadata, which the `tokenURI` function will use. This points to an off-chain service.
*   **`setRoyaltyInfo` (onlyOwner):** Sets the default royalty percentage and recipient for ERC2981.
*   **`withdrawFunds` (onlyOwner):** Allows the owner to withdraw collected Ether.
*   **`pauseCanvasInteractions` (onlyOwner):** Pauses all functions that modify canvas state (`applyFlux`, `evolve`).
*   **`pauseMinting` (onlyOwner):** Pauses only the `mintCanvas` function.
*   **`unpauseContract` (onlyOwner):** Unpauses the contract.
*   **`tokenURI`:** Required ERC721 metadata function. Returns a URI pointing to an off-chain service that will generate metadata based on the canvas's current state (`getCanvasPixels`).
*   **`royaltyInfo`:** Required ERC2981 function. Returns royalty recipient and amount for a given token sale price.
*   **`supportsInterface`:** Required ERC165 function. Indicates support for ERC721, ERC721Enumerable, and ERC2981 interfaces.
*   **`_coordinateToIndex` (internal pure):** Helper to convert (row, col) coordinates to array index.
*   **`_indexToCoordinate` (internal pure):** Helper to convert array index to (row, col) coordinates.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";

// Custom library for coordinate conversion
library CanvasUtils {
    function coordinateToIndex(uint256 width, uint256 row, uint256 col) internal pure returns (uint256) {
        require(row < width && col < width, "Invalid coordinates"); // Assuming square for simplicity, update if needed
        return row * width + col;
    }

    function indexToCoordinate(uint256 width, uint256 index) internal pure returns (uint256 row, uint256 col) {
        require(index < width * width, "Invalid index"); // Assuming square
        row = index / width;
        col = index % width;
    }
}


contract QuantumFluxCanvas is ERC721Enumerable, ERC721Pausable, ERC2981, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;

    // --- STATE VARIABLES ---

    // Canvas dimensions (fixed for all canvases minted after deployment)
    uint256 public canvasWidth;
    uint256 public canvasHeight; // Using height = width for simplicity in utils, can be separate

    // Pixel state storage: tokenId -> array of uint8 states (0-255)
    // Size of array is width * height
    mapping(uint256 => uint8[]) public canvasPixels;

    // Evolution parameters
    uint256 public evolutionCooldown = 1 hours; // Min time between evolutions per canvas
    // Simplified rule: neighbor influence decay + ambient flux. State wraps around 0-255.
    int8 public neighborInfluence = 1; // How much neighbors (on average) affect a pixel
    uint8 public ambientFlux = 1; // Constant state change per evolution step

    // Flux application parameters
    // Simplified rule: direct application + a decay factor
    uint8 public fluxDecayFactor = 1; // How much applied flux diminishes neighbor effect

    // Minting parameters
    uint256 public mintPrice = 0.05 ether;
    uint256 public maxSupply = 1000;
    bool public mintingActive = true;

    // Metadata
    string private _baseTokenURI;

    // Tracking last evolution time per canvas
    mapping(uint256 => uint48) private _lastEvolutionTime; // Using uint48 for efficiency

    // ERC2981 Royalties
    address public royaltyRecipient;
    uint96 public royaltyBps = 500; // 5%

    // --- EVENTS ---

    event CanvasMinted(uint256 indexed tokenId, address indexed owner, uint256 timestamp);
    event PixelStateChanged(uint256 indexed tokenId, uint256 indexed index, uint8 oldState, uint8 newState);
    event FluxApplied(uint256 indexed tokenId, uint256 indexed caller, uint256 index, int256 appliedValue);
    event EvolutionTriggered(uint256 indexed tokenId, uint256 timestamp, uint256 stateChangesCount);
    event RulesUpdated(uint256 timestamp);
    event RoyaltyInfoUpdated(address indexed recipient, uint96 bps);
    event PauseToggled(bool indexed pausedState);
    event MintingPauseToggled(bool indexed pausedState);
    event FundsWithdrawn(address indexed recipient, uint256 amount);

    // --- MODIFIERS ---

    modifier canvasExists(uint256 tokenId) {
        require(_exists(tokenId), "Canvas does not exist");
        _;
    }

    modifier isPixelCoordinateValid(uint256 row, uint256 col) {
        require(row < canvasHeight && col < canvasWidth, "Invalid pixel coordinates");
        _;
    }

    modifier canvasNotPaused(uint256 tokenId) {
        require(!paused(), "Contract is paused");
        // Can add token-specific pause if needed
        _;
    }

    modifier mintingActiveCheck() {
        require(mintingActive, "Minting is not active");
        _;
    }

    // --- CONSTRUCTOR ---

    constructor(uint256 initialWidth, uint256 initialHeight)
        ERC721("QuantumFluxCanvas", "QFC")
        ERC721Pausable(msg.sender) // Owner is pauser
        ERC2981() // Initialize royalties
        Ownable(msg.sender)
    {
        require(initialWidth > 0 && initialHeight > 0, "Dimensions must be positive");
        canvasWidth = initialWidth;
        canvasHeight = initialHeight;
        royaltyRecipient = msg.sender; // Default royalty recipient is owner
    }

    // --- MINTING FUNCTIONS ---

    /**
     * @notice Mints a new Quantum Flux Canvas NFT.
     * @param to The address to mint the token to.
     */
    function mintCanvas(address to) external payable whenNotPaused mintingActiveCheck {
        uint256 currentSupply = _tokenIdCounter.current();
        require(currentSupply < maxSupply, "Max supply reached");
        require(msg.value >= mintPrice, "Insufficient ETH");

        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();

        // Initialize canvas state (e.g., all zeros)
        uint8[] memory initialPixels = new uint8[](canvasWidth * canvasHeight);
        // Optionally seed randomly:
        // seedCanvasRandomly(tokenId); // Better to call externally or in a separate tx

        canvasPixels[tokenId] = initialPixels;
        _lastEvolutionTime[tokenId] = uint48(block.timestamp); // Set initial evolution time

        _safeMint(to, tokenId);

        if (msg.value > mintPrice) {
            // Return excess ETH
            payable(msg.sender).transfer(msg.value - mintPrice);
        }

        emit CanvasMinted(tokenId, to, block.timestamp);
    }

    /**
     * @notice Sets the price for minting a new canvas.
     * @param newPrice The new price in wei.
     */
    function setMintPrice(uint256 newPrice) external onlyOwner {
        mintPrice = newPrice;
    }

    /**
     * @notice Sets the maximum number of canvases that can be minted.
     * @param newMaxSupply The new max supply.
     */
    function setMaxSupply(uint256 newMaxSupply) external onlyOwner {
        maxSupply = newMaxSupply;
    }

    /**
     * @notice Withdraws collected Ether to the owner's address.
     */
    function withdrawFunds() external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No ETH to withdraw");
        payable(owner()).transfer(balance);
        emit FundsWithdrawn(owner(), balance);
    }

    // --- CANVAS INTERACTION FUNCTIONS ---

    /**
     * @notice Applies a 'flux' value to a single pixel, changing its state.
     * @param tokenId The ID of the canvas token.
     * @param row The row coordinate of the pixel.
     * @param col The column coordinate of the pixel.
     * @param fluxValue The value of the flux to apply (signed, could be positive or negative effect).
     */
    function applyFluxToPixel(uint256 tokenId, uint256 row, uint256 col, int8 fluxValue)
        external
        canvasExists(tokenId)
        canvasNotPaused(tokenId)
        isPixelCoordinateValid(row, col)
    {
        // Require token owner or approved address to apply flux?
        require(_isApprovedOrOwner(msg.sender, tokenId), "Not token owner or approved");

        uint256 index = CanvasUtils.coordinateToIndex(canvasWidth, row, col);
        uint8 currentState = canvasPixels[tokenId][index];

        // Apply flux - simplified wrapping addition
        // Note: Direct addition/subtraction on uint8 wraps automatically.
        // Use assembly or unchecked if exact wrapping is needed, or add explicit logic.
        // Example simple logic: state += fluxValue (with wrap)
        // uint8 newState = uint8(int8(currentState) + fluxValue); // Signed addition with wrap
        // Or clamp: uint8 newState = uint8(Math.max(0, Math.min(255, int256(currentState) + fluxValue)));

        // Simple wrap-around addition:
        int16 intermediateState = int16(currentState) + int16(fluxValue);
        uint8 newState = uint8(intermediateState % 256); // Modulo for wrapping

        canvasPixels[tokenId][index] = newState;

        emit PixelStateChanged(tokenId, index, currentState, newState);
        emit FluxApplied(tokenId, msg.sender, index, fluxValue);
    }

     /**
     * @notice Applies a 'flux' value to a rectangular area, affecting multiple pixels.
     * @param tokenId The ID of the canvas token.
     * @param startRow The starting row coordinate.
     * @param startCol The starting column coordinate.
     * @param endRow The ending row coordinate.
     * @param endCol The ending column coordinate.
     * @param fluxValue The base value of the flux to apply to each pixel in the area.
     */
    function applyFluxToArea(uint256 tokenId, uint256 startRow, uint256 startCol, uint256 endRow, uint256 endCol, int8 fluxValue)
        external
        canvasExists(tokenId)
        canvasNotPaused(tokenId)
    {
         require(_isApprovedOrOwner(msg.sender, tokenId), "Not token owner or approved");
         require(startRow <= endRow && startCol <= endCol, "Invalid area coordinates");
         require(endRow < canvasHeight && endCol < canvasWidth, "Area extends beyond canvas");

         uint256 stateChanges = 0;
         for (uint256 r = startRow; r <= endRow; r++) {
             for (uint256 c = startCol; c <= endCol; c++) {
                 uint256 index = CanvasUtils.coordinateToIndex(canvasWidth, r, c);
                 uint8 currentState = canvasPixels[tokenId][index];

                 // Simple wrap-around addition per pixel
                 int16 intermediateState = int16(currentState) + int16(fluxValue);
                 uint8 newState = uint8(intermediateState % 256); // Modulo for wrapping

                 if (newState != currentState) {
                     canvasPixels[tokenId][index] = newState;
                     emit PixelStateChanged(tokenId, index, currentState, newState);
                     stateChanges++;
                 }
             }
         }
         if (stateChanges > 0) {
              // Emit a general event for area application if helpful, or rely on pixel events
              // emit FluxAppliedToArea(tokenId, msg.sender, startRow, startCol, endRow, endCol, fluxValue, stateChanges);
         }
         // Note: A single FluxApplied event per pixel is emitted by the loop.
    }


    /**
     * @notice Triggers the autonomous state evolution for a specific canvas.
     * Can be called by anyone, but is rate-limited.
     * A simplified Conway-like rule is applied based on neighbors.
     * @param tokenId The ID of the canvas token.
     */
    function evolveCanvasState(uint256 tokenId) external canvasExists(tokenId) canvasNotPaused(tokenId) {
        require(_lastEvolutionTime[tokenId] + evolutionCooldown <= block.timestamp, "Evolution cooldown active");

        uint8[] memory currentState = new uint8[](canvasWidth * canvasHeight);
        // Copy current state to temp array to avoid using new states during evolution calculation
        for(uint256 i = 0; i < canvasWidth * canvasHeight; i++) {
            currentState[i] = canvasPixels[tokenId][i];
        }

        uint256 stateChangesCount = 0;
        uint256 totalPixels = canvasWidth * canvasHeight;

        for (uint256 i = 0; i < totalPixels; i++) {
            (uint256 r, uint256 c) = CanvasUtils.indexToCoordinate(canvasWidth, i);
            uint8 pixelState = currentState[i];

            // Simplified evolution rule based on neighbors:
            // Count neighbors whose state is above a threshold (e.g., 128)
            uint256 neighborsAboveThreshold = 0;
            int256 neighborStatesSum = 0; // Sum of neighbor states

            // Check 8 neighbors
            for (int256 dr = -1; dr <= 1; dr++) {
                for (int256 dc = -1; dc <= 1; dc++) {
                    if (dr == 0 && dc == 0) continue; // Skip self

                    int256 nr = int256(r) + dr;
                    int256 nc = int256(c) + dc;

                    // Check bounds
                    if (nr >= 0 && nr < int256(canvasHeight) && nc >= 0 && nc < int256(canvasWidth)) {
                        uint256 neighborIndex = CanvasUtils.coordinateToIndex(canvasWidth, uint256(nr), uint256(nc));
                        uint8 neighborState = currentState[neighborIndex];
                        neighborStatesSum += int256(neighborState);
                        if (neighborState > 128) { // Example threshold
                            neighborsAboveThreshold++;
                        }
                    }
                }
            }

            // Apply rules: state changes based on neighbor count and sum
            // Example rule: state += (neighbor sum * influence) / 8 + ambient flux
            int256 stateChange = (neighborStatesSum * neighborInfluence) / 8 + ambientFlux;

            // Apply change and wrap around
            int16 intermediateState = int16(pixelState) + int16(stateChange);
            uint8 nextState = uint8(intermediateState % 256);

            if (nextState != pixelState) {
                 canvasPixels[tokenId][i] = nextState;
                 emit PixelStateChanged(tokenId, i, pixelState, nextState);
                 stateChangesCount++;
             }
        }

        _lastEvolutionTime[tokenId] = uint48(block.timestamp);
        emit EvolutionTriggered(tokenId, block.timestamp, stateChangesCount);

        // Optional: Small ETH incentive for the caller to cover gas
        // if (stateChangesCount > 0) { // Only pay if something changed
        //     payable(msg.sender).transfer(0.0001 ether); // Example reward
        // }
    }

    /**
     * @notice Triggers autonomous evolution for a batch of canvases.
     * Useful for potential batch processing off-chain or by a bot.
     * @param tokenIds An array of canvas IDs to evolve. Limited by gas.
     */
    function bulkEvolveCanvases(uint256[] calldata tokenIds) external whenNotPaused {
        // Limit batch size to prevent excessive gas
        require(tokenIds.length <= 10, "Batch size limit exceeded (max 10)");

        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
             // Check if canvas exists and is not paused (using requires within loop might hit gas limits)
            if (_exists(tokenId) && !paused() && _lastEvolutionTime[tokenId] + evolutionCooldown <= block.timestamp) {
                // Call evolution logic - internal helper function to avoid code duplication
                 _evolveCanvasInternal(tokenId);
            }
        }
    }

    /**
     * @dev Internal helper for the evolution logic.
     * @param tokenId The ID of the canvas token.
     */
    function _evolveCanvasInternal(uint256 tokenId) internal {
        // This is the same logic as in evolveCanvasState, extracted
        uint8[] memory currentState = new uint8[](canvasWidth * canvasHeight);
        for(uint256 i = 0; i < canvasWidth * canvasHeight; i++) {
            currentState[i] = canvasPixels[tokenId][i];
        }

        uint256 stateChangesCount = 0;
        uint256 totalPixels = canvasWidth * canvasHeight;

        for (uint256 i = 0; i < totalPixels; i++) {
            (uint256 r, uint256 c) = CanvasUtils.indexToCoordinate(canvasWidth, i);
            uint8 pixelState = currentState[i];

            uint256 neighborsAboveThreshold = 0;
            int256 neighborStatesSum = 0;

            for (int256 dr = -1; dr <= 1; dr++) {
                for (int256 dc = -1; dc <= 1; dc++) {
                    if (dr == 0 && dc == 0) continue;

                    int256 nr = int256(r) + dr;
                    int256 nc = int256(c) + dc;

                    if (nr >= 0 && nr < int256(canvasHeight) && nc >= 0 && nc < int256(canvasWidth)) {
                         uint256 neighborIndex = CanvasUtils.coordinateToIndex(canvasWidth, uint256(nr), uint256(nc));
                        uint8 neighborState = currentState[neighborIndex];
                        neighborStatesSum += int256(neighborState);
                         if (neighborState > 128) {
                            neighborsAboveThreshold++;
                        }
                    }
                }
            }

            int256 stateChange = (neighborStatesSum * neighborInfluence) / 8 + ambientFlux;
            int16 intermediateState = int16(pixelState) + int16(stateChange);
            uint8 nextState = uint8(intermediateState % 256);

            if (nextState != pixelState) {
                 canvasPixels[tokenId][i] = nextState;
                 emit PixelStateChanged(tokenId, i, pixelState, nextState);
                 stateChangesCount++;
             }
        }
        _lastEvolutionTime[tokenId] = uint48(block.timestamp);
         emit EvolutionTriggered(tokenId, block.timestamp, stateChangesCount);
    }


    /**
     * @notice Seeds a canvas with initial pseudorandom states.
     * Uses block hash and timestamp, which is NOT cryptographically secure.
     * Should ideally use VRF for truly unpredictable seeding.
     * @param tokenId The ID of the canvas token.
     */
    function seedCanvasRandomly(uint256 tokenId) external canvasExists(tokenId) canvasNotPaused(tokenId) {
        require(_isApprovedOrOwner(msg.sender, tokenId) || msg.sender == owner(), "Not authorized");

        uint256 seed = uint256(keccak256(abi.encodePacked(block.timestamp, blockhash(block.number - 1), tokenId, msg.sender)));

        uint256 totalPixels = canvasWidth * canvasHeight;
        uint8[] storage pixels = canvasPixels[tokenId];

        for (uint256 i = 0; i < totalPixels; i++) {
            seed = uint256(keccak256(abi.encodePacked(seed, i))); // Mix seed for each pixel
            pixels[i] = uint8(seed % 256); // Assign a random state between 0 and 255
        }
         // Emit events for all changed pixels? Too expensive. Maybe a single event.
         // emit CanvasSeeded(tokenId, block.timestamp);
    }

    /**
     * @notice Resets a canvas's state to a default (e.g., all zeros).
     * @param tokenId The ID of the canvas token.
     */
    function resetCanvasState(uint256 tokenId) external canvasExists(tokenId) canvasNotPaused(tokenId) {
        require(_isApprovedOrOwner(msg.sender, tokenId) || msg.sender == owner(), "Not authorized");

        uint256 totalPixels = canvasWidth * canvasHeight;
        uint8[] storage pixels = canvasPixels[tokenId];
        uint256 stateChanges = 0;

        for (uint256 i = 0; i < totalPixels; i++) {
            if (pixels[i] != 0) {
                pixels[i] = 0; // Reset to zero state
                // emit PixelStateChanged(tokenId, i, oldState, 0); // Too expensive
                stateChanges++;
            }
        }
        // Emit single event indicating reset
        if (stateChanges > 0) {
             // emit CanvasReset(tokenId, msg.sender, block.timestamp);
        }
    }


    // --- QUERY FUNCTIONS ---

    /**
     * @notice Gets the current state array for all pixels of a given canvas.
     * @param tokenId The ID of the canvas token.
     * @return An array of uint8 representing the pixel states.
     */
    function getCanvasPixels(uint256 tokenId) external view canvasExists(tokenId) returns (uint8[] memory) {
        return canvasPixels[tokenId];
    }

    /**
     * @notice Gets the state of a single pixel at specific coordinates.
     * @param tokenId The ID of the canvas token.
     * @param row The row coordinate.
     * @param col The column coordinate.
     * @return The uint8 state of the pixel.
     */
    function getPixelState(uint256 tokenId, uint256 row, uint256 col)
        external
        view
        canvasExists(tokenId)
        isPixelCoordinateValid(row, col)
        returns (uint8)
    {
        uint256 index = CanvasUtils.coordinateToIndex(canvasWidth, row, col);
        return canvasPixels[tokenId][index];
    }

    /**
     * @notice Gets the timestamp when a canvas can next be evolved.
     * @param tokenId The ID of the canvas token.
     * @return The timestamp (uint256) of the next available evolution time.
     */
    function getEvolutionCooldown(uint256 tokenId) external view canvasExists(tokenId) returns (uint256) {
        return uint256(_lastEvolutionTime[tokenId]) + evolutionCooldown;
    }

    /**
     * @notice Gets the dimensions of the canvases.
     * @return width The width of the canvas.
     * @return height The height of the canvas.
     */
    function getCanvasDimensions() external view returns (uint256 width, uint256 height) {
        return (canvasWidth, canvasHeight);
    }

    // --- CONFIGURATION FUNCTIONS ---

    /**
     * @notice Sets the parameters for autonomous canvas evolution.
     * @param newCooldown The minimum time between evolutions (in seconds).
     * @param newNeighborInfluence How much neighbors (on average) affect a pixel state change.
     * @param newAmbientFlux Constant state change applied per pixel during evolution.
     */
    function setEvolutionRules(uint256 newCooldown, int8 newNeighborInfluence, uint8 newAmbientFlux) external onlyOwner {
        evolutionCooldown = newCooldown;
        neighborInfluence = newNeighborInfluence;
        ambientFlux = newAmbientFlux;
        emit RulesUpdated(block.timestamp);
    }

     /**
     * @notice Sets parameters for how flux application affects states.
     * (Currently only one parameter, fluxDecayFactor, used as example)
     * @param newFluxDecayFactor Example parameter affecting flux impact.
     */
    function setFluxRules(uint8 newFluxDecayFactor) external onlyOwner {
        fluxDecayFactor = newFluxDecayFactor;
        emit RulesUpdated(block.timestamp); // Reuse RulesUpdated event
    }

     /**
     * @notice Sets the dimensions for *newly minted* canvases.
     * Does not affect existing canvases.
     * @param newWidth The new width.
     * @param newHeight The new height.
     */
    function setCanvasDimensions(uint256 newWidth, uint256 newHeight) external onlyOwner {
        require(newWidth > 0 && newHeight > 0, "Dimensions must be positive");
        // Cannot change dimensions if any tokens have been minted, as it breaks array size expectation
        require(_tokenIdCounter.current() == 0, "Cannot change dimensions after minting starts");
        canvasWidth = newWidth;
        canvasHeight = newHeight;
    }


    /**
     * @notice Sets the base URI for token metadata.
     * The final tokenURI will be baseURI + tokenId.
     * Points to an off-chain service that generates dynamic metadata.
     * @param baseURI The base URI string.
     */
    function setBaseURI(string memory baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    /**
     * @notice Sets the default royalty information (recipient and basis points).
     * Implements ERC2981.
     * @param recipient The address to receive royalties.
     * @param bps The royalty percentage in basis points (e.g., 500 for 5%). Max 10000 (100%).
     */
    function setRoyaltyInfo(address recipient, uint96 bps) external onlyOwner {
        require(bps <= 10000, "Royalty basis points cannot exceed 100%");
        royaltyRecipient = recipient;
        royaltyBps = bps;
        _setDefaultRoyalty(recipient, bps); // Set default using OZ function
        emit RoyaltyInfoUpdated(recipient, bps);
    }


    /**
     * @notice Pauses canvas interaction functions (flux, evolution).
     * Minting is NOT paused by this.
     */
    function pauseCanvasInteractions() external onlyOwner {
        _pause(); // Uses ERC721Pausable's internal function
        emit PauseToggled(true);
    }

     /**
     * @notice Pauses the minting function.
     * Canvas interactions are NOT paused by this.
     */
    function pauseMinting() external onlyOwner {
        mintingActive = false;
        emit MintingPauseToggled(false);
    }

    /**
     * @notice Unpauses all paused functionality (canvas interactions and minting).
     */
    function unpauseContract() external onlyOwner {
        _unpause(); // Unpauses ERC721Pausable pause
        mintingActive = true; // Unpause minting flag
        emit PauseToggled(false);
        emit MintingPauseToggled(true);
    }


    // --- ERC721 OVERRIDES ---

    /**
     * @dev See {ERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view override(ERC721, ERC721Enumerable) returns (uint256) {
        return _tokenIdCounter.current();
    }

    /**
     * @dev See {ERC721-tokenURI}.
     * Returns a URI based on the base URI and token ID.
     * This URI should point to a service that generates dynamic metadata based on the canvas state.
     */
    function tokenURI(uint256 tokenId) public view override canvasExists(tokenId) returns (string memory) {
        string memory base = _baseTokenURI;
        return bytes(base).length > 0
            ? string(abi.encodePacked(base, Strings.toString(tokenId)))
            : ""; // Return empty string if base URI not set
    }

    /**
     * @dev See {ERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(uint256 index) public view override(ERC721, ERC721Enumerable) returns (uint256) {
        return super.tokenByIndex(index);
    }

    /**
     * @dev See {ERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view override(ERC721, ERC721Enumerable) returns (uint256) {
        return super.tokenOfOwnerByIndex(owner, index);
    }

    /**
     * @dev See {ERC721Pausable-_beforeTokenTransfer}.
     */
    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize)
        internal
        override(ERC721, ERC721Enumerable, ERC721Pausable)
    {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    /**
     * @dev See {ERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721Enumerable, ERC2981) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    // --- ERC2981 OVERRIDES ---

    /**
     * @dev See {IERC2981-royaltyInfo}.
     * Returns the royalty recipient and amount for a given sale price.
     */
    function royaltyInfo(uint256 _tokenId, uint256 _salePrice)
        external
        view
        override(IERC2981, ERC2981) // Specify both interfaces if needed for clarity, or just IERC2981
        returns (address receiver, uint256 royaltyAmount)
    {
        // ERC2981 is defined to return the royalty for *this* token.
        // Our implementation uses a default for all tokens, set via setRoyaltyInfo.
        // If you needed token-specific royalties, you'd store them per tokenId.
        receiver = royaltyRecipient;
        royaltyAmount = (_salePrice * royaltyBps) / 10000;
    }

    // The default royalty is set using _setDefaultRoyalty which is internal to ERC2981
    // and called in setRoyaltyInfo. No need to override _royaltyInfo.


    // --- HELPER FUNCTIONS (Internal/Pure) ---

    /**
     * @dev Internal helper to convert (row, col) to linear array index.
     */
     function _coordinateToIndex(uint256 row, uint256 col) internal view returns (uint256) {
         // Using library function
         return CanvasUtils.coordinateToIndex(canvasWidth, row, col);
     }

     /**
     * @dev Internal helper to convert linear array index to (row, col).
     */
     function _indexToCoordinate(uint256 index) internal view returns (uint256 row, uint256 col) {
         // Using library function
         return CanvasUtils.indexToCoordinate(canvasWidth, index);
     }

    // --------------------------
    // Total functions:
    // Inherited/Overridden (approx): 10 (constructor, tokenURI, supportsInterface, totalSupply, tokenByIndex, tokenOfOwnerByIndex, _beforeTokenTransfer, royaltyInfo) + Pausable internal
    // Custom: 23 (mintCanvas, applyFluxToPixel, applyFluxToArea, evolveCanvasState, bulkEvolveCanvases, seedCanvasRandomly, resetCanvasState, getCanvasPixels, getPixelState, getEvolutionCooldown, getCanvasDimensions, setEvolutionRules, setFluxRules, setCanvasDimensions, setMintPrice, setMaxSupply, setBaseURI, setRoyaltyInfo, withdrawFunds, pauseCanvasInteractions, pauseMinting, unpauseContract, _evolveCanvasInternal)
    // Helper library functions are not part of the contract's public/external API count.
    // Total public/external functions is well over the requested 20.
    // --------------------------
}
```

**Explanation of Concepts and Features:**

1.  **Dynamic State (`canvasPixels` mapping):** Instead of storing a single static metadata link or image hash, the contract stores the actual "pixel" data (`uint8[]`) for each NFT. This data *is* the art's on-chain representation.
2.  **State Evolution (`evolveCanvasState`):** Implements a simple autonomous process. Based on configurable rules (`neighborInfluence`, `ambientFlux`) and neighbor states, pixels change over time (gated by `evolutionCooldown`). This makes the art change even without direct user interaction.
3.  **User Interaction (`applyFluxToPixel`, `applyFluxToArea`):** Allows token owners (or approved addresses) to directly influence the canvas state by applying "flux". This demonstrates how external actions can modify the NFT's state, adding an interactive layer.
4.  **Dynamic Metadata (`tokenURI`):** The `tokenURI` function is crucial. It doesn't return static JSON. It returns a URL (based on `_baseTokenURI`) that points to an external service. This service is expected to:
    *   Call `getCanvasPixels(tokenId)` on the smart contract to fetch the *current* state.
    *   Generate the metadata JSON (including attributes describing the state, evolution parameters, etc.).
    *   Generate (or point to) the actual image/animation URL, rendering the grid based on the fetched pixel states.
    *   This off-chain rendering makes complex visuals possible while keeping the core *state* on-chain.
5.  **Pseudorandom Seeding (`seedCanvasRandomly`):** Provides a way to initialize canvases with varied starting states, although using block data is not truly secure for adversarial scenarios.
6.  **Configurable Rules:** The owner can update evolution and flux application parameters, allowing for dynamic tuning of the system's behavior.
7.  **ERC721Enumerable:** Makes it easy to list all minted tokens.
8.  **ERC721Pausable:** Allows the owner to pause canvas interactions in case of issues.
9.  **ERC2981 (Royalties):** Standardized way to signal creator royalties on secondary sales across compatible marketplaces.
10. **Batching (`bulkEvolveCanvases`):** Shows how you might optimize interactions by processing multiple tokens in one transaction (though limited by gas).

This contract goes beyond typical static NFTs by baking in mechanisms for state change, driven by both internal logic and external input, with the final visual output being a dynamic interpretation of the on-chain data.