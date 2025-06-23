Okay, here is a smart contract concept called "Quantum Alchemy". It's designed around resource gathering, refining, crafting, recipe discovery, and managing energy, incorporating randomness via a mock VRF oracle and state-dependent resonance mechanics, without directly copying standard ERC20/ERC721 implementations (we'll implement the necessary internal logic for balances/ownership/transfers custom).

This contract manages three types of assets:
1.  **Quantum Particles (QP):** Basic, fungible resources gathered by players. Different types exist.
2.  **Energetic Essences (EE):** Refined, fungible resources created by processing particles. Different types exist.
3.  **Quantum Artifacts (QA):** Crafted, non-fungible items created by combining essences. Have unique properties and potential for "resonance".

**Concept Highlights:**

*   **Resource Lifecycle:** Gather -> Refine -> Combine -> Discover/Upgrade/Disenchant.
*   **Energy System:** Actions consume energy, which regenerates over time per player, with a cap.
*   **Recipe Discovery:** New recipes are not initially known and must be discovered via a probabilistic mechanism using a VRF oracle.
*   **Probabilistic Outcomes:** Crafting success, artifact properties, and recipe discovery rely on verifiable randomness.
*   **Artifact Resonance:** Specific artifacts can enter a "resonance" state under certain conditions or when combined with other items, yielding bonuses.
*   **Custom Asset Management:** Internal logic for tracking balances and ownership, distinct from standard ERC20/721/1155 libraries.
*   **State-Dependent Fees/Mechanics:** (Could be added, but keeping it simpler for 20+ functions focuses on the core loop).

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// --- CONTRACT OUTLINE ---
// 1. State Variables: Define the core data structures for assets, recipes, energy, and contract parameters.
// 2. Enums & Structs: Define custom types for asset kinds, recipes, and artifact properties.
// 3. Events: Define events for tracking key actions (minting, transfers, crafting, discovery).
// 4. Modifiers: Define custom access control (onlyOwner) and state check (whenNotPaused).
// 5. Constructor: Initialize contract owner, energy parameters, and potentially add initial asset types.
// 6. Admin Functions: Functions for the owner to manage asset types, recipes, fees, and core parameters.
// 7. User Functions: Functions for players to interact with the core game loop (gather, refine, combine, discover, transfer, etc.).
// 8. VRF Integration: Functions to handle randomness requests and callbacks (simulated/mocked here).
// 9. Helper Functions: Internal or external functions for balance checks, transfers, energy management, etc.

// --- FUNCTION SUMMARY ---
// ADMIN FUNCTIONS (onlyOwner):
// 1. addParticleType(string name): Register a new type of Quantum Particle.
// 2. addEssenceType(string name): Register a new type of Energetic Essence.
// 3. addArtifactType(string name): Register a new type of Quantum Artifact.
// 4. addRefinementRecipe(...): Define a new recipe to convert particles to essences.
// 5. addCombinationRecipe(...): Define a new recipe to convert essences to artifacts.
// 6. removeRecipe(uint256 recipeId, bool isRefinement): Remove an existing recipe.
// 7. setEnergyParams(uint256 cap, uint256 regenRate, uint64 regenInterval): Configure player energy system.
// 8. setVRFOracle(address oracle, bytes32 keyHash): Configure the VRF oracle address and keyhash (mock).
// 9. setActionFees(uint256 gatherFee, uint256 refineFee, uint256 combineFee, uint256 discoverFee): Set fees for actions.
// 10. withdrawFees(address payable recipient): Withdraw accumulated fees.
// 11. pauseContract(): Pause certain user actions.
// 12. unpauseContract(): Unpause the contract.

// USER/PUBLIC FUNCTIONS:
// 13. gatherParticles(uint256 particleTypeId, uint256 amount): User action to generate/acquire particles (requires fee).
// 14. refineParticles(uint256 recipeId, uint256 inputParticleTypeId, uint256 inputAmount): Convert particles to essences based on a recipe (requires fee, energy, randomness).
// 15. combineEssences(uint256 recipeId, uint256[] inputEssenceTypeIds, uint256[] inputAmounts): Convert essences to artifacts based on a recipe (requires fee, energy, randomness).
// 16. discoverRecipe(bool isRefinement): Attempt to discover a new recipe using randomness (requires fee, energy).
// 17. getParticleBalance(address player, uint256 particleTypeId): Get a player's particle balance.
// 18. getEssenceBalance(address player, uint256 essenceTypeId): Get a player's essence balance.
// 19. getArtifactOwner(uint256 artifactId): Get the owner of an artifact.
// 20. getArtifactProperties(uint256 artifactId): Get properties of an artifact.
// 21. getPlayerEnergy(address player): Get a player's current energy, including regeneration.
// 22. getKnownRefinementRecipes(address player): Get the list of refinement recipes a player knows.
// 23. getKnownCombinationRecipes(address player): Get the list of combination recipes a player knows.
// 24. getRefinementRecipeDetails(uint256 recipeId): Get details of a refinement recipe.
// 25. getCombinationRecipeDetails(uint256 recipeId): Get details of a combination recipe.
// 26. transferParticle(address recipient, uint256 particleTypeId, uint256 amount): Transfer particles between players.
// 27. transferEssence(address recipient, uint256 essenceTypeId, uint256 amount): Transfer essences between players.
// 28. transferArtifact(address recipient, uint256 artifactId): Transfer an artifact between players.
// 29. upgradeArtifact(uint256 artifactId, uint256 particleTypeId, uint256 amount): Use particles to upgrade an artifact (simulated effect).
// 30. disenchantArtifact(uint256 artifactId): Destroy an artifact to regain some essences (simulated effect).
// 31. getArtifactResonancePotential(uint256 artifactId): Check if an artifact has potential for resonance.
// 32. triggerResonance(uint256 artifactId): Activate an artifact's resonance, consuming it for a bonus (requires energy).
// 33. onVRFCallback(uint256 requestId, uint256 randomness): Callback function for VRF oracle (mock implementation).
// 34. getVRFRequestStatus(uint256 requestId): Check status of a VRF request.

