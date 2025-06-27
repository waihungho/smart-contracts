Okay, let's create a smart contract concept that combines several interesting ideas:

*   **Dynamic Digital Assets (Fabricators):** Assets that aren't static but have internal states (like integrity, efficiency, stability) that change over time or based on interactions.
*   **Resource Management:** These assets consume one type of token (Resources) to produce another (Yield).
*   **Time-Based Mechanics:** Upgrades and repairs take time. Processing happens over time.
*   **Degradation and Maintenance:** Assets degrade and require resources for repair, adding a layer of ongoing management.
*   **Leveling System:** Assets can be upgraded, improving their efficiency and capabilities.
*   **Delegation:** Owners can delegate the processing of their assets to others.
*   **Parameterized Governance/Admin:** Key parameters can be adjusted by an admin/governance mechanism (simplified to admin for this example).

This avoids directly copying standard ERC-20/ERC-721 logic (though it interacts with external ERC-20s) and isn't a simple staking pool or exchange. The core logic revolves around the lifecycle and state management of the "Fabricator" assets.

---

### Contract Name: `DigitalFabricatorForge`

**Concept:** A factory and management system for unique digital assets called "Fabricators". Fabricators consume a `ResourceToken` over time to produce a `YieldToken`, but require maintenance (repair) to prevent degradation and can be improved (upgraded).

**Advanced Concepts Used:**
1.  **Stateful/Dynamic Assets:** Assets (`Fabricators`) whose properties (`integrity`, `efficiency`, `stability`, `status`) change based on interaction and time, unlike typical static NFTs.
2.  **Resource & Yield Economy:** Implements a simple in-system economy requiring consumption of one token type to produce another.
3.  **Time-Based Mechanics:** Crucial logic (processing, upgrading, repairing) is dependent on `block.timestamp`.
4.  **Degradation and Maintenance:** Introduces a requirement for periodic user interaction and resource spending (`repair`) to maintain asset performance.
5.  **Parameterized Logic:** Many core formulas (costs, rates, decay, probabilities) are controlled by state variables, allowing for administrative tuning.
6.  **Processing Delegation:** Allows asset owners to grant permission for others to trigger resource consumption and yield generation on their behalf.
7.  **Batch Processing:** Provides a function for processing multiple assets efficiently (from a user perspective).

---

### Function Summary:

**Admin & Setup (7 functions):**
1.  `constructor`: Initializes the contract owner and key token addresses (assumed external ERC-20s).
2.  `setResourceTokenAddress`: Sets the address for the Resource ERC-20 token.
3.  `setYieldTokenAddress`: Sets the address for the Yield ERC-20 token.
4.  `setFabricatorMintCost`: Sets the cost in ResourceToken to mint a new Fabricator.
5.  `setBaseProcessingRates`: Sets the initial Resource input and Yield output rates for level 1 Fabricators.
6.  `setDegradationParameters`: Sets parameters related to integrity decay, repair costs, and broken chances.
7.  `setUpgradeParameters`: Sets parameters related to upgrade costs and time.

