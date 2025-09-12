The contract "AuraNexus" is a sophisticated, AI-enhanced, and reputation-driven platform for funding and managing creative projects on the blockchain. It combines several advanced concepts to create a unique ecosystem for decentralized collaboration and innovation.

---

## AuraNexus Smart Contract: Outline and Function Summary

**Contract:** `AuraNexus`
**Description:** A decentralized platform for funding and managing creative projects. It integrates AI-driven insights, a dynamic reputation system ("Aura Score"), and evolving, non-transferable NFTs ("Synergy Orbs") that reflect contribution and project success. Governed by a DAO, it aims to foster quality and accountability in creative endeavors.

---

### **I. Core Protocol & Access Control**

1.  **`constructor(string name_, string symbol_, string synergyOrbBaseURI_)`**:
    *   Initializes the `ERC721` token (Synergy Orb), sets up initial administrative roles (`DEFAULT_ADMIN_ROLE`, `ADMIN_ROLE`, `PROJECT_MANAGER_ROLE`, `AI_ORACLE_MANAGER_ROLE`), and defines the base URI for dynamic Synergy Orb metadata. Grants the deployer an `INITIAL_AURA_SCORE`.
2.  **`pauseContract()`**:
    *   Allows authorized `ADMIN_ROLE` members to pause critical contract functions (e.g., in emergencies or during upgrades).
3.  **`unpauseContract()`**:
    *   Allows authorized `ADMIN_ROLE` members to unpause the contract's operations.
4.  **`updateAIOracleAddress(address _aiOracleAddress)`**:
    *   Sets or updates the address of the external `IAIOracle` contract, which is responsible for off-chain AI assessments. Requires `ADMIN_ROLE`.
5.  **`setProjectApprovalMinAura(uint256 _minAura)`**:
    *   Sets the minimum Aura Score required for a `PROJECT_MANAGER_ROLE` to approve a project proposal. Requires `ADMIN_ROLE`.
6.  **`setMilestoneReviewMinAura(uint256 _minAura)`**:
    *   Sets the minimum Aura Score required for a user to participate in milestone reviews. Requires `ADMIN_ROLE`.
7.  **`setProposalVotingPeriod(uint256 _newVotingPeriod)`**:
    *   Sets the duration for DAO proposal voting periods. Requires `ADMIN_ROLE`.

### **II. AI-Enhanced Project Evaluation**

8.  **`requestProjectAIAssessment(uint256 _projectId, string memory _detailsHash, uint256 _assessmentType)`**:
    *   *Internal function.* Triggers a call to the external AI oracle contract to evaluate a project proposal (`_assessmentType` 0) or a milestone completion (`_assessmentType` 1). The `_detailsHash` typically points to off-chain data (e.g., IPFS) for AI analysis.
9.  **`fulfillProjectAIAssessment(uint256 _projectId, uint256 _assessmentType, int256 _score, string memory _feedbackHash)`**:
    *   Callback function. Only callable by the `AI_ORACLE_MANAGER_ROLE`. Receives the AI's assessment (`_score` and `_feedbackHash`) and integrates it into the project's or milestone's data, updating its status accordingly.

### **III. Dynamic Reputation System (Aura Score)**

10. **`getAuraScore(address _user)`**:
    *   Returns the current reputation ("Aura Score") for a specific user. Users with no recorded score default to `INITIAL_AURA_SCORE`.
11. **`_updateAuraScore(address _user, int256 _amount, string memory _reason)`**:
    *   *Internal function.* Adjusts a user's Aura Score based on various on-chain actions (e.g., successful project completion, quality reviews, voting). Ensures scores do not drop below zero. Emits an `AuraScoreUpdated` event.
12. **`getAuraInfluenceMultiplier(address _user)`**:
    *   Calculates a weighted multiplier based on a user's Aura Score. This multiplier is used to scale voting power in the DAO and potentially other forms of influence within the platform.

### **IV. Project Lifecycle Management**

13. **`proposeProject(string memory _name, string memory _descriptionHash, uint256 _fundingGoal, string[] memory _milestoneDescriptionHashes, uint256[] memory _milestoneFundingAllocations)`**:
    *   Allows users to submit a new creative project proposal, including a name, detailed description (via hash), funding goal, and a breakdown of milestones with their respective funding allocations. Initiates an AI assessment request.
14. **`approveProjectProposal(uint256 _projectId)`**:
    *   Allows `PROJECT_MANAGER_ROLE` members (or a DAO vote) to approve a project proposal after its AI assessment and initial review. Requires the approver to have a minimum Aura Score. Moves the project to the `Funding` stage.
15. **`fundProject(uint256 _projectId)`**:
    *   Enables users to contribute Ether to an approved project's funding goal. Funds are held in the contract. If a significant contribution is made, a `SynergyOrb` NFT is minted to the funder.
16. **`submitMilestoneCompletion(uint256 _projectId, uint256 _milestoneId, string memory _proofHash)`**:
    *   Allows the project creator to submit proof (via hash) of a completed milestone. This moves the milestone into a review phase and triggers an AI assessment request for the milestone.
17. **`reviewMilestoneCompletion(uint256 _projectId, uint256 _milestoneId, bool _approved)`**:
    *   Allows community members (with sufficient Aura) to review a submitted milestone. Reviewers vote "for" or "against" completion, with their vote weight adjusted by their Aura Score. The collective decision (considering AI assessment) determines if the milestone is approved or rejected, impacting the creator's Aura and subsequent fund release.
18. **`_releaseMilestoneFunds(uint256 _projectId, uint256 _milestoneId)`**:
    *   *Internal function.* Called automatically upon successful milestone approval. Releases the allocated funds for that milestone to the project creator's `withdrawableBalances`. If it's the final milestone, the project status becomes `Completed`. Also triggers evolution for associated `SynergyOrb` NFTs.
19. **`withdrawProjectFunds(uint256 _projectId, uint256 _amount)`**:
    *   Allows the project creator to withdraw available funds from their `withdrawableBalances` (populated by approved milestones).
20. **`getProjectDetails(uint256 _projectId)`**:
    *   Retrieves all structured information about a specific project, including its ID, creator, status, funding, and AI assessment scores.
21. **`getProjectStatus(uint256 _projectId)`**:
    *   Returns the current `ProjectStatus` (e.g., `Proposed`, `Funding`, `Active`, `Completed`, `Failed`) of a specific project.

