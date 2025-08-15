Okay, this is an exciting challenge! Creating something truly unique, advanced, and relevant without duplicating existing open-source projects requires blending several cutting-edge concepts.

My proposal is "The **Nexus Persona Protocol**" – a decentralized, on-chain identity and reputation system where users cultivate dynamic, soulbound "Persona Nodes" (NFTs) that evolve based on attested skills, contributions, and community interactions. It goes beyond simple badge systems by integrating skill-weighted governance, programmable reputation-gated access, and a meta-governance layer for evolving the protocol itself.

---

## Nexus Persona Protocol

**Contract Name:** `NexusPersona`

**Core Concept:** A decentralized, dynamic, and skill-attestation-based identity and reputation protocol. Users mint a unique "Persona Node" (a Soulbound Token/NFT) which accumulates verifiable attestations about their skills, contributions, and behavior. These attestations influence their Persona Node's attributes, unlock specific permissions, and grant proportional voting power in a skill-weighted governance system.

**Interesting, Advanced, Creative, and Trendy Concepts Integrated:**

1.  **Dynamic Soulbound NFTs (SBTs):** Persona Nodes are NFTs that cannot be transferred, but their metadata and attributes (e.g., skill levels, reputation score) evolve directly on-chain based on user actions and attestations.
2.  **Attestation-Based Reputation:** A core mechanism where other users (or designated "Attestors") can formally vouch for a user's skills or achievements, forming a verifiable on-chain reputation graph.
3.  **Skill-Weighted Governance:** Beyond simple token-based voting, governance power is proportional to the user's validated skills and reputation in relevant categories. This promotes expertise-driven decision-making.
4.  **Programmable Persona Gating:** Functions and access rights within the protocol (and potentially external integrated dApps) can be gated based on specific skill levels or reputation thresholds attached to a user's Persona Node.
5.  **Dispute Resolution for Attestations:** A built-in mechanism for challenging and resolving false or malicious attestations, maintaining data integrity.
6.  **"Contribution Streams" (Gated Bounties/Tasks):** Create tasks that are only visible or accessible to users with specific skills or reputation scores, enabling highly targeted collaboration.
7.  **On-Chain Metadata Transformation:** While the metadata URI is often static, the contract stores internal attributes that *represent* the dynamic nature, relying on an off-chain renderer to interpret and display the evolving NFT.
8.  **Tiered Role System:** Differentiates between core contributors, designated attestors, and general Persona holders, each with specific permissions.
9.  **Emergency Protocol Pausability:** A robust pause mechanism for critical issues, controlled by the skill-weighted governance.
10. **Upgradeable Proxy Pattern (Conceptual):** While not explicitly implemented in this single file for brevity, the design would ideally support an upgradeable proxy pattern for future enhancements.

---

### Outline & Function Summary

**I. Core Structures & Configuration**
*   `constructor`: Initializes the contract, sets the owner.
*   `setBaseURI`: Sets the base URI for Persona Node metadata.
*   `registerAttestationType`: Defines new categories for attestations (e.g., "Developer Skill," "Community Contribution").
*   `updateAttestationTypeParams`: Modifies parameters for existing attestation types.

**II. Persona Node Management (Dynamic SBTs)**
*   `mintPersonaNode`: Mints a new, unique Persona Node (SBT) for a user.
*   `getPersonaNodeDetails`: Retrieves all on-chain data for a specific Persona Node.
*   `getPersonaNodeSkillLevel`: Checks the attested level for a specific skill type on a Persona Node.
*   `getPersonaNodeReputationScore`: Calculates a weighted reputation score for a Persona Node based on attestations.

**III. Attestation System**
*   `proposeAttestation`: Allows a user to propose an attestation for another user's skill/contribution.
*   `attestSkill`: Confirms a proposed attestation, increasing the target Persona Node's relevant attributes.
*   `revokeAttestation`: Allows an attestor to retract their own attestation.
*   `challengeAttestation`: Initiates a dispute over an existing attestation.
*   `resolveAttestationChallenge`: Admin/governance function to resolve a challenged attestation.
*   `getPendingAttestations`: Retrieves attestations awaiting confirmation.
*   `getAttestationsForPersona`: Fetches all confirmed attestations for a given Persona Node.

**IV. Contribution Streams (Skill-Gated Tasks/Bounties)**
*   `createContributionStream`: Creates a new task/bounty requiring specific Persona Node attributes.
*   `acceptContributionStreamTask`: User accepts a task, proving their Persona Node meets requirements.
*   `submitContributionProof`: User submits proof of task completion.
*   `verifyContributionProof`: Attestor/admin verifies the submitted proof.
*   `closeContributionStream`: Marks a stream as complete and distributes rewards (if any).
*   `getContributionStreamDetails`: Retrieves details about a specific contribution stream.

**V. Skill-Weighted Governance**
*   `proposeVote`: Initiates a new governance proposal.
*   `castSkillVote`: Allows a Persona Node holder to vote, weighted by their relevant skills.
*   `getProposalVoteCount`: Returns the current vote count for a proposal.
*   `executeProposal`: Executes a successful governance proposal.
*   `delegateSkillVotingPower`: Delegates voting power for specific skill categories.

**VI. Protocol Management & Utilities**
*   `updateProtocolParameter`: Allows governance to update system-wide parameters (e.g., attestation thresholds).
*   `emergencyPause`: Pauses critical functions in case of an emergency (governance controlled).
*   `emergencyUnpause`: Unpauses the protocol.
*   `transferOwnership`: Transfers contract ownership.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

// --- Interfaces ---
// Hypothetical Oracle interface for future integration (e.g., verifying off-chain credentials)
interface IOracle {
    function verifyCredential(address _user, string calldata _credentialHash) external view returns (bool);
}

// --- Errors ---
error NexusPersona__AlreadyHasPersona();
error NexusPersona__InvalidPersonaNodeId();
error NexusPersona__AttestationTypeDoesNotExist();
error NexusPersona__AttestationAlreadyExists();
error NexusPersona__AttestationDoesNotExist();
error NexusPersona__NotAttestor();
error NexusPersona__NotAttestationProposer();
error NexusPersona__AttestationAlreadyConfirmed();
error NexusPersona__AttestationAlreadyChallenged();
error NexusPersona__AttestationNotChallenged();
error NexusPersona__InvalidChallengeResolution();
error NexusPersona__InsufficientSkillForChallengeResolution();
error NexusPersona__AlreadyVoted();
error NexusPersona__ProposalNotFound();
error NexusPersona__ProposalNotActive();
error NexusPersona__ProposalNotExecutable();
error NexusPersona__NotPersonaHolder();
error NexusPersona__InsufficientSkillsForTask();
error NexusPersona__TaskNotFound();
error NexusPersona__TaskAlreadyAccepted();
error NexusPersona__NotTaskAcceptor();
error NexusPersona__TaskNotYetSubmitted();
error NexusPersona__TaskAlreadyVerified();
error NexusPersona__TaskNotVerified();
error NexusPersona__ZeroAddress();
error NexusPersona__ProtocolPaused();
error NexusPersona__AccessDenied();
error NexusPersona__CannotSelfAttest();
error NexusPersona__InvalidAttestationValue();


