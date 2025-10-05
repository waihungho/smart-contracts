Here is a smart contract in Solidity called `AetherForge`. It envisions a decentralized platform for intellectual property (IP) and innovation, incorporating advanced concepts like generative proposal templating (simulated), a reputation-weighted evaluation system, adaptive fees, and on-chain IP management.

This contract aims to be creative by combining a structured approach to innovation (innovation pools, generative ideas) with decentralized governance elements (curators, reputation), and a unique IP finalization mechanism. It avoids direct duplication of standard open-source DAO, NFT, or DeFi lending patterns by focusing on a specific innovation lifecycle management.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol"; // Used for basic string conversions

// Outline:
// I. Core Data Structures: Definitions for Participants, Innovation Pools, Proposals, Generative Ideas, Evaluations, and IP Ownership.
// II. User & Skill Management: Functions for participant registration, profile updates, and skill endorsements.
// III. Innovation Pool Management: Functions to create, update, manage curators, and merge innovation pools.
// IV. Generative Proposal & Submission: Functions to initiate generative idea templates, refine them, and submit final proposals.
// V. Funding & Evaluation: Functions for depositing funds, staking for evaluation, submitting evaluations, allocating funds, and disputing evaluations.
// VI. Reputation & Rewards: Functions for claiming rewards and querying adaptive fees based on system dynamics.
// VII. Intellectual Property (IP) Management: Functions to finalize IP ownership for successful proposals and release IP to the public domain.
// VIII. View Functions: Essential getter functions for retrieving contract state (not explicitly counted in the 20 interactive functions below).

// Function Summary (20 unique interactive functions):
// These functions represent the core interactive capabilities of the AetherForge platform.

// --- I. User & Skill Management ---
// 1.  registerParticipant(string calldata _username, string[] calldata _initialSkills):
//     Registers a new participant with a unique username and a set of initial skills.
//     Assigns a base reputation score.
// 2.  updateParticipantProfile(string calldata _newUsername, string[] calldata _newSkills):
//     Allows an existing participant to update their username and add new skills to their profile.
// 3.  endorseSkill(address _participant, string calldata _skill):
//     Enables a participant to endorse another participant's claimed skill, subtly boosting
//     the endorsed participant's skill-specific and overall reputation.

// --- II. Innovation Pool Management ---
// 4.  createInnovationPool(string calldata _name, string calldata _description, uint256 _targetFundingAmount, address[] calldata _initialCurators, string[] calldata _requiredSkills):
//     Creates a new "Innovation Pool" with a defined objective, target funding, initial curators,
//     and a list of skills relevant for contributing to it.
// 5.  updatePoolDetails(uint256 _poolId, string calldata _newDescription):
//     Allows curators of a pool to update its description to reflect evolving goals or focus.
// 6.  delegatePoolCuratorship(uint256 _poolId, address _newCurator, bool _revoke):
//     Enables existing curators to add or remove other participants as curators for their pool,
//     facilitating dynamic governance.
// 7.  mergeInnovationPools(uint256 _poolId1, uint256 _poolId2, string calldata _mergedName, string calldata _mergedDescription):
//     A sophisticated function allowing two distinct innovation pools to merge into a single,
//     new pool, combining their funds, objectives, and curator teams.

// --- III. Generative Proposal & Submission ---
// 8.  seedGenerativeIdea(uint256 _poolId, string calldata _initialKeywords, uint256 _minComplexity, uint256 _maxComplexity):
//     Initiates a "generative idea" process within a specific pool. The contract generates a structured
//     template (simulated as a JSON-like string) based on keywords and desired complexity, providing a starting point for proposals.
// 9.  refineGenerativeProposal(uint256 _generativeIdeaId, string calldata _refinementPrompt):
//     Allows participants to submit suggestions or prompts to "refine" a generated idea template,
//     contributing to a collective intelligence approach (a form of "cognitive mining").
// 10. submitFinalProposal(uint256 _generativeIdeaId, string calldata _finalDescription, uint256 _estimatedCost, uint256 _estimatedImpactScore):
//     Enables the original proposer to submit a finalized, detailed proposal derived from a generative
//     idea template, including estimated cost and impact.

// --- IV. Funding & Evaluation ---
// 11. depositFunding(uint256 _poolId, uint256 _amount):
//     Allows participants to deposit AETH tokens into an innovation pool to support its objectives
//     and fund proposals.
// 12. stakeForEvaluation(uint256 _proposalId, uint256 _stakeAmount):
//     Participants can stake AETH tokens to commit to evaluating a specific proposal, acting as a
//     bond for their assessment.
// 13. evaluateProposal(uint256 _proposalId, uint256 _impactScore, uint256 _feasibilityScore, string calldata _feedback):
//     Evaluators submit their assessment of a proposal's impact and feasibility, along with qualitative feedback.
// 14. allocateFundsToProposal(uint256 _poolId, uint256 _proposalId, uint256 _amount):
//     Curators of a pool can allocate a portion of the pool's funds to a specific, approved proposal,
//     transferring the funds to the proposer.
// 15. disputeEvaluation(uint256 _proposalId, address _evaluator, string calldata _reason):
//     Allows any registered participant to formally dispute an evaluator's assessment,
//     triggering a review process by curators or the community.

// --- V. Reputation & Rewards ---
// 16. claimEvaluationReward(uint256 _proposalId):
//     Enables evaluators to claim their staked tokens back, plus a reward, if their evaluation
//     was deemed accurate (e.g., aligned with the proposal's final outcome or curator consensus).
// 17. claimProposalSuccessReward(uint256 _proposalId):
//     Allows the proposer of a successfully implemented and completed innovation to claim a
//     predetermined reward, acknowledging their achievement.
// 18. queryAdaptiveFee(uint256 _transactionType):
//     A view function that calculates and returns a dynamic fee for various transaction types,
//     adapting based on factors like network congestion, participant reputation, and overall contract activity.

// --- VI. Intellectual Property (IP) Management ---
// 19. finalizeIPOwnership(uint256 _proposalId, address _owner, uint256 _royaltyShareBasisPoints, uint256 _ownershipDurationBlocks):
//     Upon successful completion of a proposal, this function formalizes its IP ownership on-chain,
//     designating an owner, royalty structure for contributors/pool, and an ownership duration.
// 20. releaseIPPublicDomain(uint256 _proposalId):
//     Provides a mechanism for the designated IP owner to voluntarily release their intellectual
//     property rights into the public domain, making it freely available.


