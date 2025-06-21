Okay, let's design a smart contract centered around crafting, resource management, and dynamic item states, incorporating concepts like time-based decay/evolution, probabilistic outcomes influenced by fluctuating global factors, and non-standard token mechanics.

We'll call it `QuantumFluxForge`. Users will interact with global "Flux" and "Entropy" fields to forge unique "Artifacts" using "Essence" and "Catalysts". Artifact properties will not be static but will evolve or decay over time based on global factors.

This design incorporates:
1.  **Dynamic State:** Artifact properties changing over time (`lastEntropyUpdate`, calculated entropy).
2.  **Global Factors:** `globalFluxLevel`, `globalEntropyFactor` influencing outcomes and state.
3.  **Multiple Resource Types:** Fungible (`Essence`), Non-fungible/Consumable (`Catalyst`), Internally tracked/Pseudo-NFT (`Artifact`).
4.  **Probabilistic Outcomes:** Forging and channeling Flux involve calculated chances.
5.  **Time-Based Mechanics:** Scavenging cooldowns, entropy application over time.
6.  **Inter-dependent Mechanics:** Forging uses resources and flux, refining improves stats, stabilizing counteracts entropy, sacrificing yields resources.

It's not a standard ERC20, ERC721, AMM, Lending, or DAO contract, offering a specific game-like or simulation-like interaction model.

---

### **Smart Contract: QuantumFluxForge**

**Description:**
A smart contract simulating a mystical forge powered by fluctuating cosmic energies. Users gather 'Essence' and 'Catalysts' to forge unique 'Artifacts'. Artifacts possess dynamic properties that can change over time influenced by global 'Flux' and 'Entropy' levels. Users can attempt to channel 'Flux' to influence outcomes, 'Refine' artifacts to improve properties, 'Stabilize' them against entropy, and 'Sacrifice' them for resources.

**Core Concepts:**
*   **Artifacts:** Unique, non-standard items tracked by ID, with mutable properties (`purity`, `stability`, `charge`, `entropyResistance`). Their 'effective' properties are calculated considering time elapsed since last update and global entropy.
*   **Essence:** A fungible resource required for most actions (minting, forging, refining, stabilizing, channeling).
*   **Catalysts:** Unique, consumable items required for forging. They can possess traits that influence forging outcomes.
*   **Flux:** A global, fluctuating energy level. Higher flux might increase forging success/quality but also volatility. Can be influenced (risky) by users. Decays over time.
*   **Entropy:** A global factor causing artifacts to decay in properties over time, counteracted by artifact's `entropyResistance`. Increases over time.
*   **Dynamic Properties:** Artifact properties are affected by elapsed time and global entropy since their last modification/creation.

**Outline:**
1.  Import OpenZeppelin libraries (Ownable, Pausable).
2.  Define custom Errors.
3.  Define Structs for `Artifact`, `Catalyst`, `ForgeParameters`.
4.  Declare State Variables (mappings for items/balances, global levels, counters, parameters).
5.  Define Events.
6.  Implement Modifiers (using Ownable, Pausable).
7.  Implement Constructor.
8.  Implement Owner/Admin Functions (setting parameters, minting, distributing).
9.  Implement User Interaction Functions (forge, refine, stabilize, scavenge, channel, sacrifice, transfer).
10. Implement State Query Functions (get details, balances, global levels, cooldowns).
11. Implement Internal Helper Functions (randomness, entropy calculation).
12. Implement Pause/Unpause.

**Function Summary (26+ Functions):**

