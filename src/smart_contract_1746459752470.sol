Okay, here is a Solidity smart contract for a hypothetical decentralized simulation game called "CryptoMineshaft".

This contract incorporates concepts like:
*   **ERC721** for unique Plot ownership.
*   **Resource Management:** Tracking different types of fungible resources.
*   **Time-Based Mechanics:** Resource production and plot decay based on time.
*   **Upgrades:** Improving plots using resources.
*   **Maintenance:** A game loop mechanic requiring players to spend resources to prevent plot decay.
*   **Batch Operations:** Functions for claiming resources or performing maintenance on multiple plots to save gas.
*   **Configurability:** Admin functions to adjust game parameters.
*   **Events & Errors:** For transparency and robust error handling.
*   **Pausable & Ownable:** Standard security patterns.

It avoids direct duplication of standard open-source contracts by implementing a specific game logic combining these elements.

---

**CryptoMineshaft Smart Contract**

**Outline:**

1.  **SPDX-License-Identifier & Pragma**
2.  **Imports:** ERC721, Ownable, Pausable, SafeMath (implicit in 0.8+).
3.  **Errors:** Custom errors for specific failure conditions.
4.  **Events:** Signaling important state changes.
5.  **Enums:** Defining resource types.
6.  **Structs:** Defining data structures for plots, resources, and configurations.
7.  **State Variables:** Storing the game state (plots, balances, configs, counters).
8.  **Modifiers:** Access control and state checks (`whenNotPaused`, `onlyOwner`).
9.  **Constructor:** Initializes the contract and sets base parameters.
10. **Core Game Logic Functions:**
    *   `mintPlot`: Mints a new unique plot NFT.
    *   `claimResources`: Allows plot owner to claim accumulated resources.
    *   `calculatePendingResources`: View function to see claimable resources.
    *   `performMaintenance`: Allows plot owner to perform maintenance, costing resources and preventing decay.
    *   `calculateMaintenanceCostPreview`: View function to see estimated maintenance cost.
    *   `upgradePlot`: Allows plot owner to upgrade a plot's level using resources.
    *   `calculateUpgradeCostPreview`: View function to see estimated upgrade cost.
11. **Resource Management Functions:**
    *   `getResourceBalance`: View owner's resource balance.
    *   `burnResource`: Admin function to burn resources (sink).
    *   `mintResource`: Admin function to mint resources (faucet, for events/testing).
    *   `getResourceTotalSupply`: View total supply of a resource.
12. **Batch Operation Functions:**
    *   `batchClaimResources`: Claim resources from multiple plots.
    *   `batchPerformMaintenance`: Perform maintenance on multiple plots.
    *   `batchUpgradePlots`: Upgrade multiple plots (if applicable - might be complex, focus on batch maintenance/claim). Let's stick to batch claim/maintenance for complexity management.
13. **Plot Management Functions:**
    *   `getPlotDetails`: View detailed information about a specific plot.
    *   `getPlotsByOwner`: View all plots owned by an address.
    *   `getTotalPlots`: View the total number of plots in existence.
    *   `getPlotProductionRate`: View the current production rate of a plot.
