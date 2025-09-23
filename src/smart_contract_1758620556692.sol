Here's a smart contract named `AetherForge` that acts as a decentralized autonomous R&D fund and intellectual property (IP) manager. It integrates advanced concepts like AI oracle decision support, a dynamic reputation system, and tokenized, dynamic IP NFTs with built-in royalty distribution.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol"; // For safe arithmetic
import "@openzeppelin/contracts/utils/Counters.sol"; // For unique IDs

/**
 * @title AetherForge
 * @dev A Decentralized Autonomous Research & Development Fund and IP Manager.
 *      This contract facilitates the funding, execution, and tokenization of
 *      research and development projects, incorporating AI-driven insights,
 *      dynamic reputation, and on-chain royalty distribution for IP.
 *      It aims to be a creative and advanced solution for decentralized innovation.
 */
contract AetherForge is Ownable, Pausable, ERC721 {
    using Counters for Counters.Counter;
    using SafeMath for uint256;

    // --- Outline and Function Summary ---
    // I. Contract Core & Administration (5 functions)
    //    1. constructor(): Initializes the contract owner, name, and IP NFT symbol.
    //    2. pauseContract(): Owner can pause critical contract functions.
    //    3. unpauseContract(): Owner can unpause the contract.
    //    4. transferOwnership(address newOwner): Transfers contract ownership.
    //    5. setAcceptedPaymentToken(address tokenAddress, bool accepted): Manages whitelist of ERC20 tokens for deposits.

    // II. Fund & Treasury Management (3 functions)
    //    6. depositFunds(address tokenAddress, uint256 amount): Accepts ETH or whitelisted ERC20 deposits.
    //    7. withdrawExcessFunds(address tokenAddress, uint256 amount): Owner can withdraw unallocated funds from the treasury.
    //    8. getTreasuryBalance(address tokenAddress): Returns current balance of a token in treasury.

    // III. Research Proposal Lifecycle (5 functions)
    //    9. submitResearchProposal(string memory _ipfsHash, uint256 _requestedFunding, uint256 _milestoneCount, uint256 _deadline): Submit new proposal.
    //    10. requestAIDecisionInsight(uint256 _proposalId): Triggers oracle for AI evaluation.
    //    11. fulfillAIDecisionInsight(uint256 _proposalId, uint256 _aiScore, string memory _aiAnalysisHash): Callback from AI oracle.
    //    12. castVoteOnProposal(uint256 _proposalId, bool _approve): DAO members vote on proposals.
    //    13. finalizeProposalDecision(uint256 _proposalId): Finalizes proposal status based on votes and AI score.

    // IV. Project Execution & Milestone Verification (5 functions)
    //    14. submitProjectMilestone(uint256 _proposalId, string memory _descriptionHash, uint256 _fundingAmount): Researcher submits a milestone.
    //    15. requestMilestoneVerification(uint256 _milestoneId): Initiates verification process for a milestone.
    //    16. submitMilestoneReview(uint256 _milestoneId, bool _isVerified, string memory _reviewHash): Verifiers submit review for a milestone.
    //    17. fundProjectMilestone(uint256 _milestoneId): Releases funds upon verified milestone completion.
    //    18. updateResearcherReputation(address _researcher, int256 _reputationChange): Adjusts researcher's reputation score.

    // V. Tokenized Intellectual Property (IP) & Royalties (4 functions)
    //    19. mintIPT_NFT(uint256 _proposalId, string memory _initialURI): Mints a dynamic ERC721 IP token.
    //    20. assignIPRoyaltySplit(uint256 _ipTokenId, address[] memory _recipients, uint256[] memory _percentages): Defines royalty distribution for an IP token.
    //    21. distributeIPRoyalties(uint256 _ipTokenId, uint256 _amount, address _tokenAddress): Distributes collected royalties.
    //    22. updateIPT_MetadataURI(uint256 _ipTokenId, string memory _newURI): Updates IP token's metadata URI.

    // VI. Dynamic Governance & Community Engagement (3 functions)
    //    23. delegateVotingPower(address _delegatee): Delegates voting power to another address.
    //    24. createCommunityChallenge(string memory _challengeHash, uint256 _bountyAmount, uint256 _duration): Creates a community challenge.
    //    25. submitChallengeSolution(uint256 _challengeId, string memory _solutionHash): Submits a solution for a community challenge.

    // VII. Information Retrieval (3 functions)
    //    26. getProposalDetails(uint256 _proposalId): Retrieves details of a specific proposal.
    //    27. getMilestoneDetails(uint256 _milestoneId): Retrieves details of a specific milestone.
    //    28. getResearcherReputation(address _researcher): Returns reputation score for a researcher.

    // --- Enums, Structs, and Events ---

    enum ProposalStatus {
        Pending,          // Awaiting AI insight or initial review
        AI_Reviewed,      // Has received AI insight
        DAO_Voting,       // Currently under DAO vote
        Approved,         // Approved for funding
        Rejected,         // Rejected by DAO or AI insight
        Funded,           // Funding has commenced / project active
        Completed         // Project successfully completed
    }

    enum MilestoneStatus {
        Pending,                    // Milestone defined but not started
        SubmittedForVerification,   // Deliverables submitted, awaiting review
        Verified,                   // Milestone successfully verified
        RejectedVerification,       // Verification failed
        Completed                   // Milestone completed and funded
    }

    struct ResearchProposal {
        uint256 proposalId;
        address proposer;
        string ipfsHash; // Link to detailed proposal document
        uint256 requestedFunding; // Total funding requested
        uint256 currentFundingProvided; // How much has been funded so far
        ProposalStatus status;
        uint256 submissionTimestamp;
        uint256 aiInsightScore; // AI-generated score (0-100), 0 if not reviewed
        string aiAnalysisHash; // IPFS hash for AI analysis report
        uint256 positiveDaoVotes; // Number of positive DAO votes
        uint256 negativeDaoVotes; // Number of negative DAO votes
        uint256 deadline; // Deadline for voting/completion
        uint256 milestoneCount; // Total number of expected milestones
        uint256 ipTokenId; // ID of the minted IP NFT, if applicable (0 if none)
    }

    struct Milestone {
        uint256 milestoneId;
        uint256 proposalId;
        string descriptionHash; // IPFS hash for milestone details/deliverables
        uint256 fundingAmount; // Funds released upon completion of this milestone
        MilestoneStatus status;
        uint256 submissionTimestamp;
        uint256 completionTimestamp; // When completed
        uint256 positiveReviews; // Number of positive verification reviews
        uint256 negativeReviews; // Number of negative verification reviews
        address[] verifiers; // Addresses who reviewed this milestone
    }

    struct IPRoyaltySplit {
        address recipient;
        uint256 percentageBasisPoints; // e.g., 1000 for 10% (10000 = 100%)
    }

    struct CommunityChallenge {
        uint256 challengeId;
        address proposer;
        string challengeHash; // IPFS hash for challenge details
        uint256 bountyAmount;
        uint256 duration; // in seconds
        uint256 creationTimestamp;
        address winningSolutionAddress; // Address of the winner, if determined
        string winningSolutionHash; // IPFS hash of the winning solution
        bool isActive;
    }

    // --- State Variables ---

    Counters.Counter private _proposalIds;
    Counters.Counter private _milestoneIds;
    Counters.Counter private _ipTokenIds;
    Counters.Counter private _challengeIds;

    // --- Mappings ---

    mapping(uint256 => ResearchProposal) public proposals;
    mapping(uint256 => Milestone) public milestones;
    mapping(uint256 => uint256[]) public proposalMilestones; // proposalId => array of milestoneIds

    mapping(address => uint256) public researcherReputation; // address => score
    mapping(uint256 => mapping(address => bool)) public hasVotedOnProposal; // proposalId => voter => hasVoted
    mapping(address => address) public votingDelegates; // delegator => delegatee

    mapping(address => uint256) public balances; // For internal ETH/ERC20 balances not yet allocated
    mapping(address => bool) public isAcceptedPaymentToken; // ERC20 token address => accepted

    mapping(uint256 => IPRoyaltySplit[]) public ipRoyaltySplits; // ipTokenId => array of royalty splits
    mapping(address => bool) public isOracle; // Address of the AI oracle
    mapping(address => bool) public isVerifier; // Address of a designated milestone verifier

    mapping(uint256 => CommunityChallenge) public communityChallenges;
    mapping(uint256 => mapping(address => string)) public challengeSolutions; // challengeId => solver => solutionHash

    // --- Events ---

    event FundsDeposited(address indexed token, address indexed depositor, uint256 amount);
    event FundsWithdrawn(address indexed token, address indexed recipient, uint256 amount);
    event ProposalSubmitted(uint256 indexed proposalId, address indexed proposer, uint256 requestedFunding);
    event AIDecisionRequested(uint256 indexed proposalId);
    event AIDecisionFulfilled(uint256 indexed proposalId, uint256 aiScore, string aiAnalysisHash);
    event ProposalVoted(uint256 indexed proposalId, address indexed voter, bool approved);
    event ProposalFinalized(uint256 indexed proposalId, ProposalStatus newStatus);
    event MilestoneSubmitted(uint256 indexed milestoneId, uint256 indexed proposalId, uint256 fundingAmount);
    event MilestoneVerificationRequested(uint256 indexed milestoneId, uint256 indexed proposalId);
    event MilestoneReviewSubmitted(uint256 indexed milestoneId, address indexed reviewer, bool isVerified);
    event MilestoneFunded(uint256 indexed milestoneId, uint256 indexed proposalId, uint256 amount);
    event ReputationUpdated(address indexed researcher, int256 change, uint256 newReputation);
    event IPT_NFT_Minted(uint256 indexed tokenId, uint256 indexed proposalId, address indexed owner);
    event IPRoyaltySplitAssigned(uint256 indexed tokenId);
    event IPRoyaltyDistributed(uint256 indexed tokenId, address indexed tokenAddress, uint256 amount);
    event IPT_MetadataURIUpdated(uint256 indexed tokenId, string newURI);
    event VotingPowerDelegated(address indexed delegator, address indexed delegatee);
    event CommunityChallengeCreated(uint256 indexed challengeId, address indexed proposer, uint256 bountyAmount);
    event ChallengeSolutionSubmitted(uint256 indexed challengeId, address indexed solver);

    // --- I. Contract Core & Administration ---

    constructor() ERC721("AetherForge IP Token", "AIPT") Ownable(msg.sender) {
        // Initialize owner, set contract name and IP NFT symbol
        // For testing, let's designate the owner as the mock oracle and verifier initially
        isOracle[msg.sender] = true;
        isVerifier[msg.sender] = true;
    }

    /**
     * @dev See {Pausable-pause}.
     * Only owner can call.
     */
    function pauseContract() public onlyOwner {
        _pause();
    }

    /**
     * @dev See {Pausable-unpause}.
     * Only owner can call.
     */
    function unpauseContract() public onlyOwner {
        _unpause();
    }

    /**
     * @dev Allows the contract owner to transfer ownership to a new address.
     * @param newOwner The address of the new owner.
     */
    function transferOwnership(address newOwner) public override onlyOwner {
        super.transferOwnership(newOwner);
    }

    /**
     * @dev Whitelists or blacklists ERC20 tokens that can be used for deposits.
     * @param tokenAddress The address of the ERC20 token.
     * @param accepted True to whitelist, false to blacklist.
     */
    function setAcceptedPaymentToken(address tokenAddress, bool accepted) public onlyOwner {
        require(tokenAddress != address(0), "Invalid token address");
        isAcceptedPaymentToken[tokenAddress] = accepted;
    }

    /**
     * @dev Sets an address as an authorized AI oracle.
     * @param oracleAddress The address of the oracle.
     * @param authorized True to authorize, false to de-authorize.
     */
    function setOracle(address oracleAddress, bool authorized) public onlyOwner {
        require(oracleAddress != address(0), "Invalid oracle address");
        isOracle[oracleAddress] = authorized;
    }

    /**
     * @dev Sets an address as an authorized milestone verifier.
     * @param verifierAddress The address of the verifier.
     * @param authorized True to authorize, false to de-authorize.
     */
    function setVerifier(address verifierAddress, bool authorized) public onlyOwner {
        require(verifierAddress != address(0), "Invalid verifier address");
        isVerifier[verifierAddress] = authorized;
    }

    // --- II. Fund & Treasury Management ---

    /**
     * @dev Allows users or protocols to deposit ERC20 tokens or ETH into the AetherForge treasury.
     * @param tokenAddress The address of the ERC20 token. Use address(0) for ETH.
     * @param amount The amount to deposit.
     */
    function depositFunds(address tokenAddress, uint256 amount) public payable whenNotPaused {
        require(amount > 0, "Deposit amount must be greater than zero");

        if (tokenAddress == address(0)) {
            require(msg.value == amount, "ETH amount mismatch");
            balances[address(0)] = balances[address(0)].add(amount);
        } else {
            require(isAcceptedPaymentToken[tokenAddress], "Token not accepted for deposits");
            IERC20(tokenAddress).transferFrom(msg.sender, address(this), amount);
            balances[tokenAddress] = balances[tokenAddress].add(amount);
        }
        emit FundsDeposited(tokenAddress, msg.sender, amount);
    }

    /**
     * @dev Allows the owner to withdraw unallocated funds from the treasury.
     * @param tokenAddress The address of the ERC20 token. Use address(0) for ETH.
     * @param amount The amount to withdraw.
     */
    function withdrawExcessFunds(address tokenAddress, uint256 amount) public onlyOwner whenNotPaused {
        require(amount > 0, "Withdraw amount must be greater than zero");
        require(balances[tokenAddress] >= amount, "Insufficient funds in treasury");

        balances[tokenAddress] = balances[tokenAddress].sub(amount);

        if (tokenAddress == address(0)) {
            payable(owner()).transfer(amount);
        } else {
            IERC20(tokenAddress).transfer(owner(), amount);
        }
        emit FundsWithdrawn(tokenAddress, owner(), amount);
    }

    /**
     * @dev Returns the current balance of a specific token held by the treasury.
     * @param tokenAddress The address of the ERC20 token. Use address(0) for ETH.
     * @return The balance of the specified token.
     */
    function getTreasuryBalance(address tokenAddress) public view returns (uint256) {
        if (tokenAddress == address(0)) {
            return address(this).balance;
        }
        return IERC20(tokenAddress).balanceOf(address(this));
    }

    // --- III. Research Proposal Lifecycle ---

    /**
     * @dev Allows researchers to submit a new funding proposal.
     * @param _ipfsHash IPFS hash linking to the detailed proposal document.
     * @param _requestedFunding Total funding amount requested (in wei or token units).
     * @param _milestoneCount The number of planned milestones for the project.
     * @param _deadline Timestamp by which the project should ideally be completed.
     */
    function submitResearchProposal(
        string memory _ipfsHash,
        uint256 _requestedFunding,
        uint256 _milestoneCount,
        uint256 _deadline
    ) public whenNotPaused {
        require(bytes(_ipfsHash).length > 0, "IPFS hash cannot be empty");
        require(_requestedFunding > 0, "Requested funding must be positive");
        require(_milestoneCount > 0, "At least one milestone required");
        require(_deadline > block.timestamp, "Deadline must be in the future");

        _proposalIds.increment();
        uint256 newProposalId = _proposalIds.current();

        proposals[newProposalId] = ResearchProposal({
            proposalId: newProposalId,
            proposer: msg.sender,
            ipfsHash: _ipfsHash,
            requestedFunding: _requestedFunding,
            currentFundingProvided: 0,
            status: ProposalStatus.Pending,
            submissionTimestamp: block.timestamp,
            aiInsightScore: 0,
            aiAnalysisHash: "",
            positiveDaoVotes: 0,
            negativeDaoVotes: 0,
            deadline: _deadline,
            milestoneCount: _milestoneCount,
            ipTokenId: 0
        });

        emit ProposalSubmitted(newProposalId, msg.sender, _requestedFunding);
    }

    /**
     * @dev Triggers an oracle request to an AI service for an objective evaluation score for a proposal.
     *      (In a real scenario, this would interact with a Chainlink or similar oracle contract).
     * @param _proposalId The ID of the proposal to be evaluated.
     */
    function requestAIDecisionInsight(uint256 _proposalId) public whenNotPaused {
        ResearchProposal storage proposal = proposals[_proposalId];
        require(proposal.proposer != address(0), "Proposal does not exist");
        require(proposal.status == ProposalStatus.Pending, "Proposal is not in Pending status");

        // Simulate sending a request to an AI oracle
        // In a real implementation, this would involve sending data to a Chainlink Request & Receive flow
        // For this example, we assume the oracle will call `fulfillAIDecisionInsight` directly.
        // It's a mock interaction to demonstrate the concept.
        emit AIDecisionRequested(_proposalId);
    }

    /**
     * @dev Callback function from the oracle to update a proposal with the AI's evaluation score and analysis.
     *      Only callable by the designated oracle address.
     * @param _proposalId The ID of the proposal.
     * @param _aiScore The AI-generated score (0-100).
     * @param _aiAnalysisHash IPFS hash for the AI's detailed analysis report.
     */
    function fulfillAIDecisionInsight(uint256 _proposalId, uint256 _aiScore, string memory _aiAnalysisHash) public {
        require(isOracle[msg.sender], "Only authorized oracle can fulfill AI insight");
        ResearchProposal storage proposal = proposals[_proposalId];
        require(proposal.proposer != address(0), "Proposal does not exist");
        require(proposal.status == ProposalStatus.Pending, "Proposal is not in Pending status");
        require(_aiScore <= 100, "AI score must be between 0 and 100");

        proposal.aiInsightScore = _aiScore;
        proposal.aiAnalysisHash = _aiAnalysisHash;
        proposal.status = ProposalStatus.AI_Reviewed; // Now ready for DAO voting
        emit AIDecisionFulfilled(_proposalId, _aiScore, _aiAnalysisHash);
    }

    /**
     * @dev Allows registered DAO members or reputation holders to vote on funding proposals.
     *      Voting power could be based on reputation, staked tokens, etc.
     *      For simplicity, anyone can vote once.
     * @param _proposalId The ID of the proposal to vote on.
     * @param _approve True for an 'approve' vote, false for 'reject'.
     */
    function castVoteOnProposal(uint256 _proposalId, bool _approve) public whenNotPaused {
        ResearchProposal storage proposal = proposals[_proposalId];
        require(proposal.proposer != address(0), "Proposal does not exist");
        require(
            proposal.status == ProposalStatus.AI_Reviewed || proposal.status == ProposalStatus.DAO_Voting,
            "Proposal is not in voting stage"
        );
        address voter = votingDelegates[msg.sender] != address(0) ? votingDelegates[msg.sender] : msg.sender;
        require(!hasVotedOnProposal[_proposalId][voter], "Voter has already voted on this proposal");
        require(block.timestamp <= proposal.deadline, "Voting deadline has passed");

        proposal.status = ProposalStatus.DAO_Voting; // Ensure status reflects voting is active

        if (_approve) {
            proposal.positiveDaoVotes = proposal.positiveDaoVotes.add(1);
        } else {
            proposal.negativeDaoVotes = proposal.negativeDaoVotes.add(1);
        }
        hasVotedOnProposal[_proposalId][voter] = true;
        emit ProposalVoted(_proposalId, voter, _approve);
    }

    /**
     * @dev Finalizes the voting process for a proposal, setting its status to Approved/Rejected based on votes and AI score.
     *      Can be called by anyone after the voting deadline.
     * @param _proposalId The ID of the proposal to finalize.
     */
    function finalizeProposalDecision(uint256 _proposalId) public whenNotPaused {
        ResearchProposal storage proposal = proposals[_proposalId];
        require(proposal.proposer != address(0), "Proposal does not exist");
        require(
            proposal.status == ProposalStatus.DAO_Voting || proposal.status == ProposalStatus.AI_Reviewed,
            "Proposal is not in a state to be finalized"
        );
        require(block.timestamp > proposal.deadline, "Voting deadline has not yet passed");

        // Simple decision logic: require more positive than negative votes AND a decent AI score
        bool approvedByDAO = proposal.positiveDaoVotes > proposal.negativeDaoVotes;
        bool approvedByAI = proposal.aiInsightScore >= 60; // Example threshold

        if (approvedByDAO && approvedByAI) {
            proposal.status = ProposalStatus.Approved;
        } else {
            proposal.status = ProposalStatus.Rejected;
        }
        emit ProposalFinalized(_proposalId, proposal.status);
    }

    // --- IV. Project Execution & Milestone Verification ---

    /**
     * @dev Researcher submits a new milestone for an approved proposal, detailing deliverables.
     * @param _proposalId The ID of the parent proposal.
     * @param _descriptionHash IPFS hash for milestone details/deliverables.
     * @param _fundingAmount Funds to be released upon successful completion of this milestone.
     */
    function submitProjectMilestone(
        uint256 _proposalId,
        string memory _descriptionHash,
        uint256 _fundingAmount
    ) public whenNotPaused {
        ResearchProposal storage proposal = proposals[_proposalId];
        require(proposal.proposer == msg.sender, "Only proposal proposer can submit milestones");
        require(proposal.proposer != address(0), "Proposal does not exist");
        require(proposal.status == ProposalStatus.Approved || proposal.status == ProposalStatus.Funded, "Proposal not approved or funded");
        require(bytes(_descriptionHash).length > 0, "Description hash cannot be empty");
        require(_fundingAmount > 0, "Milestone funding must be positive");
        require(proposal.currentFundingProvided.add(_fundingAmount) <= proposal.requestedFunding, "Milestone funding exceeds remaining budget");
        require(proposalMilestones[_proposalId].length < proposal.milestoneCount, "All milestones already defined for this proposal");

        _milestoneIds.increment();
        uint256 newMilestoneId = _milestoneIds.current();

        milestones[newMilestoneId] = Milestone({
            milestoneId: newMilestoneId,
            proposalId: _proposalId,
            descriptionHash: _descriptionHash,
            fundingAmount: _fundingAmount,
            status: MilestoneStatus.Pending,
            submissionTimestamp: block.timestamp,
            completionTimestamp: 0,
            positiveReviews: 0,
            negativeReviews: 0,
            verifiers: new address[](0)
        });
        proposalMilestones[_proposalId].push(newMilestoneId);

        // Update proposal status if this is the first milestone being submitted
        if (proposal.status == ProposalStatus.Approved) {
            proposal.status = ProposalStatus.Funded;
        }

        emit MilestoneSubmitted(newMilestoneId, _proposalId, _fundingAmount);
    }

    /**
     * @dev Researcher initiates a community or expert verification process for a completed milestone.
     * @param _milestoneId The ID of the milestone to be verified.
     */
    function requestMilestoneVerification(uint256 _milestoneId) public whenNotPaused {
        Milestone storage milestone = milestones[_milestoneId];
        require(milestone.proposalId != 0, "Milestone does not exist");
        require(proposals[milestone.proposalId].proposer == msg.sender, "Only milestone proposer can request verification");
        require(milestone.status == MilestoneStatus.Pending, "Milestone not in Pending status");

        milestone.status = MilestoneStatus.SubmittedForVerification;
        emit MilestoneVerificationRequested(_milestoneId, milestone.proposalId);
    }

    /**
     * @dev Allows designated verifiers or community members to submit their review of a milestone.
     *      Requires a minimum number of positive reviews for verification (example: 1 for this simple contract).
     * @param _milestoneId The ID of the milestone being reviewed.
     * @param _isVerified True if the reviewer believes the milestone is complete and verified, false otherwise.
     * @param _reviewHash IPFS hash for detailed review comments.
     */
    function submitMilestoneReview(uint256 _milestoneId, bool _isVerified, string memory _reviewHash) public whenNotPaused {
        require(isVerifier[msg.sender], "Only authorized verifiers can submit reviews");
        Milestone storage milestone = milestones[_milestoneId];
        require(milestone.proposalId != 0, "Milestone does not exist");
        require(milestone.status == MilestoneStatus.SubmittedForVerification, "Milestone not awaiting verification");

        // Prevent double voting by the same verifier for a specific milestone
        for (uint i = 0; i < milestone.verifiers.length; i++) {
            require(milestone.verifiers[i] != msg.sender, "You have already reviewed this milestone");
        }

        milestone.verifiers.push(msg.sender);

        if (_isVerified) {
            milestone.positiveReviews = milestone.positiveReviews.add(1);
        } else {
            milestone.negativeReviews = milestone.negativeReviews.add(1);
        }

        // Automatic verification if enough positive reviews are received (e.g., 1 for simplicity)
        // In a real system, this would be more complex (e.g., quorum, stake-weighted).
        if (milestone.positiveReviews >= 1) { // Example: A single positive review is enough for this demo
            milestone.status = MilestoneStatus.Verified;
            milestone.completionTimestamp = block.timestamp;
            updateResearcherReputation(proposals[milestone.proposalId].proposer, 10); // Reward reputation
        } else if (milestone.negativeReviews >= 2) { // Example: Two negative reviews lead to rejection
            milestone.status = MilestoneStatus.RejectedVerification;
            updateResearcherReputation(proposals[milestone.proposalId].proposer, -5); // Penalize reputation
        }
        // If not enough reviews, milestone remains in SubmittedForVerification status

        emit MilestoneReviewSubmitted(_milestoneId, msg.sender, _isVerified);
    }

    /**
     * @dev Releases funds for a verified milestone to the proposer.
     * @param _milestoneId The ID of the milestone to fund.
     */
    function fundProjectMilestone(uint256 _milestoneId) public whenNotPaused {
        Milestone storage milestone = milestones[_milestoneId];
        require(milestone.proposalId != 0, "Milestone does not exist");
        require(milestone.status == MilestoneStatus.Verified, "Milestone not yet verified");

        ResearchProposal storage proposal = proposals[milestone.proposalId];
        require(proposal.proposer != address(0), "Proposal for milestone does not exist");
        require(proposal.currentFundingProvided.add(milestone.fundingAmount) <= proposal.requestedFunding, "Funding exceeds requested amount");
        require(balances[address(0)] >= milestone.fundingAmount, "Insufficient ETH balance in treasury"); // Assuming ETH for funding

        balances[address(0)] = balances[address(0)].sub(milestone.fundingAmount);
        payable(proposal.proposer).transfer(milestone.fundingAmount);

        proposal.currentFundingProvided = proposal.currentFundingProvided.add(milestone.fundingAmount);
        milestone.status = MilestoneStatus.Completed; // Mark milestone as completed and funded

        // Check if all milestones are completed and if so, update proposal status
        bool allMilestonesCompleted = true;
        for (uint i = 0; i < proposalMilestones[milestone.proposalId].length; i++) {
            if (milestones[proposalMilestones[milestone.proposalId][i]].status != MilestoneStatus.Completed) {
                allMilestonesCompleted = false;
                break;
            }
        }
        if (allMilestonesCompleted && proposalMilestones[milestone.proposalId].length == proposal.milestoneCount) {
             proposal.status = ProposalStatus.Completed;
             // Trigger IP NFT minting if not already done
             if (proposal.ipTokenId == 0) {
                 mintIPT_NFT(milestone.proposalId, proposal.ipfsHash); // Use initial IPFS for metadata
             }
        }

        emit MilestoneFunded(_milestoneId, milestone.proposalId, milestone.fundingAmount);
    }

    /**
     * @dev Adjusts a researcher's reputation score. This could be triggered by project success, failures,
     *      peer reviews, or DAO votes.
     * @param _researcher The address of the researcher whose reputation is being updated.
     * @param _reputationChange The amount by which to change the reputation (can be negative).
     */
    function updateResearcherReputation(address _researcher, int256 _reputationChange) public onlyOwner {
        require(_researcher != address(0), "Invalid researcher address");

        uint256 currentRep = researcherReputation[_researcher];
        uint256 newRep;

        if (_reputationChange >= 0) {
            newRep = currentRep.add(uint256(_reputationChange));
        } else {
            uint256 absChange = uint256(-_reputationChange);
            newRep = currentRep > absChange ? currentRep.sub(absChange) : 0;
        }
        researcherReputation[_researcher] = newRep;
        emit ReputationUpdated(_researcher, _reputationChange, newRep);
    }

    // --- V. Tokenized Intellectual Property (IP) & Royalties ---

    /**
     * @dev Mints a unique, dynamic ERC721 NFT representing the Intellectual Property for a successfully completed research project.
     *      This NFT is initially minted to the project proposer and can be configured with royalty splits.
     * @param _proposalId The ID of the completed proposal.
     * @param _initialURI The initial metadata URI for the IP NFT.
     * @return The ID of the newly minted IP token.
     */
    function mintIPT_NFT(uint256 _proposalId, string memory _initialURI) public onlyOwner returns (uint256) {
        ResearchProposal storage proposal = proposals[_proposalId];
        require(proposal.proposer != address(0), "Proposal does not exist");
        require(proposal.status == ProposalStatus.Completed, "Proposal must be completed to mint IP NFT");
        require(proposal.ipTokenId == 0, "IP NFT already minted for this proposal");
        require(bytes(_initialURI).length > 0, "Initial URI cannot be empty");

        _ipTokenIds.increment();
        uint256 newTokenId = _ipTokenIds.current();

        _safeMint(proposal.proposer, newTokenId);
        _setTokenURI(newTokenId, _initialURI);

        proposal.ipTokenId = newTokenId;
        emit IPT_NFT_Minted(newTokenId, _proposalId, proposal.proposer);
        return newTokenId;
    }

    /**
     * @dev Defines how future royalties generated by the IP are split among stakeholders.
     *      Only the owner of the IP NFT can assign royalty splits.
     * @param _ipTokenId The ID of the IP NFT.
     * @param _recipients An array of addresses to receive royalties.
     * @param _percentages An array of percentages (in basis points, 10000 = 100%) corresponding to recipients.
     */
    function assignIPRoyaltySplit(
        uint256 _ipTokenId,
        address[] memory _recipients,
        uint256[] memory _percentages
    ) public whenNotPaused {
        require(ownerOf(_ipTokenId) == msg.sender, "Only IP NFT owner can assign royalty splits");
        require(_recipients.length == _percentages.length, "Recipient and percentage arrays must match length");

        uint256 totalPercentage;
        for (uint i = 0; i < _percentages.length; i++) {
            totalPercentage = totalPercentage.add(_percentages[i]);
        }
        require(totalPercentage == 10000, "Total percentages must sum to 10000 basis points (100%)");

        delete ipRoyaltySplits[_ipTokenId]; // Clear existing splits
        for (uint i = 0; i < _recipients.length; i++) {
            ipRoyaltySplits[_ipTokenId].push(IPRoyaltySplit({
                recipient: _recipients[i],
                percentageBasisPoints: _percentages[i]
            }));
        }
        emit IPRoyaltySplitAssigned(_ipTokenId);
    }

    /**
     * @dev Allows an external entity (e.g., a royalty collector) to deposit royalties
     *      which are then distributed to the defined split for a given IP token.
     * @param _ipTokenId The ID of the IP NFT for which royalties are being distributed.
     * @param _amount The total amount of royalties to distribute.
     * @param _tokenAddress The address of the ERC20 token for royalties. Use address(0) for ETH.
     */
    function distributeIPRoyalties(uint256 _ipTokenId, uint256 _amount, address _tokenAddress) public payable whenNotPaused {
        require(_exists(_ipTokenId), "IP Token does not exist");
        require(_amount > 0, "Royalty amount must be positive");
        require(ipRoyaltySplits[_ipTokenId].length > 0, "No royalty split defined for this IP token");

        if (_tokenAddress == address(0)) {
            require(msg.value == _amount, "ETH amount mismatch for royalties");
        } else {
            require(isAcceptedPaymentToken[_tokenAddress], "Royalty token not accepted");
            IERC20(_tokenAddress).transferFrom(msg.sender, address(this), _amount);
        }

        // Distribute royalties based on the defined splits
        for (uint i = 0; i < ipRoyaltySplits[_ipTokenId].length; i++) {
            IPRoyaltySplit storage split = ipRoyaltySplits[_ipTokenId][i];
            uint256 share = _amount.mul(split.percentageBasisPoints).div(10000);

            if (share > 0) {
                if (_tokenAddress == address(0)) {
                    payable(split.recipient).transfer(share);
                } else {
                    IERC20(_tokenAddress).transfer(split.recipient, share);
                }
            }
        }
        emit IPRoyaltyDistributed(_ipTokenId, _tokenAddress, _amount);
    }

    /**
     * @dev Updates the metadata URI for a specific IP NFT, reflecting project progress or new findings.
     *      This enables dynamic NFTs where the appearance or data changes over time.
     *      Only the current owner of the IP NFT can update its metadata.
     * @param _ipTokenId The ID of the IP NFT.
     * @param _newURI The new URI pointing to updated metadata.
     */
    function updateIPT_MetadataURI(uint256 _ipTokenId, string memory _newURI) public whenNotPaused {
        require(ownerOf(_ipTokenId) == msg.sender, "Only IP NFT owner can update metadata URI");
        _setTokenURI(_ipTokenId, _newURI);
        emit IPT_MetadataURIUpdated(_ipTokenId, _newURI);
    }

    // Override _beforeTokenTransfer to restrict transfers (making it soulbound initially)
    // For a truly soulbound token, `_transfer` and `approve` functions should not be exposed,
    // or this hook should revert unconditionally for AIPT.
    // For this example, we'll allow transfer by owner only.
    // If you want it fully soulbound (non-transferable), uncomment the revert in _beforeTokenTransfer.
    // function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize)
    //     internal
    //     override(ERC721)
    // {
    //     // Revert if anyone tries to transfer an AIPT NFT, making it effectively soulbound.
    //     // Remove or modify this line if you want the IP NFTs to be transferable.
    //     require(from == address(0) || to == address(0), "AetherForge IP Tokens are soulbound and non-transferable.");
    //     super._beforeTokenTransfer(from, to, tokenId, batchSize);
    // }

    // --- VI. Dynamic Governance & Community Engagement ---

    /**
     * @dev Allows participants to delegate their voting power (based on reputation or staked tokens)
     *      to another address. This address will then cast votes on their behalf.
     * @param _delegatee The address to which voting power is delegated.
     */
    function delegateVotingPower(address _delegatee) public {
        require(_delegatee != msg.sender, "Cannot delegate to self");
        votingDelegates[msg.sender] = _delegatee;
        emit VotingPowerDelegated(msg.sender, _delegatee);
    }

    /**
     * @dev Allows the community (or designated members) to propose smaller, time-bound research challenges with a bounty.
     * @param _challengeHash IPFS hash for challenge details and requirements.
     * @param _bountyAmount The reward for the winning solution (in ETH, assuming ETH bounty for simplicity).
     * @param _duration The duration of the challenge in seconds.
     */
    function createCommunityChallenge(string memory _challengeHash, uint256 _bountyAmount, uint256 _duration) public payable whenNotPaused {
        require(bytes(_challengeHash).length > 0, "Challenge hash cannot be empty");
        require(_bountyAmount > 0, "Bounty amount must be positive");
        require(_duration > 0, "Challenge duration must be positive");
        require(msg.value == _bountyAmount, "ETH amount mismatch for bounty");

        _challengeIds.increment();
        uint256 newChallengeId = _challengeIds.current();

        communityChallenges[newChallengeId] = CommunityChallenge({
            challengeId: newChallengeId,
            proposer: msg.sender,
            challengeHash: _challengeHash,
            bountyAmount: _bountyAmount,
            duration: _duration,
            creationTimestamp: block.timestamp,
            winningSolutionAddress: address(0),
            winningSolutionHash: "",
            isActive: true
        });

        balances[address(0)] = balances[address(0)].add(_bountyAmount); // Add bounty to internal ETH balance

        emit CommunityChallengeCreated(newChallengeId, msg.sender, _bountyAmount);
    }

    /**
     * @dev Participants submit solutions to open community challenges.
     * @param _challengeId The ID of the challenge.
     * @param _solutionHash IPFS hash linking to the submitted solution.
     */
    function submitChallengeSolution(uint256 _challengeId, string memory _solutionHash) public whenNotPaused {
        CommunityChallenge storage challenge = communityChallenges[_challengeId];
        require(challenge.challengeId != 0, "Challenge does not exist");
        require(challenge.isActive, "Challenge is not active");
        require(block.timestamp <= challenge.creationTimestamp.add(challenge.duration), "Challenge submission period has ended");
        require(bytes(_solutionHash).length > 0, "Solution hash cannot be empty");
        require(challengeSolutions[_challengeId][msg.sender].length == 0, "You have already submitted a solution for this challenge");

        challengeSolutions[_challengeId][msg.sender] = _solutionHash;
        emit ChallengeSolutionSubmitted(_challengeId, msg.sender);
    }

    /**
     * @dev Selects a winning solution for a community challenge and awards the bounty.
     *      Callable by the challenge proposer after the challenge duration, or by DAO.
     *      For simplicity, `onlyOwner` can finalize.
     * @param _challengeId The ID of the challenge.
     * @param _winner The address of the winning solver.
     * @param _winningSolutionHash The IPFS hash of the winning solution.
     */
    function finalizeChallenge(uint256 _challengeId, address _winner, string memory _winningSolutionHash) public onlyOwner whenNotPaused {
        CommunityChallenge storage challenge = communityChallenges[_challengeId];
        require(challenge.challengeId != 0, "Challenge does not exist");
        require(challenge.isActive, "Challenge is not active");
        require(block.timestamp > challenge.creationTimestamp.add(challenge.duration), "Challenge submission period has not ended");
        require(_winner != address(0), "Winner address cannot be zero");
        require(bytes(challengeSolutions[_challengeId][_winner]).length > 0, "Winner has not submitted a solution");
        require(balances[address(0)] >= challenge.bountyAmount, "Insufficient ETH for bounty payout");

        balances[address(0)] = balances[address(0)].sub(challenge.bountyAmount);
        payable(_winner).transfer(challenge.bountyAmount);

        challenge.winningSolutionAddress = _winner;
        challenge.winningSolutionHash = _winningSolutionHash;
        challenge.isActive = false;

        updateResearcherReputation(_winner, 20); // Reward winner with reputation
    }

    // --- VII. Information Retrieval ---

    /**
     * @dev Retrieves all on-chain details for a specific research proposal.
     * @param _proposalId The ID of the proposal.
     * @return A tuple containing all proposal fields.
     */
    function getProposalDetails(uint256 _proposalId) public view returns (
        uint256 proposalId,
        address proposer,
        string memory ipfsHash,
        uint256 requestedFunding,
        uint256 currentFundingProvided,
        ProposalStatus status,
        uint256 submissionTimestamp,
        uint256 aiInsightScore,
        string memory aiAnalysisHash,
        uint256 positiveDaoVotes,
        uint256 negativeDaoVotes,
        uint256 deadline,
        uint256 milestoneCount,
        uint256 ipTokenId
    ) {
        ResearchProposal storage proposal = proposals[_proposalId];
        require(proposal.proposer != address(0), "Proposal does not exist");
        return (
            proposal.proposalId,
            proposal.proposer,
            proposal.ipfsHash,
            proposal.requestedFunding,
            proposal.currentFundingProvided,
            proposal.status,
            proposal.submissionTimestamp,
            proposal.aiInsightScore,
            proposal.aiAnalysisHash,
            proposal.positiveDaoVotes,
            proposal.negativeDaoVotes,
            proposal.deadline,
            proposal.milestoneCount,
            proposal.ipTokenId
        );
    }

    /**
     * @dev Retrieves details for a specific project milestone.
     * @param _milestoneId The ID of the milestone.
     * @return A tuple containing all milestone fields.
     */
    function getMilestoneDetails(uint256 _milestoneId) public view returns (
        uint256 milestoneId,
        uint256 proposalId,
        string memory descriptionHash,
        uint256 fundingAmount,
        MilestoneStatus status,
        uint256 submissionTimestamp,
        uint256 completionTimestamp,
        uint256 positiveReviews,
        uint256 negativeReviews
    ) {
        Milestone storage milestone = milestones[_milestoneId];
        require(milestone.proposalId != 0, "Milestone does not exist");
        return (
            milestone.milestoneId,
            milestone.proposalId,
            milestone.descriptionHash,
            milestone.fundingAmount,
            milestone.status,
            milestone.submissionTimestamp,
            milestone.completionTimestamp,
            milestone.positiveReviews,
            milestone.negativeReviews
        );
    }

    /**
     * @dev Returns the current on-chain reputation score for a given researcher.
     * @param _researcher The address of the researcher.
     * @return The current reputation score.
     */
    function getResearcherReputation(address _researcher) public view returns (uint256) {
        return researcherReputation[_researcher];
    }

    // Fallback function to accept ETH deposits, primarily for `depositFunds(address(0), amount)`
    receive() external payable {
        if (msg.sender != address(0)) { // Ensure not a direct send from 0x0
            depositFunds(address(0), msg.value);
        }
    }
}
```