This smart contract, "QuantumLeap Protocol," introduces a novel concept of **AI-driven dynamic digital personas (Quantum Personas)** represented as NFTs. These personas are designed to evolve based on verified off-chain computation (simulated AI oracle calls) and interact within unique, temporary multi-persona "Quantum States." It incorporates ideas of reputation, soulbound optionality, and a catalyst-driven economy.

---

## QuantumLeap Protocol: Contract Outline and Function Summary

**Protocol Name:** QuantumLeap Protocol

**Concept:** The QuantumLeap Protocol enables the creation, evolution, and interaction of "Quantum Personas" – unique, dynamic digital entities represented as ERC721 NFTs. Each persona possesses a DNA hash, an evolution level, and a reputation score, all of which can be modified by verified off-chain AI analysis and interactions within communal "Quantum States." The protocol simulates advanced AI integration through a designated "Oracle" role, allowing personas to undergo transformative "evolutions" or collectively resolve complex scenarios within a "Quantum State," leading to dynamic updates in their attributes and reputation.

**Key Features:**
*   **Dynamic NFTs (Quantum Personas):** Personas are NFTs whose attributes (name, traits, evolution level, reputation) can change over time.
*   **AI Oracle Integration:** Leverages a designated oracle address (simulating an AI inference layer) to perform complex computations (e.g., DNA analysis for evolution, scenario resolution for Quantum States).
*   **Reputation System:** Each persona maintains a reputation score that can increase or decrease based on verified interactions and evolution outcomes, with a built-in decay mechanism.
*   **Quantum States:** Temporary, multi-persona interaction environments where personas can collaborate or compete on a shared objective, with an AI-driven resolution.
*   **Soulbound Optionality:** Personas can be optionally made non-transferable (soulbound) by their owner, or globally restricted by the contract owner.
*   **Catalyst Economy:** Fees paid in native currency (ETH/MATIC/etc.) for initiating evolutions or Quantum States, funding the oracle operations or protocol development.

**Core Entities:**

*   **`QuantumPersona` Struct:**
    *   `owner`: The address that owns the persona NFT.
    *   `tokenId`: Unique identifier for the persona.
    *   `name`: Human-readable name of the persona.
    *   `dnaHash`: A bytes32 hash representing the core, evolving genetic code or base characteristics.
    *   `evolutionLevel`: Current evolutionary stage, increases with successful evolutions.
    *   `reputationScore`: An integer score reflecting the persona's standing (can be negative).
    *   `lastStimulusTimestamp`: Timestamp of the last significant update or interaction.
    *   `currentQuantumStateId`: The ID of the Quantum State the persona is currently participating in (0 if none).
    *   `isSoulbound`: Boolean indicating if the persona is non-transferable.
    *   `traits`: A mapping of string keys to string values, representing dynamic attributes.

*   **`QuantumState` Struct:**
    *   `stateId`: Unique identifier for the Quantum State.
    *   `initiator`: Address of the user who initiated this state.
    *   `involvedPersonas`: An array of `tokenId`s of personas participating.
    *   `creationTimestamp`: When the state was initiated.
    *   `expirationTimestamp`: When the state automatically concludes if not resolved.
    *   `stateInputHash`: A bytes32 hash of the initial data/problem for the state.
    *   `resolvedOutcomeHash`: A bytes32 hash of the AI-determined outcome data.
    *   `status`: An enum representing the current phase of the state (Active, PendingResolution, Resolved, Expired).
    *   `catalystFeePaid`: The fee paid to initiate this state.

*   **`OracleRequest` Struct:**
    *   `requestId`: Unique identifier for the oracle request.
    *   `personaId`: The tokenId of the persona involved (if any).
    *   `callbackFunction`: The function selector for the callback after oracle fulfillment.
    *   `requester`: The address that made the request.
    *   `inputHash`: Hash of the data sent to the oracle.
    *   `fulfilled`: Boolean indicating if the request has been fulfilled.

**Function Summary (25 Functions):**

