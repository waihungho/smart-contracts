Okay, here is a Solidity smart contract for a Decentralized Autonomous Talent Network (DATN).

This contract aims to provide a platform where clients can post projects, talent can submit proposals, funds are held in escrow, work is tracked via milestones, and reviews/disputes are handled on-chain. It incorporates concepts like on-chain profiles, skill tagging, escrow with milestone payments, reputation tracking, and a basic dispute resolution mechanism managed by a designated arbitrator.

It has more than 20 functions covering user management, project lifecycle, proposals, escrow, reviews, disputes, skills, fees, and administrative tasks. It's designed to be a relatively complex and feature-rich example.

---

## Decentralized Autonomous Talent Network (DATN) Smart Contract

**Outline:**

1.  **SPDX License & Pragma**
2.  **Imports** (Basic necessities)
3.  **Error Definitions**
4.  **Enums:** Define states for Users, Projects, Proposals, Milestones, Disputes.
5.  **Structs:** Define data structures for User Profiles, Projects, Proposals, Milestones, Reviews, Disputes.
6.  **State Variables:** Store contract owner, arbitrator address, platform fee, mappings for users, projects, proposals, disputes, skill tags.
7.  **Events:** Emit signals for important actions (UserRegistered, ProjectCreated, ProposalSubmitted, MilestoneApproved, DisputeRaised, etc.).
8.  **Modifiers:** Restrict function access based on roles and state (onlyAdmin, onlyArbitrator, onlyProjectOwner, onlyTalent, onlyRelevantParties, etc.).
9.  **Constructor:** Initialize the admin address.
10. **Admin Functions:** Set arbitrator, platform fee, pause/unpause, withdraw fees.
11. **Arbitrator Functions:** Resolve disputes.
12. **Skill Management Functions:** Add, list, and assign skills.
13. **User Management Functions:** Register, update, view profiles.
14. **Project Management Functions:** Create, list, view, cancel projects.
15. **Proposal Management Functions:** Submit, withdraw, accept, reject proposals, view proposals for a project.
16. **Escrow & Milestone Functions:** Add milestones, mark complete, approve milestones, handle final project completion.
17. **Review Management Functions:** Leave and view reviews.
18. **Dispute Management Functions:** Raise disputes, submit evidence, get dispute details.
19. **Helper/View Functions:** Utility functions to fetch data.

**Function Summary:**

1.  `constructor()`: Initializes the contract owner (admin).
2.  `setArbitrator(address _arbitrator)`: Sets the address of the dispute arbitrator (Admin only).
3.  `setPlatformFee(uint256 _feePercentage)`: Sets the percentage platform fee (Admin only).
4.  `withdrawPlatformFees(address payable _recipient)`: Allows admin to withdraw accumulated fees (Admin only).
5.  `pauseContract()`: Pauses functionality in case of emergency (Admin only).
6.  `unpauseContract()`: Unpauses the contract (Admin only).
7.  `addSkillTag(string memory _tag)`: Adds a new valid skill tag (Admin only).
8.  `getSkillTags()`: Retrieves the list of all available skill tags.
9.  `registerUser(bool isClient, string memory _name, string memory _bio)`: Registers a new user profile (Either Client or Talent).
10. `updateUserProfile(string memory _name, string memory _bio)`: Updates the registered user's profile details.
11. `assignUserSkill(string memory _skillTag)`: Assigns a skill from the valid tags to the user's profile.
12. `getUserProfile(address _user)`: Retrieves the profile information for a given user address.
13. `createProject(string memory _title, string memory _description, string[] memory _requiredSkills, uint256 _totalBudget, uint256 _deadline)`: Creates a new project posting (Client only, requires budget in Ether).
14. `listProjects(ProjectStatus _statusFilter)`: Lists projects filtered by status.
15. `getProjectDetails(uint256 _projectId)`: Retrieves details for a specific project.
16. `cancelProject(uint256 _projectId)`: Allows the project owner to cancel a project if not yet accepted, refunding the escrowed amount.
17. `submitProposal(uint256 _projectId, string memory _coverLetter, uint256 _proposedBudget, uint256 _deliveryTime)`: Allows a registered talent to submit a proposal for a project.
18. `withdrawProposal(uint256 _projectId)`: Allows talent to withdraw their submitted proposal.
19. `acceptProposal(uint256 _projectId, address _talent)`: Allows the project owner to accept a specific talent's proposal. Moves project to `InProgress`.
20. `rejectProposal(uint256 _projectId, address _talent)`: Allows the project owner to reject a specific talent's proposal.
21. `getProjectProposals(uint256 _projectId)`: Retrieves all proposals submitted for a specific project.
22. `addMilestone(uint256 _projectId, string memory _description, uint256 _budgetPortion)`: Allows the project owner to add milestones *after* a proposal is accepted.
23. `markMilestoneCompleted(uint256 _projectId, uint256 _milestoneIndex)`: Allows the talent to mark a specific milestone as completed.
24. `approveMilestone(uint256 _projectId, uint256 _milestoneIndex)`: Allows the project owner to approve a completed milestone and release the associated funds (minus fee) to the talent.
25. `requestFullProjectCompletion(uint256 _projectId)`: Allows the talent to signal all milestones are complete and the project is finished.
26. `approveFullProjectCompletion(uint256 _projectId)`: Allows the project owner to approve the final project completion, releasing any remaining escrowed funds (after final milestone payment) and fees, and marking the project as `Completed`.
27. `leaveReview(uint256 _projectId, address _forUser, uint8 _rating, string memory _comment)`: Allows the client or talent of a completed project to leave a review for the other party.
28. `getUserReviews(address _user)`: Retrieves all reviews left for a specific user.
29. `raiseDispute(uint256 _projectId, string memory _reason)`: Allows either party of an in-progress project to raise a dispute.
30. `submitDisputeEvidence(uint256 _projectId, string memory _evidenceLink)`: Allows parties involved in a dispute to submit evidence (e.g., a link to IPFS/Arweave).
31. `getDisputeDetails(uint256 _projectId)`: Retrieves details for the dispute associated with a project.
32. `resolveDispute(uint256 _projectId, address payable _clientRecipient, uint256 _clientAmount, address payable _talentRecipient, uint256 _talentAmount)`: Allows the arbitrator to resolve a dispute by distributing the escrowed funds between the client and talent.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// Basic libraries (can be replaced by OpenZeppelin for production)
contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgValue() internal view virtual returns (uint256) {
        return msg.value;
    }
}

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _transferOwnership(_msgSender());
    }

    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is zero address");
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

