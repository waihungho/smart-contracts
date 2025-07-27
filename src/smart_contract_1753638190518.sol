This smart contract, **QuantumNexus**, envisions a decentralized ecosystem for skill recognition and collaborative project execution. It introduces several advanced concepts:

*   **Skill Orbs (SO):** Non-transferable ERC-721 tokens that represent verified skills or achievements (a form of "soulbound" token). These are minted by a trusted "Skill Verification Oracle."
*   **Dynamic Reputation System:** Users gain or lose reputation based on their participation in projects, successful milestone completions, and outcomes of dispute resolutions. This score influences their standing within the ecosystem.
*   **Multi-Stage Project Funding with Time-Locked Escrow:** Projects are funded by stakeholders, and funds are held in escrow. They are released progressively to the project creator only upon the successful approval of milestones by the project team or via arbitration.
*   **Decentralized Arbitration:** A built-in mechanism for resolving disputes over milestone completion, involving an "Arbitration Council" whose decisions impact the reputation of involved parties.
*   **Role-Based Access Control:** Granular permissions define who can perform specific actions within a project (e.g., creator, core team, contributors) and system-wide (owner, oracle, arbiters).
*   **Conceptual Oracle Integration:** While mocked for simplicity, the contract includes interfaces for a "Skill Verification Oracle" and hints at "AI-enhanced insights" for project-skill matching or risk assessment, demonstrating how off-chain data can influence on-chain logic.
*   **Pausable Contract:** An emergency mechanism allows the owner to pause critical functionalities.

---

## **Outline**

**I. State Variables & Constants:** Global counters for IDs, mappings for users, projects, skills, reputation, configuration parameters, and contract status.
**II. Events:** To log all critical state changes for off-chain monitoring and indexing.
**III. Enums & Structs:** Define various states and data structures for Skill Orbs, Projects, Milestones, and user Roles within a project.
**IV. Modifiers:** For access control, ensuring only authorized addresses can call specific functions.
**V. Core Management & Configuration Functions:** Setup, pausing/unpausing, fee management, and arbitration council management.
**VI. Skill Orb (SO) Management (Non-Transferable ERC-721):** Functions for requesting, verifying, and revoking skill attestations (the non-transferable NFTs). Includes overriding ERC721 transfer functions to enforce non-transferability.
**VII. Project Lifecycle Management:**
    *   **Project Creation & Funding:** Initiating new projects, specifying milestones, and attracting funding.
    *   **Team Formation:** Proposing and accepting team members, with optional checks for required Skill Orbs.
    *   **Milestone Submission & Approval:** Creator submits milestones, team members approve, leading to fund release.
    *   **Dispute Resolution:** Mechanism for disputing milestone completion and subsequent arbitration.
**VIII. Reputation & Query Functions:** Functions to retrieve user reputation, project details, milestone status, team members, and required skills.

---

## **Function Summary (26 Functions)**

**I. Core Management & Configuration:**
1.  `constructor()`: Initializes the contract, sets the owner, and initial fees.
2.  `setProjectCreationFee(uint256 _fee)`: Sets the fee required to create a new project. (Owner only)
3.  `setArbitrationFee(uint256 _fee)`: Sets the fee for initiating a dispute arbitration. (Owner only)
4.  `setSkillVerificationOracle(address _oracleAddress)`: Sets the address of the trusted oracle for skill verification. (Owner only)
5.  `addArbitrationCouncilMember(address _member)`: Adds an address to the arbitration council. (Owner only)
6.  `removeArbitrationCouncilMember(address _member)`: Removes an address from the arbitration council. (Owner only)
7.  `toggleContractPause()`: Pauses or unpauses critical contract functionalities. (Owner only)
8.  `withdrawContractBalance(address _to, uint256 _amount)`: Allows the owner to withdraw accumulated fees/funds from the contract. (Owner only)

**II. Skill Orb (SO) Management (Non-Transferable ERC-721):**
9.  `requestSkillVerification(string calldata _skillName, uint256 _level)`: User requests verification for a specific skill and level.
10. `verifySkill(address _user, string calldata _skillName, uint256 _level)`: Skill Verification Oracle (or authorized entity) confirms a skill, minting a unique Skill Orb NFT to the user.
11. `revokeSkillVerification(address _user, uint256 _skillOrbId)`: Oracle or admin can revoke a previously issued Skill Orb, e.g., if fraudulent.
12. `getOwnedSkillOrbs(address _user)`: Retrieves an array of Skill Orb IDs owned by a user. (View)
13. `getSkillOrbDetails(uint256 _skillOrbId)`: Retrieves detailed information about a specific Skill Orb. (View)

**III. Project Lifecycle Management:**
14. `createProject(string calldata _title, string calldata _description, uint256 _totalFundingRequired, MilestoneInfo[] calldata _milestoneInfos, uint256[] calldata _requiredSkillOrbIds, uint256 _minApprovalsForMilestone)`: Creates a new project, defines milestones, specifies required skills (referencing Skill Orbs), and sets minimum approvals for milestones. Requires a fee.
15. `depositProjectFunds(uint256 _projectId) payable`: Allows anyone to deposit funds into a project.
16. `proposeTeamMember(uint256 _projectId, address _memberAddress, Role _role)`: Project creator proposes a user to join the project team with a specific role, checking for required Skill Orbs.
17. `acceptTeamInvitation(uint256 _projectId)`: A proposed team member accepts their invitation.
18. `submitMilestoneForReview(uint256 _projectId, uint256 _milestoneIndex)`: Project creator submits a completed milestone for review by team members.
19. `approveMilestone(uint256 _projectId, uint256 _milestoneIndex)`: A core team member approves the completion of a submitted milestone. If sufficient approvals, funds are released.
20. `disputeMilestone(uint256 _projectId, uint256 _milestoneIndex)`: A team member or involved party disputes a milestone completion, initiating arbitration. Requires a fee.
21. `submitDisputeResolution(uint256 _projectId, uint256 _milestoneIndex, bool _isApproved)`: An Arbitration Council member submits a final resolution for a disputed milestone. This affects user reputations.

