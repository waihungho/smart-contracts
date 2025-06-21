Okay, here is a smart contract concept called "Quantum Canvas". It's an ERC-721 based system where users own unique "Quantum Pixels" on a large conceptual grid. These pixels have dynamic properties (Energy, Charge) that decay over time and can be influenced by interactions with other pixels ("Resonance"), calculated off-chain and applied on-chain for gas efficiency. There's also a global "Quantum State" that shifts, potentially affecting all pixels.

This contract incorporates:
1.  **ERC-721:** Standard NFT ownership of pixels.
2.  **Spatial Data:** Pixels exist at coordinates.
3.  **Dynamic Properties:** Energy and Charge decay based on time.
4.  **Interactive System:** Pixels can be boosted (Energy/Charge) by owners.
5.  **Complex Interaction (Off-chain/On-chain):** Resonance effects between nearby pixels are calculated off-chain but applied on-chain via a dedicated function, allowing for complex "physics" without excessive gas costs for storage/computation loops within a single transaction triggered by a user action.
6.  **Global State:** A "Quantum State" that changes and can influence pixel properties.
7.  **Pausable:** Standard safety mechanism.
8.  **Ownership/Admin:** Basic access control for configuration and fee withdrawal.
9.  **Multiple Functions:** Well over the required 20 functions implementing the core logic, ERC721 standard methods, view functions, and admin controls.

---

**Outline and Function Summary**

**Contract Name:** QuantumCanvas

**Concept:** An ERC-721 NFT contract representing unique "Quantum Pixels" on a large 2D grid. Pixels have dynamic `energy` and `charge` properties that decay over time. Nearby pixels can resonate and influence each other's properties. A global `quantumState` also influences pixels. Complex resonance calculations are performed off-chain and applied on-chain via a dedicated function.

**Key Features:**
*   Own unique pixels as NFTs.
*   Pixels have coordinates (x, y), color, energy, and charge.
*   Energy and charge decay based on time elapsed since last interaction.
*   Pixels can be 'charged' or 'boosted' by the owner to restore properties.
*   Resonance effects between nearby pixels (calculated off-chain) can update base properties.
*   A global quantum state that shifts and can apply broad effects.
*   Admin controls for configuration and fee withdrawal.
*   Pausable contract state.

**State Variables:**
*   `pixels`: Maps token ID to `Pixel` struct data.
*   `_coordinatesToTokenId`: Maps a coordinate key (x, y encoded) to a token ID.
*   `_tokenIdToCoordinates`: Maps token ID to a coordinate key.
*   `_canvasState`: Represents the global quantum state.
*   `_lastQuantumShiftTime`: Timestamp of the last global state shift.
*   `_resonanceFactor`: Configuration for resonance effect strength.
*   `_decayRate`: Configuration for property decay rate.
*   `_basePlacementCost`: Cost to place a new pixel.
*   `_totalPixelsMinted`: Counter for total pixels created.
*   `canvasWidth`, `canvasHeight`: Dimensions of the grid.

**Structs:**
*   `Pixel`: Stores pixel properties (coordinates, color, baseEnergy, baseCharge, lastInteractionTime). Note: `baseEnergy` and `baseCharge` are the stored values before decay calculation.

**Events:**
*   `PixelPlaced`: Emitted when a new pixel is minted and placed.
*   `PixelPropertiesUpdated`: Emitted when pixel energy/charge base values are updated (via boost, charge, or resonance).
*   `QuantumShiftOccurred`: Emitted when the global quantum state shifts.
*   `ResonanceAppliedOnChain`: Emitted when off-chain calculated resonance effects are applied.
*   `FeesWithdrawn`: Emitted when admin withdraws fees.
*   `Paused`: Emitted when contract is paused.
*   `Unpaused`: Emitted when contract is unpaused.

**Modifiers:**
*   `onlyOwner`: Restricts access to the contract owner.
*   `whenNotPaused`: Prevents execution when contract is paused.
*   `whenPaused`: Allows execution only when contract is paused.
*   `validCoordinates`: Checks if provided coordinates are within canvas bounds.

**Function Summary:**

