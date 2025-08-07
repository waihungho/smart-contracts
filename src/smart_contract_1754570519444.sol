Okay, this is an exciting challenge! Let's design a smart contract for a "Dynamic Soulbound Attestation Protocol" focusing on reputation, skill progression, and verifiable credentials that are tied to a user's identity and can evolve over time. This goes beyond simple NFTs by incorporating time-based dynamics, reputation scoring, and a gamified skill tree.

---

## Chronos Protocol: Dynamic Soulbound Attestations & Skill Tree

### Outline

1.  **Introduction:** Overview of Chronos Protocol's purpose.
2.  **Core Concepts:** Explanation of Dynamic Soulbound Attestations (DSBAs), Verifiable Credential SBTs (VCSBTs), Skill Trees, and Reputation Scoring.
3.  **Features Summary:** List of high-level capabilities.
4.  **Function Summary:** Detailed description of each public and external function.
5.  **Smart Contract Code:** Full Solidity implementation.

### Introduction

The Chronos Protocol is an innovative decentralized system designed to manage evolving on-chain identities, skills, and reputations through a novel concept of "Dynamic Soulbound Attestations" (DSBAs). Unlike static NFTs, DSBAs are non-transferable tokens that represent a verifiable claim or achievement, but critically, their `value`, `status`, or `expiry` can change over time, mimicking real-world skills that can improve, decay, or become outdated. It incorporates a gamified "Skill Tree" where users unlock nodes based on their DSBAs, contributing to a holistic, continuously updated reputation score.

### Core Concepts

*   **Dynamic Soulbound Attestations (DSBAs):** These are ERC-721 tokens that are permanently bound to the recipient's address. They represent a specific claim (e.g., "Web3 Developer Level 3," "Active DAO Contributor," "Completed Course X"). What makes them "Dynamic" is that their associated numerical `value` (e.g., skill level, contribution points) can increase or decrease over time based on protocol rules (e.g., decay), or they can have expiration dates.
*   **Verifiable Credential SBTs (VCSBTs):** A specific type of DSBA where the attestation is issued by a designated `Verifier` (e.g., an educational institution, a DAO, a project lead), serving as an on-chain verifiable credential.
*   **Skill Tree:** A tree-like structure of interconnected "Skill Nodes." Each node represents a specific skill or achievement. Users can "unlock" nodes by possessing the required DSBAs and having unlocked prerequisite nodes. Unlocking nodes contributes to their reputation score.
*   **Reputation Scoring:** A continuously updated score for each user, derived from the sum of values of their active DSBAs and the points awarded from unlocked Skill Tree nodes. This score can be used by other DApps for various purposes (e.g., eligibility for grants, access to gated communities, weighted voting).
*   **Time-Based Mechanics:** DSBAs can have expiration dates, and their numerical values can be subject to a configurable decay rate, requiring continuous engagement or re-attestation to maintain a high reputation.
*   **Dispute Mechanism:** A system allowing designated `Disputers` to challenge fraudulent or incorrect attestations, which can lead to their revocation.

### Features Summary

*   **Non-Transferable ERC-721 Tokens:** DSBAs are strictly non-transferable, reinforcing their soulbound nature.
*   **Configurable Attestation Types:** Define various types of attestations with properties like decay rates, expiry options, and associated metadata.
*   **Flexible Attestation Issuance:** Verifiers can issue DSBAs with specific values and expiration dates to any address.
*   **Dynamic Value Updates:** Attestation values can be explicitly updated by issuers or automatically decayed over time.
*   **Reputation Aggregation:** Calculates and exposes a real-time reputation score for each user.
*   **Gamified Skill Progression:** Users can unlock skill nodes by meeting on-chain criteria (holding specific DSBAs).
*   **Modular Access Control:** Role-based access for `Verifiers`, `Disputers`, and `Administrators`.
*   **On-chain Metadata:** Each DSBA includes a `tokenURI` pointing to its dynamic metadata.
*   **Attestation Challenge/Revocation:** Mechanisms for disputing and revoking attestations.

### Function Summary

**I. Core Attestation Management (DSBAs)**

1.  `registerAttestationType(bytes32 _attestationTypeHash, string memory _name, string memory _description, uint256 _decayRatePermille, bool _canExpire, bool _isVCSBT, string memory _metadataURI)`:
    *   **Description:** Allows the owner to register a new type of attestation, defining its properties like decay rate, expiry, and whether it's a Verifiable Credential SBT.
    *   **Access:** `onlyOwner`.

