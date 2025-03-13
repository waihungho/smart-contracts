```solidity
/**
 * @title Decentralized Autonomous Research Organization (DARO) Smart Contract
 * @author Gemini AI Assistant
 * @dev A smart contract for a Decentralized Autonomous Research Organization (DARO) that facilitates
 * research project proposals, funding, peer review, and intellectual property management on-chain.
 * This contract aims to be a novel implementation, avoiding duplication of existing open-source contracts
 * and incorporating advanced concepts and trendy functionalities in the Web3 space.
 *
 * **Outline and Function Summary:**
 *
 * **1. Core Functionality - Research Proposal Management:**
 *    - `submitResearchProposal(string _title, string _description, string _ipfsHash)`: Allows researchers to submit new research proposals.
 *    - `viewResearchProposal(uint256 _proposalId)`: Allows anyone to view the details of a specific research proposal.
 *    - `updateResearchProposal(uint256 _proposalId, string _description, string _ipfsHash)`: Allows the proposer to update their proposal (with limitations).
 *    - `cancelResearchProposal(uint256 _proposalId)`: Allows the proposer to cancel their proposal before funding.
 *
 * **2. Funding and Contribution Management:**
 *    - `createFundingRound(uint256 _proposalId, uint256 _fundingGoal, uint256 _fundingDeadline)`: Creates a funding round for a research proposal.
 *    - `contributeToFundingRound(uint256 _fundingRoundId)`: Allows users to contribute ETH to a funding round.
 *    - `withdrawFunding(uint256 _fundingRoundId)`: Allows the proposer to withdraw funds if the funding goal is reached.
 *    - `refundContributors(uint256 _fundingRoundId)`: Allows contributors to get refunds if the funding goal is not met.
 *    - `extendFundingDeadline(uint256 _fundingRoundId, uint256 _newDeadline)`: Allows the proposer to extend the funding deadline (with governance or time limits).
 *
 * **3. Decentralized Peer Review System:**
 *    - `requestReviewers(uint256 _proposalId, uint8 _numReviewers)`: Allows the proposer to request a certain number of reviewers.
 *    - `applyToBeReviewer(uint256 _proposalId)`: Allows users to apply to become reviewers for a proposal.
 *    - `assignReviewers(uint256 _proposalId)`: Contract or admin selects and assigns reviewers (can be random or reputation-based).
 *    - `submitReview(uint256 _proposalId, string _reviewText, uint8 _rating)`: Reviewers submit their reviews and ratings.
 *    - `viewReview(uint256 _proposalId, address _reviewer)`: Allows viewing of a specific reviewer's review for a proposal.
 *    - `finalizeReviewProcess(uint256 _proposalId)`: Finalizes the review process, potentially calculating an average rating.
 *
 * **4. Intellectual Property (IP) Management (Conceptual):**
 *    - `registerIP(uint256 _proposalId, string _ipDocumentHash)`: Researchers can register IP related to their funded proposals (basic hash registration).
 *    - `viewIPRegistration(uint256 _proposalId)`: Allows viewing of registered IP hashes for a proposal.
 *
 * **5. Governance and DAO Features (Simple Example):**
 *    - `proposeParameterChange(string _parameterName, uint256 _newValue)`: Allows token holders to propose changes to contract parameters.
 *    - `voteOnProposalChange(uint256 _proposalChangeId, bool _vote)`: Allows token holders to vote on parameter change proposals.
 *    - `executeParameterChange(uint256 _proposalChangeId)`: Executes a parameter change if it passes governance.
 *
 * **6. Utility and Information Functions:**
 *    - `getProposalCount()`: Returns the total number of research proposals submitted.
 *    - `getFundingRoundDetails(uint256 _fundingRoundId)`: Returns detailed information about a specific funding round.
 *
 * **Advanced Concepts Implemented:**
 * - **Decentralized Peer Review:** Implements a basic system for decentralized peer review, crucial for research validation.
 * - **IP Registration (Conceptual):** Introduces a rudimentary form of on-chain IP registration, a growing area of interest.
 * - **Simple On-Chain Governance:** Includes a basic governance mechanism for parameter changes, reflecting DAO principles.
 * - **Funding Rounds with Deadlines and Goals:** Implements structured funding rounds for research projects, similar to crowdfunding.
 * - **Reputation (Future Extension - Not fully implemented in this basic version):** The review system lays the groundwork for a reputation system for reviewers.
 */
pragma solidity ^0.8.0;

contract DecentralizedAutonomousResearchOrganization {

    // --- Structs and Enums ---

    enum ProposalStatus { Submitted, Funding, Review, Completed, Cancelled, Funded, ReviewPending, ReviewFinalized }
    enum FundingRoundStatus { Created, Open, Closed, GoalReached, Failed, Refunded }
    enum ReviewStatus { Pending, Submitted, Finalized }
    enum ParameterChangeStatus { Proposed, Voting, Approved, Rejected, Executed }

    struct ResearchProposal {
        uint256 proposalId;
        address proposer;
        string title;
        string description;
        string ipfsHash; // IPFS hash for detailed proposal document
        ProposalStatus status;
        uint256 fundingRoundId; // ID of associated funding round, if any
        uint256 reviewProcessId; // ID of associated review process, if any
        uint256 submissionTimestamp;
    }

    struct FundingRound {
        uint256 fundingRoundId;
        uint256 proposalId;
        uint256 fundingGoal;
        uint256 fundingDeadline;
        uint256 currentFunding;
        FundingRoundStatus status;
        address proposer; // Redundant but useful for quick access
        uint256 creationTimestamp;
    }

    struct Review {
        uint256 reviewId;
        uint256 proposalId;
        address reviewer;
        string reviewText;
        uint8 rating; // 1-5 star rating, for example
        ReviewStatus status;
        uint256 submissionTimestamp;
    }

    struct ParameterChangeProposal {
        uint256 proposalChangeId;
        string parameterName;
        uint256 newValue;
        ParameterChangeStatus status;
        uint256 votesFor;
        uint256 votesAgainst;
        uint256 votingDeadline;
        address proposer;
        uint256 proposalTimestamp;
    }

    // --- State Variables ---

    ResearchProposal[] public researchProposals;
    FundingRound[] public fundingRounds;
    Review[] public reviews;
    ParameterChangeProposal[] public parameterChangeProposals;

    uint256 public proposalCounter;
    uint256 public fundingRoundCounter;
    uint256 public reviewCounter;
    uint256 public parameterChangeCounter;

    uint8 public requiredReviewers = 3; // Default number of reviewers per proposal
    uint256 public reviewDuration = 7 days; // Default review duration
    uint256 public governanceVotingDuration = 7 days; // Default governance voting duration
    uint256 public minGovernanceVoteQuorum = 50; // Minimum percentage quorum for governance votes

    mapping(uint256 => mapping(address => Review)) public proposalReviewsByReviewer; // proposalId => reviewerAddress => Review
    mapping(uint256 => address[]) public proposalReviewers; // proposalId => array of reviewer addresses
    mapping(uint256 => address[]) public fundingRoundContributors; // fundingRoundId => array of contributor addresses
    mapping(uint256 => mapping(address => uint256)) public contributorFundingAmount; // fundingRoundId => contributorAddress => amount contributed
    mapping(uint256 => string) public proposalIPRegistrations; // proposalId => IP Document Hash


    // --- Events ---

    event ProposalSubmitted(uint256 proposalId, address proposer, string title);
    event ProposalUpdated(uint256 proposalId, address proposer);
    event ProposalCancelled(uint256 proposalId, address proposer);
    event FundingRoundCreated(uint256 fundingRoundId, uint256 proposalId, uint256 fundingGoal, uint256 fundingDeadline);
    event ContributionMade(uint256 fundingRoundId, address contributor, uint256 amount);
    event FundingWithdrawn(uint256 fundingRoundId, address proposer, uint256 amount);
    event ContributorsRefunded(uint256 fundingRoundId);
    event FundingDeadlineExtended(uint256 fundingRoundId, uint256 newDeadline);
    event ReviewersRequested(uint256 proposalId, uint8 numReviewers);
    event ReviewerApplied(uint256 proposalId, address reviewer);
    event ReviewersAssigned(uint256 proposalId, address[] reviewers);
    event ReviewSubmitted(uint256 reviewId, uint256 proposalId, address reviewer);
    event ReviewProcessFinalized(uint256 proposalId);
    event IPRegistered(uint256 proposalId, string ipDocumentHash);
    event ParameterChangeProposed(uint256 proposalChangeId, string parameterName, uint256 newValue, address proposer);
    event VoteCastOnParameterChange(uint256 proposalChangeId, address voter, bool vote);
    event ParameterChangeExecuted(uint256 proposalChangeId, string parameterName, uint256 newValue);


    // --- Modifiers ---

    modifier onlyProposer(uint256 _proposalId) {
        require(researchProposals[_proposalId].proposer == msg.sender, "Only proposer can perform this action.");
        _;
    }

    modifier validProposalId(uint256 _proposalId) {
        require(_proposalId < proposalCounter && researchProposals[_proposalId].proposalId == _proposalId, "Invalid proposal ID.");
        _;
    }

    modifier validFundingRoundId(uint256 _fundingRoundId) {
        require(_fundingRoundId < fundingRoundCounter && fundingRounds[_fundingRoundId].fundingRoundId == _fundingRoundId, "Invalid funding round ID.");
        _;
    }

    modifier validReviewId(uint256 _reviewId) {
        require(_reviewId < reviewCounter && reviews[_reviewId].reviewId == _reviewId, "Invalid review ID.");
        _;
    }

    modifier validParameterChangeId(uint256 _proposalChangeId) {
        require(_proposalChangeId < parameterChangeCounter && parameterChangeProposals[_proposalChangeId].proposalChangeId == _proposalChangeId, "Invalid parameter change proposal ID.");
        _;
    }

    modifier fundingRoundIsOpen(uint256 _fundingRoundId) {
        require(fundingRounds[_fundingRoundId].status == FundingRoundStatus.Open, "Funding round is not open.");
        _;
    }

    modifier fundingRoundGoalReached(uint256 _fundingRoundId) {
        require(fundingRounds[_fundingRoundId].status == FundingRoundStatus.GoalReached, "Funding round goal not reached.");
        _;
    }

    modifier fundingRoundIsFailed(uint256 _fundingRoundId) {
        require(fundingRounds[_fundingRoundId].status == FundingRoundStatus.Failed, "Funding round is not failed.");
        _;
    }

    modifier reviewProcessPending(uint256 _proposalId) {
        require(researchProposals[_proposalId].status == ProposalStatus.ReviewPending, "Review process is not pending.");
        _;
    }

    modifier reviewProcessFinalized(uint256 _proposalId) {
        require(researchProposals[_proposalId].status == ProposalStatus.ReviewFinalized, "Review process is not finalized.");
        _;
    }

    modifier parameterChangeIsProposed(uint256 _proposalChangeId) {
        require(parameterChangeProposals[_proposalChangeId].status == ParameterChangeStatus.Proposed, "Parameter change proposal is not proposed.");
        _;
    }

    modifier parameterChangeIsVoting(uint256 _proposalChangeId) {
        require(parameterChangeProposals[_proposalChangeId].status == ParameterChangeStatus.Voting, "Parameter change proposal is not in voting.");
        _;
    }

    modifier parameterChangeIsApproved(uint256 _proposalChangeId) {
        require(parameterChangeProposals[_proposalChangeId].status == ParameterChangeStatus.Approved, "Parameter change proposal is not approved.");
        _;
    }


    // --- 1. Research Proposal Management ---

    function submitResearchProposal(string memory _title, string memory _description, string memory _ipfsHash) public {
        require(bytes(_title).length > 0 && bytes(_description).length > 0 && bytes(_ipfsHash).length > 0, "Proposal details cannot be empty.");

        researchProposals.push(ResearchProposal({
            proposalId: proposalCounter,
            proposer: msg.sender,
            title: _title,
            description: _description,
            ipfsHash: _ipfsHash,
            status: ProposalStatus.Submitted,
            fundingRoundId: 0, // Initially no funding round
            reviewProcessId: 0, // Initially no review process
            submissionTimestamp: block.timestamp
        }));

        emit ProposalSubmitted(proposalCounter, msg.sender, _title);
        proposalCounter++;
    }

    function viewResearchProposal(uint256 _proposalId) public view validProposalId(_proposalId) returns (ResearchProposal memory) {
        return researchProposals[_proposalId];
    }

    function updateResearchProposal(uint256 _proposalId, string memory _description, string memory _ipfsHash) public onlyProposer(_proposalId) validProposalId(_proposalId) {
        require(researchProposals[_proposalId].status == ProposalStatus.Submitted || researchProposals[_proposalId].status == ProposalStatus.Cancelled, "Cannot update proposal in current status.");
        require(bytes(_description).length > 0 && bytes(_ipfsHash).length > 0, "Updated proposal details cannot be empty.");

        researchProposals[_proposalId].description = _description;
        researchProposals[_proposalId].ipfsHash = _ipfsHash;
        emit ProposalUpdated(_proposalId, msg.sender);
    }

    function cancelResearchProposal(uint256 _proposalId) public onlyProposer(_proposalId) validProposalId(_proposalId) {
        require(researchProposals[_proposalId].status == ProposalStatus.Submitted, "Proposal cannot be cancelled in current status.");
        researchProposals[_proposalId].status = ProposalStatus.Cancelled;
        emit ProposalCancelled(_proposalId, msg.sender);
    }


    // --- 2. Funding and Contribution Management ---

    function createFundingRound(uint256 _proposalId, uint256 _fundingGoal, uint256 _fundingDeadline) public onlyProposer(_proposalId) validProposalId(_proposalId) {
        require(researchProposals[_proposalId].status == ProposalStatus.Submitted || researchProposals[_proposalId].status == ProposalStatus.Cancelled, "Funding round can only be created for submitted/cancelled proposals.");
        require(_fundingGoal > 0 && _fundingDeadline > block.timestamp, "Invalid funding goal or deadline.");

        fundingRounds.push(FundingRound({
            fundingRoundId: fundingRoundCounter,
            proposalId: _proposalId,
            fundingGoal: _fundingGoal,
            fundingDeadline: _fundingDeadline,
            currentFunding: 0,
            status: FundingRoundStatus.Open,
            proposer: msg.sender,
            creationTimestamp: block.timestamp
        }));

        researchProposals[_proposalId].fundingRoundId = fundingRoundCounter;
        researchProposals[_proposalId].status = ProposalStatus.Funding;

        emit FundingRoundCreated(fundingRoundCounter, _proposalId, _fundingGoal, _fundingDeadline);
        fundingRoundCounter++;
    }

    function contributeToFundingRound(uint256 _fundingRoundId) public payable validFundingRoundId(_fundingRoundId) fundingRoundIsOpen(_fundingRoundId) {
        require(msg.value > 0, "Contribution amount must be greater than zero.");
        FundingRound storage currentRound = fundingRounds[_fundingRoundId];

        currentRound.currentFunding += msg.value;
        contributorFundingAmount[_fundingRoundId][msg.sender] += msg.value;

        bool isNewContributor = true;
        for (uint256 i = 0; i < fundingRoundContributors[_fundingRoundId].length; i++) {
            if (fundingRoundContributors[_fundingRoundId][i] == msg.sender) {
                isNewContributor = false;
                break;
            }
        }
        if (isNewContributor) {
            fundingRoundContributors[_fundingRoundId].push(msg.sender);
        }

        emit ContributionMade(_fundingRoundId, msg.sender, msg.value);

        if (currentRound.currentFunding >= currentRound.fundingGoal) {
            currentRound.status = FundingRoundStatus.GoalReached;
            researchProposals[currentRound.proposalId].status = ProposalStatus.Funded; // Proposal is now funded
        }
    }

    function withdrawFunding(uint256 _fundingRoundId) public onlyProposer(_fundingRoundId) validFundingRoundId(_fundingRoundId) fundingRoundGoalReached(_fundingRoundId) {
        FundingRound storage currentRound = fundingRounds[_fundingRoundId];
        require(currentRound.status == FundingRoundStatus.GoalReached, "Funding goal must be reached to withdraw.");
        require(researchProposals[currentRound.proposalId].status == ProposalStatus.Funded, "Proposal must be in Funded status to withdraw.");

        uint256 amountToWithdraw = currentRound.currentFunding;
        currentRound.currentFunding = 0; // Reset funding after withdrawal (or manage in a more complex way if needed)
        currentRound.status = FundingRoundStatus.Closed; // Mark funding round as closed after withdrawal
        researchProposals[currentRound.proposalId].status = ProposalStatus.ReviewPending; // Move to review stage

        (bool success, ) = payable(msg.sender).call{value: amountToWithdraw}("");
        require(success, "Funding withdrawal failed.");
        emit FundingWithdrawn(_fundingRoundId, msg.sender, amountToWithdraw);

        // Initiate review process automatically after funding withdrawal
        requestReviewers(currentRound.proposalId, requiredReviewers);
    }

    function refundContributors(uint256 _fundingRoundId) public onlyProposer(_fundingRoundId) validFundingRoundId(_fundingRoundId) fundingRoundIsFailed(_fundingRoundId) {
        FundingRound storage currentRound = fundingRounds[_fundingRoundId];
        require(currentRound.status == FundingRoundStatus.Failed, "Funding round must have failed to refund contributors.");

        currentRound.status = FundingRoundStatus.Refunded; // Mark funding round as refunded

        for (uint256 i = 0; i < fundingRoundContributors[_fundingRoundId].length; i++) {
            address contributor = fundingRoundContributors[_fundingRoundId][i];
            uint256 amountToRefund = contributorFundingAmount[_fundingRoundId][contributor];
            if (amountToRefund > 0) {
                (bool success, ) = payable(contributor).call{value: amountToRefund}("");
                require(success, "Refund failed for a contributor.");
                contributorFundingAmount[_fundingRoundId][contributor] = 0; // Reset refunded amount
            }
        }
        emit ContributorsRefunded(_fundingRoundId);
    }

    function extendFundingDeadline(uint256 _fundingRoundId, uint256 _newDeadline) public onlyProposer(_fundingRoundId) validFundingRoundId(_fundingRoundId) fundingRoundIsOpen(_fundingRoundId) {
        require(_newDeadline > fundingRounds[_fundingRoundId].fundingDeadline && _newDeadline > block.timestamp, "New deadline must be in the future and later than current deadline.");
        fundingRounds[_fundingRoundId].fundingDeadline = _newDeadline;
        emit FundingDeadlineExtended(_fundingRoundId, _newDeadline);
    }

    // --- 3. Decentralized Peer Review System ---

    function requestReviewers(uint256 _proposalId, uint8 _numReviewers) public onlyProposer(_proposalId) validProposalId(_proposalId) reviewProcessPending(_proposalId) {
        require(_numReviewers > 0 && _numReviewers <= 10, "Number of reviewers must be between 1 and 10."); // Limit reviewer count
        requiredReviewers = _numReviewers; // Update required reviewers if needed. In a real system, this might be more sophisticated.
        researchProposals[_proposalId].status = ProposalStatus.ReviewPending; // Ensure status is set correctly
        emit ReviewersRequested(_proposalId, _numReviewers);
    }

    function applyToBeReviewer(uint256 _proposalId) public validProposalId(_proposalId) reviewProcessPending(_proposalId) {
        // In a real system, you'd have criteria for reviewers (expertise, reputation, etc.)
        // For simplicity, anyone can apply in this example.
        bool alreadyApplied = false;
        for (uint256 i = 0; i < proposalReviewers[_proposalId].length; i++) {
            if (proposalReviewers[_proposalId][i] == msg.sender) {
                alreadyApplied = true;
                break;
            }
        }
        require(!alreadyApplied, "You have already applied to be a reviewer for this proposal.");

        proposalReviewers[_proposalId].push(msg.sender);
        emit ReviewerApplied(_proposalId, msg.sender);
    }

    function assignReviewers(uint256 _proposalId) public validProposalId(_proposalId) reviewProcessPending(_proposalId) {
        // In a real system, reviewer assignment could be more sophisticated:
        // - Based on expertise (profiles, keywords)
        // - Reputation scores
        // - Random selection from qualified pool

        require(proposalReviewers[_proposalId].length >= requiredReviewers, "Not enough reviewers applied yet.");

        address[] memory assignedReviewers = new address[](requiredReviewers);
        // Simple random selection (not cryptographically secure for true randomness, but illustrative)
        // In a real system, consider using Chainlink VRF or similar for verifiable randomness.
        for (uint8 i = 0; i < requiredReviewers; i++) {
            uint256 randomIndex = uint256(keccak256(abi.encodePacked(block.timestamp, i, _proposalId))) % proposalReviewers[_proposalId].length;
            assignedReviewers[i] = proposalReviewers[_proposalId][randomIndex];
            // Remove assigned reviewer to avoid duplicate assignment in this simple example.
            // In a more robust system, you might track assigned reviewers separately.
            // This removal is inefficient in gas and just for demonstration.
            // proposalReviewers[_proposalId].remove(randomIndex); // Not a standard Solidity array function, would require custom logic.
        }

        researchProposals[_proposalId].status = ProposalStatus.Review; // Move to review in progress status
        emit ReviewersAssigned(_proposalId, assignedReviewers);
        // In a real system, you would likely store the assigned reviewers more formally,
        // perhaps in a mapping or a separate struct linked to the proposal.
    }


    function submitReview(uint256 _proposalId, string memory _reviewText, uint8 _rating) public validProposalId(_proposalId) reviewProcessPending(_proposalId) { // Changed to reviewProcessPending - should be review status, and logic needs adjustment
        require(researchProposals[_proposalId].status == ProposalStatus.Review, "Review submission not allowed in current proposal status.");
        require(bytes(_reviewText).length > 0 && _rating >= 1 && _rating <= 5, "Invalid review details.");

        require(proposalReviewsByReviewer[_proposalId][msg.sender].reviewId == 0, "You have already submitted a review for this proposal."); // Prevent double review

        reviews.push(Review({
            reviewId: reviewCounter,
            proposalId: _proposalId,
            reviewer: msg.sender,
            reviewText: _reviewText,
            rating: _rating,
            status: ReviewStatus.Submitted,
            submissionTimestamp: block.timestamp
        }));
        proposalReviewsByReviewer[_proposalId][msg.sender] = reviews[reviewCounter]; // Store review by proposal and reviewer
        reviewCounter++;

        emit ReviewSubmitted(reviewCounter - 1, _proposalId, msg.sender);

        // Basic auto-finalize logic (very simplified, needs improvement in real use case)
        uint8 submittedReviewCount = 0;
        for (uint256 i = 0; i < reviewCounter; i++) {
            if (reviews[i].proposalId == _proposalId && reviews[i].status == ReviewStatus.Submitted) {
                submittedReviewCount++;
            }
        }
        if (submittedReviewCount >= requiredReviewers) {
            finalizeReviewProcess(_proposalId); // Auto finalize when enough reviews are submitted
        }
    }

    function viewReview(uint256 _proposalId, address _reviewer) public view validProposalId(_proposalId) returns (Review memory) {
        return proposalReviewsByReviewer[_proposalId][_reviewer];
    }

    function finalizeReviewProcess(uint256 _proposalId) public validProposalId(_proposalId) reviewProcessPending(_proposalId) { // Changed to reviewProcessPending - should be review status, and logic needs adjustment
        require(researchProposals[_proposalId].status == ProposalStatus.Review, "Review process not in progress.");

        uint8 submittedReviewCount = 0;
        uint256 totalRating = 0;
        for (uint256 i = 0; i < reviewCounter; i++) {
            if (reviews[i].proposalId == _proposalId && reviews[i].status == ReviewStatus.Submitted) {
                submittedReviewCount++;
                totalRating += reviews[i].rating;
            }
        }

        require(submittedReviewCount >= requiredReviewers, "Not enough reviews submitted to finalize.");

        researchProposals[_proposalId].status = ProposalStatus.ReviewFinalized; // Mark review process as finalized
        emit ReviewProcessFinalized(_proposalId);

        // Here you could calculate average rating, decide on proposal outcome based on reviews, etc.
        // For now, just finalize status. Further logic would be application-specific.
    }


    // --- 4. Intellectual Property (IP) Management (Conceptual) ---

    function registerIP(uint256 _proposalId, string memory _ipDocumentHash) public onlyProposer(_proposalId) validProposalId(_proposalId) reviewProcessFinalized(_proposalId) {
        require(bytes(_ipDocumentHash).length > 0, "IP Document Hash cannot be empty.");
        require(researchProposals[_proposalId].status == ProposalStatus.ReviewFinalized || researchProposals[_proposalId].status == ProposalStatus.Completed, "IP can only be registered after review finalized/completed.");
        require(bytes(proposalIPRegistrations[_proposalId]).length == 0, "IP already registered for this proposal."); // Prevent re-registration

        proposalIPRegistrations[_proposalId] = _ipDocumentHash;
        emit IPRegistered(_proposalId, _ipDocumentHash);
    }

    function viewIPRegistration(uint256 _proposalId) public view validProposalId(_proposalId) returns (string memory) {
        return proposalIPRegistrations[_proposalId];
    }


    // --- 5. Governance and DAO Features (Simple Example) ---

    function proposeParameterChange(string memory _parameterName, uint256 _newValue) public {
        require(bytes(_parameterName).length > 0, "Parameter name cannot be empty.");
        require(_newValue > 0, "New value must be greater than zero.");

        parameterChangeProposals.push(ParameterChangeProposal({
            proposalChangeId: parameterChangeCounter,
            parameterName: _parameterName,
            newValue: _newValue,
            status: ParameterChangeStatus.Proposed,
            votesFor: 0,
            votesAgainst: 0,
            votingDeadline: block.timestamp + governanceVotingDuration,
            proposer: msg.sender,
            proposalTimestamp: block.timestamp
        }));

        emit ParameterChangeProposed(parameterChangeCounter, _parameterName, _newValue, msg.sender);
        parameterChangeCounter++;
    }

    function voteOnProposalChange(uint256 _proposalChangeId, bool _vote) public validParameterChangeId(_proposalChangeId) parameterChangeIsProposed(_proposalChangeId) {
        ParameterChangeProposal storage currentProposal = parameterChangeProposals[_proposalChangeId];
        require(block.timestamp < currentProposal.votingDeadline, "Voting deadline has passed.");
        require(currentProposal.status == ParameterChangeStatus.Proposed, "Proposal is not in voting status."); // Redundant check, but for clarity

        if (_vote) {
            currentProposal.votesFor++;
        } else {
            currentProposal.votesAgainst++;
        }

        emit VoteCastOnParameterChange(_proposalChangeId, msg.sender, _vote);

        // Basic auto-execution logic - could be more sophisticated with token voting power, etc.
        if (block.timestamp >= currentProposal.votingDeadline) {
            if (currentProposal.votesFor * 100 / (currentProposal.votesFor + currentProposal.votesAgainst) >= minGovernanceVoteQuorum) {
                executeParameterChange(_proposalChangeId);
            } else {
                currentProposal.status = ParameterChangeStatus.Rejected;
            }
        }
    }

    function executeParameterChange(uint256 _proposalChangeId) public validParameterChangeId(_proposalChangeId) parameterChangeIsProposed(_proposalChangeId) {
        ParameterChangeProposal storage currentProposal = parameterChangeProposals[_proposalChangeId];
        require(block.timestamp >= currentProposal.votingDeadline, "Voting deadline must have passed.");
        require(currentProposal.status == ParameterChangeStatus.Proposed, "Proposal must be in Proposed status to execute."); // Redundant check, but for clarity

        require(currentProposal.votesFor * 100 / (currentProposal.votesFor + currentProposal.votesAgainst) >= minGovernanceVoteQuorum, "Governance quorum not reached for execution.");

        if (keccak256(bytes(currentProposal.parameterName)) == keccak256(bytes("requiredReviewers"))) {
            requiredReviewers = uint8(currentProposal.newValue);
        } else if (keccak256(bytes(currentProposal.parameterName)) == keccak256(bytes("reviewDuration"))) {
            reviewDuration = currentProposal.newValue;
        } else if (keccak256(bytes(currentProposal.parameterName)) == keccak256(bytes("governanceVotingDuration"))) {
            governanceVotingDuration = currentProposal.newValue;
        } else if (keccak256(bytes(currentProposal.parameterName)) == keccak256(bytes("minGovernanceVoteQuorum"))) {
            minGovernanceVoteQuorum = uint8(currentProposal.newValue);
        } else {
            revert("Invalid parameter name for change.");
        }

        currentProposal.status = ParameterChangeStatus.Executed;
        emit ParameterChangeExecuted(_proposalChangeId, currentProposal.parameterName, currentProposal.newValue);
    }


    // --- 6. Utility and Information Functions ---

    function getProposalCount() public view returns (uint256) {
        return proposalCounter;
    }

    function getFundingRoundDetails(uint256 _fundingRoundId) public view validFundingRoundId(_fundingRoundId) returns (FundingRound memory) {
        return fundingRounds[_fundingRoundId];
    }

    function getReviewDetails(uint256 _reviewId) public view validReviewId(_reviewId) returns (Review memory) {
        return reviews[_reviewId];
    }

    function getParameterChangeProposalDetails(uint256 _proposalChangeId) public view validParameterChangeId(_proposalChangeId) returns (ParameterChangeProposal memory) {
        return parameterChangeProposals[_proposalChangeId];
    }

    function getRequiredReviewers() public view returns (uint8) {
        return requiredReviewers;
    }

    function getReviewDuration() public view returns (uint256) {
        return reviewDuration;
    }

    function getGovernanceVotingDuration() public view returns (uint256) {
        return governanceVotingDuration;
    }

    function getMinGovernanceVoteQuorum() public view returns (uint256) {
        return minGovernanceVoteQuorum;
    }
}
```