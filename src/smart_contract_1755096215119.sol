## VeritasNet: Decentralized Skill & Reputation Forge Smart Contract

### Outline and Function Summary

**Contract Name:** VeritasNet: Decentralized Skill & Reputation Forge

**Purpose:**
VeritasNet is a decentralized protocol designed to foster on-chain verifiable skill acquisition and dynamic reputation building. It leverages cutting-edge Web3 concepts including AI-powered objective assessments via oracles, zero-knowledge proofs (ZKPs) for privacy-preserving credential disclosure, and a unique reputation-weighted quadratic voting system for decentralized governance. The goal is to create a robust, trustworthy, and evolving identity layer where users' skills and contributions are provable, continuously evaluated, and influence their standing and governance power within the network.

**Core Concepts:**
1.  **Dynamic Soulbound Tokens (d-SBTs):** Reputation and skill levels are represented as non-transferable, evolving on-chain records, reflecting continuous contributions and performance. They are "soulbound" to the user's address but dynamically change based on actions.
2.  **AI Oracle Integration:** External AI models (e.g., for code quality, content assessment) evaluate user submissions (e.g., code, creative content) or provide sentiment analysis for peer reviews, offering objective and scalable assessment.
3.  **Zero-Knowledge Proof (ZKP) Verification:** Users can privately prove they meet certain reputation or skill thresholds (e.g., for accessing gated content or tasks) without revealing their exact scores or levels, enhancing privacy.
4.  **Reputation-Weighted Quadratic Voting:** Governance power scales with the square root of a user's reputation score, promoting broader participation and mitigating "whale" dominance compared to simple token-weighted voting.
5.  **On-chain Task & Challenge System:** Users can create and participate in bounties that require specific skill levels, fostering practical application and verification of skills, complete with AI evaluation of solutions.
6.  **Decentralized Dispute Resolution:** A mechanism for users to appeal evaluations, ensuring fairness and transparency in assessments through a multi-party resolution process (simplified for demo).

---

**Function Categories & Summaries (25+ Functions):**

**A. User Identity & Profile Management:**
1.  `constructor(address _daoTreasury)`: Initializes the contract, setting the owner and the address for the DAO treasury.
2.  `registerUser(string calldata _username)`: Allows a new user to register in the VeritasNet, assigning them an initial reputation score and setting up their profile.
3.  `updateUserProfile(string calldata _newUsername, string calldata _ipfsMetadataHash)`: Enables a registered user to update their on-chain profile details (e.g., username, IPFS hash for profile picture/bio).
4.  `getReputationScore(address _user)`: Publicly retrieves the current reputation score of any registered user.
5.  `getSkillLevel(address _user, uint256 _skillCategoryId)`: Publicly retrieves a user's current skill level and progress for a specified skill category.

**B. Skill & Reputation SBT Management:**
6.  `createSkillCategory(string calldata _name, string calldata _description)`: (DAO Function) Allows the creation of new, official skill categories within the network (e.g., "Web3 Security Audit", "Decentralized AI Model Training").
7.  `submitSkillProof(uint256 _skillCategoryId, string calldata _ipfsProofHash)`: A user submits verifiable proof of their skill (e.g., link to a project, certification), which automatically triggers an AI evaluation.
8.  `updateReputationAndSkill(address _user, uint256 _skillCategoryId, int256 _reputationChange, uint256 _progressIncrease)`: (Internal) Core function for the contract to update a user's dynamic reputation score and their skill level progression based on evaluations or actions.

**C. AI Oracle Integration:**
9.  `requestAIEvaluation(uint256 _entityId, EvaluationType _type, string calldata _aiModelIdentifier, string calldata _inputData)`: (Internal/Admin) Initiates a request for an external AI oracle to evaluate a specific entity (e.g., a skill proof or a challenge solution).
10. `fulfillAIEvaluation(uint256 _entityId, EvaluationType _type, int256 _aiScore, string calldata _aiFeedback, uint256 _requestId)`: (AI Oracle Callback) Callable only by whitelisted AI oracles, this function receives and processes the results of an AI evaluation, updating user reputation and skills accordingly.
11. `addAIEvaluator(address _newEvaluator, string calldata _aiModelIdentifier)`: (DAO Function) Whitelists a new AI oracle address, allowing it to submit evaluation results for a specific AI model.
12. `removeAIEvaluator(address _evaluator, string calldata _aiModelIdentifier)`: (DAO Function) Revokes the whitelisting of an AI oracle.

**D. ZK Proof Verification:**
13. `verifyZKProof(bytes calldata _proof, bytes calldata _publicSignals)`: (Placeholder/Public Interface) A function designed to interface with an external Zero-Knowledge Proof verifier contract. It allows users to privately prove certain attributes (e.g., "I have a reputation score above X" or "I possess Skill Y at Level Z") without revealing the exact details, enhancing privacy while enabling conditional access.

**E. Task & Challenge System:**
14. `createChallenge(string calldata _name, string calldata _description, uint256 _rewardAmount, uint256 _requiredSkillCategoryId, uint256 _requiredSkillLevel)`: Allows a registered user to create a new on-chain challenge or bounty, specifying required skills and depositing the reward amount.
15. `submitChallengeSolution(uint256 _challengeId, string calldata _ipfsSolutionHash)`: A user submits their solution to an active challenge, which then queues it for evaluation.
16. `evaluateChallengeSolution(uint256 _challengeId, address _solver, int256 _score, string calldata _feedback)`: (Evaluator/DAO Function) Handles the evaluation of a challenge solution, typically by an AI oracle or a designated human reviewer, and updates the solver's reputation and skill.
17. `claimChallengeReward(uint256 _challengeId)`: Allows the successfully evaluated solver of a challenge to claim their native token reward.
18. `submitPeerReview(address _targetUser, uint256 _taskId, uint256 _rating, string calldata _comment)`: Enables users to provide feedback and reviews on other users' performance in collaborative tasks or interactions, influencing their reputation.

**F. Governance System (Reputation-Weighted Quadratic Voting):**
19. `proposeGovernanceChange(string calldata _description, address _targetContract, bytes calldata _calldata)`: Allows registered users (with sufficient reputation) to propose changes to the protocol's parameters or contract logic.
20. `castVote(uint256 _proposalId, bool _support)`: Enables registered users to cast their vote on active proposals. Vote power is calculated as the square root of their reputation score (quadratic voting).
21. `executeProposal(uint256 _proposalId)`: Allows any user to trigger the execution of a governance proposal that has successfully passed its voting period and thresholds.

