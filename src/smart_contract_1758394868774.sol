This smart contract, **AuraverseAttestationNetwork (AAN)**, is designed to create a decentralized, verifiable, and dynamic on-chain professional/skill profile system. It leverages Soulbound Tokens (SBTs) for user identities, allows permissioned validators to issue verifiable attestations, integrates with external oracles for AI-driven skill assessments, and computes a dynamic "Aura Score" representing a user's on-chain reputation. The SBTs have dynamic metadata that evolves with the user's attestations and score.

---

## AuraverseAttestationNetwork (AAN) - Smart Contract Outline

**Contract Name:** `AuraverseAttestationNetwork`

**Core Concepts:**
1.  **Soulbound Tokens (SBTs):** Non-transferable tokens representing individual profiles.
2.  **Dynamic Metadata:** SBTs metadata (e.g., visual representation) evolves based on attestations, Aura Score, and claimed badges.
3.  **Verifiable Attestations:** Claims about skills or achievements issued by trusted, staked validators.
4.  **Decentralized Reputation (Aura Score):** A dynamically calculated score reflecting a profile's overall credibility and validated expertise.
5.  **Permissioned & Staked Validators:** Entities that issue attestations, requiring a stake to ensure good behavior and accountability.
6.  **Challenge Mechanism:** A process to dispute false or outdated attestations.
7.  **AI/Oracle Integration:** Facilitates external, potentially AI-driven, skill assessments for specific categories.
8.  **Modular Skill Categories:** Configurable parameters for different types of skills, allowing for tailored attestation rules.
9.  **Delegated Profile Management:** Allows profile owners to grant temporary management rights to trusted third parties.
10. **On-chain Fees:** For protocol sustainability.

---

## Function Summary:

**I. Core Infrastructure & Access Control (Owner-restricted)**
1.  `constructor()`: Initializes the contract, setting the deployer as the owner.
2.  `updateOwner(address _newOwner)`: Transfers ownership of the contract.
3.  `pauseProtocol()`: Pauses all critical contract functionalities (e.g., attestation, profile updates).
4.  `unpauseProtocol()`: Unpauses the protocol, re-enabling functionalities.
5.  `setAttestationFee(uint256 _fee)`: Sets the fee required to issue a new attestation.
6.  `withdrawFees(address _to, uint256 _amount)`: Allows the owner to withdraw collected attestation fees.

**II. Profile & AuraSBT Management (User-centric)**
7.  `registerProfile(string calldata _username, string calldata _initialBio)`: Mints a new AuraSBT (ERC721) for `msg.sender`, creating their unique on-chain profile.
8.  `updateProfileDetails(string calldata _newBio, string calldata _newAvatarURI)`: Allows a profile owner (or delegate) to update their profile's bio and avatar URI.
9.  `delegateProfileManagement(address _delegatee)`: Grants a specified address permission to manage the `msg.sender`'s profile.
10. `revokeProfileManagement(address _delegatee)`: Revokes management permissions from a delegatee.
11. `getProfile(address _profileOwner)`: Retrieves the comprehensive profile data for a given address.
12. `burnAuraSBT(address _profileOwner)`: Allows a profile owner to burn their own AuraSBT, effectively deleting their profile and associated data.

**III. Validator & Attestation Management (Validator & User interaction)**
13. `registerValidator(string calldata _name, string calldata _description)`: Allows an entity to register as a potential validator, requiring a stake in native tokens.
14. `approveValidator(address _validatorAddress)`: Owner approves a registered validator, making them active.
15. `deactivateValidator(address _validatorAddress)`: Owner deactivates an active validator.
16. `issueAttestation(address _profileOwner, string calldata _skillCategory, string calldata _claimHash, uint256 _expiresAt)`: An approved validator issues a verifiable attestation for a profile owner in a specific skill category. Requires payment of `attestationFee`.
17. `revokeAttestation(bytes32 _attestationId)`: Allows the validator who issued an attestation to revoke it.
18. `challengeAttestation(bytes32 _attestationId, string calldata _reasonHash)`: Allows any user or validator to formally challenge an existing attestation.
19. `resolveChallenge(bytes32 _attestationId, bool _isChallengeValid)`: Owner/Admin resolves a challenge, either validating the attestation or marking it as invalid.
20. `getAttestation(bytes32 _attestationId)`: Retrieves details for a specific attestation.
21. `getProfileAttestations(address _profileOwner)`: Returns a list of all active, valid attestations associated with a profile.