**Fabricator Lifecycle & Interaction (12 functions):**
8.  `mintFabricator`: Allows a user to mint a new Fabricator by paying `fabricatorMintCost` in ResourceTokens.
9.  `processFabricator`: The core function. Consumes ResourceTokens, produces YieldTokens based on time elapsed and Fabricator state, updates state (integrity, last processed time), and potentially changes status (e.g., `Broken`).
10. `batchProcessFabricators`: Allows a user to call `processFabricator` for multiple of their owned Fabricators in a single transaction.
11. `upgradeFabricator`: Starts the timed upgrade process for a Fabricator, consuming resources and changing status to `Upgrading`.
12. `finishUpgrade`: Completes the upgrade process after the required time has passed, increasing the Fabricator's level and updating stats.
13. `repairFabricator`: Starts the timed repair process, consuming resources and changing status to `Repairing`.
14. `finishRepair`: Completes the repair process after the required time has passed, restoring the Fabricator's integrity.
15. `transferFabricator`: Allows the owner to transfer ownership of a Fabricator to another address.
16. `delegateProcessing`: Allows a Fabricator owner to set an address permitted to call `processFabricator` for that specific Fabricator.
17. `revokeProcessingDelegate`: Removes the processing delegate for a Fabricator.
18. `destroyFabricator`: Allows the owner to destroy a Fabricator (e.g., if it's too expensive to maintain).
19. `setFabricatorName`: Allows the owner to set a custom string name for their Fabricator.

**Query & View Functions (12 functions):**
20. `getFabricatorDetails`: Retrieves all relevant data for a given Fabricator ID.
21. `getFabricatorOwner`: Returns the owner of a specific Fabricator.
22. `getFabricatorStatus`: Returns the current status of a Fabricator.
23. `getFabricatorProcessingDelegate`: Returns the address delegated to process a Fabricator.
24. `getUserFabricators`: Returns an array of Fabricator IDs owned by a specific address.
25. `getTotalFabricatorCount`: Returns the total number of Fabricators ever minted.
26. `calculateProcessingOutput`: Pure function to estimate yield and resource consumption for a given time duration and Fabricator state *without* changing state.
27. `calculateTimeToNextEvent`: Returns the time remaining until an upgrade/repair finishes.
28. `calculateRequiredResourcesForTime`: Pure function to estimate total resources needed for a Fabricator over a given future time duration.
29. `calculateEstimatedYieldForTime`: Pure function to estimate total yield produced by a Fabricator over a given future time duration.
30. `calculateUpgradeCost`: Pure function to calculate the resource cost for upgrading a Fabricator to the next level.
31. `calculateRepairCost`: Pure function to calculate the resource cost to repair a Fabricator to full integrity.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./IERC20.sol"; // Assuming a standard IERC20 interface is available

/// @title DigitalFabricatorForge
/// @author YourNameOrAlias
/// @notice A smart contract for managing dynamic digital assets called Fabricators.
/// Fabricators consume ResourceTokens to produce YieldTokens, degrade over time,
/// require repairs, and can be upgraded.
/// @dev This contract assumes external standard ERC-20 contracts for ResourceToken and YieldToken.
/// It requires owners to approve ResourceToken transfers to this contract for minting, processing,
/// upgrading, and repairing. The contract must have the ability to mint or transfer YieldTokens.
/// (For simplicity, this example assumes the contract can 'mint' YieldTokens, representing production).

// --- Outline and Function Summary ---
// Admin & Setup (7 functions):
// 1.  constructor: Initializes contract owner and token addresses.
// 2.  setResourceTokenAddress: Sets the address for the Resource ERC-20 token.
// 3.  setYieldTokenAddress: Sets the address for the Yield ERC-20 token.
// 4.  setFabricatorMintCost: Sets the cost in ResourceToken to mint a new Fabricator.
// 5.  setBaseProcessingRates: Sets initial rates for level 1 Fabricators.
// 6.  setDegradationParameters: Sets parameters for integrity, repair, and broken chance.
// 7.  setUpgradeParameters: Sets parameters for upgrade costs and time.
//
// Fabricator Lifecycle & Interaction (12 functions):
// 8.  mintFabricator: Mints a new Fabricator.
// 9.  processFabricator: Core function: consumes resources, produces yield, updates state.
// 10. batchProcessFabricators: Calls processFabricator for multiple IDs.
// 11. upgradeFabricator: Starts timed upgrade process.
// 12. finishUpgrade: Completes upgrade after time.
// 13. repairFabricator: Starts timed repair process.
// 14. finishRepair: Completes repair after time.
// 15. transferFabricator: Transfers Fabricator ownership.
// 16. delegateProcessing: Sets processing delegate.
// 17. revokeProcessingDelegate: Removes processing delegate.
// 18. destroyFabricator: Removes a Fabricator.
// 19. setFabricatorName: Sets a custom name.
//
// Query & View Functions (12 functions):
// 20. getFabricatorDetails: Retrieves all details for an ID.
// 21. getFabricatorOwner: Returns owner of an ID.
// 22. getFabricatorStatus: Returns status of an ID.
// 23. getFabricatorProcessingDelegate: Returns delegate of an ID.
// 24. getUserFabricators: Returns IDs owned by an address.
// 25. getTotalFabricatorCount: Returns total minted count.
// 26. calculateProcessingOutput: Estimates yield/resources for duration/state.
// 27. calculateTimeToNextEvent: Time remaining for upgrade/repair.
// 28. calculateRequiredResourcesForTime: Estimates resources needed over future time.
// 29. calculateEstimatedYieldForTime: Estimates yield produced over future time.
// 30. calculateUpgradeCost: Calculates upgrade cost.
// 31. calculateRepairCost: Calculates repair cost.

contract DigitalFabricatorForge {

    // --- State Variables ---

    address public owner; // Admin address
    IERC20 public resourceToken; // Address of the Resource ERC-20 contract
    IERC20 public yieldToken; // Address of the Yield ERC-20 contract (assuming contract can mint/transfer)

    uint256 private _nextFabricatorId; // Counter for unique Fabricator IDs
    mapping(uint256 => Fabricator) public fabricators; // Stores Fabricator data by ID
    mapping(address => uint256[]) private _userFabricators; // Stores list of fabricator IDs for each user
    mapping(uint256 => address) public fabricatorProcessingDelegate; // Stores processing delegate by Fabricator ID
    mapping(uint256 => string) public fabricatorNames; // Stores optional names by Fabricator ID

    // Global Parameters (Admin configurable)
    uint256 public fabricatorMintCost; // Cost to mint a new Fabricator in ResourceToken
    uint256 public baseResourceInputRate; // Base ResourceToken consumed per second (level 1)
    uint256 public baseYieldOutputRate; // Base YieldToken produced per second (level 1)

    // Degradation & Maintenance Parameters
    uint256 public integrityDecayRatePerSecond; // How much integrity decreases per second of processing
    uint256 public repairCostMultiplier; // Multiplier for repair cost calculation (e.g., cost = (1000 - integrity) * multiplier)
    uint256 public brokenChanceMultiplier; // Multiplier affecting chance of becoming Broken (e.g., chance = (1000 - integrity) * multiplier)

    // Upgrade Parameters
    uint256 public upgradeCostMultiplier; // Multiplier for upgrade cost calculation (e.g., cost = level * multiplier)
    uint256 public baseUpgradeTime; // Base time required for upgrades in seconds
    uint256 public upgradeTimeMultiplier; // Multiplier for upgrade time calculation (e.g., time = base + level * multiplier)

    // Constants (represent max values)
    uint256 public constant MAX_INTEGRITY = 1000;
    uint256 public constant MAX_EFFICIENCY = 1000;
    uint256 public constant MAX_STABILITY = 1000; // Affects resistance to becoming broken

    // --- Structs and Enums ---

    enum FabricatorStatus {
        Idle,        // Ready for processing or other actions
        Processing,  // Currently processing (used internally, state changes after)
        Upgrading,   // Undergoing upgrade, requires time
        Repairing,   // Undergoing repair, requires time
        Broken       // Cannot process, requires repair
    }

    struct Fabricator {
        address owner;
        uint256 creationTime;
        uint256 lastProcessedTime; // Timestamp of the last processing
        uint256 level;         // Affects base efficiency and stability
        uint256 efficiency;    // Affects resource input and yield output (0-1000)
        uint256 stability;     // Affects chance of becoming broken (0-1000)
        uint256 integrity;     // Health of the fabricator (0-1000). Affects actual yield/resource cost.
        FabricatorStatus status;
        uint256 nextStatusChangeTime; // Timestamp when Upgrade/Repair finishes
    }

    // --- Events ---

    event FabricatorMinted(uint256 indexed fabricatorId, address indexed owner, uint256 timestamp);
    event FabricatorProcessed(uint256 indexed fabricatorId, address indexed owner, uint256 resourcesConsumed, uint256 yieldProduced, uint256 newIntegrity, FabricatorStatus newStatus, uint256 timestamp);
    event FabricatorStatusChanged(uint256 indexed fabricatorId, FabricatorStatus oldStatus, FabricatorStatus newStatus, uint256 timestamp);
    event FabricatorUpgraded(uint256 indexed fabricatorId, address indexed owner, uint256 newLevel, uint256 newEfficiency, uint256 newStability, uint256 timestamp);
    event FabricatorRepairStarted(uint256 indexed fabricatorId, address indexed owner, uint256 cost, uint256 repairFinishTime, uint256 timestamp);
    event FabricatorRepairCompleted(uint256 indexed fabricatorId, uint256 timestamp);
    event FabricatorTransfered(uint256 indexed fabricatorId, address indexed from, address indexed to, uint256 timestamp);
    event FabricatorProcessingDelegateSet(uint256 indexed fabricatorId, address indexed delegator, address indexed delegate, uint256 timestamp);
    event FabricatorProcessingDelegateRevoked(uint256 indexed fabricatorId, address indexed delegator, address indexed delegate, uint256 timestamp);
    event FabricatorDestroyed(uint256 indexed fabricatorId, address indexed owner, uint256 timestamp);
    event FabricatorNameSet(uint256 indexed fabricatorId, address indexed owner, string name, uint256 timestamp);

    // --- Modifiers ---

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can call this function");
        _;
    }

    modifier fabricatorExists(uint256 _fabricatorId) {
        require(fabricators[_fabricatorId].creationTime > 0, "Fabricator does not exist");
        _;
    }

    modifier isFabricatorOwner(uint256 _fabricatorId) {
        require(fabricators[_fabricatorId].owner == msg.sender, "Not the fabricator owner");
        _;
    }

     modifier canProcessFabricator(uint256 _fabricatorId) {
        address currentOwner = fabricators[_fabricatorId].owner;
        address delegate = fabricatorProcessingDelegate[_fabricatorId];
        require(msg.sender == currentOwner || msg.sender == delegate, "Not authorized to process this fabricator");
        _;
    }

    modifier notInhibitedStatus(uint256 _fabricatorId) {
         FabricatorStatus status = fabricators[_fabricatorId].status;
         require(status != FabricatorStatus.Upgrading && status != FabricatorStatus.Repairing && status != FabricatorStatus.Broken, "Fabricator is not in an operable status");
        _;
    }

    // --- Constructor ---

    constructor(address _resourceToken, address _yieldToken) {
        owner = msg.sender;
        resourceToken = IERC20(_resourceToken);
        yieldToken = IERC20(_yieldToken);
        _nextFabricatorId = 1;

        // Set some initial default parameters
        fabricatorMintCost = 100e18; // Example: 100 ResourceTokens
        baseResourceInputRate = 1e16; // Example: 0.01 ResourceTokens per second
        baseYieldOutputRate = 2e16;   // Example: 0.02 YieldTokens per second

        integrityDecayRatePerSecond = 1; // Example: 1 integrity point per second of processing
        repairCostMultiplier = 1e15; // Example: 0.001 ResourceTokens per integrity point missing
        brokenChanceMultiplier = 5; // Example: Affects chance (simplified calculation)

        upgradeCostMultiplier = 5e17; // Example: 0.5 ResourceTokens per level
        baseUpgradeTime = 1 days; // Example: 1 day base upgrade time
        upgradeTimeMultiplier = 1 hours; // Example: Additional hour per level for upgrade time
    }

    // --- Admin Functions ---

    /// @notice Sets the address for the Resource ERC-20 token.
    /// @param _resourceToken The address of the ResourceToken contract.
    function setResourceTokenAddress(address _resourceToken) external onlyOwner {
        require(_resourceToken != address(0), "Invalid address");
        resourceToken = IERC20(_resourceToken);
    }

    /// @notice Sets the address for the Yield ERC-20 token.
    /// @param _yieldToken The address of the YieldToken contract.
    function setYieldTokenAddress(address _yieldToken) external onlyOwner {
        require(_yieldToken != address(0), "Invalid address");
        yieldToken = IERC20(_yieldToken);
    }

    /// @notice Sets the cost in ResourceToken to mint a new Fabricator.
    /// @param _cost The new mint cost.
    function setFabricatorMintCost(uint256 _cost) external onlyOwner {
        fabricatorMintCost = _cost;
    }

    /// @notice Sets the base resource input and yield output rates for Level 1 Fabricators.
    /// @param _resourceRate Base ResourceToken consumed per second.
    /// @param _yieldRate Base YieldToken produced per second.
    function setBaseProcessingRates(uint256 _resourceRate, uint256 _yieldRate) external onlyOwner {
        baseResourceInputRate = _resourceRate;
        baseYieldOutputRate = _yieldRate;
    }

    /// @notice Sets parameters related to integrity decay, repair costs, and broken chances.
    /// @param _decayRate Integrity points lost per second of processing.
    /// @param _repairMultiplier Multiplier for repair cost calculation.
    /// @param _brokenMultiplier Multiplier affecting chance of becoming Broken.
    function setDegradationParameters(uint256 _decayRate, uint256 _repairMultiplier, uint256 _brokenMultiplier) external onlyOwner {
        integrityDecayRatePerSecond = _decayRate;
        repairCostMultiplier = _repairMultiplier;
        brokenChanceMultiplier = _brokenMultiplier;
    }

    /// @notice Sets parameters related to upgrade costs and time.
    /// @param _costMultiplier Multiplier for upgrade cost calculation.
    /// @param _baseTime Base time required for upgrades in seconds.
    /// @param _timeMultiplier Multiplier for upgrade time calculation per level.
    function setUpgradeParameters(uint256 _costMultiplier, uint256 _baseTime, uint255 _timeMultiplier) external onlyOwner {
        upgradeCostMultiplier = _costMultiplier;
        baseUpgradeTime = _baseTime;
        upgradeTimeMultiplier = _timeMultiplier;
    }

    // --- Fabricator Lifecycle & Interaction ---

    /// @notice Mints a new Fabricator for the caller, costing ResourceTokens.
    function mintFabricator() external {
        require(resourceToken.transferFrom(msg.sender, address(this), fabricatorMintCost), "Resource transfer failed for minting");

        uint256 newId = _nextFabricatorId++;
        uint256 currentTime = block.timestamp;

        fabricators[newId] = Fabricator({
            owner: msg.sender,
            creationTime: currentTime,
            lastProcessedTime: currentTime,
            level: 1,
            efficiency: MAX_EFFICIENCY, // Start at max efficiency
            stability: MAX_STABILITY,   // Start at max stability
            integrity: MAX_INTEGRITY,   // Start at max integrity
            status: FabricatorStatus.Idle,
            nextStatusChangeTime: 0
        });

        _userFabricators[msg.sender].push(newId);

        emit FabricatorMinted(newId, msg.sender, currentTime);
    }

    /// @notice Processes a single Fabricator to consume resources and produce yield.
    /// Requires the caller to be the owner or a registered delegate.
    /// @param _fabricatorId The ID of the Fabricator to process.
    function processFabricator(uint256 _fabricatorId)
        external
        fabricatorExists(_fabricatorId)
        canProcessFabricator(_fabricatorId)
        notInhibitedStatus(_fabricatorId)
    {
        Fabricator storage fab = fabricators[_fabricatorId];
        uint256 currentTime = block.timestamp;
        uint256 timeElapsed = currentTime - fab.lastProcessedTime;

        // Cannot process if no time has elapsed
        if (timeElapsed == 0) {
             emit FabricatorProcessed(_fabricatorId, fab.owner, 0, 0, fab.integrity, fab.status, currentTime);
             return; // Nothing to do
        }

        // Calculate resource consumption and yield production
        // Adjusted rates based on level and efficiency. Integrity affects actual output/input.
        uint256 currentResourceRate = (baseResourceInputRate * fab.level * fab.efficiency) / (MAX_EFFICIENCY * MAX_INTEGRITY) * fab.integrity;
        uint256 currentYieldRate = (baseYieldOutputRate * fab.level * fab.efficiency) / (MAX_EFFICIENCY * MAX_INTEGRITY) * fab.integrity;

        uint256 resourcesNeeded = currentResourceRate * timeElapsed;
        uint256 yieldProduced = currentYieldRate * timeElapsed;

        // Consume resources from the owner (requires owner's approval beforehand)
        require(resourceToken.transferFrom(fab.owner, address(this), resourcesNeeded), "Resource transfer failed for processing");

        // Produce yield (mint or transfer from contract balance - assuming mint for simplicity)
        // In a real scenario, yieldToken might have a minting function restricted to this contract.
        // Or this contract might receive yield tokens from another source.
        // Here we simulate transferFrom contract balance (if it had yield) or minting if yieldToken is mintable.
        // Assuming yieldToken.transfer(fab.owner, yieldProduced) is the intended behavior.
        // A real YieldToken contract would need a `mint(address recipient, uint256 amount)` function
        // that only this forge contract can call.
        // For demonstration, let's use transfer from forge balance (needs to be funded or mintable)
         require(yieldToken.transfer(fab.owner, yieldProduced), "Yield transfer failed");


        // Apply integrity decay
        uint256 integrityDecay = integrityDecayRatePerSecond * timeElapsed;
        fab.integrity = fab.integrity > integrityDecay ? fab.integrity - integrityDecay : 0;

        // Check for status change (e.g., become Broken)
        // Simplified probability check: Higher (1000 - integrity) means higher chance
        // A more sophisticated approach would use a Chainlink VRF or similar for randomness.
        // For this example, we'll use a simple timestamp/ID based check for pseudo-randomness.
        // This is NOT cryptographically secure randomness and should not be used for high-value randomness.
        if (fab.integrity < MAX_INTEGRITY / 2) { // Only a chance if integrity is below 50%
            uint256 brokenThreshold = (MAX_INTEGRITY - fab.integrity) * brokenChanceMultiplier; // Higher missing integrity = higher threshold
            uint256 pseudoRandom = uint256(keccak256(abi.encodePacked(currentTime, _fabricatorId, block.difficulty))) % 1000; // Pseudo-random number 0-999

            if (pseudoRandom < brokenThreshold && fab.integrity < 100) { // Higher chance if integrity very low
                 fab.status = FabricatorStatus.Broken;
                 emit FabricatorStatusChanged(_fabricatorId, FabricatorStatus.Idle, FabricatorStatus.Broken, currentTime);
            }
        }


        fab.lastProcessedTime = currentTime;

        emit FabricatorProcessed(_fabricatorId, fab.owner, resourcesNeeded, yieldProduced, fab.integrity, fab.status, currentTime);
    }

     /// @notice Processes multiple Fabricators for the caller or delegate in a single transaction.
     /// Note: This function might hit gas limits for large arrays. Error handling for individual
     /// processing failures in a batch is complex and omitted for simplicity here.
     /// @param _fabricatorIds The IDs of the Fabricators to process.
    function batchProcessFabricators(uint256[] memory _fabricatorIds) external {
        for (uint i = 0; i < _fabricatorIds.length; i++) {
            uint256 fabId = _fabricatorIds[i];
             // Re-check conditions for each fabricator
            require(fabricators[fabId].creationTime > 0, "Fabricator does not exist in batch");
            require(fabricators[fabId].status != FabricatorStatus.Upgrading && fabricators[fabId].status != FabricatorStatus.Repairing && fabricators[fabId].status != FabricatorStatus.Broken, "Fabricator in batch is not operable");

            address currentOwner = fabricators[fabId].owner;
            address delegate = fabricatorProcessingDelegate[fabId];
            require(msg.sender == currentOwner || msg.sender == delegate, "Not authorized for one or more fabricators in batch");

            // Call the internal processing logic
            // Note: This assumes the caller has approved sufficient ResourceToken *for all* fabricators
            // owned by them in the batch *before* calling this function.
            _processFabricatorInternal(fabId);
        }
    }

    /// @dev Internal helper function for processing logic, called by processFabricator and batchProcessFabricators.
    /// Separated to avoid code duplication while allowing external/batch calls.
    /// Assumes checks (existence, status, authorization) are done by the caller functions/modifiers.
    /// @param _fabricatorId The ID of the Fabricator to process.
    function _processFabricatorInternal(uint256 _fabricatorId) internal {
        Fabricator storage fab = fabricators[_fabricatorId];
        uint256 currentTime = block.timestamp;
        uint256 timeElapsed = currentTime - fab.lastProcessedTime;

         // Cannot process if no time has elapsed
        if (timeElapsed == 0) {
             emit FabricatorProcessed(_fabricatorId, fab.owner, 0, 0, fab.integrity, fab.status, currentTime);
             return; // Nothing to do
        }

        // Calculate resource consumption and yield production
        uint256 currentResourceRate = (baseResourceInputRate * fab.level * fab.efficiency) / (MAX_EFFICIENCY * MAX_INTEGRITY) * fab.integrity;
        uint256 currentYieldRate = (baseYieldOutputRate * fab.level * fab.efficiency) / (MAX_EFFICIENCY * MAX_INTEGRITY) * fab.integrity;

        uint256 resourcesNeeded = currentResourceRate * timeElapsed;
        uint256 yieldProduced = currentYieldRate * timeElapsed;

        // Consume resources from the owner (requires owner's approval beforehand)
        // In batch, this will call transferFrom multiple times
        require(resourceToken.transferFrom(fab.owner, address(this), resourcesNeeded), "Resource transfer failed for processing");

        // Produce yield
        require(yieldToken.transfer(fab.owner, yieldProduced), "Yield transfer failed");

        // Apply integrity decay
        uint256 integrityDecay = integrityDecayRatePerSecond * timeElapsed;
        fab.integrity = fab.integrity > integrityDecay ? fab.integrity - integrityDecay : 0;

         // Check for status change (e.g., become Broken) - using pseudo-randomness again
        if (fab.integrity < MAX_INTEGRITY / 2) {
            uint256 brokenThreshold = (MAX_INTEGRITY - fab.integrity) * brokenChanceMultiplier;
            uint256 pseudoRandom = uint256(keccak256(abi.encodePacked(currentTime, _fabricatorId, block.difficulty))) % 1000;

             if (pseudoRandom < brokenThreshold && fab.integrity < 100) {
                 fab.status = FabricatorStatus.Broken;
                 emit FabricatorStatusChanged(_fabricatorId, FabricatorStatus.Idle, FabricatorStatus.Broken, currentTime);
            }
        }

        fab.lastProcessedTime = currentTime;

        emit FabricatorProcessed(_fabricatorId, fab.owner, resourcesNeeded, yieldProduced, fab.integrity, fab.status, currentTime);
    }


    /// @notice Initiates the upgrade process for a Fabricator.
    /// Requires the owner to pay resource cost and changes status to Upgrading for a duration.
    /// @param _fabricatorId The ID of the Fabricator to upgrade.
    function upgradeFabricator(uint256 _fabricatorId)
        external
        isFabricatorOwner(_fabricatorId)
        fabricatorExists(_fabricatorId)
    {
        Fabricator storage fab = fabricators[_fabricatorId];
        require(fab.status == FabricatorStatus.Idle, "Fabricator must be Idle to upgrade");

        uint256 upgradeCost = calculateUpgradeCost(_fabricatorId);
        uint256 upgradeTime = baseUpgradeTime + (fab.level * upgradeTimeMultiplier);

        require(resourceToken.transferFrom(msg.sender, address(this), upgradeCost), "Resource transfer failed for upgrade");

        fab.status = FabricatorStatus.Upgrading;
        fab.nextStatusChangeTime = block.timestamp + upgradeTime;

        emit FabricatorStatusChanged(_fabricatorId, FabricatorStatus.Idle, FabricatorStatus.Upgrading, block.timestamp);
        // Emit a more specific event if needed, maybe showing cost and time
    }

    /// @notice Completes the upgrade process after the required time has elapsed.
    /// Updates the Fabricator's level and stats.
    /// @param _fabricatorId The ID of the Fabricator to finish upgrading.
    function finishUpgrade(uint256 _fabricatorId)
        external
        isFabricatorOwner(_fabricatorId)
        fabricatorExists(_fabricatorId)
    {
        Fabricator storage fab = fabricators[_fabricatorId];
        require(fab.status == FabricatorStatus.Upgrading, "Fabricator is not upgrading");
        require(block.timestamp >= fab.nextStatusChangeTime, "Upgrade not finished yet");

        fab.level++;
        // Recalculate base stats based on new level (example: +10% efficiency/stability per level)
        fab.efficiency = MAX_EFFICIENCY - (MAX_EFFICIENCY * (fab.level - 1)) / 10; // Example: 10% less max eff per level? Or increase? Let's increase
        fab.efficiency = MAX_EFFICIENCY + ((fab.level - 1) * 50); // Example: +5% efficiency per level, cap at MAX_EFFICIENCY logic needed
        fab.stability = MAX_STABILITY + ((fab.level - 1) * 30); // Example: +3% stability per level, cap at MAX_STABILITY logic needed

        // Simple capping
        if (fab.efficiency > MAX_EFFICIENCY) fab.efficiency = MAX_EFFICIENCY;
        if (fab.stability > MAX_STABILITY) fab.stability = MAX_STABILITY;


        fab.status = FabricatorStatus.Idle;
        fab.nextStatusChangeTime = 0;

        emit FabricatorStatusChanged(_fabricatorId, FabricatorStatus.Upgrading, FabricatorStatus.Idle, block.timestamp);
        emit FabricatorUpgraded(_fabricatorId, fab.owner, fab.level, fab.efficiency, fab.stability, block.timestamp);
    }

    /// @notice Initiates the repair process for a Fabricator.
    /// Requires the owner to pay resource cost and changes status to Repairing for a duration.
    /// Can repair from Idle or Broken status.
    /// @param _fabricatorId The ID of the Fabricator to repair.
    function repairFabricator(uint256 _fabricatorId)
        external
        isFabricatorOwner(_fabricatorId)
        fabricatorExists(_fabricatorId)
    {
        Fabricator storage fab = fabricators[_fabricatorId];
        require(fab.status == FabricatorStatus.Idle || fab.status == FabricatorStatus.Broken, "Fabricator must be Idle or Broken to repair");
        require(fab.integrity < MAX_INTEGRITY, "Fabricator already has full integrity");

        uint256 repairCost = calculateRepairCost(_fabricatorId);
        // Simple repair time (e.g., proportional to missing integrity, minimum 1 hour)
        uint256 repairTime = (MAX_INTEGRITY - fab.integrity) * 60 * 60 / MAX_INTEGRITY; // Example: 1 hour per 1000 integrity points missing
        if (repairTime == 0) repairTime = 1 hours; // Minimum repair time

        require(resourceToken.transferFrom(msg.sender, address(this), repairCost), "Resource transfer failed for repair");

        FabricatorStatus oldStatus = fab.status;
        fab.status = FabricatorStatus.Repairing;
        fab.nextStatusChangeTime = block.timestamp + repairTime;

        emit FabricatorRepairStarted(_fabricatorId, fab.owner, repairCost, fab.nextStatusChangeTime, block.timestamp);
        emit FabricatorStatusChanged(_fabricatorId, oldStatus, FabricatorStatus.Repairing, block.timestamp);
    }

    /// @notice Completes the repair process after the required time has elapsed.
    /// Restores the Fabricator's integrity to maximum.
    /// @param _fabricatorId The ID of the Fabricator to finish repairing.
    function finishRepair(uint256 _fabricatorId)
        external
        isFabricatorOwner(_fabricatorId)
        fabricatorExists(_fabricatorId)
    {
        Fabricator storage fab = fabricators[_fabricatorId];
        require(fab.status == FabricatorStatus.Repairing, "Fabricator is not repairing");
        require(block.timestamp >= fab.nextStatusChangeTime, "Repair not finished yet");

        fab.integrity = MAX_INTEGRITY; // Fully restore integrity
        fab.status = FabricatorStatus.Idle;
        fab.nextStatusChangeTime = 0;

        emit FabricatorRepairCompleted(_fabricatorId, block.timestamp);
        emit FabricatorStatusChanged(_fabricatorId, FabricatorStatus.Repairing, FabricatorStatus.Idle, block.timestamp);
    }


    /// @notice Transfers ownership of a Fabricator to another address.
    /// Resets processing delegate upon transfer.
    /// @param _to The address to transfer ownership to.
    /// @param _fabricatorId The ID of the Fabricator to transfer.
    function transferFabricator(address _to, uint256 _fabricatorId)
        external
        isFabricatorOwner(_fabricatorId)
        fabricatorExists(_fabricatorId)
    {
        require(_to != address(0), "Cannot transfer to zero address");
        require(_to != msg.sender, "Cannot transfer to self");

        Fabricator storage fab = fabricators[_fabricatorId];
        address from = fab.owner;

        // Update owner in the struct
        fab.owner = _to;

        // Remove from old owner's list and add to new owner's list (requires array manipulation)
        _removeFabricatorFromUser(from, _fabricatorId);
        _userFabricators[_to].push(_fabricatorId);

        // Reset processing delegate on transfer
        if (fabricatorProcessingDelegate[_fabricatorId] != address(0)) {
             address oldDelegate = fabricatorProcessingDelegate[_fabricatorId];
             fabricatorProcessingDelegate[_fabricatorId] = address(0);
             emit FabricatorProcessingDelegateRevoked(_fabricatorId, from, oldDelegate, block.timestamp);
        }

        emit FabricatorTransfered(_fabricatorId, from, _to, block.timestamp);
    }

    /// @dev Internal helper to remove a fabricator ID from a user's array.
    /// @param _user The user's address.
    /// @param _fabricatorId The Fabricator ID to remove.
    function _removeFabricatorFromUser(address _user, uint256 _fabricatorId) internal {
        uint256[] storage userFabs = _userFabricators[_user];
        for (uint i = 0; i < userFabs.length; i++) {
            if (userFabs[i] == _fabricatorId) {
                // Replace with the last element and pop to remove
                userFabs[i] = userFabs[userFabs.length - 1];
                userFabs.pop();
                break; // Assuming IDs are unique in the array
            }
        }
    }

    /// @notice Sets an address that is authorized to call `processFabricator` for a specific Fabricator.
    /// Only the owner can set a delegate.
    /// @param _fabricatorId The ID of the Fabricator.
    /// @param _delegate The address to set as the delegate. Use address(0) to clear.
    function delegateProcessing(uint256 _fabricatorId, address _delegate)
        external
        isFabricatorOwner(_fabricatorId)
        fabricatorExists(_fabricatorId)
    {
        require(_delegate != fabricators[_fabricatorId].owner, "Cannot delegate to self");
        address oldDelegate = fabricatorProcessingDelegate[_fabricatorId];
        fabricatorProcessingDelegate[_fabricatorId] = _delegate;
        emit FabricatorProcessingDelegateSet(_fabricatorId, msg.sender, _delegate, block.timestamp);
    }

    /// @notice Removes the processing delegate for a Fabricator.
    /// Only the owner can revoke a delegate.
    /// @param _fabricatorId The ID of the Fabricator.
    function revokeProcessingDelegate(uint256 _fabricatorId)
        external
        isFabricatorOwner(_fabricatorId)
        fabricatorExists(_fabricatorId)
    {
         address oldDelegate = fabricatorProcessingDelegate[_fabricatorId];
         require(oldDelegate != address(0), "No delegate is currently set");
         fabricatorProcessingDelegate[_fabricatorId] = address(0);
         emit FabricatorProcessingDelegateRevoked(_fabricatorId, msg.sender, oldDelegate, block.timestamp);
    }

    /// @notice Destroys a Fabricator, removing it from the system.
    /// There is no refund or resource return in this basic implementation.
    /// @param _fabricatorId The ID of the Fabricator to destroy.
    function destroyFabricator(uint256 _fabricatorId)
        external
        isFabricatorOwner(_fabricatorId)
        fabricatorExists(_fabricatorId)
    {
        address ownerToRemove = fabricators[_fabricatorId].owner;

        // Remove from user's list
        _removeFabricatorFromUser(ownerToRemove, _fabricatorId);

        // Delete the fabricator data
        delete fabricators[_fabricatorId];

        // Clear any delegate
        if (fabricatorProcessingDelegate[_fabricatorId] != address(0)) {
             fabricatorProcessingDelegate[_fabricatorId] = address(0);
        }
        delete fabricatorNames[_fabricatorId];


        emit FabricatorDestroyed(_fabricatorId, ownerToRemove, block.timestamp);
    }

    /// @notice Allows the owner to set a custom string name for their Fabricator.
    /// @param _fabricatorId The ID of the Fabricator.
    /// @param _name The desired name (can be empty to clear).
    function setFabricatorName(uint256 _fabricatorId, string calldata _name)
        external
        isFabricatorOwner(_fabricatorId)
        fabricatorExists(_fabricatorId)
    {
        fabricatorNames[_fabricatorId] = _name;
        emit FabricatorNameSet(_fabricatorId, msg.sender, _name, block.timestamp);
    }


    // --- Query & View Functions ---

    /// @notice Retrieves all relevant details for a given Fabricator ID.
    /// @param _fabricatorId The ID of the Fabricator.
    /// @return Fabricator struct data.
    function getFabricatorDetails(uint256 _fabricatorId)
        external
        view
        fabricatorExists(_fabricatorId)
        returns (Fabricator memory)
    {
        return fabricators[_fabricatorId];
    }

    /// @notice Returns the owner of a specific Fabricator.
    /// @param _fabricatorId The ID of the Fabricator.
    /// @return The owner's address.
    function getFabricatorOwner(uint256 _fabricatorId)
        external
        view
        fabricatorExists(_fabricatorId)
        returns (address)
    {
        return fabricators[_fabricatorId].owner;
    }

    /// @notice Returns the current status of a Fabricator.
    /// @param _fabricatorId The ID of the Fabricator.
    /// @return The FabricatorStatus enum value.
    function getFabricatorStatus(uint256 _fabricatorId)
        external
        view
        fabricatorExists(_fabricatorId)
        returns (FabricatorStatus)
    {
        return fabricators[_fabricatorId].status;
    }

    /// @notice Returns the address delegated to process a Fabricator.
    /// @param _fabricatorId The ID of the Fabricator.
    /// @return The delegate address, or address(0) if none is set.
    function getFabricatorProcessingDelegate(uint256 _fabricatorId)
        external
        view
        fabricatorExists(_fabricatorId)
        returns (address)
    {
        return fabricatorProcessingDelegate[_fabricatorId];
    }

    /// @notice Returns an array of Fabricator IDs owned by a specific address.
    /// @param _user The address to query.
    /// @return An array of Fabricator IDs.
    function getUserFabricators(address _user) external view returns (uint256[] memory) {
        return _userFabricators[_user];
    }

    /// @notice Returns the total number of Fabricators ever minted.
    /// @return The total count.
    function getTotalFabricatorCount() external view returns (uint256) {
        return _nextFabricatorId - 1;
    }


    /// @notice Calculates the potential resource consumption and yield production for a Fabricator over a given duration.
    /// This is a pure function and does not change state. Useful for UI/simulations.
    /// Does NOT account for potential status changes (like becoming Broken) or integrity decay *during* the duration.
    /// Assumes integrity remains constant for the duration.
    /// @param _fabricatorId The ID of the Fabricator.
    /// @param _duration Seconds into the future to calculate for.
    /// @return resourcesNeeded Estimated resources needed.
    /// @return yieldProduced Estimated yield produced.
    function calculateProcessingOutput(uint256 _fabricatorId, uint256 _duration)
        external
        view
        fabricatorExists(_fabricatorId)
        returns (uint256 resourcesNeeded, uint256 yieldProduced)
    {
         Fabricator memory fab = fabricators[_fabricatorId];

         // Adjusted rates based on level and efficiency. Integrity affects actual output/input.
        uint256 currentResourceRate = (baseResourceInputRate * fab.level * fab.efficiency) / (MAX_EFFICIENCY * MAX_INTEGRITY) * fab.integrity;
        uint256 currentYieldRate = (baseYieldOutputRate * fab.level * fab.efficiency) / (MAX_EFFICIENCY * MAX_INTEGRITY) * fab.integrity;

        resourcesNeeded = currentResourceRate * _duration;
        yieldProduced = currentYieldRate * _duration;

        return (resourcesNeeded, yieldProduced);
    }


    /// @notice Calculates the time remaining until an Upgrade or Repair finishes.
    /// Returns 0 if the Fabricator is not currently Upgrading or Repairing.
    /// @param _fabricatorId The ID of the Fabricator.
    /// @return timeRemaining Seconds remaining.
    function calculateTimeToNextEvent(uint256 _fabricatorId)
        external
        view
        fabricatorExists(_fabricatorId)
        returns (uint256 timeRemaining)
    {
        Fabricator memory fab = fabricators[_fabricatorId];
        if (fab.status == FabricatorStatus.Upgrading || fab.status == FabricatorStatus.Repairing) {
            if (block.timestamp >= fab.nextStatusChangeTime) {
                return 0; // Time is up or passed
            } else {
                return fab.nextStatusChangeTime - block.timestamp;
            }
        } else {
            return 0; // Not in a timed process
        }
    }

     /// @notice Pure function to calculate the resource cost for upgrading a Fabricator to the next level.
     /// Does not check if the Fabricator exists or can be upgraded.
     /// @param _currentLevel The current level of the Fabricator.
     /// @return The estimated resource cost.
    function calculateUpgradeCost(uint256 _currentLevel) public view returns (uint256) {
        // Example formula: cost increases with level
        return (_currentLevel + 1) * upgradeCostMultiplier;
    }

    /// @notice Pure function to calculate the resource cost to repair a Fabricator to full integrity.
    /// Does not check if the Fabricator exists or needs repair.
    /// @param _currentIntegrity The current integrity of the Fabricator (0-1000).
    /// @return The estimated resource cost.
    function calculateRepairCost(uint256 _currentIntegrity) public view returns (uint256) {
        if (_currentIntegrity >= MAX_INTEGRITY) return 0;
        // Example formula: cost proportional to missing integrity
        return (MAX_INTEGRITY - _currentIntegrity) * repairCostMultiplier;
    }

    /// @notice Estimates total resources needed for a Fabricator over a future duration.
    /// Uses the current state (level, efficiency, integrity) and base rates.
    /// Does NOT account for integrity decay or status changes *during* the duration.
    /// @param _fabricatorId The ID of the Fabricator.
    /// @param _duration Seconds into the future.
    /// @return estimatedResources Total estimated ResourceTokens needed.
     function calculateRequiredResourcesForTime(uint256 _fabricatorId, uint256 _duration)
        external
        view
        fabricatorExists(_fabricatorId)
        returns (uint256 estimatedResources)
    {
         Fabricator memory fab = fabricators[_fabricatorId];
         uint256 currentResourceRate = (baseResourceInputRate * fab.level * fab.efficiency) / (MAX_EFFICIENCY * MAX_INTEGRITY) * fab.integrity;
         return currentResourceRate * _duration;
    }

    /// @notice Estimates total yield produced by a Fabricator over a future duration.
    /// Uses the current state (level, efficiency, integrity) and base rates.
    /// Does NOT account for integrity decay or status changes *during* the duration.
    /// @param _fabricatorId The ID of the Fabricator.
    /// @param _duration Seconds into the future.
    /// @return estimatedYield Total estimated YieldTokens produced.
    function calculateEstimatedYieldForTime(uint256 _fabricatorId, uint256 _duration)
        external
        view
        fabricatorExists(_fabricatorId)
        returns (uint256 estimatedYield)
    {
        Fabricator memory fab = fabricators[_fabricatorId];
        uint256 currentYieldRate = (baseYieldOutputRate * fab.level * fab.efficiency) / (MAX_EFFICIENCY * MAX_INTEGRITY) * fab.integrity;
        return currentYieldRate * _duration;
    }
}

