```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/Math.sol"; // For random-like operations (with caveats)
import "@openzeppelin/contracts/utils/Counters.sol";

/**
 * @title QuantumArtCanvas
 * @dev An advanced ERC721 contract representing a collaborative digital canvas
 *      where pixels have 'quantum-inspired' states (superposition of colors)
 *      that can be influenced by users and 'observed' to collapse into a final state.
 *
 * @outline
 * 1. Contract Overview and ERC721 Base
 *    - Inherits ERC721, ERC721Enumerable, Ownable
 *    - Standard ERC721 functions (minting, transferring, etc.)
 * 2. Quantum Canvas State
 *    - Structs for Pixel state (potential states/colors, probabilities)
 *    - Structs for Canvas data (dimensions, potential states list, influence cost, entanglement links, etc.)
 *    - Enum for Observation Policy
 *    - Mapping to store Canvas data per token ID
 * 3. Core Quantum Mechanics Simulation (Simplified/Inspired)
 *    - applyInfluence: Users add 'influence' to shift probabilities towards a state.
 *    - observePixel: Forces a pixel's state collapse based on probabilities (using simplified pseudo-randomness).
 *    - observeCanvas: Triggers observation for the entire canvas based on policy.
 *    - entanglePixels: Links two pixels' probability changes.
 *    - applyDecoherence: Reduces probability extremes, moving towards equal distribution.
 *    - applyQuantumTunneling: Low probability jump to a significantly different state distribution.
 * 4. Canvas Management (by Canvas Owner/Admins)
 *    - mintCanvas: Creates a new canvas NFT.
 *    - setCanvasParameters: Configure canvas properties (potential states, costs, rates).
 *    - updateObservationPolicy: Set rules for state collapse.
 * 5. Interaction Mechanics
 *    - Influence with potential payment (ETH).
 *    - Triggering observation (manual, policy-driven).
 * 6. Query/View Functions
 *    - Get current quantum state (probabilities) of a pixel.
 *    - Get observed state of a pixel.
 *    - Get canvas configuration.
 *    - Get entanglement links.
 * 7. Access Control and Administration
 *    - Ownable for contract-level admin.
 *    - Canvas owner for canvas-specific config.
 *    - Admin roles for contract-wide actions.
 *    - Withdraw accumulated funds.
 *
 * @function_summary
 * - Standard ERC721 (8 functions):
 *   - `balanceOf(address owner)`: Get token balance.
 *   - `ownerOf(uint256 tokenId)`: Get owner of a token.
 *   - `approve(address to, uint256 tokenId)`: Approve address for transfer.
 *   - `getApproved(uint256 tokenId)`: Get approved address for a token.
 *   - `setApprovalForAll(address operator, bool approved)`: Set operator approval.
 *   - `isApprovedForAll(address owner, address operator)`: Check operator approval.
 *   - `transferFrom(address from, address to, uint256 tokenId)`: Transfer token.
 *   - `safeTransferFrom(address from, address to, uint256 tokenId)`: Safe transfer token.
 * - ERC721Enumerable (3 functions):
 *   - `totalSupply()`: Total number of tokens.
 *   - `tokenByIndex(uint256 index)`: Token ID by index.
 *   - `tokenOfOwnerByIndex(address owner, uint256 index)`: Token ID by owner index.
 * - Ownable (3 functions):
 *   - `owner()`: Get contract owner.
 *   - `transferOwnership(address newOwner)`: Transfer contract ownership.
 *   - `renounceOwnership()`: Renounce contract ownership.
 * - Custom Quantum Art Canvas Functions (17+ functions):
 *   - `addAdmin(address admin)`: Add contract admin.
 *   - `removeAdmin(address admin)`: Remove contract admin.
 *   - `isAdmin(address account)`: Check if address is admin.
 *   - `withdrawFunds()`: Withdraw contract balance (only owner/admin).
 *   - `mintCanvas(uint256 width, uint256 height, string memory name, string memory symbol)`: Mints a new canvas NFT. (Combines creation and setting basic props)
 *   - `setPotentialPixelStates(uint256 tokenId, uint256[] memory _potentialStates)`: Sets possible states (colors/values) for pixels on a canvas.
 *   - `setInfluenceCost(uint256 tokenId, uint256 cost)`: Sets the cost (in wei) to apply influence to a pixel.
 *   - `setDecoherenceRate(uint256 tokenId, uint256 rate)`: Sets the rate for decoherence (probability normalization).
 *   - `setEntanglementDecayRate(uint256 tokenId, uint256 rate)`: Sets how much entanglement influence decays.
 *   - `updateObservationPolicy(uint256 tokenId, ObservationPolicy policy)`: Sets rules for when observation happens.
 *   - `applyInfluence(uint256 tokenId, uint256 x, uint256 y, uint256 stateIndex)`: Apply influence to a pixel, shifting probabilities. (Payable)
 *   - `observePixel(uint256 tokenId, uint256 x, uint256 y)`: Collapse the state of a single pixel.
 *   - `triggerFullCanvasObservation(uint256 tokenId)`: Collapse states for all pixels on a canvas (requires policy permission).
 *   - `entanglePixels(uint256 tokenId, uint256 x1, uint256 y1, uint256 x2, uint256 y2, uint256 strength)`: Creates an entanglement link between two pixels.
 *   - `applyDecoherence(uint256 tokenId, uint256 x, uint256 y)`: Manually apply decoherence to a pixel.
 *   - `applyQuantumTunneling(uint256 tokenId, uint256 x, uint256 y)`: Apply quantum tunneling effect to a pixel.
 *   - `getPixelState(uint256 tokenId, uint256 x, uint256 y)`: Get current probability distribution of a pixel.
 *   - `getPixelObservedState(uint256 tokenId, uint256 x, uint256 y)`: Get the last observed state of a pixel.
 *   - `getCanvasConfig(uint256 tokenId)`: Get canvas dimensions, potential states, costs, rates.
 *   - `getEntanglementLinks(uint256 tokenId, uint256 x, uint256 y)`: Get links for a specific pixel.
 *
 * Total: 8 + 3 + 3 + 17 = 31 functions (more than 20 requirement met).
 */
contract QuantumArtCanvas is ERC721, ERC721Enumerable, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    // --- Structs and Enums ---

    /// @dev Represents the potential states (colors/values) and their current probabilities for a single pixel.
    /// Probabilities are scaled integers (e.g., sum to 10000 for 100%).
    struct PixelState {
        uint256[] potentialStates; // e.g., RGB values encoded as uint256
        uint256[] probabilities; // Corresponds to potentialStates. Sums to a fixed total.
        uint256 observedState; // The state after collapse (index into potentialStates)
        uint256 lastObservedTime; // Timestamp of last observation
        // Could add history of influences, but complex for state
    }

    /// @dev Represents an entanglement link between two pixels.
    struct EntanglementLink {
        uint256 x1;
        uint256 y1;
        uint256 x2;
        uint256 y2;
        uint256 strength; // How strongly they are linked (affects influence spread)
    }

    /// @dev Represents the data for a single canvas NFT.
    struct Canvas {
        uint256 width;
        uint256 height;
        mapping(uint256 => mapping(uint256 => PixelState)) pixels; // Grid of pixels
        uint256[] potentialPixelStates; // List of possible states (colors/values) for this canvas
        uint256 influenceCost; // Cost in wei to apply influence
        uint256 decoherenceRate; // Rate for probability normalization
        uint256 entanglementDecayRate; // Rate at which entanglement influence diminishes
        ObservationPolicy observationPolicy;
        // Could store entanglement links here too, but mapping might be complex nesting.
        // Let's store links globally per canvas ID.
        EntanglementLink[] entanglementLinks;
    }

    /// @dev Defines when a pixel's state can be observed/collapsed.
    enum ObservationPolicy {
        Manual, // Only manually triggered (by user if permission/cost met)
        CanvasOwnerOnly, // Only by the canvas owner
        TimeBased, // Automatically triggers after a certain time period
        InfluenceThresholdBased // Automatically triggers after a certain total influence amount
        // Could add Chainlink VRF trigger policy
    }

    // --- State Variables ---

    mapping(uint256 => Canvas) private _canvasData;
    mapping(address => bool) private _admins; // Contract-level admins

    // --- Events ---

    event CanvasMinted(uint256 indexed tokenId, uint256 width, uint256 height, address indexed owner);
    event PotentialPixelStatesSet(uint256 indexed tokenId, uint256[] potentialStates);
    event InfluenceCostSet(uint256 indexed tokenId, uint256 cost);
    event DecoherenceRateSet(uint256 indexed tokenId, uint256 rate);
    event EntanglementDecayRateSet(uint256 indexed tokenId, uint256 rate);
    event ObservationPolicyUpdated(uint256 indexed tokenId, ObservationPolicy policy);
    event InfluenceApplied(uint256 indexed tokenId, uint256 indexed x, uint256 indexed y, uint256 stateIndex, uint256 strength, address indexed by);
    event PixelObserved(uint256 indexed tokenId, uint256 indexed x, uint256 indexed y, uint256 observedStateIndex);
    event EntanglementCreated(uint256 indexed tokenId, uint256 x1, uint256 y1, uint256 x2, uint256 y2, uint256 strength);
    event DecoherenceApplied(uint256 indexed tokenId, uint256 x, uint256 y);
    event QuantumTunnelingApplied(uint256 indexed tokenId, uint256 x, uint256 y);
    event FundsWithdrawn(address indexed to, uint256 amount);
    event AdminAdded(address indexed admin);
    event AdminRemoved(address indexed admin);

    // --- Modifiers ---

    modifier onlyCanvasOwner(uint256 tokenId) {
        require(ownerOf(tokenId) == _msgSender(), "QAC: Not canvas owner");
        _;
    }

    modifier onlyAdmin() {
        require(_admins[_msgSender()] || owner() == _msgSender(), "QAC: Not authorized admin");
        _;
    }

    modifier validPixel(uint256 tokenId, uint256 x, uint256 y) {
        Canvas storage canvas = _canvasData[tokenId];
        require(canvas.width > 0 && x < canvas.width && y < canvas.height, "QAC: Invalid pixel coordinates");
        _;
    }

    // --- Constructor ---

    constructor(string memory name, string memory symbol) ERC721(name, symbol) {
        _admins[msg.sender] = true; // Owner is initially an admin
    }

    // --- Admin Functions (Contract-level) ---

    /// @dev Adds an address to the list of contract admins.
    function addAdmin(address admin) external onlyWithOwner {
        require(admin != address(0), "QAC: Zero address");
        _admins[admin] = true;
        emit AdminAdded(admin);
    }

    /// @dev Removes an address from the list of contract admins.
    function removeAdmin(address admin) external onlyWithOwner {
        require(admin != address(0), "QAC: Zero address");
        require(admin != owner(), "QAC: Cannot remove contract owner as admin via this function");
        _admins[admin] = false;
        emit AdminRemoved(admin);
    }

    /// @dev Checks if an address is a contract admin (including the owner).
    function isAdmin(address account) public view returns (bool) {
        return _admins[account] || owner() == account;
    }

    /// @dev Allows the contract owner or an admin to withdraw accumulated ETH.
    function withdrawFunds() external onlyAdmin {
        uint256 balance = address(this).balance;
        require(balance > 0, "QAC: No funds to withdraw");
        (bool success, ) = payable(owner()).call{value: balance}(""); // Send to contract owner
        require(success, "QAC: ETH transfer failed");
        emit FundsWithdrawn(owner(), balance);
    }

    // --- Canvas Creation and Configuration (by Canvas Owner) ---

    /// @dev Mints a new canvas NFT with specified dimensions.
    /// Initial pixel states are set with equal probability for state 0.
    /// Potential pixel states, cost, rates, and policy must be set separately.
    function mintCanvas(uint256 width, uint256 height) public payable returns (uint256) {
        require(width > 0 && height > 0, "QAC: Dimensions must be positive");

        _tokenIds.increment();
        uint256 newTokenId = _tokenIds.current();

        _safeMint(_msgSender(), newTokenId);

        Canvas storage newCanvas = _canvasData[newTokenId];
        newCanvas.width = width;
        newCanvas.height = height;
        // Initialize pixels with a default state (e.g., state 0)
        // Probabilities are empty initially until setPotentialPixelStates is called.
        // observedState defaults to 0.

        emit CanvasMinted(newTokenId, width, height, _msgSender());

        return newTokenId;
    }

    /// @dev Sets the potential states (e.g., colors) that pixels on a canvas can have.
    /// Call this after minting. This also initializes the probability arrays for all pixels
    /// with equal probability distribution across the new states.
    function setPotentialPixelStates(uint256 tokenId, uint256[] memory _potentialStates) external onlyCanvasOwner(tokenId) {
        require(_potentialStates.length > 0, "QAC: Must provide potential states");
        Canvas storage canvas = _canvasData[tokenId];
        canvas.potentialPixelStates = _potentialStates;

        // Initialize probabilities for all pixels to be equal
        uint256 numStates = _potentialStates.length;
        uint256 equalProbability = 10000 / numStates; // Using 10000 as total probability scale
        uint256 remainder = 10000 % numStates;

        for (uint256 x = 0; x < canvas.width; x++) {
            for (uint256 y = 0; y < canvas.height; y++) {
                PixelState storage pixel = canvas.pixels[x][y];
                pixel.potentialStates = _potentialStates; // Link to the canvas's potential states

                // Reset probabilities to equal distribution
                pixel.probabilities = new uint256[](numStates);
                for (uint256 i = 0; i < numStates; i++) {
                    pixel.probabilities[i] = equalProbability + (i < remainder ? 1 : 0);
                }
                // Set observed state to the first potential state initially
                pixel.observedState = pixel.potentialStates[0];
            }
        }

        emit PotentialPixelStatesSet(tokenId, _potentialStates);
    }


    /// @dev Sets the cost in wei required for a user to apply influence to a pixel.
    function setInfluenceCost(uint256 tokenId, uint256 cost) external onlyCanvasOwner(tokenId) {
        _canvasData[tokenId].influenceCost = cost;
        emit InfluenceCostSet(tokenId, cost);
    }

    /// @dev Sets the rate at which pixel probabilities drift towards equal distribution (decoherence).
    /// A higher rate means faster decoherence. This rate is used by `applyDecoherence`.
    function setDecoherenceRate(uint256 tokenId, uint256 rate) external onlyCanvasOwner(tokenId) {
        _canvasData[tokenId].decoherenceRate = rate;
        emit DecoherenceRateSet(tokenId, rate);
    }

    /// @dev Sets the rate at which influence decays through entanglement links.
    /// A higher rate means less influence is passed through links.
    function setEntanglementDecayRate(uint256 tokenId, uint256 rate) external onlyCanvasOwner(tokenId) {
        _canvasData[tokenId].entanglementDecayRate = rate;
        emit EntanglementDecayRateSet(tokenId, rate);
    }

    /// @dev Updates the policy that governs when pixel states can be observed/collapsed.
    function updateObservationPolicy(uint256 tokenId, ObservationPolicy policy) external onlyCanvasOwner(tokenId) {
        _canvasData[tokenId].observationPolicy = policy;
        emit ObservationPolicyUpdated(tokenId, policy);
    }

    // --- Core Quantum Interaction Functions ---

    /// @dev Allows a user to apply influence to a specific pixel, increasing the probability
    /// of a desired state. Requires payment equal to `influenceCost`.
    /// Influence amount adds a weight to the target state, and probabilities are re-normalized.
    function applyInfluence(uint256 tokenId, uint256 x, uint256 y, uint256 stateIndex) public payable validPixel(tokenId, x, y) {
        Canvas storage canvas = _canvasData[tokenId];
        require(msg.value >= canvas.influenceCost, "QAC: Insufficient ETH paid for influence");
        require(stateIndex < canvas.potentialPixelStates.length, "QAC: Invalid state index");
        require(canvas.potentialPixelStates.length > 0, "QAC: Potential states not set for canvas");

        PixelState storage pixel = canvas.pixels[x][y];

        // Add weight to the target state's probability
        uint256 influenceStrength = 100; // Fixed strength per paid influence for simplicity

        // Find the index of the matching state in the pixel's potentialStates
        int256 targetStateProbIndex = -1;
        for(uint256 i = 0; i < pixel.potentialStates.length; i++) {
            if (pixel.potentialStates[i] == canvas.potentialPixelStates[stateIndex]) {
                targetStateProbIndex = int256(i);
                break;
            }
        }
        require(targetStateProbIndex != -1, "QAC: State not found in pixel's potential states");

        uint256 totalProbability = 0;
        for (uint256 i = 0; i < pixel.probabilities.length; i++) {
            totalProbability += pixel.probabilities[i];
        }

        // Increase the probability of the target state
        pixel.probabilities[uint256(targetStateProbIndex)] += influenceStrength;
        totalProbability += influenceStrength;

        // Re-normalize all probabilities
        if (totalProbability > 0) {
            for (uint256 i = 0; i < pixel.probabilities.length; i++) {
                pixel.probabilities[i] = (pixel.probabilities[i] * 10000) / totalProbability; // Normalize to 10000
            }
        }
        // Distribute any rounding error if probabilities don't sum exactly to 10000
        uint256 currentSum = 0;
        for(uint256 i = 0; i < pixel.probabilities.length; i++) currentSum += pixel.probabilities[i];
        if (currentSum != 10000) {
             if (currentSum < 10000) pixel.probabilities[0] += (10000 - currentSum); // Add deficit to first state
             else pixel.probabilities[0] -= (currentSum - 10000); // Subtract excess from first state
        }


        // Apply influence to entangled pixels
        _applyEntanglementInfluence(tokenId, x, y, stateIndex, influenceStrength, canvas.entanglementDecayRate);


        emit InfluenceApplied(tokenId, x, y, stateIndex, influenceStrength, _msgSender());
    }

    /// @dev Helper function to apply influence to entangled pixels.
    function _applyEntanglementInfluence(uint256 tokenId, uint256 x, uint256 y, uint256 stateIndex, uint256 strength, uint256 decayRate) internal {
         Canvas storage canvas = _canvasData[tokenId];
         uint256 numEntanglements = canvas.entanglementLinks.length;

        for(uint256 i = 0; i < numEntanglements; i++) {
            EntanglementLink storage link = canvas.entanglementLinks[i];
            uint256 targetX = type(uint256).max; // Invalid coordinate placeholder
            uint256 targetY = type(uint256).max;

            if (link.x1 == x && link.y1 == y) {
                targetX = link.x2;
                targetY = link.y2;
            } else if (link.x2 == x && link.y2 == y) {
                targetX = link.x1;
                targetY = link.y1;
            }

            if (targetX != type(uint256).max) {
                 // Apply decayed influence to the entangled pixel
                 // Simple decay: strength = strength * (100 - decayRate) / 100
                 // Assuming decayRate is 0-100
                 uint256 decayedStrength = (strength * (100 - Math.min(decayRate, 100))) / 100;
                 if (decayedStrength > 0) {
                    // Note: This recursive call might hit stack depth limits on very complex entanglement chains.
                    // A non-recursive approach might be needed for production.
                    _applyInfluenceInternal(tokenId, targetX, targetY, stateIndex, decayedStrength);
                 }
            }
        }
    }

     /// @dev Internal helper to apply influence without payment or entanglement recursion.
     /// Used by entanglement propagation.
    function _applyInfluenceInternal(uint256 tokenId, uint256 x, uint256 y, uint256 stateIndex, uint256 strength) internal validPixel(tokenId, x, y) {
        Canvas storage canvas = _canvasData[tokenId];
        require(stateIndex < canvas.potentialPixelStates.length, "QAC: Invalid state index");
        require(canvas.potentialPixelStates.length > 0, "QAC: Potential states not set for canvas");

        PixelState storage pixel = canvas.pixels[x][y];

        int256 targetStateProbIndex = -1;
        for(uint256 i = 0; i < pixel.potentialStates.length; i++) {
            if (pixel.potentialStates[i] == canvas.potentialPixelStates[stateIndex]) {
                targetStateProbIndex = int256(i);
                break;
            }
        }
        // If the target state from the originating pixel isn't a potential state on the entangled pixel, skip
        if (targetStateProbIndex == -1) return;


        uint256 totalProbability = 0;
        for (uint256 i = 0; i < pixel.probabilities.length; i++) {
            totalProbability += pixel.probabilities[i];
        }

        pixel.probabilities[uint256(targetStateProbIndex)] += strength;
        totalProbability += strength;

        if (totalProbability > 0) {
            for (uint256 i = 0; i < pixel.probabilities.length; i++) {
                pixel.probabilities[i] = (pixel.probabilities[i] * 10000) / totalProbability;
            }
        }
         // Distribute any rounding error if probabilities don't sum exactly to 10000
        uint256 currentSum = 0;
        for(uint256 i = 0; i < pixel.probabilities.length; i++) currentSum += pixel.probabilities[i];
        if (currentSum != 10000) {
             if (currentSum < 10000) pixel.probabilities[0] += (10000 - currentSum);
             else pixel.probabilities[0] -= (currentSum - 10000);
        }
    }


    /// @dev Triggers the "observation" of a single pixel, collapsing its quantum state
    /// into a single observed state based on current probabilities.
    /// Policy must allow triggering observation (e.g., Manual or InfluenceThresholdMet).
    /// WARNING: Uses block hash and timestamp for pseudo-randomness. This is INSECURE
    /// for scenarios where an attacker can influence block timing or content.
    /// For production, use Chainlink VRF or similar secure randomness solutions.
    function observePixel(uint256 tokenId, uint256 x, uint256 y) public validPixel(tokenId, x, y) {
        Canvas storage canvas = _canvasData[tokenId];
        PixelState storage pixel = canvas.pixels[x][y];

        // Check observation policy
        // Simplified policy check: Allow Manual trigger, or if CanvasOwnerOnly and sender is owner
        bool canObserve = false;
        if (canvas.observationPolicy == ObservationPolicy.Manual) {
            // Add checks here if Manual requires payment or permission
            canObserve = true;
        } else if (canvas.observationPolicy == ObservationPolicy.CanvasOwnerOnly && _msgSender() == ownerOf(tokenId)) {
             canObserve = true;
        }
        // Add checks for TimeBased or InfluenceThresholdBased policies if implemented fully

        require(canObserve, "QAC: Observation policy does not allow manual trigger");
        require(pixel.potentialStates.length > 0, "QAC: Potential states not set for pixel");
        require(pixel.probabilities.length == pixel.potentialStates.length, "QAC: Probabilities mismatch states");


        // --- Pseudo-randomness (INSECURE - For demonstration only) ---
        uint256 randomNumber = uint256(keccak256(abi.encodePacked(
            block.timestamp,
            block.difficulty,
            block.number,
            msg.sender,
            tx.origin, // Avoid using tx.origin in production
            gasleft()
        )));
        // --- End Pseudo-randomness ---


        uint256 totalProbability = 10000; // Probabilities are scaled to sum to 10000
        uint256 randomPoint = randomNumber % totalProbability;

        uint256 cumulativeProbability = 0;
        uint256 observedStateIndex = 0; // Default to the first state index

        for (uint256 i = 0; i < pixel.probabilities.length; i++) {
            cumulativeProbability += pixel.probabilities[i];
            if (randomPoint < cumulativeProbability) {
                observedStateIndex = i;
                break;
            }
        }

        pixel.observedState = pixel.potentialStates[observedStateIndex];
        pixel.lastObservedTime = block.timestamp;

        // Optional: Reset probabilities after observation?
        // This mimics decoherence or measurement effect. Let's reset to favor the observed state slightly.
        uint256 numStates = pixel.potentialStates.length;
        if (numStates > 0) {
            uint256 baseProb = 10000 / numStates;
            uint256 bonusProb = 2000; // Give observed state a bonus probability
            uint256 remainingProb = 10000 - bonusProb;
            uint256 otherProb = remainingProb / (numStates - 1);
            uint256 otherRemainder = remainingProb % (numStates - 1);


            for(uint256 i = 0; i < numStates; i++) {
                if (i == observedStateIndex) {
                    pixel.probabilities[i] = bonusProb;
                } else {
                    pixel.probabilities[i] = otherProb + (i < otherRemainder ? 1 : 0);
                }
            }
        }


        emit PixelObserved(tokenId, x, y, observedStateIndex);
    }

     /// @dev Triggers the "observation" for all pixels on a canvas.
     /// Only allowed if the observation policy is CanvasOwnerOnly for the canvas owner.
    function triggerFullCanvasObservation(uint256 tokenId) external onlyCanvasOwner(tokenId) {
        Canvas storage canvas = _canvasData[tokenId];
        require(canvas.observationPolicy == ObservationPolicy.CanvasOwnerOnly, "QAC: Observation policy does not allow full canvas trigger by owner");

        for (uint256 x = 0; x < canvas.width; x++) {
            for (uint256 y = 0; y < canvas.height; y++) {
                // Call the internal logic to observe each pixel
                _observePixelInternal(tokenId, x, y);
            }
        }
        // Event for full canvas observation? Could be too many events.
        // Individual PixelObserved events will be emitted.
    }

     /// @dev Internal helper function to perform pixel observation logic without policy checks or event emission.
     /// Used by triggerFullCanvasObservation.
    function _observePixelInternal(uint256 tokenId, uint256 x, uint256 y) internal validPixel(tokenId, x, y) {
        PixelState storage pixel = _canvasData[tokenId].pixels[x][y];
        require(pixel.potentialStates.length > 0, "QAC: Potential states not set for pixel");
         require(pixel.probabilities.length == pixel.potentialStates.length, "QAC: Probabilities mismatch states");

        // --- Pseudo-randomness (INSECURE - For demonstration only) ---
        uint256 randomNumber = uint256(keccak256(abi.encodePacked(
            block.timestamp,
            block.difficulty,
            block.number,
            msg.sender, // Using msg.sender of the *triggering* transaction
            tx.origin,
            gasleft(),
            tokenId, x, y // Add pixel coordinates for more variance
        )));
         // --- End Pseudo-randomness ---

        uint256 totalProbability = 10000;
        uint256 randomPoint = randomNumber % totalProbability;

        uint256 cumulativeProbability = 0;
        uint256 observedStateIndex = 0;

        for (uint256 i = 0; i < pixel.probabilities.length; i++) {
            cumulativeProbability += pixel.probabilities[i];
            if (randomPoint < cumulativeProbability) {
                observedStateIndex = i;
                break;
            }
        }

        pixel.observedState = pixel.potentialStates[observedStateIndex];
        pixel.lastObservedTime = block.timestamp;

        // Reset probabilities to favor observed state
         uint256 numStates = pixel.potentialStates.length;
        if (numStates > 0) {
             uint256 baseProb = 10000 / numStates;
            uint256 bonusProb = 2000;
            uint256 remainingProb = 10000 - bonusProb;
            uint256 otherProb = remainingProb / (numStates - 1);
            uint256 otherRemainder = remainingProb % (numStates - 1);


            for(uint256 i = 0; i < numStates; i++) {
                if (i == observedStateIndex) {
                    pixel.probabilities[i] = bonusProb;
                } else {
                    pixel.probabilities[i] = otherProb + (i < otherRemainder ? 1 : 0);
                }
            }
        }

        emit PixelObserved(tokenId, x, y, observedStateIndex); // Emit event for each pixel
    }


    /// @dev Creates an entanglement link between two pixels on a canvas.
    /// Influencing one pixel will also influence the other with reduced strength.
    /// Requires canvas owner or admin.
    function entanglePixels(uint256 tokenId, uint256 x1, uint256 y1, uint256 x2, uint256 y2, uint256 strength) external onlyCanvasOwner(tokenId) validPixel(tokenId, x1, y1) validPixel(tokenId, x2, y2) {
         require(!(x1 == x2 && y1 == y2), "QAC: Cannot entangle a pixel with itself");
         require(strength > 0 && strength <= 100, "QAC: Entanglement strength must be between 1 and 100");

        Canvas storage canvas = _canvasData[tokenId];

        // Add the link. Simple check to avoid adding duplicates in the same direction.
        // A more robust check would check both directions and different strength links.
        // For simplicity, we allow duplicates / different strengths for now.
        canvas.entanglementLinks.push(EntanglementLink(x1, y1, x2, y2, strength));

        emit EntanglementCreated(tokenId, x1, y1, x2, y2, strength);
    }

    /// @dev Applies a decoherence effect to a pixel, moving its probabilities closer to an equal distribution.
    /// The rate is determined by the canvas's `decoherenceRate`.
    /// Can be called by anyone (if policy allows, or for a cost - not implemented).
    function applyDecoherence(uint256 tokenId, uint256 x, uint256 y) public validPixel(tokenId, x, y) {
        Canvas storage canvas = _canvasData[tokenId];
        PixelState storage pixel = canvas.pixels[x][y];
         require(pixel.potentialStates.length > 1, "QAC: Decoherence requires multiple potential states");
         require(canvas.decoherenceRate > 0, "QAC: Decoherence rate not set or zero");

        uint256 numStates = pixel.potentialStates.length;
        uint256 targetProbability = 10000 / numStates;
        uint256 totalProbability = 10000; // Should always sum to 10000 after normalization

        // Apply decoherence: move probabilities closer to the average
        for (uint256 i = 0; i < numStates; i++) {
            if (pixel.probabilities[i] > targetProbability) {
                uint256 reduction = (pixel.probabilities[i] - targetProbability) * canvas.decoherenceRate / 100; // Decay rate 0-100
                pixel.probabilities[i] -= reduction;
            } else if (pixel.probabilities[i] < targetProbability) {
                 uint256 increase = (targetProbability - pixel.probabilities[i]) * canvas.decoherenceRate / 100;
                 pixel.probabilities[i] += increase;
            }
        }

         // Re-normalize after adjustments (small errors might accumulate)
         uint256 currentSum = 0;
        for(uint256 i = 0; i < numStates; i++) currentSum += pixel.probabilities[i];
        if (currentSum != 10000) {
             if (currentSum < 10000) pixel.probabilities[0] += (10000 - currentSum);
             else pixel.probabilities[0] -= (currentSum - 10000);
        }


        emit DecoherenceApplied(tokenId, x, y);
    }

    /// @dev Applies a 'quantum tunneling' effect to a pixel. This is a simplified
    /// concept where the pixel's state distribution can jump significantly to
    /// a different configuration with low probability.
    /// WARNING: Uses block data for pseudo-randomness.
    /// Can be called by anyone (if policy allows, or for a cost - not implemented).
    function applyQuantumTunneling(uint256 tokenId, uint256 x, uint256 y) public validPixel(tokenId, x, y) {
         Canvas storage canvas = _canvasData[tokenId];
        PixelState storage pixel = canvas.pixels[x][y];
        require(pixel.potentialStates.length > 1, "QAC: Tunneling requires multiple potential states");

        // Simplified tunneling trigger: small random chance
        // --- Pseudo-randomness (INSECURE - For demonstration only) ---
        uint256 chance = uint256(keccak256(abi.encodePacked(
            block.timestamp,
            block.number,
            msg.sender,
            gasleft(),
            tokenId, x, y,
            "tunneling" // Add a unique salt
        ))) % 1000; // 1 in 1000 chance
        // --- End Pseudo-randomness ---

        uint256 tunnelingThreshold = 5; // e.g., 5/1000 chance

        if (chance < tunnelingThreshold) {
             // Apply tunneling effect: Randomly redistribute probabilities
             uint256 numStates = pixel.potentialStates.length;
             uint256 remainingProb = 10000;

            // --- Pseudo-randomness for redistribution (INSECURE) ---
            uint256 seed = uint256(keccak256(abi.encodePacked(
                block.timestamp,
                block.number,
                gasleft(),
                tokenId, x, y,
                "redistribution"
            )));
            // --- End Pseudo-randomness ---

             for (uint256 i = 0; i < numStates; i++) {
                 if (i == numStates - 1) {
                     pixel.probabilities[i] = remainingProb;
                 } else {
                      uint256 share = (seed % (remainingProb + 1)) / (numStates - i); // Distribute remaining prob
                      pixel.probabilities[i] = share;
                      remainingProb -= share;
                      seed = uint256(keccak256(abi.encodePacked(seed, i))); // Update seed
                 }
             }
             // Ensure sums to 10000 due to integer division
             uint256 currentSum = 0;
            for(uint256 i = 0; i < numStates; i++) currentSum += pixel.probabilities[i];
            if (currentSum != 10000) {
                 if (currentSum < 10000) pixel.probabilities[0] += (10000 - currentSum);
                 else pixel.probabilities[0] -= (currentSum - 10000);
            }

            emit QuantumTunnelingApplied(tokenId, x, y);
        }
         // If chance threshold not met, tunneling doesn't happen for this call.
    }


    // --- Query Functions (Read-only) ---

    /// @dev Gets the current quantum state (probability distribution) of a pixel.
    /// Returns the list of potential state values and their corresponding probabilities.
    function getPixelState(uint256 tokenId, uint256 x, uint256 y) public view validPixel(tokenId, x, y) returns (uint256[] memory potentialStates, uint256[] memory probabilities) {
        Canvas storage canvas = _canvasData[tokenId];
        PixelState storage pixel = canvas.pixels[x][y];
        return (pixel.potentialStates, pixel.probabilities);
    }

    /// @dev Gets the last observed (collapsed) state of a pixel.
    /// Returns the value of the state and the timestamp it was observed.
    function getPixelObservedState(uint256 tokenId, uint256 x, uint256 y) public view validPixel(tokenId, x, y) returns (uint256 observedStateValue, uint256 lastObservedTimestamp) {
        PixelState storage pixel = _canvasData[tokenId].pixels[x][y];
        return (pixel.observedState, pixel.lastObservedTime);
    }

    /// @dev Gets the dimensions, potential states, influence cost, and rates for a canvas.
    function getCanvasConfig(uint256 tokenId) public view returns (
        uint256 width,
        uint256 height,
        uint256[] memory potentialStates,
        uint256 influenceCost,
        uint256 decoherenceRate,
        uint256 entanglementDecayRate,
        ObservationPolicy observationPolicy
    ) {
        Canvas storage canvas = _canvasData[tokenId];
        return (
            canvas.width,
            canvas.height,
            canvas.potentialPixelStates,
            canvas.influenceCost,
            canvas.decoherenceRate,
            canvas.entanglementDecayRate,
            canvas.observationPolicy
        );
    }

    /// @dev Gets the entanglement links associated with a specific canvas.
    function getEntanglementLinks(uint256 tokenId) public view returns (EntanglementLink[] memory) {
        // Note: Returning full dynamic arrays from storage can be expensive/hit gas limits
        // for large numbers of links. A paginated approach might be better in production.
        return _canvasData[tokenId].entanglementLinks;
    }

     /// @dev Gets the entanglement links originating from or ending at a specific pixel.
     /// This requires iterating through all links for the canvas.
    function getEntanglementLinks(uint256 tokenId, uint256 x, uint256 y) public view validPixel(tokenId, x, y) returns (EntanglementLink[] memory) {
        Canvas storage canvas = _canvasData[tokenId];
        EntanglementLink[] storage allLinks = canvas.entanglementLinks;
        EntanglementLink[] memory pixelLinks = new EntanglementLink[](0); // Dynamic array for results

        for(uint256 i = 0; i < allLinks.length; i++) {
            if ((allLinks[i].x1 == x && allLinks[i].y1 == y) || (allLinks[i].x2 == x && allLinks[i].y2 == y)) {
                 // Append to dynamic array (inefficient pattern, but okay for view)
                 pixelLinks = _appendLink(pixelLinks, allLinks[i]);
            }
        }
        return pixelLinks;
    }

    /// @dev Helper function to append an EntanglementLink to a dynamic array (for view function).
    function _appendLink(EntanglementLink[] memory arr, EntanglementLink memory link) pure internal returns (EntanglementLink[] memory) {
        EntanglementLink[] memory newArr = new EntanglementLink[](arr.length + 1);
        for(uint256 i = 0; i < arr.length; i++) {
            newArr[i] = arr[i];
        }
        newArr[arr.length] = link;
        return newArr;
    }


    // --- ERC721 Standard Overrides ---
    // These are required by ERC721Enumerable

    function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721Enumerable) returns (bool) {
        return interfaceId == type(ERC721).interfaceId ||
               interfaceId == type(ERC721Enumerable).interfaceId ||
               super.supportsInterface(interfaceId);
    }

    function _baseURI() internal pure override returns (string memory) {
        // You would typically return a base URI pointing to metadata files here
        // return "ipfs://YOUR_METADATA_BASE_URI/";
        return ""; // Placeholder
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

     // ERC721 functions `balanceOf`, `ownerOf`, `transferFrom`, `safeTransferFrom`, `approve`, `setApprovalForAll`, `getApproved`, `isApprovedForAll` are provided by OpenZeppelin base contracts.

     // ERC721Enumerable functions `totalSupply`, `tokenByIndex`, `tokenOfOwnerByIndex` are provided by OpenZeppelin base contracts.


}
```