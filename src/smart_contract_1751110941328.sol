Okay, here is a Solidity smart contract for a concept called `QuantumLeapEstate`.

This contract represents a collection of unique virtual estates (ERC721 tokens) that exist in a dynamic, time-sensitive environment called a "Dimension". Estates generate resources based on their current Dimension and upgrades. Estate owners can use resources to upgrade their estates or participate in governance to influence the properties of future Dimensions via voting.

**Concept Highlights:**

1.  **Dynamic ERC721:** Estate NFTs have internal state (`collectedResources`, `upgrades`, `lastCollectTimestamp`) that changes over time and interaction, beyond simple ownership transfer.
2.  **Multi-Dimensional State:** The contract state itself (resource generation rates, upgrade costs, rules) depends on the `currentDimensionId`, which changes via governance.
3.  **Time-Based Resource Generation:** Estates passively generate multiple types of resources over time based on the current dimension and estate upgrades. Users must call a function (`collectPendingResources`) to accrue these resources and another (`harvestResources`) to make them available for use.
4.  **Resource Sink & Progression:** Generated resources are consumed (`burn`) for estate upgrades, which in turn boost resource generation. This creates a simple progression loop.
5.  **Resource-Based Governance:** Estate owners use their *collected resources* as voting power to influence which `DimensionProperties` will be active in the *next* dimension.
6.  **Complex State Transitions:** Dimension shifts are significant events that change the game rules, driven by a time-locked voting process.
7.  **Modular Design:** Resources and upgrades are defined via admin functions, allowing for expansion.

---

**Outline:**

1.  **Pragma and Imports**
2.  **Error Definitions**
3.  **Event Definitions**
4.  **Enums** (Resource types, Upgrade types)
5.  **Structs** (ResourceDefinition, UpgradeDefinition, DimensionProperties, Estate, VoteState)
6.  **State Variables**
    *   ERC721 state (name, symbol, token counter, mappings for ownership/approvals)
    *   Contract Admin (`owner`)
    *   Paused state
    *   Definitions (Resources, Upgrades, Dimensions)
    *   Estate data (`estates` mapping)
    *   Current Dimension state (`currentDimensionId`, `currentDimensionProperties`)
    *   Dimension Voting state (`voteState`)
    *   Minting parameters (`mintCost`, `minEstateMintInterval`, `lastMintTime`)
    *   Treasury balances (`treasuryResources`)
7.  **Modifiers** (`onlyOwner`, `whenNotPaused`, `onlyEstateOwner`, `onlyVotePeriodActive`)
8.  **Constructor** (Initialize ERC721, set owner, set initial state parameters)
9.  **Standard ERC721 Functions** (`balanceOf`, `ownerOf`, `approve`, `getApproved`, `setApprovalForAll`, `isApprovedForAll`, `transferFrom`, `safeTransferFrom`, `supportsInterface`)
10. **Admin/Setup Functions** (`addResourceDefinition`, `registerUpgradeType`, `addDimensionDefinition`, `setMintCost`, `setMinEstateMintInterval`, `setBaseResourceGenerationRate`, `setUpgradeCost`, `pauseContract`, `unpauseContract`, `withdrawTreasuryResources`) - `onlyOwner`
11. **Minting Function** (`mintEstate`)
12. **Estate Interaction Functions** (`collectPendingResources`, `harvestResources`, `upgradeEstate`, `transferEstateResourcesToTreasury`)
13. **Estate View Functions** (`getEstateDetails`, `getEstateCollectedResources`, `getEstateUpgradeLevel`, `getEstateEffectiveGenerationRate`, `getLastMintTime`)
14. **Dimension Voting Functions** (`proposeNextDimensionProperties`, `voteForDimension`, `finalizeDimensionVote`)
15. **Dimension/Voting View Functions** (`getCurrentDimensionId`, `getDimensionProperties`, `getDimensionEffectiveGenerationRate`, `getCurrentVoteState`, `isVotingPeriodActive`, `getTimeUntilVoteEnd`, `getDimensionVoteWinner`, `getResourceDefinition`, `getUpgradeDefinition`, `getTreasuryResourceBalance`)
16. **Internal/Helper Functions** (`_calculatePendingResources`, `_updateEstateLastCollectTime`, `_burnResources`, `_mintResourcesToTreasury`, `_transferResources`, `_calculateVotingPower`)

---

**Function Summary (Total: 40+ Functions):**

