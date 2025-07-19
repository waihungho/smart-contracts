This Solidity smart contract, named `QuantumNexus`, is designed as a decentralized innovation and knowledge curation protocol. It combines several advanced concepts: a dynamic, non-transferable (soulbound-like) reputation system with liquid delegation, a multi-stage project incubation and funding mechanism, and a simulated community-driven AI-assisted insight validation process that leads to the creation of immutable on-chain "Knowledge Fragments."

This contract aims to be creative and trendy by:
*   **Decentralized Reputation:** A reputation system that evolves with on-chain participation (proposing, funding, voting, curating) and is non-transferable, aligning with "soulbound token" concepts for identity and verifiable credentials. It also supports liquid delegation for flexible governance.
*   **Simulated AI Integration:** While actual AI computation is off-chain, the contract provides an on-chain framework for "AI Oracles" to submit insights and for the community to validate their utility through reputation-weighted voting. This bridges the gap between on-chain governance and off-chain AI.
*   **Generative/Curated Knowledge Fragments:** The protocol allows for the on-chain "minting" of immutable knowledge snippets, deriving from successfully validated AI insights or completed projects. This creates a public, verifiable record of validated information, linking community consensus to knowledge creation.
*   **Comprehensive Project Lifecycle:** It covers the full journey from project proposal and funding to community approval, deliverable submission, and success/failure assessment, including a basic dispute mechanism.

---

## QuantumNexus - Decentralized Innovation & Reputation Protocol

**Outline:**

**I. Core Infrastructure & State Management:**
   Manages basic contract setup, pausing functionality for upgrades/emergencies, and protocol fee handling.

**II. Reputation System:**
   Implements a dynamic, non-transferable reputation score for users. This score is earned through positive contributions to the protocol and can be delegated to others for voting power, enabling a form of liquid democracy.

**III. Project Lifecycle Management:**
   Defines a multi-stage process for projects:
   *   **Proposal:** Users propose ideas with a funding goal and fee.
   *   **Funding:** Community members contribute Ether to projects.
   *   **Approval:** Reputation-weighted voting to approve projects for incubation.
   *   **Incubation:** Project team develops their deliverable.
   *   **Deliverable Submission:** Project team submits a hash of their completed work.
   *   **Review & Completion:** Community votes on the success of the deliverable, determining project completion or failure, influencing reputations.
   *   **Dispute:** A mechanism to flag projects for review.

**IV. AI-Assisted Curation & Knowledge Fragments:**
   Introduces a system for handling "AI Insights" and "Knowledge Fragments":
   *   **AI Oracle Submission:** Designated "AI Oracles" (simulated off-chain AI agents) submit insights.
   *   **Community Validation:** Users vote on the utility of AI insights using their reputation.
   *   **Knowledge Fragment Curation:** High-reputation users can curate immutable on-chain "Knowledge Fragments" based on validated AI insights or successfully completed projects.

**V. Governance & Parameter Updates:**
   Provides functions for the owner (which could eventually be a DAO) to adjust key protocol parameters and manage collected fees.

---

**Function Summary:**

**I. Core Infrastructure & State Management**
1.  `constructor(address _initialProtocolFeeRecipient)`: Initializes the contract owner, protocol fee recipient, and initial parameters.
2.  `pauseContract()`: **(Ownable, Pausable)** Pauses most state-changing operations for maintenance or emergencies.
3.  `unpauseContract()`: **(Ownable, Pausable)** Resumes contract operations.
4.  `setProtocolFeeRecipient(address _newRecipient)`: **(Ownable)** Sets the address that receives collected protocol fees.
5.  `setProjectCreationFee(uint256 _newFee)`: **(Ownable)** Sets the fee required to propose a new project.
6.  `withdrawProtocolFees()`: **(ReentrancyGuard)** Allows the designated `protocolFeeRecipient` to withdraw accumulated fees.

**II. Reputation System**
7.  `claimInitialReputation()`: **(WhenNotPaused)** Allows a new user to claim a small initial reputation score once.
8.  `delegateReputationPower(address _delegatee)`: **(WhenNotPaused)** Allows a user to delegate their voting power (reputation score) to another address.
9.  `undelegateReputationPower()`: **(WhenNotPaused)** Allows a user to revoke their reputation delegation.
10. `getEffectiveReputation(address _user) public view returns (uint256)`: Calculates the effective reputation score for voting, considering delegations.

**III. Project Lifecycle Management**
11. `proposeProject(string memory _metadataURI, uint256 _fundingGoal, address _fundsRecipient)`: **(WhenNotPaused, ReentrancyGuard)** Allows a user to propose a new project, paying a fee and providing details.
12. `fundProject(uint256 _projectId)`: **(WhenNotPaused, ReentrancyGuard)** Allows users to contribute Ether to a proposed project.
13. `voteForProjectApproval(uint256 _projectId)`: **(WhenNotPaused)** Allows users to vote for a project's approval using their effective reputation.
14. `finalizeProjectFunding(uint256 _projectId)`: **(WhenNotPaused, ReentrancyGuard)** Finalizes funding for a project if its goal is met and it receives enough approval votes, transferring funds to the project's recipient.
15. `submitProjectDeliverableHash(uint256 _projectId, string memory _deliverableHash)`: **(WhenNotPaused)** Allows the project proposer to submit a hash of their completed deliverable.
16. `voteOnProjectDeliverable(uint256 _projectId, bool _success)`: **(WhenNotPaused)** Allows users to vote on the success or failure of a project's deliverable using their effective reputation.
17. `markProjectComplete(uint256 _projectId)`: **(WhenNotPaused)** Marks a project as completed or failed based on community votes on its deliverable, updating reputations.
18. `initiateProjectDispute(uint256 _projectId, string memory _reason)`: **(WhenNotPaused)** Allows any user to initiate a dispute for an active project.

