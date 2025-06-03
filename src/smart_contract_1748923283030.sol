Okay, let's design an advanced, creative, and non-standard smart contract. How about a contract that manages "ChronoSpheres" – unique, time-sensitive digital assets that accumulate "Temporal Energy" based on complex time mechanics, user interaction, and dynamically managed "Epochs"?

This contract, let's call it `ChronoSphere`, will incorporate concepts like:
1.  **Time-Weighted State:** Sphere attributes change based on elapsed time and interactions.
2.  **Dynamic Energy Accumulation:** Energy gain rates vary based on Sphere state, Epoch rules, and potentially bonding.
3.  **Evolution State Machine:** Spheres can 'evolve' by consuming Temporal Energy, unlocking new states or abilities.
4.  **Epoch System:** The contract operates in distinct phases ('Epochs'), controlled by the owner, each with different rules for energy accumulation, evolution costs, and rewards.
5.  **Sphere Bonding:** Users can 'bond' two spheres together, affecting their energy dynamics.
6.  **Conditional Actions:** Many functions require specific conditions (enough energy, correct evolution level, active epoch) to be met.
7.  **Internal State Management:** Instead of relying on external tokens for rewards, rewards are tracked internally as state changes on the Sphere.

It will **not** be a standard ERC-721, ERC-20, staking contract, or simple time-lock. While it simulates some NFT-like properties (unique ID, ownership), the core logic is centered around time-based state evolution and energy mechanics.

---

**Smart Contract: ChronoSphere**

**Outline:**

1.  **Contract Information:** SPDX License, Solidity version.
2.  **Owner Management:** Basic ownership pattern.
3.  **Structs:**
    *   `Sphere`: Defines the structure of a ChronoSphere (owner, timestamps, energy, level, state, bonding info, etc.).
    *   `EpochConfig`: Defines parameters for a type of epoch (duration, rates, costs, reward amount).
    *   `EpochInstance`: Tracks an active epoch (config ID, start time, end time).
4.  **State Variables:** Mappings for spheres, epoch configs, epoch instances, counters, current epoch details.
5.  **Events:** To signal key actions (Minting, Transfer, Evolution, Energy Update, Epoch Start/End, Bonding).
6.  **Modifiers:** To enforce access control and state checks.
7.  **Core Logic:**
    *   Time-based energy calculation.
    *   Sphere state transitions (evolution, pausing).
    *   Epoch lifecycle management.
    *   Sphere bonding/unbonding logic.
    *   Reward eligibility and claiming logic.
8.  **Functions (>= 20):**
    *   Owner/Admin functions (epoch creation, starting, ending, parameter setting, emergency functions).
    *   Sphere Management functions (minting, transfer, burn, pausing, resuming).
    *   Sphere Interaction functions (calculate/update energy, evolve, reset, set description, bond, unbond, claim reward).
    *   Query functions (get details, status, epoch info, ownerOf, supply).

---

**Function Summary:**

1.  `constructor()`: Initializes the contract owner.
2.  `mintSphere(address recipient)`: Creates a new ChronoSphere, assigns ownership, and sets initial state. (Owner/privileged).
3.  `transferSphere(uint256 sphereId, address newOwner)`: Transfers ownership of a Sphere. (Current owner).
4.  `burnSphere(uint256 sphereId)`: Destroys a Sphere, removing it from the contract. (Sphere owner, maybe with cost).
5.  `ownerOf(uint256 sphereId)`: Returns the current owner of a Sphere.
6.  `getSphereDetails(uint256 sphereId)`: Returns the full data struct for a Sphere.
7.  `calculatePendingEnergy(uint256 sphereId)`: Calculates the amount of Temporal Energy a Sphere has accumulated since its last update or minting, based on time, state, epoch rules, and bonding.
8.  `updateSphereEnergy(uint256 sphereId)`: Triggers the calculation and addition of pending energy to a Sphere's total, updating the last update timestamp. (Anyone can call, pays gas).
9.  `getTotalEnergy(uint256 sphereId)`: Returns the Sphere's currently banked total energy.
10. `evolveSphere(uint256 sphereId)`: Attempts to evolve the Sphere to the next level. Requires sufficient energy, checks epoch-specific evolution costs, consumes energy on success. (Sphere owner).
11. `getSphereEvolutionLevel(uint256 sphereId)`: Returns the current evolution level of a Sphere.
12. `resetSphereEvolution(uint256 sphereId)`: Resets a Sphere back to its initial evolution level. Potentially consumes a significant amount of energy or has other costs/conditions. (Sphere owner).
13. `createEpochConfig(uint256 duration, uint256 energyRatePerSecond, uint256 evolutionBaseCost, uint256 rewardAmount, string memory description)`: Owner defines a new type of epoch with specific rules. (Owner).
14. `startNewEpoch(uint256 epochConfigId)`: Owner starts a new instance of an epoch based on a predefined config, ending the previous one if active. (Owner).
15. `endCurrentEpoch()`: Owner manually ends the currently active epoch instance. (Owner).
16. `getCurrentEpochDetails()`: Returns details about the currently active epoch instance.
17. `getEpochConfigDetails(uint256 epochConfigId)`: Returns details about a specific epoch configuration.
18. `claimEpochReward(uint256 sphereId)`: Allows a Sphere owner to claim the reward associated with the *last* active epoch instance, if eligible. Marks the sphere as claimed for that epoch. Eligibility might depend on sphere state or activity during the epoch. (Sphere owner).
19. `checkSphereRewardEligibility(uint256 sphereId)`: Checks if a Sphere is currently eligible to claim a reward from the previous epoch.
20. `pauseSphereEnergyAccumulation(uint256 sphereId)`: Pauses the accumulation of Temporal Energy for a Sphere. (Sphere owner).
21. `resumeSphereEnergyAccumulation(uint256 sphereId)`: Resumes the accumulation of Temporal Energy for a Sphere. (Sphere owner).
22. `setSphereDescription(uint256 sphereId, string memory newDescription)`: Allows the Sphere owner to set a custom description (short string). (Sphere owner).
23. `setEpochConfigParameters(uint256 epochConfigId, uint256 duration, uint256 energyRatePerSecond, uint256 evolutionBaseCost, uint256 rewardAmount, string memory description)`: Owner modifies parameters of a *future* epoch configuration. (Owner).
24. `getSphereStatusSummary(uint256 sphereId)`: Returns a concise summary of a Sphere's key states (level, energy, active/paused, bonded status).
25. `getTotalSupply()`: Returns the total number of Spheres minted (and not burned).
26. `bondSpheres(uint256 sphereId1, uint256 sphereId2)`: Bonds two Spheres together. May grant energy bonuses or shared effects. Requires both Sphere owners to consent (or one owner owns both). *Implementation simplified: Owner must own both*. Updates internal state. (Sphere owner of both).
27. `unbondSpheres(uint256 sphereId)`: Unbonds a Sphere from its bonded partner. (Sphere owner).
28. `getBondedSphere(uint256 sphereId)`: Returns the ID of the Sphere bonded to this one, or 0 if not bonded.
29. `setTimeBoost(uint256 sphereId, uint256 duration, uint256 multiplier)`: Owner/privileged function to apply a temporary multiplier to a Sphere's energy accumulation rate. (Owner).
30. `getCurrentTimeBoost(uint256 sphereId)`: Returns the active boost multiplier and end time for a Sphere.
31. `redeemEnergyForAction(uint256 sphereId, uint256 energyCost)`: A generic function placeholder that allows consuming energy for hypothetical future actions. (Sphere owner).

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title ChronoSphere
 * @dev A smart contract managing unique, time-sensitive digital assets ("Spheres")
 *      that accumulate Temporal Energy based on time, state, and dynamic epochs.
 *      Features include time-weighted energy, state evolution, epoch system,
 *      sphere bonding, and conditional actions.
 */
