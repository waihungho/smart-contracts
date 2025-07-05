Okay, let's create a smart contract concept that integrates dynamic NFTs, resource production, a simulated ecosystem adaptation mechanism, user reputation, and delegated actions. We'll call it the "Ethereal Ecosystem Protocol".

It won't be a standard ERC-721 or ERC-20 contract, but rather a system where "Organism" entities (represented by internal IDs, acting like NFTs) produce "Essence" (represented by internal balances, acting like a token), influenced by their dynamic "Traits" and the evolving "Ecosystem State".

---

**Outline: Ethereal Ecosystem Protocol**

1.  **Concept:** A decentralized ecosystem simulation where users own unique digital organisms (dynamic NFTs) that possess mutable traits. Organisms produce a resource (Essence token) based on their traits and global ecosystem conditions. The ecosystem itself undergoes periodic 'adaptation' cycles, altering parameters based on overall state. Users can interact their organisms, upgrade traits by consuming Essence, build reputation, and delegate actions.
2.  **Core Components:**
    *   **Organisms:** Unique entities with IDs, owners, names, dynamic traits, production cooldowns, pending essence, and individual reputation. (Simulated NFTs)
    *   **Traits:** Attributes organisms possess (e.g., Production Efficiency, Interaction Strength). Each trait has a level.
    *   **Essence:** A consumable resource produced by organisms, used for upgrades and interactions. (Simulated ERC-20)
    *   **Ecosystem State:** Global parameters like total organisms, total essence, and dynamically adapted parameters that influence production and interaction outcomes.
    *   **User Reputation:** A score associated with each user address, influencing interactions and possibly production efficiency.
    *   **Delegation:** Users can delegate specific actions (like interaction) for their organisms to other addresses.
    *   **Adaptation Cycle:** A function that recalculates global ecosystem parameters based on aggregate state, introducing dynamism.
3.  **Key Advanced/Creative Concepts:**
    *   Dynamic/Mutable NFT state (traits stored directly in the struct, not just metadata).
    *   On-chain simulated resource production influenced by multiple factors (traits, global state).
    *   Simulated ecosystem adaptation via dynamic parameters.
    *   Gamified interactions between NFTs affecting state.
    *   On-chain user reputation system.
    *   Custom delegated permissions beyond standard ERC-721 approval.
4.  **Access Control:** Owner (for configuration), User (for organism actions), potentially delegated addresses.

**Function Summary (20+ Functions):**

1.  `constructor()`: Initializes base parameters and the first adaptation cycle.
2.  `mintOrganism(string name)`: Creates a new Organism with initial random/base traits for the caller.
3.  `getOrganismDetails(uint256 organismId)`: View details of a specific organism (traits, pending essence, cooldowns).
4.  `getUserOrganisms(address user)`: View list of organism IDs owned by a user.
5.  `getTraitDetails(uint256 traitTypeId)`: View static details about a specific type of trait.
6.  `produceEssence(uint256 organismId)`: Triggers essence production for an organism, checking cooldowns and calculating output based on traits and ecosystem state. Updates pending essence.
7.  `claimEssence()`: Transfers accumulated pending essence from all of a user's organisms to their claimed balance.
8.  `getPendingEssence(uint256 organismId)`: View how much essence a specific organism has produced but not claimed.
9.  `getUserClaimedEssence(address user)`: View a user's total claimed essence balance.
10. `upgradeTrait(uint256 organismId, uint256 traitTypeId)`: Consumes claimed essence to upgrade a specific trait on an organism. Cost is dynamic based on level and ecosystem. Updates organism traits and potentially reputation.
11. `addTrait(uint256 organismId, uint256 traitTypeId)`: Consumes claimed essence to add a *new* trait (from defined potential types) to an organism. Cost is dynamic.
12. `interactSymbiotic(uint256 organism1Id, uint256 organism2Id)`: Simulates a cooperative interaction between two organisms. Checks cooldowns & delegation. Outcome based on combined traits/reputation. Grants small bonuses or reputation increase. Consumes a small amount of essence.
13. `interactCompetitive(uint256 organism1Id, uint256 organism2Id)`: Simulates a competitive interaction. Checks cooldowns & delegation. Outcome based on combined traits/reputation. One organism might gain reputation/essence, the other might lose. Consumes essence from both participants.
14. `getUserReputation(address user)`: View the reputation score of a user.
15. `getOrganismReputation(uint256 organismId)`: View the individual reputation score of an organism.
16. `delegateInteraction(uint256 organismId, address delegatee)`: Allows an organism owner to authorize another address to trigger interactions for that specific organism.
17. `revokeDelegateInteraction(uint256 organismId)`: Revokes the delegated interaction permission for an organism.
18. `triggerAdaptationCycle()`: A publicly callable function (perhaps with cost or cooldown) that recalculates and updates the global ecosystem parameters based on current state (total organisms, essence levels, etc.).
19. `getEcosystemState()`: View the current global ecosystem parameters and state variables.
20. `setBaseParameters(uint256 baseProd, uint256 baseUpgradeCost, uint256 prodCooldown, uint256 interactCooldown)`: Owner function to set base configuration parameters.
21. `addPotentialTraitType(string name, string description, uint256 baseProdBonus, uint256 baseInteractBonus, uint256 baseUpgradeCost, uint256 maxLevel)`: Owner function to define a new type of trait that organisms can potentially acquire/upgrade.
22. `getPotentialTraitTypes()`: View list of all defined potential trait types.
23. `getTraitUpgradeCost(uint256 organismId, uint256 traitTypeId)`: View function to calculate the current essence cost to upgrade a specific trait on an organism.
24. `getTraitAddCost(uint256 traitTypeId)`: View function to calculate the current essence cost to add a specific trait type to an organism.
25. `getTotalOrganisms()`: View the total number of organisms that exist.
26. `getInteractionCooldown(uint256 organismId)`: View when an organism can next interact.
27. `pauseEcosystem(bool _paused)`: Owner function to pause/unpause core ecosystem activities (production, interactions, adaptation).

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title Ethereal Ecosystem Protocol
 * @dev A smart contract simulating a dynamic ecosystem with mutable digital organisms (dynamic NFTs),
 *      resource production (Essence token), user reputation, delegated actions, and an adaptation cycle.
 *      This is not a standard ERC-721 or ERC-20 implementation but uses internal logic
 *      to represent organism ownership and essence balances.
 */