**IV. Skill Categories & Dynamic Aura Score (Configurable & Calculated)**
22. `configureSkillCategory(string calldata _categoryName, bool _requiresOracle, uint256 _minValidatorStake, uint256 _attestationWeight)`: Owner defines and configures new skill categories, including whether they require oracle assessment and their impact on Aura Score.
23. `getAuraScore(address _profileOwner)`: Calculates and returns the dynamic Aura Score for a profile based on all its valid, active attestations.
24. `requestOracleAssessment(address _profileOwner, string calldata _skillCategory)`: Initiates a request for an external oracle to perform an AI-driven skill assessment for a profile in a specific category (simulated by emitting an event).
25. `submitOracleAssessmentResult(bytes32 _requestId, address _profileOwner, string calldata _skillCategory, uint256 _assessmentScore, string calldata _reportHash)`: An authorized oracle submits the result of an AI assessment, which can update a profile's skill data.

**V. ERC721 Standard Functions**
26. `tokenURI(uint256 tokenId)`: Returns the dynamic metadata URI for an AuraSBT, which generates JSON reflecting the profile's current state, attestations, and Aura Score.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/**
 * @title AuraverseAttestationNetwork (AAN)
 * @dev A decentralized protocol for verifiable on-chain professional/skill profiles using Soulbound Tokens (SBTs).
 *      Features include dynamic SBT metadata, permissioned validators, AI/oracle integration, and a dynamic reputation system (Aura Score).
 *
 * @author Your Name/Team
 * @notice This contract is for demonstration purposes and illustrates advanced concepts.
 *         It may not be production-ready without extensive audits and optimizations.
 */
