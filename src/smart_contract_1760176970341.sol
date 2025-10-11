This smart contract, `AetherweaveIdentity`, introduces a **Soulbound Digital Identity** system on the blockchain. It allows users to mint a non-transferable ERC-721 token representing their unique identity. This identity can then accumulate **attestable skills** from various sources (trusted parties, other contracts, or self-attested proofs). These skills dynamically contribute to higher-level **traits**, which evolve through different **levels**. Based on these trait levels, the identity can automatically unlock **dynamic privileges** within this contract or be queried by other decentralized applications. The system also supports **on-chain challenges** for skill acquisition and **immutable snapshotting** of identity states for historical purposes.

This design emphasizes **decentralized, verifiable reputation and identity progression**, moving beyond simple token ownership to a richer, activity-driven digital persona.

---

## AetherweaveIdentity Smart Contract

**Outline:**

1.  **Identity Core (ERC-721 Soulbound)**: Basic identity minting, burning, and metadata management, ensuring non-transferability.
2.  **Skill & Attestation Registry**: Defines various skills and mechanisms for entities (EOAs or contracts) to attest to a user's proficiency in these skills. Includes self-attestation with verifiable proofs.
3.  **Trait & Progression System**: Aggregates attested skills into higher-level, dynamically calculated traits, which then determine an identity's progression through various levels.
4.  **Dynamic Privilege System**: Defines privileges that are automatically granted or revoked based on an identity's current trait levels.
5.  **Role-Based Access Control**: Manages permissions for administrative tasks, skill management, privilege definition, and challenge creation.
6.  **Advanced Interactions / Challenges**: Enables the creation and completion of on-chain challenges that reward specific skills upon successful verification.
7.  **Snapshotting & History**: Allows creating immutable records of an identity's skills and traits at a specific point in time, useful for historical analysis or retroactive rewards.

---

**Function Summary:**

**I. Identity Core:**
1.  `mintIdentity()`: Mints a new soulbound identity token for the caller. Each address can mint only one identity.
2.  `burnIdentity(uint256 tokenId)`: Allows an identity owner to irreversibly burn their SBT.
3.  `getTokenIdByAddress(address owner)`: Retrieves the identity token ID associated with an address.
4.  `setIdentityMetadataURI(uint256 tokenId, string memory newURI)`: Allows identity owner to update their profile's metadata URI (e.g., profile picture, external links).

**II. Skill & Attestation Registry:**
5.  `registerSkill(string memory skillName, string memory category, string memory description, uint256 minAttestationsRequired, address attesterContract)`: Admin/SKILL_MANAGER_ROLE defines a new attestable skill with its properties. `attesterContract` is for self-attestation verification.
6.  `attestSkill(uint256 tokenId, string memory skillName, address attester, string memory proofURI)`: Authorized attestors (EOA or contract with ATTESTER_ROLE) record a claim for a user's skill.
7.  `revokeAttestation(uint256 tokenId, string memory skillName, address attester)`: Authorized attestors can revoke a previously made attestation.
8.  `claimSelfAttestedSkill(string memory skillName, bytes calldata proofData)`: Allows a user to claim a skill by providing on-chain verifiable proof to a pre-registered `attesterContract`.
9.  `getSkillDetails(string memory skillName)`: Retrieves the definition and requirements for a specific skill.
10. `getAttestationCountForSkill(uint256 tokenId, string memory skillName)`: Returns the count of distinct active attestations for a given skill on an identity.
11. `hasSkill(uint256 tokenId, string memory skillName)`: Checks if an identity possesses a specific skill based on the `minAttestationsRequired`.

**III. Trait & Progression System:**
12. `registerTrait(string memory traitName, string memory description, string[] memory contributingSkillNames, uint256[] memory levelThresholds)`: Admin/SKILL_MANAGER_ROLE registers a new trait, specifying which skills contribute to its score and the thresholds for each level.
13. `calculateTraitScore(uint256 tokenId, string memory traitName)`: Dynamically computes a trait's numerical score from its constituent skills for an identity.
14. `getTraitLevel(uint256 tokenId, string memory traitName)`: Derives an identity's level for a given trait based on its calculated score and predefined thresholds.
15. `getOverallReputationScore(uint256 tokenId)`: Calculates a comprehensive reputation score across all registered traits for an identity (e.g., sum of all trait levels).
16. `setTraitLevelThresholds(string memory traitName, uint256[] memory newThresholds)`: Admin/SKILL_MANAGER_ROLE configures the score ranges for each trait level.

**IV. Dynamic Privilege System:**
17. `registerPrivilege(string memory privilegeName, string memory description, string memory requiredTrait, uint256 requiredLevel)`: Admin/PRIVILEGE_MANAGER_ROLE defines a new dynamic privilege and its unlock condition (a specific trait and minimum level).
18. `hasPrivilege(uint256 tokenId, string memory privilegeName)`: Verifies if an identity currently meets the conditions for a specific privilege.
19. `getGrantedPrivileges(uint256 tokenId)`: Lists all privileges an identity currently qualifies for.

**V. Role-Based Access Control:**
20. `grantRole(bytes32 role, address account)`: Grants a specified role (e.g., `ATTESTER_ROLE`, `SKILL_MANAGER_ROLE`) to an account (callable by `DEFAULT_ADMIN_ROLE`).
21. `revokeRole(bytes32 role, address account)`: Revokes a specified role from an account (callable by `DEFAULT_ADMIN_ROLE`).
22. `renounceRole(bytes32 role)`: Allows an account to renounce its own role.
23. `setSkillAttesterContract(string memory skillName, address verifierContract)`: Assigns a specific smart contract as an authorized verifier/attester for certain skills.

**VI. Advanced Interactions / Challenges:**
24. `proposeIdentityChallenge(string memory challengeName, string memory description, string memory targetSkillName, uint256 skillPointsOnCompletion, address conditionVerifierContract)`: CHALLENGE_MANAGER_ROLE can propose on-chain challenges that reward skills upon completion.
25. `completeIdentityChallenge(uint256 tokenId, string memory challengeName, bytes calldata proofData)`: Allows an identity owner to claim completion of a challenge, verified by an external `conditionVerifierContract`.
26. `registerChallengeVerifier(string memory challengeName, address verifierContract)`: Assigns/updates a verifier contract for a specific challenge.

