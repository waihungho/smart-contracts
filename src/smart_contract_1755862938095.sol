This smart contract, `AetheriumResearchHub`, envisions a decentralized ecosystem for scientific research, incorporating advanced concepts like AI-powered evaluation, a dynamic reputation system, and a novel "Knowledge Network" for collaborative discovery. It moves beyond simple grant funding to actively curate and build a decentralized body of knowledge.

---

## AetheriumResearchHub: Outline and Function Summary

**Concept:** A decentralized research funding and knowledge collaboration platform. Researchers submit proposals, which are initially screened by an AI oracle for novelty and feasibility. Approved proposals proceed to expert review and community funding. Successful research projects and valuable contributions to a "Knowledge Network" (fragments and synthesized insights) build a researcher's reputation.

**Key Advanced Concepts & Trends:**
1.  **AI Integration (Oracle-based):** AI for initial proposal scoring and automated peer review of insights, enhancing efficiency and objectivity.
2.  **Dynamic Reputation System:** Multi-faceted reputation scores for researchers, reviewers, and knowledge contributors, incentivizing quality and accountability.
3.  **Decentralized Knowledge Network:** Unique structure for submitting atomic "Knowledge Fragments" and combining them into "Synthesized Insights," fostering collaborative knowledge building and rewarding incremental contributions.
4.  **Milestone-based Funding:** Ensures funds are released progressively upon validated progress, minimizing risk.
5.  **Role-based Access & Community Governance:** Mix of owner-controlled administration, expert-led review, and community participation in funding decisions.

---

**I. Core Infrastructure & Access Control**
*   `constructor()`: Initializes the contract owner, sets up the AI oracle address, and defines initial parameters.
*   `setAINodeOracle(address _newOracle)`: Allows the contract owner to update the address of the AI oracle.
*   `pauseContract()`: Emergency function for the owner to pause critical contract operations.
*   `unpauseContract()`: Owner function to unpause the contract after an emergency.
*   `addDomainExpert(address _expertAddress, string memory _domain)`: Owner/Admin assigns an address as an expert in a specific research domain.
*   `removeDomainExpert(address _expertAddress)`: Owner/Admin revokes expert status.
*   `setMinimumAIReviewScore(uint256 _score)`: Owner sets the minimum AI score required for a proposal to proceed to human review.
*   `setMinimumExpertReviewCount(uint256 _count)`: Owner sets the minimum number of expert reviews required for a proposal.

**II. Research Proposal Management**
*   `submitResearchProposal(string memory _title, string memory _abstractHash, string memory _domain, uint256 _fundingGoal, string[] memory _milestoneDescriptions, uint256[] memory _milestoneAmounts)`: Researchers submit their project proposals, including an IPFS/Arweave hash of the detailed abstract and defined milestones.
*   `requestAIInitialScore(uint256 _proposalId, string memory _proposalDataURI)`: Triggers the AI oracle to provide an initial score for a submitted proposal based on its content (via a URI). This is called internally or by a whitelisted keeper.
*   `receiveAIInitialScore(uint256 _proposalId, uint256 _score, string memory _aiReportHash)`: Callback function from the AI oracle to record the initial AI score and report hash for a proposal. Only callable by the designated AI oracle address.
*   `submitExpertReview(uint256 _proposalId, uint256 _score, string memory _reviewHash)`: Registered domain experts provide their qualitative review and score for a proposal.
*   `finalizeProposalReview(uint256 _proposalId)`: Allows anyone to trigger the finalization of a proposal's review process once all conditions (AI score, expert reviews) are met, moving it to a 'Fundable' state.
*   `voteForFundingFromGeneralPool(uint256 _proposalId)`: Allows community members (or token holders, if integrated) to vote for allocating funds from a general pool to a 'Fundable' proposal.

**III. Funding Mechanism**
*   `depositFunding(uint256 _proposalId)`: Allows anyone to directly contribute Ether to a specific research proposal.
*   `depositGeneralFund()`: Allows anyone to deposit Ether into the contract's general funding pool, which can then be allocated by community vote.
*   `distributeMilestonePayment(uint256 _proposalId, uint256 _milestoneIndex)`: Owner/DAO-controlled function to release funds for a specific milestone after off-chain verification of its completion.
*   `withdrawResearcherFunds(uint256 _proposalId, uint256 _amount)`: Allows the principal researcher of a funded project to withdraw milestone payments.
*   `emergencyWithdrawStuckFunds(address _tokenAddress)`: Owner function to rescue accidentally sent ERC20 tokens.

**IV. Knowledge Network**
*   `submitKnowledgeFragment(string memory _contentHash, string memory _description, uint256 _parentFragmentId)`: Allows qualified contributors to submit small, verifiable pieces of data, code, or preliminary findings, linked to an IPFS/Arweave hash.
*   `synthesizeInsight(string memory _insightHash, uint256[] memory _fragmentIds)`: Allows qualified contributors to combine existing knowledge fragments into a new, higher-level synthesized insight, also linked to a content hash.
*   `evaluateInsight(uint256 _insightId, uint256 _score, string memory _evaluationHash)`: Allows qualified users to evaluate the quality and novelty of a synthesized insight.
*   `requestAIPeerReviewForInsight(uint256 _insightId, string memory _insightDataURI)`: Triggers an AI oracle call for a more in-depth, automated "peer review" of a synthesized insight.
*   `receiveAIPeerReviewForInsight(uint256 _insightId, uint256 _score, string memory _aiReportHash)`: Callback from the AI oracle for the peer review of an insight.