/*
 * Outline:
 * 1. State Variables: Store core data like organisms, trait types, ecosystem state, balances, reputation, delegation.
 * 2. Structs: Define data structures for Organism, TraitType, EcosystemState.
 * 3. Events: Announce key actions like minting, production, upgrades, interactions, adaptation.
 * 4. Modifiers: Implement access control checks (owner, organism owner/delegate).
 * 5. Core Logic:
 *    - Organism Management (Minting, Details, Ownership simulation)
 *    - Trait Management (Adding, Upgrading, Definition)
 *    - Essence Management (Production, Claiming, Balances simulation)
 *    - Interaction Logic (Symbiotic, Competitive, outcome calculation based on traits/reputation)
 *    - Reputation Management (Updates based on actions)
 *    - Delegation Management
 *    - Ecosystem Adaptation (Trigger and parameter recalculation)
 *    - Parameter Management (View and Owner-only set functions)
 */

/*
 * Function Summary:
 * 1. constructor(): Initialize contract, owner, base params, initial adaptation.
 * 2. mintOrganism(string name): Create and assign a new organism NFT-like entity to caller.
 * 3. getOrganismDetails(uint256 organismId): Retrieve detailed state of an organism.
 * 4. getUserOrganisms(address user): Get list of organism IDs owned by an address.
 * 5. getTraitDetails(uint256 traitTypeId): Get static information about a trait type.
 * 6. produceEssence(uint256 organismId): Trigger essence generation for an organism.
 * 7. claimEssence(): Collect pending essence from all owned organisms to user's balance.
 * 8. getPendingEssence(uint256 organismId): View essence not yet claimed for a specific organism.
 * 9. getUserClaimedEssence(address user): View user's total claimed essence balance.
 * 10. upgradeTrait(uint256 organismId, uint256 traitTypeId): Improve a trait using claimed essence.
 * 11. addTrait(uint256 organismId, uint256 traitTypeId): Give an organism a new trait using claimed essence.
 * 12. interactSymbiotic(uint256 organism1Id, uint256 organism2Id): Perform a cooperative interaction.
 * 13. interactCompetitive(uint256 organism1Id, uint256 organism2Id): Perform a competitive interaction.
 * 14. getUserReputation(address user): View an address's reputation score.
 * 15. getOrganismReputation(uint256 organismId): View an organism's individual reputation score.
 * 16. delegateInteraction(uint256 organismId, address delegatee): Allow another address to interact with an organism.
 * 17. revokeDelegateInteraction(uint256 organismId): Remove interaction delegation.
 * 18. triggerAdaptationCycle(): Re-calculate global ecosystem parameters.
 * 19. getEcosystemState(): View current global state parameters.
 * 20. setBaseParameters(...): Owner function to configure base rates and cooldowns.
 * 21. addPotentialTraitType(...): Owner function to define new available traits.
 * 22. getPotentialTraitTypes(): List all defined trait types.
 * 23. getTraitUpgradeCost(uint256 organismId, uint256 traitTypeId): Calculate dynamic cost to upgrade a trait.
 * 24. getTraitAddCost(uint256 traitTypeId): Calculate dynamic cost to add a trait.
 * 25. getTotalOrganisms(): Get total count of organisms.
 * 26. getInteractionCooldown(uint256 organismId): Get time until next interaction is possible for an organism.
 * 27. pauseEcosystem(bool _paused): Owner function to pause/unpause key functions.
 */

