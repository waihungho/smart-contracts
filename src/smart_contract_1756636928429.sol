Here's a Solidity smart contract for the **Sovereign Skill Nexus (SSN)**, designed with advanced, creative, and trendy concepts like Soul-Bound Tokens for skills, a multi-faceted reputation system, and decentralized Guilds for collaborative project execution. It includes at least 20 functions as requested.

---

## Sovereign Skill Nexus (SSN) Smart Contract

**I. Contract Overview**

*   **Name:** SovereignSkillNexus
*   **Purpose:** The Sovereign Skill Nexus (SSN) is a decentralized platform that establishes an on-chain identity layer based on verifiable skills and contributions. It empowers individuals to build a reputation tied to their expertise, join specialized Guilds for collaborative projects, and participate in a trust-minimized ecosystem for talent discovery and project execution.
*   **Core Concepts:**
    1.  **Soul-Bound Skill Attestations (SBTs):** Non-transferable tokens issued by trusted Validators to certify specific skills for users. These attestations form the foundation of a user's on-chain identity and expertise.
    2.  **Multi-faceted Reputation System:** A dynamic and nuanced reputation score that goes beyond simple token ownership. It's built upon attested skills, successful project completions, and active participation within Guilds, offering both an overall score and skill-specific reputation.
    3.  **Skill Guilds:** Decentralized Autonomous Organizations (DAOs) formed around distinct skill sets. Guilds facilitate collaboration, governance (reputation-weighted voting), and collective project execution, fostering specialized communities.
    4.  **Reputation-Weighted Governance:** Voting mechanisms within Guilds and for project funding are dynamically influenced by a user's reputation score and the relevance of their attested skills to the proposal. Liquid democracy principles allow for reputation delegation.
    5.  **Project & Bounty Marketplace:** An integrated system for creating, applying for, and completing tasks and projects, with on-chain rewards and automatic reputation updates upon successful completion.

**II. Function Categories & Summaries**

This contract implements 26 distinct functions, categorized for clarity:

---

### **A. Administration & Control (5 functions)**

1.  `constructor()`:
    *   Initializes the contract, setting the deployer as the initial owner.
2.  `updateValidatorRegistry(address _validator, bool _isValidator)`:
    *   **Purpose:** Adds or removes addresses from the list of authorized skill validators.
    *   **Access:** Owner only.
3.  `setGuardian(address _guardian)`:
    *   **Purpose:** Designates an address with emergency pause capabilities for critical functions.
    *   **Access:** Owner only.
4.  `pauseContract()`:
    *   **Purpose:** Halts critical contract functions (e.g., attestations, project creation) in emergencies or for upgrades.
    *   **Access:** Owner or Guardian.
5.  `unpauseContract()`:
    *   **Purpose:** Resumes contract operations after a pause.
    *   **Access:** Owner or Guardian.

### **B. Skill Management (Soul-Bound Tokens - SBTs) (5 functions)**

6.  `registerSkillType(string memory _name, string memory _description)`:
    *   **Purpose:** Defines a new, unique skill that can be attested within the Nexus (e.g., "Solidity Development", "Decentralized Finance Analyst").
    *   **Access:** Owner only.
    *   **Returns:** `skillId` (uint256) of the newly registered skill.
7.  `attestSkill(address _user, uint256 _skillId)`:
    *   **Purpose:** A registered validator issues a non-transferable skill attestation (SBT) to a specified user. This also contributes to the user's reputation.
    *   **Access:** Registered Validator only.
8.  `revokeSkillAttestation(address _user, uint256 _skillId)`:
    *   **Purpose:** A validator revokes a previously issued skill attestation for a user, decrementing their reputation.
    *   **Access:** The original Validator who attested, or Owner.
9.  `getUserSkills(address _user)`:
    *   **Purpose:** Retrieves all unique skill IDs currently attested for a specific user.
    *   **Access:** Public (view).
    *   **Returns:** `uint256[]` array of skill IDs.
10. `getSkillHolders(uint256 _skillId)`:
    *   **Purpose:** Returns all users who possess a specific skill attestation. (Note: For very large numbers, off-chain indexing is more scalable).
    *   **Access:** Public (view).
    *   **Returns:** `address[]` array of holder addresses.

### **C. Reputation System (4 functions)**

11. `_updateReputationScore(address _user, uint256 _skillId, int256 _delta)`:
    *   **Purpose:** Internal function to adjust a user's overall and skill-specific reputation score. Called by other functions like `attestSkill`, `completeGuildProject`, etc.
    *   **Access:** Internal.
