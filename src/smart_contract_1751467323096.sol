Okay, let's design a smart contract that represents a dynamic, utility-bearing digital asset – something more than just a static image or a simple token. We'll call them "ChronoSpheres".

These ChronoSpheres will be NFTs (ERC-721) that have internal state that changes over time and through interaction. They have a "Temporal Energy" level that replenishes over time and can be consumed for utility (e.g., harvesting resources or performing actions). They can also be refined or merged to potentially increase their power or change their properties. They'll incorporate concepts like dynamic state, time-based mechanics, utility delegation, and on-chain crafting/evolution.

---

## Smart Contract: ChronoSphere

**SPDX-License-Identifier:** MIT
**Pragma:** solidity ^0.8.20;

### Outline:

1.  **Basic ERC721 Compliance:** Standard NFT ownership, transfer, approval. Uses OpenZeppelin's implementation for robustness.
2.  **Pausability:** Allows the owner to pause certain sensitive operations (minting, harvesting, refining, merging) in case of emergency.
3.  **Ownable & Access Control:** Standard owner pattern with an added "Manager" role for delegated administrative tasks.
4.  **Dynamic Sphere State:**
    *   Each ChronoSphere NFT (`uint256 tokenId`) stores custom data: tier, current temporal energy, max temporal energy, base energy replenishment rate, and the timestamp of the last state update (sync/harvest).
    *   Temporal energy replenishes automatically based on the elapsed time since the last update, up to the max energy limit.
5.  **Temporal Energy & Utility:**
    *   Spheres accumulate "Temporal Energy" over time.
    *   Energy can be "harvested" via the `harvestEnergy` function. This consumes energy and might yield a conceptual resource or value (represented as a return value here).
    *   Energy calculation is dynamic, considering time elapsed since the last interaction.
6.  **Time-Based Mechanics:** Uses `block.timestamp` to calculate energy replenishment.
7.  **Utility Delegation:** The owner of a ChronoSphere can delegate the *right to harvest energy* to another address for a limited time, enabling rental or collaborative use.
8.  **On-Chain Evolution/Crafting:**
    *   **Refining:** Improve a single ChronoSphere by consuming it along with a conceptual "refining material" (represented by sending ETH as payment/cost). This can potentially increase its max energy, replenishment rate, or even upgrade its tier.
    *   **Merging:** Combine two ChronoSpheres (burning them) to create a new, potentially higher-tier or more powerful ChronoSphere. Requires a conceptual "merging cost" (paid in ETH).
9.  **Tier System:** ChronoSpheres exist in different tiers, with base properties defined by the admin. These properties can be modified through refining/merging.
10. **Admin Configuration:** Owner/Manager can set base properties for tiers, set costs for refining/merging, set the base URI for metadata, and withdraw accumulated ETH fees.
11. **Dynamic Metadata:** `tokenURI` hints that metadata should be dynamic and potentially reflect the current state (tier, energy) of the ChronoSphere.

### Function Summary:

**ERC721 Standard Functions (Implemented via OpenZeppelin):**
*   `balanceOf(address owner)`: Get the number of spheres owned by an address.
*   `ownerOf(uint256 tokenId)`: Get the owner of a specific sphere.
*   `safeTransferFrom(address from, address to, uint256 tokenId)`: Safely transfer a sphere.
*   `safeTransferFrom(address from, address to, uint256 tokenId, bytes data)`: Safely transfer with data.
*   `transferFrom(address from, address to, uint256 tokenId)`: Transfer a sphere.
*   `approve(address to, uint256 tokenId)`: Approve an address to spend a specific sphere.
*   `setApprovalForAll(address operator, bool approved)`: Approve/disapprove an operator for all spheres.
*   `getApproved(uint256 tokenId)`: Get the approved address for a sphere.
*   `isApprovedForAll(address owner, address operator)`: Check if an operator is approved for all spheres.
*   `supportsInterface(bytes4 interfaceId)`: Standard ERC165 interface detection.
*   `totalSupply()`: Get the total number of minted spheres.
*   `tokenOfOwnerByIndex(address owner, uint256 index)`: Get sphere ID by owner and index (for enumeration).
*   `tokenByIndex(uint256 index)`: Get sphere ID by index (for enumeration).