contract AuraverseAttestationNetwork is ERC721, Ownable, Pausable, ReentrancyGuard {
    using Strings for uint256;
    using Counters for Counters.Counter;

    // --- Events ---
    event ProfileRegistered(address indexed profileOwner, uint256 tokenId, string username);
    event ProfileUpdated(address indexed profileOwner, string newBio, string newAvatarURI);
    event ProfileBurned(address indexed profileOwner, uint256 tokenId);
    event DelegateSet(address indexed profileOwner, address indexed delegatee);
    event DelegateRevoked(address indexed profileOwner, address indexed delegatee);

    event ValidatorRegistered(address indexed validatorAddress, string name, uint256 stake);
    event ValidatorApproved(address indexed validatorAddress);
    event ValidatorDeactivated(address indexed validatorAddress);

    event AttestationIssued(bytes32 indexed attestationId, address indexed profileOwner, address indexed validator, string skillCategory);
    event AttestationRevoked(bytes32 indexed attestationId, address indexed validator);
    event AttestationChallenged(bytes32 indexed attestationId, address indexed challenger, string reasonHash);
    event ChallengeResolved(bytes32 indexed attestationId, bool isChallengeValid);

    event SkillCategoryConfigured(string indexed categoryName, bool requiresOracle, uint256 minValidatorStake, uint256 attestationWeight);
    event OracleAssessmentRequested(bytes32 indexed requestId, address indexed profileOwner, string skillCategory);
    event OracleAssessmentResultSubmitted(bytes32 indexed requestId, address indexed profileOwner, string skillCategory, uint256 assessmentScore);

    event AttestationFeeSet(uint256 newFee);
    event FeesWithdrawn(address indexed to, uint256 amount);

    // --- Structs ---
    struct Profile {
        string username;
        string bio;
        string avatarURI;
        uint256 createdAt;
        uint256 lastUpdated;
        bool exists;
    }

    struct Attestation {
        address profileOwner;
        address validator;
        string skillCategory; // e.g., "Solidity Development", "AI Ethics"
        string claimHash;     // IPFS hash of the detailed claim or evidence
        uint256 issuedAt;
        uint256 expiresAt;    // 0 for never expires
        bool isValid;         // Can be false if challenged and resolved as invalid, or revoked
        bool exists;          // True if attestation was ever issued
    }

    struct Validator {
        string name;
        string description;
        uint256 stake;
        bool isActive;
        bool isApproved;
        uint256 registeredAt;
        uint256 lastActivity; // To track validator engagement
    }

    struct SkillCategory {
        bool requiresOracle;      // Does this category require an external oracle for assessment?
        uint256 minValidatorStake; // Minimum stake required for a validator to issue attestations in this category
        uint256 attestationWeight; // Multiplier for Aura Score calculation (e.g., higher weight for critical skills)
        bool exists;
    }

    // --- State Variables ---
    Counters.Counter private _tokenIdCounter;

    // Mapping from profile owner address to Profile struct
    mapping(address => Profile) public profiles;
    // Mapping from profile owner address to their AuraSBT tokenId
    mapping(address => uint256) public profileOwnerToTokenId;
    // Mapping from AuraSBT tokenId to profile owner address
    mapping(uint256 => address) public tokenIdToProfileOwner;
    // Mapping from profile owner to authorized delegatees
    mapping(address => mapping(address => bool)) public profileDelegates;

    // Mapping from attestationId (hash of attestation data) to Attestation struct
    mapping(bytes32 => Attestation) public attestations;
    // Mapping from profile owner to list of their attestation IDs
    mapping(address => bytes32[]) public profileAttestations;

    // Mapping from validator address to Validator struct
    mapping(address => Validator) public validators;
    // Mapping from validator address to list of attestation IDs they issued
    mapping(address => bytes32[]) public validatorIssuedAttestations;

    // Mapping from skill category name to SkillCategory struct
    mapping(string => SkillCategory) public skillCategories;

    // Mapping for current oracle requests (request ID to profile owner)
    mapping(bytes32 => address) public activeOracleRequests;

    // Global attestation fee
    uint256 public attestationFee;

    // --- Custom Errors ---
    error ProfileAlreadyRegistered();
    error ProfileNotRegistered();
    error NotProfileOwnerOrDelegate();
    error AttestationFeeNotPaid();
    error InvalidValidator();
    error ValidatorNotApproved();
    error AttestationNotFound();
    error AttestationAlreadyChallenged();
    error AttestationNotChallenged();
    error AttestationCannotBeRevoked();
    error NotAttestationIssuer();
    error CategoryNotFound();
    error OracleAssessmentNotRequired();
    error NoActiveOracleRequest();
    error InvalidOracleSignature(); // Placeholder for actual oracle integration
    error ZeroAddressNotAllowed();
    error NothingToWithdraw();
    error InsufficientBalance();
    error CategoryRequiresOracleAssessment();
    error ValidatorStakeTooLowForCategory();
    error ProfileDelegationInvalid();
    error DelegateAlreadyExists();
    error DelegateDoesNotExist();
    error SelfDelegationNotAllowed();
    error ValidatorAlreadyApproved();
    error ValidatorAlreadyDeactivated();

    // --- Modifiers ---
    modifier onlyProfileOwnerOrDelegate(address _profileOwner) {
        if (msg.sender != _profileOwner && !profileDelegates[_profileOwner][msg.sender]) {
            revert NotProfileOwnerOrDelegate();
        }
        _;
    }

    modifier onlyApprovedValidator() {
        if (!validators[msg.sender].exists || !validators[msg.sender].isApproved || !validators[msg.sender].isActive) {
            revert InvalidValidator();
        }
        _;
    }

    modifier onlyPausableState(bool _isPaused) {
        if (paused() != _isPaused) {
            revert Pausable.EnforcedPause(); // Or Pausable.ExpectedPause()
        }
        _;
    }

    /**
     * @dev Constructor to initialize the ERC721 contract.
     */
    constructor() ERC721("Auraverse Attestation Network SBT", "AAN-SBT") Ownable(msg.sender) {
        attestationFee = 0.001 ether; // Default fee
        // Configure a default skill category
        configureSkillCategory("General Knowledge", false, 0, 100);
        configureSkillCategory("Technical Skill", false, 0.01 ether, 200);
        configureSkillCategory("Soft Skill", false, 0.005 ether, 150);
    }

    // --- I. Core Infrastructure & Access Control ---

    /**
     * @dev Transfers ownership of the contract.
     * @param _newOwner The address of the new owner.
     */
    function updateOwner(address _newOwner) public virtual onlyOwner {
        if (_newOwner == address(0)) revert ZeroAddressNotAllowed();
        transferOwnership(_newOwner); // OpenZeppelin's Ownable method
    }

    /**
     * @dev Pauses all critical contract functionalities.
     *      Only callable by the owner.
     */
    function pauseProtocol() public virtual onlyOwner nonReentrant {
        _pause();
    }

    /**
     * @dev Unpauses the protocol, re-enabling functionalities.
     *      Only callable by the owner.
     */
    function unpauseProtocol() public virtual onlyOwner nonReentrant {
        _unpause();
    }

    /**
     * @dev Sets the fee required to issue a new attestation.
     *      Only callable by the owner.
     * @param _fee The new attestation fee in native tokens (e.g., Wei).
     */
    function setAttestationFee(uint256 _fee) public virtual onlyOwner {
        attestationFee = _fee;
        emit AttestationFeeSet(_fee);
    }

    /**
     * @dev Allows the owner to withdraw collected attestation fees.
     *      Only callable by the owner.
     * @param _to The address to send the collected fees to.
     * @param _amount The amount of fees to withdraw.
     */
    function withdrawFees(address _to, uint256 _amount) public virtual onlyOwner nonReentrant {
        if (_to == address(0)) revert ZeroAddressNotAllowed();
        if (_amount == 0) revert NothingToWithdraw();
        if (address(this).balance < _amount) revert InsufficientBalance();

        (bool success,) = _to.call{value: _amount}("");
        require(success, "Withdrawal failed");
        emit FeesWithdrawn(_to, _amount);
    }

    // --- II. Profile & AuraSBT Management ---

    /**
     * @dev Registers a new profile and mints a Soulbound Token (SBT) for `msg.sender`.
     *      An SBT cannot be transferred, ensuring unique identity.
     * @param _username The desired username for the profile.
     * @param _initialBio An initial biography or description for the profile.
     */
    function registerProfile(string calldata _username, string calldata _initialBio)
        public
        nonReentrant
        whenNotPaused
    {
        if (profiles[msg.sender].exists) {
            revert ProfileAlreadyRegistered();
        }

        _tokenIdCounter.increment();
        uint256 newTokenId = _tokenIdCounter.current();

        // Mint the SBT - non-transferable by design (no ERC721 transfer methods allowed)
        _mint(msg.sender, newTokenId);

        profiles[msg.sender] = Profile({
            username: _username,
            bio: _initialBio,
            avatarURI: "", // Can be updated later
            createdAt: block.timestamp,
            lastUpdated: block.timestamp,
            exists: true
        });
        profileOwnerToTokenId[msg.sender] = newTokenId;
        tokenIdToProfileOwner[newTokenId] = msg.sender;

        emit ProfileRegistered(msg.sender, newTokenId, _username);
    }

    /**
     * @dev Updates the details (bio, avatar URI) of an existing profile.
     *      Only callable by the profile owner or an authorized delegate.
     * @param _newBio The updated biography.
     * @param _newAvatarURI The updated URI for the profile's avatar image.
     */
    function updateProfileDetails(string calldata _newBio, string calldata _newAvatarURI)
        public
        nonReentrant
        whenNotPaused
        onlyProfileOwnerOrDelegate(msg.sender)
    {
        if (!profiles[msg.sender].exists) {
            revert ProfileNotRegistered();
        }

        profiles[msg.sender].bio = _newBio;
        profiles[msg.sender].avatarURI = _newAvatarURI;
        profiles[msg.sender].lastUpdated = block.timestamp;

        emit ProfileUpdated(msg.sender, _newBio, _newAvatarURI);
    }

    /**
     * @dev Grants another address the permission to manage the `msg.sender`'s profile.
     * @param _delegatee The address to grant management rights to.
     */
    function delegateProfileManagement(address _delegatee) public nonReentrant {
        if (!profiles[msg.sender].exists) revert ProfileNotRegistered();
        if (_delegatee == address(0)) revert ZeroAddressNotAllowed();
        if (_delegatee == msg.sender) revert SelfDelegationNotAllowed();
        if (profileDelegates[msg.sender][_delegatee]) revert DelegateAlreadyExists();

        profileDelegates[msg.sender][_delegatee] = true;
        emit DelegateSet(msg.sender, _delegatee);
    }

    /**
     * @dev Revokes management permissions from a previously authorized delegate.
     * @param _delegatee The address whose management rights are to be revoked.
     */
    function revokeProfileManagement(address _delegatee) public nonReentrant {
        if (!profiles[msg.sender].exists) revert ProfileNotRegistered();
        if (!profileDelegates[msg.sender][_delegatee]) revert DelegateDoesNotExist();

        profileDelegates[msg.sender][_delegatee] = false;
        emit DelegateRevoked(msg.sender, _delegatee);
    }

    /**
     * @dev Retrieves the comprehensive profile data for a given address.
     * @param _profileOwner The address of the profile owner.
     * @return A tuple containing profile details (username, bio, avatarURI, createdAt, lastUpdated, exists).
     */
    function getProfile(address _profileOwner)
        public
        view
        returns (string memory username, string memory bio, string memory avatarURI, uint256 createdAt, uint256 lastUpdated, bool exists)
    {
        Profile storage p = profiles[_profileOwner];
        return (p.username, p.bio, p.avatarURI, p.createdAt, p.lastUpdated, p.exists);
    }

    /**
     * @dev Allows a profile owner to burn their own AuraSBT, effectively deleting their profile.
     *      This is a permanent action for Soulbound Tokens.
     * @param _profileOwner The address of the profile owner whose SBT is to be burned.
     */
    function burnAuraSBT(address _profileOwner)
        public
        nonReentrant
        whenNotPaused
        onlyProfileOwnerOrDelegate(_profileOwner)
    {
        if (!profiles[_profileOwner].exists) {
            revert ProfileNotRegistered();
        }

        uint256 tokenId = profileOwnerToTokenId[_profileOwner];

        // Burn the SBT
        _burn(tokenId);

        // Clear profile data
        delete profiles[_profileOwner];
        delete profileOwnerToTokenId[_profileOwner];
        delete tokenIdToProfileOwner[tokenId];
        // Note: Attestations issued to this profile remain on chain but are "inactive" due to profile non-existence.
        // For a full cleanup, a more complex system would be needed.

        emit ProfileBurned(_profileOwner, tokenId);
    }

    // --- III. Validator & Attestation Management ---

    /**
     * @dev Allows an entity to register as a potential validator.
     *      Requires staking native tokens as collateral for accountability.
     * @param _name The name of the validator.
     * @param _description A brief description of the validator.
     */
    function registerValidator(string calldata _name, string calldata _description)
        public
        payable
        nonReentrant
        whenNotPaused
    {
        if (validators[msg.sender].exists) { // Use 'exists' field to check if validator struct was initialized
            revert InvalidValidator(); // Already registered
        }

        // Default min stake for registration, can be configured later
        uint256 defaultMinValidatorStake = 0.1 ether;
        if (msg.value < defaultMinValidatorStake) {
            revert InsufficientBalance();
        }

        validators[msg.sender] = Validator({
            name: _name,
            description: _description,
            stake: msg.value,
            isActive: true, // Registered means active (not yet approved)
            isApproved: false, // Requires owner approval
            registeredAt: block.timestamp,
            lastActivity: block.timestamp
        });
        emit ValidatorRegistered(msg.sender, _name, msg.value);
    }

    /**
     * @dev Owner approves a registered validator, making them eligible to issue attestations.
     * @param _validatorAddress The address of the validator to approve.
     */
    function approveValidator(address _validatorAddress) public virtual onlyOwner nonReentrant {
        Validator storage v = validators[_validatorAddress];
        if (!v.exists) revert InvalidValidator();
        if (v.isApproved) revert ValidatorAlreadyApproved();

        v.isApproved = true;
        v.isActive = true; // Ensure active upon approval
        emit ValidatorApproved(_validatorAddress);
    }

    /**
     * @dev Owner deactivates an active validator.
     *      Deactivated validators cannot issue new attestations, but their existing attestations remain valid unless revoked/challenged.
     * @param _validatorAddress The address of the validator to deactivate.
     */
    function deactivateValidator(address _validatorAddress) public virtual onlyOwner nonReentrant {
        Validator storage v = validators[_validatorAddress];
        if (!v.exists) revert InvalidValidator();
        if (!v.isActive) revert ValidatorAlreadyDeactivated();

        v.isActive = false;
        // Consider a mechanism to penalize/slash stake here for severe misconduct
        emit ValidatorDeactivated(_validatorAddress);
    }

    /**
     * @dev Allows an approved validator to issue a verifiable attestation for a profile owner.
     *      Requires payment of the `attestationFee`.
     * @param _profileOwner The address of the profile owner receiving the attestation.
     * @param _skillCategory The category of the skill or achievement being attested.
     * @param _claimHash IPFS hash or similar URI pointing to detailed evidence or description of the claim.
     * @param _expiresAt Unix timestamp when the attestation expires (0 for never).
     */
    function issueAttestation(
        address _profileOwner,
        string calldata _skillCategory,
        string calldata _claimHash,
        uint256 _expiresAt
    ) public payable nonReentrant whenNotPaused onlyApprovedValidator {
        if (!profiles[_profileOwner].exists) {
            revert ProfileNotRegistered();
        }
        if (msg.value < attestationFee) {
            revert AttestationFeeNotPaid();
        }

        SkillCategory storage sc = skillCategories[_skillCategory];
        if (!sc.exists) revert CategoryNotFound();
        if (validators[msg.sender].stake < sc.minValidatorStake) revert ValidatorStakeTooLowForCategory();
        if (sc.requiresOracle) revert CategoryRequiresOracleAssessment(); // Cannot issue directly if oracle is required

        bytes32 attestationId = keccak256(abi.encodePacked(_profileOwner, msg.sender, _skillCategory, _claimHash, block.timestamp));

        attestations[attestationId] = Attestation({
            profileOwner: _profileOwner,
            validator: msg.sender,
            skillCategory: _skillCategory,
            claimHash: _claimHash,
            issuedAt: block.timestamp,
            expiresAt: _expiresAt,
            isValid: true,
            exists: true
        });

        profileAttestations[_profileOwner].push(attestationId);
        validatorIssuedAttestations[msg.sender].push(attestationId);

        validators[msg.sender].lastActivity = block.timestamp; // Update validator activity

        emit AttestationIssued(attestationId, _profileOwner, msg.sender, _skillCategory);
    }

    /**
     * @dev Allows the validator who issued an attestation to revoke it.
     * @param _attestationId The unique ID of the attestation to revoke.
     */
    function revokeAttestation(bytes32 _attestationId) public nonReentrant whenNotPaused {
        Attestation storage a = attestations[_attestationId];
        if (!a.exists) revert AttestationNotFound();
        if (a.validator != msg.sender) revert NotAttestationIssuer();
        if (!a.isValid) revert AttestationCannotBeRevoked(); // Already invalid

        a.isValid = false; // Mark as invalid
        emit AttestationRevoked(_attestationId, msg.sender);
    }

    /**
     * @dev Allows any user or validator to formally challenge an existing attestation.
     *      Initiates a dispute resolution process.
     * @param _attestationId The unique ID of the attestation being challenged.
     * @param _reasonHash IPFS hash or similar URI pointing to the evidence/reason for the challenge.
     */
    function challengeAttestation(bytes32 _attestationId, string calldata _reasonHash)
        public
        nonReentrant
        whenNotPaused
    {
        Attestation storage a = attestations[_attestationId];
        if (!a.exists) revert AttestationNotFound();
        if (!a.isValid) revert AttestationAlreadyChallenged(); // Cannot challenge an invalid/revoked attestation

        // In a real system, challenging might involve a bond, and a separate state for 'under challenge'
        // For simplicity, we just mark it as under challenge and emit event.
        // The resolution relies on the owner.
        a.isValid = false; // Temporarily mark as invalid during challenge
        emit AttestationChallenged(_attestationId, msg.sender, _reasonHash);
    }

    /**
     * @dev Owner/Admin resolves a challenge to an attestation.
     *      Decides whether the challenge is valid or not, updating the attestation's status.
     * @param _attestationId The unique ID of the attestation under challenge.
     * @param _isChallengeValid True if the challenge is upheld (attestation remains invalid), false if rejected (attestation becomes valid again).
     */
    function resolveChallenge(bytes32 _attestationId, bool _isChallengeValid) public virtual onlyOwner nonReentrant {
        Attestation storage a = attestations[_attestationId];
        if (!a.exists) revert AttestationNotFound();
        // If it was already marked isValid, it means it wasn't challenged or already resolved.
        // This check helps prevent resolving unchallenged attestations.
        if (a.isValid && !a.exists) revert AttestationNotChallenged(); // Only resolve if it was previously marked invalid by a challenge

        a.isValid = !_isChallengeValid; // If challenge is valid, attestation remains invalid. If invalid, attestation becomes valid.
        emit ChallengeResolved(_attestationId, _isChallengeValid);
    }

    /**
     * @dev Retrieves details for a specific attestation.
     * @param _attestationId The unique ID of the attestation.
     * @return A tuple containing attestation details.
     */
    function getAttestation(bytes32 _attestationId)
        public
        view
        returns (address profileOwner, address validator, string memory skillCategory, string memory claimHash, uint256 issuedAt, uint256 expiresAt, bool isValid)
    {
        Attestation storage a = attestations[_attestationId];
        return (a.profileOwner, a.validator, a.skillCategory, a.claimHash, a.issuedAt, a.expiresAt, a.isValid && a.exists && (a.expiresAt == 0 || a.expiresAt > block.timestamp));
    }

    /**
     * @dev Retrieves a list of all active, valid attestations associated with a profile.
     * @param _profileOwner The address of the profile owner.
     * @return An array of active attestation IDs.
     */
    function getProfileAttestations(address _profileOwner) public view returns (bytes32[] memory) {
        bytes32[] storage rawAttestations = profileAttestations[_profileOwner];
        uint256 count = 0;
        for (uint256 i = 0; i < rawAttestations.length; i++) {
            Attestation storage a = attestations[rawAttestations[i]];
            if (a.exists && a.isValid && (a.expiresAt == 0 || a.expiresAt > block.timestamp)) {
                count++;
            }
        }

        bytes32[] memory activeAttestations = new bytes32[](count);
        uint256 currentIdx = 0;
        for (uint256 i = 0; i < rawAttestations.length; i++) {
            Attestation storage a = attestations[rawAttestations[i]];
            if (a.exists && a.isValid && (a.expiresAt == 0 || a.expiresAt > block.timestamp)) {
                activeAttestations[currentIdx] = rawAttestations[i];
                currentIdx++;
            }
        }
        return activeAttestations;
    }

    // --- IV. Skill Categories & Dynamic Aura Score ---

    /**
     * @dev Owner defines and configures new skill categories.
     *      Each category has specific rules regarding oracle requirements, validator stake, and its weight in Aura Score calculation.
     * @param _categoryName The unique name of the skill category.
     * @param _requiresOracle True if this category needs external oracle assessment for attestation.
     * @param _minValidatorStake Minimum stake required for validators to issue attestations in this category.
     * @param _attestationWeight Multiplier for Aura Score calculation (higher weight for more impactful skills).
     */
    function configureSkillCategory(
        string calldata _categoryName,
        bool _requiresOracle,
        uint256 _minValidatorStake,
        uint256 _attestationWeight
    ) public virtual onlyOwner nonReentrant {
        skillCategories[_categoryName] = SkillCategory({
            requiresOracle: _requiresOracle,
            minValidatorStake: _minValidatorStake,
            attestationWeight: _attestationWeight,
            exists: true
        });
        emit SkillCategoryConfigured(_categoryName, _requiresOracle, _minValidatorStake, _attestationWeight);
    }

    /**
     * @dev Calculates and returns the current dynamic Aura Score for a profile.
     *      The score is based on the quantity, validity, recency, and weight of its attestations.
     * @param _profileOwner The address of the profile owner.
     * @return The calculated Aura Score.
     */
    function getAuraScore(address _profileOwner) public view returns (uint256) {
        if (!profiles[_profileOwner].exists) {
            return 0; // No profile, no score
        }

        uint256 score = 0;
        bytes32[] memory profileAts = profileAttestations[_profileOwner];
        uint256 currentTimestamp = block.timestamp;

        for (uint256 i = 0; i < profileAts.length; i++) {
            Attestation storage att = attestations[profileAts[i]];
            if (att.exists && att.isValid && (att.expiresAt == 0 || att.expiresAt > currentTimestamp)) {
                SkillCategory storage sc = skillCategories[att.skillCategory];
                if (sc.exists) {
                    uint256 baseScore = 100; // Base value for each valid attestation
                    uint256 categoryWeightedScore = baseScore * sc.attestationWeight / 100; // Apply category weight

                    // Apply time decay (example: decay by 1% per year after 1 year)
                    uint256 yearsSinceIssued = (currentTimestamp - att.issuedAt) / 1 years;
                    if (yearsSinceIssued > 1) {
                        uint256 decayFactor = (100 - (yearsSinceIssued - 1)) > 0 ? (100 - (yearsSinceIssued - 1)) : 0; // Max 100% decay over 100 years
                        categoryWeightedScore = categoryWeightedScore * decayFactor / 100;
                    }

                    score += categoryWeightedScore;
                }
            }
        }
        return score;
    }

    /**
     * @dev Initiates a request for an external oracle to perform an AI-driven skill assessment.
     *      This is simulated by emitting an event that an off-chain oracle service would listen to.
     * @param _profileOwner The address of the profile owner requesting the assessment.
     * @param _skillCategory The skill category for which an assessment is requested.
     */
    function requestOracleAssessment(address _profileOwner, string calldata _skillCategory)
        public
        nonReentrant
        whenNotPaused
        onlyProfileOwnerOrDelegate(_profileOwner)
    {
        if (!profiles[_profileOwner].exists) revert ProfileNotRegistered();
        SkillCategory storage sc = skillCategories[_skillCategory];
        if (!sc.exists) revert CategoryNotFound();
        if (!sc.requiresOracle) revert OracleAssessmentNotRequired();

        // Generate a unique request ID
        bytes32 requestId = keccak256(abi.encodePacked(_profileOwner, _skillCategory, block.timestamp, msg.sender));
        activeOracleRequests[requestId] = _profileOwner;

        emit OracleAssessmentRequested(requestId, _profileOwner, _skillCategory);
    }

    /**
     * @dev An authorized oracle submits the result of an AI assessment.
     *      This function would be called by a trusted oracle service (e.g., Chainlink external adapter).
     *      The result can then trigger an internal attestation or profile update.
     * @param _requestId The ID of the original oracle request.
     * @param _profileOwner The profile owner for whom the assessment was done.
     * @param _skillCategory The skill category assessed.
     * @param _assessmentScore The score from the AI assessment.
     * @param _reportHash IPFS hash of the detailed assessment report.
     */
    function submitOracleAssessmentResult(
        bytes32 _requestId,
        address _profileOwner,
        string calldata _skillCategory,
        uint256 _assessmentScore,
        string calldata _reportHash
    ) public nonReentrant whenNotPaused {
        // In a real scenario, this would be restricted to a trusted oracle address.
        // For demonstration, let's assume `msg.sender` is the authorized oracle.
        // Oracles typically prove their identity via Chainlink VRF or similar on-chain verification.
        // require(msg.sender == trustedOracleAddress, "Only trusted oracle can submit results");

        if (activeOracleRequests[_requestId] != _profileOwner) revert NoActiveOracleRequest();
        if (!profiles[_profileOwner].exists) revert ProfileNotRegistered();

        // Potentially issue an attestation based on oracle result
        bytes32 attestationId = keccak256(abi.encodePacked(_profileOwner, address(this), _skillCategory, _reportHash, block.timestamp));
        attestations[attestationId] = Attestation({
            profileOwner: _profileOwner,
            validator: address(this), // Contract itself acts as validator for oracle results
            skillCategory: _skillCategory,
            claimHash: _reportHash,
            issuedAt: block.timestamp,
            expiresAt: 0, // Oracle assessments might be permanent or have their own renewal
            isValid: true,
            exists: true
        });

        profileAttestations[_profileOwner].push(attestationId);
        // Note: This contract is technically 'issuing' an attestation based on oracle data.
        // This makes `address(this)` an implicit validator for oracle-driven categories.

        delete activeOracleRequests[_requestId]; // Mark request as resolved

        emit OracleAssessmentResultSubmitted(_requestId, _profileOwner, _skillCategory, _assessmentScore);
        emit AttestationIssued(attestationId, _profileOwner, address(this), _skillCategory);
    }

    // --- V. ERC721 Standard Functions & Dynamic Metadata ---

    /**
     * @dev Returns the base URI for the SBT metadata.
     *      This could point to an API that dynamically generates JSON metadata based on on-chain state.
     * @return The base URI string.
     */
    function _baseURI() internal pure override returns (string memory) {
        return "https://auraverse.network/api/sbt/"; // Example API endpoint
    }

    /**
     * @dev Returns the dynamic metadata URI for an AuraSBT.
     *      This function generates a URI that, when resolved, will provide JSON metadata reflecting
     *      the profile's current state, attestations, and Aura Score.
     *      It's designed to make the SBT's visual and textual representation evolve on-chain.
     * @param tokenId The ID of the AuraSBT.
     * @return The URI for the SBT's metadata.
     */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        if (!_exists(tokenId)) {
            revert ERC721NonexistentToken(tokenId);
        }

        address profileOwner = tokenIdToProfileOwner[tokenId];
        Profile storage p = profiles[profileOwner];
        uint256 auraScore = getAuraScore(profileOwner);
        bytes32[] memory currentAttestations = getProfileAttestations(profileOwner);

        // In a real application, the baseURI would point to a service that takes tokenId
        // (and potentially other on-chain data via parameters) and generates a dynamic JSON.
        // The JSON would include a dynamically generated image (SVG) or an image URI based on
        // the profile's stats, attestations, and Aura Score.

        // Example of what the JSON might look like (generated off-chain by the baseURI service):
        // {
        //   "name": "Auraverse Profile: " + p.username,
        //   "description": p.bio,
        //   "image": "ipfs://<dynamic_image_hash_based_on_score_and_attestations>",
        //   "attributes": [
        //     {"trait_type": "Aura Score", "value": auraScore},
        //     {"trait_type": "Attestations Count", "value": currentAttestations.length},
        //     {"trait_type": "Primary Skill", "value": "Solidity Dev (example)"},
        //     {"trait_type": "Last Updated", "value": p.lastUpdated}
        //   ]
        // }

        return string(abi.encodePacked(_baseURI(), tokenId.toString()));
    }

    /**
     * @dev The following standard ERC721 `_transfer` function is explicitly
     *      made `private` or removed to ensure the SBT is non-transferable.
     *      Since we're using a Soulbound Token, no transfer is allowed.
     */
    function _transfer(address from, address to, uint256 tokenId) internal pure override {
        // Soulbound Tokens are non-transferable.
        // Any attempt to transfer will be blocked by simply not implementing a public transfer function
        // or by explicitly reverting here if an internal call somehow reaches it.
        revert("AAN-SBT: Soulbound tokens are non-transferable.");
    }

    // Override `approve` and `setApprovalForAll` to prevent any transfer capabilities
    function approve(address to, uint256 tokenId) public pure override {
        revert("AAN-SBT: Approval is not allowed for Soulbound Tokens.");
    }

    function setApprovalForAll(address operator, bool approved) public pure override {
        revert("AAN-SBT: Approval for all is not allowed for Soulbound Tokens.");
    }

    function getApproved(uint256 tokenId) public pure override returns (address) {
        // Return zero address for compatibility, but no actual approval can exist.
        return address(0);
    }

    function isApprovedForAll(address owner, address operator) public pure override returns (bool) {
        // No operator can be approved for all for SBTs.
        return false;
    }

    // Helper function to check if a validator has been initialized
    function getValidatorExists(address _validatorAddress) public view returns (bool) {
        return validators[_validatorAddress].exists;
    }
}
```