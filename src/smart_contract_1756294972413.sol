This smart contract, "Aetherial Echoes," aims to establish a sophisticated, decentralized reputation and skill network on the blockchain. It introduces a novel system of verifiable "Echoes" (attestations) that are dynamic, contextual, and interconnected. These Echoes directly influence a user's "AetherAvatar," a dynamic NFT that visually evolves with their on-chain persona. The contract integrates advanced concepts like decaying reputation, prerequisite-driven attestations, social endorsements, and a "Wisdom Oracle" for subjective expert assessments, all designed to foster a rich, non-fungible on-chain identity.

This contract avoids direct duplication of existing open-source projects by combining these advanced concepts in a unique, integrated system. While individual elements (like ERC721 or basic attestations) exist, their specific synergistic implementation for dynamic reputation, dNFT evolution based on complex decaying scores, and the "Wisdom Oracle" for qualitative assessment with challenge mechanisms offers a novel approach.

---

## Contract Outline

**I. Contract Description & Core Concepts**
*   **Purpose:** Decentralized Reputation, Skill, and Identity Network.
*   **Key Features:**
    *   **Contextual & Dynamic Echoes (Attestations):** Verifiable claims of skills/achievements with defined strength, decay rates, and contextual data.
    *   **Skill-Tree Prerequisites:** Certain Echoes require prior attainment of other Echoes, building a structured skill graph.
    *   **Decay & Endorsement Mechanisms:** Echo strength naturally diminishes over time but can be boosted by social endorsements from other users.
    *   **Dynamic NFT (AetherAvatar):** An ERC721 NFT that visually or metadata-wise evolves based on the owner's cumulative and current Echoes.
    *   **"Wisdom Oracle" for Subjective Assessment:** A permissioned system allowing trusted experts (or future AI) to provide qualitative, verifiable assessments for high-value Echoes.
    *   **Challenge & Resolution System:** A mechanism for the community to dispute the validity of an Echo, with a resolution process to maintain integrity.
    *   **Delegate Attestors:** Allows designated entities to issue Echoes on behalf of the protocol, enabling scalability and specialized attestation sources.
*   **Avoids Duplication By:**
    *   Integrating a dynamic NFT directly tied to a complex, decaying, and prerequisite-driven reputation system.
    *   Implementing contextual attestations with explicit strength, decay, and social endorsement mechanics.
    *   Introducing a "Wisdom Oracle" for qualitative assessment with a challenge mechanism, distinct from simple data-feed oracles.
    *   Combining these features into a cohesive, inter-dependent identity and reputation platform.

**II. Data Structures**
*   `Profile`: Stores user's core identity information, metadata hash, and linked AetherAvatar ID.
*   `EchoType`: Defines the blueprint for a category of Echo (e.g., "Solidity Expert"), including its name, description, base strength, decay rate, and prerequisites.
*   `Echo`: Represents an individual attestation, linking to an `EchoType`, its attestor, profile owner, specific context, current strength, and timestamps.
*   `Endorsement`: Records when one user endorses another's Echo, boosting its strength.
*   `Challenge`: Details a dispute against an Echo's validity, including challenger, reason, and resolution status.

**III. Functions Summary**

**A. Profile & Identity Management**
1.  `registerAetherialProfile(string memory _profileMetadataHash)`:
    *   **Purpose:** Initializes a user's unique on-chain profile.
    *   **Concept:** Foundation for the entire identity system, linking a user's address to their reputation and avatar.
2.  `updateProfileMetadataHash(string memory _newMetadataHash)`:
    *   **Purpose:** Allows a profile owner to update their public profile information (e.g., bio, avatar image link).
    *   **Concept:** Decentralized and user-controlled identity updates.
3.  `delegateProfileAccess(address _delegate, bool _canAttest)`:
    *   **Purpose:** Placeholder for granting specific rights (e.g., attestation, management) for a delegate over one's profile.
    *   **Concept:** Future-proofing for sophisticated delegated identity management and meta-transactions.

**B. Echo (Attestation) Management**
4.  `configureEchoType(string memory _name, string memory _descriptionHash, uint256 _baseStrength, uint256 _decayRatePermille, uint256[] memory _prerequisiteEchoTypeIds)`:
    *   **Purpose:** The contract owner defines a new category of "Echo" with its unique properties (e.g., "Master Brewer" with high base strength, slow decay, and "Junior Brewer" as a prerequisite).
    *   **Concept:** Introduces a "skill-tree" or hierarchical reputation structure with dynamic property definition.
5.  `attestEcho(address _profileOwner, uint256 _echoTypeId, string memory _contextHash)`:
    *   **Purpose:** Creates a verifiable attestation for a user (e.g., "John Doe achieved Solidity Expert status for Project X").
    *   **Concept:** Core attestation mechanism, enforcing prerequisites and initiating the dynamic reputation lifecycle.
6.  `revokeEcho(uint256 _echoId)`:
    *   **Purpose:** Allows the original attestor to invalidate an Echo they previously issued.
    *   **Concept:** Provides a mechanism for correcting errors or reacting to a change in the attested state.
7.  `endorseEcho(uint256 _echoId, string memory _endorsementContextHash)`:
    *   **Purpose:** Allows any registered profile owner to publicly endorse another user's Echo, providing social validation.
    *   **Concept:** Introduces a social reputation boost, where endorsements increase an Echo's effective strength and reset its decay clock.
