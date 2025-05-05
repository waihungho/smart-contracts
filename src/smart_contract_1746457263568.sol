Okay, let's design a smart contract around a concept of a "Soul-Bound Identity and Attestation Registry". This concept is trendy (related to SBTs - Soulbound Tokens), allows for complex interactions (attestations, delegations, potential proofs), and we can build in unique features beyond simple non-transferable tokens.

Here's the plan:

1.  **Concept:** A non-transferable digital identity (`SoulBoundIdentity`) linked to an address. This identity can accumulate verifiable claims (`Attestations`) issued by itself or others. The system allows for delegation of attestation issuance rights and potentially integrates with zero-knowledge proofs for privacy-preserving claims.
2.  **Advanced Features:**
    *   **Soulbound Nature:** Identities and Attestations are linked to a specific identity ID and cannot be transferred.
    *   **Structured Attestations:** Attestations have types (skill, reputation, verification, etc.) and associated data (URI, expiry).
    *   **Scoped Delegation:** Identity holders can delegate the right to issue *specific types* of attestations *on their behalf* to other addresses for a limited time.
    *   **ZK-Proof Integration (Simulated):** A function exists to issue attestations *only* after verifying a submitted ZK-proof (e.g., proof of age, proof of unique personhood from an external protocol). We will simulate the verifier call.
    *   **Endorsement/Challenge System:** A basic mechanism for others to publicly endorse or challenge specific attestations.
    *   **Identity State:** Identities can be frozen/unfrozen by the contract owner (e.g., in case of detected malicious activity or protocol-level decisions).
3.  **Outline & Summary:** Will be placed at the top as requested.
4.  **Function Count:** Aim for well over 20 functions covering identity management, attestation management, delegation, ZK-proof interaction, and endorsement/challenge.
5.  **No Duplication:** This specific combination of features (Soulbound Identity + Structured Attestations + Scoped Delegation + ZK-Proof Hook + Endorsement/Challenge) is not a standard open-source template. Individual parts exist, but the integrated system will be unique.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title SoulBoundIdentity - Advanced Non-Transferable Identity and Attestation Registry
 * @author YourName (or a pseudonym)
 * @notice This contract manages non-transferable digital identities and verifiable attestations linked to them.
 * It incorporates features like structured attestations, scoped delegation of issuance rights,
 * a hook for ZK-proof verification to issue attestations, and a basic endorsement/challenge system.
 * Identities and Attestations are Soul-Bound (non-transferable).
 */

/**
 * @dev Outline:
 * 1. State Variables: Counters, Mappings for Identities, Attestations, Delegations, Endorsements/Challenges, ZK Verifier address.
 * 2. Data Structures: Structs for Identity, Attestation, Delegation.
 * 3. Events: Signaling key state changes.
 * 4. Access Control: Ownership, Identity Holder checks, Attestation Issuer/Delegatee checks.
 * 5. Identity Management: Registering, retrieving, freezing/unfreezing identities.
 * 6. Attestation Management: Issuing (by contract owner, identity holder, delegatee), revoking, retrieving, validating attestations.
 * 7. Delegation: Granting/revoking rights to issue specific attestation types for an identity.
 * 8. ZK-Proof Integration: Function to verify a proof via an external contract and issue an attestation upon success.
 * 9. Endorsement/Challenge System: Functions to endorse/challenge attestations and query counts/status.
 * 10. Helper/View Functions: Retrieving total counts, checking statuses, resolving type descriptions.
 */

