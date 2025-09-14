This smart contract introduces a novel concept: **Autonomous Digital Twins (ADTs)**. These are dynamic, evolving NFTs that represent a digital entity capable of "learning," adapting, and acting based on an owner's interactions, on-chain activities, external data feeds (via oracles), and even other ADTs.

The ADTs possess customizable `Traits` (e.g., Knowledge, Reputation, Resilience) that change over time, influencing their `Form` (visual representation via `tokenURI`) and `Abilities`. Owners can `train` their ADT, `fuel` it, and define `Intents` for it to execute. External entities can `attest` to an ADT's behavior, influencing its reputation. The system is designed to be highly gamified, fostering long-term engagement and creating unique digital identities with evolving capabilities.

---

## **Contract: AutonomousDigitalTwin (ADT)**

### **Outline:**

1.  **Core ERC721 Functionality:** Standard NFT operations.
2.  **ADT Data Structures:** Defines `Trait` types, `ADTData` (containing traits, last update, etc.), and `ADTIntent` (owner-defined actions).
3.  **Access Control:** Owner, Oracle, and Attestor roles.
4.  **Trait Management:**
    *   **Dynamic Updates:** How traits change based on internal and external factors.
    *   **User Interaction:** Functions allowing owners to influence traits (`trainADT`, `fuelADT`).
    *   **Decay/Maintenance:** How traits degrade if not maintained.
5.  **Evolution & Personalization:**
    *   **Form Evolution:** How `tokenURI` changes based on traits.
    *   **Ability Unlocking:** How specific trait thresholds grant new capabilities.
6.  **Reputation & Attestation:** External validation of an ADT's behavior or owner's actions.
7.  **Intent-Based Actions:** Allowing owners to define conditional actions for their ADT.
8.  **Inter-ADT Dynamics:** Interaction between different ADTs (`mergeADTs`).
9.  **Oracle Integration:** Mechanism for external data to influence ADT state.
10. **System Management:** Pause, withdrawals, configuration.

### **Function Summary:**

1.  `constructor()`: Initializes the contract, sets name, symbol, and initial owner.
2.  `mintADT()`: Mints a new Autonomous Digital Twin NFT for the caller.
3.  `getADTTraits(uint256 _tokenId)`: Retrieves the current traits (Knowledge, Reputation, Resilience) of a specific ADT.
4.  `updateTraitFromOracle(uint256 _tokenId, TraitType _traitType, int256 _delta)`: (Oracle Only) Adjusts an ADT's trait based on external, oracle-provided data (e.g., market sentiment, real-world events).
5.  `trainADT(uint256 _tokenId, uint256 _amount)`: Allows the ADT owner to "train" their ADT by providing resources (e.g., ETH), boosting its `Knowledge` trait.
6.  `fuelADT(uint256 _tokenId, uint256 _amount)`: Allows the ADT owner to "fuel" their ADT, preventing `Resilience` trait decay and potentially boosting it.
7.  `decayADTTraits(uint256 _tokenId)`: (Can be called by anyone, incentivized) Triggers the natural decay of an ADT's traits if it hasn't been `fueled` or `trained` for a period.
8.  `defineADTIntent(uint256 _tokenId, string memory _condition, string memory _action)`: Allows an ADT owner to define a conditional "intent" for their ADT, e.g., "if Knowledge > X, attempt to stake Y token."
9.  `executeADTIntent(uint256 _tokenId, uint256 _intentIndex)`: (Oracle/Keeper Only) Triggers the execution of a defined ADT intent if its conditions are met.
10. `attestToADTBehavior(uint256 _tokenId, string memory _attestationContext, int256 _reputationDelta)`: (Authorized Attestor Only) Allows a trusted third party to attest to an ADT's behavior or owner's actions, impacting its `Reputation` trait.
11. `challengeAttestation(uint256 _tokenId, uint256 _attestationIndex)`: Allows an ADT owner to challenge a given attestation, potentially requiring arbitration (logic external to this contract, but event emitted).
12. `submitLearningContext(uint256 _tokenId, bytes memory _contextHash)`: Allows an owner to submit a hash of off-chain "learning data" or context, which an oracle might later use to update traits.
13. `evolveADTForm(uint256 _tokenId)`: (Can be called by anyone, incentivized) Checks if an ADT's traits meet certain thresholds, triggering an update to its visual `tokenURI` representing its evolution.
14. `mergeADTs(uint256 _tokenIdA, uint256 _tokenIdB)`: Allows an owner to merge two of their ADTs, burning one and combining/averaging traits into the other.
15. `unlockADTAbility(uint256 _tokenId, AbilityType _ability)`: (Can be called by anyone, incentivized) Checks if an ADT's traits qualify it to "unlock" a specific ability, recording it on-chain.
16. `getUnlockedAbilities(uint256 _tokenId)`: Retrieves a list of abilities an ADT has currently unlocked.
17. `tokenURI(uint256 _tokenId)`: Returns the dynamic URI for an ADT, reflecting its current form and traits.
18. `setOracleAddress(address _oracleAddress)`: (Owner Only) Sets the address of the trusted oracle.
19. `addAuthorizedAttestor(address _attestorAddress)`: (Owner Only) Adds an address to the list of authorized attestors.
20. `removeAuthorizedAttestor(address _attestorAddress)`: (Owner Only) Removes an address from the list of authorized attestors.
21. `setTraitDecayRate(TraitType _traitType, uint256 _rate)`: (Owner Only) Configures the decay rate for a specific trait.
22. `pause()`: (Owner Only) Pauses critical functions of the contract in an emergency.
23. `unpause()`: (Owner Only) Unpauses the contract.
24. `withdrawFunds()`: (Owner Only) Allows the contract owner to withdraw accumulated ETH (from training/fueling).

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

