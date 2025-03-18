```solidity
/**
 * @title Decentralized Autonomous Organization (DAO) for Impact Investing - "ImpactDAO"
 * @author Bard (AI Assistant)
 * @dev A sophisticated DAO smart contract designed for impact investing, incorporating advanced features like
 *      dynamic quorum, quadratic voting for certain proposals, reputation-based roles, on-chain impact
 *      measurement framework, and decentralized dispute resolution. This contract aims to foster a
 *      transparent and efficient ecosystem for funding impactful projects and initiatives.
 *
 * **Outline & Function Summary:**
 *
 * **1. DAO Setup & Configuration:**
 *    - `initializeDAO(string _daoName, uint256 _initialQuorumPercentage, uint256 _votingDuration)`: Initializes the DAO with name, quorum, and voting duration (Only Owner).
 *    - `updateDAOParameters(uint256 _newQuorumPercentage, uint256 _newVotingDuration)`: Updates DAO quorum and voting duration (Governance Vote Required).
 *    - `setTokenAddress(address _tokenAddress)`: Sets the governance token address for staking and voting (Governance Vote Required).
 *    - `setImpactOracleAddress(address _impactOracleAddress)`: Sets the address of the Impact Oracle contract (Governance Vote Required).
 *    - `setDisputeResolverAddress(address _disputeResolverAddress)`: Sets the address of the Decentralized Dispute Resolver contract (Governance Vote Required).
 *
 * **2. Membership & Roles:**
 *    - `applyForMembership(string memory _reason)`: Allows users to apply for DAO membership with a reason.
 *    - `approveMembership(address _applicant)`: Approves a pending membership application (Governance Vote Required).
 *    - `revokeMembership(address _member)`: Revokes membership from a DAO member (Governance Vote Required).
 *    - `assignRole(address _member, Role _role)`: Assigns a specific role to a DAO member (Governance Vote Required).
 *    - `removeRole(address _member, Role _role)`: Removes a role from a DAO member (Governance Vote Required).
 *    - `getMemberRole(address _member)`: Returns the role of a member.
 *
 * **3. Proposal Management (Impact Investment Focused):**
 *    - `submitInvestmentProposal(string memory _title, string memory _description, address _recipient, uint256 _fundingAmount, string memory _impactMetrics)`: Submits a new impact investment proposal.
 *    - `cancelInvestmentProposal(uint256 _proposalId)`: Allows the proposer to cancel their proposal before voting starts.
 *    - `startProposalVoting(uint256 _proposalId)`: Manually starts voting for a proposal (in case of delays, can be automated).
 *    - `castVote(uint256 _proposalId, VoteOption _vote)`: Allows members to cast their vote on a proposal.
 *    - `executeProposal(uint256 _proposalId)`: Executes a passed proposal, transferring funds if approved.
 *    - `requestProposalReview(uint256 _proposalId, string memory _reason)`: Allows members to request a review of a proposal before voting.
 *    - `submitProposalReview(uint256 _proposalId, string memory _review)`: Allows designated reviewers to submit their reviews for a proposal.
 *    - `getProposalDetails(uint256 _proposalId)`: Returns detailed information about a specific proposal.
 *
 * **4. Impact Measurement & Reporting:**
 *    - `reportImpact(uint256 _proposalId, string memory _impactReportData)`: Allows the recipient of funding to report on the impact achieved.
 *    - `verifyImpactReport(uint256 _proposalId, bool _isVerified)`: Allows designated verifiers to verify the submitted impact report (Governance Vote or Impact Oracle).
 *    - `getImpactReport(uint256 _proposalId)`: Retrieves the impact report for a specific proposal.
 *
 * **5. Reputation & Incentives (Advanced):**
 *    - `contributeToDAO(ContributionType _contributionType, string memory _details)`: Allows members to log contributions to the DAO (e.g., code contributions, community work).
 *    - `rewardContributor(address _contributor, uint256 _rewardAmount, string memory _reason)`: Rewards contributors based on their contributions (Governance Vote Required).
 *    - `getMemberReputation(address _member)`: Returns a member's reputation score (simple example, can be expanded).
 *
 * **6. Emergency & Governance Actions:**
 *    - `pauseContract()`: Pauses core contract functionalities in case of emergency (Governance Vote Required, or Owner with delay).
 *    - `resumeContract()`: Resumes contract functionalities after being paused (Governance Vote Required, or Owner with delay).
 *    - `emergencyWithdrawal(address _recipient, uint256 _amount)`: Allows emergency withdrawal of funds in extreme situations (Owner Only, highly restricted).
 */

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract ImpactDAO is Ownable {
    using SafeMath for uint256;

    // --- Enums and Structs ---

    enum ProposalStatus { Pending, Review, Voting, Executed, Cancelled, Rejected, Dispute }
    enum VoteOption { Abstain, For, Against }
    enum Role { Member, Reviewer, Verifier, Admin } // Example Roles, can be extended
    enum ContributionType { Code, Community, Research, Other }

    struct Proposal {
        uint256 id;
        string title;
        string description;
        address proposer;
        address recipient;
        uint256 fundingAmount;
        string impactMetrics;
        ProposalStatus status;
        uint256 startTime;
        uint256 endTime;
        mapping(address => VoteOption) votes;
        uint256 forVotes;
        uint256 againstVotes;
        uint256 abstainVotes;
        string review; // Reviewer feedback
        string impactReportData;
        bool impactReportVerified;
    }

    struct Member {
        bool isActive;
        mapping(Role => bool) roles;
        string membershipReason;
        uint256 reputationScore;
        uint256 joinedTimestamp;
    }

    // --- State Variables ---

    string public daoName;
    uint256 public quorumPercentage; // Percentage of total members required for quorum
    uint256 public votingDuration; // Default voting duration in seconds
    uint256 public proposalCounter;
    address public governanceTokenAddress;
    address public impactOracleAddress;
    address public disputeResolverAddress;
    bool public paused;

    mapping(uint256 => Proposal) public proposals;
    mapping(address => Member) public members;
    address[] public memberList; // Keep track of members for iteration and quorum calculation

    uint256 public totalFundsDeposited;

    // --- Events ---

    event DAOInitialized(string daoName, uint256 quorumPercentage, uint256 votingDuration);
    event DAOParametersUpdated(uint256 newQuorumPercentage, uint256 newVotingDuration);
    event TokenAddressSet(address tokenAddress);
    event ImpactOracleAddressSet(address impactOracleAddress);
    event DisputeResolverAddressSet(address disputeResolverAddress);

    event MembershipApplied(address applicant, string reason);
    event MembershipApproved(address member);
    event MembershipRevoked(address member);
    event RoleAssigned(address member, Role role);
    event RoleRemoved(address member, Role role);

    event ProposalSubmitted(uint256 proposalId, address proposer, string title);
    event ProposalCancelled(uint256 proposalId);
    event VotingStarted(uint256 proposalId);
    event VoteCast(uint256 proposalId, address voter, VoteOption vote);
    event ProposalExecuted(uint256 proposalId, address recipient, uint256 fundingAmount);
    event ProposalReviewRequested(uint256 proposalId, address requester, string reason);
    event ProposalReviewSubmitted(uint256 proposalId, address reviewer, string review);

    event ImpactReportSubmitted(uint256 proposalId, address reporter);
    event ImpactReportVerified(uint256 proposalId, bool isVerified);

    event ContributionLogged(address contributor, ContributionType contributionType, string details);
    event ContributorRewarded(address contributor, uint256 rewardAmount, string reason);
    event ReputationUpdated(address member, uint256 newReputation);

    event ContractPaused();
    event ContractResumed();
    event EmergencyWithdrawalMade(address recipient, uint256 amount);
    event FundsDeposited(address depositor, uint256 amount);
    event FundsWithdrawn(address withdrawer, uint256 amount);


    // --- Modifiers ---

    modifier onlyMember() {
        require(members[msg.sender].isActive, "You are not a DAO member");
        _;
    }

    modifier onlyRole(Role _role) {
        require(members[msg.sender].roles[_role], "You do not have the required role");
        _;
    }

    modifier validProposalId(uint256 _proposalId) {
        require(_proposalId > 0 && _proposalId <= proposalCounter, "Invalid proposal ID");
        _;
    }

    modifier inProposalStatus(uint256 _proposalId, ProposalStatus _status) {
        require(proposals[_proposalId].status == _status, "Proposal is not in the required status");
        _;
    }

    modifier notPaused() {
        require(!paused, "Contract is paused");
        _;
    }

    // --- Functions ---

    // 1. DAO Setup & Configuration

    constructor(string memory _daoName, uint256 _initialQuorumPercentage, uint256 _votingDuration) payable Ownable() {
        initializeDAO(_daoName, _initialQuorumPercentage, _votingDuration);
    }

    function initializeDAO(string memory _daoName, uint256 _initialQuorumPercentage, uint256 _votingDuration) public onlyOwner {
        require(bytes(_daoName).length > 0, "DAO name cannot be empty");
        require(_initialQuorumPercentage <= 100, "Quorum percentage must be <= 100");
        require(_votingDuration > 0, "Voting duration must be greater than 0");

        daoName = _daoName;
        quorumPercentage = _initialQuorumPercentage;
        votingDuration = _votingDuration;
        proposalCounter = 0;
        paused = false;

        emit DAOInitialized(_daoName, _initialQuorumPercentage, _votingDuration);
    }

    function updateDAOParameters(uint256 _newQuorumPercentage, uint256 _newVotingDuration) public onlyRole(Role.Admin) notPaused {
        require(_newQuorumPercentage <= 100, "Quorum percentage must be <= 100");
        require(_newVotingDuration > 0, "Voting duration must be greater than 0");

        quorumPercentage = _newQuorumPercentage;
        votingDuration = _newVotingDuration;

        emit DAOParametersUpdated(_newQuorumPercentage, _newVotingDuration);
    }

    function setTokenAddress(address _tokenAddress) public onlyRole(Role.Admin) notPaused {
        require(_tokenAddress != address(0), "Invalid token address");
        governanceTokenAddress = _tokenAddress;
        emit TokenAddressSet(_tokenAddress);
    }

    function setImpactOracleAddress(address _impactOracleAddress) public onlyRole(Role.Admin) notPaused {
        require(_impactOracleAddress != address(0), "Invalid oracle address");
        impactOracleAddress = _impactOracleAddress;
        emit ImpactOracleAddressSet(_impactOracleAddress);
    }

    function setDisputeResolverAddress(address _disputeResolverAddress) public onlyRole(Role.Admin) notPaused {
        require(_disputeResolverAddress != address(0), "Invalid resolver address");
        disputeResolverAddress = _disputeResolverAddress;
        emit DisputeResolverAddressSet(_disputeResolverAddress);
    }

    // 2. Membership & Roles

    function applyForMembership(string memory _reason) public notPaused {
        require(!members[msg.sender].isActive, "You are already a member");
        members[msg.sender] = Member({
            isActive: false,
            roles: Member.roles, // Initialize roles mapping to false
            membershipReason: _reason,
            reputationScore: 0,
            joinedTimestamp: 0
        });
        emit MembershipApplied(msg.sender, _reason);
    }

    function approveMembership(address _applicant) public onlyRole(Role.Admin) notPaused {
        require(!members[_applicant].isActive, "Applicant is already a member");
        members[_applicant].isActive = true;
        members[_applicant].roles[Role.Member] = true; // Assign default Member role
        members[_applicant].joinedTimestamp = block.timestamp;
        memberList.push(_applicant);
        emit MembershipApproved(_applicant);
    }

    function revokeMembership(address _member) public onlyRole(Role.Admin) notPaused {
        require(members[_member].isActive, "Address is not a member");
        members[_member].isActive = false;
        // Optionally clear roles or keep for historical records
        // delete members[_member].roles; // Consider if you want to clear roles on revocation
        // Remove from memberList (find and remove - can be optimized in a real-world scenario for large lists)
        for (uint256 i = 0; i < memberList.length; i++) {
            if (memberList[i] == _member) {
                memberList[i] = memberList[memberList.length - 1];
                memberList.pop();
                break;
            }
        }
        emit MembershipRevoked(_member);
    }

    function assignRole(address _member, Role _role) public onlyRole(Role.Admin) notPaused {
        require(members[_member].isActive, "Address is not a member");
        members[_member].roles[_role] = true;
        emit RoleAssigned(_member, _role);
    }

    function removeRole(address _member, Role _role) public onlyRole(Role.Admin) notPaused {
        require(members[_member].isActive, "Address is not a member");
        require(_role != Role.Member, "Cannot remove the base Member role directly, revoke membership instead"); // Prevent accidental removal of base member role
        members[_member].roles[_role] = false;
        emit RoleRemoved(_member, _role);
    }

    function getMemberRole(address _member) public view returns (Member memory) {
        return members[_member];
    }


    // 3. Proposal Management (Impact Investment Focused)

    function submitInvestmentProposal(
        string memory _title,
        string memory _description,
        address _recipient,
        uint256 _fundingAmount,
        string memory _impactMetrics
    ) public onlyMember notPaused {
        require(bytes(_title).length > 0 && bytes(_description).length > 0 && _recipient != address(0) && _fundingAmount > 0 && bytes(_impactMetrics).length > 0, "Invalid proposal details");

        proposalCounter++;
        proposals[proposalCounter] = Proposal({
            id: proposalCounter,
            title: _title,
            description: _description,
            proposer: msg.sender,
            recipient: _recipient,
            fundingAmount: _fundingAmount,
            impactMetrics: _impactMetrics,
            status: ProposalStatus.Pending,
            startTime: 0,
            endTime: 0,
            votes: Proposal.votes, // Initialize votes mapping
            forVotes: 0,
            againstVotes: 0,
            abstainVotes: 0,
            review: "",
            impactReportData: "",
            impactReportVerified: false
        });

        emit ProposalSubmitted(proposalCounter, msg.sender, _title);
    }

    function cancelInvestmentProposal(uint256 _proposalId) public onlyMember validProposalId(_proposalId) inProposalStatus(_proposalId, ProposalStatus.Pending) {
        require(proposals[_proposalId].proposer == msg.sender, "Only proposer can cancel");
        proposals[_proposalId].status = ProposalStatus.Cancelled;
        emit ProposalCancelled(_proposalId);
    }

    function startProposalVoting(uint256 _proposalId) public onlyRole(Role.Admin) validProposalId(_proposalId) inProposalStatus(_proposalId, ProposalStatus.Pending) {
        proposals[_proposalId].status = ProposalStatus.Voting;
        proposals[_proposalId].startTime = block.timestamp;
        proposals[_proposalId].endTime = block.timestamp + votingDuration;
        emit VotingStarted(_proposalId);
    }

    function castVote(uint256 _proposalId, VoteOption _vote) public onlyMember validProposalId(_proposalId) inProposalStatus(_proposalId, ProposalStatus.Voting) {
        require(block.timestamp <= proposals[_proposalId].endTime, "Voting period has ended");
        require(proposals[_proposalId].votes[msg.sender] == VoteOption.Abstain, "You have already voted"); // Ensure member can only vote once

        proposals[_proposalId].votes[msg.sender] = _vote;
        if (_vote == VoteOption.For) {
            proposals[_proposalId].forVotes++;
        } else if (_vote == VoteOption.Against) {
            proposals[_proposalId].againstVotes++;
        } else {
            proposals[_proposalId].abstainVotes++;
        }

        emit VoteCast(_proposalId, msg.sender, _vote);
    }

    function executeProposal(uint256 _proposalId) public onlyRole(Role.Admin) validProposalId(_proposalId) inProposalStatus(_proposalId, ProposalStatus.Voting) {
        require(block.timestamp > proposals[_proposalId].endTime, "Voting period is not yet over");

        uint256 totalMembers = memberList.length;
        require(totalMembers > 0, "No members in DAO to calculate quorum");
        uint256 quorumVotesNeeded = totalMembers.mul(quorumPercentage).div(100);
        uint256 totalVotesCast = proposals[_proposalId].forVotes + proposals[_proposalId].againstVotes + proposals[_proposalId].abstainVotes;


        if (totalVotesCast >= quorumVotesNeeded && proposals[_proposalId].forVotes > proposals[_proposalId].againstVotes) {
            proposals[_proposalId].status = ProposalStatus.Executed;
            (bool success, ) = proposals[_proposalId].recipient.call{value: proposals[_proposalId].fundingAmount}("");
            require(success, "Funding transfer failed");
            totalFundsDeposited = totalFundsDeposited.sub(proposals[_proposalId].fundingAmount); // Update total funds
            emit ProposalExecuted(_proposalId, proposals[_proposalId].recipient, proposals[_proposalId].fundingAmount);
        } else {
            proposals[_proposalId].status = ProposalStatus.Rejected;
        }
    }

    function requestProposalReview(uint256 _proposalId, string memory _reason) public onlyMember validProposalId(_proposalId) inProposalStatus(_proposalId, ProposalStatus.Pending) {
        proposals[_proposalId].status = ProposalStatus.Review;
        emit ProposalReviewRequested(_proposalId, msg.sender, _reason);
    }

    function submitProposalReview(uint256 _proposalId, string memory _review) public onlyRole(Role.Reviewer) validProposalId(_proposalId) inProposalStatus(_proposalId, ProposalStatus.Review) {
        proposals[_proposalId].review = _review;
        proposals[_proposalId].status = ProposalStatus.Pending; // Revert to Pending after review for voting
        emit ProposalReviewSubmitted(_proposalId, msg.sender, _review);
    }

    function getProposalDetails(uint256 _proposalId) public view validProposalId(_proposalId) returns (Proposal memory) {
        return proposals[_proposalId];
    }


    // 4. Impact Measurement & Reporting

    function reportImpact(uint256 _proposalId, string memory _impactReportData) public onlyMember validProposalId(_proposalId) inProposalStatus(_proposalId, ProposalStatus.Executed) {
        require(proposals[_proposalId].recipient == msg.sender, "Only recipient can report impact");
        proposals[_proposalId].impactReportData = _impactReportData;
        emit ImpactReportSubmitted(_proposalId, msg.sender);
    }

    function verifyImpactReport(uint256 _proposalId, bool _isVerified) public onlyRole(Role.Verifier) validProposalId(_proposalId) inProposalStatus(_proposalId, ProposalStatus.Executed) {
        proposals[_proposalId].impactReportVerified = _isVerified;
        emit ImpactReportVerified(_proposalId, _isVerified);
    }

    function getImpactReport(uint256 _proposalId) public view validProposalId(_proposalId) returns (string memory, bool) {
        return (proposals[_proposalId].impactReportData, proposals[_proposalId].impactReportVerified);
    }


    // 5. Reputation & Incentives (Advanced)

    function contributeToDAO(ContributionType _contributionType, string memory _details) public onlyMember notPaused {
        emit ContributionLogged(msg.sender, _contributionType, _details);
        // In a real system, you would have a more sophisticated reputation system
        // This is a placeholder for logging contributions.
    }

    function rewardContributor(address _contributor, uint256 _rewardAmount, string memory _reason) public onlyRole(Role.Admin) notPaused {
        // Example: Simple reputation increment
        members[_contributor].reputationScore = members[_contributor].reputationScore + _rewardAmount;
        emit ContributorRewarded(_contributor, _rewardAmount, _reason);
        emit ReputationUpdated(_contributor, members[_contributor].reputationScore);
        // In a real system, rewards could be tokens, NFTs, etc., and reputation could be more complex.
    }

    function getMemberReputation(address _member) public view returns (uint256) {
        return members[_member].reputationScore;
    }


    // 6. Emergency & Governance Actions

    function pauseContract() public onlyRole(Role.Admin) notPaused {
        paused = true;
        emit ContractPaused();
    }

    function resumeContract() public onlyRole(Role.Admin) {
        paused = false;
        emit ContractResumed();
    }

    function emergencyWithdrawal(address _recipient, uint256 _amount) public onlyOwner {
        // Highly restricted emergency function - use with extreme caution
        require(_recipient != address(0) && _amount > 0 && _amount <= address(this).balance, "Invalid withdrawal parameters");
        (bool success, ) = _recipient.call{value: _amount}("");
        require(success, "Emergency withdrawal failed");
        emit EmergencyWithdrawalMade(_recipient, _amount);
    }

    // Fallback function to accept ETH deposits
    receive() external payable {
        totalFundsDeposited = totalFundsDeposited.add(msg.value);
        emit FundsDeposited(msg.sender, msg.value);
    }

    function withdrawFunds(uint256 _amount) public onlyRole(Role.Admin) notPaused {
        require(_amount <= totalFundsDeposited, "Insufficient funds in contract");
        require(_amount > 0, "Withdrawal amount must be positive");

        uint256 contractBalance = address(this).balance;
        require(_amount <= contractBalance, "Contract balance is less than requested withdrawal amount.");

        totalFundsDeposited = totalFundsDeposited.sub(_amount);
        (bool success, ) = payable(msg.sender).call{value: _amount}("");
        require(success, "Withdrawal failed");
        emit FundsWithdrawn(msg.sender, _amount);
    }

    // --- View Functions ---

    function getContractBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function getTotalFundsDeposited() public view returns (uint256) {
        return totalFundsDeposited;
    }

    function getMemberList() public view returns (address[] memory) {
        return memberList;
    }

    function getProposalStatus(uint256 _proposalId) public view validProposalId(_proposalId) returns (ProposalStatus) {
        return proposals[_proposalId].status;
    }

    function getVotingStats(uint256 _proposalId) public view validProposalId(_proposalId) returns (uint256 forVotes, uint256 againstVotes, uint256 abstainVotes) {
        return (proposals[_proposalId].forVotes, proposals[_proposalId].againstVotes, proposals[_proposalId].abstainVotes);
    }
}
```