**ERC-721 Standard Functions (8):**
1.  `balanceOf(address owner) view returns (uint256)`: Returns the number of tokens owned by an address.
2.  `ownerOf(uint256 tokenId) view returns (address)`: Returns the owner of a specific token.
3.  `approve(address to, uint256 tokenId)`: Approves another address to transfer a specific token.
4.  `getApproved(uint256 tokenId) view returns (address)`: Returns the approved address for a specific token.
5.  `setApprovalForAll(address operator, bool approved)`: Approves/disapproves an operator for all tokens of the caller.
6.  `isApprovedForAll(address owner, address operator) view returns (bool)`: Checks if an operator is approved for an owner.
7.  `transferFrom(address from, address to, uint256 tokenId)`: Transfers a token from one address to another (requires approval/ownership).
8.  `safeTransferFrom(address from, address to, uint256 tokenId)` / `safeTransferFrom(address from, address to, uint256 tokenId, bytes data)`: Safer versions of transferFrom, includes receiver checks.

**Quantum Canvas Core Functions (Custom):**
9.  `placePixel(uint16 x, uint16 y, uint24 color) payable whenNotPaused`: Mints a new Quantum Pixel NFT at specified coordinates, requires payment.
10. `getPixelDetails(uint256 tokenId) view returns (PixelDetails)`: Returns a struct containing all current, calculated details of a pixel (including decayed energy/charge).
11. `getCalculatedEnergy(uint256 tokenId) view returns (uint256)`: Returns the current energy of a pixel after applying decay.
12. `getCalculatedCharge(uint256 tokenId) view returns (int256)`: Returns the current charge of a pixel after applying decay.
13. `chargePixel(uint256 tokenId) payable whenNotPaused`: Increases the base charge of a pixel, requires payment.
14. `boostEnergy(uint256 tokenId) payable whenNotPaused`: Increases the base energy of a pixel, requires payment.
15. `updatePixelPropertiesByResonance(uint256 tokenId, int256 energyDelta, int256 chargeDelta) onlyOwner whenNotPaused`: Applies energy and charge changes calculated by an off-chain process (resonance).
16. `triggerQuantumShift() onlyOwner whenNotPaused`: Advances the global `_canvasState`.
17. `getCanvasState() view returns (int256)`: Returns the current global quantum state.
18. `getPixelCoordinates(uint256 tokenId) view returns (uint16, uint16)`: Returns the (x, y) coordinates of a pixel.
19. `getPixelColor(uint256 tokenId) view returns (uint24)`: Returns the color of a pixel.
20. `getPixelBaseEnergy(uint256 tokenId) view returns (uint256)`: Returns the stored base energy before decay.
21. `getPixelBaseCharge(uint256 tokenId) view returns (int256)`: Returns the stored base charge before decay.
22. `getPixelsInArea(uint16 x1, uint16 y1, uint16 x2, uint16 y2) view returns (uint256[] memory)`: Returns an array of token IDs within a bounding box.
23. `getTotalSupply() view returns (uint256)`: Returns the total number of pixels minted.
24. `getLastQuantumShiftTime() view returns (uint48)`: Returns the timestamp of the last quantum shift.
25. `getCoordinatesTokenId(uint16 x, uint16 y) view returns (uint256)`: Returns the token ID at specific coordinates (0 if empty).

**Admin/Configuration Functions (Custom):**
26. `setResonanceFactor(uint16 factor) onlyOwner`: Sets the resonance factor configuration.
27. `setDecayRate(uint16 rate) onlyOwner`: Sets the decay rate configuration.
28. `setBasePlacementCost(uint256 cost) onlyOwner`: Sets the cost for placing a new pixel.
29. `withdrawFees() onlyOwner`: Withdraws accumulated contract balance (from pixel placement/boosting fees) to the owner.
30. `pause() onlyOwner whenNotPaused`: Pauses contract interactions.
31. `unpause() onlyOwner whenPaused`: Unpauses contract interactions.
32. `getResonanceFactor() view returns (uint16)`: Returns the current resonance factor.
33. `getDecayRate() view returns (uint16)`: Returns the current decay rate.
34. `getBasePlacementCost() view returns (uint256)`: Returns the current base placement cost.
35. `getCanvasDimensions() view returns (uint16, uint16)`: Returns the canvas width and height.

