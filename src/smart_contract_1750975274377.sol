Okay, let's create a smart contract for a "Dynamic Synthesized Ecosystem". This contract will manage non-standard, dynamically evolving digital entities ("Manifestations") that can be synthesized from ingredients, combined, decay over time, and whose attributes can be influenced by external data (simulated via an oracle callback). Ownership and evolution rules will be subject to a basic on-chain governance mechanism. The Manifestations are initially soul-bound but can become conditionally transferable.

This concept includes:
*   **Dynamic State:** Manifestation attributes change over time or via interactions.
*   **Composability:** Manifestations can be combined.
*   **Conditional Logic:** Transfers and evolution depend on meeting criteria.
*   **Oracle Interaction:** Integration point for external data affecting state.
*   **On-chain Governance:** Rules and parameters can be changed via proposals and voting.
*   **Non-standard Ownership/Transfer:** Not a typical ERC721; uses soul-binding initially, with a custom conditional transfer.
*   **Complex State Transitions:** Synthesis, combination, evolution, and decay involve significant attribute changes.

---

**Outline & Function Summary:**

This contract, `SynthesizedEcosystem`, manages unique digital entities called "Manifestations". Each Manifestation has a dynamic set of attributes that can change based on interactions, time, and external data.

**Core Concepts:**

1.  **Manifestations:** Non-fungible entities with dynamic attributes (`mapping(string => uint256)`). Not standard ERC721.
2.  **Synthesis:** Creating new Manifestations by providing valid ingredient tokens and potentially Ether.
3.  **Evolution:** Manifestations can evolve based on time, attribute values, and defined conditions.
4.  **Combination:** Two Manifestations can be combined into a new or evolved Manifestation.
5.  **Decay:** Manifestations can lose attributes over time if decay is enabled.
6.  **Conditional Transfer:** Manifestations are initially soul-bound but can become transferable if specific conditions are met.
7.  **Oracle Integration:** Placeholder functions for interacting with external data sources to update Manifestation attributes.
8.  **Governance:** On-chain system for proposing and voting on changes to synthesis formulas and evolution conditions.
9.  **Roles:** Admin and Rule Setter roles for system management and initial rule setup.

**Functions Summary (29 functions):**

*   **Initialization & Control:**
    1.  `constructor()`: Sets initial owner and roles.
    2.  `pauseContract()`: Pauses core interactions (creation, evolution, etc.). Only callable by Admin.
    3.  `unpauseContract()`: Unpauses core interactions. Only callable by Admin.
    4.  `setAdmin(address _newAdmin)`: Sets the address with Admin role. Only callable by Owner.
    5.  `setRuleSetter(address _newRuleSetter)`: Sets the address with Rule Setter role. Only callable by Owner.
    6.  `setOracleAddress(address _newOracle)`: Sets the address authorized to call oracle fulfillment. Only callable by Admin.

*   **System Parameters & Rules:**
    7.  `setSynthesisFee(uint256 _fee)`: Sets the Ether fee required for synthesis. Only callable by Rule Setter or Governance.
    8.  `addValidIngredient(address _tokenAddress)`: Adds an ERC20 token address that can be used as an ingredient. Only callable by Rule Setter or Governance.
    9.  `removeValidIngredient(address _tokenAddress)`: Removes an ERC20 token from the valid ingredients list. Only callable by Rule Setter or Governance.
    10. `setSynthesisFormula(uint256 _formulaId, SynthesisFormula calldata _formula)`: Defines or updates a synthesis formula (ingredients required, output attributes). Only callable by Rule Setter or Governance.
    11. `setEvolutionConditions(uint256 _conditionId, EvolutionCondition calldata _condition)`: Defines or updates an evolution condition (criteria, attribute changes). Only callable by Rule Setter or Governance.

*   **Manifestation Management & Interaction:**
    12. `mintBaseManifestation(string memory _initialType)`: Creates a basic Manifestation (e.g., initial seed). Requires fee.
    13. `synthesizeManifestation(uint256 _formulaId, address[] calldata _ingredientTokens, uint256[] calldata _amounts)`: Creates a Manifestation using a defined formula, burning ingredients and paying fee.
    14. `evolveManifestation(uint256 _manifestationId, uint256 _conditionId)`: Attempts to evolve a Manifestation if it meets the specified condition's criteria.
    15. `combineManifestations(uint256 _manifestationId1, uint256 _manifestationId2)`: Combines two Manifestations (burning them) into a new or modified one based on predefined rules.
    16. `decayManifestation(uint256 _manifestationId)`: Applies the decay logic to a Manifestation, reducing attributes based on time since last update/decay. Can be called by anyone to trigger decay, beneficial for the owner.
    17. `updateManifestationFromOracle(uint256 _manifestationId, bytes32 _oracleRequestId, string memory _attributeKey)`: Initiates an oracle request to get external data for a specific attribute of a Manifestation. Requires oracle setup.
    18. `fulfillOracleData(bytes32 _requestId, uint256 _value)`: Callback function from the oracle to update a Manifestation's attribute based on requested external data. Only callable by the designated Oracle address.
    19. `transferManifestationConditional(uint256 _manifestationId, address _to)`: Transfers a Manifestation *only if* it meets predefined conditions (e.g., 'mature', specific attribute value). Initially soul-bound until conditions met.

