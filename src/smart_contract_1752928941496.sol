Okay, this is an exciting challenge! Creating a truly novel smart contract concept that avoids duplicating existing open-source projects, yet incorporates advanced, trendy ideas, and has at least 20 functions, requires a deep dive into mechanics and creative problem-solving.

I propose a concept called **"The Bio-Algorithmic Ecosystem (BAES)"**. It's a decentralized, evolving simulation of digital lifeforms ("AetherLifestreams") that interact with each other and a dynamically changing environment governed by the community.

---

### **Concept: The Bio-Algorithmic Ecosystem (BAES)**

**Core Idea:** A decentralized "digital natural selection" experiment. Users "seed" digital organisms (AetherLifestreams, which are stateful NFTs), which then evolve, adapt, consume resources, procreate, form symbiotic relationships, and face environmental challenges determined by collective governance and external "cosmic flux" (oracle-fed randomness/events). The goal is not a game, but an emergent, self-sustaining, and community-driven digital life simulation.

**Key Advanced Concepts:**

1.  **Stateful, Evolving NFTs:** AetherLifestreams are not static. Their attributes (Health, Energy, Resilience, Intelligence, Age) constantly change based on time, interactions, and environmental factors. Their "Genetics" are immutable but influence their growth curves and resistances.
2.  **Algorithmic Decay & Growth:** Lifestreams naturally decay (age, lose energy) but can grow (gain intelligence, resilience) through interaction, resource consumption, and successful adaptation.
3.  **Community-Driven Environment (Decentralized Governance):** A DAO-like mechanism where token holders (AetherPlasma, the ecosystem's resource token) propose and vote on "Environmental Directives" that globally affect all AetherLifestreams (e.g., increased decay rate for certain traits, boosts for others, new resource discovery).
4.  **Oracle-Fed "Cosmic Flux":** An external oracle feeds pseudo-randomness or real-world data ("Cosmic Flux") that introduces unpredictable environmental variables, simulating cosmic events or natural disasters that impact Lifestreams.
5.  **Symbiotic Relationships:** Lifestreams can form "symbiotic bonds" with others, sharing resources or attributes for a limited time, reflecting complex biological interactions.
6.  **Resource Scarcity & Management:** AetherLifestreams require "AetherPlasma" (an ERC-20 token) to survive, rejuvenate, and procreate, creating a dynamic economy within the ecosystem.
7.  **Dynamic Trait Inheritance & Mutation:** Procreation involves a blend of parent genetics with a chance of mutation, leading to emergent traits.
8.  **Automated Epochs:** The ecosystem progresses in "epochs," automatically triggering global updates and applying environmental effects.

---

### **Contract Outline & Function Summary**

**File 1: `AetherPlasma.sol` (The Ecosystem's Resource Token)**
*   A standard ERC-20 token used for feeding Lifestreams, facilitating procreation, and enabling governance.

**File 2: `BioAlgorithmicEcosystem.sol` (The Core Ecosystem Logic)**

**I. Core Ecosystem State & Management**
    *   **`constructor`**: Initializes the contract, sets the AetherPlasma token address, and optionally an initial oracle address.
    *   **`setCosmicFluxOracle(address _newOracle)`**: Admin function to update the oracle address.
    *   **`setCoreParameter(uint256 _paramId, uint256 _value)`**: Governance/Admin controlled function to adjust global ecosystem parameters (e.g., base decay rates, procreation costs).
    *   **`triggerEnvironmentalEpoch()`**: Advances the ecosystem's internal "time" (epoch), triggering global updates to all Lifestreams and applying active environmental directives.

**II. AetherLifestream (ALS) Creation & Lifecycle**
    *   **`createAetherLifestream(uint256 _initialPlasmaFeed)`**: Mints a new AetherLifestream, assigning it unique initial genetics and consuming AetherPlasma.
    *   **`feedAetherLifestream(uint256 _lifestreamId, uint256 _plasmaAmount)`**: Feeds AetherPlasma to a Lifestream, boosting its Health and Energy.
    *   **`rejuvenateAetherLifestream(uint256 _lifestreamId, uint256 _plasmaAmount)`**: Rejuvenates a Lifestream, reducing its age and potentially resetting some decay.
    *   **`cullAetherLifestream(uint256 _lifestreamId)`**: Allows the owner to manually remove a Lifestream (e.g., if it's too weak), or can be triggered automatically if vitality drops too low.

**III. AetherLifestream Interactions**
    *   **`initiateSymbioticBond(uint256 _lifestreamId1, uint256 _lifestreamId2)`**: Initiates a temporary symbiotic bond between two Lifestreams (owned by different users), providing mutual benefits. Requires both owners' consent.
    *   **`resolveSymbioticBond(uint256 _lifestreamId)`**: Ends an active symbiotic bond.
    *   **`attemptProcreation(uint256 _parent1Id, uint256 _parent2Id, uint256 _plasmaCost)`**: Attempts to procreate a new AetherLifestream from two existing ones, blending their genetics and consuming AetherPlasma. Success rate depends on parents' vitality.
    *   **`applyEnvironmentalAdaptation(uint256 _lifestreamId, uint256 _adaptationType)`**: Allows an owner to guide a Lifestream to adapt to the current environment, potentially boosting specific traits based on active directives.

**IV. Environmental Governance (DAO-like)**
    *   **`submitEnvironmentalDirectiveProposal(string calldata _description, uint256 _effectTypeId, uint256 _effectValue)`**: Allows AetherPlasma holders to propose new environmental directives that alter the ecosystem's rules.
    *   **`voteOnEnvironmentalDirective(uint256 _proposalId, bool _voteFor)`**: Allows AetherPlasma holders to vote on active proposals.
    *   **`cancelEnvironmentalDirectiveProposal(uint256 _proposalId)`**: Allows the proposer to cancel their own proposal if not yet passed.
    *   **`executeEnvironmentalDirective(uint256 _proposalId)`**: Executes a passed environmental directive, applying its global effects to the ecosystem for a defined period.

**V. Information & Query Functions**
    *   **`getAetherLifestreamDetails(uint256 _lifestreamId)`**: Retrieves comprehensive details about a specific AetherLifestream, including its static genetics and dynamic attributes.
    *   **`getAetherLifestreamsByOwner(address _owner)`**: Returns a list of all AetherLifestream IDs owned by a specific address.
    *   **`checkLifestreamVitality(uint256 _lifestreamId)`**: Calculates and returns the current vitality score (health + energy + resilience) of a Lifestream.
    *   **`getEnvironmentalDirectiveDetails(uint256 _proposalId)`**: Retrieves details about a specific environmental directive proposal.
    *   **`getCurrentActiveEnvironmentalDirectives()`**: Returns a list of all environmental directives currently in effect.
    *   **`getPassedEnvironmentalDirectivesHistory()`**: Returns a list of all environmental directives that have been executed in the past.
    *   **`getCoreParameter(uint256 _paramId)`**: Retrieves the current value of a global ecosystem parameter.
    *   **`getSymbioticBondDetails(uint256 _lifestreamId)`**: Retrieves details about an active symbiotic bond involving the specified Lifestream.
    *   **`getCurrentCosmicFlux()`**: Returns the latest "Cosmic Flux" value fetched from the oracle.
    *   **`getTotalAetherLifestreams()`**: Returns the total number of AetherLifestreams that have been created.

---

### **Solidity Smart Contracts**

We'll use OpenZeppelin contracts for `ERC20`, `Ownable`, and `ReentrancyGuard` to build upon a secure foundation.

**1. `AetherPlasma.sol`**

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title AetherPlasma
 * @dev The ERC-20 token serving as the primary resource and governance token
 *      within the Bio-Algorithmic Ecosystem.
 *      Used for feeding AetherLifestreams, procreation, rejuvenation, and voting on directives.
 */
contract AetherPlasma is ERC20, Ownable {
    constructor() ERC20("AetherPlasma", "APLAS") Ownable(msg.sender) {}

    /**
     * @dev Mints new AetherPlasma tokens.
     *      Only the owner (typically the BioAlgorithmicEcosystem contract or an admin) can call this.
     * @param to The address to mint tokens to.
     * @param amount The amount of tokens to mint.
     */
    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }

    /**
     * @dev Burns AetherPlasma tokens from the caller's balance.
     * @param amount The amount of tokens to burn.
     */
    function burn(uint256 amount) public {
        _burn(msg.sender, amount);
    }

    // Standard ERC20 functions (transfer, approve, transferFrom, balanceOf, allowance) are inherited.
}
```

**2. `BioAlgorithmicEcosystem.sol`**

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol"; // For interacting with AetherPlasma

// --- Interfaces ---
/**
 * @title ICosmicFluxOracle
 * @dev Interface for an external oracle providing a "cosmic flux" value.
 *      This value introduces randomness or external environmental factors.
 */
interface ICosmicFluxOracle {
    function getLatestFlux() external view returns (uint256);
}

// --- Data Structures ---
/**
 * @dev Represents the immutable genetic blueprint of an AetherLifestream.
 */
struct GeneticTraits {
    uint8 intelligenceFactor; // Higher value means faster intelligence growth, better adaptation
    uint8 resilienceFactor;   // Higher value means better resistance to decay, damage
    uint8 energyEfficiency;   // Higher value means less AetherPlasma consumption for upkeep
    uint8 mutationLikelihood; // Higher value means higher chance of unique mutations during procreation
}

/**
 * @dev Represents the dynamic, evolving attributes of an AetherLifestream.
 */
struct DynamicAttributes {
    uint256 health;           // Current health, if 0, Lifestream is culled
    uint256 energy;           // Current energy, consumed by actions and decay
    uint256 intelligence;     // Evolves over time, influences adaptation and procreation success
    uint256 resilience;       // Evolves over time, influences resistance to decay and environmental effects
    uint256 age;              // Increases with each epoch, influences decay rates
}

/**
 * @dev Represents an AetherLifestream, a unique digital organism.
 */
struct AetherLifestream {
    address owner;
    GeneticTraits genetics;
    DynamicAttributes attributes;
    uint256 lastUpdateEpoch;   // The epoch when attributes were last updated
    uint256 creationEpoch;     // The epoch when the lifestream was created

    // Symbiotic Bond (if any)
    uint256 bondedToLifestreamId; // 0 if not bonded
    uint256 bondStartEpoch;       // Epoch when bond started
}

/**
 * @dev Represents a proposed or active environmental directive.
 */
struct EnvironmentalDirective {
    address proposer;
    string description;
    uint256 effectTypeId;      // Defines the type of effect (e.g., 1=health_boost, 2=energy_drain)
    uint256 effectValue;       // Magnitude of the effect
    uint256 proposalEpoch;     // Epoch when the proposal was submitted
    uint256 expirationEpoch;   // Epoch when the directive's effect will end (if executed)
    uint256 votesFor;
    uint256 votesAgainst;
    bool executed;             // True if the directive has been passed and applied
    bool active;               // True if currently in effect
    bool cancelled;            // True if the proposal was cancelled
}

/**
 * @dev Defines different types of global ecosystem parameters that can be adjusted.
 */
enum CoreParameter {
    BASE_DECAY_RATE,            // Base decay rate for health/energy per epoch
    PROCREATION_COST_BASE,      // Base plasma cost for procreation
    SYMBIONT_BONUS_FACTOR,      // Bonus factor for symbiotic bonds
    ADAPTATION_BOOST_FACTOR,    // Boost factor for environmental adaptation
    DIRECTIVE_QUORUM_PERCENT,   // % of total AetherPlasma supply needed for proposal to pass
    DIRECTIVE_VOTING_PERIOD_EPOCHS, // How many epochs a proposal is open for voting
    DIRECTIVE_EFFECT_DURATION_EPOCHS // How long an executed directive remains active
}

/**
 * @dev Defines different types of effects an environmental directive can have.
 */
enum DirectiveEffectType {
    NONE,                   // No effect
    HEALTH_BOOST,           // Increases health globally
    ENERGY_DRAIN,           // Decreases energy globally
    RESILIENCE_BOOST,       // Increases resilience globally
    INTELLIGENCE_PENALTY,   // Decreases intelligence globally
    MUTATION_CHANCE_INCREASE, // Increases global mutation likelihood for procreation
    PLASMA_EFFICIENCY_BOOST // Increases energy efficiency for plasma consumption
}


contract BioAlgorithmicEcosystem is Ownable, ReentrancyGuard {
    // --- State Variables ---
    IERC20 public aetherPlasmaToken;
    ICosmicFluxOracle public cosmicFluxOracle;

    uint256 public nextLifestreamId;
    uint256 public currentEpoch;
    uint256 public nextDirectiveId;

    mapping(uint256 => AetherLifestream) public aetherLifestreams;
    mapping(address => uint256[]) public ownerLifestreams; // Map owner to their Lifestream IDs
    mapping(uint256 => EnvironmentalDirective) public environmentalDirectives;
    mapping(uint256 => mapping(address => bool)) public directiveVoted; // proposalId => voter => voted

    // Global ecosystem parameters, adjustable via governance
    mapping(uint256 => uint256) public coreParameters; // CoreParameter(enum) => value

    // --- Events ---
    event AetherLifestreamCreated(uint256 indexed lifestreamId, address indexed owner, GeneticTraits genetics, uint256 creationEpoch);
    event LifestreamFed(uint256 indexed lifestreamId, uint256 amount, uint256 newHealth, uint256 newEnergy);
    event LifestreamRejuvenated(uint256 indexed lifestreamId, uint256 amount, uint256 newAge);
    event LifestreamCulled(uint256 indexed lifestreamId, address indexed owner, string reason);
    event SymbioticBondInitiated(uint256 indexed lifestreamId1, uint256 indexed lifestreamId2, uint256 bondStartEpoch);
    event SymbioticBondResolved(uint256 indexed lifestreamId1, uint256 indexed lifestreamId2, uint256 bondDuration);
    event ProcreationAttempted(uint256 indexed parent1Id, uint256 indexed parent2Id, uint256 newLifestreamId, bool success);
    event EnvironmentalAdaptationApplied(uint256 indexed lifestreamId, uint256 adaptationType, uint256 cosmicFlux);
    event EnvironmentalDirectiveProposed(uint256 indexed proposalId, address indexed proposer, string description);
    event EnvironmentalDirectiveVoted(uint256 indexed proposalId, address indexed voter, bool voteFor);
    event EnvironmentalDirectiveExecuted(uint256 indexed proposalId, uint256 expirationEpoch);
    event EnvironmentalDirectiveCancelled(uint256 indexed proposalId);
    event EpochAdvanced(uint256 indexed newEpoch, uint256 cosmicFlux);
    event CoreParameterUpdated(uint256 indexed paramId, uint256 oldValue, uint256 newValue);

    // --- Modifiers ---
    modifier onlyLifestreamOwner(uint256 _lifestreamId) {
        require(aetherLifestreams[_lifestreamId].owner == msg.sender, "Not Lifestream owner");
        _;
    }

    modifier lifestreamExists(uint256 _lifestreamId) {
        require(aetherLifestreams[_lifestreamId].owner != address(0), "Lifestream does not exist");
        _;
    }

    modifier proposalExists(uint256 _proposalId) {
        require(environmentalDirectives[_proposalId].proposer != address(0), "Proposal does not exist");
        _;
    }

    // --- Constructor ---
    constructor(address _plasmaTokenAddress, address _cosmicFluxOracleAddress) Ownable(msg.sender) {
        require(_plasmaTokenAddress != address(0), "Plasma token address cannot be zero");
        require(_cosmicFluxOracleAddress != address(0), "Cosmic Flux Oracle address cannot be zero");

        aetherPlasmaToken = IERC20(_plasmaTokenAddress);
        cosmicFluxOracle = ICosmicFluxOracle(_cosmicFluxOracleAddress);

        nextLifestreamId = 1;
        currentEpoch = 0; // Start at epoch 0
        nextDirectiveId = 1;

        // Initialize core parameters with default values
        coreParameters[uint256(CoreParameter.BASE_DECAY_RATE)] = 10; // Health/Energy decay per epoch
        coreParameters[uint256(CoreParameter.PROCREATION_COST_BASE)] = 1000 * 10**aetherPlasmaToken.decimals();
        coreParameters[uint256(CoreParameter.SYMBIONT_BONUS_FACTOR)] = 10; // % bonus on attributes
        coreParameters[uint256(CoreParameter.ADAPTATION_BOOST_FACTOR)] = 15; // % boost for adaptation
        coreParameters[uint256(CoreParameter.DIRECTIVE_QUORUM_PERCENT)] = 5; // 5% of total supply
        coreParameters[uint256(CoreParameter.DIRECTIVE_VOTING_PERIOD_EPOCHS)] = 3; // 3 epochs for voting
        coreParameters[uint256(CoreParameter.DIRECTIVE_EFFECT_DURATION_EPOCHS)] = 5; // 5 epochs for effect
    }

    // --- Core Ecosystem State & Management ---

    /**
     * @dev Admin function to update the Cosmic Flux Oracle address.
     * @param _newOracle The address of the new oracle contract.
     */
    function setCosmicFluxOracle(address _newOracle) public onlyOwner {
        require(_newOracle != address(0), "New oracle address cannot be zero");
        cosmicFluxOracle = ICosmicFluxOracle(_newOracle);
    }

    /**
     * @dev Allows governance (via a future DAO or current owner) to adjust global ecosystem parameters.
     * @param _paramId The ID of the parameter to set (from CoreParameter enum).
     * @param _value The new value for the parameter.
     */
    function setCoreParameter(uint256 _paramId, uint256 _value) public onlyOwner { // Could be DAO-governed later
        require(_paramId < 8, "Invalid parameter ID"); // Assuming 7 enum values in CoreParameter
        uint256 oldValue = coreParameters[_paramId];
        coreParameters[_paramId] = _value;
        emit CoreParameterUpdated(_paramId, oldValue, _value);
    }

    /**
     * @dev Advances the ecosystem's internal "time" by one epoch.
     *      Triggers global updates for all Lifestreams and applies active environmental directives.
     *      This function can be called by anyone but has a cooldown to prevent spam.
     *      (For simplicity, cooldown is implicitly handled by the "one epoch at a time" model.
     *      In production, this would be a time-based check or automated keeper network call).
     */
    function triggerEnvironmentalEpoch() public nonReentrant {
        currentEpoch++;
        uint256 currentFlux = getCurrentCosmicFlux();

        // Apply effects of active environmental directives (if any)
        _applyActiveDirectives();

        // No need to iterate all Lifestreams here, their state is lazily updated when interacted with.
        // The core decay and aging happens inside _updateLifestreamState.

        emit EpochAdvanced(currentEpoch, currentFlux);
    }

    // --- Internal Lifestream Update Logic ---

    /**
     * @dev Internal function to update a Lifestream's attributes based on elapsed epochs.
     *      Applies decay, aging, and potential environmental effects.
     * @param _lifestreamId The ID of the Lifestream to update.
     * @return bool True if the Lifestream is still alive, false if it's culled.
     */
    function _updateLifestreamState(uint256 _lifestreamId) internal returns (bool) {
        AetherLifestream storage ls = aetherLifestreams[_lifestreamId];
        require(ls.owner != address(0), "Lifestream does not exist for update");

        uint256 elapsedEpochs = currentEpoch - ls.lastUpdateEpoch;
        if (elapsedEpochs == 0) {
            return true; // Already up-to-date
        }

        // Apply decay based on elapsed epochs and base decay rate
        uint256 decayRate = coreParameters[uint256(CoreParameter.BASE_DECAY_RATE)];
        uint256 effectiveDecay = decayRate * elapsedEpochs;

        // Resilience reduces decay
        effectiveDecay = (effectiveDecay * 100) / (100 + ls.attributes.resilience);

        if (ls.attributes.health <= effectiveDecay) {
            ls.attributes.health = 0;
        } else {
            ls.attributes.health -= effectiveDecay;
        }

        if (ls.attributes.energy <= effectiveDecay) {
            ls.attributes.energy = 0;
        } else {
            ls.attributes.energy -= effectiveDecay;
        }

        ls.attributes.age += elapsedEpochs; // Lifestream ages

        // Check for vitality threshold to trigger auto-culling
        if (checkLifestreamVitality(_lifestreamId) == 0) {
            _cullLifestreamInternal(_lifestreamId, "Zero vitality");
            return false;
        }

        // Apply symbiotic bond effects if active
        if (ls.bondedToLifestreamId != 0 && aetherLifestreams[ls.bondedToLifestreamId].owner != address(0)) {
            AetherLifestream storage bondedLs = aetherLifestreams[ls.bondedToLifestreamId];
            if (currentEpoch - ls.bondStartEpoch < 5) { // Example: bond lasts 5 epochs
                uint256 bonus = (coreParameters[uint256(CoreParameter.SYMBIONT_BONUS_FACTOR)] * elapsedEpochs);
                ls.attributes.health += (bonus * 100); // 100 is just a multiplier to make effect visible
                ls.attributes.energy += (bonus * 50);
                ls.attributes.intelligence += (bonus / 2); // Small intelligence boost
            } else {
                // Bond expired
                ls.bondedToLifestreamId = 0;
                bondedLs.bondedToLifestreamId = 0; // Ensure both sides are cleared
                emit SymbioticBondResolved(ls.bondedToLifestreamId, _lifestreamId, currentEpoch - ls.bondStartEpoch);
            }
        }

        ls.lastUpdateEpoch = currentEpoch;
        return true;
    }

    /**
     * @dev Applies the effects of all currently active environmental directives.
     *      Called by `triggerEnvironmentalEpoch`.
     */
    function _applyActiveDirectives() internal {
        uint256 _nextDirectiveId = nextDirectiveId; // Capture current value
        for (uint256 i = 1; i < _nextDirectiveId; i++) {
            EnvironmentalDirective storage directive = environmentalDirectives[i];
            if (directive.active && currentEpoch <= directive.expirationEpoch) {
                // The actual application would involve iterating all Lifestreams
                // and modifying their state based on the directive.
                // For a truly scalable on-chain simulation, the effects would
                // implicitly modify the _updateLifestreamState logic or be accounted for
                // when Lifestreams interact or are queried, rather than
                // iterating over potentially millions of Lifestreams in one transaction.
                // Here, we'll simulate a global parameter change or flag.
                // A more advanced system might modify temporary global variables
                // that `_updateLifestreamState` then uses.
                // For this example, we'll simply acknowledge the directive is active.
            } else if (directive.active && currentEpoch > directive.expirationEpoch) {
                directive.active = false; // Directive expired
            }
        }
    }


    /**
     * @dev Internal function to generate initial random genetics for a new Lifestream.
     *      Uses blockhash and nextLifestreamId for pseudo-randomness.
     *      A real system might use Chainlink VRF for true randomness.
     */
    function _generateInitialGenetics(uint256 _seed) internal pure returns (GeneticTraits) {
        // Simple pseudo-random generation based on block data and a seed
        uint256 rand = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, msg.sender, _seed)));

        return GeneticTraits({
            intelligenceFactor: uint8((rand % 50) + 50),  // 50-99
            resilienceFactor: uint8(((rand >> 8) % 50) + 50), // 50-99
            energyEfficiency: uint8(((rand >> 16) % 50) + 50),// 50-99
            mutationLikelihood: uint8((rand % 10) + 1) // 1-10% chance
        });
    }

    /**
     * @dev Internal function to mix genetics from two parents during procreation.
     */
    function _mixGenetics(GeneticTraits memory g1, GeneticTraits memory g2, uint256 _seed) internal pure returns (GeneticTraits) {
        uint256 rand = uint256(keccak256(abi.encodePacked(block.timestamp, _seed)));

        // Simple averaging with a touch of randomness and mutation chance
        GeneticTraits memory newGenetics = GeneticTraits({
            intelligenceFactor: uint8((uint256(g1.intelligenceFactor) + uint256(g2.intelligenceFactor)) / 2),
            resilienceFactor: uint8((uint256(g1.resilienceFactor) + uint256(g2.resilienceFactor)) / 2),
            energyEfficiency: uint8((uint256(g1.energyEfficiency) + uint256(g2.energyEfficiency)) / 2),
            mutationLikelihood: uint8((uint256(g1.mutationLikelihood) + uint256(g2.mutationLikelihood)) / 2)
        });

        // Apply mutation
        if ((rand % 100) < newGenetics.mutationLikelihood) {
            uint8 mutationType = uint8(rand % 4);
            uint8 mutationAmount = uint8(1 + (rand % 10)); // Mutate by 1-10

            if (mutationType == 0) newGenetics.intelligenceFactor = (newGenetics.intelligenceFactor + mutationAmount) > 99 ? 99 : (newGenetics.intelligenceFactor + mutationAmount);
            else if (mutationType == 1) newGenetics.resilienceFactor = (newGenetics.resilienceFactor + mutationAmount) > 99 ? 99 : (newGenetics.resilienceFactor + mutationAmount);
            else if (mutationType == 2) newGenetics.energyEfficiency = (newGenetics.energyEfficiency + mutationAmount) > 99 ? 99 : (newGenetics.energyEfficiency + mutationAmount);
            else newGenetics.mutationLikelihood = (newGenetics.mutationLikelihood + mutationAmount) > 100 ? 100 : (newGenetics.mutationLikelihood + mutationAmount); // Can increase mutation chance significantly
        }

        return newGenetics;
    }


    /**
     * @dev Internal function to remove a Lifestream from the ecosystem.
     * @param _lifestreamId The ID of the Lifestream to cull.
     * @param _reason The reason for culling.
     */
    function _cullLifestreamInternal(uint256 _lifestreamId, string memory _reason) internal {
        AetherLifestream storage ls = aetherLifestreams[_lifestreamId];
        address ownerAddr = ls.owner;

        require(ownerAddr != address(0), "Lifestream does not exist for culling");

        // Remove from owner's list
        uint256[] storage ownedLifestreams = ownerLifestreams[ownerAddr];
        for (uint256 i = 0; i < ownedLifestreams.length; i++) {
            if (ownedLifestreams[i] == _lifestreamId) {
                ownedLifestreams[i] = ownedLifestreams[ownedLifestreams.length - 1];
                ownedLifestreams.pop();
                break;
            }
        }

        // Clean up symbiotic bond if active
        if (ls.bondedToLifestreamId != 0) {
            aetherLifestreams[ls.bondedToLifestreamId].bondedToLifestreamId = 0;
            emit SymbioticBondResolved(ls.bondedToLifestreamId, _lifestreamId, 0); // Duration 0 as it's forced
        }

        delete aetherLifestreams[_lifestreamId]; // Remove Lifestream data
        emit LifestreamCulled(_lifestreamId, ownerAddr, _reason);
    }

    // --- AetherLifestream (ALS) Creation & Lifecycle ---

    /**
     * @dev Mints a new AetherLifestream.
     *      Requires initial AetherPlasma for a starting boost.
     * @param _initialPlasmaFeed The amount of AetherPlasma to feed the new Lifestream.
     */
    function createAetherLifestream(uint256 _initialPlasmaFeed) public nonReentrant {
        require(_initialPlasmaFeed > 0, "Initial plasma feed must be greater than zero");
        require(aetherPlasmaToken.transferFrom(msg.sender, address(this), _initialPlasmaFeed), "Plasma transfer failed");

        uint256 newId = nextLifestreamId++;
        GeneticTraits memory newGenetics = _generateInitialGenetics(newId);

        AetherLifestream storage newLs = aetherLifestreams[newId];
        newLs.owner = msg.sender;
        newLs.genetics = newGenetics;
        newLs.attributes = DynamicAttributes({
            health: 100 + (_initialPlasmaFeed / (10**aetherPlasmaToken.decimals())), // Initial health based on plasma
            energy: 100 + (_initialPlasmaFeed / (10**aetherPlasmaToken.decimals())), // Initial energy based on plasma
            intelligence: 50, // Base intelligence
            resilience: 50,   // Base resilience
            age: 0
        });
        newLs.lastUpdateEpoch = currentEpoch;
        newLs.creationEpoch = currentEpoch;
        newLs.bondedToLifestreamId = 0;

        ownerLifestreams[msg.sender].push(newId);

        emit AetherLifestreamCreated(newId, msg.sender, newGenetics, currentEpoch);
        feedAetherLifestream(newId, _initialPlasmaFeed); // Apply initial feed as a regular feed
    }

    /**
     * @dev Feeds AetherPlasma to a Lifestream to restore its Health and Energy.
     * @param _lifestreamId The ID of the Lifestream to feed.
     * @param _plasmaAmount The amount of AetherPlasma to feed.
     */
    function feedAetherLifestream(uint256 _lifestreamId, uint256 _plasmaAmount) public nonReentrant onlyLifestreamOwner(_lifestreamId) lifestreamExists(_lifestreamId) {
        require(_plasmaAmount > 0, "Plasma amount must be greater than zero");
        require(aetherPlasmaToken.transferFrom(msg.sender, address(this), _plasmaAmount), "Plasma transfer failed");

        _updateLifestreamState(_lifestreamId); // Update before feeding
        AetherLifestream storage ls = aetherLifestreams[_lifestreamId];

        uint256 energyEfficiencyBonus = (100 + ls.genetics.energyEfficiency) / 100;
        uint256 effectivePlasma = _plasmaAmount / (10**aetherPlasmaToken.decimals()) * energyEfficiencyBonus;

        ls.attributes.health += effectivePlasma;
        ls.attributes.energy += effectivePlasma * 2; // Energy gets more boost from feeding

        emit LifestreamFed(_lifestreamId, _plasmaAmount, ls.attributes.health, ls.attributes.energy);
    }

    /**
     * @dev Rejuvenates a Lifestream, reducing its age and significantly boosting vitality.
     *      Requires a significant AetherPlasma cost.
     * @param _lifestreamId The ID of the Lifestream to rejuvenate.
     * @param _plasmaAmount The amount of AetherPlasma to spend on rejuvenation.
     */
    function rejuvenateAetherLifestream(uint256 _lifestreamId, uint256 _plasmaAmount) public nonReentrant onlyLifestreamOwner(_lifestreamId) lifestreamExists(_lifestreamId) {
        uint256 requiredPlasma = coreParameters[uint256(CoreParameter.PROCREATION_COST_BASE)] * 2; // Rejuvenation is costly
        require(_plasmaAmount >= requiredPlasma, "Not enough plasma for rejuvenation");
        require(aetherPlasmaToken.transferFrom(msg.sender, address(this), _plasmaAmount), "Plasma transfer failed");

        _updateLifestreamState(_lifestreamId);
        AetherLifestream storage ls = aetherLifestreams[_lifestreamId];

        // Reset age, boost health/energy significantly
        ls.attributes.age = ls.attributes.age / 4; // Reduce age by 75%
        ls.attributes.health = ls.attributes.health + (requiredPlasma * 10);
        ls.attributes.energy = ls.attributes.energy + (requiredPlasma * 20);

        emit LifestreamRejuvenated(_lifestreamId, _plasmaAmount, ls.attributes.age);
    }

    /**
     * @dev Allows the owner to manually cull a Lifestream. Can also be triggered internally if vitality is too low.
     * @param _lifestreamId The ID of the Lifestream to cull.
     */
    function cullAetherLifestream(uint256 _lifestreamId) public nonReentrant onlyLifestreamOwner(_lifestreamId) lifestreamExists(_lifestreamId) {
        _updateLifestreamState(_lifestreamId); // Ensure state is fresh
        require(checkLifestreamVitality(_lifestreamId) < 500, "Lifestream is too vital to be manually culled (unless it's very weak)"); // Prevent accidental culling of healthy Lifestreams

        _cullLifestreamInternal(_lifestreamId, "Owner initiated culling");
    }

    // --- AetherLifestream Interactions ---

    /**
     * @dev Initiates a temporary symbiotic bond between two Lifestreams.
     *      Both owners must call this function for the bond to be established.
     *      Benefits are shared attributes or boosted growth.
     * @param _lifestreamId1 The ID of the caller's Lifestream.
     * @param _lifestreamId2 The ID of the other Lifestream.
     */
    function initiateSymbioticBond(uint256 _lifestreamId1, uint256 _lifestreamId2) public nonReentrant onlyLifestreamOwner(_lifestreamId1) lifestreamExists(_lifestreamId1) lifestreamExists(_lifestreamId2) {
        require(_lifestreamId1 != _lifestreamId2, "Cannot bond a Lifestream with itself");
        require(aetherLifestreams[_lifestreamId1].bondedToLifestreamId == 0, "Lifestream 1 is already bonded");
        require(aetherLifestreams[_lifestreamId2].bondedToLifestreamId == 0, "Lifestream 2 is already bonded");

        _updateLifestreamState(_lifestreamId1);
        _updateLifestreamState(_lifestreamId2);

        AetherLifestream storage ls1 = aetherLifestreams[_lifestreamId1];
        AetherLifestream storage ls2 = aetherLifestreams[_lifestreamId2];

        // Check if the other Lifestream has already initiated the bond with this one
        if (ls2.bondedToLifestreamId == _lifestreamId1) {
            // Bond established!
            ls1.bondedToLifestreamId = _lifestreamId2;
            ls1.bondStartEpoch = currentEpoch;
            ls2.bondStartEpoch = currentEpoch; // This will overwrite ls2's bondStartEpoch if it called first, ensuring same start
            emit SymbioticBondInitiated(_lifestreamId1, _lifestreamId2, currentEpoch);
        } else {
            // Mark Lifestream 1 as wanting to bond with Lifestream 2, Lifestream 2 needs to reciprocate
            ls1.bondedToLifestreamId = _lifestreamId2; // Temporary marking, awaiting _lifestream2's call
            ls1.bondStartEpoch = 0; // Not truly started yet
        }
    }


    /**
     * @dev Resolves an active symbiotic bond for the caller's Lifestream.
     * @param _lifestreamId The ID of the Lifestream whose bond is to be resolved.
     */
    function resolveSymbioticBond(uint256 _lifestreamId) public nonReentrant onlyLifestreamOwner(_lifestreamId) lifestreamExists(_lifestreamId) {
        AetherLifestream storage ls = aetherLifestreams[_lifestreamId];
        require(ls.bondedToLifestreamId != 0, "Lifestream is not currently bonded");

        uint256 bondedLsId = ls.bondedToLifestreamId;
        ls.bondedToLifestreamId = 0;
        ls.bondStartEpoch = 0;

        // Also clear the bond for the other Lifestream
        aetherLifestreams[bondedLsId].bondedToLifestreamId = 0;
        aetherLifestreams[bondedLsId].bondStartEpoch = 0;

        emit SymbioticBondResolved(_lifestreamId, bondedLsId, currentEpoch - ls.bondStartEpoch);
    }

    /**
     * @dev Attempts to procreate a new AetherLifestream from two existing ones.
     *      Requires both parent Lifestreams to be owned by the caller (or authorized).
     *      Success depends on parents' vitality and consumes AetherPlasma.
     * @param _parent1Id The ID of the first parent Lifestream.
     * @param _parent2Id The ID of the second parent Lifestream.
     * @param _plasmaCost The amount of AetherPlasma paid for the attempt.
     */
    function attemptProcreation(uint256 _parent1Id, uint256 _parent2Id, uint256 _plasmaCost) public nonReentrant
        onlyLifestreamOwner(_parent1Id)
        onlyLifestreamOwner(_parent2Id)
        lifestreamExists(_parent1Id)
        lifestreamExists(_parent2Id)
    {
        require(_parent1Id != _parent2Id, "Cannot procreate with itself");
        uint256 requiredPlasma = coreParameters[uint256(CoreParameter.PROCREATION_COST_BASE)];
        require(_plasmaCost >= requiredPlasma, "Not enough plasma for procreation");
        require(aetherPlasmaToken.transferFrom(msg.sender, address(this), _plasmaCost), "Plasma transfer failed");

        _updateLifestreamState(_parent1Id);
        _updateLifestreamState(_parent2Id);

        AetherLifestream storage p1 = aetherLifestreams[_parent1Id];
        AetherLifestream storage p2 = aetherLifestreams[_parent2Id];

        // Procreation success chance based on parents' vitality and intelligence
        uint256 p1Vitality = checkLifestreamVitality(_parent1Id);
        uint256 p2Vitality = checkLifestreamVitality(_parent2Id);
        require(p1Vitality > 0 && p2Vitality > 0, "Both parents must be alive");

        uint256 successChance = (p1Vitality + p2Vitality + p1.attributes.intelligence + p2.attributes.intelligence) / 10; // Simple sum
        uint256 currentFlux = getCurrentCosmicFlux();
        uint256 randomFactor = uint256(keccak256(abi.encodePacked(block.timestamp, currentFlux, _parent1Id, _parent2Id))) % 100;

        bool success = (randomFactor < successChance);

        if (success) {
            uint256 newId = nextLifestreamId++;
            GeneticTraits memory newGenetics = _mixGenetics(p1.genetics, p2.genetics, newId);

            AetherLifestream storage childLs = aetherLifestreams[newId];
            childLs.owner = msg.sender;
            childLs.genetics = newGenetics;
            childLs.attributes = DynamicAttributes({
                health: 50 + (_plasmaCost / (10**aetherPlasmaToken.decimals())), // Initial health
                energy: 50 + (_plasmaCost / (10**aetherPlasmaToken.decimals())), // Initial energy
                intelligence: 50,
                resilience: 50,
                age: 0
            });
            childLs.lastUpdateEpoch = currentEpoch;
            childLs.creationEpoch = currentEpoch;
            childLs.bondedToLifestreamId = 0;

            ownerLifestreams[msg.sender].push(newId);

            // Parents consume energy and age more
            p1.attributes.energy = p1.attributes.energy / 2;
            p2.attributes.energy = p2.attributes.energy / 2;
            p1.attributes.age++;
            p2.attributes.age++;

            emit ProcreationAttempted(_parent1Id, _parent2Id, newId, true);
        } else {
            // Still consume plasma, but no new Lifestream
            emit ProcreationAttempted(_parent1Id, _parent2Id, 0, false);
        }
    }

    /**
     * @dev Allows a Lifestream owner to guide their Lifestream to adapt to the current environment.
     *      This might boost specific traits based on active environmental directives or cosmic flux.
     *      Consumes energy from the Lifestream.
     * @param _lifestreamId The ID of the Lifestream to adapt.
     * @param _adaptationType An integer representing a specific adaptation strategy (could map to traits).
     */
    function applyEnvironmentalAdaptation(uint256 _lifestreamId, uint256 _adaptationType) public nonReentrant onlyLifestreamOwner(_lifestreamId) lifestreamExists(_lifestreamId) {
        _updateLifestreamState(_lifestreamId);
        AetherLifestream storage ls = aetherLifestreams[_lifestreamId];

        require(ls.attributes.energy >= 50, "Lifestream needs energy to adapt");
        ls.attributes.energy -= 50; // Cost energy

        uint256 currentFlux = getCurrentCosmicFlux();
        uint256 boostFactor = coreParameters[uint256(CoreParameter.ADAPTATION_BOOST_FACTOR)];

        // Simple adaptation logic: based on _adaptationType and cosmic flux
        if (_adaptationType == 1) { // Focus on Resilience
            ls.attributes.resilience += (boostFactor + (currentFlux % 10));
        } else if (_adaptationType == 2) { // Focus on Intelligence
            ls.attributes.intelligence += (boostFactor + (currentFlux % 10));
        } else { // General adaptation
            ls.attributes.health += (boostFactor / 2);
            ls.attributes.energy += (boostFactor / 2);
        }

        emit EnvironmentalAdaptationApplied(_lifestreamId, _adaptationType, currentFlux);
    }


    // --- Environmental Governance (DAO-like) ---

    /**
     * @dev Allows AetherPlasma holders to propose new environmental directives.
     *      Requires a minimum amount of AetherPlasma to submit a proposal.
     * @param _description A brief description of the directive.
     * @param _effectTypeId The type of effect this directive will have (from DirectiveEffectType enum).
     * @param _effectValue The magnitude of the effect.
     */
    function submitEnvironmentalDirectiveProposal(string calldata _description, uint256 _effectTypeId, uint256 _effectValue) public nonReentrant {
        // Require a small deposit or minimum AetherPlasma balance to prevent spam
        require(aetherPlasmaToken.balanceOf(msg.sender) >= 100 * (10**aetherPlasmaToken.decimals()), "Not enough AetherPlasma to propose");
        require(_effectTypeId > uint256(DirectiveEffectType.NONE) && _effectTypeId <= uint256(DirectiveEffectType.PLASMA_EFFICIENCY_BOOST), "Invalid effect type ID");

        uint256 newId = nextDirectiveId++;
        environmentalDirectives[newId] = EnvironmentalDirective({
            proposer: msg.sender,
            description: _description,
            effectTypeId: _effectTypeId,
            effectValue: _effectValue,
            proposalEpoch: currentEpoch,
            expirationEpoch: 0, // Set upon execution
            votesFor: 0,
            votesAgainst: 0,
            executed: false,
            active: false,
            cancelled: false
        });

        emit EnvironmentalDirectiveProposed(newId, msg.sender, _description);
    }

    /**
     * @dev Allows AetherPlasma holders to vote on active proposals.
     *      Each AetherPlasma token held counts as one vote.
     * @param _proposalId The ID of the proposal to vote on.
     * @param _voteFor True for 'Yes', false for 'No'.
     */
    function voteOnEnvironmentalDirective(uint256 _proposalId, bool _voteFor) public nonReentrant proposalExists(_proposalId) {
        EnvironmentalDirective storage proposal = environmentalDirectives[_proposalId];
        require(!proposal.executed && !proposal.active && !proposal.cancelled, "Proposal is not in voting phase");
        require(proposal.proposalEpoch + coreParameters[uint256(CoreParameter.DIRECTIVE_VOTING_PERIOD_EPOCHS)] > currentEpoch, "Voting period has ended");
        require(!directiveVoted[_proposalId][msg.sender], "Already voted on this proposal");

        uint256 voterPlasmaBalance = aetherPlasmaToken.balanceOf(msg.sender);
        require(voterPlasmaBalance > 0, "Voter must hold AetherPlasma");

        if (_voteFor) {
            proposal.votesFor += voterPlasmaBalance;
        } else {
            proposal.votesAgainst += voterPlasmaBalance;
        }
        directiveVoted[_proposalId][msg.sender] = true;

        emit EnvironmentalDirectiveVoted(_proposalId, msg.sender, _voteFor);
    }

    /**
     * @dev Allows the proposer to cancel their own environmental directive proposal before it's executed.
     * @param _proposalId The ID of the proposal to cancel.
     */
    function cancelEnvironmentalDirectiveProposal(uint256 _proposalId) public nonReentrant proposalExists(_proposalId) {
        EnvironmentalDirective storage proposal = environmentalDirectives[_proposalId];
        require(proposal.proposer == msg.sender, "Only proposer can cancel");
        require(!proposal.executed && !proposal.active && !proposal.cancelled, "Proposal cannot be cancelled in its current state");
        require(proposal.proposalEpoch + coreParameters[uint256(CoreParameter.DIRECTIVE_VOTING_PERIOD_EPOCHS)] > currentEpoch, "Voting period has ended");

        proposal.cancelled = true;
        emit EnvironmentalDirectiveCancelled(_proposalId);
    }

    /**
     * @dev Executes a passed environmental directive. Can be called by anyone after voting period ends and quorum is met.
     * @param _proposalId The ID of the proposal to execute.
     */
    function executeEnvironmentalDirective(uint256 _proposalId) public nonReentrant proposalExists(_proposalId) {
        EnvironmentalDirective storage proposal = environmentalDirectives[_proposalId];
        require(!proposal.executed && !proposal.active && !proposal.cancelled, "Proposal already executed, active, or cancelled");
        require(proposal.proposalEpoch + coreParameters[uint256(CoreParameter.DIRECTIVE_VOTING_PERIOD_EPOCHS)] <= currentEpoch, "Voting period has not ended yet");

        uint256 totalPlasmaSupply = aetherPlasmaToken.totalSupply();
        uint256 votesNeeded = (totalPlasmaSupply * coreParameters[uint256(CoreParameter.DIRECTIVE_QUORUM_PERCENT)]) / 100;

        require(proposal.votesFor > proposal.votesAgainst, "Proposal did not pass majority vote");
        require(proposal.votesFor >= votesNeeded, "Proposal did not meet quorum");

        proposal.executed = true;
        proposal.active = true;
        proposal.expirationEpoch = currentEpoch + coreParameters[uint256(CoreParameter.DIRECTIVE_EFFECT_DURATION_EPOCHS)];

        // The actual effect logic: For a real system, this would alter global variables
        // that the _updateLifestreamState or other interaction functions read from.
        // For demonstration, we simply mark it active.
        // Example of what an effect *could* do:
        // if (proposal.effectTypeId == uint256(DirectiveEffectType.HEALTH_BOOST)) {
        //     // Temporarily increase a global "environmental_health_boost" variable
        // }

        emit EnvironmentalDirectiveExecuted(_proposalId, proposal.expirationEpoch);
    }

    // --- Information & Query Functions ---

    /**
     * @dev Retrieves comprehensive details about a specific AetherLifestream.
     * @param _lifestreamId The ID of the Lifestream.
     * @return AetherLifestream struct containing all details.
     */
    function getAetherLifestreamDetails(uint256 _lifestreamId) public view lifestreamExists(_lifestreamId) returns (AetherLifestream memory) {
        AetherLifestream storage ls = aetherLifestreams[_lifestreamId];
        // Note: For view functions, current state is implicitly shown without calling _updateLifestreamState
        // The user would need to call checkLifestreamVitality or triggerEnvironmentalEpoch to see updates.
        return ls;
    }

    /**
     * @dev Returns a list of all AetherLifestream IDs owned by a specific address.
     * @param _owner The address of the owner.
     * @return An array of Lifestream IDs.
     */
    function getAetherLifestreamsByOwner(address _owner) public view returns (uint256[] memory) {
        return ownerLifestreams[_owner];
    }

    /**
     * @dev Calculates the current vitality score of a Lifestream (Health + Energy + Resilience).
     * @param _lifestreamId The ID of the Lifestream.
     * @return The vitality score.
     */
    function checkLifestreamVitality(uint256 _lifestreamId) public view lifestreamExists(_lifestreamId) returns (uint256) {
        AetherLifestream storage ls = aetherLifestreams[_lifestreamId];
        return ls.attributes.health + ls.attributes.energy + ls.attributes.resilience;
    }

    /**
     * @dev Retrieves details about a specific environmental directive proposal.
     * @param _proposalId The ID of the proposal.
     * @return EnvironmentalDirective struct containing all details.
     */
    function getEnvironmentalDirectiveDetails(uint256 _proposalId) public view proposalExists(_proposalId) returns (EnvironmentalDirective memory) {
        return environmentalDirectives[_proposalId];
    }

    /**
     * @dev Returns a list of all environmental directives currently in effect.
     * @return An array of EnvironmentalDirective structs.
     */
    function getCurrentActiveEnvironmentalDirectives() public view returns (EnvironmentalDirective[] memory) {
        uint256 count = 0;
        for (uint256 i = 1; i < nextDirectiveId; i++) {
            if (environmentalDirectives[i].active && environmentalDirectives[i].expirationEpoch >= currentEpoch) {
                count++;
            }
        }

        EnvironmentalDirective[] memory activeDirectives = new EnvironmentalDirective[](count);
        uint256 index = 0;
        for (uint256 i = 1; i < nextDirectiveId; i++) {
            if (environmentalDirectives[i].active && environmentalDirectives[i].expirationEpoch >= currentEpoch) {
                activeDirectives[index] = environmentalDirectives[i];
                index++;
            }
        }
        return activeDirectives;
    }

    /**
     * @dev Returns a list of all environmental directives that have been executed in the past.
     * @return An array of EnvironmentalDirective structs.
     */
    function getPassedEnvironmentalDirectivesHistory() public view returns (EnvironmentalDirective[] memory) {
        uint256 count = 0;
        for (uint256 i = 1; i < nextDirectiveId; i++) {
            if (environmentalDirectives[i].executed) {
                count++;
            }
        }

        EnvironmentalDirective[] memory passedDirectives = new EnvironmentalDirective[](count);
        uint256 index = 0;
        for (uint256 i = 1; i < nextDirectiveId; i++) {
            if (environmentalDirectives[i].executed) {
                passedDirectives[index] = environmentalDirectives[i];
                index++;
            }
        }
        return passedDirectives;
    }

    /**
     * @dev Retrieves the current value of a global ecosystem parameter.
     * @param _paramId The ID of the parameter (from CoreParameter enum).
     * @return The value of the parameter.
     */
    function getCoreParameter(uint256 _paramId) public view returns (uint256) {
        return coreParameters[_paramId];
    }

    /**
     * @dev Retrieves details about an active symbiotic bond involving the specified Lifestream.
     * @param _lifestreamId The ID of the Lifestream.
     * @return _bondedToLifestreamId The ID of the Lifestream it's bonded to (0 if none).
     * @return _bondStartEpoch The epoch when the bond started (0 if none).
     * @return _isBondActive True if the bond is active and not expired.
     */
    function getSymbioticBondDetails(uint256 _lifestreamId) public view lifestreamExists(_lifestreamId) returns (uint256 _bondedToLifestreamId, uint256 _bondStartEpoch, bool _isBondActive) {
        AetherLifestream storage ls = aetherLifestreams[_lifestreamId];
        _bondedToLifestreamId = ls.bondedToLifestreamId;
        _bondStartEpoch = ls.bondStartEpoch;
        _isBondActive = (_bondedToLifestreamId != 0 && (currentEpoch - _bondStartEpoch < 5)); // Example: bond lasts 5 epochs
        return (_bondedToLifestreamId, _bondStartEpoch, _isBondActive);
    }

    /**
     * @dev Retrieves the latest "Cosmic Flux" value from the external oracle.
     * @return The current cosmic flux value.
     */
    function getCurrentCosmicFlux() public view returns (uint256) {
        return cosmicFluxOracle.getLatestFlux();
    }

    /**
     * @dev Returns the total number of AetherLifestreams that have been created.
     * @return The total count.
     */
    function getTotalAetherLifestreams() public view returns (uint256) {
        return nextLifestreamId - 1;
    }
}
```