**(Total Functions: 8 standard + 27 custom = 35)**

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

// --- Outline and Function Summary ---
// See above description for detailed outline and function summary.
// In short:
// Contract Name: QuantumCanvas (ERC-721 NFT for pixels on a grid)
// Features: ERC-721, Spatial Data, Dynamic Properties (Decay), Interactive (Charge/Boost),
//           Off-chain/On-chain Resonance Application, Global Quantum State, Pausable, Admin Controls.
// State Variables: pixels, coordinate mappings, canvas state, config params, counters.
// Structs: Pixel (details including base properties)
// Events: PixelPlaced, PixelPropertiesUpdated, QuantumShiftOccurred, ResonanceAppliedOnChain, FeesWithdrawn, Paused, Unpaused.
// Modifiers: onlyOwner, whenNotPaused, whenPaused, validCoordinates.
// Function Categories:
//   - ERC-721 Standard (8 functions)
//   - Quantum Canvas Core (Custom - ~17 functions for placement, getters, dynamic properties, state changes)
//   - Admin/Configuration (Custom - ~10 functions for settings, withdrawal, pause)
// Total Functions: ~35 functions.

contract QuantumCanvas is ERC721, Ownable, Pausable {

    struct Pixel {
        uint16 x;
        uint16 y;
        uint24 color; // RGB color, e.g., 0xFF0000 for red
        uint256 baseEnergy; // Stored energy value before decay
        int256 baseCharge;   // Stored charge value before decay (can be negative)
        uint48 lastInteractionTime; // Timestamp of last update (charge, boost, resonance, placement)
    }

    // Mapping from tokenId to Pixel data
    mapping(uint256 => Pixel) private _tokenDetails;

    // Mapping from (x, y) coordinates (encoded as uint64) to tokenId
    mapping(uint64 => uint256) private _coordinatesToTokenId;

    // Mapping from tokenId to (x, y) coordinates (encoded as uint64)
    mapping(uint256 => uint64) private _tokenIdToCoordinates;

    // Global canvas state, influenced by quantum shifts
    int256 private _canvasState;
    uint48 private _lastQuantumShiftTime;

    // Configuration parameters
    uint16 public _resonanceFactor; // Multiplier for resonance effect (e.g., 100 = 1x, 50 = 0.5x)
    uint16 public _decayRate;       // Percentage decay per unit time (e.g., 100 = 1% decay per unit time)
    uint256 public _basePlacementCost; // Cost in Wei to place a new pixel

    // Canvas dimensions
    uint16 public immutable canvasWidth;
    uint16 public immutable canvasHeight;

    // Time unit for decay calculation (e.g., seconds per decay unit)
    uint256 private constant TIME_UNIT = 1 days; // Decay calculated per day

    // Pixel ID counter
    uint256 private _tokenIdCounter;

    // Events
    event PixelPlaced(uint256 indexed tokenId, address indexed owner, uint16 x, uint16 y, uint24 color);
    event PixelPropertiesUpdated(uint256 indexed tokenId, uint256 newBaseEnergy, int256 newBaseCharge, uint48 updateTime);
    event QuantumShiftOccurred(int256 newCanvasState, uint48 timestamp);
    event ResonanceAppliedOnChain(uint256 indexed tokenId, int256 energyDelta, int256 chargeDelta);
    event FeesWithdrawn(address indexed recipient, uint256 amount);

    // Modifiers
    modifier validCoordinates(uint16 x, uint16 y) {
        require(x < canvasWidth && y < canvasHeight, "Invalid coordinates");
        _;
    }

    constructor(string memory name, string memory symbol, uint16 width, uint16 height, uint256 initialPlacementCost)
        ERC721(name, symbol)
        Ownable(msg.sender)
    {
        require(width > 0 && height > 0, "Canvas dimensions must be positive");
        canvasWidth = width;
        canvasHeight = height;
        _basePlacementCost = initialPlacementCost;
        _resonanceFactor = 10000; // Default 1x
        _decayRate = 1000;      // Default 10% per time unit
        _canvasState = 0;
        _lastQuantumShiftTime = uint48(block.timestamp);
        _tokenIdCounter = 0;
    }

    // --- Coordinate Encoding/Decoding ---
    function _encodeCoordinates(uint16 x, uint16 y) internal pure returns (uint64) {
        return (uint64(x) << 32) | y;
    }

    function _decodeCoordinates(uint64 encodedCoords) internal pure returns (uint16 x, uint16 y) {
        x = uint16(encodedCoords >> 32);
        y = uint16(encodedCoords);
    }

    // --- Pixel Property Calculation (with Decay) ---
    function _calculateCurrentEnergy(uint256 baseEnergy, uint48 lastTime) internal view returns (uint256) {
        uint256 timeElapsed = block.timestamp - lastTime;
        uint256 decayMultiplier = 10000; // Represents 100%
        if (timeElapsed > 0 && _decayRate > 0) {
            uint256 decayAmount = (baseEnergy * _decayRate * (timeElapsed / TIME_UNIT)) / 10000;
            return baseEnergy >= decayAmount ? baseEnergy - decayAmount : 0;
        }
        return baseEnergy;
    }

    function _calculateCurrentCharge(int256 baseCharge, uint48 lastTime) internal view returns (int256) {
         uint256 timeElapsed = block.timestamp - lastTime;
         if (timeElapsed > 0 && _decayRate > 0) {
             uint256 decaySteps = timeElapsed / TIME_UNIT;
             // Decay towards zero. Positive charge decreases, negative charge increases towards zero.
             if (baseCharge > 0) {
                  uint256 decayAmount = (uint256(baseCharge) * _decayRate * decaySteps) / 10000;
                  return baseCharge >= int256(decayAmount) ? baseCharge - int256(decayAmount) : 0;
             } else if (baseCharge < 0) {
                  uint256 decayAmount = (uint256(-baseCharge) * _decayRate * decaySteps) / 10000;
                  return baseCharge + int256(decayAmount) <= 0 ? baseCharge + int256(decayAmount) : 0;
             }
         }
         return baseCharge;
    }

    // --- ERC-721 Standard Functions (Implemented by OpenZeppelin) ---
    // balanceOf, ownerOf, approve, getApproved, setApprovalForAll, isApprovedForAll, transferFrom, safeTransferFrom

    // --- Custom Functions ---

    /// @notice Mints a new Quantum Pixel NFT at specific coordinates.
    /// @param x The x-coordinate of the pixel.
    /// @param y The y-coordinate of the pixel.
    /// @param color The RGB color of the pixel (0xRRGGBB).
    function placePixel(uint16 x, uint16 y, uint24 color)
        external
        payable
        whenNotPaused
        validCoordinates(x, y)
    {
        uint64 encodedCoords = _encodeCoordinates(x, y);
        require(_coordinatesToTokenId[encodedCoords] == 0, "Coordinates already occupied");
        require(msg.value >= _basePlacementCost, "Insufficient payment to place pixel");

        unchecked {
            _tokenIdCounter++;
        }
        uint256 newTokenId = _tokenIdCounter;

        _mint(msg.sender, newTokenId);

        _tokenDetails[newTokenId] = Pixel({
            x: x,
            y: y,
            color: color,
            baseEnergy: 0, // Start with 0 base energy/charge
            baseCharge: 0,
            lastInteractionTime: uint48(block.timestamp)
        });

        _coordinatesToTokenId[encodedCoords] = newTokenId;
        _tokenIdToCoordinates[newTokenId] = encodedCoords;

        emit PixelPlaced(newTokenId, msg.sender, x, y, color);
        // Any surplus payment remains in the contract balance
    }

    /// @notice Represents the detailed state of a pixel, including calculated dynamic properties.
    struct PixelDetails {
        uint256 tokenId;
        uint16 x;
        uint16 y;
        uint24 color;
        uint256 currentEnergy; // Calculated after decay
        int256 currentCharge;   // Calculated after decay
        uint256 baseEnergy; // Stored base value
        int256 baseCharge;   // Stored base value
        uint48 lastInteractionTime;
        address owner;
    }

    /// @notice Gets all details for a specific pixel token.
    /// @param tokenId The ID of the pixel token.
    /// @return PixelDetails struct containing all pixel data.
    function getPixelDetails(uint256 tokenId) public view returns (PixelDetails memory) {
        require(_exists(tokenId), "Token does not exist");
        Pixel storage pixel = _tokenDetails[tokenId];

        uint256 currentEnergy = _calculateCurrentEnergy(pixel.baseEnergy, pixel.lastInteractionTime);
        int256 currentCharge = _calculateCurrentCharge(pixel.baseCharge, pixel.lastInteractionTime);

        return PixelDetails({
            tokenId: tokenId,
            x: pixel.x,
            y: pixel.y,
            color: pixel.color,
            currentEnergy: currentEnergy,
            currentCharge: currentCharge,
            baseEnergy: pixel.baseEnergy,
            baseCharge: pixel.baseCharge,
            lastInteractionTime: pixel.lastInteractionTime,
            owner: ownerOf(tokenId)
        });
    }

    /// @notice Gets the current energy of a pixel after applying decay.
    /// @param tokenId The ID of the pixel token.
    /// @return The calculated current energy.
    function getCalculatedEnergy(uint256 tokenId) public view returns (uint256) {
        require(_exists(tokenId), "Token does not exist");
        Pixel storage pixel = _tokenDetails[tokenId];
        return _calculateCurrentEnergy(pixel.baseEnergy, pixel.lastInteractionTime);
    }

    /// @notice Gets the current charge of a pixel after applying decay.
    /// @param tokenId The ID of the pixel token.
    /// @return The calculated current charge.
    function getCalculatedCharge(uint256 tokenId) public view returns (int256) {
        require(_exists(tokenId), "Token does not exist");
        Pixel storage pixel = _tokenDetails[tokenId];
        return _calculateCurrentCharge(pixel.baseCharge, pixel.lastInteractionTime);
    }


    /// @notice Increases the base charge of a pixel.
    /// @param tokenId The ID of the pixel token.
    function chargePixel(uint256 tokenId) external payable whenNotPaused {
        require(_isApprovedOrOwner(msg.sender, tokenId), "Not authorized to charge this pixel");
        // Require some minimum payment or a payment structure here if needed
        require(msg.value > 0, "Must send value to charge pixel"); // Example: minimum charge fee
        // Logic to calculate charge increase based on msg.value would go here
        // For simplicity, let's just add a fixed amount for now and consume value
        uint256 chargeIncrease = msg.value / 1e15; // Example: 1 finney adds 1000 charge

        Pixel storage pixel = _tokenDetails[tokenId];
        pixel.baseCharge = pixel.baseCharge + int256(chargeIncrease); // Be careful with overflow
        pixel.lastInteractionTime = uint48(block.timestamp);

        emit PixelPropertiesUpdated(tokenId, pixel.baseEnergy, pixel.baseCharge, pixel.lastInteractionTime);
    }

    /// @notice Increases the base energy of a pixel.
    /// @param tokenId The ID of the pixel token.
    function boostEnergy(uint256 tokenId) external payable whenNotPaused {
        require(_isApprovedOrOwner(msg.sender, tokenId), "Not authorized to boost this pixel");
         require(msg.value > 0, "Must send value to boost energy"); // Example: minimum boost fee
        // Logic to calculate energy increase based on msg.value
        uint256 energyIncrease = msg.value / 1e15; // Example: 1 finney adds 1000 energy

        Pixel storage pixel = _tokenDetails[tokenId];
        pixel.baseEnergy = pixel.baseEnergy + energyIncrease; // Be careful with overflow
        pixel.lastInteractionTime = uint48(block.timestamp);

        emit PixelPropertiesUpdated(tokenId, pixel.baseEnergy, pixel.baseCharge, pixel.lastInteractionTime);
    }

    /// @notice Applies calculated resonance effects to a pixel's base properties.
    /// @dev This function is intended to be called by a trusted off-chain process
    /// (e.g., a keeper or computation oracle) after calculating complex resonance interactions.
    /// @param tokenId The ID of the pixel token.
    /// @param energyDelta The amount to change the base energy (can be negative).
    /// @param chargeDelta The amount to change the base charge (can be negative).
    function updatePixelPropertiesByResonance(uint256 tokenId, int256 energyDelta, int256 chargeDelta)
        external
        onlyOwner // Only the owner/trusted role can apply resonance updates
        whenNotPaused
    {
        require(_exists(tokenId), "Token does not exist");
        Pixel storage pixel = _tokenDetails[tokenId];

        // Apply deltas, ensuring energy doesn't go below zero
        if (energyDelta < 0) {
            uint256 energyDecrease = uint256(-energyDelta);
            pixel.baseEnergy = pixel.baseEnergy >= energyDecrease ? pixel.baseEnergy - energyDecrease : 0;
        } else {
            pixel.baseEnergy = pixel.baseEnergy + uint256(energyDelta);
        }

        // Apply charge delta
        pixel.baseCharge = pixel.baseCharge + chargeDelta; // Be careful with overflow potential in real app

        pixel.lastInteractionTime = uint48(block.timestamp);

        emit PixelPropertiesUpdated(tokenId, pixel.baseEnergy, pixel.baseCharge, pixel.lastInteractionTime);
        emit ResonanceAppliedOnChain(tokenId, energyDelta, chargeDelta);
    }

    /// @notice Triggers a global quantum state shift.
    /// @dev The logic for how the state shifts can be complex. For simplicity, this increments or applies a formula.
    function triggerQuantumShift()
        external
        onlyOwner // Can be restricted or made permissionless with cost
        whenNotPaused
    {
        // Example simple shift: increment state, perhaps based on time or pixel count
        _canvasState = _canvasState + 1; // Or calculate based on total energy/charge, etc.
        _lastQuantumShiftTime = uint48(block.timestamp);

        // Potential: Apply a uniform effect to all pixels based on the new state
        // (Gas-intensive, might need batching or off-chain processing)
        // For this example, the state change itself is the primary effect.

        emit QuantumShiftOccurred(_canvasState, _lastQuantumShiftTime);
    }

    /// @notice Gets the current global quantum state.
    /// @return The current quantum state value.
    function getCanvasState() public view returns (int256) {
        return _canvasState;
    }

    /// @notice Gets the coordinates of a specific pixel token.
    /// @param tokenId The ID of the pixel token.
    /// @return The x and y coordinates.
    function getPixelCoordinates(uint256 tokenId) public view returns (uint16, uint16) {
        require(_exists(tokenId), "Token does not exist");
        uint64 encodedCoords = _tokenIdToCoordinates[tokenId];
        return _decodeCoordinates(encodedCoords);
    }

    /// @notice Gets the color of a specific pixel token.
    /// @param tokenId The ID of the pixel token.
    /// @return The RGB color value.
    function getPixelColor(uint256 tokenId) public view returns (uint24) {
         require(_exists(tokenId), "Token does not exist");
         return _tokenDetails[tokenId].color;
    }

    /// @notice Gets the stored base energy of a pixel (before decay calculation).
    /// @param tokenId The ID of the pixel token.
    /// @return The stored base energy.
    function getPixelBaseEnergy(uint256 tokenId) public view returns (uint256) {
        require(_exists(tokenId), "Token does not exist");
        return _tokenDetails[tokenId].baseEnergy;
    }

     /// @notice Gets the stored base charge of a pixel (before decay calculation).
    /// @param tokenId The ID of the pixel token.
    /// @return The stored base charge.
    function getPixelBaseCharge(uint256 tokenId) public view returns (int256) {
        require(_exists(tokenId), "Token does not exist");
        return _tokenDetails[tokenId].baseCharge;
    }

    /// @notice Gets the token ID at specific coordinates.
    /// @param x The x-coordinate.
    /// @param y The y-coordinate.
    /// @return The token ID at (x, y), or 0 if empty.
    function getCoordinatesTokenId(uint16 x, uint16 y)
        public
        view
        validCoordinates(x, y)
        returns (uint256)
    {
        uint64 encodedCoords = _encodeCoordinates(x, y);
        return _coordinatesToTokenId[encodedCoords];
    }


    /// @notice Gets a list of token IDs within a rectangular area.
    /// @dev Note: This can be gas-intensive for large areas. Consider off-chain indexing for performance.
    /// @param x1 The x-coordinate of the top-left corner.
    /// @param y1 The y-coordinate of the top-left corner.
    /// @param x2 The x-coordinate of the bottom-right corner.
    /// @param y2 The y-coordinate of the bottom-right corner.
    /// @return An array of token IDs found within the area.
    function getPixelsInArea(uint16 x1, uint16 y1, uint16 x2, uint16 y2)
        public
        view
        validCoordinates(x1, y1)
        validCoordinates(x2, y2)
        returns (uint256[] memory)
    {
        // Ensure x1 <= x2 and y1 <= y2
        uint16 minX = x1 < x2 ? x1 : x2;
        uint16 maxX = x1 > x2 ? x1 : x2;
        uint16 minY = y1 < y2 ? y1 : y2;
        uint16 maxY = y1 > y2 ? y1 : y2;

        uint256[] memory tokenIds = new uint256[](0);
        uint256 count = 0;

        // WARNING: Iterating over potentially large areas on-chain is gas-intensive.
        // This is included to meet function count but is inefficient for production use.
        // Off-chain indexers should be used to query areas efficiently.
        for (uint16 x = minX; x <= maxX; x++) {
            for (uint16 y = minY; y <= maxY; y++) {
                 uint64 encodedCoords = _encodeCoordinates(x, y);
                 uint256 tokenId = _coordinatesToTokenId[encodedCoords];
                 if (tokenId != 0) {
                     // Dynamically growing arrays are gas-inefficient.
                     // A better approach might be to return a maximum batch or require off-chain query.
                     // For demonstration, resizing here:
                     assembly {
                         let newLength := add(count, 1)
                         let newArray := mload(0x40) // Get free memory pointer
                         mstore(0x40, add(newArray, mul(newLength, 0x20))) // Update free memory pointer

                         // Copy old array data to new array
                         let oldArray := mload(tokenIds)
                         if gt(count, 0) {
                             let oldData := add(oldArray, 0x20) // Start of old data
                             let newData := add(newArray, 0x20) // Start of new data
                             let dataSize := mul(count, 0x20)   // Size of data in bytes
                             // Use memory copying loop (optimized in recent compilers) or manual loop
                             // Here's a simple manual loop example:
                             for {} lt(0, dataSize) { dataSize := sub(dataSize, 0x20) } {
                                 mstore(newData, mload(oldData))
                                 oldData := add(oldData, 0x20)
                                 newData := add(newData, 0x20)
                             }
                         }

                         // Store the new tokenId at the end
                         mstore(add(newArray, mul(count, 0x20)), tokenId)
                         // Update the header to the new length
                         mstore(newArray, newLength)
                         // Update the tokenIds variable to point to the new array
                         mstore(tokenIds, newArray)
                     }
                     count++;
                 }
            }
        }
         // This assembly block is a highly simplified example of resizing and copying.
         // In practice, avoid dynamic memory arrays or use safer libraries/patterns.
         // The simple solution for this example is to return a fixed-size array or max limit,
         // but dynamic resizing is shown here for complexity, despite being inefficient.

        return tokenIds;
    }


    /// @notice Gets the total number of pixels minted.
    /// @return The total supply.
    function getTotalSupply() public view returns (uint256) {
        return _tokenIdCounter;
    }

    /// @notice Gets the timestamp of the last global quantum shift.
    /// @return The timestamp (in uint48 format).
    function getLastQuantumShiftTime() public view returns (uint48) {
        return _lastQuantumShiftTime;
    }

    // --- Admin/Configuration Functions ---

    /// @notice Sets the resonance factor configuration.
    /// @param factor The new resonance factor (e.g., 10000 for 1x).
    function setResonanceFactor(uint16 factor) external onlyOwner {
        _resonanceFactor = factor;
    }

    /// @notice Sets the decay rate configuration.
    /// @param rate The new decay rate (e.g., 1000 for 10% per time unit).
    function setDecayRate(uint16 rate) external onlyOwner {
        _decayRate = rate;
    }

    /// @notice Sets the base cost for placing a new pixel.
    /// @param cost The new cost in Wei.
    function setBasePlacementCost(uint256 cost) external onlyOwner {
        _basePlacementCost = cost;
    }

    /// @notice Allows the owner to withdraw accumulated fees.
    function withdrawFees() external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No balance to withdraw");
        (bool success, ) = payable(owner()).call{value: balance}("");
        require(success, "Withdrawal failed");
        emit FeesWithdrawn(owner(), balance);
    }

    /// @notice Pauses contract interactions.
    function pause() external onlyOwner whenNotPaused {
        _pause();
    }

    /// @notice Unpauses contract interactions.
    function unpause() external onlyOwner whenPaused {
        _unpause();
    }

    /// @notice Returns the current resonance factor.
    function getResonanceFactor() public view returns (uint16) {
        return _resonanceFactor;
    }

    /// @notice Returns the current decay rate.
    /// @return The decay rate (percentage / 100).
    function getDecayRate() public view returns (uint16) {
        return _decayRate;
    }

    /// @notice Returns the current base cost for placing a pixel.
    /// @return The cost in Wei.
    function getBasePlacementCost() public view returns (uint256) {
        return _basePlacementCost;
    }

    /// @notice Returns the canvas dimensions.
    /// @return The canvas width and height.
     function getCanvasDimensions() public view returns (uint16, uint16) {
         return (canvasWidth, canvasHeight);
     }


    // The following functions are overrides required by Solidity.
    // They are part of the ERC721 standard implementation.
    // We explicitly list them here but their logic is handled by OpenZeppelin's ERC721 base contract.

    // Override to add Pausable check to transfers
    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize)
        internal
        whenNotPaused
        override(ERC721)
    {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);

        // Additional logic specific to QuantumCanvas before transfer
        // If transferring a pixel, potentially remove it from the coordinate mapping?
        // Or is the pixel data tied to the token ID and moves with it?
        // Let's assume the pixel data is tied to the token and its position is fixed on the canvas.
        // The token represents ownership *of* the spot (x,y).
        // If the pixel state (energy/charge) should reset on transfer, add that here.
        // For this concept, let's keep position and base properties linked to the tokenID.
        // Resetting decay time might be appropriate:
        if (from != address(0)) { // Not a mint
            Pixel storage pixel = _tokenDetails[tokenId];
            pixel.lastInteractionTime = uint48(block.timestamp);
             emit PixelPropertiesUpdated(tokenId, pixel.baseEnergy, pixel.baseCharge, pixel.lastInteractionTime);
        }
    }

    // Override to handle metadata URI if needed (using _baseURI or tokenURI)
    // function tokenURI(uint256 tokenId) public view override(ERC721) returns (string memory) {
    //     // Implement logic to generate metadata URI based on pixel data
    //     // Requires string manipulation or integration with an external service
    //     // Returning empty string for simplicity in this example
    //     require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
    //     return "";
    // }

     // Override to ensure coordinates are freed if token is burned
     function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        override(ERC721) // Call super from non-batch version
     {
         super._beforeTokenTransfer(from, to, tokenId);

         if (to == address(0)) { // Burning token
              uint64 encodedCoords = _tokenIdToCoordinates[tokenId];
              delete _coordinatesToTokenId[encodedCoords];
              delete _tokenIdToCoordinates[tokenId];
              // Pixel data remains in _tokenDetails mapping but won't be reachable via _exists()
              // Or you could delete _tokenDetails[tokenId] explicitly if state should be wiped
              // delete _tokenDetails[tokenId]; // Optional: clear pixel data on burn
         } else if (from != address(0)) { // Transfer, not mint
             // Reset decay time on transfer
             Pixel storage pixel = _tokenDetails[tokenId];
             pixel.lastInteractionTime = uint48(block.timestamp);
             emit PixelPropertiesUpdated(tokenId, pixel.baseEnergy, pixel.baseCharge, pixel.lastInteractionTime);
         }
     }

     // Need to override the batch version as well, calling the single token version
     function _beforeTokenTransfer(address from, address to, uint256[] memory tokenIds, uint256 batchSize)
        internal
        override(ERC721) // Call super from batch version
     {
         for (uint256 i = 0; i < batchSize; i++) {
             _beforeTokenTransfer(from, to, tokenIds[i]); // Call the single token version for each token
         }
     }

}
```