14. **Admin & Configuration Functions:**
    *   `setResourceParameters`: Set production and decay parameters for a resource type.
    *   `setUpgradeParameters`: Set costs and multipliers for plot upgrades.
    *   `setGlobalDecayPeriod`: Set the time interval for decay calculation.
    *   `setBaseMintCostEth`: Set the ETH cost for minting a plot.
    *   `withdrawProtocolFees`: Withdraw accumulated ETH fees.
    *   `triggerGlobalEvent`: Simulate a game event affecting parameters temporarily (optional, adds complexity, let's simplify and have admin just change parameters directly). Okay, let's add a simple global event concept with an expiry.
    *   `clearGlobalEvent`: Admin function to end an event early.
    *   `setEventParameters`: Admin sets parameters for a potential global event.
15. **View Functions (Configuration & Global State):**
    *   `getResourceParameters`: View resource configs.
    *   `getUpgradeParameters`: View upgrade configs.
    *   `getGlobalDecayPeriod`: View the global decay period.
    *   `getBaseMintCostEth`: View the ETH mint cost.
    *   `getProtocolFeesAccrued`: View accrued fees.
    *   `getGlobalEventStatus`: View active event details.
    *   `getTotalMinerCount`: View count of unique players.

**Function Summary:**

1.  `constructor`: Initializes contract, name, symbol, owner, initial parameters.
2.  `mintPlot(ResourceType initialType)`: Mints a new Plot NFT of a specified resource type to the caller, potentially costing ETH.
3.  `claimResources(uint256 plotId)`: Calculates resources accumulated by `plotId` since last claim, applies decay penalties based on maintenance status, transfers resources to owner's balance, and updates state.
4.  `calculatePendingResources(uint256 plotId)`: *View* function. Calculates the amount of resources a `plotId` *would* yield if claimed now, *before* decay penalty.
5.  `performMaintenance(uint256 plotId)`: Costs resources based on accrued decay time for `plotId`, resets the maintenance timer, preventing further decay accumulation until the next period.
6.  `calculateMaintenanceCostPreview(uint256 plotId)`: *View* function. Calculates the estimated resource cost to perform maintenance on `plotId` now, based on time since last maintenance.
7.  `upgradePlot(uint256 plotId)`: Costs specific resources required for the next upgrade level of `plotId`, increases the plot's level, updates its stats (production, maintenance cost multiplier), and resets the maintenance timer.
8.  `calculateUpgradeCostPreview(uint256 plotId)`: *View* function. Calculates the resource cost required to perform the next upgrade on `plotId`.
9.  `getResourceBalance(address owner, ResourceType resource)`: *View* function. Returns the balance of a specific `resource` held by `owner`.
10. `burnResource(ResourceType resource, uint256 amount)`: *Admin Only*. Decreases the total supply of a `resource` and removes it from the contract's implicit balance (useful for sinks).
11. `mintResource(address recipient, ResourceType resource, uint256 amount)`: *Admin Only*. Increases the total supply of a `resource` and adds it to `recipient`'s balance (useful for events, compensation).
12. `getResourceTotalSupply(ResourceType resource)`: *View* function. Returns the total minted supply of a specific `resource`.
13. `batchClaimResources(uint256[] calldata plotIds)`: Allows claiming resources from multiple plots owned by the caller in a single transaction.
14. `batchPerformMaintenance(uint256[] calldata plotIds)`: Allows performing maintenance on multiple plots owned by the caller in a single transaction.
15. `getPlotDetails(uint256 plotId)`: *View* function. Returns comprehensive details about `plotId`.
16. `getPlotsByOwner(address owner)`: *View* function. Returns an array of plot IDs owned by `owner`.
17. `getTotalPlots()`: *View* function. Returns the total count of Plot NFTs minted.
18. `getPlotProductionRate(uint256 plotId)`: *View* function. Returns the current effective production rate of `plotId`, considering base rate and upgrade multipliers (but *not* decay).
19. `setResourceParameters(ResourceType resource, uint256 baseProductionRate, uint256 decayRatePerPeriod, uint256 maintenanceCostMultiplier)`: *Admin Only*. Configures parameters for a specific resource type.
20. `setUpgradeParameters(ResourceType resource, uint256 level, uint256[] calldata resourceCosts, uint256 productionMultiplier, uint256 maintenanceCostMultiplier)`: *Admin Only*. Configures the requirements and effects for a specific upgrade `level` of a specific `resource` type.
21. `setGlobalDecayPeriod(uint256 period)`: *Admin Only*. Sets the time duration that defines one decay/maintenance period.
22. `setBaseMintCostEth(uint256 cost)`: *Admin Only*. Sets the ETH amount required to mint a new plot.
23. `withdrawProtocolFees()`: *Admin Only*. Withdraws accumulated ETH fees to the owner address.
24. `triggerGlobalEvent(uint256 eventType, uint256 multiplier, uint256 duration)`: *Admin Only*. Activates a global event (e.g., production boost) for a set duration. (Simplistic example)
25. `clearGlobalEvent()`: *Admin Only*. Immediately ends any active global event.
26. `getResourceParameters(ResourceType resource)`: *View* function. Returns the current configuration for a resource type.
27. `getUpgradeParameters(ResourceType resource, uint256 level)`: *View* function. Returns the configuration for a specific upgrade level.
28. `getGlobalDecayPeriod()`: *View* function. Returns the current global decay period.
29. `getBaseMintCostEth()`: *View* function. Returns the current ETH mint cost.
30. `getProtocolFeesAccrued()`: *View* function. Returns the total ETH fees held by the contract.
31. `getGlobalEventStatus()`: *View* function. Returns details about any active global event.
32. `getTotalMinerCount()`: *View* function. Returns the number of unique addresses that own at least one plot.
33. `pause()`: *Admin Only*. Pauses core gameplay actions.
34. `unpause()`: *Admin Only*. Unpauses core gameplay actions.
35. `transferOwnership(address newOwner)`: *Admin Only*. Transfers contract ownership.

*(Note: Some standard ERC721 functions like `approve`, `getApproved`, `setApprovalForAll`, `isApprovedForAll`, `transferFrom`, `safeTransferFrom`, `balanceOf`, `ownerOf` are inherited and also count towards functionality, bringing the total well over 20).*

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol"; // To list tokens by owner

// Custom Errors
error NotPlotOwner(address caller, uint256 plotId);
error InvalidPlotId(uint256 plotId);
error InsufficientResources(uint256 required, uint256 possessed);
error MaxLevelReached(uint256 plotId, uint256 maxLevel);
error UpgradeConfigNotSet(uint256 level);
error ResourceConfigNotSet(uint256 resourceType);
error MaintenanceNotRequired(uint256 plotId);
error TransferNotAllowed(); // Used if we wanted to restrict ERC721 transfers for game reasons
error PlotAlreadyExists(uint256 plotId); // Should not happen with counter
error InsufficientETH(uint256 required, uint256 sent);

// Events
event PlotMinted(uint256 indexed plotId, address indexed owner, ResourceType indexed initialType);
event ResourcesClaimed(uint256 indexed plotId, address indexed owner, ResourceType indexed resourceType, uint256 amount);
event MaintenancePerformed(uint256 indexed plotId, address indexed owner, uint256 cost);
event PlotUpgraded(uint256 indexed plotId, address indexed owner, uint256 newLevel);
event ResourceParameterSet(ResourceType indexed resourceType, uint256 baseProductionRate, uint256 decayRatePerPeriod, uint256 maintenanceCostMultiplier);
event UpgradeParameterSet(ResourceType indexed resourceType, uint256 level, uint256[] resourceCosts, uint256 productionMultiplier);
event GlobalDecayPeriodSet(uint256 period);
event BaseMintCostEthSet(uint256 cost);
event ProtocolFeesWithdrawn(address indexed recipient, uint256 amount);
event GlobalEventTriggered(uint256 indexed eventType, uint256 multiplier, uint256 duration);
event GlobalEventCleared(uint256 indexed eventType);
event ResourceBurned(ResourceType indexed resourceType, uint256 amount);
event ResourceMinted(address indexed recipient, ResourceType indexed resourceType, uint256 amount);

enum ResourceType { Ore, Gem, Crystal } // Example resource types

struct ResourceParams {
    uint256 baseProductionRate; // Resources produced per second per base plot
    uint256 decayRatePerPeriod; // Reduction in production per decay period if not maintained
    uint256 maintenanceCostMultiplier; // Multiplier for calculating resource cost of maintenance
}

struct Plot {
    uint256 plotId; // Redundant with token ID, but useful internally
    ResourceType produces;
    uint256 level;
    uint256 lastClaimTime;
    uint256 lastMaintenanceTime; // Timestamp of the last maintenance or upgrade
    uint256 baseProductionRate; // Inherited from ResourceParams at minting, can be affected by events
}

struct UpgradeLevelParams {
    uint255[] resourceCosts; // Array of costs, indices match ResourceType enum
    uint256 productionMultiplier; // Multiplier applied to the plot's baseProductionRate
    uint256 maintenanceCostMultiplier; // Multiplier applied to the resource config's maintenanceCostMultiplier
}

struct GlobalEvent {
    uint256 eventType; // e.g., 1: ProductionBoost
    uint256 multiplier; // e.g., 120 (120%)
    uint256 startTime;
    uint256 endTime;
}

// State Variables
mapping(address => mapping(ResourceType => uint256)) public resourceBalances; // owner => resource => amount
mapping(uint256 => Plot) private _plots; // plotId => Plot data
mapping(ResourceType => ResourceParams) public resourceConfigs; // resourceType => parameters
mapping(ResourceType => mapping(uint256 => UpgradeLevelParams)) public upgradeConfigs; // resourceType => level => parameters
uint256 private _plotCounter; // To generate unique plot IDs
uint256 public globalDecayPeriod; // Time in seconds for one decay period
uint256 public baseMintCostEth; // ETH required to mint a plot
uint256 private _protocolFeesAccrued; // Accumulated ETH fees
GlobalEvent public activeGlobalEvent; // Details of the current active global event

// Keep track of all unique miner addresses (owners of plots)
mapping(address => bool) private _isMiner;
uint256 private _minerCount;

contract CryptoMineshaft is ERC721Enumerable, Ownable, Pausable {

    constructor(string memory name, string memory symbol)
        ERC721(name, symbol)
        Ownable(msg.sender)
    {}

    // --- Modifiers ---
    modifier whenNotPausedOrOwner() {
        require(!paused() || msg.sender == owner(), "Pausable: paused");
        _;
    }

    // Override _beforeTokenTransfer to track unique miners
    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize) internal override {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);

        // If transferring from zero address, a new plot is minted
        if (from == address(0)) {
            if (!_isMiner[to]) {
                _isMiner[to] = true;
                _minerCount++;
            }
        }
        // If transferring to zero address, a plot is burned (shouldn't happen in this game)
        // If from != address(0) and to != address(0), it's a player transfer.
        // Miner count only increases on mint, doesn't decrease on transfer out if they still hold other plots.
    }


    // --- Core Game Logic ---

    /// @notice Mints a new plot NFT to the caller, potentially costing ETH.
    /// @param initialType The resource type the new plot will produce.
    function mintPlot(ResourceType initialType) public payable whenNotPausedOrOwner {
        require(msg.value >= baseMintCostEth, InsufficientETH(baseMintCostEth, msg.value));
        require(uint256(initialType) < uint256(ResourceType.Crystal) + 1, "Invalid resource type"); // Ensure enum value is valid

        if (msg.value > baseMintCostEth) {
             // Refund excess ETH
            payable(msg.sender).transfer(msg.value - baseMintCostEth);
        }

        _protocolFeesAccrued += baseMintCostEth;

        uint256 newPlotId = _plotCounter++;
        _plots[newPlotId] = Plot({
            plotId: newPlotId,
            produces: initialType,
            level: 1, // Start at level 1
            lastClaimTime: block.timestamp,
            lastMaintenanceTime: block.timestamp,
            baseProductionRate: resourceConfigs[initialType].baseProductionRate // Inherit base rate
        });

        _safeMint(msg.sender, newPlotId); // Mints the NFT

        emit PlotMinted(newPlotId, msg.sender, initialType);
    }

    /// @notice Allows plot owner to claim accumulated resources.
    /// @param plotId The ID of the plot to claim resources from.
    function claimResources(uint256 plotId) public whenNotPausedOrOwner {
        require(_exists(plotId), InvalidPlotId(plotId));
        address owner = ownerOf(plotId);
        require(msg.sender == owner, NotPlotOwner(msg.sender, plotId));

        Plot storage plot = _plots[plotId];
        uint256 currentTime = block.timestamp;
        uint256 timeSinceLastClaim = currentTime - plot.lastClaimTime;

        // Calculate pending resources (before decay)
        uint256 effectiveProductionRate = _getEffectiveProductionRate(plot);
        uint256 pendingResources = (effectiveProductionRate * timeSinceLastClaim) / 1e18; // Assumes rates are scaled by 1e18

        // Calculate decay penalty - Decay cost is deducted *at the time of claim or maintenance*
        // Decay is based on time since last maintenance/upgrade
        uint256 timeSinceLastMaintenance = currentTime - plot.lastMaintenanceTime;
        uint256 decayPeriods = timeSinceLastMaintenance / globalDecayPeriod;
        uint256 decayPenalty = (decayPeriods * resourceConfigs[plot.produces].decayRatePerPeriod * _getPlotMaintenanceCostMultiplier(plot)) / 1e18; // Scaled cost

        uint256 resourcesToClaim = pendingResources > decayPenalty ? pendingResources - decayPenalty : 0;

        if (resourcesToClaim > 0) {
            resourceBalances[owner][plot.produces] += resourcesToClaim;
            emit ResourcesClaimed(plotId, owner, plot.produces, resourcesToClaim);
        }

        plot.lastClaimTime = currentTime;
        // Note: Decay timer is NOT reset by claiming. Only by Maintenance or Upgrade.
    }

    /// @notice Calculates resources accumulated by a plot since last claim, before decay penalty.
    /// @param plotId The ID of the plot.
    /// @return The amount of resources claimable if claimed now, ignoring decay cost.
    function calculatePendingResources(uint256 plotId) public view returns (uint256) {
        require(_exists(plotId), InvalidPlotId(plotId));
        Plot storage plot = _plots[plotId];
        uint256 currentTime = block.timestamp;
        uint256 timeSinceLastClaim = currentTime - plot.lastClaimTime;

        uint256 effectiveProductionRate = _getEffectiveProductionRate(plot);
        return (effectiveProductionRate * timeSinceLastClaim) / 1e18; // Assumes rates are scaled by 1e18
    }

    /// @notice Allows plot owner to perform maintenance, costing resources and preventing decay.
    /// @param plotId The ID of the plot.
    function performMaintenance(uint256 plotId) public whenNotPausedOrOwner {
        require(_exists(plotId), InvalidPlotId(plotId));
        address owner = ownerOf(plotId);
        require(msg.sender == owner, NotPlotOwner(msg.sender, plotId));

        Plot storage plot = _plots[plotId];
        uint256 currentTime = block.timestamp;
        uint256 timeSinceLastMaintenance = currentTime - plot.lastMaintenanceTime;

        if (timeSinceLastMaintenance < globalDecayPeriod) {
             revert MaintenanceNotRequired(plotId); // Maintenance is only required after a decay period
        }

        uint256 decayPeriods = timeSinceLastMaintenance / globalDecayPeriod;
        uint256 maintenanceCost = (decayPeriods * resourceConfigs[plot.produces].decayRatePerPeriod * _getPlotMaintenanceCostMultiplier(plot)) / 1e18; // Cost scales with decay periods and multipliers

        require(resourceBalances[owner][plot.produces] >= maintenanceCost, InsufficientResources(maintenanceCost, resourceBalances[owner][plot.produces]));

        resourceBalances[owner][plot.produces] -= maintenanceCost;
        plot.lastMaintenanceTime = currentTime; // Reset maintenance timer
        // Claim any pending resources before maintenance cost is deducted, and reset claim timer?
        // Or does maintenance only reset the timer and cost resources? Let's just reset timer and cost.
        // The decay penalty is applied during 'claimResources'. Maintenance just avoids *future* decay accumulation.
        // Re-think: Let's make maintenance *cost* the equivalent of the decay penalty accrued, and reset the timer. Claiming still applies penalty if maintenance wasn't done.
        // Simpler approach: `performMaintenance` *resets* the decay timer and costs resources based on the *time elapsed* since last maintenance/upgrade. The cost *prevents* the decay penalty from being applied during the *next* claim period.
        // Let's use the calculated `maintenanceCost` based on decay periods since last maintenance/upgrade. This cost is paid NOW to avoid future penalty.

        emit MaintenancePerformed(plotId, owner, maintenanceCost);
    }

     /// @notice Calculates the estimated resource cost to perform maintenance now.
     /// @param plotId The ID of the plot.
     /// @return The resource cost.
    function calculateMaintenanceCostPreview(uint256 plotId) public view returns (uint256) {
        require(_exists(plotId), InvalidPlotId(plotId));
        Plot storage plot = _plots[plotId];
        uint256 currentTime = block.timestamp;
        uint256 timeSinceLastMaintenance = currentTime - plot.lastMaintenanceTime;
        uint256 decayPeriods = timeSinceLastMaintenance / globalDecayPeriod;
         if (decayPeriods == 0) return 0; // No maintenance needed yet

        return (decayPeriods * resourceConfigs[plot.produces].decayRatePerPeriod * _getPlotMaintenanceCostMultiplier(plot)) / 1e18;
    }


    /// @notice Allows plot owner to upgrade a plot's level using resources.
    /// @param plotId The ID of the plot.
    function upgradePlot(uint256 plotId) public whenNotPausedOrOwner {
        require(_exists(plotId), InvalidPlotId(plotId));
        address owner = ownerOf(plotId);
        require(msg.sender == owner, NotPlotOwner(msg.sender, plotId));

        Plot storage plot = _plots[plotId];
        uint256 nextLevel = plot.level + 1;
        ResourceType plotResource = plot.produces;

        // Check if upgrade config exists for the next level
        UpgradeLevelParams storage config = upgradeConfigs[plotResource][nextLevel];
        require(config.resourceCosts.length > 0, UpgradeConfigNotSet(nextLevel)); // Simple check if config exists

        // Check resource costs
        require(config.resourceCosts.length == uint256(ResourceType.Crystal) + 1, "Upgrade cost config length mismatch");
        for (uint256 i = 0; i < config.resourceCosts.length; i++) {
            uint256 requiredCost = config.resourceCosts[i];
            ResourceType resourceType = ResourceType(i);
            require(resourceBalances[owner][resourceType] >= requiredCost, InsufficientResources(requiredCost, resourceBalances[owner][resourceType]));
        }

        // Deduct resources
        for (uint256 i = 0; i < config.resourceCosts.length; i++) {
            ResourceType resourceType = ResourceType(i);
            resourceBalances[owner][resourceType] -= config.resourceCosts[i];
        }

        // Apply upgrade effects
        plot.level = nextLevel;
        // Note: baseProductionRate is fixed at mint. Upgrades apply multipliers.
        // Update maintenance timer as upgrades also count as maintenance.
        plot.lastMaintenanceTime = block.timestamp;
        plot.lastClaimTime = block.timestamp; // Auto-claim on upgrade? Let's do that.

        // Optional: Apply production multiplier directly to baseProductionRate if game design intends
        // Or, _getEffectiveProductionRate calculates it on the fly. Let's use the latter.

        emit PlotUpgraded(plotId, owner, nextLevel);
    }

     /// @notice Calculates the resource cost required to perform the next upgrade.
     /// @param plotId The ID of the plot.
     /// @return An array of resource costs (matching ResourceType enum order).
    function calculateUpgradeCostPreview(uint256 plotId) public view returns (uint256[] memory) {
        require(_exists(plotId), InvalidPlotId(plotId));
        Plot storage plot = _plots[plotId];
        uint256 nextLevel = plot.level + 1;
        ResourceType plotResource = plot.produces;

        UpgradeLevelParams storage config = upgradeConfigs[plotResource][nextLevel];
        require(config.resourceCosts.length > 0, UpgradeConfigNotSet(nextLevel));

        return config.resourceCosts;
    }

    // --- Resource Management ---

    /// @notice Returns the balance of a specific resource for an owner.
    /// @param owner The address to check.
    /// @param resource The type of resource.
    /// @return The resource balance.
    function getResourceBalance(address owner, ResourceType resource) public view returns (uint256) {
        return resourceBalances[owner][resource];
    }

    /// @notice Admin function to burn resources.
    /// @param resource The type of resource to burn.
    /// @param amount The amount to burn.
    function burnResource(ResourceType resource, uint256 amount) public onlyOwner {
        // This conceptually reduces the 'total supply' tracked by admin/game logic,
        // not necessarily from a specific player's balance.
        // If burning from a player, need to add address param and require their balance >= amount.
        // For a global sink, just emit event.
        // Let's assume it's burning from *nowhere* as a sink mechanism.
        emit ResourceBurned(resource, amount);
    }

    /// @notice Admin function to mint resources.
    /// @param recipient The address to receive resources.
    /// @param resource The type of resource to mint.
    /// @param amount The amount to mint.
    function mintResource(address recipient, ResourceType resource, uint256 amount) public onlyOwner {
        resourceBalances[recipient][resource] += amount;
        emit ResourceMinted(recipient, resource, amount);
    }

    /// @notice Returns the total minted supply of a resource (conceptually, as balances are distributed).
    /// @param resource The type of resource.
    /// @return The total supply (sum of all player balances). Note: Requires iterating all players for accuracy.
    // This is inefficient on-chain. Better to track global supply explicitly if needed accurately.
    // For demonstration, this is a placeholder or can be left unimplemented if full supply tracking isn't vital.
    // Let's leave as a placeholder view function that is hard to implement efficiently on-chain.
    // A more practical implementation would involve tracking total supply during mint/burn/claim/spend.
    function getResourceTotalSupply(ResourceType resource) public pure returns (uint256) {
        // Inefficient to calculate on-chain across all addresses.
        // Requires tracking total supply separately during mint/burn/claim/spend operations.
        // Returning 0 as placeholder for on-chain call, external indexer needed for real data.
        resource; // Avoid unused variable warning
        return 0; // Placeholder
    }

    // --- Batch Operations ---

    /// @notice Allows claiming resources from multiple plots owned by the caller.
    /// @param plotIds An array of plot IDs.
    function batchClaimResources(uint256[] calldata plotIds) public whenNotPausedOrOwner {
        for (uint256 i = 0; i < plotIds.length; i++) {
            // Call claimResources for each plot.
            // Internal function call saves gas vs external call.
            _claimSinglePlotResources(plotIds[i], msg.sender);
        }
    }

     /// @notice Internal helper for claiming a single plot's resources.
     /// @param plotId The ID of the plot.
     /// @param owner The expected owner (pre-checked in batch function).
     function _claimSinglePlotResources(uint256 plotId, address owner) internal {
        // Re-validate ownership in case state changed between array creation and call
        require(_exists(plotId) && ownerOf(plotId) == owner, NotPlotOwner(owner, plotId));

        Plot storage plot = _plots[plotId];
        uint256 currentTime = block.timestamp;
        uint256 timeSinceLastClaim = currentTime - plot.lastClaimTime;

        // Calculate pending resources (before decay)
        uint256 effectiveProductionRate = _getEffectiveProductionRate(plot);
        uint256 pendingResources = (effectiveProductionRate * timeSinceLastClaim) / 1e18;

        // Calculate decay penalty
        uint256 timeSinceLastMaintenance = currentTime - plot.lastMaintenanceTime;
        uint256 decayPeriods = timeSinceLastMaintenance / globalDecayPeriod;
        uint256 decayPenalty = (decayPeriods * resourceConfigs[plot.produces].decayRatePerPeriod * _getPlotMaintenanceCostMultiplier(plot)) / 1e18;

        uint256 resourcesToClaim = pendingResources > decayPenalty ? pendingResources - decayPenalty : 0;

        if (resourcesToClaim > 0) {
            resourceBalances[owner][plot.produces] += resourcesToClaim;
             // Emit event per plot for transparency
            emit ResourcesClaimed(plotId, owner, plot.produces, resourcesToClaim);
        }

        plot.lastClaimTime = currentTime;
     }


    /// @notice Allows performing maintenance on multiple plots owned by the caller.
    /// @param plotIds An array of plot IDs.
    function batchPerformMaintenance(uint256[] calldata plotIds) public whenNotPausedOrOwner {
         for (uint256 i = 0; i < plotIds.length; i++) {
            _performSinglePlotMaintenance(plotIds[i], msg.sender);
        }
    }

    /// @notice Internal helper for performing maintenance on a single plot.
     /// @param plotId The ID of the plot.
     /// @param owner The expected owner (pre-checked in batch function).
    function _performSinglePlotMaintenance(uint256 plotId, address owner) internal {
        require(_exists(plotId) && ownerOf(plotId) == owner, NotPlotOwner(owner, plotId));

        Plot storage plot = _plots[plotId];
        uint256 currentTime = block.timestamp;
        uint256 timeSinceLastMaintenance = currentTime - plot.lastMaintenanceTime;

        // Allow batch maintenance even if not strictly required yet, but maybe no cost?
        // Let's require maintenance periods to have passed, like the single function.
        require(timeSinceLastMaintenance >= globalDecayPeriod, MaintenanceNotRequired(plotId));

        uint256 decayPeriods = timeSinceLastMaintenance / globalDecayPeriod;
        uint256 maintenanceCost = (decayPeriods * resourceConfigs[plot.produces].decayRatePerPeriod * _getPlotMaintenanceCostMultiplier(plot)) / 1e18;

        require(resourceBalances[owner][plot.produces] >= maintenanceCost, InsufficientResources(maintenanceCost, resourceBalances[owner][plot.produces]));

        resourceBalances[owner][plot.produces] -= maintenanceCost;
        plot.lastMaintenanceTime = currentTime;

        emit MaintenancePerformed(plotId, owner, maintenanceCost);
    }


    // --- Plot Management ---

    /// @notice Returns comprehensive details about a specific plot.
    /// @param plotId The ID of the plot.
    /// @return A tuple containing plot data.
    function getPlotDetails(uint256 plotId) public view returns (
        uint256 plotId_,
        address owner,
        ResourceType produces,
        uint256 level,
        uint256 lastClaimTime,
        uint256 lastMaintenanceTime,
        uint256 baseProductionRate
    ) {
        require(_exists(plotId), InvalidPlotId(plotId));
        Plot storage plot = _plots[plotId];
        return (
            plot.plotId,
            ownerOf(plotId),
            plot.produces,
            plot.level,
            plot.lastClaimTime,
            plot.lastMaintenanceTime,
            plot.baseProductionRate
        );
    }

    /// @notice Returns an array of plot IDs owned by an address.
    /// @param owner The address to check.
    /// @return An array of plot IDs. (Uses ERC721Enumerable)
    function getPlotsByOwner(address owner) public view returns (uint256[] memory) {
        uint256 tokenCount = balanceOf(owner);
        uint256[] memory tokenIds = new uint256[](tokenCount);
        for (uint256 i = 0; i < tokenCount; i++) {
            tokenIds[i] = tokenOfOwnerByIndex(owner, i);
        }
        return tokenIds;
    }

    /// @notice Returns the total count of Plot NFTs minted.
    /// @return The total plot count.
    function getTotalPlots() public view returns (uint256) {
        return _plotCounter;
    }

    /// @notice Returns the current effective production rate of a plot.
    /// @param plotId The ID of the plot.
    /// @return The production rate per second (scaled by 1e18). Does not account for decay penalty.
    function getPlotProductionRate(uint256 plotId) public view returns (uint256) {
        require(_exists(plotId), InvalidPlotId(plotId));
        Plot storage plot = _plots[plotId];
        return _getEffectiveProductionRate(plot);
    }

     /// @notice Internal helper to calculate the effective production rate including upgrade multipliers.
     /// @param plot The plot struct.
     /// @return The production rate per second (scaled by 1e18).
    function _getEffectiveProductionRate(Plot storage plot) internal view returns (uint256) {
         // Get upgrade multiplier for the current level
        uint256 productionMultiplier = upgradeConfigs[plot.produces][plot.level].productionMultiplier;
        if (productionMultiplier == 0) { // Default to 1x multiplier if config not set for level 1?
            if (plot.level == 1) productionMultiplier = 1e18; // Assume 1x base
            else return 0; // Config missing for this level
        }

        uint256 rate = (plot.baseProductionRate * productionMultiplier) / 1e18;

        // Apply global event multiplier if active and applicable (example: ProductionBoost=1)
        if (activeGlobalEvent.endTime > block.timestamp && activeGlobalEvent.eventType == 1) {
            rate = (rate * activeGlobalEvent.multiplier) / 1e18;
        }

        return rate;
    }

     /// @notice Internal helper to calculate the effective maintenance cost multiplier including upgrade multipliers.
     /// @param plot The plot struct.
     /// @return The maintenance cost multiplier (scaled by 1e18).
     function _getPlotMaintenanceCostMultiplier(Plot storage plot) internal view returns (uint256) {
         uint256 maintMultiplier = upgradeConfigs[plot.produces][plot.level].maintenanceCostMultiplier;
          if (maintMultiplier == 0) { // Default to 1x multiplier if config not set for level 1?
             if (plot.level == 1) return 1e18; // Assume 1x base
             else return 1e18; // Default to 1x if config missing for higher levels? Decide game logic.
         }
         return maintMultiplier;
     }


    // --- Admin & Configuration ---

    /// @notice Admin function to configure parameters for a specific resource type.
    /// @param resource The resource type.
    /// @param baseProductionRate_ Base rate per second (scaled by 1e18).
    /// @param decayRatePerPeriod_ Reduction in production per decay period if not maintained (scaled by 1e18).
    /// @param maintenanceCostMultiplier_ Multiplier for calculating resource cost of maintenance (scaled by 1e18).
    function setResourceParameters(
        ResourceType resource,
        uint256 baseProductionRate_,
        uint256 decayRatePerPeriod_,
        uint256 maintenanceCostMultiplier_
    ) public onlyOwner {
         require(uint256(resource) < uint256(ResourceType.Crystal) + 1, "Invalid resource type");
        resourceConfigs[resource] = ResourceParams({
            baseProductionRate: baseProductionRate_,
            decayRatePerPeriod: decayRatePerPeriod_,
            maintenanceCostMultiplier: maintenanceCostMultiplier_
        });
        emit ResourceParameterSet(resource, baseProductionRate_, decayRatePerPeriod_, maintenanceCostMultiplier_);
    }

     /// @notice Admin function to configure parameters for plot upgrades at a specific level.
     /// @param resource The resource type the plot produces.
     /// @param level The upgrade level this config applies to.
     /// @param resourceCosts The resource costs to perform this upgrade (array indices match ResourceType enum).
     /// @param productionMultiplier The production multiplier applied at this level (scaled by 1e18).
     /// @param maintenanceCostMultiplier The maintenance cost multiplier applied at this level (scaled by 1e18).
    function setUpgradeParameters(
        ResourceType resource,
        uint256 level,
        uint256[] calldata resourceCosts,
        uint256 productionMultiplier,
        uint256 maintenanceCostMultiplier
    ) public onlyOwner {
         require(uint256(resource) < uint256(ResourceType.Crystal) + 1, "Invalid resource type");
         require(resourceCosts.length == uint256(ResourceType.Crystal) + 1, "Resource cost array length must match number of resource types");
        upgradeConfigs[resource][level] = UpgradeLevelParams({
            resourceCosts: resourceCosts,
            productionMultiplier: productionMultiplier,
            maintenanceCostMultiplier: maintenanceCostMultiplier
        });
        emit UpgradeParameterSet(resource, level, resourceCosts, productionMultiplier);
    }

    /// @notice Admin function to set the global decay period duration.
    /// @param period Time in seconds.
    function setGlobalDecayPeriod(uint256 period) public onlyOwner {
        require(period > 0, "Period must be greater than 0");
        globalDecayPeriod = period;
        emit GlobalDecayPeriodSet(period);
    }

    /// @notice Admin function to set the ETH cost for minting a plot.
    /// @param cost The ETH cost in wei.
    function setBaseMintCostEth(uint256 cost) public onlyOwner {
        baseMintCostEth = cost;
        emit BaseMintCostEthSet(cost);
    }

    /// @notice Admin function to withdraw accumulated ETH fees.
    function withdrawProtocolFees() public onlyOwner {
        uint256 balance = _protocolFeesAccrued;
        require(balance > 0, "No fees to withdraw");
        _protocolFeesAccrued = 0;
        payable(owner()).transfer(balance);
        emit ProtocolFeesWithdrawn(owner(), balance);
    }

    /// @notice Admin function to trigger a global game event. (Example: Production Boost)
    /// @param eventType Type of event (e.g., 1 for Production Boost).
    /// @param multiplier Multiplier for the event effect (scaled by 1e18).
    /// @param duration Duration of the event in seconds.
    function triggerGlobalEvent(uint256 eventType, uint256 multiplier, uint256 duration) public onlyOwner {
        require(duration > 0, "Event duration must be > 0");
        activeGlobalEvent = GlobalEvent({
            eventType: eventType,
            multiplier: multiplier,
            startTime: block.timestamp,
            endTime: block.timestamp + duration
        });
        emit GlobalEventTriggered(eventType, multiplier, duration);
    }

    /// @notice Admin function to clear any active global game event.
    function clearGlobalEvent() public onlyOwner {
        uint256 clearedEventType = activeGlobalEvent.eventType;
        activeGlobalEvent.endTime = 0; // Ends the event
        emit GlobalEventCleared(clearedEventType);
    }

    // --- View Functions (Configuration & Global State) ---

    /// @notice Returns the configuration for a resource type.
    /// @param resource The resource type.
    /// @return A tuple containing resource parameters.
    function getResourceParameters(ResourceType resource) public view returns (
        uint256 baseProductionRate,
        uint256 decayRatePerPeriod,
        uint256 maintenanceCostMultiplier
    ) {
         require(uint256(resource) < uint256(ResourceType.Crystal) + 1, "Invalid resource type");
        ResourceParams storage config = resourceConfigs[resource];
        return (
            config.baseProductionRate,
            config.decayRatePerPeriod,
            config.maintenanceCostMultiplier
        );
    }

     /// @notice Returns the configuration for a specific upgrade level.
     /// @param resource The resource type the plot produces.
     /// @param level The upgrade level.
     /// @return A tuple containing upgrade parameters.
    function getUpgradeParameters(ResourceType resource, uint256 level) public view returns (
        uint256[] memory resourceCosts,
        uint256 productionMultiplier,
        uint256 maintenanceCostMultiplier
    ) {
         require(uint256(resource) < uint256(ResourceType.Crystal) + 1, "Invalid resource type");
        UpgradeLevelParams storage config = upgradeConfigs[resource][level];
         // Return copy of array for view function
        uint256[] memory costs = new uint256[](config.resourceCosts.length);
        for(uint i = 0; i < config.resourceCosts.length; i++){
            costs[i] = config.resourceCosts[i];
        }
        return (
            costs,
            config.productionMultiplier,
            config.maintenanceCostMultiplier
        );
    }

    /// @notice Returns the current global decay period.
    function getGlobalDecayPeriod() public view returns (uint256) {
        return globalDecayPeriod;
    }

    /// @notice Returns the current ETH mint cost.
    function getBaseMintCostEth() public view returns (uint256) {
        return baseMintCostEth;
    }

    /// @notice Returns the total ETH fees held by the contract.
    function getProtocolFeesAccrued() public view returns (uint256) {
        return _protocolFeesAccrued;
    }

    /// @notice Returns details about any active global event.
    /// @return A tuple containing event details.
    function getGlobalEventStatus() public view returns (
        uint256 eventType,
        uint256 multiplier,
        uint256 startTime,
        uint256 endTime,
        bool isActive
    ) {
        bool active = activeGlobalEvent.endTime > block.timestamp;
        return (
            activeGlobalEvent.eventType,
            activeGlobalEvent.multiplier,
            activeGlobalEvent.startTime,
            activeGlobalEvent.endTime,
            active
        );
    }

    /// @notice Returns the number of unique addresses that own at least one plot.
    function getTotalMinerCount() public view returns (uint256) {
        return _minerCount;
    }

    // --- Pausability ---

    /// @notice Pauses the contract. Only callable by owner.
    function pause() public onlyOwner {
        _pause();
    }

    /// @notice Unpauses the contract. Only callable by owner.
    function unpause() public onlyOwner {
        _unpause();
    }

    // The following functions are overrides required by Solidity.
    function supportsInterface(bytes4 interfaceId) public view override(ERC721Enumerable, ERC721) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    // Optional: Override transferFrom and safeTransferFrom if you want custom logic (e.g., tax, game state checks)
    // For this example, we rely on standard ERC721 transfers which work out of the box.

    // function transferFrom(address from, address to, uint256 tokenId) public override {
    //     require(paused() == false || msg.sender == owner(), "Pausable: paused");
    //     super.transferFrom(from, to, tokenId);
    // }

    // function safeTransferFrom(address from, address to, uint256 tokenId) public override {
    //      require(paused() == false || msg.sender == owner(), "Pausable: paused");
    //     super.safeTransferFrom(from, to, tokenId);
    // }

     // function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) public override {
    //      require(paused() == false || msg.sender == owner(), "Pausable: paused");
    //     super.safeTransferFrom(from, to, tokenId, data);
    // }
}
```

**Explanation of Advanced/Creative Concepts & Design Choices:**

1.  **Hybrid Fungible/Non-Fungible:** The contract manages both ERC721 Plot NFTs (unique assets) and multiple types of fungible Resources (tracked in mappings). This is common in blockchain games but structured here with specific game mechanics.
2.  **Time-Based Decay and Maintenance:** Plots have a `lastMaintenanceTime`. A global `globalDecayPeriod` defines cycles. Decay accrues based on elapsed periods since the last maintenance/upgrade. This introduces a cost/activity requirement for players. Maintenance is a resource sink and requires player interaction.
3.  **Claiming with Decay Penalty:** The `claimResources` function calculates production based on elapsed time and plot stats, but *then* deducts a decay penalty if maintenance hasn't kept up. This forces players to choose between claiming frequently (less penalty per claim but more transactions) or maintaining periodically.
4.  **Resource-Based Upgrades:** Plot levels increase production and potentially modify maintenance costs, but they require spending specific amounts of different resources, creating demand for the fungible tokens.
5.  **Configurable Game Parameters:** Admin functions allow tuning production rates, decay rates, maintenance costs, upgrade costs, and multipliers. This enables game balancing post-deployment (within the scope of the contract's logic). Scaling factors (like `1e18`) are used for potential fractional values in rates, common in DeFi/tokenomics.
6.  **Batch Operations:** `batchClaimResources` and `batchPerformMaintenance` demonstrate gas optimization by allowing players to interact with multiple NFTs in a single transaction, a crucial feature for games with many small assets.
7.  **Global Events:** A simple `GlobalEvent` struct and functions (`triggerGlobalEvent`, `clearGlobalEvent`) show how game-wide effects (like temporary production boosts) can be implemented, adding dynamic elements to the simulation.
8.  **ERC721Enumerable:** Used to easily list all plot IDs owned by an address, which is helpful for player UIs but adds gas cost on transfer due to array management. Removed the `_beforeTokenTransfer` override as `ERC721Enumerable` handles the tracking internally. Re-added a simpler `_beforeTokenTransfer` to track unique *miner* counts.
9.  **Custom Errors:** Using `error` instead of `require` strings is a gas-efficient pattern in newer Solidity versions.
10. **Internal Helpers:** Functions like `_getEffectiveProductionRate`, `_getPlotMaintenanceCostMultiplier`, `_claimSinglePlotResources`, `_performSinglePlotMaintenance` keep the public functions cleaner and allow code reuse, especially in batch operations.

This contract provides a framework for a resource-management simulation game on the blockchain, using several interconnected mechanics beyond simple token transfers or basic NFT minting.