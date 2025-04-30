Okay, here is a Solidity smart contract concept called "Quantum Canvas". It's an advanced, creative NFT project where pixels are dynamic, interact with each other, and evolve based on user actions, time, and randomness. It incorporates elements of generative art, interactive NFTs, and scheduled maintenance.

**Concept:** The Quantum Canvas is a fixed-size grid of pixels. Each pixel is a unique ERC721 NFT. Unlike static NFTs, the *appearance* and *state* of a Quantum Pixel NFT are dynamic and stored on-chain. Users can interact with their pixels (e.g., "energize" them), which can influence neighboring pixels and trigger potential "mutations" via Chainlink VRF. The canvas itself evolves over time in distinct "epochs". The final color/appearance of a pixel is *derived* from its internal state, its energy level, its neighbors' states, and potentially global canvas parameters, making the art generative and collaborative.

**Advanced Concepts Used:**

1.  **Dynamic On-Chain NFT State:** Pixel properties (color component, energy, flags) are stored and modified directly in contract storage, not just referenced via metadata URI.
2.  **Generative Art via State Derivation:** The final visual representation (color) is *calculated* by the contract based on the pixel's state and its neighbors' states, rather than being a static image. The `tokenURI` would point to a service that reads this on-chain state to generate the dynamic metadata/image.
3.  **Interactive Evolution:** User actions (`energizePixel`, `requestPixelMutation`) directly impact the pixel's state.
4.  **Inter-Pixel Influence:** Energy/state from one pixel can "propagate" and affect the state of neighboring pixels. This creates emergent patterns.
5.  **Randomness for Mutation:** Uses Chainlink VRF for secure, verifiable random numbers to introduce unpredictable changes ("mutations") to pixels.
6.  **Batched Maintenance/Evolution:** Functions like `propagateInfluenceBatch` and `requestCanvasUpdateBatch` allow anyone to trigger state updates for a small batch of pixels, potentially incentivized, managing gas costs for complex operations.
7.  **Epoch-Based Evolution:** Global state changes can occur in distinct phases ("epochs"), potentially altering rules or triggering events.

**Outline & Function Summary:**

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol"; // For getTotalSupply, tokenByIndex
import "@openzeppelin/contracts/access/Ownable.sol";
import "@chainlink/contracts/src/v0.8/vrf/VRFConsumerBaseV2.sol";
import "@chainlink/contracts/src/v0.8/interfaces/KeeperCompatibleInterface.sol"; // Optional: If using Chainlink Keepers for batch updates

// ===================================================================
// Quantum Canvas Contract
// An ERC721 NFT project where pixels are dynamic, interactive, and
// evolve on-chain based on user actions, neighbor influence, time,
// and randomness.
// ===================================================================

// ===================================================================
// OUTLINE
// - Structs & Enums: Define data structures for pixel state and global parameters.
// - State Variables: Store canvas dimensions, global parameters, pixel states, VRF config.
// - Events: Signal key actions (minting, state changes, epoch changes, VRF).
// - Constructor: Initialize canvas dimensions, VRF, and potentially mint initial pixels.
// - ERC721 Standard Functions: Implement required and optional ERC721 functions.
// - Core Pixel Interaction Functions:
//   - energizePixel: Add energy to a pixel.
//   - requestPixelMutation: Request a random mutation via VRF.
//   - fulfillRandomWords: VRF callback to apply mutation effects.
// - Canvas & Global Evolution Functions:
//   - propagateInfluenceBatch: Manually trigger influence propagation for a batch of pixels.
//   - requestCanvasUpdateBatch: Manually trigger decay and other updates for a batch.
//   - triggerEpochChange: Admin function to advance canvas epoch.
// - View Functions:
//   - getPixelState: Retrieve full on-chain state of a pixel.
//   - getPixelColor: Calculate and return the derived color of a pixel.
//   - getPixelCoords: Get grid coordinates from token ID.
//   - getPixelIdFromCoords: Get token ID from grid coordinates.
//   - getGlobalState: Retrieve global canvas parameters.
//   - getNeighborPixelIds: Get IDs of neighboring pixels.
//   - getTokenIdsForOwner: Get list of tokens owned by an address.
// - Admin/Utility Functions:
//   - withdrawFunds: Withdraw accumulated contract balance.
//   - setGlobalParameters: Update global evolution parameters.
//   - setVRFSubscriptionId: Set Chainlink VRF subscription ID.
//   - setBaseURI: Set base URI for token metadata (points to a dynamic service).
//   - burnPixel: Allow pixel owners to burn their NFT.
// - Internal Helper Functions:
//   - _initializePixelState: Set up initial state for a new pixel.
//   - _decayEnergy: Reduce pixel energy over time.
//   - _applyMutationEffect: Apply effects based on VRF randomness.
//   - _applyInfluenceEffect: Apply effects from neighbors.
//   - _calculateDerivedColor: The core art logic - calculate color from state.
//   - _coordsToTokenId, _tokenIdToCoords: Convert between coordinates and token ID.
//   - _getNeighborPixelState: Helper to get neighbor state safely.
// ===================================================================

// ===================================================================
// FUNCTION SUMMARIES
// ===================================================================

