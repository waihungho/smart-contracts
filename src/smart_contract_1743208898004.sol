```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Decentralized Autonomous Research Organization (DARO) Smart Contract
 * @author Gemini (AI Assistant)
 * @dev A smart contract implementing a Decentralized Autonomous Research Organization (DARO).
 * This contract facilitates decentralized research funding, proposal submission, voting, task management,
 * intellectual property (IP) NFT generation, and researcher reputation tracking.
 *
 * **Outline and Function Summary:**
 *
 * **Membership & Governance:**
 * 1. `joinDARO(string _researchArea)`: Allows users to join the DARO, specifying their research area.
 * 2. `leaveDARO()`: Allows members to leave the DARO.
 * 3. `getMemberInfo(address _member)`: Retrieves information about a DARO member.
 * 4. `updateMemberResearchArea(string _newResearchArea)`: Allows members to update their research area.
 * 5. `setGovernanceParameter(string _parameterName, uint256 _value)`: Allows the contract owner to set governance parameters like voting periods and quorum.
 * 6. `getGovernanceParameter(string _parameterName)`: Retrieves the value of a governance parameter.
 *
 * **Research Proposals:**
 * 7. `submitResearchProposal(string _title, string _description, uint256 _fundingGoal, string _researchArea)`: Allows members to submit research proposals.
 * 8. `voteOnProposal(uint256 _proposalId, bool _support)`: Allows members to vote on research proposals.
 * 9. `getProposalInfo(uint256 _proposalId)`: Retrieves detailed information about a specific research proposal.
 * 10. `fundProposal(uint256 _proposalId)`: Allows anyone to contribute funds to a research proposal that has passed voting.
 * 11. `startProposalExecution(uint256 _proposalId)`: Allows the proposal initiator to start execution after funding is reached.
 * 12. `completeProposal(uint256 _proposalId, string _reportCID)`: Allows the proposal initiator to mark a proposal as completed and submit a report CID.
 * 13. `markProposalFailed(uint256 _proposalId)`: Allows the contract owner to mark a proposal as failed if execution is not satisfactory.
 * 14. `withdrawProposalFunds(uint256 _proposalId)`: Allows the proposal initiator to withdraw funds after successful completion and approval.
 *
 * **Task Management:**
 * 15. `createResearchTask(uint256 _proposalId, string _taskDescription, uint256 _reward)`: Allows proposal initiators to create research tasks under their proposals.
 * 16. `assignTask(uint256 _taskId, address _researcher)`: Allows proposal initiators to assign tasks to DARO members.
 * 17. `submitTaskCompletion(uint256 _taskId, string _completionCID)`: Allows researchers to submit task completion with a content CID.
 * 18. `approveTaskCompletion(uint256 _taskId)`: Allows proposal initiators to approve task completion and reward the researcher.
 * 19. `rejectTaskCompletion(uint256 _taskId)`: Allows proposal initiators to reject task completion if it's not satisfactory.
 *
 * **Intellectual Property & Reputation:**
 * 20. `mintIPNFT(uint256 _proposalId, string _metadataCID)`: Mints an Intellectual Property NFT upon successful completion of a research proposal, linking to metadata.
 * 21. `getIPNFTOfProposal(uint256 _proposalId)`: Retrieves the IP NFT ID associated with a research proposal.
 * 22. `getResearcherReputation(address _researcher)`: Retrieves the reputation score of a researcher based on task completion and proposal success.
 * 23. `adjustResearcherReputation(address _researcher, int256 _reputationChange)`: Allows the contract owner to manually adjust researcher reputation (for dispute resolution or initial setup).
 *
 * **Utility & View:**
 * 24. `getDAROBalance()`: Retrieves the current balance of the DARO contract.
 * 25. `withdrawAdminFunds(uint256 _amount)`: Allows the contract owner to withdraw funds from the DARO contract for operational expenses.
 * 26. `isMember(address _account)`: Checks if an address is a member of the DARO.
 * 27. `getProposalStatus(uint256 _proposalId)`: Returns the current status of a research proposal.
 * 28. `getTaskStatus(uint256 _taskId)`: Returns the current status of a research task.
 */
contract DecentralizedAutonomousResearchOrganization {

    // --- Structs ---
    struct Member {
        address account;
        string researchArea;
        uint256 reputationScore;
        bool isActive;
        uint256 joinTimestamp;
    }

    struct Proposal {
        uint256 id;
        address proposer;
        string title;
        string description;
        uint256 fundingGoal;
        uint256 currentFunding;
        string researchArea;
        uint256 startTime;
        uint256 votingEndTime;
        uint256 executionStartTime;
        uint256 completionTime;
        string reportCID;
        ProposalStatus status;
        uint256 yesVotes;
        uint256 noVotes;
        mapping(address => bool) votes; // Track who voted and their vote
    }

    struct ResearchTask {
        uint256 id;
        uint256 proposalId;
        string description;
        address assignee;
        uint256 reward;
        string completionCID;
        TaskStatus status;
        uint256 submissionTime;
        uint256 approvalTime;
    }

    enum ProposalStatus {
        PENDING_VOTE,
        FUNDING,
        EXECUTION,
        COMPLETED,
        FAILED,
        CANCELLED
    }

    enum TaskStatus {
        CREATED,
        ASSIGNED,
        SUBMITTED,
        APPROVED,
        REJECTED
    }

    // --- State Variables ---
    address public owner;
    uint256 public membershipFee; // Fee to join DARO
    uint256 public proposalVotingPeriod; // Duration of proposal voting in seconds
    uint256 public quorumPercentage; // Percentage of members needed to vote for quorum
    uint256 public taskCompletionReviewPeriod; // Duration for proposal initiator to review task completion

    mapping(address => Member) public members;
    mapping(uint256 => Proposal) public proposals;
    mapping(uint256 => ResearchTask) public researchTasks;
    mapping(uint256 => uint256) public proposalToIPNFT; // Mapping proposal ID to IP NFT ID

    uint256 public memberCount;
    uint256 public proposalCount;
    uint256 public taskCount;
    uint256 public ipNFTCounter; // Simple counter for IP NFT IDs

    // --- Events ---
    event MemberJoined(address indexed member, string researchArea);
    event MemberLeft(address indexed member);
    event MemberResearchAreaUpdated(address indexed member, string newResearchArea);
    event GovernanceParameterSet(string parameterName, uint256 value);
    event ResearchProposalSubmitted(uint256 indexed proposalId, address proposer, string title);
    event ProposalVoted(uint256 indexed proposalId, address voter, bool support);
    event ProposalFunded(uint256 indexed proposalId, uint256 amount);
    event ProposalExecutionStarted(uint256 indexed proposalId);
    event ProposalCompleted(uint256 indexed proposalId);
    event ProposalFailed(uint256 indexed proposalId);
    event ProposalFundsWithdrawn(uint256 indexed proposalId, address withdrawer, uint256 amount);
    event ResearchTaskCreated(uint256 indexed taskId, uint256 proposalId, string description);
    event TaskAssigned(uint256 indexed taskId, address researcher);
    event TaskCompletionSubmitted(uint256 indexed taskId, address researcher, string completionCID);
    event TaskCompletionApproved(uint256 indexed taskId, address researcher);
    event TaskCompletionRejected(uint256 indexed taskId, address researcher);
    event IPNFTMinted(uint256 indexed ipNFTId, uint256 proposalId, string metadataCID);
    event ResearcherReputationAdjusted(address indexed researcher, int256 reputationChange, string reason);
    event AdminFundsWithdrawn(address indexed admin, uint256 amount);

    // --- Modifiers ---
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function.");
        _;
    }

    modifier onlyMember() {
        require(isMember(msg.sender), "Only DARO members can call this function.");
        _;
    }

    modifier validProposal(uint256 _proposalId) {
        require(proposals[_proposalId].id == _proposalId, "Invalid proposal ID.");
        _;
    }

    modifier validTask(uint256 _taskId) {
        require(researchTasks[_taskId].id == _taskId, "Invalid task ID.");
        _;
    }

    modifier proposalInStatus(uint256 _proposalId, ProposalStatus _status) {
        require(proposals[_proposalId].status == _status, "Proposal status is not correct.");
        _;
    }

    modifier taskInStatus(uint256 _taskId, TaskStatus _status) {
        require(researchTasks[_taskId].status == _status, "Task status is not correct.");
        _;
    }

    // --- Constructor ---
    constructor(uint256 _membershipFee, uint256 _proposalVotingPeriod, uint256 _quorumPercentage, uint256 _taskReviewPeriod) {
        owner = msg.sender;
        membershipFee = _membershipFee;
        proposalVotingPeriod = _proposalVotingPeriod;
        quorumPercentage = _quorumPercentage;
        taskCompletionReviewPeriod = _taskReviewPeriod;
        memberCount = 0;
        proposalCount = 0;
        taskCount = 0;
        ipNFTCounter = 0;
    }

    // --- Membership & Governance Functions ---
    function joinDARO(string memory _researchArea) external payable {
        require(msg.value >= membershipFee, "Membership fee is required to join.");
        require(!isMember(msg.sender), "Already a member.");
        members[msg.sender] = Member({
            account: msg.sender,
            researchArea: _researchArea,
            reputationScore: 0,
            isActive: true,
            joinTimestamp: block.timestamp
        });
        memberCount++;
        emit MemberJoined(msg.sender, _researchArea);
    }

    function leaveDARO() external onlyMember {
        require(members[msg.sender].isActive, "Not an active member.");
        members[msg.sender].isActive = false;
        memberCount--;
        emit MemberLeft(msg.sender);
    }

    function getMemberInfo(address _member) external view returns (Member memory) {
        require(isMember(_member), "Not a DARO member.");
        return members[_member];
    }

    function updateMemberResearchArea(string memory _newResearchArea) external onlyMember {
        require(members[msg.sender].isActive, "Not an active member.");
        members[msg.sender].researchArea = _newResearchArea;
        emit MemberResearchAreaUpdated(msg.sender, _newResearchArea);
    }

    function setGovernanceParameter(string memory _parameterName, uint256 _value) external onlyOwner {
        if (keccak256(bytes(_parameterName)) == keccak256(bytes("membershipFee"))) {
            membershipFee = _value;
        } else if (keccak256(bytes(_parameterName)) == keccak256(bytes("proposalVotingPeriod"))) {
            proposalVotingPeriod = _value;
        } else if (keccak256(bytes(_parameterName)) == keccak256(bytes("quorumPercentage"))) {
            quorumPercentage = _value;
        } else if (keccak256(bytes(_parameterName)) == keccak256(bytes("taskCompletionReviewPeriod"))) {
            taskCompletionReviewPeriod = _value;
        } else {
            revert("Invalid governance parameter name.");
        }
        emit GovernanceParameterSet(_parameterName, _value);
    }

    function getGovernanceParameter(string memory _parameterName) external view onlyOwner returns (uint256) {
        if (keccak256(bytes(_parameterName)) == keccak256(bytes("membershipFee"))) {
            return membershipFee;
        } else if (keccak256(bytes(_parameterName)) == keccak256(bytes("proposalVotingPeriod"))) {
            return proposalVotingPeriod;
        } else if (keccak256(bytes(_parameterName)) == keccak256(bytes("quorumPercentage"))) {
            return quorumPercentage;
        } else if (keccak256(bytes(_parameterName)) == keccak256(bytes("taskCompletionReviewPeriod"))) {
            return taskCompletionReviewPeriod;
        } else {
            revert("Invalid governance parameter name.");
        }
    }

    // --- Research Proposal Functions ---
    function submitResearchProposal(string memory _title, string memory _description, uint256 _fundingGoal, string memory _researchArea) external onlyMember {
        proposalCount++;
        proposals[proposalCount] = Proposal({
            id: proposalCount,
            proposer: msg.sender,
            title: _title,
            description: _description,
            fundingGoal: _fundingGoal,
            currentFunding: 0,
            researchArea: _researchArea,
            startTime: block.timestamp,
            votingEndTime: block.timestamp + proposalVotingPeriod,
            executionStartTime: 0,
            completionTime: 0,
            reportCID: "",
            status: ProposalStatus.PENDING_VOTE,
            yesVotes: 0,
            noVotes: 0,
            votes: mapping(address => bool)()
        });
        emit ResearchProposalSubmitted(proposalCount, msg.sender, _title);
    }

    function voteOnProposal(uint256 _proposalId, bool _support) external onlyMember validProposal(_proposalId) proposalInStatus(_proposalId, ProposalStatus.PENDING_VOTE) {
        require(!proposals[_proposalId].votes[msg.sender], "Already voted on this proposal.");
        proposals[_proposalId].votes[msg.sender] = true;
        if (_support) {
            proposals[_proposalId].yesVotes++;
        } else {
            proposals[_proposalId].noVotes++;
        }
        emit ProposalVoted(_proposalId, msg.sender, _support);

        // Check if voting period is over or quorum is reached to update proposal status
        if (block.timestamp >= proposals[_proposalId].votingEndTime || isQuorumReached(_proposalId)) {
            _finalizeProposalVoting(_proposalId);
        }
    }

    function getProposalInfo(uint256 _proposalId) external view validProposal(_proposalId) returns (Proposal memory) {
        return proposals[_proposalId];
    }

    function fundProposal(uint256 _proposalId) external payable validProposal(_proposalId) proposalInStatus(_proposalId, ProposalStatus.FUNDING) {
        require(proposals[_proposalId].currentFunding < proposals[_proposalId].fundingGoal, "Proposal funding goal already reached.");
        uint256 amountToSend = msg.value;
        if (proposals[_proposalId].currentFunding + msg.value > proposals[_proposalId].fundingGoal) {
            amountToSend = proposals[_proposalId].fundingGoal - proposals[_proposalId].currentFunding;
            payable(msg.sender).transfer(msg.value - amountToSend); // Refund excess funds
        }
        proposals[_proposalId].currentFunding += amountToSend;
        emit ProposalFunded(_proposalId, amountToSend);

        if (proposals[_proposalId].currentFunding >= proposals[_proposalId].fundingGoal) {
            proposals[_proposalId].status = ProposalStatus.EXECUTION;
            proposals[_proposalId].executionStartTime = block.timestamp;
            emit ProposalExecutionStarted(_proposalId);
        }
    }

    function startProposalExecution(uint256 _proposalId) external onlyMember validProposal(_proposalId) proposalInStatus(_proposalId, ProposalStatus.FUNDING) {
         require(msg.sender == proposals[_proposalId].proposer, "Only proposer can start execution.");
         require(proposals[_proposalId].currentFunding >= proposals[_proposalId].fundingGoal, "Funding goal not yet reached.");
         proposals[_proposalId].status = ProposalStatus.EXECUTION;
         proposals[_proposalId].executionStartTime = block.timestamp;
         emit ProposalExecutionStarted(_proposalId);
    }


    function completeProposal(uint256 _proposalId, string memory _reportCID) external onlyMember validProposal(_proposalId) proposalInStatus(_proposalId, ProposalStatus.EXECUTION) {
        require(msg.sender == proposals[_proposalId].proposer, "Only proposer can complete proposal.");
        proposals[_proposalId].status = ProposalStatus.COMPLETED;
        proposals[_proposalId].completionTime = block.timestamp;
        proposals[_proposalId].reportCID = _reportCID;
        emit ProposalCompleted(_proposalId);
    }

    function markProposalFailed(uint256 _proposalId) external onlyOwner validProposal(_proposalId) proposalInStatus(_proposalId, ProposalStatus.EXECUTION) {
        proposals[_proposalId].status = ProposalStatus.FAILED;
        emit ProposalFailed(_proposalId);
    }

    function withdrawProposalFunds(uint256 _proposalId) external onlyMember validProposal(_proposalId) proposalInStatus(_proposalId, ProposalStatus.COMPLETED) {
        require(msg.sender == proposals[_proposalId].proposer, "Only proposer can withdraw funds.");
        uint256 amountToWithdraw = proposals[_proposalId].currentFunding;
        proposals[_proposalId].currentFunding = 0; // Reset funding after withdrawal
        payable(msg.sender).transfer(amountToWithdraw);
        emit ProposalFundsWithdrawn(_proposalId, msg.sender, amountToWithdraw);
    }


    // --- Research Task Functions ---
    function createResearchTask(uint256 _proposalId, string memory _taskDescription, uint256 _reward) external onlyMember validProposal(_proposalId) proposalInStatus(_proposalId, ProposalStatus.EXECUTION) {
        require(msg.sender == proposals[_proposalId].proposer, "Only proposer can create tasks.");
        taskCount++;
        researchTasks[taskCount] = ResearchTask({
            id: taskCount,
            proposalId: _proposalId,
            description: _taskDescription,
            assignee: address(0),
            reward: _reward,
            completionCID: "",
            status: TaskStatus.CREATED,
            submissionTime: 0,
            approvalTime: 0
        });
        emit ResearchTaskCreated(taskCount, _proposalId, _taskDescription);
    }

    function assignTask(uint256 _taskId, address _researcher) external onlyMember validTask(_taskId) taskInStatus(_taskId, TaskStatus.CREATED) {
        require(msg.sender == proposals[researchTasks[_taskId].proposalId].proposer, "Only proposer can assign tasks.");
        require(isMember(_researcher), "Researcher must be a DARO member.");
        researchTasks[_taskId].assignee = _researcher;
        researchTasks[_taskId].status = TaskStatus.ASSIGNED;
        emit TaskAssigned(_taskId, _researcher);
    }

    function submitTaskCompletion(uint256 _taskId, string memory _completionCID) external onlyMember validTask(_taskId) taskInStatus(_taskId, TaskStatus.ASSIGNED) {
        require(msg.sender == researchTasks[_taskId].assignee, "Only assigned researcher can submit completion.");
        researchTasks[_taskId].completionCID = _completionCID;
        researchTasks[_taskId].status = TaskStatus.SUBMITTED;
        researchTasks[_taskId].submissionTime = block.timestamp;
        emit TaskCompletionSubmitted(_taskId, msg.sender, _completionCID);
        // Consider adding automatic approval after a review period if proposer doesn't act.
    }

    function approveTaskCompletion(uint256 _taskId) external onlyMember validTask(_taskId) taskInStatus(_taskId, TaskStatus.SUBMITTED) {
        require(msg.sender == proposals[researchTasks[_taskId].proposalId].proposer, "Only proposer can approve task completion.");
        researchTasks[_taskId].status = TaskStatus.APPROVED;
        researchTasks[_taskId].approvalTime = block.timestamp;
        // Transfer reward to researcher
        payable(researchTasks[_taskId].assignee).transfer(researchTasks[_taskId].reward);
        _adjustResearcherReputation(researchTasks[_taskId].assignee, 10); // Increase reputation for successful task
        emit TaskCompletionApproved(_taskId, researchTasks[_taskId].assignee);
    }

    function rejectTaskCompletion(uint256 _taskId) external onlyMember validTask(_taskId) taskInStatus(_taskId, TaskStatus.SUBMITTED) {
        require(msg.sender == proposals[researchTasks[_taskId].proposalId].proposer, "Only proposer can reject task completion.");
        researchTasks[_taskId].status = TaskStatus.REJECTED;
        _adjustResearcherReputation(researchTasks[_taskId].assignee, -5); // Decrease reputation for rejected task
        emit TaskCompletionRejected(_taskId, researchTasks[_taskId].assignee);
    }

    // --- Intellectual Property & Reputation Functions ---
    function mintIPNFT(uint256 _proposalId, string memory _metadataCID) external onlyMember validProposal(_proposalId) proposalInStatus(_proposalId, ProposalStatus.COMPLETED) {
        require(msg.sender == proposals[_proposalId].proposer, "Only proposer can mint IP NFT.");
        ipNFTCounter++;
        proposalToIPNFT[_proposalId] = ipNFTCounter;
        // In a real application, integrate with an actual NFT contract (e.g., ERC721) to mint a proper NFT.
        // For simplicity, we are just tracking an internal ID.
        emit IPNFTMinted(ipNFTCounter, _proposalId, _metadataCID);
    }

    function getIPNFTOfProposal(uint256 _proposalId) external view validProposal(_proposalId) returns (uint256) {
        return proposalToIPNFT[_proposalId];
    }

    function getResearcherReputation(address _researcher) external view returns (uint256) {
        if (!isMember(_researcher)) {
            return 0; // Non-members have 0 reputation
        }
        return members[_researcher].reputationScore;
    }

    function adjustResearcherReputation(address _researcher, int256 _reputationChange, string memory _reason) external onlyOwner {
        _adjustResearcherReputation(_researcher, _reputationChange);
        emit ResearcherReputationAdjusted(_researcher, _reputationChange, _reason);
    }

    // --- Utility & View Functions ---
    function getDAROBalance() external view returns (uint256) {
        return address(this).balance;
    }

    function withdrawAdminFunds(uint256 _amount) external onlyOwner {
        require(address(this).balance >= _amount, "Insufficient contract balance.");
        payable(owner).transfer(_amount);
        emit AdminFundsWithdrawn(owner, _amount);
    }

    function isMember(address _account) public view returns (bool) {
        return members[_account].isActive;
    }

    function getProposalStatus(uint256 _proposalId) external view validProposal(_proposalId) returns (ProposalStatus) {
        return proposals[_proposalId].status;
    }

    function getTaskStatus(uint256 _taskId) external view validTask(_taskId) returns (TaskStatus) {
        return researchTasks[_taskId].status;
    }

    // --- Internal Functions ---
    function _finalizeProposalVoting(uint256 _proposalId) internal validProposal(_proposalId) proposalInStatus(_proposalId, ProposalStatus.PENDING_VOTE) {
        if (proposals[_proposalId].yesVotes > proposals[_proposalId].noVotes && isQuorumReached(_proposalId)) {
            proposals[_proposalId].status = ProposalStatus.FUNDING;
        } else {
            proposals[_proposalId].status = ProposalStatus.FAILED; // Or CANCELLED depending on requirements
        }
    }

    function isQuorumReached(uint256 _proposalId) internal view returns (bool) {
        uint256 totalVotes = proposals[_proposalId].yesVotes + proposals[_proposalId].noVotes;
        uint256 requiredVotes = (memberCount * quorumPercentage) / 100;
        return totalVotes >= requiredVotes;
    }

    function _adjustResearcherReputation(address _researcher, int256 _reputationChange) internal {
        if (isMember(_researcher)) {
            // Prevent reputation from going below zero, maybe set a minimum floor if needed.
            members[_researcher].reputationScore = members[_researcher].reputationScore + uint256(int256(members[_researcher].reputationScore) + _reputationChange >= 0 ? _reputationChange : -int256(members[_researcher].reputationScore));
        }
    }

    receive() external payable {} // Allow contract to receive Ether for proposal funding
}
```