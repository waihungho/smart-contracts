```solidity
/**
 * @title Decentralized Autonomous Research Organization (DARO) Smart Contract
 * @author Bard (AI Assistant)
 * @dev A smart contract for a Decentralized Autonomous Research Organization (DARO).
 * It facilitates research proposal submissions, funding, peer review, milestone tracking,
 * intellectual property management (via NFTs), and decentralized governance.
 *
 * **Outline & Function Summary:**
 *
 * **1. Researcher Management:**
 *    - `registerResearcher(string _name, string _expertise, string _profileLink)`: Allows individuals to register as researchers.
 *    - `updateResearcherProfile(string _name, string _expertise, string _profileLink)`: Allows researchers to update their profile information.
 *    - `getResearcherProfile(address _researcherAddress) view returns (string name, string expertise, string profileLink, bool isRegistered)`: Retrieves a researcher's profile.
 *
 * **2. Funder Management:**
 *    - `depositFunds() payable`: Allows users to deposit funds to the DARO's treasury.
 *    - `withdrawFunds(uint256 _amount)`: Allows the contract owner (DARO governance) to withdraw funds from the treasury (governance controlled).
 *    - `getContractBalance() view returns (uint256)`: Retrieves the current balance of the DARO treasury.
 *
 * **3. Research Proposal Management:**
 *    - `submitProposal(string _title, string _description, uint256 _fundingGoal, string _researchPlanLink)`: Researchers can submit research proposals.
 *    - `updateProposal(uint256 _proposalId, string _title, string _description, uint256 _fundingGoal, string _researchPlanLink)`: Researchers can update their proposals before funding starts.
 *    - `cancelProposal(uint256 _proposalId)`: Researchers can cancel their proposals before funding starts.
 *    - `getProposalDetails(uint256 _proposalId) view returns (...)`: Retrieves detailed information about a specific proposal.
 *    - `listProposalsByStatus(ProposalStatus _status) view returns (uint256[])`: Lists proposal IDs based on their status (e.g., Pending, Funded, Completed).
 *
 * **4. Funding & Contribution:**
 *    - `fundProposal(uint256 _proposalId) payable`: Allows users to contribute funds to a specific research proposal.
 *    - `getProposalFundingStatus(uint256 _proposalId) view returns (uint256 currentFunding, uint256 fundingGoal)`: Retrieves the current funding status of a proposal.
 *    - `refundContribution(uint256 _proposalId)`: Allows contributors to request a refund if a proposal fails to reach its funding goal within a deadline (governance-set deadline).
 *
 * **5. Peer Review Process:**
 *    - `registerReviewer(string _expertise)`: Allows researchers to register as peer reviewers.
 *    - `submitReview(uint256 _proposalId, string _reviewText, int8 _rating)`: Registered reviewers can submit reviews for proposals.
 *    - `getProposalReviews(uint256 _proposalId) view returns (...)`: Retrieves reviews associated with a specific proposal.
 *    - `voteOnProposalFunding(uint256 _proposalId, bool _approve)`: Registered researchers can vote on whether to approve funding for a proposal after review.
 *    - `setReviewQuorum(uint256 _quorum)`: Governance function to set the required quorum for proposal funding votes.
 *
 * **6. Milestone Tracking & Project Management:**
 *    - `submitMilestone(uint256 _proposalId, string _milestoneDescription, string _evidenceLink)`: Researchers of funded proposals can submit milestones.
 *    - `approveMilestone(uint256 _proposalId, uint256 _milestoneIndex)`: Governance/Reviewers (configurable) can approve completed milestones, releasing funds in stages.
 *    - `getMilestoneDetails(uint256 _proposalId, uint256 _milestoneIndex) view returns (...)`: Retrieves details of a specific milestone.
 *
 * **7. Intellectual Property Management (NFT based - simplified example):**
 *    - `mintResearchNFT(uint256 _proposalId, string _ipfsMetadataHash)`: Upon successful research completion, mints an NFT representing the research output (simplified IP management).
 *    - `transferResearchNFT(uint256 _tokenId, address _to)`: Allows transferring ownership of the Research NFT (basic example).
 *    - `getResearchNFTOwner(uint256 _tokenId) view returns (address)`: Retrieves the owner of a Research NFT.
 *
 * **8. Governance & Administration:**
 *    - `proposeGovernanceChange(string _description, bytes _calldata)`: Allows researchers/community members to propose changes to the DARO governance (e.g., change quorum, fees, etc.).
 *    - `voteOnGovernanceChange(uint256 _proposalId, bool _support)`: Registered researchers vote on governance change proposals.
 *    - `executeGovernanceChange(uint256 _proposalId)`: Executes approved governance changes (governance controlled).
 *    - `pauseContract()`: Allows the contract owner to pause critical functions in case of emergency.
 *    - `unpauseContract()`: Allows the contract owner to resume contract operations.
 *    - `setFundingDeadlineExtension(uint256 _proposalId, uint256 _extensionDays)`: Governance function to extend the funding deadline of a proposal.
 */
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract DARO is ERC721, Ownable, Pausable {
    using Counters for Counters.Counter;
    Counters.Counter private _proposalIds;
    Counters.Counter private _researchNFTTokenIds;
    Counters.Counter private _governanceProposalIds;

    enum ProposalStatus { Pending, Funding, Funded, InProgress, Completed, Failed, Cancelled }
    enum ReviewStatus { Pending, Submitted }
    enum GovernanceProposalStatus { Pending, Active, Approved, Rejected, Executed }

    struct ResearcherProfile {
        string name;
        string expertise;
        string profileLink;
        bool isRegistered;
    }

    struct ResearchProposal {
        uint256 id;
        address researcher;
        string title;
        string description;
        uint256 fundingGoal;
        uint256 currentFunding;
        string researchPlanLink;
        ProposalStatus status;
        uint256 fundingDeadline;
        uint256 reviewQuorum; // Quorum for funding approval votes
        uint256 yesVotes;
        uint256 noVotes;
    }

    struct Review {
        address reviewer;
        uint256 proposalId;
        string reviewText;
        int8 rating; // Example rating system - can be adjusted
        ReviewStatus status;
    }

    struct Milestone {
        string description;
        string evidenceLink;
        bool isApproved;
    }

    struct GovernanceProposal {
        uint256 id;
        address proposer;
        string description;
        bytes calldataData; // Data for the governance change
        GovernanceProposalStatus status;
        uint256 yesVotes;
        uint256 noVotes;
        uint256 votingDeadline;
    }

    mapping(address => ResearcherProfile) public researcherProfiles;
    mapping(uint256 => ResearchProposal) public researchProposals;
    mapping(uint256 => Review[]) public proposalReviews;
    mapping(uint256 => Milestone[]) public proposalMilestones;
    mapping(uint256 => GovernanceProposal) public governanceProposals;
    mapping(uint256 => address[]) public proposalFunders; // Keep track of funders per proposal

    address[] public registeredReviewers;
    uint256 public reviewVoteQuorum = 5; // Default quorum for funding approval votes
    uint256 public governanceVoteQuorumPercentage = 50; // Percentage quorum for governance votes
    uint256 public governanceVotingDurationDays = 7; // Default duration for governance voting in days
    uint256 public fundingDeadlineDays = 30; // Default funding deadline in days

    event ResearcherRegistered(address researcherAddress, string name);
    event ResearcherProfileUpdated(address researcherAddress, string name);
    event FundsDeposited(address funder, uint256 amount);
    event FundsWithdrawn(address admin, uint256 amount);
    event ProposalSubmitted(uint256 proposalId, address researcher, string title);
    event ProposalUpdated(uint256 proposalId, string title);
    event ProposalCancelled(uint256 proposalId);
    event ProposalFunded(uint256 proposalId, uint256 fundingGoal);
    event ProposalFundingFailed(uint256 proposalId);
    event ContributionMade(uint256 proposalId, address contributor, uint256 amount);
    event RefundRequested(uint256 proposalId, address contributor, uint256 amount);
    event ReviewerRegistered(address reviewerAddress, string expertise);
    event ReviewSubmitted(uint256 proposalId, address reviewer, string reviewText, int8 rating);
    event FundingVoteCast(uint256 proposalId, address voter, bool approve);
    event MilestoneSubmitted(uint256 proposalId, uint256 milestoneIndex, string description);
    event MilestoneApproved(uint256 proposalId, uint256 milestoneIndex);
    event ResearchNFTMinted(uint256 tokenId, uint256 proposalId, address owner);
    event ResearchNFTTransferred(uint256 tokenId, address from, address to);
    event GovernanceProposalCreated(uint256 proposalId, address proposer, string description);
    event GovernanceVoteCast(uint256 proposalId, address voter, bool support);
    event GovernanceChangeExecuted(uint256 proposalId);
    event ContractPaused();
    event ContractUnpaused();
    event FundingDeadlineExtended(uint256 proposalId, uint256 newDeadline);

    modifier onlyResearcher() {
        require(researcherProfiles[msg.sender].isRegistered, "Only registered researchers can perform this action.");
        _;
    }

    modifier onlyReviewer() {
        bool isReviewer = false;
        for (uint256 i = 0; i < registeredReviewers.length; i++) {
            if (registeredReviewers[i] == msg.sender) {
                isReviewer = true;
                break;
            }
        }
        require(isReviewer, "Only registered reviewers can perform this action.");
        _;
    }

    modifier whenProposalPending(uint256 _proposalId) {
        require(researchProposals[_proposalId].status == ProposalStatus.Pending, "Proposal must be in Pending status.");
        _;
    }

    modifier whenProposalFunding(uint256 _proposalId) {
        require(researchProposals[_proposalId].status == ProposalStatus.Funding, "Proposal must be in Funding status.");
        _;
    }

    modifier whenProposalFunded(uint256 _proposalId) {
        require(researchProposals[_proposalId].status == ProposalStatus.Funded, "Proposal must be in Funded status.");
        _;
    }

    modifier whenProposalInProgress(uint256 _proposalId) {
        require(researchProposals[_proposalId].status == ProposalStatus.InProgress, "Proposal must be In Progress.");
        _;
    }

    modifier whenProposalCompleted(uint256 _proposalId) {
        require(researchProposals[_proposalId].status == ProposalStatus.Completed, "Proposal must be Completed.");
        _;
    }

    modifier whenProposalNotCancelled(uint256 _proposalId) {
        require(researchProposals[_proposalId].status != ProposalStatus.Cancelled, "Proposal is cancelled.");
        _;
    }

    modifier whenFundingDeadlineNotExpired(uint256 _proposalId) {
        require(block.timestamp <= researchProposals[_proposalId].fundingDeadline, "Funding deadline expired.");
        _;
    }

    modifier whenNotPaused() {
        require(!paused(), "Contract is paused.");
        _;
    }

    modifier whenPaused() {
        require(paused(), "Contract is not paused.");
        _;
    }

    constructor() ERC721("DAROResearchNFT", "DRNFT") {
        // Initialize contract if needed
    }

    // -------------------------------------------------------------------------
    // 1. Researcher Management
    // -------------------------------------------------------------------------

    /// @notice Registers a new researcher.
    /// @param _name The name of the researcher.
    /// @param _expertise The area of expertise of the researcher.
    /// @param _profileLink Link to the researcher's profile (e.g., personal website, social media).
    function registerResearcher(string memory _name, string memory _expertise, string memory _profileLink) external whenNotPaused {
        require(!researcherProfiles[msg.sender].isRegistered, "Researcher already registered.");
        researcherProfiles[msg.sender] = ResearcherProfile({
            name: _name,
            expertise: _expertise,
            profileLink: _profileLink,
            isRegistered: true
        });
        emit ResearcherRegistered(msg.sender, _name);
    }

    /// @notice Updates the profile information of a registered researcher.
    /// @param _name The updated name of the researcher.
    /// @param _expertise The updated area of expertise.
    /// @param _profileLink The updated profile link.
    function updateResearcherProfile(string memory _name, string memory _expertise, string memory _profileLink) external onlyResearcher whenNotPaused {
        researcherProfiles[msg.sender].name = _name;
        researcherProfiles[msg.sender].expertise = _expertise;
        researcherProfiles[msg.sender].profileLink = _profileLink;
        emit ResearcherProfileUpdated(msg.sender, _name);
    }

    /// @notice Retrieves the profile information of a researcher.
    /// @param _researcherAddress The address of the researcher.
    /// @return name, expertise, profileLink, isRegistered Researcher profile details.
    function getResearcherProfile(address _researcherAddress) external view returns (string memory name, string memory expertise, string memory profileLink, bool isRegistered) {
        ResearcherProfile memory profile = researcherProfiles[_researcherAddress];
        return (profile.name, profile.expertise, profile.profileLink, profile.isRegistered);
    }

    // -------------------------------------------------------------------------
    // 2. Funder Management
    // -------------------------------------------------------------------------

    /// @notice Allows users to deposit funds into the DARO treasury.
    function depositFunds() external payable whenNotPaused {
        emit FundsDeposited(msg.sender, msg.value);
    }

    /// @notice Allows the contract owner to withdraw funds from the DARO treasury. Governance controlled withdrawal.
    /// @param _amount The amount to withdraw.
    function withdrawFunds(uint256 _amount) external onlyOwner whenNotPaused {
        payable(owner()).transfer(_amount);
        emit FundsWithdrawn(owner(), _amount);
    }

    /// @notice Retrieves the current balance of the DARO treasury.
    /// @return The contract balance.
    function getContractBalance() external view returns (uint256) {
        return address(this).balance;
    }

    // -------------------------------------------------------------------------
    // 3. Research Proposal Management
    // -------------------------------------------------------------------------

    /// @notice Allows researchers to submit a new research proposal.
    /// @param _title The title of the research proposal.
    /// @param _description A brief description of the research.
    /// @param _fundingGoal The funding goal for the proposal in wei.
    /// @param _researchPlanLink Link to a detailed research plan document.
    function submitProposal(string memory _title, string memory _description, uint256 _fundingGoal, string memory _researchPlanLink) external onlyResearcher whenNotPaused {
        _proposalIds.increment();
        uint256 proposalId = _proposalIds.current();
        researchProposals[proposalId] = ResearchProposal({
            id: proposalId,
            researcher: msg.sender,
            title: _title,
            description: _description,
            fundingGoal: _fundingGoal,
            currentFunding: 0,
            researchPlanLink: _researchPlanLink,
            status: ProposalStatus.Pending,
            fundingDeadline: block.timestamp + fundingDeadlineDays * 1 days, // Set default funding deadline
            reviewQuorum: reviewVoteQuorum,
            yesVotes: 0,
            noVotes: 0
        });
        emit ProposalSubmitted(proposalId, msg.sender, _title);
    }

    /// @notice Allows researchers to update their proposal details before funding starts.
    /// @param _proposalId The ID of the proposal to update.
    /// @param _title The updated title.
    /// @param _description The updated description.
    /// @param _fundingGoal The updated funding goal.
    /// @param _researchPlanLink The updated research plan link.
    function updateProposal(uint256 _proposalId, string memory _title, string memory _description, uint256 _fundingGoal, string memory _researchPlanLink) external onlyResearcher whenProposalPending(_proposalId) whenNotPaused {
        require(researchProposals[_proposalId].researcher == msg.sender, "Only proposal owner can update.");
        researchProposals[_proposalId].title = _title;
        researchProposals[_proposalId].description = _description;
        researchProposals[_proposalId].fundingGoal = _fundingGoal;
        researchProposals[_proposalId].researchPlanLink = _researchPlanLink;
        emit ProposalUpdated(_proposalId, _title);
    }

    /// @notice Allows researchers to cancel their proposal if it's still in pending status.
    /// @param _proposalId The ID of the proposal to cancel.
    function cancelProposal(uint256 _proposalId) external onlyResearcher whenProposalPending(_proposalId) whenNotPaused {
        require(researchProposals[_proposalId].researcher == msg.sender, "Only proposal owner can cancel.");
        researchProposals[_proposalId].status = ProposalStatus.Cancelled;
        emit ProposalCancelled(_proposalId);
    }

    /// @notice Retrieves detailed information about a specific research proposal.
    /// @param _proposalId The ID of the proposal.
    /// @return All proposal details.
    function getProposalDetails(uint256 _proposalId) external view returns (
        uint256 id, address researcher, string memory title, string memory description,
        uint256 fundingGoal, uint256 currentFunding, string memory researchPlanLink,
        ProposalStatus status, uint256 fundingDeadline, uint256 reviewQuorum, uint256 yesVotes, uint256 noVotes
    ) {
        ResearchProposal memory proposal = researchProposals[_proposalId];
        return (
            proposal.id, proposal.researcher, proposal.title, proposal.description,
            proposal.fundingGoal, proposal.currentFunding, proposal.researchPlanLink,
            proposal.status, proposal.fundingDeadline, proposal.reviewQuorum, proposal.yesVotes, proposal.noVotes
        );
    }

    /// @notice Lists proposal IDs based on their status.
    /// @param _status The status to filter by.
    /// @return An array of proposal IDs with the given status.
    function listProposalsByStatus(ProposalStatus _status) external view returns (uint256[] memory) {
        uint256[] memory proposalList = new uint256[](_proposalIds.current()); // Max size, will be trimmed
        uint256 count = 0;
        for (uint256 i = 1; i <= _proposalIds.current(); i++) {
            if (researchProposals[i].status == _status) {
                proposalList[count] = i;
                count++;
            }
        }
        // Trim the array to actual size
        uint256[] memory trimmedList = new uint256[](count);
        for (uint256 i = 0; i < count; i++) {
            trimmedList[i] = proposalList[i];
        }
        return trimmedList;
    }


    // -------------------------------------------------------------------------
    // 4. Funding & Contribution
    // -------------------------------------------------------------------------

    /// @notice Allows users to contribute funds to a research proposal.
    /// @param _proposalId The ID of the proposal to fund.
    function fundProposal(uint256 _proposalId) external payable whenProposalFunding(_proposalId) whenFundingDeadlineNotExpired(_proposalId) whenNotPaused {
        require(researchProposals[_proposalId].status != ProposalStatus.Cancelled, "Cannot fund cancelled proposal.");
        require(researchProposals[_proposalId].status != ProposalStatus.Completed, "Cannot fund completed proposal.");

        ResearchProposal storage proposal = researchProposals[_proposalId];
        require(proposal.currentFunding < proposal.fundingGoal, "Proposal already fully funded.");

        uint256 amountToFund = msg.value;
        uint256 remainingFundingNeeded = proposal.fundingGoal - proposal.currentFunding;

        if (amountToFund > remainingFundingNeeded) {
            amountToFund = remainingFundingNeeded; // Don't overfund
        }

        proposal.currentFunding += amountToFund;
        proposalFunders[_proposalId].push(msg.sender); // Track funders

        emit ContributionMade(_proposalId, msg.sender, amountToFund);

        if (proposal.currentFunding >= proposal.fundingGoal) {
            proposal.status = ProposalStatus.Funded;
            emit ProposalFunded(_proposalId, proposal.fundingGoal);
        }
    }

    /// @notice Retrieves the current funding status of a proposal.
    /// @param _proposalId The ID of the proposal.
    /// @return currentFunding, fundingGoal The current funding amount and the funding goal.
    function getProposalFundingStatus(uint256 _proposalId) external view returns (uint256 currentFunding, uint256 fundingGoal) {
        return (researchProposals[_proposalId].currentFunding, researchProposals[_proposalId].fundingGoal);
    }

    /// @notice Allows contributors to request a refund if a proposal fails to reach its funding goal by the deadline.
    /// Governance/owner function to initiate refunds.
    /// @param _proposalId The ID of the proposal to refund contributors for.
    function refundContribution(uint256 _proposalId) external onlyOwner whenProposalFunding(_proposalId) whenNotPaused {
        ResearchProposal storage proposal = researchProposals[_proposalId];
        require(block.timestamp > proposal.fundingDeadline, "Funding deadline has not expired yet.");
        require(proposal.currentFunding < proposal.fundingGoal, "Proposal reached funding goal, no refund needed.");
        require(proposal.status != ProposalStatus.Failed, "Refund already processed for this proposal.");

        proposal.status = ProposalStatus.Failed;
        emit ProposalFundingFailed(_proposalId);

        // In a real-world scenario, implement logic to iterate through proposalFunders[_proposalId]
        // and refund each contributor their proportional share. This is a simplified example.
        // For full refund implementation, consider using a withdraw pattern or a separate refund function
        // per contributor to manage gas limits.
        // For simplicity, this example will not implement automatic refund distribution due to complexity and gas costs.
        // Contributors would likely need to call a separate function to claim their refunds based on records.
        // This is a placeholder for advanced refund logic.
    }

    // -------------------------------------------------------------------------
    // 5. Peer Review Process
    // -------------------------------------------------------------------------

    /// @notice Allows registered researchers to register as peer reviewers.
    /// @param _expertise The reviewer's area of expertise.
    function registerReviewer(string memory _expertise) external onlyResearcher whenNotPaused {
        bool alreadyReviewer = false;
        for (uint256 i = 0; i < registeredReviewers.length; i++) {
            if (registeredReviewers[i] == msg.sender) {
                alreadyReviewer = true;
                break;
            }
        }
        require(!alreadyReviewer, "Already registered as a reviewer.");
        registeredReviewers.push(msg.sender);
        emit ReviewerRegistered(msg.sender, _expertise);
    }

    /// @notice Allows registered reviewers to submit a review for a research proposal.
    /// @param _proposalId The ID of the proposal being reviewed.
    /// @param _reviewText The text of the review.
    /// @param _rating A rating for the proposal (example: -5 to 5, can be adjusted).
    function submitReview(uint256 _proposalId, string memory _reviewText, int8 _rating) external onlyReviewer whenProposalPending(_proposalId) whenNotPaused {
        proposalReviews[_proposalId].push(Review({
            reviewer: msg.sender,
            proposalId: _proposalId,
            reviewText: _reviewText,
            rating: _rating,
            status: ReviewStatus.Submitted
        }));
        emit ReviewSubmitted(_proposalId, msg.sender, _reviewText, _rating);
    }

    /// @notice Retrieves all reviews associated with a specific proposal.
    /// @param _proposalId The ID of the proposal.
    /// @return An array of reviews for the proposal.
    function getProposalReviews(uint256 _proposalId) external view returns (Review[] memory) {
        return proposalReviews[_proposalId];
    }

    /// @notice Allows registered researchers to vote on whether to approve funding for a proposal after review.
    /// @param _proposalId The ID of the proposal to vote on.
    /// @param _approve True to approve funding, false to reject.
    function voteOnProposalFunding(uint256 _proposalId, bool _approve) external onlyResearcher whenProposalPending(_proposalId) whenNotPaused {
        ResearchProposal storage proposal = researchProposals[_proposalId];
        require(proposal.status == ProposalStatus.Pending, "Voting can only happen in Pending status.");

        // Basic voting - in a real DAO, consider more robust voting mechanisms, prevent double voting etc.
        if (_approve) {
            proposal.yesVotes++;
        } else {
            proposal.noVotes++;
        }
        emit FundingVoteCast(_proposalId, msg.sender, _approve);

        if (proposal.yesVotes >= proposal.reviewQuorum) {
            proposal.status = ProposalStatus.Funding; // Move to Funding stage if quorum reached
            emit ProposalStatusChanged(_proposalId, ProposalStatus.Funding); // Custom event for status changes
        }
        // In a more complex system, you might have a voting deadline and then finalize the vote.
        // For simplicity, this example funds when yes votes reach quorum.
    }

    /// @notice Sets the required quorum for proposal funding votes. Governance function.
    /// @param _quorum The new quorum value.
    function setReviewQuorum(uint256 _quorum) external onlyOwner whenNotPaused {
        reviewVoteQuorum = _quorum;
    }

    // Custom event for proposal status changes
    event ProposalStatusChanged(uint256 proposalId, ProposalStatus newStatus);


    // -------------------------------------------------------------------------
    // 6. Milestone Tracking & Project Management
    // -------------------------------------------------------------------------

    /// @notice Researchers of funded proposals can submit a milestone for their project.
    /// @param _proposalId The ID of the funded proposal.
    /// @param _milestoneDescription Description of the milestone achieved.
    /// @param _evidenceLink Link to evidence or documentation of the milestone completion.
    function submitMilestone(uint256 _proposalId, string memory _milestoneDescription, string memory _evidenceLink) external onlyResearcher whenProposalFunded(_proposalId) whenNotPaused {
        require(researchProposals[_proposalId].researcher == msg.sender, "Only proposal researcher can submit milestones.");
        proposalMilestones[_proposalId].push(Milestone({
            description: _milestoneDescription,
            evidenceLink: _evidenceLink,
            isApproved: false
        }));
        emit MilestoneSubmitted(_proposalId, proposalMilestones[_proposalId].length - 1, _milestoneDescription);
    }

    /// @notice Governance/Reviewers can approve a submitted milestone, potentially releasing funds in stages.
    /// @param _proposalId The ID of the proposal.
    /// @param _milestoneIndex The index of the milestone to approve (0-based).
    function approveMilestone(uint256 _proposalId, uint256 _milestoneIndex) external onlyOwner whenProposalFunded(_proposalId) whenNotPaused {
        require(_milestoneIndex < proposalMilestones[_proposalId].length, "Invalid milestone index.");
        require(!proposalMilestones[_proposalId][_milestoneIndex].isApproved, "Milestone already approved.");

        proposalMilestones[_proposalId][_milestoneIndex].isApproved = true;
        emit MilestoneApproved(_proposalId, _milestoneIndex);

        // In a real-world scenario, you would implement fund release logic here,
        // potentially releasing a portion of the funded amount upon milestone approval.
        // This could be based on pre-defined milestone funding percentages in the proposal.
        // For simplicity, this example only marks the milestone as approved.
    }

    /// @notice Retrieves details of a specific milestone for a proposal.
    /// @param _proposalId The ID of the proposal.
    /// @param _milestoneIndex The index of the milestone.
    /// @return Milestone details.
    function getMilestoneDetails(uint256 _proposalId, uint256 _milestoneIndex) external view returns (string memory description, string memory evidenceLink, bool isApproved) {
        require(_milestoneIndex < proposalMilestones[_proposalId].length, "Invalid milestone index.");
        Milestone memory milestone = proposalMilestones[_proposalId][_milestoneIndex];
        return (milestone.description, milestone.evidenceLink, milestone.isApproved);
    }

    // -------------------------------------------------------------------------
    // 7. Intellectual Property Management (NFT based - simplified example)
    // -------------------------------------------------------------------------

    /// @notice Mints an NFT representing the research output upon successful completion.
    /// @param _proposalId The ID of the completed research proposal.
    /// @param _ipfsMetadataHash IPFS hash of the research metadata (e.g., abstract, paper, data).
    function mintResearchNFT(uint256 _proposalId, string memory _ipfsMetadataHash) external onlyResearcher whenProposalCompleted(_proposalId) whenNotPaused {
        require(researchProposals[_proposalId].researcher == msg.sender, "Only proposal researcher can mint NFT.");
        _researchNFTTokenIds.increment();
        uint256 tokenId = _researchNFTTokenIds.current();
        _safeMint(msg.sender, tokenId);
        _setTokenURI(tokenId, _ipfsMetadataHash); // Set metadata URI
        emit ResearchNFTMinted(tokenId, _proposalId, msg.sender);
    }

    /// @notice Allows transferring ownership of a Research NFT.
    /// @param _tokenId The ID of the NFT to transfer.
    /// @param _to The address to transfer the NFT to.
    function transferResearchNFT(uint256 _tokenId, address _to) external {
        transferFrom(msg.sender, _to, _tokenId);
        emit ResearchNFTTransferred(_tokenId, msg.sender, _to);
    }

    /// @notice Retrieves the owner of a Research NFT.
    /// @param _tokenId The ID of the NFT.
    /// @return The owner address.
    function getResearchNFTOwner(uint256 _tokenId) external view returns (address) {
        return ownerOf(_tokenId);
    }

    // -------------------------------------------------------------------------
    // 8. Governance & Administration
    // -------------------------------------------------------------------------

    /// @notice Allows researchers/community members to propose changes to the DARO governance.
    /// @param _description Description of the governance change proposal.
    /// @param _calldata The calldata to execute the governance change if approved.
    function proposeGovernanceChange(string memory _description, bytes memory _calldata) external onlyResearcher whenNotPaused {
        _governanceProposalIds.increment();
        uint256 proposalId = _governanceProposalIds.current();
        governanceProposals[proposalId] = GovernanceProposal({
            id: proposalId,
            proposer: msg.sender,
            description: _description,
            calldataData: _calldata,
            status: GovernanceProposalStatus.Pending,
            yesVotes: 0,
            noVotes: 0,
            votingDeadline: block.timestamp + governanceVotingDurationDays * 1 days
        });
        emit GovernanceProposalCreated(proposalId, msg.sender, _description);
    }

    /// @notice Allows registered researchers to vote on a governance change proposal.
    /// @param _proposalId The ID of the governance proposal.
    /// @param _support True to support the change, false to oppose.
    function voteOnGovernanceChange(uint256 _proposalId, bool _support) external onlyResearcher whenNotPaused {
        GovernanceProposal storage proposal = governanceProposals[_proposalId];
        require(proposal.status == GovernanceProposalStatus.Pending, "Voting can only happen in Pending status.");
        require(block.timestamp <= proposal.votingDeadline, "Governance voting deadline expired.");

        if (_support) {
            proposal.yesVotes++;
        } else {
            proposal.noVotes++;
        }
        emit GovernanceVoteCast(_proposalId, msg.sender, _support);

        uint256 totalRegisteredResearchers = 0; // In a real DAO, you'd track registered researchers more effectively.
        // For simplicity, we'll estimate total registered researchers by iterating through researcherProfiles.
        for(uint256 i = 0; i <= _proposalIds.current(); i++){ //Iterate through proposal IDs as a proxy, not ideal in large scale
            if(researchProposals[i].researcher != address(0)){ //A very rough estimate for demonstration only.
                totalRegisteredResearchers++; //This is highly inefficient and inaccurate for large scale, replace with proper researcher counting in real implementation.
            }
        }

        uint256 quorumNeeded = (totalRegisteredResearchers * governanceVoteQuorumPercentage) / 100;
        if (proposal.yesVotes >= quorumNeeded) {
            proposal.status = GovernanceProposalStatus.Active; // Move to active after quorum, can have further execution steps.
            emit GovernanceProposalStatusChanged(_proposalId, GovernanceProposalStatus.Active); // Custom event for governance status changes
        }
    }

    /// @notice Executes an approved governance change proposal. Governance controlled execution.
    /// @param _proposalId The ID of the governance proposal to execute.
    function executeGovernanceChange(uint256 _proposalId) external onlyOwner whenNotPaused {
        GovernanceProposal storage proposal = governanceProposals[_proposalId];
        require(proposal.status == GovernanceProposalStatus.Active, "Governance proposal must be active to execute.");
        proposal.status = GovernanceProposalStatus.Executed;
        emit GovernanceChangeExecuted(_proposalId);

        // Execute the governance change using delegatecall to this contract's address.
        // This is a powerful but potentially risky pattern. Ensure _calldata is carefully validated in a real application.
        (bool success, ) = address(this).delegatecall(proposal.calldataData);
        require(success, "Governance change execution failed.");
    }

    /// @notice Pauses critical contract functions in case of emergency. Owner-only function.
    function pauseContract() external onlyOwner whenNotPaused {
        _pause();
        emit ContractPaused();
    }

    /// @notice Resumes contract operations after pausing. Owner-only function.
    function unpauseContract() external onlyOwner whenPaused {
        _unpause();
        emit ContractUnpaused();
    }

    /// @notice Governance function to extend the funding deadline for a proposal.
    /// @param _proposalId The ID of the proposal.
    /// @param _extensionDays Number of days to extend the deadline by.
    function setFundingDeadlineExtension(uint256 _proposalId, uint256 _extensionDays) external onlyOwner whenProposalFunding(_proposalId) whenNotPaused {
        researchProposals[_proposalId].fundingDeadline += _extensionDays * 1 days;
        emit FundingDeadlineExtended(_proposalId, researchProposals[_proposalId].fundingDeadline);
    }

    // Fallback function to reject direct ETH transfers to the contract (except depositFunds).
    receive() external payable {
        require(msg.sig == bytes4(keccak256("depositFunds()")), "Direct ETH transfer not allowed, use depositFunds().");
    }
}
```