1.  **`constructor(address initialOracleAddress)`:** Initializes the contract, setting the initial owner and the trusted oracle address.
2.  **`setCatalystFee(uint256 _newFee)`:** Allows the contract owner to update the `catalystFee` required for certain operations.
3.  **`setOracleAddress(address _newOracleAddress)`:** Allows the contract owner to change the trusted oracle address.
4.  **`toggleSoulboundGlobal(bool _enabled)`:** Toggles the global ability for personas to be made soulbound. If `false`, no persona can be soulbound.
5.  **`withdrawCatalystFunds(address payable _to, uint256 _amount)`:** Allows the contract owner to withdraw accumulated catalyst fees.
6.  **`mintQuantumPersona(string memory _name, bytes32 _initialDnaHash)`:** Mints a new Quantum Persona NFT for the caller, assigning an initial DNA hash.
7.  **`updatePersonaName(uint256 _tokenId, string memory _newName)`:** Allows the owner of a persona to change its name.
8.  **`addPersonaTrait(uint256 _tokenId, string memory _key, string memory _value)`:** Allows the persona owner to add or update a dynamic trait for their persona.
9.  **`removePersonaTrait(uint256 _tokenId, string memory _key)`:** Allows the persona owner to remove a dynamic trait from their persona.
10. **`togglePersonaSoulbound(uint256 _tokenId)`:** Allows the owner of a persona to toggle its soulbound status (making it non-transferable or transferable again), provided global soulbound is enabled.
11. **`requestPersonaEvolution(uint256 _tokenId, string memory _evolutionContext, bytes32 _contextHash)`:** Initiates an evolution request for a persona. Requires `catalystFee`. An oracle call is simulated to determine the outcome.
12. **`fulfillEvolutionRequest(bytes32 _requestId, uint256 _personaId, bytes32 _newDnaHash, uint256 _reputationChange, string memory _evolutionOutcomeDescription)`:** Callback function, callable only by the trusted oracle, to fulfill a persona evolution request. Updates persona DNA, reputation, and evolution level.
13. **`applyDirectStimulus(uint256 _tokenId, int256 _reputationChange, string memory _stimulusType, bytes32 _stimulusDataHash)`:** Allows the trusted oracle (or potentially another whitelisted contract) to directly apply a stimulus, causing a reputation change, based on verified off-chain events.
14. **`initiateQuantumState(uint256 _durationSeconds, bytes32 _stateInputHash, uint256[] memory _initialPersonaIds)`:** Creates a new Quantum State, requiring the `catalystFee`. Includes an initial set of persona participants.
15. **`joinQuantumState(uint256 _stateId, uint256 _personaId)`:** Allows a persona owner to add their persona to an existing active Quantum State.
16. **`exitQuantumState(uint256 _stateId, uint256 _personaId)`:** Allows a persona owner to remove their persona from an active Quantum State.
17. **`requestStateResolution(uint256 _stateId)`:** Initiates the resolution process for a Quantum State. Only the state initiator can call this. Simulates an oracle call to determine the outcome.
18. **`fulfillStateResolution(bytes32 _requestId, uint256 _stateId, bytes32 _resolvedOutcomeHash, int256[] memory _reputationChanges, uint256[] memory _evolutionLevelChanges)`:** Callback function, callable only by the trusted oracle, to fulfill a Quantum State resolution request. Updates reputation and evolution levels for all involved personas based on the AI's determined outcome.
19. **`decayReputation(uint256 _tokenId)`:** Allows anyone to trigger a reputation decay for a persona if a certain cooldown period has passed since its last significant update.
20. **`getPersonaDetails(uint256 _tokenId)`:** View function to retrieve all public details of a Quantum Persona.
21. **`getPersonaTraits(uint256 _tokenId, string[] memory _keys)`:** View function to retrieve specific traits of a persona by their keys.
22. **`getQuantumStateDetails(uint256 _stateId)`:** View function to retrieve all public details of a Quantum State.
23. **`getOracleRequestStatus(bytes32 _requestId)`:** View function to check the status of an ongoing oracle request.
24. **`_transfer(address from, address to, uint256 tokenId)` (Internal ERC721 override):** Overrides the ERC721 transfer logic to enforce soulbound restrictions.
25. **`updateQuantumStateParameters(uint256 _maxParticipants, uint256 _minStateDuration, uint256 _maxStateDuration)`:** Allows the contract owner to adjust parameters for Quantum States (e.g., maximum participants, minimum/maximum duration).

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

// Interfaces
interface IOracle {
    // Defines a generic interface for an external oracle that can respond to requests.
    // The actual oracle implementation would be off-chain and then call back into this contract.
    // For this example, it's simplified to a direct callback mechanism.
    function fulfillRequest(
        bytes32 requestId,
        bytes4 callbackFunctionSelector,
        bytes memory callbackData // ABI encoded data for the callback
    ) external;
}

