Okay, here is a Solidity smart contract designed around an "Algorithmic Environment & Entity System". It simulates a simple on-chain world where digital entities (represented as NFTs) interact with a shared environment and each other based on deterministic rules. The rules themselves can 'adapt' based on aggregated interaction data, giving a primitive sense of an evolving system.

This concept is advanced because it combines dynamic NFT attributes, a shared global state, complex rule-based interactions, and a state-dependent rule adaptation mechanism, all managed deterministically on-chain without relying on external oracles for the core simulation loop. It's creative as it simulates an artificial life/agent system on-chain. It's trendy in its use of NFTs and the idea of complex, evolving on-chain systems.

It avoids duplicating standard open-source patterns like basic tokens, simple DeFi vaults, standard marketplaces, or basic DAO structures. It inherits standard interfaces (like ERC721) and uses standard utilities (like Ownable) for best practice, but the core simulation and adaptation logic is custom.

**Disclaimer:** This is a complex experimental concept. On-chain deterministic simulation has limitations (gas costs, complexity of rules, true randomness impossible). This contract provides a *framework* and *simulated* adaptation, not a full AI or complex game engine. It is provided for educational and illustrative purposes and is *not* audited or production-ready.

---

## Smart Contract Outline & Function Summary

**Contract Name:** AlgorithmicEntitySystem

**Core Concept:** A deterministic on-chain simulation system managing digital entities (NFTs) within a shared environment. Entities have dynamic attributes and interact based on rules that can adapt based on aggregate interaction history.

**Key Features:**
*   **Dynamic Entities:** NFTs with mutable attributes (`energy`, `complexityPoints`, `affinity`, `explorationSkill`, `interactionSkill`).
*   **Environment State:** Global parameters affecting entity interactions.
*   **Rule-Based Actions:** Users trigger actions (`explore`, `interact`, `rest`, `specialize`, `attemptComplexityIncrease`) for their entities, consuming energy and modifying attributes based on rules.
*   **Deterministic Rules:** Interaction outcomes are determined by entity attributes, environment state, and rule parameters.
*   **Rule Adaptation:** Authorized users can trigger a process that adjusts rule parameters based on collected aggregate interaction data. This simulates an evolving system.
*   **Complexity Levels:** Entities can attempt to increase their complexity level, potentially unlocking new behaviors or improving outcomes.
*   **Standard ERC721 Compliance:** Basic ownership and transfer functionality for entities.
*   **Role-Based Access:** Owner and authorized adaptors roles.

**Structs:**
*   `Entity`: Basic entity info (ID, owner, creation block, complexity level).
*   `EntityAttributes`: Dynamic attributes of an entity.
*   `EnvironmentState`: Global simulation parameters.
*   `RuleParameters`: Parameters governing entity action outcomes.
*   `InteractionData`: Aggregated data used for rule adaptation.

**State Variables:**
*   Standard ERC721 mappings (`_owners`, `_balances`, `_tokenApprovals`, `_operatorApprovals`).
*   `_entityCounter`: Counter for new entities.
*   `_entities`: Mapping from ID to `Entity` struct.
*   `_entityAttributes`: Mapping from ID to `EntityAttributes` struct.
*   `_environmentState`: Current `EnvironmentState`.
*   `_ruleParameters`: Current `RuleParameters`.
*   `_interactionData`: Aggregate `InteractionData` for adaptation.
*   `_lastAdaptationBlock`: Block number of the last adaptation.
*   `_authorisedAdaptors`: Set of addresses allowed to trigger adaptation.
*   `_complexityThresholds`: Mapping for complexity level point requirements.
*   `_ERC721_RECEIVED`: Interface ID for ERC721Receiver.

**Events:**
*   `EntityCreated`: When a new entity is minted.
*   `AttributesChanged`: When an entity's attributes are modified.
*   `EnvironmentShift`: When global environment parameters change.
*   `ActionPerformed`: When an entity performs an action.
*   `ComplexityLevelIncreased`: When an entity gains a complexity level.
*   `RuleParametersAdapted`: When rule parameters are adjusted.
*   `AuthorisedAdaptorAdded`/`Removed`.

**Function Summary (Minimum 20 Functions):**

**ERC721 Standard Functions (9):**
1.  `balanceOf(address owner)`: Returns the number of tokens owned by `owner`. (view)
2.  `ownerOf(uint256 tokenId)`: Returns the owner of the `tokenId`. (view)
3.  `approve(address to, uint256 tokenId)`: Approves `to` to transfer `tokenId`.
4.  `getApproved(uint256 tokenId)`: Returns the approved address for `tokenId`. (view)
5.  `setApprovalForAll(address operator, bool approved)`: Sets approval for `operator` for all owner's tokens.
6.  `isApprovedForAll(address owner, address operator)`: Checks if `operator` is approved for `owner`. (view)
7.  `transferFrom(address from, address to, uint256 tokenId)`: Transfers `tokenId` from `from` to `to`.
8.  `safeTransferFrom(address from, address to, uint256 tokenId)`: Transfers `tokenId` safely, checks recipient.
9.  `safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)`: Safe transfer with data.

