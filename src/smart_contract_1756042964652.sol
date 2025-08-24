Here's a Solidity smart contract named `DecentralizedProtocolGuardian` that implements an advanced, creative, and trendy concept: a **Soulbound Dynamic NFT (SBT) Reputation System with On-chain Attestations for Protocol Guardianship**.

This contract allows individuals to earn reputation as "Guardians" of a decentralized ecosystem. Their reputation is represented by a non-transferable (Soulbound) NFT whose visual and textual metadata dynamically evolves based on their on-chain score. The system includes an attestation mechanism where authorized entities can issue verifiable claims (attestations) about a guardian's contributions or behaviors, directly impacting their reputation score.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Base64.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";

/*
    Contract Name: DecentralizedProtocolGuardian

    Outline:
    This contract establishes a novel Decentralized Protocol Guardian (DPG) system, leveraging Soulbound Tokens (SBTs)
    and dynamic NFT metadata to represent on-chain reputation. It empowers a community of "Guardians" whose contributions
    and behaviors are tracked through a scoring system, influenced by on-chain attestations. The NFT metadata, including
    SVG imagery, dynamically adapts to reflect a guardian's current reputation level and score.

    1.  Core Interfaces & Libraries: Utilizes standard OpenZeppelin components (ERC721, AccessControl, ReentrancyGuard,
        Pausable) and utility libraries (Counters, Base64, Strings) for robust and secure functionality.
    2.  Custom Soulbound ERC721 Implementation: Overrides ERC721 transfer mechanisms to enforce the non-transferability
        of Guardian SBTs, ensuring they are permanently bound to the owning address.
    3.  Reputation System: Manages a 'Guardian Score' for each SBT holder, which can increase, decrease, or decay
        based on various on-chain interactions and attested contributions. Reputation levels are configurable tiers.
    4.  Dynamic NFT Metadata: Generates rich, on-chain SVG images and JSON metadata. The NFT's appearance and
        descriptive attributes evolve in real-time with changes in the guardian's reputation score and level.
    5.  On-chain Attestation System: Provides a mechanism for authorized roles to issue, revoke, and verify claims
        (attestations) about the actions or qualities of other guardians. These attestations directly influence
        reputation scores.
    6.  Role-Based Access Control (RBAC): Implements granular permissions using OpenZeppelin's AccessControl,
        defining roles such as Default Admin, Attestor, Reputation Manager, and Pauser, each with specific
        authorizations.
    7.  Pausable & Emergency Features: Allows administrators to pause critical contract functionalities during
        emergencies, enhancing protocol resilience and security.

    Function Summary:

    I. Initialization & Core Setup:
    1.  constructor(string memory _name, string memory _symbol): Initializes the contract with a name and symbol,
        and grants DEFAULT_ADMIN_ROLE and PAUSER_ROLE to the deployer.
    2.  setReputationLevels(uint256[] calldata _levels, string[] calldata _names, string[] calldata _colors):
        Configures the tiered reputation system, defining score thresholds, corresponding level names, and associated
        hex colors for dynamic NFT rendering. Only callable by DEFAULT_ADMIN_ROLE.
    3.  setBaseURI(string memory newBaseURI): Sets an optional base URI for metadata, though not used by default
        when dynamic data URIs are active. Only callable by DEFAULT_ADMIN_ROLE.
    4.  setTokenURIPrefix(string memory _prefix): Defines the prefix for the `tokenURI` function, typically
        `data:application/json;base64,` for on-chain metadata. Only callable by DEFAULT_ADMIN_ROLE.

    II. Guardian SBT Management:
    5.  mintGuardianSBT(address _to): Mints a new Soulbound Token (SBT) for a specified address. Each address is
        limited to one SBT, representing their unique guardian identity. Sets initial score to 0 and status to Active.
        Callable by anyone (can be restricted if needed).
    6.  burnGuardianSBT(uint256 _tokenId): Allows an SBT owner to burn their token, effectively relinquishing their
        guardian role and associated reputation.
    7.  getGuardianAddress(uint256 _tokenId): Retrieves the wallet address linked to a specific token ID.

    III. Reputation Scoring & Lifecycle:
    8.  increaseReputationScore(uint256 _tokenId, uint256 _amount, string calldata _reason): Public wrapper allowing
        REPUTATION_MANAGER_ROLE to increase a guardian's score. Internally calls `_increaseReputationScore`.
    9.  _increaseReputationScore(uint256 _tokenId, uint256 _amount, string calldata _reason): Internal function
        to safely increment a guardian's reputation score and emit an event.
    10. decreaseReputationScore(uint256 _tokenId, uint256 _amount, string calldata _reason): Public wrapper allowing
        REPUTATION_MANAGER_ROLE to decrease a guardian's score. Internally calls `_decreaseReputationScore`.
    11. _decreaseReputationScore(uint256 _tokenId, uint256 _amount, string calldata _reason): Internal function
        to safely decrement a guardian's reputation score (min 0) and emit an event.
    12. decayReputationScore(uint256 _tokenId, uint256 _amount): Allows REPUTATION_MANAGER_ROLE to apply a
        time-based decay to a guardian's score, simulating the fading relevance of past contributions.
    13. updateGuardianStatus(uint256 _tokenId, GuardianStatus _status): Allows REPUTATION_MANAGER_ROLE to change a
        guardian's operational status (e.g., Active, Inactive, Suspended).
    14. getReputationScore(uint256 _tokenId): Returns the current numerical reputation score for a guardian.
    15. getReputationLevel(uint256 _tokenId): Determines and returns the textual name (e.g., "Novice", "Expert")
        and color of a guardian's current reputation level based on their score.
    16. getGuardianStatus(uint256 _tokenId): Returns the current operational status of a guardian.

    IV. On-chain Attestation System:
    17. issueAttestation(uint256 _subjectTokenId, string calldata _claim, AttestationType _type): Allows ATTESTOR_ROLE
        to issue a verifiable attestation about another guardian's action or characteristic. This triggers an
        automatic adjustment to the subject's reputation score based on the attestation type.
    18. revokeAttestation(uint256 _attestationId): Enables the original issuer or REPUTATION_MANAGER_ROLE to revoke
        an attestation. Revocation attempts to reverse the original score change.
    19. getAttestation(uint256 _attestationId): Retrieves the detailed information of a specific attestation.
    20. getActiveAttestationsForSubject(uint256 _subjectTokenId): Returns all non-revoked attestations issued
        against a particular guardian.
    21. getActiveAttestationsByIssuer(address _issuer): Returns all non-revoked attestations issued by a specific address.

    V. Dynamic Metadata Generation:
    22. tokenURI(uint256 _tokenId): Overrides the standard ERC721 function to dynamically generate a data URI
        containing JSON metadata and an embedded SVG image for the NFT, reflecting the guardian's live reputation.
    23. _generateSVG(uint256 _score, string memory _levelName, string memory _levelColor): Internal pure function
        to construct the SVG image content, visually representing the guardian's score and level.
    24. _generateMetadataJSON(uint256 _tokenId, uint256 _score, string memory _levelName, string memory _levelColor):
        Internal view function to create the JSON metadata structure, embedding the dynamic SVG.
    25. _statusToString(GuardianStatus _status): Internal pure utility function to convert `GuardianStatus` enum
        values into human-readable strings for metadata.

    VI. Role-Based Access Control:
    26. grantRole(bytes32 role, address account): Grants a specified role to an address. Only DEFAULT_ADMIN_ROLE.
    27. revokeRole(bytes32 role, address account): Revokes a specified role from an address. Only DEFAULT_ADMIN_ROLE.
    28. supportsInterface(bytes4 interfaceId): Standard ERC165 function to indicate supported interfaces (ERC721, AccessControl).

    VII. Pausable & Emergency Functions:
    29. pause(): Suspends minting, score modifications, and attestation issuance. Callable by PAUSER_ROLE.
    30. unpause(): Resumes normal contract operations. Callable by PAUSER_ROLE.
*/

