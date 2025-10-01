Here's a Solidity smart contract for `ImpactCatalystDAO` that incorporates advanced concepts like AI-enhanced decision support, a reputation system, and multi-stage project funding via milestones, all managed by a decentralized autonomous organization. It aims for creativity by combining these elements into a novel research funding mechanism.

---

**Outline and Function Summary**

**Contract Name:** `ImpactCatalystDAO`

**Concept:** A Decentralized Autonomous Organization (DAO) facilitating funding for high-impact research. It combines a reputation system for researchers and reviewers, community governance, and an AI-powered oracle for grant allocation recommendations based on configurable "impact vectors." Funding is released in tranches upon milestone completion.

**Key Features:**
*   **Project Lifecycle Management:** From proposal submission, through DAO approval, to funding and completion via verified milestones.
*   **Reputation System:** Rewards successful researchers for completing projects and diligent reviewers for accurate assessments.
*   **DAO Governance:** Token-weighted voting mechanism for project approval, AI recommendation consideration, and protocol parameter changes.
*   **AI-Enhanced Decision Support:** Integrates an AI oracle (e.g., via Chainlink Functions for an LLM) to provide *recommendations* for grant allocations. These recommendations are informed by project descriptions, researcher reputation, and a set of configurable "impact vectors" (e.g., environmental, health, technological innovation). The DAO has the ultimate authority to accept or override these recommendations.
*   **Dynamic Funding:** Approved projects receive their total allocated funds in tranches, disbursed only upon the successful completion and approval of individual milestones.
*   **Role-Based Access Control:** Differentiates permissions for researchers, reviewers, token holders (voters), and DAO administrators (owner).

---

**Function Summary (24 Functions)**

**I. Core Project Management Functions (Researcher & Admin)**
1.  `constructor()`: Initializes the DAO with its governance token, an initial AI oracle address, and default impact vectors.
2.  `proposeProject()`: Allows any address to propose a new research project, detailing its title, description, funding goal, and planned milestones.
3.  `submitMilestone()`: Enables the project researcher to submit a completed milestone with evidence, requesting a percentage of the total project funding.
4.  `updateProjectDetails()`: Allows the researcher (or admin) to update non-critical details of their proposed or active project.
5.  `cancelProject()`: Permits the researcher (for proposed projects) or the DAO owner (for active projects) to cancel a project, returning unspent funds to the DAO pool.

**II. Reputation System Functions (Reviewer & Admin)**
6.  `registerReviewer()`: Allows any address to register themselves as a peer reviewer for project milestones.
7.  `reviewMilestone()`: Enables a registered reviewer to assess a submitted milestone, approving or rejecting it, and providing feedback. This updates reviewer and researcher reputation.
8.  `getResearcherReputation()`: View function to retrieve the current reputation score of a specific researcher.
9.  `getReviewerReputation()`: View function to retrieve the current reputation score of a specific reviewer.

**III. DAO Governance & Funding Functions (Voters & Admin)**
10. `stakeGovernanceTokens()`: Allows users to lock their governance tokens in the contract to gain voting power for proposals.
11. `unstakeGovernanceTokens()`: Allows users to retrieve their staked governance tokens (provided no active votes are tied to them).
12. `createProjectFundingProposal()`: Initiates a new DAO proposal for token holders to vote on the funding approval of a proposed research project.
13. `voteOnProposal()`: Enables staked token holders to cast their 'for' or 'against' vote on an active DAO proposal.
14. `finalizeProjectFunding()`: An owner-controlled function (in this demo, would be DAO-controlled) that resolves a project funding proposal based on votes and optionally incorporates the AI's recommendation to determine the final allocated amount.
15. `claimMilestoneFunds()`: Allows the researcher to receive their designated share of funds for a successfully approved milestone.
16. `depositFunding()`: A payable function allowing anyone to deposit native currency (e.g., Ether) into the DAO's general funding pool.
17. `withdrawDAOExcessFunds()`: Allows the DAO owner to withdraw any surplus native currency from the DAO's funding pool that is not allocated to projects.

**IV. AI Integration Functions (Oracle & Admin)**
18. `requestAI_GrantRecommendation()`: Triggers an external call to the AI oracle (e.g., Chainlink Functions) to obtain a data-driven recommendation for a project's funding.
19. `fulfillAI_GrantRecommendation()`: A callback function, callable only by the designated AI oracle, to deliver the AI's funding recommendation and rationale back to the contract.
20. `setAIOracleAddress()`: Allows the DAO owner to update the address of the trusted AI oracle contract, enabling upgrades or changes.
21. `configureImpactVector()`: Allows the DAO owner to define, weight, and set thresholds for "impact vectors" that the AI oracle considers during its recommendation process.

**V. Utility & View Functions**
22. `getProjectDetails()`: View function to retrieve comprehensive information about a specific research project.
23. `getProposalDetails()`: View function to retrieve detailed information about a specific DAO proposal.
24. `getVotingPower()`: View function to query the current voting power (amount of staked tokens) of any given address.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

// --- Outline and Function Summary ---

// Contract Name: ImpactCatalystDAO

// Concept: A Decentralized Autonomous Organization (DAO) facilitating funding for high-impact research.
// It combines a reputation system for researchers and reviewers, community governance, and an AI-powered oracle
// for grant allocation recommendations based on configurable "impact vectors." Funding is released in tranches
// upon milestone completion.

// Key Features:
// - Project Lifecycle Management: From proposal to funding and completion via milestones.
// - Reputation System: Rewards successful researchers and diligent reviewers.
// - DAO Governance: Token-weighted voting for project approval, funding, and parameter changes.
// - AI-Enhanced Decision Support: Integrates an AI oracle (e.g., Chainlink Functions + LLM) to provide
//   recommendations for grant allocations, considering user-defined impact vectors and researcher reputation.
//   The DAO can choose to override or follow the AI recommendation.
// - Dynamic Funding: Funds disbursed upon verified milestone achievement.
// - Role-Based Access Control: Differentiates between researchers, reviewers, voters, and DAO administrators.

