Okay, let's design a smart contract that manages dynamically evolving digital entities we'll call "Quantum State Shapers". This concept incorporates elements of collectible assets, state machines, time-based mechanics (decay), and potentially complex interaction/evolution rules, aiming for something less common than standard ERC-20/721 or DeFi primitives.

It will *not* be a standard ERC-721/1155, although shapers are unique entities. We'll manage ownership internally.

**Concept: Quantum State Shapers**

Users can create "Shapers". Shapers have various properties (affinity, energy, state, generation, dynamic attributes). Shapers can decay over time if not interacted with (losing energy). Users can interact with their shapers to boost energy and influence dynamic attributes. Shapers can evolve, potentially consuming one or more parent shapers and producing a new, higher-generation shaper with properties influenced by the parents and some element of randomness. The contract includes admin controls for global parameters and simulation of external "oracle-like" data that can influence mechanics.

---

**Outline and Function Summary**

**Contract Name:** QuantumStateShapers

**Purpose:**
A smart contract for managing unique, dynamically evolving digital entities ("Shapers") with properties that change based on time (decay), user interaction, and algorithmic evolution. Features include creation, interaction, time-based decay mechanics, single and paired evolution processes, and retrieval of state information. Includes administrative functions to control global parameters and simulate external influences.

**Key Concepts:**
*   **Shaper:** A unique digital entity with properties like state, energy, generation, affinity, and dynamic attributes.
*   **State:** Defines the current status of a Shaper (Active, Dormant, Decayed, Evolved).
*   **Energy:** A value that decays over time and is required for actions like interaction and evolution.
*   **Decay:** Shapers lose energy passively based on elapsed time since last interaction.
*   **Interaction:** User actions that can restore energy and influence dynamic attributes.
*   **Evolution:** A process where Shapers, under specific conditions (energy, cost), can transform into new, higher-generation Shapers, potentially consuming or altering parent Shapers.
*   **Affinity:** A fixed property influencing interaction and evolution outcomes.
*   **Dynamic Attribute:** A numerical property that changes based on interactions and evolution.
*   **Oracle-like Data:** A parameter simulating external environmental factors influencing mechanics.

**State Variables:**
*   `owner`: Contract administrator.
*   `paused`: Emergency pause flag.
*   `_shaperIdCounter`: Counter for unique Shaper IDs.
*   `idToShaper`: Mapping from Shaper ID to Shaper struct.
*   `ownerToShaperIds`: Mapping from owner address to list of owned Shaper IDs (Note: Gas intensive for large numbers of shapers).
*   `shaperCountByState`: Mapping to track counts per state.
*   `shaperCountByAffinity`: Mapping to track counts per affinity.
*   `shaperCountByGeneration`: Mapping to track counts per generation.
*   `decayRatePerSecond`: Global parameter for energy decay rate.
*   `evolutionCostSingle`: Cost (in Wei) for single Shaper evolution.
*   `evolutionCostPair`: Cost (in Wei) for paired Shaper evolution.
*   `primordialSparkCost`: Cost (in Wei) to create a new Shaper via Spark.
*   `oracleLikeData`: A uint simulating external data influencing mechanics.

**Enums:**
*   `State`: { Active, Dormant, Decayed, Evolved }
*   `Affinity`: { Fire, Water, Air, Earth, Void }

**Structs:**
*   `Shaper`: Represents a single Shaper entity. Contains properties like `owner`, `state`, `energyLevel`, `generation`, `affinity`, `lastInteractionTime`, `dynamicAttribute`, `metadataURI`.

**Events:**
*   `ShaperCreated(uint256 indexed shaperId, address indexed owner, Affinity affinity)`
*   `ShaperInteracted(uint256 indexed shaperId, address indexed user, uint256 newEnergy, uint256 newDynamicAttribute)`
*   `ShaperStateChanged(uint256 indexed shaperId, State oldState, State newState)`
*   `ShaperEvolved(uint256 indexed parentShaperId1, uint256 indexed parentShaperId2, uint256 indexed newShaperId, uint256 generation)` (parentShaperId2 can be 0 for single evolution)
*   `ParametersUpdated(string parameterName, uint256 oldValue, uint256 newValue)`
*   `FundsWithdrawn(address indexed recipient, uint256 amount)`
*   `ContractPaused(bool paused)`
*   `OracleLikeDataUpdated(uint256 newData)`
*   `MetadataURIUpdated(uint256 indexed shaperId, string newURI)`

**Modifiers:**
*   `onlyOwner`: Restricts function access to the contract owner.
*   `whenNotPaused`: Ensures the contract is not currently paused.
*   `whenPaused`: Ensures the contract *is* currently paused.
*   `onlyShaperOwner(uint256 _shaperId)`: Ensures the caller owns the specified Shaper.
*   `whenShaperActive(uint256 _shaperId)`: Ensures the specified Shaper is in the `Active` state.

**Functions (24 Total Public/External):**

**Admin Functions:**
1.  `setDecayRatePerSecond(uint256 _rate)`: Set the global energy decay rate.
2.  `setEvolutionCostSingle(uint256 _cost)`: Set the cost for single Shaper evolution.
3.  `setEvolutionCostPair(uint256 _cost)`: Set the cost for paired Shaper evolution.
4.  `setPrimordialSparkCost(uint256 _cost)`: Set the cost to create a new Shaper via Spark.
5.  `withdrawFunds()`: Withdraw accumulated contract balance (payable amounts) to the owner.
6.  `pauseContract()`: Pause core contract functionality (emergency).
7.  `unpauseContract()`: Unpause core contract functionality.
8.  `setOracleLikeData(uint256 _data)`: Set the simulation of external oracle data.