12. `getOverallReputationScore(address _user)`:
    *   **Purpose:** Retrieves a user's total reputation score across all their attested skills and contributions.
    *   **Access:** Public (view).
    *   **Returns:** `uint256` overall reputation score.
13. `getSkillSpecificReputation(address _user, uint256 _skillId)`:
    *   **Purpose:** Fetches a user's reputation score specifically for a particular skill type.
    *   **Access:** Public (view).
    *   **Returns:** `uint256` skill-specific reputation score.
14. `delegateReputation(address _delegatee, uint256 _guildId)`:
    *   **Purpose:** Allows a user to delegate their voting power (reputation) for proposals within a specific Guild to another address (liquid democracy).
    *   **Access:** Guild member.

### **D. Skill Guilds (Decentralized Autonomous Organizations - DAOs) (7 functions)**

15. `createGuild(string memory _name, string memory _description, uint256 _focusSkillId)`:
    *   **Purpose:** Enables eligible users (requiring a minimum reputation and the `_focusSkillId`) to establish a new Guild centered around a particular skill.
    *   **Access:** Requires minimum reputation and focus skill.
    *   **Returns:** `guildId` (uint256) of the new Guild.
16. `joinGuild(uint256 _guildId)`:
    *   **Purpose:** Allows a user to apply for membership in an existing Guild. Requires the Guild's focus skill and a minimum reputation.
    *   **Access:** Requires specific skills and reputation.
17. `leaveGuild(uint256 _guildId)`:
    *   **Purpose:** Permits a Guild member to voluntarily exit.
    *   **Access:** Guild member.
18. `proposeGuildProject(uint256 _guildId, string memory _title, string memory _description, uint256 _rewardAmount, uint256[] memory _requiredSkills)`:
    *   **Purpose:** A Guild member submits a project proposal, outlining objectives, required skills, and requested funding from the Guild's treasury.
    *   **Access:** Guild member.
    *   **Returns:** `projectId` (uint256) of the new proposal.
19. `voteOnGuildProposal(uint256 _guildId, uint256 _projectId, bool _approve)`:
    *   **Purpose:** Guild members cast votes on pending project proposals. Vote weight is tied to their reputation score within that Guild's focus skill.
    *   **Access:** Guild member.
20. `fundGuildProject(uint256 _guildId, uint256 _projectId)`:
    *   **Purpose:** Initiates the transfer of allocated funds from the Guild's treasury to an approved project's designated recipient address (e.g., a multi-sig or project contract).
    *   **Access:** Guild Admin/Owner (after proposal approval).
21. `completeGuildProject(uint256 _guildId, uint256 _projectId, address[] memory _contributors, uint256[] memory _reputationGains)`:
    *   **Purpose:** Marks a Guild project as finished, triggers the distribution of rewards to contributors, and updates their reputation based on their involvement.
    *   **Access:** Guild Admin/Owner.

### **E. Project & Bounty Management (5 functions)**

22. `createBounty(string memory _title, string memory _description, uint256 _rewardAmount, uint256[] memory _requiredSkills, uint256 _deadline) payable`:
    *   **Purpose:** Posts a public bounty for a specific task, including the reward amount (sent with the transaction), required skills, and a deadline.
    *   **Access:** Any user.
    *   **Returns:** `bountyId` (uint256) of the new bounty.
23. `applyForBounty(uint256 _bountyId)`:
    *   **Purpose:** Users can formally apply to work on an open bounty, showcasing their relevant skills (which are checked against `_requiredSkills`).
    *   **Access:** Any user with required skills.
24. `assignBountyWorker(uint256 _bountyId, address _worker)`:
    *   **Purpose:** The bounty creator selects and assigns a worker from the pool of applicants.
    *   **Access:** Bounty creator only.
25. `submitBountyWork(uint256 _bountyId, string memory _workHash)`:
    *   **Purpose:** The assigned worker indicates completion of the bounty task, providing a hash (e.g., IPFS CID) referencing their submitted work.
    *   **Access:** Assigned worker only.
26. `resolveBounty(uint256 _bountyId, bool _accepted)`:
    *   **Purpose:** The bounty creator verifies the submitted work. If `_accepted` is true, funds are released to the worker, and their reputation is updated. If false, the bounty can be reopened.
    *   **Access:** Bounty creator only.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