2.  `issueAttestation(address _recipient, bytes32 _attestationTypeHash, uint256 _value, uint256 _expiresAt, string memory _ipfsHash)`:
    *   **Description:** Allows a registered verifier or the owner to issue a new attestation (DSBA) to a recipient.
    *   **Access:** `onlyVerifier` or `onlyOwner`.
    *   **Note:** Mints a new ERC721 token.

3.  `revokeAttestation(uint256 _attestationId, string memory _reason)`:
    *   **Description:** Allows the original issuer or an administrator to revoke an attestation. Also called by `resolveAttestationDispute` if the dispute confirms fraud.
    *   **Access:** `onlyIssuer` or `onlyOwner`.

4.  `updateAttestationValue(uint256 _attestationId, uint256 _newValue)`:
    *   **Description:** Allows the original issuer to update the numerical value of an existing attestation. Useful for continuous contributions or performance updates.
    *   **Access:** `onlyIssuer`.

5.  `decayAttestation(uint256 _attestationId)`:
    *   **Description:** Applies the defined decay rate to an attestation's value. Can be called by anyone, but only applies if the cooldown period has passed. Designed for external keepers/cron jobs.
    *   **Access:** `public`.

6.  `challengeAttestation(uint256 _attestationId, string memory _reason)`:
    *   **Description:** Initiates a dispute process for a given attestation, changing its status to `Disputed`.
    *   **Access:** `public`.

7.  `resolveAttestationDispute(uint256 _attestationId, bool _isValid, string memory _resolutionNote)`:
    *   **Description:** Allows a designated disputer to resolve an attestation dispute. If `_isValid` is false, the attestation is revoked.
    *   **Access:** `onlyDisputer`.

8.  `getAttestation(uint256 _attestationId)`:
    *   **Description:** Retrieves all details of a specific attestation.
    *   **Access:** `public view`.

9.  `getUserAttestations(address _user)`:
    *   **Description:** Returns a list of all attestation IDs currently held by a user.
    *   **Access:** `public view`.

10. `getAttestationTypeInfo(bytes32 _attestationTypeHash)`:
    *   **Description:** Retrieves the configuration details for a specific attestation type.
    *   **Access:** `public view`.

**II. Skill Tree Management**

11. `addSkillNode(bytes32 _skillNodeHash, string memory _name, string memory _description, uint256 _pointsAwarded, bytes32[] memory _requiredAttestationTypes, bytes32[] memory _prerequisiteSkillNodes)`:
    *   **Description:** Allows the owner to define a new skill node in the tree, specifying its requirements (attestations, prerequisites) and points awarded upon unlock.
    *   **Access:** `onlyOwner`.

12. `unlockSkillNode(bytes32 _skillNodeHash)`:
    *   **Description:** Allows a user to attempt to unlock a skill node. It checks if all required attestations are held, are active, and if all prerequisite skill nodes are already unlocked.
    *   **Access:** `public`.

13. `getSkillNodeDetails(bytes32 _skillNodeHash)`:
    *   **Description:** Retrieves the details of a specific skill node.
    *   **Access:** `public view`.

14. `getUserSkillTreeProgress(address _user, bytes32 _skillNodeHash)`:
    *   **Description:** Checks if a specific skill node has been unlocked by a given user.
    *   **Access:** `public view`.

15. `getUserUnlockedSkillNodes(address _user)`:
    *   **Description:** Returns a list of all skill node hashes unlocked by a user.
    *   **Access:** `public view`.

**III. Reputation Scoring**

16. `getReputationScore(address _user)`:
    *   **Description:** Calculates and returns the current reputation score for a user based on their active DSBAs and unlocked skill nodes.
    *   **Access:** `public view`.
    *   **Note:** This function will re-evaluate scores based on current attestation states and unlocked nodes.

**IV. Admin & Role Management**

17. `addVerifier(address _verifier)`:
    *   **Description:** Grants the `Verifier` role to an address, allowing them to issue new DSBAs.
    *   **Access:** `onlyOwner`.

18. `removeVerifier(address _verifier)`:
    *   **Description:** Revokes the `Verifier` role from an address.
    *   **Access:** `onlyOwner`.

19. `addDisputer(address _disputer)`:
    *   **Description:** Grants the `Disputer` role to an address, allowing them to resolve attestation disputes.
    *   **Access:** `onlyOwner`.

