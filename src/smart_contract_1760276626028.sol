This smart contract, `AuraNexus`, is designed as a sophisticated decentralized credentialing and reputation system. It leverages non-transferable (soulbound-like) ERC-721 NFTs called "Attestations" to represent verifiable on-chain credentials, achievements, or contributions. Users can register profiles, link external identifiers, and accumulate Attestations issued by approved entities called "Attestors." The contract features a dynamic reputation scoring mechanism that considers Attestation types, their configured weights, and time-based decay. A decentralized governance module manages the approval and permissioning of Attestors.

The core idea is to build a foundational layer for decentralized identity and reputation, where trust and credibility are established through verifiable on-chain actions and attestations, rather than centralized entities.

---

## Contract: `AuraNexus`

**Outline:**

The `AuraNexus` contract is structured into six main modules:

1.  **Core Infrastructure & Access Control:** Handles basic contract ownership and general contract settings.
2.  **User Profiles & Identity Management:** Allows users to create and manage their on-chain identity, including profile metadata and linking external identifiers.
3.  **Attestation (NFT) Management:** Defines, issues, revokes, and updates the dynamic, non-transferable ERC-721 Attestation NFTs.
4.  **Decentralized Attestor Governance:** Provides a DAO-like mechanism for community-approved voters to propose, vote on, and execute the addition/removal of Attestors.
5.  **Reputation Scoring & Verification:** Implements the core logic for calculating a user's aggregate reputation score based on their Attestations and allows external contracts to verify credentials.
6.  **System Economics & Maintenance:** Manages fees, fee withdrawal, and voter weights for governance.

---

**Function Summary (26 Functions):**

**I. Core Infrastructure & Access Control (3 Functions):**

1.  `constructor()`: Initializes the contract, sets the deployer as the owner, and assigns initial voting weight to the owner for governance.
2.  `updateContractURI(string memory _newURI)`: Allows the contract owner to update the contract-level metadata URI (e.g., for general project information).
3.  `renounceOwnership()`: (Inherited from `Ownable`) Allows the current owner to relinquish ownership of the contract.

**II. User Profiles & Identity Management (5 Functions):**

4.  `registerProfile(string memory _metadataURI)`: Allows a user to create a unique on-chain profile for `msg.sender`, linking a metadata URI (e.g., PFP, bio).
5.  `updateProfileMetadata(string memory _newMetadataURI)`: Enables the profile owner (`msg.sender`) to update their own profile's metadata URI.
6.  `updateDelegatedProfileMetadata(address _user, string memory _newMetadataURI)`: Allows a pre-designated delegator (`msg.sender`) to update the profile metadata for a specific user (`_user`).
7.  `linkExternalIdentifier(bytes32 _idHash, uint256 _idType)`: Associates a hashed off-chain identifier (e.g., Twitter handle hash, GitHub ID hash) with the caller's profile for verifiable linkages.
8.  `setProfileDelegator(address _delegator)`: Designates an address (`_delegator`) that is authorized to update the caller's profile metadata. Setting `_delegator` to `address(0)` removes delegation.
9.  `getUserProfile(address _user)`: (View) Retrieves all details associated with a specific user's profile, including metadata, delegator, and linked external identifiers.

**III. Attestation (NFT) Management (7 Functions):**

10. `createAttestationType(string memory _name, string memory _description, bool _isRevocable, uint256 _baseWeight, uint256 _decayRateBasisPoints)`: (Owner only) Defines a new type of credential (e.g., "Web3 Developer L3"). It specifies its name, description, whether it can be revoked, its base reputation weight, and an annual decay rate.
11. `issueAttestation(address _to, uint256 _attestationTypeId, string memory _attestationMetadataURI, uint256 _expirationDate)`: An approved Attestor issues a new non-transferable ERC-721 Attestation NFT to a user. It requires a fee and specifies the recipient, attestation type, specific metadata URI, and an expiration date (0 for no expiration).
12. `revokeAttestation(uint256 _tokenId)`: Allows the original issuer (if the type is revocable) or the contract owner to invalidate an issued Attestation NFT.
13. `updateAttestationMetadata(uint256 _tokenId, string memory _newMetadataURI)`: Enables the original issuer to update the dynamic metadata URI for an existing Attestation NFT, allowing its traits or status to evolve.
14. `updateAttestationExpiration(uint256 _tokenId, uint256 _newExpirationDate)`: Allows the original issuer to modify the expiration date of an Attestation NFT.
15. `requestAttestation(uint256 _attestationTypeId, address _fromAttestor, string memory _requestDetailsURI)`: A user formally signals their request for a specific attestation type from a designated Attestor, emitting an event for off-chain processing.
16. `getAttestationDetails(uint256 _tokenId)`: (View) Retrieves detailed information about a specific Attestation NFT, including its type, owner, issuer, metadata, dates, and status.
17. `getUserAttestationTokens(address _user)`: (View) Returns an array of all Attestation NFT token IDs held by a given user.

