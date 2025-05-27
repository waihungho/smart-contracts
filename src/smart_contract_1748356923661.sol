Okay, let's create a complex, creative, and advanced smart contract. We'll build a "Quantum Canvas" where users can interact with cells on a grid, influencing their "energy" state. The twist is that interactions can trigger emergent behavior based on configurable rules, including probabilistic decay, "entanglement" between cells, and temporal resonance. Users can also snapshot sections of the canvas state as NFTs.

This design uses:
*   Complex state management (2D grid, history, entanglement pairs, phase shifts).
*   Structs and Mappings for data structures.
*   Advanced interaction logic (propagation, decay based on time/blocks, conditional effects).
*   Simulated "quantum" effects (probabilistic decay, entanglement metaphor).
*   NFT integration (snapshotting canvas sections).
*   Access control and pausable state.
*   Events for traceability.

It's important to note that true randomness is not possible directly on-chain without relying on external or semi-external sources (like Chainlink VRF). The "probabilistic" aspect here will be simplified or based on pseudo-randomness derived from block hashes/timestamps, or require an oracle integration (which we won't implement fully for brevity but can mention). The "quantum" aspect is a metaphor for complex, non-deterministic-feeling interactions based on state and timing.

---

## QuantumCanvas Smart Contract

This contract implements a digital canvas (`WIDTH` x `HEIGHT`) composed of cells, each holding an `energy` state. Users can interact with cells by adding energy (`energize`), which can trigger reactions like energy propagation to neighbors. The canvas state evolves over time due to passive energy decay. More advanced features include "entanglement" (linking cells so they influence each other), "temporal resonance" (allowing cells to reference past states), and "phase shifts" (temporarily altering interaction rules in an area). Sections of the canvas can be snapshotted into unique NFTs.

**Key Concepts:**

*   **Cells:** Units on the grid with `energy` (uint16) and `lastInteractionBlock` (uint64).
*   **Energy:** A numerical value representing the state of a cell, influencing its behavior and appearance (off-chain rendering).
*   **Decay:** Energy passively reduces over time (based on block number).
*   **Propagation:** Adding energy to a cell can push energy to its neighbors based on rules and thresholds.
*   **Entanglement:** Two cells linked together; interaction with one can affect the other.
*   **Temporal Resonance:** A cell can store a history of its energy states; interactions can reference this history.
*   **Phase Shift:** A temporary modifier applied to an area that changes interaction rules within that area.
*   **Snapshot:** Minting an ERC721 token representing the state of a rectangular section of the canvas at a specific block.

**Outline:**

1.  **State Variables:** Define canvas dimensions, decay rate, propagation threshold, grid mapping, entanglement mapping, resonance history mapping, phase shift data, NFT token counter and data mapping.
2.  **Structs:** Define structures for CellCoords, Entanglement, TemporalHistory, PhaseShift, SnapshotData.
3.  **Events:** Define events for key actions (Energize, Propagate, Entangle, PhaseShiftApplied, SnapshotMinted, etc.).
4.  **Modifiers:** `onlyOwner`, `whenNotPaused`, `validCoords`.
5.  **Constructor:** Initialize dimensions, owner, default parameters.
6.  **Admin Functions (Owner Only):**
    *   Set parameters (decay rate, thresholds).
    *   Pause/Unpause interactions.
    *   Withdraw collected fees (if any).
    *   Set external rule engine address (placeholder for modularity).
7.  **Core Interaction Functions:**
    *   `energizeCell`: Add energy to a cell, potentially triggering decay calculation and propagation.
    *   `decayCell`: Explicitly apply decay calculation to a cell. (Note: Decay is primarily passive/calculated on interaction).
    *   `propagateFromCell`: Trigger the energy propagation logic from a specific cell.
    *   `observeCell`: Read a cell's state, potentially triggering decay calculation.
8.  **Advanced Interaction Functions:**
    *   `entangleCells`: Link two cells.
    *   `disentangleCells`: Unlink two cells.
    *   `triggerEntanglementEffect`: Trigger the effect on an entangled partner cell.
    *   `createTemporalResonance`: Enable history tracking for a cell.
    *   `applyTemporalInfluence`: Influence a cell's state using its history.
    *   `applyPhaseShift`: Define and activate a phase shift in an area.
    *   `endPhaseShift`: Explicitly end a phase shift.
9.  **NFT Snapshot Functions:**
    *   `snapshotSection`: Record the state of a canvas section and mint an NFT (simplified).
    *   `getTokenState`: Retrieve the recorded state data for a snapshot NFT.
