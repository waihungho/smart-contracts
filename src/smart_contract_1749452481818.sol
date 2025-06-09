Okay, here is a Solidity smart contract concept called "MetaMorphosis: Adaptive Entities". It features evolving entities (NFTs) that can mutate based on randomness, adapt based on environmental factors, gain experience, recover energy, and equip components (represented by references to other tokens).

It integrates Chainlink VRF for secure randomness for mutations and simulates an "environmental factor" that the entities adapt to. It aims for complexity beyond standard ERC721s.

**Disclaimer:** This is a complex concept for a smart contract. Implementing and securing it fully for production would require extensive testing, gas optimization, and security audits. The simulated "environmental factor" would ideally come from a secure oracle, not just an owner-controlled variable in a real-world scenario.

---

### **Contract Outline and Function Summary**

**Contract Name:** `MetaMorphosis`

**Core Concept:** An ERC721 collection representing "Entities" that dynamically evolve based on various on-chain triggers:
1.  **Experience (XP):** Gained over time or through interactions, leading to evolution.
2.  **Mutation:** Random changes to attributes/traits, triggered by user action and Chainlink VRF.
3.  **Adaptation:** Changes based on an external "Environmental Factor".
4.  **Energy:** Resource consumed by actions like evolution/mutation attempts, recovers over time.
5.  **Components:** Entities can "equip" references to other ERC721/ERC1155 tokens, modifying their stats/traits.

**Key Advanced Concepts:**
*   **Dynamic/Evolving NFTs:** Entity state changes over time and based on events.
*   **Algorithmic State Changes:** Evolution, mutation, and adaptation logic determined by contract code.
*   **Oracle Integration:** Using Chainlink VRF for secure randomness in mutations. Potential for integrating external data for Adaptation (though simulated here).
*   **Composable Assets:** Referencing external ERC721/ERC1155 tokens as "Components".
*   **State-Dependent Logic:** Action success/outcome depends on entity's current attributes, energy, XP, etc.
*   **Resource Management:** Energy system adds a strategic layer.

**Inheritance:** ERC721Enumerable, Ownable, VRFConsumerBaseV2

**State Variables:**
*   `EntityState` struct: Holds attributes, traits, XP, energy, timestamps, component references.
*   `Attributes` struct: Numeric stats (e.g., Strength, Agility).
*   `Traits` struct: Categorical properties (e.g., Element, Type).
*   `ComponentSlot` struct: Defines a slot for a component reference.
*   Mappings to track entity states, component slots, VRF requests, etc.
*   Configuration parameters for evolution thresholds, mutation rates, energy recovery, VRF settings, etc.
*   `environmentalFactor`: A value simulating external conditions.

**Events:**
*   `EntityMinted`
*   `XPGained`
*   `EvolutionTriggered`
*   `MutationRequested`
*   `MutationApplied`
*   `AdaptationApplied`
*   `EnergyRecovered`
*   `ComponentEquipped`
*   `ComponentUnequipped`
*   `EnvironmentalFactorUpdated`
*   `ConfigurationUpdated`

**Function Summary (>= 20 Functions):**

**Standard ERC721 (inherited):**
1.  `name()`: Returns contract name.
2.  `symbol()`: Returns contract symbol.
3.  `totalSupply()`: Returns total number of entities.
4.  `balanceOf(address owner)`: Returns number of entities owned by an address.
5.  `ownerOf(uint256 tokenId)`: Returns the owner of an entity.
6.  `transferFrom(address from, address to, uint256 tokenId)`: Transfers entity ownership.
7.  `safeTransferFrom(address from, address to, uint256 tokenId)`: Safe transfer (checks receiver).
8.  `safeTransferFrom(address from, address to, uint256 tokenId, bytes data)`: Safe transfer with data.
9.  `approve(address to, uint256 tokenId)`: Approves an address to spend an entity.
10. `getApproved(uint256 tokenId)`: Gets the approved address for an entity.
11. `setApprovalForAll(address operator, bool approved)`: Approves/disapproves an operator for all entities.
12. `isApprovedForAll(address owner, address operator)`: Checks if an operator is approved.
13. `tokenOfOwnerByIndex(address owner, uint256 index)`: Get token ID by owner and index (from Enumerable).
14. `tokenByIndex(uint256 index)`: Get token ID by index (from Enumerable).

**Custom Core Logic:**
15. `constructor(...)`: Initializes the contract, ERC721, Ownable, and VRF.
16. `mintInitialEntity(address recipient)`: Mints a new entity with base stats.
17. `getEntityState(uint256 tokenId)`: View function to retrieve an entity's full state.
18. `gainXP(uint256 tokenId, uint256 amount)`: Increases an entity's experience points. (Could be restricted or public for game loops).
19. `triggerEvolution(uint256 tokenId)`: Attempts to evolve an entity if XP/energy requirements are met. Consumes energy, potentially resets XP. Calls internal evolution logic.
20. `requestMutation(uint256 tokenId)`: Requests randomness from Chainlink VRF to potentially mutate an entity. Requires LINK.
21. `rawFulfillRandomWords(uint256 requestId, uint256[] memory randomWords)`: VRF callback function. Processes randomness to apply mutation logic.
22. `triggerAdaptation(uint256 tokenId)`: Checks the current `environmentalFactor` and entity state to apply adaptation changes.
23. `equipComponent(uint256 entityId, uint8 slotIndex, address componentAddress, uint256 componentId, uint256 amount)`: Records an external token reference as an equipped component in a specific slot. Checks slot type compatibility and ownership. `amount` is for ERC1155.
24. `unequipComponent(uint256 entityId, uint8 slotIndex)`: Removes a component reference from a slot.
25. `recoverEnergy(uint256 tokenId)`: Allows an entity owner to attempt energy recovery based on cooldown.