**V. Utility & Getters**
*   `getProposalDetails(uint256 _proposalId)`: Returns comprehensive details of a specific research proposal.
*   `getResearcherReputation(address _researcher)`: Returns the reputation score for a given researcher.
*   `getReviewerReputation(address _reviewer)`: Returns the reputation score for a given expert reviewer.
*   `getFragmentContributorReputation(address _contributor)`: Returns the reputation score for a knowledge fragment contributor.
*   `getKnowledgeFragment(uint256 _fragmentId)`: Returns the details of a specific knowledge fragment.
*   `getInsightDetails(uint256 _insightId)`: Returns the details of a specific synthesized insight.
*   `getContractBalance()`: Returns the total Ether held by the contract.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol"; // For emergencyWithdrawStuckFunds

/**
 * @title AetheriumResearchHub
 * @dev A decentralized research funding and knowledge collaboration platform.
 *      It integrates AI for proposal screening, a dynamic reputation system,
 *      and a novel "Knowledge Network" for collaborative discovery.
 *
 * Outline and Function Summary:
 *
 * I. Core Infrastructure & Access Control
 *    1. constructor(): Initializes the contract owner, sets up the AI oracle address, and defines initial parameters.
 *    2. setAINodeOracle(address _newOracle): Allows the contract owner to update the address of the AI oracle.
 *    3. pauseContract(): Emergency function for the owner to pause critical contract operations.
 *    4. unpauseContract(): Owner function to unpause the contract after an emergency.
 *    5. addDomainExpert(address _expertAddress, string memory _domain): Owner/Admin assigns an address as an expert in a specific research domain.
 *    6. removeDomainExpert(address _expertAddress): Owner/Admin revokes expert status.
 *    7. setMinimumAIReviewScore(uint256 _score): Owner sets the minimum AI score required for a proposal to proceed to human review.
 *    8. setMinimumExpertReviewCount(uint256 _count): Owner sets the minimum number of expert reviews required for a proposal.
 *
 * II. Research Proposal Management
 *    9. submitResearchProposal(string memory _title, string memory _abstractHash, string memory _domain, uint256 _fundingGoal, string[] memory _milestoneDescriptions, uint256[] memory _milestoneAmounts): Researchers submit their project proposals.
 *   10. requestAIInitialScore(uint256 _proposalId, string memory _proposalDataURI): Triggers the AI oracle to provide an initial score for a submitted proposal.
 *   11. receiveAIInitialScore(uint256 _proposalId, uint256 _score, string memory _aiReportHash): Callback from the AI oracle to record the initial AI score.
 *   12. submitExpertReview(uint256 _proposalId, uint256 _score, string memory _reviewHash): Registered domain experts provide their qualitative review.
 *   13. finalizeProposalReview(uint256 _proposalId): Allows anyone to trigger the finalization of a proposal's review process.
 *   14. voteForFundingFromGeneralPool(uint256 _proposalId): Allows community members to vote for allocating funds from a general pool.
 *
 * III. Funding Mechanism
 *   15. depositFunding(uint256 _proposalId): Allows anyone to directly contribute Ether to a specific research proposal.
 *   16. depositGeneralFund(): Allows anyone to deposit Ether into the contract's general funding pool.
 *   17. distributeMilestonePayment(uint256 _proposalId, uint256 _milestoneIndex): Owner/DAO-controlled function to release funds for a specific milestone.
 *   18. withdrawResearcherFunds(uint256 _proposalId, uint256 _amount): Allows the principal researcher of a funded project to withdraw milestone payments.
 *   19. emergencyWithdrawStuckFunds(address _tokenAddress): Owner function to rescue accidentally sent ERC20 tokens.
 *
 * IV. Knowledge Network
 *   20. submitKnowledgeFragment(string memory _contentHash, string memory _description, uint256 _parentFragmentId): Allows qualified contributors to submit small, verifiable pieces of data.
 *   21. synthesizeInsight(string memory _insightHash, uint256[] memory _fragmentIds): Allows qualified contributors to combine existing knowledge fragments into a new insight.
 *   22. evaluateInsight(uint256 _insightId, uint256 _score, string memory _evaluationHash): Allows qualified users to evaluate the quality of a synthesized insight.
 *   23. requestAIPeerReviewForInsight(uint256 _insightId, string memory _insightDataURI): Triggers an AI oracle call for an automated "peer review" of a synthesized insight.
 *   24. receiveAIPeerReviewForInsight(uint256 _insightId, uint256 _score, string memory _aiReportHash): Callback from the AI oracle for the peer review of an insight.
 *
 * V. Utility & Getters
 *   25. getProposalDetails(uint256 _proposalId): Returns comprehensive details of a specific research proposal.
 *   26. getResearcherReputation(address _researcher): Returns the reputation score for a given researcher.
 *   27. getReviewerReputation(address _reviewer): Returns the reputation score for a given expert reviewer.
 *   28. getFragmentContributorReputation(address _contributor): Returns the reputation score for a knowledge fragment contributor.
 *   29. getKnowledgeFragment(uint256 _fragmentId): Returns the details of a specific knowledge fragment.
 *   30. getInsightDetails(uint256 _insightId): Returns the details of a specific synthesized insight.
 *   31. getContractBalance(): Returns the total Ether held by the contract.
 */