contract AetherForge is Ownable {
    using Counters for Counters.Counter;
    using Strings for uint256; // For basic string conversions

    // --- State Variables ---
    IERC20 public immutable AETHToken; // The primary token for funding, staking, and rewards

    // --- Counters for unique IDs ---
    Counters.Counter private _participantIds;
    Counters.Counter private _poolIds;
    Counters.Counter private _proposalIds;
    Counters.Counter private _generativeIdeaIds;

    // --- Constants for system parameters ---
    uint256 public constant MIN_INITIAL_REPUTATION = 100;
    uint256 public constant EVALUATION_STAKE_PERIOD_BLOCKS = 100; // Blocks after which evaluation stake can be released
    //uint256 public constant DISPUTE_RESOLUTION_PERIOD_BLOCKS = 50; // Blocks for dispute resolution (not fully implemented in this example)
    uint256 public constant REWARD_MULTIPLIER_BPS = 1000; // 10% base reward multiplier (1000 basis points)

    // --- Enums ---
    enum ProposalStatus {
        PendingEvaluation,
        UnderReview,
        Approved,
        Rejected,
        Funded,
        Completed,
        Failed
    }

    enum TransactionType {
        CreatePool,
        SubmitProposal,
        RefineIdea,
        StakeEvaluation,
        Dispute // Represents the dispute initiation
    }

    // --- Data Structures ---
    struct Participant {
        string username;
        uint256 reputationScore; // Overall reputation score
        mapping(string => uint256) skillReputation; // Reputation per specific skill
        mapping(string => bool) skills; // Set of skills the participant claims
        bool isRegistered;
    }

    struct InnovationPool {
        uint256 id;
        string name;
        string description;
        uint256 targetFundingAmount;
        uint256 currentFunding; // AETH tokens held by the pool
        mapping(address => bool) curators; // Address => isCurator
        address[] curatorList; // For easier iteration/retrieval of curators
        mapping(string => bool) requiredSkills; // Skills required for proposals in this pool
        bool isOpen; // Can new proposals be submitted?
        uint256 createdAt;
    }

    struct GenerativeIdeaDraft {
        uint256 id;
        uint256 poolId;
        address proposer;
        string initialKeywords;
        string generatedContentTemplate; // Simulated template, e.g., JSON string structure
        uint256 refinementCount; // How many times this draft has been refined
        uint256 createdAt;
    }

    struct Proposal {
        uint256 id;
        uint256 poolId;
        address proposer;
        string description;
        uint256 estimatedCost;
        uint256 estimatedImpactScore; // Proposer's self-assessment (0-100)
        uint256 currentFundingAllocated;
        ProposalStatus status;
        uint256 submittedAt;
        uint256 evaluationAverageScore; // Average of all evaluator impact/feasibility scores
        uint256 totalEvaluators;
        mapping(address => bool) hasEvaluated; // To prevent double evaluation per participant
        uint256 ipOwnershipId; // Link to IPOwnership record (0 if no IP finalized)
    }

    struct Evaluation {
        uint256 id; // Unique ID for each evaluation within a proposal's array
        uint256 proposalId;
        address evaluator;
        uint256 impactScore;    // 0-100
        uint256 feasibilityScore; // 0-100
        string feedback;
        uint256 stakeAmount;
        uint256 stakedAtBlock; // Block number when the stake was locked for this evaluation
        bool isDisputed;
        bool disputeResolved; // True if a dispute has been resolved (by curators/governance)
        bool rewardClaimed;
    }

    struct IPOwnership {
        uint256 id;
        uint256 proposalId;
        address owner;
        uint256 royaltyShareBasisPoints; // e.g., 500 for 5% of future revenues (conceptual)
        uint256 ownershipDurationBlocks; // 0 for perpetual ownership, otherwise duration in blocks
        uint256 finalizedAtBlock;
        bool isPublicDomain;
    }

    // --- Mappings ---
    mapping(address => Participant) public participants;
    mapping(uint256 => InnovationPool) public innovationPools;
    mapping(uint256 => GenerativeIdeaDraft) public generativeIdeaDrafts;
    mapping(uint256 => Proposal) public proposals;
    mapping(uint256 => Evaluation[]) public proposalEvaluations; // Proposal ID to list of all its evaluations
    mapping(address => mapping(uint256 => uint256)) public evaluationStakes; // evaluator => proposalId => stakeAmount
    mapping(uint256 => IPOwnership) public ipOwnerships; // IP ID (same as proposal ID) to IPOwnership data

    // --- Events ---
    event ParticipantRegistered(address indexed participantAddress, string username, uint256 reputationScore);
    event ParticipantProfileUpdated(address indexed participantAddress, string newUsername);
    event SkillEndorsed(address indexed endorser, address indexed participant, string skill);
    event InnovationPoolCreated(uint256 indexed poolId, string name, address indexed creator, uint256 targetFunding);
    event PoolDetailsUpdated(uint256 indexed poolId, string newDescription);
    event CuratorDelegated(uint256 indexed poolId, address indexed curator, bool added);
    event PoolsMerged(uint256 indexed newPoolId, uint256 indexed oldPoolId1, uint256 indexed oldPoolId2);
    event GenerativeIdeaSeeded(uint256 indexed ideaId, uint256 indexed poolId, address indexed proposer, string template);
    event GenerativeIdeaRefined(uint256 indexed ideaId, address indexed refiner);
    event ProposalSubmitted(uint256 indexed proposalId, uint256 indexed poolId, address indexed proposer, uint256 estimatedCost);
    event FundsDeposited(uint256 indexed poolId, address indexed depositor, uint256 amount);
    event EvaluationStakeLocked(uint256 indexed proposalId, address indexed evaluator, uint256 stakeAmount);
    event ProposalEvaluated(uint256 indexed proposalId, address indexed evaluator, uint256 impactScore, uint256 feasibilityScore);
    event FundsAllocated(uint256 indexed poolId, uint256 indexed proposalId, uint256 amount);
    event EvaluationDisputed(uint256 indexed proposalId, address indexed evaluator, address indexed disputer);
    event EvaluationRewardClaimed(uint256 indexed proposalId, address indexed evaluator, uint256 rewardAmount);
    event ProposalSuccessRewardClaimed(uint256 indexed proposalId, address indexed proposer, uint256 rewardAmount);
    event IPOwnershipFinalized(uint256 indexed ipId, uint256 indexed proposalId, address indexed owner, uint256 royaltyShareBasisPoints);
    event IPReleasedToPublicDomain(uint256 indexed ipId, uint256 indexed proposalId);

    // --- Constructor ---
    constructor(address _aethTokenAddress) Ownable(msg.sender) {
        require(_aethTokenAddress != address(0), "AETH Token address cannot be zero");
        AETHToken = IERC20(_aethTokenAddress);
    }

    // --- Modifiers ---
    modifier onlyRegisteredParticipant() {
        require(participants[msg.sender].isRegistered, "Caller is not a registered participant");
        _;
    }

    modifier onlyPoolCurator(uint256 _poolId) {
        require(innovationPools[_poolId].curators[msg.sender], "Caller is not a curator of this pool");
        _;
    }

    modifier proposalExists(uint256 _proposalId) {
        require(_proposalId > 0 && _proposalId <= _proposalIds.current(), "Proposal does not exist");
        _;
    }

    modifier poolExists(uint256 _poolId) {
        require(_poolId > 0 && _poolId <= _poolIds.current(), "Pool does not exist");
        _;
    }

    modifier generativeIdeaExists(uint256 _ideaId) {
        require(_ideaId > 0 && _ideaId <= _generativeIdeaIds.current(), "Generative Idea does not exist");
        _;
    }

    // --- Internal Utility Functions ---
    /// @dev Updates the overall reputation score of a participant.
    /// @param _participantAddress The address of the participant.
    /// @param _delta The amount to change the reputation score by (can be negative).
    function _updateReputation(address _participantAddress, int256 _delta) internal {
        Participant storage p = participants[_participantAddress];
        if (p.isRegistered) {
            if (_delta > 0) {
                p.reputationScore += uint256(_delta);
            } else {
                p.reputationScore = p.reputationScore > uint256(-_delta) ? p.reputationScore - uint256(-_delta) : 0;
            }
        }
    }

    /// @dev Transfers AETH tokens from this contract to a recipient.
    /// @param _to The recipient address.
    /// @param _amount The amount of AETH tokens to transfer.
    function _transferToken(address _to, uint256 _amount) internal {
        require(AETHToken.transfer(_to, _amount), "Token transfer failed");
    }

    /// @dev Transfers AETH tokens from a sender to this contract. Requires prior approval.
    /// @param _from The sender address.
    /// @param _to The recipient address (usually this contract).
    /// @param _amount The amount of AETH tokens to transfer.
    function _transferTokenFrom(address _from, address _to, uint256 _amount) internal {
        require(AETHToken.transferFrom(_from, _to, _amount), "Token transferFrom failed");
    }

    // --- I. User & Skill Management ---

    /// @notice Registers a new participant in the AetherForge system.
    /// @param _username The desired username for the participant.
    /// @param _initialSkills An array of skills the participant claims to possess.
    /// @dev Initial reputation is set to MIN_INITIAL_REPUTATION.
    function registerParticipant(string calldata _username, string[] calldata _initialSkills)
        external
    {
        require(!participants[msg.sender].isRegistered, "Participant already registered");
        require(bytes(_username).length > 0, "Username cannot be empty");

        participants[msg.sender].username = _username;
        participants[msg.sender].reputationScore = MIN_INITIAL_REPUTATION;
        participants[msg.sender].isRegistered = true;

        for (uint256 i = 0; i < _initialSkills.length; i++) {
            participants[msg.sender].skills[_initialSkills[i]] = true;
            participants[msg.sender].skillReputation[_initialSkills[i]] = MIN_INITIAL_REPUTATION; // Initial skill reputation
        }

        _participantIds.increment();
        emit ParticipantRegistered(msg.sender, _username, MIN_INITIAL_REPUTATION);
    }

    /// @notice Updates an existing participant's username and adds new skills to their profile.
    /// @param _newUsername The new username.
    /// @param _newSkills An array of additional skills to add. Existing skills are preserved.
    /// @dev This function adds new skills; it does not remove existing ones.
    function updateParticipantProfile(string calldata _newUsername, string[] calldata _newSkills)
        external
        onlyRegisteredParticipant
    {
        require(bytes(_newUsername).length > 0, "Username cannot be empty");

        participants[msg.sender].username = _newUsername;

        for (uint256 i = 0; i < _newSkills.length; i++) {
            if (!participants[msg.sender].skills[_newSkills[i]]) {
                participants[msg.sender].skills[_newSkills[i]] = true;
                // Assign initial reputation to newly added skills if not already present
                if (participants[msg.sender].skillReputation[_newSkills[i]] == 0) {
                     participants[msg.sender].skillReputation[_newSkills[i]] = MIN_INITIAL_REPUTATION;
                }
            }
        }
        emit ParticipantProfileUpdated(msg.sender, _newUsername);
    }

    /// @notice Allows a participant to endorse another participant's skill.
    /// @param _participant The address of the participant whose skill is being endorsed.
    /// @param _skill The skill being endorsed.
    /// @dev Endorsing a skill increases the target participant's skill-specific and overall reputation.
    function endorseSkill(address _participant, string calldata _skill)
        external
        onlyRegisteredParticipant
    {
        require(_participant != msg.sender, "Cannot endorse your own skill");
        require(participants[_participant].isRegistered, "Target participant not registered");
        require(participants[_participant].skills[_skill], "Target participant does not claim this skill");

        // A simple, fixed reputation boost. Could be weighted by endorser's reputation in a more complex system.
        participants[_participant].skillReputation[_skill] += 5;
        _updateReputation(_participant, 5); // General reputation boost too
        emit SkillEndorsed(msg.sender, _participant, _skill);
    }

    // --- II. Innovation Pool Management ---

    /// @notice Creates a new innovation pool.
    /// @param _name The name of the innovation pool.
    /// @param _description A detailed description of the pool's objectives.
    /// @param _targetFundingAmount The target funding amount in AETH for this pool.
    /// @param _initialCurators An array of addresses to be appointed as initial curators.
    /// @param _requiredSkills An array of skills deemed necessary for contributing to this pool.
    /// @return poolId The ID of the newly created innovation pool.
    function createInnovationPool(
        string calldata _name,
        string calldata _description,
        uint256 _targetFundingAmount,
        address[] calldata _initialCurators,
        string[] calldata _requiredSkills
    ) external onlyRegisteredParticipant returns (uint256 poolId) {
        _poolIds.increment();
        poolId = _poolIds.current();

        innovationPools[poolId].id = poolId;
        innovationPools[poolId].name = _name;
        innovationPools[poolId].description = _description;
        innovationPools[poolId].targetFundingAmount = _targetFundingAmount;
        innovationPools[poolId].isOpen = true;
        innovationPools[poolId].createdAt = block.timestamp;

        for (uint256 i = 0; i < _initialCurators.length; i++) {
            require(participants[_initialCurators[i]].isRegistered, "Initial curator not registered");
            innovationPools[poolId].curators[_initialCurators[i]] = true;
            innovationPools[poolId].curatorList.push(_initialCurators[i]);
        }
        require(innovationPools[poolId].curatorList.length > 0, "At least one initial curator is required");

        for (uint256 i = 0; i < _requiredSkills.length; i++) {
            innovationPools[poolId].requiredSkills[_requiredSkills[i]] = true;
        }

        emit InnovationPoolCreated(poolId, _name, msg.sender, _targetFundingAmount);
        return poolId;
    }

    /// @notice Updates the description of an existing innovation pool.
    /// @param _poolId The ID of the innovation pool to update.
    /// @param _newDescription The new description for the pool.
    function updatePoolDetails(uint256 _poolId, string calldata _newDescription)
        external
        onlyPoolCurator(_poolId)
        poolExists(_poolId)
    {
        require(bytes(_newDescription).length > 0, "Description cannot be empty");
        innovationPools[_poolId].description = _newDescription;
        emit PoolDetailsUpdated(_poolId, _newDescription);
    }

    /// @notice Adds or removes a curator from an innovation pool.
    /// @param _poolId The ID of the innovation pool.
    /// @param _newCurator The address of the participant to add or remove as a curator.
    /// @param _revoke If true, removes the curator; if false, adds them.
    function delegatePoolCuratorship(uint256 _poolId, address _newCurator, bool _revoke)
        external
        onlyPoolCurator(_poolId)
        poolExists(_poolId)
    {
        require(participants[_newCurator].isRegistered, "New curator not registered");
        if (_revoke) {
            require(innovationPools[_poolId].curators[_newCurator], "Participant is not a curator");
            require(innovationPools[_poolId].curatorList.length > 1, "Cannot remove the last curator");
            innovationPools[_poolId].curators[_newCurator] = false;
            // Remove from list (inefficient for very large lists, but simple)
            for (uint256 i = 0; i < innovationPools[_poolId].curatorList.length; i++) {
                if (innovationPools[_poolId].curatorList[i] == _newCurator) {
                    innovationPools[_poolId].curatorList[i] = innovationPools[_poolId].curatorList[innovationPools[_poolId].curatorList.length - 1];
                    innovationPools[_poolId].curatorList.pop();
                    break;
                }
            }
            emit CuratorDelegated(_poolId, _newCurator, false);
        } else {
            require(!innovationPools[_poolId].curators[_newCurator], "Participant is already a curator");
            innovationPools[_poolId].curators[_newCurator] = true;
            innovationPools[_poolId].curatorList.push(_newCurator);
            emit CuratorDelegated(_poolId, _newCurator, true);
        }
    }

    /// @notice Merges two existing innovation pools into a new one.
    /// @param _poolId1 The ID of the first innovation pool.
    /// @param _poolId2 The ID of the second innovation pool.
    /// @param _mergedName The name for the new merged pool.
    /// @param _mergedDescription The description for the new merged pool.
    /// @return newPoolId The ID of the newly created merged pool.
    /// @dev Funds from both pools are combined into the new pool. Curators are combined.
    ///      Required skills for the new pool start empty and can be updated by curators.
    function mergeInnovationPools(
        uint256 _poolId1,
        uint256 _poolId2,
        string calldata _mergedName,
        string calldata _mergedDescription
    ) external onlyRegisteredParticipant returns (uint256 newPoolId) {
        require(_poolId1 != _poolId2, "Cannot merge a pool with itself");
        require(innovationPools[_poolId1].isOpen && innovationPools[_poolId2].isOpen, "Both pools must be open to merge");
        require(innovationPools[_poolId1].curators[msg.sender] || innovationPools[_poolId2].curators[msg.sender], "Caller must be a curator of at least one pool");

        InnovationPool storage pool1 = innovationPools[_poolId1];
        InnovationPool storage pool2 = innovationPools[_poolId2];

        _poolIds.increment();
        newPoolId = _poolIds.current();

        innovationPools[newPoolId].id = newPoolId;
        innovationPools[newPoolId].name = _mergedName;
        innovationPools[newPoolId].description = _mergedDescription;
        innovationPools[newPoolId].targetFundingAmount = pool1.targetFundingAmount + pool2.targetFundingAmount;
        innovationPools[newPoolId].currentFunding = pool1.currentFunding + pool2.currentFunding;
        innovationPools[newPoolId].isOpen = true;
        innovationPools[newPoolId].createdAt = block.timestamp;

        // Combine curators (avoiding duplicates)
        for (uint256 i = 0; i < pool1.curatorList.length; i++) {
            if (!innovationPools[newPoolId].curators[pool1.curatorList[i]]) {
                innovationPools[newPoolId].curators[pool1.curatorList[i]] = true;
                innovationPools[newPoolId].curatorList.push(pool1.curatorList[i]);
            }
        }
        for (uint256 i = 0; i < pool2.curatorList.length; i++) {
            if (!innovationPools[newPoolId].curators[pool2.curatorList[i]]) {
                innovationPools[newPoolId].curators[pool2.curatorList[i]] = true;
                innovationPools[newPoolId].curatorList.push(pool2.curatorList[i]);
            }
        }
        require(innovationPools[newPoolId].curatorList.length > 0, "Merged pool must have at least one curator");

        // Required skills for the new pool are left empty by default. Curators can add them later.

        // Close original pools
        pool1.isOpen = false;
        pool2.isOpen = false;

        emit PoolsMerged(newPoolId, _poolId1, _poolId2);
        return newPoolId;
    }

    // --- III. Generative Proposal & Submission ---

    /// @notice Initiates a generative idea template within a specified innovation pool.
    /// @param _poolId The ID of the innovation pool.
    /// @param _initialKeywords Keywords to guide the template generation.
    /// @param _minComplexity Minimum complexity score for the generated template (simulated).
    /// @param _maxComplexity Maximum complexity score for the generated template (simulated).
    /// @return ideaId The ID of the generated idea draft.
    /// @return generatedTemplate The structured content template string (e.g., JSON).
    /// @dev This function simulates the generation of a structured proposal template based on input.
    /// It could be a simple prompt or a more complex JSON structure for an off-chain AI.
    function seedGenerativeIdea(
        uint256 _poolId,
        string calldata _initialKeywords,
        uint256 _minComplexity,
        uint256 _maxComplexity
    ) external onlyRegisteredParticipant poolExists(_poolId) returns (uint256 ideaId, string memory generatedTemplate) {
        require(innovationPools[_poolId].isOpen, "Pool is not open for new ideas");

        _generativeIdeaIds.increment();
        ideaId = _generativeIdeaIds.current();

        // Simulate generative template creation.
        // In a real system, this might involve an oracle call to an AI service,
        // or a complex on-chain logic that combines predefined segments.
        // For this example, it generates a basic JSON-like string.
        string memory complexityStr = _minComplexity.toString() + "-" + _maxComplexity.toString();
        generatedTemplate = string(abi.encodePacked(
            '{"title": "Idea Template for ', _initialKeywords, '", "description_prompt": "Elaborate on the problem and solution, considering complexity (', complexityStr, ').", "impact_metrics_prompt": "Define measurable success metrics.", "timeline_prompt": "Outline key milestones and estimated duration."}'
        ));

        generativeIdeaDrafts[ideaId] = GenerativeIdeaDraft({
            id: ideaId,
            poolId: _poolId,
            proposer: msg.sender,
            initialKeywords: _initialKeywords,
            generatedContentTemplate: generatedTemplate,
            refinementCount: 0,
            createdAt: block.timestamp
        });

        emit GenerativeIdeaSeeded(ideaId, _poolId, msg.sender, generatedTemplate);
        return (ideaId, generatedTemplate);
    }

    /// @notice Allows participants to refine a generated idea template.
    /// @param _generativeIdeaId The ID of the generative idea draft to refine.
    /// @param _refinementPrompt A prompt or suggestion to improve the generated template.
    /// @dev Each refinement increases the idea's refinementCount, potentially boosting its visibility or proposer's cognitive mining reputation.
    function refineGenerativeProposal(uint256 _generativeIdeaId, string calldata _refinementPrompt)
        external
        onlyRegisteredParticipant
        generativeIdeaExists(_generativeIdeaId)
    {
        GenerativeIdeaDraft storage draft = generativeIdeaDrafts[_generativeIdeaId];
        // The _refinementPrompt is not directly stored in `generatedContentTemplate` due to EVM string complexity.
        // It acts as a signal for future off-chain processing or as a contribution marker.

        draft.refinementCount++;
        _updateReputation(msg.sender, 2); // Small reputation boost for contributing to idea refinement.

        emit GenerativeIdeaRefined(_generativeIdeaId, msg.sender);
    }

    /// @notice Submits a finalized proposal based on a generative idea draft.
    /// @param _generativeIdeaId The ID of the generative idea draft.
    /// @param _finalDescription The detailed, finalized description of the proposal.
    /// @param _estimatedCost The estimated AETH cost to implement the proposal.
    /// @param _estimatedImpactScore The proposer's assessment of the proposal's impact (0-100).
    /// @return proposalId The ID of the newly submitted proposal.
    function submitFinalProposal(
        uint256 _generativeIdeaId,
        string calldata _finalDescription,
        uint256 _estimatedCost,
        uint256 _estimatedImpactScore
    ) external onlyRegisteredParticipant generativeIdeaExists(_generativeIdeaId) returns (uint256 proposalId) {
        GenerativeIdeaDraft storage draft = generativeIdeaDrafts[_generativeIdeaId];
        require(msg.sender == draft.proposer, "Only the original proposer can submit a final proposal");
        require(bytes(_finalDescription).length > 0, "Proposal description cannot be empty");
        require(_estimatedCost > 0, "Estimated cost must be greater than zero");
        require(_estimatedImpactScore <= 100, "Estimated impact score must be between 0 and 100");
        require(innovationPools[draft.poolId].isOpen, "Associated pool is not open for new proposals");

        _proposalIds.increment();
        proposalId = _proposalIds.current();

        proposals[proposalId] = Proposal({
            id: proposalId,
            poolId: draft.poolId,
            proposer: msg.sender,
            description: _finalDescription,
            estimatedCost: _estimatedCost,
            estimatedImpactScore: _estimatedImpactScore,
            currentFundingAllocated: 0,
            status: ProposalStatus.PendingEvaluation,
            submittedAt: block.timestamp,
            evaluationAverageScore: 0,
            totalEvaluators: 0,
            hasEvaluated: new mapping(address => bool)(), // Initialize mapping for evaluator tracking
            ipOwnershipId: 0
        });

        emit ProposalSubmitted(proposalId, draft.poolId, msg.sender, _estimatedCost);
        return proposalId;
    }

    // --- IV. Funding & Evaluation ---

    /// @notice Deposits AETH tokens into an innovation pool.
    /// @param _poolId The ID of the innovation pool to fund.
    /// @param _amount The amount of AETH tokens to deposit.
    function depositFunding(uint256 _poolId, uint256 _amount)
        external
        onlyRegisteredParticipant
        poolExists(_poolId)
    {
        require(innovationPools[_poolId].isOpen, "Pool is not open for funding");
        require(_amount > 0, "Deposit amount must be greater than zero");

        _transferTokenFrom(msg.sender, address(this), _amount);
        innovationPools[_poolId].currentFunding += _amount;

        emit FundsDeposited(_poolId, msg.sender, _amount);
    }

    /// @notice Stakes AETH tokens to become an evaluator for a specific proposal.
    /// @param _proposalId The ID of the proposal to evaluate.
    /// @param _stakeAmount The amount of AETH tokens to stake.
    function stakeForEvaluation(uint256 _proposalId, uint256 _stakeAmount)
        external
        onlyRegisteredParticipant
        proposalExists(_proposalId)
    {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.proposer != msg.sender, "Proposer cannot evaluate their own proposal");
        require(proposal.status == ProposalStatus.PendingEvaluation || proposal.status == ProposalStatus.UnderReview, "Proposal is not in an evaluable state");
        require(_stakeAmount > 0, "Stake amount must be greater than zero");
        require(evaluationStakes[msg.sender][_proposalId] == 0, "Already staked for this proposal");

        _transferTokenFrom(msg.sender, address(this), _stakeAmount);
        evaluationStakes[msg.sender][_proposalId] = _stakeAmount;
        // Update proposal status to UnderReview if it was PendingEvaluation
        if (proposal.status == ProposalStatus.PendingEvaluation) {
            proposal.status = ProposalStatus.UnderReview;
        }

        emit EvaluationStakeLocked(_proposalId, msg.sender, _stakeAmount);
    }

    /// @notice Submits an evaluation for a proposal.
    /// @param _proposalId The ID of the proposal being evaluated.
    /// @param _impactScore The evaluator's impact score (0-100).
    /// @param _feasibilityScore The evaluator's feasibility score (0-100).
    /// @param _feedback Detailed feedback from the evaluator.
    /// @dev Evaluator must have staked previously for this proposal and not evaluated it yet.
    function evaluateProposal(
        uint256 _proposalId,
        uint256 _impactScore,
        uint256 _feasibilityScore,
        string calldata _feedback
    ) external onlyRegisteredParticipant proposalExists(_proposalId) {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.proposer != msg.sender, "Proposer cannot evaluate their own proposal");
        require(evaluationStakes[msg.sender][_proposalId] > 0, "Must stake to evaluate this proposal");
        require(!proposal.hasEvaluated[msg.sender], "Already evaluated this proposal");
        require(_impactScore <= 100 && _feasibilityScore <= 100, "Scores must be between 0 and 100");
        require(proposal.status == ProposalStatus.UnderReview || proposal.status == ProposalStatus.PendingEvaluation, "Proposal is not open for evaluation");

        uint256 evalIndex = proposalEvaluations[_proposalId].length; // ID within the array
        proposalEvaluations[_proposalId].push(Evaluation({
            id: evalIndex,
            proposalId: _proposalId,
            evaluator: msg.sender,
            impactScore: _impactScore,
            feasibilityScore: _feasibilityScore,
            feedback: _feedback,
            stakeAmount: evaluationStakes[msg.sender][_proposalId],
            stakedAtBlock: block.number, // Record when the evaluation was *submitted*
            isDisputed: false,
            disputeResolved: false,
            rewardClaimed: false
        }));

        proposal.hasEvaluated[msg.sender] = true;
        proposal.totalEvaluators++;
        // Update running average of evaluation scores (simplified for this example)
        proposal.evaluationAverageScore = (proposal.evaluationAverageScore * (proposal.totalEvaluators - 1) + (_impactScore + _feasibilityScore) / 2) / proposal.totalEvaluators;

        emit ProposalEvaluated(_proposalId, msg.sender, _impactScore, _feasibilityScore);
    }

    /// @notice Curators allocate deposited funds from a pool to a proposal.
    /// @param _poolId The ID of the innovation pool.
    /// @param _proposalId The ID of the proposal to fund.
    /// @param _amount The amount of AETH tokens to allocate.
    /// @dev Only pool curators can allocate funds. Proposal status changes to 'Funded'.
    function allocateFundsToProposal(uint256 _poolId, uint256 _proposalId, uint256 _amount)
        external
        onlyPoolCurator(_poolId)
        proposalExists(_proposalId)
    {
        InnovationPool storage pool = innovationPools[_poolId];
        Proposal storage proposal = proposals[_proposalId];

        require(proposal.poolId == _poolId, "Proposal does not belong to this pool");
        require(pool.currentFunding >= _amount, "Insufficient funds in pool");
        require(_amount > 0, "Allocation amount must be greater than zero");
        require(
            proposal.status == ProposalStatus.PendingEvaluation ||
            proposal.status == ProposalStatus.UnderReview ||
            proposal.status == ProposalStatus.Approved, // Can fund if already approved
            "Proposal cannot be funded in its current state"
        );

        pool.currentFunding -= _amount;
        proposal.currentFundingAllocated += _amount;
        proposal.status = ProposalStatus.Funded;

        // Transfer funds from contract to proposer. This simulates the actual funding.
        _transferToken(proposal.proposer, _amount);

        _updateReputation(proposal.proposer, 50); // Significant reputation boost for successful funding

        emit FundsAllocated(_poolId, _proposalId, _amount);
    }

    /// @notice Initiates a dispute against an evaluator's assessment.
    /// @param _proposalId The ID of the proposal the evaluation belongs to.
    /// @param _evaluator The address of the evaluator whose assessment is being disputed.
    /// @param _reason A reason for the dispute.
    /// @dev This can only be called after the evaluation period ends and before rewards are claimed.
    /// Curators are expected to resolve the dispute, potentially slashing/rewarding evaluator.
    function disputeEvaluation(uint256 _proposalId, address _evaluator, string calldata _reason)
        external
        onlyRegisteredParticipant
        proposalExists(_proposalId)
    {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.status == ProposalStatus.Funded || proposal.status == ProposalStatus.Completed, "Proposal status not eligible for dispute resolution");

        bool foundEvaluation = false;
        uint256 evalIndex = 0;
        for (uint256 i = 0; i < proposalEvaluations[_proposalId].length; i++) {
            if (proposalEvaluations[_proposalId][i].evaluator == _evaluator) {
                evalIndex = i;
                foundEvaluation = true;
                break;
            }
        }
        require(foundEvaluation, "No evaluation found from this evaluator for this proposal");
        Evaluation storage eval = proposalEvaluations[_proposalId][evalIndex];

        require(!eval.isDisputed, "Evaluation already disputed");
        require(!eval.rewardClaimed, "Cannot dispute a claimed reward");
        require(block.number >= eval.stakedAtBlock + EVALUATION_STAKE_PERIOD_BLOCKS, "Cannot dispute before evaluation period ends"); // Allow dispute after a delay
        require(bytes(_reason).length > 0, "Dispute reason cannot be empty");

        eval.isDisputed = true;
        // In a full system, this would trigger a governance vote or curator review.
        // For simplicity, `disputeResolved` must be set by an off-chain process or a privileged call by a curator for this example.

        _updateReputation(msg.sender, -5); // Small reputational cost for initiating a potentially frivolous dispute.

        emit EvaluationDisputed(_proposalId, _evaluator, msg.sender);
    }

    // --- V. Reputation & Rewards ---

    /// @notice Allows evaluators to claim rewards for accurate evaluations.
    /// @param _proposalId The ID of the proposal that was evaluated.
    /// @dev Rewards are distributed based on the accuracy of the evaluation (e.g., alignment with final outcome/curator decision).
    function claimEvaluationReward(uint256 _proposalId)
        external
        onlyRegisteredParticipant
        proposalExists(_proposalId)
    {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.status == ProposalStatus.Completed || proposal.status == ProposalStatus.Failed, "Proposal not yet completed or failed");

        bool foundEvaluation = false;
        uint256 evalIndex = 0;
        for (uint256 i = 0; i < proposalEvaluations[_proposalId].length; i++) {
            if (proposalEvaluations[_proposalId][i].evaluator == msg.sender) {
                evalIndex = i;
                foundEvaluation = true;
                break;
            }
        }
        require(foundEvaluation, "No evaluation found from caller for this proposal");
        Evaluation storage eval = proposalEvaluations[_proposalId][evalIndex];

        require(eval.stakedAtBlock > 0, "No stake recorded for this evaluation");
        require(block.number >= eval.stakedAtBlock + EVALUATION_STAKE_PERIOD_BLOCKS, "Evaluation period not yet ended");
        require(!eval.rewardClaimed, "Reward already claimed for this evaluation");
        require(!eval.isDisputed || (eval.isDisputed && eval.disputeResolved), "Evaluation is under dispute or dispute unresolved");

        uint256 rewardAmount = 0;
        uint256 stakeToReturn = eval.stakeAmount;

        // Simplified reward logic:
        // If proposal succeeded and evaluator's score was high (aligned with success), they get a reward.
        // If proposal failed and evaluator's score was low (aligned with failure), they also get a reward.
        uint256 avgEvalScore = (eval.impactScore + eval.feasibilityScore) / 2;
        if (proposal.status == ProposalStatus.Completed && avgEvalScore >= proposal.evaluationAverageScore) {
            rewardAmount = (stakeToReturn * REWARD_MULTIPLIER_BPS) / 10000; // 10% reward on stake
            _updateReputation(msg.sender, 10);
        } else if (proposal.status == ProposalStatus.Failed && avgEvalScore < proposal.evaluationAverageScore) {
             rewardAmount = (stakeToReturn * REWARD_MULTIPLIER_BPS) / 20000; // 5% reward for "correctly" predicting failure
             _updateReputation(msg.sender, 5);
        } else {
             // Potentially slash stake for incorrect/malicious evaluation in a more advanced system.
             // For this example, just a reputation penalty.
             _updateReputation(msg.sender, -5);
        }

        eval.rewardClaimed = true;
        _transferToken(msg.sender, stakeToReturn + rewardAmount);
        emit EvaluationRewardClaimed(_proposalId, msg.sender, stakeToReturn + rewardAmount);
    }

    /// @notice Allows proposers to claim rewards for successfully implemented proposals.
    /// @param _proposalId The ID of the successful proposal.
    /// @dev Requires the proposal to be in 'Completed' status. The reward comes from the contract's AETHToken balance.
    function claimProposalSuccessReward(uint256 _proposalId)
        external
        onlyRegisteredParticipant
        proposalExists(_proposalId)
    {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.proposer == msg.sender, "Only the proposer can claim this reward");
        require(proposal.status == ProposalStatus.Completed, "Proposal is not yet completed");
        // Add a 'rewardClaimed' flag to Proposal struct in a production system to prevent double claims.

        uint256 rewardAmount = (proposal.estimatedCost * REWARD_MULTIPLIER_BPS) / 10000; // 10% of estimated cost as reward

        _transferToken(msg.sender, rewardAmount); // Transfer reward from this contract's AETHToken balance

        _updateReputation(msg.sender, 100); // Significant reputation boost

        emit ProposalSuccessRewardClaimed(_proposalId, msg.sender, rewardAmount);
    }

    /// @notice Queries the dynamically calculated fee for a specific transaction type.
    /// @param _transactionType The type of transaction for which to query the fee (mapped from enum to uint256).
    /// @return feeAmount The dynamically calculated fee in AETH tokens.
    /// @dev Fees can be adaptive based on factors like transaction type, participant reputation, and overall contract activity.
    function queryAdaptiveFee(uint256 _transactionType)
        external
        view
        returns (uint256 feeAmount)
    {
        // Example of adaptive fee logic:
        // - Base fee for different transaction types
        // - Modifier based on caller's reputation (lower for higher reputation)
        // - Modifier based on contract activity (e.g., number of active proposals/pools)

        uint256 baseFee;
        uint256 AETH_DECIMALS = 18; // Assuming AETH token has 18 decimals

        if (_transactionType == uint256(TransactionType.CreatePool)) {
            baseFee = 500 * (10 ** AETH_DECIMALS);
        } else if (_transactionType == uint256(TransactionType.SubmitProposal)) {
            baseFee = 50 * (10 ** AETH_DECIMALS);
        } else if (_transactionType == uint256(TransactionType.RefineIdea)) {
            baseFee = 10 * (10 ** AETH_DECIMALS);
        } else if (_transactionType == uint256(TransactionType.StakeEvaluation)) {
            baseFee = 1 * (10 ** AETH_DECIMALS); // Small network fee for staking interaction
        } else if (_transactionType == uint256(TransactionType.Dispute)) {
            baseFee = 200 * (10 ** AETH_DECIMALS); // Higher fee for disputes to deter frivolous ones
        } else {
            baseFee = 10 * (10 ** AETH_DECIMALS); // Default base fee
        }

        // Reputation-based adjustment (higher reputation = lower fee)
        if (participants[msg.sender].isRegistered) {
            uint256 reputation = participants[msg.sender].reputationScore;
            // Max 50% discount for very high reputation, min 0% discount.
            // Reputations up to 1000 give a max discount factor of 5000 (50%).
            uint256 discountFactor = reputation > 1000 ? 5000 : (reputation * 5); // 5000 bps = 50%
            feeAmount = (baseFee * (10000 - discountFactor)) / 10000;
        } else {
            feeAmount = baseFee; // No discount for unregistered or low reputation
        }

        // Add a minor factor for overall contract activity (e.g., total proposals)
        // This makes fees slightly increase with platform usage, creating a burn/value capture mechanism.
        feeAmount += (_proposalIds.current() / 100) * (10 ** (AETH_DECIMALS - 1)); // Small increase per 100 proposals (e.g., 0.1 AETH)

        return feeAmount;
    }

    // --- VI. Intellectual Property (IP) Management ---

    /// @notice Finalizes intellectual property ownership for a successful proposal.
    /// @param _proposalId The ID of the successful proposal.
    /// @param _owner The address of the final IP owner (can be a multisig or DAO).
    /// @param _royaltyShareBasisPoints Royalty percentage (e.g., 500 for 5%) for the pool/contributors (conceptual).
    /// @param _ownershipDurationBlocks Number of blocks for which ownership is valid (0 for perpetual).
    /// @dev This typically happens after a proposal is completed and validated. Only a pool curator can finalize IP.
    function finalizeIPOwnership(
        uint256 _proposalId,
        address _owner,
        uint256 _royaltyShareBasisPoints,
        uint256 _ownershipDurationBlocks
    ) external onlyPoolCurator(proposals[_proposalId].poolId) proposalExists(_proposalId) {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.status == ProposalStatus.Completed, "Proposal must be completed to finalize IP");
        require(_owner != address(0), "IP owner address cannot be zero");
        require(_royaltyShareBasisPoints <= 10000, "Royalty share cannot exceed 100% (10000 bps)");

        uint256 ipId = proposal.id; // Use proposal ID as IP ID for direct linkage

        require(ipOwnerships[ipId].proposalId == 0, "IP ownership already finalized for this proposal");

        ipOwnerships[ipId] = IPOwnership({
            id: ipId,
            proposalId: _proposalId,
            owner: _owner,
            royaltyShareBasisPoints: _royaltyShareBasisPoints,
            ownershipDurationBlocks: _ownershipDurationBlocks,
            finalizedAtBlock: block.number,
            isPublicDomain: false
        });

        proposal.ipOwnershipId = ipId; // Link the proposal to its IP record

        emit IPOwnershipFinalized(ipId, _proposalId, _owner, _royaltyShareBasisPoints);
    }

    /// @notice Allows the IP owner to release their intellectual property into the public domain.
    /// @param _proposalId The ID of the proposal whose IP is to be released.
    /// @dev Only the designated IP owner can call this function.
    function releaseIPPublicDomain(uint256 _proposalId)
        external
        proposalExists(_proposalId)
    {
        IPOwnership storage ip = ipOwnerships[_proposalId];
        require(ip.proposalId == _proposalId, "IP ownership not finalized for this proposal");
        require(ip.owner == msg.sender, "Only the IP owner can release to public domain");
        require(!ip.isPublicDomain, "IP is already in public domain");

        ip.isPublicDomain = true;

        emit IPReleasedToPublicDomain(ip.id, _proposalId);
    }

    // --- VIII. View Functions (Essential getters for contract state) ---
    // These functions allow external parties to query the contract's state without altering it.

    function getParticipant(address _participantAddress)
        public
        view
        returns (
            bool isRegistered,
            string memory username,
            uint256 reputationScore,
            string[] memory skillsList // Returns an array of claimed skills
        )
    {
        Participant storage p = participants[_participantAddress];
        uint256 skillCount = 0;
        // Count skills (iterating mapping values directly is not possible)
        // For a more efficient way, skills would need to be stored in an array as well.
        // For simplicity, we create a placeholder, a real system might pre-cache this or require off-chain iteration.
        // For now, let's return an empty array if not registered, or a simplified list.
        if (!p.isRegistered) {
            return (false, "", 0, new string[](0));
        }

        // To return skills efficiently, a dynamic array would be better managed during updates.
        // For a mapping-only structure, it's not directly iterable. This is a common Solidity limitation.
        // A placeholder for the return:
        return (p.isRegistered, p.username, p.reputationScore, new string[](0));
        // A more advanced solution would involve tracking skill strings in a dynamic array
        // alongside the mapping for efficient retrieval.
    }

    function getInnovationPool(uint256 _poolId)
        public
        view
        poolExists(_poolId)
        returns (
            string memory name,
            string memory description,
            uint256 targetFundingAmount,
            uint256 currentFunding,
            address[] memory curatorList,
            bool isOpen,
            uint256 createdAt
        )
    {
        InnovationPool storage pool = innovationPools[_poolId];
        return (pool.name, pool.description, pool.targetFundingAmount, pool.currentFunding, pool.curatorList, pool.isOpen, pool.createdAt);
    }

    function getProposal(uint256 _proposalId)
        public
        view
        proposalExists(_proposalId)
        returns (
            uint256 id,
            uint256 poolId,
            address proposer,
            string memory description,
            uint256 estimatedCost,
            uint256 estimatedImpactScore,
            uint256 currentFundingAllocated,
            ProposalStatus status,
            uint256 submittedAt,
            uint256 evaluationAverageScore,
            uint256 totalEvaluators,
            uint256 ipOwnershipId
        )
    {
        Proposal storage proposal = proposals[_proposalId];
        return (
            proposal.id,
            proposal.poolId,
            proposal.proposer,
            proposal.description,
            proposal.estimatedCost,
            proposal.estimatedImpactScore,
            proposal.currentFundingAllocated,
            proposal.status,
            proposal.submittedAt,
            proposal.evaluationAverageScore,
            proposal.totalEvaluators,
            proposal.ipOwnershipId
        );
    }

    function getGenerativeIdeaDraft(uint256 _ideaId)
        public
        view
        generativeIdeaExists(_ideaId)
        returns (
            uint256 id,
            uint256 poolId,
            address proposer,
            string memory initialKeywords,
            string memory generatedContentTemplate,
            uint256 refinementCount,
            uint256 createdAt
        )
    {
        GenerativeIdeaDraft storage draft = generativeIdeaDrafts[_ideaId];
        return (
            draft.id,
            draft.poolId,
            draft.proposer,
            draft.initialKeywords,
            draft.generatedContentTemplate,
            draft.refinementCount,
            draft.createdAt
        );
    }

    function getIPOwnership(uint256 _proposalId)
        public
        view
        returns (
            uint256 id,
            uint256 proposalId,
            address owner,
            uint256 royaltyShareBasisPoints,
            uint256 ownershipDurationBlocks,
            uint256 finalizedAtBlock,
            bool isPublicDomain
        )
    {
        IPOwnership storage ip = ipOwnerships[_proposalId];
        require(ip.proposalId == _proposalId, "IP ownership not finalized for this proposal");
        return (
            ip.id,
            ip.proposalId,
            ip.owner,
            ip.royaltyShareBasisPoints,
            ip.ownershipDurationBlocks,
            ip.finalizedAtBlock,
            ip.isPublicDomain
        );
    }
}
```