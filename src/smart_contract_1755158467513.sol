This smart contract, named `AttestationNexus`, creates a decentralized system for managing verifiable attestations, user reputation, and dynamic "Skill Badge" NFTs. It aims to provide a robust framework for individuals to build on-chain profiles of their skills, contributions, and reputation, authenticated by other users or verified entities.

It introduces several advanced concepts:
1.  **Soulbound-like Persona**: Each user can register a unique, non-transferable "Persona" that acts as their on-chain identity, accumulating attestations and reputation.
2.  **Dynamic Skill Badges (ERC721)**: Transferable NFTs that represent specific skills or achievements. These badges are "dynamic" because their attributes (e.g., level, visual representation) can be updated on-chain based on new attestations or reputation changes, ensuring they reflect current status.
3.  **Verifiable Attestations**: A core registry for issuing, revoking, and disputing claims about user skills, roles, or contributions. Attestations can have configurable properties like expiry and reputation weight.
4.  **On-chain Reputation Scoring**: A mechanism to calculate a user's reputation score based on the aggregate of valid attestations they've received, weighted by attestation type.
5.  **Staking for Attestation Privilege**: Optionally, users might need to stake tokens to issue high-impact attestations, deterring spam or malicious claims.
6.  **Role-Based Access Control**: Granular permissions using OpenZeppelin's `AccessControl` for managing system roles (e.g., Admin, Dispute Committee).

---

## Contract Outline & Function Summary

**Contract Name:** `AttestationNexus`

This contract manages the issuance and validation of attestations, user personas, and dynamic skill badge NFTs.

---

### **I. Core Attestation Management**

These functions handle the creation, retrieval, and invalidation of verifiable claims (attestations) within the system.

1.  **`issueAttestation(address _subject, bytes32 _attestationTypeHash, bytes32 _dataHash, uint64 _expiryTimestamp)`**
    *   **Description:** Allows a caller to issue an attestation (a verifiable claim) about a specified subject. The `_dataHash` typically points to off-chain evidence (e.g., IPFS CID). Attestations can be configured to expire.
    *   **Access:** Open to all registered Persona holders, with optional staking requirements based on attestation type.
2.  **`revokeAttestation(bytes32 _attestationId)`**
    *   **Description:** Enables the original issuer to revoke (invalidate) an attestation they previously issued.
    *   **Access:** Only the original issuer.
3.  **`getAttestation(bytes32 _attestationId) view`**
    *   **Description:** Retrieves the full details of a specific attestation given its unique ID.
    *   **Access:** Public.
4.  **`getAttestationsBySubject(address _subject) view`**
    *   **Description:** Returns a list of all attestation IDs received by a specific subject.
    *   **Access:** Public.
5.  **`getAttestationsByIssuer(address _issuer) view`**
    *   **Description:** Returns a list of all attestation IDs issued by a specific address.
    *   **Access:** Public.
6.  **`setAttestationTypeConfig(bytes32 _attestationTypeHash, bool _canExpire, uint256 _reputationWeight, bool _requiresStake, uint256 _stakeAmount)`**
    *   **Description:** Configures the properties for a new or existing attestation type. This includes whether it expires, its contribution to reputation, and if issuing it requires staking tokens.
    *   **Access:** `DEFAULT_ADMIN_ROLE` or `GOVERNANCE_ROLE`.

---

### **II. Persona & Reputation (Soulbound-like NFT) Management**

These functions manage a user's unique, non-transferable "Persona" identity and their associated reputation score.

7.  **`registerPersona()`**
    *   **Description:** Allows a user to mint their unique "Persona" identity. This is a soulbound-like action as the Persona is intrinsically linked to the address and non-transferable.
    *   **Access:** Any address that has not yet registered a Persona.
8.  **`getPersona(address _owner) view`**
    *   **Description:** Retrieves the Persona data (creation timestamp, attestation count, current reputation score) for a given address.
    *   **Access:** Public.
9.  **`updatePersonaMetadata(string calldata _newMetadataURI)`**
    *   **Description:** Allows a Persona owner to update their associated off-chain metadata URI (e.g., for profile picture, bio).
    *   **Access:** Only the owner of the Persona.
