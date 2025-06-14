Okay, let's design a smart contract that manages a dynamic, on-chain "Persona" system. This system will allow users to register a profile, acquire and level up skills through experience points (XP), earn reputation, collect achievement badges, and participate in projects that require specific skills and award rewards.

This concept combines elements of identity, reputation, gamification (XP, leveling), and a decentralized work/collaboration registry, aiming for a more advanced and interconnected on-chain profile than simple tokens or static NFTs. It avoids duplicating standard ERC-20/721, basic voting, or simple staking contracts.

**Advanced Concepts Used:**

1.  **Dynamic State per User:** Persona profiles with changing skill levels, XP, and reputation.
2.  **Complex Data Structures:** Nested mappings, structs, and arrays to manage profiles, skills, badges, and projects.
3.  **Role-Based Access Control (Simple):** Owner and a designated "Curator" role for specific actions (creating skills/badges, managing projects).
4.  **Conditional Logic:** Checking skill prerequisites for project application.
5.  **Internal State Transitions:** Functions that trigger updates to reputation, skill XP, and levels internally based on project completion.
6.  **Soulbound (Conceptually):** User profiles and their associated skills/reputation are tied to the address and not directly transferable like standard tokens (though the contract itself is transferable).
7.  **Enumerable State (Partial):** Keeping track of registered skills, badges, and projects via arrays for listing (with gas cost considerations).

---

## **Outline & Function Summary**

**Contract Name:** PersonaRegistry

**Purpose:** To provide a decentralized, on-chain system for managing user personas with dynamic skills, reputation, badges, and participation in structured projects.

**Core Components:**

1.  **Persona Profiles:** User-specific data including reputation, skills, badges, and projects.
2.  **Skills:** Definitions of skills with metadata. Users can acquire and level up skills.
3.  **Badges:** Definitions of achievement badges with metadata. Users can be awarded badges.
4.  **Projects:** Defined tasks/opportunities requiring specific skills and offering rewards (reputation, skill XP, badges).
5.  **Roles:** Owner (full control) and Curator (can manage skill/badge types, create/manage projects).

**State Variables:**

*   `owner`: The contract owner.
*   `curator`: Address designated as the curator.
*   `nextProjectId`: Counter for new projects.
*   `personas`: Mapping from address to `PersonaProfile` struct.
*   `registeredSkillHashes`: Array of defined skill hashes.
*   `skillMetadataURIs`: Mapping from skill hash to metadata URI.
*   `registeredBadgeHashes`: Array of defined badge hashes.
*   `badgeMetadataURIs`: Mapping from badge hash to metadata URI.
*   `projects`: Mapping from project ID to `ProjectData` struct.
*   `projectIds`: Array of all project IDs.

**Structs:**

*   `PersonaProfile`: User's data (exists, creation time, reputation, skills, badges, associated projects).
*   `SkillData`: User's skill data (level, xp, acquisition time).
*   `BadgeAward`: User's badge award data (award time).
*   `ProjectData`: Project details (creator, title, description, requirements, participants, status, rewards, creation time).
*   `ProjectRewards`: Rewards structure within ProjectData.

**Enum:**

*   `ProjectStatus`: Open, InProgress, Completed, Cancelled.

**Events:**

*   `PersonaRegistered`
*   `ProfileUpdated`
*   `SkillCreated`
*   `SkillAddedToPersona`
*   `SkillXPUpdated`
*   `SkillLeveledUp`
*   `ReputationUpdated`
*   `BadgeCreated`
*   `BadgeAwarded`
*   `ProjectCreated`
*   `ProjectApplied`
*   `ParticipantAccepted`
*   `ProjectStatusUpdated` (for Completed/Cancelled)
*   `CuratorSet`
*   `CuratorRemoved`
*   `OwnershipTransferred`

**Functions (Total: 35)**

**Persona Management (4)**
1.  `registerPersona()`: Creates a new persona profile for the caller.
2.  `getPersonaProfile(address _user)`: Retrieves a user's profile data.
3.  `updatePersonaProfile(bytes32 _newIdentityHash)`: Allows updating a linked identity hash (placeholder).
4.  `checkPersonaExists(address _user)`: Checks if an address has a registered persona.

**Skill Type Management (Curator/Owner) (3)**
5.  `createSkill(bytes32 _skillHash, string memory _metadataURI)`: Defines a new skill type.
6.  `getSkillMetadata(bytes32 _skillHash)`: Gets metadata URI for a skill type.
7.  `getAllSkillHashes()`: Gets list of all registered skill hashes.

**Persona Skill Management (User/Internal) (3)**
8.  `addSkillToPersona(bytes32 _skillHash)`: Allows a user to add an existing skill type to their profile (starts at level 1).
9.  `getPersonaSkillLevel(address _user, bytes32 _skillHash)`: Gets a user's level for a specific skill.
10. `getPersonaSkillXP(address _user, bytes32 _skillHash)`: Gets a user's XP for a specific skill.