contract QuantumLeapProtocol is ERC721, Ownable {
    using Counters for Counters.Counter;
    using Strings for uint256;

    // --- State Variables ---

    Counters.Counter private _personaIdCounter;
    Counters.Counter private _quantumStateIdCounter;

    // Configuration
    address public oracleAddress; // The trusted oracle responsible for AI computations
    uint256 public catalystFee; // Fee required for certain actions (e.g., persona evolution, quantum state initiation)
    uint256 public reputationDecayInterval = 30 days; // How often reputation decays
    int256 public reputationDecayAmount = -10; // Amount reputation decays by per interval
    uint256 public minEvolutionLevelRepGain = 50; // Minimum reputation gain required for an evolution level increase
    bool public soulboundGlobalEnabled = true; // Global switch to allow personas to be soulbound

    // Quantum Persona Data
    struct QuantumPersona {
        address owner;
        uint256 tokenId;
        string name;
        bytes32 dnaHash; // Core genetic code, evolves over time
        uint256 evolutionLevel; // Reflects advanced evolution stages
        int256 reputationScore; // Can be positive or negative
        uint256 lastStimulusTimestamp; // Timestamp of last significant update/interaction for decay
        uint256 currentQuantumStateId; // 0 if not in a state, otherwise the state ID
        bool isSoulbound; // If true, persona cannot be transferred
        mapping(string => string) traits; // Dynamic traits (e.g., "mood": "curious", "element": "fire")
    }
    mapping(uint256 => QuantumPersona) public personas;
    mapping(string => uint256) private _personaNameIdMap; // For quick lookup by unique name

    // Quantum State Data
    enum QuantumStateStatus { Active, PendingResolution, Resolved, Expired }
    struct QuantumState {
        uint256 stateId;
        address initiator;
        uint256[] involvedPersonas; // Token IDs of personas participating
        uint256 creationTimestamp;
        uint256 expirationTimestamp; // When the state automatically concludes
        bytes32 stateInputHash; // Hash of the initial problem/context for the state
        bytes32 resolvedOutcomeHash; // Hash of the AI-determined outcome data
        QuantumStateStatus status;
        uint256 catalystFeePaid; // Fee collected for this specific state
    }
    mapping(uint256 => QuantumState) public quantumStates;

    // Quantum State Configuration Parameters
    uint256 public quantumStateMaxParticipants = 10;
    uint256 public quantumStateMinDuration = 1 hours;
    uint256 public quantumStateMaxDuration = 7 days;

    // Oracle Request Tracking
    enum OracleRequestStatus { Pending, Fulfilled, Failed }
    struct OracleRequest {
        bytes32 requestId; // Unique ID for the request
        uint256 personaId; // Persona related to the request (0 if not applicable)
        bytes4 callbackFunction; // Function selector to call upon fulfillment
        address requester; // Address that initiated the request
        bytes32 inputHash; // Hash of the data sent to the oracle
        bool fulfilled; // True if the request has been fulfilled
    }
    mapping(bytes32 => OracleRequest) public oracleRequests;

    // --- Events ---

    event PersonaMinted(uint256 indexed tokenId, address indexed owner, string name, bytes32 initialDnaHash);
    event PersonaNameUpdated(uint256 indexed tokenId, string newName);
    event PersonaTraitUpdated(uint256 indexed tokenId, string key, string value);
    event PersonaTraitRemoved(uint256 indexed tokenId, string key);
    event PersonaSoulboundToggled(uint256 indexed tokenId, bool isSoulbound);
    event PersonaEvolutionRequested(bytes32 indexed requestId, uint256 indexed tokenId, string context);
    event PersonaEvolutionFulfilled(bytes32 indexed requestId, uint256 indexed tokenId, bytes32 newDnaHash, int256 reputationChange, string outcome);
    event DirectStimulusApplied(uint256 indexed tokenId, int256 reputationChange, string stimulusType, bytes32 stimulusDataHash);
    event ReputationDecayed(uint256 indexed tokenId, int256 newReputation);

    event QuantumStateInitiated(uint256 indexed stateId, address indexed initiator, uint256 duration, bytes32 stateInputHash);
    event QuantumStatePersonaJoined(uint256 indexed stateId, uint256 indexed personaId);
    event QuantumStatePersonaExited(uint256 indexed stateId, uint256 indexed personaId);
    event QuantumStateResolutionRequested(bytes32 indexed requestId, uint256 indexed stateId);
    event QuantumStateResolutionFulfilled(bytes32 indexed requestId, uint256 indexed stateId, bytes32 resolvedOutcomeHash);
    event QuantumStateEnded(uint256 indexed stateId, QuantumStateStatus finalStatus);

    event CatalystFeeSet(uint256 newFee);
    event OracleAddressSet(address newAddress);
    event FundsWithdrawn(address indexed to, uint256 amount);
    event SoulboundGlobalToggled(bool enabled);
    event QuantumStateParametersUpdated(uint256 maxParticipants, uint256 minDuration, uint256 maxDuration);


    // --- Modifiers ---

    modifier onlyOracle() {
        require(msg.sender == oracleAddress, "QLP: Not the trusted oracle");
        _;
    }

    modifier _isPersonaOwner(uint256 _tokenId) {
        require(personas[_tokenId].owner == msg.sender, "QLP: Not persona owner");
        _;
    }

    // --- Constructor ---

    constructor(address _initialOracleAddress) ERC721("Quantum Persona", "QLP") Ownable(msg.sender) {
        require(_initialOracleAddress != address(0), "QLP: Oracle address cannot be zero");
        oracleAddress = _initialOracleAddress;
        catalystFee = 0.01 ether; // Default catalyst fee
        emit OracleAddressSet(_initialOracleAddress);
        emit CatalystFeeSet(catalystFee);
    }

    // --- Admin Functions (Owner) ---

    /**
     * @dev Sets the catalyst fee required for certain operations.
     * @param _newFee The new fee amount.
     */
    function setCatalystFee(uint256 _newFee) public onlyOwner {
        catalystFee = _newFee;
        emit CatalystFeeSet(_newFee);
    }

    /**
     * @dev Sets the trusted oracle address.
     * @param _newOracleAddress The new oracle address.
     */
    function setOracleAddress(address _newOracleAddress) public onlyOwner {
        require(_newOracleAddress != address(0), "QLP: Oracle address cannot be zero");
        oracleAddress = _newOracleAddress;
        emit OracleAddressSet(_newOracleAddress);
    }

    /**
     * @dev Toggles the global ability for personas to be made soulbound.
     *      If set to `false`, no persona can be made soulbound, and existing soulbound personas become transferable.
     * @param _enabled Whether soulbound functionality is globally enabled.
     */
    function toggleSoulboundGlobal(bool _enabled) public onlyOwner {
        soulboundGlobalEnabled = _enabled;
        emit SoulboundGlobalToggled(_enabled);
    }

    /**
     * @dev Allows the contract owner to withdraw accumulated catalyst fees.
     * @param _to The address to send the funds to.
     * @param _amount The amount to withdraw.
     */
    function withdrawCatalystFunds(address payable _to, uint256 _amount) public onlyOwner {
        require(_amount > 0, "QLP: Withdrawal amount must be greater than zero");
        require(address(this).balance >= _amount, "QLP: Insufficient contract balance");
        (bool success, ) = _to.call{value: _amount}("");
        require(success, "QLP: Failed to withdraw funds");
        emit FundsWithdrawn(_to, _amount);
    }

    /**
     * @dev Allows the contract owner to adjust parameters for Quantum States.
     * @param _maxParticipants Max number of personas in a state.
     * @param _minDuration Minimum duration for a state.
     * @param _maxDuration Maximum duration for a state.
     */
    function updateQuantumStateParameters(
        uint256 _maxParticipants,
        uint256 _minDuration,
        uint256 _maxDuration
    ) public onlyOwner {
        require(_maxParticipants > 0, "QLP: Max participants must be greater than zero");
        require(_minDuration > 0, "QLP: Min duration must be greater than zero");
        require(_maxDuration >= _minDuration, "QLP: Max duration must be >= min duration");

        quantumStateMaxParticipants = _maxParticipants;
        quantumStateMinDuration = _minDuration;
        quantumStateMaxDuration = _maxDuration;

        emit QuantumStateParametersUpdated(_maxParticipants, _minDuration, _maxDuration);
    }

    // --- Persona Management Functions ---

    /**
     * @dev Mints a new Quantum Persona NFT for the caller.
     * @param _name The desired name for the persona (must be unique).
     * @param _initialDnaHash The initial DNA hash representing core traits.
     */
    function mintQuantumPersona(string memory _name, bytes32 _initialDnaHash) public {
        bytes memory nameBytes = bytes(_name);
        require(nameBytes.length > 0 && nameBytes.length <= 32, "QLP: Name must be 1-32 chars"); // Simple length check
        require(_personaNameIdMap[_name] == 0, "QLP: Persona name already exists");

        _personaIdCounter.increment();
        uint256 newItemId = _personaIdCounter.current();

        _mint(msg.sender, newItemId);

        QuantumPersona storage newPersona = personas[newItemId];
        newPersona.owner = msg.sender;
        newPersona.tokenId = newItemId;
        newPersona.name = _name;
        newPersona.dnaHash = _initialDnaHash;
        newPersona.evolutionLevel = 1; // Start at level 1
        newPersona.reputationScore = 0; // Start with neutral reputation
        newPersona.lastStimulusTimestamp = block.timestamp;
        newPersona.currentQuantumStateId = 0;
        newPersona.isSoulbound = false; // Default to not soulbound

        _personaNameIdMap[_name] = newItemId; // Map name to ID

        emit PersonaMinted(newItemId, msg.sender, _name, _initialDnaHash);
    }

    /**
     * @dev Allows the owner of a persona to change its name.
     * @param _tokenId The ID of the persona.
     * @param _newName The new name for the persona.
     */
    function updatePersonaName(uint256 _tokenId, string memory _newName) public _isPersonaOwner(_tokenId) {
        bytes memory newNameBytes = bytes(_newName);
        require(newNameBytes.length > 0 && newNameBytes.length <= 32, "QLP: Name must be 1-32 chars");
        require(_personaNameIdMap[_newName] == 0, "QLP: New persona name already exists");

        // Remove old name mapping
        delete _personaNameIdMap[personas[_tokenId].name];
        // Set new name and map
        personas[_tokenId].name = _newName;
        _personaNameIdMap[_newName] = _tokenId;

        emit PersonaNameUpdated(_tokenId, _newName);
    }

    /**
     * @dev Allows the persona owner to add or update a dynamic trait for their persona.
     * @param _tokenId The ID of the persona.
     * @param _key The key for the trait (e.g., "mood", "element").
     * @param _value The value for the trait.
     */
    function addPersonaTrait(uint256 _tokenId, string memory _key, string memory _value) public _isPersonaOwner(_tokenId) {
        require(bytes(_key).length > 0, "QLP: Trait key cannot be empty");
        personas[_tokenId].traits[_key] = _value;
        emit PersonaTraitUpdated(_tokenId, _key, _value);
    }

    /**
     * @dev Allows the persona owner to remove a dynamic trait from their persona.
     * @param _tokenId The ID of the persona.
     * @param _key The key of the trait to remove.
     */
    function removePersonaTrait(uint256 _tokenId, string memory _key) public _isPersonaOwner(_tokenId) {
        require(bytes(personas[_tokenId].traits[_key]).length > 0, "QLP: Trait does not exist");
        delete personas[_tokenId].traits[_key];
        emit PersonaTraitRemoved(_tokenId, _key);
    }

    /**
     * @dev Allows the owner of a persona to toggle its soulbound status.
     *      A soulbound persona cannot be transferred. Requires `soulboundGlobalEnabled` to be true.
     * @param _tokenId The ID of the persona.
     */
    function togglePersonaSoulbound(uint256 _tokenId) public _isPersonaOwner(_tokenId) {
        require(soulboundGlobalEnabled, "QLP: Soulbound feature is globally disabled");
        personas[_tokenId].isSoulbound = !personas[_tokenId].isSoulbound;
        emit PersonaSoulboundToggled(_tokenId, personas[_tokenId].isSoulbound);
    }

    /**
     * @dev Initiates an evolution request for a persona, requiring a catalyst fee.
     *      This simulates an off-chain AI analysis of the persona's DNA and history.
     * @param _tokenId The ID of the persona to evolve.
     * @param _evolutionContext A description or prompt for the AI regarding the evolution.
     * @param _contextHash A hash of additional data sent to the oracle for the evolution.
     */
    function requestPersonaEvolution(
        uint256 _tokenId,
        string memory _evolutionContext,
        bytes32 _contextHash
    ) public payable _isPersonaOwner(_tokenId) {
        require(msg.value >= catalystFee, "QLP: Insufficient catalyst fee");
        require(oracleAddress != address(0), "QLP: Oracle address not set");

        bytes32 requestId = keccak256(abi.encodePacked(block.timestamp, _tokenId, _evolutionContext, msg.sender));
        require(oracleRequests[requestId].requestId == bytes32(0), "QLP: Duplicate request ID"); // Prevent re-requesting same one

        oracleRequests[requestId] = OracleRequest({
            requestId: requestId,
            personaId: _tokenId,
            callbackFunction: this.fulfillEvolutionRequest.selector,
            requester: msg.sender,
            inputHash: _contextHash,
            fulfilled: false
        });

        emit PersonaEvolutionRequested(requestId, _tokenId, _evolutionContext);

        // In a real scenario, this would trigger an off-chain oracle call.
        // For this example, we assume the oracle will call `fulfillEvolutionRequest` directly.
    }

    /**
     * @dev Callback function to fulfill a persona evolution request. Callable only by the trusted oracle.
     * @param _requestId The ID of the original oracle request.
     * @param _personaId The ID of the persona being evolved.
     * @param _newDnaHash The new DNA hash determined by the AI.
     * @param _reputationChange The change in reputation score.
     * @param _evolutionOutcomeDescription A description of the evolution outcome from the AI.
     */
    function fulfillEvolutionRequest(
        bytes32 _requestId,
        uint256 _personaId,
        bytes32 _newDnaHash,
        int256 _reputationChange,
        string memory _evolutionOutcomeDescription
    ) public onlyOracle {
        OracleRequest storage request = oracleRequests[_requestId];
        require(request.requestId != bytes32(0), "QLP: Request not found");
        require(!request.fulfilled, "QLP: Request already fulfilled");
        require(request.personaId == _personaId, "QLP: Persona ID mismatch for request");
        require(request.callbackFunction == this.fulfillEvolutionRequest.selector, "QLP: Incorrect callback function");

        QuantumPersona storage persona = personas[_personaId];
        require(persona.tokenId == _personaId, "QLP: Persona not found for fulfillment");

        persona.dnaHash = _newDnaHash;
        persona.reputationScore += _reputationChange;
        persona.lastStimulusTimestamp = block.timestamp;

        // Optionally increase evolution level if reputation threshold met
        if (persona.reputationScore >= int256(persona.evolutionLevel * minEvolutionLevelRepGain)) {
            persona.evolutionLevel++;
        }

        request.fulfilled = true;

        emit PersonaEvolutionFulfilled(_requestId, _personaId, _newDnaHash, _reputationChange, _evolutionOutcomeDescription);
    }

    /**
     * @dev Allows the trusted oracle (or potentially another whitelisted contract) to directly apply a stimulus.
     *      This can be used for verified off-chain events impacting a persona's reputation.
     * @param _tokenId The ID of the persona to stimulate.
     * @param _reputationChange The amount by which to change the reputation (can be negative).
     * @param _stimulusType A string describing the type of stimulus (e.g., "verified_achievement", "breach_of_conduct").
     * @param _stimulusDataHash A hash of the data verifying the stimulus.
     */
    function applyDirectStimulus(
        uint256 _tokenId,
        int256 _reputationChange,
        string memory _stimulusType,
        bytes32 _stimulusDataHash
    ) public onlyOracle {
        QuantumPersona storage persona = personas[_tokenId];
        require(persona.tokenId == _tokenId, "QLP: Persona not found");

        persona.reputationScore += _reputationChange;
        persona.lastStimulusTimestamp = block.timestamp;

        // Optionally increase evolution level if reputation threshold met (repeated logic for consistency)
        if (persona.reputationScore >= int256(persona.evolutionLevel * minEvolutionLevelRepGain)) {
            persona.evolutionLevel++;
        }

        emit DirectStimulusApplied(_tokenId, _reputationChange, _stimulusType, _stimulusDataHash);
    }

    /**
     * @dev Allows anyone to trigger a reputation decay for a persona if enough time has passed.
     * @param _tokenId The ID of the persona.
     */
    function decayReputation(uint256 _tokenId) public {
        QuantumPersona storage persona = personas[_tokenId];
        require(persona.tokenId == _tokenId, "QLP: Persona not found");
        require(block.timestamp >= persona.lastStimulusTimestamp + reputationDecayInterval, "QLP: Not yet time for reputation decay");

        persona.reputationScore += reputationDecayAmount;
        persona.lastStimulusTimestamp = block.timestamp; // Reset timestamp after decay

        emit ReputationDecayed(_tokenId, persona.reputationScore);
    }

    // --- Quantum State Functions ---

    /**
     * @dev Initiates a new Quantum State. Requires catalyst fee and an initial set of persona participants.
     *      This state allows multiple personas to interact and potentially resolve a scenario via AI.
     * @param _durationSeconds The duration for which the state will be active.
     * @param _stateInputHash A hash of the initial data/problem for the state to be resolved.
     * @param _initialPersonaIds An array of persona IDs to initially include in the state.
     */
    function initiateQuantumState(
        uint256 _durationSeconds,
        bytes32 _stateInputHash,
        uint256[] memory _initialPersonaIds
    ) public payable {
        require(msg.value >= catalystFee, "QLP: Insufficient catalyst fee");
        require(_durationSeconds >= quantumStateMinDuration && _durationSeconds <= quantumStateMaxDuration, "QLP: Invalid state duration");
        require(_initialPersonaIds.length > 0 && _initialPersonaIds.length <= quantumStateMaxParticipants, "QLP: Invalid number of initial participants");
        require(oracleAddress != address(0), "QLP: Oracle address not set");

        _quantumStateIdCounter.increment();
        uint256 newStateId = _quantumStateIdCounter.current();

        QuantumState storage newState = quantumStates[newStateId];
        newState.stateId = newStateId;
        newState.initiator = msg.sender;
        newState.creationTimestamp = block.timestamp;
        newState.expirationTimestamp = block.timestamp + _durationSeconds;
        newState.stateInputHash = _stateInputHash;
        newState.status = QuantumStateStatus.Active;
        newState.catalystFeePaid = msg.value;

        // Add initial personas and update their state
        for (uint256 i = 0; i < _initialPersonaIds.length; i++) {
            uint256 personaId = _initialPersonaIds[i];
            QuantumPersona storage p = personas[personaId];
            require(p.tokenId == personaId, "QLP: Persona in initial list not found");
            require(p.currentQuantumStateId == 0, "QLP: Persona already in another state");
            
            newState.involvedPersonas.push(personaId);
            p.currentQuantumStateId = newStateId;
            p.lastStimulusTimestamp = block.timestamp; // Mark as active
            emit QuantumStatePersonaJoined(newStateId, personaId);
        }

        emit QuantumStateInitiated(newStateId, msg.sender, _durationSeconds, _stateInputHash);
    }

    /**
     * @dev Allows a persona owner to add their persona to an existing active Quantum State.
     * @param _stateId The ID of the Quantum State.
     * @param _personaId The ID of the persona to join.
     */
    function joinQuantumState(uint256 _stateId, uint256 _personaId) public _isPersonaOwner(_personaId) {
        QuantumState storage state = quantumStates[_stateId];
        require(state.stateId == _stateId, "QLP: Quantum State not found");
        require(state.status == QuantumStateStatus.Active, "QLP: Quantum State is not active");
        require(block.timestamp < state.expirationTimestamp, "QLP: Quantum State has expired");
        require(state.involvedPersonas.length < quantumStateMaxParticipants, "QLP: Quantum State is full");

        QuantumPersona storage persona = personas[_personaId];
        require(persona.currentQuantumStateId == 0, "QLP: Persona already in another state");

        // Check if persona is already in the state
        for (uint256 i = 0; i < state.involvedPersonas.length; i++) {
            require(state.involvedPersonas[i] != _personaId, "QLP: Persona already in this state");
        }

        state.involvedPersonas.push(_personaId);
        persona.currentQuantumStateId = _stateId;
        persona.lastStimulusTimestamp = block.timestamp;

        emit QuantumStatePersonaJoined(_stateId, _personaId);
    }

    /**
     * @dev Allows a persona owner to remove their persona from an active Quantum State.
     * @param _stateId The ID of the Quantum State.
     * @param _personaId The ID of the persona to exit.
     */
    function exitQuantumState(uint256 _stateId, uint256 _personaId) public _isPersonaOwner(_personaId) {
        QuantumState storage state = quantumStates[_stateId];
        require(state.stateId == _stateId, "QLP: Quantum State not found");
        require(state.status == QuantumStateStatus.Active, "QLP: Quantum State is not active");
        require(personas[_personaId].currentQuantumStateId == _stateId, "QLP: Persona not in this state");

        // Remove persona from involved list
        bool found = false;
        for (uint256 i = 0; i < state.involvedPersonas.length; i++) {
            if (state.involvedPersonas[i] == _personaId) {
                state.involvedPersonas[i] = state.involvedPersonas[state.involvedPersonas.length - 1];
                state.involvedPersonas.pop();
                found = true;
                break;
            }
        }
        require(found, "QLP: Persona not found in state's participant list");

        personas[_personaId].currentQuantumStateId = 0; // Persona no longer in any state
        personas[_personaId].lastStimulusTimestamp = block.timestamp;

        emit QuantumStatePersonaExited(_stateId, _personaId);
    }

    /**
     * @dev Initiates the resolution process for a Quantum State. Only the state initiator can call this.
     *      This simulates an off-chain AI calculation of the state's outcome based on its input and participants.
     * @param _stateId The ID of the Quantum State to resolve.
     */
    function requestStateResolution(uint256 _stateId) public {
        QuantumState storage state = quantumStates[_stateId];
        require(state.stateId == _stateId, "QLP: Quantum State not found");
        require(state.initiator == msg.sender, "QLP: Only state initiator can request resolution");
        require(state.status == QuantumStateStatus.Active, "QLP: Quantum State not active");
        require(block.timestamp < state.expirationTimestamp, "QLP: Quantum State has expired, cannot request resolution");
        require(oracleAddress != address(0), "QLP: Oracle address not set");

        state.status = QuantumStateStatus.PendingResolution;

        bytes32 requestId = keccak256(abi.encodePacked(block.timestamp, _stateId, state.stateInputHash, state.involvedPersonas));
        require(oracleRequests[requestId].requestId == bytes32(0), "QLP: Duplicate resolution request ID");

        oracleRequests[requestId] = OracleRequest({
            requestId: requestId,
            personaId: 0, // Not tied to a single persona
            callbackFunction: this.fulfillStateResolution.selector,
            requester: msg.sender,
            inputHash: state.stateInputHash, // Or a hash of all state data
            fulfilled: false
        });

        emit QuantumStateResolutionRequested(requestId, _stateId);
    }

    /**
     * @dev Callback function to fulfill a Quantum State resolution request. Callable only by the trusted oracle.
     *      Updates reputation and evolution levels for all involved personas based on the AI's determined outcome.
     * @param _requestId The ID of the original oracle request.
     * @param _stateId The ID of the Quantum State being resolved.
     * @param _resolvedOutcomeHash A hash of the AI-determined outcome data.
     * @param _reputationChanges An array of reputation changes, corresponding to `involvedPersonas` order.
     * @param _evolutionLevelChanges An array of evolution level changes, corresponding to `involvedPersonas` order.
     */
    function fulfillStateResolution(
        bytes32 _requestId,
        uint256 _stateId,
        bytes32 _resolvedOutcomeHash,
        int256[] memory _reputationChanges,
        uint256[] memory _evolutionLevelChanges
    ) public onlyOracle {
        OracleRequest storage request = oracleRequests[_requestId];
        require(request.requestId != bytes32(0), "QLP: Request not found");
        require(!request.fulfilled, "QLP: Request already fulfilled");
        require(request.callbackFunction == this.fulfillStateResolution.selector, "QLP: Incorrect callback function");

        QuantumState storage state = quantumStates[_stateId];
        require(state.stateId == _stateId, "QLP: Quantum State not found");
        require(state.status == QuantumStateStatus.PendingResolution, "QLP: Quantum State not pending resolution");
        require(state.involvedPersonas.length == _reputationChanges.length, "QLP: Reputation changes array length mismatch");
        require(state.involvedPersonas.length == _evolutionLevelChanges.length, "QLP: Evolution changes array length mismatch");

        state.resolvedOutcomeHash = _resolvedOutcomeHash;
        state.status = QuantumStateStatus.Resolved;

        // Apply outcomes to involved personas
        for (uint256 i = 0; i < state.involvedPersonas.length; i++) {
            uint256 personaId = state.involvedPersonas[i];
            QuantumPersona storage persona = personas[personaId];

            persona.reputationScore += _reputationChanges[i];
            persona.evolutionLevel += _evolutionLevelChanges[i]; // Can increase or decrease based on outcome
            persona.lastStimulusTimestamp = block.timestamp;
            persona.currentQuantumStateId = 0; // Persona exits the state upon resolution
        }

        request.fulfilled = true;

        emit QuantumStateResolutionFulfilled(_requestId, _stateId, _resolvedOutcomeHash);
        emit QuantumStateEnded(_stateId, QuantumStateStatus.Resolved);
    }

    // --- View Functions ---

    /**
     * @dev Retrieves all public details of a Quantum Persona.
     * @param _tokenId The ID of the persona.
     * @return A tuple containing persona details.
     */
    function getPersonaDetails(uint256 _tokenId)
        public
        view
        returns (
            address owner,
            string memory name,
            bytes32 dnaHash,
            uint256 evolutionLevel,
            int256 reputationScore,
            uint256 lastStimulusTimestamp,
            uint256 currentQuantumStateId,
            bool isSoulbound
        )
    {
        QuantumPersona storage persona = personas[_tokenId];
        require(persona.tokenId == _tokenId, "QLP: Persona not found");

        return (
            persona.owner,
            persona.name,
            persona.dnaHash,
            persona.evolutionLevel,
            persona.reputationScore,
            persona.lastStimulusTimestamp,
            persona.currentQuantumStateId,
            persona.isSoulbound
        );
    }

    /**
     * @dev Retrieves specific traits of a persona by their keys.
     * @param _tokenId The ID of the persona.
     * @param _keys An array of trait keys to retrieve.
     * @return An array of trait values, in the same order as the keys.
     */
    function getPersonaTraits(uint256 _tokenId, string[] memory _keys) public view returns (string[] memory) {
        QuantumPersona storage persona = personas[_tokenId];
        require(persona.tokenId == _tokenId, "QLP: Persona not found");

        string[] memory values = new string[](_keys.length);
        for (uint256 i = 0; i < _keys.length; i++) {
            values[i] = persona.traits[_keys[i]];
        }
        return values;
    }

    /**
     * @dev Retrieves all public details of a Quantum State.
     * @param _stateId The ID of the Quantum State.
     * @return A tuple containing state details.
     */
    function getQuantumStateDetails(uint256 _stateId)
        public
        view
        returns (
            uint256 stateId,
            address initiator,
            uint256[] memory involvedPersonas,
            uint256 creationTimestamp,
            uint256 expirationTimestamp,
            bytes32 stateInputHash,
            bytes32 resolvedOutcomeHash,
            QuantumStateStatus status,
            uint256 catalystFeePaid
        )
    {
        QuantumState storage state = quantumStates[_stateId];
        require(state.stateId == _stateId, "QLP: Quantum State not found");

        return (
            state.stateId,
            state.initiator,
            state.involvedPersonas,
            state.creationTimestamp,
            state.expirationTimestamp,
            state.stateInputHash,
            state.resolvedOutcomeHash,
            state.status,
            state.catalystFeePaid
        );
    }

    /**
     * @dev Checks the status of an ongoing oracle request.
     * @param _requestId The ID of the oracle request.
     * @return The status of the request (Pending, Fulfilled, Failed).
     */
    function getOracleRequestStatus(bytes32 _requestId) public view returns (OracleRequestStatus) {
        OracleRequest storage request = oracleRequests[_requestId];
        if (request.requestId == bytes32(0)) {
            return OracleRequestStatus.Failed; // Or define as 'NotFound'
        }
        return request.fulfilled ? OracleRequestStatus.Fulfilled : OracleRequestStatus.Pending;
    }

    // --- ERC721 Overrides ---

    /**
     * @dev ERC721 `_transfer` override to enforce soulbound logic.
     * @param from The current owner of the NFT.
     * @param to The new owner.
     * @param tokenId The ID of the NFT to transfer.
     */
    function _transfer(address from, address to, uint256 tokenId) internal override {
        // Allow transfers initiated by the contract itself (e.g., during mint)
        if (msg.sender == address(this)) {
            super._transfer(from, to, tokenId);
            return;
        }

        // Check if the persona is soulbound or if global soulbound is enabled and persona is soulbound
        // If global soulbound is disabled, then no persona is effectively soulbound.
        if (soulboundGlobalEnabled && personas[tokenId].isSoulbound) {
            revert("QLP: This Quantum Persona is soulbound and cannot be transferred.");
        }
        super._transfer(from, to, tokenId);
        personas[tokenId].owner = to; // Update owner in our custom struct
    }

    // ERC721 default _beforeTokenTransfer and _afterTokenTransfer are not explicitly used
    // but can be overridden for more complex hooks if needed.

    // The ERC721 `tokenURI` function is not implemented here as persona data is stored directly on-chain.
    // However, it could be implemented to return a dynamic URI pointing to a metadata server
    // that generates metadata based on the on-chain `QuantumPersona` struct data.
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        // For a real Dapp, this would point to an off-chain API that renders the JSON metadata
        // based on the persona's on-chain data.
        // Example: return string(abi.encodePacked("https://api.quantumleap.xyz/metadata/", tokenId.toString()));
        return string(abi.encodePacked("data:application/json;base64,", Base64.encode(
            bytes(abi.encodePacked(
                '{"name":"', personas[tokenId].name,
                '", "description":"An evolving Quantum Persona.",',
                '"attributes": [',
                    '{"trait_type": "Evolution Level", "value": "', personas[tokenId].evolutionLevel.toString(), '"},',
                    '{"trait_type": "Reputation Score", "value": "', personas[tokenId].reputationScore.toString(), '"},',
                    '{"trait_type": "DNA Hash", "value": "', Strings.toHexString(personas[tokenId].dnaHash), '"},',
                    '{"trait_type": "Soulbound", "value": ', (personas[tokenId].isSoulbound ? "true" : "false"), '}',
                    // Add more attributes dynamically from the traits mapping if desired
                ']}'
            ))
        )));
    }
}

