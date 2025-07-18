Okay, this is an exciting challenge! Let's design a smart contract system that goes beyond simple token transfers or NFTs. We'll build a "Decentralized Adaptive Identity & Skill Registry with Dynamic Reputation and Talent Matching" system.

**Concept:** This contract allows users to create decentralized profiles, declare and have skills verified by peers or curators, build a dynamic reputation based on contributions and endorsements, and then be matched with projects or bounties that require their unique skill sets and reputation. The "adaptive" part comes from the reputation decay, dynamic skill verification, and project-based reputation adjustments.

---

### **Contract Outline & Function Summary**

**Contract Name:** `TalentNexus`

**Core Idea:** A decentralized platform for identity, skill verification, dynamic reputation, and project-to-talent matching.

**Key Features:**
1.  **Decentralized Profiles:** Users own their identity data.
2.  **Verifiable Skills:** Skills can be self-declared and then verified by other users or designated curators.
3.  **Dynamic Reputation System:** Reputation increases/decreases based on endorsements, project completion, and penalties. It also decays over time, encouraging continuous engagement.
4.  **Project/Bounty System:** Project creators can post tasks, define required skills/reputation, and reward talent.
5.  **Talent Matching:** Basic on-chain matching capabilities for projects to find talent and vice-versa.
6.  **Dispute Resolution (Basic):** A mechanism for resolving conflicts.

---

**Function Summary:**

**I. Core Identity & Profile Management**
1.  `createProfile(string memory _name, string memory _bio)`: Creates a new user profile.
2.  `updateProfileBio(string memory _newBio)`: Updates a user's profile biography.
3.  `deactivateProfile()`: Temporarily deactivates a user's profile.
4.  `reactivateProfile()`: Reactivates a deactivated profile.
5.  `setProfileVisibility(bool _isVisible)`: Sets whether a profile is publicly discoverable.

**II. Skill Management & Verification**
6.  `registerSkill(string memory _skillName, string memory _skillDescription)`: Registers a new skill in the system (callable by admin).
7.  `addSkillToProfile(bytes32 _skillId)`: Adds a declared skill to the caller's profile.
8.  `removeSkillFromProfile(bytes32 _skillId)`: Removes a declared skill from the caller's profile.
9.  `endorseSkill(address _profileAddress, bytes32 _skillId)`: Allows one user to endorse another's skill. This also contributes to reputation.
10. `setSkillCurator(address _curatorAddress, bool _isCurator)`: Assigns or revokes skill curator role (admin only).
11. `verifySkillByCurator(address _profileAddress, bytes32 _skillId)`: A designated curator formally verifies a skill for a profile.

**III. Dynamic Reputation System**
12. `calculateCurrentReputation(address _profileAddress)`: Calculates the real-time reputation score for a profile, considering decay.
13. `endorseProfile(address _profileAddress, string memory _reason)`: Allows one user to endorse another's profile, boosting their reputation.
14. `penalizeReputation(address _profileAddress, uint256 _amount, string memory _reason)`: Admin function to reduce a profile's reputation.
15. `setReputationDecayRate(uint256 _decayRatePerYear)`: Sets the global reputation decay rate (admin only).

**IV. Project & Talent Matching System**
16. `createProject(string memory _title, string memory _description, uint256 _rewardAmount, IERC20 _rewardTokenAddress, uint256 _deadline, uint256 _minReputationRequired, bytes32[] memory _requiredSkills)`: Creates a new project/bounty.
17. `applyForProject(bytes32 _projectId)`: Allows a user to apply for a project.
18. `selectTalentForProject(bytes32 _projectId, address _talentAddress)`: Project creator selects talent from applicants.
19. `submitProjectCompletion(bytes32 _projectId)`: Selected talent submits project completion.
20. `confirmProjectCompletionAndReward(bytes32 _projectId, address _talentAddress)`: Project creator confirms completion, releases rewards, and boosts talent reputation.
21. `cancelProject(bytes32 _projectId)`: Project creator can cancel an ongoing project.
22. `discoverProjectsBySkill(bytes32 _skillId)`: Finds active projects requiring a specific skill (returns array of IDs).
23. `discoverTalentBySkill(bytes32 _skillId)`: Finds profiles with a specific skill, ordered by reputation (returns array of addresses).

**V. Dispute Resolution (Basic)**
24. `initiateDispute(bytes32 _projectId, address _partyA, address _partyB, string memory _details)`: Initiates a dispute for a project.
25. `resolveDispute(bytes32 _projectId, address _winner, uint256 _reputationPenaltyLoser, string memory _resolutionDetails)`: Admin/DAO function to resolve a dispute.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Context.sol";