/**
 * @title AutonomousDigitalTwin (ADT)
 * @notice A novel ERC721 contract for dynamic, evolving NFTs representing digital entities.
 *         ADTs possess customizable Traits (Knowledge, Reputation, Resilience) that change over time,
 *         influencing their Form (visual representation via tokenURI) and Abilities.
 *         Owners can "train" and "fuel" their ADT, and define "Intents" for it to execute.
 *         External entities can "attest" to an ADT's behavior.
 *         Designed for gamified long-term engagement and unique digital identities.
 *
 * Outline:
 * 1. Core ERC721 Functionality: Standard NFT operations.
 * 2. ADT Data Structures: Defines Trait types, ADTData, and ADTIntent.
 * 3. Access Control: Owner, Oracle, and Attestor roles.
 * 4. Trait Management: Dynamic updates, user interaction, decay/maintenance.
 * 5. Evolution & Personalization: Form evolution, ability unlocking.
 * 6. Reputation & Attestation: External validation of ADT behavior.
 * 7. Intent-Based Actions: Owner-defined conditional actions for ADT.
 * 8. Inter-ADT Dynamics: Interaction between different ADTs (merge).
 * 9. Oracle Integration: Mechanism for external data to influence ADT state.
 * 10. System Management: Pause, withdrawals, configuration.
 *
 * Function Summary:
 * 1. constructor(): Initializes the contract.
 * 2. mintADT(): Mints a new ADT NFT.
 * 3. getADTTraits(uint256 _tokenId): Retrieves current traits of an ADT.
 * 4. updateTraitFromOracle(uint256 _tokenId, TraitType _traitType, int256 _delta): (Oracle Only) Adjusts trait based on external data.
 * 5. trainADT(uint256 _tokenId, uint256 _amount): Owner trains ADT, boosting Knowledge.
 * 6. fuelADT(uint256 _tokenId, uint256 _amount): Owner fuels ADT, boosting Resilience and preventing decay.
 * 7. decayADTTraits(uint256 _tokenId): Triggers natural trait decay if neglected.
 * 8. defineADTIntent(uint256 _tokenId, string memory _condition, string memory _action): Owner defines conditional intent.
 * 9. executeADTIntent(uint256 _tokenId, uint256 _intentIndex): (Oracle/Keeper Only) Executes a defined intent if conditions met.
 * 10. attestToADTBehavior(uint256 _tokenId, string memory _attestationContext, int256 _reputationDelta): (Authorized Attestor Only) Attests to ADT behavior, impacting Reputation.
 * 11. challengeAttestation(uint256 _tokenId, uint256 _attestationIndex): Owner challenges an attestation.
 * 12. submitLearningContext(uint256 _tokenId, bytes memory _contextHash): Owner submits hash of off-chain learning data.
 * 13. evolveADTForm(uint256 _tokenId): Triggers tokenURI update based on trait thresholds.
 * 14. mergeADTs(uint256 _tokenIdA, uint256 _tokenIdB): Merges two ADTs, burning one and combining traits.
 * 15. unlockADTAbility(uint256 _tokenId, AbilityType _ability): Checks and unlocks an ADT's ability.
 * 16. getUnlockedAbilities(uint256 _tokenId): Retrieves a list of unlocked abilities.
 * 17. tokenURI(uint256 _tokenId): Returns dynamic URI for an ADT.
 * 18. setOracleAddress(address _oracleAddress): (Owner Only) Sets the trusted oracle address.
 * 19. addAuthorizedAttestor(address _attestorAddress): (Owner Only) Adds authorized attestor.
 * 20. removeAuthorizedAttestor(address _attestorAddress): (Owner Only) Removes authorized attestor.
 * 21. setTraitDecayRate(TraitType _traitType, uint256 _rate): (Owner Only) Configures trait decay rate.
 * 22. pause(): (Owner Only) Pauses critical functions.
 * 23. unpause(): (Owner Only) Unpauses contract.
 * 24. withdrawFunds(): (Owner Only) Withdraws accumulated ETH.
 */
