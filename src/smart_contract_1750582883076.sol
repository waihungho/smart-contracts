Okay, let's design an interesting, advanced, and non-standard Solidity smart contract.

How about a contract managing "Adaptive On-Chain Entities" (AOEs)? These aren't just static NFTs. They have dynamic state, can evolve based on interaction and internal parameters, can have modular capabilities added, and can potentially trigger external actions under certain conditions.

**Concept:**

*   **Adaptive Entities:** ERC721 tokens representing unique digital entities.
*   **Dynamic State:** Attributes (like Energy, Reputation, Strength, Intelligence, etc.) that change over time and based on interactions.
*   **Modular Capabilities:** Entities can have "Modules" installed that grant them special abilities or modify their attributes. Modules are also defined within the contract.
*   **Evolution:** Entities can undergo an "evolution" process (possibly triggered periodically or manually at cost) that algorithmically updates their attributes and potentially visual representation based on their current state, modules, and history.
*   **Interactions:** Users can "interact" with entities, influencing their state (e.g., giving energy, boosting reputation).
*   **Autonomous Actions (Limited):** Entities (or rather, the contract acting on behalf of an entity with sufficient state/modules) can trigger pre-approved external smart contract calls.
*   **Dynamic Metadata:** The ERC721 `tokenURI` is generated dynamically, reflecting the entity's current evolving state and installed modules.

This concept blends elements of NFTs, dynamic state, modularity, and limited autonomous behavior, going beyond typical token or DeFi contracts.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol"; // We'll override URI, but useful base
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/Math.sol"; // For randomness/calculations
import "@openzeppelin/contracts/utils/Address.sol"; // For external calls

// --- OUTLINE & FUNCTION SUMMARY ---

// Contract: AdaptiveOnChainEntities
// A non-standard ERC721 contract for dynamic, evolving digital entities with modular capabilities.

// Interfaces:
// - IERC721MetadataRenderer: Interface for an external contract that generates dynamic token metadata.

// Errors:
// - InvalidModuleType: The module type ID is invalid.
// - MaxModulesReached: Cannot install more modules on this entity.
// - NotEnoughEnergy: The entity does not have enough energy for the action.
// - ModuleNotInstalled: The specified module is not installed on this entity.
// - NotCallableContract: The target contract is not registered as callable.
// - ExternalCallFailed: The external call triggered by an entity failed.
// - AlreadyBonded: Entities are already bonded.
// - NotBonded: Entities are not bonded.
// - CannotBondSelf: Cannot bond an entity to itself.
// - NotOwnerOfBoth: Sender must own both entities to bond/unbond.
// - DelegationNotFound: No active delegation found for this entity/delegate pair.

// Events:
// - SentinelMinted(uint256 indexed tokenId, address indexed owner, uint256 initialEnergy)
// - SentinelBurned(uint256 indexed tokenId)
// - SentinelEnergyAccrued(uint256 indexed tokenId, uint256 amount, uint256 newEnergy)
// - SentinelEnergySpent(uint256 indexed tokenId, uint256 amount, uint256 newEnergy)
// - ModuleTypeAdded(uint16 indexed moduleTypeId, uint256 cost, int256 energyEffect, int256 reputationEffect, bytes32 indexed moduleHash)
// - ModuleTypeRemoved(uint16 indexed moduleTypeId)
// - ModuleInstalled(uint256 indexed tokenId, uint16 indexed moduleTypeId, uint8 indexed slot)
// - ModuleUninstalled(uint256 indexed tokenId, uint16 indexed moduleTypeId, uint8 indexed slot)
// - ModuleUpgraded(uint256 indexed tokenId, uint16 indexed moduleTypeId, uint8 indexed slot, uint8 newLevel)
// - SentinelInteracted(uint256 indexed tokenId, address indexed interactor, uint256 energyBoost, uint256 reputationBoost)
// - AdaptiveEvolutionTriggered(uint256 indexed tokenId, uint256 evolutionCount, bytes newAttributesHash)
// - CallableContractRegistered(address indexed contractAddress, bool indexed allowed)
// - ExternalActionExecuted(uint256 indexed tokenId, address indexed targetContract, bytes4 indexed signature, bytes payload)
// - DynamicMetadataRendererUpdated(address indexed newRenderer)
// - SentinelTributeReceived(uint256 indexed tokenId, address indexed payer, uint256 value, uint256 energyBoost, uint256 reputationBoost)
// - SentinelBonded(uint256 indexed token1, uint256 indexed token2)
// - SentinelBondBroken(uint256 indexed token1, uint256 indexed token2)
// - ControlDelegated(uint256 indexed tokenId, address indexed delegate, uint48 expiration)
// - ControlRevoked(uint256 indexed tokenId, address indexed delegate)
// - EvolutionWeightsConfigured(bytes32 indexed weightsHash)

// Structs:
// - Sentinel: Represents an entity's core dynamic state.
// - ModuleType: Defines a type of module and its effects/costs.
// - InstalledModule: Links a Sentinel to a ModuleType instance in a specific slot.
// - Delegation: Tracks temporary control delegation.

// State Variables:
// - _sentinels: Mapping from tokenId to Sentinel struct.
// - _moduleTypes: Mapping from moduleTypeId to ModuleType struct.
// - _installedModules: Mapping from tokenId => slot => InstalledModule struct.
// - _nextSentinelId: Counter for new entities.
// - _nextModuleTypeId: Counter for new module types.
// - _callableContracts: Mapping to track approved external contracts.
// - _metadataRenderer: Address of the dynamic metadata renderer contract.
// - _evolutionWeights: Weights influencing the adaptive evolution calculation.
// - _sentinelBonds: Mapping for bonded pairs (uses sorted token IDs as key).
// - _delegations: Mapping from tokenId => delegate address => Delegation struct.

// Functions (25+ unique functions beyond base ERC721 interface compliance):
// 1. constructor: Initializes the contract. (Part of standard setup)
// 2. supportsInterface: Standard ERC165 check. (Part of standard compliance)
// 3. tokenURI: Overrides ERC721URIStorage to call external renderer for dynamic data. (Custom ERC721)
// 4. mintSentinel: Creates and mints a new Sentinel entity. (Core Entity Mgmt)
// 5. burnSentinel: Burns a Sentinel entity. (Core Entity Mgmt)
// 6. getSentinelState: Retrieves the full dynamic state of a Sentinel. (Core Entity Mgmt)
// 7. updateSentinelAttributes: Allows owner to attempt attribute changes (e.g., via spending energy). (Core Entity Mgmt)
// 8. accrueEnergy: Adds energy to a Sentinel based on time or external trigger. (Dynamic State)
// 9. spendEnergy: Spends energy from a Sentinel for an action. (Dynamic State)
// 10. addModuleType: Owner adds a new definition for a module type. (Modular System)
// 11. removeModuleType: Owner removes a module type definition. (Modular System)
// 12. getModuleType: Retrieves details of a specific module type. (Modular System)
// 13. installModule: Installs a module instance onto a Sentinel. (Modular System)
// 14. upgradeModule: Levels up an installed module instance. (Modular System)
// 15. uninstallModule: Removes an installed module instance. (Modular System)
// 16. getSentinelModules: Lists all modules installed on a Sentinel. (Modular System)
// 17. interactWithSentinel: Allows any user to interact, boosting energy/reputation. (Interaction)
// 18. bondSentinels: Bonds two entities owned by the sender for synergy. (Interaction/Synergy)
// 19. breakBond: Breaks a bond between two entities. (Interaction/Synergy)
// 20. querySynergyEffect: Calculates potential synergy effect for a pair. (Interaction/Synergy)
// 21. triggerAdaptiveEvolution: Initiates the state evolution process for an entity. (Advanced Evolution)
// 22. registerCallableContract: Owner approves/disapproves contracts for entities to call. (Advanced External Interaction)
// 23. executeExternalAction: Allows a Sentinel (via logic/modules/energy) to trigger a call to a registered contract. (Advanced External Interaction)
// 24. setDynamicMetadataRenderer: Owner sets the address for the external metadata renderer contract. (Dynamic Metadata)
// 25. payTribute: Allows anyone to send value, boosting a Sentinel's state. (Interaction/Reputation)
// 26. delegateControl: Owner delegates certain control (non-transfer) over a Sentinel temporarily. (Advanced Delegation)
// 27. revokeDelegateControl: Owner revokes a specific delegation. (Advanced Delegation)
// 28. configureEvolutionWeights: Owner configures the parameters for the evolution algorithm. (Advanced Configuration)

