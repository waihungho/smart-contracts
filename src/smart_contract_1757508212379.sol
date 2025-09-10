This smart contract, **AuraForge**, introduces a sophisticated decentralized protocol for on-chain identity, reputation, and skill management. It is designed to allow any Ethereum address (EOA, smart contract, or DAO) to build a dynamic, non-transferable "Aura" profile, representing their verifiable contributions, acquired skills, and accumulated reputation within an ecosystem.

AuraForge aims to be an interoperable identity layer, where other dApps and DAOs can query an agent's Aura profile to grant specific permissions, enhance governance weight, or provide exclusive access based on their on-chain track record. It combines elements of soul-bound tokens (SBTs), decentralized reputation systems, and skill-tree mechanics, supported by an attestation system, a bounty board, and basic dispute resolution.

---

## AuraForge Protocol

**Purpose:** AuraForge is a decentralized protocol for establishing, managing, and leveraging on-chain reputation and skill-trees for any Ethereum address (EOAs, smart contracts, DAOs). It provides a dynamic, non-transferable (soul-bound) "Aura" profile, allowing users to earn reputation through verifiable contributions and unlock specific "skills" or "traits" that can confer benefits, access, or enhanced governance power within integrated dApps and DAOs. It features a robust attestation system, a bounty board for coordinated tasks, and a basic dispute resolution mechanism.

**Core Concepts:**

*   **Aura Profile:** A unique, non-transferable profile for each address, tracking its categorized reputation and unlocked skills.
*   **Reputation:** Earned through verified contributions, task completion, and attestations. Reputation is categorized (e.g., `Development`, `Governance`, `Community`).
*   **Skill Tree:** Reputation points can be spent to unlock "skills" or "traits" organized into categories, granting specific on-chain capabilities, privileges, or prerequisites for higher-level skills. Skills are "soul-bound" to the profile.
*   **Attestation System:** Whitelisted entities (e.g., trusted DAOs, community leaders) can attest to a contributor's actions, boosting their reputation or validating specific contributions.
*   **Decentralized Task/Bounty Board:** A system for creating tasks, submitting proofs of completion, and rewarding participants with reputation and/or ERC20 tokens.
*   **Dispute Resolution:** A basic on-chain mechanism for arbitrators to resolve disagreements related to attestations, task outcomes, or reputation adjustments.
*   **Interoperability:** Other smart contracts can query AuraForge to check an address's reputation scores or unlocked skills for their own access control, governance, or reward distribution logic.

---

### Function Summary:

1.  `registerAuraProfile()`: Initializes a new Aura profile for the caller, making them eligible to earn reputation and unlock skills.
2.  `viewAuraProfile(address _account)`: Retrieves the metadata URI associated with an Aura profile.
3.  `setProfileMetadataURI(string memory _uri)`: Sets or updates a URI for off-chain profile metadata (e.g., avatar, description).
4.  `awardReputation(address _recipient, uint256 _amount, bytes32 _categoryHash)`: Awards reputation points to a recipient in a specific category. (Callable by Whitelisted Attesters or Arbitrators).
5.  `penalizeReputation(address _recipient, uint256 _amount, bytes32 _categoryHash)`: Deducts reputation points from a recipient in a specific category. (Callable by Arbitrators).
6.  `getReputation(address _account, bytes32 _categoryHash)`: Returns the current reputation of an account in a given category.
7.  `getTotalReputation(address _account)`: Returns the sum of all categorized reputation for an account.
8.  `defineSkillCategory(string memory _name)`: Defines a new top-level skill category (e.g., "Development"). (Callable by Owner).
9.  `defineSkill(bytes32 _categoryHash, string memory _name, uint256 _reputationCost, bytes32[] memory _prerequisites)`: Defines a new skill within a category, specifying its reputation cost and prerequisite skills. (Callable by Owner).
10. `unlockSkill(bytes32 _skillHash)`: Allows an Aura profile owner to spend their reputation to unlock a defined skill, provided prerequisites are met.
11. `hasSkill(address _account, bytes32 _skillHash)`: Checks if an account has a specific skill unlocked.
12. `attestContribution(address _contributor, bytes32 _categoryHash, string memory _proofURI)`: A whitelisted attester can vouch for a contributor's work, optionally awarding reputation. (Callable by Whitelisted Attesters).
13. `revokeAttestation(address _contributor, uint256 _attestationId)`: An attester can revoke their own previously made attestation. (Callable by Whitelisted Attesters).
14. `getAttestationIdsForAccount(address _account)`: Retrieves a list of all attestation IDs made for a specific account.
15. `getAttestationDetails(address _account, uint256 _attestationId)`: Retrieves the full details of a specific attestation.
16. `createTask(string memory _title, string memory _descriptionURI, bytes32 _requiredSkillHash, uint256 _reputationReward, bytes32 _reputationCategory, address _tokenRewardAddress, uint256 _tokenRewardAmount)`: Creates a new task that can require specific skills and offer reputation and/or ERC20 token rewards. (ERC20 tokens must be approved to the contract).
17. `submitTaskCompletion(uint256 _taskId, string memory _submissionURI)`: Submits proof of task completion for a given task.
18. `reviewTaskSubmission(uint256 _taskId, address _submitter, bool _approved)`: Task creator or owner reviews a task submission, marking it as approved or rejected.
19. `awardTaskReward(uint256 _taskId, address _submitter)`: Awards the reputation and token rewards for an approved task submission. (Callable by Task Creator).
20. `cancelTask(uint256 _taskId)`: Allows the task creator to cancel an open task and reclaim any deposited token rewards.
21. `addWhitelistedAttester(address _attester)`: Adds an address to the list of entities authorized to make attestations. (Callable by Owner).
22. `removeWhitelistedAttester(address _attester)`: Removes an address from the whitelisted attesters. (Callable by Owner).
23. `initiateDispute(uint256 _disputedEntityId, DisputeType _type, address _affectedAccount, string memory _reasonURI)`: Initiates a dispute regarding an attestation, task outcome, or a direct reputation adjustment.
24. `resolveDispute(uint256 _disputeId, bool _resolutionOutcome, uint256 _reputationAdjustment, bytes32 _categoryHash)`: Arbitrators resolve a dispute, applying consequences like reputation adjustments or attestation revocations. (Callable by Arbitrators).
25. `setArbitrator(address _arbitrator, bool _isArbitrator)`: Manages the list of addresses authorized to resolve disputes. (Callable by Owner).
26. `pause()`: Pauses the contract in case of an emergency. (Callable by Owner).
27. `unpause()`: Unpauses the contract. (Callable by Owner).

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
// import "@openzeppelin/contracts/utils/Strings.sol"; // Not directly used in current version, but useful for conversions

