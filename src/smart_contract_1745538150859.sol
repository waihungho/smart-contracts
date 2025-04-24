Okay, here is a Solidity smart contract for a system I'm calling "Chronoids: Evolving Digital Organisms".

**Concept:** This contract simulates a world of on-chain digital organisms called Chronoids. Chronoids have traits, energy, and health. They can perform various actions that consume energy and affect their state or the state of other Chronoids/the environment. They can evolve through mutation and reproduction. The environment itself has parameters that influence Chronoid behavior and evolution, controllable by designated "Stewards". The system incorporates concepts like dynamic state, resource management (energy), pseudo-random events (mutation, engagement outcomes), trait inheritance/evolution, and a basic role-based access control.

It aims to be distinct from standard ERC20/ERC721 boilerplate, focusing on interactive on-chain simulation and state changes beyond simple ownership or fixed metadata.

---

### Chronoids: Evolving Digital Organisms

**Outline:**

1.  **Contract Definition:** Main contract `Chronoids`.
2.  **Roles:** Basic owner role and a multi-address "Steward" role for parameter management.
3.  **Paused State:** Contract can be paused for emergency maintenance (prevents user actions).
4.  **Data Structures:**
    *   `Chronoid` struct: Represents an individual organism with ID, owner, stats, traits, lineage, status, etc.
    *   `Environment` struct: Global parameters influencing all Chronoids.
    *   `TraitRanges` struct: Defines min/max possible values for traits.
5.  **State Variables:** Mappings and variables to store Chronoids, environment data, stewards, fee balance, etc.
6.  **Events:** To log important actions and state changes.
7.  **Modifiers:** For access control and state checks.
8.  **Constructor:** Initializes owner, initial environment parameters, and creation fee.
9.  **Core Management Functions:** Creation, transfer, burning, pausing, fee withdrawal.
10. **Chronoid Action Functions:** Actions Chronoids can perform (consuming energy).
11. **Steward Functions:** Functions to adjust environment parameters.
12. **View/Utility Functions:** Read state, check conditions, calculate potential outcomes.
13. **Internal Helper Functions:** Complex logic hidden from external calls (trait generation, energy calculation, action outcomes, randomness).

**Function Summary:**

1.  `constructor()`: Initializes the contract owner, stewards, environment, and creation fee.
2.  `createChronoid()`: Mints a new Chronoid for the caller (requires ETH fee).
3.  `transferChronoid(uint256 _chronoidId, address _to)`: Transfers ownership of a Chronoid.
4.  `burnChronoid(uint256 _chronoidId)`: Destroys a Chronoid, removing it from existence.
5.  `rest(uint256 _chronoidId)`: Allows a Chronoid to recover energy based on time elapsed.
6.  `exploreEnvironment(uint256 _chronoidId)`: Chronoid explores, potentially finding essence or encountering minor events.
7.  `engageChronoid(uint256 _chronoidId1, uint256 _chronoidId2)`: Initiates an interaction (e.g., competition, bonding) between two Chronoids, affecting their state.
8.  `attemptMutation(uint256 _chronoidId)`: Chronoid attempts to mutate, chance and outcome influenced by environment and traits.
9.  `reproduce(uint256 _parent1Id, uint256 _parent2Id)`: Creates a new Chronoid child from two parent Chronoids (requires conditions met).
10. `gatherEssence(uint256 _chronoidId)`: A specific action to gather "essence", potentially boosting traits or affecting environment state.
11. `setMutationFactor(uint16 _newFactor)`: Steward function to adjust the environment's mutation influence.
12. `setEnergyRecoveryRate(uint16 _newRate)`: Steward function to adjust how fast Chronoids recover energy.
13. `addSteward(address _steward)`: Owner function to grant Steward role.
14. `removeSteward(address _steward)`: Owner function to revoke Steward role.
15. `pauseContract()`: Owner function to pause user actions.
16. `unpauseContract()`: Owner function to unpause the contract.
17. `withdrawFees()`: Owner function to withdraw accumulated ETH fees.
18. `getChronoidDetails(uint256 _chronoidId)`: View function to retrieve a Chronoid's full details.
19. `getTotalChronoids()`: View function for the total number of Chronoids ever created.
20. `getChronoidsByOwner(address _owner)`: View function listing Chronoid IDs owned by an address.
21. `getEnvironmentParams()`: View function for current environment settings.
22. `isSteward(address _addr)`: View function to check if an address is a steward.
23. `calculateEnergyRecovery(uint256 _chronoidId)`: View function estimating potential energy recovery since last action.
24. `calculateMutationProbability(uint256 _chronoidId)`: View function estimating the chance of successful mutation.