**IV. AI-Assisted Curation & Knowledge Fragments**
19. `setAIOracle(address _oracleAddress, bool _status)`: **(Ownable)** Registers or unregisters an address as an "AI Oracle".
20. `submitAIAssistedInsight(string memory _insightURI)`: **(OnlyAIOracle, WhenNotPaused)** Allows a registered AI Oracle to submit an AI-generated insight.
21. `voteOnAIInsightUtility(uint256 _insightId, bool _useful)`: **(WhenNotPaused)** Allows users to vote on the utility/accuracy of an AI insight using their effective reputation.
22. `curateKnowledgeFragment(string memory _contentHash, uint256 _sourceAIInsightId, uint256 _sourceProjectId)`: **(WhenNotPaused)** Allows high-reputation users to curate an immutable "Knowledge Fragment" based on a validated AI insight or completed project.
23. `getKnowledgeFragmentContent(uint256 _fragmentId) public view returns (string memory)`: Retrieves the content hash of a specific Knowledge Fragment.

**V. Governance & Parameter Updates (Simple for now, could be DAO)**
24. `updateProjectApprovalThreshold(uint256 _newThreshold)`: **(Ownable)** Updates the minimum total reputation required for project approval.
25. `updateAIInsightVoteThreshold(uint256 _newThreshold)`: **(Ownable)** Updates the minimum total reputation required for AI insight validation votes.
26. `updateDeliverableSuccessVoteRatio(uint256 _newRatio)`: **(Ownable)** Updates the required success vote ratio for project deliverables (scaled by 10000).
27. `updateAIInsightValidationRatio(uint256 _newRatio)`: **(Ownable)** Updates the required useful vote ratio for AI insight validation (scaled by 10000).

