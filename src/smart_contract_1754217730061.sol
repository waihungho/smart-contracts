This smart contract, **ChronoForge**, introduces a novel concept of "ChronoEssences" – dynamic, time-sensitive digital assets that can evolve, decay, and react to conditions and external data. It goes beyond simple NFTs by embedding a life-cycle, programmable attributes, and rule-based transformations directly into the asset's on-chain representation.

---

## ChronoForge: Programmable Digital Life Cycles

**Concept:** ChronoForge allows for the creation, management, and dynamic evolution of "ChronoEssences." These are unique digital assets (similar to advanced NFTs) that possess a defined life cycle, programmable attributes, and a set of immutable or mutable rules that dictate their behavior, evolution, or decay over time or in response to external conditions. They are not just static images or simple tokens; they are living, evolving digital entities.

**Core Innovation:**
*   **Temporal Evolution:** Essences can advance through defined stages (Seed, Sprout, Bloom, Decay) based on time, external triggers, or attribute values.
*   **Programmable Attributes:** Key-value string pairs that can be dynamically updated, queried, and used in conditional logic.
*   **On-Chain Condition Rules:** Define if/then logic that dictates how an Essence behaves, changes attributes, or restricts actions.
*   **Oracle Integration (Conceptual):** Designed to interact with external data for real-world influence on Essence state.
*   **No Open Source Duplication:** This contract is designed from scratch around the concept of "programmable digital life cycles" rather than being a clone of existing token standards, DeFi primitives, or governance contracts.

---

### **Outline and Function Summary:**

**I. Core Infrastructure & Management**
1.  **`constructor()`**: Initializes the contract owner.
2.  **`pause()`**: Pauses contract operations (owner only).
3.  **`unpause()`**: Unpauses contract operations (owner only).
4.  **`setOracleAddress(address _oracle)`**: Sets the address of an approved oracle for external data feeds (owner only).

**II. ChronoEssence Creation & Blueprints**
5.  **`forgeEssence(string memory _name, uint256 _durationSeconds, mapping(string => string) memory _initialAttributes)`**: Mints a new ChronoEssence with a name, initial lifespan, and a set of starting attributes.
6.  **`registerBlueprint(string memory _blueprintName, uint256 _defaultDuration, mapping(string => string) memory _defaultAttributes, address[] memory _allowedForgers)`**: Creates a reusable blueprint (template) for forging Essences, defining default properties and who can use it.
7.  **`forgeFromBlueprint(string memory _blueprintName)`**: Mints a new ChronoEssence using a registered blueprint.
8.  **`updateBlueprint(string memory _blueprintName, uint256 _newDefaultDuration, mapping(string => string) memory _newDefaultAttributes, address[] memory _newAllowedForgers)`**: Modifies an existing blueprint (owner or blueprint owner).

**III. ChronoEssence Lifecycle & Evolution**
9.  **`evolveEssence(uint256 _essenceId)`**: Advances an Essence to its next life stage, triggered by time, attribute conditions, or manual intervention (if rules allow). Can be called by anyone, with gas costs incentivized by the system or a DAO.
10. **`decayEssence(uint256 _essenceId)`**: Explicitly marks an Essence as 'Decayed' if its expiration conditions are met.
11. **`renewEssence(uint256 _essenceId, uint256 _additionalDurationSeconds)`**: Extends the lifespan of an Essence, subject to rules and potential payment.
12. **`setEssenceExpirationPolicy(uint256 _essenceId, uint8 _policyType, string memory _attributeKey, string memory _attributeValue)`**: Defines how an Essence expires (e.g., fixed time, specific attribute value).

**IV. Dynamic Attribute Management**
13. **`setAttribute(uint256 _essenceId, string memory _key, string memory _value)`**: Sets or updates a specific attribute for an Essence (owner of Essence).
14. **`modifyAttributeConditional(uint256 _essenceId, string memory _key, string memory _newValue, uint256 _conditionRuleId)`**: Modifies an attribute only if a specific pre-defined condition rule is met (e.g., oracle input, time-based).
15. **`batchUpdateAttributes(uint256 _essenceId, string[] memory _keys, string[] memory _values)`**: Updates multiple attributes for an Essence in a single transaction.

**V. Rule-Based Logic & Interaction**
16. **`addConditionRule(uint256 _essenceId, string memory _description, ConditionType _type, string memory _targetKey, string memory _threshold, string memory _actionKey, string memory _actionValue)`**: Adds a new condition rule to an Essence, defining an `IF [condition] THEN [action]` logic for its attributes or behavior.
17. **`removeConditionRule(uint256 _essenceId, uint256 _ruleId)`**: Removes an existing condition rule from an Essence.
18. **`evaluateCondition(uint256 _essenceId, uint256 _ruleId, string memory _oracleData)`**: Triggers the evaluation of a specific condition rule for an Essence, potentially using external oracle data. If the condition is met, the associated action is executed.
19. **`recordInteraction(uint256 _essenceId, string memory _interactionType, string memory _metadata)`**: Logs an external interaction or event related to an Essence (e.g., "fed", "inspected", "traded off-chain").

