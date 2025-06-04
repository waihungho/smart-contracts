Okay, here is a smart contract written in Solidity using advanced concepts like complex state management, time-based dynamics, conditional logic based on evolving state, and functions for manipulating these states in creative ways (like splitting and merging vaults).

This contract, named `QuantumFluxVault`, manages deposits (`Cells`) that can only be withdrawn when their internal "Flux Level" decays below a certain threshold, influenced by time and interaction. Users can also trigger a "Flux Pulse" to temporarily increase a cell's flux, resetting the decay timer.

**Outline:**

1.  **License and Pragma**
2.  **Imports:** Ownable, Pausable, ReentrancyGuard
3.  **Error Definitions**
4.  **Events**
5.  **Struct Definitions:** `Cell`
6.  **State Variables:**
    *   Owner, Paused state
    *   Cell counter
    *   Mappings for Cells, user cell lists, decay parameters by cell type
    *   Global decay rate, thresholds, pulse costs/effects
    *   Factor for converting deposit amount to initial flux
7.  **Modifiers:** `onlyOwner`, `whenNotPaused`, `whenPaused`, `nonReentrant`, `validCellId`, `isCellOwner`
8.  **Helper Functions (Internal/Pure):**
    *   `_calculateCurrentFlux`: Core logic for time-based decay calculation.
    *   `_updateCellFluxState`: Updates cell's stored flux and timestamp based on current state.
    *   `_addCellToUser`: Helper for managing user cell lists.
    *   `_removeCellFromUser`: Helper for managing user cell lists (logical removal).
    *   `_deactivateCell`: Sets cell state to inactive.
9.  **Core Logic Functions (External/Public):**
    *   `constructor`: Initializes owner and parameters.
    *   `pauseContract`, `unpauseContract`: Emergency stop.
    *   `setGlobalDecayRate`, `setDecayThreshold`, `setPulseParameters`, `setFluxDepositFactor`, `setCellTypeDecayFactor`: Owner configures parameters.
    *   `createCell`: Deposit ETH and create a new cell with initial flux.
    *   `depositToCell`: Add more ETH to an existing cell, impacting flux.
    *   `triggerFluxPulse`: Pay a fee to increase a cell's flux and reset decay timer.
    *   `attemptDecayHarvest`: Attempt to withdraw ETH if cell flux is below threshold.
    *   `splitCell`: Split a cell into two, distributing amount and flux.
    *   `mergeCells`: Merge two cells into one, combining amounts and fluxes.
    *   `transferCellOwnership`: Transfer cell ownership to another address.
    *   `emergencyOwnerWithdraw`: Owner can withdraw all funds when paused.
10. **View Functions (External/Public):**
    *   `getCurrentFluxLevel`: Get the current calculated flux for a cell (read-only).
    *   `getCellDetails`: Get details of a specific cell.
    *   `getUserCellIds`: Get all cell IDs belonging to a user.
    *   `viewAvailableForHarvest`: List cells a user can harvest from.
    *   `simulateFutureFlux`: Calculate flux at a specific future time.
    *   `getContractBalance`: Get contract's ETH balance.
    *   `getGlobalParameters`: Get global configuration parameters.
    *   `getCellTypeDecayFactor`: Get decay factor for a cell type.
11. **Batch Function (External):**
    *   `batchAttemptDecayHarvest`: Attempt harvest on multiple cells.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol"; // For flux calculations if needed, uint256 is large
import "@openzeppelin/contracts/utils/Address.sol"; // For sending ETH

