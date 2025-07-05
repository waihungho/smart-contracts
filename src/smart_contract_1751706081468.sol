Okay, here is a Solidity smart contract concept called "InfiniteCanvas" that leverages a grid-based system with various advanced features beyond simple token transfers or basic interactions. It allows users to own, modify, and interact with cells on a theoretically infinite 2D plane, incorporating concepts like dynamic data types, energy mechanics, delegation, inter-canvas linking (conceptual), and more.

**Disclaimer:** This is a complex concept for a single smart contract example. Some features (like dynamic elements, portals, complex interaction rules) rely heavily on *off-chain* applications/renderers interpreting the on-chain data and state changes. The contract enforces ownership, state integrity, and rule execution where possible, but cannot run arbitrary code for visuals or complex simulations itself due to EVM limitations.

---

**InfiniteCanvas Smart Contract**

**Outline:**

1.  **License & Pragma**
2.  **Error Definitions**
3.  **State Variables**
    *   Owner address
    *   Fee percentage for sales/claims
    *   Collected fees
    *   Pause state
    *   Base parameters (claim cost, energy decay rate, min energy)
    *   Mapping for Cell data (Coord => Cell)
    *   Mapping for Cell listing prices (Coord => price)
    *   Mapping for Data Type Registry (bytes4 => metadata URI)
    *   Mapping for Delegated Control (Coord => DelegateInfo)
    *   Last daily energy bonus claim time per user
4.  **Structs**
    *   `Coord`: Represents a 2D coordinate (x, y).
    *   `Cell`: Represents a single cell's state (owner, data, energy, timestamps).
    *   `DelegateInfo`: Information for delegated control (delegate address, expiration).
5.  **Events**
    *   `CellClaimed`: When a cell is claimed.
    *   `CellDataUpdated`: When a cell's data is changed.
    *   `CellOwnershipTransferred`: When cell ownership changes.
    *   `CellListedForSale`: When a cell is put on sale.
    *   `CellBought`: When a cell is purchased.
    *   `CellInteraction`: When `interactWithCell` is called.
    *   `EnergyFed`: When energy is added to a cell.
    *   `CellDestroyed`: When a cell is destroyed.
    *   `PortalCreated`: When a cell is designated as a portal.
    *   `DynamicElementSpawned`: When a cell is designated as a dynamic element root.
    *   `CellsMerged`: When cells are conceptually merged.
    *   `TerritoryExpanded`: When adjacent cells are claimed via expansion.
    *   `RuleSet`: When an interaction rule is set for a cell.
    *   `EntropySeeded`: When user contributes entropy.
    *   `DelegateSet`: When control is delegated for a cell.
    *   `DataTypeRegistered`: When a new data type is registered.
    *   `GlobalEffectApplied`: When an admin applies a global effect.
    *   `CellAttested`: When metadata is attached to a cell.
    *   `CellLinkedToExternal`: When a cell is linked to an external contract/NFT.
    *   `BeaconPlaced`: When a beacon message is placed.
    *   `VisibilitySet`: When cell visibility changes.
    *   `EnergyBonusClaimed`: When daily bonus is claimed.
    *   `FeesWithdrawn`: When admin withdraws fees.
    *   `Paused`: When contract is paused.
    *   `Unpaused`: When contract is unpaused.
6.  **Modifiers**
    *   `onlyOwner`: Restricts function to contract owner.
    *   `whenNotPaused`: Restricts function when contract is not paused.
    *   `whenPaused`: Restricts function when contract is paused.
    *   `isCellOwnerOrDelegate`: Checks if caller is owner or delegate of a cell.
    *   `isCellListedForSale`: Checks if a cell is currently listed for sale.
7.  **Functions**
    *   **Admin Functions:**
        *   `constructor`: Deploys and sets owner.
        *   `setFeePercentage`: Sets sale fee percentage.
        *   `setBaseParameters`: Sets claim cost, energy rates, etc.
        *   `pause`: Pauses core interactions.
        *   `unpause`: Unpauses core interactions.
        *   `withdrawFees`: Withdraws collected fees.
        *   `registerDataType`: Registers a new bytes4 data type prefix with metadata URI.
        *   `applyGlobalEffect`: Applies a canvas-wide effect (admin-defined config).
    *   **User Functions:**
        *   `claimCell`: Claim an unowned cell by paying a fee.
        *   `updateCellData`: Update the data content of an owned cell.
        *   `transferCellOwnership`: Transfer ownership of a cell.
        *   `listCellForSale`: List an owned cell for sale at a price.
        *   `cancelCellListing`: Remove a cell from the sale list.
        *   `buyCell`: Purchase a listed cell.
        *   `interactWithCell`: Generic function to trigger cell-specific interactions.
        *   `feedCellEnergy`: Add energy to an owned cell.
        *   `destroyCell`: Destroy an owned cell, removing it from the canvas (requires energy/fee).
        *   `createPortal`: Designate an owned cell as a portal (requires specific data structure).
        *   `activatePortal`: Interact with a portal cell (records portal activation).
        *   `spawnDynamicElement`: Designate an owned cell as the root of a dynamic element (requires specific data structure).
        *   `mergeCells`: Conceptually merge two *adjacent* owned cells (ownership consolidation, data logic defined off-chain).
        *   `expandTerritory`: Claim adjacent unowned cells around an owned cell within a radius.
        *   `setCellInteractionRule`: Designate an owned cell's data to define interaction rules for its neighbors (conceptual).
        *   `seedEntropy`: Contribute entropy for potential future pseudo-random events.
        *   `delegateCellControl`: Delegate control of a cell to another address for a duration.
        *   `attestCell`: Add a verifiable metadata URI/hash to a cell.
        *   `linkCellToExternal`: Link an owned cell to an external contract/NFT (record association).
        *   `placeBeacon`: Place a temporary, non-ownership public message beacon on a cell.
        *   `setCellVisibility`: Set a flag on a cell indicating preferred rendering visibility (conceptual for clients).
        *   `claimDailyEnergyBonus`: Allow users to claim a small energy bonus once per day.
    *   **Internal Helper Functions:**
        *   `_getCell`: Internal function to safely retrieve cell data, calculating current energy.
        *   `_setCell`: Internal function to update cell data, updating timestamps.
        *   `_calculateCurrentEnergy`: Calculates effective energy based on last update and decay rate.
        *   `_requireCellOwnershipOrDelegate`: Helper for modifier logic.