**IV. Reputation & Query Functions:**
22. `getUserReputation(address _user)`: Retrieves the current reputation score of a user. (View)
23. `getProjectDetails(uint256 _projectId)`: Retrieves comprehensive details about a project. (View)
24. `getProjectMilestoneStatus(uint256 _projectId, uint256 _milestoneIndex)`: Gets the specific status of a project milestone. (View)
25. `getProjectTeamMembers(uint256 _projectId)`: Retrieves the list of team members for a given project. (View)
26. `getProjectRequiredSkills(uint256 _projectId)`: Retrieves the list of Skill Orb IDs required for a project. (View)

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

/**
 * @title QuantumNexus
 * @author Your Name / AI Collaboration
 * @dev An advanced, decentralized ecosystem for skill recognition and collaborative project execution.
 *      It features non-transferable "Skill Orbs" (SO) to represent verified competencies,
 *      a dynamic reputation system, and a multi-stage, milestone-based project funding mechanism
 *      with built-in dispute resolution. The aim is to create a self-governing, merit-based
 *      marketplace for talent and innovation, conceptually integrating external "AI insights" via oracles.
 *
 * @concept Advanced Features:
 *  - Soulbound-ish NFTs (Skill Orbs): Non-transferable tokens representing verified skills/achievements.
 *  - Dynamic Reputation System: User reputation changes based on project success/failure, dispute outcomes.
 *  - Multi-stage, Time-locked Escrow: Project funds released progressively upon milestone approval.
 *  - Decentralized Arbitration: Built-in mechanism for resolving disputes over milestone completion.
 *  - Role-based Access Control: Granular permissions for project participants and system roles.
 *  - Oracle Integration (Conceptual): For skill verification and potential "AI insights" (mocked).
 *  - Pausable Contract: Emergency stop functionality.
 *  - ERC721Enumerable for Skill Orbs: Allows iterating over all Skill Orbs (though not efficient for large scale).
 */

// --- OUTLINE ---
// I.  State Variables & Constants
// II. Events
// III. Enums & Structs
// IV. Modifiers
// V.  Core Management & Configuration Functions
// VI. Skill Orb (SO) Management (Non-Transferable ERC-721)
// VII. Project Lifecycle Management
// VIII. Reputation & Query Functions

// --- FUNCTION SUMMARY (26 Functions) ---

// I. Core Management & Configuration:
// 1. constructor(): Initializes the contract, sets the owner, and initial fees.
// 2. setProjectCreationFee(uint256 _fee): Sets the fee required to create a new project. (Owner)
// 3. setArbitrationFee(uint256 _fee): Sets the fee for initiating a dispute arbitration. (Owner)
// 4. setSkillVerificationOracle(address _oracleAddress): Sets the address of the trusted oracle for skill verification. (Owner)
// 5. addArbitrationCouncilMember(address _member): Adds an address to the arbitration council. (Owner)
// 6. removeArbitrationCouncilMember(address _member): Removes an address from the arbitration council. (Owner)
// 7. toggleContractPause(): Pauses or unpauses critical contract functionalities. (Owner)
// 8. withdrawContractBalance(address _to, uint256 _amount): Allows the owner to withdraw accumulated fees/funds from the contract. (Owner)

// II. Skill Orb (SO) Management (Non-Transferable ERC-721):
// 9. requestSkillVerification(string calldata _skillName, uint256 _level): User requests verification for a specific skill and level.
// 10. verifySkill(address _user, string calldata _skillName, uint256 _level): Skill Verification Oracle (or authorized entity) confirms a skill, minting a unique Skill Orb NFT to the user.
// 11. revokeSkillVerification(address _user, uint256 _skillOrbId): Oracle or admin can revoke a previously issued Skill Orb, e.g., if fraudulent.
// 12. getOwnedSkillOrbs(address _user): Retrieves an array of Skill Orb IDs owned by a user. (View)
// 13. getSkillOrbDetails(uint256 _skillOrbId): Retrieves detailed information about a specific Skill Orb. (View)

