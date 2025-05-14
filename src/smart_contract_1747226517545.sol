Okay, let's craft a smart contract that represents a "Decentralized Reputation & Skill Attestation Network". This concept involves users building a profile based on verifiable claims (attestations) issued by trusted parties, which contributes to a dynamic reputation score and allows claiming skill-based badges. It combines elements of decentralized identity, verifiable credentials, and on-chain scoring, which are quite relevant and offer complexity beyond typical tokens or simple contracts.

We'll focus on:
1.  **Identities:** Users creating profiles.
2.  **Issuers:** Trusted entities that can issue attestations.
3.  **Attestations:** Claims about an identity, issued by an issuer, with properties like value and expiration.
4.  **Reputation:** A dynamic score derived from valid attestations issued by trusted issuers.
5.  **Skill Badges:** Claimable achievements based on having specific attestations.

This allows for over 20 distinct functions covering registration, management, querying, and calculation.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

// --- Outline ---
// 1. State Variables: Storage for identities, issuers, attestations, configs, counters.
// 2. Structs: Data structures for Identity, Issuer, Attestation, Configs.
// 3. Events: Notifications for state changes.
// 4. Modifiers: Custom access control (e.g., onlyIssuer).
// 5. Enums: Status types for clarity.
// 6. Core Logic:
//    - Identity Management (Register, Update, Query)
//    - Issuer Management (Register, Update Trust, Query)
//    - Attestation Management (Issue, Revoke, Query)
//    - Attestation Type Configuration (Owner sets value/decay)
//    - Skill Badge Configuration (Owner sets criteria)
//    - Skill Badge Claiming (User claims based on attestations)
//    - Reputation Calculation (Dynamic scoring based on attestations)
//    - Querying & Utility Functions (Counts, Status, Top Reputations)

// --- Function Summary ---
// --- Identity Management ---
// 1. registerIdentity(): Allows a user to create a decentralized identity profile.
// 2. updateIdentityProfile(string memory _name, string memory _profileUri): Allows an identity owner to update their profile details.
// 3. getIdentityProfile(address _identityAddress): Retrieves the profile details for a given identity address.
// 4. checkIdentityExists(address _identityAddress): Checks if an address is registered as an identity.
// 5. getTotalRegisteredIdentities(): Returns the total count of registered identities.
//
// --- Issuer Management ---
// 6. registerIssuer(address _issuerAddress, string memory _name, uint256 _trustLevel): Allows the owner to register a new issuer with a specified trust level.
// 7. updateIssuerProfile(address _issuerAddress, string memory _name, uint256 _trustLevel): Allows the owner to update an existing issuer's profile and trust level.
// 8. getIssuerDetails(address _issuerAddress): Retrieves the profile details for a given issuer address.
// 9. checkIsIssuer(address _account): Checks if an address is registered as an issuer.
// 10. getTotalRegisteredIssuers(): Returns the total count of registered issuers.
//
// --- Attestation Management ---
// 11. issueAttestation(address _identityAddress, uint256 _attestationType, string memory _metadataUri, uint64 _expirationTimestamp): Allows a registered issuer to issue an attestation to an identity.
// 12. revokeAttestation(uint256 _attestationId): Allows the issuer of an attestation to revoke it.
// 13. getAttestationDetails(uint256 _attestationId): Retrieves the details of a specific attestation by ID.
// 14. getAttestationsReceived(address _identityAddress): Retrieves a list of IDs of attestations received by an identity.
// 15. getAttestationsIssued(address _issuerAddress): Retrieves a list of IDs of attestations issued by an issuer.
// 16. getActiveAttestationCount(address _identityAddress, uint256 _attestationType): Gets the count of active, non-expired attestations of a specific type for an identity.
//
// --- Configuration (Owner Only) ---
// 17. defineAttestationType(uint256 _attestationType, uint256 _baseValue, uint256 _decayRateBps, string memory _name): Allows owner to define properties of an attestation type (value, decay). DecayRateBps is in Basis Points (0-10000).
// 18. getAttestationTypeProperties(uint256 _attestationType): Retrieves the configuration properties for an attestation type.
// 19. defineSkillBadgeType(uint256 _badgeId, string memory _name, string memory _metadataUri, SkillBadgeCriteria[] memory _criteria): Allows owner to define a skill badge and its required attestation criteria.
// 20. getSkillBadgeDetails(uint256 _badgeId): Retrieves the details and criteria for a specific skill badge.
// 21. setReputationCalculationParams(uint256 _timeDecayFactorBps, uint256 _issuerTrustWeightBps): Allows owner to set global parameters for reputation calculation (decay factor, issuer trust weight).
// 22. getReputationCalculationParams(): Retrieves the global parameters for reputation calculation.
//
// --- Skill Badge Claiming ---
// 23. claimSkillBadge(uint256 _badgeId): Allows an identity to claim a skill badge if they meet the defined criteria.
// 24. getUserSkillBadges(address _identityAddress): Gets the list of badge IDs claimed by an identity.
//
// --- Reputation ---
// 25. getUserReputationScore(address _identityAddress): Calculates and returns the current reputation score for an identity.
// 26. getTopReputationIdentities(uint256 _count): Retrieves a list of addresses for the top N identities by reputation score (Iterative - gas warning for large N).

