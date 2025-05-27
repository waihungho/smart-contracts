Okay, here is a Solidity smart contract for a Decentralized Skill Sharing and Verification Platform.

This contract incorporates several interesting, advanced, and trendy concepts:

1.  **Soulbound Token (SBT)-like Skill Proofs:** Users earn non-transferable "Skill Tokens" upon successful completion of verified projects or receiving endorsements for specific skills.
2.  **Project/Bounty Escrow & State Machine:** Manages project lifecycle with distinct states (Open, Applied, Selected, InProgress, Completed, Confirmed, Cancelled) and handles bounty payments securely via internal escrow.
3.  **Reputation System:** A basic on-chain reputation score derived from successful project completions and endorsements.
4.  **Internal Token Balances:** Manages user balances for bounties *within* the contract, demonstrating a pattern where a contract acts as a ledger or simple token manager for specific use cases, avoiding the need for a full ERC20 implementation if only used internally (or assuming an external token is handled carefully). *Note: For real-world large-scale use, interacting with a standard ERC20 contract would be more robust.*
5.  **Role-Based Access Control (Simple):** Owner and Admin roles manage core platform data like skills and categories.
6.  **Comprehensive Data Structures:** Uses structs and mappings to store complex relationships between users, skills, projects, and endorsements.
7.  **Event-Driven Architecture:** Emits detailed events for critical actions, enabling easy off-chain tracking and dApp integration.

It aims to be creative by combining elements of decentralized identity (SBT-like skills), decentralized work/freelancing (projects/bounties), and reputation systems.

**Outline & Function Summary**

```
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title DecentralizedSkillShare
 * @dev A smart contract for a decentralized platform connecting users based on skills,
 *      facilitating project collaboration, bounty payments, and verifiable skill proofs (SBT-like).
 *
 * Outline:
 * 1.  State Variables & Data Structures: Define roles, enums, structs for Users, Skills, Projects, etc.
 * 2.  Mappings: Store relationships between addresses, IDs, and data.
 * 3.  Events: Signal important state changes and actions.
 * 4.  Modifiers: Enforce access control and state validity.
 * 5.  Internal Balances / Token Logic: Manage internal balances for bounties.
 * 6.  Core Functionality:
 *     - User Registration & Profile Management
 *     - Skill Category & Skill Management (Admin)
 *     - User Skill Declaration
 *     - Skill Endorsements & Reputation Calculation
 *     - Project Creation, Application, Selection, Completion & Confirmation
 *     - Bounty Escrow & Payment
 *     - Skill Proof Issuance (SBT-like)
 *     - Admin Controls
 *     - Getters (Read-only functions)
 *
 * Function Summary:
 * (A = Admin Only, O = Owner Only, C = Project Creator Only, R = Registered User Only, P = Project Applicant Only)
 *
 * User Management:
 * 1. registerUser(string name): Registers a new user profile. (R)
 * 2. updateProfile(string name, string bio): Updates user profile details. (R)
 * 3. getUserProfile(address user): Retrieves user profile information. (View)
 * 4. isUserRegistered(address user): Checks if an address is a registered user. (View)
 *
 * Skill Management:
 * 5. addSkillCategory(string categoryName): Adds a new skill category. (A)
 * 6. addSkill(uint256 categoryId, string skillName): Adds a new skill under a category. (A)
 * 7. removeSkillCategory(uint256 categoryId): Removes a skill category and associated skills. (A)
 * 8. removeSkill(uint256 skillId): Removes a specific skill. (A)
 * 9. getSkillCategories(): Retrieves all skill categories. (View)
 * 10. getSkillsInCategory(uint256 categoryId): Retrieves skills within a category. (View)
 * 11. declareSkill(uint256 skillId): User declares interest in a skill. (R)
 * 12. getUserDeclaredSkills(address user): Gets skills a user has declared interest in. (View)
 * 13. removeDeclaredSkill(uint256 skillId): User removes a declared skill. (R)
 *
 * Endorsements & Reputation:
 * 14. endorseSkill(address endorsedUser, uint256 skillId): Endorses a user for a declared skill. (R)
 * 15. getSkillEndorsements(address user, uint256 skillId): Gets endorsement count for a user's skill. (View)
 * 16. calculateReputationScore(address user): Calculates a simple reputation score. (View)
 *
 * Skill Proofs (SBT-like):
 * 17. hasSkillToken(address user, uint256 skillId): Checks if a user holds the SBT-like token for a skill. (View)
 * 18. getUserEarnedSkills(address user): Lists skills for which a user has earned a skill token. (View)
 *
 * Project & Bounty Management:
 * 19. createProject(uint256 skillIdRequired, uint256 bountyAmount, string description): Creates a project with a bounty (requires deposit). (R)
 * 20. applyForProject(uint256 projectId): User applies to a project. (R)
 * 21. getProjectDetails(uint256 projectId): Retrieves project details. (View)
 * 22. getProjectsBySkill(uint256 skillId): Retrieves projects requiring a specific skill. (View)
 * 23. getApplicants(uint256 projectId): Retrieves applicants for a project. (View)
 * 24. selectProjectApplicant(uint256 projectId, address applicant): Creator selects an applicant. (C)
 * 25. completeProject(uint256 projectId): Selected applicant marks project as complete. (P)
 * 26. confirmProjectCompletion(uint256 projectId): Creator confirms completion and releases bounty, potentially issuing skill token. (C)
 * 27. rateProjectCompletion(uint256 projectId, uint8 rating): Creator rates the applicant after confirmation. (C)
 * 28. cancelProject(uint256 projectId): Creator cancels the project (refunds bounty). (C)
 * 29. getProjectsByUser(address user, bool isCreator): Gets projects created or applied to by a user. (View)
 * 30. getUserProjectHistory(address user): Gets all project IDs associated with a user. (View)
 *
 * Internal Balance Management:
 * 31. withdrawEarnedBounty(uint256 amount): User withdraws earned bounty funds. (R)
 * 32. getUserBalance(address user): Gets the internal balance of a user. (View)
 *
 * Admin Controls:
 * 33. setAdmin(address admin, bool isAdmin): Grants or revokes admin role. (O)
 */
```

