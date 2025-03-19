```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Decentralized Creative Collaboration Platform
 * @author Bard (Example Smart Contract)
 * @notice A smart contract for decentralized creative collaboration, allowing users to propose projects, contribute, vote, and share rewards.
 *
 * Function Summary:
 * -----------------
 * **Project Management:**
 * 1. createProject(string _projectName, string _projectDescription, string _projectCategory, address[] _initialCollaborators): Allows project creators to initiate a new collaborative project.
 * 2. joinProject(uint _projectId): Enables users to request to join an existing project as a contributor.
 * 3. leaveProject(uint _projectId): Allows contributors to leave a project they are currently part of.
 * 4. proposeProjectChange(uint _projectId, string _changeDescription): Project owners can propose changes to the project details, requiring contributor votes.
 * 5. finalizeProject(uint _projectId):  Project owners can finalize a project, distributing rewards and marking it as complete.
 * 6. cancelProject(uint _projectId):  Project owners can cancel a project, potentially with a voting mechanism for contributors (admin override).
 * 7. getProjectDetails(uint _projectId): Retrieves detailed information about a specific project.
 * 8. getAllProjects(): Returns a list of all active project IDs.
 *
 * **Contribution and Task Management:**
 * 9. submitContribution(uint _projectId, string _contributionDescription, string _contributionLink): Contributors can submit their work or contributions to a project.
 * 10. markContributionAsApproved(uint _projectId, uint _contributionId): Project owners can approve submitted contributions.
 * 11. requestTaskAssignment(uint _projectId, string _taskDescription): Contributors can request assignment to specific tasks within a project.
 * 12. assignTask(uint _projectId, uint _contributorId, string _taskDescription): Project owners can assign tasks to specific contributors.
 * 13. markTaskAsCompleted(uint _projectId, uint _taskId): Contributors can mark tasks as completed for review.
 * 14. verifyTaskCompletion(uint _projectId, uint _taskId): Project owners can verify and approve completed tasks.
 *
 * **Voting and Governance:**
 * 15. voteOnProjectChangeProposal(uint _projectId, uint _proposalId, bool _vote): Contributors can vote on proposed project changes.
 * 16. voteOnProjectCancellation(uint _projectId, uint _proposalId, bool _vote): Contributors can vote on project cancellation proposals.
 * 17. getProposalDetails(uint _projectId, uint _proposalId): Retrieves details of a specific proposal within a project.
 *
 * **Reward and Incentive System:**
 * 18. setProjectReward(uint _projectId, uint256 _rewardAmount): Project owners can set a reward amount for the entire project (in platform's native token or ETH).
 * 19. distributeRewards(uint _projectId): Distributes project rewards to contributors based on their contributions and approvals (weighted distribution logic can be added).
 * 20. claimContributionRewards(uint _projectId, uint _contributionId): Contributors can claim rewards specifically associated with their approved contributions.
 *
 * **Utility and Admin Functions:**
 * 21. pauseContract(): Allows the contract owner to pause core functionalities in case of emergency.
 * 22. unpauseContract(): Allows the contract owner to resume contract functionalities.
 * 23. setPlatformFee(uint256 _feePercentage): Allows the contract owner to set a platform fee for project creation or reward distribution.
 * 24. withdrawPlatformFees(): Allows the contract owner to withdraw accumulated platform fees.
 */
contract CreativeCollaborationPlatform {

    // -------- State Variables --------

    address public owner;
    bool public paused;
    uint256 public platformFeePercentage; // Percentage fee charged on project rewards or creation

    uint256 public projectCounter;
    mapping(uint256 => Project) public projects;
    mapping(uint256 => mapping(address => Contributor)) public projectContributors; // projectId => contributorAddress => Contributor struct
    mapping(uint256 => mapping(uint256 => Contribution)) public projectContributions; // projectId => contributionId => Contribution struct
    mapping(uint256 => mapping(uint256 => Task)) public projectTasks; // projectId => taskId => Task struct
    mapping(uint256 => mapping(uint256 => Proposal)) public projectProposals; // projectId => proposalId => Proposal struct

    uint256 public platformFeesCollected;

    enum ProjectStatus { CREATING, ACTIVE, FINALIZED, CANCELLED }
    enum ContributionStatus { SUBMITTED, APPROVED, REJECTED }
    enum TaskStatus { REQUESTED, ASSIGNED, COMPLETED, VERIFIED }
    enum ProposalStatus { PENDING, ACCEPTED, REJECTED, EXECUTED }

    struct Project {
        uint256 id;
        string name;
        string description;
        string category;
        address owner;
        ProjectStatus status;
        uint256 rewardAmount;
        address[] collaborators; // List of contributor addresses in the project
        uint256 contributionCounter;
        uint256 taskCounter;
        uint256 proposalCounter;
        uint256 creationTimestamp;
    }

    struct Contributor {
        address contributorAddress;
        uint256 joinTimestamp;
        bool isActive; // Flag if contributor is currently active in the project
    }

    struct Contribution {
        uint256 id;
        address contributorAddress;
        string description;
        string link;
        ContributionStatus status;
        uint256 submissionTimestamp;
        uint256 rewardAmount; // Specific reward for this contribution (optional, can be part of overall project reward)
        bool rewardClaimed;
    }

    struct Task {
        uint256 id;
        string description;
        address assignee;
        TaskStatus status;
        uint256 createdTimestamp;
        uint256 completionTimestamp;
    }

    struct Proposal {
        uint256 id;
        string description;
        ProposalStatus status;
        uint256 proposalTimestamp;
        uint256 voteCountYes;
        uint256 voteCountNo;
        address proposer;
        ProposalType proposalType;
    }

    enum ProposalType { PROJECT_CHANGE, PROJECT_CANCELLATION }


    // -------- Events --------
    event ProjectCreated(uint256 projectId, address owner, string projectName);
    event ProjectJoined(uint256 projectId, address contributor);
    event ProjectLeft(uint256 projectId, address contributor);
    event ProjectChangeProposed(uint256 projectId, uint256 proposalId, string description);
    event ProjectFinalized(uint256 projectId);
    event ProjectCancelled(uint256 projectId);
    event ContributionSubmitted(uint256 projectId, uint256 contributionId, address contributor);
    event ContributionApproved(uint256 projectId, uint256 contributionId);
    event ContributionRewardClaimed(uint256 projectId, uint256 contributionId, address contributor, uint256 rewardAmount);
    event TaskRequested(uint256 projectId, string taskDescription, address requester);
    event TaskAssigned(uint256 projectId, uint256 taskId, address assignee, string taskDescription);
    event TaskCompleted(uint256 projectId, uint256 taskId, address completer);
    event TaskVerified(uint256 projectId, uint256 taskId);
    event VoteCast(uint256 projectId, uint256 proposalId, address voter, bool vote);
    event RewardsDistributed(uint256 projectId);
    event PlatformFeeSet(uint256 feePercentage);
    event PlatformFeesWithdrawn(uint256 amount, address recipient);
    event ContractPaused(address pauser);
    event ContractUnpaused(address unpauser);

    // -------- Modifiers --------
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function.");
        _;
    }

    modifier whenNotPaused() {
        require(!paused, "Contract is paused.");
        _;
    }

    modifier whenPaused() {
        require(paused, "Contract is not paused.");
        _;
    }

    modifier onlyProjectOwner(uint256 _projectId) {
        require(projects[_projectId].owner == msg.sender, "Only project owner can call this function.");
        _;
    }

    modifier onlyProjectContributor(uint256 _projectId) {
        require(projectContributors[_projectId][msg.sender].isActive, "Only project contributors can call this function.");
        _;
    }

    // -------- Constructor --------
    constructor() {
        owner = msg.sender;
        paused = false;
        platformFeePercentage = 2; // Default platform fee 2%
        projectCounter = 0;
    }

    // -------- Project Management Functions --------

    /// @notice Allows project creators to initiate a new collaborative project.
    /// @param _projectName Name of the project.
    /// @param _projectDescription Description of the project.
    /// @param _projectCategory Category of the project (e.g., Art, Software, Writing).
    /// @param _initialCollaborators Array of addresses to be added as initial collaborators (optional, can be empty).
    function createProject(
        string memory _projectName,
        string memory _projectDescription,
        string memory _projectCategory,
        address[] memory _initialCollaborators
    ) external whenNotPaused {
        projectCounter++;
        Project storage newProject = projects[projectCounter];
        newProject.id = projectCounter;
        newProject.name = _projectName;
        newProject.description = _projectDescription;
        newProject.category = _projectCategory;
        newProject.owner = msg.sender;
        newProject.status = ProjectStatus.CREATING; // Initial status
        newProject.rewardAmount = 0; // Default reward is 0, can be set later
        newProject.creationTimestamp = block.timestamp;
        newProject.contributionCounter = 0;
        newProject.taskCounter = 0;
        newProject.proposalCounter = 0;

        // Add initial collaborators if provided
        for (uint256 i = 0; i < _initialCollaborators.length; i++) {
            _addContributorToProject(projectCounter, _initialCollaborators[i]);
        }
        newProject.status = ProjectStatus.ACTIVE; // Move to active after initial setup

        emit ProjectCreated(projectCounter, msg.sender, _projectName);
    }

    /// @notice Enables users to request to join an existing project as a contributor.
    /// @param _projectId ID of the project to join.
    function joinProject(uint256 _projectId) external whenNotPaused {
        require(projects[_projectId].id != 0, "Project does not exist.");
        require(!projectContributors[_projectId][msg.sender].isActive, "Already a contributor in this project.");

        _addContributorToProject(_projectId, msg.sender);
        emit ProjectJoined(_projectId, msg.sender);
    }

    function _addContributorToProject(uint256 _projectId, address _contributorAddress) private {
        Contributor storage newContributor = projectContributors[_projectId][_contributorAddress];
        newContributor.contributorAddress = _contributorAddress;
        newContributor.joinTimestamp = block.timestamp;
        newContributor.isActive = true;
        projects[_projectId].collaborators.push(_contributorAddress);
    }


    /// @notice Allows contributors to leave a project they are currently part of.
    /// @param _projectId ID of the project to leave.
    function leaveProject(uint256 _projectId) external whenNotPaused onlyProjectContributor(_projectId) {
        require(projects[_projectId].status == ProjectStatus.ACTIVE, "Cannot leave a project that is not active.");

        projectContributors[_projectId][msg.sender].isActive = false; // Mark as inactive
        // Optionally remove from collaborators array (can be gas intensive for large arrays, consider alternative if performance is critical)
        emit ProjectLeft(_projectId, msg.sender);
    }


    /// @notice Project owners can propose changes to the project details, requiring contributor votes.
    /// @param _projectId ID of the project.
    /// @param _changeDescription Description of the proposed change.
    function proposeProjectChange(uint256 _projectId, string memory _changeDescription) external whenNotPaused onlyProjectOwner(_projectId) {
        require(projects[_projectId].status == ProjectStatus.ACTIVE, "Project must be active to propose changes.");

        projects[_projectId].proposalCounter++;
        uint256 proposalId = projects[_projectId].proposalCounter;
        Proposal storage newProposal = projectProposals[_projectId][proposalId];
        newProposal.id = proposalId;
        newProposal.description = _changeDescription;
        newProposal.status = ProposalStatus.PENDING;
        newProposal.proposalTimestamp = block.timestamp;
        newProposal.voteCountYes = 0;
        newProposal.voteCountNo = 0;
        newProposal.proposer = msg.sender;
        newProposal.proposalType = ProposalType.PROJECT_CHANGE;

        emit ProjectChangeProposed(_projectId, proposalId, _changeDescription);
    }

    /// @notice Project owners can finalize a project, distributing rewards and marking it as complete.
    /// @param _projectId ID of the project to finalize.
    function finalizeProject(uint256 _projectId) external whenNotPaused onlyProjectOwner(_projectId) {
        require(projects[_projectId].status == ProjectStatus.ACTIVE, "Project must be active to finalize.");
        projects[_projectId].status = ProjectStatus.FINALIZED;
        distributeRewards(_projectId); // Automatically distribute rewards upon finalization
        emit ProjectFinalized(_projectId);
    }

    /// @notice Project owners can cancel a project, potentially with a voting mechanism for contributors (admin override).
    /// @param _projectId ID of the project to cancel.
    function cancelProject(uint256 _projectId) external whenNotPaused onlyProjectOwner(_projectId) {
        require(projects[_projectId].status == ProjectStatus.ACTIVE || projects[_projectId].status == ProjectStatus.CREATING, "Project must be active or creating to cancel.");

        projects[_projectId].proposalCounter++;
        uint256 proposalId = projects[_projectId].proposalCounter;
        Proposal storage newProposal = projectProposals[_projectId][proposalId];
        newProposal.id = proposalId;
        newProposal.description = "Project Cancellation Proposal";
        newProposal.status = ProposalStatus.PENDING;
        newProposal.proposalTimestamp = block.timestamp;
        newProposal.voteCountYes = 0;
        newProposal.voteCountNo = 0;
        newProposal.proposer = msg.sender;
        newProposal.proposalType = ProposalType.PROJECT_CANCELLATION;

        // In a real-world scenario, you might implement voting here.
        // For simplicity in this example, project owner can directly cancel (or implement voting later)
        // For now, direct cancellation by owner:
        _executeCancelProject(_projectId);
    }

    function _executeCancelProject(uint256 _projectId) private {
        projects[_projectId].status = ProjectStatus.CANCELLED;
        emit ProjectCancelled(_projectId);
    }

    /// @notice Retrieves detailed information about a specific project.
    /// @param _projectId ID of the project.
    /// @return Project struct containing project details.
    function getProjectDetails(uint256 _projectId) external view returns (Project memory) {
        require(projects[_projectId].id != 0, "Project does not exist.");
        return projects[_projectId];
    }

    /// @notice Returns a list of all active project IDs.
    /// @return Array of active project IDs.
    function getAllProjects() external view returns (uint256[] memory) {
        uint256[] memory activeProjectIds = new uint256[](projectCounter); // Max size, can be optimized
        uint256 count = 0;
        for (uint256 i = 1; i <= projectCounter; i++) {
            if (projects[i].status == ProjectStatus.ACTIVE) {
                activeProjectIds[count] = i;
                count++;
            }
        }
        // Resize to actual count if needed for gas optimization in very large datasets
        uint256[] memory result = new uint256[](count);
        for (uint256 i = 0; i < count; i++) {
            result[i] = activeProjectIds[i];
        }
        return result;
    }

    // -------- Contribution and Task Management Functions --------

    /// @notice Contributors can submit their work or contributions to a project.
    /// @param _projectId ID of the project.
    /// @param _contributionDescription Description of the contribution.
    /// @param _contributionLink Link to the contribution (e.g., IPFS, cloud storage).
    function submitContribution(uint256 _projectId, string memory _contributionDescription, string memory _contributionLink) external whenNotPaused onlyProjectContributor(_projectId) {
        require(projects[_projectId].status == ProjectStatus.ACTIVE, "Contributions can only be submitted to active projects.");

        projects[_projectId].contributionCounter++;
        uint256 contributionId = projects[_projectId].contributionCounter;
        Contribution storage newContribution = projectContributions[_projectId][contributionId];
        newContribution.id = contributionId;
        newContribution.contributorAddress = msg.sender;
        newContribution.description = _contributionDescription;
        newContribution.link = _contributionLink;
        newContribution.status = ContributionStatus.SUBMITTED;
        newContribution.submissionTimestamp = block.timestamp;
        newContribution.rewardClaimed = false;

        emit ContributionSubmitted(_projectId, contributionId, msg.sender);
    }

    /// @notice Project owners can approve submitted contributions.
    /// @param _projectId ID of the project.
    /// @param _contributionId ID of the contribution to approve.
    function markContributionAsApproved(uint256 _projectId, uint256 _contributionId) external whenNotPaused onlyProjectOwner(_projectId) {
        require(projectContributions[_projectId][_contributionId].id != 0, "Contribution does not exist.");
        require(projectContributions[_projectId][_contributionId].status == ContributionStatus.SUBMITTED, "Contribution is not in submitted status.");

        projectContributions[_projectId][_contributionId].status = ContributionStatus.APPROVED;
        emit ContributionApproved(_projectId, _contributionId);
    }

    /// @notice Contributors can request assignment to specific tasks within a project.
    /// @param _projectId ID of the project.
    /// @param _taskDescription Description of the task requested.
    function requestTaskAssignment(uint256 _projectId, string memory _taskDescription) external whenNotPaused onlyProjectContributor(_projectId) {
        require(projects[_projectId].status == ProjectStatus.ACTIVE, "Tasks can only be requested in active projects.");

        emit TaskRequested(_projectId, _taskDescription, msg.sender);
    }

    /// @notice Project owners can assign tasks to specific contributors.
    /// @param _projectId ID of the project.
    /// @param _contributorId Address of the contributor to assign the task to.
    /// @param _taskDescription Description of the task.
    function assignTask(uint256 _projectId, uint256 _contributorId, string memory _taskDescription) external whenNotPaused onlyProjectOwner(_projectId) {
        require(projects[_projectId].status == ProjectStatus.ACTIVE, "Tasks can only be assigned in active projects.");
        require(projectContributors[_projectId][projects[_projectId].collaborators[_contributorId]].isActive, "Contributor is not active in the project."); // basic check, improve contributor ID handling

        projects[_projectId].taskCounter++;
        uint256 taskId = projects[_projectId].taskCounter;
        Task storage newTask = projectTasks[_projectId][taskId];
        newTask.id = taskId;
        newTask.description = _taskDescription;
        newTask.assignee = projects[_projectId].collaborators[_contributorId]; // Assign by index in collaborators array (improve ID handling)
        newTask.status = TaskStatus.ASSIGNED;
        newTask.createdTimestamp = block.timestamp;

        emit TaskAssigned(_projectId, taskId, projects[_projectId].collaborators[_contributorId], _taskDescription);
    }

    /// @notice Contributors can mark tasks as completed for review.
    /// @param _projectId ID of the project.
    /// @param _taskId ID of the task marked as complete.
    function markTaskAsCompleted(uint256 _projectId, uint256 _taskId) external whenNotPaused onlyProjectContributor(_projectId) {
        require(projectTasks[_projectId][_taskId].id != 0, "Task does not exist.");
        require(projectTasks[_projectId][_taskId].assignee == msg.sender, "Only assignee can mark task as completed.");
        require(projectTasks[_projectId][_taskId].status == TaskStatus.ASSIGNED, "Task is not in assigned status.");

        projectTasks[_projectId][_taskId].status = TaskStatus.COMPLETED;
        projectTasks[_projectId][_taskId].completionTimestamp = block.timestamp;
        emit TaskCompleted(_projectId, _taskId, msg.sender);
    }

    /// @notice Project owners can verify and approve completed tasks.
    /// @param _projectId ID of the project.
    /// @param _taskId ID of the task to verify.
    function verifyTaskCompletion(uint256 _projectId, uint256 _taskId) external whenNotPaused onlyProjectOwner(_projectId) {
        require(projectTasks[_projectId][_taskId].id != 0, "Task does not exist.");
        require(projectTasks[_projectId][_taskId].status == TaskStatus.COMPLETED, "Task is not in completed status.");

        projectTasks[_projectId][_taskId].status = TaskStatus.VERIFIED;
        emit TaskVerified(_projectId, _taskId);
    }

    // -------- Voting and Governance Functions --------

    /// @notice Contributors can vote on proposed project changes.
    /// @param _projectId ID of the project.
    /// @param _proposalId ID of the proposal to vote on.
    /// @param _vote True for yes, false for no.
    function voteOnProjectChangeProposal(uint256 _projectId, uint256 _proposalId, bool _vote) external whenNotPaused onlyProjectContributor(_projectId) {
        _voteOnProposal(_projectId, _proposalId, _vote, ProposalType.PROJECT_CHANGE);
    }

    /// @notice Contributors can vote on project cancellation proposals.
    /// @param _projectId ID of the project.
    /// @param _proposalId ID of the cancellation proposal.
    /// @param _vote True for yes, false for no.
    function voteOnProjectCancellation(uint256 _projectId, uint256 _proposalId, bool _vote) external whenNotPaused onlyProjectContributor(_projectId) {
        _voteOnProposal(_projectId, _proposalId, _vote, ProposalType.PROJECT_CANCELLATION);
    }

    function _voteOnProposal(uint256 _projectId, uint256 _proposalId, bool _vote, ProposalType _proposalType) private {
        require(projectProposals[_projectId][_proposalId].id != 0, "Proposal does not exist.");
        require(projectProposals[_projectId][_proposalId].status == ProposalStatus.PENDING, "Proposal is not pending.");
        require(projectProposals[_projectId][_proposalId].proposalType == _proposalType, "Proposal type mismatch.");

        if (_vote) {
            projectProposals[_projectId][_proposalId].voteCountYes++;
        } else {
            projectProposals[_projectId][_proposalId].voteCountNo++;
        }
        emit VoteCast(_projectId, _proposalId, msg.sender, _vote);

        // Example: Simple majority vote to execute proposal (adjust logic as needed)
        uint256 totalContributors = projects[_projectId].collaborators.length;
        uint256 requiredVotes = (totalContributors / 2) + 1; // Simple majority

        if (projectProposals[_projectId][_proposalId].voteCountYes >= requiredVotes) {
            projectProposals[_projectId][_proposalId].status = ProposalStatus.ACCEPTED;
            if (_proposalType == ProposalType.PROJECT_CHANGE) {
                // Execute project change logic here if needed (not implemented in this example)
                projectProposals[_projectId][_proposalId].status = ProposalStatus.EXECUTED; // Mark as executed even if no change logic is implemented
            } else if (_proposalType == ProposalType.PROJECT_CANCELLATION) {
                _executeCancelProject(_projectId); // Execute cancellation if cancellation proposal is accepted
                projectProposals[_projectId][_proposalId].status = ProposalStatus.EXECUTED;
            }

        } else if (projectProposals[_projectId][_proposalId].voteCountNo >= requiredVotes) {
            projectProposals[_projectId][_proposalId].status = ProposalStatus.REJECTED;
        }
    }


    /// @notice Retrieves details of a specific proposal within a project.
    /// @param _projectId ID of the project.
    /// @param _proposalId ID of the proposal.
    /// @return Proposal struct containing proposal details.
    function getProposalDetails(uint256 _projectId, uint256 _proposalId) external view returns (Proposal memory) {
        require(projectProposals[_projectId][_proposalId].id != 0, "Proposal does not exist.");
        return projectProposals[_projectId][_proposalId];
    }

    // -------- Reward and Incentive System Functions --------

    /// @notice Project owners can set a reward amount for the entire project (in platform's native token or ETH).
    /// @param _projectId ID of the project.
    /// @param _rewardAmount Amount of reward to set (in wei if using ETH, or in platform's token units).
    function setProjectReward(uint256 _projectId, uint256 _rewardAmount) external whenNotPaused onlyProjectOwner(_projectId) {
        require(projects[_projectId].status == ProjectStatus.ACTIVE, "Reward can only be set for active projects.");
        projects[_projectId].rewardAmount = _rewardAmount;
    }

    /// @notice Distributes project rewards to contributors based on their contributions and approvals.
    /// @param _projectId ID of the project to distribute rewards for.
    function distributeRewards(uint256 _projectId) private { // Made private, called by finalizeProject for now
        require(projects[_projectId].status == ProjectStatus.FINALIZED, "Rewards can only be distributed for finalized projects.");
        require(projects[_projectId].rewardAmount > 0, "No reward set for this project.");

        uint256 totalReward = projects[_projectId].rewardAmount;
        uint256 platformFee = (totalReward * platformFeePercentage) / 100;
        uint256 rewardToDistribute = totalReward - platformFee;

        platformFeesCollected += platformFee;

        // Simple reward distribution example: Equal split among approved contributions
        uint256 approvedContributionCount = 0;
        for (uint256 i = 1; i <= projects[_projectId].contributionCounter; i++) {
            if (projectContributions[_projectId][i].status == ContributionStatus.APPROVED) {
                approvedContributionCount++;
            }
        }

        if (approvedContributionCount > 0) {
            uint256 rewardPerContribution = rewardToDistribute / approvedContributionCount;
            for (uint256 i = 1; i <= projects[_projectId].contributionCounter; i++) {
                if (projectContributions[_projectId][i].status == ContributionStatus.APPROVED) {
                    projectContributions[_projectId][i].rewardAmount = rewardPerContribution;
                    // Rewards are claimable, not automatically sent to contributors in this example
                }
            }
            emit RewardsDistributed(_projectId);
        }
    }


    /// @notice Contributors can claim rewards specifically associated with their approved contributions.
    /// @param _projectId ID of the project.
    /// @param _contributionId ID of the contribution to claim rewards for.
    function claimContributionRewards(uint256 _projectId, uint256 _contributionId) external whenNotPaused onlyProjectContributor(_projectId) {
        require(projectContributions[_projectId][_contributionId].id != 0, "Contribution does not exist.");
        require(projectContributions[_projectId][_contributionId].contributorAddress == msg.sender, "Not the contributor of this contribution.");
        require(projectContributions[_projectId][_contributionId].status == ContributionStatus.APPROVED, "Contribution is not approved.");
        require(!projectContributions[_projectId][_contributionId].rewardClaimed, "Reward already claimed for this contribution.");
        require(projectContributions[_projectId][_contributionId].rewardAmount > 0, "No reward allocated for this contribution.");

        uint256 rewardAmount = projectContributions[_projectId][_contributionId].rewardAmount;

        projectContributions[_projectId][_contributionId].rewardClaimed = true;
        (bool success, ) = msg.sender.call{value: rewardAmount}(""); // Sending ETH reward (adjust for token transfer if using platform token)
        require(success, "Reward transfer failed.");

        emit ContributionRewardClaimed(_projectId, _contributionId, msg.sender, rewardAmount);
    }


    // -------- Utility and Admin Functions --------

    /// @notice Allows the contract owner to pause core functionalities in case of emergency.
    function pauseContract() external onlyOwner whenNotPaused {
        paused = true;
        emit ContractPaused(msg.sender);
    }

    /// @notice Allows the contract owner to resume contract functionalities.
    function unpauseContract() external onlyOwner whenPaused {
        paused = false;
        emit ContractUnpaused(msg.sender);
    }

    /// @notice Allows the contract owner to set a platform fee for project creation or reward distribution.
    /// @param _feePercentage Fee percentage to set.
    function setPlatformFee(uint256 _feePercentage) external onlyOwner {
        require(_feePercentage <= 100, "Fee percentage cannot exceed 100.");
        platformFeePercentage = _feePercentage;
        emit PlatformFeeSet(_feePercentage);
    }

    /// @notice Allows the contract owner to withdraw accumulated platform fees.
    function withdrawPlatformFees() external onlyOwner {
        uint256 amountToWithdraw = platformFeesCollected;
        platformFeesCollected = 0; // Reset collected fees after withdrawal

        (bool success, ) = owner.call{value: amountToWithdraw}("");
        require(success, "Fee withdrawal failed.");
        emit PlatformFeesWithdrawn(amountToWithdraw, owner);
    }

    // Fallback function to receive Ether (if reward distribution uses ETH directly)
    receive() external payable {}
    fallback() external payable {}
}
```