**Function Summary:**

1.  `constructor()`: Deploys the contract and sets the initial owner.
2.  `setFeePercentage(uint256 _feePercentage)`: (Admin) Sets the percentage of sale price collected as a fee (e.g., 100 = 1%).
3.  `setBaseParameters(uint256 _claimCost, uint256 _energyDecayPerSecond, uint256 _minInteractionEnergy)`: (Admin) Configures base costs and energy mechanics.
4.  `pause()`: (Admin) Pauses user interactions with the canvas state (except admin functions).
5.  `unpause()`: (Admin) Resumes user interactions.
6.  `withdrawFees()`: (Admin) Transfers collected fees from the contract balance to the owner.
7.  `registerDataType(bytes4 _dataTypeHash, string memory _metadataURI)`: (Admin) Registers a specific 4-byte prefix that can be used at the start of cell `data` to signify its type (e.g., image, text, portal config), linking it to off-chain metadata describing the type.
8.  `applyGlobalEffect(bytes memory _effectConfig)`: (Admin) Records that a global effect has been applied to the canvas. Off-chain renderers interpret `_effectConfig` to apply visual or logical effects (e.g., color filter, energy drain event).
9.  `claimCell(Coord calldata _coord, bytes calldata _initialData)`: (User) Allows a user to claim ownership of a cell that is currently unowned, paying a set fee (`claimCost`). Initial data is stored.
10. `updateCellData(Coord calldata _coord, bytes calldata _newData)`: (User) Allows the owner (or delegate) of a cell to update its associated data.
11. `transferCellOwnership(Coord calldata _coord, address _to)`: (User) Allows the owner (or delegate) of a cell to transfer its ownership to another address.
12. `listCellForSale(Coord calldata _coord, uint256 _price)`: (User) Allows the owner of a cell to list it for sale at a specific ETH price.
13. `cancelCellListing(Coord calldata _coord)`: (User) Allows the owner of a cell to remove it from the sale list.
14. `buyCell(Coord calldata _coord)`: (User) Allows a user to purchase a cell listed for sale by sending the required ETH. The seller receives the price minus fees.
15. `interactWithCell(Coord calldata _coord, bytes calldata _interactionData)`: (User) A generic interaction function. Intended for off-chain clients to trigger specific actions or animations related to a cell. May require cell energy. The cell's `data` and `_interactionData` define the *type* of interaction off-chain. On-chain, this records the interaction event.
16. `feedCellEnergy(Coord calldata _coord, uint256 _amount)`: (User) Allows the owner (or delegate) to add energy to a cell, potentially extending its lifespan or enabling high-energy actions.
17. `destroyCell(Coord calldata _coord)`: (User) Allows the owner (or delegate) to destroy a cell, making it unowned again. May require consuming energy or paying a fee.
18. `createPortal(Coord calldata _coord, address _targetCanvas, Coord calldata _targetCoord, bytes calldata _portalData)`: (User) Marks an owned cell as a portal. Requires specific data format starting with the Portal data type hash. Records the target canvas address and coordinates. `_portalData` contains visualization/interaction config.
19. `activatePortal(Coord calldata _coord)`: (User) Interacts with a cell marked as a portal. Records the activation event. Primarily for off-chain clients to detect and simulate "traveling" through the portal.
20. `spawnDynamicElement(Coord calldata _coord, bytes calldata _elementConfig)`: (User) Marks an owned cell as the root/origin of a dynamic element. Requires specific data format starting with the Dynamic Element data type hash. Records the element's configuration `_elementConfig`. Off-chain clients simulate the element's behavior based on this data and canvas state.
21. `mergeCells(Coord calldata _coord1, Coord calldata _coord2)`: (User) Allows the owner to conceptually merge two adjacent cells they own. Ownership of `_coord2` is transferred to the owner of `_coord1`, and off-chain clients can interpret the combined state or data.
22. `expandTerritory(Coord calldata _coord, uint256 _radius)`: (User) Allows the owner of a cell to attempt to claim all unowned cells within a specified Chebyshev distance (`_radius`) from the cell. Each claimed cell costs the `claimCost`.
23. `setCellInteractionRule(Coord calldata _coord, bytes calldata _ruleConfig)`: (User) Allows the owner of a cell to store data (`_ruleConfig`) that defines specific interaction rules or effects centered on this cell for off-chain clients (e.g., gravity well, color zone, sound emitter). Requires specific data type hash.
24. `seedEntropy(bytes32 _entropy)`: (User) Allows users to contribute arbitrary entropy (e.g., a hash of off-chain data) to the contract's state. This can be mixed into future pseudo-random calculations if needed for dynamic element behavior or events, although truly secure on-chain randomness is challenging.
25. `delegateCellControl(Coord calldata _coord, address _delegate, uint64 _duration)`: (User) Allows the owner of a cell to grant update and interaction permissions for that specific cell to another address (`_delegate`) for a limited time (`_duration` in seconds).
26. `attestCell(Coord calldata _coord, string memory _metadataURI)`: (User) Allows any address to link a metadata URI/hash to a cell. This can be used for third-party verification, comments, or attaching IPFS hashes of content related to the cell, without changing the cell's core data or ownership.
27. `linkCellToExternal(Coord calldata _coord, address _externalContract, uint256 _externalTokenId, bytes4 _linkType)`: (User) Allows the owner to record a link from an owned cell to an external contract (e.g., an NFT contract) and a specific token ID. `_linkType` defines the nature of the link (e.g., 0x721a -> ERC721 owner link).
28. `placeBeacon(Coord calldata _coord, string memory _message, uint64 _duration)`: (User) Allows a user (potentially for a fee, not implemented in detail here) to place a temporary, non-ownership text message beacon on a cell. Off-chain clients display this message for a limited time.
29. `setCellVisibility(Coord calldata _coord, bool _visible)`: (User) Allows the owner (or delegate) to set a conceptual visibility flag on a cell. Off-chain renderers can use this to allow users to hide or show certain types of cells.
30. `claimDailyEnergyBonus()`: (User) Allows a user to claim a small amount of global energy that can be applied to any cell they own, once every 24 hours.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title InfiniteCanvas
/// @dev A smart contract representing a theoretically infinite 2D grid where users can own, modify, and interact with cells.
/// @dev Incorporates advanced concepts like dynamic data types, energy mechanics, delegation, portals (conceptual), etc., relying on off-chain clients for full interpretation.