contract QuantumAlchemy {
    address public owner;
    bool public paused = false;

    // --- STATE VARIABLES ---

    // Asset Tracking (Custom, not standard ERCs)
    mapping(address => mapping(uint256 => uint256)) private particleBalances; // player => particleType => balance
    mapping(address => mapping(uint256 => uint256)) private essenceBalances; // player => essenceType => balance

    mapping(uint256 => address) private artifactOwners; // artifactId => owner
    mapping(uint256 => uint256) private artifactTypes; // artifactId => artifactType
    mapping(uint256 => ArtifactProperties) private artifactProperties; // artifactId => properties
    uint256 private nextArtifactId = 1; // Start artifact IDs from 1

    // Asset Type Definitions (mapping ID to something descriptive, names storage is expensive)
    mapping(uint256 => bool) public isValidParticleType;
    mapping(uint256 => bool) public isValidEssenceType;
    mapping(uint256 => bool) public isValidArtifactType;
    uint256 private nextParticleTypeId = 1;
    uint256 private nextEssenceTypeId = 1;
    uint256 private nextArtifactTypeId = 1;

    // Recipe Definitions
    mapping(uint256 => RefinementRecipe) public refinementRecipes;
    mapping(uint256 => CombinationRecipe) public combinationRecipes;
    uint256 private nextRefinementRecipeId = 1;
    uint256 private nextCombinationRecipeId = 1;

    // Player Knowledge
    mapping(address => mapping(uint256 => bool)) private knownRefinementRecipes; // player => recipeId => known
    mapping(address => mapping(uint256 => bool)) private knownCombinationRecipes; // player => recipeId => known

    // Energy System
    mapping(address => uint256) private playerEnergy; // player => current energy
    mapping(address => uint64) private lastEnergyRegenTimestamp; // player => last regen block timestamp
    uint256 public energyCap = 100; // Max energy a player can have
    uint256 public energyRegenRate = 1; // Energy regenerated per interval
    uint64 public energyRegenInterval = 60; // Interval in seconds (e.g., 60s for 1 energy/minute)

    // Fees (in contract's native currency, e.g., Ether)
    uint256 public gatherFee = 0.001 ether;
    uint256 public refineFee = 0.002 ether;
    uint256 public combineFee = 0.003 ether;
    uint256 public discoverFee = 0.005 ether;
    uint256 public feesCollected = 0;

    // Randomness (Mock VRF Integration)
    address public vrfOracle; // Address of the mock VRF Coordinator
    bytes32 public vrfKeyHash; // Keyhash for VRF requests (mock)
    uint256 private nextVRFRequestId = 1;
    mapping(uint256 => VRFRequestStatus) private vrfRequests; // request ID => status/details

    // --- ENUMS & STRUCTS ---

    enum VRFRequestType {
        None,
        Refine,
        Combine,
        DiscoverRefinement,
        DiscoverCombination
    }

    struct VRFRequestStatus {
        address player;
        VRFRequestType requestType;
        uint256 associatedId; // Recipe ID or dummy for discovery
        bool fulfilled;
        uint256 randomness;
    }

    struct RefinementRecipe {
        uint256 inputParticleType;
        uint256 inputAmount;
        uint256 outputEssenceType;
        uint256 outputAmount;
        uint256 energyCost;
        uint256 baseSuccessChance; // out of 1000 (e.g., 900 for 90%)
    }

    struct CombinationRecipe {
        uint256[] inputEssenceTypes;
        uint256[] inputAmounts;
        uint256 outputArtifactType;
        uint256 energyCost;
        uint256 baseSuccessChance; // out of 1000
        uint256 resonanceBonusEssenceType; // Type of essence given on resonance trigger (0 if none)
        uint256 resonanceBonusAmount;
    }

    struct ArtifactProperties {
        uint256 power; // Example property
        uint256 durability; // Example property
        bool hasResonancePotential; // Can this artifact trigger resonance?
        uint256 resonanceEssenceBonusType; // Which essence type is the bonus?
        uint256 resonanceEssenceBonusAmount; // How much essence for the bonus?
    }

    // --- EVENTS ---

    event ParticleMinted(address indexed player, uint256 particleTypeId, uint256 amount);
    event ParticleTransferred(address indexed from, address indexed to, uint256 particleTypeId, uint256 amount);
    event ParticleBurned(address indexed player, uint256 particleTypeId, uint256 amount);

    event EssenceMinted(address indexed player, uint256 essenceTypeId, uint256 amount);
    event EssenceTransferred(address indexed from, address indexed to, uint256 essenceTypeId, uint256 amount);
    event EssenceBurned(address indexed player, uint256 essenceTypeId, uint256 amount);

    event ArtifactMinted(address indexed owner, uint256 indexed artifactId, uint256 artifactType);
    event ArtifactTransferred(address indexed from, address indexed to, uint256 indexed artifactId);
    event ArtifactBurned(address indexed owner, uint256 indexed artifactId);

    event RecipeAdded(uint256 indexed recipeId, bool isRefinement);
    event RecipeRemoved(uint256 indexed recipeId, bool isRefinement);
    event RecipeDiscovered(address indexed player, uint256 indexed recipeId, bool isRefinement);

    event CraftingAttempt(address indexed player, uint256 indexed recipeId, bool isRefinement, bool success);
    event ResonanceTriggered(address indexed player, uint256 indexed artifactId, uint256 essenceBonusType, uint256 essenceBonusAmount);

    event EnergyChanged(address indexed player, uint256 newEnergy, uint256 energyUsed);
    event FeesCollected(uint256 amount);
    event FeesWithdrawn(address indexed recipient, uint256 amount);
    event ContractPaused();
    event ContractUnpaused();

    event VRFRequested(uint256 indexed requestId, address indexed player, VRFRequestType requestType);
    event VRFFulfilled(uint256 indexed requestId, uint256 randomness);


    // --- MODIFIERS ---

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }

    modifier whenNotPaused() {
        require(!paused, "Contract is paused");
        _;
    }

    // --- CONSTRUCTOR ---

    constructor() {
        owner = msg.sender;
        // Initialize with default energy params, can be changed later
        energyCap = 100;
        energyRegenRate = 1;
        energyRegenInterval = 60; // 1 minute interval
    }

    // --- ADMIN FUNCTIONS ---

    function addParticleType(string memory /* name */) public onlyOwner {
        uint256 id = nextParticleTypeId++;
        isValidParticleType[id] = true;
        // In a real contract, storing names directly is expensive.
        // Would likely use a separate off-chain registry or just IDs.
    }

    function addEssenceType(string memory /* name */) public onlyOwner {
        uint256 id = nextEssenceTypeId++;
        isValidEssenceType[id] = true;
    }

    function addArtifactType(string memory /* name */) public onlyOwner {
        uint256 id = nextArtifactTypeId++;
        isValidArtifactType[id] = true;
    }

    function addRefinementRecipe(
        uint256 inputParticleTypeId,
        uint256 inputAmount,
        uint256 outputEssenceTypeId,
        uint256 outputAmount,
        uint256 energyCost,
        uint256 baseSuccessChance // out of 1000
    ) public onlyOwner {
        require(isValidParticleType[inputParticleTypeId], "Invalid input particle type");
        require(isValidEssenceType[outputEssenceTypeId], "Invalid output essence type");
        uint256 id = nextRefinementRecipeId++;
        refinementRecipes[id] = RefinementRecipe({
            inputParticleType: inputParticleTypeId,
            inputAmount: inputAmount,
            outputEssenceType: outputEssenceTypeId,
            outputAmount: outputAmount,
            energyCost: energyCost,
            baseSuccessChance: baseSuccessChance
        });
        emit RecipeAdded(id, true);
    }

    function addCombinationRecipe(
        uint256[] memory inputEssenceTypeIds,
        uint256[] memory inputAmounts,
        uint256 outputArtifactTypeId,
        uint256 energyCost,
        uint256 baseSuccessChance, // out of 1000
        uint256 resonanceBonusEssenceType,
        uint256 resonanceBonusAmount
    ) public onlyOwner {
        require(inputEssenceTypeIds.length == inputAmounts.length, "Input arrays mismatch");
        for(uint i = 0; i < inputEssenceTypeIds.length; i++) {
            require(isValidEssenceType[inputEssenceTypeIds[i]], "Invalid input essence type");
        }
        require(isValidArtifactType[outputArtifactTypeId], "Invalid output artifact type");
        if (resonanceBonusEssenceType != 0) {
             require(isValidEssenceType[resonanceBonusEssenceType], "Invalid resonance essence type");
        }

        uint256 id = nextCombinationRecipeId++;
        combinationRecipes[id] = CombinationRecipe({
            inputEssenceTypes: inputEssenceTypeIds,
            inputAmounts: inputAmounts,
            outputArtifactType: outputArtifactTypeId,
            energyCost: energyCost,
            baseSuccessChance: baseSuccessChance,
            resonanceBonusEssenceType: resonanceBonusEssenceType,
            resonanceBonusAmount: resonanceBonusAmount
        });
        emit RecipeAdded(id, false);
    }

    function removeRecipe(uint256 recipeId, bool isRefinement) public onlyOwner {
        if (isRefinement) {
            delete refinementRecipes[recipeId];
        } else {
            delete combinationRecipes[recipeId];
        }
        emit RecipeRemoved(recipeId, isRefinement);
    }

    function setEnergyParams(uint256 cap, uint256 regenRate_, uint64 regenInterval_) public onlyOwner {
        energyCap = cap;
        energyRegenRate = regenRate_;
        energyRegenInterval = regenInterval_;
    }

    // Simplified VRF Oracle setting for mock/testing
    function setVRFOracle(address oracle, bytes32 keyHash) public onlyOwner {
        vrfOracle = oracle;
        vrfKeyHash = keyHash;
    }

    function setActionFees(uint256 gatherFee_, uint256 refineFee_, uint256 combineFee_, uint256 discoverFee_) public onlyOwner {
        gatherFee = gatherFee_;
        refineFee = refineFee_;
        combineFee = combineFee_;
        discoverFee = discoverFee_;
    }

    function withdrawFees(address payable recipient) public onlyOwner {
        uint256 amount = feesCollected;
        feesCollected = 0;
        require(amount > 0, "No fees to withdraw");
        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Fee withdrawal failed");
        emit FeesWithdrawn(recipient, amount);
    }

    function pauseContract() public onlyOwner {
        require(!paused, "Contract is already paused");
        paused = true;
        emit ContractPaused();
    }

    function unpauseContract() public onlyOwner {
        require(paused, "Contract is not paused");
        paused = false;
        emit ContractUnpaused();
    }


    // --- USER/PUBLIC FUNCTIONS ---

    function gatherParticles(uint256 particleTypeId, uint256 amount) public payable whenNotPaused {
        require(isValidParticleType[particleTypeId], "Invalid particle type");
        require(amount > 0, "Amount must be greater than zero");
        require(msg.value >= gatherFee, "Insufficient fee");

        feesCollected += msg.value;
        _mintParticle(msg.sender, particleTypeId, amount);
    }

    function refineParticles(uint256 recipeId) public payable whenNotPaused {
        RefinementRecipe storage recipe = refinementRecipes[recipeId];
        require(recipe.inputParticleType != 0, "Invalid refinement recipe ID"); // Check if recipe exists
        require(msg.value >= refineFee, "Insufficient fee");

        feesCollected += msg.value;

        address player = msg.sender;

        // Check if player knows recipe (optional gate, but adds complexity)
        // require(knownRefinementRecipes[player][recipeId], "Recipe not known");

        // Check particle balance
        require(particleBalances[player][recipe.inputParticleType] >= recipe.inputAmount, "Insufficient particles");

        // Check and use energy
        uint256 currentEnergy = getPlayerEnergy(player); // Use getter to trigger regen
        require(currentEnergy >= recipe.energyCost, "Insufficient energy");
        _useEnergy(player, recipe.energyCost);

        // Burn input particles
        _burnParticle(player, recipe.inputParticleType, recipe.inputAmount);

        // Request randomness for success chance
        _requestVRF(player, VRFRequestType.Refine, recipeId);

        // Result (mint output essence) happens in onVRFCallback
    }

     function combineEssences(uint256 recipeId) public payable whenNotPaused {
        CombinationRecipe storage recipe = combinationRecipes[recipeId];
        require(recipe.outputArtifactType != 0, "Invalid combination recipe ID"); // Check if recipe exists
        require(msg.value >= combineFee, "Insufficient fee");

        feesCollected += msg.value;

        address player = msg.sender;

        // Check if player knows recipe (optional gate)
        // require(knownCombinationRecipes[player][recipeId], "Recipe not known");

        // Check essence balances
        require(recipe.inputEssenceTypes.length == recipe.inputAmounts.length, "Recipe data mismatch");
        for(uint i = 0; i < recipe.inputEssenceTypes.length; i++) {
            require(essenceBalances[player][recipe.inputEssenceTypes[i]] >= recipe.inputAmounts[i], "Insufficient essences");
        }

        // Check and use energy
        uint256 currentEnergy = getPlayerEnergy(player); // Use getter to trigger regen
        require(currentEnergy >= recipe.energyCost, "Insufficient energy");
        _useEnergy(player, recipe.energyCost);

        // Burn input essences
         for(uint i = 0; i < recipe.inputEssenceTypes.length; i++) {
            _burnEssence(player, recipe.inputEssenceTypes[i], recipe.inputAmounts[i]);
        }

        // Request randomness for success chance and artifact properties
        _requestVRF(player, VRFRequestType.Combine, recipeId);

        // Result (mint output artifact) happens in onVRFCallback
    }


    function discoverRecipe(bool isRefinement) public payable whenNotPaused {
        require(msg.value >= discoverFee, "Insufficient fee");
        feesCollected += msg.value;

        address player = msg.sender;

        // Check and use energy (discovery also costs energy)
        uint256 currentEnergy = getPlayerEnergy(player); // Use getter to trigger regen
        require(currentEnergy >= discoverFee / (1 ether / energyRegenRate), "Insufficient energy for discovery"); // Example cost tied to fee
        _useEnergy(player, discoverFee / (1 ether / energyRegenRate)); // Arbitrary energy cost

        // Request randomness for discovery outcome
        if (isRefinement) {
            _requestVRF(player, VRFRequestType.DiscoverRefinement, 0); // 0 as dummy ID
        } else {
            _requestVRF(player, VRFRequestType.DiscoverCombination, 0); // 0 as dummy ID
        }

        // Discovery result happens in onVRFCallback
    }

    function getParticleBalance(address player, uint256 particleTypeId) public view returns (uint256) {
        return particleBalances[player][particleTypeId];
    }

    function getEssenceBalance(address player, uint256 essenceTypeId) public view returns (uint256) {
        return essenceBalances[player][essenceTypeId];
    }

    function getArtifactOwner(uint256 artifactId) public view returns (address) {
        require(artifactId > 0 && artifactId < nextArtifactId, "Invalid artifact ID");
        return artifactOwners[artifactId];
    }

    function getArtifactProperties(uint255 artifactId) public view returns (ArtifactProperties memory) {
         require(artifactId > 0 && artifactId < nextArtifactId, "Invalid artifact ID");
         require(artifactOwners[artifactId] != address(0), "Artifact does not exist"); // Check existence
         return artifactProperties[artifactId];
    }

    function getPlayerEnergy(address player) public view returns (uint256) {
        uint64 lastTimestamp = lastEnergyRegenTimestamp[player];
        uint64 currentTimestamp = uint64(block.timestamp);

        uint256 currentEnergy = playerEnergy[player];

        if (lastTimestamp == 0) {
             // First time checking energy, set timestamp but no regen
             return currentEnergy;
        }

        if (currentTimestamp > lastTimestamp && energyRegenInterval > 0) {
            uint64 timePassed = currentTimestamp - lastTimestamp;
            uint256 intervals = timePassed / energyRegenInterval;
            uint256 potentialRegen = intervals * energyRegenRate;
             currentEnergy = currentEnergy + potentialRegen;
             if (currentEnergy > energyCap) {
                currentEnergy = energyCap;
            }
            // Note: This view function doesn't update the state.
            // The state update happens internally when energy is used (_useEnergy).
        }
        return currentEnergy;
    }

    // This view function recalculates, but the state update happens on _useEnergy
    function _calculateEnergyRegen(address player) internal {
        uint64 lastTimestamp = lastEnergyRegenTimestamp[player];
        uint64 currentTimestamp = uint64(block.timestamp);

        if (lastTimestamp == 0) {
            lastEnergyRegenTimestamp[player] = currentTimestamp;
            return; // No regen on first check
        }

        if (currentTimestamp > lastTimestamp && energyRegenInterval > 0) {
            uint64 timePassed = currentTimestamp - lastTimestamp;
            uint256 intervals = timePassed / energyRegenInterval;
            uint256 potentialRegen = intervals * energyRegenRate;

            playerEnergy[player] += potentialRegen;
            if (playerEnergy[player] > energyCap) {
                playerEnergy[player] = energyCap;
            }
            lastEnergyRegenTimestamp[player] = lastTimestamp + intervals * energyRegenInterval;
        }
    }

     function _useEnergy(address player, uint256 amount) internal {
        _calculateEnergyRegen(player); // Regen before using

        require(playerEnergy[player] >= amount, "Insufficient energy after regen attempt");
        playerEnergy[player] -= amount;
        emit EnergyChanged(player, playerEnergy[player], amount);
    }


    function getKnownRefinementRecipes(address player) public view returns (uint256[] memory) {
        uint256[] memory known;
        uint256 count = 0;
        // Iterate through all possible recipe IDs (up to the current max)
        // In a real contract, this might need indexing or a more efficient way
        // if the number of recipes grows very large.
        for (uint i = 1; i < nextRefinementRecipeId; i++) {
            if (knownRefinementRecipes[player][i]) {
                count++;
            }
        }
        known = new uint256[](count);
        uint256 index = 0;
        for (uint i = 1; i < nextRefinementRecipeId; i++) {
            if (knownRefinementRecipes[player][i]) {
                known[index] = i;
                index++;
            }
        }
        return known;
    }

     function getKnownCombinationRecipes(address player) public view returns (uint256[] memory) {
        uint256[] memory known;
        uint256 count = 0;
        for (uint i = 1; i < nextCombinationRecipeId; i++) {
            if (knownCombinationRecipes[player][i]) {
                count++;
            }
        }
        known = new uint256[](count);
        uint256 index = 0;
        for (uint i = 1; i < nextCombinationRecipeId; i++) {
            if (knownCombinationRecipes[player][i]) {
                known[index] = i;
                index++;
            }
        }
        return known;
    }

    function getRefinementRecipeDetails(uint256 recipeId) public view returns (RefinementRecipe memory) {
         require(refinementRecipes[recipeId].inputParticleType != 0, "Invalid refinement recipe ID");
         return refinementRecipes[recipeId];
    }

    function getCombinationRecipeDetails(uint256 recipeId) public view returns (CombinationRecipe memory) {
         require(combinationRecipes[recipeId].outputArtifactType != 0, "Invalid combination recipe ID");
         return combinationRecipes[recipeId];
    }

    function transferParticle(address recipient, uint256 particleTypeId, uint256 amount) public whenNotPaused {
        _transferParticle(msg.sender, recipient, particleTypeId, amount);
    }

    function transferEssence(address recipient, uint256 essenceTypeId, uint256 amount) public whenNotPaused {
        _transferEssence(msg.sender, recipient, essenceTypeId, amount);
    }

     function transferArtifact(address recipient, uint256 artifactId) public whenNotPaused {
        _transferArtifact(msg.sender, recipient, artifactId);
    }

    // --- Placeholder/Simulated Functions ---
    // These would have more complex logic in a real game

    function upgradeArtifact(uint256 artifactId, uint256 particleTypeId, uint256 amount) public whenNotPaused {
        require(artifactOwners[artifactId] == msg.sender, "Not your artifact");
        require(isValidParticleType[particleTypeId], "Invalid particle type");
        require(amount > 0, "Amount must be > 0");
        require(particleBalances[msg.sender][particleTypeId] >= amount, "Insufficient particles");

        _burnParticle(msg.sender, particleTypeId, amount);

        // Simulate upgrading properties (e.g., add amount/100 to power)
        artifactProperties[artifactId].power += amount / 100;

        // In a real system, this might be probabilistic or have diminishing returns
        // emit ArtifactUpgraded(artifactId, particleTypeId, amount); // Need new event
    }

    function disenchantArtifact(uint256 artifactId) public whenNotPaused {
        require(artifactOwners[artifactId] == msg.sender, "Not your artifact");
        require(artifactId > 0 && artifactId < nextArtifactId && artifactOwners[artifactId] != address(0), "Invalid or non-existent artifact");

        ArtifactProperties memory props = artifactProperties[artifactId];
        // Simulate getting essences back based on properties
        uint256 essenceAmount = (props.power + props.durability) / 10; // Example logic
        uint256 essenceType = 1; // Example: always return essence type 1

        _burnArtifact(artifactId); // Destroy the artifact
        _mintEssence(msg.sender, essenceType, essenceAmount); // Give essences back

        // emit ArtifactDisenchanted(artifactId, essenceType, essenceAmount); // Need new event
    }

    function getArtifactResonancePotential(uint256 artifactId) public view returns (bool, uint256, uint256) {
         require(artifactId > 0 && artifactId < nextArtifactId && artifactOwners[artifactId] != address(0), "Invalid or non-existent artifact");
         ArtifactProperties memory props = artifactProperties[artifactId];
         return (props.hasResonancePotential, props.resonanceEssenceBonusType, props.resonanceEssenceBonusAmount);
    }


    function triggerResonance(uint256 artifactId) public whenNotPaused {
        require(artifactOwners[artifactId] == msg.sender, "Not your artifact");
        require(artifactId > 0 && artifactId < nextArtifactId && artifactOwners[artifactId] != address(0), "Invalid or non-existent artifact");

        ArtifactProperties memory props = artifactProperties[artifactId];
        require(props.hasResonancePotential, "Artifact does not have resonance potential");
        require(props.resonanceEssenceBonusType != 0 && props.resonanceEssenceBonusAmount > 0, "Resonance configured incorrectly");

        // Require energy to trigger resonance
        uint256 resonanceEnergyCost = 50; // Example fixed cost
        uint256 currentEnergy = getPlayerEnergy(msg.sender);
        require(currentEnergy >= resonanceEnergyCost, "Insufficient energy to trigger resonance");
        _useEnergy(msg.sender, resonanceEnergyCost);

        _burnArtifact(artifactId); // Resonance consumes the artifact
        _mintEssence(msg.sender, props.resonanceEssenceBonusType, props.resonanceEssenceBonusAmount); // Reward bonus essence

        emit ResonanceTriggered(msg.sender, artifactId, props.resonanceEssenceBonusType, props.resonanceEssenceBonusAmount);
    }

    // --- VRF Integration (Mock) ---

    // In a real Chainlink VRF integration, this would call the VRF Coordinator contract
    function _requestVRF(address player, VRFRequestType requestType, uint256 associatedId) internal {
        require(vrfOracle != address(0), "VRF oracle not set");
        // In real VRF, you'd pass keyHash and fee. Here, we just track the request.
        uint256 requestId = nextVRFRequestId++;
        vrfRequests[requestId] = VRFRequestStatus({
            player: player,
            requestType: requestType,
            associatedId: associatedId,
            fulfilled: false,
            randomness: 0 // Will be set by callback
        });
        emit VRFRequested(requestId, player, requestType);

        // Simulate immediate callback for demonstration purposes.
        // In production, this would be an external call from the VRF oracle.
        // Mocking randomness: block.timestamp is NOT secure randomness
        // This is purely for simulating the *structure* of the callback.
        uint256 mockRandomness = uint256(keccak256(abi.encodePacked(block.timestamp, msg.sender, requestId)));
         onVRFCallback(requestId, mockRandomness);

    }

    // Mock callback function - in a real integration, this would implement
    // Chainlink's VRFConsumerBase and this function would be callable ONLY by the oracle.
    // For this example, we make it public to simulate the call.
    function onVRFCallback(uint256 requestId, uint256 randomness) public {
         // In a real VRFConsumer, add 'onlyVRF' modifier and check request exists.
         // require(msg.sender == vrfOracle, "Only VRF oracle can call this"); // Uncomment in real impl
         require(vrfRequests[requestId].requestType != VRFRequestType.None, "Invalid VRF request ID");
         require(!vrfRequests[requestId].fulfilled, "VRF request already fulfilled");

         vrfRequests[requestId].fulfilled = true;
         vrfRequests[requestId].randomness = randomness;
         emit VRFFulfilled(requestId, randomness);

         address player = vrfRequests[requestId].player;
         VRFRequestType requestType = vrfRequests[requestId].requestType;
         uint256 associatedId = vrfRequests[requestId].associatedId;

         // Process the outcome based on randomness
         if (requestType == VRFRequestType.Refine) {
             RefinementRecipe storage recipe = refinementRecipes[associatedId];
             uint256 chance = recipe.baseSuccessChance; // Can add logic to modify chance based on player state/items

             // Deterministic outcome based on randomness
             if (randomness % 1000 < chance) {
                 // Success
                 _mintEssence(player, recipe.outputEssenceType, recipe.outputAmount);
                 emit CraftingAttempt(player, associatedId, true, true);
             } else {
                 // Failure - Maybe return some fraction of input?
                 emit CraftingAttempt(player, associatedId, true, false);
             }

         } else if (requestType == VRFRequestType.Combine) {
             CombinationRecipe storage recipe = combinationRecipes[associatedId];
              uint256 chance = recipe.baseSuccessChance; // Can add logic to modify chance

             if (randomness % 1000 < chance) {
                  // Success - Mint Artifact
                  uint256 artifactId = nextArtifactId++;
                  artifactOwners[artifactId] = player;
                  artifactTypes[artifactId] = recipe.outputArtifactType;
                  // Determine properties based on randomness
                  artifactProperties[artifactId] = ArtifactProperties({
                      power: (randomness % 100) + 1, // Example random property
                      durability: (randomness % 50) + 1, // Example random property
                      hasResonancePotential: recipe.resonanceBonusEssenceType != 0 && (randomness % 10) < 3, // Example: 30% chance if resonance is possible
                      resonanceEssenceBonusType: recipe.resonanceBonusEssenceType,
                      resonanceEssenceBonusAmount: recipe.resonanceBonusAmount + (randomness % (recipe.resonanceBonusAmount/2 + 1)) // Add small random bonus
                  });
                  emit ArtifactMinted(player, artifactId, recipe.outputArtifactType);
                  emit CraftingAttempt(player, associatedId, false, true);
             } else {
                 // Failure - Maybe return some fraction of input essences?
                 emit CraftingAttempt(player, associatedId, false, false);
             }

         } else if (requestType == VRFRequestType.DiscoverRefinement) {
             // Simulate discovery: Find a random unknown recipe (up to the current max)
             uint256 attemptRecipeId = (randomness % (nextRefinementRecipeId - 1)) + 1;
             if (!knownRefinementRecipes[player][attemptRecipeId] && refinementRecipes[attemptRecipeId].inputParticleType != 0) {
                 // Discovered a valid, unknown recipe
                 knownRefinementRecipes[player][attemptRecipeId] = true;
                 emit RecipeDiscovered(player, attemptRecipeId, true);
             }
             // Else: Discovery attempt failed (either found known or invalid ID)

         } else if (requestType == VRFRequestType.DiscoverCombination) {
              uint256 attemptRecipeId = (randomness % (nextCombinationRecipeId - 1)) + 1;
               if (!knownCombinationRecipes[player][attemptRecipeId] && combinationRecipes[attemptRecipeId].outputArtifactType != 0) {
                 // Discovered a valid, unknown recipe
                 knownCombinationRecipes[player][attemptRecipeId] = true;
                 emit RecipeDiscovered(player, attemptRecipeId, false);
             }
              // Else: Discovery attempt failed
         }
    }

     function getVRFRequestStatus(uint256 requestId) public view returns (VRFRequestStatus memory) {
        require(vrfRequests[requestId].requestType != VRFRequestType.None, "Invalid VRF request ID");
        return vrfRequests[requestId];
     }

    // --- CUSTOM ASSET MANAGEMENT (Internal Helpers) ---

    function _mintParticle(address player, uint256 particleTypeId, uint256 amount) internal {
        require(isValidParticleType[particleTypeId], "Invalid particle type for mint");
        require(amount > 0, "Mint amount must be > 0");
        particleBalances[player][particleTypeId] += amount;
        emit ParticleMinted(player, particleTypeId, amount);
    }

    function _burnParticle(address player, uint256 particleTypeId, uint256 amount) internal {
         require(isValidParticleType[particleTypeId], "Invalid particle type for burn");
         require(amount > 0, "Burn amount must be > 0");
         require(particleBalances[player][particleTypeId] >= amount, "Insufficient particles for burn");
         particleBalances[player][particleTypeId] -= amount;
         emit ParticleBurned(player, particleTypeId, amount);
    }

    function _transferParticle(address from, address to, uint256 particleTypeId, uint256 amount) internal {
         require(isValidParticleType[particleTypeId], "Invalid particle type for transfer");
         require(amount > 0, "Transfer amount must be > 0");
         require(particleBalances[from][particleTypeId] >= amount, "Insufficient particles for transfer");
         require(to != address(0), "Transfer to zero address");

         particleBalances[from][particleTypeId] -= amount;
         particleBalances[to][particleTypeId] += amount;
         emit ParticleTransferred(from, to, particleTypeId, amount);
    }

    function _mintEssence(address player, uint256 essenceTypeId, uint256 amount) internal {
        require(isValidEssenceType[essenceTypeId], "Invalid essence type for mint");
        require(amount > 0, "Mint amount must be > 0");
        essenceBalances[player][essenceTypeId] += amount;
        emit EssenceMinted(player, essenceTypeId, amount);
    }

     function _burnEssence(address player, uint256 essenceTypeId, uint256 amount) internal {
         require(isValidEssenceType[essenceTypeId], "Invalid essence type for burn");
         require(amount > 0, "Burn amount must be > 0");
         require(essenceBalances[player][essenceTypeId] >= amount, "Insufficient essences for burn");
         essenceBalances[player][essenceTypeId] -= amount;
         emit EssenceBurned(player, essenceTypeId, amount);
    }

    function _transferEssence(address from, address to, uint256 essenceTypeId, uint256 amount) internal {
         require(isValidEssenceType[essenceTypeId], "Invalid essence type for transfer");
         require(amount > 0, "Transfer amount must be > 0");
         require(essenceBalances[from][essenceTypeId] >= amount, "Insufficient essences for transfer");
         require(to != address(0), "Transfer to zero address");

         essenceBalances[from][essenceTypeId] -= amount;
         essenceBalances[to][essenceTypeId] += amount;
         emit EssenceTransferred(from, to, essenceTypeId, amount);
    }

     function _mintArtifact(address player, uint256 artifactTypeId, ArtifactProperties memory props) internal returns (uint256) {
        require(isValidArtifactType[artifactTypeId], "Invalid artifact type for mint");
        uint256 artifactId = nextArtifactId++;
        artifactOwners[artifactId] = player;
        artifactTypes[artifactId] = artifactTypeId;
        artifactProperties[artifactId] = props;
        emit ArtifactMinted(player, artifactId, artifactTypeId);
        return artifactId;
    }

    function _burnArtifact(uint256 artifactId) internal {
        require(artifactId > 0 && artifactId < nextArtifactId && artifactOwners[artifactId] != address(0), "Invalid or non-existent artifact for burn");
        address owner = artifactOwners[artifactId];
        delete artifactOwners[artifactId];
        delete artifactTypes[artifactId];
        delete artifactProperties[artifactId];
        // Note: We don't decrement nextArtifactId. IDs are unique forever.
        emit ArtifactBurned(owner, artifactId);
    }

     function _transferArtifact(address from, address to, uint256 artifactId) internal {
        require(artifactId > 0 && artifactId < nextArtifactId, "Invalid artifact ID for transfer");
        require(artifactOwners[artifactId] == from, "Not owner of artifact");
        require(to != address(0), "Transfer to zero address");

        artifactOwners[artifactId] = to;
        emit ArtifactTransferred(from, to, artifactId);
    }

    function getCurrentFees() public view returns (uint256 gather, uint256 refine, uint256 combine, uint256 discover) {
        return (gatherFee, refineFee, combineFee, discoverFee);
    }
}
```