contract DecentralizedProtocolGuardian is ERC721, AccessControl, ReentrancyGuard, Pausable {
    using Counters for Counters.Counter;
    using Strings for uint256;

    // --- State Variables ---
    Counters.Counter private _tokenIdCounter;

    // Mapping from token ID to the guardian's reputation score
    mapping(uint256 => uint256) public reputationScores;
    // Mapping from token ID to the guardian's status
    mapping(uint256 => GuardianStatus) public guardianStatus;
    // Mapping from address to token ID (since it's SBT, one address = one token)
    mapping(address => uint256) public addressToTokenId;
    // Mapping from token ID to address
    mapping(uint256 => address) public tokenIdToAddress;
    // Mapping to track if an address has already minted an SBT
    mapping(address => bool) public hasMintedSBT;

    // Reputation level definitions: score thresholds, names, and colors
    struct ReputationLevel {
        uint256 scoreThreshold;
        string name;
        string color; // Hex color code for SVG background/elements
    }
    ReputationLevel[] public reputationLevels; // Must be sorted by scoreThreshold ascending

    // Attestation System
    struct Attestation {
        uint256 id;
        uint256 subjectTokenId; // The tokenId of the guardian being attested
        address issuer;         // The address of the entity issuing the attestation
        string claim;           // A descriptive claim or reason for the attestation
        AttestationType attestationType;
        uint256 issuedAt;
        bool revoked;
    }
    Counters.Counter private _attestationIdCounter;
    mapping(uint256 => Attestation) public attestations; // attestationId -> Attestation struct
    mapping(uint256 => uint256[]) public subjectAttestations; // subjectTokenId -> array of attestation IDs
    mapping(address => uint256[]) public issuerAttestations; // issuerAddress -> array of attestation IDs

    // Token URI related
    string private _tokenURIPrefix = "data:application/json;base64,"; // Default to data URI
    string private _baseURI; // Fallback or for external image hosting, not used with data URI by default.

    // --- Enums ---
    enum GuardianStatus {
        Active,
        Inactive,
        Suspended
    }

    enum AttestationType {
        PositiveContribution, // Increases score (e.g., 10 points)
        NegativeBehavior,     // Decreases score (e.g., 5 points)
        NeutralObservation    // No score change
    }

    // --- Roles ---
    bytes32 public constant DEFAULT_ADMIN_ROLE = keccak256("DEFAULT_ADMIN_ROLE");
    bytes32 public constant ATTESTOR_ROLE = keccak256("ATTESTOR_ROLE");
    bytes32 public constant REPUTATION_MANAGER_ROLE = keccak256("REPUTATION_MANAGER_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

    // --- Events ---
    event GuardianSBTMinted(address indexed owner, uint256 indexed tokenId, uint256 initialScore);
    event GuardianSBTBurned(address indexed owner, uint256 indexed tokenId);
    event ReputationScoreIncreased(uint256 indexed tokenId, uint256 oldScore, uint256 newScore, string reason);
    event ReputationScoreDecreased(uint256 indexed tokenId, uint256 oldScore, uint256 newScore, string reason);
    event ReputationScoreDecayed(uint256 indexed tokenId, uint256 oldScore, uint256 newScore);
    event GuardianStatusUpdated(uint256 indexed tokenId, GuardianStatus oldStatus, GuardianStatus newStatus);
    event AttestationIssued(uint256 indexed attestationId, uint256 indexed subjectTokenId, address indexed issuer, AttestationType attestationType);
    event AttestationRevoked(uint256 indexed attestationId, uint256 indexed subjectTokenId);
    event ReputationLevelsUpdated();
    event TokenURIPrefixSet(string oldPrefix, string newPrefix);

    // --- Constructor (Function 1) ---
    constructor(string memory _name, string memory _symbol) ERC721(_name, _symbol) {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(PAUSER_ROLE, msg.sender); // Deployer can pause by default
    }

    // --- Role Management (Functions 26, 27, 28) ---
    function grantRole(bytes32 role, address account) public virtual override onlyRole(DEFAULT_ADMIN_ROLE) {
        _grantRole(role, account);
    }

    function revokeRole(bytes32 role, address account) public virtual override onlyRole(DEFAULT_ADMIN_ROLE) {
        _revokeRole(role, account);
    }

    // `hasRole` is inherited and public directly from AccessControl.
    // Function 28: Overrides required by Solidity to make `_msgSender` work for AccessControl.
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, AccessControl) returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    // --- Core Setup (Functions 2, 3, 4) ---
    function setReputationLevels(uint256[] calldata _levels, string[] calldata _names, string[] calldata _colors)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(_levels.length == _names.length && _levels.length == _colors.length, "DPG: Array length mismatch");
        require(_levels.length > 0, "DPG: At least one reputation level is required");

        // Ensure levels are sorted ascending
        for (uint i = 0; i < _levels.length - 1; i++) {
            require(_levels[i] < _levels[i+1], "DPG: Reputation levels must be in ascending order");
        }

        delete reputationLevels; // Clear existing levels
        for (uint i = 0; i < _levels.length; i++) {
            reputationLevels.push(ReputationLevel({
                scoreThreshold: _levels[i],
                name: _names[i],
                color: _colors[i]
            }));
        }
        emit ReputationLevelsUpdated();
    }

    function setBaseURI(string memory newBaseURI) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _baseURI = newBaseURI;
    }

    function setTokenURIPrefix(string memory _prefix) public onlyRole(DEFAULT_ADMIN_ROLE) {
        require(bytes(_prefix).length > 0, "DPG: Prefix cannot be empty");
        emit TokenURIPrefixSet(_tokenURIPrefix, _prefix);
        _tokenURIPrefix = _prefix;
    }

    // --- Guardian SBT Management (Functions 5, 6, 7) ---
    function mintGuardianSBT(address _to) public onlyWhenNotPaused nonReentrant { // Function 5
        require(_to != address(0), "DPG: Mint to the zero address");
        require(!hasMintedSBT[_to], "DPG: Address already has a Guardian SBT");

        _tokenIdCounter.increment();
        uint256 newTokenId = _tokenIdCounter.current();

        _safeMint(_to, newTokenId); // Mints the ERC721 token
        reputationScores[newTokenId] = 0; // Start with a base reputation score
        guardianStatus[newTokenId] = GuardianStatus.Active;
        addressToTokenId[_to] = newTokenId;
        tokenIdToAddress[newTokenId] = _to;
        hasMintedSBT[_to] = true;

        emit GuardianSBTMinted(_to, newTokenId, 0);
    }

    function burnGuardianSBT(uint256 _tokenId) public onlyWhenNotPaused nonReentrant { // Function 6
        require(_isApprovedOrOwner(msg.sender, _tokenId), "DPG: Not owner or approved");

        address owner = ownerOf(_tokenId);

        // Clear associated data
        delete reputationScores[_tokenId];
        delete guardianStatus[_tokenId];
        delete addressToTokenId[owner];
        delete tokenIdToAddress[_tokenId];
        hasMintedSBT[owner] = false;

        _burn(_tokenId); // Burns the ERC721 token
        emit GuardianSBTBurned(owner, _tokenId);
    }

    function getGuardianAddress(uint256 _tokenId) public view returns (address) { // Function 7
        require(_exists(_tokenId), "DPG: Token ID does not exist");
        return tokenIdToAddress[_tokenId];
    }

    // --- Soulbound Enforcement (Overrides) ---
    // Prevents transfers after minting
    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize)
        internal
        virtual
        override(ERC721, ERC721)
    {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);

        // Allow minting (from == address(0)) and burning (to == address(0)), but not transfers between addresses
        if (from != address(0) && to != address(0)) {
            revert("DPG: Soulbound tokens are non-transferable");
        }
    }

    // Override approve and setApprovalForAll to ensure non-transferability even if someone tries
    function approve(address to, uint256 tokenId) public virtual override {
        revert("DPG: Soulbound tokens cannot be approved for transfer");
    }

    function setApprovalForAll(address operator, bool approved) public virtual override {
        revert("DPG: Soulbound tokens cannot be approved for transfer");
    }

    // --- Reputation Scoring & Lifecycle ---

    // Internal helper for increasing reputation (Function 9)
    function _increaseReputationScore(uint256 _tokenId, uint256 _amount, string calldata _reason) internal {
        uint256 oldScore = reputationScores[_tokenId];
        reputationScores[_tokenId] = oldScore + _amount;
        emit ReputationScoreIncreased(_tokenId, oldScore, reputationScores[_tokenId], _reason);
    }

    // Public function for REPUTATION_MANAGER_ROLE to increase score (Function 8)
    function increaseReputationScore(uint256 _tokenId, uint256 _amount, string calldata _reason)
        public
        onlyWhenNotPaused
        onlyRole(REPUTATION_MANAGER_ROLE)
        nonReentrant
    {
        require(_exists(_tokenId), "DPG: Token ID does not exist");
        _increaseReputationScore(_tokenId, _amount, _reason);
    }

    // Internal helper for decreasing reputation (Function 11)
    function _decreaseReputationScore(uint256 _tokenId, uint256 _amount, string calldata _reason) internal {
        uint256 oldScore = reputationScores[_tokenId];
        if (reputationScores[_tokenId] > _amount) {
            reputationScores[_tokenId] -= _amount;
        } else {
            reputationScores[_tokenId] = 0; // Score cannot go below zero
        }
        emit ReputationScoreDecreased(_tokenId, oldScore, reputationScores[_tokenId], _reason);
    }

    // Public function for REPUTATION_MANAGER_ROLE to decrease score (Function 10)
    function decreaseReputationScore(uint256 _tokenId, uint256 _amount, string calldata _reason)
        public
        onlyWhenNotPaused
        onlyRole(REPUTATION_MANAGER_ROLE)
        nonReentrant
    {
        require(_exists(_tokenId), "DPG: Token ID does not exist");
        _decreaseReputationScore(_tokenId, _amount, _reason);
    }

    function decayReputationScore(uint256 _tokenId, uint256 _amount) // Function 12
        public
        onlyWhenNotPaused
        onlyRole(REPUTATION_MANAGER_ROLE)
        nonReentrant
    {
        require(_exists(_tokenId), "DPG: Token ID does not exist");
        uint256 oldScore = reputationScores[_tokenId];
        _decreaseReputationScore(_tokenId, _amount, "Reputation decay"); // Use internal decrease for decay as well
        // Emit specific decay event with correct oldScore before modification
        emit ReputationScoreDecayed(_tokenId, oldScore, reputationScores[_tokenId]);
    }

    function updateGuardianStatus(uint256 _tokenId, GuardianStatus _status) // Function 13
        public
        onlyWhenNotPaused
        onlyRole(REPUTATION_MANAGER_ROLE)
    {
        require(_exists(_tokenId), "DPG: Token ID does not exist");
        GuardianStatus oldStatus = guardianStatus[_tokenId];
        require(oldStatus != _status, "DPG: Guardian already has this status");
        guardianStatus[_tokenId] = _status;
        emit GuardianStatusUpdated(_tokenId, oldStatus, _status);
    }

    function getReputationScore(uint256 _tokenId) public view returns (uint256) { // Function 14
        require(_exists(_tokenId), "DPG: Token ID does not exist");
        return reputationScores[_tokenId];
    }

    function getReputationLevel(uint256 _tokenId) public view returns (string memory levelName, string memory levelColor) { // Function 15
        require(_exists(_tokenId), "DPG: Token ID does not exist");
        uint256 score = reputationScores[_tokenId];

        // Find the highest level whose threshold is less than or equal to the current score
        levelName = "Unranked";
        levelColor = "A0A0A0"; // Default Grey

        for (uint i = 0; i < reputationLevels.length; i++) {
            if (score >= reputationLevels[i].scoreThreshold) {
                levelName = reputationLevels[i].name;
                levelColor = reputationLevels[i].color;
            } else {
                // Since levels are sorted, we can stop once we pass the score
                break;
            }
        }
        return (levelName, levelColor);
    }

    function getGuardianStatus(uint256 _tokenId) public view returns (GuardianStatus) { // Function 16
        require(_exists(_tokenId), "DPG: Token ID does not exist");
        return guardianStatus[_tokenId];
    }

    // --- On-chain Attestation System ---
    function issueAttestation(uint256 _subjectTokenId, string calldata _claim, AttestationType _type) // Function 17
        public
        onlyWhenNotPaused
        onlyRole(ATTESTOR_ROLE)
        nonReentrant
    {
        require(_exists(_subjectTokenId), "DPG: Subject token ID does not exist");

        _attestationIdCounter.increment();
        uint256 newAttestationId = _attestationIdCounter.current();

        attestations[newAttestationId] = Attestation({
            id: newAttestationId,
            subjectTokenId: _subjectTokenId,
            issuer: msg.sender,
            claim: _claim,
            attestationType: _type,
            issuedAt: block.timestamp,
            revoked: false
        });

        subjectAttestations[_subjectTokenId].push(newAttestationId);
        issuerAttestations[msg.sender].push(newAttestationId);

        // Apply score change based on attestation type
        if (_type == AttestationType.PositiveContribution) {
            _increaseReputationScore(_subjectTokenId, 10, string(abi.encodePacked("Attestation: ", _claim)));
        } else if (_type == AttestationType.NegativeBehavior) {
            _decreaseReputationScore(_subjectTokenId, 5, string(abi.encodePacked("Attestation: ", _claim)));
        }
        // NeutralObservation has no score change

        emit AttestationIssued(newAttestationId, _subjectTokenId, msg.sender, _type);
    }

    function revokeAttestation(uint256 _attestationId) // Function 18
        public
        onlyWhenNotPaused
        nonReentrant
    {
        Attestation storage attestation = attestations[_attestationId];
        require(attestation.id != 0, "DPG: Attestation does not exist");
        require(!attestation.revoked, "DPG: Attestation already revoked");
        require(attestation.issuer == msg.sender || hasRole(REPUTATION_MANAGER_ROLE, msg.sender),
            "DPG: Only issuer or manager can revoke attestation");

        attestation.revoked = true;

        // Revert score change (as per design choice: a revoked positive attestation decreases score, etc.)
        if (attestation.attestationType == AttestationType.PositiveContribution) {
            _decreaseReputationScore(attestation.subjectTokenId, 10, "Attestation revoked");
        } else if (attestation.attestationType == AttestationType.NegativeBehavior) {
            _increaseReputationScore(attestation.subjectTokenId, 5, "Attestation revoked");
        }
        // NeutralObservation has no score change to revert

        emit AttestationRevoked(_attestationId, attestation.subjectTokenId);
    }

    function getAttestation(uint256 _attestationId) public view returns (Attestation memory) { // Function 19
        require(attestations[_attestationId].id != 0, "DPG: Attestation does not exist");
        return attestations[_attestationId];
    }

    function getActiveAttestationsForSubject(uint256 _subjectTokenId) public view returns (Attestation[] memory) { // Function 20
        require(_exists(_subjectTokenId), "DPG: Subject token ID does not exist");
        uint256[] storage attestationIds = subjectAttestations[_subjectTokenId];
        Attestation[] memory activeAttestations = new Attestation[](attestationIds.length);
        uint256 count = 0;
        for (uint i = 0; i < attestationIds.length; i++) {
            Attestation storage att = attestations[attestationIds[i]];
            if (!att.revoked) {
                activeAttestations[count] = att;
                count++;
            }
        }
        // Resize array to fit actual number of active attestations
        Attestation[] memory result = new Attestation[](count);
        for (uint i = 0; i < count; i++) {
            result[i] = activeAttestations[i];
        }
        return result;
    }

    function getActiveAttestationsByIssuer(address _issuer) public view returns (Attestation[] memory) { // Function 21
        uint256[] storage attestationIds = issuerAttestations[_issuer];
        Attestation[] memory activeAttestations = new Attestation[](attestationIds.length);
        uint256 count = 0;
        for (uint i = 0; i < attestationIds.length; i++) {
            Attestation storage att = attestations[attestationIds[i]];
            if (!att.revoked) {
                activeAttestations[count] = att;
                count++;
            }
        }
        Attestation[] memory result = new Attestation[](count);
        for (uint i = 0; i < count; i++) {
            result[i] = activeAttestations[i];
        }
        return result;
    }

    // --- Dynamic Metadata Generation ---
    function tokenURI(uint256 _tokenId) public view override returns (string memory) { // Function 22
        require(_exists(_tokenId), "DPG: Token ID does not exist");

        (string memory levelName, string memory levelColor) = getReputationLevel(_tokenId);
        uint256 score = reputationScores[_tokenId];

        string memory json = _generateMetadataJSON(_tokenId, score, levelName, levelColor);
        return string(abi.encodePacked(_tokenURIPrefix, Base64.encode(bytes(json))));
    }

    function _generateMetadataJSON(uint256 _tokenId, uint256 _score, string memory _levelName, string memory _levelColor)
        internal
        view
        returns (string memory) // Function 24
    {
        string memory svg = _generateSVG(_score, _levelName, _levelColor);
        string memory encodedSVG = Base64.encode(bytes(svg));
        string memory imageURI = string(abi.encodePacked("data:image/svg+xml;base64,", encodedSVG));

        return string(abi.encodePacked(
            '{"name": "DPG Guardian #', _tokenId.toString(), '",',
            '"description": "Decentralized Protocol Guardian SBT, representing on-chain reputation and contributions to the ecosystem.",',
            '"image": "', imageURI, '",',
            '"attributes": [',
                '{"trait_type": "Reputation Score", "value": ', _score.toString(), '},',
                '{"trait_type": "Reputation Level", "value": "', _levelName, '"},',
                '{"trait_type": "Guardian Status", "value": "', _statusToString(guardianStatus[_tokenId]), '"},',
                '{"trait_type": "Minted At (Timestamp)", "value": ', block.timestamp.toString(), '}',
            ']}'
        ));
    }

    function _generateSVG(uint256 _score, string memory _levelName, string memory _levelColor)
        internal
        pure
        returns (string memory) // Function 23
    {
        // A simple, dynamic SVG representation of the guardian's level and score.
        // Can be much more complex with more levels, shapes, etc.
        return string(abi.encodePacked(
            '<svg width="300" height="300" viewBox="0 0 300 300" fill="none" xmlns="http://www.w3.org/2000/svg">',
            '<rect width="300" height="300" fill="#1A1A1A"/>', // Dark background
            '<rect x="25" y="25" width="250" height="250" fill="#', _levelColor, '" opacity="0.1"/>', // Faded color based on level
            '<circle cx="150" cy="150" r="100" fill="#', _levelColor, '" stroke="#FFFFFF" stroke-width="5"/>', // Central circle
            '<text x="150" y="140" font-family="monospace" font-size="24" fill="#FFFFFF" text-anchor="middle">Guardian</text>',
            '<text x="150" y="175" font-family="monospace" font-size="28" fill="#FFFFFF" text-anchor="middle">', _levelName, '</text>',
            '<text x="150" y="220" font-family="monospace" font-size="18" fill="#FFFFFF" text-anchor="middle">Score: ', _score.toString(), '</text>',
            // Add some dynamic elements based on score for visual progression
            _score >= 100 ? '<polygon points="150,50 160,80 190,80 165,100 175,130 150,110 125,130 135,100 110,80 140,80" fill="#FFD700"/>' : '', // A star if score >= 100
            _score >= 200 ? '<rect x="120" y="240" width="60" height="10" fill="#FFFFFF"/>' : '', // A bar if score >= 200
            '</svg>'
        ));
    }

    // Helper to convert GuardianStatus enum to string for metadata (Function 25)
    function _statusToString(GuardianStatus _status) internal pure returns (string memory) {
        if (_status == GuardianStatus.Active) return "Active";
        if (_status == GuardianStatus.Inactive) return "Inactive";
        if (_status == GuardianStatus.Suspended) return "Suspended";
        return "Unknown";
    }

    // --- Pausable & Emergency Functions (Functions 29, 30) ---
    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() public public onlyRole(PAUSER_ROLE) {
        _unpause();
    }
}
```