**Entity Management & Info Functions (5):**
10. `mintInitialEntity(address owner)`: Mints a new entity to `owner` with initial attributes. (onlyOwner)
11. `getEntityInfo(uint256 entityId)`: Returns basic `Entity` struct info. (view)
12. `getEntityAttributes(uint256 entityId)`: Returns current `EntityAttributes`. (view)
13. `getEntityComplexityLevel(uint256 entityId)`: Returns the current complexity level. (view)
14. `getEntityComplexityPoints(uint256 entityId)`: Returns the current complexity points. (view)

**Environment Interaction & Info Functions (2):**
15. `getEnvironmentState()`: Returns the current `EnvironmentState`. (view)
16. `triggerEnvironmentEvent(uint128 globalEnergyShift, int128 globalAffinityShiftDelta)`: Modifies global environment parameters. (onlyOwner)

**Entity Action Functions (5):**
17. `performActionExplore(uint256 entityId)`: Triggers exploration action for an entity. (requires owner/approved, consumes energy, affects attributes based on rules/environment).
18. `performActionInteract(uint256 entityId, uint256 targetEntityId)`: Triggers interaction between two entities. (requires owner/approved for `entityId`, consumes energy, affects attributes of *both* based on rules/affinity).
19. `performActionRest(uint256 entityId)`: Triggers resting action for an entity. (requires owner/approved, gains energy, potentially affects complexity).
20. `performActionSpecialize(uint256 entityId, uint8 attributeIndex)`: Increases one attribute at cost of others/complexity. (requires owner/approved, consumes energy/complexity, affects attributes). AttributeIndex 0=exploration, 1=interaction.
21. `attemptComplexityIncrease(uint256 entityId)`: Attempts to increase entity's complexity level. (requires owner/approved, consumes complexity points/energy if successful).

**Rule Adaptation & Management Functions (4):**
22. `getRuleParameters()`: Returns the current `RuleParameters`. (view)
23. `triggerRuleAdaptation()`: Initiates the rule adaptation process based on `_interactionData`. (onlyAuthorisedAdaptor, clears `_interactionData` afterwards).
24. `addAuthorisedAdaptor(address adaptor)`: Adds an address to the authorised adaptors list. (onlyOwner)
25. `removeAuthorisedAdaptor(address adaptor)`: Removes an address from the authorised adaptors list. (onlyOwner)