// ERC721 Standard Functions:
// constructor(uint256 _width, uint256 _height, address _vrfCoordinator, bytes32 _keyHash, uint64 _subscriptionId): Initializes the canvas dimensions, VRF settings, and the ERC721 contract.
// safeMint(address to, uint256 x, uint256 y): Mints a pixel at specific coordinates (if available) to an address. Wraps ERC721's _safeMint and initializes the pixel's state.
// balanceOf(address owner) view: Returns the number of NFTs owned by an address.
// ownerOf(uint256 tokenId) view: Returns the owner of a specific NFT.
// transferFrom(address from, address to, uint256 tokenId): Transfers ownership of an NFT.
// safeTransferFrom(address from, address to, uint256 tokenId): Transfers ownership of an NFT, checking for receiver contract compatibility.
// safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data): Overloaded safe transfer.
// approve(address to, uint256 tokenId): Approves an address to spend a specific NFT.
// setApprovalForAll(address operator, bool approved): Approves or revokes approval for an operator for all owner's NFTs.
// getApproved(uint256 tokenId) view: Returns the approved address for a specific NFT.
// isApprovedForAll(address owner, address operator) view: Checks if an operator is approved for all owner's NFTs.
// getTotalSupply() view: Returns the total number of pixels (NFTs).
// tokenByIndex(uint256 index) view: Returns the token ID at a given index (requires ERC721Enumerable).
// tokenOfOwnerByIndex(address owner, uint256 index) view: Returns the token ID at a given index for a specific owner (requires ERC721Enumerable).
// tokenURI(uint256 tokenId) view: Returns the metadata URI for a pixel, pointing to a service that reads on-chain state.

// Core Pixel Interaction Functions:
// energizePixel(uint256 tokenId) payable: Increases the energy level of a specific pixel. Requires sending Ether (or another defined cost). Energy affects state and influence.
// requestPixelMutation(uint256 tokenId): Initiates a VRF request to potentially mutate a pixel's state. May require burning energy or a small fee.
// fulfillRandomWords(uint256 requestId, uint256[] memory randomWords) internal override: Chainlink VRF callback. Processes the random result and applies mutation effects to the pixel associated with the requestId.

// Canvas & Global Evolution Functions:
// propagateInfluenceBatch(uint256 startTokenId, uint256 count): Allows anyone to trigger the calculation and application of neighbor influence for a batch of pixels starting from startTokenId. Potentially gas-intensive, designed to be callable in batches. Could include a small reward for the caller.
// requestCanvasUpdateBatch(uint256 startTokenId, uint256 count): Allows anyone to trigger general updates like energy decay and check for other time-based effects for a batch of pixels. Also callable in batches. Could include a small reward.
// triggerEpochChange() onlyOwner: Advances the global canvas epoch. This can trigger global state changes or reset certain parameters.

// View Functions:
// getPixelState(uint256 tokenId) view: Returns the full PixelState struct for a given token ID.
// getPixelColor(uint256 tokenId) view: Returns the calculated derived color (e.g., RGB uint24) for a pixel, considering its state and neighbors. This is the "art" function.
// getPixelCoords(uint256 tokenId) pure: Converts a token ID back to its (x, y) grid coordinates.
// getPixelIdFromCoords(uint256 x, uint256 y) pure: Converts grid coordinates to a token ID.
// getGlobalState() view: Returns the current global canvas parameters (epoch, decay factor, etc.).
// getNeighborPixelIds(uint256 tokenId) view: Returns the token IDs of a pixel's direct neighbors.
// getTokenIdsForOwner(address owner) view: Returns a list of all token IDs owned by a specific address. (Requires ERC721Enumerable)

// Admin/Utility Functions:
// withdrawFunds() onlyOwner: Allows the contract owner to withdraw accumulated Ether (e.g., from energizing fees).
// setGlobalParameters(uint16 _globalEnergyDecayFactor, uint16 _mutationChanceBasis, uint8 _influencePropagationAmount) onlyOwner: Sets global parameters affecting canvas evolution.
// setVRFSubscriptionId(uint64 _subscriptionId) onlyOwner: Updates the Chainlink VRF subscription ID.
// setBaseURI(string memory baseURI_) onlyOwner: Sets the base URI for token metadata (e.g., a gateway URL that serves dynamic JSON/images).
// burnPixel(uint256 tokenId): Allows the owner of a pixel to burn (destroy) their NFT. Removes it from the canvas state.

// Internal Helper Functions (not directly callable externally):
// _initializePixelState(uint256 tokenId, uint256 x, uint256 y): Sets initial state for a newly minted pixel.
// _decayEnergy(uint256 tokenId): Reduces a pixel's energy based on time and global decay factor.
// _applyMutationEffect(uint256 tokenId, uint256 randomness): Modifies pixel state based on a random number.
// _applyInfluenceEffect(uint256 sourceTokenId, uint256 targetTokenId): Applies influence from source to target pixel.
// _calculateDerivedColor(uint256 tokenId) view: Core logic to compute pixel's display color.
// _coordsToTokenId(uint256 x, uint256 y) pure: Internal coordinate to ID conversion.
// _tokenIdToCoords(uint256 tokenId) pure: Internal ID to coordinate conversion.
// _getNeighborPixelState(uint256 tokenId, int256 dx, int256 dy) view: Internal helper to get a neighbor's state safely.