/**
 * @title AuraForge Protocol
 * @dev AuraForge is a decentralized protocol for establishing, managing, and leveraging on-chain reputation and
 *      skill-trees for any Ethereum address (EOAs, smart contracts, DAOs). It provides a dynamic, non-transferable
 *      (soul-bound) "Aura" profile, allowing users to earn reputation through verifiable contributions and unlock
 *      specific "skills" or "traits" that can confer benefits, access, or enhanced governance power within
 *      integrated dApps and DAOs. It features a robust attestation system, a bounty board for coordinated tasks,
 *      and a basic dispute resolution mechanism.
 *
 * Core Concepts:
 * - Aura Profile: A unique, non-transferable profile for each address, tracking its categorized reputation and unlocked skills.
 * - Reputation: Earned through verified contributions, task completion, and attestations. Can be categorized.
 * - Skill Tree: Reputation can be spent to unlock skills/traits organized into categories, granting specific on-chain capabilities or privileges.
 * - Attestation System: Reputable entities can attest to contributions, boosting reputation or meeting skill prerequisites.
 * - Interoperability: Other contracts can query AuraForge to utilize its reputation and skill data for their own logic.
 *
 * Note: This contract is designed for conceptual demonstration. Gas optimizations,
 *       advanced security audits, and more robust dispute resolution mechanisms
 *       would be required for a production environment.
 */