**Shaper Creation & Interaction Functions:**
9.  `primordialSpark()`: Create a new Shaper (payable). Initial properties determined algorithmically.
10. `interactWithSelf(uint256 _shaperId)`: Interact with one's own Shaper. Restores energy, modifies dynamic attribute. Applies decay first.
11. `interactWithOther(uint256 _shaperId1, uint256 _shaperId2)`: Interact between two owned Shapers. More complex energy/attribute effects based on affinities. Applies decay first to both.
12. `refreshState(uint256 _shaperId)`: Explicitly triggers decay calculation and state update for a Shaper without other interactions.

**Shaper Evolution Functions:**
13. `evolveShaperSingle(uint256 _shaperId)`: Attempt to evolve a single Shaper. Requires cost and sufficient energy. Creates a new Shaper and sets the original to `Evolved` or `Decayed`. Applies decay first.
14. `evolveShapersPair(uint256 _shaperId1, uint256 _shaperId2)`: Attempt to evolve two Shapers together. Requires cost and sufficient energy from both. Creates a new Shaper inheriting traits. Sets originals to `Evolved` or `Decayed`. Applies decay first to both.

**Shaper Management & State Change Functions:**
15. `updateShaperMetadataURI(uint256 _shaperId, string memory _uri)`: Update the metadata URI for a Shaper (owner only).
16. `setShaperDormant(uint256 _shaperId)`: Owner can set a Shaper to `Dormant` state, potentially pausing decay (logic needs implementation).
17. `reviveDormantShaper(uint256 _shaperId)`: Pay a cost to change a `Dormant` Shaper back to `Active`.

**Read/Getter Functions:**
18. `getShaperDetails(uint256 _shaperId)`: Get all details of a specific Shaper (Applies decay before returning details).
19. `getOwnerShaperIds(address _owner)`: Get a list of Shaper IDs owned by an address.
20. `getTotalSupply()`: Get the total number of Shapers ever created.
21. `getShaperCountByState(State _state)`: Get the count of Shapers in a specific state.
22. `getShaperCountByAffinity(Affinity _affinity)`: Get the count of Shapers with a specific affinity.
23. `getShaperCountByGeneration(uint256 _generation)`: Get the count of Shapers of a specific generation.
24. `getContractParameters()`: Get the current global contract parameters (costs, rates, oracle data).

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// Outline and Function Summary above the code section.

