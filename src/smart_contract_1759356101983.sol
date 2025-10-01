The contract described below, **Aethelgard: The Adaptive Trust Nexus**, introduces an advanced system for decentralized, dynamic, and multi-faceted reputation management using non-transferable "Nexus Profiles" (akin to Soulbound Tokens). It integrates conditional attestation issuance, time-decaying reputation scores across configurable domains, a robust policy engine for conditional access, and external oracle integration for verifiable claims.

The core idea is to build a rich, evolving on-chain identity that reflects a participant's history, skills, and contributions within a decentralized ecosystem, enabling nuanced trust mechanisms and access control.

---

## Aethelgard: The Adaptive Trust Nexus - Contract Outline & Function Summary

### **I. Core Concepts**

*   **Nexus Profiles (Soulbound Identity):** Non-transferable ERC-721 like tokens representing unique on-chain identities. These profiles accumulate attestations and reputation.
*   **Multi-Dimensional Attestations:** Verifiable claims or endorsements issued by other addresses or entities to a Nexus Profile, categorized by type, subject, and value.
*   **Dynamic Reputation Domains:** Configurable reputation categories (e.g., "Technical Skill", "Integrity", "Collaboration") each with its own weight and time-based decay rate.
*   **Conditional Attestations:** Attestation types can require prior specific attestations on the profile or external oracle validation before they are considered valid.
*   **Adaptive Trust Scoring:** An aggregated, weighted reputation score calculated from various domains, which can be used for dynamic decision-making.
*   **Policy Engine:** A mechanism to define complex access rules or conditions based on a profile's attestations and reputation scores.
*   **Oracle Integration:** Leverages external oracles (e.g., Chainlink) to validate attestations or fetch real-world data impacting reputation.
*   **Scheduled Decay:** Reputation scores are designed to decay over time, requiring periodic re-evaluation or new attestations to maintain influence.

---

### **II. Contract Outline**

1.  **Configuration & State Variables:** Global parameters, IDs, mappings for profiles, attestations, domains, and policies.
2.  **Access Control & Pausability:** Admin roles, emergency pause.
3.  **Nexus Profile Management:** Creation, metadata updates, basic retrieval for non-transferable profiles.
4.  **Attestation Engine:** Definition of attestation types, issuance, revocation, and detailed retrieval.
5.  **Reputation Domain & Scoring:** Configuration of domains, calculation of domain-specific and aggregated reputation, and scheduled decay logic.
6.  **Policy Engine:** Definition of complex access policies and evaluation of a profile against these policies.
7.  **Oracle Integration:** Functions for requesting and fulfilling external validation of attestations.
8.  **System Parameters & Governance:** Admin functions to update system-wide configurations.

---

### **III. Function Summary (23 Functions)**

**A. Core Nexus Profile Management (SBT-like functionality)**

1.  `createNexusProfile(address _owner, string calldata _initialMetadataURI)`: Mints a new non-transferable Nexus Profile (SBT) for a specified owner with initial metadata.
2.  `updateProfileMetadata(uint256 _profileId, string calldata _newMetadataURI)`: Allows the profile owner to update the metadata URI associated with their Nexus Profile.
3.  `getNexusProfileDetails(uint256 _profileId)`: Retrieves comprehensive details for a given Nexus Profile ID, including owner, creation time, and metadata URI.
4.  `getProfileOwner(uint256 _profileId)`: Returns the current owner address of a specified Nexus Profile.

**B. Multi-Dimensional Attestation Engine**

5.  `defineAttestationType(bytes32 _attestationType, string calldata _name, string calldata _description, bool _requiresOracleValidation, bytes32[] calldata _requiredPriorAttestationTypes)`: Admin function to define a new type of attestation, specifying its properties, including if it needs oracle validation and any prerequisite attestation types.
6.  `issueAttestation(uint256 _profileId, bytes32 _attestationType, bytes32 _subjectIdentifier, int256 _value, string calldata _proofURI)`: Allows an authorized issuer to issue a new attestation to a target Nexus Profile.
7.  `revokeAttestation(uint256 _attestationId)`: Enables the original issuer to revoke a previously issued attestation.
8.  `getAttestationDetails(uint256 _attestationId)`: Retrieves all details of a specific attestation by its ID.
9.  `getProfileAttestations(uint256 _profileId, bytes32 _attestationType)`: Returns a list of all attestation IDs of a specific type issued to a given Nexus Profile.
10. `verifyAttestationValidity(uint256 _attestationId)`: Checks and returns whether an attestation is currently valid (not revoked, not disputed, and oracle validated if required).

**C. Dynamic Reputation & Trust Scoring**

11. `configureReputationDomain(bytes32 _domainId, string calldata _name, uint256 _initialWeightBasisPoints, uint256 _decayRatePerPeriodBasisPoints, uint256 _decayPeriodSeconds)`: Admin function to define or update a reputation domain, setting its name, impact weight, decay rate, and decay period.
12. `updateReputationDomainWeight(bytes32 _domainId, uint256 _newWeightBasisPoints)`: Admin function to adjust the impact weight of an existing reputation domain in the aggregated trust score calculation.
13. `calculateProfileReputationScore(uint256 _profileId, bytes32 _domainId)`: Calculates the current, decayed reputation score for a specific profile within a designated domain.
14. `getProfileAggregatedTrustScore(uint256 _profileId)`: Calculates a single, aggregated dynamic trust score for a profile based on all its reputation domains and their weights.
15. `processScheduledDecay(uint256 _profileId)`: A public function intended to be called by a decentralized scheduler (e.g., Chainlink Keepers) to apply time-based decay to a profile's reputation scores.