contract EtherealEcosystem {

    address public owner;
    uint256 private _nextTokenId;
    bool public paused = false;

    // --- Data Structures ---

    struct TraitType {
        uint256 id;
        string name;
        string description;
        uint256 baseProductionBonus; // Permille (0-1000) added to base production
        uint256 baseInteractionBonus; // Permille added to interaction score
        uint256 baseUpgradeCost; // Base Essence cost to level up this trait
        uint256 baseAddCost; // Base Essence cost to add this trait initially
        uint256 maxLevel;
    }

    struct Organism {
        uint256 tokenId;
        address owner;
        string name;
        uint256 birthTime;
        uint256 lastProductionTime;
        uint256 pendingEssence; // Essence produced but not yet claimed
        uint256 lastInteractionTime;
        uint256 individualReputation; // Affects interactions
        mapping(uint256 => uint256) traits; // traitTypeId => level
        uint256[] activeTraitTypeIds; // List of trait type IDs this organism has
    }

    struct EcosystemState {
        uint256 totalOrganisms;
        uint256 totalClaimedEssence; // Total Essence claimed by all users
        uint256 totalPendingEssence; // Total Essence pending across all organisms
        uint256 adaptationCycleCount;
        uint256 lastAdaptationTime;
        // Dynamically adapted parameters (simplified for example)
        uint256 currentBaseProductionRate; // Adjusted base production per cycle/unit time
        uint256 currentTraitUpgradeCostMultiplier; // Multiplier for upgrade costs
        uint256 currentTraitAddCostMultiplier; // Multiplier for add costs
    }

    // --- State Variables ---

    mapping(uint256 => Organism) public organisms;
    mapping(address => uint256[]) private userOrganisms; // owner => list of organismIds
    mapping(address => uint256) private userClaimedEssence; // owner => claimed essence balance

    mapping(uint256 => TraitType) private traitTypes; // traitTypeId => TraitType
    uint256[] public potentialTraitTypeIds; // List of IDs for traits that can be added/upgraded
    uint256 private _nextTraitTypeId; // Counter for trait type IDs

    EcosystemState public ecosystemState;

    mapping(address => uint256) public userReputationScores; // owner => reputation

    mapping(uint256 => address) public interactionDelegates; // organismId => delegate address

    // --- Configuration Parameters ---
    uint256 public baseProductionAmountPerCycle = 100; // Base essence produced per production cycle before bonuses
    uint256 public productionCooldown = 1 days; // Time between essence production
    uint256 public interactionCooldown = 1 hours; // Time between organism interactions
    uint256 public adaptationCycleCooldown = 7 days; // How often adaptation can be triggered
    uint256 public reputationLossOnCompetitiveLoss = 10;
    uint256 public reputationGainOnCompetitiveWin = 15;
    uint256 public reputationGainOnSymbioticSuccess = 5;
    uint256 public interactionEssenceCost = 10; // Essence cost per participant in interaction

    // --- Events ---

    event OrganismMinted(uint256 indexed organismId, address indexed owner, string name);
    event EssenceProduced(uint256 indexed organismId, uint256 amount);
    event EssenceClaimed(address indexed user, uint256 amount);
    event TraitUpgraded(uint256 indexed organismId, uint256 indexed traitTypeId, uint256 newLevel);
    event TraitAdded(uint256 indexed organismId, uint256 indexed traitTypeId, uint256 initialLevel);
    event SymbioticInteraction(uint256 indexed organism1Id, uint256 indexed organism2Id, string outcome);
    event CompetitiveInteraction(uint256 indexed winnerId, uint256 indexed loserId, string outcome);
    event UserReputationUpdated(address indexed user, uint256 newReputation);
    event OrganismReputationUpdated(uint256 indexed organismId, uint256 newReputation);
    event InteractionDelegated(uint256 indexed organismId, address indexed delegatee);
    event InteractionDelegationRevoked(uint256 indexed organismId);
    event AdaptationCycleTriggered(uint256 cycleCount, uint256 totalOrganisms, uint256 totalEssence);
    event EcosystemPaused(bool _paused);

    // --- Modifiers ---

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }

    modifier onlyOrganismOwner(uint256 organismId) {
        require(organisms[organismId].owner == msg.sender, "Not the organism owner");
        _;
    }

    modifier onlyOrganismOwnerOrDelegate(uint256 organismId) {
        require(
            organisms[organismId].owner == msg.sender || interactionDelegates[organismId] == msg.sender,
            "Not the organism owner or delegatee"
        );
        _;
    }

    modifier whenNotPaused() {
        require(!paused, "Ecosystem is paused");
        _;
    }

    // --- Constructor ---

    constructor() {
        owner = msg.sender;
        _nextTokenId = 1;
        _nextTraitTypeId = 1;

        // Initialize ecosystem state
        ecosystemState.totalOrganisms = 0;
        ecosystemState.totalClaimedEssence = 0;
        ecosystemState.totalPendingEssence = 0;
        ecosystemState.adaptationCycleCount = 0;
        ecosystemState.lastAdaptationTime = block.timestamp;
        ecosystemState.currentBaseProductionRate = baseProductionAmountPerCycle;
        ecosystemState.currentTraitUpgradeCostMultiplier = 1000; // 100%
        ecosystemState.currentTraitAddCostMultiplier = 1000; // 100%

        // Add some initial potential trait types (Owner could do this later too)
        _addPotentialTraitType("Production Efficiency", "Increases essence production rate", 150, 0, 500, 1000, 10); // +15% prod, base cost 500, add cost 1000, max level 10
        _addPotentialTraitType("Interaction Strength", "Increases success chance/bonus in interactions", 0, 100, 600, 1200, 5); // +10% interact, base cost 600, add cost 1200, max level 5
        _addPotentialTraitType("Resilience", "Reduces negative outcomes in competitive interactions", 0, 50, 400, 800, 7); // +5% interact bonus, base cost 400, add cost 800, max level 7
        _addPotentialTraitType("Essence Conservation", "Reduces essence consumption costs", 0, 0, 700, 1400, 3); // No prod/interact bonus, reduces costs (logic needs implementation)
        _addPotentialTraitType("Reputation Aura", "Boosts reputation gain from positive interactions", 0, 75, 550, 1100, 4); // +7.5% interact bonus, base cost 550, add cost 1100, max level 4

        // Initial Adaptation Cycle
        _triggerAdaptationCycle();
    }

    // --- Organism Management ---

    /**
     * @dev Mints a new Organism for the caller. Assigns a unique ID and initial traits.
     * @param name The desired name for the new organism.
     */
    function mintOrganism(string memory name) public whenNotPaused {
        uint256 tokenId = _nextTokenId++;
        address minter = msg.sender;

        organisms[tokenId] = Organism({
            tokenId: tokenId,
            owner: minter,
            name: name,
            birthTime: block.timestamp,
            lastProductionTime: block.timestamp,
            pendingEssence: 0,
            lastInteractionTime: block.timestamp, // Can interact immediately
            individualReputation: 100, // Starting reputation
            activeTraitTypeIds: new uint256[](0) // Start with no traits
        });

        // Assign initial traits (example: start with level 1 of a few random or predefined traits)
         if (potentialTraitTypeIds.length > 0) {
             uint256 initialTraitCount = 2; // Example: give 2 random initial traits
             for (uint256 i = 0; i < initialTraitCount; i++) {
                 uint256 randomTraitIndex = uint256(keccak256(abi.encodePacked(block.timestamp, msg.sender, tokenId, i))) % potentialTraitTypeIds.length;
                 uint256 traitTypeId = potentialTraitTypeIds[randomTraitIndex];
                 // Add trait at level 1
                 organisms[tokenId].traits[traitTypeId] = 1;
                 organisms[tokenId].activeTraitTypeIds.push(traitTypeId);
             }
         }


        userOrganisms[minter].push(tokenId);
        ecosystemState.totalOrganisms++;

        emit OrganismMinted(tokenId, minter, name);
    }

    /**
     * @dev Gets detailed information about a specific organism.
     * @param organismId The ID of the organism.
     * @return A tuple containing organism details.
     */
    function getOrganismDetails(uint256 organismId)
        public
        view
        returns (
            uint256 tokenId,
            address owner,
            string memory name,
            uint256 birthTime,
            uint256 lastProductionTime,
            uint256 pendingEssence,
            uint256 lastInteractionTime,
            uint256 individualReputation,
            uint256[] memory activeTraitTypeIds,
            uint256[] memory traitLevels // Levels corresponding to activeTraitTypeIds
        )
    {
        Organism storage org = organisms[organismId];
        require(org.owner != address(0), "Organism does not exist");

        uint256[] memory currentTraitLevels = new uint256[](org.activeTraitTypeIds.length);
        for (uint256 i = 0; i < org.activeTraitTypeIds.length; i++) {
            currentTraitLevels[i] = org.traits[org.activeTraitTypeIds[i]];
        }

        return (
            org.tokenId,
            org.owner,
            org.name,
            org.birthTime,
            org.lastProductionTime,
            org.pendingEssence,
            org.lastInteractionTime,
            org.individualReputation,
            org.activeTraitTypeIds,
            currentTraitLevels
        );
    }

    /**
     * @dev Gets a list of organism IDs owned by a user.
     * @param user The address of the user.
     * @return An array of organism IDs.
     */
    function getUserOrganisms(address user) public view returns (uint256[] memory) {
        return userOrganisms[user];
    }

    // --- Trait Management ---

    /**
     * @dev Gets static details about a specific trait type.
     * @param traitTypeId The ID of the trait type.
     * @return A tuple containing trait type details.
     */
    function getTraitDetails(uint256 traitTypeId)
        public
        view
        returns (
            uint256 id,
            string memory name,
            string memory description,
            uint256 baseProductionBonus,
            uint256 baseInteractionBonus,
            uint256 baseUpgradeCost,
            uint256 baseAddCost,
            uint256 maxLevel
        )
    {
        TraitType storage t = traitTypes[traitTypeId];
        require(bytes(t.name).length > 0, "Trait type does not exist");
        return (
            t.id,
            t.name,
            t.description,
            t.baseProductionBonus,
            t.baseInteractionBonus,
            t.baseUpgradeCost,
            t.baseAddCost,
            t.maxLevel
        );
    }

    /**
     * @dev Allows an organism owner to upgrade a specific trait on their organism
     *      by consuming claimed essence. Cost increases with level and ecosystem state.
     * @param organismId The ID of the organism.
     * @param traitTypeId The ID of the trait type to upgrade.
     */
    function upgradeTrait(uint256 organismId, uint256 traitTypeId) public onlyOrganismOwner(organismId) whenNotPaused {
        Organism storage org = organisms[organismId];
        TraitType storage t = traitTypes[traitTypeId];
        require(bytes(t.name).length > 0, "Trait type does not exist");

        uint256 currentLevel = org.traits[traitTypeId];
        require(currentLevel > 0, "Organism does not have this trait");
        require(currentLevel < t.maxLevel, "Trait is already at max level");

        uint256 cost = getTraitUpgradeCost(organismId, traitTypeId);
        require(userClaimedEssence[msg.sender] >= cost, "Insufficient claimed essence");

        userClaimedEssence[msg.sender] -= cost;
        org.traits[traitTypeId] = currentLevel + 1;

        // Minor reputation update (example)
        _updateUserReputation(msg.sender, userReputationScores[msg.sender] + (currentLevel * 2) );
        _updateOrganismReputation(organismId, org.individualReputation + currentLevel);


        emit TraitUpgraded(organismId, traitTypeId, org.traits[traitTypeId]);
    }

    /**
     * @dev Allows an organism owner to add a new trait type to their organism
     *      by consuming claimed essence. Cost is based on the trait type and ecosystem state.
     * @param organismId The ID of the organism.
     * @param traitTypeId The ID of the trait type to add. Must be a potential trait type.
     */
    function addTrait(uint256 organismId, uint256 traitTypeId) public onlyOrganismOwner(organismId) whenNotPaused {
        Organism storage org = organisms[organismId];
        TraitType storage t = traitTypes[traitTypeId];
        require(bytes(t.name).length > 0, "Trait type does not exist");

        bool isPotential = false;
        for (uint256 i = 0; i < potentialTraitTypeIds.length; i++) {
            if (potentialTraitTypeIds[i] == traitTypeId) {
                isPotential = true;
                break;
            }
        }
        require(isPotential, "Trait type cannot be added");
        require(org.traits[traitTypeId] == 0, "Organism already has this trait");

        uint256 cost = getTraitAddCost(traitTypeId);
        require(userClaimedEssence[msg.sender] >= cost, "Insufficient claimed essence");

        userClaimedEssence[msg.sender] -= cost;
        org.traits[traitTypeId] = 1; // Add at level 1
        org.activeTraitTypeIds.push(traitTypeId);

         // Minor reputation update (example)
        _updateUserReputation(msg.sender, userReputationScores[msg.sender] + 5);
        _updateOrganismReputation(organismId, org.individualReputation + 5);

        emit TraitAdded(organismId, traitTypeId, 1);
    }

    /**
     * @dev Calculates the dynamic cost to upgrade a trait.
     * @param organismId The ID of the organism.
     * @param traitTypeId The ID of the trait type.
     * @return The essence cost for the upgrade.
     */
    function getTraitUpgradeCost(uint256 organismId, uint256 traitTypeId) public view returns (uint256) {
        Organism storage org = organisms[organismId];
        TraitType storage t = traitTypes[traitTypeId];
        require(org.traits[traitTypeId] > 0, "Organism does not have this trait"); // Must have the trait to upgrade
        require(bytes(t.name).length > 0, "Trait type does not exist");

        uint256 currentLevel = org.traits[traitTypeId];
        // Example cost calculation: base cost * current level * ecosystem multiplier
        // Add logic for 'Essence Conservation' trait if implemented
        return (t.baseUpgradeCost * currentLevel * ecosystemState.currentTraitUpgradeCostMultiplier) / 1000;
    }

    /**
     * @dev Calculates the dynamic cost to add a trait initially.
     * @param traitTypeId The ID of the trait type.
     * @return The essence cost to add the trait.
     */
    function getTraitAddCost(uint256 traitTypeId) public view returns (uint256) {
         TraitType storage t = traitTypes[traitTypeId];
         require(bytes(t.name).length > 0, "Trait type does not exist");

         // Example cost calculation: base add cost * ecosystem multiplier
         // Add logic for 'Essence Conservation' trait if implemented
         return (t.baseAddCost * ecosystemState.currentTraitAddCostMultiplier) / 1000;
    }


    // --- Essence Management ---

    /**
     * @dev Triggers essence production for an organism if its cooldown has passed.
     *      Calculates production amount based on traits and ecosystem state.
     * @param organismId The ID of the organism.
     */
    function produceEssence(uint256 organismId) public onlyOrganismOwner(organismId) whenNotPaused {
        Organism storage org = organisms[organismId];
        require(block.timestamp >= org.lastProductionTime + productionCooldown, "Production cooldown not met");

        uint256 productionAmount = ecosystemState.currentBaseProductionRate;
        uint256 totalTraitBonus = 0; // Sum of permille bonuses from traits

        // Calculate trait bonuses
        for (uint256 i = 0; i < org.activeTraitTypeIds.length; i++) {
            uint256 traitTypeId = org.activeTraitTypeIds[i];
            uint256 level = org.traits[traitTypeId];
            TraitType storage t = traitTypes[traitTypeId]; // Assuming traitType exists based on activeTraitTypeIds
            totalTraitBonus += (t.baseProductionBonus * level) / t.maxLevel; // Scale bonus by level relative to max
        }

        // Apply total trait bonus (e.g., 1000 permille = 100% bonus)
        productionAmount = (productionAmount * (1000 + totalTraitBonus)) / 1000;

        // Apply individual organism reputation bonus (example: 1% bonus per 100 reputation above base 100)
        if (org.individualReputation > 100) {
            productionAmount = (productionAmount * (1000 + (org.individualReputation - 100) / 10)) / 1000;
        }

        org.pendingEssence += productionAmount;
        org.lastProductionTime = block.timestamp;
        ecosystemState.totalPendingEssence += productionAmount;

        emit EssenceProduced(organismId, productionAmount);
    }

    /**
     * @dev Claims all pending essence from all of the caller's organisms and adds it
     *      to their claimed balance.
     */
    function claimEssence() public whenNotPaused {
        address user = msg.sender;
        uint256 totalPending = 0;

        for (uint256 i = 0; i < userOrganisms[user].length; i++) {
            uint256 organismId = userOrganisms[user][i];
            Organism storage org = organisms[organismId];
            totalPending += org.pendingEssence;
            ecosystemState.totalPendingEssence -= org.pendingEssence; // Deduct from global pending
            org.pendingEssence = 0; // Clear organism pending
        }

        if (totalPending > 0) {
            userClaimedEssence[user] += totalPending;
            ecosystemState.totalClaimedEssence += totalPending; // Add to global claimed
            emit EssenceClaimed(user, totalPending);
        }
    }

    /**
     * @dev Gets the amount of essence an organism has produced but not yet claimed.
     * @param organismId The ID of the organism.
     * @return The pending essence amount.
     */
    function getPendingEssence(uint256 organismId) public view returns (uint256) {
        require(organisms[organismId].owner != address(0), "Organism does not exist");
        return organisms[organismId].pendingEssence;
    }

    /**
     * @dev Gets the total claimed essence balance for a user.
     * @param user The address of the user.
     * @return The claimed essence balance.
     */
    function getUserClaimedEssence(address user) public view returns (uint256) {
        return userClaimedEssence[user];
    }

    // --- Interaction Logic ---

    /**
     * @dev Simulates a symbiotic interaction between two organisms.
     *      Requires interaction cooldown to have passed for both.
     *      Checks if caller is owner or delegate of both.
     *      Outcome based on combined interaction strength/reputation.
     *      Consumes a small amount of essence from each participant's owner.
     *      Grants reputation and potentially small bonuses.
     * @param organism1Id The ID of the first organism.
     * @param organism2Id The ID of the second organism.
     */
    function interactSymbiotic(uint256 organism1Id, uint256 organism2Id) public whenNotPaused {
        require(organism1Id != organism2Id, "Cannot interact with self");
        Organism storage org1 = organisms[organism1Id];
        Organism storage org2 = organisms[organism2Id];
        require(org1.owner != address(0) && org2.owner != address(0), "One or both organisms do not exist");
        require(block.timestamp >= org1.lastInteractionTime + interactionCooldown, "Organism 1 cooldown not met");
        require(block.timestamp >= org2.lastInteractionTime + interactionCooldown, "Organism 2 cooldown not met");

        // Check caller is owner or delegate for BOTH
        require(
            org1.owner == msg.sender || interactionDelegates[organism1Id] == msg.sender,
            "Not authorized for Organism 1"
        );
         require(
            org2.owner == msg.sender || interactionDelegates[organism2Id] == msg.sender,
            "Not authorized for Organism 2"
        );

        // Consume essence from owners
        require(userClaimedEssence[org1.owner] >= interactionEssenceCost, "Owner of Organism 1 needs essence");
        require(userClaimedEssence[org2.owner] >= interactionEssenceCost, "Owner of Organism 2 needs essence");
        userClaimedEssence[org1.owner] -= interactionEssenceCost;
        userClaimedEssence[org2.owner] -= interactionEssenceCost;
         ecosystemState.totalClaimedEssence -= (interactionEssenceCost * 2); // Update global

        // Simulate outcome based on combined interaction factors (simplified)
        uint256 score1 = _getInteractionScore(organism1Id);
        uint256 score2 = _getInteractionScore(organism2Id);

        // Symbiotic outcome: usually positive, strength based on combined score
        uint256 combinedScore = score1 + score2;
        string memory outcome = "Successful Symbiosis";
        uint256 reputationGain = reputationGainOnSymbioticSuccess + (combinedScore / 200); // Example: add bonus based on score

        _updateUserReputation(org1.owner, userReputationScores[org1.owner] + reputationGain);
        _updateUserReputation(org2.owner, userReputationScores[org2.owner] + reputationGain);
        _updateOrganismReputation(organism1Id, org1.individualReputation + (reputationGain / 2));
        _updateOrganismReputation(organism2Id, org2.individualReputation + (reputationGain / 2));

        // Potentially add minor trait boosts temporarily or permanently (example - not implemented fully)
        // for (uint256 i = 0; i < org1.activeTraitTypeIds.length; i++) { /* boost trait */ }
        // for (uint256 i = 0; i < org2.activeTraitTypeIds.length; i++) { /* boost trait */ }


        org1.lastInteractionTime = block.timestamp;
        org2.lastInteractionTime = block.timestamp;

        emit SymbioticInteraction(organism1Id, organism2Id, outcome);
    }

    /**
     * @dev Simulates a competitive interaction between two organisms.
     *      Requires interaction cooldown to have passed for both.
     *      Checks if caller is owner or delegate of both.
     *      Outcome based on combined interaction strength/reputation and randomness.
     *      Consumes a small amount of essence from each participant's owner.
     *      One organism wins (gains reputation/essence), the other loses (loses reputation).
     * @param organism1Id The ID of the first organism.
     * @param organism2Id The ID of the second organism.
     */
    function interactCompetitive(uint256 organism1Id, uint256 organism2Id) public whenNotPaused {
        require(organism1Id != organism2Id, "Cannot interact with self");
        Organism storage org1 = organisms[organism1Id];
        Organism storage org2 = organisms[organism2Id];
        require(org1.owner != address(0) && org2.owner != address(0), "One or both organisms do not exist");
        require(block.timestamp >= org1.lastInteractionTime + interactionCooldown, "Organism 1 cooldown not met");
        require(block.timestamp >= org2.lastInteractionTime + interactionCooldown, "Organism 2 cooldown not met");

         // Check caller is owner or delegate for BOTH
        require(
            org1.owner == msg.sender || interactionDelegates[organism1Id] == msg.sender,
            "Not authorized for Organism 1"
        );
         require(
            org2.owner == msg.sender || interactionDelegates[organism2Id] == msg.sender,
            "Not authorized for Organism 2"
        );

        // Consume essence from owners
        require(userClaimedEssence[org1.owner] >= interactionEssenceCost, "Owner of Organism 1 needs essence");
        require(userClaimedEssence[org2.owner] >= interactionEssenceCost, "Owner of Organism 2 needs essence");
        userClaimedEssence[org1.owner] -= interactionEssenceCost;
        userClaimedEssence[org2.owner] -= interactionEssenceCost;
        ecosystemState.totalClaimedEssence -= (interactionEssenceCost * 2); // Update global


        // Simulate outcome based on combined interaction factors and randomness
        uint256 score1 = _getInteractionScore(organism1Id);
        uint256 score2 = _getInteractionScore(organism2Id);

        // Add randomness based on block data
        uint256 randomFactor = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, msg.sender, organism1Id, organism2Id)));

        uint256 effectiveScore1 = score1 + (randomFactor % 100); // Add up to +99 randomness
        uint256 effectiveScore2 = score2 + ((randomFactor / 100) % 100); // Add a different random factor

        uint256 winnerId;
        uint256 loserId;
        string memory outcome;

        if (effectiveScore1 > effectiveScore2) {
            winnerId = organism1Id;
            loserId = organism2Id;
            outcome = "Organism 1 Won";
        } else if (effectiveScore2 > effectiveScore1) {
            winnerId = organism2Id;
            loserId = organism1Id;
            outcome = "Organism 2 Won";
        } else {
             // Tie - less likely with randomness, but possible
            winnerId = 0; // Indicate tie
            loserId = 0;
            outcome = "Competitive Draw";
            // No reputation change, maybe return essence cost or reduce it
             userClaimedEssence[org1.owner] += interactionEssenceCost; // Return cost
             userClaimedEssence[org2.owner] += interactionEssenceCost; // Return cost
             ecosystemState.totalClaimedEssence += (interactionEssenceCost * 2); // Update global back
        }

        if (winnerId != 0) {
            address winnerOwner = organisms[winnerId].owner;
            address loserOwner = organisms[loserId].owner;

            // Apply reputation changes
            _updateUserReputation(winnerOwner, userReputationScores[winnerOwner] + reputationGainOnCompetitiveWin);
            _updateUserReputation(loserOwner, userReputationScores[loserOwner] > reputationLossOnCompetitiveLoss ? userReputationScores[loserOwner] - reputationLossOnCompetitiveLoss : 0);
            _updateOrganismReputation(winnerId, organisms[winnerId].individualReputation + (reputationGainOnCompetitiveWin / 2));
             _updateOrganismReputation(loserId, organisms[loserId].individualReputation > (reputationLossOnCompetitiveLoss / 2) ? organisms[loserId].individualReputation - (reputationLossOnCompetitiveLoss / 2) : 0);

            // Winner gets some bonus essence (example)
            uint256 winnerBonus = interactionEssenceCost; // Winner gets their essence cost back and a bonus equal to one cost
            userClaimedEssence[winnerOwner] += winnerBonus;
            ecosystemState.totalClaimedEssence += winnerBonus; // Update global

            // Potentially apply temporary stat debuff to loser organism (not implemented fully)
        }


        org1.lastInteractionTime = block.timestamp;
        org2.lastInteractionTime = block.timestamp;

        emit CompetitiveInteraction(winnerId, loserId, outcome);
    }

    /**
     * @dev Internal helper to calculate an organism's interaction score based on traits and reputation.
     * @param organismId The ID of the organism.
     * @return The calculated interaction score.
     */
    function _getInteractionScore(uint256 organismId) internal view returns (uint256) {
         Organism storage org = organisms[organismId];
         uint256 score = org.individualReputation; // Base score is reputation

         // Add trait bonuses
         uint256 totalTraitBonus = 0; // Sum of permille bonuses
         for (uint256 i = 0; i < org.activeTraitTypeIds.length; i++) {
            uint256 traitTypeId = org.activeTraitTypeIds[i];
            uint256 level = org.traits[traitTypeId];
            TraitType storage t = traitTypes[traitTypeId]; // Assuming traitType exists
             totalTraitBonus += (t.baseInteractionBonus * level) / t.maxLevel; // Scale bonus by level relative to max
         }

         score = (score * (1000 + totalTraitBonus)) / 1000; // Apply trait bonus

         // Add user reputation bonus (example: 1% bonus per 100 user reputation above base 100)
         if (userReputationScores[org.owner] > 100) {
             score = (score * (1000 + (userReputationScores[org.owner] - 100) / 10)) / 1000;
         }

         return score;
    }

    // --- Reputation Management ---

    /**
     * @dev Views the reputation score for a given user address.
     * @param user The address to query.
     * @return The user's reputation score.
     */
    function getUserReputation(address user) public view returns (uint256) {
        return userReputationScores[user];
    }

     /**
     * @dev Views the individual reputation score for a given organism.
     * @param organismId The ID of the organism.
     * @return The organism's individual reputation score.
     */
    function getOrganismReputation(uint256 organismId) public view returns (uint256) {
        require(organisms[organismId].owner != address(0), "Organism does not exist");
        return organisms[organismId].individualReputation;
    }


    /**
     * @dev Internal function to update a user's reputation score.
     * @param user The address to update.
     * @param newReputation The new reputation score. Capped at a max (e.g., 1000).
     */
    function _updateUserReputation(address user, uint256 newReputation) internal {
        uint256 cappedReputation = newReputation;
        // Example cap: 1000
        if (cappedReputation > 1000) {
            cappedReputation = 1000;
        }
         // Example min: 0
         if (cappedReputation < 0) { // Note: uint will wrap if negative, but logical check
             cappedReputation = 0;
         }
        userReputationScores[user] = cappedReputation;
        emit UserReputationUpdated(user, cappedReputation);
    }

     /**
     * @dev Internal function to update an organism's individual reputation score.
     * @param organismId The ID of the organism.
     * @param newReputation The new reputation score. Capped at a max (e.g., 500).
     */
    function _updateOrganismReputation(uint256 organismId, uint256 newReputation) internal {
        Organism storage org = organisms[organismId];
        uint256 cappedReputation = newReputation;
        // Example cap: 500
        if (cappedReputation > 500) {
            cappedReputation = 500;
        }
         // Example min: 0
         if (cappedReputation < 0) {
             cappedReputation = 0;
         }
        org.individualReputation = cappedReputation;
        emit OrganismReputationUpdated(organismId, cappedReputation);
    }


    // --- Delegation Management ---

    /**
     * @dev Allows an organism owner to delegate the ability to trigger interactions
     *      for a specific organism to another address.
     * @param organismId The ID of the organism.
     * @param delegatee The address to delegate interaction rights to. Address(0) to clear.
     */
    function delegateInteraction(uint256 organismId, address delegatee) public onlyOrganismOwner(organismId) {
        interactionDelegates[organismId] = delegatee;
        emit InteractionDelegated(organismId, delegatee);
    }

    /**
     * @dev Allows an organism owner to revoke any existing interaction delegation
     *      for a specific organism.
     * @param organismId The ID of the organism.
     */
    function revokeDelegateInteraction(uint256 organismId) public onlyOrganismOwner(organismId) {
        require(interactionDelegates[organismId] != address(0), "No active delegation to revoke");
        delete interactionDelegates[organismId];
        emit InteractionDelegationRevoked(organismId);
    }

    // --- Ecosystem Adaptation ---

    /**
     * @dev Triggers an adaptation cycle for the ecosystem if the cooldown has passed.
     *      This recalculates global parameters based on the current state.
     *      Can be called by anyone, potentially with a small gas incentive.
     */
    function triggerAdaptationCycle() public whenNotPaused {
        require(block.timestamp >= ecosystemState.lastAdaptationTime + adaptationCycleCooldown, "Adaptation cycle cooldown not met");

        _triggerAdaptationCycle();
    }

    /**
     * @dev Internal function containing the adaptation logic.
     *      Recalculates parameters based on the current ecosystem state.
     *      Simplified example: if total essence is high, increase upgrade costs.
     *      If organism count is low, increase base production.
     */
    function _triggerAdaptationCycle() internal {
        uint256 currentOrganismCount = ecosystemState.totalOrganisms;
        uint256 currentTotalEssence = ecosystemState.totalClaimedEssence + ecosystemState.totalPendingEssence;

        // Example Adaptation Logic:
        uint256 newBaseProductionRate = baseProductionAmountPerCycle;
        uint256 newUpgradeCostMultiplier = 1000; // 100%
        uint256 newAddCostMultiplier = 1000; // 100%

        // If essence is abundant, increase costs
        if (currentTotalEssence > currentOrganismCount * 1000) { // Arbitrary threshold
            newUpgradeCostMultiplier = (newUpgradeCostMultiplier * 1200) / 1000; // +20%
            newAddCostMultiplier = (newAddCostMultiplier * 1200) / 1000; // +20%
        } else if (currentTotalEssence < currentOrganismCount * 200) { // Arbitrary threshold
             // If essence is scarce, decrease costs
             newUpgradeCostMultiplier = (newUpgradeCostMultiplier * 800) / 1000; // -20%
             newAddCostMultiplier = (newAddCostMultiplier * 800) / 1000; // -20%
        }

        // If organisms are few, boost production
        if (currentOrganismCount < 100) { // Arbitrary threshold
            newBaseProductionRate = (baseProductionAmountPerCycle * 1100) / 1000; // +10%
        } else if (currentOrganismCount > 1000) { // Arbitrary threshold
             // If organisms are many, slightly decrease production
             newBaseProductionRate = (baseProductionAmountPerCycle * 950) / 1000; // -5%
        }


        // Apply reasonable bounds (e.g., multiplier min/max)
        if (newUpgradeCostMultiplier < 500) newUpgradeCostMultiplier = 500; // Min 50% cost
        if (newUpgradeCostMultiplier > 2000) newUpgradeCostMultiplier = 2000; // Max 200% cost
         if (newAddCostMultiplier < 500) newAddCostMultiplier = 500; // Min 50% cost
        if (newAddCostMultiplier > 2000) newAddCostMultiplier = 2000; // Max 200% cost
         if (newBaseProductionRate < baseProductionAmountPerCycle / 2) newBaseProductionRate = baseProductionAmountPerCycle / 2; // Min 50% base prod
         if (newBaseProductionRate > baseProductionAmountPerCycle * 2) newBaseProductionRate = baseProductionAmountPerCycle * 2; // Max 200% base prod


        ecosystemState.currentBaseProductionRate = newBaseProductionRate;
        ecosystemState.currentTraitUpgradeCostMultiplier = newUpgradeCostMultiplier;
        ecosystemState.currentTraitAddCostMultiplier = newAddCostMultiplier;
        ecosystemState.adaptationCycleCount++;
        ecosystemState.lastAdaptationTime = block.timestamp;

        emit AdaptationCycleTriggered(
            ecosystemState.adaptationCycleCount,
            currentOrganismCount,
            currentTotalEssence
        );
    }

    /**
     * @dev Views the current global ecosystem state parameters.
     * @return A tuple containing ecosystem state details.
     */
    function getEcosystemState()
        public
        view
        returns (
            uint256 totalOrganisms,
            uint256 totalClaimedEssence,
            uint256 totalPendingEssence,
            uint256 adaptationCycleCount,
            uint256 lastAdaptationTime,
            uint256 currentBaseProductionRate,
            uint256 currentTraitUpgradeCostMultiplier,
            uint256 currentTraitAddCostMultiplier
        )
    {
        return (
            ecosystemState.totalOrganisms,
            ecosystemState.totalClaimedEssence,
            ecosystemState.totalPendingEssence,
            ecosystemState.adaptationCycleCount,
            ecosystemState.lastAdaptationTime,
            ecosystemState.currentBaseProductionRate,
            ecosystemState.currentTraitUpgradeCostMultiplier,
            ecosystemState.currentTraitAddCostMultiplier
        );
    }


    // --- Parameter Management (Owner Only) ---

    /**
     * @dev Owner function to set base configuration parameters.
     */
    function setBaseParameters(
        uint256 _baseProd,
        uint256 _baseUpgradeCost,
        uint256 _baseAddCost, // Added for add cost
        uint256 _prodCooldown,
        uint256 _interactCooldown,
        uint256 _adaptationCooldown
    ) public onlyOwner {
        baseProductionAmountPerCycle = _baseProd;
        // Note: BaseUpgradeCost and BaseAddCost set per TraitType
        productionCooldown = _prodCooldown;
        interactionCooldown = _interactCooldown;
        adaptationCycleCooldown = _adaptationCooldown;
        // Does NOT affect currentBaseProductionRate, which is dynamic
    }

    /**
     * @dev Owner function to define a new type of trait that organisms can potentially acquire/upgrade.
     */
    function addPotentialTraitType(
        string memory name,
        string memory description,
        uint256 baseProdBonus, // Permille
        uint256 baseInteractBonus, // Permille
        uint256 baseUpgradeCost,
        uint256 baseAddCost,
        uint256 maxLevel
    ) public onlyOwner {
        uint256 traitTypeId = _nextTraitTypeId++;
        traitTypes[traitTypeId] = TraitType({
            id: traitTypeId,
            name: name,
            description: description,
            baseProductionBonus: baseProdBonus,
            baseInteractionBonus: baseInteractBonus,
            baseUpgradeCost: baseUpgradeCost,
            baseAddCost: baseAddCost,
            maxLevel: maxLevel
        });
        potentialTraitTypeIds.push(traitTypeId);
    }

     /**
     * @dev Internal helper to add a trait type. Used in constructor and addPotentialTraitType.
     */
    function _addPotentialTraitType(
        string memory name,
        string memory description,
        uint256 baseProdBonus, // Permille
        uint256 baseInteractBonus, // Permille
        uint256 baseUpgradeCost,
        uint256 baseAddCost,
        uint256 maxLevel
    ) internal {
        uint256 traitTypeId = _nextTraitTypeId++;
        traitTypes[traitTypeId] = TraitType({
            id: traitTypeId,
            name: name,
            description: description,
            baseProductionBonus: baseProdBonus,
            baseInteractionBonus: baseInteractBonus,
            baseUpgradeCost: baseUpgradeCost,
            baseAddCost: baseAddCost,
            maxLevel: maxLevel
        });
        potentialTraitTypeIds.push(traitTypeId);
    }


    /**
     * @dev Views the list of all defined potential trait type IDs.
     */
    function getPotentialTraitTypes() public view returns (uint256[] memory) {
        return potentialTraitTypeIds;
    }

    /**
     * @dev Owner function to pause or unpause core ecosystem activities.
     * @param _paused Whether the ecosystem should be paused (true) or unpaused (false).
     */
    function pauseEcosystem(bool _paused) public onlyOwner {
        paused = _paused;
        emit EcosystemPaused(_paused);
    }

    // --- Utility Views ---

    /**
     * @dev Gets the total count of organisms that exist.
     * @return The total number of organisms.
     */
    function getTotalOrganisms() public view returns (uint256) {
        return ecosystemState.totalOrganisms;
    }

    /**
     * @dev Gets the time when an organism can next trigger production.
     * @param organismId The ID of the organism.
     * @return The timestamp of the next available production time.
     */
    function getProductionCooldown(uint256 organismId) public view returns (uint256) {
         require(organisms[organismId].owner != address(0), "Organism does not exist");
         return organisms[organismId].lastProductionTime + productionCooldown;
    }

     /**
     * @dev Gets the time when an organism can next participate in an interaction.
     * @param organismId The ID of the organism.
     * @return The timestamp of the next available interaction time.
     */
    function getInteractionCooldown(uint256 organismId) public view returns (uint256) {
         require(organisms[organismId].owner != address(0), "Organism does not exist");
         return organisms[organismId].lastInteractionTime + interactionCooldown;
    }

     /**
     * @dev Gets the owner of a specific organism (simulating ERC-721 ownerOf).
     * @param organismId The ID of the organism.
     * @return The owner's address, or address(0) if not found.
     */
    function getOrganismOwner(uint256 organismId) public view returns (address) {
         return organisms[organismId].owner;
    }

    // Add more utility functions as needed, e.g., get total claimed essence, get total pending essence etc.
    // (Covered by getEcosystemState and getUserClaimedEssence already)

     // We need at least 20 functions, let's double check...
     // 1. constructor
     // 2. mintOrganism
     // 3. getOrganismDetails
     // 4. getUserOrganisms
     // 5. getTraitDetails
     // 6. produceEssence
     // 7. claimEssence
     // 8. getPendingEssence (Organism)
     // 9. getUserClaimedEssence (User)
     // 10. upgradeTrait
     // 11. addTrait
     // 12. interactSymbiotic
     // 13. interactCompetitive
     // 14. getUserReputation
     // 15. getOrganismReputation
     // 16. delegateInteraction
     // 17. revokeDelegateInteraction
     // 18. triggerAdaptationCycle
     // 19. getEcosystemState
     // 20. setBaseParameters (Owner)
     // 21. addPotentialTraitType (Owner)
     // 22. getPotentialTraitTypes
     // 23. getTraitUpgradeCost (View)
     // 24. getTraitAddCost (View)
     // 25. getTotalOrganisms (View)
     // 26. getProductionCooldown (View)
     // 27. getInteractionCooldown (View)
     // 28. getOrganismOwner (View - sim ERC721)
     // 29. pauseEcosystem (Owner)

     // Yes, we have 29 public/external functions, exceeding the minimum 20.
}
```