**ChronoSphere Core Logic Functions:**
*   `mintSphere(address recipient, uint256 initialTier, uint256 initialEnergy)`: Mint a new sphere (Owner/Manager only).
*   `burnSphere(uint256 sphereId)`: Burn a sphere (Owner or Approved caller).
*   `getSphereData(uint256 sphereId)`: Get the stored `SphereData` for a sphere.
*   `getCurrentEnergy(uint256 sphereId)`: Calculate and return the *current* temporal energy including time-based replenishment.
*   `harvestEnergy(uint256 sphereId)`: Consume energy from a sphere, calculate replenished energy first, update state, and return harvested amount. Callable by owner or delegated utility address.
*   `refineSphere(uint256 sphereId, uint256 refiningCost)`: Attempt to refine a sphere, consuming it and paying the cost in ETH. May result in an upgrade or new sphere (simulated).
*   `mergeSpheres(uint256 sphereId1, uint256 sphereId2, uint256 mergeCost)`: Attempt to merge two spheres, burning them and paying the cost in ETH. May result in a new, higher-tier sphere (simulated).
*   `delegateUtilityAccess(uint256 sphereId, address delegatee, uint64 durationSeconds)`: Delegate the right to call `harvestEnergy` for a period.
*   `revokeUtilityAccess(uint256 sphereId)`: Revoke any active utility delegation for a sphere.
*   `getUtilityDelegatee(uint256 sphereId)`: Get the current utility delegatee for a sphere.
*   `isUtilityDelegatee(uint256 sphereId, address account)`: Check if an account is the current utility delegatee for a sphere.
*   `getRefinedSphereParams(uint256 sphereId)`: Simulate/predict parameters after refining (internal logic, exposed as view for transparency).
*   `getMergedSphereParams(uint256 sphereId1, uint256 sphereId2)`: Simulate/predict parameters of the resulting sphere after merging (internal logic, exposed as view).

**Admin & Configuration Functions:**
*   `setTierProperties(uint256 tier, uint256 baseMaxEnergy, uint256 baseReplenishmentRatePerSecond)`: Set the base properties for a specific tier (Owner/Manager only).
*   `setRefiningCost(uint256 tier, uint256 costInWei)`: Set the ETH cost for refining a sphere of a given tier (Owner/Manager only).
*   `setMergeCost(uint256 tier1, uint256 tier2, uint256 costInWei)`: Set the ETH cost for merging two spheres of given tiers (Owner/Manager only).
*   `setApprovedManager(address account, bool approved)`: Grant or revoke Manager role (Owner only).
*   `isApprovedManager(address account)`: Check if an address is a Manager.
*   `pause()`: Pause operations (Owner only).
*   `unpause()`: Unpause operations (Owner only).
*   `withdrawAdminFees(address payable recipient)`: Withdraw accumulated ETH fees (Owner only).
*   `setBaseTokenURI(string memory baseURI)`: Set the base URI for metadata (Owner only).
*   `tokenURI(uint256 sphereId)`: Get the metadata URI for a sphere (Overridden ERC721).

**Internal Helper Functions:**
*   `_getSphereData(uint256 sphereId)`: Safely retrieve mutable sphere data.
*   `_updateSphereEnergy(uint256 sphereId)`: Calculate and update stored energy based on time.
*   `_calculateCurrentEnergy(uint256 sphereId)`: Calculate current energy without updating state.
*   `_beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize)`: ERC721 hook - useful for internal state updates before transfers.
*   `_burn(uint256 tokenId)`: ERC721 hook - custom burn logic.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

// Outline and Function Summary provided above the contract code.