8.  `challengeEcho(uint256 _echoId, string memory _reasonHash)`:
    *   **Purpose:** Enables any registered user to initiate a formal dispute against the validity of an Echo.
    *   **Concept:** A decentralized integrity mechanism, allowing the community to flag fraudulent or incorrect attestations.
9.  `resolveChallenge(uint256 _challengeId, bool _isValid, string memory _resolutionHash)`:
    *   **Purpose:** The contract owner (or a future DAO) resolves an open challenge, either validating or invalidating the Echo.
    *   **Concept:** Governance mechanism to maintain the trustworthiness of the attestation network.
10. `updateEchoStrength(uint256 _echoId, uint256 _newStrength)`:
    *   **Purpose:** Allows the original attestor to manually adjust the strength of an Echo, reflecting ongoing contribution or skill changes.
    *   **Concept:** Manual fine-tuning of dynamic reputation, complementing automated decay and endorsements.
11. `setEchoPrerequisites(uint256 _echoTypeId, uint256[] memory _newPrerequisiteEchoTypeIds)`:
    *   **Purpose:** Contract owner can update the prerequisite EchoTypes for an existing EchoType.
    *   **Concept:** Allows for the evolution and refinement of the skill-tree structure over time.
12. `grantDelegateAttestor(address _delegate, bool _canAttest)`:
    *   **Purpose:** Contract owner grants global permission to an address to issue Echoes.
    *   **Concept:** Enables a distributed network of trusted attestors, scaling the issuance of reputation without centralizing control.
13. `getEchoCurrentStrength(uint256 _echoId)`:
    *   **Purpose:** Calculates the real-time, effective strength of a specific Echo, considering its initial value, decay over time, and endorsements.
    *   **Concept:** Provides an accurate, dynamic representation of an Echo's current relevance and impact.

**C. Reputation & Scoring**
14. `getProfileEchoScore(address _profileOwner, uint256 _echoTypeId)`:
    *   **Purpose:** Aggregates the current strength of all active Echoes of a specific type for a user, providing a score for that skill/category.
    *   **Concept:** Granular reputation scoring, allowing assessment of specific areas of expertise.
15. `getOverallReputationScore(address _profileOwner)`:
    *   **Purpose:** Calculates a user's total, global reputation score across all their active Echoes and all EchoTypes.
    *   **Concept:** A comprehensive and dynamic on-chain reputation metric.
16. `getWeightedEchoCount(address _profileOwner, uint256 _echoTypeId)`:
    *   **Purpose:** Returns a count of unique, active Echoes of a certain type, weighted by their current strength relative to their base strength.
    *   **Concept:** Measures the "depth" or "breadth" of a user's achievement within a specific EchoType, not just raw score.

**D. Dynamic NFT (AetherAvatar) Integration**
17. `mintAetherAvatar(string memory _tokenURI)`:
    *   **Purpose:** Mints a unique AetherAvatar NFT for the calling profile, acting as their visual on-chain identity.
    *   **Concept:** Links a dynamic NFT directly to the user's reputation, making identity tangible and visual.
18. `getAetherAvatarDynamicMetadata(uint256 _tokenId)`:
    *   **Purpose:** Generates a dynamic metadata URI for an AetherAvatar, which changes based on the owner's current Echoes and overall reputation.
    *   **Concept:** Core dynamic NFT functionality; an off-chain server interprets this URI (containing a hash derived from reputation) to render a unique image and JSON metadata reflecting the avatar's evolution.
19. `evolveAetherAvatar(uint256 _tokenId)`:
    *   **Purpose:** Triggers an explicit re-evaluation of the AetherAvatar's state, updating its internal tokenURI with the latest dynamic metadata.
    *   **Concept:** Allows users to "evolve" their avatar on-demand, reflecting recent changes in their reputation and skill set.

**E. Wisdom Oracle (Simulated Expert System)**
20. `setWisdomOracle(address _oracle, bool _isTrusted)`:
    *   **Purpose:** Contract owner grants or revokes "trusted oracle" status to an address.
    *   **Concept:** Establishes a permissioned network of expert assessors for subjective or qualitative evaluations.
21. `requestWisdomAssessment(uint256 _echoId, string memory _requestContextHash)`:
    *   **Purpose:** A profile owner requests a trusted oracle to provide an assessment for one of their Echoes.
    *   **Concept:** Mechanism for seeking expert validation for high-stakes or complex attestations that require human judgment or off-chain analysis.
22. `submitWisdomAssessment(uint256 _echoId, string memory _assessmentHash, uint256 _newStrength)`:
    *   **Purpose:** A trusted oracle submits their assessment for an Echo, potentially adjusting its strength or invalidating it.
    *   **Concept:** The "AI/Expert" layer of the reputation system, allowing qualitative judgment to influence quantitative scores.

---

## Smart Contract Source Code

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol"; // For toHexString

/**
 * @title Aetherial Echoes: The Decentralized Reputation & Skill Network
 * @dev This contract creates a dynamic, multi-faceted on-chain reputation and skill system,
 *      integrated with a dynamic NFT (AetherAvatar) that evolves based on a user's verifiable
 *      "Echoes" (attestations). It incorporates concepts like contextual, decaying, and
 *      prerequisite-driven attestations, social endorsements, and a permissioned "Wisdom Oracle"
 *      for subjective assessments, aiming to create a rich, non-fungible on-chain identity.
 *      It aims to avoid direct duplication of existing open-source projects by combining these
 *      advanced concepts in a novel, integrated system.
 */