contract AuraForge is Ownable, Pausable {

    // --- State Variables ---

    // Mapping: account => AuraProfile
    mapping(address => AuraProfile) public auraProfiles;
    // Mapping: account => if they have registered an AuraProfile
    mapping(address => bool) public hasAuraProfile;

    // --- Skill Tree Definitions ---
    // Mapping: categoryHash => SkillCategory
    mapping(bytes32 => SkillCategory) public skillCategories;
    // Mapping: skillHash => Skill
    mapping(bytes32 => Skill) public skills;
    // Mapping: categoryHash => array of skillHashes in that category (for easier retrieval of all skills in a category)
    mapping(bytes32 => bytes32[]) public skillCategoryToSkills;
    // Global list of all defined skill category hashes, managed by admin. Used for iterating through all categories.
    bytes32[] private _definedCategoryHashes;
    // Mapping to quickly check if a category is in _definedCategoryHashes to avoid duplicates
    mapping(bytes32 => bool) private _isCategoryDefined;

    // --- Attestation System ---
    // Mapping: attesterAddress => isWhitelisted
    mapping(address => bool) public whitelistedAttesters;
    // Mapping: account => attestationId => Attestation (for easy lookup of specific attestations made *for* an account)
    mapping(address => mapping(uint256 => Attestation)) public attestationsForAccount;
    // Global counter for attestations
    uint256 private _nextAttestationId;

    // --- Task/Bounty Board ---
    // Mapping: taskId => Task
    mapping(uint256 => Task) public tasks;
    // Mapping: taskId => submitter => TaskSubmission
    mapping(uint256 => mapping(address => TaskSubmission)) public taskSubmissions;
    // Global counter for tasks
    uint256 private _nextTaskId;

    // --- Dispute Resolution ---
    // Mapping: disputeId => Dispute
    mapping(uint256 => Dispute) public disputes;
    // Mapping: address => isArbitrator
    mapping(address => bool) public arbitrators;
    // Global counter for disputes
    uint256 private _nextDisputeId;

    // --- Struct Definitions ---

    struct AuraProfile {
        string metadataURI; // URI for off-chain profile data (e.g., ENS, avatar, description)
        // Mapping: categoryHash => reputation score in that category
        mapping(bytes32 => uint256) reputation;
        // Mapping: skillHash => bool (true if unlocked) - for O(1) checks
        mapping(bytes32 => bool) unlockedSkills;
        // Array of attestation IDs made *for* this account (for easier retrieval)
        uint256[] attestationIds;
    }

    struct SkillCategory {
        string name;
        bytes32 categoryHash;
        bool exists;
    }

    struct Skill {
        string name;
        bytes32 categoryHash;
        uint256 reputationCost; // Reputation required to unlock
        bytes32[] prerequisites; // Hashes of other skills required before this one can be unlocked
        bool exists;
    }

    struct Attestation {
        uint256 id;
        address attester;
        address contributor;
        bytes32 categoryHash;
        string proofURI; // URI pointing to off-chain proof of contribution
        uint256 timestamp;
        bool revoked;
    }

    enum TaskStatus { Open, Submitted, UnderReview, Approved, Rejected, Cancelled }

    struct Task {
        uint256 id;
        address creator;
        string title;
        string descriptionURI; // URI for detailed task description
        bytes32 requiredSkillHash; // Optional: skill required to attempt the task (bytes32(0) for no requirement)
        uint256 reputationReward;
        bytes32 reputationCategory; // Category for the reputation reward
        address tokenRewardAddress; // ERC20 token address (0x0 for no token reward)
        uint256 tokenRewardAmount; // Total amount of ERC20 token reward. For single winner.
        TaskStatus status;
        uint256 creationTimestamp;
        // Mapping: submitter => bool (true if submitted)
        mapping(address => bool) hasSubmitted;
    }

    struct TaskSubmission {
        uint256 taskId;
        address submitter;
        string submissionURI; // URI for proof of completion
        uint256 submissionTimestamp;
        bool reviewed;
        bool approved; // Only relevant after review
    }

    enum DisputeType { Attestation, TaskSubmission, ReputationAdjustment }

    struct Dispute {
        uint256 id;
        address initiator;
        DisputeType disputeType;
        uint256 disputedEntityId; // Attestation ID, Task ID, or 0 for direct reputation adj.
        address affectedAccount; // The account whose reputation/attestation/task is disputed
        string reasonURI; // URI for detailed dispute reason
        bool resolved;
        bool resolutionOutcome; // true for initiator wins, false for initiator loses
        uint256 resolutionTimestamp;
        address resolver;
    }

    // --- Events ---

    event AuraProfileRegistered(address indexed account, string metadataURI);
    event AuraProfileMetadataUpdated(address indexed account, string newMetadataURI);
    event ReputationAwarded(address indexed recipient, bytes32 indexed categoryHash, uint256 amount, address indexed by);
    event ReputationPenalized(address indexed recipient, bytes32 indexed categoryHash, uint256 amount, address indexed by);
    event SkillCategoryDefined(bytes32 indexed categoryHash, string name);
    event SkillDefined(bytes32 indexed skillHash, bytes32 indexed categoryHash, string name, uint256 cost);
    event SkillUnlocked(address indexed account, bytes32 indexed skillHash, uint256 reputationSpent);
    event AttestationMade(uint256 indexed attestationId, address indexed attester, address indexed contributor, bytes32 categoryHash, string proofURI);
    event AttestationRevoked(uint256 indexed attestationId, address indexed attester);
    event WhitelistedAttesterAdded(address indexed attester);
    event WhitelistedAttesterRemoved(address indexed attester);
    event TaskCreated(uint256 indexed taskId, address indexed creator, string title, uint256 reputationReward, address tokenRewardAddress, uint256 tokenRewardAmount);
    event TaskSubmitted(uint256 indexed taskId, address indexed submitter, string submissionURI);
    event TaskReviewed(uint256 indexed taskId, address indexed submitter, bool approved);
    event TaskRewardsAwarded(uint256 indexed taskId, address indexed submitter, uint256 reputationAwarded, uint256 tokenAmountAwarded);
    event TaskCancelled(uint256 indexed taskId, address indexed creator);
    event DisputeInitiated(uint256 indexed disputeId, address indexed initiator, DisputeType disputeType, uint256 disputedEntityId, address affectedAccount);
    event DisputeResolved(uint256 indexed disputeId, address indexed resolver, bool outcome, address indexed affectedAccount);
    event ArbitratorSet(address indexed arbitrator, bool isArbitrator);

    // --- Constructor ---

    constructor(address _initialAttester) Ownable(msg.sender) {
        // Initial setup for whitelisted attester and arbitrator (owner is default)
        whitelistedAttesters[_initialAttester] = true;
        arbitrators[msg.sender] = true;
        emit WhitelistedAttesterAdded(_initialAttester);
        emit ArbitratorSet(msg.sender, true);
    }

    // --- Modifiers ---

    modifier onlyWhitelistedAttester() {
        require(whitelistedAttesters[msg.sender], "AuraForge: Caller is not a whitelisted attester");
        _;
    }

    modifier onlyArbitrator() {
        require(arbitrators[msg.sender], "AuraForge: Caller is not an arbitrator");
        _;
    }

    // --- Aura Profile Management (3 functions) ---

    /**
     * @dev Registers a new Aura profile for the caller.
     *      An account can only register one profile.
     */
    function registerAuraProfile() external whenNotPaused {
        require(!hasAuraProfile[msg.sender], "AuraForge: Profile already registered");
        hasAuraProfile[msg.sender] = true;
        // No need to explicitly initialize AuraProfile struct itself, as mappings handle default values.
        // It will be created implicitly on first access.
        emit AuraProfileRegistered(msg.sender, "");
    }

    /**
     * @dev Retrieves the metadata URI of an Aura profile.
     * @param _account The address of the account whose profile to view.
     * @return metadataURI The URI for off-chain profile data.
     */
    function viewAuraProfile(address _account) external view returns (string memory metadataURI) {
        require(hasAuraProfile[_account], "AuraForge: Profile not registered");
        return auraProfiles[_account].metadataURI;
    }

    /**
     * @dev Sets or updates the URI for off-chain profile metadata.
     * @param _uri The new URI for the profile metadata.
     */
    function setProfileMetadataURI(string memory _uri) external whenNotPaused {
        require(hasAuraProfile[msg.sender], "AuraForge: Profile not registered");
        auraProfiles[msg.sender].metadataURI = _uri;
        emit AuraProfileMetadataUpdated(msg.sender, _uri);
    }

    // --- Reputation Management (4 functions) ---

    /**
     * @dev Awards reputation points to a recipient in a specific category.
     *      Can only be called by a whitelisted attester or an arbitrator (e.g., during dispute resolution).
     * @param _recipient The address to award reputation to.
     * @param _amount The amount of reputation to award.
     * @param _categoryHash The hash of the reputation category.
     */
    function awardReputation(address _recipient, uint256 _amount, bytes32 _categoryHash) external onlyWhitelistedAttester whenNotPaused {
        require(hasAuraProfile[_recipient], "AuraForge: Recipient profile not registered");
        require(skillCategories[_categoryHash].exists, "AuraForge: Category does not exist");
        auraProfiles[_recipient].reputation[_categoryHash] += _amount;
        emit ReputationAwarded(_recipient, _categoryHash, _amount, msg.sender);
    }

    /**
     * @dev Deducts reputation points from a recipient in a specific category.
     *      Can only be called by an arbitrator.
     * @param _recipient The address to penalize.
     * @param _amount The amount of reputation to deduct.
     * @param _categoryHash The hash of the reputation category.
     */
    function penalizeReputation(address _recipient, uint256 _amount, bytes32 _categoryHash) external onlyArbitrator whenNotPaused {
        require(hasAuraProfile[_recipient], "AuraForge: Recipient profile not registered");
        require(skillCategories[_categoryHash].exists, "AuraForge: Category does not exist");
        require(auraProfiles[_recipient].reputation[_categoryHash] >= _amount, "AuraForge: Insufficient reputation to penalize");
        auraProfiles[_recipient].reputation[_categoryHash] -= _amount;
        emit ReputationPenalized(_recipient, _categoryHash, _amount, msg.sender);
    }

    /**
     * @dev Returns the current reputation of an account in a given category.
     * @param _account The address of the account.
     * @param _categoryHash The hash of the reputation category.
     * @return The reputation score.
     */
    function getReputation(address _account, bytes32 _categoryHash) external view returns (uint256) {
        require(hasAuraProfile[_account], "AuraForge: Profile not registered");
        return auraProfiles[_account].reputation[_categoryHash];
    }

    /**
     * @dev Returns the total sum of all reputation categories for an account.
     *      This function iterates over all defined categories, so gas cost scales with number of categories.
     * @param _account The address of the account.
     * @return The total reputation score.
     */
    function getTotalReputation(address _account) external view returns (uint256) {
        require(hasAuraProfile[_account], "AuraForge: Profile not registered");
        uint256 total = 0;
        for (uint256 i = 0; i < _definedCategoryHashes.length; i++) {
            total += auraProfiles[_account].reputation[_definedCategoryHashes[i]];
        }
        return total;
    }

    // --- Skill Tree Management (5 functions) ---

    /**
     * @dev Defines a new top-level skill category.
     *      Only callable by the contract owner.
     * @param _name The name of the skill category.
     * @return The hash of the newly defined category.
     */
    function defineSkillCategory(string memory _name) external onlyOwner whenNotPaused returns (bytes32) {
        bytes32 categoryHash = keccak256(abi.encodePacked(_name));
        require(!skillCategories[categoryHash].exists, "AuraForge: Skill category already exists");
        skillCategories[categoryHash] = SkillCategory(_name, categoryHash, true);

        if (!_isCategoryDefined[categoryHash]) {
            _definedCategoryHashes.push(categoryHash);
            _isCategoryDefined[categoryHash] = true;
        }

        emit SkillCategoryDefined(categoryHash, _name);
        return categoryHash;
    }

    /**
     * @dev Defines a new skill within a category, specifying its reputation cost and prerequisite skills.
     *      Only callable by the contract owner.
     * @param _categoryHash The hash of the skill category this skill belongs to.
     * @param _name The name of the skill.
     * @param _reputationCost The reputation points required to unlock this skill.
     * @param _prerequisites Array of skill hashes that must be unlocked first.
     * @return The hash of the newly defined skill.
     */
    function defineSkill(
        bytes32 _categoryHash,
        string memory _name,
        uint256 _reputationCost,
        bytes32[] memory _prerequisites
    ) external onlyOwner whenNotPaused returns (bytes32) {
        require(skillCategories[_categoryHash].exists, "AuraForge: Skill category does not exist");
        bytes32 skillHash = keccak256(abi.encodePacked(_categoryHash, _name));
        require(!skills[skillHash].exists, "AuraForge: Skill already exists in this category");

        // Validate prerequisites
        for (uint256 i = 0; i < _prerequisites.length; i++) {
            require(skills[_prerequisites[i]].exists, "AuraForge: Prerequisite skill does not exist");
        }

        skills[skillHash] = Skill(_name, _categoryHash, _reputationCost, _prerequisites, true);
        skillCategoryToSkills[_categoryHash].push(skillHash); // Add to category's list of skills
        emit SkillDefined(skillHash, _categoryHash, _name, _reputationCost);
        return skillHash;
    }

    /**
     * @dev Allows an Aura profile owner to spend reputation to unlock a defined skill.
     * @param _skillHash The hash of the skill to unlock.
     */
    function unlockSkill(bytes32 _skillHash) external whenNotPaused {
        require(hasAuraProfile[msg.sender], "AuraForge: Profile not registered");
        require(skills[_skillHash].exists, "AuraForge: Skill does not exist");
        require(!auraProfiles[msg.sender].unlockedSkills[_skillHash], "AuraForge: Skill already unlocked");

        Skill storage skillToUnlock = skills[_skillHash];
        require(auraProfiles[msg.sender].reputation[skillToUnlock.categoryHash] >= skillToUnlock.reputationCost, "AuraForge: Insufficient reputation to unlock skill");

        // Check prerequisites
        for (uint256 i = 0; i < skillToUnlock.prerequisites.length; i++) {
            require(auraProfiles[msg.sender].unlockedSkills[skillToUnlock.prerequisites[i]], "AuraForge: Prerequisite skill not met");
        }

        auraProfiles[msg.sender].reputation[skillToUnlock.categoryHash] -= skillToUnlock.reputationCost;
        auraProfiles[msg.sender].unlockedSkills[_skillHash] = true;
        emit SkillUnlocked(msg.sender, _skillHash, skillToUnlock.reputationCost);
    }

    /**
     * @dev Checks if an account has a specific skill unlocked.
     * @param _account The address of the account.
     * @param _skillHash The hash of the skill.
     * @return True if the skill is unlocked, false otherwise.
     */
    function hasSkill(address _account, bytes32 _skillHash) external view returns (bool) {
        require(hasAuraProfile[_account], "AuraForge: Profile not registered");
        return auraProfiles[_account].unlockedSkills[_skillHash];
    }

    // --- Attestation System (4 functions) ---

    /**
     * @dev A whitelisted attester can vouch for a contributor's work or positive action.
     *      Awards no reputation by default; explicit `awardReputation` should be used for that.
     * @param _contributor The address of the account being attested for.
     * @param _categoryHash The reputation category this attestation falls under.
     * @param _proofURI URI pointing to off-chain proof of contribution/action.
     * @return The ID of the newly created attestation.
     */
    function attestContribution(address _contributor, bytes32 _categoryHash, string memory _proofURI) external onlyWhitelistedAttester whenNotPaused returns (uint256) {
        require(hasAuraProfile[_contributor], "AuraForge: Contributor profile not registered");
        require(skillCategories[_categoryHash].exists, "AuraForge: Category does not exist");
        require(msg.sender != _contributor, "AuraForge: Cannot attest to your own contribution");

        _nextAttestationId++;
        attestationsForAccount[_contributor][_nextAttestationId] = Attestation(
            _nextAttestationId,
            msg.sender,
            _contributor,
            _categoryHash,
            _proofURI,
            block.timestamp,
            false
        );
        // Add attestation ID to the contributor's profile for easy lookup
        auraProfiles[_contributor].attestationIds.push(_nextAttestationId);

        emit AttestationMade(_nextAttestationId, msg.sender, _contributor, _categoryHash, _proofURI);
        return _nextAttestationId;
    }

    /**
     * @dev An attester can revoke their own attestation.
     * @param _contributor The address of the account whose attestation is being revoked.
     * @param _attestationId The ID of the attestation to revoke.
     */
    function revokeAttestation(address _contributor, uint256 _attestationId) external onlyWhitelistedAttester whenNotPaused {
        Attestation storage att = attestationsForAccount[_contributor][_attestationId];
        require(att.attester == msg.sender, "AuraForge: Only the original attester can revoke");
        require(!att.revoked, "AuraForge: Attestation already revoked");

        att.revoked = true;
        emit AttestationRevoked(_attestationId, msg.sender);
    }

    /**
     * @dev Retrieves a list of all attestation IDs made for a specific account.
     * @param _account The address of the account.
     * @return An array of attestation IDs.
     */
    function getAttestationIdsForAccount(address _account) external view returns (uint256[] memory) {
        require(hasAuraProfile[_account], "AuraForge: Profile not registered");
        return auraProfiles[_account].attestationIds;
    }

    /**
     * @dev Retrieves details of a specific attestation.
     * @param _account The account the attestation was made for.
     * @param _attestationId The ID of the attestation.
     * @return The Attestation struct details.
     */
    function getAttestationDetails(address _account, uint256 _attestationId) external view returns (Attestation memory) {
        require(hasAuraProfile[_account], "AuraForge: Profile not registered");
        Attestation memory att = attestationsForAccount[_account][_attestationId];
        require(att.id == _attestationId, "AuraForge: Attestation not found for this account/ID");
        return att;
    }

    // --- Task/Bounty Board (5 functions) ---

    /**
     * @dev Creates a new task that requires a specific skill and offers reputation and/or token rewards.
     *      ERC20 tokens for rewards must be approved to this contract beforehand by the creator.
     * @param _title The title of the task.
     * @param _descriptionURI URI for detailed task description.
     * @param _requiredSkillHash The hash of the skill required to attempt this task (bytes32(0) for no skill requirement).
     * @param _reputationReward Reputation points awarded upon completion.
     * @param _reputationCategory The category for the reputation reward.
     * @param _tokenRewardAddress ERC20 token address (0x0 for no token reward).
     * @param _tokenRewardAmount Amount of ERC20 token reward.
     * @return The ID of the newly created task.
     */
    function createTask(
        string memory _title,
        string memory _descriptionURI,
        bytes32 _requiredSkillHash,
        uint256 _reputationReward,
        bytes32 _reputationCategory,
        address _tokenRewardAddress,
        uint256 _tokenRewardAmount
    ) external whenNotPaused returns (uint256) {
        if (_requiredSkillHash != bytes32(0)) {
            require(skills[_requiredSkillHash].exists, "AuraForge: Required skill does not exist");
        }
        if (_reputationReward > 0) {
            require(skillCategories[_reputationCategory].exists, "AuraForge: Reputation category for reward does not exist");
        }

        _nextTaskId++;
        tasks[_nextTaskId] = Task(
            _nextTaskId,
            msg.sender,
            _title,
            _descriptionURI,
            _requiredSkillHash,
            _reputationReward,
            _reputationCategory,
            _tokenRewardAddress,
            _tokenRewardAmount,
            TaskStatus.Open,
            block.timestamp
        );

        if (_tokenRewardAmount > 0) {
            require(_tokenRewardAddress != address(0), "AuraForge: Token reward address cannot be zero for non-zero amount");
            IERC20(_tokenRewardAddress).transferFrom(msg.sender, address(this), _tokenRewardAmount);
        }

        emit TaskCreated(_nextTaskId, msg.sender, _title, _reputationReward, _tokenRewardAddress, _tokenRewardAmount);
        return _nextTaskId;
    }

    /**
     * @dev Submits proof of task completion.
     * @param _taskId The ID of the task.
     * @param _submissionURI URI for proof of completion.
     */
    function submitTaskCompletion(uint256 _taskId, string memory _submissionURI) external whenNotPaused {
        Task storage task = tasks[_taskId];
        require(task.status == TaskStatus.Open, "AuraForge: Task is not open for submission");
        require(task.creator != msg.sender, "AuraForge: Task creator cannot submit their own task");
        require(!task.hasSubmitted[msg.sender], "AuraForge: Already submitted for this task");
        require(hasAuraProfile[msg.sender], "AuraForge: Submitter profile not registered");

        if (task.requiredSkillHash != bytes32(0)) {
            require(auraProfiles[msg.sender].unlockedSkills[task.requiredSkillHash], "AuraForge: Submitter does not have required skill");
        }

        taskSubmissions[_taskId][msg.sender] = TaskSubmission(
            _taskId,
            msg.sender,
            _submissionURI,
            block.timestamp,
            false,
            false
        );
        task.hasSubmitted[msg.sender] = true;

        emit TaskSubmitted(_taskId, msg.sender, _submissionURI);
    }

    /**
     * @dev Task creator or a designated reviewer approves or rejects a submission.
     * @param _taskId The ID of the task.
     * @param _submitter The address of the account that submitted the task.
     * @param _approved True to approve, false to reject.
     */
    function reviewTaskSubmission(uint256 _taskId, address _submitter, bool _approved) external whenNotPaused {
        Task storage task = tasks[_taskId];
        require(task.creator == msg.sender || Ownable(address(this)).owner() == msg.sender, "AuraForge: Only task creator or owner can review");
        TaskSubmission storage submission = taskSubmissions[_taskId][_submitter];
        require(submission.submitter == _submitter, "AuraForge: Submission not found for this user");
        require(!submission.reviewed, "AuraForge: Submission already reviewed");
        require(task.status != TaskStatus.Cancelled, "AuraForge: Cannot review a cancelled task");

        submission.reviewed = true;
        submission.approved = _approved;

        emit TaskReviewed(_taskId, _submitter, _approved);
    }

    /**
     * @dev Awards the reputation and token rewards for an approved task.
     *      Only callable by the task creator after a submission has been approved.
     * @param _taskId The ID of the task.
     * @param _submitter The address of the account that submitted the task.
     */
    function awardTaskReward(uint256 _taskId, address _submitter) external whenNotPaused {
        Task storage task = tasks[_taskId];
        require(task.creator == msg.sender, "AuraForge: Only task creator can award rewards");
        TaskSubmission storage submission = taskSubmissions[_taskId][_submitter];
        require(submission.submitter == _submitter, "AuraForge: Submission not found for this user");
        require(submission.reviewed && submission.approved, "AuraForge: Submission not reviewed or not approved");
        require(task.status != TaskStatus.Cancelled, "AuraForge: Cannot award rewards for a cancelled task");
        
        // Mark submission as processed by setting approved to false
        // This is a simple way to prevent double awarding. In a more complex system,
        // a dedicated `rewardClaimed` flag might be more appropriate.
        require(submission.approved, "AuraForge: Reward already claimed or submission not approved");
        submission.approved = false; 

        // Award reputation
        if (task.reputationReward > 0) {
            if (!hasAuraProfile[_submitter]) {
                // If the submitter doesn't have a profile, register one for them.
                hasAuraProfile[_submitter] = true;
                emit AuraProfileRegistered(_submitter, "");
            }
            auraProfiles[_submitter].reputation[task.reputationCategory] += task.reputationReward;
        }

        // Transfer token reward
        uint256 tokenAmountAwarded = 0;
        if (task.tokenRewardAmount > 0 && task.tokenRewardAddress != address(0)) {
            IERC20(task.tokenRewardAddress).transfer(_submitter, task.tokenRewardAmount);
            tokenAmountAwarded = task.tokenRewardAmount;
            // Clear the token reward amount from the task to prevent re-awarding.
            task.tokenRewardAmount = 0;
            task.tokenRewardAddress = address(0); // Clear address too
        }

        emit TaskRewardsAwarded(_taskId, _submitter, task.reputationReward, tokenAmountAwarded);
    }

    /**
     * @dev Allows the task creator to cancel an outstanding task and reclaim token rewards.
     * @param _taskId The ID of the task to cancel.
     */
    function cancelTask(uint256 _taskId) external whenNotPaused {
        Task storage task = tasks[_taskId];
        require(task.creator == msg.sender, "AuraForge: Only task creator can cancel");
        require(task.status == TaskStatus.Open, "AuraForge: Task is not open to be cancelled");

        task.status = TaskStatus.Cancelled;

        // Refund token rewards to creator
        if (task.tokenRewardAmount > 0 && task.tokenRewardAddress != address(0)) {
            IERC20(task.tokenRewardAddress).transfer(task.creator, task.tokenRewardAmount);
            task.tokenRewardAmount = 0; // Clear remaining reward
        }

        emit TaskCancelled(_taskId, msg.sender);
    }

    // --- Whitelisted Attesters Management (2 functions) ---

    /**
     * @dev Adds an address to the list of entities authorized to make attestations.
     *      Only callable by the contract owner.
     * @param _attester The address to whitelist.
     */
    function addWhitelistedAttester(address _attester) external onlyOwner whenNotPaused {
        require(!whitelistedAttesters[_attester], "AuraForge: Attester already whitelisted");
        whitelistedAttesters[_attester] = true;
        emit WhitelistedAttesterAdded(_attester);
    }

    /**
     * @dev Removes an address from the whitelisted attesters.
     *      Only callable by the contract owner.
     * @param _attester The address to remove.
     */
    function removeWhitelistedAttester(address _attester) external onlyOwner whenNotPaused {
        require(whitelistedAttesters[_attester], "AuraForge: Attester not whitelisted");
        whitelistedAttesters[_attester] = false;
        emit WhitelistedAttesterRemoved(_attester);
    }

    // --- Dispute Resolution (3 functions) ---

    /**
     * @dev Initiates a dispute regarding an attestation, task outcome, or direct reputation adjustment.
     * @param _disputedEntityId The ID of the disputed entity (attestation ID, task ID, or 0 for direct rep adj).
     * @param _type The type of dispute.
     * @param _affectedAccount The account directly affected by the dispute (e.g., contributor in attestation, submitter in task).
     * @param _reasonURI URI for detailed dispute reason.
     * @return The ID of the newly created dispute.
     */
    function initiateDispute(
        uint256 _disputedEntityId,
        DisputeType _type,
        address _affectedAccount,
        string memory _reasonURI
    ) external whenNotPaused returns (uint256) {
        require(hasAuraProfile[_affectedAccount], "AuraForge: Affected account profile not registered");

        _nextDisputeId++;
        disputes[_nextDisputeId] = Dispute(
            _nextDisputeId,
            msg.sender,
            _type,
            _disputedEntityId,
            _affectedAccount,
            _reasonURI,
            false,
            false, // Default resolution outcome
            0,
            address(0)
        );

        emit DisputeInitiated(_nextDisputeId, msg.sender, _type, _disputedEntityId, _affectedAccount);
        return _nextDisputeId;
    }

    /**
     * @dev Arbitrators resolve a dispute, applying consequences based on resolution.
     *      Only callable by a designated arbitrator.
     * @param _disputeId The ID of the dispute to resolve.
     * @param _resolutionOutcome True if the initiator's claim is upheld (e.g., attestation revoked, penalty applied).
     * @param _reputationAdjustment Optional: amount to adjust reputation by. (0 for no adjustment).
     * @param _categoryHash Optional: category for reputation adjustment. (bytes32(0) for no adjustment).
     */
    function resolveDispute(
        uint256 _disputeId,
        bool _resolutionOutcome,
        uint256 _reputationAdjustment,
        bytes32 _categoryHash
    ) external onlyArbitrator whenNotPaused {
        Dispute storage dispute = disputes[_disputeId];
        require(dispute.id == _disputeId, "AuraForge: Dispute not found");
        require(!dispute.resolved, "AuraForge: Dispute already resolved");

        dispute.resolved = true;
        dispute.resolutionOutcome = _resolutionOutcome;
        dispute.resolutionTimestamp = block.timestamp;
        dispute.resolver = msg.sender;

        // Apply reputation consequences if specified
        if (_reputationAdjustment > 0) {
            require(skillCategories[_categoryHash].exists, "AuraForge: Category for reputation adjustment does not exist");
            if (_resolutionOutcome) { // Initiator wins, typically implies a negative action against the affected
                penalizeReputation(dispute.affectedAccount, _reputationAdjustment, _categoryHash);
            } else { // Initiator loses, maybe affected account gets a small award (optional logic not included for simplicity)
                // awardReputation(dispute.affectedAccount, _reputationAdjustment / 10, _categoryHash); // Example
            }
        }

        // Apply further actions based on dispute type
        if (dispute.disputeType == DisputeType.Attestation) {
            Attestation storage att = attestationsForAccount[dispute.affectedAccount][dispute.disputedEntityId];
            if (att.id != 0 && _resolutionOutcome) { // If attestation exists and initiator wins (attestation deemed invalid)
                att.revoked = true;
                emit AttestationRevoked(dispute.disputedEntityId, att.attester);
            }
        } else if (dispute.disputeType == DisputeType.TaskSubmission) {
            // For task submissions, an arbitrator might call reviewTaskSubmission directly,
            // or this can definitively mark the submission in a specific way.
            // For now, the reputation adjustment is the primary effect in this simplified design.
        }

        emit DisputeResolved(_disputeId, msg.sender, _resolutionOutcome, dispute.affectedAccount);
    }

    /**
     * @dev Manages the list of addresses authorized to resolve disputes.
     *      Only callable by the contract owner.
     * @param _arbitrator The address to set/unset as an arbitrator.
     * @param _isArbitrator True to make them an arbitrator, false to remove.
     */
    function setArbitrator(address _arbitrator, bool _isArbitrator) external onlyOwner whenNotPaused {
        require(arbitrators[_arbitrator] != _isArbitrator, "AuraForge: Arbitrator status already set to this value");
        arbitrators[_arbitrator] = _isArbitrator;
        emit ArbitratorSet(_arbitrator, _isArbitrator);
    }

    // --- Pausable override (2 functions) ---

    /**
     * @dev Pauses the contract, preventing most state-changing operations.
     *      Only callable by the contract owner.
     */
    function pause() public onlyOwner override {
        super.pause();
    }

    /**
     * @dev Unpauses the contract, allowing operations to resume.
     *      Only callable by the contract owner.
     */
    function unpause() public onlyOwner override {
        super.unpause();
    }
}
```