**VII. Snapshotting & History:**
27. `snapshotIdentityState(uint256 tokenId)`: Creates an immutable record of an identity's skills and traits at the current block.
28. `getIdentityStateAtSnapshot(uint256 tokenId, uint256 snapshotId)`: Retrieves the full identity state (skills, traits, levels) from a specific snapshot ID.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/Address.sol";

// Interfaces for external verifier contracts
interface ISkillVerifier {
    function verifyProof(uint256 tokenId, bytes calldata proofData) external view returns (bool);
    // Optional: function getSkillName() external pure returns (string memory);
}

interface IChallengeConditionVerifier {
    function verifyCondition(uint256 tokenId, bytes calldata conditionData) external view returns (bool);
    // Optional: function getChallengeName() external pure returns (string memory);
}

// Define custom errors for better clarity and gas efficiency
error Aetherweave__NotIdentityOwner();
error Aetherweave__IdentityAlreadyMinted();
error Aetherweave__IdentityNotFound();
error Aetherweave__SkillAlreadyRegistered();
error Aetherweave__SkillNotRegistered();
error Aetherweave__NotAuthorizedAttester();
error Aetherweave__AttestationAlreadyExists();
error Aetherweave__AttestationDoesNotExist();
error Aetherweave__TraitAlreadyRegistered();
error Aetherweave__TraitNotRegistered();
error Aetherweave__TraitThresholdsInvalid();
error Aetherweave__PrivilegeAlreadyRegistered();
error Aetherweave__PrivilegeNotRegistered();
error Aetherweave__ChallengeAlreadyRegistered();
error Aetherweave__ChallengeNotRegistered();
error Aetherweave__ChallengeAlreadyCompleted();
error Aetherweave__ChallengeConditionNotMet();
error Aetherweave__InvalidVerifierContract();
error Aetherweave__SnapshotDoesNotExist();
error Aetherweave__SelfAttestationNotSupported();
error Aetherweave__SelfAttestationProofFailed();


/**
 * @title AetherweaveIdentity
 * @dev A Soulbound Digital Identity contract featuring Attestable Skills, Dynamic Trait Progression,
 *      and Unlockable Privileges. This contract enables users to mint a non-transferable ERC-721
 *      identity token, accumulate verified skills through various attestation mechanisms,
 *      which then dynamically derive higher-level traits and unlock specific privileges.
 *      It also includes on-chain challenges and immutable identity state snapshotting.
 */