**IV. Decentralized Attestor Governance (5 Functions):**

18. `proposeAttestor(address _newAttestor, string memory _reasonURI)`: Allows any whitelisted voter to initiate a proposal to add a new address as an official Attestor.
19. `voteOnAttestorProposal(uint256 _proposalId, bool _support)`: Enables whitelisted voters to cast their weighted vote (for or against) on an active Attestor proposal.
20. `executeAttestorProposal(uint256 _proposalId)`: Anyone can call this function after the voting period ends. It tallies votes and, if passed by majority, officially registers the proposed address as an Attestor.
21. `setAttestorPermissions(address _attestor, uint256 _attestationTypeId, bool _canIssue, bool _canRevoke)`: (Owner only) Configures which specific attestation types an approved Attestor is allowed to issue and/or revoke.
22. `renounceAttestorRole()`: Allows an active Attestor (`msg.sender`) to voluntarily step down from their role.

**V. Reputation Scoring & Verification (4 Functions):**

23. `calculateUserReputationScore(address _user)`: (View) Computes the aggregate reputation score for a user by iterating through all their valid Attestations, applying the base weights and time-based decay rates defined for each attestation type.
24. `getAttestationTypeDetails(uint256 _attestationTypeId)`: (View) Provides all configurable details about a specific attestation type, such as its name, description, weight, and decay rate.
25. `adjustAttestationTypeWeight(uint256 _attestationTypeId, uint256 _newBaseWeight)`: (Owner only) Modifies the base reputation weight associated with an existing attestation type, affecting future score calculations.
26. `verifyAttestationPresence(address _user, uint256 _attestationTypeId)`: (View) A crucial function for external contracts, allowing them to quickly check if a given user holds *any* valid (non-revoked, non-expired, non-challenged) Attestation NFT of a specific type.
27. `challengeAttestation(uint256 _tokenId, string memory _challengeReasonURI)`: Allows any user to formally dispute the validity of an existing attestation. This flags the attestation as "challenged," which reduces its reputation contribution and signals for external (e.g., DAO) review.

**VI. System Economics & Maintenance (3 Functions):**

28. `setAttestationIssuanceFee(uint256 _fee)`: (Owner only) Sets the fee (in native currency, e.g., ETH) that Attestors must pay to issue new Attestation NFTs.
29. `withdrawFees(address _to)`: (Owner only) Allows the contract owner to withdraw accumulated fees to a specified address.
30. `setVoterWeight(address _voter, uint256 _weight)`: (Owner only) Configures the voting power (weight) of a specific address in the Attestor governance proposals, enabling a curated or tiered voting system.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol"; // SafeMath is redundant in 0.8.x but harmless.
import "@openzeppelin/contracts/utils/Strings.sol";

/**
 * @title IAuraNexus
 * @notice Interface for external contracts to interact with AuraNexus for reputation and credential verification.
 */
interface IAuraNexus {
    function calculateUserReputationScore(address _user) external view returns (uint256);
    function verifyAttestationPresence(address _user, uint256 _attestationTypeId) external view returns (bool);
    function getAttestationDetails(uint256 _tokenId) external view returns (
        uint256 attestationTypeId,
        address owner,
        address issuer,
        string memory metadataURI,
        uint256 issueDate,
        uint256 expirationDate,
        bool isRevoked,
        bool isChallenged
    );
    function getUserProfile(address _user) external view returns (
        string memory metadataURI,
        address delegator,
        bytes32[] memory externalIdHashes,
        uint256[] memory externalIdTypes,
        bool profileExists
    );
}

/**
 * @title AuraNexus
 * @author YourName/Alias
 * @notice A comprehensive smart contract system for managing on-chain verifiable credentials (Attestation NFTs),
 *         user profiles, decentralized Attestor governance, and an aggregated reputation scoring mechanism.
 *         Attestation NFTs are designed to be soulbound-like (non-transferable) and dynamic.
 *         This contract aims to provide a foundational layer for decentralized identity and reputation.
 *
 * @dev This contract extends ERC721 for Attestation NFTs and Ownable for base contract ownership.
 *      It includes custom logic for non-transferable NFTs, dynamic metadata, expiration,
 *      reputation score calculation with decay, and a basic DAO for Attestor management.
 *      External contracts can query user reputation and attestation presence.
 */