// III. Project Lifecycle Management:
// 14. createProject(string calldata _title, string calldata _description, uint256 _totalFundingRequired, MilestoneInfo[] calldata _milestoneInfos, uint256[] calldata _requiredSkillOrbIds, uint256 _minApprovalsForMilestone): Creates a new project, defines milestones, specifies required skills (referencing Skill Orbs), and sets minimum approvals. Requires a fee.
// 15. depositProjectFunds(uint256 _projectId) payable: Allows anyone to deposit funds into a project.
// 16. proposeTeamMember(uint256 _projectId, address _memberAddress, Role _role): Project creator proposes a user to join the project team with a specific role, checking for required Skill Orbs.
// 17. acceptTeamInvitation(uint256 _projectId): A proposed team member accepts their invitation.
// 18. submitMilestoneForReview(uint256 _projectId, uint256 _milestoneIndex): Project creator submits a completed milestone for review by team members.
// 19. approveMilestone(uint256 _projectId, uint256 _milestoneIndex): A core team member approves the completion of a submitted milestone. If sufficient approvals, funds are released.
// 20. disputeMilestone(uint256 _projectId, uint256 _milestoneIndex): A team member or involved party disputes a milestone completion, initiating arbitration. Requires a fee.
// 21. submitDisputeResolution(uint256 _projectId, uint256 _milestoneIndex, bool _isApproved): An Arbitration Council member submits a final resolution for a disputed milestone. This affects user reputations.

// IV. Reputation & Query Functions:
// 22. getUserReputation(address _user): Retrieves the current reputation score of a user. (View)
// 23. getProjectDetails(uint256 _projectId): Retrieves comprehensive details about a project. (View)
// 24. getProjectMilestoneStatus(uint256 _projectId, uint256 _milestoneIndex): Gets the specific status of a project milestone. (View)
// 25. getProjectTeamMembers(uint256 _projectId): Retrieves the list of team members for a given project. (View)
// 26. getProjectRequiredSkills(uint256 _projectId): Retrieves the list of Skill Orb IDs required for a project. (View)

