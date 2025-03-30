```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Decentralized Autonomous Creative Agency (DACA)
 * @author Bard (AI Assistant)
 * @dev A smart contract implementing a Decentralized Autonomous Creative Agency (DACA).
 * This contract facilitates the creation, management, and execution of creative projects in a decentralized manner.
 * It incorporates advanced concepts like skill-based matching, reputation systems, on-chain governance for creative decisions,
 * dynamic task pricing, and even a decentralized portfolio system for members.
 *
 * Function Summary:
 * -----------------
 *
 * // --- Membership & Roles ---
 * 1. joinAgency(string memory _profileHash, string memory _skillsHash): Allows users to apply to join the agency.
 * 2. approveMembership(address _applicant, string memory _profileHash, string memory _skillsHash): Governance function to approve a member application.
 * 3. removeMembership(address _member): Governance function to remove a member from the agency.
 * 4. getAgencyMembers(): Returns a list of all agency members.
 * 5. getMemberProfile(address _member): Returns the profile and skills hash of a member.
 *
 * // --- Project Proposals & Management ---
 * 6. submitProjectProposal(string memory _proposalHash, string memory _requiredSkillsHash, uint256 _budget): Members can submit project proposals.
 * 7. voteOnProjectProposal(uint256 _projectId, bool _approve): Agency members vote on project proposals.
 * 8. getProjectDetails(uint256 _projectId): Returns details of a specific project.
 * 9. startProject(uint256 _projectId): Governance function to start a project after proposal approval.
 * 10. assignTask(uint256 _projectId, uint256 _taskId, address _assignee, string memory _taskDescriptionHash, uint256 _taskBudget): Assign tasks to members within a project.
 * 11. completeTask(uint256 _projectId, uint256 _taskId, string memory _submissionHash): Members can mark tasks as completed with a submission.
 * 12. verifyTaskCompletion(uint256 _projectId, uint256 _taskId, bool _isApproved): Governance function to verify task completion.
 * 13. payTask(uint256 _projectId, uint256 _taskId): Pays out the budget for a completed and verified task.
 * 14. finalizeProject(uint256 _projectId): Governance function to finalize a project after all tasks are completed and paid.
 *
 * // --- Reputation & Skill System ---
 * 15. rateMemberSkill(address _member, string memory _skillName, uint8 _rating): Members can rate other members' skills (reputation based).
 * 16. getMemberSkillRating(address _member, string memory _skillName): Retrieves the skill rating of a member.
 * 17. getTopSkilledMembers(string memory _skillName, uint256 _limit): Returns a list of top-rated members for a specific skill.
 *
 * // --- Advanced & Creative Functions ---
 * 18. proposeDynamicTaskPricing(uint256 _projectId, uint256 _taskId, uint256 _newBudget):  Propose a dynamic price adjustment for a task (governance vote).
 * 19. voteOnDynamicPricing(uint256 _projectId, uint256 _taskId, bool _approve): Vote on a dynamic task pricing proposal.
 * 20. createDecentralizedPortfolio(address _member, string memory _portfolioHash): Members can create a decentralized portfolio linked to their profile.
 * 21. getMemberPortfolio(address _member): Retrieve a member's decentralized portfolio hash.
 * 22. getAgencyTreasuryBalance(): View the agency's treasury balance.
 * 23. withdrawFromTreasury(address _to, uint256 _amount): Governance function to withdraw funds from the treasury.
 */

contract DecentralizedCreativeAgency {

    // --- State Variables ---

    address public governanceAddress; // Address with governance rights
    mapping(address => bool) public isAgencyMember;
    address[] public agencyMembers;

    struct MemberProfile {
        string profileHash; // IPFS hash of member profile
        string skillsHash;  // IPFS hash of member skills
        bool isActive;
    }
    mapping(address => MemberProfile) public memberProfiles;

    uint256 public projectCounter;
    struct Project {
        uint256 projectId;
        string proposalHash;    // IPFS hash of project proposal document
        string requiredSkillsHash; // IPFS hash of required skills for the project
        uint256 budget;
        ProjectStatus status;
        mapping(uint256 => Task) tasks;
        uint256 taskCounter;
        mapping(address => bool) hasVotedOnProposal; // Track members who voted on project proposal
        uint256 votesForProposal;
    }
    mapping(uint256 => Project) public projects;
    enum ProjectStatus { Proposed, Approved, Active, Finalized }

    struct Task {
        uint256 taskId;
        address assignee;
        string descriptionHash; // IPFS hash of task description
        uint256 budget;
        TaskStatus status;
        string submissionHash; // IPFS hash of task submission
    }
    enum TaskStatus { Created, Assigned, Completed, Verified, Paid }

    mapping(address => mapping(string => SkillRating)) public memberSkillRatings;
    struct SkillRating {
        uint8 rating; // 1-5 rating
        uint256 ratingCount;
    }

    mapping(address => string) public memberPortfolios; // IPFS hash of member portfolios

    uint256 public agencyTreasuryBalance;

    // --- Events ---
    event MembershipRequested(address indexed member, string profileHash, string skillsHash);
    event MembershipApproved(address indexed member, string profileHash, string skillsHash);
    event MembershipRemoved(address indexed member);
    event ProjectProposed(uint256 projectId, address proposer, string proposalHash, string requiredSkillsHash, uint256 budget);
    event ProjectVoteCast(uint256 projectId, address voter, bool approve);
    event ProjectApproved(uint256 projectId);
    event ProjectStarted(uint256 projectId);
    event TaskAssigned(uint256 projectId, uint256 taskId, address assignee, string descriptionHash, uint256 budget);
    event TaskCompleted(uint256 projectId, uint256 taskId, address submitter, string submissionHash);
    event TaskVerified(uint256 projectId, uint256 taskId, bool isApproved);
    event TaskPaid(uint256 projectId, uint256 taskId, address payee);
    event ProjectFinalized(uint256 projectId);
    event SkillRated(address indexed member, address rater, string skillName, uint8 rating);
    event DynamicPricingProposed(uint256 projectId, uint256 taskId, uint256 newBudget);
    event DynamicPricingVoteCast(uint256 projectId, uint256 taskId, address voter, bool approve);
    event DynamicPricingApproved(uint256 projectId, uint256 taskId, uint256 newBudget);
    event PortfolioCreated(address indexed member, string portfolioHash);
    event TreasuryWithdrawal(address to, uint256 amount);

    // --- Modifiers ---
    modifier onlyGovernance() {
        require(msg.sender == governanceAddress, "Only governance address can call this function.");
        _;
    }

    modifier onlyAgencyMember() {
        require(isAgencyMember[msg.sender], "Only agency members can call this function.");
        _;
    }

    modifier projectExists(uint256 _projectId) {
        require(_projectId < projectCounter, "Project does not exist.");
        _;
    }

    modifier taskExists(uint256 _projectId, uint256 _taskId) {
        require(_taskId < projects[_projectId].taskCounter, "Task does not exist.");
        _;
    }

    modifier validRating(uint8 _rating) {
        require(_rating >= 1 && _rating <= 5, "Rating must be between 1 and 5.");
        _;
    }

    // --- Constructor ---
    constructor() {
        governanceAddress = msg.sender; // Deployer is the initial governance address
    }

    // --- Membership & Roles ---
    function setGovernanceAddress(address _newGovernanceAddress) public onlyGovernance {
        require(_newGovernanceAddress != address(0), "Invalid governance address.");
        governanceAddress = _newGovernanceAddress;
    }

    function joinAgency(string memory _profileHash, string memory _skillsHash) public {
        require(!isAgencyMember[msg.sender], "Already an agency member.");
        require(bytes(_profileHash).length > 0 && bytes(_skillsHash).length > 0, "Profile and skills hashes are required.");
        memberProfiles[msg.sender] = MemberProfile({
            profileHash: _profileHash,
            skillsHash: _skillsHash,
            isActive: false // Initially inactive, needs governance approval
        });
        emit MembershipRequested(msg.sender, _profileHash, _skillsHash);
    }

    function approveMembership(address _applicant, string memory _profileHash, string memory _skillsHash) public onlyGovernance {
        require(!isAgencyMember[_applicant], "Applicant is already a member.");
        require(!memberProfiles[_applicant].isActive, "Applicant membership already active.");
        require(bytes(_profileHash).length > 0 && bytes(_skillsHash).length > 0, "Profile and skills hashes are required."); // Re-check in case of direct governance call

        isAgencyMember[_applicant] = true;
        agencyMembers.push(_applicant);
        memberProfiles[_applicant].isActive = true;
        memberProfiles[_applicant].profileHash = _profileHash; // Update in case it was changed since application
        memberProfiles[_applicant].skillsHash = _skillsHash;
        emit MembershipApproved(_applicant, _profileHash, _skillsHash);
    }

    function removeMembership(address _member) public onlyGovernance {
        require(isAgencyMember[_member], "Not an agency member.");
        isAgencyMember[_member] = false;
        memberProfiles[_member].isActive = false;

        // Remove from agencyMembers array (more gas-efficient way in modern Solidity if order doesn't matter)
        for (uint256 i = 0; i < agencyMembers.length; i++) {
            if (agencyMembers[i] == _member) {
                agencyMembers[i] = agencyMembers[agencyMembers.length - 1];
                agencyMembers.pop();
                break;
            }
        }
        emit MembershipRemoved(_member);
    }

    function getAgencyMembers() public view returns (address[] memory) {
        return agencyMembers;
    }

    function getMemberProfile(address _member) public view returns (string memory profileHash, string memory skillsHash, bool isActive) {
        require(isAgencyMember[_member], "Not an agency member.");
        MemberProfile memory profile = memberProfiles[_member];
        return (profile.profileHash, profile.skillsHash, profile.isActive);
    }

    // --- Project Proposals & Management ---
    function submitProjectProposal(string memory _proposalHash, string memory _requiredSkillsHash, uint256 _budget) public onlyAgencyMember {
        require(bytes(_proposalHash).length > 0 && bytes(_requiredSkillsHash).length > 0 && _budget > 0, "Invalid project proposal details.");
        uint256 projectId = projectCounter++;
        projects[projectId] = Project({
            projectId: projectId,
            proposalHash: _proposalHash,
            requiredSkillsHash: _requiredSkillsHash,
            budget: _budget,
            status: ProjectStatus.Proposed,
            taskCounter: 0,
            votesForProposal: 0
        });
        emit ProjectProposed(projectId, msg.sender, _proposalHash, _requiredSkillsHash, _budget);
    }

    function voteOnProjectProposal(uint256 _projectId, bool _approve) public onlyAgencyMember projectExists(_projectId) {
        Project storage project = projects[_projectId];
        require(project.status == ProjectStatus.Proposed, "Project is not in 'Proposed' status.");
        require(!project.hasVotedOnProposal[msg.sender], "Already voted on this proposal.");

        project.hasVotedOnProposal[msg.sender] = true;
        if (_approve) {
            project.votesForProposal++;
        }
        emit ProjectVoteCast(_projectId, msg.sender, _approve);

        // Simple majority for approval (can be adjusted for more complex governance)
        if (project.votesForProposal > (agencyMembers.length / 2)) {
            project.status = ProjectStatus.Approved;
            emit ProjectApproved(_projectId);
        }
    }

    function getProjectDetails(uint256 _projectId) public view projectExists(_projectId) returns (
        uint256 projectId,
        string memory proposalHash,
        string memory requiredSkillsHash,
        uint256 budget,
        ProjectStatus status,
        uint256 taskCount
    ) {
        Project memory project = projects[_projectId];
        return (
            project.projectId,
            project.proposalHash,
            project.requiredSkillsHash,
            project.budget,
            project.status,
            project.taskCounter
        );
    }

    function startProject(uint256 _projectId) public onlyGovernance projectExists(_projectId) {
        Project storage project = projects[_projectId];
        require(project.status == ProjectStatus.Approved, "Project must be approved to start.");
        project.status = ProjectStatus.Active;
        emit ProjectStarted(_projectId);
    }

    function assignTask(uint256 _projectId, address _assignee, string memory _taskDescriptionHash, uint256 _taskBudget) public onlyGovernance projectExists(_projectId) {
        Project storage project = projects[_projectId];
        require(project.status == ProjectStatus.Active, "Project must be active to assign tasks.");
        require(isAgencyMember[_assignee], "Assignee must be an agency member.");
        require(_taskBudget > 0 && _taskBudget <= project.budget, "Invalid task budget.");

        uint256 taskId = project.taskCounter++;
        project.tasks[taskId] = Task({
            taskId: taskId,
            assignee: _assignee,
            descriptionHash: _taskDescriptionHash,
            budget: _taskBudget,
            status: TaskStatus.Assigned,
            submissionHash: ""
        });
        project.budget -= _taskBudget; // Reduce project budget by task budget
        emit TaskAssigned(_projectId, taskId, _assignee, _taskDescriptionHash, _taskBudget);
    }

    function completeTask(uint256 _projectId, uint256 _taskId, string memory _submissionHash) public onlyAgencyMember projectExists(_projectId) taskExists(_projectId, _taskId) {
        Project storage project = projects[_projectId];
        Task storage task = project.tasks[_taskId];
        require(task.assignee == msg.sender, "Only assignee can complete the task.");
        require(task.status == TaskStatus.Assigned, "Task must be in 'Assigned' status.");
        require(bytes(_submissionHash).length > 0, "Submission hash is required.");

        task.status = TaskStatus.Completed;
        task.submissionHash = _submissionHash;
        emit TaskCompleted(_projectId, _taskId, msg.sender, _submissionHash);
    }

    function verifyTaskCompletion(uint256 _projectId, uint256 _taskId, bool _isApproved) public onlyGovernance projectExists(_projectId) taskExists(_projectId, _taskId) {
        Project storage project = projects[_projectId];
        Task storage task = project.tasks[_taskId];
        require(task.status == TaskStatus.Completed, "Task must be in 'Completed' status.");

        if (_isApproved) {
            task.status = TaskStatus.Verified;
        } else {
            task.status = TaskStatus.Assigned; // Revert back to assigned if not approved (can add more complex rejection flow)
        }
        emit TaskVerified(_projectId, _taskId, _isApproved);
    }

    function payTask(uint256 _projectId, uint256 _taskId) public onlyGovernance projectExists(_projectId) taskExists(_projectId, _taskId) {
        Project storage project = projects[_projectId];
        Task storage task = project.tasks[_taskId];
        require(task.status == TaskStatus.Verified, "Task must be in 'Verified' status.");
        require(agencyTreasuryBalance >= task.budget, "Insufficient funds in agency treasury.");

        task.status = TaskStatus.Paid;
        agencyTreasuryBalance -= task.budget;
        payable(task.assignee).transfer(task.budget);
        emit TaskPaid(_projectId, _taskId, task.assignee);
    }

    function finalizeProject(uint256 _projectId) public onlyGovernance projectExists(_projectId) {
        Project storage project = projects[_projectId];
        require(project.status == ProjectStatus.Active, "Project must be active to finalize.");

        bool allTasksPaid = true;
        for (uint256 i = 0; i < project.taskCounter; i++) {
            if (project.tasks[i].status != TaskStatus.Paid) {
                allTasksPaid = false;
                break;
            }
        }
        require(allTasksPaid, "All tasks must be paid before project can be finalized.");

        project.status = ProjectStatus.Finalized;
        emit ProjectFinalized(_projectId);
    }

    // --- Reputation & Skill System ---
    function rateMemberSkill(address _member, string memory _skillName, uint8 _rating) public onlyAgencyMember validRating(_rating) {
        require(isAgencyMember(_member), "Target member must be an agency member.");
        memberSkillRatings[_member][_skillName].rating += _rating;
        memberSkillRatings[_member][_skillName].ratingCount++;
        emit SkillRated(_member, msg.sender, _skillName, _rating);
    }

    function getMemberSkillRating(address _member, string memory _skillName) public view returns (uint8 averageRating, uint256 ratingCount) {
        require(isAgencyMember(_member), "Target member must be an agency member.");
        SkillRating memory ratingData = memberSkillRatings[_member][_skillName];
        if (ratingData.ratingCount == 0) {
            return (0, 0); // No ratings yet
        }
        return (uint8(ratingData.rating / ratingData.ratingCount), ratingData.ratingCount);
    }

    function getTopSkilledMembers(string memory _skillName, uint256 _limit) public view returns (address[] memory topMembers, uint8[] memory ratings) {
        require(_limit > 0, "Limit must be greater than 0.");
        uint256 memberCount = agencyMembers.length;
        uint256 count = 0;
        uint256 resultCount = 0;

        address[] memory resultMembers = new address[](_limit);
        uint8[] memory resultRatings = new uint8[](_limit);

        // Simple sorting (can be optimized if needed for larger member counts)
        for (uint256 i = 0; i < memberCount; i++) {
            address member = agencyMembers[i];
            (uint8 rating, ) = getMemberSkillRating(member, _skillName);

            if (count < _limit) {
                resultMembers[count] = member;
                resultRatings[count] = rating;
                count++;
            } else {
                // In a real-world scenario, you'd implement a proper sorting algorithm here
                // For simplicity, this example just finds the member with the lowest rating in the current result set
                uint8 minRating = 5; // Start with max possible rating
                uint256 minIndex = 0;
                for (uint256 j = 0; j < _limit; j++) {
                    if (resultRatings[j] < minRating) {
                        minRating = resultRatings[j];
                        minIndex = j;
                    }
                }
                if (rating > minRating) {
                    resultMembers[minIndex] = member;
                    resultRatings[minIndex] = rating;
                }
            }
        }
        resultCount = count < _limit ? count : _limit; // Adjust result count if fewer members than limit
        topMembers = new address[](resultCount);
        ratings = new uint8[](resultCount);
        for(uint256 i=0; i< resultCount; i++){
            topMembers[i] = resultMembers[i];
            ratings[i] = resultRatings[i];
        }
        return (topMembers, ratings);
    }


    // --- Advanced & Creative Functions ---
    function proposeDynamicTaskPricing(uint256 _projectId, uint256 _taskId, uint256 _newBudget) public onlyGovernance projectExists(_projectId) taskExists(_projectId, _taskId) {
        Project storage project = projects[_projectId];
        Task storage task = project.tasks[_taskId];
        require(task.status == TaskStatus.Assigned || task.status == TaskStatus.Completed, "Task must be assigned or completed to propose dynamic pricing.");
        require(_newBudget > 0 && _newBudget <= project.budget + task.budget, "Invalid new budget."); // Ensure new budget is within project's total budget capacity

        // Store proposed new budget (or create a separate struct for dynamic pricing proposals if more complex info is needed)
        task.budget = _newBudget; // For simplicity, directly updating the budget for demonstration. In real scenario, might be better to store proposal and update after voting.

        emit DynamicPricingProposed(_projectId, _taskId, _newBudget);
        // In a real-world scenario, you would trigger a voting process here
        // For this simplified example, we'll auto-approve for demonstration purposes (remove in production)
        approveDynamicPricing(_projectId, _taskId);
    }

    // Simplified auto-approval for demonstration - remove in production and implement actual voting
    function approveDynamicPricing(uint256 _projectId, uint256 _taskId) private projectExists(_projectId) taskExists(_projectId, _taskId) {
        Task storage task = projects[_projectId].tasks[_taskId];
        emit DynamicPricingApproved(_projectId, _taskId, task.budget);
    }

    // In a real decentralized voting system, you'd have a function like this:
    /*
    function voteOnDynamicPricing(uint256 _projectId, uint256 _taskId, bool _approve) public onlyAgencyMember projectExists(_projectId) taskExists(_projectId, _taskId) {
        // ... (Voting logic - track votes, check quorum, etc.) ...
        emit DynamicPricingVoteCast(_projectId, _taskId, msg.sender, _approve);
        if (_approve) {
            approveDynamicPricing(_projectId, _taskId);
        }
    }
    */


    function createDecentralizedPortfolio(address _member, string memory _portfolioHash) public onlyAgencyMember {
        require(msg.sender == _member, "Only member can create their own portfolio.");
        require(bytes(_portfolioHash).length > 0, "Portfolio hash is required.");
        memberPortfolios[_member] = _portfolioHash;
        emit PortfolioCreated(_member, _portfolioHash);
    }

    function getMemberPortfolio(address _member) public view returns (string memory portfolioHash) {
        require(isAgencyMember(_member), "Not an agency member.");
        return memberPortfolios[_member];
    }

    function getAgencyTreasuryBalance() public view returns (uint256) {
        return agencyTreasuryBalance;
    }

    function depositToTreasury() public payable {
        agencyTreasuryBalance += msg.value;
    }

    function withdrawFromTreasury(address _to, uint256 _amount) public onlyGovernance {
        require(_to != address(0), "Invalid recipient address.");
        require(agencyTreasuryBalance >= _amount, "Insufficient treasury balance.");
        agencyTreasuryBalance -= _amount;
        payable(_to).transfer(_amount);
        emit TreasuryWithdrawal(_to, _amount);
    }
}
```