10. **`calculateReputation(address _subject)`**
    *   **Description:** Triggers a recalculation and update of a subject's reputation score based on all their valid attestations and their configured weights.
    *   **Access:** Public (anyone can trigger a recalculation).
11. **`getReputationScore(address _subject) view`**
    *   **Description:** Returns the current reputation score of a specific subject.
    *   **Access:** Public.

---

### **III. Skill Badge (Dynamic ERC721) Management**

These functions manage the lifecycle and dynamic attributes of transferable Skill Badge NFTs. Inherits standard ERC721 functions.

12. **`defineSkillBadgeType(bytes32 _badgeTypeHash, string calldata _name, string calldata _symbol, string calldata _baseURI)`**
    *   **Description:** Defines a new type of Skill Badge that can be minted (e.g., "Solidity Wizard", "Community Contributor"). Sets its name, symbol, and base URI for metadata.
    *   **Access:** `DEFAULT_ADMIN_ROLE` or `GOVERNANCE_ROLE`.
13. **`mintSkillBadge(address _recipient, bytes32 _badgeTypeHash, uint256 _initialLevel, string calldata _initialTokenURI)`**
    *   **Description:** Mints a new Skill Badge NFT of a defined type to a specified recipient. This might be triggered upon achieving certain criteria (e.g., specific attestations, reputation threshold).
    *   **Access:** `BADGE_MINTER_ROLE`.
14. **`updateSkillBadgeAttributes(uint256 _tokenId, uint256 _newLevel, string calldata _newTokenURI)`**
    *   **Description:** Updates the level and metadata URI of an existing Skill Badge NFT. This is the core "dynamic" aspect, allowing the badge to evolve.
    *   **Access:** `BADGE_UPDATER_ROLE` (potentially controlled by automated logic based on new attestations).
15. **`getSkillBadgeDetails(uint256 _tokenId) view`**
    *   **Description:** Retrieves the custom details (type, level) of a specific Skill Badge NFT.
    *   **Access:** Public.
16. **`tokenURI(uint256 tokenId) view`**
    *   **Description:** Standard ERC721 function to get the metadata URI for a given token ID.
    *   **Access:** Public.
17. **`transferFrom(address from, address to, uint256 tokenId)`**
    *   **Description:** Standard ERC721 function to transfer ownership of a Skill Badge NFT.
    *   **Access:** Owner or approved address.
18. **`approve(address to, uint256 tokenId)`**
    *   **Description:** Standard ERC721 function to grant approval to another address to transfer a specific token.
    *   **Access:** Owner.

---

### **IV. Dispute Resolution & Staking**

These functions provide mechanisms for disputing attestations and managing token stakes.

19. **`initiateDispute(bytes32 _attestationId, string calldata _reason)`**
    *   **Description:** Allows any user to initiate a dispute against a specific attestation, flagging it for review.
    *   **Access:** Public.
20. **`resolveDispute(bytes32 _attestationId, bool _isValid)`**
    *   **Description:** Resolves a dispute for an attestation, marking it as valid or invalid based on the resolution outcome.
    *   **Access:** `DISPUTE_COMMITTEE_ROLE`.
21. **`stakeForAttestation(uint256 _amount)`**
    *   **Description:** Allows a user to stake tokens, required for issuing certain high-impact attestation types as configured.
    *   **Access:** Public.
22. **`withdrawStake()`**
    *   **Description:** Allows a user to withdraw their staked tokens, potentially after a cool-down period or successful issuance of attestations.
    *   **Access:** The staker.

---

### **V. Governance & Access Control**

These functions manage roles and core contract configurations.

23. **`grantRole(bytes32 role, address account)`**
    *   **Description:** Grants a specific role (e.g., `ADMIN_ROLE`, `DISPUTE_COMMITTEE_ROLE`, `BADGE_MINTER_ROLE`) to an account.
    *   **Access:** Account with `ADMIN_ROLE` or a role that can grant the specific role.
24. **`revokeRole(bytes32 role, address account)`**
    *   **Description:** Revokes a specific role from an account.
    *   **Access:** Account with `ADMIN_ROLE` or a role that can revoke the specific role.