**Smart Contract Code**

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract DecentralizedSkillShare {

    address public owner;
    mapping(address => bool) public admins;

    uint256 public nextSkillCategoryId;
    uint256 public nextSkillId;
    uint256 public nextProjectId;

    enum ProjectState {
        Open,         // Project is listed, accepting applications
        Applied,      // At least one applicant, creator needs to select
        Selected,     // Applicant selected, project is In Progress
        Completed,    // Applicant claims completion
        Confirmed,    // Creator confirms completion, bounty paid, skill token issued
        Cancelled     // Project cancelled by creator, bounty refunded
    }

    struct UserProfile {
        string name;
        string bio;
        bool isRegistered;
        uint256 reputation; // Simple score based on endorsements + projects
        address[] projectsCreated;
        address[] projectsApplied;
    }

    struct SkillCategory {
        string name;
        uint256[] skillIds;
        bool exists;
    }

    struct Skill {
        uint256 categoryId;
        string name;
        bool exists;
    }

    struct Project {
        uint256 skillIdRequired;
        uint256 bountyAmount; // Amount in native token (wei) held by the contract
        address creator;
        string description;
        ProjectState state;
        address[] applicants;
        address selectedApplicant;
        uint256 creationTime;
        uint8 rating; // 0 if not rated, 1-5 otherwise
    }

    mapping(address => UserProfile) public userProfiles;
    mapping(uint256 => SkillCategory) public skillCategories;
    mapping(uint256 => Skill) public skills;
    mapping(uint256 => Project) public projects;

    // User declared skills (skills they are interested in or claim to have)
    mapping(address => mapping(uint256 => bool)) public userDeclaredSkills;
    mapping(address => uint256[] as declaredSkillIds)) public getUserDeclaredSkillIds; // Helper to list declared skills

    // Skill Endorsements: user => skillId => endorser => bool
    mapping(address => mapping(uint256 => mapping(address => bool))) private skillEndorsements;
    // Skill Endorsement Count: user => skillId => count
    mapping(address => mapping(uint256 => uint256)) public userSkillEndorsementCount;

    // Soulbound Token (SBT)-like Skill Proofs: user => skillId => bool
    // Represents a verified skill earned through projects/endorsements
    mapping(address => mapping(uint256 => bool)) public userSkillTokens;
    mapping(address => uint256[] as earnedSkillTokenIds)) public getUserEarnedSkillTokenIds; // Helper to list earned skill tokens

    // Internal balance mapping for bounty funds held by the contract for each user
    mapping(address => uint256) private userBalances;

    // Events
    event UserRegistered(address indexed user, string name);
    event ProfileUpdated(address indexed user, string name, string bio);
    event SkillCategoryAdded(uint256 indexed categoryId, string name);
    event SkillAdded(uint256 indexed skillId, uint256 indexed categoryId, string name);
    event SkillCategoryRemoved(uint256 indexed categoryId);
    event SkillRemoved(uint256 indexed skillId);
    event SkillDeclared(address indexed user, uint256 indexed skillId);
    event SkillDeclarationRemoved(address indexed user, uint256 indexed skillId);
    event SkillEndorsed(address indexed endorser, address indexed endorsedUser, uint256 indexed skillId);
    event SkillTokenIssued(address indexed user, uint256 indexed skillId);
    event ProjectCreated(uint256 indexed projectId, address indexed creator, uint256 skillIdRequired, uint256 bountyAmount);
    event ProjectApplied(uint256 indexed projectId, address indexed applicant);
    event ProjectApplicantSelected(uint256 indexed projectId, address indexed selectedApplicant);
    event ProjectCompleted(uint256 indexed projectId, address indexed applicant);
    event ProjectConfirmed(uint256 indexed projectId, address indexed creator, address indexed applicant);
    event ProjectRated(uint256 indexed projectId, address indexed creator, address indexed applicant, uint8 rating);
    event ProjectCancelled(uint256 indexed projectId, address indexed creator);
    event FundsDeposited(address indexed user, uint256 amount); // Not used directly in project creation deposit flow, but good practice
    event FundsWithdrawn(address indexed user, uint256 amount);
    event BountyPaid(uint256 indexed projectId, address indexed recipient, uint255 amount);
    event AdminSet(address indexed admin, bool status);


    // Modifiers
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }

    modifier onlyAdmin() {
        require(admins[msg.sender] || msg.sender == owner, "Only admin or owner can call this function");
        _;
    }

    modifier isRegisteredUser() {
        require(userProfiles[msg.sender].isRegistered, "User not registered");
        _;
    }

    modifier onlyProjectCreator(uint256 _projectId) {
        require(projects[_projectId].creator == msg.sender, "Only project creator can call this function");
        _;
    }

    modifier onlySelectedApplicant(uint256 _projectId) {
        require(projects[_projectId].selectedApplicant == msg.sender, "Only selected applicant can call this function");
        _;
    }

    // Constructor
    constructor() {
        owner = msg.sender;
        admins[msg.sender] = true; // Owner is also an admin by default
        nextSkillCategoryId = 1;
        nextSkillId = 1;
        nextProjectId = 1;
    }

    // --- Admin Functions ---

    /**
     * @dev Sets or removes an admin role.
     * @param _admin The address to set or remove the admin role for.
     * @param _status True to set as admin, false to remove.
     */
    function setAdmin(address _admin, bool _status) external onlyOwner {
        admins[_admin] = _status;
        emit AdminSet(_admin, _status);
    }

    /**
     * @dev Adds a new skill category.
     * @param _categoryName The name of the skill category.
     */
    function addSkillCategory(string memory _categoryName) external onlyAdmin {
        require(bytes(_categoryName).length > 0, "Category name cannot be empty");
        uint256 categoryId = nextSkillCategoryId++;
        skillCategories[categoryId] = SkillCategory({
            name: _categoryName,
            skillIds: new uint256[](0),
            exists: true
        });
        emit SkillCategoryAdded(categoryId, _categoryName);
    }

    /**
     * @dev Adds a new skill under an existing category.
     * @param _categoryId The ID of the category to add the skill to.
     * @param _skillName The name of the skill.
     */
    function addSkill(uint256 _categoryId, string memory _skillName) external onlyAdmin {
        require(skillCategories[_categoryId].exists, "Category does not exist");
        require(bytes(_skillName).length > 0, "Skill name cannot be empty");

        uint256 skillId = nextSkillId++;
        skills[skillId] = Skill({
            categoryId: _categoryId,
            name: _skillName,
            exists: true
        });
        skillCategories[_categoryId].skillIds.push(skillId);
        emit SkillAdded(skillId, _categoryId, _skillName);
    }

    /**
     * @dev Removes a skill category and implicitly makes associated skills inactive.
     *      Does not delete user declared skills or earned skill tokens.
     * @param _categoryId The ID of the category to remove.
     */
    function removeSkillCategory(uint256 _categoryId) external onlyAdmin {
        require(skillCategories[_categoryId].exists, "Category does not exist");
        skillCategories[_categoryId].exists = false; // Mark as inactive
         // Note: Skills under this category are still in the `skills` mapping but can be filtered by checking if skill exists or category exists
        emit SkillCategoryRemoved(_categoryId);
    }

     /**
     * @dev Removes a specific skill.
     *      Does not delete user declared skills or earned skill tokens.
     * @param _skillId The ID of the skill to remove.
     */
    function removeSkill(uint256 _skillId) external onlyAdmin {
        require(skills[_skillId].exists, "Skill does not exist");
        skills[_skillId].exists = false; // Mark as inactive
        // Removing from category's skillIds array is complex and gas-intensive,
        // better to filter on retrieval or mark as inactive. We mark as inactive.
        emit SkillRemoved(_skillId);
    }

    // --- User Management ---

    /**
     * @dev Registers a new user profile.
     * @param _name The name of the user.
     */
    function registerUser(string memory _name) external {
        require(!userProfiles[msg.sender].isRegistered, "User already registered");
        require(bytes(_name).length > 0, "Name cannot be empty");

        userProfiles[msg.sender] = UserProfile({
            name: _name,
            bio: "",
            isRegistered: true,
            reputation: 0,
            projectsCreated: new address[](0), // Placeholder, need project IDs
            projectsApplied: new address[](0) // Placeholder, need project IDs
        });

        // Initialize declared and earned skill ID arrays
        delete getUserDeclaredSkillIds[msg.sender];
        delete getUserEarnedSkillTokenIds[msg.sender];


        emit UserRegistered(msg.sender, _name);
    }

    /**
     * @dev Updates the user's profile information.
     * @param _name The new name for the profile.
     * @param _bio The new bio for the profile.
     */
    function updateProfile(string memory _name, string memory _bio) external isRegisteredUser {
        userProfiles[msg.sender].name = _name;
        userProfiles[msg.sender].bio = _bio;
        emit ProfileUpdated(msg.sender, _name, _bio);
    }

    /**
     * @dev Retrieves a user's profile information.
     * @param _user The address of the user.
     * @return name, bio, isRegistered, reputation, projectsCreatedCount, projectsAppliedCount.
     */
    function getUserProfile(address _user) external view returns (string memory name, string memory bio, bool isRegistered, uint256 reputation, uint256 projectsCreatedCount, uint256 projectsAppliedCount) {
        UserProfile storage profile = userProfiles[_user];
        return (
            profile.name,
            profile.bio,
            profile.isRegistered,
            profile.reputation,
            profile.projectsCreated.length, // Note: This returns length, not IDs directly
            profile.projectsApplied.length // Note: This returns length, not IDs directly
        );
    }

     /**
     * @dev Checks if an address is a registered user.
     * @param _user The address to check.
     * @return True if registered, false otherwise.
     */
    function isUserRegistered(address _user) external view returns (bool) {
        return userProfiles[_user].isRegistered;
    }

    // --- User Skill Declaration ---

    /**
     * @dev User declares their interest in or claim of having a specific skill.
     * @param _skillId The ID of the skill.
     */
    function declareSkill(uint256 _skillId) external isRegisteredUser {
        require(skills[_skillId].exists, "Skill does not exist");
        require(!userDeclaredSkills[msg.sender][_skillId], "Skill already declared");

        userDeclaredSkills[msg.sender][_skillId] = true;
        getUserDeclaredSkillIds[msg.sender].push(_skillId);
        emit SkillDeclared(msg.sender, _skillId);
    }

    /**
     * @dev User removes a skill they previously declared.
     * @param _skillId The ID of the skill.
     */
    function removeDeclaredSkill(uint256 _skillId) external isRegisteredUser {
        require(skills[_skillId].exists, "Skill does not exist");
        require(userDeclaredSkills[msg.sender][_skillId], "Skill not declared by user");

        userDeclaredSkills[msg.sender][_skillId] = false;

        // Remove from dynamic array (potentially gas-intensive for large arrays)
        uint256[] storage declaredIds = getUserDeclaredSkillIds[msg.sender];
        for (uint i = 0; i < declaredIds.length; i++) {
            if (declaredIds[i] == _skillId) {
                declaredIds[i] = declaredIds[declaredIds.length - 1];
                declaredIds.pop();
                break; // Found and removed
            }
        }

        emit SkillDeclarationRemoved(msg.sender, _skillId);
    }

     /**
     * @dev Gets the list of skill IDs a user has declared interest in.
     * @param _user The address of the user.
     * @return An array of skill IDs.
     */
    function getUserDeclaredSkills(address _user) external view returns (uint256[] memory) {
        return getUserDeclaredSkillIds[_user];
    }

    // --- Skill Endorsements ---

    /**
     * @dev Endorses a user for a specific skill they have declared.
     * @param _endorsedUser The address of the user being endorsed.
     * @param _skillId The ID of the skill being endorsed.
     */
    function endorseSkill(address _endorsedUser, uint256 _skillId) external isRegisteredUser {
        require(msg.sender != _endorsedUser, "Cannot endorse yourself");
        require(userProfiles[_endorsedUser].isRegistered, "Endorsed user not registered");
        require(userDeclaredSkills[_endorsedUser][_skillId], "Endorsed user has not declared this skill");
        require(!skillEndorsements[_endorsedUser][_skillId][msg.sender], "Already endorsed this skill by this user");

        skillEndorsements[_endorsedUser][_skillId][msg.sender] = true;
        userSkillEndorsementCount[_endorsedUser][_skillId]++;
        _updateReputation(_endorsedUser, 1); // Increase reputation by 1 for each unique endorsement
        emit SkillEndorsed(msg.sender, _endorsedUser, _skillId);
    }

     /**
     * @dev Gets the number of endorsements a user has for a specific skill.
     * @param _user The address of the user.
     * @param _skillId The ID of the skill.
     * @return The number of endorsements.
     */
    function getSkillEndorsements(address _user, uint256 _skillId) external view returns (uint256) {
        return userSkillEndorsementCount[_user][_skillId];
    }

    /**
     * @dev Calculates a simple reputation score for a user.
     *      Currently based on total endorsement count + (successful project count * 5)
     * @param _user The address of the user.
     * @return The calculated reputation score.
     */
    function calculateReputationScore(address _user) external view returns (uint256) {
        require(userProfiles[_user].isRegistered, "User not registered");
        // Reputation is updated internally, this is just a getter
        return userProfiles[_user].reputation;
    }

    // --- Skill Proofs (SBT-like) ---

    /**
     * @dev Checks if a user holds the SBT-like token for a specific skill.
     *      This token is earned, not transferred.
     * @param _user The address of the user.
     * @param _skillId The ID of the skill.
     * @return True if the user has earned the skill token, false otherwise.
     */
    function hasSkillToken(address _user, uint256 _skillId) external view returns (bool) {
        return userSkillTokens[_user][_skillId];
    }

     /**
     * @dev Gets the list of skill IDs for which a user has earned an SBT-like token.
     * @param _user The address of the user.
     * @return An array of skill IDs.
     */
    function getUserEarnedSkills(address _user) external view returns (uint256[] memory) {
        return getUserEarnedSkillTokenIds[_user];
    }

    /**
     * @dev Internal function to issue a non-transferable skill token (SBT-like).
     *      This is typically called after successful project completion or reaching endorsement threshold.
     * @param _user The user to issue the token to.
     * @param _skillId The skill ID for the token.
     */
    function _issueSkillToken(address _user, uint256 _skillId) internal {
        if (!userSkillTokens[_user][_skillId]) {
            userSkillTokens[_user][_skillId] = true;
            getUserEarnedSkillTokenIds[_user].push(_skillId);
            emit SkillTokenIssued(_user, _skillId);
        }
    }

    // --- Project & Bounty Management ---

    /**
     * @dev Creates a new project requiring a specific skill and deposits the bounty.
     * @param _skillIdRequired The ID of the skill required for the project.
     * @param _bountyAmount The amount of native token (wei) offered as bounty.
     * @param _description A description of the project.
     */
    function createProject(uint256 _skillIdRequired, uint256 _bountyAmount, string memory _description) external payable isRegisteredUser {
        require(skills[_skillIdRequired].exists, "Required skill does not exist");
        require(_bountyAmount > 0, "Bounty amount must be greater than zero");
        require(msg.value == _bountyAmount, "Sent amount must match bounty amount");
        require(bytes(_description).length > 0, "Description cannot be empty");

        uint256 projectId = nextProjectId++;
        projects[projectId] = Project({
            skillIdRequired: _skillIdRequired,
            bountyAmount: _bountyAmount,
            creator: msg.sender,
            description: _description,
            state: ProjectState.Open,
            applicants: new address[](0),
            selectedApplicant: address(0),
            creationTime: block.timestamp,
            rating: 0
        });

        userProfiles[msg.sender].projectsCreated.push(address(uint160(projectId))); // Store as address for simplicity, cast back later

        emit ProjectCreated(projectId, msg.sender, _skillIdRequired, _bountyAmount);
    }


    /**
     * @dev Allows a registered user to apply for an open project.
     * @param _projectId The ID of the project to apply for.
     */
    function applyForProject(uint256 _projectId) external isRegisteredUser {
        Project storage project = projects[_projectId];
        require(project.creator != address(0), "Project does not exist");
        require(project.state == ProjectState.Open, "Project is not open for applications");
        require(project.creator != msg.sender, "Cannot apply to your own project");

        // Check if already applied (simple check)
        bool alreadyApplied = false;
        for (uint i = 0; i < project.applicants.length; i++) {
            if (project.applicants[i] == msg.sender) {
                alreadyApplied = true;
                break;
            }
        }
        require(!alreadyApplied, "Already applied for this project");

        project.applicants.push(msg.sender);
        userProfiles[msg.sender].projectsApplied.push(address(uint160(_projectId))); // Store as address
        project.state = ProjectState.Applied; // Move to Applied state after first applicant

        emit ProjectApplied(_projectId, msg.sender);
    }

    /**
     * @dev Project creator selects an applicant to work on the project.
     * @param _projectId The ID of the project.
     * @param _applicant The address of the applicant to select.
     */
    function selectProjectApplicant(uint256 _projectId, address _applicant) external onlyProjectCreator(_projectId) {
        Project storage project = projects[_projectId];
        require(project.state == ProjectState.Open || project.state == ProjectState.Applied, "Project not in applicable state");

        bool isApplicant = false;
        for (uint i = 0; i < project.applicants.length; i++) {
            if (project.applicants[i] == _applicant) {
                isApplicant = true;
                break;
            }
        }
        require(isApplicant, "Address is not an applicant for this project");

        project.selectedApplicant = _applicant;
        project.state = ProjectState.Selected;

        // Clear other applicants? Or leave them? Leaving them is simpler.

        emit ProjectApplicantSelected(_projectId, _applicant);
    }

    /**
     * @dev Selected applicant marks the project as completed.
     * @param _projectId The ID of the project.
     */
    function completeProject(uint256 _projectId) external onlySelectedApplicant(_projectId) {
        Project storage project = projects[_projectId];
        require(project.state == ProjectState.Selected, "Project is not in 'Selected' state");

        project.state = ProjectState.Completed;
        emit ProjectCompleted(_projectId, msg.sender);
    }

    /**
     * @dev Project creator confirms the project completion and releases the bounty.
     *      Issues the skill token to the applicant upon confirmation.
     * @param _projectId The ID of the project.
     */
    function confirmProjectCompletion(uint256 _projectId) external onlyProjectCreator(_projectId) {
        Project storage project = projects[_projectId];
        require(project.state == ProjectState.Completed, "Project is not in 'Completed' state");
        require(project.selectedApplicant != address(0), "No applicant was selected for this project");

        // Transfer bounty to the selected applicant's internal balance
        _transferInternal(address(this), project.selectedApplicant, project.bountyAmount);
        project.state = ProjectState.Confirmed;

        // Issue SBT-like skill token to the applicant
        _issueSkillToken(project.selectedApplicant, project.skillIdRequired);

        // Increase applicant reputation for successful project
        _updateReputation(project.selectedApplicant, 5); // Increase by 5 for project completion

        emit ProjectConfirmed(_projectId, msg.sender, project.selectedApplicant);
        emit BountyPaid(_projectId, project.selectedApplicant, project.bountyAmount);
    }

     /**
     * @dev Project creator rates the selected applicant after confirming completion.
     * @param _projectId The ID of the project.
     * @param _rating The rating (1-5).
     */
    function rateProjectCompletion(uint256 _projectId, uint8 _rating) external onlyProjectCreator(_projectId) {
        Project storage project = projects[_projectId];
        require(project.state == ProjectState.Confirmed, "Project must be confirmed to be rated");
        require(_rating >= 1 && _rating <= 5, "Rating must be between 1 and 5");
        require(project.rating == 0, "Project already rated");

        project.rating = _rating;
        // Future improvement: Incorporate rating into reputation calculation

        emit ProjectRated(_projectId, msg.sender, project.selectedApplicant, _rating);
    }


    /**
     * @dev Project creator cancels the project. Bounty is refunded to the creator.
     *      Allowed only if the project is in Open, Applied, or Selected state.
     * @param _projectId The ID of the project.
     */
    function cancelProject(uint256 _projectId) external onlyProjectCreator(_projectId) {
        Project storage project = projects[_projectId];
        require(
            project.state == ProjectState.Open ||
            project.state == ProjectState.Applied ||
            project.state == ProjectState.Selected,
            "Project cannot be cancelled in its current state"
        );

        // Refund bounty to creator's internal balance
        _transferInternal(address(this), project.creator, project.bountyAmount);
        project.state = ProjectState.Cancelled;

        // Clean up applicant's applied list? Too complex, leave as is. Filter on frontend.

        emit ProjectCancelled(_projectId, msg.sender);
        emit FundsDeposited(project.creator, project.bountyAmount); // Refund treated as deposit to creator's balance
    }

    /**
     * @dev Retrieves details for a specific project.
     * @param _projectId The ID of the project.
     * @return skillIdRequired, bountyAmount, creator, description, state, selectedApplicant, rating.
     */
    function getProjectDetails(uint256 _projectId) external view returns (uint256 skillIdRequired, uint256 bountyAmount, address creator, string memory description, ProjectState state, address selectedApplicant, uint8 rating) {
        Project storage project = projects[_projectId];
        require(project.creator != address(0), "Project does not exist"); // Check if struct is initialized
        return (
            project.skillIdRequired,
            project.bountyAmount,
            project.creator,
            project.description,
            project.state,
            project.selectedApplicant,
            project.rating
        );
    }

     /**
     * @dev Retrieves a list of project IDs requiring a specific skill.
     *      Note: This requires iterating, potentially gas-intensive for many projects.
     *      A more efficient approach might involve a mapping skillId => projectIds[].
     *      For simplicity in this example, we iterate.
     * @param _skillId The ID of the skill.
     * @return An array of project IDs.
     */
    function getProjectsBySkill(uint256 _skillId) external view returns (uint256[] memory) {
        // This is a simple iteration. For production, consider index mapping.
        uint256[] memory projectIds = new uint256[](nextProjectId - 1);
        uint256 count = 0;
        for (uint256 i = 1; i < nextProjectId; i++) {
            if (projects[i].creator != address(0) && // Check if project exists
                projects[i].skillIdRequired == _skillId &&
                (projects[i].state == ProjectState.Open || projects[i].state == ProjectState.Applied) // Only show open/applied projects
            ) {
                 projectIds[count] = i;
                 count++;
            }
        }
        // Trim array
        uint256[] memory result = new uint256[](count);
        for (uint i = 0; i < count; i++) {
            result[i] = projectIds[i];
        }
        return result;
    }


    /**
     * @dev Retrieves the list of applicants for a specific project.
     * @param _projectId The ID of the project.
     * @return An array of applicant addresses.
     */
    function getApplicants(uint256 _projectId) external view returns (address[] memory) {
        require(projects[_projectId].creator != address(0), "Project does not exist");
        return projects[_projectId].applicants;
    }

    /**
     * @dev Gets project IDs created by or applied to by a specific user.
     * @param _user The address of the user.
     * @param _isCreator True to get projects created, False to get projects applied.
     * @return An array of project IDs (represented as addresses).
     */
    function getProjectsByUser(address _user, bool _isCreator) external view returns (address[] memory) {
        require(userProfiles[_user].isRegistered, "User not registered");
        if (_isCreator) {
             return userProfiles[_user].projectsCreated;
        } else {
             return userProfiles[_user].projectsApplied;
        }
    }

    /**
     * @dev Gets ALL project IDs associated with a user (both created and applied).
     *      Helper function to avoid two separate calls.
     * @param _user The address of the user.
     * @return projectsCreated, projectsApplied arrays (both as addresses).
     */
    function getUserProjectHistory(address _user) external view returns (address[] memory projectsCreated, address[] memory projectsApplied) {
         require(userProfiles[_user].isRegistered, "User not registered");
         return (userProfiles[_user].projectsCreated, userProfiles[_user].projectsApplied);
    }

    // --- Internal Balance Management ---

    /**
     * @dev Internal function to transfer funds within the contract's balance mapping.
     * @param _from The address to transfer from (can be contract address).
     * @param _to The address to transfer to.
     * @param _amount The amount to transfer.
     */
    function _transferInternal(address _from, address _to, uint256 _amount) internal {
        if (_from != address(this)) { // Allow transfers from contract address (for refunds)
             require(userBalances[_from] >= _amount, "Insufficient balance");
             userBalances[_from] -= _amount;
        }
        userBalances[_to] += _amount;
    }

     /**
     * @dev Allows a user to withdraw earned funds from their internal balance.
     * @param _amount The amount to withdraw (in native token, wei).
     */
    function withdrawEarnedBounty(uint256 _amount) external isRegisteredUser {
        require(userBalances[msg.sender] >= _amount, "Insufficient balance");
        require(_amount > 0, "Amount must be greater than zero");

        userBalances[msg.sender] -= _amount;

        (bool success, ) = payable(msg.sender).call{value: _amount}("");
        require(success, "Withdrawal failed");

        emit FundsWithdrawn(msg.sender, _amount);
    }

     /**
     * @dev Gets the internal balance of a user held by the contract.
     * @param _user The address of the user.
     * @return The user's balance in wei.
     */
    function getUserBalance(address _user) external view returns (uint256) {
        return userBalances[_user];
    }

     // --- Reputation Update (Internal) ---
     /**
     * @dev Internal function to update a user's reputation score.
     * @param _user The user whose reputation is being updated.
     * @param _scoreChange The amount to add to the reputation (can be negative, but not used yet).
     */
    function _updateReputation(address _user, int256 _scoreChange) internal {
        // Simple addition for now. Could be weighted, decay over time, etc.
        // Using int256 allows for potential negative changes, though not currently implemented.
        if (_scoreChange > 0) {
             userProfiles[_user].reputation += uint256(_scoreChange);
        }
        // Potential logic for negative: if(userProfiles[_user].reputation >= uint256(-_scoreChange)) { userProfiles[_user].reputation -= uint256(-_scoreChange); }
    }

    // --- Getters for Skills/Categories (Redundant, but fulfilling function count and common pattern) ---

    /**
     * @dev Retrieves all skill categories.
     * @return An array of category IDs.
     */
    function getSkillCategories() external view returns (uint256[] memory) {
        uint256[] memory categoryIds = new uint256[](nextSkillCategoryId - 1);
        uint256 count = 0;
        for(uint256 i = 1; i < nextSkillCategoryId; i++) {
            if (skillCategories[i].exists) {
                categoryIds[count] = i;
                count++;
            }
        }
        uint256[] memory result = new uint256[](count);
        for(uint i = 0; i < count; i++) {
            result[i] = categoryIds[i];
        }
        return result;
    }

    /**
     * @dev Retrieves skills within a specific category.
     * @param _categoryId The ID of the category.
     * @return An array of skill IDs.
     */
    function getSkillsInCategory(uint256 _categoryId) external view returns (uint256[] memory) {
        require(skillCategories[_categoryId].exists, "Category does not exist");
        // Return copy to prevent external modification
        return skillCategories[_categoryId].skillIds;
    }

    // Fallback/Receive functions to accept native token
    receive() external payable {
        // Optional: Emit an event if direct sends are possible and meaningful
        // emit FundsDeposited(msg.sender, msg.value);
    }

    fallback() external payable {
        // Optional: Handle unexpected sends
        // emit FundsDeposited(msg.sender, msg.value);
    }
}
```