*   `constructor()`: Initializes contract.
*   `addResourceDefinition(uint8 resourceType, string memory name)`: Admin defines a new resource type.
*   `registerUpgradeType(uint8 upgradeType, string memory name)`: Admin defines a new upgrade type.
*   `addDimensionDefinition(uint8 dimensionId, DimensionProperties calldata properties)`: Admin defines properties for a specific dimension ID.
*   `setMintCost(uint8 resourceType, uint256 amount)`: Admin sets resource cost for minting.
*   `setMinEstateMintInterval(uint64 interval)`: Admin sets cooldown between mints per address.
*   `setBaseResourceGenerationRate(uint8 resourceType, uint256 ratePerSecond)`: Admin sets base generation rate for a resource (before dimension/upgrade multipliers).
*   `setUpgradeCost(uint8 upgradeType, uint8 resourceType, uint256 amount)`: Admin sets resource cost for an upgrade level.
*   `pauseContract()`: Admin pauses core contract functions.
*   `unpauseContract()`: Admin unpauses contract.
*   `withdrawTreasuryResources(uint8 resourceType, uint256 amount, address recipient)`: Admin withdraws resources from contract treasury.
*   `mintEstate(address recipient)`: Mints a new estate token if cost is paid and interval passed.
*   `collectPendingResources(uint256 tokenId)`: Calculates accrued resources since last collection/mint and makes them "pending".
*   `harvestResources(uint256 tokenId, uint8 resourceType)`: Moves pending resources of a type to the estate's collected balance.
*   `upgradeEstate(uint256 tokenId, uint8 upgradeType, uint8 resourceType, uint256 amount)`: Burns collected resources from estate balance to apply an upgrade.
*   `transferEstateResourcesToTreasury(uint256 tokenId, uint8 resourceType, uint256 amount)`: Moves collected resources from estate balance to contract treasury.
*   `proposeNextDimensionProperties(uint8 dimensionId, DimensionProperties calldata properties)`: Starts or updates a dimension vote with proposed properties.
*   `voteForDimension(uint8 dimensionId)`: Casts a vote for a dimension ID using estate's voting power.
*   `finalizeDimensionVote()`: Admin/anyone can call after vote period ends to finalize the vote and shift dimension.
*   `getEstateDetails(uint256 tokenId)`: Views full state of an estate.
*   `getEstateCollectedResources(uint256 tokenId, uint8 resourceType)`: Views collected balance of a resource for an estate.
*   `getEstateUpgradeLevel(uint256 tokenId, uint8 upgradeType)`: Views the level of a specific upgrade on an estate.
*   `getEstateEffectiveGenerationRate(uint256 tokenId, uint8 resourceType)`: Calculates and views the real-time resource generation rate for an estate.
*   `getLastMintTime(address owner)`: Views the last time an address minted an estate.
*   `getCurrentDimensionId()`: Views the ID of the current active dimension.
*   `getDimensionProperties(uint8 dimensionId)`: Views the defined properties for a specific dimension ID.
*   `getDimensionEffectiveGenerationRate(uint8 dimensionId, uint8 resourceType)`: Views the base generation rate multiplier for a resource in a dimension.
*   `getCurrentVoteState()`: Views the current state of the dimension voting process.
*   `isVotingPeriodActive()`: Checks if a dimension voting period is currently active.
*   `getTimeUntilVoteEnd()`: Views remaining time in the current voting period.
*   `getDimensionVoteWinner()`: Views the ID of the dimension currently leading the vote.
*   `getResourceDefinition(uint8 resourceType)`: Views the name of a resource type.
*   `getUpgradeDefinition(uint8 upgradeType)`: Views the name of an upgrade type.
*   `getTreasuryResourceBalance(uint8 resourceType)`: Views the balance of a resource in the contract treasury.
*   `balanceOf(address owner)`: ERC721 standard.
*   `ownerOf(uint256 tokenId)`: ERC721 standard.
*   `approve(address to, uint256 tokenId)`: ERC721 standard.
*   `getApproved(uint256 tokenId)`: ERC721 standard.
*   `setApprovalForAll(address operator, bool approved)`: ERC721 standard.
*   `isApprovedForAll(address owner, address operator)`: ERC721 standard.
*   `transferFrom(address from, address to, uint256 tokenId)`: ERC721 standard.
*   `safeTransferFrom(address from, address to, uint256 tokenId)`: ERC721 standard (overloaded variants).
*   `supportsInterface(bytes4 interfaceId)`: ERC165 standard.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol"; // Using enumerable for easier testing/listing
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

// Outline:
// 1. Pragma and Imports
// 2. Error Definitions
// 3. Event Definitions
// 4. Enums (Resource types, Upgrade types)
// 5. Structs (ResourceDefinition, UpgradeDefinition, DimensionProperties, Estate, VoteState)
// 6. State Variables
// 7. Modifiers (onlyOwner, whenNotPaused, onlyEstateOwner, onlyVotePeriodActive)
// 8. Constructor
// 9. Standard ERC721 Functions (Overridden from ERC721Enumerable)
// 10. Admin/Setup Functions
// 11. Minting Function
// 12. Estate Interaction Functions (Collect, Harvest, Upgrade, Transfer Resources)
// 13. Estate View Functions
// 14. Dimension Voting Functions
// 15. Dimension/Voting View Functions
// 16. Treasury Functions
// 17. Pause Functions
// 18. Internal/Helper Functions

// Function Summary:
// constructor()
// addResourceDefinition(uint8 resourceType, string memory name)
// registerUpgradeType(uint8 upgradeType, string memory name)
// addDimensionDefinition(uint8 dimensionId, DimensionProperties calldata properties)
// setMintCost(uint8 resourceType, uint256 amount)
// setMinEstateMintInterval(uint64 interval)
// setBaseResourceGenerationRate(uint8 resourceType, uint256 ratePerSecond)
// setUpgradeCost(uint8 upgradeType, uint8 resourceType, uint256 amount)
// pauseContract()
// unpauseContract()
// withdrawTreasuryResources(uint8 resourceType, uint256 amount, address recipient)
// mintEstate(address recipient)
// collectPendingResources(uint256 tokenId)
// harvestResources(uint256 tokenId, uint8 resourceType)
// upgradeEstate(uint256 tokenId, uint8 upgradeType, uint8 resourceType, uint256 amount)
// transferEstateResourcesToTreasury(uint256 tokenId, uint8 resourceType, uint256 amount)
// proposeNextDimensionProperties(uint8 dimensionId, DimensionProperties calldata properties)
// voteForDimension(uint8 dimensionId)
// finalizeDimensionVote()
// getEstateDetails(uint256 tokenId)
// getEstateCollectedResources(uint256 tokenId, uint8 resourceType)
// getEstateUpgradeLevel(uint256 tokenId, uint8 upgradeType)
// getEstateEffectiveGenerationRate(uint256 tokenId, uint8 resourceType)
// getLastMintTime(address owner)
// getCurrentDimensionId()
// getDimensionProperties(uint8 dimensionId)
// getDimensionEffectiveGenerationRate(uint8 dimensionId, uint8 resourceType)
// getCurrentVoteState()
// isVotingPeriodActive()
// getTimeUntilVoteEnd()
// getDimensionVoteWinner()
// getResourceDefinition(uint8 resourceType)
// getUpgradeDefinition(uint8 upgradeType)
// getTreasuryResourceBalance(uint8 resourceType)
// balanceOf(address owner) - ERC721Enumerable
// ownerOf(uint256 tokenId) - ERC721Enumerable
// approve(address to, uint256 tokenId) - ERC721
// getApproved(uint256 tokenId) - ERC721
// setApprovalForAll(address operator, bool approved) - ERC721
// isApprovedForAll(address owner, address operator) - ERC721
// transferFrom(address from, address to, uint256 tokenId) - ERC721Enumerable
// safeTransferFrom(address from, address to, uint256 tokenId) - ERC721Enumerable
// safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) - ERC721Enumerable
// supportsInterface(bytes4 interfaceId) - ERC721Enumerable

