```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/*
 *  Smart Contract Outline: Decentralized Autonomous Organization for Creative Projects (DAO-CP)
 *
 *  Function Summary:
 *  -----------------
 *  // --- Core DAO Functions ---
 *  1. proposeProject(string projectName, string projectDescription, uint256 fundingGoal, string[] projectTags): Allows members to propose new creative projects to the DAO.
 *  2. voteOnProposal(uint256 proposalId, bool vote): Members can vote on project proposals (for or against).
 *  3. executeProposal(uint256 proposalId): Executes a proposal if it passes the voting threshold.
 *  4. depositDAOFunds() payable: Allows anyone to deposit funds into the DAO's treasury.
 *  5. withdrawDAOFunds(uint256 amount): Allows governance (e.g., DAO owners/admins) to withdraw funds from the treasury for DAO operations (governance controlled).
 *  6. addMember(address newMember): Allows governance to add new members to the DAO.
 *  7. removeMember(address memberToRemove): Allows governance to remove members from the DAO.
 *  8. setVotingDuration(uint256 durationInBlocks): Allows governance to set the default voting duration for proposals.
 *  9. setQuorum(uint256 quorumPercentage): Allows governance to set the quorum percentage required for proposal acceptance.
 *  10. getProposalDetails(uint256 proposalId): Retrieves detailed information about a specific project proposal.
 *  11. getMemberDetails(address memberAddress): Retrieves details about a DAO member, including their reputation and projects.
 *  12. getDAOBalance(): Retrieves the current balance of the DAO treasury.
 *  13. getActiveProposals(): Returns a list of currently active project proposal IDs.
 *
 *  // --- Project & Creative Functions ---
 *  14. fundProject(uint256 projectId) payable: Members or external contributors can fund approved projects.
 *  15. requestMilestonePayment(uint256 projectId, string milestoneDescription, uint256 amount): Project owners can request payments upon reaching project milestones.
 *  16. voteOnMilestonePayment(uint256 projectId, uint256 milestoneId, bool vote): Members vote to approve or reject milestone payment requests.
 *  17. reportProjectProgress(uint256 projectId, string progressUpdate): Project owners can report progress updates on their projects.
 *  18. endorseProject(uint256 projectId): Members can endorse projects they believe are valuable or promising.
 *  19. rewardProjectContributor(uint256 projectId, address contributor, uint256 rewardAmount):  Project owners can reward contributors for specific tasks or contributions (governance approval might be added for larger rewards).
 *  20. createBounty(uint256 projectId, string bountyDescription, uint256 bountyAmount): Project owners can create bounties for specific tasks related to their projects, attracting external contributors.
 *  21. claimBounty(uint256 bountyId): Anyone can claim a bounty by completing the associated task (verification process needed, simplified here).
 *  22. voteOnBountyClaim(uint256 bountyId, bool vote): Members vote to approve or reject a bounty claim (could be project owner or DAO vote).
 *
 *  // --- Reputation & Incentive Functions (Advanced Concept) ---
 *  23. contributeSkill(string skillDescription): Members can register skills they possess, building a skill profile within the DAO.
 *  24. endorseMemberSkill(address memberAddress, string skillDescription): Members can endorse other members for specific skills, building reputation.
 *  25. getMemberSkillProfile(address memberAddress): Retrieves the skill profile of a DAO member, including endorsements.
 *
 */

contract CreativeProjectDAO {
    // --- State Variables ---

    address public daoOwner; // Address of the DAO owner/admin (can be a multisig wallet)
    uint256 public votingDurationBlocks = 100; // Default voting duration in blocks
    uint256 public quorumPercentage = 50; // Percentage of votes required for proposal to pass

    uint256 public proposalCount = 0;
    mapping(uint256 => Proposal) public proposals;
    mapping(uint256 => mapping(address => bool)) public proposalVotes; // proposalId => memberAddress => voted

    uint256 public bountyCount = 0;
    mapping(uint256 => Bounty) public bounties;
    mapping(uint256 => mapping(address => bool)) public bountyClaimVotes; // bountyId => memberAddress => voted

    mapping(address => Member) public members;
    address[] public memberList;
    mapping(address => bool) public isMember;

    // --- Structs ---

    struct Proposal {
        uint256 id;
        string projectName;
        string projectDescription;
        uint256 fundingGoal;
        string[] projectTags;
        address proposer;
        uint256 voteStartTime;
        uint256 voteEndTime;
        uint256 yesVotes;
        uint256 noVotes;
        bool executed;
        bool passed;
    }

    struct Bounty {
        uint256 id;
        uint256 projectId;
        string bountyDescription;
        uint256 bountyAmount;
        address creator;
        address claimant;
        bool claimed;
        uint256 voteStartTime;
        uint256 voteEndTime;
        uint256 yesVotes;
        uint256 noVotes;
        bool approved;
    }

    struct Member {
        address memberAddress;
        uint256 reputationScore; // Example reputation system
        string[] skills;
        mapping(string => address[]) skillEndorsements; // skill => endorser addresses
    }


    // --- Events ---

    event ProposalCreated(uint256 proposalId, string projectName, address proposer);
    event ProposalVoted(uint256 proposalId, address voter, bool vote);
    event ProposalExecuted(uint256 proposalId, bool passed);
    event DAOFundsDeposited(address depositor, uint256 amount);
    event DAOFundsWithdrawn(address withdrawer, uint256 amount);
    event MemberAdded(address newMember);
    event MemberRemoved(address removedMember);
    event ProjectFunded(uint256 projectId, address funder, uint256 amount);
    event MilestonePaymentRequested(uint256 projectId, uint256 milestoneId, string description, uint256 amount);
    event MilestonePaymentVoted(uint256 projectId, uint256 milestoneId, address voter, bool vote);
    event ProjectProgressReported(uint256 projectId, string progressUpdate);
    event ProjectEndorsed(uint256 projectId, address endorser);
    event ContributorRewarded(uint256 projectId, address contributor, uint256 rewardAmount);
    event BountyCreated(uint256 bountyId, uint256 projectId, string description, uint256 amount, address creator);
    event BountyClaimed(uint256 bountyId, address claimant);
    event BountyClaimVoted(uint256 bountyId, address voter, bool vote);
    event BountyClaimApproved(uint256 bountyId);
    event SkillContributed(address member, string skill);
    event SkillEndorsed(address member, string skill, address endorser);


    // --- Modifiers ---

    modifier onlyOwner() {
        require(msg.sender == daoOwner, "Only DAO owner can call this function.");
        _;
    }

    modifier onlyMember() {
        require(isMember[msg.sender], "Only DAO members can call this function.");
        _;
    }

    modifier validProposal(uint256 proposalId) {
        require(proposals[proposalId].id == proposalId, "Invalid proposal ID.");
        _;
    }

    modifier validBounty(uint256 bountyId) {
        require(bounties[bountyId].id == bountyId, "Invalid bounty ID.");
        _;
    }

    modifier proposalVotingActive(uint256 proposalId) {
        require(block.number >= proposals[proposalId].voteStartTime && block.number <= proposals[proposalId].voteEndTime, "Voting is not active for this proposal.");
        _;
    }

    modifier bountyVotingActive(uint256 bountyId) {
        require(block.number >= bounties[bountyId].voteStartTime && block.number <= bounties[bountyId].voteEndTime, "Voting is not active for this bounty claim.");
        _;
    }

    modifier proposalNotExecuted(uint256 proposalId) {
        require(!proposals[proposalId].executed, "Proposal already executed.");
        _;
    }

    modifier bountyNotClaimed(uint256 bountyId) {
        require(!bounties[bountyId].claimed, "Bounty already claimed.");
        _;
    }

    modifier bountyClaimNotApproved(uint256 bountyId) {
        require(!bounties[bountyId].approved, "Bounty claim already approved.");
        _;
    }


    // --- Constructor ---

    constructor() {
        daoOwner = msg.sender;
    }

    // --- Core DAO Functions ---

    function proposeProject(string memory projectName, string memory projectDescription, uint256 fundingGoal, string[] memory projectTags) public onlyMember {
        proposalCount++;
        Proposal storage newProposal = proposals[proposalCount];
        newProposal.id = proposalCount;
        newProposal.projectName = projectName;
        newProposal.projectDescription = projectDescription;
        newProposal.fundingGoal = fundingGoal;
        newProposal.projectTags = projectTags;
        newProposal.proposer = msg.sender;
        newProposal.voteStartTime = block.number;
        newProposal.voteEndTime = block.number + votingDurationBlocks;
        emit ProposalCreated(proposalCount, projectName, msg.sender);
    }

    function voteOnProposal(uint256 proposalId, bool vote) public onlyMember validProposal(proposalId) proposalVotingActive(proposalId) proposalNotExecuted(proposalId) {
        require(!proposalVotes[proposalId][msg.sender], "Member has already voted on this proposal.");
        proposalVotes[proposalId][msg.sender] = true;
        if (vote) {
            proposals[proposalId].yesVotes++;
        } else {
            proposals[proposalId].noVotes++;
        }
        emit ProposalVoted(proposalId, msg.sender, vote);
    }

    function executeProposal(uint256 proposalId) public onlyMember validProposal(proposalId) proposalNotExecuted(proposalId) {
        require(block.number > proposals[proposalId].voteEndTime, "Voting is still active.");
        uint256 totalVotes = proposals[proposalId].yesVotes + proposals[proposalId].noVotes;
        require(totalVotes > 0, "No votes cast on this proposal."); // Prevent division by zero
        uint256 yesPercentage = (proposals[proposalId].yesVotes * 100) / totalVotes;

        if (yesPercentage >= quorumPercentage) {
            proposals[proposalId].passed = true;
        } else {
            proposals[proposalId].passed = false;
        }
        proposals[proposalId].executed = true;
        emit ProposalExecuted(proposalId, proposals[proposalId].passed);
    }

    function depositDAOFunds() public payable {
        emit DAOFundsDeposited(msg.sender, msg.value);
    }

    function withdrawDAOFunds(uint256 amount) public onlyOwner {
        payable(daoOwner).transfer(amount);
        emit DAOFundsWithdrawn(daoOwner, amount);
    }

    function addMember(address newMember) public onlyOwner {
        require(!isMember[newMember], "Address is already a member.");
        members[newMember].memberAddress = newMember;
        isMember[newMember] = true;
        memberList.push(newMember);
        emit MemberAdded(newMember);
    }

    function removeMember(address memberToRemove) public onlyOwner {
        require(isMember[memberToRemove], "Address is not a member.");
        isMember[memberToRemove] = false;
        // Optional: Remove from memberList if needed, but can be skipped for simplicity in this example.
        emit MemberRemoved(memberToRemove);
    }

    function setVotingDuration(uint256 durationInBlocks) public onlyOwner {
        votingDurationBlocks = durationInBlocks;
    }

    function setQuorum(uint256 quorumPercentage_) public onlyOwner {
        require(quorumPercentage_ <= 100, "Quorum percentage must be less than or equal to 100.");
        quorumPercentage = quorumPercentage_;
    }

    function getProposalDetails(uint256 proposalId) public view validProposal(proposalId) returns (Proposal memory) {
        return proposals[proposalId];
    }

    function getMemberDetails(address memberAddress) public view returns (Member memory) {
        return members[memberAddress];
    }

    function getDAOBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function getActiveProposals() public view returns (uint256[] memory) {
        uint256[] memory activeProposalIds = new uint256[](proposalCount);
        uint256 count = 0;
        for (uint256 i = 1; i <= proposalCount; i++) {
            if (block.number >= proposals[i].voteStartTime && block.number <= proposals[i].voteEndTime && !proposals[i].executed) {
                activeProposalIds[count] = i;
                count++;
            }
        }
        // Resize array to actual number of active proposals
        uint256[] memory resizedActiveProposals = new uint256[](count);
        for (uint256 i = 0; i < count; i++) {
            resizedActiveProposals[i] = activeProposalIds[i];
        }
        return resizedActiveProposals;
    }

    // --- Project & Creative Functions ---

    function fundProject(uint256 projectId) public payable validProposal(projectId) {
        require(proposals[projectId].passed, "Project proposal must be approved to receive funding.");
        require(msg.value > 0, "Funding amount must be greater than zero.");
        // In a real-world scenario, funds might be managed more carefully, potentially locked until milestones are met.
        // For simplicity, here funds are directly added to the contract balance (representing project funds pool).
        emit ProjectFunded(projectId, msg.sender, msg.value);
    }

    uint256 public milestoneCount = 0;
    mapping(uint256 => mapping(uint256 => MilestonePaymentRequest)) public projectMilestoneRequests;

    struct MilestonePaymentRequest {
        uint256 id;
        uint256 projectId;
        string description;
        uint256 amount;
        address requester;
        uint256 voteStartTime;
        uint256 voteEndTime;
        uint256 yesVotes;
        uint256 noVotes;
        bool approved;
    }

    function requestMilestonePayment(uint256 projectId, string memory milestoneDescription, uint256 amount) public onlyMember validProposal(projectId) {
        require(proposals[projectId].proposer == msg.sender, "Only project proposer can request milestone payments.");
        milestoneCount++;
        MilestonePaymentRequest storage newRequest = projectMilestoneRequests[projectId][milestoneCount];
        newRequest.id = milestoneCount;
        newRequest.projectId = projectId;
        newRequest.description = milestoneDescription;
        newRequest.amount = amount;
        newRequest.requester = msg.sender;
        newRequest.voteStartTime = block.number;
        newRequest.voteEndTime = block.number + votingDurationBlocks;
        emit MilestonePaymentRequested(projectId, milestoneCount, milestoneDescription, amount);
    }

    function voteOnMilestonePayment(uint256 projectId, uint256 milestoneId, bool vote) public onlyMember validProposal(projectId) {
        MilestonePaymentRequest storage request = projectMilestoneRequests[projectId][milestoneId];
        require(request.projectId == projectId && request.id == milestoneId, "Invalid milestone request.");
        require(block.number >= request.voteStartTime && block.number <= request.voteEndTime, "Milestone payment voting is not active.");
        require(!request.approved, "Milestone payment already approved."); // Prevent double voting/processing
        require(proposalVotes[projectId][msg.sender] == false, "Member has already voted on this milestone."); // Reuse proposalVotes mapping for simplicity

        proposalVotes[projectId][msg.sender] = true; // Mark member as voted (using proposalVotes mapping for milestone votes for simplicity)
        if (vote) {
            request.yesVotes++;
        } else {
            request.noVotes++;
        }
        emit MilestonePaymentVoted(projectId, milestoneId, msg.sender, vote);

        if (block.number > request.voteEndTime) { // Check if voting period ended after vote cast, and execute if passed
            uint256 totalVotes = request.yesVotes + request.noVotes;
            if (totalVotes > 0) {
                uint256 yesPercentage = (request.yesVotes * 100) / totalVotes;
                if (yesPercentage >= quorumPercentage) {
                    request.approved = true;
                    payable(proposals[projectId].proposer).transfer(request.amount); // Pay to project proposer
                }
            }
        }
    }

    function reportProjectProgress(uint256 projectId, string memory progressUpdate) public onlyMember validProposal(projectId) {
        require(proposals[projectId].proposer == msg.sender, "Only project proposer can report progress.");
        // In a real application, you might store progress reports more systematically (e.g., in a linked list or IPFS).
        emit ProjectProgressReported(projectId, progressUpdate);
    }

    function endorseProject(uint256 projectId) public onlyMember validProposal(projectId) {
        // Simple endorsement - could be expanded to track endorsement count, etc.
        emit ProjectEndorsed(projectId, msg.sender);
    }

    function rewardProjectContributor(uint256 projectId, address contributor, uint256 rewardAmount) public onlyMember validProposal(projectId) {
        require(proposals[projectId].proposer == msg.sender, "Only project proposer can reward contributors.");
        require(rewardAmount > 0, "Reward amount must be greater than zero.");
        require(address(this).balance >= rewardAmount, "DAO treasury does not have sufficient funds for reward.");
        payable(contributor).transfer(rewardAmount);
        emit ContributorRewarded(projectId, contributor, rewardAmount);
    }

    function createBounty(uint256 projectId, string memory bountyDescription, uint256 bountyAmount) public onlyMember validProposal(projectId) {
        require(proposals[projectId].proposer == msg.sender, "Only project proposer can create bounties for their project.");
        require(bountyAmount > 0, "Bounty amount must be greater than zero.");
        bountyCount++;
        Bounty storage newBounty = bounties[bountyCount];
        newBounty.id = bountyCount;
        newBounty.projectId = projectId;
        newBounty.bountyDescription = bountyDescription;
        newBounty.bountyAmount = bountyAmount;
        newBounty.creator = msg.sender;
        emit BountyCreated(bountyCount, projectId, bountyDescription, bountyAmount, msg.sender);
    }

    function claimBounty(uint256 bountyId) public validBounty(bountyId) bountyNotClaimed(bountyId) bountyClaimNotApproved(bountyId){
        require(bounties[bountyId].claimant == address(0), "Bounty already claimed."); // Ensure only claimed once
        bounties[bountyId].claimant = msg.sender;
        bounties[bountyId].claimed = true;
        bounties[bountyId].voteStartTime = block.number;
        bounties[bountyId].voteEndTime = block.number + votingDurationBlocks;
        emit BountyClaimed(bountyId, msg.sender);
    }

    function voteOnBountyClaim(uint256 bountyId, bool vote) public onlyMember validBounty(bountyId) bountyVotingActive(bountyId) bountyClaimNotApproved(bountyId){
        require(bounties[bountyId].claimed, "Bounty must be claimed before voting on claim.");
        require(!bountyClaimVotes[bountyId][msg.sender], "Member has already voted on this bounty claim.");
        bountyClaimVotes[bountyId][msg.sender] = true;
        if (vote) {
            bounties[bountyId].yesVotes++;
        } else {
            bounties[bountyId].noVotes++;
        }
        emit BountyClaimVoted(bountyId, msg.sender, vote);
    }

    function finalizeBountyClaim(uint256 bountyId) public onlyMember validBounty(bountyId) bountyClaimNotApproved(bountyId){
        require(bounties[bountyId].claimed, "Bounty must be claimed to finalize.");
        require(block.number > bounties[bountyId].voteEndTime, "Bounty claim voting is still active.");

        uint256 totalVotes = bounties[bountyId].yesVotes + bounties[bountyId].noVotes;
        require(totalVotes > 0, "No votes cast on this bounty claim.");
        uint256 yesPercentage = (bounties[bountyId].yesVotes * 100) / totalVotes;

        if (yesPercentage >= quorumPercentage) {
            bounties[bountyId].approved = true;
            payable(bounties[bountyId].claimant).transfer(bounties[bountyId].bountyAmount);
            emit BountyClaimApproved(bountyId);
        } else {
            // Bounty claim rejected - might want to handle this differently, e.g., allow re-claiming or re-voting.
        }
    }


    // --- Reputation & Incentive Functions (Advanced Concept) ---

    function contributeSkill(string memory skillDescription) public onlyMember {
        bool skillExists = false;
        for (uint256 i = 0; i < members[msg.sender].skills.length; i++) {
            if (keccak256(bytes(members[msg.sender].skills[i])) == keccak256(bytes(skillDescription))) {
                skillExists = true;
                break;
            }
        }
        if (!skillExists) {
            members[msg.sender].skills.push(skillDescription);
            emit SkillContributed(msg.sender, skillDescription);
        }
    }

    function endorseMemberSkill(address memberAddress, string memory skillDescription) public onlyMember {
        require(isMember[memberAddress], "Target address is not a member.");
        members[memberAddress].skillEndorsements[skillDescription].push(msg.sender);
        emit SkillEndorsed(memberAddress, skillDescription, msg.sender);
    }

    function getMemberSkillProfile(address memberAddress) public view returns (Member memory) {
        return members[memberAddress];
    }

    // --- Fallback and Receive Functions (Optional for fund deposits) ---
    receive() external payable {
        emit DAOFundsDeposited(msg.sender, msg.value);
    }

    fallback() external payable {
        emit DAOFundsDeposited(msg.sender, msg.value);
    }
}
```