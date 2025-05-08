Okay, here is a smart contract concept for "ChronoMorphs" - dynamic digital entities that can evolve, interact, and mutate based on on-chain catalysts and simulations. This goes beyond typical token or NFT functionalities by incorporating state changes driven by multiple specific interaction functions.

It implements a custom ERC-721 like structure (without inheriting directly from OpenZeppelin to avoid duplicating *that specific* open source code, though the *standard* interface is followed) and adds a complex layer of attribute management and interactions.

**Outline & Function Summary**

This contract, `ChronoMorphs`, manages a collection of unique digital entities called "ChronoMorphs". Each ChronoMorph is an NFT (following a custom ERC721 implementation) with a set of dynamic attributes and a state that can change over time or through specific interactions.

**Core Concepts:**

1.  **ChronoMorphs:** Unique tokens (NFTs) represented by a struct containing standard ERC721 data (ID, owner) and specific ChronoMorph data (`speciesId`, `attributes`, `generation`, `lastInteractionTime`, `stateFlags`).
2.  **Attributes:** Numerical properties of a ChronoMorph (e.g., Strength, Agility, Resilience, Vitality, ChronoEnergy). These values are dynamic.
3.  **Species:** Predefined templates for ChronoMorphs with base attributes and potentially different behavioral rules.
4.  **Catalysts:** On-chain triggers (`catalystId`) that, when applied to a ChronoMorph, cause specific changes to its attributes or state based on predefined configurations.
5.  **Evolution:** A process that can be triggered based on certain conditions (e.g., attribute thresholds, number of interactions, time), leading to significant changes in attributes or species.
6.  **Decay:** A time-based process where attributes (especially Vitality) might decrease if not interacted with.
7.  **Breeding:** Combining two parent ChronoMorphs to create a new one with inherited and potentially randomized attributes.
8.  **Interaction Simulation:** Simulating an interaction (like combat or synergy) between two ChronoMorphs, affecting both participants' attributes.
9.  **Mutation:** Introducing a degree of randomness or pseudo-randomness to unpredictably alter attributes.
10. **Sacrifice:** Destroying a ChronoMorph to provide a benefit (e.g., attribute boost, catalyst charge) to another or the owner.
11. **State Flags:** Boolean flags representing temporary or permanent states (e.g., frozen, mutated, catalyzed).

**Data Structures:**

*   `MorphAttributes`: Struct holding numerical attributes (`uint32`).
*   `ChronoMorph`: Struct holding the full state of a morph (`owner`, `speciesId`, `attributes`, `generation`, `lastInteractionTime`, `stateFlags`).
*   `SpeciesConfig`: Struct holding base attributes for a species.
*   `CatalystEffectConfig`: Struct/Data representation defining how a specific catalyst affects attributes.
*   `MorphConfig`: Struct holding various parameters related to morph behavior (decay rate, evolution thresholds, etc.).

**State Variables:**

*   `_morphs`: Mapping from `tokenId` to `ChronoMorph` struct.
*   `_owners`: Mapping from `tokenId` to owner address (ERC721).
*   `_balances`: Mapping from owner address to token count (ERC721).
*   `_approvals`: Mapping from `tokenId` to approved address (ERC721).
*   `_operatorApprovals`: Mapping from owner address to mapping of operator address to approval status (ERC721).
*   `_nextMorphId`: Counter for minting new tokens.
*   `owner`: Contract owner address (for administrative functions).
*   `_speciesConfig`: Mapping from `speciesId` to `SpeciesConfig`.
*   `_catalystConfig`: Mapping from `catalystId` to `CatalystEffectConfig` data (bytes).
*   `_morphConfigs`: Mapping from `configType` (uint8) to `MorphConfig`.

**Function Summary (Public/External):**

1.  `constructor()`: Sets contract owner.
2.  `balanceOf(address owner)`: (ERC721) Returns the number of tokens owned by an address.
3.  `ownerOf(uint256 tokenId)`: (ERC721) Returns the owner of a specific token.
4.  `transferFrom(address from, address to, uint256 tokenId)`: (ERC721) Transfers a token.
5.  `safeTransferFrom(address from, address to, uint256 tokenId)`: (ERC721) Safely transfers a token (checks receiver).
6.  `safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)`: (ERC721) Safely transfers a token with data (checks receiver).
7.  `approve(address to, uint256 tokenId)`: (ERC721) Approves an address to manage a token.
8.  `setApprovalForAll(address operator, bool approved)`: (ERC721) Approves/unapproves an operator for all tokens.
9.  `getApproved(uint256 tokenId)`: (ERC721) Returns the approved address for a token.
10. `isApprovedForAll(address owner, address operator)`: (ERC721) Returns approval status for an operator.
11. `genesisMint(address recipient, uint8 speciesId)`: (Owner only) Creates a new ChronoMorph of a specific species.
12. `getMorph(uint256 morphId)`: (View) Returns all details of a ChronoMorph.
13. `getMorphAttributes(uint256 morphId)`: (View) Returns just the attributes of a ChronoMorph.
14. `applyCatalyst(uint256 morphId, uint256 catalystId, bytes memory catalystData)`: Applies a specific catalyst effect to a ChronoMorph.
15. `triggerEvolution(uint256 morphId)`: Attempts to evolve a ChronoMorph based on its current state and configured rules.
16. `breed(uint256 parent1Id, uint256 parent2Id, address recipient)`: Creates a new ChronoMorph by combining two parents.
17. `decay(uint256 morphId)`: Applies time-based decay to a ChronoMorph's attributes if due and not frozen.
18. `simulateInteraction(uint256 morph1Id, uint256 morph2Id, bytes memory interactionData)`: Simulates an interaction between two morphs, modifying their attributes.
19. `sacrificeMorph(uint256 morphId, uint256 targetMorphId)`: Burns `morphId` to boost `targetMorphId`.
20. `mutate(uint256 morphId, uint256 mutationSeed)`: Applies a pseudo-random mutation to attributes.
21. `freezeState(uint256 morphId, uint256 duration)`: Freezes a morph's state (e.g., prevents decay) for a duration.
22. `unfreezeState(uint256 morphId)`: Manually unfreezes a morph's state.
23. `getConfig(uint8 configType)`: (View) Returns a specific morph configuration struct.
24. `setAttributeBase(uint8 speciesId, MorphAttributes memory baseAttributes)`: (Owner only) Sets/updates the base attributes for a species.
25. `setCatalystEffectConfig(uint256 catalystId, bytes memory effectData)`: (Owner only) Sets/updates the configuration data for a catalyst effect.
26. `setMorphConfig(uint8 configType, MorphConfig memory config)`: (Owner only) Sets/updates a general morph configuration type.
27. `getTotalSupply()`: (View) Returns the total number of ChronoMorphs.