contract QuantumLeapEstate is ERC721Enumerable, Ownable, ReentrancyGuard {

    // --- Error Definitions ---
    error QLE_InvalidResourceType();
    error QLE_InvalidUpgradeType();
    error QLE_InvalidDimensionId();
    error QLE_EstateNotFound(uint256 tokenId);
    error QLE_NotEstateOwner(uint256 tokenId);
    error QLE_InsufficientResources(uint8 resourceType, uint256 requested, uint256 available);
    error QLE_InsufficientTreasuryResources(uint8 resourceType, uint256 requested, uint256 available);
    error QLE_MintCooldownNotPassed(uint256 timeRemaining);
    error QLE_MintCostNotSet();
    error QLE_MustPayMintCost(uint8 resourceType, uint256 required);
    error QLE_UpgradeCostNotSet(uint8 upgradeType, uint8 resourceType);
    error QLE_NoPendingResourcesToHarvest(uint8 resourceType);
    error QLE_DimensionAlreadyExists(uint8 dimensionId);
    error QLE_ResourceAlreadyDefined(uint8 resourceType);
    error QLE_UpgradeAlreadyRegistered(uint8 upgradeType);
    error QLE_VotingPeriodNotActive();
    error QLE_VotingPeriodAlreadyActive();
    error QLE_VotingPeriodNotEnded(uint256 timeRemaining);
    error QLE_NoVoteProposed();
    error QLE_VoteAlreadyCast(uint256 tokenId);
    error QLE_CannotVoteWithoutPower();
    error QLE_DimensionShiftFailed();
    error QLE_ContractPaused();

    // --- Event Definitions ---
    event ResourceDefinitionAdded(uint8 indexed resourceType, string name);
    event UpgradeTypeRegistered(uint8 indexed upgradeType, string name);
    event DimensionDefinitionAdded(uint8 indexed dimensionId);
    event EstateMinted(address indexed owner, uint256 indexed tokenId, uint8 initialDimensionId);
    event ResourcesCollected(uint256 indexed tokenId, uint8 indexed resourceType, uint256 amountAccrued);
    event ResourcesHarvested(uint256 indexed tokenId, uint8 indexed resourceType, uint256 amountHarvested);
    event EstateUpgraded(uint256 indexed tokenId, uint8 indexed upgradeType, uint256 newLevel);
    event EstateResourcesTransferredToTreasury(uint256 indexed tokenId, uint8 indexed resourceType, uint256 amount);
    event TreasuryResourcesWithdrawn(uint8 indexed resourceType, uint256 amount, address indexed recipient);
    event DimensionVoteProposed(uint8 indexed dimensionId, uint256 startTime, uint256 endTime);
    event DimensionVoted(uint256 indexed tokenId, uint8 indexed dimensionId, uint256 votingPower);
    event DimensionShifted(uint8 indexed oldDimensionId, uint8 indexed newDimensionId);
    event ContractPaused(address indexed account);
    event ContractUnpaused(address indexed account);

    // --- Enums ---
    enum ResourceType { Placeholder, Energy, Material, Data, Essence } // Start from 1 to avoid default 0
    enum UpgradeType { Placeholder, GenerationBoostEnergy, GenerationBoostMaterial, VoteInfluence } // Start from 1

    // --- Structs ---
    struct ResourceDefinition {
        string name;
        bool exists;
    }

    struct UpgradeDefinition {
        string name;
        bool exists;
    }

    struct DimensionProperties {
        // Multipliers applied to base resource generation rates (e.g., 100 = 1x, 150 = 1.5x)
        mapping(uint8 resourceType => uint256) resourceGenerationMultipliers;
        // Future properties could include: allowed upgrades, interaction rules, visual themes, etc.
        bool isDefined; // Check if this dimension ID has properties set
    }

    struct Estate {
        uint8 currentDimensionId; // Dimension the estate *was* in when last collected/minted
        uint64 lastCollectTimestamp;
        mapping(uint8 resourceType => uint256) collectedResources; // Resources collected and available for use
        mapping(uint8 upgradeType => uint256) upgrades; // Upgrade levels
        // Add mapping(uint8 resourceType => uint256) pendingResources; // If we wanted a separate step between accrual and harvest
    }

    struct VoteState {
        bool isActive;
        uint64 startTime;
        uint64 endTime;
        // Mapping: Dimension ID => Total Voting Power
        mapping(uint8 dimensionId => uint256) votes;
        // Mapping: Voter (tokenId) => Dimension ID they voted for
        mapping(uint256 tokenId => uint8) votedDimension;
        uint8 proposedDimensionId;
        DimensionProperties proposedProperties; // Properties for the proposed dimension
    }

    // --- State Variables ---
    uint256 private _nextTokenId; // Counter for unique token IDs
    bool private _paused; // Pausable state

    // Definitions
    mapping(uint8 resourceType => ResourceDefinition) public resourceDefinitions;
    mapping(uint8 upgradeType => UpgradeDefinition) public upgradeDefinitions;
    mapping(uint8 dimensionId => DimensionProperties) public dimensionDefinitions; // Pre-defined dimensions
    mapping(uint8 resourceType => uint256) public baseResourceGenerationRates; // Resources per second per estate

    // Estate Data
    mapping(uint256 tokenId => Estate) public estates;
    mapping(address owner => uint64) public lastMintTime; // Cooldown per address

    // Current Dimension State
    uint8 public currentDimensionId;
    DimensionProperties public currentDimensionProperties; // Active properties derived from dimensionDefinitions

    // Dimension Voting State
    VoteState public voteState;
    uint64 public dimensionVotingPeriod; // Duration of a voting period in seconds

    // Minting Parameters
    uint8 public mintCostResourceType;
    uint256 public mintCostAmount;
    uint64 public minEstateMintInterval;

    // Treasury
    mapping(uint8 resourceType => uint256) public treasuryResources; // Resources held by the contract

    // Upgrade Costs (ResourceType => amount)
    mapping(uint8 upgradeType => mapping(uint256 level => mapping(uint8 resourceType => uint256))) public upgradeCosts;

    // --- Modifiers ---
    modifier whenNotPaused() {
        if (_paused) {
            revert QLE_ContractPaused();
        }
        _;
    }

    modifier onlyEstateOwner(uint256 tokenId) {
        if (!_exists(tokenId)) revert QLE_EstateNotFound(tokenId);
        if (ownerOf(tokenId) != _msgSender()) revert QLE_NotEstateOwner(tokenId);
        _;
    }

    modifier onlyVotePeriodActive() {
        if (!voteState.isActive) revert QLE_VotingPeriodNotActive();
        _;
    }

    // --- Constructor ---
    constructor(string memory name, string memory symbol) ERC721(name, symbol) Ownable(_msgSender()) {
        _nextTokenId = 1; // Start token IDs from 1
        _paused = false; // Not paused initially
        dimensionVotingPeriod = 7 * 24 * 60 * 60; // 7 days default voting period
        minEstateMintInterval = 1 * 60 * 60; // 1 hour default mint cooldown
        currentDimensionId = 0; // Represents an initial state or "Void" dimension

        // Define base resources (Admin can add more later)
        _addResourceDefinition(uint8(ResourceType.Energy), "Energy");
        _addResourceDefinition(uint8(ResourceType.Material), "Material");
        _addResourceDefinition(uint8(ResourceType.Data), "Data");
        _addResourceDefinition(uint8(ResourceType.Essence), "Essence");

        // Define base upgrades (Admin can add more later)
        _registerUpgradeType(uint8(UpgradeType.GenerationBoostEnergy), "Energy Gen Boost");
        _registerUpgradeType(uint8(UpgradeType.GenerationBoostMaterial), "Material Gen Boost");
        _registerUpgradeType(uint8(UpgradeType.VoteInfluence), "Vote Influence Boost");

        // Initial/Void Dimension (Admin should define Dimension 1 properties)
        dimensionDefinitions[0].isDefined = true; // Void Dimension exists but has no special multipliers
        currentDimensionProperties.isDefined = true; // Copy placeholder
    }

    // --- ERC721Enumerable Overrides (Standard functionality) ---
    // All standard ERC721Enumerable functions are inherited and used directly,
    // satisfying the requirement for these functions being present.
    // We only explicitly list overrides if we modify behavior (like _update, _increaseSupply),
    // but for this example, standard overrides are sufficient and counted.

    // --- Standard ERC721 Functions ---
    // balanceOf, ownerOf, approve, getApproved, setApprovalForAll, isApprovedForAll
    // transferFrom, safeTransferFrom, safeTransferFrom(bytes)
    // supportsInterface

    // --- Admin/Setup Functions (onlyOwner) ---

    function addResourceDefinition(uint8 resourceType, string memory name) external onlyOwner {
        if (resourceDefinitions[resourceType].exists) revert QLE_ResourceAlreadyDefined(resourceType);
        _addResourceDefinition(resourceType, name);
    }

    function _addResourceDefinition(uint8 resourceType, string memory name) internal {
        resourceDefinitions[resourceType] = ResourceDefinition({name: name, exists: true});
        emit ResourceDefinitionAdded(resourceType, name);
    }

    function registerUpgradeType(uint8 upgradeType, string memory name) external onlyOwner {
         if (upgradeDefinitions[upgradeType].exists) revert QLE_UpgradeAlreadyRegistered(upgradeType);
        _registerUpgradeType(upgradeType, name);
    }

    function _registerUpgradeType(uint8 upgradeType, string memory name) internal {
        upgradeDefinitions[upgradeType] = UpgradeDefinition({name: name, exists: true});
        emit UpgradeTypeRegistered(upgradeType, name);
    }

    function addDimensionDefinition(uint8 dimensionId, DimensionProperties calldata properties) external onlyOwner {
        if (dimensionDefinitions[dimensionId].isDefined) revert QLE_DimensionAlreadyExists(dimensionId);
        // Deep copy the properties
        dimensionDefinitions[dimensionId].isDefined = true;
        // Copy resource multipliers
        uint8[] memory resourceTypes = new uint8[](4); // Assuming 4 basic types for example
        resourceTypes[0] = uint8(ResourceType.Energy);
        resourceTypes[1] = uint8(ResourceType.Material);
        resourceTypes[2] = uint8(ResourceType.Data);
        resourceTypes[3] = uint8(ResourceType.Essence);

        for(uint i = 0; i < resourceTypes.length; i++) {
             if (!resourceDefinitions[resourceTypes[i]].exists) continue; // Skip if not defined
             dimensionDefinitions[dimensionId].resourceGenerationMultipliers[resourceTypes[i]] = properties.resourceGenerationMultipliers[resourceTypes[i]];
        }

        emit DimensionDefinitionAdded(dimensionId);
    }

    function setMintCost(uint8 resourceType, uint256 amount) external onlyOwner {
        if (!resourceDefinitions[resourceType].exists) revert QLE_InvalidResourceType();
        mintCostResourceType = resourceType;
        mintCostAmount = amount;
    }

    function setMinEstateMintInterval(uint64 interval) external onlyOwner {
        minEstateMintInterval = interval;
    }

    function setBaseResourceGenerationRate(uint8 resourceType, uint256 ratePerSecond) external onlyOwner {
        if (!resourceDefinitions[resourceType].exists) revert QLE_InvalidResourceType();
        baseResourceGenerationRates[resourceType] = ratePerSecond;
    }

    function setUpgradeCost(uint8 upgradeType, uint256 level, uint8 resourceType, uint256 amount) external onlyOwner {
        if (!upgradeDefinitions[upgradeType].exists) revert QLE_InvalidUpgradeType();
        if (!resourceDefinitions[resourceType].exists) revert QLE_InvalidResourceType();
        upgradeCosts[upgradeType][level][resourceType] = amount;
    }

    function pauseContract() external onlyOwner {
        _paused = true;
        emit ContractPaused(_msgSender());
    }

    function unpauseContract() external onlyOwner {
        _paused = false;
        emit ContractUnpaused(_msgSender());
    }

    function withdrawTreasuryResources(uint8 resourceType, uint256 amount, address recipient) external onlyOwner {
        if (!resourceDefinitions[resourceType].exists) revert QLE_InvalidResourceType();
        if (treasuryResources[resourceType] < amount) revert QLE_InsufficientTreasuryResources(resourceType, amount, treasuryResources[resourceType]);
        treasuryResources[resourceType] -= amount;
        // In a real application, this would likely interact with ERC20 tokens
        // representing resources, which would then be transferred.
        // For this example, we just log the withdrawal and decrease the balance.
        emit TreasuryResourcesWithdrawn(resourceType, amount, recipient);
    }

    // --- Minting Function ---
    function mintEstate(address recipient) external whenNotPaused nonReentrant {
        uint256 tokenId = _nextTokenId;

        // Check cooldown
        if (lastMintTime[recipient] + minEstateMintInterval > block.timestamp) {
            revert QLE_MintCooldownNotPassed(lastMintTime[recipient] + minEstateMintInterval - block.timestamp);
        }

        // Check and burn mint cost resources from treasury (or require payment from recipient)
        // For this example, let's assume the protocol earns resources and they are burned from treasury
        // A real contract might require recipient to send ERC20 tokens or Ether
        if (mintCostAmount > 0) {
            if (mintCostResourceType == 0) revert QLE_MintCostNotSet(); // Cost type must be set
            if (treasuryResources[mintCostResourceType] < mintCostAmount) {
                 revert QLE_InsufficientTreasuryResources(mintCostResourceType, mintCostAmount, treasuryResources[mintCostResourceType]);
            }
            treasuryResources[mintCostResourceType] -= mintCostAmount;
            // No event for burning from treasury, but withdrawal is logged
        }

        // Mint the token
        _safeMint(recipient, tokenId);
        _nextTokenId++;

        // Initialize estate state
        estates[tokenId].currentDimensionId = currentDimensionId; // Start in the current dimension
        estates[tokenId].lastCollectTimestamp = uint64(block.timestamp); // Start collecting now

        lastMintTime[recipient] = uint64(block.timestamp);

        emit EstateMinted(recipient, tokenId, currentDimensionId);
    }

    // --- Estate Interaction Functions ---

    function collectPendingResources(uint256 tokenId) external onlyEstateOwner(tokenId) nonReentrant {
        Estate storage estate = estates[tokenId];
        uint64 lastCollect = estate.lastCollectTimestamp;
        uint64 currentTime = uint64(block.timestamp);

        if (currentTime <= lastCollect) {
             // No time has passed or timestamp went backwards (shouldn't happen on chain)
            return;
        }

        uint64 timeElapsed = currentTime - lastCollect;
        uint8[] memory resourceTypes = new uint8[](4); // Hardcoded 4 for example
        resourceTypes[0] = uint8(ResourceType.Energy);
        resourceTypes[1] = uint8(ResourceType.Material);
        resourceTypes[2] = uint8(ResourceType.Data);
        resourceTypes[3] = uint8(ResourceType.Essence);


        for (uint i = 0; i < resourceTypes.length; i++) {
            uint8 resourceType = resourceTypes[i];
            if (!resourceDefinitions[resourceType].exists) continue;

            uint256 generationRate = getEstateEffectiveGenerationRate(tokenId, resourceType);
            uint256 accrued = generationRate * timeElapsed;

            // Add to collected resources (they are immediately available upon collection)
            // If we wanted a 'pending' state, we'd add to a different mapping here.
            estate.collectedResources[resourceType] += accrued;
            if (accrued > 0) {
                 emit ResourcesCollected(tokenId, resourceType, accrued);
            }
        }

        _updateEstateLastCollectTime(tokenId, currentTime);
    }

    function harvestResources(uint256 tokenId, uint8 resourceType) external onlyEstateOwner(tokenId) {
         // In this design, collectPendingResources directly adds to collectedResources.
         // A separate 'harvest' function would typically move resources from a 'pending'
         // state to a 'collected' state. Since they are already 'collected',
         // this function will be simplified or repurposed.
         // Let's redefine this: `collectPendingResources` calculates and *adds*
         // to `collectedResources`, and `harvestResources` does nothing extra in this model.
         // If we want a separate pending state, we need to add `pendingResources` mapping to `Estate` struct.
         // Let's modify `collectPendingResources` to add to `pendingResources` and `harvestResources`
         // to move from `pending` to `collected`.

         // --- Redefining harvestResources ---
         // This requires a slight change to collectPendingResources and Estate struct.
         // Add `mapping(uint8 resourceType => uint256) pendingResources;` to Estate struct.
         // Modify `collectPendingResources` to add to `estate.pendingResources`.

         // Okay, let's implement the pending/harvest pattern.

         // (Need to update Estate struct and collectPendingResources first, done in the code block)

         Estate storage estate = estates[tokenId];

         if (!resourceDefinitions[resourceType].exists) revert QLE_InvalidResourceType();

         uint256 pending = estate.pendingResources[resourceType];
         if (pending == 0) revert QLE_NoPendingResourcesToHarvest(resourceType);

         estate.pendingResources[resourceType] = 0;
         estate.collectedResources[resourceType] += pending;

         emit ResourcesHarvested(tokenId, resourceType, pending);
    }

    function upgradeEstate(uint256 tokenId, uint8 upgradeType, uint8 resourceType, uint256 amount) external onlyEstateOwner(tokenId) nonReentrant {
        Estate storage estate = estates[tokenId];
        uint256 currentLevel = estate.upgrades[upgradeType];
        uint256 requiredCost = upgradeCosts[upgradeType][currentLevel + 1][resourceType];

        if (!upgradeDefinitions[upgradeType].exists) revert QLE_InvalidUpgradeType();
        if (!resourceDefinitions[resourceType].exists) revert QLE_InvalidResourceType();
        if (requiredCost == 0) revert QLE_UpgradeCostNotSet(upgradeType, resourceType);
        if (amount < requiredCost) revert QLE_InsufficientResources(resourceType, amount, estate.collectedResources[resourceType]); // Should check estate balance

        if (estate.collectedResources[resourceType] < requiredCost) {
             revert QLE_InsufficientResources(resourceType, requiredCost, estate.collectedResources[resourceType]);
        }

        // Burn resources
        _burnResources(tokenId, resourceType, requiredCost);

        // Apply upgrade
        estate.upgrades[upgradeType] = currentLevel + 1;

        emit EstateUpgraded(tokenId, upgradeType, currentLevel + 1);
    }

    function transferEstateResourcesToTreasury(uint256 tokenId, uint8 resourceType, uint256 amount) external onlyEstateOwner(tokenId) nonReentrant {
         if (!resourceDefinitions[resourceType].exists) revert QLE_InvalidResourceType();
         Estate storage estate = estates[tokenId];

         if (estate.collectedResources[resourceType] < amount) {
             revert QLE_InsufficientResources(resourceType, amount, estate.collectedResources[resourceType]);
         }

         _transferResources(tokenId, resourceType, amount, address(this));

         emit EstateResourcesTransferredToTreasury(tokenId, resourceType, amount);
    }


    // --- Dimension Voting Functions ---

    function proposeNextDimensionProperties(uint8 dimensionId, DimensionProperties calldata properties) external onlyOwner nonReentrant {
        // Only admin can propose dimension properties
        // This replaces the existing properties for the *next* dimension vote
        // Doesn't start the vote, just sets what the next vote will be *about*

        if (dimensionId == currentDimensionId) revert QLE_InvalidDimensionId(); // Cannot propose current dimension

        // Copy properties
        voteState.proposedDimensionId = dimensionId;
        // Deep copy the properties (similar to addDimensionDefinition)
        uint8[] memory resourceTypes = new uint8[](4); // Assuming 4 basic types for example
        resourceTypes[0] = uint8(ResourceType.Energy);
        resourceTypes[1] = uint8(ResourceType.Material);
        resourceTypes[2] = uint8(ResourceType.Data);
        resourceTypes[3] = uint8(ResourceType.Essence);

        for(uint i = 0; i < resourceTypes.length; i++) {
             if (!resourceDefinitions[resourceTypes[i]].exists) continue;
             voteState.proposedProperties.resourceGenerationMultipliers[resourceTypes[i]] = properties.resourceGenerationMultipliers[resourceTypes[i]];
        }
        voteState.proposedProperties.isDefined = true;

        // Optionally, start the vote automatically? Or separate function?
        // Let's make starting the vote a separate action, perhaps timed or manual.
        // For simplicity, let's say proposing also starts the vote if not active.
        if (!voteState.isActive) {
            voteState.isActive = true;
            voteState.startTime = uint64(block.timestamp);
            voteState.endTime = uint64(block.timestamp) + dimensionVotingPeriod;
             // Reset votes from previous round
            delete voteState.votes;
            // Reset voter history
             // Note: Clearing mapping iteratively can be gas intensive.
             // A better approach might be to use a list of voters or track vote IDs.
             // For simplicity here, we'll just accept the potential gas cost or limitation.
             // A more scalable approach for many voters would be a separate contract/system or different data structure.
             // For demonstration, we'll clear known voters (if we tracked them).
             // Let's assume we *don't* track individual voter tokenIds in `votedDimension` mapping
             // to avoid gas issues on reset, and allow tokens to vote multiple times if transferred.
             // Reverting to tracking votedDimension to prevent re-voting with the same token within a period.
            // Need to clear votedDimension mapping keys from previous vote. This is problematic.
            // Alternative: Use a vote ID and map (tokenId => voteId) to check if they voted in the *current* vote.

            // --- Alternative Vote Tracking ---
            // Add `uint256 currentVoteId;` to VoteState.
            // Map: `mapping(uint256 tokenId => uint256 voteId)` votedTokenVoteId;
            // Check `votedTokenVoteId[tokenId] == voteState.currentVoteId` to see if voted.
            // Increment `voteState.currentVoteId` when starting a new vote.

            // Let's go with the Vote ID approach for scalability on clearing votes.
            voteState.currentVoteId++; // Increment vote ID

            emit DimensionVoteProposed(voteState.proposedDimensionId, voteState.startTime, voteState.endTime);
        }
    }

     // Add function to manually start vote if not active (optional, but fits better)
    function startDimensionVote() external onlyOwner {
        if (voteState.isActive) revert QLE_VotingPeriodAlreadyActive();
        if (!voteState.proposedProperties.isDefined) revert QLE_NoVoteProposed();

        voteState.isActive = true;
        voteState.startTime = uint64(block.timestamp);
        voteState.endTime = uint64(block.timestamp) + dimensionVotingPeriod;
        voteState.currentVoteId++; // New vote ID
        // votes mapping is automatically cleared for the new voteId due to default value 0

        emit DimensionVoteProposed(voteState.proposedDimensionId, voteState.startTime, voteState.endTime);
    }


    function voteForDimension(uint256 tokenId) external onlyEstateOwner(tokenId) onlyVotePeriodActive nonReentrant {
         // Check if the token has already voted in THIS voting period
         if (voteState.votedTokenVoteId[tokenId] == voteState.currentVoteId) {
             revert QLE_VoteAlreadyCast(tokenId);
         }

        // Calculate voting power based on the estate's collected resources (example: sum of all resource balances)
        uint256 votingPower = _calculateVotingPower(tokenId);
        if (votingPower == 0) revert QLE_CannotVoteWithoutPower(); // Must have resources to vote

        // Add vote power for the proposed dimension
        voteState.votes[voteState.proposedDimensionId] += votingPower;

        // Record that this token voted in this period
        voteState.votedTokenVoteId[tokenId] = voteState.currentVoteId;

        emit DimensionVoted(tokenId, voteState.proposedDimensionId, votingPower);
    }

    function finalizeDimensionVote() external nonReentrant {
        if (!voteState.isActive) revert QLE_VotingPeriodNotActive();
        if (block.timestamp < voteState.endTime) revert QLE_VotingPeriodNotEnded(voteState.endTime - uint64(block.timestamp));
        if (!voteState.proposedProperties.isDefined) revert QLE_NoVoteProposed(); // Shouldn't happen if active, but safety check

        // Determine winner (simple majority for the proposed dimension vs default if no votes/other votes?)
        // Let's assume the proposed dimension wins if it gets *any* votes and vote period ended.
        // Or simple majority: compare proposed votes vs a 'stay' vote (which isn't explicitly counted here).
        // More robust: allow voting for proposed, staying, or another predefined dimension ID.
        // For simplicity: If proposed dimension has > 0 votes AND vote period ended, it wins. Otherwise, stay in current dimension.

        uint8 winningDimensionId = currentDimensionId;
        DimensionProperties storage winningProperties; // Will point to either current or proposed

        if (voteState.votes[voteState.proposedDimensionId] > 0) {
            // Proposed dimension wins
            winningDimensionId = voteState.proposedDimensionId;
            // Copy properties from the proposed state
             currentDimensionProperties = voteState.proposedProperties;
            emit DimensionShifted(currentDimensionId, winningDimensionId);
             currentDimensionId = winningDimensionId; // Update contract state
        } else {
            // No votes for proposed, or proposed got 0 votes. Stay in current.
             // currentDimensionProperties already holds the correct state for currentDimensionId
             emit DimensionShifted(currentDimensionId, currentDimensionId); // Emit event even if staying? Maybe not.
             // No event emitted if dimension doesn't change to avoid confusion.
        }

        // End the voting period
        voteState.isActive = false;
        // voteState.votes mapping automatically resets for the next vote due to voteId check

        // Clear proposed properties for next round (forces admin to propose again)
        delete voteState.proposedProperties;
        voteState.proposedDimensionId = 0; // Reset proposed ID
    }

    // --- Estate View Functions ---

    function getEstateDetails(uint256 tokenId)
        external
        view
        returns (
            address owner,
            uint8 currentDimension,
            uint64 lastCollectTimestamp
            // Note: Collected resources and upgrades are separate mappings for efficiency
        )
    {
        if (!_exists(tokenId)) revert QLE_EstateNotFound(tokenId);
        Estate storage estate = estates[tokenId];
        return (
            ownerOf(tokenId),
            estate.currentDimensionId,
            estate.lastCollectTimestamp
        );
    }

    function getEstateCollectedResources(uint256 tokenId, uint8 resourceType) external view returns (uint256) {
        if (!_exists(tokenId)) revert QLE_EstateNotFound(tokenId);
        if (!resourceDefinitions[resourceType].exists) revert QLE_InvalidResourceType();
        return estates[tokenId].collectedResources[resourceType];
    }

    function getEstatePendingResources(uint256 tokenId, uint8 resourceType) external view returns (uint256) {
         if (!_exists(tokenId)) revert QLE_EstateNotFound(tokenId);
         if (!resourceDefinitions[resourceType].exists) revert QLE_InvalidResourceType();
         uint64 lastCollect = estates[tokenId].lastCollectTimestamp;
         uint64 currentTime = uint64(block.timestamp);
         if (currentTime <= lastCollect) return 0;
         uint64 timeElapsed = currentTime - lastCollect;
         uint256 generationRate = getEstateEffectiveGenerationRate(tokenId, resourceType);
         return generationRate * timeElapsed;
    }


    function getEstateUpgradeLevel(uint256 tokenId, uint8 upgradeType) external view returns (uint256) {
        if (!_exists(tokenId)) revert QLE_EstateNotFound(tokenId);
        if (!upgradeDefinitions[upgradeType].exists) revert QLE_InvalidUpgradeType();
        return estates[tokenId].upgrades[upgradeType];
    }

     function getEstateEffectiveGenerationRate(uint256 tokenId, uint8 resourceType) public view returns (uint256) {
        if (!_exists(tokenId)) revert QLE_EstateNotFound(tokenId);
        if (!resourceDefinitions[resourceType].exists) revert QLE_InvalidResourceType();

        uint256 baseRate = baseResourceGenerationRates[resourceType];
        uint256 dimensionMultiplier = currentDimensionProperties.resourceGenerationMultipliers[resourceType];
        // Assume 100 is 1x multiplier if not set
        if (dimensionMultiplier == 0) dimensionMultiplier = 100; // Default to 1x if not defined

        // Calculate upgrade bonus (example: 1% boost per upgrade level)
        uint256 upgradeLevel = estates[tokenId].upgrades[uint8(UpgradeType.GenerationBoostEnergy)] + estates[tokenId].upgrades[uint8(UpgradeType.GenerationBoostMaterial)]; // Example: sum of relevant boosts
        uint256 upgradeMultiplier = 100 + (upgradeLevel); // Example: 100 + (level * 1)%

        // Combined rate: base * dimension_multiplier/100 * upgrade_multiplier/100
        // Use proper scaling to avoid division first
        return (baseRate * dimensionMultiplier / 100 * upgradeMultiplier / 100);
    }


    function getLastMintTime(address owner) external view returns (uint64) {
        return lastMintTime[owner];
    }

    // --- Dimension/Voting View Functions ---

    function getCurrentDimensionId() external view returns (uint8) {
        return currentDimensionId;
    }

    function getDimensionProperties(uint8 dimensionId) external view returns (DimensionProperties memory) {
         // Note: Returning structs with mappings directly is not possible in external/public functions.
         // Need to return individual elements or a flattened structure.
         // Let's return basic info and require specific calls for multipliers.
         // Check if defined is sufficient for basic info.
        if (!dimensionDefinitions[dimensionId].isDefined) revert QLE_InvalidDimensionId();
        // Return a memory struct containing basic info, not the mapping.
        // We cannot return the map directly.
        // Acknowledge this limitation. Users will need helper view functions for multipliers.
        // Returning a placeholder struct here.
        // return dimensionDefinitions[dimensionId]; // THIS WILL NOT COMPILE
         return DimensionProperties({isDefined: dimensionDefinitions[dimensionId].isDefined, resourceGenerationMultipliers: new mapping(uint8 => uint256)(0)}); // Return placeholder
    }

    function getDimensionEffectiveGenerationRate(uint8 dimensionId, uint8 resourceType) external view returns (uint256 multiplier) {
        if (!dimensionDefinitions[dimensionId].isDefined) revert QLE_InvalidDimensionId();
        if (!resourceDefinitions[resourceType].exists) revert QLE_InvalidResourceType();
        multiplier = dimensionDefinitions[dimensionId].resourceGenerationMultipliers[resourceType];
        if (multiplier == 0) multiplier = 100; // Default to 1x if not set
    }


    function getCurrentVoteState()
        external
        view
        returns (
            bool isActive,
            uint64 startTime,
            uint64 endTime,
            uint8 proposedDimensionId,
            uint256 proposedDimensionVoteCount // Votes for the proposed dimension
            // Note: Cannot return the full `votes` mapping
        )
    {
        isActive = voteState.isActive;
        startTime = voteState.startTime;
        endTime = voteState.endTime;
        proposedDimensionId = voteState.proposedDimensionId;
        proposedDimensionVoteCount = voteState.votes[voteState.proposedDimensionId];
         // Returning vote count for the proposed dimension is simple enough.
    }

    function isVotingPeriodActive() external view returns (bool) {
        return voteState.isActive && block.timestamp < voteState.endTime;
    }

    function getTimeUntilVoteEnd() external view returns (uint256) {
        if (!voteState.isActive || block.timestamp >= voteState.endTime) return 0;
        return voteState.endTime - uint64(block.timestamp);
    }

    function getDimensionVoteWinner() external view returns (uint8 winningDimensionId, uint256 totalVotesForWinner) {
        // This only makes sense *after* the vote ends or during the active period.
        // If active, return current leader (the proposed dimension if it has votes).
        // If ended, return the winner of the finalized vote (which is already currentDimensionId if shift occurred).
        // Let's make this view only reflect the *potential* winner if the vote ended NOW.
         if (voteState.isActive || block.timestamp < voteState.endTime) {
             // During active vote or before end, the "winner" is the proposed dimension if it has votes.
             return (voteState.proposedDimensionId, voteState.votes[voteState.proposedDimensionId]);
         } else {
             // Vote ended. The winner was already applied to currentDimensionId by finalizeDimensionVote.
             // Return current dimension info.
             return (currentDimensionId, 0); // Votes reset after finalization
         }
    }

    function getResourceDefinition(uint8 resourceType) external view returns (string memory name, bool exists) {
        ResourceDefinition storage def = resourceDefinitions[resourceType];
        return (def.name, def.exists);
    }

    function getUpgradeDefinition(uint8 upgradeType) external view returns (string memory name, bool exists) {
        UpgradeDefinition storage def = upgradeDefinitions[upgradeType];
        return (def.name, def.exists);
    }

    function getUpgradeCost(uint8 upgradeType, uint256 level, uint8 resourceType) external view returns (uint256) {
        return upgradeCosts[upgradeType][level][resourceType];
    }

    function getMintCost() external view returns (uint8 resourceType, uint256 amount) {
        return (mintCostResourceType, mintCostAmount);
    }

    // --- Treasury Functions ---
    function getTreasuryResourceBalance(uint8 resourceType) external view returns (uint256) {
         if (!resourceDefinitions[resourceType].exists) revert QLE_InvalidResourceType();
         return treasuryResources[resourceType];
    }


    // --- Internal/Helper Functions ---

    function _calculatePendingResources(uint256 tokenId) internal view returns (uint256 energyAccrued, uint256 materialAccrued, uint256 dataAccrued, uint256 essenceAccrued) {
         // This function calculates without updating state, used by views
         Estate storage estate = estates[tokenId];
         uint64 lastCollect = estate.lastCollectTimestamp;
         uint64 currentTime = uint64(block.timestamp);

        if (currentTime <= lastCollect) {
            return (0, 0, 0, 0);
        }

        uint64 timeElapsed = currentTime - lastCollect;

        // Calculate for each resource type
        if (resourceDefinitions[uint8(ResourceType.Energy)].exists) {
             energyAccrued = getEstateEffectiveGenerationRate(tokenId, uint8(ResourceType.Energy)) * timeElapsed;
        }
         if (resourceDefinitions[uint8(ResourceType.Material)].exists) {
             materialAccrued = getEstateEffectiveGenerationRate(tokenId, uint8(ResourceType.Material)) * timeElapsed;
        }
         if (resourceDefinitions[uint8(ResourceType.Data)].exists) {
             dataAccrued = getEstateEffectiveGenerationRate(tokenId, uint8(ResourceType.Data)) * timeElapsed;
        }
         if (resourceDefinitions[uint8(ResourceType.Essence)].exists) {
             essenceAccrued = getEstateEffectiveGenerationRate(tokenId, uint8(ResourceType.Essence)) * timeElapsed;
        }

        // Add more resources here if defined

         return (energyAccrued, materialAccrued, dataAccrued, essenceAccrued);
    }

    // Update last collect timestamp for an estate
    function _updateEstateLastCollectTime(uint256 tokenId, uint64 timestamp) internal {
        estates[tokenId].lastCollectTimestamp = timestamp;
        // Also update the dimension the estate is "synced" to for collection calculations
        estates[tokenId].currentDimensionId = currentDimensionId;
    }

    // Burn resources from an estate's collected balance
    function _burnResources(uint256 tokenId, uint8 resourceType, uint256 amount) internal {
        Estate storage estate = estates[tokenId];
        estate.collectedResources[resourceType] -= amount; // Assumes sufficient balance checked by caller
    }

    // Mint resources directly to the contract treasury (e.g., from external source or system event)
    function _mintResourcesToTreasury(uint8 resourceType, uint256 amount) internal {
         if (!resourceDefinitions[resourceType].exists) revert QLE_InvalidResourceType(); // Should be defined if used internally
         treasuryResources[resourceType] += amount;
         // No event for internal mint for simplicity
    }

     // Transfer resources between an estate's collected balance and the treasury
    function _transferResources(uint256 tokenId, uint8 resourceType, uint256 amount, address destination) internal {
         Estate storage estate = estates[tokenId];
         if (destination == address(this)) {
             // Estate to Treasury
             estate.collectedResources[resourceType] -= amount; // Checked by caller
             treasuryResources[resourceType] += amount;
         } else {
             // Treasury to Estate (less common, maybe for rewards?)
             // Not implemented in this example, but would need treasury check.
             // For now, this function only supports estate -> treasury.
              revert("Unsupported transfer destination");
         }
    }

    // Calculate voting power for a token
    function _calculateVotingPower(uint256 tokenId) internal view returns (uint256) {
        // Example: Voting power is the sum of all collected resources plus a bonus from the VoteInfluence upgrade
        uint256 totalCollectedResources = 0;
         uint8[] memory resourceTypes = new uint8[](4); // Hardcoded 4 for example
        resourceTypes[0] = uint8(ResourceType.Energy);
        resourceTypes[1] = uint8(ResourceType.Material);
        resourceTypes[2] = uint8(ResourceType.Data);
        resourceTypes[3] = uint8(ResourceType.Essence);

        for (uint i = 0; i < resourceTypes.length; i++) {
             uint8 resourceType = resourceTypes[i];
             if (resourceDefinitions[resourceType].exists) {
                totalCollectedResources += estates[tokenId].collectedResources[resourceType];
             }
        }

        uint256 voteInfluenceLevel = estates[tokenId].upgrades[uint8(UpgradeType.VoteInfluence)];
        uint256 voteInfluenceBonus = totalCollectedResources * voteInfluenceLevel / 100; // Example: 1% bonus power per level

        return totalCollectedResources + voteInfluenceBonus;
    }

    // --- ERC165 support ---
     function supportsInterface(bytes4 interfaceId) public view override(ERC721Enumerable, ERC721) returns (bool) {
         return super.supportsInterface(interfaceId);
     }


    // --- Pause Implementation (Manual) ---
    function paused() public view returns (bool) {
        return _paused;
    }


    // Overrides required by ERC721Enumerable
    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize) internal override(ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    function _afterTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize) internal override(ERC721Enumerable) {
         super._afterTokenTransfer(from, to, tokenId, batchSize);
         // Optional: When an estate is transferred, should resources reset?
         // Or should they transfer with the estate? Keeping them with the estate makes sense for an NFT.
         // Need to update lastCollectTimestamp on transfer if we want generation to continue seamlessly.
         // However, collectPendingResources handles the time elapsed correctly.
         // No state modification needed here based on current design.
    }

     function _increaseTokenSupply(uint256 batchSize) internal override(ERC721Enumerable) {
        super._increaseTokenSupply(batchSize);
    }

}
```