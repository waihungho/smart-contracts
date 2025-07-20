This smart contract, named **"SynergisticSkillNetwork (SSN)"**, aims to create a decentralized, on-chain reputation and skill network. It combines concepts of Soulbound Tokens (SBTs) for user identity, dynamic NFTs for evolving skill profiles, a robust attestation system for verifiable expertise, project collaboration, and an innovative "Intent-Based Skill Delegation" mechanism.

The goal is to go beyond simple token transfers or static NFTs, allowing users to build a verifiable, evolving on-chain professional profile, find collaborators, and even "lend" their attested skills for specific tasks or projects under predefined intents.

---

## **Contract Outline & Function Summary: SynergisticSkillNetwork (SSN)**

**Contract Name:** `SynergisticSkillNetwork`

**Core Concept:** A decentralized platform for building, verifying, and leveraging on-chain skill profiles. It utilizes non-transferable Profile NFTs (SBT-like) as user identities, dynamic "Skill Modules" attached to these profiles which can be attested by others, and a unique system for delegating attested skill capacity for specific on-chain intents.

---

### **Function Categories & Summaries:**

#### **I. Profile NFT Management (Soulbound Identity)**
*   **1. `mintProfileNFT(string _metadataURI)`:** Allows a unique address to mint a single, non-transferable Profile NFT, representing their on-chain identity. The `_metadataURI` points to off-chain profile data.
*   **2. `getProfileDetails(uint256 _profileId)`:** Retrieves all stored details for a given Profile NFT ID, including its owner and metadata URI.
*   **3. `getProfileIdByOwner(address _owner)`:** Returns the Profile NFT ID associated with a given owner address.
*   **4. `updateProfileMetadataURI(uint256 _profileId, string _newMetadataURI)`:** Allows the owner of a Profile NFT to update its associated metadata URI.

#### **II. Skill Schema Management (Governance-Controlled)**
*   **5. `proposeSkillSchema(string _name, string _description, string _category)`:** Allows a qualified entity (e.g., DAO member, admin) to propose a new, standardized skill type. This requires subsequent approval.
*   **6. `approveSkillSchema(uint256 _schemaId)`:** (Admin/DAO) Approves a proposed skill schema, making it available for users to attach to their profiles.
*   **7. `revokeSkillSchema(uint256 _schemaId)`:** (Admin/DAO) Deactivates an existing skill schema, preventing new attachments of that type.
*   **8. `getSkillSchemaDetails(uint256 _schemaId)`:** Retrieves details of a specific skill schema, including its name, description, category, and active status.

#### **III. Dynamic Skill Module Management (Attached to Profiles)**
*   **9. `attachSkillModule(uint256 _profileId, uint256 _schemaId)`:** Allows a Profile NFT owner to attach a specific, approved skill schema as a module to their profile. Initializes its level and reputation.
*   **10. `detachSkillModule(uint256 _skillModuleId)`:** Allows a Profile NFT owner to remove a skill module from their profile.
*   **11. `updateSkillModuleLevel(uint256 _skillModuleId)`:** Triggers a re-evaluation and potential update of a skill module's level based on its current attestation count and reputation score. (This function itself won't directly set the level, but rather trigger a recalculation based on internal logic after attestations/challenges).
*   **12. `getProfileSkills(uint256 _profileId)`:** Returns a list of all `skillModuleIds` attached to a given Profile NFT.
*   **13. `getSkillModuleDetails(uint256 _skillModuleId)`:** Retrieves all details of a specific skill module, including its associated profile, schema, level, and reputation.

#### **IV. Attestation & Validation System (Verifying Skills)**
*   **14. `attestSkill(uint256 _attesterProfileId, uint256 _targetSkillModuleId, uint8 _rating)`:** Allows an attested profile owner (`_attesterProfileId`) to vouch for another's skill module, assigning a rating (e.g., 1-5). This contributes to the target skill's reputation.
*   **15. `revokeAttestation(uint256 _attestationId)`:** Allows the original attester to revoke their previously given attestation.
*   **16. `initiateSkillChallenge(uint256 _challengerProfileId, uint256 _targetSkillModuleId, string _reasonHash)`:** Allows a profile owner to formally challenge the validity of a skill module's level or attestations on another profile. This initiates a dispute.
*   **17. `resolveSkillChallenge(uint256 _challengeId, bool _isChallengerVictorious)`:** (Admin/DAO/Oracle) Resolves a skill challenge. If the challenger is victorious, the target skill module's reputation/level might be reduced or attestations invalidated.
*   **18. `getSkillAttestations(uint256 _skillModuleId)`:** Returns a list of all attestation IDs associated with a specific skill module.

#### **V. Project Collaboration & Matching**
*   **19. `createProjectListing(string _title, string _description, uint256[] _requiredSkillSchemaIds, uint256 _rewardAmount)`:** Allows a profile owner to list a new project requiring specific skills, along with an associated reward pool.
*   **20. `applyForProjectRole(uint256 _profileId, uint256 _projectId, uint256 _skillModuleId)`:** Allows a profile owner with a relevant skill module to apply for a role in an existing project.
*   **21. `acceptProjectApplicant(uint256 _projectId, uint256 _applicantProfileId)`:** (Project Creator) Accepts an applicant for a project role.
*   **22. `completeProjectPhase(uint256 _projectId, uint256 _participantProfileId, uint256 _payoutAmount)`:** (Project Creator) Marks a phase of a project as complete for a participant and distributes a portion of rewards.