contract ChronoSphere is ERC721Enumerable, Ownable, Pausable {
    using EnumerableSet for EnumerableSet.AddressSet;

    // --- Errors ---
    error ChronoSphere__SphereDoesNotExist(uint256 sphereId);
    error ChronoSphere__NotSphereOwnerOrApprovedOrDelegatee(uint256 sphereId, address account);
    error ChronoSphere__NotEnoughEnergy(uint256 sphereId, uint256 requiredAmount, uint256 currentAmount);
    error ChronoSphere__InvalidTier(uint256 tier);
    error ChronoSphere__RefiningCostMismatch(uint256 expectedCost, uint256 sentValue);
    error ChronoSphere__MergeCostMismatch(uint256 expectedCost, uint256 sentValue);
    error ChronoSphere__CannotMergeSameSphere(uint256 sphereId);
    error ChronoSphere__UtilityDelegationNotActive(uint256 sphereId, address account);
    error ChronoSphere__UtilityDelegationAlreadyActive(uint256 sphereId, address delegatee);

    // --- Structs ---
    struct SphereData {
        uint256 tier;
        uint256 currentEnergy; // Stored energy (needs sync)
        uint256 maxEnergy;
        uint256 replenishmentRatePerSecond; // Energy added per second
        uint64 lastSyncTimestamp; // Timestamp of last energy calculation update
    }

    struct TierProperties {
        uint256 baseMaxEnergy;
        uint256 baseReplenishmentRatePerSecond;
    }

    struct UtilityDelegation {
        address delegatee;
        uint64 expirationTimestamp;
    }

    // --- State Variables ---
    mapping(uint256 => SphereData) private s_sphereData;
    mapping(uint256 => UtilityDelegation) private s_utilityDelegation;
    mapping(uint256 => TierProperties) private s_tierProperties;
    mapping(uint256 => uint256) private s_refiningCosts; // Tier => Cost in Wei
    mapping(bytes32 => uint256) private s_mergeCosts;    // hash(tier1, tier2) => Cost in Wei (sorted tiers for consistent hash)
    EnumerableSet.AddressSet private s_approvedManagers;

    uint256 private s_nextTokenId;
    string private s_baseTokenURI;

    // --- Events ---
    event SphereMinted(uint256 indexed sphereId, address indexed owner, uint256 initialTier, uint256 initialEnergy);
    event SphereBurned(uint256 indexed sphereId, address indexed owner);
    event EnergyHarvested(uint256 indexed sphereId, address indexed harvester, uint256 amountHarvested, uint256 remainingEnergy);
    event EnergySynced(uint256 indexed sphereId, uint256 energyAdded, uint256 newEnergy);
    event SphereRefined(uint256 indexed oldSphereId, uint256 indexed newSphereId, uint256 newTier, uint256 newMaxEnergy, uint256 newReplenishmentRate);
    event SphereMerged(uint256 indexed sphereId1, uint256 indexed sphereId2, uint256 indexed newSphereId, uint256 newTier);
    event UtilityDelegated(uint256 indexed sphereId, address indexed delegatee, uint64 expirationTimestamp);
    event UtilityDelegationRevoked(uint256 indexed sphereId, address indexed delegatee);
    event TierPropertiesUpdated(uint256 indexed tier, uint256 baseMaxEnergy, uint256 baseReplenishmentRate);
    event RefiningCostUpdated(uint256 indexed tier, uint256 costInWei);
    event MergeCostUpdated(uint256 indexed tier1, uint256 indexed tier2, uint256 costInWei);
    event ManagerApproved(address indexed account);
    event ManagerRevoked(address indexed account);
    event AdminFeesWithdrawn(address indexed recipient, uint256 amount);
    event BaseTokenURIUpdated(string baseURI);

    // --- Modifiers ---
    modifier onlyApprovedManager() {
        if (!s_approvedManagers.contains(msg.sender) && msg.sender != owner()) {
            revert OwnableUnauthorizedAccount(msg.sender); // Re-use Ownable error for role
        }
        _;
    }

    modifier whenNotPausedAndOperational(uint256 sphereId) {
        whenNotPaused();
        _exists(sphereId); // Check if token exists
        _;
    }

     modifier whenNotPausedAndOperational(uint256 sphereId1, uint256 sphereId2) {
        whenNotPaused();
        _exists(sphereId1);
        _exists(sphereId2);
        _;
    }

    // --- Constructor ---
    constructor(string memory name, string memory symbol) ERC721(name, symbol) Ownable(msg.sender) {}

    // --- Access Control (Manager Role) ---
    function setApprovedManager(address account, bool approved) external onlyOwner {
        if (approved) {
            require(s_approvedManagers.add(account), "ChronoSphere: Manager already approved");
            emit ManagerApproved(account);
        } else {
            require(s_approvedManagers.remove(account), "ChronoSphere: Manager not approved");
            emit ManagerRevoked(account);
        }
    }

    function isApprovedManager(address account) public view returns (bool) {
        return s_approvedManagers.contains(account);
    }

    // --- Pausability ---
    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    // --- ERC721 Overrides ---
    // Override supportsInterface to include ERC721Enumerable and custom interfaces if needed
    // ERC721Enumerable adds ERC721, ERC165, and ERC721Metadata interfaces automatically.
    // No extra overrides needed here unless adding custom interfaces.

    // Custom logic before any transfer
    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize) internal override(ERC721Enumerable) whenNotPaused {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);

        if (from != address(0)) {
            // When transferring out, revoke utility delegation for the old owner
             if (s_utilityDelegation[tokenId].delegatee != address(0)) {
                delete s_utilityDelegation[tokenId];
                emit UtilityDelegationRevoked(tokenId, address(0)); // Emit with address(0) as delegatee indicates removal
            }
            // Sync energy before transfer if state matters at transfer time
            // _updateSphereEnergy(tokenId); // Optional: sync energy before transfer
        }

        // Note: We don't sync energy on mint (to address(0)) as initial energy is set.
        // No sync needed on burn (from != address(0)).
    }

    // Custom burn logic
    function _burn(uint256 tokenId) internal override(ERC721Enumerable) {
        require(ownerOf(tokenId) == msg.sender || isApprovedForAll(ownerOf(tokenId), msg.sender), "ChronoSphere: caller is not owner nor approved");
        super._burn(tokenId);

        // Clean up custom state upon burning
        delete s_sphereData[tokenId];
        delete s_utilityDelegation[tokenId];

        emit SphereBurned(tokenId, msg.sender); // Emit with caller as burner, not owner
    }

    // Dynamic Token URI
    function tokenURI(uint256 sphereId) public view override returns (string memory) {
        _exists(sphereId);
        // Concatenate base URI with token ID or custom path indicating dynamism
        // For dynamic NFTs, the URI should point to an API endpoint that reads the state and returns metadata.
        // Example: "https://myapi.com/chronospheres/{id}.json"
        // Or a custom scheme: "chronosphere://{id}"
        if (bytes(s_baseTokenURI).length == 0) {
            return ""; // No base URI set
        }
        return string(abi.encodePacked(s_baseTokenURI, Strings.toString(sphereId)));
    }

    function setBaseTokenURI(string memory baseURI) external onlyApprovedManager {
        s_baseTokenURI = baseURI;
        emit BaseTokenURIUpdated(baseURI);
    }

    // --- Sphere State Getters ---
    function _getSphereData(uint256 sphereId) internal view returns (SphereData storage sphere) {
        require(_exists(sphereId), ChronoSphere__SphereDoesNotExist(sphereId));
        return s_sphereData[sphereId];
    }

    function getSphereData(uint256 sphereId) public view returns (uint256 tier, uint256 currentEnergy, uint256 maxEnergy, uint256 replenishmentRate, uint64 lastSyncTimestamp) {
        SphereData storage sphere = _getSphereData(sphereId);
        return (
            sphere.tier,
            _calculateCurrentEnergy(sphereId), // Return calculated current energy
            sphere.maxEnergy,
            sphere.replenishmentRatePerSecond,
            sphere.lastSyncTimestamp
        );
    }

    function getSphereTier(uint256 sphereId) public view returns (uint256) {
         return _getSphereData(sphereId).tier;
    }

     function getCurrentEnergy(uint256 sphereId) public view returns (uint256) {
        return _calculateCurrentEnergy(sphereId);
    }

    function getSphereLastSyncTime(uint256 sphereId) public view returns (uint64) {
        return _getSphereData(sphereId).lastSyncTimestamp;
    }

    // --- Sphere Creation & Destruction ---
    function mintSphere(address recipient, uint256 initialTier, uint256 initialEnergy) external onlyApprovedManager whenNotPaused {
        uint256 newTokenId = s_nextTokenId++;
        _safeMint(recipient, newTokenId);

        require(s_tierProperties[initialTier].baseMaxEnergy > 0, ChronoSphere__InvalidTier(initialTier)); // Tier must be configured

        s_sphereData[newTokenId] = SphereData({
            tier: initialTier,
            currentEnergy: initialEnergy,
            maxEnergy: s_tierProperties[initialTier].baseMaxEnergy,
            replenishmentRatePerSecond: s_tierProperties[initialTier].baseReplenishmentRatePerSecond,
            lastSyncTimestamp: uint64(block.timestamp)
        });

        emit SphereMinted(newTokenId, recipient, initialTier, initialEnergy);
    }

    // Burn function inherited from ERC721, overridden internally for state cleanup.
    // expose _burn as public burnSphere
    function burnSphere(uint256 sphereId) external {
        _burn(sphereId);
    }


    // --- Temporal Energy Mechanics ---

    // Internal function to calculate how much energy was replenished since last sync/harvest
    function _calculateReplenishedEnergy(uint256 sphereId) internal view returns (uint256) {
        SphereData storage sphere = s_sphereData[sphereId]; // Use storage reference for internal calculations
        uint64 timeElapsed = uint64(block.timestamp) - sphere.lastSyncTimestamp;
        return timeElapsed * sphere.replenishmentRatePerSecond;
    }

    // Internal function to calculate current energy including replenishment
    function _calculateCurrentEnergy(uint256 sphereId) internal view returns (uint256) {
         require(_exists(sphereId), ChronoSphere__SphereDoesNotExist(sphereId));
         SphereData storage sphere = s_sphereData[sphereId];
         uint256 replenished = _calculateReplenishedEnergy(sphereId);
         return Math.min(sphere.currentEnergy + replenished, sphere.maxEnergy);
    }

    // Internal function to sync the stored energy state
    function _updateSphereEnergy(uint256 sphereId) internal returns (uint256 newEnergy) {
        SphereData storage sphere = s_sphereData[sphereId];
        uint256 replenished = _calculateReplenishedEnergy(sphereId);
        uint256 oldEnergy = sphere.currentEnergy;
        newEnergy = Math.min(oldEnergy + replenished, sphere.maxEnergy);

        if (newEnergy != oldEnergy) {
             sphere.currentEnergy = newEnergy;
             emit EnergySynced(sphereId, newEnergy - oldEnergy, newEnergy);
        }
        sphere.lastSyncTimestamp = uint64(block.timestamp);
        return newEnergy;
    }

    /**
     * @notice Harvest temporal energy from a ChronoSphere.
     * @dev Calculates replenishment, updates stored energy, consumes energy, and returns the harvested amount.
     * @param sphereId The ID of the ChronoSphere to harvest from.
     * @return harvestedAmount The amount of energy harvested.
     */
    function harvestEnergy(uint256 sphereId) external whenNotPausedAndOperational(sphereId) returns (uint256 harvestedAmount) {
        address sphereOwner = ownerOf(sphereId);
        UtilityDelegation storage delegation = s_utilityDelegation[sphereId];
        bool isApprovedOrOwner = (_isApprovedOrOwner(sphereOwner, msg.sender));
        bool isDelegatee = (delegation.delegatee == msg.sender && block.timestamp <= delegation.expirationTimestamp);

        require(isApprovedOrOwner || isDelegatee, ChronoSphere__NotSphereOwnerOrApprovedOrDelegatee(sphereId, msg.sender));

        SphereData storage sphere = s_sphereData[sphereId];
        uint256 currentEnergy = _updateSphereEnergy(sphereId); // Sync energy first

        // Determine harvested amount (e.g., proportional to current energy, or fixed amount)
        // Let's make it a simple percentage of current energy, but leave at least 1 energy
        uint256 energyToHarvest = currentEnergy / 5; // Example: Harvest 20% of current energy
        if (energyToHarvest == 0 && currentEnergy > 0) {
             energyToHarvest = 1; // Ensure at least 1 is harvested if energy > 0
        }
        require(energyToHarvest > 0, ChronoSphere__NotEnoughEnergy(sphereId, 1, currentEnergy));

        sphere.currentEnergy -= energyToHarvest;
        harvestedAmount = energyToHarvest; // This could represent a resource token amount or points

        emit EnergyHarvested(sphereId, msg.sender, harvestedAmount, sphere.currentEnergy);
        return harvestedAmount;
    }

    function getHarvestAmount(uint256 sphereId) public view returns (uint256 possibleHarvestAmount) {
         uint256 currentEnergy = _calculateCurrentEnergy(sphereId);
         uint256 energyToHarvest = currentEnergy / 5;
         if (energyToHarvest == 0 && currentEnergy > 0) {
             energyToHarvest = 1;
         }
         return energyToHarvest;
    }


    // --- Utility Delegation (Rental/Access) ---
    function delegateUtilityAccess(uint256 sphereId, address delegatee, uint64 durationSeconds) external whenNotPausedAndOperational(sphereId) {
        require(ownerOf(sphereId) == msg.sender, "ChronoSphere: Not owner");
        require(delegatee != address(0), "ChronoSphere: Cannot delegate to zero address");
        require(s_utilityDelegation[sphereId].delegatee == address(0) || block.timestamp > s_utilityDelegation[sphereId].expirationTimestamp, ChronoSphere__UtilityDelegationAlreadyActive(sphereId, s_utilityDelegation[sphereId].delegatee));

        uint64 expiration = uint64(block.timestamp) + durationSeconds;
        s_utilityDelegation[sphereId] = UtilityDelegation({
            delegatee: delegatee,
            expirationTimestamp: expiration
        });

        emit UtilityDelegated(sphereId, delegatee, expiration);
    }

    function revokeUtilityAccess(uint256 sphereId) external whenNotPausedAndOperational(sphereId) {
        require(ownerOf(sphereId) == msg.sender, "ChronoSphere: Not owner");
         require(s_utilityDelegation[sphereId].delegatee != address(0) && block.timestamp <= s_utilityDelegation[sphereId].expirationTimestamp, ChronoSphere__UtilityDelegationNotActive(sphereId, s_utilityDelegation[sphereId].delegatee));

        address revokedDelegatee = s_utilityDelegation[sphereId].delegatee;
        delete s_utilityDelegation[sphereId];

        emit UtilityDelegationRevoked(sphereId, revokedDelegatee);
    }

    function getUtilityDelegatee(uint256 sphereId) public view returns (address delegatee, uint64 expirationTimestamp) {
        UtilityDelegation storage delegation = s_utilityDelegation[sphereId];
        if (delegation.delegatee != address(0) && block.timestamp <= delegation.expirationTimestamp) {
            return (delegation.delegatee, delegation.expirationTimestamp);
        } else {
            return (address(0), 0); // No active delegation
        }
    }

    function isUtilityDelegatee(uint256 sphereId, address account) public view returns (bool) {
        UtilityDelegation storage delegation = s_utilityDelegation[sphereId];
        return (delegation.delegatee == account && block.timestamp <= delegation.expirationTimestamp);
    }


    // --- On-Chain Evolution (Refine/Merge) ---

    /**
     * @notice Refine a ChronoSphere, potentially upgrading its properties or tier.
     * @dev Burns the input sphere, requires ETH payment as refining cost. Simulates output params.
     * @param sphereId The ID of the sphere to refine.
     * @param refiningCost The expected ETH cost for this refining attempt.
     */
    function refineSphere(uint256 sphereId, uint256 refiningCost) external payable whenNotPausedAndOperational(sphereId) {
        require(ownerOf(sphereId) == msg.sender, "ChronoSphere: Not owner");
        SphereData storage sphere = s_sphereData[sphereId];
        uint256 expectedCost = s_refiningCosts[sphere.tier];
        require(msg.value >= expectedCost, ChronoSphere__RefiningCostMismatch(expectedCost, msg.value));
        require(refiningCost == expectedCost, ChronoSphere__RefiningCostMismatch(expectedCost, refiningCost)); // Check caller provided correct expected cost

        uint256 oldSphereId = sphereId;
        address oldOwner = msg.sender; // ownerOf(sphereId) before burning

        // Simulate refinement outcome (simplified: maybe increase stats or tier probabilistically)
        // In a real application, this could use Chainlink VRF or complex deterministic logic.
        // Here, we'll just simulate an increase based on tier.
        uint256 newTier = sphere.tier;
        uint256 newMaxEnergy = sphere.maxEnergy + s_tierProperties[sphere.tier].baseMaxEnergy / 10; // Example: +10% of base max
        uint256 newReplenishmentRate = sphere.replenishmentRatePerSecond + s_tierProperties[sphere.tier].baseReplenishmentRatePerSecond / 10; // Example: +10% of base rate

        // Chance to upgrade tier? (Simple example: 20% chance)
        // For randomness, integrate Chainlink VRF
        // If VRF integrated: request random words, implement fulfillment, trigger refinement in fulfillRandomWords
        // For this example, we'll skip true randomness to keep it self-contained.
        // Let's make refinement *always* slightly improve stats but never change tier directly.
        // Merging can handle tier upgrades.

        // Burn the old sphere
        _burn(oldSphereId);

        // Mint a new sphere with the refined properties (or update in place if not changing ID)
        // Updating in place is simpler if ID doesn't change, but less common for "crafting" results.
        // Let's mint a new ID to represent transformation.
        uint256 newSphereId = s_nextTokenId++;
        _safeMint(oldOwner, newSphereId);

        s_sphereData[newSphereId] = SphereData({
            tier: newTier,
            currentEnergy: newMaxEnergy / 2, // Start with half energy after refinement
            maxEnergy: newMaxEnergy,
            replenishmentRatePerSecond: newReplenishmentRate,
            lastSyncTimestamp: uint64(block.timestamp)
        });

        emit SphereRefined(oldSphereId, newSphereId, newTier, newMaxEnergy, newReplenishmentRate);
    }

    function getRefinedSphereParams(uint256 sphereId) public view returns (uint256 predictedNewTier, uint256 predictedNewMaxEnergy, uint256 predictedNewReplenishmentRate) {
         require(_exists(sphereId), ChronoSphere__SphereDoesNotExist(sphereId));
         SphereData storage sphere = s_sphereData[sphereId];
         // Simulate the same logic as in refineSphere for prediction
         predictedNewTier = sphere.tier; // Refine doesn't change tier in this sim
         predictedNewMaxEnergy = sphere.maxEnergy + s_tierProperties[sphere.tier].baseMaxEnergy / 10;
         predictedNewReplenishmentRate = sphere.replenishmentRatePerSecond + s_tierProperties[sphere.tier].baseReplenishmentRatePerSecond / 10;
         // Note: Actual result in refineSphere might differ if randomness was used
    }


    /**
     * @notice Merge two ChronoSpheres into one, potentially creating a higher-tier sphere.
     * @dev Burns the two input spheres, requires ETH payment as merging cost. Simulates output params.
     * @param sphereId1 The ID of the first sphere.
     * @param sphereId2 The ID of the second sphere.
     * @param mergeCost The expected ETH cost for this merge attempt.
     */
    function mergeSpheres(uint256 sphereId1, uint256 sphereId2, uint256 mergeCost) external payable whenNotPausedAndOperational(sphereId1, sphereId2) {
        require(sphereId1 != sphereId2, ChronoSphere__CannotMergeSameSphere(sphereId1));
        require(ownerOf(sphereId1) == msg.sender, "ChronoSphere: Not owner of first sphere");
        require(ownerOf(sphereId2) == msg.sender, "ChronoSphere: Not owner of second sphere");

        SphereData storage sphere1 = s_sphereData[sphereId1];
        SphereData storage sphere2 = s_sphereData[sphereId2];

        // Sort tiers for consistent hash lookup
        (uint256 tierA, uint256 tierB) = sphere1.tier <= sphere2.tier ? (sphere1.tier, sphere2.tier) : (sphere2.tier, sphere1.tier);
        bytes32 mergeKey = keccak256(abi.encodePacked(tierA, tierB));

        uint256 expectedCost = s_mergeCosts[mergeKey];
        require(msg.value >= expectedCost, ChronoSphere__MergeCostMismatch(expectedCost, msg.value));
        require(mergeCost == expectedCost, ChronoSphere__MergeCostMismatch(expectedCost, mergeCost)); // Check caller provided correct expected cost

        address owner = msg.sender; // ownerOf both spheres

        // Simulate merge outcome (simplified: new tier is Max(tier1, tier2) + 1, capped, stats are average/sum)
        uint256 newTier = Math.min(Math.max(sphere1.tier, sphere2.tier) + 1, 5); // Example: Max tier is 5
        uint256 newMaxEnergy = (sphere1.maxEnergy + sphere2.maxEnergy) / 2;
        uint256 newReplenishmentRate = (sphere1.replenishmentRatePerSecond + sphere2.replenishmentRatePerSecond) / 2;

        // Burn the input spheres
        _burn(sphereId1);
        _burn(sphereId2);

        // Mint the new sphere
        uint256 newSphereId = s_nextTokenId++;
        _safeMint(owner, newSphereId);

        s_sphereData[newSphereId] = SphereData({
            tier: newTier,
            currentEnergy: newMaxEnergy / 2, // Start with half energy
            maxEnergy: newMaxEnergy,
            replenishmentRatePerSecond: newReplenishmentRate,
            lastSyncTimestamp: uint64(block.timestamp)
        });

        emit SphereMerged(sphereId1, sphereId2, newSphereId, newTier);
    }

     function getMergedSphereParams(uint256 sphereId1, uint256 sphereId2) public view returns (uint256 predictedNewTier, uint256 predictedNewMaxEnergy, uint256 predictedNewReplenishmentRate) {
        require(_exists(sphereId1), ChronoSphere__SphereDoesNotExist(sphereId1));
        require(_exists(sphereId2), ChronoSphere__SphereDoesNotExist(sphereId2));
         require(sphereId1 != sphereId2, ChronoSphere__CannotMergeSameSphere(sphereId1));

         SphereData storage sphere1 = s_sphereData[sphereId1];
         SphereData storage sphere2 = s_sphereData[sphereId2];

         predictedNewTier = Math.min(Math.max(sphere1.tier, sphere2.tier) + 1, 5);
         predictedNewMaxEnergy = (sphere1.maxEnergy + sphere2.maxEnergy) / 2;
         predictedNewReplenishmentRate = (sphere1.replenishmentRatePerSecond + sphere2.replenishmentRatePerSecond) / 2;
         // Note: Actual result in mergeSpheres might differ if randomness was used
     }


    // --- Admin Configuration ---
    function setTierProperties(uint256 tier, uint256 baseMaxEnergy, uint256 baseReplenishmentRatePerSecond) external onlyApprovedManager {
        require(tier > 0, "ChronoSphere: Tier must be greater than 0");
        s_tierProperties[tier] = TierProperties({
            baseMaxEnergy: baseMaxEnergy,
            baseReplenishmentRatePerSecond: baseReplenishmentRatePerSecond
        });
        emit TierPropertiesUpdated(tier, baseMaxEnergy, baseReplenishmentRatePerSecond);
    }

    function setRefiningCost(uint256 tier, uint256 costInWei) external onlyApprovedManager {
         require(tier > 0, "ChronoSphere: Tier must be greater than 0");
         s_refiningCosts[tier] = costInWei;
         emit RefiningCostUpdated(tier, costInWei);
    }

    function setMergeCost(uint256 tier1, uint256 tier2, uint256 costInWei) external onlyApprovedManager {
        require(tier1 > 0 && tier2 > 0, "ChronoSphere: Tiers must be greater than 0");
        // Store cost using sorted tiers for consistent lookup
        (uint256 tierA, uint256 tierB) = tier1 <= tier2 ? (tier1, tier2) : (tier2, tier1);
        bytes32 mergeKey = keccak256(abi.encodePacked(tierA, tierB));
        s_mergeCosts[mergeKey] = costInWei;
        emit MergeCostUpdated(tierA, tierB, costInWei);
    }

    function getRefiningCost(uint256 tier) public view returns (uint256) {
         return s_refiningCosts[tier];
    }

     function getMergeCost(uint256 tier1, uint256 tier2) public view returns (uint256) {
        (uint256 tierA, uint256 tierB) = tier1 <= tier2 ? (tier1, tier2) : (tier2, tier1);
        bytes32 mergeKey = keccak256(abi.encodePacked(tierA, tierB));
        return s_mergeCosts[mergeKey];
    }

    // --- Fee Management ---
    // Receive ETH sent with refine/merge calls
    receive() external payable {}

    // Withdraw collected ETH fees
    function withdrawAdminFees(address payable recipient) external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "ChronoSphere: No fees to withdraw");
        (bool success, ) = recipient.call{value: balance}("");
        require(success, "ChronoSphere: ETH withdrawal failed");
        emit AdminFeesWithdrawn(recipient, balance);
    }

    // --- Internal Helper for Ownership/Approval check ---
     function _isApprovedOrOwner(address owner, address spender) internal view returns (bool) {
        return (spender == owner || isApprovedForAll(owner, spender) || getApproved(s_sphereData[EnumerableSet.uint256Set.at(ERC721Enumerable.tokensOfOwner(owner), 0)].tier) == spender); // Simplified check - only checks first token for specific approval
        // A proper check would iterate through owned tokens or use a different approval mechanism
        // For ERC721, standard `_isApprovedOrOwner` is internal to OZ and sufficient for ERC721 methods.
        // We need a custom one to check for *utility* delegation too.
        // Let's just check owner or operator for simplicity here.
        // The `harvestEnergy` check covers delegatee separately.
        return (spender == owner || isApprovedForAll(owner, spender));
    }
}
```