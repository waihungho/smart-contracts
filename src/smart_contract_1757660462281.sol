This smart contract, **SentinelNexus**, introduces an advanced concept of "Digital Sentinels" – unique, evolving NFTs that represent autonomous agents. These Sentinels consume resources (EnergyEssence tokens) to stay active, perform abstract tasks (attested off-chain), and earn rewards (InsightCores tokens), while accumulating reputation and evolving through new traits. The contract aims to create a dynamic, resource-managed, and reputation-driven ecosystem for programmable digital entities.

---

## Smart Contract: SentinelNexus

**Contract Name:** `SentinelNexus`

**Core Concept:** An ecosystem of dynamic, evolving NFTs ("Digital Sentinels") that require resources to maintain, perform tasks, and gain reputation and new abilities. It bridges on-chain resource management and off-chain attested performance.

### Outline and Function Summary

**I. Core Infrastructure & ERC20 Tokens**
*   `EnergyEssence`: ERC20 token used to power Sentinels.
*   `InsightCores`: ERC20 token earned as rewards for tasks.
*   `SentinelNexus`: Main contract, deploys and manages Sentinels and their lifecycle.

**II. Data Structures**
*   `Trait`: Defines an evolvable characteristic for Sentinels.
*   `Sentinel`: Represents the dynamic NFT, holding its state (energy, reputation, traits, task module).

**III. Core Sentinel Management (ERC721 & Life Cycle)**
*   `constructor`: Initializes the contract, deploys associated ERC20 tokens, and sets the initial owner.
*   `mintSentinel`: Creates a new Sentinel NFT, assigning an initial name and (optionally) base traits.
*   `retireSentinel`: Allows an owner to burn their Sentinel NFT, permanently removing it from the ecosystem.
*   `getSentinelDetails`: Retrieves comprehensive information about a specific Sentinel.
*   `renameSentinel`: Allows the owner to change their Sentinel's name.

**IV. Resource Management (EnergyEssence)**
*   `depositEnergyEssence`: Users can deposit EnergyEssence tokens into the contract, to be used for their Sentinels.
*   `withdrawEnergyEssence`: Users can withdraw any unused EnergyEssence they have deposited.
*   `feedSentinel`: Replenishes a Sentinel's energy level by consuming deposited EnergyEssence.
*   `getSentinelEnergyLevel`: Calculates and returns the current energy level of a Sentinel, accounting for time-based decay.
*   `setEnergyConsumptionRate`: (Admin) Adjusts the global rate at which Sentinels consume energy over time.

**V. Evolution & Traits**
*   `defineNewTrait`: (Admin) Creates a new type of trait that Sentinels can potentially acquire.
*   `updateTraitEffect`: (Admin) Modifies the numerical effects (e.g., energy efficiency, reward bonus) of an existing trait.
*   `evolveSentinel`: Allows a Sentinel to acquire a new trait or upgrade an existing one, by spending accumulated `evolutionPoints`.
*   `removeTraitFromSentinel`: (Admin/System) Allows removal of a trait from a Sentinel, perhaps due to corruption or system events.
*   `getSentinelTraits`: Returns the list of traits a specific Sentinel possesses.

**VI. Task Execution & Rewards (InsightCores)**
*   `registerTaskModule`: (Admin) Registers an external contract that defines a specific type of task Sentinels can perform.
*   `assignTaskModuleToSentinel`: Assigns a specific registered task module to a Sentinel, determining its purpose.
*   `initiateTask`: Owner signals their Sentinel to attempt an off-chain task, consuming energy.
*   `attestTaskCompletion`: (Oracle) Confirms the successful completion of an off-chain task, awarding `InsightCores`, `reputationScore`, and `evolutionPoints` to the Sentinel.
*   `claimPendingRewards`: Allows users to claim their accumulated `InsightCores` earned by their Sentinels.
*   `getSentinelPendingRewards`: Returns the amount of `InsightCores` a Sentinel has accumulated but not yet claimed.

**VII. Reputation & Status**
*   `adjustReputationManually`: (Admin) Manually adjusts a Sentinel's reputation score.
*   `updateSentinelStatus`: (Admin/System) Allows changing a Sentinel's operational status (e.g., Active, Dormant, Corrupted).
*   `getSentinelReputation`: Returns the current reputation score of a Sentinel.
*   `getSentinelStatus`: Returns the current operational status of a Sentinel.

**VIII. Access Control & System Settings**
*   `setOracleAddress`: (Admin) Sets the address authorized to attest task completions.
*   `getOracleAddress`: Returns the currently authorized oracle address.
*   `setEvolutionPointCost`: (Admin) Sets the cost in evolution points to acquire or upgrade a trait.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

