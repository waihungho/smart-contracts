Okay, here is a Solidity smart contract incorporating several advanced, creative, and less commonly duplicated concepts. It models a "Dimensional Canvas" – a persistent, multi-dimensional digital space where users can claim ownership of individual "cells" or larger "regions", modify cell data, stake Ether to influence state dynamics (like decay), and manage access within regions.

Key advanced concepts include:
1.  **Multi-Dimensional State:** Representing a 3D space (X, Y, Z).
2.  **Layered Ownership/Management:** Duality of individual cell ownership vs. regional management rights.
3.  **Calculated/Dynamic State:** Cell data can conceptually "decay" over time, influenced by staking, with a function to apply this decay physically.
4.  **Staking for State Influence:** Ether staked on cells or regions affects their decay rate.
5.  **Role-Based Access Control within Regions:** Region owners can grant specific management rights.
6.  **On-Chain Persistent World:** Creating a mutable digital environment managed by the contract.

This is not a standard token, DeFi protocol, or simple NFT art contract. It focuses on persistent, interactive state management in a spatial context.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title DimensionalCanvas
 * @dev A smart contract representing a persistent, multi-dimensional digital canvas (X, Y, Z).
 * Users can claim ownership of individual cells or manage defined regions.
 * Cell data can be modified by owners/managers and is subject to decay, influenced by staked Ether.
 */

// --- OUTLINE ---
// 1. State Variables: Canvas dimensions, cell/region data, ownership, staking, prices, decay parameters, admin, paused state.
// 2. Structs: Region definition.
// 3. Events: Tracking key actions (claim, modify, transfer, stake, region events, admin actions).
// 4. Modifiers: Ownership, Pausability, Region Management.
// 5. Helper Functions (Internal/Public View): Calculate cell index, calculate decay factor.
// 6. Admin Functions: Setup, price setting, withdrawal, pause, admin transfer, define regions.
// 7. Cell Interaction Functions: Claim, modify, transfer, stake, withdraw stake, apply decay.
// 8. Region Interaction Functions: Claim predefined regions, transfer region ownership, add/remove managers, stake, withdraw stake.
// 9. View Functions: Get cell/region info, get dimensions, prices, etc.

// --- FUNCTION SUMMARY ---
// Admin & Setup:
// 1.  constructor(uint16 _width, uint16 _height, uint16 _depth, uint256 _initialCellClaimPrice, uint256 _initialRegionClaimPrice, uint256 _initialDecayRate): Initializes the canvas dimensions, prices, decay, and admin.
// 2.  setCellClaimPrice(uint256 _price): Sets the price to claim an individual cell.
// 3.  setRegionClaimPrice(uint256 _price): Sets the price to claim a predefined region.
// 4.  setDecayRate(uint256 _rate): Sets the base decay rate applied to cell data.
// 5.  defineRegionBounds(uint256 _regionId, uint16 x1, uint16 y1, uint16 x2, uint16 y2, uint16 z): Defines the spatial boundaries for a specific region ID.
// 6.  withdrawFees(): Allows the admin to withdraw collected Ether fees.
// 7.  pauseContract(): Pauses core contract interactions (claiming, modifying, staking).
// 8.  unpauseContract(): Unpauses the contract.
// 9.  transferAdminOwnership(address _newAdmin): Transfers admin rights.

// Cell Interaction:
// 10. getCellIndex(uint16 x, uint16 y, uint16 z): Calculates the flat index for a 3D coordinate. Public helper view.
// 11. claimCell(uint16 x, uint16 y, uint16 z): Claims ownership of an individual cell, payable.
// 12. modifyCell(uint16 x, uint16 y, uint16 z, bytes32 _data): Modifies the data of a cell if caller is owner or a region manager.
// 13. transferCellOwnership(uint16 x, uint16 y, uint16 z, address _newOwner): Transfers ownership of a cell to another address.
// 14. stakeEtherOnCell(uint16 x, uint16 y, uint16 z): Stakes Ether on a specific cell to reduce its decay rate. Payable.
// 15. withdrawStakedEtherFromCell(uint16 x, uint16 y, uint16 z, uint256 amount): Allows a staker to withdraw their staked Ether from a cell.
// 16. applyDecayToCell(uint16 x, uint16 y, uint16 z): Applies the decay logic to a cell's stored data based on time and stake.

// Region Interaction:
// 17. claimPredefinedRegion(uint256 _regionId): Claims ownership/management rights over a predefined region, payable.
// 18. transferRegionOwnership(uint256 _regionId, address _newOwner): Transfers ownership of a region.
// 19. addRegionManager(uint256 _regionId, address _manager): Grants region management rights to an address for a specific region.
// 20. removeRegionManager(uint256 _regionId, address _manager): Revokes region management rights.
// 21. stakeEtherOnRegion(uint256 _regionId): Stakes Ether on a specific region to reduce decay for cells within it. Payable.
// 22. withdrawStakedEtherFromRegion(uint256 _regionId, uint256 amount): Allows a staker to withdraw their staked Ether from a region.

