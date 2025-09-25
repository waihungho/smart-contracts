Here's a smart contract written in Solidity that embodies advanced concepts, creative functionality, and trendy features, while aiming to provide a unique combination of functionalities not directly copied from standard open-source projects.

This contract, `PersonaNexus`, establishes a **Dynamic On-Chain Identity Protocol** where users mint non-transferable **Adaptive Personas (Soulbound NFTs)**. These personas evolve with dynamic traits, a reputation system, and participate in a multi-stage **Intent-Based Interaction Protocol**. An oracle system is integrated for external validation and attribute attestation.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol"; // For withdrawStuckFunds

// --- Custom Errors ---
error PersonaNexus__NotPersonaOwner();
error PersonaNexus__PersonaDoesNotExist();
error PersonaNexus__PersonaAlreadyExists();
error PersonaNexus__InvalidPersonaStatus();
error PersonaNexus__TraitDoesNotExist();
error PersonaNexus__TraitIsSoulbound();
error PersonaNexus__ZeroReputationBoost();
error PersonaNexus__IntentDoesNotExist();
error PersonaNexus__IntentNotOpen();
error PersonaNexus__IntentNotProposer();
error PersonaNexus__NotAcceptedFulfiller();
error PersonaNexus__IntentAlreadyFulfilled();
error PersonaNexus__InvalidDeadline();
error PersonaNexus__ReputationThresholdNotMet();
error PersonaNexus__OracleNotAuthorized();
error PersonaNexus__NoMatchingIntentsFound();
error PersonaNexus__InvalidInputLength();
error PersonaNexus__TraitAlreadyExists();
error PersonaNexus__IntentNotInAcceptedState();
error PersonaNexus__IntentExpired();
error PersonaNexus__NoProposalFromFulfiller();
error PersonaNexus__IntentCannotBeCancelled();


/**
 * @title PersonaNexus - Adaptive On-Chain Persona & Intent Protocol
 * @dev This contract implements a novel decentralized identity and interaction system.
 *      It leverages a non-transferable ERC-721 token (Soulbound Token concept) for core identity,
 *      introduces dynamic traits that can be soulbound or mutable, a dynamic reputation system
 *      with user-triggered decay, and a multi-stage intent-based protocol for collaborations.
 *      An oracle system allows for external validation of attributes and intent fulfillment.
 *
 * Outline and Function Summary:
 *
 * I. Core Persona Management (ERC-721 Soulbound Token)
 *    1.  `createPersona(string calldata _name)`: Mints a new non-transferable Persona NFT for the caller.
 *    2.  `updatePersonaName(uint256 _personaId, string calldata _newName)`: Allows persona owner to change its display name.
 *    3.  `setPersonaStatus(uint256 _personaId, PersonaStatus _newStatus)`: Owner manages persona visibility/activity (Active, Inactive, Private).
 *    4.  `getPersonaDetails(uint256 _personaId)`: View function to retrieve core persona data.
 *    5.  `personaExists(uint256 _personaId)`: Checks if a persona ID is valid and exists.
 *    6.  `tokenURI(uint256 _personaId)`: Generates dynamic metadata URI for the Persona NFT, reflecting its traits and reputation.
 *
 * II. Dynamic Traits & Attributes
 *    7.  `addTrait(uint256 _personaId, string calldata _key, bytes32 _value, bool _isSoulbound)`: Adds a trait; can be owner-mutable or soulbound (immutable by owner).
 *    8.  `updateTrait(uint256 _personaId, string calldata _key, bytes32 _newValue)`: Updates a *mutable* trait of a persona.
 *    9.  `removeTrait(uint256 _personaId, string calldata _key)`: Removes a *mutable* trait from a persona.
 *    10. `getTrait(uint256 _personaId, string calldata _key)`: Retrieves a specific trait's value for a persona.
 *    11. `getPersonaTraitKeys(uint256 _personaId)`: Retrieves all trait keys associated with a persona.
 *
 * III. Reputation & Scoring System
 *    12. `updateReputationScoreInternal(uint256 _personaId, int256 _delta)`: Internal function to modify a persona's dynamic reputation.
 *    13. `getReputationScore(uint256 _personaId)`: View function to get current reputation, applying decay logic.
 *    14. `decayReputation(uint256 _personaId)`: User-triggered function to explicitly apply reputation decay based on inactivity.
 *
 * IV. Intent-Based Interaction Protocol (Multi-stage Fulfillment)
 *    15. `declareIntent(uint256 _proposerPersonaId, IntentType _type, bytes32 _descriptionHash, string[] calldata _requiredTraitKeys, bytes32[] calldata _requiredTraitValues, uint256 _minReputationNeeded, uint256 _deadline)`: Creates a new intent, specifying requirements for fulfillment.
 *    16. `proposeFulfillment(bytes32 _intentHash, uint256 _fulfillerPersonaId, bytes32 _proposalHash)`: A persona proposes to fulfill an open intent.
 *    17. `acceptFulfillmentProposal(bytes32 _intentHash, uint256 _acceptedFulfillerPersonaId)`: The intent proposer accepts a specific fulfillment proposal.
 *    18. `submitProofOfFulfillment(bytes32 _intentHash, bytes32 _proofHash)`: The accepted fulfiller submits cryptographic proof of fulfillment.
 *    19. `verifyAndCompleteIntent(bytes32 _intentHash, uint256 _reputationBoostForFulfiller)`: Intent proposer or an Oracle verifies proof, completes intent, and boosts fulfiller's reputation.
 *    20. `cancelIntent(bytes32 _intentHash)`: The intent proposer can cancel an open or proposed intent.
 *    21. `getIntentDetails(bytes32 _intentHash)`: Retrieves all details of a specific intent.
 *    22. `findMatchingIntents(uint256 _querierPersonaId, IntentType _matchType)`: Finds open intents matching a persona's traits and reputation.
 *
 * V. Attestation & Oracle System
 *    23. `attestPersonaAttribute(uint256 _targetPersonaId, string calldata _key, bytes32 _value, bytes32 _statementHash, uint256 _weight, bool _isPositive)`: An authorized oracle can attest to a persona's attribute, influencing reputation.
 *    24. `setOracleAddress(address _oracle, bool _isOracle)`: Owner manages authorized oracle addresses.
 *
 * VI. Governance & Configuration
 *    25. `setReputationDecayPeriod(uint256 _period)`: Configures the time period for reputation decay.
 *    26. `setBaseReputationBoost(uint256 _boost)`: Configures the default reputation boost for successful intent fulfillment.
 *    27. `withdrawStuckFunds(address _tokenAddress)`: Allows the owner to recover accidentally sent ERC20 or native ETH from the contract.
 */