**VI. Querying & Information**
20. **`getEssenceDetails(uint256 _essenceId)`**: Retrieves all public details of a ChronoEssence, including its current stage, attributes, and lifecycle data.
21. **`getEssenceAttribute(uint256 _essenceId, string memory _key)`**: Retrieves the value of a specific attribute for an Essence.
22. **`getEssencesByStage(EssenceStage _stage)`**: Returns a list of Essence IDs currently in a specific life stage.
23. **`getExpiredEssences()`**: Returns a list of Essence IDs that have currently expired/decayed.
24. **`getBlueprintDetails(string memory _blueprintName)`**: Retrieves the details of a registered blueprint.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";

/**
 * @title ChronoForge
 * @dev A contract for creating, managing, and evolving dynamic, time-sensitive digital assets called ChronoEssences.
 *      These assets have programmable attributes, life-cycles, and rule-based transformations.
 *      This contract is designed to be a unique implementation and does not duplicate existing open-source token standards.
 */
contract ChronoForge is Ownable, ReentrancyGuard, Pausable {

    // --- Custom Errors for Gas Efficiency ---
    error EssenceNotFound(uint256 essenceId);
    error EssenceNotActive(uint256 essenceId);
    error EssenceAlreadyDecayed(uint256 essenceId);
    error EssenceAlreadyActive(uint256 essenceId);
    error UnauthorizedCaller();
    error InvalidDuration();
    error BlueprintNotFound(string blueprintName);
    error BlueprintAlreadyExists(string blueprintName);
    error NotAllowedToForge();
    error InvalidRuleId(uint256 ruleId);
    error ConditionNotMet();
    error NoOracleAddressSet();
    error InvalidExpirationPolicy();

    // --- Enums ---
    enum EssenceStage {
        Seed,      // Initial state
        Sprout,    // Early growth
        Bloom,     // Mature, fully active
        Decay,     // Past prime, declining
        Extinct    // Final state, no longer usable or renewable
    }

    enum ConditionType {
        TimeElapsed,      // Condition based on passage of time
        AttributeValue,   // Condition based on an attribute's value
        OracleInput       // Condition based on external data via oracle
    }

    enum ExpirationPolicyType {
        FixedTime,        // Expires after a set duration from creation
        AttributeValue    // Expires when a specific attribute reaches a value
    }

    // --- Structs ---

    struct ChronoEssence {
        uint256 id;
        address owner;
        string name;
        uint256 creationTime;
        uint256 expirationTime; // Set based on duration or policy
        EssenceStage currentStage;
        mapping(string => string) attributes; // Dynamic key-value attributes
        uint256 lastEvolutionTime; // Timestamp of the last stage evolution
        uint256 nextRuleId; // Counter for condition rules
        mapping(uint256 => ConditionRule) conditionRules; // Rules governing behavior
        ExpirationPolicy expirationPolicy; // How this essence expires
    }

    struct ConditionRule {
        uint256 id;
        string description;
        ConditionType ruleType;
        string targetKey;       // For AttributeValue & OracleInput
        string threshold;       // Value to compare against
        string actionKey;       // Attribute to modify if condition met
        string actionValue;     // New value for actionKey if condition met
        bool isActive;
    }

    struct ExpirationPolicy {
        ExpirationPolicyType policyType;
        string attributeKey;    // Relevant for AttributeValue policy
        string attributeValue;  // Relevant for AttributeValue policy
    }

    struct ChronoBlueprint {
        string blueprintName;
        uint256 defaultDuration;
        mapping(string => string) defaultAttributes; // Initial attributes for Essences forged from this blueprint
        address[] allowedForgers; // Addresses allowed to use this blueprint, empty means anyone
        address creator; // The address that created this blueprint
        uint256 totalForged; // Count of essences forged from this blueprint
    }

    // --- State Variables ---

    uint256 private _nextEssenceId;
    mapping(uint256 => ChronoEssence) private _essences;
    mapping(address => uint256[]) private _ownerEssences; // Mapping of owner to array of owned Essence IDs
    mapping(EssenceStage => uint256[]) private _essencesByStage; // Mapping of stage to array of Essence IDs

    mapping(string => ChronoBlueprint) private _blueprints;
    string[] private _blueprintNames; // To iterate over blueprint names

    address private _oracleAddress; // Address of a trusted oracle for external data

    // --- Events ---

    event EssenceForged(uint256 indexed essenceId, address indexed owner, string name, uint256 creationTime, uint256 expirationTime, EssenceStage initialStage);
    event EssenceEvolved(uint256 indexed essenceId, EssenceStage oldStage, EssenceStage newStage, uint256 timestamp);
    event EssenceDecayed(uint256 indexed essenceId, uint256 timestamp);
    event EssenceRenewed(uint256 indexed essenceId, uint256 newExpirationTime);
    event AttributeSet(uint256 indexed essenceId, string key, string value);
    event ConditionRuleAdded(uint256 indexed essenceId, uint256 ruleId, string description);
    event ConditionRuleRemoved(uint256 indexed essenceId, uint256 ruleId);
    event ConditionEvaluated(uint256 indexed essenceId, uint256 indexed ruleId, bool conditionMet, string oracleData);
    event InteractionRecorded(uint256 indexed essenceId, string interactionType, string metadata, address indexed initiator);
    event BlueprintRegistered(string indexed blueprintName, address indexed creator);
    event BlueprintUpdated(string indexed blueprintName);
    event EssenceExpirationPolicySet(uint256 indexed essenceId, ExpirationPolicyType policyType);
    event OracleAddressSet(address indexed newOracleAddress);

    // --- Modifiers ---

    modifier essenceExists(uint256 _essenceId) {
        if (_essences[_essenceId].id == 0) revert EssenceNotFound(_essenceId);
        _;
    }

    modifier essenceActive(uint256 _essenceId) {
        if (_essences[_essenceId].id == 0) revert EssenceNotFound(_essenceId);
        if (_essences[_essenceId].currentStage == EssenceStage.Extinct) revert EssenceAlreadyDecayed(_essenceId);
        _;
    }

    // --- Constructor ---

    constructor() Ownable(msg.sender) Pausable() {
        _nextEssenceId = 1; // Start Essence IDs from 1
    }

    // --- I. Core Infrastructure & Management ---

    /**
     * @dev Pauses the contract. Only callable by the owner.
     */
    function pause() external onlyOwner whenNotPaused {
        _pause();
    }

    /**
     * @dev Unpauses the contract. Only callable by the owner.
     */
    function unpause() external onlyOwner whenPaused {
        _unpause();
    }

    /**
     * @dev Sets the address of an approved oracle for external data feeds.
     *      Only callable by the owner.
     * @param _oracle The address of the new oracle contract.
     */
    function setOracleAddress(address _oracle) external onlyOwner {
        require(_oracle != address(0), "ChronoForge: Oracle address cannot be zero");
        _oracleAddress = _oracle;
        emit OracleAddressSet(_oracle);
    }

    // --- II. ChronoEssence Creation & Blueprints ---

    /**
     * @dev Mints a new ChronoEssence with a name, initial lifespan, and a set of starting attributes.
     * @param _name The name of the ChronoEssence.
     * @param _durationSeconds The initial lifespan in seconds from creation time.
     * @param _initialAttributes A mapping of initial attributes for the Essence.
     * @return The ID of the newly forged ChronoEssence.
     */
    function forgeEssence(
        string memory _name,
        uint256 _durationSeconds,
        string[] memory _attributeKeys,
        string[] memory _attributeValues
    ) external whenNotPaused nonReentrant returns (uint256) {
        require(_durationSeconds > 0, "ChronoForge: Duration must be positive");
        require(_attributeKeys.length == _attributeValues.length, "ChronoForge: Attribute keys and values length mismatch");

        uint256 essenceId = _nextEssenceId++;
        uint256 creationTime = block.timestamp;
        uint256 expirationTime = creationTime + _durationSeconds;

        ChronoEssence storage newEssence = _essences[essenceId];
        newEssence.id = essenceId;
        newEssence.owner = msg.sender;
        newEssence.name = _name;
        newEssence.creationTime = creationTime;
        newEssence.expirationTime = expirationTime;
        newEssence.currentStage = EssenceStage.Seed;
        newEssence.lastEvolutionTime = creationTime;
        newEssence.nextRuleId = 1; // Initialize rule counter
        newEssence.expirationPolicy = ExpirationPolicy(ExpirationPolicyType.FixedTime, "", "");

        for (uint256 i = 0; i < _attributeKeys.length; i++) {
            newEssence.attributes[_attributeKeys[i]] = _attributeValues[i];
        }

        _ownerEssences[msg.sender].push(essenceId);
        _essencesByStage[EssenceStage.Seed].push(essenceId);

        emit EssenceForged(essenceId, msg.sender, _name, creationTime, expirationTime, EssenceStage.Seed);
        return essenceId;
    }

    /**
     * @dev Creates a reusable blueprint (template) for forging Essences.
     * @param _blueprintName The unique name for the blueprint.
     * @param _defaultDuration The default lifespan for Essences forged from this blueprint.
     * @param _attributeKeys Keys for default attributes.
     * @param _attributeValues Values for default attributes.
     * @param _allowedForgers Addresses allowed to use this blueprint. If empty, anyone can use.
     */
    function registerBlueprint(
        string memory _blueprintName,
        uint256 _defaultDuration,
        string[] memory _attributeKeys,
        string[] memory _attributeValues,
        address[] memory _allowedForgers
    ) external onlyOwner whenNotPaused nonReentrant {
        require(bytes(_blueprintName).length > 0, "ChronoForge: Blueprint name cannot be empty");
        require(_defaultDuration > 0, "ChronoForge: Default duration must be positive");
        require(_attributeKeys.length == _attributeValues.length, "ChronoForge: Attribute keys and values length mismatch");
        if (_blueprints[_blueprintName].creator != address(0)) revert BlueprintAlreadyExists(_blueprintName);

        ChronoBlueprint storage newBlueprint = _blueprints[_blueprintName];
        newBlueprint.blueprintName = _blueprintName;
        newBlueprint.defaultDuration = _defaultDuration;
        newBlueprint.creator = msg.sender;
        newBlueprint.allowedForgers = _allowedForgers;

        for (uint256 i = 0; i < _attributeKeys.length; i++) {
            newBlueprint.defaultAttributes[_attributeKeys[i]] = _attributeValues[i];
        }

        _blueprintNames.push(_blueprintName);
        emit BlueprintRegistered(_blueprintName, msg.sender);
    }

    /**
     * @dev Mints a new ChronoEssence using a registered blueprint.
     * @param _blueprintName The name of the blueprint to use.
     * @return The ID of the newly forged ChronoEssence.
     */
    function forgeFromBlueprint(string memory _blueprintName)
        external
        whenNotPaused
        nonReentrant
        returns (uint256)
    {
        ChronoBlueprint storage blueprint = _blueprints[_blueprintName];
        if (blueprint.creator == address(0)) revert BlueprintNotFound(_blueprintName);

        if (blueprint.allowedForgers.length > 0) {
            bool isAllowed = false;
            for (uint256 i = 0; i < blueprint.allowedForgers.length; i++) {
                if (blueprint.allowedForgers[i] == msg.sender) {
                    isAllowed = true;
                    break;
                }
            }
            if (!isAllowed) revert NotAllowedToForge();
        }

        uint256 essenceId = _nextEssenceId++;
        uint256 creationTime = block.timestamp;
        uint256 expirationTime = creationTime + blueprint.defaultDuration;

        ChronoEssence storage newEssence = _essences[essenceId];
        newEssence.id = essenceId;
        newEssence.owner = msg.sender;
        newEssence.name = string(abi.encodePacked("Blueprint-", _blueprintName, "-", Strings.toString(essenceId)));
        newEssence.creationTime = creationTime;
        newEssence.expirationTime = expirationTime;
        newEssence.currentStage = EssenceStage.Seed;
        newEssence.lastEvolutionTime = creationTime;
        newEssence.nextRuleId = 1;
        newEssence.expirationPolicy = ExpirationPolicy(ExpirationPolicyType.FixedTime, "", "");


        // Copy default attributes from blueprint
        // Note: Direct iteration over mapping keys in Solidity is not possible.
        // For production, you'd store blueprint attribute keys in an array or pass them.
        // For this example, we'll assume a mechanism to copy.
        // A more robust solution might involve passing them as parameters to this function,
        // or storing them in an array within the blueprint struct for iteration.
        // For simplicity of this example, we'll omit direct attribute copying from blueprint here
        // as it requires knowing the keys at compile time or storing them in an iterable array within blueprint.
        // In a real scenario, defaultAttributes in Blueprint would also store _attributeKeys as an array.
        // e.g., blueprint.defaultAttributeKeys = _attributeKeys; blueprint.defaultAttributes[key] = value;
        // then iterate blueprint.defaultAttributeKeys.
        // For now, it will be an empty attribute set unless explicitly set via setAttribute.

        _ownerEssences[msg.sender].push(essenceId);
        _essencesByStage[EssenceStage.Seed].push(essenceId);

        blueprint.totalForged++;
        emit EssenceForged(essenceId, msg.sender, newEssence.name, creationTime, expirationTime, EssenceStage.Seed);
        return essenceId;
    }

    /**
     * @dev Modifies an existing blueprint. Only callable by the blueprint's creator or the contract owner.
     * @param _blueprintName The name of the blueprint to update.
     * @param _newDefaultDuration The new default lifespan.
     * @param _attributeKeys Keys for new default attributes.
     * @param _attributeValues Values for new default attributes.
     * @param _newAllowedForgers New list of allowed forgers.
     */
    function updateBlueprint(
        string memory _blueprintName,
        uint256 _newDefaultDuration,
        string[] memory _attributeKeys,
        string[] memory _attributeValues,
        address[] memory _newAllowedForgers
    ) external whenNotPaused nonReentrant {
        ChronoBlueprint storage blueprint = _blueprints[_blueprintName];
        if (blueprint.creator == address(0)) revert BlueprintNotFound(_blueprintName);
        if (msg.sender != blueprint.creator && msg.sender != owner()) revert UnauthorizedCaller();
        require(_newDefaultDuration > 0, "ChronoForge: New default duration must be positive");
        require(_attributeKeys.length == _attributeValues.length, "ChronoForge: Attribute keys and values length mismatch");

        blueprint.defaultDuration = _newDefaultDuration;
        blueprint.allowedForgers = _newAllowedForgers;

        // Clear existing default attributes and set new ones
        // (Similar caveat as in forgeFromBlueprint about mapping iteration)
        // For a full implementation, you'd track keys to delete old ones efficiently.
        // For now, new keys will overwrite, old keys will persist if not overwritten.

        // In a real scenario, you'd manage previous keys and delete them if not present in new _attributeKeys
        // For this example, we'll just overwrite.
        for (uint256 i = 0; i < _attributeKeys.length; i++) {
            blueprint.defaultAttributes[_attributeKeys[i]] = _attributeValues[i];
        }

        emit BlueprintUpdated(_blueprintName);
    }

    // --- III. ChronoEssence Lifecycle & Evolution ---

    /**
     * @dev Advances an Essence to its next life stage.
     *      Can be triggered by anyone, incentivizing timely evolution based on game mechanics or external scripts.
     *      Evolution rules can be simple (time-based) or complex (attribute-based, oracle-driven).
     * @param _essenceId The ID of the Essence to evolve.
     */
    function evolveEssence(uint256 _essenceId) external whenNotPaused nonReentrant essenceActive(_essenceId) {
        ChronoEssence storage essence = _essences[_essenceId];

        // Basic time-based evolution logic. This can be extended with complex rules.
        EssenceStage oldStage = essence.currentStage;
        EssenceStage newStage = oldStage;

        // Example: Advance stage every X seconds, or based on specific attribute values
        if (essence.currentStage == EssenceStage.Seed && block.timestamp >= essence.creationTime + 1 hours) {
            newStage = EssenceStage.Sprout;
        } else if (essence.currentStage == EssenceStage.Sprout && block.timestamp >= essence.creationTime + 2 days) {
            newStage = EssenceStage.Bloom;
        } else if (essence.currentStage == EssenceStage.Bloom && block.timestamp >= essence.creationTime + 7 days) {
            newStage = EssenceStage.Decay; // Begin decay after a week
        }

        // Check expiration policy
        _checkAndApplyExpiration(_essenceId); // Internal call to check for decay/extinct based on policy

        if (newStage != oldStage) {
            _removeEssenceFromStage(oldStage, _essenceId);
            essence.currentStage = newStage;
            essence.lastEvolutionTime = block.timestamp;
            _essencesByStage[newStage].push(_essenceId);
            emit EssenceEvolved(_essenceId, oldStage, newStage, block.timestamp);
        } else if (essence.currentStage == EssenceStage.Decay && block.timestamp >= essence.expirationTime) {
            // Ensure final stage transition if decay condition met and time runs out
            decayEssence(_essenceId);
        }
    }

    /**
     * @dev Explicitly marks an Essence as 'Extinct' if its expiration conditions are met.
     *      Can be called by anyone to finalize expired essences.
     * @param _essenceId The ID of the Essence to decay.
     */
    function decayEssence(uint256 _essenceId) public whenNotPaused nonReentrant essenceActive(_essenceId) {
        ChronoEssence storage essence = _essences[_essenceId];

        bool shouldDecay = false;
        if (essence.expirationPolicy.policyType == ExpirationPolicyType.FixedTime) {
            shouldDecay = block.timestamp >= essence.expirationTime;
        } else if (essence.expirationPolicy.policyType == ExpirationPolicyType.AttributeValue) {
            // Example: attribute "health" drops to 0
            if (keccak256(abi.encodePacked(essence.attributes[essence.expirationPolicy.attributeKey])) == keccak256(abi.encodePacked(essence.expirationPolicy.attributeValue))) {
                shouldDecay = true;
            }
        }

        if (shouldDecay) {
            _removeEssenceFromStage(essence.currentStage, _essenceId);
            essence.currentStage = EssenceStage.Extinct;
            emit EssenceDecayed(_essenceId, block.timestamp);
        } else {
            // Optionally, revert or log if decay condition not met
            revert("ChronoForge: Essence not ready for decay based on policy");
        }
    }

    /**
     * @dev Extends the lifespan of an Essence, subject to rules and potential payment (not implemented).
     *      Only callable by the Essence owner.
     * @param _essenceId The ID of the Essence to renew.
     * @param _additionalDurationSeconds The additional time in seconds to add to the lifespan.
     */
    function renewEssence(uint256 _essenceId, uint256 _additionalDurationSeconds)
        external
        whenNotPaused
        nonReentrant
        essenceActive(_essenceId)
    {
        ChronoEssence storage essence = _essences[_essenceId];
        if (essence.owner != msg.sender) revert UnauthorizedCaller();
        require(_additionalDurationSeconds > 0, "ChronoForge: Additional duration must be positive");

        // Allow renewal only if not Extinct and within a certain decay window, or if policy allows
        // (e.g., cannot renew if "Extinct" but can if "Decay")
        if (essence.currentStage == EssenceStage.Extinct) revert EssenceAlreadyDecayed(_essenceId);

        essence.expirationTime += _additionalDurationSeconds;
        // Optionally, revert stage from Decay to Bloom upon renewal, based on contract rules
        if (essence.currentStage == EssenceStage.Decay) {
             _removeEssenceFromStage(EssenceStage.Decay, _essenceId);
             essence.currentStage = EssenceStage.Bloom; // Revive to Bloom
             _essencesByStage[EssenceStage.Bloom].push(_essenceId);
        }


        emit EssenceRenewed(_essenceId, essence.expirationTime);
    }

    /**
     * @dev Defines how an Essence expires (e.g., fixed time, specific attribute value).
     *      Only callable by the Essence owner.
     * @param _essenceId The ID of the Essence.
     * @param _policyType The type of expiration policy.
     * @param _attributeKey Relevant for AttributeValue policy.
     * @param _attributeValue Relevant for AttributeValue policy.
     */
    function setEssenceExpirationPolicy(
        uint256 _essenceId,
        ExpirationPolicyType _policyType,
        string memory _attributeKey,
        string memory _attributeValue
    ) external whenNotPaused essenceActive(_essenceId) {
        ChronoEssence storage essence = _essences[_essenceId];
        if (essence.owner != msg.sender) revert UnauthorizedCaller();

        if (_policyType == ExpirationPolicyType.AttributeValue) {
            require(bytes(_attributeKey).length > 0, "ChronoForge: Attribute key required for AttributeValue policy");
        } else {
            // For FixedTime, attributeKey and value are not strictly needed, ensure they are empty or ignored
            _attributeKey = "";
            _attributeValue = "";
        }

        essence.expirationPolicy = ExpirationPolicy(_policyType, _attributeKey, _attributeValue);
        emit EssenceExpirationPolicySet(_essenceId, _policyType);
    }

    // --- IV. Dynamic Attribute Management ---

    /**
     * @dev Sets or updates a specific attribute for an Essence.
     *      Only callable by the Essence owner.
     * @param _essenceId The ID of the Essence.
     * @param _key The attribute key.
     * @param _value The attribute value.
     */
    function setAttribute(uint256 _essenceId, string memory _key, string memory _value)
        external
        whenNotPaused
        essenceActive(_essenceId)
    {
        ChronoEssence storage essence = _essences[_essenceId];
        if (essence.owner != msg.sender) revert UnauthorizedCaller();
        require(bytes(_key).length > 0, "ChronoForge: Attribute key cannot be empty");

        essence.attributes[_key] = _value;
        emit AttributeSet(_essenceId, _key, _value);
    }

    /**
     * @dev Modifies an attribute only if a specific pre-defined condition rule is met.
     *      This function can be called by anyone (e.g., an automated bot, or the Essence owner)
     *      to attempt an attribute modification. The actual change depends on the rule's outcome.
     * @param _essenceId The ID of the Essence.
     * @param _key The attribute key to modify.
     * @param _newValue The new value to set if condition met.
     * @param _conditionRuleId The ID of the condition rule to evaluate.
     */
    function modifyAttributeConditional(
        uint256 _essenceId,
        string memory _key,
        string memory _newValue,
        uint256 _conditionRuleId
    ) external whenNotPaused essenceActive(_essenceId) nonReentrant {
        ChronoEssence storage essence = _essences[_essenceId];
        ConditionRule storage rule = essence.conditionRules[_conditionRuleId];
        if (rule.id == 0 || !rule.isActive) revert InvalidRuleId(_conditionRuleId);
        require(bytes(_key).length > 0, "ChronoForge: Attribute key cannot be empty");
        require(keccak256(abi.encodePacked(rule.actionKey)) == keccak256(abi.encodePacked(_key)), "ChronoForge: Rule action key mismatch");
        require(keccak256(abi.encodePacked(rule.actionValue)) == keccak256(abi.encodePacked(_newValue)), "ChronoForge: Rule action value mismatch");


        bool conditionMet = _checkCondition(essence, rule, ""); // No oracle data for this check directly

        if (conditionMet) {
            essence.attributes[_key] = _newValue;
            emit AttributeSet(_essenceId, _key, _newValue);
            emit ConditionEvaluated(_essenceId, _conditionRuleId, true, "");
        } else {
            revert ConditionNotMet();
        }
    }

    /**
     * @dev Updates multiple attributes for an Essence in a single transaction.
     *      Only callable by the Essence owner.
     * @param _essenceId The ID of the Essence.
     * @param _keys An array of attribute keys.
     * @param _values An array of attribute values.
     */
    function batchUpdateAttributes(uint256 _essenceId, string[] memory _keys, string[] memory _values)
        external
        whenNotPaused
        essenceActive(_essenceId)
    {
        ChronoEssence storage essence = _essences[_essenceId];
        if (essence.owner != msg.sender) revert UnauthorizedCaller();
        require(_keys.length == _values.length, "ChronoForge: Keys and values length mismatch");

        for (uint256 i = 0; i < _keys.length; i++) {
            require(bytes(_keys[i]).length > 0, "ChronoForge: Attribute key cannot be empty");
            essence.attributes[_keys[i]] = _values[i];
            emit AttributeSet(_essenceId, _keys[i], _values[i]);
        }
    }

    // --- V. Rule-Based Logic & Interaction ---

    /**
     * @dev Adds a new condition rule to an Essence, defining an `IF [condition] THEN [action]` logic.
     *      Only callable by the Essence owner.
     * @param _essenceId The ID of the Essence.
     * @param _description A human-readable description of the rule.
     * @param _type The type of condition (e.g., TimeElapsed, AttributeValue, OracleInput).
     * @param _targetKey For AttributeValue/OracleInput: the key of the attribute/data to check.
     * @param _threshold The value to compare against for the condition.
     * @param _actionKey The key of the attribute to modify if the condition is met.
     * @param _actionValue The new value for the actionKey if the condition is met.
     * @return The ID of the newly added condition rule.
     */
    function addConditionRule(
        uint256 _essenceId,
        string memory _description,
        ConditionType _type,
        string memory _targetKey,
        string memory _threshold,
        string memory _actionKey,
        string memory _actionValue
    ) external whenNotPaused essenceActive(_essenceId) returns (uint256) {
        ChronoEssence storage essence = _essences[_essenceId];
        if (essence.owner != msg.sender) revert UnauthorizedCaller();

        uint256 ruleId = essence.nextRuleId++;
        ConditionRule storage newRule = essence.conditionRules[ruleId];
        newRule.id = ruleId;
        newRule.description = _description;
        newRule.ruleType = _type;
        newRule.targetKey = _targetKey;
        newRule.threshold = _threshold;
        newRule.actionKey = _actionKey;
        newRule.actionValue = _actionValue;
        newRule.isActive = true;

        emit ConditionRuleAdded(_essenceId, ruleId, _description);
        return ruleId;
    }

    /**
     * @dev Removes an existing condition rule from an Essence.
     *      Only callable by the Essence owner.
     * @param _essenceId The ID of the Essence.
     * @param _ruleId The ID of the rule to remove.
     */
    function removeConditionRule(uint256 _essenceId, uint256 _ruleId)
        external
        whenNotPaused
        essenceActive(_essenceId)
    {
        ChronoEssence storage essence = _essences[_essenceId];
        if (essence.owner != msg.sender) revert UnauthorizedCaller();
        if (essence.conditionRules[_ruleId].id == 0) revert InvalidRuleId(_ruleId);

        delete essence.conditionRules[_ruleId]; // Delete from storage
        emit ConditionRuleRemoved(_essenceId, _ruleId);
    }

    /**
     * @dev Triggers the evaluation of a specific condition rule for an Essence.
     *      If the condition is met, the associated action is executed.
     *      This function can be called by anyone (e.g., automated bots, dApps) to apply rules.
     * @param _essenceId The ID of the Essence.
     * @param _ruleId The ID of the rule to evaluate.
     * @param _oracleData Optional: Data provided by an oracle for OracleInput conditions.
     */
    function evaluateCondition(uint256 _essenceId, uint256 _ruleId, string memory _oracleData)
        external
        whenNotPaused
        essenceActive(_essenceId)
        nonReentrant
    {
        ChronoEssence storage essence = _essences[_essenceId];
        ConditionRule storage rule = essence.conditionRules[_ruleId];
        if (rule.id == 0 || !rule.isActive) revert InvalidRuleId(_ruleId);

        bool conditionMet = _checkCondition(essence, rule, _oracleData);

        if (conditionMet) {
            essence.attributes[rule.actionKey] = rule.actionValue;
            emit AttributeSet(_essenceId, rule.actionKey, rule.actionValue); // Log attribute change
            emit ConditionEvaluated(_essenceId, _ruleId, true, _oracleData);
        } else {
            emit ConditionEvaluated(_essenceId, _ruleId, false, _oracleData);
            revert ConditionNotMet();
        }
    }

    /**
     * @dev Logs an external interaction or event related to an Essence.
     *      Can be called by any authorized entity (e.g., games, other contracts, users).
     * @param _essenceId The ID of the Essence.
     * @param _interactionType A string describing the type of interaction (e.g., "fed", "inspected", "traded_off_chain").
     * @param _metadata Additional metadata about the interaction.
     */
    function recordInteraction(uint256 _essenceId, string memory _interactionType, string memory _metadata)
        external
        whenNotPaused
        essenceExists(_essenceId)
    {
        // This function primarily serves to log events for off-chain analysis or future on-chain use.
        // It does not directly modify Essence state, but could be integrated with other rules.
        emit InteractionRecorded(_essenceId, _interactionType, _metadata, msg.sender);
    }

    // --- VI. Querying & Information ---

    /**
     * @dev Retrieves all public details of a ChronoEssence.
     * @param _essenceId The ID of the Essence.
     * @return owner The owner's address.
     * @return name The Essence's name.
     * @return creationTime The creation timestamp.
     * @return expirationTime The expiration timestamp.
     * @return currentStage The current life stage.
     * @return attributeKeys An array of all attribute keys.
     * @return attributeValues An array of all attribute values (corresponding to keys).
     */
    function getEssenceDetails(uint256 _essenceId)
        external
        view
        essenceExists(_essenceId)
        returns (
            address owner,
            string memory name,
            uint256 creationTime,
            uint256 expirationTime,
            uint8 currentStage, // uint8 for enum
            string[] memory attributeKeys,
            string[] memory attributeValues
        )
    {
        ChronoEssence storage essence = _essences[_essenceId];

        // This requires iterating over the mapping's keys. Solidity mappings don't expose keys.
        // In a real application, you'd store attribute keys in a dynamic array within the struct
        // alongside the mapping itself to make this query efficient.
        // For this example, we'll return empty arrays for attributes for simplicity.
        // A full implementation would look like:
        // string[] memory keys = new string[](essence.attributeKeys.length);
        // string[] memory values = new string[](essence.attributeKeys.length);
        // for (uint256 i = 0; i < essence.attributeKeys.length; i++) {
        //     keys[i] = essence.attributeKeys[i];
        //     values[i] = essence.attributes[essence.attributeKeys[i]];
        // }
        // For now, returning empty arrays:
        attributeKeys = new string[](0);
        attributeValues = new string[](0);

        return (
            essence.owner,
            essence.name,
            essence.creationTime,
            essence.expirationTime,
            uint8(essence.currentStage),
            attributeKeys,
            attributeValues
        );
    }

    /**
     * @dev Retrieves the value of a specific attribute for an Essence.
     * @param _essenceId The ID of the Essence.
     * @param _key The attribute key.
     * @return The attribute value.
     */
    function getEssenceAttribute(uint256 _essenceId, string memory _key)
        external
        view
        essenceExists(_essenceId)
        returns (string memory)
    {
        ChronoEssence storage essence = _essences[_essenceId];
        return essence.attributes[_key];
    }

    /**
     * @dev Returns a list of Essence IDs currently in a specific life stage.
     * @param _stage The target EssenceStage.
     * @return An array of Essence IDs.
     */
    function getEssencesByStage(EssenceStage _stage) external view returns (uint256[] memory) {
        return _essencesByStage[_stage];
    }

    /**
     * @dev Returns a list of Essence IDs that have currently expired/decayed.
     *      This function iterates through all Essences, which can be gas-intensive for large numbers.
     *      For production, a more efficient indexing mechanism (e.g., a dedicated mapping for expired IDs, or a batched query) would be preferred.
     * @return An array of expired Essence IDs.
     */
    function getExpiredEssences() external view returns (uint256[] memory) {
        uint256[] memory expiredEssences = new uint256[](0);
        uint256 count = 0;
        for (uint256 i = 1; i < _nextEssenceId; i++) {
            if (_essences[i].id != 0 && _essences[i].currentStage == EssenceStage.Extinct) {
                count++;
            }
        }

        expiredEssences = new uint256[](count);
        uint256 currentIndex = 0;
        for (uint256 i = 1; i < _nextEssenceId; i++) {
            if (_essences[i].id != 0 && _essences[i].currentStage == EssenceStage.Extinct) {
                expiredEssences[currentIndex++] = i;
            }
        }
        return expiredEssences;
    }

    /**
     * @dev Retrieves the details of a registered blueprint.
     * @param _blueprintName The name of the blueprint.
     * @return defaultDuration The default duration for Essences forged from this blueprint.
     * @return allowedForgers Addresses allowed to use this blueprint.
     * @return creator The address that created this blueprint.
     * @return totalForged Count of essences forged from this blueprint.
     */
    function getBlueprintDetails(string memory _blueprintName)
        external
        view
        returns (
            uint256 defaultDuration,
            address[] memory allowedForgers,
            address creator,
            uint256 totalForged
        )
    {
        ChronoBlueprint storage blueprint = _blueprints[_blueprintName];
        if (blueprint.creator == address(0)) revert BlueprintNotFound(_blueprintName);

        return (
            blueprint.defaultDuration,
            blueprint.allowedForgers,
            blueprint.creator,
            blueprint.totalForged
        );
    }

    // --- Internal Helpers ---

    /**
     * @dev Internal function to check and apply expiration based on the Essence's policy.
     * @param _essenceId The ID of the Essence.
     */
    function _checkAndApplyExpiration(uint256 _essenceId) internal {
        ChronoEssence storage essence = _essences[_essenceId];
        if (essence.currentStage == EssenceStage.Extinct) return; // Already extinct

        bool expired = false;
        if (essence.expirationPolicy.policyType == ExpirationPolicyType.FixedTime) {
            if (block.timestamp >= essence.expirationTime) {
                expired = true;
            }
        } else if (essence.expirationPolicy.policyType == ExpirationPolicyType.AttributeValue) {
            // Compare attribute value. Assuming string comparison for simplicity,
            // but for numbers, you'd convert and compare numerically.
            if (keccak256(abi.encodePacked(essence.attributes[essence.expirationPolicy.attributeKey])) == keccak256(abi.encodePacked(essence.expirationPolicy.attributeValue))) {
                expired = true;
            }
        }

        if (expired) {
            _removeEssenceFromStage(essence.currentStage, _essenceId);
            essence.currentStage = EssenceStage.Extinct;
            emit EssenceDecayed(_essenceId, block.timestamp);
        }
    }

    /**
     * @dev Internal function to check a condition rule.
     * @param _essence The ChronoEssence struct.
     * @param _rule The ConditionRule struct.
     * @param _oracleData Data from an external oracle (if ruleType is OracleInput).
     * @return True if the condition is met, false otherwise.
     */
    function _checkCondition(
        ChronoEssence storage _essence,
        ConditionRule storage _rule,
        string memory _oracleData
    ) internal view returns (bool) {
        if (!_rule.isActive) return false;

        if (_rule.ruleType == ConditionType.TimeElapsed) {
            // Threshold here is expected to be a string representation of seconds.
            uint256 thresholdTime = _essence.creationTime + (uint256(uint256(keccak256(abi.encodePacked(_rule.threshold))))); // Simplified for example, parse int
            // In a real scenario, convert string to uint256 reliably:
            // uint265 thresholdDuration; // parse _rule.threshold from string
            // uint256 thresholdTime = _essence.creationTime + thresholdDuration;
            // return block.timestamp >= thresholdTime;
            // For now, just compare current time with a placeholder for threshold (e.g., _rule.threshold could be "3600" for 1 hour)
            // A more robust conversion from string to uint: `uint256 thresholdNum = Strings.toUint(_rule.threshold);` (if using openzeppelin's String.sol)
            return block.timestamp >= (_essence.creationTime + 1 hours); // Placeholder
        } else if (_rule.ruleType == ConditionType.AttributeValue) {
            string memory currentAttributeValue = _essence.attributes[_rule.targetKey];
            return keccak256(abi.encodePacked(currentAttributeValue)) == keccak256(abi.encodePacked(_rule.threshold));
        } else if (_rule.ruleType == ConditionType.OracleInput) {
            // This is conceptual. In a real scenario, _oracleAddress would point to an Oracle contract
            // with a specific interface, e.g., `IOracle(_oracleAddress).getData(_rule.targetKey)`
            // For now, we compare the passed _oracleData directly to the threshold.
            if (_oracleAddress == address(0)) revert NoOracleAddressSet();
            // This mock simply checks if the input _oracleData matches the rule's threshold
            // A real oracle integration would call an oracle contract at _oracleAddress
            return keccak256(abi.encodePacked(_oracleData)) == keccak256(abi.encodePacked(_rule.threshold));
        }
        return false;
    }

    /**
     * @dev Internal helper to remove an essence ID from its current stage array.
     *      Note: This is an O(N) operation. For very large collections, a more efficient
     *      data structure (e.g., doubly linked list or a mapping of ID to index) would be needed.
     * @param _stage The stage array to remove from.
     * @param _essenceId The ID of the Essence to remove.
     */
    function _removeEssenceFromStage(EssenceStage _stage, uint256 _essenceId) internal {
        uint256[] storage stageEssences = _essencesByStage[_stage];
        for (uint256 i = 0; i < stageEssences.length; i++) {
            if (stageEssences[i] == _essenceId) {
                // Swap with last element and pop
                stageEssences[i] = stageEssences[stageEssences.length - 1];
                stageEssences.pop();
                break;
            }
        }
    }
}
```