// View & Info:
// 23. getCanvasDimensions(): Returns the width, height, and depth of the canvas.
// 24. getCellData(uint16 x, uint16 y, uint16 z): Returns the raw stored data for a cell (before decay calculation).
// 25. getCellOwner(uint16 x, uint16 y, uint16 z): Returns the owner address of a cell.
// 26. getStakedEtherOnCell(uint16 x, uint16 y, uint16 z): Returns the total staked Ether on a cell.
// 27. getCalculatedCellData(uint16 x, uint16 y, uint16 z): Returns the cell data after applying conceptual decay based on time and stake.
// 28. getRegionOwner(uint256 _regionId): Returns the owner address of a region.
// 29. getRegionBounds(uint256 _regionId): Returns the spatial boundaries of a region.
// 30. isRegionManager(uint256 _regionId, address _manager): Checks if an address is a manager for a region.
// 31. getStakedEtherOnRegion(uint256 _regionId): Returns the total staked Ether on a region.
// 32. getTotalRegionsDefined(): Returns the total number of regions defined by the admin.
// 33. getRegionIdByIndexDefined(uint256 index): Returns the ID of a defined region by its index (0 to TotalRegionsDefined-1).
// 34. getRegionIdAt(uint16 x, uint16 y, uint16 z): Returns the ID of the region containing the cell (x, y, z), or 0 if none. (Note: assumes non-overlapping regions or returns first match).
// 35. getCellLastModificationTime(uint16 x, uint16 y, uint16 z): Returns the timestamp of the last modification for a cell.

