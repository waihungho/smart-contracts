```solidity
/**
 * @title Decentralized Autonomous Research Organization (DARO) Smart Contract
 * @author Your Name or Organization Name
 * @notice This smart contract implements a Decentralized Autonomous Research Organization (DARO)
 *  that allows for collaborative research, proposal submissions, peer review, funding, and intellectual property management.
 *  It incorporates advanced concepts like:
 *      - Decentralized governance through voting with a custom governance token.
 *      - On-chain reputation system for members and reviewers.
 *      - Structured research proposal process with milestones.
 *      - Decentralized IP ownership and revenue sharing mechanisms.
 *      - Dynamic role-based access control.
 *      - Advanced data structures for managing complex research workflows.
 *      - On-chain dispute resolution mechanism.
 *
 * Function Summary:
 *  [Membership & Governance]
 *      1. joinDARO(): Allows users to become members of the DARO by staking governance tokens.
 *      2. leaveDARO(): Allows members to leave the DARO and unstake their tokens (with potential cooldown).
 *      3. delegateVote(): Allows members to delegate their voting power to another member.
 *      4. createGovernanceProposal(): Allows members to create proposals for DARO governance changes.
 *      5. voteOnGovernanceProposal(): Allows members to vote on active governance proposals.
 *      6. executeGovernanceProposal(): Executes a governance proposal if it passes quorum and threshold.
 *
 *  [Research Proposals & Funding]
 *      7. submitResearchProposal(): Allows members to submit research proposals with milestones and funding requests.
 *      8. reviewResearchProposal(): Allows designated reviewers to review and rate research proposals.
 *      9. voteOnResearchProposalFunding(): Allows members to vote on funding research proposals.
 *      10. fundResearchProposal(): Allows the DARO to allocate funds to approved research proposals.
 *      11. markMilestoneComplete(): Allows researchers to mark milestones as complete, triggering review.
 *      12. approveMilestoneCompletion(): Allows reviewers to approve completed milestones, releasing funds.
 *      13. reportResearchProgress(): Allows researchers to submit progress reports on their funded projects.
 *
 *  [Intellectual Property & Revenue Sharing]
 *      14. registerIP(): Allows researchers to register intellectual property generated from funded research.
 *      15. setRevenueSharingPercentage(): Allows researchers to set a revenue sharing percentage for their IP.
 *      16. distributeRevenue(): Allows the DARO to distribute revenue generated from IP to researchers and the DARO treasury.
 *
 *  [Reputation & Dispute Resolution]
 *      17. awardReputation(): Allows admins and potentially members to award reputation to other members.
 *      18. penalizeReputation(): Allows admins to penalize reputation for misconduct.
 *      19. initiateDispute(): Allows members to initiate a dispute regarding research or governance.
 *      20. voteOnDisputeResolution(): Allows members to vote on resolutions for active disputes.
 *
 *  [Utility & Admin Functions]
 *      21. getProposalDetails(): Retrieves detailed information about a specific research proposal.
 *      22. getMemberDetails(): Retrieves details about a specific DARO member.
 *      23. getDAROBalance(): Returns the current balance of the DARO contract in governance tokens.
 *      24. emergencyWithdraw(): (Admin only) Allows emergency withdrawal of funds in case of critical issues.
 *      25. pauseContract(): (Admin only) Pauses critical contract functionalities.
 *      26. unpauseContract(): (Admin only) Resumes paused functionalities.
 *      27. setQuorum(): (Admin only) Sets the quorum for governance and research proposal voting.
 *      28. setVotingPeriod(): (Admin only) Sets the voting period for proposals.
 *      29. setReviewers(): (Admin only) Designates members as reviewers for research proposals.
 *      30. changeGovernanceToken(): (Admin only) Allows changing the governance token address (careful!).
 */
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

contract DARO is Ownable, Pausable {
    using SafeMath for uint256;
    using EnumerableSet for EnumerableSet.AddressSet;

    // --- Structs and Enums ---

    enum ProposalStatus { PendingReview, UnderVoting, Funded, InProgress, MilestoneReview, Completed, Rejected, Dispute }
    enum GovernanceProposalType { ParameterChange, RuleChange, MembershipAction, ContractUpgrade }
    enum DisputeStatus { Open, Voting, Resolved }
    enum VoteType { Approve, Reject }

    struct Member {
        address memberAddress;
        uint256 reputationScore;
        uint256 joinTimestamp;
        address delegatedVoteTo;
        bool isActive;
    }

    struct ResearchProposal {
        uint256 proposalId;
        address proposer;
        string title;
        string description;
        uint256 fundingGoal;
        Milestone[] milestones;
        ProposalStatus status;
        uint256 reviewDeadline;
        uint256 votingDeadline;
        mapping(address => VoteType) votes; // Member address => Vote
        uint256 approveVotesCount;
        uint256 rejectVotesCount;
        Review[] reviews;
        uint256 fundingAllocated;
        uint256 ipRegistrationId; // ID for registered Intellectual Property
    }

    struct GovernanceProposal {
        uint256 proposalId;
        GovernanceProposalType proposalType;
        string description;
        bytes proposalData; // Encoded data for parameter changes or contract calls
        uint256 votingDeadline;
        mapping(address => VoteType) votes; // Member address => Vote
        uint256 approveVotesCount;
        uint256 rejectVotesCount;
        bool executed;
    }

    struct Milestone {
        string description;
        uint256 fundingAmount;
        bool isComplete;
        bool isApproved;
        uint256 reviewDeadline;
    }

    struct Review {
        address reviewer;
        uint8 rating; // e.g., 1-5 star rating
        string comment;
        uint256 reviewTimestamp;
    }

    struct IntellectualProperty {
        uint256 registrationId;
        uint256 proposalId;
        address researcher;
        string ipDescription;
        uint256 revenueSharingPercentage; // Percentage for researcher, rest for DARO
        uint256 totalRevenueGenerated;
    }

    struct Dispute {
        uint256 disputeId;
        address initiator;
        string description;
        DisputeStatus status;
        uint256 votingDeadline;
        mapping(address => VoteType) votes; // Member address => Vote
        uint256 approveVotesCount;
        uint256 rejectVotesCount;
        string resolutionDetails;
    }


    // --- State Variables ---

    IERC20 public governanceToken;
    uint256 public stakingAmountForMembership;
    uint256 public membershipCooldownPeriod;
    uint256 public proposalReviewPeriod;
    uint256 public proposalVotingPeriod;
    uint256 public governanceVotingPeriod;
    uint256 public disputeVotingPeriod;
    uint256 public quorumPercentage = 50; // Percentage for quorum in voting
    uint256 public proposalApprovalThresholdPercentage = 60; // Percentage for proposal approval
    uint256 public governanceApprovalThresholdPercentage = 70; // Higher threshold for governance changes
    uint256 public disputeResolutionThresholdPercentage = 60;

    mapping(address => Member) public members;
    EnumerableSet.AddressSet private _activeMembers;
    uint256 public memberCount = 0;

    mapping(uint256 => ResearchProposal) public researchProposals;
    uint256 public proposalCount = 0;

    mapping(uint256 => GovernanceProposal) public governanceProposals;
    uint256 public governanceProposalCount = 0;

    mapping(uint256 => IntellectualProperty) public registeredIPs;
    uint256 public ipRegistrationCount = 0;

    mapping(uint256 => Dispute) public disputes;
    uint256 public disputeCount = 0;

    EnumerableSet.AddressSet private _reviewers;
    uint256 public reviewerCount = 0;

    uint256 public reputationAwardAmount = 10;
    uint256 public reputationPenaltyAmount = 20;

    uint256 public daroTreasuryBalance = 0; // Track DARO's token balance from revenue sharing

    // --- Events ---

    event MemberJoined(address memberAddress);
    event MemberLeft(address memberAddress);
    event VoteDelegated(address delegator, address delegatee);
    event GovernanceProposalCreated(uint256 proposalId, GovernanceProposalType proposalType, string description);
    event GovernanceProposalVoted(uint256 proposalId, address voter, VoteType vote);
    event GovernanceProposalExecuted(uint256 proposalId);

    event ResearchProposalSubmitted(uint256 proposalId, address proposer, string title);
    event ResearchProposalReviewed(uint256 proposalId, address reviewer, uint8 rating);
    event ResearchProposalFundingVoted(uint256 proposalId, address voter, VoteType vote);
    event ResearchProposalFunded(uint256 proposalId, uint256 fundingAmount);
    event MilestoneMarkedComplete(uint256 proposalId, uint256 milestoneIndex);
    event MilestoneApproved(uint256 proposalId, uint256 milestoneIndex);
    event ResearchProgressReported(uint256 proposalId, string report);
    event ResearchProposalStatusUpdated(uint256 proposalId, ProposalStatus newStatus);

    event IPRegistered(uint256 registrationId, uint256 proposalId, address researcher, string ipDescription);
    event RevenueSharingPercentageSet(uint256 registrationId, uint256 percentage);
    event RevenueDistributed(uint256 registrationId, uint256 researcherRevenue, uint256 daroRevenue);

    event ReputationAwarded(address member, uint256 amount);
    event ReputationPenalized(address member, uint256 amount);

    event DisputeInitiated(uint256 disputeId, address initiator, string description);
    event DisputeResolutionVoted(uint256 disputeId, address voter, VoteType vote, string resolutionDetails);
    event DisputeResolved(uint256 disputeId, DisputeStatus status, string resolutionDetails);

    event ContractPaused(address admin);
    event ContractUnpaused(address admin);
    event EmergencyWithdrawal(address admin, uint256 amount);

    // --- Modifiers ---

    modifier onlyMember() {
        require(isMember(msg.sender), "Not a DARO member");
        _;
    }

    modifier onlyReviewer() {
        require(isReviewer(msg.sender), "Not a designated reviewer");
        _;
    }

    modifier onlyProposalStatus(uint256 _proposalId, ProposalStatus _status) {
        require(researchProposals[_proposalId].status == _status, "Proposal status not as expected");
        _;
    }

    modifier onlyGovernanceProposalStatus(uint256 _proposalId, ProposalStatus _status) { // Reusing ProposalStatus enum for simplicity, could be dedicated GovernanceProposalStatus
        require(governanceProposals[_proposalId].status == _status, "Governance proposal status not as expected");
        _;
    }

    modifier onlyDisputeStatus(uint256 _disputeId, DisputeStatus _status) {
        require(disputes[_disputeId].status == _status, "Dispute status not as expected");
        _;
    }

    modifier validProposalId(uint256 _proposalId) {
        require(_proposalId > 0 && _proposalId <= proposalCount, "Invalid proposal ID");
        _;
    }

    modifier validGovernanceProposalId(uint256 _proposalId) {
        require(_proposalId > 0 && _proposalId <= governanceProposalCount, "Invalid governance proposal ID");
        _;
    }

    modifier validDisputeId(uint256 _disputeId) {
        require(_disputeId > 0 && _disputeId <= disputeCount, "Invalid dispute ID");
        _;
    }

    modifier votingPeriodActive(uint256 _deadline) {
        require(block.timestamp < _deadline, "Voting period has ended");
        _;
    }

    modifier reviewPeriodActive(uint256 _deadline) {
        require(block.timestamp < _deadline, "Review period has ended");
        _;
    }

    // --- Constructor ---
    constructor(address _governanceTokenAddress, uint256 _stakingAmount, uint256 _membershipCooldown, uint256 _reviewPeriod, uint256 _votingPeriod, uint256 _governanceVotingPeriodDuration, uint256 _disputeVotingDuration) payable {
        governanceToken = IERC20(_governanceTokenAddress);
        stakingAmountForMembership = _stakingAmount;
        membershipCooldownPeriod = _membershipCooldown;
        proposalReviewPeriod = _reviewPeriod;
        proposalVotingPeriod = _votingPeriod;
        governanceVotingPeriod = _governanceVotingPeriodDuration;
        disputeVotingPeriod = _disputeVotingDuration;
    }

    // --- Membership & Governance Functions ---

    function joinDARO() external payable whenNotPaused {
        require(!isMember(msg.sender), "Already a member");
        require(governanceToken.allowance(msg.sender, address(this)) >= stakingAmountForMembership, "Insufficient token allowance for staking");

        governanceToken.transferFrom(msg.sender, address(this), stakingAmountForMembership);

        members[msg.sender] = Member({
            memberAddress: msg.sender,
            reputationScore: 0,
            joinTimestamp: block.timestamp,
            delegatedVoteTo: address(0),
            isActive: true
        });
        _activeMembers.add(msg.sender);
        memberCount++;
        emit MemberJoined(msg.sender);
    }

    function leaveDARO() external onlyMember whenNotPaused {
        require(block.timestamp >= members[msg.sender].joinTimestamp + membershipCooldownPeriod, "Membership cooldown period not over yet");

        governanceToken.transfer(msg.sender, stakingAmountForMembership);
        members[msg.sender].isActive = false;
        _activeMembers.remove(msg.sender);
        memberCount--;
        emit MemberLeft(msg.sender);
    }

    function delegateVote(address _delegatee) external onlyMember whenNotPaused {
        require(isMember(_delegatee), "Delegatee is not a DARO member");
        require(_delegatee != msg.sender, "Cannot delegate vote to yourself");

        members[msg.sender].delegatedVoteTo = _delegatee;
        emit VoteDelegated(msg.sender, _delegatee);
    }

    function createGovernanceProposal(GovernanceProposalType _proposalType, string memory _description, bytes memory _proposalData) external onlyMember whenNotPaused {
        governanceProposalCount++;
        governanceProposals[governanceProposalCount] = GovernanceProposal({
            proposalId: governanceProposalCount,
            proposalType: _proposalType,
            description: _description,
            proposalData: _proposalData,
            votingDeadline: block.timestamp + governanceVotingPeriod,
            approveVotesCount: 0,
            rejectVotesCount: 0,
            executed: false
        });
        emit GovernanceProposalCreated(governanceProposalCount, _proposalType, _description);
    }

    function voteOnGovernanceProposal(uint256 _proposalId, VoteType _vote) external onlyMember validGovernanceProposalId votingPeriodActive(governanceProposals[_proposalId].votingDeadline) whenNotPaused {
        require(governanceProposals[_proposalId].votes[msg.sender] == VoteType.Reject || governanceProposals[_proposalId].votes[msg.sender] == VoteType.Approve || governanceProposals[_proposalId].votes[msg.sender] == VoteType(0), "Already voted on this proposal"); // VoteType(0) is default value for not voted

        governanceProposals[_proposalId].votes[msg.sender] = _vote;
        if (_vote == VoteType.Approve) {
            governanceProposals[_proposalId].approveVotesCount++;
        } else {
            governanceProposals[_proposalId].rejectVotesCount++;
        }
        emit GovernanceProposalVoted(_proposalId, msg.sender, _vote);
    }

    function executeGovernanceProposal(uint256 _proposalId) external validGovernanceProposalId onlyGovernanceProposalStatus(_proposalId, ProposalStatus.UnderVoting) whenNotPaused { // Reusing ProposalStatus enum for simplicity
        require(block.timestamp >= governanceProposals[_proposalId].votingDeadline, "Voting period not ended yet");
        require(!governanceProposals[_proposalId].executed, "Governance proposal already executed");

        uint256 totalActiveMembers = _activeMembers.length();
        uint256 quorum = (totalActiveMembers * quorumPercentage) / 100;
        uint256 approvalThreshold = (quorum * governanceApprovalThresholdPercentage) / 100; // Approval threshold based on quorum

        require(governanceProposals[_proposalId].approveVotesCount >= approvalThreshold, "Governance proposal did not reach approval threshold");
        require(EnumerableSet.length(_activeMembers) >= quorum, "Governance proposal did not reach quorum");


        governanceProposals[_proposalId].executed = true;
        // --- Implement proposal execution logic based on proposalType and proposalData ---
        if (governanceProposals[_proposalId].proposalType == GovernanceProposalType.ParameterChange) {
            // Decode proposalData and implement parameter changes (e.g., quorumPercentage, votingPeriod)
            // This would require careful encoding/decoding of data and specific logic for each parameter
            // Example (very simplified and needs proper encoding/decoding in real implementation):
            // (string memory parameterName, uint256 newValue) = abi.decode(governanceProposals[_proposalId].proposalData, (string, uint256));
            // if (keccak256(abi.encodePacked(parameterName)) == keccak256(abi.encodePacked("quorumPercentage"))) {
            //     quorumPercentage = newValue;
            // } // ... handle other parameters similarly
        } else if (governanceProposals[_proposalId].proposalType == GovernanceProposalType.RuleChange) {
            // Implement logic for rule changes based on description and potentially proposalData
            // This might involve more complex on-chain or off-chain actions depending on the rules.
        } else if (governanceProposals[_proposalId].proposalType == GovernanceProposalType.MembershipAction) {
            // Implement logic for membership actions like removing a member (needs careful consideration and voting process)
            // (address memberToRemove) = abi.decode(governanceProposals[_proposalId].proposalData, (address));
            // removeMember(memberToRemove); // Example function (not implemented here, needs careful design)
        } else if (governanceProposals[_proposalId].proposalType == GovernanceProposalType.ContractUpgrade) {
            // Logic for contract upgrade (using proxy patterns or similar - complex and beyond basic example)
            // This is a very advanced topic and requires secure upgrade mechanisms.
        }

        emit GovernanceProposalExecuted(_proposalId);
    }

    // --- Research Proposals & Funding Functions ---

    function submitResearchProposal(string memory _title, string memory _description, uint256 _fundingGoal, Milestone[] memory _milestones) external onlyMember whenNotPaused {
        require(bytes(_title).length > 0 && bytes(_description).length > 0, "Title and description cannot be empty");
        require(_fundingGoal > 0, "Funding goal must be greater than zero");
        require(_milestones.length > 0, "At least one milestone is required");

        proposalCount++;
        researchProposals[proposalCount] = ResearchProposal({
            proposalId: proposalCount,
            proposer: msg.sender,
            title: _title,
            description: _description,
            fundingGoal: _fundingGoal,
            milestones: _milestones,
            status: ProposalStatus.PendingReview,
            reviewDeadline: block.timestamp + proposalReviewPeriod,
            votingDeadline: 0, // Set during review process
            approveVotesCount: 0,
            rejectVotesCount: 0,
            fundingAllocated: 0,
            ipRegistrationId: 0
        });

        emit ResearchProposalSubmitted(proposalCount, msg.sender, _title);
        emit ResearchProposalStatusUpdated(proposalCount, ProposalStatus.PendingReview);
    }

    function reviewResearchProposal(uint256 _proposalId, uint8 _rating, string memory _comment) external onlyReviewer validProposalId onlyProposalStatus(_proposalId, ProposalStatus.PendingReview) reviewPeriodActive(researchProposals[_proposalId].reviewDeadline) whenNotPaused {
        require(_rating >= 1 && _rating <= 5, "Rating must be between 1 and 5"); // Example rating scale

        researchProposals[_proposalId].reviews.push(Review({
            reviewer: msg.sender,
            rating: _rating,
            comment: _comment,
            reviewTimestamp: block.timestamp
        }));

        emit ResearchProposalReviewed(_proposalId, msg.sender, _rating);

        // Basic logic to move to voting after first review (can be adjusted for multiple reviews, average rating etc.)
        if (researchProposals[_proposalId].reviews.length >= 1) { // Example: Move to voting after one review
            researchProposals[_proposalId].status = ProposalStatus.UnderVoting;
            researchProposals[_proposalId].votingDeadline = block.timestamp + proposalVotingPeriod;
            emit ResearchProposalStatusUpdated(_proposalId, ProposalStatus.UnderVoting);
        }
    }

    function voteOnResearchProposalFunding(uint256 _proposalId, VoteType _vote) external onlyMember validProposalId onlyProposalStatus(_proposalId, ProposalStatus.UnderVoting) votingPeriodActive(researchProposals[_proposalId].votingDeadline) whenNotPaused {
        require(researchProposals[_proposalId].votes[msg.sender] == VoteType.Reject || researchProposals[_proposalId].votes[msg.sender] == VoteType.Approve || researchProposals[_proposalId].votes[msg.sender] == VoteType(0), "Already voted on this proposal"); // VoteType(0) is default value for not voted

        researchProposals[_proposalId].votes[msg.sender] = _vote;
        if (_vote == VoteType.Approve) {
            researchProposals[_proposalId].approveVotesCount++;
        } else {
            researchProposals[_proposalId].rejectVotesCount++;
        }
        emit ResearchProposalFundingVoted(_proposalId, msg.sender, _vote);
    }

    function fundResearchProposal(uint256 _proposalId) external validProposalId onlyProposalStatus(_proposalId, ProposalStatus.UnderVoting) whenNotPaused {
        require(block.timestamp >= researchProposals[_proposalId].votingDeadline, "Voting period not ended yet");

        uint256 totalActiveMembers = _activeMembers.length();
        uint256 quorum = (totalActiveMembers * quorumPercentage) / 100;
        uint256 approvalThreshold = (quorum * proposalApprovalThresholdPercentage) / 100; // Proposal approval threshold

        require(researchProposals[_proposalId].approveVotesCount >= approvalThreshold, "Research proposal did not reach approval threshold");
        require(EnumerableSet.length(_activeMembers) >= quorum, "Research proposal did not reach quorum");

        require(address(this).balance >= researchProposals[_proposalId].fundingGoal, "Contract balance insufficient to fund proposal"); // Check contract ETH balance for funding (assuming ETH for funding for simplicity)

        payable(researchProposals[_proposalId].proposer).transfer(researchProposals[_proposalId].fundingGoal); // Transfer ETH to proposer (replace with token transfer if funding in governance tokens, requires token balance check)
        researchProposals[_proposalId].status = ProposalStatus.Funded;
        researchProposals[_proposalId].fundingAllocated = researchProposals[_proposalId].fundingGoal;
        emit ResearchProposalFunded(_proposalId, researchProposals[_proposalId].fundingGoal);
        emit ResearchProposalStatusUpdated(_proposalId, ProposalStatus.Funded);
    }

    function markMilestoneComplete(uint256 _proposalId, uint256 _milestoneIndex) external onlyMember validProposalId onlyProposalStatus(_proposalId, ProposalStatus.Funded) whenNotPaused {
        require(msg.sender == researchProposals[_proposalId].proposer, "Only proposer can mark milestones complete");
        require(_milestoneIndex < researchProposals[_proposalId].milestones.length, "Invalid milestone index");
        require(!researchProposals[_proposalId].milestones[_milestoneIndex].isComplete, "Milestone already marked as complete");

        researchProposals[_proposalId].milestones[_milestoneIndex].isComplete = true;
        researchProposals[_proposalId].milestones[_milestoneIndex].reviewDeadline = block.timestamp + proposalReviewPeriod; // Set review deadline for milestone approval
        researchProposals[_proposalId].status = ProposalStatus.MilestoneReview;
        emit MilestoneMarkedComplete(_proposalId, _milestoneIndex);
        emit ResearchProposalStatusUpdated(_proposalId, ProposalStatus.MilestoneReview);
    }

    function approveMilestoneCompletion(uint256 _proposalId, uint256 _milestoneIndex) external onlyReviewer validProposalId onlyProposalStatus(_proposalId, ProposalStatus.MilestoneReview) reviewPeriodActive(researchProposals[_proposalId].milestones[_milestoneIndex].reviewDeadline) whenNotPaused {
        require(_milestoneIndex < researchProposals[_proposalId].milestones.length, "Invalid milestone index");
        require(researchProposals[_proposalId].milestones[_milestoneIndex].isComplete, "Milestone not marked as complete");
        require(!researchProposals[_proposalId].milestones[_milestoneIndex].isApproved, "Milestone already approved");

        researchProposals[_proposalId].milestones[_milestoneIndex].isApproved = true;
        uint256 milestoneFunding = researchProposals[_proposalId].milestones[_milestoneIndex].fundingAmount;

        require(address(this).balance >= milestoneFunding, "Contract balance insufficient to fund milestone"); // Check contract ETH balance for milestone funding (assuming ETH for funding for simplicity)
        payable(researchProposals[_proposalId].proposer).transfer(milestoneFunding); // Transfer ETH to proposer for milestone (replace with token transfer if funding in governance tokens, requires token balance check)

        emit MilestoneApproved(_proposalId, _milestoneIndex);

        bool allMilestonesApproved = true;
        for (uint256 i = 0; i < researchProposals[_proposalId].milestones.length; i++) {
            if (!researchProposals[_proposalId].milestones[i].isApproved) {
                allMilestonesApproved = false;
                break;
            }
        }

        if (allMilestonesApproved) {
            researchProposals[_proposalId].status = ProposalStatus.Completed;
            emit ResearchProposalStatusUpdated(_proposalId, ProposalStatus.Completed);
        } else {
            researchProposals[_proposalId].status = ProposalStatus.InProgress; // Or back to Funded if not all milestones approved yet but some are
            emit ResearchProposalStatusUpdated(_proposalId, ProposalStatus.InProgress);
        }
    }

    function reportResearchProgress(uint256 _proposalId, string memory _report) external onlyMember validProposalId onlyProposalStatus(_proposalId, ProposalStatus.InProgress) whenNotPaused {
        require(msg.sender == researchProposals[_proposalId].proposer, "Only proposer can submit progress reports");
        require(bytes(_report).length > 0, "Report cannot be empty");

        // Store report on-chain (e.g., as part of proposal struct or separate event - for simplicity, just emit event for now)
        emit ResearchProgressReported(_proposalId, _report);
    }

    // --- Intellectual Property & Revenue Sharing Functions ---

    function registerIP(uint256 _proposalId, string memory _ipDescription) external onlyMember validProposalId onlyProposalStatus(_proposalId, ProposalStatus.Completed) whenNotPaused {
        require(msg.sender == researchProposals[_proposalId].proposer, "Only proposer can register IP for their proposal");
        require(researchProposals[_proposalId].ipRegistrationId == 0, "IP already registered for this proposal"); // Prevent double registration
        require(bytes(_ipDescription).length > 0, "IP description cannot be empty");

        ipRegistrationCount++;
        registeredIPs[ipRegistrationCount] = IntellectualProperty({
            registrationId: ipRegistrationCount,
            proposalId: _proposalId,
            researcher: msg.sender,
            ipDescription: _ipDescription,
            revenueSharingPercentage: 0, // Default to 0, researcher needs to set it
            totalRevenueGenerated: 0
        });
        researchProposals[_proposalId].ipRegistrationId = ipRegistrationCount;

        emit IPRegistered(ipRegistrationCount, _proposalId, msg.sender, _ipDescription);
    }

    function setRevenueSharingPercentage(uint256 _registrationId, uint256 _percentage) external onlyMember whenNotPaused {
        require(registeredIPs[_registrationId].researcher == msg.sender, "Only researcher who registered IP can set percentage");
        require(_percentage <= 100, "Percentage cannot exceed 100");
        require(registeredIPs[_registrationId].revenueSharingPercentage == 0, "Revenue sharing percentage already set"); // Prevent re-setting

        registeredIPs[_registrationId].revenueSharingPercentage = _percentage;
        emit RevenueSharingPercentageSet(_registrationId, _percentage);
    }

    function distributeRevenue(uint256 _registrationId, uint256 _revenueAmount) external onlyOwner whenNotPaused { // Example: Admin triggers revenue distribution when revenue is received off-chain
        require(_revenueAmount > 0, "Revenue amount must be greater than zero");
        require(registeredIPs[_registrationId].revenueSharingPercentage > 0, "Revenue sharing percentage not set yet");

        uint256 researcherShare = (_revenueAmount * registeredIPs[_registrationId].revenueSharingPercentage) / 100;
        uint256 daroShare = _revenueAmount - researcherShare;

        // For simplicity, assuming revenue distribution happens in ETH. In real-world, might be other tokens.
        // This example assumes contract has received the revenue off-chain (e.g., through sales or licensing).
        // In a more advanced scenario, revenue could be streamed directly to the contract.

        payable(registeredIPs[_registrationId].researcher).transfer(researcherShare); // Transfer to researcher in ETH (replace with token transfer if needed)
        daroTreasuryBalance = daroTreasuryBalance + daroShare; // Track DARO's share

        registeredIPs[_registrationId].totalRevenueGenerated = registeredIPs[_registrationId].totalRevenueGenerated + _revenueAmount;
        emit RevenueDistributed(_registrationId, researcherShare, daroShare);
    }

    // --- Reputation & Dispute Resolution Functions ---

    function awardReputation(address _member, uint256 _amount) external onlyOwner whenNotPaused { // Admin controlled reputation for initial stage, can be decentralized later
        require(isMember(_member), "Recipient is not a DARO member");

        members[_member].reputationScore = members[_member].reputationScore + _amount;
        emit ReputationAwarded(_member, _amount);
    }

    function penalizeReputation(address _member, uint256 _amount) external onlyOwner whenNotPaused { // Admin controlled penalty for initial stage, can be decentralized later
        require(isMember(_member), "Recipient is not a DARO member");
        require(members[_member].reputationScore >= _amount, "Reputation score is too low to penalize"); // Prevent negative reputation

        members[_member].reputationScore = members[_member].reputationScore - _amount;
        emit ReputationPenalized(_member, _amount);
    }

    function initiateDispute(string memory _description) external onlyMember whenNotPaused {
        require(bytes(_description).length > 0, "Dispute description cannot be empty");

        disputeCount++;
        disputes[disputeCount] = Dispute({
            disputeId: disputeCount,
            initiator: msg.sender,
            description: _description,
            status: DisputeStatus.Open,
            votingDeadline: block.timestamp + disputeVotingPeriod,
            approveVotesCount: 0,
            rejectVotesCount: 0,
            resolutionDetails: ""
        });
        emit DisputeInitiated(disputeCount, msg.sender, _description);
        disputes[disputeCount].status = DisputeStatus.Voting; // Move to voting immediately
    }

    function voteOnDisputeResolution(uint256 _disputeId, VoteType _vote, string memory _resolutionDetails) external onlyMember validDisputeId onlyDisputeStatus(_disputeId, DisputeStatus.Voting) votingPeriodActive(disputes[_disputeId].votingDeadline) whenNotPaused {
        require(disputes[_disputeId].votes[msg.sender] == VoteType.Reject || disputes[_disputeId].votes[msg.sender] == VoteType.Approve || disputes[_disputeId].votes[msg.sender] == VoteType(0), "Already voted on this dispute"); // VoteType(0) is default value for not voted

        disputes[_disputeId].votes[msg.sender] = _vote;
        if (_vote == VoteType.Approve) {
            disputes[_disputeId].approveVotesCount++;
        } else {
            disputes[_disputeId].rejectVotesCount++;
        }
        emit DisputeResolutionVoted(_disputeId, msg.sender, _vote, _resolutionDetails);
    }

    function resolveDispute(uint256 _disputeId) external validDisputeId onlyDisputeStatus(_disputeId, DisputeStatus.Voting) whenNotPaused {
        require(block.timestamp >= disputes[_disputeId].votingDeadline, "Dispute voting period not ended yet");

        uint256 totalActiveMembers = _activeMembers.length();
        uint256 quorum = (totalActiveMembers * quorumPercentage) / 100;
        uint256 resolutionThreshold = (quorum * disputeResolutionThresholdPercentage) / 100; // Dispute resolution threshold

        require(disputes[_disputeId].approveVotesCount >= resolutionThreshold, "Dispute resolution did not reach approval threshold");
        require(EnumerableSet.length(_activeMembers) >= quorum, "Dispute resolution did not reach quorum");

        disputes[_disputeId].status = DisputeStatus.Resolved;
        disputes[_disputeId].resolutionDetails = "Dispute resolved through community vote."; // Example resolution, can be more detailed based on vote and resolutionDetails input in voting function
        emit DisputeResolved(_disputeId, DisputeStatus.Resolved, disputes[_disputeId].resolutionDetails);
    }

    // --- Utility & Admin Functions ---

    function getProposalDetails(uint256 _proposalId) external view validProposalId returns (ResearchProposal memory) {
        return researchProposals[_proposalId];
    }

    function getMemberDetails(address _memberAddress) external view returns (Member memory) {
        return members[_memberAddress];
    }

    function getDAROBalance() external view returns (uint256) {
        return address(this).balance; // Returns ETH balance of contract (adjust if governance token balance is needed)
    }

    function emergencyWithdraw(uint256 _amount) external onlyOwner whenPaused {
        require(address(this).balance >= _amount, "Insufficient contract balance for withdrawal");
        payable(owner()).transfer(_amount);
        emit EmergencyWithdrawal(owner(), _amount);
    }

    function pauseContract() external onlyOwner {
        _pause();
        emit ContractPaused(owner());
    }

    function unpauseContract() external onlyOwner {
        _unpause();
        emit ContractUnpaused(owner());
    }

    function setQuorum(uint256 _quorumPercentage) external onlyOwner {
        require(_quorumPercentage >= 1 && _quorumPercentage <= 100, "Quorum percentage must be between 1 and 100");
        quorumPercentage = _quorumPercentage;
    }

    function setVotingPeriod(uint256 _votingPeriodSeconds) external onlyOwner {
        proposalVotingPeriod = _votingPeriodSeconds;
    }

    function setReviewers(address[] memory _reviewersAddresses) external onlyOwner {
        // Clear existing reviewers
        while (_reviewers.length() > 0) {
            _reviewers.pop();
        }
        reviewerCount = 0;

        // Add new reviewers
        for (uint256 i = 0; i < _reviewersAddresses.length; i++) {
            _reviewers.add(_reviewersAddresses[i]);
            reviewerCount++;
        }
    }

    function changeGovernanceToken(address _newGovernanceTokenAddress) external onlyOwner {
        require(_newGovernanceTokenAddress != address(0), "Invalid governance token address");
        governanceToken = IERC20(_newGovernanceTokenAddress);
        // Consider migration logic for existing staked tokens if needed in a real-world scenario.
    }

    // --- Helper Functions ---

    function isMember(address _address) public view returns (bool) {
        return _activeMembers.contains(_address) && members[_address].isActive;
    }

    function isReviewer(address _address) public view returns (bool) {
        return _reviewers.contains(_address);
    }

    function getActiveMemberCount() public view returns (uint256) {
        return _activeMembers.length();
    }

    function getReviewerCount() public view returns (uint256) {
        return _reviewers.length();
    }
}
```