*   **Admin/Setup:**
    1.  `constructor()`: Initializes owner, sets initial parameters.
    2.  `setForgeParameters(ForgeParameters _params)`: Owner sets crafting costs, cooldowns, success rates, etc.
    3.  `mintEssence(address _to, uint256 _amount)`: Owner mints Essence to an address.
    4.  `distributeCatalyst(address _to, uint256 _catalystId, uint256 _trait1, uint256 _trait2)`: Owner distributes a Catalyst with specific traits.
    5.  `setGlobalFactors(uint256 _flux, uint256 _entropyFactor)`: Owner manually sets global Flux and Entropy (emergency/override).
    6.  `setCatalystTraits(uint256 _catalystId, uint256 _trait1, uint256 _trait2)`: Owner updates traits of an existing Catalyst (if not used).
    7.  `pause()`: Owner pauses contract actions.
    8.  `unpause()`: Owner unpauses contract actions.
    9.  `renounceOwnership()`: Owner renounces ownership (from Ownable).
    10. `transferOwnership(address newOwner)`: Owner transfers ownership (from Ownable).
    11. `withdrawFees()`: If any fees accumulate (design could add this), owner withdraws. (Let's add a conceptual fee/burn to some actions).

*   **User Actions:**
    12. `forgeArtifact(uint256 _catalystId)`: Craft a new Artifact using Essence and a specific Catalyst. Outcome depends on Catalyst traits, Flux, and parameters. Consumes Catalyst and Essence. Applies cooldown.
    13. `refineArtifact(uint256 _artifactId, uint256 _essenceAmount)`: Spend Essence to attempt to improve an Artifact's properties (`purity`, `stability`, `charge`). Success/degree influenced by Flux. Updates artifact's `lastEntropyUpdate`.
    14. `stabilizeArtifact(uint256 _artifactId, uint256 _essenceAmount)`: Spend Essence to attempt to improve an Artifact's `entropyResistance`. Success/degree influenced by Flux. Updates artifact's `lastEntropyUpdate`.
    15. `scavengeEssence()`: A time-locked action to gain a small amount of free Essence. Applies cooldown.
    16. `channelFlux(uint256 _essenceAmount)`: Spend Essence in a risky attempt to increase the global Flux level. Has a chance of success or failure (potentially *decreasing* Flux).
    17. `sacrificeArtifact(uint256 _artifactId)`: Burn an Artifact to regain a portion of Essence, and potentially a chance of gaining a Catalyst or increasing Flux.
    18. `transferArtifact(address _to, uint256 _artifactId)`: Transfer ownership of an Artifact.
    19. `burnEssence(uint256 _amount)`: Burn Essence owned by the caller (maybe for a future feature or just cleanup).

*   **Query Functions:**
    20. `getArtifactDetails(uint256 _artifactId)`: Get all stored details of an Artifact (raw state).
    21. `getEffectiveArtifactProperties(uint256 _artifactId)`: Calculate and return the Artifact's properties after applying entropy decay based on current time and global factors.
    22. `getEssenceBalance(address _owner)`: Get the Essence balance of an address.
    23. `getCatalystOwner(uint256 _catalystId)`: Get the owner of a Catalyst.
    24. `getGlobalFluxLevel()`: Get the current global Flux level.
    25. `getGlobalEntropyFactor()`: Get the current global Entropy factor.
    26. `getTimeToNextScavenge(address _owner)`: Get seconds remaining until an address can scavenge again.
    27. `getTimeToNextForge(address _owner)`: Get seconds remaining until an address can forge again.
    28. `getForgeParameters()`: Get the current Forge Parameters.
    29. `getCatalystDetails(uint256 _catalystId)`: Get traits and owner of a Catalyst.
    30. `getTotalArtifactsMinted()`: Get the total number of artifacts ever created.

*   **Internal/Utility (Not directly callable by user usually, but part of logic):**
    *   `_generateRandomSeed()`: Helper for pseudo-randomness.
    *   `_applyEntropyDecay(Artifact storage _artifact)`: Internal logic to calculate decay. (Used within `getEffectiveArtifactProperties` and modification functions).
    *   `_updateGlobalFactors()`: Internal logic to decay Flux and increase Entropy over time. (Could be called by owner periodically or triggered by specific actions - let's make it triggered on certain actions like forge/scavenge/channel).

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

// --- Smart Contract: QuantumFluxForge ---
// Description:
// A smart contract simulating a mystical forge powered by fluctuating cosmic energies.
// Users gather 'Essence' and 'Catalysts' to forge unique 'Artifacts'. Artifacts possess
// dynamic properties that can change over time influenced by global 'Flux' and 'Entropy' levels.
// Users can attempt to channel 'Flux' to influence outcomes, 'Refine' artifacts to improve
// properties, 'Stabilize' them against entropy, and 'Sacrifice' them for resources.
//
// Core Concepts:
// - Artifacts: Unique, non-standard items tracked by ID, with mutable properties. Effective
//   properties are calculated based on time and global entropy.
// - Essence: A fungible resource.
// - Catalysts: Unique, consumable items for forging, can have traits influencing outcomes.
// - Flux: Global, fluctuating energy influencing outcomes and state evolution. Decays over time.
// - Entropy: Global factor causing artifact property decay over time. Increases over time.
// - Dynamic Properties: Artifact stats are affected by elapsed time and global entropy.
//
// Outline:
// 1. Imports (Ownable, Pausable)
// 2. Custom Errors
// 3. Struct Definitions (Artifact, Catalyst, ForgeParameters)
// 4. State Variables
// 5. Events
// 6. Modifiers (using Pausable)
// 7. Constructor
// 8. Admin/Setup Functions (set parameters, mint resources, manage global factors)
// 9. User Interaction Functions (forge, refine, stabilize, scavenge, channel, sacrifice, transfer, burn)
// 10. State Query Functions (get item details, balances, global levels, cooldowns)
// 11. Internal Helper Functions (randomness, entropy calculation, global factor update)

contract QuantumFluxForge is Ownable, Pausable {

    // --- Custom Errors ---
    error InsufficientEssence(uint256 required, uint256 has);
    error ArtifactNotFound(uint256 artifactId);
    error CatalystNotFound(uint256 catalystId);
    error NotArtifactOwner(uint256 artifactId, address caller);
    error NotCatalystOwner(uint256 catalystId, address caller);
    error CatalystAlreadyUsed(uint256 catalystId);
    error ScavengeCooldownActive(uint256 timeLeft);
    error ForgeCooldownActive(uint256 timeLeft);
    error CannotTransferUsedCatalyst();
    error NothingToWithdraw();

    // --- Struct Definitions ---

    struct Artifact {
        uint256 id;
        address owner;
        uint256 purity; // Higher is better
        uint256 stability; // Higher is better
        uint256 charge; // Higher is better
        uint256 entropyResistance; // Higher is better resistance to decay
        uint40 creationTime;
        uint40 lastEntropyUpdate; // Timestamp when properties were last modified/checked
    }

    struct Catalyst {
        uint256 id;
        address owner;
        bool usedInForge;
        uint256 trait1; // Example trait affecting forging
        uint256 trait2; // Example trait affecting forging
    }

    struct ForgeParameters {
        uint256 forgeEssenceCost;
        uint256 forgeCooldown; // Per user
        uint256 refineEssenceCost;
        uint256 stabilizeEssenceCost;
        uint256 scavengeCooldown; // Per user
        uint256 scavengeEssenceAmount;
        uint256 channelFluxEssenceCost;
        uint256 sacrificeEssenceReturnPercent; // Percentage of forge cost returned
        uint256 fluxChannelSuccessChance; // Out of 10000
        uint256 fluxChannelAmount; // Amount flux changes on success/failure
        uint256 fluxDecayRatePerSecond;
        uint256 entropyIncreaseRatePerSecond;
    }

    // --- State Variables ---

    mapping(uint256 => Artifact) private artifacts;
    mapping(uint256 => Catalyst) private catalysts;
    mapping(address => uint256) private essenceBalances;

    mapping(address => uint40) private lastScavengeTime;
    mapping(address => uint40) private lastForgeTime;

    uint256 private nextArtifactId;
    uint256 private nextCatalystId;
    uint256 public essenceTotalSupply;
    uint256 public globalFluxLevel; // Can be thought of as a multiplier/factor
    uint256 public globalEntropyFactor; // Can be thought of as a multiplier/factor

    uint40 private lastGlobalFactorUpdateTime; // Timestamp of last update

    ForgeParameters public forgeParams;

    uint256 public totalProtocolFees; // Accumulated essence from transactions

    // --- Events ---

    event ArtifactForged(uint256 indexed artifactId, address indexed owner, uint256 purity, uint256 stability, uint256 charge, uint256 entropyResistance);
    event ArtifactRefined(uint256 indexed artifactId, uint256 newPurity, uint256 newStability, uint256 newCharge);
    event ArtifactStabilized(uint256 indexed artifactId, uint256 newEntropyResistance);
    event ArtifactSacrificed(uint256 indexed artifactId, address indexed owner, uint256 essenceReturned);
    event ArtifactTransferred(uint256 indexed artifactId, address indexed from, address indexed to);
    event EssenceMinted(address indexed to, uint256 amount);
    event EssenceBurned(address indexed from, uint256 amount);
    event CatalystDistributed(uint256 indexed catalystId, address indexed to, uint256 trait1, uint256 trait2);
    event CatalystUsed(uint256 indexed catalystId, uint256 indexed inArtifactId);
    event ScavengeCompleted(address indexed owner, uint256 amount);
    event FluxChanneled(address indexed owner, bool success, int256 fluxChange, uint256 newFluxLevel);
    event GlobalFactorsUpdated(uint256 newFlux, uint256 newEntropyFactor, uint40 updateTime);
    event ForgeParametersUpdated(ForgeParameters newParams);
    event ProtocolFeesWithdrawn(address indexed to, uint256 amount);

    // --- Modifiers ---
    // Using Pausable's `whenNotPaused` and `whenPaused`

    // --- Constructor ---
    constructor() Ownable(msg.sender) Pausable(false) {
        nextArtifactId = 1;
        nextCatalystId = 1;
        essenceTotalSupply = 0;
        globalFluxLevel = 5000; // Starting flux (e.g., 0-10000 range)
        globalEntropyFactor = 100; // Starting entropy factor (e.g., higher is worse)
        lastGlobalFactorUpdateTime = uint40(block.timestamp);

        forgeParams = ForgeParameters({
            forgeEssenceCost: 100,
            forgeCooldown: 1 days,
            refineEssenceCost: 50,
            stabilizeEssenceCost: 75,
            scavengeCooldown: 4 hours,
            scavengeEssenceAmount: 10,
            channelFluxEssenceCost: 200,
            sacrificeEssenceReturnPercent: 50, // 50% of forge cost
            fluxChannelSuccessChance: 3000, // 30% success chance
            fluxChannelAmount: 1000, // +- 1000 flux on success/failure
            fluxDecayRatePerSecond: 1, // 1 flux decrease per second
            entropyIncreaseRatePerSecond: 1 // 1 entropy increase per second
        });
    }

    // --- Admin/Setup Functions ---

    /// @notice Allows owner to set the core parameters for forging, refining, etc.
    /// @param _params The new ForgeParameters struct.
    function setForgeParameters(ForgeParameters memory _params) public onlyOwner {
        forgeParams = _params;
        emit ForgeParametersUpdated(_params);
    }

    /// @notice Allows owner to mint Essence and distribute it.
    /// @param _to The address to mint Essence to.
    /// @param _amount The amount of Essence to mint.
    function mintEssence(address _to, uint256 _amount) public onlyOwner whenNotPaused {
        essenceBalances[_to] += _amount;
        essenceTotalSupply += _amount;
        emit EssenceMinted(_to, _amount);
    }

    /// @notice Allows owner to distribute a new Catalyst with specified traits.
    /// @param _to The address to give the Catalyst to.
    /// @param _trait1 The first trait value for the Catalyst.
    /// @param _trait2 The second trait value for the Catalyst.
    function distributeCatalyst(address _to, uint256 _trait1, uint256 _trait2) public onlyOwner whenNotPaused {
        uint256 catalystId = nextCatalystId++;
        catalysts[catalystId] = Catalyst({
            id: catalystId,
            owner: _to,
            usedInForge: false,
            trait1: _trait1,
            trait2: _trait2
        });
        emit CatalystDistributed(catalystId, _to, _trait1, _trait2);
    }

    /// @notice Allows owner to manually set the global Flux and Entropy levels. Use cautiously.
    /// @param _flux The new global Flux level.
    /// @param _entropyFactor The new global Entropy factor.
    function setGlobalFactors(uint256 _flux, uint256 _entropyFactor) public onlyOwner {
        globalFluxLevel = _flux;
        globalEntropyFactor = _entropyFactor;
        lastGlobalFactorUpdateTime = uint40(block.timestamp);
        emit GlobalFactorsUpdated(globalFluxLevel, globalEntropyFactor, lastGlobalFactorUpdateTime);
    }

    /// @notice Allows owner to update traits of a Catalyst *if it hasn't been used yet*.
    /// @param _catalystId The ID of the Catalyst to update.
    /// @param _trait1 The new first trait value.
    /// @param _trait2 The new second trait value.
    function setCatalystTraits(uint256 _catalystId, uint256 _trait1, uint256 _trait2) public onlyOwner whenNotPaused {
        Catalyst storage catalyst = catalysts[_catalystId];
        if (catalyst.id == 0 || catalyst.usedInForge) {
            revert CatalystNotFound(_catalystId); // Or specific error for used catalyst
        }
        catalyst.trait1 = _trait1;
        catalyst.trait2 = _trait2;
        // No specific event, assumes traits are set before distribution/use
    }

    /// @notice Allows the owner to withdraw any accumulated protocol fees (Essence burned from user actions).
    function withdrawFees() public onlyOwner {
        uint256 amount = totalProtocolFees;
        if (amount == 0) {
            revert NothingToWithdraw();
        }
        totalProtocolFees = 0;
        essenceBalances[msg.sender] += amount;
        emit ProtocolFeesWithdrawn(msg.sender, amount);
    }


    // --- User Interaction Functions ---

    /// @notice Allows a user to forge a new Artifact using Essence and a Catalyst.
    /// @param _catalystId The ID of the Catalyst to use.
    function forgeArtifact(uint256 _catalystId) public whenNotPaused {
        _updateGlobalFactors();

        if (essenceBalances[msg.sender] < forgeParams.forgeEssenceCost) {
            revert InsufficientEssence(forgeParams.forgeEssenceCost, essenceBalances[msg.sender]);
        }

        uint40 lastForge = lastForgeTime[msg.sender];
        if (block.timestamp < lastForge + forgeParams.forgeCooldown) {
             revert ForgeCooldownActive(lastForge + forgeParams.forgeCooldown - uint40(block.timestamp));
        }

        Catalyst storage catalyst = catalysts[_catalystId];
        if (catalyst.id == 0) {
            revert CatalystNotFound(_catalystId);
        }
        if (catalyst.owner != msg.sender) {
             revert NotCatalystOwner(_catalystId, msg.sender);
        }
        if (catalyst.usedInForge) {
            revert CatalystAlreadyUsed(_catalystId);
        }

        // Consume resources
        essenceBalances[msg.sender] -= forgeParams.forgeEssenceCost;
        totalProtocolFees += forgeParams.forgeEssenceCost; // Essence goes to fees

        catalyst.usedInForge = true; // Mark catalyst as used
        // Catalyst ownership remains with user, but it's "used"

        uint256 artifactId = nextArtifactId++;
        uint40 currentTime = uint40(block.timestamp);

        // --- Forging Logic: Probabilistic Outcome ---
        // Outcome influenced by Catalyst traits and current Flux level
        uint256 seed = _generateRandomSeed();
        uint256 fluxInfluence = globalFluxLevel / 100; // Scale flux to a smaller range (0-100)

        // Example simplistic outcome calculation:
        uint256 basePurity = (seed % 50) + 50; // Base 50-99
        uint256 traitInfluence = (catalyst.trait1 + catalyst.trait2) / 2;
        uint256 fluxBonus = (fluxInfluence * (seed % 10)) / 100; // Flux adds a bonus

        uint256 purity = basePurity + traitInfluence + fluxBonus;
        uint256 stability = 100 + (seed % 50) + (fluxInfluence / 2) - (traitInfluence / 5); // Base 100+, influenced by flux/traits
        uint256 charge = (seed % 200); // 0-199
        uint256 entropyResistance = 50 + (catalyst.trait1 % 50) + (fluxInfluence / 4); // Base 50+, influenced by trait1/flux

        // Clamp values (example limits)
        purity = purity > 200 ? 200 : purity; // Max purity 200
        stability = stability > 300 ? 300 : stability; // Max stability 300
        entropyResistance = entropyResistance > 150 ? 150 : entropyResistance; // Max resistance 150

        Artifact storage newArtifact = artifacts[artifactId];
        newArtifact.id = artifactId;
        newArtifact.owner = msg.sender;
        newArtifact.purity = purity;
        newArtifact.stability = stability;
        newArtifact.charge = charge;
        newArtifact.entropyResistance = entropyResistance;
        newArtifact.creationTime = currentTime;
        newArtifact.lastEntropyUpdate = currentTime; // Initialize last update time

        lastForgeTime[msg.sender] = currentTime; // Set forge cooldown

        emit ArtifactForged(artifactId, msg.sender, purity, stability, charge, entropyResistance);
        emit CatalystUsed(_catalystId, artifactId);
    }

    /// @notice Allows a user to spend Essence to refine an Artifact, improving its properties.
    /// @param _artifactId The ID of the Artifact to refine.
    /// @param _essenceAmount The amount of Essence to spend.
    function refineArtifact(uint256 _artifactId, uint256 _essenceAmount) public whenNotPaused {
        _updateGlobalFactors();

        Artifact storage artifact = artifacts[_artifactId];
        if (artifact.id == 0) {
            revert ArtifactNotFound(_artifactId);
        }
        if (artifact.owner != msg.sender) {
            revert NotArtifactOwner(_artifactId, msg.sender);
        }
        if (essenceBalances[msg.sender] < _essenceAmount) {
            revert InsufficientEssence(_essenceAmount, essenceBalances[msg.sender]);
        }
        if (_essenceAmount < forgeParams.refineEssenceCost) {
             revert InsufficientEssence(forgeParams.refineEssenceCost, _essenceAmount); // Must meet min cost
        }


        essenceBalances[msg.sender] -= _essenceAmount;
        totalProtocolFees += _essenceAmount; // Essence goes to fees

        // Apply entropy decay before refining, then reset lastEntropyUpdate
        (uint256 currentPurity, uint256 currentStability, uint256 currentCharge) = _getEffectiveArtifactProperties(artifact);
        artifact.purity = currentPurity;
        artifact.stability = currentStability;
        artifact.charge = currentCharge;

        // --- Refining Logic ---
        uint256 seed = _generateRandomSeed();
        uint256 fluxInfluence = globalFluxLevel / 100; // Scale flux to a smaller range (0-100)
        uint256 refinePower = (_essenceAmount / forgeParams.refineEssenceCost) * 10; // More essence = more power

        // Improvements influenced by refine power and flux
        artifact.purity += (refinePower * (seed % 100)) / 10000; // Up to refinePower * 0.01
        artifact.stability += (refinePower * (seed % 100)) / 10000;
        artifact.charge += (refinePower * (seed % 150)) / 15000;

        // Add flux-based bonus/penalty
        if (seed % 100 < fluxInfluence) { // Chance based on flux
            artifact.purity += fluxInfluence / 10;
            artifact.stability += fluxInfluence / 10;
        } else if (seed % 100 > 100 - (fluxInfluence/2)) { // Risk of negative from high flux volatility
             artifact.purity -= fluxInfluence / 20;
             artifact.stability -= fluxInfluence / 20;
        }


        // Clamp values again
        artifact.purity = artifact.purity > 200 ? 200 : (artifact.purity < 0 ? 0 : artifact.purity);
        artifact.stability = artifact.stability > 300 ? 300 : (artifact.stability < 0 ? 0 : artifact.stability);
        artifact.charge = artifact.charge > 300 ? 300 : (artifact.charge < 0 ? 0 : artifact.charge); // Allow charge to go higher than initial max

        artifact.lastEntropyUpdate = uint40(block.timestamp); // Reset entropy timer

        emit ArtifactRefined(_artifactId, artifact.purity, artifact.stability, artifact.charge);
    }

    /// @notice Allows a user to spend Essence to stabilize an Artifact, improving its entropy resistance.
    /// @param _artifactId The ID of the Artifact to stabilize.
    /// @param _essenceAmount The amount of Essence to spend.
    function stabilizeArtifact(uint256 _artifactId, uint256 _essenceAmount) public whenNotPaused {
         _updateGlobalFactors();

        Artifact storage artifact = artifacts[_artifactId];
        if (artifact.id == 0) {
            revert ArtifactNotFound(_artifactId);
        }
        if (artifact.owner != msg.sender) {
            revert NotArtifactOwner(_artifactId, msg.sender);
        }
         if (essenceBalances[msg.sender] < _essenceAmount) {
            revert InsufficientEssence(_essenceAmount, essenceBalances[msg.sender]);
        }
         if (_essenceAmount < forgeParams.stabilizeEssenceCost) {
             revert InsufficientEssence(forgeParams.stabilizeEssenceCost, _essenceAmount); // Must meet min cost
        }

        essenceBalances[msg.sender] -= _essenceAmount;
        totalProtocolFees += _essenceAmount; // Essence goes to fees

        // Apply entropy decay before stabilizing, then reset lastEntropyUpdate
        (uint256 currentPurity, uint256 currentStability, uint256 currentCharge) = _getEffectiveArtifactProperties(artifact);
        artifact.purity = currentPurity; // Update stored stats after decay calculation
        artifact.stability = currentStability;
        artifact.charge = currentCharge;


        // --- Stabilizing Logic ---
        uint256 seed = _generateRandomSeed();
        uint256 stabilizePower = (_essenceAmount / forgeParams.stabilizeEssenceCost) * 5; // More essence = more power

        artifact.entropyResistance += (stabilizePower * (seed % 100)) / 10000; // Up to stabilizePower * 0.01

        // Add flux-based bonus/penalty
        if (seed % 100 < (globalFluxLevel / 200)) { // Chance based on Flux (lower chance)
             artifact.entropyResistance += globalFluxLevel / 400;
        }

        // Clamp values
        artifact.entropyResistance = artifact.entropyResistance > 200 ? 200 : artifact.entropyResistance; // Max resistance 200

        artifact.lastEntropyUpdate = uint40(block.timestamp); // Reset entropy timer

        emit ArtifactStabilized(_artifactId, artifact.entropyResistance);
    }

    /// @notice Allows a user to perform a time-locked scavenge action to gain Essence.
    function scavengeEssence() public whenNotPaused {
         _updateGlobalFactors(); // Update global factors before action

        uint40 lastScavenge = lastScavengeTime[msg.sender];
        if (block.timestamp < lastScavenge + forgeParams.scavengeCooldown) {
            revert ScavengeCooldownActive(lastScavenge + forgeParams.scavengeCooldown - uint40(block.timestamp));
        }

        uint256 amountGained = forgeParams.scavengeEssenceAmount;
        // Optionally add minor variation based on Flux or seed
        uint256 seed = _generateRandomSeed();
        amountGained += (seed % (globalFluxLevel / 1000 + 1)); // Add minor bonus based on flux

        essenceBalances[msg.sender] += amountGained;
        essenceTotalSupply += amountGained; // Scavenging creates new essence

        lastScavengeTime[msg.sender] = uint40(block.timestamp);

        emit ScavengeCompleted(msg.sender, amountGained);
    }

    /// @notice Allows a user to spend Essence in a risky attempt to influence the global Flux level.
    /// @param _essenceAmount The amount of Essence to spend. Must meet minimum cost.
    function channelFlux(uint256 _essenceAmount) public whenNotPaused {
         _updateGlobalFactors(); // Update global factors before action

        if (essenceBalances[msg.sender] < _essenceAmount) {
            revert InsufficientEssence(_essenceAmount, essenceBalances[msg.sender]);
        }
        if (_essenceAmount < forgeParams.channelFluxEssenceCost) {
            revert InsufficientEssence(forgeParams.channelFluxEssenceCost, _essenceAmount); // Must meet min cost
        }

        essenceBalances[msg.sender] -= _essenceAmount;
        totalProtocolFees += _essenceAmount; // Essence goes to fees

        uint256 seed = _generateRandomSeed();
        bool success = (seed % 10000) < forgeParams.fluxChannelSuccessChance;
        int256 fluxChange;
        uint256 oldFlux = globalFluxLevel;

        if (success) {
            fluxChange = int256(forgeParams.fluxChannelAmount);
            globalFluxLevel += forgeParams.fluxChannelAmount;
             // Clamp max flux
            if (globalFluxLevel > 10000) globalFluxLevel = 10000;

        } else {
            fluxChange = -int256(forgeParams.fluxChannelAmount);
            // Ensure flux doesn't go below 0
            if (globalFluxLevel >= forgeParams.fluxChannelAmount) {
                globalFluxLevel -= forgeParams.fluxChannelAmount;
            } else {
                globalFluxLevel = 0;
            }
        }

        // Also slightly increase entropy as channeling is volatile
        globalEntropyFactor += (seed % 50) + 1; // Always some entropy increase
         // Clamp max entropy
        if (globalEntropyFactor > 500) globalEntropyFactor = 500;


        lastGlobalFactorUpdateTime = uint40(block.timestamp); // Global factors just changed

        emit FluxChanneled(msg.sender, success, fluxChange, globalFluxLevel);
        emit GlobalFactorsUpdated(globalFluxLevel, globalEntropyFactor, lastGlobalFactorUpdateTime);
    }

    /// @notice Allows a user to burn an Artifact to regain some Essence and potentially other resources.
    /// @param _artifactId The ID of the Artifact to sacrifice.
    function sacrificeArtifact(uint256 _artifactId) public whenNotPaused {
        Artifact storage artifact = artifacts[_artifactId];
        if (artifact.id == 0) {
            revert ArtifactNotFound(_artifactId);
        }
        if (artifact.owner != msg.sender) {
            revert NotArtifactOwner(_artifactId, msg.sender);
        }

        address owner = artifact.owner; // Store owner before deleting

        // Return a percentage of the initial forge cost
        uint256 essenceReturn = (forgeParams.forgeEssenceCost * forgeParams.sacrificeEssenceReturnPercent) / 100;
        essenceBalances[owner] += essenceReturn;
        // Note: This Essence is effectively re-minted from the protocol fees pool.

        // Optional: Chance to gain Catalyst or influence Flux based on artifact quality or seed
        uint265 seed = _generateRandomSeed();
        if (artifact.purity > 150 && seed % 100 < 10) { // 10% chance for high purity items
             // Example: Distribute a low-trait catalyst back
             distributeCatalyst(owner, seed % 10, seed % 10); // Low traits
        }
        if (artifact.stability < 50 && seed % 100 < 20) { // 20% chance for unstable items to cause flux spike
             globalFluxLevel += (seed % 500) + 100;
             if (globalFluxLevel > 10000) globalFluxLevel = 10000;
             lastGlobalFactorUpdateTime = uint40(block.timestamp);
             emit GlobalFactorsUpdated(globalFluxLevel, globalEntropyFactor, lastGlobalFactorUpdateTime);
        }


        delete artifacts[_artifactId]; // Burn the artifact data

        emit ArtifactSacrificed(_artifactId, owner, essenceReturn);
    }

     /// @notice Allows a user to transfer ownership of an Artifact to another address.
     /// @param _to The recipient address.
     /// @param _artifactId The ID of the Artifact to transfer.
    function transferArtifact(address _to, uint256 _artifactId) public whenNotPaused {
        Artifact storage artifact = artifacts[_artifactId];
        if (artifact.id == 0) {
            revert ArtifactNotFound(_artifactId);
        }
        if (artifact.owner != msg.sender) {
            revert NotArtifactOwner(_artifactId, msg.sender);
        }

        address from = artifact.owner;
        artifact.owner = _to;

        emit ArtifactTransferred(_artifactId, from, _to);
    }

    /// @notice Allows a user to burn their own Essence. Does not give anything back.
    /// @param _amount The amount of Essence to burn.
    function burnEssence(uint256 _amount) public whenNotPaused {
        if (essenceBalances[msg.sender] < _amount) {
            revert InsufficientEssence(_amount, essenceBalances[msg.sender]);
        }
        essenceBalances[msg.sender] -= _amount;
        // total supply decreases, protocol fees do not increase as this is a voluntary burn
        essenceTotalSupply -= _amount;
        emit EssenceBurned(msg.sender, _amount);
    }


    // --- Query Functions ---

    /// @notice Gets the raw stored details of an Artifact before applying entropy.
    /// @param _artifactId The ID of the Artifact.
    /// @return The Artifact struct data.
    function getArtifactDetails(uint256 _artifactId) public view returns (Artifact memory) {
        Artifact memory artifact = artifacts[_artifactId];
         if (artifact.id == 0) {
            revert ArtifactNotFound(_artifactId);
        }
        return artifact;
    }

     /// @notice Calculates and returns the effective properties of an Artifact after applying entropy decay.
     /// @param _artifactId The ID of the Artifact.
     /// @return purity, stability, charge (effective values).
    function getEffectiveArtifactProperties(uint256 _artifactId) public view returns (uint256 purity, uint256 stability, uint256 charge) {
         Artifact memory artifact = artifacts[_artifactId];
         if (artifact.id == 0) {
            revert ArtifactNotFound(_artifactId);
        }

        // Calculate elapsed time since last update or creation
        uint256 timeElapsed = block.timestamp - artifact.lastEntropyUpdate;
        if (timeElapsed == 0) { // No time elapsed, return current stored values
            return (artifact.purity, artifact.stability, artifact.charge);
        }

        // Calculate current global factors based on decay/increase rates since last update
        (uint256 currentFlux, uint256 currentEntropyFactor) = _getEffectiveGlobalFactors();

        // Calculate decay amount based on time, entropy factor, and artifact resistance
        // Decay rate is proportional to timeElapsed and currentEntropyFactor, inversely proportional to entropyResistance
        // Using safe math internally is assumed here, but actual impl would need care.
        // Example decay calculation: decay = (timeElapsed * currentEntropyFactor) / artifact.entropyResistance
        // Need to handle division by zero if resistance can be 0. Assume min resistance > 0.

        uint256 effectiveResistance = artifact.entropyResistance == 0 ? 1 : artifact.entropyResistance; // Prevent div by zero
        uint256 entropyInfluencePerSecond = currentEntropyFactor * 1000 / effectiveResistance; // Scale factor

        uint256 totalDecay = (timeElapsed * entropyInfluencePerSecond) / 1000; // Total decay units

        // Apply decay to properties (e.g., purity, stability, charge)
        // Decay applies based on base value, capped at 0.
        purity = artifact.purity > totalDecay ? artifact.purity - totalDecay : 0;
        stability = artifact.stability > totalDecay ? artifact.stability - totalDecay : 0;
        charge = artifact.charge > totalDecay ? artifact.charge - totalDecay : 0; // Charge can decay too

        // Flux could also influence volatility/decay rate, adding another layer
        // Example: Higher flux increases decay variance
        // uint256 fluxVariance = (currentFlux / 100) * (seed % 20 - 10); // +/- 10% decay variance based on flux
        // totalDecay = totalDecay * (10000 + fluxVariance) / 10000;
        // (This would need a seed which view functions don't have reliable access to; maybe pre-calculate?)
        // For simplicity in view function, stick to deterministic decay based on time and factors.

        return (purity, stability, charge);
    }


    /// @notice Gets the Essence balance for a given address.
    /// @param _owner The address to check.
    /// @return The balance of Essence.
    function getEssenceBalance(address _owner) public view returns (uint256) {
        return essenceBalances[_owner];
    }

    /// @notice Gets the owner of a specific Catalyst.
    /// @param _catalystId The ID of the Catalyst.
    /// @return The owner address. Returns address(0) if not found.
    function getCatalystOwner(uint256 _catalystId) public view returns (address) {
        return catalysts[_catalystId].owner;
    }

    /// @notice Gets the current global Flux level. This value updates over time.
    /// @return The global Flux level.
    function getGlobalFluxLevel() public view returns (uint256) {
        (uint256 currentFlux, ) = _getEffectiveGlobalFactors();
        return currentFlux;
    }

    /// @notice Gets the current global Entropy factor. This value updates over time.
    /// @return The global Entropy factor.
    function getGlobalEntropyFactor() public view returns (uint256) {
        (, uint256 currentEntropyFactor) = _getEffectiveGlobalFactors();
        return currentEntropyFactor;
    }

    /// @notice Gets the seconds remaining until a user can scavenge Essence again.
    /// @param _owner The address to check.
    /// @return The time remaining in seconds. Returns 0 if no cooldown is active.
    function getTimeToNextScavenge(address _owner) public view returns (uint256) {
        uint40 lastScavenge = lastScavengeTime[_owner];
        uint256 cooldownEnd = lastScavenge + forgeParams.scavengeCooldown;
        if (block.timestamp < cooldownEnd) {
            return cooldownEnd - uint40(block.timestamp);
        }
        return 0;
    }

    /// @notice Gets the seconds remaining until a user can forge an Artifact again.
    /// @param _owner The address to check.
    /// @return The time remaining in seconds. Returns 0 if no cooldown is active.
    function getTimeToNextForge(address _owner) public view returns (uint256) {
        uint40 lastForge = lastForgeTime[_owner];
         uint256 cooldownEnd = lastForge + forgeParams.forgeCooldown;
        if (block.timestamp < cooldownEnd) {
            return cooldownEnd - uint40(block.timestamp);
        }
        return 0;
    }

    /// @notice Gets the current ForgeParameters struct.
    /// @return The current ForgeParameters.
    function getForgeParameters() public view returns (ForgeParameters memory) {
        return forgeParams;
    }

    /// @notice Gets the details of a specific Catalyst.
    /// @param _catalystId The ID of the Catalyst.
    /// @return id, owner, usedInForge, trait1, trait2. Returns default values if not found.
    function getCatalystDetails(uint256 _catalystId) public view returns (uint256 id, address owner, bool usedInForge, uint256 trait1, uint256 trait2) {
        Catalyst memory catalyst = catalysts[_catalystId];
         if (catalyst.id == 0 && _catalystId != 0) { // Check specifically for id > 0
             revert CatalystNotFound(_catalystId);
         }
        return (catalyst.id, catalyst.owner, catalyst.usedInForge, catalyst.trait1, catalyst.trait2);
    }

    /// @notice Gets the total number of Artifacts ever minted.
    /// @return The total count of artifacts created.
    function getTotalArtifactsMinted() public view returns (uint256) {
        return nextArtifactId - 1;
    }

     /// @notice Gets the total Essence held by the protocol (from transaction fees).
     /// @return The amount of Essence held as fees.
    function getProtocolFees() public view returns (uint256) {
        return totalProtocolFees;
    }


    // --- Internal Helper Functions ---

    /// @dev Generates a pseudo-random seed based on block data. NOT secure for critical randomness.
    /// Use Chainlink VRF or similar for production systems needing strong randomness.
    function _generateRandomSeed() internal view returns (uint256) {
        // Combine recent block hash, timestamp, and sender address for basic entropy
        return uint256(keccak256(abi.encodePacked(blockhash(block.number - 1), block.timestamp, msg.sender)));
    }

    /// @dev Internal function to calculate the current global Flux and Entropy levels based on time elapsed.
    /// @return currentFlux, currentEntropyFactor
    function _getEffectiveGlobalFactors() internal view returns (uint256 currentFlux, uint256 currentEntropyFactor) {
         uint256 timeElapsed = block.timestamp - lastGlobalFactorUpdateTime;

         // Decay Flux
         uint256 fluxDecay = timeElapsed * forgeParams.fluxDecayRatePerSecond;
         currentFlux = globalFluxLevel > fluxDecay ? globalFluxLevel - fluxDecay : 0;

         // Increase Entropy
         uint256 entropyIncrease = timeElapsed * forgeParams.entropyIncreaseRatePerSecond;
         currentEntropyFactor = globalEntropyFactor + entropyIncrease;
         // Clamp max entropy (example limit)
         currentEntropyFactor = currentEntropyFactor > 500 ? 500 : currentEntropyFactor;

         return (currentFlux, currentEntropyFactor);
    }

    /// @dev Internal function to apply the entropy decay to an artifact's stored properties.
    /// This is called BEFORE modifying an artifact or when getting effective properties,
    /// then lastEntropyUpdate is reset.
    /// @param _artifact The artifact storage reference.
    /// @return purity, stability, charge (values after decay calculation).
    function _applyEntropyDecay(Artifact storage _artifact) internal view returns (uint256 purity, uint256 stability, uint256 charge) {
        uint256 timeElapsed = block.timestamp - _artifact.lastEntropyUpdate;
        if (timeElapsed == 0) {
             return (_artifact.purity, _artifact.stability, _artifact.charge);
        }

        (uint256 currentFlux, uint256 currentEntropyFactor) = _getEffectiveGlobalFactors();

        uint256 effectiveResistance = _artifact.entropyResistance == 0 ? 1 : _artifact.entropyResistance;
        uint256 entropyInfluencePerSecond = currentEntropyFactor * 1000 / effectiveResistance; // Scale factor

        uint256 totalDecay = (timeElapsed * entropyInfluencePerSecond) / 1000;

        purity = _artifact.purity > totalDecay ? _artifact.purity - totalDecay : 0;
        stability = _artifact.stability > totalDecay ? _artifact.stability - totalDecay : 0;
        charge = _artifact.charge > totalDecay ? _artifact.charge - totalDecay : 0;

        // Note: This internal helper calculates decay but does *not* update the artifact's storage
        // or lastEntropyUpdate time itself. That must be done by the calling function (refine, stabilize, etc.)
        return (purity, stability, charge);
    }

    /// @dev Internal helper to update the global Flux and Entropy levels based on elapsed time and store the new levels.
    /// This is called at the beginning of user interaction functions that consume resources or have side effects
    /// on the global state (forge, refine, stabilize, scavenge, channel).
    function _updateGlobalFactors() internal {
         uint256 timeElapsed = block.timestamp - lastGlobalFactorUpdateTime;
         if (timeElapsed == 0) return; // Already updated recently

        // Decay Flux
        uint256 fluxDecay = timeElapsed * forgeParams.fluxDecayRatePerSecond;
        globalFluxLevel = globalFluxLevel > fluxDecay ? globalFluxLevel - fluxDecay : 0;

        // Increase Entropy
        uint256 entropyIncrease = timeElapsed * forgeParams.entropyIncreaseRatePerSecond;
        globalEntropyFactor += entropyIncrease;
        // Clamp max entropy
        globalEntropyFactor = globalEntropyFactor > 500 ? 500 : globalEntropyFactor;


        lastGlobalFactorUpdateTime = uint40(block.timestamp);

        // Optionally emit event here, but might be too noisy. Or emit in calling function.
        // Let's emit in channelFlux and setGlobalFactors where the change is significant.
    }


    // --- Pausable Implementation ---
    function pause() public onlyOwner whenNotPaused {
        _pause();
    }

    function unpause() public onlyOwner whenPaused {
        _unpause();
    }
}
```