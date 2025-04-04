```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Decentralized Autonomous Research Organization (DARO) Smart Contract
 * @author Bard (AI Assistant)
 * @dev A smart contract for a Decentralized Autonomous Research Organization (DARO) that manages research proposals, funding, researcher reputation,
 *      data sharing, and governance, incorporating advanced concepts like dynamic reputation scoring, quadratic voting for proposals,
 *      decentralized data storage integration (simulated here), and on-chain dispute resolution.
 *
 * Function Summary:
 * -----------------
 * **Governance & Membership:**
 * 1.  `proposeGovernanceChange(string memory description, bytes memory data)`: Allows members to propose changes to governance parameters.
 * 2.  `voteOnGovernanceChange(uint256 proposalId, bool support)`: Members vote on governance change proposals.
 * 3.  `executeGovernanceChange(uint256 proposalId)`: Executes approved governance changes.
 * 4.  `applyForMembership(string memory researcherProfile)`: Allows researchers to apply for membership with their profile information.
 * 5.  `approveMembership(address researcherAddress)`: Governance members can approve pending membership applications.
 * 6.  `revokeMembership(address memberAddress)`: Governance members can revoke membership.
 *
 * **Research Proposals & Funding:**
 * 7.  `submitResearchProposal(string memory title, string memory description, uint256 fundingGoal, string memory ipfsDataHash)`: Researchers submit research proposals with funding goals and data links.
 * 8.  `fundResearchProposal(uint256 proposalId)`: Allows anyone to contribute funds to a research proposal.
 * 9.  `voteOnResearchProposal(uint256 proposalId, bool support)`: Members vote on research proposals using quadratic voting.
 * 10. `finalizeResearchProposal(uint256 proposalId)`: Finalizes a research proposal after funding is reached and voting is successful.
 * 11. `requestMilestonePayment(uint256 proposalId, string memory milestoneDescription, string memory evidenceIpfsHash)`: Researchers request payment for completed milestones.
 * 12. `approveMilestonePayment(uint256 proposalId)`: Governance members approve milestone payments.
 * 13. `withdrawProposalFunds(uint256 proposalId)`: Researchers can withdraw funds for approved milestones (partially or fully funded proposals).
 * 14. `cancelResearchProposal(uint256 proposalId)`: Governance can cancel proposals under certain conditions (e.g., lack of progress).
 *
 * **Researcher Reputation & Data Management:**
 * 15. `submitResearchData(uint256 proposalId, string memory dataDescription, string memory ipfsDataHash)`: Researchers submit research data related to a proposal.
 * 16. `reviewResearchData(uint256 proposalId, string memory reviewComment, uint8 rating)`: Governance members review and rate submitted research data, affecting researcher reputation.
 * 17. `getResearcherReputation(address researcherAddress)`: Retrieves the reputation score of a researcher.
 * 18. `accessResearchData(uint256 proposalId)`: Allows members to access research data (simulated access control based on proposal and membership).
 *
 * **Dispute Resolution & Emergency:**
 * 19. `raiseDispute(uint256 proposalId, string memory disputeDescription)`: Members can raise disputes regarding proposals or research.
 * 20. `resolveDispute(uint256 disputeId, bool resolution)`: Governance members vote to resolve disputes.
 * 21. `pauseContract()`: Governance can pause the contract in case of emergency.
 * 22. `unpauseContract()`: Governance can unpause the contract.
 */

contract DecentralizedAutonomousResearchOrganization {

    // -------- State Variables --------

    address public governanceAdmin; // Address that can manage governance roles and emergency functions
    mapping(address => bool) public governanceMembers; // Mapping of governance members
    uint256 public governanceQuorum = 50; // Percentage of governance members required for quorum
    uint256 public governanceVotingDuration = 7 days; // Duration for governance votes

    struct Researcher {
        string profile;
        uint256 reputationScore;
        bool isMember;
    }
    mapping(address => Researcher) public researchers;
    address[] public pendingMembershipApplications;

    struct ResearchProposal {
        uint256 id;
        address researcher;
        string title;
        string description;
        uint256 fundingGoal;
        uint256 currentFunding;
        string ipfsDataHash; // IPFS hash for proposal details
        ProposalStatus status;
        uint256 votingStartTime;
        uint256 votingEndTime;
        mapping(address => uint256) votes; // Address => Vote Power (Quadratic voting, simulated with ETH sent)
        uint256 positiveVotes;
        uint256 negativeVotes;
    }
    enum ProposalStatus { Pending, Voting, Funded, Active, Completed, Cancelled, Dispute }
    ResearchProposal[] public researchProposals;
    uint256 public proposalCounter;
    uint256 public proposalVotingDuration = 3 days;
    uint256 public proposalFundingThreshold = 75; // Percentage of funding goal required for voting

    struct Milestone {
        string description;
        string evidenceIpfsHash;
        bool approved;
        bool paid;
    }
    mapping(uint256 => Milestone[]) public proposalMilestones; // proposalId => Milestones

    struct GovernanceProposal {
        uint256 id;
        string description;
        bytes data; // Encoded data for governance action
        uint256 votingStartTime;
        uint256 votingEndTime;
        mapping(address => bool) votes;
        uint256 positiveVotes;
        uint256 negativeVotes;
        bool executed;
    }
    GovernanceProposal[] public governanceProposals;
    uint256 public governanceProposalCounter;

    struct ResearchData {
        string description;
        string ipfsDataHash;
        address researcher;
        uint256 timestamp;
        mapping(address => uint8) reviews; // Reviewer address => rating (0-10)
        uint256 totalRatingScore;
        uint256 reviewCount;
    }
    mapping(uint256 => ResearchData[]) public proposalResearchData; // proposalId => Research Data entries

    struct Dispute {
        uint256 id;
        uint256 proposalId;
        string description;
        DisputeStatus status;
        uint256 votingStartTime;
        uint256 votingEndTime;
        mapping(address => bool) votes;
        uint256 positiveVotes;
        uint256 negativeVotes;
        bool resolved;
        bool resolution; // true = dispute resolved in favor of raiser, false = against
    }
    enum DisputeStatus { Open, Voting, Resolved }
    Dispute[] public disputes;
    uint256 public disputeCounter;
    uint256 public disputeVotingDuration = 5 days;

    bool public paused = false;

    // -------- Events --------
    event GovernanceChangeProposed(uint256 proposalId, string description);
    event GovernanceChangeVoted(uint256 proposalId, address voter, bool support);
    event GovernanceChangeExecuted(uint256 proposalId);
    event MembershipApplied(address researcherAddress);
    event MembershipApproved(address researcherAddress);
    event MembershipRevoked(address memberAddress);
    event ResearchProposalSubmitted(uint256 proposalId, address researcher, string title);
    event ResearchProposalFunded(uint256 proposalId, address funder, uint256 amount);
    event ResearchProposalVoted(uint256 proposalId, address voter, bool support);
    event ResearchProposalFinalized(uint256 proposalId, uint256 finalFunding);
    event MilestonePaymentRequested(uint256 proposalId, uint256 milestoneIndex, string description);
    event MilestonePaymentApproved(uint256 proposalId, uint256 milestoneIndex);
    event FundsWithdrawn(uint256 proposalId, address researcher, uint256 amount);
    event ResearchDataSubmitted(uint256 proposalId, uint256 dataIndex, address researcher, string description);
    event ResearchDataReviewed(uint256 proposalId, uint256 dataIndex, address reviewer, uint8 rating);
    event ReputationScoreUpdated(address researcherAddress, uint256 newScore);
    event DisputeRaised(uint256 disputeId, uint256 proposalId, address raiser);
    event DisputeResolved(uint256 disputeId, bool resolution);
    event ContractPaused();
    event ContractUnpaused();

    // -------- Modifiers --------
    modifier onlyGovernance() {
        require(governanceMembers[msg.sender], "Not a governance member");
        _;
    }

    modifier onlyGovernanceAdmin() {
        require(msg.sender == governanceAdmin, "Not governance admin");
        _;
    }

    modifier onlyResearcher(uint256 proposalId) {
        require(researchProposals[proposalId].researcher == msg.sender, "Not the proposal researcher");
        _;
    }

    modifier proposalExists(uint256 proposalId) {
        require(proposalId < researchProposals.length, "Proposal does not exist");
        _;
    }

    modifier governanceProposalExists(uint256 proposalId) {
        require(proposalId < governanceProposals.length, "Governance Proposal does not exist");
        _;
    }

    modifier disputeExists(uint256 disputeId) {
        require(disputeId < disputes.length, "Dispute does not exist");
        _;
    }

    modifier notPaused() {
        require(!paused, "Contract is paused");
        _;
    }

    // -------- Constructor --------
    constructor() {
        governanceAdmin = msg.sender;
        governanceMembers[msg.sender] = true; // Deployer is initial governance member
    }

    // -------- Governance & Membership Functions --------

    /// @dev Allows governance members to propose changes to governance parameters.
    /// @param description Description of the governance change proposal.
    /// @param data Encoded data for the governance change (e.g., function signature and parameters).
    function proposeGovernanceChange(string memory description, bytes memory data) external onlyGovernance notPaused {
        governanceProposals.push(GovernanceProposal({
            id: governanceProposalCounter++,
            description: description,
            data: data,
            votingStartTime: block.timestamp,
            votingEndTime: block.timestamp + governanceVotingDuration,
            positiveVotes: 0,
            negativeVotes: 0,
            executed: false
        }));
        emit GovernanceChangeProposed(governanceProposals.length - 1, description);
    }

    /// @dev Allows governance members to vote on a governance change proposal.
    /// @param proposalId ID of the governance proposal to vote on.
    /// @param support True for supporting the proposal, false for opposing.
    function voteOnGovernanceChange(uint256 proposalId, bool support) external onlyGovernance governanceProposalExists(proposalId) notPaused {
        GovernanceProposal storage proposal = governanceProposals[proposalId];
        require(block.timestamp >= proposal.votingStartTime && block.timestamp <= proposal.votingEndTime, "Voting period is not active");
        require(!proposal.votes[msg.sender], "Already voted");

        proposal.votes[msg.sender] = true;
        if (support) {
            proposal.positiveVotes++;
        } else {
            proposal.negativeVotes++;
        }
        emit GovernanceChangeVoted(proposalId, msg.sender, support);
    }

    /// @dev Executes a governance change proposal if it has passed the voting and quorum requirements.
    /// @param proposalId ID of the governance proposal to execute.
    function executeGovernanceChange(uint256 proposalId) external onlyGovernance governanceProposalExists(proposalId) notPaused {
        GovernanceProposal storage proposal = governanceProposals[proposalId];
        require(block.timestamp > proposal.votingEndTime, "Voting period is not over");
        require(!proposal.executed, "Proposal already executed");

        uint256 totalGovernanceMembers = 0;
        for (uint i = 0; i < governanceProposals.length; i++) { // Inefficient in real-world, better to track active members separately
            if (governanceMembers[address(uint160(i))]) { // Placeholder, needs proper member tracking
                totalGovernanceMembers++;
            }
        }
        uint256 quorumNeeded = (totalGovernanceMembers * governanceQuorum) / 100;
        require(proposal.positiveVotes > proposal.negativeVotes && proposal.positiveVotes >= quorumNeeded, "Governance quorum not met or proposal rejected");

        // Execute the governance change based on proposal.data (Example - needs proper decoding and execution logic based on design)
        (bool success, ) = address(this).delegatecall(proposal.data); // Be extremely careful with delegatecall in production
        require(success, "Governance change execution failed");

        proposal.executed = true;
        emit GovernanceChangeExecuted(proposalId);
    }


    /// @dev Allows researchers to apply for membership by submitting their profile information.
    /// @param researcherProfile String containing researcher profile details (e.g., skills, experience, affiliations).
    function applyForMembership(string memory researcherProfile) external notPaused {
        require(!researchers[msg.sender].isMember, "Already a member");
        researchers[msg.sender] = Researcher({profile: researcherProfile, reputationScore: 0, isMember: false});
        pendingMembershipApplications.push(msg.sender);
        emit MembershipApplied(msg.sender);
    }

    /// @dev Allows governance members to approve a pending membership application.
    /// @param researcherAddress Address of the researcher to approve for membership.
    function approveMembership(address researcherAddress) external onlyGovernance notPaused {
        require(!researchers[researcherAddress].isMember, "Already a member");
        researchers[researcherAddress].isMember = true;
        // Remove from pending list (inefficient for large lists, consider alternatives for production)
        for (uint i = 0; i < pendingMembershipApplications.length; i++) {
            if (pendingMembershipApplications[i] == researcherAddress) {
                pendingMembershipApplications[i] = pendingMembershipApplications[pendingMembershipApplications.length - 1];
                pendingMembershipApplications.pop();
                break;
            }
        }
        emit MembershipApproved(researcherAddress);
    }

    /// @dev Allows governance members to revoke membership of a researcher.
    /// @param memberAddress Address of the member to revoke membership from.
    function revokeMembership(address memberAddress) external onlyGovernance notPaused {
        require(researchers[memberAddress].isMember, "Not a member");
        researchers[memberAddress].isMember = false;
        emit MembershipRevoked(memberAddress);
    }


    // -------- Research Proposal & Funding Functions --------

    /// @dev Allows researchers to submit a research proposal.
    /// @param title Title of the research proposal.
    /// @param description Detailed description of the research proposal.
    /// @param fundingGoal Funding goal for the research proposal in wei.
    /// @param ipfsDataHash IPFS hash pointing to a document with detailed proposal information.
    function submitResearchProposal(string memory title, string memory description, uint256 fundingGoal, string memory ipfsDataHash) external notPaused {
        require(researchers[msg.sender].isMember, "Must be a member to submit a proposal");
        researchProposals.push(ResearchProposal({
            id: proposalCounter++,
            researcher: msg.sender,
            title: title,
            description: description,
            fundingGoal: fundingGoal,
            currentFunding: 0,
            ipfsDataHash: ipfsDataHash,
            status: ProposalStatus.Pending,
            votingStartTime: 0,
            votingEndTime: 0,
            positiveVotes: 0,
            negativeVotes: 0
        }));
        emit ResearchProposalSubmitted(researchProposals.length - 1, msg.sender, title);
    }

    /// @dev Allows anyone to contribute funds to a research proposal.
    /// @param proposalId ID of the research proposal to fund.
    function fundResearchProposal(uint256 proposalId) external payable proposalExists(proposalId) notPaused {
        ResearchProposal storage proposal = researchProposals[proposalId];
        require(proposal.status == ProposalStatus.Pending, "Proposal is not in Pending status");
        proposal.currentFunding += msg.value;
        emit ResearchProposalFunded(proposalId, msg.sender, msg.value);

        // Automatically start voting if funding threshold is reached
        if (proposal.currentFunding >= (proposal.fundingGoal * proposalFundingThreshold) / 100 && proposal.status == ProposalStatus.Pending) {
            _startProposalVoting(proposalId);
        }
    }

    /// @dev Starts the voting process for a research proposal. Internal function.
    /// @param proposalId ID of the research proposal to start voting for.
    function _startProposalVoting(uint256 proposalId) internal proposalExists(proposalId) {
        ResearchProposal storage proposal = researchProposals[proposalId];
        require(proposal.status == ProposalStatus.Pending, "Proposal is not in Pending status");
        proposal.status = ProposalStatus.Voting;
        proposal.votingStartTime = block.timestamp;
        proposal.votingEndTime = block.timestamp + proposalVotingDuration;
    }

    /// @dev Allows members to vote on a research proposal using quadratic voting (simulated by ETH value sent).
    /// @param proposalId ID of the research proposal to vote on.
    /// @param support True for supporting the proposal, false for opposing.
    function voteOnResearchProposal(uint256 proposalId, bool support) external payable onlyGovernance proposalExists(proposalId) notPaused {
        ResearchProposal storage proposal = researchProposals[proposalId];
        require(proposal.status == ProposalStatus.Voting, "Proposal is not in Voting status");
        require(block.timestamp >= proposal.votingStartTime && block.timestamp <= proposal.votingEndTime, "Voting period is not active");
        require(proposal.votes[msg.sender] == 0, "Already voted"); // Simple check, quadratic voting requires more complex tracking

        uint256 votePower = msg.value; // Simulate quadratic voting - more ETH sent = more vote power (simplified)
        proposal.votes[msg.sender] = votePower; // Store vote power
        if (support) {
            proposal.positiveVotes += votePower;
        } else {
            proposal.negativeVotes += votePower;
        }
        emit ResearchProposalVoted(proposalId, msg.sender, support);
    }

    /// @dev Finalizes a research proposal after voting period ends and conditions are met.
    /// @param proposalId ID of the research proposal to finalize.
    function finalizeResearchProposal(uint256 proposalId) external onlyGovernance proposalExists(proposalId) notPaused {
        ResearchProposal storage proposal = researchProposals[proposalId];
        require(proposal.status == ProposalStatus.Voting, "Proposal is not in Voting status");
        require(block.timestamp > proposal.votingEndTime, "Voting period is not over");

        if (proposal.positiveVotes > proposal.negativeVotes && proposal.currentFunding >= proposal.fundingGoal) {
            proposal.status = ProposalStatus.Funded; // Or Active, depending on workflow
            emit ResearchProposalFinalized(proposalId, proposal.currentFunding);
        } else {
            proposal.status = ProposalStatus.Cancelled; // Or Rejected, depending on workflow
            // Refund funders (complex logic, omitted for brevity, requires tracking funders and amounts)
            proposal.currentFunding = 0; // Reset funding if cancelled
            emit ResearchProposalFinalized(proposalId, 0); // Indicate cancelled and refunded (implicitly)
        }
    }

    /// @dev Researcher requests payment for a completed milestone.
    /// @param proposalId ID of the research proposal.
    /// @param milestoneDescription Description of the milestone completed.
    /// @param evidenceIpfsHash IPFS hash providing evidence of milestone completion.
    function requestMilestonePayment(uint256 proposalId, string memory milestoneDescription, string memory evidenceIpfsHash) external onlyResearcher(proposalId) proposalExists(proposalId) notPaused {
        ResearchProposal storage proposal = researchProposals[proposalId];
        require(proposal.status == ProposalStatus.Funded || proposal.status == ProposalStatus.Active, "Proposal must be Funded or Active");

        proposalMilestones[proposalId].push(Milestone({
            description: milestoneDescription,
            evidenceIpfsHash: evidenceIpfsHash,
            approved: false,
            paid: false
        }));
        emit MilestonePaymentRequested(proposalId, proposalMilestones[proposalId].length - 1, milestoneDescription);
    }

    /// @dev Governance members approve a milestone payment request.
    /// @param proposalId ID of the research proposal.
    function approveMilestonePayment(uint256 proposalId) external onlyGovernance proposalExists(proposalId) notPaused {
        require(proposalMilestones[proposalId].length > 0, "No milestones to approve");
        Milestone storage lastMilestone = proposalMilestones[proposalId][proposalMilestones[proposalId].length - 1];
        require(!lastMilestone.approved, "Milestone already approved");
        lastMilestone.approved = true;
        emit MilestonePaymentApproved(proposalId, proposalMilestones[proposalId].length - 1);
    }

    /// @dev Researcher withdraws funds for approved milestones.
    /// @param proposalId ID of the research proposal.
    function withdrawProposalFunds(uint256 proposalId) external onlyResearcher(proposalId) proposalExists(proposalId) notPaused {
        ResearchProposal storage proposal = researchProposals[proposalId];
        require(proposal.status == ProposalStatus.Funded || proposal.status == ProposalStatus.Active, "Proposal must be Funded or Active");

        uint256 withdrawableAmount = 0;
        for (uint i = 0; i < proposalMilestones[proposalId].length; i++) {
            Milestone storage milestone = proposalMilestones[proposalId][i];
            if (milestone.approved && !milestone.paid) {
                // Simple milestone payout logic - could be percentage based or fixed amounts per milestone
                withdrawableAmount += proposal.fundingGoal / 5; // Example: 5 milestones, equal payout per milestone
                milestone.paid = true;
            }
        }
        require(withdrawableAmount > 0 && proposal.currentFunding >= withdrawableAmount, "No funds to withdraw or insufficient proposal funding");

        (bool success, ) = payable(msg.sender).call{value: withdrawableAmount}("");
        require(success, "Withdrawal failed");
        proposal.currentFunding -= withdrawableAmount; // Reduce proposal funding balance
        emit FundsWithdrawn(proposalId, msg.sender, withdrawableAmount);
    }

    /// @dev Governance can cancel a research proposal (e.g., due to lack of progress, disputes).
    /// @param proposalId ID of the research proposal to cancel.
    function cancelResearchProposal(uint256 proposalId) external onlyGovernance proposalExists(proposalId) notPaused {
        ResearchProposal storage proposal = researchProposals[proposalId];
        require(proposal.status != ProposalStatus.Cancelled && proposal.status != ProposalStatus.Completed, "Proposal already cancelled or completed");
        proposal.status = ProposalStatus.Cancelled;
        // Logic to handle refunds to funders (similar to finalizeResearchProposal, omitted for brevity)
        proposal.currentFunding = 0; // Reset funding
    }


    // -------- Researcher Reputation & Data Management Functions --------

    /// @dev Researchers submit research data related to a proposal.
    /// @param proposalId ID of the research proposal.
    /// @param dataDescription Description of the submitted data.
    /// @param ipfsDataHash IPFS hash pointing to the research data.
    function submitResearchData(uint256 proposalId, string memory dataDescription, string memory ipfsDataHash) external onlyResearcher(proposalId) proposalExists(proposalId) notPaused {
        ResearchProposal storage proposal = researchProposals[proposalId];
        require(proposal.status == ProposalStatus.Funded || proposal.status == ProposalStatus.Active || proposal.status == ProposalStatus.Completed, "Proposal must be Funded, Active or Completed");

        proposalResearchData[proposalId].push(ResearchData({
            description: dataDescription,
            ipfsDataHash: ipfsDataHash,
            researcher: msg.sender,
            timestamp: block.timestamp,
            totalRatingScore: 0,
            reviewCount: 0
        }));
        emit ResearchDataSubmitted(proposalId, proposalResearchData[proposalId].length - 1, msg.sender, dataDescription);
    }

    /// @dev Governance members review and rate submitted research data.
    /// @param proposalId ID of the research proposal.
    /// @param reviewComment Comment on the research data.
    /// @param rating Rating for the data (0-10 scale).
    function reviewResearchData(uint256 proposalId, string memory reviewComment, uint8 rating) external onlyGovernance proposalExists(proposalId) notPaused {
        require(proposalResearchData[proposalId].length > 0, "No research data to review");
        ResearchData storage lastData = proposalResearchData[proposalId][proposalResearchData[proposalId].length - 1];
        require(lastData.reviews[msg.sender] == 0, "Already reviewed this data");
        require(rating >= 0 && rating <= 10, "Rating must be between 0 and 10");

        lastData.reviews[msg.sender] = rating;
        lastData.totalRatingScore += rating;
        lastData.reviewCount++;

        // Update researcher reputation based on review (simplified reputation update)
        uint256 averageRating = lastData.totalRatingScore / lastData.reviewCount;
        researchers[lastData.researcher].reputationScore += averageRating; // Simple additive reputation, can be more sophisticated
        emit ReputationScoreUpdated(lastData.researcher, researchers[lastData.researcher].reputationScore);
        emit ResearchDataReviewed(proposalId, proposalResearchData[proposalId].length - 1, msg.sender, rating);
    }

    /// @dev Retrieves the reputation score of a researcher.
    /// @param researcherAddress Address of the researcher.
    /// @return reputation score of the researcher.
    function getResearcherReputation(address researcherAddress) external view returns (uint256) {
        return researchers[researcherAddress].reputationScore;
    }

    /// @dev Allows members to access research data for a specific proposal (simulated access control).
    /// @param proposalId ID of the research proposal.
    /// @return Array of IPFS hashes for research data (for demonstration, actual data retrieval would be off-chain from IPFS).
    function accessResearchData(uint256 proposalId) external view proposalExists(proposalId) returns (string[] memory) {
        require(researchers[msg.sender].isMember, "Must be a member to access research data");
        require(researchProposals[proposalId].status != ProposalStatus.Pending && researchProposals[proposalId].status != ProposalStatus.Voting, "Proposal must be past Pending/Voting to access data");

        string[] memory dataHashes = new string[](proposalResearchData[proposalId].length);
        for (uint i = 0; i < proposalResearchData[proposalId].length; i++) {
            dataHashes[i] = proposalResearchData[proposalId][i].ipfsDataHash;
        }
        return dataHashes;
    }


    // -------- Dispute Resolution & Emergency Functions --------

    /// @dev Allows members to raise a dispute regarding a research proposal.
    /// @param proposalId ID of the research proposal in dispute.
    /// @param disputeDescription Description of the dispute.
    function raiseDispute(uint256 proposalId, string memory disputeDescription) external onlyGovernance proposalExists(proposalId) notPaused {
        ResearchProposal storage proposal = researchProposals[proposalId];
        require(proposal.status != ProposalStatus.Dispute && proposal.status != ProposalStatus.Cancelled && proposal.status != ProposalStatus.Completed, "Proposal cannot be in Dispute, Cancelled or Completed status to raise a new dispute");
        proposal.status = ProposalStatus.Dispute;

        disputes.push(Dispute({
            id: disputeCounter++,
            proposalId: proposalId,
            description: disputeDescription,
            status: DisputeStatus.Open,
            votingStartTime: 0,
            votingEndTime: 0,
            positiveVotes: 0,
            negativeVotes: 0,
            resolved: false,
            resolution: false
        }));
        emit DisputeRaised(disputes.length - 1, proposalId, msg.sender);
    }

    /// @dev Starts voting for dispute resolution.
    /// @param disputeId ID of the dispute to resolve.
    function _startDisputeVoting(uint256 disputeId) internal disputeExists(disputeId) {
        Dispute storage dispute = disputes[disputeId];
        require(dispute.status == DisputeStatus.Open, "Dispute is not in Open status");
        dispute.status = DisputeStatus.Voting;
        dispute.votingStartTime = block.timestamp;
        dispute.votingEndTime = block.timestamp + disputeVotingDuration;
    }

    /// @dev Governance members vote to resolve a dispute.
    /// @param disputeId ID of the dispute to vote on.
    /// @param resolution True if resolving in favor of the dispute raiser, false otherwise.
    function resolveDispute(uint256 disputeId, bool resolution) external onlyGovernance disputeExists(disputeId) notPaused {
        Dispute storage dispute = disputes[disputeId];
        require(dispute.status == DisputeStatus.Open || dispute.status == DisputeStatus.Voting, "Dispute is not in Open or Voting status"); // Allow voting even if voting not explicitly started yet.
        if (dispute.status == DisputeStatus.Open) {
            _startDisputeVoting(disputeId); // Start voting if not started yet upon first vote.
        }
        require(block.timestamp >= dispute.votingStartTime && block.timestamp <= dispute.votingEndTime, "Dispute voting period is not active");
        require(!dispute.votes[msg.sender], "Already voted on this dispute");

        dispute.votes[msg.sender] = true;
        if (resolution) {
            dispute.positiveVotes++;
        } else {
            dispute.negativeVotes++;
        }

        if (block.timestamp > dispute.votingEndTime && dispute.status == DisputeStatus.Voting) { // Check if voting period ended
            if (dispute.positiveVotes > dispute.negativeVotes) {
                dispute.resolution = resolution; // Resolution set based on vote outcome
                dispute.status = DisputeStatus.Resolved;
                dispute.resolved = true;
                // Implement actions based on dispute resolution (e.g., proposal cancellation, fund redistribution) - omitted for brevity
                emit DisputeResolved(disputeId, resolution);
            } else {
                dispute.resolution = false; // Dispute not resolved in favor of raiser
                dispute.status = DisputeStatus.Resolved;
                dispute.resolved = true;
                emit DisputeResolved(disputeId, false);
            }
        }
    }


    /// @dev Governance admin can pause the contract in case of emergency.
    function pauseContract() external onlyGovernanceAdmin notPaused {
        paused = true;
        emit ContractPaused();
    }

    /// @dev Governance admin can unpause the contract.
    function unpauseContract() external onlyGovernanceAdmin {
        paused = false;
        emit ContractUnpaused();
    }

    // -------- Fallback and Receive (for funding) --------
    receive() external payable {
        // Optional: Handle direct ETH sent to contract (e.g., for general DARO funding, not tied to a specific proposal in this example)
    }

    fallback() external {}
}
```