// --- QuantumFluxVault Contract ---
//
// This contract introduces a novel mechanism for time-locked or conditionally
// accessible Ether deposits ("Cells"). Each Cell has a "Flux Level" that decays
// over time. Ether can only be withdrawn ("Harvested") when the Flux Level
// falls below a configurable threshold. Users can interact with their Cells
// by depositing more (increasing flux), triggering a "Flux Pulse" (significantly
// increasing flux), splitting cells, merging cells, or transferring ownership.
//
// Concepts Used:
// - Complex State Management: Storing and updating dynamic state per Cell (amount, flux, time).
// - Time-Based Dynamics: Flux decay based on elapsed time since last interaction.
// - Conditional Release: Funds unlock based on the calculated Flux Level relative to a threshold.
// - State Manipulation Functions: Split, Merge, Pulse, Transfer Ownership.
// - Configurable Parameters: Owner sets global decay rates, thresholds, pulse effects, and type-specific decay factors.
// - Emergency Controls: Pausing the contract.
// - Batch Operations: Harvesting multiple cells at once.
//
// This contract is designed to be an example of creative tokenomics or state-based
// game mechanics rather than a standard financial instrument. The "Flux" is an
// abstract concept governing access.
//
// Outline:
// 1. License and Pragma
// 2. Imports
// 3. Error Definitions
// 4. Events
// 5. Struct Definitions (Cell)
// 6. State Variables
// 7. Modifiers
// 8. Internal/Pure Helper Functions (_calculateCurrentFlux, _updateCellFluxState, etc.)
// 9. External Core Logic Functions (constructor, pause, set params, create, deposit, pulse, harvest, split, merge, transfer, emergency withdraw)
// 10. External View Functions (get flux, get details, get user cells, view harvestable, simulate flux, get balance, get parameters)
// 11. External Batch Function (batch harvest)
//
// Function Summary:
// --- Admin/Setup Functions ---
// 1.  constructor(): Initializes contract with owner and base parameters.
// 2.  pauseContract(): Pauses the contract (emergency).
// 3.  unpauseContract(): Unpauses the contract.
// 4.  setGlobalDecayRate(uint256 _newRatePerSecond): Sets the base rate at which flux decays per second.
// 5.  setDecayThreshold(uint256 _newThreshold): Sets the maximum flux level allowed for harvesting.
// 6.  setPulseParameters(uint256 _pulseCost, uint256 _pulseIncrease): Sets the cost and flux increase for a Flux Pulse.
// 7.  setFluxDepositFactor(uint256 _newFactor): Sets the factor converting deposit amount to initial flux.
// 8.  setCellTypeDecayFactor(uint8 _cellType, uint256 _factorMultiplier): Sets a decay rate multiplier for a specific cell type.
// 9.  emergencyOwnerWithdraw(): Allows owner to withdraw all ETH when contract is paused.
// --- User Interaction Functions ---
// 10. createCell(uint8 _cellType): Creates a new cell with deposited Ether and initial flux based on amount and type. Payable.
// 11. depositToCell(uint256 _cellId): Adds Ether to an existing cell, increasing its amount and flux. Payable.
// 12. triggerFluxPulse(uint256 _cellId): Pays a fee to instantly increase a cell's flux and reset its decay timer. Payable.
// 13. attemptDecayHarvest(uint256 _cellId): Attempts to withdraw Ether from a cell if its flux is below the threshold.
// 14. splitCell(uint256 _cellId, uint256 _amountForNewCell): Splits a cell's contents and flux into two distinct cells.
// 15. mergeCells(uint256 _cellId1, uint256 _cellId2): Merges two cells into one, combining amounts and fluxes.
// 16. transferCellOwnership(uint256 _cellId, address _newOwner): Transfers ownership of a cell to another address.
// 17. batchAttemptDecayHarvest(uint256[] calldata _cellIds): Attempts to harvest from multiple cells in one transaction.
// --- View/Read Functions ---
// 18. getCurrentFluxLevel(uint256 _cellId): Returns the currently calculated flux level for a cell.
// 19. getCellDetails(uint256 _cellId): Returns the full details of a cell.
// 20. getUserCellIds(address _user): Returns a list of cell IDs owned by a user.
// 21. viewAvailableForHarvest(address _user): Returns a list of cell IDs owned by a user that are currently harvestable.
// 22. simulateFutureFlux(uint256 _cellId, uint256 _futureTimestamp): Simulates and returns the flux level at a specific future timestamp.
// 23. getContractBalance(): Returns the total ETH held by the contract.
// 24. getGlobalParameters(): Returns global configuration parameters.
// 25. getCellTypeDecayFactor(uint8 _cellType): Returns the decay factor multiplier for a specific cell type.
//
// Note: Flux calculation uses simple linear decay for EVM compatibility.
// Flux decreases by (baseRate * typeMultiplier * timeElapsed) per second.
// Initial flux is depositAmount / fluxDepositFactor.