// Dummy IERC20 interface for compilation if not using OpenZeppelin
interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint255 value);
}
```

---

**Explanation of Concepts and Implementation Choices:**

1.  **Dynamic Assets:** The `Fabricator` struct holds mutable state (`level`, `efficiency`, `stability`, `integrity`, `status`, `lastProcessedTime`, `nextStatusChangeTime`). Functions like `processFabricator`, `finishUpgrade`, `finishRepair` directly modify these properties, making the assets dynamic.
2.  **Resource/Yield Economy:** The contract defines `resourceToken` and `yieldToken` addresses (assuming they are external ERC-20s). `mintFabricator`, `processFabricator`, `upgradeFabricator`, and `repairFabricator` require `transferFrom` calls for `resourceToken`, consuming them. `processFabricator` performs a `transfer` (or minting logic, simulated here) of `yieldToken` to the Fabricator owner, representing production.
3.  **Time-Based Mechanics:** `processFabricator` calculates activity based on `block.timestamp - lastProcessedTime`. `upgradeFabricator` and `repairFabricator` set a `nextStatusChangeTime`, and `finishUpgrade`/`finishRepair` check against `block.timestamp` to enforce timed waits.
4.  **Degradation:** `processFabricator` reduces `integrity` based on time. Low integrity impacts the effective processing rates and increases the chance of becoming `Broken`. `repairFabricator` costs resources and time to restore integrity.
5.  **Leveling:** `upgradeFabricator` costs resources and time. `finishUpgrade` increases the `level`, which modifies the base `efficiency` and `stability`, leading to better processing rates.
6.  **Delegation:** The `fabricatorProcessingDelegate` mapping allows an owner to authorize another address to call `processFabricator` on their behalf, useful for automation or third-party services. The `canProcessFabricator` modifier enforces this.
7.  **Parameterized Logic:** Costs and rates (`fabricatorMintCost`, `baseResourceInputRate`, `baseYieldOutputRate`, `integrityDecayRatePerSecond`, `repairCostMultiplier`, `brokenChanceMultiplier`, `upgradeCostMultiplier`, `baseUpgradeTime`, `upgradeTimeMultiplier`) are stored as state variables, allowing the contract owner (or potentially a DAO governance mechanism in a more complex version) to tune the economy and mechanics without deploying a new contract.
8.  **Batching:** `batchProcessFabricators` demonstrates how multiple operations on owned assets can be bundled to save transaction costs for users.
9.  **Pseudo-Randomness:** The chance of becoming `Broken` uses a very simple pseudo-random calculation based on hashing `block.timestamp`, `fabricatorId`, and `block.difficulty`. **Important:** This is *not* secure or unpredictable randomness for critical applications but serves the purpose of demonstrating the concept of a probabilistic event. For production, a service like Chainlink VRF would be necessary.

This contract provides a framework for a more complex, interactive digital asset compared to simple ownership or static metadata. It introduces resource management, maintenance, and evolution mechanics entirely on-chain.