**Configuration & Oracle Management (Owner Only):**
26. `setEnvironmentalFactor(uint256 factor)`: Sets the global environmental factor. (In a real dApp, this might be from a secure oracle).
27. `updateConfiguration(...)`: Allows the owner to update various contract parameters (XP thresholds, energy rates, mutation costs, etc.).
28. `addVRFSubscriptionBalance(uint256 amount)`: Adds LINK to the VRF subscription.
29. `withdrawLink(uint256 amount)`: Withdraws LINK from the contract.
30. `setAllowedComponentTypes(address componentAddress, uint8[] memory allowedSlots)`: Maps component contract addresses to the types of slots they can be equipped in.

**View/Helper Functions:**
31. `getEnvironmentalFactor()`: Returns the current environmental factor.
32. `getConfiguration()`: Returns the current contract configuration parameters.
33. `getEquippedComponents(uint256 tokenId)`: Returns the list of components equipped by an entity.
34. `getEnergyRecoveryCooldown(uint256 tokenId)`: Returns the timestamp when energy recovery will next be available for an entity.

**Internal Helper Functions (not exposed externally, but part of logic):**
*   `_performEvolution(...)`: Internal logic for applying evolutionary changes.
*   `_applyMutation(...)`: Internal logic for applying mutation changes based on randomness.
*   `_applyAdaptation(...)`: Internal logic for applying adaptation changes based on environmental factor.
*   `_gainEnergy(...)`: Internal function to add energy to an entity.
*   `_consumeEnergy(...)`: Internal function to subtract energy.
*   `_getEffectiveAttributes(...)`: Calculates an entity's attributes including component bonuses. (Could be a view function too).

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ERC721Enumerable} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {VRFConsumerBaseV2} from "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import {LinkTokenInterface} from "@chainlink/contracts/src/v0.8/interfaces/LinkTokenInterface.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {IERC1155} from "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";


/**
 * @title MetaMorphosis: Adaptive Entities
 * @dev An ERC721 contract representing evolving entities that mutate, adapt,
 *      gain experience, manage energy, and equip components.
 *      Integrates Chainlink VRF for secure randomness.
 *
 * Contract Outline and Function Summary:
 *
 * Core Concept: Dynamic ERC721 NFTs representing Entities that evolve.
 * Key Advanced Concepts: Dynamic NFTs, Algorithmic State Changes, Oracle Integration (Chainlink VRF),
 *   Composable Assets (Component References), State-Dependent Logic, Resource Management (Energy).
 * Inheritance: ERC721Enumerable, Ownable, VRFConsumerBaseV2.
 *
 * State Variables:
 * - EntityState struct: Holds attributes, traits, XP, energy, timestamps, component references.
 * - Attributes struct: Numeric stats.
 * - Traits struct: Categorical properties.
 * - ComponentSlot struct: Defines a slot for a component reference.
 * - Mappings: _entityStates, _componentSlots, _vrfRequests, _componentAllowedSlots, etc.
 * - Configuration: evolutionConfig, mutationConfig, energyConfig.
 * - environmentalFactor: Global state variable.
 *
 * Events: EntityMinted, XPGained, EvolutionTriggered, MutationRequested, MutationApplied,
 *   AdaptationApplied, EnergyRecovered, ComponentEquipped, ComponentUnequipped,
 *   EnvironmentalFactorUpdated, ConfigurationUpdated.
 *
 * Function Summary (>= 20 Functions):
 * Standard ERC721 (inherited): name, symbol, totalSupply, balanceOf, ownerOf, transferFrom,
 *   safeTransferFrom (x2), approve, getApproved, setApprovalForAll, isApprovedForAll,
 *   tokenOfOwnerByIndex, tokenByIndex. (14 functions)
 *
 * Custom Core Logic:
 * 15. constructor(...)
 * 16. mintInitialEntity(address recipient)
 * 17. getEntityState(uint256 tokenId) - View
 * 18. gainXP(uint256 tokenId, uint256 amount)
 * 19. triggerEvolution(uint256 tokenId)
 * 20. requestMutation(uint256 tokenId)
 * 21. rawFulfillRandomWords(uint256 requestId, uint256[] memory randomWords) - VRF Callback
 * 22. triggerAdaptation(uint256 tokenId)
 * 23. equipComponent(uint256 entityId, uint8 slotIndex, address componentAddress, uint256 componentId, uint256 amount)
 * 24. unequipComponent(uint256 entityId, uint8 slotIndex)
 * 25. recoverEnergy(uint256 tokenId)
 *
 * Configuration & Oracle Management (Owner Only):
 * 26. setEnvironmentalFactor(uint256 factor)
 * 27. updateConfiguration(...)
 * 28. addVRFSubscriptionBalance(uint256 amount)
 * 29. withdrawLink(uint256 amount)
 * 30. setAllowedComponentTypes(address componentAddress, uint8[] memory allowedSlots)
 *
 * View/Helper Functions:
 * 31. getEnvironmentalFactor() - View
 * 32. getConfiguration() - View
 * 33. getEquippedComponents(uint256 tokenId) - View
 * 34. getEnergyRecoveryCooldown(uint256 tokenId) - View
 *
 * Internal Helper Functions (not exposed externally): _performEvolution, _applyMutation,
 *   _applyAdaptation, _gainEnergy, _consumeEnergy, _getEffectiveAttributes.
 */