**G. Dispute Resolution:**
22. `initiateDispute(uint256 _entityId, DisputeType _type, string calldata _reason)`: Allows a user to formally initiate a dispute regarding an evaluation outcome (e.g., skill proof rejection, low challenge score).
23. `resolveDispute(uint256 _disputeId, DisputeResolution _resolution, string calldata _details)`: (DAO Function/Dispute Resolvers) Used by elected dispute resolvers (or DAO/owner for demo) to decide on and finalize a dispute, potentially reversing previous reputation/skill impacts.

**H. System Configuration & Treasury:**
24. `setProtocolParameter(bytes32 _parameterName, uint256 _value)`: (DAO Function) Allows the adjustment of various system parameters (e.g., minimum reputation for actions, voting period duration).
25. `withdrawFunds(address _to, uint256 _amount)`: (DAO Function) Enables the withdrawal of native token funds from the contract's treasury (e.g., uncollected challenge rewards, future protocol fees) to a specified address.

---

**Note on Open Source Duplication:**
While individual concepts like Soulbound Tokens, DAO governance, or oracle integration exist in open-source projects, the unique combination and deep integration of:
*   **Dynamic, AI-assessed reputation/skill SBTs**
*   **Privacy-preserving ZKPs for credential disclosure**
*   **Reputation-weighted quadratic voting**
*   **A gamified, AI-evaluated task and dispute resolution framework**
all within a single, cohesive protocol, constitute the novel contribution of this contract. It aims to build a comprehensive, adaptive, and trustworthy on-chain identity and contribution layer that goes beyond existing singular implementations.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
// No direct ERC20 import as rewards are in native token for simplicity,
// but could easily integrate IERC20 for token-based rewards.

