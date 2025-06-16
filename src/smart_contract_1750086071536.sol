Okay, here is a Solidity smart contract example incorporating an interesting, advanced-concept centered around "Evolving Digital Organisms" (EDOs). This contract isn't based on standard patterns like ERC721 directly (though it manages ownership), and focuses on internal state management, resource interaction, and dynamic evolution mechanics.

It features:
*   **Dynamic State:** Organisms have properties that change over time and based on interaction (vitality, energy, traits, evolution stage).
*   **Resource Pool:** A shared pool of 'Essence' (represented by contract balance) that organisms consume from to stay alive and evolve. Users deposit Essence into this pool.
*   **Decay Mechanics:** Organisms lose vitality over time if not sustained.
*   **Evolution System:** Organisms can evolve through stages based on criteria like feeding, stimulation, and time.
*   **Dynamic Traits:** Organisms have traits that can change or unlock through interaction and evolution.
*   **Inter-Organism Interaction:** Organisms can potentially interact with each other (e.g., 'attuning').
*   **Sacrifice Mechanic:** Organisms can be sacrificed for potential benefits.

This concept is designed to be non-standard and illustrate a system where digital assets have internal life-cycles and interactive states beyond simple ownership and metadata.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title EvolvingDigitalOrganisms
 * @dev A smart contract managing dynamic digital organisms that require sustenance,
 *      can evolve, possess dynamic traits, and interact within a shared resource pool.
 *      This is a conceptual, non-standard asset system.
 */

/*
Outline:
1.  State Variables: Contract owner, counters, costs, Essence pool, organism data storage.
2.  Structs: Organism definition (vitality, energy, traits, stage, timestamps, etc.).
3.  Events: Minting, feeding, evolution, death, trait changes, resource deposit/withdrawal, sacrifice.
4.  Modifiers: onlyOwner.
5.  Internal Helpers: Vitality calculation/decay, trait calculation, checking organism status.
6.  Core Functions: Minting, feeding, stimulating, evolving.
7.  Resource Management Functions: Depositing/withdrawing Essence, setting costs.
8.  Organism Interaction Functions: Attuning, sacrificing.
9.  Dynamic Trait Functions: Modifying/viewing traits (mostly internal logic triggered by core functions).
10. Status/Query Functions: Checking state, getting details, querying evolution needs, getting counts.
11. Admin Functions: Setting parameters, emergency transfers/withdrawals.
*/

/*
Function Summary:

Core Lifecycle & Interaction:
1.  constructor() - Initializes the contract owner.
2.  mintOrganism() - Creates a new digital organism for the caller, deducting cost from deposit.
3.  feedOrganism(uint256 organismId) - Sustains an organism, increasing vitality/energy, using Essence from the pool.
4.  stimulateOrganism(uint256 organismId) - Interacts with an organism for potential state changes (e.g., trait effects), using energy.
5.  evolveOrganism(uint256 organismId) - Attempts to evolve an organism to the next stage based on criteria.
6.  attuneOrganism(uint256 organism1Id, uint256 organism2Id) - Allows two organisms to interact, potentially transferring energy/vitality with loss.
7.  sacrificeOrganism(uint256 organismId) - Permanently destroys an organism, potentially yielding a benefit or returning some Essence.
8.  tryManifestTrait(uint256 organismId) - A risky action that might unlock or alter a trait.

Resource & Admin:
9.  depositEssence() - Allows users to deposit ETH into the contract's shared Essence pool.
10. adminWithdrawEssence(uint256 amount) - Allows the owner to withdraw ETH from the contract balance (Essence pool).
11. setMintCost(uint256 cost) - Owner sets the cost to mint a new organism.
12. setSustainCostBase(uint256 cost) - Owner sets the base cost to feed an organism.
13. setStageEssenceCostModifier(uint256 stage, uint256 modifierFactor) - Owner sets a cost modifier for feeding based on evolution stage.
14. adminTransferOrganism(uint256 organismId, address newOwner) - Owner can transfer an organism (e.g., for support).

Status & Query (View Functions):
15. getOrganismState(uint256 organismId) - Get the full state details of an organism.
16. getOrganismOwner(uint256 organismId) - Get the owner of an organism.
17. getOwnerOrganismCount(address owner) - Get the number of organisms owned by an address.
18. getTotalEssencePool() - Get the total ETH balance held by the contract (representing the Essence pool).
19. getTotalOrganismsMinted() - Get the total number of organisms ever minted.
20. getOrganismDynamicTraits(uint256 organismId) - Get the array of dynamic trait values for an organism.
21. calculateCurrentVitality(uint256 organismId) - Calculate the organism's current vitality considering decay since last update.
22. checkOrganismStatus(uint256 organismId) - Get a simple status (Alive, Dormant, Deceased).
23. queryEvolutionCriteria(uint256 organismId) - See what conditions are needed for the organism's next evolution.
24. getTotalOrganismsByStage(uint256 stage) - Get the count of organisms currently at a specific evolution stage.
25. getSustainCost(uint256 organismId) - Calculate the current cost to feed an organism based on its stage.
*/