**Reputation Management (Internal/Getter) (1)**
11. `getPersonaReputation(address _user)`: Gets a user's reputation score.

**Badge Type Management (Curator/Owner) (3)**
12. `createBadge(bytes32 _badgeHash, string memory _metadataURI)`: Defines a new badge type.
13. `getBadgeMetadata(bytes32 _badgeHash)`: Gets metadata URI for a badge type.
14. `getAllBadgeHashes()`: Gets list of all registered badge hashes.

**Persona Badge Management (Curator/Internal/Getter) (3)**
15. `awardBadgeToPersona(address _user, bytes32 _badgeHash)`: Awards a badge to a user (by Curator/Owner or internal reward system).
16. `hasPersonaBadge(address _user, bytes32 _badgeHash)`: Checks if a user has been awarded a specific badge.
17. `getPersonaBadges(address _user)`: Gets the list of badge hashes awarded to a user.

**Project Management (Curator/Owner/User) (9)**
18. `createProject(string memory _title, bytes32 _descriptionHash, bytes32[] memory _requiredSkillHashes, uint256[] memory _requiredSkillLevels, uint256 _reputationReward, bytes32[] memory _skillXPRewardsHashes, uint256[] memory _skillXPRewardsAmounts, bytes32[] memory _badgeRewardsHashes)`: Creates a new project.
19. `getProjectDetails(uint256 _projectId)`: Retrieves details of a project.
20. `applyForProject(uint256 _projectId)`: Allows a user to apply for a project if they meet skill requirements.
21. `acceptProjectParticipant(uint256 _projectId, address _user)`: Accepts an applicant into a project's participant list.
22. `getProjectParticipants(uint256 _projectId)`: Gets the list of addresses participating in a project.
23. `completeProject(uint256 _projectId)`: Marks a project as completed and distributes rewards to participants.
24. `cancelProject(uint256 _projectId)`: Cancels an open or in-progress project.
25. `getProjectsByStatus(ProjectStatus _status)`: Gets a list of project IDs matching a given status.
26. `getProjectsUserParticipatedIn(address _user)`: Gets a list of project IDs a user was involved in.

**Role Management (Owner) (3)**
27. `setCuratorRole(address _newCurator)`: Sets the curator address.
28. `removeCuratorRole()`: Removes the current curator.
29. `isCurator(address _user)`: Checks if an address is the current curator.

**Owner Management (2)**
30. `owner()`: Gets the current contract owner.
31. `transferOwnership(address _newOwner)`: Transfers contract ownership.

**Internal Helper Functions (4)**
32. `_distributeProjectRewards(uint256 _projectId)`: Handles the logic of distributing rewards upon project completion.
33. `_calculateLevelUp(uint256 _currentLevel, uint256 _currentXP, uint256 _xpGained)`: Determines if a skill levels up and calculates the new level and remaining XP. (Simple linear model used).
34. `_updatePersonaReputation(address _user, uint256 _reputationAmount)`: Internal function to add reputation.
35. `_updatePersonaSkillXP(address _user, bytes32 _skillHash, uint256 _xpAmount)`: Internal function to add XP to a skill and potentially trigger level up.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title PersonaRegistry
 * @dev A smart contract for managing dynamic on-chain user personas with skills, reputation, badges,
 * and project participation.
 *
 * Outline & Function Summary:
 * - Manages user profiles (Personas) linked to addresses.
 * - Defines Skill types and allows users to acquire and level them up via XP.
 * - Defines Badge types and allows awarding them to users.
 * - Allows creation of Projects requiring specific skills and offering rewards (Reputation, Skill XP, Badges).
 * - Users can apply to projects based on their skills.
 * - Project creators/Curator can accept participants and complete projects to distribute rewards.
 * - Implements Owner and Curator roles for governance over skill/badge creation and project lifecycle.
 *
 * State Variables:
 * - owner: The contract owner.
 * - curator: Address designated as the curator.
 * - nextProjectId: Counter for new projects.
 * - personas: Mapping from address to PersonaProfile struct.
 * - registeredSkillHashes: Array of defined skill hashes.
 * - skillMetadataURIs: Mapping from skill hash to metadata URI.
 * - registeredBadgeHashes: Array of defined badge hashes.
 * - badgeMetadataURIs: Mapping from badge hash to metadata URI.
 * - projects: Mapping from project ID to ProjectData struct.
 * - projectIds: Array of all project IDs.
 *
 * Structs:
 * - PersonaProfile: User's data (exists, creation time, reputation, skills, badges, associated projects).
 * - SkillData: User's skill data (level, xp, acquisition time).
 * - BadgeAward: User's badge award data (award time).
 * - ProjectData: Project details (creator, title, description, requirements, participants, status, rewards, creation time).
 * - ProjectRewards: Rewards structure within ProjectData.
 *
 * Enum:
 * - ProjectStatus: Open, InProgress, Completed, Cancelled.
 *
 * Events:
 * - PersonaRegistered
 * - ProfileUpdated
 * - SkillCreated
 * - SkillAddedToPersona
 * - SkillXPUpdated
 * - SkillLeveledUp
 * - ReputationUpdated
 * - BadgeCreated
 * - BadgeAwarded
 * - ProjectCreated
 * - ProjectApplied
 * - ParticipantAccepted
 * - ProjectStatusUpdated (for Completed/Cancelled)
 * - CuratorSet
 * - CuratorRemoved
 * - OwnershipTransferred
 *
 * Functions (Total: 35):
 * - Persona Management (4)
 * - Skill Type Management (Curator/Owner) (3)
 * - Persona Skill Management (User/Internal) (3)
 * - Reputation Management (Internal/Getter) (1)
 * - Badge Type Management (Curator/Owner) (3)
 * - Persona Badge Management (Curator/Internal/Getter) (3)
 * - Project Management (Curator/Owner/User) (9)
 * - Role Management (Owner) (3)
 * - Owner Management (2)
 * - Internal Helper Functions (4)
 */