### **V. Dynamic NFT (Synergy Orb) Ecosystem**

22. **`mintSynergyOrb(address _to, uint256 _projectId, string memory _contributionType)`**:
    *   Mints a non-transferable (`Soulbound`) `SynergyOrb` NFT to a user for significant contributions (e.g., funding, project creation). Each Orb is linked to a specific project. This function is primarily called internally by other contract logic.
23. **`evolveSynergyOrb(uint256 _orbId, string memory _reason)`**:
    *   Updates the dynamic metadata/traits of a `SynergyOrb` NFT. This function is called internally when a project progresses (e.g., milestone completion) or a holder's Aura Score changes. The off-chain `tokenURI` API would then reflect these changes.
24. **`tokenURI(uint256 tokenId)`**:
    *   *Overrides `ERC721`.* Returns the dynamic metadata URI for a given `SynergyOrb`. The URI points to an off-chain service that generates JSON metadata reflecting the Orb's current state, its associated project's progress, and the holder's Aura.

### **VI. Decentralized Autonomous Organization (DAO) Governance**

25. **`createGovernanceProposal(string memory _descriptionHash, address _targetContract, bytes memory _callData)`**:
    *   Allows users with sufficient Aura to propose changes to the protocol (e.g., updating parameters, adding new features). Proposals include `callData` for direct execution if passed.
26. **`voteOnProposal(uint256 _proposalId, bool _support)`**:
    *   Enables eligible users to cast their vote (`_support` true for 'for', false for 'against') on an active DAO proposal. Their vote weight is scaled by their Aura Influence Multiplier.
27. **`executeProposal(uint256 _proposalId)`**:
    *   Can be called by anyone after a proposal's voting period ends. If the proposal has met the passing criteria (e.g., majority Aura-weighted votes 'for'), its `callData` is executed on the `targetContract`.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol"; // For explicit uint256 operations

/**
 * @title IAIOracle
 * @dev Interface for an external AI Oracle service.
 * This contract does not implement the oracle itself but interacts with one.
 * The `requestAIAssessment` would typically be called by AuraNexus,
 * and `sendAssessment` would be called by the trusted AI Oracle Manager.
 */
interface IAIOracle {
    /**
     * @dev Requests an AI assessment for a specific project or milestone.
     * The oracle service would then process this off-chain and use `sendAssessment`
     * to report back the results.
     * @param projectId The ID of the project to assess.
     * @param projectDetailsHash A hash (e.g., IPFS) pointing to detailed project information.
     * @param callbackContract The address of the contract that should receive the assessment.
     * @param callbackFunctionSelector The function selector of the callback function.
     * @param assessmentType 0 for proposal, 1 for milestone.
     */
    function requestAIAssessment(
        uint256 projectId,
        string memory projectDetailsHash,
        address callbackContract,
        bytes4 callbackFunctionSelector,
        uint256 assessmentType
    ) external;

    /**
     * @dev A function placeholder (could be part of a real Chainlink adapter contract)
     * for the AI manager to send an assessment back to the requesting contract.
     * This function is expected to be called by the `AI_ORACLE_MANAGER_ROLE` in AuraNexus.
     * @param projectId The ID of the project assessed.
     * @param assessmentType 0 for proposal, 1 for milestone.
     * @param score The AI's assessment score (e.g., -100 to 100).
     * @param feedbackHash IPFS hash of detailed feedback or reasoning.
     */
    function sendAssessment(
        uint256 projectId,
        uint256 assessmentType,
        int256 score,
        string memory feedbackHash
    ) external;
}

/**
 * @title AuraNexus - AI-Enhanced, Reputation-Driven, Dynamic NFT Ecosystem for Decentralized Creative Projects
 * @author ChatGPT
 * @dev This contract implements a novel platform for funding and managing creative projects.
 *      It integrates several advanced, creative, and trendy concepts:
 *      - **AI-Driven Curation:** External AI oracles assist in project proposal and milestone evaluation.
 *        The contract requests assessments and reacts to the AI's feedback, but human oversight remains.
 *      - **Dynamic Reputation (Aura Score):** Users earn a non-transferable "Aura Score" based on their contributions,
 *        project successes, quality of reviews, and governance participation. This score influences
 *        voting power, project approval thresholds, and access to exclusive features.
 *      - **Dynamic NFTs (Synergy Orbs):** Non-transferable ERC721 tokens (Soulbound Tokens) that evolve
 *        in appearance and metadata. They are minted for significant contributions and their traits
 *        update based on project progress, AI assessments, and the holder's Aura Score, representing
 *        a living record of contribution and achievement.
 *      - **DAO Governance:** The platform's parameters and critical project decisions are governed by a DAO
 *        where voting power is weighted by the participant's Aura Score.
 *      - **Milestone-Based Funding:** Project funds are released conditionally upon verified milestone
 *        completion, with verification aided by community review and AI insights.
 *
 *      The contract aims to create a self-sustaining ecosystem for decentralized creative endeavors,
 *      promoting quality and accountability through integrated reputation and AI-assisted processes.
 */