**D. Conditional Access & Policy Engine**

16. `defineAccessPolicy(bytes32 _policyId, string calldata _name, AccessCondition[] calldata _conditions)`: Admin function to define a new access policy, consisting of one or more conditions based on reputation scores or specific attestations.
17. `checkProfileAccess(uint256 _profileId, bytes32 _policyId)`: Evaluates if a given Nexus Profile meets all the conditions of a specified access policy, returning a boolean result.
18. `getPolicyDetails(bytes32 _policyId)`: Retrieves the definition and conditions of a specified access policy.

**E. Oracle Integration (e.g., Chainlink)**

19. `requestAttestationOracleValidation(uint256 _attestationId, bytes calldata _oracleJobData)`: Initiates an external oracle request for validation of an attestation that was marked as requiring oracle verification.
20. `fulfillOracleValidation(bytes32 _requestId, bool _isValid, string calldata _oracleMessage)`: The callback function invoked by the Chainlink oracle to report the result of an attestation validation request.

**F. Governance & System Hooks**

21. `setAdmin(address _newAdmin)`: Allows the current admin to transfer administrative privileges to a new address.
22. `pauseSystem()`: Admin function to pause core functionalities of the contract during emergencies or maintenance.
23. `updateSystemParameter(bytes32 _paramKey, uint256 _newValue)`: Admin function to update generic system-wide parameters (e.g., dispute fees, attestation cooldowns, min/max values).

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol"; // For safety, though transfers are disabled.
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol"; // Using VRF as an example for oracle, could be Chainlink Price Feeds or any other.
import "@chainlink/contracts/src/v0.8/interfaces/KeeperCompatibleInterface.sol"; // For scheduled functions.
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol"; // For general oracle price feeds, if needed
import "@chainlink/contracts/src/v0.8/KeeperCompatible.sol"; // Base for Keeper callbacks

// Aethelgard: The Adaptive Trust Nexus
//
// This contract implements a novel decentralized reputation and skill attestation
// network using non-transferable "Nexus Profiles" (Soulbound Tokens).
// It features multi-dimensional, time-decaying reputation scores, conditional
// attestation issuance, a policy engine for access control, and oracle integration.