#### **VI. Advanced: Intent-Based Skill Delegation**
*   **23. `delegateSkillCapacity(uint256 _delegatorProfileId, address _delegateeAddress, uint256 _skillSchemaId, uint256 _validUntil, bytes32 _intentHash)`:** Allows a profile owner (`_delegatorProfileId`) to temporarily "lend" their attested capacity for a specific skill (`_skillSchemaId`) to another address (`_delegateeAddress`) for a limited duration (`_validUntil`) and for a predefined off-chain "intent" or task (`_intentHash`).
*   **24. `executeDelegatedTask(uint256 _delegationId, bytes32 _executedIntentHash)`:** Allows the `delegateeAddress` to "execute" a delegated task, marking the specific delegation as used or consumed. This requires matching the `_executedIntentHash` to the one stored in the delegation.
*   **25. `revokeSkillDelegation(uint256 _delegationId)`:** Allows the original delegator to revoke an active skill delegation before its `validUntil` period ends or before it's executed.
*   **26. `getDelegatedIntent(uint256 _delegationId)`:** Retrieves the details of a specific skill delegation, including delegator, delegatee, skill, and the associated intent hash.

#### **VII. Governance & Utilities**
*   **27. `setTrustedOracle(address _oracleAddress)`:** (Owner) Sets a trusted oracle address that can potentially provide external verification for skill challenges or level updates.
*   **28. `emergencyPause()`:** (Owner) Pauses critical contract functions in case of an emergency.
*   **29. `unpauseContract()`:** (Owner) Unpauses the contract after an emergency.
*   **30. `withdrawContractBalance(address _to)`:** (Owner) Allows the contract owner to withdraw any accumulated ETH from project fees or unspent rewards. (Assumes a fee mechanism or project funds held on contract).

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol"; // For profile metadataURI

/**
 * @title SynergisticSkillNetwork (SSN)
 * @dev A decentralized platform for building, verifying, and leveraging on-chain skill profiles.
 *      It combines Soulbound Tokens (SBTs) for user identity, dynamic "Skill Modules" attached
 *      to these profiles which can be attested by others, a robust attestation system for verifiable expertise,
 *      project collaboration, and an innovative "Intent-Based Skill Delegation" mechanism.
 *      The goal is to provide a comprehensive, on-chain professional profile that is dynamic,
 *      trustworthy through community attestation, and actionable through collaboration and skill delegation.
 */