*   **Governance:**
    20. `proposeRuleChange(bytes memory _callData, string memory _description)`: Creates a new proposal to change a rule (e.g., call `setSynthesisFormula` via governance). Requires owning a Manifestation (simple example).
    21. `voteOnRuleChange(uint256 _proposalId, bool _support)`: Votes on an active rule change proposal. Requires owning a Manifestation.
    22. `executeRuleChange(uint256 _proposalId)`: Executes a proposal that has passed voting and the waiting period.

*   **Utility & Views:**
    23. `withdrawFees(address payable _recipient)`: Allows the owner/admin/governance to withdraw collected Ether fees.
    24. `getManifestationDetails(uint256 _manifestationId)`: Returns comprehensive details of a Manifestation.
    25. `getManifestationAttribute(uint256 _manifestationId, string memory _attributeKey)`: Returns a specific attribute value for a Manifestation.
    26. `getOwnerManifestations(address _owner)`: Returns a list of Manifestation IDs owned by an address. (Note: Tracking this efficiently on-chain for large numbers requires careful data structure design, simple array might gas limit. For this example, we'll use a simple mapping check, which means iterating off-chain is needed, or a separate helper for on-chain lists).
    27. `getSynthesisFormula(uint256 _formulaId)`: Returns details of a specific synthesis formula.
    28. `getEvolutionConditions(uint256 _conditionId)`: Returns details of a specific evolution condition.
    29. `getProposalDetails(uint256 _proposalId)`: Returns details of a governance proposal.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/access/Ownable.sol"; // Using Ownable for base ownership

// Custom errors for clarity
error SynthesizedEcosystem__NotAdmin();
error SynthesizedEcosystem__NotRuleSetter();
error SynthesizedEcosystem__NotOracle();
error SynthesizedEcosystem__Paused();
error SynthesizedEcosystem__NotPaused();
error SynthesizedEcosystem__InsufficientBalance();
error SynthesizedEcosystem__ManifestationNotFound();
error SynthesizedEcosystem__NotManifestationOwner(uint256 _manifestationId, address _owner);
error SynthesizedEcosystem__ManifestationNotEligible(uint256 _manifestationId);
error SynthesizedEcosystem__InvalidIngredient(address _tokenAddress);
error SynthesizedEcosystem__InvalidSynthesisFormula(uint256 _formulaId);
error SynthesizedEcosystem__InvalidEvolutionCondition(uint256 _conditionId);
error SynthesizedEcosystem__InsufficientIngredients();
error SynthesizedEcosystem__SelfTransferDisallowed();
error SynthesizedEcosystem__TransferNotUnlocked(uint256 _manifestationId);
error SynthesizedEcosystem__ManifestationsCannotCombine();
error SynthesizedEcosystem__ProposalNotFound();
error SynthesizedEcosystem__ProposalAlreadyExists(uint256 _proposalId); // Simplified, based on calldata hash maybe
error SynthesizedEcosystem__ProposalNotActive();
error SynthesizedEcosystem__ProposalNotPassed();
error SynthesizedEcosystem__ProposalNotExecutable();
error SynthesizedEcosystem__AlreadyVoted();
error SynthesizedEcosystem__NoVotingPower();
error SynthesizedEcosystem__OracleRequestAlreadyExists(bytes32 _requestId);


// Outline & Function Summary are provided above the code block.

contract SynthesizedEcosystem is Ownable {
    using Address for address;

    // --- Structs ---

    // Represents a single Manifestation entity
    struct Manifestation {
        uint256 id;
        address owner; // Owner address
        string manifestationType; // e.g., "Seed", "Plant", "Crystal"
        uint256 creationTime;
        uint256 lastInteractionTime; // Time of last evolution, combination, decay, etc.
        uint256 decayRate; // Rate at which attributes decay per unit of time (e.g., per day)
        bool transferUnlocked; // Can this manifestation be transferred?
        mapping(string => uint256) attributes; // Dynamic attributes (e.g., "energy", "level", "purity")
        // Note: Mappings within structs cannot be returned entirely by public functions.
        // Specific attribute lookups are needed.
    }

    // Represents a formula for synthesizing a Manifestation
    struct SynthesisFormula {
        mapping(address => uint256) requiredIngredients; // ERC20 token => amount
        uint256 requiredEther;
        string outputManifestationType;
        mapping(string => uint256) initialAttributes; // Initial attributes for the output
        // Note: Mapping restriction applies here too
    }

    // Represents conditions and effects for evolving a Manifestation
    struct EvolutionCondition {
        uint256 minTimeSinceLastInteraction; // Time in seconds
        uint256 minAttributeValue; // Example condition based on a single attribute
        string minAttributeKey; // The key for the attribute to check
        mapping(string => int256) attributeChanges; // Changes to apply (can be negative)
        bool unlockTransferOnEvolution; // Does this evolution unlock transfer?
        string newManifestationType; // Type after evolution (optional)
        // Note: Mapping restriction applies here too
    }

    // Governance proposal state
    enum ProposalState {
        Pending,
        Active,
        Passed,
        Failed,
        Executed
    }

    // Represents a governance proposal
    struct RuleChangeProposal {
        uint256 id;
        bytes callData; // The function call to execute (e.g., setSynthesisFormula)
        string description;
        uint256 creationTime;
        uint256 votingEndTime;
        uint256 executionDelay; // Time after voting ends before executable
        uint256 votesFor;
        uint256 votesAgainst;
        mapping(address => bool) voted; // Address => hasVoted
        ProposalState state;
    }

    // Represents an active oracle request
    struct OracleRequest {
        uint256 manifestationId;
        string attributeKey;
        bool fulfilled;
    }

    // --- State Variables ---

    address private _admin;
    address private _ruleSetter;
    address private _oracleAddress; // Address allowed to call fulfillOracleData

    bool private _paused;
    uint256 private _nextManifestationId;
    uint256 private _synthesisFee; // Ether fee in wei

    mapping(uint256 => Manifestation) private _manifestations;
    mapping(address => uint256[]) private _ownerManifestationsList; // Simple owner tracking (for basic listing, might gas out on large lists)
    mapping(uint256 => address) private _manifestationOwners; // Direct mapping for faster ownership check

    mapping(address => bool) private _validIngredients; // ERC20 addresses allowed for synthesis
    mapping(uint256 => SynthesisFormula) private _synthesisFormulas;
    mapping(uint256 => EvolutionCondition) private _evolutionConditions;

    uint256 private _nextProposalId;
    mapping(uint256 => RuleChangeProposal) private _proposals;
    uint256 private _votingPeriod = 3 days; // Default voting duration
    uint256 private _executionDelay = 1 days; // Default delay after voting

    mapping(bytes32 => OracleRequest) private _oracleRequests; // Track active oracle requests

    // --- Events ---

    event Paused(address account);
    event Unpaused(address account);
    event AdminSet(address oldAdmin, address newAdmin);
    event RuleSetterSet(address oldRuleSetter, address newRuleSetter);
    event OracleAddressSet(address oldOracle, address newOracle);

    event SynthesisFeeSet(uint256 oldFee, uint256 newFee);
    event ValidIngredientAdded(address tokenAddress);
    event ValidIngredientRemoved(address tokenAddress);
    event SynthesisFormulaSet(uint256 formulaId);
    event EvolutionConditionSet(uint256 conditionId);

    event ManifestationMinted(uint256 indexed id, address indexed owner, string manifestationType, uint256 creationTime);
    event ManifestationEvolved(uint256 indexed id, uint256 conditionId, string newType);
    event ManifestationCombined(uint256 indexed id1, uint256 indexed id2, uint256 indexed newId); // newId could be 0 if they combine into one of the originals
    event ManifestationDecayed(uint256 indexed id);
    event ManifestationAttributeUpdated(uint256 indexed id, string attributeKey, uint256 newValue);
    event ManifestationTransferUnlocked(uint256 indexed id);
    event ManifestationTransferredConditional(uint256 indexed id, address indexed from, address indexed to);
    event ManifestationBurned(uint256 indexed id, address indexed owner);

    event OracleRequested(uint256 indexed manifestationId, bytes32 indexed requestId, string attributeKey);
    event OracleFulfilled(bytes32 indexed requestId, uint256 value, uint256 indexed manifestationId, string attributeKey);

    event ProposalCreated(uint256 indexed proposalId, address indexed proposer, string description);
    event Voted(uint256 indexed proposalId, address indexed voter, bool support);
    event ProposalStateChanged(uint256 indexed proposalId, ProposalState newState);
    event ProposalExecuted(uint256 indexed proposalId);

    // --- Modifiers ---

    modifier onlyAdmin() {
        if (msg.sender != _admin) revert SynthesizedEcosystem__NotAdmin();
        _;
    }

    modifier onlyRuleSetter() {
        if (msg.sender != _ruleSetter) revert SynthesizedEcosystem__NotRuleSetter();
        _;
    }

    modifier onlyOracle() {
        if (msg.sender != _oracleAddress) revert SynthesizedEcosystem__NotOracle();
        _;
    }

    modifier whenNotPaused() {
        if (_paused) revert SynthesizedEcosystem__Paused();
        _;
    }

    modifier whenPaused() {
        if (!_paused) revert SynthesizedEcosystem__NotPaused();
        _;
    }

    modifier manifestationExists(uint256 _manifestationId) {
        if (_manifestationOwners[_manifestationId] == address(0)) revert SynthesizedEcosystem__ManifestationNotFound();
        _;
    }

    // --- Constructor ---

    constructor(address initialAdmin, address initialRuleSetter) Ownable(msg.sender) {
        _admin = initialAdmin;
        _ruleSetter = initialRuleSetter;
        _paused = false;
        _nextManifestationId = 1;
        _nextProposalId = 1;
        _synthesisFee = 0; // Should be set later via admin/governance
    }

    // --- Initialization & Control (6 functions) ---

    function pauseContract() external onlyAdmin whenNotPaused {
        _paused = true;
        emit Paused(msg.sender);
    }

    function unpauseContract() external onlyAdmin whenPaused {
        _paused = false;
        emit Unpaused(msg.sender);
    }

    function setAdmin(address _newAdmin) external onlyOwner {
        address oldAdmin = _admin;
        _admin = _newAdmin;
        emit AdminSet(oldAdmin, _newAdmin);
    }

    function setRuleSetter(address _newRuleSetter) external onlyOwner {
        address oldRuleSetter = _ruleSetter;
        _ruleSetter = _newRuleSetter;
        emit RuleSetterSet(oldRuleSetter, _newRuleSetter);
    }

    function setOracleAddress(address _newOracle) external onlyAdmin {
        address oldOracle = _oracleAddress;
        _oracleAddress = _newOracle;
        emit OracleAddressSet(oldOracle, _newOracle);
    }

    // --- System Parameters & Rules (5 functions) ---

    function setSynthesisFee(uint256 _fee) external onlyRuleSetter whenNotPaused { // Can later be called by Governance
        uint256 oldFee = _synthesisFee;
        _synthesisFee = _fee;
        emit SynthesisFeeSet(oldFee, _fee);
    }

    function addValidIngredient(address _tokenAddress) external onlyRuleSetter whenNotPaused { // Can later be called by Governance
        _validIngredients[_tokenAddress] = true;
        emit ValidIngredientAdded(_tokenAddress);
    }

    function removeValidIngredient(address _tokenAddress) external onlyRuleSetter whenNotPaused { // Can later be called by Governance
        _validIngredients[_tokenAddress] = false;
        emit ValidIngredientRemoved(_tokenAddress);
    }

    // Note: Setting complex structs like formulas/conditions via external calls
    // requires careful encoding (e.g., using abi.encode or passing separate arrays).
    // For simplicity in this example, we'll use a basic representation.
    // A more robust system might use a factory contract or a library for complex types.
    // Here, we'll use mappings within the structs, which means view functions can't return the full struct easily.
    // Setters will require separate inputs for mapping elements.

    struct IngredientRequirement {
        address tokenAddress;
        uint256 amount;
    }

    struct InitialAttribute {
        string key;
        uint256 value;
    }

    // Function 10: Set Synthesis Formula
    function setSynthesisFormula(
        uint256 _formulaId,
        IngredientRequirement[] calldata _requiredIngredients,
        uint256 _requiredEther,
        string calldata _outputManifestationType,
        InitialAttribute[] calldata _initialAttributes
    ) external onlyRuleSetter whenNotPaused { // Can later be called by Governance
        SynthesisFormula storage formula = _synthesisFormulas[_formulaId];
        // Clear previous ingredients
        delete formula.requiredIngredients;
        for (uint i = 0; i < _requiredIngredients.length; i++) {
             if (!_validIngredients[_requiredIngredients[i].tokenAddress]) {
                 revert SynthesizedEcosystem__InvalidIngredient(_requiredIngredients[i].tokenAddress);
             }
            formula.requiredIngredients[_requiredIngredients[i].tokenAddress] = _requiredIngredients[i].amount;
        }
        formula.requiredEther = _requiredEther;
        formula.outputManifestationType = _outputManifestationType;

        // Clear previous attributes
        // Note: Clearing mapping attributes inside a struct is tricky. A common pattern
        // is to store attributes in a separate mapping: mapping(uint256 => mapping(string => uint256)) manifestationAttributes;
        // Let's proceed with the struct mapping but acknowledge this limitation for clearing/full reading.
        // For setting, we just overwrite.
        for (uint i = 0; i < _initialAttributes.length; i++) {
            formula.initialAttributes[_initialAttributes[i].key] = _initialAttributes[i].value;
        }

        emit SynthesisFormulaSet(_formulaId);
    }

    struct AttributeChange {
        string key;
        int256 change; // Use int256 to allow negative changes (reduction)
    }

    // Function 11: Set Evolution Conditions
    function setEvolutionConditions(
        uint256 _conditionId,
        uint256 _minTimeSinceLastInteraction,
        uint256 _minAttributeValue,
        string calldata _minAttributeKey,
        AttributeChange[] calldata _attributeChanges,
        bool _unlockTransferOnEvolution,
        string calldata _newManifestationType
    ) external onlyRuleSetter whenNotPaused { // Can later be called by Governance
        EvolutionCondition storage condition = _evolutionConditions[_conditionId];
        condition.minTimeSinceLastInteraction = _minTimeSinceLastInteraction;
        condition.minAttributeValue = _minAttributeValue;
        condition.minAttributeKey = _minAttributeKey;

        // Clear previous attribute changes (mapping limitation applies)
        for (uint i = 0; i < _attributeChanges.length; i++) {
            condition.attributeChanges[_attributeChanges[i].key] = _attributeChanges[i].change;
        }

        condition.unlockTransferOnEvolution = _unlockTransferOnEvolution;
        condition.newManifestationType = _newManifestationType;

        emit EvolutionConditionSet(_conditionId);
    }


    // --- Manifestation Management & Interaction (8 functions) ---

    // Function 12: Mint a simple base Manifestation
    function mintBaseManifestation(string memory _initialType) external payable whenNotPaused {
        if (msg.value < _synthesisFee) revert SynthesizedEcosystem__InsufficientBalance();

        _createManifestation(msg.sender, _initialType);

        // Potentially add some base attributes here
        Manifestation storage newManifestation = _manifestations[_nextManifestationId - 1];
        newManifestation.attributes["energy"] = 100;
        newManifestation.attributes["level"] = 1;
        newManifestation.decayRate = 10; // Example decay rate

        // Ether fee is automatically sent to contract balance
    }

    // Function 13: Synthesize a Manifestation using ingredients and fee
    function synthesizeManifestation(
        uint256 _formulaId,
        address[] calldata _ingredientTokens,
        uint256[] calldata _amounts
    ) external payable whenNotPaused {
        if (msg.value < _synthesisFee) revert SynthesizedEcosystem__InsufficientBalance();
        if (_ingredientTokens.length != _amounts.length) revert SynthesizedEcosystem__InsufficientIngredients(); // Simple check

        SynthesisFormula storage formula = _synthesisFormulas[_formulaId];
        if (bytes(formula.outputManifestationType).length == 0) revert SynthesizedEcosystem__InvalidSynthesisFormula(_formulaId);

        if (msg.value < formula.requiredEther) revert SynthesizedEcosystem__InsufficientBalance();

        // Check and burn ingredients
        for (uint i = 0; i < _ingredientTokens.length; i++) {
            address token = _ingredientTokens[i];
            uint256 amount = _amounts[i];

            if (!_validIngredients[token]) revert SynthesizedEcosystem__InvalidIngredient(token);
            if (formula.requiredIngredients[token] > amount) revert SynthesizedEcosystem__InsufficientIngredients();

            // Require allowance and transferFrom
            IERC20 ingredientToken = IERC20(token);
            bool success = ingredientToken.transferFrom(msg.sender, address(this), amount);
            if (!success) revert SynthesizedEcosystem__InsufficientIngredients(); // More specific error needed in production
            // Note: Tokens are transferred to the contract, effectively 'burned' for the user's purpose.
            // A more advanced system might require transferring to a burn address or using Permit.
        }

        // Create the manifestation based on the formula
        uint256 newId = _createManifestation(msg.sender, formula.outputManifestationType);
        Manifestation storage newManifestation = _manifestations[newId];

        // Set initial attributes from formula (Mapping limitation applies here too)
        // This loop needs to iterate keys, which is not directly supported for mappings.
        // A better design would store attributes in a list or external mapping.
        // Simulating attribute setting:
        // For example purposes, assume formula.initialAttributes has a known set of keys
        // and we iterate over a list of common attribute keys.
        string[] memory commonAttributeKeys = new string[](2); // Example: just 'energy', 'level'
        commonAttributeKeys[0] = "energy";
        commonAttributeKeys[1] = "level";

        for(uint i = 0; i < commonAttributeKeys.length; i++) {
            string memory key = commonAttributeKeys[i];
             // This assumes initialAttributes mapping was populated correctly by setSynthesisFormula
            newManifestation.attributes[key] = formula.initialAttributes[key];
        }

        // Set base decay rate if not set by formula
        if (newManifestation.decayRate == 0) {
             newManifestation.decayRate = 10; // Default
        }

        // Ether fee is automatically sent to contract balance
    }

    // Function 14: Evolve a Manifestation based on conditions
    function evolveManifestation(uint256 _manifestationId, uint256 _conditionId) external whenNotPaused manifestationExists(_manifestationId) {
        Manifestation storage manifestation = _manifestations[_manifestationId];
        if (manifestation.owner != msg.sender) revert SynthesizedEcosystem__NotManifestationOwner(_manifestationId, msg.sender);

        EvolutionCondition storage condition = _evolutionConditions[_conditionId];
        if (bytes(condition.minAttributeKey).length == 0) revert SynthesizedEcosystem__InvalidEvolutionCondition(_conditionId);

        // Check conditions
        if (block.timestamp < manifestation.lastInteractionTime + condition.minTimeSinceLastInteraction) {
            revert SynthesizedEcosystem__ManifestationNotEligible(_manifestationId);
        }
        if (manifestation.attributes[condition.minAttributeKey] < condition.minAttributeValue) {
             revert SynthesizedEcosystem__ManifestationNotEligible(_manifestationId);
        }

        // Apply attribute changes (Mapping limitation applies)
        // Simulate iterating through potential attribute keys
        string[] memory commonAttributeKeys = new string[](3); // Example: 'energy', 'level', 'purity'
        commonAttributeKeys[0] = "energy";
        commonAttributeKeys[1] = "level";
        commonAttributeKeys[2] = "purity";

        for(uint i = 0; i < commonAttributeKeys.length; i++) {
            string memory key = commonAttributeKeys[i];
            int256 change = condition.attributeChanges[key];
             // Ensure attribute doesn't go negative
             if (change < 0 && uint256(-change) > manifestation.attributes[key]) {
                 manifestation.attributes[key] = 0;
             } else {
                manifestation.attributes[key] = uint256(int256(manifestation.attributes[key]) + change);
             }
             emit ManifestationAttributeUpdated(_manifestationId, key, manifestation.attributes[key]);
        }


        // Update type if specified
        if (bytes(condition.newManifestationType).length > 0) {
            manifestation.manifestationType = condition.newManifestationType;
        }

        // Unlock transfer if applicable
        if (condition.unlockTransferOnEvolution && !manifestation.transferUnlocked) {
            manifestation.transferUnlocked = true;
            emit ManifestationTransferUnlocked(_manifestationId);
        }

        manifestation.lastInteractionTime = block.timestamp;
        emit ManifestationEvolved(_manifestationId, _conditionId, manifestation.manifestationType);
    }

    // Function 15: Combine two Manifestations
    function combineManifestations(uint256 _manifestationId1, uint256 _manifestationId2) external whenNotPaused manifestationExists(_manifestationId1) manifestationExists(_manifestationId2) {
        Manifestation storage m1 = _manifestations[_manifestationId1];
        Manifestation storage m2 = _manifestations[_manifestationId2];

        if (m1.owner != msg.sender) revert SynthesizedEcosystem__NotManifestationOwner(_manifestationId1, msg.sender);
        if (m2.owner != msg.sender) revert SynthesizedEcosystem__NotManifestationOwner(_manifestationId2, msg.sender);
        if (_manifestationId1 == _manifestationId2) revert SynthesizedEcosystem__ManifestationsCannotCombine(); // Cannot combine with self

        // --- Combination Logic (Advanced/Complex Example) ---
        // This is a simplified placeholder. Real logic would involve:
        // 1. Checking compatibility (e.g., types, attributes meet criteria).
        // 2. Defining output (new manifestation vs. one evolving).
        // 3. Defining how attributes combine (sum, average, merge, weighted average, new calculation).
        // 4. Defining decay/interaction time for the resulting manifestation.

        // Example: Simple merge - Burn both, create a new one with combined attributes
        uint256 newId = _createManifestation(msg.sender, "CombinedManifestation");
        Manifestation storage newManifestation = _manifestations[newId];

        // Simulate attribute combination (Mapping limitation applies)
        string[] memory commonAttributeKeys = new string[](3); // Example: 'energy', 'level', 'purity'
        commonAttributeKeys[0] = "energy";
        commonAttributeKeys[1] = "level";
        commonAttributeKeys[2] = "purity";

        for(uint i = 0; i < commonAttributeKeys.length; i++) {
            string memory key = commonAttributeKeys[i];
            newManifestation.attributes[key] = m1.attributes[key] + m2.attributes[key]; // Simple sum
        }
        newManifestation.decayRate = (m1.decayRate + m2.decayRate) / 2; // Average decay

        _burnManifestation(_manifestationId1);
        _burnManifestation(_manifestationId2);

        emit ManifestationCombined(_manifestationId1, _manifestationId2, newId);
    }

    // Function 16: Apply decay logic
    function decayManifestation(uint256 _manifestationId) external whenNotPaused manifestationExists(_manifestationId) {
        Manifestation storage manifestation = _manifestations[_manifestationId];

        uint256 timeElapsed = block.timestamp - manifestation.lastInteractionTime;
        if (timeElapsed == 0 || manifestation.decayRate == 0) {
            // No time elapsed or no decay rate set
            return;
        }

        uint256 decayAmount = (timeElapsed / (1 days)) * manifestation.decayRate; // Example: Decay per day

        // Apply decay to relevant attributes (Mapping limitation applies)
         string[] memory decayableAttributeKeys = new string[](2); // Example: 'energy', 'purity'
        decayableAttributeKeys[0] = "energy";
        decayableAttributeKeys[1] = "purity";

        for(uint i = 0; i < decayableAttributeKeys.length; i++) {
            string memory key = decayableAttributeKeys[i];
            if (manifestation.attributes[key] > 0) {
                uint256 currentAttribute = manifestation.attributes[key];
                uint256 newAttribute = currentAttribute > decayAmount ? currentAttribute - decayAmount : 0;
                manifestation.attributes[key] = newAttribute;
                 emit ManifestationAttributeUpdated(_manifestationId, key, newAttribute);
            }
        }

        manifestation.lastInteractionTime = block.timestamp;
        emit ManifestationDecayed(_manifestationId);
    }


    // Function 17: Initiate oracle request for attribute update
    function updateManifestationFromOracle(uint256 _manifestationId, bytes32 _oracleRequestId, string memory _attributeKey) external whenNotPaused manifestationExists(_manifestationId) {
        Manifestation storage manifestation = _manifestations[_manifestationId];
        if (manifestation.owner != msg.sender) revert SynthesizedEcosystem__NotManifestationOwner(_manifestationId, msg.sender);
        if (_oracleRequests[_oracleRequestId].manifestationId != 0) revert SynthesizedEcosystem__OracleRequestAlreadyExists(_oracleRequestId); // Check if request ID is unique/available

        // In a real Chainlink integration, this would call Chainlink.request...
        // For this example, we just record the request pending fulfillment.
        _oracleRequests[_oracleRequestId] = OracleRequest({
            manifestationId: _manifestationId,
            attributeKey: _attributeKey,
            fulfilled: false
        });

        emit OracleRequested(_manifestationId, _oracleRequestId, _attributeKey);

        // Note: Actual oracle interaction (like Chainlink VRF or Data Feeds)
        // requires inheriting specific Chainlink contracts and managing LINK tokens/fees.
        // This is a simplified representation of the *interface* needed.
    }

    // Function 18: Oracle callback to fulfill request
    function fulfillOracleData(bytes32 _requestId, uint256 _value) external onlyOracle whenNotPaused {
        OracleRequest storage req = _oracleRequests[_requestId];
        if (req.manifestationId == 0 || req.fulfilled) {
            // Request not found or already fulfilled (basic check)
            return; // Or revert with a specific error
        }

        Manifestation storage manifestation = _manifestations[req.manifestationId];
        // Apply the oracle value to the attribute
        manifestation.attributes[req.attributeKey] = _value;
        emit ManifestationAttributeUpdated(req.manifestationId, req.attributeKey, _value);
        emit OracleFulfilled(_requestId, _value, req.manifestationId, req.attributeKey);

        req.fulfilled = true; // Mark as fulfilled
        // Potentially delete the request to save gas, but needs careful handling
        // delete _oracleRequests[_requestId];
    }

    // Function 19: Transfer a Manifestation conditionally
    function transferManifestationConditional(uint256 _manifestationId, address _to) external whenNotPaused manifestationExists(_manifestationId) {
        Manifestation storage manifestation = _manifestations[_manifestationId];
        if (manifestation.owner != msg.sender) revert SynthesizedEcosystem__NotManifestationOwner(_manifestationId, msg.sender);
        if (msg.sender == _to) revert SynthesizedEcosystem__SelfTransferDisallowed();

        // Check transfer condition - Requires 'transferUnlocked' flag to be true
        if (!manifestation.transferUnlocked) {
            // Could add other conditions here too, e.g., manifestation.attributes["level"] >= 10
             revert SynthesizedEcosystem__TransferNotUnlocked(_manifestationId);
        }

        // Perform the transfer
        address oldOwner = manifestation.owner;
        _removeManifestationFromOwnerList(oldOwner, _manifestationId); // Simple list management
        _addManifestationToOwnerList(_to, _manifestationId); // Simple list management
        manifestation.owner = _to;
        _manifestationOwners[_manifestationId] = _to; // Update direct owner mapping

        emit ManifestationTransferredConditional(_manifestationId, oldOwner, _to);
    }


    // --- Governance (3 functions) ---

    // Function 20: Propose a rule change
    function proposeRuleChange(bytes memory _callData, string memory _description) external whenNotPaused {
        // Simple voting power: requires owning at least one Manifestation
        uint256[] memory ownerManifestations = getOwnerManifestations(msg.sender);
        if (ownerManifestations.length == 0) revert SynthesizedEcosystem__NoVotingPower();

        uint256 proposalId = _nextProposalId++;
        RuleChangeProposal storage proposal = _proposals[proposalId];

        proposal.id = proposalId;
        proposal.callData = _callData;
        proposal.description = _description;
        proposal.creationTime = block.timestamp;
        proposal.votingEndTime = block.timestamp + _votingPeriod;
        proposal.executionDelay = _executionDelay; // Delay after voting ends
        proposal.state = ProposalState.Active;

        emit ProposalCreated(proposalId, msg.sender, _description);
    }

    // Function 21: Vote on a proposal
    function voteOnRuleChange(uint256 _proposalId, bool _support) external whenNotPaused {
        RuleChangeProposal storage proposal = _proposals[_proposalId];
        if (proposal.state != ProposalState.Active) revert SynthesizedEcosystem__ProposalNotActive();
        if (block.timestamp > proposal.votingEndTime) revert SynthesizedEcosystem__ProposalNotActive(); // Voting period ended

        // Simple voting power: requires owning at least one Manifestation
        uint256[] memory ownerManifestations = getOwnerManifestations(msg.sender);
        if (ownerManifestations.length == 0) revert SynthesizedEcosystem__NoVotingPower();
        if (proposal.voted[msg.sender]) revert SynthesizedEcosystem__AlreadyVoted();

        // Voting weight could be based on number of manifestations, attribute values, etc.
        // Simple weight: 1 vote per voter who owns at least one manifestation
        if (_support) {
            proposal.votesFor++;
        } else {
            proposal.votesAgainst++;
        }

        proposal.voted[msg.sender] = true;
        emit Voted(_proposalId, msg.sender, _support);

        // Automatically transition state if voting ends or threshold met (simplified)
        // More complex logic needed for thresholds and quorum
         if (block.timestamp >= proposal.votingEndTime) {
            _evaluateProposal(_proposalId);
         }
    }

    // Function 22: Execute a passed proposal
    function executeRuleChange(uint256 _proposalId) external whenNotPaused {
        RuleChangeProposal storage proposal = _proposals[_proposalId];
        if (proposal.state != ProposalState.Passed) revert SynthesizedEcosystem__ProposalNotPassed();
        if (block.timestamp < proposal.votingEndTime + proposal.executionDelay) revert SynthesizedEcosystem__ProposalNotExecutable();

        // Execute the callData (e.g., call setSynthesisFormula)
        // Ensure the target address and function signature are handled correctly
        // This requires careful crafting of `callData` when proposing
        (bool success, ) = address(this).call(proposal.callData);

        if (success) {
            proposal.state = ProposalState.Executed;
            emit ProposalExecuted(_proposalId);
        } else {
             // Handle execution failure (e.g., log error, change state to Failed/ExecutionFailed)
             // For simplicity, we'll just revert here.
             revert("SynthesizedEcosystem: Proposal execution failed");
        }
    }


    // --- Utility & Views (7 functions) ---

    // Function 23: Withdraw collected fees
    function withdrawFees(address payable _recipient) external onlyOwner { // Or Governance
        uint256 balance = address(this).balance;
        if (balance > 0) {
            _recipient.transfer(balance);
        }
    }

    // Function 24: Get Manifestation details
    function getManifestationDetails(uint256 _manifestationId)
        external
        view
        manifestationExists(_manifestationId)
        returns (
            uint256 id,
            address owner,
            string memory manifestationType,
            uint256 creationTime,
            uint256 lastInteractionTime,
            uint256 decayRate,
            bool transferUnlocked
            // Note: Cannot return the full attributes mapping here
        )
    {
        Manifestation storage m = _manifestations[_manifestationId];
        return (
            m.id,
            m.owner,
            m.manifestationType,
            m.creationTime,
            m.lastInteractionTime,
            m.decayRate,
            m.transferUnlocked
        );
    }

     // Function 25: Get a specific Manifestation attribute
     function getManifestationAttribute(uint256 _manifestationId, string memory _attributeKey)
        external
        view
        manifestationExists(_manifestationId)
        returns (uint256)
     {
         return _manifestations[_manifestationId].attributes[_attributeKey];
     }


    // Function 26: Get Manifestations owned by an address (simplified)
    function getOwnerManifestations(address _owner) external view returns (uint256[] memory) {
        // This is a simple implementation. For a large number of manifestations,
        // iterating this array or returning it could hit gas limits.
        // A better approach involves external indexing or mapping `owner => mapping => bool` check
        // combined with event logging for off-chain indexing.
        // For this example, we'll just iterate and check the owner mapping.
        // This function is mainly useful for clients querying owned IDs.

        uint256[] memory ownedIds;
        uint256 count = 0;
        // Need to iterate through _manifestationOwners keys, which is not efficient
        // Let's rely on the _ownerManifestationsList for *approximate* list (needs maintenance)
        // Simulating return from the simple list:
        return _ownerManifestationsList[_owner]; // Warning: This list needs proper adding/removing in _create and _burn/_transfer functions.
    }

    // Function 27: Get Synthesis Formula details (Partial view due to mapping limitations)
    function getSynthesisFormula(uint256 _formulaId)
        external
        view
        returns (
            uint256 requiredEther,
            string memory outputManifestationType
            // Cannot return the full requiredIngredients or initialAttributes mappings
        )
    {
         SynthesisFormula storage formula = _synthesisFormulas[_formulaId];
         return (formula.requiredEther, formula.outputManifestationType);
    }

    // Function 28: Get Evolution Condition details (Partial view due to mapping limitations)
    function getEvolutionConditions(uint256 _conditionId)
        external
        view
        returns (
            uint256 minTimeSinceLastInteraction,
            uint256 minAttributeValue,
            string memory minAttributeKey,
            bool unlockTransferOnEvolution,
            string memory newManifestationType
            // Cannot return the full attributeChanges mapping
        )
    {
        EvolutionCondition storage condition = _evolutionConditions[_conditionId];
        return (
            condition.minTimeSinceLastInteraction,
            condition.minAttributeValue,
            condition.minAttributeKey,
            condition.unlockTransferOnEvolution,
            condition.newManifestationType
        );
    }

    // Function 29: Get Governance Proposal details
    function getProposalDetails(uint256 _proposalId)
        external
        view
        returns (
            uint256 id,
            bytes memory callData,
            string memory description,
            uint256 creationTime,
            uint256 votingEndTime,
            uint256 executionDelay,
            uint256 votesFor,
            uint256 votesAgainst,
            ProposalState state
            // Cannot return the 'voted' mapping
        )
    {
        RuleChangeProposal storage proposal = _proposals[_proposalId];
        if (proposal.id == 0 && _proposalId != 0) revert SynthesizedEcosystem__ProposalNotFound(); // Basic check

        return (
            proposal.id,
            proposal.callData,
            proposal.description,
            proposal.creationTime,
            proposal.votingEndTime,
            proposal.executionDelay,
            proposal.votesFor,
            proposal.votesAgainst,
            proposal.state
        );
    }


    // --- Internal Helper Functions ---

    // Internal function to create a new manifestation
    function _createManifestation(address _owner, string memory _type) internal returns (uint256) {
        uint256 newId = _nextManifestationId++;
        Manifestation storage newManifestation = _manifestations[newId];

        newManifestation.id = newId;
        newManifestation.owner = _owner;
        newManifestation.manifestationType = _type;
        newManifestation.creationTime = block.timestamp;
        newManifestation.lastInteractionTime = block.timestamp;
        newManifestation.decayRate = 0; // Default, can be set later
        newManifestation.transferUnlocked = false; // Soul-bound by default

        _manifestationOwners[newId] = _owner; // Direct owner mapping
        _addManifestationToOwnerList(_owner, newId); // Simple list tracking

        emit ManifestationMinted(newId, _owner, _type, block.timestamp);
        return newId;
    }

    // Internal function to burn a manifestation
    function _burnManifestation(uint256 _manifestationId) internal manifestationExists(_manifestationId) {
        address owner = _manifestationOwners[_manifestationId];
        // Remove from simple owner list (Needs implementation)
         _removeManifestationFromOwnerList(owner, _manifestationId);

        // Clear the manifestation data (Mapping limitation - attributes not fully cleared easily)
        delete _manifestations[_manifestationId];
        delete _manifestationOwners[_manifestationId]; // Remove from direct owner mapping

        emit ManifestationBurned(_manifestationId, owner);
    }

    // Internal helper for basic owner list management (simplified, gas considerations apply)
    function _addManifestationToOwnerList(address _owner, uint256 _manifestationId) internal {
        // Find if the ID already exists (shouldn't if logic is correct, but safe check)
        bool found = false;
        for (uint i = 0; i < _ownerManifestationsList[_owner].length; i++) {
            if (_ownerManifestationsList[_owner][i] == _manifestationId) {
                found = true;
                break;
            }
        }
        if (!found) {
             _ownerManifestationsList[_owner].push(_manifestationId);
        }
    }

    // Internal helper for basic owner list management (simplified, gas considerations apply)
    function _removeManifestationFromOwnerList(address _owner, uint256 _manifestationId) internal {
        // Find and remove the ID
        for (uint i = 0; i < _ownerManifestationsList[_owner].length; i++) {
            if (_ownerManifestationsList[_owner][i] == _manifestationId) {
                // Replace the found ID with the last element and pop the last element
                _ownerManifestationsList[_owner][i] = _ownerManifestationsList[_owner][_ownerManifestationsList[_owner].length - 1];
                _ownerManifestationsList[_owner].pop();
                break; // Found and removed
            }
        }
    }


    // Internal function to evaluate a proposal's state after voting ends
    function _evaluateProposal(uint256 _proposalId) internal {
        RuleChangeProposal storage proposal = _proposals[_proposalId];
        if (proposal.state != ProposalState.Active || block.timestamp < proposal.votingEndTime) {
            return; // Not the right time or state
        }

        // Simple majority rule: more 'for' votes than 'against'
        if (proposal.votesFor > proposal.votesAgainst) {
            proposal.state = ProposalState.Passed;
        } else {
            proposal.state = ProposalState.Failed;
        }
        emit ProposalStateChanged(_proposalId, proposal.state);
    }


    // Fallback function to receive Ether
    receive() external payable {
        // Ether sent directly to the contract is collected as fees
    }

    // Optional: Add a fallback function to handle incorrect calls
    // fallback() external payable {
    //     // Handle calls to unknown functions or unexpected Ether
    //     revert("SynthesizedEcosystem: Invalid call");
    // }
}
```