// --- Function Summary (24 Functions) ---

// I. Core Project Management Functions (Researcher & Admin)
// 1. constructor(): Initializes the DAO with governance token, AI oracle address, and initial parameters.
// 2. proposeProject(): Allows a researcher to propose a new research project.
// 3. submitMilestone(): Allows the project researcher to submit a completed milestone for review.
// 4. updateProjectDetails(): Allows researcher/admin to update non-critical project details.
// 5. cancelProject(): Allows the DAO or researcher to cancel a project, returning unspent funds.

// II. Reputation System Functions (Reviewer & Admin)
// 6. registerReviewer(): Allows any address to register as a peer reviewer.
// 7. reviewMilestone(): A registered reviewer assesses a submitted milestone and approves/rejects it.
// 8. getResearcherReputation(): View function to get a researcher's current reputation score.
// 9. getReviewerReputation(): View function to get a reviewer's current reputation score.

// III. DAO Governance & Funding Functions (Voters & Admin)
// 10. stakeGovernanceTokens(): Allows users to stake governance tokens to gain voting power.
// 11. unstakeGovernanceTokens(): Allows users to unstake governance tokens.
// 12. createProjectFundingProposal(): Creates a DAO proposal for token holders to vote on funding approval.
// 13. voteOnProposal(): Allows staked token holders to vote on an active proposal.
// 14. finalizeProjectFunding(): Finalizes the funding decision for a project, considering DAO votes and AI recommendation.
// 15. claimMilestoneFunds(): Allows the researcher to claim funds for a successfully approved milestone.
// 16. depositFunding(): Allows anyone to deposit funds into the DAO's main funding pool.
// 17. withdrawDAOExcessFunds(): Allows DAO admin to withdraw any surplus funds not allocated to projects.

// IV. AI Integration Functions (Oracle & Admin)
// 18. requestAI_GrantRecommendation(): Triggers an external AI oracle call for a project's funding recommendation.
// 19. fulfillAI_GrantRecommendation(): Callback function from the AI oracle to deliver its recommendation.
// 20. setAIOracleAddress(): Allows DAO governance to update the trusted AI oracle contract address.
// 21. configureImpactVector(): Allows DAO governance to define and weight "impact vectors" for the AI oracle.

// V. Utility & View Functions
// 22. getProjectDetails(): View function to retrieve comprehensive details of a project.
// 23. getProposalDetails(): View function to get details about a specific DAO proposal.
// 24. getVotingPower(): View function to get the current voting power of an address.

// --- End of Outline and Function Summary ---

