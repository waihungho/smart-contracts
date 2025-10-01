Here's a smart contract named "QuantumLeap" designed to be a decentralized skill and reputation network with advanced features like AI-assisted project evaluation, a non-transferable (soulbound-like) reputation system, and a dynamic marketplace for projects.

---

# QuantumLeap: Decentralized Skill & Reputation Network

## Outline & Function Summary

This contract establishes a decentralized platform where users can register profiles, declare skills, and participate in projects. Project creators can post tasks with specific requirements and budgets, and contributors can apply, submit work, and earn reputation and rewards. A unique aspect is the integration with an AI oracle for objective evaluation of project submissions, enhancing trust and fairness.

### I. Core Setup & Administration
1.  **`constructor(address _initialOracle, address _acceptedToken)`**: Initializes the contract owner, sets the trusted AI oracle address, and defines the ERC-20 token used for project budgets and payments.
2.  **`updateOracleAddress(address _newOracle)`**: Allows the owner to change the trusted AI oracle address.
3.  **`setFeePercentage(uint256 _newFeePercentage)`**: Allows the owner to adjust the platform's fee percentage (e.g., 500 for 5%).
4.  **`withdrawFees()`**: Allows the owner to withdraw accumulated fees in the accepted ERC-20 token.
5.  **`pause()`**: Pauses contract operations (e.g., for upgrades or critical issues).
6.  **`unpause()`**: Unpauses contract operations.

### II. User & Reputation Management
7.  **`registerUser(string calldata _name, string calldata _bio)`**: Allows a new user to create their profile, which is required to participate in projects.
8.  **`updateUserProfile(string calldata _newName, string calldata _newBio)`**: Allows registered users to update their profile information.
9.  **`addSkill(string calldata _skill)`**: Allows a user to declare a new skill.
10. **`removeSkill(string calldata _skill)`**: Allows a user to remove a previously declared skill.
11. **`getReputationTier(address _user)`**: Returns the reputation tier (e.g., Bronze, Silver, Gold) for a given user based on their score.
12. **`getUserProfile(address _user)`**: Retrieves a user's full profile details (name, bio, reputation, skills).

### III. Project Creation & Lifecycle
13. **`createProject(string calldata _title, string calldata _description, string[] calldata _requiredSkills, uint256 _budget, uint256 _deadline)`**: Allows a registered user to create a new project, depositing the required budget in the accepted ERC-20 token.
14. **`cancelProject(uint256 _projectId)`**: Allows the project creator to cancel an open project before a contributor is selected, refunding the budget.
15. **`applyForProject(uint256 _projectId)`**: Allows a registered user with matching skills to apply for an open project.
16. **`selectContributor(uint256 _projectId, address _contributor)`**: Allows the project creator to select one applicant for their project.
17. **`submitProjectWork(uint256 _projectId, string calldata _submissionHash)`**: Allows the selected contributor to submit their work (e.g., an IPFS CID) for a project.
18. **`requestAIEvaluation(uint256 _projectId)`**: Allows the project creator to request an AI evaluation of the submitted work from the trusted oracle. This is an external call.
19. **`receiveAIEvaluation(uint256 _projectId, uint256 _score)`**: Callback function, *only callable by the trusted AI oracle*, to record the AI's evaluation score for a submission.
20. **`approveProjectCompletion(uint256 _projectId)`**: Allows the project creator to approve the submitted work, triggering payment to the contributor and reputation update.
21. **`rejectProjectCompletion(uint252 _projectId, string calldata _reason)`**: Allows the project creator to reject submitted work, potentially leading to a dispute.
22. **`initiateDispute(uint256 _projectId, string calldata _reason)`**: Allows either the creator or contributor to formally initiate a dispute after a rejection or failure to approve.
23. **`resolveDisputeByArbitrator(uint256 _projectId, address _winner, uint256 _payoutToWinner)`**: Admin function to resolve a dispute, determining the winner and payout.
24. **`getProjectDetails(uint256 _projectId)`**: Retrieves all details for a specific project.
25. **`getApplicationsForProject(uint256 _projectId)`**: Retrieves all applications for a specific project.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

