Okay, let's design a smart contract that represents a dynamic, evolving canvas where users can interact, and states can be captured as NFTs. This blends generative art concepts, state-dependent logic, interaction mechanics, and NFTs, aiming for novelty beyond typical token contracts.

We'll call it "QuantumCanvas". The idea is that the canvas itself is a complex state governed by rules, and users can pay to influence parts of it, causing it to change over time. Specific states or areas can then be "snapshot" into static ERC721 NFTs.

**Advanced Concepts Used:**

1.  **State-Dependent Evolution:** The core state of the "pixels" or "cells" changes based on time, user interactions, and potentially neighbors' states, governed by on-chain rules.
2.  **Generative Mechanics:** The `applyCanvasEvolutionStep` function simulates a form of on-chain cellular automaton or rule-based system that modifies the canvas state.
3.  **Dynamic NFTs:** While the *snapshot* NFTs are static representations, they derive from a constantly *dynamic* underlying asset (the canvas).
4.  **Complex Data Structure on Chain:** Storing a grid state efficiently using a mapping.
5.  **Time-Based Logic:** Cell states decay or evolve based on time elapsed since the last interaction.
6.  **Parameterized Interactions:** User actions (paint, boost, propagate) have configurable costs and effects.
7.  **Snapshotting Specific State Subsets:** NFTs can represent arbitrary rectangular regions of the canvas at a specific moment.

---

## QuantumCanvas Smart Contract Outline

*   **Overview:** A smart contract managing a grid-based canvas where users can interact to influence cell states. The canvas state evolves over time based on defined rules. Users can mint NFTs that capture specific areas or the entire canvas state at a moment in time.
*   **State Variables:**
    *   Canvas dimensions (`width`, `height`).
    *   Mapping storing `CellState` for each cell index.
    *   Configuration parameters (interaction costs, decay rates, snapshot cost, etc.).
    *   Snapshot NFT counter and mapping to store snapshot area data.
    *   Mapping for ERC721 token approvals and balances.
    *   Base URI for snapshot NFT metadata.
    *   Paused state flag.
*   **Structs:**
    *   `CellState`: Contains properties like color, energy level, last update timestamp, maybe influence type.
    *   `SnapshotArea`: Stores the coordinates (`x1, y1, x2, y2`) for a specific snapshot NFT.
*   **Events:** Signalling key actions like cell updates, configuration changes, snapshots, transfers.
*   **Modifiers:** Access control (`onlyOwner`), reentrancy protection (`nonReentrant`), paused checks (`whenNotPaused`).
*   **Functions:** (Grouped by category)

    *   **Canvas Interaction (User Callable):**
        *   `paintCell`: Sets the color of a single cell, consumes energy, updates timestamp, costs Ether.
        *   `boostCell`: Increases the energy of a cell, updates timestamp, costs Ether.
        *   `propagateInfluence`: Applies an effect (e.g., color, energy) from a cell to its neighbors within a radius, consuming energy, updates timestamps, costs Ether proportional to area.
        *   `applyCanvasEvolutionStep`: Triggers the rule-based evolution logic for a specified batch of cells based on time and neighbor states. Costs Ether or gas.
        *   `triggerFullCanvasEvolution`: (Owner or privileged role) Triggers evolution step across a larger portion or the entire canvas (potentially batching internally).
        *   `getCellState`: Reads the current state of a single cell.
        *   `getMultipleCellStates`: Reads the state of multiple cells by coordinates.

    *   **Configuration (Owner Only):**
        *   `setInteractionCost`: Sets the Ether cost for Paint, Boost, Propagate actions.
        *   `setDecayRate`: Sets the rate at which cell energy decays per unit of time.
        *   `setPropagationCostMultiplier`: Sets a multiplier for the propagate influence cost based on radius.
        *   `setSnapshotCost`: Sets the Ether cost for minting snapshot NFTs.
        *   `setSnapshotNFTBaseURI`: Sets the base URI for fetching NFT metadata.
        *   `pauseInteractions`: Toggles user interaction pause.
        *   `setEvolutionParams`: Sets parameters that control the `applyCanvasEvolutionStep` rules.
        *   `withdrawFunds`: Allows owner to withdraw accumulated Ether.
        *   `setCanvasDimensions`: (Careful, potentially breaking) Resizes the canvas (maybe only before interactions start).

    *   **Snapshotting / NFT (User Callable):**
        *   `snapshotCellArea`: Mints an ERC721 NFT representing the state of a defined rectangular area. Requires payment.
        *   `snapshotFullCanvas`: Mints an ERC721 NFT representing the state of the entire canvas. Requires payment.
        *   `getCellAreaSnapshotData`: Retrieves the coordinates stored for a specific snapshot NFT.

    *   **ERC721 Standard (Inherited/Overridden):**
        *   `balanceOf`: Returns the number of NFTs owned by an address.
        *   `ownerOf`: Returns the owner of a specific token ID.
        *   `transferFrom`: Transfers ownership of an NFT.
        *   `safeTransferFrom`: Safe transfer of ownership.
        *   `approve`: Approves another address to transfer an NFT.
        *   `getApproved`: Returns the approved address for an NFT.
        *   `setApprovalForAll`: Approves/unapproves an operator for all NFTs.
        *   `isApprovedForAll`: Checks if an address is an approved operator.
        *   `tokenURI`: Returns the metadata URI for an NFT.

    *   **Utilities:**
        *   `getCanvasDimensions`: Returns the canvas width and height.
        *   `getInteractionCost`: Returns the current cost for a specific interaction type.
        *   `getDecayRate`: Returns the current decay rate.
        *   `getSnapshotCost`: Returns the current snapshot cost.