contract ImpactCatalystDAO is Ownable, ReentrancyGuard {

    // --- Custom Errors ---
    error ZeroAddress();
    error InvalidAmount();
    error NotEnoughStakedTokens();
    error NotEnoughAllowance(); // Clarified from NotEnoughStakedTokens for ERC20
    error ProposalNotFound();
    error AlreadyVoted();
    error VotingPeriodExpired();
    error VotingPeriodNotOver();
    error ProposalNotOpen();
    error ProjectNotFound();
    error MilestoneNotFound();
    error NotProjectResearcher();
    error NotRegisteredReviewer();
    error MilestoneNotPendingReview();
    error ProjectNotApproved();
    error FundingGoalNotMet(); // Not used currently, but good for future validation
    error InsufficientMilestoneFunds(); // Used for failed fund transfers
    error AIRecommendationPending();
    error AIRecommendationAlreadySet();
    error UnauthorizedAIOracle();
    error ProjectAlreadyFunded();
    error ProposalAlreadyFinalized();
    error ProjectNotCancellable();
    error InvalidMilestoneIndex();
    error InvalidFundingPercentage();
    error InsufficientFundingPool();
    error ProjectHasActiveProposals();
    error ImpactVectorNotFound();
    error ImpactVectorAlreadyExists(); // Not strictly an error in `_configureImpactVector` as it updates
    error ReviewerAlreadyRegistered();
    error FailedToSendFunds(); // Specific error for native token transfers


    // --- Enums ---
    enum ProjectStatus { Proposed, PendingFundingReview, Approved, Rejected, InProgress, Completed, Cancelled }
    enum MilestoneStatus { PendingSubmission, PendingReview, Approved, Rejected, Claimed }
    enum ProposalType { ProjectFunding, AI_RecommendationDecision, ParameterChange } // ParameterChange for future use
    enum ProposalStatus { Active, Succeeded, Failed, Executed }

    // --- Structs ---

    struct Milestone {
        uint256 milestoneId;
        string descriptionIpfsHash;
        string evidenceIpfsHash;
        MilestoneStatus status;
        uint256 fundingPercentage; // Percentage of total project funding allocated to this milestone
        address reviewer; // Address of the reviewer who approved/rejected (0x0 if not reviewed)
        string reviewFeedbackIpfsHash;
        bool fundsClaimed;
    }

    struct Project {
        uint256 projectId;
        address researcher;
        string title;
        string descriptionIpfsHash;
        uint256 fundingGoal; // Total funding requested by the researcher (in native token units)
        uint256 totalFundingAllocated; // Actual funding approved by DAO (in native token units)
        ProjectStatus status;
        uint256 initialProposedMilestones; // How many milestones the project was proposed with
        Milestone[] milestones;
        uint256 aiRecommendationRequestId; // Chainlink requestId for AI recommendation
        uint256 aiRecommendedAmount; // Amount recommended by AI oracle (in native token units)
        string aiRationaleIpfsHash;
        uint256 fundingProposalId; // ID of the proposal to fund this project
    }

    struct Proposal {
        uint256 proposalId;
        address proposer;
        ProposalType proposalType;
        uint256 targetId; // Project ID, or other ID depending on proposalType
        string descriptionIpfsHash; // Link to proposal details
        uint256 voteStartTime;
        uint256 voteEndTime;
        uint256 votesFor;
        uint256 votesAgainst;
        mapping(address => bool) hasVoted; // Voter address => true if voted
        ProposalStatus status;
        uint256 minVotesNeeded; // Minimum total votes (voting power) needed for quorum
        uint256 quorumPercentage; // Percentage of total staked tokens required to vote
    }

    struct ImpactVector {
        string name;
        uint256 weight;    // How important this vector is (e.g., 1-100)
        uint256 threshold; // Min score required for AI recommendation (e.g., 0-100)
        string descriptionIpfsHash;
        bool exists; // To check if a vector with this name exists
    }

    // --- State Variables ---

    IERC20 public immutable governanceToken; // The token used for voting power
    address public aiOracleAddress; // Address of the trusted AI oracle contract

    uint256 public nextProjectId;
    mapping(uint256 => Project) public projects;

    uint256 public nextProposalId;
    mapping(uint256 => Proposal) public proposals;

    mapping(address => uint256) public researcherReputation; // Researcher address => score
    mapping(address => uint256) public reviewerReputation;   // Reviewer address => score
    mapping(address => bool) public isRegisteredReviewer; // Track registered reviewers

    mapping(address => uint256) public stakedTokens; // User address => staked amount
    uint256 public totalStakedTokens; // Total governance tokens staked in the DAO

    uint256 public constant VOTING_PERIOD_DURATION = 7 days; // Duration for proposals to be active
    uint256 public constant QUORUM_PERCENTAGE_BPS = 400; // 4% in basis points (400/10000)

    // Mapping to store configurable impact vectors by name
    mapping(string => ImpactVector) public impactVectors;
    string[] public impactVectorNames; // To iterate over impact vectors

    uint256 public daoFundingPool; // ETH/native currency held by the DAO for projects

    // --- Events ---
    event ProjectProposed(uint256 indexed projectId, address indexed researcher, string title, uint256 fundingGoal);
    event MilestoneSubmitted(uint256 indexed projectId, uint256 indexed milestoneIndex, address researcher);
    event MilestoneReviewed(uint256 indexed projectId, uint256 indexed milestoneIndex, address indexed reviewer, bool approved);
    event ReviewerRegistered(address indexed reviewer);
    event TokensStaked(address indexed staker, uint256 amount);
    event TokensUnstaked(address indexed staker, uint256 amount);
    event ProposalCreated(uint256 indexed proposalId, address indexed proposer, ProposalType proposalType, uint256 targetId);
    event Voted(uint256 indexed proposalId, address indexed voter, bool support);
    event AIRecommendationRequested(uint256 indexed projectId, uint256 requestId, address indexed caller);
    event AIRecommendationFulfilled(uint256 indexed projectId, uint256 requestId, uint256 recommendedAmount);
    event ProjectFundingFinalized(uint256 indexed projectId, uint256 allocatedAmount, ProposalStatus status);
    event MilestoneFundsClaimed(uint256 indexed projectId, uint256 indexed milestoneIndex, address indexed researcher, uint256 amount);
    event FundingDeposited(address indexed depositor, uint256 amount);
    event DAOExcessFundsWithdrawn(address indexed recipient, uint224 amount); // Adjusted to uint224 for safety with .call
    event ProjectDetailsUpdated(uint256 indexed projectId, string newDescriptionIpfsHash);
    event ProjectCancelled(uint256 indexed projectId, address indexed canceller);
    event ImpactVectorConfigured(string indexed vectorName, uint256 weight, uint256 threshold);
    event AIOracleAddressUpdated(address indexed newAddress);
    event ResearcherReputationUpdated(address indexed researcher, uint256 newReputation);
    event ReviewerReputationUpdated(address indexed reviewer, uint256 newReputation);

    // --- Constructor ---
    constructor(address _governanceTokenAddress, address _initialAIOracleAddress) Ownable(msg.sender) {
        if (_governanceTokenAddress == address(0) || _initialAIOracleAddress == address(0)) {
            revert ZeroAddress();
        }
        governanceToken = IERC20(_governanceTokenAddress);
        aiOracleAddress = _initialAIOracleAddress;
        nextProjectId = 1;
        nextProposalId = 1;

        // Initialize default impact vectors (example)
        _configureImpactVector("Environmental Impact", 80, 70, "ipfs://environmental_desc_v1");
        _configureImpactVector("Health Advancement", 90, 75, "ipfs://health_desc_v1");
        _configureImpactVector("Technological Innovation", 70, 60, "ipfs://tech_desc_v1");
        _configureImpactVector("Social Equity", 60, 50, "ipfs://social_desc_v1");
    }

    // --- Modifiers ---
    modifier onlyResearcher(uint256 _projectId) {
        if (projects[_projectId].researcher != msg.sender) {
            revert NotProjectResearcher();
        }
        _;
    }

    modifier onlyRegisteredReviewer() {
        if (!isRegisteredReviewer[msg.sender]) {
            revert NotRegisteredReviewer();
        }
        _;
    }

    modifier onlyAIOracle() {
        if (msg.sender != aiOracleAddress) {
            revert UnauthorizedAIOracle();
        }
        _;
    }

    // --- Core Project Management Functions ---

    /**
     * @notice Allows a researcher to propose a new research project.
     * @param _title The title of the research project.
     * @param _descriptionIpfsHash IPFS hash pointing to the detailed project description.
     * @param _fundingGoal The total funding goal in native tokens (e.g., wei).
     * @param _numMilestones The number of milestones the project plans to have.
     */
    function proposeProject(
        string memory _title,
        string memory _descriptionIpfsHash,
        uint256 _fundingGoal,
        uint256 _numMilestones
    ) external nonReentrant {
        if (_fundingGoal == 0 || _numMilestones == 0) {
            revert InvalidAmount();
        }

        uint256 projectId = nextProjectId++;
        Project storage newProject = projects[projectId];

        newProject.projectId = projectId;
        newProject.researcher = msg.sender;
        newProject.title = _title;
        newProject.descriptionIpfsHash = _descriptionIpfsHash;
        newProject.fundingGoal = _fundingGoal;
        newProject.status = ProjectStatus.Proposed;
        newProject.initialProposedMilestones = _numMilestones;
        // Milestones array will be populated by submitMilestone.

        emit ProjectProposed(projectId, msg.sender, _title, _fundingGoal);
    }

    /**
     * @notice Allows the project researcher to submit a completed milestone for review.
     * @param _projectId The ID of the project.
     * @param _milestoneIndex The index of the milestone being submitted (0-indexed).
     * @param _milestoneDescriptionIpfsHash IPFS hash of the milestone description.
     * @param _evidenceIpfsHash IPFS hash pointing to the evidence of milestone completion.
     * @param _fundingPercentage Percentage of the total project funding requested for this milestone (e.g., 25 for 25%).
     *                          Total of all milestone percentages must sum to 100 for successful completion.
     */
    function submitMilestone(
        uint256 _projectId,
        uint256 _milestoneIndex,
        string memory _milestoneDescriptionIpfsHash,
        string memory _evidenceIpfsHash,
        uint256 _fundingPercentage
    ) external nonReentrant onlyResearcher(_projectId) {
        Project storage project = projects[_projectId];

        if (project.status != ProjectStatus.InProgress && project.status != ProjectStatus.Approved) {
            revert ProjectNotApproved();
        }
        if (_milestoneIndex >= project.initialProposedMilestones) {
            revert InvalidMilestoneIndex();
        }
        if (_fundingPercentage == 0 || _fundingPercentage > 100) {
            revert InvalidFundingPercentage();
        }

        if (project.milestones.length == _milestoneIndex) {
            // Adding a new milestone if it's the next logical one
            project.milestones.push(
                Milestone({
                    milestoneId: _milestoneIndex,
                    descriptionIpfsHash: _milestoneDescriptionIpfsHash,
                    evidenceIpfsHash: _evidenceIpfsHash,
                    status: MilestoneStatus.PendingReview,
                    fundingPercentage: _fundingPercentage,
                    reviewer: address(0),
                    reviewFeedbackIpfsHash: "",
                    fundsClaimed: false
                })
            );
        } else if (project.milestones.length > _milestoneIndex) {
            // Updating an existing milestone (e.g., rejected previously, re-submitting)
            Milestone storage milestone = project.milestones[_milestoneIndex];
            if (milestone.status != MilestoneStatus.Rejected) {
                revert MilestoneNotPendingReview(); // Can only re-submit rejected ones
            }
            milestone.descriptionIpfsHash = _milestoneDescriptionIpfsHash;
            milestone.evidenceIpfsHash = _evidenceIpfsHash;
            milestone.status = MilestoneStatus.PendingReview;
            milestone.fundingPercentage = _fundingPercentage;
            milestone.reviewer = address(0);
            milestone.reviewFeedbackIpfsHash = "";
        } else {
            // Trying to submit a milestone out of sequence or beyond initialProposedMilestones
            revert InvalidMilestoneIndex();
        }

        // Set project status to InProgress if it was just Approved and this is the first milestone.
        if (project.status == ProjectStatus.Approved) {
            project.status = ProjectStatus.InProgress;
        }

        emit MilestoneSubmitted(_projectId, _milestoneIndex, msg.sender);
    }

    /**
     * @notice Allows the researcher or admin to update non-critical project details.
     * @param _projectId The ID of the project.
     * @param _newDescriptionIpfsHash The new IPFS hash for the project description.
     */
    function updateProjectDetails(uint256 _projectId, string memory _newDescriptionIpfsHash)
        external
        onlyResearcher(_projectId)
        nonReentrant
    {
        Project storage project = projects[_projectId];
        // Only allow updates if project is not yet fully completed or cancelled.
        if (project.status == ProjectStatus.Completed || project.status == ProjectStatus.Cancelled) {
            revert ProjectNotCancellable();
        }
        project.descriptionIpfsHash = _newDescriptionIpfsHash;
        emit ProjectDetailsUpdated(_projectId, _newDescriptionIpfsHash);
    }

    /**
     * @notice Allows the DAO (owner) or researcher (under specific conditions) to cancel a project.
     * Funds that have not been claimed for milestones will remain in the DAO funding pool.
     * @param _projectId The ID of the project to cancel.
     */
    function cancelProject(uint256 _projectId) external nonReentrant {
        Project storage project = projects[_projectId];

        if (project.projectId == 0) {
            revert ProjectNotFound();
        }

        // Only owner can cancel Approved/InProgress projects, researcher can cancel Proposed ones.
        if (msg.sender != owner() && project.researcher != msg.sender) {
            revert NotProjectResearcher();
        }
        if (msg.sender == project.researcher && project.status != ProjectStatus.Proposed) {
            revert ProjectNotCancellable(); // Researcher can only cancel if still in 'Proposed' state
        }
        if (project.status == ProjectStatus.Completed || project.status == ProjectStatus.Cancelled) {
            revert ProjectNotCancellable();
        }

        // Check for active funding proposals related to this project
        // Note: This check is simplified. A robust system might iterate all proposals.
        if (project.fundingProposalId != 0 && proposals[project.fundingProposalId].status == ProposalStatus.Active) {
            revert ProjectHasActiveProposals();
        }

        project.status = ProjectStatus.Cancelled;
        // No funds are explicitly 'returned' as they are only deducted from daoFundingPool upon milestone claims.
        // Any approved but unclaimed funds are simply no longer claimable by the researcher.

        emit ProjectCancelled(_projectId, msg.sender);
    }

    // --- Reputation System Functions ---

    /**
     * @notice Allows any address to register as a peer reviewer.
     * Future iterations might require staking tokens or having a minimum reputation.
     */
    function registerReviewer() external nonReentrant {
        if (isRegisteredReviewer[msg.sender]) {
            revert ReviewerAlreadyRegistered();
        }
        isRegisteredReviewer[msg.sender] = true;
        emit ReviewerRegistered(msg.sender);
    }

    /**
     * @notice A registered reviewer assesses a submitted milestone and approves/rejects it.
     * @param _projectId The ID of the project.
     * @param _milestoneIndex The index of the milestone being reviewed.
     * @param _isApproved True if the milestone is approved, false otherwise.
     * @param _reviewFeedbackIpfsHash IPFS hash pointing to the reviewer's feedback.
     */
    function reviewMilestone(
        uint256 _projectId,
        uint256 _milestoneIndex,
        bool _isApproved,
        string memory _reviewFeedbackIpfsHash
    ) external onlyRegisteredReviewer nonReentrant {
        Project storage project = projects[_projectId];
        if (project.projectId == 0) {
            revert ProjectNotFound();
        }
        if (_milestoneIndex >= project.milestones.length) {
            revert MilestoneNotFound();
        }

        Milestone storage milestone = project.milestones[_milestoneIndex];
        if (milestone.status != MilestoneStatus.PendingReview) {
            revert MilestoneNotPendingReview();
        }
        if (milestone.reviewer != address(0)) {
            // Already reviewed, or in a state where a reviewer is assigned.
            // This case handles double-review, or review of rejected milestone.
            // For simplicity, we only allow review of PendingReview status.
            revert MilestoneNotPendingReview();
        }

        milestone.reviewer = msg.sender;
        milestone.reviewFeedbackIpfsHash = _reviewFeedbackIpfsHash;

        if (_isApproved) {
            milestone.status = MilestoneStatus.Approved;
            // Reward reviewer for a successful review
            reviewerReputation[msg.sender] += 10;
            emit ReviewerReputationUpdated(msg.sender, reviewerReputation[msg.sender]);

            // If this is the last milestone and it's approved, mark project as completed
            if (_milestoneIndex == project.initialProposedMilestones - 1) {
                 project.status = ProjectStatus.Completed;
                 // Reward researcher for project completion
                 researcherReputation[project.researcher] += 50;
                 emit ResearcherReputationUpdated(project.researcher, researcherReputation[project.researcher]);
            }

        } else {
            milestone.status = MilestoneStatus.Rejected;
            // Penalize researcher for rejected milestone
            if (researcherReputation[project.researcher] >= 5) { // Ensure score doesn't go negative
                researcherReputation[project.researcher] -= 5;
                emit ResearcherReputationUpdated(project.researcher, researcherReputation[project.researcher]);
            }
        }
        emit MilestoneReviewed(_projectId, _milestoneIndex, msg.sender, _isApproved);
    }

    /**
     * @notice View function to get a researcher's current reputation score.
     * @param _researcher The address of the researcher.
     * @return The reputation score.
     */
    function getResearcherReputation(address _researcher) external view returns (uint256) {
        return researcherReputation[_researcher];
    }

    /**
     * @notice View function to get a reviewer's current reputation score.
     * @param _reviewer The address of the reviewer.
     * @return The reputation score.
     */
    function getReviewerReputation(address _reviewer) external view returns (uint256) {
        return reviewerReputation[_reviewer];
    }

    // --- DAO Governance & Funding Functions ---

    /**
     * @notice Allows users to stake governance tokens to gain voting power.
     * @param _amount The amount of governance tokens to stake.
     */
    function stakeGovernanceTokens(uint256 _amount) external nonReentrant {
        if (_amount == 0) {
            revert InvalidAmount();
        }
        if (governanceToken.allowance(msg.sender, address(this)) < _amount) {
            revert NotEnoughAllowance();
        }
        
        governanceToken.transferFrom(msg.sender, address(this), _amount);
        stakedTokens[msg.sender] += _amount;
        totalStakedTokens += _amount;
        emit TokensStaked(msg.sender, _amount);
    }

    /**
     * @notice Allows users to unstake governance tokens. Requires no active votes or cooldown.
     * @param _amount The amount of governance tokens to unstake.
     */
    function unstakeGovernanceTokens(uint256 _amount) external nonReentrant {
        if (_amount == 0) {
            revert InvalidAmount();
        }
        if (stakedTokens[msg.sender] < _amount) {
            revert NotEnoughStakedTokens();
        }

        // --- Advanced Check (not fully implemented for brevity) ---
        // A more robust system would check if msg.sender has active votes on any
        // ongoing proposals and prevent unstaking until those votes are finalized
        // or a cooldown period has passed. This avoids 'vote-buying' or manipulating
        // voting power during active proposals.
        // For simplicity, this check is omitted in this example.

        stakedTokens[msg.sender] -= _amount;
        totalStakedTokens -= _amount;
        governanceToken.transfer(msg.sender, _amount);
        emit TokensUnstaked(msg.sender, _amount);
    }

    /**
     * @notice Creates a new DAO proposal for token holders to vote on funding approval for a proposed project.
     * @param _projectId The ID of the project to create a proposal for.
     */
    function createProjectFundingProposal(uint256 _projectId) external nonReentrant {
        Project storage project = projects[_projectId];
        if (project.projectId == 0) {
            revert ProjectNotFound();
        }
        if (project.status != ProjectStatus.Proposed) {
            revert ProjectAlreadyFunded(); // Or rejected, cancelled, etc.
        }

        uint256 proposalId = nextProposalId++;
        Proposal storage newProposal = proposals[proposalId];

        newProposal.proposalId = proposalId;
        newProposal.proposer = msg.sender;
        newProposal.proposalType = ProposalType.ProjectFunding;
        newProposal.targetId = _projectId;
        newProposal.descriptionIpfsHash = project.descriptionIpfsHash; // Link to project description
        newProposal.voteStartTime = block.timestamp;
        newProposal.voteEndTime = block.timestamp + VOTING_PERIOD_DURATION;
        newProposal.status = ProposalStatus.Active;
        newProposal.minVotesNeeded = (totalStakedTokens * QUORUM_PERCENTAGE_BPS) / 10000;
        newProposal.quorumPercentage = QUORUM_PERCENTAGE_BPS;

        project.status = ProjectStatus.PendingFundingReview;
        project.fundingProposalId = proposalId;

        emit ProposalCreated(proposalId, msg.sender, ProposalType.ProjectFunding, _projectId);
    }

    /**
     * @notice Allows staked token holders to vote on an active proposal.
     * @param _proposalId The ID of the proposal to vote on.
     * @param _support True for 'for' vote, false for 'against' vote.
     */
    function voteOnProposal(uint256 _proposalId, bool _support) external nonReentrant {
        Proposal storage proposal = proposals[_proposalId];
        if (proposal.proposalId == 0) {
            revert ProposalNotFound();
        }
        if (proposal.status != ProposalStatus.Active) {
            revert ProposalNotOpen();
        }
        if (proposal.voteEndTime < block.timestamp) {
            revert VotingPeriodExpired();
        }
        if (stakedTokens[msg.sender] == 0) {
            revert NotEnoughStakedTokens();
        }
        if (proposal.hasVoted[msg.sender]) {
            revert AlreadyVoted();
        }

        proposal.hasVoted[msg.sender] = true;
        if (_support) {
            proposal.votesFor += stakedTokens[msg.sender];
        } else {
            proposal.votesAgainst += stakedTokens[msg.sender];
        }
        emit Voted(_proposalId, msg.sender, _support);
    }

    /**
     * @notice Finalizes the funding decision for a project, considering DAO votes and optionally the AI recommendation.
     * This function is callable by the contract `owner()` in this example, but in a full DAO, it would be
     * triggered by a successful governance proposal or auto-executed if certain conditions are met.
     * @param _projectId The ID of the project to finalize funding for.
     * @param _considerAI Whether to factor in the AI's recommendation when determining final funding.
     * @dev The AI recommendation is only a suggestion. The DAO's governance (represented here by `owner()`)
     *      makes the final decision.
     */
    function finalizeProjectFunding(uint256 _projectId, bool _considerAI) external onlyOwner nonReentrant {
        Project storage project = projects[_projectId];
        if (project.projectId == 0) {
            revert ProjectNotFound();
        }
        if (project.status != ProjectStatus.PendingFundingReview) {
            revert ProjectAlreadyFunded(); // Or completed, cancelled, etc.
        }

        Proposal storage proposal = proposals[project.fundingProposalId];
        if (proposal.proposalId == 0) {
            revert ProposalNotFound();
        }
        if (proposal.status != ProposalStatus.Active || proposal.voteEndTime > block.timestamp) {
            revert VotingPeriodNotOver(); // Need to wait until voting ends
        }
        if (proposal.status == ProposalStatus.Executed) {
            revert ProposalAlreadyFinalized();
        }

        // Check quorum and outcome
        uint256 totalVotes = proposal.votesFor + proposal.votesAgainst;
        bool quorumMet = (totalVotes >= proposal.minVotesNeeded);
        bool proposalPassed = (proposal.votesFor > proposal.votesAgainst);

        if (quorumMet && proposalPassed) {
            proposal.status = ProposalStatus.Succeeded;
            project.status = ProjectStatus.Approved;
            project.totalFundingAllocated = project.fundingGoal; // Default: fund fully if approved

            // AI recommendation consideration logic
            if (_considerAI && project.aiRecommendedAmount > 0) {
                // Example logic: If AI recommends less than the goal, cap at AI's recommendation.
                // If AI recommends more, we still stick to the project's requested goal (or require another proposal).
                if (project.aiRecommendedAmount < project.fundingGoal) {
                     project.totalFundingAllocated = project.aiRecommendedAmount;
                }
                proposal.aiRecommendationConsidered = true;
            }

            // Funds are not moved from daoFundingPool at this stage. They are earmarked conceptually.
            // Actual transfer happens when milestones are claimed.
            // This design ensures funds are not locked if a project fails after approval but before claims.
            
            emit ProjectFundingFinalized(_projectId, project.totalFundingAllocated, ProposalStatus.Succeeded);
            // Reward researcher reputation for successful funding
            researcherReputation[project.researcher] += 20;
            emit ResearcherReputationUpdated(project.researcher, researcherReputation[project.researcher]);

        } else {
            proposal.status = ProposalStatus.Failed;
            project.status = ProjectStatus.Rejected;
            project.totalFundingAllocated = 0; // Explicitly set to zero if rejected
            emit ProjectFundingFinalized(_projectId, 0, ProposalStatus.Failed);
        }
        proposal.status = ProposalStatus.Executed; // Mark as executed after resolution
    }

    /**
     * @notice Allows the researcher to claim funds for a successfully approved milestone.
     * @param _projectId The ID of the project.
     * @param _milestoneIndex The index of the milestone.
     */
    function claimMilestoneFunds(uint256 _projectId, uint256 _milestoneIndex) external nonReentrant onlyResearcher(_projectId) {
        Project storage project = projects[_projectId];
        if (project.projectId == 0) {
            revert ProjectNotFound();
        }
        if (project.status != ProjectStatus.Approved && project.status != ProjectStatus.InProgress && project.status != ProjectStatus.Completed) {
            revert ProjectNotApproved(); // Must be approved or in progress to claim milestones
        }
        if (project.totalFundingAllocated == 0) {
            revert ProjectNotApproved(); // No funds allocated
        }
        if (_milestoneIndex >= project.milestones.length) {
            revert MilestoneNotFound();
        }

        Milestone storage milestone = project.milestones[_milestoneIndex];
        if (milestone.status != MilestoneStatus.Approved) {
            revert MilestoneNotPendingReview(); // Needs to be approved to claim
        }
        if (milestone.fundsClaimed) {
            revert InsufficientMilestoneFunds(); // Funds already claimed for this milestone
        }

        uint256 amountToClaim = (project.totalFundingAllocated * milestone.fundingPercentage) / 100;
        if (amountToClaim == 0) {
            revert InvalidAmount(); // Should not happen if percentages are > 0
        }

        if (daoFundingPool < amountToClaim) {
            revert InsufficientFundingPool(); // DAO must have enough liquid funds
        }

        daoFundingPool -= amountToClaim;
        (bool success, ) = payable(project.researcher).call{value: amountToClaim}("");
        if (!success) {
            daoFundingPool += amountToClaim; // Return funds to pool if transfer fails
            revert FailedToSendFunds();
        }

        milestone.fundsClaimed = true;
        emit MilestoneFundsClaimed(_projectId, _milestoneIndex, msg.sender, amountToClaim);
    }

    /**
     * @notice Allows anyone to deposit funds (native currency, e.g., Ether) into the DAO's main funding pool.
     */
    function depositFunding() external payable nonReentrant {
        if (msg.value == 0) {
            revert InvalidAmount();
        }
        daoFundingPool += msg.value;
        emit FundingDeposited(msg.sender, msg.value);
    }

    /**
     * @notice Allows the DAO admin (owner) to withdraw any surplus funds from the DAO's funding pool.
     * @param _recipient The address to send the funds to.
     * @param _amount The amount of funds to withdraw.
     */
    function withdrawDAOExcessFunds(address _recipient, uint256 _amount) external onlyOwner nonReentrant {
        if (_recipient == address(0)) {
            revert ZeroAddress();
        }
        if (_amount == 0) {
            revert InvalidAmount();
        }
        if (daoFundingPool < _amount) {
            revert InsufficientFundingPool();
        }

        daoFundingPool -= _amount;
        (bool success, ) = payable(_recipient).call{value: _amount}("");
        if (!success) {
            daoFundingPool += _amount; // Revert state if transfer fails
            revert FailedToSendFunds();
        }
        emit DAOExcessFundsWithdrawn(_recipient, _amount);
    }

    // --- AI Integration Functions ---

    /**
     * @notice Triggers an external AI oracle call to get a recommendation for a project's funding allocation.
     * This function would typically be called by a frontend/coordinator after a project proposal is active.
     * It simulates requesting a Chainlink Functions job.
     * @param _projectId The ID of the project to get a recommendation for.
     * @param _requestId A unique request ID provided by the caller to track the request.
     * @dev In a real Chainlink Functions integration, this would call `sendRequest` on the Functions client contract.
     *      The `_requestId` would typically come from the Chainlink client. For this demo, it's provided by the caller.
     */
    function requestAI_GrantRecommendation(uint256 _projectId, uint256 _requestId) external nonReentrant {
        Project storage project = projects[_projectId];
        if (project.projectId == 0) {
            revert ProjectNotFound();
        }
        if (project.status != ProjectStatus.PendingFundingReview) {
            revert ProjectNotOpen(); // Can only request for projects pending review
        }
        if (project.aiRecommendationRequestId != 0) {
            revert AIRecommendationAlreadySet(); // Already requested or fulfilled
        }

        project.aiRecommendationRequestId = _requestId;
        // In a real scenario, this would trigger a Chainlink Functions call to an LLM.
        // The LLM would analyze project.descriptionIpfsHash, researcherReputation[project.researcher],
        // and impactVectors configurations to return a recommendation.
        // For this mock, we just record the request ID.
        // The actual `request` logic (e.g., Chainlink) is abstracted.

        emit AIRecommendationRequested(_projectId, _requestId, msg.sender);
    }

    /**
     * @notice Callback function from the AI oracle to deliver its funding recommendation.
     * Only callable by the trusted oracle address.
     * @param _requestId The ID of the original request.
     * @param _projectId The ID of the project for which the recommendation is given.
     * @param _recommendedFundingAmount The amount of funding recommended by the AI (in native token units).
     * @param _rationaleIpfsHash IPFS hash pointing to the AI's detailed rationale for the recommendation.
     */
    function fulfillAI_GrantRecommendation(
        uint256 _requestId,
        uint256 _projectId,
        uint256 _recommendedFundingAmount,
        string memory _rationaleIpfsHash
    ) external onlyAIOracle nonReentrant {
        Project storage project = projects[_projectId];
        if (project.projectId == 0) {
            revert ProjectNotFound();
        }
        if (project.aiRecommendationRequestId == 0 || project.aiRecommendationRequestId != _requestId) {
            revert AIRecommendationPending(); // Request ID mismatch or no request made
        }
        if (project.aiRecommendedAmount != 0) {
            revert AIRecommendationAlreadySet(); // Already fulfilled
        }

        project.aiRecommendedAmount = _recommendedFundingAmount;
        project.aiRationaleIpfsHash = _rationaleIpfsHash;

        emit AIRecommendationFulfilled(_projectId, _requestId, _recommendedFundingAmount);
    }

    /**
     * @notice Allows the DAO admin (owner) to update the trusted AI oracle contract address.
     * This could be upgraded to a DAO governance proposal for broader decentralization.
     * @param _newOracleAddress The new address for the AI oracle.
     */
    function setAIOracleAddress(address _newOracleAddress) external onlyOwner {
        if (_newOracleAddress == address(0)) {
            revert ZeroAddress();
        }
        aiOracleAddress = _newOracleAddress;
        emit AIOracleAddressUpdated(_newOracleAddress);
    }

    /**
     * @notice Allows DAO admin (owner) to define and weight "impact vectors" that the AI oracle should consider.
     * These vectors influence the AI's funding recommendations. Can also be used to update existing vectors.
     * @param _vectorName A unique name for the impact vector (e.g., "Environmental Impact").
     * @param _weight The importance weight of this vector (e.g., 1-100, higher is more important).
     * @param _threshold The minimum score required for this vector for a project to be considered high-impact.
     * @param _descriptionIpfsHash IPFS hash for a detailed description of the impact vector.
     */
    function configureImpactVector(
        string memory _vectorName,
        uint256 _weight,
        uint256 _threshold,
        string memory _descriptionIpfsHash
    ) external onlyOwner {
        _configureImpactVector(_vectorName, _weight, _threshold, _descriptionIpfsHash);
    }

    /**
     * @dev Internal helper for configuring impact vectors.
     */
    function _configureImpactVector(
        string memory _vectorName,
        uint256 _weight,
        uint256 _threshold,
        string memory _descriptionIpfsHash
    ) internal {
        if (!impactVectors[_vectorName].exists) {
            // Add new vector if it doesn't exist
            impactVectorNames.push(_vectorName);
        }
        // Update or create the vector
        impactVectors[_vectorName] = ImpactVector({
            name: _vectorName,
            weight: _weight,
            threshold: _threshold,
            descriptionIpfsHash: _descriptionIpfsHash,
            exists: true
        });
        emit ImpactVectorConfigured(_vectorName, _weight, _threshold);
    }


    // --- Utility & View Functions ---

    /**
     * @notice View function to retrieve comprehensive details of a project.
     * @param _projectId The ID of the project.
     * @return All relevant project details.
     */
    function getProjectDetails(uint256 _projectId)
        external
        view
        returns (
            uint256 projectId,
            address researcher,
            string memory title,
            string memory descriptionIpfsHash,
            uint256 fundingGoal,
            uint256 totalFundingAllocated,
            ProjectStatus status,
            uint256 initialProposedMilestones,
            uint256 currentMilestoneCount, // Number of milestones added so far
            uint256 aiRecommendedAmount,
            string memory aiRationaleIpfsHash,
            uint256 fundingProposalId
        )
    {
        Project storage project = projects[_projectId];
        if (project.projectId == 0) {
            revert ProjectNotFound();
        }
        return (
            project.projectId,
            project.researcher,
            project.title,
            project.descriptionIpfsHash,
            project.fundingGoal,
            project.totalFundingAllocated,
            project.status,
            project.initialProposedMilestones,
            project.milestones.length, // Current number of milestones added
            project.aiRecommendedAmount,
            project.aiRationaleIpfsHash,
            project.fundingProposalId
        );
    }

    /**
     * @notice View function to get details about a specific DAO proposal.
     * @param _proposalId The ID of the proposal.
     * @return All relevant proposal details.
     */
    function getProposalDetails(uint256 _proposalId)
        external
        view
        returns (
            uint256 proposalId,
            address proposer,
            ProposalType proposalType,
            uint256 targetId,
            string memory descriptionIpfsHash,
            uint256 voteStartTime,
            uint256 voteEndTime,
            uint256 votesFor,
            uint256 votesAgainst,
            ProposalStatus status,
            uint256 minVotesNeeded,
            uint256 quorumPercentage
        )
    {
        Proposal storage proposal = proposals[_proposalId];
        if (proposal.proposalId == 0) {
            revert ProposalNotFound();
        }
        return (
            proposal.proposalId,
            proposal.proposer,
            proposal.proposalType,
            proposal.targetId,
            proposal.descriptionIpfsHash,
            proposal.voteStartTime,
            proposal.voteEndTime,
            proposal.votesFor,
            proposal.votesAgainst,
            proposal.status,
            proposal.minVotesNeeded,
            proposal.quorumPercentage
        );
    }

    /**
     * @notice View function to get the current voting power of an address.
     * @param _voter The address of the voter.
     * @return The amount of staked tokens, representing voting power.
     */
    function getVotingPower(address _voter) external view returns (uint256) {
        return stakedTokens[_voter];
    }

    /**
     * @notice View function to get the current balance of the DAO's funding pool.
     * @return The amount of native currency (e.g., Ether) in the funding pool.
     */
    function getFundingPoolBalance() external view returns (uint256) {
        return daoFundingPool;
    }

    /**
     * @notice View function to get details of a specific impact vector.
     * @param _vectorName The name of the impact vector.
     * @return Impact vector details.
     */
    function getImpactVector(string memory _vectorName) external view returns (string memory name, uint256 weight, uint256 threshold, string memory descriptionIpfsHash) {
        ImpactVector storage vector = impactVectors[_vectorName];
        if (!vector.exists) {
            revert ImpactVectorNotFound();
        }
        return (vector.name, vector.weight, vector.threshold, vector.descriptionIpfsHash);
    }

    /**
     * @notice View function to get the list of configured impact vector names.
     * @return An array of impact vector names.
     */
    function getImpactVectorNames() external view returns (string[] memory) {
        return impactVectorNames;
    }

    /**
     * @notice Fallback function to accept direct Ether transfers to the contract.
     * For any direct Ether sent without calling `depositFunding`.
     */
    receive() external payable {
        if (msg.value > 0) {
            daoFundingPool += msg.value;
            emit FundingDeposited(msg.sender, msg.value);
        }
    }
}
```