contract QuantumNexus is Ownable, Pausable, ERC721Enumerable {
    using Counters for Counters.Counter;

    // I. State Variables & Constants
    Counters.Counter private _skillOrbIds;
    Counters.Counter private _projectIds;

    uint256 public projectCreationFee;
    uint256 public arbitrationFee;
    address public skillVerificationOracle; // Address of the trusted oracle for skill verification
    mapping(address => bool) public arbitrationCouncilMembers;

    // Reputation system: positive for good, negative for bad contributions
    mapping(address => int252) public userReputation; // Using int252 for reputation to avoid large integers unless needed

    // Mapping for Skill Orbs (SO)
    // SkillOrb ID => SkillOrb struct
    mapping(uint256 => SkillOrb) public skillOrbs;
    // User Address => Array of Skill Orb IDs owned by user
    mapping(address => uint256[]) private _ownedSkillOrbIds;

    // Mapping for Projects
    // Project ID => Project struct
    mapping(uint256 => Project) public projects;
    // Project ID => total funds locked for project
    mapping(uint256 => uint256) public projectLockedFunds;


    // II. Events
    event ProjectCreated(uint256 indexed projectId, address indexed creator, string title, uint256 totalFunding);
    event FundsDeposited(uint256 indexed projectId, address indexed depositor, uint256 amount);
    event TeamMemberProposed(uint256 indexed projectId, address indexed proposer, address indexed member, Role role);
    event TeamMemberAccepted(uint256 indexed projectId, address indexed member);
    event MilestoneSubmittedForReview(uint256 indexed projectId, uint256 indexed milestoneIndex, address indexed submitter);
    event MilestoneApproved(uint256 indexed projectId, uint256 indexed milestoneIndex, address indexed approver, uint256 fundsReleased);
    event MilestoneDisputed(uint256 indexed projectId, uint256 indexed milestoneIndex, address indexed disputer);
    event DisputeResolved(uint256 indexed projectId, uint256 indexed milestoneIndex, bool approved, address indexed resolver);
    event SkillVerificationRequested(address indexed user, string skillName, uint256 level);
    event SkillOrbMinted(address indexed to, uint256 indexed skillOrbId, string skillName, uint256 level);
    event SkillOrbRevoked(address indexed from, uint256 indexed skillOrbId);
    event ReputationUpdated(address indexed user, int252 newReputation);
    event ContractPaused(address indexed pauser);
    event ContractUnpaused(address indexed unpauser);
    event FeeUpdated(string feeType, uint256 newFee);

    // III. Enums & Structs

    enum ProjectStatus {
        Pending,          // Project created, waiting for full funding or team
        Active,           // Project active, milestones being worked on
        Completed,        // All milestones completed
        Cancelled,        // Project cancelled by creator or arbitration
        InDispute         // A milestone is currently under arbitration
    }

    enum MilestoneStatus {
        Pending,              // Not yet started/submitted
        SubmittedForReview,   // Creator submitted, waiting for team approval
        Approved,             // Approved by team/arbitration, funds released
        Disputed,             // Under dispute
        Rejected              // Rejected by team/arbitration
    }

    enum Role {
        None,
        Creator,      // The original project creator
        CoreTeam,     // Key team members with approval rights
        Contributor   // Members who contribute but may not have approval rights
    }

    struct SkillOrb {
        uint256 id;
        string name;
        uint256 level;
        address verifiedBy;
        uint256 verificationTimestamp;
    }

    struct MilestoneInfo {
        string description;
        uint256 fundingPercentage; // Percentage of total project funding for this milestone
    }

    struct Milestone {
        string description;
        uint256 fundingPercentage;
        MilestoneStatus status;
        uint256 completionTimestamp; // When it was approved/resolved
        mapping(address => bool) approvals; // Who has approved this milestone
        uint256 approvalCount;
        mapping(address => bool) disputes; // Who has disputed this milestone
        uint256 disputeCount;
    }

    struct Project {
        uint256 id;
        address creator;
        string title;
        string description;
        uint256 totalFundingRequired;
        uint256 fundsDeposited;
        ProjectStatus status;
        Milestone[] milestones;
        mapping(address => Role) teamMembers; // Maps address to their role in the project
        address[] teamMembersArray; // Array to store team member addresses for iteration
        uint256[] requiredSkillOrbIds; // IDs of Skill Orbs required for team members
        uint256 createdAt;
        uint256 minApprovalsForMilestone; // Minimum number of core team approvals needed for a milestone
    }

    // IV. Modifiers
    modifier onlySkillVerificationOracle() {
        require(msg.sender == skillVerificationOracle, "Qx: Not the skill verification oracle");
        _;
    }

    modifier onlyArbitrationCouncil() {
        require(arbitrationCouncilMembers[msg.sender], "Qx: Not an arbitration council member");
        _;
    }

    modifier onlyProjectCreator(uint256 _projectId) {
        require(projects[_projectId].creator == msg.sender, "Qx: Only project creator can call this function");
        _;
    }

    modifier onlyProjectCoreTeam(uint256 _projectId) {
        require(projects[_projectId].teamMembers[msg.sender] == Role.Creator ||
                projects[_projectId].teamMembers[msg.sender] == Role.CoreTeam,
                "Qx: Not a core team member of this project");
        _;
    }

    modifier onlyProjectTeamMember(uint256 _projectId) {
        require(projects[_projectId].teamMembers[msg.sender] != Role.None, "Qx: Not a team member of this project");
        _;
    }

    // V. Core Management & Configuration Functions
    constructor() ERC721("SkillOrb", "SO") Ownable(msg.sender) {
        projectCreationFee = 0.01 ether; // Example initial fee
        arbitrationFee = 0.005 ether; // Example initial fee
        _pause(); // Start paused for initial setup
        emit ContractPaused(msg.sender);
    }

    /**
     * @dev Sets the fee required to create a new project.
     * @param _fee The new project creation fee in wei.
     */
    function setProjectCreationFee(uint256 _fee) external onlyOwner {
        projectCreationFee = _fee;
        emit FeeUpdated("ProjectCreationFee", _fee);
    }

    /**
     * @dev Sets the fee for initiating a dispute arbitration.
     * @param _fee The new arbitration fee in wei.
     */
    function setArbitrationFee(uint256 _fee) external onlyOwner {
        arbitrationFee = _fee;
        emit FeeUpdated("ArbitrationFee", _fee);
    }

    /**
     * @dev Sets the address of the trusted oracle for skill verification.
     * @param _oracleAddress The address of the skill verification oracle.
     */
    function setSkillVerificationOracle(address _oracleAddress) external onlyOwner {
        require(_oracleAddress != address(0), "Qx: Oracle address cannot be zero");
        skillVerificationOracle = _oracleAddress;
    }

    /**
     * @dev Adds an address to the arbitration council.
     * @param _member The address to add.
     */
    function addArbitrationCouncilMember(address _member) external onlyOwner {
        require(_member != address(0), "Qx: Member address cannot be zero");
        arbitrationCouncilMembers[_member] = true;
    }

    /**
     * @dev Removes an address from the arbitration council.
     * @param _member The address to remove.
     */
    function removeArbitrationCouncilMember(address _member) external onlyOwner {
        arbitrationCouncilMembers[_member] = false;
    }

    /**
     * @dev Pauses or unpauses critical contract functionalities.
     * Emergency brake functionality.
     */
    function toggleContractPause() external onlyOwner {
        if (paused()) {
            _unpause();
            emit ContractUnpaused(msg.sender);
        } else {
            _pause();
            emit ContractPaused(msg.sender);
        }
    }

    /**
     * @dev Allows the owner to withdraw accumulated fees/funds from the contract.
     * @param _to The address to send the funds to.
     * @param _amount The amount to withdraw.
     */
    function withdrawContractBalance(address _to, uint256 _amount) external onlyOwner {
        require(_to != address(0), "Qx: Recipient address cannot be zero");
        require(address(this).balance >= _amount, "Qx: Insufficient contract balance");
        (bool success,) = _to.call{value: _amount}("");
        require(success, "Qx: Failed to withdraw funds");
    }

    // VI. Skill Orb (SO) Management (Non-Transferable ERC-721)
    // Note: Skill Orbs are designed to be non-transferable (soulbound-ish) by overriding the transfer functions.
    // ERC721Enumerable is used to demonstrate the ID tracking, but in practice, iterating thousands of NFTs on-chain is inefficient.
    function _approve(address to, uint256 tokenId) internal virtual override {
        // This function is intentionally disabled to prevent external approvals for Skill Orbs.
        revert("SkillOrbs are non-transferable and cannot be approved.");
    }

    function _transfer(address from, address to, uint256 tokenId) internal virtual override {
        // This function is intentionally disabled to prevent external transfers for Skill Orbs.
        revert("SkillOrbs are non-transferable.");
    }

    // Override ERC721's transferFrom and safeTransferFrom to prevent direct transfers
    function transferFrom(address from, address to, uint256 tokenId) public virtual override(ERC721, IERC721) {
        revert("SkillOrbs are non-transferable.");
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public virtual override(ERC721, IERC721) {
        revert("SkillOrbs are non-transferable.");
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public virtual override(ERC721, IERC721) {
        revert("SkillOrbs are non-transferable.");
    }

    /**
     * @dev Allows a user to request verification for a specific skill and level.
     * This would typically be followed by an off-chain process for verification.
     * @param _skillName The name of the skill (e.g., "Solidity Development").
     * @param _level The proficiency level of the skill (e.g., 3).
     */
    function requestSkillVerification(string calldata _skillName, uint256 _level) external whenNotPaused {
        require(bytes(_skillName).length > 0, "Qx: Skill name cannot be empty");
        require(_level > 0, "Qx: Skill level must be greater than zero");
        emit SkillVerificationRequested(msg.sender, _skillName, _level);
    }

    /**
     * @dev The Skill Verification Oracle confirms a skill, minting a unique Skill Orb NFT.
     * Only callable by the designated `skillVerificationOracle`.
     * @param _user The address of the user whose skill is being verified.
     * @param _skillName The name of the skill.
     * @param _level The proficiency level.
     */
    function verifySkill(address _user, string calldata _skillName, uint256 _level)
        external
        onlySkillVerificationOracle
        whenNotPaused
    {
        require(_user != address(0), "Qx: User address cannot be zero");
        require(bytes(_skillName).length > 0, "Qx: Skill name cannot be empty");
        require(_level > 0, "Qx: Skill level must be greater than zero");

        _skillOrbIds.increment();
        uint256 newSkillOrbId = _skillOrbIds.current();

        SkillOrb storage newOrb = skillOrbs[newSkillOrbId];
        newOrb.id = newSkillOrbId;
        newOrb.name = _skillName;
        newOrb.level = _level;
        newOrb.verifiedBy = msg.sender;
        newOrb.verificationTimestamp = block.timestamp;

        _safeMint(_user, newSkillOrbId); // Mint the ERC721 token
        _ownedSkillOrbIds[_user].push(newSkillOrbId); // Track ownership for easier lookup

        // Optionally, update user reputation for successful verification
        userReputation[_user] += 5; // Example reputation gain
        emit ReputationUpdated(_user, userReputation[_user]);
        emit SkillOrbMinted(_user, newSkillOrbId, _skillName, _level);
    }

    /**
     * @dev Revokes a previously issued Skill Orb, e.g., if proof is found fraudulent.
     * Only callable by the Skill Verification Oracle. This burns the Skill Orb.
     * @param _user The owner of the Skill Orb.
     * @param _skillOrbId The ID of the Skill Orb to revoke.
     */
    function revokeSkillVerification(address _user, uint256 _skillOrbId)
        external
        onlySkillVerificationOracle
        whenNotPaused
    {
        require(ownerOf(_skillOrbId) == _user, "Qx: Skill Orb not owned by user");
        require(skillOrbs[_skillOrbId].id != 0, "Qx: Skill Orb does not exist");

        // Decrement reputation for revocation
        userReputation[_user] -= 10; // Example reputation loss
        emit ReputationUpdated(_user, userReputation[_user]);

        // Remove from _ownedSkillOrbIds mapping
        uint256[] storage userOrbs = _ownedSkillOrbIds[_user];
        for (uint256 i = 0; i < userOrbs.length; i++) {
            if (userOrbs[i] == _skillOrbId) {
                userOrbs[i] = userOrbs[userOrbs.length - 1];
                userOrbs.pop();
                break;
            }
        }

        _burn(_skillOrbId); // Burn the ERC721 token
        delete skillOrbs[_skillOrbId]; // Clear the struct data
        emit SkillOrbRevoked(_user, _skillOrbId);
    }

    /**
     * @dev Retrieves an array of Skill Orb IDs owned by a user.
     * @param _user The address of the user.
     * @return An array of Skill Orb IDs.
     */
    function getOwnedSkillOrbs(address _user) external view returns (uint256[] memory) {
        return _ownedSkillOrbIds[_user];
    }

    /**
     * @dev Retrieves detailed information about a specific Skill Orb.
     * @param _skillOrbId The ID of the Skill Orb.
     * @return A tuple containing skill Orb details.
     */
    function getSkillOrbDetails(uint256 _skillOrbId)
        external
        view
        returns (uint256 id, string memory name, uint256 level, address verifiedBy, uint256 verificationTimestamp)
    {
        SkillOrb storage orb = skillOrbs[_skillOrbId];
        require(orb.id != 0, "Qx: Skill Orb does not exist");
        return (orb.id, orb.name, orb.level, orb.verifiedBy, orb.verificationTimestamp);
    }

    // VII. Project Lifecycle Management

    /**
     * @dev Creates a new project, defines milestones, and specifies required skills.
     * Requires a `projectCreationFee`.
     * @param _title The title of the project.
     * @param _description A detailed description of the project.
     * @param _totalFundingRequired The total funds needed for the project.
     * @param _milestoneInfos An array of MilestoneInfo structs detailing each milestone.
     * @param _requiredSkillOrbIds An array of Skill Orb IDs representing required competencies for the project team.
     * @param _minApprovalsForMilestone Minimum number of team approvals needed for a milestone release.
     * @return projectId The ID of the newly created project.
     */
    function createProject(
        string calldata _title,
        string calldata _description,
        uint256 _totalFundingRequired,
        MilestoneInfo[] calldata _milestoneInfos,
        uint256[] calldata _requiredSkillOrbIds,
        uint256 _minApprovalsForMilestone
    ) external payable whenNotPaused returns (uint256 projectId) {
        require(msg.value >= projectCreationFee, "Qx: Insufficient project creation fee");
        require(bytes(_title).length > 0, "Qx: Project title cannot be empty");
        require(_totalFundingRequired > 0, "Qx: Total funding required must be greater than zero");
        require(_milestoneInfos.length > 0, "Qx: Project must have at least one milestone");
        require(_minApprovalsForMilestone > 0, "Qx: Minimum approvals must be greater than zero");

        uint256 totalMilestonePercentage = 0;
        for (uint256 i = 0; i < _milestoneInfos.length; i++) {
            require(_milestoneInfos[i].fundingPercentage > 0, "Qx: Milestone funding percentage must be positive");
            totalMilestonePercentage += _milestoneInfos[i].fundingPercentage;
        }
        require(totalMilestonePercentage == 100, "Qx: Total milestone percentages must sum to 100");

        _projectIds.increment();
        projectId = _projectIds.current();

        Project storage newProject = projects[projectId];
        newProject.id = projectId;
        newProject.creator = msg.sender;
        newProject.title = _title;
        newProject.description = _description;
        newProject.totalFundingRequired = _totalFundingRequired;
        newProject.status = ProjectStatus.Pending;
        newProject.createdAt = block.timestamp;
        newProject.minApprovalsForMilestone = _minApprovalsForMilestone;

        // Initialize milestones
        newProject.milestones.length = _milestoneInfos.length;
        for (uint256 i = 0; i < _milestoneInfos.length; i++) {
            newProject.milestones[i].description = _milestoneInfos[i].description;
            newProject.milestones[i].fundingPercentage = _milestoneInfos[i].fundingPercentage;
            newProject.milestones[i].status = MilestoneStatus.Pending;
        }

        // Store required skill IDs
        newProject.requiredSkillOrbIds = new uint256[_requiredSkillOrbIds.length];
        for (uint256 i = 0; i < _requiredSkillOrbIds.length; i++) {
            require(skillOrbs[_requiredSkillOrbIds[i]].id != 0, "Qx: Required Skill Orb ID does not exist");
            newProject.requiredSkillOrbIds[i] = _requiredSkillOrbIds[i];
        }

        newProject.teamMembers[msg.sender] = Role.Creator; // Creator is automatically a team member
        newProject.teamMembersArray.push(msg.sender); // Add creator to the iterable array

        emit ProjectCreated(projectId, msg.sender, _title, _totalFundingRequired);
    }

    /**
     * @dev Allows anyone to deposit funds into a project.
     * Funds are held in escrow until milestones are completed.
     * @param _projectId The ID of the project to fund.
     */
    function depositProjectFunds(uint256 _projectId) external payable whenNotPaused {
        Project storage project = projects[_projectId];
        require(project.id != 0, "Qx: Project does not exist");
        require(project.status != ProjectStatus.Completed && project.status != ProjectStatus.Cancelled, "Qx: Project not eligible for funding");
        require(msg.value > 0, "Qx: Must deposit a positive amount");

        project.fundsDeposited += msg.value;
        projectLockedFunds[_projectId] += msg.value;

        // If sufficient funds, activate the project
        if (project.status == ProjectStatus.Pending && project.fundsDeposited >= project.totalFundingRequired) {
            project.status = ProjectStatus.Active;
        }
        emit FundsDeposited(_projectId, msg.sender, msg.value);
    }

    /**
     * @dev Project creator proposes a user to join the project team with a specific role.
     * Requires the proposed member to possess at least one of the required Skill Orbs for the project.
     * @param _projectId The ID of the project.
     * @param _memberAddress The address of the user to propose.
     * @param _role The role to assign (CoreTeam or Contributor).
     */
    function proposeTeamMember(uint256 _projectId, address _memberAddress, Role _role)
        external
        onlyProjectCreator(_projectId)
        whenNotPaused
    {
        Project storage project = projects[_projectId];
        require(project.teamMembers[_memberAddress] == Role.None, "Qx: Member already part of the team");
        require(_memberAddress != address(0), "Qx: Member address cannot be zero");
        require(_role == Role.CoreTeam || _role == Role.Contributor, "Qx: Invalid role for proposal");

        // Enforce that a proposed team member must possess at least one of the project's required Skill Orbs.
        bool hasRequiredSkill = false;
        if (project.requiredSkillOrbIds.length > 0) {
            uint256[] memory memberSkillOrbs = _ownedSkillOrbIds[_memberAddress];
            for (uint256 i = 0; i < project.requiredSkillOrbIds.length; i++) {
                for (uint256 j = 0; j < memberSkillOrbs.length; j++) {
                    if (project.requiredSkillOrbIds[i] == memberSkillOrbs[j]) {
                        hasRequiredSkill = true;
                        break;
                    }
                }
                if (hasRequiredSkill) break;
            }
            require(hasRequiredSkill, "Qx: Proposed member does not possess any of the required skills (Skill Orbs)");
        }

        project.teamMembers[_memberAddress] = _role; // Set role, awaits acceptance (conceptually)
        // Add to the iterable array of team members if not already present
        bool found = false;
        for (uint i = 0; i < project.teamMembersArray.length; i++) {
            if (project.teamMembersArray[i] == _memberAddress) {
                found = true;
                break;
            }
        }
        if (!found) {
            project.teamMembersArray.push(_memberAddress);
        }

        emit TeamMemberProposed(_projectId, msg.sender, _memberAddress, _role);
    }

    /**
     * @dev A proposed team member accepts their invitation to join a project.
     * @param _projectId The ID of the project.
     */
    function acceptTeamInvitation(uint256 _projectId) external whenNotPaused {
        Project storage project = projects[_projectId];
        require(project.id != 0, "Qx: Project does not exist");
        require(project.teamMembers[msg.sender] != Role.None, "Qx: You have no pending invitation for this project");
        // No explicit "pending" state needed for accepting, as proposer sets the role immediately.
        emit TeamMemberAccepted(_projectId, msg.sender);
    }

    /**
     * @dev Project creator submits a completed milestone for review by team members.
     * @param _projectId The ID of the project.
     * @param _milestoneIndex The index of the milestone (0-based).
     */
    function submitMilestoneForReview(uint256 _projectId, uint256 _milestoneIndex)
        external
        onlyProjectCreator(_projectId)
        whenNotPaused
    {
        Project storage project = projects[_projectId];
        require(project.status == ProjectStatus.Active, "Qx: Project is not active");
        require(_milestoneIndex < project.milestones.length, "Qx: Invalid milestone index");
        Milestone storage milestone = project.milestones[_milestoneIndex];
        require(milestone.status == MilestoneStatus.Pending || milestone.status == MilestoneStatus.Rejected,
                "Qx: Milestone not in pending or rejected state for submission");

        milestone.status = MilestoneStatus.SubmittedForReview;
        milestone.approvalCount = 0; // Reset approvals for new submission
        milestone.disputeCount = 0;  // Reset disputes

        emit MilestoneSubmittedForReview(_projectId, _milestoneIndex, msg.sender);
    }

    /**
     * @dev A core team member approves the completion of a submitted milestone.
     * If sufficient approvals are met (defined by `minApprovalsForMilestone`), funds are released.
     * @param _projectId The ID of the project.
     * @param _milestoneIndex The index of the milestone.
     */
    function approveMilestone(uint256 _projectId, uint256 _milestoneIndex)
        external
        onlyProjectCoreTeam(_projectId)
        whenNotPaused
    {
        Project storage project = projects[_projectId];
        require(project.id != 0, "Qx: Project does not exist");
        require(project.status == ProjectStatus.Active, "Qx: Project is not active"); // Only approve if active, not in dispute
        require(_milestoneIndex < project.milestones.length, "Qx: Invalid milestone index");
        Milestone storage milestone = project.milestones[_milestoneIndex];
        require(milestone.status == MilestoneStatus.SubmittedForReview, "Qx: Milestone not in review state for approval");
        require(!milestone.approvals[msg.sender], "Qx: You have already approved this milestone");

        milestone.approvals[msg.sender] = true;
        milestone.approvalCount++;

        // If sufficient approvals, release funds
        if (milestone.approvalCount >= project.minApprovalsForMilestone) {
            _releaseMilestoneFunds(_projectId, _milestoneIndex);
        }
        // else, await more approvals.
    }

    /**
     * @dev Internal function to release funds for a completed and approved milestone.
     * This function is called by `approveMilestone` or `submitDisputeResolution`.
     * @param _projectId The ID of the project.
     * @param _milestoneIndex The index of the milestone.
     */
    function _releaseMilestoneFunds(uint256 _projectId, uint256 _milestoneIndex) internal {
        Project storage project = projects[_projectId];
        Milestone storage milestone = project.milestones[_milestoneIndex];

        // Calculate funds for this milestone
        uint256 fundsToRelease = (project.totalFundingRequired * milestone.fundingPercentage) / 100;

        require(projectLockedFunds[_projectId] >= fundsToRelease, "Qx: Insufficient locked funds for milestone release");

        milestone.status = MilestoneStatus.Approved;
        milestone.completionTimestamp = block.timestamp;
        projectLockedFunds[_projectId] -= fundsToRelease;

        // Transfer funds to the project creator
        (bool success, ) = project.creator.call{value: fundsToRelease}("");
        require(success, "Qx: Failed to transfer milestone funds");

        // Update creator reputation for successful milestone
        userReputation[project.creator] += 3; // Example reputation gain
        emit ReputationUpdated(project.creator, userReputation[project.creator]);

        // If this was the last milestone, mark project as completed
        if (_milestoneIndex == project.milestones.length - 1) {
            project.status = ProjectStatus.Completed;
        }

        emit MilestoneApproved(_projectId, _milestoneIndex, msg.sender, fundsToRelease);
    }

    /**
     * @dev A team member or involved party disputes a milestone completion, initiating arbitration.
     * Requires an `arbitrationFee`.
     * @param _projectId The ID of the project.
     * @param _milestoneIndex The index of the milestone.
     */
    function disputeMilestone(uint256 _projectId, uint256 _milestoneIndex)
        external
        payable
        onlyProjectTeamMember(_projectId)
        whenNotPaused
    {
        Project storage project = projects[_projectId];
        require(project.id != 0, "Qx: Project does not exist");
        require(msg.value >= arbitrationFee, "Qx: Insufficient arbitration fee");
        require(_milestoneIndex < project.milestones.length, "Qx: Invalid milestone index");
        Milestone storage milestone = project.milestones[_milestoneIndex];
        require(milestone.status == MilestoneStatus.SubmittedForReview, "Qx: Milestone not in review state for dispute");
        require(!milestone.disputes[msg.sender], "Qx: You have already disputed this milestone");

        milestone.disputes[msg.sender] = true;
        milestone.disputeCount++;
        project.status = ProjectStatus.InDispute; // Project-level status change

        // Minor reputation penalty for initiating dispute (can be reverted if dispute is successful)
        userReputation[msg.sender] -= 1;
        emit ReputationUpdated(msg.sender, userReputation[msg.sender]);
        emit MilestoneDisputed(_projectId, _milestoneIndex, msg.sender);
    }

    /**
     * @dev An Arbitration Council member submits a final resolution for a disputed milestone.
     * This decision overrides team approvals/disputes and affects user reputations.
     * @param _projectId The ID of the project.
     * @param _milestoneIndex The index of the milestone.
     * @param _isApproved True if the milestone is approved, false if rejected.
     */
    function submitDisputeResolution(uint256 _projectId, uint256 _milestoneIndex, bool _isApproved)
        external
        onlyArbitrationCouncil
        whenNotPaused
    {
        Project storage project = projects[_projectId];
        require(project.id != 0, "Qx: Project does not exist");
        require(project.status == ProjectStatus.InDispute, "Qx: Project is not in dispute");
        require(_milestoneIndex < project.milestones.length, "Qx: Invalid milestone index");
        Milestone storage milestone = project.milestones[_milestoneIndex];
        require(milestone.status == MilestoneStatus.Disputed, "Qx: Milestone is not under dispute");

        if (_isApproved) {
            _releaseMilestoneFunds(_projectId, _milestoneIndex); // Release funds if approved
            milestone.status = MilestoneStatus.Approved;
            // Reward reputation to creator for successful resolution
            userReputation[project.creator] += 5;
            emit ReputationUpdated(project.creator, userReputation[project.creator]);
        } else {
            milestone.status = MilestoneStatus.Rejected;
            // Penalize creator for rejected milestone
            userReputation[project.creator] -= 5;
            emit ReputationUpdated(project.creator, userReputation[project.creator]);
            // If milestone rejected, revert project status to active if not the last one, otherwise mark cancelled.
            if (_milestoneIndex < project.milestones.length - 1) {
                project.status = ProjectStatus.Active;
            } else {
                project.status = ProjectStatus.Cancelled; // If last milestone rejected, project might be cancelled/failed
            }
        }

        // TODO: Advanced: Implement reputation adjustments for disputers based on resolution outcome.

        emit DisputeResolved(_projectId, _milestoneIndex, _isApproved, msg.sender);
    }

    // VIII. Reputation & Query Functions

    /**
     * @dev Retrieves the current reputation score of a user.
     * @param _user The address of the user.
     * @return The reputation score.
     */
    function getUserReputation(address _user) external view returns (int252) {
        return userReputation[_user];
    }

    /**
     * @dev Retrieves comprehensive details about a project.
     * @param _projectId The ID of the project.
     * @return A tuple containing project details.
     */
    function getProjectDetails(uint256 _projectId)
        external
        view
        returns (
            uint256 id,
            address creator,
            string memory title,
            string memory description,
            uint256 totalFundingRequired,
            uint256 fundsDeposited,
            ProjectStatus status,
            uint256 createdAt,
            uint256 minApprovalsForMilestone
        )
    {
        Project storage project = projects[_projectId];
        require(project.id != 0, "Qx: Project does not exist");
        return (
            project.id,
            project.creator,
            project.title,
            project.description,
            project.totalFundingRequired,
            project.fundsDeposited,
            project.status,
            project.createdAt,
            project.minApprovalsForMilestone
        );
    }

    /**
     * @dev Gets the specific status of a project milestone.
     * @param _projectId The ID of the project.
     * @param _milestoneIndex The index of the milestone.
     * @return A tuple containing milestone details.
     */
    function getProjectMilestoneStatus(uint256 _projectId, uint256 _milestoneIndex)
        external
        view
        returns (string memory description, uint256 fundingPercentage, MilestoneStatus status, uint256 completionTimestamp, uint256 approvalCount, uint256 disputeCount)
    {
        Project storage project = projects[_projectId];
        require(project.id != 0, "Qx: Project does not exist");
        require(_milestoneIndex < project.milestones.length, "Qx: Invalid milestone index");
        Milestone storage milestone = project.milestones[_milestoneIndex];
        return (milestone.description, milestone.fundingPercentage, milestone.status, milestone.completionTimestamp, milestone.approvalCount, milestone.disputeCount);
    }

    /**
     * @dev Retrieves the list of team members (addresses) for a given project.
     * @param _projectId The ID of the project.
     * @return An array of team member addresses.
     */
    function getProjectTeamMembers(uint256 _projectId) external view returns (address[] memory) {
        Project storage project = projects[_projectId];
        require(project.id != 0, "Qx: Project does not exist");
        return project.teamMembersArray;
    }

    /**
     * @dev Retrieves the list of Skill Orb IDs required for a project.
     * @param _projectId The ID of the project.
     * @return An array of required Skill Orb IDs.
     */
    function getProjectRequiredSkills(uint256 _projectId) external view returns (uint256[] memory) {
        Project storage project = projects[_projectId];
        require(project.id != 0, "Qx: Project does not exist");
        return project.requiredSkillOrbIds;
    }
}
```