contract EvolvingDigitalOrganisms {

    address public owner;

    uint256 private _totalOrganismsMinted;
    uint256 public mintCost = 0.01 ether; // Initial mint cost
    uint256 public sustainCostBase = 0.001 ether; // Base cost to feed

    // Represents the total ETH sent to the contract by users for the Essence pool.
    // EDOs consume from this conceptual pool via required payments for actions.
    // Contract balance is the true pool. This variable is more conceptual/tracked.
    // However, for simplicity in this example, we'll treat contract balance as the pool.
    // Note: In a real scenario, using a specific ERC20 as Essence or managing internal credits
    // might be better to avoid direct ETH dependency for actions other than deposit.
    // For this example, 'depositEssence' adds to contract balance, and actions require msg.value
    // equal to the cost, which also implicitly goes to the contract balance.
    // We'll use `address(this).balance` directly for the pool amount.

    // Mapping for stage-specific feeding cost modifiers (e.g., stage 1 = 1x, stage 2 = 1.2x, etc.)
    // Stored as basis points (e.g., 10000 for 1x, 12000 for 1.2x)
    mapping(uint256 => uint256) public stageEssenceCostModifiers; // stage => basis points modifier

    // --- Structs ---
    struct Organism {
        uint256 vitality; // Represents health/lifeforce (0-100)
        uint256 energy;   // Represents energy for actions (0-100)
        uint256 evolutionStage; // Current stage (starts at 0)
        uint256 lastFedTime; // Timestamp of last successful feeding
        uint256 lastStimulatedTime; // Timestamp of last stimulation
        uint256 creationTime; // Timestamp of creation

        // Dynamic traits - simple uint256 array.
        // Index 0: Resilience, Index 1: Agility, Index 2: Intellect, Index 3: Charisma, Index 4: Mutability
        // Values 0-100. Can be influenced by actions.
        uint256[5] dynamicTraits;

        bool isDead; // If vitality hits 0
        address owner; // Redundant with mapping below, but useful in the struct for direct access
    }

    // --- State Storage ---
    mapping(uint256 => Organism) private organisms;
    mapping(address => uint256) private ownerOrganismCount;
    mapping(uint256 => address) private organismOwners; // organismId => owner address
    mapping(uint256 => uint256) private organismsByStageCount; // stage => count

    // --- Events ---
    event OrganismMinted(uint256 indexed organismId, address indexed owner, uint256 creationTime);
    event OrganismFed(uint256 indexed organismId, uint256 newVitality, uint256 newEnergy);
    event OrganismStimulated(uint256 indexed organismId, uint256 newEnergy, uint256[5] currentTraits);
    event OrganismEvolved(uint256 indexed organismId, uint256 newStage, uint256 newVitality, uint256 newEnergy);
    event OrganismDied(uint256 indexed organismId, address indexed owner);
    event TraitChanged(uint256 indexed organismId, uint256 indexed traitIndex, uint256 oldValue, uint256 newValue);
    event EssenceDeposited(address indexed user, uint256 amount);
    event EssenceWithdrawn(address indexed admin, uint256 amount);
    event OrganismSacrificed(uint256 indexed organismId, address indexed originalOwner, uint256 returnedEssence);
    event OrganismsAttuned(uint256 indexed organism1Id, uint256 indexed organism2Id);
    event OrganismTransferred(uint256 indexed organismId, address indexed oldOwner, address indexed newOwner);
    event TraitManifestAttempt(uint256 indexed organismId, bool success, uint256[5] newTraits);

    // --- Modifiers ---
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }

    // --- Constructor ---
    constructor() {
        owner = msg.sender;
        _totalOrganismsMinted = 0;
        // Set initial stage cost modifiers (e.g., stage 0 & 1 cost 1x base)
        stageEssenceCostModifiers[0] = 10000; // 100%
        stageEssenceCostModifiers[1] = 10000; // 100%
        stageEssenceCostModifiers[2] = 12000; // 120%
        stageEssenceCostModifiers[3] = 15000; // 150%
        stageEssenceCostModifiers[4] = 20000; // 200%
        // Higher stages will default to 0 modifier, effectively making feeding free
        // unless explicitly set higher by owner.
    }

    // --- Internal Helpers ---

    /**
     * @dev Calculates decay and updates vitality/energy based on time since last fed.
     *      Sets isDead flag if vitality reaches zero.
     * @param organismId The ID of the organism to update.
     */
    function _updateVitality(uint256 organismId) internal {
        Organism storage organism = organisms[organismId];
        if (organism.isDead) {
            return;
        }

        uint256 timePassed = block.timestamp - organism.lastFedTime;
        // Simple decay: lose 1 vitality per hour, plus more based on stage
        uint256 decayRate = 1 + (organism.evolutionStage / 2); // e.g., stage 0/1: 1, stage 2/3: 2, stage 4/5: 3
        uint256 potentialDecay = (timePassed / 1 hours) * decayRate;

        if (potentialDecay > 0) {
            if (organism.vitality <= potentialDecay) {
                organism.vitality = 0;
                organism.isDead = true;
                emit OrganismDied(organismId, organism.owner);
            } else {
                organism.vitality -= potentialDecay;
            }
            // Energy also decays, maybe faster or differently
            uint256 energyDecay = (timePassed / 30 minutes) * decayRate; // Faster energy decay
             if (organism.energy <= energyDecay) {
                organism.energy = 0;
             } else {
                organism.energy -= energyDecay;
             }
        }

        // Update lastFedTime only if a decay period has passed (to avoid timestamp manipulation griefing)
        // Or simpler: just update it whenever _updateVitality is called, assuming it's called by
        // functions that require user interaction anyway. Let's stick to updating only on actual feed.
        // The decay calculation *uses* lastFedTime but doesn't update it here.
    }

     /**
     * @dev Checks the current status of an organism.
     * @param organismId The ID of the organism.
     * @return 0: Alive, 1: Dormant (low vitality/energy), 2: Deceased.
     */
    function _getOrganismStatusCode(uint256 organismId) internal view returns (uint256) {
         Organism storage organism = organisms[organismId]; // Use storage for potential internal use, view external function uses memory
        if (organism.isDead) return 2; // Deceased
        if (organism.vitality < 20 || organism.energy < 10) return 1; // Dormant
        return 0; // Alive
    }


    // --- Core Lifecycle & Interaction Functions ---

    /**
     * @dev Mints a new digital organism.
     *      Requires sending `mintCost` ETH with the transaction, which goes to the contract pool.
     */
    function mintOrganism() external payable {
        require(msg.value >= mintCost, "Insufficient ETH for minting");
        require(_totalOrganismsMinted < type(uint256).max, "Max organisms minted");

        _totalOrganismsMinted++;
        uint256 newOrganismId = _totalOrganismsMinted;

        Organism storage newOrganism = organisms[newOrganismId];
        newOrganism.vitality = 50; // Start with partial vitality
        newOrganism.energy = 30;   // Start with partial energy
        newOrganism.evolutionStage = 0;
        newOrganism.lastFedTime = block.timestamp;
        newOrganism.lastStimulatedTime = block.timestamp;
        newOrganism.creationTime = block.timestamp;
        newOrganism.isDead = false;
        newOrganism.owner = msg.sender;

        // Initialize random-ish traits based on block data (simple non-secure randomness)
        uint256 seed = uint256(keccak256(abi.encodePacked(block.timestamp, msg.sender, newOrganismId, block.difficulty)));
        for (uint i = 0; i < 5; i++) {
             newOrganism.dynamicTraits[i] = uint8((seed >> (i * 8)) % 50 + 25); // Traits initialized between 25-75
        }

        organismOwners[newOrganismId] = msg.sender;
        ownerOrganismCount[msg.sender]++;
        organismsByStageCount[0]++;

        emit OrganismMinted(newOrganismId, msg.sender, block.timestamp);

        // The received ETH automatically increases address(this).balance, contributing to the conceptual pool.
    }

    /**
     * @dev Feeds an organism, increasing vitality and energy.
     *      Requires sending the calculated sustain cost in ETH, which goes to the contract pool.
     * @param organismId The ID of the organism to feed.
     */
    function feedOrganism(uint256 organismId) external payable {
        Organism storage organism = organisms[organismId];
        require(organismOwners[organismId] == msg.sender, "Not your organism");
        _updateVitality(organismId); // Update state before action
        require(!organism.isDead, "Organism is deceased");

        uint256 requiredCost = getSustainCost(organismId);
        require(msg.value >= requiredCost, "Insufficient ETH for feeding");

        // Refund excess ETH if sent
        if (msg.value > requiredCost) {
            payable(msg.sender).transfer(msg.value - requiredCost);
        }

        // Increase vitality and energy, cap at 100
        organism.vitality = min(organism.vitality + 20, 100); // Feeding gives a good vitality boost
        organism.energy = min(organism.energy + 30, 100);   // Feeding gives a significant energy boost
        organism.lastFedTime = block.timestamp; // Only update lastFedTime on successful feed

        emit OrganismFed(organismId, organism.vitality, organism.energy);

         // The received ETH automatically increases address(this).balance, contributing to the conceptual pool.
    }

     /**
     * @dev Stimulates an organism, using energy and potentially affecting traits.
     * @param organismId The ID of the organism to stimulate.
     */
    function stimulateOrganism(uint256 organismId) external {
        Organism storage organism = organisms[organismId];
        require(organismOwners[organismId] == msg.sender, "Not your organism");
        _updateVitality(organismId); // Update state before action
        require(!organism.isDead, "Organism is deceased");
        require(organism.energy >= 10, "Not enough energy to stimulate"); // Stimulation costs energy

        organism.energy -= 10;
        organism.lastStimulatedTime = block.timestamp;

        // Simple random trait effect based on energy and time (non-secure)
         uint256 seed = uint256(keccak256(abi.encodePacked(block.timestamp, msg.sender, organismId, organism.energy)));
         uint256 traitIndex = seed % 5;
         int256 change = int256(seed % 11) - 5; // Change between -5 and +5

         uint256 oldValue = organism.dynamicTraits[traitIndex];
         int256 newValueSigned = int256(oldValue) + change;

         if (newValueSigned < 0) newValueSigned = 0;
         if (newValueSigned > 100) newValueSigned = 100;

         organism.dynamicTraits[traitIndex] = uint256(newValueSigned);
         emit TraitChanged(organismId, traitIndex, oldValue, organism.dynamicTraits[traitIndex]);


        emit OrganismStimulated(organismId, organism.energy, organism.dynamicTraits);
    }

    /**
     * @dev Attempts to evolve an organism to the next stage.
     *      Requires certain conditions to be met (e.g., high vitality, recent feeding, stage-specific criteria).
     *      Costs energy and vitality.
     * @param organismId The ID of the organism to evolve.
     */
    function evolveOrganism(uint256 organismId) external {
        Organism storage organism = organisms[organismId];
        require(organismOwners[organismId] == msg.sender, "Not your organism");
        _updateVitality(organismId); // Update state before action
        require(!organism.isDead, "Organism is deceased");
        require(organism.vitality >= 70, "Vitality too low to evolve");
        require(organism.energy >= 50, "Energy too low to evolve");
        require(block.timestamp - organism.lastFedTime <= 24 hours, "Organism must be fed recently to evolve");
        // Add stage-specific evolution criteria here (e.g., must reach certain trait levels for stage 2)
        // For simplicity, current check is just vitality/energy/feeding time.

        uint256 oldStage = organism.evolutionStage;
        // Prevent evolving past a max stage if desired, or add high requirements
        require(oldStage < 5, "Organism is at max evolution stage"); // Example max stage

        // Check specific criteria based on the *target* stage (oldStage + 1)
        if (oldStage == 1) {
            // Example: Require sum of first two traits > 100 to evolve to stage 2
            require(organism.dynamicTraits[0] + organism.dynamicTraits[1] > 100, "Trait criteria not met for stage 2");
        }
        // Add more criteria for other stages...

        // Costs for evolving
        organism.vitality -= 20; // Evolution is taxing
        organism.energy -= 40;  // Evolution uses a lot of energy

        organism.evolutionStage++;
        organismsByStageCount[oldStage]--;
        organismsByStageCount[organism.evolutionStage]++;

        // Evolution can unlock/modify traits further
        uint256 seed = uint256(keccak256(abi.encodePacked(block.timestamp, organismId, organism.evolutionStage)));
         for (uint i = 0; i < 5; i++) {
             // Example: Slightly boost traits or unlock new trait potential upon evolution
             organism.dynamicTraits[i] = min(organism.dynamicTraits[i] + (seed % 10), 100);
         }


        emit OrganismEvolved(organismId, organism.evolutionStage, organism.vitality, organism.energy);
    }

     /**
     * @dev Allows two organisms to interact, potentially transferring energy with loss.
     *      Both organisms must be owned by the caller.
     * @param organism1Id The ID of the first organism.
     * @param organism2Id The ID of the second organism.
     */
    function attuneOrganism(uint256 organism1Id, uint256 organism2Id) external {
        require(organism1Id != organism2Id, "Cannot attune an organism to itself");
        require(organismOwners[organism1Id] == msg.sender, "Not your first organism");
        require(organismOwners[organism2Id] == msg.sender, "Not your second organism");

        Organism storage org1 = organisms[organism1Id];
        Organism storage org2 = organisms[organism2Id];

        _updateVitality(organism1Id);
        _updateVitality(organism2Id);
        require(!org1.isDead && !org2.isDead, "One or both organisms are deceased");

        // Example attunement: Transfer energy from one to the other with 20% loss
        uint256 transferAmount = min(org1.energy / 2, 30); // Can transfer up to half energy, max 30
        uint256 receivedAmount = transferAmount * 8 / 10; // 20% loss

        org1.energy -= transferAmount;
        org2.energy = min(org2.energy + receivedAmount, 100);

        // Attunement could also slightly affect specific traits based on organism stages or traits
        // uint256 seed = uint256(keccak256(abi.encodePacked(block.timestamp, organism1Id, organism2Id)));
        // ... trait modifications ...

        emit OrganismsAttuned(organism1Id, organism2Id);
    }

     /**
     * @dev Permanently destroys an organism.
     *      Potentially returns a fraction of its initial cost or adds value to the pool.
     * @param organismId The ID of the organism to sacrifice.
     */
    function sacrificeOrganism(uint256 organismId) external {
        Organism storage organism = organisms[organismId];
        require(organismOwners[organismId] == msg.sender, "Not your organism");
        require(!organism.isDead, "Organism is already deceased"); // Can only sacrifice living organisms

        // Mark as dead immediately
        organism.isDead = true;

        // Reduce counts
        ownerOrganismCount[msg.sender]--;
        organismsByStageCount[organism.evolutionStage]--;

        // Calculate return value - example: 10% of mint cost + a bonus based on evolution stage
        uint256 returnAmount = mintCost / 10 + (organism.evolutionStage * 0.0005 ether);

        // Ensure contract has enough balance before sending
        if (address(this).balance >= returnAmount) {
            payable(msg.sender).transfer(returnAmount);
            emit OrganismSacrificed(organismId, msg.sender, returnAmount);
        } else {
             emit OrganismSacrificed(organismId, msg.sender, 0);
        }

        // Clear ownership mapping (makes it truly unowned and unusable via owner checks)
        delete organismOwners[organismId];

        // Note: The Organism struct data is NOT deleted from storage to save gas,
        // but the `isDead` flag and deleted ownership prevent further interaction.
    }

    /**
     * @dev A risky action that might unlock or significantly alter a trait.
     *      Requires high energy and has a chance of failure (draining energy/vitality).
     * @param organismId The ID of the organism.
     */
    function tryManifestTrait(uint256 organismId) external {
        Organism storage organism = organisms[organismId];
        require(organismOwners[organismId] == msg.sender, "Not your organism");
         _updateVitality(organismId); // Update state before action
        require(!organism.isDead, "Organism is deceased");
        require(organism.energy >= 60, "Not enough energy for risky manifestation"); // Requires high energy

        organism.energy -= 30; // Base cost

        // Simple pseudo-random success chance based on vitality, energy, and a trait (e.g., Mutability)
        uint256 luckSeed = uint256(keccak256(abi.encodePacked(block.timestamp, tx.origin, organismId, organism.vitality, organism.energy, organism.dynamicTraits[4])));
        uint256 chance = (organism.vitality + organism.energy + organism.dynamicTraits[4]) / 3; // Average of key stats + Mutability
        bool success = (luckSeed % 100) < chance;

        bool traitChanged = false;
        uint256[5] memory oldTraits = organism.dynamicTraits; // Save old values for event

        if (success) {
            // Success: Boost a random trait significantly, maybe unlock a "hidden" state (not modeled here)
             uint256 boostSeed = uint256(keccak256(abi.encodePacked(luckSeed, "SUCCESS")));
             uint256 traitIndex = boostSeed % 5;
             uint256 boostAmount = (boostSeed % 10) + 5; // Boost between 5 and 14
             uint256 newValue = min(organism.dynamicTraits[traitIndex] + boostAmount, 100);
             if (organism.dynamicTraits[traitIndex] != newValue) {
                 organism.dynamicTraits[traitIndex] = newValue;
                 emit TraitChanged(organismId, traitIndex, oldTraits[traitIndex], newValue);
                 traitChanged = true;
             }
            organism.vitality = min(organism.vitality + 5, 100); // Small vitality recovery on success

        } else {
            // Failure: Drain more energy/vitality, potentially reduce a trait
            organism.energy = organism.energy < 30 ? 0 : organism.energy - 30; // Additional energy drain
            organism.vitality = organism.vitality < 10 ? 0 : organism.vitality - 10; // Vitality hit
             _updateVitality(organismId); // Check for death after vitality loss

             uint256 failSeed = uint256(keccak256(abi.encodePacked(luckSeed, "FAIL")));
             uint256 traitIndex = failSeed % 5;
             uint256 drainAmount = (failSeed % 5) + 2; // Drain between 2 and 6
             uint256 newValue = organism.dynamicTraits[traitIndex] < drainAmount ? 0 : organism.dynamicTraits[traitIndex] - drainAmount;
              if (organism.dynamicTraits[traitIndex] != newValue) {
                 organism.dynamicTraits[traitIndex] = newValue;
                 emit TraitChanged(organismId, traitIndex, oldTraits[traitIndex], newValue);
                 traitChanged = true;
             }
        }
         emit TraitManifestAttempt(organismId, success, organism.dynamicTraits);
    }


    // --- Resource & Admin Functions ---

    /**
     * @dev Allows users to deposit ETH into the contract, increasing the shared Essence pool.
     */
    function depositEssence() external payable {
        require(msg.value > 0, "Must send ETH to deposit Essence");
        emit EssenceDeposited(msg.sender, msg.value);
        // ETH is automatically added to address(this).balance
    }

    /**
     * @dev Allows the contract owner to withdraw ETH from the contract balance (Essence pool).
     *      Caution: This reduces the resources available for organisms.
     * @param amount The amount of ETH to withdraw.
     */
    function adminWithdrawEssence(uint256 amount) external onlyOwner {
        require(amount > 0, "Cannot withdraw zero");
        require(address(this).balance >= amount, "Insufficient contract balance");
        payable(owner).transfer(amount);
        emit EssenceWithdrawn(owner, amount);
    }

    /**
     * @dev Owner sets the cost to mint a new organism.
     * @param cost The new mint cost in wei.
     */
    function setMintCost(uint256 cost) external onlyOwner {
        mintCost = cost;
    }

    /**
     * @dev Owner sets the base cost to feed an organism.
     * @param cost The new base sustain cost in wei.
     */
    function setSustainCostBase(uint256 cost) external onlyOwner {
        sustainCostBase = cost;
    }

    /**
     * @dev Owner sets the cost modifier for feeding based on evolution stage.
     * @param stage The evolution stage.
     * @param modifierFactor The modifier in basis points (e.g., 10000 for 1x, 15000 for 1.5x).
     */
    function setStageEssenceCostModifier(uint256 stage, uint256 modifierFactor) external onlyOwner {
        stageEssenceCostModifiers[stage] = modifierFactor;
    }

     /**
     * @dev Admin function to transfer an organism (e.g., for support or recovery).
     *      Bypasses standard ownership transfer logic.
     * @param organismId The ID of the organism to transfer.
     * @param newOwner The address of the new owner.
     */
    function adminTransferOrganism(uint256 organismId, address newOwner) external onlyOwner {
        require(newOwner != address(0), "Invalid address");
        require(organismOwners[organismId] != address(0), "Organism does not exist");
        require(!organisms[organismId].isDead, "Cannot transfer deceased organism via admin"); // Can't transfer if sacrificed

        address oldOwner = organismOwners[organismId];
        require(oldOwner != newOwner, "New owner is the same as the old owner");

        // Update owner mappings
        ownerOrganismCount[oldOwner]--;
        organismOwners[organismId] = newOwner;
        ownerOrganismCount[newOwner]++;
        organisms[organismId].owner = newOwner; // Update owner stored in struct as well

        emit OrganismTransferred(organismId, oldOwner, newOwner);
    }


    // --- Status & Query (View Functions) ---

    /**
     * @dev Gets the full state details of an organism.
     * @param organismId The ID of the organism.
     * @return Organism struct details.
     */
    function getOrganismState(uint256 organismId) external view returns (Organism memory) {
        require(organismOwners[organismId] != address(0), "Organism does not exist");
        // Note: Vitality/Energy in the struct might be outdated.
        // Call calculateCurrentVitality for up-to-date vitality/death status.
        return organisms[organismId];
    }

    /**
     * @dev Gets the owner of an organism.
     * @param organismId The ID of the organism.
     * @return The owner's address, or address(0) if it doesn't exist or was sacrificed.
     */
    function getOrganismOwner(uint256 organismId) external view returns (address) {
        return organismOwners[organismId];
    }

    /**
     * @dev Gets the number of organisms owned by an address.
     * @param owner The address to check.
     * @return The count of organisms owned.
     */
    function getOwnerOrganismCount(address owner) external view returns (uint256) {
        return ownerOrganismCount[owner];
    }

    /**
     * @dev Gets the total ETH balance held by the contract, representing the conceptual Essence pool.
     * @return The contract balance in wei.
     */
    function getTotalEssencePool() external view returns (uint256) {
        return address(this).balance;
    }

    /**
     * @dev Gets the total number of organisms ever minted.
     * @return The total count.
     */
    function getTotalOrganismsMinted() external view returns (uint256) {
        return _totalOrganismsMinted;
    }

    /**
     * @dev Gets the array of dynamic trait values for an organism.
     * @param organismId The ID of the organism.
     * @return The array of 5 trait values.
     */
    function getOrganismDynamicTraits(uint256 organismId) external view returns (uint256[5] memory) {
         require(organismOwners[organismId] != address(0), "Organism does not exist");
         return organisms[organismId].dynamicTraits;
    }

     /**
     * @dev Calculates the organism's current vitality considering decay since last fed.
     *      Does NOT update the stored vitality in the struct. Use _updateVitality internally for that.
     * @param organismId The ID of the organism.
     * @return The calculated current vitality (0-100).
     */
    function calculateCurrentVitality(uint256 organismId) external view returns (uint256) {
         require(organismOwners[organismId] != address(0), "Organism does not exist");
         Organism storage organism = organisms[organismId];
         if (organism.isDead) return 0;

         uint256 timePassed = block.timestamp - organism.lastFedTime;
         uint256 decayRate = 1 + (organism.evolutionStage / 2);
         uint256 potentialDecay = (timePassed / 1 hours) * decayRate;

         if (potentialDecay >= organism.vitality) return 0;
         return organism.vitality - potentialDecay;
    }

    /**
     * @dev Gets a simple status for the organism.
     * @param organismId The ID of the organism.
     * @return 0: Alive, 1: Dormant, 2: Deceased.
     */
    function checkOrganismStatus(uint256 organismId) external view returns (uint256) {
        require(organismOwners[organismId] != address(0), "Organism does not exist");
         Organism storage organism = organisms[organismId];
        if (organism.isDead) return 2; // Deceased (explicit flag check first)

        // Calculate potential vitality after decay to inform Dormant status
        uint256 currentCalculatedVitality = calculateCurrentVitality(organismId);
         if (currentCalculatedVitality < 20 || organism.energy < 10) return 1; // Dormant

        return 0; // Alive
    }

     /**
     * @dev Provides guidance on the criteria needed for the organism's next evolution stage.
     *      This is a conceptual view function; actual evolution checks are in evolveOrganism.
     * @param organismId The ID of the organism.
     * @return A string describing the criteria (simplified).
     */
    function queryEvolutionCriteria(uint256 organismId) external view returns (string memory) {
        require(organismOwners[organismId] != address(0), "Organism does not exist");
        Organism storage organism = organisms[organismId];
        if (organism.isDead) return "Organism is deceased.";
        if (organism.evolutionStage >= 5) return "Organism is at maximum evolution stage."; // Matches require in evolve

        uint256 nextStage = organism.evolutionStage + 1;
        string memory criteria = "To evolve to Stage ";
        criteria = string.concat(criteria, _uint256ToString(nextStage));
        criteria = string.concat(criteria, ": Vitality >= 70, Energy >= 50, Fed within 24 hours.");

        // Add stage-specific criteria hints
        if (nextStage == 2) {
            criteria = string.concat(criteria, " Additionally: Resilience + Agility > 100.");
        }
        // Add hints for other stages...

        return criteria;
    }

    /**
     * @dev Gets the count of organisms currently at a specific evolution stage.
     * @param stage The evolution stage to check.
     * @return The count.
     */
    function getTotalOrganismsByStage(uint256 stage) external view returns (uint256) {
        return organismsByStageCount[stage];
    }

    /**
     * @dev Calculates the current cost to feed an organism based on its stage.
     * @param organismId The ID of the organism.
     * @return The calculated cost in wei.
     */
    function getSustainCost(uint256 organismId) public view returns (uint256) {
        require(organismOwners[organismId] != address(0), "Organism does not exist");
        Organism storage organism = organisms[organismId];
        uint256 modifierFactor = stageEssenceCostModifiers[organism.evolutionStage];
         if (modifierFactor == 0) {
             // If no specific modifier set for stage, default to 1x base cost
             modifierFactor = 10000; // 100%
         }
        // Calculate cost: baseCost * modifier / 10000
        return (sustainCostBase * modifierFactor) / 10000;
    }


    // --- Utility Functions ---

    // Simple min function
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    // Simple utility function to convert uint256 to string (for queryEvolutionCriteria)
    // Note: This is a basic implementation and can be inefficient for large numbers.
    function _uint256ToString(uint256 value) internal pure returns (string memory) {
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
            buffer[digits] = bytes1(uint8(48 + value % 10));
            value /= 10;
        }
        return string(buffer);
    }
}
```