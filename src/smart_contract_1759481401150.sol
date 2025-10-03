Here is a smart contract in Solidity called `Aethelworks` that incorporates several advanced, creative, and trendy concepts: AI-validated tasks, dynamic Soulbound Tokens (SBTs) for multi-dimensional reputation, a "Curiosity Fund" for novel discoveries, and delegated authority. It aims to create a decentralized knowledge economy where contributions are recognized and rewarded based on merit and innovation.

---

### Contract: Aethelworks: A Decentralized Knowledge Economy

**Core Concepts:**

*   **Dynamic Soulbound Tokens (SBTs):** Non-transferable tokens (`AWSB`) representing a user's cumulative skills and reputation. Their metadata (e.g., visual traits) dynamically updates based on on-chain activity and evolving reputation scores.
*   **AI-Validated Tasks:** Tasks can be created with bounties, requiring external AI oracle validation for objective assessment of submissions. The smart contract defines the interface for AI oracle callbacks.
*   **Multi-Dimensional Reputation:** Users earn reputation scores across various dimensions (accuracy, novelty, timeliness, review credibility) which influence their ability to claim tasks, review others, and the evolution of their SBT.
*   **Curiosity Fund:** A special pool of funds that incentivizes users to propose and solve novel challenges, or make unprompted discoveries, rewarding based on "novelty" and "impact" scores derived from specialized evaluation (often by expert peer reviewers).
*   **Delegated Authority:** Users can delegate specific reputation-based powers (e.g., peer review voting) to another address without transferring their SBT, enabling flexible participation.

**Outline & Function Summary:**

The contract inherits from OpenZeppelin's `ERC721` (for SBTs), `Ownable` (for admin control), and `ReentrancyGuard` (for security).

**I. Admin & Configuration Functions:**
1.  `constructor(address _aiOracleAddress)`: Initializes the contract, sets the initial owner and the trusted AI oracle address.
2.  `setAIDomainOracle(address _newOracle)`: Allows the owner to update the address of the trusted AI validation oracle.
3.  `setPeerReviewers(address[] calldata _reviewers, bool _add)`: Allows the owner to add or remove addresses from the pool of trusted peer reviewers.

**II. User Profile & SBT Management Functions:**
4.  `registerProfile(string calldata _profileMetadataCID)`: Mints a new, non-transferable SkillBadge (SBT) for the caller, establishing their profile, initializing reputation, and linking to off-chain metadata.
5.  `updateProfileMetadata(string calldata _newProfileMetadataCID)`: Allows users to update the IPFS CID pointing to their off-chain profile details.
6.  `delegateReputationAuthority(address _delegatee, bool _allowDelegation)`: Allows a user to delegate specific reputation-based actions to another address.
7.  `getSkillBadgeMetadataURI(address _owner)`: Returns the dynamic metadata URI for a user's SkillBadge. This URI's content would evolve with the user's on-chain activity.
8.  `_updateSkillBadgeTraits(address _user)`: (Internal) Updates a user's SBT metadata URI, triggered by reputation changes or task completions.

**III. Task Management Functions (Proposer Side):**
9.  `proposeTask(string calldata _descriptionCID, uint256 _bounty, uint256 _deadline, string[] calldata _requiredSkillTags)`: Creates a new task, specifies its bounty, deadline, and required skills. Proposer must send the bounty along with the transaction.
10. `cancelTask(uint256 _taskId)`: Allows the proposer to cancel an open or unassigned task and reclaim the bounty.
11. `withdrawBounty(uint256 _taskId)`: Allows the proposer to withdraw bounty from a cancelled task if it hasn't been returned yet.

**IV. Task Management Functions (Solver Side):**
12. `claimTask(uint256 _taskId)`: A registered user claims an open task, provided they meet the (placeholder) skill requirements.
13. `submitTaskSolution(uint256 _taskId, string calldata _solutionCID)`: The assigned solver submits their solution by providing an IPFS CID.
14. `requestTaskReassignment(uint256 _taskId)`: Allows an assigned solver to request to drop a task, making it `Open` again.

**V. Task Validation & Review Functions:**
15. `initiateAIDomainValidation(uint256 _taskId, string calldata _aiPromptCID)`: Triggers the AI oracle for a submitted task, setting its status to `UnderAIValidation`.
16. `receiveAIDomainValidationResult(uint256 _taskId, uint256 _validationScore, string calldata _validationReportCID)`: Callback function, callable only by the `aiDomainOracle`, to report AI validation results.
17. `submitPeerReview(uint256 _taskId, uint256 _score, string calldata _commentCID)`: Allows a designated peer reviewer to submit their assessment for a task.
18. `resolveTask(uint256 _taskId)`: Finalizes a task based on AI validation and peer reviews, distributes the bounty, and updates the solver's and reviewers' reputations.

**VI. Curiosity Fund & Discovery Functions:**
19. `depositToCuriosityFund()`: Allows anyone to deposit native tokens into the general Curiosity Fund.
20. `withdrawFromCuriosityFund(address _to, uint256 _amount)`: (Admin only) Allows the owner to withdraw funds from the general Curiosity Fund (e.g., for grants or operational costs).
21. `proposeCuriosityChallenge(string calldata _challengeCID, uint256 _initialRewardPool, string[] calldata _discoveryTags)`: Users can propose novel challenges, providing an initial reward pool.
22. `submitCuriosityDiscovery(uint256 _challengeId, string calldata _discoveryCID)`: Submits a discovery for a specific challenge or as an unprompted contribution (if `_challengeId` is 0).
23. `initiateCuriosityDiscoveryEvaluation(uint256 _discoveryId)`: Triggers the evaluation process for a submitted discovery (by admin or reviewer).
24. `finalizeCuriosityDiscoveryEvaluation(uint256 _discoveryId, uint256 _noveltyScore, uint256 _impactScore)`: Callback, callable by designated peer reviewers, to record evaluation scores for a discovery.
25. `distributeCuriosityRewards(uint256 _challengeId)`: Distributes rewards from a Curiosity Challenge's pool to evaluated discoveries based on their novelty and impact scores.