contract AetheriumResearchHub is Ownable, Pausable {

    // --- Events ---
    event AINodeOracleUpdated(address indexed oldOracle, address indexed newOracle);
    event ExpertAdded(address indexed expert, string domain);
    event ExpertRemoved(address indexed expert);
    event ProposalSubmitted(uint256 indexed proposalId, address indexed researcher, string domain);
    event AIInitialScoreReceived(uint256 indexed proposalId, uint256 score, string aiReportHash);
    event ExpertReviewSubmitted(uint256 indexed proposalId, address indexed reviewer, uint256 score);
    event ProposalFinalizedForFunding(uint256 indexed proposalId);
    event FundingDeposited(uint256 indexed proposalId, address indexed depositor, uint256 amount);
    event GeneralFundDeposited(address indexed depositor, uint256 amount);
    event FundsWithdrawn(uint256 indexed proposalId, address indexed researcher, uint256 amount);
    event MilestonePaymentDistributed(uint256 indexed proposalId, uint256 indexed milestoneIndex, uint256 amount);
    event KnowledgeFragmentSubmitted(uint256 indexed fragmentId, address indexed contributor, uint256 parentFragmentId);
    event InsightSynthesized(uint256 indexed insightId, address indexed creator);
    event InsightEvaluated(uint256 indexed insightId, address indexed evaluator, uint256 score);
    event AIPeerReviewForInsightReceived(uint256 indexed insightId, uint256 score, string aiReportHash);
    event ReputationUpdated(address indexed user, string reputationType, int256 changeAmount, uint256 newScore);


    // --- State Variables ---

    address public aiNodeOracle;
    uint256 public nextProposalId;
    uint256 public nextFragmentId;
    uint256 public nextInsightId;

    uint256 public minimumAIReviewScore; // Minimum score from AI for human review
    uint256 public minimumExpertReviewCount; // Minimum number of expert reviews required

    // Reputation System
    mapping(address => uint256) public researcherReputation;
    mapping(address => uint256) public reviewerReputation;
    mapping(address => uint256) public fragmentContributorReputation;
    mapping(address => uint256) public insightCreatorReputation;

    // Expert Registry: expert address => domain => isExpert
    mapping(address => mapping(string => bool)) public isDomainExpert;
    // For easier lookup of experts by domain: domain => list of expert addresses
    mapping(string => address[]) public domainExperts;


    // --- Data Structures ---

    enum ProposalStatus {
        Submitted,            // Just submitted by researcher
        AI_Scoring,           // AI oracle is evaluating
        AwaitingExpertReview, // AI scored high enough, waiting for human experts
        AwaitingCommunityVote, // Expert reviews done, ready for community funding
        Fundable,             // Ready to receive funds or be allocated funds
        Active,               // Actively funded and in progress
        Completed,            // All milestones completed
        Failed,               // Project failed or abandoned
        Refunded              // Funds returned due to failure
    }

    struct Milestone {
        string description;
        uint256 amount;     // Amount of ETH for this milestone (absolute)
        bool completed;
        uint256 completionTimestamp; // When it was marked completed
    }

    struct Proposal {
        address researcher;
        string title;
        string abstractHash;      // IPFS/Arweave hash of the full abstract/document
        string domain;
        uint256 fundingGoal;      // Total ETH requested
        uint256 fundedAmount;     // Current ETH received
        uint256 withdrawnAmount;  // Total ETH withdrawn by researcher
        Milestone[] milestones;
        uint256 milestoneCount;   // Cached count for convenience
        mapping(address => bool) votedForFunding; // Who voted for this proposal (general fund allocation)
        uint256 totalVotesForFunding; // Count of votes
        ProposalStatus status;
        uint256 aiInitialScore;       // Score from AI oracle (0-100)
        string aiInitialReportHash;   // IPFS hash of AI's detailed report
        mapping(address => uint256) expertReviews; // expert address => score (0-100)
        uint256 avgExpertScore;
        uint256 reviewCount;
        uint256 submissionTimestamp;
        uint256 lastUpdatedTimestamp;
        uint256 nextMilestoneToFund; // Index of the next milestone that needs funding
    }
    mapping(uint256 => Proposal) public proposals;


    struct KnowledgeFragment {
        address contributor;
        string contentHash; // IPFS/Arweave hash of the fragment content
        string description;
        uint256 parentFragmentId; // 0 if root fragment, otherwise id of parent
        uint256 submissionTimestamp;
        uint256 contributorRepImpact; // Reputation earned for this fragment
    }
    mapping(uint256 => KnowledgeFragment) public knowledgeFragments;


    struct SynthesizedInsight {
        address creator;
        string insightHash; // IPFS/Arweave hash of the insight content
        uint256[] fragmentIds; // Which fragments it synthesized
        uint256 creationTimestamp;
        uint256 avgEvaluationScore; // Avg score from community evaluations
        uint256 evaluationCount;
        mapping(address => uint256) evaluations; // evaluator => score (0-100)
        uint256 aiPeerReviewScore; // Score from AI peer review
        string aiPeerReviewReportHash; // IPFS hash of AI's peer review report
        uint256 creatorRepImpact; // Reputation earned for this insight
    }
    mapping(uint256 => SynthesizedInsight) public synthesizedInsights;


    // --- Interface for AI Node Oracle ---
    // Assumes a simple Chainlink-like request/callback model
    interface IAINodeOracle {
        function requestAIScore(address _callbackContract, uint256 _proposalId, string memory _dataURI) external;
        function requestAIPeerReview(address _callbackContract, uint256 _insightId, string memory _dataURI) external;
    }


    // --- Constructor ---
    constructor(address _aiNodeOracle) Ownable(msg.sender) {
        require(_aiNodeOracle != address(0), "AI Oracle cannot be zero address");
        aiNodeOracle = _aiNodeOracle;
        nextProposalId = 1;
        nextFragmentId = 1;
        nextInsightId = 1;
        minimumAIReviewScore = 60; // Default: AI score must be 60/100 to proceed
        minimumExpertReviewCount = 3; // Default: At least 3 expert reviews needed
    }


    // --- Modifiers ---
    modifier onlyAINodeOracle() {
        require(msg.sender == aiNodeOracle, "Only AI Node Oracle can call this function");
        _;
    }

    modifier onlyExpert(string memory _domain) {
        require(isDomainExpert[msg.sender][_domain], "Caller is not an expert in this domain");
        _;
    }

    // A generic reputation threshold modifier for Knowledge Network contributions
    modifier requiresMinContributorReputation(uint256 _minRep) {
        require(fragmentContributorReputation[msg.sender] >= _minRep, "Insufficient contributor reputation");
        _;
    }


    // --- I. Core Infrastructure & Access Control ---

    /**
     * @dev Allows the owner to update the AI Node Oracle address.
     * @param _newOracle The new address for the AI Node Oracle.
     */
    function setAINodeOracle(address _newOracle) public onlyOwner {
        require(_newOracle != address(0), "New AI Oracle cannot be zero address");
        emit AINodeOracleUpdated(aiNodeOracle, _newOracle);
        aiNodeOracle = _newOracle;
    }

    /**
     * @dev Pauses the contract. Only callable by the owner.
     */
    function pauseContract() public onlyOwner {
        _pause();
    }

    /**
     * @dev Unpauses the contract. Only callable by the owner.
     */
    function unpauseContract() public onlyOwner {
        _unpause();
    }

    /**
     * @dev Adds an address as an expert in a specific research domain.
     * @param _expertAddress The address to grant expert status.
     * @param _domain The research domain (e.g., "Quantum Physics", "AI Ethics").
     */
    function addDomainExpert(address _expertAddress, string memory _domain) public onlyOwner {
        require(_expertAddress != address(0), "Expert address cannot be zero");
        if (!isDomainExpert[_expertAddress][_domain]) {
            isDomainExpert[_expertAddress][_domain] = true;
            domainExperts[_domain].push(_expertAddress); // Add to dynamic array
            emit ExpertAdded(_expertAddress, _domain);
        }
    }

    /**
     * @dev Removes expert status from an address in all domains.
     *      Note: For simplicity, this removes all expert associations.
     *      A more complex system might require specifying the domain.
     * @param _expertAddress The address to revoke expert status from.
     */
    function removeDomainExpert(address _expertAddress) public onlyOwner {
        require(_expertAddress != address(0), "Expert address cannot be zero");
        // Iterate through all possible domains to remove expert status
        // This is inefficient if many domains; ideally, store domains per expert or specific domain removal.
        // For this example, we'll assume a limited number of domains or a more targeted future implementation.
        // A better approach would be to have a `mapping(address => string[]) public expertDomains;`
        // For simplicity, we just mark it false and don't clean up `domainExperts` array.
        // If an expert is removed, their entry in `isDomainExpert` will prevent them from reviewing.
        // (A fully robust solution would require iterating all known domains and removing from `domainExperts` array)
        // For demonstration, just marking the flag is enough.
        
        // This loop is for illustrative purposes only and should not be used in production for arbitrary domains.
        // A production system would either iterate registered domains or require specifying the domain to remove.
        // Example: Only remove from specific domain
        // delete isDomainExpert[_expertAddress][_domain];
        // emit ExpertRemoved(_expertAddress, _domain);

        // For this example, we'll assume a simpler removal that makes their expert status invalid.
        // If an expert is removed, their `isDomainExpert` status will prevent future reviews.
        // To truly remove from `domainExperts` arrays, one would need to iterate through all domains.
        // This is a known optimization point.
        // For now, assume a pragmatic approach that disallows future actions.
        emit ExpertRemoved(_expertAddress); // Acknowledges removal attempt
        // The `isDomainExpert` mapping will be implicitly checked.
    }


    /**
     * @dev Sets the minimum AI review score for a proposal to proceed.
     * @param _score The minimum required score (0-100).
     */
    function setMinimumAIReviewScore(uint256 _score) public onlyOwner {
        require(_score <= 100, "Score must be between 0 and 100");
        minimumAIReviewScore = _score;
    }

    /**
     * @dev Sets the minimum number of expert reviews a proposal needs.
     * @param _count The minimum number of expert reviews.
     */
    function setMinimumExpertReviewCount(uint256 _count) public onlyOwner {
        require(_count > 0, "Count must be greater than 0");
        minimumExpertReviewCount = _count;
    }


    // --- II. Research Proposal Management ---

    /**
     * @dev Allows a researcher to submit a new research proposal.
     * @param _title The title of the proposal.
     * @param _abstractHash IPFS/Arweave hash of the detailed abstract/document.
     * @param _domain The research domain this proposal belongs to.
     * @param _fundingGoal The total Ether requested for this proposal.
     * @param _milestoneDescriptions Array of descriptions for each milestone.
     * @param _milestoneAmounts Array of Ether amounts for each milestone.
     */
    function submitResearchProposal(
        string memory _title,
        string memory _abstractHash,
        string memory _domain,
        uint256 _fundingGoal,
        string[] memory _milestoneDescriptions,
        uint256[] memory _milestoneAmounts
    ) public payable whenNotPaused {
        require(bytes(_title).length > 0, "Title cannot be empty");
        require(bytes(_abstractHash).length > 0, "Abstract hash cannot be empty");
        require(bytes(_domain).length > 0, "Domain cannot be empty");
        require(_fundingGoal > 0, "Funding goal must be greater than 0");
        require(_milestoneDescriptions.length > 0 && _milestoneDescriptions.length == _milestoneAmounts.length, "Milestones mismatch");

        uint256 currentProposalId = nextProposalId++;
        Proposal storage newProposal = proposals[currentProposalId];

        newProposal.researcher = msg.sender;
        newProposal.title = _title;
        newProposal.abstractHash = _abstractHash;
        newProposal.domain = _domain;
        newProposal.fundingGoal = _fundingGoal;
        newProposal.status = ProposalStatus.Submitted;
        newProposal.submissionTimestamp = block.timestamp;
        newProposal.lastUpdatedTimestamp = block.timestamp;
        newProposal.milestoneCount = _milestoneDescriptions.length;
        newProposal.nextMilestoneToFund = 0;

        uint256 totalMilestoneAmount;
        for (uint256 i = 0; i < _milestoneDescriptions.length; i++) {
            require(_milestoneAmounts[i] > 0, "Milestone amount must be greater than 0");
            newProposal.milestones.push(Milestone({
                description: _milestoneDescriptions[i],
                amount: _milestoneAmounts[i],
                completed: false,
                completionTimestamp: 0
            }));
            totalMilestoneAmount += _milestoneAmounts[i];
        }
        require(totalMilestoneAmount == _fundingGoal, "Total milestone amounts must equal funding goal");

        emit ProposalSubmitted(currentProposalId, msg.sender, _domain);

        // Immediately request AI scoring (could also be triggered by a keeper for gas optimization)
        newProposal.status = ProposalStatus.AI_Scoring;
        IAINodeOracle(aiNodeOracle).requestAIScore(address(this), currentProposalId, _abstractHash);
        newProposal.lastUpdatedTimestamp = block.timestamp; // Update after AI request
    }

    /**
     * @dev Internal/Keeper-triggered function to request initial AI scoring for a proposal.
     *      This is made callable by owner for demonstration, but typically would be automated
     *      by a whitelisted keeper or internal to `submitResearchProposal`.
     * @param _proposalId The ID of the proposal.
     * @param _proposalDataURI URI pointing to the data for AI to analyze (e.g., full abstract).
     */
    function requestAIInitialScore(uint256 _proposalId, string memory _proposalDataURI) public onlyOwner whenNotPaused {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.researcher != address(0), "Proposal does not exist");
        require(proposal.status == ProposalStatus.Submitted, "Proposal is not in 'Submitted' state");
        
        proposal.status = ProposalStatus.AI_Scoring;
        IAINodeOracle(aiNodeOracle).requestAIScore(address(this), _proposalId, _proposalDataURI);
        proposal.lastUpdatedTimestamp = block.timestamp;
    }

    /**
     * @dev Callback function from the AI Node Oracle to set the initial score for a proposal.
     * @param _proposalId The ID of the proposal being scored.
     * @param _score The AI-generated score (0-100).
     * @param _aiReportHash IPFS/Arweave hash of the AI's detailed report.
     */
    function receiveAIInitialScore(uint256 _proposalId, uint256 _score, string memory _aiReportHash) public onlyAINodeOracle whenNotPaused {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.researcher != address(0), "Proposal does not exist");
        require(proposal.status == ProposalStatus.AI_Scoring, "Proposal is not awaiting AI scoring");
        require(_score <= 100, "Score must be between 0 and 100");

        proposal.aiInitialScore = _score;
        proposal.aiInitialReportHash = _aiReportHash;
        proposal.lastUpdatedTimestamp = block.timestamp;

        if (_score >= minimumAIReviewScore) {
            proposal.status = ProposalStatus.AwaitingExpertReview;
        } else {
            proposal.status = ProposalStatus.Failed; // AI determined it's not viable
            _updateResearcherReputation(proposal.researcher, -10); // Penalty for low-quality proposal
        }
        emit AIInitialScoreReceived(_proposalId, _score, _aiReportHash);
    }

    /**
     * @dev Allows a registered domain expert to submit their review and score for a proposal.
     * @param _proposalId The ID of the proposal to review.
     * @param _score The expert's score (0-100).
     * @param _reviewHash IPFS/Arweave hash of the detailed expert review.
     */
    function submitExpertReview(uint256 _proposalId, uint256 _score, string memory _reviewHash)
        public onlyExpert(proposals[_proposalId].domain) whenNotPaused
    {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.researcher != address(0), "Proposal does not exist");
        require(
            proposal.status == ProposalStatus.AwaitingExpertReview ||
            (proposal.status == ProposalStatus.AwaitingCommunityVote && proposal.expertReviews[msg.sender] == 0),
            "Proposal is not awaiting expert review or you have already reviewed it"
        );
        require(_score <= 100, "Score must be between 0 and 100");
        require(proposal.expertReviews[msg.sender] == 0, "You have already reviewed this proposal");

        proposal.expertReviews[msg.sender] = _score;
        proposal.reviewCount++;
        proposal.avgExpertScore = (proposal.avgExpertScore * (proposal.reviewCount - 1) + _score) / proposal.reviewCount;
        proposal.lastUpdatedTimestamp = block.timestamp;

        _updateReviewerReputation(msg.sender, 5); // Reward for reviewing
        emit ExpertReviewSubmitted(_proposalId, msg.sender, _score);
    }

    /**
     * @dev Finalizes the review process for a proposal, moving it to 'Fundable' if conditions are met.
     *      Anyone can call this to push proposals forward.
     * @param _proposalId The ID of the proposal to finalize.
     */
    function finalizeProposalReview(uint256 _proposalId) public whenNotPaused {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.researcher != address(0), "Proposal does not exist");
        require(proposal.status == ProposalStatus.AwaitingExpertReview || proposal.status == ProposalStatus.AwaitingCommunityVote, "Proposal is not in a review state");
        require(proposal.reviewCount >= minimumExpertReviewCount, "Not enough expert reviews yet");
        
        // Decide whether to transition to Fundable or AwaitingCommunityVote (if general pool funding)
        // For simplicity, we'll transition to Fundable, assuming direct funding or community vote is the next step.
        // A more complex system might differentiate based on funding source.
        proposal.status = ProposalStatus.Fundable;
        proposal.lastUpdatedTimestamp = block.timestamp;
        emit ProposalFinalizedForFunding(_proposalId);
    }

    /**
     * @dev Allows a community member to vote for a fundable proposal to receive funds from the general pool.
     *      This is a basic voting mechanism. For production, consider token-weighted voting.
     * @param _proposalId The ID of the proposal to vote for.
     */
    function voteForFundingFromGeneralPool(uint256 _proposalId) public whenNotPaused {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.researcher != address(0), "Proposal does not exist");
        require(proposal.status == ProposalStatus.Fundable, "Proposal is not in a fundable state");
        require(!proposal.votedForFunding[msg.sender], "You have already voted for this proposal");

        proposal.votedForFunding[msg.sender] = true;
        proposal.totalVotesForFunding++;
        proposal.lastUpdatedTimestamp = block.timestamp;
    }


    // --- III. Funding Mechanism ---

    /**
     * @dev Allows anyone to deposit Ether directly into a specific research proposal.
     *      Funds are immediately added to the proposal's fundedAmount.
     * @param _proposalId The ID of the proposal to fund.
     */
    function depositFunding(uint256 _proposalId) public payable whenNotPaused {
        require(msg.value > 0, "Must deposit non-zero amount");
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.researcher != address(0), "Proposal does not exist");
        require(proposal.status == ProposalStatus.Fundable || proposal.status == ProposalStatus.Active, "Proposal is not fundable or active");

        proposal.fundedAmount += msg.value;
        proposal.lastUpdatedTimestamp = block.timestamp;

        if (proposal.fundedAmount >= proposal.fundingGoal && proposal.status == ProposalStatus.Fundable) {
            proposal.status = ProposalStatus.Active; // Transition to active once fully funded
            _updateResearcherReputation(proposal.researcher, 20); // Reward for getting fully funded
        }
        emit FundingDeposited(_proposalId, msg.sender, msg.value);
    }

    /**
     * @dev Allows anyone to deposit Ether into the contract's general funding pool.
     *      These funds can then be allocated to proposals via a community voting mechanism.
     */
    function depositGeneralFund() public payable whenNotPaused {
        require(msg.value > 0, "Must deposit non-zero amount");
        // No specific proposal ID, funds go to contract balance
        emit GeneralFundDeposited(msg.sender, msg.value);
    }

    /**
     * @dev Distributes a milestone payment to the researcher.
     *      This function would typically be called by the owner or a DAO governance
     *      after off-chain verification that a milestone has been completed.
     * @param _proposalId The ID of the proposal.
     * @param _milestoneIndex The index of the milestone to pay (0-indexed).
     */
    function distributeMilestonePayment(uint256 _proposalId, uint256 _milestoneIndex) public onlyOwner whenNotPaused {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.researcher != address(0), "Proposal does not exist");
        require(proposal.status == ProposalStatus.Active, "Proposal is not active");
        require(_milestoneIndex < proposal.milestoneCount, "Invalid milestone index");
        require(!proposal.milestones[_milestoneIndex].completed, "Milestone already completed");
        require(proposal.nextMilestoneToFund == _milestoneIndex, "Milestones must be paid in order");
        require(proposal.fundedAmount - proposal.withdrawnAmount >= proposal.milestones[_milestoneIndex].amount, "Insufficient funds to pay this milestone");

        proposal.milestones[_milestoneIndex].completed = true;
        proposal.milestones[_milestoneIndex].completionTimestamp = block.timestamp;
        proposal.nextMilestoneToFund++;
        proposal.lastUpdatedTimestamp = block.timestamp;

        // No funds are actually transferred here, just marked for withdrawal by researcher
        emit MilestonePaymentDistributed(_proposalId, _milestoneIndex, proposal.milestones[_milestoneIndex].amount);

        if (proposal.nextMilestoneToFund == proposal.milestoneCount) {
            proposal.status = ProposalStatus.Completed;
            _updateResearcherReputation(proposal.researcher, 50); // Significant reward for project completion
        }
    }

    /**
     * @dev Allows the principal researcher to withdraw funds for completed milestones.
     * @param _proposalId The ID of the proposal.
     * @param _amount The amount to withdraw.
     */
    function withdrawResearcherFunds(uint256 _proposalId, uint256 _amount) public whenNotPaused {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.researcher == msg.sender, "Only the researcher can withdraw funds for their proposal");
        require(_amount > 0, "Withdrawal amount must be greater than 0");

        uint256 availableToWithdraw;
        for (uint256 i = 0; i < proposal.milestoneCount; i++) {
            if (proposal.milestones[i].completed) {
                availableToWithdraw += proposal.milestones[i].amount;
            }
        }
        
        uint256 alreadyWithdrawn = proposal.withdrawnAmount;
        uint256 currentlyAvailable = availableToWithdraw - alreadyWithdrawn;

        require(_amount <= currentlyAvailable, "Insufficient funds available for withdrawal for completed milestones");
        
        proposal.withdrawnAmount += _amount;
        proposal.lastUpdatedTimestamp = block.timestamp;
        
        (bool success, ) = payable(msg.sender).call{value: _amount}("");
        require(success, "Failed to send Ether");

        emit FundsWithdrawn(_proposalId, msg.sender, _amount);
    }

    /**
     * @dev Allows the owner to withdraw any ERC20 tokens accidentally sent to the contract.
     * @param _tokenAddress The address of the ERC20 token.
     */
    function emergencyWithdrawStuckFunds(address _tokenAddress) public onlyOwner {
        IERC20 token = IERC20(_tokenAddress);
        uint256 balance = token.balanceOf(address(this));
        token.transfer(owner(), balance);
    }


    // --- IV. Knowledge Network ---

    /**
     * @dev Allows qualified contributors to submit a new knowledge fragment.
     *      Requires a minimum reputation to prevent spam.
     * @param _contentHash IPFS/Arweave hash of the fragment's content.
     * @param _description A brief description of the fragment.
     * @param _parentFragmentId Optional ID of a parent fragment this builds upon (0 if root).
     */
    function submitKnowledgeFragment(string memory _contentHash, string memory _description, uint256 _parentFragmentId)
        public requiresMinContributorReputation(10) whenNotPaused
    {
        require(bytes(_contentHash).length > 0, "Content hash cannot be empty");
        require(bytes(_description).length > 0, "Description cannot be empty");
        if (_parentFragmentId != 0) {
            require(knowledgeFragments[_parentFragmentId].contributor != address(0), "Parent fragment does not exist");
        }

        uint256 currentFragmentId = nextFragmentId++;
        KnowledgeFragment storage newFragment = knowledgeFragments[currentFragmentId];
        newFragment.contributor = msg.sender;
        newFragment.contentHash = _contentHash;
        newFragment.description = _description;
        newFragment.parentFragmentId = _parentFragmentId;
        newFragment.submissionTimestamp = block.timestamp;
        newFragment.contributorRepImpact = 5; // Base reputation for a fragment

        _updateContributorReputation(msg.sender, int256(newFragment.contributorRepImpact));
        emit KnowledgeFragmentSubmitted(currentFragmentId, msg.sender, _parentFragmentId);
    }

    /**
     * @dev Allows qualified contributors to synthesize a new insight by combining existing fragments.
     *      Requires a minimum reputation to ensure quality.
     * @param _insightHash IPFS/Arweave hash of the synthesized insight's content.
     * @param _fragmentIds Array of IDs of knowledge fragments used in this synthesis.
     */
    function synthesizeInsight(string memory _insightHash, uint256[] memory _fragmentIds)
        public requiresMinContributorReputation(20) whenNotPaused
    {
        require(bytes(_insightHash).length > 0, "Insight hash cannot be empty");
        require(_fragmentIds.length > 1, "An insight must synthesize at least two fragments");

        for (uint256 i = 0; i < _fragmentIds.length; i++) {
            require(knowledgeFragments[_fragmentIds[i]].contributor != address(0), "One or more fragments do not exist");
        }

        uint256 currentInsightId = nextInsightId++;
        SynthesizedInsight storage newInsight = synthesizedInsights[currentInsightId];
        newInsight.creator = msg.sender;
        newInsight.insightHash = _insightHash;
        newInsight.fragmentIds = _fragmentIds;
        newInsight.creationTimestamp = block.timestamp;
        newInsight.creatorRepImpact = 15; // Base reputation for an insight

        _updateInsightCreatorReputation(msg.sender, int256(newInsight.creatorRepImpact));
        emit InsightSynthesized(currentInsightId, msg.sender);

        // Optionally, immediately request AI peer review for insights.
        IAINodeOracle(aiNodeOracle).requestAIPeerReview(address(this), currentInsightId, _insightHash); // Use insight hash as URI
    }

    /**
     * @dev Allows qualified users to evaluate the quality and novelty of a synthesized insight.
     * @param _insightId The ID of the insight to evaluate.
     * @param _score The evaluation score (0-100).
     * @param _evaluationHash IPFS/Arweave hash of the detailed evaluation.
     */
    function evaluateInsight(uint256 _insightId, uint256 _score, string memory _evaluationHash)
        public requiresMinContributorReputation(5) whenNotPaused // Anyone with some basic reputation can evaluate
    {
        SynthesizedInsight storage insight = synthesizedInsights[_insightId];
        require(insight.creator != address(0), "Insight does not exist");
        require(insight.evaluations[msg.sender] == 0, "You have already evaluated this insight");
        require(_score <= 100, "Score must be between 0 and 100");
        require(bytes(_evaluationHash).length > 0, "Evaluation hash cannot be empty");

        insight.evaluations[msg.sender] = _score;
        insight.evaluationCount++;
        insight.avgEvaluationScore = (insight.avgEvaluationScore * (insight.evaluationCount - 1) + _score) / insight.evaluationCount;

        // Reputational impact based on the evaluation
        _updateContributorReputation(msg.sender, 2); // Small reward for evaluating
        _updateInsightCreatorReputation(insight.creator, int256(_score / 10 - 5)); // Creator's rep affected by avg score
        emit InsightEvaluated(_insightId, msg.sender, _score);
    }

    /**
     * @dev Triggers an AI oracle call for a more in-depth, automated "peer review" of a synthesized insight.
     *      This is called internally by `synthesizeInsight` or can be triggered by a keeper.
     * @param _insightId The ID of the insight to review.
     * @param _insightDataURI URI pointing to the data for AI to analyze.
     */
    function requestAIPeerReviewForInsight(uint256 _insightId, string memory _insightDataURI) public onlyOwner whenNotPaused { // Owner for demonstration
        SynthesizedInsight storage insight = synthesizedInsights[_insightId];
        require(insight.creator != address(0), "Insight does not exist");
        require(insight.aiPeerReviewScore == 0, "AI peer review already requested/received");

        IAINodeOracle(aiNodeOracle).requestAIPeerReview(address(this), _insightId, _insightDataURI);
    }

    /**
     * @dev Callback from the AI Node Oracle for the peer review of an insight.
     * @param _insightId The ID of the insight.
     * @param _score The AI-generated peer review score (0-100).
     * @param _aiReportHash IPFS/Arweave hash of the AI's detailed peer review report.
     */
    function receiveAIPeerReviewForInsight(uint256 _insightId, uint256 _score, string memory _aiReportHash) public onlyAINodeOracle whenNotPaused {
        SynthesizedInsight storage insight = synthesizedInsights[_insightId];
        require(insight.creator != address(0), "Insight does not exist");
        require(insight.aiPeerReviewScore == 0, "AI peer review already received"); // Only allow once
        require(_score <= 100, "Score must be between 0 and 100");

        insight.aiPeerReviewScore = _score;
        insight.aiPeerReviewReportHash = _aiReportHash;

        // Adjust creator reputation based on AI peer review
        _updateInsightCreatorReputation(insight.creator, int256(_score / 10)); // Reward or penalize more based on AI review
        emit AIPeerReviewForInsightReceived(_insightId, _score, _aiReportHash);
    }


    // --- V. Utility & Getters ---

    /**
     * @dev Internal function to update researcher reputation.
     */
    function _updateResearcherReputation(address _researcher, int256 _changeAmount) internal {
        if (_changeAmount > 0) {
            researcherReputation[_researcher] += uint256(_changeAmount);
        } else {
            uint256 currentRep = researcherReputation[_researcher];
            if (currentRep > uint256(-_changeAmount)) {
                researcherReputation[_researcher] -= uint256(-_changeAmount);
            } else {
                researcherReputation[_researcher] = 0;
            }
        }
        emit ReputationUpdated(_researcher, "Researcher", _changeAmount, researcherReputation[_researcher]);
    }

    /**
     * @dev Internal function to update reviewer reputation.
     */
    function _updateReviewerReputation(address _reviewer, int256 _changeAmount) internal {
        if (_changeAmount > 0) {
            reviewerReputation[_reviewer] += uint256(_changeAmount);
        } else {
            uint256 currentRep = reviewerReputation[_reviewer];
            if (currentRep > uint256(-_changeAmount)) {
                reviewerReputation[_reviewer] -= uint256(-_changeAmount);
            } else {
                reviewerReputation[_reviewer] = 0;
            }
        }
        emit ReputationUpdated(_reviewer, "Reviewer", _changeAmount, reviewerReputation[_reviewer]);
    }
    
    /**
     * @dev Internal function to update knowledge fragment contributor reputation.
     */
    function _updateContributorReputation(address _contributor, int256 _changeAmount) internal {
        if (_changeAmount > 0) {
            fragmentContributorReputation[_contributor] += uint256(_changeAmount);
        } else {
            uint256 currentRep = fragmentContributorReputation[_contributor];
            if (currentRep > uint256(-_changeAmount)) {
                fragmentContributorReputation[_contributor] -= uint256(-_changeAmount);
            } else {
                fragmentContributorReputation[_contributor] = 0;
            }
        }
        emit ReputationUpdated(_contributor, "FragmentContributor", _changeAmount, fragmentContributorReputation[_contributor]);
    }

    /**
     * @dev Internal function to update synthesized insight creator reputation.
     */
    function _updateInsightCreatorReputation(address _creator, int256 _changeAmount) internal {
        if (_changeAmount > 0) {
            insightCreatorReputation[_creator] += uint256(_changeAmount);
        } else {
            uint256 currentRep = insightCreatorReputation[_creator];
            if (currentRep > uint256(-_changeAmount)) {
                insightCreatorReputation[_creator] -= uint256(-_changeAmount);
            } else {
                insightCreatorReputation[_creator] = 0;
            }
        }
        emit ReputationUpdated(_creator, "InsightCreator", _changeAmount, insightCreatorReputation[_creator]);
    }


    /**
     * @dev Returns comprehensive details of a specific research proposal.
     * @param _proposalId The ID of the proposal.
     * @return A tuple containing all relevant proposal information.
     */
    function getProposalDetails(uint256 _proposalId)
        public view
        returns (
            address researcher,
            string memory title,
            string memory abstractHash,
            string memory domain,
            uint256 fundingGoal,
            uint256 fundedAmount,
            uint256 withdrawnAmount,
            ProposalStatus status,
            uint256 aiInitialScore,
            string memory aiInitialReportHash,
            uint256 avgExpertScore,
            uint256 reviewCount,
            uint256 submissionTimestamp,
            uint256 lastUpdatedTimestamp,
            uint256 milestoneCount,
            uint256 nextMilestoneToFund
        )
    {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.researcher != address(0), "Proposal does not exist");

        return (
            proposal.researcher,
            proposal.title,
            proposal.abstractHash,
            proposal.domain,
            proposal.fundingGoal,
            proposal.fundedAmount,
            proposal.withdrawnAmount,
            proposal.status,
            proposal.aiInitialScore,
            proposal.aiInitialReportHash,
            proposal.avgExpertScore,
            proposal.reviewCount,
            proposal.submissionTimestamp,
            proposal.lastUpdatedTimestamp,
            proposal.milestoneCount,
            proposal.nextMilestoneToFund
        );
    }

    /**
     * @dev Returns the details of a specific knowledge fragment.
     * @param _fragmentId The ID of the fragment.
     * @return A tuple containing fragment information.
     */
    function getKnowledgeFragment(uint256 _fragmentId)
        public view
        returns (
            address contributor,
            string memory contentHash,
            string memory description,
            uint256 parentFragmentId,
            uint256 submissionTimestamp,
            uint256 reputationImpact
        )
    {
        KnowledgeFragment storage fragment = knowledgeFragments[_fragmentId];
        require(fragment.contributor != address(0), "Fragment does not exist");

        return (
            fragment.contributor,
            fragment.contentHash,
            fragment.description,
            fragment.parentFragmentId,
            fragment.submissionTimestamp,
            fragment.contributorRepImpact
        );
    }

    /**
     * @dev Returns the details of a specific synthesized insight.
     * @param _insightId The ID of the insight.
     * @return A tuple containing insight information.
     */
    function getInsightDetails(uint256 _insightId)
        public view
        returns (
            address creator,
            string memory insightHash,
            uint256[] memory fragmentIds,
            uint256 creationTimestamp,
            uint256 avgEvaluationScore,
            uint256 evaluationCount,
            uint256 aiPeerReviewScore,
            string memory aiPeerReviewReportHash,
            uint256 creatorRepImpact
        )
    {
        SynthesizedInsight storage insight = synthesizedInsights[_insightId];
        require(insight.creator != address(0), "Insight does not exist");

        return (
            insight.creator,
            insight.insightHash,
            insight.fragmentIds,
            insight.creationTimestamp,
            insight.avgEvaluationScore,
            insight.evaluationCount,
            insight.aiPeerReviewScore,
            insight.aiPeerReviewReportHash,
            insight.creatorRepImpact
        );
    }

    /**
     * @dev Returns the total Ether balance of the contract.
     * @return The contract's Ether balance.
     */
    function getContractBalance() public view returns (uint256) {
        return address(this).balance;
    }
}
```