**Admin & Utility Functions (3):**
26. `setComplexityThresholds(uint8[] calldata levels, uint128[] calldata pointsRequired)`: Sets the points needed for each complexity level. (onlyOwner)
27. `setInitialEntityAttributes(uint128 initialEnergy, uint128 initialComplexityPoints, int128 initialAffinity, uint128 initialExplorationSkill, uint128 initialInteractionSkill)`: Sets default attributes for new entities. (onlyOwner)
28. `setRuleParameters(...)`: Sets the parameters used in rule calculations. (onlyOwner)
    *   *(Self-correction: This would be one function with many parameters, let's count it as one but acknowledge its complexity)*

**Total Functions:** 9 (ERC721) + 5 (Entity Info) + 2 (Environment) + 5 (Actions) + 4 (Adaptation) + 3 (Admin) = **28 Functions**. This meets the minimum of 20.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

// --- Smart Contract Outline & Function Summary ---
// (See detailed summary above the code block)
// Contract: AlgorithmicEntitySystem
// Core Concept: Deterministic on-chain simulation of dynamic entities interacting within an evolving environment.
// Features: Dynamic Entity NFTs, Global Environment State, Rule-Based Actions, Deterministic Rules, Rule Adaptation based on aggregate data, Complexity Levels, ERC721 Compliance, Role-Based Access.
// Structs: Entity, EntityAttributes, EnvironmentState, RuleParameters, InteractionData.
// State Variables: Standard ERC721, _entityCounter, _entities, _entityAttributes, _environmentState, _ruleParameters, _interactionData, _lastAdaptationBlock, _authorisedAdaptors, _complexityThresholds.
// Events: EntityCreated, AttributesChanged, EnvironmentShift, ActionPerformed, ComplexityLevelIncreased, RuleParametersAdapted, AuthorisedAdaptorAdded/Removed.
// Functions: 28+ (ERC721 Standard: 9, Entity Info: 5, Environment: 2, Actions: 5, Adaptation: 4, Admin/Utility: 3).

contract AlgorithmicEntitySystem is ERC721, Ownable {
    using Counters for Counters.Counter;
    using Strings for uint256;
    using Math for uint256; // Using Math for min/max

    // --- Errors ---
    error EntityNotFound(uint256 entityId);
    error NotOwnerOrApproved(uint256 entityId);
    error InsufficientEnergy(uint256 entityId, uint128 required, uint128 current);
    error InvalidAttributeIndex(uint8 index);
    error ComplexityLevelNotReached(uint256 entityId, uint8 requiredLevel, uint8 currentLevel);
    error InsufficientComplexityPoints(uint256 entityId, uint128 required, uint128 current);
    error AdaptationTooFrequent(uint64 lastAdaptationBlock, uint64 currentBlock, uint64 cooldown);
    error NotAuthorisedAdaptor();
    error InvalidComplexityThresholds();
    error InvalidActionParameters();

    // --- Structs ---
    struct Entity {
        uint256 id;
        address owner;
        uint64 creationBlock;
        uint8 complexityLevel; // Starts at 0
    }

    struct EntityAttributes {
        uint128 energy; // Resource consumed by actions
        uint128 complexityPoints; // Points towards increasing complexityLevel
        int128 affinity; // Affects interaction outcomes (can be positive or negative)
        uint128 explorationSkill; // Improves exploration outcomes
        uint128 interactionSkill; // Improves interaction outcomes
    }

    struct EnvironmentState {
        uint128 globalEnergy; // Affects energy costs/gains
        uint128 globalComplexityFactor; // Affects complexity point gains/losses
        int128 globalAffinityShift; // Shifts baseline affinity
        uint64 lastEnvironmentalShiftBlock; // Block of last env change
    }

    struct RuleParameters {
        // Energy Costs & Gains
        uint128 exploreEnergyCost;
        uint128 interactEnergyCost;
        uint128 restEnergyGain;
        uint128 specializationEnergyCost;
        uint128 complexityAttemptEnergyCost;

        // Base Outcomes
        uint128 exploreBaseOutcome; // Base complexity points/skill gain from exploring
        int128 interactBaseOutcome; // Base affinity/skill change from interacting

        // Factors
        uint128 affinityImpactFactor; // How much affinity affects interaction outcome
        uint128 complexityGainFactor; // How much complexity points are gained per action
        uint128 complexityLossFactor; // How much complexity points are lost from certain actions
        uint128 restComplexityLoss; // Complexity points lost when resting
        uint128 specializationComplexityCost; // Complexity points lost when specializing
        uint128 complexityAttemptPointsCost; // Complexity points needed to attempt level up

        // Thresholds & Cooldowns
        uint64 ruleAdaptationCooldown; // Blocks between rule adaptations
    }

    struct InteractionData {
        // Aggregate data for adaptation
        uint256 successfulExplores; // Exploration resulted in net positive gain
        uint256 failedExplores; // Exploration resulted in net negative gain (or significant cost)
        uint256 successfulInteracts; // Interaction resulted in net positive affinity/skill change for initiator
        uint256 failedInteracts; // Interaction resulted in net negative affinity/skill change for initiator
        int256 totalAffinityChange; // Sum of all affinity changes from interactions
    }

    // --- State Variables ---
    Counters.Counter private _entityCounter;

    mapping(uint256 => Entity) private _entities;
    mapping(uint256 => EntityAttributes) private _entityAttributes;

    EnvironmentState public _environmentState;
    RuleParameters public _ruleParameters;
    InteractionData public _interactionData;

    uint64 public _lastAdaptationBlock;

    // Use a mapping for authorized adaptors
    mapping(address => bool) private _authorisedAdaptors;

    // Complexity level thresholds (level => points required to reach that level)
    mapping(uint8 => uint128) public _complexityThresholds;

    // ERC721 standard interface ID
    bytes4 private constant _ERC721_RECEIVED = 0x150b7a02;

    // --- Events ---
    event EntityCreated(uint256 indexed entityId, address indexed owner, uint64 creationBlock);
    event AttributesChanged(uint256 indexed entityId, uint128 energy, uint128 complexityPoints, int128 affinity, uint128 explorationSkill, uint128 interactionSkill);
    event EnvironmentShift(uint128 globalEnergy, uint128 globalComplexityFactor, int128 globalAffinityShift);
    event ActionPerformed(uint256 indexed entityId, string actionType, bool success, int256 outcomeValue); // outcomeValue is action-specific
    event ComplexityLevelIncreased(uint256 indexed entityId, uint8 newComplexityLevel);
    event RuleParametersAdapted(uint64 adaptationBlock);
    event AuthorisedAdaptorAdded(address indexed adaptor);
    event AuthorisedAdaptorRemoved(address indexed adaptor);

    // --- Modifiers ---
    modifier onlyAuthorisedAdaptor() {
        if (msg.sender != owner() && !_authorisedAdaptors[msg.sender]) {
            revert NotAuthorisedAdaptor();
        }
        _;
    }

    modifier onlyEntityOwnerOrApproved(uint256 entityId) {
        if (ownerOf(entityId) != msg.sender && !isApprovedForAll(ownerOf(entityId), msg.sender) && getApproved(entityId) != msg.sender) {
            revert NotOwnerOrApproved(entityId);
        }
        _;
    }

    // --- Constructor ---
    constructor(
        string memory name,
        string memory symbol,
        uint128 initialEnergy,
        uint128 initialComplexityPoints,
        int128 initialAffinity,
        uint128 initialExplorationSkill,
        uint128 initialInteractionSkill,
        RuleParameters memory initialRuleParams,
        EnvironmentState memory initialEnvState,
        uint8[] memory complexityLevels,
        uint128[] memory pointsRequired
    ) ERC721(name, symbol) Ownable(msg.sender) {
        _setInitialEntityAttributes(initialEnergy, initialComplexityPoints, initialAffinity, initialExplorationSkill, initialInteractionSkill);
        _ruleParameters = initialRuleParams;
        _environmentState = initialEnvState;
        _environmentState.lastEnvironmentalShiftBlock = block.number; // Initialize env shift block
        _lastAdaptationBlock = block.number; // Initialize last adaptation block

        if (complexityLevels.length != pointsRequired.length || complexityLevels.length == 0) {
             revert InvalidComplexityThresholds();
        }
        for (uint i = 0; i < complexityLevels.length; i++) {
            _complexityThresholds[complexityLevels[i]] = pointsRequired[i];
        }

        // Owner is automatically an authorised adaptor
        _authorisedAdaptors[msg.sender] = true;
    }

    // --- ERC721 Standard Functions (Implemented via inheritance) ---
    // 1. balanceOf(address owner)
    // 2. ownerOf(uint256 tokenId)
    // 3. approve(address to, uint256 tokenId)
    // 4. getApproved(uint256 tokenId)
    // 5. setApprovalForAll(address operator, bool approved)
    // 6. isApprovedForAll(address owner, address operator)
    // 7. transferFrom(address from, address to, uint256 tokenId)
    // 8. safeTransferFrom(address from, address to, uint256 tokenId)
    // 9. safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
    // (These are provided by the OpenZeppelin ERC721 base contract)

    // Override ERC721 _update function to ensure entity state is linked correctly
    function _update(address to, uint256 tokenId, address auth) internal override(ERC721) returns (address) {
        address from = _ownerOf(tokenId);
        super._update(to, tokenId, auth);
        if (from != address(0) && to == address(0)) {
            // Entity burned - handle state cleanup if needed (optional, current design keeps history)
        } else if (from != address(0) && to != address(0)) {
            // Entity transferred
            _entities[tokenId].owner = to;
        } else if (from == address(0) && to != address(0)) {
            // Entity minted - _mint calls _update with from=0 address
            // State is set in mintInitialEntity
        }
        return to;
    }

    // Override ERC721 _safeTransfer function to ensure it handles ERC721Receiver
     function _safeTransfer(address from, address to, uint256 tokenId, bytes memory data) internal override(ERC721) {
        super._safeTransfer(from, to, tokenId, data);
        if (to.code.length > 0) { // Only check if recipient is a contract
            require(
                IERC721Receiver(to).onERC721Received(msg.sender, from, tokenId, data) == _ERC721_RECEIVED,
                "ERC721: transfer to non ERC721Receiver implementer"
            );
        }
    }


    // --- Entity Management & Info Functions ---

    /**
     * @dev Mints a new entity NFT and initializes its state and attributes.
     * @param owner The address to mint the entity to.
     */
    function mintInitialEntity(address owner) external onlyOwner {
        uint256 newEntityId = _entityCounter.current();
        _entityCounter.increment();

        _safeMint(owner, newEntityId);

        _entities[newEntityId] = Entity({
            id: newEntityId,
            owner: owner,
            creationBlock: uint64(block.number),
            complexityLevel: 0
        });

        // Initialize attributes based on current defaults
        _entityAttributes[newEntityId] = EntityAttributes({
            energy: _initialEntityAttributes.energy,
            complexityPoints: _initialEntityAttributes.complexityPoints,
            affinity: _initialEntityAttributes.affinity,
            explorationSkill: _initialEntityAttributes.explorationSkill,
            interactionSkill: _initialEntityAttributes.interactionSkill
        });

        emit EntityCreated(newEntityId, owner, uint64(block.number));
        emit AttributesChanged(
            newEntityId,
            _initialEntityAttributes.energy,
            _initialEntityAttributes.complexityPoints,
            _initialEntityAttributes.affinity,
            _initialEntityAttributes.explorationSkill,
            _initialEntityAttributes.interactionSkill
        );
    }

    /**
     * @dev Gets the basic information for an entity.
     * @param entityId The ID of the entity.
     * @return The Entity struct.
     */
    function getEntityInfo(uint256 entityId) external view returns (Entity memory) {
        _requireEntityExists(entityId);
        return _entities[entityId];
    }

    /**
     * @dev Gets the current attributes for an entity.
     * @param entityId The ID of the entity.
     * @return The EntityAttributes struct.
     */
    function getEntityAttributes(uint256 entityId) public view returns (EntityAttributes memory) {
         _requireEntityExists(entityId);
        return _entityAttributes[entityId];
    }

    /**
     * @dev Gets the current complexity level of an entity.
     * @param entityId The ID of the entity.
     * @return The complexity level.
     */
    function getEntityComplexityLevel(uint256 entityId) external view returns (uint8) {
        _requireEntityExists(entityId);
        return _entities[entityId].complexityLevel;
    }

     /**
     * @dev Gets the current complexity points of an entity.
     * @param entityId The ID of the entity.
     * @return The complexity points.
     */
    function getEntityComplexityPoints(uint256 entityId) external view returns (uint128) {
         _requireEntityExists(entityId);
        return _entityAttributes[entityId].complexityPoints;
    }


    // --- Environment Interaction & Info Functions ---

    /**
     * @dev Gets the current global environment state.
     * @return The EnvironmentState struct.
     */
    function getEnvironmentState() external view returns (EnvironmentState memory) {
        return _environmentState;
    }

    /**
     * @dev Triggers a shift in global environment parameters.
     * @param globalEnergyShift Amount to change global energy factor (positive or negative).
     * @param globalAffinityShiftDelta Amount to change global affinity shift (positive or negative).
     */
    function triggerEnvironmentEvent(uint128 globalEnergyShift, int128 globalAffinityShiftDelta) external onlyOwner {
        // Example: Apply shifts, preventing underflow/overflow conceptually
        // In real implementation, careful bounds checking or saturated arithmetic would be needed.
        // Here we show a simplified version.
        _environmentState.globalEnergy = _environmentState.globalEnergy + globalEnergyShift; // Simplified, no max
        _environmentState.globalAffinityShift = _environmentState.globalAffinityShift + globalAffinityShiftDelta;
        _environmentState.lastEnvironmentalShiftBlock = uint64(block.number);

        emit EnvironmentShift(
            _environmentState.globalEnergy,
            _environmentState.globalComplexityFactor,
            _environmentState.globalAffinityShift
        );
    }

    // --- Entity Action Functions ---

    /**
     * @dev Performs the 'explore' action for an entity.
     * Consumes energy, potentially gains complexity points and exploration skill based on rules and environment.
     * @param entityId The ID of the entity.
     */
    function performActionExplore(uint256 entityId) external onlyEntityOwnerOrApproved(entityId) {
        _requireEntityExists(entityId);
        EntityAttributes storage attrs = _entityAttributes[entityId];

        uint128 energyCost = _ruleParameters.exploreEnergyCost;
        if (attrs.energy < energyCost) {
            revert InsufficientEnergy(entityId, energyCost, attrs.energy);
        }
        attrs.energy -= energyCost;

        // Deterministic outcome simulation using block hash and entity ID
        bytes32 outcomeSeed = keccak256(abi.encodePacked(blockhash(block.number - 1), entityId, "explore"));
        uint256 outcomeValue = uint256(outcomeSeed);

        // Rule calculation based on attributes, environment, and parameters
        // Example rule: Outcome scaled by exploration skill and global complexity factor
        uint128 pointsGained = (_ruleParameters.exploreBaseOutcome * (100 + attrs.explorationSkill)) / 100;
        pointsGained = (pointsGained * (100 + _environmentState.globalComplexityFactor)) / 100;

        // Add some pseudo-random variation (within a deterministic range)
        uint128 variation = uint128(outcomeValue % (pointsGained / 4 + 1)); // +/- up to 25% variation
        if (outcomeValue % 2 == 0) {
            pointsGained = pointsGained + variation;
        } else {
            pointsGained = (pointsGained > variation) ? pointsGained - variation : 0;
        }


        attrs.complexityPoints += pointsGained;
        attrs.explorationSkill += (pointsGained / 10); // Small skill gain based on points

        // Update aggregate interaction data
        if (pointsGained > _ruleParameters.exploreBaseOutcome) {
             _interactionData.successfulExplores++;
        } else {
             _interactionData.failedExplores++;
        }


        _checkComplexityIncrease(entityId, attrs); // Check if complexity level increases

        emit ActionPerformed(entityId, "explore", pointsGained > 0, int256(pointsGained));
        _emitAttributesChanged(entityId, attrs);
    }

    /**
     * @dev Performs the 'interact' action between two entities.
     * Consumes energy for the initiator, affects attributes (especially affinity) of both entities
     * based on their skills, affinities, rules, and environment.
     * @param entityId The ID of the initiating entity.
     * @param targetEntityId The ID of the target entity.
     */
    function performActionInteract(uint256 entityId, uint256 targetEntityId) external onlyEntityOwnerOrApproved(entityId) {
        _requireEntityExists(entityId);
        _requireEntityExists(targetEntityId);
        require(entityId != targetEntityId, "Cannot interact with self");

        EntityAttributes storage initiatorAttrs = _entityAttributes[entityId];
        EntityAttributes storage targetAttrs = _entityAttributes[targetEntityId];

        uint128 energyCost = _ruleParameters.interactEnergyCost;
         if (initiatorAttrs.energy < energyCost) {
            revert InsufficientEnergy(entityId, energyCost, initiatorAttrs.energy);
        }
        initiatorAttrs.energy -= energyCost;

        // Deterministic outcome simulation
        bytes32 outcomeSeed = keccak256(abi.encodePacked(blockhash(block.number - 1), entityId, targetEntityId, "interact"));
        uint256 outcomeValue = uint256(outcomeSeed);

        // Rule calculation
        // Outcome influenced by initiator skill, target skill, their current affinity, global affinity shift, and parameters
        int128 baseOutcome = _ruleParameters.interactBaseOutcome;
        int128 affinityModifier = (initiatorAttrs.affinity + targetAttrs.affinity + _environmentState.globalAffinityShift) / int128(2); // Average affinity
        int128 skillModifier = int128(initiatorAttrs.interactionSkill + targetAttrs.interactionSkill) / int128(2); // Average skill

        // Scale modifiers by affinityImpactFactor (divide by a large number to keep it reasonable)
        int128 finalOutcome = baseOutcome +
                             (affinityModifier * int128(_ruleParameters.affinityImpactFactor)) / 1000 +
                             (skillModifier * int128(_ruleParameters.affinityImpactFactor)) / 2000; // Skill has less impact than affinity

        // Add pseudo-random variation
        int128 variation = int128(outcomeValue % uint256(type(int128).max) / 20); // +/- up to ~5% variation
        if (outcomeValue % 2 == 0) {
             finalOutcome += variation;
        } else {
             finalOutcome -= variation;
        }

        // Apply outcome (e.g., change affinity for both)
        int128 initiatorAffinityChange = finalOutcome;
        int128 targetAffinityChange = finalOutcome / 2; // Target is less affected

        initiatorAttrs.affinity += initiatorAffinityChange;
        targetAttrs.affinity += targetAffinityChange;

        // Add complexity points based on interaction (simplified)
        initiatorAttrs.complexityPoints += (_ruleParameters.complexityGainFactor * (100 + uint128(Math.max(0, finalOutcome)))) / 100;

        // Update aggregate interaction data
        _interactionData.totalAffinityChange += initiatorAffinityChange + targetAffinityChange;
        if (finalOutcome > _ruleParameters.interactBaseOutcome) {
             _interactionData.successfulInteracts++;
        } else {
             _interactionData.failedInteracts++;
        }

        _checkComplexityIncrease(entityId, initiatorAttrs);

        emit ActionPerformed(entityId, "interact", finalOutcome > 0, finalOutcome);
        _emitAttributesChanged(entityId, initiatorAttrs);
        _emitAttributesChanged(targetEntityId, targetAttrs);
    }

    /**
     * @dev Performs the 'rest' action for an entity.
     * Gains energy, potentially loses some complexity points.
     * @param entityId The ID of the entity.
     */
    function performActionRest(uint256 entityId) external onlyEntityOwnerOrApproved(entityId) {
        _requireEntityExists(entityId);
        EntityAttributes storage attrs = _entityAttributes[entityId];

        // Gain energy (up to a conceptual max - simplified here)
        attrs.energy += _ruleParameters.restEnergyGain;

        // Lose complexity points (resting is passive)
        uint128 complexityLoss = _ruleParameters.restComplexityLoss;
        attrs.complexityPoints = (attrs.complexityPoints > complexityLoss) ? attrs.complexityPoints - complexityLoss : 0;

        emit ActionPerformed(entityId, "rest", true, int256(_ruleParameters.restEnergyGain)); // Report energy gain as outcome
        _emitAttributesChanged(entityId, attrs);
    }

    /**
     * @dev Performs the 'specialize' action for an entity.
     * Increases one specific skill/attribute at the cost of energy and complexity points.
     * @param entityId The ID of the entity.
     * @param attributeIndex Index indicating which attribute to specialize (0: explore, 1: interact).
     */
    function performActionSpecialize(uint256 entityId, uint8 attributeIndex) external onlyEntityOwnerOrApproved(entityId) {
         _requireEntityExists(entityId);
        EntityAttributes storage attrs = _entityAttributes[entityId];

        uint128 energyCost = _ruleParameters.specializationEnergyCost;
        uint128 complexityCost = _ruleParameters.specializationComplexityCost;

         if (attrs.energy < energyCost) {
            revert InsufficientEnergy(entityId, energyCost, attrs.energy);
        }
         if (attrs.complexityPoints < complexityCost) {
            revert InsufficientComplexityPoints(entityId, complexityCost, attrs.complexityPoints);
        }

        attrs.energy -= energyCost;
        attrs.complexityPoints -= complexityCost;

        uint128 skillGain = complexityCost / 10; // Example: Gain skill based on complexity cost

        if (attributeIndex == 0) { // Explore Skill
             attrs.explorationSkill += skillGain;
        } else if (attributeIndex == 1) { // Interaction Skill
             attrs.interactionSkill += skillGain;
        } else {
             revert InvalidAttributeIndex(attributeIndex);
        }

        emit ActionPerformed(entityId, "specialize", true, int256(skillGain));
        _emitAttributesChanged(entityId, attrs);
    }

    /**
     * @dev Attempts to increase the complexity level of an entity.
     * Requires the entity to have reached the necessary complexity points for the next level.
     * Consumes energy and complexity points upon successful level up.
     * @param entityId The ID of the entity.
     */
    function attemptComplexityIncrease(uint256 entityId) external onlyEntityOwnerOrApproved(entityId) {
        _requireEntityExists(entityId);
        Entity storage entity = _entities[entityId];
        EntityAttributes storage attrs = _entityAttributes[entityId];

        uint8 currentLevel = entity.complexityLevel;
        uint8 nextLevel = currentLevel + 1;

        uint128 pointsRequired = _complexityThresholds[nextLevel];
        if (pointsRequired == 0 && nextLevel > 0) {
             // No threshold defined for the next level, entity is at max defined complexity
            emit ActionPerformed(entityId, "attemptComplexityIncrease", false, 0);
            return; // Cannot increase further
        }

         if (attrs.complexityPoints < pointsRequired) {
            revert InsufficientComplexityPoints(entityId, pointsRequired, attrs.complexityPoints);
        }

        uint128 energyCost = _ruleParameters.complexityAttemptEnergyCost;
         if (attrs.energy < energyCost) {
            revert InsufficientEnergy(entityId, energyCost, attrs.energy);
        }

        // Success! Consume resources and update level
        attrs.energy -= energyCost;
        attrs.complexityPoints -= pointsRequired; // Consume the points needed for the level

        entity.complexityLevel = nextLevel;

        emit ComplexityLevelIncreased(entityId, nextLevel);
        emit ActionPerformed(entityId, "attemptComplexityIncrease", true, int256(nextLevel));
        _emitAttributesChanged(entityId, attrs);
    }

    // --- Rule Adaptation & Management Functions ---

     /**
     * @dev Returns the current parameters governing entity actions.
     * @return The RuleParameters struct.
     */
    function getRuleParameters() external view returns (RuleParameters memory) {
        return _ruleParameters;
    }

    /**
     * @dev Triggers the rule adaptation process.
     * This function adjusts the `_ruleParameters` based on the collected `_interactionData`.
     * Can only be called by the owner or an authorised adaptor after a cooldown period.
     */
    function triggerRuleAdaptation() external onlyAuthorisedAdaptor {
        uint64 cooldown = _ruleParameters.ruleAdaptationCooldown;
        if (block.number < _lastAdaptationBlock + cooldown) {
            revert AdaptationTooFrequent(_lastAdaptationBlock, uint64(block.number), cooldown);
        }

        // --- Rule Adaptation Logic (Example) ---
        // This is a simplified, deterministic adaptation based on aggregate stats.
        // A real system could involve more complex calculations or even on-chain "decision trees".

        uint256 totalExplores = _interactionData.successfulExplores + _interactionData.failedExplores;
        if (totalExplores > 0) {
            uint256 successRate = (_interactionData.successfulExplores * 1000) / totalExplores;
            // If exploration is very successful, increase its energy cost slightly, reduce base outcome slightly
            if (successRate > 700) { // >70% success
                _ruleParameters.exploreEnergyCost += (_ruleParameters.exploreEnergyCost * 10) / 100; // +10% cost
                _ruleParameters.exploreBaseOutcome = (_ruleParameters.exploreBaseOutcome * 95) / 100; // -5% outcome
            } else if (successRate < 300) { // <30% success
                 _ruleParameters.exploreEnergyCost = (_ruleParameters.exploreEnergyCost * 90) / 100; // -10% cost
                 _ruleParameters.exploreBaseOutcome += (_ruleParameters.exploreBaseOutcome * 10) / 100; // +10% outcome
            }
        }

        uint256 totalInteracts = _interactionData.successfulInteracts + _interactionData.failedInteracts;
        if (totalInteracts > 0) {
            int256 avgAffinityChange = _interactionData.totalAffinityChange / int256(totalInteracts);
            // If average affinity change is very positive, increase base interact outcome slightly
            if (avgAffinityChange > 50) {
                _ruleParameters.interactBaseOutcome += (_ruleParameters.interactBaseOutcome >= 0 ? (_ruleParameters.interactBaseOutcome * 5) / 100 : (_ruleParameters.interactBaseOutcome * 105) / 100); // +5% or adjust
                _ruleParameters.affinityImpactFactor += (_ruleParameters.affinityImpactFactor * 5) / 100;
            } else if (avgAffinityChange < -50) {
                 _ruleParameters.interactBaseOutcome = (_ruleParameters.interactBaseOutcome >= 0 ? (_ruleParameters.interactBaseOutcome * 95) / 100 : (_ruleParameters.interactBaseOutcome * 90) / 100); // -5% or adjust
                 _ruleParameters.affinityImpactFactor = (_ruleParameters.affinityImpactFactor > 0 ? (_ruleParameters.affinityImpactFactor * 95) / 100 : 0); // Reduce positive impact
            }
        }

        // --- End Rule Adaptation Logic ---

        // Reset interaction data after adaptation
        _interactionData = InteractionData({
            successfulExplores: 0,
            failedExplores: 0,
            successfulInteracts: 0,
            failedInteracts: 0,
            totalAffinityChange: 0
        });

        _lastAdaptationBlock = uint64(block.number);

        emit RuleParametersAdapted(block.number);
    }

    /**
     * @dev Adds an address to the list of authorised adaptors.
     * Only the owner can call this.
     * @param adaptor The address to authorise.
     */
    function addAuthorisedAdaptor(address adaptor) external onlyOwner {
        require(adaptor != address(0), "Invalid address");
        _authorisedAdaptors[adaptor] = true;
        emit AuthorisedAdaptorAdded(adaptor);
    }

    /**
     * @dev Removes an address from the list of authorised adaptors.
     * Only the owner can call this.
     * @param adaptor The address to de-authorise.
     */
    function removeAuthorisedAdaptor(address adaptor) external onlyOwner {
        require(adaptor != owner(), "Cannot remove owner");
        _authorisedAdaptors[adaptor] = false;
        emit AuthorisedAdaptorRemoved(adaptor);
    }


    // --- Admin & Utility Functions ---

    /**
     * @dev Sets the required complexity points for reaching specific levels.
     * @param levels Array of complexity levels (e.g., [1, 2, 3]).
     * @param pointsRequired Array of complexity points required for each level (e.g., [1000, 5000, 20000]).
     */
    function setComplexityThresholds(uint8[] calldata levels, uint128[] calldata pointsRequired) external onlyOwner {
         if (levels.length != pointsRequired.length || levels.length == 0) {
             revert InvalidComplexityThresholds();
         }
         for (uint i = 0; i < levels.length; i++) {
             _complexityThresholds[levels[i]] = pointsRequired[i];
         }
    }

    // Internal state for initial entity attributes (can be set by owner)
    EntityAttributes private _initialEntityAttributes;

    /**
     * @dev Sets the default initial attributes for newly minted entities.
     * @param initialEnergy Initial energy.
     * @param initialComplexityPoints Initial complexity points.
     * @param initialAffinity Initial affinity.
     * @param initialExplorationSkill Initial exploration skill.
     * @param initialInteractionSkill Initial interaction skill.
     */
    function setInitialEntityAttributes(
        uint128 initialEnergy,
        uint128 initialComplexityPoints,
        int128 initialAffinity,
        uint128 initialExplorationSkill,
        uint128 initialInteractionSkill
    ) external onlyOwner {
        _setInitialEntityAttributes(initialEnergy, initialComplexityPoints, initialAffinity, initialExplorationSkill, initialInteractionSkill);
    }

    // Internal helper to set initial attributes state
    function _setInitialEntityAttributes(
         uint128 initialEnergy,
        uint128 initialComplexityPoints,
        int128 initialAffinity,
        uint128 initialExplorationSkill,
        uint128 initialInteractionSkill
    ) internal {
        _initialEntityAttributes = EntityAttributes({
            energy: initialEnergy,
            complexityPoints: initialComplexityPoints,
            affinity: initialAffinity,
            explorationSkill: initialExplorationSkill,
            interactionSkill: initialInteractionSkill
        });
    }

     /**
     * @dev Sets the parameters used in rule calculations for entity actions.
     * @param params The new RuleParameters struct.
     */
    function setRuleParameters(RuleParameters memory params) external onlyOwner {
         // Add basic validation if needed, e.g., costs shouldn't be excessive etc.
         _ruleParameters = params;
    }


    // --- Internal Helper Functions ---

    /**
     * @dev Checks if an entity exists and reverts if not.
     * @param entityId The ID of the entity.
     */
    function _requireEntityExists(uint256 entityId) internal view {
        if (_ownerOf(entityId) == address(0)) {
            revert EntityNotFound(entityId);
        }
    }

    /**
     * @dev Helper to emit AttributesChanged event.
     * @param entityId The ID of the entity.
     * @param attrs The EntityAttributes struct.
     */
    function _emitAttributesChanged(uint256 entityId, EntityAttributes memory attrs) internal {
         emit AttributesChanged(
            entityId,
            attrs.energy,
            attrs.complexityPoints,
            attrs.affinity,
            attrs.explorationSkill,
            attrs.interactionSkill
         );
    }

    /**
     * @dev Checks if an entity is eligible for a complexity level increase and performs it if so.
     * Called internally after actions that might increase complexity points.
     * @param entityId The ID of the entity.
     * @param attrs The EntityAttributes struct (passed by storage reference).
     */
    function _checkComplexityIncrease(uint256 entityId, EntityAttributes storage attrs) internal {
         Entity storage entity = _entities[entityId];
         uint8 currentLevel = entity.complexityLevel;
         uint8 nextLevel = currentLevel + 1;
         uint128 pointsRequired = _complexityThresholds[nextLevel];

         // Check if threshold is defined and points are sufficient
         if (pointsRequired > 0 && attrs.complexityPoints >= pointsRequired) {
             // Entity has enough points, they can attempt to level up using `attemptComplexityIncrease`
             // This helper only checks if they *can*, the actual level up and cost is in the external function.
             // This prevents passive level ups. Leaving this check here documents the state dependency.
             // Could potentially add a flag or event indicating "Ready for Level Up".
         }
    }


    // The following functions are standard ERC721 overrides necessary for compliance
    function supportsInterface(bytes4 interfaceId) public view override(ERC721) returns (bool) {
        return interfaceId == type(IERC721).interfaceId ||
               interfaceId == type(IERC721Metadata).interfaceId ||
               super.supportsInterface(interfaceId);
    }
}
```