20. `removeDisputer(address _disputer)`:
    *   **Description:** Revokes the `Disputer` role from an address.
    *   **Access:** `onlyOwner`.

**V. ERC721 Overrides (for Soulbound functionality)**

21. `tokenURI(uint256 _tokenId)`:
    *   **Description:** Overrides ERC721's `tokenURI` to provide a dynamic metadata URI for each DSBA.
    *   **Access:** `public view`.

22. `_update(address to, uint256 tokenId, address auth)`:
    *   **Description:** Internal override to prevent any transfer of DSBA tokens.
    *   **Access:** `internal`.

---

### Smart Contract Code

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

// Custom Errors
error Chronos__NotVerifier();
error Chronos__NotDisputer();
error Chronos__AttestationNotFound();
error Chronos__AttestationExpired();
error Chronos__AttestationTypeNotRegistered();
error Chronos__AttestationNotActive();
error Chronos__AttestationAlreadyDisputed();
error Chronos__AttestationNotDisputed();
error Chronos__AttestationNotOwnedOrIssuer();
error Chronos__AttestationValueUpdateFailed();
error Chronos__SkillNodeNotFound();
error Chronos__SkillNodeAlreadyUnlocked();
error Chronos__SkillNodePrerequisitesNotMet();
error Chronos__SkillNodeRequiredAttestationsNotMet();
error Chronos__CannotTransferSoulboundToken();
error Chronos__InvalidDecayRate();
error Chronos__InvalidAttestationValue();
error Chronos__InvalidExpiryTime();

/**
 * @title ChronosProtocol
 * @dev A dynamic Soulbound Attestation and Skill Tree protocol.
 *      DSBAs (Dynamic Soulbound Attestations) are non-transferable ERC-721 tokens
 *      whose values can decay or be updated, contributing to a user's reputation.
 *      Users can unlock skill tree nodes based on their DSBAs, further boosting reputation.
 */