/**
 * @dev Function Summary (27 Functions):
 *
 * --- Identity Management ---
 * 1.  constructor() - Sets contract owner.
 * 2.  registerIdentity(address owner) - Registers a new SoulBound Identity for an address (callable by owner or potentially self-service under rules).
 * 3.  getIdentityByAddress(address owner) view - Retrieves the identity ID for a given address.
 * 4.  getIdentityById(uint256 identityId) view - Retrieves details of a specific identity.
 * 5.  isRegistered(address owner) view - Checks if an address has a registered identity.
 * 6.  freezeIdentity(uint256 identityId) - Freezes an identity (prevents new attestations, invalidates existing ones). Owner only.
 * 7.  unfreezeIdentity(uint256 identityId) - Unfreezes a previously frozen identity. Owner only.
 * 8.  transferOwnership(address newOwner) - Transfers contract ownership. Standard OpenZeppelin pattern.
 *
 * --- Attestation Management ---
 * 9.  issueAttestation(uint256 identityId, uint8 attestationType, string calldata dataURI, uint64 expiry, address issuerOverride) - Issues an attestation about an identity (callable by owner, delegated delegatee, or identity holder for self-attestation types). Allows issuer override by owner.
 * 10. revokeAttestation(uint256 attestationId) - Revokes an attestation (callable by original issuer or owner).
 * 11. getAttestationDetails(uint256 attestationId) view - Retrieves details of a specific attestation.
 * 12. getIdentityAttestationIds(uint256 identityId) view - Gets the list of attestation IDs associated with an identity.
 * 13. isAttestationValid(uint256 attestationId) view - Checks if an attestation is currently valid (not revoked, not expired, identity not frozen).
 * 14. attestSelf(uint8 attestationType, string calldata dataURI, uint64 expiry) - Allows an identity holder to issue a self-attestation (restricted types).
 *
 * --- Delegation ---
 * 15. delegateAttestationIssuance(uint256 identityId, uint8 attestationType, address delegatee, uint64 expiry) - Delegates the right to issue a specific attestation type for an identity (identity holder only).
 * 16. revokeDelegation(uint256 identityId, uint8 attestationType, address delegatee) - Revokes a specific delegation (identity holder or delegatee).
 * 17. isDelegationActive(uint256 identityId, uint8 attestationType, address delegatee) view - Checks if a specific delegation is currently active.
 *
 * --- ZK-Proof Integration ---
 * 18. setVerifierAddress(address verifier) - Sets the address of the external ZK proof verifier contract. Owner only.
 * 19. verifyAndIssueZKAttestation(uint256 identityId, uint8 attestationType, string calldata dataURI, uint64 expiry, bytes calldata proof, bytes calldata publicInputs) - Verifies a ZK proof against external verifier and issues an attestation if valid. (Simplified parameters for proof/publicInputs).
 *
 * --- Endorsement / Challenge System ---
 * 20. endorseAttestation(uint256 attestationId) - Publicly endorses an attestation.
 * 21. challengeAttestation(uint256 attestationId, string calldata reason) - Publicly challenges an attestation.
 * 22. getEndorsementCount(uint256 attestationId) view - Gets the number of endorsements for an attestation.
 * 23. getChallengeCount(uint256 attestationId) view - Gets the number of challenges for an attestation.
 * 24. hasEndorsed(uint256 attestationId, address endorser) view - Checks if an address has endorsed an attestation.
 * 25. hasChallenged(uint256 attestationId, address challenger) view - Checks if an address has challenged an attestation.
 *
 * --- Helper/View Functions ---
 * 26. getTotalIdentities() view - Returns the total number of registered identities.
 * 27. getTotalAttestations() view - Returns the total number of issued attestations.
 * 28. getAttestationTypeDescription(uint8 attestationType) pure - Returns a string description for an attestation type (helper). (Oops, added one more, good!)
 */

// --- External Interface for ZK Verifier ---
// Note: Replace with the actual interface of your ZK verifier contract
interface IZKVerifier {
    function verify(bytes calldata proof, bytes calldata publicInputs) external view returns (bool);
}