contract QuantumCanvas is ERC721Enumerable, Ownable, VRFConsumerBaseV2 {
    // ===================================================================
    // Structs & Enums
    // ===================================================================

    struct PixelState {
        uint256 id;          // Redundant with map key, but useful for passing struct around
        uint32 x;            // X coordinate on the grid
        uint32 y;            // Y coordinate on the grid
        uint24 baseColor;    // Base color component (e.g., initial color, or a primary state representation)
        uint128 energy;      // Energy level, influenced by user interaction and decay
        uint48 lastUpdateTime; // Timestamp of the last significant state update (energy, mutation, etc.)
        uint8 stateFlags;    // Bit flags for various states (e.g., mutated, active influence, etc.)
        uint16 mutationEpoch; // Epoch when last mutated
        uint8 influenceRadius; // How many steps neighbor influence propagates (derived from energy)
    }

    // ===================================================================
    // State Variables
    // ===================================================================

    uint256 public immutable canvasWidth;
    uint256 public immutable canvasHeight;
    uint256 public immutable totalPixels;

    // Mapping from token ID to its current state
    mapping(uint256 => PixelState) private _pixelStates;

    // Global canvas state parameters
    uint16 public currentEpoch = 1;
    uint48 public lastEpochChangeTime;
    uint16 public globalEnergyDecayFactor = 1; // e.g., energy / decayFactor per day
    uint16 public mutationChanceBasis = 1000; // Basis for mutation probability (e.g., 1 in mutationChanceBasis per VRF request)
    uint8 public influencePropagationAmount = 2; // How many steps influence propagates in `propagateInfluenceBatch` per call

    // VRF Variables
    bytes32 public immutable vrfKeyHash;
    uint64 public vrfSubscriptionId;
    mapping(uint256 => uint256) public vrfRequestIdToTokenId; // Map VRF request ID to the pixel token ID

    // Constants for calculations
    uint256 private constant MAX_UINT24 = 0xFFFFFF;
    uint256 private constant MAX_UINT128 = type(uint128).max;
    uint256 private constant MAX_UINT48 = type(uint48).max;
    uint256 private constant MAX_UINT8 = type(uint8).max;
    uint256 private constant MAX_UINT16 = type(uint16).max;
    uint256 private constant ENERGY_PER_ETH = 1e15; // 0.001 ETH = 1e15 wei -> 1e15 energy unit (arbitrary)

    // For batch processing
    uint256 public constant BATCH_SIZE = 20; // Number of pixels to process per batch call

    // ===================================================================
    // Events
    // ===================================================================

    event PixelStateUpdated(uint256 indexed tokenId, PixelState newState, uint24 derivedColor);
    event PixelEnergized(uint256 indexed tokenId, uint128 energyAdded, uint128 newEnergy);
    event MutationRequested(uint256 indexed tokenId, uint256 indexed requestId);
    event MutationFulfilled(uint256 indexed requestId, uint256 indexed tokenId, uint256 randomness);
    event InfluencePropagated(uint256 indexed sourceTokenId, uint256 indexed targetTokenId, uint8 influenceAmount);
    event EpochChanged(uint16 newEpoch, uint48 changeTime);
    event PixelBurned(uint256 indexed tokenId, address indexed owner);
    event CanvasUpdateBatchProcessed(uint256 indexed startTokenId, uint256 count, uint256 pixelsAffected);

    // ===================================================================
    // Constructor
    // ===================================================================

    constructor(
        uint256 _width,
        uint256 _height,
        address _vrfCoordinator,
        bytes32 _keyHash,
        uint64 _subscriptionId,
        string memory name,
        string memory symbol
    )
        ERC721(name, symbol)
        ERC721Enumerable() // Use enumerable extension for getTotalSupply, tokenByIndex, etc.
        VRFConsumerBaseV2(_vrfCoordinator)
        Ownable(msg.sender)
    {
        require(_width > 0 && _height > 0, "Canvas dimensions must be positive");
        require(_width <= 1000 && _height <= 1000, "Canvas dimensions too large"); // Prevent excessive gas/storage
        canvasWidth = _width;
        canvasHeight = _height;
        totalPixels = _width * _height;

        vrfKeyHash = _keyHash;
        vrfSubscriptionId = _subscriptionId;
        lastEpochChangeTime = uint48(block.timestamp);
    }

    // ===================================================================
    // ERC721 Standard Functions (Overridden or implicitly included)
    // ===================================================================

    // We override _safeMint to initialize pixel state upon minting
    function safeMint(address to, uint256 x, uint256 y) public onlyOwner { // Only owner can mint initially
        require(x < canvasWidth && y < canvasHeight, "Coords out of bounds");
        uint256 tokenId = _coordsToTokenId(x, y);
        require(!_exists(tokenId), "Pixel already minted");

        // Initialize the pixel state BEFORE minting
        _initializePixelState(tokenId, uint32(x), uint32(y));

        _safeMint(to, tokenId); // Use ERC721's _safeMint
    }

    // Overrides for ERC721Enumerable
    function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function _update(address to, uint256 tokenId, address auth) internal override(ERC721, ERC721Enumerable) returns (address) {
        return super._update(to, tokenId, auth);
    }

    function _increaseBalance(address account, uint256 amount) internal override(ERC721, ERC721Enumerable) {
        super._increaseBalance(account, amount);
    }

    function _burn(uint256 tokenId) internal override(ERC721, ERC721Enumerable) {
        super._burn(tokenId);
        // Clear pixel state when burned
        delete _pixelStates[tokenId];
    }

    // tokenURI function to point to a dynamic metadata service
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721: token query for nonexistent token");
        // Base URI should point to a server/gateway that reads on-chain state via RPC
        // and generates metadata/image dynamically based on getPixelState and getPixelColor.
        string memory base = _baseURI();
        return string(abi.encodePacked(base, Strings.toString(tokenId)));
    }

    // Set the base URI for token metadata
    function setBaseURI(string memory baseURI_) public onlyOwner {
        _setBaseURI(baseURI_);
    }


    // ERC721Enumerable methods:
    // getTotalSupply(), tokenByIndex(uint256 index), tokenOfOwnerByIndex(address owner, uint256 index)
    // are automatically available due to inheriting ERC721Enumerable

    // ===================================================================
    // Core Pixel Interaction Functions
    // ===================================================================

    // Allows a user to add energy to their pixel, potentially costs Ether
    function energizePixel(uint256 tokenId) public payable {
        require(_exists(tokenId), "Pixel does not exist");
        require(ownerOf(tokenId) == msg.sender, "Not pixel owner");
        require(msg.value > 0, "Must send Ether to energize");

        PixelState storage pixel = _pixelStates[tokenId];

        uint128 energyAdded = uint128(msg.value * ENERGY_PER_ETH / 1e18); // Convert wei to energy units
        uint128 newEnergy = pixel.energy + energyAdded;
        if (newEnergy < pixel.energy) { // Check for overflow
            newEnergy = MAX_UINT128;
        }
        pixel.energy = newEnergy;
        pixel.lastUpdateTime = uint48(block.timestamp);
        pixel.influenceRadius = _calculateInfluenceRadius(pixel.energy); // Recalculate influence based on new energy

        // Decay energy of this pixel before applying new energy? Or handle decay in batch jobs?
        // Let's rely on batch jobs or influence propagation to handle decay for performance.

        emit PixelEnergized(tokenId, energyAdded, pixel.energy);
        emit PixelStateUpdated(tokenId, pixel, _calculateDerivedColor(tokenId));
    }

    // Allows a user to request a random mutation for their pixel
    function requestPixelMutation(uint256 tokenId) public {
        require(_exists(tokenId), "Pixel does not exist");
        require(ownerOf(tokenId) == msg.sender, "Not pixel owner");
        // Add cost/energy burn check here if desired, e.g., require(pixel.energy >= MUTATION_COST, "Not enough energy");

        // Use Chainlink VRF to request randomness
        // We need 1 random word for simple mutation logic
        uint32 numWords = 1;
        uint256 requestId = requestRandomWords(vrfKeyHash, vrfSubscriptionId, numWords);

        vrfRequestIdToTokenId[requestId] = tokenId;

        emit MutationRequested(tokenId, requestId);
    }

    // Chainlink VRF callback function
    function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords) internal override {
        uint256 tokenId = vrfRequestIdToTokenId[requestId];
        require(_exists(tokenId), "VRF fulfilled for non-existent pixel"); // Should not happen if state is managed correctly

        // We only requested 1 random word
        uint256 randomness = randomWords[0];

        // Apply mutation effect based on randomness
        _applyMutationEffect(tokenId, randomness);

        // Clean up the mapping
        delete vrfRequestIdToTokenId[requestId];

        PixelState storage pixel = _pixelStates[tokenId]; // Get updated state
        emit MutationFulfilled(requestId, tokenId, randomness);
        emit PixelStateUpdated(tokenId, pixel, _calculateDerivedColor(tokenId));
    }

    // ===================================================================
    // Canvas & Global Evolution Functions
    // ===================================================================

    // Allows anyone to trigger propagation of influence from high-energy pixels in a batch
    // This function is designed to be called repeatedly by users or a keeper service
    // to distribute the computational cost of influence propagation.
    // Potentially reward the caller with a small amount of ETH or a separate token.
    function propagateInfluenceBatch(uint256 startTokenId, uint256 count) public {
        uint256 pixelsAffected = 0;
        uint256 endTokenId = startTokenId + count;
        if (endTokenId > totalPixels) {
            endTokenId = totalPixels;
        }

        for (uint256 tokenId = startTokenId; tokenId < endTokenId; ++tokenId) {
            if (!_exists(tokenId)) continue;

            PixelState storage sourcePixel = _pixelStates[tokenId];

            // Only propagate influence if the source pixel has sufficient energy/influence radius
            if (sourcePixel.energy == 0 || sourcePixel.influenceRadius == 0) {
                 continue;
            }

            // Iterate through neighbors within the influence radius and apply influence
            // This nested loop can be expensive, keep radius small or optimize
            for (int256 dy = -int256(sourcePixel.influenceRadius); dy <= int256(sourcePixel.influenceRadius); ++dy) {
                for (int256 dx = -int256(sourcePixel.influenceRadius); dx <= int256(sourcePixel.influenceRadius); ++dx) {
                     if (dx == 0 && dy == 0) continue; // Don't influence self

                     uint256 neighborTokenId = _getNeighborPixelIdSafe(tokenId, dx, dy);
                     if (neighborTokenId != 0 && _exists(neighborTokenId)) { // 0 indicates invalid coords
                         // Apply influence effect from sourcePixel to neighborTokenId
                         // The actual _applyInfluenceEffect logic defines the art's dynamics
                         _applyInfluenceEffect(tokenId, neighborTokenId);
                         pixelsAffected++;
                         // Note: Emitting events for every influenced pixel might exceed gas limit.
                         // Could aggregate or only emit for major changes.
                         // emit InfluencePropagated(tokenId, neighborTokenId, sourcePixel.influenceRadius);
                     }
                }
            }
        }

         emit CanvasUpdateBatchProcessed(startTokenId, count, pixelsAffected);
    }

    // Allows anyone to trigger general canvas updates (like energy decay) for a batch
    // Similar to propagateInfluenceBatch, callable in batches, potentially rewarded.
    function requestCanvasUpdateBatch(uint256 startTokenId, uint256 count) public {
         uint256 pixelsUpdated = 0;
         uint256 endTokenId = startTokenId + count;
         if (endTokenId > totalPixels) {
             endTokenId = totalPixels;
         }

         for (uint256 tokenId = startTokenId; tokenId < endTokenId; ++tokenId) {
             if (!_exists(tokenId)) continue;

             // Apply decay to the pixel's energy
             _decayEnergy(tokenId);
             // Add other time-based updates here if needed

             pixelsUpdated++;

             // Emit update event if state significantly changed by decay/updates?
             // Or rely on getPixelState/getPixelColor views reflecting the decay?
             // Let's rely on views for simplicity unless a major visual change occurs.
         }
         emit CanvasUpdateBatchProcessed(startTokenId, count, pixelsUpdated);
    }

    // Admin/Owner function to advance the global canvas epoch
    function triggerEpochChange() public onlyOwner {
        currentEpoch++;
        lastEpochChangeTime = uint48(block.timestamp);

        // Could trigger global events or state changes here, e.g.,
        // - reset global parameters
        // - trigger a forced mutation on some pixels
        // - change the _calculateDerivedColor logic based on epoch

        emit EpochChanged(currentEpoch, lastEpochChangeTime);
    }

    // ===================================================================
    // View Functions
    // ===================================================================

    // Get the full state struct of a pixel
    function getPixelState(uint256 tokenId) public view returns (PixelState memory) {
        require(_exists(tokenId), "Pixel does not exist");
        PixelState memory pixel = _pixelStates[tokenId];
        // Decay energy before returning state for view consistency (does not modify storage)
        // Note: This is a simplified view decay; actual state decay happens in batch updates.
        // For a precise view, you'd calculate decay based on current timestamp.
        // To keep view simple and gas cheap, return stored state or calculate decay lightly.
        // Let's return stored state + calculated decay for the view.
        pixel.energy = _calculateDecayedEnergy(tokenId);
        return pixel;
    }

     // Calculate and return the derived color of a pixel (the "art")
    function getPixelColor(uint256 tokenId) public view returns (uint24) {
        require(_exists(tokenId), "Pixel does not exist");
        return _calculateDerivedColor(tokenId);
    }

    // Get grid coordinates from token ID
    function getPixelCoords(uint255 tokenId) public pure returns (uint32 x, uint32 y) {
        return _tokenIdToCoords(tokenId);
    }

    // Get token ID from grid coordinates
    function getPixelIdFromCoords(uint255 x, uint255 y) public pure returns (uint256) {
        return _coordsToTokenId(x, y);
    }

    // Get current global canvas state parameters
    function getGlobalState() public view returns (uint16 epoch, uint48 lastChangeTime, uint16 decayFactor, uint16 mutationBasis, uint8 influenceAmount) {
        return (currentEpoch, lastEpochChangeTime, globalEnergyDecayFactor, mutationChanceBasis, influencePropagationAmount);
    }

    // Get token IDs of direct neighbors (up, down, left, right)
    function getNeighborPixelIds(uint256 tokenId) public view returns (uint256[4] memory) {
         (uint32 x, uint32 y) = _tokenIdToCoords(tokenId);
         uint256[4] memory neighbors;
         neighbors[0] = (y > 0) ? _coordsToTokenId(x, y - 1) : 0; // Up
         neighbors[1] = (y < canvasHeight - 1) ? _coordsToTokenId(x, y + 1) : 0; // Down
         neighbors[2] = (x > 0) ? _coordsToTokenId(x - 1, y) : 0; // Left
         neighbors[3] = (x < canvasWidth - 1) ? _coordsToTokenId(x + 1, y) : 0; // Right
         return neighbors;
    }

    // Return all token IDs owned by an address (provided by ERC721Enumerable)
    // function getTokenIdsForOwner(address owner) view returns (uint256[] memory);

    // ===================================================================
    // Admin/Utility Functions
    // ===================================================================

    // Allows the owner to withdraw ETH collected from energizePixel
    function withdrawFunds() public onlyOwner {
        (bool success,) = payable(owner()).call{value: address(this).balance}("");
        require(success, "Withdrawal failed");
    }

    // Set global parameters influencing canvas evolution
    function setGlobalParameters(uint16 _globalEnergyDecayFactor, uint16 _mutationChanceBasis, uint8 _influencePropagationAmount) public onlyOwner {
        globalEnergyDecayFactor = _globalEnergyDecayFactor;
        mutationChanceBasis = _mutationChanceBasis;
        influencePropagationAmount = _influencePropagationAmount;
    }

    // Set Chainlink VRF Subscription ID (needed if subscription changes)
    function setVRFSubscriptionId(uint64 _subscriptionId) public onlyOwner {
        vrfSubscriptionId = _subscriptionId;
    }

    // Burn a pixel - removes it permanently
    function burnPixel(uint256 tokenId) public {
        require(_exists(tokenId), "Pixel does not exist");
        require(ownerOf(tokenId) == msg.sender, "Not pixel owner");

        _burn(tokenId);
        emit PixelBurned(tokenId, msg.sender);
    }


    // ===================================================================
    // Internal Helper Functions
    // ===================================================================

    // Calculate decayed energy based on time passed since last update
    function _calculateDecayedEnergy(uint256 tokenId) internal view returns (uint128) {
        PixelState storage pixel = _pixelStates[tokenId];
        uint48 currentTime = uint48(block.timestamp);
        uint48 timePassed = currentTime - pixel.lastUpdateTime;

        if (globalEnergyDecayFactor == 0 || timePassed == 0 || pixel.energy == 0) {
            return pixel.energy; // No decay if factor is 0, no time passed, or no energy
        }

        // Simple linear decay based on time elapsed and decay factor
        // Avoid division by zero or excessive multiplication
        uint256 decayAmount = (uint256(pixel.energy) * timePassed) / (globalEnergyDecayFactor * 1 days); // Example: decayFactor * 1 day duration
        if (decayAmount >= pixel.energy) {
            return 0;
        }
        return pixel.energy - uint126(decayAmount); // Cast to uint126 to avoid overflow risk in subtraction, assuming decayAmount < pixel.energy
    }

    // Helper to update pixel energy after considering decay in update batches
    function _decayEnergy(uint256 tokenId) internal {
         PixelState storage pixel = _pixelStates[tokenId];
         uint128 currentEnergy = _calculateDecayedEnergy(tokenId);
         pixel.energy = currentEnergy;
         pixel.lastUpdateTime = uint48(block.timestamp); // Update timestamp after decay applied
         pixel.influenceRadius = _calculateInfluenceRadius(pixel.energy); // Recalculate influence
    }


    // Initialize state for a new pixel
    function _initializePixelState(uint256 tokenId, uint32 x, uint32 y) internal {
        // Example initialization: Set base color based on coordinates (simple pattern)
        uint24 initialColor = uint24(((x % 16) * 16 + (y % 16)) * 255 / 256); // Example pattern
        initialColor = (initialColor << 8) | uint24(((x + y) % 16) * 255 / 256);
        initialColor = (initialColor << 8) | uint24(((x * y) % 16) * 255 / 256);

        _pixelStates[tokenId] = PixelState({
            id: tokenId,
            x: x,
            y: y,
            baseColor: initialColor,
            energy: 0,
            lastUpdateTime: uint48(block.timestamp),
            stateFlags: 0, // Start with no flags
            mutationEpoch: 0, // No mutation yet
            influenceRadius: 0 // No influence initially
        });
        // No event here, PixelStateUpdated will be emitted by the minting function after this
    }

     // Calculate influence radius based on energy level
    function _calculateInfluenceRadius(uint128 energy) internal pure returns (uint8) {
        // Example: Radius increases logarithmically or step-wise with energy
        if (energy < ENERGY_PER_ETH * 10) return 0; // Need at least 10x base energy
        if (energy < ENERGY_PER_ETH * 100) return 1;
        if (energy < ENERGY_PER_ETH * 1000) return 2;
        // Cap at a reasonable value to limit gas costs in propagation
        return 3; // Max radius
    }

    // Apply mutation effect based on random number
    function _applyMutationEffect(uint256 tokenId, uint256 randomness) internal {
        PixelState storage pixel = _pixelStates[tokenId];

        // Example mutation logic:
        // If randomness is below mutationChanceBasis threshold, mutate color
        // The specific mutation effect can be complex and depend on pixel state, epoch, etc.
        if ((randomness % mutationChanceBasis) == 0) {
            // Mutate base color components randomly
            pixel.baseColor = uint24(randomness % MAX_UINT24);
            pixel.stateFlags |= 0x01; // Set a 'mutated' flag
            pixel.mutationEpoch = currentEpoch;
            pixel.lastUpdateTime = uint48(block.timestamp);
            emit PixelStateUpdated(tokenId, pixel, _calculateDerivedColor(tokenId)); // Emit update after significant change
        }
        // Add other potential mutation effects here... e.g., change flags, influence radius (carefully!)
    }

    // Apply influence from a source pixel to a target pixel
    function _applyInfluenceEffect(uint256 sourceTokenId, uint256 targetTokenId) internal {
        PixelState storage sourcePixel = _pixelStates[sourceTokenId];
        PixelState storage targetPixel = _pixelStates[targetTokenId];

        // Example influence logic:
        // - Target pixel's color shifts slightly towards source pixel's color based on source energy
        // - Target pixel gains a small amount of energy
        // - Target pixel might adopt some flags from source

        uint128 influenceEnergyAmount = sourcePixel.energy / 1000; // Example: 0.1% of source energy
        if (influenceEnergyAmount > 0) {
             targetPixel.energy += influenceEnergyAmount;
             if (targetPixel.energy > MAX_UINT128) targetPixel.energy = MAX_UINT128; // Cap energy

            // Simple color blending based on influence energy
            uint24 blendedColor = targetPixel.baseColor;
            uint24 sourceColor = sourcePixel.baseColor; // Or maybe use source's derived color? Using base color for simplicity

            uint256 influenceFactor = influenceEnergyAmount > 1e12 ? 1e12 : influenceEnergyAmount; // Cap factor for calculation
            uint256 blendRatio = influenceFactor / (1e12 + influenceFactor); // Blend more with higher influence

            uint8 r1 = uint8(blendedColor >> 16);
            uint8 g1 = uint8((blendedColor >> 8) & 0xFF);
            uint8 b1 = uint8(blendedColor & 0xFF);

            uint8 r2 = uint8(sourceColor >> 16);
            uint8 g2 = uint8((sourceColor >> 8) & 0xFF);
            uint8 b2 = uint8(sourceColor & 0xFF);

            uint8 r_new = uint8(uint256(r1) * (1 - blendRatio) + uint256(r2) * blendRatio);
            uint8 g_new = uint8(uint256(g1) * (1 - blendRatio) + uint256(g2) * blendRatio);
            uint8 b_new = uint8(uint256(b1) * (1 - blendRatio) + uint256(b2) * blendRatio);

            targetPixel.baseColor = (uint24(r_new) << 16) | (uint24(g_new) << 8) | uint24(b_new);

             targetPixel.lastUpdateTime = uint48(block.timestamp); // Update timestamp
             targetPixel.influenceRadius = _calculateInfluenceRadius(targetPixel.energy); // Recalculate target's radius
             emit PixelStateUpdated(targetTokenId, targetPixel, _calculateDerivedColor(targetTokenId)); // Emit update for target
        }
    }


    // The core art generation logic: calculate the final display color
    // This function can be highly complex and depend on various factors
    // (pixel state, energy, flags, neighbors' states, global epoch, time).
    function _calculateDerivedColor(uint256 tokenId) internal view returns (uint24) {
        PixelState storage pixel = _pixelStates[tokenId];

        uint24 finalColor = pixel.baseColor;
        uint128 currentEnergy = _calculateDecayedEnergy(tokenId); // Use decayed energy for calculation

        // Example Calculation Logic:
        // 1. Base color is the starting point.
        // 2. High energy pixels might appear brighter or have a glowing effect (mix with white/yellow based on energy).
        // 3. Mutated pixels (check flags) might have distinct colors or patterns.
        // 4. Influence from neighbors could subtly shift color towards average neighbor color or the color of the highest energy neighbor.
        // 5. Epoch could influence the palette or rendering style.

        // Effect 1: Energy brightness/glow
        if (currentEnergy > ENERGY_PER_ETH * 50) { // If energy is high enough
             uint256 energyBrightness = (currentEnergy / (ENERGY_PER_ETH * 50)); // Simple scaling factor
             if (energyBrightness > 10) energyBrightness = 10; // Cap effect

             uint8 r = uint8(finalColor >> 16);
             uint8 g = uint8((finalColor >> 8) & 0xFF);
             uint8 b = uint8(finalColor & 0xFF);

             // Mix with white based on energy
             r = uint8(Math.min(255, r + energyBrightness * 10));
             g = uint8(Math.min(255, g + energyBrightness * 10));
             b = uint8(Math.min(255, b + energyBrightness * 10));

             finalColor = (uint24(r) << 16) | (uint24(g) << 8) | uint24(b);
        }

        // Effect 2: Mutation visual indicator
        if ((pixel.stateFlags & 0x01) != 0) { // Check if 'mutated' flag is set
             // Example: Mutated pixels pulse between base color and green/purple based on epoch
             uint8 pulsatingComponent = uint8((block.timestamp % 256)); // Simple pulsing based on time

             uint8 r = uint8(finalColor >> 16);
             uint8 g = uint8((finalColor >> 8) & 0xFF);
             uint8 b = uint8(finalColor & 0xFF);

             if (currentEpoch % 2 == 0) { // Pulsate towards green in even epochs
                  g = uint8(Math.min(255, g + pulsatingComponent));
             } else { // Pulsate towards purple in odd epochs
                 r = uint8(Math.min(255, r + pulsatingComponent));
                 b = uint8(Math.min(255, b + pulsatingComponent));
             }
             finalColor = (uint24(r) << 16) | (uint24(g) << 8) | uint24(b);
        }

        // Effect 3: Subtle neighbor influence based on their energy (more complex, requires reading neighbors)
        // This could involve averaging neighbor colors, or picking the dominant neighbor color, etc.
        // For simplicity in this example, we rely on _applyInfluenceEffect modifying baseColor directly.

        return finalColor;
    }

    // Convert (x, y) coordinates to a unique token ID
    function _coordsToTokenId(uint256 x, uint256 y) internal pure returns (uint256) {
        // Ensure coordinates fit within uint32 before conversion
        require(x < 2**32 && y < 2**32, "Coords too large for uint32");
        // Simple mapping: ID = y * width + x
        return y * canvasWidth + x;
    }

    // Convert a token ID back to (x, y) coordinates
    function _tokenIdToCoords(uint256 tokenId) internal pure returns (uint32 x, uint32 y) {
        // Ensure tokenId is within the bounds implied by uint32 coords and max dimensions
        // We rely on canvasWidth being reasonable (< 2^32) for this to not overflow intermediates.
        require(tokenId < 2**64, "Token ID too large"); // Basic sanity check

        // Inverse mapping: y = ID / width, x = ID % width
        // Requires canvasWidth to be non-zero, which is checked in constructor.
        y = uint32(tokenId / canvasWidth);
        x = uint32(tokenId % canvasWidth);

         // Double check bounds - this is implicit if tokenId is valid but good practice
         // require(x < canvasWidth && y < canvasHeight, "Invalid token ID coordinates"); // Removed pure flag if enabling this
    }

     // Helper to get neighbor token ID safely, returns 0 for out of bounds
    function _getNeighborPixelIdSafe(uint256 tokenId, int256 dx, int256 dy) internal view returns (uint256) {
        (uint32 x, uint32 y) = _tokenIdToCoords(tokenId);
        int256 neighborX = int256(x) + dx;
        int256 neighborY = int256(y) + dy;

        if (neighborX < 0 || neighborX >= int256(canvasWidth) || neighborY < 0 || neighborY >= int256(canvasHeight)) {
            return 0; // Out of bounds
        }

        return _coordsToTokenId(uint256(neighborX), uint256(neighborY));
    }

     // Helper to get neighbor pixel state safely, returns zeroed struct for invalid or non-existent
     function _getNeighborPixelState(uint256 tokenId, int256 dx, int256 dy) internal view returns (PixelState memory) {
         uint256 neighborTokenId = _getNeighborPixelIdSafe(tokenId, dx, dy);
         if (neighborTokenId == 0 || !_exists(neighborTokenId)) {
              return PixelState(0, 0, 0, 0, 0, 0, 0, 0, 0); // Return zeroed struct
         }
         // Recursively get neighbor's state, including decay for the view
         // Note: This could lead to deep call stacks if influenceRadius is large and neighbors call neighbors
         // Consider iterative approach or capping recursion depth if performance is critical.
         // For simplicity here, we'll just return the stored state, assuming decay is handled by batches.
         return _pixelStates[neighborTokenId]; // Return stored state
     }

    // Basic Math Library (Solidity 0.8 doesn't have built-in min/max for all types)
    library Math {
        function min(uint8 a, uint8 b) internal pure returns (uint8) {
            return a < b ? a : b;
        }
         function max(uint8 a, uint8 b) internal pure returns (uint8) {
            return a > b ? a : b;
        }
         function min(uint256 a, uint256 b) internal pure returns (uint256) {
             return a < b ? a : b;
         }
         function max(uint256 a, uint256 b) internal pure returns (uint256) {
             return a > b ? a : b;
         }
    }
}