contract ChronosProtocol is ERC721, Ownable, ReentrancyGuard {
    using Counters for Counters.Counter;
    using Strings for uint256;

    // --- State Variables & Mappings ---

    Counters.Counter private _attestationIds;

    // Attestation Status
    enum AttestationStatus {
        ACTIVE,
        REVOKED,
        DISPUTED
    }

    // Struct for an Attestation Type configuration
    struct AttestationTypeInfo {
        string name;
        string description;
        uint256 decayRatePermille; // e.g., 100 = 10% per decay period
        uint256 decayPeriodSeconds; // How often decay occurs (e.g., 1 day)
        bool canExpire;
        bool isVCSBT; // Is this a Verifiable Credential SBT?
        string metadataURI; // Base URI for attestation type metadata
    }

    // Struct for an individual Attestation (DSBA - Dynamic Soulbound Attestation)
    struct Attestation {
        uint256 id;
        bytes32 attestationTypeHash;
        address issuer;
        address recipient;
        uint256 value; // Dynamic numerical value (e.g., skill level, points)
        uint256 issuedAt;
        uint256 expiresAt; // 0 for permanent
        AttestationStatus status;
        string ipfsHash; // Link to off-chain evidence/details
        uint256 lastDecayAt; // Timestamp of the last decay application
    }

    // Mapping: attestationId => Attestation
    mapping(uint256 => Attestation) public attestationIdToAttestation;
    // Mapping: recipientAddress => List of attestation IDs
    mapping(address => uint256[]) public userAttestations;
    // Mapping: attestationTypeHash => AttestationTypeInfo
    mapping(bytes32 => AttestationTypeInfo) public attestationTypeHashes;

    // Skill Tree Structures
    struct SkillNode {
        string name;
        string description;
        uint256 pointsAwarded; // Points added to reputation upon unlock
        bytes32[] requiredAttestationTypes; // Attestation types needed to unlock
        bytes32[] prerequisiteSkillNodes; // Other skill nodes needed to unlock
        string metadataURI; // URI for skill node metadata
    }

    // Mapping: skillNodeHash => SkillNode
    mapping(bytes32 => SkillNode) public skillNodes;
    // Mapping: userAddress => skillNodeHash => true (if unlocked)
    mapping(address => mapping(bytes32 => bool)) public userSkillTreeProgress;
    // Mapping: userAddress => list of unlocked skillNodeHashes
    mapping(address => bytes32[]) public userUnlockedSkillNodes;

    // Access Control
    mapping(address => bool) public isVerifier;
    mapping(address => bool) public isDisputer;

    // Event Declarations
    event AttestationTypeRegistered(bytes32 indexed attestationTypeHash, string name, string description);
    event AttestationIssued(uint256 indexed attestationId, bytes32 indexed attestationTypeHash, address indexed recipient, address issuer, uint256 value, uint256 expiresAt);
    event AttestationValueUpdated(uint256 indexed attestationId, uint256 oldValue, uint256 newValue);
    event AttestationRevoked(uint256 indexed attestationId, address indexed revoker, string reason);
    event AttestationChallenged(uint256 indexed attestationId, address indexed challenger, string reason);
    event AttestationDisputeResolved(uint256 indexed attestationId, bool isValid, address indexed resolver, string resolutionNote);
    event AttestationDecayed(uint256 indexed attestationId, uint256 oldValue, uint256 newValue);

    event SkillNodeAdded(bytes32 indexed skillNodeHash, string name, uint256 pointsAwarded);
    event SkillNodeUnlocked(address indexed user, bytes32 indexed skillNodeHash, uint256 newReputationScore);

    event VerifierAdded(address indexed verifier);
    event VerifierRemoved(address indexed verifier);
    event DisputerAdded(address indexed disputer);
    event DisputerRemoved(address indexed disputer);

    // --- Constructor ---

    constructor() ERC721("Chronos Protocol Attestation", "CHRONOS") Ownable(msg.sender) {
        // Owner is initially a verifier and disputer by default for easier setup
        isVerifier[msg.sender] = true;
        isDisputer[msg.sender] = true;
    }

    // --- Modifiers ---

    modifier onlyVerifier() {
        if (!isVerifier[msg.sender]) revert Chronos__NotVerifier();
        _;
    }

    modifier onlyDisputer() {
        if (!isDisputer[msg.sender]) revert Chronos__NotDisputer();
        _;
    }

    modifier isValidAttestationType(bytes32 _attestationTypeHash) {
        if (attestationTypeHashes[_attestationTypeHash].name == "")
            revert Chronos__AttestationTypeNotRegistered();
        _;
    }

    // --- I. Core Attestation Management (DSBAs) ---

    /**
     * @dev Registers a new type of attestation.
     * @param _attestationTypeHash A unique hash identifying this attestation type (e.g., keccak256("DeveloperSkillLevel")).
     * @param _name The human-readable name of the attestation type.
     * @param _description A detailed description.
     * @param _decayRatePermille The percentage of decay per decay period (e.g., 100 = 10% decay). 0 for no decay. Max 1000 (100%).
     * @param _decayPeriodSeconds The time period in seconds after which decay can be applied. 0 for no decay.
     * @param _canExpire True if attestations of this type can have an expiration date.
     * @param _isVCSBT True if this type represents a Verifiable Credential SBT.
     * @param _metadataURI Base URI for off-chain metadata associated with this type.
     */
    function registerAttestationType(
        bytes32 _attestationTypeHash,
        string memory _name,
        string memory _description,
        uint256 _decayRatePermille,
        uint256 _decayPeriodSeconds,
        bool _canExpire,
        bool _isVCSBT,
        string memory _metadataURI
    ) external onlyOwner {
        if (_decayRatePermille > 1000) revert Chronos__InvalidDecayRate(); // Max 100% decay
        if (_decayRatePermille > 0 && _decayPeriodSeconds == 0) revert Chronos__InvalidDecayRate(); // Must have a period if decaying
        if (attestationTypeHashes[_attestationTypeHash].name != "") {
            revert("Chronos: Attestation type already registered.");
        }

        attestationTypeHashes[_attestationTypeHash] = AttestationTypeInfo({
            name: _name,
            description: _description,
            decayRatePermille: _decayRatePermille,
            decayPeriodSeconds: _decayPeriodSeconds,
            canExpire: _canExpire,
            isVCSBT: _isVCSBT,
            metadataURI: _metadataURI
        });

        emit AttestationTypeRegistered(_attestationTypeHash, _name, _description);
    }

    /**
     * @dev Issues a new Dynamic Soulbound Attestation (DSBA) to a recipient.
     * Mints a new ERC721 token that is non-transferable.
     * @param _recipient The address to whom the attestation is issued.
     * @param _attestationTypeHash The type of attestation being issued.
     * @param _value The initial numerical value of the attestation (e.g., skill level).
     * @param _expiresAt The Unix timestamp when the attestation expires (0 for permanent).
     * @param _ipfsHash IPFS hash linking to the full verifiable credential or evidence.
     */
    function issueAttestation(
        address _recipient,
        bytes32 _attestationTypeHash,
        uint256 _value,
        uint256 _expiresAt,
        string memory _ipfsHash
    ) external nonReentrant onlyVerifier isValidAttestationType(_attestationTypeHash) {
        if (_value == 0) revert Chronos__InvalidAttestationValue();
        AttestationTypeInfo storage typeInfo = attestationTypeHashes[_attestationTypeHash];
        if (!typeInfo.canExpire && _expiresAt != 0) revert Chronos__InvalidExpiryTime();
        if (typeInfo.canExpire && _expiresAt != 0 && _expiresAt <= block.timestamp) revert Chronos__InvalidExpiryTime();

        _attestationIds.increment();
        uint256 newId = _attestationIds.current();

        Attestation memory newAttestation = Attestation({
            id: newId,
            attestationTypeHash: _attestationTypeHash,
            issuer: msg.sender,
            recipient: _recipient,
            value: _value,
            issuedAt: block.timestamp,
            expiresAt: _expiresAt,
            status: AttestationStatus.ACTIVE,
            ipfsHash: _ipfsHash,
            lastDecayAt: block.timestamp // Initialize last decay time
        });

        attestationIdToAttestation[newId] = newAttestation;
        userAttestations[_recipient].push(newId);
        _safeMint(_recipient, newId); // Mints the ERC721 token

        emit AttestationIssued(newId, _attestationTypeHash, _recipient, msg.sender, _value, _expiresAt);
    }

    /**
     * @dev Revokes an existing attestation.
     * Can only be called by the original issuer or the contract owner.
     * @param _attestationId The ID of the attestation to revoke.
     * @param _reason The reason for revocation.
     */
    function revokeAttestation(uint256 _attestationId, string memory _reason) external nonReentrant {
        Attestation storage att = attestationIdToAttestation[_attestationId];
        if (att.id == 0) revert Chronos__AttestationNotFound();
        if (att.status == AttestationStatus.REVOKED) revert("Chronos: Attestation already revoked.");

        // Only issuer or owner can revoke
        if (att.issuer != msg.sender && owner() != msg.sender)
            revert Chronos__AttestationNotOwnedOrIssuer();

        att.status = AttestationStatus.REVOKED;
        _burn(att.recipient, _attestationId); // Burns the ERC721 token

        emit AttestationRevoked(_attestationId, msg.sender, _reason);
    }

    /**
     * @dev Updates the numerical value of an existing attestation.
     * Can only be called by the original issuer.
     * @param _attestationId The ID of the attestation to update.
     * @param _newValue The new numerical value.
     */
    function updateAttestationValue(uint256 _attestationId, uint256 _newValue) external nonReentrant {
        Attestation storage att = attestationIdToAttestation[_attestationId];
        if (att.id == 0) revert Chronos__AttestationNotFound();
        if (att.issuer != msg.sender) revert Chronos__AttestationNotOwnedOrIssuer();
        if (att.status != AttestationStatus.ACTIVE) revert Chronos__AttestationNotActive();
        if (_newValue == 0) revert Chronos__InvalidAttestationValue();

        uint256 oldValue = att.value;
        att.value = _newValue;

        emit AttestationValueUpdated(_attestationId, oldValue, _newValue);
    }

    /**
     * @dev Applies the configured decay rate to an attestation's value.
     * Can be called by anyone; intended for external keepers/cron jobs.
     * Only applies if the decay period has passed since last decay or issuance.
     * @param _attestationId The ID of the attestation to decay.
     */
    function decayAttestation(uint256 _attestationId) external nonReentrant {
        Attestation storage att = attestationIdToAttestation[_attestationId];
        if (att.id == 0) revert Chronos__AttestationNotFound();
        if (att.status != AttestationStatus.ACTIVE) return; // Only decay active attestations

        AttestationTypeInfo storage typeInfo = attestationTypeHashes[att.attestationTypeHash];
        if (typeInfo.decayRatePermille == 0 || typeInfo.decayPeriodSeconds == 0) return; // No decay configured

        uint256 decayPeriodsPassed = (block.timestamp - att.lastDecayAt) / typeInfo.decayPeriodSeconds;
        if (decayPeriodsPassed == 0) return; // Not enough time passed for decay

        uint256 oldValue = att.value;
        uint256 newCalculatedValue = att.value;

        for (uint256 i = 0; i < decayPeriodsPassed; i++) {
            newCalculatedValue = (newCalculatedValue * (1000 - typeInfo.decayRatePermille)) / 1000;
        }
        
        // Ensure value doesn't drop to 0 unexpectedly, unless decay completely depletes it
        if (newCalculatedValue < 1 && oldValue >= 1) { // If it drops below 1, set to 0 to signify completion of decay
            newCalculatedValue = 0;
        }

        att.value = newCalculatedValue;
        att.lastDecayAt = block.timestamp; // Update last decay timestamp

        if (att.value == 0) {
            att.status = AttestationStatus.REVOKED; // Automatically revoke if value becomes 0
            _burn(att.recipient, _attestationId);
        }

        emit AttestationDecayed(_attestationId, oldValue, att.value);
    }

    /**
     * @dev Initiates a dispute for a given attestation, changing its status to DISPUTED.
     * Any user can challenge an attestation.
     * @param _attestationId The ID of the attestation to challenge.
     * @param _reason The reason for challenging the attestation.
     */
    function challengeAttestation(uint256 _attestationId, string memory _reason) external nonReentrant {
        Attestation storage att = attestationIdToAttestation[_attestationId];
        if (att.id == 0) revert Chronos__AttestationNotFound();
        if (att.status != AttestationStatus.ACTIVE) revert Chronos__AttestationNotActive();
        if (att.status == AttestationStatus.DISPUTED) revert Chronos__AttestationAlreadyDisputed();

        att.status = AttestationStatus.DISPUTED;

        emit AttestationChallenged(_attestationId, msg.sender, _reason);
    }

    /**
     * @dev Resolves a dispute for an attestation.
     * Only callable by a designated disputer. If `_isValid` is false, the attestation is revoked.
     * @param _attestationId The ID of the attestation whose dispute is being resolved.
     * @param _isValid True if the attestation is found to be valid, false otherwise (leads to revocation).
     * @param _resolutionNote A note explaining the resolution.
     */
    function resolveAttestationDispute(uint256 _attestationId, bool _isValid, string memory _resolutionNote) external nonReentrant onlyDisputer {
        Attestation storage att = attestationIdToAttestation[_attestationId];
        if (att.id == 0) revert Chronos__AttestationNotFound();
        if (att.status != AttestationStatus.DISPUTED) revert Chronos__AttestationNotDisputed();

        if (_isValid) {
            att.status = AttestationStatus.ACTIVE;
        } else {
            att.status = AttestationStatus.REVOKED;
            _burn(att.recipient, _attestationId); // Burns the token if invalid
        }

        emit AttestationDisputeResolved(_attestationId, _isValid, msg.sender, _resolutionNote);
    }

    /**
     * @dev Retrieves details of a specific attestation by its ID.
     * @param _attestationId The ID of the attestation.
     * @return An Attestation struct containing all details.
     */
    function getAttestation(uint256 _attestationId) public view returns (Attestation memory) {
        Attestation memory att = attestationIdToAttestation[_attestationId];
        if (att.id == 0) revert Chronos__AttestationNotFound();
        return att;
    }

    /**
     * @dev Retrieves all attestation IDs for a given user.
     * @param _user The address of the user.
     * @return An array of attestation IDs.
     */
    function getUserAttestations(address _user) public view returns (uint256[] memory) {
        return userAttestations[_user];
    }

    /**
     * @dev Retrieves information about a specific attestation type.
     * @param _attestationTypeHash The hash of the attestation type.
     * @return An AttestationTypeInfo struct.
     */
    function getAttestationTypeInfo(bytes32 _attestationTypeHash) public view isValidAttestationType(_attestationTypeHash) returns (AttestationTypeInfo memory) {
        return attestationTypeHashes[_attestationTypeHash];
    }

    // --- II. Skill Tree Management ---

    /**
     * @dev Adds a new skill node to the Chronos Protocol's skill tree.
     * @param _skillNodeHash A unique hash identifying this skill node (e.g., keccak256("AdvancedSolidity")).
     * @param _name The human-readable name of the skill node.
     * @param _description A description of the skill node.
     * @param _pointsAwarded Points added to user's reputation upon unlocking this node.
     * @param _requiredAttestationTypes Array of attestation type hashes required to unlock this node.
     * @param _prerequisiteSkillNodes Array of skill node hashes that must be unlocked first.
     * @param _metadataURI URI for off-chain metadata associated with this skill node.
     */
    function addSkillNode(
        bytes32 _skillNodeHash,
        string memory _name,
        string memory _description,
        uint256 _pointsAwarded,
        bytes32[] memory _requiredAttestationTypes,
        bytes32[] memory _prerequisiteSkillNodes,
        string memory _metadataURI
    ) external onlyOwner {
        if (skillNodes[_skillNodeHash].name != "") {
            revert("Chronos: Skill node already exists.");
        }
        skillNodes[_skillNodeHash] = SkillNode({
            name: _name,
            description: _description,
            pointsAwarded: _pointsAwarded,
            requiredAttestationTypes: _requiredAttestationTypes,
            prerequisiteSkillNodes: _prerequisiteSkillNodes,
            metadataURI: _metadataURI
        });

        emit SkillNodeAdded(_skillNodeHash, _name, _pointsAwarded);
    }

    /**
     * @dev Allows a user to attempt to unlock a skill node.
     * Checks if all required attestations are held and active, and if prerequisite nodes are unlocked.
     * @param _skillNodeHash The hash of the skill node to unlock.
     */
    function unlockSkillNode(bytes32 _skillNodeHash) external nonReentrant {
        SkillNode storage node = skillNodes[_skillNodeHash];
        if (node.name == "") revert Chronos__SkillNodeNotFound();
        if (userSkillTreeProgress[msg.sender][_skillNodeHash]) revert Chronos__SkillNodeAlreadyUnlocked();

        // Check prerequisites
        for (uint256 i = 0; i < node.prerequisiteSkillNodes.length; i++) {
            if (!userSkillTreeProgress[msg.sender][node.prerequisiteSkillNodes[i]]) {
                revert Chronos__SkillNodePrerequisitesNotMet();
            }
        }

        // Check required attestations
        uint256[] memory currentUserAttestations = userAttestations[msg.sender];
        for (uint256 i = 0; i < node.requiredAttestationTypes.length; i++) {
            bool foundRequiredAttestation = false;
            bytes32 requiredType = node.requiredAttestationTypes[i];
            for (uint256 j = 0; j < currentUserAttestations.length; j++) {
                Attestation storage att = attestationIdToAttestation[currentUserAttestations[j]];
                // Ensure attestation is active, not expired, and of the required type
                if (att.status == AttestationStatus.ACTIVE &&
                    (att.expiresAt == 0 || att.expiresAt > block.timestamp) &&
                    att.attestationTypeHash == requiredType &&
                    att.value > 0 // Attestation must have a non-zero value
                ) {
                    foundRequiredAttestation = true;
                    break;
                }
            }
            if (!foundRequiredAttestation) {
                revert Chronos__SkillNodeRequiredAttestationsNotMet();
            }
        }

        userSkillTreeProgress[msg.sender][_skillNodeHash] = true;
        userUnlockedSkillNodes[msg.sender].push(_skillNodeHash);

        emit SkillNodeUnlocked(msg.sender, _skillNodeHash, getReputationScore(msg.sender)); // Recalculate and emit new score
    }

    /**
     * @dev Retrieves details of a specific skill node by its hash.
     * @param _skillNodeHash The hash of the skill node.
     * @return A SkillNode struct.
     */
    function getSkillNodeDetails(bytes32 _skillNodeHash) public view returns (SkillNode memory) {
        SkillNode memory node = skillNodes[_skillNodeHash];
        if (node.name == "") revert Chronos__SkillNodeNotFound();
        return node;
    }

    /**
     * @dev Checks if a specific skill node has been unlocked by a user.
     * @param _user The address of the user.
     * @param _skillNodeHash The hash of the skill node.
     * @return True if unlocked, false otherwise.
     */
    function getUserSkillTreeProgress(address _user, bytes32 _skillNodeHash) public view returns (bool) {
        return userSkillTreeProgress[_user][_skillNodeHash];
    }

    /**
     * @dev Returns an array of all skill node hashes unlocked by a user.
     * @param _user The address of the user.
     * @return An array of skill node hashes.
     */
    function getUserUnlockedSkillNodes(address _user) public view returns (bytes32[] memory) {
        return userUnlockedSkillNodes[_user];
    }

    // --- III. Reputation Scoring ---

    /**
     * @dev Calculates and returns the current reputation score for a user.
     * This score is derived from the values of active, non-expired DSBAs
     * and points awarded from unlocked skill nodes.
     * @param _user The address of the user.
     * @return The calculated reputation score.
     */
    function getReputationScore(address _user) public view returns (uint256) {
        uint256 score = 0;

        // Sum active attestation values
        uint256[] memory currentAttestations = userAttestations[_user];
        for (uint256 i = 0; i < currentAttestations.length; i++) {
            Attestation storage att = attestationIdToAttestation[currentAttestations[i]];
            // Only count active, non-expired attestations with positive value
            if (att.status == AttestationStatus.ACTIVE &&
                (att.expiresAt == 0 || att.expiresAt > block.timestamp) &&
                att.value > 0
            ) {
                // Decay may need to be applied here if not triggered externally often enough.
                // For a view function, it's more gas efficient to return current state.
                // An external "decayAttestation" call or a keeper network should handle updates.
                score += att.value;
            }
        }

        // Add points from unlocked skill nodes
        bytes32[] memory unlockedNodes = userUnlockedSkillNodes[_user];
        for (uint256 i = 0; i < unlockedNodes.length; i++) {
            score += skillNodes[unlockedNodes[i]].pointsAwarded;
        }

        return score;
    }

    // --- IV. Admin & Role Management ---

    /**
     * @dev Grants the `Verifier` role to an address.
     * Verifiers can issue new attestations.
     * @param _verifier The address to grant the role to.
     */
    function addVerifier(address _verifier) external onlyOwner {
        isVerifier[_verifier] = true;
        emit VerifierAdded(_verifier);
    }

    /**
     * @dev Revokes the `Verifier` role from an address.
     * @param _verifier The address to revoke the role from.
     */
    function removeVerifier(address _verifier) external onlyOwner {
        isVerifier[_verifier] = false;
        emit VerifierRemoved(_verifier);
    }

    /**
     * @dev Grants the `Disputer` role to an address.
     * Disputers can resolve attestation challenges.
     * @param _disputer The address to grant the role to.
     */
    function addDisputer(address _disputer) external onlyOwner {
        isDisputer[_disputer] = true;
        emit DisputerAdded(_disputer);
    }

    /**
     * @dev Revokes the `Disputer` role from an address.
     * @param _disputer The address to revoke the role from.
     */
    function removeDisputer(address _disputer) external onlyOwner {
        isDisputer[_disputer] = false;
        emit DisputerRemoved(_disputer);
    }

    // --- V. ERC721 Overrides (for Soulbound functionality) ---

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `_tokenId` token.
     * @param _tokenId The ID of the attestation token.
     * @return The URI.
     */
    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        Attestation storage att = attestationIdToAttestation[_tokenId];
        if (att.id == 0) revert Chronos__AttestationNotFound();

        AttestationTypeInfo storage typeInfo = attestationTypeHashes[att.attestationTypeHash];
        // In a real application, this would point to an API endpoint
        // that dynamically generates JSON metadata based on the attestation state.
        // For example: "https://api.chronosprotocol.xyz/attestations/{id}"
        return string(abi.encodePacked(typeInfo.metadataURI, _tokenId.toString(), "/", att.ipfsHash));
    }

    /**
     * @dev Overrides the internal _update function to prevent any transfer of the token.
     * This is the core mechanism for making the ERC721 token Soulbound.
     * Any attempt to transfer or approve will revert.
     */
    function _update(address to, uint256 tokenId, address auth) internal override returns (address) {
        if (to != address(0) && ownerOf(tokenId) != address(0) && to != ownerOf(tokenId)) {
            revert Chronos__CannotTransferSoulboundToken();
        }
        return super._update(to, tokenId, auth);
    }

    // Additional overrides to ensure non-transferability through standard ERC721 methods
    function approve(address to, uint256 tokenId) public override {
        revert Chronos__CannotTransferSoulboundToken();
    }

    function setApprovalForAll(address operator, bool approved) public override {
        revert Chronos__CannotTransferSoulboundToken();
    }

    function transferFrom(address from, address to, uint256 tokenId) public override {
        revert Chronos__CannotTransferSoulboundToken();
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public override {
        revert Chronos__CannotTransferSoulboundToken();
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public override {
        revert Chronos__CannotTransferSoulboundToken();
    }

    // ERC165 support
    function supportsInterface(bytes4 interfaceId) public view override(ERC721, IERC165) returns (bool) {
        return interfaceId == type(IERC721).interfaceId || super.supportsInterface(interfaceId);
    }
}
```