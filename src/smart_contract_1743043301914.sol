```solidity
pragma solidity ^0.8.0;

/**
 * @title Decentralized Autonomous Organization for Creative Projects (DAO-CP)
 * @author Bard (AI Assistant)
 * @notice A smart contract for a DAO focused on funding, governing, and managing creative projects.
 * It incorporates advanced concepts like dynamic voting power based on reputation, milestone-based funding,
 * decentralized dispute resolution, and a skill-based contributor system.
 *
 * Function Summary:
 *
 * ### Project Proposal and Management ###
 * 1. submitProjectProposal(string projectName, string projectDescription, uint256 fundingGoal, string[] milestones):
 *    - Allows DAO members to submit project proposals with details, funding goal, and milestones.
 * 2. voteOnProjectProposal(uint256 proposalId, bool vote):
 *    - Enables DAO members to vote on project proposals. Voting power is dynamically calculated based on reputation.
 * 3. fundProject(uint256 projectId):
 *    - Funds a project if it has passed the voting threshold and hasn't been funded yet.
 * 4. markMilestoneComplete(uint256 projectId, uint256 milestoneIndex):
 *    - Allows project leads to mark a milestone as complete, triggering a vote for fund release.
 * 5. voteOnMilestoneCompletion(uint256 projectId, uint256 milestoneIndex, bool vote):
 *    - DAO members vote on whether a milestone is truly complete and funds should be released.
 * 6. withdrawMilestoneFunds(uint256 projectId, uint256 milestoneIndex):
 *    - Project leads can withdraw funds for a completed and approved milestone.
 * 7. cancelProjectProposal(uint256 proposalId):
 *    - Allows the project proposer to cancel their proposal before funding.
 * 8. getProjectDetails(uint256 projectId):
 *    - Retrieves detailed information about a specific project, including status, milestones, and funding.
 * 9. getAllProjectProposals():
 *    - Returns a list of all project proposal IDs.
 *
 * ### DAO Membership and Reputation ###
 * 10. joinDAO():
 *     - Allows anyone to join the DAO as a member.
 * 11. leaveDAO():
 *     - Allows members to leave the DAO.
 * 12. contributeToProject(uint256 projectId, string skillOffered):
 *     - Members can offer their skills to contribute to projects, increasing their reputation.
 * 13. rewardContributorReputation(address contributor, uint256 reputationPoints):
 *     - DAO admins or project leads can reward contributors with reputation points for valuable contributions.
 * 14. getMemberReputation(address member):
 *     - Retrieves the reputation score of a DAO member.
 * 15. getDAOMemberList():
 *     - Returns a list of all DAO member addresses.
 *
 * ### Governance and Dispute Resolution ###
 * 16. proposeGovernanceChange(string description, bytes calldata action):
 *     - Allows DAO members to propose changes to the DAO's governance rules or contract parameters.
 * 17. voteOnGovernanceChange(uint256 proposalId, bool vote):
 *     - DAO members vote on governance change proposals.
 * 18. raiseProjectDispute(uint256 projectId, string disputeDescription):
 *     - Allows DAO members to raise a dispute regarding a project, triggering a decentralized resolution process.
 * 19. voteOnDisputeResolution(uint256 disputeId, DisputeResolutionOption option):
 *     - DAO members vote on how to resolve a raised dispute.
 * 20. executeGovernanceChange(uint256 proposalId):
 *     - Executes an approved governance change proposal after voting.
 * 21. pauseContract():
 *     - Allows DAO admins to pause the contract in case of emergency.
 * 22. unpauseContract():
 *     - Allows DAO admins to unpause the contract.
 * 23. setVotingThreshold(uint256 newThresholdPercentage):
 *     - Allows DAO admins to change the voting threshold for proposals.
 */
contract DAOCreativeProjects {

    // -------- State Variables --------

    struct ProjectProposal {
        string projectName;
        string projectDescription;
        address proposer;
        uint256 fundingGoal;
        string[] milestones;
        uint256 yesVotes;
        uint256 noVotes;
        bool isActive;
        bool isFunded;
        uint256 fundingRaised;
    }

    struct Project {
        string projectName;
        string projectDescription;
        address lead;
        uint256 fundingGoal;
        string[] milestones;
        uint256 fundingRaised;
        bool isActive;
        mapping(uint256 => MilestoneStatus) milestoneStatuses; // Milestone index to status
    }

    enum MilestoneStatus {
        PENDING,
        COMPLETED_PROPOSED,
        COMPLETED_APPROVED,
        REJECTED
    }

    struct GovernanceProposal {
        string description;
        bytes calldata action; // Encoded function call data
        uint256 yesVotes;
        uint256 noVotes;
        bool isActive;
        bool isExecuted;
    }

    struct Dispute {
        uint256 projectId;
        string description;
        address reporter;
        uint256 yesVotes; // Votes for resolution option 1
        uint256 noVotes;  // Votes for resolution option 2
        bool isActive;
        DisputeResolutionOption resolution;
    }

    enum DisputeResolutionOption {
        RESOLVE_IN_FAVOR_PROJECT,
        RESOLVE_IN_FAVOR_DAO
    }

    mapping(uint256 => ProjectProposal) public projectProposals;
    mapping(uint256 => Project) public projects;
    mapping(uint256 => GovernanceProposal) public governanceProposals;
    mapping(uint256 => Dispute) public disputes;
    mapping(address => uint256) public memberReputation; // Member address to reputation score
    mapping(address => bool) public isDAOMember;
    address[] public daoMembers;
    address public daoAdmin;
    uint256 public proposalCounter;
    uint256 public projectCounter;
    uint256 public governanceProposalCounter;
    uint256 public disputeCounter;
    uint256 public votingThresholdPercentage = 51; // Default to 51% for proposal approval
    bool public paused = false;

    // -------- Events --------

    event ProjectProposalSubmitted(uint256 proposalId, address proposer, string projectName);
    event ProjectProposalVoted(uint256 proposalId, address voter, bool vote);
    event ProjectFunded(uint256 projectId, address lead, uint256 fundingAmount);
    event MilestoneCompletedProposed(uint256 projectId, uint256 milestoneIndex);
    event MilestoneCompletionVoted(uint256 projectId, uint256 milestoneIndex, address voter, bool vote);
    event MilestoneFundsWithdrawn(uint256 projectId, uint256 milestoneIndex, uint256 amount);
    event GovernanceChangeProposed(uint256 proposalId, address proposer, string description);
    event GovernanceChangeVoted(uint256 proposalId, address voter, bool vote);
    event GovernanceChangeExecuted(uint256 proposalId);
    event DisputeRaised(uint256 disputeId, uint256 projectId, address reporter, string description);
    event DisputeResolutionVoted(uint256 disputeId, address voter, DisputeResolutionOption option);
    event ContractPaused(address admin);
    event ContractUnpaused(address admin);
    event MemberJoinedDAO(address member);
    event MemberLeftDAO(address member);
    event ReputationRewarded(address member, uint256 points);

    // -------- Modifiers --------

    modifier onlyDAOMember() {
        require(isDAOMember[msg.sender], "Only DAO members can perform this action.");
        _;
    }

    modifier onlyDAOAdmin() {
        require(msg.sender == daoAdmin, "Only DAO admin can perform this action.");
        _;
    }

    modifier projectProposalExists(uint256 _proposalId) {
        require(projectProposals[_proposalId].isActive, "Project proposal does not exist or is not active.");
        _;
    }

    modifier projectExists(uint256 _projectId) {
        require(projects[_projectId].isActive, "Project does not exist or is not active.");
        _;
    }

    modifier governanceProposalExists(uint256 _proposalId) {
        require(governanceProposals[_proposalId].isActive, "Governance proposal does not exist or is not active.");
        _;
    }

    modifier disputeExists(uint256 _disputeId) {
        require(disputes[_disputeId].isActive, "Dispute does not exist or is not active.");
        _;
    }

    modifier notPaused() {
        require(!paused, "Contract is paused.");
        _;
    }

    // -------- Constructor --------

    constructor() {
        daoAdmin = msg.sender;
    }

    // -------- Project Proposal and Management Functions --------

    /// @notice Allows DAO members to submit project proposals.
    /// @param _projectName The name of the project.
    /// @param _projectDescription A brief description of the project.
    /// @param _fundingGoal The total funding goal for the project in wei.
    /// @param _milestones An array of milestones for the project.
    function submitProjectProposal(
        string memory _projectName,
        string memory _projectDescription,
        uint256 _fundingGoal,
        string[] memory _milestones
    ) external onlyDAOMember notPaused {
        proposalCounter++;
        projectProposals[proposalCounter] = ProjectProposal({
            projectName: _projectName,
            projectDescription: _projectDescription,
            proposer: msg.sender,
            fundingGoal: _fundingGoal,
            milestones: _milestones,
            yesVotes: 0,
            noVotes: 0,
            isActive: true,
            isFunded: false,
            fundingRaised: 0
        });
        emit ProjectProposalSubmitted(proposalCounter, msg.sender, _projectName);
    }

    /// @notice Allows DAO members to vote on project proposals. Voting power is reputation-based.
    /// @param _proposalId The ID of the project proposal.
    /// @param _vote True for yes, false for no.
    function voteOnProjectProposal(uint256 _proposalId, bool _vote)
        external
        onlyDAOMember
        notPaused
        projectProposalExists(_proposalId)
    {
        ProjectProposal storage proposal = projectProposals[_proposalId];
        require(proposal.proposer != msg.sender, "Proposer cannot vote on their own proposal.");
        require(proposal.isActive && !proposal.isFunded, "Proposal is not active or already funded.");

        uint256 votingPower = getVotingPower(msg.sender); // Dynamic voting power based on reputation

        if (_vote) {
            proposal.yesVotes += votingPower;
        } else {
            proposal.noVotes += votingPower;
        }
        emit ProjectProposalVoted(_proposalId, msg.sender, _vote);

        // Check if proposal passes voting threshold
        uint256 totalVotingPower = getTotalVotingPower();
        if (proposal.yesVotes * 100 >= votingThresholdPercentage * totalVotingPower) {
            proposal.isActive = false; // Deactivate proposal after passing
        }
    }

    /// @notice Funds a project if it has passed the voting threshold and hasn't been funded yet.
    /// @param _projectId The ID of the project proposal (which will become the project ID).
    function fundProject(uint256 _projectId)
        external
        onlyDAOAdmin // For demonstration, can be changed to governance voted funding in a real DAO
        notPaused
        projectProposalExists(_projectId)
    {
        ProjectProposal storage proposal = projectProposals[_projectId];
        require(!proposal.isFunded, "Project is already funded.");

        uint256 totalVotingPower = getTotalVotingPower();
        require(proposal.yesVotes * 100 >= votingThresholdPercentage * totalVotingPower, "Proposal did not pass voting threshold.");

        projects[projectCounter] = Project({
            projectName: proposal.projectName,
            projectDescription: proposal.projectDescription,
            lead: proposal.proposer,
            fundingGoal: proposal.fundingGoal,
            milestones: proposal.milestones,
            fundingRaised: 0,
            isActive: true,
            milestoneStatuses: mapping(uint256 => MilestoneStatus.PENDING)
        });
        proposal.isFunded = true;
        proposal.isActive = false; // Deactivate proposal after funding (even if voting passed earlier)

        projectCounter++;
        payable(proposal.proposer).transfer(proposal.fundingGoal); // Send funds to project proposer (lead)
        projects[projectCounter -1].fundingRaised = proposal.fundingGoal; // Update project funding raised

        emit ProjectFunded(projectCounter - 1, proposal.proposer, proposal.fundingGoal);
    }

    /// @notice Allows project leads to mark a milestone as complete, triggering a vote for fund release.
    /// @param _projectId The ID of the project.
    /// @param _milestoneIndex The index of the milestone to mark as complete.
    function markMilestoneComplete(uint256 _projectId, uint256 _milestoneIndex)
        external
        onlyDAOMember // In real scenario, restrict to project lead or designated milestone approvers
        notPaused
        projectExists(_projectId)
    {
        Project storage project = projects[_projectId];
        require(msg.sender == project.lead, "Only project lead can mark milestones complete.");
        require(_milestoneIndex < project.milestones.length, "Invalid milestone index.");
        require(project.milestoneStatuses[_milestoneIndex] == MilestoneStatus.PENDING, "Milestone is not pending.");

        project.milestoneStatuses[_milestoneIndex] = MilestoneStatus.COMPLETED_PROPOSED;
        emit MilestoneCompletedProposed(_projectId, _milestoneIndex);
    }

    /// @notice DAO members vote on whether a milestone is truly complete and funds should be released.
    /// @param _projectId The ID of the project.
    /// @param _milestoneIndex The index of the milestone being voted on.
    /// @param _vote True for yes (milestone is complete), false for no.
    function voteOnMilestoneCompletion(uint256 _projectId, uint256 _milestoneIndex, bool _vote)
        external
        onlyDAOMember
        notPaused
        projectExists(_projectId)
    {
        Project storage project = projects[_projectId];
        require(project.milestoneStatuses[_milestoneIndex] == MilestoneStatus.COMPLETED_PROPOSED, "Milestone completion proposal is not active.");

        uint256 votingPower = getVotingPower(msg.sender); // Dynamic voting power

        if (_vote) {
            project.milestoneStatuses[_milestoneIndex] = MilestoneStatus.COMPLETED_APPROVED; // For simplicity, direct approval after first yes vote
        } else {
            project.milestoneStatuses[_milestoneIndex] = MilestoneStatus.REJECTED; // For simplicity, direct rejection after first no vote
        }
        emit MilestoneCompletionVoted(_projectId, _milestoneIndex, msg.sender, _vote);

        // In a real DAO, implement proper voting tally and threshold for milestone approval/rejection
    }

    /// @notice Project leads can withdraw funds for a completed and approved milestone.
    /// @param _projectId The ID of the project.
    /// @param _milestoneIndex The index of the milestone to withdraw funds for.
    function withdrawMilestoneFunds(uint256 _projectId, uint256 _milestoneIndex)
        external
        onlyDAOMember
        notPaused
        projectExists(_projectId)
    {
        Project storage project = projects[_projectId];
        require(msg.sender == project.lead, "Only project lead can withdraw milestone funds.");
        require(_milestoneIndex < project.milestones.length, "Invalid milestone index.");
        require(project.milestoneStatuses[_milestoneIndex] == MilestoneStatus.COMPLETED_APPROVED, "Milestone is not approved for funding.");

        // Calculate funds for this milestone (simple equal distribution for example)
        uint256 milestoneFunds = project.fundingGoal / project.milestones.length;
        require(project.fundingRaised >= milestoneFunds, "Insufficient funds in contract for milestone.");

        project.fundingRaised -= milestoneFunds; // Deduct from funding raised
        payable(project.lead).transfer(milestoneFunds);
        project.milestoneStatuses[_milestoneIndex] = MilestoneStatus.PENDING; // Reset milestone status for future milestones

        emit MilestoneFundsWithdrawn(_projectId, _milestoneIndex, milestoneFunds);
    }

    /// @notice Allows the project proposer to cancel their proposal before funding.
    /// @param _proposalId The ID of the project proposal to cancel.
    function cancelProjectProposal(uint256 _proposalId)
        external
        onlyDAOMember
        notPaused
        projectProposalExists(_proposalId)
    {
        ProjectProposal storage proposal = projectProposals[_proposalId];
        require(proposal.proposer == msg.sender, "Only the proposer can cancel their proposal.");
        require(!proposal.isFunded, "Cannot cancel a funded project proposal.");

        proposal.isActive = false; // Mark proposal as inactive (canceled)
    }

    /// @notice Retrieves detailed information about a specific project.
    /// @param _projectId The ID of the project.
    /// @return Project details (projectName, projectDescription, lead, fundingGoal, milestones, fundingRaised, isActive).
    function getProjectDetails(uint256 _projectId)
        external
        view
        projectExists(_projectId)
        returns (
            string memory projectName,
            string memory projectDescription,
            address lead,
            uint256 fundingGoal,
            string[] memory milestones,
            uint256 fundingRaised,
            bool isActive
        )
    {
        Project storage project = projects[_projectId];
        return (
            project.projectName,
            project.projectDescription,
            project.lead,
            project.fundingGoal,
            project.milestones,
            project.fundingRaised,
            project.isActive
        );
    }

    /// @notice Returns a list of all active project proposal IDs.
    /// @return An array of project proposal IDs.
    function getAllProjectProposals() external view returns (uint256[] memory) {
        uint256[] memory proposalIds = new uint256[](proposalCounter);
        uint256 count = 0;
        for (uint256 i = 1; i <= proposalCounter; i++) {
            if (projectProposals[i].isActive) {
                proposalIds[count] = i;
                count++;
            }
        }
        // Resize the array to remove empty slots if any
        uint256[] memory activeProposalIds = new uint256[](count);
        for (uint256 i = 0; i < count; i++) {
            activeProposalIds[i] = proposalIds[i];
        }
        return activeProposalIds;
    }


    // -------- DAO Membership and Reputation Functions --------

    /// @notice Allows anyone to join the DAO as a member.
    function joinDAO() external notPaused {
        require(!isDAOMember[msg.sender], "Already a DAO member.");
        isDAOMember[msg.sender] = true;
        daoMembers.push(msg.sender);
        emit MemberJoinedDAO(msg.sender);
    }

    /// @notice Allows members to leave the DAO.
    function leaveDAO() external onlyDAOMember notPaused {
        require(isDAOMember[msg.sender], "Not a DAO member.");
        isDAOMember[msg.sender] = false;
        // Remove member from daoMembers array (can be optimized for gas in production)
        for (uint256 i = 0; i < daoMembers.length; i++) {
            if (daoMembers[i] == msg.sender) {
                daoMembers[i] = daoMembers[daoMembers.length - 1];
                daoMembers.pop();
                break;
            }
        }
        emit MemberLeftDAO(msg.sender);
    }

    /// @notice Members can offer their skills to contribute to projects, increasing their reputation.
    /// @param _projectId The ID of the project to contribute to.
    /// @param _skillOffered A string describing the skill offered.
    function contributeToProject(uint256 _projectId, string memory _skillOffered)
        external
        onlyDAOMember
        notPaused
        projectExists(_projectId)
    {
        // In a real system, this could be more complex, involving project lead approval, etc.
        // For simplicity, contributing automatically increases reputation.
        rewardContributorReputation(msg.sender, 1); // Small reputation reward for contribution
    }

    /// @notice DAO admins or project leads can reward contributors with reputation points.
    /// @param _contributor The address of the contributor to reward.
    /// @param _reputationPoints The number of reputation points to award.
    function rewardContributorReputation(address _contributor, uint256 _reputationPoints)
        external
        onlyDAOAdmin // For demonstration, can be made governable or project-lead initiated with DAO approval
        notPaused
    {
        memberReputation[_contributor] += _reputationPoints;
        emit ReputationRewarded(_contributor, _reputationPoints);
    }

    /// @notice Retrieves the reputation score of a DAO member.
    /// @param _member The address of the member.
    /// @return The reputation score of the member.
    function getMemberReputation(address _member) external view returns (uint256) {
        return memberReputation[_member];
    }

    /// @notice Returns a list of all DAO member addresses.
    /// @return An array of DAO member addresses.
    function getDAOMemberList() external view returns (address[] memory) {
        return daoMembers;
    }

    // -------- Governance and Dispute Resolution Functions --------

    /// @notice Allows DAO members to propose changes to the DAO's governance rules or contract parameters.
    /// @param _description A description of the governance change proposal.
    /// @param _action Encoded function call data to execute the change (e.g., changeVotingThreshold(newValue)).
    function proposeGovernanceChange(string memory _description, bytes memory _action)
        external
        onlyDAOMember
        notPaused
    {
        governanceProposalCounter++;
        governanceProposals[governanceProposalCounter] = GovernanceProposal({
            description: _description,
            action: _action,
            yesVotes: 0,
            noVotes: 0,
            isActive: true,
            isExecuted: false
        });
        emit GovernanceChangeProposed(governanceProposalCounter, msg.sender, _description);
    }

    /// @notice DAO members vote on governance change proposals.
    /// @param _proposalId The ID of the governance change proposal.
    /// @param _vote True for yes, false for no.
    function voteOnGovernanceChange(uint256 _proposalId, bool _vote)
        external
        onlyDAOMember
        notPaused
        governanceProposalExists(_proposalId)
    {
        GovernanceProposal storage proposal = governanceProposals[_proposalId];
        require(proposal.isActive && !proposal.isExecuted, "Governance proposal is not active or already executed.");

        uint256 votingPower = getVotingPower(msg.sender);

        if (_vote) {
            proposal.yesVotes += votingPower;
        } else {
            proposal.noVotes += votingPower;
        }
        emit GovernanceChangeVoted(_proposalId, msg.sender, _vote);

        // Check if governance proposal passes voting threshold
        uint256 totalVotingPower = getTotalVotingPower();
        if (proposal.yesVotes * 100 >= votingThresholdPercentage * totalVotingPower) {
            proposal.isActive = false; // Deactivate proposal after passing
        }
    }

    /// @notice Executes an approved governance change proposal after voting.
    /// @param _proposalId The ID of the governance change proposal to execute.
    function executeGovernanceChange(uint256 _proposalId)
        external
        onlyDAOAdmin // For demonstration, can be made automatically executable after vote passes
        notPaused
        governanceProposalExists(_proposalId)
    {
        GovernanceProposal storage proposal = governanceProposals[_proposalId];
        require(!proposal.isExecuted, "Governance proposal already executed.");

        uint256 totalVotingPower = getTotalVotingPower();
        require(proposal.yesVotes * 100 >= votingThresholdPercentage * totalVotingPower, "Governance proposal did not pass voting threshold.");

        (bool success, ) = address(this).call(proposal.action); // Execute the encoded function call
        require(success, "Governance change execution failed.");
        proposal.isExecuted = true;
        proposal.isActive = false; // Deactivate after execution

        emit GovernanceChangeExecuted(_proposalId);
    }

    /// @notice Allows DAO members to raise a dispute regarding a project.
    /// @param _projectId The ID of the project in dispute.
    /// @param _disputeDescription A description of the dispute.
    function raiseProjectDispute(uint256 _projectId, string memory _disputeDescription)
        external
        onlyDAOMember
        notPaused
        projectExists(_projectId)
    {
        disputeCounter++;
        disputes[disputeCounter] = Dispute({
            projectId: _projectId,
            description: _disputeDescription,
            reporter: msg.sender,
            yesVotes: 0,
            noVotes: 0,
            isActive: true,
            resolution: DisputeResolutionOption.RESOLVE_IN_FAVOR_DAO // Default resolution option
        });
        emit DisputeRaised(disputeCounter, _projectId, msg.sender, _disputeDescription);
    }

    /// @notice DAO members vote on how to resolve a raised dispute.
    /// @param _disputeId The ID of the dispute.
    /// @param _option The chosen resolution option (RESOLVE_IN_FAVOR_PROJECT or RESOLVE_IN_FAVOR_DAO).
    function voteOnDisputeResolution(uint256 _disputeId, DisputeResolutionOption _option)
        external
        onlyDAOMember
        notPaused
        disputeExists(_disputeId)
    {
        Dispute storage dispute = disputes[_disputeId];
        require(dispute.isActive, "Dispute is not active.");

        uint256 votingPower = getVotingPower(msg.sender);

        if (_option == DisputeResolutionOption.RESOLVE_IN_FAVOR_PROJECT) {
            dispute.yesVotes += votingPower;
        } else if (_option == DisputeResolutionOption.RESOLVE_IN_FAVOR_DAO) {
            dispute.noVotes += votingPower;
        } else {
            revert("Invalid dispute resolution option.");
        }
        dispute.resolution = _option; // Store the chosen option for later resolution logic
        emit DisputeResolutionVoted(_disputeId, msg.sender, _option);

        // Basic resolution logic - for demonstration, can be more complex with thresholds, etc.
        uint256 totalVotingPower = getTotalVotingPower();
        if (dispute.yesVotes * 100 >= votingThresholdPercentage * totalVotingPower || dispute.noVotes * 100 >= votingThresholdPercentage * totalVotingPower) {
            dispute.isActive = false; // Deactivate dispute after resolution vote
            // In a real DAO, implement actual dispute resolution logic based on the voted option.
            // For example, potentially refunding project funds if resolved in favor of DAO, etc.
        }
    }

    // -------- Admin and Utility Functions --------

    /// @notice Pauses the contract, preventing most actions except unpausing.
    function pauseContract() external onlyDAOAdmin notPaused {
        paused = true;
        emit ContractPaused(msg.sender);
    }

    /// @notice Unpauses the contract, restoring normal functionality.
    function unpauseContract() external onlyDAOAdmin {
        paused = false;
        emit ContractUnpaused(msg.sender);
    }

    /// @notice Sets a new voting threshold percentage for proposals.
    /// @param _newThresholdPercentage The new voting threshold percentage (e.g., 51 for 51%).
    function setVotingThreshold(uint256 _newThresholdPercentage) external onlyDAOAdmin {
        require(_newThresholdPercentage <= 100, "Voting threshold cannot exceed 100%.");
        votingThresholdPercentage = _newThresholdPercentage;
    }

    // -------- Helper Functions --------

    /// @notice Calculates voting power for a member based on their reputation.
    /// @param _member The address of the member.
    /// @return The voting power of the member.
    function getVotingPower(address _member) public view returns (uint256) {
        // Example: Voting power increases linearly with reputation (can be adjusted)
        return 1 + (memberReputation[_member] / 10); // Base voting power of 1 + reputation bonus
    }

    /// @notice Calculates the total voting power of all DAO members.
    /// @return The total voting power.
    function getTotalVotingPower() public view returns (uint256) {
        uint256 totalPower = 0;
        for (uint256 i = 0; i < daoMembers.length; i++) {
            totalPower += getVotingPower(daoMembers[i]);
        }
        return totalPower;
    }

    // Fallback function to receive Ether for funding projects (optional, for direct funding)
    receive() external payable {}
}
```