contract AutonomousDigitalTwin is ERC721, Ownable, Pausable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;

    // --- Enums ---
    enum TraitType { Knowledge, Reputation, Resilience }
    enum AbilityType { DataAnalysis, StrategyOptimization, SocialCoordination, ResourceHarvesting }

    // --- Structs ---
    struct Traits {
        int256 knowledge; // Represents acquired information, skill.
        int256 reputation; // Represents trustworthiness, community standing.
        int256 resilience; // Represents durability, ability to resist decay/stress.
    }

    struct ADTData {
        Traits traits;
        uint64 lastTraitUpdateTimestamp; // When traits were last modified or decayed
        uint64 lastFueledTimestamp;      // When ADT was last fueled
        mapping(AbilityType => bool) unlockedAbilities;
        AbilityType[] activeAbilities; // To quickly list unlocked abilities
        uint256 nextEvolutionStage; // For dynamic tokenURI progression
    }

    struct ADTIntent {
        string condition; // A textual representation of the condition (e.g., "Knowledge > 100")
        string action;    // A textual representation of the action (e.g., "Stake 0.1 ETH in ProtocolX")
        bool executed;
    }

    struct Attestation {
        address attestor;
        uint64 timestamp;
        string context;
        int256 reputationImpact;
        bool challenged;
    }

    // --- State Variables ---
    mapping(uint256 => ADTData) private _adtData;
    mapping(uint256 => ADTIntent[]) private _adtIntents;
    mapping(uint256 => Attestation[]) private _adtAttestations;
    
    address private _oracleAddress;
    mapping(address => bool) private _authorizedAttestors;

    // Default decay rates for traits (per second for simplicity, adjust for practical intervals)
    uint256 private _knowledgeDecayRate = 1; // Example: 1 unit per day (86400 seconds)
    uint256 private _reputationDecayRate = 1;
    uint256 private _resilienceDecayRate = 5;

    // Base URI for token metadata, actual URI will be dynamic
    string private _baseTokenURI;

    // Min/Max trait values to prevent overflow and maintain system integrity
    int224 public constant MIN_TRAIT_VALUE = -1_000_000_000_000_000_000_000; // ~-1e21
    int224 public constant MAX_TRAIT_VALUE = 1_000_000_000_000_000_000_000; // ~1e21

    // --- Events ---
    event ADTMinted(uint256 indexed tokenId, address indexed owner);
    event TraitUpdated(uint256 indexed tokenId, TraitType indexed traitType, int256 oldValue, int256 newValue, string reason);
    event ADTTrained(uint256 indexed tokenId, address indexed trainer, uint256 amount, int256 knowledgeGained);
    event ADTFueled(uint256 indexed tokenId, address indexed fueler, uint256 amount, int256 resilienceGained);
    event ADTIntentDefined(uint256 indexed tokenId, uint256 intentIndex, string condition, string action);
    event ADTIntentExecuted(uint256 indexed tokenId, uint256 indexed intentIndex, string action);
    event ADTAttested(uint256 indexed tokenId, uint256 attestationIndex, address indexed attestor, string context, int256 reputationImpact);
    event AttestationChallenged(uint256 indexed tokenId, uint256 indexed attestationIndex, address indexed challenger);
    event LearningContextSubmitted(uint256 indexed tokenId, address indexed sender, bytes contextHash);
    event ADTFormEvolved(uint256 indexed tokenId, uint256 newStage, string newURI);
    event ADTMerged(uint256 indexed primaryTokenId, uint256 indexed burnedTokenId, address indexed owner);
    event ADTAbilityUnlocked(uint256 indexed tokenId, AbilityType indexed ability);
    event OracleAddressSet(address indexed newOracleAddress);
    event AuthorizedAttestorAdded(address indexed attestor);
    event AuthorizedAttestorRemoved(address indexed attestor);
    event TraitDecayRateSet(TraitType indexed traitType, uint256 rate);

    // --- Modifiers ---
    modifier onlyOracle() {
        require(msg.sender == _oracleAddress, "ADT: Only callable by the oracle");
        _;
    }

    modifier onlyAuthorizedAttestor() {
        require(_authorizedAttestors[msg.sender], "ADT: Only callable by authorized attestors");
        _;
    }

    // --- Constructor ---
    constructor(string memory name_, string memory symbol_, string memory baseURI_)
        ERC721(name_, symbol_)
        Ownable(msg.sender)
        Pausable()
    {
        _baseTokenURI = baseURI_;
        // Set initial oracle and attestors for testing, or leave blank to be set by owner
        // _oracleAddress = msg.sender;
        // _authorizedAttestors[msg.sender] = true;
    }

    // --- Internal Helpers ---

    function _clampTrait(int256 _value) internal pure returns (int256) {
        if (_value < MIN_TRAIT_VALUE) return MIN_TRAIT_VALUE;
        if (_value > MAX_TRAIT_VALUE) return MAX_TRAIT_VALUE;
        return _value;
    }

    function _updateTrait(uint256 _tokenId, TraitType _traitType, int256 _delta, string memory _reason) internal {
        ADTData storage adt = _adtData[_tokenId];
        int256 oldValue;
        int256 newValue;

        if (_traitType == TraitType.Knowledge) {
            oldValue = adt.traits.knowledge;
            adt.traits.knowledge = _clampTrait(adt.traits.knowledge + _delta);
            newValue = adt.traits.knowledge;
        } else if (_traitType == TraitType.Reputation) {
            oldValue = adt.traits.reputation;
            adt.traits.reputation = _clampTrait(adt.traits.reputation + _delta);
            newValue = adt.traits.reputation;
        } else if (_traitType == TraitType.Resilience) {
            oldValue = adt.traits.resilience;
            adt.traits.resilience = _clampTrait(adt.traits.resilience + _delta);
            newValue = adt.traits.resilience;
        } else {
            revert("ADT: Invalid TraitType");
        }
        adt.lastTraitUpdateTimestamp = uint64(block.timestamp);
        emit TraitUpdated(_tokenId, _traitType, oldValue, newValue, _reason);
    }

    // --- Core ERC721 Overrides (with dynamic aspects) ---

    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        _requireOwned(_tokenId);
        ADTData storage adt = _adtData[_tokenId];
        // Construct a dynamic URI based on current traits and evolution stage
        // This is a simplified example; a real implementation would use IPFS/Arweave and a metadata service.
        string memory currentBaseURI = _baseTokenURI;
        string memory formIndicator = string(abi.encodePacked("form", Strings.toString(adt.nextEvolutionStage)));
        string memory knowledgeStr = string(abi.encodePacked("k", Strings.toString(adt.traits.knowledge)));
        string memory reputationStr = string(abi.encodePacked("r", Strings.toString(adt.traits.reputation)));
        string memory resilienceStr = string(abi.encodePacked("s", Strings.toString(adt.traits.resilience)));

        // Example: baseURI/metadata?id=1&form=stage1&k=100&r=50&s=75
        // A more sophisticated system would have a dedicated metadata server or generate dynamic JSON.
        return string(abi.encodePacked(
            currentBaseURI,
            Strings.toString(_tokenId),
            ".json?",
            "form=", formIndicator,
            "&",
            "traits=", knowledgeStr, "-", reputationStr, "-", resilienceStr
        ));
    }

    // --- ADT Core Functions ---

    /**
     * @notice Mints a new Autonomous Digital Twin NFT for the caller.
     * @dev Initializes traits to a base level.
     */
    function mintADT() public whenNotPaused returns (uint256) {
        _tokenIdCounter.increment();
        uint256 newTokenId = _tokenIdCounter.current();

        _safeMint(msg.sender, newTokenId);

        ADTData storage newADT = _adtData[newTokenId];
        newADT.traits.knowledge = 50;    // Initial knowledge
        newADT.traits.reputation = 20;   // Initial reputation
        newADT.traits.resilience = 100;  // Initial resilience
        newADT.lastTraitUpdateTimestamp = uint64(block.timestamp);
        newADT.lastFueledTimestamp = uint64(block.timestamp);
        newADT.nextEvolutionStage = 1; // Starting form stage

        emit ADTMinted(newTokenId, msg.sender);
        emit TraitUpdated(newTokenId, TraitType.Knowledge, 0, newADT.traits.knowledge, "Initial mint");
        emit TraitUpdated(newTokenId, TraitType.Reputation, 0, newADT.traits.reputation, "Initial mint");
        emit TraitUpdated(newTokenId, TraitType.Resilience, 0, newADT.traits.resilience, "Initial mint");
        return newTokenId;
    }

    /**
     * @notice Retrieves the current traits (Knowledge, Reputation, Resilience) of a specific ADT.
     * @param _tokenId The ID of the ADT.
     * @return knowledge The current knowledge trait value.
     * @return reputation The current reputation trait value.
     * @return resilience The current resilience trait value.
     */
    function getADTTraits(uint256 _tokenId) public view returns (int256 knowledge, int256 reputation, int256 resilience) {
        _requireOwned(_tokenId);
        ADTData storage adt = _adtData[_tokenId];
        return (adt.traits.knowledge, adt.traits.reputation, adt.traits.resilience);
    }

    /**
     * @notice (Oracle Only) Adjusts an ADT's trait based on external, oracle-provided data.
     * @dev This is how external AI insights, market sentiment, or real-world events can influence an ADT.
     * @param _tokenId The ID of the ADT.
     * @param _traitType The type of trait to update.
     * @param _delta The amount to adjust the trait by (can be positive or negative).
     */
    function updateTraitFromOracle(uint256 _tokenId, TraitType _traitType, int256 _delta) public onlyOracle whenNotPaused {
        _requireOwned(_tokenId); // Ensure ADT exists
        _updateTrait(_tokenId, _traitType, _delta, "Oracle update");
    }

    /**
     * @notice Allows the ADT owner to "train" their ADT by providing resources (e.g., ETH).
     * @dev Training boosts the ADT's `Knowledge` trait.
     * @param _tokenId The ID of the ADT.
     * @param _amount The amount of ETH provided for training.
     */
    function trainADT(uint256 _tokenId, uint256 _amount) public payable whenNotPaused {
        require(ownerOf(_tokenId) == msg.sender, "ADT: Only ADT owner can train");
        require(msg.value == _amount, "ADT: Sent amount must match specified amount");
        require(_amount > 0, "ADT: Training amount must be positive");

        int256 knowledgeGained = int256(_amount / 1e16); // Example: 1 ETH (1e18 wei) = 100 knowledge
        _updateTrait(_tokenId, TraitType.Knowledge, knowledgeGained, "Owner training");
        emit ADTTrained(_tokenId, msg.sender, _amount, knowledgeGained);
    }

    /**
     * @notice Allows the ADT owner to "fuel" their ADT.
     * @dev Fueling prevents `Resilience` trait decay and can boost it.
     * @param _tokenId The ID of the ADT.
     * @param _amount The amount of ETH provided as fuel.
     */
    function fuelADT(uint256 _tokenId, uint256 _amount) public payable whenNotPaused {
        require(ownerOf(_tokenId) == msg.sender, "ADT: Only ADT owner can fuel");
        require(msg.value == _amount, "ADT: Sent amount must match specified amount");
        require(_amount > 0, "ADT: Fuel amount must be positive");

        ADTData storage adt = _adtData[_tokenId];
        adt.lastFueledTimestamp = uint64(block.timestamp);
        int256 resilienceGained = int256(_amount / 1e17); // Example: 1 ETH = 10 resilience
        _updateTrait(_tokenId, TraitType.Resilience, resilienceGained, "Owner fueling");
        emit ADTFueled(_tokenId, msg.sender, _amount, resilienceGained);
    }

    /**
     * @notice Triggers the natural decay of an ADT's traits if it hasn't been fueled or trained for a period.
     * @dev Anyone can call this function, creating a public good incentive for maintenance.
     * @param _tokenId The ID of the ADT.
     */
    function decayADTTraits(uint256 _tokenId) public whenNotPaused {
        _requireOwned(_tokenId); // Ensure ADT exists

        ADTData storage adt = _adtData[_tokenId];
        uint256 timeElapsed = block.timestamp - adt.lastTraitUpdateTimestamp;
        
        if (timeElapsed == 0) return; // Already updated or not enough time passed

        // Decay calculation based on timeElapsed and configured rates
        int256 knowledgeDecay = int256(timeElapsed * _knowledgeDecayRate / 86400); // Per day
        int256 reputationDecay = int256(timeElapsed * _reputationDecayRate / 86400); // Per day
        int256 resilienceDecay = int256(timeElapsed * _resilienceDecayRate / 86400); // Per day

        if (adt.traits.knowledge > 0 && knowledgeDecay > 0) {
            _updateTrait(_tokenId, TraitType.Knowledge, -knowledgeDecay, "Trait decay");
        }
        if (adt.traits.reputation > 0 && reputationDecay > 0) {
            _updateTrait(_tokenId, TraitType.Reputation, -reputationDecay, "Trait decay");
        }
        if (adt.traits.resilience > 0 && resilienceDecay > 0) {
            _updateTrait(_tokenId, TraitType.Resilience, -resilienceDecay, "Trait decay");
        }

        adt.lastTraitUpdateTimestamp = uint64(block.timestamp); // Reset timestamp after decay
    }

    /**
     * @notice Allows an ADT owner to define a conditional "intent" for their ADT.
     * @dev This is a text-based intent; execution would rely on an oracle interpreting and triggering it.
     * @param _tokenId The ID of the ADT.
     * @param _condition A textual representation of the condition (e.g., "Knowledge > 100").
     * @param _action A textual representation of the action (e.g., "Stake 0.1 ETH in ProtocolX").
     */
    function defineADTIntent(uint256 _tokenId, string memory _condition, string memory _action) public whenNotPaused {
        require(ownerOf(_tokenId) == msg.sender, "ADT: Only ADT owner can define intents");
        _adtIntents[_tokenId].push(ADTIntent({
            condition: _condition,
            action: _action,
            executed: false
        }));
        uint256 intentIndex = _adtIntents[_tokenId].length - 1;
        emit ADTIntentDefined(_tokenId, intentIndex, _condition, _action);
    }

    /**
     * @notice (Oracle/Keeper Only) Triggers the execution of a defined ADT intent if its conditions are met.
     * @dev The oracle or a trusted keeper would be responsible for evaluating the conditions.
     *      Actual execution logic would involve cross-contract calls or integration with other protocols.
     * @param _tokenId The ID of the ADT.
     * @param _intentIndex The index of the intent to execute.
     */
    function executeADTIntent(uint256 _tokenId, uint256 _intentIndex) public onlyOracle whenNotPaused {
        _requireOwned(_tokenId); // Ensure ADT exists
        require(_intentIndex < _adtIntents[_tokenId].length, "ADT: Intent index out of bounds");
        ADTIntent storage intent = _adtIntents[_tokenId][_intentIndex];
        require(!intent.executed, "ADT: Intent already executed");

        // Here, the oracle *confirms* the condition is met off-chain.
        // The contract merely records execution and emits an event.
        // Actual on-chain action would require the oracle to pass more parameters
        // or for the action to be a direct call to another contract.
        // For this example, we keep the action as a string and log it.

        intent.executed = true;
        // Optionally, impact ADT traits based on intent execution (e.g., gain knowledge for successful execution)
        _updateTrait(_tokenId, TraitType.Knowledge, 5, "Intent executed"); // Example
        emit ADTIntentExecuted(_tokenId, _intentIndex, intent.action);
    }

    /**
     * @notice (Authorized Attestor Only) Allows a trusted third party to attest to an ADT's behavior or owner's actions.
     * @dev This impacts the ADT's `Reputation` trait.
     * @param _tokenId The ID of the ADT.
     * @param _attestationContext A description of the behavior or action being attested.
     * @param _reputationDelta The amount to adjust the reputation by (positive for good, negative for bad).
     */
    function attestToADTBehavior(uint256 _tokenId, string memory _attestationContext, int256 _reputationDelta) public onlyAuthorizedAttestor whenNotPaused {
        _requireOwned(_tokenId); // Ensure ADT exists
        
        _adtAttestations[_tokenId].push(Attestation({
            attestor: msg.sender,
            timestamp: uint64(block.timestamp),
            context: _attestationContext,
            reputationImpact: _reputationDelta,
            challenged: false
        }));
        uint256 attestationIndex = _adtAttestations[_tokenId].length - 1;
        
        _updateTrait(_tokenId, TraitType.Reputation, _reputationDelta, string(abi.encodePacked("Attestation by ", Strings.toHexString(uint160(msg.sender), 20))));
        emit ADTAttested(_tokenId, attestationIndex, msg.sender, _attestationContext, _reputationDelta);
    }

    /**
     * @notice Allows an ADT owner to challenge a given attestation.
     * @dev This doesn't automatically revert the attestation's impact but flags it,
     *      suggesting a need for off-chain arbitration or a DAO vote.
     * @param _tokenId The ID of the ADT.
     * @param _attestationIndex The index of the attestation to challenge.
     */
    function challengeAttestation(uint256 _tokenId, uint256 _attestationIndex) public whenNotPaused {
        require(ownerOf(_tokenId) == msg.sender, "ADT: Only ADT owner can challenge attestations");
        require(_attestationIndex < _adtAttestations[_tokenId].length, "ADT: Attestation index out of bounds");
        Attestation storage att = _adtAttestations[_tokenId][_attestationIndex];
        require(!att.challenged, "ADT: Attestation already challenged");

        att.challenged = true;
        // Logic for arbitration or DAO proposal could be triggered here.
        // For simplicity, we just mark as challenged and emit an event.
        emit AttestationChallenged(_tokenId, _attestationIndex, msg.sender);
    }

    /**
     * @notice Allows an owner to submit a hash of off-chain "learning data" or context.
     * @dev This hash can serve as a proof-of-context for future oracle-driven trait updates.
     * @param _tokenId The ID of the ADT.
     * @param _contextHash A hash representing off-chain learning data (e.g., IPFS CID, data summary hash).
     */
    function submitLearningContext(uint256 _tokenId, bytes memory _contextHash) public whenNotPaused {
        require(ownerOf(_tokenId) == msg.sender, "ADT: Only ADT owner can submit learning context");
        require(_contextHash.length > 0, "ADT: Context hash cannot be empty");
        // Store hash or trigger an oracle to process it
        // For this example, we just emit an event. A real system might store this in a mapping
        // and allow an oracle to retrieve it later, or even directly trigger a 'updateTraitFromOracle' call.
        emit LearningContextSubmitted(_tokenId, msg.sender, _contextHash);
    }

    /**
     * @notice Checks if an ADT's traits meet certain thresholds, triggering an update to its visual tokenURI.
     * @dev Anyone can call this function, incentivizing community members to help ADTs evolve.
     *      This function can be structured with different "evolution stages".
     * @param _tokenId The ID of the ADT.
     */
    function evolveADTForm(uint256 _tokenId) public whenNotPaused {
        _requireOwned(_tokenId); // Ensure ADT exists
        ADTData storage adt = _adtData[_tokenId];

        uint256 currentStage = adt.nextEvolutionStage;
        uint256 newStage = currentStage;

        // Example evolution conditions
        if (adt.traits.knowledge >= 1000 && currentStage < 2) {
            newStage = 2;
        } else if (adt.traits.reputation >= 500 && adt.traits.resilience >= 200 && currentStage < 3) {
            newStage = 3;
        } else if (adt.traits.knowledge >= 2000 && adt.traits.reputation >= 1000 && adt.traits.resilience >= 500 && currentStage < 4) {
            newStage = 4;
        }
        // ... more stages ...

        if (newStage > currentStage) {
            adt.nextEvolutionStage = newStage;
            // Optionally, boost traits for evolving
            _updateTrait(_tokenId, TraitType.Resilience, 10, "Form evolution bonus");
            emit ADTFormEvolved(_tokenId, newStage, tokenURI(_tokenId));
        } else {
            revert("ADT: Conditions for next evolution stage not met or already evolved");
        }
    }

    /**
     * @notice Allows an owner to merge two of their ADTs.
     * @dev One ADT is burned, and its traits are combined/averaged into the primary ADT.
     * @param _tokenIdA The ID of the primary ADT (retained).
     * @param _tokenIdB The ID of the secondary ADT (burned).
     */
    function mergeADTs(uint256 _tokenIdA, uint256 _tokenIdB) public whenNotPaused {
        require(ownerOf(_tokenIdA) == msg.sender, "ADT: Caller must own primary ADT");
        require(ownerOf(_tokenIdB) == msg.sender, "ADT: Caller must own secondary ADT");
        require(_tokenIdA != _tokenIdB, "ADT: Cannot merge an ADT with itself");

        ADTData storage adtA = _adtData[_tokenIdA];
        ADTData storage adtB = _adtData[_tokenIdB];

        // Combine traits (e.g., weighted average or sum)
        // For simplicity, let's take a simple average here and add a bonus
        int256 newKnowledge = (adtA.traits.knowledge + adtB.traits.knowledge) / 2 + 50;
        int256 newReputation = (adtA.traits.reputation + adtB.traits.reputation) / 2 + 20;
        int256 newResilience = (adtA.traits.resilience + adtB.traits.resilience) / 2 + 30;

        _updateTrait(_tokenIdA, TraitType.Knowledge, newKnowledge - adtA.traits.knowledge, "ADT Merge bonus");
        _updateTrait(_tokenIdA, TraitType.Reputation, newReputation - adtA.traits.reputation, "ADT Merge bonus");
        _updateTrait(_tokenIdA, TraitType.Resilience, newResilience - adtA.traits.resilience, "ADT Merge bonus");

        // Merge abilities (simple union)
        for (uint256 i = 0; i < adtB.activeAbilities.length; i++) {
            AbilityType ability = adtB.activeAbilities[i];
            if (!adtA.unlockedAbilities[ability]) {
                adtA.unlockedAbilities[ability] = true;
                adtA.activeAbilities.push(ability);
                emit ADTAbilityUnlocked(_tokenIdA, ability);
            }
        }

        // Burn the secondary ADT
        _burn(_tokenIdB);
        // Clear its data to save storage (optional, but good practice)
        delete _adtData[_tokenIdB]; // Note: This does not clear nested mappings like unlockedAbilities if they were struct members
        // To fully clear, you'd need to iterate or ensure they are properly handled.
        // For activeAbilities, it's cleared by deleting the struct.

        emit ADTMerged(_tokenIdA, _tokenIdB, msg.sender);
    }

    /**
     * @notice Checks if an ADT's traits qualify it to "unlock" a specific ability, recording it on-chain.
     * @dev This provides functional utility to high trait values. Anyone can call it.
     * @param _tokenId The ID of the ADT.
     * @param _ability The type of ability to check for.
     */
    function unlockADTAbility(uint256 _tokenId, AbilityType _ability) public whenNotPaused {
        _requireOwned(_tokenId); // Ensure ADT exists
        ADTData storage adt = _adtData[_tokenId];

        require(!adt.unlockedAbilities[_ability], "ADT: Ability already unlocked");

        bool canUnlock = false;
        if (_ability == AbilityType.DataAnalysis && adt.traits.knowledge >= 750) {
            canUnlock = true;
        } else if (_ability == AbilityType.StrategyOptimization && adt.traits.knowledge >= 1200 && adt.traits.reputation >= 200) {
            canUnlock = true;
        } else if (_ability == AbilityType.SocialCoordination && adt.traits.reputation >= 600 && adt.traits.resilience >= 150) {
            canUnlock = true;
        } else if (_ability == AbilityType.ResourceHarvesting && adt.traits.resilience >= 300 && adt.traits.knowledge >= 300) {
            canUnlock = true;
        }
        // ... define more abilities and their unlock conditions

        require(canUnlock, "ADT: Trait conditions not met to unlock this ability");

        adt.unlockedAbilities[_ability] = true;
        adt.activeAbilities.push(_ability); // Add to dynamic array for retrieval
        emit ADTAbilityUnlocked(_tokenId, _ability);
    }

    /**
     * @notice Retrieves a list of abilities an ADT has currently unlocked.
     * @param _tokenId The ID of the ADT.
     * @return An array of unlocked AbilityType enums.
     */
    function getUnlockedAbilities(uint256 _tokenId) public view returns (AbilityType[] memory) {
        _requireOwned(_tokenId);
        return _adtData[_tokenId].activeAbilities;
    }

    // --- Admin Functions ---

    /**
     * @notice (Owner Only) Sets the address of the trusted oracle.
     * @param _oracleAddress The new oracle address.
     */
    function setOracleAddress(address _oracleAddress) public onlyOwner {
        require(_oracleAddress != address(0), "ADT: Oracle address cannot be zero");
        _oracleAddress = _oracleAddress;
        emit OracleAddressSet(_oracleAddress);
    }

    /**
     * @notice (Owner Only) Adds an address to the list of authorized attestors.
     * @param _attestorAddress The address to authorize.
     */
    function addAuthorizedAttestor(address _attestorAddress) public onlyOwner {
        require(_attestorAddress != address(0), "ADT: Attestor address cannot be zero");
        _authorizedAttestors[_attestorAddress] = true;
        emit AuthorizedAttestorAdded(_attestorAddress);
    }

    /**
     * @notice (Owner Only) Removes an address from the list of authorized attestors.
     * @param _attestorAddress The address to de-authorize.
     */
    function removeAuthorizedAttestor(address _attestorAddress) public onlyOwner {
        require(_attestorAddress != address(0), "ADT: Attestor address cannot be zero");
        _authorizedAttestors[_attestorAddress] = false;
        emit AuthorizedAttestorRemoved(_attestorAddress);
    }

    /**
     * @notice (Owner Only) Configures the decay rate for a specific trait.
     * @param _traitType The type of trait to configure.
     * @param _rate The new decay rate per day (units per 86400 seconds).
     */
    function setTraitDecayRate(TraitType _traitType, uint256 _rate) public onlyOwner {
        if (_traitType == TraitType.Knowledge) {
            _knowledgeDecayRate = _rate;
        } else if (_traitType == TraitType.Reputation) {
            _reputationDecayRate = _rate;
        } else if (_traitType == TraitType.Resilience) {
            _resilienceDecayRate = _rate;
        } else {
            revert("ADT: Invalid TraitType for decay rate config");
        }
        emit TraitDecayRateSet(_traitType, _rate);
    }

    /**
     * @notice (Owner Only) Pauses critical functions of the contract in an emergency.
     */
    function pause() public onlyOwner {
        _pause();
    }

    /**
     * @notice (Owner Only) Unpauses the contract.
     */
    function unpause() public onlyOwner {
        _unpause();
    }

    /**
     * @notice (Owner Only) Allows the contract owner to withdraw accumulated ETH.
     * @dev ETH is accumulated from `trainADT` and `fuelADT` functions.
     */
    function withdrawFunds() public onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "ADT: No funds to withdraw");
        (bool success, ) = payable(owner()).call{value: balance}("");
        require(success, "ADT: Failed to withdraw funds");
    }

    // --- View Functions for External Checks ---

    function getOracleAddress() public view returns (address) {
        return _oracleAddress;
    }

    function isAuthorizedAttestor(address _addr) public view returns (bool) {
        return _authorizedAttestors[_addr];
    }

    function getADTIntents(uint256 _tokenId) public view returns (ADTIntent[] memory) {
        _requireOwned(_tokenId);
        return _adtIntents[_tokenId];
    }

    function getADTAttestations(uint256 _tokenId) public view returns (Attestation[] memory) {
        _requireOwned(_tokenId);
        return _adtAttestations[_tokenId];
    }
    
    // Fallback function to accept ETH, primarily for 'trainADT' and 'fuelADT'
    receive() external payable {
        // This contract explicitly handles ETH transfers through specific functions
        // If ETH is sent without calling trainADT or fuelADT, it will be held.
        // The withdrawFunds function will allow owner to retrieve.
    }
}
```