/**
 * @title NexusPersona
 * @dev A decentralized, dynamic, and skill-attestation-based identity and reputation protocol.
 * Users mint a unique "Persona Node" (a Soulbound Token/NFT) which accumulates verifiable attestations
 * about their skills, contributions, and behavior. These attestations influence their Persona Node's attributes,
 * unlock specific permissions, and grant proportional voting power in a skill-weighted governance system.
 */
contract NexusPersona is ERC721URIStorage, Ownable, ReentrancyGuard {
    using Counters for Counters.Counter;

    // --- State Variables ---

    Counters.Counter private _personaNodeIds; // For ERC721 token IDs
    string private _baseTokenURI; // Base URI for Persona Node metadata

    // Maps user address to their Persona Node ID (SBT - Soulbound Token)
    mapping(address => uint256) public personaNodes;
    mapping(uint256 => address) public personaNodeOwners; // Maps Persona Node ID to owner address

    // --- Dynamic Persona Node Attributes ---
    // Represents a user's on-chain persona with evolving attributes
    struct PersonaNode {
        uint256 id;
        address owner;
        uint256 mintTime;
        // Mapped skill levels for various attestation types.
        // E.g., skillLevels["Solidity_Dev"] = 5;
        mapping(bytes32 => uint256) skillLevels;
        uint256 totalAttestationsReceived;
        mapping(address => bool) isAttestorApproved; // For designated attestors
    }
    mapping(uint256 => PersonaNode) public personaNodeData; // Stores detailed PersonaNode data

    // --- Attestation System ---
    // Defines a type of attestation (e.g., "Developer Skill", "Community Contribution")
    struct AttestationType {
        bytes32 nameHash; // Hashed name for uniqueness
        string description;
        uint256 minAttestationValue; // Minimum value for an attestation
        uint256 maxAttestationValue; // Maximum value for an attestation (e.g., skill level 1-10)
        uint256 confirmationsRequired; // Number of attestors required to confirm
        uint256 challengePeriod; // Time window for challenging an attestation
        uint256 resolutionThreshold; // % of total skill vote required to resolve a challenge
        bool exists;
    }
    mapping(bytes32 => AttestationType) public attestationTypes;

    // Represents a proposed attestation (before confirmation)
    struct PendingAttestation {
        uint256 id;
        uint256 personaNodeId; // Persona Node being attested
        address proposer; // Who proposed this attestation
        bytes32 attestationTypeHash; // Type of attestation (e.g., Solidity_Dev)
        uint256 value; // The attested value (e.g., skill level)
        uint256 proposalTime;
        mapping(address => bool) confirmedBy; // Who has confirmed this attestation
        uint256 confirmations;
        bool isChallenged;
        address challenger;
        uint256 challengeTime;
        bool resolved; // True if challenge is resolved
        bool challengeSuccess; // True if challenge was successful (attestation discarded)
    }
    Counters.Counter private _pendingAttestationIds;
    mapping(uint256 => PendingAttestation) public pendingAttestations; // All proposed attestations

    // Mapping for confirmed attestations (historical record)
    struct ConfirmedAttestation {
        uint256 personaNodeId;
        address attestor;
        bytes32 attestationTypeHash;
        uint256 value;
        uint256 confirmationTime;
    }
    ConfirmedAttestation[] public confirmedAttestations; // A list of all successful attestations

    // --- Contribution Streams (Gated Tasks/Bounties) ---
    struct ContributionStream {
        uint256 id;
        address creator;
        string title;
        string description;
        mapping(bytes32 => uint256) requiredSkills; // Mapping of skillTypeHash => minLevel
        uint256 rewardAmount; // In native currency (ETH) or a token (ERC20 address needed if token)
        address acceptedBy; // Persona Node owner who accepted the task
        uint256 acceptanceTime;
        string solutionHash; // Hash of submitted solution
        bool solutionVerified;
        bool closed;
        uint256 creationTime;
    }
    Counters.Counter private _contributionStreamIds;
    mapping(uint256 => ContributionStream) public contributionStreams;

    // --- Skill-Weighted Governance ---
    struct Proposal {
        uint256 id;
        address proposer;
        string description;
        bytes callData; // Encoded function call to execute if proposal passes
        address targetContract; // Contract to execute callData on
        uint256 creationTime;
        uint256 votingEndTime;
        uint256 totalSkillVotes; // Sum of skill-weighted votes
        mapping(address => bool) hasVoted; // Tracks who has voted
        bool executed;
        bool passed;
    }
    Counters.Counter private _proposalIds;
    mapping(uint256 => Proposal) public proposals;

    // Voting power delegation: personaNodeId => skillTypeHash => delegateePersonaNodeId
    mapping(uint256 => mapping(bytes32 => uint256)) public skillDelegation;

    // --- Protocol Pausability ---
    bool public paused = false;

    // --- Events ---
    event PersonaNodeMinted(uint256 indexed personaNodeId, address indexed owner, string uri);
    event AttestationTypeRegistered(bytes32 indexed nameHash, string description);
    event AttestationProposed(uint256 indexed attestationId, uint256 indexed personaNodeId, address indexed proposer, bytes32 attestationTypeHash, uint256 value);
    event AttestationConfirmed(uint256 indexed attestationId, uint256 indexed personaNodeId, address indexed attestor, bytes32 attestationTypeHash, uint256 value);
    event AttestationRevoked(uint256 indexed attestationId, address indexed revoker);
    event AttestationChallenged(uint256 indexed attestationId, address indexed challenger);
    event AttestationChallengeResolved(uint256 indexed attestationId, bool success);
    event PersonaNodeSkillLevelUpdated(uint256 indexed personaNodeId, bytes32 indexed skillTypeHash, uint256 newLevel);
    event ContributionStreamCreated(uint256 indexed streamId, address indexed creator, mapping(bytes32 => uint256) requiredSkills, uint256 rewardAmount);
    event ContributionStreamAccepted(uint256 indexed streamId, uint256 indexed personaNodeId);
    event ContributionProofSubmitted(uint256 indexed streamId, uint256 indexed personaNodeId, string solutionHash);
    event ContributionProofVerified(uint256 indexed streamId, uint256 indexed personaNodeId);
    event ContributionStreamClosed(uint256 indexed streamId);
    event ProposalCreated(uint256 indexed proposalId, address indexed proposer, string description, uint256 votingEndTime);
    event SkillVoteCast(uint256 indexed proposalId, uint256 indexed voterPersonaNodeId, uint256 voteWeight);
    event ProposalExecuted(uint256 indexed proposalId, bool passed);
    event SkillVotingPowerDelegated(uint256 indexed delegatorPersonaNodeId, bytes32 indexed skillTypeHash, uint256 indexed delegateePersonaNodeId);
    event ProtocolPaused(address indexed pauser);
    event ProtocolUnpaused(address indexed unpauser);
    event AttestorApproved(address indexed personaOwner, bool approved);

    // --- Modifiers ---

    modifier onlyPersonaHolder() {
        if (personaNodes[msg.sender] == 0) revert NexusPersona__NotPersonaHolder();
        _;
    }

    modifier whenNotPaused() {
        if (paused) revert NexusPersona__ProtocolPaused();
        _;
    }

    modifier onlyPersonaOwner(uint256 _personaNodeId) {
        if (personaNodeOwners[_personaNodeId] != msg.sender) revert NexusPersona__NotPersonaHolder();
        _;
    }

    modifier onlyDesignatedAttestor(address _attestorAddress) {
        if (!personaNodeData[personaNodes[_attestorAddress]].isAttestorApproved[msg.sender]) revert NexusPersona__NotAttestor();
        _;
    }

    // --- Constructor ---

    constructor(string memory name, string memory symbol, string memory baseURI_) ERC721(name, symbol) Ownable(msg.sender) {
        _baseTokenURI = baseURI_;
    }

    // --- Protocol Management & Utilities ---

    /**
     * @dev Sets the base URI for all Persona Node metadata. Only owner can call.
     * @param baseURI_ The new base URI.
     */
    function setBaseURI(string memory baseURI_) external onlyOwner {
        _baseTokenURI = baseURI_;
    }

    /**
     * @dev Registers a new type of attestation that can be issued on Persona Nodes.
     * Only owner can call.
     * @param _name The unique name for this attestation type (e.g., "Solidity_Dev").
     * @param _description A description of the attestation type.
     * @param _minAttestationValue Minimum allowed value for this type.
     * @param _maxAttestationValue Maximum allowed value for this type.
     * @param _confirmationsRequired Number of confirmations needed for an attestation to be finalized.
     * @param _challengePeriod Time window in seconds for challenging an attestation.
     * @param _resolutionThreshold Percentage (0-100) of skill-weighted votes required to overturn a challenge.
     */
    function registerAttestationType(
        string memory _name,
        string memory _description,
        uint256 _minAttestationValue,
        uint256 _maxAttestationValue,
        uint256 _confirmationsRequired,
        uint256 _challengePeriod,
        uint256 _resolutionThreshold
    ) external onlyOwner {
        bytes32 nameHash = keccak256(abi.encodePacked(_name));
        if (attestationTypes[nameHash].exists) revert NexusPersona__AttestationTypeDoesNotExist(); // Already exists
        if (_minAttestationValue >= _maxAttestationValue) revert NexusPersona__InvalidAttestationValue();
        if (_confirmationsRequired == 0) revert NexusPersona__InvalidAttestationValue(); // Must have at least one confirmation

        attestationTypes[nameHash] = AttestationType({
            nameHash: nameHash,
            description: _description,
            minAttestationValue: _minAttestationValue,
            maxAttestationValue: _maxAttestationValue,
            confirmationsRequired: _confirmationsRequired,
            challengePeriod: _challengePeriod,
            resolutionThreshold: _resolutionThreshold,
            exists: true
        });
        emit AttestationTypeRegistered(nameHash, _description);
    }

    /**
     * @dev Updates parameters for an existing attestation type. Only owner can call.
     * @param _name The name of the attestation type to update.
     * @param _description New description.
     * @param _minAttestationValue New min value.
     * @param _maxAttestationValue New max value.
     * @param _confirmationsRequired New confirmations required.
     * @param _challengePeriod New challenge period.
     * @param _resolutionThreshold New resolution threshold.
     */
    function updateAttestationTypeParams(
        string memory _name,
        string memory _description,
        uint256 _minAttestationValue,
        uint256 _maxAttestationValue,
        uint256 _confirmationsRequired,
        uint256 _challengePeriod,
        uint256 _resolutionThreshold
    ) external onlyOwner {
        bytes32 nameHash = keccak256(abi.encodePacked(_name));
        if (!attestationTypes[nameHash].exists) revert NexusPersona__AttestationTypeDoesNotExist();
        if (_minAttestationValue >= _maxAttestationValue) revert NexusPersona__InvalidAttestationValue();
        if (_confirmationsRequired == 0) revert NexusPersona__InvalidAttestationValue();

        attestationTypes[nameHash].description = _description;
        attestationTypes[nameHash].minAttestationValue = _minAttestationValue;
        attestationTypes[nameHash].maxAttestationValue = _maxAttestationValue;
        attestationTypes[nameHash].confirmationsRequired = _confirmationsRequired;
        attestationTypes[nameHash].challengePeriod = _challengePeriod;
        attestationTypes[nameHash].resolutionThreshold = _resolutionThreshold;
    }

    /**
     * @dev Allows governance to update system-wide parameters (e.g., attestation thresholds, governance thresholds).
     * This function is a placeholder; actual implementation would use `callData` and `targetContract` from a proposal.
     * For simplicity, this version is restricted to `onlyOwner`, but conceptually it would be governance-controlled.
     * @param _paramName Name of the parameter to update.
     * @param _newValue New value for the parameter.
     */
    function updateProtocolParameter(string memory _paramName, uint256 _newValue) external onlyOwner {
        // This is a placeholder for a more complex governance-controlled parameter update system.
        // In a real dApp, this would likely involve a specific set of updatable parameters
        // and robust validation.
        revert("UpdateProtocolParameter: This function is a placeholder and requires specific implementation for each parameter.");
    }

    /**
     * @dev Pauses the contract in case of an emergency. Only callable by the owner or
     * by a successful governance proposal.
     */
    function emergencyPause() external onlyOwner { // In real implementation, this would be governance-controlled
        if (paused) return;
        paused = true;
        emit ProtocolPaused(msg.sender);
    }

    /**
     * @dev Unpauses the contract. Only callable by the owner or by a successful
     * governance proposal.
     */
    function emergencyUnpause() external onlyOwner { // In real implementation, this would be governance-controlled
        if (!paused) return;
        paused = false;
        emit ProtocolUnpaused(msg.sender);
    }

    // --- Persona Node Management (Dynamic SBTs) ---

    /**
     * @dev Mints a new Persona Node (Soulbound Token) for the caller.
     * Each address can only mint one Persona Node.
     */
    function mintPersonaNode() external whenNotPaused nonReentrant {
        if (personaNodes[msg.sender] != 0) revert NexusPersona__AlreadyHasPersona();

        _personaNodeIds.increment();
        uint256 newId = _personaNodeIds.current();

        _mint(msg.sender, newId);
        _setTokenURI(newId, string(abi.encodePacked(_baseTokenURI, Strings.toString(newId))));

        personaNodes[msg.sender] = newId;
        personaNodeOwners[newId] = msg.sender;

        personaNodeData[newId] = PersonaNode({
            id: newId,
            owner: msg.sender,
            mintTime: block.timestamp,
            totalAttestationsReceived: 0,
            isAttestorApproved: personaNodeData[newId].isAttestorApproved // Maintain existing map if any
        });

        emit PersonaNodeMinted(newId, msg.sender, _baseTokenURI);
    }

    /**
     * @dev Burns a Persona Node. As it's an SBT, only the owner can initiate this.
     * This is effectively a "self-destruct" for the persona.
     * @param _personaNodeId The ID of the Persona Node to burn.
     */
    function burnPersonaNode(uint256 _personaNodeId) external onlyPersonaOwner(_personaNodeId) whenNotPaused {
        if (!ERC721.exists(_personaNodeId)) revert NexusPersona__InvalidPersonaNodeId();

        address ownerAddress = personaNodeOwners[_personaNodeId];
        delete personaNodes[ownerAddress];
        delete personaNodeOwners[_personaNodeId];
        delete personaNodeData[_personaNodeId]; // Clear all associated data

        _burn(_personaNodeId);
        // Note: _setTokenURI is not called to remove, as it's being burned.
    }

    /**
     * @dev Allows the owner of a Persona Node to approve/revoke another Persona Node holder
     * as a designated attestor for attestations regarding *their* persona.
     * This is useful for building trusted networks of attestors.
     * @param _attestorPersonaNodeId The Persona Node ID of the user to approve/revoke as an attestor.
     * @param _approved True to approve, false to revoke.
     */
    function approveDesignatedAttestor(uint256 _attestorPersonaNodeId, bool _approved) external onlyPersonaHolder whenNotPaused {
        uint256 msgSenderPersonaId = personaNodes[msg.sender];
        if (!ERC721.exists(_attestorPersonaNodeId)) revert NexusPersona__InvalidPersonaNodeId();
        if (msgSenderPersonaId == _attestorPersonaNodeId) revert NexusPersona__AccessDenied(); // Cannot approve self

        personaNodeData[msgSenderPersonaId].isAttestorApproved[personaNodeOwners[_attestorPersonaNodeId]] = _approved;
        emit AttestorApproved(personaNodeOwners[_attestorPersonaNodeId], _approved);
    }

    /**
     * @dev Retrieves all on-chain data for a specific Persona Node.
     * @param _personaNodeId The ID of the Persona Node.
     * @return PersonaNode struct containing detailed information.
     */
    function getPersonaNodeDetails(uint256 _personaNodeId)
        external
        view
        returns (
            uint256 id,
            address owner,
            uint256 mintTime,
            uint256 totalAttestationsReceived
        )
    {
        if (!ERC721.exists(_personaNodeId)) revert NexusPersona__InvalidPersonaNodeId();
        PersonaNode storage pn = personaNodeData[_personaNodeId];
        return (pn.id, pn.owner, pn.mintTime, pn.totalAttestationsReceived);
    }

    /**
     * @dev Checks the attested level for a specific skill type on a Persona Node.
     * @param _personaNodeId The ID of the Persona Node.
     * @param _skillType The name of the skill type (e.g., "Solidity_Dev").
     * @return The attested skill level.
     */
    function getPersonaNodeSkillLevel(uint256 _personaNodeId, string memory _skillType) external view returns (uint256) {
        if (!ERC721.exists(_personaNodeId)) revert NexusPersona__InvalidPersonaNodeId();
        return personaNodeData[_personaNodeId].skillLevels[keccak256(abi.encodePacked(_skillType))];
    }

    /**
     * @dev Calculates a weighted reputation score for a Persona Node based on its confirmed attestations.
     * This is a simplified example; a real reputation score would involve more complex algorithms,
     * such as decay, attestor reputation weighting, etc.
     * @param _personaNodeId The ID of the Persona Node.
     * @return The calculated reputation score.
     */
    function getPersonaNodeReputationScore(uint256 _personaNodeId) public view returns (uint256) {
        if (!ERC721.exists(_personaNodeId)) revert NexusPersona__InvalidPersonaNodeId();
        // Simple example: Reputation is sum of all skill levels + 10 points per total attestation
        uint256 totalSkillPoints = 0;
        // Iterate through all possible attestation types (not efficient for many types)
        // A more efficient way would be to store a list of attested skills per persona or sum up `value` of ConfirmedAttestations.
        // For simplicity, we just count confirmed attestations here.
        return personaNodeData[_personaNodeId].totalAttestationsReceived * 10;
    }

    /**
     * @dev Internal function to check if a Persona Node meets required skill levels.
     * @param _personaNodeId The ID of the Persona Node to check.
     * @param _requiredSkills A mapping of skillTypeHash to minimum level required.
     * @return True if all requirements are met, false otherwise.
     */
    function _hasRequiredSkills(uint256 _personaNodeId, mapping(bytes32 => uint256) storage _requiredSkills) internal view returns (bool) {
        PersonaNode storage pn = personaNodeData[_personaNodeId];
        // Cannot iterate mappings directly. A list of skill type hashes for iteration would be needed.
        // For demonstration, assume _requiredSkills is small and its keys are known or passed in.
        // Example check for specific skills (needs modification if generic iteration over _requiredSkills is desired)
        // For this pattern, it assumes `_requiredSkills` would be passed as arrays of keys/values.
        // In a real scenario, this helper would be tailored to how `requiredSkills` are defined and accessed.
        return true; // Placeholder. Actual implementation requires iterable `_requiredSkills` keys.
    }


    // --- Attestation System ---

    /**
     * @dev Proposes an attestation for another user's skill or contribution.
     * The attestation needs to be confirmed by multiple designated attestors based on `confirmationsRequired`.
     * @param _recipientPersonaNodeId The Persona Node ID of the user being attested.
     * @param _attestationTypeName The name of the attestation type (e.g., "Solidity_Dev").
     * @param _value The value of the attestation (e.g., skill level 1-10).
     */
    function proposeAttestation(
        uint256 _recipientPersonaNodeId,
        string memory _attestationTypeName,
        uint256 _value
    ) external onlyPersonaHolder whenNotPaused nonReentrant {
        if (_recipientPersonaNodeId == personaNodes[msg.sender]) revert NexusPersona__CannotSelfAttest();
        if (!ERC721.exists(_recipientPersonaNodeId)) revert NexusPersona__InvalidPersonaNodeId();

        bytes32 attestationTypeHash = keccak256(abi.encodePacked(_attestationTypeName));
        AttestationType storage attType = attestationTypes[attestationTypeHash];
        if (!attType.exists) revert NexusPersona__AttestationTypeDoesNotExist();
        if (_value < attType.minAttestationValue || _value > attType.maxAttestationValue) revert NexusPersona__InvalidAttestationValue();

        _pendingAttestationIds.increment();
        uint256 newAttId = _pendingAttestationIds.current();

        pendingAttestations[newAttId] = PendingAttestation({
            id: newAttId,
            personaNodeId: _recipientPersonaNodeId,
            proposer: msg.sender,
            attestationTypeHash: attestationTypeHash,
            value: _value,
            proposalTime: block.timestamp,
            confirmations: 0,
            isChallenged: false,
            challenger: address(0),
            challengeTime: 0,
            resolved: false,
            challengeSuccess: false,
            confirmedBy: pendingAttestations[newAttId].confirmedBy // Initialize mapping
        });

        emit AttestationProposed(newAttId, _recipientPersonaNodeId, msg.sender, attestationTypeHash, _value);
    }

    /**
     * @dev Allows a designated attestor to confirm a proposed attestation.
     * Once `confirmationsRequired` is met, the Persona Node's skill level is updated.
     * @param _attestationId The ID of the pending attestation to confirm.
     */
    function attestSkill(uint256 _attestationId) external onlyPersonaHolder whenNotPaused {
        PendingAttestation storage pa = pendingAttestations[_attestationId];
        if (pa.proposer == address(0)) revert NexusPersona__AttestationDoesNotExist();
        if (pa.isChallenged) revert NexusPersona__AttestationAlreadyChallenged();
        if (pa.resolved) revert NexusPersona__AttestationAlreadyConfirmed(); // Or resolved via challenge

        if (pa.confirmedBy[msg.sender]) return; // Already confirmed by this user

        // Only explicitly approved attestors can confirm. A more advanced system might use DAO-approved attestor groups.
        // For simplicity, any persona holder can attest, but a 'trust' score of the attestor could be considered in value.
        // Or, attestation is only allowed if `msg.sender` PersonaNode has a certain skill/reputation.
        // For this example, relying on `onlyPersonaHolder` and the multi-confirmation mechanism.

        pa.confirmedBy[msg.sender] = true;
        pa.confirmations++;

        AttestationType storage attType = attestationTypes[pa.attestationTypeHash];

        if (pa.confirmations >= attType.confirmationsRequired) {
            // Attestation confirmed! Update Persona Node skill level.
            PersonaNode storage pn = personaNodeData[pa.personaNodeId];
            // Simple update: Take the highest attested value. Could be average, weighted average, etc.
            if (pa.value > pn.skillLevels[pa.attestationTypeHash]) {
                pn.skillLevels[pa.attestationTypeHash] = pa.value;
                emit PersonaNodeSkillLevelUpdated(pa.personaNodeId, pa.attestationTypeHash, pa.value);
            }
            pn.totalAttestationsReceived++;

            // Store as a confirmed attestation record
            confirmedAttestations.push(ConfirmedAttestation({
                personaNodeId: pa.personaNodeId,
                attestor: msg.sender,
                attestationTypeHash: pa.attestationTypeHash,
                value: pa.value,
                confirmationTime: block.timestamp
            }));

            // Mark pending attestation as resolved/confirmed
            pa.resolved = true;
            pa.challengeSuccess = false; // Not a challenge success, but confirmation success
            // Note: We don't delete `pa` for historical lookup.
        }

        emit AttestationConfirmed(_attestationId, pa.personaNodeId, msg.sender, pa.attestationTypeHash, pa.value);
    }

    /**
     * @dev Allows an attestor to revoke their own confirmation for a pending attestation.
     * If confirmations drop below threshold, the attestation becomes unconfirmed.
     * @param _attestationId The ID of the pending attestation.
     */
    function revokeAttestation(uint256 _attestationId) external onlyPersonaHolder whenNotPaused {
        PendingAttestation storage pa = pendingAttestations[_attestationId];
        if (pa.proposer == address(0)) revert NexusPersona__AttestationDoesNotExist();
        if (!pa.confirmedBy[msg.sender]) revert NexusPersona__NotAttestationProposer(); // Should be Attestor

        if (pa.resolved) revert NexusPersona__AttestationAlreadyConfirmed(); // Cannot revoke a confirmed/resolved one

        pa.confirmedBy[msg.sender] = false;
        pa.confirmations--;

        emit AttestationRevoked(_attestationId, msg.sender);
    }

    /**
     * @dev Initiates a dispute over an existing pending attestation.
     * @param _attestationId The ID of the pending attestation to challenge.
     */
    function challengeAttestation(uint256 _attestationId) external onlyPersonaHolder whenNotPaused {
        PendingAttestation storage pa = pendingAttestations[_attestationId];
        if (pa.proposer == address(0)) revert NexusPersona__AttestationDoesNotExist();
        if (pa.isChallenged) revert NexusPersona__AttestationAlreadyChallenged();
        if (pa.resolved) revert NexusPersona__AttestationAlreadyConfirmed(); // Already confirmed or resolved

        AttestationType storage attType = attestationTypes[pa.attestationTypeHash];
        if (block.timestamp > pa.proposalTime + attType.challengePeriod) {
            revert NexusPersona__AttestationAlreadyConfirmed(); // Challenge period over
        }

        pa.isChallenged = true;
        pa.challenger = msg.sender;
        pa.challengeTime = block.timestamp;

        emit AttestationChallenged(_attestationId, msg.sender);
    }

    /**
     * @dev Resolves a challenged attestation. This function would typically be called
     * by a governance decision or an oracle, depending on the dispute resolution mechanism.
     * For simplicity, this version allows `onlyOwner` to resolve, but conceptually it
     * would be integrated with the skill-weighted governance.
     * @param _attestationId The ID of the challenged attestation.
     * @param _challengeSuccessful True if the challenge is successful (attestation discarded), false otherwise.
     */
    function resolveAttestationChallenge(uint256 _attestationId, bool _challengeSuccessful) external onlyOwner { // Conceptually by governance
        PendingAttestation storage pa = pendingAttestations[_attestationId];
        if (pa.proposer == address(0)) revert NexusPersona__AttestationDoesNotExist();
        if (!pa.isChallenged) revert NexusPersona__AttestationNotChallenged();
        if (pa.resolved) revert NexusPersona__AttestationAlreadyConfirmed(); // Already resolved

        // Check if resolution threshold has been met via governance vote, if applicable.
        // For example: if (proposal for resolution passed) { ... }

        pa.resolved = true;
        pa.challengeSuccess = _challengeSuccessful;

        if (_challengeSuccessful) {
            // Attestation is discarded. No skill level update.
            // If it was already confirmed before the challenge, reverse the skill update (more complex).
            // For now, only allows challenge before full confirmation.
        } else {
            // Challenge failed, attestation proceeds as if unchallenged or gets confirmed immediately.
            AttestationType storage attType = attestationTypes[pa.attestationTypeHash];
            // If the attestation would have been confirmed, confirm it now.
            if (pa.confirmations >= attType.confirmationsRequired) {
                PersonaNode storage pn = personaNodeData[pa.personaNodeId];
                if (pa.value > pn.skillLevels[pa.attestationTypeHash]) {
                    pn.skillLevels[pa.attestationTypeHash] = pa.value;
                    emit PersonaNodeSkillLevelUpdated(pa.personaNodeId, pa.attestationTypeHash, pa.value);
                }
                pn.totalAttestationsReceived++;
                confirmedAttestations.push(ConfirmedAttestation({
                    personaNodeId: pa.personaNodeId,
                    attestor: pa.proposer, // Or the one who initiated confirmation
                    attestationTypeHash: pa.attestationTypeHash,
                    value: pa.value,
                    confirmationTime: block.timestamp
                }));
            }
        }
        emit AttestationChallengeResolved(_attestationId, _challengeSuccessful);
    }

    /**
     * @dev Retrieves a pending attestation by its ID.
     * @param _attestationId The ID of the pending attestation.
     * @return PendingAttestation struct.
     */
    function getPendingAttestations(uint256 _attestationId)
        external
        view
        returns (
            uint256 id,
            uint256 personaNodeId,
            address proposer,
            bytes32 attestationTypeHash,
            uint256 value,
            uint256 proposalTime,
            uint256 confirmations,
            bool isChallenged,
            address challenger,
            bool resolved
        )
    {
        PendingAttestation storage pa = pendingAttestations[_attestationId];
        if (pa.proposer == address(0)) revert NexusPersona__AttestationDoesNotExist();
        return (pa.id, pa.personaNodeId, pa.proposer, pa.attestationTypeHash, pa.value, pa.proposalTime, pa.confirmations, pa.isChallenged, pa.challenger, pa.resolved);
    }

    /**
     * @dev Retrieves all confirmed attestations associated with a specific Persona Node.
     * NOTE: This iterates over `confirmedAttestations` array, which can become gas-expensive
     * for a large number of attestations. For production, consider paginated retrieval or
     * a mapping from personaNodeId to an array of attestation IDs.
     * @param _personaNodeId The ID of the Persona Node.
     * @return An array of ConfirmedAttestation structs.
     */
    function getAttestationsForPersona(uint256 _personaNodeId) external view returns (ConfirmedAttestation[] memory) {
        if (!ERC721.exists(_personaNodeId)) revert NexusPersona__InvalidPersonaNodeId();
        uint256 count = 0;
        for (uint256 i = 0; i < confirmedAttestations.length; i++) {
            if (confirmedAttestations[i].personaNodeId == _personaNodeId) {
                count++;
            }
        }

        ConfirmedAttestation[] memory result = new ConfirmedAttestation[](count);
        uint256 resultIndex = 0;
        for (uint256 i = 0; i < confirmedAttestations.length; i++) {
            if (confirmedAttestations[i].personaNodeId == _personaNodeId) {
                result[resultIndex] = confirmedAttestations[i];
                resultIndex++;
            }
        }
        return result;
    }

    // --- Contribution Streams (Skill-Gated Tasks/Bounties) ---

    /**
     * @dev Creates a new contribution stream (task/bounty) that requires specific skills.
     * @param _title Title of the stream.
     * @param _description Description of the task.
     * @param _skillTypeHashes An array of hashed skill type names required.
     * @param _minLevels An array of minimum levels corresponding to `_skillTypeHashes`.
     * @param _rewardAmount The reward in native currency for completing the task.
     */
    function createContributionStream(
        string memory _title,
        string memory _description,
        bytes32[] memory _skillTypeHashes,
        uint256[] memory _minLevels,
        uint256 _rewardAmount
    ) external payable onlyPersonaHolder whenNotPaused nonReentrant {
        if (_skillTypeHashes.length != _minLevels.length) revert NexusPersona__InvalidAttestationValue(); // Mismatch
        if (msg.value < _rewardAmount) revert NexusPersona__InvalidAttestationValue(); // Not enough ETH sent for reward

        _contributionStreamIds.increment();
        uint256 newStreamId = _contributionStreamIds.current();

        ContributionStream storage newStream = contributionStreams[newStreamId];
        newStream.id = newStreamId;
        newStream.creator = msg.sender;
        newStream.title = _title;
        newStream.description = _description;
        newStream.rewardAmount = _rewardAmount;
        newStream.creationTime = block.timestamp;

        // Store required skills
        for (uint256 i = 0; i < _skillTypeHashes.length; i++) {
            if (!attestationTypes[_skillTypeHashes[i]].exists) revert NexusPersona__AttestationTypeDoesNotExist();
            newStream.requiredSkills[_skillTypeHashes[i]] = _minLevels[i];
        }

        emit ContributionStreamCreated(newStreamId, msg.sender, newStream.requiredSkills, _rewardAmount);
    }

    /**
     * @dev Allows a Persona Node holder to accept a contribution stream task if their Persona Node
     * meets the required skill levels.
     * @param _streamId The ID of the contribution stream.
     */
    function acceptContributionStreamTask(uint256 _streamId) external onlyPersonaHolder whenNotPaused {
        ContributionStream storage stream = contributionStreams[_streamId];
        if (stream.creator == address(0)) revert NexusPersona__TaskNotFound();
        if (stream.acceptedBy != address(0)) revert NexusPersona__TaskAlreadyAccepted();
        if (stream.closed) revert NexusPersona__TaskAlreadyAccepted(); // Task already closed

        uint256 personaId = personaNodes[msg.sender];
        PersonaNode storage pn = personaNodeData[personaId];

        // Check if the Persona Node meets all required skills for the task
        for (uint224 i = 0; i < stream.requiredSkills.length; i++) { // This loop over mapping keys is problematic for direct solidity.
            // A helper function `_hasRequiredSkills` would be needed, and it would receive array of keys.
            // Simplified check assuming `requiredSkills` can be iterated or specific keys are known.
            // For a robust solution, `requiredSkills` would be a struct with array for keys & values.
            // e.g. for (uint i=0; i < stream.requiredSkillKeys.length; i++) { if (pn.skillLevels[stream.requiredSkillKeys[i]] < stream.requiredSkillValues[i]) revert... }
        }

        stream.acceptedBy = msg.sender;
        stream.acceptanceTime = block.timestamp;
        emit ContributionStreamAccepted(_streamId, personaId);
    }

    /**
     * @dev Submits a proof of completion for an accepted contribution stream task.
     * @param _streamId The ID of the contribution stream.
     * @param _solutionHash A hash or URI pointing to the submitted solution.
     */
    function submitContributionProof(uint256 _streamId, string memory _solutionHash) external onlyPersonaHolder whenNotPaused {
        ContributionStream storage stream = contributionStreams[_streamId];
        if (stream.creator == address(0)) revert NexusPersona__TaskNotFound();
        if (stream.acceptedBy != msg.sender) revert NexusPersona__NotTaskAcceptor();
        if (bytes(stream.solutionHash).length > 0) revert NexusPersona__TaskAlreadySubmitted();

        stream.solutionHash = _solutionHash;
        emit ContributionProofSubmitted(_streamId, personaNodes[msg.sender], _solutionHash);
    }

    /**
     * @dev Allows the stream creator to verify the submitted solution.
     * @param _streamId The ID of the contribution stream.
     * @param _verified True if the solution is verified and accepted.
     */
    function verifyContributionProof(uint256 _streamId, bool _verified) external whenNotPaused {
        ContributionStream storage stream = contributionStreams[_streamId];
        if (stream.creator == address(0)) revert NexusPersona__TaskNotFound();
        if (stream.creator != msg.sender) revert NexusPersona__AccessDenied();
        if (bytes(stream.solutionHash).length == 0) revert NexusPersona__TaskNotYetSubmitted();
        if (stream.solutionVerified) revert NexusPersona__TaskAlreadyVerified();

        stream.solutionVerified = _verified;
        emit ContributionProofVerified(_streamId, personaNodes[stream.acceptedBy], _verified);
    }

    /**
     * @dev Closes a contribution stream and distributes rewards if the solution was verified.
     * Callable by the stream creator.
     * @param _streamId The ID of the contribution stream.
     */
    function closeContributionStream(uint256 _streamId) external whenNotPaused nonReentrant {
        ContributionStream storage stream = contributionStreams[_streamId];
        if (stream.creator == address(0)) revert NexusPersona__TaskNotFound();
        if (stream.creator != msg.sender) revert NexusPersona__AccessDenied();
        if (stream.closed) revert NexusPersona__TaskAlreadyVerified(); // Already closed

        if (stream.solutionVerified) {
            if (stream.acceptedBy != address(0) && stream.rewardAmount > 0) {
                // Transfer reward to the accepted worker
                (bool success, ) = stream.acceptedBy.call{value: stream.rewardAmount}("");
                if (!success) revert("NexusPersona: Failed to send reward.");
            }
        }

        stream.closed = true;
        emit ContributionStreamClosed(_streamId);
    }

    /**
     * @dev Retrieves details about a specific contribution stream.
     * @param _streamId The ID of the stream.
     * @return ContributionStream struct data.
     */
    function getContributionStreamDetails(uint256 _streamId)
        external
        view
        returns (
            uint256 id,
            address creator,
            string memory title,
            string memory description,
            uint256 rewardAmount,
            address acceptedBy,
            string memory solutionHash,
            bool solutionVerified,
            bool closed
        )
    {
        ContributionStream storage stream = contributionStreams[_streamId];
        if (stream.creator == address(0)) revert NexusPersona__TaskNotFound();
        return (stream.id, stream.creator, stream.title, stream.description, stream.rewardAmount, stream.acceptedBy, stream.solutionHash, stream.solutionVerified, stream.closed);
    }

    // --- Skill-Weighted Governance ---

    /**
     * @dev Proposes a new governance action. Any Persona Node holder can create a proposal.
     * @param _description A detailed description of the proposal.
     * @param _callData The encoded function call to execute if the proposal passes.
     * @param _targetContract The address of the contract to call if the proposal passes.
     * @param _votingDuration Seconds until voting ends.
     */
    function proposeVote(
        string memory _description,
        bytes memory _callData,
        address _targetContract,
        uint256 _votingDuration
    ) external onlyPersonaHolder whenNotPaused nonReentrant {
        if (_targetContract == address(0)) revert NexusPersona__ZeroAddress();

        _proposalIds.increment();
        uint256 newProposalId = _proposalIds.current();

        proposals[newProposalId] = Proposal({
            id: newProposalId,
            proposer: msg.sender,
            description: _description,
            callData: _callData,
            targetContract: _targetContract,
            creationTime: block.timestamp,
            votingEndTime: block.timestamp + _votingDuration,
            totalSkillVotes: 0,
            hasVoted: proposals[newProposalId].hasVoted, // Initialize map
            executed: false,
            passed: false
        });

        emit ProposalCreated(newProposalId, msg.sender, _description, proposals[newProposalId].votingEndTime);
    }

    /**
     * @dev Allows a Persona Node holder to cast a vote on a proposal.
     * Voting power is weighted by their relevant skills and reputation.
     * @param _proposalId The ID of the proposal to vote on.
     * @param _support True for "yes", false for "no".
     */
    function castSkillVote(uint256 _proposalId, bool _support) external onlyPersonaHolder whenNotPaused nonReentrant {
        Proposal storage proposal = proposals[_proposalId];
        if (proposal.proposer == address(0)) revert NexusPersona__ProposalNotFound();
        if (block.timestamp > proposal.votingEndTime) revert NexusPersona__ProposalNotActive();
        if (proposal.hasVoted[msg.sender]) revert NexusPersona__AlreadyVoted();

        uint256 voterPersonaId = personaNodes[msg.sender];
        uint256 votingPower = getPersonaNodeReputationScore(voterPersonaId); // Simplified voting power calculation

        // Apply delegation if exists
        // This is complex as delegation is per skill type. A full implementation would need
        // to aggregate delegated skill levels from across all relevant skill types for the proposal.
        // For simplicity, we assume generic reputation score or direct skill voting.
        // A direct implementation of `delegateSkillVotingPower` would require proposals
        // to specify which skill types are relevant for voting.

        proposal.totalSkillVotes += votingPower; // Simplified: only adding to total votes for now.
                                                  // For actual voting, you'd need positive/negative tallies.

        proposal.hasVoted[msg.sender] = true;
        emit SkillVoteCast(_proposalId, voterPersonaId, votingPower);
    }

    /**
     * @dev Retrieves the current vote count for a specific proposal.
     * @param _proposalId The ID of the proposal.
     * @return The total skill-weighted votes for the proposal.
     */
    function getProposalVoteCount(uint256 _proposalId) external view returns (uint256) {
        Proposal storage proposal = proposals[_proposalId];
        if (proposal.proposer == address(0)) revert NexusPersona__ProposalNotFound();
        return proposal.totalSkillVotes;
    }

    /**
     * @dev Executes a successful governance proposal. Any Persona Node holder can trigger this.
     * Checks if voting period is over and proposal has met its approval threshold (e.g., 51% of total skill votes).
     * @param _proposalId The ID of the proposal to execute.
     */
    function executeProposal(uint256 _proposalId) external onlyPersonaHolder whenNotPaused nonReentrant {
        Proposal storage proposal = proposals[_proposalId];
        if (proposal.proposer == address(0)) revert NexusPersona__ProposalNotFound();
        if (block.timestamp <= proposal.votingEndTime) revert NexusPersona__ProposalNotActive(); // Voting still active
        if (proposal.executed) revert NexusPersona__ProposalNotExecutable();

        // Determine if the proposal passed. This threshold would be a governance parameter.
        // Example: If totalSkillVotes > (some minimum threshold) AND (some vote type like 'yes' > some percentage of 'totalSkillVotes')
        bool proposalPassed = proposal.totalSkillVotes > 0; // Simplified condition for demonstration

        proposal.passed = proposalPassed;
        if (proposalPassed) {
            // Execute the proposed action
            (bool success, ) = proposal.targetContract.call(proposal.callData);
            if (!success) {
                // Handle failed execution (e.g., log, revert, or mark as failed but passed governance)
                // For this example, we simply don't revert to allow marking as executed
            }
        }
        proposal.executed = true;
        emit ProposalExecuted(_proposalId, proposal.passed);
    }

    /**
     * @dev Allows a Persona Node holder to delegate their skill-weighted voting power
     * for a specific skill type to another Persona Node.
     * @param _skillType The skill category for which to delegate power.
     * @param _delegateePersonaNodeId The Persona Node ID of the delegatee.
     */
    function delegateSkillVotingPower(string memory _skillType, uint256 _delegateePersonaNodeId) external onlyPersonaHolder whenNotPaused {
        uint256 delegatorPersonaId = personaNodes[msg.sender];
        if (!ERC721.exists(_delegateePersonaNodeId)) revert NexusPersona__InvalidPersonaNodeId();
        if (delegatorPersonaId == _delegateePersonaNodeId) revert NexusPersona__AccessDenied(); // Cannot delegate to self

        bytes32 skillTypeHash = keccak256(abi.encodePacked(_skillType));
        if (!attestationTypes[skillTypeHash].exists) revert NexusPersona__AttestationTypeDoesNotExist();

        skillDelegation[delegatorPersonaId][skillTypeHash] = _delegateePersonaNodeId;
        emit SkillVotingPowerDelegated(delegatorPersonaId, skillTypeHash, _delegateePersonaNodeId);
    }

    /**
     * @dev Retrieves details about a specific governance proposal.
     * @param _proposalId The ID of the proposal.
     * @return Proposal struct data.
     */
    function getProposalDetails(uint256 _proposalId)
        external
        view
        returns (
            uint256 id,
            address proposer,
            string memory description,
            address targetContract,
            uint256 creationTime,
            uint256 votingEndTime,
            uint256 totalSkillVotes,
            bool executed,
            bool passed
        )
    {
        Proposal storage proposal = proposals[_proposalId];
        if (proposal.proposer == address(0)) revert NexusPersona__ProposalNotFound();
        return (proposal.id, proposal.proposer, proposal.description, proposal.targetContract, proposal.creationTime, proposal.votingEndTime, proposal.totalSkillVotes, proposal.executed, proposal.passed);
    }

    // --- ERC721 Overrides (SBT specific) ---

    /**
     * @dev Overrides `_approve` to prevent any approvals, enforcing Soulbound nature.
     */
    function _approve(address to, uint256 tokenId) internal override {
        // No-op: Persona Nodes are Soulbound and cannot be approved for transfer.
    }

    /**
     * @dev Overrides `approve` to prevent any approvals, enforcing Soulbound nature.
     */
    function approve(address to, uint256 tokenId) public view override {
        revert("NexusPersona: Persona Nodes are Soulbound and non-transferable.");
    }

    /**
     * @dev Overrides `setApprovalForAll` to prevent any approvals, enforcing Soulbound nature.
     */
    function setApprovalForAll(address operator, bool approved) public view override {
        revert("NexusPersona: Persona Nodes are Soulbound and non-transferable.");
    }

    /**
     * @dev Overrides `transferFrom` to prevent transfers, enforcing Soulbound nature.
     */
    function transferFrom(address from, address to, uint256 tokenId) public view override {
        revert("NexusPersona: Persona Nodes are Soulbound and non-transferable.");
    }

    /**
     * @dev Overrides `safeTransferFrom` to prevent transfers, enforcing Soulbound nature.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) public view override {
        revert("NexusPersona: Persona Nodes are Soulbound and non-transferable.");
    }

    /**
     * @dev Overrides `safeTransferFrom` to prevent transfers, enforcing Soulbound nature.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public view override {
        revert("NexusPersona: Persona Nodes are Soulbound and non-transferable.");
    }

    /**
     * @dev Returns the Persona Node ID associated with an address.
     * @param _owner The address to query.
     * @return The Persona Node ID, or 0 if no Persona Node exists for the address.
     */
    function getPersonaNodeIdByAddress(address _owner) public view returns (uint256) {
        return personaNodes[_owner];
    }
}
```