contract DecentralizedReputationNetwork is Ownable {
    using Counters for Counters.Counter;
    using Strings for uint256; // For potential string conversions

    // --- State Variables ---

    // Counter for unique attestation IDs
    Counters.Counter private _attestationIds;

    // Mapping from identity address to their profile details
    mapping(address => IdentityProfile) public identities;
    // List of all registered identity addresses (for iteration - use with caution for large scale)
    address[] private _identityAddresses;

    // Mapping from issuer address to their profile details
    mapping(address => IssuerProfile) public issuers;
    // List of all registered issuer addresses (for iteration - use with caution for large scale)
    address[] private _issuerAddresses;

    // Mapping from attestation ID to attestation details
    mapping(uint256 => Attestation) public attestations;
    // Mapping from identity address to array of attestation IDs received
    mapping(address => uint256[]) private _attestationsReceived;
    // Mapping from issuer address to array of attestation IDs issued
    mapping(address => uint256[]) private _attestationsIssued;

    // Configuration for different attestation types
    mapping(uint256 => AttestationTypeConfig) public attestationTypeConfigs;
    // Mapping to track which attestation types have been defined
    mapping(uint256 => bool) private _isAttestationTypeDefined;
    uint256[] public definedAttestationTypes; // List of defined types

    // Configuration for skill badges
    mapping(uint256 => SkillBadgeConfig) public skillBadgeConfigs;
    // Mapping to track which badge IDs have been defined
    mapping(uint256 => bool) private _isSkillBadgeDefined;
    uint256[] public definedSkillBadgeTypes; // List of defined badge IDs

    // Mapping from identity address to mapping of claimed badge ID to boolean (true if claimed)
    mapping(address => mapping(uint256 => bool)) private _claimedSkillBadges;
    // Mapping from identity address to array of claimed badge IDs
    mapping(address => uint256[] ) private _userSkillBadges;

    // Global parameters for reputation calculation
    uint256 public reputationTimeDecayFactorBps; // Basis points (0-10000)
    uint256 public reputationIssuerTrustWeightBps; // Basis points (0-10000)

    // --- Enums ---
    enum Status { Active, Revoked, Expired }

    // --- Structs ---

    struct IdentityProfile {
        string name;
        string profileUri; // URI to off-chain profile metadata (e.g., IPFS)
        uint66 registrationTimestamp; // Use uint64 for timestamp
        bool exists; // Flag to check if address is registered
    }

    struct IssuerProfile {
        string name;
        uint256 trustLevel; // A score indicating the issuer's credibility (e.g., 1-100)
        bool exists; // Flag to check if address is registered as issuer
    }

    struct Attestation {
        uint256 id;
        address issuer;
        address recipient; // The identity receiving the attestation
        uint256 attestationType; // ID referencing AttestationTypeConfig
        uint66 issueTimestamp; // Use uint64 for timestamp
        uint66 expirationTimestamp; // Use uint64 for timestamp (0 for no expiration)
        string metadataUri; // URI to off-chain attestation details (e.g., IPFS)
        Status status;
    }

    struct AttestationTypeConfig {
        string name;
        uint256 baseValue; // Base reputation points this attestation contributes
        uint256 decayRateBps; // Decay rate in Basis Points per year (0-10000)
        bool isDefined; // Flag to check if type is configured
    }

    // Criteria for claiming a skill badge
    struct SkillBadgeCriteria {
        uint256 attestationType; // The required attestation type
        uint256 minCount; // Minimum number of active attestations of this type required
        uint256 minIssuerTrustLevel; // Minimum trust level of issuers for these attestations
    }

    struct SkillBadgeConfig {
        string name;
        string metadataUri; // URI to off-chain badge metadata
        SkillBadgeCriteria[] criteria; // Array of criteria to claim this badge
        bool isDefined; // Flag to check if badge is configured
    }

    // --- Events ---

    event IdentityRegistered(address indexed identityAddress, string name, uint66 registrationTimestamp);
    event IdentityProfileUpdated(address indexed identityAddress, string name, string profileUri);

    event IssuerRegistered(address indexed issuerAddress, string name, uint256 trustLevel);
    event IssuerProfileUpdated(address indexed issuerAddress, string name, uint256 trustLevel);

    event AttestationIssued(uint256 indexed attestationId, address indexed issuer, address indexed recipient, uint256 attestationType, uint66 issueTimestamp, uint66 expirationTimestamp);
    event AttestationRevoked(uint256 indexed attestationId, address indexed issuer);

    event AttestationTypeDefined(uint256 indexed attestationType, string name, uint256 baseValue);
    event SkillBadgeTypeDefined(uint256 indexed badgeId, string name);

    event SkillBadgeClaimed(uint256 indexed badgeId, address indexed identityAddress);

    // --- Modifiers ---

    modifier onlyIssuer() {
        require(issuers[msg.sender].exists, "DRN: Caller is not a registered issuer");
        _;
    }

    modifier onlyIdentity(address _identityAddress) {
        require(msg.sender == _identityAddress, "DRN: Not authorized to act for this identity");
        _;
    }

    modifier whenIdentityExists(address _identityAddress) {
        require(identities[_identityAddress].exists, "DRN: Identity does not exist");
        _;
    }

    modifier whenIssuerExists(address _issuerAddress) {
        require(issuers[_issuerAddress].exists, "DRN: Issuer does not exist");
        _;
    }

    modifier whenAttestationTypeDefined(uint256 _attestationType) {
         require(attestationTypeConfigs[_attestationType].isDefined, "DRN: Attestation type not defined");
         _;
    }

     modifier whenSkillBadgeDefined(uint256 _badgeId) {
         require(skillBadgeConfigs[_badgeId].isDefined, "DRN: Skill badge not defined");
         _;
    }


    // --- Constructor ---
    constructor() Ownable() {
        // Set initial reputation calculation parameters
        // Example: 5% decay per year, 50% weight for issuer trust level
        reputationTimeDecayFactorBps = 500; // 5%
        reputationIssuerTrustWeightBps = 5000; // 50%
    }

    // --- Core Logic Functions ---

    // --- Identity Management ---

    /// @notice Allows a user to create a decentralized identity profile.
    /// @param _name The name associated with the identity.
    /// @param _profileUri URI pointing to off-chain profile metadata.
    function registerIdentity(string memory _name, string memory _profileUri) external {
        require(!identities[msg.sender].exists, "DRN: Identity already registered");

        identities[msg.sender] = IdentityProfile({
            name: _name,
            profileUri: _profileUri,
            registrationTimestamp: uint64(block.timestamp),
            exists: true
        });
        _identityAddresses.push(msg.sender); // Add to the list of identities

        emit IdentityRegistered(msg.sender, _name, uint64(block.timestamp));
    }

    /// @notice Allows an identity owner to update their profile details.
    /// @param _name The new name for the identity.
    /// @param _profileUri The new URI for off-chain profile metadata.
    function updateIdentityProfile(string memory _name, string memory _profileUri) external whenIdentityExists(msg.sender) onlyIdentity(msg.sender) {
        identities[msg.sender].name = _name;
        identities[msg.sender].profileUri = _profileUri;

        emit IdentityProfileUpdated(msg.sender, _name, _profileUri);
    }

    /// @notice Retrieves the profile details for a given identity address.
    /// @param _identityAddress The address of the identity to query.
    /// @return name, profileUri, registrationTimestamp, exists
    function getIdentityProfile(address _identityAddress) external view returns (string memory, string memory, uint64, bool) {
        IdentityProfile storage identity = identities[_identityAddress];
        return (identity.name, identity.profileUri, identity.registrationTimestamp, identity.exists);
    }

    /// @notice Checks if an address is registered as an identity.
    /// @param _identityAddress The address to check.
    /// @return True if registered, false otherwise.
    function checkIdentityExists(address _identityAddress) external view returns (bool) {
        return identities[_identityAddress].exists;
    }

    /// @notice Returns the total count of registered identities.
    /// @return The total count.
    function getTotalRegisteredIdentities() external view returns (uint256) {
        return _identityAddresses.length;
    }


    // --- Issuer Management ---

    /// @notice Allows the owner to register a new issuer with a specified trust level.
    /// @param _issuerAddress The address of the issuer to register.
    /// @param _name The name of the issuer.
    /// @param _trustLevel The trust level of the issuer (e.g., 1-100).
    function registerIssuer(address _issuerAddress, string memory _name, uint256 _trustLevel) external onlyOwner {
        require(!issuers[_issuerAddress].exists, "DRN: Issuer already registered");
        require(_trustLevel <= 100, "DRN: Trust level must be <= 100");

        issuers[_issuerAddress] = IssuerProfile({
            name: _name,
            trustLevel: _trustLevel,
            exists: true
        });
        _issuerAddresses.push(_issuerAddress); // Add to the list of issuers

        emit IssuerRegistered(_issuerAddress, _name, _trustLevel);
    }

    /// @notice Allows the owner to update an existing issuer's profile and trust level.
    /// @param _issuerAddress The address of the issuer to update.
    /// @param _name The new name of the issuer.
    /// @param _trustLevel The new trust level of the issuer.
    function updateIssuerProfile(address _issuerAddress, string memory _name, uint256 _trustLevel) external onlyOwner whenIssuerExists(_issuerAddress) {
        require(_trustLevel <= 100, "DRN: Trust level must be <= 100");

        issuers[_issuerAddress].name = _name;
        issuers[_issuerAddress].trustLevel = _trustLevel;

        emit IssuerProfileUpdated(_issuerAddress, _name, _trustLevel);
    }

    /// @notice Retrieves the profile details for a given issuer address.
    /// @param _issuerAddress The address of the issuer to query.
    /// @return name, trustLevel, exists
    function getIssuerDetails(address _issuerAddress) external view returns (string memory, uint256, bool) {
        IssuerProfile storage issuer = issuers[_issuerAddress];
        return (issuer.name, issuer.trustLevel, issuer.exists);
    }

    /// @notice Checks if an address is registered as an issuer.
    /// @param _account The address to check.
    /// @return True if registered, false otherwise.
    function checkIsIssuer(address _account) external view returns (bool) {
        return issuers[_account].exists;
    }

     /// @notice Returns the total count of registered issuers.
    /// @return The total count.
    function getTotalRegisteredIssuers() external view returns (uint256) {
        return _issuerAddresses.length;
    }


    // --- Attestation Management ---

    /// @notice Allows a registered issuer to issue an attestation to an identity.
    /// @param _identityAddress The identity receiving the attestation.
    /// @param _attestationType The defined type of attestation.
    /// @param _metadataUri URI pointing to off-chain attestation details.
    /// @param _expirationTimestamp Optional expiration timestamp (0 for no expiration).
    function issueAttestation(
        address _identityAddress,
        uint256 _attestationType,
        string memory _metadataUri,
        uint64 _expirationTimestamp
    ) external onlyIssuer whenIdentityExists(_identityAddress) whenAttestationTypeDefined(_attestationType) {
        _attestationIds.increment();
        uint256 newAttestationId = _attestationIds.current();

        attestations[newAttestationId] = Attestation({
            id: newAttestationId,
            issuer: msg.sender,
            recipient: _identityAddress,
            attestationType: _attestationType,
            issueTimestamp: uint64(block.timestamp),
            expirationTimestamp: _expirationTimestamp,
            metadataUri: _metadataUri,
            status: Status.Active
        });

        _attestationsReceived[_identityAddress].push(newAttestationId);
        _attestationsIssued[msg.sender].push(newAttestationId);

        emit AttestationIssued(newAttestationId, msg.sender, _identityAddress, _attestationType, uint64(block.timestamp), _expirationTimestamp);
    }

    /// @notice Allows the issuer of an attestation to revoke it.
    /// @param _attestationId The ID of the attestation to revoke.
    function revokeAttestation(uint256 _attestationId) external onlyIssuer {
        require(attestations[_attestationId].issuer == msg.sender, "DRN: Not the issuer of this attestation");
        require(attestations[_attestationId].status == Status.Active, "DRN: Attestation is not active");

        attestations[_attestationId].status = Status.Revoked;

        emit AttestationRevoked(_attestationId, msg.sender);
    }

    /// @notice Retrieves the details of a specific attestation by ID.
    /// @param _attestationId The ID of the attestation to query.
    /// @return id, issuer, recipient, attestationType, issueTimestamp, expirationTimestamp, metadataUri, status
    function getAttestationDetails(uint256 _attestationId) external view returns (
        uint256, address, address, uint256, uint64, uint64, string memory, Status
    ) {
        Attestation storage att = attestations[_attestationId];
        require(att.id != 0, "DRN: Attestation not found"); // Check if attestation exists

        Status currentStatus = att.status;
        if (currentStatus == Status.Active && att.expirationTimestamp != 0 && att.expirationTimestamp < block.timestamp) {
             currentStatus = Status.Expired; // Mark as expired if necessary
        }

        return (
            att.id,
            att.issuer,
            att.recipient,
            att.attestationType,
            att.issueTimestamp,
            att.expirationTimestamp,
            att.metadataUri,
            currentStatus // Return potentially expired status
        );
    }

    /// @notice Retrieves a list of IDs of attestations received by an identity.
    /// @param _identityAddress The address of the identity.
    /// @return An array of attestation IDs.
    function getAttestationsReceived(address _identityAddress) external view whenIdentityExists(_identityAddress) returns (uint256[] memory) {
        return _attestationsReceived[_identityAddress];
    }

    /// @notice Retrieves a list of IDs of attestations issued by an issuer.
    /// @param _issuerAddress The address of the issuer.
    /// @return An array of attestation IDs.
    function getAttestationsIssued(address _issuerAddress) external view whenIssuerExists(_issuerAddress) returns (uint256[] memory) {
        return _attestationsIssued[_issuerAddress];
    }

    /// @notice Gets the count of active, non-expired attestations of a specific type for an identity from issuers with a minimum trust level.
    /// @param _identityAddress The address of the identity.
    /// @param _attestationType The type of attestation to count.
    /// @param _minIssuerTrustLevel The minimum trust level required for the issuer.
    /// @return The count of matching active attestations.
    function getActiveAttestationCount(address _identityAddress, uint256 _attestationType, uint256 _minIssuerTrustLevel) internal view whenIdentityExists(_identityAddress) returns (uint256) {
        uint256 count = 0;
        for (uint i = 0; i < _attestationsReceived[_identityAddress].length; i++) {
            uint256 attId = _attestationsReceived[_identityAddress][i];
            Attestation storage att = attestations[attId];
            IssuerProfile storage issuer = issuers[att.issuer];

            if (att.status == Status.Active &&
                (att.expirationTimestamp == 0 || att.expirationTimestamp >= block.timestamp) &&
                att.attestationType == _attestationType &&
                issuer.exists && // Ensure issuer still exists
                issuer.trustLevel >= _minIssuerTrustLevel
            ) {
                count++;
            }
        }
        return count;
    }

    // --- Configuration (Owner Only) ---

    /// @notice Allows owner to define properties of an attestation type (value, decay).
    /// @param _attestationType The unique ID for the attestation type.
    /// @param _baseValue The base reputation points this attestation contributes.
    /// @param _decayRateBps Decay rate in Basis Points per year (0-10000). 0 for no decay.
    /// @param _name A descriptive name for the attestation type.
    function defineAttestationType(uint256 _attestationType, uint256 _baseValue, uint256 _decayRateBps, string memory _name) external onlyOwner {
         require(_decayRateBps <= 10000, "DRN: Decay rate must be <= 10000 bps");

        if (!_isAttestationTypeDefined[_attestationType]) {
            definedAttestationTypes.push(_attestationType);
            _isAttestationTypeDefined[_attestationType] = true;
        }

        attestationTypeConfigs[_attestationType] = AttestationTypeConfig({
            name: _name,
            baseValue: _baseValue,
            decayRateBps: _decayRateBps,
            isDefined: true
        });

        emit AttestationTypeDefined(_attestationType, _name, _baseValue);
    }

    /// @notice Retrieves the configuration properties for an attestation type.
    /// @param _attestationType The ID of the attestation type.
    /// @return name, baseValue, decayRateBps, isDefined
    function getAttestationTypeProperties(uint256 _attestationType) external view returns (string memory, uint256, uint256, bool) {
        AttestationTypeConfig storage config = attestationTypeConfigs[_attestationType];
        return (config.name, config.baseValue, config.decayRateBps, config.isDefined);
    }

    /// @notice Allows owner to define a skill badge and its required attestation criteria.
    /// @param _badgeId The unique ID for the skill badge.
    /// @param _name The name of the badge.
    /// @param _metadataUri URI pointing to off-chain badge metadata/image.
    /// @param _criteria Array of criteria required to claim the badge.
    function defineSkillBadgeType(uint256 _badgeId, string memory _name, string memory _metadataUri, SkillBadgeCriteria[] memory _criteria) external onlyOwner {
        require(_criteria.length > 0, "DRN: Badge must have at least one criteria");
        for (uint i = 0; i < _criteria.length; i++) {
            require(attestationTypeConfigs[_criteria[i].attestationType].isDefined, "DRN: Criteria uses undefined attestation type");
            require(_criteria[i].minIssuerTrustLevel <= 100, "DRN: Min issuer trust level must be <= 100");
        }

         if (!_isSkillBadgeDefined[_badgeId]) {
            definedSkillBadgeTypes.push(_badgeId);
            _isSkillBadgeDefined[_badgeId] = true;
        }

        skillBadgeConfigs[_badgeId] = SkillBadgeConfig({
            name: _name,
            metadataUri: _metadataUri,
            criteria: _criteria,
            isDefined: true
        });

        emit SkillBadgeTypeDefined(_badgeId, _name);
    }

     /// @notice Retrieves the details and criteria for a specific skill badge.
    /// @param _badgeId The ID of the skill badge.
    /// @return name, metadataUri, criteria, isDefined
    function getSkillBadgeDetails(uint256 _badgeId) external view returns (string memory, string memory, SkillBadgeCriteria[] memory, bool) {
        SkillBadgeConfig storage config = skillBadgeConfigs[_badgeId];
        return (config.name, config.metadataUri, config.criteria, config.isDefined);
    }

    /// @notice Allows owner to set global parameters for reputation calculation.
    /// @param _timeDecayFactorBps Time decay factor in Basis Points per year for attestation value.
    /// @param _issuerTrustWeightBps Weight of issuer trust level in Basis Points (0-10000).
    function setReputationCalculationParams(uint256 _timeDecayFactorBps, uint256 _issuerTrustWeightBps) external onlyOwner {
        require(_timeDecayFactorBps <= 10000, "DRN: Time decay factor must be <= 10000 bps");
        require(_issuerTrustWeightBps <= 10000, "DRN: Issuer trust weight must be <= 10000 bps");
        reputationTimeDecayFactorBps = _timeDecayFactorBps;
        reputationIssuerTrustWeightBps = _issuerTrustWeightBps;
    }

    /// @notice Retrieves the global parameters for reputation calculation.
    /// @return timeDecayFactorBps, issuerTrustWeightBps
    function getReputationCalculationParams() external view returns (uint256, uint256) {
        return (reputationTimeDecayFactorBps, reputationIssuerTrustWeightBps);
    }


    // --- Skill Badge Claiming ---

    /// @notice Allows an identity to claim a skill badge if they meet the defined criteria.
    /// @param _badgeId The ID of the skill badge to claim.
    function claimSkillBadge(uint256 _badgeId) external whenIdentityExists(msg.sender) whenSkillBadgeDefined(_badgeId) {
        require(!_claimedSkillBadges[msg.sender][_badgeId], "DRN: Badge already claimed");

        SkillBadgeConfig storage badgeConfig = skillBadgeConfigs[_badgeId];
        bool criteriaMet = true;

        for (uint i = 0; i < badgeConfig.criteria.length; i++) {
            SkillBadgeCriteria storage criteria = badgeConfig.criteria[i];
            uint256 activeCount = getActiveAttestationCount(msg.sender, criteria.attestationType, criteria.minIssuerTrustLevel);
            if (activeCount < criteria.minCount) {
                criteriaMet = false;
                break; // Criteria not met, no need to check further
            }
        }

        require(criteriaMet, "DRN: Skill badge criteria not met");

        _claimedSkillBadges[msg.sender][_badgeId] = true;
        _userSkillBadges[msg.sender].push(_badgeId);

        emit SkillBadgeClaimed(_badgeId, msg.sender);
    }

    /// @notice Gets the list of badge IDs claimed by an identity.
    /// @param _identityAddress The address of the identity.
    /// @return An array of badge IDs claimed by the identity.
    function getUserSkillBadges(address _identityAddress) external view whenIdentityExists(_identityAddress) returns (uint256[] memory) {
        return _userSkillBadges[_identityAddress];
    }


    // --- Reputation ---

    /// @notice Calculates the contribution of a single attestation to the reputation score.
    /// @param _attestationId The ID of the attestation.
    /// @return The calculated reputation value from this attestation.
    function calculateAttestationValue(uint256 _attestationId) internal view returns (uint256) {
        Attestation storage att = attestations[_attestationId];
        // Only calculate for active, non-expired attestations
        if (att.status != Status.Active || (att.expirationTimestamp != 0 && att.expirationTimestamp < block.timestamp)) {
            return 0;
        }

        AttestationTypeConfig storage typeConfig = attestationTypeConfigs[att.attestationType];
        // Only calculate if attestation type is defined and has base value
        if (!typeConfig.isDefined || typeConfig.baseValue == 0) {
            return 0;
        }

        IssuerProfile storage issuer = issuers[att.issuer];
        // Only calculate if issuer exists
        if (!issuer.exists) {
             return 0;
        }

        uint256 baseValue = typeConfig.baseValue;
        uint256 issuerFactor = (issuer.trustLevel * reputationIssuerTrustWeightBps) / 10000; // Scale trust level (0-100) and weight (0-10000)
        uint256 valueAdjustedByTrust = (baseValue * (10000 + issuerFactor)) / 10000; // Adjust value based on issuer trust weight (e.g., 50% weight on trust 100 adds 50% value)

        // Simple linear time decay for demonstration. More complex decay (e.g., exponential) might be needed.
        // Decay rate is per year (approx 31536000 seconds).
        uint256 timePassed = block.timestamp - att.issueTimestamp;
        uint256 timeDecay = (timePassed * reputationTimeDecayFactorBps) / (31536000 * 10000); // Decay per second

        // Apply decay, ensuring value doesn't go below zero
        uint256 decayedValue = valueAdjustedByTrust > timeDecay ? valueAdjustedByTrust - timeDecay : 0;

        return decayedValue;
    }


    /// @notice Calculates and returns the current reputation score for an identity.
    /// @param _identityAddress The address of the identity.
    /// @return The calculated reputation score.
    /// @dev This function iterates over all attestations received by the identity. Gas costs increase with the number of attestations.
    function getUserReputationScore(address _identityAddress) public view whenIdentityExists(_identityAddress) returns (uint256) {
        uint256 totalScore = 0;
        uint256[] memory receivedAttestations = _attestationsReceived[_identityAddress];

        for (uint i = 0; i < receivedAttestations.length; i++) {
            uint255 individualAttValue = uint255(calculateAttestationValue(receivedAttestations[i])); // Safely cast, values expected within range
             totalScore += individualAttValue;
        }

        return totalScore;
    }

    /// @notice Retrieves a list of addresses for the top N identities by reputation score.
    /// @param _count The number of top identities to return.
    /// @return An array of identity addresses sorted by reputation score (highest first).
    /// @dev Warning: This function iterates over ALL registered identities and calculates reputation for each. This can be VERY expensive for a large number of identities. Not suitable for mainnet with many users. A more scalable approach would involve off-chain indexing or a separate on-chain sorting mechanism (which is complex and gas-heavy).
    function getTopReputationIdentities(uint256 _count) external view returns (address[] memory) {
        uint256 totalIdentities = _identityAddresses.length;
        if (totalIdentities == 0 || _count == 0) {
            return new address[](0);
        }

        // Limit count to total number of identities
        uint256 limit = _count < totalIdentities ? _count : totalIdentities;

        // Store (score, address) pairs in memory. Max limit 200 to avoid excessive memory usage.
        // Adjust limit based on desired practical maximum for an example.
        uint256 practicalLimit = limit > 200 ? 200 : limit; // Cap at 200 for example purposes

        struct ScoreIdentityPair {
            uint256 score;
            address identity;
        }

        ScoreIdentityPair[] memory scoredIdentities = new ScoreIdentityPair[](totalIdentities);

        for (uint i = 0; i < totalIdentities; i++) {
             address currentIdentity = _identityAddresses[i];
             // Only calculate score for active identities
             if(identities[currentIdentity].exists) {
                scoredIdentities[i] = ScoreIdentityPair({
                    score: getUserReputationScore(currentIdentity),
                    identity: currentIdentity
                });
             } else {
                // Handle non-existent/deactivated identities if needed, here just 0 score
                 scoredIdentities[i] = ScoreIdentityPair({
                    score: 0,
                    identity: currentIdentity
                });
             }
        }

        // Simple Bubble Sort (O(N^2)) - NOT efficient for large N, but sufficient for example/small N
        // For larger N, requires a more complex sorting algorithm or off-chain computation
        for (uint i = 0; i < totalIdentities; i++) {
            for (uint j = 0; j < totalIdentities - 1 - i; j++) {
                if (scoredIdentities[j].score < scoredIdentities[j + 1].score) {
                    // Swap
                    ScoreIdentityPair memory temp = scoredIdentities[j];
                    scoredIdentities[j] = scoredIdentities[j + 1];
                    scoredIdentities[j + 1] = temp;
                }
            }
        }

        // Extract top N identities
        address[] memory topIdentities = new address[](practicalLimit);
        for (uint i = 0; i < practicalLimit; i++) {
            topIdentities[i] = scoredIdentities[i].identity;
        }

        return topIdentities;
    }

    // --- Utility Functions ---

    /// @notice Checks the current status of an attestation, considering expiration.
    /// @param _attestationId The ID of the attestation.
    /// @return The current status (Active, Revoked, Expired).
     function getAttestationStatus(uint256 _attestationId) external view returns (Status) {
        Attestation storage att = attestations[_attestationId];
        require(att.id != 0, "DRN: Attestation not found");

        if (att.status == Status.Active && att.expirationTimestamp != 0 && att.expirationTimestamp < block.timestamp) {
            return Status.Expired;
        }
        return att.status;
    }

    // --- Configuration Retrieval Functions (Added to meet function count and improve usability) ---

    /// @notice Gets the list of all defined attestation type IDs.
    /// @return An array of attestation type IDs.
    function getDefinedAttestationTypes() external view returns (uint256[] memory) {
        return definedAttestationTypes;
    }

    /// @notice Gets the list of all defined skill badge IDs.
    /// @return An array of skill badge IDs.
    function getDefinedSkillBadgeTypes() external view returns (uint256[] memory) {
        return definedSkillBadgeTypes;
    }
}
```