// Standard ERC721/Enumerable/URIStorage functions (implemented for compliance, not counted in the 20+ novel ones):
// - balanceOf(address owner)
// - ownerOf(uint256 tokenId)
// - safeTransferFrom(address from, address to, uint256 tokenId)
// - safeTransferFrom(address from, address to, uint256 tokenId, bytes data)
// - transferFrom(address from, address to, uint256 tokenId)
// - approve(address to, uint256 tokenId)
// - setApprovalForAll(address operator, bool approved)
// - getApproved(uint256 tokenId)
// - isApprovedForAll(address owner, address operator)
// - totalSupply()
// - tokenByIndex(uint256 index)
// - tokenOfOwnerByIndex(address owner, uint256 index)
// - name()
// - symbol()

// Note: This contract focuses on the *logic* and *state management* of dynamic entities.
// The actual visual representation and detailed metadata generation are delegated to an external `IERC721MetadataRenderer` contract for scalability and flexibility, which is a common pattern for dynamic NFTs.
// The 'Adaptive Evolution' and 'Execute External Action' logic are simplified examples; real-world implementation would require more complex algorithms and secure external call patterns.

// --- CONTRACT CODE ---

interface IERC721MetadataRenderer {
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

error InvalidModuleType(uint16 moduleTypeId);
error MaxModulesReached(uint256 tokenId, uint8 maxSlots);
error NotEnoughEnergy(uint256 tokenId, uint256 required, uint256 available);
error ModuleNotInstalled(uint256 tokenId, uint16 moduleTypeId, uint8 slot);
error NotCallableContract(address contractAddress);
error ExternalCallFailed(address target, bytes data);
error AlreadyBonded(uint256 token1, uint256 token2);
error NotBonded(uint256 token1, uint256 token2);
error CannotBondSelf(uint256 tokenId);
error NotOwnerOfBoth(uint256 token1, uint256 token2, address owner);
error DelegationNotFound(uint256 tokenId, address delegate);


contract AdaptiveOnChainEntities is ERC721Enumerable, ERC721URIStorage, Ownable {
    using Counters for Counters.Counter;
    using Address for address;

    struct Sentinel {
        uint256 creationTime;
        uint256 lastEnergyAccrualTime;
        uint256 energy;
        uint256 reputation;
        uint8 coreAttribute1; // e.g., Strength
        uint8 coreAttribute2; // e.g., Intelligence
        uint8 coreAttribute3; // e.g., Agility
        uint256 lastEvolutionTime;
        uint256 evolutionCount;
        bytes32 currentAttributesHash; // Hash of the core attributes for change tracking
    }

    struct ModuleType {
        bool exists; // To check if a type ID is valid
        uint256 cost; // Cost to install (e.g., in wei)
        int256 energyEffect; // Effect on energy accrual/max energy
        int256 reputationEffect; // Effect on reputation gain/loss
        uint8 attributeBoost1; // Boost to attribute 1
        uint8 attributeBoost2; // Boost to attribute 2
        uint8 attributeBoost3; // Boost to attribute 3
        uint8 requiredSentinelLevel; // Minimum evolution count to install
        uint8 maxLevel; // Max upgrade level for this module type
        bytes32 moduleHash; // Identifier for off-chain data (e.g., visual asset)
    }

    struct InstalledModule {
        uint16 moduleTypeId;
        uint8 level;
        uint256 installationTime;
    }

    struct Delegation {
        uint48 expiration; // Unix timestamp
        bool exists;
    }

    mapping(uint256 tokenId => Sentinel) private _sentinels;
    mapping(uint16 moduleTypeId => ModuleType) private _moduleTypes;
    mapping(uint256 tokenId => mapping(uint8 slot => InstalledModule)) private _installedModules;
    mapping(uint256 tokenId => uint8) private _installedModuleCount; // Count per sentinel
    mapping(uint256 tokenId => mapping(uint16 moduleTypeId => uint8 slot)) private _moduleTypeToSlot; // Helper to find slot by type ID
    uint8 public maxModuleSlots = 5; // Max number of modules per sentinel

    Counters.Counter private _nextSentinelId;
    Counters.Counter private _nextModuleTypeId;

    mapping(address => bool) private _callableContracts; // Registry of contracts entities can interact with

    address public _metadataRenderer; // Address of the dynamic metadata renderer

    // Parameters for adaptive evolution algorithm (simplified)
    struct EvolutionWeights {
        uint8 energyInfluence; // How much energy affects attribute change (0-100)
        uint8 reputationInfluence; // How much reputation affects attribute change (0-100)
        uint8 moduleInfluence; // How much installed modules affect attribute change (0-100)
        uint8 randomnessFactor; // How much randomness is introduced (0-100)
    }
    EvolutionWeights public _evolutionWeights;

    // Sentinel Bonding - store the pair sorted to ensure unique key
    // bondId => (token1, token2)
    mapping(uint256 => uint256) private _sentinelBonds; // Maps token1 (lower ID) to token2 (higher ID)
    mapping(uint256 => uint256) private _bondedPairId; // Maps token ID to the token ID it's bonded with (0 if not bonded)
    Counters.Counter private _bondCounter;

    // Delegation Mapping: tokenId => delegate address => delegation details
    mapping(uint256 => mapping(address => Delegation)) private _delegations;


    // --- Events ---
    event SentinelMinted(uint256 indexed tokenId, address indexed owner, uint256 initialEnergy);
    event SentinelBurned(uint256 indexed tokenId);
    event SentinelEnergyAccrued(uint256 indexed tokenId, uint256 amount, uint256 newEnergy);
    event SentinelEnergySpent(uint256 indexed tokenId, uint256 amount, uint256 newEnergy);
    event ModuleTypeAdded(uint16 indexed moduleTypeId, uint256 cost, int256 energyEffect, int256 reputationEffect, bytes32 indexed moduleHash);
    event ModuleTypeRemoved(uint16 indexed moduleTypeId);
    event ModuleInstalled(uint256 indexed tokenId, uint16 indexed moduleTypeId, uint8 indexed slot);
    event ModuleUninstalled(uint256 indexed tokenId, uint16 indexed moduleTypeId, uint8 indexed slot);
    event ModuleUpgraded(uint256 indexed tokenId, uint16 indexed moduleTypeId, uint8 indexed slot, uint8 newLevel);
    event SentinelInteracted(uint256 indexed tokenId, address indexed interactor, uint256 energyBoost, uint256 reputationBoost);
    event AdaptiveEvolutionTriggered(uint256 indexed tokenId, uint256 evolutionCount, bytes newAttributesHash);
    event CallableContractRegistered(address indexed contractAddress, bool indexed allowed);
    event ExternalActionExecuted(uint256 indexed tokenId, address indexed targetContract, bytes4 indexed signature, bytes payload);
    event DynamicMetadataRendererUpdated(address indexed newRenderer);
    event SentinelTributeReceived(uint256 indexed tokenId, address indexed payer, uint256 value, uint256 energyBoost, uint256 reputationBoost);
    event SentinelBonded(uint256 indexed token1, uint256 indexed token2);
    event SentinelBondBroken(uint256 indexed token1, uint256 indexed token2);
    event ControlDelegated(uint256 indexed tokenId, address indexed delegate, uint48 expiration);
    event ControlRevoked(uint256 indexed tokenId, address indexed delegate);
    event EvolutionWeightsConfigured(bytes32 indexed weightsHash);


    // --- Modifiers ---
    modifier onlySentinelOwnerOrDelegate(uint256 tokenId) {
        address tokenOwner = ownerOf(tokenId);
        require(tokenOwner == _msgSender() || _isDelegate(_msgSender(), tokenId), "Not owner or authorized delegate");
        _;
    }

    modifier whenBonded(uint256 token1, uint256 token2) {
        require(_isBonded(token1, token2), "Entities are not bonded");
        _;
    }

    // --- Constructor ---
    constructor(address initialRenderer)
        ERC721("AdaptiveOnChainEntities", "AOE")
        Ownable(msg.sender)
    {
         require(initialRenderer != address(0), "Renderer cannot be zero address");
        _metadataRenderer = initialRenderer;

        // Set some default evolution weights (example)
        _evolutionWeights = EvolutionWeights({
            energyInfluence: 40, // 40% influence
            reputationInfluence: 30, // 30% influence
            moduleInfluence: 20, // 20% influence
            randomnessFactor: 10 // 10% randomness
        });
        emit EvolutionWeightsConfigured(keccak256(abi.encode(_evolutionWeights)));
    }

    // --- ERC721 Overrides ---

    // Note: ERC721URIStorage requires _baseURI and tokenURIs. We override tokenURI
    // to use an external renderer, so _baseURI is not strictly needed for tokenURI.
    // However, keeping ERC721URIStorage might be useful if a fallback is desired.
    // For this example, we rely solely on the renderer.
     function tokenURI(uint256 tokenId) public view override returns (string memory) {
        // ERC721URIStorage check for existence:
        _requireOwned(tokenId); // Reverts if token doesn't exist

        require(_metadataRenderer != address(0), "Metadata renderer not set");

        IERC721MetadataRenderer renderer = IERC721MetadataRenderer(_metadataRenderer);
        return renderer.tokenURI(tokenId);
    }

    // --- Core Entity Management ---

    /**
     * @notice Mints a new Sentinel entity.
     * @param to The address to mint the Sentinel to.
     * @param initialEnergy The starting energy for the new Sentinel.
     * @return The tokenId of the newly minted Sentinel.
     */
    function mintSentinel(address to, uint256 initialEnergy) external onlyOwner returns (uint256) {
        _nextSentinelId.increment();
        uint256 newItemId = _nextSentinelId.current();

        _sentinels[newItemId] = Sentinel({
            creationTime: block.timestamp,
            lastEnergyAccrualTime: block.timestamp,
            energy: initialEnergy,
            reputation: 0,
            coreAttribute1: uint8(Math.ceil(Math.random() * 10)), // Random initial attributes (simplified)
            coreAttribute2: uint8(Math.ceil(Math.random() * 10)),
            coreAttribute3: uint8(Math.ceil(Math.random() * 10)),
            lastEvolutionTime: block.timestamp,
            evolutionCount: 0,
            currentAttributesHash: bytes32(0) // Initial hash
        });
         _sentinels[newItemId].currentAttributesHash = keccak256(abi.encodePacked(
             _sentinels[newItemId].coreAttribute1,
             _sentinels[newItemId].coreAttribute2,
             _sentinels[newItemId].coreAttribute3
         ));


        _mint(to, newItemId);
        emit SentinelMinted(newItemId, to, initialEnergy);
        return newItemId;
    }

    /**
     * @notice Burns a Sentinel entity. Only the owner can burn.
     * @param tokenId The ID of the Sentinel to burn.
     */
    function burnSentinel(uint256 tokenId) external onlyOwner {
        require(_exists(tokenId), "Token does not exist");

        // Clean up installed modules
        uint8 count = _installedModuleCount[tokenId];
        for (uint8 i = 0; i < count; i++) {
             // Need a way to get slot from index if slots aren't sequential/packed
             // Simplified: just iterate potential slots up to maxModuleSlots
             // A more robust system would track active slots
             if (_installedModules[tokenId][i].moduleTypeId != 0) {
                  delete _installedModules[tokenId][i];
             }
        }
        delete _installedModuleCount[tokenId];
        // Note: _moduleTypeToSlot mapping cleanup skipped for simplicity

        // Clean up bonding if bonded
        uint256 bondedToken = _bondedPairId[tokenId];
        if (bondedToken != 0) {
            breakBond(tokenId, bondedToken);
        }

        // Clean up delegations
        delete _delegations[tokenId];

        delete _sentinels[tokenId];
        _burn(tokenId); // Handles transfer implications
        emit SentinelBurned(tokenId);
    }

    /**
     * @notice Retrieves the full dynamic state of a Sentinel.
     * @param tokenId The ID of the Sentinel.
     * @return Sentinel struct containing the entity's state.
     */
    function getSentinelState(uint256 tokenId) public view returns (Sentinel memory) {
        _requireOwned(tokenId); // Check if token exists
        return _sentinels[tokenId];
    }

     /**
     * @notice Allows the owner (or delegate) to attempt an attribute change on a Sentinel by spending energy.
     * @param tokenId The ID of the Sentinel.
     * @param energyToSpend The amount of energy to spend on the attempt.
     * @dev Simplified example: Spends energy and potentially modifies an attribute based on randomness.
     *      Real-world could involve complex logic, dice rolls, module effects.
     */
    function updateSentinelAttributes(uint256 tokenId, uint256 energyToSpend) external onlySentinelOwnerOrDelegate(tokenId) {
        Sentinel storage sentinel = _sentinels[tokenId];
        if (sentinel.energy < energyToSpend) {
             revert NotEnoughEnergy(tokenId, energyToSpend, sentinel.energy);
        }
        sentinel.energy -= energyToSpend;
        emit SentinelEnergySpent(tokenId, energyToSpend, sentinel.energy);

        // Simplified random attribute boost attempt based on energy spent
        bytes32 randomness = keccak256(abi.encodePacked(block.timestamp, tx.origin, block.difficulty, tokenId, energyToSpend, sentinel.evolutionCount));
        uint8 attributeIndex = uint8(uint256(randomness) % 3); // Choose attribute 0, 1, or 2
        uint8 potentialBoost = uint8(uint256(randomness) % (energyToSpend / 100 + 1)); // Max boost increases with energy spent (simplified)

        // Apply boost if successful roll (example: 50% chance + 1% per 100 energy)
        uint8 successChance = 50 + uint8(Math.min(energyToSpend / 100, 50)); // Max 100% chance
        if (uint8(uint256(keccak256(abi.encodePacked(randomness, "boost")))%100) < successChance) {
             if (attributeIndex == 0) sentinel.coreAttribute1 = uint8(Math.min(sentinel.coreAttribute1 + potentialBoost, 255));
             else if (attributeIndex == 1) sentinel.coreAttribute2 = uint8(Math.min(sentinel.coreAttribute2 + potentialBoost, 255));
             else sentinel.coreAttribute3 = uint8(Math.min(sentinel.coreAttribute3 + potentialBoost, 255));

             sentinel.currentAttributesHash = keccak256(abi.encodePacked(
                sentinel.coreAttribute1,
                sentinel.coreAttribute2,
                sentinel.coreAttribute3
            ));
             // No specific event for this small update, EvolutionTriggered is the major state change event.
        }
    }


    /**
     * @notice Accrues energy to a Sentinel based on time elapsed since last accrual.
     * @param tokenId The ID of the Sentinel.
     * @dev Can be called by anyone to "poke" the sentinel and update its energy.
     *      The rate of accrual could be influenced by modules later.
     */
    function accrueEnergy(uint256 tokenId) external {
        Sentinel storage sentinel = _sentinels[tokenId];
        _requireOwned(tokenId); // Check if token exists

        uint256 timeElapsed = block.timestamp - sentinel.lastEnergyAccrualTime;
        if (timeElapsed == 0) return; // No time elapsed

        uint256 energyGained = timeElapsed * 10; // Example: 10 energy per second

        // Module influence on energy gain (simplified)
        uint8 count = _installedModuleCount[tokenId];
        for (uint8 i = 0; i < maxModuleSlots; i++) { // Iterate potential slots
            InstalledModule storage instModule = _installedModules[tokenId][i];
            if (instModule.moduleTypeId != 0) { // Check if slot is active
                 ModuleType storage moduleType = _moduleTypes[instModule.moduleTypeId];
                 if (moduleType.exists && moduleType.energyEffect > 0) { // Only positive effects for accrual
                    // Apply positive module effect (e.g., percentage boost or flat add)
                    // Simplified: add 10% of energyEffect per module level
                    energyGained += (energyGained * uint256(moduleType.energyEffect) / 1000) * instModule.level;
                 }
            }
        }

        sentinel.energy += energyGained;
        sentinel.lastEnergyAccrualTime = block.timestamp;

        emit SentinelEnergyAccrued(tokenId, energyGained, sentinel.energy);
    }

     /**
     * @notice Internal function to spend energy from a Sentinel.
     * @param tokenId The ID of the Sentinel.
     * @param amount The amount of energy to spend.
     */
    function spendEnergy(uint256 tokenId, uint256 amount) internal {
        Sentinel storage sentinel = _sentinels[tokenId];
        if (sentinel.energy < amount) {
             revert NotEnoughEnergy(tokenId, amount, sentinel.energy);
        }
        sentinel.energy -= amount;
        emit SentinelEnergySpent(tokenId, amount, sentinel.energy);
    }

    // --- Modular System ---

    /**
     * @notice Owner adds a new type of module that can be installed.
     * @param cost The cost to install this module (in wei).
     * @param energyEffect How this module affects energy (positive or negative).
     * @param reputationEffect How this module affects reputation (positive or negative).
     * @param attributeBoost1 Boost to coreAttribute1.
     * @param attributeBoost2 Boost to coreAttribute2.
     * @param attributeBoost3 Boost to coreAttribute3.
     * @param requiredSentinelLevel Minimum evolution count required to install.
     * @param maxLevel Max upgrade level for this module type.
     * @param moduleHash Identifier for off-chain data (e.g., IPFS hash for visuals/description).
     * @return The ID of the new module type.
     */
    function addModuleType(
        uint256 cost,
        int256 energyEffect,
        int256 reputationEffect,
        uint8 attributeBoost1,
        uint8 attributeBoost2,
        uint8 attributeBoost3,
        uint8 requiredSentinelLevel,
        uint8 maxLevel,
        bytes32 moduleHash
    ) external onlyOwner returns (uint16) {
        _nextModuleTypeId.increment();
        uint16 newModuleId = uint16(_nextModuleTypeId.current()); // Assumes less than 65536 module types

        _moduleTypes[newModuleId] = ModuleType({
            exists: true,
            cost: cost,
            energyEffect: energyEffect,
            reputationEffect: reputationEffect,
            attributeBoost1: attributeBoost1,
            attributeBoost2: attributeBoost2,
            attributeBoost3: attributeBoost3,
            requiredSentinelLevel: requiredSentinelLevel,
            maxLevel: maxLevel,
            moduleHash: moduleHash
        });

        emit ModuleTypeAdded(
            newModuleId,
            cost,
            energyEffect,
            reputationEffect,
            moduleHash
        );
        return newModuleId;
    }

    /**
     * @notice Owner removes a module type definition. Does not affect already installed modules.
     * @param moduleTypeId The ID of the module type to remove.
     */
    function removeModuleType(uint16 moduleTypeId) external onlyOwner {
        require(_moduleTypes[moduleTypeId].exists, "Module type does not exist");
        delete _moduleTypes[moduleTypeId];
        // Note: This doesn't remove installed modules of this type. They just lose their definition.
        // A more complex system might require uninstalling all instances first.
        emit ModuleTypeRemoved(moduleTypeId);
    }

    /**
     * @notice Retrieves the details of a module type.
     * @param moduleTypeId The ID of the module type.
     * @return ModuleType struct.
     */
    function getModuleType(uint16 moduleTypeId) public view returns (ModuleType memory) {
        require(_moduleTypes[moduleTypeId].exists, "Module type does not exist");
        return _moduleTypes[moduleTypeId];
    }

    /**
     * @notice Installs a module of a specific type onto a Sentinel.
     * @param tokenId The ID of the Sentinel.
     * @param moduleTypeId The ID of the module type to install.
     * @param slot The slot to install the module into (0 to maxModuleSlots-1).
     * @dev Requires payment of the module cost.
     */
    function installModule(uint256 tokenId, uint16 moduleTypeId, uint8 slot) external payable onlySentinelOwnerOrDelegate(tokenId) {
        Sentinel storage sentinel = _sentinels[tokenId];
        ModuleType storage moduleType = _moduleTypes[moduleTypeId];

        require(moduleType.exists, "Invalid module type");
        require(slot < maxModuleSlots, "Invalid module slot");
        require(_installedModules[tokenId][slot].moduleTypeId == 0, "Slot already occupied"); // Slot must be empty
        require(_installedModuleCount[tokenId] < maxModuleSlots, "Max modules reached");
        require(sentinel.evolutionCount >= moduleType.requiredSentinelLevel, "Sentinel level too low");
        require(msg.value >= moduleType.cost, "Insufficient payment");

        // Transfer the installation cost to the contract owner
        (bool success,) = payable(owner()).call{value: msg.value}("");
        require(success, "Payment transfer failed");

        _installedModules[tokenId][slot] = InstalledModule({
            moduleTypeId: moduleTypeId,
            level: 1, // Start at level 1
            installationTime: block.timestamp
        });
        _installedModuleCount[tokenId]++;
        _moduleTypeToSlot[tokenId][moduleTypeId] = slot; // Store slot for quick lookup

        emit ModuleInstalled(tokenId, moduleTypeId, slot);
    }

    /**
     * @notice Upgrades an installed module instance on a Sentinel.
     * @param tokenId The ID of the Sentinel.
     * @param slot The slot of the module to upgrade.
     * @dev Requires energy cost for upgrade. Simplified logic.
     */
    function upgradeModule(uint256 tokenId, uint8 slot) external onlySentinelOwnerOrDelegate(tokenId) {
        InstalledModule storage instModule = _installedModules[tokenId][slot];
        require(instModule.moduleTypeId != 0, "No module installed in this slot");

        ModuleType storage moduleType = _moduleTypes[instModule.moduleTypeId];
        require(moduleType.exists, "Installed module type no longer exists");
        require(instModule.level < moduleType.maxLevel, "Module already at max level");

        // Example energy cost for upgrade (scales with level)
        uint256 upgradeCost = 1000 * instModule.level;
        spendEnergy(tokenId, upgradeCost);

        instModule.level++;

        emit ModuleUpgraded(tokenId, instModule.moduleTypeId, slot, instModule.level);
    }

    /**
     * @notice Uninstalls a module from a Sentinel.
     * @param tokenId The ID of the Sentinel.
     * @param slot The slot of the module to uninstall.
     */
    function uninstallModule(uint256 tokenId, uint8 slot) external onlySentinelOwnerOrDelegate(tokenId) {
         InstalledModule storage instModule = _installedModules[tokenId][slot];
        require(instModule.moduleTypeId != 0, "No module installed in this slot");

        uint16 moduleTypeId = instModule.moduleTypeId;

        delete _installedModules[tokenId][slot];
        _installedModuleCount[tokenId]--;
        delete _moduleTypeToSlot[tokenId][moduleTypeId]; // Remove slot lookup

        emit ModuleUninstalled(tokenId, moduleTypeId, slot);
    }

    /**
     * @notice Gets a list of all modules installed on a Sentinel.
     * @param tokenId The ID of the Sentinel.
     * @return An array of InstalledModule structs.
     */
    function getSentinelModules(uint256 tokenId) public view returns (InstalledModule[] memory) {
        _requireOwned(tokenId); // Check if token exists

        uint8 count = _installedModuleCount[tokenId];
        InstalledModule[] memory installed = new InstalledModule[](count);
        uint8 currentIndex = 0;
        for (uint8 i = 0; i < maxModuleSlots; i++) {
            if (_installedModules[tokenId][i].moduleTypeId != 0) {
                installed[currentIndex] = _installedModules[tokenId][i];
                currentIndex++;
            }
        }
        return installed;
    }

    // --- Interaction ---

    /**
     * @notice Allows any user to interact with a Sentinel, providing small boosts.
     * @param tokenId The ID of the Sentinel.
     * @dev Limited effect, potentially with cooldowns (not implemented here for brevity).
     */
    function interactWithSentinel(uint256 tokenId) external {
        Sentinel storage sentinel = _sentinels[tokenId];
         _requireOwned(tokenId); // Check if token exists

        // Simple interaction effect: small energy and reputation boost
        uint256 energyBoost = 50;
        uint256 reputationBoost = 1;

        sentinel.energy += energyBoost;
        sentinel.reputation += reputationBoost;

        // Optionally update lastEnergyAccrualTime to prevent double accrual right after interaction
        sentinel.lastEnergyAccrualTime = block.timestamp;

        emit SentinelInteracted(tokenId, _msgSender(), energyBoost, reputationBoost);
    }

    /**
     * @notice Allows an owner to pay tribute (send value) to a Sentinel, boosting its state.
     * @param tokenId The ID of the Sentinel receiving the tribute.
     * @dev The sent Ether is converted into energy/reputation boost. The Ether is absorbed by the contract.
     */
    function payTribute(uint256 tokenId) external payable {
        Sentinel storage sentinel = _sentinels[tokenId];
        _requireOwned(tokenId); // Check if token exists
        require(msg.value > 0, "Must send value");

        // Convert value to energy/reputation boost (example conversion rate)
        uint256 energyBoost = msg.value * 100; // 1 wei = 100 energy
        uint256 reputationBoost = msg.value / (1 ether / 100); // 1 ether = 100 reputation

        sentinel.energy += energyBoost;
        sentinel.reputation += reputationBoost;
        sentinel.lastEnergyAccrualTime = block.timestamp; // Update accrual time

        // Ether is absorbed by the contract. Could be directed elsewhere (treasury, burning)
        // For this example, it just increases contract balance.

        emit SentinelTributeReceived(tokenId, _msgSender(), msg.value, energyBoost, reputationBoost);
    }


    // --- Bonding ---

    /**
     * @notice Bonds two Sentinels owned by the sender, enabling synergy effects.
     * @param token1 The ID of the first Sentinel.
     * @param token2 The ID of the second Sentinel.
     */
    function bondSentinels(uint256 token1, uint256 token2) external {
        require(token1 != token2, "Cannot bond a sentinel to itself");
        address owner1 = ownerOf(token1);
        address owner2 = ownerOf(token2);
        require(owner1 == _msgSender() && owner2 == _msgSender(), "Sender must own both sentinels");
        require(!_isBonded(token1, token2), "Sentinels are already bonded");

        // Store bond with sorted IDs
        uint256 lowerId = token1 < token2 ? token1 : token2;
        uint256 higherId = token1 < token2 ? token2 : token1;

        _bondCounter.increment();
        uint256 bondId = _bondCounter.current();

        _sentinelBonds[lowerId] = higherId;
        _bondedPairId[lowerId] = higherId;
        _bondedPairId[higherId] = lowerId;

        emit SentinelBonded(lowerId, higherId);
    }

    /**
     * @notice Breaks a bond between two Sentinels.
     * @param token1 The ID of one Sentinel in the bond.
     * @param token2 The ID of the other Sentinel in the bond.
     */
    function breakBond(uint256 token1, uint256 token2) public {
        require(token1 != token2, "Invalid bond pair");
         address owner1 = ownerOf(token1);
        address owner2 = ownerOf(token2);

        // Check if owner is msg.sender OR if msg.sender is a delegate for *both* tokens
        bool isOwner = (owner1 == _msgSender() && owner2 == _msgSender());
        bool isDelegate = (_isDelegate(_msgSender(), token1) && _isDelegate(_msgSender(), token2));
        require(isOwner || isDelegate, "Not owner or authorized delegate of both");

        uint256 lowerId = token1 < token2 ? token1 : token2;
        uint256 higherId = token1 < token2 ? token2 : token1;

        require(_isBonded(lowerId, higherId), "Sentinels are not bonded");

        // Use the stored bonded pair ID to verify the bond exists and involves these tokens
        require(_bondedPairId[lowerId] == higherId && _bondedPairId[higherId] == lowerId, "Bond mapping mismatch");


        delete _sentinelBonds[lowerId];
        delete _bondedPairId[lowerId];
        delete _bondedPairId[higherId];

        emit SentinelBondBroken(lowerId, higherId);
    }

    /**
     * @notice Checks if two Sentinels are currently bonded.
     * @param token1 The ID of the first Sentinel.
     * @param token2 The ID of the second Sentinel.
     * @return true if they are bonded, false otherwise.
     */
    function _isBonded(uint256 token1, uint256 token2) internal view returns (bool) {
         if (token1 == token2) return false;
         uint256 lowerId = token1 < token2 ? token1 : token2;
         uint256 higherId = token1 < token2 ? token2 : token1;
         return _sentinelBonds[lowerId] == higherId;
    }

    /**
     * @notice Queries the potential synergy effect between two Sentinels if they were bonded.
     * @param token1 The ID of the first Sentinel.
     * @param token2 The ID of the second Sentinel.
     * @return synergyBonus1 Potential bonus for token1.
     * @return synergyBonus2 Potential bonus for token2.
     * @dev Simplified example: Synergy is based on combined core attributes.
     */
    function querySynergyEffect(uint256 token1, uint256 token2) public view returns (uint8 synergyBonus1, uint8 synergyBonus2) {
         _requireOwned(token1);
         _requireOwned(token2);

         Sentinel storage sentinel1 = _sentinels[token1];
         Sentinel storage sentinel2 = _sentinels[token2];

         // Example Synergy calculation: Sum of matching attributes / 10
         uint8 combinedStr = uint8(Math.min(sentinel1.coreAttribute1 + sentinel2.coreAttribute1, 255));
         uint8 combinedInt = uint8(Math.min(sentinel1.coreAttribute2 + sentinel2.coreAttribute2, 255));
         uint8 combinedAgi = uint8(Math.min(sentinel1.coreAttribute3 + sentinel2.coreAttribute3, 255));

         synergyBonus1 = uint8(Math.min((combinedStr + combinedInt + combinedAgi) / 30, 255)); // Example formula
         synergyBonus2 = synergyBonus1; // Symmetric synergy in this example

         // More advanced: Asymmetric synergy based on specific module combinations, or attribute differences.

         return (synergyBonus1, synergyBonus2);
    }

    // --- Advanced Concepts ---

    /**
     * @notice Triggers the adaptive evolution process for a Sentinel.
     * @param tokenId The ID of the Sentinel.
     * @dev This is a core dynamic function. It uses current state, modules, parameters,
     *      and potentially randomness to update the Sentinel's attributes.
     *      Requires spending energy.
     */
    function triggerAdaptiveEvolution(uint256 tokenId) external onlySentinelOwnerOrDelegate(tokenId) {
        Sentinel storage sentinel = _sentinels[tokenId];
         _requireOwned(tokenId); // Check if token exists

        // Example energy cost for evolution
        uint256 evolutionCost = 5000 + (sentinel.evolutionCount * 1000); // Cost increases with evolutions
        spendEnergy(tokenId, evolutionCost);

        // Calculate base attribute changes based on current state (Energy, Reputation)
        int256 strChange = (int256(sentinel.energy) / 10000) + (int256(sentinel.reputation) / 50); // Example formula
        int256 intChange = (int256(sentinel.energy) / 8000) + (int256(sentinel.reputation) / 60);
        int256 agiChange = (int256(sentinel.energy) / 9000) + (int256(sentinel.reputation) / 40);

        // Apply influence from evolution weights
        strChange = (strChange * _evolutionWeights.energyInfluence + (int256(sentinel.reputation) / 50 * _evolutionWeights.reputationInfluence)) / 100;
        intChange = (int256(sentinel.energy) / 8000 * _evolutionWeights.energyInfluence + (int256(sentinel.reputation) / 60 * _evolutionWeights.reputationInfluence)) / 100;
        agiChange = (int256(sentinel.energy) / 9000 * _evolutionWeights.energyInfluence + (int256(sentinel.reputation) / 40 * _evolutionWeights.reputationInfluence)) / 100;


        // Apply influence from installed modules (simplified aggregation)
        uint8 totalModuleAttributeBoost1 = 0;
        uint8 totalModuleAttributeBoost2 = 0;
        uint8 totalModuleAttributeBoost3 = 0;
        uint8 count = _installedModuleCount[tokenId];
         for (uint8 i = 0; i < maxModuleSlots; i++) { // Iterate potential slots
            InstalledModule storage instModule = _installedModules[tokenId][i];
            if (instModule.moduleTypeId != 0) { // Check if slot is active
                 ModuleType storage moduleType = _moduleTypes[instModule.moduleTypeId];
                 if (moduleType.exists) {
                     totalModuleAttributeBoost1 += moduleType.attributeBoost1 * instModule.level;
                     totalModuleAttributeBoost2 += moduleType.attributeBoost2 * instModule.level;
                     totalModuleAttributeBoost3 += moduleType.attributeBoost3 * instModule.level;
                 }
            }
        }
         strChange += (int256(totalModuleAttributeBoost1) * _evolutionWeights.moduleInfluence) / 100;
         intChange += (int256(totalModuleAttributeBoost2) * _evolutionWeights.moduleInfluence) / 100;
         agiChange += (int256(totalModuleAttribute3) * _evolutionWeights.moduleInfluence) / 100;


        // Add randomness (influenced by randomness factor)
         bytes32 randomness = keccak256(abi.encodePacked(block.timestamp, tx.origin, block.difficulty, tokenId, sentinel.evolutionCount, block.number));
         int256 randomStr = int256(uint256(keccak256(abi.encodePacked(randomness, "str"))) % 100) - 50; // Random value between -50 and 49
         int256 randomInt = int256(uint256(keccak256(abi.encodePacked(randomness, "int"))) % 100) - 50;
         int256 randomAgi = int256(uint256(keccak256(abi.encodePacked(randomness, "agi"))) % 100) - 50;

         strChange += (randomStr * _evolutionWeights.randomnessFactor) / 100;
         intChange += (randomInt * _evolutionWeights.randomnessFactor) / 100;
         agiChange += (randomAgi * _evolutionWeights.randomnessFactor) / 100;


        // Apply changes, ensuring attributes stay within bounds (e.g., 0-255)
        int256 currentStr = int256(sentinel.coreAttribute1);
        int256 currentInt = int256(sentinel.coreAttribute2);
        int256 currentAgi = int256(sentinel.coreAttribute3);

        sentinel.coreAttribute1 = uint8(Math.max(0, Math.min(currentStr + strChange, 255)));
        sentinel.coreAttribute2 = uint8(Math.max(0, Math.min(currentInt + intChange, 255)));
        sentinel.coreAttribute3 = uint8(Math.max(0, Math.min(currentAgi + agiChange, 255)));

        // Update state
        sentinel.evolutionCount++;
        sentinel.lastEvolutionTime = block.timestamp;
        sentinel.currentAttributesHash = keccak256(abi.encodePacked(
             sentinel.coreAttribute1,
             sentinel.coreAttribute2,
             sentinel.coreAttribute3
         ));


        emit AdaptiveEvolutionTriggered(tokenId, sentinel.evolutionCount, sentinel.currentAttributesHash);

        // Note: The metadata renderer should pick up these changes via `tokenURI`
    }

     /**
     * @notice Configures the weights used in the adaptive evolution algorithm.
     * @param energyInfluence Weight for energy (0-100).
     * @param reputationInfluence Weight for reputation (0-100).
     * @param moduleInfluence Weight for installed modules (0-100).
     * @param randomnessFactor Weight for randomness (0-100).
     * @dev Sum of weights is not strictly required to be 100, but influences overall change magnitude.
     */
     function configureEvolutionWeights(
         uint8 energyInfluence,
         uint8 reputationInfluence,
         uint8 moduleInfluence,
         uint8 randomnessFactor
     ) external onlyOwner {
         _evolutionWeights = EvolutionWeights({
             energyInfluence: energyInfluence,
             reputationInfluence: reputationInfluence,
             moduleInfluence: moduleInfluence,
             randomnessFactor: randomnessFactor
         });
         emit EvolutionWeightsConfigured(keccak256(abi.encode(_evolutionWeights)));
     }


    /**
     * @notice Owner registers or unregisters an external contract address as callable by entities.
     * @param contractAddress The address of the contract to register/unregister.
     * @param allowed Whether to allow or disallow calls to this address.
     */
    function registerCallableContract(address contractAddress, bool allowed) external onlyOwner {
        _callableContracts[contractAddress] = allowed;
        emit CallableContractRegistered(contractAddress, allowed);
    }

    /**
     * @notice Allows a Sentinel (via its owner/delegate and sufficient energy/modules) to trigger a call to a registered external contract.
     * @param tokenId The ID of the Sentinel triggering the action.
     * @param targetContract The address of the registered contract to call.
     * @param data The data payload for the call (function signature and arguments).
     * @dev This is a simplified example. Real-world usage needs careful module/energy gating.
     *      A module type could grant permission for specific signatures or contracts.
     */
    function executeExternalAction(uint256 tokenId, address targetContract, bytes memory data) external onlySentinelOwnerOrDelegate(tokenId) {
        Sentinel storage sentinel = _sentinels[tokenId];
        _requireOwned(tokenId); // Check if token exists
        require(_callableContracts[targetContract], "Target contract is not registered");

        // Example requirement: Entity needs certain energy or a specific module to call
        // Simplified: Require minimum energy for *any* external call
        uint256 callCost = 2000; // Example energy cost per external call
        spendEnergy(tokenId, callCost);

        // Example module gate: Check if Sentinel has *any* module that allows external calls (requires module definition update)
        // For now, assume any module allows it or remove this check if not needed.
        // require(_installedModuleCount[tokenId] > 0, "Sentinel needs at least one module to perform external actions");

        // Perform the external call
        (bool success, ) = targetContract.call(data);
        if (!success) {
            // Emit error but don't necessarily revert, depending on desired behavior
            // Reverting is safer for atomic actions.
            revert ExternalCallFailed(targetContract, data);
        }

        emit ExternalActionExecuted(tokenId, targetContract, bytes4(data), data);
    }

    /**
     * @notice Owner sets the address of the external contract responsible for generating dynamic token metadata.
     * @param rendererAddress The address of the IERC721MetadataRenderer contract.
     */
    function setDynamicMetadataRenderer(address rendererAddress) external onlyOwner {
         require(rendererAddress != address(0), "Renderer cannot be zero address");
        _metadataRenderer = rendererAddress;
        emit DynamicMetadataRendererUpdated(rendererAddress);
    }

    /**
     * @notice Allows the owner to delegate control (non-transfer) over a Sentinel to another address temporarily.
     * @param tokenId The ID of the Sentinel.
     * @param delegate The address to delegate control to.
     * @param expiration The Unix timestamp when the delegation expires.
     * @dev Delegate can perform actions like install modules, trigger evolution, execute external actions etc.
     */
    function delegateControl(uint256 tokenId, address delegate, uint48 expiration) external onlyOwner {
         _requireOwned(tokenId); // Check if token exists
         require(delegate != address(0), "Delegate cannot be zero address");
         require(delegate != ownerOf(tokenId), "Cannot delegate control to owner");
         require(expiration > block.timestamp, "Expiration must be in the future");

         _delegations[tokenId][delegate] = Delegation({
             expiration: expiration,
             exists: true
         });

         emit ControlDelegated(tokenId, delegate, expiration);
    }

    /**
     * @notice Allows the owner to revoke an active delegation.
     * @param tokenId The ID of the Sentinel.
     * @param delegate The address of the delegate to revoke.
     */
    function revokeDelegateControl(uint256 tokenId, address delegate) external onlyOwner {
         _requireOwned(tokenId); // Check if token exists
         require(_delegations[tokenId][delegate].exists && _delegations[tokenId][delegate].expiration > block.timestamp, "Delegation is not active or does not exist");

         delete _delegations[tokenId][delegate];

         emit ControlRevoked(tokenId, delegate);
    }

     /**
     * @notice Internal helper to check if an address is a valid delegate for a Sentinel.
     * @param potentialDelegate The address to check.
     * @param tokenId The ID of the Sentinel.
     * @return true if the address is an active delegate, false otherwise.
     */
    function _isDelegate(address potentialDelegate, uint256 tokenId) internal view returns (bool) {
        Delegation storage delegation = _delegations[tokenId][potentialDelegate];
        return delegation.exists && delegation.expiration > block.timestamp;
    }

    /**
     * @notice Queries potential attribute boosts an entity could gain from available energy/modules.
     * @param tokenId The ID of the Sentinel.
     * @return potentialStrBoost
     * @return potentialIntBoost
     * @return potentialAgiBoost
     * @dev This is a hypothetical query simulating potential outcomes, not deterministic.
     */
    function getPotentialAttributeBoosts(uint256 tokenId) public view returns (uint8 potentialStrBoost, uint8 potentialIntBoost, uint8 potentialAgiBoost) {
        _requireOwned(tokenId); // Check if token exists
        Sentinel storage sentinel = _sentinels[tokenId];

        // Simplified potential calculation based on current energy and module effects
        // This is a *simulation* and doesn't guarantee actual outcome of evolution
        uint256 energyPotential = sentinel.energy / 5000; // How many 'units' of potential from energy
        uint256 reputationPotential = sentinel.reputation / 100; // How many 'units' from reputation

        uint8 totalModuleAttributeBoost1 = 0;
        uint8 totalModuleAttributeBoost2 = 0;
        uint8 totalModuleAttributeBoost3 = 0;
        uint8 count = _installedModuleCount[tokenId];
        for (uint8 i = 0; i < maxModuleSlots; i++) {
            InstalledModule storage instModule = _installedModules[tokenId][i];
            if (instModule.moduleTypeId != 0) {
                 ModuleType storage moduleType = _moduleTypes[instModule.moduleTypeId];
                 if (moduleType.exists) {
                     totalModuleAttributeBoost1 += moduleType.attributeBoost1 * instModule.level;
                     totalModuleAttribute2 += moduleType.attributeBoost2 * instModule.level;
                     totalModuleAttribute3 += moduleType.attributeBoost3 * instModule.level;
                 }
            }
        }

        potentialStrBoost = uint8(Math.min(energyPotential + reputationPotential + totalModuleAttributeBoost1, 255)); // Example calculation
        potentialIntBoost = uint8(Math.min(energyPotential + reputationPotential + totalModuleAttributeBoost2, 255));
        potentialAgiBoost = uint8(Math.min(energyPotential + reputationPotential + totalModuleAttribute3, 255));

        // Note: This function does not use the evolution weights or randomness from `triggerAdaptiveEvolution`.
        // It's a separate projection based on current resources/modules.

        return (potentialStrBoost, potentialIntBoost, potentialAgiBoost);
    }

    // --- Internal / Helper Functions ---

    // Override ERC721Enumerable's _beforeTokenTransfer to update bonded status
    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);