contract AuraNexus is ERC721, Ownable, IAuraNexus {
    using Counters for Counters.Counter;
    using SafeMath for uint256; // SafeMath is mostly for illustrative purposes in 0.8.x
    using Strings for uint256;

    // --- State Variables ---

    string public contractURI; // Contract-wide metadata URI

    // Counters for unique IDs
    Counters.Counter private _attestationTypeIds;
    Counters.Counter private _attestationTokenIds;
    Counters.Counter private _attestorProposalIds;

    // --- Structs ---

    struct UserProfile {
        string metadataURI; // IPFS hash or URL for profile details (e.g., PFP, bio)
        address delegator; // Address authorized to update profile metadata on behalf of owner
        mapping(uint256 => bytes32) externalIdentifiers; // idType => idHash (e.g., 1=Twitter, 2=GitHub)
        uint256[] externalIdentifierTypes; // To iterate over linked identifiers
        bool exists; // Flag to check if profile is registered
    }

    struct AttestationType {
        string name;
        string description;
        bool isRevocable; // Can the issuer revoke this attestation?
        uint256 baseWeight; // Base reputation points this attestation contributes
        uint256 decayRateBasisPoints; // Annual decay rate in basis points (e.g., 100 for 1%)
        bool exists;
    }

    struct Attestation {
        uint256 attestationTypeId;
        address owner; // The user who holds this attestation
        address issuer; // The Attestor who issued this attestation
        string metadataURI; // Dynamic metadata URI for the specific attestation instance
        uint256 issueDate;
        uint256 expirationDate; // 0 for no expiration
        bool isRevoked;
        bool isChallenged; // Marked true if under dispute, affects score calculation
    }

    struct AttestorProposal {
        address newAttestor;
        string reasonURI;
        uint256 votesFor;
        uint256 votesAgainst;
        mapping(address => bool) hasVoted; // Voter address => true
        bool executed;
        bool passed;
        uint256 proposalEndTime;
    }

    // --- Mappings ---

    mapping(address => UserProfile) public profiles;
    mapping(uint256 => AttestationType) public attestationTypes; // attestationTypeId => AttestationType
    mapping(uint256 => Attestation) public attestations; // tokenId => Attestation

    mapping(address => bool) public isAttestor; // address => true if approved Attestor
    mapping(address => mapping(uint256 => bool)) public attestorPermissions; // attestor => attestationTypeId => canIssue
    mapping(address => mapping(uint256 => bool)) public attestorRevokePermissions; // attestor => attestationTypeId => canRevoke

    mapping(uint256 => AttestorProposal) public attestorProposals;
    mapping(address => uint256) public voterWeights; // For DAO voting power

    mapping(address => uint256[]) private userAttestationTokens; // user address => array of owned tokenIds

    uint256 public attestationIssuanceFee; // Fee (in native currency) to issue an attestation
    uint256 public proposalVotingPeriod = 3 days; // Default voting period for attestor proposals

    // --- Events ---

    event ProfileRegistered(address indexed user, string metadataURI);
    event ProfileMetadataUpdated(address indexed user, string newMetadataURI);
    event ExternalIdentifierLinked(address indexed user, uint256 indexed idType, bytes32 idHash);
    event ProfileDelegatorSet(address indexed user, address indexed delegator);

    event AttestationTypeCreated(uint256 indexed typeId, string name, uint256 baseWeight, uint256 decayRate);
    event AttestationIssued(uint256 indexed tokenId, uint256 indexed typeId, address indexed to, address issuer, string metadataURI);
    event AttestationRevoked(uint256 indexed tokenId, address indexed revoker);
    event AttestationMetadataUpdated(uint256 indexed tokenId, string newMetadataURI);
    event AttestationExpirationUpdated(uint256 indexed tokenId, uint256 newExpirationDate);
    event AttestationRequested(address indexed user, uint256 indexed attestationTypeId, address indexed fromAttestor, string requestDetailsURI);
    event AttestationChallenged(uint256 indexed tokenId, address indexed challenger, string reasonURI);

    event AttestorProposed(uint256 indexed proposalId, address indexed newAttestor, address proposer, string reasonURI);
    event AttestorVoteCast(uint256 indexed proposalId, address indexed voter, bool support, uint256 weight);
    event AttestorProposalExecuted(uint256 indexed proposalId, address indexed newAttestor, bool passed);
    event AttestorPermissionsUpdated(address indexed attestor, uint256 indexed attestationTypeId, bool canIssue, bool canRevoke);
    event AttestorRoleRenounced(address indexed attestor);

    event AttestationTypeWeightAdjusted(uint256 indexed typeId, uint256 newBaseWeight);
    event VoterWeightSet(address indexed voter, uint256 weight);

    event AttestationIssuanceFeeSet(uint256 newFee);
    event FeesWithdrawn(address indexed to, uint256 amount);

    // --- Constructor ---

    constructor() ERC721("AuraNexusAttestation", "AURA") Ownable(msg.sender) {
        contractURI = "ipfs://QmYOurUniqueContractURIHash"; // Default contract URI
        // Set initial owner as a voter with significant weight to bootstrap governance
        voterWeights[msg.sender] = 1000;
        emit VoterWeightSet(msg.sender, 1000);
    }

    // --- I. Core Infrastructure & Access Control (3 Functions) ---

    /**
     * @notice Updates the contract-level metadata URI.
     * @dev Only callable by the contract owner.
     * @param _newURI The new URI for contract metadata (e.g., IPFS hash).
     */
    function updateContractURI(string memory _newURI) external onlyOwner {
        contractURI = _newURI;
    }

    // `renounceOwnership()` is inherited from Ownable, making it 3 functions.

    // --- II. User Profiles & Identity Management (5 Functions) ---

    /**
     * @notice Registers a new user profile for `msg.sender`.
     * @dev Each address can only register one profile.
     * @param _metadataURI URI pointing to the user's profile metadata (e.g., PFP, bio, linked social profiles).
     */
    function registerProfile(string memory _metadataURI) external {
        require(!profiles[msg.sender].exists, "Profile already registered");
        profiles[msg.sender].metadataURI = _metadataURI;
        profiles[msg.sender].exists = true;
        emit ProfileRegistered(msg.sender, _metadataURI);
    }

    /**
     * @notice Updates the metadata URI for the caller's *own* profile.
     * @dev Callable only by the profile owner (`msg.sender`).
     * @param _newMetadataURI The new URI for the profile metadata.
     */
    function updateProfileMetadata(string memory _newMetadataURI) external {
        require(profiles[msg.sender].exists, "Profile not registered");
        profiles[msg.sender].metadataURI = _newMetadataURI;
        emit ProfileMetadataUpdated(msg.sender, _newMetadataURI);
    }

    /**
     * @notice Allows a designated delegator to update another user's profile metadata.
     * @dev Callable only by the address that `_user` has explicitly set as their delegator.
     * @param _user The address of the profile owner whose profile is being updated.
     * @param _newMetadataURI The new URI for the profile metadata.
     */
    function updateDelegatedProfileMetadata(address _user, string memory _newMetadataURI) external {
        require(profiles[_user].exists, "Profile not registered");
        require(profiles[_user].delegator == msg.sender, "Caller is not the designated delegator for this profile");
        profiles[_user].metadataURI = _newMetadataURI;
        emit ProfileMetadataUpdated(_user, _newMetadataURI); // Emit event for the _user, not msg.sender
    }

    /**
     * @notice Links an off-chain identifier hash to the caller's profile.
     * @dev Allows users to associate external proofs of identity (e.g., hashes of social media profiles, email hashes).
     *      Each `_idType` can only have one `_idHash` linked.
     * @param _idHash The hash of the external identifier.
     * @param _idType A numerical type representing the kind of identifier (e.g., 1=Twitter, 2=GitHub, 3=Email).
     */
    function linkExternalIdentifier(bytes32 _idHash, uint256 _idType) external {
        require(profiles[msg.sender].exists, "Profile not registered");
        require(profiles[msg.sender].externalIdentifiers[_idType] == bytes32(0), "Identifier type already linked");
        profiles[msg.sender].externalIdentifiers[_idType] = _idHash;
        profiles[msg.sender].externalIdentifierTypes.push(_idType); // For easy iteration
        emit ExternalIdentifierLinked(msg.sender, _idType, _idHash);
    }

    /**
     * @notice Designates an address that can update the caller's profile metadata via `updateDelegatedProfileMetadata`.
     * @dev Allows for delegated profile management. Set to `address(0)` to remove delegation.
     * @param _delegator The address to grant delegation rights to.
     */
    function setProfileDelegator(address _delegator) external {
        require(profiles[msg.sender].exists, "Profile not registered");
        profiles[msg.sender].delegator = _delegator;
        emit ProfileDelegatorSet(msg.sender, _delegator);
    }

    /**
     * @notice Retrieves details of a user profile.
     * @param _user The address of the user profile to query.
     * @return metadataURI URI for profile details.
     * @return delegator The address designated as delegator.
     * @return externalIdHashes Array of linked external identifier hashes.
     * @return externalIdTypes Array of linked external identifier types.
     * @return profileExists True if the profile is registered.
     */
    function getUserProfile(address _user) external view override returns (
        string memory metadataURI,
        address delegator,
        bytes32[] memory externalIdHashes,
        uint256[] memory externalIdTypes,
        bool profileExists
    ) {
        UserProfile storage profile = profiles[_user];
        if (!profile.exists) {
            return ("", address(0), new bytes32[](0), new uint256[](0), false);
        }

        uint256[] memory types = profile.externalIdentifierTypes;
        bytes32[] memory hashes = new bytes32[](types.length);
        for (uint i = 0; i < types.length; i++) {
            hashes[i] = profile.externalIdentifiers[types[i]];
        }

        return (profile.metadataURI, profile.delegator, hashes, types, profile.exists);
    }

    // --- III. Attestation (NFT) Management (7 Functions) ---

    /**
     * @notice Creates a new type of attestation that Attestors can issue.
     * @dev Only callable by the contract owner.
     * @param _name The name of the attestation type (e.g., "Developer L3").
     * @param _description A detailed description of this attestation type.
     * @param _isRevocable True if the issuer can revoke instances of this attestation type.
     * @param _baseWeight The base reputation points this attestation type contributes to a user's score.
     * @param _decayRateBasisPoints The annual decay rate in basis points (e.g., 100 for 1% per year).
     */
    function createAttestationType(
        string memory _name,
        string memory _description,
        bool _isRevocable,
        uint256 _baseWeight,
        uint256 _decayRateBasisPoints
    ) external onlyOwner {
        _attestationTypeIds.increment();
        uint256 newTypeId = _attestationTypeIds.current();
        attestationTypes[newTypeId] = AttestationType({
            name: _name,
            description: _description,
            isRevocable: _isRevocable,
            baseWeight: _baseWeight,
            decayRateBasisPoints: _decayRateBasisPoints,
            exists: true
        });
        emit AttestationTypeCreated(newTypeId, _name, _baseWeight, _decayRateBasisPoints);
    }

    /**
     * @notice Issues a new non-transferable Attestation NFT to a user.
     * @dev Only callable by an approved Attestor with permission for the specific attestation type.
     *      Requires payment of `attestationIssuanceFee`.
     * @param _to The address of the recipient. Must have a registered profile.
     * @param _attestationTypeId The ID of the attestation type to issue.
     * @param _attestationMetadataURI URI for this specific attestation instance's metadata (can be dynamic).
     * @param _expirationDate Unix timestamp when the attestation expires (0 for no expiration).
     */
    function issueAttestation(
        address _to,
        uint256 _attestationTypeId,
        string memory _attestationMetadataURI,
        uint256 _expirationDate
    ) external payable {
        require(isAttestor[msg.sender], "Not an approved Attestor");
        require(attestationTypes[_attestationTypeId].exists, "Attestation type does not exist");
        require(attestorPermissions[msg.sender][_attestationTypeId], "Attestor not permitted to issue this type");
        require(msg.value >= attestationIssuanceFee, "Insufficient fee for attestation issuance");
        require(profiles[_to].exists, "Recipient profile not registered");

        _attestationTokenIds.increment();
        uint256 newTokenId = _attestationTokenIds.current();

        _mint(_to, newTokenId); // Mints the ERC721 token
        // The ERC721 _beforeTokenTransfer hook will prevent actual transferability.

        attestations[newTokenId] = Attestation({
            attestationTypeId: _attestationTypeId,
            owner: _to,
            issuer: msg.sender,
            metadataURI: _attestationMetadataURI,
            issueDate: block.timestamp,
            expirationDate: _expirationDate,
            isRevoked: false,
            isChallenged: false
        });

        userAttestationTokens[_to].push(newTokenId); // Track tokens per user for efficient lookup

        emit AttestationIssued(newTokenId, _attestationTypeId, _to, msg.sender, _attestationMetadataURI);
    }

    /**
     * @notice Revokes an issued Attestation NFT, marking it as invalid.
     * @dev Callable by the original issuer (if `isRevocable` for type and has revoke permission) or by the contract owner.
     * @param _tokenId The ID of the attestation token to revoke.
     */
    function revokeAttestation(uint256 _tokenId) external {
        Attestation storage attestation = attestations[_tokenId];
        require(attestation.owner != address(0), "Attestation does not exist"); // Checks if token exists
        require(!attestation.isRevoked, "Attestation already revoked");

        bool hasPermission = msg.sender == owner() ||
                             (attestation.issuer == msg.sender &&
                              attestationTypes[attestation.attestationTypeId].isRevocable &&
                              attestorRevokePermissions[msg.sender][attestation.attestationTypeId]);

        require(hasPermission, "Not authorized to revoke this attestation");

        attestation.isRevoked = true;
        emit AttestationRevoked(_tokenId, msg.sender);
    }

    /**
     * @notice Updates the metadata URI for a specific Attestation NFT, enabling dynamic NFTs.
     * @dev Only callable by the original issuer.
     * @param _tokenId The ID of the attestation token to update.
     * @param _newMetadataURI The new URI for the attestation metadata.
     */
    function updateAttestationMetadata(uint256 _tokenId, string memory _newMetadataURI) external {
        Attestation storage attestation = attestations[_tokenId];
        require(attestation.owner != address(0), "Attestation does not exist");
        require(attestation.issuer == msg.sender, "Only the issuer can update attestation metadata");

        attestation.metadataURI = _newMetadataURI;
        emit AttestationMetadataUpdated(_tokenId, _newMetadataURI);
    }

    /**
     * @notice Adjusts the expiration date of an Attestation NFT.
     * @dev Only callable by the original issuer.
     * @param _tokenId The ID of the attestation token to update.
     * @param _newExpirationDate The new Unix timestamp for expiration (0 for no expiration).
     */
    function updateAttestationExpiration(uint256 _tokenId, uint256 _newExpirationDate) external {
        Attestation storage attestation = attestations[_tokenId];
        require(attestation.owner != address(0), "Attestation does not exist");
        require(attestation.issuer == msg.sender, "Only the issuer can update attestation expiration");

        attestation.expirationDate = _newExpirationDate;
        emit AttestationExpirationUpdated(_tokenId, _newExpirationDate);
    }

    /**
     * @notice Allows a user to formally request an attestation from a designated Attestor.
     * @dev This is an on-chain signaling mechanism. The Attestor would then need to `issueAttestation`.
     * @param _attestationTypeId The ID of the attestation type being requested.
     * @param _fromAttestor The address of the Attestor the request is directed to.
     * @param _requestDetailsURI URI pointing to details about the request.
     */
    function requestAttestation(
        uint256 _attestationTypeId,
        address _fromAttestor,
        string memory _requestDetailsURI
    ) external {
        require(profiles[msg.sender].exists, "Profile not registered");
        require(attestationTypes[_attestationTypeId].exists, "Attestation type does not exist");
        require(isAttestor[_fromAttestor], "Requested address is not an Attestor");

        emit AttestationRequested(msg.sender, _attestationTypeId, _fromAttestor, _requestDetailsURI);
    }

    /**
     * @notice Retrieves details of a specific attestation NFT.
     * @param _tokenId The ID of the attestation token.
     * @return attestationTypeId The ID of the attestation type.
     * @return owner The address of the current owner.
     * @return issuer The address of the issuer.
     * @return metadataURI The metadata URI of the attestation.
     * @return issueDate The timestamp when the attestation was issued.
     * @return expirationDate The timestamp when the attestation expires (0 if never).
     * @return isRevoked True if the attestation has been revoked.
     * @return isChallenged True if the attestation is currently challenged.
     */
    function getAttestationDetails(uint256 _tokenId) external view override returns (
        uint256 attestationTypeId,
        address owner,
        address issuer,
        string memory metadataURI,
        uint256 issueDate,
        uint256 expirationDate,
        bool isRevoked,
        bool isChallenged
    ) {
        Attestation storage attestation = attestations[_tokenId];
        require(attestation.owner != address(0), "Attestation does not exist"); // Checks if token exists
        return (
            attestation.attestationTypeId,
            attestation.owner,
            attestation.issuer,
            attestation.metadataURI,
            attestation.issueDate,
            attestation.expirationDate,
            attestation.isRevoked,
            attestation.isChallenged
        );
    }

    /**
     * @notice Returns an array of token IDs for all attestations owned by a user.
     * @param _user The address of the user.
     * @return An array of `uint256` token IDs.
     */
    function getUserAttestationTokens(address _user) external view returns (uint256[] memory) {
        return userAttestationTokens[_user];
    }

    // --- Internal ERC721 Overrides (for non-transferable NFTs) ---

    /**
     * @dev Overrides ERC721's _beforeTokenTransfer hook to prevent any transfers
     *      of Attestation NFTs once they are minted, making them soulbound-like.
     */
    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize) internal pure override {
        // Allow minting (from address(0)) and burning (to address(0)), but no actual transfers.
        if (from != address(0) && to != address(0)) {
            revert("Attestation NFTs are non-transferable (soulbound-like)");
        }
    }

    // --- IV. Decentralized Attestor Governance (5 Functions) ---

    /**
     * @notice Initiates a governance proposal to add a new Attestor.
     * @dev Only callable by an address with a non-zero voting weight.
     * @param _newAttestor The address proposed to become an Attestor.
     * @param _reasonURI URI explaining the reason for the proposal (e.g., proposal details on IPFS).
     * @return proposalId The ID of the newly created proposal.
     */
    function proposeAttestor(address _newAttestor, string memory _reasonURI) external returns (uint256) {
        require(voterWeights[msg.sender] > 0, "Only voters can propose");
        require(!isAttestor[_newAttestor], "Address is already an Attestor");

        _attestorProposalIds.increment();
        uint256 proposalId = _attestorProposalIds.current();

        attestorProposals[proposalId] = AttestorProposal({
            newAttestor: _newAttestor,
            reasonURI: _reasonURI,
            votesFor: 0,
            votesAgainst: 0,
            executed: false,
            passed: false,
            proposalEndTime: block.timestamp.add(proposalVotingPeriod)
        });

        emit AttestorProposed(proposalId, _newAttestor, msg.sender, _reasonURI);
        return proposalId;
    }

    /**
     * @notice Allows whitelisted voters to cast their weighted vote on an Attestor proposal.
     * @dev Each voter can only vote once per proposal.
     * @param _proposalId The ID of the proposal.
     * @param _support True for 'for' vote, false for 'against' vote.
     */
    function voteOnAttestorProposal(uint256 _proposalId, bool _support) external {
        AttestorProposal storage proposal = attestorProposals[_proposalId];
        require(proposal.newAttestor != address(0), "Proposal does not exist");
        require(block.timestamp <= proposal.proposalEndTime, "Voting period has ended");
        require(voterWeights[msg.sender] > 0, "Caller has no voting weight");
        require(!proposal.hasVoted[msg.sender], "Already voted on this proposal");

        if (_support) {
            proposal.votesFor = proposal.votesFor.add(voterWeights[msg.sender]);
        } else {
            proposal.votesAgainst = proposal.votesAgainst.add(voterWeights[msg.sender]);
        }
        proposal.hasVoted[msg.sender] = true;
        emit AttestorVoteCast(_proposalId, msg.sender, _support, voterWeights[msg.sender]);
    }

    /**
     * @notice Executes a passed Attestor proposal.
     * @dev Can be called by anyone after the voting period ends. Requires a simple majority vote (votesFor > votesAgainst).
     * @param _proposalId The ID of the proposal to execute.
     */
    function executeAttestorProposal(uint256 _proposalId) external {
        AttestorProposal storage proposal = attestorProposals[_proposalId];
        require(proposal.newAttestor != address(0), "Proposal does not exist");
        require(block.timestamp > proposal.proposalEndTime, "Voting period has not ended");
        require(!proposal.executed, "Proposal already executed");

        proposal.executed = true;
        if (proposal.votesFor > proposal.votesAgainst) {
            isAttestor[proposal.newAttestor] = true;
            proposal.passed = true;
        } else {
            // If it fails, explicitly ensure they are not an attestor (if they were somehow)
            isAttestor[proposal.newAttestor] = false;
            proposal.passed = false;
        }
        emit AttestorProposalExecuted(_proposalId, proposal.newAttestor, proposal.passed);
    }

    /**
     * @notice Sets the permissions for an Attestor to issue or revoke specific attestation types.
     * @dev Only callable by the contract owner.
     * @param _attestor The address of the Attestor.
     * @param _attestationTypeId The ID of the attestation type.
     * @param _canIssue True if the Attestor can issue this type, false otherwise.
     * @param _canRevoke True if the Attestor can revoke this type, false otherwise.
     */
    function setAttestorPermissions(
        address _attestor,
        uint256 _attestationTypeId,
        bool _canIssue,
        bool _canRevoke
    ) external onlyOwner {
        require(isAttestor[_attestor], "Address is not an Attestor");
        require(attestationTypes[_attestationTypeId].exists, "Attestation type does not exist");
        attestorPermissions[_attestor][_attestationTypeId] = _canIssue;
        attestorRevokePermissions[_attestor][_attestationTypeId] = _canRevoke;
        emit AttestorPermissionsUpdated(_attestor, _attestationTypeId, _canIssue, _canRevoke);
    }

    /**
     * @notice Allows an Attestor to voluntarily renounce their role.
     * @dev This removes them from the `isAttestor` list.
     */
    function renounceAttestorRole() external {
        require(isAttestor[msg.sender], "Caller is not an Attestor");
        isAttestor[msg.sender] = false;
        // Optionally, also clear all permissions associated with this attestor
        // For simplicity, we just mark them as not an attestor globally.
        emit AttestorRoleRenounced(msg.sender);
    }

    // --- V. Reputation Scoring & Verification (4 Functions) ---

    /**
     * @notice Calculates the aggregate reputation score for a given user.
     * @dev Iterates through all valid attestations held by the user, applying weights and annual decay.
     *      Returns 0 if the profile is not registered or if the user has no valid attestations.
     *      Challenged or revoked attestations do not contribute to the score.
     * @param _user The address of the user.
     * @return The calculated reputation score.
     */
    function calculateUserReputationScore(address _user) external view override returns (uint256) {
        if (!profiles[_user].exists) {
            return 0;
        }

        uint256 totalScore = 0;
        uint256[] memory tokens = userAttestationTokens[_user];

        for (uint256 i = 0; i < tokens.length; i++) {
            uint256 tokenId = tokens[i];
            Attestation storage attestation = attestations[tokenId];
            AttestationType storage attestationType = attestationTypes[attestation.attestationTypeId];

            // Skip if revoked, challenged, or expired
            if (attestation.isRevoked || attestation.isChallenged) {
                continue;
            }
            if (attestation.expirationDate != 0 && block.timestamp > attestation.expirationDate) {
                continue;
            }

            uint256 currentWeight = attestationType.baseWeight;

            // Apply annual decay based on decayRateBasisPoints
            if (attestationType.decayRateBasisPoints > 0 && attestation.issueDate < block.timestamp) {
                uint256 yearsPassed = (block.timestamp - attestation.issueDate) / 31536000; // Seconds in a year
                uint256 decayFactor = 10000; // Represents 100% in basis points
                for (uint256 j = 0; j < yearsPassed; j++) {
                    decayFactor = decayFactor.mul(10000 - attestationType.decayRateBasisPoints).div(10000);
                }
                currentWeight = currentWeight.mul(decayFactor).div(10000);
            }
            totalScore = totalScore.add(currentWeight);
        }
        return totalScore;
    }

    /**
     * @notice Retrieves the details of an attestation type.
     * @dev Public view function to query attestation type configurations.
     * @param _attestationTypeId The ID of the attestation type.
     * @return name The name of the attestation type.
     * @return description A description of the attestation type.
     * @return isRevocable True if this type can be revoked.
     * @return baseWeight The base reputation weight.
     * @return decayRateBasisPoints The annual decay rate in basis points.
     */
    function getAttestationTypeDetails(uint256 _attestationTypeId)
        external
        view
        returns (string memory name, string memory description, bool isRevocable, uint256 baseWeight, uint256 decayRateBasisPoints)
    {
        AttestationType storage attestationType = attestationTypes[_attestationTypeId];
        require(attestationType.exists, "Attestation type does not exist");
        return (
            attestationType.name,
            attestationType.description,
            attestationType.isRevocable,
            attestationType.baseWeight,
            attestationType.decayRateBasisPoints
        );
    }

    /**
     * @notice Adjusts the base reputation weight for a specific attestation type.
     * @dev Only callable by the contract owner. This affects future score calculations.
     * @param _attestationTypeId The ID of the attestation type.
     * @param _newBaseWeight The new base reputation weight.
     */
    function adjustAttestationTypeWeight(uint256 _attestationTypeId, uint256 _newBaseWeight) external onlyOwner {
        require(attestationTypes[_attestationTypeId].exists, "Attestation type does not exist");
        attestationTypes[_attestationTypeId].baseWeight = _newBaseWeight;
        emit AttestationTypeWeightAdjusted(_attestationTypeId, _newBaseWeight);
    }

    /**
     * @notice Checks if a user holds at least one valid attestation of a specific type.
     * @dev Useful for external contracts to verify credentials for access control or specific features.
     *      A valid attestation is one that is not revoked, not challenged, and not expired.
     * @param _user The address of the user.
     * @param _attestationTypeId The ID of the attestation type to check for.
     * @return True if the user holds a valid attestation of the specified type, false otherwise.
     */
    function verifyAttestationPresence(address _user, uint256 _attestationTypeId) external view override returns (bool) {
        if (!profiles[_user].exists) {
            return false;
        }

        uint256[] memory tokens = userAttestationTokens[_user];
        for (uint256 i = 0; i < tokens.length; i++) {
            uint256 tokenId = tokens[i];
            Attestation storage attestation = attestations[tokenId];

            if (attestation.attestationTypeId == _attestationTypeId &&
                !attestation.isRevoked &&
                !attestation.isChallenged &&
                (attestation.expirationDate == 0 || block.timestamp <= attestation.expirationDate)) {
                return true;
            }
        }
        return false;
    }

    /**
     * @notice Allows any user to formally challenge the validity of an attestation.
     * @dev This marks the attestation as challenged and emits an event for off-chain or governance review.
     *      Challenged attestations do not contribute to a user's reputation score.
     * @param _tokenId The ID of the attestation token to challenge.
     * @param _challengeReasonURI URI pointing to details about the challenge.
     */
    function challengeAttestation(uint256 _tokenId, string memory _challengeReasonURI) external {
        Attestation storage attestation = attestations[_tokenId];
        require(attestation.owner != address(0), "Attestation does not exist");
        require(!attestation.isChallenged, "Attestation already challenged");
        // Optionally, add a fee to challenge to prevent spam
        // require(msg.value >= challengeFee, "Insufficient fee to challenge attestation");

        attestation.isChallenged = true;
        emit AttestationChallenged(_tokenId, msg.sender, _challengeReasonURI);
    }

    // --- VI. System Economics & Maintenance (3 Functions) ---

    /**
     * @notice Sets the fee required (in native currency, e.g., ETH) for Attestors to issue new attestations.
     * @dev Only callable by the contract owner.
     * @param _fee The new issuance fee in wei.
     */
    function setAttestationIssuanceFee(uint256 _fee) external onlyOwner {
        attestationIssuanceFee = _fee;
        emit AttestationIssuanceFeeSet(_fee);
    }

    /**
     * @notice Allows the contract owner to withdraw collected fees from the contract.
     * @dev Only callable by the contract owner.
     * @param _to The address to send the collected fees to.
     */
    function withdrawFees(address _to) external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No fees to withdraw");
        (bool success,) = _to.call{value: balance}("");
        require(success, "Failed to withdraw fees");
        emit FeesWithdrawn(_to, balance);
    }

    /**
     * @notice Sets the voting power for a specific address in Attestor proposals.
     * @dev Only callable by the contract owner. Used to bootstrap or manage DAO voters.
     * @param _voter The address whose voting weight is being set.
     * @param _weight The new voting weight for the address. Set to 0 to remove voting power.
     */
    function setVoterWeight(address _voter, uint256 _weight) external onlyOwner {
        voterWeights[_voter] = _weight;
        emit VoterWeightSet(_voter, _weight);
    }
}
```