---

## QuantumCanvas Smart Contract Source Code

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";

// --- QuantumCanvas Smart Contract ---
//
// Overview:
// A smart contract that manages a grid-based visual canvas.
// Users can interact with cells on the canvas (paint, boost energy, propagate influence)
// by paying Ether. Cell states (color, energy) evolve over time based on
// predefined rules influenced by energy decay and neighbor interactions,
// triggered by the `applyCanvasEvolutionStep` function.
// The canvas state can be captured at any moment in time for specific
// rectangular areas or the entire canvas, and minted as unique ERC721 NFTs.
//
// Advanced Concepts:
// - State-Dependent Evolution: Canvas state changes based on time and rules.
// - Generative Mechanics: On-chain rules simulate life-like patterns (`applyCanvasEvolutionStep`).
// - Dynamic Underlying Asset: NFTs are snapshots of a constantly changing canvas.
// - Complex Data Structure: Storing grid state efficiently.
// - Time-Based Logic: Decay and evolution rely on timestamps.
// - Parameterized Interactions & Economy: Configurable costs for actions influencing state.
// - Snapshotting Subsets: Capturing specific areas as NFTs.
//
// ERC721 Token:
// This contract also functions as an ERC721 token for the minted snapshot NFTs.
// The metadata URI for each token will typically point to an off-chain service
// that renders the snapshot image based on the stored cell data or coordinates.
//
// --- Function Summary ---
//
// Canvas Interaction (User Callable):
// - constructor(uint256 initialWidth, uint256 initialHeight, uint256 initialDecayRate, uint256 initialSnapshotCost): Initializes canvas dimensions, decay rate, and snapshot cost.
// - paintCell(uint256 x, uint256 y, bytes3 color): Sets cell color, consumes energy, updates time, charges fee.
// - boostCell(uint256 x, uint256 y): Increases cell energy, updates time, charges fee.
// - propagateInfluence(uint256 x, uint256 y, uint256 radius): Spreads color/energy from (x,y) to neighbors within radius, consumes energy, updates time, charges fee.
// - applyCanvasEvolutionStep(uint256[] cellIndices): Applies evolution rules (decay, neighbor influence) to a batch of cells.
// - triggerFullCanvasEvolution(uint256 batchSize): (Owner or whitelisted) Triggers evolution across the entire canvas in batches.
// - getCellState(uint256 x, uint256 y): Reads the current state of a single cell.
// - getMultipleCellStates(uint256[] cellIndices): Reads states of multiple cells by index.
//
// Configuration (Owner Only):
// - setInteractionCost(uint8 interactionType, uint256 cost): Sets cost for a specific interaction type.
// - setDecayRate(uint256 rate): Sets the global energy decay rate.
// - setPropagationCostMultiplier(uint256 multiplier): Sets the cost multiplier for propagate based on radius area.
// - setSnapshotCost(uint256 cost): Sets the cost to mint a snapshot NFT.
// - setSnapshotNFTBaseURI(string memory uri): Sets the base URI for NFT metadata.
// - pauseInteractions(bool paused): Pauses/unpauses user interactions.
// - setEvolutionParams(uint256 minEnergyForInfluence, uint256 neighborInfluenceFactor): Configures evolution rules.
// - withdrawFunds(): Allows owner to withdraw contract balance.
// - setCanvasDimensions(uint256 newWidth, uint256 newHeight): (Requires careful use, potentially disruptive) Resizes canvas.
//
// Snapshotting / NFT (User Callable):
// - snapshotCellArea(uint256 x1, uint256 y1, uint256 x2, uint256 y2): Mints NFT for specified rectangular area.
// - snapshotFullCanvas(): Mints NFT for the entire canvas.
// - getCellAreaSnapshotData(uint256 tokenId): Retrieves coordinates for an area snapshot NFT.
//
// ERC721 Standard (Inherited from OpenZeppelin ERC721):
// - supportsInterface(bytes4 interfaceId): Checks if interface is supported.
// - balanceOf(address owner): Number of NFTs owned by address.
// - ownerOf(uint256 tokenId): Owner of token ID.
// - transferFrom(address from, address to, uint256 tokenId): Transfers token ownership.
// - safeTransferFrom(address from, address to, uint256 tokenId): Safe transfer.
// - approve(address to, uint256 tokenId): Approves address for token transfer.
// - getApproved(uint256 tokenId): Gets approved address for token.
// - setApprovalForAll(address operator, bool approved): Sets operator approval for all tokens.
// - isApprovedForAll(address owner, address operator): Checks if operator is approved.
// - tokenURI(uint256 tokenId): Returns metadata URI for token.
//
// Utilities (Getter Functions):
// - getCanvasDimensions(): Returns width and height.
// - getInteractionCost(uint8 interactionType): Returns cost for interaction type.
// - getDecayRate(): Returns the decay rate.
// - getPropagationCostMultiplier(): Returns the propagation cost multiplier.
// - getSnapshotCost(): Returns the snapshot cost.
// - getCanvasTotalCells(): Returns total number of cells (width * height).

