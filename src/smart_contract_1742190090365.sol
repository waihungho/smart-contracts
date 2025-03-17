```solidity
pragma solidity ^0.8.0;

/**
 * @title Decentralized Autonomous Organization (DAO) with Dynamic Resource Allocation & Skill-Based Contribution
 * @author Bard (AI Assistant)
 * @dev This smart contract implements a DAO with advanced features focusing on dynamic resource allocation based on community needs
 *      and skill-based contribution, rewarding members for their expertise and active participation. It incorporates a reputation system
 *      and skill verification to ensure quality contributions.  This contract is designed to be unique and avoids direct duplication
 *      of common open-source DAO structures by focusing on dynamic resource management and skill-based incentives.
 *
 * **Outline & Function Summary:**
 *
 * **Membership & Roles:**
 *   1. `joinDAO()`: Allows users to request membership in the DAO.
 *   2. `approveMembership(address _member)`: Admin function to approve pending membership requests.
 *   3. `revokeMembership(address _member)`: Admin function to remove a member from the DAO.
 *   4. `listMembers()`: Returns a list of current DAO members.
 *   5. `isAdmin(address _account)`: Checks if an address is an admin.
 *
 * **Skill Management & Verification:**
 *   6. `registerSkill(string memory _skillName)`: Members can register their skills.
 *   7. `requestSkillVerification(address _member, string memory _skillName)`: Members can request verification of a skill by other members.
 *   8. `verifySkill(address _member, string memory _skillName)`: Members can verify another member's skill.
 *   9. `getMemberSkills(address _member)`: Returns a list of skills registered and verified for a member.
 *
 * **Proposal System (Dynamic Resource Allocation & Skill-Based Tasks):**
 *   10. `createResourceProposal(string memory _title, string memory _description, uint256 _amount, address _recipient)`: Propose allocation of resources (e.g., ETH, tokens).
 *   11. `createSkillTaskProposal(string memory _title, string memory _description, string[] memory _requiredSkills, uint256 _reward)`: Propose a task requiring specific skills with a reward.
 *   12. `voteOnProposal(uint256 _proposalId, bool _vote)`: Members can vote on active proposals.
 *   13. `executeProposal(uint256 _proposalId)`: Executes a proposal if it passes and is executable.
 *   14. `getProposalDetails(uint256 _proposalId)`: Returns details of a specific proposal.
 *   15. `listProposals()`: Returns a list of all proposal IDs.
 *   16. `getPendingProposals()`: Returns a list of proposal IDs that are currently in voting.
 *   17. `getExecutedProposals()`: Returns a list of proposal IDs that have been executed.
 *
 * **Reputation & Contribution Tracking:**
 *   18. `contributeToTask(uint256 _proposalId)`: Members can register their contribution to a skill-based task proposal.
 *   19. `markTaskCompletion(uint256 _proposalId)`: Function (potentially admin/task creator) to mark a skill-based task as completed, distributing rewards.
 *   20. `getMemberReputation(address _member)`: Returns the reputation score of a member based on verified skills and task contributions.
 *
 * **Emergency & Admin Functions:**
 *   21. `pauseContract()`: Admin function to pause core functionalities in case of emergency.
 *   22. `unpauseContract()`: Admin function to unpause the contract.
 */

contract DynamicSkillDAO {
    // --- State Variables ---
    address public admin;
    mapping(address => bool) public members;
    address[] public memberList;
    uint256 public memberCount;

    mapping(address => string[]) public memberSkills; // Skills registered by members
    mapping(address => mapping(string => bool)) public verifiedSkills; // Skill verification status

    struct Proposal {
        uint256 id;
        string title;
        string description;
        ProposalType proposalType;
        ProposalStatus status;
        uint256 startTime;
        uint256 endTime;
        mapping(address => bool) votes; // Members who voted and their vote (true for yes, false for no)
        uint256 yesVotes;
        uint256 noVotes;
        address proposer;
        // Specific to Resource Proposals
        uint256 resourceAmount;
        address resourceRecipient;
        // Specific to Skill Task Proposals
        string[] requiredSkills;
        uint256 taskReward;
        mapping(address => bool) taskContributors; // Members who contributed to the task
        bool taskCompleted;
    }

    enum ProposalType { RESOURCE_ALLOCATION, SKILL_TASK, POLICY_CHANGE }
    enum ProposalStatus { PENDING, ACTIVE, PASSED, REJECTED, EXECUTED }

    mapping(uint256 => Proposal) public proposals;
    uint256 public proposalCount;
    uint256 public votingDuration = 7 days; // Default voting duration
    uint256 public quorumPercentage = 50; // Default quorum percentage for proposals to pass
    bool public paused = false;

    mapping(address => uint256) public memberReputation; // Reputation score for members

    // --- Events ---
    event MembershipRequested(address indexed member);
    event MembershipApproved(address indexed member);
    event MembershipRevoked(address indexed member);
    event SkillRegistered(address indexed member, string skillName);
    event SkillVerificationRequested(address indexed member, string skillName, address verifier);
    event SkillVerified(address indexed member, string skillName, address verifier);
    event ResourceProposalCreated(uint256 proposalId, string title, uint256 amount, address recipient, address proposer);
    event SkillTaskProposalCreated(uint256 proposalId, string title, string[] requiredSkills, uint256 reward, address proposer);
    event ProposalVoted(uint256 proposalId, address voter, bool vote);
    event ProposalExecuted(uint256 proposalId);
    event TaskContributionRegistered(uint256 proposalId, address contributor);
    event TaskCompleted(uint256 proposalId);
    event ContractPaused();
    event ContractUnpaused();

    // --- Modifiers ---
    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can call this function.");
        _;
    }

    modifier onlyMember() {
        require(members[msg.sender], "Only members can call this function.");
        _;
    }

    modifier notPaused() {
        require(!paused, "Contract is paused.");
        _;
    }

    modifier proposalExists(uint256 _proposalId) {
        require(_proposalId < proposalCount && proposals[_proposalId].id == _proposalId, "Proposal does not exist.");
        _;
    }

    modifier proposalActive(uint256 _proposalId) {
        require(proposals[_proposalId].status == ProposalStatus.ACTIVE, "Proposal is not active.");
        _;
    }

    modifier proposalPending(uint256 _proposalId) {
        require(proposals[_proposalId].status == ProposalStatus.PENDING, "Proposal is not pending.");
        _;
    }

    modifier proposalExecutable(uint256 _proposalId) {
        require(proposals[_proposalId].status == ProposalStatus.PASSED && proposals[_proposalId].endTime < block.timestamp, "Proposal is not executable.");
        _;
    }

    modifier notVoted(uint256 _proposalId) {
        require(!proposals[_proposalId].votes[msg.sender], "Member has already voted on this proposal.");
        _;
    }

    // --- Constructor ---
    constructor() {
        admin = msg.sender;
    }

    // --- Membership & Roles Functions ---
    function joinDAO() external notPaused {
        require(!members[msg.sender], "Already a member or membership requested.");
        members[msg.sender] = false; // Mark as requested, will be approved by admin
        emit MembershipRequested(msg.sender);
    }

    function approveMembership(address _member) external onlyAdmin notPaused {
        require(!members[_member], "Address is not a pending member.");
        members[_member] = true;
        memberList.push(_member);
        memberCount++;
        emit MembershipApproved(_member);
    }

    function revokeMembership(address _member) external onlyAdmin notPaused {
        require(members[_member], "Address is not a member.");
        delete members[_member];
        // Remove from memberList (inefficient for large lists, consider alternatives for production)
        for (uint256 i = 0; i < memberList.length; i++) {
            if (memberList[i] == _member) {
                memberList[i] = memberList[memberList.length - 1];
                memberList.pop();
                break;
            }
        }
        memberCount--;
        emit MembershipRevoked(_member);
    }

    function listMembers() external view returns (address[] memory) {
        return memberList;
    }

    function isAdmin(address _account) external view returns (bool) {
        return _account == admin;
    }

    // --- Skill Management & Verification Functions ---
    function registerSkill(string memory _skillName) external onlyMember notPaused {
        memberSkills[msg.sender].push(_skillName);
        emit SkillRegistered(msg.sender, _skillName);
    }

    function requestSkillVerification(address _member, string memory _skillName) external onlyMember notPaused {
        require(members[_member], "Target address is not a member.");
        require(msg.sender != _member, "Cannot request verification for yourself.");
        emit SkillVerificationRequested(_member, _skillName, msg.sender);
        // In a more complex system, this could trigger notifications, reputation adjustments etc.
    }

    function verifySkill(address _member, string memory _skillName) external onlyMember notPaused {
        require(members[_member], "Target address is not a member.");
        require(msg.sender != _member, "Cannot verify your own skill.");
        bool skillRegistered = false;
        for (uint256 i = 0; i < memberSkills[_member].length; i++) {
            if (keccak256(bytes(memberSkills[_member][i])) == keccak256(bytes(_skillName))) {
                skillRegistered = true;
                break;
            }
        }
        require(skillRegistered, "Skill not registered by the member.");
        verifiedSkills[_member][_skillName] = true;
        emit SkillVerified(_member, _skillName, msg.sender);
        // Potentially increase reputation of both verifier and verified member
        memberReputation[_member]++;
        memberReputation[msg.sender]++;
    }

    function getMemberSkills(address _member) external view returns (string[] memory, bool[] memory) {
        string[] memory skills = memberSkills[_member];
        bool[] memory verificationStatuses = new bool[](skills.length);
        for (uint256 i = 0; i < skills.length; i++) {
            verificationStatuses[i] = verifiedSkills[_member][skills[i]];
        }
        return (skills, verificationStatuses);
    }

    // --- Proposal System Functions ---
    function createResourceProposal(
        string memory _title,
        string memory _description,
        uint256 _amount,
        address _recipient
    ) external onlyMember notPaused {
        require(_amount > 0, "Resource amount must be greater than zero.");
        require(_recipient != address(0), "Invalid recipient address.");

        Proposal storage newProposal = proposals[proposalCount];
        newProposal.id = proposalCount;
        newProposal.title = _title;
        newProposal.description = _description;
        newProposal.proposalType = ProposalType.RESOURCE_ALLOCATION;
        newProposal.status = ProposalStatus.ACTIVE;
        newProposal.startTime = block.timestamp;
        newProposal.endTime = block.timestamp + votingDuration;
        newProposal.proposer = msg.sender;
        newProposal.resourceAmount = _amount;
        newProposal.resourceRecipient = _recipient;

        proposalCount++;
        emit ResourceProposalCreated(newProposal.id, _title, _amount, _recipient, msg.sender);
    }

    function createSkillTaskProposal(
        string memory _title,
        string memory _description,
        string[] memory _requiredSkills,
        uint256 _reward
    ) external onlyMember notPaused {
        require(_requiredSkills.length > 0, "At least one skill is required for the task.");
        require(_reward > 0, "Task reward must be greater than zero.");

        Proposal storage newProposal = proposals[proposalCount];
        newProposal.id = proposalCount;
        newProposal.title = _title;
        newProposal.description = _description;
        newProposal.proposalType = ProposalType.SKILL_TASK;
        newProposal.status = ProposalStatus.ACTIVE;
        newProposal.startTime = block.timestamp;
        newProposal.endTime = block.timestamp + votingDuration;
        newProposal.proposer = msg.sender;
        newProposal.requiredSkills = _requiredSkills;
        newProposal.taskReward = _reward;

        proposalCount++;
        emit SkillTaskProposalCreated(newProposal.id, _title, _requiredSkills, _reward, msg.sender);
    }

    function voteOnProposal(uint256 _proposalId, bool _vote)
        external
        onlyMember
        notPaused
        proposalExists(_proposalId)
        proposalActive(_proposalId)
        notVoted(_proposalId)
    {
        Proposal storage proposal = proposals[_proposalId];
        proposal.votes[msg.sender] = _vote;
        if (_vote) {
            proposal.yesVotes++;
        } else {
            proposal.noVotes++;
        }
        emit ProposalVoted(_proposalId, msg.sender, _vote);

        // Check if voting period is over and update proposal status
        if (block.timestamp > proposal.endTime) {
            if ((proposal.yesVotes * 100) / memberCount >= quorumPercentage) {
                proposal.status = ProposalStatus.PASSED;
            } else {
                proposal.status = ProposalStatus.REJECTED;
            }
        }
    }

    function executeProposal(uint256 _proposalId)
        external
        onlyMember
        notPaused
        proposalExists(_proposalId)
        proposalExecutable(_proposalId)
    {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.status == ProposalStatus.PASSED, "Proposal did not pass voting.");

        proposal.status = ProposalStatus.EXECUTED;
        emit ProposalExecuted(_proposalId);

        if (proposal.proposalType == ProposalType.RESOURCE_ALLOCATION) {
            payable(proposal.resourceRecipient).transfer(proposal.resourceAmount);
        } else if (proposal.proposalType == ProposalType.SKILL_TASK && proposal.taskCompleted) {
            // Distribute rewards to task contributors (simplified - could be more granular in a real system)
            uint256 rewardPerContributor = proposal.taskReward / getContributorCount(_proposalId);
            for (uint256 i = 0; i < memberList.length; i++) {
                if (proposal.taskContributors[memberList[i]]) {
                    payable(memberList[i]).transfer(rewardPerContributor);
                }
            }
        }
    }

    function getProposalDetails(uint256 _proposalId)
        external
        view
        proposalExists(_proposalId)
        returns (Proposal memory)
    {
        return proposals[_proposalId];
    }

    function listProposals() external view returns (uint256[] memory) {
        uint256[] memory proposalIds = new uint256[](proposalCount);
        for (uint256 i = 0; i < proposalCount; i++) {
            proposalIds[i] = i;
        }
        return proposalIds;
    }

    function getPendingProposals() external view returns (uint256[] memory) {
        uint256 pendingCount = 0;
        for (uint256 i = 0; i < proposalCount; i++) {
            if (proposals[i].status == ProposalStatus.ACTIVE) {
                pendingCount++;
            }
        }
        uint256[] memory pendingProposals = new uint256[](pendingCount);
        uint256 index = 0;
        for (uint256 i = 0; i < proposalCount; i++) {
            if (proposals[i].status == ProposalStatus.ACTIVE) {
                pendingProposals[index++] = i;
            }
        }
        return pendingProposals;
    }

    function getExecutedProposals() external view returns (uint256[] memory) {
        uint256 executedCount = 0;
        for (uint256 i = 0; i < proposalCount; i++) {
            if (proposals[i].status == ProposalStatus.EXECUTED) {
                executedCount++;
            }
        }
        uint256[] memory executedProposals = new uint256[](executedCount);
        uint256 index = 0;
        for (uint256 i = 0; i < proposalCount; i++) {
            if (proposals[i].status == ProposalStatus.EXECUTED) {
                executedProposals[index++] = i;
            }
        }
        return executedProposals;
    }


    // --- Reputation & Contribution Tracking Functions ---
    function contributeToTask(uint256 _proposalId)
        external
        onlyMember
        notPaused
        proposalExists(_proposalId)
        proposalActive(_proposalId) // Or maybe proposal passed and waiting for contribution? Design choice.
    {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.proposalType == ProposalType.SKILL_TASK, "Proposal is not a skill task.");
        bool hasRequiredSkill = false;
        for (uint256 i = 0; i < proposal.requiredSkills.length; i++) {
            if (verifiedSkills[msg.sender][proposal.requiredSkills[i]]) {
                hasRequiredSkill = true;
                break;
            }
        }
        require(hasRequiredSkill, "Member does not have the required skills for this task.");
        require(!proposal.taskContributors[msg.sender], "Member already contributed to this task.");

        proposal.taskContributors[msg.sender] = true;
        emit TaskContributionRegistered(_proposalId, msg.sender);
        memberReputation[msg.sender] += 5; // Increase reputation for contribution (adjust value as needed)
    }

    function markTaskCompletion(uint256 _proposalId) external onlyMember notPaused proposalExists(_proposalId) {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.proposalType == ProposalType.SKILL_TASK, "Proposal is not a skill task.");
        require(proposal.status == ProposalStatus.PASSED, "Task can only be marked complete after proposal has passed.");
        require(!proposal.taskCompleted, "Task already marked as completed.");

        proposal.taskCompleted = true;
        emit TaskCompleted(_proposalId);

        // Reward distribution is handled in executeProposal function when proposal is executed.
    }

    function getMemberReputation(address _member) external view returns (uint256) {
        return memberReputation[_member];
    }

    function getContributorCount(uint256 _proposalId) private view returns (uint256) {
        uint256 count = 0;
        for (uint256 i = 0; i < memberList.length; i++) {
            if (proposals[_proposalId].taskContributors[memberList[i]]) {
                count++;
            }
        }
        return count;
    }

    // --- Emergency & Admin Functions ---
    function pauseContract() external onlyAdmin {
        paused = true;
        emit ContractPaused();
    }

    function unpauseContract() external onlyAdmin {
        paused = false;
        emit ContractUnpaused();
    }

    // Fallback function to receive ETH for resource proposals
    receive() external payable {}
}
```