contract QuantumStateShapers {
    // --- State Variables ---
    address public owner;
    bool public paused;

    uint256 private _shaperIdCounter;

    // Mapping from Shaper ID to Shaper details
    mapping(uint256 => Shaper) public idToShaper;
    // Mapping from owner address to an array of Shaper IDs they own
    // WARNING: This can be gas-intensive for addresses owning many shapers.
    // In a real-world scenario, consider external indexing or paginated retrieval.
    mapping(address => uint256[]) public ownerToShaperIds;

    // Counters for various Shaper properties
    mapping(State => uint256) public shaperCountByState;
    mapping(Affinity => uint256) public shaperCountByAffinity;
    mapping(uint256 => uint256) public shaperCountByGeneration;

    // Global contract parameters (admin configurable)
    uint256 public decayRatePerSecond = 1; // Energy units lost per second
    uint256 public evolutionCostSingle = 0.01 ether;
    uint256 public evolutionCostPair = 0.02 ether;
    uint256 public primordialSparkCost = 0.005 ether;

    // Simulating external data influencing mechanics (set by admin)
    uint256 public oracleLikeData = 100; // Can influence decay, evolution chance, attributes etc.

    // --- Enums ---
    enum State { Active, Dormant, Decayed, Evolved }
    enum Affinity { Fire, Water, Air, Earth, Void }

    // --- Structs ---
    struct Shaper {
        uint256 id;
        address owner;
        State state;
        uint256 energyLevel; // Vitality, decays over time
        uint256 generation; // How many times it (or ancestors) evolved
        Affinity affinity; // Intrinsic property influencing interactions/evolution
        uint256 lastInteractionTime; // Timestamp for decay calculation
        uint256 dynamicAttribute; // A property that changes based on interactions/evolution
        string metadataURI; // Link to external metadata/art (like an NFT tokenURI)
    }

    // --- Events ---
    event ShaperCreated(uint256 indexed shaperId, address indexed owner, Affinity affinity);
    event ShaperInteracted(uint256 indexed shaperId, address indexed user, uint256 newEnergy, uint256 newDynamicAttribute);
    event ShaperStateChanged(uint256 indexed shaperId, State oldState, State newState);
    event ShaperEvolved(uint256 indexed parentShaperId1, uint256 indexed parentShaperId2, uint256 indexed newShaperId, uint256 generation); // parentShaperId2 can be 0 for single evolution
    event ParametersUpdated(string parameterName, uint256 oldValue, uint256 newValue);
    event FundsWithdrawn(address indexed recipient, uint256 amount);
    event ContractPaused(bool paused);
    event OracleLikeDataUpdated(uint256 newData);
    event MetadataURIUpdated(uint256 indexed shaperId, string newURI);

    // --- Modifiers ---
    modifier onlyOwner() {
        require(msg.sender == owner, "Not contract owner");
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

    modifier onlyShaperOwner(uint256 _shaperId) {
        require(_exists(_shaperId), "Shaper does not exist");
        require(idToShaper[_shaperId].owner == msg.sender, "Not shaper owner");
        _;
    }

    modifier whenShaperActive(uint256 _shaperId) {
        require(_exists(_shaperId), "Shaper does not exist");
        require(idToShaper[_shaperId].state == State.Active, "Shaper is not Active");
        _;
    }

    // --- Constructor ---
    constructor() {
        owner = msg.sender;
        _shaperIdCounter = 0; // Shaper IDs start from 1
        paused = false;
    }

    // --- Admin Functions (8) ---

    /**
     * @notice Sets the global energy decay rate per second.
     * @param _rate The new decay rate (energy units per second).
     */
    function setDecayRatePerSecond(uint256 _rate) external onlyOwner {
        uint256 oldRate = decayRatePerSecond;
        decayRatePerSecond = _rate;
        emit ParametersUpdated("decayRatePerSecond", oldRate, _rate);
    }

    /**
     * @notice Sets the cost for single Shaper evolution.
     * @param _cost The new cost in Wei.
     */
    function setEvolutionCostSingle(uint256 _cost) external onlyOwner {
        uint256 oldCost = evolutionCostSingle;
        evolutionCostSingle = _cost;
        emit ParametersUpdated("evolutionCostSingle", oldCost, _cost);
    }

    /**
     * @notice Sets the cost for paired Shaper evolution.
     * @param _cost The new cost in Wei.
     */
    function setEvolutionCostPair(uint256 _cost) external onlyOwner {
        uint256 oldCost = evolutionCostPair;
        evolutionCostPair = _cost;
        emit ParametersUpdated("evolutionCostPair", oldCost, _cost);
    }

    /**
     * @notice Sets the cost to create a new Shaper via Primordial Spark.
     * @param _cost The new cost in Wei.
     */
    function setPrimordialSparkCost(uint256 _cost) external onlyOwner {
        uint256 oldCost = primordialSparkCost;
        primordialSparkCost = _cost;
        emit ParametersUpdated("primordialSparkCost", oldCost, _cost);
    }

    /**
     * @notice Allows the owner to withdraw the contract's balance.
     */
    function withdrawFunds() external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No funds to withdraw");
        (bool success, ) = owner.call{value: balance}("");
        require(success, "Withdrawal failed");
        emit FundsWithdrawn(owner, balance);
    }

    /**
     * @notice Pauses core contract functionality (emergency).
     */
    function pauseContract() external onlyOwner whenNotPaused {
        paused = true;
        emit ContractPaused(true);
    }

    /**
     * @notice Unpauses core contract functionality.
     */
    function unpauseContract() external onlyOwner whenPaused {
        paused = false;
        emit ContractPaused(false);
    }

    /**
     * @notice Sets the simulated external oracle-like data.
     * @param _data The new oracle data value.
     */
    function setOracleLikeData(uint256 _data) external onlyOwner {
        uint256 oldData = oracleLikeData;
        oracleLikeData = _data;
        emit OracleLikeDataUpdated(_data);
    }

    // --- Shaper Creation & Interaction Functions (4) ---

    /**
     * @notice Creates a new Shaper via a "Primordial Spark". Requires payment.
     */
    function primordialSpark() external payable whenNotPaused {
        require(msg.value >= primordialSparkCost, "Insufficient payment for spark");

        _shaperIdCounter++;
        uint256 newId = _shaperIdCounter;

        // Initial attributes based on current state and some pseudo-randomness
        uint256 entropy = uint256(keccak256(abi.encodePacked(block.timestamp, msg.sender, newId, block.difficulty, oracleLikeData)));
        Affinity initialAffinity = Affinity(entropy % 5); // Assign a random-ish affinity
        uint256 initialEnergy = 1000 + (entropy % 500); // Starting energy
        uint256 initialDynamicAttribute = entropy % 256; // Starting attribute value

        _mint(newId, msg.sender, initialEnergy, 0, initialAffinity, initialDynamicAttribute, "");

        // Refund excess payment if any
        if (msg.value > primordialSparkCost) {
            (bool success, ) = payable(msg.sender).call{value: msg.value - primordialSparkCost}("");
            require(success, "Refund failed");
        }
    }

    /**
     * @notice Allows a Shaper owner to interact with their own Shaper.
     * Applies decay, restores energy, modifies dynamic attribute.
     * @param _shaperId The ID of the Shaper to interact with.
     */
    function interactWithSelf(uint256 _shaperId) external onlyShaperOwner(_shaperId) whenShaperActive(_shaperId) whenNotPaused {
        _applyDecay(_shaperId); // Apply decay before interaction effects

        Shaper storage shaper = idToShaper[_shaperId];

        // Interaction effects: Boost energy, change attribute
        uint256 energyBoost = 50 + (shaper.generation * 5) + (oracleLikeData % 20);
        shaper.energyLevel = shaper.energyLevel + energyBoost; // Cap energy? Max 2000?
        if (shaper.energyLevel > 2000) shaper.energyLevel = 2000;

        uint256 attributeChange = (shaper.energyLevel % 10) + (uint256(shaper.affinity) * 3) + (oracleLikeData % 10);
        if (block.timestamp % 2 == 0) { // Random-ish increase/decrease
             shaper.dynamicAttribute = shaper.dynamicAttribute + attributeChange; // Cap? Max 500?
             if (shaper.dynamicAttribute > 500) shaper.dynamicAttribute = 500;
        } else {
             if (shaper.dynamicAttribute > attributeChange) shaper.dynamicAttribute = shaper.dynamicAttribute - attributeChange;
             else shaper.dynamicAttribute = 0;
        }


        shaper.lastInteractionTime = block.timestamp;

        emit ShaperInteracted(_shaperId, msg.sender, shaper.energyLevel, shaper.dynamicAttribute);
    }

    /**
     * @notice Allows a Shaper owner to interact with two of their own Shapers.
     * Applies decay, potential for more complex energy/attribute effects based on affinities.
     * @param _shaperId1 The ID of the first Shaper.
     * @param _shaperId2 The ID of the second Shaper.
     */
    function interactWithOther(uint256 _shaperId1, uint256 _shaperId2) external
        onlyShaperOwner(_shaperId1)
        onlyShaperOwner(_shaperId2)
        whenShaperActive(_shaperId1)
        whenShaperActive(_shaperId2)
        whenNotPaused
    {
        require(_shaperId1 != _shaperId2, "Cannot interact two identical shapers this way");

        _applyDecay(_shaperId1); // Apply decay first
        _applyDecay(_shaperId2); // Apply decay first

        Shaper storage shaper1 = idToShaper[_shaperId1];
        Shaper storage shaper2 = idToShaper[_shaperId2];

        // Complex interaction logic based on affinities and other properties
        uint256 energyBoost1 = 30 + (uint256(shaper2.affinity) * 5) + (oracleLikeData % 15);
        uint256 energyBoost2 = 30 + (uint256(shaper1.affinity) * 5) + (oracleLikeData % 15);

        uint256 attributeChange1 = (shaper2.dynamicAttribute / 10) + (shaper1.energyLevel % 10) + (oracleLikeData % 10);
        uint256 attributeChange2 = (shaper1.dynamicAttribute / 10) + (shaper2.energyLevel % 10) + (oracleLikeData % 10);

        // Example: Complementary affinities boost each other more
        if ((shaper1.affinity == Affinity.Fire && shaper2.affinity == Affinity.Water) ||
            (shaper1.affinity == Affinity.Water && shaper2.affinity == Affinity.Fire) ||
            (shaper1.affinity == Affinity.Air && shaper2.affinity == Affinity.Earth) ||
            (shaper1.affinity == Affinity.Earth && shaper2.affinity == Affinity.Air)) {
            energyBoost1 = energyBoost1 + 50;
            energyBoost2 = energyBoost2 + 50;
            attributeChange1 = attributeChange1 + 20;
            attributeChange2 = attributeChange2 + 20;
        }

        shaper1.energyLevel = shaper1.energyLevel + energyBoost1;
        shaper2.energyLevel = shaper2.energyLevel + energyBoost2;
        if (shaper1.energyLevel > 2000) shaper1.energyLevel = 2000; // Cap energy
        if (shaper2.energyLevel > 2000) shaper2.energyLevel = 2000;

        // Apply attribute changes with random direction
        if (block.timestamp % 3 == 0) { // Random-ish interaction direction
             shaper1.dynamicAttribute = shaper1.dynamicAttribute + attributeChange1;
             shaper2.dynamicAttribute = shaper2.dynamicAttribute + attributeChange2;
        } else if (block.timestamp % 3 == 1) {
             if (shaper1.dynamicAttribute > attributeChange1) shaper1.dynamicAttribute = shaper1.dynamicAttribute - attributeChange1;
             else shaper1.dynamicAttribute = 0;
             shaper2.dynamicAttribute = shaper2.dynamicAttribute + attributeChange2;
        } else {
             shaper1.dynamicAttribute = shaper1.dynamicAttribute + attributeChange1;
              if (shaper2.dynamicAttribute > attributeChange2) shaper2.dynamicAttribute = shaper2.dynamicAttribute - attributeChange2;
             else shaper2.dynamicAttribute = 0;
        }

        if (shaper1.dynamicAttribute > 500) shaper1.dynamicAttribute = 500; // Cap attribute
        if (shaper2.dynamicAttribute > 500) shaper2.dynamicAttribute = 500;


        shaper1.lastInteractionTime = block.timestamp;
        shaper2.lastInteractionTime = block.timestamp;

        emit ShaperInteracted(_shaperId1, msg.sender, shaper1.energyLevel, shaper1.dynamicAttribute);
        emit ShaperInteracted(_shaperId2, msg.sender, shaper2.energyLevel, shaper2.dynamicAttribute);
    }

     /**
     * @notice Explicitly applies decay to a Shaper and updates its state if necessary.
     * Useful for refreshing state without another interaction.
     * @param _shaperId The ID of the Shaper to refresh.
     */
    function refreshState(uint256 _shaperId) external onlyShaperOwner(_shaperId) whenNotPaused {
        _applyDecay(_shaperId);
        // _applyDecay includes the state change logic (to Decayed/Dormant)
    }

    // --- Shaper Evolution Functions (2) ---

    /**
     * @notice Attempts to evolve a single Shaper into a new one.
     * Requires payment and sufficient energy from the parent.
     * Consumes energy, creates a new Shaper, sets parent state to Evolved.
     * @param _shaperId The ID of the Shaper to evolve.
     */
    function evolveShaperSingle(uint256 _shaperId) external payable
        onlyShaperOwner(_shaperId)
        whenShaperActive(_shaperId)
        whenNotPaused
    {
        _applyDecay(_shaperId); // Apply decay first

        Shaper storage parentShaper = idToShaper[_shaperId];
        require(msg.value >= evolutionCostSingle, "Insufficient payment for evolution");
        require(parentShaper.energyLevel >= 500, "Parent Shaper requires at least 500 energy to evolve"); // Example energy requirement

        parentShaper.energyLevel = parentShaper.energyLevel - 500; // Consume energy

        _shaperIdCounter++;
        uint256 newId = _shaperIdCounter;

        // Generate new shaper attributes based on parent, randomness, oracle data
        (Affinity newAffinity, uint256 initialEnergy, uint256 initialDynamicAttribute, string memory newMetadataURI) =
            _generateNewShaperAttributes(parentShaper.id, 0); // 0 indicates single evolution

        _mint(newId, msg.sender, initialEnergy, parentShaper.generation + 1, newAffinity, initialDynamicAttribute, newMetadataURI);

        // Change parent state
        _updateShaperState(_shaperId, State.Evolved);

        // Refund excess payment if any
        if (msg.value > evolutionCostSingle) {
            (bool success, ) = payable(msg.sender).call{value: msg.value - evolutionCostSingle}("");
            require(success, "Refund failed");
        }

        emit ShaperEvolved(_shaperId, 0, newId, parentShaper.generation + 1);
    }

    /**
     * @notice Attempts to evolve two Shapers together into a new one.
     * Requires payment and sufficient energy from both parents.
     * Consumes energy from both, creates a new Shaper, sets parent states to Evolved.
     * @param _shaperId1 The ID of the first Shaper.
     * @param _shaperId2 The ID of the second Shaper.
     */
    function evolveShapersPair(uint256 _shaperId1, uint256 _shaperId2) external payable
        onlyShaperOwner(_shaperId1)
        onlyShaperOwner(_shaperId2)
        whenShaperActive(_shaperId1)
        whenShaperActive(_shaperId2)
        whenNotPaused
    {
        require(_shaperId1 != _shaperId2, "Cannot evolve two identical shapers together");
        require(msg.value >= evolutionCostPair, "Insufficient payment for paired evolution");

        _applyDecay(_shaperId1); // Apply decay first
        _applyDecay(_shaperId2); // Apply decay first

        Shaper storage parentShaper1 = idToShaper[_shaperId1];
        Shaper storage parentShaper2 = idToShaper[_shaperId2];

        // Example energy requirement for paired evolution
        require(parentShaper1.energyLevel >= 400 && parentShaper2.energyLevel >= 400, "Both parent Shapers require at least 400 energy to evolve");

        // Consume energy from both
        parentShaper1.energyLevel = parentShaper1.energyLevel - 400;
        parentShaper2.energyLevel = parentShaper2.energyLevel - 400;


        _shaperIdCounter++;
        uint256 newId = _shaperIdCounter;

        // Generate new shaper attributes based on parents, randomness, oracle data
        (Affinity newAffinity, uint256 initialEnergy, uint256 initialDynamicAttribute, string memory newMetadataURI) =
             _generateNewShaperAttributes(parentShaper1.id, parentShaper2.id);

        // New generation is max of parents + 1
        uint256 newGeneration = (parentShaper1.generation > parentShaper2.generation ? parentShaper1.generation : parentShaper2.generation) + 1;

        _mint(newId, msg.sender, initialEnergy, newGeneration, newAffinity, initialDynamicAttribute, newMetadataURI);

        // Change parent states
        _updateShaperState(_shaperId1, State.Evolved);
        _updateShaperState(_shaperId2, State.Evolved);

        // Refund excess payment if any
        if (msg.value > evolutionCostPair) {
            (bool success, ) = payable(msg.sender).call{value: msg.value - evolutionCostPair}("");
            require(success, "Refund failed");
        }

        emit ShaperEvolved(_shaperId1, _shaperId2, newId, newGeneration);
    }

    // --- Shaper Management & State Change Functions (3) ---

    /**
     * @notice Allows the Shaper owner to update the metadata URI.
     * @param _shaperId The ID of the Shaper.
     * @param _uri The new metadata URI.
     */
    function updateShaperMetadataURI(uint256 _shaperId, string memory _uri) external onlyShaperOwner(_shaperId) whenNotPaused {
        require(_exists(_shaperId), "Shaper does not exist");
        idToShaper[_shaperId].metadataURI = _uri;
        emit MetadataURIUpdated(_shaperId, _uri);
    }

    /**
     * @notice Allows the Shaper owner to manually set a Shaper to Dormant state.
     * Shapers in Dormant state might have different decay rules or interactions (logic for this needs to be applied in _applyDecay etc.).
     * @param _shaperId The ID of the Shaper to set to Dormant.
     */
    function setShaperDormant(uint256 _shaperId) external onlyShaperOwner(_shaperId) whenShaperActive(_shaperId) whenNotPaused {
        _updateShaperState(_shaperId, State.Dormant);
    }

    /**
     * @notice Allows the owner to revive a Dormant Shaper back to Active state. Requires payment.
     * @param _shaperId The ID of the Dormant Shaper to revive.
     */
    function reviveDormantShaper(uint256 _shaperId) external payable onlyShaperOwner(_shaperId) whenNotPaused {
        require(_exists(_shaperId), "Shaper does not exist");
        require(idToShaper[_shaperId].state == State.Dormant, "Shaper is not Dormant");
        require(msg.value >= primordialSparkCost, "Insufficient payment to revive"); // Using Spark cost as revival cost

        _updateShaperState(_shaperId, State.Active);
        idToShaper[_shaperId].lastInteractionTime = block.timestamp; // Reset interaction time on revival
        // Could add an energy boost on revival: idToShaper[_shaperId].energyLevel += 200;

        // Refund excess payment
         if (msg.value > primordialSparkCost) {
            (bool success, ) = payable(msg.sender).call{value: msg.value - primordialSparkCost}("");
            require(success, "Refund failed");
        }
    }

    // --- Read/Getter Functions (7) ---

    /**
     * @notice Gets all details for a specific Shaper. Applies decay before returning.
     * @param _shaperId The ID of the Shaper.
     * @return A tuple containing all Shaper properties.
     */
    function getShaperDetails(uint256 _shaperId) external whenNotPaused view returns (
        uint256 id,
        address owner,
        State state,
        uint256 energyLevel,
        uint256 generation,
        Affinity affinity,
        uint256 lastInteractionTime,
        uint256 dynamicAttribute,
        string memory metadataURI
    ) {
        require(_exists(_shaperId), "Shaper does not exist");
        Shaper storage shaper = idToShaper[_shaperId];

        // Note: Decay is not applied in a pure view function.
        // A real-world implementation might require an external call to apply decay
        // or return details WITH decay applied based on current block.timestamp.
        // For this example, we'll return the stored value and note this limitation.
        // To return decay-applied state, this would need to be a non-view function
        // or use a state snapshot mechanism. Let's simulate applying decay for the return value only:
        uint256 currentEnergy = shaper.energyLevel;
        State currentState = shaper.state;
        if (shaper.state == State.Active) {
             uint256 timeElapsed = block.timestamp - shaper.lastInteractionTime;
             uint256 potentialDecay = timeElapsed * decayRatePerSecond;
             if (currentEnergy > potentialDecay) {
                 currentEnergy -= potentialDecay;
             } else {
                 currentEnergy = 0;
                 // Simulate state change for the view, but don't save it
                 currentState = State.Decayed;
             }
        }
         if (shaper.state == State.Dormant) {
             // Example: Dormant decays slower or not at all
             // uint256 timeElapsed = block.timestamp - shaper.lastInteractionTime;
             // uint256 potentialDecay = (timeElapsed * decayRatePerSecond) / 2; // Half decay rate
             // if (currentEnergy > potentialDecay) {
             //     currentEnergy -= potentialDecay;
             // } else {
             //     currentEnergy = 0;
             //     currentState = State.Decayed;
             // }
             // Or simply no decay in dormant: currentEnergy = shaper.energyLevel;
              currentEnergy = shaper.energyLevel; // Assuming Dormant state halts decay for this demo
         }


        return (
            shaper.id,
            shaper.owner,
            currentState, // Return calculated state for the view
            currentEnergy, // Return calculated energy for the view
            shaper.generation,
            shaper.affinity,
            shaper.lastInteractionTime,
            shaper.dynamicAttribute,
            shaper.metadataURI
        );
    }

    /**
     * @notice Gets the list of Shaper IDs owned by an address.
     * WARNING: This can be gas-intensive for addresses owning many shapers.
     * @param _owner The address of the owner.
     * @return An array of Shaper IDs.
     */
    function getOwnerShaperIds(address _owner) external view returns (uint256[] memory) {
        return ownerToShaperIds[_owner];
    }

    /**
     * @notice Gets the total number of Shapers ever created.
     * @return The total supply count.
     */
    function getTotalSupply() external view returns (uint256) {
        return _shaperIdCounter;
    }

    /**
     * @notice Gets the count of Shapers in a specific state.
     * @param _state The state to count.
     * @return The number of Shapers in that state.
     */
    function getShaperCountByState(State _state) external view returns (uint256) {
        return shaperCountByState[_state];
    }

    /**
     * @notice Gets the count of Shapers with a specific affinity.
     * @param _affinity The affinity to count.
     * @return The number of Shapers with that affinity.
     */
    function getShaperCountByAffinity(Affinity _affinity) external view returns (uint256) {
        return shaperCountByAffinity[_affinity];
    }

    /**
     * @notice Gets the count of Shapers of a specific generation.
     * @param _generation The generation to count.
     * @return The number of Shapers of that generation.
     */
    function getShaperCountByGeneration(uint256 _generation) external view returns (uint256) {
        return shaperCountByGeneration[_generation];
    }

    /**
     * @notice Gets the current global contract parameters.
     * @return A tuple containing various parameter values.
     */
    function getContractParameters() external view returns (
        uint256 currentDecayRatePerSecond,
        uint256 currentEvolutionCostSingle,
        uint256 currentEvolutionCostPair,
        uint256 currentPrimordialSparkCost,
        uint256 currentOracleLikeData
    ) {
        return (
            decayRatePerSecond,
            evolutionCostSingle,
            evolutionCostPair,
            primordialSparkCost,
            oracleLikeData
        );
    }


    // --- Internal Helper Functions ---

    /**
     * @dev Mints a new Shaper with specified properties.
     * @param _id The unique ID for the new Shaper.
     * @param _owner The address that will own the new Shaper.
     * @param _energyLevel Initial energy level.
     * @param _generation Generation level.
     * @param _affinity Affinity of the Shaper.
     * @param _dynamicAttribute Initial dynamic attribute value.
     * @param _metadataURI Metadata URI.
     */
    function _mint(
        uint256 _id,
        address _owner,
        uint256 _energyLevel,
        uint256 _generation,
        Affinity _affinity,
        uint256 _dynamicAttribute,
        string memory _metadataURI
    ) internal {
        require(!_exists(_id), "Shaper ID already exists");
        require(_owner != address(0), "Cannot mint to zero address");

        idToShaper[_id] = Shaper({
            id: _id,
            owner: _owner,
            state: State.Active, // New shapers are Active
            energyLevel: _energyLevel,
            generation: _generation,
            affinity: _affinity,
            lastInteractionTime: block.timestamp,
            dynamicAttribute: _dynamicAttribute,
            metadataURI: _metadataURI
        });

        ownerToShaperIds[_owner].push(_id);

        shaperCountByState[State.Active]++;
        shaperCountByAffinity[_affinity]++;
        shaperCountByGeneration[_generation]++;

        emit ShaperCreated(_id, _owner, _affinity);
    }

    /**
     * @dev Checks if a Shaper ID exists.
     * @param _shaperId The ID to check.
     * @return True if the Shaper exists, false otherwise.
     */
    function _exists(uint256 _shaperId) internal view returns (bool) {
        // Shaper IDs start from 1. ID 0 is invalid.
        // Check mapping directly is okay, but checking counter is faster if ID is within range.
        // A safer check: if idToShaper[_shaperId].id == _shaperId and _shaperId > 0.
        // Given we increment _shaperIdCounter from 0, any ID > 0 and <= counter exists.
        return (_shaperId > 0 && _shaperId <= _shaperIdCounter);
    }

    /**
     * @dev Applies decay to a Shaper based on time elapsed since last interaction.
     * Can change the Shaper's state to Decayed if energy reaches zero.
     * @param _shaperId The ID of the Shaper to apply decay to.
     */
    function _applyDecay(uint256 _shaperId) internal {
        Shaper storage shaper = idToShaper[_shaperId];

        // Decay only applies to Active shapers
        if (shaper.state != State.Active) {
            return;
        }

        uint256 timeElapsed = block.timestamp - shaper.lastInteractionTime;
        uint256 decayAmount = timeElapsed * decayRatePerSecond;

        // Influence decay amount based on oracle-like data (example: higher oracle means faster decay)
        decayAmount = decayAmount * (oracleLikeData / 100); // If oracleLikeData is 200, decay is doubled

        if (shaper.energyLevel > decayAmount) {
            shaper.energyLevel -= decayAmount;
        } else {
            shaper.energyLevel = 0;
            // Change state to Decayed
            _updateShaperState(_shaperId, State.Decayed);
        }

        // Update last interaction time even if only decay happened,
        // so next decay calculation starts from now.
        shaper.lastInteractionTime = block.timestamp;
    }

    /**
     * @dev Updates the state of a Shaper and manages state counters.
     * @param _shaperId The ID of the Shaper.
     * @param _newState The new state to set.
     */
    function _updateShaperState(uint256 _shaperId, State _newState) internal {
        Shaper storage shaper = idToShaper[_shaperId];
        State oldState = shaper.state;

        if (oldState != _newState) {
            // Update counters
            if (shaperCountByState[oldState] > 0) {
                shaperCountByState[oldState]--;
            }
            shaperCountByState[_newState]++;

            // Update state
            shaper.state = _newState;

            emit ShaperStateChanged(_shaperId, oldState, _newState);
        }
    }

    /**
     * @dev Generates attributes for a new Shaper during creation or evolution.
     * Attributes are influenced by parent(s), randomness, and oracle data.
     * @param _parentShaperId1 The ID of the first parent (or the only parent for single evo).
     * @param _parentShaperId2 The ID of the second parent (0 for single evo).
     * @return A tuple containing the new Shaper's affinity, energy, dynamic attribute, and metadata URI.
     */
    function _generateNewShaperAttributes(uint256 _parentShaperId1, uint256 _parentShaperId2)
        internal
        view
        returns (Affinity newAffinity, uint256 initialEnergy, uint256 initialDynamicAttribute, string memory newMetadataURI)
    {
        uint256 entropy;
        if (_parentShaperId2 == 0) { // Single evolution
             Shaper storage parent1 = idToShaper[_parentShaperId1];
             entropy = uint256(keccak256(abi.encodePacked(block.timestamp, parent1.id, parent1.energyLevel, parent1.dynamicAttribute, block.number, block.difficulty, oracleLikeData)));

             // New affinity might be same as parent or a random variation
             newAffinity = parent1.affinity;
             if (entropy % 10 < 2) { // 20% chance to mutate affinity
                 newAffinity = Affinity(entropy % 5);
             }

             // Energy based on parent energy + randomness
             initialEnergy = (parent1.energyLevel / 2) + (entropy % 300) + (oracleLikeData % 50);
             if (initialEnergy > 1500) initialEnergy = 1500; // Cap

             // Attribute based on parent attribute + randomness
             initialDynamicAttribute = (parent1.dynamicAttribute / 2) + (entropy % 100) + (oracleLikeData % 30);
              if (initialDynamicAttribute > 400) initialDynamicAttribute = 400; // Cap

             newMetadataURI = string(abi.encodePacked(parent1.metadataURI, "/gen", Strings.toString(parent1.generation + 1))); // Append generation to URI

        } else { // Paired evolution
             Shaper storage parent1 = idToShaper[_parentShaperId1];
             Shaper storage parent2 = idToShaper[_parentShaperId2];
             entropy = uint256(keccak256(abi.encodePacked(block.timestamp, parent1.id, parent2.id, parent1.dynamicAttribute, parent2.dynamicAttribute, block.number, block.difficulty, oracleLikeData)));

             // New affinity based on parents' affinities or a combination/random
             if (parent1.affinity == parent2.affinity) {
                 newAffinity = parent1.affinity; // Same affinity reinforces
                 if (entropy % 10 < 1) { // Small chance of mutation
                    newAffinity = Affinity(entropy % 5);
                 }
             } else {
                 // Example: Fire + Water = Void? Or just random? Let's use a mix + randomness
                 uint256 combinedAffinityValue = (uint256(parent1.affinity) + uint256(parent2.affinity)) % 5;
                 newAffinity = Affinity((combinedAffinityValue + (entropy % 5)) % 5); // Mix and random variation
             }

             // Energy based on average parent energy + randomness
             initialEnergy = ((parent1.energyLevel + parent2.energyLevel) / 3) + (entropy % 400) + (oracleLikeData % 60);
              if (initialEnergy > 1800) initialEnergy = 1800; // Cap

             // Attribute based on combined parent attributes + randomness
             initialDynamicAttribute = ((parent1.dynamicAttribute + parent2.dynamicAttribute) / 3) + (entropy % 150) + (oracleLikeData % 40);
              if (initialDynamicAttribute > 450) initialDynamicAttribute = 450; // Cap

             // Combine metadata URIs or create a new pattern
             newMetadataURI = string(abi.encodePacked(parent1.metadataURI, "_", parent2.metadataURI, "/gen", Strings.toString((parent1.generation > parent2.generation ? parent1.generation : parent2.generation) + 1)));
        }

         // Add OracleLikeData influence to attributes
         initialEnergy = initialEnergy + (initialEnergy * oracleLikeData / 200); // Scale energy based on oracle (if oracle > 100, boost)
         initialDynamicAttribute = initialDynamicAttribute + (initialDynamicAttribute * oracleLikeData / 300); // Scale attribute

        return (newAffinity, initialEnergy, initialDynamicAttribute, newMetadataURI);
    }

    // --- Utility/Standard Library Functions (for string conversion) ---
    // Using a minimal version of OpenZeppelin's Strings.toString for demo purposes.
    // In a real project, import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";

    library Strings {
        bytes16 private constant alphabet = "0123456789abcdef";

        function toString(uint256 value) internal pure returns (string memory) {
            if (value == 0) {
                return "0";
            }
            uint256 temp = value;
            uint256 digits;
            while (temp != 0) {
                digits++;
                temp /= 10;
            }
            bytes memory buffer = new bytes(digits);
            while (value != 0) {
                digits -= 1;
                buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
                value /= 10;
            }
            return string(buffer);
        }
    }
}
```

**Explanation of Advanced/Creative/Trendy Concepts:**

1.  **Dynamic State & Time-Based Mechanics (Decay):** Shapers aren't static NFTs. Their `energyLevel` decays over time, pushing them towards a `Decayed` state if neglected. This adds a "management" layer and makes interaction crucial. The `_applyDecay` function is a core mechanic, and getters like `getShaperDetails` simulate this decay for view purposes (though a state-changing call would be needed to persist it).
2.  **Complex Interaction Effects:** `interactWithSelf` and `interactWithOther` demonstrate how functions can modify multiple properties based on the Shaper's current state and other factors (like affinities). `interactWithOther` adds complexity by considering the relationship between two entities.
3.  **Algorithmic Evolution:** The `evolveShaperSingle` and `evolveShapersPair` functions implement a non-standard minting process. New Shapers are not simply minted; they are *derived* from existing ones (`parentShaper`s). The `_generateNewShaperAttributes` function encapsulates the logic for how properties (affinity, energy, attribute, metadata) are inherited or randomized, influenced by parent traits and external factors (`oracleLikeData`). This creates a lineage and variability not found in simple generative mints.
4.  **Simulated External Influence (Oracle-like Data):** The `oracleLikeData` variable and `setOracleLikeData` function allow an administrator (or potentially a more complex governance mechanism in a real dApp) to inject data that influences core mechanics like decay rate and evolution outcomes. This simulates how a contract could react to external conditions without directly integrating a complex oracle (which is outside the scope of just the contract logic itself).
5.  **State Machine Transitions:** The `State` enum (`Active`, `Dormant`, `Decayed`, `Evolved`) and the `_updateShaperState` helper function manage transitions between defined states, triggered by energy loss, evolution, or explicit owner actions (`setShaperDormant`, `reviveDormantShaper`).
6.  **Non-Standard Collectible:** This isn't a typical ERC-721 transfer. While owners can hypothetically transfer the Shaper by changing the `owner` field in the struct and updating the `ownerToShaperIds` mapping (which wasn't explicitly added as a public function to keep focus on evolution/decay, but could be), the primary value comes from interacting with and evolving the Shaper, not just simple ownership/trading.
7.  **Internal State Management:** Ownership and lists of shapers per owner (`ownerToShaperIds`) are managed within the contract itself, deviating from standard token interface patterns.

This contract provides a framework for a dynamic ecosystem where digital entities have lifecycle management, interactive properties, and algorithmic growth, going beyond basic token functionalities.

**Note on Security and Gas:**
*   The `ownerToShaperIds` mapping and corresponding `getOwnerShaperIds` function are inefficient for owners with many shapers and can hit gas limits. In a production dApp, this would typically be handled by an external indexer service rather than storing/retrieving arrays on-chain.
*   The pseudo-randomness using `block.timestamp`, `block.number`, and `block.difficulty` is **not secure** for high-value or competitive scenarios, as miners can influence these values. A real application requiring secure randomness would need Chainlink VRF or a similar solution.
*   Applying decay on every interaction/getter requires updating state, consuming gas. The current `getShaperDetails` *simulates* decay for the view but doesn't persist it. A more complex system might require a dedicated state-update function or integrate decay application carefully into critical state-changing calls.
*   Error handling and edge cases (e.g., maximum energy/attribute values) have basic implementations but would need robust refinement for production.