        // Break bond if the token being transferred is part of a bond
        uint256 bondedToken = _bondedPairId[tokenId];
        if (bondedToken != 0) {
            // Break bond automatically on transfer. This prevents bonds across owners.
            // Need to make sure the call to breakBond here doesn't require msg.sender to be owner,
            // or adjust the breakBond function logic for this specific scenario.
            // Simplest: The bond is just broken implicitly and state cleared.
             uint256 lowerId = tokenId < bondedToken ? tokenId : bondedToken;
             uint256 higherId = tokenId < bondedToken ? bondedToken : tokenId;
             if (_sentinelBonds[lowerId] == higherId) { // Double check it's a valid current bond
                delete _sentinelBonds[lowerId];
                delete _bondedPairId[lowerId];
                delete _bondedPairId[higherId];
                // Event might not be ideal in _beforeTokenTransfer, but for clarity:
                 emit SentinelBondBroken(lowerId, higherId);
             }
        }

         // Clear any active delegations for the token being transferred
        delete _delegations[tokenId];
    }

    // Provide empty implementations for URIStorage overrides as we use external renderer
    function _baseURI() internal view override(ERC721, ERC721URIStorage) returns (string memory) {
        return ""; // Not used with external renderer
    }

    // Need to override _burn to make sure ERC721URIStorage state is handled if used later
    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
         super._burn(tokenId);
         // Clean up URI storage explicitly if using ERC721URIStorage's internal mapping
         // delete _tokenURIs[tokenId]; // If using internal mapping
    }

     // Required for ERC721Enumerable
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable, ERC721URIStorage)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
```

**Explanation of Concepts and Functions:**

1.  **Dynamic State (`Sentinel` struct):**
    *   `creationTime`, `lastEnergyAccrualTime`, `energy`, `reputation`: Core state variables that change based on time and interactions.
    *   `coreAttributeX`: Example attributes that represent inherent qualities and are modified by evolution.
    *   `lastEvolutionTime`, `evolutionCount`: Track the entity's lifecycle stage.
    *   `currentAttributesHash`: A hash of the attributes, useful for easily checking if the core attributes have changed (for metadata updates, etc.).

2.  **Modular Capabilities (`ModuleType`, `InstalledModule` structs, mappings):**
    *   `ModuleType`: Defines the *blueprint* of a module (cost, effects, required level, max level). Added and managed by the owner.
    *   `InstalledModule`: Represents an instance of a module *on* a specific Sentinel in a particular `slot`. Has its own `level`.
    *   `addModuleType`, `removeModuleType`, `getModuleType`: Owner functions to manage module blueprints.
    *   `installModule`, `upgradeModule`, `uninstallModule`: Functions for the Sentinel owner (or delegate) to manage modules on their entities. Installation costs Ether, upgrade costs energy.
    *   `getSentinelModules`: Retrieves all modules currently installed on an entity.
    *   `maxModuleSlots`: Limits the number of modules per entity, adding a strategic layer.

3.  **Evolution (`triggerAdaptiveEvolution`, `configureEvolutionWeights`):**
    *   `triggerAdaptiveEvolution`: The core "advanced" function. Takes energy and uses the entity's current state (`energy`, `reputation`), installed modules, configurable `_evolutionWeights`, and block-dependent randomness to algorithmically adjust the core attributes. This is deterministic on-chain but incorporates varied influences.
    *   `configureEvolutionWeights`: Allows the contract owner to tune the parameters of the evolution algorithm, influencing which factors (energy, reputation, modules, randomness) have the most impact. This adds a dynamic governance-like aspect to the system's rules.

4.  **Interaction (`interactWithSentinel`, `payTribute`):**
    *   `interactWithSentinel`: A low-cost function for anyone to give small boosts to an entity. Encourages social interaction.
    *   `payTribute`: Allows users to send value (Ether) to the contract, which is converted into significant energy/reputation boosts for a specific Sentinel. The Ether remains in the contract (could be a treasury, or burned).

5.  **Autonomous Actions (`registerCallableContract`, `executeExternalAction`):**
    *   `registerCallableContract`: Owner defines a list of trusted external contracts that the entities *can* interact with. This is crucial for security.
    *   `executeExternalAction`: Allows a Sentinel (specifically, its owner/delegate) to trigger a call to one of the registered contracts. This function would require energy and potentially specific installed modules as a gate, making the *entity's state and capabilities* determine its ability to interact with the wider DeFi/NFT ecosystem. (Simplified security gate included).

6.  **Bonding (`bondSentinels`, `breakBond`, `querySynergyEffect`):**
    *   `bondSentinels`: Allows an owner to link two of their Sentinels together.
    *   `breakBond`: Breaks the link. Handled automatically on transfer.
    *   `querySynergyEffect`: A view function to calculate a potential bonus (e.g., attribute boost, energy efficiency) that the bonded entities might receive if they were interacting or performing actions together (the *application* of this synergy would happen in other functions like `triggerAdaptiveEvolution` or `executeExternalAction` if designed).

7.  **Delegation (`delegateControl`, `revokeDelegateControl`, `_isDelegate`):**
    *   Allows an owner to grant temporary control (for specific actions like module management, evolution, external actions, *but not transfer or burning*) to another address. Useful for gaming guilds, managers, or automated bots acting on behalf of the owner.

8.  **Dynamic Metadata (`setDynamicMetadataRenderer`, `tokenURI`, `IERC721MetadataRenderer` interface):**
    *   Instead of storing a static URI, `tokenURI` calls out to a separate, registered `IERC721MetadataRenderer` contract. This external contract is responsible for fetching the Sentinel's *current state* from *this* contract and generating the JSON metadata on the fly, including attributes, installed modules, etc. This is essential for truly dynamic NFTs where the visual or data representation changes.

9.  **ERC721 Compliance:** Inherits from OpenZeppelin's standard ERC721, ERC721Enumerable (for listing tokens), and ERC721URIStorage (overridden). Includes necessary overrides and helper functions (`_beforeTokenTransfer`, `supportsInterface`) to maintain standard compatibility while adding custom logic.

This contract provides a framework for dynamic, stateful NFTs with evolving attributes, custom capabilities via modules, inter-entity relationships (bonding), limited autonomous interaction with external contracts, and delegated control, all linked to dynamic metadata. It avoids duplicating standard ERC20/721/1155 or common DeFi mechanisms directly.