// Minimal Base64 encoder for on-chain dynamic SVG/JSON generation
library Base64 {
    string internal constant TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    function encode(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return "";

        // load the table into memory
        string memory table = TABLE;

        // calculate output length required
        uint256 encodedLen = 4 * ((data.length + 2) / 3);

        // allocate output buffer with space for base64 + newline + null terminator
        bytes memory result = new bytes(encodedLen);

        // encode 3 bytes at a time into 4 output bytes
        uint256 idx = 0;
        uint256 dataIdx = 0;
        for (uint256 i = data.length; i > 2; i -= 3) {
            result[idx] = bytes1(table[uint8(data[dataIdx] >> 2)]);
            result[idx + 1] = bytes1(table[uint8(((data[dataIdx] & 0x03) << 4) | (data[dataIdx + 1] >> 4))]);
            result[idx + 2] = bytes1(table[uint8(((data[dataIdx + 1] & 0x0f) << 2) | (data[dataIdx + 2] >> 6))]);
            result[idx + 3] = bytes1(table[uint8(data[dataIdx + 2] & 0x3f)]);
            idx += 4;
            dataIdx += 3;
        }

        // handle padding for last 1 or 2 bytes
        if (data.length - dataIdx == 1) {
            result[idx] = bytes1(table[uint8(data[dataIdx] >> 2)]);
            result[idx + 1] = bytes1(table[uint8((data[dataIdx] & 0x03) << 4)]);
            result[idx + 2] = bytes1('=');
            result[idx + 3] = bytes1('=');
        } else if (data.length - dataIdx == 2) {
            result[idx] = bytes1(table[uint8(data[dataIdx] >> 2)]);
            result[idx + 1] = bytes1(table[uint8(((data[dataIdx] & 0x03) << 4) | (data[dataIdx + 1] >> 4))]);
            result[idx + 2] = bytes1(table[uint8((data[dataIdx + 1] & 0x0f) << 2)]);
            result[idx + 3] = bytes1('=');
        }

        return string(result);
    }
}
```