10. **View Functions:**
    *   `getCellState`: Get current energy of a cell (with potential decay calculation).
    *   `getCanvasDimensions`: Get WIDTH and HEIGHT.
    *   `getEntangledPair`: Get the entangled partner of a cell.
    *   `getCellHistory`: Get the history of a resonant cell.
    *   `getPhaseShiftArea`: Get the active phase shift data for a cell.
    *   `getCellLastInteractionBlock`: Get the last interaction block of a cell.
    *   `supportsInterface`: For ERC721 compatibility (minimal).
    *   `ownerOf`: For ERC721 compatibility (minimal).
    *   `balanceOf`: For ERC721 compatibility (minimal).

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol"; // Using the interface for snapshot compatibility

// Note: True randomness requires external oracles like Chainlink VRF.
// Decay is simulated based on block numbers. Propagation is deterministic in this example.

/**
 * @title QuantumCanvas
 * @dev A complex, interactive, and dynamic on-chain generative art canvas.
 * Cells have energy states that decay and propagate based on interactions and rules.
 * Features include cell entanglement, temporal resonance (history), phase shifts,
 * and snapshotting sections as NFTs.
 */
contract QuantumCanvas is Ownable, Pausable, IERC721 { // Inherit IERC721 minimally for snapshot concept

    // --- State Variables ---

    uint16 public constant WIDTH = 64; // Canvas width
    uint16 public constant HEIGHT = 64; // Canvas height

    // Grid state: mapping (x => (y => CellData))
    mapping(uint256 => mapping(uint256 => CellData)) private grid;

    // Parameters controlling canvas dynamics
    uint16 public decayRatePerBlock = 1; // How much energy decays per block (simplified)
    uint16 public propagationThreshold = 100; // Minimum energy to trigger propagation
    uint16 public propagationAmount = 50; // Energy transferred to neighbors during propagation

    // Advanced Features Data Structures
    // Entanglement: mapping (x1 => (y1 => CellCoords_of_Partner))
    mapping(uint256 => mapping(uint256 => CellCoords)) private entangledPairs;

    // Temporal Resonance: mapping (x => (y => array_of_Past_Energies))
    mapping(uint256 => mapping(uint256 => uint16[])) private cellHistory;
    uint8 public constant MAX_HISTORY_LENGTH = 10; // Limit history depth

    // Phase Shifts: array of active shifts
    PhaseShift[] private activePhaseShifts;

    // NFT Snapshot Data (Simplified ERC721 implementation)
    uint256 private _tokenIdCounter;
    mapping(uint256 => address) private _tokenOwners; // tokenId => owner
    mapping(address => uint256) private _ownerTokenCount; // owner => count
    // Store snapshot data: tokenId => encoded_section_state
    mapping(uint256 => bytes) private snapshotData;
    // Keep track of which section a token represents
    mapping(uint256 => SnapshotMetadata) private snapshotMetadata;


    // --- Structs ---

    struct CellData {
        uint16 energy;
        uint64 lastInteractionBlock; // Block number of last relevant interaction (energize, propagate, etc.)
        bool isResonant; // If temporal history is tracked
    }

    struct CellCoords {
        uint256 x;
        uint256 y;
    }

    struct PhaseShift {
        uint256 x1;
        uint256 y1;
        uint256 x2;
        uint256 y2;
        uint8 phaseType; // e.g., 1: Increased decay, 2: Enhanced propagation, 3: Reduced interaction cost, etc.
        uint64 endBlock; // Block number when the shift ends
    }

    struct SnapshotMetadata {
        uint256 x1;
        uint256 y1;
        uint256 x2;
        uint256 y2;
        uint64 snapshotBlock;
    }

    // --- Events ---

    event CellEnergized(uint256 indexed x, uint256 indexed y, uint16 amountAdded, uint16 newEnergy);
    event EnergyDecayed(uint256 indexed x, uint256 indexed y, uint16 oldEnergy, uint16 newEnergy);
    event EnergyPropagated(uint256 indexed fromX, uint256 indexed fromY, uint256 indexed toX, uint256 toY, uint16 amount);
    event CellsEntangled(uint256 indexed x1, uint256 indexed y1, uint256 indexed x2, uint256 indexed y2);
    event CellsDisentangled(uint256 indexed x1, uint256 indexed y1); // Only emit for one side
    event EntanglementEffectTriggered(uint256 indexed sourceX, uint256 indexed sourceY, uint256 indexed partnerX, uint256 partnerY, uint16 effectAmount);
    event TemporalResonanceCreated(uint256 indexed x, uint256 indexed y);
    event TemporalInfluenceApplied(uint256 indexed x, uint256 indexed y, uint16 oldEnergy, uint16 newEnergy, uint256 historyIndex);
    event PhaseShiftApplied(uint256 indexed shiftId, uint256 x1, uint256 y1, uint256 x2, uint256 y2, uint8 phaseType, uint64 endBlock);
    event PhaseShiftEnded(uint256 indexed shiftId);
    event SectionSnapshotted(uint256 indexed tokenId, address indexed owner, uint256 x1, uint256 y1, uint256 x2, uint256 y2, uint64 snapshotBlock);

    // Minimal ERC721 Events
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);


    // --- Modifiers ---

    modifier validCoords(uint256 x, uint256 y) {
        require(x < WIDTH && y < HEIGHT, "Invalid coordinates");
        _;
    }

    modifier validSectionCoords(uint256 x1, uint256 y1, uint256 x2, uint256 y2) {
        require(x1 <= x2 && y1 <= y2, "Invalid section coordinates order");
        require(x2 < WIDTH && y2 < HEIGHT, "Section out of bounds");
        _;
    }

    // --- Constructor ---

    constructor() Ownable(msg.sender) Pausable() {
        // Initial canvas state is zero energy everywhere by default for mappings
        // Owner can set initial parameters
    }

    // --- Internal Helpers ---

    /**
     * @dev Applies passive decay based on blocks passed since last interaction.
     * Only applies decay if the cell has some energy.
     * @param x X coordinate of the cell.
     * @param y Y coordinate of the cell.
     */
    function _applyDecay(uint256 x, uint256 y) internal validCoords(x, y) {
        CellData storage cell = grid[x][y];
        if (cell.energy == 0) {
            // No energy to decay
            cell.lastInteractionBlock = uint64(block.number); // Reset interaction block even if energy is zero
            return;
        }

        uint64 blocksSinceLastInteraction = uint64(block.number) - cell.lastInteractionBlock;

        // Simple linear decay (can be made more complex)
        uint16 decayAmount = uint16(blocksSinceLastInteraction) * decayRatePerBlock;
        uint16 oldEnergy = cell.energy;

        if (cell.energy <= decayAmount) {
            cell.energy = 0;
        } else {
            cell.energy -= decayAmount;
        }

        cell.lastInteractionBlock = uint64(block.number); // Update last interaction block after decay calculation

        if (oldEnergy != cell.energy) {
            emit EnergyDecayed(x, y, oldEnergy, cell.energy);
        }
    }

    /**
     * @dev Checks if a cell is within an active phase shift area and returns the type.
     * @param x X coordinate of the cell.
     * @param y Y coordinate of the cell.
     * @return phaseType The type of the active phase shift (0 if none).
     */
    function _getPhaseShiftType(uint256 x, uint256 y) internal view returns (uint8) {
        // Iterate active phase shifts (consider gas if many shifts)
        for (uint i = 0; i < activePhaseShifts.length; i++) {
            PhaseShift storage shift = activePhaseShifts[i];
            if (uint64(block.number) <= shift.endBlock &&
                x >= shift.x1 && x <= shift.x2 &&
                y >= shift.y1 && y <= shift.y2)
            {
                return shift.phaseType;
            }
        }
        return 0; // No active phase shift
    }

    /**
     * @dev Adds a state to the history of a resonant cell, keeping history length limited.
     * @param x X coordinate of the cell.
     * @param y Y coordinate of the cell.
     */
    function _addStateToHistory(uint256 x, uint256 y) internal {
        if (cellHistory[x][y].length >= MAX_HISTORY_LENGTH) {
            // Remove the oldest state
            for (uint i = 0; i < MAX_HISTORY_LENGTH - 1; i++) {
                cellHistory[x][y][i] = cellHistory[x][y][i+1];
            }
            cellHistory[x][y].pop(); // Remove the last element (which was the second oldest)
        }
        cellHistory[x][y].push(grid[x][y].energy);
    }

    // --- Admin Functions ---

    /**
     * @dev Sets the rate at which energy decays per block.
     * @param _rate New decay rate.
     */
    function setDecayRatePerBlock(uint16 _rate) external onlyOwner {
        decayRatePerBlock = _rate;
    }

    /**
     * @dev Sets the minimum energy required for a cell to trigger propagation.
     * @param _threshold New propagation threshold.
     */
    function setPropagationThreshold(uint16 _threshold) external onlyOwner {
        propagationThreshold = _threshold;
    }

    /**
     * @dev Sets the amount of energy transferred during propagation.
     * @param _amount New propagation amount.
     */
    function setPropagationAmount(uint16 _amount) external onlyOwner {
        propagationAmount = _amount;
    }

    /**
     * @dev Pauses all interactions with the canvas.
     */
    function pauseInteractions() external onlyOwner {
        _pause();
    }

    /**
     * @dev Unpauses interactions with the canvas.
     */
    function unpauseInteractions() external onlyOwner {
        _unpause();
    }

    // Placeholder for withdrawing potential accumulated fees
    function withdrawFees(address payable recipient) external onlyOwner {
        // require(address(this).balance > 0, "No balance to withdraw");
        // (bool success, ) = recipient.call{value: address(this).balance}("");
        // require(success, "Withdraw failed");
        // No fee collection implemented in this version, this is a placeholder
    }

    // Placeholder for setting a separate contract responsible for complex rule calculations
    // This allows upgrading rules without deploying a new Canvas contract
    address public ruleEngineAddress;
    function setRuleEngineAddress(address _ruleEngine) external onlyOwner {
         ruleEngineAddress = _ruleEngine;
         // Add checks that _ruleEngine implements a required interface in a real contract
    }


    // --- Core Interaction Functions ---

    /**
     * @dev Adds energy to a cell. Applies decay, adds energy, updates history, and potentially triggers propagation and entanglement effects.
     * @param x X coordinate of the cell.
     * @param y Y coordinate of the cell.
     * @param amount Amount of energy to add.
     */
    function energizeCell(uint256 x, uint256 y, uint16 amount) external whenNotPaused validCoords(x, y) {
        _applyDecay(x, y); // Apply decay before adding energy

        CellData storage cell = grid[x][y];
        uint16 oldEnergy = cell.energy;

        // Add energy, preventing overflow (max uint16)
        cell.energy = cell.energy + amount > type(uint16).max ? type(uint16).max : cell.energy + amount;

        cell.lastInteractionBlock = uint64(block.number);

        if (cell.isResonant) {
            _addStateToHistory(x, y);
        }

        emit CellEnergized(x, y, amount, cell.energy);

        // Check for propagation threshold (can be influenced by Phase Shift)
        uint8 currentPhase = _getPhaseShiftType(x, y);
        uint16 effectivePropagationThreshold = propagationThreshold;
        // Example: Phase type 2 reduces propagation threshold
        if (currentPhase == 2) {
             effectivePropagationThreshold = effectivePropagationThreshold * 7 / 10; // 30% reduction
        }

        if (cell.energy >= effectivePropagationThreshold) {
            propagateFromCell(x, y); // Trigger propagation
        }

        // Check for entanglement
        CellCoords memory partner = entangledPairs[x][y];
        if (partner.x < WIDTH && partner.y < HEIGHT) { // Check if partner exists
            triggerEntanglementEffect(x, y);
        }
    }

    /**
     * @dev Explicitly triggers the decay calculation for a cell.
     * Note: Decay is calculated implicitly in `energizeCell` and `observeCell`.
     * This function exists for explicit state updates or scenarios where no other interaction occurs.
     * @param x X coordinate of the cell.
     * @param y Y coordinate of the cell.
     */
    function decayCell(uint256 x, uint256 y) external whenNotPaused validCoords(x, y) {
        _applyDecay(x, y);
    }


    /**
     * @dev Triggers energy propagation from a cell to its direct neighbors.
     * Requires the cell's energy to be above the propagation threshold.
     * Propagation amount can be influenced by phase shifts.
     * @param x X coordinate of the cell.
     * @param y Y coordinate of the cell.
     */
    function propagateFromCell(uint256 x, uint256 y) public whenNotPaused validCoords(x, y) {
        // Public visibility allows external triggering, but also used internally by energizeCell
        _applyDecay(x, y); // Apply decay before propagation check

        CellData storage cell = grid[x][y];

        uint8 currentPhase = _getPhaseShiftType(x, y);
        uint16 effectivePropagationThreshold = propagationThreshold;
         if (currentPhase == 2) {
             effectivePropagationThreshold = effectivePropagationThreshold * 7 / 10;
        }

        if (cell.energy < effectivePropagationThreshold) {
            return; // Not enough energy to propagate
        }

        // Determine effective propagation amount (can be influenced by Phase Shift)
        uint16 effectivePropagationAmount = propagationAmount;
         if (currentPhase == 2) {
             effectivePropagationAmount = effectivePropagationAmount * 13 / 10; // 30% increase
         }

        // List of neighbor offsets: Top, Bottom, Left, Right
        int256[] memory dx = new int256[](4);
        int256[] memory dy = new int256[](4);
        dx[0] = 0; dy[0] = -1; // Top
        dx[1] = 0; dy[1] = 1;  // Bottom
        dx[2] = -1; dy[2] = 0; // Left
        dx[3] = 1; dy[3] = 0;  // Right

        for (uint i = 0; i < dx.length; i++) {
            int256 neighborX = int256(x) + dx[i];
            int256 neighborY = int256(y) + dy[i];

            // Check bounds for neighbor
            if (neighborX >= 0 && neighborX < WIDTH && neighborY >= 0 && neighborY < HEIGHT) {
                 uint256 nx = uint256(neighborX);
                 uint256 ny = uint256(neighborY);

                 _applyDecay(nx, ny); // Apply decay to neighbor before adding energy

                 CellData storage neighborCell = grid[nx][ny];
                 neighborCell.energy = neighborCell.energy + effectivePropagationAmount > type(uint16).max ? type(uint16).max : neighborCell.energy + effectivePropagationAmount;
                 neighborCell.lastInteractionBlock = uint64(block.number);

                 if (neighborCell.isResonant) {
                     _addStateToHistory(nx, ny);
                 }

                 emit EnergyPropagated(x, y, nx, ny, effectivePropagationAmount);
            }
        }

        // Optional: Reduce energy of the source cell after propagation? Add complex rules here.
        // cell.energy = cell.energy > effectivePropagationAmount * dx.length ? cell.energy - effectivePropagationAmount * dx.length : 0;
    }

    /**
     * @dev Reads the current energy state of a cell. Automatically applies decay calculation before returning.
     * @param x X coordinate of the cell.
     * @param y Y coordinate of the cell.
     * @return The current energy of the cell after decay calculation.
     */
    function observeCell(uint256 x, uint256 y) public validCoords(x, y) view returns (uint16) {
        // Note: View functions cannot change state, so decay is calculated based on current block
        // but the state variable `lastInteractionBlock` cannot be updated.
        // A transaction is needed to *actually* apply decay and update the block timestamp.
        CellData storage cell = grid[x][y];
        uint64 blocksSinceLastInteraction = uint64(block.number) - cell.lastInteractionBlock;
        uint16 decayAmount = uint16(blocksSinceLastInteraction) * decayRatePerBlock;

        if (cell.energy <= decayAmount) {
            return 0;
        } else {
            return cell.energy - decayAmount;
        }
        // In a state-changing function like energize, _applyDecay would update cell.lastInteractionBlock
    }


    // --- Advanced Interaction Functions ---

    /**
     * @dev Entangles two cells, linking their states for future interactions.
     * Requires both cells to not be already entangled.
     * @param x1 X coordinate of the first cell.
     * @param y1 Y coordinate of the first cell.
     * @param x2 X coordinate of the second cell.
     * @param y2 Y coordinate of the second cell.
     */
    function entangleCells(uint256 x1, uint256 y1, uint256 x2, uint256 y2) external whenNotPaused validCoords(x1, y1) validCoords(x2, y2) {
        require(!(x1 == x2 && y1 == y2), "Cannot entangle a cell with itself");
        require(entangledPairs[x1][y1].x >= WIDTH, "Cell 1 already entangled"); // Check if default CellCoords (0,0) or beyond bounds
        require(entangledPairs[x2][y2].x >= WIDTH, "Cell 2 already entangled");

        entangledPairs[x1][y1] = CellCoords({x: x2, y: y2});
        entangledPairs[x2][y2] = CellCoords({x: x1, y: y1});

        emit CellsEntangled(x1, y1, x2, y2);
    }

    /**
     * @dev Disentangles two linked cells. Only need to call for one cell in the pair.
     * @param x X coordinate of one cell in the pair.
     * @param y Y coordinate of one cell in the pair.
     */
    function disentangleCells(uint256 x, uint256 y) external whenNotPaused validCoords(x, y) {
        CellCoords memory partner = entangledPairs[x][y];
        require(partner.x < WIDTH && partner.y < HEIGHT, "Cell is not entangled");

        // Clear both ends of the entanglement
        delete entangledPairs[x][y];
        delete entangledPairs[partner.x][partner.y];

        emit CellsDisentangled(x, y);
    }

    /**
     * @dev Triggers a correlated energy effect on a cell's entangled partner.
     * Can be called explicitly or triggered by other interactions (like energize).
     * The effect amount can be proportional to the source cell's energy or a fixed value.
     * @param sourceX X coordinate of the source cell.
     * @param sourceY Y coordinate of the source cell.
     */
    function triggerEntanglementEffect(uint256 sourceX, uint256 sourceY) public whenNotPaused validCoords(sourceX, sourceY) {
         // Public allows external triggering and internal use
        CellCoords memory partner = entangledPairs[sourceX][sourceY];
        require(partner.x < WIDTH && partner.y < HEIGHT, "Source cell is not entangled");

        _applyDecay(sourceX, sourceY); // Apply decay to source before calculating effect
        uint16 sourceEnergy = grid[sourceX][sourceY].energy;

        // Define entanglement effect (example: transfer 20% of source energy)
        uint16 effectAmount = sourceEnergy * 20 / 100;

        if (effectAmount > 0) {
             // Apply effect to partner - simulate adding energy
            _applyDecay(partner.x, partner.y); // Apply decay to partner

            CellData storage partnerCell = grid[partner.x][partner.y];
            partnerCell.energy = partnerCell.energy + effectAmount > type(uint16).max ? type(uint16).max : partnerCell.energy + effectAmount;
            partnerCell.lastInteractionBlock = uint64(block.number);

            if (partnerCell.isResonant) {
                _addStateToHistory(partner.x, partner.y);
            }

            emit EntanglementEffectTriggered(sourceX, sourceY, partner.x, partner.y, effectAmount);
        }
    }

    /**
     * @dev Enables temporal resonance for a cell, starting its history tracking.
     * @param x X coordinate of the cell.
     * @param y Y coordinate of the cell.
     */
    function createTemporalResonance(uint256 x, uint256 y) external whenNotPaused validCoords(x, y) {
        CellData storage cell = grid[x][y];
        require(!cell.isResonant, "Cell is already resonant");
        cell.isResonant = true;
        // Add current state to history upon creation
        _addStateToHistory(x, y);
        emit TemporalResonanceCreated(x, y);
    }

     /**
      * @dev Influences a cell's current state by pulling from its history.
      * Example: Resets the cell's energy to a past state.
      * @param x X coordinate of the cell.
      * @param y Y coordinate of the cell.
      * @param historyIndex Index in the history array (0 is oldest, length-1 is most recent).
      */
    function applyTemporalInfluence(uint256 x, uint256 y, uint256 historyIndex) external whenNotPaused validCoords(x, y) {
        CellData storage cell = grid[x][y];
        require(cell.isResonant, "Cell is not resonant");
        require(historyIndex < cellHistory[x][y].length, "Invalid history index");

        uint16 oldEnergy = cell.energy;
        uint16 historyEnergy = cellHistory[x][y][historyIndex];

        cell.energy = historyEnergy; // Set current energy to a past state
        cell.lastInteractionBlock = uint64(block.number); // Reset interaction block

        // Optionally add the new (history-influenced) state back to history?
        // _addStateToHistory(x,y);

        emit TemporalInfluenceApplied(x, y, oldEnergy, cell.energy, historyIndex);
    }

    /**
     * @dev Applies a phase shift to a rectangular area of the canvas for a limited time.
     * Phase shifts alter rules like decay or propagation within their area.
     * @param x1 X coordinate of the top-left corner.
     * @param y1 Y coordinate of the top-left corner.
     * @param x2 X coordinate of the bottom-right corner.
     * @param y2 Y coordinate of the bottom-right corner.
     * @param phaseType Type of phase shift (defined by contract logic).
     * @param durationBlocks Duration of the shift in block numbers.
     */
    function applyPhaseShift(uint256 x1, uint256 y1, uint256 x2, uint256 y2, uint8 phaseType, uint64 durationBlocks) external whenNotPaused validSectionCoords(x1, y1, x2, y2) {
        require(durationBlocks > 0, "Duration must be positive");
        // Could add checks for valid phaseTypes

        // Clean up expired shifts first (optional, can be done off-chain or in a maintenance function)
        // For simplicity here, new shifts are just added. _getPhaseShiftType handles expiry.

        PhaseShift memory newShift = PhaseShift({
            x1: x1,
            y1: y1,
            x2: x2,
            y2: y2,
            phaseType: phaseType,
            endBlock: uint64(block.number) + durationBlocks
        });

        activePhaseShifts.push(newShift);

        // Emit event with the index (shiftId)
        emit PhaseShiftApplied(activePhaseShifts.length - 1, x1, y1, x2, y2, phaseType, newShift.endBlock);
    }

     /**
      * @dev Explicitly ends a phase shift before its duration expires.
      * This might require iterating and removing from the array, which can be gas-intensive.
      * A more gas-efficient approach for removal might use a mapping instead of an array,
      * or mark as inactive instead of removing. Using a simple removal here for clarity.
      * @param shiftId The index of the phase shift in the activePhaseShifts array.
      */
    function endPhaseShift(uint256 shiftId) external onlyOwner { // Only owner can prematurely end? Or creator of shift?
        require(shiftId < activePhaseShifts.length, "Invalid phase shift ID");
        require(uint64(block.number) <= activePhaseShifts[shiftId].endBlock, "Phase shift already expired");

        activePhaseShifts[shiftId].endBlock = uint64(block.number); // Set end block to now

        // Optional: Remove from array (gas cost increases with array size)
        // Swap with last element and pop
        if (shiftId != activePhaseShifts.length - 1) {
            activePhaseShifts[shiftId] = activePhaseShifts[activePhaseShifts.length - 1];
        }
        activePhaseShifts.pop();

        emit PhaseShiftEnded(shiftId);
    }


    // --- NFT Snapshot Functions (Simplified ERC721) ---

    /**
     * @dev Snapshots the current state of a rectangular section of the canvas and mints it as a simple NFT.
     * Stores the cell data for the section on-chain associated with the token ID.
     * @param x1 X coordinate of the top-left corner.
     * @param y1 Y coordinate of the top-left corner.
     * @param x2 X coordinate of the bottom-right corner.
     * @param y2 Y coordinate of the bottom-right corner.
     * @return tokenId The ID of the newly minted snapshot token.
     */
    function snapshotSection(uint256 x1, uint256 y1, uint256 x2, uint256 y2) external whenNotPaused validSectionCoords(x1, y1, x2, y2) returns (uint256) {
        // This is a simplified snapshot. A real implementation would need to consider gas costs
        // of reading/writing potentially large sections, and proper ERC721 metadata.

        uint256 currentTokenId = _tokenIdCounter++;
        address tokenOwner = msg.sender;

        _tokenOwners[currentTokenId] = tokenOwner;
        _ownerTokenCount[tokenOwner]++;

        // Store the section data ON-CHAIN (can be gas intensive for large sections!)
        bytes memory encodedState = _encodeSectionState(x1, y1, x2, y2);
        snapshotData[currentTokenId] = encodedState;

        // Store metadata about the snapshot
        snapshotMetadata[currentTokenId] = SnapshotMetadata({
            x1: x1,
            y1: y1,
            x2: x2,
            y2: y2,
            snapshotBlock: uint64(block.number) // Record block of snapshot
        });


        // Emit ERC721 Transfer event (minting)
        emit Transfer(address(0), tokenOwner, currentTokenId);
        emit SectionSnapshotted(currentTokenId, tokenOwner, x1, y1, x2, y2, uint64(block.number));

        return currentTokenId;
    }

    /**
     * @dev Internal helper to encode the state of a canvas section into bytes.
     * For simplicity, just concatenates the energy values.
     * @param x1 X coordinate of the top-left corner.
     * @param y1 Y coordinate of the top-left corner.
     * @param x2 X coordinate of the bottom-right corner.
     * @param y2 Y coordinate of the bottom-right corner.
     * @return bytes Encoded state data.
     */
    function _encodeSectionState(uint256 x1, uint256 y1, uint256 x2, uint256 y2) internal view returns (bytes memory) {
        uint256 sectionWidth = x2 - x1 + 1;
        uint256 sectionHeight = y2 - y1 + 1;
        uint256 dataLength = sectionWidth * sectionHeight * 2; // 2 bytes per uint16 energy

        bytes memory data = new bytes(dataLength);
        uint256 offset = 0;

        for (uint256 y = y1; y <= y2; y++) {
            for (uint256 x = x1; x <= x2; x++) {
                // Get the energy state (applying decay for the snapshot!)
                // Use observeCell logic here to get the decayed state at snapshot time
                uint16 currentEnergy;
                 CellData storage cell = grid[x][y];
                uint64 blocksSinceLastInteraction = uint64(block.number) - cell.lastInteractionBlock;
                uint16 decayAmount = uint16(blocksSinceLastInteraction) * decayRatePerBlock;
                 if (cell.energy <= decayAmount) {
                    currentEnergy = 0;
                } else {
                    currentEnergy = cell.energy - decayAmount;
                }

                // Encode uint16 (2 bytes) into bytes
                data[offset] = bytes1(uint8(currentEnergy >> 8)); // High byte
                data[offset + 1] = bytes1(uint8(currentEnergy));   // Low byte
                offset += 2;
            }
        }
        return data;
    }

    /**
     * @dev Retrieves the encoded state data stored with a snapshot NFT.
     * Off-chain applications can decode this to render the snapshot.
     * @param tokenId The ID of the snapshot token.
     * @return bytes The encoded state data for the section.
     */
    function getTokenState(uint256 tokenId) external view returns (bytes memory) {
        require(_tokenOwners[tokenId] != address(0), "Invalid token ID"); // Check if token exists
        return snapshotData[tokenId];
    }

     /**
      * @dev Retrieves metadata about a snapshot NFT's section and snapshot block.
      * @param tokenId The ID of the snapshot token.
      * @return metadata SnapshotMetadata struct.
      */
    function getSnapshotMetadata(uint256 tokenId) external view returns (SnapshotMetadata memory) {
         require(_tokenOwners[tokenId] != address(0), "Invalid token ID");
         return snapshotMetadata[tokenId];
    }


    // --- View Functions ---

    /**
     * @dev Gets the current energy state of a cell, applying decay calculation on read.
     * @param x X coordinate of the cell.
     * @param y Y coordinate of the cell.
     * @return The current energy of the cell.
     */
    function getCellState(uint256 x, uint256 y) public view validCoords(x, y) returns (uint16) {
         // This calls the internal _applyDecay logic but only returns the *calculated* value,
         // it doesn't change the state in a view function.
        return observeCell(x, y);
    }

    /**
     * @dev Gets the dimensions of the canvas.
     * @return width The canvas width.
     * @return height The canvas height.
     */
    function getCanvasDimensions() external pure returns (uint16 width, uint16 height) {
        return (WIDTH, HEIGHT);
    }

    /**
     * @dev Gets the entangled partner of a cell.
     * @param x X coordinate of the cell.
     * @param y Y coordinate of the cell.
     * @return partnerX X coordinate of the partner (WIDTH if not entangled).
     * @return partnerY Y coordinate of the partner (HEIGHT if not entangled).
     */
    function getEntangledPair(uint256 x, uint256 y) external view validCoords(x, y) returns (uint256 partnerX, uint256 partnerY) {
        CellCoords memory partner = entangledPairs[x][y];
        // Return WIDTH, HEIGHT if not entangled (default struct values)
        return (partner.x, partner.y);
    }

    /**
     * @dev Gets the history of energy states for a resonant cell.
     * @param x X coordinate of the cell.
     * @param y Y coordinate of the cell.
     * @return history An array of past energy states (oldest to newest).
     */
    function getCellHistory(uint256 x, uint256 y) external view validCoords(x, y) returns (uint16[] memory history) {
        return cellHistory[x][y];
    }

    /**
     * @dev Gets information about the active phase shift affecting a cell.
     * @param x X coordinate of the cell.
     * @param y Y coordinate of the cell.
     * @return phaseType Type of the shift (0 if none).
     * @return endBlock Block number when the shift ends (0 if none).
     */
    function getPhaseShiftArea(uint256 x, uint256 y) external view validCoords(x, y) returns (uint8 phaseType, uint64 endBlock) {
        // Iterate active phase shifts (consider gas if many shifts)
        for (uint i = 0; i < activePhaseShifts.length; i++) {
            PhaseShift storage shift = activePhaseShifts[i];
            if (uint64(block.number) <= shift.endBlock &&
                x >= shift.x1 && x <= shift.x2 &&
                y >= shift.y1 && y <= shift.y2)
            {
                return (shift.phaseType, shift.endBlock);
            }
        }
        return (0, 0); // No active phase shift
    }

    /**
     * @dev Gets the block number of the last interaction for a cell.
     * Useful for off-chain clients to estimate current energy before calling a state-changing function.
     * @param x X coordinate of the cell.
     * @param y Y coordinate of the cell.
     * @return The block number of the last interaction.
     */
    function getCellLastInteractionBlock(uint256 x, uint256 y) external view validCoords(x, y) returns (uint64) {
        return grid[x][y].lastInteractionBlock;
    }


    // --- Minimal ERC721 Interface Implementations (for Snapshot) ---
    // Note: This is NOT a full ERC721 implementation. It only includes
    // the functions required by the IERC721 interface for basic compatibility
    // and allows tools/explorers to see token ownership. Transfer, approval
    // logic etc. are missing for brevity.

    function supportsInterface(bytes4 interfaceId) external view override returns (bool) {
        // Simplified support check: ERC721, ERC165
        return interfaceId == type(IERC721).interfaceId || interfaceId == 0x01ffc9a7; // ERC165
        // A full implementation would check other standard interfaces like Metadata, Enumerable
    }

    function balanceOf(address owner) external view override returns (uint256) {
        require(owner != address(0), "ERC721: address zero is not a valid owner");
        return _ownerTokenCount[owner];
    }

    function ownerOf(uint256 tokenId) external view override returns (address) {
        address owner = _tokenOwners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }

    // These functions are required by IERC721 but not implemented fully for this example's complexity focus.
    // A real NFT contract would require proper implementation of transferFrom, approve, setApprovalForAll, etc.
    function transferFrom(address from, address to, uint256 tokenId) external override {
        revert("Transfer not implemented in this example");
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) external override {
         revert("SafeTransfer not implemented in this example");
    }

     function safeTransferFrom(address from, address to, uint256 tokenId) external override {
         revert("SafeTransfer not implemented in this example");
    }

    function approve(address to, uint256 tokenId) external override {
         revert("Approve not implemented in this example");
    }

    function setApprovalForAll(address operator, bool approved) external override {
        revert("SetApprovalForAll not implemented in this example");
    }

    function getApproved(uint256 tokenId) external view override returns (address) {
        revert("GetApproved not implemented in this example");
    }

    function isApprovedForAll(address owner, address operator) external view override returns (bool) {
         revert("IsApprovedForAll not implemented in this example");
    }
}
```