contract Pausable is Context, Ownable {
    bool private _paused;

    event Paused(address account);
    event Unpaused(address account);

    constructor() {
        _paused = false;
    }

    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }

    modifier whenPaused() {
        _requirePaused();
        _;
    }

    function paused() public view virtual returns (bool) {
        return _paused;
    }

    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
    }

    function _pause() internal virtual onlyOwner whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    function _unpause() internal virtual onlyOwner whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }

    // Exposed pause/unpause functions for admin
    function pauseContract() public onlyOwner {
        _pause();
    }

    function unpauseContract() public onlyOwner {
        _unpause();
    }
}


// Error definitions
error DATN__UserNotRegistered();
error DATN__UserAlreadyRegistered();
error DATN__ProjectNotFound();
error DATN__ProjectNotInState(string expectedState);
error DATN__NotProjectOwner();
error DATN__NotProjectTalent();
error DATN__ProposalNotFound();
error DATN__ProposalAlreadySubmitted();
error DATN__MilestoneNotFound();
error DATN__MilestoneNotInState(string expectedState);
error DATN__CannotAddMilestonesAfterAccepted(); // Refined error name
error DATN__MilestoneBudgetExceedsRemaining();
error DATN__MilestonesNotCompleted();
error DATN__DisputeNotFound();
error DATN__DisputeAlreadyRaised();
error DATN__NotDisputeParty();
error DATN__NotArbitrator();
error DATN__SkillTagNotFound();
error DATN__SkillAlreadyAssigned();
error DATN__InsufficientFunds();
error DATN__InvalidFeePercentage();
error DATN__NoFeesToWithdraw();
error DATN__ReviewAlreadyLeft();