contract SynergisticSkillNetwork is ERC721, Ownable, ReentrancyGuard {
    using Counters for Counters.Counter;

    // --- State Variables ---
    Counters.Counter private _profileIds;
    Counters.Counter private _skillSchemaIds;
    Counters.Counter private _skillModuleIds;
    Counters.Counter private _attestationIds;
    Counters.Counter private _challengeIds;
    Counters.Counter private _projectIds;
    Counters.Counter private _delegationIds;

    // --- Data Structures ---

    // Represents a user's on-chain identity (SBT-like)
    struct Profile {
        address owner;
        string metadataURI; // URI to IPFS or other storage for profile details
        bool exists;        // True if the profile is minted
    }
    mapping(uint256 => Profile) public profiles;
    mapping(address => uint256) public ownerToProfileId; // Maps owner address to their profile ID

    // Defines a standardized type of skill (e.g., "Solidity Development", "UI/UX Design")
    struct SkillSchema {
        string name;
        string description;
        string category;
        bool isActive; // Can be deactivated by governance
    }
    mapping(uint256 => SkillSchema) public skillSchemas;

    // A specific skill attached to a user's profile
    struct SkillModule {
        uint256 profileId;
        uint256 schemaId;
        uint256 level;          // Abstract level (e.g., 1-100), derived from reputation
        uint256 reputationScore; // Aggregated score from attestations
        uint256 attestationCount; // Number of unique attestations received
        bool attached;          // True if attached to a profile
    }
    mapping(uint256 => SkillModule) public skillModules;

    // An attestation from one profile to another's skill
    struct Attestation {
        uint256 attesterProfileId;
        uint256 targetSkillModuleId;
        uint8 rating;          // e.g., 1-5
        uint256 timestamp;
        bool isValid;          // Can be invalidated by challenges
    }
    mapping(uint256 => Attestation) public attestations;
    // Track which profile has attested which skill module to prevent multiple attestations
    mapping(uint256 => mapping(uint256 => uint256)) public profileAttestedSkill; // attesterProfileId => skillModuleId => attestationId

    // A formal challenge against a skill module's validity
    struct SkillChallenge {
        uint256 challengerProfileId;
        uint256 targetSkillModuleId;
        string reasonHash; // IPFS hash of detailed reason for challenge
        uint256 timestamp;
        bool isResolved;
        bool challengerVictorious; // Outcome of the challenge
    }
    mapping(uint256 => SkillChallenge) public skillChallenges;

    // Represents a project listed for collaboration
    struct Project {
        uint256 creatorProfileId;
        string title;
        string description;
        uint256[] requiredSkillSchemaIds; // List of skill schemas needed
        uint256 rewardAmount; // Total reward for the project (in native currency or ERC20)
        bool isCompleted;
    }
    mapping(uint256 => Project) public projects;
    mapping(uint256 => mapping(uint256 => bool)) public projectApplicants; // projectId => applicantProfileId => applied
    mapping(uint256 => mapping(uint256 => bool)) public projectParticipants; // projectId => participantProfileId => accepted

    // Represents a temporary delegation of a skill module's capacity for an intent
    struct SkillDelegation {
        uint256 delegatorProfileId; // Profile ID granting the delegation
        address delegateeAddress;   // Address that can use the delegated capacity
        uint256 skillModuleId;      // The specific skill module being delegated
        uint256 validUntil;         // Timestamp when delegation expires
        bytes32 intentHash;         // Hash representing the specific off-chain task/intent this delegation is for
        bool isActive;              // True if delegation is active and not yet executed/revoked
    }
    mapping(uint256 => SkillDelegation) public skillDelegations;

    // --- Events ---
    event ProfileMinted(uint256 indexed profileId, address indexed owner, string metadataURI);
    event ProfileMetadataUpdated(uint256 indexed profileId, string oldMetadataURI, string newMetadataURI);
    event SkillSchemaProposed(uint256 indexed schemaId, string name, string category);
    event SkillSchemaApproved(uint256 indexed schemaId);
    event SkillSchemaRevoked(uint256 indexed schemaId);
    event SkillModuleAttached(uint256 indexed profileId, uint256 indexed skillModuleId, uint256 indexed schemaId);
    event SkillModuleDetached(uint256 indexed profileId, uint256 indexed skillModuleId);
    event SkillModuleLevelUpdated(uint256 indexed skillModuleId, uint256 oldLevel, uint256 newLevel, uint256 newReputation);
    event SkillAttested(uint256 indexed attestationId, uint256 indexed attesterProfileId, uint256 indexed targetSkillModuleId, uint8 rating);
    event AttestationRevoked(uint256 indexed attestationId);
    event SkillChallengeInitiated(uint256 indexed challengeId, uint256 indexed challengerProfileId, uint256 indexed targetSkillModuleId);
    event SkillChallengeResolved(uint256 indexed challengeId, bool challengerVictorious);
    event ProjectCreated(uint256 indexed projectId, uint256 indexed creatorProfileId, string title, uint256 rewardAmount);
    event ProjectApplied(uint256 indexed projectId, uint256 indexed applicantProfileId);
    event ProjectApplicantAccepted(uint256 indexed projectId, uint256 indexed applicantProfileId);
    event ProjectPhaseCompleted(uint256 indexed projectId, uint256 indexed participantProfileId, uint256 payoutAmount);
    event SkillDelegated(uint256 indexed delegationId, uint256 indexed delegatorProfileId, address indexed delegateeAddress, uint256 skillModuleId, uint256 validUntil, bytes32 intentHash);
    event DelegatedTaskExecuted(uint256 indexed delegationId, address indexed executor, bytes32 executedIntentHash);
    event SkillDelegationRevoked(uint256 indexed delegationId);
    event TrustedOracleSet(address indexed newOracle);
    event ContractPaused(address indexed pauser);
    event ContractUnpaused(address indexed unpauser);
    event BalanceWithdrawn(address indexed to, uint256 amount);

    address public trustedOracle;
    bool public paused;

    // --- Modifiers ---
    modifier onlyProfileOwner(uint256 _profileId) {
        require(profiles[_profileId].owner == msg.sender, "SSN: Not profile owner");
        _;
    }

    modifier mustHaveProfile(address _addr) {
        require(ownerToProfileId[_addr] != 0, "SSN: Address must have a profile");
        _;
    }

    modifier onlyTrustedOracle() {
        require(msg.sender == trustedOracle, "SSN: Not trusted oracle");
        _;
    }

    modifier whenNotPaused() {
        require(!paused, "SSN: Contract is paused");
        _;
    }

    modifier whenPaused() {
        require(paused, "SSN: Contract is not paused");
        _;
    }

    // --- Constructor ---
    constructor() ERC721("SynergisticSkillNetworkProfile", "SSN-P") Ownable(msg.sender) {}

    // --- I. Profile NFT Management (Soulbound Identity) ---

    /**
     * @dev Mints a unique, non-transferable Profile NFT for the caller.
     *      Each address can only mint one Profile NFT.
     *      This NFT serves as the user's on-chain identity within the SSN.
     * @param _metadataURI URI pointing to off-chain metadata (e.g., IPFS hash of a JSON).
     */
    function mintProfileNFT(string memory _metadataURI) public whenNotPaused {
        require(ownerToProfileId[msg.sender] == 0, "SSN: Profile already exists for this address");

        _profileIds.increment();
        uint256 newProfileId = _profileIds.current();

        profiles[newProfileId] = Profile({
            owner: msg.sender,
            metadataURI: _metadataURI,
            exists: true
        });
        ownerToProfileId[msg.sender] = newProfileId;

        _safeMint(msg.sender, newProfileId);
        _setTokenURI(newProfileId, _metadataURI); // Set ERC721 token URI
        emit ProfileMinted(newProfileId, msg.sender, _metadataURI);
    }

    /**
     * @dev Retrieves all stored details for a given Profile NFT ID.
     * @param _profileId The ID of the Profile NFT.
     * @return owner The address of the profile owner.
     * @return metadataURI The URI pointing to the profile's metadata.
     * @return exists True if the profile exists.
     */
    function getProfileDetails(uint256 _profileId) public view returns (address owner, string memory metadataURI, bool exists) {
        Profile storage profile = profiles[_profileId];
        return (profile.owner, profile.metadataURI, profile.exists);
    }

    /**
     * @dev Returns the Profile NFT ID associated with a given owner address.
     * @param _owner The address to query.
     * @return The Profile NFT ID, or 0 if no profile exists for the address.
     */
    function getProfileIdByOwner(address _owner) public view returns (uint256) {
        return ownerToProfileId[_owner];
    }

    /**
     * @dev Allows the owner of a Profile NFT to update its associated metadata URI.
     * @param _profileId The ID of the Profile NFT to update.
     * @param _newMetadataURI The new URI pointing to the updated metadata.
     */
    function updateProfileMetadataURI(uint256 _profileId, string memory _newMetadataURI)
        public
        whenNotPaused
        onlyProfileOwner(_profileId)
    {
        string memory oldMetadataURI = profiles[_profileId].metadataURI;
        profiles[_profileId].metadataURI = _newMetadataURI;
        _setTokenURI(_profileId, _newMetadataURI); // Update ERC721 token URI
        emit ProfileMetadataUpdated(_profileId, oldMetadataURI, _newMetadataURI);
    }

    // ERC721 `_approve` and `transferFrom` are overridden to make tokens non-transferable (Soulbound)
    function _approve(address to, uint256 tokenId) internal override {
        revert("SSN: Profile NFTs are non-transferable.");
    }

    function transferFrom(address from, address to, uint256 tokenId) public pure override {
        revert("SSN: Profile NFTs are non-transferable.");
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public pure override {
        revert("SSN: Profile NFTs are non-transferable.");
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public pure override {
        revert("SSN: Profile NFTs are non-transferable.");
    }

    // --- II. Skill Schema Management (Governance-Controlled) ---

    /**
     * @dev Allows the contract owner to propose a new, standardized skill schema.
     *      This schema must be approved by `approveSkillSchema` before it can be used.
     * @param _name The name of the skill (e.g., "Solidity Development").
     * @param _description A brief description of the skill.
     * @param _category The category of the skill (e.g., "Web3 Dev", "Design").
     * @return The ID of the newly proposed skill schema.
     */
    function proposeSkillSchema(string memory _name, string memory _description, string memory _category)
        public
        onlyOwner
        whenNotPaused
        returns (uint256)
    {
        _skillSchemaIds.increment();
        uint256 newSchemaId = _skillSchemaIds.current();

        skillSchemas[newSchemaId] = SkillSchema({
            name: _name,
            description: _description,
            category: _category,
            isActive: false // Must be approved to be active
        });
        emit SkillSchemaProposed(newSchemaId, _name, _category);
        return newSchemaId;
    }

    /**
     * @dev (Admin/DAO) Approves a proposed skill schema, making it available for users to attach.
     *      Only the contract owner can call this.
     * @param _schemaId The ID of the skill schema to approve.
     */
    function approveSkillSchema(uint256 _schemaId) public onlyOwner whenNotPaused {
        require(skillSchemas[_schemaId].isActive == false, "SSN: Skill schema is already active");
        require(bytes(skillSchemas[_schemaId].name).length > 0, "SSN: Skill schema does not exist");
        skillSchemas[_schemaId].isActive = true;
        emit SkillSchemaApproved(_schemaId);
    }

    /**
     * @dev (Admin/DAO) Deactivates an existing skill schema, preventing new attachments of that type.
     *      Existing skill modules of this schema remain but cannot be newly attached.
     *      Only the contract owner can call this.
     * @param _schemaId The ID of the skill schema to revoke.
     */
    function revokeSkillSchema(uint256 _schemaId) public onlyOwner whenNotPaused {
        require(skillSchemas[_schemaId].isActive == true, "SSN: Skill schema is already inactive");
        require(bytes(skillSchemas[_schemaId].name).length > 0, "SSN: Skill schema does not exist");
        skillSchemas[_schemaId].isActive = false;
        emit SkillSchemaRevoked(_schemaId);
    }

    /**
     * @dev Retrieves details of a specific skill schema.
     * @param _schemaId The ID of the skill schema.
     * @return name The name of the skill.
     * @return description A description of the skill.
     * @return category The category of the skill.
     * @return isActive True if the schema is active and can be attached.
     */
    function getSkillSchemaDetails(uint256 _schemaId)
        public
        view
        returns (string memory name, string memory description, string memory category, bool isActive)
    {
        SkillSchema storage schema = skillSchemas[_schemaId];
        return (schema.name, schema.description, schema.category, schema.isActive);
    }

    // --- III. Dynamic Skill Module Management (Attached to Profiles) ---

    /**
     * @dev Allows a Profile NFT owner to attach a specific, approved skill schema as a module to their profile.
     *      Initializes its level and reputation.
     * @param _profileId The ID of the Profile NFT to attach the skill to.
     * @param _schemaId The ID of the approved skill schema to attach.
     */
    function attachSkillModule(uint256 _profileId, uint256 _schemaId)
        public
        whenNotPaused
        onlyProfileOwner(_profileId)
    {
        require(skillSchemas[_schemaId].isActive, "SSN: Skill schema is not active or does not exist");
        // Check if this skill schema is already attached to this profile (not by skill module ID, but by schema ID)
        // This requires iterating profile's skill modules or a more complex mapping.
        // For simplicity in this example, we assume attaching a schema creates a new unique module.
        // In a real system, you'd likely have profileId => schemaId => skillModuleId to prevent duplicates.

        _skillModuleIds.increment();
        uint256 newSkillModuleId = _skillModuleIds.current();

        skillModules[newSkillModuleId] = SkillModule({
            profileId: _profileId,
            schemaId: _schemaId,
            level: 1, // Start at level 1
            reputationScore: 0,
            attestationCount: 0,
            attached: true
        });
        emit SkillModuleAttached(_profileId, newSkillModuleId, _schemaId);
    }

    /**
     * @dev Allows a Profile NFT owner to remove a skill module from their profile.
     *      This marks the module as detached, but the record persists.
     * @param _skillModuleId The ID of the skill module to detach.
     */
    function detachSkillModule(uint256 _skillModuleId)
        public
        whenNotPaused
    {
        require(skillModules[_skillModuleId].attached, "SSN: Skill module is not attached");
        require(profiles[skillModules[_skillModuleId].profileId].owner == msg.sender, "SSN: Not owner of the skill module's profile");

        skillModules[_skillModuleId].attached = false;
        emit SkillModuleDetached(skillModules[_skillModuleId].profileId, _skillModuleId);
    }

    /**
     * @dev Recalculates and updates a skill module's level based on its current reputation score and attestation count.
     *      This function can be triggered by the profile owner or by the system (e.g., after a challenge is resolved).
     *      The actual level calculation logic is internal.
     * @param _skillModuleId The ID of the skill module to update.
     */
    function updateSkillModuleLevel(uint256 _skillModuleId)
        public
        whenNotPaused
    {
        require(skillModules[_skillModuleId].attached, "SSN: Skill module is not attached");
        // Allow owner to trigger or anyone if a public recalculation logic is needed.
        // Here, only the profile owner can trigger it.
        require(profiles[skillModules[_skillModuleId].profileId].owner == msg.sender, "SSN: Not owner of the skill module's profile");


        SkillModule storage sm = skillModules[_skillModuleId];
        uint256 oldLevel = sm.level;

        // Simple Leveling Logic:
        // Level increases based on reputation score and number of unique attestations.
        // This can be a more complex, nonlinear formula in a real system.
        uint256 newLevel = 1;
        if (sm.reputationScore > 0) {
            newLevel = sm.reputationScore / 10 + sm.attestationCount / 2; // Example simple formula
            if (newLevel == 0) newLevel = 1; // Minimum level 1
            if (newLevel > 100) newLevel = 100; // Cap at 100
        }

        sm.level = newLevel;
        emit SkillModuleLevelUpdated(_skillModuleId, oldLevel, newLevel, sm.reputationScore);
    }


    /**
     * @dev Returns a list of all `skillModuleIds` attached to a given Profile NFT.
     *      Note: This currently requires iterating through all skill modules, which can be gas-intensive for many skills.
     *      A more efficient approach for production would involve storing an array of skillModuleIds within the Profile struct,
     *      or using a mapping `profileId => mapping(uint256 => bool)` for quick existence checks.
     * @param _profileId The ID of the Profile NFT.
     * @return An array of skill module IDs.
     */
    function getProfileSkills(uint256 _profileId) public view returns (uint256[] memory) {
        require(profiles[_profileId].exists, "SSN: Profile does not exist");
        uint256[] memory profileSkillIds = new uint256[](_skillModuleIds.current()); // Max possible size
        uint256 count = 0;
        for (uint256 i = 1; i <= _skillModuleIds.current(); i++) {
            if (skillModules[i].attached && skillModules[i].profileId == _profileId) {
                profileSkillIds[count] = i;
                count++;
            }
        }
        uint256[] memory result = new uint256[](count);
        for (uint256 i = 0; i < count; i++) {
            result[i] = profileSkillIds[i];
        }
        return result;
    }

    /**
     * @dev Retrieves all details of a specific skill module.
     * @param _skillModuleId The ID of the skill module.
     * @return profileId The ID of the associated profile.
     * @return schemaId The ID of the associated skill schema.
     * @return level The current level of the skill.
     * @return reputationScore The current aggregated reputation score.
     * @return attestationCount The number of attestations received.
     * @return attached True if the skill module is currently attached to a profile.
     */
    function getSkillModuleDetails(uint256 _skillModuleId)
        public
        view
        returns (uint256 profileId, uint256 schemaId, uint256 level, uint256 reputationScore, uint256 attestationCount, bool attached)
    {
        SkillModule storage sm = skillModules[_skillModuleId];
        require(sm.attached || sm.profileId != 0, "SSN: Skill module does not exist or is detached"); // Check for existence
        return (sm.profileId, sm.schemaId, sm.level, sm.reputationScore, sm.attestationCount, sm.attached);
    }


    // --- IV. Attestation & Validation System (Verifying Skills) ---

    /**
     * @dev Allows an attested profile owner (`_attesterProfileId`) to vouch for another's skill module,
     *      assigning a rating (e.g., 1-5). This contributes to the target skill's reputation.
     *      An attester can only attest a specific skill module once.
     * @param _attesterProfileId The ID of the profile making the attestation.
     * @param _targetSkillModuleId The ID of the skill module being attested.
     * @param _rating The rating given (e.g., 1-5).
     */
    function attestSkill(uint256 _attesterProfileId, uint256 _targetSkillModuleId, uint8 _rating)
        public
        whenNotPaused
        onlyProfileOwner(_attesterProfileId)
    {
        require(skillModules[_targetSkillModuleId].attached, "SSN: Target skill module not attached");
        require(profiles[_attesterProfileId].exists, "SSN: Attester profile does not exist");
        require(_attesterProfileId != skillModules[_targetSkillModuleId].profileId, "SSN: Cannot attest your own skill");
        require(_rating >= 1 && _rating <= 5, "SSN: Rating must be between 1 and 5");
        require(profileAttestedSkill[_attesterProfileId][_targetSkillModuleId] == 0, "SSN: Already attested this skill module");

        _attestationIds.increment();
        uint256 newAttestationId = _attestationIds.current();

        attestations[newAttestationId] = Attestation({
            attesterProfileId: _attesterProfileId,
            targetSkillModuleId: _targetSkillModuleId,
            rating: _rating,
            timestamp: block.timestamp,
            isValid: true
        });

        profileAttestedSkill[_attesterProfileId][_targetSkillModuleId] = newAttestationId;

        // Update target skill module's reputation
        SkillModule storage sm = skillModules[_targetSkillModuleId];
        sm.reputationScore += _rating;
        sm.attestationCount++; // Only increment for unique attestations

        emit SkillAttested(newAttestationId, _attesterProfileId, _targetSkillModuleId, _rating);
        // Optionally trigger updateSkillModuleLevel here
    }

    /**
     * @dev Allows the original attester to revoke their previously given attestation.
     *      This will reverse the reputation score impact.
     * @param _attestationId The ID of the attestation to revoke.
     */
    function revokeAttestation(uint256 _attestationId)
        public
        whenNotPaused
    {
        Attestation storage att = attestations[_attestationId];
        require(att.isValid, "SSN: Attestation is already invalid or does not exist");
        require(profiles[att.attesterProfileId].owner == msg.sender, "SSN: Not the original attester");

        att.isValid = false; // Invalidate the attestation

        // Reverse reputation impact
        SkillModule storage sm = skillModules[att.targetSkillModuleId];
        require(sm.reputationScore >= att.rating, "SSN: Reputation score inconsistency");
        sm.reputationScore -= att.rating;
        sm.attestationCount--; // Decrement unique attestation count

        profileAttestedSkill[att.attesterProfileId][att.targetSkillModuleId] = 0; // Clear the mapping entry

        emit AttestationRevoked(_attestationId);
        // Optionally trigger updateSkillModuleLevel here
    }

    /**
     * @dev Allows a profile owner to formally challenge the validity of a skill module's level or attestations.
     *      This initiates a dispute which requires resolution by an admin/DAO/oracle.
     * @param _challengerProfileId The ID of the profile initiating the challenge.
     * @param _targetSkillModuleId The ID of the skill module being challenged.
     * @param _reasonHash IPFS hash of a detailed document explaining the reason for the challenge.
     */
    function initiateSkillChallenge(uint256 _challengerProfileId, uint256 _targetSkillModuleId, string memory _reasonHash)
        public
        whenNotPaused
        onlyProfileOwner(_challengerProfileId)
    {
        require(skillModules[_targetSkillModuleId].attached, "SSN: Target skill module not attached");
        require(profiles[_challengerProfileId].exists, "SSN: Challenger profile does not exist");
        require(_challengerProfileId != skillModules[_targetSkillModuleId].profileId, "SSN: Cannot challenge your own skill");
        require(bytes(_reasonHash).length > 0, "SSN: Reason hash cannot be empty");

        _challengeIds.increment();
        uint256 newChallengeId = _challengeIds.current();

        skillChallenges[newChallengeId] = SkillChallenge({
            challengerProfileId: _challengerProfileId,
            targetSkillModuleId: _targetSkillModuleId,
            reasonHash: _reasonHash,
            timestamp: block.timestamp,
            isResolved: false,
            challengerVictorious: false
        });
        emit SkillChallengeInitiated(newChallengeId, _challengerProfileId, _targetSkillModuleId);
    }

    /**
     * @dev (Admin/DAO/Oracle) Resolves a skill challenge. If the challenger is victorious,
     *      the target skill module's reputation/level might be reduced or specific attestations invalidated.
     *      This function can only be called by the contract owner or a designated trusted oracle.
     * @param _challengeId The ID of the challenge to resolve.
     * @param _isChallengerVictorious True if the challenge is upheld (challenger wins), false otherwise.
     */
    function resolveSkillChallenge(uint256 _challengeId, bool _isChallengerVictorious)
        public
        whenNotPaused
    {
        require(msg.sender == owner() || msg.sender == trustedOracle, "SSN: Only owner or trusted oracle can resolve challenges");
        SkillChallenge storage challenge = skillChallenges[_challengeId];
        require(!challenge.isResolved, "SSN: Challenge already resolved");
        require(challenge.targetSkillModuleId != 0, "SSN: Challenge does not exist"); // Basic existence check

        challenge.isResolved = true;
        challenge.challengerVictorious = _isChallengerVictorious;

        if (_isChallengerVictorious) {
            // Implement logic to penalize the skill module.
            // This could involve:
            // 1. Reducing the reputation score by a fixed amount or percentage.
            // 2. Invalidating some or all attestations related to this skill module.
            // For simplicity, we'll apply a reputation penalty.
            SkillModule storage sm = skillModules[challenge.targetSkillModuleId];
            uint256 penalty = sm.reputationScore / 5; // Example: 20% reputation penalty
            sm.reputationScore = sm.reputationScore >= penalty ? sm.reputationScore - penalty : 0;
            // Potentially re-calculate level after penalty
            updateSkillModuleLevel(challenge.targetSkillModuleId); // Recalculate level

            // Optionally, invalidate specific attestations linked to the false claim.
            // This would require a more detailed challenge structure or external oracle input.
        }
        emit SkillChallengeResolved(_challengeId, _isChallengerVictorious);
    }

    /**
     * @dev Returns a list of all attestation IDs associated with a specific skill module.
     *      Similar to `getProfileSkills`, this iterates, consider alternative data structures for scale.
     * @param _skillModuleId The ID of the skill module.
     * @return An array of attestation IDs.
     */
    function getSkillAttestations(uint256 _skillModuleId) public view returns (uint256[] memory) {
        require(skillModules[_skillModuleId].attached || skillModules[_skillModuleId].profileId != 0, "SSN: Skill module does not exist");

        uint256[] memory skillAttestationIds = new uint256[](_attestationIds.current()); // Max possible size
        uint256 count = 0;
        for (uint256 i = 1; i <= _attestationIds.current(); i++) {
            if (attestations[i].isValid && attestations[i].targetSkillModuleId == _skillModuleId) {
                skillAttestationIds[count] = i;
                count++;
            }
        }
        uint256[] memory result = new uint256[](count);
        for (uint256 i = 0; i < count; i++) {
            result[i] = skillAttestationIds[i];
        }
        return result;
    }


    // --- V. Project Collaboration & Matching ---

    /**
     * @dev Allows a profile owner to list a new project, specifying required skills and an ETH reward pool.
     *      The reward amount is deposited into the contract and held in trust.
     * @param _title The title of the project.
     * @param _description A description of the project.
     * @param _requiredSkillSchemaIds An array of skill schema IDs required for the project.
     * @param _rewardAmount The total ETH reward for the project.
     */
    function createProjectListing(string memory _title, string memory _description, uint256[] memory _requiredSkillSchemaIds, uint256 _rewardAmount)
        public payable whenNotPaused mustHaveProfile(msg.sender) nonReentrant
    {
        require(msg.value == _rewardAmount, "SSN: Sent ETH must match reward amount");
        require(_rewardAmount > 0, "SSN: Reward amount must be greater than zero");
        require(_requiredSkillSchemaIds.length > 0, "SSN: Project must specify required skills");

        // Basic validation for required skills exist and are active
        for (uint256 i = 0; i < _requiredSkillSchemaIds.length; i++) {
            require(skillSchemas[_requiredSkillSchemaIds[i]].isActive, "SSN: Required skill schema is not active");
        }

        _projectIds.increment();
        uint256 newProjectId = _projectIds.current();
        uint256 creatorProfileId = ownerToProfileId[msg.sender];

        projects[newProjectId] = Project({
            creatorProfileId: creatorProfileId,
            title: _title,
            description: _description,
            requiredSkillSchemaIds: _requiredSkillSchemaIds,
            rewardAmount: _rewardAmount,
            isCompleted: false
        });
        emit ProjectCreated(newProjectId, creatorProfileId, _title, _rewardAmount);
    }

    /**
     * @dev Allows a profile owner with a relevant skill module to apply for a role in an existing project.
     * @param _profileId The ID of the profile applying.
     * @param _projectId The ID of the project to apply for.
     * @param _skillModuleId The ID of the skill module being used for the application.
     */
    function applyForProjectRole(uint256 _profileId, uint256 _projectId, uint256 _skillModuleId)
        public whenNotPaused onlyProfileOwner(_profileId)
    {
        Project storage project = projects[_projectId];
        require(project.creatorProfileId != 0, "SSN: Project does not exist");
        require(!project.isCompleted, "SSN: Project is already completed");
        require(!projectApplicants[_projectId][_profileId], "SSN: Profile already applied for this project");

        SkillModule storage sm = skillModules[_skillModuleId];
        require(sm.attached && sm.profileId == _profileId, "SSN: Invalid or unattached skill module for this profile");
        require(sm.level > 0, "SSN: Skill module must have a level above 0"); // Requires some attested skill

        bool skillMatches = false;
        for (uint256 i = 0; i < project.requiredSkillSchemaIds.length; i++) {
            if (project.requiredSkillSchemaIds[i] == sm.schemaId) {
                skillMatches = true;
                break;
            }
        }
        require(skillMatches, "SSN: Skill module does not match project requirements");

        projectApplicants[_projectId][_profileId] = true;
        emit ProjectApplied(_projectId, _profileId);
    }

    /**
     * @dev Allows the project creator to accept an applicant for a project role.
     * @param _projectId The ID of the project.
     * @param _applicantProfileId The ID of the applicant's profile to accept.
     */
    function acceptProjectApplicant(uint256 _projectId, uint256 _applicantProfileId)
        public whenNotPaused mustHaveProfile(msg.sender)
    {
        Project storage project = projects[_projectId];
        require(project.creatorProfileId != 0, "SSN: Project does not exist");
        require(project.creatorProfileId == ownerToProfileId[msg.sender], "SSN: Only project creator can accept applicants");
        require(!project.isCompleted, "SSN: Project is already completed");
        require(projectApplicants[_projectId][_applicantProfileId], "SSN: Profile has not applied for this project");
        require(!projectParticipants[_projectId][_applicantProfileId], "SSN: Profile is already a participant in this project");

        projectParticipants[_projectId][_applicantProfileId] = true;
        emit ProjectApplicantAccepted(_projectId, _applicantProfileId);
    }

    /**
     * @dev (Project Creator) Marks a phase of a project as complete for a participant and distributes a portion of rewards.
     * @param _projectId The ID of the project.
     * @param _participantProfileId The ID of the participant's profile to reward.
     * @param _payoutAmount The amount of ETH to pay to this participant for this phase.
     */
    function completeProjectPhase(uint256 _projectId, uint256 _participantProfileId, uint256 _payoutAmount)
        public payable whenNotPaused mustHaveProfile(msg.sender) nonReentrant
    {
        Project storage project = projects[_projectId];
        require(project.creatorProfileId != 0, "SSN: Project does not exist");
        require(project.creatorProfileId == ownerToProfileId[msg.sender], "SSN: Only project creator can complete phases");
        require(!project.isCompleted, "SSN: Project is already completed");
        require(projectParticipants[_projectId][_participantProfileId], "SSN: Profile is not a participant in this project");
        require(address(this).balance >= _payoutAmount, "SSN: Insufficient contract balance for payout"); // Check remaining project balance

        // Deduct from project's remaining reward pool conceptually, though funds are just sent directly
        // In a more complex system, _rewardAmount would track remaining project funds within the contract.
        // Here, it's just a reference.
        payable(profiles[_participantProfileId].owner).transfer(_payoutAmount);
        emit ProjectPhaseCompleted(_projectId, _participantProfileId, _payoutAmount);

        // Logic to mark project as completed if total rewards match or last payout.
        // For simplicity, this function can be called multiple times for multiple phases/participants.
    }


    // --- VI. Advanced: Intent-Based Skill Delegation ---

    /**
     * @dev Allows a profile owner to temporarily "lend" their attested capacity for a specific skill
     *      to another address (`_delegateeAddress`) for a limited duration and for a predefined off-chain "intent" or task.
     *      This creates an on-chain record of the delegation, which can be referenced and consumed.
     * @param _delegatorProfileId The ID of the profile granting the delegation.
     * @param _delegateeAddress The address that can use the delegated capacity.
     * @param _skillModuleId The specific skill module being delegated.
     * @param _validUntil Timestamp when delegation expires (Unix timestamp).
     * @param _intentHash A bytes32 hash representing the specific off-chain task/intent this delegation is for.
     *                    This could be a hash of a task description, a contract address + function signature, etc.
     *                    It's crucial for the delegatee to match this hash when executing.
     */
    function delegateSkillCapacity(
        uint256 _delegatorProfileId,
        address _delegateeAddress,
        uint256 _skillModuleId,
        uint256 _validUntil,
        bytes32 _intentHash
    ) public whenNotPaused onlyProfileOwner(_delegatorProfileId) {
        require(profiles[_delegatorProfileId].exists, "SSN: Delegator profile does not exist");
        require(skillModules[_skillModuleId].attached && skillModules[_skillModuleId].profileId == _delegatorProfileId, "SSN: Invalid or unattached skill module for delegator");
        require(skillModules[_skillModuleId].level > 0, "SSN: Delegated skill must have a level above 0");
        require(_delegateeAddress != address(0), "SSN: Delegatee address cannot be zero");
        require(_delegateeAddress != msg.sender, "SSN: Cannot delegate to self");
        require(_validUntil > block.timestamp, "SSN: Delegation must be valid for a future time");
        require(_intentHash != bytes32(0), "SSN: Intent hash cannot be zero");

        _delegationIds.increment();
        uint256 newDelegationId = _delegationIds.current();

        skillDelegations[newDelegationId] = SkillDelegation({
            delegatorProfileId: _delegatorProfileId,
            delegateeAddress: _delegateeAddress,
            skillModuleId: _skillModuleId,
            validUntil: _validUntil,
            intentHash: _intentHash,
            isActive: true
        });

        emit SkillDelegated(newDelegationId, _delegatorProfileId, _delegateeAddress, _skillModuleId, _validUntil, _intentHash);
    }

    /**
     * @dev Allows the `delegateeAddress` to "execute" a delegated task, marking the specific delegation as used or consumed.
     *      This function requires the `_executedIntentHash` to match the `intentHash` stored in the delegation.
     *      This is a conceptual execution; the actual off-chain task is not performed by this contract.
     * @param _delegationId The ID of the delegation to execute.
     * @param _executedIntentHash The hash of the intent that is being executed (must match the stored intent).
     */
    function executeDelegatedTask(uint256 _delegationId, bytes32 _executedIntentHash)
        public whenNotPaused
    {
        SkillDelegation storage delegation = skillDelegations[_delegationId];
        require(delegation.isActive, "SSN: Delegation is not active or does not exist");
        require(delegation.delegateeAddress == msg.sender, "SSN: Only the designated delegatee can execute this task");
        require(block.timestamp <= delegation.validUntil, "SSN: Delegation has expired");
        require(delegation.intentHash == _executedIntentHash, "SSN: Executed intent hash does not match delegation intent");

        delegation.isActive = false; // Mark as consumed
        emit DelegatedTaskExecuted(_delegationId, msg.sender, _executedIntentHash);
    }

    /**
     * @dev Allows the original delegator to revoke an active skill delegation before its `validUntil` period ends
     *      or before it's executed by the delegatee.
     * @param _delegationId The ID of the delegation to revoke.
     */
    function revokeSkillDelegation(uint256 _delegationId)
        public whenNotPaused
    {
        SkillDelegation storage delegation = skillDelegations[_delegationId];
        require(delegation.isActive, "SSN: Delegation is not active or does not exist");
        require(profiles[delegation.delegatorProfileId].owner == msg.sender, "SSN: Not the original delegator");

        delegation.isActive = false; // Mark as revoked
        emit SkillDelegationRevoked(_delegationId);
    }

    /**
     * @dev Retrieves the details of a specific skill delegation.
     * @param _delegationId The ID of the delegation.
     * @return delegatorProfileId The ID of the profile granting the delegation.
     * @return delegateeAddress The address that can use the delegated capacity.
     * @return skillModuleId The specific skill module being delegated.
     * @return validUntil Timestamp when delegation expires.
     * @return intentHash Hash representing the specific off-chain task/intent.
     * @return isActive True if delegation is active and not yet executed/revoked.
     */
    function getDelegatedIntent(uint256 _delegationId)
        public view returns (
            uint256 delegatorProfileId,
            address delegateeAddress,
            uint256 skillModuleId,
            uint256 validUntil,
            bytes32 intentHash,
            bool isActive
        )
    {
        SkillDelegation storage delegation = skillDelegations[_delegationId];
        require(delegation.delegatorProfileId != 0, "SSN: Delegation does not exist"); // Check for existence
        return (
            delegation.delegatorProfileId,
            delegation.delegateeAddress,
            delegation.skillModuleId,
            delegation.validUntil,
            delegation.intentHash,
            delegation.isActive
        );
    }

    // --- VII. Governance & Utilities ---

    /**
     * @dev (Owner) Sets the address of a trusted oracle. This oracle can be used for
     *      off-chain verification (e.g., for resolving skill challenges).
     * @param _oracleAddress The address of the new trusted oracle.
     */
    function setTrustedOracle(address _oracleAddress) public onlyOwner whenNotPaused {
        require(_oracleAddress != address(0), "SSN: Oracle address cannot be zero");
        trustedOracle = _oracleAddress;
        emit TrustedOracleSet(_oracleAddress);
    }

    /**
     * @dev (Owner) Pauses critical functions of the contract in case of an emergency.
     *      Prevents `mintProfileNFT`, `attestSkill`, `createProjectListing`, `delegateSkillCapacity` etc.
     */
    function emergencyPause() public onlyOwner whenNotPaused {
        paused = true;
        emit ContractPaused(msg.sender);
    }

    /**
     * @dev (Owner) Unpauses the contract after an emergency.
     */
    function unpauseContract() public onlyOwner whenPaused {
        paused = false;
        emit ContractUnpaused(msg.sender);
    }

    /**
     * @dev (Owner) Allows the contract owner to withdraw any accumulated ETH.
     *      This could be from project fees (if implemented) or unspent project rewards.
     * @param _to The address to send the ETH to.
     */
    function withdrawContractBalance(address _to) public onlyOwner nonReentrant {
        require(_to != address(0), "SSN: Target address cannot be zero");
        uint256 balance = address(this).balance;
        require(balance > 0, "SSN: No balance to withdraw");
        payable(_to).transfer(balance);
        emit BalanceWithdrawn(_to, balance);
    }
}
```