contract AuraNexus is ERC721, AccessControl, Pausable {
    using Counters for Counters.Counter;
    using Strings for uint256;
    using SafeMath for uint256;

    // --- State Variables & Constants ---

    // Roles for AccessControl
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant PROJECT_MANAGER_ROLE = keccak256("PROJECT_MANAGER_ROLE"); // Can approve projects, manage disputes
    bytes32 public constant AI_ORACLE_MANAGER_ROLE = keccak256("AI_ORACLE_MANAGER_ROLE"); // Address that can trigger/receive AI oracle calls.

    // Project Statuses
    enum ProjectStatus {
        Proposed,              // Initial submission by creator
        AwaitingAIAssessment,  // Sent to AI for initial proposal review
        AwaitingApproval,      // AI assessed, waiting for manager/DAO approval
        Funding,               // Approved, open for community funding
        Active,                // Funding goal met, project is ongoing
        MilestoneReview,       // Creator submitted milestone, awaiting community/AI review
        Completed,             // All milestones completed successfully
        Failed,                // Project failed to meet goals or deadlines
        Cancelled              // Project cancelled by managers/DAO
    }

    // Milestone Statuses
    enum MilestoneStatus {
        Pending,              // Not yet submitted by creator
        SubmittedForReview,   // Submitted, awaiting community/AI review
        Approved,             // Reviewed and deemed successful
        Rejected              // Reviewed and deemed unsuccessful
    }

    // Struct for Project
    struct Project {
        uint256 id;
        address creator;
        string name;
        string descriptionHash;         // IPFS hash or similar for detailed description
        uint256 fundingGoal;            // Total ETH required
        uint256 fundsRaised;            // Total ETH contributed by funders
        uint256 fundsWithdrawn;         // Total ETH withdrawn by creator (from released milestones)
        uint256 currentMilestoneIndex;  // Which milestone is currently active/being worked on
        ProjectStatus status;
        uint256 creationTimestamp;
        uint256 lastUpdateTimestamp;
        mapping(uint256 => Milestone) milestones; // Milestones by index
        uint256 numMilestones;
        int256 aiProposalAssessmentScore; // AI's initial score for the proposal (e.g., -100 to 100)
        uint256 totalSynergyOrbsMinted; // Count of Orbs for this project
    }

    // Struct for Milestone
    struct Milestone {
        uint256 id;
        string descriptionHash;      // IPFS hash for milestone details/requirements, then proof of completion
        uint256 fundingAllocation;   // Percentage (e.g., 2500 for 25%) of total funding for this milestone
        MilestoneStatus status;
        int256 aiAssessmentScore;    // AI's score for this specific milestone completion (e.g., -100 to 100)
        uint256 submissionTimestamp;
        uint256 approvalTimestamp;
        uint256 reviewVotesFor;      // Count of Aura-weighted votes for approval
        uint256 reviewVotesAgainst;  // Count of Aura-weighted votes against approval
        mapping(address => bool) hasReviewed; // To prevent double voting on milestones by a single address
    }

    // Struct for DAO Proposal
    struct DAOProposal {
        uint256 id;
        address proposer;
        string descriptionHash; // IPFS hash for proposal details
        bytes callData;         // Data to execute if proposal passes (e.g., set new fee, update role)
        address targetContract; // Contract to call
        uint256 voteStartTime;
        uint256 voteEndTime;
        uint256 votesFor;       // Total Aura-weighted votes for
        uint256 votesAgainst;   // Total Aura-weighted votes against
        bool executed;
        bool passed;
        mapping(address => bool) hasVoted; // Prevents double voting
    }

    Counters.Counter private _projectIdCounter;
    Counters.Counter private _daoProposalIdCounter;
    Counters.Counter private _synergyOrbIdCounter; // For unique Synergy Orb IDs

    mapping(uint256 => Project) public projects;
    mapping(uint256 => DAOProposal) public daoProposals;

    // Aura Score System
    mapping(address => uint256) private _auraScores; // User address => Aura Score
    uint256 public constant INITIAL_AURA_SCORE = 100;
    uint256 public constant MIN_AURA_FOR_PROPOSAL = 500; // Minimum Aura to create a DAO proposal
    mapping(address => uint256) public withdrawableBalances; // Creator's balance available for withdrawal

    // AI Oracle Integration
    IAIOracle public aiOracle;

    // Synergy Orb (Dynamic NFT) Configuration
    string private _synergyOrbBaseURI; // Base URI for dynamic metadata
    mapping(uint256 => uint256) public synergyOrbProjectMapping; // Orb ID -> Project ID

    // Governance Parameters
    uint256 public proposalVotingPeriod = 7 days; // Default voting period for DAO proposals
    uint256 public projectApprovalMinAura = 200; // Minimum Aura score for a manager to approve a project
    uint256 public milestoneReviewMinAura = 150; // Minimum Aura score to review a milestone
    uint256 public constant MILESTONE_REVIEW_QUORUM = 3; // Minimum number of Aura-weighted reviews (e.g., 3000 for 3 reviews if 1000 base) for a milestone decision
    int256 public constant AI_MILESTONE_PASS_THRESHOLD = 0; // AI score >= this to be considered positive

    // Events
    event ProjectProposed(uint256 indexed projectId, address indexed creator, string name);
    event ProjectAIRequested(uint256 indexed projectId, uint256 assessmentType);
    event ProjectAIFulfilled(uint256 indexed projectId, uint256 assessmentType, int256 score, string feedbackHash);
    event ProjectApproved(uint256 indexed projectId, address indexed approver);
    event ProjectFunded(uint256 indexed projectId, address indexed funder, uint256 amount);
    event ProjectStatusUpdated(uint256 indexed projectId, ProjectStatus newStatus);
    event MilestoneSubmitted(uint256 indexed projectId, uint256 indexed milestoneId, string proofHash);
    event MilestoneReviewed(uint256 indexed projectId, uint256 indexed milestoneId, address indexed reviewer, bool approved, uint256 auraWeight);
    event MilestoneFundsReleased(uint256 indexed projectId, uint256 indexed milestoneId, uint256 amount);
    event ProjectFundsWithdrawn(uint256 indexed projectId, address indexed receiver, uint256 amount);
    event AuraScoreUpdated(address indexed user, uint256 oldScore, uint256 newScore, string reason);
    event SynergyOrbMinted(uint256 indexed orbId, address indexed owner, uint256 indexed projectId, string contributionType);
    event SynergyOrbEvolved(uint256 indexed orbId, string reason);
    event DAOProposalCreated(uint256 indexed proposalId, address indexed proposer, string descriptionHash);
    event DAOProposalVoted(uint256 indexed proposalId, address indexed voter, bool support, uint256 voteWeight);
    event DAOProposalExecuted(uint256 indexed proposalId);

    // --- Constructor ---
    /**
     * @dev Initializes the AuraNexus contract, setting up initial roles and the NFT's base URI.
     * @param name_ The name of the NFT collection (e.g., "Synergy Orb").
     * @param symbol_ The symbol of the NFT collection (e.g., "SORB").
     * @param synergyOrbBaseURI_ The base URI for the dynamic Synergy Orb metadata (e.g., "https://api.auranexus.xyz/orb/").
     */
    constructor(string memory name_, string memory symbol_, string memory synergyOrbBaseURI_) ERC721(name_, symbol_) {
        // Grant deployer initial administrative roles
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(ADMIN_ROLE, msg.sender);
        _grantRole(PROJECT_MANAGER_ROLE, msg.sender);
        _grantRole(AI_ORACLE_MANAGER_ROLE, msg.sender);

        _synergyOrbBaseURI = synergyOrbBaseURI_;
        _auraScores[msg.sender] = INITIAL_AURA_SCORE; // Initial Aura for the deployer
        emit AuraScoreUpdated(address(0), 0, INITIAL_AURA_SCORE, "Initial deployer Aura");
    }

    // Required by OpenZeppelin's Ownable for upgradability, but not directly used here.
    function _authorizeUpgrade(address newImplementation) internal override {}

    // --- Access Control & Pausability ---

    /**
     * @dev Pauses all critical contract operations.
     * Requires ADMIN_ROLE.
     */
    function pauseContract() public onlyRole(ADMIN_ROLE) whenNotPaused {
        _pause();
    }

    /**
     * @dev Unpauses all critical contract operations.
     * Requires ADMIN_ROLE.
     */
    function unpauseContract() public onlyRole(ADMIN_ROLE) whenPaused {
        _unpause();
    }

    /**
     * @dev Sets or updates the address of the external AI Oracle contract.
     * Requires ADMIN_ROLE. This oracle contract will be used for requesting assessments.
     * @param _aiOracleAddress The new address of the AI Oracle contract.
     */
    function updateAIOracleAddress(address _aiOracleAddress) public onlyRole(ADMIN_ROLE) {
        require(_aiOracleAddress != address(0), "AIOracle address cannot be zero");
        aiOracle = IAIOracle(_aiOracleAddress);
        _updateAuraScore(msg.sender, 5, "Updated AI Oracle Address"); // Small Aura boost for admin actions
    }

    /**
     * @dev Sets or updates the minimum Aura Score required for a PROJECT_MANAGER_ROLE to approve a project proposal.
     * Requires ADMIN_ROLE.
     * @param _minAura The new minimum Aura score.
     */
    function setProjectApprovalMinAura(uint256 _minAura) public onlyRole(ADMIN_ROLE) {
        projectApprovalMinAura = _minAura;
    }

    /**
     * @dev Sets or updates the minimum Aura Score required for a user to review a milestone.
     * Requires ADMIN_ROLE.
     * @param _minAura The new minimum Aura score.
     */
    function setMilestoneReviewMinAura(uint256 _minAura) public onlyRole(ADMIN_ROLE) {
        milestoneReviewMinAura = _minAura;
    }

    /**
     * @dev Sets or updates the voting period for DAO proposals.
     * Requires ADMIN_ROLE.
     * @param _newVotingPeriod The new duration in seconds.
     */
    function setProposalVotingPeriod(uint256 _newVotingPeriod) public onlyRole(ADMIN_ROLE) {
        require(_newVotingPeriod > 0, "Voting period must be positive");
        proposalVotingPeriod = _newVotingPeriod;
    }

    // --- AI-Enhanced Project Evaluation ---

    /**
     * @dev Requests an AI assessment for a project proposal or a milestone.
     * This function interacts with an external AI oracle.
     * @param _projectId The ID of the project to assess.
     * @param _detailsHash The IPFS hash of the project/milestone details for AI analysis.
     * @param _assessmentType 0 for proposal, 1 for milestone.
     */
    function requestProjectAIAssessment(
        uint256 _projectId,
        string memory _detailsHash,
        uint256 _assessmentType
    ) internal whenNotPaused {
        require(address(aiOracle) != address(0), "AI Oracle not set");
        aiOracle.requestAIAssessment(
            _projectId,
            _detailsHash,
            address(this),
            this.fulfillProjectAIAssessment.selector,
            _assessmentType
        );
        emit ProjectAIRequested(_projectId, _assessmentType);
    }

    /**
     * @dev Callback function to receive the AI's assessment for a project.
     * Only callable by the designated AI Oracle Manager role.
     * This function updates the project or milestone with the AI's score and feedback hash.
     * @param _projectId The ID of the project assessed.
     * @param _assessmentType 0 for proposal, 1 for milestone.
     * @param _score The AI's assessment score (e.g., -100 to 100).
     * @param _feedbackHash IPFS hash of detailed AI feedback.
     */
    function fulfillProjectAIAssessment(
        uint256 _projectId,
        uint256 _assessmentType,
        int256 _score,
        string memory _feedbackHash
    ) public onlyRole(AI_ORACLE_MANAGER_ROLE) {
        require(_projectId > 0 && _projectId <= _projectIdCounter.current(), "Invalid Project ID");
        Project storage project = projects[_projectId];

        if (_assessmentType == 0) { // Proposal Assessment
            require(project.status == ProjectStatus.AwaitingAIAssessment, "Project not awaiting proposal AI assessment");
            project.aiProposalAssessmentScore = _score;
            project.status = ProjectStatus.AwaitingApproval;
            emit ProjectStatusUpdated(_projectId, ProjectStatus.AwaitingApproval);
        } else if (_assessmentType == 1) { // Milestone Assessment
            uint256 currentMilestoneId = project.currentMilestoneIndex;
            Milestone storage milestone = project.milestones[currentMilestoneId];
            require(milestone.status == MilestoneStatus.SubmittedForReview, "Milestone not submitted for review or awaiting AI assessment");
            milestone.aiAssessmentScore = _score;
            // AI assessment doesn't directly approve, it informs community review.
        } else {
            revert("Invalid assessment type");
        }
        project.lastUpdateTimestamp = block.timestamp;
        emit ProjectAIFulfilled(_projectId, _assessmentType, _score, _feedbackHash);
    }

    // --- Dynamic Reputation System (Aura Score) ---

    /**
     * @dev Returns the current reputation score for a specific user.
     * If a user has no recorded score, they start with INITIAL_AURA_SCORE.
     * @param _user The address of the user.
     * @return The Aura Score of the user.
     */
    function getAuraScore(address _user) public view returns (uint256) {
        return _auraScores[_user] > 0 ? _auraScores[_user] : INITIAL_AURA_SCORE;
    }

    /**
     * @dev Internal function to adjust a user's Aura Score based on various on-chain actions.
     * This function is called by other contract functions, not directly by users.
     * Ensures Aura Score does not drop below 0.
     * @param _user The address of the user whose Aura Score is being updated.
     * @param _amount The signed amount to add or subtract from the Aura Score.
     * @param _reason A string describing the reason for the update.
     */
    function _updateAuraScore(address _user, int256 _amount, string memory _reason) internal {
        uint256 oldScore = getAuraScore(_user);
        uint256 newScore;

        if (_amount > 0) {
            newScore = oldScore.add(uint256(_amount));
        } else {
            // Safe subtraction, ensures score doesn't go negative
            newScore = oldScore > uint256(-_amount) ? oldScore.sub(uint256(-_amount)) : 0;
        }

        _auraScores[_user] = newScore;
        emit AuraScoreUpdated(_user, oldScore, newScore, _reason);
    }

    /**
     * @dev Calculates an influence multiplier based on Aura Score, used for weighted voting or funding limits.
     * Example: Every 100 Aura points adds 0.1x multiplier, starting at 1.0x (1000 base units) for 0 Aura.
     * @param _user The address of the user.
     * @return A multiplier (scaled by 1000) for influence. E.g., 1000 for 1.0x, 1100 for 1.1x.
     */
    function getAuraInfluenceMultiplier(address _user) public view returns (uint256) {
        uint256 score = getAuraScore(_user);
        return 1000 + (score / 100) * 100; // Returns 1000, 1100, 1200...
    }


    // --- Project Lifecycle Management ---

    /**
     * @dev Allows users to submit a new creative project proposal.
     * Includes project details, funding goal, and defined milestones with funding allocations.
     * @param _name The name of the project.
     * @param _descriptionHash IPFS hash for detailed project description.
     * @param _fundingGoal The total amount of funding required for the project (in Wei).
     * @param _milestoneDescriptionHashes Array of IPFS hashes for each milestone's details.
     * @param _milestoneFundingAllocations Array of funding percentages (e.g., 2500 for 25%) for each milestone.
     */
    function proposeProject(
        string memory _name,
        string memory _descriptionHash,
        uint256 _fundingGoal,
        string[] memory _milestoneDescriptionHashes,
        uint256[] memory _milestoneFundingAllocations
    ) public whenNotPaused returns (uint256) {
        require(bytes(_name).length > 0, "Project name cannot be empty");
        require(_fundingGoal > 0, "Funding goal must be greater than zero");
        require(_milestoneDescriptionHashes.length == _milestoneFundingAllocations.length, "Milestone arrays mismatch");
        require(_milestoneDescriptionHashes.length > 0, "Project must have at least one milestone");

        uint256 totalAllocation;
        for (uint256 i = 0; i < _milestoneFundingAllocations.length; i++) {
            require(_milestoneFundingAllocations[i] > 0, "Milestone allocation must be positive");
            totalAllocation = totalAllocation.add(_milestoneFundingAllocations[i]);
        }
        require(totalAllocation == 10000, "Total milestone allocations must sum to 100%"); // 10000 for 100%

        _projectIdCounter.increment();
        uint256 newProjectId = _projectIdCounter.current();

        Project storage newProject = projects[newProjectId];
        newProject.id = newProjectId;
        newProject.creator = msg.sender;
        newProject.name = _name;
        newProject.descriptionHash = _descriptionHash;
        newProject.fundingGoal = _fundingGoal;
        newProject.status = ProjectStatus.AwaitingAIAssessment;
        newProject.creationTimestamp = block.timestamp;
        newProject.lastUpdateTimestamp = block.timestamp;
        newProject.numMilestones = _milestoneDescriptionHashes.length;

        for (uint256 i = 0; i < _milestoneDescriptionHashes.length; i++) {
            newProject.milestones[i].id = i;
            newProject.milestones[i].descriptionHash = _milestoneDescriptionHashes[i];
            newProject.milestones[i].fundingAllocation = _milestoneFundingAllocations[i];
            newProject.milestones[i].status = MilestoneStatus.Pending;
        }

        requestProjectAIAssessment(newProjectId, _descriptionHash, 0); // 0 for proposal assessment

        _updateAuraScore(msg.sender, 10, "Proposed a new project"); // Minor Aura boost for proposing
        emit ProjectProposed(newProjectId, msg.sender, _name);
        return newProjectId;
    }

    /**
     * @dev Allows project managers or DAO to approve a project proposal after AI assessment and initial review.
     * Moves the project to the 'Funding' stage.
     * @param _projectId The ID of the project to approve.
     */
    function approveProjectProposal(uint256 _projectId) public onlyRole(PROJECT_MANAGER_ROLE) whenNotPaused {
        require(_projectId > 0 && _projectId <= _projectIdCounter.current(), "Invalid Project ID");
        Project storage project = projects[_projectId];
        require(project.status == ProjectStatus.AwaitingApproval, "Project not in 'Awaiting Approval' status");
        require(getAuraScore(msg.sender) >= projectApprovalMinAura, "Insufficient Aura to approve project");
        
        project.status = ProjectStatus.Funding;
        project.lastUpdateTimestamp = block.timestamp;
        _updateAuraScore(msg.sender, 20, "Approved a project proposal");
        emit ProjectApproved(_projectId, msg.sender);
        emit ProjectStatusUpdated(_projectId, ProjectStatus.Funding);
    }

    /**
     * @dev Allows users to contribute funds to an approved project.
     * Funds are held in the contract until milestones are approved and released.
     * Mint a Synergy Orb for significant funders.
     * @param _projectId The ID of the project to fund.
     */
    function fundProject(uint256 _projectId) public payable whenNotPaused {
        require(_projectId > 0 && _projectId <= _projectIdCounter.current(), "Invalid Project ID");
        Project storage project = projects[_projectId];
        require(project.status == ProjectStatus.Funding || project.status == ProjectStatus.Active, "Project not open for funding");
        require(msg.value > 0, "Contribution must be greater than zero");
        require(project.fundsRaised.add(msg.value) <= project.fundingGoal, "Contribution exceeds funding goal");

        project.fundsRaised = project.fundsRaised.add(msg.value);
        project.lastUpdateTimestamp = block.timestamp;

        if (project.fundsRaised == project.fundingGoal) {
            project.status = ProjectStatus.Active;
            project.currentMilestoneIndex = 0; // Set up the first milestone to be active
            _updateAuraScore(project.creator, 50, "Project fully funded"); // Creator gets Aura boost
            emit ProjectStatusUpdated(_projectId, ProjectStatus.Active);
        }

        // Mint a Synergy Orb for significant contributors (e.g., > 1% of funding goal)
        if (msg.value >= project.fundingGoal.div(100)) { // Example threshold for Orb minting
            mintSynergyOrb(msg.sender, _projectId, "Funder");
        }
        _updateAuraScore(msg.sender, 5, "Funded a project");
        emit ProjectFunded(_projectId, msg.sender, msg.value);
    }

    /**
     * @dev Project creator submits proof of milestone completion.
     * This moves the milestone into a review phase by community and AI.
     * @param _projectId The ID of the project.
     * @param _milestoneId The ID of the milestone being submitted.
     * @param _proofHash IPFS hash or URL to the proof of completion.
     */
    function submitMilestoneCompletion(
        uint256 _projectId,
        uint256 _milestoneId,
        string memory _proofHash
    ) public whenNotPaused {
        require(_projectId > 0 && _projectId <= _projectIdCounter.current(), "Invalid Project ID");
        Project storage project = projects[_projectId];
        require(project.creator == msg.sender, "Only project creator can submit milestones");
        require(project.status == ProjectStatus.Active, "Project not in active status");
        require(_milestoneId == project.currentMilestoneIndex, "Only current milestone can be submitted");
        require(_milestoneId < project.numMilestones, "Milestone ID out of bounds");

        Milestone storage milestone = project.milestones[_milestoneId];
        require(milestone.status == MilestoneStatus.Pending, "Milestone not in Pending status");

        milestone.status = MilestoneStatus.SubmittedForReview;
        milestone.submissionTimestamp = block.timestamp;
        milestone.descriptionHash = _proofHash; // Update descriptionHash to point to proof

        project.status = ProjectStatus.MilestoneReview;
        project.lastUpdateTimestamp = block.timestamp;

        requestProjectAIAssessment(_projectId, _proofHash, 1); // 1 for milestone assessment

        _updateAuraScore(msg.sender, 10, "Submitted milestone for review");
        emit MilestoneSubmitted(_projectId, _milestoneId, _proofHash);
        emit ProjectStatusUpdated(_projectId, ProjectStatus.MilestoneReview);
    }

    /**
     * @dev Community members or designated reviewers assess a milestone submission.
     * Their Aura score influences the weight of their review.
     * This function's logic determines if a milestone is approved or rejected based on collective review and AI score.
     * @param _projectId The ID of the project.
     * @param _milestoneId The ID of the milestone being reviewed.
     * @param _approved True if the reviewer approves the milestone, false otherwise.
     */
    function reviewMilestoneCompletion(
        uint256 _projectId,
        uint256 _milestoneId,
        bool _approved
    ) public whenNotPaused {
        require(_projectId > 0 && _projectId <= _projectIdCounter.current(), "Invalid Project ID");
        Project storage project = projects[_projectId];
        require(project.status == ProjectStatus.MilestoneReview, "Project not in milestone review status");
        require(_milestoneId == project.currentMilestoneIndex, "Only current milestone can be reviewed");
        require(_milestoneId < project.numMilestones, "Milestone ID out of bounds");

        Milestone storage milestone = project.milestones[_milestoneId];
        require(milestone.status == MilestoneStatus.SubmittedForReview, "Milestone not submitted for review");
        require(getAuraScore(msg.sender) >= milestoneReviewMinAura, "Insufficient Aura to review milestone");
        require(!milestone.hasReviewed[msg.sender], "You have already reviewed this milestone");
        require(msg.sender != project.creator, "Project creator cannot review their own milestone");

        uint256 reviewerAuraWeight = getAuraInfluenceMultiplier(msg.sender);
        milestone.hasReviewed[msg.sender] = true;

        if (_approved) {
            milestone.reviewVotesFor = milestone.reviewVotesFor.add(reviewerAuraWeight);
            _updateAuraScore(msg.sender, 3, "Approved milestone review");
        } else {
            milestone.reviewVotesAgainst = milestone.reviewVotesAgainst.add(reviewerAuraWeight);
            _updateAuraScore(msg.sender, -2, "Rejected milestone review"); // Small Aura penalty for potential bad review
        }
        emit MilestoneReviewed(_projectId, _milestoneId, msg.sender, _approved, reviewerAuraWeight);

        // Decision logic: A simple quorum and majority vote with AI score consideration
        uint256 totalAuraWeightedVotes = milestone.reviewVotesFor.add(milestone.reviewVotesAgainst);
        if (totalAuraWeightedVotes >= MILESTONE_REVIEW_QUORUM * 1000) { // Example: Quorum based on Aura weight
            if (milestone.reviewVotesFor > milestone.reviewVotesAgainst && milestone.aiAssessmentScore >= AI_MILESTONE_PASS_THRESHOLD) {
                // Milestone Approved
                milestone.status = MilestoneStatus.Approved;
                milestone.approvalTimestamp = block.timestamp;
                _updateAuraScore(project.creator, 25, "Milestone approved by community/AI");
                _releaseMilestoneFunds(_projectId, _milestoneId); // Release funds internally
            } else {
                // Milestone Rejected (even if slight majority, negative AI or strong rejection leads to failure)
                milestone.status = MilestoneStatus.Rejected;
                _updateAuraScore(project.creator, -20, "Milestone rejected by community/AI");
                project.status = ProjectStatus.Failed; // For simplicity, project fails if a milestone is rejected
                emit ProjectStatusUpdated(_projectId, ProjectStatus.Failed);
            }
        }
        project.lastUpdateTimestamp = block.timestamp;
    }

    /**
     * @dev Internally releases a portion of the funded amount to the project creator's withdrawable balance
     * upon successful milestone verification.
     * This function is called internally after a milestone is approved.
     * @param _projectId The ID of the project.
     * @param _milestoneId The ID of the milestone.
     */
    function _releaseMilestoneFunds(uint256 _projectId, uint256 _milestoneId) internal whenNotPaused {
        Project storage project = projects[_projectId];
        Milestone storage milestone = project.milestones[_milestoneId];

        require(milestone.status == MilestoneStatus.Approved, "Milestone not approved for fund release");
        require(_projectId > 0 && _projectId <= _projectIdCounter.current(), "Invalid Project ID");
        require(_milestoneId == project.currentMilestoneIndex, "Funds can only be released for the current approved milestone");

        uint256 amountToRelease = project.fundingGoal.mul(milestone.fundingAllocation).div(10000);
        require(project.fundsRaised >= amountToRelease, "Insufficient project funds raised for this milestone"); // Ensure we have enough from funders

        withdrawableBalances[project.creator] = withdrawableBalances[project.creator].add(amountToRelease);
        
        project.currentMilestoneIndex++;
        if (project.currentMilestoneIndex >= project.numMilestones) {
            project.status = ProjectStatus.Completed;
            _updateAuraScore(project.creator, 100, "Project successfully completed");
            mintSynergyOrb(project.creator, _projectId, "Creator_Completed"); // Mint an evolved Orb for completion
        } else {
            project.status = ProjectStatus.Active; // Move to next milestone
            // No direct Aura update here, was done in reviewMilestoneCompletion if successful
        }
        project.lastUpdateTimestamp = block.timestamp;
        
        // Evolve Synergy Orbs associated with this project due to milestone completion
        for (uint256 i = 1; i <= _synergyOrbIdCounter.current(); i++) {
            if (synergyOrbProjectMapping[i] == _projectId) {
                address orbOwner = ownerOf(i);
                evolveSynergyOrb(i, string(abi.encodePacked("Milestone_", _milestoneId.toString(), "_Completion")));
                _updateAuraScore(orbOwner, 5, "Synergy Orb evolved due to milestone completion");
            }
        }
        
        emit MilestoneFundsReleased(_projectId, _milestoneId, amountToRelease);
        emit ProjectStatusUpdated(_projectId, project.status);
    }

    /**
     * @dev Allows project creators to withdraw their available released funds.
     * Funds are added to `withdrawableBalances` upon successful milestone approval.
     * @param _projectId The ID of the project from which funds are being withdrawn (for event tracking).
     * @param _amount The amount of funds to withdraw (in Wei).
     */
    function withdrawProjectFunds(uint256 _projectId, uint256 _amount) public whenNotPaused {
        require(_projectId > 0 && _projectId <= _projectIdCounter.current(), "Invalid Project ID");
        Project storage project = projects[_projectId];
        require(project.creator == msg.sender, "Only project creator can withdraw funds");
        require(_amount > 0, "Withdrawal amount must be greater than zero");
        require(withdrawableBalances[msg.sender] >= _amount, "Insufficient withdrawable balance");

        withdrawableBalances[msg.sender] = withdrawableBalances[msg.sender].sub(_amount);
        project.fundsWithdrawn = project.fundsWithdrawn.add(_amount);
        payable(msg.sender).transfer(_amount);

        _updateAuraScore(msg.sender, 5, "Withdrew project funds");
        emit ProjectFundsWithdrawn(_projectId, msg.sender, _amount);
    }

    /**
     * @dev Retrieves all structured information about a specific project.
     * @param _projectId The ID of the project.
     * @return A tuple containing all project details.
     */
    function getProjectDetails(uint256 _projectId) public view returns (
        uint256 id,
        address creator,
        string memory name,
        string memory descriptionHash,
        uint256 fundingGoal,
        uint256 fundsRaised,
        uint256 fundsWithdrawn,
        uint256 currentMilestoneIndex,
        ProjectStatus status,
        uint256 creationTimestamp,
        uint256 lastUpdateTimestamp,
        uint256 numMilestones,
        int256 aiProposalAssessmentScore,
        uint256 totalSynergyOrbsMinted
    ) {
        require(_projectId > 0 && _projectId <= _projectIdCounter.current(), "Invalid Project ID");
        Project storage project = projects[_projectId];
        return (
            project.id,
            project.creator,
            project.name,
            project.descriptionHash,
            project.fundingGoal,
            project.fundsRaised,
            project.fundsWithdrawn,
            project.currentMilestoneIndex,
            project.status,
            project.creationTimestamp,
            project.lastUpdateTimestamp,
            project.numMilestones,
            project.aiProposalAssessmentScore,
            project.totalSynergyOrbsMinted
        );
    }

    /**
     * @dev Returns the current status of a project.
     * @param _projectId The ID of the project.
     * @return The ProjectStatus enum value.
     */
    function getProjectStatus(uint256 _projectId) public view returns (ProjectStatus) {
        require(_projectId > 0 && _projectId <= _projectIdCounter.current(), "Invalid Project ID");
        return projects[_projectId].status;
    }

    // --- Dynamic NFT (Synergy Orb) Ecosystem ---

    /**
     * @dev Mints a non-transferable (Soulbound) Synergy Orb NFT to users who make significant
     * contributions or achieve project milestones.
     * This function is primarily intended for internal calls by the contract logic.
     * @param _to The address to mint the Orb to.
     * @param _projectId The ID of the project this Orb is associated with.
     * @param _contributionType A string indicating the type of contribution (e.g., "Funder", "Creator_Completed").
     */
    function mintSynergyOrb(address _to, uint256 _projectId, string memory _contributionType) public whenNotPaused {
        // Ensure only the contract itself or authorized roles can mint Orbs
        require(msg.sender == address(this) || hasRole(PROJECT_MANAGER_ROLE, msg.sender) || hasRole(ADMIN_ROLE, msg.sender), "Unauthorized to mint Orb");
        
        _synergyOrbIdCounter.increment();
        uint256 newTokenId = _synergyOrbIdCounter.current();
        _safeMint(_to, newTokenId);
        synergyOrbProjectMapping[newTokenId] = _projectId;
        // Make it non-transferable (soulbound) by immediately revoking any potential transfer permissions.
        // ERC721 `approve` and `transferFrom` are overridden below to always revert.
        
        projects[_projectId].totalSynergyOrbsMinted++;
        _updateAuraScore(_to, 15, string(abi.encodePacked("Minted Synergy Orb for ", _contributionType)));
        emit SynergyOrbMinted(newTokenId, _to, _projectId, _contributionType);
    }

    /**
     * @dev Updates the metadata/traits of a Synergy Orb NFT based on the associated project's progress,
     * the holder's Aura Score, or AI feedback.
     * This function is primarily intended for internal calls by the contract logic.
     * The actual metadata JSON (returned by `tokenURI`) would dynamically reflect these internal state changes.
     * @param _orbId The ID of the Synergy Orb to evolve.
     * @param _reason A string indicating why the Orb is evolving (e.g., "Milestone_Completion", "Aura_Boost").
     */
    function evolveSynergyOrb(uint256 _orbId, string memory _reason) public whenNotPaused {
        require(_exists(_orbId), "Synergy Orb does not exist");
        // Ensure only the contract itself or authorized roles can evolve Orbs
        require(msg.sender == address(this) || hasRole(PROJECT_MANAGER_ROLE, msg.sender) || hasRole(ADMIN_ROLE, msg.sender), "Unauthorized to evolve Orb");

        // In a full implementation, this function would update specific on-chain attributes
        // (e.g., `_orbAttributes[_orbId].level`, `_orbAttributes[_orbId].traits`)
        // that the off-chain `_synergyOrbBaseURI` endpoint uses to generate dynamic JSON metadata.
        
        emit SynergyOrbEvolved(_orbId, _reason);
        // Note: The `tokenURI` will return the same URI, but the content at that URI should change
        // based on the updated on-chain state or external data referenced by the Orb's current state.
    }

    /**
     * @dev Returns the dynamic metadata URI for a given Synergy Orb, reflecting its current state.
     * Overrides ERC721's tokenURI. The actual JSON data is served by an off-chain API,
     * which reads the Orb's associated project status, holder's Aura, etc.
     * @param tokenId The ID of the Synergy Orb.
     * @return The URI for the Orb's metadata.
     */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        return string(abi.encodePacked(_synergyOrbBaseURI, tokenId.toString()));
    }

    /**
     * @dev Makes Synergy Orbs non-transferable (Soulbound Tokens).
     * Overrides OpenZeppelin's internal `_approve` function to always revert,
     * preventing any form of explicit approval for transfer.
     */
    function _approve(address to, uint256 tokenId) internal override {
        revert("Synergy Orbs are non-transferable.");
    }

    /**
     * @dev Makes Synergy Orbs non-transferable (Soulbound Tokens).
     * Overrides OpenZeppelin's internal `_transfer` function to always revert,
     * preventing any form of direct token transfer.
     */
    function _transfer(address from, address to, uint256 tokenId) internal override {
        revert("Synergy Orbs are non-transferable.");
    }

    // --- Decentralized Autonomous Organization (DAO) Governance ---

    /**
     * @dev Allows users (with sufficient Aura) to propose changes to protocol parameters,
     * new features, or critical project decisions.
     * The proposal includes `callData` and `targetContract` for direct execution.
     * @param _descriptionHash IPFS hash for detailed proposal description.
     * @param _targetContract The address of the contract that will be called if the proposal passes.
     * @param _callData The ABI-encoded function call to execute if the proposal passes.
     */
    function createGovernanceProposal(
        string memory _descriptionHash,
        address _targetContract,
        bytes memory _callData
    ) public whenNotPaused returns (uint256) {
        require(getAuraScore(msg.sender) >= MIN_AURA_FOR_PROPOSAL, "Insufficient Aura to create proposal");
        
        _daoProposalIdCounter.increment();
        uint252 newProposalId = _daoProposalIdCounter.current();

        DAOProposal storage newProposal = daoProposals[newProposalId];
        newProposal.id = newProposalId;
        newProposal.proposer = msg.sender;
        newProposal.descriptionHash = _descriptionHash;
        newProposal.targetContract = _targetContract;
        newProposal.callData = _callData;
        newProposal.voteStartTime = block.timestamp;
        newProposal.voteEndTime = block.timestamp.add(proposalVotingPeriod);
        newProposal.votesFor = 0;
        newProposal.votesAgainst = 0;
        newProposal.executed = false;
        newProposal.passed = false;

        _updateAuraScore(msg.sender, 10, "Created a DAO proposal");
        emit DAOProposalCreated(newProposalId, msg.sender, _descriptionHash);
        return newProposalId;
    }

    /**
     * @dev Enables eligible users to vote on active governance proposals.
     * Their vote weight is influenced by their Aura Score.
     * @param _proposalId The ID of the proposal to vote on.
     * @param _support True for 'for' vote, false for 'against' vote.
     */
    function voteOnProposal(uint256 _proposalId, bool _support) public whenNotPaused {
        require(_proposalId > 0 && _proposalId <= _daoProposalIdCounter.current(), "Invalid Proposal ID");
        DAOProposal storage proposal = daoProposals[_proposalId];
        require(block.timestamp >= proposal.voteStartTime, "Voting has not started");
        require(block.timestamp < proposal.voteEndTime, "Voting has ended");
        require(!proposal.hasVoted[msg.sender], "You have already voted on this proposal");
        
        uint256 voteWeight = getAuraInfluenceMultiplier(msg.sender); // Aura-weighted vote
        
        if (_support) {
            proposal.votesFor = proposal.votesFor.add(voteWeight);
            _updateAuraScore(msg.sender, 2, "Voted FOR a proposal");
        } else {
            proposal.votesAgainst = proposal.votesAgainst.add(voteWeight);
            _updateAuraScore(msg.sender, 2, "Voted AGAINST a proposal");
        }
        proposal.hasVoted[msg.sender] = true;
        emit DAOProposalVoted(_proposalId, msg.sender, _support, voteWeight);
    }

    /**
     * @dev Executes the changes specified in a passed governance proposal.
     * Can be called by anyone after the voting period ends and the proposal has met the passing criteria.
     * @param _proposalId The ID of the proposal to execute.
     */
    function executeProposal(uint256 _proposalId) public whenNotPaused {
        require(_proposalId > 0 && _proposalId <= _daoProposalIdCounter.current(), "Invalid Proposal ID");
        DAOProposal storage proposal = daoProposals[_proposalId];
        require(block.timestamp >= proposal.voteEndTime, "Voting period has not ended");
        require(!proposal.executed, "Proposal already executed");
        require(!proposal.passed, "Proposal already passed and executed"); // Ensure it hasn't been set passed by a previous call

        // Check if proposal passes: majority Aura-weighted votes FOR, plus a minimum participation (quorum)
        uint256 totalVotes = proposal.votesFor.add(proposal.votesAgainst);
        require(totalVotes > 0, "No votes cast for this proposal");
        // Example passing criteria: Simple majority of Aura-weighted votes for + a minimum total vote threshold
        require(proposal.votesFor > proposal.votesAgainst, "Proposal did not pass: 'for' votes not greater than 'against' votes.");
        
        // Execute the call data
        (bool success, ) = proposal.targetContract.call(proposal.callData);
        require(success, "Proposal execution failed");
        
        proposal.passed = true;
        proposal.executed = true;
        _updateAuraScore(proposal.proposer, 30, "DAO Proposal successfully executed"); // Proposer gets significant Aura boost
        emit DAOProposalExecuted(_proposalId);
    }

    // --- Fallback & Receive Functions ---
    receive() external payable {
        // Allows direct ETH transfers to the contract.
        // ETH received here increases the contract's overall balance,
        // which will be used for project funding.
    }
}
```