// --- ERC20 Tokens for the Sentinel Ecosystem ---

/// @title EnergyEssence
/// @notice ERC20 token used to power and maintain Sentinels.
contract EnergyEssence is ERC20, Ownable {
    constructor(address initialOwner) ERC20("EnergyEssence", "EE") Ownable(initialOwner) {}

    /// @notice Mints new EnergyEssence tokens. Only callable by the owner (SentinelNexus).
    /// @param to The address to mint tokens to.
    /// @param amount The amount of tokens to mint.
    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }
}

/// @title InsightCores
/// @notice ERC20 token earned as rewards for Sentinels completing tasks.
contract InsightCores is ERC20, Ownable {
    constructor(address initialOwner) ERC20("InsightCores", "IC") Ownable(initialOwner) {}

    /// @notice Mints new InsightCores tokens. Only callable by the owner (SentinelNexus).
    /// @param to The address to mint tokens to.
    /// @param amount The amount of tokens to mint.
    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }
}

// --- Interface for External Task Modules ---

/// @title ITaskModule
/// @notice Interface for external contracts that define specific types of tasks
///         that Sentinels can be assigned to. This allows for modularity and extensibility.
interface ITaskModule {
    /// @notice Returns a human-readable name for the task module.
    function getName() external view returns (string memory);

    /// @notice Returns a brief description of the tasks this module enables.
    function getDescription() external view returns (string memory);
}

// --- Main SentinelNexus Contract ---