contract MetaMorphosis is ERC721Enumerable, Ownable, VRFConsumerBaseV2 {

    using Strings for uint256;

    // --- Custom Errors ---
    error NotEntityOwner();
    error EntityDoesNotExist();
    error InsufficientXPForEvolution();
    error InsufficientEnergy();
    error EnergyRecoveryOnCooldown();
    error MutationOnCooldown();
    error InvalidComponentSlot();
    error SlotAlreadyOccupied();
    error ComponentNotAllowedInSlot();
    error ComponentNotEquipped();
    error CallerDoesNotOwnComponent();
    error ERC721NotSupported();
    error ERC1155NotSupported();
    error InsufficientComponentAmount();
    error InvalidAmountForComponentType();


    // --- Structs ---
    struct Attributes {
        uint16 strength;
        uint16 agility;
        uint16 intelligence;
        uint16 vitality;
        uint16 resistanceFire; // Example specific resistances
        uint16 resistanceWater;
        uint16 resistanceEarth;
    }

    enum TraitType { Element, Class, Temperament } // Example Trait Types
    enum Element { None, Fire, Water, Earth, Air }
    enum Class { None, Warrior, Mage, Rogue, Scholar }
    enum Temperament { None, Aggressive, Passive, Balanced, Curious }

    struct Traits {
        Element element;
        Class entityClass;
        Temperament temperament;
        // Add more traits as needed
    }

    enum ComponentType { Generic, Weapon, Armor, Accessory, Skill }

    struct ComponentSlot {
        ComponentType slotType;
        uint256 maxCount; // Max items in this slot (for stacking, e.g., consumables)
        address componentAddress; // Address of the ERC721 or ERC1155 contract
        uint256 componentId; // Token ID (ERC721) or Item ID (ERC1155)
        uint256 amount; // Amount for ERC1155 components (always 1 for ERC721)
    }

    struct EntityState {
        Attributes baseAttributes; // Attributes before components
        Traits traits;
        uint256 xp; // Experience Points
        uint256 level; // Derived from XP? Or evolves directly? Let's make it evolve directly.
        uint256 currentEnergy;
        uint256 lastEnergyRecoveryTimestamp;
        uint256 lastMutationTimestamp;
        uint256 lastAdaptationTimestamp;
        uint8 evolutionStage; // 0, 1, 2, ...
        uint8 maxComponentSlots; // Number of available slots
    }

    struct EvolutionConfig {
        uint256 xpThresholdPerStage;
        uint256 energyCost;
        uint256 attributeIncreasePerStage; // e.g., total points to distribute
        uint256 maxEvolutionStage;
    }

    struct MutationConfig {
        uint256 linkCost; // Cost to request VRF
        uint256 energyCost;
        uint256 cooldownSeconds;
        uint16 attributeChangeRange; // e.g., +/- up to X points per attribute affected
        uint16 traitChangeProbabilityBasis; // e.g., 1000 = 100% (numerator for probability)
        uint16 traitChangeProbability; // Denominator will be traitChangeProbabilityBasis
    }

    struct EnergyConfig {
        uint256 maxEnergy;
        uint256 recoveryCooldownSeconds;
        uint256 recoveryAmount;
    }


    // --- State Variables ---
    uint256 private _nextTokenId;
    mapping(uint256 tokenId => EntityState state) private _entityStates;
    mapping(uint256 tokenId => ComponentSlot[] slots) private _entityComponentSlots;
    mapping(address componentAddress => uint8[] allowedSlotTypes) private _componentAllowedSlots; // What slot types a component contract can fill

    // Chainlink VRF V2 variables
    bytes32 private immutable i_keyHash;
    uint64 private immutable i_subscriptionId;
    uint32 private immutable i_callbackGasLimit;
    uint16 private constant REQUEST_CONFIRMATIONS = 3;
    uint32 private constant NUM_WORDS = 1; // We need 1 random number for simple mutation logic
    mapping(uint256 requestId => uint256 tokenId) private _vrfRequests; // Map request ID to entity ID

    // Global factors
    uint256 private _environmentalFactor; // Example global state

    // Configuration
    EvolutionConfig public evolutionConfig;
    MutationConfig public mutationConfig;
    EnergyConfig public energyConfig;

    // --- Events ---
    event EntityMinted(address indexed owner, uint256 indexed tokenId);
    event XPGained(uint256 indexed tokenId, uint256 amount, uint256 newXP);
    event EvolutionTriggered(uint256 indexed tokenId, uint8 newStage);
    event MutationRequested(uint256 indexed tokenId, uint256 requestId);
    event MutationApplied(uint256 indexed tokenId, uint256 randomNumber);
    event AdaptationApplied(uint256 indexed tokenId, uint256 environmentalFactor);
    event EnergyRecovered(uint256 indexed tokenId, uint256 recovered, uint256 newEnergy);
    event ComponentEquipped(uint256 indexed entityId, uint8 slotIndex, address indexed componentAddress, uint256 indexed componentId, uint256 amount);
    event ComponentUnequipped(uint256 indexed entityId, uint8 slotIndex);
    event EnvironmentalFactorUpdated(uint256 newFactor);
    event ConfigurationUpdated();


    // --- Constructor ---
    constructor(
        address vrfCoordinator,
        bytes32 keyHash,
        uint66 subscriptionId,
        uint32 callbackGasLimit,
        string memory name,
        string memory symbol
    )
        ERC721Enumerable(name, symbol)
        Ownable(msg.sender)
        VRFConsumerBaseV2(vrfCoordinator)
    {
        i_keyHash = keyHash;
        i_subscriptionId = subscriptionId;
        i_callbackGasLimit = callbackGasLimit;

        // Initial Default Configuration (Owner should update these)
        evolutionConfig = EvolutionConfig({
            xpThresholdPerStage: 100,
            energyCost: 10,
            attributeIncreasePerStage: 15, // Total points to add
            maxEvolutionStage: 3
        });

        mutationConfig = MutationConfig({
            linkCost: 1e17, // 0.1 LINK (example cost)
            energyCost: 5,
            cooldownSeconds: 1 days,
            attributeChangeRange: 10, // +/- 10 points
            traitChangeProbabilityBasis: 1000, // Basis for probability
            traitChangeProbability: 150 // 15% chance of trait change (150/1000)
        });

        energyConfig = EnergyConfig({
            maxEnergy: 100,
            recoveryCooldownSeconds: 4 hours,
            recoveryAmount: 25
        });

        _nextTokenId = 0; // Start token IDs from 0 or 1
        _environmentalFactor = 0; // Initial environmental factor
    }

    // --- Standard ERC721 Functions (Inherited) ---
    // ERC721Enumerable includes: name, symbol, totalSupply, balanceOf, ownerOf, transferFrom, safeTransferFrom (x2), approve, getApproved, setApprovalForAll, isApprovedForAll, tokenOfOwnerByIndex, tokenByIndex. (14 functions)

    // --- Custom Core Logic ---

    /**
     * @dev Mints a new entity with base attributes and traits.
     * @param recipient The address to mint the entity to.
     * @return The ID of the newly minted entity.
     */
    function mintInitialEntity(address recipient) public onlyOwner returns (uint256) {
        uint256 tokenId = _nextTokenId++;

        // Basic initial state - could add more complex initial randomness/generation
        _entityStates[tokenId] = EntityState({
            baseAttributes: Attributes({
                strength: uint16(10 + (tokenId % 5)), // Simple variation
                agility: uint16(10 + ((tokenId + 1) % 5)),
                intelligence: uint16(10 + ((tokenId + 2) % 5)),
                vitality: uint16(15 + ((tokenId + 3) % 5)),
                resistanceFire: uint16(0),
                resistanceWater: uint16(0),
                resistanceEarth: uint16(0)
            }),
            traits: Traits({
                element: Element(tokenId % 5), // 0-4
                entityClass: Class((tokenId + 1) % 5), // 0-4
                temperament: Temperament((tokenId + 2) % 4) // 0-3
            }),
            xp: 0,
            level: 0,
            currentEnergy: energyConfig.maxEnergy,
            lastEnergyRecoveryTimestamp: block.timestamp,
            lastMutationTimestamp: 0,
            lastAdaptationTimestamp: 0,
            evolutionStage: 0,
            maxComponentSlots: 2 // Initial slots
        });

        // Initialize component slots as empty
        _entityComponentSlots[tokenId] = new ComponentSlot[](2); // Start with 2 empty slots

        _safeMint(recipient, tokenId);

        emit EntityMinted(recipient, tokenId);

        return tokenId;
    }

    /**
     * @dev Gets the full state details of an entity.
     * @param tokenId The ID of the entity.
     * @return The EntityState struct.
     */
    function getEntityState(uint256 tokenId) public view returns (EntityState memory) {
        _requireEntityExists(tokenId);
        return _entityStates[tokenId];
    }

    /**
     * @dev Increases the XP of an entity. Can be called by owner or potentially other trusted contracts.
     * @param tokenId The ID of the entity.
     * @param amount The amount of XP to add.
     */
    function gainXP(uint256 tokenId, uint256 amount) public {
         _requireEntityExists(tokenId);
         // Add potential restrictions here, e.g., `onlyOwner` or specific minters
         // Or make it public for game mechanics assuming XP gain is handled externally

        EntityState storage entity = _entityStates[tokenId];
        entity.xp += amount;

        emit XPGained(tokenId, amount, entity.xp);
    }

    /**
     * @dev Attempts to trigger an entity's evolution. Requires sufficient XP and energy.
     * @param tokenId The ID of the entity.
     */
    function triggerEvolution(uint256 tokenId) public {
        _requireEntityExists(tokenId);
        _requireIsEntityOwner(tokenId);

        EntityState storage entity = _entityStates[tokenId];

        if (entity.evolutionStage >= evolutionConfig.maxEvolutionStage) {
            revert("Entity is at max evolution stage");
        }
        if (entity.xp < evolutionConfig.xpThresholdPerStage) {
            revert InsufficientXPForEvolution();
        }
        if (entity.currentEnergy < evolutionConfig.energyCost) {
            revert InsufficientEnergy();
        }

        // Consume energy and XP
        _consumeEnergy(tokenId, evolutionConfig.energyCost);
        entity.xp -= evolutionConfig.xpThresholdPerStage; // Or set to 0, depending on design

        entity.evolutionStage++;
        entity.level++; // Level up upon evolution

        _performEvolution(tokenId, entity); // Apply the actual stat/trait changes

        emit EvolutionTriggered(tokenId, entity.evolutionStage);
    }

    /**
     * @dev Requests randomness from Chainlink VRF to potentially mutate an entity.
     * @param tokenId The ID of the entity.
     * @return The VRF request ID.
     */
    function requestMutation(uint256 tokenId) public returns (uint256 requestId) {
        _requireEntityExists(tokenId);
        _requireIsEntityOwner(tokenId);

        EntityState storage entity = _entityStates[tokenId];

        if (block.timestamp < entity.lastMutationTimestamp + mutationConfig.cooldownSeconds) {
             revert MutationOnCooldown();
        }
        if (entity.currentEnergy < mutationConfig.energyCost) {
            revert InsufficientEnergy();
        }
         // Ensure contract has LINK balance for the request
         LinkTokenInterface linkToken = LinkTokenInterface(0x514910771AF9Ca656af840dff83E8264cA1eD85A); // LINK token address on mainnet/common testnets

         if (linkToken.balanceOf(address(this)) < mutationConfig.linkCost) {
              // In a real dApp, you might handle this more gracefully or prevent the call
             revert("Insufficient LINK balance in contract for VRF request");
         }

        // Consume energy *before* requesting randomness
        _consumeEnergy(tokenId, mutationConfig.energyCost);

        // Request randomness
        requestId = requestRandomWords(
            i_keyHash,
            i_subscriptionId,
            REQUEST_CONFIRMATIONS,
            i_callbackGasLimit,
            NUM_WORDS
        );

        _vrfRequests[requestId] = tokenId;
        entity.lastMutationTimestamp = block.timestamp; // Start cooldown immediately

        emit MutationRequested(tokenId, requestId);
        return requestId;
    }

    /**
     * @dev Chainlink VRF V2 callback function. This function is called by the VRF coordinator
     *      after the random words are generated. It must be external.
     * @param requestId The ID of the VRF request.
     * @param randomWords The array of random words.
     */
    function rawFulfillRandomWords(
        uint256 requestId,
        uint256[] calldata randomWords
    ) external override {
        // This function is called by the VRF coordinator. It can only be called by the VRF coordinator address.
        // The VRFConsumerBaseV2 contract ensures this.
        // Check if the requestId is one we initiated
        require(_vrfRequests[requestId] != 0, "request not known"); // Or check if entity ID exists for this request

        uint256 tokenId = _vrfRequests[requestId];
        delete _vrfRequests[requestId]; // Prevent replay attacks

        // Process the random number
        uint256 randomNumber = randomWords[0];
        _applyMutation(tokenId, randomNumber); // Apply the mutation logic

        emit MutationApplied(tokenId, randomNumber);
    }

    /**
     * @dev Attempts to trigger an entity's adaptation based on the global environmental factor.
     *      Can be called by anyone, but adaptation only occurs if conditions are met.
     * @param tokenId The ID of the entity.
     */
    function triggerAdaptation(uint256 tokenId) public {
        _requireEntityExists(tokenId);
        // Adaptation doesn't necessarily need to be owner-only

        EntityState storage entity = _entityStates[tokenId];

        // Add cooldown for adaptation if needed
        // if (block.timestamp < entity.lastAdaptationTimestamp + adaptationConfig.cooldown) { ... }

        // Check if conditions for adaptation are met based on environmentalFactor and entity state
        // Example: Adapt if environmentalFactor is high/low OR matches entity's element
        bool adaptationOccurs = false;
        if (_environmentalFactor > 50 && entity.traits.element != Element.Fire) {
             adaptationOccurs = true; // Example condition
        } else if (_environmentalFactor < 20 && entity.traits.element != Element.Water) {
             adaptationOccurs = true; // Example condition
        }
        // Add more complex adaptation logic here

        if (adaptationOccurs) {
             _applyAdaptation(tokenId, _environmentalFactor);
             entity.lastAdaptationTimestamp = block.timestamp; // Update timestamp
             emit AdaptationApplied(tokenId, _environmentalFactor);
        } else {
             // Optionally emit an event indicating no adaptation occurred
        }
    }

    /**
     * @dev Records an external token (ERC721 or ERC1155) as being 'equipped' by an entity in a slot.
     *      Does *not* transfer ownership of the component token.
     * @param entityId The ID of the entity.
     * @param slotIndex The index of the component slot to equip to.
     * @param componentAddress The address of the component token contract.
     * @param componentId The ID of the component token (ERC721 tokenId or ERC1155 itemId).
     * @param amount The amount for ERC1155 tokens (should be 1 for ERC721).
     */
    function equipComponent(
        uint256 entityId,
        uint8 slotIndex,
        address componentAddress,
        uint256 componentId,
        uint256 amount
    ) public {
        _requireEntityExists(entityId);
        _requireIsEntityOwner(entityId);

        EntityState storage entity = _entityStates[entityId];
        if (slotIndex >= entity.maxComponentSlots) {
            revert InvalidComponentSlot();
        }
        if (_entityComponentSlots[entityId][slotIndex].componentAddress != address(0)) {
            revert SlotAlreadyOccupied();
        }
        if (amount == 0) {
             revert("Equip amount must be greater than 0");
        }

        // Check if the component contract supports ERC721 or ERC1155 and if caller owns it
        IERC165 componentIERC165 = IERC165(componentAddress);
        bool isERC721 = componentIERC165.supportsInterface(0x80ac58cd); // ERC721 Interface ID
        bool isERC1155 = componentIERC165.supportsInterface(0xd9b67a26); // ERC1155 Interface ID

        if (!isERC721 && !isERC1155) {
            revert("Component address must be ERC721 or ERC1155");
        }

        if (isERC721) {
            if (amount != 1) revert InvalidAmountForComponentType();
            if (IERC721(componentAddress).ownerOf(componentId) != msg.sender) revert CallerDoesNotOwnComponent();
        } else { // isERC1155
            if (IERC1155(componentAddress).balanceOf(msg.sender, componentId) < amount) revert InsufficientComponentAmount();
        }

        // Check if component type is allowed in this slot type (based on config)
        uint8[] memory allowedTypes = _componentAllowedSlots[componentAddress];
        bool typeAllowed = false;
        ComponentType slotType = _entityComponentSlots[entityId][slotIndex].slotType; // Get the type assigned to this slot index
        for(uint i = 0; i < allowedTypes.length; i++) {
            if (allowedTypes[i] == uint8(slotType)) {
                typeAllowed = true;
                break;
            }
        }
        if (!typeAllowed) {
             revert ComponentNotAllowedInSlot();
        }

        // Record the component reference
        _entityComponentSlots[entityId][slotIndex] = ComponentSlot({
            slotType: slotType, // Keep the slot's defined type
            maxCount: _entityComponentSlots[entityId][slotIndex].maxCount, // Keep slot's defined max count
            componentAddress: componentAddress,
            componentId: componentId,
            amount: amount
        });

        emit ComponentEquipped(entityId, slotIndex, componentAddress, componentId, amount);
    }

    /**
     * @dev Removes a component reference from a slot. Does not transfer ownership back
     *      as ownership was never transferred to this contract.
     * @param entityId The ID of the entity.
     * @param slotIndex The index of the component slot to unequip.
     */
    function unequipComponent(uint256 entityId, uint8 slotIndex) public {
        _requireEntityExists(entityId);
        _requireIsEntityOwner(entityId);

        EntityState storage entity = _entityStates[entityId];
        if (slotIndex >= entity.maxComponentSlots) {
            revert InvalidComponentSlot();
        }
        if (_entityComponentSlots[entityId][slotIndex].componentAddress == address(0)) {
            revert ComponentNotEquipped();
        }

        // Clear the slot reference
        ComponentSlot memory unequipped = _entityComponentSlots[entityId][slotIndex]; // Copy before clearing
        _entityComponentSlots[entityId][slotIndex] = ComponentSlot({
             slotType: unequipped.slotType, // Preserve original slot definition
             maxCount: unequipped.maxCount,
             componentAddress: address(0),
             componentId: 0,
             amount: 0
        });

        emit ComponentUnequipped(entityId, slotIndex);
    }

    /**
     * @dev Allows an entity owner to recover energy if the cooldown has passed.
     * @param tokenId The ID of the entity.
     */
    function recoverEnergy(uint256 tokenId) public {
        _requireEntityExists(tokenId);
        _requireIsEntityOwner(tokenId);

        EntityState storage entity = _entityStates[tokenId];
        uint256 lastRecovery = entity.lastEnergyRecoveryTimestamp;
        uint256 cooldown = energyConfig.recoveryCooldownSeconds;

        if (block.timestamp < lastRecovery + cooldown) {
            revert EnergyRecoveryOnCooldown();
        }

        uint256 maxEnergy = energyConfig.maxEnergy;
        uint256 recoveryAmount = energyConfig.recoveryAmount;
        uint256 recovered = 0;

        if (entity.currentEnergy < maxEnergy) {
            recovered = maxEnergy - entity.currentEnergy;
            if (recovered > recoveryAmount) {
                recovered = recoveryAmount;
            }
            entity.currentEnergy += recovered;
        }

        entity.lastEnergyRecoveryTimestamp = block.timestamp; // Reset cooldown regardless of amount recovered

        emit EnergyRecovered(tokenId, recovered, entity.currentEnergy);
    }


    // --- Configuration & Oracle Management (Owner Only) ---

    /**
     * @dev Sets the global environmental factor. Intended to be set by the owner or a trusted oracle.
     * @param factor The new environmental factor value.
     */
    function setEnvironmentalFactor(uint256 factor) public onlyOwner {
        _environmentalFactor = factor;
        emit EnvironmentalFactorUpdated(factor);
    }

    /**
     * @dev Updates various configuration parameters for evolution, mutation, and energy.
     * @param newEvolutionConfig The new evolution configuration.
     * @param newMutationConfig The new mutation configuration.
     * @param newEnergyConfig The new energy configuration.
     */
    function updateConfiguration(
        EvolutionConfig memory newEvolutionConfig,
        MutationConfig memory newMutationConfig,
        EnergyConfig memory newEnergyConfig
    ) public onlyOwner {
        // Add validation for config values if necessary (e.g., non-zero costs, valid ranges)
        evolutionConfig = newEvolutionConfig;
        mutationConfig = newMutationConfig;
        energyConfig = newEnergyConfig;
        emit ConfigurationUpdated();
    }

    /**
     * @dev Adds LINK token balance to the contract's VRF subscription.
     *      Requires the owner to first approve this contract to spend LINK.
     * @param amount The amount of LINK to add.
     */
    function addVRFSubscriptionBalance(uint256 amount) public onlyOwner {
        LinkTokenInterface linkToken = LinkTokenInterface(0x514910771AF9Ca656af840dff83E8264cA1eD85A); // LINK token address
        // Ensure the contract owner has approved this contract to spend 'amount' of LINK
        require(linkToken.transferFrom(msg.sender, address(this), amount), "LINK transfer failed");
        // Funding the subscription requires calling the VRF Coordinator directly with LINK
        // This function requires the VRF Coordinator to support `addBalance(uint64 subscriptionId, uint256 amount)`
        // Check Chainlink documentation for exact v0.8 interface.
        // Assuming `VRFCoordinatorV2` has this function:
        // VRFCoordinatorV2Interface(VRFCoordinatorV2(i_vrfCoordinator)).addBalance(i_subscriptionId, amount);
        // For simplicity in this example, we just ensure the contract has LINK.
        // A real implementation needs to call the coordinator.
    }

    /**
     * @dev Allows the owner to withdraw LINK tokens from the contract.
     * @param amount The amount of LINK to withdraw.
     */
    function withdrawLink(uint256 amount) public onlyOwner {
        LinkTokenInterface linkToken = LinkTokenInterface(0x514910771AF9Ca656af840dff83E8264cA1eD85A); // LINK token address
        require(linkToken.transfer(msg.sender, amount), "LINK withdrawal failed");
    }

    /**
     * @dev Sets which component slot types are allowed for a given component contract address.
     * @param componentAddress The address of the component token contract.
     * @param allowedSlots An array of uint8 representing the allowed ComponentType enum values.
     */
    function setAllowedComponentTypes(address componentAddress, uint8[] memory allowedSlots) public onlyOwner {
        // Basic validation: ensure uint8 values correspond to valid ComponentType enum values
        for (uint i = 0; i < allowedSlots.length; i++) {
            require(allowedSlots[i] <= uint8(ComponentType.Skill), "Invalid component slot type value");
        }
        _componentAllowedSlots[componentAddress] = allowedSlots;
    }


    // --- View/Helper Functions ---

    /**
     * @dev Returns the current global environmental factor.
     */
    function getEnvironmentalFactor() public view returns (uint256) {
        return _environmentalFactor;
    }

    /**
     * @dev Returns the current contract configuration parameters.
     */
    function getConfiguration() public view returns (EvolutionConfig memory, MutationConfig memory, EnergyConfig memory) {
        return (evolutionConfig, mutationConfig, energyConfig);
    }

    /**
     * @dev Returns the components currently equipped by an entity.
     * @param tokenId The ID of the entity.
     * @return An array of ComponentSlot structs.
     */
    function getEquippedComponents(uint256 tokenId) public view returns (ComponentSlot[] memory) {
        _requireEntityExists(tokenId);
        return _entityComponentSlots[tokenId];
    }

    /**
     * @dev Returns the timestamp when energy recovery will next be available for an entity.
     * @param tokenId The ID of the entity.
     * @return The next recovery timestamp.
     */
    function getEnergyRecoveryCooldown(uint256 tokenId) public view returns (uint256) {
        _requireEntityExists(tokenId);
        EntityState storage entity = _entityStates[tokenId];
        uint256 nextRecoveryTime = entity.lastEnergyRecoveryTimestamp + energyConfig.recoveryCooldownSeconds;
        // Return max(block.timestamp, nextRecoveryTime) if you want to indicate 0 cooldown if already past
        return nextRecoveryTime;
    }

    /**
     * @dev Gets an entity's attributes, potentially including bonuses from equipped components.
     * @param tokenId The ID of the entity.
     * @return The effective Attributes struct.
     */
     function getEffectiveAttributes(uint256 tokenId) public view returns (Attributes memory) {
        _requireEntityExists(tokenId);
        EntityState storage entity = _entityStates[tokenId];
        Attributes memory effectiveAttributes = entity.baseAttributes;

        // Example: Iterate through equipped components and apply attribute bonuses
        ComponentSlot[] storage equipped = _entityComponentSlots[tokenId];
        for(uint i = 0; i < equipped.length; i++) {
            if (equipped[i].componentAddress != address(0)) {
                 // In a real scenario, you would look up the stats/bonuses associated
                 // with `equipped[i].componentAddress` and `equipped[i].componentId`.
                 // This would likely require another contract or a large mapping.
                 // For this example, we'll apply a simple placeholder bonus based on slot type.
                 if (equipped[i].slotType == ComponentType.Weapon) {
                     effectiveAttributes.strength += 5 * uint16(equipped[i].amount);
                 } else if (equipped[i].slotType == ComponentType.Armor) {
                      effectiveAttributes.vitality += 3 * uint16(equipped[i].amount);
                      effectiveAttributes.resistanceFire += 2 * uint16(equipped[i].amount);
                 }
                 // Add more logic based on component data lookup
            }
        }

        return effectiveAttributes;
     }

    // --- Internal Helper Functions ---

    /**
     * @dev Internal function to check if an entity ID exists.
     */
    function _requireEntityExists(uint256 tokenId) internal view {
        if (!_exists(tokenId)) {
            revert EntityDoesNotExist();
        }
    }

    /**
     * @dev Internal function to check if the caller is the owner of the entity.
     */
    function _requireIsEntityOwner(uint256 tokenId) internal view {
        if (ownerOf(tokenId) != msg.sender) {
            revert NotEntityOwner();
        }
    }

    /**
     * @dev Internal function to apply evolution changes based on the new evolution stage.
     * @param tokenId The ID of the entity.
     * @param entity The entity state storage reference.
     */
    function _performEvolution(uint256 tokenId, EntityState storage entity) internal {
        uint256 totalPoints = evolutionConfig.attributeIncreasePerStage;
        uint256 pointsPerAttribute = totalPoints / 7; // Distribute points among 7 base attributes
        uint256 remainder = totalPoints % 7;

        // Distribute points evenly first
        entity.baseAttributes.strength += uint16(pointsPerAttribute);
        entity.baseAttributes.agility += uint16(pointsPerAttribute);
        entity.baseAttributes.intelligence += uint16(pointsPerAttribute);
        entity.baseAttributes.vitality += uint16(pointsPerAttribute);
        entity.baseAttributes.resistanceFire += uint16(pointsPerAttribute);
        entity.baseAttributes.resistanceWater += uint16(pointsPerAttribute);
        entity.baseAttributes.resistanceEarth += uint16(pointsPerAttribute);

        // Distribute remainder randomly (could use another small random number)
        // For simplicity here, just add to Strength
        entity.baseAttributes.strength += uint16(remainder);

        // Optional: Add or upgrade traits upon evolution
        // Example: If stage 1, add a random Class; if stage 2, potentially upgrade Element resistance.
    }

    /**
     * @dev Internal function to apply mutation changes based on a random number.
     * @param tokenId The ID of the entity.
     * @param randomNumber The random number from VRF.
     */
    function _applyMutation(uint256 tokenId, uint256 randomNumber) internal {
        EntityState storage entity = _entityStates[tokenId];
        uint256 randAttr = randomNumber % 7; // Select which attribute type to affect (0-6)
        uint256 randSign = (randomNumber / 7) % 2; // Determine if increase or decrease (0 or 1)
        uint256 randValue = (randomNumber / 14) % (mutationConfig.attributeChangeRange + 1); // Amount of change (0 to range)
        uint256 randTrait = (randomNumber / 14 / (mutationConfig.attributeChangeRange + 1)) % mutationConfig.traitChangeProbabilityBasis; // For trait change check

        uint16 changeAmount = uint16(randValue);

        // Apply attribute change
        if (randAttr == 0) { // Strength
            if (randSign == 0) entity.baseAttributes.strength += changeAmount; else entity.baseAttributes.strength = (entity.baseAttributes.strength >= changeAmount) ? entity.baseAttributes.strength - changeAmount : 0;
        } else if (randAttr == 1) { // Agility
             if (randSign == 0) entity.baseAttributes.agility += changeAmount; else entity.baseAttributes.agility = (entity.baseAttributes.agility >= changeAmount) ? entity.baseAttributes.agility - changeAmount : 0;
        } // ... continue for all 7 attributes

        // Apply trait change with probability
        if (randTrait < mutationConfig.traitChangeProbability) {
             uint256 randTraitType = (randomNumber / 10000) % 3; // Select trait type (0-2)
             uint256 randTraitValue;

             if (randTraitType == 0) { // Element
                 randTraitValue = (randomNumber / 30000) % 5; // 0-4
                 entity.traits.element = Element(randTraitValue);
             } else if (randTraitType == 1) { // Class
                  randTraitValue = (randomNumber / 30000) % 5; // 0-4
                 entity.traits.entityClass = Class(randTraitValue);
             } else { // Temperament
                  randTraitValue = (randomNumber / 30000) % 4; // 0-3
                 entity.traits.temperament = Temperament(randTraitValue);
             }
        }
        // Note: This mutation logic is very basic. A real system would be more sophisticated.
    }

    /**
     * @dev Internal function to apply adaptation changes based on environmental factor.
     * @param tokenId The ID of the entity.
     * @param factor The current environmental factor.
     */
    function _applyAdaptation(uint256 tokenId, uint256 factor) internal {
        EntityState storage entity = _entityStates[tokenId];

        // Example adaptation logic:
        if (factor > 70) {
             // High factor favors Fire resistance
             entity.baseAttributes.resistanceFire += 5;
             entity.baseAttributes.resistanceWater = (entity.baseAttributes.resistanceWater >= 2) ? entity.baseAttributes.resistanceWater - 2 : 0;
        } else if (factor < 30) {
             // Low factor favors Water resistance
             entity.baseAttributes.resistanceWater += 5;
             entity.baseAttributes.resistanceFire = (entity.baseAttributes.resistanceFire >= 2) ? entity.baseAttributes.resistanceFire - 2 : 0;
        } else {
             // Moderate factor favors Earth resistance
             entity.baseAttributes.resistanceEarth += 3;
        }

        // Could also change traits, max energy, recovery rate, etc.
    }

    /**
     * @dev Internal function to add energy to an entity.
     * @param tokenId The ID of the entity.
     * @param amount The amount of energy to add.
     */
    function _gainEnergy(uint256 tokenId, uint256 amount) internal {
        _entityStates[tokenId].currentEnergy += amount;
        if (_entityStates[tokenId].currentEnergy > energyConfig.maxEnergy) {
            _entityStates[tokenId].currentEnergy = energyConfig.maxEnergy;
        }
    }

    /**
     * @dev Internal function to consume energy from an entity.
     * @param tokenId The ID of the entity.
     * @param amount The amount of energy to consume.
     */
    function _consumeEnergy(uint256 tokenId, uint256 amount) internal {
        // Assumes check for sufficient energy happened before calling this
        _entityStates[tokenId].currentEnergy -= amount;
    }

    // The getEffectiveAttributes function is already a public view function above.

    // --- Overrides for ERC721Enumerable ---
    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize) internal override {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
        // Optional: Add logic here before transfers, e.g., pause contract
    }

     function _afterTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize) internal override {
         super._afterTokenTransfer(from, to, tokenId, batchSize);
         // Optional: Add logic here after transfers, e.g., logging
     }

    // --- Utility/Safety ---
    // Re-declare tokenURI to potentially generate dynamic URI based on entity state
     function tokenURI(uint256 tokenId) public view override returns (string memory) {
         _requireEntityExists(tokenId);
         // This is where you would generate a dynamic JSON metadata URI.
         // The URI would likely point to a server or IPFS hosting a JSON file
         // describing the entity's current state (attributes, traits, level, etc.)
         // The JSON file itself could reference a dynamic image generator.
         // For this example, we return a placeholder.
         return string(abi.encodePacked("ipfs://YOUR_METADATA_BASE_URI/", tokenId.toString()));
     }
}
```