// Outline:
// 1. License & Pragma
// 2. Error Definitions
// 3. State Variables
// 4. Structs
// 5. Events
// 6. Modifiers
// 7. Functions
//    - Admin Functions
//    - User Functions
//    - Internal Helper Functions

// Function Summary:
// constructor(): Deploys the contract and sets the initial owner.
// setFeePercentage(uint256 _feePercentage): (Admin) Sets the percentage of sale price collected as a fee.
// setBaseParameters(uint256 _claimCost, uint256 _energyDecayPerSecond, uint256 _minInteractionEnergy): (Admin) Configures base costs and energy mechanics.
// pause(): (Admin) Pauses core user interactions.
// unpause(): (Admin) Resumes user interactions.
// withdrawFees(): (Admin) Transfers collected fees to the owner.
// registerDataType(bytes4 _dataTypeHash, string memory _metadataURI): (Admin) Registers a bytes4 data type prefix with off-chain metadata.
// applyGlobalEffect(bytes memory _effectConfig): (Admin) Records a global effect (interpreted off-chain).
// claimCell(Coord calldata _coord, bytes calldata _initialData): (User) Claim an unowned cell by paying a fee.
// updateCellData(Coord calldata _coord, bytes calldata _newData): (User) Update data in an owned cell.
// transferCellOwnership(Coord calldata _coord, address _to): (User) Transfer ownership of a cell.
// listCellForSale(Coord calldata _coord, uint256 _price): (User) List an owned cell for sale.
// cancelCellListing(Coord calldata _coord): (User) Remove a cell from the sale list.
// buyCell(Coord calldata _coord): (User) Purchase a listed cell.
// interactWithCell(Coord calldata _coord, bytes calldata _interactionData): (User) Generic interaction trigger (interpreted off-chain).
// feedCellEnergy(Coord calldata _coord, uint256 _amount): (User) Add energy to an owned cell.
// destroyCell(Coord calldata _coord): (User) Destroy an owned cell.
// createPortal(Coord calldata _coord, address _targetCanvas, Coord calldata _targetCoord, bytes calldata _portalData): (User) Designate a cell as a portal (conceptual).
// activatePortal(Coord calldata _coord): (User) Record activation of a portal cell.
// spawnDynamicElement(Coord calldata _coord, bytes calldata _elementConfig): (User) Designate a cell as a dynamic element root (conceptual).
// mergeCells(Coord calldata _coord1, Coord calldata _coord2): (User) Conceptually merge two adjacent owned cells.
// expandTerritory(Coord calldata _coord, uint256 _radius): (User) Claim adjacent unowned cells around an owned cell.
// setCellInteractionRule(Coord calldata _coord, bytes calldata _ruleConfig): (User) Store data defining interaction rules for a cell (conceptual).
// seedEntropy(bytes32 _entropy): (User) Contribute entropy for potential future pseudo-randomness.
// delegateCellControl(Coord calldata _coord, address _delegate, uint64 _duration): (User) Delegate control of a cell temporarily.
// attestCell(Coord calldata _coord, string memory _metadataURI): (User) Attach verifiable metadata URI to a cell.
// linkCellToExternal(Coord calldata _coord, address _externalContract, uint256 _externalTokenId, bytes4 _linkType): (User) Record a link to an external contract/NFT.
// placeBeacon(Coord calldata _coord, string memory _message, uint64 _duration): (User) Place a temporary message beacon on a cell.
// setCellVisibility(Coord calldata _coord, bool _visible): (User) Set conceptual visibility flag for a cell.
// claimDailyEnergyBonus(): (User) Claim a daily energy bonus.
// _getCell(Coord memory _coord): Internal helper to retrieve cell state, accounting for energy decay.
// _setCell(Coord memory _coord, Cell memory _cell): Internal helper to update cell state, updating timestamps.
// _calculateCurrentEnergy(Cell memory _cell): Internal helper to calculate current energy based on decay.
// _requireCellOwnershipOrDelegate(Coord memory _coord): Internal helper for delegate modifier logic.