25. **`renounceRole(bytes32 role, address account)`**
    *   **Description:** Allows an account to renounce (give up) a role they possess.
    *   **Access:** The account itself.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

// Contract Outline & Function Summary at the top of the file.

contract AttestationNexus is ERC721Enumerable, AccessControl {
    using Counters for Counters.Counter;
    using SafeMath for uint256;

    // --- Roles ---
    bytes32 public constant DEFAULT_ADMIN_ROLE = keccak256("DEFAULT_ADMIN_ROLE");
    bytes32 public constant GOVERNANCE_ROLE = keccak256("GOVERNANCE_ROLE"); // Can set system configs
    bytes32 public constant DISPUTE_COMMITTEE_ROLE = keccak256("DISPUTE_COMMITTEE_ROLE"); // Can resolve disputes
    bytes32 public constant BADGE_MINTER_ROLE = keccak256("BADGE_MINTER_ROLE"); // Can mint new skill badges
    bytes32 public constant BADGE_UPDATER_ROLE = keccak256("BADGE_UPDATER_ROLE"); // Can update skill badge attributes

    // --- Enums ---
    enum DisputeStatus {
        None,
        Pending,
        ResolvedValid,
        ResolvedInvalid
    }

    // --- Structs ---

    struct Attestation {
        bytes32 id; // keccak256(abi.encodePacked(issuer, subject, attestationTypeHash, dataHash, timestamp))
        address issuer;
        address subject;
        bytes32 attestationTypeHash; // Hash representing the type of attestation (e.g., keccak256("SkillVerification:Solidity"))
        bytes32 dataHash; // Hash of off-chain data (e.g., IPFS CID of proof)
        uint64 timestamp;
        uint64 expiryTimestamp; // 0 if no expiry
        bool revoked;
        DisputeStatus disputeStatus;
    }

    struct AttestationTypeConfig {
        bool canExpire; // If true, expiryTimestamp must be set
        uint256 reputationWeight; // How much this type of attestation contributes to reputation
        bool requiresStake; // If true, issuer must stake tokens to issue
        uint256 stakeAmount; // Amount required to stake
    }

    struct Persona {
        address owner;
        uint64 registeredTimestamp;
        string metadataURI; // IPFS hash or URL for user's profile metadata
        uint256 attestationCount;
        uint256 currentReputationScore;
        // No owner, approve, transfer for Persona - inherently soulbound
    }

    struct SkillBadgeType {
        bytes32 badgeTypeHash; // Unique hash for the badge type (e.g., keccak256("SkillBadge:SolidityExpert"))
        string name;
        string symbol;
        string baseURI; // Base URI for metadata generation
    }

    struct SkillBadgeDetails {
        bytes32 badgeTypeHash;
        uint256 level; // Dynamic attribute: level of the skill
        string tokenURI; // Specific URI for this token instance (can be changed dynamically)
    }

    // --- State Variables ---

    Counters.Counter private _tokenIdCounter;

    // Mapping of attestation ID to Attestation struct
    mapping(bytes32 => Attestation) public attestations;
    // Mapping of subject address to array of attestation IDs received
    mapping(address => bytes32[]) public subjectAttestations;
    // Mapping of issuer address to array of attestation IDs issued
    mapping(address => bytes32[]) public issuerAttestations;

    // Mapping of attestation type hash to its configuration
    mapping(bytes32 => AttestationTypeConfig) public attestationTypeConfigs;
    // Mapping of registered Persona addresses to their Persona data
    mapping(address => Persona) public personas;
    // Check if an address has a Persona registered
    mapping(address => bool) public hasPersona;

    // Mapping of skill badge type hash to its configuration
    mapping(bytes32 => SkillBadgeType) public skillBadgeTypes;
    // Mapping of ERC721 token ID to its dynamic skill badge details
    mapping(uint256 => SkillBadgeDetails) public skillBadgeDetails;
    // Mapping of skill badge type hash to array of token IDs of that type
    mapping(bytes32 => uint256[]) public skillBadgeTokensByType;

    // Staking related
    mapping(address => uint256) public stakedBalances;

    // Events
    event AttestationIssued(bytes32 indexed attestationId, address indexed issuer, address indexed subject, bytes32 attestationTypeHash, uint64 timestamp, uint64 expiryTimestamp);
    event AttestationRevoked(bytes32 indexed attestationId, address indexed revoker);
    event AttestationDisputeInitiated(bytes32 indexed attestationId, address indexed disputer, string reason);
    event AttestationDisputeResolved(bytes32 indexed attestationId, bool isValid);
    event AttestationTypeConfigured(bytes32 indexed attestationTypeHash, bool canExpire, uint256 reputationWeight, bool requiresStake, uint256 stakeAmount);

    event PersonaRegistered(address indexed owner, uint64 registeredTimestamp);
    event PersonaMetadataUpdated(address indexed owner, string newMetadataURI);
    event ReputationCalculated(address indexed subject, uint256 newReputationScore);

    event SkillBadgeTypeDefined(bytes32 indexed badgeTypeHash, string name, string symbol);
    event SkillBadgeMinted(uint256 indexed tokenId, address indexed recipient, bytes32 indexed badgeTypeHash, uint256 initialLevel);
    event SkillBadgeAttributesUpdated(uint256 indexed tokenId, uint256 newLevel, string newTokenURI);

    event TokensStaked(address indexed staker, uint256 amount);
    event StakeWithdrawn(address indexed staker, uint256 amount);

    constructor() ERC721("SkillBadge", "SKLBDG") {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(GOVERNANCE_ROLE, msg.sender); // Admin is also Governance
        _grantRole(DISPUTE_COMMITTEE_ROLE, msg.sender); // Admin is also Dispute Committee
        _grantRole(BADGE_MINTER_ROLE, msg.sender); // Admin can mint badges
        _grantRole(BADGE_UPDATER_ROLE, msg.sender); // Admin can update badges
    }

    // --- Internal Helpers ---
    function _generateAttestationId(address _issuer, address _subject, bytes32 _attestationTypeHash, bytes32 _dataHash, uint64 _timestamp)
        internal
        pure
        returns (bytes32)
    {
        return keccak256(abi.encodePacked(_issuer, _subject, _attestationTypeHash, _dataHash, _timestamp));
    }

    // Helper to check if an attestation is currently valid (not revoked, not expired, not invalidated by dispute)
    function _isAttestationValid(bytes32 _attestationId) internal view returns (bool) {
        Attestation storage att = attestations[_attestationId];
        if (att.issuer == address(0) || att.revoked) {
            return false;
        }
        if (att.disputeStatus == DisputeStatus.Pending || att.disputeStatus == DisputeStatus.ResolvedInvalid) {
            return false;
        }
        if (att.expiryTimestamp != 0 && att.expiryTimestamp < block.timestamp) {
            return false;
        }
        return true;
    }

    // Override to ensure tokenURI for dynamic NFTs works correctly
    function _baseURI() internal view override returns (string memory) {
        // This is generic for ERC721Enumerable, specific token URIs are stored per badge
        return "";
    }

    // --- I. Core Attestation Management ---

    /**
     * @dev Allows a caller to issue an attestation about a specified subject.
     * The `_dataHash` typically points to off-chain evidence (e.g., IPFS CID).
     * Attestations can be configured to expire. Requires staking if configured for the type.
     * @param _subject The address of the person the attestation is about.
     * @param _attestationTypeHash A hash identifying the type of attestation (e.g., keccak256("SkillVerification:Solidity")).
     * @param _dataHash A hash linking to off-chain data for context/proof.
     * @param _expiryTimestamp The Unix timestamp when this attestation expires. Set to 0 for no expiry.
     */
    function issueAttestation(address _subject, bytes32 _attestationTypeHash, bytes32 _dataHash, uint64 _expiryTimestamp)
        public
    {
        require(hasPersona[msg.sender], "Issuer must have a Persona");
        require(hasPersona[_subject], "Subject must have a Persona");
        require(_subject != address(0), "Subject cannot be zero address");
        require(_attestationTypeHash != 0, "Attestation type hash cannot be zero");

        AttestationTypeConfig storage config = attestationTypeConfigs[_attestationTypeHash];
        require(config.reputationWeight > 0 || config.requiresStake, "Attestation type not configured"); // Must be configured to issue

        if (config.canExpire) {
            require(_expiryTimestamp > block.timestamp, "Expiry timestamp must be in the future");
        } else {
            require(_expiryTimestamp == 0, "Expiry timestamp must be 0 for non-expiring types");
        }

        if (config.requiresStake) {
            require(stakedBalances[msg.sender] >= config.stakeAmount, "Insufficient staked balance for this attestation type");
            // Deduct stake for this attestation (can be returned on revoke or dispute resolution)
            stakedBalances[msg.sender] = stakedBalances[msg.sender].sub(config.stakeAmount);
        }

        uint64 currentTimestamp = uint64(block.timestamp);
        bytes32 attId = _generateAttestationId(msg.sender, _subject, _attestationTypeHash, _dataHash, currentTimestamp);

        require(attestations[attId].issuer == address(0), "Attestation with this ID already exists");

        attestations[attId] = Attestation({
            id: attId,
            issuer: msg.sender,
            subject: _subject,
            attestationTypeHash: _attestationTypeHash,
            dataHash: _dataHash,
            timestamp: currentTimestamp,
            expiryTimestamp: _expiryTimestamp,
            revoked: false,
            disputeStatus: DisputeStatus.None
        });

        subjectAttestations[_subject].push(attId);
        issuerAttestations[msg.sender].push(attId);
        personas[_subject].attestationCount = personas[_subject].attestationCount.add(1);

        emit AttestationIssued(attId, msg.sender, _subject, _attestationTypeHash, currentTimestamp, _expiryTimestamp);
    }

    /**
     * @dev Enables the original issuer to revoke (invalidate) an attestation they previously issued.
     * @param _attestationId The ID of the attestation to revoke.
     */
    function revokeAttestation(bytes32 _attestationId) public {
        Attestation storage att = attestations[_attestationId];
        require(att.issuer == msg.sender, "Only the issuer can revoke this attestation");
        require(!att.revoked, "Attestation is already revoked");
        require(att.disputeStatus == DisputeStatus.None || att.disputeStatus == DisputeStatus.ResolvedValid, "Cannot revoke attestation under active dispute or already invalidated");

        att.revoked = true;
        // Optionally, return stake if it was required
        if (attestationTypeConfigs[att.attestationTypeHash].requiresStake) {
            stakedBalances[msg.sender] = stakedBalances[msg.sender].add(attestationTypeConfigs[att.attestationTypeHash].stakeAmount);
        }

        emit AttestationRevoked(_attestationId, msg.sender);
    }

    /**
     * @dev Retrieves the full details of a specific attestation given its unique ID.
     * @param _attestationId The ID of the attestation.
     * @return Attestation struct containing all details.
     */
    function getAttestation(bytes32 _attestationId) public view returns (Attestation memory) {
        return attestations[_attestationId];
    }

    /**
     * @dev Returns a list of all attestation IDs received by a specific subject.
     * @param _subject The address of the subject.
     * @return An array of attestation IDs.
     */
    function getAttestationsBySubject(address _subject) public view returns (bytes32[] memory) {
        return subjectAttestations[_subject];
    }

    /**
     * @dev Returns a list of all attestation IDs issued by a specific address.
     * @param _issuer The address of the issuer.
     * @return An array of attestation IDs.
     */
    function getAttestationsByIssuer(address _issuer) public view returns (bytes32[] memory) {
        return issuerAttestations[_issuer];
    }

    /**
     * @dev Configures the properties for a new or existing attestation type.
     * This includes whether it expires, its contribution to reputation, and if issuing it requires staking tokens.
     * @param _attestationTypeHash A hash identifying the type of attestation.
     * @param _canExpire If true, attestations of this type can have an expiry timestamp.
     * @param _reputationWeight The numerical weight this attestation type contributes to reputation.
     * @param _requiresStake If true, the issuer must stake `_stakeAmount` to issue this type.
     * @param _stakeAmount The amount of tokens to stake if `_requiresStake` is true.
     */
    function setAttestationTypeConfig(bytes32 _attestationTypeHash, bool _canExpire, uint256 _reputationWeight, bool _requiresStake, uint256 _stakeAmount)
        public
        onlyRole(GOVERNANCE_ROLE)
    {
        require(_attestationTypeHash != 0, "Attestation type hash cannot be zero");
        if (_requiresStake) {
            require(_stakeAmount > 0, "Stake amount must be greater than zero if required");
        } else {
            require(_stakeAmount == 0, "Stake amount must be zero if not required");
        }

        attestationTypeConfigs[_attestationTypeHash] = AttestationTypeConfig({
            canExpire: _canExpire,
            reputationWeight: _reputationWeight,
            requiresStake: _requiresStake,
            stakeAmount: _stakeAmount
        });

        emit AttestationTypeConfigured(_attestationTypeHash, _canExpire, _reputationWeight, _requiresStake, _stakeAmount);
    }

    // --- II. Persona & Reputation (Soulbound-like NFT) Management ---

    /**
     * @dev Allows a user to mint their unique "Persona" identity. This is a soulbound-like action as
     * the Persona is intrinsically linked to the address and non-transferable.
     */
    function registerPersona() public {
        require(!hasPersona[msg.sender], "Persona already registered for this address");

        personas[msg.sender] = Persona({
            owner: msg.sender,
            registeredTimestamp: uint64(block.timestamp),
            metadataURI: "", // Can be updated later
            attestationCount: 0,
            currentReputationScore: 0
        });
        hasPersona[msg.sender] = true;

        emit PersonaRegistered(msg.sender, uint64(block.timestamp));
    }

    /**
     * @dev Retrieves the Persona data (creation timestamp, attestation count, current reputation score) for a given address.
     * @param _owner The address of the Persona owner.
     * @return Persona struct containing all details.
     */
    function getPersona(address _owner) public view returns (Persona memory) {
        require(hasPersona[_owner], "No Persona registered for this address");
        return personas[_owner];
    }

    /**
     * @dev Allows a Persona owner to update their associated off-chain metadata URI (e.g., for profile picture, bio).
     * @param _newMetadataURI The new URI pointing to off-chain metadata.
     */
    function updatePersonaMetadata(string calldata _newMetadataURI) public {
        require(hasPersona[msg.sender], "No Persona registered for caller");
        personas[msg.sender].metadataURI = _newMetadataURI;
        emit PersonaMetadataUpdated(msg.sender, _newMetadataURI);
    }

    /**
     * @dev Triggers a recalculation and update of a subject's reputation score based on all their valid attestations and their configured weights.
     * Anyone can call this to refresh a subject's score.
     * @param _subject The address whose reputation score needs to be calculated.
     */
    function calculateReputation(address _subject) public {
        require(hasPersona[_subject], "No Persona registered for subject");

        uint256 totalReputation = 0;
        bytes32[] storage subjectAtts = subjectAttestations[_subject];

        for (uint256 i = 0; i < subjectAtts.length; i++) {
            bytes32 attId = subjectAtts[i];
            if (_isAttestationValid(attId)) {
                Attestation storage att = attestations[attId];
                AttestationTypeConfig storage config = attestationTypeConfigs[att.attestationTypeHash];
                totalReputation = totalReputation.add(config.reputationWeight);
                // Future improvement: decay score over time, or weight by issuer's reputation.
            }
        }
        personas[_subject].currentReputationScore = totalReputation;
        emit ReputationCalculated(_subject, totalReputation);
    }

    /**
     * @dev Returns the current reputation score of a specific subject.
     * @param _subject The address of the subject.
     * @return The current reputation score.
     */
    function getReputationScore(address _subject) public view returns (uint256) {
        require(hasPersona[_subject], "No Persona registered for subject");
        return personas[_subject].currentReputationScore;
    }

    // --- III. Skill Badge (Dynamic ERC721) Management ---

    /**
     * @dev Defines a new type of Skill Badge that can be minted. Sets its name, symbol, and base URI for metadata.
     * @param _badgeTypeHash A unique hash for this badge type (e.g., keccak256("SkillBadge:SolidityExpert")).
     * @param _name The human-readable name of the badge type (e.g., "Solidity Expert Badge").
     * @param _symbol The symbol for the badge type (e.g., "SLEXP").
     * @param _baseURI The base URI for generating metadata for tokens of this type.
     */
    function defineSkillBadgeType(bytes32 _badgeTypeHash, string calldata _name, string calldata _symbol, string calldata _baseURI)
        public
        onlyRole(GOVERNANCE_ROLE)
    {
        require(_badgeTypeHash != 0, "Badge type hash cannot be zero");
        require(skillBadgeTypes[_badgeTypeHash].badgeTypeHash == 0, "Skill badge type already defined");
        require(bytes(_name).length > 0 && bytes(_symbol).length > 0, "Name and symbol cannot be empty");

        skillBadgeTypes[_badgeTypeHash] = SkillBadgeType({
            badgeTypeHash: _badgeTypeHash,
            name: _name,
            symbol: _symbol,
            baseURI: _baseURI
        });

        emit SkillBadgeTypeDefined(_badgeTypeHash, _name, _symbol);
    }

    /**
     * @dev Mints a new Skill Badge NFT of a defined type to a specified recipient.
     * This might be triggered upon achieving certain criteria (e.g., specific attestations, reputation threshold).
     * @param _recipient The address to mint the badge to.
     * @param _badgeTypeHash The hash of the predefined skill badge type.
     * @param _initialLevel The initial level of the skill badge.
     * @param _initialTokenURI The initial token URI for this specific badge instance.
     */
    function mintSkillBadge(address _recipient, bytes32 _badgeTypeHash, uint256 _initialLevel, string calldata _initialTokenURI)
        public
        onlyRole(BADGE_MINTER_ROLE)
    {
        require(hasPersona[_recipient], "Recipient must have a Persona registered");
        require(skillBadgeTypes[_badgeTypeHash].badgeTypeHash != 0, "Skill badge type not defined");
        require(_recipient != address(0), "Cannot mint to zero address");

        _tokenIdCounter.increment();
        uint256 newTokenId = _tokenIdCounter.current();

        _safeMint(_recipient, newTokenId);

        skillBadgeDetails[newTokenId] = SkillBadgeDetails({
            badgeTypeHash: _badgeTypeHash,
            level: _initialLevel,
            tokenURI: _initialTokenURI
        });
        skillBadgeTokensByType[_badgeTypeHash].push(newTokenId);

        emit SkillBadgeMinted(newTokenId, _recipient, _badgeTypeHash, _initialLevel);
    }

    /**
     * @dev Updates the level and metadata URI of an existing Skill Badge NFT.
     * This is the core "dynamic" aspect, allowing the badge to evolve based on new attestations or reputation.
     * @param _tokenId The ID of the skill badge to update.
     * @param _newLevel The new level of the skill badge.
     * @param _newTokenURI The new token URI (reflecting updated attributes) for this specific badge instance.
     */
    function updateSkillBadgeAttributes(uint256 _tokenId, uint256 _newLevel, string calldata _newTokenURI)
        public
        onlyRole(BADGE_UPDATER_ROLE)
    {
        require(_exists(_tokenId), "ERC721: token not minted");
        require(skillBadgeDetails[_tokenId].badgeTypeHash != 0, "Token is not a skill badge or invalid ID");

        skillBadgeDetails[_tokenId].level = _newLevel;
        skillBadgeDetails[_tokenId].tokenURI = _newTokenURI;

        emit SkillBadgeAttributesUpdated(_tokenId, _newLevel, _newTokenURI);
    }

    /**
     * @dev Retrieves the custom details (type, level) of a specific Skill Badge NFT.
     * @param _tokenId The ID of the skill badge.
     * @return SkillBadgeDetails struct.
     */
    function getSkillBadgeDetails(uint256 _tokenId) public view returns (SkillBadgeDetails memory) {
        require(_exists(_tokenId), "ERC721: token not minted");
        require(skillBadgeDetails[_tokenId].badgeTypeHash != 0, "Token is not a skill badge or invalid ID");
        return skillBadgeDetails[_tokenId];
    }

    /**
     * @dev Returns the token URI for a given token ID, reflecting its dynamic state.
     * Overrides ERC721's `tokenURI` to use the stored dynamic `tokenURI`.
     */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        return skillBadgeDetails[tokenId].tokenURI;
    }

    // `transferFrom` and `approve` are inherited from ERC721Enumerable.

    // --- IV. Dispute Resolution & Staking ---

    /**
     * @dev Allows any user to initiate a dispute against a specific attestation, flagging it for review.
     * Puts the attestation in a `Pending` dispute status.
     * @param _attestationId The ID of the attestation to dispute.
     * @param _reason A string explaining the reason for the dispute.
     */
    function initiateDispute(bytes32 _attestationId, string calldata _reason) public {
        Attestation storage att = attestations[_attestationId];
        require(att.issuer != address(0), "Attestation does not exist");
        require(att.disputeStatus == DisputeStatus.None, "Attestation is already under dispute or resolved");
        require(!att.revoked, "Cannot dispute a revoked attestation");

        att.disputeStatus = DisputeStatus.Pending;
        emit AttestationDisputeInitiated(_attestationId, msg.sender, _reason);
    }

    /**
     * @dev Resolves a dispute for an attestation, marking it as valid or invalid based on the resolution outcome.
     * Can also return the stake if the attestation was found invalid and required a stake.
     * @param _attestationId The ID of the attestation to resolve the dispute for.
     * @param _isValid True if the attestation is deemed valid, false if invalid.
     */
    function resolveDispute(bytes32 _attestationId, bool _isValid) public onlyRole(DISPUTE_COMMITTEE_ROLE) {
        Attestation storage att = attestations[_attestationId];
        require(att.issuer != address(0), "Attestation does not exist");
        require(att.disputeStatus == DisputeStatus.Pending, "Attestation is not under active dispute");

        if (_isValid) {
            att.disputeStatus = DisputeStatus.ResolvedValid;
            // If attestation was valid, stake (if any) could be released back to issuer after a waiting period,
            // or forfeited as a cost of doing business. For simplicity, we don't return here.
        } else {
            att.disputeStatus = DisputeStatus.ResolvedInvalid;
            // If attestation required a stake and was found invalid, forfeit the stake.
            // For simplicity, we just mark it invalid.
        }

        emit AttestationDisputeResolved(_attestationId, _isValid);
    }

    /**
     * @dev Allows a user to stake tokens, required for issuing certain high-impact attestation types as configured.
     * Assumes an ERC20 token is pre-approved for transfer to this contract. For simplicity, this example uses Ether.
     * In a real scenario, this would interact with an ERC20 token contract.
     * @param _amount The amount of tokens/Ether to stake.
     */
    function stakeForAttestation(uint256 _amount) public payable {
        require(msg.value == _amount, "Amount sent must match amount specified");
        require(_amount > 0, "Stake amount must be greater than zero");
        stakedBalances[msg.sender] = stakedBalances[msg.sender].add(_amount);
        emit TokensStaked(msg.sender, _amount);
    }

    /**
     * @dev Allows a user to withdraw their staked tokens.
     * Assumes no specific lock-up or cool-down for simplicity. In a real system, there would be.
     */
    function withdrawStake() public {
        uint256 amount = stakedBalances[msg.sender];
        require(amount > 0, "No staked tokens to withdraw");

        stakedBalances[msg.sender] = 0;
        (bool success, ) = payable(msg.sender).call{value: amount}("");
        require(success, "Failed to withdraw stake");

        emit StakeWithdrawn(msg.sender, amount);
    }

    // Fallback function to receive Ether if not explicitly staking
    receive() external payable {
        // Ether sent without calling stakeForAttestation() will be held in the contract.
        // Consider rejecting or handling if not intended.
    }

    // --- V. Governance & Access Control (Inherited from AccessControl) ---
    // grantRole, revokeRole, renounceRole are inherited and callable by accounts with DEFAULT_ADMIN_ROLE or other granted roles.

    /**
     * @dev See {IERC165-supportsInterface}.
     * Overridden to support ERC721, ERC721Enumerable, and AccessControl interfaces.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721Enumerable, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
```