// --- Outline & Function Summary above ---

contract QuantumLeap is Ownable, Pausable {
    using SafeMath for uint256;

    // --- Enums ---
    enum ProjectStatus { Open, Applied, Selected, Submitted, AI_Evaluating, Approved, Rejected, Disputed, Cancelled }
    enum ApplicationStatus { Pending, Approved, Rejected }
    enum DisputeStatus { None, Initiated, Resolved }
    enum ReputationTier { Bronze, Silver, Gold, Platinum, Diamond }

    // --- Structs ---

    struct UserProfile {
        string name;
        string bio;
        uint256 reputationScore; // Non-transferable, increases with successful projects
        mapping(string => bool) skills; // Mapping for quick skill check
        string[] declaredSkills; // Array to easily retrieve all skills
        bool isRegistered;
        uint256 createdAt;
    }

    struct Project {
        address creator;
        string title;
        string description;
        uint256 budget; // In accepted ERC20 token
        uint256 deadline; // Unix timestamp
        string[] requiredSkills;
        ProjectStatus status;
        address selectedContributor;
        string submissionHash; // IPFS CID or similar for submitted work
        uint256 aiEvaluationScore; // 0-100 scale, from trusted AI oracle
        DisputeStatus disputeStatus;
        uint256 createdAt;
        uint256 completedAt;
        uint256 feeAmount; // Fee collected from this project
    }

    struct Application {
        address applicant;
        uint256 projectId;
        ApplicationStatus status;
        uint256 appliedAt;
    }

    // --- State Variables ---

    uint256 public nextProjectId;
    address public trustedAIO oracle; // Address of the AI oracle
    IERC20 public acceptedToken; // The ERC-20 token used for payments

    // Platform fee percentage (e.g., 500 for 5%)
    uint256 public feePercentage = 500; // Default to 5%

    // Mappings
    mapping(address => UserProfile) public userProfiles;
    mapping(uint256 => Project) public projects;
    mapping(uint256 => mapping(address => Application)) public projectApplications;
    mapping(uint256 => address[]) public projectApplicantsList; // To iterate applicants
    mapping(address => uint256[]) public userProjectsCreated;
    mapping(address => uint256[]) public userProjectsContributed;

    // --- Events ---

    event UserRegistered(address indexed user, string name);
    event UserProfileUpdated(address indexed user, string newName, string newBio);
    event SkillAdded(address indexed user, string skill);
    event SkillRemoved(address indexed user, string skill);
    event ProjectCreated(uint256 indexed projectId, address indexed creator, uint256 budget, uint256 deadline);
    event ProjectCancelled(uint256 indexed projectId, address indexed creator);
    event ProjectApplied(uint256 indexed projectId, address indexed applicant);
    event ContributorSelected(uint256 indexed projectId, address indexed creator, address indexed contributor);
    event WorkSubmitted(uint256 indexed projectId, address indexed contributor, string submissionHash);
    event AIEvaluationRequested(uint256 indexed projectId, address indexed requester);
    event AIEvaluationReceived(uint256 indexed projectId, uint256 score);
    event ProjectApproved(uint256 indexed projectId, address indexed creator, address indexed contributor, uint256 payoutAmount);
    event ProjectRejected(uint256 indexed projectId, address indexed creator, address indexed contributor, string reason);
    event DisputeInitiated(uint256 indexed projectId, address indexed initiator, string reason);
    event DisputeResolved(uint256 indexed projectId, address indexed winner, uint256 payoutToWinner);
    event FeesWithdrawn(address indexed owner, uint256 amount);
    event FeePercentageUpdated(uint256 oldPercentage, uint256 newPercentage);

    // --- Modifiers ---

    modifier onlyRegisteredUser() {
        require(userProfiles[_msgSender()].isRegistered, "QuantumLeap: User not registered.");
        _;
    }

    modifier onlyProjectCreator(uint256 _projectId) {
        require(projects[_projectId].creator == _msgSender(), "QuantumLeap: Only project creator can call this function.");
        _;
    }

    modifier onlySelectedContributor(uint256 _projectId) {
        require(projects[_projectId].selectedContributor == _msgSender(), "QuantumLeap: Only selected contributor can call this function.");
        _;
    }

    modifier onlyOracle() {
        require(_msgSender() == trustedAIO oracle, "QuantumLeap: Only the trusted AI oracle can call this function.");
        _;
    }

    // --- Constructor ---

    constructor(address _initialOracle, address _acceptedToken) Ownable(_msgSender()) {
        require(_initialOracle != address(0), "QuantumLeap: Initial oracle cannot be zero address.");
        require(_acceptedToken != address(0), "QuantumLeap: Accepted token cannot be zero address.");
        trustedAIO oracle = _initialOracle;
        acceptedToken = IERC20(_acceptedToken);
        nextProjectId = 1;
    }

    // --- I. Core Setup & Administration ---

    /**
     * @notice Allows the owner to update the address of the trusted AI oracle.
     * @param _newOracle The new address for the AI oracle.
     */
    function updateOracleAddress(address _newOracle) public onlyOwner {
        require(_newOracle != address(0), "QuantumLeap: New oracle cannot be zero address.");
        trustedAIO oracle = _newOracle;
    }

    /**
     * @notice Allows the owner to set the platform's fee percentage.
     * @param _newFeePercentage The new fee percentage (e.g., 500 for 5%). Max 10,000 (100%).
     */
    function setFeePercentage(uint256 _newFeePercentage) public onlyOwner {
        require(_newFeePercentage <= 10000, "QuantumLeap: Fee percentage cannot exceed 10000 (100%).");
        emit FeePercentageUpdated(feePercentage, _newFeePercentage);
        feePercentage = _newFeePercentage;
    }

    /**
     * @notice Allows the owner to withdraw accumulated fees from the contract.
     *         Uses the accepted ERC-20 token.
     */
    function withdrawFees() public onlyOwner {
        uint256 feesBalance = acceptedToken.balanceOf(address(this));
        uint256 totalProjectBudgets = 0;
        for (uint256 i = 1; i < nextProjectId; i++) {
            totalProjectBudgets = totalProjectBudgets.add(projects[i].budget);
        }
        
        // This calculates total fees based on approved projects.
        // A more robust system would track fees per project specifically.
        // For simplicity, we'll assume a running total or calculate from actual balance less held funds.
        // Let's refine this to only withdraw actual fees that have been settled.
        // For now, we'll assume `acceptedToken.balanceOf(address(this))` less active project budgets are fees.
        
        // A better approach would be to track `totalCollectedFees`.
        // Let's add a `uint256 public totalCollectedFees;` and update it in `approveProjectCompletion`.
        
        uint256 feesToWithdraw = totalCollectedFees;
        require(feesToWithdraw > 0, "QuantumLeap: No fees to withdraw.");
        totalCollectedFees = 0; // Reset after withdrawal

        acceptedToken.transfer(owner(), feesToWithdraw);
        emit FeesWithdrawn(owner(), feesToWithdraw);
    }
    uint256 public totalCollectedFees; // Added for better fee tracking

    /**
     * @notice Pauses contract operations. Only owner.
     */
    function pause() public onlyOwner whenNotPaused {
        _pause();
    }

    /**
     * @notice Unpauses contract operations. Only owner.
     */
    function unpause() public onlyOwner whenPaused {
        _unpause();
    }

    // --- II. User & Reputation Management ---

    /**
     * @notice Allows a user to register their profile.
     * @param _name User's display name.
     * @param _bio User's short biography.
     */
    function registerUser(string calldata _name, string calldata _bio) public whenNotPaused {
        require(!userProfiles[_msgSender()].isRegistered, "QuantumLeap: User already registered.");
        require(bytes(_name).length > 0, "QuantumLeap: Name cannot be empty.");

        UserProfile storage user = userProfiles[_msgSender()];
        user.name = _name;
        user.bio = _bio;
        user.reputationScore = 0;
        user.isRegistered = true;
        user.createdAt = block.timestamp;
        emit UserRegistered(_msgSender(), _name);
    }

    /**
     * @notice Allows a registered user to update their profile.
     * @param _newName New display name.
     * @param _newBio New biography.
     */
    function updateUserProfile(string calldata _newName, string calldata _newBio) public onlyRegisteredUser whenNotPaused {
        require(bytes(_newName).length > 0, "QuantumLeap: Name cannot be empty.");
        userProfiles[_msgSender()].name = _newName;
        userProfiles[_msgSender()].bio = _newBio;
        emit UserProfileUpdated(_msgSender(), _newName, _newBio);
    }

    /**
     * @notice Allows a user to add a skill to their profile.
     * @param _skill The skill to add.
     */
    function addSkill(string calldata _skill) public onlyRegisteredUser whenNotPaused {
        require(bytes(_skill).length > 0, "QuantumLeap: Skill cannot be empty.");
        UserProfile storage user = userProfiles[_msgSender()];
        require(!user.skills[_skill], "QuantumLeap: Skill already added.");
        user.skills[_skill] = true;
        user.declaredSkills.push(_skill);
        emit SkillAdded(_msgSender(), _skill);
    }

    /**
     * @notice Allows a user to remove a skill from their profile.
     * @param _skill The skill to remove.
     */
    function removeSkill(string calldata _skill) public onlyRegisteredUser whenNotPaused {
        require(userProfiles[_msgSender()].skills[_skill], "QuantumLeap: Skill not found.");
        userProfiles[_msgSender()].skills[_skill] = false;
        
        // Remove from the dynamic array as well (expensive, but necessary for retrieval)
        UserProfile storage user = userProfiles[_msgSender()];
        for (uint i = 0; i < user.declaredSkills.length; i++) {
            if (keccak256(abi.encodePacked(user.declaredSkills[i])) == keccak256(abi.encodePacked(_skill))) {
                user.declaredSkills[i] = user.declaredSkills[user.declaredSkills.length - 1];
                user.declaredSkills.pop();
                break;
            }
        }
        emit SkillRemoved(_msgSender(), _skill);
    }

    /**
     * @notice Determines the reputation tier for a given user.
     * @param _user The address of the user.
     * @return The reputation tier (Bronze, Silver, Gold, Platinum, Diamond).
     */
    function getReputationTier(address _user) public view returns (ReputationTier) {
        require(userProfiles[_user].isRegistered, "QuantumLeap: User not registered.");
        uint256 score = userProfiles[_user].reputationScore;
        if (score >= 1000) return ReputationTier.Diamond;
        if (score >= 500) return ReputationTier.Platinum;
        if (score >= 200) return ReputationTier.Gold;
        if (score >= 50) return ReputationTier.Silver;
        return ReputationTier.Bronze;
    }

    /**
     * @notice Retrieves a user's full profile details.
     * @param _user The address of the user.
     * @return name, bio, reputationScore, declaredSkills, isRegistered, createdAt.
     */
    function getUserProfile(address _user)
        public
        view
        returns (
            string memory name,
            string memory bio,
            uint256 reputationScore,
            string[] memory declaredSkills,
            bool isRegistered,
            uint256 createdAt
        )
    {
        UserProfile storage user = userProfiles[_user];
        return (
            user.name,
            user.bio,
            user.reputationScore,
            user.declaredSkills,
            user.isRegistered,
            user.createdAt
        );
    }

    // --- III. Project Creation & Lifecycle ---

    /**
     * @notice Allows a registered user to create a new project.
     *         The project budget must be approved and transferred to the contract.
     * @param _title Project title.
     * @param _description Project description.
     * @param _requiredSkills An array of skills required for the project.
     * @param _budget The budget for the project in the accepted ERC-20 token.
     * @param _deadline Unix timestamp by which the project must be completed.
     */
    function createProject(
        string calldata _title,
        string calldata _description,
        string[] calldata _requiredSkills,
        uint256 _budget,
        uint256 _deadline
    ) public onlyRegisteredUser whenNotPaused returns (uint256) {
        require(bytes(_title).length > 0, "QuantumLeap: Title cannot be empty.");
        require(_budget > 0, "QuantumLeap: Budget must be greater than zero.");
        require(_deadline > block.timestamp, "QuantumLeap: Deadline must be in the future.");
        require(_requiredSkills.length > 0, "QuantumLeap: At least one skill is required.");
        
        // Transfer budget from creator to contract
        require(acceptedToken.transferFrom(_msgSender(), address(this), _budget), "QuantumLeap: Token transfer failed.");

        Project storage newProject = projects[nextProjectId];
        newProject.creator = _msgSender();
        newProject.title = _title;
        newProject.description = _description;
        newProject.budget = _budget;
        newProject.deadline = _deadline;
        newProject.requiredSkills = _requiredSkills; // Copies array
        newProject.status = ProjectStatus.Open;
        newProject.createdAt = block.timestamp;

        userProjectsCreated[_msgSender()].push(nextProjectId);
        emit ProjectCreated(nextProjectId, _msgSender(), _budget, _deadline);
        nextProjectId++;
        return nextProjectId - 1;
    }

    /**
     * @notice Allows a project creator to cancel an open project.
     *         The budget is refunded to the creator.
     * @param _projectId The ID of the project to cancel.
     */
    function cancelProject(uint256 _projectId) public onlyProjectCreator(_projectId) whenNotPaused {
        Project storage project = projects[_projectId];
        require(project.status == ProjectStatus.Open, "QuantumLeap: Project is not open for cancellation.");
        
        project.status = ProjectStatus.Cancelled;
        acceptedToken.transfer(project.creator, project.budget); // Refund budget
        emit ProjectCancelled(_projectId, project.creator);
    }

    /**
     * @notice Allows a registered user to apply for an open project.
     *         User must possess all required skills.
     * @param _projectId The ID of the project to apply for.
     */
    function applyForProject(uint256 _projectId) public onlyRegisteredUser whenNotPaused {
        Project storage project = projects[_projectId];
        require(project.status == ProjectStatus.Open, "QuantumLeap: Project is not open for applications.");
        require(_msgSender() != project.creator, "QuantumLeap: Creator cannot apply for their own project.");
        require(projectApplications[_projectId][_msgSender()].applicant == address(0), "QuantumLeap: Already applied for this project.");

        // Check if applicant has all required skills
        UserProfile storage applicantProfile = userProfiles[_msgSender()];
        for (uint i = 0; i < project.requiredSkills.length; i++) {
            require(applicantProfile.skills[project.requiredSkills[i]], "QuantumLeap: Missing required skill.");
        }

        projectApplications[_projectId][_msgSender()] = Application({
            applicant: _msgSender(),
            projectId: _projectId,
            status: ApplicationStatus.Pending,
            appliedAt: block.timestamp
        });
        projectApplicantsList[_projectId].push(_msgSender());
        project.status = ProjectStatus.Applied; // Set status to applied if first applicant
        emit ProjectApplied(_projectId, _msgSender());
    }

    /**
     * @notice Allows the project creator to select a contributor from the applicants.
     * @param _projectId The ID of the project.
     * @param _contributor The address of the selected contributor.
     */
    function selectContributor(uint256 _projectId, address _contributor) public onlyProjectCreator(_projectId) whenNotPaused {
        Project storage project = projects[_projectId];
        require(project.status == ProjectStatus.Applied || project.status == ProjectStatus.Open, "QuantumLeap: Project not in an applicable state.");
        require(projectApplicantsList[_projectId].length > 0, "QuantumLeap: No applications for this project.");
        require(projectApplications[_projectId][_contributor].applicant == _contributor, "QuantumLeap: Contributor did not apply for this project.");
        require(projectApplications[_projectId][_contributor].status == ApplicationStatus.Pending, "QuantumLeap: Contributor already processed.");

        project.selectedContributor = _contributor;
        project.status = ProjectStatus.Selected;
        projectApplications[_projectId][_contributor].status = ApplicationStatus.Approved;

        // Reject other pending applications
        for (uint i = 0; i < projectApplicantsList[_projectId].length; i++) {
            address applicant = projectApplicantsList[_projectId][i];
            if (applicant != _contributor && projectApplications[_projectId][applicant].status == ApplicationStatus.Pending) {
                projectApplications[_projectId][applicant].status = ApplicationStatus.Rejected;
            }
        }
        emit ContributorSelected(_projectId, _msgSender(), _contributor);
    }

    /**
     * @notice Allows the selected contributor to submit their work.
     * @param _projectId The ID of the project.
     * @param _submissionHash IPFS CID or hash of the submitted work.
     */
    function submitProjectWork(uint256 _projectId, string calldata _submissionHash) public onlySelectedContributor(_projectId) whenNotPaused {
        Project storage project = projects[_projectId];
        require(project.status == ProjectStatus.Selected, "QuantumLeap: Project not in selected state.");
        require(bytes(_submissionHash).length > 0, "QuantumLeap: Submission hash cannot be empty.");
        require(block.timestamp <= project.deadline, "QuantumLeap: Submission past deadline.");

        project.submissionHash = _submissionHash;
        project.status = ProjectStatus.Submitted;
        emit WorkSubmitted(_projectId, _msgSender(), _submissionHash);
    }

    /**
     * @notice Allows the project creator to request an AI evaluation of the submitted work.
     *         This function simulates an external call to an AI oracle.
     * @param _projectId The ID of the project.
     */
    function requestAIEvaluation(uint256 _projectId) public onlyProjectCreator(_projectId) whenNotPaused {
        Project storage project = projects[_projectId];
        require(project.status == ProjectStatus.Submitted, "QuantumLeap: Work not submitted for evaluation.");
        require(project.submissionHash.length > 0, "QuantumLeap: No submission to evaluate.");

        project.status = ProjectStatus.AI_Evaluating;
        // In a real scenario, this would trigger an off-chain Chainlink request or similar.
        // For simulation, we'll assume the oracle calls back `receiveAIEvaluation`.
        emit AIEvaluationRequested(_projectId, _msgSender());
    }

    /**
     * @notice Callback function for the trusted AI oracle to submit evaluation results.
     * @param _projectId The ID of the project.
     * @param _score The AI's evaluation score (0-100).
     */
    function receiveAIEvaluation(uint256 _projectId, uint256 _score) public onlyOracle whenNotPaused {
        Project storage project = projects[_projectId];
        require(project.status == ProjectStatus.AI_Evaluating, "QuantumLeap: Project not in AI evaluation state.");
        require(_score <= 100, "QuantumLeap: AI score must be between 0 and 100.");

        project.aiEvaluationScore = _score;
        project.status = ProjectStatus.Submitted; // Revert to submitted state, creator can now approve/reject
        emit AIEvaluationReceived(_projectId, _score);
    }

    /**
     * @notice Allows the project creator to approve the submitted work.
     *         Transfers payment to the contributor and updates reputation.
     * @param _projectId The ID of the project.
     */
    function approveProjectCompletion(uint256 _projectId) public onlyProjectCreator(_projectId) whenNotPaused {
        Project storage project = projects[_projectId];
        require(project.status == ProjectStatus.Submitted, "QuantumLeap: Project not in submitted state.");
        require(block.timestamp <= project.deadline.add(7 days), "QuantumLeap: Approval window closed (7 days after deadline)."); // Grace period

        address contributor = project.selectedContributor;
        uint256 payoutAmount = project.budget;
        uint256 fee = payoutAmount.mul(feePercentage).div(10000);
        payoutAmount = payoutAmount.sub(fee);

        require(acceptedToken.transfer(contributor, payoutAmount), "QuantumLeap: Payment to contributor failed.");
        totalCollectedFees = totalCollectedFees.add(fee); // Collect fee
        
        project.status = ProjectStatus.Approved;
        project.completedAt = block.timestamp;
        project.feeAmount = fee; // Record actual fee for this project

        // Update contributor's reputation
        userProfiles[contributor].reputationScore = userProfiles[contributor].reputationScore.add(10); // Example reputation gain
        userProjectsContributed[contributor].push(_projectId);

        emit ProjectApproved(_projectId, _msgSender(), contributor, payoutAmount);
    }

    /**
     * @notice Allows the project creator to reject the submitted work.
     *         Can lead to a dispute if the contributor disagrees.
     * @param _projectId The ID of the project.
     * @param _reason The reason for rejection.
     */
    function rejectProjectCompletion(uint256 _projectId, string calldata _reason) public onlyProjectCreator(_projectId) whenNotPaused {
        Project storage project = projects[_projectId];
        require(project.status == ProjectStatus.Submitted, "QuantumLeap: Project not in submitted state.");
        require(bytes(_reason).length > 0, "QuantumLeap: Rejection reason cannot be empty.");

        project.status = ProjectStatus.Rejected;
        emit ProjectRejected(_projectId, _msgSender(), project.selectedContributor, _reason);
    }

    /**
     * @notice Allows either the creator or contributor to initiate a dispute.
     * @param _projectId The ID of the project.
     * @param _reason The reason for initiating the dispute.
     */
    function initiateDispute(uint256 _projectId, string calldata _reason) public whenNotPaused {
        Project storage project = projects[_projectId];
        require(project.disputeStatus == DisputeStatus.None, "QuantumLeap: Dispute already initiated or resolved.");
        require(project.status == ProjectStatus.Rejected || (project.status == ProjectStatus.Submitted && block.timestamp > project.deadline.add(7 days)), "QuantumLeap: Project not in a state for dispute initiation.");
        require(_msgSender() == project.creator || _msgSender() == project.selectedContributor, "QuantumLeap: Only creator or contributor can initiate dispute.");
        require(bytes(_reason).length > 0, "QuantumLeap: Dispute reason cannot be empty.");

        project.disputeStatus = DisputeStatus.Initiated;
        project.status = ProjectStatus.Disputed; // Change project status to disputed
        emit DisputeInitiated(_projectId, _msgSender(), _reason);
    }

    /**
     * @notice Admin function to resolve a dispute, determining the winner and payout.
     * @param _projectId The ID of the project.
     * @param _winner The address of the party who won the dispute (creator or contributor).
     * @param _payoutToWinner The amount to be paid to the winner (can be partial or full budget).
     */
    function resolveDisputeByArbitrator(uint256 _projectId, address _winner, uint256 _payoutToWinner) public onlyOwner whenNotPaused {
        Project storage project = projects[_projectId];
        require(project.disputeStatus == DisputeStatus.Initiated, "QuantumLeap: No active dispute for this project.");
        require(_winner == project.creator || _winner == project.selectedContributor, "QuantumLeap: Winner must be creator or contributor.");
        require(_payoutToWinner <= project.budget, "QuantumLeap: Payout cannot exceed project budget.");

        uint256 remainingBudget = project.budget.sub(_payoutToWinner);

        // Payout to winner
        if (_payoutToWinner > 0) {
            uint256 fee = _payoutToWinner.mul(feePercentage).div(10000);
            uint256 netPayout = _payoutToWinner.sub(fee);
            require(acceptedToken.transfer(_winner, netPayout), "QuantumLeap: Dispute payout failed.");
            totalCollectedFees = totalCollectedFees.add(fee); // Collect fee on payout
            project.feeAmount = project.feeAmount.add(fee); // Track fees
        }

        // Handle remaining funds (e.g., refund to creator if contributor wins partially, or vice-versa)
        // For simplicity, remaining budget after dispute goes back to creator unless explicitly defined otherwise.
        if (remainingBudget > 0 && _winner == project.selectedContributor) {
            acceptedToken.transfer(project.creator, remainingBudget);
        } else if (remainingBudget > 0 && _winner == project.creator) {
            // Funds stay in contract (or are considered fees depending on policy) if contributor lost completely
            // For now, if creator wins, remaining budget stays in contract and can be withdrawn by creator later if desired
            // Or it can be considered additional fees. Let's make it go to creator.
            acceptedToken.transfer(project.creator, remainingBudget);
        }

        project.disputeStatus = DisputeStatus.Resolved;
        project.status = ProjectStatus.Approved; // Mark as approved/resolved
        project.completedAt = block.timestamp;

        // Update reputation based on dispute outcome (simplified)
        if (_winner == project.selectedContributor) {
            userProfiles[_winner].reputationScore = userProfiles[_winner].reputationScore.add(5);
        } else if (_winner == project.creator) {
            // Potentially deduct reputation from contributor
            if (userProfiles[project.selectedContributor].reputationScore >= 5) {
                userProfiles[project.selectedContributor].reputationScore = userProfiles[project.selectedContributor].reputationScore.sub(5);
            } else {
                userProfiles[project.selectedContributor].reputationScore = 0;
            }
        }
        emit DisputeResolved(_projectId, _winner, _payoutToWinner);
    }
    
    // --- View Functions ---

    /**
     * @notice Retrieves the details of a specific project.
     * @param _projectId The ID of the project.
     * @return All project fields.
     */
    function getProjectDetails(uint256 _projectId)
        public
        view
        returns (
            address creator,
            string memory title,
            string memory description,
            uint256 budget,
            uint256 deadline,
            string[] memory requiredSkills,
            ProjectStatus status,
            address selectedContributor,
            string memory submissionHash,
            uint256 aiEvaluationScore,
            DisputeStatus disputeStatus,
            uint256 createdAt,
            uint256 completedAt,
            uint256 feeAmount
        )
    {
        Project storage project = projects[_projectId];
        return (
            project.creator,
            project.title,
            project.description,
            project.budget,
            project.deadline,
            project.requiredSkills,
            project.status,
            project.selectedContributor,
            project.submissionHash,
            project.aiEvaluationScore,
            project.disputeStatus,
            project.createdAt,
            project.completedAt,
            project.feeAmount
        );
    }

    /**
     * @notice Retrieves all applicants for a specific project.
     * @param _projectId The ID of the project.
     * @return An array of applicant addresses.
     */
    function getApplicationsForProject(uint256 _projectId) public view returns (address[] memory) {
        return projectApplicantsList[_projectId];
    }

    /**
     * @notice Retrieves a list of projects created by a specific user.
     * @param _user The address of the user.
     * @return An array of project IDs.
     */
    function getProjectsByUser(address _user) public view returns (uint256[] memory) {
        return userProjectsCreated[_user];
    }

    /**
     * @notice Retrieves a list of skills declared by a specific user.
     * @param _user The address of the user.
     * @return An array of skill strings.
     */
    function getUserSkills(address _user) public view returns (string[] memory) {
        return userProfiles[_user].declaredSkills;
    }
}
```