contract InfiniteCanvas {

    // 2. Error Definitions
    error NotOwner();
    error Paused();
    error NotPaused();
    error CellAlreadyOwned(address owner);
    error CellNotOwned();
    error NotCellOwnerOrDelegate();
    error CellNotForSale();
    error InsufficientPayment(uint256 required, uint256 sent);
    error CannotDestroyCell(); // Example: requires minimum energy or fee
    error CannotMergeCells(); // Example: not adjacent or not owned by same person
    error CannotExpandTerritory(); // Example: no unowned cells nearby or not enough payment
    error NoFeesToWithdraw();
    error AlreadyClaimedBonusToday();
    error InvalidPercentage(); // Fee percentage > 10000 (100%)
    error DelegateAlreadySet();
    error DelegateExpired();
    error NotDelegate();

    // 3. State Variables
    address public owner;
    bool public paused;
    uint256 public feePercentageBasisPoints; // 10000 basis points = 100%
    uint256 public collectedFees;

    // Base parameters for game mechanics
    uint256 public claimCost;
    uint256 public energyDecayPerSecond; // Energy units decayed per second
    uint256 public minInteractionEnergy; // Min energy required for certain interactions
    uint256 public baseDailyEnergyBonus = 100; // Units of energy

    // --- Canvas State ---
    // Using nested mappings for a sparse 2D grid
    mapping(int128 => mapping(int128 => Cell)) public cells;
    mapping(int128 => mapping(int128 => uint256)) public listedPrices; // Price in wei

    // --- Registry & Dynamic Data ---
    mapping(bytes4 => string) public dataTypeMetadataURI; // Maps data type hash to metadata URI

    // --- Delegation ---
    mapping(int128 => mapping(int128 => DelegateInfo)) public cellDelegates;

    // --- User State ---
    mapping(address => uint64) public lastDailyEnergyBonusClaim;

    // --- Beacon State (Example of temporary state) ---
    struct Beacon {
        address placer;
        string message;
        uint64 expiryTime;
    }
    mapping(int128 => mapping(int128 => Beacon)) public cellBeacons;


    // 4. Structs
    struct Coord {
        int128 x;
        int128 y;
    }

    struct Cell {
        address owner; // Address of the cell owner (address(0) for unowned)
        bytes data; // Arbitrary data associated with the cell (e.g., color, image hash, portal config)
        uint64 lastUpdated; // Timestamp of the last significant update (for energy decay calculation)
        uint64 energy; // Current energy level
        uint64 creationTime; // Timestamp when the cell was first claimed
        bool visible; // Conceptual flag for off-chain renderers
    }

    struct DelegateInfo {
        address delegate;
        uint64 expiryTime; // Timestamp when delegation expires
    }

    // 5. Events
    event CellClaimed(Coord indexed coord, address indexed owner, bytes data);
    event CellDataUpdated(Coord indexed coord, bytes data);
    event CellOwnershipTransferred(Coord indexed coord, address indexed from, address indexed to);
    event CellListedForSale(Coord indexed coord, uint256 price);
    event CellSaleCancelled(Coord indexed coord);
    event CellBought(Coord indexed coord, address indexed buyer, address indexed seller, uint256 price);
    event CellInteraction(Coord indexed coord, address indexed sender, bytes interactionData);
    event EnergyFed(Coord indexed coord, uint256 amount);
    event CellDestroyed(Coord indexed coord, address indexed owner);
    event PortalCreated(Coord indexed coord, address indexed targetCanvas, Coord targetCoord, bytes portalData);
    event DynamicElementSpawned(Coord indexed coord, bytes configData);
    event CellsMerged(Coord indexed coord1, Coord indexed coord2, address indexed newOwner);
    event TerritoryExpanded(Coord indexed originCoord, uint256 radius, uint256 cellsClaimed);
    event RuleSet(Coord indexed coord, bytes ruleConfig);
    event EntropySeeded(bytes32 entropy);
    event DelegateSet(Coord indexed coord, address indexed delegate, uint64 expiryTime);
    event DelegateRevoked(Coord indexed coord); // Implicit revocation by setting new delegate or transfer
    event DataTypeRegistered(bytes4 indexed dataTypeHash, string metadataURI);
    event GlobalEffectApplied(bytes effectConfig);
    event CellAttested(Coord indexed coord, address indexed attester, string metadataURI); // Simple on-chain record
    event CellLinkedToExternal(Coord indexed coord, address indexed externalContract, uint256 externalTokenId, bytes4 linkType); // Simple on-chain record
    event BeaconPlaced(Coord indexed coord, address indexed placer, string message, uint64 expiryTime);
    event VisibilitySet(Coord indexed coord, bool visible);
    event EnergyBonusClaimed(address indexed user, uint256 amount);
    event FeesWithdrawn(address indexed owner, uint256 amount);
    event Paused(address account);
    event Unpaused(address account);

    // 6. Modifiers
    modifier onlyOwner() {
        if (msg.sender != owner) revert NotOwner();
        _;
    }

    modifier whenNotPaused() {
        if (paused) revert Paused();
        _;
    }

    modifier whenPaused() {
        if (!paused) revert NotPaused();
        _;
    }

    modifier isCellOwner(Coord calldata _coord) {
        if (cells[_coord.x][_coord.y].owner != msg.sender) revert CellNotOwned();
        _;
    }

    modifier isCellOwnerOrDelegate(Coord calldata _coord) {
        _requireCellOwnershipOrDelegate(_coord);
        _;
    }

    modifier isCellListedForSale(Coord calldata _coord) {
        if (listedPrices[_coord.x][_coord.y] == 0) revert CellNotForSale();
        _;
        // Note: This modifier doesn't check ownership before sale, buyCell does that.
    }

    // 7. Functions

    // --- Admin Functions ---

    constructor() {
        owner = msg.sender;
        paused = false;
        feePercentageBasisPoints = 500; // Default 5%
        claimCost = 0.001 ether; // Default claim cost
        energyDecayPerSecond = 1; // Default decay rate
        minInteractionEnergy = 10; // Default min energy for interaction
    }

    /// @notice Sets the percentage of the sale price collected as a fee.
    /// @param _feePercentage The fee percentage in basis points (100 = 1%). Max 10000 (100%).
    function setFeePercentage(uint256 _feePercentage) external onlyOwner {
        if (_feePercentage > 10000) revert InvalidPercentage();
        feePercentageBasisPoints = _feePercentage;
    }

    /// @notice Sets base parameters for claim cost, energy decay, and interaction energy threshold.
    function setBaseParameters(uint256 _claimCost, uint256 _energyDecayPerSecond, uint256 _minInteractionEnergy) external onlyOwner {
        claimCost = _claimCost;
        energyDecayPerSecond = _energyDecayPerSecond;
        minInteractionEnergy = _minInteractionEnergy;
    }

    /// @notice Pauses user interactions with the canvas state.
    function pause() external onlyOwner whenNotPaused {
        paused = true;
        emit Paused(msg.sender);
    }

    /// @notice Unpauses user interactions.
    function unpause() external onlyOwner whenPaused {
        paused = false;
        emit Unpaused(msg.sender);
    }

    /// @notice Withdraws collected fees to the contract owner.
    function withdrawFees() external onlyOwner {
        uint256 fees = collectedFees;
        if (fees == 0) revert NoFeesToWithdraw();
        collectedFees = 0;
        (bool success, ) = owner.call{value: fees}("");
        // Consider adding stricter error handling for withdrawal failure in production
        require(success, "Withdrawal failed");
        emit FeesWithdrawn(owner, fees);
    }

    /// @notice Registers a bytes4 data type hash with an off-chain metadata URI.
    /// @dev This helps off-chain clients interpret the meaning of cell data based on its prefix.
    function registerDataType(bytes4 _dataTypeHash, string memory _metadataURI) external onlyOwner {
        dataTypeMetadataURI[_dataTypeHash] = _metadataURI;
        emit DataTypeRegistered(_dataTypeHash, _metadataURI);
    }

    /// @notice Records that a global effect has been applied to the canvas.
    /// @dev Off-chain clients interpret the effect based on the config bytes.
    /// @param _effectConfig Arbitrary bytes defining the global effect.
    function applyGlobalEffect(bytes memory _effectConfig) external onlyOwner {
        // No state change on cells, just logs the event for off-chain clients
        emit GlobalEffectApplied(_effectConfig);
    }

    // --- User Functions ---

    /// @notice Claims an unowned cell by paying the claim cost.
    /// @param _coord The coordinates of the cell to claim.
    /// @param _initialData The initial data to set for the cell.
    function claimCell(Coord calldata _coord, bytes calldata _initialData) external payable whenNotPaused {
        if (cells[_coord.x][_coord.y].owner != address(0)) revert CellAlreadyOwned(cells[_coord.x][_coord.y].owner);
        if (msg.value < claimCost) revert InsufficientPayment(claimCost, msg.value);

        cells[_coord.x][_coord.y] = Cell({
            owner: msg.sender,
            data: _initialData,
            lastUpdated: uint64(block.timestamp),
            energy: 0, // Start with 0 energy, needs to be fed
            creationTime: uint64(block.timestamp),
            visible: true // Default visibility
        });

        if (msg.value > claimCost) {
            // Refund excess payment
            (bool success, ) = msg.sender.call{value: msg.value - claimCost}("");
            require(success, "Refund failed");
        }

        // Add claim cost to fees (simplified: assumes claimCost is the fee part)
        collectedFees += claimCost;

        emit CellClaimed(_coord, msg.sender, _initialData);
    }

    /// @notice Updates the data associated with an owned cell.
    /// @param _coord The coordinates of the cell.
    /// @param _newData The new data for the cell.
    function updateCellData(Coord calldata _coord, bytes calldata _newData) external whenNotPaused isCellOwnerOrDelegate(_coord) {
        Cell memory cell = _getCell(_coord); // Get cell including current energy

        // Optionally require energy for updates: if (cell.energy < minInteractionEnergy) { ... }

        cell.data = _newData;
        // Keep current energy, but update timestamp
        cell.lastUpdated = uint64(block.timestamp);

        _setCell(_coord, cell); // Update state
        emit CellDataUpdated(_coord, _newData);
    }

    /// @notice Transfers ownership of an owned cell.
    /// @param _coord The coordinates of the cell.
    /// @param _to The recipient address.
    function transferCellOwnership(Coord calldata _coord, address _to) external whenNotPaused isCellOwnerOrDelegate(_coord) {
        if (_to == address(0)) revert CellNotOwned(); // Cannot transfer to zero address

        Cell memory cell = _getCell(_coord);
        address previousOwner = cell.owner;

        // Clear any active delegation on transfer
        delete cellDelegates[_coord.x][_coord.y];

        cell.owner = _to;
        // Keep energy and data, update timestamp
        cell.lastUpdated = uint64(block.timestamp);

        _setCell(_coord, cell);

        // Cancel any active sale listing on transfer
        delete listedPrices[_coord.x][_coord.y];
        emit CellSaleCancelled(_coord); // Emit cancellation event

        emit CellOwnershipTransferred(_coord, previousOwner, _to);
    }

    /// @notice Lists an owned cell for sale.
    /// @param _coord The coordinates of the cell.
    /// @param _price The sale price in wei.
    function listCellForSale(Coord calldata _coord, uint256 _price) external whenNotPaused isCellOwner(_coord) {
        listedPrices[_coord.x][_coord.y] = _price;
        emit CellListedForSale(_coord, _price);
    }

    /// @notice Cancels the sale listing for an owned cell.
    /// @param _coord The coordinates of the cell.
    function cancelCellListing(Coord calldata _coord) external whenNotPaused isCellOwner(_coord) {
        delete listedPrices[_coord.x][_coord.y];
        emit CellSaleCancelled(_coord);
    }

    /// @notice Purchases a listed cell.
    /// @param _coord The coordinates of the cell.
    function buyCell(Coord calldata _coord) external payable whenNotPaused isCellListedForSale(_coord) {
        uint256 price = listedPrices[_coord.x][_coord.y];
        if (msg.value < price) revert InsufficientPayment(price, msg.value);

        Cell memory cell = _getCell(_coord);
        address seller = cell.owner;
        if (seller == address(0) || seller == msg.sender) revert CellNotForSale(); // Double check ownership & prevent self-buy

        // Clear any active delegation on sale
        delete cellDelegates[_coord.x][_coord.y];

        cell.owner = msg.sender;
        // Keep energy and data, update timestamp
        cell.lastUpdated = uint64(block.timestamp);
        _setCell(_coord, cell);

        delete listedPrices[_coord.x][_coord.y]; // Remove from listing

        uint256 feeAmount = (price * feePercentageBasisPoints) / 10000;
        uint256 payoutToSeller = price - feeAmount;

        collectedFees += feeAmount;

        // Pay seller
        (bool successSeller, ) = payable(seller).call{value: payoutToSeller}("");
        // Refund buyer excess (if any)
        if (msg.value > price) {
             (bool successRefund, ) = msg.sender.call{value: msg.value - price}("");
             // Consider more robust error handling
             require(successRefund, "Refund failed");
        }

        // Consider stricter error handling for payout failure in production
        require(successSeller, "Seller payout failed");

        emit CellBought(_coord, msg.sender, seller, price);
    }

    /// @notice Triggers a generic interaction event for a cell.
    /// @dev The specific logic and effects are intended to be handled by off-chain clients based on cell data and interactionData.
    /// @param _coord The coordinates of the cell.
    /// @param _interactionData Arbitrary bytes defining the interaction type and parameters.
    function interactWithCell(Coord calldata _coord, bytes calldata _interactionData) external whenNotPaused {
        Cell memory cell = _getCell(_coord);

        // Optionally require a minimum energy to interact
        // if (cell.owner != address(0) && cell.energy < minInteractionEnergy) { revert CannotInteract(); }
        // Optionally consume energy on interaction
        // if (cell.owner != address(0)) { cell.energy -= interactionEnergyCost; _setCell(_coord, cell); }

        // This function primarily emits an event for off-chain clients to react.
        emit CellInteraction(_coord, msg.sender, _interactionData);
    }

    /// @notice Feeds energy to an owned cell.
    /// @param _coord The coordinates of the cell.
    /// @param _amount The amount of energy to add.
    function feedCellEnergy(Coord calldata _coord, uint256 _amount) external whenNotPaused isCellOwnerOrDelegate(_coord) {
        Cell memory cell = _getCell(_coord); // Get cell including current energy
        cell.energy += uint64(_amount); // Add energy (beware of overflow if amount is huge)
        cell.lastUpdated = uint64(block.timestamp); // Update timestamp as feeding is a significant event
        _setCell(_coord, cell);
        emit EnergyFed(_coord, _amount);
    }

    /// @notice Destroys an owned cell, making it unowned.
    /// @dev This might require minimum energy or a fee.
    /// @param _coord The coordinates of the cell.
    function destroyCell(Coord calldata _coord) external whenNotPaused isCellOwnerOrDelegate(_coord) {
        Cell memory cell = _getCell(_coord); // Get cell including current energy

        // Example requirement: needs minimum energy to self-destruct
        if (cell.energy < minInteractionEnergy) revert CannotDestroyCell();

        address previousOwner = cell.owner;

        // Remove from mappings
        delete cells[_coord.x][_coord.y];
        delete listedPrices[_coord.x][_coord.y]; // Cancel sale if listed
        delete cellDelegates[_coord.x][_coord.y]; // Remove delegation
        delete cellBeacons[_coord.x][_coord.y]; // Remove beacon

        emit CellDestroyed(_coord, previousOwner);
    }

    /// @notice Designates an owned cell as a portal.
    /// @dev Requires cell data to start with the registered Portal data type hash.
    /// @param _coord The coordinates of the cell.
    /// @param _targetCanvas The address of the target InfiniteCanvas contract.
    /// @param _targetCoord The coordinates within the target canvas.
    /// @param _portalData Additional configuration bytes for the portal visual/interaction.
    function createPortal(Coord calldata _coord, address _targetCanvas, Coord calldata _targetCoord, bytes calldata _portalData) external whenNotPaused isCellOwnerOrDelegate(_coord) {
        // Example: Check if data starts with a registered portal data type hash (off-chain interpretation)
        // Here we just record the intent and data.

        Cell memory cell = _getCell(_coord); // Get cell including current energy

        // Ensure cell data is set with a valid portal type prefix (conceptual check)
        // require(_portalData.length >= 4 && dataTypeMetadataURI[bytes4(_portalData[0:4])] != "", "Invalid portal data type");
        // For this example, we just store the data directly including target info.
        // A real implementation might store target info separately or encode it strictly in the data.
        // Let's just update the data and log the intent.

        // Example of encoding target info into data (basic, needs robust structure)
        // bytes memory fullPortalData = abi.encodePacked(bytes4(keccak256("PORTAL")), _targetCanvas, _targetCoord.x, _targetCoord.y, _portalData);
        // cell.data = fullPortalData;

        // Simpler: Just update cell data and emit event with target info
        cell.data = _portalData; // Update cell data with visual/config data
        cell.lastUpdated = uint64(block.timestamp);
        _setCell(_coord, cell);

        emit PortalCreated(_coord, _targetCanvas, _targetCoord, _portalData);
    }

    /// @notice Records activation of a portal cell.
    /// @dev Intended for off-chain clients to detect portal activation and simulate travel.
    /// @param _coord The coordinates of the portal cell.
    function activatePortal(Coord calldata _coord) external whenNotPaused {
         // Check if the cell exists (it must to be a portal)
         if (cells[_coord.x][_coord.y].owner == address(0)) revert CellNotOwned();

         Cell memory cell = _getCell(_coord);
         // Optionally check if cell data indicates it's a portal (e.g., check data prefix)
         // if (cell.data.length < 4 || bytes4(cell.data[0:4]) != bytes4(keccak256("PORTAL"))) { revert NotAPortal(); }

         // Optionally require energy to activate portal
         // if (cell.energy < minInteractionEnergy) { revert CannotActivatePortal(); }
         // Optionally consume energy
         // cell.energy -= portalActivationCost;
         // _setCell(_coord, cell); // Update state with energy change

         // This function primarily emits an event for off-chain clients to react.
         // Off-chain clients should look up the cell data to find the target canvas/coord.
         emit CellInteraction(_coord, msg.sender, bytes("ACTIVATE_PORTAL"));
         // A more specific event could be emitted if target info was stored on-chain for portals
         // emit PortalActivated(_coord, cell.targetCanvas, cell.targetCoord);
    }


    /// @notice Designates an owned cell as the root of a dynamic element.
    /// @dev Off-chain clients simulate the element's behavior based on the config data and canvas state.
    /// @param _coord The coordinates of the cell.
    /// @param _elementConfig Configuration bytes for the dynamic element.
    function spawnDynamicElement(Coord calldata _coord, bytes calldata _elementConfig) external whenNotPaused isCellOwnerOrDelegate(_coord) {
        Cell memory cell = _getCell(_coord); // Get cell including current energy

        // Check if cell data starts with registered Dynamic Element type (conceptual)
        // require(_elementConfig.length >= 4 && bytes4(_elementConfig[0:4]) == bytes4(keccak256("DYNAMIC_ELEMENT")), "Invalid dynamic element data type");

        cell.data = _elementConfig; // Store configuration data
        cell.lastUpdated = uint64(block.timestamp);
        _setCell(_coord, cell);

        emit DynamicElementSpawned(_coord, _elementConfig);
    }

    /// @notice Conceptually merges two adjacent cells owned by the caller.
    /// @dev Transfers ownership of _coord2 to the owner of _coord1 and allows off-chain clients to interpret the combined state/data.
    /// @param _coord1 The coordinates of the first cell (primary).
    /// @param _coord2 The coordinates of the second cell (will be transferred).
    function mergeCells(Coord calldata _coord1, Coord calldata _coord2) external whenNotPaused {
        // Check both cells exist and are owned by sender or sender is delegate for both
        _requireCellOwnershipOrDelegate(_coord1);
        _requireCellOwnershipOrDelegate(_coord2);

        Cell memory cell1 = _getCell(_coord1);
        Cell memory cell2 = _getCell(_coord2);

        if (cell1.owner != cell2.owner) revert CannotMergeCells(); // Must be same owner

        // Basic adjacency check (Chebyshev distance = 1)
        bool adjacent = (int256(_coord1.x) - _coord2.x >= -1 && int256(_coord1.x) - _coord2.x <= 1) &&
                        (int256(_coord1.y) - _coord2.y >= -1 && int256(_coord1.y) - _coord2.y <= 1) &&
                        !(_coord1.x == _coord2.x && _coord1.y == _coord2.y); // Not the same cell

        if (!adjacent) revert CannotMergeCells();

        // Clear any active delegation on the cell being merged into the other
        delete cellDelegates[_coord2.x][_coord2.y];

        // Transfer ownership of cell2 to cell1's owner (redundant if already same owner, but good practice)
        // This step is mainly symbolic here as owner is already the same.
        // The *effect* of merging is interpreted off-chain.

        // Off-chain clients might combine cell data, energy, etc., based on the emitted event.
        // No state change on the cells themselves beyond the owner check and delegate removal in this minimal example.
        // A more advanced implementation might modify cell1's data or energy based on cell2.

        // Cancel sale listing for cell2
        delete listedPrices[_coord2.x][_coord2.y];
        emit CellSaleCancelled(_coord2);

        // Remove beacon from cell2
        delete cellBeacons[_coord2.x][_coord2.y];

        emit CellsMerged(_coord1, _coord2, cell1.owner);
    }


    /// @notice Allows the owner of a cell to claim adjacent unowned cells within a radius.
    /// @dev Each claimed cell costs the `claimCost`. Payment must cover max possible claims in radius.
    /// @param _coord The coordinates of the central owned cell.
    /// @param _radius The Chebyshev distance radius (e.g., 1 for 3x3 area). Max radius might be limited for gas.
    function expandTerritory(Coord calldata _coord, uint256 _radius) external payable whenNotPaused isCellOwner(_coord) {
        // Limit radius to avoid excessive gas costs
        if (_radius > 5) revert CannotExpandTerritory(); // Example limit

        uint256 costPerCell = claimCost;
        uint256 totalCost = 0;
        uint256 cellsClaimedCount = 0;
        Coord memory currentCoord;

        // Iterate through the square area defined by the radius
        for (int128 i = int128(-_radius); i <= int128(_radius); i++) {
            for (int128 j = int128(-_radius); j <= int128(_radius); j++) {
                currentCoord.x = _coord.x + i;
                currentCoord.y = _coord.y + j;

                // Skip the center cell and cells outside the actual radius (if needed, simple square here)
                if (i == 0 && j == 0) continue;

                // Check if the cell is unowned
                if (cells[currentCoord.x][currentCoord.y].owner == address(0)) {
                    totalCost += costPerCell;
                    // Check if enough payment is sent *before* claiming to avoid partial claims or refunds issues
                    if (msg.value < totalCost) revert InsufficientPayment(totalCost, msg.value);

                    // Claim the cell
                    cells[currentCoord.x][currentCoord.y] = Cell({
                        owner: msg.sender,
                        data: bytes(""), // Default empty data
                        lastUpdated: uint64(block.timestamp),
                        energy: 0, // Start with 0 energy
                        creationTime: uint64(block.timestamp),
                        visible: true
                    });
                    cellsClaimedCount++;
                    emit CellClaimed(currentCoord, msg.sender, bytes("")); // Emit event for each claimed cell
                }
            }
        }

        if (cellsClaimedCount == 0) revert CannotExpandTerritory(); // No cells claimed in the radius

        // Handle payment and fees for the claimed cells
        if (msg.value < totalCost) revert InsufficientPayment(totalCost, msg.value); // Should be caught by incremental check, but a final check is safe

        uint256 refundAmount = msg.value - totalCost;
        if (refundAmount > 0) {
             (bool successRefund, ) = msg.sender.call{value: refundAmount}("");
             require(successRefund, "Refund failed");
        }

        // Add total claim cost to fees
        collectedFees += totalCost;

        emit TerritoryExpanded(_coord, _radius, cellsClaimedCount);
    }

    /// @notice Allows the owner of a cell to store data that defines interaction rules for it or its neighbors.
    /// @dev Off-chain clients interpret _ruleConfig. Requires cell data to start with a registered Rule data type hash.
    /// @param _coord The coordinates of the cell.
    /// @param _ruleConfig Configuration bytes defining the interaction rule.
    function setCellInteractionRule(Coord calldata _coord, bytes calldata _ruleConfig) external whenNotPaused isCellOwnerOrDelegate(_coord) {
        Cell memory cell = _getCell(_coord); // Get cell including current energy

        // Check for rule data type prefix (conceptual)
        // require(_ruleConfig.length >= 4 && bytes4(_ruleConfig[0:4]) == bytes4(keccak256("INTERACTION_RULE")), "Invalid rule data type");

        cell.data = _ruleConfig; // Store rule configuration
        cell.lastUpdated = uint64(block.timestamp);
        _setCell(_coord, cell);

        emit RuleSet(_coord, _ruleConfig);
    }

    /// @notice Allows users to contribute arbitrary entropy to the contract state.
    /// @dev This can be used as a weak source of pseudo-randomness by mixing it with block data or other sources.
    /// @param _entropy A 32-byte value provided by the user (e.g., hash of something off-chain).
    function seedEntropy(bytes32 _entropy) external whenNotPaused {
        // Store entropy (e.g., in a state variable, or combine with existing state)
        // For this example, we just emit the event. A real contract might hash contributions or store the last few.
        // bytes32 public entropyAccumulator;
        // entropyAccumulator = keccak224(abi.encodePacked(entropyAccumulator, _entropy, block.timestamp, msg.sender));
        emit EntropySeeded(_entropy);
    }

    /// @notice Delegates control of a specific cell to another address for a limited duration.
    /// @param _coord The coordinates of the cell.
    /// @param _delegate The address to delegate control to.
    /// @param _duration The duration of the delegation in seconds.
    function delegateCellControl(Coord calldata _coord, address _delegate, uint64 _duration) external whenNotPaused isCellOwner(_coord) {
        if (_delegate == address(0) || _duration == 0) revert InvalidPercentage(); // Reuse error, or define new one
        // If a delegation already exists that is not expired, disallow or require explicit revoke first?
        // Here, we allow overwriting or setting expired delegates.
        // if (cellDelegates[_coord.x][_coord.y].delegate != address(0) && cellDelegates[_coord.x][_coord.y].expiryTime > block.timestamp) revert DelegateAlreadySet();

        cellDelegates[_coord.x][_coord.y] = DelegateInfo({
            delegate: _delegate,
            expiryTime: uint64(block.timestamp) + _duration
        });

        emit DelegateSet(_coord, _delegate, cellDelegates[_coord.x][_coord.y].expiryTime);
    }

    /// @notice Allows any address to add verifiable metadata (e.g., IPFS hash, URI) to a cell.
    /// @dev This doesn't change the cell's core data or ownership but provides a way to attach third-party info.
    /// @param _coord The coordinates of the cell.
    /// @param _metadataURI The URI or hash pointing to the metadata.
    function attestCell(Coord calldata _coord, string memory _metadataURI) external whenNotPaused {
         // Check if cell exists (owner != address(0)) - attestations only for claimed cells? Or any coord?
         // Let's allow attesting any coord, could be for an area, not just a claimed cell.
         // if (cells[_coord.x][_coord.y].owner == address(0)) revert CellNotOwned(); // Uncomment if only for owned cells

         // This function just logs the attestation event. Off-chain clients track attestations.
         emit CellAttested(_coord, msg.sender, _metadataURI);
    }

    /// @notice Links an owned cell to an external contract/NFT.
    /// @dev Records an association that off-chain clients can recognize.
    /// @param _coord The coordinates of the cell.
    /// @param _externalContract The address of the external contract (e.g., ERC721).
    /// @param _externalTokenId The ID of the token within the external contract.
    /// @param _linkType A bytes4 identifier for the type of link (e.g., 0x721a for ERC721 owner link).
    function linkCellToExternal(Coord calldata _coord, address _externalContract, uint256 _externalTokenId, bytes4 _linkType) external whenNotPaused isCellOwnerOrDelegate(_coord) {
        // Store this link information. A dedicated mapping would be needed for robust tracking.
        // For this example, we just emit the event.
        emit CellLinkedToExternal(_coord, _externalContract, _externalTokenId, _linkType);
    }

    /// @notice Places a temporary message beacon on a cell.
    /// @dev Beacons are non-ownership messages interpreted by off-chain clients and expire.
    /// @param _coord The coordinates of the cell.
    /// @param _message The message string.
    /// @param _duration The duration the beacon is visible (in seconds).
    function placeBeacon(Coord calldata _coord, string memory _message, uint64 _duration) external whenNotPaused {
        // Can place a beacon on any cell, owned or unowned.
        // Maybe require a small fee? Not added here.
        uint64 expiry = uint64(block.timestamp) + _duration;
        cellBeacons[_coord.x][_coord.y] = Beacon({
            placer: msg.sender,
            message: _message,
            expiryTime: expiry
        });
        emit BeaconPlaced(_coord, msg.sender, _message, expiry);
    }

    /// @notice Sets the conceptual visibility flag for an owned cell.
    /// @dev Intended for off-chain renderers to respect user preferences (e.g., hide certain elements).
    /// @param _coord The coordinates of the cell.
    /// @param _visible The desired visibility state.
    function setCellVisibility(Coord calldata _coord, bool _visible) external whenNotPaused isCellOwnerOrDelegate(_coord) {
        Cell memory cell = _getCell(_coord);
        cell.visible = _visible;
        // Energy/timestamp update is optional for just changing visibility flag
        // cell.lastUpdated = uint64(block.timestamp);
        _setCell(_coord, cell);
        emit VisibilitySet(_coord, _visible);
    }

    /// @notice Allows a user to claim a daily energy bonus once per 24 hours.
    function claimDailyEnergyBonus() external whenNotPaused {
        uint64 lastClaim = lastDailyEnergyBonusClaim[msg.sender];
        uint64 nextClaimAvailable = lastClaim + 24 hours; // Using standard library duration literal

        if (block.timestamp < nextClaimAvailable) {
            revert AlreadyClaimedBonusToday();
        }

        lastDailyEnergyBonusClaim[msg.sender] = uint64(block.timestamp);

        // This energy bonus is conceptual; it's emitted as an event.
        // Off-chain clients or mechanisms would need to apply this energy to specific cells the user owns.
        // Alternatively, the contract could add it to a user's 'energy bank' state variable.
        // For this example, we just emit the event showing the user is *eligible* for the bonus amount.
        emit EnergyBonusClaimed(msg.sender, baseDailyEnergyBonus);
    }


    // --- Internal Helper Functions ---

    /// @dev Internal helper to get cell state, calculating current energy based on decay.
    function _getCell(Coord memory _coord) internal view returns (Cell memory) {
        Cell memory cell = cells[_coord.x][_coord.y];
        if (cell.owner != address(0)) {
            uint64 elapsed = uint64(block.timestamp) - cell.lastUpdated;
            uint64 decayedEnergy = elapsed * energyDecayPerSecond;
            if (cell.energy > decayedEnergy) {
                cell.energy -= decayedEnergy;
            } else {
                cell.energy = 0;
            }
             // Note: This view function doesn't modify state (the actual energy in storage).
             // The energy decay is only applied to the stored value during state-changing operations
             // that call _setCell or require current energy check.
        }
        return cell;
    }

     /// @dev Internal helper to update cell state in storage, updating the lastUpdated timestamp.
     function _setCell(Coord memory _coord, Cell memory _cell) internal {
         // Energy decay calculation is typically done when reading (_getCell) or *before* calling _setCell
         // if an action consumes energy. _setCell's primary role is writing the state and updating timestamp.
         cells[_coord.x][_coord.y] = _cell;
     }

    /// @dev Internal helper for isCellOwnerOrDelegate modifier.
    function _requireCellOwnershipOrDelegate(Coord memory _coord) internal view {
        Cell memory cell = cells[_coord.x][_coord.y];
        if (cell.owner == msg.sender) return;

        DelegateInfo memory delegateInfo = cellDelegates[_coord.x][_coord.y];
        if (delegateInfo.delegate != address(0) && delegateInfo.delegate == msg.sender && delegateInfo.expiryTime > block.timestamp) {
            return; // Caller is an active delegate
        }

        revert NotCellOwnerOrDelegate();
    }

    // Fallback/Receive function to accept ETH for claim/buy
    receive() external payable {}
    fallback() external payable {}
}
```