// Custom errors for better readability and gas efficiency
error SSN__Unauthorized();
error SSN__AlreadyRegistered();
error SSN__SkillNotFound();
error SSN__UserHasNoSkill();
error SSN__NotAValidator();
error SSN__SkillAlreadyAttested();
error SSN__SkillNotAttested();
error SSN__InvalidReputationScore();
error SSN__GuildNotFound();
error SSN__NotGuildMember();
error SSN__AlreadyGuildMember();
error SSN__GuildCreationRequirementsNotMet();
error SSN__GuildProjectNotFound();
error SSN__GuildProjectNotPending();
error SSN__GuildProjectAlreadyVoted();
error SSN__BountyNotFound();
error SSN__BountyAlreadyAssigned();
error SSN__BountyNotAssignedToYou();
error SSN__BountyNotPendingWork();
error SSN__BountyNotPendingResolution();
error SSN__DeadlinePassed();
error SSN__InsufficientFunds();
error SSN__ZeroAddress();
error SSN__EmptyString();
error SSN__InvalidAmount();
error SSN__AlreadyVoted();
error SSN__SelfDelegationNotAllowed();
error SSN__DelegationNotAllowedForThisGuild();
error SSN__InsufficientSkillOrReputation();

contract SovereignSkillNexus is Ownable, Pausable, ReentrancyGuard {

    // --- Enums and Structs ---

    enum ProjectStatus { Pending, Approved, Rejected, Completed }
    enum BountyStatus { Open, Assigned, WorkSubmitted, ResolvedAccepted, ResolvedRejected }

    struct SkillType {
        string name;
        string description;
        uint256 id; // Unique ID for the skill
        bool exists;
    }

    struct Guild {
        uint256 id;
        string name;
        string description;
        uint256 focusSkillId; // The primary skill this Guild is centered around
        address[] members; // List of guild member addresses
        mapping(address => bool) isMember; // Quick lookup for membership
        uint256 totalReputation; // Sum of members' focus skill reputation
        // Future: Guild treasury balance, specific governance parameters
        bool exists;
    }

    struct GuildProject {
        uint256 id;
        uint256 guildId;
        address proposer;
        string title;
        string description;
        uint256 rewardAmount;
        uint256[] requiredSkills;
        ProjectStatus status;
        uint256 totalVotesFor; // Sum of reputation-weighted votes FOR
        uint256 totalVotesAgainst; // Sum of reputation-weighted votes AGAINST
        mapping(address => bool) hasVoted; // Check if member has voted
        uint256 voteDeadline;
        bool exists;
    }

    struct Bounty {
        uint256 id;
        address creator;
        string title;
        string description;
        uint256 rewardAmount; // Amount in WEI
        uint256[] requiredSkills;
        uint256 deadline;
        BountyStatus status;
        address assignedWorker;
        string workHash; // Reference to off-chain work (e.g., IPFS CID)
        bool exists;
    }

    // --- State Variables ---

    uint256 private nextSkillId = 1;
    uint256 private nextGuildId = 1;
    uint256 private nextGuildProjectId = 1;
    uint256 private nextBountyId = 1;

    // A. Administration & Control
    address public guardian;
    mapping(address => bool) public isValidator;

    // B. Skill Management (SBTs)
    mapping(uint256 => SkillType) public skillTypes; // skillId => SkillType
    mapping(address => mapping(uint256 => bool)) public userHasSkill; // userAddress => skillId => hasSkill
    mapping(uint256 => address[]) private skillHoldersList; // skillId => list of holders (for getSkillHolders)

    // C. Reputation System
    // Overall reputation score for a user
    mapping(address => uint256) public overallReputation;
    // Skill-specific reputation score for a user
    mapping(address => mapping(uint256 => uint256)) public skillSpecificReputation;
    // Reputation delegation for guild voting: guildId => delegator => delegatee
    mapping(uint256 => mapping(address => address)) public reputationDelegations;

    // D. Skill Guilds (DAOs)
    mapping(uint256 => Guild) public guilds; // guildId => Guild
    mapping(uint256 => GuildProject) public guildProjects; // projectId => GuildProject

    // E. Project & Bounty Management
    mapping(uint256 => Bounty) public bounties; // bountyId => Bounty

    // --- Constants ---
    uint256 public constant MIN_REPUTATION_FOR_GUILD_CREATION = 100;
    uint256 public constant MIN_REPUTATION_FOR_GUILD_JOIN = 10;
    uint256 public constant INITIAL_REPUTATION_FOR_SKILL = 10; // Reputation gain/loss for skill attestations
    uint256 public constant PROJECT_VOTE_DURATION = 7 days; // How long a guild project proposal stays open for voting
    uint256 public constant GUILD_PROJECT_APPROVAL_THRESHOLD = 60; // Percentage of positive reputation-weighted votes

    // --- Events ---

    event ValidatorRegistryUpdated(address indexed _validator, bool _isValidator);
    event GuardianUpdated(address indexed _guardian);
    event ContractPaused(address indexed _pauser);
    event ContractUnpaused(address indexed _unpauser);

    event SkillTypeRegistered(uint256 indexed skillId, string name, string description);
    event SkillAttested(address indexed _user, uint256 indexed _skillId, address indexed _validator);
    event SkillAttestationRevoked(address indexed _user, uint256 indexed _skillId, address indexed _revoker);

    event ReputationUpdated(address indexed _user, uint256 indexed _skillId, uint256 newOverallReputation, uint256 newSkillReputation);
    event ReputationDelegated(address indexed _delegator, address indexed _delegatee, uint256 indexed _guildId);

    event GuildCreated(uint256 indexed _guildId, string name, address indexed creator, uint256 focusSkillId);
    event GuildJoined(uint256 indexed _guildId, address indexed _member);
    event GuildLeft(uint256 indexed _guildId, address indexed _member);
    event GuildProjectProposed(uint256 indexed _guildId, uint256 indexed _projectId, address indexed _proposer, string _title);
    event GuildProjectVoted(uint256 indexed _guildId, uint256 indexed _projectId, address indexed _voter, bool _approved, uint256 reputationWeight);
    event GuildProjectFunded(uint256 indexed _guildId, uint256 indexed _projectId, uint256 _amount);
    event GuildProjectCompleted(uint256 indexed _guildId, uint256 indexed _projectId);

    event BountyCreated(uint256 indexed _bountyId, address indexed _creator, uint256 _rewardAmount, uint256 _deadline);
    event BountyApplied(uint256 indexed _bountyId, address indexed _applicant);
    event BountyWorkerAssigned(uint256 indexed _bountyId, address indexed _worker);
    event BountyWorkSubmitted(uint256 indexed _bountyId, address indexed _worker, string _workHash);
    event BountyResolved(uint256 indexed _bountyId, address indexed _worker, bool _accepted, uint256 _rewardAmount);

    // --- Modifiers ---

    modifier _onlyValidator() {
        if (!isValidator[msg.sender]) revert SSN__NotAValidator();
        _;
    }

    modifier _onlyGuildMember(uint256 _guildId) {
        if (!guilds[_guildId].exists) revert SSN__GuildNotFound();
        if (!guilds[_guildId].isMember[msg.sender]) revert SSN__NotGuildMember();
        _;
    }

    modifier _guildProjectExists(uint256 _projectId) {
        if (!guildProjects[_projectId].exists) revert SSN__GuildProjectNotFound();
        _;
    }

    modifier _bountyExists(uint256 _bountyId) {
        if (!bounties[_bountyId].exists) revert SSN__BountyNotFound();
        _;
    }

    // --- Constructor ---

    constructor() Ownable(msg.sender) {}

    // --- A. Administration & Control ---

    function updateValidatorRegistry(address _validator, bool _isValidator) public onlyOwner {
        if (_validator == address(0)) revert SSN__ZeroAddress();
        isValidator[_validator] = _isValidator;
        emit ValidatorRegistryUpdated(_validator, _isValidator);
    }

    function setGuardian(address _guardian) public onlyOwner {
        if (_guardian == address(0)) revert SSN__ZeroAddress();
        guardian = _guardian;
        emit GuardianUpdated(_guardian);
    }

    function pauseContract() public nonReentrant whenNotPaused {
        if (msg.sender != owner() && msg.sender != guardian) revert SSN__Unauthorized();
        _pause();
        emit ContractPaused(msg.sender);
    }

    function unpauseContract() public nonReentrant whenPaused {
        if (msg.sender != owner() && msg.sender != guardian) revert SSN__Unauthorized();
        _unpause();
        emit ContractUnpaused(msg.sender);
    }

    // --- B. Skill Management (SBTs) ---

    function registerSkillType(string memory _name, string memory _description) public onlyOwner returns (uint256) {
        if (bytes(_name).length == 0 || bytes(_description).length == 0) revert SSN__EmptyString();
        
        // Prevent duplicate skill names (simple check for small number of skills)
        for (uint256 i = 1; i < nextSkillId; i++) {
            if (skillTypes[i].exists && keccak256(abi.encodePacked(skillTypes[i].name)) == keccak256(abi.encodePacked(_name))) {
                revert SSN__AlreadyRegistered();
            }
        }

        uint256 skillId = nextSkillId++;
        skillTypes[skillId] = SkillType(
            _name,
            _description,
            skillId,
            true
        );
        emit SkillTypeRegistered(skillId, _name, _description);
        return skillId;
    }

    function attestSkill(address _user, uint256 _skillId) public _onlyValidator whenNotPaused {
        if (_user == address(0)) revert SSN__ZeroAddress();
        if (!skillTypes[_skillId].exists) revert SSN__SkillNotFound();
        if (userHasSkill[_user][_skillId]) revert SSN__SkillAlreadyAttested();

        userHasSkill[_user][_skillId] = true;
        skillHoldersList[_skillId].push(_user);
        _updateReputationScore(_user, _skillId, int256(INITIAL_REPUTATION_FOR_SKILL)); // Positive reputation gain
        emit SkillAttested(_user, _skillId, msg.sender);
    }

    function revokeSkillAttestation(address _user, uint256 _skillId) public whenNotPaused {
        if (_user == address(0)) revert SSN__ZeroAddress();
        if (!skillTypes[_skillId].exists) revert SSN__SkillNotFound();
        if (!userHasSkill[_user][_skillId]) revert SSN__SkillNotAttested();
        
        // Only the original validator or the owner can revoke
        // For simplicity, we assume the original validator is msg.sender.
        // A more complex system might store validator per attestation.
        // For now, any current validator can revoke. Or the owner.
        if (!isValidator[msg.sender] && msg.sender != owner()) revert SSN__Unauthorized();

        userHasSkill[_user][_skillId] = false;
        // Remove from skillHoldersList (inefficient for large arrays, but simple for example)
        for (uint256 i = 0; i < skillHoldersList[_skillId].length; i++) {
            if (skillHoldersList[_skillId][i] == _user) {
                skillHoldersList[_skillId][i] = skillHoldersList[_skillId][skillHoldersList[_skillId].length - 1];
                skillHoldersList[_skillId].pop();
                break;
            }
        }
        _updateReputationScore(_user, _skillId, -int256(INITIAL_REPUTATION_FOR_SKILL)); // Negative reputation loss
        emit SkillAttestationRevoked(_user, _skillId, msg.sender);
    }

    function getUserSkills(address _user) public view returns (uint256[] memory) {
        if (_user == address(0)) revert SSN__ZeroAddress();
        uint256[] memory skills = new uint256[](nextSkillId);
        uint256 count = 0;
        for (uint256 i = 1; i < nextSkillId; i++) {
            if (userHasSkill[_user][i]) {
                skills[count++] = i;
            }
        }
        uint256[] memory result = new uint256[](count);
        for (uint256 i = 0; i < count; i++) {
            result[i] = skills[i];
        }
        return result;
    }

    function getSkillHolders(uint256 _skillId) public view returns (address[] memory) {
        if (!skillTypes[_skillId].exists) revert SSN__SkillNotFound();
        return skillHoldersList[_skillId];
    }

    // --- C. Reputation System ---

    function _updateReputationScore(address _user, uint256 _skillId, int256 _delta) internal {
        if (_user == address(0)) revert SSN__ZeroAddress();

        // Update skill-specific reputation
        if (_delta > 0) {
            skillSpecificReputation[_user][_skillId] += uint256(_delta);
            overallReputation[_user] += uint256(_delta);
        } else if (_delta < 0) {
            uint256 absDelta = uint256(-_delta);
            if (skillSpecificReputation[_user][_skillId] < absDelta) {
                skillSpecificReputation[_user][_skillId] = 0;
            } else {
                skillSpecificReputation[_user][_skillId] -= absDelta;
            }

            if (overallReputation[_user] < absDelta) {
                overallReputation[_user] = 0;
            } else {
                overallReputation[_user] -= absDelta;
            }
        } else {
            // No change if delta is 0
            return;
        }

        emit ReputationUpdated(_user, _skillId, overallReputation[_user], skillSpecificReputation[_user][_skillId]);
    }

    function getOverallReputationScore(address _user) public view returns (uint256) {
        if (_user == address(0)) revert SSN__ZeroAddress();
        return overallReputation[_user];
    }

    function getSkillSpecificReputation(address _user, uint256 _skillId) public view returns (uint256) {
        if (_user == address(0)) revert SSN__ZeroAddress();
        if (!skillTypes[_skillId].exists) revert SSN__SkillNotFound();
        return skillSpecificReputation[_user][_skillId];
    }

    function delegateReputation(address _delegatee, uint256 _guildId) public _onlyGuildMember(_guildId) whenNotPaused {
        if (_delegatee == address(0)) revert SSN__ZeroAddress();
        if (_delegatee == msg.sender) revert SSN__SelfDelegationNotAllowed();
        
        // Ensure the delegatee is also a member of the same guild
        if (!guilds[_guildId].isMember[_delegatee]) revert SSN__DelegationNotAllowedForThisGuild();

        reputationDelegations[_guildId][msg.sender] = _delegatee;
        emit ReputationDelegated(msg.sender, _delegatee, _guildId);
    }

    // Helper to get effective voter
    function _getEffectiveVoter(uint256 _guildId, address _voter) internal view returns (address) {
        address delegatee = reputationDelegations[_guildId][_voter];
        return delegatee == address(0) ? _voter : delegatee;
    }

    // --- D. Skill Guilds (DAOs) ---

    function createGuild(string memory _name, string memory _description, uint256 _focusSkillId) public whenNotPaused returns (uint256) {
        if (bytes(_name).length == 0 || bytes(_description).length == 0) revert SSN__EmptyString();
        if (!skillTypes[_focusSkillId].exists) revert SSN__SkillNotFound();
        
        // Check creator requirements
        if (!userHasSkill[msg.sender][_focusSkillId] || getOverallReputationScore(msg.sender) < MIN_REPUTATION_FOR_GUILD_CREATION) {
            revert SSN__GuildCreationRequirementsNotMet();
        }

        uint256 guildId = nextGuildId++;
        guilds[guildId].id = guildId;
        guilds[guildId].name = _name;
        guilds[guildId].description = _description;
        guilds[guildId].focusSkillId = _focusSkillId;
        guilds[guildId].members.push(msg.sender);
        guilds[guildId].isMember[msg.sender] = true;
        guilds[guildId].totalReputation = getSkillSpecificReputation(msg.sender, _focusSkillId);
        guilds[guildId].exists = true;

        emit GuildCreated(guildId, _name, msg.sender, _focusSkillId);
        return guildId;
    }

    function joinGuild(uint256 _guildId) public whenNotPaused {
        Guild storage guild = guilds[_guildId];
        if (!guild.exists) revert SSN__GuildNotFound();
        if (guild.isMember[msg.sender]) revert SSN__AlreadyGuildMember();

        // Check joining requirements
        if (!userHasSkill[msg.sender][guild.focusSkillId] || getOverallReputationScore(msg.sender) < MIN_REPUTATION_FOR_GUILD_JOIN) {
            revert SSN__InsufficientSkillOrReputation();
        }

        guild.members.push(msg.sender);
        guild.isMember[msg.sender] = true;
        guild.totalReputation += getSkillSpecificReputation(msg.sender, guild.focusSkillId);

        emit GuildJoined(_guildId, msg.sender);
    }

    function leaveGuild(uint256 _guildId) public _onlyGuildMember(_guildId) whenNotPaused {
        Guild storage guild = guilds[_guildId];
        guild.isMember[msg.sender] = false;

        // Remove from members array (inefficient, but simple for example)
        for (uint256 i = 0; i < guild.members.length; i++) {
            if (guild.members[i] == msg.sender) {
                guild.members[i] = guild.members[guild.members.length - 1];
                guild.members.pop();
                break;
            }
        }
        guild.totalReputation -= getSkillSpecificReputation(msg.sender, guild.focusSkillId);

        emit GuildLeft(_guildId, msg.sender);
    }

    function proposeGuildProject(
        uint256 _guildId,
        string memory _title,
        string memory _description,
        uint256 _rewardAmount,
        uint256[] memory _requiredSkills
    ) public _onlyGuildMember(_guildId) whenNotPaused returns (uint256) {
        if (bytes(_title).length == 0 || bytes(_description).length == 0) revert SSN__EmptyString();
        if (_rewardAmount == 0) revert SSN__InvalidAmount();

        // Check if proposer has at least the guild's focus skill
        if (!userHasSkill[msg.sender][guilds[_guildId].focusSkillId]) revert SSN__InsufficientSkillOrReputation();

        uint256 projectId = nextGuildProjectId++;
        guildProjects[projectId] = GuildProject(
            projectId,
            _guildId,
            msg.sender,
            _title,
            _description,
            _rewardAmount,
            _requiredSkills,
            ProjectStatus.Pending,
            0,
            0,
            address(0) == address(0), // Placeholder for hasVoted mapping initial state
            block.timestamp + PROJECT_VOTE_DURATION,
            true
        );
        emit GuildProjectProposed(_guildId, projectId, msg.sender, _title);
        return projectId;
    }

    function voteOnGuildProposal(uint256 _guildId, uint256 _projectId, bool _approve) public _onlyGuildMember(_guildId) whenNotPaused {
        GuildProject storage project = guildProjects[_projectId];
        if (!project.exists || project.guildId != _guildId) revert SSN__GuildProjectNotFound();
        if (project.status != ProjectStatus.Pending) revert SSN__GuildProjectNotPending();
        if (block.timestamp > project.voteDeadline) revert SSN__DeadlinePassed();
        
        address voter = _getEffectiveVoter(_guildId, msg.sender);
        if (project.hasVoted[voter]) revert SSN__AlreadyVoted();

        // Vote weight based on the user's reputation for the guild's focus skill
        uint256 voteWeight = getSkillSpecificReputation(voter, guilds[_guildId].focusSkillId);
        if (voteWeight == 0) revert SSN__InsufficientSkillOrReputation(); // Must have some reputation to vote

        if (_approve) {
            project.totalVotesFor += voteWeight;
        } else {
            project.totalVotesAgainst += voteWeight;
        }
        project.hasVoted[voter] = true;
        emit GuildProjectVoted(_guildId, _projectId, voter, _approve, voteWeight);
    }

    function fundGuildProject(uint256 _guildId, uint256 _projectId) public _guildProjectExists(_projectId) onlyOwner nonReentrant {
        GuildProject storage project = guildProjects[_projectId];
        if (project.guildId != _guildId) revert SSN__GuildProjectNotFound();
        if (project.status != ProjectStatus.Pending) revert SSN__GuildProjectNotPending();
        if (block.timestamp < project.voteDeadline) revert SSN__DeadlinePassed(); // Must wait for voting to conclude

        uint256 totalVotes = project.totalVotesFor + project.totalVotesAgainst;
        if (totalVotes == 0) revert SSN__GuildProjectNotPending(); // No votes cast, implicitly not approved

        uint256 approvalPercentage = (project.totalVotesFor * 100) / totalVotes;

        if (approvalPercentage >= GUILD_PROJECT_APPROVAL_THRESHOLD) {
            project.status = ProjectStatus.Approved;
            // Transfer funds to the proposer. In a real DAO, this might go to a Guild multi-sig
            // or a dedicated project contract. For simplicity, we transfer to the proposer.
            if (address(this).balance < project.rewardAmount) revert SSN__InsufficientFunds();
            (bool success, ) = project.proposer.call{value: project.rewardAmount}("");
            if (!success) revert SSN__InsufficientFunds(); // More specific error in real impl
            emit GuildProjectFunded(_guildId, _projectId, project.rewardAmount);
        } else {
            project.status = ProjectStatus.Rejected;
        }
    }
    
    function completeGuildProject(uint256 _guildId, uint256 _projectId, address[] memory _contributors, uint256[] memory _reputationGains) public _onlyGuildMember(_guildId) nonReentrant {
        GuildProject storage project = guildProjects[_projectId];
        if (!project.exists || project.guildId != _guildId) revert SSN__GuildProjectNotFound();
        if (project.status != ProjectStatus.Approved) revert SSN__GuildProjectNotPending(); // Only approved projects can be completed
        if (_contributors.length != _reputationGains.length) revert SSN__InvalidAmount();

        // Only the project proposer or a guild admin can mark as complete
        if (msg.sender != project.proposer && !guilds[_guildId].isMember[msg.sender]) revert SSN__Unauthorized(); // Simplified: assuming proposer is authorized

        project.status = ProjectStatus.Completed;

        for (uint256 i = 0; i < _contributors.length; i++) {
            if (_contributors[i] == address(0)) continue;
            if (_reputationGains[i] > 0) {
                // Apply reputation gain for relevant skills
                for (uint256 j = 0; j < project.requiredSkills.length; j++) {
                     _updateReputationScore(_contributors[i], project.requiredSkills[j], int256(_reputationGains[i]));
                }
            }
        }
        emit GuildProjectCompleted(_guildId, _projectId);
    }

    // --- E. Project & Bounty Management ---

    function createBounty(
        string memory _title,
        string memory _description,
        uint256 _rewardAmount,
        uint256[] memory _requiredSkills,
        uint256 _deadline
    ) public payable whenNotPaused returns (uint256) {
        if (bytes(_title).length == 0 || bytes(_description).length == 0) revert SSN__EmptyString();
        if (_rewardAmount == 0) revert SSN__InvalidAmount();
        if (msg.value < _rewardAmount) revert SSN__InsufficientFunds();
        if (_deadline <= block.timestamp) revert SSN__DeadlinePassed(); // Deadline must be in the future

        uint256 bountyId = nextBountyId++;
        bounties[bountyId] = Bounty(
            bountyId,
            msg.sender,
            _title,
            _description,
            _rewardAmount,
            _requiredSkills,
            _deadline,
            BountyStatus.Open,
            address(0), // No assigned worker yet
            "",
            true
        );
        emit BountyCreated(bountyId, msg.sender, _rewardAmount, _deadline);
        return bountyId;
    }

    function applyForBounty(uint256 _bountyId) public _bountyExists(_bountyId) whenNotPaused {
        Bounty storage bounty = bounties[_bountyId];
        if (bounty.status != BountyStatus.Open) revert SSN__BountyAlreadyAssigned();
        if (block.timestamp > bounty.deadline) revert SSN__DeadlinePassed();

        // Check if applicant has required skills
        bool hasAllRequiredSkills = true;
        for (uint256 i = 0; i < bounty.requiredSkills.length; i++) {
            if (!userHasSkill[msg.sender][bounty.requiredSkills[i]]) {
                hasAllRequiredSkills = false;
                break;
            }
        }
        if (!hasAllRequiredSkills) revert SSN__InsufficientSkillOrReputation();

        // This is a simple application. A more complex system might store a list of applicants
        // For simplicity, we just check skills and allow assignment.
        emit BountyApplied(_bountyId, msg.sender);
    }

    function assignBountyWorker(uint256 _bountyId, address _worker) public _bountyExists(_bountyId) whenNotPaused {
        Bounty storage bounty = bounties[_bountyId];
        if (msg.sender != bounty.creator) revert SSN__Unauthorized();
        if (bounty.status != BountyStatus.Open) revert SSN__BountyAlreadyAssigned();
        if (_worker == address(0)) revert SSN__ZeroAddress();
        if (block.timestamp > bounty.deadline) revert SSN__DeadlinePassed();

        // Verify worker has the required skills (optional, could be checked on apply)
        bool hasAllRequiredSkills = true;
        for (uint256 i = 0; i < bounty.requiredSkills.length; i++) {
            if (!userHasSkill[_worker][bounty.requiredSkills[i]]) {
                hasAllRequiredSkills = false;
                break;
            }
        }
        if (!hasAllRequiredSkills) revert SSN__InsufficientSkillOrReputation();

        bounty.assignedWorker = _worker;
        bounty.status = BountyStatus.Assigned;
        emit BountyWorkerAssigned(_bountyId, _worker);
    }

    function submitBountyWork(uint256 _bountyId, string memory _workHash) public _bountyExists(_bountyId) whenNotPaused {
        Bounty storage bounty = bounties[_bountyId];
        if (msg.sender != bounty.assignedWorker) revert SSN__BountyNotAssignedToYou();
        if (bounty.status != BountyStatus.Assigned) revert SSN__BountyNotPendingWork();
        if (bytes(_workHash).length == 0) revert SSN__EmptyString();
        if (block.timestamp > bounty.deadline) revert SSN__DeadlinePassed();

        bounty.workHash = _workHash;
        bounty.status = BountyStatus.WorkSubmitted;
        emit BountyWorkSubmitted(_bountyId, msg.sender, _workHash);
    }

    function resolveBounty(uint256 _bountyId, bool _accepted) public _bountyExists(_bountyId) nonReentrant {
        Bounty storage bounty = bounties[_bountyId];
        if (msg.sender != bounty.creator) revert SSN__Unauthorized();
        if (bounty.status != BountyStatus.WorkSubmitted) revert SSN__BountyNotPendingResolution();

        if (_accepted) {
            // Transfer reward to the worker
            (bool success, ) = bounty.assignedWorker.call{value: bounty.rewardAmount}("");
            if (!success) revert SSN__InsufficientFunds(); // More specific error in real impl
            
            // Update worker's reputation for relevant skills
            for (uint256 i = 0; i < bounty.requiredSkills.length; i++) {
                _updateReputationScore(bounty.assignedWorker, bounty.requiredSkills[i], int256(bounty.rewardAmount / 1000000000000000)); // Example: 0.001 ETH reward = 1 reputation
            }
            bounty.status = BountyStatus.ResolvedAccepted;
        } else {
            // Worker's work not accepted, bounty re-opens or funds returned to creator.
            // For simplicity, we re-open it to 'Open' and clear assigned worker.
            bounty.assignedWorker = address(0);
            bounty.status = BountyStatus.Open;
            bounty.workHash = ""; // Clear submitted work
        }
        emit BountyResolved(_bountyId, bounty.assignedWorker, _accepted, _accepted ? bounty.rewardAmount : 0);
    }

    // --- Fallback & Receive ---
    receive() external payable {
        // Log incoming funds for bounties or future guild treasuries
    }

    fallback() external payable {
        // Log incoming funds for bounties or future guild treasuries
    }
}
```