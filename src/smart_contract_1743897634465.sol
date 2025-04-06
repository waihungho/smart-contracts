```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Dynamic Reputation & Governance DAO Contract
 * @author Bard (Example - Not for Production)
 * @dev A smart contract implementing a Dynamic Reputation and Governance DAO with advanced and creative features.
 *
 * Outline:
 *
 * 1. Membership Management:
 *    - joinDAO(): Allows users to become members.
 *    - leaveDAO(): Allows members to exit the DAO.
 *    - isMember(): Checks if an address is a member.
 *    - getMemberCount(): Returns the total number of members.
 *
 * 2. Dynamic Reputation System:
 *    - increaseReputation(): Increases member's reputation (admin/role-based).
 *    - decreaseReputation(): Decreases member's reputation (admin/role-based).
 *    - getReputation(): Retrieves a member's reputation score.
 *    - getMemberRank(): Determines member rank based on reputation.
 *    - transferReputation(): Allows members to transfer reputation points to others.
 *    - decayReputation(): Periodically reduces reputation for inactivity.
 *
 * 3. Advanced Governance & Voting:
 *    - proposeNewRule(): Allows members to propose new DAO rules.
 *    - voteOnRuleProposal(): Allows members to vote on rule proposals (weighted by reputation).
 *    - executeRuleProposal(): Executes a rule proposal if it passes.
 *    - delegateVote(): Allows members to delegate their voting power to another member.
 *    - createTaskProposal(): Allows members to propose tasks for the DAO to undertake.
 *    - applyForTask(): Members can apply to execute proposed tasks.
 *    - approveTaskCompletion(): Admin/Council can approve task completion and reward reputation.
 *    - voteForCouncilMember(): Members vote to elect council members (representative governance).
 *
 * 4. Dynamic NFT Reputation Badges:
 *    - mintReputationBadge(): Mints an NFT badge that represents member's reputation level.
 *    - getReputationBadgeURI(): Retrieves the URI for a member's reputation badge NFT.
 *
 * Function Summary:
 *
 * - joinDAO(): Allows an address to become a member of the DAO.
 * - leaveDAO(): Allows a member to resign from the DAO.
 * - isMember(address _member): Checks if the given address is a member.
 * - getMemberCount(): Returns the total number of members in the DAO.
 * - increaseReputation(address _member, uint256 _amount): Increases the reputation of a member (admin-only).
 * - decreaseReputation(address _member, uint256 _amount): Decreases the reputation of a member (admin-only).
 * - getReputation(address _member): Returns the reputation score of a member.
 * - getMemberRank(address _member): Returns the rank of a member based on their reputation.
 * - transferReputation(address _recipient, uint256 _amount): Allows a member to transfer reputation to another member.
 * - decayReputation(): Periodically reduces reputation for inactive members.
 * - proposeNewRule(string memory _ruleDescription, bytes memory _ruleData): Allows members to propose a new DAO rule.
 * - voteOnRuleProposal(uint256 _proposalId, bool _support): Allows members to vote on a rule proposal.
 * - executeRuleProposal(uint256 _proposalId): Executes a rule proposal if it has passed the voting.
 * - delegateVote(address _delegateTo): Allows a member to delegate their voting power to another member.
 * - createTaskProposal(string memory _taskDescription, uint256 _reputationReward): Allows members to propose tasks for the DAO.
 * - applyForTask(uint256 _taskId): Allows members to apply to execute a proposed task.
 * - approveTaskCompletion(uint256 _taskId, address _executor): Allows admin/council to approve task completion and reward reputation.
 * - voteForCouncilMember(address _candidate): Allows members to vote for a candidate to become a council member.
 * - mintReputationBadge(address _member): Mints an NFT reputation badge for a member based on their reputation level.
 * - getReputationBadgeURI(address _member): Returns the URI for a member's reputation badge NFT metadata.
 */
contract DynamicReputationDAO {

    // --- State Variables ---

    address public owner; // Contract owner, can be DAO initial creator or multi-sig
    string public daoName;

    mapping(address => bool) public members;
    address[] public memberList;
    mapping(address => uint256) public reputation;
    mapping(address => address) public voteDelegation; // Member -> Delegated Address

    uint256 public reputationDecayRate = 1; // Percentage decay per decay period
    uint256 public reputationDecayPeriod = 30 days; // Decay period

    uint256 public nextProposalId = 1;
    struct RuleProposal {
        uint256 proposalId;
        string description;
        bytes ruleData;
        uint256 votingStartTime;
        uint256 votingEndTime;
        mapping(address => bool) votes; // Members who voted
        uint256 yesVotes;
        uint256 noVotes;
        bool executed;
    }
    mapping(uint256 => RuleProposal) public ruleProposals;

    uint256 public nextTaskId = 1;
    struct TaskProposal {
        uint256 taskId;
        string description;
        uint256 reputationReward;
        address assignedExecutor;
        bool taskCompleted;
        address taskProposer;
        address[] applicants;
    }
    mapping(uint256 => TaskProposal) public taskProposals;

    address[] public councilMembers; // Representative council members
    uint256 public councilElectionDuration = 7 days;
    uint256 public lastCouncilElectionTime;
    mapping(address => uint256) public councilVotes; // Candidates and their votes
    uint256 public councilThreshold = 3; // Minimum reputation to be council member candidate

    // --- Events ---

    event MemberJoined(address member);
    event MemberLeft(address member);
    event ReputationIncreased(address member, uint256 amount, address admin);
    event ReputationDecreased(address member, uint256 amount, address admin);
    event ReputationTransferred(address from, address to, uint256 amount);
    event ReputationDecayed(address member, uint256 decayedAmount);
    event RuleProposalCreated(uint256 proposalId, string description, address proposer);
    event VoteCast(uint256 proposalId, address voter, bool support);
    event RuleProposalExecuted(uint256 proposalId);
    event VoteDelegated(address delegator, address delegateTo);
    event TaskProposalCreated(uint256 taskId, string description, address proposer);
    event TaskApplicationSubmitted(uint256 taskId, address applicant);
    event TaskCompletionApproved(uint256 taskId, address executor, address approver);
    event CouncilMemberVoted(address voter, address candidate);
    event CouncilElectionStarted();
    event CouncilMemberElected(address member);
    event ReputationBadgeMinted(address member, uint256 badgeId);

    // --- Modifiers ---

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function.");
        _;
    }

    modifier onlyMember() {
        require(members[msg.sender], "Only members can call this function.");
        _;
    }

    modifier onlyCouncil() {
        bool isCouncil = false;
        for (uint256 i = 0; i < councilMembers.length; i++) {
            if (councilMembers[i] == msg.sender) {
                isCouncil = true;
                break;
            }
        }
        require(isCouncil || msg.sender == owner, "Only council members or owner can call this function.");
        _;
    }


    // --- Constructor ---

    constructor(string memory _daoName) {
        owner = msg.sender;
        daoName = _daoName;
    }

    // --- 1. Membership Management ---

    function joinDAO() public {
        require(!members[msg.sender], "Already a member.");
        members[msg.sender] = true;
        memberList.push(msg.sender);
        emit MemberJoined(msg.sender);
    }

    function leaveDAO() public onlyMember {
        delete members[msg.sender];
        // Remove from memberList (more gas efficient ways exist for large lists but for clarity)
        address[] memory tempMemberList = new address[](memberList.length - 1);
        uint256 index = 0;
        for (uint256 i = 0; i < memberList.length; i++) {
            if (memberList[i] != msg.sender) {
                tempMemberList[index] = memberList[i];
                index++;
            }
        }
        memberList = tempMemberList;
        emit MemberLeft(msg.sender);
    }

    function isMember(address _member) public view returns (bool) {
        return members[_member];
    }

    function getMemberCount() public view returns (uint256) {
        return memberList.length;
    }

    // --- 2. Dynamic Reputation System ---

    function increaseReputation(address _member, uint256 _amount) public onlyCouncil {
        reputation[_member] += _amount;
        emit ReputationIncreased(_member, _amount, msg.sender);
    }

    function decreaseReputation(address _member, uint256 _amount) public onlyCouncil {
        require(reputation[_member] >= _amount, "Reputation cannot be negative.");
        reputation[_member] -= _amount;
        emit ReputationDecreased(_member, _amount, msg.sender);
    }

    function getReputation(address _member) public view returns (uint256) {
        return reputation[_member];
    }

    function getMemberRank(address _member) public view returns (string memory) {
        uint256 memberReputation = reputation[_member];
        if (memberReputation >= 1000) {
            return "Legendary Contributor";
        } else if (memberReputation >= 500) {
            return "Valued Member";
        } else if (memberReputation >= 100) {
            return "Active Member";
        } else {
            return "New Member";
        }
    }

    function transferReputation(address _recipient, uint256 _amount) public onlyMember {
        require(reputation[msg.sender] >= _amount, "Insufficient reputation to transfer.");
        reputation[msg.sender] -= _amount;
        reputation[_recipient] += _amount;
        emit ReputationTransferred(msg.sender, _recipient, _amount);
    }

    function decayReputation() public {
        if (block.timestamp >= lastReputationDecayTime + reputationDecayPeriod) {
            lastReputationDecayTime = block.timestamp;
            for (uint256 i = 0; i < memberList.length; i++) {
                address member = memberList[i];
                uint256 decayAmount = (reputation[member] * reputationDecayRate) / 100;
                if (reputation[member] >= decayAmount) {
                    reputation[member] -= decayAmount;
                    emit ReputationDecayed(member, decayAmount);
                } else {
                    reputation[member] = 0; // Avoid negative reputation
                    emit ReputationDecayed(member, reputation[member]); // Decay all remaining reputation
                }
            }
        }
    }
    uint256 public lastReputationDecayTime;


    // --- 3. Advanced Governance & Voting ---

    function proposeNewRule(string memory _ruleDescription, bytes memory _ruleData) public onlyMember {
        RuleProposal storage newProposal = ruleProposals[nextProposalId];
        newProposal.proposalId = nextProposalId;
        newProposal.description = _ruleDescription;
        newProposal.ruleData = _ruleData;
        newProposal.votingStartTime = block.timestamp;
        newProposal.votingEndTime = block.timestamp + 7 days; // 7 days voting period
        newProposal.executed = false;
        emit RuleProposalCreated(nextProposalId, _ruleDescription, msg.sender);
        nextProposalId++;
    }

    function voteOnRuleProposal(uint256 _proposalId, bool _support) public onlyMember {
        RuleProposal storage proposal = ruleProposals[_proposalId];
        require(proposal.votingStartTime <= block.timestamp && block.timestamp <= proposal.votingEndTime, "Voting period is not active.");
        require(!proposal.votes[msg.sender], "Already voted on this proposal.");
        proposal.votes[msg.sender] = true;

        uint256 votingPower = reputation[msg.sender];
        if (voteDelegation[msg.sender] != address(0)) {
            votingPower = reputation[voteDelegation[msg.sender]]; // Delegate voting power. Could be recursive delegation logic in advanced cases.
        }

        if (_support) {
            proposal.yesVotes += votingPower;
        } else {
            proposal.noVotes += votingPower;
        }
        emit VoteCast(_proposalId, msg.sender, _support);
    }

    function executeRuleProposal(uint256 _proposalId) public onlyCouncil {
        RuleProposal storage proposal = ruleProposals[_proposalId];
        require(block.timestamp > proposal.votingEndTime, "Voting period is still active.");
        require(!proposal.executed, "Proposal already executed.");

        uint256 totalVotes = proposal.yesVotes + proposal.noVotes;
        require(totalVotes > 0, "No votes cast on this proposal."); // Avoid division by zero
        uint256 quorum = (getMemberCount() * 50) / 100; // 50% quorum
        require(totalVotes >= quorum, "Quorum not reached.");

        uint256 majorityPercentage = (proposal.yesVotes * 100) / totalVotes;
        if (majorityPercentage > 60) { // 60% majority needed to pass
            proposal.executed = true;
            // Execute the rule change based on proposal.ruleData -  This part is highly dependent on what kind of rules you want to implement.
            // Example: if ruleData is an address, maybe update a DAO parameter.
            // For this example, we just emit an event indicating execution.
            emit RuleProposalExecuted(_proposalId);
        } else {
            // Proposal failed
        }
    }

    function delegateVote(address _delegateTo) public onlyMember {
        require(members[_delegateTo], "Delegate address must be a member.");
        require(_delegateTo != msg.sender, "Cannot delegate to self.");
        voteDelegation[msg.sender] = _delegateTo;
        emit VoteDelegated(msg.sender, _delegateTo);
    }


    function createTaskProposal(string memory _taskDescription, uint256 _reputationReward) public onlyMember {
        TaskProposal storage newTask = taskProposals[nextTaskId];
        newTask.taskId = nextTaskId;
        newTask.description = _taskDescription;
        newTask.reputationReward = _reputationReward;
        newTask.taskProposer = msg.sender;
        emit TaskProposalCreated(nextTaskId, _taskDescription, msg.sender);
        nextTaskId++;
    }

    function applyForTask(uint256 _taskId) public onlyMember {
        TaskProposal storage task = taskProposals[_taskId];
        require(task.assignedExecutor == address(0), "Task already assigned.");
        bool alreadyApplied = false;
        for (uint256 i = 0; i < task.applicants.length; i++) {
            if (task.applicants[i] == msg.sender) {
                alreadyApplied = true;
                break;
            }
        }
        require(!alreadyApplied, "Already applied for this task.");
        task.applicants.push(msg.sender);
        emit TaskApplicationSubmitted(_taskId, msg.sender);
    }

    function approveTaskCompletion(uint256 _taskId, address _executor) public onlyCouncil {
        TaskProposal storage task = taskProposals[_taskId];
        require(task.assignedExecutor == _executor, "Executor not assigned to this task.");
        require(!task.taskCompleted, "Task already marked as completed.");
        task.taskCompleted = true;
        increaseReputation(_executor, task.reputationReward);
        emit TaskCompletionApproved(_taskId, _executor, msg.sender);
    }


    function voteForCouncilMember(address _candidate) public onlyMember {
        require(members[_candidate], "Candidate must be a member.");
        require(reputation[_candidate] >= councilThreshold, "Candidate reputation too low to be council member.");
        require(block.timestamp <= lastCouncilElectionTime + councilElectionDuration, "Council election is not active.");

        councilVotes[_candidate]++;
        emit CouncilMemberVoted(msg.sender, _candidate);
    }

    function startCouncilElection() public onlyOwner {
        require(block.timestamp >= lastCouncilElectionTime + councilElectionDuration, "Council election is already active or cooldown period not finished.");
        lastCouncilElectionTime = block.timestamp;
        councilVotes = mapping(address => uint256)({}); // Reset votes
        emit CouncilElectionStarted();
    }

    function finalizeCouncilElection() public onlyOwner {
        require(block.timestamp > lastCouncilElectionTime + councilElectionDuration, "Council election is still active.");

        address winningCandidate = address(0);
        uint256 maxVotes = 0;
        for (uint256 i = 0; i < memberList.length; i++) { // Iterate through members to check votes as candidates might not be explicitly tracked
            address member = memberList[i];
            if (councilVotes[member] > maxVotes) {
                maxVotes = councilVotes[member];
                winningCandidate = member;
            }
        }

        if (winningCandidate != address(0)) {
            councilMembers.push(winningCandidate);
            emit CouncilMemberElected(winningCandidate);
        } else {
            // No winner in this round
        }
    }


    // --- 4. Dynamic NFT Reputation Badges (Simplified Example - Requires external NFT contract or library for full implementation) ---

    function mintReputationBadge(address _member) public onlyCouncil {
        // --- Simplified Badge Minting Logic ---
        // In a real-world scenario, you would interact with an NFT contract (ERC721 or ERC1155)
        // and mint an NFT based on the member's reputation level.
        // Here, we'll just emit an event with a hypothetical badge ID.

        uint256 badgeId = getReputationBadgeId(_member); // Function to determine badge ID based on reputation
        // In real implementation, call NFT contract's mint function:
        // nftContract.mint(_member, badgeId, ...);

        emit ReputationBadgeMinted(_member, badgeId);
    }

    function getReputationBadgeURI(address _member) public view returns (string memory) {
        uint256 badgeId = getReputationBadgeId(_member);
        // In real implementation, construct URI based on badgeId and metadata standards.
        return string(abi.encodePacked("ipfs://your-ipfs-cid/badge-metadata-", Strings.toString(badgeId), ".json"));
    }

    function getReputationBadgeId(address _member) internal view returns (uint256) {
        uint256 memberReputation = reputation[_member];
        if (memberReputation >= 1000) {
            return 3; // Legendary Badge
        } else if (memberReputation >= 500) {
            return 2; // Valued Badge
        } else if (memberReputation >= 100) {
            return 1; // Active Badge
        } else {
            return 0; // New Member Badge
        }
    }
}

// --- Helper library for string conversion (Solidity 0.8+ requires external library for uint to string) ---
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.5.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }
}
```