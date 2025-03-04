```solidity
/**
 * @title Decentralized Autonomous Research Organization (DARO) Smart Contract
 * @author Bard (AI Assistant)
 * @dev A smart contract for a Decentralized Autonomous Research Organization (DARO).
 *      This contract facilitates the entire lifecycle of research proposals, funding, peer review, collaboration,
 *      and intellectual property management in a decentralized and transparent manner.
 *
 * **Outline & Function Summary:**
 *
 * **I. Core Research Proposal Management:**
 *   1. `submitResearchProposal(string _title, string _description, string _researchPlan, uint256 _fundingGoal, string[] _milestones)`: Allows researchers to submit research proposals with details, funding goals, and milestones.
 *   2. `getResearchProposal(uint256 _proposalId)`: Retrieves detailed information about a specific research proposal.
 *   3. `updateResearchProposal(uint256 _proposalId, string _description, string _researchPlan, string[] _milestones)`: Allows researchers to update certain aspects of their proposals before funding.
 *   4. `cancelResearchProposal(uint256 _proposalId)`: Allows researchers to cancel their proposal if needed.
 *   5. `listResearchProposals()`: Returns a list of all active research proposal IDs.
 *   6. `listProposalsByStatus(ProposalStatus _status)`: Returns a list of proposal IDs filtered by status (e.g., Pending, Funded, Completed, Rejected).
 *
 * **II. Funding and Financial Management:**
 *   7. `fundResearchProposal(uint256 _proposalId)`: Allows members to contribute funds to a research proposal.
 *   8. `withdrawFunds(uint256 _proposalId)`: Allows researchers to withdraw funds in stages based on approved milestones.
 *   9. `refundUnusedFunds(uint256 _proposalId)`: Returns any unused funds to contributors if a proposal is cancelled or not fully funded.
 *   10. `getProposalFundingStatus(uint256 _proposalId)`: Returns the current funding status and amount raised for a proposal.
 *
 * **III. Peer Review and Evaluation:**
 *   11. `requestReview(uint256 _proposalId, address[] _reviewers)`: Initiates a peer review process by assigning reviewers to a proposal.
 *   12. `submitReview(uint256 _proposalId, string _reviewText, uint8 _rating)`: Allows assigned reviewers to submit their reviews and ratings for a proposal.
 *   13. `getProposalReviews(uint256 _proposalId)`: Retrieves all reviews associated with a specific research proposal.
 *   14. `calculateAverageRating(uint256 _proposalId)`: Calculates the average rating of a proposal based on submitted reviews.
 *
 * **IV. Collaboration and Researcher Management:**
 *   15. `addResearcher(address _researcherAddress, string _researcherProfile)`: Allows the DAO to add new researchers to the platform.
 *   16. `getResearcherProfile(address _researcherAddress)`: Retrieves the profile information of a registered researcher.
 *   17. `requestCollaboration(uint256 _proposalId, address _collaboratorAddress)`: Allows researchers to request collaboration on a proposal.
 *   18. `acceptCollaborationRequest(uint256 _proposalId, address _collaboratorAddress)`: Allows researchers to accept collaboration requests.
 *   19. `listProposalCollaborators(uint256 _proposalId)`: Returns a list of researchers collaborating on a specific proposal.
 *
 * **V. Intellectual Property and Results Management:**
 *   20. `submitResearchResults(uint256 _proposalId, string _resultsData, string _ipLicense)`: Allows researchers to submit their research results and specify an IP license (e.g., Creative Commons).
 *   21. `getResearchResults(uint256 _proposalId)`: Allows access to the submitted research results and IP license for a proposal (with potential access control based on license).
 *   22. `recordIntellectualProperty(uint256 _proposalId, string _ipHash)`:  Records a hash of the intellectual property (e.g., a scientific paper) on-chain for timestamping and verification.
 *
 * **VI. Governance and DAO Management (Basic):**
 *   23. `addMember(address _memberAddress)`:  Allows the DAO owner to add members with governance rights (basic example, more complex governance can be built).
 *   24. `removeMember(address _memberAddress)`: Allows the DAO owner to remove members.
 *   25. `isMember(address _address)`: Checks if an address is a DAO member.
 *   26. `setReviewQuorum(uint8 _quorum)`: Allows DAO owner to set the minimum number of reviews required for a proposal.
 *   27. `setFundingThreshold(uint256 _threshold)`: Allows DAO owner to set a funding threshold for automatic proposal approval.
 */
pragma solidity ^0.8.0;

contract DecentralizedAutonomousResearchOrganization {

    enum ProposalStatus { Pending, Review, Funded, InProgress, Completed, Rejected, Cancelled }
    enum ReviewStatus { Pending, Submitted }

    struct ResearchProposal {
        uint256 id;
        address researcher;
        string title;
        string description;
        string researchPlan;
        uint256 fundingGoal;
        uint256 fundsRaised;
        string[] milestones;
        ProposalStatus status;
        uint256 submissionTimestamp;
        address[] collaborators;
        string resultsData;
        string ipLicense;
        string ipHash; // Hash of IP document
    }

    struct Review {
        address reviewer;
        uint256 proposalId;
        string reviewText;
        uint8 rating; // e.g., 1-5 scale
        ReviewStatus status;
        uint256 submissionTimestamp;
    }

    struct ResearcherProfile {
        string profileData; // Could be IPFS hash or on-chain data
        uint256 registrationTimestamp;
    }

    mapping(uint256 => ResearchProposal) public researchProposals;
    mapping(uint256 => Review[]) public proposalReviews;
    mapping(address => ResearcherProfile) public researcherProfiles;
    mapping(address => bool) public members; // Basic DAO membership

    uint256 public proposalCounter;
    uint8 public reviewQuorum = 3; // Minimum reviewers required
    uint256 public fundingThreshold = 10 ether; // Funding threshold for auto-approval (example)
    address public owner;

    event ProposalSubmitted(uint256 proposalId, address researcher, string title);
    event ProposalUpdated(uint256 proposalId, string title);
    event ProposalCancelled(uint256 proposalId);
    event ProposalFunded(uint256 proposalId, uint256 amount);
    event FundsWithdrawn(uint256 proposalId, uint256 amount, uint256 milestoneIndex);
    event FundsRefunded(uint256 proposalId, uint256 amount);
    event ReviewRequested(uint256 proposalId, address[] reviewers);
    event ReviewSubmitted(uint256 proposalId, address reviewer);
    event CollaborationRequested(uint256 proposalId, address requester, address collaborator);
    event CollaborationAccepted(uint256 proposalId, address researcher, address collaborator);
    event ResearchResultsSubmitted(uint256 proposalId, string ipLicense);
    event IntellectualPropertyRecorded(uint256 proposalId, string ipHash);
    event ResearcherAdded(address researcherAddress);
    event MemberAdded(address memberAddress);
    event MemberRemoved(address memberAddress);
    event ReviewQuorumChanged(uint8 newQuorum);
    event FundingThresholdChanged(uint256 newThreshold);


    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can perform this action");
        _;
    }

    modifier onlyMember() {
        require(members[msg.sender], "Only members can perform this action");
        _;
    }

    modifier onlyResearcher(uint256 _proposalId) {
        require(researchProposals[_proposalId].researcher == msg.sender, "Only proposal researcher can perform this action");
        _;
    }

    modifier proposalExists(uint256 _proposalId) {
        require(researchProposals[_proposalId].id != 0, "Proposal does not exist");
        _;
    }

    modifier validProposalStatus(uint256 _proposalId, ProposalStatus _status) {
        require(researchProposals[_proposalId].status == _status, "Invalid proposal status");
        _;
    }

    modifier validReviewer(uint256 _proposalId) {
        bool isReviewer = false;
        for (uint256 i = 0; i < proposalReviews[_proposalId].length; i++) {
            if (proposalReviews[_proposalId][i].reviewer == msg.sender && proposalReviews[_proposalId][i].status == ReviewStatus.Pending) {
                isReviewer = true;
                break;
            }
        }
        require(isReviewer, "You are not assigned as a reviewer for this proposal or review already submitted.");
        _;
    }


    constructor() {
        owner = msg.sender;
    }

    /**
     * @dev Allows the contract owner to add a new member to the DAO.
     * @param _memberAddress The address to add as a member.
     */
    function addMember(address _memberAddress) external onlyOwner {
        members[_memberAddress] = true;
        emit MemberAdded(_memberAddress);
    }

    /**
     * @dev Allows the contract owner to remove a member from the DAO.
     * @param _memberAddress The address to remove.
     */
    function removeMember(address _memberAddress) external onlyOwner {
        members[_memberAddress] = false;
        emit MemberRemoved(_memberAddress);
    }

    /**
     * @dev Checks if an address is a member of the DAO.
     * @param _address The address to check.
     * @return bool True if the address is a member, false otherwise.
     */
    function isMember(address _address) external view returns (bool) {
        return members[_address];
    }

    /**
     * @dev Allows the DAO owner to set the minimum number of reviews required for a proposal.
     * @param _quorum The new review quorum value.
     */
    function setReviewQuorum(uint8 _quorum) external onlyOwner {
        reviewQuorum = _quorum;
        emit ReviewQuorumChanged(_quorum);
    }

    /**
     * @dev Allows the DAO owner to set the funding threshold for automatic proposal approval.
     * @param _threshold The new funding threshold value in wei.
     */
    function setFundingThreshold(uint256 _threshold) external onlyOwner {
        fundingThreshold = _threshold;
        emit FundingThresholdChanged(_threshold);
    }


    /**
     * @dev Allows researchers to submit a new research proposal.
     * @param _title The title of the research proposal.
     * @param _description A brief description of the research.
     * @param _researchPlan Detailed research plan.
     * @param _fundingGoal The funding goal for the proposal in wei.
     * @param _milestones Array of milestones for the research project.
     */
    function submitResearchProposal(
        string memory _title,
        string memory _description,
        string memory _researchPlan,
        uint256 _fundingGoal,
        string[] memory _milestones
    ) external {
        proposalCounter++;
        researchProposals[proposalCounter] = ResearchProposal({
            id: proposalCounter,
            researcher: msg.sender,
            title: _title,
            description: _description,
            researchPlan: _researchPlan,
            fundingGoal: _fundingGoal,
            fundsRaised: 0,
            milestones: _milestones,
            status: ProposalStatus.Pending,
            submissionTimestamp: block.timestamp,
            collaborators: new address[](0),
            resultsData: "",
            ipLicense: "",
            ipHash: ""
        });
        emit ProposalSubmitted(proposalCounter, msg.sender, _title);
    }

    /**
     * @dev Retrieves detailed information about a specific research proposal.
     * @param _proposalId The ID of the research proposal.
     * @return ResearchProposal struct containing proposal details.
     */
    function getResearchProposal(uint256 _proposalId) external view proposalExists(_proposalId) returns (ResearchProposal memory) {
        return researchProposals[_proposalId];
    }

    /**
     * @dev Allows researchers to update certain aspects of their proposal before funding.
     * @param _proposalId The ID of the proposal to update.
     * @param _description Updated description.
     * @param _researchPlan Updated research plan.
     * @param _milestones Updated list of milestones.
     */
    function updateResearchProposal(
        uint256 _proposalId,
        string memory _description,
        string memory _researchPlan,
        string[] memory _milestones
    ) external onlyResearcher(_proposalId) validProposalStatus(_proposalId, ProposalStatus.Pending) {
        researchProposals[_proposalId].description = _description;
        researchProposals[_proposalId].researchPlan = _researchPlan;
        researchProposals[_proposalId].milestones = _milestones;
        emit ProposalUpdated(_proposalId, researchProposals[_proposalId].title);
    }

    /**
     * @dev Allows researchers to cancel their proposal if needed before funding.
     * @param _proposalId The ID of the proposal to cancel.
     */
    function cancelResearchProposal(uint256 _proposalId) external onlyResearcher(_proposalId) validProposalStatus(_proposalId, ProposalStatus.Pending) {
        researchProposals[_proposalId].status = ProposalStatus.Cancelled;
        refundUnusedFunds(_proposalId); // Return any raised funds
        emit ProposalCancelled(_proposalId);
    }

    /**
     * @dev Lists IDs of all active research proposals (Pending, Review, Funded, InProgress).
     * @return uint256[] Array of proposal IDs.
     */
    function listResearchProposals() external view returns (uint256[] memory) {
        uint256[] memory proposalIds = new uint256[](proposalCounter);
        uint256 count = 0;
        for (uint256 i = 1; i <= proposalCounter; i++) {
            if (researchProposals[i].id != 0 && (researchProposals[i].status == ProposalStatus.Pending || researchProposals[i].status == ProposalStatus.Review || researchProposals[i].status == ProposalStatus.Funded || researchProposals[i].status == ProposalStatus.InProgress)) {
                proposalIds[count] = i;
                count++;
            }
        }
        // Resize array to actual number of proposals
        uint256[] memory result = new uint256[](count);
        for(uint256 i=0; i<count; i++){
            result[i] = proposalIds[i];
        }
        return result;
    }

    /**
     * @dev Lists proposal IDs by a specific status.
     * @param _status The status to filter by.
     * @return uint256[] Array of proposal IDs with the given status.
     */
    function listProposalsByStatus(ProposalStatus _status) external view returns (uint256[] memory) {
        uint256[] memory proposalIds = new uint256[](proposalCounter);
        uint256 count = 0;
        for (uint256 i = 1; i <= proposalCounter; i++) {
            if (researchProposals[i].status == _status) {
                proposalIds[count] = i;
                count++;
            }
        }
        // Resize array to actual number of proposals
        uint256[] memory result = new uint256[](count);
        for(uint256 i=0; i<count; i++){
            result[i] = proposalIds[i];
        }
        return result;
    }

    /**
     * @dev Allows members to contribute funds to a research proposal.
     * @param _proposalId The ID of the proposal to fund.
     */
    function fundResearchProposal(uint256 _proposalId) external payable onlyMember proposalExists(_proposalId) validProposalStatus(_proposalId, ProposalStatus.Pending) {
        ResearchProposal storage proposal = researchProposals[_proposalId];
        proposal.fundsRaised += msg.value;
        emit ProposalFunded(_proposalId, msg.value);

        if (proposal.fundsRaised >= proposal.fundingGoal || proposal.fundsRaised >= fundingThreshold) { // Example auto-approval based on funding or threshold
            proposal.status = ProposalStatus.Funded;
        } else if (proposal.status != ProposalStatus.Review) {
            proposal.status = ProposalStatus.Review; // Move to review if not fully funded but received initial funds
            requestReview(_proposalId, new address[](0)); // Initiate review process (reviewers can be assigned later or dynamically by DAO)
        }
    }

    /**
     * @dev Allows researchers to withdraw funds based on approved milestones.
     * @param _proposalId The ID of the proposal.
     * @param _milestoneIndex The index of the milestone to claim funds for.
     */
    function withdrawFunds(uint256 _proposalId, uint256 _milestoneIndex) external onlyResearcher(_proposalId) validProposalStatus(_proposalId, ProposalStatus.Funded) {
        ResearchProposal storage proposal = researchProposals[_proposalId];
        require(_milestoneIndex < proposal.milestones.length, "Invalid milestone index");
        // In a real-world scenario, milestone approval would be more sophisticated (e.g., DAO voting, review process)
        // For this example, we are assuming milestones are auto-approved for simplicity.
        // **Security Note:**  Real-world implementation needs robust milestone approval mechanism.

        uint256 amountToWithdraw = proposal.fundingGoal / proposal.milestones.length; // Example: Equal distribution per milestone
        require(proposal.fundsRaised >= amountToWithdraw, "Insufficient funds available for withdrawal.");
        payable(proposal.researcher).transfer(amountToWithdraw);
        proposal.fundsRaised -= amountToWithdraw; // Deduct withdrawn amount
        proposal.status = ProposalStatus.InProgress; // Move to in progress after first withdrawal (simplification)
        emit FundsWithdrawn(_proposalId, amountToWithdraw, _milestoneIndex);
    }

    /**
     * @dev Refunds any unused funds to contributors if a proposal is cancelled or not fully funded.
     * @param _proposalId The ID of the proposal.
     */
    function refundUnusedFunds(uint256 _proposalId) internal proposalExists(_proposalId) {
        ResearchProposal storage proposal = researchProposals[_proposalId];
        if (proposal.fundsRaised > 0) {
            // In a real system, you would need to track individual contributors and their contributions
            // For simplicity, this example just refunds to the proposal researcher (assuming they are the initial funder or representative)
            // **Important:**  Proper refund mechanism requires tracking contributors.
            payable(proposal.researcher).transfer(proposal.fundsRaised);
            emit FundsRefunded(_proposalId, proposal.fundsRaised);
            proposal.fundsRaised = 0;
        }
    }

    /**
     * @dev Gets the current funding status and amount raised for a proposal.
     * @param _proposalId The ID of the proposal.
     * @return uint256 Amount of funds raised.
     * @return uint256 Funding goal.
     * @return ProposalStatus Current proposal status.
     */
    function getProposalFundingStatus(uint256 _proposalId) external view proposalExists(_proposalId) returns (uint256, uint256, ProposalStatus) {
        return (researchProposals[_proposalId].fundsRaised, researchProposals[_proposalId].fundingGoal, researchProposals[_proposalId].status);
    }

    /**
     * @dev Initiates a peer review process for a proposal by assigning reviewers.
     * @param _proposalId The ID of the proposal to be reviewed.
     * @param _reviewers An array of addresses to be assigned as reviewers.
     */
    function requestReview(uint256 _proposalId, address[] memory _reviewers) public onlyMember proposalExists(_proposalId) validProposalStatus(_proposalId, ProposalStatus.Review) {
        require(_reviewers.length >= reviewQuorum, "Not enough reviewers provided to meet quorum.");
        delete proposalReviews[_proposalId]; // Clear existing reviews if re-reviewing.
        for (uint256 i = 0; i < _reviewers.length; i++) {
            proposalReviews[_proposalId].push(Review({
                reviewer: _reviewers[i],
                proposalId: _proposalId,
                reviewText: "",
                rating: 0,
                status: ReviewStatus.Pending,
                submissionTimestamp: 0
            }));
        }
        emit ReviewRequested(_proposalId, _reviewers);
    }

    /**
     * @dev Allows assigned reviewers to submit their review and rating for a proposal.
     * @param _proposalId The ID of the proposal being reviewed.
     * @param _reviewText The text of the review.
     * @param _rating A rating for the proposal (e.g., 1-5).
     */
    function submitReview(uint256 _proposalId, string memory _reviewText, uint8 _rating) external validReviewer(_proposalId) proposalExists(_proposalId) validProposalStatus(_proposalId, ProposalStatus.Review) {
        Review[] storage reviews = proposalReviews[_proposalId];
        for (uint256 i = 0; i < reviews.length; i++) {
            if (reviews[i].reviewer == msg.sender && reviews[i].status == ReviewStatus.Pending) {
                reviews[i].reviewText = _reviewText;
                reviews[i].rating = _rating;
                reviews[i].status = ReviewStatus.Submitted;
                reviews[i].submissionTimestamp = block.timestamp;
                emit ReviewSubmitted(_proposalId, msg.sender);
                break;
            }
        }

        // Check if enough reviews are submitted to move to Funded/Rejected
        uint8 submittedReviewsCount = 0;
        for (uint256 i = 0; i < reviews.length; i++) {
            if (reviews[i].status == ReviewStatus.Submitted) {
                submittedReviewsCount++;
            }
        }

        if (submittedReviewsCount >= reviewQuorum) {
            uint8 averageRating = calculateAverageRating(_proposalId);
            if (averageRating >= 3) { // Example: Approve if average rating is 3 or higher
                researchProposals[_proposalId].status = ProposalStatus.Funded;
            } else {
                researchProposals[_proposalId].status = ProposalStatus.Rejected;
            }
        }
    }

    /**
     * @dev Retrieves all reviews associated with a specific research proposal.
     * @param _proposalId The ID of the proposal.
     * @return Review[] Array of Review structs.
     */
    function getProposalReviews(uint256 _proposalId) external view proposalExists(_proposalId) returns (Review[] memory) {
        return proposalReviews[_proposalId];
    }

    /**
     * @dev Calculates the average rating of a proposal based on submitted reviews.
     * @param _proposalId The ID of the proposal.
     * @return uint8 Average rating (rounded down to nearest integer).
     */
    function calculateAverageRating(uint256 _proposalId) public view proposalExists(_proposalId) returns (uint8) {
        uint256 totalRating = 0;
        uint8 submittedReviewsCount = 0;
        Review[] memory reviews = proposalReviews[_proposalId];
        for (uint256 i = 0; i < reviews.length; i++) {
            if (reviews[i].status == ReviewStatus.Submitted) {
                totalRating += reviews[i].rating;
                submittedReviewsCount++;
            }
        }
        if (submittedReviewsCount == 0) {
            return 0;
        }
        return uint8(totalRating / submittedReviewsCount);
    }

    /**
     * @dev Allows the DAO to add new researchers to the platform.
     * @param _researcherAddress The address of the researcher to add.
     * @param _researcherProfile Profile information for the researcher (e.g., IPFS hash, on-chain data).
     */
    function addResearcher(address _researcherAddress, string memory _researcherProfile) external onlyMember {
        researcherProfiles[_researcherAddress] = ResearcherProfile({
            profileData: _researcherProfile,
            registrationTimestamp: block.timestamp
        });
        emit ResearcherAdded(_researcherAddress);
    }

    /**
     * @dev Retrieves the profile information of a registered researcher.
     * @param _researcherAddress The address of the researcher.
     * @return ResearcherProfile struct containing profile details.
     */
    function getResearcherProfile(address _researcherAddress) external view returns (ResearcherProfile memory) {
        return researcherProfiles[_researcherAddress];
    }

    /**
     * @dev Allows researchers to request collaboration on a proposal.
     * @param _proposalId The ID of the proposal.
     * @param _collaboratorAddress The address of the researcher to collaborate with.
     */
    function requestCollaboration(uint256 _proposalId, address _collaboratorAddress) external onlyResearcher(_proposalId) proposalExists(_proposalId) validProposalStatus(_proposalId, ProposalStatus.Pending) { // Can request collaboration before funding
        // In a real system, you might want to prevent duplicate requests or add a more sophisticated collaboration management
        emit CollaborationRequested(_proposalId, msg.sender, _collaboratorAddress);
    }

    /**
     * @dev Allows researchers to accept collaboration requests on a proposal.
     * @param _proposalId The ID of the proposal.
     * @param _collaboratorAddress The address of the researcher accepting the collaboration.
     */
    function acceptCollaborationRequest(uint256 _proposalId, address _collaboratorAddress) external proposalExists(_proposalId) validProposalStatus(_proposalId, ProposalStatus.Pending) { // Can accept before funding
        ResearchProposal storage proposal = researchProposals[_proposalId];
        require(proposal.researcher == _collaboratorAddress, "Only the requested collaborator can accept."); // Simple check - can be refined
        bool alreadyCollaborating = false;
        for (uint256 i = 0; i < proposal.collaborators.length; i++) {
            if (proposal.collaborators[i] == msg.sender) {
                alreadyCollaborating = true;
                break;
            }
        }
        require(!alreadyCollaborating, "Already collaborating on this proposal.");

        proposal.collaborators.push(msg.sender);
        emit CollaborationAccepted(_proposalId, proposal.researcher, msg.sender);
    }

    /**
     * @dev Lists all collaborators on a specific research proposal.
     * @param _proposalId The ID of the proposal.
     * @return address[] Array of collaborator addresses.
     */
    function listProposalCollaborators(uint256 _proposalId) external view proposalExists(_proposalId) returns (address[] memory) {
        return researchProposals[_proposalId].collaborators;
    }

    /**
     * @dev Allows researchers to submit their research results and IP license upon completion.
     * @param _proposalId The ID of the proposal.
     * @param _resultsData Data containing the research results (e.g., IPFS hash, on-chain data).
     * @param _ipLicense  The IP license chosen for the research results (e.g., Creative Commons license identifier).
     */
    function submitResearchResults(uint256 _proposalId, string memory _resultsData, string memory _ipLicense) external onlyResearcher(_proposalId) validProposalStatus(_proposalId, ProposalStatus.InProgress) {
        researchProposals[_proposalId].resultsData = _resultsData;
        researchProposals[_proposalId].ipLicense = _ipLicense;
        researchProposals[_proposalId].status = ProposalStatus.Completed;
        emit ResearchResultsSubmitted(_proposalId, _ipLicense);
    }

    /**
     * @dev Allows access to the submitted research results and IP license of a completed proposal.
     * @param _proposalId The ID of the proposal.
     * @return string Research results data.
     * @return string IP license identifier.
     */
    function getResearchResults(uint256 _proposalId) external view proposalExists(_proposalId) returns (string memory, string memory) {
        require(researchProposals[_proposalId].status == ProposalStatus.Completed, "Research is not yet completed."); // Example: Restrict access until completion
        return (researchProposals[_proposalId].resultsData, researchProposals[_proposalId].ipLicense);
    }

    /**
     * @dev Records a hash of the intellectual property document on-chain for timestamping and verification.
     * @param _proposalId The ID of the proposal.
     * @param _ipHash The hash of the IP document (e.g., SHA256 hash of a research paper).
     */
    function recordIntellectualProperty(uint256 _proposalId, string memory _ipHash) external onlyResearcher(_proposalId) validProposalStatus(_proposalId, ProposalStatus.InProgress) { // Can record IP hash before final results submission
        researchProposals[_proposalId].ipHash = _ipHash;
        emit IntellectualPropertyRecorded(_proposalId, _ipHash);
    }
}
```