---
```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/**
 * @title QuantumNexus - Decentralized Innovation & Reputation Protocol
 * @author YourName (placeholder for this example)
 * @notice A novel smart contract designed to foster decentralized innovation, reputation building,
 *         and community-driven AI-assisted knowledge curation.
 *         This protocol serves as a hub where ideas are proposed, projects are funded,
 *         and contributions are recognized through a dynamic, non-transferable reputation system.
 *         It incorporates a unique mechanism for community validation of "AI-assisted insights"
 *         leading to the creation of on-chain, immutable "Knowledge Fragments".
 *
 * Outline:
 * I. Core Infrastructure & State Management
 *    - Basic setup, pausing mechanism, protocol fee management.
 * II. Reputation System
 *    - Dynamic, non-transferable reputation (Soulbound-like) tied to on-chain actions.
 *    - Supports liquid delegation of voting power.
 * III. Project Lifecycle Management
 *    - Comprehensive flow from project proposal, funding, community approval,
 *      deliverable submission, to completion and dispute resolution.
 * IV. AI-Assisted Curation & Knowledge Fragments
 *    - Mechanism for "AI Oracles" to submit insights.
 *    - Community voting on AI insight utility.
 *    - Creation of immutable "Knowledge Fragments" based on validated insights or project outcomes.
 * V. Governance & Parameter Updates
 *    - Functions for updating core protocol parameters and fee withdrawal.
 */
contract QuantumNexus is Ownable, Pausable, ReentrancyGuard {

    // --- I. Core Infrastructure & State Management ---

    /// @dev Emitted when the contract is paused.
    event Paused(address account);
    /// @dev Emitted when the contract is unpaused.
    event Unpaused(address account);
    /// @dev Emitted when the protocol fee recipient is updated.
    event ProtocolFeeRecipientUpdated(address indexed oldRecipient, address indexed newRecipient);
    /// @dev Emitted when the project creation fee is updated.
    event ProjectCreationFeeUpdated(uint256 indexed oldFee, uint256 indexed newFee);
    /// @dev Emitted when protocol fees are withdrawn.
    event ProtocolFeeWithdrawn(address indexed recipient, uint256 amount);

    address public protocolFeeRecipient;
    uint256 public projectCreationFee;
    uint256 public totalProtocolFeesCollected;

    // --- II. Reputation System ---

    /// @dev Emitted when a user's reputation score is updated.
    event ReputationUpdated(address indexed user, uint256 newScore, string reason);
    /// @dev Emitted when a user delegates their reputation power.
    event ReputationDelegated(address indexed delegator, address indexed delegatee);
    /// @dev Emitted when a user undelegates their reputation power.
    event ReputationUndelegated(address indexed delegator, address indexed delegatee);

    /// @notice Maps user addresses to their non-transferable reputation score.
    mapping(address => uint256) public reputationScores;
    /// @notice Maps delegator addresses to the address they have delegated their reputation power to.
    mapping(address => address) public delegatedReputationTo;
    /// @notice Maps delegatee addresses to their current total delegated power.
    mapping(address => uint256) public delegatedPower;

    uint256 public constant INITIAL_REPUTATION_CLAIM = 10;
    uint256 public constant MAX_REPUTATION_BOOST_PER_ACTION = 50; // Max points gained for a single positive action
    uint256 public constant MAX_REPUTATION_PENALTY_PER_ACTION = 25; // Max points lost for a single negative action

    // --- III. Project Lifecycle Management ---

    /// @dev Emitted when a new project is proposed.
    event ProjectProposed(uint256 indexed projectId, address indexed proposer, uint256 goal, string metadataURI);
    /// @dev Emitted when funds are contributed to a project.
    event ProjectFunded(uint256 indexed projectId, address indexed contributor, uint256 amount);
    /// @dev Emitted when a project receives an approval vote.
    event ProjectApprovedVote(uint256 indexed projectId, address indexed voter, bool approved);
    /// @dev Emitted when a project reaches its funding goal and is ready for incubation.
    event ProjectFundingFinalized(uint256 indexed projectId, uint256 totalFundedAmount, address indexed fundsRecipient);
    /// @dev Emitted when a project deliverable hash is submitted.
    event ProjectDeliverableSubmitted(uint256 indexed projectId, string deliverableHash);
    /// @dev Emitted when a vote is cast on a project's deliverable.
    event ProjectDeliverableVoted(uint256 indexed projectId, address indexed voter, bool success);
    /// @dev Emitted when a project is marked complete (either success or failure).
    event ProjectCompleted(uint256 indexed projectId, address indexed completer, ProjectStatus status);
    /// @dev Emitted when a project dispute is initiated.
    event ProjectDisputeInitiated(uint256 indexed projectId, address indexed disputer, string reason);

    enum ProjectStatus { Proposed, Funding, Incubation, DeliverableSubmitted, Dispute, Completed, Failed }

    struct Project {
        address proposer;
        string metadataURI; // IPFS hash or similar for detailed project description
        uint256 fundingGoal;
        uint256 currentFunding;
        ProjectStatus status;
        uint256 proposalTimestamp;
        address fundsRecipientAddress; // Multi-sig or designated address for project funds
        string deliverableHash; // Hash of the final project output (e.g., IPFS CID)
        uint256 totalApprovalVotesReputation; // Sum of reputation scores for 'approve' votes
        uint256 totalDeliverableSuccessVotesReputation; // Sum of reputation for 'success' votes
        uint256 totalDeliverableFailureVotesReputation; // Sum of reputation for 'failure' votes
    }

    /// @notice Maps project IDs to their respective Project struct.
    mapping(uint256 => Project) public projects;
    uint256 public nextProjectId;

    /// @notice Tracks contributions per project per address.
    mapping(uint256 => mapping(address => uint256)) public projectContributions;
    /// @notice Tracks if an address has voted for project approval.
    mapping(uint256 => mapping(address => bool)) public projectApprovalVotes;
    /// @notice Tracks if an address has voted on a project deliverable.
    mapping(uint256 => mapping(address => bool)) public projectDeliverableVotes;

    uint256 public projectApprovalThresholdReputation; // Minimum total reputation votes to approve a project
    uint256 public deliverableSuccessVoteThresholdRatio; // e.g., 7000 for 70% (scaled by 10000)

    // --- IV. AI-Assisted Curation & Knowledge Fragments ---

    /// @dev Emitted when an AI-assisted insight is submitted by a registered oracle.
    event AIAssistedInsightSubmitted(uint256 indexed insightId, address indexed oracle, string insightURI);
    /// @dev Emitted when a user votes on the utility of an AI insight.
    event AIInsightUtilityVoted(uint256 indexed insightId, address indexed voter, bool useful);
    /// @dev Emitted when a new knowledge fragment is curated.
    event KnowledgeFragmentCurated(uint256 indexed fragmentId, address indexed curator, uint256 sourceInsightId, uint256 sourceProjectId, string contentHash);

    struct AIInsight {
        address oracle;
        string insightURI; // IPFS hash or similar for the raw AI insight data
        uint256 submissionTimestamp;
        uint256 totalUtilityVotesReputation; // Sum of reputation for 'useful' votes
        uint256 totalDisutilityVotesReputation; // Sum of reputation for 'not useful' votes
        bool isValidated; // True if enough 'useful' votes based on threshold
    }

    struct KnowledgeFragment {
        address curator; // Address that minted this fragment
        string contentHash; // Immutable hash of the knowledge fragment content
        uint256 creationTimestamp;
        uint256 sourceAIInsightId; // ID of the AI insight it was derived from (0 if none)
        uint256 sourceProjectId; // ID of the project it was derived from (0 if none)
    }

    /// @notice Maps AI insight IDs to their struct.
    mapping(uint256 => AIInsight) public aiInsights;
    uint256 public nextAIInsightId;

    /// @notice Tracks if an address has voted on an AI insight.
    mapping(uint256 => mapping(address => bool)) public aiInsightVotes;

    /// @notice Maps knowledge fragment IDs to their struct.
    mapping(uint256 => KnowledgeFragment) public knowledgeFragments;
    uint256 public nextKnowledgeFragmentId;

    /// @notice Addresses registered as "AI Oracles" that can submit insights.
    mapping(address => bool) public isAIOracle;

    uint256 public aiInsightVoteThresholdReputation; // Minimum total reputation votes for an AI insight to be considered for validation
    uint256 public aiInsightValidationRatio; // e.g., 7500 for 75% useful votes needed (scaled by 10000)

    // --- Constructor & Initial Setup ---

    /**
     * @notice Initializes the contract, setting the initial owner and core parameters.
     * @param _initialProtocolFeeRecipient The address designated to receive collected protocol fees.
     */
    constructor(address _initialProtocolFeeRecipient) Ownable(msg.sender) {
        require(_initialProtocolFeeRecipient != address(0), "Invalid fee recipient");
        protocolFeeRecipient = _initialProtocolFeeRecipient;
        projectCreationFee = 0.01 ether; // Example: 0.01 ETH
        projectApprovalThresholdReputation = 500; // Example: 500 total reputation for project approval
        deliverableSuccessVoteThresholdRatio = 7000; // Example: 70% of reputation votes for success
        aiInsightVoteThresholdReputation = 200; // Example: 200 total reputation for AI insight validation
        aiInsightValidationRatio = 7500; // Example: 75% useful votes for AI insight validation
        nextProjectId = 1;
        nextAIInsightId = 1;
        nextKnowledgeFragmentId = 1;
    }

    // --- Modifiers ---

    /**
     * @dev Restricts access to functions to only addresses registered as AI Oracles.
     */
    modifier onlyAIOracle() {
        require(isAIOracle[msg.sender], "Not a registered AI Oracle");
        _;
    }

    // --- I. Core Infrastructure & State Management ---

    /**
     * @notice Pauses the contract, preventing most state-changing operations.
     * @dev Only the owner can call this. Inherited from Pausable.
     */
    function pauseContract() external onlyOwner {
        _pause();
    }

    /**
     * @notice Unpauses the contract, allowing operations to resume.
     * @dev Only the owner can call this. Inherited from Pausable.
     */
    function unpauseContract() external onlyOwner {
        _unpause();
    }

    /**
     * @notice Sets the address that receives protocol fees.
     * @dev Only the contract owner can call this.
     * @param _newRecipient The new address to receive protocol fees.
     */
    function setProtocolFeeRecipient(address _newRecipient) external onlyOwner {
        require(_newRecipient != address(0), "Invalid recipient address");
        emit ProtocolFeeRecipientUpdated(protocolFeeRecipient, _newRecipient);
        protocolFeeRecipient = _newRecipient;
    }

    /**
     * @notice Sets the fee required to propose a new project.
     * @dev Only the contract owner can call this.
     * @param _newFee The new project creation fee in Wei.
     */
    function setProjectCreationFee(uint256 _newFee) external onlyOwner {
        emit ProjectCreationFeeUpdated(projectCreationFee, _newFee);
        projectCreationFee = _newFee;
    }

    /**
     * @notice Allows the protocol fee recipient to withdraw accumulated fees.
     * @dev Only the designated `protocolFeeRecipient` can call this. Uses ReentrancyGuard for security.
     */
    function withdrawProtocolFees() external nonReentrant {
        require(msg.sender == protocolFeeRecipient, "Not the protocol fee recipient");
        uint256 amount = totalProtocolFeesCollected;
        require(amount > 0, "No fees to withdraw");
        totalProtocolFeesCollected = 0;
        (bool success,) = payable(msg.sender).call{value: amount}("");
        require(success, "Fee withdrawal failed");
        emit ProtocolFeeWithdrawn(msg.sender, amount);
    }

    // --- II. Reputation System ---

    /**
     * @notice Internal function to update a user's reputation score.
     * @dev This function is only called internally by other functions as a result of on-chain actions.
     * @param _user The address whose reputation score is to be updated.
     * @param _amount The amount to adjust the reputation by (can be positive or negative).
     * @param _reason A string describing the reason for the reputation update.
     */
    function _updateReputationScore(address _user, int256 _amount, string memory _reason) internal {
        if (_amount > 0) {
            reputationScores[_user] += uint256(_amount);
        } else {
            // Prevent reputation from going below zero
            if (reputationScores[_user] < uint256(-_amount)) {
                reputationScores[_user] = 0;
            } else {
                reputationScores[_user] -= uint256(-_amount);
            }
        }
        emit ReputationUpdated(_user, reputationScores[_user], _reason);
    }

    /**
     * @notice Allows a new user to claim a small initial reputation score.
     * @dev Can only be called once per address. Requires `msg.sender` to have 0 reputation initially.
     */
    function claimInitialReputation() external whenNotPaused {
        require(reputationScores[msg.sender] == 0, "Initial reputation already claimed");
        _updateReputationScore(msg.sender, int256(INITIAL_REPUTATION_CLAIM), "Initial claim");
    }

    /**
     * @notice Allows a user to delegate their reputation power to another address for voting.
     * @dev The delegator's reputation is added to the delegatee's effective voting power.
     *      A user cannot delegate to themselves or to an address that is already delegating to them (circular delegation).
     * @param _delegatee The address to delegate reputation power to.
     */
    function delegateReputationPower(address _delegatee) external whenNotPaused {
        require(_delegatee != address(0), "Cannot delegate to zero address");
        require(_delegatee != msg.sender, "Cannot delegate to yourself");
        require(delegatedReputationTo[msg.sender] == address(0), "Already delegated"); // Only one active delegation
        require(delegatedReputationTo[_delegatee] != msg.sender, "Circular delegation not allowed");

        uint256 delegatorRep = reputationScores[msg.sender];
        require(delegatorRep > 0, "Delegator must have reputation to delegate");

        delegatedReputationTo[msg.sender] = _delegatee;
        delegatedPower[_delegatee] += delegatorRep;

        emit ReputationDelegated(msg.sender, _delegatee);
    }

    /**
     * @notice Allows a user to undelegate their reputation power.
     * @dev Revokes the active delegation and adjusts the delegatee's effective voting power.
     */
    function undelegateReputationPower() external whenNotPaused {
        address currentDelegatee = delegatedReputationTo[msg.sender];
        require(currentDelegatee != address(0), "No active delegation to undelegate");

        uint256 delegatorRep = reputationScores[msg.sender];
        // This check prevents underflow if, for some reason, the delegated rep was already deducted
        // (e.g., if the delegator lost reputation after delegating).
        // In a real system, one might consider adjusting delegatedPower dynamically or penalizing.
        delegatedPower[currentDelegatee] = delegatedPower[currentDelegatee] >= delegatorRep ?
                                           delegatedPower[currentDelegatee] - delegatorRep : 0;

        delegatedReputationTo[msg.sender] = address(0);
        emit ReputationUndelegated(msg.sender, currentDelegatee);
    }

    /**
     * @notice Gets the effective reputation score for voting, considering delegations.
     * @dev If an address has delegated their power, their effective score is 0. If they have received delegations,
     *      their effective score includes their own reputation plus any delegated power they have received.
     * @param _user The address to query the effective reputation for.
     * @return The effective reputation score for voting.
     */
    function getEffectiveReputation(address _user) public view returns (uint256) {
        if (delegatedReputationTo[_user] != address(0)) {
            // If user has delegated their power, they have no effective power for direct voting
            return 0;
        }
        // User's own reputation + any delegated power they have received
        return reputationScores[_user] + delegatedPower[_user];
    }

    // --- III. Project Lifecycle Management ---

    /**
     * @notice Allows a user to propose a new project.
     * @dev Requires a project creation fee and an initial reputation score.
     * @param _metadataURI A URI pointing to off-chain project details (e.g., IPFS CID).
     * @param _fundingGoal The target funding amount in Wei for the project.
     * @param _fundsRecipient The address designated to receive project funds if successfully funded.
     */
    function proposeProject(
        string memory _metadataURI,
        uint256 _fundingGoal,
        address _fundsRecipient
    ) external payable whenNotPaused nonReentrant {
        require(reputationScores[msg.sender] > 0, "Proposer must have reputation to propose a project");
        require(msg.value == projectCreationFee, "Incorrect project creation fee provided");
        require(_fundingGoal > 0, "Funding goal must be greater than zero");
        require(_fundsRecipient != address(0), "Invalid funds recipient address");
        require(bytes(_metadataURI).length > 0, "Project metadata URI cannot be empty");

        totalProtocolFeesCollected += msg.value;

        uint256 projectId = nextProjectId++;
        projects[projectId] = Project({
            proposer: msg.sender,
            metadataURI: _metadataURI,
            fundingGoal: _fundingGoal,
            currentFunding: 0,
            status: ProjectStatus.Proposed,
            proposalTimestamp: block.timestamp,
            fundsRecipientAddress: _fundsRecipient,
            deliverableHash: "",
            totalApprovalVotesReputation: 0,
            totalDeliverableSuccessVotesReputation: 0,
            totalDeliverableFailureVotesReputation: 0
        });

        _updateReputationScore(msg.sender, int256(MAX_REPUTATION_BOOST_PER_ACTION / 2), "Project proposal submitted");
        emit ProjectProposed(projectId, msg.sender, _fundingGoal, _metadataURI);
    }

    /**
     * @notice Allows users to contribute Ether to a proposed project.
     * @dev Funds are held in escrow by the contract until the project is finalized.
     * @param _projectId The ID of the project to fund.
     */
    function fundProject(uint256 _projectId) external payable whenNotPaused nonReentrant {
        Project storage project = projects[_projectId];
        require(project.proposer != address(0), "Project does not exist");
        require(project.status == ProjectStatus.Proposed || project.status == ProjectStatus.Funding, "Project not in funding stage");
        require(msg.value > 0, "Contribution must be greater than zero");
        require(project.currentFunding + msg.value <= project.fundingGoal, "Contribution would exceed project funding goal");

        project.currentFunding += msg.value;
        projectContributions[_projectId][msg.sender] += msg.value;

        // Set status to Funding if it was Proposed
        if (project.status == ProjectStatus.Proposed) {
            project.status = ProjectStatus.Funding;
        }

        _updateReputationScore(msg.sender, int256(MAX_REPUTATION_BOOST_PER_ACTION / 4), "Project funding contribution");
        emit ProjectFunded(_projectId, msg.sender, msg.value);
    }

    /**
     * @notice Allows users to vote for a project's approval, moving it to Incubation.
     * @dev Voting power is based on effective reputation. Each user can vote once per project for approval.
     *      Requires the project to have already met its funding goal.
     * @param _projectId The ID of the project to vote on.
     */
    function voteForProjectApproval(uint256 _projectId) external whenNotPaused {
        Project storage project = projects[_projectId];
        require(project.proposer != address(0), "Project does not exist");
        require(project.status == ProjectStatus.Funding, "Project is not in funding stage for approval vote");
        require(project.currentFunding >= project.fundingGoal, "Project has not met its funding goal yet");
        require(!projectApprovalVotes[_projectId][msg.sender], "Already voted for this project's approval");

        uint256 effectiveRep = getEffectiveReputation(msg.sender);
        require(effectiveRep > 0, "Voter must have effective reputation to vote");

        projectApprovalVotes[_projectId][msg.sender] = true;
        project.totalApprovalVotesReputation += effectiveRep;

        _updateReputationScore(msg.sender, int256(MAX_REPUTATION_BOOST_PER_ACTION / 8), "Project approval vote cast");
        emit ProjectApprovedVote(_projectId, msg.sender, true);
    }

    /**
     * @notice Finalizes a project if its funding goal has been met and enough approval votes are cast.
     * @dev Transfers collected funds to the project's designated recipient. Can be called by anyone.
     * @param _projectId The ID of the project to finalize.
     */
    function finalizeProjectFunding(uint256 _projectId) external whenNotPaused nonReentrant {
        Project storage project = projects[_projectId];
        require(project.proposer != address(0), "Project does not exist");
        require(project.status == ProjectStatus.Funding, "Project not in funding stage");
        require(project.currentFunding >= project.fundingGoal, "Project has not met its funding goal");
        require(project.totalApprovalVotesReputation >= projectApprovalThresholdReputation, "Not enough reputation votes for project approval");
        require(project.fundsRecipientAddress != address(0), "Project has no valid funds recipient address");

        project.status = ProjectStatus.Incubation;

        // Transfer funds to the project's designated recipient
        (bool success,) = payable(project.fundsRecipientAddress).call{value: project.currentFunding}("");
        require(success, "Funds transfer to project recipient failed");

        _updateReputationScore(project.proposer, int256(MAX_REPUTATION_BOOST_PER_ACTION), "Project incubation successfully started");
        emit ProjectFundingFinalized(_projectId, project.currentFunding, project.fundsRecipientAddress);
    }

    /**
     * @notice Allows the project proposer to submit a hash of the project's final deliverable.
     * @dev This moves the project into the 'DeliverableSubmitted' stage for community review.
     * @param _projectId The ID of the project.
     * @param _deliverableHash The hash (e.g., IPFS CID) of the completed project deliverable.
     */
    function submitProjectDeliverableHash(uint256 _projectId, string memory _deliverableHash) external whenNotPaused {
        Project storage project = projects[_projectId];
        require(project.proposer != address(0), "Project does not exist");
        require(msg.sender == project.proposer, "Only project proposer can submit deliverable");
        require(project.status == ProjectStatus.Incubation, "Project not in incubation stage to submit deliverable");
        require(bytes(_deliverableHash).length > 0, "Deliverable hash cannot be empty");

        project.deliverableHash = _deliverableHash;
        project.status = ProjectStatus.DeliverableSubmitted;
        emit ProjectDeliverableSubmitted(_projectId, _deliverableHash);
    }

    /**
     * @notice Allows users to vote on the success or failure of a project's submitted deliverable.
     * @dev Voting power is based on effective reputation. Each user can vote once per project deliverable.
     * @param _projectId The ID of the project.
     * @param _success True for success, false for failure.
     */
    function voteOnProjectDeliverable(uint256 _projectId, bool _success) external whenNotPaused {
        Project storage project = projects[_projectId];
        require(project.proposer != address(0), "Project does not exist");
        require(project.status == ProjectStatus.DeliverableSubmitted, "Project not in deliverable review stage");
        require(!projectDeliverableVotes[_projectId][msg.sender], "Already voted on this project's deliverable");

        uint256 effectiveRep = getEffectiveReputation(msg.sender);
        require(effectiveRep > 0, "Voter must have effective reputation to vote");

        projectDeliverableVotes[_projectId][msg.sender] = true;

        if (_success) {
            project.totalDeliverableSuccessVotesReputation += effectiveRep;
            _updateReputationScore(msg.sender, int256(MAX_REPUTATION_BOOST_PER_ACTION / 8), "Project deliverable success vote cast");
        } else {
            project.totalDeliverableFailureVotesReputation += effectiveRep;
            _updateReputationScore(msg.sender, -int256(MAX_REPUTATION_PENALTY_PER_ACTION / 8), "Project deliverable failure vote cast");
        }
        emit ProjectDeliverableVoted(_projectId, msg.sender, _success);
    }

    /**
     * @notice Marks a project as complete (success or failure) if the community votes on its deliverable.
     * @dev Can be called by any participant after sufficient votes are cast to determine outcome.
     * @param _projectId The ID of the project to mark complete.
     */
    function markProjectComplete(uint256 _projectId) external whenNotPaused {
        Project storage project = projects[_projectId];
        require(project.proposer != address(0), "Project does not exist");
        require(project.status == ProjectStatus.DeliverableSubmitted, "Project not in deliverable review stage");

        uint256 totalDeliverableVotesRep = project.totalDeliverableSuccessVotesReputation + project.totalDeliverableFailureVotesReputation;
        require(totalDeliverableVotesRep > 0, "No votes cast on deliverable yet to determine outcome");

        uint256 successRatio = (project.totalDeliverableSuccessVotesReputation * 10000) / totalDeliverableVotesRep;

        if (successRatio >= deliverableSuccessVoteThresholdRatio) {
            project.status = ProjectStatus.Completed;
            _updateReputationScore(project.proposer, int256(MAX_REPUTATION_BOOST_PER_ACTION * 2), "Project successfully completed");
            emit ProjectCompleted(_projectId, msg.sender, ProjectStatus.Completed);
        } else {
            project.status = ProjectStatus.Failed;
            _updateReputationScore(project.proposer, -int256(MAX_REPUTATION_PENALTY_PER_ACTION * 2), "Project failed community review");
            emit ProjectCompleted(_projectId, msg.sender, ProjectStatus.Failed);
        }
    }

    /**
     * @notice Allows any user to initiate a dispute for a project that is in Incubation or DeliverableSubmitted stage.
     * @dev This moves the project to a 'Dispute' status, implying further review (e.g., off-chain arbitration or DAO vote).
     * @param _projectId The ID of the project to dispute.
     * @param _reason A description or hash pointing to the reason for the dispute.
     */
    function initiateProjectDispute(uint256 _projectId, string memory _reason) external whenNotPaused {
        Project storage project = projects[_projectId];
        require(project.proposer != address(0), "Project does not exist");
        require(project.status == ProjectStatus.Incubation || project.status == ProjectStatus.DeliverableSubmitted, "Project not in a disputable stage");
        require(reputationScores[msg.sender] > 0, "Disputer must have reputation");
        require(bytes(_reason).length > 0, "Dispute reason cannot be empty");

        project.status = ProjectStatus.Dispute;
        // A small reputation penalty to discourage frivolous disputes.
        _updateReputationScore(msg.sender, -int256(MAX_REPUTATION_PENALTY_PER_ACTION / 2), "Initiated project dispute");
        emit ProjectDisputeInitiated(_projectId, msg.sender, _reason);
    }

    // --- IV. AI-Assisted Curation & Knowledge Fragments ---

    /**
     * @notice Registers or unregisters an address as an AI Oracle, allowing it to submit insights.
     * @dev Only the contract owner can call this.
     * @param _oracleAddress The address to register/unregister as an AI Oracle.
     * @param _status True to register, false to unregister.
     */
    function setAIOracle(address _oracleAddress, bool _status) external onlyOwner {
        isAIOracle[_oracleAddress] = _status;
    }

    /**
     * @notice Allows a registered AI Oracle to submit an AI-generated insight.
     * @param _insightURI A URI (e.g., IPFS CID) pointing to the raw AI insight data.
     */
    function submitAIAssistedInsight(string memory _insightURI) external onlyAIOracle whenNotPaused {
        require(bytes(_insightURI).length > 0, "Insight URI cannot be empty");

        uint256 insightId = nextAIInsightId++;
        aiInsights[insightId] = AIInsight({
            oracle: msg.sender,
            insightURI: _insightURI,
            submissionTimestamp: block.timestamp,
            totalUtilityVotesReputation: 0,
            totalDisutilityVotesReputation: 0,
            isValidated: false
        });

        _updateReputationScore(msg.sender, int256(MAX_REPUTATION_BOOST_PER_ACTION / 4), "AI insight submitted");
        emit AIAssistedInsightSubmitted(insightId, msg.sender, _insightURI);
    }

    /**
     * @notice Allows users to vote on the utility/accuracy of a submitted AI insight.
     * @dev Voting power is based on effective reputation. Each user can vote once per insight.
     *      If the insight reaches enough useful votes, it becomes validated.
     * @param _insightId The ID of the AI insight to vote on.
     * @param _useful True if the insight is useful, false otherwise.
     */
    function voteOnAIInsightUtility(uint256 _insightId, bool _useful) external whenNotPaused {
        AIInsight storage insight = aiInsights[_insightId];
        require(insight.oracle != address(0), "AI Insight does not exist");
        require(!insight.isValidated, "AI Insight already validated, cannot vote");
        require(!aiInsightVotes[_insightId][msg.sender], "Already voted on this AI insight");

        uint256 effectiveRep = getEffectiveReputation(msg.sender);
        require(effectiveRep > 0, "Voter must have effective reputation to vote");

        aiInsightVotes[_insightId][msg.sender] = true;

        if (_useful) {
            insight.totalUtilityVotesReputation += effectiveRep;
            _updateReputationScore(msg.sender, int256(MAX_REPUTATION_BOOST_PER_ACTION / 10), "AI insight useful vote cast");
        } else {
            insight.totalDisutilityVotesReputation += effectiveRep;
            _updateReputationScore(msg.sender, -int256(MAX_REPUTATION_PENALTY_PER_ACTION / 10), "AI insight disutility vote cast");
        }

        uint256 totalVotesRep = insight.totalUtilityVotesReputation + insight.totalDisutilityVotesReputation;

        // Check for validation threshold and update status
        if (totalVotesRep >= aiInsightVoteThresholdReputation) {
            uint256 utilityRatio = (insight.totalUtilityVotesReputation * 10000) / totalVotesRep;
            if (utilityRatio >= aiInsightValidationRatio) {
                insight.isValidated = true;
                _updateReputationScore(insight.oracle, int256(MAX_REPUTATION_BOOST_PER_ACTION / 2), "AI Insight validated by community");
            } else {
                // Optionally penalize oracle for low utility insights, or mark as invalid.
                // For simplicity, we just won't mark as validated.
            }
        }
        emit AIInsightUtilityVoted(_insightId, msg.sender, _useful);
    }

    /**
     * @notice Allows a high-reputation user to curate a new, immutable Knowledge Fragment.
     * @dev Can be based on a validated AI insight or a successfully completed project.
     *      Requires the curator to have a minimum reputation score.
     * @param _contentHash The immutable content hash (e.g., IPFS CID) of the knowledge fragment itself.
     * @param _sourceAIInsightId The ID of the validated AI insight this fragment is based on (0 if none).
     * @param _sourceProjectId The ID of the completed project this fragment is based on (0 if none).
     */
    function curateKnowledgeFragment(
        string memory _contentHash,
        uint256 _sourceAIInsightId,
        uint256 _sourceProjectId
    ) external whenNotPaused {
        require(reputationScores[msg.sender] >= INITIAL_REPUTATION_CLAIM * 5, "Curator must have sufficient reputation to mint fragments"); // Example: need at least 50 reputation

        require(bytes(_contentHash).length > 0, "Content hash cannot be empty");
        require(_sourceAIInsightId > 0 || _sourceProjectId > 0, "Must specify a source AI Insight or a Project");

        if (_sourceAIInsightId > 0) {
            AIInsight storage insight = aiInsights[_sourceAIInsightId];
            require(insight.oracle != address(0), "Source AI Insight does not exist");
            require(insight.isValidated, "Source AI Insight must be validated by the community");
        }
        if (_sourceProjectId > 0) {
            Project storage project = projects[_sourceProjectId];
            require(project.proposer != address(0), "Source Project does not exist");
            require(project.status == ProjectStatus.Completed, "Source Project must be completed successfully");
        }

        uint256 fragmentId = nextKnowledgeFragmentId++;
        knowledgeFragments[fragmentId] = KnowledgeFragment({
            curator: msg.sender,
            contentHash: _contentHash,
            creationTimestamp: block.timestamp,
            sourceAIInsightId: _sourceAIInsightId,
            sourceProjectId: _sourceProjectId
        });

        _updateReputationScore(msg.sender, int256(MAX_REPUTATION_BOOST_PER_ACTION * 1.5), "Knowledge fragment curated");
        emit KnowledgeFragmentCurated(fragmentId, msg.sender, _sourceAIInsightId, _sourceProjectId, _contentHash);
    }

    /**
     * @notice Retrieves the content hash of a specific Knowledge Fragment.
     * @param _fragmentId The ID of the knowledge fragment.
     * @return The content hash of the fragment.
     */
    function getKnowledgeFragmentContent(uint256 _fragmentId) public view returns (string memory) {
        require(knowledgeFragments[_fragmentId].curator != address(0), "Knowledge Fragment does not exist");
        return knowledgeFragments[_fragmentId].contentHash;
    }

    // --- V. Governance & Parameter Updates (Simple for now, could be DAO) ---

    /**
     * @notice Updates the minimum total reputation required for a project to be approved for incubation.
     * @dev Only the contract owner can call this.
     * @param _newThreshold The new reputation threshold.
     */
    function updateProjectApprovalThreshold(uint256 _newThreshold) external onlyOwner {
        projectApprovalThresholdReputation = _newThreshold;
    }

    /**
     * @notice Updates the minimum total reputation required for an AI insight to be considered for validation.
     * @dev Only the contract owner can call this.
     * @param _newThreshold The new reputation threshold.
     */
    function updateAIInsightVoteThreshold(uint256 _newThreshold) external onlyOwner {
        aiInsightVoteThresholdReputation = _newThreshold;
    }

    /**
     * @notice Updates the required ratio of success votes for project deliverables.
     * @dev Only the contract owner can call this. Value is scaled by 10000 (e.g., 7000 for 70%).
     * @param _newRatio The new ratio for deliverable success votes. Must be between 0 and 10000.
     */
    function updateDeliverableSuccessVoteRatio(uint256 _newRatio) external onlyOwner {
        require(_newRatio <= 10000, "Ratio cannot exceed 100% (10000)");
        deliverableSuccessVoteThresholdRatio = _newRatio;
    }

    /**
     * @notice Updates the required ratio of useful votes for AI insight validation.
     * @dev Only the contract owner can call this. Value is scaled by 10000 (e.g., 7500 for 75%).
     * @param _newRatio The new ratio for AI insight validation. Must be between 0 and 10000.
     */
    function updateAIInsightValidationRatio(uint256 _newRatio) external onlyOwner {
        require(_newRatio <= 10000, "Ratio cannot exceed 100% (10000)");
        aiInsightValidationRatio = _newRatio;
    }
}
```