contract PersonaRegistry {

    // --- Errors ---
    error PersonaAlreadyRegistered();
    error PersonaNotRegistered();
    error SkillAlreadyExists();
    error SkillNotRegistered();
    error BadgeAlreadyExists();
    error BadgeNotRegistered();
    error NotOwnerOrCurator();
    error OnlyOwner();
    error OnlyCurator();
    error OnlyProjectCreatorOrCurator();
    error ProjectNotExists();
    error ProjectNotInStatus(ProjectStatus expectedStatus);
    error SkillRequirementsNotMet();
    error AlreadyAppliedForProject();
    error NotAProjectParticipant();
    error ParticipantAlreadyAccepted();
    error BadgeAlreadyAwarded();
    error SkillAlreadyPossessed();
    error CannotUpdateCompletedOrCancelledProject();

    // --- Enums ---
    enum ProjectStatus { Open, InProgress, Completed, Cancelled }

    // --- Structs ---
    struct SkillData {
        uint256 level; // Current skill level
        uint256 xp;    // Experience points towards the next level
        uint256 acquiredTimestamp; // When the skill was first added
    }

    struct BadgeAward {
        uint256 awardedTimestamp; // When the badge was awarded
    }

    struct PersonaProfile {
        bool exists; // Flag to check if profile is registered
        uint256 creationTimestamp; // Timestamp of profile creation
        uint256 reputationScore; // Accumulative reputation score
        mapping(bytes32 => SkillData) skills; // Acquired skills and their data
        mapping(bytes32 => BadgeAward) badges; // Awarded badges
        uint256[] associatedProjectIds; // IDs of projects the persona participated in
    }

    struct ProjectRewards {
        uint256 reputation; // Reputation points awarded on completion
        mapping(bytes32 => uint256) skillXP; // Skill hash => XP awarded
        mapping(bytes32 => bool) badges; // Badge hash => true if awarded
    }

    struct ProjectData {
        bool exists; // Flag to check if project exists
        address creator; // Address of the project creator
        string title; // Project title
        bytes32 descriptionHash; // Hash referencing external description (e.g., IPFS)
        mapping(bytes32 => uint256) requiredSkills; // Skill hash => minimum required level
        mapping(address => bool) participants; // Address => true if accepted participant
        address[] participantsList; // List of accepted participant addresses
        ProjectStatus status; // Current status of the project
        ProjectRewards rewards; // Rewards for completing the project
        uint256 creationTimestamp; // Timestamp of project creation
        mapping(address => bool) applicants; // Address => true if applied (simple tracking, no detailed application data)
    }

    // --- State Variables ---
    address private _owner;
    address private _curator;

    uint256 private _nextProjectId;
    mapping(uint256 => ProjectData) private _projects;
    uint256[] public projectIds; // List of all project IDs

    mapping(address => PersonaProfile) private _personas;

    bytes32[] public registeredSkillHashes;
    mapping(bytes32 => string) private _skillMetadataURIs;
    mapping(bytes32 => bool) private _isSkillRegistered; // Helper for quick check

    bytes32[] public registeredBadgeHashes;
    mapping(bytes32 => string) private _badgeMetadataURIs;
    mapping(bytes32 => bool) private _isBadgeRegistered; // Helper for quick check


    // --- Events ---
    event PersonaRegistered(address indexed user, uint256 timestamp);
    event ProfileUpdated(address indexed user, bytes32 newIdentityHash);
    event SkillCreated(bytes32 indexed skillHash, string metadataURI);
    event SkillAddedToPersona(address indexed user, bytes32 indexed skillHash, uint256 level);
    event SkillXPUpdated(address indexed user, bytes32 indexed skillHash, uint256 newXP, uint256 xpGained);
    event SkillLeveledUp(address indexed user, bytes32 indexed skillHash, uint256 newLevel, uint256 remainingXP);
    event ReputationUpdated(address indexed user, uint256 newReputation, uint256 reputationGained);
    event BadgeCreated(bytes32 indexed badgeHash, string metadataURI);
    event BadgeAwarded(address indexed user, bytes32 indexed badgeHash, uint256 timestamp);
    event ProjectCreated(uint256 indexed projectId, address indexed creator, string title, ProjectStatus status, uint256 timestamp);
    event ProjectApplied(uint256 indexed projectId, address indexed user);
    event ParticipantAccepted(uint256 indexed projectId, address indexed user);
    event ProjectStatusUpdated(uint256 indexed projectId, ProjectStatus newStatus);
    event CuratorSet(address indexed oldCurator, address indexed newCurator);
    event CuratorRemoved(address indexed oldCurator);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    // --- Modifiers ---
    modifier onlyOwner() {
        if (msg.sender != _owner) revert OnlyOwner();
        _;
    }

    modifier onlyCurator() {
        if (msg.sender != _curator) revert OnlyCurator();
        _;
    }

    modifier onlyOwnerOrCurator() {
        if (msg.sender != _owner && msg.sender != _curator) revert NotOwnerOrCurator();
        _;
    }

    modifier personaExists(address _user) {
        if (!_personas[_user].exists) revert PersonaNotRegistered();
        _;
    }

    modifier projectExists(uint256 _projectId) {
        if (!_projects[_projectId].exists) revert ProjectNotExists();
        _;
    }

    modifier projectInStatus(uint256 _projectId, ProjectStatus _status) {
        if (_projects[_projectId].status != _status) revert ProjectNotInStatus(_status);
        _;
    }

    modifier skillExists(bytes32 _skillHash) {
        if (!_isSkillRegistered[_skillHash]) revert SkillNotRegistered();
        _;
    }

    modifier badgeExists(bytes32 _badgeHash) {
        if (!_isBadgeRegistered[_badgeHash]) revert BadgeNotRegistered();
        _;
    }

    // --- Constructor ---
    constructor() {
        _owner = msg.sender;
    }

    // --- Owner Management (2) ---
    function owner() public view returns (address) {
        return _owner;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        if (newOwner == address(0)) revert OnlyOwner(); // Prevent transferring to zero address
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }

    // --- Role Management (Owner) (3) ---
    function setCuratorRole(address newCurator) public onlyOwner {
        address oldCurator = _curator;
        _curator = newCurator;
        emit CuratorSet(oldCurator, newCurator);
    }

    function removeCuratorRole() public onlyOwner {
        address oldCurator = _curator;
        _curator = address(0);
        emit CuratorRemoved(oldCurator);
    }

    function isCurator(address user) public view returns (bool) {
        return user == _curator;
    }

    // --- Persona Management (4) ---
    function registerPersona() public {
        if (_personas[msg.sender].exists) revert PersonaAlreadyRegistered();

        _personas[msg.sender] = PersonaProfile({
            exists: true,
            creationTimestamp: block.timestamp,
            reputationScore: 0,
            skills: {}, // Initialize empty mappings
            badges: {},
            associatedProjectIds: new uint256[](0) // Initialize empty array
        });

        emit PersonaRegistered(msg.sender, block.timestamp);
    }

    function getPersonaProfile(address _user) public view personaExists(_user) returns (
        bool exists,
        uint256 creationTimestamp,
        uint256 reputationScore,
        uint256[] memory associatedProjectIds
    ) {
        PersonaProfile storage persona = _personas[_user];
        return (
            persona.exists,
            persona.creationTimestamp,
            persona.reputationScore,
            persona.associatedProjectIds
        );
    }

    // Placeholder for potentially linking off-chain identity proofs
    function updatePersonaProfile(bytes32 _newIdentityHash) public personaExists(msg.sender) {
        // Logic to potentially verify _newIdentityHash off-chain before allowing update
        // For this example, we just emit the event.
        // In a real scenario, this would likely involve a trusted oracle or more complex verification.
        // PersonaProfile storage persona = _personas[msg.sender];
        // persona.identityHash = _newIdentityHash; // Assuming identityHash field exists

        emit ProfileUpdated(msg.sender, _newIdentityHash);
    }

    function checkPersonaExists(address _user) public view returns (bool) {
        return _personas[_user].exists;
    }

    // --- Skill Type Management (Curator/Owner) (3) ---
    function createSkill(bytes32 _skillHash, string memory _metadataURI) public onlyOwnerOrCurator {
        if (_isSkillRegistered[_skillHash]) revert SkillAlreadyExists();

        _skillMetadataURIs[_skillHash] = _metadataURI;
        _isSkillRegistered[_skillHash] = true;
        registeredSkillHashes.push(_skillHash);

        emit SkillCreated(_skillHash, _metadataURI);
    }

    function getSkillMetadata(bytes32 _skillHash) public view skillExists(_skillHash) returns (string memory) {
        return _skillMetadataURis[_skillHash];
    }

    function getAllSkillHashes() public view returns (bytes32[] memory) {
        return registeredSkillHashes;
    }

    // --- Persona Skill Management (User/Internal) (3) ---
    function addSkillToPersona(bytes32 _skillHash) public personaExists(msg.sender) skillExists(_skillHash) {
        PersonaProfile storage persona = _personas[msg.sender];
        if (persona.skills[_skillHash].level > 0) revert SkillAlreadyPossessed(); // Check if already added

        // Start at Level 1 with 0 XP
        persona.skills[_skillHash] = SkillData({
            level: 1,
            xp: 0,
            acquiredTimestamp: block.timestamp
        });

        emit SkillAddedToPersona(msg.sender, _skillHash, 1);
    }

    function getPersonaSkillLevel(address _user, bytes32 _skillHash) public view personaExists(_user) skillExists(_skillHash) returns (uint256) {
         // Returns 0 if skill not explicitly added, which is okay.
         return _personas[_user].skills[_skillHash].level;
    }

    function getPersonaSkillXP(address _user, bytes32 _skillHash) public view personaExists(_user) skillExists(_skillHash) returns (uint256) {
        // Returns 0 if skill not explicitly added, which is okay.
        return _personas[_user].skills[_skillHash].xp;
    }

    // --- Reputation Management (Internal/Getter) (1) ---
    function getPersonaReputation(address _user) public view personaExists(_user) returns (uint256) {
        return _personas[_user].reputationScore;
    }

    // --- Badge Type Management (Curator/Owner) (3) ---
    function createBadge(bytes32 _badgeHash, string memory _metadataURI) public onlyOwnerOrCurator {
         if (_isBadgeRegistered[_badgeHash]) revert BadgeAlreadyExists();

        _badgeMetadataURIs[_badgeHash] = _metadataURI;
        _isBadgeRegistered[_badgeHash] = true;
        registeredBadgeHashes.push(_badgeHash);

        emit BadgeCreated(_badgeHash, _metadataURI);
    }

    function getBadgeMetadata(bytes32 _badgeHash) public view badgeExists(_badgeHash) returns (string memory) {
        return _badgeMetadataURIs[_badgeHash];
    }

    function getAllBadgeHashes() public view returns (bytes32[] memory) {
        return registeredBadgeHashes;
    }

    // --- Persona Badge Management (Curator/Internal/Getter) (3) ---
    function awardBadgeToPersona(address _user, bytes32 _badgeHash) public onlyOwnerOrCurator personaExists(_user) badgeExists(_badgeHash) {
        PersonaProfile storage persona = _personas[_user];
        if (persona.badges[_badgeHash].awardedTimestamp > 0) revert BadgeAlreadyAwarded();

        persona.badges[_badgeHash] = BadgeAward({
            awardedTimestamp: block.timestamp
        });

        emit BadgeAwarded(_user, _badgeHash, block.timestamp);
    }

    function hasPersonaBadge(address _user, bytes32 _badgeHash) public view personaExists(_user) badgeExists(_badgeHash) returns (bool) {
        // Checks if the awarded timestamp is greater than 0
        return _personas[_user].badges[_badgeHash].awardedTimestamp > 0;
    }

     function getPersonaBadges(address _user) public view personaExists(_user) returns (bytes32[] memory) {
        PersonaProfile storage persona = _personas[_user];
        bytes32[] memory userBadges = new bytes32[](0); // Dynamic array

        // Iterate through all registered badge types and check if the user has them
        for (uint i = 0; i < registeredBadgeHashes.length; i++) {
            bytes32 badgeHash = registeredBadgeHashes[i];
            if (persona.badges[badgeHash].awardedTimestamp > 0) {
                 // Add to the dynamic array (inefficient for very large numbers, but acceptable for this demo)
                bytes32[] memory tmp = new bytes32[](userBadges.length + 1);
                for (uint j = 0; j < userBadges.length; j++) {
                    tmp[j] = userBadges[j];
                }
                tmp[userBadges.length] = badgeHash;
                userBadges = tmp;
            }
        }
        return userBadges;
    }


    // --- Project Management (Curator/Owner/User) (9) ---
    function createProject(
        string memory _title,
        bytes32 _descriptionHash,
        bytes32[] memory _requiredSkillHashes,
        uint256[] memory _requiredSkillLevels,
        uint256 _reputationReward,
        bytes32[] memory _skillXPRewardsHashes,
        uint256[] memory _skillXPRewardsAmounts,
        bytes32[] memory _badgeRewardsHashes
    ) public onlyOwnerOrCurator returns (uint256 projectId) {
        if (_requiredSkillHashes.length != _requiredSkillLevels.length) revert ProjectNotExists(); // Simple input validation
        if (_skillXPRewardsHashes.length != _skillXPRewardsAmounts.length) revert ProjectNotExists(); // Simple input validation

        // Basic validation for existence of rewards/requirements
        for(uint i=0; i < _requiredSkillHashes.length; i++) skillExists(_requiredSkillHashes[i]);
        for(uint i=0; i < _skillXPRewardsHashes.length; i++) skillExists(_skillXPRewardsHashes[i]);
        for(uint i=0; i < _badgeRewardsHashes.length; i++) badgeExists(_badgeRewardsHashes[i]);


        projectId = _nextProjectId++;
        ProjectData storage newProject = _projects[projectId];

        newProject.exists = true;
        newProject.creator = msg.sender;
        newProject.title = _title;
        newProject.descriptionHash = _descriptionHash;
        newProject.status = ProjectStatus.Open;
        newProject.creationTimestamp = block.timestamp;
        newProject.participantsList = new address[](0); // Initialize empty participant list

        // Set required skills
        for (uint i = 0; i < _requiredSkillHashes.length; i++) {
            newProject.requiredSkills[_requiredSkillHashes[i]] = _requiredSkillLevels[i];
        }

        // Set rewards
        newProject.rewards.reputation = _reputationReward;
        for (uint i = 0; i < _skillXPRewardsHashes.length; i++) {
             newProject.rewards.skillXP[_skillXPRewardsHashes[i]] = _skillXPRewardsAmounts[i];
        }
        for (uint i = 0; i < _badgeRewardsHashes.length; i++) {
            newProject.rewards.badges[_badgeRewardsHashes[i]] = true;
        }

        projectIds.push(projectId); // Add to list of all project IDs

        emit ProjectCreated(projectId, msg.sender, _title, newProject.status, block.timestamp);
    }

    function getProjectDetails(uint256 _projectId) public view projectExists(_projectId) returns (
        uint256 projectId,
        address creator,
        string memory title,
        bytes32 descriptionHash,
        ProjectStatus status,
        uint256 creationTimestamp
    ) {
         ProjectData storage project = _projects[_projectId];
         return (
             _projectId,
             project.creator,
             project.title,
             project.descriptionHash,
             project.status,
             project.creationTimestamp
         );
    }

     // Helper getter for project required skills
    function getProjectRequiredSkills(uint256 _projectId) public view projectExists(_projectId) returns (bytes32[] memory, uint256[] memory) {
        ProjectData storage project = _projects[_projectId];
        bytes32[] memory hashes = new bytes32[](project.requiredSkills.length); // Note: requires 0.8.20 or higher for mapping.length
        uint256[] memory levels = new uint256[](project.requiredSkills.length);
        uint i = 0;
        // Iterate through mappings is not directly possible, need to store required skill hashes in project struct if needed frequently.
        // For this demo, we assume the creator's input arrays are canonical for the getter, or we'd need to add a skills list to ProjectData struct.
        // Let's assume the createProject input arrays are the *only* way to know the original list of requirements for the getter.
        // A more robust design would store the required skills explicitly as arrays in the struct.
        // Adding a simple helper that *tries* to list assuming the original creation order/data isn't stored this way.
        // *Correction*: A better approach for a demo without changing structs is to list *all* skill types and check if project.requiredSkills has an entry > 0.

        bytes32[] memory allSkillHashes = registeredSkillHashes;
        bytes32[] memory reqHashes = new bytes32[](0);
        uint256[] memory reqLevels = new uint256[](0);

        for(uint j = 0; j < allSkillHashes.length; j++) {
            bytes32 skillHash = allSkillHashes[j];
            uint256 requiredLevel = project.requiredSkills[skillHash];
            if (requiredLevel > 0) {
                 bytes32[] memory tmpHashes = new bytes32[](reqHashes.length + 1);
                 uint256[] memory tmpLevels = new uint256[](reqLevels.length + 1);
                 for(uint k = 0; k < reqHashes.length; k++) {
                     tmpHashes[k] = reqHashes[k];
                     tmpLevels[k] = reqLevels[k];
                 }
                 tmpHashes[reqHashes.length] = skillHash;
                 tmpLevels[reqLevels.length] = requiredLevel;
                 reqHashes = tmpHashes;
                 reqLevels = tmpLevels;
            }
        }
        return (reqHashes, reqLevels);
    }


    function applyForProject(uint256 _projectId) public personaExists(msg.sender) projectExists(_projectId) projectInStatus(_projectId, ProjectStatus.Open) {
        ProjectData storage project = _projects[_projectId];
        PersonaProfile storage applicantPersona = _personas[msg.sender];

        if (project.applicants[msg.sender]) revert AlreadyAppliedForProject();

        // Check if applicant meets skill requirements
        bytes32[] memory allSkillHashes = registeredSkillHashes;
        for(uint i = 0; i < allSkillHashes.length; i++) {
             bytes32 skillHash = allSkillHashes[i];
             uint256 requiredLevel = project.requiredSkills[skillHash];
             if (requiredLevel > 0) {
                 // Applicant must have the skill and meet the minimum level
                 if (applicantPersona.skills[skillHash].level < requiredLevel) {
                     revert SkillRequirementsNotMet();
                 }
             }
        }

        project.applicants[msg.sender] = true; // Mark as applied

        emit ProjectApplied(_projectId, msg.sender);
    }

    function acceptProjectParticipant(uint256 _projectId, address _user) public projectExists(_projectId) projectInStatus(_projectId, ProjectStatus.Open) {
        ProjectData storage project = _projects[_projectId];
        PersonaProfile storage userPersona = _personas[_user];

        // Only creator or curator can accept
        if (msg.sender != project.creator && msg.sender != _curator) revert OnlyProjectCreatorOrCurator();
        // User must have applied
        if (!project.applicants[_user]) revert NotAProjectParticipant(); // Reusing error, maybe make specific AppliedButNotApplied?
        // User must have a registered persona
        if (!userPersona.exists) revert PersonaNotRegistered(); // Should be guaranteed by apply, but good check.
        // User must not already be accepted
        if (project.participants[_user]) revert ParticipantAlreadyAccepted();

        project.participants[_user] = true;
        project.participantsList.push(_user); // Add to the list

        // Move project to InProgress if this is the first participant? Or require manual status update?
        // Let's allow creator/curator to move to InProgress explicitly for flexibility.

        emit ParticipantAccepted(_projectId, _user);
    }

     function getProjectParticipants(uint256 _projectId) public view projectExists(_projectId) returns (address[] memory) {
        return _projects[_projectId].participantsList;
    }

    function completeProject(uint256 _projectId) public projectExists(_projectId) projectInStatus(_projectId, ProjectStatus.Open) {
        // Allowing completion directly from Open. If `InProgress` state transition is desired,
        // add a `startProject` function and require `projectInStatus(_projectId, ProjectStatus.InProgress)` here.
        // For this demo, completing from Open means the creator/curator deems it done.
        ProjectData storage project = _projects[_projectId];

        // Only creator or curator can complete
        if (msg.sender != project.creator && msg.sender != _curator) revert OnlyProjectCreatorOrCurator();

        project.status = ProjectStatus.Completed;
        _distributeProjectRewards(_projectId); // Distribute rewards to accepted participants

        emit ProjectStatusUpdated(_projectId, ProjectStatus.Completed);
    }

     function cancelProject(uint256 _projectId) public projectExists(_projectId) {
         ProjectData storage project = _projects[_projectId];
         if (project.status == ProjectStatus.Completed || project.status == ProjectStatus.Cancelled) {
             revert CannotUpdateCompletedOrCancelledProject();
         }

        // Only creator or curator can cancel
        if (msg.sender != project.creator && msg.sender != _curator) revert OnlyProjectCreatorOrCurator();

        project.status = ProjectStatus.Cancelled;

        emit ProjectStatusUpdated(_projectId, ProjectStatus.Cancelled);
     }

    function getProjectsByStatus(ProjectStatus _status) public view returns (uint256[] memory) {
        uint256[] memory filteredIds = new uint256[](0); // Dynamic array

        for (uint i = 0; i < projectIds.length; i++) {
            uint256 projectId = projectIds[i];
            if (_projects[projectId].exists && _projects[projectId].status == _status) {
                // Add to dynamic array
                 uint256[] memory tmp = new uint256[](filteredIds.length + 1);
                 for(uint j = 0; j < filteredIds.length; j++) {
                     tmp[j] = filteredIds[j];
                 }
                 tmp[filteredIds.length] = projectId;
                 filteredIds = tmp;
            }
        }
        return filteredIds;
    }

     function getProjectsUserParticipatedIn(address _user) public view personaExists(_user) returns (uint256[] memory) {
         // Directly return the stored array of associated project IDs
         return _personas[_user].associatedProjectIds;
     }


    // --- Internal Helper Functions (4) ---

    // Distributes rewards to all *accepted* participants of a completed project
    function _distributeProjectRewards(uint256 _projectId) internal projectExists(_projectId) projectInStatus(_projectId, ProjectStatus.Completed) {
        ProjectData storage project = _projects[_projectId];

        // Iterate through accepted participants
        for (uint i = 0; i < project.participantsList.length; i++) {
            address participant = project.participantsList[i];
            PersonaProfile storage participantPersona = _personas[participant];

            // Add project to the participant's associated list
            participantPersona.associatedProjectIds.push(_projectId);

            // Distribute Reputation
            if (project.rewards.reputation > 0) {
                 _updatePersonaReputation(participant, project.rewards.reputation);
            }

            // Distribute Skill XP
            bytes32[] memory allSkillHashes = registeredSkillHashes; // Iterate through all skill types
            for(uint j = 0; j < allSkillHashes.length; j++) {
                 bytes32 skillHash = allSkillHashes[j];
                 uint256 xpAmount = project.rewards.skillXP[skillHash];
                 if (xpAmount > 0) {
                      // Ensure participant has the skill added to their profile before adding XP
                      // (They must have had it at level >= req to apply, but they might not have explicitly added it if req=0)
                      // Let's implicitly add skills with XP rewards if the user doesn't have them
                      if (participantPersona.skills[skillHash].level == 0) {
                          participantPersona.skills[skillHash] = SkillData({
                              level: 1, // Start at level 1 implicitly
                              xp: 0,
                              acquiredTimestamp: block.timestamp // Use reward distribution time
                          });
                           emit SkillAddedToPersona(participant, skillHash, 1);
                      }
                      _updatePersonaSkillXP(participant, skillHash, xpAmount);
                 }
            }

            // Award Badges
             bytes32[] memory allBadgeHashes = registeredBadgeHashes; // Iterate through all badge types
             for(uint j = 0; j < allBadgeHashes.length; j++) {
                 bytes32 badgeHash = allBadgeHashes[j];
                 bool awardBadge = project.rewards.badges[badgeHash];
                 if (awardBadge) {
                     // Award badge if they don't already have it
                     if (participantPersona.badges[badgeHash].awardedTimestamp == 0) {
                         participantPersona.badges[badgeHash] = BadgeAward({
                             awardedTimestamp: block.timestamp // Use reward distribution time
                         });
                         emit BadgeAwarded(participant, badgeHash, block.timestamp);
                     }
                 }
             }
        }
    }

    // Internal helper to calculate new level and remaining XP after gaining XP
    function _calculateLevelUp(uint256 _currentLevel, uint256 _currentXP, uint256 _xpGained) internal pure returns (uint256 newLevel, uint256 remainingXP) {
        uint256 totalXP = _currentXP + _xpGained;
        uint256 level = _currentLevel;
        uint256 xpNeededForNextLevel;

        // Simple linear XP required model: Level N needs N * 100 XP
        // Level 1 needs 100 XP to reach 2
        // Level 2 needs 200 XP to reach 3
        // Total XP needed for Level N is SUM(i=1 to N-1, i*100)
        // Total XP needed to reach Level N+1 is total XP needed to reach N + N*100

        // Start checking from the current level
        xpNeededForNextLevel = level * 100;

        while (totalXP >= xpNeededForNextLevel && xpNeededForNextLevel > 0) { // xpNeededForNextLevel > 0 check to avoid infinite loop if totalXP is very large
             totalXP -= xpNeededForNextLevel; // Deduct XP needed for this level-up
             level++; // Increment level
             // Calculate XP needed for the *next* level (the one we just leveled up to)
             xpNeededForNextLevel = level * 100;
             // Prevent overflow / extremely high levels in practice
             if (level > 1000) break; // Arbitrary cap to prevent issues
        }

        return (level, totalXP); // Return new level and remaining XP
    }

    // Internal helper to add reputation to a persona
    function _updatePersonaReputation(address _user, uint256 _reputationAmount) internal personaExists(_user) {
        PersonaProfile storage persona = _personas[_user];
        uint256 oldReputation = persona.reputationScore;
        persona.reputationScore += _reputationAmount;
        emit ReputationUpdated(_user, persona.reputationScore, _reputationAmount);
    }

    // Internal helper to add XP to a persona's skill and handle level ups
    function _updatePersonaSkillXP(address _user, bytes32 _skillHash, uint256 _xpAmount) internal personaExists(_user) skillExists(_skillHash) {
         PersonaProfile storage persona = _personas[_user];
         SkillData storage skill = persona.skills[_skillHash];

         // Only add XP if the skill has been explicitly added (level > 0)
         if (skill.level == 0) return; // Should not happen if _distributeProjectRewards implicitly adds, but safe check.

         uint256 oldXP = skill.xp;
         uint256 oldLevel = skill.level;

         (uint256 newLevel, uint256 remainingXP) = _calculateLevelUp(skill.level, skill.xp, _xpAmount);

         skill.xp = remainingXP;
         skill.level = newLevel;

         emit SkillXPUpdated(_user, _skillHash, skill.xp, _xpAmount);

         if (newLevel > oldLevel) {
             emit SkillLeveledUp(_user, _skillHash, newLevel, remainingXP);
         }
    }

    // --- Fallback and Receive (Optional, not required for this concept) ---
    // receive() external payable {}
    // fallback() external payable {}
}
```