contract ChronoSphere {

    // --- Owner Management ---
    address private immutable _owner;
    modifier onlyOwner() {
        require(msg.sender == _owner, "Not owner");
        _;
    }

    // --- Structs ---

    struct Sphere {
        address owner;
        uint64 mintTimestamp;              // When the sphere was created
        uint64 lastEnergyUpdateTimestamp;  // When energy was last calculated/updated
        uint256 totalEnergy;               // Accumulated temporal energy
        uint8 evolutionLevel;              // Current evolution level (0 to 255)
        bool isPaused;                     // Is energy accumulation paused?
        string description;                // User-set description (limited size)
        uint256 bondedToSphereId;          // The ID of the sphere this one is bonded to (0 if none)
        uint256 lastEpochClaimedId;        // The ID of the last epoch instance reward claimed
        uint64 boostEndTime;               // Timestamp when time boost ends
        uint16 boostMultiplier;            // Multiplier for energy accumulation during boost (e.g., 1000 = 1x, 1500 = 1.5x)
    }

    struct EpochConfig {
        uint64 duration;               // Duration of the epoch instance in seconds
        uint256 energyRatePerSecond;   // Base energy accumulated per second per sphere in this epoch
        uint256 evolutionBaseCost;     // Base energy cost for evolution in this epoch
        uint256 rewardAmount;          // Hypothetical reward amount (or state change) for eligible spheres
        string description;            // Description of this epoch type
    }

    struct EpochInstance {
        uint256 epochConfigId;     // The ID of the config this instance is based on
        uint64 startTime;          // Timestamp when this epoch instance started
        uint64 endTime;            // Timestamp when this epoch instance ends
        bool endedByOwner;         // Was this epoch ended manually by owner?
    }

    // --- State Variables ---

    mapping(uint256 => Sphere) private _spheres;
    uint256 private _sphereCounter; // Starts from 1

    mapping(uint256 => EpochConfig) private _epochConfigs;
    uint256 private _epochConfigCounter; // Starts from 1

    mapping(uint256 => EpochInstance) private _epochInstances;
    uint256 private _epochInstanceCounter; // Starts from 1
    uint256 private _currentEpochInstanceId; // 0 if no active epoch

    // Mapping for ownership lookup (ERC721 style)
    mapping(uint256 => address) private _sphereOwners;
    // Mapping to track number of spheres per owner (cannot efficiently list on-chain arrays)
    mapping(address => uint256) private _ownedSpheresCount;


    // Global energy rate multiplier (e.g., 1000 = 1x, 500 = 0.5x, 2000 = 2x)
    uint16 public globalEnergyRateMultiplier = 1000;

    // --- Events ---

    event SphereMinted(uint256 indexed sphereId, address indexed owner, uint64 timestamp);
    event SphereTransfer(uint256 indexed sphereId, address indexed from, address indexed to);
    event SphereBurned(uint256 indexed sphereId);
    event EnergyUpdated(uint256 indexed sphereId, uint256 addedEnergy, uint256 newTotalEnergy, uint64 timestamp);
    event SphereEvolved(uint256 indexed sphereId, uint8 newLevel, uint256 energyCost);
    event SphereEvolutionReset(uint256 indexed sphereId, uint256 energyCost);
    event EpochConfigCreated(uint256 indexed configId, uint64 duration, uint256 rate);
    event EpochStarted(uint256 indexed instanceId, uint256 indexed configId, uint64 startTime, uint64 endTime);
    event EpochEnded(uint256 indexed instanceId, uint64 endTime, bool endedByOwner);
    event RewardClaimed(uint256 indexed sphereId, uint256 indexed epochInstanceId, uint256 rewardAmount);
    event SpherePaused(uint256 indexed sphereId, uint64 timestamp);
    event SphereResumed(uint256 indexed sphereId, uint64 timestamp);
    event SphereDescriptionUpdated(uint256 indexed sphereId, string newDescription);
    event SpheresBonded(uint256 indexed sphereId1, uint256 indexed sphereId2);
    event SpheresUnbonded(uint256 indexed sphereId1, uint256 indexed sphereId2);
    event TimeBoostApplied(uint256 indexed sphereId, uint64 endTime, uint16 multiplier);
    event EnergyRedeemed(uint256 indexed sphereId, uint256 energyCost, uint256 newTotalEnergy);

    // --- Modifiers ---

    modifier sphereExists(uint256 sphereId) {
        require(_sphereOwners[sphereId] != address(0), "Sphere does not exist");
        _;
    }

    modifier isSphereOwner(uint256 sphereId) {
        require(_sphereOwners[sphereId] == msg.sender, "Not sphere owner");
        _;
    }

    modifier isActiveEpoch() {
        require(_currentEpochInstanceId != 0, "No active epoch");
        require(block.timestamp >= _epochInstances[_currentEpochInstanceId].startTime && block.timestamp < _epochInstances[_currentEpochInstanceId].endTime, "Current epoch not active");
        _;
    }

    // --- Constructor ---

    constructor() {
        _owner = msg.sender;
    }

    // --- Owner/Admin Functions ---

    /**
     * @dev Creates a new type of epoch configuration.
     * @param duration Duration of the epoch instance in seconds.
     * @param energyRatePerSecond Base energy per second for spheres in this epoch.
     * @param evolutionBaseCost Base energy cost multiplier for evolution in this epoch.
     * @param rewardAmount Hypothetical reward amount.
     * @param description Description of the epoch config.
     */
    function createEpochConfig(
        uint64 duration,
        uint256 energyRatePerSecond,
        uint256 evolutionBaseCost,
        uint256 rewardAmount,
        string memory description
    ) external onlyOwner returns (uint256 configId) {
        _epochConfigCounter++;
        configId = _epochConfigCounter;
        _epochConfigs[configId] = EpochConfig(
            duration,
            energyRatePerSecond,
            evolutionBaseCost,
            rewardAmount,
            description
        );
        emit EpochConfigCreated(configId, duration, energyRatePerSecond);
        return configId;
    }

    /**
     * @dev Starts a new epoch instance based on a predefined configuration.
     *      Ends the current epoch if one is active.
     * @param epochConfigId The ID of the epoch configuration to use.
     */
    function startNewEpoch(uint256 epochConfigId) external onlyOwner {
        require(_epochConfigs[epochConfigId].duration > 0, "Invalid epoch config ID");

        if (_currentEpochInstanceId != 0) {
            endCurrentEpoch(); // Automatically end the previous epoch
        }

        _epochInstanceCounter++;
        _currentEpochInstanceId = _epochInstanceCounter;

        EpochConfig storage config = _epochConfigs[epochConfigId];
        uint64 startTime = uint64(block.timestamp);
        uint64 endTime = startTime + config.duration;

        _epochInstances[_currentEpochInstanceId] = EpochInstance(
            epochConfigId,
            startTime,
            endTime,
            false // Not ended by owner initially
        );

        emit EpochStarted(_currentEpochInstanceId, epochConfigId, startTime, endTime);
    }

    /**
     * @dev Ends the currently active epoch instance manually.
     */
    function endCurrentEpoch() public onlyOwner {
        require(_currentEpochInstanceId != 0, "No active epoch to end");
        EpochInstance storage currentInstance = _epochInstances[_currentEpochInstanceId];
        require(block.timestamp < currentInstance.endTime, "Epoch already ended naturally");

        currentInstance.endTime = uint64(block.timestamp);
        currentInstance.endedByOwner = true;

        emit EpochEnded(_currentEpochInstanceId, currentInstance.endTime, true);

        // Keep _currentEpochInstanceId as the last active one for reward claims etc.
        // Set it to 0 if you want no current epoch state after ending, but keeping it
        // allows querying the details of the just-ended epoch via getCurrentEpochDetails.
        // Let's keep it for now, it will be overwritten by startNewEpoch.
    }

    /**
     * @dev Sets parameters for a future epoch configuration. Cannot modify active config.
     * @param epochConfigId The ID of the epoch configuration to modify.
     * @param duration New duration.
     * @param energyRatePerSecond New energy rate.
     * @param evolutionBaseCost New evolution cost.
     * @param rewardAmount New reward amount.
     * @param description New description.
     */
    function setEpochConfigParameters(
        uint256 epochConfigId,
        uint64 duration,
        uint256 energyRatePerSecond,
        uint256 evolutionBaseCost,
        uint256 rewardAmount,
        string memory description
    ) external onlyOwner {
        require(_epochConfigs[epochConfigId].duration > 0, "Invalid epoch config ID");
        // Optional: Add check that this config is not the one used for the *currently* active epoch instance if _currentEpochInstanceId != 0
        // require(_currentEpochInstanceId == 0 || _epochInstances[_currentEpochInstanceId].epochConfigId != epochConfigId, "Cannot modify active epoch config");

        _epochConfigs[epochConfigId] = EpochConfig(
            duration,
            energyRatePerSecond,
            evolutionBaseCost,
            rewardAmount,
            description
        );
        // Consider adding a specific event for config updates if needed
    }

    /**
     * @dev Allows the owner to apply a temporary boost to a sphere's energy accumulation rate.
     * @param sphereId The ID of the sphere to boost.
     * @param duration Duration of the boost in seconds.
     * @param multiplier The energy rate multiplier (e.g., 1500 for 1.5x).
     */
    function setTimeBoost(uint256 sphereId, uint64 duration, uint16 multiplier) external onlyOwner sphereExists(sphereId) {
         // Update energy before applying boost to capture accumulation before the change
        _updateSphereEnergyInternal(sphereId);

        Sphere storage sphere = _spheres[sphereId];
        sphere.boostEndTime = uint64(block.timestamp) + duration;
        sphere.boostMultiplier = multiplier;

        emit TimeBoostApplied(sphereId, sphere.boostEndTime, multiplier);
    }

    // --- Sphere Management Functions ---

    /**
     * @dev Creates a new ChronoSphere and assigns it to a recipient.
     * @param recipient The address to mint the sphere to.
     */
    function mintSphere(address recipient) external onlyOwner returns (uint256 sphereId) {
        require(recipient != address(0), "Mint to non-zero address");

        _sphereCounter++;
        sphereId = _sphereCounter;
        uint64 currentTimestamp = uint64(block.timestamp);

        _spheres[sphereId] = Sphere({
            owner: recipient,
            mintTimestamp: currentTimestamp,
            lastEnergyUpdateTimestamp: currentTimestamp,
            totalEnergy: 0,
            evolutionLevel: 0,
            isPaused: false,
            description: "",
            bondedToSphereId: 0,
            lastEpochClaimedId: 0,
            boostEndTime: 0,
            boostMultiplier: 1000 // Default 1x multiplier
        });

        _sphereOwners[sphereId] = recipient;
        _ownedSpheresCount[recipient]++;

        emit SphereMinted(sphereId, recipient, currentTimestamp);
        return sphereId;
    }

    /**
     * @dev Transfers ownership of a sphere. Basic transfer, does not handle ERC721 approvals.
     * @param sphereId The ID of the sphere to transfer.
     * @param newOwner The address to transfer the sphere to.
     */
    function transferSphere(uint256 sphereId, address newOwner) external isSphereOwner(sphereId) sphereExists(sphereId) {
        require(newOwner != address(0), "Transfer to non-zero address");
        require(_spheres[sphereId].bondedToSphereId == 0, "Cannot transfer bonded sphere"); // Prevent transferring bonded spheres without handling the bond

        address oldOwner = msg.sender;
        Sphere storage sphere = _spheres[sphereId];

        // Update energy before transfer
        _updateSphereEnergyInternal(sphereId);

        // Clear description on transfer? Or keep? Let's keep it.
        // sphere.description = ""; // Optional: reset description on transfer

        _sphereOwners[sphereId] = newOwner;
        _ownedSpheresCount[oldOwner]--;
        _ownedSpheresCount[newOwner]++;
        sphere.owner = newOwner; // Update owner in the struct as well

        emit SphereTransfer(sphereId, oldOwner, newOwner);
    }

    /**
     * @dev Destroys a sphere.
     * @param sphereId The ID of the sphere to burn.
     */
    function burnSphere(uint256 sphereId) external isSphereOwner(sphereId) sphereExists(sphereId) {
         require(_spheres[sphereId].bondedToSphereId == 0, "Cannot burn bonded sphere"); // Prevent burning bonded spheres

        address owner = msg.sender;
        // No energy calculation needed as the sphere is destroyed

        // If bonded to another sphere, unbond it first
        if (_spheres[sphereId].bondedToSphereId != 0) {
            unbondSpheres(sphereId); // This should also update the other sphere
        }

        delete _spheres[sphereId]; // Removes the struct data
        delete _sphereOwners[sphereId]; // Removes owner mapping
        _ownedSpheresCount[owner]--;

        emit SphereBurned(sphereId);
    }

    // --- Sphere Interaction Functions ---

    /**
     * @dev Calculates the pending Temporal Energy for a sphere based on elapsed time.
     *      Takes into account pause status, time boosts, and the current epoch's rate.
     * @param sphereId The ID of the sphere.
     * @return The amount of energy accumulated since last update.
     */
    function calculatePendingEnergy(uint256 sphereId) public view sphereExists(sphereId) returns (uint256) {
        Sphere storage sphere = _spheres[sphereId];

        if (sphere.isPaused || _currentEpochInstanceId == 0) {
            return 0; // No energy accumulation when paused or no active epoch
        }

        EpochInstance storage currentInstance = _epochInstances[_currentEpochInstanceId];
        if (block.timestamp < currentInstance.startTime || block.timestamp >= currentInstance.endTime) {
             return 0; // Current block is outside the active epoch window
        }

        EpochConfig storage currentConfig = _epochConfigs[currentInstance.epochConfigId];
        uint64 lastUpdate = sphere.lastEnergyUpdateTimestamp;
        uint64 currentTime = uint64(block.timestamp);

        // Limit calculation duration to the current epoch instance boundary
        if (currentTime >= currentInstance.endTime) {
             currentTime = currentInstance.endTime;
        }
         if (lastUpdate < currentInstance.startTime) {
             lastUpdate = currentInstance.startTime; // Only accumulate since epoch started
         }


        uint64 duration = 0;
        if (currentTime > lastUpdate) {
            duration = currentTime - lastUpdate;
        }

        if (duration == 0) {
            return 0;
        }

        // Base energy per second from epoch config
        uint256 baseRate = currentConfig.energyRatePerSecond;

        // Apply global multiplier
        uint256 effectiveRate = (baseRate * globalEnergyRateMultiplier) / 1000;

        // Apply time boost if active
        if (currentTime < sphere.boostEndTime) {
             // Calculate time within boost duration and outside
             uint64 boostDuration = sphere.boostEndTime - lastUpdate; // Duration from last update to boost end
             uint64 effectiveBoostDuration = duration; // Assume full duration is boosted initially
             if (currentTime < sphere.boostEndTime) {
                // Boost ends after current time, apply multiplier to full duration
                // effectiveBoostDuration = duration; // Already set
             } else {
                 // Boost ends before or at current time, only part of duration is boosted
                 effectiveBoostDuration = sphere.boostEndTime - lastUpdate;
             }
              if (effectiveBoostDuration > duration) effectiveBoostDuration = duration; // Should not happen with logic above, but safety

             uint64 normalDuration = duration - effectiveBoostDuration;

             uint256 boostedEnergy = (effectiveRate * sphere.boostMultiplier) / 1000;
             uint256 energy = (boostedEnergy * effectiveBoostDuration) + (effectiveRate * normalDuration);

             return energy;

        } else {
             // No active boost or boost ended before last update
             return effectiveRate * duration;
        }
    }

    /**
     * @dev Internal function to update sphere energy. Callable by other contract functions.
     * @param sphereId The ID of the sphere.
     */
    function _updateSphereEnergyInternal(uint256 sphereId) internal sphereExists(sphereId) {
        Sphere storage sphere = _spheres[sphereId];
        uint256 pendingEnergy = calculatePendingEnergy(sphereId);

        if (pendingEnergy > 0) {
            sphere.totalEnergy += pendingEnergy;
            sphere.lastEnergyUpdateTimestamp = uint64(block.timestamp);
            emit EnergyUpdated(sphereId, pendingEnergy, sphere.totalEnergy, uint64(block.timestamp));
        } else {
            // Even if no energy gained (paused, outside epoch, etc.), update timestamp if not paused and time passed.
            // This prevents calculating huge energy chunk if paused for a long time then unpaused,
            // but only if the state allows accumulation.
            if (!sphere.isPaused) {
                 uint64 currentTime = uint64(block.timestamp);
                 uint64 lastUpdate = sphere.lastEnergyUpdateTimestamp;
                 if (currentTime > lastUpdate) {
                    // Only update timestamp if time has actually passed since last recorded update
                    // and the sphere is not paused.
                    sphere.lastEnergyUpdateTimestamp = currentTime;
                 }
            }
        }
    }


    /**
     * @dev Triggers the calculation and addition of pending energy for a sphere.
     *      Can be called by anyone to help users update their sphere state.
     * @param sphereId The ID of the sphere.
     */
    function updateSphereEnergy(uint256 sphereId) external sphereExists(sphereId) {
        _updateSphereEnergyInternal(sphereId);
    }


    /**
     * @dev Attempts to evolve the sphere to the next level.
     *      Requires sufficient energy and consumes the cost.
     *      Cost scales with current level and epoch base cost.
     * @param sphereId The ID of the sphere.
     */
    function evolveSphere(uint256 sphereId) external isSphereOwner(sphereId) sphereExists(sphereId) isActiveEpoch {
        Sphere storage sphere = _spheres[sphereId];
        require(sphere.evolutionLevel < 255, "Sphere at max evolution level");

        _updateSphereEnergyInternal(sphereId); // Update energy before checking cost

        EpochInstance storage currentInstance = _epochInstances[_currentEpochInstanceId];
        EpochConfig storage currentConfig = _epochConfigs[currentInstance.epochConfigId];

        // Simple example cost calculation: Base cost from epoch * (current level + 1) * some factor
        uint256 evolutionCost = currentConfig.evolutionBaseCost * (sphere.evolutionLevel + 1);
        // Add complexity: Maybe bonded spheres reduce cost? Or require bonded partner to also have energy?
        // For now, just simple scaling.

        require(sphere.totalEnergy >= evolutionCost, "Not enough energy to evolve");

        sphere.totalEnergy -= evolutionCost;
        sphere.evolutionLevel++;

        emit SphereEvolved(sphereId, sphere.evolutionLevel, evolutionCost);
    }

    /**
     * @dev Resets a sphere's evolution level back to 0.
     *      This is a costly operation.
     * @param sphereId The ID of the sphere.
     */
    function resetSphereEvolution(uint256 sphereId) external isSphereOwner(sphereId) sphereExists(sphereId) {
        Sphere storage sphere = _spheres[sphereId];
        require(sphere.evolutionLevel > 0, "Sphere is already at minimum level");

        _updateSphereEnergyInternal(sphereId); // Update energy before applying cost

        // Define a significant fixed cost for resetting evolution
        uint256 resetCost = 1000 * 10**18; // Example large number (adjust units as needed)
                                          // Maybe based on current level? resetCost = sphere.evolutionLevel * factor;

        require(sphere.totalEnergy >= resetCost, "Not enough energy to reset evolution");

        sphere.totalEnergy -= resetCost;
        uint8 oldLevel = sphere.evolutionLevel;
        sphere.evolutionLevel = 0;

        emit SphereEvolutionReset(sphereId, resetCost);
        // Consider adding an event for the level change itself
    }

    /**
     * @dev Allows claiming the reward for the last ended epoch instance if eligible.
     *      Eligibility is based on the sphere not having claimed this epoch's reward before.
     *      More complex eligibility (e.g., minimum level, activity during epoch) could be added.
     * @param sphereId The ID of the sphere.
     */
    function claimEpochReward(uint256 sphereId) external isSphereOwner(sphereId) sphereExists(sphereId) {
        require(_currentEpochInstanceId != 0 || _epochInstanceCounter > 0, "No epoch instances recorded");

        // Check the *last* recorded epoch instance ID
        uint256 lastEpochInstanceId = _epochInstanceCounter;
        require(_spheres[sphereId].lastEpochClaimedId < lastEpochInstanceId, "Reward already claimed for this epoch instance");

        EpochInstance storage lastInstance = _epochInstances[lastEpochInstanceId];
        // Check if the last instance has actually ended
        require(block.timestamp >= lastInstance.endTime, "Current epoch must end before claiming reward");

        EpochConfig storage config = _epochConfigs[lastInstance.epochConfigId];

        // --- Add Complex Eligibility Logic Here ---
        // Example: Sphere must have been active (not paused) throughout the epoch duration.
        // Example: Sphere must have reached a minimum evolution level by epoch end.
        // For simplicity, let's just require the sphere was minted before the epoch ended.
        require(_spheres[sphereId].mintTimestamp < lastInstance.endTime, "Sphere not active during epoch");
        // --- End Eligibility Logic ---


        // Mark sphere as having claimed the reward for this epoch instance
        _spheres[sphereId].lastEpochClaimedId = lastEpochInstanceId;

        // This contract doesn't issue tokens, so the "reward" is a state change.
        // In a real dApp, this might trigger distribution of an ERC20 reward token,
        // unlock features, or increase an internal "reward balance".
        // Here, we emit the event signifying the reward is 'claimed' internally.

        emit RewardClaimed(sphereId, lastEpochInstanceId, config.rewardAmount);
    }

     /**
     * @dev Checks if a Sphere is eligible to claim the reward for the last ended epoch instance.
     *      Does not modify state.
     * @param sphereId The ID of the sphere.
     * @return bool True if eligible, false otherwise.
     */
    function checkSphereRewardEligibility(uint256 sphereId) external view sphereExists(sphereId) returns (bool) {
        if (_epochInstanceCounter == 0) return false; // No epochs ever

        uint256 lastEpochInstanceId = _epochInstanceCounter;
        Sphere storage sphere = _spheres[sphereId];

        // Already claimed for the last epoch instance?
        if (sphere.lastEpochClaimedId >= lastEpochInstanceId) return false;

        EpochInstance storage lastInstance = _epochInstances[lastEpochInstanceId];

        // Has the last epoch instance actually ended?
        if (block.timestamp < lastInstance.endTime) return false;

        // Check eligibility logic (matching claimEpochReward)
        if (sphere.mintTimestamp >= lastInstance.endTime) return false; // Sphere not active during epoch

        // Add other eligibility checks if implemented in claimEpochReward
        // Example: if (sphere.evolutionLevel < requiredLevel) return false;

        return true;
    }


    /**
     * @dev Pauses energy accumulation for a sphere.
     * @param sphereId The ID of the sphere.
     */
    function pauseSphereEnergyAccumulation(uint256 sphereId) external isSphereOwner(sphereId) sphereExists(sphereId) {
        Sphere storage sphere = _spheres[sphereId];
        require(!sphere.isPaused, "Sphere is already paused");

        _updateSphereEnergyInternal(sphereId); // Update energy before pausing

        sphere.isPaused = true;
        emit SpherePaused(sphereId, uint64(block.timestamp));
    }

    /**
     * @dev Resumes energy accumulation for a sphere.
     * @param sphereId The ID of the sphere.
     */
    function resumeSphereEnergyAccumulation(uint256 sphereId) external isSphereOwner(sphereId) sphereExists(sphereId) {
        Sphere storage sphere = _spheres[sphereId];
        require(sphere.isPaused, "Sphere is not paused");

        sphere.isPaused = false;
        // Update lastEnergyUpdateTimestamp to now when resuming, to start accumulation from this point
        sphere.lastEnergyUpdateTimestamp = uint64(block.timestamp);
        emit SphereResumed(sphereId, uint64(block.timestamp));
    }

    /**
     * @dev Allows the owner to set a custom description for their sphere.
     * @param sphereId The ID of the sphere.
     * @param newDescription The new description string (max 100 bytes).
     */
    function setSphereDescription(uint256 sphereId, string memory newDescription) external isSphereOwner(sphereId) sphereExists(sphereId) {
        require(bytes(newDescription).length <= 100, "Description too long"); // Limit description size

        _spheres[sphereId].description = newDescription;
        emit SphereDescriptionUpdated(sphereId, newDescription);
    }

    /**
     * @dev Bonds two spheres together. Requires the caller to own both spheres.
     *      Updates state to link the spheres.
     *      Energy calculation *might* be affected (e.g., bonus rate, shared pool - not implemented in calcPendingEnergy yet, but state is set).
     * @param sphereId1 The ID of the first sphere.
     * @param sphereId2 The ID of the second sphere.
     */
    function bondSpheres(uint256 sphereId1, uint256 sphereId2) external sphereExists(sphereId1) sphereExists(sphereId2) {
        require(sphereId1 != sphereId2, "Cannot bond sphere to itself");
        require(_sphereOwners[sphereId1] == msg.sender, "Not owner of sphere 1");
        require(_sphereOwners[sphereId2] == msg.sender, "Not owner of sphere 2");
        require(_spheres[sphereId1].bondedToSphereId == 0, "Sphere 1 already bonded");
        require(_spheres[sphereId2].bondedToSphereId == 0, "Sphere 2 already bonded");

        // Update energy for both before bonding to capture current state
        _updateSphereEnergyInternal(sphereId1);
        _updateSphereEnergyInternal(sphereId2);

        _spheres[sphereId1].bondedToSphereId = sphereId2;
        _spheres[sphereId2].bondedToSphereId = sphereId1;

        emit SpheresBonded(sphereId1, sphereId2);
    }

    /**
     * @dev Unbonds a sphere from its partner.
     * @param sphereId The ID of the sphere to unbond.
     */
    function unbondSpheres(uint256 sphereId) public sphereExists(sphereId) {
        require(_spheres[sphereId].bondedToSphereId != 0, "Sphere is not bonded");
        // Allow either bonded sphere's owner or the owner of *both* to unbond?
        // Let's simplify: require caller is owner of the sphere they provide.
        require(_sphereOwners[sphereId] == msg.sender, "Not owner of sphere");

        uint256 bondedPartnerId = _spheres[sphereId].bondedToSphereId;
        require(sphereExists(bondedPartnerId), "Bonded partner does not exist"); // Should not happen if state is consistent

         // Update energy for both before unbonding
        _updateSphereEnergyInternal(sphereId);
        _updateSphereEnergyInternal(bondedPartnerId);


        _spheres[sphereId].bondedToSphereId = 0;
        _spheres[bondedPartnerId].bondedToSphereId = 0;

        emit SpheresUnbonded(sphereId, bondedPartnerId);
    }

    /**
     * @dev Allows consuming a specific amount of energy for a hypothetical action.
     *      Placeholder for future functionality unlocked by evolution level or other states.
     * @param sphereId The ID of the sphere.
     * @param energyCost The amount of energy to consume.
     */
    function redeemEnergyForAction(uint256 sphereId, uint256 energyCost) external isSphereOwner(sphereId) sphereExists(sphereId) {
        require(energyCost > 0, "Energy cost must be positive");

        _updateSphereEnergyInternal(sphereId); // Update energy before spending

        Sphere storage sphere = _spheres[sphereId];
        require(sphere.totalEnergy >= energyCost, "Not enough energy for action");

        sphere.totalEnergy -= energyCost;

        // Add specific checks here for which actions are possible based on sphere.evolutionLevel or other state
        // require(sphere.evolutionLevel >= requiredLevel, "Sphere level too low for this action");
        // if (actionId == 1) { ... } else if (actionId == 2) { ... }

        emit EnergyRedeemed(sphereId, energyCost, sphere.totalEnergy);
        // Consider emitting a more specific event like ActionTriggered(sphereId, actionId, energyCost);
    }

    // --- Query Functions ---

    /**
     * @dev Returns the owner of a specific sphere.
     * @param sphereId The ID of the sphere.
     * @return The address of the owner. Returns address(0) if sphere does not exist.
     */
    function ownerOf(uint256 sphereId) public view returns (address) {
        return _sphereOwners[sphereId];
    }

     /**
     * @dev Returns the number of spheres owned by an address.
     * @param owner The address to query.
     * @return The count of spheres owned.
     */
    function getOwnedSpheresCount(address owner) external view returns (uint256) {
        return _ownedSpheresCount[owner];
    }

    /**
     * @dev Returns the full details of a sphere.
     * @param sphereId The ID of the sphere.
     * @return Sphere struct data.
     */
    function getSphereDetails(uint256 sphereId) external view sphereExists(sphereId) returns (Sphere memory) {
        return _spheres[sphereId];
    }

    /**
     * @dev Returns the current evolution level of a sphere.
     * @param sphereId The ID of the sphere.
     * @return The evolution level.
     */
    function getSphereEvolutionLevel(uint256 sphereId) external view sphereExists(sphereId) returns (uint8) {
        return _spheres[sphereId].evolutionLevel;
    }

    /**
     * @dev Returns the current details of the active epoch instance.
     * @return EpochInstance struct data. Returns empty struct if no active epoch.
     */
    function getCurrentEpochDetails() external view returns (EpochInstance memory, EpochConfig memory) {
        if (_currentEpochInstanceId == 0 || block.timestamp >= _epochInstances[_currentEpochInstanceId].endTime) {
            // No active epoch or it has ended naturally
             // Find the last ended epoch if no current one, or indicate none
             if (_epochInstanceCounter > 0) {
                 EpochInstance storage lastInstance = _epochInstances[_epochInstanceCounter];
                 EpochConfig storage lastConfig = _epochConfigs[lastInstance.epochConfigId];
                 return (lastInstance, lastConfig);
             }
            return (EpochInstance(0, 0, 0, false), EpochConfig(0, 0, 0, 0, ""));
        }
        EpochInstance storage currentInstance = _epochInstances[_currentEpochInstanceId];
        EpochConfig storage currentConfig = _epochConfigs[currentInstance.epochConfigId];
        return (currentInstance, currentConfig);
    }

    /**
     * @dev Returns the details of a specific epoch configuration.
     * @param epochConfigId The ID of the epoch configuration.
     * @return EpochConfig struct data.
     */
    function getEpochConfigDetails(uint256 epochConfigId) external view returns (EpochConfig memory) {
        require(_epochConfigs[epochConfigId].duration > 0, "Invalid epoch config ID");
        return _epochConfigs[epochConfigId];
    }

     /**
     * @dev Returns a concise summary of a sphere's key status.
     * @param sphereId The ID of the sphere.
     * @return level, totalEnergy, isPaused, bondedToSphereId, currentEpochRewardClaimed, boostEndTime, boostMultiplier.
     */
    function getSphereStatusSummary(uint256 sphereId) external view sphereExists(sphereId) returns (
        uint8 level,
        uint256 totalEnergy,
        bool isPaused,
        uint256 bondedToSphereId,
        uint256 lastEpochClaimedId,
        uint64 boostEndTime,
        uint16 boostMultiplier
    ) {
        Sphere storage sphere = _spheres[sphereId];
        return (
            sphere.evolutionLevel,
            sphere.totalEnergy, // Note: this is banked energy, not total including pending
            sphere.isPaused,
            sphere.bondedToSphereId,
            sphere.lastEpochClaimedId,
            sphere.boostEndTime,
            sphere.boostMultiplier
        );
    }

    /**
     * @dev Returns the total number of spheres that have been minted and not burned.
     * @return The total supply of spheres.
     */
    function getTotalSupply() external view returns (uint256) {
        // Note: This counter doesn't decrement on burn, so total supply is counter - burned count.
        // To get accurate total supply, need to track burned count or iterate (gas expensive).
        // Let's return the counter for simplicity, implying max ID minted. Off-chain indexer should track burned.
        // A more accurate way needs a Set data structure or similar, complex on-chain.
        // Let's stick to counter for simplicity, assuming off-chain handles tracking burned.
        // Corrected: Use _ownedSpheresCount for sum of all addresses? No, that tracks owners.
        // A simple counter is fine if burn logic doesn't reuse IDs and external systems account for burned IDs.
        // Or, track burned count explicitly. Let's add a burned counter.
        return _sphereCounter - _burnedSphereCount;
    }

    uint256 private _burnedSphereCount; // Track burned spheres for accurate supply

    /**
     * @dev Overrides burnSphere to update burned count.
     */
    function burnSphere(uint256 sphereId) external override isSphereOwner(sphereId) sphereExists(sphereId) {
        require(_spheres[sphereId].bondedToSphereId == 0, "Cannot burn bonded sphere");

        address owner = msg.sender;

        if (_spheres[sphereId].bondedToSphereId != 0) {
            unbondSpheres(sphereId);
        }

        delete _spheres[sphereId];
        delete _sphereOwners[sphereId];
        _ownedSpheresCount[owner]--;
        _burnedSphereCount++; // Increment burned count

        emit SphereBurned(sphereId);
    }


    /**
     * @dev Returns the ID of the sphere bonded to this one.
     * @param sphereId The ID of the sphere.
     * @return The ID of the bonded sphere, or 0 if not bonded.
     */
    function getBondedSphere(uint256 sphereId) external view sphereExists(sphereId) returns (uint256) {
        return _spheres[sphereId].bondedToSphereId;
    }

    /**
     * @dev Returns the current time boost details for a sphere.
     * @param sphereId The ID of the sphere.
     * @return boostEndTime, boostMultiplier.
     */
    function getCurrentTimeBoost(uint256 sphereId) external view sphereExists(sphereId) returns (uint64, uint16) {
        Sphere storage sphere = _spheres[sphereId];
        if (block.timestamp < sphere.boostEndTime) {
             return (sphere.boostEndTime, sphere.boostMultiplier);
        } else {
             return (0, 1000); // No active boost, return default 1x multiplier
        }
    }

    // Adding a few more to reach >= 20 easily and add utility

    /**
     * @dev Get details of a specific epoch instance (past or current).
     * @param instanceId The ID of the epoch instance.
     * @return EpochInstance and EpochConfig data.
     */
    function getEpochInstanceDetails(uint256 instanceId) external view returns (EpochInstance memory, EpochConfig memory) {
        require(instanceId > 0 && instanceId <= _epochInstanceCounter, "Invalid epoch instance ID");
        EpochInstance storage instance = _epochInstances[instanceId];
        require(_epochConfigs[instance.epochConfigId].duration > 0, "Epoch config not found for this instance"); // Should not happen if state is consistent
        EpochConfig storage config = _epochConfigs[instance.epochConfigId];
        return (instance, config);
    }

     /**
     * @dev Get the ID of the last recorded epoch instance.
     * @return The last epoch instance ID, or 0 if none.
     */
    function getLastEpochInstanceId() external view returns (uint256) {
        return _epochInstanceCounter;
    }

    /**
     * @dev Get the ID of the currently active epoch instance.
     * @return The current epoch instance ID, or 0 if none is active *right now*.
     */
     function getCurrentlyActiveEpochInstanceId() external view returns (uint256) {
        if (_currentEpochInstanceId == 0) return 0;
        EpochInstance storage currentInstance = _epochInstances[_currentEpochInstanceId];
        if (block.timestamp >= currentInstance.startTime && block.timestamp < currentInstance.endTime) {
            return _currentEpochInstanceId;
        }
        return 0; // Current instance has ended naturally
     }


    /**
     * @dev Allows the owner to set the global energy rate multiplier.
     * @param multiplier The new multiplier (e.g., 1000 for 1x).
     */
    function setGlobalEnergyRateMultiplier(uint16 multiplier) external onlyOwner {
        globalEnergyRateMultiplier = multiplier;
    }

    // Total functions so far: 31. Meets the requirement.
}
```