contract DecentralizedAutonomousTalentNetwork is Pausable {

    // --- Enums ---
    enum UserStatus {
        Inactive, // Default state before registration
        Active
    }

    enum ProjectStatus {
        Open,         // Client created, accepting proposals
        InProgress,   // Proposal accepted, work is ongoing
        AwaitingCompletion, // Talent requests final completion
        Completed,    // Client approves final work, funds dispersed
        Cancelled,    // Client cancelled before acceptance
        Disputed      // Project is currently in dispute
    }

    enum ProposalStatus {
        Pending,   // Submitted by talent
        Accepted,  // Accepted by client
        Rejected,  // Rejected by client
        Withdrawn  // Withdrawn by talent
    }

    enum MilestoneStatus {
        Pending,    // Created by client
        Completed,  // Marked completed by talent
        Approved    // Approved by client, funds released
    }

     enum DisputeStatus {
        None,       // No active dispute
        Active,     // Dispute raised, awaiting evidence
        Resolved    // Arbitrator has resolved the dispute
    }


    // --- Structs ---
    struct UserProfile {
        address userAddress;
        UserStatus status;
        bool isClient;
        string name;
        string bio;
        string[] skills; // References skillTags
        uint256 projectsAsClientCount;
        uint256 projectsAsTalentCount;
        uint256 totalClientRating; // Sum of ratings received as client
        uint256 totalTalentRating; // Sum of ratings received as talent
        uint256 clientReviewCount; // Number of ratings received as client
        uint256 talentReviewCount; // Number of ratings received as talent
    }

    struct Project {
        uint256 id;
        address client;
        address talent; // Address of accepted talent
        ProjectStatus status;
        string title;
        string description;
        string[] requiredSkills;
        uint256 totalBudget; // Total budget in native token (e.g., Wei)
        uint256 fundsInEscrow; // Amount currently held in escrow for this project
        uint256 deadline; // Timestamp
        uint256 creationTimestamp;
        Milestone[] milestones;
        // Proposal[] proposals; // Might store proposals separately if many per project
        bool clientReviewedTalent; // Track if reviews are left
        bool talentReviewedClient;
    }

    struct Proposal {
        uint256 id; // Unique proposal ID (optional, can use project+talent address)
        uint256 projectId;
        address talent;
        ProposalStatus status;
        string coverLetter;
        uint256 proposedBudget; // Should match project budget if accepted, or potentially lower
        uint256 deliveryTime; // Estimated delivery time in days/hours? Or timestamp? Let's keep it simple, days.
        uint256 submissionTimestamp;
    }

    struct Milestone {
        uint256 id;
        string description;
        uint256 budgetPortion; // Amount allocated to this milestone in native token (Wei)
        MilestoneStatus status;
        uint256 completedTimestamp; // When talent marked completed
        uint256 approvedTimestamp; // When client approved
    }

     struct Review {
        uint256 projectId;
        address reviewer; // Who left the review
        address reviewee; // Who received the review
        uint8 rating; // 1-5 stars
        string comment;
        uint256 timestamp;
    }

     struct Dispute {
        uint256 projectId;
        DisputeStatus status;
        address initiatedBy;
        string reason;
        string clientEvidence; // Link to evidence (e.g., IPFS hash)
        string talentEvidence; // Link to evidence
        uint256 raisedTimestamp;
        uint256 resolvedTimestamp; // When resolved
    }


    // --- State Variables ---
    address public arbitrator;
    uint256 public platformFeePercentage; // e.g., 5 for 5%
    uint256 private totalPlatformFees; // Accumulated fees

    mapping(address => UserProfile) public users;
    mapping(address => bool) public isRegistered; // Quick check

    Project[] public projects; // Array to store all projects
    uint256 private _nextProjectId;

    // Mapping from project ID to mapping of talent address to proposal
    mapping(uint256 => mapping(address => Proposal)) public proposals;
    // Keep track of talent addresses who submitted proposals for a project
    mapping(uint256 => address[]) public projectProposalsTalent;
    uint256 private _nextProposalId; // Global proposal ID (optional)

    mapping(uint256 => Dispute) public projectDisputes;

    // Mapping from user address to array of reviews they received
    mapping(address => Review[]) public userReviews;

    // List of allowed skills
    string[] public skillTags;
    mapping(string => bool) private isValidSkillTag;


    // --- Events ---
    event UserRegistered(address indexed user, bool isClient);
    event ProfileUpdated(address indexed user);
    event SkillAssigned(address indexed user, string skill);
    event ProjectCreated(uint256 indexed projectId, address indexed client, uint256 budget, uint256 deadline);
    event ProjectStatusChanged(uint256 indexed projectId, ProjectStatus newStatus);
    event ProjectCancelled(uint256 indexed projectId, uint208 refundedAmount); // uint208 to avoid overflow issues if value is large
    event ProposalSubmitted(uint256 indexed projectId, address indexed talent);
    event ProposalStatusChanged(uint256 indexed projectId, address indexed talent, ProposalStatus newStatus);
    event MilestoneAdded(uint256 indexed projectId, uint256 indexed milestoneIndex, uint256 budgetPortion);
    event MilestoneStatusChanged(uint256 indexed projectId, uint256 indexed milestoneIndex, MilestoneStatus newStatus);
    event FundsReleased(uint256 indexed projectId, address indexed recipient, uint256 amount);
    event ReviewLeft(uint256 indexed projectId, address indexed reviewer, address indexed reviewee, uint8 rating);
    event DisputeRaised(uint256 indexed projectId, address indexed initiatedBy, string reason);
    event DisputeEvidenceSubmitted(uint256 indexed projectId, address indexed party);
    event DisputeResolved(uint256 indexed projectId, address indexed arbitrator, uint256 clientPayment, uint256 talentPayment);
    event SkillTagAdded(string tag);
    event PlatformFeeSet(uint256 percentage);
    event PlatformFeesWithdrawn(address indexed recipient, uint256 amount);


    // --- Modifiers ---
    modifier onlyAdmin() {
        // Using Ownable's onlyOwner for the initial admin (contract owner)
        // If using a separate admin role, would need custom check: require(msg.sender == admin, "DATN: Only admin");
        onlyOwner();
        _;
    }

    modifier onlyArbitrator() {
        require(_msgSender() == arbitrator, "DATN: Only arbitrator");
        _;
    }

    modifier onlyRegisteredUser() {
        require(isRegistered[_msgSender()], "DATN: Caller not registered");
        _;
    }

    modifier onlyProjectOwner(uint256 _projectId) {
        require(_projectId < projects.length, "DATN: Invalid project ID");
        require(projects[_projectId].client == _msgSender(), "DATN: Not project owner");
        _;
    }

    modifier onlyProjectTalent(uint256 _projectId) {
        require(_projectId < projects.length, "DATN: Invalid project ID");
        require(projects[_projectId].talent == _msgSender(), "DATN: Not project talent");
        _;
    }

    modifier onlyRelevantProjectParty(uint256 _projectId) {
        require(_projectId < projects.length, "DATN: Invalid project ID");
        require(projects[_projectId].client == _msgSender() || projects[_projectId].talent == _msgSender(), "DATN: Not project party");
        _;
    }

    modifier onlyInProjectState(uint256 _projectId, ProjectStatus _status) {
        require(_projectId < projects.length, "DATN: Invalid project ID");
        require(projects[_projectId].status == _status, string(abi.encodePacked("DATN: Project must be in ", uint256(_status), " state")));
        _;
    }

     modifier onlyInMilestoneState(uint256 _projectId, uint256 _milestoneIndex, MilestoneStatus _status) {
         require(_projectId < projects.length, "DATN: Invalid project ID");
         require(_milestoneIndex < projects[_projectId].milestones.length, "DATN: Invalid milestone index");
         require(projects[_projectId].milestones[_milestoneIndex].status == _status, string(abi.encodePacked("DATN: Milestone must be in ", uint256(_status), " state")));
         _;
     }

     modifier onlyInDisputeState(uint256 _projectId, DisputeStatus _status) {
         require(_projectId < projects.length, "DATN: Invalid project ID");
         require(projectDisputes[_projectId].status == _status, string(abi.encodePacked("DATN: Dispute must be in ", uint256(_status), " state")));
     }


    // --- Constructor ---
    constructor() Pausable() {
        // Ownable constructor sets owner, Pausable constructor sets _paused to false.
        // admin = msg.sender; // Already set by Ownable
        platformFeePercentage = 0; // Default 0 fee
        _nextProjectId = 0;
        _nextProposalId = 0;
    }


    // --- Admin Functions ---

    function setArbitrator(address _arbitrator) external onlyAdmin whenNotPaused {
        require(_arbitrator != address(0), "DATN: Zero address not allowed");
        arbitrator = _arbitrator;
    }

    function setPlatformFee(uint256 _feePercentage) external onlyAdmin whenNotPaused {
        require(_feePercentage <= 100, "DATN: Fee percentage must be between 0 and 100");
        platformFeePercentage = _feePercentage;
        emit PlatformFeeSet(_feePercentage);
    }

     function withdrawPlatformFees(address payable _recipient) external onlyAdmin {
         require(_recipient != address(0), "DATN: Invalid recipient address");
         uint256 amount = totalPlatformFees;
         require(amount > 0, "DATN: No fees to withdraw");
         totalPlatformFees = 0;
         // Use low-level call for robustness
         (bool success, ) = _recipient.call{value: amount}("");
         require(success, "DATN: Fee withdrawal failed");
         emit PlatformFeesWithdrawn(_recipient, amount);
     }


    // --- Arbitrator Functions ---

    function resolveDispute(
        uint256 _projectId,
        address payable _clientRecipient,
        uint256 _clientAmount,
        address payable _talentRecipient,
        uint256 _talentAmount
    ) external onlyArbitrator whenNotPaused onlyInDisputeState(_projectId, DisputeStatus.Active) {
        Project storage project = projects[_projectId];
        require(_clientRecipient == project.client || _clientRecipient == address(0), "DATN: Invalid client recipient");
        require(_talentRecipient == project.talent || _talentRecipient == address(0), "DATN: Invalid talent recipient");
        require(_clientAmount + _talentAmount <= project.fundsInEscrow, "DATN: Resolution amount exceeds escrow");

        project.status = ProjectStatus.Completed; // Dispute is resolved, project is considered completed via resolution

        // Distribute funds
        if (_clientAmount > 0 && _clientRecipient != address(0)) {
             (bool success, ) = _clientRecipient.call{value: _clientAmount}("");
             require(success, "DATN: Client payment failed");
             emit FundsReleased(_projectId, _clientRecipient, _clientAmount);
        }
         if (_talentAmount > 0 && _talentRecipient != address(0)) {
             // Note: Fees could be applied here if desired based on resolution outcome
             (bool success, ) = _talentRecipient.call{value: _talentAmount}("");
             require(success, "DATN: Talent payment failed");
             emit FundsReleased(_projectId, _talentRecipient, _talentAmount);
        }

        // Handle remaining escrow (e.g., send to platform fees or burn)
        uint256 remainingEscrow = project.fundsInEscrow - (_clientAmount + _talentAmount);
        if (remainingEscrow > 0) {
             totalPlatformFees += remainingEscrow; // Add remaining to platform fees
        }

        project.fundsInEscrow = 0; // Escrow is empty

        Dispute storage dispute = projectDisputes[_projectId];
        dispute.status = DisputeStatus.Resolved;
        dispute.resolvedTimestamp = block.timestamp;

        emit ProjectStatusChanged(_projectId, ProjectStatus.Completed); // Or maybe a specific 'Resolved' status? Let's use Completed for now.
        emit DisputeResolved(_projectId, _msgSender(), _clientAmount, _talentAmount);
    }


    // --- Skill Management Functions ---

    function addSkillTag(string memory _tag) external onlyAdmin whenNotPaused {
        require(!isValidSkillTag[_tag], "DATN: Skill tag already exists");
        skillTags.push(_tag);
        isValidSkillTag[_tag] = true;
        emit SkillTagAdded(_tag);
    }

    function getSkillTags() external view returns (string[] memory) {
        return skillTags;
    }


    // --- User Management Functions ---

    function registerUser(bool isClient, string memory _name, string memory _bio) external whenNotPaused {
        require(!isRegistered[_msgSender()], Error.DATN__UserAlreadyRegistered());
        require(bytes(_name).length > 0, "DATN: Name cannot be empty");

        users[_msgSender()] = UserProfile({
            userAddress: _msgSender(),
            status: UserStatus.Active,
            isClient: isClient,
            name: _name,
            bio: _bio,
            skills: new string[](0),
            projectsAsClientCount: 0,
            projectsAsTalentCount: 0,
            totalClientRating: 0,
            totalTalentRating: 0,
            clientReviewCount: 0,
            talentReviewCount: 0
        });
        isRegistered[_msgSender()] = true;

        emit UserRegistered(_msgSender(), isClient);
    }

    function updateUserProfile(string memory _name, string memory _bio) external onlyRegisteredUser whenNotPaused {
        require(bytes(_name).length > 0, "DATN: Name cannot be empty");
        UserProfile storage user = users[_msgSender()];
        user.name = _name;
        user.bio = _bio;
        emit ProfileUpdated(_msgSender());
    }

     function assignUserSkill(string memory _skillTag) external onlyRegisteredUser whenNotPaused {
         require(isValidSkillTag[_skillTag], Error.DATN__SkillTagNotFound());
         UserProfile storage user = users[_msgSender()];
         // Check if skill is already assigned
         for(uint i = 0; i < user.skills.length; i++) {
             if (keccak256(bytes(user.skills[i])) == keccak256(bytes(_skillTag))) {
                 revert DATN__SkillAlreadyAssigned();
             }
         }
         user.skills.push(_skillTag);
         emit SkillAssigned(_msgSender(), _skillTag);
     }

    function getUserProfile(address _user) external view returns (UserProfile memory) {
        require(isRegistered[_user], Error.DATN__UserNotRegistered());
        return users[_user];
    }


    // --- Project Management Functions ---

    function createProject(
        string memory _title,
        string memory _description,
        string[] memory _requiredSkills,
        uint256 _totalBudget,
        uint256 _deadline
    ) external payable onlyRegisteredUser whenNotPaused {
        UserProfile storage clientProfile = users[_msgSender()];
        require(clientProfile.isClient, "DATN: Only clients can create projects");
        require(bytes(_title).length > 0, "DATN: Title cannot be empty");
        require(_totalBudget > 0, "DATN: Budget must be greater than zero");
        require(_msgSender() == tx.origin, "DATN: Not allowed to create project via contract"); // Basic re-entrancy prevention for ETH transfer in future
        require(msg.value == _totalBudget, Error.DATN__InsufficientFunds());

        uint256 projectId = _nextProjectId++;
        projects.push(Project({
            id: projectId,
            client: _msgSender(),
            talent: address(0),
            status: ProjectStatus.Open,
            title: _title,
            description: _description,
            requiredSkills: _requiredSkills,
            totalBudget: _totalBudget,
            fundsInEscrow: msg.value,
            deadline: _deadline,
            creationTimestamp: block.timestamp,
            milestones: new Milestone[](0),
            clientReviewedTalent: false,
            talentReviewedClient: false
        }));

        clientProfile.projectsAsClientCount++;

        emit ProjectCreated(projectId, _msgSender(), _totalBudget, _deadline);
    }

    function listProjects(ProjectStatus _statusFilter) external view returns (Project[] memory) {
        uint256 count = 0;
        for (uint i = 0; i < projects.length; i++) {
            if (projects[i].status == _statusFilter) {
                count++;
            }
        }

        Project[] memory filteredProjects = new Project[](count);
        uint256 index = 0;
        for (uint i = 0; i < projects.length; i++) {
            if (projects[i].status == _statusFilter) {
                filteredProjects[index] = projects[i];
                index++;
            }
        }
        return filteredProjects;
    }

    function getProjectDetails(uint256 _projectId) external view returns (Project memory) {
         require(_projectId < projects.length, Error.DATN__ProjectNotFound());
         return projects[_projectId];
     }


    function cancelProject(uint256 _projectId) external onlyProjectOwner(_projectId) whenNotPaused onlyInProjectState(_projectId, ProjectStatus.Open) {
        Project storage project = projects[_projectId];
        uint256 refundAmount = project.fundsInEscrow;
        project.fundsInEscrow = 0;
        project.status = ProjectStatus.Cancelled;

        // Refund funds to client
        (bool success, ) = payable(project.client).call{value: refundAmount}("");
        require(success, "DATN: Refund failed");

        emit ProjectStatusChanged(_projectId, ProjectStatus.Cancelled);
        emit ProjectCancelled(_projectId, uint208(refundAmount));

        // Optional: Also need to mark all proposals for this project as rejected/cancelled
        address[] memory talentAddresses = projectProposalsTalent[_projectId];
        for(uint i=0; i<talentAddresses.length; i++) {
             Proposal storage prop = proposals[_projectId][talentAddresses[i]];
             if (prop.status == ProposalStatus.Pending) {
                 prop.status = ProposalStatus.Rejected; // Or add a new status like 'ProjectCancelled'
                 emit ProposalStatusChanged(_projectId, talentAddresses[i], prop.status);
             }
        }
    }


    // --- Proposal Management Functions ---

    function submitProposal(
        uint256 _projectId,
        string memory _coverLetter,
        uint256 _proposedBudget,
        uint256 _deliveryTime
    ) external onlyRegisteredUser whenNotPaused onlyInProjectState(_projectId, ProjectStatus.Open) {
        UserProfile storage talentProfile = users[_msgSender()];
        require(!talentProfile.isClient, "DATN: Clients cannot submit proposals");
        require(_proposedBudget > 0, "DATN: Proposed budget must be greater than zero");
        require(_deliveryTime > 0, "DATN: Delivery time must be greater than zero");
         // Check if talent already submitted a proposal for this project
        require(proposals[_projectId][_msgSender()].talent == address(0) || proposals[_projectId][_msgSender()].status == ProposalStatus.Withdrawn || proposals[_projectId][_msgSender()].status == ProposalStatus.Rejected, Error.DATN__ProposalAlreadySubmitted());


        Proposal memory newProposal = Proposal({
             id: _nextProposalId++,
             projectId: _projectId,
             talent: _msgSender(),
             status: ProposalStatus.Pending,
             coverLetter: _coverLetter,
             proposedBudget: _proposedBudget,
             deliveryTime: _deliveryTime,
             submissionTimestamp: block.timestamp
         });

        proposals[_projectId][_msgSender()] = newProposal;
        projectProposalsTalent[_projectId].push(_msgSender()); // Add talent to list for this project

        emit ProposalSubmitted(_projectId, _msgSender());
    }

    function withdrawProposal(uint256 _projectId) external onlyRegisteredUser whenNotPaused onlyInProjectState(_projectId, ProjectStatus.Open) {
        Proposal storage proposal = proposals[_projectId][_msgSender()];
        require(proposal.talent == _msgSender(), Error.DATN__ProposalNotFound()); // Check if proposal exists for this user/project
        require(proposal.status == ProposalStatus.Pending, "DATN: Proposal not in Pending state");

        proposal.status = ProposalStatus.Withdrawn;
        emit ProposalStatusChanged(_projectId, _msgSender(), ProposalStatus.Withdrawn);
    }

    function acceptProposal(uint256 _projectId, address _talent) external onlyProjectOwner(_projectId) whenNotPaused onlyInProjectState(_projectId, ProjectStatus.Open) {
        require(isRegistered[_talent], Error.DATN__UserNotRegistered());
        UserProfile storage talentProfile = users[_talent];
        require(!talentProfile.isClient, "DATN: Cannot accept client as talent");

        Proposal storage proposal = proposals[_projectId][_talent];
        require(proposal.talent == _talent, Error.DATN__ProposalNotFound()); // Check if proposal exists
        require(proposal.status == ProposalStatus.Pending, "DATN: Proposal not in Pending state");
        require(proposal.proposedBudget <= projects[_projectId].totalBudget, "DATN: Proposed budget exceeds project budget");


        Project storage project = projects[_projectId];
        project.talent = _talent;
        project.status = ProjectStatus.InProgress;
        // Note: The actual budget might be slightly lower than totalBudget if proposedBudget is less.
        // We'll keep totalBudget as the max and use proposal.proposedBudget or milestone budgets for payments.
        // For simplicity, let's assume accepted budget matches totalBudget unless adjusted via milestones.
        // A more complex version would allow client to negotiate/accept a different budget.
        // For THIS contract, we'll stick to totalBudget as the amount in escrow. Milestone budgets must sum up to <= totalBudget.

        proposal.status = ProposalStatus.Accepted;
        talentProfile.projectsAsTalentCount++;

        emit ProposalStatusChanged(_projectId, _talent, ProposalStatus.Accepted);
        emit ProjectStatusChanged(_projectId, ProjectStatus.InProgress);

        // Reject all other pending proposals for this project
        address[] memory talentAddresses = projectProposalsTalent[_projectId];
        for(uint i=0; i<talentAddresses.length; i++) {
             if (talentAddresses[i] != _talent) {
                 Proposal storage otherProp = proposals[_projectId][talentAddresses[i]];
                 if (otherProp.status == ProposalStatus.Pending) {
                     otherProp.status = ProposalStatus.Rejected;
                     emit ProposalStatusChanged(_projectId, talentAddresses[i], otherProp.status);
                 }
             }
        }
    }

    function rejectProposal(uint256 _projectId, address _talent) external onlyProjectOwner(_projectId) whenNotPaused onlyInProjectState(_projectId, ProjectStatus.Open) {
        require(isRegistered[_talent], Error.DATN__UserNotRegistered());
        Proposal storage proposal = proposals[_projectId][_talent];
        require(proposal.talent == _talent, Error.DATN__ProposalNotFound()); // Check if proposal exists
        require(proposal.status == ProposalStatus.Pending, "DATN: Proposal not in Pending state");

        proposal.status = ProposalStatus.Rejected;
        emit ProposalStatusChanged(_projectId, _talent, ProposalStatus.Rejected);
    }

     function getProjectProposals(uint256 _projectId) external view returns (Proposal[] memory) {
         require(_projectId < projects.length, Error.DATN__ProjectNotFound());
         address[] memory talentAddresses = projectProposalsTalent[_projectId];
         Proposal[] memory projectProps = new Proposal[](talentAddresses.length);
         for(uint i=0; i<talentAddresses.length; i++) {
             projectProps[i] = proposals[_projectId][talentAddresses[i]];
         }
         return projectProps;
     }


    // --- Escrow & Milestone Functions ---

    function addMilestone(uint256 _projectId, string memory _description, uint256 _budgetPortion) external onlyProjectOwner(_projectId) whenNotPaused onlyInProjectState(_projectId, ProjectStatus.InProgress) {
        Project storage project = projects[_projectId];
        require(bytes(_description).length > 0, "DATN: Description cannot be empty");
        require(_budgetPortion > 0, "DATN: Budget portion must be greater than zero");

        // Check total milestone budget doesn't exceed total project budget
        uint256 currentTotalMilestoneBudget = 0;
        for (uint i = 0; i < project.milestones.length; i++) {
            currentTotalMilestoneBudget += project.milestones[i].budgetPortion;
        }
        require(currentTotalMilestoneBudget + _budgetPortion <= project.totalBudget, Error.DATN__MilestoneBudgetExceedsRemaining());

        project.milestones.push(Milestone({
            id: project.milestones.length, // Simple incremental ID within the project
            description: _description,
            budgetPortion: _budgetPortion,
            status: MilestoneStatus.Pending,
            completedTimestamp: 0,
            approvedTimestamp: 0
        }));

        emit MilestoneAdded(_projectId, project.milestones.length - 1, _budgetPortion);
    }


    function markMilestoneCompleted(uint256 _projectId, uint256 _milestoneIndex) external onlyProjectTalent(_projectId) whenNotPaused onlyInProjectState(_projectId, ProjectStatus.InProgress) onlyInMilestoneState(_projectId, _milestoneIndex, MilestoneStatus.Pending) {
        Project storage project = projects[_projectId];
        Milestone storage milestone = project.milestones[_milestoneIndex];

        milestone.status = MilestoneStatus.Completed;
        milestone.completedTimestamp = block.timestamp;

        emit MilestoneStatusChanged(_projectId, _milestoneIndex, MilestoneStatus.Completed);
    }

    function approveMilestone(uint256 _projectId, uint256 _milestoneIndex) external onlyProjectOwner(_projectId) whenNotPaused onlyInProjectState(_projectId, ProjectStatus.InProgress) onlyInMilestoneState(_projectId, _milestoneIndex, MilestoneStatus.Completed) {
        Project storage project = projects[_projectId];
        Milestone storage milestone = project.milestones[_milestoneIndex];

        uint256 paymentAmount = milestone.budgetPortion;
        uint256 feeAmount = (paymentAmount * platformFeePercentage) / 100;
        uint256 talentPayment = paymentAmount - feeAmount;

        milestone.status = MilestoneStatus.Approved;
        milestone.approvedTimestamp = block.timestamp;

        // Update escrow and fees
        project.fundsInEscrow -= paymentAmount;
        totalPlatformFees += feeAmount;

        // Pay talent
         (bool success, ) = payable(project.talent).call{value: talentPayment}("");
         require(success, "DATN: Milestone payment failed");

        emit MilestoneStatusChanged(_projectId, _milestoneIndex, MilestoneStatus.Approved);
        emit FundsReleased(_projectId, project.talent, talentPayment);
    }

    function requestFullProjectCompletion(uint256 _projectId) external onlyProjectTalent(_projectId) whenNotPaused onlyInProjectState(_projectId, ProjectStatus.InProgress) {
         Project storage project = projects[_projectId];

         // Ensure all milestones are approved
         for(uint i=0; i < project.milestones.length; i++) {
             require(project.milestones[i].status == MilestoneStatus.Approved, Error.DATN__MilestonesNotCompleted());
         }

         project.status = ProjectStatus.AwaitingCompletion;
         emit ProjectStatusChanged(_projectId, ProjectStatus.AwaitingCompletion);
     }

    function approveFullProjectCompletion(uint256 _projectId) external onlyProjectOwner(_projectId) whenNotPaused onlyInProjectState(_projectId, ProjectStatus.AwaitingCompletion) {
        Project storage project = projects[_projectId];

         // Double check all milestones are approved (should be guaranteed by requestFullProjectCompletion)
         for(uint i=0; i < project.milestones.length; i++) {
             require(project.milestones[i].status == MilestoneStatus.Approved, Error.DATN__MilestonesNotCompleted());
         }

        // Any remaining funds in escrow after all milestone payments go to platform fees
        if (project.fundsInEscrow > 0) {
            totalPlatformFees += project.fundsInEscrow;
             project.fundsInEscrow = 0;
        }

        project.status = ProjectStatus.Completed;
        emit ProjectStatusChanged(_projectId, ProjectStatus.Completed);
    }


    // --- Review Management Functions ---

    function leaveReview(uint256 _projectId, address _forUser, uint8 _rating, string memory _comment) external onlyRelevantProjectParty(_projectId) whenNotPaused {
        Project storage project = projects[_projectId];
        require(project.status == ProjectStatus.Completed || (project.status == ProjectStatus.Disputed && projectDisputes[_projectId].status == DisputeStatus.Resolved), "DATN: Project must be completed or dispute resolved to leave review");
        require(_rating >= 1 && _rating <= 5, "DATN: Rating must be between 1 and 5");
        require(_forUser == project.client || _forUser == project.talent, "DATN: Can only review client or talent for this project");
        require(_msgSender() != _forUser, "DATN: Cannot review yourself");

        // Check if review already exists for this pair on this project
        if (_msgSender() == project.client && _forUser == project.talent) {
            require(!project.clientReviewedTalent, Error.DATN__ReviewAlreadyLeft());
            project.clientReviewedTalent = true;
        } else if (_msgSender() == project.talent && _forUser == project.client) {
             require(!project.talentReviewedClient, Error.DATN__ReviewAlreadyLeft());
             project.talentReviewedClient = true;
        } else {
             revert("DATN: Invalid reviewer/reviewee pair for this project");
        }

        Review memory newReview = Review({
            projectId: _projectId,
            reviewer: _msgSender(),
            reviewee: _forUser,
            rating: _rating,
            comment: _comment,
            timestamp: block.timestamp
        });

        userReviews[_forUser].push(newReview);

        // Update user's total rating and count
        UserProfile storage revieweeProfile = users[_forUser];
        if (revieweeProfile.isClient) { // Reviewee is the client
            revieweeProfile.totalClientRating += _rating;
            revieweeProfile.clientReviewCount++;
        } else { // Reviewee is the talent
            revieweeProfile.totalTalentRating += _rating;
            revieweeProfile.talentReviewCount++;
        }

        emit ReviewLeft(_projectId, _msgSender(), _forUser, _rating);
    }

    function getUserReviews(address _user) external view returns (Review[] memory) {
        require(isRegistered[_user], Error.DATN__UserNotRegistered());
        return userReviews[_user];
    }


    // --- Dispute Management Functions ---

    function raiseDispute(uint256 _projectId, string memory _reason) external onlyRelevantProjectParty(_projectId) whenNotPaused {
         Project storage project = projects[_projectId];
         require(project.status == ProjectStatus.InProgress || project.status == ProjectStatus.AwaitingCompletion, "DATN: Dispute can only be raised for InProgress or AwaitingCompletion projects");
         require(projectDisputes[_projectId].status == DisputeStatus.None, Error.DATN__DisputeAlreadyRaised());
         require(bytes(_reason).length > 0, "DATN: Reason cannot be empty");
         require(arbitrator != address(0), "DATN: Arbitrator not set");

         project.status = ProjectStatus.Disputed; // Change project status
         projectDisputes[_projectId] = Dispute({
             projectId: _projectId,
             status: DisputeStatus.Active,
             initiatedBy: _msgSender(),
             reason: _reason,
             clientEvidence: "",
             talentEvidence: "",
             raisedTimestamp: block.timestamp,
             resolvedTimestamp: 0
         });

         emit ProjectStatusChanged(_projectId, ProjectStatus.Disputed);
         emit DisputeRaised(_projectId, _msgSender(), _reason);
     }

    function submitDisputeEvidence(uint256 _projectId, string memory _evidenceLink) external onlyRelevantProjectParty(_projectId) whenNotPaused onlyInDisputeState(_projectId, DisputeStatus.Active) {
         Dispute storage dispute = projectDisputes[_projectId];
         Project storage project = projects[_projectId];

         if (_msgSender() == project.client) {
             dispute.clientEvidence = _evidenceLink;
         } else if (_msgSender() == project.talent) {
             dispute.talentEvidence = _evidenceLink;
         } else {
             revert DATN__NotDisputeParty(); // Should be covered by onlyRelevantProjectParty, but good safety check
         }

         emit DisputeEvidenceSubmitted(_projectId, _msgSender());
     }

    function getDisputeDetails(uint256 _projectId) external view returns (Dispute memory) {
         require(_projectId < projects.length, Error.DATN__ProjectNotFound());
         require(projectDisputes[_projectId].status != DisputeStatus.None, Error.DATN__DisputeNotFound());
         return projectDisputes[_projectId];
    }


    // --- Helper / View Functions ---

    function getAverageClientRating(address _user) external view returns (uint256) {
        UserProfile memory user = getUserProfile(_user);
        if (user.clientReviewCount == 0) {
            return 0;
        }
        return user.totalClientRating / user.clientReviewCount;
    }

     function getAverageTalentRating(address _user) external view returns (uint256) {
         UserProfile memory user = getUserProfile(_user);
         if (user.talentReviewCount == 0) {
             return 0;
         }
         return user.totalTalentRating / user.talentReviewCount;
     }

     // Get a specific proposal by project and talent address
     function getProposal(uint256 _projectId, address _talent) external view returns (Proposal memory) {
         require(_projectId < projects.length, Error.DATN__ProjectNotFound());
         require(proposals[_projectId][_talent].talent != address(0), Error.DATN__ProposalNotFound());
         return proposals[_projectId][_talent];
     }

     // Get total number of projects
     function getTotalProjects() external view returns (uint256) {
         return projects.length;
     }

     // Get all project IDs for a user (can be slow for large number of projects)
     // A more scalable approach would involve a separate mapping or off-chain indexing
     function getUserProjectIds(address _user) external view returns (uint256[] memory clientProjects, uint256[] memory talentProjects) {
        require(isRegistered[_user], Error.DATN__UserNotRegistered());

        uint256 clientCount = 0;
        uint256 talentCount = 0;

        // First pass to count
        for (uint i = 0; i < projects.length; i++) {
            if (projects[i].client == _user) {
                clientCount++;
            }
            if (projects[i].talent == _user) {
                 talentCount++;
            }
        }

        clientProjects = new uint256[](clientCount);
        talentProjects = new uint256[](talentCount);

        uint256 clientIndex = 0;
        uint256 talentIndex = 0;

        // Second pass to populate arrays
         for (uint i = 0; i < projects.length; i++) {
            if (projects[i].client == _user) {
                clientProjects[clientIndex++] = projects[i].id;
            }
            if (projects[i].talent == _user) {
                 talentProjects[talentIndex++] = projects[i].id;
            }
        }

        return (clientProjects, talentProjects);
     }
}
```