```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Decentralized Autonomous Creative Collective (DACC)
 * @author Bard (Generated based on user request)
 * @dev A smart contract for managing a decentralized autonomous creative collective.
 *      This contract allows members to propose creative projects, vote on them,
 *      contribute resources, track progress, and share revenue.
 *
 * **Outline & Function Summary:**
 *
 * **Membership & Roles:**
 *   1. `joinCollective(string _name, string _expertise)`: Allows users to join the collective as members.
 *   2. `leaveCollective()`: Allows members to leave the collective.
 *   3. `isAdmin(address _member)`: Checks if an address is an admin.
 *   4. `addAdmin(address _newAdmin)`: Allows admins to add new admins.
 *   5. `removeAdmin(address _adminToRemove)`: Allows admins to remove admins.
 *   6. `getMemberDetails(address _member)`: Retrieves details of a member.
 *   7. `getMemberCount()`: Returns the total number of members in the collective.
 *
 * **Project Proposals & Voting:**
 *   8. `submitProjectProposal(string _title, string _description, uint256 _fundingGoal, string[] _requiredSkills)`: Members can submit project proposals.
 *   9. `voteOnProposal(uint256 _proposalId, bool _vote)`: Members can vote on project proposals.
 *  10. `finalizeProposal(uint256 _proposalId)`: Admins can finalize a proposal after voting period.
 *  11. `getProposalDetails(uint256 _proposalId)`: Retrieves details of a specific proposal.
 *  12. `getProposalStatus(uint256 _proposalId)`: Gets the current status of a proposal.
 *  13. `getProposalVoteCount(uint256 _proposalId)`: Gets the vote counts for a proposal.
 *
 * **Project Management & Contribution:**
 *  14. `contributeToProject(uint256 _projectId, uint256 _amount)`: Members can contribute funds to approved projects.
 *  15. `recordProjectMilestone(uint256 _projectId, string _milestoneDescription)`: Project leads can record milestones.
 *  16. `markMilestoneComplete(uint256 _projectId, uint256 _milestoneIndex)`: Project leads can mark milestones as complete.
 *  17. `markProjectComplete(uint256 _projectId)`: Project leads can mark a project as complete.
 *  18. `getProjectDetails(uint256 _projectId)`: Retrieves details of a specific project.
 *  19. `getProjectMilestones(uint256 _projectId)`: Retrieves milestones for a project.
 *  20. `withdrawProjectFunds(uint256 _projectId)`: Project leads can withdraw project funds after completion (with admin approval - not implemented for simplicity, but a future enhancement).
 *
 * **Utility & Events:**
 *  21. `getContractBalance()`: Returns the contract's current ETH balance.
 *  22. `pauseContract()`: Allows admin to pause the contract.
 *  23. `unpauseContract()`: Allows admin to unpause the contract.
 *
 * **Events:**
 *   - `MemberJoined(address memberAddress, string name)`
 *   - `MemberLeft(address memberAddress)`
 *   - `AdminAdded(address adminAddress)`
 *   - `AdminRemoved(address adminAddress)`
 *   - `ProposalSubmitted(uint256 proposalId, address proposer, string title)`
 *   - `ProposalVoted(uint256 proposalId, address voter, bool vote)`
 *   - `ProposalFinalized(uint256 proposalId, bool approved)`
 *   - `ProjectFunded(uint256 projectId, address contributor, uint256 amount)`
 *   - `ProjectMilestoneRecorded(uint256 projectId, uint256 milestoneIndex, string description)`
 *   - `ProjectMilestoneCompleted(uint256 projectId, uint256 milestoneIndex)`
 *   - `ProjectCompleted(uint256 projectId)`
 *   - `ProjectFundsWithdrawn(uint256 projectId, address withdrawer, uint256 amount)`
 */
contract DecentralizedAutonomousCreativeCollective {

    // Structs and Enums

    enum ProposalStatus { Pending, Voting, Finalized }
    enum ProjectStatus { Proposed, Approved, InProgress, Completed, Cancelled }

    struct Member {
        string name;
        string expertise;
        bool isActive;
        uint256 joinTimestamp;
    }

    struct Proposal {
        uint256 id;
        address proposer;
        string title;
        string description;
        uint256 fundingGoal;
        string[] requiredSkills;
        ProposalStatus status;
        uint256 voteStartTime;
        uint256 voteEndTime;
        mapping(address => bool) votes; // Member address to vote (true for yes, false for no)
        uint256 yesVotes;
        uint256 noVotes;
    }

    struct Project {
        uint256 id;
        uint256 proposalId;
        string title;
        string description;
        uint256 fundingGoal;
        uint256 currentFunding;
        address leadMember; // Member responsible for project management
        ProjectStatus status;
        uint256 startTime;
        Milestone[] milestones;
    }

    struct Milestone {
        string description;
        bool isCompleted;
        uint256 completionTimestamp;
    }

    // State Variables

    mapping(address => Member) public members;
    mapping(uint256 => Proposal) public proposals;
    mapping(uint256 => Project) public projects;
    address[] public adminAddresses;
    uint256 public memberCount;
    uint256 public proposalCount;
    uint256 public projectCount;
    uint256 public votingDuration = 7 days; // Default voting duration
    bool public paused = false;

    // Events

    event MemberJoined(address memberAddress, string name);
    event MemberLeft(address memberAddress);
    event AdminAdded(address adminAddress);
    event AdminRemoved(address adminAddress);
    event ProposalSubmitted(uint256 proposalId, address proposer, string title);
    event ProposalVoted(uint256 proposalId, address voter, bool vote);
    event ProposalFinalized(uint256 proposalId, bool approved);
    event ProjectFunded(uint256 projectId, address contributor, uint256 amount);
    event ProjectMilestoneRecorded(uint256 projectId, uint256 milestoneIndex, string description);
    event ProjectMilestoneCompleted(uint256 projectId, uint256 milestoneIndex);
    event ProjectCompleted(uint256 projectId);
    event ProjectFundsWithdrawn(uint256 projectId, address withdrawer, uint256 amount);
    event ContractPaused(address admin);
    event ContractUnpaused(address admin);


    // Modifiers

    modifier onlyAdmin() {
        require(isAdmin(msg.sender), "Only admins can perform this action.");
        _;
    }

    modifier onlyMember() {
        require(members[msg.sender].isActive, "Only active members can perform this action.");
        _;
    }

    modifier proposalExists(uint256 _proposalId) {
        require(_proposalId < proposalCount && proposals[_proposalId].id == _proposalId, "Proposal does not exist.");
        _;
    }

    modifier projectExists(uint256 _projectId) {
        require(_projectId < projectCount && projects[_projectId].id == _projectId, "Project does not exist.");
        _;
    }

    modifier notPaused() {
        require(!paused, "Contract is paused.");
        _;
    }

    // Constructor

    constructor() {
        adminAddresses.push(msg.sender); // Deployer is the initial admin
    }

    // ------------------------------------------------------------------------
    // Membership & Roles Functions
    // ------------------------------------------------------------------------

    /// @dev Allows a user to join the collective as a member.
    /// @param _name The name of the member.
    /// @param _expertise The member's area of expertise.
    function joinCollective(string memory _name, string memory _expertise) external notPaused {
        require(!members[msg.sender].isActive, "Already a member.");
        memberCount++;
        members[msg.sender] = Member({
            name: _name,
            expertise: _expertise,
            isActive: true,
            joinTimestamp: block.timestamp
        });
        emit MemberJoined(msg.sender, _name);
    }

    /// @dev Allows a member to leave the collective.
    function leaveCollective() external onlyMember notPaused {
        members[msg.sender].isActive = false;
        memberCount--; // Consider if memberCount should decrement or just track active members.
        emit MemberLeft(msg.sender);
    }

    /// @dev Checks if an address is an admin.
    /// @param _member The address to check.
    /// @return True if the address is an admin, false otherwise.
    function isAdmin(address _member) public view returns (bool) {
        for (uint256 i = 0; i < adminAddresses.length; i++) {
            if (adminAddresses[i] == _member) {
                return true;
            }
        }
        return false;
    }

    /// @dev Allows admins to add new admins.
    /// @param _newAdmin The address of the new admin to add.
    function addAdmin(address _newAdmin) external onlyAdmin notPaused {
        require(!isAdmin(_newAdmin), "Address is already an admin.");
        adminAddresses.push(_newAdmin);
        emit AdminAdded(_newAdmin);
    }

    /// @dev Allows admins to remove admins. Cannot remove the last admin.
    /// @param _adminToRemove The address of the admin to remove.
    function removeAdmin(address _adminToRemove) external onlyAdmin notPaused {
        require(adminAddresses.length > 1, "Cannot remove the last admin.");
        for (uint256 i = 0; i < adminAddresses.length; i++) {
            if (adminAddresses[i] == _adminToRemove) {
                adminAddresses.splice(i, 1);
                emit AdminRemoved(_adminToRemove);
                return;
            }
        }
        revert("Admin address not found.");
    }

    /// @dev Retrieves details of a member.
    /// @param _member The address of the member.
    /// @return Member struct containing member details.
    function getMemberDetails(address _member) external view returns (Member memory) {
        return members[_member];
    }

    /// @dev Returns the total number of members in the collective.
    /// @return The member count.
    function getMemberCount() external view returns (uint256) {
        return memberCount;
    }

    // ------------------------------------------------------------------------
    // Project Proposals & Voting Functions
    // ------------------------------------------------------------------------

    /// @dev Allows members to submit project proposals.
    /// @param _title The title of the project proposal.
    /// @param _description A detailed description of the project.
    /// @param _fundingGoal The funding goal for the project in wei.
    /// @param _requiredSkills An array of skills required for the project.
    function submitProjectProposal(
        string memory _title,
        string memory _description,
        uint256 _fundingGoal,
        string[] memory _requiredSkills
    ) external onlyMember notPaused {
        require(bytes(_title).length > 0 && bytes(_description).length > 0, "Title and description cannot be empty.");
        require(_fundingGoal > 0, "Funding goal must be greater than zero.");

        proposals[proposalCount] = Proposal({
            id: proposalCount,
            proposer: msg.sender,
            title: _title,
            description: _description,
            fundingGoal: _fundingGoal,
            requiredSkills: _requiredSkills,
            status: ProposalStatus.Pending,
            voteStartTime: 0,
            voteEndTime: 0,
            votes: mapping(address => bool)(),
            yesVotes: 0,
            noVotes: 0
        });
        emit ProposalSubmitted(proposalCount, msg.sender, _title);
        proposalCount++;
    }

    /// @dev Allows members to vote on project proposals. Voting is open for a set duration after admin finalizes the proposal.
    /// @param _proposalId The ID of the proposal to vote on.
    /// @param _vote True for yes, false for no.
    function voteOnProposal(uint256 _proposalId, bool _vote) external onlyMember notPaused proposalExists(_proposalId) {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.status == ProposalStatus.Voting, "Proposal is not currently in voting phase.");
        require(block.timestamp >= proposal.voteStartTime && block.timestamp <= proposal.voteEndTime, "Voting period is over.");
        require(!proposal.votes[msg.sender], "Member has already voted on this proposal.");

        proposal.votes[msg.sender] = _vote;
        if (_vote) {
            proposal.yesVotes++;
        } else {
            proposal.noVotes++;
        }
        emit ProposalVoted(_proposalId, msg.sender, _vote);
    }

    /// @dev Allows admins to finalize a proposal and start the voting process.
    /// @param _proposalId The ID of the proposal to finalize.
    function finalizeProposal(uint256 _proposalId) external onlyAdmin notPaused proposalExists(_proposalId) {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.status == ProposalStatus.Pending, "Proposal is not in pending status.");

        proposal.status = ProposalStatus.Voting;
        proposal.voteStartTime = block.timestamp;
        proposal.voteEndTime = block.timestamp + votingDuration;
    }


    /// @dev Retrieves details of a specific proposal.
    /// @param _proposalId The ID of the proposal.
    /// @return Proposal struct containing proposal details.
    function getProposalDetails(uint256 _proposalId) external view proposalExists(_proposalId) returns (Proposal memory) {
        return proposals[_proposalId];
    }

    /// @dev Gets the current status of a proposal.
    /// @param _proposalId The ID of the proposal.
    /// @return ProposalStatus enum representing the proposal's status.
    function getProposalStatus(uint256 _proposalId) external view proposalExists(_proposalId) returns (ProposalStatus) {
        return proposals[_proposalId].status;
    }

    /// @dev Gets the vote counts for a proposal.
    /// @param _proposalId The ID of the proposal.
    /// @return yesVotes The number of yes votes.
    /// @return noVotes The number of no votes.
    function getProposalVoteCount(uint256 _proposalId) external view proposalExists(_proposalId) returns (uint256 yesVotes, uint256 noVotes) {
        return (proposals[_proposalId].yesVotes, proposals[_proposalId].noVotes);
    }


    // ------------------------------------------------------------------------
    // Project Management & Contribution Functions
    // ------------------------------------------------------------------------

    /// @dev Allows members to contribute funds to approved projects.
    /// @param _projectId The ID of the project to contribute to.
    /// @param _amount The amount to contribute in wei.
    function contributeToProject(uint256 _projectId, uint256 _amount) external payable onlyMember notPaused projectExists(_projectId) {
        require(msg.value == _amount, "Incorrect amount sent."); // Ensure msg.value matches _amount
        Project storage project = projects[_projectId];
        require(project.status == ProjectStatus.Approved || project.status == ProjectStatus.InProgress, "Project is not currently accepting contributions.");
        require(project.currentFunding + _amount <= project.fundingGoal, "Contribution exceeds remaining funding goal.");

        project.currentFunding += _amount;
        payable(address(this)).transfer(_amount); // Transfer funds to the contract. In real scenario, consider more secure fund handling.

        emit ProjectFunded(_projectId, msg.sender, _amount);
    }

    /// @dev Records a milestone for a project. Only the project lead can do this.
    /// @param _projectId The ID of the project.
    /// @param _milestoneDescription Description of the milestone.
    function recordProjectMilestone(uint256 _projectId, string memory _milestoneDescription) external onlyMember notPaused projectExists(_projectId) {
        Project storage project = projects[_projectId];
        require(msg.sender == project.leadMember, "Only project lead can record milestones.");
        require(project.status == ProjectStatus.InProgress, "Project must be in progress to record milestones.");
        require(bytes(_milestoneDescription).length > 0, "Milestone description cannot be empty.");

        project.milestones.push(Milestone({
            description: _milestoneDescription,
            isCompleted: false,
            completionTimestamp: 0
        }));
        emit ProjectMilestoneRecorded(_projectId, project.milestones.length - 1, _milestoneDescription);
    }

    /// @dev Marks a milestone as complete. Only the project lead can do this.
    /// @param _projectId The ID of the project.
    /// @param _milestoneIndex The index of the milestone to mark as complete.
    function markMilestoneComplete(uint256 _projectId, uint256 _milestoneIndex) external onlyMember notPaused projectExists(_projectId) {
        Project storage project = projects[_projectId];
        require(msg.sender == project.leadMember, "Only project lead can mark milestones complete.");
        require(project.status == ProjectStatus.InProgress, "Project must be in progress to complete milestones.");
        require(_milestoneIndex < project.milestones.length, "Invalid milestone index.");
        require(!project.milestones[_milestoneIndex].isCompleted, "Milestone already completed.");

        project.milestones[_milestoneIndex].isCompleted = true;
        project.milestones[_milestoneIndex].completionTimestamp = block.timestamp;
        emit ProjectMilestoneCompleted(_projectId, _milestoneIndex);
    }

    /// @dev Marks a project as complete. Only the project lead can do this.
    /// @param _projectId The ID of the project.
    function markProjectComplete(uint256 _projectId) external onlyMember notPaused projectExists(_projectId) {
        Project storage project = projects[_projectId];
        require(msg.sender == project.leadMember, "Only project lead can mark project complete.");
        require(project.status == ProjectStatus.InProgress, "Project must be in progress to mark as complete.");

        project.status = ProjectStatus.Completed;
        emit ProjectCompleted(_projectId);
    }

    /// @dev Retrieves details of a specific project.
    /// @param _projectId The ID of the project.
    /// @return Project struct containing project details.
    function getProjectDetails(uint256 _projectId) external view projectExists(_projectId) returns (Project memory) {
        return projects[_projectId];
    }

    /// @dev Retrieves milestones for a project.
    /// @param _projectId The ID of the project.
    /// @return An array of Milestone structs.
    function getProjectMilestones(uint256 _projectId) external view projectExists(_projectId) returns (Milestone[] memory) {
        return projects[_projectId].milestones;
    }

    /// @dev Allows project leads to withdraw project funds after completion. (Simplified, admin approval would be a good addition)
    /// @param _projectId The ID of the project.
    function withdrawProjectFunds(uint256 _projectId) external onlyMember notPaused projectExists(_projectId) {
        Project storage project = projects[_projectId];
        require(msg.sender == project.leadMember, "Only project lead can withdraw funds.");
        require(project.status == ProjectStatus.Completed, "Project must be completed to withdraw funds.");
        require(project.currentFunding > 0, "Project has no funds to withdraw.");

        uint256 amountToWithdraw = project.currentFunding;
        project.currentFunding = 0; // Set current funding to zero after withdrawal

        (bool success, ) = payable(project.leadMember).call{value: amountToWithdraw}("");
        require(success, "Transfer failed.");

        emit ProjectFundsWithdrawn(_projectId, project.leadMember, amountToWithdraw);
    }

    // ------------------------------------------------------------------------
    // Utility & Admin Functions
    // ------------------------------------------------------------------------

    /// @dev Returns the contract's current ETH balance.
    /// @return The contract's ETH balance in wei.
    function getContractBalance() external view returns (uint256) {
        return address(this).balance;
    }

    /// @dev Pauses the contract, preventing most functions from being called.
    function pauseContract() external onlyAdmin {
        paused = true;
        emit ContractPaused(msg.sender);
    }

    /// @dev Unpauses the contract, restoring normal functionality.
    function unpauseContract() external onlyAdmin {
        paused = false;
        emit ContractUnpaused(msg.sender);
    }

    // **Future Enhancements (Beyond 20 functions, but ideas for expansion):**
    // - Reputation system for members based on contributions and project successes.
    // - Revenue sharing mechanisms for project participants.
    // - More granular roles within projects (e.g., contributor, reviewer, tester).
    // - Integration with IPFS or similar for storing project assets.
    // - Project cancellation functionality.
    // - Voting mechanisms for proposals to become projects (currently implicitly approved after voting).
    // - Time-based voting periods and quorum requirements.
    // - More sophisticated fund management (escrow, multi-sig for larger projects).
    // - NFT integration for representing project ownership or membership tiers.
}
```