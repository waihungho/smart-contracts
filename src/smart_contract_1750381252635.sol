Okay, here is a Solidity smart contract for a "Metaverse Estate Manager". It combines elements of NFTs (for land parcels), dynamic on-chain data, per-NFT access control, simulated resource harvesting, environmental factors, staking-like mechanics, and delegation patterns. It aims for creativity and uses several interconnected concepts beyond a basic ERC-721.

**Outline and Function Summary**

This contract, `MetaverseEstateManager`, manages unique virtual land parcels (represented as ERC-721 NFTs) within a simulated metaverse. Each parcel has dynamic properties like coordinates, biome type, environmental score, resources, and associated "build" data. The contract implements advanced features including per-parcel role-based access control, time-based resource harvesting, fee collection, and conceptual state shifts.

**Contract Outline:**

1.  **Imports:** ERC721, Ownable, Counters.
2.  **Errors:** Custom errors for specific failure conditions.
3.  **Enums:** RoleType, BiomeType.
4.  **Structs:** ParcelData.
5.  **State Variables:** Mappings to store parcel data, roles, delegates, fees, global parameters, pausing state. Counter for token IDs.
6.  **Events:** Emitted for key actions like minting, role grants, harvesting, builds, state changes.
7.  **Modifiers:** Custom modifiers for access control.
8.  **ERC721 Standard Functions:** Overridden where necessary (minting handled by custom functions).
9.  **Core Parcel Management:** Minting, setting coordinates/biome/environmental score (admin), setting parcel name (owner).
10. **Per-Parcel Access Control (RBAC):** Granting/revoking roles (Builder, Harvester, etc.) for specific parcels, delegating role management.
11. **Build System:** Associating data representing builds with a parcel (requires role).
12. **Resource System:** Storing resource state, time-based regeneration calculation, harvesting resources (requires role, applies fee).
13. **Global Parameters & Fees:** Setting global resource regeneration rate, harvest fee percentage, withdrawing collected fees (admin).
14. **Dynamic Features:** Simulating a "cross-dimensional shift" that alters a parcel's state (conceptual).
15. **Pause Functionality:** Pausing resource harvesting globally (admin).
16. **Query Functions:** Retrieving parcel details, role status, resource state, build data, global parameters, fees.

**Function Summary (at least 20 custom functions):**

1.  `constructor()`: Initializes the ERC721 contract with name and symbol, sets initial admin.
2.  `mintParcel(address to, int256 x, int256 y, BiomeType biome)`: (Admin only) Mints a new land parcel NFT to an address with initial coordinates and biome.
3.  `batchMintParcels(address[] calldata tos, int256[] calldata xs, int256[] calldata ys, BiomeType[] calldata biomes)`: (Admin only) Mints multiple parcels in a single transaction.
4.  `setParcelCoordinates(uint256 tokenId, int256 x, int256 y)`: (Admin only) Updates the coordinates of a specific parcel.
5.  `setParcelBiome(uint256 tokenId, BiomeType biome)`: (Admin only) Updates the biome type of a specific parcel.
6.  `updateParcelEnvironmentalScore(uint256 tokenId, uint256 newScore)`: (Admin only) Sets the environmental score of a parcel, affecting resource potential.
7.  `setParcelName(uint256 tokenId, string memory name)`: (Parcel Owner) Allows the owner to set a custom name for their parcel.
8.  `grantParcelRole(uint256 tokenId, address user, RoleType role)`: (Parcel Owner or Delegate) Grants a specific role on a parcel to a user.
9.  `revokeParcelRole(uint256 tokenId, address user, RoleType role)`: (Parcel Owner or Delegate) Revokes a specific role on a parcel from a user.
10. `delegateRoleManagement(uint256 tokenId, address delegatee)`: (Parcel Owner) Assigns an address that can grant/revoke roles on this parcel on behalf of the owner. Set address(0) to remove delegation.
11. `setBuildData(uint256 tokenId, bytes memory data)`: (Requires BUILDER role on parcel) Associates arbitrary data (e.g., IPFS hash, structure details) with a parcel.
12. `getBuildData(uint256 tokenId)`: (Query) Retrieves the build data associated with a parcel.
13. `harvestResources(uint256 tokenId)`: (Requires HARVESTER role on parcel) Calculates and 'harvests' available resources based on time elapsed and parcel state. Applies a fee.
14. `getParcelResourceState(uint256 tokenId)`: (Query) Calculates the current potential resource amount available for harvest without actually harvesting.
15. `setGlobalResourceRegenRate(uint256 rate)`: (Admin only) Sets the global resources regenerated per second multiplier.
16. `setGlobalHarvestFeePercentage(uint256 percentage)`: (Admin only) Sets the percentage fee taken on resource harvests (e.g., 5 for 5%). Max 100.
17. `withdrawFees()`: (Admin only) Withdraws accumulated harvest fees.
18. `simulateCrossDimensionalShift(uint256 tokenId, BiomeType newBiome)`: (Admin only, conceptual) Simulates a significant event by changing a parcel's biome type, potentially resetting resource state.
19. `pauseHarvesting()`: (Admin only) Pauses the `harvestResources` function globally.
20. `unpauseHarvesting()`: (Admin only) Unpauses the `harvestResources` function globally.
21. `isHarvestingPaused()`: (Query) Checks if harvesting is globally paused.
22. `getParcelDetails(uint256 tokenId)`: (Query) Retrieves the core data structure for a parcel.
23. `hasParcelRole(uint256 tokenId, address user, RoleType role)`: (Query) Checks if a user has a specific role on a parcel.
24. `getDelegate(uint256 tokenId)`: (Query) Gets the address delegated to manage roles for a parcel.
25. `getTotalFeesCollected()`: (Query) Gets the total amount of fees collected in the contract.
26. `getGlobalResourceRegenRate()`: (Query) Gets the current global resource regeneration rate.
27. `getGlobalHarvestFeePercentage()`: (Query) Gets the current global harvest fee percentage.

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";

