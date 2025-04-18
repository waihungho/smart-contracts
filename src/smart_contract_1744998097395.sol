```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Decentralized Autonomous Research Organization (DARO) Smart Contract
 * @author Gemini
 * @dev This contract implements a Decentralized Autonomous Research Organization (DARO)
 *      with advanced features for managing research proposals, funding, reviews, reputation,
 *      and decentralized collaboration. It aims to be a comprehensive platform for scientific
 *      and technological research within a decentralized ecosystem.
 *
 * **Contract Outline and Function Summary:**
 *
 * **Core Functionality:**
 * 1. **Research Proposal Submission & Management:**
 *    - `submitResearchProposal(string _title, string _description, uint256 _fundingGoal, string _researchPlan)`: Allows researchers to submit new research proposals.
 *    - `acceptResearchProposal(uint256 _proposalId)`:  Admin function to accept a research proposal and make it eligible for funding.
 *    - `rejectResearchProposal(uint256 _proposalId, string _reason)`: Admin function to reject a research proposal with a reason.
 *    - `updateProposalStatus(uint256 _proposalId, ProposalStatus _newStatus)`: Researcher or Admin function to update the status of a proposal (e.g., In Progress, Completed, On Hold).
 *    - `getProposalDetails(uint256 _proposalId)`: Retrieves detailed information about a specific research proposal.
 *    - `listProposalsByStatus(ProposalStatus _status)`: Returns a list of proposal IDs filtered by their status.
 *
 * 2. **Decentralized Funding & Grants:**
 *    - `fundProposal(uint256 _proposalId)`: Allows anyone to contribute funds (ETH) to a research proposal.
 *    - `requestWithdrawal(uint256 _proposalId, uint256 _amount)`: Researcher can request withdrawal of funds for accepted proposals, subject to admin approval.
 *    - `approveWithdrawal(uint256 _proposalId, uint256 _amount)`: Admin function to approve a withdrawal request for a research proposal.
 *    - `getProposalFundingStatus(uint256 _proposalId)`: Returns the current funding status (funded amount, funding goal) of a proposal.
 *
 * 3. **Peer Review & Decentralized Evaluation:**
 *    - `assignReviewers(uint256 _proposalId, address[] memory _reviewers)`: Admin function to assign reviewers to a research proposal.
 *    - `submitReview(uint256 _proposalId, string _reviewText, uint8 _rating)`: Reviewers can submit their reviews and ratings for assigned proposals.
 *    - `getProposalReviews(uint256 _proposalId)`: Retrieves all reviews submitted for a specific proposal.
 *    - `calculateAverageRating(uint256 _proposalId)`: Calculates the average rating of a proposal based on submitted reviews.
 *
 * 4. **Reputation & Contribution Tracking:**
 *    - `earnReputation(address _researcher, uint256 _reputationPoints, string _reason)`: Admin function to award reputation points to researchers for contributions (e.g., successful proposals, high-quality reviews).
 *    - `getResearcherReputation(address _researcher)`: Retrieves the reputation score of a researcher.
 *    - `useReputationForPriority(uint256 _proposalId)`: (Conceptual) - In a more advanced version, reputation could influence proposal visibility or voting weight. (Placeholder function for future expansion).
 *
 * 5. **Decentralized Collaboration & Data Sharing (Conceptual):**
 *    - `submitResearchOutput(uint256 _proposalId, string _outputHash, string _outputDescription)`: Researchers can submit research outputs (e.g., papers, datasets - represented by hashes) linked to their proposals.
 *    - `getResearchOutputs(uint256 _proposalId)`: Retrieves a list of research outputs associated with a proposal.
 *    - `requestDataAccess(uint256 _outputId)`: (Conceptual) -  Future function for managing decentralized access to research data, possibly with access control or payment mechanisms.
 *
 * 6. **Governance & Administration:**
 *    - `setAdmin(address _newAdmin)`: Allows the current admin to change the contract administrator.
 *    - `pauseContract()`: Admin function to pause critical contract functionalities for emergency situations.
 *    - `unpauseContract()`: Admin function to resume contract functionalities after a pause.
 *    - `getContractBalance()`:  Returns the current ETH balance of the contract.
 */

contract DecentralizedAutonomousResearchOrganization {
    // --- Data Structures ---

    enum ProposalStatus {
        Pending,
        Accepted,
        Rejected,
        InProgress,
        Completed,
        OnHold
    }

    struct ResearchProposal {
        uint256 id;
        address researcher;
        string title;
        string description;
        uint256 fundingGoal;
        uint256 fundedAmount;
        string researchPlan;
        ProposalStatus status;
        uint256 submissionTimestamp;
    }

    struct Review {
        uint256 reviewId;
        uint256 proposalId;
        address reviewer;
        string reviewText;
        uint8 rating; // Scale of 1-5 or similar
        uint256 submissionTimestamp;
    }

    struct ResearchOutput {
        uint256 outputId;
        uint256 proposalId;
        string outputHash; // IPFS hash or similar to point to the data
        string outputDescription;
        uint256 submissionTimestamp;
    }

    // --- State Variables ---

    address public admin;
    uint256 public proposalCounter;
    uint256 public reviewCounter;
    uint256 public outputCounter;
    mapping(uint256 => ResearchProposal) public researchProposals;
    mapping(uint256 => Review[]) public proposalReviews;
    mapping(uint256 => ResearchOutput[]) public proposalOutputs;
    mapping(address => uint256) public researcherReputation;
    bool public paused;

    // --- Events ---

    event ProposalSubmitted(uint256 proposalId, address researcher, string title);
    event ProposalAccepted(uint256 proposalId);
    event ProposalRejected(uint256 proposalId, string reason);
    event ProposalStatusUpdated(uint256 proposalId, ProposalStatus newStatus);
    event ProposalFunded(uint256 proposalId, address funder, uint256 amount);
    event WithdrawalRequested(uint256 proposalId, address researcher, uint256 amount);
    event WithdrawalApproved(uint256 proposalId, uint256 amount);
    event ReviewSubmitted(uint256 reviewId, uint256 proposalId, address reviewer);
    event ReputationEarned(address researcher, uint256 reputationPoints, string reason);
    event ResearchOutputSubmitted(uint256 outputId, uint256 proposalId, string outputHash);
    event ContractPaused();
    event ContractUnpaused();
    event AdminChanged(address newAdmin);

    // --- Modifiers ---

    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can perform this action");
        _;
    }

    modifier whenNotPaused() {
        require(!paused, "Contract is paused");
        _;
    }

    // --- Constructor ---

    constructor() {
        admin = msg.sender;
        proposalCounter = 0;
        reviewCounter = 0;
        outputCounter = 0;
        paused = false;
    }

    // --- Governance Functions ---

    /**
     * @dev Sets a new admin for the contract. Only the current admin can call this function.
     * @param _newAdmin The address of the new admin.
     */
    function setAdmin(address _newAdmin) public onlyAdmin {
        require(_newAdmin != address(0), "New admin address cannot be zero address");
        admin = _newAdmin;
        emit AdminChanged(_newAdmin);
    }

    /**
     * @dev Pauses the contract, preventing critical functions from being executed. Only admin can call.
     */
    function pauseContract() public onlyAdmin {
        paused = true;
        emit ContractPaused();
    }

    /**
     * @dev Unpauses the contract, resuming normal functionality. Only admin can call.
     */
    function unpauseContract() public onlyAdmin whenNotPaused {
        paused = false;
        emit ContractUnpaused();
    }

    /**
     * @dev Returns the current ETH balance of the contract.
     * @return The contract's ETH balance.
     */
    function getContractBalance() public view returns (uint256) {
        return address(this).balance;
    }


    // --- Research Proposal Functions ---

    /**
     * @dev Allows researchers to submit a new research proposal.
     * @param _title The title of the research proposal.
     * @param _description A brief description of the research.
     * @param _fundingGoal The target funding amount in wei.
     * @param _researchPlan A detailed research plan or methodology.
     */
    function submitResearchProposal(
        string memory _title,
        string memory _description,
        uint256 _fundingGoal,
        string memory _researchPlan
    ) public whenNotPaused {
        require(bytes(_title).length > 0 && bytes(_title).length <= 200, "Title must be between 1 and 200 characters");
        require(bytes(_description).length > 0 && bytes(_description).length <= 1000, "Description must be between 1 and 1000 characters");
        require(_fundingGoal > 0, "Funding goal must be greater than zero");
        require(bytes(_researchPlan).length > 0, "Research plan cannot be empty");

        proposalCounter++;
        researchProposals[proposalCounter] = ResearchProposal({
            id: proposalCounter,
            researcher: msg.sender,
            title: _title,
            description: _description,
            fundingGoal: _fundingGoal,
            fundedAmount: 0,
            researchPlan: _researchPlan,
            status: ProposalStatus.Pending,
            submissionTimestamp: block.timestamp
        });

        emit ProposalSubmitted(proposalCounter, msg.sender, _title);
    }

    /**
     * @dev Admin function to accept a research proposal and make it eligible for funding.
     * @param _proposalId The ID of the proposal to accept.
     */
    function acceptResearchProposal(uint256 _proposalId) public onlyAdmin whenNotPaused {
        require(researchProposals[_proposalId].id == _proposalId, "Proposal ID does not exist");
        require(researchProposals[_proposalId].status == ProposalStatus.Pending, "Proposal must be in Pending status");

        researchProposals[_proposalId].status = ProposalStatus.Accepted;
        emit ProposalAccepted(_proposalId);
    }

    /**
     * @dev Admin function to reject a research proposal with a reason.
     * @param _proposalId The ID of the proposal to reject.
     * @param _reason The reason for rejection.
     */
    function rejectResearchProposal(uint256 _proposalId, string memory _reason) public onlyAdmin whenNotPaused {
        require(researchProposals[_proposalId].id == _proposalId, "Proposal ID does not exist");
        require(researchProposals[_proposalId].status == ProposalStatus.Pending, "Proposal must be in Pending status");
        require(bytes(_reason).length > 0 && bytes(_reason).length <= 500, "Rejection reason must be between 1 and 500 characters");

        researchProposals[_proposalId].status = ProposalStatus.Rejected;
        emit ProposalRejected(_proposalId, _reason);
    }

    /**
     * @dev Allows researcher or admin to update the status of a proposal.
     * @param _proposalId The ID of the proposal to update.
     * @param _newStatus The new status to set for the proposal.
     */
    function updateProposalStatus(uint256 _proposalId, ProposalStatus _newStatus) public whenNotPaused {
        require(researchProposals[_proposalId].id == _proposalId, "Proposal ID does not exist");
        require(msg.sender == researchProposals[_proposalId].researcher || msg.sender == admin, "Only researcher or admin can update status");

        researchProposals[_proposalId].status = _newStatus;
        emit ProposalStatusUpdated(_proposalId, _newStatus);
    }

    /**
     * @dev Retrieves detailed information about a specific research proposal.
     * @param _proposalId The ID of the proposal to retrieve.
     * @return ResearchProposal struct containing proposal details.
     */
    function getProposalDetails(uint256 _proposalId) public view returns (ResearchProposal memory) {
        require(researchProposals[_proposalId].id == _proposalId, "Proposal ID does not exist");
        return researchProposals[_proposalId];
    }

    /**
     * @dev Returns a list of proposal IDs filtered by their status.
     * @param _status The status to filter by.
     * @return An array of proposal IDs with the specified status.
     */
    function listProposalsByStatus(ProposalStatus _status) public view returns (uint256[] memory) {
        uint256[] memory proposalIds = new uint256[](proposalCounter); // Max size, could be optimized in production
        uint256 count = 0;
        for (uint256 i = 1; i <= proposalCounter; i++) {
            if (researchProposals[i].status == _status) {
                proposalIds[count] = i;
                count++;
            }
        }
        // Resize array to actual count
        uint256[] memory result = new uint256[](count);
        for (uint256 i = 0; i < count; i++) {
            result[i] = proposalIds[i];
        }
        return result;
    }


    // --- Funding Functions ---

    /**
     * @dev Allows anyone to contribute funds (ETH) to an accepted research proposal.
     * @param _proposalId The ID of the proposal to fund.
     */
    function fundProposal(uint256 _proposalId) public payable whenNotPaused {
        require(researchProposals[_proposalId].id == _proposalId, "Proposal ID does not exist");
        require(researchProposals[_proposalId].status == ProposalStatus.Accepted || researchProposals[_proposalId].status == ProposalStatus.InProgress, "Proposal must be Accepted or InProgress to receive funding");
        require(researchProposals[_proposalId].fundedAmount + msg.value <= researchProposals[_proposalId].fundingGoal, "Funding exceeds funding goal");

        researchProposals[_proposalId].fundedAmount += msg.value;
        emit ProposalFunded(_proposalId, msg.sender, msg.value);
    }

    /**
     * @dev Researcher can request withdrawal of funds for accepted proposals, subject to admin approval.
     * @param _proposalId The ID of the proposal to request withdrawal for.
     * @param _amount The amount to withdraw in wei.
     */
    function requestWithdrawal(uint256 _proposalId, uint256 _amount) public whenNotPaused {
        require(researchProposals[_proposalId].id == _proposalId, "Proposal ID does not exist");
        require(msg.sender == researchProposals[_proposalId].researcher, "Only researcher can request withdrawal");
        require(researchProposals[_proposalId].fundedAmount >= _amount, "Requested withdrawal amount exceeds funded amount");
        require(_amount > 0, "Withdrawal amount must be greater than zero");

        emit WithdrawalRequested(_proposalId, msg.sender, _amount);
        // Admin will manually call approveWithdrawal after verification (e.g., milestones reached)
    }

    /**
     * @dev Admin function to approve a withdrawal request and send funds to the researcher.
     * @param _proposalId The ID of the proposal for withdrawal approval.
     * @param _amount The amount to approve for withdrawal in wei.
     */
    function approveWithdrawal(uint256 _proposalId, uint256 _amount) public onlyAdmin whenNotPaused {
        require(researchProposals[_proposalId].id == _proposalId, "Proposal ID does not exist");
        require(researchProposals[_proposalId].fundedAmount >= _amount, "Withdrawal amount exceeds funded amount");
        require(address(this).balance >= _amount, "Contract balance is insufficient for withdrawal");

        payable(researchProposals[_proposalId].researcher).transfer(_amount);
        researchProposals[_proposalId].fundedAmount -= _amount;
        emit WithdrawalApproved(_proposalId, _amount);
    }

    /**
     * @dev Returns the current funding status (funded amount, funding goal) of a proposal.
     * @param _proposalId The ID of the proposal.
     * @return Funded amount and funding goal for the proposal.
     */
    function getProposalFundingStatus(uint256 _proposalId) public view returns (uint256 fundedAmount, uint256 fundingGoal) {
        require(researchProposals[_proposalId].id == _proposalId, "Proposal ID does not exist");
        return (researchProposals[_proposalId].fundedAmount, researchProposals[_proposalId].fundingGoal);
    }


    // --- Peer Review Functions ---

    /**
     * @dev Admin function to assign reviewers to a research proposal.
     * @param _proposalId The ID of the proposal to assign reviewers to.
     * @param _reviewers An array of addresses to assign as reviewers.
     */
    function assignReviewers(uint256 _proposalId, address[] memory _reviewers) public onlyAdmin whenNotPaused {
        require(researchProposals[_proposalId].id == _proposalId, "Proposal ID does not exist");
        // In a real-world scenario, more sophisticated reviewer selection logic might be implemented
        // (e.g., based on expertise, reputation, availability, etc.)
        // For simplicity, this function just allows admin to assign addresses.
        // Further logic to track assigned reviewers and prevent duplicate reviews could be added.
    }

    /**
     * @dev Reviewers can submit their reviews and ratings for assigned proposals.
     * @param _proposalId The ID of the proposal being reviewed.
     * @param _reviewText The text of the review.
     * @param _rating A rating for the proposal (e.g., 1-5).
     */
    function submitReview(uint256 _proposalId, string memory _reviewText, uint8 _rating) public whenNotPaused {
        require(researchProposals[_proposalId].id == _proposalId, "Proposal ID does not exist");
        // In a real-world scenario, check if msg.sender is in the list of assigned reviewers for _proposalId
        require(bytes(_reviewText).length > 0 && bytes(_reviewText).length <= 2000, "Review text must be between 1 and 2000 characters");
        require(_rating >= 1 && _rating <= 5, "Rating must be between 1 and 5"); // Example rating scale

        reviewCounter++;
        proposalReviews[_proposalId].push(Review({
            reviewId: reviewCounter,
            proposalId: _proposalId,
            reviewer: msg.sender,
            reviewText: _reviewText,
            rating: _rating,
            submissionTimestamp: block.timestamp
        }));

        emit ReviewSubmitted(reviewCounter, _proposalId, msg.sender);
    }

    /**
     * @dev Retrieves all reviews submitted for a specific proposal.
     * @param _proposalId The ID of the proposal to get reviews for.
     * @return An array of Review structs for the proposal.
     */
    function getProposalReviews(uint256 _proposalId) public view returns (Review[] memory) {
        require(researchProposals[_proposalId].id == _proposalId, "Proposal ID does not exist");
        return proposalReviews[_proposalId];
    }

    /**
     * @dev Calculates the average rating of a proposal based on submitted reviews.
     * @param _proposalId The ID of the proposal to calculate the average rating for.
     * @return The average rating (can be scaled up for integer representation, e.g., average * 100).
     */
    function calculateAverageRating(uint256 _proposalId) public view returns (uint256 averageRating) {
        require(researchProposals[_proposalId].id == _proposalId, "Proposal ID does not exist");
        Review[] memory reviews = proposalReviews[_proposalId];
        if (reviews.length == 0) {
            return 0; // No reviews yet
        }

        uint256 totalRating = 0;
        for (uint256 i = 0; i < reviews.length; i++) {
            totalRating += reviews[i].rating;
        }
        // Return average rating scaled by 100 for integer representation (e.g., 3.5 becomes 350)
        return (totalRating * 100) / reviews.length;
    }


    // --- Reputation Functions ---

    /**
     * @dev Admin function to award reputation points to researchers for contributions.
     * @param _researcher The address of the researcher to award reputation to.
     * @param _reputationPoints The number of reputation points to award.
     * @param _reason The reason for awarding reputation points.
     */
    function earnReputation(address _researcher, uint256 _reputationPoints, string memory _reason) public onlyAdmin whenNotPaused {
        require(_researcher != address(0), "Researcher address cannot be zero address");
        require(_reputationPoints > 0, "Reputation points must be greater than zero");
        require(bytes(_reason).length > 0 && bytes(_reason).length <= 500, "Reputation reason must be between 1 and 500 characters");

        researcherReputation[_researcher] += _reputationPoints;
        emit ReputationEarned(_researcher, _reputationPoints, _reason);
    }

    /**
     * @dev Retrieves the reputation score of a researcher.
     * @param _researcher The address of the researcher.
     * @return The reputation score of the researcher.
     */
    function getResearcherReputation(address _researcher) public view returns (uint256) {
        return researcherReputation[_researcher];
    }

    /**
     * @dev (Conceptual) - Placeholder for future function to use reputation for proposal priority or voting weight.
     * @param _proposalId The ID of the proposal.
     */
    function useReputationForPriority(uint256 _proposalId) public pure {
        // Example: In a voting system, higher reputation could give more voting power.
        // This function is just a placeholder to illustrate the concept.
        // Implementation would depend on the specific mechanism (e.g., voting contract).
        (void _proposalId;); // To avoid unused parameter warning
        // Placeholder - Future implementation could use researcherReputation to influence proposal priority/visibility.
    }


    // --- Research Output Functions (Conceptual) ---

    /**
     * @dev Researchers can submit research outputs (e.g., papers, datasets - represented by hashes) linked to their proposals.
     * @param _proposalId The ID of the proposal the output is related to.
     * @param _outputHash The hash of the research output (e.g., IPFS hash).
     * @param _outputDescription A description of the research output.
     */
    function submitResearchOutput(uint256 _proposalId, string memory _outputHash, string memory _outputDescription) public whenNotPaused {
        require(researchProposals[_proposalId].id == _proposalId, "Proposal ID does not exist");
        require(msg.sender == researchProposals[_proposalId].researcher, "Only researcher can submit outputs");
        require(bytes(_outputHash).length > 0, "Output hash cannot be empty");
        require(bytes(_outputDescription).length > 0 && bytes(_outputDescription).length <= 1000, "Output description must be between 1 and 1000 characters");
        require(researchProposals[_proposalId].status == ProposalStatus.InProgress || researchProposals[_proposalId].status == ProposalStatus.Completed, "Proposal must be InProgress or Completed to submit output");


        outputCounter++;
        proposalOutputs[_proposalId].push(ResearchOutput({
            outputId: outputCounter,
            proposalId: _proposalId,
            outputHash: _outputHash,
            outputDescription: _outputDescription,
            submissionTimestamp: block.timestamp
        }));

        emit ResearchOutputSubmitted(outputCounter, _proposalId, _outputHash);
    }

    /**
     * @dev Retrieves a list of research outputs associated with a proposal.
     * @param _proposalId The ID of the proposal to get outputs for.
     * @return An array of ResearchOutput structs for the proposal.
     */
    function getResearchOutputs(uint256 _proposalId) public view returns (ResearchOutput[] memory) {
        require(researchProposals[_proposalId].id == _proposalId, "Proposal ID does not exist");
        return proposalOutputs[_proposalId];
    }

    /**
     * @dev (Conceptual) - Future function for managing decentralized access to research data.
     * @param _outputId The ID of the research output.
     */
    function requestDataAccess(uint256 _outputId) public pure {
        // Placeholder for future access control mechanisms for research data.
        // Could involve payment, permissions, decentralized identity, etc.
        (void _outputId;); // To avoid unused parameter warning
        // Future implementation could handle requests for access to research outputs,
        // potentially with access control or payment mechanisms.
    }
}
```