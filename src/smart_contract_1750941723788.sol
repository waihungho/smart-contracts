Okay, let's create a smart contract concept that goes beyond standard tokens or NFTs. We'll design a system around "Dynamic Digital Entities" (let's call them "Spectra") that exist within a shared "Nexus" environment. These Spectra can evolve, interact with the environment, consume and produce abstract resources, and have attributes that change over time or based on actions.

This contract will combine elements of dynamic NFTs, resource management, environmental state, and on-chain simulation-lite, aiming for complexity and interconnected functions without directly copying common patterns.

**Concept: The Spectra Nexus**

This contract manages a collection of unique, non-fungible "Spectra" (ERC-721 like entities) that inhabit a shared "Nexus" (the contract's state). Spectra have dynamic attributes (Energy, Harmony, Resonance) and static traits (Form, Affinity). They interact with the Nexus and potentially each other through various actions like Attuning, Harmonizing, Synthesizing, and Navigating. The Nexus itself has a state (e.g., Flux Level) that affects Spectra actions. Abstract resources ("Essence", "Spark") are consumed and produced.

---

**Smart Contract: SpectraNexus**

**Outline:**

1.  **Pragma & Imports:** Solidity version, ERC721, Ownable.
2.  **Structs:** Define `Spectrum` (attributes, traits, state) and potentially resource types.
3.  **State Variables:**
    *   ERC721 mappings and counters.
    *   Mapping for `Spectrum` structs by token ID.
    *   Global Nexus state variables (`nexusFluxLevel`, `lastNexusUpdateTimestamp`).
    *   Mapping for resource balances (`address => mapping(uint256 => uint256)`).
    *   Configuration parameters (costs, cooldowns, attribute caps, resource types).
    *   Allowed Spectrum Forms/Affinities.
    *   Randomness seed management (with caution).
4.  **Events:** Actions, state changes, resource transfers.
5.  **Modifiers:** Common checks (e.g., `onlySpectrumOwner`, `canPerformAction`).
6.  **Core Logic:**
    *   **Admin/Setup:** Setting config, managing forms/affinities, initial resource distribution, updating Nexus state manually.
    *   **Spectrum Lifecycle:** Genesis (minting), Attuning (basic action affecting attributes), Harmonizing (interaction with environment/Nexus state), Synthesizing (resource creation/consumption), Evolving (changing Form/Traits based on conditions).
    *   **Nexus Interaction:** Navigating (exploration-like, costs energy, finds resources/events), Reacting (passive interaction based on Nexus state).
    *   **Resource Management:** Transferring resources, consuming/producing resources via Spectrum actions.
    *   **Query Functions:** Getting Spectrum details, Nexus state, resource balances, config.
    *   **Internal Helpers:** Attribute update logic, randomness (careful!), cooldown checks.

**Function Summary:**

1.  `constructor()`: Initializes the contract, sets base Nexus state and initial configs.
2.  `setNexusFluxLevel(uint256 _newFlux)`: Admin: Sets the global Nexus Flux level.
3.  `setGameConfig(uint256 _paramId, uint256 _value)`: Admin: Sets various game configuration parameters (costs, caps, cooldowns).
4.  `addAllowedSpectrumForm(uint256 _formId)`: Admin: Adds a new allowed Spectrum Form type.
5.  `removeAllowedSpectrumForm(uint256 _formId)`: Admin: Removes an allowed Spectrum Form type.
6.  `addAllowedSpectrumAffinity(uint256 _affinityId)`: Admin: Adds a new allowed Spectrum Affinity type.
7.  `removeAllowedSpectrumAffinity(uint256 _affinityId)`: Admin: Removes an allowed Spectrum Affinity type.
8.  `mintInitialResources(address[] calldata _recipients, uint256[] calldata _resourceTypes, uint256[] calldata _amounts)`: Admin: Distributes initial abstract resources.
9.  `transferOwnership(address newOwner)`: Admin: Transfers contract ownership.
10. `genesisSpectrum(uint256 _initialForm, uint256 _initialAffinity)`: Public: Creates a new Spectrum (mints an NFT). Requires certain resources/conditions. Attributes are randomized based on Form/Affinity and Nexus state.
11. `attuneSpectrum(uint256 _tokenId)`: User: Performs a basic attunement action with a Spectrum. Costs Energy, slightly boosts Harmony/Resonance based on Form/Affinity. Has a cooldown.
12. `harmonizeWithNexus(uint256 _tokenId)`: User: Attempts to harmonize the Spectrum with the current Nexus state. Costs Energy & Harmony, potentially boosts Resonance or yields minor resources based on success chance (influenced by Resonance vs. Flux). Has a cooldown.
13. `synthesizeResources(uint256 _tokenId, uint256 _resourceType)`: User: Uses Spectrum's Resonance and Energy to attempt synthesizing a specific resource. Costs Energy & Resonance, consumes other resources, produces target resource on success. Success chance influenced by Spectrum stats and Affinity vs. resource type. Has a cooldown.
14. `evolveSpectrum(uint256 _tokenId, uint256 _targetForm)`: User: Attempts to evolve the Spectrum to a new Form. Requires high Harmony/Resonance, costs significant resources, and potentially requires specific Nexus Flux conditions. Changes Form, potentially re-rolls/boosts some static traits or caps. Burns the old Spectrum state (effectively transforms the NFT).
15. `navigateNexus(uint256 _tokenId)`: User: Uses Spectrum's Energy to explore the Nexus. Costs Energy, consumes minor resources (fuel?), randomly (caution!) finds abstract resources or encounters events (simulated state changes, attribute boosts/drains). Has a cooldown.
16. `reactToFlux(uint256 _tokenId)`: User: Triggers a passive reaction based on the current Nexus Flux level. No cost, potentially boosts or drains minor attributes based on Affinity vs. Flux. Can be called periodically.
17. `getResourceBalance(address _owner, uint256 _resourceType)`: View: Gets an address's balance of a specific resource type.
18. `transferResource(address _to, uint256 _resourceType, uint256 _amount)`: User: Transfers abstract resources owned by the caller to another address.
19. `getSpectrumAttributes(uint256 _tokenId)`: View: Gets the current dynamic attributes (Energy, Harmony, Resonance) of a Spectrum.
20. `getSpectrumTraits(uint256 _tokenId)`: View: Gets the static traits (Form, Affinity) of a Spectrum.
21. `getSpectrumLastActionTime(uint256 _tokenId)`: View: Gets the timestamp of the Spectrum's last major action.
22. `getNexusState()`: View: Gets the current global Nexus state (Flux level, last update time).
23. `getGameConfigParam(uint256 _paramId)`: View: Gets the value of a specific game configuration parameter.
24. `isSpectrumFormAllowed(uint256 _formId)`: View: Checks if a Spectrum Form is currently allowed for genesis/evolution.
25. `isSpectrumAffinityAllowed(uint256 _affinityId)`: View: Checks if a Spectrum Affinity is currently allowed.

This setup provides over 20 functions and covers a system with dynamic state, resource management, NFT interaction, and environmental influence, distinct from typical contract patterns.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol"; // Or similar to count tokens if needed
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol"; // Good practice

// --- Smart Contract: SpectraNexus ---

// Outline:
// 1. Pragmas & Imports
// 2. Structs: Spectrum, ResourceType Enum
// 3. State Variables: ERC721 data, Spectrum storage, Nexus state, Resource balances, Configs, Allowed types, Counters, Randomness nonce.
// 4. Events: Genesis, Attune, Harmonize, Synthesize, Evolve, Navigate, React, ResourceTransfer, NexusFluxUpdate, ConfigUpdate.
// 5. Modifiers: onlySpectrumOwner, canPerformAction, onlyAllowedForm, onlyAllowedAffinity.
// 6. Core Logic Functions (Admin, Spectrum Lifecycle, Interaction, Resource, Query).

// Function Summary:
// 1. constructor(): Initializes state.
// 2. setNexusFluxLevel(uint256 _newFlux): Admin: Update global flux.
// 3. setGameConfig(uint256 _paramId, uint256 _value): Admin: Set config params.
// 4. addAllowedSpectrumForm(uint256 _formId): Admin: Add allowed Form type.
// 5. removeAllowedSpectrumForm(uint256 _formId): Admin: Remove allowed Form type.
// 6. addAllowedSpectrumAffinity(uint256 _affinityId): Admin: Add allowed Affinity type.
// 7. removeAllowedSpectrumAffinity(uint256 _affinityId): Admin: Remove allowed Affinity type.
// 8. mintInitialResources(address[] calldata _recipients, uint256[] calldata _resourceTypes, uint256[] calldata _amounts): Admin: Distribute initial resources.
// 9. transferOwnership(address newOwner): Admin: Transfer ownership.
// 10. genesisSpectrum(uint256 _initialForm, uint256 _initialAffinity): Public: Mint a new Spectrum NFT with initial traits/attributes.
// 11. attuneSpectrum(uint256 _tokenId): User: Basic action, consume energy, minor attribute shifts.
// 12. harmonizeWithNexus(uint256 _tokenId): User: Interact with Nexus flux, consume energy/harmony, potential resonance boost/resource gain.
// 13. synthesizeResources(uint256 _tokenId, uint256 _resourceType): User: Consume energy/resonance/other resources to generate target resource.
// 14. evolveSpectrum(uint256 _tokenId, uint256 _targetForm): User: Transform Spectrum Form, costs resources/stats, changes traits/caps.
// 15. navigateNexus(uint256 _tokenId): User: Exploration, consume energy, random resource finds/events.
// 16. reactToFlux(uint256 _tokenId): User: Passive reaction based on flux/affinity, minor attribute changes.
// 17. getResourceBalance(address _owner, uint256 _resourceType): View: Get resource balance for address.
// 18. transferResource(address _to, uint256 _resourceType, uint256 _amount): User: Transfer abstract resources.
// 19. getSpectrumAttributes(uint256 _tokenId): View: Get dynamic attributes.
// 20. getSpectrumTraits(uint56 _tokenId): View: Get static traits.
// 21. getSpectrumLastActionTime(uint256 _tokenId): View: Get timestamp of last major action.
// 22. getNexusState(): View: Get global Nexus state.
// 23. getGameConfigParam(uint256 _paramId): View: Get value of a config param.
// 24. isSpectrumFormAllowed(uint256 _formId): View: Check if a Form is allowed.
// 25. isSpectrumAffinityAllowed(uint256 _affinityId): View: Check if an Affinity is allowed.

contract SpectraNexus is ERC721Enumerable, Ownable {
    using Counters for Counters.Counter;
    using SafeMath for uint256; // For preventing overflows/underflows

    Counters.Counter private _tokenIdCounter;

    // --- Structs ---
    struct Spectrum {
        uint256 form; // Static trait: Represents base type/appearance
        uint256 affinity; // Static trait: Represents elemental/type affinity

        uint256 energy; // Dynamic attribute: Resource for actions
        uint256 harmony; // Dynamic attribute: Represents balance/wellbeing
        uint256 resonance; // Dynamic attribute: Represents power/influence

        uint256 genesisTimestamp; // When it was created
        uint256 lastActionTimestamp; // For cooldowns

        // Potential attribute caps based on Form/Affinity (can be stored here or calculated)
        // uint256 energyCap;
        // uint256 harmonyCap;
        // uint256 resonanceCap;
    }

    // Define abstract resource types using an enum
    enum ResourceType {
        Essence,
        Spark,
        Glyph,
        Crystal // Example types
    }

    // --- State Variables ---
    mapping(uint256 => Spectrum) private _spectra; // Token ID to Spectrum struct
    mapping(address => mapping(uint256 => uint256)) private _resourceBalances; // owner => ResourceType => amount

    uint256 public nexusFluxLevel; // Global environment state
    uint256 public lastNexusUpdateTimestamp;

    // Game Configuration Parameters (using a mapping for flexibility)
    // Example IDs: 1=GenesisCostEssence, 2=AttuneEnergyCost, 3=AttuneCooldown, 4=MaxEnergy, etc.
    mapping(uint256 => uint256) public gameConfig;

    mapping(uint256 => bool) private _allowedSpectrumForms;
    mapping(uint256 => bool) private _allowedSpectrumAffinities;

    // --- Randomness (CAUTION: On-chain randomness is exploitable) ---
    // For a real game, use Chainlink VRF or a commit-reveal scheme.
    // This is simplified for concept demonstration ONLY.
    uint256 private _randomNonce;

    // --- Events ---
    event SpectrumGenesis(uint256 indexed tokenId, address indexed owner, uint256 form, uint256 affinity);
    event SpectrumAttuned(uint256 indexed tokenId, uint256 energySpent, uint256 harmonyGained, uint256 resonanceGained);
    event SpectrumHarmonized(uint256 indexed tokenId, uint256 energySpent, uint256 harmonySpent, bool success, uint256 resonanceChange, uint256 resourcesGained);
    event SpectrumSynthesized(uint256 indexed tokenId, uint256 resourceType, bool success, uint256 amountProduced, uint256 energySpent, uint256 resonanceSpent);
    event SpectrumEvolved(uint256 indexed tokenId, uint256 oldForm, uint256 newForm);
    event SpectrumNavigated(uint256 indexed tokenId, uint256 energySpent, string outcome); // Outcome could be simplified string or ID
    event SpectrumReactedToFlux(uint256 indexed tokenId, int256 energyChange, int256 harmonyChange, int256 resonanceChange); // Using int256 for potential negative change
    event ResourceTransferred(address indexed from, address indexed to, uint256 resourceType, uint256 amount);
    event NexusFluxUpdated(uint256 oldFlux, uint256 newFlux, uint256 timestamp);
    event GameConfigUpdated(uint256 paramId, uint256 oldValue, uint256 newValue);

    // --- Modifiers ---
    modifier onlySpectrumOwner(uint256 _tokenId) {
        require(_exists(_tokenId), "SpectraNexus: Token does not exist");
        require(_isApprovedOrOwner(msg.sender, _tokenId), "SpectraNexus: Not owner or approved");
        _;
    }

    modifier canPerformAction(uint256 _tokenId, uint256 _cooldownParamId) {
        uint256 cooldown = gameConfig[_cooldownParamId];
        require(block.timestamp >= _spectra[_tokenId].lastActionTimestamp + cooldown, "SpectraNexus: Action on cooldown");
        _;
    }

    modifier onlyAllowedForm(uint256 _formId) {
        require(_allowedSpectrumForms[_formId], "SpectraNexus: Form type not allowed");
        _;
    }

    modifier onlyAllowedAffinity(uint256 _affinityId) {
        require(_allowedSpectrumAffinities[_affinityId], "SpectraNexus: Affinity type not allowed");
        _;
    }

    // --- Constructor ---
    constructor() ERC721("SpectraNexus", "SPX") Ownable(msg.sender) {
        nexusFluxLevel = 50; // Initial flux
        lastNexusUpdateTimestamp = block.timestamp;
        _randomNonce = 0; // Initialize nonce
        // Set some initial default configs (example values)
        gameConfig[1] = 10; // GenesisCostEssence = 10 Essence
        gameConfig[2] = 5;  // AttuneEnergyCost = 5 Energy
        gameConfig[3] = 1 * 60; // AttuneCooldown = 1 minute
        gameConfig[4] = 100; // MaxEnergy = 100
        gameConfig[5] = 50;  // MaxHarmony = 50
        gameConfig[6] = 50;  // MaxResonance = 50
        gameConfig[7] = 10;  // HarmonizeEnergyCost = 10 Energy
        gameConfig[8] = 5;   // HarmonizeHarmonyCost = 5 Harmony
        gameConfig[9] = 5 * 60; // HarmonizeCooldown = 5 minutes
        gameConfig[10] = 15; // SynthesizeEnergyCost = 15 Energy
        gameConfig[11] = 10; // SynthesizeResonanceCost = 10 Resonance
        gameConfig[12] = 10 * 60; // SynthesizeCooldown = 10 minutes
        gameConfig[13] = 20; // NavigateEnergyCost = 20 Energy
        gameConfig[14] = 15 * 60; // NavigateCooldown = 15 minutes
         gameConfig[15] = 1 * 60 * 60; // EvolveCooldown = 1 hour
        // Define resource types and link them to enum values
        gameConfig[100] = uint256(ResourceType.Essence);
        gameConfig[101] = uint256(ResourceType.Spark);
        gameConfig[102] = uint256(ResourceType.Glyph);
        gameConfig[103] = uint256(ResourceType.Crystal);
    }

    // --- Admin/Setup Functions ---

    /// @notice Sets the global Nexus Flux level.
    /// @param _newFlux The new flux level value.
    function setNexusFluxLevel(uint256 _newFlux) public onlyOwner {
        emit NexusFluxUpdated(nexusFluxLevel, _newFlux, block.timestamp);
        nexusFluxLevel = _newFlux;
        lastNexusUpdateTimestamp = block.timestamp;
    }

    /// @notice Sets a game configuration parameter.
    /// @param _paramId The ID of the parameter to set.
    /// @param _value The new value for the parameter.
    function setGameConfig(uint256 _paramId, uint256 _value) public onlyOwner {
        require(_paramId > 0, "SpectraNexus: Invalid param ID");
        emit GameConfigUpdated(_paramId, gameConfig[_paramId], _value);
        gameConfig[_paramId] = _value;
    }

    /// @notice Adds an allowed Spectrum Form type.
    /// @param _formId The ID of the Form to allow.
    function addAllowedSpectrumForm(uint256 _formId) public onlyOwner {
        _allowedSpectrumForms[_formId] = true;
    }

    /// @notice Removes an allowed Spectrum Form type.
    /// @param _formId The ID of the Form to disallow.
    function removeAllowedSpectrumForm(uint256 _formId) public onlyOwner {
         _allowedSpectrumForms[_formId] = false;
    }

    /// @notice Adds an allowed Spectrum Affinity type.
    /// @param _affinityId The ID of the Affinity to allow.
    function addAllowedSpectrumAffinity(uint256 _affinityId) public onlyOwner {
        _allowedSpectrumAffinities[_affinityId] = true;
    }

    /// @notice Removes an allowed Spectrum Affinity type.
    /// @param _affinityId The ID of the Affinity to disallow.
    function removeAllowedSpectrumAffinity(uint256 _affinityId) public onlyOwner {
        _allowedSpectrumAffinities[_affinityId] = false;
    }

    /// @notice Distributes initial abstract resources to addresses.
    /// @param _recipients Array of recipient addresses.
    /// @param _resourceTypes Array of resource type IDs. Must match recipients and amounts length.
    /// @param _amounts Array of amounts to distribute. Must match recipients and resourceTypes length.
    function mintInitialResources(address[] calldata _recipients, uint256[] calldata _resourceTypes, uint256[] calldata _amounts) public onlyOwner {
        require(_recipients.length == _resourceTypes.length && _recipients.length == _amounts.length, "SpectraNexus: Array length mismatch");
        for(uint i = 0; i < _recipients.length; i++) {
            _resourceBalances[_recipients[i]][_resourceTypes[i]] = _resourceBalances[_recipients[i]][_resourceTypes[i]].add(_amounts[i]);
            emit ResourceTransferred(address(0), _recipients[i], _resourceTypes[i], _amounts[i]);
        }
    }

    // Function 9: transferOwnership inherited from Ownable

    // --- Spectrum Lifecycle & Interaction Functions ---

    /// @notice Creates a new Spectrum NFT.
    /// @param _initialForm The desired initial Form ID.
    /// @param _initialAffinity The desired initial Affinity ID.
    function genesisSpectrum(uint256 _initialForm, uint256 _initialAffinity)
        public
        onlyAllowedForm(_initialForm)
        onlyAllowedAffinity(_initialAffinity)
    {
        // Example Cost: Require Essence
        uint256 essenceCost = gameConfig[1]; // GenesisCostEssence
        require(_resourceBalances[msg.sender][gameConfig[100]] >= essenceCost, "SpectraNexus: Insufficient Essence for genesis");
        _resourceBalances[msg.sender][gameConfig[100]] = _resourceBalances[msg.sender][gameConfig[100]].sub(essenceCost);
         emit ResourceTransferred(msg.sender, address(0), gameConfig[100], essenceCost);

        _tokenIdCounter.increment();
        uint256 newTokenId = _tokenIdCounter.current();

        // --- Simplified Randomness for attributes (CAUTION) ---
        // This is highly insecure for production.
        // For this example, we'll use block hash and nonce.
        uint256 randomness = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, msg.sender, _randomNonce++)));
        uint256 energy = (randomness % (gameConfig[4] / 2)).add(gameConfig[4] / 4); // Start with 25%-75% max energy
        randomness = uint256(keccak256(abi.encodePacked(randomness, _randomNonce++))); // Re-seed
        uint256 harmony = (randomness % (gameConfig[5] / 2)).add(gameConfig[5] / 4);
         randomness = uint256(keccak256(abi.encodePacked(randomness, _randomNonce++))); // Re-seed
        uint256 resonance = (randomness % (gameConfig[6] / 2)).add(gameConfig[6] / 4);

        Spectrum memory newSpectrum = Spectrum({
            form: _initialForm,
            affinity: _initialAffinity,
            energy: energy,
            harmony: harmony,
            resonance: resonance,
            genesisTimestamp: block.timestamp,
            lastActionTimestamp: block.timestamp // Can act immediately after genesis
        });

        _spectra[newTokenId] = newSpectrum;
        _safeMint(msg.sender, newTokenId);

        emit SpectrumGenesis(newTokenId, msg.sender, _initialForm, _initialAffinity);
    }

    /// @notice Performs a basic attunement action with a Spectrum.
    /// @param _tokenId The ID of the Spectrum to attune.
    function attuneSpectrum(uint256 _tokenId)
        public
        onlySpectrumOwner(_tokenId)
        canPerformAction(_tokenId, 3) // AttuneCooldown = gameConfig[3]
    {
        Spectrum storage spectrum = _spectra[_tokenId];
        uint256 energyCost = gameConfig[2]; // AttuneEnergyCost

        require(spectrum.energy >= energyCost, "SpectraNexus: Insufficient Energy");

        spectrum.energy = spectrum.energy.sub(energyCost);

        // Attribute boosts (simplified logic)
        uint256 harmonyGain = 1; // Example fixed gain
        uint256 resonanceGain = 1; // Example fixed gain

        spectrum.harmony = _min(spectrum.harmony.add(harmonyGain), gameConfig[5]); // Apply caps
        spectrum.resonance = _min(spectrum.resonance.add(resonanceGain), gameConfig[6]);

        spectrum.lastActionTimestamp = block.timestamp;

        emit SpectrumAttuned(_tokenId, energyCost, harmonyGain, resonanceGain);
    }

     /// @notice Attempts to harmonize the Spectrum with the current Nexus state.
     /// @param _tokenId The ID of the Spectrum to harmonize.
    function harmonizeWithNexus(uint256 _tokenId)
        public
        onlySpectrumOwner(_tokenId)
        canPerformAction(_tokenId, 9) // HarmonizeCooldown = gameConfig[9]
    {
        Spectrum storage spectrum = _spectra[_tokenId];
        uint256 energyCost = gameConfig[7]; // HarmonizeEnergyCost
        uint256 harmonyCost = gameConfig[8]; // HarmonizeHarmonyCost

        require(spectrum.energy >= energyCost, "SpectraNexus: Insufficient Energy");
        require(spectrum.harmony >= harmonyCost, "SpectraNexus: Insufficient Harmony");

        spectrum.energy = spectrum.energy.sub(energyCost);
        spectrum.harmony = spectrum.harmony.sub(harmonyCost);

        // Success chance based on Resonance vs. Flux (simplified)
        // Using basic modulo randomness (CAUTION)
        uint256 randomness = uint256(keccak256(abi.encodePacked(block.timestamp, msg.sender, _tokenId, _randomNonce++))) % 100; // 0-99
        uint256 successThreshold = (spectrum.resonance * 100) / (nexusFluxLevel == 0 ? 1 : nexusFluxLevel); // Example: Higher resonance vs lower flux = higher chance
        if (successThreshold > 90) successThreshold = 90; // Cap chance

        bool success = randomness < successThreshold;

        uint256 resonanceChange = 0;
        uint256 resourcesGained = 0;
        uint256 resourceTypeGained = gameConfig[101]; // Example: Gain Spark (gameConfig[101] = ResourceType.Spark)

        if (success) {
            resonanceChange = 5; // Example gain on success
            resourcesGained = 2; // Example resource gain on success
            spectrum.resonance = _min(spectrum.resonance.add(resonanceChange), gameConfig[6]);
            _resourceBalances[msg.sender][resourceTypeGained] = _resourceBalances[msg.sender][resourceTypeGained].add(resourcesGained);
            emit ResourceTransferred(address(0), msg.sender, resourceTypeGained, resourcesGained);
        } else {
            // Optional: minor resonance loss on failure
            resonanceChange = 1;
            if (spectrum.resonance > resonanceChange) spectrum.resonance = spectrum.resonance.sub(resonanceChange); else spectrum.resonance = 0;
            resonanceChange = uint256(0).sub(resonanceChange); // Indicate loss in event
        }

        spectrum.lastActionTimestamp = block.timestamp;

        emit SpectrumHarmonized(_tokenId, energyCost, harmonyCost, success, uint256(int256(resonanceChange)), resourcesGained);
    }

    /// @notice Uses Spectrum's attributes to attempt synthesizing a specific resource.
    /// @param _tokenId The ID of the Spectrum performing synthesis.
    /// @param _resourceType The type of resource to synthesize.
    function synthesizeResources(uint256 _tokenId, uint256 _resourceType)
        public
        onlySpectrumOwner(_tokenId)
        canPerformAction(_tokenId, 12) // SynthesizeCooldown = gameConfig[12]
    {
        Spectrum storage spectrum = _spectra[_tokenId];
        uint256 energyCost = gameConfig[10]; // SynthesizeEnergyCost
        uint256 resonanceCost = gameConfig[11]; // SynthesizeResonanceCost

        require(spectrum.energy >= energyCost, "SpectraNexus: Insufficient Energy");
        require(spectrum.resonance >= resonanceCost, "SpectraNexus: Insufficient Resonance");
        require(_resourceType <= uint256(ResourceType.Crystal), "SpectraNexus: Invalid resource type"); // Ensure resource type is valid enum value

        // Example cost: Consume 1 Glyph to produce something else
        uint256 inputResourceType = gameConfig[102]; // Glyph (gameConfig[102] = ResourceType.Glyph)
        uint256 inputResourceCost = 1;
         require(_resourceBalances[msg.sender][inputResourceType] >= inputResourceCost, "SpectraNexus: Insufficient input resource (Glyph)");

        _resourceBalances[msg.sender][inputResourceType] = _resourceBalances[msg.sender][inputResourceType].sub(inputResourceCost);
         emit ResourceTransferred(msg.sender, address(0), inputResourceType, inputResourceCost);

        spectrum.energy = spectrum.energy.sub(energyCost);
        spectrum.resonance = spectrum.resonance.sub(resonanceCost);

        // Success chance based on Resonance and Affinity vs. Resource type
        // Using basic modulo randomness (CAUTION)
        uint256 randomness = uint256(keccak256(abi.encodePacked(block.timestamp, msg.sender, _tokenId, _randomNonce++))) % 100; // 0-99
        uint256 successThreshold = (spectrum.resonance * 100) / 100; // Example: Base chance
        if (spectrum.affinity == _resourceType) successThreshold = successThreshold.add(10); // Bonus for matching affinity

        bool success = randomness < successThreshold;

        uint256 amountProduced = 0;

        if (success) {
            amountProduced = 1; // Example fixed production
            _resourceBalances[msg.sender][_resourceType] = _resourceBalances[msg.sender][_resourceType].add(amountProduced);
            emit ResourceTransferred(address(0), msg.sender, _resourceType, amountProduced);
        }

        spectrum.lastActionTimestamp = block.timestamp;

        emit SpectrumSynthesized(_tokenId, _resourceType, success, amountProduced, energyCost, resonanceCost);
    }

    /// @notice Attempts to evolve the Spectrum to a new Form.
    /// @param _tokenId The ID of the Spectrum to evolve.
    /// @param _targetForm The target Form ID.
    function evolveSpectrum(uint256 _tokenId, uint256 _targetForm)
        public
        onlySpectrumOwner(_tokenId)
        onlyAllowedForm(_targetForm)
        canPerformAction(_tokenId, 15) // EvolveCooldown = gameConfig[15]
    {
        Spectrum storage spectrum = _spectra[_tokenId];
        require(spectrum.form != _targetForm, "SpectraNexus: Cannot evolve to the same form");

        // Example Requirements: High Harmony, Resonance, and specific resources
        uint256 evolveCostEssence = 50; // Example cost
        uint256 evolveCostSpark = 20; // Example cost

        require(spectrum.harmony >= 40, "SpectraNexus: Not enough Harmony to evolve"); // Example threshold
        require(spectrum.resonance >= 40, "SpectraNexus: Not enough Resonance to evolve"); // Example threshold

        require(_resourceBalances[msg.sender][gameConfig[100]] >= evolveCostEssence, "SpectraNexus: Insufficient Essence for evolution");
        require(_resourceBalances[msg.sender][gameConfig[101]] >= evolveCostSpark, "SpectraNexus: Insufficient Spark for evolution");

        _resourceBalances[msg.sender][gameConfig[100]] = _resourceBalances[msg.sender][gameConfig[100]].sub(evolveCostEssence);
        _resourceBalances[msg.sender][gameConfig[101]] = _resourceBalances[msg.sender][gameConfig[101]].sub(evolveCostSpark);
        emit ResourceTransferred(msg.sender, address(0), gameConfig[100], evolveCostEssence);
        emit ResourceTransferred(msg.sender, address(0), gameConfig[101], evolveCostSpark);

        uint256 oldForm = spectrum.form;
        spectrum.form = _targetForm;

        // Re-calculate/boost attributes or caps based on new form (simplified)
        // Using basic modulo randomness (CAUTION)
        uint256 randomness = uint256(keccak256(abi.encodePacked(block.timestamp, msg.sender, _tokenId, _randomNonce++)));
        spectrum.energy = _min(spectrum.energy.add(randomness % 20), gameConfig[4]); // Example boost
        randomness = uint256(keccak256(abi.encodePacked(randomness, _randomNonce++)));
        spectrum.harmony = _min(spectrum.harmony.add(randomness % 10), gameConfig[5]);
        randomness = uint256(keccak256(abi.encodePacked(randomness, _randomNonce++)));
        spectrum.resonance = _min(spectrum.resonance.add(randomness % 15), gameConfig[6]);

        spectrum.lastActionTimestamp = block.timestamp;

        // Note: Evolving here replaces the state associated with the token ID.
        // If Forms were distinct NFT types, you might burn the old and mint a new.
        // This approach mutates the existing NFT's state.

        emit SpectrumEvolved(_tokenId, oldForm, _targetForm);
    }

    /// @notice Uses Spectrum's Energy to explore the Nexus.
    /// @param _tokenId The ID of the Spectrum exploring.
    function navigateNexus(uint256 _tokenId)
         public
         onlySpectrumOwner(_tokenId)
         canPerformAction(_tokenId, 14) // NavigateCooldown = gameConfig[14]
    {
         Spectrum storage spectrum = _spectra[_tokenId];
         uint256 energyCost = gameConfig[13]; // NavigateEnergyCost

         require(spectrum.energy >= energyCost, "SpectraNexus: Insufficient Energy");

         spectrum.energy = spectrum.energy.sub(energyCost);

         // Simulate random outcome (CAUTION)
         uint256 randomness = uint256(keccak256(abi.encodePacked(block.timestamp, msg.sender, _tokenId, _randomNonce++))) % 100; // 0-99

         string memory outcome;
         if (randomness < 30) { // 30% chance of finding Essence
             uint256 amountFound = randomness % 5 + 1; // 1-5 Essence
             uint256 resourceType = gameConfig[100]; // Essence
             _resourceBalances[msg.sender][resourceType] = _resourceBalances[msg.sender][resourceType].add(amountFound);
             emit ResourceTransferred(address(0), msg.sender, resourceType, amountFound);
             outcome = string(abi.encodePacked("Found Essence: ", amountFound));
         } else if (randomness < 60) { // 30% chance of finding Spark
             uint256 amountFound = randomness % 3 + 1; // 1-3 Spark
             uint256 resourceType = gameConfig[101]; // Spark
             _resourceBalances[msg.sender][resourceType] = _resourceBalances[msg.sender][resourceType].add(amountFound);
             emit ResourceTransferred(address(0), msg.sender, resourceType, amountFound);
             outcome = string(abi.encodePacked("Found Spark: ", amountFound));
         } else if (randomness < 80) { // 20% chance of minor energy restore
             uint256 energyRestored = randomness % 10 + 5; // 5-14 Energy
             spectrum.energy = _min(spectrum.energy.add(energyRestored), gameConfig[4]);
             outcome = string(abi.encodePacked("Energy restored: ", energyRestored));
         } else { // 20% chance of nothing or minor negative event
             outcome = "Encountered static fields";
         }

         spectrum.lastActionTimestamp = block.timestamp;

         emit SpectrumNavigated(_tokenId, energyCost, outcome);
    }

    /// @notice Triggers a passive reaction based on the current Nexus Flux level.
    /// @param _tokenId The ID of the Spectrum reacting.
    // No cooldown enforced here, could be called more frequently, or triggered by system
    function reactToFlux(uint256 _tokenId)
        public
        onlySpectrumOwner(_tokenId)
    {
        Spectrum storage spectrum = _spectra[_tokenId];

        int256 energyChange = 0;
        int256 harmonyChange = 0;
        int256 resonanceChange = 0;

        // Simplified reaction logic: higher flux might favor certain affinities or drain others
        // Example: If Affinity is 1 and Flux is high (>70), gain Harmony. If Affinity is 2 and Flux is high, lose Harmony.
        if (nexusFluxLevel > 70) {
            if (spectrum.affinity == 1) harmonyChange = 3;
            else if (spectrum.affinity == 2) harmonyChange = -2;
        } else if (nexusFluxLevel < 30) {
             if (spectrum.affinity == 2) resonanceChange = 3;
             else if (spectrum.affinity == 1) resonanceChange = -2;
        } else {
             // Neutral flux might restore minor energy
             energyChange = 1;
        }

        // Apply changes, respecting caps and minimums (0)
        if (energyChange > 0) spectrum.energy = _min(spectrum.energy.add(uint256(energyChange)), gameConfig[4]);
        else if (energyChange < 0) spectrum.energy = spectrum.energy > uint256(-energyChange) ? spectrum.energy.sub(uint256(-energyChange)) : 0;

         if (harmonyChange > 0) spectrum.harmony = _min(spectrum.harmony.add(uint256(harmonyChange)), gameConfig[5]);
        else if (harmonyChange < 0) spectrum.harmony = spectrum.harmony > uint256(-harmonyChange) ? spectrum.harmony.sub(uint256(-harmonyChange)) : 0;

        if (resonanceChange > 0) spectrum.resonance = _min(spectrum.resonance.add(uint256(resonanceChange)), gameConfig[6]);
        else if (resonanceChange < 0) spectrum.resonance = spectrum.resonance > uint256(-resonanceChange) ? spectrum.resonance.sub(uint256(-resonanceChange)) : 0;


        // Note: Does not update lastActionTimestamp if it's a purely "passive" reaction

        emit SpectrumReactedToFlux(_tokenId, energyChange, harmonyChange, resonanceChange);
    }


    // --- Resource Management Functions ---

    /// @notice Gets the resource balance for an owner and resource type.
    /// @param _owner The address to query.
    /// @param _resourceType The type of resource (from ResourceType enum).
    /// @return The amount of the resource owned by the address.
    function getResourceBalance(address _owner, uint256 _resourceType) public view returns (uint256) {
        require(_resourceType <= uint256(ResourceType.Crystal), "SpectraNexus: Invalid resource type");
        return _resourceBalances[_owner][_resourceType];
    }

    // Note: collectResource and spendResource are handled internally by action functions.
    // A public transfer function is provided for users to manage their resources.

    /// @notice Transfers abstract resources owned by the caller to another address.
    /// @param _to The recipient address.
    /// @param _resourceType The type of resource to transfer.
    /// @param _amount The amount to transfer.
    function transferResource(address _to, uint256 _resourceType, uint256 _amount) public {
        require(msg.sender != _to, "SpectraNexus: Cannot transfer to self");
        require(_amount > 0, "SpectraNexus: Amount must be greater than 0");
        require(_resourceType <= uint256(ResourceType.Crystal), "SpectraNexus: Invalid resource type");
        require(_resourceBalances[msg.sender][_resourceType] >= _amount, "SpectraNexus: Insufficient resource balance");

        _resourceBalances[msg.sender][_resourceType] = _resourceBalances[msg.sender][_resourceType].sub(_amount);
        _resourceBalances[_to][_resourceType] = _resourceBalances[_to][_resourceType].add(_amount);

        emit ResourceTransferred(msg.sender, _to, _resourceType, _amount);
    }


    // --- Query Functions ---

    // Function 17: getResourceBalance - already defined above

    /// @notice Gets the current dynamic attributes of a Spectrum.
    /// @param _tokenId The ID of the Spectrum.
    /// @return energy, harmony, resonance The current dynamic attributes.
    function getSpectrumAttributes(uint256 _tokenId) public view returns (uint256 energy, uint256 harmony, uint256 resonance) {
        require(_exists(_tokenId), "SpectraNexus: Token does not exist");
        Spectrum storage spectrum = _spectra[_tokenId];
        return (spectrum.energy, spectrum.harmony, spectrum.resonance);
    }

    /// @notice Gets the static traits of a Spectrum.
    /// @param _tokenId The ID of the Spectrum.
    /// @return form, affinity The static traits.
    function getSpectrumTraits(uint256 _tokenId) public view returns (uint256 form, uint256 affinity) {
        require(_exists(_tokenId), "SpectraNexus: Token does not exist");
        Spectrum storage spectrum = _spectra[_tokenId];
        return (spectrum.form, spectrum.affinity);
    }

    /// @notice Gets the timestamp of the Spectrum's last major action.
    /// @param _tokenId The ID of the Spectrum.
    /// @return lastActionTimestamp The timestamp.
    function getSpectrumLastActionTime(uint256 _tokenId) public view returns (uint256) {
        require(_exists(_tokenId), "SpectraNexus: Token does not exist");
        return _spectra[_tokenId].lastActionTimestamp;
    }

     /// @notice Gets the current global Nexus state.
     /// @return fluxLevel, lastUpdateTime The current Nexus state.
    function getNexusState() public view returns (uint256 fluxLevel, uint256 lastUpdateTime) {
        return (nexusFluxLevel, lastNexusUpdateTimestamp);
    }

    /// @notice Gets the value of a specific game configuration parameter.
    /// @param _paramId The ID of the parameter.
    /// @return The value of the parameter.
    function getGameConfigParam(uint256 _paramId) public view returns (uint256) {
        require(_paramId > 0, "SpectraNexus: Invalid param ID");
        return gameConfig[_paramId];
    }

    /// @notice Checks if a Spectrum Form is currently allowed for genesis/evolution.
    /// @param _formId The ID of the Form.
    /// @return True if allowed, false otherwise.
    function isSpectrumFormAllowed(uint256 _formId) public view returns (bool) {
        return _allowedSpectrumForms[_formId];
    }

    /// @notice Checks if a Spectrum Affinity is currently allowed.
    /// @param _affinityId The ID of the Affinity.
    /// @return True if allowed, false otherwise.
    function isSpectrumAffinityAllowed(uint256 _affinityId) public view returns (bool) {
        return _allowedSpectrumAffinities[_affinityId];
    }


    // --- Internal Helpers ---

    // Helper to get minimum of two numbers for attribute caps
    function _min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    // The following functions are standard ERC721 overrides necessary when inheriting
    // and adding custom logic. ERC721Enumerable adds more.

    function supportsInterface(bytes4 interfaceId) public view override(ERC721Enumerable, ERC721) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    // ERC721Enumerable overrides:
    function tokenOfOwnerByIndex(address owner, uint256 index) public view override(ERC721Enumerable, ERC721) returns (uint256) {
        return super.tokenOfOwnerByIndex(owner, index);
    }

     function totalSupply() public view override(ERC721Enumerable, ERC721) returns (uint256) {
        return super.totalSupply();
    }

     function tokenByIndex(uint256 index) public view override(ERC721Enumerable, ERC721) returns (uint256) {
        return super.tokenByIndex(index);
    }

}
```