// Helper contracts needed (from OpenZeppelin and Chainlink):
// @openzeppelin/contracts/token/ERC721/ERC721.sol
// @openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol
// @openzeppelin/contracts/access/Ownable.sol
// @openzeppelin/contracts/utils/Strings.sol (Used implicitly by ERC721 or explicitly if needed elsewhere)
// @chainlink/contracts/src/v0.8/vrf/VRFConsumerBaseV2.sol
// @chainlink/contracts/src/v0.8/interfaces/KeeperCompatibleInterface.sol (Optional, for keeper automation)

```

**Explanation of Key Functions and Concepts:**

1.  **`PixelState` Struct:** This is the core of the dynamic NFT. Instead of just an ID and owner, each pixel NFT maps to this struct containing its unique, mutable properties on-chain.
2.  **`safeMint` Override:** The standard ERC721 minting is wrapped to automatically call `_initializePixelState`, setting up the initial look/properties of a pixel when it's first created.
3.  **`energizePixel`:** A `payable` function demonstrating user interaction changing state. Sending ETH (or a specific token) increases the `energy` field, which can influence the pixel's derived color and its `influenceRadius`.
4.  **`requestPixelMutation` & `fulfillRandomWords`:** Integrates Chainlink VRF. A user initiates a request, and the `fulfillRandomWords` callback receives a verifiable random number which is then used by `_applyMutationEffect` to potentially change the pixel's `baseColor` or `stateFlags`.
5.  **`_calculateDerivedColor`:** This is the *art generation logic*. It's a `view` function that takes the pixel's *current on-chain state* (including potentially decayed energy) and the state of its neighbors, and computes the final 24-bit RGB color. This is where the complex, generative patterns based on interaction and evolution would be defined. A `tokenURI` endpoint would read this state and display the result.
6.  **`propagateInfluenceBatch` & `requestCanvasUpdateBatch`:** These functions are designed to manage the computational cost of canvas-wide evolution. Instead of a single, monolithic update function that would hit gas limits, anyone can call these functions to process a small `BATCH_SIZE` of pixels. This decentralizes the "rendering" and "maintenance" of the canvas state. They could be triggered by users or automated by Chainlink Keepers.
7.  **Epochs:** The `currentEpoch` and `triggerEpochChange` allow for distinct phases in the canvas's life, potentially altering the `_calculateDerivedColor` logic or global parameters over time, creating distinct visual eras.
8.  **Coordinate <-> ID Mapping:** Simple `_coordsToTokenId` and `_tokenIdToCoords` helpers are used to manage the grid structure.
9.  **`tokenURI`:** This points to an external service (not part of the contract itself, as generating images on-chain is too expensive) that reads the dynamic state (`getPixelState`, `getPixelColor`) from the contract via RPC and serves the metadata JSON and potentially a dynamically rendered image URL.

This contract provides a framework for a highly interactive and visually evolving NFT collection, moving beyond static images by leveraging on-chain state and programmed evolution rules. Remember that implementing the full, detailed art generation logic within `_calculateDerivedColor` and `_applyInfluenceEffect` is the most creative part and would require careful design based on the desired visual outcome. The batch processing functions also need careful gas optimization depending on the complexity of the logic they trigger.