contract SoulBoundIdentity {

    // --- State Variables ---
    uint256 private _identityCounter;
    uint256 private _attestationCounter;

    address private _owner; // Contract owner

    // --- Mappings ---
    mapping(address => uint256) private _addressToIdentityId; // owner address -> identity ID
    mapping(uint256 => Identity) private _identityIdToIdentity; // identity ID -> Identity struct
    mapping(uint256 => Attestation) private _attestationIdToAttestation; // attestation ID -> Attestation struct

    // identityId => delegateeAddress => attestationType => Delegation struct
    mapping(uint256 => mapping(address => mapping(uint8 => Delegation))) private _identityDelegations;

    // attestationId => endorserAddress => bool (has endorsed?)
    mapping(uint256 => mapping(address => bool)) private _attestationEndorsements;
    mapping(uint256 => uint256) private _attestationEndorsementCounts; // attestationId => count

    // attestationId => challengerAddress => bool (has challenged?)
    mapping(uint256 => mapping(address => bool)) private _attestationChallenges;
    mapping(uint256 => uint256) private _attestationChallengeCounts; // attestationId => count

    address public zkVerifierAddress; // Address of the external ZK Verifier contract

    // --- Constants / Enums ---
    enum AttestationType {
        None,              // 0 - Default/Invalid
        Generic,           // 1 - General purpose data
        SkillClaim,        // 2 - Claim about a skill
        ReputationScore,   // 3 - Represents a reputation metric
        VerificationClaim, // 4 - Proof of verification (e.g., KYC, uniqueness)
        Achievement,       // 5 - Represents an achievement
        SelfClaim,         // 6 - Claim made by the identity holder about themselves
        ZKVerifiedClaim    // 7 - Claim backed by a ZK proof verification
        // Add more types as needed
    }

    // --- Data Structures ---
    struct Identity {
        uint256 identityId; // Unique ID for the identity
        address owner; // The address controlling this identity
        bool isFrozen; // If true, attestations linked to this ID are invalid
        uint256[] attestationIds; // List of attestation IDs linked to this identity
        uint64 registeredTimestamp;
    }

    struct Attestation {
        uint256 attestationId; // Unique ID for the attestation
        uint256 identityId; // The identity this attestation is about
        address issuer; // The address that issued the attestation
        uint8 attestationType; // Type of attestation (from AttestationType enum)
        string dataURI; // URI pointing to off-chain data or metadata
        uint64 issuedTimestamp;
        uint64 expiryTimestamp; // 0 if no expiry
        bool isRevoked;
    }

    struct Delegation {
        uint256 delegatorIdentityId; // The identity ID that granted delegation
        address delegateeAddress; // The address that received delegation rights
        uint8 attestationType; // The specific type of attestation delegated (0 for all types? - let's stick to specific types for now)
        uint64 expiryTimestamp; // When the delegation expires (0 if infinite, but good practice to have expiry)
    }

    // --- Events ---
    event IdentityRegistered(uint256 indexed identityId, address indexed owner, uint64 timestamp);
    event IdentityFrozen(uint256 indexed identityId, address indexed caller, uint64 timestamp);
    event IdentityUnfrozen(uint256 indexed identityId, address indexed caller, uint64 timestamp);

    event AttestationIssued(uint256 indexed attestationId, uint256 indexed identityId, address indexed issuer, uint8 attestationType, uint64 timestamp);
    event AttestationRevoked(uint256 indexed attestationId, address indexed caller, uint64 timestamp);
    event AttestationEndorsed(uint256 indexed attestationId, uint256 indexed identityId, address indexed endorser, uint64 timestamp);
    event AttestationChallenged(uint256 indexed attestationId, uint256 indexed identityId, address indexed challenger, string reason, uint64 timestamp);

    event DelegationSet(uint256 indexed identityId, address indexed delegatee, uint8 attestationType, uint64 expiry, uint64 timestamp);
    event DelegationRevoked(uint256 indexed identityId, address indexed delegatee, uint8 attestationType, uint64 timestamp);

    event VerifierAddressUpdated(address indexed oldVerifier, address indexed newVerifier);


    // --- Access Control Modifiers ---
    modifier onlyOwner() {
        require(msg.sender == _owner, "SBI: Not the contract owner");
        _;
    }

    modifier isIdentityHolder(uint256 identityId) {
        require(_identityIdToIdentity[identityId].owner == msg.sender, "SBI: Not the identity holder");
        _;
    }

    modifier onlyAttestationIssuerOrOwner(uint256 attestationId) {
        Attestation storage attestation = _attestationIdToAttestation[attestationId];
        require(attestation.attestationId != 0, "SBI: Attestation not found");
        require(msg.sender == attestation.issuer || msg.sender == _owner, "SBI: Not the attestation issuer or contract owner");
        _;
    }

    modifier isValidAttestationIssuer(uint256 identityId, uint8 attestationType) {
        Identity storage identity = _identityIdToIdentity[identityId];
        require(identity.identityId != 0, "SBI: Identity not found");

        bool isOwner = msg.sender == _owner;
        bool isIdentityOwner = msg.sender == identity.owner;
        bool isDelegatee = isDelegationActive(identityId, attestationType, msg.sender);

        require(isOwner || isIdentityOwner || isDelegatee, "SBI: Not authorized to issue this attestation type for this identity");

        // Add restrictions for self-attestation type if needed (e.g., only identity owner can issue SelfClaim)
        if (attestationType == uint8(AttestationType.SelfClaim)) {
             require(isIdentityOwner, "SBI: Only identity owner can issue SelfClaim attestation");
             require(!isOwner && !isDelegatee, "SBI: Contract owner or delegatee cannot issue SelfClaim for others"); // Or adjust logic if owner can act on behalf
        } else if (attestationType == uint8(AttestationType.ZKVerifiedClaim)) {
             require(isOwner || isDelegatee, "SBI: Only owner or delegatee can issue ZKVerifiedClaim"); // Typically issued after verification by a trusted entity
             require(!isIdentityOwner, "SBI: Identity owner cannot issue ZKVerifiedClaim directly"); // ZK claim implies verification by external entity
        }
        // Add other type-specific issuer restrictions here

        _;
    }


    // --- Constructor ---
    constructor() {
        _owner = msg.sender;
        _identityCounter = 1; // Start ID from 1
        _attestationCounter = 1; // Start ID from 1
    }

    // --- Ownership Standard (Simplified) ---
    function owner() public view returns (address) {
        return _owner;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "SBI: New owner is the zero address");
        _owner = newOwner;
        // No event needed for simplicity, could add Ownable from OpenZeppelin if desired
    }

    // --- Identity Management ---

    /**
     * @notice Registers a new SoulBound Identity for an address.
     * @param owner The address that will control the new identity.
     * @dev Callable by contract owner or potentially self-service (if added logic allows msg.sender == owner).
     * Here, restricted to owner or if msg.sender is the owner requesting their own identity.
     */
    function registerIdentity(address owner) public {
        require(_addressToIdentityId[owner] == 0, "SBI: Address already has an identity");
        require(msg.sender == _owner || msg.sender == owner, "SBI: Not authorized to register identity for this address");

        uint256 newId = _identityCounter++;
        _identityIdToIdentity[newId] = Identity({
            identityId: newId,
            owner: owner,
            isFrozen: false,
            attestationIds: new uint256[](0),
            registeredTimestamp: uint64(block.timestamp)
        });
        _addressToIdentityId[owner] = newId;

        emit IdentityRegistered(newId, owner, uint64(block.timestamp));
    }

    /**
     * @notice Retrieves the identity ID associated with an address.
     * @param owner The address to query.
     * @return identityId The ID of the identity, or 0 if not registered.
     */
    function getIdentityByAddress(address owner) public view returns (uint256 identityId) {
        return _addressToIdentityId[owner];
    }

    /**
     * @notice Retrieves the details of a specific identity by its ID.
     * @param identityId The ID of the identity to query.
     * @return identity The Identity struct.
     */
    function getIdentityById(uint256 identityId) public view returns (Identity memory identity) {
        require(_identityIdToIdentity[identityId].identityId != 0, "SBI: Identity not found");
        return _identityIdToIdentity[identityId];
    }

    /**
     * @notice Checks if an address has a registered identity.
     * @param owner The address to check.
     * @return bool True if the address has an identity, false otherwise.
     */
    function isRegistered(address owner) public view returns (bool) {
        return _addressToIdentityId[owner] != 0;
    }

    /**
     * @notice Freezes an identity, effectively invalidating its attestations.
     * @param identityId The ID of the identity to freeze.
     * @dev Callable only by the contract owner. Frozen identities cannot issue or receive new valid attestations.
     */
    function freezeIdentity(uint256 identityId) public onlyOwner {
        Identity storage identity = _identityIdToIdentity[identityId];
        require(identity.identityId != 0, "SBI: Identity not found");
        require(!identity.isFrozen, "SBI: Identity is already frozen");

        identity.isFrozen = true;
        emit IdentityFrozen(identityId, msg.sender, uint64(block.timestamp));
    }

    /**
     * @notice Unfreezes a previously frozen identity.
     * @param identityId The ID of the identity to unfreeze.
     * @dev Callable only by the contract owner. Attestations only become valid if they haven't expired or been revoked.
     */
    function unfreezeIdentity(uint256 identityId) public onlyOwner {
        Identity storage identity = _identityIdToIdentity[identityId];
        require(identity.identityId != 0, "SBI: Identity not found");
        require(identity.isFrozen, "SBI: Identity is not frozen");

        identity.isFrozen = false;
        emit IdentityUnfrozen(identityId, msg.sender, uint64(block.timestamp));
    }

    // --- Attestation Management ---

    /**
     * @notice Issues a new attestation about a specific identity.
     * @param identityId The ID of the identity the attestation is about.
     * @param attestationType The type of attestation (from AttestationType enum).
     * @param dataURI URI pointing to off-chain data related to the attestation.
     * @param expiry When the attestation expires (0 for no expiry). Unix timestamp.
     * @param issuerOverride Allows owner to issue on behalf of someone else (use address(0) if not needed).
     * @dev Callable by contract owner, an address with delegated rights, or the identity holder for self-attestation types.
     */
    function issueAttestation(
        uint256 identityId,
        uint8 attestationType,
        string calldata dataURI,
        uint64 expiry,
        address issuerOverride
    ) public isValidAttestationIssuer(identityId, attestationType) {
         // Determine the actual issuer address
        address actualIssuer = (msg.sender == _owner && issuerOverride != address(0)) ? issuerOverride : msg.sender;

        uint256 newId = _attestationCounter++;
        _attestationIdToAttestation[newId] = Attestation({
            attestationId: newId,
            identityId: identityId,
            issuer: actualIssuer,
            attestationType: attestationType,
            dataURI: dataURI,
            issuedTimestamp: uint64(block.timestamp),
            expiryTimestamp: expiry,
            isRevoked: false
        });

        // Add attestation ID to the identity's list
        _identityIdToIdentity[identityId].attestationIds.push(newId);

        emit AttestationIssued(newId, identityId, actualIssuer, attestationType, uint64(block.timestamp));
    }

    /**
     * @notice Allows an identity holder to issue a self-attestation.
     * @param attestationType The type of self-attestation (must be allowed for self-issuance, e.g., SelfClaim).
     * @param dataURI URI pointing to off-chain data.
     * @param expiry When the attestation expires (0 for no expiry).
     * @dev Requires the caller to be a registered identity holder. Restricted to specific attestation types (handled in modifier).
     */
    function attestSelf(uint8 attestationType, string calldata dataURI, uint64 expiry) public {
        uint256 identityId = _addressToIdentityId[msg.sender];
        require(identityId != 0, "SBI: Caller does not have an identity");
        require(attestationType == uint8(AttestationType.SelfClaim), "SBI: Only SelfClaim type allowed for self-attestation directly");

        // Use the main issue function with caller as issuer and no override
        issueAttestation(identityId, attestationType, dataURI, expiry, address(0));
    }


    /**
     * @notice Revokes an existing attestation.
     * @param attestationId The ID of the attestation to revoke.
     * @dev Callable by the original issuer or the contract owner.
     */
    function revokeAttestation(uint256 attestationId) public onlyAttestationIssuerOrOwner(attestationId) {
        Attestation storage attestation = _attestationIdToAttestation[attestationId];
        require(!attestation.isRevoked, "SBI: Attestation is already revoked");

        attestation.isRevoked = true;
        // Note: Attestation ID is kept in the identity's array but marked as revoked.
        // We don't remove from array for gas efficiency. Validity check handles this.

        emit AttestationRevoked(attestationId, msg.sender, uint64(block.timestamp));
    }

    /**
     * @notice Retrieves the details of a specific attestation.
     * @param attestationId The ID of the attestation.
     * @return Attestation struct details.
     */
    function getAttestationDetails(uint256 attestationId) public view returns (Attestation memory) {
        require(_attestationIdToAttestation[attestationId].attestationId != 0, "SBI: Attestation not found");
        return _attestationIdToAttestation[attestationId];
    }

     /**
     * @notice Gets the list of attestation IDs associated with a specific identity.
     * @param identityId The ID of the identity.
     * @return attestationIds An array of attestation IDs.
     */
    function getIdentityAttestationIds(uint256 identityId) public view returns (uint256[] memory) {
         require(_identityIdToIdentity[identityId].identityId != 0, "SBI: Identity not found");
         return _identityIdToIdentity[identityId].attestationIds;
    }


    /**
     * @notice Checks if an attestation is currently considered valid.
     * @param attestationId The ID of the attestation.
     * @return bool True if valid, false otherwise.
     * @dev Validity requires: exists, not revoked, not expired, and the target identity is not frozen.
     */
    function isAttestationValid(uint256 attestationId) public view returns (bool) {
        Attestation memory attestation = _attestationIdToAttestation[attestationId];
        if (attestation.attestationId == 0 || attestation.isRevoked) {
            return false; // Attestation doesn't exist or is revoked
        }

        // Check expiry
        if (attestation.expiryTimestamp != 0 && attestation.expiryTimestamp < block.timestamp) {
            return false; // Attestation has expired
        }

        // Check if the associated identity is frozen
        Identity memory identity = _identityIdToIdentity[attestation.identityId];
        if (identity.identityId == 0 || identity.isFrozen) {
             return false; // Target identity doesn't exist or is frozen
        }

        return true; // All checks passed
    }

    // --- Delegation ---

    /**
     * @notice Delegates the right to issue a specific type of attestation for this identity to another address.
     * @param identityId The ID of the identity granting delegation.
     * @param attestationType The specific type of attestation to delegate.
     * @param delegatee The address receiving the delegation rights.
     * @param expiry When the delegation expires (0 for infinite).
     * @dev Callable only by the identity holder. Cannot delegate AttestationType.None or SelfClaim types.
     */
    function delegateAttestationIssuance(
        uint256 identityId,
        uint8 attestationType,
        address delegatee,
        uint64 expiry
    ) public isIdentityHolder(identityId) {
        require(delegatee != address(0), "SBI: Delegatee cannot be the zero address");
        require(attestationType != uint8(AttestationType.None), "SBI: Cannot delegate None type");
        require(attestationType != uint8(AttestationType.SelfClaim), "SBI: Cannot delegate SelfClaim type");
         require(attestationType != uint8(AttestationType.ZKVerifiedClaim), "SBI: ZK Verified Claim type delegation managed by owner/verifier"); // ZK claim delegation is different

        _identityDelegations[identityId][delegatee][attestationType] = Delegation({
            delegatorIdentityId: identityId,
            delegateeAddress: delegatee,
            attestationType: attestationType,
            expiryTimestamp: expiry
        });

        emit DelegationSet(identityId, delegatee, attestationType, expiry, uint64(block.timestamp));
    }

    /**
     * @notice Revokes a specific delegation.
     * @param identityId The ID of the identity that granted the delegation.
     * @param attestationType The specific type of attestation delegated.
     * @param delegatee The address whose delegation rights are being revoked.
     * @dev Callable by the identity holder (delegator) or the delegatee themselves.
     */
    function revokeDelegation(uint256 identityId, uint8 attestationType, address delegatee) public {
        Identity memory identity = _identityIdToIdentity[identityId];
        require(identity.identityId != 0, "SBI: Identity not found");
        require(msg.sender == identity.owner || msg.sender == delegatee, "SBI: Not authorized to revoke this delegation");

        Delegation storage delegation = _identityDelegations[identityId][delegatee][attestationType];
        require(delegation.delegatorIdentityId != 0, "SBI: Delegation not found"); // Check if delegation exists

        // Clear the delegation struct
        delete _identityDelegations[identityId][delegatee][attestationType];

        emit DelegationRevoked(identityId, delegatee, attestationType, uint64(block.timestamp));
    }

     /**
     * @notice Checks if a specific delegation is currently active.
     * @param identityId The ID of the delegating identity.
     * @param attestationType The attestation type delegated.
     * @param delegatee The address of the delegatee.
     * @return bool True if the delegation is active and not expired, false otherwise.
     */
    function isDelegationActive(uint256 identityId, uint8 attestationType, address delegatee) public view returns (bool) {
        Delegation memory delegation = _identityDelegations[identityId][delegatee][attestationType];

        // Check if delegation exists and is not expired
        return delegation.delegatorIdentityId != 0 &&
               (delegation.expiryTimestamp == 0 || delegation.expiryTimestamp >= block.timestamp);
    }


    // --- ZK-Proof Integration ---

    /**
     * @notice Sets the address of the external ZK proof verifier contract.
     * @param verifier The address of the verifier contract.
     * @dev Callable only by the contract owner.
     */
    function setVerifierAddress(address verifier) public onlyOwner {
        require(verifier != address(0), "SBI: Verifier address cannot be zero");
        emit VerifierAddressUpdated(zkVerifierAddress, verifier);
        zkVerifierAddress = verifier;
    }

    /**
     * @notice Verifies a submitted ZK proof and issues a ZKVerifiedClaim attestation if valid.
     * @param identityId The identity ID the attestation is for.
     * @param attestationType The type of attestation to issue (must be ZKVerifiedClaim or similar).
     * @param dataURI URI for attestation data.
     * @param expiry Expiry timestamp for the attestation.
     * @param proof ZK proof bytes.
     * @param publicInputs ZK public inputs bytes.
     * @dev Callable by the contract owner or a specifically delegated address for ZKVerifiedClaim type.
     * This function assumes `IZKVerifier` contract exists at `zkVerifierAddress`.
     * Requires `ZKVerifiedClaim` attestation type.
     */
    function verifyAndIssueZKAttestation(
        uint256 identityId,
        uint8 attestationType, // Expected to be AttestationType.ZKVerifiedClaim
        string calldata dataURI,
        uint64 expiry,
        bytes calldata proof,
        bytes calldata publicInputs
    ) public isValidAttestationIssuer(identityId, uint8(AttestationType.ZKVerifiedClaim)) {
        require(zkVerifierAddress != address(0), "SBI: ZK Verifier address not set");
        require(attestationType == uint8(AttestationType.ZKVerifiedClaim), "SBI: Can only issue ZKVerifiedClaim type with this function");

        // Call the external verifier contract
        bool success = IZKVerifier(zkVerifierAddress).verify(proof, publicInputs);
        require(success, "SBI: ZK proof verification failed");

        // Issue the attestation upon successful verification
        // Issuer is msg.sender (owner or delegatee)
        issueAttestation(identityId, attestationType, dataURI, expiry, address(0));
    }

    // --- Endorsement / Challenge System ---

    /**
     * @notice Allows any address to publicly endorse a specific attestation.
     * @param attestationId The ID of the attestation to endorse.
     * @dev Requires the attestation to exist and be currently valid. Cannot endorse the same attestation twice.
     */
    function endorseAttestation(uint256 attestationId) public {
        require(isAttestationValid(attestationId), "SBI: Attestation is not valid for endorsement");
        require(!_attestationEndorsements[attestationId][msg.sender], "SBI: Already endorsed this attestation");

        _attestationEndorsements[attestationId][msg.sender] = true;
        _attestationEndorsementCounts[attestationId]++;

        // Get identity ID for event
        uint256 identityId = _attestationIdToAttestation[attestationId].identityId;

        emit AttestationEndorsed(attestationId, identityId, msg.sender, uint64(block.timestamp));
    }

    /**
     * @notice Allows any address to publicly challenge a specific attestation.
     * @param attestationId The ID of the attestation to challenge.
     * @param reason Optional reason for the challenge.
     * @dev Requires the attestation to exist and be currently valid. Cannot challenge the same attestation twice.
     * Note: This is a social layer, the contract doesn't automatically invalidate on challenge count.
     */
    function challengeAttestation(uint256 attestationId, string calldata reason) public {
        require(isAttestationValid(attestationId), "SBI: Attestation is not valid for challenge");
        require(!_attestationChallenges[attestationId][msg.sender], "SBI: Already challenged this attestation");

        _attestationChallenges[attestationId][msg.sender] = true;
        _attestationChallengeCounts[attestationId]++;

        // Get identity ID for event
        uint256 identityId = _attestationIdToAttestation[attestationId].identityId;

        emit AttestationChallenged(attestationId, identityId, msg.sender, reason, uint64(block.timestamp));
    }

    /**
     * @notice Gets the total count of endorsements for an attestation.
     * @param attestationId The ID of the attestation.
     * @return count The number of endorsements.
     */
    function getEndorsementCount(uint256 attestationId) public view returns (uint256) {
         require(_attestationIdToAttestation[attestationId].attestationId != 0, "SBI: Attestation not found");
        return _attestationEndorsementCounts[attestationId];
    }

    /**
     * @notice Gets the total count of challenges for an attestation.
     * @param attestationId The ID of the attestation.
     * @return count The number of challenges.
     */
    function getChallengeCount(uint256 attestationId) public view returns (uint256) {
         require(_attestationIdToAttestation[attestationId].attestationId != 0, "SBI: Attestation not found");
        return _attestationChallengeCounts[attestationId];
    }

    /**
     * @notice Checks if a specific address has endorsed an attestation.
     * @param attestationId The ID of the attestation.
     * @param endorser The address to check.
     * @return bool True if the address has endorsed, false otherwise.
     */
    function hasEndorsed(uint256 attestationId, address endorser) public view returns (bool) {
        require(_attestationIdToAttestation[attestationId].attestationId != 0, "SBI: Attestation not found");
        return _attestationEndorsements[attestationId][endorser];
    }

    /**
     * @notice Checks if a specific address has challenged an attestation.
     * @param attestationId The ID of the attestation.
     * @param challenger The address to check.
     * @return bool True if the address has challenged, false otherwise.
     */
    function hasChallenged(uint256 attestationId, address challenger) public view returns (bool) {
         require(_attestationIdToAttestation[attestationId].attestationId != 0, "SBI: Attestation not found");
        return _attestationChallenges[attestationId][challenger];
    }

    // --- Helper/View Functions ---

    /**
     * @notice Returns the total number of registered identities.
     * @return total The count of identities.
     */
    function getTotalIdentities() public view returns (uint256) {
        return _identityCounter - 1; // Subtract 1 because we started at 1
    }

    /**
     * @notice Returns the total number of issued attestations.
     * @return total The count of attestations.
     */
    function getTotalAttestations() public view returns (uint256) {
        return _attestationCounter - 1; // Subtract 1 because we started at 1
    }

     /**
     * @notice Returns a string description for an attestation type enum value.
     * @param attestationType The uint8 enum value.
     * @return string Description of the type.
     */
    function getAttestationTypeDescription(uint8 attestationType) public pure returns (string memory) {
        if (attestationType == uint8(AttestationType.None)) return "None";
        if (attestationType == uint8(AttestationType.Generic)) return "Generic";
        if (attestationType == uint8(AttestationType.SkillClaim)) return "SkillClaim";
        if (attestationType == uint8(AttestationType.ReputationScore)) return "ReputationScore";
        if (attestationType == uint8(AttestationType.VerificationClaim)) return "VerificationClaim";
        if (attestationType == uint8(AttestationType.Achievement)) return "Achievement";
        if (attestationType == uint8(AttestationType.SelfClaim)) return "SelfClaim";
        if (attestationType == uint8(AttestationType.ZKVerifiedClaim)) return "ZKVerifiedClaim";
        return "Unknown";
    }
}
```