contract QuantumCanvas is ERC721, Ownable, ReentrancyGuard {

    struct CellState {
        bytes3 color; // RGB color
        uint256 energy; // Level of "aliveness" or stability
        uint40 lastUpdateTime; // Timestamp of last interaction or evolution step
        uint40 lastEvolutionTime; // Timestamp of last evolution step application
    }

    struct SnapshotArea {
        uint256 x1;
        uint256 y1;
        uint256 x2;
        uint256 y2;
        uint256 timestamp; // Timestamp when snapshot was taken
    }

    uint256 public immutable width;
    uint256 public immutable height;

    mapping(uint256 => CellState) private cells; // Key is index = y * width + x

    // Interaction Types
    enum InteractionType { Paint, Boost, Propagate }
    mapping(uint8 => uint256) public interactionCosts; // Cost in Wei

    uint256 public decayRate; // Energy units lost per second per cell if not interacted with
    uint256 public propagationCostMultiplier; // Cost multiplier for propagate based on area (radius^2)

    uint256 public snapshotCost; // Cost in Wei to mint a snapshot NFT
    uint256 private nextSnapshotId = 0;

    // Mapping to store snapshot area data for minted NFTs
    mapping(uint256 => SnapshotArea) private _snapshotAreas;
    // 0 indicates a full canvas snapshot, >0 indicates area snapshot

    bool public paused = false;

    // Parameters for the evolution rules (Owner settable)
    uint256 public minEnergyForInfluence = 100; // Minimum energy for a cell to influence neighbors
    uint256 public neighborInfluenceFactor = 50; // Percentage (0-100) of neighbor's color/energy that influences a cell during evolution

    string private _snapshotNFTBaseURI;

    // --- Events ---
    event CellPainted(uint256 x, uint256 y, bytes3 color, address indexed by);
    event CellBoosted(uint256 x, uint256 y, uint256 newEnergy, address indexed by);
    event InfluencePropagated(uint256 x, uint256 y, uint256 radius, address indexed by);
    event CanvasEvolutionStep(uint256[] indexed cellIndices, uint256 timestamp);
    event SnapshotMinted(uint256 indexed tokenId, address indexed owner, uint256 x1, uint256 y1, uint256 x2, uint256 y2);
    event InteractionCostSet(uint8 indexed interactionType, uint256 cost);
    event DecayRateSet(uint256 rate);
    event PropagationCostMultiplierSet(uint256 multiplier);
    event SnapshotCostSet(uint256 cost);
    event Paused(bool paused);
    event EvolutionParamsSet(uint256 minEnergyForInfluence, uint256 neighborInfluenceFactor);

    // --- Modifiers ---
    modifier whenNotPaused() {
        require(!paused, "Contract is paused");
        _;
    }

    modifier onlyExistingToken(uint256 tokenId) {
        require(_exists(tokenId), "Token does not exist");
        _;
    }

    // --- Constructor ---
    constructor(uint256 initialWidth, uint256 initialHeight, uint256 initialDecayRate, uint256 initialSnapshotCost)
        ERC721("QuantumCanvasSnapshot", "QCS")
        Ownable(msg.sender)
    {
        require(initialWidth > 0 && initialHeight > 0, "Invalid dimensions");
        require(initialWidth <= 256 && initialHeight <= 256, "Dimensions too large (max 256x256)"); // Keep reasonable for gas
        width = initialWidth;
        height = initialHeight;
        decayRate = initialDecayRate;
        snapshotCost = initialSnapshotCost;

        // Set initial costs (example values)
        interactionCosts[uint8(InteractionType.Paint)] = 0.001 ether;
        interactionCosts[uint8(InteractionType.Boost)] = 0.0005 ether;
        // Cost for propagate is baseCost + radius*radius * multiplier
        interactionCosts[uint8(InteractionType.Propagate)] = 0.002 ether;
        propagationCostMultiplier = 1 ether / 100; // Example: 0.01 ether per square unit of radius area

        // Initialize all cells (optional, can be done on first interaction/read)
        // Omitting full init loop to save gas on deployment. Cells will default to zero/empty.
    }

    // --- Internal Helper Functions ---
    function _getCellIndex(uint256 x, uint256 y) internal view returns (uint256) {
        require(x < width && y < height, "Coordinates out of bounds");
        return y * width + x;
    }

    function _isCellValid(uint256 x, uint256 y) internal view returns (bool) {
         return x < width && y < height;
    }

    function _applyDecay(uint256 x, uint256 y, uint256 cellIndex) internal {
        CellState storage cell = cells[cellIndex];
        if (cell.lastUpdateTime == 0) {
             // Cell has never been updated, treat as initial state with max decay
             cell.lastUpdateTime = uint40(block.timestamp);
             cell.lastEvolutionTime = uint40(block.timestamp);
        }

        uint256 timeElapsed = block.timestamp - cell.lastUpdateTime;
        uint256 energyLoss = timeElapsed * decayRate;

        if (cell.energy > energyLoss) {
            cell.energy -= energyLoss;
        } else {
            cell.energy = 0;
        }
        cell.lastUpdateTime = uint40(block.timestamp);
    }

     // Calculates the next state based on current state, decay, and neighbors (simple rule)
    function _calculateNextCellState(uint256 x, uint256 y, uint256 cellIndex) internal view returns (bytes3 nextColor, uint256 nextEnergy, uint40 newEvolutionTime) {
        CellState storage currentCell = cells[cellIndex];

        // Apply decay first
        uint256 decayedEnergy = currentCell.energy;
        if (currentCell.lastEvolutionTime > 0) { // Only apply decay if it has evolved before
            uint256 timeSinceLastEvolution = block.timestamp - currentCell.lastEvolutionTime;
            uint256 energyLoss = timeSinceLastEvolution * decayRate;
             if (decayedEnergy > energyLoss) {
                decayedEnergy -= energyLoss;
            } else {
                decayedEnergy = 0;
            }
        } else {
             // If never evolved, assume initial state, decay applied on first interaction/evolution
             decayedEnergy = currentCell.energy; // Decay applied externally before calling this often
        }

        nextEnergy = decayedEnergy;
        nextColor = currentCell.color;
        newEvolutionTime = uint40(block.timestamp);

        // Simple evolution rule: if energy is high enough, average color with neighbors
        if (decayedEnergy >= minEnergyForInfluence) {
            uint256 neighborX;
            uint256 neighborY;
            uint256 liveNeighborCount = 0;
            uint256 totalNeighborEnergy = 0;
            uint256 totalNeighborR = 0;
            uint256 totalNeighborG = 0;
            uint256 totalNeighborB = 0;

            // Check 8 neighbors
            for (int i = -1; i <= 1; i++) {
                for (int j = -1; j <= 1; j++) {
                    if (i == 0 && j == 0) continue;

                    neighborX = x + uint256(int256(i));
                    neighborY = y + uint256(int256(j));

                    if (_isCellValid(neighborX, neighborY)) {
                        uint256 neighborIndex = _getCellIndex(neighborX, neighborY);
                        CellState storage neighborCell = cells[neighborIndex];
                        // Apply neighbor decay for calculation consistency? No, assume decay is applied before this.
                        // Just use current state for influence calculation.

                        if (neighborCell.energy > 0) { // Only consider neighbors with energy
                            liveNeighborCount++;
                            totalNeighborEnergy += neighborCell.energy;
                            totalNeighborR += uint256(neighborCell.color[0]);
                            totalNeighborG += uint256(neighborCell.color[1]);
                            totalNeighborB += uint256(neighborCell.color[2]);
                        }
                    }
                }
            }

            if (liveNeighborCount > 0) {
                // Calculate average neighbor color
                uint8 avgNeighborR = uint8(totalNeighborR / liveNeighborCount);
                uint8 avgNeighborG = uint8(totalNeighborG / liveNeighborCount);
                uint8 avgNeighborB = uint8(totalNeighborB / liveNeighborCount);

                // Blend current color with average neighbor color based on influence factor
                uint256 factor = neighborInfluenceFactor; // 0-100
                uint256 currentFactor = 100 - factor;

                uint8 nextR = uint8((uint256(currentCell.color[0]) * currentFactor + uint256(avgNeighborR) * factor) / 100);
                uint8 nextG = uint8((uint256(currentCell.color[1]) * currentFactor + uint256(avgNeighborG) * factor) / 100);
                uint8 nextB = uint8((uint256(currentCell.color[2]) * currentFactor + uint256(avgNeighborB) * factor) / 100);

                nextColor = bytes3(nextR, nextG, nextB);

                // Energy might fluctuate based on neighbor energy (optional complexity)
                // nextEnergy = (decayedEnergy + totalNeighborEnergy / (liveNeighborCount * 2)); // Simple average influence
                // Capped at some max energy?
                 // nextEnergy = Math.min(decayedEnergy + (totalNeighborEnergy / liveNeighborCount) / 10, 1000); // Example cap
            }
        } else {
            // If energy is too low, color might tend towards black or decay randomly
            // Simple rule: low energy cells tend to lose color intensity
             uint256 energyRatio = decayedEnergy * 100 / minEnergyForInfluence; // 0-100
             uint8 nextR = uint8(uint256(currentCell.color[0]) * energyRatio / 100);
             uint8 nextG = uint8(uint256(currentCell.color[1]) * energyRatio / 100);
             uint8 nextB = uint8(uint256(currentCell.color[2]) * energyRatio / 100);
             nextColor = bytes3(nextR, nextG, nextB);
        }
    }


    function _chargeFee(uint256 amount) internal nonReentrant {
        require(msg.value >= amount, "Insufficient Ether sent");
        if (amount > 0) {
            (bool success, ) = payable(owner()).call{value: amount}("");
            require(success, "Payment failed");
        }
    }

    // --- Canvas Interaction Functions ---

    function paintCell(uint256 x, uint256 y, bytes3 color) external payable whenNotPaused nonReentrant {
        uint256 cellIndex = _getCellIndex(x, y);
        _chargeFee(interactionCosts[uint8(InteractionType.Paint)]);

        CellState storage cell = cells[cellIndex];
        _applyDecay(x, y, cellIndex); // Apply decay before interaction

        cell.color = color;
        cell.energy = Math.min(cell.energy + 50, 1000); // Example: Gain 50 energy, capped
        cell.lastUpdateTime = uint40(block.timestamp);

        emit CellPainted(x, y, color, msg.sender);
    }

    function boostCell(uint256 x, uint256 y) external payable whenNotPaused nonReentrant {
        uint256 cellIndex = _getCellIndex(x, y);
        _chargeFee(interactionCosts[uint8(InteractionType.Boost)]);

        CellState storage cell = cells[cellIndex];
        _applyDecay(x, y, cellIndex); // Apply decay before interaction

        cell.energy = Math.min(cell.energy + 200, 1000); // Example: Gain 200 energy, capped
        cell.lastUpdateTime = uint40(block.timestamp);

        emit CellBoosted(x, y, cell.energy, msg.sender);
    }

    function propagateInfluence(uint256 x, uint256 y, uint256 radius) external payable whenNotPaused nonReentrant {
        require(radius > 0 && radius <= 5, "Radius must be between 1 and 5"); // Limit radius for gas
        uint256 area = radius * radius;
        uint256 totalCost = interactionCosts[uint8(InteractionType.Propagate)] + area * propagationCostMultiplier;
        _chargeFee(totalCost);

        uint256 centerCellIndex = _getCellIndex(x, y);
        CellState storage centerCell = cells[centerCellIndex];

        _applyDecay(x, y, centerCellIndex); // Decay center cell

        // Apply a simple influence (e.g., average color/energy) to neighbors within radius
        // This is a gas-intensive operation, radius should be small.
        // In a real advanced system, this might be more complex, maybe requiring multiple transactions or a specialized layer.

        uint256 energyConsumedPerCell = centerCell.energy / (area * 4); // Consume energy from the center cell
        bytes3 influenceColor = centerCell.color; // Color to propagate

        uint256 affectedCells = 0;
        for (int i = -int(radius); i <= int(radius); i++) {
            for (int j = -int(radius); j <= int(radius); j++) {
                 if (i == 0 && j == 0) continue; // Skip the center cell

                 uint256 neighborX = x + uint256(int256(i));
                 uint256 neighborY = y + uint256(int256(j));

                 if (_isCellValid(neighborX, neighborY)) {
                     uint256 neighborIndex = _getCellIndex(neighborX, neighborY);
                     CellState storage neighborCell = cells[neighborIndex];

                     _applyDecay(neighborX, neighborY, neighborIndex); // Decay neighbor

                     // Simple influence: blend color, add some energy
                     uint256 currentEnergy = neighborCell.energy;
                     bytes3 currentColor = neighborCell.color;

                     // Blend color (e.g., 50/50 blend with influence color)
                     uint8 blendedR = uint8((uint256(currentColor[0]) + uint256(influenceColor[0])) / 2);
                     uint8 blendedG = uint8((uint256(currentColor[1]) + uint256(influenceColor[1])) / 2);
                     uint8 blendedB = uint8((uint256(currentColor[2]) + uint256(influenceColor[2])) / 2);
                     neighborCell.color = bytes3(blendedR, blendedG, blendedB);

                     // Add energy (capped)
                     neighborCell.energy = Math.min(currentEnergy + energyConsumedPerCell, 1000);
                     neighborCell.lastUpdateTime = uint40(block.timestamp);
                     affectedCells++;
                 }
            }
        }

        centerCell.energy = centerCell.energy > (energyConsumedPerCell * affectedCells) ? centerCell.energy - (energyConsumedPerCell * affectedCells) : 0;
        centerCell.lastUpdateTime = uint40(block.timestamp); // Update center cell time as well

        emit InfluencePropagated(x, y, radius, msg.sender);
    }

    // This function applies the rule-based evolution step to a batch of cells.
    // Anyone can call this, paying gas to help evolve the canvas.
    // The actual evolution logic is in _calculateNextCellState.
    function applyCanvasEvolutionStep(uint256[] calldata cellIndices) external whenNotPaused {
        // Limit the number of cells processed in one call to manage gas costs
        require(cellIndices.length <= 100, "Batch size too large (max 100)"); // Adjustable limit

        uint256 currentTime = block.timestamp;

        // Cache necessary values before modifying cells
        // This is crucial because cell states can affect neighbor calculations
        // In a simple rule like decay + blend, reading neighbors might be okay,
        // but for complex cellular automata, you need a "next state" buffer.
        // For this example, we will read neighbors directly, which is simpler but
        // means cell updates within the loop affect subsequent neighbor calculations
        // *within the same block*. This might not be ideal for simulating a single
        // discrete time step across the whole canvas, but saves gas.
        // A true "next state" approach would involve storing next states and applying
        // them in a second pass or using a more complex state representation.

        uint256 x;
        uint256 y;
        uint256 index;

        for (uint i = 0; i < cellIndices.length; i++) {
            index = cellIndices[i];
            x = index % width;
            y = index / width;

             if (!_isCellValid(x, y)) {
                continue; // Skip invalid indices if provided
            }

            CellState storage cell = cells[index];

            // Apply decay before calculating next state based on current state and neighbors
            _applyDecay(x, y, index);

            // Calculate the next state based on the *current* (decayed) state and neighbors
            (bytes3 nextColor, uint256 nextEnergy, uint40 newEvolutionTime) = _calculateNextCellState(x, y, index);

            // Apply the calculated next state
            cell.color = nextColor;
            cell.energy = nextEnergy;
            // Only update lastEvolutionTime, lastUpdateTime is updated on user interaction/decay
            cell.lastEvolutionTime = newEvolutionTime; // Ensure this timestamp is updated consistently

            // Note: This loop modifies cell states as it goes, meaning later cells in the batch
            // will see the *already updated* state of earlier cells *in the same batch*.
            // For a truly synchronized single time-step, all next states would need to be calculated
            // based on the state *before* the loop, then applied. This requires caching states,
            // which is gas-intensive for larger batches. This simplified approach is more gas-friendly.
        }

        emit CanvasEvolutionStep(cellIndices, currentTime);
    }

    // Allows the owner (or privileged user) to trigger evolution across the whole canvas in batches
    function triggerFullCanvasEvolution(uint256 batchSize) external onlyOwner {
         require(batchSize > 0 && batchSize <= 1000, "Batch size must be between 1 and 1000"); // Higher batch size for owner trigger

         uint256 totalCells = width * height;
         uint256 currentIndex = 0;
         uint256[] memory batchIndices = new uint256[](batchSize);

         // This is a simplified loop. In a real system, you might need to track
         // the last processed index or use a different iteration strategy
         // if this function can be called repeatedly before the whole canvas is covered.
         // For simplicity here, we assume one call attempts one full pass (or as many batches as possible).
         // A more robust system would use a state variable to track progress.

         uint256 cellsToProcess = Math.min(batchSize, totalCells - currentIndex);
         while (cellsToProcess > 0) {
             for (uint i = 0; i < cellsToProcess; i++) {
                 batchIndices[i] = currentIndex + i;
             }

             // Call the internal evolution step (this will still be limited by block gas limit)
             // Note: Directly calling applyCanvasEvolutionStep(batchIndices[:cellsToProcess]) might hit gas limits.
             // A pattern here might be to emit an event for an off-chain relayer to process batches,
             // or use a commit/reveal pattern, or rely on users calling `applyCanvasEvolutionStep`.
             // Direct call:
             _applyCanvasEvolutionStepInternal(batchIndices, cellsToProcess);

             currentIndex += cellsToProcess;
             if (currentIndex >= totalCells) break;
             cellsToProcess = Math.min(batchSize, totalCells - currentIndex);
         }

         // Note: This function might revert if the total gas for all batches exceeds the block gas limit.
         // It's often better to emit events for off-chain workers or have users trigger evolution.
    }

     // Internal helper for triggerFullCanvasEvolution
     function _applyCanvasEvolutionStepInternal(uint256[] memory cellIndices, uint256 count) internal {
         uint256 currentTime = block.timestamp;
         uint256 x;
         uint256 y;
         uint256 index;

         for (uint i = 0; i < count; i++) {
             index = cellIndices[i];
             x = index % width;
             y = index / width;

             // Already validated in the calling function, but good practice
             if (!_isCellValid(x, y)) continue;

             CellState storage cell = cells[index];
             _applyDecay(x, y, index);
             (bytes3 nextColor, uint256 nextEnergy, uint40 newEvolutionTime) = _calculateNextCellState(x, y, index);

             cell.color = nextColor;
             cell.energy = nextEnergy;
             cell.lastEvolutionTime = newEvolutionTime;
         }

         emit CanvasEvolutionStep(cellIndices, currentTime); // Emit event for the *batch* that was processed
     }


    function getCellState(uint256 x, uint256 y) external view returns (CellState memory) {
        uint256 cellIndex = _getCellIndex(x, y);
        CellState memory cell = cells[cellIndex];

        // Apply decay simulation for reading
        if (cell.lastUpdateTime > 0) {
            uint256 timeElapsed = block.timestamp - cell.lastUpdateTime;
             uint256 energyLoss = timeElapsed * decayRate;
             if (cell.energy > energyLoss) {
                cell.energy -= energyLoss;
            } else {
                cell.energy = 0;
            }
        } else {
             // If never updated, energy is 0, lastUpdateTime is now
             cell.energy = 0;
             cell.lastUpdateTime = uint40(block.timestamp);
        }
        // Evolution time decay simulation is complex on read, return last recorded evolution time
        // External systems reading state would need to calculate projected evolution based on rules and time elapsed since lastEvolutionTime

        return cell;
    }

    function getMultipleCellStates(uint256[] calldata cellIndices) external view returns (CellState[] memory) {
         CellState[] memory states = new CellState[](cellIndices.length);
         uint256 x;
         uint256 y;
         uint256 index;

         for (uint i = 0; i < cellIndices.length; i++) {
             index = cellIndices[i];
             x = index % width;
             y = index / width;

             if (_isCellValid(x,y)) {
                states[i] = cells[index];
                // Apply decay simulation for reading
                if (states[i].lastUpdateTime > 0) {
                    uint256 timeElapsed = block.timestamp - states[i].lastUpdateTime;
                     uint256 energyLoss = timeElapsed * decayRate;
                     if (states[i].energy > energyLoss) {
                        states[i].energy -= energyLoss;
                    } else {
                        states[i].energy = 0;
                    }
                } else {
                     states[i].energy = 0;
                     states[i].lastUpdateTime = uint40(block.timestamp);
                }
             } else {
                 // Return default/empty state for invalid indices
                 states[i] = CellState(bytes3(0,0,0), 0, 0, 0);
             }
         }
         return states;
    }


    // --- Configuration Functions (Owner Only) ---

    function setInteractionCost(uint8 interactionType, uint256 cost) external onlyOwner {
        require(interactionType <= uint8(InteractionType.Propagate), "Invalid interaction type");
        interactionCosts[interactionType] = cost;
        emit InteractionCostSet(interactionType, cost);
    }

    function setDecayRate(uint256 rate) external onlyOwner {
        decayRate = rate;
        emit DecayRateSet(rate);
    }

    function setPropagationCostMultiplier(uint256 multiplier) external onlyOwner {
        propagationCostMultiplier = multiplier;
        emit PropagationCostMultiplierSet(multiplier);
    }

    function setSnapshotCost(uint256 cost) external onlyOwner {
        snapshotCost = cost;
        emit SnapshotCostSet(cost);
    }

    function setSnapshotNFTBaseURI(string memory uri) external onlyOwner {
        _snapshotNFTBaseURI = uri;
        // No event for this one to potentially save gas if updated frequently off-chain
    }

    function pauseInteractions(bool _paused) external onlyOwner {
        paused = _paused;
        emit Paused(_paused);
    }

    function setEvolutionParams(uint256 _minEnergyForInfluence, uint256 _neighborInfluenceFactor) external onlyOwner {
         require(_neighborInfluenceFactor <= 100, "Neighbor influence factor cannot exceed 100%");
         minEnergyForInfluence = _minEnergyForInfluence;
         neighborInfluenceFactor = _neighborInfluenceFactor;
         emit EvolutionParamsSet(_minEnergyForInfluence, _neighborInfluenceFactor);
    }

    function withdrawFunds() external onlyOwner nonReentrant {
        uint256 balance = address(this).balance;
        require(balance > 0, "No Ether to withdraw");
        (bool success, ) = payable(msg.sender).call{value: balance}("");
        require(success, "Withdrawal failed");
    }

    // Warning: Resizing can lose current canvas state and is disruptive.
    // Consider making this only callable before any interactions occur.
    function setCanvasDimensions(uint256 newWidth, uint256 newHeight) external onlyOwner {
         // require(nextSnapshotId == 0, "Cannot resize after snapshots are minted"); // Example restriction
         require(newWidth > 0 && newHeight > 0, "Invalid dimensions");
         require(newWidth <= 256 && newHeight <= 256, "Dimensions too large (max 256x256)");

         // WARNING: This clears the entire canvas state!
         // A proper resizing would involve migrating existing cells, which is very complex and gas-intensive.
         // This implementation simply resets the canvas.
         assembly {
             // Zero out the mapping storage slot
             sstore(cells.slot, 0)
         }

         // Update dimensions - these are immutable in this design, cannot be changed after constructor.
         // To make dimensions mutable, they would need to be state variables, not immutable.
         // Revert if attempted:
         revert("Canvas dimensions are immutable after deployment");
         // To implement mutable dimensions: remove `immutable`, update state variables here.
         // width = newWidth;
         // height = newHeight;
         // No event for this as it's not intended to be called in this immutable version.
    }


    // --- Snapshotting / NFT Functions ---

    function snapshotCellArea(uint256 x1, uint256 y1, uint256 x2, uint256 y2) external payable whenNotPaused nonReentrant returns (uint256 tokenId) {
        require(x1 < width && y1 < height && x2 < width && y2 < height, "Coordinates out of bounds");
        require(x1 <= x2 && y1 <= y2, "Invalid area coordinates");
        _chargeFee(snapshotCost);

        tokenId = nextSnapshotId++;
        _safeMint(msg.sender, tokenId);

        _snapshotAreas[tokenId] = SnapshotArea(x1, y1, x2, y2, uint40(block.timestamp));

        // Note: The cell data at the time of the snapshot is NOT stored on-chain for gas reasons.
        // The off-chain metadata server will need to retrieve the state using getMultipleCellStates
        // by iterating through the stored coordinates (x1..x2, y1..y2) when the tokenURI is requested.

        emit SnapshotMinted(tokenId, msg.sender, x1, y1, x2, y2);
        return tokenId;
    }

    function snapshotFullCanvas() external payable whenNotPaused nonReentrant returns (uint256 tokenId) {
        _chargeFee(snapshotCost);

        tokenId = nextSnapshotId++;
        _safeMint(msg.sender, tokenId);

        // Store special indicator for full canvas snapshot (e.g., 0,0,0,0 or 0,0,width,height)
        // Let's use (0, 0, width-1, height-1) to represent the full valid range.
         _snapshotAreas[tokenId] = SnapshotArea(0, 0, width - 1, height - 1, uint40(block.timestamp));


        emit SnapshotMinted(tokenId, msg.sender, 0, 0, width - 1, height - 1);
        return tokenId;
    }

     function getCellAreaSnapshotData(uint256 tokenId) external view onlyExistingToken(tokenId) returns (SnapshotArea memory) {
         // Revert if it's not an area snapshot (or use a specific check if full canvas is different)
         // Assuming _snapshotAreas[tokenId].x1 == 0 && _snapshotAreas[tokenId].y1 == 0 && _snapshotAreas[tokenId].x2 == width - 1 && _snapshotAreas[tokenId].y2 == height - 1
         // indicates a full canvas snapshot vs area.
         return _snapshotAreas[tokenId];
     }


    // --- ERC721 Standard Functions (Overridden) ---

    function tokenURI(uint256 tokenId) public view override onlyExistingToken(tokenId) returns (string memory) {
        // The off-chain service receiving this URI should use the tokenId to query
        // the contract for snapshot area data (if applicable) and then query
        // the relevant cell states to generate the metadata JSON and image.
        return string(abi.encodePacked(_snapshotNFTBaseURI, "/", Strings.toString(tokenId)));
    }

    // The rest of ERC721 functions (balanceOf, ownerOf, transferFrom, etc.)
    // are provided by the inherited OpenZeppelin ERC721 contract.
    // We list them in the summary for completeness as they are part of the contract's interface.
    // balanceOf, ownerOf, approve, getApproved, setApprovalForAll, isApprovedForAll, transferFrom, safeTransferFrom

    // --- Utility Functions ---

    function getCanvasDimensions() external view returns (uint256 canvasWidth, uint256 canvasHeight) {
        return (width, height);
    }

    function getInteractionCost(uint8 interactionType) external view returns (uint256) {
        require(interactionType <= uint8(InteractionType.Propagate), "Invalid interaction type");
        return interactionCosts[interactionType];
    }

    function getDecayRate() external view returns (uint256) {
        return decayRate;
    }

     function getPropagationCostMultiplier() external view returns (uint256) {
        return propagationCostMultiplier;
    }

    function getSnapshotCost() external view returns (uint256) {
        return snapshotCost;
    }

    function getCanvasTotalCells() external view returns (uint256) {
         return width * height;
    }

    // Fallback function to receive Ether, primarily for interactions
    receive() external payable {}
}
```