contract AetherweaveIdentity is ERC721, AccessControl {
    using Counters for Counters.Counter;
    using Strings for uint256;

    // --- Outline ---
    // I. Identity Core (ERC-721 Soulbound)
    // II. Skill & Attestation Registry
    // III. Trait & Progression System
    // IV. Dynamic Privilege System
    // V. Role-Based Access Control
    // VI. Advanced Interactions / Challenges
    // VII. Snapshotting & History

    // --- Function Summary ---
    // I. Identity Core:
    // 1. mintIdentity(): Mints a new soulbound identity token for the caller.
    // 2. burnIdentity(): Allows an identity owner to irreversibly burn their SBT.
    // 3. getTokenIdByAddress(): Retrieves the identity token ID associated with an address.
    // 4. setIdentityMetadataURI(): Allows identity owner to update their profile's metadata URI.

    // II. Skill & Attestation Registry:
    // 5. registerSkill(): Admin/ROLE defines a new attestable skill with its properties.
    // 6. attestSkill(): Authorized attestors (EOA or contract) record a claim for a user's skill.
    // 7. revokeAttestation(): Authorized attestors can revoke a previously made attestation.
    // 8. claimSelfAttestedSkill(): Allows a user to claim a skill by providing on-chain verifiable proof.
    // 9. getSkillDetails(): Retrieves the definition and requirements for a specific skill.
    // 10. getAttestationCountForSkill(): Returns the count of active attestations for a given skill on an identity.
    // 11. hasSkill(): Checks if an identity possesses a specific skill based on attestations.

    // III. Trait & Progression System:
    // 12. registerTrait(): Admin/ROLE registers a new trait with its contributing skills and default thresholds.
    // 13. calculateTraitScore(): Dynamically computes a trait's numerical score from its constituent skills.
    // 14. getTraitLevel(): Derives an identity's level for a given trait based on its score and thresholds.
    // 15. getOverallReputationScore(): Calculates a comprehensive reputation score across all traits.
    // 16. setTraitLevelThresholds(): Admin/ROLE configures the score ranges for each trait level.

    // IV. Dynamic Privilege System:
    // 17. registerPrivilege(): Admin/ROLE defines a new dynamic privilege and its unlock condition (trait/level).
    // 18. hasPrivilege(): Verifies if an identity currently meets the conditions for a specific privilege.
    // 19. getGrantedPrivileges(): Lists all privileges an identity currently qualifies for.

    // V. Role-Based Access Control:
    // 20. grantRole(): Grants a role (e.g., ATTESTER_ROLE, CHALLENGE_PROPOSER_ROLE).
    // 21. revokeRole(): Revokes a role.
    // 22. renounceRole(): Allows an account to renounce its own role.
    // 23. setSkillAttesterContract(): Assigns a specific smart contract as an authorized attester for certain skills.

    // VI. Advanced Interactions / Challenges:
    // 24. proposeIdentityChallenge(): Users (with specific roles/stake) can propose on-chain challenges that reward skills.
    // 25. completeIdentityChallenge(): Allows an identity owner to claim completion of a challenge.
    // 26. registerChallengeVerifier(): Assigns a verifier contract for a specific challenge.

    // VII. Snapshotting & History:
    // 27. snapshotIdentityState(): Creates an immutable record of an identity's skills and traits at a specific block.
    // 28. getIdentityStateAtSnapshot(): Retrieves the full identity state from a specific snapshot ID.

    // --- State Variables & Data Structures ---

    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE"); // A higher-level admin role, above specific managers
    bytes32 public constant ATTESTER_ROLE = keccak256("ATTESTER_ROLE");
    bytes32 public constant SKILL_MANAGER_ROLE = keccak256("SKILL_MANAGER_ROLE");
    bytes32 public constant PRIVILEGE_MANAGER_ROLE = keccak256("PRIVILEGE_MANAGER_ROLE");
    bytes32 public constant CHALLENGE_MANAGER_ROLE = keccak256("CHALLENGE_MANAGER_ROLE");

    Counters.Counter private _tokenIdCounter;

    // Mapping from owner address to tokenId (for O(1) lookup)
    mapping(address => uint256) private _identities;

    // --- Skill Definitions ---
    struct Skill {
        string name;
        string category;
        string description;
        uint256 minAttestationsRequired; // Minimum distinct attestations needed for an identity to 'possess' the skill
        address attesterContract; // Optional: specific contract authorized to verify self-attestations for this skill
        bool isRegistered; // To check if skill exists without iterating
    }
    mapping(string => Skill) private _skills;
    string[] private _registeredSkillNames; // To iterate over all skills

    // --- Attestations ---
    struct Attestation {
        address attester;
        uint64 timestamp;
        string proofURI; // Optional URI for off-chain proof documentation
    }
    // tokenId => skillName => attesterAddress => Attestation details
    mapping(uint256 => mapping(string => mapping(address => Attestation))) private _skillAttestations;
    // tokenId => skillName => count of unique attestations
    mapping(uint256 => mapping(string => uint256)) private _attestationCount;

    // --- Traits & Progression ---
    struct Trait {
        string name;
        string description;
        string[] contributingSkillNames; // Names of skills that contribute to this trait
        uint256[] levelThresholds; // Scores required for each level (e.g., [0, 100, 250, 500] for levels 0, 1, 2, 3)
        bool isRegistered;
    }
    mapping(string => Trait) private _traits;
    string[] private _registeredTraitNames; // To iterate over all traits

    // --- Privileges ---
    struct Privilege {
        string name;
        string description;
        string requiredTrait; // Name of the trait required for this privilege
        uint256 requiredLevel; // Minimum level of the requiredTrait
        bool isRegistered;
    }
    mapping(string => Privilege) private _privileges;
    string[] private _registeredPrivilegeNames; // To iterate over all privileges

    // --- Challenges ---
    struct Challenge {
        string name;
        string description;
        string targetSkillName; // The skill to be awarded upon completion
        address conditionVerifierContract; // Contract that verifies challenge completion conditions
        bool isRegistered;
    }
    mapping(string => Challenge) private _challenges;
    string[] private _registeredChallengeNames; // To iterate over all challenges
    // tokenId => challengeName => true if completed
    mapping(uint256 => mapping(string => bool)) private _challengeCompletion;

    // --- Snapshotting ---
    struct IdentitySnapshot {
        uint256 blockNumber;
        uint64 timestamp;
        // Mapping of skillName => count of attestations at snapshot
        mapping(string => uint256) skillAttestationCounts;
        // Mapping of traitName => current score at snapshot
        mapping(string => uint256) traitScores;
        // Mapping of traitName => current level at snapshot
        mapping(string => uint256) traitLevels;
        // Arrays to store names for iteration (to retrieve all snapshotted data)
        string[] snapshottedSkillNames;
        string[] snapshottedTraitNames;
    }
    // tokenId => snapshotId => IdentitySnapshot
    mapping(uint224 => mapping(uint32 => IdentitySnapshot)) private _identitySnapshots;
    // tokenId => next available snapshotId
    mapping(uint224 => Counters.Counter) private _nextSnapshotId;


    // Events to log important actions
    event IdentityMinted(address indexed owner, uint256 indexed tokenId);
    event IdentityBurned(address indexed owner, uint256 indexed tokenId);
    event IdentityMetadataUpdated(uint256 indexed tokenId, string newURI);
    event SkillRegistered(string indexed skillName, string category, address attesterContract);
    event SkillAttested(uint256 indexed tokenId, string indexed skillName, address indexed attester);
    event AttestationRevoked(uint256 indexed tokenId, string indexed skillName, address indexed attester);
    event SelfAttestedSkillClaimed(uint256 indexed tokenId, string indexed skillName, address indexed verifier);
    event TraitRegistered(string indexed traitName, string[] contributingSkillNames);
    event TraitLevelThresholdsSet(string indexed traitName, uint256[] thresholds);
    event PrivilegeRegistered(string indexed privilegeName, string requiredTrait, uint256 requiredLevel);
    event ChallengeRegistered(string indexed challengeName, string targetSkillName, address conditionVerifier);
    event ChallengeCompleted(uint256 indexed tokenId, string indexed challengeName, string awardedSkill);
    event IdentityStateSnapshotted(uint256 indexed tokenId, uint256 indexed snapshotId, uint256 blockNumber);


    /**
     * @dev Constructor grants DEFAULT_ADMIN_ROLE and a custom ADMIN_ROLE to the deployer.
     * @param name The name of the ERC721 token (e.g., "Aetherweave Identity").
     * @param symbol The symbol of the ERC721 token (e.g., "AWEI").
     */
    constructor(string memory name, string memory symbol) ERC721(name, symbol) {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(ADMIN_ROLE, msg.sender); // Custom admin role for broader management
        _grantRole(SKILL_MANAGER_ROLE, msg.sender);
        _grantRole(PRIVILEGE_MANAGER_ROLE, msg.sender);
        _grantRole(CHALLENGE_MANAGER_ROLE, msg.sender);
    }

    // --- I. Identity Core (ERC-721 Soulbound) ---

    /**
     * @dev ERC721 hook to prevent any transfers, making tokens soulbound.
     *      Reverts if 'from' or 'to' are not the zero address.
     */
    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize) internal pure override {
        if (from != address(0) && to != address(0)) {
            revert("Aetherweave: Soulbound tokens are non-transferable");
        }
    }

    // Explicitly revert transfer-related functions to ensure non-transferability
    function approve(address to, uint256 tokenId) public pure override {
        revert("Aetherweave: Soulbound tokens cannot be approved for transfer");
    }

    function setApprovalForAll(address operator, bool approved) public pure override {
        revert("Aetherweave: Soulbound tokens cannot be approved for all");
    }

    function transferFrom(address from, address to, uint256 tokenId) public pure override {
        revert("Aetherweave: Soulbound tokens cannot be transferred");
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public pure override {
        revert("Aetherweave: Soulbound tokens cannot be transferred");
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public pure override {
        revert("Aetherweave: Soulbound tokens cannot be transferred");
    }

    /**
     * @dev Mints a new soulbound identity token for the caller.
     *      Each address can only mint one identity.
     * @return The ID of the newly minted identity token.
     */
    function mintIdentity() external returns (uint256) {
        if (_identities[msg.sender] != 0) {
            revert Aetherweave__IdentityAlreadyMinted();
        }
        _tokenIdCounter.increment();
        uint256 newId = _tokenIdCounter.current();

        _safeMint(msg.sender, newId); // Mints the ERC721 token
        _identities[msg.sender] = newId; // Track owner-to-tokenId mapping
        emit IdentityMinted(msg.sender, newId);
        return newId;
    }

    /**
     * @dev Allows an identity owner to irreversibly burn their SBT.
     *      All associated skills, traits, and privileges will become inaccessible.
     * @param tokenId The ID of the identity token to burn.
     */
    function burnIdentity(uint256 tokenId) external {
        if (ownerOf(tokenId) != msg.sender) {
            revert Aetherweave__NotIdentityOwner();
        }
        _burn(tokenId); // Burns the ERC721 token
        delete _identities[msg.sender]; // Clear owner-to-tokenId mapping
        // Note: Associated skill/trait/challenge data remains in storage but is unreachable
        // for this tokenId. Could be explicitly cleared for gas if needed, but not critical.
        emit IdentityBurned(msg.sender, tokenId);
    }

    /**
     * @dev Retrieves the identity token ID associated with an address.
     * @param owner The address whose identity ID is to be retrieved.
     * @return The token ID, or 0 if no identity is found.
     */
    function getTokenIdByAddress(address owner) public view returns (uint256) {
        return _identities[owner];
    }

    /**
     * @dev Allows identity owner to update their profile's metadata URI.
     * @param tokenId The ID of the identity token.
     * @param newURI The new URI pointing to the identity's metadata.
     */
    function setIdentityMetadataURI(uint256 tokenId, string memory newURI) external {
        if (ownerOf(tokenId) != msg.sender) {
            revert Aetherweave__NotIdentityOwner();
        }
        _setTokenURI(tokenId, newURI);
        emit IdentityMetadataUpdated(tokenId, newURI);
    }

    // --- II. Skill & Attestation Registry ---

    /**
     * @dev Admin or SKILL_MANAGER_ROLE defines a new attestable skill with its properties.
     * @param skillName The unique name of the skill.
     * @param category The category this skill belongs to (e.g., "DeFi", "Governance").
     * @param description A brief description of the skill.
     * @param minAttestationsRequired Minimum distinct attestations needed for an identity to 'possess' this skill.
     * @param attesterContract Optional: address of a contract that verifies self-attested proofs for this skill.
     *                         If provided, it must be a contract address.
     */
    function registerSkill(
        string memory skillName,
        string memory category,
        string memory description,
        uint256 minAttestationsRequired,
        address attesterContract
    ) external onlyRole(SKILL_MANAGER_ROLE) {
        if (_skills[skillName].isRegistered) {
            revert Aetherweave__SkillAlreadyRegistered();
        }
        if (attesterContract != address(0) && !Address.isContract(attesterContract)) {
            revert Aetherweave__InvalidVerifierContract();
        }

        _skills[skillName] = Skill({
            name: skillName,
            category: category,
            description: description,
            minAttestationsRequired: minAttestationsRequired,
            attesterContract: attesterContract,
            isRegistered: true
        });
        _registeredSkillNames.push(skillName);
        emit SkillRegistered(skillName, category, attesterContract);
    }

    /**
     * @dev Authorized attestors (EOA or contract with ATTESTER_ROLE) record a claim for a user's skill.
     *      Each attester can only attest to a specific skill once per identity.
     * @param tokenId The ID of the identity token.
     * @param skillName The name of the skill being attested.
     * @param attester The address making the attestation. Must be `msg.sender`.
     * @param proofURI Optional URI for off-chain proof documentation.
     */
    function attestSkill(
        uint256 tokenId,
        string memory skillName,
        address attester, // Explicitly pass attester address, must match msg.sender
        string memory proofURI
    ) external onlyRole(ATTESTER_ROLE) {
        if (!_skills[skillName].isRegistered) {
            revert Aetherweave__SkillNotRegistered();
        }
        if (ownerOf(tokenId) == address(0)) {
            revert Aetherweave__IdentityNotFound();
        }
        // For simplicity, msg.sender MUST be the attester for this function.
        // A more complex system might have a separate attester registry or proxy permissions.
        if (attester != msg.sender) {
            revert Aetherweave__NotAuthorizedAttester();
        }

        if (_skillAttestations[tokenId][skillName][attester].timestamp != 0) {
            revert Aetherweave__AttestationAlreadyExists();
        }

        _skillAttestations[tokenId][skillName][attester] = Attestation({
            attester: attester,
            timestamp: uint64(block.timestamp),
            proofURI: proofURI
        });
        _attestationCount[tokenId][skillName]++;
        emit SkillAttested(tokenId, skillName, attester);
    }

    /**
     * @dev Authorized attestors can revoke a previously made attestation.
     * @param tokenId The ID of the identity token.
     * @param skillName The name of the skill whose attestation is being revoked.
     * @param attester The address of the original attester. Must be `msg.sender`.
     */
    function revokeAttestation(
        uint256 tokenId,
        string memory skillName,
        address attester
    ) external onlyRole(ATTESTER_ROLE) {
        if (!_skills[skillName].isRegistered) {
            revert Aetherweave__SkillNotRegistered();
        }
        if (ownerOf(tokenId) == address(0)) {
            revert Aetherweave__IdentityNotFound();
        }
        if (attester != msg.sender) {
            revert Aetherweave__NotAuthorizedAttester();
        }
        if (_skillAttestations[tokenId][skillName][attester].timestamp == 0) {
            revert Aetherweave__AttestationDoesNotExist();
        }

        delete _skillAttestations[tokenId][skillName][attester];
        _attestationCount[tokenId][skillName]--;
        emit AttestationRevoked(tokenId, skillName, attester);
    }

    /**
     * @dev Allows a user to claim a skill by providing on-chain verifiable proof.
     *      Requires a `Skill` to have an `attesterContract` configured for this purpose.
     *      The `attesterContract` must implement `ISkillVerifier`.
     * @param skillName The name of the skill being claimed.
     * @param proofData Arbitrary data passed to the `attesterContract` for verification.
     */
    function claimSelfAttestedSkill(string memory skillName, bytes calldata proofData) external {
        uint256 tokenId = _identities[msg.sender];
        if (tokenId == 0) {
            revert Aetherweave__IdentityNotFound();
        }
        Skill storage skill = _skills[skillName];
        if (!skill.isRegistered) {
            revert Aetherweave__SkillNotRegistered();
        }
        if (skill.attesterContract == address(0)) {
            revert Aetherweave__SelfAttestationNotSupported();
        }

        // Call the external verifier contract to verify the proof
        bool verified = ISkillVerifier(skill.attesterContract).verifyProof(tokenId, proofData);
        if (!verified) {
            revert Aetherweave__SelfAttestationProofFailed();
        }

        // If verified, record this self-attestation. The verifier contract itself acts as the attester.
        address selfAttester = skill.attesterContract;
        if (_skillAttestations[tokenId][skillName][selfAttester].timestamp != 0) {
            revert Aetherweave__AttestationAlreadyExists(); // Already self-attested via this verifier
        }

        _skillAttestations[tokenId][skillName][selfAttester] = Attestation({
            attester: selfAttester,
            timestamp: uint64(block.timestamp),
            proofURI: "" // Proof is on-chain via `proofData` and `attesterContract`
        });
        _attestationCount[tokenId][skillName]++;
        emit SelfAttestedSkillClaimed(tokenId, skillName, selfAttester);
    }

    /**
     * @dev Retrieves the definition and requirements for a specific skill.
     * @param skillName The name of the skill.
     * @return name The skill's name.
     * @return category The skill's category.
     * @return description The skill's description.
     * @return minAttestationsRequired Minimum distinct attestations needed.
     * @return attesterContract Optional contract for self-attestation.
     */
    function getSkillDetails(string memory skillName)
        public
        view
        returns (
            string memory name,
            string memory category,
            string memory description,
            uint256 minAttestationsRequired,
            address attesterContract
        )
    {
        Skill storage skill = _skills[skillName];
        if (!skill.isRegistered) {
            revert Aetherweave__SkillNotRegistered();
        }
        return (
            skill.name,
            skill.category,
            skill.description,
            skill.minAttestationsRequired,
            skill.attesterContract
        );
    }

    /**
     * @dev Retrieves the count of active attestations for a given skill on an identity.
     * @param tokenId The ID of the identity token.
     * @param skillName The name of the skill.
     * @return The number of distinct attestations for the specified skill and identity.
     */
    function getAttestationCountForSkill(uint256 tokenId, string memory skillName) public view returns (uint256) {
        if (!_skills[skillName].isRegistered) {
            revert Aetherweave__SkillNotRegistered();
        }
        if (ownerOf(tokenId) == address(0)) {
            revert Aetherweave__IdentityNotFound();
        }
        return _attestationCount[tokenId][skillName];
    }

    /**
     * @dev Checks if an identity possesses a specific skill based on attestations.
     *      An identity possesses a skill if it has at least `minAttestationsRequired` for that skill.
     * @param tokenId The ID of the identity token.
     * @param skillName The name of the skill to check.
     * @return True if the identity possesses the skill, false otherwise.
     */
    function hasSkill(uint256 tokenId, string memory skillName) public view returns (bool) {
        Skill storage skill = _skills[skillName];
        if (!skill.isRegistered) {
            return false;
        }
        if (ownerOf(tokenId) == address(0)) {
            return false;
        }
        return _attestationCount[tokenId][skillName] >= skill.minAttestationsRequired;
    }

    // --- III. Trait & Progression System ---

    /**
     * @dev Admin or SKILL_MANAGER_ROLE registers a new trait with its contributing skills and default thresholds.
     * @param traitName The unique name of the trait.
     * @param description A brief description of the trait.
     * @param contributingSkillNames An array of skill names that contribute to this trait's score.
     * @param levelThresholds An array of scores required for each level (e.g., [0, 100, 250] for levels 0, 1, 2).
     *                          Must be strictly increasing and start with 0.
     */
    function registerTrait(
        string memory traitName,
        string memory description,
        string[] memory contributingSkillNames,
        uint256[] memory levelThresholds
    ) external onlyRole(SKILL_MANAGER_ROLE) {
        if (_traits[traitName].isRegistered) {
            revert Aetherweave__TraitAlreadyRegistered();
        }
        if (levelThresholds.length == 0 || levelThresholds[0] != 0) {
            revert Aetherweave__TraitThresholdsInvalid();
        }
        for (uint256 i = 0; i < levelThresholds.length - 1; i++) {
            if (levelThresholds[i] >= levelThresholds[i+1]) {
                revert Aetherweave__TraitThresholdsInvalid();
            }
        }
        for (uint256 i = 0; i < contributingSkillNames.length; i++) {
            if (!_skills[contributingSkillNames[i]].isRegistered) {
                revert Aetherweave__SkillNotRegistered(); // All contributing skills must be registered
            }
        }

        _traits[traitName] = Trait({
            name: traitName,
            description: description,
            contributingSkillNames: contributingSkillNames,
            levelThresholds: levelThresholds,
            isRegistered: true
        });
        _registeredTraitNames.push(traitName);
        emit TraitRegistered(traitName, contributingSkillNames);
    }

    /**
     * @dev Dynamically computes a trait's numerical score from its constituent skills for an identity.
     *      Each skill (if possessed) adds 1 to the score for simplicity. More complex logic (e.g., weighted skills) can be added.
     * @param tokenId The ID of the identity token.
     * @param traitName The name of the trait to calculate.
     * @return The calculated score for the trait.
     */
    function calculateTraitScore(uint256 tokenId, string memory traitName) public view returns (uint256) {
        Trait storage trait = _traits[traitName];
        if (!trait.isRegistered) {
            revert Aetherweave__TraitNotRegistered();
        }
        if (ownerOf(tokenId) == address(0)) {
            revert Aetherweave__IdentityNotFound();
        }

        uint256 score = 0;
        for (uint256 i = 0; i < trait.contributingSkillNames.length; i++) {
            if (hasSkill(tokenId, trait.contributingSkillNames[i])) {
                score++; // Each possessed skill contributes 1 point. Can be weighted or more complex.
            }
        }
        return score;
    }

    /**
     * @dev Derives an identity's level for a given trait based on its score and thresholds.
     * @param tokenId The ID of the identity token.
     * @param traitName The name of the trait.
     * @return The current level (0-indexed) for the trait.
     */
    function getTraitLevel(uint256 tokenId, string memory traitName) public view returns (uint256) {
        Trait storage trait = _traits[traitName];
        if (!trait.isRegistered) {
            revert Aetherweave__TraitNotRegistered();
        }
        if (ownerOf(tokenId) == address(0)) {
            revert Aetherweave__IdentityNotFound();
        }

        uint256 score = calculateTraitScore(tokenId, traitName);
        uint256 currentLevel = 0;
        for (uint256 i = 0; i < trait.levelThresholds.length; i++) {
            if (score >= trait.levelThresholds[i]) {
                currentLevel = i;
            } else {
                break;
            }
        }
        return currentLevel;
    }

    /**
     * @dev Calculates a comprehensive reputation score across all registered traits for an identity.
     *      Simple sum of all trait levels. Can be extended with weights.
     * @param tokenId The ID of the identity token.
     * @return The overall reputation score.
     */
    function getOverallReputationScore(uint256 tokenId) public view returns (uint256) {
        if (ownerOf(tokenId) == address(0)) {
            revert Aetherweave__IdentityNotFound();
        }

        uint256 totalScore = 0;
        for (uint256 i = 0; i < _registeredTraitNames.length; i++) {
            totalScore += getTraitLevel(tokenId, _registeredTraitNames[i]);
        }
        return totalScore;
    }

    /**
     * @dev Admin or SKILL_MANAGER_ROLE configures the score ranges for each trait level.
     * @param traitName The name of the trait.
     * @param newThresholds An array of scores required for each level. Must be strictly increasing and start with 0.
     */
    function setTraitLevelThresholds(string memory traitName, uint256[] memory newThresholds)
        external
        onlyRole(SKILL_MANAGER_ROLE)
    {
        Trait storage trait = _traits[traitName];
        if (!trait.isRegistered) {
            revert Aetherweave__TraitNotRegistered();
        }
        if (newThresholds.length == 0 || newThresholds[0] != 0) {
            revert Aetherweave__TraitThresholdsInvalid();
        }
        for (uint256 i = 0; i < newThresholds.length - 1; i++) {
            if (newThresholds[i] >= newThresholds[i+1]) {
                revert Aetherweave__TraitThresholdsInvalid();
            }
        }
        trait.levelThresholds = newThresholds;
        emit TraitLevelThresholdsSet(traitName, newThresholds);
    }

    // --- IV. Dynamic Privilege System ---

    /**
     * @dev Admin or PRIVILEGE_MANAGER_ROLE defines a new dynamic privilege and its unlock condition.
     * @param privilegeName The unique name of the privilege.
     * @param description A brief description of the privilege.
     * @param requiredTrait The name of the trait whose level is checked for this privilege.
     * @param requiredLevel The minimum level of the `requiredTrait` to unlock this privilege.
     */
    function registerPrivilege(
        string memory privilegeName,
        string memory description,
        string memory requiredTrait,
        uint256 requiredLevel
    ) external onlyRole(PRIVILEGE_MANAGER_ROLE) {
        if (_privileges[privilegeName].isRegistered) {
            revert Aetherweave__PrivilegeAlreadyRegistered();
        }
        if (!_traits[requiredTrait].isRegistered) {
            revert Aetherweave__TraitNotRegistered();
        }

        _privileges[privilegeName] = Privilege({
            name: privilegeName,
            description: description,
            requiredTrait: requiredTrait,
            requiredLevel: requiredLevel,
            isRegistered: true
        });
        _registeredPrivilegeNames.push(privilegeName);
        emit PrivilegeRegistered(privilegeName, requiredTrait, requiredLevel);
    }

    /**
     * @dev Verifies if an identity currently meets the conditions for a specific privilege.
     * @param tokenId The ID of the identity token.
     * @param privilegeName The name of the privilege to check.
     * @return True if the identity qualifies, false otherwise.
     */
    function hasPrivilege(uint256 tokenId, string memory privilegeName) public view returns (bool) {
        Privilege storage privilege = _privileges[privilegeName];
        if (!privilege.isRegistered) {
            return false;
        }
        if (ownerOf(tokenId) == address(0)) {
            return false;
        }

        uint256 currentTraitLevel = getTraitLevel(tokenId, privilege.requiredTrait);
        return currentTraitLevel >= privilege.requiredLevel;
    }

    /**
     * @dev Lists all privileges an identity currently qualifies for.
     * @param tokenId The ID of the identity token.
     * @return An array of privilege names that the identity possesses.
     */
    function getGrantedPrivileges(uint256 tokenId) public view returns (string[] memory) {
        if (ownerOf(tokenId) == address(0)) {
            revert Aetherweave__IdentityNotFound();
        }

        uint256 count = 0;
        for (uint256 i = 0; i < _registeredPrivilegeNames.length; i++) {
            if (hasPrivilege(tokenId, _registeredPrivilegeNames[i])) {
                count++;
            }
        }

        string[] memory grantedPrivileges = new string[](count);
        uint256 currentIdx = 0;
        for (uint256 i = 0; i < _registeredPrivilegeNames.length; i++) {
            if (hasPrivilege(tokenId, _registeredPrivilegeNames[i])) {
                grantedPrivileges[currentIdx] = _registeredPrivilegeNames[i];
                currentIdx++;
            }
        }
        return grantedPrivileges;
    }

    // --- V. Role-Based Access Control ---

    /**
     * @dev Grants a specified role to an account. Only accounts with DEFAULT_ADMIN_ROLE can call this.
     * @param role The role to grant (e.g., ATTESTER_ROLE).
     * @param account The address to grant the role to.
     */
    function grantRole(bytes32 role, address account) public override onlyRole(DEFAULT_ADMIN_ROLE) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes a specified role from an account. Only accounts with DEFAULT_ADMIN_ROLE can call this.
     * @param role The role to revoke.
     * @param account The address to revoke the role from.
     */
    function revokeRole(bytes32 role, address account) public override onlyRole(DEFAULT_ADMIN_ROLE) {
        _revokeRole(role, account);
    }

    /**
     * @dev Allows an account to renounce its own role.
     * @param role The role to renounce.
     */
    function renounceRole(bytes32 role) public override {
        _renounceRole(role, _msgSender());
    }

    /**
     * @dev Assigns a specific smart contract as an authorized attester/verifier for a given skill.
     *      This `attesterContract` is used by `claimSelfAttestedSkill` to verify proofs.
     * @param skillName The name of the skill.
     * @param verifierContract The address of the contract that will act as the verifier/attester.
     */
    function setSkillAttesterContract(string memory skillName, address verifierContract)
        external
        onlyRole(SKILL_MANAGER_ROLE)
    {
        Skill storage skill = _skills[skillName];
        if (!skill.isRegistered) {
            revert Aetherweave__SkillNotRegistered();
        }
        if (verifierContract != address(0) && !Address.isContract(verifierContract)) {
            revert Aetherweave__InvalidVerifierContract();
        }
        skill.attesterContract = verifierContract;
        emit SkillRegistered(skillName, skill.category, verifierContract); // Re-emit with updated contract
    }

    // --- VI. Advanced Interactions / Challenges ---

    /**
     * @dev CHALLENGE_MANAGER_ROLE or other privileged accounts can propose on-chain challenges.
     *      These challenges, once completed, award a specific skill to the identity.
     *      A `conditionVerifierContract` (implementing `IChallengeConditionVerifier`) is used to verify completion.
     * @param challengeName Unique name for the challenge.
     * @param description A brief description of the challenge.
     * @param targetSkillName The name of the skill awarded upon completion.
     * @param conditionVerifierContract The contract that verifies the challenge completion conditions.
     */
    function proposeIdentityChallenge(
        string memory challengeName,
        string memory description,
        string memory targetSkillName,
        address conditionVerifierContract
    ) external onlyRole(CHALLENGE_MANAGER_ROLE) {
        if (_challenges[challengeName].isRegistered) {
            revert Aetherweave__ChallengeAlreadyRegistered();
        }
        if (!_skills[targetSkillName].isRegistered) {
            revert Aetherweave__SkillNotRegistered();
        }
        if (!Address.isContract(conditionVerifierContract)) {
            revert Aetherweave__InvalidVerifierContract();
        }

        _challenges[challengeName] = Challenge({
            name: challengeName,
            description: description,
            targetSkillName: targetSkillName,
            conditionVerifierContract: conditionVerifierContract,
            isRegistered: true
        });
        _registeredChallengeNames.push(challengeName);
        emit ChallengeRegistered(challengeName, targetSkillName, conditionVerifierContract);
    }

    /**
     * @dev Allows an identity owner to claim completion of a challenge.
     *      The `conditionVerifierContract` associated with the challenge is called for verification.
     *      Upon successful verification, the target skill is 'attested' by the challenge's verifier contract.
     * @param tokenId The ID of the identity token.
     * @param challengeName The name of the challenge being claimed.
     * @param proofData Optional data for the `conditionVerifierContract` to verify.
     */
    function completeIdentityChallenge(uint256 tokenId, string memory challengeName, bytes calldata proofData)
        external
    {
        if (ownerOf(tokenId) != msg.sender) {
            revert Aetherweave__NotIdentityOwner();
        }
        Challenge storage challenge = _challenges[challengeName];
        if (!challenge.isRegistered) {
            revert Aetherweave__ChallengeNotRegistered();
        }
        if (_challengeCompletion[tokenId][challengeName]) {
            revert Aetherweave__ChallengeAlreadyCompleted();
        }

        // Verify challenge condition via external contract
        bool conditionMet = IChallengeConditionVerifier(challenge.conditionVerifierContract).verifyCondition(tokenId, proofData);
        if (!conditionMet) {
            revert Aetherweave__ChallengeConditionNotMet();
        }

        // Mark challenge as completed
        _challengeCompletion[tokenId][challengeName] = true;

        // Attest the target skill using the challenge verifier contract as the attester
        address challengeAttester = challenge.conditionVerifierContract; // The challenge verifier acts as the attester
        string memory targetSkill = challenge.targetSkillName;

        // Check if this specific verifier contract has already attested this skill for this tokenId
        if (_skillAttestations[tokenId][targetSkill][challengeAttester].timestamp == 0) {
            _skillAttestations[tokenId][targetSkill][challengeAttester] = Attestation({
                attester: challengeAttester,
                timestamp: uint64(block.timestamp),
                proofURI: string(abi.encodePacked("challenge:", challengeName)) // URI indicates challenge origin
            });
            _attestationCount[tokenId][targetSkill]++;
        }
        // If already attested by this specific challenge verifier, we don't increment again,
        // but the challenge is still marked as completed.

        emit ChallengeCompleted(tokenId, challengeName, targetSkill);
    }

    /**
     * @dev Assigns a verifier contract for a specific challenge. Only CHALLENGE_MANAGER_ROLE can call this.
     * @param challengeName The name of the challenge.
     * @param verifierContract The address of the contract implementing `IChallengeConditionVerifier`.
     */
    function registerChallengeVerifier(string memory challengeName, address verifierContract)
        external
        onlyRole(CHALLENGE_MANAGER_ROLE)
    {
        Challenge storage challenge = _challenges[challengeName];
        if (!challenge.isRegistered) {
            revert Aetherweave__ChallengeNotRegistered();
        }
        if (!Address.isContract(verifierContract)) {
            revert Aetherweave__InvalidVerifierContract();
        }
        challenge.conditionVerifierContract = verifierContract;
        emit ChallengeRegistered(challengeName, challenge.targetSkillName, verifierContract); // Re-emit for update
    }

    // --- VII. Snapshotting & History ---

    /**
     * @dev Creates an immutable record of an identity's skills and traits at the current block.
     *      This is useful for historical analysis, retroactive rewards, or specific eligibility checks.
     * @param tokenId The ID of the identity token.
     * @return The unique ID of the created snapshot.
     */
    function snapshotIdentityState(uint256 tokenId) external returns (uint256) {
        if (ownerOf(tokenId) != msg.sender) {
            revert Aetherweave__NotIdentityOwner();
        }
        if (ownerOf(tokenId) == address(0)) {
            revert Aetherweave__IdentityNotFound();
        }

        _nextSnapshotId[uint224(tokenId)].increment();
        uint32 snapshotId = uint32(_nextSnapshotId[uint224(tokenId)].current());
        IdentitySnapshot storage snapshot = _identitySnapshots[uint224(tokenId)][snapshotId];

        snapshot.blockNumber = block.number;
        snapshot.timestamp = uint64(block.timestamp);

        // Snapshot skill attestations
        for (uint256 i = 0; i < _registeredSkillNames.length; i++) {
            string memory skillName = _registeredSkillNames[i];
            uint256 attCount = _attestationCount[tokenId][skillName];
            snapshot.skillAttestationCounts[skillName] = attCount;
            snapshot.snapshottedSkillNames.push(skillName); // Store names for iteration in getter
        }

        // Snapshot trait scores and levels
        for (uint256 i = 0; i < _registeredTraitNames.length; i++) {
            string memory traitName = _registeredTraitNames[i];
            uint256 score = calculateTraitScore(tokenId, traitName);
            uint256 level = getTraitLevel(tokenId, traitName);
            snapshot.traitScores[traitName] = score;
            snapshot.traitLevels[traitName] = level;
            snapshot.snapshottedTraitNames.push(traitName); // Store names for iteration in getter
        }

        emit IdentityStateSnapshotted(tokenId, snapshotId, block.number);
        return snapshotId;
    }

    /**
     * @dev Retrieves the full identity state from a specific snapshot ID.
     * @param tokenId The ID of the identity token.
     * @param snapshotId The ID of the desired snapshot.
     * @return blockNumber The block number when the snapshot was taken.
     * @return timestamp The timestamp when the snapshot was taken.
     * @return skillNames An array of skill names snapshotted.
     * @return skillAttestationCounts A corresponding array of attestation counts.
     * @return traitNames An array of trait names snapshotted.
     * @return traitScores A corresponding array of scores.
     * @return traitLevels A corresponding array of levels.
     */
    function getIdentityStateAtSnapshot(uint256 tokenId, uint256 snapshotId)
        public
        view
        returns (
            uint256 blockNumber,
            uint64 timestamp,
            string[] memory skillNames, // Array of skill names snapshotted
            uint256[] memory skillAttestationCounts, // Corresponding array of counts
            string[] memory traitNames, // Array of trait names snapshotted
            uint256[] memory traitScores, // Corresponding array of scores
            uint256[] memory traitLevels // Corresponding array of levels
        )
    {
        if (ownerOf(tokenId) == address(0)) {
            revert Aetherweave__IdentityNotFound();
        }
        if (snapshotId == 0 || snapshotId > _nextSnapshotId[uint224(tokenId)].current()) {
            revert Aetherweave__SnapshotDoesNotExist();
        }

        IdentitySnapshot storage snapshot = _identitySnapshots[uint224(tokenId)][uint32(snapshotId)];
        blockNumber = snapshot.blockNumber;
        timestamp = snapshot.timestamp;

        skillNames = new string[](snapshot.snapshottedSkillNames.length);
        skillAttestationCounts = new uint256[](snapshot.snapshottedSkillNames.length);
        for (uint256 i = 0; i < snapshot.snapshottedSkillNames.length; i++) {
            string memory skillName = snapshot.snapshottedSkillNames[i];
            skillNames[i] = skillName;
            skillAttestationCounts[i] = snapshot.skillAttestationCounts[skillName];
        }

        traitNames = new string[](snapshot.snapshottedTraitNames.length);
        traitScores = new uint256[](snapshot.snapshottedTraitNames.length);
        traitLevels = new uint256[](snapshot.snapshottedTraitNames.length);
        for (uint256 i = 0; i < snapshot.snapshottedTraitNames.length; i++) {
            string memory traitName = snapshot.snapshottedTraitNames[i];
            traitNames[i] = traitName;
            traitScores[i] = snapshot.traitScores[traitName];
            traitLevels[i] = snapshot.traitLevels[traitName];
        }
    }

    // --- ERC721 Overrides (Minimalist to allow compilation) ---
    // The core transfer/approval functions are reverted in _beforeTokenTransfer / approve / setApprovalForAll etc.
    // However, some external functions might call these, so overriding them directly to revert is safer.
    // For `tokenURI`, `supportsInterface`, `balanceOf`, `ownerOf`, `getApproved`, `isApprovedForAll`,
    // the OpenZeppelin implementation is sufficient, but we ensure transfers are blocked.
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        _requireOwned(tokenId); // Checks if tokenId exists
        return _tokenURIs[tokenId];
    }
}
```