contract AetherialEchoes is ERC721, Ownable {
    using Counters for Counters.Counter;

    // --- Data Structures ---

    struct Profile {
        address owner;
        string metadataHash; // IPFS CID for profile picture, description, etc.
        bool isRegistered;
        uint256 avatarTokenId; // 0 if no avatar minted, otherwise the tokenId
    }

    struct EchoType {
        string name;
        string descriptionHash; // IPFS CID for detailed description of the EchoType
        uint256 baseStrength; // Initial strength of an Echo of this type
        uint256 decayRatePermille; // Decay rate in per-mille (e.g., 100 = 10% per time unit)
        uint256[] prerequisiteEchoTypeIds; // IDs of EchoTypes required before this one can be attested
        bool exists; // To check if an EchoType ID is valid
    }

    struct Echo {
        uint256 id;
        uint256 echoTypeId;
        address attestor; // Who issued this Echo
        address profileOwner; // To whom this Echo is attributed
        string contextHash; // IPFS CID for specific details of this attestation (e.g., project link, proof)
        uint256 strength; // Current numerical strength, can be adjusted
        uint256 issuedAt;
        bool isActive; // Can be false if revoked or challenged and invalidated
        uint256 lastStrengthUpdate; // Timestamp of the last strength change (for decay calculation)
    }

    struct Endorsement {
        uint256 echoId;
        address endorser;
        string contextHash; // IPFS CID for reason of endorsement
        uint256 endorsedAt;
        bool isActive; // Can be false if endorser revokes (not implemented for simplicity)
    }

    struct Challenge {
        uint256 id;
        uint256 echoId;
        address challenger;
        string reasonHash; // IPFS CID for reason of challenge
        uint256 challengedAt;
        bool isOpen; // true if awaiting resolution
        bool isResolvedValid; // true if resolved in favor of Echo, false if invalidated
        string resolutionHash; // IPFS CID for resolution details
    }

    // --- State Variables ---

    Counters.Counter private _profileIds; // Not directly used for IDs, but to track count
    Counters.Counter private _echoTypeIds;
    Counters.Counter private _echoIds;
    Counters.Counter private _challengeIds;
    Counters.Counter private _avatarTokenIds;

    mapping(address => Profile) public profiles;
    mapping(uint256 => EchoType) public echoTypes;
    mapping(uint256 => Echo) public echoes;
    mapping(uint256 => Challenge) public challenges;

    // Mapping: ProfileOwner => EchoTypeID => Echo ID[] (active echoes)
    mapping(address => mapping(uint256 => uint256[])) public profileEchoesByType;
    // Mapping: Echo ID => Endorsement[]
    mapping(uint256 => Endorsement[]) public echoEndorsements;
    // Mapping: Echo ID => Address (endorser) => bool (has endorsed) - ensures unique endorsement
    mapping(uint256 => mapping(address => bool)) public hasEndorsedEcho;

    // Global delegate attestors (can attest for anyone)
    mapping(address => bool) public isDelegateAttestor;

    // Trusted Wisdom Oracles
    mapping(address => bool) public isTrustedOracle;

    // Configuration parameters
    uint256 public MIN_ECHO_STRENGTH = 10; // Minimum strength an echo must have to count towards reputation after decay
    uint256 public DECAY_TIME_UNIT = 1 days; // Time unit for decay calculation (e.g., 1 day in seconds)
    uint256 public ENDORSEMENT_STRENGTH_BOOST_PERCENT = 10; // % boost of current strength per endorsement

    // --- Events ---

    event ProfileRegistered(address indexed owner, string metadataHash);
    event ProfileMetadataUpdated(address indexed owner, string newMetadataHash);
    event ProfileAccessDelegated(address indexed owner, address indexed delegate, bool canAttest);

    event EchoTypeConfigured(uint256 indexed echoTypeId, string name, uint256 baseStrength, uint256 decayRatePermille);
    event EchoAttested(uint256 indexed echoId, uint256 indexed echoTypeId, address indexed attestor, address profileOwner, uint256 strength);
    event EchoRevoked(uint256 indexed echoId, address indexed attestor);
    event EchoEndorsed(uint256 indexed echoId, address indexed endorser, string contextHash);
    event EchoChallenged(uint256 indexed challengeId, uint256 indexed echoId, address indexed challenger, string reasonHash);
    event EchoChallengeResolved(uint256 indexed challengeId, uint256 indexed echoId, bool isValid, address resolver);
    event EchoStrengthUpdated(uint256 indexed echoId, uint256 oldStrength, uint256 newStrength, address updater);
    event EchoPrerequisitesUpdated(uint256 indexed echoTypeId, uint256[] newPrerequisiteEchoTypeIds);

    event DelegateAttestorGranted(address indexed delegate, bool granted);

    event AetherAvatarMinted(uint256 indexed tokenId, address indexed owner, string tokenURI);
    event AetherAvatarEvolved(uint256 indexed tokenId, address indexed owner, string newMetadataURI);

    event WisdomOracleSet(address indexed oracle, bool isTrusted);
    event WisdomAssessmentRequested(uint256 indexed echoId, address indexed requester, string requestContextHash);
    event WisdomAssessmentSubmitted(uint256 indexed echoId, address indexed oracle, uint256 newStrength);

    // --- Errors ---

    error NotProfileOwner(address caller, address expectedOwner);
    error ProfileAlreadyRegistered(address owner);
    error ProfileNotRegistered(address owner);
    error EchoTypeNotFound(uint256 echoTypeId);
    error PrerequisiteNotMet(uint256 requiredEchoTypeId, address profileOwner);
    error InvalidEchoId(uint256 echoId);
    error NotAttestorOfEcho(address caller, address expectedAttestor);
    error CannotEndorseOwnEcho(address endorser, uint256 echoId);
    error AlreadyEndorsed(address endorser, uint256 echoId);
    error ChallengeInProgress(uint256 echoId);
    error NoActiveChallenge(uint256 challengeId);
    error InvalidChallengeResolution(uint256 challengeId);
    error NotDelegateAttestor(address caller);
    error NotTrustedOracle(address caller);
    error AvatarAlreadyMinted(address owner);
    error NotAvatarOwner(address caller, uint256 tokenId);
    error InvalidStrength(uint256 strength);
    error RequisitesNotMet();
    error ZeroAddress();
    error EmptyString();

    constructor(string memory _name, string memory _symbol) ERC721(_name, _symbol) Ownable(msg.sender) {}

    // --- Modifiers ---

    modifier onlyRegisteredProfileOwner() {
        if (!profiles[msg.sender].isRegistered) revert ProfileNotRegistered(msg.sender);
        _;
    }

    modifier onlyDelegateAttestorOrOwner() {
        if (!isDelegateAttestor[msg.sender] && msg.sender != owner()) revert NotDelegateAttestor(msg.sender);
        _;
    }

    // --- Internal/View Helpers ---

    /**
     * @dev Calculates the decayed strength of an Echo.
     * @param _echo The Echo struct.
     * @return The current decayed strength.
     */
    function _calculateDecayedStrength(Echo storage _echo) internal view returns (uint256) {
        if (!_echo.isActive || _echo.strength == 0) return 0;

        uint256 timeSinceLastUpdate = block.timestamp - _echo.lastStrengthUpdate;
        uint256 numDecayUnits = timeSinceLastUpdate / DECAY_TIME_UNIT;

        EchoType storage echoType = echoTypes[_echo.echoTypeId];
        uint256 decayRate = echoType.decayRatePermille;

        uint256 currentStrength = _echo.strength;

        // Apply decay
        for (uint256 i = 0; i < numDecayUnits; i++) {
            currentStrength = currentStrength - (currentStrength * decayRate / 1000);
            if (currentStrength < MIN_ECHO_STRENGTH) {
                return 0; // Strength falls below minimum, effectively zero
            }
        }
        return currentStrength;
    }

    /**
     * @dev Checks if all prerequisite EchoTypes are met for a profile.
     * @param _profileOwner The owner of the profile.
     * @param _prerequisites An array of prerequisite EchoType IDs.
     * @return True if all prerequisites are met, false otherwise.
     */
    function _checkPrerequisites(address _profileOwner, uint256[] memory _prerequisites) internal view returns (bool) {
        for (uint256 i = 0; i < _prerequisites.length; i++) {
            uint256 requiredEchoTypeId = _prerequisites[i];
            if (!echoTypes[requiredEchoTypeId].exists) return false;

            uint256[] storage activeEchoes = profileEchoesByType[_profileOwner][requiredEchoTypeId];
            bool hasRequiredEcho = false;
            for (uint256 j = 0; j < activeEchoes.length; j++) {
                uint256 echoId = activeEchoes[j];
                // Check if the echo is active and its decayed strength is above minimum
                if (echoes[echoId].isActive && _calculateDecayedStrength(echoes[echoId]) >= MIN_ECHO_STRENGTH) {
                    hasRequiredEcho = true;
                    break;
                }
            }
            if (!hasRequiredEcho) return false;
        }
        return true;
    }

    // --- Profile & Identity Management ---

    /**
     * @notice Registers a new Aetherial Profile for the caller.
     * @dev A user must register a profile before they can receive Echoes or mint an AetherAvatar.
     * @param _profileMetadataHash IPFS CID pointing to the user's profile metadata (e.g., profile picture, bio).
     */
    function registerAetherialProfile(string memory _profileMetadataHash) external {
        if (profiles[msg.sender].isRegistered) revert ProfileAlreadyRegistered(msg.sender);
        if (bytes(_profileMetadataHash).length == 0) revert EmptyString();

        profiles[msg.sender] = Profile({
            owner: msg.sender,
            metadataHash: _profileMetadataHash,
            isRegistered: true,
            avatarTokenId: 0
        });

        emit ProfileRegistered(msg.sender, _profileMetadataHash);
    }

    /**
     * @notice Updates the metadata hash for the caller's profile.
     * @param _newMetadataHash New IPFS CID for updated profile metadata.
     */
    function updateProfileMetadataHash(string memory _newMetadataHash) external onlyRegisteredProfileOwner {
        if (bytes(_newMetadataHash).length == 0) revert EmptyString();
        profiles[msg.sender].metadataHash = _newMetadataHash;
        emit ProfileMetadataUpdated(msg.sender, _newMetadataHash);
    }

    /**
     * @notice Grants or revokes specific delegation rights for a profile.
     * @dev This is a placeholder for future granular delegation. For current scope, `isDelegateAttestor` is global.
     * @param _delegate The address to grant/revoke rights to.
     * @param _canAttest If true, the delegate *would* be able to attest on behalf of the profile owner for specific EchoTypes (if implemented).
     */
    function delegateProfileAccess(address _delegate, bool _canAttest) external onlyRegisteredProfileOwner {
        if (_delegate == address(0)) revert ZeroAddress();
        // Placeholder: Actual implementation would involve a separate mapping for per-profile delegation.
        // E.g., `mapping(address => mapping(address => bool)) public profileAttestationDelegates;`
        emit ProfileAccessDelegated(msg.sender, _delegate, _canAttest);
    }

    // --- Echo (Attestation) Management ---

    /**
     * @notice Configures a new EchoType, defining its properties.
     * @dev Only the contract owner can define new EchoTypes.
     * @param _name The human-readable name of the EchoType (e.g., "Solidity Expert", "Community Contributor").
     * @param _descriptionHash IPFS CID for a detailed description of what this EchoType represents.
     * @param _baseStrength The initial strength value an Echo of this type will have.
     * @param _decayRatePermille The rate at which this EchoType's strength decays (per mille per DECAY_TIME_UNIT). Max 1000 (100%).
     * @param _prerequisiteEchoTypeIds An array of EchoType IDs that must be met before this EchoType can be attested.
     */
    function configureEchoType(
        string memory _name,
        string memory _descriptionHash,
        uint256 _baseStrength,
        uint256 _decayRatePermille,
        uint256[] memory _prerequisiteEchoTypeIds
    ) external onlyOwner {
        if (bytes(_name).length == 0 || bytes(_descriptionHash).length == 0) revert EmptyString();
        if (_baseStrength == 0) revert InvalidStrength(0);
        if (_decayRatePermille > 1000) revert InvalidStrength(_decayRatePermille);

        _echoTypeIds.increment();
        uint256 newId = _echoTypeIds.current();

        echoTypes[newId] = EchoType({
            name: _name,
            descriptionHash: _descriptionHash,
            baseStrength: _baseStrength,
            decayRatePermille: _decayRatePermille,
            prerequisiteEchoTypeIds: _prerequisiteEchoTypeIds,
            exists: true
        });

        emit EchoTypeConfigured(newId, _name, _baseStrength, _decayRatePermille);
    }

    /**
     * @notice Attests an Echo for a specific profile owner.
     * @dev Only the contract owner or a designated delegate attestor can issue Echoes.
     *      Prerequisites for the EchoType must be met by the profile owner.
     * @param _profileOwner The address of the profile owner receiving the Echo.
     * @param _echoTypeId The ID of the EchoType being attested.
     * @param _contextHash IPFS CID for specific details or proof of this particular attestation.
     */
    function attestEcho(
        address _profileOwner,
        uint256 _echoTypeId,
        string memory _contextHash
    ) external onlyDelegateAttestorOrOwner {
        if (!profiles[_profileOwner].isRegistered) revert ProfileNotRegistered(_profileOwner);
        if (!echoTypes[_echoTypeId].exists) revert EchoTypeNotFound(_echoTypeId);
        if (bytes(_contextHash).length == 0) revert EmptyString();

        EchoType storage echoType = echoTypes[_echoTypeId];
        if (!_checkPrerequisites(_profileOwner, echoType.prerequisiteEchoTypeIds)) {
            revert RequisitesNotMet();
        }

        _echoIds.increment();
        uint256 newEchoId = _echoIds.current();

        echoes[newEchoId] = Echo({
            id: newEchoId,
            echoTypeId: _echoTypeId,
            attestor: msg.sender,
            profileOwner: _profileOwner,
            contextHash: _contextHash,
            strength: echoType.baseStrength,
            issuedAt: block.timestamp,
            isActive: true,
            lastStrengthUpdate: block.timestamp
        });

        profileEchoesByType[_profileOwner][_echoTypeId].push(newEchoId);

        emit EchoAttested(newEchoId, _echoTypeId, msg.sender, _profileOwner, echoType.baseStrength);
    }

    /**
     * @notice Revokes an existing Echo.
     * @dev Only the original attestor of the Echo can revoke it.
     * @param _echoId The ID of the Echo to revoke.
     */
    function revokeEcho(uint256 _echoId) external {
        Echo storage echo = echoes[_echoId];
        if (!echo.isActive) revert InvalidEchoId(_echoId);
        if (echo.attestor != msg.sender) revert NotAttestorOfEcho(msg.sender, echo.attestor);

        echo.isActive = false;
        echo.strength = 0; // Set strength to 0 upon revocation

        emit EchoRevoked(_echoId, msg.sender);
    }

    /**
     * @notice Allows a user to endorse another user's Echo.
     * @dev Endorsing boosts the Echo's effective strength. A user can only endorse an Echo once.
     * @param _echoId The ID of the Echo to endorse.
     * @param _endorsementContextHash IPFS CID for the reason/context of the endorsement.
     */
    function endorseEcho(uint256 _echoId, string memory _endorsementContextHash) external onlyRegisteredProfileOwner {
        Echo storage echo = echoes[_echoId];
        if (!echo.isActive) revert InvalidEchoId(_echoId);
        if (echo.profileOwner == msg.sender) revert CannotEndorseOwnEcho(msg.sender, _echoId);
        if (hasEndorsedEcho[_echoId][msg.sender]) revert AlreadyEndorsed(msg.sender, _echoId);
        if (bytes(_endorsementContextHash).length == 0) revert EmptyString();

        Endorsement memory newEndorsement = Endorsement({
            echoId: _echoId,
            endorser: msg.sender,
            contextHash: _endorsementContextHash,
            endorsedAt: block.timestamp,
            isActive: true
        });

        echoEndorsements[_echoId].push(newEndorsement);
        hasEndorsedEcho[_echoId][msg.sender] = true;

        uint256 oldDecayedStrength = _calculateDecayedStrength(echo);
        echo.strength = oldDecayedStrength + (oldDecayedStrength * ENDORSEMENT_STRENGTH_BOOST_PERCENT / 100);
        echo.lastStrengthUpdate = block.timestamp; // Reset decay clock to apply boost from now

        emit EchoEndorsed(_echoId, msg.sender, _endorsementContextHash);
        emit EchoStrengthUpdated(_echoId, oldDecayedStrength, echo.strength, msg.sender);
    }

    /**
     * @notice Initiates a challenge against an Echo's validity.
     * @dev Any registered profile owner can challenge an Echo.
     * @param _echoId The ID of the Echo to challenge.
     * @param _reasonHash IPFS CID for the detailed reason for the challenge.
     */
    function challengeEcho(uint256 _echoId, string memory _reasonHash) external onlyRegisteredProfileOwner {
        Echo storage echo = echoes[_echoId];
        if (!echo.isActive) revert InvalidEchoId(_echoId);
        if (bytes(_reasonHash).length == 0) revert EmptyString();

        // Check for active challenges for this echo
        for (uint256 i = 1; i <= _challengeIds.current(); i++) {
            Challenge storage c = challenges[i];
            if (c.echoId == _echoId && c.isOpen) revert ChallengeInProgress(_echoId);
        }
        
        _challengeIds.increment();
        uint256 newChallengeId = _challengeIds.current();

        challenges[newChallengeId] = Challenge({
            id: newChallengeId,
            echoId: _echoId,
            challenger: msg.sender,
            reasonHash: _reasonHash,
            challengedAt: block.timestamp,
            isOpen: true,
            isResolvedValid: false, // Default to false until resolved
            resolutionHash: ""
        });

        emit EchoChallenged(newChallengeId, _echoId, msg.sender, _reasonHash);
    }

    /**
     * @notice Resolves an open challenge for an Echo.
     * @dev Only the contract owner can resolve challenges.
     * @param _challengeId The ID of the challenge to resolve.
     * @param _isValid If true, the Echo is deemed valid; if false, it's invalidated.
     * @param _resolutionHash IPFS CID for the details of the resolution.
     */
    function resolveChallenge(uint256 _challengeId, bool _isValid, string memory _resolutionHash) external onlyOwner {
        Challenge storage challenge = challenges[_challengeId];
        if (!challenge.isOpen) revert NoActiveChallenge(_challengeId);
        if (bytes(_resolutionHash).length == 0) revert EmptyString();

        challenge.isOpen = false;
        challenge.isResolvedValid = _isValid;
        challenge.resolutionHash = _resolutionHash;

        Echo storage echo = echoes[challenge.echoId];
        if (!_isValid) {
            echo.isActive = false;
            echo.strength = 0;
            emit EchoRevoked(challenge.echoId, address(0)); // Attestor is address(0) for system revocation
        }
        // If it was temporarily suspended, reactivate (not implemented, currently only invalidate)

        emit EchoChallengeResolved(_challengeId, challenge.echoId, _isValid, msg.sender);
    }

    /**
     * @notice Allows the original attestor to update the strength of an Echo they issued.
     * @dev Can be used for dynamic adjustments based on ongoing contributions or performance.
     * @param _echoId The ID of the Echo to update.
     * @param _newStrength The new strength value for the Echo. Must be > 0.
     */
    function updateEchoStrength(uint256 _echoId, uint256 _newStrength) external {
        Echo storage echo = echoes[_echoId];
        if (!echo.isActive) revert InvalidEchoId(_echoId);
        if (echo.attestor != msg.sender) revert NotAttestorOfEcho(msg.sender, echo.attestor);
        if (_newStrength == 0) revert InvalidStrength(0);

        uint256 oldStrength = _calculateDecayedStrength(echo);
        echo.strength = _newStrength;
        echo.lastStrengthUpdate = block.timestamp; // Reset decay clock

        emit EchoStrengthUpdated(_echoId, oldStrength, _newStrength, msg.sender);
    }

    /**
     * @notice Updates the prerequisite EchoTypes for an existing EchoType.
     * @dev Only the contract owner can modify EchoType definitions.
     * @param _echoTypeId The ID of the EchoType to update.
     * @param _newPrerequisiteEchoTypeIds The new array of prerequisite EchoType IDs.
     */
    function setEchoPrerequisites(uint256 _echoTypeId, uint256[] memory _newPrerequisiteEchoTypeIds) external onlyOwner {
        if (!echoTypes[_echoTypeId].exists) revert EchoTypeNotFound(_echoTypeId);
        
        echoTypes[_echoTypeId].prerequisiteEchoTypeIds = _newPrerequisiteEchoTypeIds;
        emit EchoPrerequisitesUpdated(_echoTypeId, _newPrerequisiteEchoTypeIds);
    }

    /**
     * @notice Grants or revokes permission for an address to act as a global delegate attestor.
     * @dev Delegate attestors can issue Echoes on behalf of the protocol.
     * @param _delegate The address to grant/revoke permissions to.
     * @param _canAttest True to grant, false to revoke.
     */
    function grantDelegateAttestor(address _delegate, bool _canAttest) external onlyOwner {
        if (_delegate == address(0)) revert ZeroAddress();
        isDelegateAttestor[_delegate] = _canAttest;
        emit DelegateAttestorGranted(_delegate, _canAttest);
    }

    // --- Reputation & Scoring ---

    /**
     * @notice Calculates a user's aggregated score for a specific EchoType.
     * @dev Sums the current decayed strength of all active Echoes of that type for the user.
     * @param _profileOwner The address of the profile owner.
     * @param _echoTypeId The ID of the EchoType.
     * @return The total aggregated strength for that EchoType.
     */
    function getProfileEchoScore(address _profileOwner, uint256 _echoTypeId) public view returns (uint256) {
        if (!profiles[_profileOwner].isRegistered) return 0;
        if (!echoTypes[_echoTypeId].exists) return 0;

        uint256 totalScore = 0;
        uint256[] storage activeEchoes = profileEchoesByType[_profileOwner][_echoTypeId];

        for (uint256 i = 0; i < activeEchoes.length; i++) {
            uint256 echoId = activeEchoes[i];
            totalScore += _calculateDecayedStrength(echoes[echoId]);
        }
        return totalScore;
    }

    /**
     * @notice Calculates a user's total reputation score across all active Echoes.
     * @dev Sums the current decayed strength of all active Echoes for the user, across all types.
     * @param _profileOwner The address of the profile owner.
     * @return The overall reputation score.
     */
    function getOverallReputationScore(address _profileOwner) public view returns (uint256) {
        if (!profiles[_profileOwner].isRegistered) return 0;

        uint256 totalScore = 0;
        for (uint256 echoTypeId = 1; echoTypeId <= _echoTypeIds.current(); echoTypeId++) {
            totalScore += getProfileEchoScore(_profileOwner, echoTypeId);
        }
        return totalScore;
    }

    /**
     * @notice Returns the count of unique, active Echoes of a certain type, weighted by their strength.
     * @dev Useful for understanding the breadth and depth of a skill.
     *      Each echo contributes a fractional amount (decayed_strength / base_strength) to the count.
     * @param _profileOwner The address of the profile owner.
     * @param _echoTypeId The ID of the EchoType.
     * @return The weighted count.
     */
    function getWeightedEchoCount(address _profileOwner, uint256 _echoTypeId) public view returns (uint256) {
        if (!profiles[_profileOwner].isRegistered) return 0;
        EchoType storage echoType = echoTypes[_echoTypeId];
        if (!echoType.exists || echoType.baseStrength == 0) return 0;

        uint256 weightedCount = 0;
        uint256[] storage activeEchoes = profileEchoesByType[_profileOwner][_echoTypeId];

        for (uint256 i = 0; i < activeEchoes.length; i++) {
            uint256 echoId = activeEchoes[i];
            uint256 decayedStrength = _calculateDecayedStrength(echoes[echoId]);
            if (decayedStrength > 0) {
                // Add fractional count based on current strength relative to original base strength
                weightedCount += (decayedStrength * 1000) / echoType.baseStrength; // Use 1000x for precision
            }
        }
        return weightedCount / 1000; // Return integer part
    }

    // --- Dynamic NFT (AetherAvatar) Integration ---

    /**
     * @notice Mints an AetherAvatar NFT for the calling profile.
     * @dev Each profile can only mint one AetherAvatar. This NFT represents their on-chain persona.
     * @param _initialTokenURI Initial token URI for the NFT (can be static, as it will be dynamic later).
     */
    function mintAetherAvatar(string memory _initialTokenURI) external onlyRegisteredProfileOwner {
        if (profiles[msg.sender].avatarTokenId != 0) revert AvatarAlreadyMinted(msg.sender);
        if (bytes(_initialTokenURI).length == 0) revert EmptyString();

        _avatarTokenIds.increment();
        uint256 newTokenId = _avatarTokenIds.current();

        _safeMint(msg.sender, newTokenId);
        _setTokenURI(newTokenId, _initialTokenURI); 
        profiles[msg.sender].avatarTokenId = newTokenId;

        emit AetherAvatarMinted(newTokenId, msg.sender, _initialTokenURI);
    }

    /**
     * @notice Generates a dynamic metadata URI for an AetherAvatar based on the owner's Echoes.
     * @dev This function calculates a "state hash" from the owner's reputation and specific Echoes.
     *      An off-chain service is expected to serve different metadata/images based on this dynamic URI.
     * @param _tokenId The ID of the AetherAvatar NFT.
     * @return The dynamic metadata URI.
     */
    function getAetherAvatarDynamicMetadata(uint256 _tokenId) public view returns (string memory) {
        address avatarOwner = ownerOf(_tokenId);
        if (avatarOwner == address(0)) revert NotAvatarOwner(msg.sender, _tokenId); // msg.sender might not be owner

        // Derive a unique hash based on the owner's reputation and a selection of key EchoTypes
        // This hash will dictate the NFT's metadata/appearance off-chain.
        // For a more granular avatar, more specific EchoType scores could be included.
        bytes32 avatarStateHash = keccak256(abi.encodePacked(
            avatarOwner,
            getOverallReputationScore(avatarOwner),
            getProfileEchoScore(avatarOwner, 1), // Example: EchoType 1 score
            getProfileEchoScore(avatarOwner, 2), // Example: EchoType 2 score
            getWeightedEchoCount(avatarOwner, 1), // Example: Weighted count for EchoType 1
            block.timestamp / DECAY_TIME_UNIT // Include time unit to ensure periodic changes
        ));

        // Base URI for the metadata server (e.g., https://aetherialechoes.xyz/api/avatars/)
        string memory baseURI = "https://aetherialechoes.xyz/api/avatars/state/";
        // Concatenate base URI with the derived hash
        return string(abi.encodePacked(baseURI, Strings.toHexString(uint256(avatarStateHash))));
    }

    /**
     * @notice Triggers an explicit re-evaluation of the AetherAvatar's state, updating its tokenURI.
     * @dev This function forces the NFT to update its metadata to reflect the current reputation.
     * @param _tokenId The ID of the AetherAvatar NFT.
     */
    function evolveAetherAvatar(uint256 _tokenId) external onlyRegisteredProfileOwner {
        if (profiles[msg.sender].avatarTokenId != _tokenId) revert NotAvatarOwner(msg.sender, _tokenId);

        string memory newURI = getAetherAvatarDynamicMetadata(_tokenId);
        _setTokenURI(_tokenId, newURI); // Updates the tokenURI, triggering metadata refresh on marketplaces

        emit AetherAvatarEvolved(_tokenId, msg.sender, newURI);
    }

    // --- Wisdom Oracle (Simulated Expert System) ---

    /**
     * @notice Manages trusted addresses for the Wisdom Oracle.
     * @dev Only the contract owner can set or unset trusted oracles.
     * @param _oracle The address of the oracle.
     * @param _isTrusted True to trust, false to untrust.
     */
    function setWisdomOracle(address _oracle, bool _isTrusted) external onlyOwner {
        if (_oracle == address(0)) revert ZeroAddress();
        isTrustedOracle[_oracle] = _isTrusted;
        emit WisdomOracleSet(_oracle, _isTrusted);
    }

    /**
     * @notice Requests a trusted oracle to assess a specific Echo.
     * @dev This can be used for high-value Echoes that require subjective expert validation.
     * @param _echoId The ID of the Echo to be assessed.
     * @param _requestContextHash IPFS CID for details of the assessment request.
     */
    function requestWisdomAssessment(uint256 _echoId, string memory _requestContextHash) external onlyRegisteredProfileOwner {
        Echo storage echo = echoes[_echoId];
        if (!echo.isActive) revert InvalidEchoId(_echoId);
        if (echo.profileOwner != msg.sender) revert NotEchoOwner(msg.sender, echo.profileOwner);
        if (bytes(_requestContextHash).length == 0) revert EmptyString();

        // Potentially, mark echo as 'under assessment' to prevent other actions
        // For simplicity, we just emit an event here.
        emit WisdomAssessmentRequested(_echoId, msg.sender, _requestContextHash);
    }

    /**
     * @notice Allows a trusted oracle to submit an assessment for an Echo, potentially adjusting its strength.
     * @dev This function empowers trusted experts to validate or invalidate Echoes based on off-chain analysis.
     * @param _echoId The ID of the Echo that was assessed.
     * @param _assessmentHash IPFS CID for the detailed assessment report.
     * @param _newStrength The new strength value proposed by the oracle. Can be 0 to invalidate.
     */
    function submitWisdomAssessment(uint256 _echoId, string memory _assessmentHash, uint256 _newStrength) external {
        if (!isTrustedOracle[msg.sender]) revert NotTrustedOracle(msg.sender);
        if (bytes(_assessmentHash).length == 0) revert EmptyString();

        Echo storage echo = echoes[_echoId];
        if (!echo.isActive) revert InvalidEchoId(_echoId);

        uint256 oldStrength = _calculateDecayedStrength(echo);
        echo.strength = _newStrength;
        echo.lastStrengthUpdate = block.timestamp;
        echo.isActive = (_newStrength > 0); // Invalidate if strength is 0

        emit WisdomAssessmentSubmitted(_echoId, msg.sender, _newStrength);
        emit EchoStrengthUpdated(_echoId, oldStrength, _newStrength, msg.sender);
        if (!echo.isActive) emit EchoRevoked(_echoId, msg.sender);
    }

    // --- Overrides for ERC721 ---

    function _baseURI() internal view override returns (string memory) {
        // This is the base for _tokenURI if not explicitly set per token.
        // For dynamic NFTs, the tokenURI will be updated by getAetherAvatarDynamicMetadata.
        return "ipfs://aetherial.echoes/avatars/metadata/default/";
    }
}
```