**VII. View Functions:**
26. `getReputationScore(address _user)`: Returns the multi-dimensional reputation scores for a given user.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

// Custom errors for better UX and gas efficiency
error NotSkillBadgeOwner();
error NotAuthorizedReviewer();
error TaskNotFound(uint256 taskId);
error TaskAlreadyClaimed(uint256 taskId);
error TaskNotAssignedToCaller(uint256 taskId);
error TaskNotSubmitted(uint256 taskId);
error TaskAlreadyResolved(uint256 taskId);
error TaskNotOpen(uint256 taskId);
error TaskAlreadyCanceled(uint256 taskId);
error TaskClaimPeriodEnded(uint256 taskId);
error TaskDeadlinePassed(uint256 taskId);
error InsufficientReputation(address user, string skillTag); // Placeholder for future skill logic
error ChallengeNotFound(uint256 challengeId);
error DiscoveryNotFound(uint256 discoveryId);
error DiscoveryAlreadyEvaluated(uint256 discoveryId);
error NotAIGovernanceOracle();
error NotAdmin();
error NoFundsToDistribute();
error WithdrawalFailed();
error InvalidAmount();
error AlreadyHasSkillBadge();


/**
 * @title Aethelworks: A Decentralized Knowledge Economy
 * @dev Aethelworks is a smart contract platform for a decentralized knowledge economy,
 *      incentivizing skill development, task completion, and novel discovery. It leverages
 *      AI validation oracles, dynamic Soulbound Tokens (SBTs) for reputation, and a unique
 *      "Curiosity Fund" to foster innovation.
 *
 * @notice Core Concepts:
 * - **Dynamic Soulbound Tokens (SBTs):** Non-transferable tokens representing a user's cumulative skills and reputation.
 *   Their metadata (e.g., visual traits) dynamically updates based on on-chain activity and reputation scores.
 * - **AI-Validated Tasks:** Tasks can require external AI oracle validation for objective assessment of submissions.
 * - **Multi-Dimensional Reputation:** Users earn reputation scores across various dimensions (e.g., accuracy, novelty, timeliness)
 *   which influence their ability to claim tasks and the evolution of their SBT.
 * - **Curiosity Fund:** A special fund that incentivizes users to propose and solve novel challenges, or make unprompted
 *   discoveries, rewarding based on "novelty" and "impact" scores derived from specialized evaluation.
 * - **Delegated Authority:** Users can delegate specific reputation-based powers (e.g., peer review voting) to other addresses.
 *
 * @dev This contract extends ERC721 for SkillBadges, Ownable for administrative control,
 *      and ReentrancyGuard for security. It includes mechanisms for task proposing, claiming,
 *      submission, AI/peer review, and a unique reward system for innovative contributions.
 */