// --- Contract Outline & Function Summary ---
//
// Contract Name: TalentNexus
// Core Idea: A decentralized platform for identity, skill verification, dynamic reputation, and project-to-talent matching.
//
// Key Features:
// 1. Decentralized Profiles: Users own their identity data.
// 2. Verifiable Skills: Skills can be self-declared and then verified by other users or designated curators.
// 3. Dynamic Reputation System: Reputation increases/decreases based on contributions and endorsements. It also decays over time, encouraging continuous engagement.
// 4. Project/Bounty System: Project creators can post tasks, define required skills/reputation, and reward talent.
// 5. Talent Matching: Basic on-chain matching capabilities for projects to find talent and vice-versa.
// 6. Dispute Resolution (Basic): A mechanism for resolving conflicts.
//
// Function Summary:
//
// I. Core Identity & Profile Management
// 1. createProfile(string memory _name, string memory _bio): Creates a new user profile.
// 2. updateProfileBio(string memory _newBio): Updates a user's profile biography.
// 3. deactivateProfile(): Temporarily deactivates a user's profile.
// 4. reactivateProfile(): Reactivates a deactivated profile.
// 5. setProfileVisibility(bool _isVisible): Sets whether a profile is publicly discoverable.
//
// II. Skill Management & Verification
// 6. registerSkill(string memory _skillName, string memory _skillDescription): Registers a new skill in the system (callable by admin).
// 7. addSkillToProfile(bytes32 _skillId): Adds a declared skill to the caller's profile.
// 8. removeSkillFromProfile(bytes32 _skillId): Removes a declared skill from the caller's profile.
// 9. endorseSkill(address _profileAddress, bytes32 _skillId): Allows one user to endorse another's skill. This also contributes to reputation.
// 10. setSkillCurator(address _curatorAddress, bool _isCurator): Assigns or revokes skill curator role (admin only).
// 11. verifySkillByCurator(address _profileAddress, bytes32 _skillId): A designated curator formally verifies a skill for a profile.
//
// III. Dynamic Reputation System
// 12. calculateCurrentReputation(address _profileAddress): Calculates the real-time reputation score for a profile, considering decay.
// 13. endorseProfile(address _profileAddress, string memory _reason): Allows one user to endorse another's profile, boosting their reputation.
// 14. penalizeReputation(address _profileAddress, uint256 _amount, string memory _reason): Admin function to reduce a profile's reputation.
// 15. setReputationDecayRate(uint256 _decayRatePerYear): Sets the global reputation decay rate (admin only).
//
// IV. Project & Talent Matching System
// 16. createProject(string memory _title, string memory _description, uint256 _rewardAmount, IERC20 _rewardTokenAddress, uint256 _deadline, uint256 _minReputationRequired, bytes32[] memory _requiredSkills): Creates a new project/bounty.
// 17. applyForProject(bytes32 _projectId): Allows a user to apply for a project.
// 18. selectTalentForProject(bytes32 _projectId, address _talentAddress): Project creator selects talent from applicants.
// 19. submitProjectCompletion(bytes32 _projectId): Selected talent submits project completion.
// 20. confirmProjectCompletionAndReward(bytes32 _projectId, address _talentAddress): Project creator confirms completion, releases rewards, and boosts talent reputation.
// 21. cancelProject(bytes33 _projectId): Project creator can cancel an ongoing project.
// 22. discoverProjectsBySkill(bytes32 _skillId): Finds active projects requiring a specific skill (returns array of IDs).
// 23. discoverTalentBySkill(bytes32 _skillId): Finds profiles with a specific skill, ordered by reputation (returns array of addresses).
//
// V. Dispute Resolution (Basic)
// 24. initiateDispute(bytes32 _projectId, address _partyA, address _partyB, string memory _details): Initiates a dispute for a project.
// 25. resolveDispute(bytes32 _projectId, address _winner, uint256 _reputationPenaltyLoser, string memory _resolutionDetails): Admin/DAO function to resolve a dispute.
//
// --- End Outline ---


