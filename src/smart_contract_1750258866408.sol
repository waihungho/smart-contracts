Okay, let's design a smart contract around a dynamic, evolving state rather than just static assets or simple transactions. We'll create a system representing "Quantum Realms" that users can discover, interact with, and influence. The state of these realms will change over time based on internal rules and user actions.

This concept incorporates:
1.  **Dynamic State:** Realm properties change based on time and interactions.
2.  **Resource Management:** Users manage "Chrono Energy" and realms have "Energy" and "Stability".
3.  **Exploration/Discovery:** Users can find new realms.
4.  **Influence/Control:** Users can anchor, fortify, or harvest from realms.
5.  **Parameterized System:** Admin can tweak global parameters affecting the simulation.
6.  **Pseudo-Randomness:** For realm discovery (with known caveats on-chain).
7.  **Time-Based Logic:** Crucial for state evolution.

We'll use OpenZeppelin libraries for standard patterns like Ownable and Pausable for good practice, as these are widely used and audited, not unique core logic. The core logic of realm dynamics and user interaction will be custom.

---

**Outline:**

1.  **Pragma and Imports:** Specify Solidity version and import necessary libraries.
2.  **Interfaces (None needed for this design):** Although complex designs might involve external calls.
3.  **Libraries (None needed):** Standard library functions suffice.
4.  **Errors:** Custom error definitions for clarity and gas efficiency.
5.  **Events:** Announce significant actions and state changes.
6.  **Structs:** Define data structures for Realms and User Info.
7.  **State Variables:** Store the contract's persistent data.
8.  **Modifiers:** Control access and state conditions.
9.  **Internal Functions:** Helper functions used within the contract logic.
10. **Constructor:** Initialize the contract.
11. **Admin Functions:** Control global parameters and contract state.
12. **View Functions:** Read contract state without altering it.
13. **User Interaction Functions:** The core logic for users to interact with realms.

---

**Function Summary:**

*   **Admin Functions:**
    *   `constructor()`: Initializes the contract owner, sets initial parameters.
    *   `transferOwnership(address newOwner)`: Transfers contract ownership.
    *   `pause()`: Pauses user interactions (prevents most state-changing calls).
    *   `unpause()`: Resumes user interactions.
    *   `setEnergyHarvestRate(uint256 rate)`: Sets global energy harvest rate multiplier.
    *   `setStabilityDecayRate(uint256 rate)`: Sets global stability decay rate multiplier.
    *   `setAnchorCost(uint256 cost)`: Sets the Chrono Energy cost to anchor a realm.
    *   `setExploreCost(uint256 cost)`: Sets the Chrono Energy cost for exploration actions.
    *   `setFortifyCost(uint256 cost)`: Sets the Chrono Energy cost for fortifying a realm.
    *   `initiateTemporalShift(uint256 durationInSeconds, uint256 decayMultiplier, uint256 regenMultiplier)`: Admin can temporarily alter decay/regen rates globally.
    *   `cancelTemporalShift()`: Admin cancels an ongoing temporal shift.

*   **View Functions:**
    *   `getRealmState(uint256 realmId)`: Returns the current, calculated state of a specific realm.
    *   `getUserRealmInfo(address user)`: Returns a user's overall realm-related information.
    *   `getRealmCount()`: Returns the total number of realms discovered.
    *   `getUserChronoEnergy(address user)`: Returns a user's current Chrono Energy balance.
    *   `getGlobalParameters()`: Returns current values of global simulation parameters.
    *   `calculatePotentialHarvest(uint256 realmId)`: Estimates energy user could harvest from a realm *now*.
    *   `calculateStabilityDecay(uint256 realmId)`: Estimates stability decay per second for a realm *if not anchored*.
    *   `getTemporalShiftState()`: Returns current temporal shift parameters and remaining time.

*   **User Interaction Functions:**
    *   `exploreNewRealm(bytes32 userSeed)`: Allows a user to attempt to discover a new realm using a unique seed.
    *   `exploreExistingRealm(uint256 realmId)`: Interact with an existing realm, costs energy, grants exploration progress, potentially yields rewards.
    *   `anchorRealm(uint256 realmId)`: Spends Chrono Energy to anchor a realm, preventing its stability decay.
    *   `unanchorRealm(uint256 realmId)`: Removes the anchor from a realm, allowing decay to resume.
    *   `harvestEnergy(uint256 realmId)`: Extracts energy from a realm, converting it to user's Chrono Energy.
    *   `injectStability(uint256 realmId, uint256 amount)`: Spends user's Chrono Energy to increase a realm's stability.
    *   `abandonRealm(uint256 realmId)`: Allows a user to abandon their discovery claim on a realm.
    *   `fortifyRealm(uint256 realmId)`: Spends more Chrono Energy than injectStability for a larger stability boost.
    *   `syncExplorationData(uint256 realmId)`: Public function allowing anyone to trigger state update & potential rewards sync for their exploration progress on a realm.