*(Note: The internal helper functions also contribute significantly to the logic but are not directly callable externally, so they aren't listed in the *public* function summary count).*

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title Chronoids: Evolving Digital Organisms
 * @dev A smart contract simulating digital organisms (Chronoids) that can be created,
 * owned, and interact within a dynamic on-chain environment. Chronoids have traits,
 * energy, and health. They can perform actions like resting, exploring, engaging others,
 * mutating, and reproducing, all influencing their state and the global environment
 * parameters. Stewards manage environmental factors.
 * Features: Dynamic state, energy management, pseudo-random events (mutation, engagement),
 * trait evolution/inheritance, role-based access control (Owner, Steward), pausability.
 */
contract Chronoids {

    // --- Enums ---

    enum ChronoidStatus {
        Alive,
        Dormant, // Can't perform actions, requires rest
        Mutating, // Temporarily unavailable while mutating
        Injured // Can't perform actions, requires healing/rest
    }

    // --- Structs ---

    struct Chronoid {
        uint256 id;
        address owner;
        uint64 birthBlock;
        uint64 lastActionBlock; // Use uint64 as block.number fits within it
        uint8 energy; // 0-100
        uint8 health; // 0-100
        uint256 traits; // Packed traits (e.g., Strength, Agility, Resilience, Intelligence, Mutation Affinity)
        uint16 generation;
        uint256 parent1Id; // 0 for Genesis Chronoids
        uint256 parent2Id; // 0 for Genesis Chronoids
        ChronoidStatus status;
    }

    struct Environment {
        uint16 mutationFactor; // Influences mutation probability and intensity (e.g., 0-1000)
        uint16 energyRecoveryRate; // Base energy recovered per block (e.g., 0-100)
        uint16 essenceBoostFactor; // How much essence gathering boosts traits (e.g., 0-100)
    }

    // Trait bit positions and masks (assuming 5 traits, 8 bits each = 40 bits needed in uint256)
    // This allows for 5 traits, each 0-255. Max total trait value is 1275.
    uint8 constant TRAIT_BITS = 8; // Each trait uses 8 bits (0-255)
    uint8 constant NUM_TRAITS = 5;
    uint256 constant TRAIT_MASK = (1 << TRAIT_BITS) - 1; // 0xFF

    // Trait indices (for clarity)
    uint8 constant TRAIT_STRENGTH_INDEX = 0;
    uint8 constant TRAIT_AGILITY_INDEX = 1;
    uint8 constant TRAIT_RESILIENCE_INDEX = 2;
    uint8 constant TRAIT_INTELLIGENCE_INDEX = 3;
    uint8 constant TRAIT_MUTATION_AFFINITY_INDEX = 4; // Influences self-mutation chance

    // --- State Variables ---

    mapping(uint256 => Chronoid) public chronoids;
    uint256 public chronoidCount; // Starts at 1 for the first ID

    mapping(address => uint256[]) private ownerToChronoids;
    mapping(uint256 => uint256) private chronoidIndexInOwnerArray; // Helps remove chronoid ID from owner array efficiently

    Environment public environment;

    address private _owner;
    mapping(address => bool) private _stewards;

    bool public isPaused = false;

    uint256 public creationFee;
    uint256 public contractBalance; // Tracks collected fees

    // --- Constants ---
    uint8 constant MAX_ENERGY = 100;
    uint8 constant MAX_HEALTH = 100;
    uint8 constant MIN_ACTION_ENERGY = 10; // Minimum energy required for most actions

    // --- Events ---

    event ChronoidCreated(uint256 id, address owner, uint16 generation, uint256 parent1Id, uint256 parent2Id, uint256 initialTraits);
    event ChronoidTransferred(uint256 id, address from, address to);
    event ChronoidBurned(uint256 id);
    event ChronoidStateChanged(uint256 id, uint8 energy, uint8 health, uint256 traits, ChronoidStatus status);
    event EnvironmentChanged(uint16 mutationFactor, uint16 energyRecoveryRate, uint16 essenceBoostFactor);
    event StewardAdded(address steward);
    event StewardRemoved(address steward);
    event ContractPaused(address by);
    event ContractUnpaused(address by);
    event FeesWithdrawn(address to, uint256 amount);
    event ActionRest(uint256 chronoidId, uint8 energyRecovered, uint8 newEnergy);
    event ActionExplore(uint256 chronoidId, string outcome); // Outcome could be mapped to enum/uint
    event ActionEngage(uint256 chronoid1Id, uint256 chronoid2Id, string outcome);
    event ActionMutationAttempt(uint256 chronoidId, bool success, uint256 newTraits);
    event ActionReproduce(uint256 parent1Id, uint256 parent2Id, uint256 childId);
    event ActionGatherEssence(uint256 chronoidId, uint8 essenceBoost, uint256 newTraits);


    // --- Modifiers ---

    modifier onlyOwner() {
        require(msg.sender == _owner, "Only owner can call");
        _;
    }

    modifier onlySteward() {
        require(_stewards[msg.sender] || msg.sender == _owner, "Only steward or owner can call");
        _;
    }

    modifier whenNotPaused() {
        require(!isPaused, "Contract is paused");
        _;
    }

    modifier whenPaused() {
        require(isPaused, "Contract is not paused");
        _;
    }

    modifier isValidChronoid(uint256 _chronoidId) {
        require(_chronoidId > 0 && _chronoidId <= chronoidCount && chronoids[_chronoidId].id != 0, "Invalid Chronoid ID");
        _;
    }

    modifier isChronoidAlive(uint256 _chronoidId) {
         require(chronoids[_chronoidId].status != ChronoidStatus.Dormant &&
                 chronoids[_chronoidId].status != ChronoidStatus.Mutating &&
                 chronoids[_chronoidId].status != ChronoidStatus.Injured, "Chronoid is not in an active state");
        _;
    }

    modifier requireEnergy(uint256 _chronoidId, uint8 _amount) {
        require(chronoids[_chronoidId].energy >= _amount, "Not enough energy");
        _;
    }


    // --- Constructor ---

    constructor(uint16 _initialMutationFactor, uint16 _initialEnergyRecoveryRate, uint16 _initialEssenceBoostFactor, uint256 _initialCreationFee) {
        _owner = msg.sender;
        _stewards[msg.sender] = true; // Owner is also a steward by default

        environment = Environment({
            mutationFactor: _initialMutationFactor,
            energyRecoveryRate: _initialEnergyRecoveryRate,
            essenceBoostFactor: _initialEssenceBoostFactor
        });

        creationFee = _initialCreationFee;
        contractBalance = 0;

        chronoidCount = 0; // Will be incremented to 1 for the first chronoid
    }

    // --- Core Management Functions ---

    /**
     * @notice Creates a new Genesis Chronoid.
     * @dev Requires payment of the creation fee. Genesis Chronoids have generation 0.
     * Traits are generated based on block data randomness.
     */
    function createChronoid() external payable whenNotPaused {
        require(msg.value >= creationFee, "Insufficient creation fee");

        uint256 newId = ++chronoidCount;
        address _owner = msg.sender;

        // Pseudo-random trait generation based on block data
        uint256 seed = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, block.number, msg.sender, newId)));
        uint256 initialTraits = _generateTraits(seed, 0); // Generation 0 has no parents

        chronoids[newId] = Chronoid({
            id: newId,
            owner: _owner,
            birthBlock: uint64(block.number),
            lastActionBlock: uint64(block.number),
            energy: MAX_ENERGY, // Start with full energy
            health: MAX_HEALTH, // Start with full health
            traits: initialTraits,
            generation: 0,
            parent1Id: 0,
            parent2Id: 0,
            status: ChronoidStatus.Alive
        });

        _addChronoidToOwner(_owner, newId);

        contractBalance += msg.value;

        emit ChronoidCreated(newId, _owner, 0, 0, 0, initialTraits);
        emit ChronoidStateChanged(newId, MAX_ENERGY, MAX_HEALTH, initialTraits, ChronoidStatus.Alive);
    }

    /**
     * @notice Transfers ownership of a Chronoid.
     * @param _chronoidId The ID of the Chronoid to transfer.
     * @param _to The address to transfer the Chronoid to.
     */
    function transferChronoid(uint256 _chronoidId, address _to) external isValidChronoid(_chronoidId) {
        require(msg.sender == chronoids[_chronoidId].owner, "Not your Chronoid");
        require(_to != address(0), "Cannot transfer to zero address");

        address from = msg.sender;
        _transferChronoidInternal(from, _to, _chronoidId);

        emit ChronoidTransferred(_chronoidId, from, _to);
    }

    /**
     * @notice Destroys a Chronoid.
     * @dev This is irreversible. Only the owner can burn their Chronoid.
     * @param _chronoidId The ID of the Chronoid to burn.
     */
    function burnChronoid(uint256 _chronoidId) external isValidChronoid(_chronoidId) {
         require(msg.sender == chronoids[_chronoidId].owner, "Not your Chronoid");

         address owner = msg.sender;
         _removeChronoidFromOwner(owner, _chronoidId);

         // Clear the chronoid data from storage
         delete chronoids[_chronoidId];

         emit ChronoidBurned(_chronoidId);
    }

    /**
     * @notice Pauses the contract. Prevents most user actions.
     * @dev Only the owner can pause.
     */
    function pauseContract() external onlyOwner whenNotPaused {
        isPaused = true;
        emit ContractPaused(msg.sender);
    }

    /**
     * @notice Unpauses the contract. Allows user actions again.
     * @dev Only the owner can unpause.
     */
    function unpauseContract() external onlyOwner whenPaused {
        isPaused = false;
        emit ContractUnpaused(msg.sender);
    }

    /**
     * @notice Allows the owner to withdraw accumulated fees.
     * @dev Only the owner can withdraw.
     */
    function withdrawFees() external onlyOwner {
        require(contractBalance > 0, "No fees to withdraw");
        uint256 amount = contractBalance;
        contractBalance = 0;
        (bool success, ) = payable(_owner).call{value: amount}("");
        require(success, "Withdrawal failed");
        emit FeesWithdrawn(_owner, amount);
    }


    // --- Chronoid Action Functions (whenNotPaused) ---

    /**
     * @notice Allows a Chronoid to rest and recover energy.
     * @dev Energy recovery rate is based on environment parameters and time since last action.
     * @param _chronoidId The ID of the Chronoid resting.
     */
    function rest(uint256 _chronoidId) external whenNotPaused isValidChronoid(_chronoidId) isChronoidAlive(_chronoidId) {
        require(msg.sender == chronoids[_chronoidId].owner, "Not your Chronoid");
        require(chronoids[_chronoidId].energy < MAX_ENERGY, "Energy already full");

        uint8 recoveredEnergy = _calculateEnergyRecovery(_chronoidId);
        uint8 oldEnergy = chronoids[_chronoidId].energy;
        chronoids[_chronoidId].energy = uint8(Math.min(MAX_ENERGY, oldEnergy + recoveredEnergy));
        chronoids[_chronoidId].lastActionBlock = uint64(block.number);

        emit ActionRest(_chronoidId, recoveredEnergy, chronoids[_chronoidId].energy);
        emit ChronoidStateChanged(_chronoidId, chronoids[_chronoidId].energy, chronoids[_chronoidId].health, chronoids[_chronoidId].traits, chronoids[_chronoidId].status);
    }

    /**
     * @notice Chronoid explores the environment.
     * @dev Consumes energy. Can have varied minor outcomes based on pseudo-randomness.
     * @param _chronoidId The ID of the Chronoid exploring.
     */
    function exploreEnvironment(uint256 _chronoidId) external whenNotPaused isValidChronoid(_chronoidId) isChronoidAlive(_chronoidId) requireEnergy(_chronoidId, MIN_ACTION_ENERGY) {
         require(msg.sender == chronoids[_chronoidId].owner, "Not your Chronoid");

         _deductEnergy(_chronoidId, MIN_ACTION_ENERGY);

         uint256 seed = _generateActionSeed(_chronoidId);
         // Simulate varied minor outcomes
         string memory outcome;
         if (seed % 100 < 20) { // 20% chance of finding something beneficial
             chronoids[_chronoidId].health = uint8(Math.min(MAX_HEALTH, chronoids[_chronoidId].health + 5)); // Small health boost
             outcome = "Found a refreshing spot.";
         } else if (seed % 100 < 30) { // 10% chance of minor setback
             chronoids[_chronoidId].health = uint8(Math.max(0, int(chronoids[_chronoidId].health) - 5)); // Small health loss
             outcome = "Stumbled upon a hazard.";
         } else { // 70% chance of uneventful exploration
             outcome = "Exploration was uneventful.";
         }

         // Check for health status update
         _checkHealthStatus(_chronoidId);

         emit ActionExplore(_chronoidId, outcome);
         emit ChronoidStateChanged(_chronoidId, chronoids[_chronoidId].energy, chronoids[_chronoidId].health, chronoids[_chronoidId].traits, chronoids[_chronoidId].status);
    }

    /**
     * @notice Initiates an engagement between two Chronoids.
     * @dev Can be a fight, bonding, etc. Outcome depends on traits and randomness.
     * Consumes energy from both participants.
     * @param _chronoid1Id The ID of the first Chronoid.
     * @param _chronoid2Id The ID of the second Chronoid.
     */
    function engageChronoid(uint256 _chronoid1Id, uint256 _chronoid2Id) external whenNotPaused isValidChronoid(_chronoid1Id) isValidChronoid(_chronoid2Id) isChronoidAlive(_chronoid1Id) isChronoidAlive(_chronoid2Id) {
        require(_chronoid1Id != _chronoid2Id, "Cannot engage with self");
        require(msg.sender == chronoids[_chronoid1Id].owner || msg.sender == chronoids[_chronoid2Id].owner, "Must own one of the Chronoids");

        // Both need energy (require min energy for both)
        require(chronoids[_chronoid1Id].energy >= MIN_ACTION_ENERGY && chronoids[_chronoid2Id].energy >= MIN_ACTION_ENERGY, "Both Chronoids need energy");

        _deductEnergy(_chronoid1Id, MIN_ACTION_ENERGY);
        _deductEnergy(_chronoid2Id, MIN_ACTION_ENERGY);

        string memory outcome = _handleEngagementLogic(_chronoid1Id, _chronoid2Id);

        // Check health status for both
        _checkHealthStatus(_chronoid1Id);
        _checkHealthStatus(_chronoid2Id);

        emit ActionEngage(_chronoid1Id, _chronoid2Id, outcome);
        emit ChronoidStateChanged(_chronoid1Id, chronoids[_chronoid1Id].energy, chronoids[_chronoid1Id].health, chronoids[_chronoid1Id].traits, chronoids[_chronoid1Id].status);
        emit ChronoidStateChanged(_chronoid2Id, chronoids[_chronoid2Id].energy, chronoids[_chronoid2Id].health, chronoids[_chronoid2Id].traits, chronoids[_chronoid2Id].status);
    }

    /**
     * @notice Chronoid attempts to trigger a mutation.
     * @dev Chance and outcome influenced by environment mutation factor and the Chronoid's Mutation Affinity trait.
     * Consumes energy.
     * @param _chronoidId The ID of the Chronoid attempting mutation.
     */
    function attemptMutation(uint256 _chronoidId) external whenNotPaused isValidChronoid(_chronoidId) isChronoidAlive(_chronoidId) requireEnergy(_chronoidId, MIN_ACTION_ENERGY * 2) { // Mutation is more energy intensive
        require(msg.sender == chronoids[_chronoidId].owner, "Not your Chronoid");

        _deductEnergy(_chronoidId, MIN_ACTION_ENERGY * 2);

        uint256 seed = _generateActionSeed(_chronoidId);
        uint16 mutationAffinity = _getTrait(chronoids[_chronoidId].traits, TRAIT_MUTATION_AFFINITY_INDEX);
        // Base chance + affinity bonus + environment factor influence
        uint256 chance = (10 + (mutationAffinity / 10) + (environment.mutationFactor / 50)) * 10; // Scale factors for a % chance out of 1000

        bool mutationSuccess = (seed % 1000 < chance);

        uint256 newTraits = chronoids[_chronoidId].traits; // Default to current traits

        if (mutationSuccess) {
            // Apply mutation logic
            chronoids[_chronoidId].status = ChronoidStatus.Mutating; // Temporarily set status
            newTraits = _applyMutation(_chronoidId, seed);
            chronoids[_chronoidId].traits = newTraits;
             // Mutation might briefly reduce health or energy (simulating strain)
            chronoids[_chronoidId].health = uint8(Math.max(1, int(chronoids[_chronoidId].health) - 10));
            chronoids[_chronoidId].energy = uint8(Math.max(1, int(chronoids[_chronoidId].energy) - 10));
             // After mutation, maybe status becomes Injured or Dormant for a brief period (handled implicitly by energy/health check or require status)
            _checkHealthStatus(_chronoidId); // Might trigger Injured status
            if (chronoids[_chronoidId].status == ChronoidStatus.Mutating) {
                 chronoids[_chronoidId].status = ChronoidStatus.Dormant; // Default state after mutation strain
            }

        } else {
            // Failed mutation attempt
            // Small penalty for failed attempt
            chronoids[_chronoidId].health = uint8(Math.max(1, int(chronoids[_chronoidId].health) - 2));
             _checkHealthStatus(_chronoidId);
        }

        emit ActionMutationAttempt(_chronoidId, mutationSuccess, newTraits);
        emit ChronoidStateChanged(_chronoidId, chronoids[_chronoidId].energy, chronoids[_chronoidId].health, chronoids[_chronoidId].traits, chronoids[_chronoidId].status);
    }

    /**
     * @notice Allows two Chronoids to reproduce and create a child.
     * @dev Requires both parents to meet conditions (Alive, sufficient energy, same owner or mutual consent logic needed, generation difference).
     * Consumes energy from both parents. Child inherits traits with potential variation/mutation.
     * @param _parent1Id The ID of the first parent.
     * @param _parent2Id The ID of the second parent.
     */
    function reproduce(uint256 _parent1Id, uint256 _parent2Id) external whenNotPaused isValidChronoid(_parent1Id) isValidChronoid(_parent2Id) isChronoidAlive(_parent1Id) isChronoidAlive(_parent2Id) {
        require(_parent1Id != _parent2Id, "Cannot reproduce with self");
        require(msg.sender == chronoids[_parent1Id].owner && msg.sender == chronoids[_parent2Id].owner, "Must own both parent Chronoids"); // Simple owner check

        // Require sufficient energy from both parents (Reproduction is energy intensive)
        uint8 reproductionEnergyCost = MIN_ACTION_ENERGY * 3;
        require(chronoids[_parent1Id].energy >= reproductionEnergyCost && chronoids[_parent2Id].energy >= reproductionEnergyCost, "Both parents need enough energy for reproduction");

        // Add other reproduction criteria (e.g., generation gap, specific traits?)
        // require(chronoids[_parent1Id].generation <= chronoids[_parent2Id].generation + 2 && chronoids[_parent2Id].generation <= chronoids[_parent1Id].generation + 2, "Generations too far apart");

        _deductEnergy(_parent1Id, reproductionEnergyCost);
        _deductEnergy(_parent2Id, reproductionEnergyCost);

        uint256 childId = ++chronoidCount;
        uint16 childGeneration = uint16(Math.max(chronoids[_parent1Id].generation, chronoids[_parent2Id].generation) + 1);
        address childOwner = msg.sender;

        // Generate child traits (mix of parents with potential mutation influence)
        uint256 seed = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, block.number, msg.sender, _parent1Id, _parent2Id, childId)));
        uint256 childTraits = _generateChildTraits(chronoids[_parent1Id].traits, chronoids[_parent2Id].traits, seed);

         chronoids[childId] = Chronoid({
            id: childId,
            owner: childOwner,
            birthBlock: uint64(block.number),
            lastActionBlock: uint64(block.number),
            energy: uint8(MAX_ENERGY / 2), // Child starts with half energy
            health: MAX_HEALTH,
            traits: childTraits,
            generation: childGeneration,
            parent1Id: _parent1Id,
            parent2Id: _parent2Id,
            status: ChronoidStatus.Alive
        });

        _addChronoidToOwner(childOwner, childId);

        // Reproduction effort might reduce parent health slightly
        chronoids[_parent1Id].health = uint8(Math.max(1, int(chronoids[_parent1Id].health) - 5));
        chronoids[_parent2Id].health = uint8(Math.max(1, int(chronoids[_parent2Id].health) - 5));

        _checkHealthStatus(_parent1Id);
        _checkHealthStatus(_parent2Id);

        emit ActionReproduce(_parent1Id, _parent2Id, childId);
        emit ChronoidCreated(childId, childOwner, childGeneration, _parent1Id, _parent2Id, childTraits);
        emit ChronoidStateChanged(childId, uint8(MAX_ENERGY / 2), MAX_HEALTH, childTraits, ChronoidStatus.Alive);
        emit ChronoidStateChanged(_parent1Id, chronoids[_parent1Id].energy, chronoids[_parent1Id].health, chronoids[_parent1Id].traits, chronoids[_parent1Id].status);
        emit ChronoidStateChanged(_parent2Id, chronoids[_parent2Id].energy, chronoids[_parent2Id].health, chronoids[_parent2Id].traits, chronoids[_parent2Id].status);
    }

    /**
     * @notice Chronoid attempts to gather 'essence' from the environment.
     * @dev Consumes energy. Can provide small, random trait boosts or influence environment slightly.
     * @param _chronoidId The ID of the Chronoid gathering essence.
     */
    function gatherEssence(uint256 _chronoidId) external whenNotPaused isValidChronoid(_chronoidId) isChronoidAlive(_chronoidId) requireEnergy(_chronoidId, MIN_ACTION_ENERGY) {
         require(msg.sender == chronoids[_chronoidId].owner, "Not your Chronoid");

         _deductEnergy(_chronoidId, MIN_ACTION_ENERGY);

         uint256 seed = _generateActionSeed(_chronoidId);
         uint16 essenceBoost = 0;
         uint256 currentTraits = chronoids[_chronoidId].traits;
         uint256 newTraits = currentTraits;

         if (seed % 100 < environment.essenceBoostFactor / 10) { // Chance influenced by environment
             // Success: Boost a random trait
             uint8 traitIndexToBoost = uint8(seed % NUM_TRAITS);
             uint16 currentTraitValue = _getTrait(currentTraits, traitIndexToBoost);
             uint16 boostAmount = uint16(1 + (seed % 5)); // Boost by 1-5 points
             uint16 boostedValue = uint16(Math.min(255, currentTraitValue + boostAmount)); // Traits cap at 255
             newTraits = _setTrait(currentTraits, traitIndexToBoost, boostedValue);
             chronoids[_chronoidId].traits = newTraits;
             essenceBoost = boostAmount;
         }

         // Small chance to influence environment factor (e.g., slightly increase mutation factor)
         if (seed % 1000 < 10) { // 1% chance
             environment.mutationFactor = uint16(Math.min(1000, environment.mutationFactor + 1)); // Small increase
             emit EnvironmentChanged(environment.mutationFactor, environment.energyRecoveryRate, environment.essenceBoostFactor);
         }

         emit ActionGatherEssence(_chronoidId, essenceBoost, newTraits);
         emit ChronoidStateChanged(_chronoidId, chronoids[_chronoidId].energy, chronoids[_chronoidId].health, chronoids[_chronoidId].traits, chronoids[_chronoidId].status);
    }


    // --- Steward Functions (onlySteward, whenNotPaused applies unless function is for emergency config) ---

    /**
     * @notice Sets the environment's mutation factor.
     * @dev Higher factor increases mutation chance and intensity.
     * @param _newFactor The new mutation factor (0-1000).
     */
    function setMutationFactor(uint16 _newFactor) external onlySteward whenNotPaused {
        require(_newFactor <= 1000, "Mutation factor max is 1000");
        environment.mutationFactor = _newFactor;
        emit EnvironmentChanged(environment.mutationFactor, environment.energyRecoveryRate, environment.essenceBoostFactor);
    }

     /**
     * @notice Sets the environment's energy recovery rate.
     * @dev Higher rate means Chronoids recover energy faster when resting.
     * @param _newRate The new energy recovery rate (0-100).
     */
    function setEnergyRecoveryRate(uint16 _newRate) external onlySteward whenNotPaused {
        require(_newRate <= 100, "Energy recovery rate max is 100");
        environment.energyRecoveryRate = _newRate;
        emit EnvironmentChanged(environment.mutationFactor, environment.energyRecoveryRate, environment.essenceBoostFactor);
    }

     /**
     * @notice Sets the environment's essence boost factor.
     * @dev Higher factor increases the chance and magnitude of trait boosts from gathering essence.
     * @param _newFactor The new essence boost factor (0-100).
     */
    function setEssenceBoostFactor(uint16 _newFactor) external onlySteward whenNotPaused {
        require(_newFactor <= 100, "Essence boost factor max is 100");
        environment.essenceBoostFactor = _newFactor;
         emit EnvironmentChanged(environment.mutationFactor, environment.energyRecoveryRate, environment.essenceBoostFactor);
    }

    /**
     * @notice Adds an address to the list of stewards.
     * @dev Only the owner can add stewards.
     * @param _steward The address to add.
     */
    function addSteward(address _steward) external onlyOwner {
        require(_steward != address(0), "Cannot add zero address as steward");
        require(!_stewards[_steward], "Address is already a steward");
        _stewards[_steward] = true;
        emit StewardAdded(_steward);
    }

    /**
     * @notice Removes an address from the list of stewards.
     * @dev Only the owner can remove stewards. Cannot remove the owner's steward role this way.
     * @param _steward The address to remove.
     */
    function removeSteward(address _steward) external onlyOwner {
        require(_steward != _owner, "Cannot remove owner's steward role");
        require(_stewards[_steward], "Address is not a steward");
        _stewards[_steward] = false;
        emit StewardRemoved(_steward);
    }


    // --- View / Utility Functions ---

    /**
     * @notice Gets the details of a specific Chronoid.
     * @param _chronoidId The ID of the Chronoid.
     * @return A tuple containing the Chronoid's properties.
     */
    function getChronoidDetails(uint256 _chronoidId) external view isValidChronoid(_chronoidId) returns (
        uint256 id,
        address owner,
        uint64 birthBlock,
        uint64 lastActionBlock,
        uint8 energy,
        uint8 health,
        uint256 traits,
        uint16 generation,
        uint256 parent1Id,
        uint256 parent2Id,
        ChronoidStatus status
    ) {
        Chronoid storage c = chronoids[_chronoidId];
        return (
            c.id,
            c.owner,
            c.birthBlock,
            c.lastActionBlock,
            c.energy,
            c.health,
            c.traits,
            c.generation,
            c.parent1Id,
            c.parent2Id,
            c.status
        );
    }

    /**
     * @notice Gets the total number of Chronoids ever created.
     * @return The total count.
     */
    function getTotalChronoids() external view returns (uint256) {
        return chronoidCount;
    }

    /**
     * @notice Gets the list of Chronoid IDs owned by an address.
     * @param _owner The owner's address.
     * @return An array of Chronoid IDs.
     */
    function getChronoidsByOwner(address _owner) external view returns (uint256[] memory) {
        return ownerToChronoids[_owner];
    }

    /**
     * @notice Gets the current global environment parameters.
     * @return A tuple containing the mutation factor, energy recovery rate, and essence boost factor.
     */
    function getEnvironmentParams() external view returns (uint16 mutationFactor, uint16 energyRecoveryRate, uint16 essenceBoostFactor) {
        return (environment.mutationFactor, environment.energyRecoveryRate, environment.essenceBoostFactor);
    }

     /**
     * @notice Checks if an address is a steward.
     * @param _addr The address to check.
     * @return True if the address is a steward or the owner, false otherwise.
     */
    function isSteward(address _addr) external view returns (bool) {
        return _stewards[_addr] || _addr == _owner;
    }

    /**
     * @notice Calculates potential energy recovery for a Chronoid since its last action block.
     * @dev This is a view function, it doesn't update the state. Actual recovery happens in `rest()`.
     * @param _chronoidId The ID of the Chronoid.
     * @return The estimated energy that could be recovered.
     */
    function calculateEnergyRecovery(uint256 _chronoidId) public view isValidChronoid(_chronoidId) returns (uint8) {
         if (chronoids[_chronoidId].energy == MAX_ENERGY) return 0;

         uint256 blocksElapsed = block.number - chronoids[_chronoidId].lastActionBlock;
         uint256 potentialRecovery = blocksElapsed * environment.energyRecoveryRate / 100; // Scale rate per block

         return uint8(Math.min(MAX_ENERGY - chronoids[_chronoidId].energy, potentialRecovery));
    }

    /**
     * @notice Calculates the estimated probability of a successful mutation attempt for a Chronoid.
     * @dev This is an estimation based on current state, actual outcome uses randomness.
     * @param _chronoidId The ID of the Chronoid.
     * @return The probability percentage (0-100).
     */
    function calculateMutationProbability(uint256 _chronoidId) external view isValidChronoid(_chronoidId) returns (uint8) {
         uint16 mutationAffinity = _getTrait(chronoids[_chronoidId].traits, TRAIT_MUTATION_AFFINITY_INDEX);
         // Formula mirrors attemptMutation chance calculation
         uint256 chanceOutOf1000 = (10 + (mutationAffinity / 10) + (environment.mutationFactor / 50)) * 10;
         return uint8(Math.min(100, chanceOutOf1000 / 10)); // Return percentage
    }

    /**
     * @notice Checks if two Chronoids meet basic requirements for reproduction.
     * @dev This is a view function, doesn't perform the reproduction.
     * Does NOT check ownership, only Chronoid state and energy.
     * @param _parent1Id The ID of the first potential parent.
     * @param _parent2Id The ID of the second potential parent.
     * @return True if they meet basic requirements, false otherwise.
     */
    function canReproduce(uint256 _parent1Id, uint256 _parent2Id) external view isValidChronoid(_parent1Id) isValidChronoid(_parent2Id) returns (bool) {
        if (_parent1Id == _parent2Id) return false;

        Chronoid storage p1 = chronoids[_parent1Id];
        Chronoid storage p2 = chronoids[_parent2Id];

        // Basic checks: Alive status, sufficient energy, generation check
        uint8 reproductionEnergyCost = MIN_ACTION_ENERGY * 3;
        if (p1.status != ChronoidStatus.Alive || p2.status != ChronoidStatus.Alive) return false;
        if (p1.energy < reproductionEnergyCost || p2.energy < reproductionEnergyCost) return false;
        // Example generation check: Within 2 generations of each other
        // if (!(p1.generation <= p2.generation + 2 && p2.generation <= p1.generation + 2)) return false;

        // Add other checks here if needed (e.g., compatible traits?)

        return true;
    }

     /**
     * @notice Gets a specific trait value for a Chronoid.
     * @param _chronoidId The ID of the Chronoid.
     * @param _traitIndex The index of the trait (0-NUM_TRAITS-1).
     * @return The value of the specified trait.
     */
    function getChronoidTrait(uint256 _chronoidId, uint8 _traitIndex) external view isValidChronoid(_chronoidId) returns (uint16) {
        require(_traitIndex < NUM_TRAITS, "Invalid trait index");
        return _getTrait(chronoids[_chronoidId].traits, _traitIndex);
    }

    /**
     * @notice Gets the owner of the contract.
     * @return The owner's address.
     */
    function owner() external view returns (address) {
        return _owner;
    }

     /**
     * @notice Gets the current creation fee in Wei.
     * @return The creation fee.
     */
    function getCreationFee() external view returns (uint256) {
        return creationFee;
    }

     /**
     * @notice Gets the current contract balance of collected fees.
     * @return The contract balance.
     */
    function getContractBalance() external view returns (uint256) {
        return contractBalance;
    }


    // --- Internal Helper Functions ---

    /**
     * @dev Generates initial traits for a new Chronoid based on a seed.
     * Traits are packed into a uint256.
     * @param _seed A unique seed for randomness.
     * @param _generation The generation of the chronoid (influences base trait values).
     * @return A uint256 containing the packed traits.
     */
    function _generateTraits(uint256 _seed, uint16 _generation) internal pure returns (uint256) {
        uint256 traits = 0;
        uint256 currentSeed = _seed;

        // Base trait value adjusted by generation
        uint16 baseTraitValue = uint16(50 + (_generation * 2)); // Example: higher generation starts with slightly better base traits

        for (uint8 i = 0; i < NUM_TRAITS; i++) {
            currentSeed = uint256(keccak256(abi.encodePacked(currentSeed, i))); // Evolve seed
            // Trait value = Base + random offset (e.g., +/- 20)
            uint16 traitValue = uint16(baseTraitValue + (currentSeed % 41) - 20); // Random value between base-20 and base+20
             // Ensure trait value is within reasonable bounds (e.g., 1-255)
            traitValue = uint16(Math.max(1, Math.min(255, traitValue)));
            traits |= (uint256(traitValue) << (i * TRAIT_BITS));
        }
        return traits;
    }

    /**
     * @dev Generates traits for a child Chronoid based on parents' traits and a seed.
     * @param _parent1Traits Packed traits of parent 1.
     * @param _parent2Traits Packed traits of parent 2.
     * @param _seed A unique seed for randomness.
     * @return A uint256 containing the packed traits for the child.
     */
    function _generateChildTraits(uint256 _parent1Traits, uint256 _parent2Traits, uint256 _seed) internal view returns (uint256) {
        uint256 childTraits = 0;
        uint256 currentSeed = _seed;

        for (uint8 i = 0; i < NUM_TRAITS; i++) {
            currentSeed = uint256(keccak256(abi.encodePacked(currentSeed, i))); // Evolve seed

            uint16 parent1Trait = _getTrait(_parent1Traits, i);
            uint16 parent2Trait = _getTrait(_parent2Traits, i);

            uint16 inheritedTrait;
            // 50% chance to inherit from parent 1, 50% from parent 2 (simplistic mix)
            if (currentSeed % 2 == 0) {
                inheritedTrait = parent1Trait;
            } else {
                inheritedTrait = parent2Trait;
            }

            // Add slight random variation around the inherited trait
             currentSeed = uint256(keccak256(abi.encodePacked(currentSeed, i, 1))); // Evolve seed again
             uint16 variedTrait = uint16(inheritedTrait + (currentSeed % 11) - 5); // +/- 5 variation
             variedTrait = uint16(Math.max(1, Math.min(255, variedTrait))); // Ensure bounds

            // Small chance of a mutation applying here (influenced by environment factor)
            currentSeed = uint256(keccak256(abi.encodePacked(currentSeed, i, 2))); // Evolve seed again
            if (currentSeed % 1000 < environment.mutationFactor) { // Chance influenced by env
                 currentSeed = uint256(keccak256(abi.encodePacked(currentSeed, i, 3))); // Evolve seed again
                uint16 mutationChange = uint16(10 + (currentSeed % 21)); // Add 10-30 points randomly
                if (currentSeed % 2 == 0) {
                    variedTrait = uint16(Math.min(255, variedTrait + mutationChange));
                } else {
                     variedTrait = uint16(Math.max(1, int(variedTrait) - int(mutationChange)));
                }
                variedTrait = uint16(Math.max(1, Math.min(255, variedTrait))); // Ensure bounds
            }

            childTraits |= (uint256(variedTrait) << (i * TRAIT_BITS));
        }
        return childTraits;
    }

     /**
     * @dev Applies mutation logic to a Chronoid's traits.
     * Changes a random trait value based on environment factor and seed.
     * @param _chronoidId The ID of the Chronoid mutating.
     * @param _seed A unique seed for randomness.
     * @return The new packed traits after mutation.
     */
    function _applyMutation(uint256 _chronoidId, uint256 _seed) internal view returns (uint256) {
        uint256 currentTraits = chronoids[_chronoidId].traits;
        uint256 newTraits = currentTraits;

        uint8 traitIndexToMutate = uint8(_seed % NUM_TRAITS);
        uint16 currentTraitValue = _getTrait(currentTraits, traitIndexToMutate);

        // Mutation magnitude influenced by environment factor
        uint16 mutationMagnitude = uint16(10 + (environment.mutationFactor / 20) + (_seed % 20)); // Base + env influence + random

        uint16 mutatedValue;
        if (_seed % 2 == 0) { // 50% chance to increase, 50% chance to decrease
            mutatedValue = uint16(Math.min(255, currentTraitValue + mutationMagnitude));
        } else {
            mutatedValue = uint16(Math.max(1, int(currentTraitValue) - int(mutationMagnitude)));
        }
        mutatedValue = uint16(Math.max(1, Math.min(255, mutatedValue))); // Ensure bounds

        newTraits = _setTrait(currentTraits, traitIndexToMutate, mutatedValue);

        return newTraits;
    }


    /**
     * @dev Calculates energy recovery based on elapsed blocks and environment rate.
     * @param _chronoidId The ID of the Chronoid.
     * @return The amount of energy to recover (uint8).
     */
    function _calculateEnergyRecovery(uint256 _chronoidId) internal view returns (uint8) {
        return calculateEnergyRecovery(_chronoidId); // Calls the public view helper
    }

     /**
     * @dev Handles the outcome logic for engagement between two Chronoids.
     * Affects health/energy based on traits and randomness.
     * @param _chronoid1Id The ID of the first Chronoid.
     * @param _chronoid2Id The ID of the second Chronoid.
     * @return A string describing the outcome.
     */
    function _handleEngagementLogic(uint256 _chronoid1Id, uint256 _chronoid2Id) internal view returns (string memory) {
         Chronoid storage c1 = chronoids[_chronoid1Id];
         Chronoid storage c2 = chronoids[_chronoid2Id];

         uint16 c1Strength = _getTrait(c1.traits, TRAIT_STRENGTH_INDEX);
         uint16 c2Strength = _getTrait(c2.traits, TRAIT_STRENGTH_INDEX);
         uint16 c1Resilience = _getTrait(c1.traits, TRAIT_RESILIENCE_INDEX);
         uint16 c2Resilience = _getTrait(c2.traits, TRAIT_RESILIENCE_INDEX);
         uint16 c1Agility = _getTrait(c1.traits, TRAIT_AGILITY_INDEX);
         uint16 c2Agility = _getTrait(c2.traits, TRAIT_AGILITY_INDEX);


         uint256 seed = _generateActionSeed(_chronoid1Id) ^ _generateActionSeed(_chronoid2Id); // Combine seeds

         // Simple combat simulation: compare effective stats (Strength vs Resilience/Agility)
         int256 c1Score = int256(c1Strength) - int256(c2Resilience) + int256(c1Agility) - int256(c2Agility) + int256(seed % 50) - 25; // Add random element
         int256 c2Score = int256(c2Strength) - int256(c1Resilience) + int256(c2Agility) - int256(c1Agility) + int256(seed % 50) - 25; // Add random element

         int256 outcomeDiff = c1Score - c2Score;

         string memory outcome;

         if (outcomeDiff > 20) { // C1 wins significantly
             int8 healthLossC2 = int8(Math.min(int256(c2.health), outcomeDiff / 5)); // C2 loses health
             c2.health = uint8(Math.max(1, int(c2.health) - healthLossC2));
             c1.health = uint8(Math.min(MAX_HEALTH, c1.health + uint8(healthLossC2 / 2))); // C1 gains some health/experience
             outcome = "Chronoid 1 dominated Chronoid 2.";
         } else if (outcomeDiff < -20) { // C2 wins significantly
             int8 healthLossC1 = int8(Math.min(int256(c1.health), -outcomeDiff / 5)); // C1 loses health
             c1.health = uint8(Math.max(1, int(c1.health) - healthLossC1));
             c2.health = uint8(Math.min(MAX_HEALTH, c2.health + uint8(healthLossC1 / 2))); // C2 gains some health/experience
             outcome = "Chronoid 2 dominated Chronoid 1.";
         } else if (outcomeDiff > 0) { // C1 wins slightly
             int8 healthLossC2 = int8(Math.min(int256(c2.health), 3)); // Small loss for C2
             c2.health = uint8(Math.max(1, int(c2.health) - healthLossC2));
             c1.health = uint8(Math.min(MAX_HEALTH, c1.health + 1)); // Small gain for C1
             outcome = "Chronoid 1 edged out Chronoid 2.";
         } else if (outcomeDiff < 0) { // C2 wins slightly
              int8 healthLossC1 = int8(Math.min(int256(c1.health), 3)); // Small loss for C1
             c1.health = uint8(Math.max(1, int(c1.health) - healthLossC1));
             c2.health = uint8(Math.min(MAX_HEALTH, c2.health + 1)); // Small gain for C2
             outcome = "Chronoid 2 edged out Chronoid 1.";
         } else { // Draw or negligible outcome
             outcome = "Engagement was a stalemate.";
         }

         return outcome;
    }

     /**
     * @dev Deducts energy from a Chronoid and updates last action block.
     * @param _chronoidId The ID of the Chronoid.
     * @param _amount The amount of energy to deduct.
     */
    function _deductEnergy(uint256 _chronoidId, uint8 _amount) internal {
        // Ensure energy doesn't go below zero (should be handled by requireEnergy caller)
        chronoids[_chronoidId].energy = uint8(Math.max(0, int(chronoids[_chronoidId].energy) - int(_amount)));
        chronoids[_chronoidId].lastActionBlock = uint64(block.number);
    }

     /**
     * @dev Checks a Chronoid's health and updates status if necessary (e.g., to Injured).
     * @param _chronoidId The ID of the Chronoid.
     */
    function _checkHealthStatus(uint256 _chronoidId) internal {
        Chronoid storage c = chronoids[_chronoidId];
        if (c.health == 0 && c.status != ChronoidStatus.Dormant) { // If health drops to 0, become Dormant (not dead, just inactive)
            c.status = ChronoidStatus.Dormant;
            // Could add logic here for permanent death or requiring special action to revive
        } else if (c.health < MAX_HEALTH / 4 && c.status == ChronoidStatus.Alive) { // If health is low, become Injured
             c.status = ChronoidStatus.Injured;
        } else if (c.health >= MAX_HEALTH / 2 && (c.status == ChronoidStatus.Injured || c.status == ChronoidStatus.Dormant)) {
            // If health recovers above threshold, and wasn't mutating, return to Alive
            if (c.status != ChronoidStatus.Mutating) {
                 c.status = ChronoidStatus.Alive;
            }
        }
         // If energy hits 0, also become Dormant
         if (c.energy == 0 && c.status == ChronoidStatus.Alive) {
             c.status = ChronoidStatus.Dormant;
         } else if (c.energy > 0 && c.status == ChronoidStatus.Dormant && c.health > 0) {
             // If energy/health recovers and was just dormant from energy/health loss, return to Alive
              c.status = ChronoidStatus.Alive;
         }
    }

    /**
     * @dev Internal function to transfer Chronoid ownership and update owner arrays.
     * @param _from The address transferring the Chronoid.
     * @param _to The address receiving the Chronoid.
     * @param _chronoidId The ID of the Chronoid.
     */
    function _transferChronoidInternal(address _from, address _to, uint256 _chronoidId) internal {
         chronoids[_chronoidId].owner = _to;
         _removeChronoidFromOwner(_from, _chronoidId);
         _addChronoidToOwner(_to, _chronoidId);
    }

    /**
     * @dev Adds a Chronoid ID to an owner's array.
     * @param _owner The owner's address.
     * @param _chronoidId The ID of the Chronoid.
     */
    function _addChronoidToOwner(address _owner, uint256 _chronoidId) internal {
        ownerToChronoids[_owner].push(_chronoidId);
        chronoidIndexInOwnerArray[_chronoidId] = ownerToChronoids[_owner].length - 1;
    }

    /**
     * @dev Removes a Chronoid ID from an owner's array efficiently.
     * Uses the swap-and-pop method.
     * @param _owner The owner's address.
     * @param _chronoidId The ID of the Chronoid.
     */
    function _removeChronoidFromOwner(address _owner, uint256 _chronoidId) internal {
        uint256 indexToRemove = chronoidIndexInOwnerArray[_chronoidId];
        uint256 lastChronoidIndex = ownerToChronoids[_owner].length - 1;

        if (indexToRemove != lastChronoidIndex) {
            // Move the last element into the place of the element to delete
            uint256 lastChronoidId = ownerToChronoids[_owner][lastChronoidIndex];
            ownerToChronoids[_owner][indexToRemove] = lastChronoidId;
            chronoidIndexInOwnerArray[lastChronoidId] = indexToRemove;
        }

        // Remove the last element
        ownerToChronoids[_owner].pop();
        delete chronoidIndexInOwnerArray[_chronoidId]; // Clean up the index mapping
    }


     /**
     * @dev Gets a specific trait value from the packed traits uint256.
     * @param _packedTraits The uint256 containing the packed traits.
     * @param _traitIndex The index of the trait (0-NUM_TRAITS-1).
     * @return The value of the specified trait.
     */
    function _getTrait(uint256 _packedTraits, uint8 _traitIndex) internal pure returns (uint16) {
        require(_traitIndex < NUM_TRAITS, "Invalid trait index");
        return uint16((_packedTraits >> (_traitIndex * TRAIT_BITS)) & TRAIT_MASK);
    }

    /**
     * @dev Sets a specific trait value within the packed traits uint256.
     * @param _packedTraits The current uint256 containing the packed traits.
     * @param _traitIndex The index of the trait (0-NUM_TRAITS-1).
     * @param _value The new value for the trait (0-255).
     * @return The new uint256 with the updated trait.
     */
    function _setTrait(uint256 _packedTraits, uint8 _traitIndex, uint16 _value) internal pure returns (uint256) {
        require(_traitIndex < NUM_TRAITS, "Invalid trait index");
        require(_value <= TRAIT_MASK, "Trait value out of bounds (max 255)");

        // Clear the bits for this trait
        uint256 clearedTraits = _packedTraits & ~(TRAIT_MASK << (_traitIndex * TRAIT_BITS));
        // Set the new value
        return clearedTraits | (uint256(_value) << (_traitIndex * TRAIT_BITS));
    }


    /**
     * @dev Generates a pseudo-random seed for Chronoid actions.
     * WARNING: Block-based randomness is predictable by miners.
     * This is suitable for demonstration/low-stakes simulation, NOT for high-stakes outcomes.
     * @param _chronoidId The ID of the Chronoid performing the action.
     * @return A pseudo-random uint256 seed.
     */
    function _generateActionSeed(uint256 _chronoidId) internal view returns (uint256) {
        // Combine various block-specific and Chronoid-specific data
        return uint256(keccak256(abi.encodePacked(
            block.timestamp,
            block.difficulty, // Deprecated in PoS, but still accessible
            block.number,
            tx.origin, // Use tx.origin for unique per-transaction variability
            msg.sender,
            _chronoidId,
            chronoids[_chronoidId].lastActionBlock,
            chronoids[_chronoidId].energy,
            chronoids[_chronoidId].health,
            chronoids[_chronoidId].traits
        )));
    }

    // --- Math Library (Simplified) ---
    // In a real contract, you might use OpenZeppelin's SafeMath/Math.
    // Custom implementation here to avoid external dependencies as requested.
    library Math {
        function min(uint256 a, uint256 b) internal pure returns (uint256) {
            return a < b ? a : b;
        }
        function max(uint256 a, uint256 b) internal pure returns (uint256) {
            return a > b ? a : b;
        }
        function min(uint8 a, uint8 b) internal pure returns (uint8) {
            return a < b ? a : b;
        }
        function max(uint8 a, uint8 b) internal pure returns (uint8) {
            return a > b ? a : b;
        }
         function min(uint16 a, uint16 b) internal pure returns (uint16) {
            return a < b ? a : b;
        }
        function max(uint16 a, uint16 b) internal pure returns (uint16) {
            return a > b ? a : b;
        }
         function max(int a, int b) internal pure returns (int) {
            return a > b ? a : b;
        }
    }
}
```