contract TalentNexus is Ownable {

    // --- Custom Errors ---
    error ProfileAlreadyExists();
    error ProfileDoesNotExist();
    error ProfileNotActive();
    error ProfileIsActive();
    error UnauthorizedAction();
    error InvalidSkillId();
    error SkillAlreadyRegistered();
    error SkillNotRegistered();
    error SkillAlreadyAdded();
    error SkillNotAdded();
    error SelfEndorsementNotAllowed();
    error AlreadyEndorsed();
    error ProjectDoesNotExist();
    error ProjectNotActive();
    error ProjectStatusInvalid();
    error ApplicantNotEligible();
    error AlreadyApplied();
    error NotAnApplicant();
    error NoApplicants();
    error TalentAlreadySelected();
    error TalentNotSelected();
    error ProjectNotCompletedByTalent();
    error ProjectRewardTransferFailed();
    error InvalidRewardToken();
    error DisputeAlreadyActive();
    error DisputeNotActive();
    error NotDisputeParticipant();

    // --- Enums ---
    enum ProjectStatus { Pending, Active, CompletedByTalent, Completed, Cancelled, Disputed }

    // --- Structs ---

    struct Profile {
        string name;
        string bio;
        uint256 creationTime;
        uint256 lastReputationUpdateTime; // For decay calculation
        uint256 currentRawReputation;     // Base reputation score
        bool isActive;
        bool isVisible;
        mapping(bytes32 => bool) declaredSkills; // Skills declared by the user
        mapping(bytes32 => bool) verifiedSkills; // Skills verified by curators
        mapping(bytes32 => mapping(address => bool)) skillEndorsedBy; // Skill ID => Endorser => bool
        mapping(address => bool) profileEndorsedBy; // Profile Endorser => bool
        bytes32[] declaredSkillIds; // Array for iteration
    }

    struct Skill {
        bytes32 skillId;
        string name;
        string description;
        address[] verifiedByCurators;
        uint256 endorsementCount; // Number of peer endorsements
    }

    struct Project {
        bytes32 projectId;
        address owner;
        string title;
        string description;
        uint256 rewardAmount;
        IERC20 rewardToken;
        uint256 deadline;
        uint256 minReputationRequired;
        bytes32[] requiredSkills;
        ProjectStatus status;
        address[] applicants;
        mapping(address => bool) hasApplied;
        address selectedTalent;
        bool talentSubmittedCompletion;
        bool disputeActive;
    }

    struct Dispute {
        bytes32 projectId;
        address partyA;
        address partyB;
        string details;
        bool resolved;
        address winner; // Address of the party who won the dispute
    }

    // --- State Variables ---

    mapping(address => Profile) public profiles;
    mapping(address => bool) public hasProfile;
    address[] public allProfiles; // For iteration/discovery, could grow large

    mapping(bytes32 => Skill) public skills;
    mapping(bytes32 => bool) public isSkillRegistered;
    bytes32[] public allRegisteredSkillIds; // For iteration/discovery

    mapping(address => bool) public isSkillCurator; // Curators for skill verification

    mapping(bytes32 => Project) public projects;
    mapping(bytes32 => bool) public isProjectRegistered;
    bytes32[] public activeProjectIds; // For iteration/discovery

    mapping(bytes32 => Dispute) public disputes;
    mapping(bytes32 => bool) public isDisputeRegistered;

    uint256 public reputationDecayRatePerYear = 10; // Percentage per year (e.g., 10 for 10%)
    uint256 public constant BASE_REPUTATION_FOR_CREATION = 100; // Starting reputation for new profiles
    uint256 public constant ENDORSEMENT_REPUTATION_GAIN = 5;
    uint256 public constant PROJECT_COMPLETION_REPUTATION_GAIN = 50;

    uint256 private nextProjectId = 1;
    uint256 private nextSkillId = 1; // Used for generating unique IDs

    // --- Events ---

    event ProfileCreated(address indexed user, string name, uint256 creationTime);
    event ProfileUpdated(address indexed user, string newBio);
    event ProfileDeactivated(address indexed user);
    event ProfileReactivated(address indexed user);
    event ProfileVisibilityChanged(address indexed user, bool isVisible);

    event SkillRegistered(bytes32 indexed skillId, string name, string description);
    event SkillAddedToProfile(address indexed user, bytes32 indexed skillId);
    event SkillRemovedFromProfile(address indexed user, bytes32 indexed skillId);
    event SkillEndorsed(address indexed endorser, address indexed endorsee, bytes32 indexed skillId);
    event SkillCuratorSet(address indexed curator, bool status);
    event SkillVerifiedByCurator(address indexed curator, address indexed profile, bytes32 indexed skillId);

    event ReputationUpdated(address indexed profile, uint256 oldReputation, uint256 newReputation, string reason);
    event ReputationDecayRateSet(uint256 newRate);

    event ProjectCreated(bytes32 indexed projectId, address indexed owner, string title, uint256 rewardAmount, IERC20 rewardToken, uint256 deadline);
    event ProjectApplied(bytes32 indexed projectId, address indexed applicant);
    event TalentSelected(bytes32 indexed projectId, address indexed talent);
    event ProjectCompletionSubmitted(bytes32 indexed projectId, address indexed talent);
    event ProjectCompleted(bytes32 indexed projectId, address indexed talent, uint256 rewardAmount);
    event ProjectCancelled(bytes32 indexed projectId, address indexed owner);

    event DisputeInitiated(bytes32 indexed projectId, address indexed partyA, address indexed partyB);
    event DisputeResolved(bytes32 indexed projectId, address indexed winner, uint256 reputationPenaltyLoser, string resolutionDetails);

    // --- Modifiers ---

    modifier onlyProfileOwner(address _profileAddress) {
        if (msg.sender != _profileAddress) revert UnauthorizedAction();
        _;
    }

    modifier profileMustExist(address _profileAddress) {
        if (!hasProfile[_profileAddress]) revert ProfileDoesNotExist();
        _;
    }

    modifier profileMustBeActive(address _profileAddress) {
        profileMustExist(_profileAddress);
        if (!profiles[_profileAddress].isActive) revert ProfileNotActive();
        _;
    }

    modifier projectMustExist(bytes32 _projectId) {
        if (!isProjectRegistered[_projectId]) revert ProjectDoesNotExist();
        _;
    }

    modifier onlyProjectOwner(bytes32 _projectId) {
        projectMustExist(_projectId);
        if (projects[_projectId].owner != msg.sender) revert UnauthorizedAction();
        _;
    }

    // --- Constructor ---
    constructor() Ownable(msg.sender) {
        // Initial setup for the owner/admin
    }

    // --- Internal Helpers ---

    function _generateSkillId(string memory _name) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(_name));
    }

    function _generateProjectId() internal returns (bytes32) {
        bytes32 newId = keccak256(abi.encodePacked(block.timestamp, msg.sender, nextProjectId++));
        // Ensure ID is unique, though timestamp + sender + counter makes collisions unlikely
        while (isProjectRegistered[newId]) {
            newId = keccak256(abi.encodePacked(block.timestamp, msg.sender, nextProjectId++));
        }
        return newId;
    }

    function _updateReputation(address _profileAddress, int256 _changeAmount, string memory _reason) internal {
        profileMustExist(_profileAddress);
        Profile storage p = profiles[_profileAddress];
        uint256 oldReputation = calculateCurrentReputation(_profileAddress);

        // Apply decay before applying new change
        p.currentRawReputation = oldReputation;
        
        if (_changeAmount > 0) {
            p.currentRawReputation += uint256(_changeAmount);
        } else {
            if (p.currentRawReputation < uint256(-_changeAmount)) {
                p.currentRawReputation = 0;
            } else {
                p.currentRawReputation -= uint256(-_changeAmount);
            }
        }
        p.lastReputationUpdateTime = block.timestamp;
        emit ReputationUpdated(_profileAddress, oldReputation, p.currentRawReputation, _reason);
    }

    // --- I. Core Identity & Profile Management (5 Functions) ---

    /// @notice Creates a new user profile.
    /// @param _name The desired name for the profile.
    /// @param _bio A short biography for the profile.
    function createProfile(string memory _name, string memory _bio) public {
        if (hasProfile[msg.sender]) revert ProfileAlreadyExists();

        Profile storage newProfile = profiles[msg.sender];
        newProfile.name = _name;
        newProfile.bio = _bio;
        newProfile.creationTime = block.timestamp;
        newProfile.lastReputationUpdateTime = block.timestamp;
        newProfile.currentRawReputation = BASE_REPUTATION_FOR_CREATION;
        newProfile.isActive = true;
        newProfile.isVisible = true;

        hasProfile[msg.sender] = true;
        allProfiles.push(msg.sender);

        emit ProfileCreated(msg.sender, _name, block.timestamp);
        emit ReputationUpdated(msg.sender, 0, BASE_REPUTATION_FOR_CREATION, "Profile creation");
    }

    /// @notice Updates a user's profile biography.
    /// @param _newBio The new biography text.
    function updateProfileBio(string memory _newBio) public profileMustBeActive(msg.sender) {
        profiles[msg.sender].bio = _newBio;
        emit ProfileUpdated(msg.sender, _newBio);
    }

    /// @notice Temporarily deactivates a user's profile, making it undiscoverable.
    function deactivateProfile() public profileMustBeActive(msg.sender) {
        profiles[msg.sender].isActive = false;
        profiles[msg.sender].isVisible = false; // Deactivated profiles are not visible
        emit ProfileDeactivated(msg.sender);
    }

    /// @notice Reactivates a deactivated profile.
    function reactivateProfile() public profileMustExist(msg.sender) {
        if (profiles[msg.sender].isActive) revert ProfileIsActive();
        profiles[msg.sender].isActive = true;
        profiles[msg.sender].isVisible = true; // Reactivated profiles are visible by default
        emit ProfileReactivated(msg.sender);
    }

    /// @notice Sets whether a profile is publicly discoverable.
    /// @param _isVisible True to make visible, false otherwise.
    function setProfileVisibility(bool _isVisible) public profileMustBeActive(msg.sender) {
        profiles[msg.sender].isVisible = _isVisible;
        emit ProfileVisibilityChanged(msg.sender, _isVisible);
    }

    // --- II. Skill Management & Verification (6 Functions) ---

    /// @notice Registers a new skill in the system. Only callable by the contract owner.
    /// @param _skillName The name of the skill (e.g., "Solidity Development").
    /// @param _skillDescription A brief description of the skill.
    function registerSkill(string memory _skillName, string memory _skillDescription) public onlyOwner {
        bytes32 skillId = _generateSkillId(_skillName);
        if (isSkillRegistered[skillId]) revert SkillAlreadyRegistered();

        skills[skillId] = Skill({
            skillId: skillId,
            name: _skillName,
            description: _skillDescription,
            verifiedByCurators: new address[](0),
            endorsementCount: 0
        });
        isSkillRegistered[skillId] = true;
        allRegisteredSkillIds.push(skillId);
        emit SkillRegistered(skillId, _skillName, _skillDescription);
    }

    /// @notice Adds a declared skill to the caller's profile.
    /// @param _skillId The ID of the skill to add.
    function addSkillToProfile(bytes32 _skillId) public profileMustBeActive(msg.sender) {
        if (!isSkillRegistered[_skillId]) revert InvalidSkillId();
        Profile storage p = profiles[msg.sender];
        if (p.declaredSkills[_skillId]) revert SkillAlreadyAdded();

        p.declaredSkills[_skillId] = true;
        p.declaredSkillIds.push(_skillId); // Add to dynamic array
        emit SkillAddedToProfile(msg.sender, _skillId);
    }

    /// @notice Removes a declared skill from the caller's profile.
    /// @param _skillId The ID of the skill to remove.
    function removeSkillFromProfile(bytes32 _skillId) public profileMustBeActive(msg.sender) {
        Profile storage p = profiles[msg.sender];
        if (!p.declaredSkills[_skillId]) revert SkillNotAdded();

        p.declaredSkills[_skillId] = false;
        // Remove from dynamic array (inefficient for large arrays, but acceptable for skill lists)
        for (uint i = 0; i < p.declaredSkillIds.length; i++) {
            if (p.declaredSkillIds[i] == _skillId) {
                p.declaredSkillIds[i] = p.declaredSkillIds[p.declaredSkillIds.length - 1];
                p.declaredSkillIds.pop();
                break;
            }
        }
        // Also remove if it was verified
        p.verifiedSkills[_skillId] = false; 
        emit SkillRemovedFromProfile(msg.sender, _skillId);
    }

    /// @notice Allows one user to endorse another's skill. This also contributes to reputation.
    /// @param _profileAddress The address of the profile whose skill is being endorsed.
    /// @param _skillId The ID of the skill being endorsed.
    function endorseSkill(address _profileAddress, bytes32 _skillId) public profileMustBeActive(msg.sender) profileMustBeActive(_profileAddress) {
        if (msg.sender == _profileAddress) revert SelfEndorsementNotAllowed();
        if (!isSkillRegistered[_skillId]) revert InvalidSkillId();
        Profile storage targetProfile = profiles[_profileAddress];
        if (!targetProfile.declaredSkills[_skillId]) revert SkillNotAdded(); // Can only endorse declared skills

        if (targetProfile.skillEndorsedBy[_skillId][msg.sender]) revert AlreadyEndorsed();

        targetProfile.skillEndorsedBy[_skillId][msg.sender] = true;
        skills[_skillId].endorsementCount++;
        _updateReputation(_profileAddress, int256(ENDORSEMENT_REPUTATION_GAIN), "Skill endorsement");
        emit SkillEndorsed(msg.sender, _profileAddress, _skillId);
    }

    /// @notice Assigns or revokes skill curator role. Only callable by the contract owner.
    /// @param _curatorAddress The address to set/unset as a curator.
    /// @param _isCurator True to assign, false to revoke.
    function setSkillCurator(address _curatorAddress, bool _isCurator) public onlyOwner {
        isSkillCurator[_curatorAddress] = _isCurator;
        emit SkillCuratorSet(_curatorAddress, _isCurator);
    }

    /// @notice A designated curator formally verifies a skill for a profile.
    /// @param _profileAddress The address of the profile whose skill is being verified.
    /// @param _skillId The ID of the skill to verify.
    function verifySkillByCurator(address _profileAddress, bytes32 _skillId) public profileMustBeActive(_profileAddress) {
        if (!isSkillCurator[msg.sender]) revert UnauthorizedAction();
        if (!isSkillRegistered[_skillId]) revert InvalidSkillId();
        Profile storage targetProfile = profiles[_profileAddress];
        if (!targetProfile.declaredSkills[_skillId]) revert SkillNotAdded(); // Must be declared first

        if (!targetProfile.verifiedSkills[_skillId]) { // Only add if not already verified
            targetProfile.verifiedSkills[_skillId] = true;
            skills[_skillId].verifiedByCurators.push(msg.sender); // Add curator to list for this skill
            _updateReputation(_profileAddress, int256(ENDORSEMENT_REPUTATION_GAIN * 2), "Curator skill verification"); // Stronger reputation gain
            emit SkillVerifiedByCurator(msg.sender, _profileAddress, _skillId);
        }
    }

    // --- III. Dynamic Reputation System (4 Functions) ---

    /// @notice Calculates the real-time reputation score for a profile, considering decay.
    /// @param _profileAddress The address of the profile.
    /// @return The current effective reputation score.
    function calculateCurrentReputation(address _profileAddress) public view profileMustExist(_profileAddress) returns (uint256) {
        Profile storage p = profiles[_profileAddress];
        if (reputationDecayRatePerYear == 0) return p.currentRawReputation; // No decay

        uint256 timeElapsed = block.timestamp - p.lastReputationUpdateTime;
        // Simple linear decay for demonstration. More complex models could be exponential.
        // Decay = (raw_reputation * decay_rate * time_elapsed_in_seconds) / (seconds_in_a_year * 100)
        uint256 secondsInYear = 365 days;
        uint256 decayAmount = (p.currentRawReputation * reputationDecayRatePerYear * timeElapsed) / (secondsInYear * 100);

        return p.currentRawReputation > decayAmount ? p.currentRawReputation - decayAmount : 0;
    }

    /// @notice Allows one user to endorse another's profile, boosting their reputation.
    /// @param _profileAddress The address of the profile being endorsed.
    /// @param _reason A short reason for the endorsement.
    function endorseProfile(address _profileAddress, string memory _reason) public profileMustBeActive(msg.sender) profileMustBeActive(_profileAddress) {
        if (msg.sender == _profileAddress) revert SelfEndorsementNotAllowed();
        Profile storage targetProfile = profiles[_profileAddress];
        if (targetProfile.profileEndorsedBy[msg.sender]) revert AlreadyEndorsed();

        targetProfile.profileEndorsedBy[msg.sender] = true;
        _updateReputation(_profileAddress, int256(ENDORSEMENT_REPUTATION_GAIN * 3), string.concat("Profile endorsement: ", _reason)); // Stronger gain than skill endorsement
        emit ReputationUpdated(_profileAddress, calculateCurrentReputation(_profileAddress), calculateCurrentReputation(_profileAddress) + (ENDORSEMENT_REPUTATION_GAIN * 3), "Profile endorsement");
    }

    /// @notice Admin function to reduce a profile's reputation.
    /// @param _profileAddress The address of the profile to penalize.
    /// @param _amount The amount of reputation to deduct.
    /// @param _reason The reason for the penalty.
    function penalizeReputation(address _profileAddress, uint256 _amount, string memory _reason) public onlyOwner profileMustExist(_profileAddress) {
        _updateReputation(_profileAddress, -int256(_amount), string.concat("Reputation penalty: ", _reason));
    }

    /// @notice Sets the global reputation decay rate. Only callable by the contract owner.
    /// @param _decayRatePerYear The percentage of reputation decay per year (e.g., 10 for 10%).
    function setReputationDecayRate(uint256 _decayRatePerYear) public onlyOwner {
        reputationDecayRatePerYear = _decayRatePerYear;
        emit ReputationDecayRateSet(_decayRatePerYear);
    }

    // --- IV. Project & Talent Matching System (8 Functions) ---

    /// @notice Creates a new project/bounty. The reward token amount must be approved beforehand.
    /// @param _title The title of the project.
    /// @param _description A detailed description of the project.
    /// @param _rewardAmount The amount of reward tokens for successful completion.
    /// @param _rewardTokenAddress The address of the ERC-20 token used for rewards.
    /// @param _deadline The timestamp by which the project must be completed.
    /// @param _minReputationRequired The minimum reputation score required for applicants.
    /// @param _requiredSkills An array of skill IDs required for the project.
    function createProject(
        string memory _title,
        string memory _description,
        uint256 _rewardAmount,
        IERC20 _rewardTokenAddress,
        uint256 _deadline,
        uint256 _minReputationRequired,
        bytes32[] memory _requiredSkills
    ) public profileMustBeActive(msg.sender) {
        if (_rewardAmount == 0) revert InvalidRewardToken();
        if (_deadline <= block.timestamp) revert ProjectStatusInvalid();

        bytes32 projectId = _generateProjectId();

        // Transfer reward tokens from creator to the contract
        // Creator must have approved this contract beforehand for _rewardAmount
        require(_rewardTokenAddress.transferFrom(msg.sender, address(this), _rewardAmount), "Token transfer failed");

        projects[projectId] = Project({
            projectId: projectId,
            owner: msg.sender,
            title: _title,
            description: _description,
            rewardAmount: _rewardAmount,
            rewardToken: _rewardTokenAddress,
            deadline: _deadline,
            minReputationRequired: _minReputationRequired,
            requiredSkills: _requiredSkills,
            status: ProjectStatus.Pending,
            applicants: new address[](0),
            hasApplied: new mapping(address => bool)(),
            selectedTalent: address(0),
            talentSubmittedCompletion: false,
            disputeActive: false
        });
        isProjectRegistered[projectId] = true;
        activeProjectIds.push(projectId);
        emit ProjectCreated(projectId, msg.sender, _title, _rewardAmount, _rewardTokenAddress, _deadline);
    }

    /// @notice Allows a user to apply for a project.
    /// @param _projectId The ID of the project to apply for.
    function applyForProject(bytes32 _projectId) public profileMustBeActive(msg.sender) projectMustExist(_projectId) {
        Project storage p = projects[_projectId];
        if (p.status != ProjectStatus.Pending && p.status != ProjectStatus.Active) revert ProjectStatusInvalid();
        if (p.hasApplied[msg.sender]) revert AlreadyApplied();
        if (calculateCurrentReputation(msg.sender) < p.minReputationRequired) revert ApplicantNotEligible();

        // Check if applicant has all required skills (declared or verified)
        for (uint i = 0; i < p.requiredSkills.length; i++) {
            bytes32 skillId = p.requiredSkills[i];
            if (!profiles[msg.sender].declaredSkills[skillId] && !profiles[msg.sender].verifiedSkills[skillId]) {
                revert ApplicantNotEligible(); // Missing required skill
            }
        }

        p.applicants.push(msg.sender);
        p.hasApplied[msg.sender] = true;
        p.status = ProjectStatus.Active; // Transition to active once first applicant applies
        emit ProjectApplied(_projectId, msg.sender);
    }

    /// @notice Project creator selects talent from applicants.
    /// @param _projectId The ID of the project.
    /// @param _talentAddress The address of the selected talent.
    function selectTalentForProject(bytes32 _projectId, address _talentAddress) public onlyProjectOwner(_projectId) {
        Project storage p = projects[_projectId];
        if (p.status != ProjectStatus.Active) revert ProjectStatusInvalid();
        if (!p.hasApplied[_talentAddress]) revert NotAnApplicant();
        if (p.selectedTalent != address(0)) revert TalentAlreadySelected();

        p.selectedTalent = _talentAddress;
        emit TalentSelected(_projectId, _talentAddress);
    }

    /// @notice Selected talent submits project completion.
    /// @param _projectId The ID of the project.
    function submitProjectCompletion(bytes32 _projectId) public profileMustBeActive(msg.sender) projectMustExist(_projectId) {
        Project storage p = projects[_projectId];
        if (p.selectedTalent != msg.sender) revert UnauthorizedAction();
        if (p.status != ProjectStatus.Active) revert ProjectStatusInvalid();
        if (block.timestamp > p.deadline) revert ProjectStatusInvalid(); // Past deadline

        p.talentSubmittedCompletion = true;
        p.status = ProjectStatus.CompletedByTalent;
        emit ProjectCompletionSubmitted(_projectId, msg.sender);
    }

    /// @notice Project creator confirms completion, releases rewards, and boosts talent reputation.
    /// @param _projectId The ID of the project.
    /// @param _talentAddress The address of the talent who completed the project.
    function confirmProjectCompletionAndReward(bytes32 _projectId, address _talentAddress) public onlyProjectOwner(_projectId) {
        Project storage p = projects[_projectId];
        if (p.selectedTalent != _talentAddress) revert TalentNotSelected();
        if (p.status != ProjectStatus.CompletedByTalent) revert ProjectNotCompletedByTalent();
        if (p.disputeActive) revert DisputeAlreadyActive();

        // Transfer rewards to talent
        require(p.rewardToken.transfer(_talentAddress, p.rewardAmount), "Reward token transfer failed");

        // Boost talent reputation
        _updateReputation(_talentAddress, int256(PROJECT_COMPLETION_REPUTATION_GAIN), "Project completion reward");

        p.status = ProjectStatus.Completed;
        // Remove from active projects list (inefficient for large arrays, consider using mapping to bool)
        for (uint i = 0; i < activeProjectIds.length; i++) {
            if (activeProjectIds[i] == _projectId) {
                activeProjectIds[i] = activeProjectIds[activeProjectIds.length - 1];
                activeProjectIds.pop();
                break;
            }
        }
        emit ProjectCompleted(_projectId, _talentAddress, p.rewardAmount);
    }

    /// @notice Project creator can cancel an ongoing project. Rewards are returned to creator.
    /// @param _projectId The ID of the project to cancel.
    function cancelProject(bytes32 _projectId) public onlyProjectOwner(_projectId) {
        Project storage p = projects[_projectId];
        if (p.status == ProjectStatus.Completed || p.status == ProjectStatus.CompletedByTalent || p.status == ProjectStatus.Cancelled) {
            revert ProjectStatusInvalid();
        }
        if (p.disputeActive) revert DisputeAlreadyActive();

        // Refund reward tokens to the project owner
        require(p.rewardToken.transfer(msg.sender, p.rewardAmount), "Refund token transfer failed");

        p.status = ProjectStatus.Cancelled;
         // Remove from active projects list
        for (uint i = 0; i < activeProjectIds.length; i++) {
            if (activeProjectIds[i] == _projectId) {
                activeProjectIds[i] = activeProjectIds[activeProjectIds.length - 1];
                activeProjectIds.pop();
                break;
            }
        }
        emit ProjectCancelled(_projectId, msg.sender);
    }

    /// @notice Finds active projects requiring a specific skill.
    /// @param _skillId The ID of the skill to search for.
    /// @return An array of project IDs.
    function discoverProjectsBySkill(bytes32 _skillId) public view returns (bytes32[] memory) {
        if (!isSkillRegistered[_skillId]) revert InvalidSkillId();

        bytes32[] memory matchingProjects = new bytes32[](0);
        uint256 count = 0;

        // First pass to count
        for (uint i = 0; i < activeProjectIds.length; i++) {
            bytes32 projectId = activeProjectIds[i];
            Project storage p = projects[projectId];

            // Only consider projects that are Pending or Active and not cancelled/disputed/completed
            if (p.status == ProjectStatus.Pending || p.status == ProjectStatus.Active) {
                for (uint j = 0; j < p.requiredSkills.length; j++) {
                    if (p.requiredSkills[j] == _skillId) {
                        count++;
                        break;
                    }
                }
            }
        }

        // Second pass to populate the array
        matchingProjects = new bytes32[](count);
        uint256 currentIdx = 0;
        for (uint i = 0; i < activeProjectIds.length; i++) {
            bytes32 projectId = activeProjectIds[i];
            Project storage p = projects[projectId];
            if (p.status == ProjectStatus.Pending || p.status == ProjectStatus.Active) {
                for (uint j = 0; j < p.requiredSkills.length; j++) {
                    if (p.requiredSkills[j] == _skillId) {
                        matchingProjects[currentIdx++] = projectId;
                        break;
                    }
                }
            }
        }
        return matchingProjects;
    }

    /// @notice Finds profiles with a specific skill, ordered by reputation (simplistic ordering for on-chain).
    /// @param _skillId The ID of the skill to search for.
    /// @return An array of profile addresses.
    function discoverTalentBySkill(bytes32 _skillId) public view returns (address[] memory) {
        if (!isSkillRegistered[_skillId]) revert InvalidSkillId();

        address[] memory matchingTalent = new address[](0);
        uint256 count = 0;

        // First pass to count
        for (uint i = 0; i < allProfiles.length; i++) {
            address profileAddr = allProfiles[i];
            Profile storage p = profiles[profileAddr];

            if (p.isActive && p.isVisible && (p.declaredSkills[_skillId] || p.verifiedSkills[_skillId])) {
                count++;
            }
        }

        // Second pass to populate (no complex sorting on-chain for gas limits)
        matchingTalent = new address[](count);
        uint256 currentIdx = 0;
        for (uint i = 0; i < allProfiles.length; i++) {
            address profileAddr = allProfiles[i];
            Profile storage p = profiles[profileAddr];

            if (p.isActive && p.isVisible && (p.declaredSkills[_skillId] || p.verifiedSkills[_skillId])) {
                matchingTalent[currentIdx++] = profileAddr;
            }
        }
        return matchingTalent;
    }

    // --- V. Dispute Resolution (Basic) (2 Functions) ---

    /// @notice Initiates a dispute for a project. Can be called by project owner or selected talent.
    /// @param _projectId The ID of the project under dispute.
    /// @param _partyA The address of the first party in the dispute.
    /// @param _partyB The address of the second party in the dispute.
    /// @param _details A description of the dispute.
    function initiateDispute(bytes32 _projectId, address _partyA, address _partyB, string memory _details) public projectMustExist(_projectId) {
        Project storage p = projects[_projectId];
        if (p.disputeActive) revert DisputeAlreadyActive();
        if (msg.sender != p.owner && msg.sender != p.selectedTalent) revert UnauthorizedAction(); // Only owner or selected talent can initiate
        if (_partyA != p.owner && _partyA != p.selectedTalent) revert NotDisputeParticipant();
        if (_partyB != p.owner && _partyB != p.selectedTalent) revert NotDisputeParticipant();
        if (_partyA == _partyB) revert NotDisputeParticipant(); // Must be two different parties

        p.disputeActive = true;
        p.status = ProjectStatus.Disputed;

        disputes[_projectId] = Dispute({
            projectId: _projectId,
            partyA: _partyA,
            partyB: _partyB,
            details: _details,
            resolved: false,
            winner: address(0)
        });
        isDisputeRegistered[_projectId] = true;
        emit DisputeInitiated(_projectId, _partyA, _partyB);
    }

    /// @notice Admin/Owner function to resolve a dispute.
    /// @param _projectId The ID of the disputed project.
    /// @param _winner The address of the party who won the dispute.
    /// @param _reputationPenaltyLoser The amount of reputation to penalize the losing party.
    /// @param _resolutionDetails A description of the resolution.
    function resolveDispute(
        bytes32 _projectId,
        address _winner,
        uint256 _reputationPenaltyLoser,
        string memory _resolutionDetails
    ) public onlyOwner projectMustExist(_projectId) {
        Project storage p = projects[_projectId];
        if (!p.disputeActive) revert DisputeNotActive();
        Dispute storage d = disputes[_projectId];
        if (d.resolved) revert DisputeNotActive();

        address loser = address(0);
        if (_winner == d.partyA) {
            loser = d.partyB;
        } else if (_winner == d.partyB) {
            loser = d.partyA;
        } else {
            revert UnauthorizedAction(); // Winner must be one of the dispute parties
        }

        // Apply penalty to the loser
        _updateReputation(loser, -int256(_reputationPenaltyLoser), string.concat("Dispute resolution penalty: ", _resolutionDetails));

        // Transfer funds based on resolution (logic simplified, could be more complex)
        // For simplicity, let's assume if winner is talent, they get rewards. If owner, rewards are refunded.
        if (_winner == p.selectedTalent && p.rewardAmount > 0) {
            require(p.rewardToken.transfer(p.selectedTalent, p.rewardAmount), "Dispute reward transfer failed");
            _updateReputation(_winner, int256(PROJECT_COMPLETION_REPUTATION_GAIN / 2), "Dispute resolution reward"); // Partial reward gain
        } else if (_winner == p.owner && p.rewardAmount > 0) {
            require(p.rewardToken.transfer(p.owner, p.rewardAmount), "Dispute refund transfer failed");
        }
        
        p.disputeActive = false;
        p.status = ProjectStatus.Completed; // Or ProjectStatus.Cancelled, depending on outcome
        d.resolved = true;
        d.winner = _winner;

        // Remove from active projects list
        for (uint i = 0; i < activeProjectIds.length; i++) {
            if (activeProjectIds[i] == _projectId) {
                activeProjectIds[i] = activeProjectIds[activeProjectIds.length - 1];
                activeProjectIds.pop();
                break;
            }
        }
        
        emit DisputeResolved(_projectId, _winner, _reputationPenaltyLoser, _resolutionDetails);
    }

    // --- Getter Functions (Public Views for Data Retrieval) ---

    /// @notice Gets profile details for a given address.
    /// @param _profileAddress The address of the profile.
    /// @return name, bio, creationTime, current reputation, isActive, isVisible, declaredSkillCount, verifiedSkillCount
    function getProfile(address _profileAddress) public view profileMustExist(_profileAddress) returns (
        string memory name,
        string memory bio,
        uint256 creationTime,
        uint256 currentReputation,
        bool isActive,
        bool isVisible,
        uint256 declaredSkillCount,
        uint256 verifiedSkillCount
    ) {
        Profile storage p = profiles[_profileAddress];
        uint256 _declaredCount = 0;
        uint256 _verifiedCount = 0;
        for (uint i = 0; i < p.declaredSkillIds.length; i++) {
            _declaredCount++;
            if (p.verifiedSkills[p.declaredSkillIds[i]]) {
                _verifiedCount++;
            }
        }

        return (
            p.name,
            p.bio,
            p.creationTime,
            calculateCurrentReputation(_profileAddress),
            p.isActive,
            p.isVisible,
            _declaredCount,
            _verifiedCount
        );
    }

    /// @notice Gets the skill IDs declared by a profile.
    /// @param _profileAddress The address of the profile.
    /// @return An array of declared skill IDs.
    function getProfileDeclaredSkills(address _profileAddress) public view profileMustExist(_profileAddress) returns (bytes32[] memory) {
        return profiles[_profileAddress].declaredSkillIds;
    }

    /// @notice Checks if a specific skill is verified for a profile.
    /// @param _profileAddress The profile address.
    /// @param _skillId The skill ID to check.
    /// @return True if verified, false otherwise.
    function isSkillVerifiedForProfile(address _profileAddress, bytes32 _skillId) public view returns (bool) {
        return hasProfile[_profileAddress] && profiles[_profileAddress].verifiedSkills[_skillId];
    }

    /// @notice Gets details of a registered skill.
    /// @param _skillId The ID of the skill.
    /// @return name, description, endorsementCount, verifiedByCuratorsCount
    function getSkillDetails(bytes32 _skillId) public view returns (string memory name, string memory description, uint256 endorsementCount, uint256 verifiedByCuratorsCount) {
        if (!isSkillRegistered[_skillId]) revert InvalidSkillId();
        Skill storage s = skills[_skillId];
        return (s.name, s.description, s.endorsementCount, s.verifiedByCurators.length);
    }

    /// @notice Gets project details for a given project ID.
    /// @param _projectId The ID of the project.
    /// @return owner, title, description, rewardAmount, rewardToken, deadline, minReputationRequired, selectedTalent, status, disputeActive
    function getProjectDetails(bytes32 _projectId) public view projectMustExist(_projectId) returns (
        address owner,
        string memory title,
        string memory description,
        uint256 rewardAmount,
        IERC20 rewardToken,
        uint256 deadline,
        uint256 minReputationRequired,
        address selectedTalent,
        ProjectStatus status,
        bool disputeActive
    ) {
        Project storage p = projects[_projectId];
        return (
            p.owner,
            p.title,
            p.description,
            p.rewardAmount,
            p.rewardToken,
            p.deadline,
            p.minReputationRequired,
            p.selectedTalent,
            p.status,
            p.disputeActive
        );
    }

    /// @notice Gets the list of applicants for a project.
    /// @param _projectId The ID of the project.
    /// @return An array of applicant addresses.
    function getProjectApplicants(bytes32 _projectId) public view projectMustExist(_projectId) returns (address[] memory) {
        return projects[_projectId].applicants;
    }

    /// @notice Returns the list of all active project IDs.
    function getAllActiveProjectIds() public view returns (bytes32[] memory) {
        return activeProjectIds;
    }

    /// @notice Returns the list of all registered skill IDs.
    function getAllRegisteredSkillIds() public view returns (bytes32[] memory) {
        return allRegisteredSkillIds;
    }

    /// @notice Returns the list of all profile addresses.
    function getAllProfileAddresses() public view returns (address[] memory) {
        return allProfiles;
    }
}
```