contract Aethelgard is ERC721, Ownable, Pausable, KeeperCompatibleInterface {
    // --- 0. State Variables & Configuration ---

    // Nexus Profile (SBT-like)
    struct NexusProfile {
        address owner;
        uint256 creationTimestamp;
        string metadataURI;
        uint256 lastDecayTimestamp; // Timestamp when decay was last processed
    }
    uint256 private _nextProfileId;
    mapping(uint256 => NexusProfile) public nexusProfiles;
    mapping(address => uint256) public addressToProfileId; // Allows lookup by address (one profile per address)

    // Attestations
    enum AttestationStatus { PendingOracle, Valid, Revoked, Disputed }
    struct Attestation {
        uint256 id;
        uint256 profileId;
        address issuer;
        bytes32 attestationType;
        bytes32 subjectIdentifier; // Unique identifier for what is being attested (e.g., a project ID, a skill hash)
        int256 value; // Numeric value of the attestation (can be positive or negative)
        string proofURI; // URI to off-chain proof (e.g., IPFS hash of a document)
        uint256 issueTimestamp;
        uint256 lastUpdateTimestamp; // For oracle updates
        AttestationStatus status;
        bool requiresOracleValidation;
        bytes32 oracleRequestId; // Link to the oracle request if applicable
    }
    uint256 private _nextAttestationId;
    mapping(uint256 => Attestation) public attestations;
    mapping(uint256 => mapping(bytes32 => uint256[])) public profileAttestationsByType; // profileId => attestationType => list of attestation IDs

    struct AttestationTypeConfig {
        string name;
        string description;
        bool requiresOracleValidation;
        bytes32[] requiredPriorAttestationTypes; // Attestations required to be present on profile before this type can be issued
        mapping(address => bool) authorizedIssuers; // If true, only these addresses can issue this type (default: anyone can issue if empty)
    }
    mapping(bytes32 => AttestationTypeConfig) public attestationTypeConfigs; // attestationType => config

    // Reputation Domains
    struct ReputationDomain {
        string name;
        uint256 initialWeightBasisPoints; // e.g., 10000 for 100%, 5000 for 50%
        uint256 decayRatePerPeriodBasisPoints; // % of score to decay per period (e.g., 100 = 1%)
        uint256 decayPeriodSeconds; // How often the decay applies
    }
    mapping(bytes32 => ReputationDomain) public reputationDomains;
    mapping(uint256 => mapping(bytes32 => int256)) public profileReputationScores; // profileId => domainId => current score
    mapping(uint256 => mapping(bytes32 => uint256)) public profileReputationLastUpdate; // profileId => domainId => last timestamp score was updated (attestation or decay)
    bytes32[] public allReputationDomainIds; // List of all defined domain IDs for iteration

    // Policy Engine for Conditional Access
    enum ConditionType { HasAttestation, MinReputationInDomain, MaxReputationInDomain }
    struct AccessCondition {
        ConditionType conditionType;
        bytes32 param1; // AttestationType for HasAttestation, ReputationDomain for Min/MaxReputationInDomain
        int256 param2;  // Not used for HasAttestation, MinValue for MinReputation, MaxValue for MaxReputation
    }
    struct AccessPolicy {
        string name;
        AccessCondition[] conditions;
    }
    mapping(bytes32 => AccessPolicy) public accessPolicies;

    // Generic System Parameters (Admin configurable)
    mapping(bytes32 => uint256) public systemParameters;

    // Oracle Integration (Chainlink specific for this example)
    address public immutable i_link; // LINK token address
    address public immutable i_oracle; // Chainlink Oracle address (for data feeds / general requests)
    bytes32 public immutable i_jobId; // Chainlink Job ID for attestation validation
    uint256 public immutable i_fee; // LINK fee for oracle requests

    // --- Events ---
    event NexusProfileCreated(uint256 indexed profileId, address indexed owner, string metadataURI);
    event ProfileMetadataUpdated(uint256 indexed profileId, string oldMetadataURI, string newMetadataURI);
    event AttestationTypeDefined(bytes32 indexed attestationType, string name, bool requiresOracleValidation);
    event AttestationIssued(uint256 indexed attestationId, uint256 indexed profileId, address indexed issuer, bytes32 attestationType, int256 value);
    event AttestationRevoked(uint256 indexed attestationId, address indexed revoker);
    event AttestationStatusUpdated(uint256 indexed attestationId, AttestationStatus oldStatus, AttestationStatus newStatus, bytes32 oracleRequestId);
    event ReputationDomainConfigured(bytes32 indexed domainId, string name, uint256 weight, uint256 decayRate, uint256 decayPeriod);
    event ReputationDomainWeightUpdated(bytes32 indexed domainId, uint256 oldWeight, uint256 newWeight);
    event ProfileReputationDecayed(uint256 indexed profileId, bytes32 indexed domainId, int256 oldScore, int256 newScore);
    event AccessPolicyDefined(bytes32 indexed policyId, string name);
    event AccessCheckResult(uint256 indexed profileId, bytes32 indexed policyId, bool granted);
    event OracleValidationRequested(uint256 indexed attestationId, bytes32 oracleRequestId);
    event OracleValidationFulfilled(bytes32 indexed oracleRequestId, uint256 indexed attestationId, bool isValid, string message);
    event SystemParameterUpdated(bytes32 indexed paramKey, uint256 oldValue, uint256 newValue);


    // --- 1. Constructor ---

    constructor(
        address _link,
        address _oracle,
        bytes32 _jobId,
        uint256 _fee
    )
        ERC721("Aethelgard Nexus Profile", "AETHNEX")
        Ownable(msg.sender)
        Pausable()
    {
        i_link = _link;
        i_oracle = _oracle;
        i_jobId = _jobId;
        i_fee = _fee;

        _nextProfileId = 1; // Start profile IDs from 1
        _nextAttestationId = 1; // Start attestation IDs from 1

        // Initialize some default system parameters
        systemParameters["MinAttestationValue"] = 0;
        systemParameters["MaxAttestationValue"] = 10000;
        systemParameters["DefaultProfileReputationDecayPeriod"] = 7 days; // For general profile decay check
        systemParameters["AttestationOracleValidationGasLimit"] = 200000;
    }

    // --- 2. Access Control & Pausability ---

    modifier onlyAdmin() {
        require(owner() == _msgSender(), "Aethelgard: Caller is not the admin");
        _;
    }

    // This contract itself is not transferrable, but it extends ERC721
    // to leverage its ID management and metadata.
    // Overriding transfer functions to make tokens non-transferable (Soulbound).
    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize) internal pure override {
        if (from != address(0) && to != address(0)) {
            revert("Aethelgard: Nexus Profiles are non-transferable (Soulbound)");
        }
    }

    function transferFrom(address from, address to, uint256 tokenId) public pure override {
        revert("Aethelgard: Nexus Profiles are non-transferable (Soulbound)");
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public pure override {
        revert("Aethelgard: Nexus Profiles are non-transferable (Soulbound)");
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public pure override {
        revert("Aethelgard: Nexus Profiles are non-transferable (Soulbound)");
    }


    // --- 3. Core Nexus Profile Management (SBT-like functionality) ---

    /// @notice Mints a new non-transferable Nexus Profile (SBT) for a specified owner with initial metadata.
    /// @param _owner The address to whom the Nexus Profile will be minted.
    /// @param _initialMetadataURI IPFS or other URI pointing to the profile's initial metadata.
    /// @return The ID of the newly created Nexus Profile.
    function createNexusProfile(address _owner, string calldata _initialMetadataURI)
        external
        whenNotPaused
        returns (uint256)
    {
        require(addressToProfileId[_owner] == 0, "Aethelgard: Address already has a Nexus Profile");

        uint256 newProfileId = _nextProfileId++;
        _safeMint(_owner, newProfileId); // Use ERC721's _safeMint to assign token ID

        NexusProfile storage newProfile = nexusProfiles[newProfileId];
        newProfile.owner = _owner;
        newProfile.creationTimestamp = block.timestamp;
        newProfile.metadataURI = _initialMetadataURI;
        newProfile.lastDecayTimestamp = block.timestamp; // Initialize last decay timestamp

        addressToProfileId[_owner] = newProfileId;

        emit NexusProfileCreated(newProfileId, _owner, _initialMetadataURI);
        return newProfileId;
    }

    /// @notice Allows the profile owner to update the metadata URI associated with their Nexus Profile.
    /// @param _profileId The ID of the Nexus Profile to update.
    /// @param _newMetadataURI The new IPFS or other URI for the profile's metadata.
    function updateProfileMetadata(uint256 _profileId, string calldata _newMetadataURI)
        external
        whenNotPaused
    {
        require(_exists(_profileId), "Aethelgard: Profile does not exist");
        require(ownerOf(_profileId) == _msgSender(), "Aethelgard: Not profile owner");

        string memory oldMetadataURI = nexusProfiles[_profileId].metadataURI;
        nexusProfiles[_profileId].metadataURI = _newMetadataURI;

        emit ProfileMetadataUpdated(_profileId, oldMetadataURI, _newMetadataURI);
    }

    /// @notice Retrieves comprehensive details for a given Nexus Profile ID.
    /// @param _profileId The ID of the Nexus Profile.
    /// @return profile Owner address, creation timestamp, metadata URI, and last decay timestamp.
    function getNexusProfileDetails(uint256 _profileId)
        external
        view
        returns (address owner, uint256 creationTimestamp, string memory metadataURI, uint256 lastDecayTimestamp)
    {
        require(_exists(_profileId), "Aethelgard: Profile does not exist");
        NexusProfile storage profile = nexusProfiles[_profileId];
        return (profile.owner, profile.creationTimestamp, profile.metadataURI, profile.lastDecayTimestamp);
    }

    /// @notice Returns the current owner address of a specified Nexus Profile.
    /// @param _profileId The ID of the Nexus Profile.
    /// @return The owner's address.
    function getProfileOwner(uint256 _profileId)
        public
        view
        returns (address)
    {
        return ownerOf(_profileId); // Leverages ERC721's ownerOf
    }


    // --- 4. Multi-Dimensional Attestation Engine ---

    /// @notice Admin function to define a new type of attestation, specifying its properties.
    /// @param _attestationType A unique identifier for the attestation type (e.g., keccak256("SKILL_WEB3_DEV")).
    /// @param _name A human-readable name for the attestation type.
    /// @param _description A detailed description of what this attestation represents.
    /// @param _requiresOracleValidation True if this attestation type must be validated by an external oracle.
    /// @param _requiredPriorAttestationTypes An array of attestation types that must already be present on a profile for this type to be issued.
    function defineAttestationType(
        bytes32 _attestationType,
        string calldata _name,
        string calldata _description,
        bool _requiresOracleValidation,
        bytes32[] calldata _requiredPriorAttestationTypes
    )
        external
        onlyOwner
        whenNotPaused
    {
        require(attestationTypeConfigs[_attestationType].name == "", "Aethelgard: Attestation type already defined");
        AttestationTypeConfig storage config = attestationTypeConfigs[_attestationType];
        config.name = _name;
        config.description = _description;
        config.requiresOracleValidation = _requiresOracleValidation;
        config.requiredPriorAttestationTypes = _requiredPriorAttestationTypes;

        emit AttestationTypeDefined(_attestationType, _name, _requiresOracleValidation);
    }

    /// @notice Allows an authorized issuer to issue a new attestation to a target Nexus Profile.
    /// @param _profileId The ID of the target Nexus Profile.
    /// @param _attestationType The type of attestation being issued.
    /// @param _subjectIdentifier A unique identifier for the specific subject of this attestation (e.g., a project hash).
    /// @param _value A numeric value associated with the attestation (can be negative).
    /// @param _proofURI IPFS or other URI pointing to off-chain proof of the attestation.
    /// @return The ID of the newly issued attestation.
    function issueAttestation(
        uint256 _profileId,
        bytes32 _attestationType,
        bytes32 _subjectIdentifier,
        int256 _value,
        string calldata _proofURI
    )
        external
        whenNotPaused
        returns (uint256)
    {
        require(_exists(_profileId), "Aethelgard: Target profile does not exist");
        require(attestationTypeConfigs[_attestationType].name != "", "Aethelgard: Attestation type not defined");
        require(_value >= int256(systemParameters["MinAttestationValue"]) && _value <= int256(systemParameters["MaxAttestationValue"]), "Aethelgard: Attestation value out of bounds");

        AttestationTypeConfig storage typeConfig = attestationTypeConfigs[_attestationType];

        // Check required prior attestations
        for (uint256 i = 0; i < typeConfig.requiredPriorAttestationTypes.length; i++) {
            bytes32 requiredType = typeConfig.requiredPriorAttestationTypes[i];
            require(profileAttestationsByType[_profileId][requiredType].length > 0, "Aethelgard: Missing required prior attestation");
            bool foundValid = false;
            for (uint256 j = 0; j < profileAttestationsByType[_profileId][requiredType].length; j++) {
                if (verifyAttestationValidity(profileAttestationsByType[_profileId][requiredType][j])) {
                    foundValid = true;
                    break;
                }
            }
            require(foundValid, "Aethelgard: No valid prior attestation of required type found");
        }

        uint256 newAttestationId = _nextAttestationId++;
        Attestation storage newAttestation = attestations[newAttestationId];

        newAttestation.id = newAttestationId;
        newAttestation.profileId = _profileId;
        newAttestation.issuer = _msgSender();
        newAttestation.attestationType = _attestationType;
        newAttestation.subjectIdentifier = _subjectIdentifier;
        newAttestation.value = _value;
        newAttestation.proofURI = _proofURI;
        newAttestation.issueTimestamp = block.timestamp;
        newAttestation.lastUpdateTimestamp = block.timestamp;
        newAttestation.requiresOracleValidation = typeConfig.requiresOracleValidation;
        newAttestation.status = typeConfig.requiresOracleValidation ? AttestationStatus.PendingOracle : AttestationStatus.Valid;

        profileAttestationsByType[_profileId][_attestationType].push(newAttestationId);

        // Update reputation scores immediately (or queue for processing)
        _updateReputationForAttestation(_profileId, _attestationType, _value);

        emit AttestationIssued(newAttestationId, _profileId, _msgSender(), _attestationType, _value);
        return newAttestationId;
    }

    /// @notice Allows the original issuer to revoke a previously issued attestation.
    /// @param _attestationId The ID of the attestation to revoke.
    function revokeAttestation(uint256 _attestationId)
        external
        whenNotPaused
    {
        Attestation storage att = attestations[_attestationId];
        require(att.id == _attestationId, "Aethelgard: Attestation does not exist");
        require(att.issuer == _msgSender(), "Aethelgard: Not the issuer of this attestation");
        require(att.status != AttestationStatus.Revoked, "Aethelgard: Attestation already revoked");

        att.status = AttestationStatus.Revoked;
        att.lastUpdateTimestamp = block.timestamp;

        // Optionally, impact reputation negatively or revert positive impact
        // For simplicity, we just mark as revoked, actual reputation score recalculation happens on decay or explicit recalculation.
        // A more complex system might trigger an immediate reputation update.

        emit AttestationRevoked(_attestationId, _msgSender());
    }

    /// @notice Retrieves all details of a specific attestation by its ID.
    /// @param _attestationId The ID of the attestation.
    /// @return All fields of the Attestation struct.
    function getAttestationDetails(uint256 _attestationId)
        public
        view
        returns (Attestation memory)
    {
        return attestations[_attestationId];
    }

    /// @notice Returns a list of all attestation IDs of a specific type issued to a given Nexus Profile.
    /// @param _profileId The ID of the Nexus Profile.
    /// @param _attestationType The type of attestation.
    /// @return An array of attestation IDs.
    function getProfileAttestations(uint256 _profileId, bytes32 _attestationType)
        external
        view
        returns (uint256[] memory)
    {
        return profileAttestationsByType[_profileId][_attestationType];
    }

    /// @notice Checks and returns whether an attestation is currently valid.
    /// @param _attestationId The ID of the attestation.
    /// @return True if the attestation is valid, false otherwise.
    function verifyAttestationValidity(uint256 _attestationId)
        public
        view
        returns (bool)
    {
        Attestation storage att = attestations[_attestationId];
        if (att.id == 0) return false; // Attestation does not exist
        return att.status == AttestationStatus.Valid;
    }

    // Internal helper to update reputation based on a new attestation
    function _updateReputationForAttestation(uint256 _profileId, bytes32 _attestationType, int256 _value) internal {
        // This is a simplified example. A real system might have complex logic
        // mapping attestation types to specific reputation domains.
        // For now, let's assume all attestations contribute to a general 'Activity' domain,
        // or we define explicit mappings.

        // For this example, let's say all attestation types can potentially affect reputation.
        // We iterate through all defined reputation domains and update them based on rules.
        for (uint256 i = 0; i < allReputationDomainIds.length; i++) {
            bytes32 domainId = allReputationDomainIds[i];
            // Simple rule: if attestation value is positive, boost score. If negative, reduce.
            // A more complex rule would map specific attestation types to specific domains.
            int256 currentScore = calculateProfileReputationScore(_profileId, domainId); // Calculate current decayed score first
            profileReputationScores[_profileId][domainId] = currentScore + _value; // Add raw value
            profileReputationLastUpdate[_profileId][domainId] = block.timestamp;
            // Emit an event if needed
        }
    }


    // --- 5. Dynamic Reputation & Trust Scoring ---

    /// @notice Admin function to define or update a reputation domain, setting its properties.
    /// @param _domainId A unique identifier for the reputation domain (e.g., keccak256("DOMAIN_TECHNICAL")).
    /// @param _name A human-readable name for the domain.
    /// @param _initialWeightBasisPoints The initial impact weight of this domain in the aggregated trust score (0-10000).
    /// @param _decayRatePerPeriodBasisPoints The percentage of score to decay per period (0-10000, e.g., 100 = 1%).
    /// @param _decayPeriodSeconds The duration of one decay period in seconds.
    function configureReputationDomain(
        bytes32 _domainId,
        string calldata _name,
        uint256 _initialWeightBasisPoints,
        uint256 _decayRatePerPeriodBasisPoints,
        uint256 _decayPeriodSeconds
    )
        external
        onlyOwner
        whenNotPaused
    {
        require(_initialWeightBasisPoints <= 10000, "Aethelgard: Weight cannot exceed 100%");
        require(_decayRatePerPeriodBasisPoints <= 10000, "Aethelgard: Decay rate cannot exceed 100%");
        require(_decayPeriodSeconds > 0, "Aethelgard: Decay period must be positive");

        bool isNewDomain = reputationDomains[_domainId].name == "";
        reputationDomains[_domainId] = ReputationDomain({
            name: _name,
            initialWeightBasisPoints: _initialWeightBasisPoints,
            decayRatePerPeriodBasisPoints: _decayRatePerPeriodBasisPoints,
            decayPeriodSeconds: _decayPeriodSeconds
        });

        if (isNewDomain) {
            allReputationDomainIds.push(_domainId);
        }

        emit ReputationDomainConfigured(_domainId, _name, _initialWeightBasisPoints, _decayRatePerPeriodBasisPoints, _decayPeriodSeconds);
    }

    /// @notice Admin function to adjust the impact weight of an existing reputation domain.
    /// @param _domainId The ID of the reputation domain.
    /// @param _newWeightBasisPoints The new impact weight in basis points (0-10000).
    function updateReputationDomainWeight(bytes32 _domainId, uint256 _newWeightBasisPoints)
        external
        onlyOwner
        whenNotPaused
    {
        require(reputationDomains[_domainId].name != "", "Aethelgard: Reputation domain not defined");
        require(_newWeightBasisPoints <= 10000, "Aethelgard: Weight cannot exceed 100%");

        uint256 oldWeight = reputationDomains[_domainId].initialWeightBasisPoints;
        reputationDomains[_domainId].initialWeightBasisPoints = _newWeightBasisPoints;

        emit ReputationDomainWeightUpdated(_domainId, oldWeight, _newWeightBasisPoints);
    }

    /// @notice Calculates the current, decayed reputation score for a specific profile within a designated domain.
    /// @param _profileId The ID of the Nexus Profile.
    /// @param _domainId The ID of the reputation domain.
    /// @return The current reputation score for the profile in that domain.
    function calculateProfileReputationScore(uint256 _profileId, bytes32 _domainId)
        public
        view
        returns (int256)
    {
        require(_exists(_profileId), "Aethelgard: Profile does not exist");
        require(reputationDomains[_domainId].name != "", "Aethelgard: Reputation domain not defined");

        ReputationDomain storage domain = reputationDomains[_domainId];
        int256 rawScore = profileReputationScores[_profileId][_domainId];
        uint256 lastUpdate = profileReputationLastUpdate[_profileId][_domainId];

        if (rawScore == 0 || domain.decayRatePerPeriodBasisPoints == 0 || lastUpdate == 0) {
            return rawScore; // No score or no decay configured
        }

        uint256 periods = (block.timestamp - lastUpdate) / domain.decayPeriodSeconds;
        if (periods == 0) {
            return rawScore; // No decay period has passed
        }

        int256 currentScore = rawScore;
        for (uint256 i = 0; i < periods; i++) {
            currentScore = currentScore - (currentScore * int256(domain.decayRatePerPeriodBasisPoints) / 10000);
        }
        return currentScore;
    }

    /// @notice Calculates a single, aggregated dynamic trust score for a profile based on all its reputation domains and their weights.
    /// @param _profileId The ID of the Nexus Profile.
    /// @return The aggregated dynamic trust score.
    function getProfileAggregatedTrustScore(uint256 _profileId)
        public
        view
        returns (uint256)
    {
        require(_exists(_profileId), "Aethelgard: Profile does not exist");

        uint256 totalWeightedScore = 0;
        uint256 totalWeight = 0;

        for (uint256 i = 0; i < allReputationDomainIds.length; i++) {
            bytes32 domainId = allReputationDomainIds[i];
            ReputationDomain storage domain = reputationDomains[domainId];

            if (domain.initialWeightBasisPoints > 0) {
                int256 domainScore = calculateProfileReputationScore(_profileId, domainId);
                // Ensure positive score contribution for aggregation
                if (domainScore < 0) domainScore = 0;
                totalWeightedScore += uint256(domainScore) * domain.initialWeightBasisPoints;
                totalWeight += domain.initialWeightBasisPoints;
            }
        }

        if (totalWeight == 0) {
            return 0;
        }
        return totalWeightedScore / totalWeight; // Average weighted score
    }

    /// @notice A public function intended to be called by a decentralized scheduler (e.g., Chainlink Keepers)
    ///         to apply time-based decay to a profile's reputation scores.
    /// @param _profileId The ID of the Nexus Profile to decay.
    function processScheduledDecay(uint256 _profileId)
        external
        whenNotPaused
    {
        require(_exists(_profileId), "Aethelgard: Profile does not exist");
        
        // This function is meant to be called externally, likely by a Keeper.
        // It processes the decay for ALL domains for a given profile.
        NexusProfile storage profile = nexusProfiles[_profileId];
        uint256 currentTime = block.timestamp;
        
        // Update the global last decay timestamp for the profile.
        // This helps manage how often the profile is eligible for decay checks.
        // A more granular approach would be to track decay per domain.
        // For this example, we'll iterate through domains and update.

        for (uint256 i = 0; i < allReputationDomainIds.length; i++) {
            bytes32 domainId = allReputationDomainIds[i];
            ReputationDomain storage domain = reputationDomains[domainId];
            uint256 lastUpdate = profileReputationLastUpdate[_profileId][domainId];

            if (domain.decayRatePerPeriodBasisPoints > 0 && lastUpdate > 0) {
                uint256 periods = (currentTime - lastUpdate) / domain.decayPeriodSeconds;
                if (periods > 0) {
                    int256 oldScore = profileReputationScores[_profileId][domainId];
                    int256 newScore = calculateProfileReputationScore(_profileId, domainId); // Re-calculate based on current time
                    profileReputationScores[_profileId][domainId] = newScore;
                    profileReputationLastUpdate[_profileId][domainId] = currentTime; // Update last update time for this domain
                    emit ProfileReputationDecayed(_profileId, domainId, oldScore, newScore);
                }
            }
        }
        profile.lastDecayTimestamp = currentTime; // Update general profile decay timestamp
    }

    // Chainlink Keeper checkUpkeep interface
    function checkUpkeep(bytes calldata checkData)
        external
        view
        returns (bool upkeepNeeded, bytes memory performData)
    {
        // `checkData` could encode the profileId to check
        uint256 profileIdToCheck = abi.decode(checkData, (uint256));
        require(_exists(profileIdToCheck), "Aethelgard: Keeper check for non-existent profile");

        NexusProfile storage profile = nexusProfiles[profileIdToCheck];
        uint256 defaultDecayPeriod = systemParameters["DefaultProfileReputationDecayPeriod"];

        // Check if enough time has passed since last decay
        upkeepNeeded = (block.timestamp - profile.lastDecayTimestamp) >= defaultDecayPeriod;

        if (upkeepNeeded) {
            performData = abi.encode(profileIdToCheck);
        }
    }

    // Chainlink Keeper performUpkeep interface
    function performUpkeep(bytes calldata performData)
        external
        override
        whenNotPaused
    {
        uint256 profileIdToPerform = abi.decode(performData, (uint256));
        // Ensure this call originates from a Keeper or trusted source (if needed, enforce this check)
        // For simplicity here, we assume if checkUpkeep passed, performUpkeep is valid.

        processScheduledDecay(profileIdToPerform);
    }


    // --- 6. Conditional Access & Policy Engine ---

    /// @notice Admin function to define a new access policy, consisting of one or more conditions.
    /// @param _policyId A unique identifier for the access policy (e.g., keccak256("POLICY_DAO_GOVERNANCE")).
    /// @param _name A human-readable name for the policy.
    /// @param _conditions An array of `AccessCondition` structs that define the policy's rules.
    function defineAccessPolicy(bytes32 _policyId, string calldata _name, AccessCondition[] calldata _conditions)
        external
        onlyOwner
        whenNotPaused
    {
        require(accessPolicies[_policyId].name == "", "Aethelgard: Policy ID already exists");
        require(_conditions.length > 0, "Aethelgard: Policy must have at least one condition");

        AccessPolicy storage newPolicy = accessPolicies[_policyId];
        newPolicy.name = _name;
        newPolicy.conditions = new AccessCondition[_conditions.length];
        for (uint256 i = 0; i < _conditions.length; i++) {
            newPolicy.conditions[i] = _conditions[i];
        }

        emit AccessPolicyDefined(_policyId, _name);
    }

    /// @notice Evaluates if a given Nexus Profile meets all the conditions of a specified access policy.
    /// @param _profileId The ID of the Nexus Profile to check.
    /// @param _policyId The ID of the access policy to evaluate against.
    /// @return True if the profile meets all policy conditions, false otherwise.
    function checkProfileAccess(uint256 _profileId, bytes32 _policyId)
        public
        view
        returns (bool)
    {
        require(_exists(_profileId), "Aethelgard: Profile does not exist");
        require(accessPolicies[_policyId].name != "", "Aethelgard: Access policy not defined");

        AccessPolicy storage policy = accessPolicies[_policyId];

        for (uint252 i = 0; i < policy.conditions.length; i++) {
            AccessCondition storage condition = policy.conditions[i];
            bool conditionMet = false;

            if (condition.conditionType == ConditionType.HasAttestation) {
                // Check if profile has *any* valid attestation of the specified type
                uint256[] memory attestationsOfType = profileAttestationsByType[_profileId][condition.param1];
                for (uint256 j = 0; j < attestationsOfType.length; j++) {
                    if (verifyAttestationValidity(attestationsOfType[j])) {
                        conditionMet = true;
                        break;
                    }
                }
            } else if (condition.conditionType == ConditionType.MinReputationInDomain) {
                int256 currentScore = calculateProfileReputationScore(_profileId, condition.param1);
                conditionMet = (currentScore >= condition.param2);
            } else if (condition.conditionType == ConditionType.MaxReputationInDomain) {
                int256 currentScore = calculateProfileReputationScore(_profileId, condition.param1);
                conditionMet = (currentScore <= condition.param2);
            }

            if (!conditionMet) {
                emit AccessCheckResult(_profileId, _policyId, false);
                return false; // If any condition is not met, access is denied
            }
        }

        emit AccessCheckResult(_profileId, _policyId, true);
        return true; // All conditions met
    }

    /// @notice Retrieves the definition and conditions of a specified access policy.
    /// @param _policyId The ID of the access policy.
    /// @return The name and an array of `AccessCondition` structs for the policy.
    function getPolicyDetails(bytes32 _policyId)
        external
        view
        returns (string memory name, AccessCondition[] memory conditions)
    {
        require(accessPolicies[_policyId].name != "", "Aethelgard: Access policy not defined");
        AccessPolicy storage policy = accessPolicies[_policyId];
        return (policy.name, policy.conditions);
    }


    // --- 7. Oracle Integration (Chainlink specific) ---

    /// @notice Initiates an external oracle request for validation of an attestation that was marked as requiring oracle verification.
    /// @param _attestationId The ID of the attestation to validate.
    /// @param _oracleJobData Specific data for the Chainlink oracle job (e.g., URL, path).
    function requestAttestationOracleValidation(uint256 _attestationId, bytes calldata _oracleJobData)
        external
        whenNotPaused
        returns (bytes32 requestId)
    {
        Attestation storage att = attestations[_attestationId];
        require(att.id == _attestationId, "Aethelgard: Attestation does not exist");
        require(att.requiresOracleValidation, "Aethelgard: Attestation type does not require oracle validation");
        require(att.status == AttestationStatus.PendingOracle, "Aethelgard: Attestation not in PendingOracle status");
        require(LinkToken(i_link).balanceOf(address(this)) >= i_fee, "Aethelgard: Insufficient LINK balance for oracle request");

        ChainlinkClient.Chainlink.Request memory req = buildChainlinkRequest(i_jobId, address(this), this.fulfillOracleValidation.selector);
        req.add("attestationId", Strings.toString(_attestationId)); // Pass attestation ID to oracle job
        req.addBytes("jobData", _oracleJobData); // Custom data for the oracle job

        requestId = sendChainlinkRequest(req, i_fee);
        att.oracleRequestId = requestId;
        emit OracleValidationRequested(_attestationId, requestId);
        return requestId;
    }

    /// @notice The callback function invoked by the Chainlink oracle to report the result of an attestation validation request.
    /// @param _requestId The ID of the oracle request.
    /// @param _isValid True if the attestation was validated successfully by the oracle, false otherwise.
    /// @param _oracleMessage An optional message from the oracle (e.g., error details).
    function fulfillOracleValidation(bytes32 _requestId, bool _isValid, string calldata _oracleMessage)
        external
        recordChainlinkFulfillment(_requestId)
        whenNotPaused
    {
        require(msg.sender == i_oracle, "Aethelgard: Unauthorized oracle callback");

        uint256 attestationId;
        bool found = false;
        for (uint256 i = 1; i < _nextAttestationId; i++) {
            if (attestations[i].oracleRequestId == _requestId) {
                attestationId = i;
                found = true;
                break;
            }
        }
        require(found, "Aethelgard: Oracle request ID not found for any attestation");

        Attestation storage att = attestations[attestationId];
        AttestationStatus oldStatus = att.status;

        if (_isValid) {
            att.status = AttestationStatus.Valid;
        } else {
            // Decide what happens on failed validation: revoke, mark invalid, etc.
            att.status = AttestationStatus.Revoked; // Example: Revoke on failed validation
        }
        att.lastUpdateTimestamp = block.timestamp;

        emit OracleValidationFulfilled(_requestId, attestationId, _isValid, _oracleMessage);
        emit AttestationStatusUpdated(attestationId, oldStatus, att.status, _requestId);
    }


    // --- 8. Governance & System Hooks ---

    /// @notice Allows the current admin to transfer administrative privileges to a new address.
    /// @param _newAdmin The address of the new administrator.
    function setAdmin(address _newAdmin) external onlyOwner {
        transferOwnership(_newAdmin); // Leverages Ownable's transferOwnership
    }

    /// @notice Admin function to pause core functionalities of the contract during emergencies or maintenance.
    function pauseSystem() external onlyOwner {
        _pause(); // Leverages Pausable's _pause
    }

    /// @notice Admin function to unpause the contract.
    function unpauseSystem() external onlyOwner {
        _unpause(); // Leverages Pausable's _unpause
    }

    /// @notice Admin function to update generic system-wide parameters.
    /// @param _paramKey A unique key for the parameter (e.g., keccak256("MIN_ATTESTATION_VALUE")).
    /// @param _newValue The new value for the parameter.
    function updateSystemParameter(bytes32 _paramKey, uint256 _newValue)
        external
        onlyOwner
        whenNotPaused
    {
        uint256 oldValue = systemParameters[_paramKey];
        systemParameters[_paramKey] = _newValue;
        emit SystemParameterUpdated(_paramKey, oldValue, _newValue);
    }
}

// --- External Libraries / Interfaces (simplified for brevity, assume full Chainlink contracts are imported) ---

// Placeholder for ChainlinkClient (normally imported from @chainlink/contracts)
// This is a minimal representation to satisfy compilation for the example.
interface LinkToken {
    function transferAndCall(address _receiver, uint256 _amount, bytes memory _data) external returns (bool success);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function balanceOf(address owner) external view returns (uint256);
}

library ChainlinkClient {
    struct Request {
        bytes32 id;
        address callbackAddress;
        bytes4 callbackFunctionId;
        uint256 expiration;
        string data;
        string[] data_strings;
        bytes[] data_bytes;
    }

    function buildChainlinkRequest(bytes32 _jobId, address _callbackAddress, bytes4 _callbackFunctionId) internal pure returns (Request memory) {
        Request memory req;
        req.id = _jobId;
        req.callbackAddress = _callbackAddress;
        req.callbackFunctionId = _callbackFunctionId;
        // Simplified: In a real ChainlinkClient, there are more fields and helper functions
        return req;
    }

    function add(Request memory _req, string memory _key, string memory _value) internal pure {
        // Simplified: Add data to request
    }

    function addBytes(Request memory _req, string memory _key, bytes memory _value) internal pure {
        // Simplified: Add bytes data to request
    }

    function sendChainlinkRequest(Request memory _req, uint256 _fee) internal returns (bytes32) {
        // Simplified: Simulate sending. In reality, this interacts with a Chainlink Oracle contract
        return keccak256(abi.encodePacked(block.timestamp, _req.id, _req.callbackAddress));
    }

    // This modifier is used in the actual ChainlinkClient, just a placeholder here
    modifier recordChainlinkFulfillment(bytes32 _requestId) {
        _;
    }
}

// Minimal ERC721 interface for Clarity, actual implementation from OpenZeppelin
interface IERC721Custom {
    function ownerOf(uint256 tokenId) external view returns (address owner);
}

// Minimal Strings utility (from OpenZeppelin's `Address.sol` or `Strings.sol`)
library Strings {
    function toString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        uint256 index = digits - 1;
        temp = value;
        while (temp != 0) {
            buffer[index--] = bytes1(uint8(48 + temp % 10));
            temp /= 10;
        }
        return string(buffer);
    }
}
```