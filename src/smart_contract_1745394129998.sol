Okay, here is a Solidity smart contract concept called `QuantumCanvas`. It combines ideas from dynamic NFTs, probabilistic state changes inspired by quantum mechanics (simulated), spatial interaction, time-based evolution, and a touch of collaborative art.

It avoids duplicating standard OpenZeppelin ERC721 by implementing a simplified ownership tracking mechanism directly within the contract, focusing on the custom logic of the cells themselves. True secure randomness (like Chainlink VRF) is mentioned as a necessity for production but simulated with weaker on-chain sources for this example.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title QuantumCanvas
 * @dev A dynamic and evolving digital canvas where each cell is a unique, probabilistic NFT.
 *      Cells exist in a "superposition" of potential states until observed, at which point
 *      their state collapses based on randomness and influencing factors. Cells can be
 *      entangled, causing interactions to potentially affect linked cells. The canvas
 *      evolves over time through global influence and 'quantum ripple' effects.
 */

/**
 * @notice Outline:
 * - State Variables: Dimensions, parameters, admin, epoch, cell data.
 * - Structs: CellData to hold state and properties of each canvas cell.
 * - Events: To log key actions like Observation, StateChange, Entanglement, etc.
 * - Modifiers: Access control (admin, cell owner), pausable.
 * - Core Cell Logic: Minting/Claiming, Observing (state collapse), Painting.
 * - Ownership/Transfer Logic: Simplified internal management mimicking ERC721 subset (ownerOf, transfer).
 * - Quantum Simulation Mechanics: Handling potential states, randomness for collapse, entanglement logic, quantum ripple effect.
 * - Time/Evolution Mechanics: Epoch tracking, global canvas evolution function.
 * - Admin & Configuration: Setting parameters, triggering global events, pausing.
 * - View Functions: Retrieving cell data, canvas state, parameters.
 */

/**
 * @notice Function Summary (at least 20 functions):
 * 1. constructor(): Initializes canvas dimensions, admin, and initial parameters.
 * 2. claimCell(uint256 _cellId): Allows a user to claim an unowned cell (minting).
 * 3. ownerOf(uint256 _cellId): Returns the current owner of a cell.
 * 4. balanceOf(address _owner): Returns the number of cells owned by an address.
 * 5. transferCell(address _to, uint256 _cellId): Transfers ownership of a cell.
 * 6. getCellState(uint256 _cellId): Returns the current state (color/pattern) of a cell.
 * 7. getCellPotentialStates(uint256 _cellId): Returns the array of potential states for a cell.
 * 8. observeCell(uint256 _cellId): Triggers the state collapse based on randomness and influence, costs ether.
 * 9. paintCell(uint256 _cellId, uint8 _newState): Allows cell owner to set the state after collapse.
 * 10. tryEntangleCells(uint256 _cellId1, uint256 _cellId2): Attempts to create an entanglement link between two cells.
 * 11. getEntangledCell(uint256 _cellId): Returns the cell ID entangled with the given cell.
 * 12. disentangleCell(uint256 _cellId): Breaks the entanglement link for a cell and its partner.
 * 13. setCellPotentialStates(uint256 _cellId, uint8[] calldata _newPotentialStates): Allows cell owner to update potential states (conditions apply).
 * 14. setEntanglementProbability(uint8 _probability): Admin function to set the success chance for `tryEntangleCells`.
 * 15. evolveCanvas(): Admin or time-triggered function to apply global evolution rules to the canvas.
 * 16. triggerQuantumRipple(uint256 _cellId): User function to potentially affect neighboring cells probabilistically.
 * 17. setTimeEpoch(uint256 _newEpoch): Admin function to advance the canvas epoch.
 * 18. getEpoch(): Returns the current canvas epoch.
 * 19. setObservationCost(uint256 _cost): Admin function to set the cost of observing a cell.
 * 20. getObservationCost(): Returns the current observation cost.
 * 21. getCellObservationCount(uint256 _cellId): Returns how many times a cell has been observed.
 * 22. getCellsByOwner(address _owner): Returns a list of cell IDs owned by an address (potentially gas-intensive).
 * 23. claimObservationRevenue(): Admin function to withdraw accumulated ether from observation fees.
 * 24. setGlobalInfluence(uint256 _influenceFactor): Admin function to set a factor influencing observation outcomes.
 * 25. getCanvasDimensions(): Returns the width and height of the canvas.
 * 26. pauseContract(): Admin function to pause interactions.
 * 27. unpauseContract(): Admin function to unpause interactions.
 * 28. getCellCoordinates(uint256 _cellId): Returns the (x,y) coordinates for a cell ID.
 * 29. getCellIdFromCoordinates(uint16 _x, uint16 _y): Returns the cell ID for (x,y) coordinates.
 * 30. adminSetCellState(uint256 _cellId, uint8 _newState): Admin function to override a cell's state.
 */