contract PersonaNexus is ERC721, Ownable, ReentrancyGuard {
    using Counters for Counters.Counter;
    using Strings for uint256;

    // --- Enums ---
    enum PersonaStatus {
        Active,    // Persona is fully active and can participate
        Inactive,  // Persona is temporarily inactive (cannot declare/fulfill intents)
        Private    // Persona details are private (cannot be discovered by findMatchingIntents)
    }

    enum IntentType {
        General,
        Collaboration,
        Funding,
        Mentorship,
        Research,
        Development,
        Arbitration // Added for more diverse intents
    }

    enum IntentStatus {
        Open,           // Actively seeking fulfillers
        ProposalMade,   // One or more proposals received
        Accepted,       // Proposer accepted a fulfiller, awaiting proof
        Fulfilled,      // Proof submitted and verified
        Cancelled,      // Proposer cancelled the intent
        Expired         // Deadline passed without fulfillment
    }

    // --- Structs ---
    struct Persona {
        address owner;
        string name;
        PersonaStatus status;
        uint256 reputationScore;
        uint256 lastReputationUpdate; // Timestamp for decay calculation
        uint256 creationTime;
    }

    struct Intent {
        uint256 proposerPersonaId;
        IntentType intentType;
        bytes32 descriptionHash; // IPFS/Arweave hash for detailed description
        uint256 creationTime;
        uint256 deadline;
        uint256 minReputationNeeded;
        IntentStatus status;
        uint256 acceptedFulfillerPersonaId; // 0 if no fulfiller accepted yet
        bytes32 proofOfFulfillmentHash; // Hash of the proof provided by fulfiller
        uint256 fulfillmentTime;
        mapping(uint256 => bytes32) proposals; // personaId => proposalHash
        uint256[] proposers; // Track proposers for easy iteration of submitted proposals
    }

    // --- State Variables ---
    Counters.Counter private _personaIds;
    Counters.Counter private _intentHashesCounter; // Used to generate unique IDs for intentHashes (to ensure uniqueness when hashing)

    mapping(uint256 => Persona) public personas;
    mapping(address => uint256) public ownerToPersonaId; // Maps an owner address to their personaId (1:1 relationship)

    // Separate mappings for dynamic traits (because mappings inside structs are not supported for storage)
    mapping(uint256 => mapping(string => bytes32)) private personaTraits;
    mapping(uint256 => mapping(string => bool)) private isSoulboundTrait; // True if trait is immutable by owner or Oracle
    mapping(uint256 => string[]) private personaTraitKeys; // To retrieve all trait keys for metadata generation

    mapping(bytes32 => Intent) public intents; // intentHash => Intent details
    mapping(bytes32 => mapping(string => bytes32)) private intentRequiredTraits; // Stores trait requirements for intents
    mapping(bytes32 => string[]) private intentRequiredTraitKeys; // To retrieve all required trait keys for an intent

    bytes32[] public openIntentHashes; // Stores hashes of intents that are currently open or have proposals
    mapping(bytes32 => bool) private _isOpenIntentInList; // Quick check if an intent is in openIntentHashes array

    mapping(address => bool) public authorizedOracles; // Addresses authorized to provide attestations

    uint256 public reputationDecayPeriod = 365 days; // Default to 1 year
    uint256 public baseReputationBoost = 50; // Default boost for successful intent fulfillment

    // --- Events ---
    event PersonaCreated(uint256 indexed personaId, address indexed owner, string name, uint256 creationTime);
    event PersonaNameUpdated(uint256 indexed personaId, string newName);
    event PersonaStatusUpdated(uint256 indexed personaId, PersonaStatus newStatus);
    event TraitAdded(uint256 indexed personaId, string key, bytes32 value, bool isSoulbound);
    event TraitUpdated(uint256 indexed personaId, string key, bytes32 oldValue, bytes32 newValue);
    event TraitRemoved(uint256 indexed personaId, string key, bytes32 value);
    event ReputationScoreUpdated(uint256 indexed personaId, int256 delta, uint256 newScore);
    event IntentDeclared(bytes32 indexed intentHash, uint256 indexed proposerPersonaId, IntentType intentType, uint256 deadline);
    event ProposalMade(bytes32 indexed intentHash, uint256 indexed fulfillerPersonaId, bytes32 proposalHash);
    event FulfillmentProposalAccepted(bytes32 indexed intentHash, uint256 indexed acceptedFulfillerPersonaId);
    event ProofSubmitted(bytes32 indexed intentHash, uint256 indexed fulfillerPersonaId, bytes32 proofHash);
    event IntentCompleted(bytes32 indexed intentHash, uint256 indexed fulfillerPersonaId, uint256 reputationBoost);
    event IntentCancelled(bytes32 indexed intentHash);
    event AttestationMade(address indexed attester, uint256 indexed targetPersonaId, string key, bytes32 value, bool isPositive);
    event OracleSet(address indexed oracleAddress, bool isAuthorized);

    // --- Constructor ---
    constructor(string memory name, string memory symbol) ERC721(name, symbol) Ownable(msg.sender) {}

    // --- Modifiers ---
    modifier onlyPersonaOwner(uint256 _personaId) {
        if (!personaExists(_personaId) || personas[_personaId].owner != _msgSender()) {
            revert PersonaNexus__NotPersonaOwner();
        }
        _;
    }

    modifier onlyPersonaActive(uint256 _personaId) {
        if (!personaExists(_personaId) || personas[_personaId].status != PersonaStatus.Active) {
            revert PersonaNexus__InvalidPersonaStatus();
        }
        _;
    }

    modifier onlyIntentProposer(bytes32 _intentHash) {
        if (!personaExists(intents[_intentHash].proposerPersonaId) ||
            personas[intents[_intentHash].proposerPersonaId].owner != _msgSender()) {
            revert PersonaNexus__IntentNotProposer();
        }
        _;
    }

    modifier onlyAcceptedFulfiller(bytes32 _intentHash) {
        if (!personaExists(intents[_intentHash].acceptedFulfillerPersonaId) ||
            personas[intents[_intentHash].acceptedFulfillerPersonaId].owner != _msgSender()) {
            revert PersonaNexus__NotAcceptedFulfiller();
        }
        _;
    }

    modifier onlyOracle() {
        if (!authorizedOracles[_msgSender()]) {
            revert PersonaNexus__OracleNotAuthorized();
        }
        _;
    }

    // --- ERC721 Overrides (for Soulbound Token behavior) ---
    // Make tokens non-transferable by reverting on transfer functions
    function _transfer(address from, address to, uint256 tokenId) internal pure override {
        revert("PersonaNexus: Personas are soulbound and cannot be transferred");
    }

    function approve(address to, uint256 tokenId) public pure override {
        revert("PersonaNexus: Personas are soulbound and cannot be approved for transfer");
    }

    function setApprovalForAll(address operator, bool approved) public pure override {
        revert("PersonaNexus: Personas are soulbound and cannot be approved for all transfers");
    }

    function transferFrom(address from, address to, uint256 tokenId) public pure override {
        revert("PersonaNexus: Personas are soulbound and cannot be transferred");
    }

    // Standard ERC721 view functions (still useful for enumeration and checking ownership)
    function balanceOf(address owner) public view override returns (uint256) {
        return ownerToPersonaId[owner] != 0 ? 1 : 0;
    }

    function ownerOf(uint256 tokenId) public view override returns (address) {
        if (!personaExists(tokenId)) {
            revert PersonaNexus__PersonaDoesNotExist();
        }
        return personas[tokenId].owner;
    }

    /**
     * @summary Generates dynamic metadata URI for the Persona NFT.
     * @dev The metadata includes persona's name, description, reputation, status, and all dynamic traits.
     * @param _personaId The ID of the persona.
     * @return A JSON string representing the NFT metadata.
     */
    function tokenURI(uint256 _personaId) public view override returns (string memory) {
        if (!personaExists(_personaId)) {
            revert PersonaNexus__PersonaDoesNotExist();
        }
        
        Persona storage persona = personas[_personaId];
        
        string memory json = string(abi.encodePacked(
            '{"name": "', persona.name, ' #', _personaId.toString(), '",',
            '"description": "An Adaptive On-Chain Persona. Reputation: ', getReputationScore(_personaId).toString(), '",', // Get calculated reputation
            '"image": "ipfs://QmbD2Vb4A7h7S4Z2y1c2n7g6x8j9k0l1m2n3o4p5q6",', // Placeholder image hash for dynamic rendering off-chain
            '"attributes": ['
        ));

        // Add core attributes
        json = string(abi.encodePacked(json, '{"trait_type": "Reputation", "value": "', getReputationScore(_personaId).toString(), '"},'));
        json = string(abi.encodePacked(json, '{"trait_type": "Status", "value": "', _statusToString(persona.status), '"},'));
        json = string(abi.encodePacked(json, '{"trait_type": "Creation Time", "value": "', persona.creationTime.toString(), '"}'));

        // Add dynamic traits
        string[] memory keys = personaTraitKeys[_personaId];
        for (uint i = 0; i < keys.length; i++) {
            string memory key = keys[i];
            bytes32 value = personaTraits[_personaId][key];
            json = string(abi.encodePacked(json, ',', '{"trait_type": "', key, '", "value": "', string(abi.encodePacked("0x", Strings.toHexString(uint256(value)))), '", "display_type": "string"}'));
        }

        json = string(abi.encodePacked(json, ']}'));
        return json;
    }

    /**
     * @dev Internal helper to convert PersonaStatus enum to string.
     * @param _status The PersonaStatus enum value.
     * @return The string representation of the status.
     */
    function _statusToString(PersonaStatus _status) internal pure returns (string memory) {
        if (_status == PersonaStatus.Active) return "Active";
        if (_status == PersonaStatus.Inactive) return "Inactive";
        if (_status == PersonaStatus.Private) return "Private";
        return "Unknown";
    }

    // --- Utility View Functions ---
    /**
     * @summary Checks if a persona with the given ID exists.
     * @param _personaId The ID of the persona.
     * @return True if the persona exists, false otherwise.
     */
    function personaExists(uint256 _personaId) public view returns (bool) {
        return _exists(_personaId); // Uses ERC721's internal _exists
    }

    // --- I. Core Persona Management (ERC-721 SBT) ---

    /**
     * @summary Creates a new non-transferable Persona NFT for the caller.
     * @dev Each address can only own one persona. Mints an ERC721 token and initializes core persona data.
     * @param _name The display name for the new persona.
     * @return newPersonaId The unique ID of the newly created persona.
     */
    function createPersona(string calldata _name) public nonReentrant returns (uint256) {
        if (ownerToPersonaId[_msgSender()] != 0) {
            revert PersonaNexus__PersonaAlreadyExists();
        }

        _personaIds.increment();
        uint256 newPersonaId = _personaIds.current();

        Persona storage newPersona = personas[newPersonaId];
        newPersona.owner = _msgSender();
        newPersona.name = _name;
        newPersona.status = PersonaStatus.Active;
        newPersona.reputationScore = 100; // Starting reputation
        newPersona.lastReputationUpdate = block.timestamp;
        newPersona.creationTime = block.timestamp;

        ownerToPersonaId[_msgSender()] = newPersonaId;
        _safeMint(_msgSender(), newPersonaId); // Mints the ERC721 token, making it an SBT

        emit PersonaCreated(newPersonaId, _msgSender(), _name, block.timestamp);
        return newPersonaId;
    }

    /**
     * @summary Allows the persona owner to update their persona's display name.
     * @param _personaId The ID of the persona to update.
     * @param _newName The new display name.
     */
    function updatePersonaName(uint256 _personaId, string calldata _newName)
        public
        onlyPersonaOwner(_personaId)
        nonReentrant
    {
        string memory oldName = personas[_personaId].name; // Stored for event, if needed.
        personas[_personaId].name = _newName;
        emit PersonaNameUpdated(_personaId, _newName);
    }

    /**
     * @summary Allows the owner to set their persona's status (Active, Inactive, Private).
     * @dev An Inactive persona cannot declare or fulfill intents. A Private persona cannot be found by `findMatchingIntents`.
     * @param _personaId The ID of the persona.
     * @param _newStatus The new status for the persona.
     */
    function setPersonaStatus(uint256 _personaId, PersonaStatus _newStatus)
        public
        onlyPersonaOwner(_personaId)
        nonReentrant
    {
        personas[_personaId].status = _newStatus;
        emit PersonaStatusUpdated(_personaId, _newStatus);
    }

    /**
     * @summary Retrieves the core details of a persona.
     * @param _personaId The ID of the persona.
     * @return owner The address of the persona owner.
     * @return name The display name of the persona.
     * @return status The current status of the persona.
     * @return reputationScore The current reputation score.
     * @return creationTime The creation timestamp of the persona.
     */
    function getPersonaDetails(uint256 _personaId)
        public
        view
        returns (address owner, string memory name, PersonaStatus status, uint256 reputationScore, uint256 creationTime)
    {
        if (!personaExists(_personaId)) {
            revert PersonaNexus__PersonaDoesNotExist();
        }
        Persona storage p = personas[_personaId];
        return (p.owner, p.name, p.status, getReputationScore(_personaId), p.creationTime);
    }

    // --- II. Dynamic Traits & Attributes ---

    /**
     * @summary Adds a new trait to a persona. Traits can be soulbound (immutable by owner) or mutable.
     * @param _personaId The ID of the persona.
     * @param _key The identifier for the trait (e.g., "expertise", "affiliation").
     * @param _value The bytes32 value of the trait.
     * @param _isSoulbound If true, the trait cannot be updated or removed by the owner.
     */
    function addTrait(uint256 _personaId, string calldata _key, bytes32 _value, bool _isSoulbound)
        public
        onlyPersonaOwner(_personaId)
        nonReentrant
    {
        if (personaTraits[_personaId][_key] != bytes32(0)) {
            revert PersonaNexus__TraitAlreadyExists();
        }

        personaTraits[_personaId][_key] = _value;
        isSoulboundTrait[_personaId][_key] = _isSoulbound;
        personaTraitKeys[_personaId].push(_key); // For easy enumeration in tokenURI

        emit TraitAdded(_personaId, _key, _value, _isSoulbound);
    }

    /**
     * @summary Updates a mutable trait for a persona.
     * @dev Soulbound traits cannot be updated by the owner.
     * @param _personaId The ID of the persona.
     * @param _key The identifier for the trait.
     * @param _newValue The new bytes32 value for the trait.
     */
    function updateTrait(uint256 _personaId, string calldata _key, bytes32 _newValue)
        public
        onlyPersonaOwner(_personaId)
        nonReentrant
    {
        if (personaTraits[_personaId][_key] == bytes32(0)) {
            revert PersonaNexus__TraitDoesNotExist();
        }
        if (isSoulboundTrait[_personaId][_key]) {
            revert PersonaNexus__TraitIsSoulbound();
        }
        bytes32 oldValue = personaTraits[_personaId][_key];
        personaTraits[_personaId][_key] = _newValue;
        emit TraitUpdated(_personaId, _key, oldValue, _newValue);
    }

    /**
     * @summary Removes a mutable trait from a persona.
     * @dev Soulbound traits cannot be removed by the owner.
     * @param _personaId The ID of the persona.
     * @param _key The identifier for the trait to remove.
     */
    function removeTrait(uint256 _personaId, string calldata _key)
        public
        onlyPersonaOwner(_personaId)
        nonReentrant
    {
        if (personaTraits[_personaId][_key] == bytes32(0)) {
            revert PersonaNexus__TraitDoesNotExist();
        }
        if (isSoulboundTrait[_personaId][_key]) {
            revert PersonaNexus__TraitIsSoulbound();
        }
        bytes32 removedValue = personaTraits[_personaId][_key];
        delete personaTraits[_personaId][_key];
        delete isSoulboundTrait[_personaId][_key];

        // Remove from personaTraitKeys array (inefficient for very large arrays, but acceptable for reasonable trait counts)
        string[] storage keys = personaTraitKeys[_personaId];
        for (uint i = 0; i < keys.length; i++) {
            if (keccak256(abi.encodePacked(keys[i])) == keccak256(abi.encodePacked(_key))) {
                keys[i] = keys[keys.length - 1]; // Replace with last element
                keys.pop(); // Shrink array
                break;
            }
        }
        emit TraitRemoved(_personaId, _key, removedValue);
    }

    /**
     * @summary Retrieves the value of a specific trait for a persona.
     * @param _personaId The ID of the persona.
     * @param _key The identifier for the trait.
     * @return The bytes32 value of the trait. Returns bytes32(0) if not found.
     */
    function getTrait(uint256 _personaId, string calldata _key) public view returns (bytes32) {
        if (!personaExists(_personaId)) {
            revert PersonaNexus__PersonaDoesNotExist();
        }
        return personaTraits[_personaId][_key];
    }

    /**
     * @summary Retrieves all trait keys associated with a persona.
     * @param _personaId The ID of the persona.
     * @return An array of strings, each representing a trait key.
     */
    function getPersonaTraitKeys(uint256 _personaId) public view returns (string[] memory) {
        if (!personaExists(_personaId)) {
            revert PersonaNexus__PersonaDoesNotExist();
        }
        return personaTraitKeys[_personaId];
    }

    // --- III. Reputation & Scoring System ---

    /**
     * @summary Internal function to update a persona's reputation score.
     * @dev This function is called by other contract functions (e.g., intent completion, attestations).
     * @param _personaId The ID of the persona whose reputation is being updated.
     * @param _delta The amount to change the reputation by (can be positive or negative).
     */
    function updateReputationScoreInternal(uint256 _personaId, int256 _delta) internal {
        Persona storage p = personas[_personaId];
        if (_delta == 0) return;

        // Apply decay before updating, to ensure `lastReputationUpdate` is current
        _applyReputationDecay(p);

        if (_delta > 0) {
            p.reputationScore += uint256(_delta);
        } else {
            if (p.reputationScore < uint256(-_delta)) {
                p.reputationScore = 0;
            } else {
                p.reputationScore -= uint256(-_delta);
            }
        }
        p.lastReputationUpdate = block.timestamp; // Update timestamp only if score changed
        emit ReputationScoreUpdated(_personaId, _delta, p.reputationScore);
    }

    /**
     * @dev Internal helper function to apply reputation decay.
     * @param _persona The persona storage reference.
     */
    function _applyReputationDecay(Persona storage _persona) internal {
        if (reputationDecayPeriod > 0 && _persona.lastReputationUpdate < block.timestamp) {
            uint256 timeElapsed = block.timestamp - _persona.lastReputationUpdate;
            uint256 decayPeriods = timeElapsed / reputationDecayPeriod;
            uint256 decayAmount = (_persona.reputationScore * decayPeriods) / 100; // 1% decay per period

            if (decayAmount > 0) {
                if (decayAmount >= _persona.reputationScore) {
                    _persona.reputationScore = 0;
                } else {
                    _persona.reputationScore -= decayAmount;
                }
                _persona.lastReputationUpdate = block.timestamp;
            }
        }
    }

    /**
     * @summary Retrieves the current reputation score of a persona.
     * @dev This function applies decay logic *on-the-fly* before returning the score.
     * @param _personaId The ID of the persona.
     * @return The current reputation score.
     */
    function getReputationScore(uint256 _personaId) public view returns (uint256) {
        if (!personaExists(_personaId)) {
            revert PersonaNexus__PersonaDoesNotExist();
        }
        Persona storage p = personas[_personaId];
        uint256 currentScore = p.reputationScore;

        if (reputationDecayPeriod > 0 && p.lastReputationUpdate < block.timestamp) {
            uint256 timeElapsed = block.timestamp - p.lastReputationUpdate;
            uint256 decayPeriods = timeElapsed / reputationDecayPeriod;
            // Simple linear decay: 1% per decay period
            uint256 decayAmount = (currentScore * decayPeriods) / 100;
            if (decayAmount >= currentScore) {
                currentScore = 0;
            } else {
                currentScore -= decayAmount;
            }
        }
        return currentScore;
    }

    /**
     * @summary Allows a user to manually trigger the reputation decay calculation for their persona.
     * @dev This updates the stored `reputationScore` after applying decay, and updates `lastReputationUpdate`.
     * @param _personaId The ID of the persona.
     */
    function decayReputation(uint256 _personaId) public onlyPersonaOwner(_personaId) nonReentrant {
        Persona storage p = personas[_personaId];
        uint256 oldScore = p.reputationScore;
        _applyReputationDecay(p);
        if (p.reputationScore != oldScore) {
            emit ReputationScoreUpdated(_personaId, int256(p.reputationScore) - int256(oldScore), p.reputationScore);
        }
    }

    // --- IV. Intent-Based Interaction Protocol ---

    /**
     * @dev Internal helper to generate a unique intent hash.
     * @param _proposerPersonaId The persona ID of the proposer.
     * @param _creationTime The timestamp of intent creation.
     * @return The unique intent hash.
     */
    function _generateIntentHash(uint256 _proposerPersonaId, uint256 _creationTime) internal returns (bytes32) {
        _intentHashesCounter.increment();
        return keccak256(abi.encodePacked(_proposerPersonaId, _intentHashesCounter.current(), _creationTime));
    }

    /**
     * @dev Internal helper to remove an intent from the `openIntentHashes` list.
     * @param _intentHash The hash of the intent to remove.
     */
    function _removeIntentFromOpenList(bytes32 _intentHash) internal {
        if (_isOpenIntentInList[_intentHash]) {
            for (uint i = 0; i < openIntentHashes.length; i++) {
                if (openIntentHashes[i] == _intentHash) {
                    openIntentHashes[i] = openIntentHashes[openIntentHashes.length - 1]; // Swap with last element
                    openIntentHashes.pop(); // Remove last element
                    _isOpenIntentInList[_intentHash] = false;
                    break;
                }
            }
        }
    }

    /**
     * @summary Declares a new intent, specifying required traits and reputation for fulfillment.
     * @param _proposerPersonaId The ID of the persona declaring the intent.
     * @param _type The category of the intent (e.g., Collaboration, Funding).
     * @param _descriptionHash IPFS/Arweave hash for a detailed description of the intent.
     * @param _requiredTraitKeys Array of keys for traits required by a fulfiller.
     * @param _requiredTraitValues Array of corresponding values for required traits.
     * @param _minReputationNeeded Minimum reputation score required for a fulfiller.
     * @param _deadline Timestamp by which the intent must be fulfilled.
     * @return intentHash The unique hash identifying the declared intent.
     */
    function declareIntent(
        uint256 _proposerPersonaId,
        IntentType _type,
        bytes32 _descriptionHash,
        string[] calldata _requiredTraitKeys,
        bytes32[] calldata _requiredTraitValues,
        uint256 _minReputationNeeded,
        uint256 _deadline
    ) public onlyPersonaOwner(_proposerPersonaId) onlyPersonaActive(_proposerPersonaId) nonReentrant returns (bytes32) {
        if (_deadline <= block.timestamp) {
            revert PersonaNexus__InvalidDeadline();
        }
        if (_requiredTraitKeys.length != _requiredTraitValues.length) {
            revert PersonaNexus__InvalidInputLength();
        }

        bytes32 intentHash = _generateIntentHash(_proposerPersonaId, block.timestamp);

        Intent storage newIntent = intents[intentHash];
        newIntent.proposerPersonaId = _proposerPersonaId;
        newIntent.intentType = _type;
        newIntent.descriptionHash = _descriptionHash;
        newIntent.creationTime = block.timestamp;
        newIntent.deadline = _deadline;
        newIntent.minReputationNeeded = _minReputationNeeded;
        newIntent.status = IntentStatus.Open;

        for (uint i = 0; i < _requiredTraitKeys.length; i++) {
            intentRequiredTraits[intentHash][_requiredTraitKeys[i]] = _requiredTraitValues[i];
            intentRequiredTraitKeys[intentHash].push(_requiredTraitKeys[i]);
        }

        openIntentHashes.push(intentHash); // Add to active list
        _isOpenIntentInList[intentHash] = true;

        emit IntentDeclared(intentHash, _proposerPersonaId, _type, _deadline);
        return intentHash;
    }

    /**
     * @summary Allows a persona to propose fulfillment for an open intent.
     * @dev The proposing persona must meet the intent's minimum reputation and required traits.
     * @param _intentHash The hash of the intent to propose fulfillment for.
     * @param _fulfillerPersonaId The ID of the persona proposing to fulfill.
     * @param _proposalHash IPFS/Arweave hash detailing the fulfillment proposal.
     */
    function proposeFulfillment(bytes32 _intentHash, uint256 _fulfillerPersonaId, bytes32 _proposalHash)
        public
        onlyPersonaOwner(_fulfillerPersonaId)
        onlyPersonaActive(_fulfillerPersonaId)
        nonReentrant
    {
        Intent storage intent = intents[_intentHash];
        if (intent.proposerPersonaId == 0) { // Check if intent exists
            revert PersonaNexus__IntentDoesNotExist();
        }
        if (intent.status != IntentStatus.Open && intent.status != IntentStatus.ProposalMade) {
            revert PersonaNexus__IntentNotOpen();
        }
        if (block.timestamp > intent.deadline) {
            intent.status = IntentStatus.Expired; // Update status if past deadline
            _removeIntentFromOpenList(_intentHash);
            revert PersonaNexus__IntentExpired();
        }
        if (getReputationScore(_fulfillerPersonaId) < intent.minReputationNeeded) {
            revert PersonaNexus__ReputationThresholdNotMet();
        }

        // Check if fulfiller has all required traits
        string[] memory requiredKeys = intentRequiredTraitKeys[_intentHash];
        for (uint i = 0; i < requiredKeys.length; i++) {
            string memory key = requiredKeys[i];
            if (personaTraits[_fulfillerPersonaId][key] != intentRequiredTraits[_intentHash][key]) {
                revert("PersonaNexus: Fulfiller does not meet all required traits.");
            }
        }

        // Add proposer to the list if not already there, and store proposal
        bool alreadyProposed = false;
        for(uint i = 0; i < intent.proposers.length; i++) {
            if (intent.proposers[i] == _fulfillerPersonaId) {
                alreadyProposed = true;
                break;
            }
        }
        if (!alreadyProposed) {
            intent.proposers.push(_fulfillerPersonaId);
        }
        intent.proposals[_fulfillerPersonaId] = _proposalHash;
        intent.status = IntentStatus.ProposalMade; // Update status if this is the first proposal

        emit ProposalMade(_intentHash, _fulfillerPersonaId, _proposalHash);
    }

    /**
     * @summary The intent proposer accepts a specific fulfillment proposal.
     * @param _intentHash The hash of the intent.
     * @param _acceptedFulfillerPersonaId The ID of the persona whose proposal is accepted.
     */
    function acceptFulfillmentProposal(bytes32 _intentHash, uint256 _acceptedFulfillerPersonaId)
        public
        onlyIntentProposer(_intentHash)
        nonReentrant
    {
        Intent storage intent = intents[_intentHash];
        if (intent.proposerPersonaId == 0) {
            revert PersonaNexus__IntentDoesNotExist();
        }
        if (intent.status == IntentStatus.Fulfilled || intent.status == IntentStatus.Cancelled || intent.status == IntentStatus.Expired) {
            revert PersonaNexus__IntentAlreadyFulfilled();
        }
        if (block.timestamp > intent.deadline) {
            intent.status = IntentStatus.Expired;
            _removeIntentFromOpenList(_intentHash);
            revert PersonaNexus__IntentExpired();
        }
        if (intent.proposals[_acceptedFulfillerPersonaId] == bytes32(0)) {
            revert PersonaNexus__NoProposalFromFulfiller();
        }

        intent.acceptedFulfillerPersonaId = _acceptedFulfillerPersonaId;
        intent.status = IntentStatus.Accepted;

        emit FulfillmentProposalAccepted(_intentHash, _acceptedFulfillerPersonaId);
    }

    /**
     * @summary The accepted fulfiller submits proof of fulfillment.
     * @param _intentHash The hash of the intent.
     * @param _proofHash IPFS/Arweave hash for the proof of fulfillment.
     */
    function submitProofOfFulfillment(bytes32 _intentHash, bytes32 _proofHash)
        public
        onlyAcceptedFulfiller(_intentHash)
        nonReentrant
    {
        Intent storage intent = intents[_intentHash];
        if (intent.proposerPersonaId == 0) {
            revert PersonaNexus__IntentDoesNotExist();
        }
        if (intent.status != IntentStatus.Accepted) {
            revert PersonaNexus__IntentNotInAcceptedState();
        }
        if (block.timestamp > intent.deadline) {
            intent.status = IntentStatus.Expired;
            _removeIntentFromOpenList(_intentHash);
            revert PersonaNexus__IntentExpired();
        }

        intent.proofOfFulfillmentHash = _proofHash;
        emit ProofSubmitted(_intentHash, intent.acceptedFulfillerPersonaId, _proofHash);
    }

    /**
     * @summary The original intent proposer (or an authorized oracle) verifies the proof and completes the intent.
     * @dev This boosts the fulfiller's reputation. Requires a submitted proof.
     * @param _intentHash The hash of the intent.
     * @param _reputationBoostForFulfiller Additional reputation points for the fulfiller (beyond base).
     */
    function verifyAndCompleteIntent(bytes32 _intentHash, uint256 _reputationBoostForFulfiller)
        public
        nonReentrant
    {
        Intent storage intent = intents[_intentHash];
        if (intent.proposerPersonaId == 0) {
            revert PersonaNexus__IntentDoesNotExist();
        }
        if (intent.status != IntentStatus.Accepted || intent.proofOfFulfillmentHash == bytes32(0)) {
            revert PersonaNexus__IntentNotInAcceptedState();
        }
        if (block.timestamp > intent.deadline) {
            intent.status = IntentStatus.Expired;
            _removeIntentFromOpenList(_intentHash);
            revert PersonaNexus__IntentExpired();
        }

        // Only original proposer or an oracle can complete
        bool isProposer = (personas[intent.proposerPersonaId].owner == _msgSender());
        bool isOracle = authorizedOracles[_msgSender()];

        if (!isProposer && !isOracle) {
            revert("PersonaNexus: Only intent proposer or an authorized oracle can complete.");
        }

        intent.status = IntentStatus.Fulfilled;
        intent.fulfillmentTime = block.timestamp;
        _removeIntentFromOpenList(_intentHash); // Remove from active list as it's fulfilled

        uint256 totalReputationBoost = baseReputationBoost + _reputationBoostForFulfiller;
        if (totalReputationBoost == 0) {
            revert PersonaNexus__ZeroReputationBoost();
        }
        updateReputationScoreInternal(intent.acceptedFulfillerPersonaId, int256(totalReputationBoost));
        
        emit IntentCompleted(_intentHash, intent.acceptedFulfillerPersonaId, totalReputationBoost);
    }

    /**
     * @summary Allows the intent proposer to cancel an open or proposed intent.
     * @dev An intent can only be cancelled if it's still open or has proposals, but not yet accepted for fulfillment.
     * @param _intentHash The hash of the intent to cancel.
     */
    function cancelIntent(bytes32 _intentHash) public onlyIntentProposer(_intentHash) nonReentrant {
        Intent storage intent = intents[_intentHash];
        if (intent.proposerPersonaId == 0) {
            revert PersonaNexus__IntentDoesNotExist();
        }
        if (intent.status == IntentStatus.Accepted || intent.status == IntentStatus.Fulfilled || intent.status == IntentStatus.Expired) {
            revert PersonaNexus__IntentCannotBeCancelled();
        }
        if (block.timestamp > intent.deadline) {
            intent.status = IntentStatus.Expired;
            _removeIntentFromOpenList(_intentHash); // Remove even if expired
            revert PersonaNexus__IntentExpired();
        }

        intent.status = IntentStatus.Cancelled;
        _removeIntentFromOpenList(_intentHash); // Remove from active list
        emit IntentCancelled(_intentHash);
    }

    /**
     * @summary Retrieves all details of a specific intent.
     * @param _intentHash The hash of the intent.
     * @return A tuple containing all intent details.
     */
    function getIntentDetails(bytes32 _intentHash)
        public
        view
        returns (
            uint256 proposerPersonaId,
            IntentType intentType,
            bytes32 descriptionHash,
            uint256 creationTime,
            uint256 deadline,
            uint256 minReputationNeeded,
            IntentStatus status,
            uint256 acceptedFulfillerPersonaId,
            bytes32 proofOfFulfillmentHash,
            uint256 fulfillmentTime,
            uint256[] memory proposersList,
            string[] memory requiredTraitKeysList,
            bytes32[] memory requiredTraitValuesList
        )
    {
        Intent storage intent = intents[_intentHash];
        if (intent.proposerPersonaId == 0) {
            revert PersonaNexus__IntentDoesNotExist();
        }

        // Collect required traits
        requiredTraitKeysList = intentRequiredTraitKeys[_intentHash];
        requiredTraitValuesList = new bytes32[](requiredTraitKeysList.length);
        for (uint i = 0; i < requiredTraitKeysList.length; i++) {
            requiredTraitValuesList[i] = intentRequiredTraits[_intentHash][requiredTraitKeysList[i]];
        }

        return (
            intent.proposerPersonaId,
            intent.intentType,
            intent.descriptionHash,
            intent.creationTime,
            intent.deadline,
            intent.minReputationNeeded,
            intent.status,
            intent.acceptedFulfillerPersonaId,
            intent.proofOfFulfillmentHash,
            intent.fulfillmentTime,
            intent.proposers, // Return the list of unique proposers
            requiredTraitKeysList,
            requiredTraitValuesList
        );
    }

    /**
     * @summary Finds open intents that match a querying persona's capabilities (traits and reputation).
     * @param _querierPersonaId The ID of the persona looking for intents.
     * @param _matchType The type of intent to filter by (General for any type match).
     * @return An array of `bytes32` intent hashes that match the criteria.
     */
    function findMatchingIntents(uint256 _querierPersonaId, IntentType _matchType)
        public
        view
        returns (bytes32[] memory)
    {
        if (!personaExists(_querierPersonaId)) {
            revert PersonaNexus__PersonaDoesNotExist();
        }
        if (personas[_querierPersonaId].status == PersonaStatus.Private) {
            revert("PersonaNexus: Private personas cannot search for intents.");
        }

        uint256 querierReputation = getReputationScore(_querierPersonaId);
        string[] memory querierTraitKeys = personaTraitKeys[_querierPersonaId];

        bytes32[] memory tempMatchingIntents = new bytes32[](openIntentHashes.length); // Max possible matches
        uint256 matchCount = 0;

        for (uint i = 0; i < openIntentHashes.length; i++) {
            bytes32 intentHash = openIntentHashes[i];
            Intent storage intent = intents[intentHash];

            // Basic filters
            if (intent.status != IntentStatus.Open && intent.status != IntentStatus.ProposalMade) {
                continue; // Only consider truly open or awaiting proposals
            }
            if (block.timestamp > intent.deadline) {
                // Should ideally be removed from list, but check defensively
                continue; 
            }
            if (_matchType != IntentType.General && intent.intentType != _matchType) {
                continue;
            }
            if (querierReputation < intent.minReputationNeeded) {
                continue;
            }
            if (intent.proposerPersonaId == _querierPersonaId) {
                continue; // A persona cannot fulfill its own intent
            }


            // Trait matching
            bool allTraitsMatch = true;
            string[] memory requiredKeys = intentRequiredTraitKeys[intentHash];
            for (uint j = 0; j < requiredKeys.length; j++) {
                string memory key = requiredKeys[j];
                bytes32 requiredValue = intentRequiredTraits[intentHash][key];
                bytes32 querierValue = personaTraits[_querierPersonaId][key];

                if (querierValue == bytes32(0) || querierValue != requiredValue) {
                    allTraitsMatch = false;
                    break;
                }
            }

            if (allTraitsMatch) {
                tempMatchingIntents[matchCount] = intentHash;
                matchCount++;
            }
        }

        if (matchCount == 0) {
            revert PersonaNexus__NoMatchingIntentsFound();
        }

        bytes32[] memory result = new bytes32[](matchCount);
        for (uint i = 0; i < matchCount; i++) {
            result[i] = tempMatchingIntents[i];
        }
        return result;
    }


    // --- V. Attestation & Oracle System ---

    /**
     * @summary An authorized oracle or trusted entity can attest to a persona's attribute, influencing reputation.
     * @dev This allows for external validation and can add or update soulbound traits, overriding owner's mutability restrictions.
     * @param _targetPersonaId The ID of the persona being attested.
     * @param _key The trait key being attested (e.g., "verifiedExpertise", "KYC_status").
     * @param _value The attested value for the trait.
     * @param _statementHash IPFS/Arweave hash for a detailed attestation statement/proof.
     * @param _weight The impact weight of this attestation on reputation.
     * @param _isPositive If true, reputation is boosted; if false, it's reduced.
     */
    function attestPersonaAttribute(
        uint256 _targetPersonaId,
        string calldata _key,
        bytes32 _value,
        bytes32 _statementHash, // Placeholder for external proof or statement (can be IPFS hash)
        uint256 _weight,
        bool _isPositive
    ) public onlyOracle nonReentrant {
        if (!personaExists(_targetPersonaId)) {
            revert PersonaNexus__PersonaDoesNotExist();
        }
        if (_weight == 0) {
            revert("PersonaNexus: Attestation weight must be greater than zero.");
        }

        // Oracles can add or update soulbound traits (overriding owner's restriction)
        personaTraits[_targetPersonaId][_key] = _value;
        isSoulboundTrait[_targetPersonaId][_key] = true; // Oracle-attested traits are soulbound by default

        // Add key to the array if it's new
        bool keyExists = false;
        for(uint i=0; i<personaTraitKeys[_targetPersonaId].length; i++) {
            if (keccak256(abi.encodePacked(personaTraitKeys[_targetPersonaId][i])) == keccak256(abi.encodePacked(_key))) {
                keyExists = true;
                break;
            }
        }
        if (!keyExists) {
            personaTraitKeys[_targetPersonaId].push(_key);
        }

        int256 delta = _isPositive ? int256(_weight) : -int256(_weight);
        updateReputationScoreInternal(_targetPersonaId, delta);

        emit AttestationMade(_msgSender(), _targetPersonaId, _key, _value, _isPositive);
    }

    /**
     * @summary Allows the contract owner to set or revoke an address as an authorized oracle.
     * @dev Oracles have special privileges like verifying intents and attesting to attributes.
     * @param _oracle The address to authorize/revoke.
     * @param _isOracle True to authorize, false to revoke.
     */
    function setOracleAddress(address _oracle, bool _isOracle) public onlyOwner nonReentrant {
        authorizedOracles[_oracle] = _isOracle;
        emit OracleSet(_oracle, _isOracle);
    }

    // --- VI. Governance & Configuration ---

    /**
     * @summary Sets the period after which reputation starts to decay due to inactivity.
     * @dev Only callable by the contract owner. Set to 0 to disable decay.
     * @param _period The new decay period in seconds.
     */
    function setReputationDecayPeriod(uint256 _period) public onlyOwner {
        reputationDecayPeriod = _period;
    }

    /**
     * @summary Sets the base reputation boost amount for successful intent fulfillment.
     * @dev This amount is added to any additional boost specified during intent completion.
     * @param _boost The new base reputation boost.
     */
    function setBaseReputationBoost(uint256 _boost) public onlyOwner {
        baseReputationBoost = _boost;
    }

    /**
     * @summary Allows the owner to withdraw accidentally sent ERC20 tokens or native tokens (ETH) from the contract.
     * @param _tokenAddress The address of the ERC20 token to withdraw, or address(0) for native ETH.
     */
    function withdrawStuckFunds(address _tokenAddress) public onlyOwner nonReentrant {
        if (_tokenAddress == address(0)) {
            // Withdraw native ETH
            (bool success, ) = payable(msg.sender).call{value: address(this).balance}("");
            require(success, "PersonaNexus: Failed to withdraw ETH");
        } else {
            // Withdraw ERC20 tokens
            IERC20 token = IERC20(_tokenAddress);
            uint256 balance = token.balanceOf(address(this));
            require(balance > 0, "PersonaNexus: No tokens of this type to withdraw");
            token.transfer(msg.sender, balance);
        }
    }
}
```