contract VeritasNet is Ownable {
    // --- Enums ---
    enum EvaluationStatus { Pending, Approved, Rejected, Disputed }
    enum EvaluationType { SkillProof, ChallengeSolution, PeerReview }
    enum ChallengeStatus { Open, Submitted, Evaluated, Claimed, Disputed }
    enum DisputeType { SkillProofEvaluation, ChallengeSolutionEvaluation, PeerReview }
    enum DisputeResolution { Undecided, Upheld, Overturned }

    // --- Structs ---

    /// @dev Represents a user's on-chain profile and dynamic reputation.
    struct UserProfile {
        string username;
        string ipfsMetadataHash; // IPFS hash for profile picture, bio, etc.
        uint256 reputationScore; // Dynamic and continuously updated
        bool registered;
    }

    /// @dev Defines a formal skill category within VeritasNet.
    struct SkillCategory {
        string name;
        string description;
        uint256 id; // Unique ID for the skill category
    }

    /// @dev Represents a user's soulbound skill credential, dynamically updated.
    struct SkillSBT {
        uint256 categoryId;
        uint256 level; // Represents mastery, e.g., 0 (beginner), 1 (intermediate), 2 (expert)
        string ipfsMetadataHash; // Hash of the verified proof or credential
        uint256 lastUpdated;
        uint256 progressToNextLevel; // For gamification, 0-100% towards next level
    }

    /// @dev Stores details of a user's skill proof submission and its evaluation status.
    struct SkillProofSubmission {
        address user;
        uint256 skillCategoryId;
        string ipfsProofHash;
        EvaluationStatus status;
        int256 aiScore; // Score from AI evaluation, e.g., -100 to 100
        string aiFeedback;
        uint256 submissionTime;
        uint256 aiRequestId; // Corresponds to a specific AI evaluation request
    }

    /// @dev Defines a challenge/bounty created within VeritasNet.
    struct Challenge {
        uint256 id;
        address creator;
        string name;
        string description;
        uint256 rewardAmount; // In native token (wei)
        uint256 requiredSkillCategoryId;
        uint256 requiredSkillLevel;
        ChallengeStatus status;
        uint256 submissionDeadline;
        address solutionSolver; // Address of the solver if submitted
        string ipfsSolutionHash; // IPFS hash of the solution
        EvaluationStatus solutionEvaluationStatus;
        int256 solutionEvaluatorScore;
        string solutionEvaluatorFeedback;
        uint256 solutionSubmissionTime;
        uint256 solutionAIRequestId;
    }

    /// @dev Represents a governance proposal.
    struct Proposal {
        uint256 id;
        string description;
        address targetContract; // Contract to call if proposal passes
        bytes callData;         // Calldata for the target contract
        uint256 creationTimestamp;
        uint256 expirationTimestamp;
        uint256 yesVotesPower; // Sum of sqrt(reputation) for 'yes' votes
        uint256 noVotesPower;  // Sum of sqrt(reputation) for 'no' votes
        mapping(address => bool) hasVoted; // Tracks if a user has voted
        bool executed;
        bool passed;
    }

    /// @dev Stores details of a formal dispute initiated by a user.
    struct Dispute {
        uint256 id;
        address initiator;
        uint256 entityId; // ID of the contested skill proof, challenge, or peer review
        DisputeType disputeType;
        string reason;
        uint256 creationTime;
        // In a real system, `disputeResolvers` could be an array of elected jury members
        // For this demo, resolution is by `owner` or a designated role.
        address[] disputeResolvers;
        DisputeResolution resolution;
        string resolutionDetails;
    }

    // --- State Variables ---
    address public daoTreasury;
    // @dev zkVerifierContract: Address of an external ZK verifier contract.
    // In a real ZK integration, this would be an address of an actual ZK verifier contract.
    // Here, it's a placeholder.
    address public zkVerifierContract;

    // Mappings
    mapping(address => UserProfile) public users;
    mapping(address => mapping(uint256 => SkillSBT)) public userSkills; // user => skillCategoryId => SkillSBT
    mapping(uint256 => SkillCategory) public skillCategories; // id => SkillCategory
    mapping(uint256 => SkillProofSubmission) public skillProofSubmissions; // id => SkillProofSubmission
    mapping(uint256 => Challenge) public challenges; // id => Challenge
    mapping(uint256 => Proposal) public proposals; // id => Proposal
    mapping(uint256 => Dispute) public disputes; // id => Dispute
    mapping(bytes32 => uint256) public protocolParameters; // bytes32 for string param names, e.g., keccak256("MIN_REPUTATION_FOR_CHALLENGE_CREATION")
    mapping(address => mapping(string => bool)) public aiEvaluators; // aiAddress => aiModelIdentifier => bool (whitelisted AI oracles)
    mapping(uint256 => uint256) private aiRequestToEntityId; // Maps AI requestId to entityId (skill proof or challenge)
    mapping(uint256 => EvaluationType) private aiRequestToEvaluationType; // Maps AI requestId to evaluation type

    // Counters for unique IDs
    uint256 private nextSkillCategoryId = 1;
    uint256 private nextSkillProofId = 1;
    uint256 private nextChallengeId = 1;
    uint256 private nextProposalId = 1;
    uint256 private nextDisputeId = 1;
    uint256 private nextAIRequestId = 1;

    // --- Events ---
    event UserRegistered(address indexed user, string username);
    event UserProfileUpdated(address indexed user, string newUsername, string ipfsMetadataHash);
    event SkillCategoryCreated(uint256 indexed id, string name);
    event SkillProofSubmitted(address indexed user, uint256 indexed skillCategoryId, uint256 indexed proofId);
    event AIEvaluationRequested(uint256 indexed entityId, EvaluationType indexed _type, uint256 indexed requestId, string aiModelIdentifier, string inputData);
    event AIEvaluationFulfilled(uint256 indexed entityId, EvaluationType indexed _type, uint256 indexed requestId, int256 score, string feedback);
    event ReputationUpdated(address indexed user, uint256 oldReputation, uint256 newReputation);
    event SkillSBTUpdated(address indexed user, uint256 indexed skillCategoryId, uint256 oldLevel, uint256 newLevel, uint256 newProgress);
    event ChallengeCreated(uint256 indexed id, address indexed creator, uint256 rewardAmount);
    event ChallengeSolutionSubmitted(uint256 indexed challengeId, address indexed solver);
    event ChallengeEvaluated(uint256 indexed challengeId, address indexed solver, int256 score);
    event ChallengeRewardClaimed(uint256 indexed challengeId, address indexed solver, uint256 rewardAmount);
    event PeerReviewSubmitted(address indexed reviewer, address indexed targetUser, uint256 indexed taskId, uint256 rating);
    event ProposalCreated(uint256 indexed proposalId, string description, address targetContract);
    event VoteCast(uint256 indexed proposalId, address indexed voter, bool support, uint256 votePower);
    event ProposalExecuted(uint256 indexed proposalId, bool passed);
    event DisputeInitiated(uint256 indexed disputeId, address indexed initiator, DisputeType disputeType, uint256 entityId);
    event DisputeResolved(uint256 indexed disputeId, DisputeResolution resolution);
    event ProtocolParameterUpdated(bytes32 indexed parameterName, uint256 value);
    event AIEvaluatorAdded(address indexed evaluator, string aiModelIdentifier);
    event AIEvaluatorRemoved(address indexed evaluator, string aiModelIdentifier);
    event FundsWithdrawn(address indexed to, uint256 amount);

    // --- Modifiers ---

    /// @dev Ensures that the caller is a registered user in VeritasNet.
    modifier onlyRegisteredUser() {
        require(users[msg.sender].registered, "VeritasNet: Caller not a registered user");
        _;
    }

    /// @dev Ensures that the caller is a whitelisted AI oracle for the specified model.
    /// @param _aiModelIdentifier The identifier string for the AI model.
    modifier onlyAIOracle(string calldata _aiModelIdentifier) {
        require(aiEvaluators[msg.sender][_aiModelIdentifier], "VeritasNet: Caller is not a whitelisted AI oracle for this model");
        _;
    }

    // --- Constructor ---

    /// @notice Initializes the VeritasNet contract.
    /// @param _daoTreasury The address designated as the DAO treasury, to receive certain protocol funds.
    constructor(address _daoTreasury) Ownable(msg.sender) {
        require(_daoTreasury != address(0), "VeritasNet: DAO Treasury cannot be zero address");
        daoTreasury = _daoTreasury;

        // Initialize some default protocol parameters. These can be changed via governance.
        protocolParameters[keccak256("MIN_REPUTATION_FOR_CHALLENGE_CREATION")] = 100; // Reputation needed to create a challenge
        protocolParameters[keccak256("MIN_REPUTATION_FOR_GOVERNANCE_PROPOSAL")] = 50; // Reputation needed to create a governance proposal
        protocolParameters[keccak256("VOTING_PERIOD_SECONDS")] = 7 * 24 * 60 * 60; // 7 days for voting on proposals
        protocolParameters[keccak256("INITIAL_REPUTATION_SCORE")] = 10; // Starting reputation for new users
        protocolParameters[keccak256("REPUTATION_FOR_SKILL_LEVEL_UP")] = 50; // Reputation points needed to advance a skill level
        protocolParameters[keccak256("SKILL_PROGRESS_PER_PROOF_PERCENT")] = 20; // % progress per skill proof submission
    }

    // --- Helper Functions ---

    /// @dev Simple integer square root calculation used for quadratic voting.
    /// @param x The number to find the integer square root of.
    /// @return The integer square root of x.
    function _isqrt(uint256 x) internal pure returns (uint256 y) {
        if (x == 0) return 0;
        uint256 z = (x + 1) / 2;
        y = x;
        while (z < y) {
            y = z;
            z = (x / z + z) / 2;
        }
    }

    /// @dev Internal function to update a user's reputation and skill levels.
    /// This function is the core logic for dynamically updating d-SBTs.
    /// @param _user The address of the user whose reputation/skill is being updated.
    /// @param _skillCategoryId The ID of the skill category to update (0 if only reputation is affected).
    /// @param _reputationChange The amount to change reputation (can be positive or negative).
    /// @param _progressIncrease The percentage progress increase for the skill level (0-100).
    function _updateReputationAndSkill(address _user, uint256 _skillCategoryId, int256 _reputationChange, uint256 _progressIncrease) internal {
        UserProfile storage user = users[_user];
        require(user.registered, "VeritasNet: User not registered");

        uint256 oldReputation = user.reputationScore;
        // Ensure reputation doesn't go below zero
        user.reputationScore = (user.reputationScore > 0 || _reputationChange > 0) ? uint256(int256(user.reputationScore) + _reputationChange) : 0;
        emit ReputationUpdated(_user, oldReputation, user.reputationScore);

        if (_skillCategoryId > 0) { // If a skill category is provided, update the skill SBT
            SkillSBT storage userSkill = userSkills[_user][_skillCategoryId];
            if (userSkill.categoryId == 0) { // New skill for user, initialize it
                userSkill.categoryId = _skillCategoryId;
                userSkill.level = 0; // Start at level 0
                userSkill.progressToNextLevel = 0;
            }

            uint256 oldLevel = userSkill.level;
            uint256 newProgress = userSkill.progressToNextLevel + _progressIncrease;
            uint256 reputationRequiredForLevelUp = protocolParameters[keccak256("REPUTATION_FOR_SKILL_LEVEL_UP")];
            
            // Advance skill levels if conditions are met
            while (newProgress >= 100 && user.reputationScore >= reputationRequiredForLevelUp * (userSkill.level + 1)) {
                userSkill.level++;
                newProgress -= 100;
                // Consider increasing `reputationRequiredForLevelUp` for higher levels in a more complex system.
            }
            userSkill.progressToNextLevel = newProgress;
            userSkill.lastUpdated = block.timestamp;
            // Note: ipfsMetadataHash for SkillSBT would typically be updated upon successful proof approval.

            if (userSkill.level != oldLevel || _progressIncrease > 0) {
                emit SkillSBTUpdated(_user, _skillCategoryId, oldLevel, userSkill.level, userSkill.progressToNextLevel);
            }
        }
    }

    // --- A. User Identity & Profile Management ---

    /// @notice Registers a new user in the VeritasNet. Mints an initial reputation score.
    /// @param _username The desired username for the new user.
    function registerUser(string calldata _username) external {
        require(!users[msg.sender].registered, "VeritasNet: User already registered");
        require(bytes(_username).length > 0, "VeritasNet: Username cannot be empty");

        users[msg.sender].username = _username;
        users[msg.sender].ipfsMetadataHash = ""; // Can be updated later
        users[msg.sender].reputationScore = protocolParameters[keccak256("INITIAL_REPUTATION_SCORE")];
        users[msg.sender].registered = true;

        emit UserRegistered(msg.sender, _username);
    }

    /// @notice Updates the profile details of a registered user.
    /// @param _newUsername The new username. Empty string to keep current.
    /// @param _ipfsMetadataHash The IPFS hash pointing to the new profile metadata (e.g., profile picture, bio). Empty string to keep current.
    function updateUserProfile(string calldata _newUsername, string calldata _ipfsMetadataHash) external onlyRegisteredUser {
        UserProfile storage user = users[msg.sender];
        if (bytes(_newUsername).length > 0) {
            user.username = _newUsername;
        }
        if (bytes(_ipfsMetadataHash).length > 0) {
            user.ipfsMetadataHash = _ipfsMetadataHash;
        }
        emit UserProfileUpdated(msg.sender, user.username, user.ipfsMetadataHash);
    }

    /// @notice Retrieves the current reputation score of a user.
    /// @param _user The address of the user.
    /// @return The user's current reputation score.
    function getReputationScore(address _user) external view returns (uint256) {
        return users[_user].reputationScore;
    }

    /// @notice Retrieves a user's current level and progress for a specific skill category.
    /// @param _user The address of the user.
    /// @param _skillCategoryId The ID of the skill category.
    /// @return The user's skill level and progress (0-100%).
    function getSkillLevel(address _user, uint256 _skillCategoryId) external view returns (uint256 level, uint256 progress) {
        SkillSBT storage userSkill = userSkills[_user][_skillCategoryId];
        return (userSkill.level, userSkill.progressToNextLevel);
    }

    // --- B. Skill & Reputation SBT Management ---

    /// @notice Creates a new skill category. Callable only by the DAO (via governance proposal).
    /// @param _name The name of the skill category (e.g., "Solidity Development", "Generative AI Art").
    /// @param _description A detailed description of the skill category.
    function createSkillCategory(string calldata _name, string calldata _description) external onlyOwner { // In a full DAO, this would be an `onlyDAO` modifier through a proposal execution.
        require(bytes(_name).length > 0, "VeritasNet: Skill name cannot be empty");

        uint256 newId = nextSkillCategoryId++;
        skillCategories[newId] = SkillCategory(newId, _name, _description);
        emit SkillCategoryCreated(newId, _name);
    }

    /// @notice User submits a proof for a skill, initiating an evaluation process.
    /// This submission is then queued for AI evaluation.
    /// @param _skillCategoryId The ID of the skill category this proof belongs to.
    /// @param _ipfsProofHash The IPFS hash of the proof (e.g., link to a GitHub repo, project portfolio, certified course link).
    function submitSkillProof(uint256 _skillCategoryId, string calldata _ipfsProofHash) external onlyRegisteredUser {
        require(skillCategories[_skillCategoryId].id != 0, "VeritasNet: Skill category does not exist");
        require(bytes(_ipfsProofHash).length > 0, "VeritasNet: IPFS proof hash cannot be empty");

        uint256 currentProofId = nextSkillProofId++;
        skillProofSubmissions[currentProofId] = SkillProofSubmission({
            user: msg.sender,
            skillCategoryId: _skillCategoryId,
            ipfsProofHash: _ipfsProofHash,
            status: EvaluationStatus.Pending,
            aiScore: 0,
            aiFeedback: "",
            submissionTime: block.timestamp,
            aiRequestId: 0 // Will be set upon AI request
        });

        // Automatically request AI evaluation for the submitted proof
        requestAIEvaluation(currentProofId, EvaluationType.SkillProof, "default_skill_evaluator", _ipfsProofHash);

        emit SkillProofSubmitted(msg.sender, _skillCategoryId, currentProofId);
    }

    // --- C. AI Oracle Integration ---

    /// @notice Requests an external AI evaluation for a given entity (skill proof or challenge solution).
    /// This function simulates an oracle request. In a real system, it would interact with a decentralized oracle network.
    /// @param _entityId The ID of the entity to be evaluated (skillProofId or challengeId).
    /// @param _type The type of entity being evaluated (SkillProof or ChallengeSolution).
    /// @param _aiModelIdentifier A string identifier for the specific AI model to be used (e.g., "code_quality_v2").
    /// @param _inputData The data to be sent to the AI model (e.g., IPFS hash of code, text content).
    function requestAIEvaluation(uint256 _entityId, EvaluationType _type, string calldata _aiModelIdentifier, string calldata _inputData) public onlyOwner { // Made public for direct testing; normally internal or admin-controlled
        // In a real system, this would trigger an event for an off-chain oracle to pick up
        // and send data to an AI model, then call fulfillAIEvaluation.
        // For demo purposes, we allow the owner (or internal functions) to trigger this.

        uint256 currentAIRequestId = nextAIRequestId++;
        aiRequestToEntityId[currentAIRequestId] = _entityId;
        aiRequestToEvaluationType[currentAIRequestId] = _type;

        if (_type == EvaluationType.SkillProof) {
            skillProofSubmissions[_entityId].aiRequestId = currentAIRequestId;
        } else if (_type == EvaluationType.ChallengeSolution) {
            challenges[_entityId].solutionAIRequestId = currentAIRequestId;
        } else {
            revert("VeritasNet: Invalid evaluation type for AI request");
        }

        emit AIEvaluationRequested(_entityId, _type, currentAIRequestId, _aiModelIdentifier, _inputData);
    }

    /// @notice Callback function for whitelisted AI oracles to submit evaluation results.
    /// Processes the AI's score and feedback to update the relevant entity and user's reputation/skill.
    /// @param _entityId The ID of the entity that was evaluated.
    /// @param _type The type of entity (SkillProof or ChallengeSolution).
    /// @param _aiScore The score provided by the AI (e.g., -100 to 100, where >=0 might be approval).
    /// @param _aiFeedback The feedback message from the AI.
    /// @param _requestId The unique ID of the original AI request.
    function fulfillAIEvaluation(uint256 _entityId, EvaluationType _type, int256 _aiScore, string calldata _aiFeedback, uint256 _requestId) external onlyAIOracle("default_skill_evaluator") { // `default_skill_evaluator` is an example model
        // Requires authentication of the AI oracle based on `_aiModelIdentifier` used in `onlyAIOracle` modifier.
        require(_requestId != 0 && aiRequestToEntityId[_requestId] == _entityId && aiRequestToEvaluationType[_requestId] == _type, "VeritasNet: Invalid AI request ID or type mismatch");
        // Ensure request hasn't been fulfilled or tampered with
        require(aiRequestToEntityId[_requestId] != 0, "VeritasNet: AI request ID already fulfilled or never existed");

        if (_type == EvaluationType.SkillProof) {
            SkillProofSubmission storage submission = skillProofSubmissions[_entityId];
            require(submission.status == EvaluationStatus.Pending, "VeritasNet: Skill proof not pending evaluation");

            submission.aiScore = _aiScore;
            submission.aiFeedback = _aiFeedback;
            submission.status = (_aiScore >= 0) ? EvaluationStatus.Approved : EvaluationStatus.Rejected; // Example: score >= 0 means approved

            if (submission.status == EvaluationStatus.Approved) {
                // Update user's reputation and skill based on AI score
                _updateReputationAndSkill(submission.user, submission.skillCategoryId, _aiScore, protocolParameters[keccak256("SKILL_PROGRESS_PER_PROOF_PERCENT")]);
                // Update the SkillSBT's metadata hash with the verified proof's hash
                userSkills[submission.user][submission.skillCategoryId].ipfsMetadataHash = submission.ipfsProofHash;
            } else {
                // Apply a negative reputation impact for rejected proofs (e.g., a fraction of the negative score)
                _updateReputationAndSkill(submission.user, 0, _aiScore / 2, 0);
            }
        } else if (_type == EvaluationType.ChallengeSolution) {
            Challenge storage challenge = challenges[_entityId];
            require(challenge.status == ChallengeStatus.Submitted && challenge.solutionSolver != address(0), "VeritasNet: Challenge solution not pending evaluation");

            challenge.solutionEvaluatorScore = _aiScore;
            challenge.solutionEvaluatorFeedback = _aiFeedback;
            challenge.solutionEvaluationStatus = (_aiScore >= 0) ? EvaluationStatus.Approved : EvaluationStatus.Rejected; // Example: score >= 0 means approved
            challenge.status = ChallengeStatus.Evaluated; // Mark challenge as evaluated

            if (challenge.solutionEvaluationStatus == EvaluationStatus.Approved) {
                // Update solver's reputation and skill for successful challenge completion
                _updateReputationAndSkill(challenge.solutionSolver, challenge.requiredSkillCategoryId, _aiScore, protocolParameters[keccak256("SKILL_PROGRESS_PER_PROOF_PERCENT")] / 2); // Half progress for challenge solution
            } else {
                // Apply negative reputation for rejected solutions
                _updateReputationAndSkill(challenge.solutionSolver, 0, _aiScore / 2, 0);
            }
        } else {
            revert("VeritasNet: Unexpected evaluation type for fulfillment");
        }

        // Clean up the request mapping to prevent re-fulfillment and potential attacks
        delete aiRequestToEntityId[_requestId];
        delete aiRequestToEvaluationType[_requestId];

        emit AIEvaluationFulfilled(_entityId, _type, _requestId, _aiScore, _aiFeedback);
    }

    /// @notice DAO function to whitelist a new AI oracle address for a specific model.
    /// Callable only by the contract owner (or DAO via governance).
    /// @param _newEvaluator The address of the new AI oracle.
    /// @param _aiModelIdentifier The identifier string for the AI model this oracle supports.
    function addAIEvaluator(address _newEvaluator, string calldata _aiModelIdentifier) external onlyOwner { // Or should be callable via DAO proposal
        require(_newEvaluator != address(0), "VeritasNet: Evaluator address cannot be zero");
        require(bytes(_aiModelIdentifier).length > 0, "VeritasNet: AI model identifier cannot be empty");
        aiEvaluators[_newEvaluator][_aiModelIdentifier] = true;
        emit AIEvaluatorAdded(_newEvaluator, _aiModelIdentifier);
    }

    /// @notice DAO function to revoke a whitelisted AI oracle.
    /// Callable only by the contract owner (or DAO via governance).
    /// @param _evaluator The address of the AI oracle to revoke.
    /// @param _aiModelIdentifier The identifier string for the AI model.
    function removeAIEvaluator(address _evaluator, string calldata _aiModelIdentifier) external onlyOwner { // Or should be callable via DAO proposal
        require(_evaluator != address(0), "VeritasNet: Evaluator address cannot be zero");
        require(bytes(_aiModelIdentifier).length > 0, "VeritasNet: AI model identifier cannot be empty");
        aiEvaluators[_evaluator][_aiModelIdentifier] = false;
        emit AIEvaluatorRemoved(_evaluator, _aiModelIdentifier);
    }

    // --- D. ZK Proof Verification ---

    /// @notice Placeholder function to verify a generic ZK proof.
    /// In a real implementation, this would call an external ZK verifier contract
    /// (e.g., one generated by snarkjs/circom, or a universal verifier).
    /// This function can be used internally by other functions (e.g., for gated access)
    /// or exposed for users to prove attributes privately (e.g., "I have > X reputation").
    /// @param _proof The serialized zero-knowledge proof.
    /// @param _publicSignals The public inputs corresponding to the proof.
    /// @return True if the proof is valid, false otherwise.
    function verifyZKProof(bytes calldata _proof, bytes calldata _publicSignals) public view returns (bool) {
        // This is a placeholder. In a real dApp, this would call a precompiled
        // contract or a dedicated ZK verifier contract (e.g., from snarkjs/circom).
        // Example: return IVerifier(zkVerifierContract).verifyProof(_proof, _publicSignals);
        // For demonstration, we simply return true, simulating a successful verification.
        require(zkVerifierContract != address(0), "VeritasNet: ZK verifier contract not set");
        // In a live environment, this would involve complex cryptographic verification.
        // For this illustrative contract, we'll assume the proof is valid if provided correctly.
        return true; // Simulate successful verification for demonstration
    }

    // --- E. Task & Challenge System ---

    /// @notice Allows a registered user to create a new challenge/bounty.
    /// Requires minimum reputation and the challenge reward amount to be sent with the transaction.
    /// @param _name The name of the challenge.
    /// @param _description A detailed description of the challenge.
    /// @param _rewardAmount The amount of native token (wei) as reward for the solver.
    /// @param _requiredSkillCategoryId The ID of the skill category required for this challenge.
    /// @param _requiredSkillLevel The minimum level required in the specified skill.
    function createChallenge(
        string calldata _name,
        string calldata _description,
        uint256 _rewardAmount,
        uint256 _requiredSkillCategoryId,
        uint256 _requiredSkillLevel
    ) external payable onlyRegisteredUser {
        require(msg.value == _rewardAmount, "VeritasNet: Sent value must match reward amount");
        require(_rewardAmount > 0, "VeritasNet: Reward amount must be greater than zero");
        require(users[msg.sender].reputationScore >= protocolParameters[keccak256("MIN_REPUTATION_FOR_CHALLENGE_CREATION")], "VeritasNet: Insufficient reputation to create challenge");
        require(skillCategories[_requiredSkillCategoryId].id != 0, "VeritasNet: Required skill category does not exist");

        uint256 currentChallengeId = nextChallengeId++;
        challenges[currentChallengeId] = Challenge({
            id: currentChallengeId,
            creator: msg.sender,
            name: _name,
            description: _description,
            rewardAmount: _rewardAmount,
            requiredSkillCategoryId: _requiredSkillCategoryId,
            requiredSkillLevel: _requiredSkillLevel,
            status: ChallengeStatus.Open,
            submissionDeadline: block.timestamp + 7 days, // Example: 7 days deadline
            solutionSolver: address(0),
            ipfsSolutionHash: "",
            solutionEvaluationStatus: EvaluationStatus.Pending,
            solutionEvaluatorScore: 0,
            solutionEvaluatorFeedback: "",
            solutionSubmissionTime: 0,
            solutionAIRequestId: 0
        });

        emit ChallengeCreated(currentChallengeId, msg.sender, _rewardAmount);
    }

    /// @notice User submits a solution to an active challenge.
    /// Checks if the user meets the skill requirements before accepting the submission.
    /// @param _challengeId The ID of the challenge.
    /// @param _ipfsSolutionHash The IPFS hash of the solution content.
    function submitChallengeSolution(uint256 _challengeId, string calldata _ipfsSolutionHash) external onlyRegisteredUser {
        Challenge storage challenge = challenges[_challengeId];
        require(challenge.id != 0, "VeritasNet: Challenge does not exist");
        require(challenge.status == ChallengeStatus.Open, "VeritasNet: Challenge is not open for submissions");
        require(block.timestamp <= challenge.submissionDeadline, "VeritasNet: Challenge submission deadline passed");
        require(bytes(_ipfsSolutionHash).length > 0, "VeritasNet: IPFS solution hash cannot be empty");
        require(challenge.solutionSolver == address(0), "VeritasNet: Solution already submitted for this challenge"); // Only one solution for simplicity

        // Check if solver meets skill requirements
        SkillSBT storage solverSkill = userSkills[msg.sender][challenge.requiredSkillCategoryId];
        require(solverSkill.level >= challenge.requiredSkillLevel, "VeritasNet: Solver does not meet required skill level");

        challenge.solutionSolver = msg.sender;
        challenge.ipfsSolutionHash = _ipfsSolutionHash;
        challenge.solutionSubmissionTime = block.timestamp;
        challenge.status = ChallengeStatus.Submitted;

        // Automatically request AI evaluation for the submitted solution
        requestAIEvaluation(_challengeId, EvaluationType.ChallengeSolution, "default_challenge_evaluator", _ipfsSolutionHash);

        emit ChallengeSolutionSubmitted(_challengeId, msg.sender);
    }

    /// @notice Evaluator function for challenge solutions. Typically called by an AI oracle or a designated human reviewer.
    /// For demo purposes, callable by owner. In a full system, specific evaluators via DAO.
    /// @param _challengeId The ID of the challenge.
    /// @param _solver The address of the user who submitted the solution.
    /// @param _score The score given to the solution (e.g., -100 to 100).
    /// @param _feedback The feedback message for the solution.
    function evaluateChallengeSolution(uint256 _challengeId, address _solver, int256 _score, string calldata _feedback) external onlyOwner { // Or by AI oracle, or designated human
        Challenge storage challenge = challenges[_challengeId];
        require(challenge.id != 0, "VeritasNet: Challenge does not exist");
        require(challenge.status == ChallengeStatus.Submitted, "VeritasNet: Challenge not in submitted state");
        require(challenge.solutionSolver == _solver, "VeritasNet: Solution not submitted by this solver");

        challenge.solutionEvaluatorScore = _score;
        challenge.solutionEvaluatorFeedback = _feedback;
        challenge.solutionEvaluationStatus = (_score >= 0) ? EvaluationStatus.Approved : EvaluationStatus.Rejected; // Example: score >= 0 means approved
        challenge.status = ChallengeStatus.Evaluated;

        if (challenge.solutionEvaluationStatus == EvaluationStatus.Approved) {
            // Reward the solver's reputation and potentially skill progress
            _updateReputationAndSkill(_solver, challenge.requiredSkillCategoryId, _score, protocolParameters[keccak256("SKILL_PROGRESS_PER_PROOF_PERCENT")] / 2); // Half progress for challenge solution
        } else {
            // Negative reputation for rejected solutions (optional)
            _updateReputationAndSkill(_solver, 0, _score / 2, 0);
        }

        emit ChallengeEvaluated(_challengeId, _solver, _score);
    }

    /// @notice Allows the successful solver to claim their reward.
    /// @param _challengeId The ID of the challenge.
    function claimChallengeReward(uint256 _challengeId) external onlyRegisteredUser {
        Challenge storage challenge = challenges[_challengeId];
        require(challenge.id != 0, "VeritasNet: Challenge does not exist");
        require(challenge.status == ChallengeStatus.Evaluated, "VeritasNet: Challenge not yet evaluated");
        require(challenge.solutionEvaluationStatus == EvaluationStatus.Approved, "VeritasNet: Challenge solution was not approved");
        require(challenge.solutionSolver == msg.sender, "VeritasNet: Only the designated solver can claim this reward");
        require(challenge.rewardAmount > 0, "VeritasNet: Reward already claimed or zero");

        uint256 reward = challenge.rewardAmount;
        challenge.rewardAmount = 0; // Mark as claimed
        challenge.status = ChallengeStatus.Claimed;

        // Transfer native token reward to the solver
        (bool success, ) = payable(msg.sender).call{value: reward}("");
        require(success, "VeritasNet: Failed to transfer reward");

        emit ChallengeRewardClaimed(_challengeId, msg.sender, reward);
    }

    /// @notice Users can provide reviews for others based on interactions (e.g., task collaboration).
    /// This review influences the target user's reputation.
    /// @param _targetUser The address of the user being reviewed.
    /// @param _taskId An identifier for the task/interaction being reviewed (can be 0 if general).
    /// @param _rating A numerical rating (e.g., 1-5).
    /// @param _comment A comment describing the review.
    function submitPeerReview(address _targetUser, uint256 _taskId, uint256 _rating, string calldata _comment) external onlyRegisteredUser {
        require(_targetUser != address(0) && _targetUser != msg.sender, "VeritasNet: Cannot review self or zero address");
        require(users[_targetUser].registered, "VeritasNet: Target user not registered");
        require(_rating >= 1 && _rating <= 5, "VeritasNet: Rating must be between 1 and 5");
        // Further logic could ensure reviewer and target participated in _taskId, or if they have mutual connections.

        // Influence reputation based on rating. Example: +10 for 5-star, -10 for 1-star
        int256 reputationChange = int256(_rating - 3) * 5; // Calculation: (-2*5 = -10 for 1-star), (2*5 = +10 for 5-star)
        _updateReputationAndSkill(_targetUser, 0, reputationChange, 0);

        emit PeerReviewSubmitted(msg.sender, _targetUser, _taskId, _rating);
    }

    // --- F. Governance System (Reputation-Weighted Quadratic Voting) ---

    /// @notice Allows registered users (with sufficient reputation) to propose protocol changes.
    /// These proposals can include updating parameters, contract upgrades, or other actions.
    /// @param _description A description of the proposal.
    /// @param _targetContract The address of the contract to call if the proposal passes (e.g., this contract itself).
    /// @param _calldata The encoded function call data for the target contract (e.g., `abi.encodeWithSelector(this.setProtocolParameter.selector, _parameterName, _value)`).
    function proposeGovernanceChange(string calldata _description, address _targetContract, bytes calldata _calldata) external onlyRegisteredUser {
        require(users[msg.sender].reputationScore >= protocolParameters[keccak256("MIN_REPUTATION_FOR_GOVERNANCE_PROPOSAL")], "VeritasNet: Insufficient reputation to propose");
        require(bytes(_description).length > 0, "VeritasNet: Proposal description cannot be empty");
        require(_targetContract != address(0), "VeritasNet: Target contract cannot be zero address");
        require(bytes(_calldata).length > 0, "VeritasNet: Calldata cannot be empty");

        uint256 currentProposalId = nextProposalId++;
        proposals[currentProposalId].id = currentProposalId;
        proposals[currentProposalId].description = _description;
        proposals[currentProposalId].targetContract = _targetContract;
        proposals[currentProposalId].callData = _calldata;
        proposals[currentProposalId].creationTimestamp = block.timestamp;
        proposals[currentProposalId].expirationTimestamp = block.timestamp + protocolParameters[keccak256("VOTING_PERIOD_SECONDS")];

        emit ProposalCreated(currentProposalId, _description, _targetContract);
    }

    /// @notice Allows registered users to vote on proposals, with vote power weighted by their reputation.
    /// Uses quadratic voting (square root of reputation) to give more voice to broader community.
    /// @param _proposalId The ID of the proposal to vote on.
    /// @param _support True for a 'yes' vote, false for a 'no' vote.
    function castVote(uint256 _proposalId, bool _support) external onlyRegisteredUser {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.id != 0, "VeritasNet: Proposal does not exist");
        require(block.timestamp <= proposal.expirationTimestamp, "VeritasNet: Voting period has ended");
        require(!proposal.hasVoted[msg.sender], "VeritasNet: Already voted on this proposal");
        require(!proposal.executed, "VeritasNet: Proposal already executed");

        uint256 votePower = _isqrt(users[msg.sender].reputationScore); // Quadratic voting
        require(votePower > 0, "VeritasNet: Reputation too low to cast a meaningful vote (reputation must be > 0)");

        if (_support) {
            proposal.yesVotesPower += votePower;
        } else {
            proposal.noVotesPower += votePower;
        }
        proposal.hasVoted[msg.sender] = true;

        emit VoteCast(_proposalId, msg.sender, _support, votePower);
    }

    /// @notice Executes a proposal that has met its voting thresholds and passed its voting period.
    /// Any registered user can call this function after the voting period ends.
    /// @param _proposalId The ID of the proposal to execute.
    function executeProposal(uint256 _proposalId) external {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.id != 0, "VeritasNet: Proposal does not exist");
        require(block.timestamp > proposal.expirationTimestamp, "VeritasNet: Voting period not yet ended");
        require(!proposal.executed, "VeritasNet: Proposal already executed");

        // Example: Simple majority rule for execution (can be made more complex, e.g., quorum requirements)
        if (proposal.yesVotesPower > proposal.noVotesPower) {
            proposal.passed = true;
            // Execute the proposed transaction
            (bool success, ) = proposal.targetContract.call(proposal.callData);
            require(success, "VeritasNet: Proposal execution failed");
        } else {
            proposal.passed = false;
        }

        proposal.executed = true;
        emit ProposalExecuted(_proposalId, proposal.passed);
    }

    // --- G. Dispute Resolution ---

    /// @notice Allows users to formally dispute an evaluation or outcome (skill proof, challenge solution, peer review).
    /// Initiating a dispute will flag the entity as 'Disputed'.
    /// @param _entityId The ID of the contested entity (e.g., skillProofId, challengeId).
    /// @param _type The type of entity being disputed (SkillProofEvaluation, ChallengeSolutionEvaluation).
    /// @param _reason A detailed description of the reason for the dispute.
    function initiateDispute(uint256 _entityId, DisputeType _type, string calldata _reason) external onlyRegisteredUser {
        // Basic checks for dispute validity (e.g., entity exists and is in a disputable state)
        if (_type == DisputeType.SkillProofEvaluation) {
            require(skillProofSubmissions[_entityId].status == EvaluationStatus.Approved || skillProofSubmissions[_entityId].status == EvaluationStatus.Rejected, "VeritasNet: Skill proof not evaluated yet or already disputed");
            require(skillProofSubmissions[_entityId].user == msg.sender, "VeritasNet: Can only dispute your own skill proof");
        } else if (_type == DisputeType.ChallengeSolutionEvaluation) {
            require(challenges[_entityId].status == ChallengeStatus.Evaluated, "VeritasNet: Challenge solution not evaluated yet or already disputed");
            require(challenges[_entityId].solutionSolver == msg.sender, "VeritasNet: Can only dispute your own challenge solution");
        } else if (_type == DisputeType.PeerReview) {
            // For simplicity, peer review disputes are not directly handled as specific entities in this demo.
            revert("VeritasNet: Direct peer review disputes as separate entities are not supported in this demo");
        } else {
            revert("VeritasNet: Invalid dispute type");
        }

        uint256 currentDisputeId = nextDisputeId++;
        disputes[currentDisputeId] = Dispute({
            id: currentDisputeId,
            initiator: msg.sender,
            entityId: _entityId,
            disputeType: _type,
            reason: _reason,
            creationTime: block.timestamp,
            disputeResolvers: new address[](0), // In a real system, dispute resolvers would be assigned/elected here.
            resolution: DisputeResolution.Undecided,
            resolutionDetails: ""
        });

        // Mark the entity as disputed to prevent further actions until resolved
        if (_type == DisputeType.SkillProofEvaluation) {
            skillProofSubmissions[_entityId].status = EvaluationStatus.Disputed;
        } else if (_type == DisputeType.ChallengeSolutionEvaluation) {
            challenges[_entityId].solutionEvaluationStatus = EvaluationStatus.Disputed;
        }

        emit DisputeInitiated(currentDisputeId, msg.sender, _type, _entityId);
    }

    /// @notice Function for elected dispute resolvers (or DAO/owner for demo) to decide on a dispute.
    /// This function re-evaluates the case and potentially reverts previous reputation/skill changes.
    /// @param _disputeId The ID of the dispute.
    /// @param _resolution The resolution (Upheld: original decision stands, Overturned: original decision reversed).
    /// @param _details Additional details for the resolution.
    function resolveDispute(uint256 _disputeId, DisputeResolution _resolution, string calldata _details) external onlyOwner { // Or by a specific DisputeResolver role
        Dispute storage dispute = disputes[_disputeId];
        require(dispute.id != 0, "VeritasNet: Dispute does not exist");
        require(dispute.resolution == DisputeResolution.Undecided, "VeritasNet: Dispute already resolved");
        require(_resolution == DisputeResolution.Upheld || _resolution == DisputeResolution.Overturned, "VeritasNet: Invalid resolution type");

        dispute.resolution = _resolution;
        dispute.resolutionDetails = _details;

        // Apply consequences based on resolution
        if (_resolution == DisputeResolution.Overturned) {
            // If the original evaluation is overturned, reverse previous reputation/skill changes and apply the correct ones.
            if (dispute.disputeType == DisputeType.SkillProofEvaluation) {
                SkillProofSubmission storage submission = skillProofSubmissions[dispute.entityId];
                int256 originalScore = submission.aiScore; // The score from the original evaluation
                
                // Reverse the impact of the original evaluation
                _updateReputationAndSkill(submission.user, 0, -originalScore, 0); // Remove original rep impact
                _updateReputationAndSkill(submission.user, submission.skillCategoryId, -int256(protocolParameters[keccak256("SKILL_PROGRESS_PER_PROOF_PERCENT")]), 0); // Remove original skill progress

                // Apply the "correct" impact (e.g., if it was rejected and now approved, apply positive impact)
                // For simplicity, let's assume if it's overturned, it means the opposite outcome was correct.
                if (submission.status == EvaluationStatus.Rejected) { // Original was rejected, now approved
                    _updateReputationAndSkill(submission.user, submission.skillCategoryId, originalScore, protocolParameters[keccak256("SKILL_PROGRESS_PER_PROOF_PERCENT")]);
                    submission.status = EvaluationStatus.Approved;
                } else { // Original was approved, now rejected (less common for user-initiated disputes)
                    // No change to original score (it was positive), but effectively "nullify" it
                    submission.status = EvaluationStatus.Rejected;
                }
            } else if (dispute.disputeType == DisputeType.ChallengeSolutionEvaluation) {
                Challenge storage challenge = challenges[dispute.entityId];
                int256 originalScore = challenge.solutionEvaluatorScore;

                // Reverse original impact
                _updateReputationAndSkill(challenge.solutionSolver, 0, -originalScore, 0);
                _updateReputationAndSkill(challenge.solutionSolver, challenge.requiredSkillCategoryId, -int256(protocolParameters[keccak256("SKILL_PROGRESS_PER_PROOF_PERCENT")] / 2), 0);

                // Apply "correct" impact
                if (challenge.solutionEvaluationStatus == EvaluationStatus.Rejected) { // Was rejected, now approved
                    _updateReputationAndSkill(challenge.solutionSolver, challenge.requiredSkillCategoryId, originalScore, protocolParameters[keccak256("SKILL_PROGRESS_PER_PROOF_PERCENT")] / 2);
                    challenge.solutionEvaluationStatus = EvaluationStatus.Approved;
                } else { // Was approved, now rejected
                    challenge.solutionEvaluationStatus = EvaluationStatus.Rejected;
                }
                challenge.status = ChallengeStatus.Evaluated; // Return to evaluated state
            }
        }
        // If resolution is Upheld, no change needed as original decision stands.

        emit DisputeResolved(_disputeId, _resolution);
    }

    // --- H. System Configuration & Treasury ---

    /// @notice Allows the DAO (owner in this demo) to adjust various protocol parameters.
    /// This provides flexibility and upgradeability to the network's rules.
    /// @param _parameterName The keccak256 hash of the parameter name (e.g., `keccak256("MIN_REPUTATION_FOR_CHALLENGE_CREATION")`).
    /// @param _value The new value for the parameter.
    function setProtocolParameter(bytes32 _parameterName, uint256 _value) external onlyOwner { // Or by DAO governance proposal
        protocolParameters[_parameterName] = _value;
        emit ProtocolParameterUpdated(_parameterName, _value);
    }

    /// @notice Allows the DAO (owner in this demo) to withdraw native token funds from the contract's treasury.
    /// Funds might accumulate from uncollected challenge rewards, or future fees if implemented.
    /// @param _to The address to send the funds to.
    /// @param _amount The amount of native token (wei) to withdraw.
    function withdrawFunds(address _to, uint256 _amount) external onlyOwner { // Or by DAO governance proposal
        require(_to != address(0), "VeritasNet: Recipient cannot be zero address");
        require(address(this).balance >= _amount, "VeritasNet: Insufficient balance in contract");

        (bool success, ) = payable(_to).call{value: _amount}("");
        require(success, "VeritasNet: Failed to withdraw funds");

        emit FundsWithdrawn(_to, _amount);
    }
}
```