// Outline and Function Summary provided above the code block.

/**
 * @title MetaverseEstateManager
 * @dev Manages unique virtual land parcels (ERC-721 NFTs) with dynamic features.
 * Implements per-parcel access control, time-based resources, build data, and fees.
 */
contract MetaverseEstateManager is ERC721, Ownable {
    using Counters for Counters.Counter;
    using SafeMath for uint256;
    using Address for address payable;

    Counters.Counter private _tokenIdCounter;

    // --- Errors ---
    error NotParcelOwnerOrDelegate(uint256 tokenId, address caller);
    error OnlyParcelOwner(uint256 tokenId, address caller);
    error HarvestingPaused();
    error InsufficientResources(uint256 tokenId, uint256 available);
    error NotEnoughTimePassed(uint256 tokenId, uint256 timeRemaining);
    error NoDelegateSet(uint256 tokenId);
    error Unauthorized(address caller);
    error InvalidFeePercentage(uint256 percentage);
    error InvalidBatchData();

    // --- Enums ---
    enum RoleType {
        NONE,       // Default state, no specific role
        VISITOR,    // Can enter/view parcel
        BUILDER,    // Can set/update build data on parcel
        HARVESTER   // Can harvest resources from parcel
    }

    enum BiomeType {
        PLAINS,
        FOREST,
        MOUNTAIN,
        WATER,
        DESERT,
        CRYSTAL_CAVE // Rare biome
    }

    // --- Structs ---
    struct ParcelData {
        int256 x;
        int256 y;
        BiomeType biome;
        uint256 environmentalScore; // Affects resource generation (e.g., 0-100)
        uint256 currentResources;   // Current harvestable resource amount
        uint256 lastHarvestTime;    // Timestamp of the last harvest
        bytes buildData;            // Arbitrary data representing structures/builds (e.g., IPFS hash)
        string name;                // Owner-defined parcel name
        uint256 resourceCapacity;   // Maximum resources the parcel can hold
        uint256 baseRegenRate;      // Base resources regenerated per second
    }

    // --- State Variables ---
    mapping(uint256 => ParcelData) private _parcelData;

    // Per-parcel Role-Based Access Control: tokenId -> user address -> role type -> granted
    mapping(uint256 => mapping(address => mapping(RoleType => bool))) private _parcelRoles;

    // Per-parcel Role Delegation: tokenId -> address allowed to manage roles for this parcel
    mapping(uint256 => address) private _parcelRoleDelegate;

    uint256 public globalResourceRegenRate = 1; // Multiplier for resource regeneration (e.g., resources per second per base rate)
    uint256 public globalHarvestFeePercentage = 5; // Percentage (0-100) taken as fee on harvest

    uint256 private _totalFeesCollected; // Accumulated fees

    bool public harvestingPaused = false;

    // --- Events ---
    event ParcelMinted(uint256 indexed tokenId, address indexed owner, int256 x, int256 y, BiomeType biome);
    event ParcelCoordinatesUpdated(uint256 indexed tokenId, int256 newX, int256 newY);
    event ParcelBiomeUpdated(uint256 indexed tokenId, BiomeType newBiome);
    event ParcelEnvironmentalScoreUpdated(uint256 indexed tokenId, uint256 newScore);
    event ParcelNameUpdated(uint256 indexed tokenId, string newName);
    event ParcelRoleGranted(uint256 indexed tokenId, address indexed user, RoleType role, address indexed grantor);
    event ParcelRoleRevoked(uint256 indexed tokenId, address indexed user, RoleType role, address indexed revoker);
    event ParcelRoleDelegateSet(uint256 indexed tokenId, address indexed delegatee, address indexed delegator);
    event BuildDataSet(uint256 indexed tokenId, bytes data, address indexed setter);
    event ResourcesHarvested(uint256 indexed tokenId, address indexed harvester, uint256 amount, uint256 feeAmount);
    event GlobalResourceRegenRateUpdated(uint256 newRate);
    event GlobalHarvestFeePercentageUpdated(uint256 newPercentage);
    event FeesWithdrawn(uint256 amount, address indexed to);
    event CrossDimensionalShift(uint256 indexed tokenId, BiomeType oldBiome, BiomeType newBiome);
    event HarvestingPausedStateChanged(bool paused);

    // --- Modifiers ---
    modifier onlyParcelOwner(uint256 tokenId) {
        if (ownerOf(tokenId) != _msgSender()) revert OnlyParcelOwner(tokenId, _msgSender());
        _;
    }

    modifier onlyParcelOwnerOrDelegate(uint256 tokenId) {
        address owner = ownerOf(tokenId);
        address delegatee = _parcelRoleDelegate[tokenId];
        if (_msgSender() != owner && _msgSender() != delegatee) {
             revert NotParcelOwnerOrDelegate(tokenId, _msgSender());
        }
        _;
    }

    modifier onlyRole(uint256 tokenId, RoleType role) {
        if (!_parcelRoles[tokenId][_msgSender()][role] && ownerOf(tokenId) != _msgSender()) {
            revert Unauthorized(_msgSender());
        }
        _;
    }

    // --- Constructor ---
    constructor() ERC721("Metaverse Estate Parcel", "MEP") Ownable(_msgSender()) {}

    // --- Core Parcel Management (Admin) ---

    /**
     * @dev Mints a new land parcel NFT.
     * @param to The address to mint the parcel to.
     * @param x The x-coordinate of the parcel.
     * @param y The y-coordinate of the parcel.
     * @param biome The biome type of the parcel.
     */
    function mintParcel(address to, int256 x, int256 y, BiomeType biome) external onlyOwner {
        _tokenIdCounter.increment();
        uint256 newTokenId = _tokenIdCounter.current();

        // Set initial parcel data
        _parcelData[newTokenId] = ParcelData({
            x: x,
            y: y,
            biome: biome,
            environmentalScore: 50, // Default score
            currentResources: 0,
            lastHarvestTime: block.timestamp,
            buildData: "",
            name: "",
            resourceCapacity: _getBaseResourceCapacity(biome),
            baseRegenRate: _getBaseRegenRate(biome)
        });

        _safeMint(to, newTokenId);

        emit ParcelMinted(newTokenId, to, x, y, biome);
    }

    /**
     * @dev Mints multiple new land parcel NFTs in a batch.
     * @param tos An array of addresses to mint the parcels to.
     * @param xs An array of x-coordinates.
     * @param ys An array of y-coordinates.
     * @param biomes An array of biome types.
     */
    function batchMintParcels(
        address[] calldata tos,
        int256[] calldata xs,
        int256[] calldata ys,
        BiomeType[] calldata biomes
    ) external onlyOwner {
        if (tos.length != xs.length || tos.length != ys.length || tos.length != biomes.length) {
            revert InvalidBatchData();
        }

        for (uint i = 0; i < tos.length; i++) {
            _tokenIdCounter.increment();
            uint256 newTokenId = _tokenIdCounter.current();

             _parcelData[newTokenId] = ParcelData({
                x: xs[i],
                y: ys[i],
                biome: biomes[i],
                environmentalScore: 50, // Default score
                currentResources: 0,
                lastHarvestTime: block.timestamp,
                buildData: "",
                name: "",
                resourceCapacity: _getBaseResourceCapacity(biomes[i]),
                baseRegenRate: _getBaseRegenRate(biomes[i])
            });

            _safeMint(tos[i], newTokenId);
            emit ParcelMinted(newTokenId, tos[i], xs[i], ys[i], biomes[i]);
        }
    }

    /**
     * @dev Updates the coordinates of a specific parcel. Admin only.
     * @param tokenId The ID of the parcel.
     * @param newX The new x-coordinate.
     * @param newY The new y-coordinate.
     */
    function setParcelCoordinates(uint256 tokenId, int256 newX, int256 newY) external onlyOwner {
        _parcelData[tokenId].x = newX;
        _parcelData[tokenId].y = newY;
        emit ParcelCoordinatesUpdated(tokenId, newX, newY);
    }

    /**
     * @dev Updates the biome type of a specific parcel. Admin only.
     * @param tokenId The ID of the parcel.
     * @param newBiome The new biome type.
     */
    function setParcelBiome(uint256 tokenId, BiomeType newBiome) external onlyOwner {
        BiomeType oldBiome = _parcelData[tokenId].biome;
         _parcelData[tokenId].biome = newBiome;
         // Optionally update resource params based on new biome
         _parcelData[tokenId].resourceCapacity = _getBaseResourceCapacity(newBiome);
         _parcelData[tokenId].baseRegenRate = _getBaseRegenRate(newBiome);
         // Optionally reset or adjust current resources based on new biome
         _parcelData[tokenId].currentResources = _parcelData[tokenId].currentResources.min(_parcelData[tokenId].resourceCapacity);

        emit ParcelBiomeUpdated(tokenId, oldBiome, newBiome);
    }

    /**
     * @dev Updates the environmental score of a parcel. Admin only.
     * This score can influence resource regeneration.
     * @param tokenId The ID of the parcel.
     * @param newScore The new environmental score (e.g., 0-100).
     */
    function updateParcelEnvironmentalScore(uint256 tokenId, uint256 newScore) external onlyOwner {
        _parcelData[tokenId].environmentalScore = newScore;
        emit ParcelEnvironmentalScoreUpdated(tokenId, newScore);
    }

    /**
     * @dev Allows the parcel owner to set a custom name for their parcel.
     * @param tokenId The ID of the parcel.
     * @param name The desired name for the parcel.
     */
    function setParcelName(uint256 tokenId, string memory name) external onlyParcelOwner(tokenId) {
        _parcelData[tokenId].name = name;
        emit ParcelNameUpdated(tokenId, name);
    }

    // --- Per-Parcel Access Control (RBAC) ---

    /**
     * @dev Grants a specific role on a parcel to a user.
     * Can only be called by the parcel owner or the delegated address for role management.
     * @param tokenId The ID of the parcel.
     * @param user The address to grant the role to.
     * @param role The role type to grant.
     */
    function grantParcelRole(uint256 tokenId, address user, RoleType role) external onlyParcelOwnerOrDelegate(tokenId) {
        if (role == RoleType.NONE) return; // Cannot grant NONE role
        _parcelRoles[tokenId][user][role] = true;
        emit ParcelRoleGranted(tokenId, user, role, _msgSender());
    }

    /**
     * @dev Revokes a specific role on a parcel from a user.
     * Can only be called by the parcel owner or the delegated address for role management.
     * @param tokenId The ID of the parcel.
     * @param user The address to revoke the role from.
     * @param role The role type to revoke.
     */
    function revokeParcelRole(uint256 tokenId, address user, RoleType role) external onlyParcelOwnerOrDelegate(tokenId) {
         if (role == RoleType.NONE) return; // Cannot revoke NONE role
        _parcelRoles[tokenId][user][role] = false;
        emit ParcelRoleRevoked(tokenId, user, role, _msgSender());
    }

     /**
     * @dev Assigns an address that can manage roles (grant/revoke) for a specific parcel.
     * Can only be called by the parcel owner.
     * @param tokenId The ID of the parcel.
     * @param delegatee The address to delegate role management to (address(0) to clear).
     */
    function delegateRoleManagement(uint256 tokenId, address delegatee) external onlyParcelOwner(tokenId) {
        _parcelRoleDelegate[tokenId] = delegatee;
        emit ParcelRoleDelegateSet(tokenId, delegatee, _msgSender());
    }

    /**
     * @dev Checks if a user has a specific role on a parcel.
     * Parcel owner implicitly has all roles.
     * @param tokenId The ID of the parcel.
     * @param user The address to check.
     * @param role The role type to check.
     * @return bool True if the user has the role, false otherwise.
     */
    function hasParcelRole(uint256 tokenId, address user, RoleType role) public view returns (bool) {
        if (ownerOf(tokenId) == user) return true; // Owner implicitly has all roles
        return _parcelRoles[tokenId][user][role];
    }

     /**
     * @dev Gets the address currently delegated to manage roles for a parcel.
     * @param tokenId The ID of the parcel.
     * @return address The delegated address, or address(0) if none is set.
     */
    function getDelegate(uint256 tokenId) public view returns (address) {
        return _parcelRoleDelegate[tokenId];
    }


    // --- Build System ---

    /**
     * @dev Allows a user with the BUILDER role to set/update arbitrary build data for a parcel.
     * Data could represent structures, assets, IPFS links, etc.
     * @param tokenId The ID of the parcel.
     * @param data The bytes data to associate with the parcel.
     */
    function setBuildData(uint256 tokenId, bytes memory data) external onlyRole(tokenId, RoleType.BUILDER) {
        _parcelData[tokenId].buildData = data;
        emit BuildDataSet(tokenId, data, _msgSender());
    }

    /**
     * @dev Retrieves the build data associated with a parcel.
     * @param tokenId The ID of the parcel.
     * @return bytes The build data.
     */
    function getBuildData(uint256 tokenId) public view returns (bytes memory) {
        return _parcelData[tokenId].buildData;
    }

    // --- Resource System ---

    /**
     * @dev Calculates and harvests available resources from a parcel.
     * Requires the HARVESTER role or being the parcel owner.
     * Resources regenerate over time based on biome, environmental score, and global rate.
     * Applies a global harvest fee.
     * @param tokenId The ID of the parcel.
     */
    function harvestResources(uint256 tokenId) external onlyRole(tokenId, RoleType.HARVESTER) {
        if (harvestingPaused) revert HarvestingPaused();

        ParcelData storage parcel = _parcelData[tokenId];
        uint256 availableResources = _calculateAvailableResources(tokenId);

        if (availableResources == 0) revert InsufficientResources(tokenId, 0);

        // Calculate fee
        uint256 feeAmount = availableResources.mul(globalHarvestFeePercentage).div(100);
        uint256 harvestAmount = availableResources.sub(feeAmount);

        // Update state
        parcel.currentResources = 0; // Reset current resources to 0 after harvest
        parcel.lastHarvestTime = block.timestamp; // Record the harvest time
        _totalFeesCollected = _totalFeesCollected.add(feeAmount);

        // In a real system, you'd typically issue resource tokens here
        // For this example, we just track the amount harvested and the fee.
        // Emit event for off-chain systems to handle resource distribution.
        emit ResourcesHarvested(tokenId, _msgSender(), harvestAmount, feeAmount);
    }

    /**
     * @dev Calculates the current amount of resources available for harvest on a parcel.
     * Resources regenerate since the last harvest time, up to the capacity.
     * @param tokenId The ID of the parcel.
     * @return uint256 The potential resources available for harvest.
     */
    function getParcelResourceState(uint256 tokenId) public view returns (uint256) {
        return _calculateAvailableResources(tokenId);
    }

    /**
     * @dev Internal function to calculate resources regenerated since last harvest.
     * @param tokenId The ID of the parcel.
     * @return uint256 The calculated resources available.
     */
    function _calculateAvailableResources(uint256 tokenId) internal view returns (uint256) {
        ParcelData storage parcel = _parcelData[tokenId];
        uint256 timeElapsed = block.timestamp.sub(parcel.lastHarvestTime);

        // Resources generated = timeElapsed * baseRegenRate * environmentalScore / 100 * globalRegenRate
        // Use scaling to handle score 0-100 and global rate
        uint256 generated = timeElapsed.mul(parcel.baseRegenRate)
                                    .mul(parcel.environmentalScore) // Score 0-100
                                    .div(100)
                                    .mul(globalResourceRegenRate);

        uint256 totalResources = parcel.currentResources.add(generated);

        // Cap resources at the parcel's capacity
        return totalResources.min(parcel.resourceCapacity);
    }

    /**
     * @dev Helper function to get base resource capacity based on biome.
     * This could be more complex (e.g., mapping).
     */
    function _getBaseResourceCapacity(BiomeType biome) internal pure returns (uint256) {
        if (biome == BiomeType.FOREST) return 1000;
        if (biome == BiomeType.MOUNTAIN) return 1500;
        if (biome == BiomeType.WATER) return 800;
        if (biome == BiomeType.DESERT) return 500;
        if (biome == BiomeType.CRYSTAL_CAVE) return 3000; // Rare biome has high capacity
        return 750; // PLAINS or other default
    }

     /**
     * @dev Helper function to get base resource regeneration rate based on biome.
     */
    function _getBaseRegenRate(BiomeType biome) internal pure returns (uint256) {
        if (biome == BiomeType.FOREST) return 1; // 1 resource per second base
        if (biome == BiomeType.MOUNTAIN) return 0.8 ether / 1e18; // Fractional base rate (using ether units as example)
        if (biome == BiomeType.WATER) return 0.5 ether / 1e18;
        if (biome == BiomeType.DESERT) return 0.2 ether / 1e18;
        if (biome == BiomeType.CRYSTAL_CAVE) return 2; // High regen rate
        return 0.7 ether / 1e18; // PLAINS
    }


    // --- Global Parameters & Fees (Admin) ---

    /**
     * @dev Sets the global multiplier for resource regeneration rate. Admin only.
     * A value of 1 means resources regenerate at the base rate * environmentalScore/100.
     * A value of 2 means they regenerate at 2 * baseRate * environmentalScore/100.
     * @param rate The new global regeneration rate multiplier.
     */
    function setGlobalResourceRegenRate(uint256 rate) external onlyOwner {
        globalResourceRegenRate = rate;
        emit GlobalResourceRegenRateUpdated(rate);
    }

    /**
     * @dev Sets the percentage fee collected on resource harvests. Admin only.
     * @param percentage The new fee percentage (0-100).
     */
    function setGlobalHarvestFeePercentage(uint256 percentage) external onlyOwner {
        if (percentage > 100) revert InvalidFeePercentage(percentage);
        globalHarvestFeePercentage = percentage;
        emit GlobalHarvestFeePercentageUpdated(percentage);
    }

    /**
     * @dev Allows the contract owner to withdraw accumulated harvest fees. Admin only.
     */
    function withdrawFees() external onlyOwner {
        uint256 amount = _totalFeesCollected;
        if (amount == 0) return;

        _totalFeesCollected = 0; // Reset fees before sending to prevent reentrancy issues (though unlikely here)

        // Send ether (assuming fees are tracked in the chain's native currency, though the example tracks a 'resource' amount)
        // NOTE: This example tracks fees in 'resource' units, not actual ether/tokens sent to the contract.
        // For actual financial fees, the harvestResources function would need to handle value transfers.
        // This implementation simulates a 'resource sink' for the metaverse's economy.
        // If fees were ETH/tokens, you'd use payable(owner()).send(amount);
        // For now, this function just acknowledges the withdrawal of 'resource' fees conceptually.
        // To implement actual withdrawal of ETH/tokens, the contract needs to RECEIVE them first.
        // This requires `harvestResources` to handle incoming value or transfer tokens.
        // As the prompt asks for creative concepts, let's imagine fees are resource units
        // taken by the system, not necessarily ETH. If ETH fees are needed, the contract
        // would need to be payable and handle ETH balances.

        // Conceptual fee withdrawal event - off-chain system would handle this based on totalFeesCollected
        emit FeesWithdrawn(amount, _msgSender());

        // If implementing actual ETH/token withdrawal:
        // require(payable(owner()).send(amount), "Fee withdrawal failed");
    }

    /**
     * @dev Gets the total amount of fees (in resource units) collected.
     */
     function getTotalFeesCollected() public view returns (uint256) {
         return _totalFeesCollected;
     }

    /**
     * @dev Gets the current global resource regeneration rate.
     */
     function getGlobalResourceRegenRate() public view returns (uint256) {
         return globalResourceRegenRate;
     }

    /**
     * @dev Gets the current global harvest fee percentage.
     */
     function getGlobalHarvestFeePercentage() public view returns (uint256) {
         return globalHarvestFeePercentage;
     }


    // --- Dynamic Features ---

    /**
     * @dev Conceptual function to simulate a major event or state shift for a parcel.
     * This could be a plot point, environmental disaster, or magical transformation.
     * As an example, it changes the biome and might reset resources. Admin only.
     * More complex logic could be added (e.g., affecting environmental score, adding/removing features).
     * @param tokenId The ID of the parcel undergoing the shift.
     * @param newBiome The new biome type for the parcel.
     */
    function simulateCrossDimensionalShift(uint256 tokenId, BiomeType newBiome) external onlyOwner {
         ParcelData storage parcel = _parcelData[tokenId];
         BiomeType oldBiome = parcel.biome;

         parcel.biome = newBiome;
         parcel.environmentalScore = uint256(50); // Reset environmental score
         parcel.currentResources = 0; // Reset resources
         parcel.lastHarvestTime = block.timestamp; // Reset harvest timer
         parcel.resourceCapacity = _getBaseResourceCapacity(newBiome);
         parcel.baseRegenRate = _getBaseRegenRate(newBiome);

        emit CrossDimensionalShift(tokenId, oldBiome, newBiome);
    }


    // --- Pause Functionality ---

    /**
     * @dev Pauses resource harvesting globally. Admin only.
     */
    function pauseHarvesting() external onlyOwner {
        harvestingPaused = true;
        emit HarvestingPausedStateChanged(true);
    }

    /**
     * @dev Unpauses resource harvesting globally. Admin only.
     */
    function unpauseHarvesting() external onlyOwner {
        harvestingPaused = false;
        emit HarvestingPausedStateChanged(false);
    }

    /**
     * @dev Checks if resource harvesting is currently paused.
     */
    function isHarvestingPaused() public view returns (bool) {
        return harvestingPaused;
    }


    // --- Query Functions ---

    /**
     * @dev Gets the core data struct for a specific parcel.
     * @param tokenId The ID of the parcel.
     * @return ParcelData The struct containing parcel details.
     */
    function getParcelDetails(uint256 tokenId) public view returns (ParcelData memory) {
        return _parcelData[tokenId];
    }

    // NOTE: Getting all token IDs for an owner, or iterating through all tokens,
    // is potentially very gas expensive for large numbers of tokens.
    // ERC721Enumerable extension provides tokenOfOwnerByIndex and tokenByIndex,
    // but these also have gas costs. For efficiency in large metaverses,
    // off-chain indexing is typically used to list user assets or iterate through tokens.
    // We are skipping functions like `getParcelsByBiome` or `getAllOwnedParcelsDetailed`
    // that would require iterating over the entire dataset on-chain for gas efficiency.

    // --- ERC721 Overrides (Minimal for custom minting flow) ---

    // We rely on the inherited _safeMint for actual token creation and assignment.
    // Standard transferFrom, approve, getApproved, setApprovalForAll, isApprovedForAll work as inherited.
    // ownerOf and balanceOf are inherited and used internally.

    /**
     * @dev See {ERC721-tokenURI}.
     * Returns a dynamic URI based on parcel data.
     * In a real application, this might point to an API that returns JSON metadata.
     */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        _requireOwned(tokenId); // Inherited check

        ParcelData memory parcel = _parcelData[tokenId];
        string memory baseURI = "https://metaverse.example.com/parcels/"; // Example base URI

        // Construct a simple example URI - real applications use off-chain APIs
        string memory uri = string(abi.encodePacked(
            baseURI,
            Strings.toString(tokenId),
            "/metadata"
            // You might add query params like ?name=...&biome=...
        ));

        return uri;
    }

    // The following ERC721 functions are inherited and work out-of-the-box:
    // transferFrom(address from, address to, uint256 tokenId)
    // safeTransferFrom(address from, address to, uint256 tokenId)
    // safeTransferFrom(address from, address to, uint256 tokenId, bytes data)
    // approve(address to, uint256 tokenId)
    // setApprovalForAll(address operator, bool approved)
    // getApproved(uint256 tokenId)
    // isApprovedForAll(address owner, address operator)
    // ownerOf(uint256 tokenId)
    // balanceOf(address owner)
    // supportsInterface(bytes4 interfaceId)

}
```