contract QuantumFluxVault is Ownable, Pausable, ReentrancyGuard {
    using SafeMath for uint256;
    using Address for address;

    // --- Error Definitions ---
    error Vault__InvalidCellId();
    error Vault__CellNotActive();
    error Vault__NotCellOwner();
    error Vault__HarvestNotReady(uint256 currentFlux, uint256 decayThreshold);
    error Vault__SplitAmountTooLarge();
    error Vault__MergeFailedNotSameOwner();
    error Vault__MergeFailedCannotMergeSelf();
    error Vault__InsufficientPulsePayment(uint256 requiredCost);
    error Vault__ZeroAddressNotAllowed();
    error Vault__InvalidDecayFactor();
    error Vault__NoEthDeposited();
    error Vault__BatchHarvestFailed(uint256 cellId);


    // --- Events ---
    event CellCreated(uint256 indexed cellId, address indexed depositor, uint256 amount, uint256 initialFlux, uint8 cellType);
    event DepositAdded(uint256 indexed cellId, uint256 addedAmount, uint256 newFlux);
    event FluxPulsed(uint256 indexed cellId, address indexed púlser, uint256 pulseCost, uint256 newFlux);
    event HarvestAttempted(uint256 indexed cellId, address indexed receiver, uint256 currentFlux, uint256 decayThreshold, bool success);
    event CellHarvested(uint256 indexed cellId, address indexed receiver, uint256 amount);
    event CellSplit(uint256 indexed originalCellId, uint256 indexed newCellId, uint256 amountSplit, uint256 originalRemainingAmount);
    event CellsMerged(uint256 indexed cellId1, uint256 indexed cellId2, uint256 mergedCellId, uint256 totalAmount);
    event CellOwnershipTransferred(uint256 indexed cellId, address indexed oldOwner, address indexed newOwner);
    event ParametersUpdated();
    event EmergencyWithdrawal(uint256 amount);

    // --- Struct Definitions ---
    struct Cell {
        uint256 amount;              // Amount of ETH stored in the cell (in wei)
        address depositor;           // Original depositor and current owner
        uint256 fluxAtLastUpdate;    // The calculated flux level at the time of the last interaction
        uint256 lastFluxUpdateTime;  // Timestamp of the last interaction/flux update
        uint8 cellType;              // Identifier for different decay rate profiles
        bool isActive;               // Is this cell currently active and holding funds?
    }

    // --- State Variables ---
    uint256 private _cellCounter; // Counter for unique cell IDs
    mapping(uint256 => Cell) public cells; // Mapping of cell ID to Cell struct
    mapping(address => uint256[]) private _userCells; // Mapping of user address to list of their cell IDs (simplistic list, removal is logical)

    // Global parameters affecting flux dynamics
    uint256 public globalDecayRatePerSecond = 1; // Base rate of flux decay per second (e.g., 1 unit per sec)
    uint256 public decayThreshold = 100;       // Flux must be <= this to harvest
    uint256 public pulseCost = 0.01 ether;     // Cost to trigger a flux pulse
    uint256 public pulseIncreaseAmount = 500;  // Amount flux increases by when pulsed
    uint256 public fluxDepositFactor = 1 ether; // Factor to convert deposit amount (wei) to initial flux units (e.g., 1 ETH deposit adds 1 flux unit if factor is 1e18)

    // Type-specific decay multipliers
    mapping(uint8 => uint256) public cellTypeDecayFactors; // Multiplier for globalDecayRatePerSecond based on cell type

    // --- Modifiers ---
    modifier validCellId(uint256 _cellId) {
        if (!cells[_cellId].isActive) {
            revert Vault__InvalidCellId();
        }
        _;
    }

    modifier isCellOwner(uint256 _cellId) {
        if (cells[_cellId].depositor != msg.sender) {
            revert Vault__NotCellOwner();
        }
        _;
    }

    modifier hasEth() {
        if (msg.value == 0) {
            revert Vault__NoEthDeposited();
        }
        _;
    }

    // --- Constructor ---
    constructor() Ownable(msg.sender) Pausable() {
        _cellCounter = 0;
        // Set some default cell type decay factors
        cellTypeDecayFactors[0] = 1;   // Type 0: Standard decay
        cellTypeDecayFactors[1] = 2;   // Type 1: Faster decay
        cellTypeDecayFactors[2] = 5;   // Type 2: Much faster decay
        cellTypeDecayFactors[100] = 0; // Type 100: No decay (locked until split/merge/transfer?) - example of different behavior
        emit ParametersUpdated();
    }

    // --- Internal/Pure Helper Functions ---

    /**
     * @dev Calculates the current flux level of a cell based on its state and elapsed time.
     *      Uses linear decay: current = fluxAtLastUpdate - decayRate * timeElapsed.
     * @param _cell The cell struct.
     * @return The calculated current flux level.
     */
    function _calculateCurrentFlux(Cell storage _cell) internal view returns (uint256) {
        uint256 elapsed = block.timestamp.sub(_cell.lastFluxUpdateTime);
        uint256 effectiveDecayRate = globalDecayRatePerSecond.mul(cellTypeDecayFactors[_cell.cellType]);

        // Prevent decay if effective rate is 0
        if (effectiveDecayRate == 0) {
             return _cell.fluxAtLastUpdate;
        }

        uint256 decayAmount = elapsed.mul(effectiveDecayRate);

        // Flux cannot go below zero
        return _cell.fluxAtLastUpdate > decayAmount ? _cell.fluxAtLastUpdate.sub(decayAmount) : 0;
    }

    /**
     * @dev Updates a cell's stored flux and timestamp to the current state.
     *      This should be called before modifying the flux (deposit, pulse, harvest).
     * @param _cellId The ID of the cell to update.
     */
    function _updateCellFluxState(uint256 _cellId) internal {
        Cell storage cell = cells[_cellId];
        uint256 currentFlux = _calculateCurrentFlux(cell);
        cell.fluxAtLastUpdate = currentFlux;
        cell.lastFluxUpdateTime = block.timestamp;
    }

    /**
     * @dev Adds a cell ID to a user's list. Note: This is a simplistic list.
     * @param _user The user's address.
     * @param _cellId The cell ID to add.
     */
    function _addCellToUser(address _user, uint256 _cellId) internal {
         _userCells[_user].push(_cellId);
         // Note: A more gas-efficient or robust method for dynamic arrays might be needed
         // for production, but this serves the example. Removal is logical (`isActive`).
    }

     /**
     * @dev Logically removes a cell ID from a user's list by setting isActive to false.
     *      Actual removal from the array _userCells is not done to save gas on array manipulation.
     *      View functions like getUserCellIds and viewAvailableForHarvest filter by isActive.
     * @param _cellId The cell ID to deactivate.
     */
    function _deactivateCell(uint256 _cellId) internal {
        Cell storage cell = cells[_cellId];
        cell.isActive = false;
        cell.amount = 0; // Zero out amount for clarity
        cell.fluxAtLastUpdate = 0; // Zero out flux
        // depositor and other fields remain for historical lookup if needed
    }


    // --- Admin/Setup Functions ---

    /**
     * @dev Pauses the contract. Only callable by the owner.
     */
    function pauseContract() external onlyOwner whenNotPaused {
        _pause();
    }

    /**
     * @dev Unpauses the contract. Only callable by the owner.
     */
    function unpauseContract() external onlyOwner whenPaused {
        _unpause();
    }

    /**
     * @dev Sets the global base decay rate per second.
     * @param _newRatePerSecond The new base decay rate.
     */
    function setGlobalDecayRate(uint256 _newRatePerSecond) external onlyOwner {
        globalDecayRatePerSecond = _newRatePerSecond;
        emit ParametersUpdated();
    }

    /**
     * @dev Sets the maximum flux level allowed for harvesting.
     * @param _newThreshold The new decay threshold.
     */
    function setDecayThreshold(uint256 _newThreshold) external onlyOwner {
        decayThreshold = _newThreshold;
        emit ParametersUpdated();
    }

    /**
     * @dev Sets the parameters for triggering a flux pulse.
     * @param _pulseCost The Ether cost for a pulse.
     * @param _pulseIncrease The amount flux increases by on a pulse.
     */
    function setPulseParameters(uint256 _pulseCost, uint256 _pulseIncrease) external onlyOwner {
         pulseCost = _pulseCost;
         pulseIncreaseAmount = _pulseIncrease;
         emit ParametersUpdated();
    }

    /**
     * @dev Sets the factor used to convert deposit amount to initial flux.
     *      Higher factor means less flux per ETH deposited.
     * @param _newFactor The new flux deposit factor. Must be non-zero.
     */
    function setFluxDepositFactor(uint256 _newFactor) external onlyOwner {
         if (_newFactor == 0) {
             revert Vault__InvalidDecayFactor(); // Reusing error, maybe need a specific one
         }
         fluxDepositFactor = _newFactor;
         emit ParametersUpdated();
    }

    /**
     * @dev Sets or updates the decay factor multiplier for a specific cell type.
     *      Effective Decay Rate = globalDecayRatePerSecond * cellTypeDecayFactors[_cellType].
     * @param _cellType The identifier for the cell type.
     * @param _factorMultiplier The multiplier for this cell type (e.g., 100 for 100x faster decay).
     */
    function setCellTypeDecayFactor(uint8 _cellType, uint256 _factorMultiplier) external onlyOwner {
         cellTypeDecayFactors[_cellType] = _factorMultiplier;
         emit ParametersUpdated();
    }


    /**
     * @dev Allows the owner to withdraw all ETH from the contract in case of emergency, only when paused.
     */
    function emergencyOwnerWithdraw() external onlyOwner whenPaused nonReentrant {
        uint256 balance = address(this).balance;
        if (balance > 0) {
            Address.sendValue(payable(owner()), balance);
            emit EmergencyWithdrawal(balance);
        }
    }

    // --- User Interaction Functions ---

    /**
     * @dev Creates a new cell with deposited Ether. Initial flux is based on deposit amount and type.
     * @param _cellType The desired cell type for the new cell.
     */
    function createCell(uint8 _cellType) external payable whenNotPaused hasEth nonReentrant {
        _cellCounter = _cellCounter.add(1);
        uint256 cellId = _cellCounter;
        uint256 initialFlux = msg.value.div(fluxDepositFactor); // Initial flux proportional to deposit

        cells[cellId] = Cell({
            amount: msg.value,
            depositor: msg.sender,
            fluxAtLastUpdate: initialFlux,
            lastFluxUpdateTime: block.timestamp,
            cellType: _cellType,
            isActive: true
        });

        _addCellToUser(msg.sender, cellId);

        emit CellCreated(cellId, msg.sender, msg.value, initialFlux, _cellType);
    }

    /**
     * @dev Adds more Ether to an existing cell. Adds to amount and increases flux.
     * @param _cellId The ID of the cell to deposit into.
     */
    function depositToCell(uint256 _cellId) external payable whenNotPaused hasEth nonReentrant validCellId(_cellId) isCellOwner(_cellId) {
        Cell storage cell = cells[_cellId];

        // Update cell's flux state based on time elapsed *before* adding new deposit's flux
        _updateCellFluxState(_cellId);

        cell.amount = cell.amount.add(msg.value);
        // Increase flux proportionally to the new deposit amount
        cell.fluxAtLastUpdate = cell.fluxAtLastUpdate.add(msg.value.div(fluxDepositFactor));
        cell.lastFluxUpdateTime = block.timestamp; // Update timestamp after interaction

        emit DepositAdded(_cellId, msg.value, cell.fluxAtLastUpdate);
    }

    /**
     * @dev Pays a fee (pulseCost) to increase a cell's flux significantly and reset its decay timer.
     * @param _cellId The ID of the cell to pulse.
     */
    function triggerFluxPulse(uint256 _cellId) external payable whenNotPaused nonReentrant validCellId(_cellId) isCellOwner(_cellId) {
        if (msg.value < pulseCost) {
            revert Vault__InsufficientPulsePayment(pulseCost);
        }

        Cell storage cell = cells[_cellId];

        // Update cell's flux state based on time elapsed *before* pulsing
        _updateCellFluxState(_cellId);

        // Increase flux by the pulse amount
        cell.fluxAtLastUpdate = cell.fluxAtLastUpdate.add(pulseIncreaseAmount);
        cell.lastFluxUpdateTime = block.timestamp; // Update timestamp after interaction

        // Refund excess Ether
        if (msg.value > pulseCost) {
            Address.sendValue(payable(msg.sender), msg.value.sub(pulseCost));
        }

        emit FluxPulsed(_cellId, msg.sender, pulseCost, cell.fluxAtLastUpdate);
    }

    /**
     * @dev Attempts to withdraw Ether from a cell. Only succeeds if the current flux is below the decay threshold.
     * @param _cellId The ID of the cell to harvest from.
     */
    function attemptDecayHarvest(uint256 _cellId) external nonReentrant whenNotPaused validCellId(_cellId) isCellOwner(_cellId) {
        Cell storage cell = cells[_cellId];

        // Update cell's flux state based on time elapsed
        _updateCellFluxState(_cellId);
        uint256 currentFlux = cell.fluxAtLastUpdate;

        bool success = false;
        if (currentFlux <= decayThreshold) {
            uint256 amountToTransfer = cell.amount;
            _deactivateCell(_cellId); // Mark cell as inactive *before* transfer

            // Transfer the Ether
            Address.sendValue(payable(msg.sender), amountToTransfer);

            emit CellHarvested(_cellId, msg.sender, amountToTransfer);
            success = true;
        } else {
            revert Vault__HarvestNotReady(currentFlux, decayThreshold);
        }

        emit HarvestAttempted(_cellId, msg.sender, currentFlux, decayThreshold, success);
    }

    /**
     * @dev Splits an active cell into two. The original cell's amount and flux are reduced,
     *      and a new cell is created with the specified amount and a proportional flux.
     * @param _cellId The ID of the cell to split.
     * @param _amountForNewCell The amount of Ether to put into the new cell.
     */
    function splitCell(uint256 _cellId, uint256 _amountForNewCell) external whenNotPaused nonReentrant validCellId(_cellId) isCellOwner(_cellId) {
         Cell storage originalCell = cells[_cellId];

         if (_amountForNewCell == 0 || _amountForNewCell >= originalCell.amount) {
             revert Vault__SplitAmountTooLarge();
         }

         // Update original cell's flux based on time elapsed
         _updateCellFluxState(_cellId);
         uint256 originalCurrentFlux = originalCell.fluxAtLastUpdate;

         // Calculate proportional flux for the new cell
         // fluxForNew = (amountForNew / originalAmount) * originalFlux
         uint256 fluxForNewCell = originalCurrentFlux.mul(_amountForNewCell).div(originalCell.amount);
         uint256 originalRemainingAmount = originalCell.amount.sub(_amountForNewCell);
         uint256 originalRemainingFlux = originalCurrentFlux.sub(fluxForNewCell); // The rest stays with the original

         // Create the new cell
         _cellCounter = _cellCounter.add(1);
         uint256 newCellId = _cellCounter;

         cells[newCellId] = Cell({
             amount: _amountForNewCell,
             depositor: originalCell.depositor, // New cell owned by original owner
             fluxAtLastUpdate: fluxForNewCell,
             lastFluxUpdateTime: block.timestamp,
             cellType: originalCell.cellType, // New cell has same type
             isActive: true
         });
         _addCellToUser(originalCell.depositor, newCellId);

         // Update the original cell
         originalCell.amount = originalRemainingAmount;
         originalCell.fluxAtLastUpdate = originalRemainingFlux;
         originalCell.lastFluxUpdateTime = block.timestamp; // Reset timer for both

         emit CellSplit(_cellId, newCellId, _amountForNewCell, originalRemainingAmount);
    }

    /**
     * @dev Merges two active cells owned by the caller into a single new cell.
     *      The amounts are combined, and fluxes are summed (capped at a high value).
     * @param _cellId1 The ID of the first cell to merge.
     * @param _cellId2 The ID of the second cell to merge.
     */
    function mergeCells(uint256 _cellId1, uint256 _cellId2) external whenNotPaused nonReentrant validCellId(_cellId1) validCellId(_cellId2) isCellOwner(_cellId1) isCellOwner(_cellId2) {
         if (_cellId1 == _cellId2) {
             revert Vault__MergeFailedCannotMergeSelf();
         }
         if (cells[_cellId1].depositor != cells[_cellId2].depositor) {
             revert Vault__MergeFailedNotSameOwner(); // Should be caught by isCellOwner, but extra check
         }

         Cell storage cell1 = cells[_cellId1];
         Cell storage cell2 = cells[_cellId2];

         // Update both cells' flux states before merging
         _updateCellFluxState(_cellId1);
         _updateCellFluxState(_cellId2);

         uint256 totalAmount = cell1.amount.add(cell2.amount);
         // Combine fluxes - simple sum, capped to avoid overflow/unrealistic values
         uint256 combinedFlux = cell1.fluxAtLastUpdate.add(cell2.fluxAtLastUpdate);
         uint256 maxFlux = type(uint256).max - 1000; // Set a high practical cap
         if (combinedFlux > maxFlux) {
            combinedFlux = maxFlux;
         }


         // Create the new merged cell - potentially use a specific 'merged' cell type?
         // For simplicity, let's use the type of the first cell or default.
         uint8 mergedCellType = cell1.cellType; // Could add logic to choose type

         _cellCounter = _cellCounter.add(1);
         uint256 mergedCellId = _cellCounter;

         cells[mergedCellId] = Cell({
             amount: totalAmount,
             depositor: msg.sender,
             fluxAtLastUpdate: combinedFlux,
             lastFluxUpdateTime: block.timestamp, // Reset timer for the new cell
             cellType: mergedCellType,
             isActive: true
         });
         _addCellToUser(msg.sender, mergedCellId);

         // Deactivate the original cells
         _deactivateCell(_cellId1);
         _deactivateCell(_cellId2);

         emit CellsMerged(_cellId1, _cellId2, mergedCellId, totalAmount);
    }

     /**
      * @dev Transfers ownership of a cell to another address.
      *      Note: The receiving address must be prepared to manage the cell.
      * @param _cellId The ID of the cell to transfer.
      * @param _newOwner The address of the new owner.
      */
     function transferCellOwnership(uint256 _cellId, address _newOwner) external whenNotPaused validCellId(_cellId) isCellOwner(_cellId) {
         if (_newOwner == address(0)) {
             revert Vault__ZeroAddressNotAllowed();
         }
         if (_newOwner == msg.sender) {
             // No-op
             return;
         }

         Cell storage cell = cells[_cellId];
         address oldOwner = cell.depositor;

         // No flux update needed on transfer itself, state carries over
         cell.depositor = _newOwner;

         // Update user cell lists (logical removal from old, addition to new)
         // Note: Actual removal from the array _userCells[oldOwner] is not done.
         _addCellToUser(_newOwner, _cellId); // Add to new owner's list

         emit CellOwnershipTransferred(_cellId, oldOwner, _newOwner);
     }

     /**
      * @dev Attempts to harvest from a list of cells in a single transaction.
      *      If a harvest fails for a specific cell (e.g., flux too high), it is skipped,
      *      and an event is emitted for the failure.
      * @param _cellIds An array of cell IDs to attempt harvesting from.
      */
     function batchAttemptDecayHarvest(uint256[] calldata _cellIds) external whenNotPaused nonReentrant {
         // Note: This function can be gas-intensive depending on the number of cellIds
         for (uint i = 0; i < _cellIds.length; i++) {
             uint256 cellId = _cellIds[i];

             // Check if the cell exists, is active, and owned by the caller
             if (!cells[cellId].isActive || cells[cellId].depositor != msg.sender) {
                 emit HarvestAttempted(cellId, msg.sender, 0, 0, false); // Log failure for invalid/inactive/not owned cell
                 emit Vault__BatchHarvestFailed(cellId); // Indicate failure
                 continue; // Skip to the next cell
             }

             // Use a try/catch block to handle failed harvests gracefully within the batch
             try this.attemptDecayHarvest(cellId) {}
             catch {
                 // Catch any revert from attemptDecayHarvest (e.g., flux too high)
                 // The attemptHarvest event *inside* attemptDecayHarvest should already log the failure reason (flux too high)
                 // We can log an additional event here if needed, or rely on the internal one.
                  emit Vault__BatchHarvestFailed(cellId);
             }
         }
     }


    // --- View/Read Functions ---

    /**
     * @dev Returns the current calculated flux level for a cell.
     * @param _cellId The ID of the cell.
     * @return The current flux level.
     */
    function getCurrentFluxLevel(uint256 _cellId) public view validCellId(_cellId) returns (uint256) {
        return _calculateCurrentFlux(cells[_cellId]);
    }

    /**
     * @dev Returns the details of a specific cell.
     * @param _cellId The ID of the cell.
     * @return amount The Ether amount in the cell.
     * @return depositor The owner of the cell.
     * @return currentFlux The current calculated flux level.
     * @return lastUpdate The timestamp of the last flux update.
     * @return cellType The type of the cell.
     * @return isActive Is the cell active.
     */
    function getCellDetails(uint256 _cellId) external view validCellId(_cellId) returns (uint256 amount, address depositor, uint256 currentFlux, uint256 lastUpdate, uint8 cellType, bool isActive) {
        Cell storage cell = cells[_cellId];
        return (
            cell.amount,
            cell.depositor,
            _calculateCurrentFlux(cell), // Calculate flux dynamically for view
            cell.lastFluxUpdateTime,
            cell.cellType,
            cell.isActive
        );
    }

    /**
     * @dev Returns a list of cell IDs owned by a user. Filters out inactive cells.
     *      Note: This iterates through a potentially large array and can be gas-intensive off-chain.
     * @param _user The address of the user.
     * @return An array of active cell IDs owned by the user.
     */
    function getUserCellIds(address _user) external view returns (uint256[] memory) {
        uint256[] storage userCellsRaw = _userCells[_user];
        uint256 activeCount = 0;
        // First pass: count active cells
        for (uint i = 0; i < userCellsRaw.length; i++) {
            if (cells[userCellsRaw[i]].isActive) {
                activeCount++;
            }
        }

        // Second pass: populate active cell array
        uint256[] memory activeCellIds = new uint256[](activeCount);
        uint256 currentIndex = 0;
        for (uint i = 0; i < userCellsRaw.length; i++) {
            if (cells[userCellsRaw[i]].isActive) {
                activeCellIds[currentIndex] = userCellsRaw[i];
                currentIndex++;
            }
        }
        return activeCellIds;
    }

     /**
      * @dev Returns a list of cell IDs owned by a user that are currently eligible for harvest.
      *      Note: This iterates through user's cells and calculates flux for each.
      * @param _user The address of the user.
      * @return An array of harvestable cell IDs owned by the user.
      */
    function viewAvailableForHarvest(address _user) external view returns (uint256[] memory) {
        uint256[] storage userCellsRaw = _userCells[_user];
        uint256 harvestableCount = 0;

        // First pass: count harvestable cells
        for (uint i = 0; i < userCellsRaw.length; i++) {
            uint256 cellId = userCellsRaw[i];
            if (cells[cellId].isActive && cells[cellId].depositor == _user) {
                // Calculate flux (view version, no state update)
                 uint256 currentFlux = _calculateCurrentFlux(cells[cellId]);
                 if (currentFlux <= decayThreshold) {
                     harvestableCount++;
                 }
            }
        }

        // Second pass: populate harvestable cell array
        uint256[] memory harvestableCellIds = new uint256[](harvestableCount);
        uint256 currentIndex = 0;
        for (uint i = 0; i < userCellsRaw.length; i++) {
             uint256 cellId = userCellsRaw[i];
             if (cells[cellId].isActive && cells[cellId].depositor == _user) {
                 uint256 currentFlux = _calculateCurrentFlux(cells[cellId]);
                 if (currentFlux <= decayThreshold) {
                     harvestableCellIds[currentIndex] = cellId;
                     currentIndex++;
                 }
             }
        }
        return harvestableCellIds;
    }


    /**
     * @dev Simulates the flux level of a cell at a specific future timestamp.
     * @param _cellId The ID of the cell.
     * @param _futureTimestamp The timestamp to simulate for. Must be in the future relative to last update.
     * @return The simulated flux level at the future timestamp.
     */
    function simulateFutureFlux(uint256 _cellId, uint256 _futureTimestamp) external view validCellId(_cellId) returns (uint256) {
         Cell storage cell = cells[_cellId];
         // Cannot simulate past the last update time meaningfully with this model
         if (_futureTimestamp < cell.lastFluxUpdateTime) {
             // Or handle as needed, e.g., return fluxAtLastUpdate
             return cell.fluxAtLastUpdate;
         }

         uint256 elapsedSinceLastUpdate = _futureTimestamp.sub(cell.lastFluxUpdateTime);
         uint256 effectiveDecayRate = globalDecayRatePerSecond.mul(cellTypeDecayFactors[cell.cellType]);

         if (effectiveDecayRate == 0) {
             return cell.fluxAtLastUpdate; // No decay
         }

         uint256 decayAmount = elapsedSinceLastUpdate.mul(effectiveDecayRate);

         // Flux cannot go below zero
         return cell.fluxAtLastUpdate > decayAmount ? cell.fluxAtLastUpdate.sub(decayAmount) : 0;
    }

    /**
     * @dev Returns the total Ether balance held by the contract.
     * @return The contract's balance in wei.
     */
    function getContractBalance() external view returns (uint256) {
        return address(this).balance;
    }

    /**
     * @dev Returns the current global configuration parameters.
     * @return decayRate The base decay rate per second.
     * @return threshold The flux threshold for harvesting.
     * @return pulseCostEth The cost in Ether to pulse.
     * @return pulseIncrease The flux increase from a pulse.
     * @return depositFactor The factor for deposit-to-flux conversion.
     */
    function getGlobalParameters() external view returns (uint256 decayRate, uint256 threshold, uint256 pulseCostEth, uint256 pulseIncrease, uint256 depositFactor) {
        return (
            globalDecayRatePerSecond,
            decayThreshold,
            pulseCost,
            pulseIncreaseAmount,
            fluxDepositFactor
        );
    }

    /**
     * @dev Returns the decay factor multiplier for a specific cell type.
     * @param _cellType The identifier for the cell type.
     * @return The multiplier for this cell type.
     */
    function getCellTypeDecayFactor(uint8 _cellType) external view returns (uint256) {
        return cellTypeDecayFactors[_cellType];
    }

    // Fallback function to receive Ether if sent without calling a specific function (optional but good practice)
    fallback() external payable {
        // Could emit an event or revert depending on desired behavior
        // If intended for deposits, maybe route to createCell or depositToCell?
        // For this complex contract, likely better to require calling a specific function.
        revert("QuantumFluxVault: Direct ETH deposits not supported. Use createCell or depositToCell.");
    }

    receive() external payable {
        // Same as fallback
         revert("QuantumFluxVault: Direct ETH deposits not supported. Use createCell or depositToCell.");
    }
}
```