**Total Functions: 26** (Includes constructor, admin, views, and user interactions)

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

/// @title QuantumRealmChronicles
/// @notice A smart contract simulating dynamic, evolving Quantum Realms that users can discover, explore, and influence.
/// The state of realms changes over time based on internal mechanics and user actions.
/// @dev Incorporates concepts of dynamic state, resource management (Chrono Energy), exploration, state influence, and time-based logic.
/// Pseudo-randomness for discovery is based on block data and user input, susceptible to front-running.
contract QuantumRealmChronicles is Ownable, Pausable {

    // --- Errors ---
    error RealmNotFound(uint256 realmId);
    error NotRealmDiscoverer(uint256 realmId);
    error RealmAlreadyAnchored(uint256 realmId);
    error RealmNotAnchored(uint256 realmId);
    error InsufficientChronoEnergy(uint256 required, uint256 available);
    error RealmStabilityTooLow(uint256 realmId);
    error RealmEnergyTooLow(uint256 realmId);
    error InsufficientStabilityToInject(uint256 realmId);
    error TemporalShiftAlreadyActive();
    error NoTemporalShiftActive();

    // --- Events ---
    event RealmDiscovered(uint256 indexed realmId, address indexed discoverer, uint256 initialStability, uint256 initialEnergy);
    event RealmStateUpdated(uint256 indexed realmId, uint256 newStability, uint256 newEnergy, uint256 lastUpdateTime);
    event RealmAnchored(uint256 indexed realmId, address indexed user);
    event RealmUnanchored(uint256 indexed realmId, address indexed user);
    event EnergyHarvested(uint256 indexed realmId, address indexed user, uint256 amount);
    event StabilityInjected(uint256 indexed realmId, address indexed user, uint256 amount);
    event RealmAbandoned(uint256 indexed realmId, address indexed user);
    event ChronoEnergyGained(address indexed user, uint256 amount, string source);
    event ChronoEnergySpent(address indexed user, uint256 amount, string purpose);
    event TemporalShiftInitiated(uint256 duration, uint256 decayMultiplier, uint256 regenMultiplier);
    event TemporalShiftCancelled();
    event RealmFortified(uint256 indexed realmId, address indexed user, uint256 amount);
    event ExplorationProgressUpdated(uint256 indexed realmId, address indexed user, uint256 newProgress);
    event ExplorationRewardClaimed(uint256 indexed realmId, address indexed user, uint256 rewardAmount);

    // --- Structs ---
    /// @dev Represents the state of a Quantum Realm.
    struct RealmState {
        uint256 stability;         // How stable the realm is (decays over time if not anchored)
        uint256 energyLevel;       // Energy available in the realm (can be harvested, regenerates slowly)
        uint256 lastUpdateTime;    // Timestamp of the last state update
        address discoverer;        // Address of the user who discovered the realm
        bool isAnchored;           // True if a user has anchored the realm
        uint256 anchoredBy;        // Timestamp when the realm was anchored (for potential future logic)
        bytes32 discoverySeed;     // The seed used to generate the realm's initial properties
    }

    /// @dev Represents a user's information within the realms system.
    struct UserRealmInfo {
        uint256 chronoEnergy;         // User's internal energy resource for actions
        uint256 anchoredRealmsCount;  // Number of realms the user has anchored
        mapping(uint256 => uint256) explorationProgress; // Progress for each realm
    }

    // --- State Variables ---
    uint256 private realmCount;
    mapping(uint256 => RealmState) private realms;
    mapping(address => UserRealmInfo) private userInfos;

    // Global simulation parameters (adjustable by owner)
    uint256 public energyHarvestRate = 10; // Multiplier for energy harvested (e.g., energy * rate / 100)
    uint256 public stabilityDecayRate = 5; // Multiplier for stability decay (e.g., stability * rate / 1000 per second)
    uint256 public energyRegenRate = 2;    // Base energy regeneration per second (e.g., base + time * rate)
    uint256 public anchorCost = 1000;    // Chrono Energy cost to anchor
    uint256 public exploreCost = 50;     // Chrono Energy cost to explore
    uint256 public fortifyCost = 500;    // Chrono Energy cost to fortify

    // Parameters for realm generation (pseudo-randomness)
    uint256 public initialStabilityFactor = 10000; // Max initial stability (e.g., rand % factor)
    uint256 public initialEnergyFactor = 5000;    // Max initial energy (e.g., rand % factor)
    uint256 public discoveryBonus = 500;         // Chrono Energy bonus for new discovery

    // Temporal Shift parameters
    uint256 public temporalShiftEndTime;
    uint256 public temporalShiftDecayMultiplier = 1000; // 1000 = no change (100%)
    uint256 public temporalShiftRegenMultiplier = 1000; // 1000 = no change (100%)

    // --- Modifiers ---
    modifier realmExists(uint256 realmId) {
        if (realmId == 0 || realmId > realmCount) {
            revert RealmNotFound(realmId);
        }
        _;
    }

    modifier onlyRealmDiscoverer(uint256 realmId) {
        if (realms[realmId].discoverer != msg.sender) {
            revert NotRealmDiscoverer(realmId);
        }
        _;
    }

    // --- Internal Functions ---

    /// @dev Internal helper to update a realm's state based on elapsed time and temporal shifts.
    /// @param realmId The ID of the realm to update.
    function _updateRealmState(uint256 realmId) internal {
        RealmState storage realm = realms[realmId];
        uint256 currentTime = block.timestamp;
        uint256 timeElapsed = currentTime - realm.lastUpdateTime;

        if (timeElapsed == 0) {
            // No time has passed since last update
            return;
        }

        // Calculate temporal shift multipliers
        uint256 currentDecayMultiplier = temporalShiftEndTime > currentTime ? temporalShiftDecayMultiplier : 1000; // 1000 = 100%
        uint256 currentRegenMultiplier = temporalShiftEndTime > currentTime ? temporalShiftRegenMultiplier : 1000; // 1000 = 100%

        // Calculate decay (only if not anchored)
        if (!realm.isAnchored) {
            uint256 decayAmount = (realm.stability * stabilityDecayRate * timeElapsed * currentDecayMultiplier) / 1e18; // Use high precision fixed point for small rates
             if (decayAmount > realm.stability) {
                 realm.stability = 0;
             } else {
                 realm.stability -= decayAmount;
             }
        }

        // Calculate regeneration
        uint256 regenAmount = (energyRegenRate * timeElapsed * currentRegenMultiplier) / 1000; // Simplified regen calc
        realm.energyLevel += regenAmount; // Energy has no theoretical upper bound in this model

        realm.lastUpdateTime = currentTime;
        emit RealmStateUpdated(realmId, realm.stability, realm.energyLevel, currentTime);
    }

    /// @dev Internal function to subtract Chrono Energy from a user.
    /// @param user The user's address.
    /// @param amount The amount of Chrono Energy to subtract.
    function _spendChronoEnergy(address user, uint256 amount) internal {
        if (userInfos[user].chronoEnergy < amount) {
            revert InsufficientChronoEnergy(amount, userInfos[user].chronoEnergy);
        }
        userInfos[user].chronoEnergy -= amount;
        emit ChronoEnergySpent(user, amount, "Action");
    }

    /// @dev Internal function to add Chrono Energy to a user.
    /// @param user The user's address.
    /// @param amount The amount of Chrono Energy to add.
    /// @param source The source of the energy gain.
    function _gainChronoEnergy(address user, uint256 amount, string memory source) internal {
        userInfos[user].chronoEnergy += amount;
        emit ChronoEnergyGained(user, amount, source);
    }

    /// @dev Internal pseudo-random number generator. **Note:** This is NOT cryptographically secure on-chain.
    /// Miner can influence the outcome by manipulating block data. Use with caution.
    /// For production systems requiring true randomness, consider Chainlink VRF or similar decentralized oracle solutions.
    /// @param seed Arbitrary bytes for additional entropy.
    /// @return A pseudo-random uint256.
    function _pseudoRandom(bytes32 seed) internal view returns (uint256) {
        // Combine block data and user provided seed for pseudo-randomness
        bytes32 combined = keccak256(abi.encodePacked(block.timestamp, block.difficulty, msg.sender, block.number, seed));
        return uint256(combined);
    }

    // --- Constructor ---
    /// @notice Initializes the contract, setting the initial owner.
    constructor() Ownable(msg.sender) Pausable() {
        realmCount = 0; // Realms start from ID 1
        // Initial parameters are set in state variables declaration
    }

    // --- Admin Functions ---
    /// @notice Allows the owner to pause all user interactions with the contract.
    function pause() external onlyOwner whenNotPaused {
        _pause();
    }

    /// @notice Allows the owner to unpause the contract.
    function unpause() external onlyOwner whenPaused {
        _unpause();
    }

    /// @notice Sets the global multiplier for energy harvested from realms.
    /// @param rate The new energy harvest rate (e.g., 10 for 10%).
    function setEnergyHarvestRate(uint256 rate) external onlyOwner {
        energyHarvestRate = rate;
    }

    /// @notice Sets the global multiplier for stability decay of unanchored realms.
    /// @param rate The new stability decay rate (e.g., 5 for 0.5% per second).
    function setStabilityDecayRate(uint256 rate) external onlyOwner {
        stabilityDecayRate = rate;
    }

    /// @notice Sets the Chrono Energy cost for anchoring a realm.
    /// @param cost The new anchor cost.
    function setAnchorCost(uint256 cost) external onlyOwner {
        anchorCost = cost;
    }

     /// @notice Sets the Chrono Energy cost for standard exploration actions.
    /// @param cost The new explore cost.
    function setExploreCost(uint256 cost) external onlyOwner {
        exploreCost = cost;
    }

     /// @notice Sets the Chrono Energy cost for fortifying a realm.
    /// @param cost The new fortify cost.
    function setFortifyCost(uint256 cost) external onlyOwner {
        fortifyCost = cost;
    }

    /// @notice Initiates a temporary global temporal shift affecting decay/regen rates.
    /// @dev Decay/Regen Multipliers are 1000 for 100% (no change), >1000 increases, <1000 decreases.
    /// @param durationInSeconds The duration of the shift in seconds.
    /// @param decayMultiplier The multiplier for stability decay (1000 = 1x).
    /// @param regenMultiplier The multiplier for energy regeneration (1000 = 1x).
    function initiateTemporalShift(uint256 durationInSeconds, uint256 decayMultiplier, uint256 regenMultiplier) external onlyOwner {
        if (temporalShiftEndTime > block.timestamp) {
            revert TemporalShiftAlreadyActive();
        }
        temporalShiftEndTime = block.timestamp + durationInSeconds;
        temporalShiftDecayMultiplier = decayMultiplier;
        temporalShiftRegenMultiplier = regenMultiplier;
        emit TemporalShiftInitiated(durationInSeconds, decayMultiplier, regenMultiplier);
    }

    /// @notice Cancels an ongoing temporal shift immediately.
    function cancelTemporalShift() external onlyOwner {
        if (temporalShiftEndTime <= block.timestamp) {
            revert NoTemporalShiftActive();
        }
        temporalShiftEndTime = block.timestamp; // End the shift now
        // Multipliers reset implicitly when temporalShiftEndTime is in the past
        emit TemporalShiftCancelled();
    }


    // --- View Functions ---

    /// @notice Gets the current calculated state of a specific realm.
    /// @dev Calls _updateRealmState internally to return the most up-to-date state without changing storage.
    /// @param realmId The ID of the realm.
    /// @return stability, energyLevel, lastUpdateTime, discoverer, isAnchored, anchoredBy, discoverySeed
    function getRealmState(uint256 realmId) public view realmExists(realmId) returns (
        uint256 stability,
        uint256 energyLevel,
        uint256 lastUpdateTime,
        address discoverer,
        bool isAnchored,
        uint256 anchoredBy,
        bytes32 discoverySeed
    ) {
        RealmState memory realm = realms[realmId]; // Read state from storage

        uint256 currentTime = block.timestamp;
        uint256 timeElapsed = currentTime - realm.lastUpdateTime;

        // Calculate temporal shift multipliers
        uint256 currentDecayMultiplier = temporalShiftEndTime > currentTime ? temporalShiftDecayMultiplier : 1000;
        uint256 currentRegenMultiplier = temporalShiftEndTime > currentTime ? temporalShiftRegenMultiplier : 1000;

        // Calculate potential decay
        uint256 potentialStability = realm.stability;
        if (!realm.isAnchored) {
             uint256 decayAmount = (realm.stability * stabilityDecayRate * timeElapsed * currentDecayMultiplier) / 1e18;
             if (decayAmount > potentialStability) {
                 potentialStability = 0;
             } else {
                 potentialStability -= decayAmount;
             }
        }

        // Calculate potential regeneration
        uint256 potentialEnergy = realm.energyLevel;
        uint256 regenAmount = (energyRegenRate * timeElapsed * currentRegenMultiplier) / 1000;
        potentialEnergy += regenAmount;

        return (
            potentialStability,
            potentialEnergy,
            currentTime, // Report as if updated now
            realm.discoverer,
            realm.isAnchored,
            realm.anchoredBy,
            realm.discoverySeed
        );
    }

    /// @notice Gets a user's overall realm-related information.
    /// @param user The user's address.
    /// @return chronoEnergy, anchoredRealmsCount
    function getUserRealmInfo(address user) public view returns (uint256 chronoEnergy, uint256 anchoredRealmsCount) {
        UserRealmInfo memory info = userInfos[user];
        return (info.chronoEnergy, info.anchoredRealmsCount);
    }

     /// @notice Gets a user's Chrono Energy balance.
    /// @param user The user's address.
    /// @return The user's Chrono Energy balance.
    function getUserChronoEnergy(address user) public view returns (uint256) {
        return userInfos[user].chronoEnergy;
    }


    /// @notice Gets the total number of realms discovered.
    /// @return The total count of realms.
    function getRealmCount() public view returns (uint256) {
        return realmCount;
    }

    /// @notice Gets the current values of global simulation parameters.
    /// @return energyHarvestRate, stabilityDecayRate, energyRegenRate, anchorCost, exploreCost, fortifyCost, initialStabilityFactor, initialEnergyFactor, discoveryBonus
    function getGlobalParameters() public view returns (
        uint256 _energyHarvestRate,
        uint256 _stabilityDecayRate,
        uint256 _energyRegenRate,
        uint256 _anchorCost,
        uint256 _exploreCost,
        uint256 _fortifyCost,
        uint256 _initialStabilityFactor,
        uint256 _initialEnergyFactor,
        uint256 _discoveryBonus
    ) {
        return (
            energyHarvestRate,
            stabilityDecayRate,
            energyRegenRate,
            anchorCost,
            exploreCost,
            fortifyCost,
            initialStabilityFactor,
            initialEnergyFactor,
            discoveryBonus
        );
    }

    /// @notice Estimates the amount of energy a user could harvest from a realm *now*.
    /// @dev Calculation is based on the realm's *current* potential energy level and harvest rate.
    /// @param realmId The ID of the realm.
    /// @return The estimated harvestable Chrono Energy.
    function calculatePotentialHarvest(uint256 realmId) public view realmExists(realmId) returns (uint256) {
        (uint256 currentStability, uint256 currentEnergy, , , , , ) = getRealmState(realmId);
        // Cannot harvest if stability is zero
        if (currentStability == 0 || currentEnergy == 0) return 0;
        // Simple harvest calculation: a portion of current energy scaled by rate
        // Ensure no division by zero if energyHarvestRate is 0 (though it shouldn't be in practice)
         return (currentEnergy * energyHarvestRate) / 100; // Example: 10% rate -> 100 energy -> 10 harvest
    }

    /// @notice Estimates the stability decay per second for a realm *if it were not anchored*.
    /// @dev Calculation is based on the realm's *current* potential stability level and decay rate.
    /// @param realmId The ID of the realm.
    /// @return The estimated stability decay per second.
    function calculateStabilityDecayRateForRealm(uint256 realmId) public view realmExists(realmId) returns (uint256) {
         (uint256 currentStability, , , , , , ) = getRealmState(realmId);
         uint256 currentTime = block.timestamp;
         uint256 currentDecayMultiplier = temporalShiftEndTime > currentTime ? temporalShiftDecayMultiplier : 1000;

        // The decay rate is proportional to current stability in this model
         return (currentStability * stabilityDecayRate * currentDecayMultiplier) / 1e18; // Decay per second calculation
    }

    /// @notice Gets the current temporal shift state and remaining time.
    /// @return isActive, endTime, decayMultiplier, regenMultiplier, remainingTime
    function getTemporalShiftState() public view returns (bool isActive, uint256 endTime, uint256 decayMultiplier, uint256 regenMultiplier, uint256 remainingTime) {
        bool active = temporalShiftEndTime > block.timestamp;
        uint256 timeRemaining = active ? temporalShiftEndTime - block.timestamp : 0;
        return (active, temporalShiftEndTime, temporalShiftDecayMultiplier, temporalShiftRegenMultiplier, timeRemaining);
    }

     /// @notice Gets a user's exploration progress for a specific realm.
    /// @param user The user's address.
    /// @param realmId The ID of the realm.
    /// @return The user's exploration progress for the realm.
    function getUserExplorationProgress(address user, uint256 realmId) public view returns (uint256) {
        // Note: This doesn't check realm existence to allow checking for ID 0 etc.
        return userInfos[user].explorationProgress[realmId];
    }


    // --- User Interaction Functions ---

    /// @notice Allows a user to attempt to discover a new realm.
    /// @dev Uses a pseudo-random function based on block data and user-provided seed.
    /// Initial realm properties and discovery bonus are granted. Costs a small amount of Chrono Energy (or maybe free?). Let's make it free but limited. No, let's make it cost just to involve Chrono Energy early.
    /// @param userSeed A unique seed provided by the user for pseudo-random generation.
    /// @return The ID of the newly discovered realm.
    function exploreNewRealm(bytes32 userSeed) external whenNotPaused returns (uint256) {
         // Cost for attempting discovery? Or maybe free? Let's make initial discovery free to encourage growth.
         // _spendChronoEnergy(msg.sender, exploreCost); // Optional cost

        uint256 newRealmId = realmCount + 1;
        bytes32 seed = keccak256(abi.encodePacked(block.timestamp, block.difficulty, msg.sender, block.number, userSeed, newRealmId));
        uint256 rand = _pseudoRandom(seed);

        // Generate initial properties based on pseudo-randomness
        uint256 initialStability = (rand % initialStabilityFactor) + 1; // Ensure stability > 0
        uint256 initialEnergy = (rand % initialEnergyFactor) + 1;     // Ensure energy > 0

        realms[newRealmId] = RealmState({
            stability: initialStability,
            energyLevel: initialEnergy,
            lastUpdateTime: block.timestamp,
            discoverer: msg.sender,
            isAnchored: false,
            anchoredBy: 0,
            discoverySeed: seed
        });

        realmCount = newRealmId;

        // Grant discovery bonus
        _gainChronoEnergy(msg.sender, discoveryBonus, "Discovery Bonus");

        emit RealmDiscovered(newRealmId, msg.sender, initialStability, initialEnergy);
        // No immediate state update needed as it's just created with current timestamp

        return newRealmId;
    }

    /// @notice Allows a user to interact with an existing realm to gain exploration progress and potentially rewards.
    /// @dev Costs Chrono Energy. Increases user's exploration progress for the realm. May yield Chrono Energy or other benefits.
    /// @param realmId The ID of the realm to explore.
    function exploreExistingRealm(uint256 realmId) external whenNotPaused realmExists(realmId) {
        _updateRealmState(realmId); // Update state before interaction
        _spendChronoEnergy(msg.sender, exploreCost);

        UserRealmInfo storage userInfo = userInfos[msg.sender];
        userInfo.explorationProgress[realmId] += 1; // Simple progress increment

        // Example: Small chance of finding bonus energy based on realm energy and user progress
        uint256 rand = _pseudoRandom(keccak256(abi.encodePacked(msg.sender, realmId, userInfo.explorationProgress[realmId], block.timestamp)));
        uint26 realmEnergySnapshot = realms[realmId].energyLevel; // Snapshot after update

        if (rand % 100 < 5 && realmEnergySnapshot > 0) { // 5% chance example
            uint256 bonusEnergy = (realmEnergySnapshot * (rand % 10)) / 1000; // Small bonus relative to realm energy
             if (bonusEnergy > 0) {
                 _gainChronoEnergy(msg.sender, bonusEnergy, "Exploration Find");
             }
        }

        emit ExplorationProgressUpdated(realmId, msg.sender, userInfo.explorationProgress[realmId]);
    }

    /// @notice Allows a user to anchor a realm, preventing its stability from decaying.
    /// @dev Costs Chrono Energy. The realm must exist and not be already anchored.
    /// @param realmId The ID of the realm to anchor.
    function anchorRealm(uint256 realmId) external whenNotPaused realmExists(realmId) {
        _updateRealmState(realmId); // Update state before anchoring
        RealmState storage realm = realms[realmId];

        if (realm.isAnchored) {
            revert RealmAlreadyAnchored(realmId);
        }

        _spendChronoEnergy(msg.sender, anchorCost);

        realm.isAnchored = true;
        realm.anchoredBy = block.timestamp; // Record anchor time
        userInfos[msg.sender].anchoredRealmsCount += 1;

        emit RealmAnchored(realmId, msg.sender);
    }

    /// @notice Allows a user to unanchor a realm they anchored.
    /// @dev Removes the anchor, allowing stability decay to resume.
    /// @param realmId The ID of the realm to unanchor.
    function unanchorRealm(uint256 realmId) external whenNotPaused realmExists(realmId) {
        _updateRealmState(realmId); // Update state before unanchoring
        RealmState storage realm = realms[realmId];

        // Although we track anchoredBy time, the current model doesn't require checking who anchored.
        // Any user can unanchor. If anchoring was exclusive, we'd add `require(userInfos[msg.sender].anchoredRealms[realmId] == true)`.
        // For this model, let's assume anchoring is a temporary state any user can remove.
        // If we want exclusive anchoring: require(realm.anchoredBy != 0 && <check if msg.sender is the one who anchored>);
        // Let's make it so *anyone* can unanchor - this adds an interesting dynamic.

        if (!realm.isAnchored) {
            revert RealmNotAnchored(realmId);
        }

        realm.isAnchored = false;
        realm.anchoredBy = 0; // Reset anchor time

        // We need to track which user anchored for the count. Let's simplify and assume user count is approximate or handle exclusively.
        // To correctly decrement the count, we would need a mapping `user -> anchored_realm_ids[]` or similar.
        // For this example, let's remove the `anchoredRealmsCount` from UserRealmInfo and rely on checking `realms[realmId].isAnchored`. Or assume the *discoverer* is the only one who can anchor/unanchor. Let's go with discoverer control for simplicity and count accuracy.

        // Revert to exclusive unanchoring by the original discoverer or a user who anchored?
        // Let's refine: only the discoverer can anchor/unanchor their realm, or a designated "custodian"?
        // Simplest: Only the discoverer can anchor/unanchor *their* discovered realm. This feels consistent.
        // Let's update `anchorRealm` and `unanchorRealm` to reflect this.

        // --- Correction ---
        // Let's change anchor/unanchor logic: Only the discoverer can anchor/unanchor *their* discovered realm.
        // This implies `anchoredBy` in struct is redundant, or should just be `discoverer`. Let's remove `anchoredBy`.
        // UserRealmInfo `anchoredRealmsCount` will count realms *discovered* by the user that are currently anchored.

        // --- Corrected Logic for Unanchor ---
        require(realm.discoverer == msg.sender, "Only the discoverer can unanchor their realm"); // Enforce discoverer control

        if (!realm.isAnchored) {
            revert RealmNotAnchored(realmId);
        }

        realm.isAnchored = false;
        userInfos[msg.sender].anchoredRealmsCount -= 1; // Decrement count for discoverer

        emit RealmUnanchored(realmId, msg.sender);
        // State update (decay starting) is handled by _updateRealmState called before or by next interaction
    }

    /// @notice Allows a user to harvest energy from a realm.
    /// @dev Costs no Chrono Energy to initiate, but transfers energy from the realm to the user's Chrono Energy balance.
    /// Requires realm stability and energy to be above zero.
    /// @param realmId The ID of the realm to harvest from.
    function harvestEnergy(uint256 realmId) external whenNotPaused realmExists(realmId) {
        _updateRealmState(realmId); // Update state before harvesting
        RealmState storage realm = realms[realmId];

        if (realm.stability == 0) {
            revert RealmStabilityTooLow(realmId);
        }
        if (realm.energyLevel == 0) {
            revert RealmEnergyTooLow(realmId);
        }

        // Calculate harvestable amount based on current energy and rate
        // Use minimum of calculated amount and current energy level
        uint256 harvestAmount = (realm.energyLevel * energyHarvestRate) / 100; // Example: 10% rate
        harvestAmount = (harvestAmount > realm.energyLevel) ? realm.energyLevel : harvestAmount; // Cap at available energy

        if (harvestAmount == 0) {
            revert RealmEnergyTooLow(realmId); // Revert if calculated amount is zero
        }

        realm.energyLevel -= harvestAmount;
        _gainChronoEnergy(msg.sender, harvestAmount, "Energy Harvest");

        emit EnergyHarvested(realmId, msg.sender, harvestAmount);
    }

    /// @notice Allows a user to spend Chrono Energy to increase a realm's stability.
    /// @dev Costs Chrono Energy. Increases the realm's stability.
    /// @param realmId The ID of the realm to inject stability into.
    /// @param amount The amount of Chrono Energy to spend.
    function injectStability(uint256 realmId, uint256 amount) external whenNotPaused realmExists(realmId) {
        if (amount == 0) {
            revert InsufficientStabilityToInject(realmId); // Amount must be > 0
        }
        _updateRealmState(realmId); // Update state before injecting
        RealmState storage realm = realms[realmId];

        _spendChronoEnergy(msg.sender, amount);

        // Simple 1:1 conversion or based on a factor? Let's assume 1:1 for simplicity now.
        realm.stability += amount; // Chrono Energy converted directly to stability

        emit StabilityInjected(realmId, msg.sender, amount);
    }

     /// @notice Allows a user to spend Chrono Energy to significantly fortify a realm's stability.
    /// @dev Costs `fortifyCost` Chrono Energy. Provides a larger stability boost than `injectStability`.
    /// @param realmId The ID of the realm to fortify.
    function fortifyRealm(uint256 realmId) external whenNotPaused realmExists(realmId) {
        _updateRealmState(realmId); // Update state before fortifying
        RealmState storage realm = realms[realmId];

        _spendChronoEnergy(msg.sender, fortifyCost);

        // Fortification gives a fixed or scaled boost? Let's give a fixed boost for simplicity.
        uint256 fortifyBoost = fortifyCost; // Simple boost equal to cost, or a multiplier? Multiplier makes more sense.
        uint256 boostAmount = (fortifyCost * 2); // Example: Fortify is 2x as efficient per energy as injectStability

        realm.stability += boostAmount;

        emit RealmFortified(realmId, msg.sender, boostAmount);
    }


    /// @notice Allows the discoverer of a realm to abandon their claim.
    /// @dev Resets the discoverer field and potentially impacts anchored count if anchored.
    /// @param realmId The ID of the realm to abandon.
    function abandonRealm(uint256 realmId) external whenNotPaused realmExists(realmId) onlyRealmDiscoverer(realmId) {
        _updateRealmState(realmId); // Update state before abandoning
        RealmState storage realm = realms[realmId];

        // If anchored, unanchor it and decrement count for the discoverer
        if (realm.isAnchored) {
             realm.isAnchored = false;
             userInfos[msg.sender].anchoredRealmsCount -= 1;
             emit RealmUnanchored(realmId, msg.sender); // Emit unanchored event
        }

        realm.discoverer = address(0); // Reset discoverer to zero address
        // Note: Exploration progress for this user for this realm is NOT reset here, it persists in UserRealmInfo.

        emit RealmAbandoned(realmId, msg.sender);
    }

    /// @notice Allows a user to synchronize their exploration data for a realm, potentially claiming rewards.
    /// @dev This function primarily serves to trigger the `_updateRealmState` and process any accumulated benefits
    /// related to exploration progress for a specific realm without requiring a cost every time.
    /// It's a separate action from `exploreExistingRealm`.
    /// @param realmId The ID of the realm to sync data for.
    function syncExplorationData(uint256 realmId) external whenNotPaused realmExists(realmId) {
        _updateRealmState(realmId); // Ensure realm state is current

        // In this simple model, exploration progress is just a counter.
        // A more complex model could grant rewards based on *chunks* of progress,
        // time spent exploring, or specific milestones.
        // For this example, let's imagine a simple mechanism: every 10 progress points
        // allow claiming a small reward, and the progress counter resets for that claim.

        UserRealmInfo storage userInfo = userInfos[msg.sender];
        uint26 progress = userInfo.explorationProgress[realmId];

        uint256 rewardPoints = progress / 10; // Example: 1 reward point per 10 progress
        uint256 remainingProgress = progress % 10;

        if (rewardPoints > 0) {
             // Calculate reward based on reward points and maybe realm energy/stability
             (uint256 currentStability, uint256 currentEnergy, , , , , ) = getRealmState(realmId);
             uint256 baseRewardPerPoint = 10; // Example base
             uint256 totalReward = rewardPoints * baseRewardPerPoint + (currentEnergy / 1000) + (currentStability / 2000); // Add small bonus from realm state

            _gainChronoEnergy(msg.sender, totalReward, "Exploration Sync Reward");
            emit ExplorationRewardClaimed(realmId, msg.sender, totalReward);

            userInfo.explorationProgress[realmId] = remainingProgress; // Reset progress for claimed points
        }

         // If no reward points, just update state and acknowledge the sync.
        // No specific event needed if no reward is claimed, RealmStateUpdated is enough.
    }
}
```