contract Aethelworks is ERC721, Ownable, ReentrancyGuard {
    using Counters for Counters.Counter;
    using Strings for uint256;

    /* ========== STATE VARIABLES ========== */

    // --- SkillBadges (SBTs) ---
    Counters.Counter private _skillBadgeIds; // Counter for SBT token IDs
    mapping(address => uint256) public userSkillBadgeTokenId; // Maps user address to their SBT tokenId

    // --- User Profiles & Reputation ---
    struct Reputation {
        uint256 accuracy; // Score for consistent, correct task completion
        uint256 novelty;  // Score for innovative solutions or discoveries
        uint256 timeliness; // Score for on-time task completion
        uint256 reviewCredibility; // Score for reliable peer reviews
    }
    mapping(address => Reputation) public userReputations;
    mapping(address => string) public userProfileMetadataCIDs; // IPFS CID for off-chain profile data
    mapping(address => address) public delegatedAuthority; // address => delegatee for reputation-based actions

    // --- Tasks ---
    enum TaskStatus {
        Open,
        Assigned,
        Submitted,
        UnderAIValidation,
        UnderPeerReview,
        Validated,
        Rejected,
        Canceled
    }

    struct Task {
        uint256 id;
        address proposer;
        address assignedTo;
        uint256 bounty; // In WEI (or native token)
        string descriptionCID; // IPFS CID for task description
        uint256 deadline; // Unix timestamp
        string[] requiredSkillTags; // Placeholder for future skill matching logic
        TaskStatus status;
        string submissionCID; // IPFS CID for solution submission
        uint256 aiValidationScore; // Score from AI oracle (0-100)
        string aiValidationReportCID; // IPFS CID for detailed AI report
        mapping(address => uint256) peerReviewScores; // reviewer => score (0-100)
        uint256 totalPeerReviewScore; // Sum of peer review scores
        uint256 peerReviewCount;
        uint256 validatedAt;
    }
    mapping(uint256 => Task) public tasks;
    Counters.Counter private _taskIds; // Counter for task IDs

    // --- Curiosity Fund & Challenges ---
    struct CuriosityChallenge {
        uint256 id;
        address proposer;
        string challengeCID; // IPFS CID for the challenge description
        uint256 rewardPool; // Funds specifically for this challenge
        string[] discoveryTags; // Tags for categorization
        uint256[] submittedDiscoveryIds; // List of discovery IDs submitted to this challenge
        bool active;
    }
    struct Discovery {
        uint256 id;
        uint256 challengeId; // 0 for unprompted discoveries
        address submitter;
        string discoveryCID; // IPFS CID for the discovery content
        uint256 noveltyScore; // Score from specialized evaluation (0-100)
        uint256 impactScore; // Score from specialized evaluation (0-100)
        bool evaluated;
        bool rewarded;
    }
    mapping(uint256 => CuriosityChallenge) public curiosityChallenges;
    mapping(uint256 => Discovery) public discoveries;
    Counters.Counter private _challengeIds; // Counter for challenge IDs
    Counters.Counter private _discoveryIds; // Counter for discovery IDs
    uint256 public curiosityFundBalance; // General pool for unprompted discoveries or admin use

    // --- Oracles & Reviewers ---
    address public aiDomainOracle; // Trusted address for AI validation callbacks
    mapping(address => bool) public isPeerReviewer; // Whitelisted addresses for manual peer review

    /* ========== EVENTS ========== */
    event SkillBadgeMinted(address indexed owner, uint256 tokenId, string profileMetadataCID);
    event ProfileMetadataUpdated(address indexed owner, string newProfileMetadataCID);
    event ReputationAuthorityDelegated(address indexed delegator, address indexed delegatee, bool allowed);

    event TaskProposed(uint256 indexed taskId, address indexed proposer, uint256 bounty, string descriptionCID);
    event TaskClaimed(uint256 indexed taskId, address indexed claimant);
    event TaskSolutionSubmitted(uint256 indexed taskId, address indexed submitter, string solutionCID);
    event TaskReassignmentRequested(uint256 indexed taskId, address indexed originalSolver);
    event TaskCanceled(uint256 indexed taskId);
    event AIValidationInitiated(uint256 indexed taskId, address indexed caller, string aiPromptCID);
    event AIValidationReceived(uint256 indexed taskId, uint256 score, string reportCID);
    event PeerReviewSubmitted(uint256 indexed taskId, address indexed reviewer, uint256 score, string commentCID);
    event TaskResolved(uint256 indexed taskId, address indexed winner, uint256 bountyAwarded, Reputation reputationGain);

    event CuriosityChallengeProposed(uint256 indexed challengeId, address indexed proposer, string challengeCID, uint256 rewardPool);
    event CuriosityDiscoverySubmitted(uint256 indexed discoveryId, uint256 indexed challengeId, address indexed submitter, string discoveryCID);
    event CuriosityDiscoveryEvaluationInitiated(uint256 indexed discoveryId);
    event CuriosityDiscoveryEvaluationFinalized(uint256 indexed discoveryId, uint256 noveltyScore, uint256 impactScore);
    event CuriosityRewardsDistributed(uint256 indexed challengeId, address[] indexed winners, uint256 totalDistributed);
    event CuriosityFundDeposited(address indexed depositor, uint256 amount);
    event CuriosityFundWithdrawn(address indexed recipient, uint256 amount);

    event AIDomainOracleUpdated(address indexed newOracle);
    event PeerReviewerStatusUpdated(address indexed reviewer, bool isNowReviewer);

    /* ========== MODIFIERS ========== */
    modifier onlyAIGovernanceOracle() {
        if (msg.sender != aiDomainOracle) revert NotAIGovernanceOracle();
        _;
    }
    modifier onlyPeerReviewer() {
        if (!isPeerReviewer[msg.sender]) revert NotAuthorizedReviewer();
        _;
    }
    modifier hasSkillBadge() {
        if (userSkillBadgeTokenId[msg.sender] == 0) revert AlreadyHasSkillBadge(); // Corrected: user has no SBT
        _;
    }

    /* ========== CONSTRUCTOR ========== */

    constructor(address _aiOracleAddress) ERC721("Aethelworks SkillBadge", "AWSB") Ownable(msg.sender) {
        if (_aiOracleAddress == address(0)) revert("Aethelworks: AI Oracle address cannot be zero.");
        aiDomainOracle = _aiOracleAddress;
        emit AIDomainOracleUpdated(_aiOracleAddress);
    }

    /* ========== CORE SBT (ERC721) FUNCTIONALITY - NON-TRANSFERABLE ========== */

    /**
     * @dev Overrides the internal _transfer function to prevent any transfers, making tokens Soulbound.
     *      SkillBadges are intended to be non-transferable representations of identity and reputation.
     */
    function _transfer(address from, address to, uint256 tokenId) internal pure override {
        revert NotSkillBadgeOwner(); // SkillBadges are non-transferable
    }

    /**
     * @dev Ensures SkillBadges cannot be approved for transfer.
     */
    function approve(address to, uint256 tokenId) public pure override {
        revert NotSkillBadgeOwner(); // SkillBadges cannot be approved
    }

    /**
     * @dev Ensures SkillBadges cannot be approved for all.
     */
    function setApprovalForAll(address operator, bool approved) public pure override {
        revert NotSkillBadgeOwner(); // SkillBadges cannot be approved for all
    }

    /**
     * @dev Ensures SkillBadges cannot be transferred via safeTransferFrom.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) public pure override {
        revert NotSkillBadgeOwner(); // SkillBadges are non-transferable
    }

    /**
     * @dev Ensures SkillBadges cannot be transferred via safeTransferFrom with data.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) public pure override {
        revert NotSkillBadgeOwner(); // SkillBadges are non-transferable
    }

    /**
     * @dev Ensures SkillBadges cannot be transferred via transferFrom.
     */
    function transferFrom(address from, address to, uint256 tokenId) public pure override {
        revert NotSkillBadgeOwner(); // SkillBadges are non-transferable
    }

    /* ========== ADMIN & CONFIGURATION FUNCTIONS ========== */

    /**
     * @notice Sets the address of the trusted AI Domain Oracle.
     * @dev Only callable by the contract owner.
     * @param _newOracle The new address for the AI oracle.
     */
    function setAIDomainOracle(address _newOracle) external onlyOwner {
        if (_newOracle == address(0)) revert("Aethelworks: New AI Oracle address cannot be zero.");
        aiDomainOracle = _newOracle;
        emit AIDomainOracleUpdated(_newOracle);
    }

    /**
     * @notice Manages the pool of peer reviewers.
     * @dev Only callable by the contract owner. Reviewers are crucial for manual validation and curiosity discovery evaluation.
     * @param _reviewers An array of addresses to add or remove.
     * @param _add True to add, false to remove.
     */
    function setPeerReviewers(address[] calldata _reviewers, bool _add) external onlyOwner {
        for (uint256 i = 0; i < _reviewers.length; i++) {
            isPeerReviewer[_reviewers[i]] = _add;
            emit PeerReviewerStatusUpdated(_reviewers[i], _add);
        }
    }

    /* ========== USER PROFILE & SBT MANAGEMENT FUNCTIONS ========== */

    /**
     * @notice Registers a new user profile by minting a unique, non-transferable SkillBadge (SBT).
     * @dev A user can only mint one SkillBadge.
     * @param _profileMetadataCID IPFS CID pointing to off-chain profile details (e.g., bio, portfolio).
     */
    function registerProfile(string calldata _profileMetadataCID) external nonReentrant {
        if (userSkillBadgeTokenId[msg.sender] != 0) { // Check if msg.sender already has an SBT
            revert AlreadyHasSkillBadge();
        }

        _skillBadgeIds.increment();
        uint256 tokenId = _skillBadgeIds.current();
        _safeMint(msg.sender, tokenId);
        userSkillBadgeTokenId[msg.sender] = tokenId; // Map user to their tokenId
        userProfileMetadataCIDs[msg.sender] = _profileMetadataCID;
        // Initialize reputation
        userReputations[msg.sender] = Reputation(0, 0, 0, 0);

        _updateSkillBadgeTraits(msg.sender); // Set initial metadata URI
        emit SkillBadgeMinted(msg.sender, tokenId, _profileMetadataCID);
    }

    /**
     * @notice Allows a user to update their off-chain profile metadata.
     * @param _newProfileMetadataCID The new IPFS CID for updated profile data.
     */
    function updateProfileMetadata(string calldata _newProfileMetadataCID) external hasSkillBadge {
        userProfileMetadataCIDs[msg.sender] = _newProfileMetadataCID;
        emit ProfileMetadataUpdated(msg.sender, _newProfileMetadataCID);
    }

    /**
     * @notice Allows a user to delegate their reputation-based authority (e.g., for peer review or voting)
     *         to another address without transferring their SkillBadge.
     * @param _delegatee The address to whom authority is delegated.
     * @param _allowDelegation True to allow delegation, false to revoke.
     */
    function delegateReputationAuthority(address _delegatee, bool _allowDelegation) external hasSkillBadge {
        if (_allowDelegation) {
            delegatedAuthority[msg.sender] = _delegatee;
        } else {
            delete delegatedAuthority[msg.sender];
        }
        emit ReputationAuthorityDelegated(msg.sender, _delegatee, _allowDelegation);
    }

    /**
     * @notice Retrieves the dynamic metadata URI for a user's SkillBadge.
     * @dev This URI typically points to a metadata JSON that can contain dynamic properties
     *      based on the user's current reputation and achievements. The actual metadata
     *      generation often happens off-chain by a service querying the contract's state.
     * @param _owner The address of the SkillBadge owner.
     * @return A string representing the metadata URI.
     */
    function getSkillBadgeMetadataURI(address _owner) public view returns (string memory) {
        uint256 tokenId = userSkillBadgeTokenId[_owner];
        if (tokenId == 0) return ""; // User doesn't own an SBT

        // In a real dApp, this would likely be an external service that queries
        // `userReputations[_owner]` and `userProfileMetadataCIDs[_owner]`
        // to generate a dynamic JSON based on the current state.
        // For simplicity, here we return a placeholder or a basic URI.
        return string(abi.encodePacked(
            "ipfs://", // or "https://api.aethelworks.com/sbt/",
            tokenId.toString(),
            "/metadata.json"
        ));
    }

    /**
     * @dev Internal function to update a user's SkillBadge metadata URI.
     *      Called whenever a user's reputation or achievements change.
     *      The actual metadata generation (e.g., IPFS hash for image traits) would
     *      typically be handled off-chain and then the URI set here.
     * @param _user The address of the user whose SkillBadge traits are to be updated.
     */
    function _updateSkillBadgeTraits(address _user) internal {
        uint256 tokenId = userSkillBadgeTokenId[_user];
        if (tokenId != 0) {
            _setTokenURI(tokenId, getSkillBadgeMetadataURI(_user));
        }
    }

    /* ========== TASK MANAGEMENT FUNCTIONS (PROPOSER) ========== */

    /**
     * @notice Proposes a new task to the network, attaching a bounty.
     * @param _descriptionCID IPFS CID for the task's detailed description.
     * @param _bounty Amount of native token (WEI) to be paid upon successful completion.
     * @param _deadline Unix timestamp by which the task must be completed.
     * @param _requiredSkillTags An array of skill tags required for solvers to claim this task. (Placeholder logic)
     */
    function proposeTask(
        string calldata _descriptionCID,
        uint256 _bounty,
        uint256 _deadline,
        string[] calldata _requiredSkillTags
    ) external payable nonReentrant hasSkillBadge {
        if (msg.value < _bounty) revert("Aethelworks: Insufficient bounty provided");
        if (_deadline <= block.timestamp + 1 days) revert("Aethelworks: Deadline must be at least 1 day in the future."); // Minimum deadline

        _taskIds.increment();
        uint256 taskId = _taskIds.current();
        tasks[taskId] = Task({
            id: taskId,
            proposer: msg.sender,
            assignedTo: address(0),
            bounty: _bounty,
            descriptionCID: _descriptionCID,
            deadline: _deadline,
            requiredSkillTags: _requiredSkillTags,
            status: TaskStatus.Open,
            submissionCID: "",
            aiValidationScore: 0,
            aiValidationReportCID: "",
            totalPeerReviewScore: 0,
            peerReviewCount: 0,
            validatedAt: 0
        });

        emit TaskProposed(taskId, msg.sender, _bounty, _descriptionCID);
    }

    /**
     * @notice Allows the task proposer to cancel an open or unassigned task.
     * @dev Returns the bounty to the proposer.
     * @param _taskId The ID of the task to cancel.
     */
    function cancelTask(uint256 _taskId) external nonReentrant {
        Task storage task = tasks[_taskId];
        if (task.id == 0) revert TaskNotFound(_taskId);
        if (task.proposer != msg.sender) revert("Aethelworks: Only proposer can cancel task");
        if (task.status != TaskStatus.Open && task.status != TaskStatus.Assigned) {
            revert TaskAlreadyResolved(_taskId);
        }
        if (task.status == TaskStatus.Canceled) {
            revert TaskAlreadyCanceled(_taskId);
        }

        task.status = TaskStatus.Canceled;
        if (task.bounty > 0) {
            (bool success, ) = payable(task.proposer).call{value: task.bounty}("");
            if (!success) revert WithdrawalFailed();
            task.bounty = 0; // Clear bounty after withdrawal
        }
        emit TaskCanceled(_taskId);
    }

    /**
     * @notice Proposer can withdraw bounty if task is cancelled and funds are still held.
     * @dev This is mainly for edge cases where `cancelTask` might fail to send funds immediately.
     * @param _taskId The ID of the task.
     */
    function withdrawBounty(uint256 _taskId) external nonReentrant {
        Task storage task = tasks[_taskId];
        if (task.id == 0) revert TaskNotFound(_taskId);
        if (task.proposer != msg.sender) revert("Aethelworks: Only proposer can withdraw bounty");
        if (task.status != TaskStatus.Canceled) revert("Aethelworks: Task must be canceled to withdraw bounty.");
        if (task.bounty == 0) revert NoFundsToDistribute();

        uint256 amount = task.bounty;
        task.bounty = 0;
        (bool success, ) = payable(task.proposer).call{value: amount}("");
        if (!success) revert WithdrawalFailed();
        emit CuriosityFundWithdrawn(task.proposer, amount); // Re-use event for now, could be a new event
    }

    /* ========== TASK MANAGEMENT FUNCTIONS (SOLVER) ========== */

    /**
     * @notice Allows a registered user to claim an open task.
     * @dev Requires the claimant to have a SkillBadge and meet the task's required skill tags (placeholder logic).
     * @param _taskId The ID of the task to claim.
     */
    function claimTask(uint256 _taskId) external nonReentrant hasSkillBadge {
        Task storage task = tasks[_taskId];
        if (task.id == 0) revert TaskNotFound(_taskId);
        if (task.status != TaskStatus.Open) revert TaskNotOpen(_taskId);
        if (task.deadline <= block.timestamp) revert TaskDeadlinePassed(_taskId);

        // Placeholder for skill requirement check:
        // In a real system, `userReputations[msg.sender]` would be checked against `task.requiredSkillTags`.
        // E.g., for (string memory skill : task.requiredSkillTags) { if (!hasMinSkill(msg.sender, skill)) revert InsufficientReputation(...) }

        task.assignedTo = msg.sender;
        task.status = TaskStatus.Assigned;
        emit TaskClaimed(_taskId, msg.sender);
    }

    /**
     * @notice Solver submits their solution to an assigned task.
     * @param _taskId The ID of the task.
     * @param _solutionCID IPFS CID for the submitted solution.
     */
    function submitTaskSolution(uint256 _taskId, string calldata _solutionCID) external nonReentrant {
        Task storage task = tasks[_taskId];
        if (task.id == 0) revert TaskNotFound(_taskId);
        if (task.assignedTo != msg.sender) revert TaskNotAssignedToCaller(_taskId);
        if (task.status != TaskStatus.Assigned) revert("Aethelworks: Task not in assigned status.");
        if (task.deadline <= block.timestamp) revert TaskDeadlinePassed(_taskId);

        task.submissionCID = _solutionCID;
        task.status = TaskStatus.Submitted;
        emit TaskSolutionSubmitted(_taskId, msg.sender, _solutionCID);
    }

    /**
     * @notice Allows an assigned solver to request reassignment of a task if they cannot complete it.
     * @dev The task reverts to `Open` status.
     * @param _taskId The ID of the task to reassign.
     */
    function requestTaskReassignment(uint256 _taskId) external nonReentrant {
        Task storage task = tasks[_taskId];
        if (task.id == 0) revert TaskNotFound(_taskId);
        if (task.assignedTo != msg.sender) revert TaskNotAssignedToCaller(_taskId);
        if (task.status != TaskStatus.Assigned) revert("Aethelworks: Task not in assigned status.");

        task.assignedTo = address(0);
        task.submissionCID = ""; // Clear any partial submission
        task.status = TaskStatus.Open;
        emit TaskReassignmentRequested(_taskId, msg.sender);
    }

    /* ========== TASK VALIDATION & REVIEW FUNCTIONS ========== */

    /**
     * @notice Initiates the AI validation process for a submitted task.
     * @dev Only the task proposer or contract owner can trigger this. The AI oracle will call back
     *      `receiveAIDomainValidationResult` with the outcome.
     * @param _taskId The ID of the task to validate.
     * @param _aiPromptCID IPFS CID for the specific AI prompt or validation parameters.
     */
    function initiateAIDomainValidation(uint256 _taskId, string calldata _aiPromptCID) external nonReentrant {
        Task storage task = tasks[_taskId];
        if (task.id == 0) revert TaskNotFound(_taskId);
        if (task.proposer != msg.sender && owner() != msg.sender) revert NotAdmin();
        if (task.status != TaskStatus.Submitted) revert TaskNotSubmitted(_taskId);

        task.status = TaskStatus.UnderAIValidation;
        // In a real scenario, this would trigger an off-chain Chainlink keeper or similar service
        // that interacts with the `aiDomainOracle` and then calls back.
        emit AIValidationInitiated(_taskId, msg.sender, _aiPromptCID);
    }

    /**
     * @notice Callback function for the AI Domain Oracle to report validation results.
     * @dev Only callable by the designated `aiDomainOracle` address.
     * @param _taskId The ID of the task that was validated.
     * @param _validationScore A score from 0-100 indicating the quality of the submission.
     * @param _validationReportCID IPFS CID for a detailed AI validation report.
     */
    function receiveAIDomainValidationResult(
        uint256 _taskId,
        uint256 _validationScore,
        string calldata _validationReportCID
    ) external onlyAIGovernanceOracle nonReentrant {
        Task storage task = tasks[_taskId];
        if (task.id == 0) revert TaskNotFound(_taskId);
        if (task.status != TaskStatus.UnderAIValidation) revert("Aethelworks: Task not awaiting AI validation.");
        if (_validationScore > 100) revert("Aethelworks: Validation score must be between 0-100.");

        task.aiValidationScore = _validationScore;
        task.aiValidationReportCID = _validationReportCID;
        task.status = TaskStatus.UnderPeerReview; // Transition to peer review after AI
        emit AIValidationReceived(_taskId, _validationScore, _validationReportCID);
    }

    /**
     * @notice Allows a designated peer reviewer to submit their assessment for a task.
     * @dev Reviews contribute to the final task resolution and reviewer's credibility score.
     * @param _taskId The ID of the task being reviewed.
     * @param _score A manual score from 0-100 given by the reviewer.
     * @param _commentCID IPFS CID for detailed review comments.
     */
    function submitPeerReview(uint256 _taskId, uint256 _score, string calldata _commentCID) external onlyPeerReviewer nonReentrant {
        Task storage task = tasks[_taskId];
        if (task.id == 0) revert TaskNotFound(_taskId);
        if (task.status != TaskStatus.UnderPeerReview) revert("Aethelworks: Task not in peer review status.");
        if (task.peerReviewScores[msg.sender] != 0) revert("Aethelworks: Reviewer already submitted a review.");
        if (_score > 100) revert("Aethelworks: Review score must be between 0-100.");

        task.peerReviewScores[msg.sender] = _score;
        task.totalPeerReviewScore += _score;
        task.peerReviewCount++;

        // Update reviewer's credibility (simple logic: higher score -> higher credibility)
        userReputations[msg.sender].reviewCredibility += _score / 10; // Scaled for reasonable growth
        _updateSkillBadgeTraits(msg.sender); // Update reviewer's SBT

        emit PeerReviewSubmitted(_taskId, msg.sender, _score, _commentCID);
    }

    /**
     * @notice Finalizes a task based on AI validation and peer reviews, distributes bounty, and updates reputations.
     * @dev Can be called by the task proposer or the contract owner after sufficient reviews.
     * @param _taskId The ID of the task to resolve.
     */
    function resolveTask(uint256 _taskId) external nonReentrant {
        Task storage task = tasks[_taskId];
        if (task.id == 0) revert TaskNotFound(_taskId);
        if (task.proposer != msg.sender && owner() != msg.sender) revert NotAdmin();
        if (task.status != TaskStatus.UnderPeerReview) revert("Aethelworks: Task not ready for resolution (needs reviews).");
        if (task.peerReviewCount < 1) revert("Aethelworks: Not enough peer reviews to resolve."); // Minimum 1 review

        // Calculate final score: weighted average of AI and peer reviews
        uint256 avgPeerScore = task.totalPeerReviewScore / task.peerReviewCount;
        uint256 finalScore = (task.aiValidationScore + avgPeerScore) / 2; // Simple average for now

        if (finalScore >= 70) { // Threshold for successful completion
            task.status = TaskStatus.Validated;
            task.validatedAt = block.timestamp;

            // Distribute bounty
            if (task.bounty > 0) {
                (bool success, ) = payable(task.assignedTo).call{value: task.bounty}("");
                if (!success) revert WithdrawalFailed();
            }

            // Update solver's reputation
            Reputation storage solverRep = userReputations[task.assignedTo];
            solverRep.accuracy += (finalScore / 10);
            if (block.timestamp <= task.deadline) { // Reward timeliness
                solverRep.timeliness += 5;
            }
            _updateSkillBadgeTraits(task.assignedTo);

            emit TaskResolved(_taskId, task.assignedTo, task.bounty, solverRep);
        } else {
            task.status = TaskStatus.Rejected;
            // Optionally, penalize solver's reputation for low-quality submission
            userReputations[task.assignedTo].accuracy = userReputations[task.assignedTo].accuracy > 5 ? userReputations[task.assignedTo].accuracy - 5 : 0;
            _updateSkillBadgeTraits(task.assignedTo);
            emit TaskResolved(_taskId, address(0), 0, userReputations[task.assignedTo]); // No winner, 0 bounty
        }
    }

    /* ========== CURIOSITY FUND & DISCOVERY FUNCTIONS ========== */

    /**
     * @notice Allows anyone to deposit native tokens into the general Curiosity Fund.
     * @dev These funds can be used for unprompted discoveries or admin-allocated rewards for novelty.
     */
    function depositToCuriosityFund() external payable nonReentrant {
        if (msg.value == 0) revert InvalidAmount();
        curiosityFundBalance += msg.value;
        emit CuriosityFundDeposited(msg.sender, msg.value);
    }

    /**
     * @notice Admin function to withdraw funds from the general Curiosity Fund.
     * @dev This could be for operational costs, directed grants, or returning unused funds.
     * @param _to The recipient address.
     * @param _amount The amount to withdraw.
     */
    function withdrawFromCuriosityFund(address _to, uint256 _amount) external onlyOwner nonReentrant {
        if (_amount == 0 || _amount > curiosityFundBalance) revert InvalidAmount();
        curiosityFundBalance -= _amount;
        (bool success, ) = payable(_to).call{value: _amount}("");
        if (!success) revert WithdrawalFailed();
        emit CuriosityFundWithdrawn(_to, _amount);
    }

    /**
     * @notice Proposes a new "Curiosity Challenge" with an initial reward pool.
     * @dev Challenges incentivize exploration and novel solutions in specific domains.
     * @param _challengeCID IPFS CID for the challenge description.
     * @param _initialRewardPool Initial funds contributed to this specific challenge.
     * @param _discoveryTags Categorization tags for the challenge.
     */
    function proposeCuriosityChallenge(
        string calldata _challengeCID,
        uint256 _initialRewardPool,
        string[] calldata _discoveryTags
    ) external payable nonReentrant hasSkillBadge {
        if (msg.value < _initialRewardPool) revert("Aethelworks: Insufficient initial reward pool provided");

        _challengeIds.increment();
        uint256 challengeId = _challengeIds.current();
        curiosityChallenges[challengeId] = CuriosityChallenge({
            id: challengeId,
            proposer: msg.sender,
            challengeCID: _challengeCID,
            rewardPool: _initialRewardPool,
            discoveryTags: _discoveryTags,
            submittedDiscoveryIds: new uint256[](0), // Initialize empty
            active: true
        });

        emit CuriosityChallengeProposed(challengeId, msg.sender, _challengeCID, _initialRewardPool);
    }

    /**
     * @notice Submits a discovery for a specific Curiosity Challenge or as an unprompted novel contribution.
     * @dev If `_challengeId` is 0, it's considered an unprompted discovery, evaluated for a share of the general Curiosity Fund.
     * @param _challengeId The ID of the Curiosity Challenge (0 for unprompted discovery).
     * @param _discoveryCID IPFS CID for the discovery content.
     */
    function submitCuriosityDiscovery(uint256 _challengeId, string calldata _discoveryCID) external nonReentrant hasSkillBadge {
        if (_challengeId != 0 && !curiosityChallenges[_challengeId].active) revert("Aethelworks: Challenge not active.");

        _discoveryIds.increment();
        uint256 discoveryId = _discoveryIds.current();
        discoveries[discoveryId] = Discovery({
            id: discoveryId,
            challengeId: _challengeId,
            submitter: msg.sender,
            discoveryCID: _discoveryCID,
            noveltyScore: 0,
            impactScore: 0,
            evaluated: false,
            rewarded: false
        });

        if (_challengeId != 0) {
            curiosityChallenges[_challengeId].submittedDiscoveryIds.push(discoveryId);
        }

        emit CuriosityDiscoverySubmitted(discoveryId, _challengeId, msg.sender, _discoveryCID);
    }

    /**
     * @notice Initiates the evaluation process for a submitted curiosity discovery.
     * @dev This would typically trigger specialized peer reviewers or advanced AI models.
     * @param _discoveryId The ID of the discovery to evaluate.
     */
    function initiateCuriosityDiscoveryEvaluation(uint256 _discoveryId) external nonReentrant {
        Discovery storage discovery = discoveries[_discoveryId];
        if (discovery.id == 0) revert DiscoveryNotFound(_discoveryId);
        if (discovery.evaluated) revert DiscoveryAlreadyEvaluated(_discoveryId);

        // Check for delegated authority or direct reviewer/owner status
        address caller = msg.sender;
        if (delegatedAuthority[caller] != address(0)) {
            caller = delegatedAuthority[caller]; // Use the delegatee for authority check
        }

        if (!isPeerReviewer[caller] && owner() != caller) revert NotAuthorizedReviewer();

        // In a real system, this would trigger an off-chain process
        emit CuriosityDiscoveryEvaluationInitiated(_discoveryId);
    }

    /**
     * @notice Callback to finalize the evaluation of a curiosity discovery.
     * @dev Only callable by authorized peer reviewers or a specialized oracle.
     * @param _discoveryId The ID of the discovery.
     * @param _noveltyScore Score (0-100) indicating the uniqueness/originality.
     * @param _impactScore Score (0-100) indicating potential real-world value.
     */
    function finalizeCuriosityDiscoveryEvaluation(
        uint256 _discoveryId,
        uint256 _noveltyScore,
        uint256 _impactScore
    ) external onlyPeerReviewer nonReentrant { // Assuming peer reviewers are responsible for this for now
        Discovery storage discovery = discoveries[_discoveryId];
        if (discovery.id == 0) revert DiscoveryNotFound(_discoveryId);
        if (discovery.evaluated) revert DiscoveryAlreadyEvaluated(_discoveryId);
        if (_noveltyScore > 100 || _impactScore > 100) revert("Aethelworks: Scores must be between 0-100.");

        discovery.noveltyScore = _noveltyScore;
        discovery.impactScore = _impactScore;
        discovery.evaluated = true;

        // Update submitter's reputation for novelty
        userReputations[discovery.submitter].novelty += (_noveltyScore + _impactScore) / 10;
        _updateSkillBadgeTraits(discovery.submitter);

        emit CuriosityDiscoveryEvaluationFinalized(_discoveryId, _noveltyScore, _impactScore);
    }

    /**
     * @notice Distributes rewards from a Curiosity Challenge's pool to evaluated discoveries.
     * @dev Distribution logic can be complex (e.g., quadratic funding, impact-weighted).
     *      For simplicity, it divides the pool among highly-rated discoveries.
     * @param _challengeId The ID of the Curiosity Challenge.
     */
    function distributeCuriosityRewards(uint256 _challengeId) external nonReentrant {
        CuriosityChallenge storage challenge = curiosityChallenges[_challengeId];
        if (challenge.id == 0) revert ChallengeNotFound(_challengeId);
        if (challenge.proposer != msg.sender && owner() != msg.sender) revert NotAdmin();
        if (challenge.rewardPool == 0) revert NoFundsToDistribute();

        uint256 totalScoreSum = 0;
        uint256[] memory eligibleDiscoveryIds = new uint256[](challenge.submittedDiscoveryIds.length);
        uint256 eligibleCount = 0;

        for (uint256 i = 0; i < challenge.submittedDiscoveryIds.length; i++) {
            Discovery storage d = discoveries[challenge.submittedDiscoveryIds[i]];
            if (d.evaluated && !d.rewarded) {
                if (d.noveltyScore >= 50 && d.impactScore >= 50) { // Only reward sufficiently good discoveries
                    totalScoreSum += (d.noveltyScore + d.impactScore);
                    eligibleDiscoveryIds[eligibleCount] = d.id;
                    eligibleCount++;
                }
            }
        }

        if (totalScoreSum == 0) {
            // No eligible discoveries, refund challenge pool to proposer or move to general fund
            (bool success, ) = payable(challenge.proposer).call{value: challenge.rewardPool}("");
            if (!success) revert WithdrawalFailed();
            challenge.rewardPool = 0;
            emit CuriosityRewardsDistributed(_challengeId, new address[](0), 0);
            challenge.active = false;
            return;
        }

        uint256 totalDistributed = 0;
        address[] memory winners = new address[](eligibleCount);
        for (uint256 i = 0; i < eligibleCount; i++) {
            Discovery storage d = discoveries[eligibleDiscoveryIds[i]];
            uint256 weightedScore = (d.noveltyScore + d.impactScore);
            uint256 rewardAmount = (challenge.rewardPool * weightedScore) / totalScoreSum;

            if (rewardAmount > 0) {
                (bool success, ) = payable(d.submitter).call{value: rewardAmount}("");
                if (success) {
                    d.rewarded = true;
                    totalDistributed += rewardAmount;
                    winners[i] = d.submitter;
                } else {
                    // Handle failed reward distribution, e.g., move to general fund or try again
                    curiosityFundBalance += rewardAmount; // Send failed distribution to general fund
                }
            }
        }
        
        // Any remaining funds in the challenge pool (due to rounding or prior failures) go to the general curiosity fund
        challenge.rewardPool -= totalDistributed; 
        if (challenge.rewardPool > 0) {
            curiosityFundBalance += challenge.rewardPool; 
            challenge.rewardPool = 0;
        }
        challenge.active = false; // Deactivate challenge after distribution
        emit CuriosityRewardsDistributed(_challengeId, winners, totalDistributed);
    }


    /* ========== VIEW FUNCTIONS ========== */

    /**
     * @notice Returns a user's multi-dimensional reputation scores.
     * @param _user The address of the user.
     * @return A Reputation struct containing accuracy, novelty, timeliness, and review credibility.
     */
    function getReputationScore(address _user) public view returns (Reputation memory) {
        return userReputations[_user];
    }
}

```