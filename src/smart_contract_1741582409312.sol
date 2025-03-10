```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Decentralized Autonomous Creative Agency (DACA)
 * @author Bard (AI Assistant)
 * @dev A smart contract implementing a decentralized autonomous creative agency.
 *
 * Outline and Function Summary:
 *
 * 1.  **Contract Initialization and Agency Settings:**
 *     - `constructor(address _agencyOwner, string _agencyName)`: Initializes the contract, sets agency owner and name.
 *     - `setAgencyFee(uint256 _feePercentage)`: Allows the agency owner to set the platform fee percentage.
 *     - `setAgencyName(string _newName)`: Allows the agency owner to change the agency name.
 *
 * 2.  **Creative Profile Management:**
 *     - `registerCreative(string _name, string _portfolioLink, string[] memory _skills)`: Allows creatives to register their profile with skills and portfolio link.
 *     - `updateCreativeProfile(string _name, string _portfolioLink, string[] memory _skills)`: Allows creatives to update their profile information.
 *     - `getCreativeProfile(address _creativeAddress) external view returns (string memory name, string memory portfolioLink, string[] memory skills, uint256 rating)`: Retrieves a creative's profile information.
 *     - `addSkillToCreativeProfile(string memory _skill)`: Allows creatives to add new skills to their profile.
 *     - `removeSkillFromCreativeProfile(string memory _skill)`: Allows creatives to remove skills from their profile.
 *
 * 3.  **Client Project Management:**
 *     - `createProject(string _projectName, string _projectBrief, uint256 _budget, uint256 _deadline)`: Allows clients to create new projects, specifying details and budget.
 *     - `updateProjectBrief(uint256 _projectId, string memory _newBrief)`: Allows clients to update the project brief.
 *     - `cancelProject(uint256 _projectId)`: Allows clients to cancel a project before it's started (with potential refund logic).
 *     - `depositFundsForProject(uint256 _projectId) payable`: Allows clients to deposit funds into the contract for a specific project.
 *     - `getProjectDetails(uint256 _projectId) external view returns (string memory projectName, string memory projectBrief, address client, uint256 budget, uint256 deadline, uint256 fundsDeposited, ProjectStatus status)`: Retrieves detailed information about a project.
 *
 * 4.  **Proposal and Bidding System:**
 *     - `submitProposal(uint256 _projectId, string memory _proposalDetails, uint256 _bidAmount)`: Allows registered creatives to submit proposals for projects.
 *     - `acceptProposal(uint256 _projectId, address _creativeAddress)`: Allows clients to accept a proposal from a creative for their project.
 *     - `rejectProposal(uint256 _projectId, address _creativeAddress)`: Allows clients to reject a proposal.
 *     - `getProjectProposals(uint256 _projectId) external view returns (Proposal[] memory)`: Retrieves all proposals submitted for a specific project.
 *
 * 5.  **Milestone and Payment Management:**
 *     - `addMilestone(uint256 _projectId, string memory _milestoneDescription, uint256 _milestoneValue)`: Allows clients (or agency in future versions) to add milestones to a project.
 *     - `markMilestoneComplete(uint256 _projectId, uint256 _milestoneId)`: Allows creatives to mark a milestone as completed.
 *     - `approveMilestone(uint256 _projectId, uint256 _milestoneId)`: Allows clients to approve a completed milestone, triggering payment release.
 *     - `requestMilestoneRevision(uint256 _projectId, uint256 _milestoneId, string memory _revisionNotes)`: Allows clients to request revisions for a completed milestone.
 *     - `releasePaymentToCreative(uint256 _projectId, address _creativeAddress, uint256 _amount)`: (Internal/Agency controlled) Releases payment to the creative after milestone approval (can be triggered automatically in `approveMilestone`).
 *
 * 6.  **Reputation and Review System:**
 *     - `submitCreativeReview(address _creativeAddress, uint256 _rating, string memory _reviewText)`: Allows clients to submit reviews and ratings for creatives after project completion.
 *     - `submitClientReview(uint256 _projectId, uint256 _rating, string memory _reviewText)`: Allows creatives to submit reviews and ratings for clients after project completion.
 *     - `getAverageCreativeRating(address _creativeAddress) external view returns (uint256)`: Retrieves the average rating for a creative.
 *
 * 7.  **Dispute Resolution (Basic - can be expanded):**
 *     - `openDispute(uint256 _projectId, string memory _disputeReason)`: Allows clients or creatives to open a dispute on a project.
 *     - `resolveDispute(uint256 _projectId, address _winner, string memory _resolutionDetails)`: (Agency/Admin function) Allows the agency owner to resolve a dispute and allocate funds.
 *
 * 8.  **Emergency and Admin Functions (Agency Owner):**
 *     - `pauseContract()`: Allows the agency owner to pause the contract in case of emergency.
 *     - `unpauseContract()`: Allows the agency owner to unpause the contract.
 *     - `withdrawAgencyFees()`: Allows the agency owner to withdraw accumulated agency fees.
 *     - `emergencyWithdraw(address payable _recipient)`: Allows the agency owner to withdraw all contract balance in case of extreme emergency.
 */

contract DecentralizedAutonomousCreativeAgency {
    // Agency Owner and Settings
    address public agencyOwner;
    string public agencyName;
    uint256 public agencyFeePercentage; // Percentage fee charged by the agency

    // Data Structures
    struct CreativeProfile {
        string name;
        string portfolioLink;
        string[] skills;
        uint256 rating; // Average rating, could be more complex in future
        uint256 reviewCount;
    }

    struct Project {
        string projectName;
        string projectBrief;
        address client;
        uint256 budget;
        uint256 deadline; // Timestamp for deadline
        uint256 fundsDeposited;
        ProjectStatus status;
        address assignedCreative;
        uint256 proposalIdCounter;
        mapping(uint256 => Proposal) proposals; // Proposal ID => Proposal
        uint256 milestoneIdCounter;
        mapping(uint256 => Milestone) milestones; // Milestone ID => Milestone
    }

    struct Proposal {
        address creative;
        uint256 projectId;
        string proposalDetails;
        uint256 bidAmount;
        ProposalStatus status;
    }

    struct Milestone {
        string description;
        uint256 value; // Value in project budget percentage or fixed amount
        MilestoneStatus status;
        uint256 deadline; // Optional milestone deadline
        string revisionNotes;
    }

    struct Review {
        address reviewer;
        uint256 rating;
        string reviewText;
        uint256 timestamp;
    }

    // Enums
    enum ProjectStatus { Open, ProposalStage, InProgress, MilestoneReview, Completed, Disputed, Cancelled, Closed }
    enum ProposalStatus { Submitted, Accepted, Rejected }
    enum MilestoneStatus { Pending, Completed, Approved, RevisionRequested, Paid }

    // State Variables
    mapping(address => CreativeProfile) public creativeProfiles;
    mapping(uint256 => Project) public projects;
    uint256 public projectCounter;
    mapping(uint256 => Proposal) public proposals; // Keeping separate for easier access if needed
    uint256 public proposalCounter;

    mapping(address => Review[]) public creativeReviews; // Creative address to list of reviews
    mapping(uint256 => Review[]) public clientReviews; // Project ID to list of client reviews

    bool public paused; // Contract pause state
    uint256 public agencyFeesBalance; // Accumulated agency fees

    // Events
    event AgencyFeeSet(uint256 feePercentage);
    event AgencyNameChanged(string newName);
    event CreativeRegistered(address creativeAddress, string name);
    event CreativeProfileUpdated(address creativeAddress);
    event ProjectCreated(uint256 projectId, string projectName, address client);
    event ProjectBriefUpdated(uint256 projectId);
    event ProjectCancelled(uint256 projectId);
    event FundsDeposited(uint256 projectId, address client, uint256 amount);
    event ProposalSubmitted(uint256 proposalId, uint256 projectId, address creative);
    event ProposalAccepted(uint256 proposalId, uint256 projectId, address creative);
    event ProposalRejected(uint256 proposalId, uint256 projectId, address creative);
    event MilestoneAdded(uint256 projectId, uint256 milestoneId);
    event MilestoneMarkedComplete(uint256 projectId, uint256 milestoneId);
    event MilestoneApproved(uint256 projectId, uint256 milestoneId);
    event MilestoneRevisionRequested(uint256 projectId, uint256 milestoneId);
    event PaymentReleased(uint256 projectId, address creative, uint256 amount);
    event CreativeReviewSubmitted(address creativeAddress, uint256 rating);
    event ClientReviewSubmitted(uint256 projectId, uint256 rating);
    event DisputeOpened(uint256 projectId, address initiator, string reason);
    event DisputeResolved(uint256 projectId, address winner, string resolution);
    event ContractPaused();
    event ContractUnpaused();
    event AgencyFeesWithdrawn(uint256 amount, address recipient);
    event EmergencyWithdrawal(address recipient, uint256 amount);

    // Modifiers
    modifier onlyAgencyOwner() {
        require(msg.sender == agencyOwner, "Only agency owner can call this function.");
        _;
    }

    modifier onlyCreative() {
        require(creativeProfiles[msg.sender].name.length > 0, "Only registered creatives can call this function.");
        _;
    }

    modifier onlyClient(uint256 _projectId) {
        require(projects[_projectId].client == msg.sender, "Only the project client can call this function.");
        _;
    }

    modifier projectExists(uint256 _projectId) {
        require(_projectId < projectCounter && projects[_projectId].projectName.length > 0, "Project does not exist.");
        _;
    }

    modifier proposalExists(uint256 _proposalId) {
        require(_proposalId < proposalCounter && proposals[_proposalId].proposalDetails.length > 0, "Proposal does not exist.");
        _;
    }

    modifier milestoneExists(uint256 _projectId, uint256 _milestoneId) {
        require(_milestoneId < projects[_projectId].milestoneIdCounter && projects[_projectId].milestones[_milestoneId].description.length > 0, "Milestone does not exist.");
        _;
    }

    modifier isProjectStatus(uint256 _projectId, ProjectStatus _status) {
        require(projects[_projectId].status == _status, "Project status is not valid for this action.");
        _;
    }

    modifier isNotPaused() {
        require(!paused, "Contract is paused.");
        _;
    }

    // Constructor
    constructor(address _agencyOwner, string memory _agencyName) {
        agencyOwner = _agencyOwner;
        agencyName = _agencyName;
        agencyFeePercentage = 5; // Default agency fee percentage
        emit AgencyNameChanged(_agencyName);
    }

    // ------------------------------------------------------------------------
    // 1. Contract Initialization and Agency Settings
    // ------------------------------------------------------------------------

    /**
     * @dev Sets the agency fee percentage. Only callable by the agency owner.
     * @param _feePercentage The new agency fee percentage.
     */
    function setAgencyFee(uint256 _feePercentage) external onlyAgencyOwner isNotPaused {
        require(_feePercentage <= 100, "Fee percentage must be between 0 and 100.");
        agencyFeePercentage = _feePercentage;
        emit AgencyFeeSet(_feePercentage);
    }

    /**
     * @dev Sets the agency name. Only callable by the agency owner.
     * @param _newName The new agency name.
     */
    function setAgencyName(string memory _newName) external onlyAgencyOwner isNotPaused {
        agencyName = _newName;
        emit AgencyNameChanged(_newName);
    }

    // ------------------------------------------------------------------------
    // 2. Creative Profile Management
    // ------------------------------------------------------------------------

    /**
     * @dev Registers a creative profile.
     * @param _name The creative's name.
     * @param _portfolioLink Link to the creative's portfolio.
     * @param _skills Array of skills the creative possesses.
     */
    function registerCreative(string memory _name, string memory _portfolioLink, string[] memory _skills) external isNotPaused {
        require(creativeProfiles[msg.sender].name.length == 0, "Creative profile already exists.");
        creativeProfiles[msg.sender] = CreativeProfile({
            name: _name,
            portfolioLink: _portfolioLink,
            skills: _skills,
            rating: 0,
            reviewCount: 0
        });
        emit CreativeRegistered(msg.sender, _name);
    }

    /**
     * @dev Updates a creative's profile information.
     * @param _name The creative's name.
     * @param _portfolioLink Link to the creative's portfolio.
     * @param _skills Array of skills the creative possesses.
     */
    function updateCreativeProfile(string memory _name, string memory _portfolioLink, string[] memory _skills) external onlyCreative isNotPaused {
        creativeProfiles[msg.sender].name = _name;
        creativeProfiles[msg.sender].portfolioLink = _portfolioLink;
        creativeProfiles[msg.sender].skills = _skills;
        emit CreativeProfileUpdated(msg.sender);
    }

    /**
     * @dev Retrieves a creative's profile information.
     * @param _creativeAddress The address of the creative.
     * @return name Creative's name.
     * @return portfolioLink Creative's portfolio link.
     * @return skills Array of creative's skills.
     * @return rating Average rating of the creative.
     */
    function getCreativeProfile(address _creativeAddress) external view returns (string memory name, string memory portfolioLink, string[] memory skills, uint256 rating) {
        CreativeProfile memory profile = creativeProfiles[_creativeAddress];
        return (profile.name, profile.portfolioLink, profile.skills, profile.rating);
    }

    /**
     * @dev Adds a skill to a creative's profile.
     * @param _skill The skill to add.
     */
    function addSkillToCreativeProfile(string memory _skill) external onlyCreative isNotPaused {
        bool skillExists = false;
        for (uint i = 0; i < creativeProfiles[msg.sender].skills.length; i++) {
            if (keccak256(abi.encodePacked(creativeProfiles[msg.sender].skills[i])) == keccak256(abi.encodePacked(_skill))) {
                skillExists = true;
                break;
            }
        }
        require(!skillExists, "Skill already exists in profile.");
        creativeProfiles[msg.sender].skills.push(_skill);
        emit CreativeProfileUpdated(msg.sender);
    }

    /**
     * @dev Removes a skill from a creative's profile.
     * @param _skill The skill to remove.
     */
    function removeSkillFromCreativeProfile(string memory _skill) external onlyCreative isNotPaused {
        bool skillRemoved = false;
        string[] memory currentSkills = creativeProfiles[msg.sender].skills;
        string[] memory updatedSkills;
        for (uint i = 0; i < currentSkills.length; i++) {
            if (keccak256(abi.encodePacked(currentSkills[i])) != keccak256(abi.encodePacked(_skill))) {
                updatedSkills.push(currentSkills[i]); // Not efficient, consider better approach for large arrays in real app
            } else {
                skillRemoved = true;
            }
        }
        require(skillRemoved, "Skill not found in profile.");
        creativeProfiles[msg.sender].skills = updatedSkills;
        emit CreativeProfileUpdated(msg.sender);
    }

    // ------------------------------------------------------------------------
    // 3. Client Project Management
    // ------------------------------------------------------------------------

    /**
     * @dev Creates a new project.
     * @param _projectName The name of the project.
     * @param _projectBrief A brief description of the project.
     * @param _budget The budget allocated for the project in wei.
     * @param _deadline Timestamp for project deadline.
     */
    function createProject(string memory _projectName, string memory _projectBrief, uint256 _budget, uint256 _deadline) external isNotPaused {
        require(_budget > 0, "Budget must be greater than zero.");
        projectCounter++;
        projects[projectCounter] = Project({
            projectName: _projectName,
            projectBrief: _projectBrief,
            client: msg.sender,
            budget: _budget,
            deadline: _deadline,
            fundsDeposited: 0,
            status: ProjectStatus.Open,
            assignedCreative: address(0),
            proposalIdCounter: 0,
            milestoneIdCounter: 0
        });
        emit ProjectCreated(projectCounter, _projectName, msg.sender);
    }

    /**
     * @dev Updates the brief description of a project. Only callable by the client.
     * @param _projectId The ID of the project.
     * @param _newBrief The new project brief.
     */
    function updateProjectBrief(uint256 _projectId, string memory _newBrief) external onlyClient(_projectId) projectExists(_projectId) isProjectStatus(_projectId, ProjectStatus.Open) isNotPaused {
        projects[_projectId].projectBrief = _newBrief;
        emit ProjectBriefUpdated(_projectId);
    }

    /**
     * @dev Cancels a project. Only callable by the client before project starts (Open or ProposalStage).
     * @param _projectId The ID of the project to cancel.
     */
    function cancelProject(uint256 _projectId) external onlyClient(_projectId) projectExists(_projectId) isProjectStatus(_projectId, ProjectStatus.Open) isNotPaused {
        projects[_projectId].status = ProjectStatus.Cancelled;
        // Future: Implement refund logic for deposited funds if applicable.
        emit ProjectCancelled(_projectId);
    }

    /**
     * @dev Allows clients to deposit funds into the contract for a specific project.
     * @param _projectId The ID of the project to deposit funds for.
     */
    function depositFundsForProject(uint256 _projectId) external payable onlyClient(_projectId) projectExists(_projectId) isProjectStatus(_projectId, ProjectStatus.ProposalStage) isNotPaused {
        require(msg.value > 0, "Deposit amount must be greater than zero.");
        projects[_projectId].fundsDeposited += msg.value;
        require(projects[_projectId].fundsDeposited <= projects[_projectId].budget, "Deposited funds exceed project budget.");
        emit FundsDeposited(_projectId, msg.sender, msg.value);
    }

    /**
     * @dev Retrieves detailed information about a project.
     * @param _projectId The ID of the project.
     * @return projectName Project's name.
     * @return projectBrief Project's brief description.
     * @return client Address of the client who created the project.
     * @return budget Project's budget.
     * @return deadline Project's deadline timestamp.
     * @return fundsDeposited Funds deposited for the project.
     * @return status Project's current status.
     */
    function getProjectDetails(uint256 _projectId) external view projectExists(_projectId) returns (string memory projectName, string memory projectBrief, address client, uint256 budget, uint256 deadline, uint256 fundsDeposited, ProjectStatus status) {
        Project memory project = projects[_projectId];
        return (project.projectName, project.projectBrief, project.client, project.budget, project.deadline, project.fundsDeposited, project.status);
    }

    // ------------------------------------------------------------------------
    // 4. Proposal and Bidding System
    // ------------------------------------------------------------------------

    /**
     * @dev Allows registered creatives to submit proposals for projects.
     * @param _projectId The ID of the project to submit a proposal for.
     * @param _proposalDetails Details of the proposal.
     * @param _bidAmount The bid amount for the project.
     */
    function submitProposal(uint256 _projectId, string memory _proposalDetails, uint256 _bidAmount) external onlyCreative projectExists(_projectId) isProjectStatus(_projectId, ProjectStatus.Open) isNotPaused {
        projects[_projectId].proposalIdCounter++;
        uint256 proposalId = projects[_projectId].proposalIdCounter;
        Proposal storage newProposal = projects[_projectId].proposals[proposalId]; // Store within project mapping
        newProposal.creative = msg.sender;
        newProposal.projectId = _projectId;
        newProposal.proposalDetails = _proposalDetails;
        newProposal.bidAmount = _bidAmount;
        newProposal.status = ProposalStatus.Submitted;

        proposals[proposalCounter] = newProposal; // Keep a separate global list if needed for easier querying
        proposalCounter++;

        emit ProposalSubmitted(proposalCounter -1, _projectId, msg.sender);
        projects[_projectId].status = ProjectStatus.ProposalStage; // Move project to proposal stage
    }

    /**
     * @dev Allows clients to accept a proposal from a creative for their project.
     * @param _projectId The ID of the project.
     * @param _creativeAddress The address of the creative whose proposal is accepted.
     */
    function acceptProposal(uint256 _projectId, address _creativeAddress) external onlyClient(_projectId) projectExists(_projectId) isProjectStatus(_projectId, ProjectStatus.ProposalStage) isNotPaused {
        bool proposalFound = false;
        uint256 acceptedProposalId;
        for (uint256 i = 1; i <= projects[_projectId].proposalIdCounter; i++) {
            if (projects[_projectId].proposals[i].creative == _creativeAddress && projects[_projectId].proposals[i].status == ProposalStatus.Submitted) {
                projects[_projectId].proposals[i].status = ProposalStatus.Accepted;
                acceptedProposalId = i;
                proposalFound = true;
                break;
            }
        }
        require(proposalFound, "Submitted proposal from this creative not found for this project.");

        projects[_projectId].assignedCreative = _creativeAddress;
        projects[_projectId].status = ProjectStatus.InProgress;
        emit ProposalAccepted(acceptedProposalId, _projectId, _creativeAddress);
    }

    /**
     * @dev Allows clients to reject a proposal from a creative for their project.
     * @param _projectId The ID of the project.
     * @param _creativeAddress The address of the creative whose proposal is rejected.
     */
    function rejectProposal(uint256 _projectId, address _creativeAddress) external onlyClient(_projectId) projectExists(_projectId) isProjectStatus(_projectId, ProjectStatus.ProposalStage) isNotPaused {
         bool proposalFound = false;
        uint256 rejectedProposalId;
        for (uint256 i = 1; i <= projects[_projectId].proposalIdCounter; i++) {
            if (projects[_projectId].proposals[i].creative == _creativeAddress && projects[_projectId].proposals[i].status == ProposalStatus.Submitted) {
                projects[_projectId].proposals[i].status = ProposalStatus.Rejected;
                rejectedProposalId = i;
                proposalFound = true;
                break;
            }
        }
        require(proposalFound, "Submitted proposal from this creative not found for this project.");
        emit ProposalRejected(rejectedProposalId, _projectId, _creativeAddress);
    }

    /**
     * @dev Retrieves all proposals submitted for a specific project.
     * @param _projectId The ID of the project.
     * @return Array of proposals for the project.
     */
    function getProjectProposals(uint256 _projectId) external view projectExists(_projectId) returns (Proposal[] memory) {
        uint256 proposalCount = projects[_projectId].proposalIdCounter;
        Proposal[] memory projectProposals = new Proposal[](proposalCount);
        uint256 index = 0;
        for (uint256 i = 1; i <= proposalCount; i++) {
            if (projects[_projectId].proposals[i].proposalDetails.length > 0) { // Check if proposal exists (might be gaps if proposals are deleted in future)
                projectProposals[index] = projects[_projectId].proposals[i];
                index++;
            }
        }
        // Resize array to actual number of proposals
        Proposal[] memory trimmedProposals = new Proposal[](index);
        for (uint256 i = 0; i < index; i++) {
            trimmedProposals[i] = projectProposals[i];
        }
        return trimmedProposals;
    }

    // ------------------------------------------------------------------------
    // 5. Milestone and Payment Management
    // ------------------------------------------------------------------------

    /**
     * @dev Adds a milestone to a project. Only callable by the client.
     * @param _projectId The ID of the project.
     * @param _milestoneDescription Description of the milestone.
     * @param _milestoneValue Value of the milestone in wei.
     */
    function addMilestone(uint256 _projectId, string memory _milestoneDescription, uint256 _milestoneValue) external onlyClient(_projectId) projectExists(_projectId) isProjectStatus(_projectId, ProjectStatus.InProgress) isNotPaused {
        require(_milestoneValue > 0, "Milestone value must be greater than zero.");
        projects[_projectId].milestoneIdCounter++;
        uint256 milestoneId = projects[_projectId].milestoneIdCounter;
        projects[_projectId].milestones[milestoneId] = Milestone({
            description: _milestoneDescription,
            value: _milestoneValue,
            status: MilestoneStatus.Pending,
            deadline: 0, // Optional deadline, can be set later
            revisionNotes: ""
        });
        emit MilestoneAdded(_projectId, milestoneId);
    }

    /**
     * @dev Marks a milestone as completed by the assigned creative.
     * @param _projectId The ID of the project.
     * @param _milestoneId The ID of the milestone.
     */
    function markMilestoneComplete(uint256 _projectId, uint256 _milestoneId) external onlyCreative projectExists(_projectId) milestoneExists(_projectId, _milestoneId) isProjectStatus(_projectId, ProjectStatus.InProgress) isNotPaused {
        require(projects[_projectId].assignedCreative == msg.sender, "Only assigned creative can mark milestone complete.");
        projects[_projectId].milestones[_milestoneId].status = MilestoneStatus.Completed;
        emit MilestoneMarkedComplete(_projectId, _milestoneId);
        projects[_projectId].status = ProjectStatus.MilestoneReview; // Move project to milestone review stage
    }

    /**
     * @dev Approves a completed milestone by the client. Releases payment to the creative.
     * @param _projectId The ID of the project.
     * @param _milestoneId The ID of the milestone.
     */
    function approveMilestone(uint256 _projectId, uint256 _milestoneId) external payable onlyClient(_projectId) projectExists(_projectId) milestoneExists(_projectId, _milestoneId) isProjectStatus(_projectId, ProjectStatus.MilestoneReview) isNotPaused {
        require(projects[_projectId].milestones[_milestoneId].status == MilestoneStatus.Completed, "Milestone is not marked as completed.");
        require(projects[_projectId].fundsDeposited >= projects[_projectId].milestones[_milestoneId].value, "Insufficient funds deposited for milestone payment.");

        uint256 milestoneValue = projects[_projectId].milestones[_milestoneId].value;
        address creativeAddress = projects[_projectId].assignedCreative;

        // Calculate agency fee
        uint256 agencyFee = (milestoneValue * agencyFeePercentage) / 100;
        uint256 creativePayment = milestoneValue - agencyFee;

        // Transfer payment to creative
        (bool successCreative, ) = payable(creativeAddress).call{value: creativePayment}("");
        require(successCreative, "Payment to creative failed.");

        // Transfer agency fee to contract balance
        agencyFeesBalance += agencyFee;

        projects[_projectId].fundsDeposited -= milestoneValue; // Deduct milestone value from deposited funds
        projects[_projectId].milestones[_milestoneId].status = MilestoneStatus.Approved;
        emit MilestoneApproved(_projectId, _milestoneId);
        emit PaymentReleased(_projectId, creativeAddress, creativePayment);

        // Check if all milestones are approved, then complete the project
        bool allMilestonesApproved = true;
        for (uint256 i = 1; i <= projects[_projectId].milestoneIdCounter; i++) {
            if (projects[_projectId].milestones[i].status != MilestoneStatus.Approved && projects[_projectId].milestones[i].description.length > 0) {
                allMilestonesApproved = false;
                break;
            }
        }
        if (allMilestonesApproved) {
            projects[_projectId].status = ProjectStatus.Completed;
        } else {
            projects[_projectId].status = ProjectStatus.InProgress; // Back to in progress if not all milestones done
        }
    }

    /**
     * @dev Requests revision for a completed milestone by the client.
     * @param _projectId The ID of the project.
     * @param _milestoneId The ID of the milestone.
     * @param _revisionNotes Notes detailing the revisions requested.
     */
    function requestMilestoneRevision(uint256 _projectId, uint256 _milestoneId, string memory _revisionNotes) external onlyClient(_projectId) projectExists(_projectId) milestoneExists(_projectId, _milestoneId) isProjectStatus(_projectId, ProjectStatus.MilestoneReview) isNotPaused {
        require(projects[_projectId].milestones[_milestoneId].status == MilestoneStatus.Completed, "Milestone is not marked as completed.");
        projects[_projectId].milestones[_milestoneId].status = MilestoneStatus.RevisionRequested;
        projects[_projectId].milestones[_milestoneId].revisionNotes = _revisionNotes;
        projects[_projectId].status = ProjectStatus.InProgress; // Back to in progress after revision request
        emit MilestoneRevisionRequested(_projectId, _milestoneId);
    }

    // Internal function for payment release (can be extended for more complex logic later)
    function releasePaymentToCreative(uint256 _projectId, address _creativeAddress, uint256 _amount) internal {
        // In this basic version, payment is handled directly in `approveMilestone`.
        // This function is kept as a placeholder for potential future more complex payment logic.
        (bool success, ) = payable(_creativeAddress).call{value: _amount}("");
        require(success, "Payment transfer failed.");
        emit PaymentReleased(_projectId, _creativeAddress, _amount);
    }

    // ------------------------------------------------------------------------
    // 6. Reputation and Review System
    // ------------------------------------------------------------------------

    /**
     * @dev Allows clients to submit reviews and ratings for creatives after project completion.
     * @param _creativeAddress The address of the creative to review.
     * @param _rating The rating given (e.g., 1-5).
     * @param _reviewText Textual review of the creative.
     */
    function submitCreativeReview(address _creativeAddress, uint256 _rating, string memory _reviewText) external projectExists(projectCounter) isProjectStatus(projectCounter, ProjectStatus.Completed) isNotPaused { // Assuming review after last project created for simplicity, adjust project ID logic as needed
        require(projects[projectCounter].client == msg.sender, "Only project client can review creative for this project."); // Assuming review for the last project created by client
        require(_rating >= 1 && _rating <= 5, "Rating must be between 1 and 5.");

        creativeReviews[_creativeAddress].push(Review({
            reviewer: msg.sender,
            rating: _rating,
            reviewText: _reviewText,
            timestamp: block.timestamp
        }));

        // Update creative's average rating
        uint256 totalRating = 0;
        for (uint256 i = 0; i < creativeReviews[_creativeAddress].length; i++) {
            totalRating += creativeReviews[_creativeAddress][i].rating;
        }
        creativeProfiles[_creativeAddress].rating = totalRating / creativeReviews[_creativeAddress].length;
        creativeProfiles[_creativeAddress].reviewCount = creativeReviews[_creativeAddress].length;

        emit CreativeReviewSubmitted(_creativeAddress, _rating);
    }

    /**
     * @dev Allows creatives to submit reviews and ratings for clients after project completion.
     * @param _projectId The ID of the project.
     * @param _rating The rating given (e.g., 1-5).
     * @param _reviewText Textual review of the client.
     */
    function submitClientReview(uint256 _projectId, uint256 _rating, string memory _reviewText) external onlyCreative projectExists(_projectId) isProjectStatus(_projectId, ProjectStatus.Completed) isNotPaused {
        require(projects[_projectId].assignedCreative == msg.sender, "Only assigned creative can review client for this project.");
        require(_rating >= 1 && _rating <= 5, "Rating must be between 1 and 5.");

        clientReviews[_projectId].push(Review({
            reviewer: msg.sender,
            rating: _rating,
            reviewText: _reviewText,
            timestamp: block.timestamp
        }));
        emit ClientReviewSubmitted(_projectId, _rating);
    }

    /**
     * @dev Retrieves the average rating for a creative.
     * @param _creativeAddress The address of the creative.
     * @return Average rating of the creative.
     */
    function getAverageCreativeRating(address _creativeAddress) external view returns (uint256) {
        return creativeProfiles[_creativeAddress].rating;
    }

    // ------------------------------------------------------------------------
    // 7. Dispute Resolution (Basic)
    // ------------------------------------------------------------------------

    /**
     * @dev Allows clients or creatives to open a dispute on a project.
     * @param _projectId The ID of the project in dispute.
     * @param _disputeReason Reason for opening the dispute.
     */
    function openDispute(uint256 _projectId, string memory _disputeReason) external projectExists(_projectId) isProjectStatus(_projectId, ProjectStatus.InProgress) isNotPaused { // Can be opened during InProgress or MilestoneReview
        require(projects[_projectId].client == msg.sender || projects[_projectId].assignedCreative == msg.sender, "Only client or assigned creative can open a dispute.");
        projects[_projectId].status = ProjectStatus.Disputed;
        emit DisputeOpened(_projectId, msg.sender, _disputeReason);
    }

    /**
     * @dev Allows the agency owner to resolve a dispute and allocate funds.
     * @param _projectId The ID of the project in dispute.
     * @param _winner Address of the party who wins the dispute (client or creative).
     * @param _resolutionDetails Details of the dispute resolution.
     */
    function resolveDispute(uint256 _projectId, address _winner, string memory _resolutionDetails) external onlyAgencyOwner projectExists(_projectId) isProjectStatus(_projectId, ProjectStatus.Disputed) isNotPaused {
        require(_winner == projects[_projectId].client || _winner == projects[_projectId].assignedCreative, "Winner must be either client or creative involved in the project.");

        if (_winner == projects[_projectId].assignedCreative) {
            // Release remaining project funds to creative if creative wins dispute
            uint256 remainingFunds = projects[_projectId].fundsDeposited;
            (bool success, ) = payable(_winner).call{value: remainingFunds}("");
            require(success, "Payment to dispute winner (creative) failed.");
            projects[_projectId].fundsDeposited = 0; // Set deposited funds to 0 after payout
            emit PaymentReleased(_projectId, _winner, remainingFunds);
        } else if (_winner == projects[_projectId].client) {
            // Refund remaining project funds to client if client wins dispute
            uint256 remainingFunds = projects[_projectId].fundsDeposited;
            (bool success, ) = payable(_winner).call{value: remainingFunds}("");
            require(success, "Refund to dispute winner (client) failed.");
            projects[_projectId].fundsDeposited = 0; // Set deposited funds to 0 after refund
            emit PaymentReleased(_projectId, _winner, remainingFunds); // Event can be reused for refund too
        }

        projects[_projectId].status = ProjectStatus.Closed; // Close the project after dispute resolution
        emit DisputeResolved(_projectId, _winner, _resolutionDetails);
    }

    // ------------------------------------------------------------------------
    // 8. Emergency and Admin Functions (Agency Owner)
    // ------------------------------------------------------------------------

    /**
     * @dev Pauses the contract, preventing most functions from being called.
     */
    function pauseContract() external onlyAgencyOwner isNotPaused {
        paused = true;
        emit ContractPaused();
    }

    /**
     * @dev Unpauses the contract, allowing functions to be called again.
     */
    function unpauseContract() external onlyAgencyOwner {
        paused = false;
        emit ContractUnpaused();
    }

    /**
     * @dev Allows the agency owner to withdraw accumulated agency fees.
     */
    function withdrawAgencyFees() external onlyAgencyOwner isNotPaused {
        uint256 amountToWithdraw = agencyFeesBalance;
        agencyFeesBalance = 0; // Reset agency fees balance after withdrawal
        (bool success, ) = payable(agencyOwner).call{value: amountToWithdraw}("");
        require(success, "Agency fee withdrawal failed.");
        emit AgencyFeesWithdrawn(amountToWithdraw, agencyOwner);
    }

    /**
     * @dev Emergency function to withdraw all contract balance in case of extreme emergency.
     *      USE WITH CAUTION.
     * @param _recipient Address to receive the withdrawn funds.
     */
    function emergencyWithdraw(address payable _recipient) external onlyAgencyOwner isNotPaused {
        uint256 contractBalance = address(this).balance;
        (bool success, ) = _recipient.call{value: contractBalance}("");
        require(success, "Emergency withdrawal failed.");
        emit EmergencyWithdrawal(_recipient, contractBalance);
    }

    // Fallback function to accept ETH deposits (if needed for any reason, though not directly used in current logic)
    receive() external payable {}
}
```