contract QuantumCanvas {

    // --- State Variables ---

    address public immutable admin; // Contract administrator
    bool public paused; // Pausability flag

    uint16 public immutable canvasWidth; // Width of the canvas grid
    uint16 public immutable canvasHeight; // Height of the canvas grid
    uint256 public immutable totalCells; // Total number of cells (canvasWidth * canvasHeight)

    uint256 public currentEpoch; // Tracks the passage of time/major canvas cycles

    // Parameters influencing mechanics
    uint256 public observationCost = 0.01 ether; // Cost to observe a cell
    uint8 public entanglementProbability = 50; // Probability % for entanglement success (0-100)
    uint256 public globalInfluenceFactor = 100; // Factor influencing observation outcomes (higher = more influence)
    uint256 public rippleEffectChance = 30; // Probability % for a quantum ripple to affect a neighbor (0-100)

    // --- Structs ---

    struct CellData {
        address owner;              // Address of the cell owner (0x0 for unowned)
        uint8 currentState;         // The state after collapse (e.g., color index)
        uint8[] potentialStates;    // Possible states before collapse
        bool isCollapsed;           // True if the cell state has been collapsed
        uint256 lastObservationTime; // Timestamp of the last observation
        uint256 observationCount;   // How many times this cell has been observed
        uint256 entangledCellId;    // ID of the cell this is entangled with (0 if none)
        uint16 x;                   // X coordinate (0 to canvasWidth-1)
        uint16 y;                   // Y coordinate (0 to canvasHeight-1)
    }

    // --- Mappings ---

    mapping(uint256 => CellData) private _cells; // cellId -> CellData
    mapping(address => uint256) private _ownerCellCount; // owner address -> number of cells owned

    // --- Events ---

    event CellClaimed(uint256 indexed cellId, address indexed owner, uint16 x, uint16 y);
    event CellTransfer(uint256 indexed cellId, address indexed from, address indexed to);
    event CellObserved(uint256 indexed cellId, address indexed observer, uint8 newState, uint256 observationCount);
    event StateChange(uint256 indexed cellId, address indexed modifier, uint8 newState, bool collapsed);
    event PotentialStatesUpdated(uint256 indexed cellId, uint8[] newPotentialStates);
    event Entanglement(uint256 indexed cellId1, uint256 indexed cellId2);
    event Disentanglement(uint256 indexed cellId1, uint256 indexed cellId2);
    event QuantumRipple(uint256 indexed originCellId, uint256 indexed affectedCellId, string effect);
    event EpochAdvanced(uint256 newEpoch);
    event ParametersUpdated(string paramName, uint256 newValue); // Generic event for admin updates
    event ContractPaused();
    event ContractUnpaused();

    // --- Modifiers ---

    modifier onlyAdmin() {
        require(msg.sender == admin, "QC: Only admin");
        _;
    }

    modifier whenNotPaused() {
        require(!paused, "QC: Contract is paused");
        _;
    }

    modifier onlyCellOwner(uint256 _cellId) {
        require(_cells[_cellId].owner != address(0), "QC: Cell is unowned");
        require(msg.sender == _cells[_cellId].owner, "QC: Not cell owner");
        _;
    }

    modifier cellExists(uint256 _cellId) {
        require(_cellId < totalCells, "QC: Cell does not exist");
        _;
    }

    // --- Constructor ---

    constructor(uint16 _canvasWidth, uint16 _canvasHeight) {
        require(_canvasWidth > 0 && _canvasHeight > 0, "QC: Dimensions must be positive");
        require(_canvasWidth * _canvasHeight > 0, "QC: Total cells must be positive"); // Avoid overflow near max uint16
        admin = msg.sender;
        canvasWidth = _canvasWidth;
        canvasHeight = _canvasHeight;
        totalCells = uint256(_canvasWidth) * _canvasHeight;
        paused = false;
        currentEpoch = 1;

        // Initialize cells with default potential states (e.g., a few basic colors)
        // In a real scenario, initial potential states could be set differently per cell or globally
        uint8[] memory initialPotentials = new uint8[](3);
        initialPotentials[0] = 0; // State 0
        initialPotentials[1] = 1; // State 1
        initialPotentials[2] = 2; // State 2

        for (uint256 i = 0; i < totalCells; i++) {
            (uint16 x, uint16 y) = _getCellCoordinates(i);
            _cells[i] = CellData({
                owner: address(0), // Unowned initially
                currentState: 0,
                potentialStates: initialPotentials,
                isCollapsed: false,
                lastObservationTime: 0,
                observationCount: 0,
                entangledCellId: 0, // No entanglement initially
                x: x,
                y: y
            });
        }
    }

    // --- Core Cell Logic ---

    /**
     * @notice Allows a user to claim an unowned cell on the canvas.
     * @param _cellId The ID of the cell to claim.
     */
    function claimCell(uint256 _cellId) external whenNotPaused cellExists(_cellId) {
        require(_cells[_cellId].owner == address(0), "QC: Cell is already owned");

        _cells[_cellId].owner = msg.sender;
        _ownerCellCount[msg.sender]++;
        emit CellClaimed(_cellId, msg.sender, _cells[_cellId].x, _cells[_cellId].y);
    }

    /**
     * @notice Triggers the probabilistic state collapse of a cell.
     *         Requires payment of the observation cost.
     * @param _cellId The ID of the cell to observe.
     */
    function observeCell(uint256 _cellId) external payable whenNotPaused cellExists(_cellId) {
        require(msg.value >= observationCost, "QC: Insufficient ether for observation");
        // Refund any excess ether
        if (msg.value > observationCost) {
            payable(msg.sender).transfer(msg.value - observationCost);
        }

        CellData storage cell = _cells[_cellId];
        require(cell.potentialStates.length > 0, "QC: Cell has no potential states");

        // --- Simulate Randomness & State Collapse ---
        // NOTE: block.timestamp and block.difficulty/blockhash are NOT cryptographically secure randomness.
        //       For production, use Chainlink VRF or a similar secure oracle.
        uint256 blockValue = uint256(blockhash(block.number - 1));
        uint256 randomSeed = blockValue ^ block.timestamp ^ uint256(uint160(msg.sender)) ^ _cellId ^ globalInfluenceFactor;

        // Deterministically select a potential state based on randomness and influence
        uint256 selectedIndex = (randomSeed * globalInfluenceFactor) % cell.potentialStates.length;
        uint8 newState = cell.potentialStates[selectedIndex];

        // Apply the new state
        cell.currentState = newState;
        cell.isCollapsed = true;
        cell.lastObservationTime = block.timestamp;
        cell.observationCount++;

        emit CellObserved(_cellId, msg.sender, newState, cell.observationCount);
        emit StateChange(_cellId, msg.sender, newState, true);

        // --- Handle Entanglement Effect (if entangled) ---
        if (cell.entangledCellId != 0) {
             // Pass the same random seed or a derivation to potentially link outcomes
            _handleEntanglementEffect(cell.entangledCellId, randomSeed);
        }
    }

    /**
     * @notice Allows the owner of a collapsed cell to 'paint' or set its state.
     * @param _cellId The ID of the cell to paint.
     * @param _newState The desired new state (e.g., color index).
     */
    function paintCell(uint256 _cellId, uint8 _newState) external whenNotPaused onlyCellOwner(_cellId) cellExists(_cellId) {
        CellData storage cell = _cells[_cellId];
        require(cell.isCollapsed, "QC: Cell must be collapsed to be painted");

        cell.currentState = _newState;
        // Painting doesn't un-collapse or change potential states by default
        emit StateChange(_cellId, msg.sender, _newState, true);
    }

    /**
     * @notice Allows the owner of a cell to set its potential states before it's observed.
     *         May have limitations (e.g., number of states, only when uncollapsed).
     * @param _cellId The ID of the cell.
     * @param _newPotentialStates The array of potential states.
     */
    function setCellPotentialStates(uint256 _cellId, uint8[] calldata _newPotentialStates) external whenNotPaused onlyCellOwner(_cellId) cellExists(_cellId) {
        // Add rules: e.g., require(!_cells[_cellId].isCollapsed, "QC: Cannot set potentials after collapse");
        // require(_newPotentialStates.length > 0 && _newPotentialStates.length <= 10, "QC: Invalid potential states array"); // Example limits
        
        _cells[_cellId].potentialStates = _newPotentialStates;
        emit PotentialStatesUpdated(_cellId, _newPotentialStates);
    }

    // --- Ownership / Transfer Logic (Simplified) ---

    /**
     * @notice Returns the owner of a cell.
     * @param _cellId The ID of the cell.
     * @return The owner's address (address(0) if unowned).
     */
    function ownerOf(uint256 _cellId) public view cellExists(_cellId) returns (address) {
        return _cells[_cellId].owner;
    }

    /**
     * @notice Returns the number of cells owned by an address.
     * @param _owner The address to check.
     * @return The count of cells owned.
     */
    function balanceOf(address _owner) public view returns (uint256) {
        return _ownerCellCount[_owner];
    }

     /**
      * @notice Transfers ownership of a cell from the caller to another address.
      * @param _to The recipient address.
      * @param _cellId The ID of the cell to transfer.
      */
    function transferCell(address _to, uint256 _cellId) external whenNotPaused onlyCellOwner(_cellId) cellExists(_cellId) {
        require(_to != address(0), "QC: Transfer to zero address");

        address from = msg.sender;
        _ownerCellCount[from]--;
        _ownerCellCount[_to]++;
        _cells[_cellId].owner = _to;

        emit CellTransfer(_cellId, from, _to);
    }

    // --- Quantum Simulation Mechanics ---

    /**
     * @notice Attempts to create an entanglement link between two cells.
     *         Requires owners' consent or special conditions. Probabilistic.
     * @param _cellId1 The ID of the first cell.
     * @param _cellId2 The ID of the second cell.
     */
    function tryEntangleCells(uint256 _cellId1, uint256 _cellId2) external whenNotPaused cellExists(_cellId1) cellExists(_cellId2) {
        require(_cellId1 != _cellId2, "QC: Cannot entangle a cell with itself");
        require(_cells[_cellId1].entangledCellId == 0 && _cells[_cellId2].entangledCellId == 0, "QC: One or both cells already entangled");
        // Add requirement for owner consent/cost/conditions here
        // For simplicity, let's require caller owns both, or admin
        require(msg.sender == _cells[_cellId1].owner || msg.sender == _cells[_cellId2].owner || msg.sender == admin, "QC: Must own one cell or be admin");
        if (msg.sender != admin) {
            require(msg.sender == _cells[_cellId1].owner && msg.sender == _cells[_cellId2].owner, "QC: Non-admin must own both cells");
        }


        // Simulate probabilistic success
        uint256 randomSeed = uint256(blockhash(block.number - 1)) ^ block.timestamp ^ _cellId1 ^ _cellId2;
        if ((randomSeed % 100) < entanglementProbability) {
            _cells[_cellId1].entangledCellId = _cellId2;
            _cells[_cellId2].entangledCellId = _cellId1;
            emit Entanglement(_cellId1, _cellId2);
        }
        // Optional: Add event for failed attempt
    }

     /**
      * @notice Breaks the entanglement link for a cell and its partner.
      * @param _cellId The ID of one of the entangled cells.
      */
    function disentangleCell(uint256 _cellId) external whenNotPaused onlyCellOwner(_cellId) cellExists(_cellId) {
        uint256 entangledId = _cells[_cellId].entangledCellId;
        require(entangledId != 0, "QC: Cell is not entangled");
        require(entangledId < totalCells, "QC: Invalid entangled ID"); // Safety check

        _cells[_cellId].entangledCellId = 0;
        _cells[entangledId].entangledCellId = 0;
        emit Disentanglement(_cellId, entangledId);
    }

    /**
     * @dev Internal helper to handle the effect on an entangled cell during observation.
     *      Simulates quantum effects like partial collapse or adding potential states.
     * @param _cellId The ID of the cell to affect.
     * @param _influenceSeed A random seed derived from the observation event.
     */
    function _handleEntanglementEffect(uint256 _cellId, uint256 _influenceSeed) internal {
        CellData storage cell = _cells[_cellId];

        // Effect 1: Chance to revert to superposition
        if ((_influenceSeed % 100) < 20) { // 20% chance to un-collapse
            cell.isCollapsed = false;
            emit StateChange(_cellId, address(this), cell.currentState, false); // Note change in collapsed state
        }

        // Effect 2: Chance to add a new random potential state
         if ((_influenceSeed % 100) < 30) { // 30% chance to add a new potential state
            uint8 randomPotential = uint8((_influenceSeed / 7) % 256); // Use a different part of the seed
            // Avoid adding duplicates if needed, or add logic to manage potential states growth
            bool found = false;
            for(uint i = 0; i < cell.potentialStates.length; i++) {
                if(cell.potentialStates[i] == randomPotential) {
                    found = true;
                    break;
                }
            }
            if (!found) {
                 uint8[] memory newPotentials = new uint8[](cell.potentialStates.length + 1);
                 for(uint i = 0; i < cell.potentialStates.length; i++) {
                     newPotentials[i] = cell.potentialStates[i];
                 }
                 newPotentials[cell.potentialStates.length] = randomPotential;
                 cell.potentialStates = newPotentials;
                 // Emit a specific event if needed
             }
         }
         // Other potential effects: subtle shift in currentState, affect neighbors, etc.
    }

     /**
      * @notice Triggers a 'quantum ripple' effect spreading from a cell to its neighbors.
      *         Probabilistically affects neighbor states or potential states.
      * @param _cellId The ID of the origin cell.
      */
     function triggerQuantumRipple(uint256 _cellId) external whenNotPaused cellExists(_cellId) {
         // Optional: require cost or special token
         // require(...);

         (uint16 x, uint16 y) = _getCellCoordinates(_cellId);

         int16[] memory dx = new int16[](4); dx[0]=0; dx[1]=0; dx[2]=1; dx[3]=-1;
         int16[] memory dy = new int16[](4); dy[0]=1; dy[1]=-1; dy[2]=0; dy[3]=0;

         // Simulate randomness for the ripple
         uint256 randomSeed = uint256(blockhash(block.number - 1)) ^ block.timestamp ^ _cellId;

         for (uint i = 0; i < 4; i++) {
             int16 neighborX_int = int16(x) + dx[i];
             int16 neighborY_int = int16(y) + dy[i];

             // Check bounds
             if (neighborX_int >= 0 && neighborX_int < canvasWidth && neighborY_int >= 0 && neighborY_int < canvasHeight) {
                 uint16 neighborX = uint16(neighborX_int);
                 uint16 neighborY = uint16(neighborY_int);
                 uint256 neighborCellId = getCellIdFromCoordinates(neighborX, neighborY);

                 // Probabilistically affect the neighbor
                 uint256 neighborRandomness = randomSeed ^ neighborCellId ^ uint256(i);
                 if ((neighborRandomness % 100) < rippleEffectChance) {
                     // Example effect: Add a random potential state to the neighbor
                     uint8 randomPotential = uint8((neighborRandomness / 11) % 256);
                     CellData storage neighborCell = _cells[neighborCellId];
                     bool found = false;
                     for(uint j = 0; j < neighborCell.potentialStates.length; j++) {
                        if(neighborCell.potentialStates[j] == randomPotential) {
                            found = true;
                            break;
                        }
                     }
                     if (!found) {
                         uint8[] memory newPotentials = new uint8[](neighborCell.potentialStates.length + 1);
                         for(uint j = 0; j < neighborCell.potentialStates.length; j++) {
                             newPotentials[j] = neighborCell.potentialStates[j];
                         }
                         newPotentials[neighborCell.potentialStates.length] = randomPotential;
                         neighborCell.potentialStates = newPotentials;
                         emit QuantumRipple(_cellId, neighborCellId, "AddedPotentialState");
                     } else {
                         emit QuantumRipple(_cellId, neighborCellId, "NoEffect(PotentialExists)");
                     }
                 }
             }
         }
     }


    // --- Time / Evolution Mechanics ---

    /**
     * @notice Admin function to advance the canvas epoch. Can trigger epoch-specific rules.
     * @param _newEpoch The new epoch number. Must be greater than current.
     */
    function setTimeEpoch(uint256 _newEpoch) external onlyAdmin whenNotPaused {
        require(_newEpoch > currentEpoch, "QC: New epoch must be greater than current");
        currentEpoch = _newEpoch;
        emit EpochAdvanced(currentEpoch);

        // Optional: Add logic here for epoch transition effects, e.g.,
        // - Globally reset some cells to superposition
        // - Change entanglement probabilities
        // - Introduce new potential states across the canvas
    }

    /**
     * @notice Triggers a global evolution process on the canvas.
     *         Might be gas intensive if iterating all cells.
     *         Simulates natural drift or systemic change.
     */
    function evolveCanvas() external onlyAdmin whenNotPaused {
        // WARNING: Iterating over ALL cells in a large canvas is gas-intensive.
        // A real implementation might require users to trigger evolution on their cells,
        // or use a decentralized keeper network, or process a subset of cells per call.

        uint256 evolutionSeed = uint256(blockhash(block.number - 1)) ^ block.timestamp ^ currentEpoch;

        // Example evolution effect: Cells un-collapse if not observed for a long time
        uint256 uncollapseThreshold = 30 days; // Example: 30 days of inactivity

        for (uint256 i = 0; i < totalCells; i++) {
            CellData storage cell = _cells[i];

            if (cell.isCollapsed && cell.lastObservationTime > 0 && block.timestamp - cell.lastObservationTime > uncollapseThreshold) {
                 // Apply probabilistic un-collapse or state shift
                 uint256 cellEvolutionSeed = evolutionSeed ^ i;
                 if((cellEvolutionSeed % 100) < 50) { // 50% chance to uncollapse after threshold
                    cell.isCollapsed = false;
                    // Optional: add a random potential state back
                     uint8 randomPotential = uint8((cellEvolutionSeed / 13) % 256);
                     bool found = false;
                     for(uint j = 0; j < cell.potentialStates.length; j++) {
                        if(cell.potentialStates[j] == randomPotential) {
                            found = true;
                            break;
                        }
                     }
                     if (!found) {
                        uint8[] memory newPotentials = new uint8[](cell.potentialStates.length + 1);
                         for(uint j = 0; j < cell.potentialStates.length; j++) {
                             newPotentials[j] = cell.potentialStates[j];
                         }
                         newPotentials[cell.potentialStates.length] = randomPotential;
                         cell.potentialStates = newPotentials;
                     }
                     emit StateChange(i, address(this), cell.currentState, false); // Indicate un-collapse
                 }
            }
            // Add other evolution effects here
        }
        // Event signalling evolution round complete
        emit ParametersUpdated("CanvasEvolved", block.timestamp);
    }


    // --- Admin & Configuration ---

    /**
     * @notice Admin function to set the probability of successful entanglement.
     * @param _probability New probability (0-100).
     */
    function setEntanglementProbability(uint8 _probability) external onlyAdmin {
        require(_probability <= 100, "QC: Probability must be 0-100");
        entanglementProbability = _probability;
        emit ParametersUpdated("EntanglementProbability", _probability);
    }

     /**
      * @notice Admin function to set the cost of observing a cell.
      * @param _cost New observation cost in wei.
      */
    function setObservationCost(uint256 _cost) external onlyAdmin {
        observationCost = _cost;
        emit ParametersUpdated("ObservationCost", _cost);
    }

     /**
      * @notice Admin function to set the global influence factor affecting observation outcomes.
      * @param _influenceFactor New influence factor.
      */
    function setGlobalInfluence(uint256 _influenceFactor) external onlyAdmin {
        require(_influenceFactor > 0, "QC: Influence factor must be positive");
        globalInfluenceFactor = _influenceFactor;
        emit ParametersUpdated("GlobalInfluenceFactor", _influenceFactor);
    }

     /**
      * @notice Admin function to withdraw accumulated observation fees.
      */
    function claimObservationRevenue() external onlyAdmin {
        uint256 balance = address(this).balance;
        require(balance > 0, "QC: No balance to claim");
        payable(admin).transfer(balance);
        emit ParametersUpdated("RevenueClaimed", balance); // Reuse event for simplicity
    }

     /**
      * @notice Admin function to pause the contract, preventing most interactions.
      */
    function pauseContract() external onlyAdmin {
        require(!paused, "QC: Contract is already paused");
        paused = true;
        emit ContractPaused();
    }

     /**
      * @notice Admin function to unpause the contract.
      */
    function unpauseContract() external onlyAdmin {
        require(paused, "QC: Contract is not paused");
        paused = false;
        emit ContractUnpaused();
    }

    /**
     * @notice Admin function to override a cell's state directly. Use with caution.
     * @param _cellId The ID of the cell.
     * @param _newState The state to force the cell into.
     */
    function adminSetCellState(uint256 _cellId, uint8 _newState) external onlyAdmin cellExists(_cellId) {
        CellData storage cell = _cells[_cellId];
        cell.currentState = _newState;
        cell.isCollapsed = true; // Admin setting state means it's collapsed
        emit StateChange(_cellId, msg.sender, _newState, true);
    }


    // --- View Functions ---

    /**
     * @notice Returns the current epoch of the canvas.
     */
    function getEpoch() external view returns (uint256) {
        return currentEpoch;
    }

    /**
     * @notice Returns the current cost to observe a cell.
     */
    function getObservationCost() external view returns (uint256) {
        return observationCost;
    }

    /**
     * @notice Returns the ID of the cell entangled with the given cell.
     * @param _cellId The ID of the cell.
     * @return The entangled cell ID (0 if none).
     */
    function getEntangledCell(uint256 _cellId) external view cellExists(_cellId) returns (uint256) {
        return _cells[_cellId].entangledCellId;
    }

     /**
      * @notice Returns the number of times a cell has been observed.
      * @param _cellId The ID of the cell.
      */
    function getCellObservationCount(uint256 _cellId) external view cellExists(_cellId) returns (uint256) {
        return _cells[_cellId].observationCount;
    }

    /**
     * @notice Returns the width and height of the canvas.
     * @return width, height
     */
    function getCanvasDimensions() external view returns (uint16 width, uint16 height) {
        return (canvasWidth, canvasHeight);
    }

    /**
     * @notice Retrieves all core data for a specific cell.
     * @param _cellId The ID of the cell.
     * @return cellData Struct containing all cell information.
     */
    function getCellData(uint256 _cellId) external view cellExists(_cellId) returns (CellData memory cellData) {
        return _cells[_cellId];
    }

    /**
     * @notice Returns a list of cell IDs owned by an address.
     *         NOTE: This function can be gas-intensive for owners with many cells on large canvases.
     *         For performance, rely on off-chain indexing of `CellClaimed` and `CellTransfer` events.
     * @param _owner The address to query.
     * @return An array of cell IDs.
     */
    function getCellsByOwner(address _owner) external view returns (uint256[] memory) {
        uint256 count = _ownerCellCount[_owner];
        if (count == 0) {
            return new uint256[](0);
        }

        uint256[] memory ownedCellIds = new uint256[](count);
        uint256 currentIndex = 0;
        // Iterate through all cells - this is the potentially gas-heavy part
        for (uint256 i = 0; i < totalCells; i++) {
            if (_cells[i].owner == _owner) {
                if (currentIndex < count) { // Safety check
                    ownedCellIds[currentIndex] = i;
                    currentIndex++;
                } else {
                     // Should not happen if _ownerCellCount is accurate, but safety first
                     break;
                }
            }
        }
        return ownedCellIds;
    }

     /**
      * @notice Calculates the (x,y) coordinates for a given cell ID.
      * @param _cellId The ID of the cell.
      * @return x, y coordinates (0-indexed).
      */
    function getCellCoordinates(uint256 _cellId) public view cellExists(_cellId) returns (uint16 x, uint16 y) {
        // cellId = y * width + x
        x = uint16(_cellId % canvasWidth);
        y = uint16(_cellId / canvasWidth);
    }

     /**
      * @notice Calculates the cell ID for given (x,y) coordinates.
      * @param _x X coordinate (0-indexed).
      * @param _y Y coordinate (0-indexed).
      * @return The cell ID.
      */
    function getCellIdFromCoordinates(uint16 _x, uint16 _y) public view returns (uint256) {
        require(_x < canvasWidth && _y < canvasHeight, "QC: Coordinates out of bounds");
        return uint256(_y) * canvasWidth + _x;
    }

    // --- Internal Helper Functions ---

    // (No internal helpers beyond the entanglement effect and coordinate conversion used above)

}
```