/// @title SentinelNexus
/// @notice A sophisticated platform for managing and interacting with dynamic, evolving NFT-based Digital Sentinels.
///         Sentinels require resources (EnergyEssence) to perform tasks, earn rewards (InsightCores),
///         and accumulate reputation and evolution points to acquire new traits.
contract SentinelNexus is ERC721Enumerable, Ownable {
    using Counters for Counters.Counter;
    using SafeMath for uint256;
    using Strings for uint256;

    // --- State Variables ---

    Counters.Counter private _sentinelIds;
    address public oracleAddress; // Address authorized to attest task completion

    EnergyEssence public energyEssence;
    InsightCores public insightCores;

    // Sentinel Configuration
    uint256 public constant MAX_ENERGY = 10000; // Max energy level for a Sentinel
    uint256 public energyConsumptionRatePerDay = 100; // EE per day (scaled to seconds)
    uint256 public minEnergyForTask = 500; // Minimum energy required to initiate a task
    uint256 public baseTaskEnergyCost = 200; // Base EE consumed per task initiation

    uint256 public evolutionPointCostForTrait = 500; // EP needed to evolve a trait

    // --- Enums and Structs ---

    enum SentinelStatus {
        Active,
        Dormant, // Low energy, cannot perform tasks
        Corrupted, // Severely low reputation or other negative status
        Retired // Permanently removed (burned)
    }

    struct Trait {
        uint256 id;
        string name;
        string description;
        int256 energyEfficiencyBonus; // e.g., -10 for 10% less energy consumption, 10 for 10% more
        uint256 rewardMultiplierBonus; // e.g., 10 for 10% more rewards (scaled by 100)
        uint256 reputationGainBonus;   // e.g., 5 for 5 extra reputation points
        bool active; // Can be disabled by admin
    }

    struct Sentinel {
        uint256 id;
        string name;
        uint256 generation;
        SentinelStatus status;
        uint256 lastEnergyUpdateTimestamp;
        uint256 currentEnergy; // Max 10000
        int256 reputationScore; // Can be negative, affects task success/rewards
        uint256 evolutionPoints; // Points accumulated for evolving traits
        uint256 lastTaskCompletionTime;
        uint256 assignedTaskModuleId; // ID referencing a registered ITaskModule
        mapping(uint256 => bool) traits; // traitId => hasTrait (for quick lookup)
        uint256[] traitIds; // Array for easy enumeration of traits
    }

    // --- Mappings ---

    mapping(uint256 => Sentinel) public sentinels; // sentinelId => Sentinel details
    mapping(address => uint256) public userEnergyBalance; // owner address => total EE deposited
    mapping(uint256 => uint256) public sentinelPendingInsightCores; // sentinelId => pending IC rewards

    mapping(uint256 => Trait) public allTraits; // traitId => Trait details
    Counters.Counter private _traitIds;

    mapping(uint256 => address) public registeredTaskModules; // taskId => ITaskModule address
    Counters.Counter private _taskModuleIds;

    // --- Events ---

    event SentinelMinted(uint256 indexed sentinelId, address indexed owner, string name, uint256 generation);
    event SentinelRetired(uint256 indexed sentinelId, address indexed owner);
    event EnergyDeposited(address indexed user, uint256 amount);
    event EnergyWithdrawn(address indexed user, uint256 amount);
    event SentinelFed(uint256 indexed sentinelId, uint256 amount, uint256 newEnergy);
    event TraitDefined(uint256 indexed traitId, string name, string description);
    event TraitUpdated(uint256 indexed traitId, string name, bool active);
    event SentinelEvolved(uint256 indexed sentinelId, uint256 indexed traitId);
    event SentinelTraitRemoved(uint256 indexed sentinelId, uint256 indexed traitId);
    event TaskModuleRegistered(uint256 indexed moduleId, address moduleAddress, string name);
    event TaskModuleAssigned(uint256 indexed sentinelId, uint256 indexed moduleId);
    event TaskInitiated(uint256 indexed sentinelId, address indexed initiator, uint256 energyCost);
    event TaskCompleted(uint256 indexed sentinelId, uint256 rewards, uint256 reputationGained, uint256 evolutionPointsGained);
    event RewardsClaimed(uint256 indexed sentinelId, address indexed claimant, uint256 amount);
    event ReputationAdjusted(uint256 indexed sentinelId, int256 oldReputation, int256 newReputation);
    event SentinelStatusUpdated(uint256 indexed sentinelId, SentinelStatus oldStatus, SentinelStatus newStatus);
    event SentinelRenamed(uint256 indexed sentinelId, string oldName, string newName);
    event OracleAddressSet(address indexed oldOracle, address indexed newOracle);

    // --- Modifiers ---

    modifier onlyOracle() {
        require(msg.sender == oracleAddress, "SentinelNexus: Only oracle can call this function");
        _;
    }

    modifier onlySentinelOwner(uint256 sentinelId) {
        require(_isApprovedOrOwner(msg.sender, sentinelId), "SentinelNexus: Not owner or approved for sentinel");
        _;
    }

    // --- Constructor ---

    constructor(address initialOwner) ERC721("Digital Sentinel", "DSNTL") Ownable(initialOwner) {
        energyEssence = new EnergyEssence(address(this)); // SentinelNexus owns the EE token contract
        insightCores = new InsightCores(address(this)); // SentinelNexus owns the IC token contract
        oracleAddress = initialOwner; // Initially set owner as oracle
    }

    // --- Internal/Utility Functions ---

    /// @dev Calculates the current energy of a Sentinel, accounting for time decay.
    function _getCurrentEnergy(uint256 sentinelId) internal view returns (uint256) {
        Sentinel storage sentinel = sentinels[sentinelId];
        if (sentinel.status == SentinelStatus.Retired) return 0; // Retired sentinels have no energy

        uint256 timeElapsed = block.timestamp.sub(sentinel.lastEnergyUpdateTimestamp);
        uint256 energyLost = timeElapsed.mul(energyConsumptionRatePerDay).div(1 days); // Scale to days

        if (energyLost >= sentinel.currentEnergy) {
            return 0;
        }
        return sentinel.currentEnergy.sub(energyLost);
    }

    /// @dev Updates Sentinel's energy to its current decay state and sets last update time.
    function _syncEnergy(uint256 sentinelId) internal {
        Sentinel storage sentinel = sentinels[sentinelId];
        if (sentinel.status == SentinelStatus.Retired) return; // No sync for retired sentinels

        sentinel.currentEnergy = _getCurrentEnergy(sentinelId);
        sentinel.lastEnergyUpdateTimestamp = block.timestamp;

        // Auto-update status if critically low on energy
        if (sentinel.currentEnergy < minEnergyForTask && sentinel.status == SentinelStatus.Active) {
            _updateSentinelStatus(sentinelId, SentinelStatus.Dormant);
        } else if (sentinel.currentEnergy >= minEnergyForTask && sentinel.status == SentinelStatus.Dormant) {
            _updateSentinelStatus(sentinelId, SentinelStatus.Active);
        }
    }

    /// @dev Internal helper to update sentinel status and emit event.
    function _updateSentinelStatus(uint256 sentinelId, SentinelStatus newStatus) internal {
        Sentinel storage sentinel = sentinels[sentinelId];
        SentinelStatus oldStatus = sentinel.status;
        if (oldStatus != newStatus) {
            sentinel.status = newStatus;
            emit SentinelStatusUpdated(sentinelId, oldStatus, newStatus);
        }
    }

    /// @dev Internal helper to add a trait to a sentinel.
    function _addTraitToSentinel(uint256 sentinelId, uint256 traitId) internal {
        Sentinel storage sentinel = sentinels[sentinelId];
        require(allTraits[traitId].active, "SentinelNexus: Trait not active or does not exist");
        require(!sentinel.traits[traitId], "SentinelNexus: Sentinel already has this trait");

        sentinel.traits[traitId] = true;
        sentinel.traitIds.push(traitId); // Add to enumerable array
        emit SentinelEvolved(sentinelId, traitId);
    }

    /// @dev Internal helper to remove a trait from a sentinel.
    function _removeTraitFromSentinel(uint256 sentinelId, uint256 traitId) internal {
        Sentinel storage sentinel = sentinels[sentinelId];
        require(sentinel.traits[traitId], "SentinelNexus: Sentinel does not have this trait");

        sentinel.traits[traitId] = false;
        // Remove from enumerable array (inefficient for large arrays, but traits should be limited)
        for (uint256 i = 0; i < sentinel.traitIds.length; i++) {
            if (sentinel.traitIds[i] == traitId) {
                sentinel.traitIds[i] = sentinel.traitIds[sentinel.traitIds.length - 1];
                sentinel.traitIds.pop();
                break;
            }
        }
        emit SentinelTraitRemoved(sentinelId, traitId);
    }

    // --- Core Sentinel Management (ERC721 & Life Cycle) ---

    /// @notice Mints a new Digital Sentinel NFT.
    /// @dev Only callable by the contract owner. Assigns a unique ID, initial name, and default energy.
    /// @param to The address that will own the new Sentinel.
    /// @param name The initial name for the Sentinel.
    function mintSentinel(address to, string memory name) public onlyOwner {
        _sentinelIds.increment();
        uint256 newId = _sentinelIds.current();

        // Basic pseudo-randomness for initial generation
        uint256 generation = (block.timestamp % 100) + 1;

        sentinels[newId] = Sentinel({
            id: newId,
            name: name,
            generation: generation,
            status: SentinelStatus.Active,
            lastEnergyUpdateTimestamp: block.timestamp,
            currentEnergy: MAX_ENERGY,
            reputationScore: 0,
            evolutionPoints: 0,
            lastTaskCompletionTime: 0,
            assignedTaskModuleId: 0, // No task module assigned initially
            traitIds: new uint256[](0)
        });

        _mint(to, newId);
        emit SentinelMinted(newId, to, name, generation);
    }

    /// @notice Allows the owner to retire (burn) their Sentinel NFT.
    /// @dev Permanently removes the Sentinel from the ecosystem. Any pending rewards or energy are lost.
    /// @param sentinelId The ID of the Sentinel to retire.
    function retireSentinel(uint256 sentinelId) public onlySentinelOwner(sentinelId) {
        _updateSentinelStatus(sentinelId, SentinelStatus.Retired);
        _burn(sentinelId);
        emit SentinelRetired(sentinelId, msg.sender);
    }

    /// @notice Renames a Sentinel.
    /// @param sentinelId The ID of the Sentinel to rename.
    /// @param newName The new name for the Sentinel.
    function renameSentinel(uint256 sentinelId, string memory newName) public onlySentinelOwner(sentinelId) {
        require(bytes(newName).length > 0, "SentinelNexus: Name cannot be empty");
        string memory oldName = sentinels[sentinelId].name;
        sentinels[sentinelId].name = newName;
        emit SentinelRenamed(sentinelId, oldName, newName);
    }

    /// @notice Returns comprehensive details about a specific Sentinel.
    /// @param sentinelId The ID of the Sentinel.
    /// @return A tuple containing all relevant Sentinel information.
    function getSentinelDetails(uint256 sentinelId)
        public
        view
        returns (
            uint256 id,
            string memory name,
            uint256 generation,
            SentinelStatus status,
            uint256 currentEnergy,
            int256 reputationScore,
            uint256 evolutionPoints,
            uint256 lastTaskCompletionTime,
            uint256 assignedTaskModuleId,
            uint256[] memory traitIds
        )
    {
        Sentinel storage sentinel = sentinels[sentinelId];
        return (
            sentinel.id,
            sentinel.name,
            sentinel.generation,
            sentinel.status,
            _getCurrentEnergy(sentinelId), // Always return current decayed energy
            sentinel.reputationScore,
            sentinel.evolutionPoints,
            sentinel.lastTaskCompletionTime,
            sentinel.assignedTaskModuleId,
            sentinel.traitIds
        );
    }

    // --- Resource Management (EnergyEssence) ---

    /// @notice Allows users to deposit EnergyEssence tokens into the contract for their Sentinels.
    /// @param amount The amount of EnergyEssence to deposit.
    function depositEnergyEssence(uint256 amount) public {
        require(amount > 0, "SentinelNexus: Deposit amount must be greater than zero");
        energyEssence.transferFrom(msg.sender, address(this), amount);
        userEnergyBalance[msg.sender] = userEnergyBalance[msg.sender].add(amount);
        emit EnergyDeposited(msg.sender, amount);
    }

    /// @notice Allows users to withdraw any unused EnergyEssence they have deposited.
    /// @param amount The amount of EnergyEssence to withdraw.
    function withdrawEnergyEssence(uint256 amount) public {
        require(amount > 0, "SentinelNexus: Withdraw amount must be greater than zero");
        require(userEnergyBalance[msg.sender] >= amount, "SentinelNexus: Insufficient deposited EE balance");
        userEnergyBalance[msg.sender] = userEnergyBalance[msg.sender].sub(amount);
        energyEssence.transfer(msg.sender, amount);
        emit EnergyWithdrawn(msg.sender, amount);
    }

    /// @notice Feeds a Sentinel with EnergyEssence, replenishing its energy.
    /// @param sentinelId The ID of the Sentinel to feed.
    /// @param amount The amount of EnergyEssence to consume for feeding.
    function feedSentinel(uint256 sentinelId, uint256 amount) public onlySentinelOwner(sentinelId) {
        require(amount > 0, "SentinelNexus: Feed amount must be greater than zero");
        require(userEnergyBalance[msg.sender] >= amount, "SentinelNexus: Insufficient deposited EE balance");

        _syncEnergy(sentinelId); // Sync energy before feeding

        Sentinel storage sentinel = sentinels[sentinelId];
        require(sentinel.status != SentinelStatus.Retired, "SentinelNexus: Sentinel is retired");

        userEnergyBalance[msg.sender] = userEnergyBalance[msg.sender].sub(amount);

        // Convert EE amount to energy points (e.g., 1 EE = 1 energy point)
        uint256 energyToRestore = amount;
        uint256 oldEnergy = sentinel.currentEnergy;
        sentinel.currentEnergy = sentinel.currentEnergy.add(energyToRestore);
        if (sentinel.currentEnergy > MAX_ENERGY) {
            uint256 excessEnergy = sentinel.currentEnergy.sub(MAX_ENERGY);
            sentinel.currentEnergy = MAX_ENERGY;
            // Optionally, refund excess EE or convert to evolution points
            userEnergyBalance[msg.sender] = userEnergyBalance[msg.sender].add(excessEnergy);
        }

        sentinel.lastEnergyUpdateTimestamp = block.timestamp; // Reset timer
        _syncEnergy(sentinelId); // Re-sync to potentially update status from Dormant to Active

        emit SentinelFed(sentinelId, amount, sentinel.currentEnergy);
    }

    /// @notice Sets the global energy consumption rate for all Sentinels.
    /// @dev Only callable by the contract owner.
    /// @param ratePerDay The new energy consumption rate in EE per day.
    function setEnergyConsumptionRate(uint256 ratePerDay) public onlyOwner {
        energyConsumptionRatePerDay = ratePerDay;
    }

    // --- Evolution & Traits ---

    /// @notice Defines a new type of trait that Sentinels can acquire.
    /// @dev Only callable by the contract owner.
    /// @param name The name of the trait (e.g., "Adaptive Shielding").
    /// @param description A brief description of the trait's effects.
    /// @param energyEfficiencyBonus Bonus/penalty to energy consumption (e.g., -10 for 10% less).
    /// @param rewardMultiplierBonus Bonus to rewards (e.g., 10 for 10% more, scaled by 100).
    /// @param reputationGainBonus Bonus to reputation earned from tasks.
    function defineNewTrait(
        string memory name,
        string memory description,
        int256 energyEfficiencyBonus,
        uint256 rewardMultiplierBonus,
        uint256 reputationGainBonus
    ) public onlyOwner {
        _traitIds.increment();
        uint256 newTraitId = _traitIds.current();
        allTraits[newTraitId] = Trait({
            id: newTraitId,
            name: name,
            description: description,
            energyEfficiencyBonus: energyEfficiencyBonus,
            rewardMultiplierBonus: rewardMultiplierBonus,
            reputationGainBonus: reputationGainBonus,
            active: true
        });
        emit TraitDefined(newTraitId, name, description);
    }

    /// @notice Updates the parameters of an existing trait.
    /// @dev Only callable by the contract owner.
    /// @param traitId The ID of the trait to update.
    /// @param name The new name of the trait.
    /// @param description The new description.
    /// @param energyEfficiencyBonus New energy efficiency bonus.
    /// @param rewardMultiplierBonus New reward multiplier bonus.
    /// @param reputationGainBonus New reputation gain bonus.
    /// @param active New active status.
    function updateTraitEffect(
        uint256 traitId,
        string memory name,
        string memory description,
        int256 energyEfficiencyBonus,
        uint256 rewardMultiplierBonus,
        uint256 reputationGainBonus,
        bool active
    ) public onlyOwner {
        require(allTraits[traitId].id != 0, "SentinelNexus: Trait does not exist");
        allTraits[traitId] = Trait({
            id: traitId,
            name: name,
            description: description,
            energyEfficiencyBonus: energyEfficiencyBonus,
            rewardMultiplierBonus: rewardMultiplierBonus,
            reputationGainBonus: reputationGainBonus,
            active: active
        });
        emit TraitUpdated(traitId, name, active);
    }

    /// @notice Allows a Sentinel to acquire a new trait or upgrade an existing one, by spending evolution points.
    /// @dev Callable by the Sentinel owner.
    /// @param sentinelId The ID of the Sentinel to evolve.
    /// @param traitId The ID of the trait to add/upgrade.
    function evolveSentinel(uint256 sentinelId, uint256 traitId) public onlySentinelOwner(sentinelId) {
        _syncEnergy(sentinelId);
        Sentinel storage sentinel = sentinels[sentinelId];
        require(sentinel.status != SentinelStatus.Retired, "SentinelNexus: Sentinel is retired");
        require(allTraits[traitId].active, "SentinelNexus: Trait is not active or does not exist");
        require(!sentinel.traits[traitId], "SentinelNexus: Sentinel already has this trait");
        require(sentinel.evolutionPoints >= evolutionPointCostForTrait, "SentinelNexus: Not enough evolution points");

        sentinel.evolutionPoints = sentinel.evolutionPoints.sub(evolutionPointCostForTrait);
        _addTraitToSentinel(sentinelId, traitId);
    }

    /// @notice (Admin/System) Removes a trait from a Sentinel, potentially due to negative events or system adjustments.
    /// @dev Only callable by the contract owner.
    /// @param sentinelId The ID of the Sentinel.
    /// @param traitId The ID of the trait to remove.
    function removeTraitFromSentinel(uint256 sentinelId, uint256 traitId) public onlyOwner {
        require(sentinels[sentinelId].id != 0, "SentinelNexus: Sentinel does not exist");
        _removeTraitFromSentinel(sentinelId, traitId);
    }

    /// @notice Returns an array of trait IDs possessed by a Sentinel.
    /// @param sentinelId The ID of the Sentinel.
    /// @return An array of uint256 representing trait IDs.
    function getSentinelTraits(uint256 sentinelId) public view returns (uint256[] memory) {
        require(sentinels[sentinelId].id != 0, "SentinelNexus: Sentinel does not exist");
        return sentinels[sentinelId].traitIds;
    }

    /// @notice Sets the cost in evolution points for acquiring a new trait.
    /// @dev Only callable by the contract owner.
    /// @param cost The new evolution point cost.
    function setEvolutionPointCost(uint256 cost) public onlyOwner {
        require(cost > 0, "SentinelNexus: Evolution point cost must be positive");
        evolutionPointCostForTrait = cost;
    }

    // --- Task Execution & Rewards (InsightCores) ---

    /// @notice Registers an external Task Module contract.
    /// @dev Only callable by the contract owner. Allows for modular task definitions.
    /// @param moduleAddress The address of the ITaskModule contract.
    function registerTaskModule(address moduleAddress) public onlyOwner {
        require(moduleAddress != address(0), "SentinelNexus: Invalid module address");
        // Ensure it implements the interface
        ITaskModule module = ITaskModule(moduleAddress);
        module.getName(); // Call to verify interface implementation

        _taskModuleIds.increment();
        uint256 newModuleId = _taskModuleIds.current();
        registeredTaskModules[newModuleId] = moduleAddress;
        emit TaskModuleRegistered(newModuleId, moduleAddress, module.getName());
    }

    /// @notice Assigns a specific registered Task Module to a Sentinel.
    /// @dev Callable by the Sentinel owner. Determines the type of tasks the Sentinel performs.
    /// @param sentinelId The ID of the Sentinel.
    /// @param moduleId The ID of the registered Task Module.
    function assignTaskModuleToSentinel(uint256 sentinelId, uint256 moduleId) public onlySentinelOwner(sentinelId) {
        require(sentinels[sentinelId].id != 0, "SentinelNexus: Sentinel does not exist");
        require(registeredTaskModules[moduleId] != address(0), "SentinelNexus: Task module not registered");
        sentinels[sentinelId].assignedTaskModuleId = moduleId;
        emit TaskModuleAssigned(sentinelId, moduleId);
    }

    /// @notice Initiates an off-chain task for a Sentinel. Consumes energy.
    /// @dev Callable by the Sentinel owner. This signals the intention to perform a task.
    ///      Actual completion is confirmed by an oracle.
    /// @param sentinelId The ID of the Sentinel to initiate a task for.
    function initiateTask(uint256 sentinelId) public onlySentinelOwner(sentinelId) {
        _syncEnergy(sentinelId);
        Sentinel storage sentinel = sentinels[sentinelId];

        require(sentinel.status == SentinelStatus.Active, "SentinelNexus: Sentinel is not active (check energy)");
        require(sentinel.assignedTaskModuleId != 0, "SentinelNexus: Sentinel has no assigned task module");

        // Calculate actual energy cost, considering traits
        uint256 actualEnergyCost = baseTaskEnergyCost;
        for (uint256 i = 0; i < sentinel.traitIds.length; i++) {
            uint256 traitId = sentinel.traitIds[i];
            Trait storage trait = allTraits[traitId];
            if (trait.active && trait.energyEfficiencyBonus != 0) {
                // Apply bonus/penalty. Example: -10 efficiency means 10% less cost.
                // 1000 base - (1000 * 10 / 100) = 900
                // 1000 base + (1000 * -10 / 100) = 1100
                actualEnergyCost = actualEnergyCost.add(actualEnergyCost.mul(uint256(trait.energyEfficiencyBonus)).div(100));
            }
        }

        require(sentinel.currentEnergy >= actualEnergyCost, "SentinelNexus: Not enough energy for task");

        sentinel.currentEnergy = sentinel.currentEnergy.sub(actualEnergyCost);
        sentinel.lastEnergyUpdateTimestamp = block.timestamp; // Reset timer after task
        _syncEnergy(sentinelId); // Re-sync to potentially update status to Dormant if energy is low
        emit TaskInitiated(sentinelId, msg.sender, actualEnergyCost);
    }

    /// @notice Attests to the successful completion of an off-chain task by a Sentinel.
    /// @dev Only callable by the designated `oracleAddress`. Awards rewards, reputation, and evolution points.
    /// @param sentinelId The ID of the Sentinel that completed the task.
    /// @param baseRewardAmount The base amount of InsightCores to award.
    /// @param baseReputationGain The base amount of reputation to award.
    /// @param baseEvolutionPoints The base amount of evolution points to award.
    function attestTaskCompletion(
        uint256 sentinelId,
        uint256 baseRewardAmount,
        uint256 baseReputationGain,
        uint256 baseEvolutionPoints
    ) public onlyOracle {
        _syncEnergy(sentinelId);
        Sentinel storage sentinel = sentinels[sentinelId];
        require(sentinel.status != SentinelStatus.Retired, "SentinelNexus: Sentinel is retired");
        // Add additional checks if needed, e.g., if a task was recently initiated.

        // Calculate actual rewards, reputation, and evolution points considering traits
        uint256 actualRewardAmount = baseRewardAmount;
        uint256 actualReputationGain = baseReputationGain;
        uint256 actualEvolutionPoints = baseEvolutionPoints;

        for (uint256 i = 0; i < sentinel.traitIds.length; i++) {
            uint256 traitId = sentinel.traitIds[i];
            Trait storage trait = allTraits[traitId];
            if (trait.active) {
                if (trait.rewardMultiplierBonus != 0) {
                    actualRewardAmount = actualRewardAmount.add(actualRewardAmount.mul(trait.rewardMultiplierBonus).div(100));
                }
                if (trait.reputationGainBonus != 0) {
                    actualReputationGain = actualReputationGain.add(trait.reputationGainBonus);
                }
            }
        }

        sentinelPendingInsightCores[sentinelId] = sentinelPendingInsightCores[sentinelId].add(actualRewardAmount);
        sentinel.reputationScore = sentinel.reputationScore.add(int256(actualReputationGain));
        sentinel.evolutionPoints = sentinel.evolutionPoints.add(actualEvolutionPoints);
        sentinel.lastTaskCompletionTime = block.timestamp;

        // Mint InsightCores to the contract's balance to be claimed later
        insightCores.mint(address(this), actualRewardAmount);

        emit TaskCompleted(sentinelId, actualRewardAmount, actualReputationGain, actualEvolutionPoints);
    }

    /// @notice Allows a Sentinel's owner to claim their accumulated InsightCores rewards.
    /// @param sentinelId The ID of the Sentinel for which to claim rewards.
    function claimPendingRewards(uint256 sentinelId) public onlySentinelOwner(sentinelId) {
        uint256 amount = sentinelPendingInsightCores[sentinelId];
        require(amount > 0, "SentinelNexus: No pending rewards to claim");

        sentinelPendingInsightCores[sentinelId] = 0;
        insightCores.transfer(msg.sender, amount); // Transfer from contract balance

        emit RewardsClaimed(sentinelId, msg.sender, amount);
    }

    /// @notice Returns the amount of InsightCores a Sentinel has accumulated but not yet claimed.
    /// @param sentinelId The ID of the Sentinel.
    /// @return The amount of pending InsightCores.
    function getSentinelPendingRewards(uint256 sentinelId) public view returns (uint256) {
        return sentinelPendingInsightCores[sentinelId];
    }

    // --- Reputation & Status ---

    /// @notice Manually adjusts a Sentinel's reputation score.
    /// @dev Only callable by the contract owner.
    /// @param sentinelId The ID of the Sentinel.
    /// @param adjustment The amount to add or subtract from the reputation score.
    function adjustReputationManually(uint256 sentinelId, int256 adjustment) public onlyOwner {
        require(sentinels[sentinelId].id != 0, "SentinelNexus: Sentinel does not exist");
        int256 oldReputation = sentinels[sentinelId].reputationScore;
        sentinels[sentinelId].reputationScore = sentinels[sentinelId].reputationScore.add(adjustment);
        emit ReputationAdjusted(sentinelId, oldReputation, sentinels[sentinelId].reputationScore);
    }

    /// @notice Updates the operational status of a Sentinel.
    /// @dev Only callable by the contract owner. Can be used for maintenance or game mechanics.
    /// @param sentinelId The ID of the Sentinel.
    /// @param newStatus The new status to set for the Sentinel.
    function updateSentinelStatus(uint256 sentinelId, SentinelStatus newStatus) public onlyOwner {
        require(sentinels[sentinelId].id != 0, "SentinelNexus: Sentinel does not exist");
        require(newStatus != SentinelStatus.Retired, "SentinelNexus: Use retireSentinel to retire");
        _updateSentinelStatus(sentinelId, newStatus);
    }

    /// @notice Returns the current reputation score of a Sentinel.
    /// @param sentinelId The ID of the Sentinel.
    /// @return The Sentinel's reputation score.
    function getSentinelReputation(uint256 sentinelId) public view returns (int256) {
        require(sentinels[sentinelId].id != 0, "SentinelNexus: Sentinel does not exist");
        return sentinels[sentinelId].reputationScore;
    }

    /// @notice Returns the current operational status of a Sentinel.
    /// @param sentinelId The ID of the Sentinel.
    /// @return The Sentinel's status (Active, Dormant, Corrupted, Retired).
    function getSentinelStatus(uint256 sentinelId) public view returns (SentinelStatus) {
        require(sentinels[sentinelId].id != 0, "SentinelNexus: Sentinel does not exist");
        _syncEnergy(sentinelId); // Ensure status reflects current energy
        return sentinels[sentinelId].status;
    }

    /// @notice Returns the address of the assigned task module for a Sentinel.
    /// @param sentinelId The ID of the Sentinel.
    /// @return The address of the assigned ITaskModule.
    function getSentinelTaskModule(uint256 sentinelId) public view returns (address) {
        require(sentinels[sentinelId].id != 0, "SentinelNexus: Sentinel does not exist");
        return registeredTaskModules[sentinels[sentinelId].assignedTaskModuleId];
    }

    // --- Access Control & System Settings ---

    /// @notice Sets the address authorized to attest task completions.
    /// @dev Only callable by the contract owner.
    /// @param newOracleAddress The new address for the oracle.
    function setOracleAddress(address newOracleAddress) public onlyOwner {
        require(newOracleAddress != address(0), "SentinelNexus: Oracle address cannot be zero");
        address oldOracle = oracleAddress;
        oracleAddress = newOracleAddress;
        emit OracleAddressSet(oldOracle, newOracleAddress);
    }

    /// @notice Returns the currently configured oracle address.
    function getOracleAddress() public view returns (address) {
        return oracleAddress;
    }
}
```