**Smart Contract Code (Solidity)**

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// Minimal ERC721-like interface for compatibility reference
interface IERC721Like {
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    function balanceOf(address owner) external view returns (uint256 balance);
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
    function transferFrom(address from, address to, uint256 tokenId) external;
    function approve(address to, uint256 tokenId) external;
    function setApprovalForAll(address operator, bool approved) external;
    function getApproved(uint256 tokenId) external view returns (address operator);
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// Interface for receiving ERC721 tokens
interface IERC721Receiver {
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external returns (bytes4);
}


// --- ChronoMorphs Smart Contract ---
//
// This contract manages dynamic digital entities (ChronoMorphs) as NFTs.
// ChronoMorphs have attributes that can change based on interactions, catalysts,
// evolution, decay, breeding, and mutation. It includes a custom implementation
// of ERC721-like functionality and adds complex state management and interaction
// functions.
//
// Outline:
// 1. Events
// 2. Error Definitions
// 3. Structs (MorphAttributes, ChronoMorph, SpeciesConfig, MorphConfig)
// 4. State Variables
// 5. Modifiers (onlyOwner)
// 6. Constructor
// 7. ERC721-Like Implementation (balanceOf, ownerOf, transferFrom, approve, etc.)
// 8. Core ChronoMorph Functions (genesisMint, getMorph, applyCatalyst, triggerEvolution, breed, etc.)
// 9. Interaction & State Change Logic (decay, simulateInteraction, sacrificeMorph, mutate, freezeState)
// 10. Configuration Functions (setAttributeBase, setCatalystEffectConfig, setMorphConfig)
// 11. View Helpers (getTotalSupply, getConfig)
// 12. Internal Helper Functions (_exists, _requireOwned, _requireApprovedOrOwner, _transfer, _mint, _burn, _updateAttributes, etc.)
//
// Function Summary: (See above Outline & Function Summary section for detailed list 1-27)
// - ERC721 standard functions for ownership and transfer (9 functions)
// - Core morph lifecycle: minting, getting state (3 functions)
// - Attribute & State Modification: catalyst application, evolution, breeding, decay,
//   interaction simulation, sacrifice, mutation, state freezing/unfreezing (10 functions)
// - Configuration management: setting base attributes, catalyst effects, general configs (4 functions)
// - Utility views: total supply, config retrieval (2 functions)
// Total Public/External Functions: 9 + 3 + 10 + 4 + 2 = 28+ functions.
//

contract ChronoMorphs is IERC721Like {

    // --- 1. Events ---
    event MorphGenesis(uint256 indexed tokenId, address indexed owner, uint8 speciesId);
    event AttributesChanged(uint256 indexed tokenId, MorphAttributes oldAttributes, MorphAttributes newAttributes);
    event MorphEvolved(uint256 indexed tokenId, uint8 oldSpeciesId, uint8 newSpeciesId, uint32 oldGeneration, uint32 newGeneration);
    event MorphDecayed(uint256 indexed tokenId, uint256 decayAmount); // Simplified for example
    event CatalystApplied(uint256 indexed tokenId, uint256 indexed catalystId);
    event InteractionSimulated(uint256 indexed morph1Id, uint256 indexed morph2Id);
    event MorphMutated(uint256 indexed tokenId, uint256 mutationSeed);
    event MorphSacrificed(uint256 indexed sacrificedTokenId, uint256 indexed targetTokenId);
    event StateFrozen(uint256 indexed tokenId, uint256 untilTime);
    event StateUnfrozen(uint256 indexed tokenId);

    // --- 2. Error Definitions ---
    error TokenDoesNotExist(uint256 tokenId);
    error NotOwnerOrApproved(uint256 tokenId);
    error NotApprovedForAll(address owner, address operator);
    error TransferToZeroAddress();
    error TransferIntoNonERC721Receiver();
    error Unauthorized();
    error InvalidSpecies();
    error InvalidCatalyst();
    error BreedingConditionsNotMet();
    error InvalidParent();
    error SelfInteractionDisallowed();
    error SacrificeTargetDoesNotExist();
    error MorphStateFrozen(uint256 tokenId);
    error InvalidConfigType();


    // --- 3. Structs ---
    struct MorphAttributes {
        uint32 strength;
        uint32 agility;
        uint32 resilience;
        uint32 vitality; // Can decay
        uint32 chronoEnergy; // Can be consumed/generated
        uint32 latentPotential; // Can influence mutation/evolution
    }

    struct ChronoMorph {
        address owner; // Stored here for quick access alongside other morph data
        uint8 speciesId;
        MorphAttributes attributes;
        uint32 generation;
        uint256 lastInteractionTime; // Used for decay logic
        uint256 stateFlags; // Bit flags for various states (e.g., 1=Frozen, 2=Mutated)
        uint256 freezeEndTime; // Timestamp when freeze state ends
    }

    struct SpeciesConfig {
        MorphAttributes baseAttributes;
        // Add species-specific rules here if needed (e.g., decay multipliers, evolution triggers)
    }

    // Example Config Struct (can be expanded for different types)
    struct MorphConfig {
        uint256 decayRatePerSecond; // e.g., Vitality decay
        uint256 decayInterval; // Minimum time between decay calculations
        uint256 breedingEnergyCost;
        uint256 breedingCooldown;
        uint256 minAttributeForEvolution; // Example condition
        uint256 maxAttributeForEvolution; // Example condition
    }

    // --- 4. State Variables ---
    mapping(uint256 => ChronoMorph) private _morphs;
    // ERC721 standard mappings (redundant with struct owner but included for standard lookups)
    mapping(uint256 => address) private _owners;
    mapping(address => uint256) private _balances;
    mapping(uint256 => address) private _approvals;
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    uint256 private _nextMorphId;
    address public owner;

    mapping(uint8 => SpeciesConfig) private _speciesConfig;
    mapping(uint256 => bytes) private _catalystConfig; // Store raw data for complex effects
    mapping(uint8 => MorphConfig) private _morphConfigs; // Various configurations (e.g., 1=Default)


    // --- 5. Modifiers ---
    modifier onlyOwner() {
        if (msg.sender != owner) {
            revert Unauthorized();
        }
        _;
    }

    // --- 6. Constructor ---
    constructor() {
        owner = msg.sender;
        _nextMorphId = 1; // Start token IDs from 1
    }

    // --- 7. ERC721-Like Implementation ---

    function balanceOf(address owner_) public view override returns (uint256) {
        if (owner_ == address(0)) revert TransferToZeroAddress();
        return _balances[owner_];
    }

    function ownerOf(uint256 tokenId) public view override returns (address) {
        address owner_ = _owners[tokenId];
        if (owner_ == address(0)) revert TokenDoesNotExist(tokenId);
        return owner_;
    }

    function transferFrom(address from, address to, uint256 tokenId) public override {
        _transfer(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public override {
        safeTransferFrom(from, to, tokenId, "");
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) public override {
        _transfer(from, to, tokenId);
        if (to.code.length > 0 && !_checkOnERC721Received(address(0), from, to, tokenId, data)) {
             revert TransferIntoNonERC721Receiver();
        }
    }

    function approve(address to, uint256 tokenId) public override {
        address owner_ = ownerOf(tokenId); // Implicitly checks if token exists
        if (msg.sender != owner_ && !isApprovedForAll(owner_, msg.sender)) {
            revert NotOwnerOrApproved(tokenId);
        }
        _approve(to, tokenId);
    }

    function setApprovalForAll(address operator, bool approved) public override {
        if (msg.sender == operator) revert Unauthorized(); // Cannot approve self as operator
        _operatorApprovals[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function getApproved(uint256 tokenId) public view override returns (address) {
         if (!_exists(tokenId)) revert TokenDoesNotExist(tokenId);
         return _approvals[tokenId];
    }

    function isApprovedForAll(address owner_, address operator) public view override returns (bool) {
        return _operatorApprovals[owner_][operator];
    }

    // --- 8. Core ChronoMorph Functions ---

    /// @notice Creates a new ChronoMorph instance.
    /// @dev Only callable by the contract owner.
    /// @param recipient The address to receive the new morph.
    /// @param speciesId The ID defining the base attributes and type of the morph.
    function genesisMint(address recipient, uint8 speciesId) external onlyOwner {
        if (recipient == address(0)) revert TransferToZeroAddress();
        SpeciesConfig memory sCfg = _speciesConfig[speciesId];
        if (sCfg.baseAttributes.vitality == 0 && sCfg.baseAttributes.strength == 0) { // Basic check if species exists
             revert InvalidSpecies();
        }

        uint256 tokenId = _nextMorphId++;
        _morphs[tokenId] = ChronoMorph({
            owner: recipient,
            speciesId: speciesId,
            attributes: sCfg.baseAttributes,
            generation: 0, // Genesis morphs are generation 0
            lastInteractionTime: block.timestamp,
            stateFlags: 0,
            freezeEndTime: 0
        });

        _mint(recipient, tokenId); // Updates ERC721 mappings
        emit MorphGenesis(tokenId, recipient, speciesId);
    }

    /// @notice Gets the full details of a ChronoMorph.
    /// @param morphId The ID of the morph.
    /// @return The ChronoMorph struct.
    function getMorph(uint256 morphId) public view returns (ChronoMorph memory) {
        if (!_exists(morphId)) revert TokenDoesNotExist(morphId);
        ChronoMorph storage morph = _morphs[morphId];
         // Return a memory copy
        return ChronoMorph({
            owner: morph.owner,
            speciesId: morph.speciesId,
            attributes: morph.attributes,
            generation: morph.generation,
            lastInteractionTime: morph.lastInteractionTime,
            stateFlags: morph.stateFlags,
            freezeEndTime: morph.freezeEndTime
        });
    }

     /// @notice Gets only the attributes of a ChronoMorph.
    /// @param morphId The ID of the morph.
    /// @return The MorphAttributes struct.
    function getMorphAttributes(uint256 morphId) public view returns (MorphAttributes memory) {
         if (!_exists(morphId)) revert TokenDoesNotExist(morphId);
         return _morphs[morphId].attributes;
    }


    /// @notice Applies a configured catalyst effect to a ChronoMorph.
    /// @dev Effects are defined by the `_catalystConfig` mapping.
    /// @param morphId The ID of the morph to affect.
    /// @param catalystId The ID of the catalyst to apply.
    /// @param catalystData Optional data to pass to the catalyst effect logic.
    function applyCatalyst(uint256 morphId, uint256 catalystId, bytes memory catalystData) external {
        ChronoMorph storage morph = _morphs[morphId];
        _requireOwnedOrApproved(morphId); // Ensure caller has permission
        if (_isStateFrozen(morphId)) revert MorphStateFrozen(morphId);

        bytes memory effectData = _catalystConfig[catalystId];
        if (effectData.length == 0) revert InvalidCatalyst();

        MorphAttributes memory oldAttributes = morph.attributes;
        MorphAttributes memory newAttributes = oldAttributes; // Start with current attributes

        // --- Advanced/Creative Logic: Interpret catalystData and effectData ---
        // This is a placeholder. Real implementation would parse `effectData`
        // (e.g., abi.decode into a specific CatalystEffectParams struct)
        // and `catalystData` (e.g., amount, target attribute ID) to modify
        // `newAttributes` based on complex rules defined by the catalyst.
        // Example: Increase Strength by X, decrease Vitality by Y, if chronoEnergy > Z.
        // The specific logic for each catalystId would be implemented here or in a helper.

        // Example Placeholder Logic: Catalyst 1 boosts Vitality, Catalyst 2 boosts Strength
        if (catalystId == 1) {
            uint32 boostAmount = catalystData.length >= 4 ? abi.decode(catalystData, (uint32)) : 10; // Example: decode boost or default
            newAttributes.vitality = newAttributes.vitality + boostAmount; // Simple additive effect
        } else if (catalystId == 2) {
             uint32 boostAmount = catalystData.length >= 4 ? abi.decode(catalystData, (uint32)) : 5;
             newAttributes.strength = newAttributes.strength + boostAmount;
        }
        // ... more catalyst effects based on catalystId ...

        _updateAttributes(morphId, newAttributes); // Apply changes and emit event
        emit CatalystApplied(morphId, catalystId);

        // Update last interaction time
        morph.lastInteractionTime = block.timestamp;
    }

    /// @notice Attempts to evolve a ChronoMorph based on its state and configured rules.
    /// @dev Evolution might change species, generation, and attributes.
    /// @param morphId The ID of the morph to evolve.
    function triggerEvolution(uint256 morphId) external {
        ChronoMorph storage morph = _morphs[morphId];
        _requireOwnedOrApproved(morphId);
        if (_isStateFrozen(morphId)) revert MorphStateFrozen(morphId);

        MorphConfig memory config = _morphConfigs[1]; // Example: Use config type 1
        MorphAttributes memory currentAttributes = morph.attributes;

        bool evolutionConditionsMet =
            currentAttributes.strength >= config.minAttributeForEvolution &&
            currentAttributes.agility >= config.minAttributeForEvolution &&
            currentAttributes.resilience >= config.minAttributeForEvolution &&
            currentAttributes.vitality >= config.minAttributeForEvolution &&
            currentAttributes.chronoEnergy >= config.minAttributeForEvolution &&
            currentAttributes.latentPotential >= config.minAttributeForEvolution &&
            currentAttributes.strength + currentAttributes.agility + currentAttributes.resilience +
            currentAttributes.vitality + currentAttributes.chronoEnergy + currentAttributes.latentPotential
            >= config.maxAttributeForEvolution; // Example aggregate condition

        // Add more complex conditions based on species, interaction history, etc.

        if (evolutionConditionsMet) {
            MorphAttributes memory oldAttributes = currentAttributes;
            uint8 oldSpeciesId = morph.speciesId;
            uint32 oldGeneration = morph.generation;

            // --- Advanced/Creative Logic: Determine evolution outcome ---
            // This is a placeholder. Real implementation would determine the
            // new speciesId, generation, and attributes based on complex logic
            // considering current stats, original species, maybe latentPotential.
            // Example: Evolve Species 1 to Species 2 if stats are high.
            // Example: Reset some stats, boost others, increment generation.

            morph.speciesId = morph.speciesId + 1; // Simple example: just increment species ID
            morph.generation = morph.generation + 1;
            // Re-calculate attributes based on new species base + some carry-over/bonus
            SpeciesConfig memory nextSpeciesCfg = _speciesConfig[morph.speciesId];
            if (nextSpeciesCfg.baseAttributes.vitality == 0 && nextSpeciesCfg.baseAttributes.strength == 0) {
                 // If next species not configured, prevent evolution or evolve to a generic high-gen species
                 morph.speciesId = oldSpeciesId; // Revert species change
                 revert InvalidSpecies(); // Or handle differently
            }

            MorphAttributes memory newAttributes = nextSpeciesCfg.baseAttributes;
            // Add some percentage of old attributes or a fixed bonus
            newAttributes.strength += oldAttributes.strength / 2;
            newAttributes.vitality = newAttributes.vitality * 2; // Example boost


            _updateAttributes(morphId, newAttributes);
            emit MorphEvolved(morphId, oldSpeciesId, morph.speciesId, oldGeneration, morph.generation);

             // Update last interaction time (evolution counts as interaction)
            morph.lastInteractionTime = block.timestamp;

        } else {
            // Evolution conditions not met - maybe apply a small penalty or cooldown?
             // For simplicity, just do nothing if conditions aren't met.
        }
    }

    /// @notice Creates a new ChronoMorph by combining two parent morphs.
    /// @dev Requires parents to be owned by or approved for the caller.
    /// @param parent1Id The ID of the first parent morph.
    /// @param parent2Id The ID of the second parent morph.
    /// @param recipient The address to receive the new morph.
    function breed(uint256 parent1Id, uint256 parent2Id, address recipient) external {
        if (recipient == address(0)) revert TransferToZeroAddress();
        if (parent1Id == parent2Id) revert InvalidParent(); // Cannot breed with self

        ChronoMorph storage parent1 = _morphs[parent1Id];
        ChronoMorph storage parent2 = _morphs[parent2Id];

        _requireOwnedOrApproved(parent1Id);
        _requireOwnedOrApproved(parent2Id);
        if (_isStateFrozen(parent1Id) || _isStateFrozen(parent2Id)) revert MorphStateFrozen(parent1Id); // Assume if one is frozen, cannot breed

        MorphConfig memory config = _morphConfigs[1]; // Example: Use config type 1

        // --- Advanced/Creative Logic: Breeding Conditions and Attribute Calculation ---
        // Placeholder for complex breeding rules.
        // Example Conditions: Check vitality thresholds, cooldowns (`lastInteractionTime`), ChronoEnergy cost.
        // Example Attribute Calculation: Average parents' stats, add randomness, inherit species traits,
        // consider latentPotential, add generation bonus.

        if (parent1.attributes.vitality < config.minAttributeForEvolution || parent2.attributes.vitality < config.minAttributeForEvolution) { // Using minAttribute as a vitality check example
            revert BreedingConditionsNotMet();
        }

        // Example: Deduct ChronoEnergy from parents
        if (parent1.attributes.chronoEnergy < config.breedingEnergyCost || parent2.attributes.chronoEnergy < config.breedingEnergyCost) {
             revert BreedingConditionsNotMet(); // Not enough energy
        }
        parent1.attributes.chronoEnergy -= uint32(config.breedingEnergyCost);
        parent2.attributes.chronoEnergy -= uint32(config.breedingEnergyCost);
        _updateAttributes(parent1Id, parent1.attributes); // Update parents' energy
        _updateAttributes(parent2Id, parent2.attributes);


        // Simplified attribute calculation: average + bonus
        MorphAttributes memory childAttributes;
        childAttributes.strength = (parent1.attributes.strength + parent2.attributes.strength) / 2 + 5; // + bonus
        childAttributes.agility = (parent1.attributes.agility + parent2.attributes.agility) / 2 + 5;
        childAttributes.resilience = (parent1.attributes.resilience + parent2.attributes.resilience) / 2 + 5;
        childAttributes.vitality = (parent1.attributes.vitality + parent2.attributes.vitality) / 2 + 10; // Vitality boost on birth
        childAttributes.chronoEnergy = (parent1.attributes.chronoEnergy + parent2.attributes.chronoEnergy) / 2; // Energy carries over
        childAttributes.latentPotential = (parent1.attributes.latentPotential + parent2.attributes.latentPotential) / 2 + uint32(block.difficulty % 10); // Add some pseudo-randomness

        uint8 childSpeciesId = (parent1.speciesId + parent2.speciesId) / 2; // Simple average species ID
        if (_speciesConfig[childSpeciesId].baseAttributes.vitality == 0) { // Ensure child species is valid
             childSpeciesId = parent1.speciesId; // Default to parent 1 species if average is invalid
        }


        uint256 tokenId = _nextMorphId++;
        _morphs[tokenId] = ChronoMorph({
            owner: recipient,
            speciesId: childSpeciesId,
            attributes: childAttributes,
            generation: max(parent1.generation, parent2.generation) + 1, // Increment generation
            lastInteractionTime: block.timestamp,
            stateFlags: 0,
            freezeEndTime: 0
        });

        _mint(recipient, tokenId); // Updates ERC721 mappings
        emit MorphGenesis(tokenId, recipient, childSpeciesId);

        // Update parent interaction times (breeding counts as interaction)
        parent1.lastInteractionTime = block.timestamp;
        parent2.lastInteractionTime = block.timestamp;
    }

    // --- 9. Interaction & State Change Logic ---

    /// @notice Applies time-based decay to a ChronoMorph's attributes if applicable.
    /// @dev Vitality is the primary attribute affected by decay. Can be triggered by anyone.
    /// @param morphId The ID of the morph to decay.
    function decay(uint256 morphId) external {
        ChronoMorph storage morph = _morphs[morphId];
        if (!_exists(morphId)) revert TokenDoesNotExist(morphId); // Allow anyone to trigger decay for any token
        if (_isStateFrozen(morphId)) return; // Cannot decay if frozen

        MorphConfig memory config = _morphConfigs[1]; // Example: Use config type 1

        uint256 timeElapsed = block.timestamp - morph.lastInteractionTime;

        if (timeElapsed > config.decayInterval) {
             uint256 decayAmount = (timeElapsed / config.decayInterval) * config.decayRatePerSecond; // Decay based on intervals passed

            MorphAttributes memory oldAttributes = morph.attributes;
            MorphAttributes memory newAttributes = oldAttributes;

            if (newAttributes.vitality > decayAmount) {
                 newAttributes.vitality -= uint32(decayAmount);
            } else {
                 newAttributes.vitality = 0; // Vitality cannot go below zero
                 // Optional: Implement consequences for 0 vitality (e.g., dormant state, cannot interact)
            }

            _updateAttributes(morphId, newAttributes);
            emit MorphDecayed(morphId, decayAmount);

            // Update last interaction time to now, regardless of decay amount, to prevent immediate re-decay
            morph.lastInteractionTime = block.timestamp;
        }
         // If timeElapsed <= decayInterval, do nothing
    }

    /// @notice Simulates an interaction (e.g., battle, synergy) between two morphs.
    /// @dev Modifies attributes of both morphs based on interaction logic.
    /// @param morph1Id The ID of the first interacting morph.
    /// @param morph2Id The ID of the second interacting morph.
    /// @param interactionData Optional data influencing the simulation outcome.
    function simulateInteraction(uint256 morph1Id, uint256 morph2Id, bytes memory interactionData) external {
         if (morph1Id == morph2Id) revert SelfInteractionDisallowed();

         ChronoMorph storage morph1 = _morphs[morph1Id];
         ChronoMorph storage morph2 = _morphs[morph2Id];

         // Ensure sender has permission over at least one morph, or both if required by logic
         bool callerOwnsOrApproved1 = _isApprovedOrOwner(msg.sender, morph1Id);
         bool callerOwnsOrApproved2 = _isApprovedOrOwner(msg.sender, morph2Id);

         if (!callerOwnsOrApproved1 && !callerOwnsOrApproved2) {
              revert NotOwnerOrApproved(morph1Id); // Or create a specific error
         }

        if (_isStateFrozen(morph1Id) || _isStateFrozen(morph2Id)) revert MorphStateFrozen(morph1Id); // If either is frozen, interaction fails

         MorphAttributes memory oldAttr1 = morph1.attributes;
         MorphAttributes memory oldAttr2 = morph2.attributes;
         MorphAttributes memory newAttr1 = oldAttr1;
         MorphAttributes memory newAttr2 = oldAttr2;

         // --- Advanced/Creative Logic: Interaction Simulation ---
         // Placeholder for complex battle/synergy logic.
         // Example: Compare Strength vs Resilience, Agility vs Agility.
         // Example: Calculate damage, attribute drains, buffs based on stats and interactionData.
         // Example: Vitality loss, ChronoEnergy consumption.

         uint256 morph1Attack = oldAttr1.strength + oldAttr1.agility / 2;
         uint256 morph2Defense = oldAttr2.resilience + oldAttr2.agility / 2;
         uint256 damageTo2 = morph1Attack > morph2Defense ? morph1Attack - morph2Defense : 0;

         uint256 morph2Attack = oldAttr2.strength + oldAttr2.agility / 2;
         uint256 morph1Defense = oldAttr1.resilience + oldAttr1.agility / 2;
         uint256 damageTo1 = morph2Attack > morph1Defense ? morph2Attack - morph1Defense : 0;

         if (newAttr1.vitality > damageTo1) {
              newAttr1.vitality -= uint32(damageTo1);
         } else {
              newAttr1.vitality = 0;
         }
         if (newAttr2.vitality > damageTo2) {
              newAttr2.vitality -= uint32(damageTo2);
         } else {
              newAttr2.vitality = 0;
         }

        // Example: Energy cost for interaction
        uint32 energyCost = 10; // Example fixed cost
        if (newAttr1.chronoEnergy >= energyCost) newAttr1.chronoEnergy -= energyCost; else newAttr1.chronoEnergy = 0;
        if (newAttr2.chronoEnergy >= energyCost) newAttr2.chronoEnergy -= energyCost; else newAttr2.chronoEnergy = 0;


         _updateAttributes(morph1Id, newAttr1);
         _updateAttributes(morph2Id, newAttr2);

         emit InteractionSimulated(morph1Id, morph2Id);

         // Update interaction times for both morphs
         morph1.lastInteractionTime = block.timestamp;
         morph2.lastInteractionTime = block.timestamp;
    }

    /// @notice Sacrifices one morph to provide a benefit to another morph.
    /// @dev Burns `morphId` and applies an effect to `targetMorphId`.
    /// @param sacrificedMorphId The ID of the morph to sacrifice (will be burned).
    /// @param targetMorphId The ID of the morph that receives the benefit.
    function sacrificeMorph(uint256 sacrificedMorphId, uint256 targetMorphId) external {
         if (!_exists(sacrificedMorphId)) revert TokenDoesNotExist(sacrificedMorphId);
         if (!_exists(targetMorphId)) revert SacrificeTargetDoesNotExist();

         // Ensure sender owns or is approved for the sacrificed morph
         _requireOwnedOrApproved(sacrificedMorphId);

         ChronoMorph storage targetMorph = _morphs[targetMorphId];
         if (_isStateFrozen(targetMorphId)) revert MorphStateFrozen(targetMorphId);

         // --- Advanced/Creative Logic: Sacrifice Effect ---
         // Placeholder: Determine the benefit based on the sacrificed morph's species, attributes, etc.
         // Example: Gain a percentage of sacrificed morph's stats, or a specific boost type.
         MorphAttributes memory sacrificedAttributes = _morphs[sacrificedMorphId].attributes;
         MorphAttributes memory oldTargetAttributes = targetMorph.attributes;
         MorphAttributes memory newTargetAttributes = oldTargetAttributes;

         // Example: Gain 10% of sacrificed morph's stats
         newTargetAttributes.strength += sacrificedAttributes.strength / 10;
         newTargetAttributes.agility += sacrificedAttributes.agility / 10;
         newTargetAttributes.resilience += sacrificedAttributes.resilience / 10;
         newTargetAttributes.vitality += sacrificedAttributes.vitality / 5; // Vitality gets a bigger boost
         newTargetAttributes.chronoEnergy += sacrificedAttributes.chronoEnergy / 2;
         newTargetAttributes.latentPotential += sacrificedAttributes.latentPotential / 10;

         // Apply the changes to the target
         _updateAttributes(targetMorphId, newTargetAttributes);

         // Burn the sacrificed morph
         _burn(sacrificedMorphId);

         emit MorphSacrificed(sacrificedMorphId, targetMorphId);

          // Update interaction time for the target
         targetMorph.lastInteractionTime = block.timestamp;
    }

    /// @notice Applies a pseudo-random mutation to a ChronoMorph's attributes.
    /// @dev The outcome depends on the seed, current attributes, and state.
    /// @param morphId The ID of the morph to mutate.
    /// @param mutationSeed A seed value (can be user-provided, or derived from block data).
    function mutate(uint256 morphId, uint256 mutationSeed) external {
         ChronoMorph storage morph = _morphs[morphId];
         _requireOwnedOrApproved(morphId);
         if (_isStateFrozen(morphId)) revert MorphStateFrozen(morphId);

         MorphAttributes memory oldAttributes = morph.attributes;
         MorphAttributes memory newAttributes = oldAttributes;

         // --- Advanced/Creative Logic: Mutation Effect ---
         // Placeholder: Use the seed and current block data for pseudo-randomness.
         // The mutation logic should be complex, potentially boosting some stats,
         // lowering others, or even adding/removing state flags based on the seed
         // and current attributes.

         uint256 randomFactor = uint256(keccak256(abi.encodePacked(morphId, mutationSeed, block.timestamp, block.difficulty)));

         // Example Mutation Logic:
         // Based on randomFactor, decide which attribute to affect and how much.
         // Add some percentage, subtract some percentage, cap at min/max values.

         uint252 attrIndex = (randomFactor % 6); // Which attribute to strongly affect (0-5)
         uint256 changeAmount = (randomFactor % 100) + 1; // Change amount (1-100)
         bool increase = (randomFactor % 2) == 0; // Increase or decrease?

         if (attrIndex == 0) { // Strength
             if (increase) newAttributes.strength += uint32(changeAmount); else newAttributes.strength = newAttributes.strength > changeAmount ? newAttributes.strength - uint32(changeAmount) : 0;
         } else if (attrIndex == 1) { // Agility
             if (increase) newAttributes.agility += uint32(changeAmount); else newAttributes.agility = newAttributes.agility > changeAmount ? newAttributes.agility - uint32(changeAmount) : 0;
         } else if (attrIndex == 2) { // Resilience
             if (increase) newAttributes.resilience += uint32(changeAmount); else newAttributes.resilience = newAttributes.resilience > changeAmount ? newAttributes.resilience - uint32(changeAmount) : 0;
         } else if (attrIndex == 3) { // Vitality
              if (increase) newAttributes.vitality += uint32(changeAmount * 2); // Vitality changes more
              else newAttributes.vitality = newAttributes.vitality > changeAmount ? newAttributes.vitality - uint32(changeAmount) : 0;
         } else if (attrIndex == 4) { // ChronoEnergy
              if (increase) newAttributes.chronoEnergy += uint32(changeAmount * 3); // Energy changes most
              else newAttributes.chronoEnergy = newAttributes.chronoEnergy > changeAmount ? newAttributes.chronoEnergy - uint32(changeAmount * 2) : 0;
         } else if (attrIndex == 5) { // LatentPotential
              if (increase) newAttributes.latentPotential += uint32(changeAmount); else newAttributes.latentPotential = newAttributes.latentPotential > changeAmount ? newAttributes.latentPotential - uint32(changeAmount) : 0;
         }

         // Optional: Set a state flag indicating mutation occurred
         morph.stateFlags |= (1 << 1); // Example: Set bit 1 for Mutated state

         _updateAttributes(morphId, newAttributes);
         emit MorphMutated(morphId, mutationSeed);

         // Update last interaction time
         morph.lastInteractionTime = block.timestamp;
    }

    /// @notice Freezes a ChronoMorph's state, preventing certain state changes like decay.
    /// @dev Duration in seconds.
    /// @param morphId The ID of the morph to freeze.
    /// @param duration The duration (in seconds) for which the state is frozen.
    function freezeState(uint256 morphId, uint256 duration) external {
         ChronoMorph storage morph = _morphs[morphId];
         _requireOwnedOrApproved(morphId);

         // Set the frozen state flag and the end time
         morph.stateFlags |= (1 << 0); // Example: Set bit 0 for Frozen state
         morph.freezeEndTime = block.timestamp + duration;

         emit StateFrozen(morphId, morph.freezeEndTime);
    }

    /// @notice Manually unfreezes a ChronoMorph's state.
    /// @param morphId The ID of the morph to unfreeze.
    function unfreezeState(uint256 morphId) external {
         ChronoMorph storage morph = _morphs[morphId];
         _requireOwnedOrApproved(morphId);

         // Clear the frozen state flag and reset end time
         morph.stateFlags &= ~(1 << 0); // Clear bit 0
         morph.freezeEndTime = 0;

         emit StateUnfrozen(morphId);
    }


    // --- 10. Configuration Functions (Owner Only) ---

    /// @notice Sets or updates the base attributes for a specific species ID.
    /// @dev Only callable by the contract owner.
    /// @param speciesId The ID of the species to configure.
    /// @param baseAttributes The MorphAttributes struct containing the base values.
    function setAttributeBase(uint8 speciesId, MorphAttributes memory baseAttributes) external onlyOwner {
        _speciesConfig[speciesId] = SpeciesConfig({
            baseAttributes: baseAttributes
            // species-specific rules could be set here too
        });
    }

     /// @notice Sets or updates the configuration data for a specific catalyst ID.
    /// @dev Only callable by the contract owner. The `effectData` bytes should encode the catalyst logic parameters.
    /// @param catalystId The ID of the catalyst to configure.
    /// @param effectData The bytes data defining the catalyst's effect logic and parameters.
    function setCatalystEffectConfig(uint256 catalystId, bytes memory effectData) external onlyOwner {
        _catalystConfig[catalystId] = effectData;
    }

    /// @notice Sets or updates a general morph configuration type.
    /// @dev Only callable by the contract owner. Use different `configType` values for different sets of parameters.
    /// @param configType The ID of the configuration type to set (e.g., 1 for default).
    /// @param config The MorphConfig struct containing the parameters.
    function setMorphConfig(uint8 configType, MorphConfig memory config) external onlyOwner {
        _morphConfigs[configType] = config;
    }

    // --- 11. View Helpers ---

     /// @notice Gets a specific morph configuration struct by type.
    /// @param configType The ID of the configuration type.
    /// @return The MorphConfig struct.
    function getConfig(uint8 configType) public view returns (MorphConfig memory) {
        MorphConfig memory config = _morphConfigs[configType];
        if (config.decayInterval == 0 && config.breedingEnergyCost == 0 && config.minAttributeForEvolution == 0) { // Basic check if config exists
             revert InvalidConfigType();
        }
        return config;
    }


    /// @notice Returns the total number of ChronoMorphs minted.
    function getTotalSupply() public view returns (uint256) {
        return _nextMorphId - 1; // Since IDs start from 1
    }

    // --- 12. Internal Helper Functions ---

    /// @dev Checks if a morph exists.
    function _exists(uint256 tokenId) internal view returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /// @dev Checks if the caller is the owner of the morph.
    function _requireOwned(uint256 tokenId) internal view {
        if (ownerOf(tokenId) != msg.sender) { // ownerOf checks existence
            revert NotOwnerOrApproved(tokenId); // Using a generic error for simplicity
        }
    }

     /// @dev Checks if the caller is the owner or approved for the morph.
    function _requireOwnedOrApproved(uint256 tokenId) internal view {
        address owner_ = ownerOf(tokenId); // Checks existence
        if (!(owner_ == msg.sender || getApproved(tokenId) == msg.sender || isApprovedForAll(owner_, msg.sender))) {
            revert NotOwnerOrApproved(tokenId);
        }
    }

    /// @dev Internal transfer logic.
    function _transfer(address from, address to, uint256 tokenId) internal {
        address owner_ = ownerOf(tokenId); // Checks existence
        if (owner_ != from) revert NotOwnerOrApproved(tokenId); // Ensure 'from' is the actual owner
        if (to == address(0)) revert TransferToZeroAddress();

        // Permission check: caller must be owner, approved, or operator
        if (!(owner_ == msg.sender || getApproved(tokenId) == msg.sender || isApprovedForAll(owner_, msg.sender))) {
             revert NotOwnerOrApproved(tokenId);
        }

        _approve(address(0), tokenId); // Clear approval for the token

        _balances[from]--;
        _owners[tokenId] = to; // Update ERC721 owner mapping
        _balances[to]++;

        _morphs[tokenId].owner = to; // Update owner in ChronoMorph struct

        emit Transfer(from, to, tokenId);
    }

     /// @dev Internal mint logic (used by genesisMint).
    function _mint(address to, uint256 tokenId) internal {
        if (to == address(0)) revert TransferToZeroAddress();
        if (_exists(tokenId)) revert Unauthorized(); // Should not happen with _nextMorphId

        _balances[to]++;
        _owners[tokenId] = to; // Update ERC721 owner mapping
        // ChronoMorph struct is created in genesisMint before _mint is called

        emit Transfer(address(0), to, tokenId);
    }

    /// @dev Internal burn logic (used by sacrificeMorph).
    function _burn(uint256 tokenId) internal {
        address owner_ = ownerOf(tokenId); // Checks existence
        if (owner_ == address(0)) revert TokenDoesNotExist(tokenId); // Should not happen

        _approve(address(0), tokenId); // Clear approvals

        _balances[owner_]--;
        delete _owners[tokenId]; // Clear ERC721 owner mapping
        delete _approvals[tokenId]; // Clear token-specific approval

        // Clear data in ChronoMorph struct (marking it as burned/non-existent for logic)
        delete _morphs[tokenId]; // This makes _exists(tokenId) check work correctly using _owners

        emit Transfer(owner_, address(0), tokenId);
    }

    /// @dev Internal helper to approve an address for a token.
    function _approve(address to, uint256 tokenId) internal {
        _approvals[tokenId] = to;
        emit Approval(ownerOf(tokenId), to, tokenId); // ownerOf checks existence
    }

    /// @dev Internal helper to check if a contract receiver can accept ERC721 tokens.
    function _checkOnERC721Received(address operator, address from, address to, uint256 tokenId, bytes calldata data) internal returns (bool) {
        try IERC721Receiver(to).onERC721Received(operator, from, tokenId, data) returns (bytes4 retval) {
            return retval == IERC721Receiver.onERC721Received.selector;
        } catch (bytes memory reason) {
            if (reason.length > 0) {
                // Handle revert reason from receiver contract if needed
                // For simplicity, re-revert or log the reason
            }
            return false; // Indicates the call failed or returned incorrect value
        }
    }

    /// @dev Internal helper to update morph attributes and emit the AttributesChanged event.
    function _updateAttributes(uint256 morphId, MorphAttributes memory newAttributes) internal {
        ChronoMorph storage morph = _morphs[morphId];
        MorphAttributes memory oldAttributes = morph.attributes; // Capture current state before update
        morph.attributes = newAttributes;
        emit AttributesChanged(morphId, oldAttributes, newAttributes);
    }

    /// @dev Internal helper to check if a morph's state is currently frozen.
    function _isStateFrozen(uint256 morphId) internal view returns (bool) {
         ChronoMorph storage morph = _morphs[morphId];
         // Check the flag AND if the current time is before the freeze end time
         return (morph.stateFlags & (1 << 0) != 0) && (block.timestamp < morph.freezeEndTime);
    }

     /// @dev Internal helper to check if sender is owner or approved/operator.
     function _isApprovedOrOwner(address sender, uint256 tokenId) internal view returns (bool) {
         address owner_ = ownerOf(tokenId); // Checks existence
         return (owner_ == sender || getApproved(tokenId) == sender || isApprovedForAll(owner_, sender));
     }

     // Helper for max uint32
     function max(uint32 a, uint32 b) internal pure returns (uint32) {
         return a >= b ? a : b;
     }

     // Optional: Implement ERC165 support
    /*
    bytes4 private constant _INTERFACE_ID_ERC721 = 0x80ac58cd;
    bytes4 private constant _INTERFACE_ID_ERC721_METADATA = 0x5b5e139f; // Optional, not implemented attributes as metadata
    bytes4 private constant _INTERFACE_ID_ERC721_ENUMERABLE = 0x780e9d63; // Optional, not implemented enumerable

    function supportsInterface(bytes4 interfaceId) public view virtual returns (bool) {
        return interfaceId == _INTERFACE_ID_ERC721 || interfaceId == type(IERC165).interfaceId;
    }
    */
}
```

**Explanation of Advanced/Creative/Trendy Concepts:**

1.  **Dynamic, Mutable State (Beyond Static Metadata):** Unlike typical NFTs where metadata is static or points to an external file, ChronoMorphs have core attributes (`MorphAttributes`) stored directly on-chain that are *designed* to change via contract functions (`applyCatalyst`, `triggerEvolution`, etc.). This is a core advanced concept allowing for persistent on-chain state evolution.
2.  **Attribute-Based Mechanics:** Many functions (`triggerEvolution`, `breed`, `simulateInteraction`, `sacrificeMorph`, `mutate`) explicitly use or modify the ChronoMorph's numerical attributes. This enables complex game-like or simulation mechanics driven purely by on-chain state.
3.  **Catalyst System:** The `applyCatalyst` function is a flexible pattern for introducing external effects. By using `catalystId` and `catalystData` mapping to `_catalystConfig` (which stores raw `bytes`), the contract owner can configure *new types* of attribute-modifying effects over time without changing the core `applyCatalyst` function's signature. The placeholder logic shows how different IDs would trigger different effects. This allows for evolving game design or mechanics managed by the contract owner.
4.  **On-chain Evolution & Breeding Logic:** `triggerEvolution` and `breed` implement complex state transitions that create new entities or significantly change existing ones based on internal rules and current attributes. This moves beyond simple minting to a generative process driven by user interaction with the contract state.
5.  **Interaction Simulation:** `simulateInteraction` is an example of implementing complex, multi-entity logic purely on-chain, modifying the state of *multiple* tokens in a single transaction based on a defined ruleset (like combat).
6.  **Sacrifice Mechanic:** `sacrificeMorph` introduces a "burning for benefit" pattern, where tokens are destroyed to enhance others. This adds a deflationary aspect and a strategic decision point for users.
7.  **On-chain Mutation (with Pseudo-Randomness):** The `mutate` function uses on-chain data (`block.timestamp`, `block.difficulty`) combined with a user-provided seed (`mutationSeed`) and token state (`morphId`) to introduce pseudo-random changes to attributes. While true randomness is hard on-chain, this demonstrates implementing probabilistic outcomes based on available block data.
8.  **State Freezing:** `freezeState` and `unfreezeState` add a mechanism to temporarily protect assets from certain state-changing effects (like decay or interactions), introducing another layer of strategic management for the owner.
9.  **Configurability:** The contract includes owner-only functions (`setAttributeBase`, `setCatalystEffectConfig`, `setMorphConfig`) to configure key parameters like species base stats, catalyst effects, and decay/breeding rules. This allows for balancing and evolving the game/simulation mechanics over time without requiring full contract upgrades (for these specific parameters).

This contract provides a framework for a complex on-chain ecosystem where assets are not static collectibles but living entities whose traits and value change based on active participation and simulated environmental factors.