contract DimensionalCanvas {

    // --- State Variables ---

    address public admin;
    bool public paused;

    uint16 public immutable canvasWidth;
    uint16 public immutable canvasHeight;
    uint16 public immutable canvasDepth;

    // Cell State
    mapping(uint256 => bytes32) private cellsData; // Use flat index: x + y*width + z*width*height
    mapping(uint256 => address) private cellOwners;
    mapping(uint256 => uint256) private stakedCellEther; // Ether staked per cell
    mapping(uint256 => uint256) private cellLastModificationTime; // Timestamp of last data change

    // Region State
    struct Region {
        uint16 x1;
        uint16 y1;
        uint16 x2;
        uint16 y2;
        uint16 z; // Regions are defined on a single Z layer for simplicity
        address owner;
        mapping(address => bool) managers;
        uint256 stakedEther;
    }
    mapping(uint256 => Region) private regions; // regionId => Region struct
    uint256 private nextRegionId = 1; // Start region IDs from 1

    // Store defined region IDs to iterate through them (careful with gas)
    uint256[] private definedRegionIds;
    mapping(uint256 => bool) private regionIdExists; // Check if an ID has been defined

    // Prices & Fees
    uint256 public cellClaimPrice;
    uint256 public regionClaimPrice; // Price to claim management of a defined region
    uint256 private totalCollectedFees;

    // Decay Parameters (Adjustable by Admin)
    uint256 public decayRate; // Units per second (e.g., 1 meaning 1 byte32 unit per second, scaled down)
    uint256 private constant STAKE_INFLUENCE_FACTOR = 1 ether; // 1 Ether stake cancels decay for X seconds/units

    // --- Events ---

    event CellClaimed(uint16 indexed x, uint16 indexed y, uint16 indexed z, address indexed owner, uint256 pricePaid);
    event CellModified(uint16 indexed x, uint16 indexed y, uint16 indexed z, address indexed modifier, bytes32 newData);
    event CellOwnershipTransferred(uint16 indexed x, uint16 indexed y, uint16 indexed z, address indexed oldOwner, address indexed newOwner);
    event CellEtherStaked(uint16 indexed x, uint16 indexed y, uint16 indexed z, address indexed staker, uint256 amount);
    event CellStakeWithdrawn(uint16 indexed x, uint16 indexed y, uint16 indexed z, address indexed staker, uint256 amount);
    event CellDecayApplied(uint16 indexed x, uint16 indexed y, uint16 indexed z, bytes32 finalData);

    event RegionDefined(uint256 indexed regionId, uint16 x1, uint16 y1, uint16 x2, uint16 y2, uint16 z, address indexed admin);
    event RegionClaimed(uint256 indexed regionId, address indexed owner, uint256 pricePaid);
    event RegionOwnershipTransferred(uint256 indexed regionId, address indexed oldOwner, address indexed newOwner);
    event RegionManagerAdded(uint256 indexed regionId, address indexed manager, address indexed owner);
    event RegionManagerRemoved(uint256 indexed regionId, address indexed manager, address indexed owner);
    event RegionEtherStaked(uint256 indexed regionId, address indexed staker, uint256 amount);
    event RegionStakeWithdrawn(uint256 indexed regionId, address indexed staker, uint256 amount);

    event FeesWithdrawn(address indexed admin, uint256 amount);
    event ContractPaused(address indexed admin);
    event ContractUnpaused(address indexed admin);
    event AdminOwnershipTransferred(address indexed previousAdmin, address indexed newAdmin);
    event PriceUpdated(string indexed item, uint256 newPrice);
    event DecayRateUpdated(uint256 newRate);

    // --- Modifiers ---

    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can call this function");
        _;
    }

    modifier whenNotPaused() {
        require(!paused, "Contract is paused");
        _;
    }

    modifier whenPaused() {
        require(paused, "Contract is not paused");
        _;
    }

    modifier onlyCellOwnerOrRegionManager(uint16 x, uint16 y, uint16 z) {
        uint256 cellIdx = getCellIndex(x, y, z);
        address cellOwner = cellOwners[cellIdx];
        bool isOwner = msg.sender == cellOwner;

        uint256 regionId = getRegionIdAt(x, y, z);
        bool isManager = false;
        if (regionId != 0) {
            isManager = regions[regionId].managers[msg.sender];
        }

        require(isOwner || isManager, "Only cell owner or region manager can modify");
        _;
    }

    modifier onlyRegionOwner(uint256 _regionId) {
        require(regions[_regionId].owner != address(0), "Region does not exist or is not claimed");
        require(regions[_regionId].owner == msg.sender, "Only region owner can call this function");
        _;
    }

    // --- Helper Functions (Public View) ---

    /**
     * @dev Calculates the flat index for a given 3D coordinate (x, y, z).
     * @param x The x-coordinate (0 to canvasWidth-1).
     * @param y The y-coordinate (0 to canvasHeight-1).
     * @param z The z-coordinate (0 to canvasDepth-1).
     * @return The flat index representing the cell's position in storage.
     */
    function getCellIndex(uint16 x, uint16 y, uint16 z) public view returns (uint256) {
        require(x < canvasWidth, "X coordinate out of bounds");
        require(y < canvasHeight, "Y coordinate out of bounds");
        require(z < canvasDepth, "Z coordinate out of bounds");
        return uint256(x) + uint256(y) * canvasWidth + uint256(z) * canvasWidth * canvasHeight;
    }

    /**
     * @dev Calculates the effective decay factor for a cell based on time and staked ether.
     * Internal helper. Higher factor means less decay.
     * @param cellIdx The flat index of the cell.
     * @return A multiplier (scaled by 1e18) where 1e18 means no decay influence, lower means more.
     */
    function _calculateDecayFactor(uint256 cellIdx) internal view returns (uint256) {
        uint256 currentTime = block.timestamp;
        uint256 lastModTime = cellLastModificationTime[cellIdx];
        uint256 timePassed = (currentTime > lastModTime) ? (currentTime - lastModTime) : 0;

        // Decay is linear with time passed
        uint256 effectiveDecayAmount = timePassed * decayRate;

        // Staked Ether reduces effective decay time
        uint256 totalStake = stakedCellEther[cellIdx];
        uint256 regionId = getRegionIdAt(uint16(cellIdx % canvasWidth), uint16((cellIdx / canvasWidth) % canvasHeight), uint16(cellIdx / (canvasWidth * canvasHeight))); // Reverse index calculation
        if (regionId != 0) {
             totalStake += regions[regionId].stakedEther; // Region stake also contributes
        }

        // Stake cancels out decay based on STAKE_INFLUENCE_FACTOR
        // Example: 1 ether cancels X units of decay amount
        uint256 decayCancelledByStake = (totalStake * STAKE_INFLUENCE_FACTOR) / 1 ether;

        // Effective decay is reduced by stake
        uint256 netDecayAmount = (effectiveDecayAmount > decayCancelledByStake) ? (effectiveDecayAmount - decayCancelledByStake) : 0;

        // Max possible decay amount for a bytes32 is large. Let's cap netDecayAmount conceptually
        // or simplify: Stake reduces decay RATE for that cell.
        // Let's simplify: Stake *directly* reduces the decay RATE for that cell over time.
        // Effective Decay Rate = Base Decay Rate * (MaxStakeInfluenceFactor - CurrentStakeInfluence) / MaxStakeInfluenceFactor
        // Simpler: Stake directly subtracts from the DECAY RATE.
        // Effective Rate = max(0, baseRate - stake * factor)
        // Decay Amount = Time * Effective Rate

        uint256 effectiveRate = decayRate;
        if (totalStake > 0) {
             // A simple inverse relationship: Stake reduces decay rate linearly.
             // Example: 1 Ether might halve the rate, 2 Ether cancels it.
             // This needs tuning based on STAKE_INFLUENCE_FACTOR and decayRate units.
             // Let's use a different model: Stake provides "decay resistance".
             // Decay reduction = (totalStake * RESISTANCE_FACTOR)
             // Effective Decay Amount = max(0, timePassed * decayRate - (totalStake * STAKE_INFLUENCE_FACTOR / 1 ether))
             // Okay, let's go back to the first idea but clarify: STAKE_INFLUENCE_FACTOR means 1 ether provides 1 second of decay resistance *at the base decay rate*.
             // Effective time subject to decay = max(0, timePassed - (totalStake * STAKE_INFLUENCE_FACTOR / decayRate)) -> Careful if decayRate is 0!
             // Let's make STAKE_INFLUENCE_FACTOR mean 1 ether reduces the effective decay *rate* by X.
             // Effective Rate = max(0, decayRate - (totalStake * STAKE_RATE_REDUCTION_FACTOR / 1 ether))

             // Let's try a simpler approach: Stake *delays* decay. 1 Ether delays by Y seconds.
             // Time subject to decay = max(0, timePassed - (totalStake * DELAY_PER_ETHER))
             // Let's make STAKE_INFLUENCE_FACTOR mean 1 ether delays decay by that many seconds.
             uint256 delaySeconds = (totalStake * STAKE_INFLUENCE_FACTOR) / 1 ether;
             uint256 effectiveTimePassed = (timePassed > delaySeconds) ? (timePassed - delaySeconds) : 0;
             netDecayAmount = effectiveTimePassed * decayRate; // Decay is amount per second
        } else {
             netDecayAmount = timePassed * decayRate;
        }

        // Conceptually, this is the total amount of "decay" accumulated.
        // The `getCalculatedCellData` will use this to derive the displayed data.
        // `applyDecayToCell` will use this to update the stored data.
        // For now, just return a representation of decay amount.
        // Let's make decay amount per second simple: decayRate is units/second.
        // Total conceptual decay = timePassed * decayRate.
        // Staked Ether provides `totalStake * STAKE_INFLUENCE_FACTOR` units of resistance.
        // Effective Decay = max(0, timePassed * decayRate - totalStake * STAKE_INFLUENCE_FACTOR).
        uint256 resistance = (totalStake * STAKE_INFLUENCE_FACTOR) / 1 ether; // Convert stake to resistance units
        uint256 totalConceptualDecayAmount = timePassed * decayRate;
        uint256 netConceptualDecayAmount = (totalConceptualDecayAmount > resistance) ? (totalConceptualDecayAmount - resistance) : 0;

        // This function should calculate the *factor* applied to the data.
        // Let's say data decays towards bytes32(0). DecayFactor is 1 (no decay) down to 0 (full decay).
        // DecayAmount (as calculated above) needs to be scaled relative to the maximum possible decay (time since epoch * max_rate?)
        // A simpler decay model: Data decays linearly towards 0 over T time if no stake. Stake increases T.
        // DecayFactor = max(0, 1 - timePassed / EffectiveDecayTime)
        // EffectiveDecayTime = BaseDecayTime + Stake * StakeBonusTime
        // Let's set decayRate as UnitsPerSecond, and STAKE_INFLUENCE_FACTOR as ResistanceUnitsPerEtherStake.
        // Total Decay Units = timePassed * decayRate
        // Total Resistance Units = totalStake * STAKE_INFLUENCE_FACTOR / 1 ether
        // Net Decay Units = max(0, Total Decay Units - Total Resistance Units)
        // This net decay units *directly subtracts* from the bytes32 value (interpreted as an integer).
        return netConceptualDecayAmount; // Returning the net decay amount conceptually
    }


    /**
     * @dev Returns the calculated cell data after applying conceptual decay.
     * This function is VIEW and does not change state.
     * @param x The x-coordinate (0 to canvasWidth-1).
     * @param y The y-coordinate (0 to canvasHeight-1).
     * @param z The z-coordinate (0 to canvasDepth-1).
     * @return The bytes32 data after applying decay.
     */
    function getCalculatedCellData(uint16 x, uint16 y, uint16 z) public view returns (bytes32) {
        uint256 cellIdx = getCellIndex(x, y, z);
        bytes32 rawData = cellsData[cellIdx];
        if (rawData == bytes32(0)) {
            return bytes32(0); // No decay applies if data is already zero
        }

        uint256 decayAmount = _calculateDecayFactor(cellIdx); // This is the amount to subtract

        // Convert bytes32 to uint256 for arithmetic
        uint256 rawDataUint;
        assembly {
            rawDataUint := mload(add(rawData, 32)) // Load bytes32 as uint256
        }

        // Subtract decay amount, ensuring it doesn't go below zero
        uint256 decayedDataUint = (rawDataUint > decayAmount) ? (rawDataUint - decayAmount) : 0;

        // Convert back to bytes32
        bytes32 decayedData;
        assembly {
            mstore(add(decayedData, 32), decayedDataUint) // Store uint256 as bytes32
        }

        return decayedData;
    }

    /**
     * @dev Gets the ID of the region that contains the given cell coordinates.
     * Assumes regions do not overlap. Returns 0 if no region contains the cell.
     * Note: Iterates through defined regions. Can be gas-intensive if many regions.
     * @param x The x-coordinate.
     * @param y The y-coordinate.
     * @param z The z-coordinate.
     * @return The region ID, or 0 if not in any claimed region.
     */
    function getRegionIdAt(uint16 x, uint16 y, uint16 z) public view returns (uint256) {
        for (uint256 i = 0; i < definedRegionIds.length; i++) {
            uint256 regionId = definedRegionIds[i];
            Region storage r = regions[regionId];
            // Check if region exists, is claimed (has owner), and coordinates are within bounds
            if (r.owner != address(0) && z == r.z &&
                x >= r.x1 && x <= r.x2 &&
                y >= r.y1 && y <= r.y2) {
                return regionId;
            }
        }
        return 0; // Not found in any claimed region
    }

    // --- Constructor ---

    constructor(
        uint16 _width,
        uint16 _height,
        uint16 _depth,
        uint256 _initialCellClaimPrice,
        uint256 _initialRegionClaimPrice,
        uint256 _initialDecayRate // Units per second, e.g., 1e12 for slow decay of bytes32
    ) {
        require(_width > 0 && _height > 0 && _depth > 0, "Dimensions must be positive");
        admin = msg.sender;
        canvasWidth = _width;
        canvasHeight = _height;
        canvasDepth = _depth;
        cellClaimPrice = _initialCellClaimPrice;
        regionClaimPrice = _initialRegionClaimPrice;
        decayRate = _initialDecayRate; // e.g., 1, meaning decay reduces value by 1 unit per second
    }

    // --- Admin Functions ---

    /**
     * @dev Sets the price required to claim ownership of an individual cell.
     * @param _price The new cell claim price in wei.
     */
    function setCellClaimPrice(uint256 _price) public onlyAdmin {
        cellClaimPrice = _price;
        emit PriceUpdated("CellClaim", _price);
    }

    /**
     * @dev Sets the price required to claim management rights over a defined region.
     * @param _price The new region claim price in wei.
     */
    function setRegionClaimPrice(uint256 _price) public onlyAdmin {
        regionClaimPrice = _price;
        emit PriceUpdated("RegionClaim", _price);
    }

    /**
     * @dev Sets the base decay rate for cell data.
     * @param _rate The new decay rate (units per second).
     */
    function setDecayRate(uint256 _rate) public onlyAdmin {
        decayRate = _rate;
        emit DecayRateUpdated(_rate);
    }

    /**
     * @dev Defines the spatial boundaries for a region ID. Can only be set once per ID.
     * Region IDs are managed incrementally by the contract for simplicity.
     * @param x1 The minimum x-coordinate (inclusive).
     * @param y1 The minimum y-coordinate (inclusive).
     * @param x2 The maximum x-coordinate (inclusive).
     * @param y2 The maximum y-coordinate (inclusive).
     * @param z The z-coordinate layer for the region.
     */
    function defineRegionBounds(uint16 x1, uint16 y1, uint16 x2, uint16 y2, uint16 z) public onlyAdmin {
        require(x1 <= x2 && y1 <= y2, "Invalid region bounds");
        require(getCellIndex(x1, y1, z) <= getCellIndex(x2, y2, z), "Region bounds out of canvas limits"); // Implicit bounds check
        // Note: This function *defines* the region area, it does not claim it.
        // Claiming happens via claimPredefinedRegion.
        uint256 regionId = nextRegionId++;
        definedRegionIds.push(regionId);
        regionIdExists[regionId] = true;

        regions[regionId].x1 = x1;
        regions[regionId].y1 = y1;
        regions[regionId].x2 = x2;
        regions[regionId].y2 = y2;
        regions[regionId].z = z;
        // Owner remains address(0) until claimed

        emit RegionDefined(regionId, x1, y1, x2, y2, z, msg.sender);
    }


    /**
     * @dev Allows the admin to withdraw accumulated fees.
     */
    function withdrawFees() public onlyAdmin {
        uint256 amount = totalCollectedFees;
        require(amount > 0, "No fees to withdraw");
        totalCollectedFees = 0;
        payable(admin).transfer(amount);
        emit FeesWithdrawn(admin, amount);
    }

    /**
     * @dev Pauses core contract interactions (claiming, modifying, staking).
     */
    function pauseContract() public onlyAdmin whenNotPaused {
        paused = true;
        emit ContractPaused(msg.sender);
    }

    /**
     * @dev Unpauses the contract.
     */
    function unpauseContract() public onlyAdmin whenPaused {
        paused = false;
        emit ContractUnpaused(msg.sender);
    }

    /**
     * @dev Transfers admin ownership to a new address.
     * @param _newAdmin The address of the new admin.
     */
    function transferAdminOwnership(address _newAdmin) public onlyAdmin {
        require(_newAdmin != address(0), "New admin cannot be the zero address");
        address previousAdmin = admin;
        admin = _newAdmin;
        emit AdminOwnershipTransferred(previousAdmin, _newAdmin);
    }

    // --- Cell Interaction Functions ---

    /**
     * @dev Claims ownership of an individual cell.
     * Requires payment equal to the current cellClaimPrice.
     * @param x The x-coordinate.
     * @param y The y-coordinate.
     * @param z The z-coordinate.
     */
    function claimCell(uint16 x, uint16 y, uint16 z) public payable whenNotPaused {
        uint256 cellIdx = getCellIndex(x, y, z);
        require(cellOwners[cellIdx] == address(0), "Cell is already claimed");
        require(msg.value >= cellClaimPrice, "Insufficient Ether to claim cell");

        cellOwners[cellIdx] = msg.sender;
        cellLastModificationTime[cellIdx] = block.timestamp; // Set initial modification time
        totalCollectedFees += msg.value;

        emit CellClaimed(x, y, z, msg.sender, msg.value);
    }

    /**
     * @dev Modifies the data stored in a cell.
     * Requires caller to be the cell owner or a manager of a region containing the cell.
     * Updates the last modification time for decay calculation.
     * @param x The x-coordinate.
     * @param y The y-coordinate.
     * @param z The z-coordinate.
     * @param _data The new bytes32 data to store.
     */
    function modifyCell(uint16 x, uint16 y, uint16 z, bytes32 _data) public whenNotPaused onlyCellOwnerOrRegionManager(x, y, z) {
        uint256 cellIdx = getCellIndex(x, y, z);
        cellsData[cellIdx] = _data;
        cellLastModificationTime[cellIdx] = block.timestamp; // Reset modification time
        emit CellModified(x, y, z, msg.sender, _data);
    }

    /**
     * @dev Transfers ownership of a claimed cell to a new address.
     * Requires caller to be the current cell owner.
     * @param x The x-coordinate.
     * @param y The y-coordinate.
     * @param z The z-coordinate.
     * @param _newOwner The address to transfer ownership to.
     */
    function transferCellOwnership(uint16 x, uint16 y, uint16 z, address _newOwner) public whenNotPaused {
        uint256 cellIdx = getCellIndex(x, y, z);
        require(cellOwners[cellIdx] == msg.sender, "Only cell owner can transfer ownership");
        require(_newOwner != address(0), "New owner cannot be the zero address");
        require(_newOwner != cellOwners[cellIdx], "Cannot transfer to current owner");

        address oldOwner = cellOwners[cellIdx];
        cellOwners[cellIdx] = _newOwner;
        // Note: Staked ether is NOT transferred, it remains linked to the original staker address for this cell.
        // Transferring ownership doesn't affect modification time or data.

        emit CellOwnershipTransferred(x, y, z, oldOwner, _newOwner);
    }

    /**
     * @dev Stakes Ether on a specific cell. Staked Ether helps reduce decay.
     * Any address can stake on any cell (claimed or unclaimed).
     * Staking is recorded per cell index and per staker address (not per owner).
     * Mapping `stakedCellEther` stores total per cell. Need another mapping for staker amounts.
     * Let's store total per cell for simplicity in decay calc. User withdrawal requires tracking per staker.
     * Okay, let's add `mapping(uint256 => mapping(address => uint256)) private stakerCellEther;`
     * @param x The x-coordinate.
     * @param y The y-coordinate.
     * @param z The z-coordinate.
     */
    mapping(uint256 => mapping(address => uint256)) private stakerCellEther; // cellIdx => staker => amount

    function stakeEtherOnCell(uint16 x, uint16 y, uint16 z) public payable whenNotPaused {
        require(msg.value > 0, "Must stake a positive amount");
        uint256 cellIdx = getCellIndex(x, y, z);

        stakerCellEther[cellIdx][msg.sender] += msg.value;
        stakedCellEther[cellIdx] += msg.value;

        emit CellEtherStaked(x, y, z, msg.sender, msg.value);
    }

    /**
     * @dev Allows a staker to withdraw their staked Ether from a cell.
     * @param x The x-coordinate.
     * @param y The y-coordinate.
     * @param z The z-coordinate.
     * @param amount The amount of Ether to withdraw.
     */
    function withdrawStakedEtherFromCell(uint16 x, uint16 y, uint16 z, uint256 amount) public whenNotPaused {
        uint256 cellIdx = getCellIndex(x, y, z);
        require(stakerCellEther[cellIdx][msg.sender] >= amount, "Insufficient staked Ether");

        stakerCellEther[cellIdx][msg.sender] -= amount;
        stakedCellEther[cellIdx] -= amount;

        payable(msg.sender).transfer(amount);
        emit CellStakeWithdrawn(x, y, z, msg.sender, amount);
    }

    /**
     * @dev Applies the decay process to a cell's stored data.
     * Calculates the decay amount since the last modification (or last decay application)
     * and subtracts it from the stored data, then updates the last modification time.
     * Callable by anyone, potentially incentivized off-chain.
     * @param x The x-coordinate.
     * @param y The y-coordinate.
     * @param z The z-coordinate.
     */
    function applyDecayToCell(uint16 x, uint16 y, uint16 z) public whenNotPaused {
        uint256 cellIdx = getCellIndex(x, y, z);
        bytes32 currentData = cellsData[cellIdx];
        if (currentData == bytes32(0)) {
            // Already fully decayed or never set
            cellLastModificationTime[cellIdx] = block.timestamp; // Still update time to reflect check
            return;
        }

        uint256 decayAmount = _calculateDecayFactor(cellIdx); // This is the net amount to subtract

        if (decayAmount == 0) {
             cellLastModificationTime[cellIdx] = block.timestamp; // Update time as if decay was applied (0)
             return; // No effective decay occurred
        }

        // Convert bytes32 to uint256 for arithmetic
        uint256 currentDataUint;
        assembly {
            currentDataUint := mload(add(currentData, 32))
        }

        // Subtract decay amount, ensuring it doesn't go below zero
        uint256 decayedDataUint = (currentDataUint > decayAmount) ? (currentDataUint - decayAmount) : 0;

        // Convert back to bytes32
        bytes32 decayedData;
        assembly {
            mstore(add(decayedData, 32), decayedDataUint)
        }

        cellsData[cellIdx] = decayedData;
        cellLastModificationTime[cellIdx] = block.timestamp; // Update last modification time

        emit CellDecayApplied(x, y, z, decayedData);
    }


    // --- Region Interaction Functions ---

    /**
     * @dev Claims ownership/management rights over a predefined region.
     * Requires the region ID to be defined by the admin and not already claimed.
     * Requires payment equal to the current regionClaimPrice.
     * @param _regionId The ID of the region to claim.
     */
    function claimPredefinedRegion(uint256 _regionId) public payable whenNotPaused {
        require(regionIdExists[_regionId], "Region ID is not defined");
        require(regions[_regionId].owner == address(0), "Region is already claimed");
        require(msg.value >= regionClaimPrice, "Insufficient Ether to claim region");

        regions[_regionId].owner = msg.sender;
        totalCollectedFees += msg.value;

        emit RegionClaimed(_regionId, msg.sender, msg.value);
    }

    /**
     * @dev Transfers ownership of a claimed region to a new address.
     * Requires caller to be the current region owner.
     * @param _regionId The ID of the region.
     * @param _newOwner The address to transfer ownership to.
     */
    function transferRegionOwnership(uint256 _regionId, address _newOwner) public whenNotPaused onlyRegionOwner(_regionId) {
        require(_newOwner != address(0), "New owner cannot be the zero address");
        require(_newOwner != regions[_regionId].owner, "Cannot transfer to current owner");

        address oldOwner = regions[_regionId].owner;
        regions[_regionId].owner = _newOwner;
        // Managers are kept. Staked ether is kept.

        emit RegionOwnershipTransferred(_regionId, oldOwner, _newOwner);
    }

    /**
     * @dev Grants region management rights to an address.
     * Managers can modify cells within the region.
     * Requires caller to be the region owner.
     * @param _regionId The ID of the region.
     * @param _manager The address to grant management rights to.
     */
    function addRegionManager(uint256 _regionId, address _manager) public whenNotPaused onlyRegionOwner(_regionId) {
        require(_manager != address(0), "Manager address cannot be zero");
        regions[_regionId].managers[_manager] = true;
        emit RegionManagerAdded(_regionId, _manager, msg.sender);
    }

    /**
     * @dev Revokes region management rights from an address.
     * Requires caller to be the region owner.
     * @param _regionId The ID of the region.
     * @param _manager The address to revoke management rights from.
     */
    function removeRegionManager(uint256 _regionId, address _manager) public whenNotPaused onlyRegionOwner(_regionId) {
        regions[_regionId].managers[_manager] = false;
        emit RegionManagerRemoved(_regionId, _manager, msg.sender);
    }

    /**
     * @dev Stakes Ether on a specific region. Staked Ether on a region contributes
     * to reducing decay for *all* cells within that region.
     * Any address can stake on any claimed region.
     * @param _regionId The ID of the region.
     */
    mapping(uint256 => mapping(address => uint256)) private stakerRegionEther; // regionId => staker => amount

    function stakeEtherOnRegion(uint256 _regionId) public payable whenNotPaused {
        require(msg.value > 0, "Must stake a positive amount");
        require(regions[_regionId].owner != address(0), "Region is not claimed");

        stakerRegionEther[_regionId][msg.sender] += msg.value;
        regions[_regionId].stakedEther += msg.value;

        emit RegionEtherStaked(_regionId, msg.sender, msg.value);
    }

    /**
     * @dev Allows a staker to withdraw their staked Ether from a region.
     * @param _regionId The ID of the region.
     * @param amount The amount of Ether to withdraw.
     */
    function withdrawStakedEtherFromRegion(uint256 _regionId, uint256 amount) public whenNotPaused {
        require(regions[_regionId].owner != address(0), "Region is not claimed");
        require(stakerRegionEther[_regionId][msg.sender] >= amount, "Insufficient staked Ether");

        stakerRegionEther[_regionId][msg.sender] -= amount;
        regions[_regionId].stakedEther -= amount;

        payable(msg.sender).transfer(amount);
        emit RegionStakeWithdrawn(_regionId, msg.sender, amount);
    }


    // --- View & Info Functions ---

    /**
     * @dev Returns the dimensions of the canvas.
     * @return width, height, depth.
     */
    function getCanvasDimensions() public view returns (uint16 width, uint16 height, uint16 depth) {
        return (canvasWidth, canvasHeight, canvasDepth);
    }

    /**
     * @dev Returns the raw stored data for a cell (before conceptual decay is applied).
     * @param x The x-coordinate.
     * @param y The y-coordinate.
     * @param z The z-coordinate.
     * @return The raw bytes32 data.
     */
    function getCellData(uint16 x, uint16 y, uint16 z) public view returns (bytes32) {
        uint256 cellIdx = getCellIndex(x, y, z);
        return cellsData[cellIdx];
    }

    /**
     * @dev Returns the address that owns the specified cell.
     * Returns the zero address if the cell is unclaimed.
     * @param x The x-coordinate.
     * @param y The y-coordinate.
     * @param z The z-coordinate.
     * @return The owner address.
     */
    function getCellOwner(uint16 x, uint16 y, uint16 z) public view returns (address) {
        uint256 cellIdx = getCellIndex(x, y, z);
        return cellOwners[cellIdx];
    }

    /**
     * @dev Returns the total amount of Ether staked directly on a specific cell.
     * Does NOT include region stake contribution.
     * @param x The x-coordinate.
     * @param y The y-coordinate.
     * @param z The z-coordinate.
     * @return The total staked Ether amount in wei.
     */
    function getStakedEtherOnCell(uint16 x, uint16 y, uint16 z) public view returns (uint256) {
        uint256 cellIdx = getCellIndex(x, y, z);
        return stakedCellEther[cellIdx];
    }

     /**
     * @dev Returns the timestamp of the last modification for a cell.
     * Used in decay calculation.
     * @param x The x-coordinate.
     * @param y The y-coordinate.
     * @param z The z-coordinate.
     * @return The timestamp in seconds since epoch.
     */
    function getCellLastModificationTime(uint16 x, uint16 y, uint16 z) public view returns (uint256) {
        uint256 cellIdx = getCellIndex(x, y, z);
        return cellLastModificationTime[cellIdx];
    }


    /**
     * @dev Returns the address that owns the specified region.
     * Returns the zero address if the region is not defined or not claimed.
     * @param _regionId The ID of the region.
     * @return The owner address.
     */
    function getRegionOwner(uint256 _regionId) public view returns (address) {
        if (!regionIdExists[_regionId]) return address(0); // Region not defined
        return regions[_regionId].owner;
    }

    /**
     * @dev Returns the spatial boundaries of a defined region.
     * @param _regionId The ID of the region.
     * @return x1, y1, x2, y2, z coordinates of the region bounds. Returns 0s if region ID is not defined.
     */
    function getRegionBounds(uint256 _regionId) public view returns (uint16 x1, uint16 y1, uint16 x2, uint16 y2, uint16 z) {
        if (!regionIdExists[_regionId]) return (0, 0, 0, 0, 0);
        Region storage r = regions[_regionId];
        return (r.x1, r.y1, r.x2, r.y2, r.z);
    }

    /**
     * @dev Checks if an address is a manager for a specified region.
     * @param _regionId The ID of the region.
     * @param _manager The address to check.
     * @return True if the address is a manager, false otherwise or if region not defined/claimed.
     */
    function isRegionManager(uint256 _regionId, address _manager) public view returns (bool) {
        if (!regionIdExists[_regionId] || regions[_regionId].owner == address(0)) return false; // Region not defined or not claimed
        return regions[_regionId].managers[_manager];
    }

    /**
     * @dev Returns the total amount of Ether staked on a specific region.
     * Does NOT include individual cell stake within the region.
     * @param _regionId The ID of the region.
     * @return The total staked Ether amount in wei. Returns 0 if region not defined/claimed.
     */
    function getStakedEtherOnRegion(uint256 _regionId) public view returns (uint256) {
        if (!regionIdExists[_regionId] || regions[_regionId].owner == address(0)) return 0; // Region not defined or not claimed
        return regions[_regionId].stakedEther;
    }

    /**
     * @dev Returns the total number of regions that have been defined by the admin.
     * @return The count of defined regions.
     */
    function getTotalRegionsDefined() public view returns (uint256) {
        return definedRegionIds.length;
    }

    /**
     * @dev Returns the Region ID at a specific index in the list of defined regions.
     * Useful for iterating through defined regions off-chain.
     * @param index The index (0 to getTotalRegionsDefined() - 1).
     * @return The region ID at the given index.
     */
    function getRegionIdByIndexDefined(uint256 index) public view returns (uint256) {
        require(index < definedRegionIds.length, "Index out of bounds");
        return definedRegionIds[index];
    }

    // Fallback function to accept Ether, if needed for manual fee payments etc.
    // Though the current design funnels payments through claim functions.
    // receive() external payable {}
}
```