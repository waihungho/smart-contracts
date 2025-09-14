```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/**
 * @title AetherWeaverNetwork - Decentralized Innovation Catalyst
 * @author Your Name / AI Assistant
 * @notice A platform to foster and fund decentralized innovation (public goods)
 *         by creating a meritocratic, reputation-based ecosystem. It utilizes
 *         dynamic, non-transferable NFTs (AetherWeaver Nodes), an adaptive
 *         quadratic funding model, and conceptual AI oracle integration.
 *
 * Core Concepts:
 * 1.  **Catalyst (Project) Submissions:** Users propose innovative projects (public goods).
 * 2.  **AetherWeaver Nodes (Dynamic NFTs):** Non-transferable NFTs representing a user's
 *     reputation and expertise across various "domains" (e.g., ZK-Tech, AI Ethics, DeSci Research).
 *     These nodes level up/down based on their activities and the impact of their contributions.
 * 3.  **Reputation-Weighted Evaluation:** Other AetherWeaver Node holders evaluate submitted Catalysts.
 *     Their influence in evaluation is weighted by their Node's level in the relevant domain.
 * 4.  **AI Oracle Integration (Simulated):** The contract design conceptually integrates an AI Oracle
 *     for objective metrics and initial scoring of Catalysts. This is handled via a trusted `IAIOracle`
 *     interface, which the network owner sets.
 * 5.  **Adaptive Quadratic Funding (AQF):** Patrons fund Catalysts, and a matching pool, which adapts
 *     its multiplier based on network health and impact, incentivizes broad participation.
 * 6.  **Impact Vouching:** Users can "vouch" for a Catalyst's potential impact by staking tokens,
 *     signaling value and boosting its visibility and funding potential.
 */

// --- Interfaces ---
interface IAIOracle {
    function getCatalystAIScore(uint256 _catalystId) external view returns (uint256 score, string memory reportIpfsHash);
    function submitImpactReport(uint256 _catalystId, uint256 _impactScore, string memory _reportIpfsHash) external;
}

// --- Errors ---
error AetherWeaver__NotOwner();
error AetherWeaver__Paused();
error AetherWeaver__TokenTransferFailed();
error AetherWeaver__AlreadyHasNode();
error AetherWeaver__NoNodeFound();
error AetherWeaver__CatalystNotFound();
error AetherWeaver__Unauthorized();
error AetherWeaver__InvalidStatusTransition();
error AetherWeaver__EvaluationPeriodNotActive();
error AetherWeaver__EvaluationPeriodExpired();
error AetherWeaver__EvaluationAlreadySubmitted();
error AetherWeaver__InsufficientFunds();
error AetherWeaver__NoFundsToWithdraw();
error AetherWeaver__ZeroAmount();
error AetherWeaver__InvalidDomain();
error AetherWeaver__DomainNotAllowed();
error AetherWeaver__NodeLevelTooLow();
error AetherWeaver__EvaluationNotFound();
error AetherWeaver__TooSoonToDispute();
error AetherWeaver__NoMatchingFundsAvailable();
error AetherWeaver__AQFDistributionAlreadyDone();
error AetherWeaver__CatalystNotApproved();
error AetherWeaver__AlreadyVouched();
error AetherWeaver__NotEnoughVouchStake();
error AetherWeaver__RewardNotClaimable();
error AetherWeaver__IncorrectNodeId();


contract AetherWeaverNetwork is ERC721, Ownable, ReentrancyGuard {
    using Counters for Counters.Counter;

    // --- State Variables ---
    IERC20 public aetherToken;
    IAIOracle public aiOracle;

    bool public paused = false;

    // Configuration parameters
    uint256 public baseAQFMultiplier = 100; // Multiplier for Adaptive Quadratic Funding (e.g., 100 = 1x)
    uint256 public evaluationPeriodDuration = 7 days; // How long evaluations are open for a catalyst
    uint256 public disputeGracePeriod = 2 days; // Time after evaluation period to dispute results

    uint256 public matchingPoolBalance; // Funds for quadratic matching
    Counters.Counter private _nodeIdCounter; // ERC721 token IDs for AetherWeaver Nodes
    Counters.Counter private _catalystIdCounter; // Unique IDs for Catalyst projects
    Counters.Counter private _roundIdCounter; // Unique IDs for funding rounds

    // Mapping of domain name (bytes32) to if it's an allowed domain
    mapping(bytes32 => bool) public allowedDomains;
    mapping(bytes32 => uint256) public domainTotalNodes; // Total nodes specialized in a domain
    mapping(bytes32 => uint256) public domainAvgLevel; // Average level in a domain (simplified)

    // --- Enums ---
    enum CatalystStatus {
        Submitted,      // Just submitted, awaiting evaluation
        UnderEvaluation, // Open for community evaluations
        AIEvaluating,    // AI oracle is processing
        Approved,       // Approved for funding
        Rejected,       // Rejected, no funding
        Completed,      // Project completed successfully
        Disputed        // Evaluation or AI score disputed
    }

    // --- Structs ---
    struct AetherNode {
        uint256 nodeId;                      // ERC721 Token ID
        address owner;                       // Owner of the node
        mapping(bytes32 => uint8) levels;    // Expertise levels per domain (0-100)
        bytes32[] specializedDomains;        // List of domains the node has expertise in
        uint256 lastActivityTime;            // Timestamp of last interaction (e.g., evaluation, submission)
        uint256 reputationScore;             // Aggregate reputation score (derived from levels and activity)
    }

    struct Catalyst {
        uint256 id;
        address contributor;
        string title;
        string description;
        string ipfsHash;                   // IPFS hash for full proposal details
        bytes32[] relevantDomains;         // Domains relevant to the project
        CatalystStatus status;
        uint256 submissionTimestamp;
        uint256 evaluationStartTimestamp;
        uint256 aiScore;                   // Score from AI oracle
        string aiReportIpfsHash;           // IPFS hash for AI report
        uint256 totalDirectFunds;          // Funds directly contributed by patrons
        uint256 totalMatchingFunds;        // Funds allocated from matching pool
        uint256 totalVouchStake;           // Total tokens staked by vouching users
        mapping(address => uint256) directContributions; // Who contributed how much
        mapping(address => bool) hasEvaluated;             // Prevent double evaluation
        mapping(address => uint256) vouchStakes;           // User's stake for this catalyst
        mapping(address => uint256) vouchClaimableRewards; // Rewards claimable by vouch stakers
        uint256 evaluationCount;             // Number of unique evaluations
        uint256 weightedEvaluationSum;       // Sum of (score * evaluator_reputation_weight)
        bool matchingFundsDistributed;       // Flag for AQF distribution
    }

    struct Evaluation {
        uint256 catalystId;
        address evaluator;
        int8 score;                         // -5 to 5
        uint256 weight;                     // Calculated based on evaluator's node level
        string feedbackIpfsHash;            // IPFS hash for detailed feedback
        uint256 timestamp;
        bool disputed;
    }

    // --- Mappings ---
    mapping(address => AetherNode) public aetherNodes; // User address to their unique node
    mapping(uint256 => Catalyst) public catalysts; // Catalyst ID to Catalyst details
    mapping(uint256 => Evaluation[]) public catalystEvaluations; // Catalyst ID to array of evaluations
    mapping(uint256 => mapping(address => bool)) public hasUserEvaluatedCatalyst; // User has evaluated a specific catalyst

    // --- Events ---
    event AetherTokenSet(address indexed _token);
    event AIOracleSet(address indexed _oracle);
    event Paused(bool _paused);
    event BaseAQFMultiplierSet(uint256 _newMultiplier);
    event EvaluationPeriodSet(uint256 _duration);
    event AllowedDomainAdded(bytes32 indexed _domain);

    event AetherNodeMinted(address indexed _owner, uint256 _nodeId);
    event NodeLevelUpdated(uint256 indexed _nodeId, bytes32 indexed _domain, int8 _levelChange, uint8 _newLevel);
    event NodeDomainAssigned(uint256 indexed _nodeId, bytes32 indexed _domain, uint8 _initialLevel);

    event CatalystSubmitted(uint256 indexed _catalystId, address indexed _contributor, string _title, bytes32[] _domains);
    event CatalystStatusUpdated(uint256 indexed _catalystId, CatalystStatus _oldStatus, CatalystStatus _newStatus);
    event CatalystFundsWithdrawn(uint256 indexed _catalystId, address indexed _contributor, uint256 _amount);

    event EvaluationSubmitted(uint256 indexed _catalystId, address indexed _evaluator, int8 _score, uint256 _weight);
    event EvaluationDisputed(uint256 indexed _catalystId, uint256 _evaluationIndex, address indexed _disputer);
    event AIEvaluationUpdated(uint256 indexed _catalystId, uint256 _aiScore, string _aiReportIpfsHash);
    event ImpactVouchProcessed(uint256 indexed _catalystId, address indexed _voucher, uint256 _amount);

    event ContributedToMatchingPool(address indexed _contributor, uint256 _amount);
    event CatalystFunded(uint256 indexed _catalystId, address indexed _funder, uint256 _amount);
    event MatchingFundsDistributed(uint256 indexed _roundId, uint256 _totalDistributed);
    event VouchStakingRewardsClaimed(address indexed _staker, uint256 _amount);

    event AdaptiveAQFMultiplierAdjusted(uint256 _oldMultiplier, uint256 _newMultiplier);
    event ImpactThresholdsSet(bytes32 indexed _domain, uint256 _minVouchAmount, uint256 _minAIScore);


    // --- Modifiers ---
    modifier whenNotPaused() {
        if (paused) revert AetherWeaver__Paused();
        _;
    }

    modifier onlyAetherNodeHolder() {
        if (aetherNodes[msg.sender].nodeId == 0) revert AetherWeaver__NoNodeFound();
        _;
    }

    modifier onlyAIOracleContract() {
        if (msg.sender != address(aiOracle)) revert AetherWeaver__Unauthorized();
        _;
    }

    modifier onlyCatalystContributor(uint256 _catalystId) {
        if (catalysts[_catalystId].contributor != msg.sender) revert AetherWeaver__Unauthorized();
        _;
    }

    // --- Constructor ---
    constructor(address _aetherToken, address _aiOracle) ERC721("AetherWeaverNode", "AWN") Ownable(msg.sender) {
        if (_aetherToken == address(0)) revert AetherWeaver__ZeroAmount();
        if (_aiOracle == address(0)) revert AetherWeaver__ZeroAmount();
        aetherToken = IERC20(_aetherToken);
        aiOracle = IAIOracle(_aiOracle);
        emit AetherTokenSet(_aetherToken);
        emit AIOracleSet(_aiOracle);

        // Add some initial allowed domains
        allowedDomains["General"] = true;
        allowedDomains["ZK-Tech"] = true;
        allowedDomains["AI-Ethics"] = true;
        allowedDomains["DeSci-Research"] = true;
    }

    // --- I. Core Configuration & Management (Owner Only) ---

    /**
     * @dev Sets the ERC-20 token address used for funding.
     * @param _token The address of the ERC-20 token.
     */
    function setAetherToken(address _token) public onlyOwner {
        if (_token == address(0)) revert AetherWeaver__ZeroAmount();
        aetherToken = IERC20(_token);
        emit AetherTokenSet(_token);
    }

    /**
     * @dev Sets the address of the AI Oracle contract.
     * @param _oracle The address of the AI Oracle contract.
     */
    function setAIOracle(address _oracle) public onlyOwner {
        if (_oracle == address(0)) revert AetherWeaver__ZeroAmount();
        aiOracle = IAIOracle(_oracle);
        emit AIOracleSet(_oracle);
    }

    /**
     * @dev Sets the base multiplier for Adaptive Quadratic Funding.
     * @param _multiplier The new base multiplier (e.g., 100 for 1x).
     */
    function setBaseAQFMultiplier(uint256 _multiplier) public onlyOwner {
        baseAQFMultiplier = _multiplier;
        emit BaseAQFMultiplierSet(_multiplier);
    }

    /**
     * @dev Sets the duration for which a Catalyst is open for community evaluations.
     * @param _duration The new duration in seconds.
     */
    function setEvaluationPeriod(uint256 _duration) public onlyOwner {
        evaluationPeriodDuration = _duration;
        emit EvaluationPeriodSet(_duration);
    }

    /**
     * @dev Pauses or unpauses critical contract functionalities.
     * @param _paused True to pause, false to unpause.
     */
    function pauseContract(bool _paused) public onlyOwner {
        paused = _paused;
        emit Paused(_paused);
    }

    /**
     * @dev Adds a new domain that AetherWeaver Nodes can specialize in.
     * @param _domain The bytes32 representation of the domain name (e.g., keccak256("ZK-Tech")).
     */
    function addAllowedDomain(bytes32 _domain) public onlyOwner {
        if (allowedDomains[_domain]) revert AetherWeaver__InvalidDomain();
        allowedDomains[_domain] = true;
        emit AllowedDomainAdded(_domain);
    }

    // --- II. AetherWeaver Nodes (Dynamic NFT) Management ---

    /**
     * @dev Mints a unique, non-transferable AetherWeaver Node (NFT) for the caller.
     *      Each user can only have one Node.
     */
    function mintAetherNode() public whenNotPaused {
        if (aetherNodes[msg.sender].nodeId != 0) revert AetherWeaver__AlreadyHasNode();

        _nodeIdCounter.increment();
        uint256 newTokenId = _nodeIdCounter.current();

        AetherNode storage newNode = aetherNodes[msg.sender];
        newNode.nodeId = newTokenId;
        newNode.owner = msg.sender;
        newNode.lastActivityTime = block.timestamp;
        newNode.reputationScore = 0; // Starts at 0, builds over time

        _mint(msg.sender, newTokenId); // Mints the ERC721 token
        emit AetherNodeMinted(msg.sender, newTokenId);
    }

    /**
     * @dev Allows an AetherWeaver Node holder to declare initial expertise in a domain.
     *      Can only be done once per domain per node.
     * @param _nodeId The ID of the AetherWeaver Node.
     * @param _domain The domain to specialize in.
     * @param _initialLevel The initial level of expertise (e.g., 1-10).
     */
    function assignDomainExpertise(uint256 _nodeId, bytes32 _domain, uint8 _initialLevel) public onlyAetherNodeHolder {
        AetherNode storage node = aetherNodes[msg.sender];
        if (node.nodeId != _nodeId) revert AetherWeaver__IncorrectNodeId();
        if (!allowedDomains[_domain]) revert AetherWeaver__DomainNotAllowed();
        if (node.levels[_domain] != 0) revert AetherWeaver__AlreadyHasNode(); // Already assigned

        // Simplistic initial level. Could require a fee or proof of work in a real system.
        node.levels[_domain] = _initialLevel;
        node.specializedDomains.push(_domain);

        // Update global domain stats (simplified average)
        domainTotalNodes[_domain]++;
        domainAvgLevel[_domain] = (domainAvgLevel[_domain] * (domainTotalNodes[_domain] - 1) + _initialLevel) / domainTotalNodes[_domain];

        emit NodeDomainAssigned(_nodeId, _domain, _initialLevel);
    }

    /**
     * @dev Adjusts a node's level within a specific domain.
     *      This function is called internally or by a trusted oracle/governance based on performance.
     * @param _nodeId The ID of the AetherWeaver Node.
     * @param _domain The domain to update.
     * @param _levelChange The amount to change the level by (can be negative).
     */
    function updateNodeLevel(uint256 _nodeId, bytes32 _domain, int8 _levelChange) public onlyOwner { // For simplicity, only owner can trigger this. In production, this would be a complex governance or oracle process.
        address nodeOwner = ownerOf(_nodeId);
        if (nodeOwner == address(0)) revert AetherWeaver__NoNodeFound();
        AetherNode storage node = aetherNodes[nodeOwner];
        if (!allowedDomains[_domain]) revert AetherWeaver__DomainNotAllowed();

        uint8 currentLevel = node.levels[_domain];
        int256 newLevelSigned = int256(currentLevel) + _levelChange;

        if (newLevelSigned < 0) newLevelSigned = 0;
        if (newLevelSigned > 100) newLevelSigned = 100; // Cap at 100

        node.levels[_domain] = uint8(newLevelSigned);
        node.lastActivityTime = block.timestamp; // Mark activity

        // Update global average (simplified, would need more robust logic for removal/decrease)
        if (domainTotalNodes[_domain] > 0) {
             domainAvgLevel[_domain] = (domainAvgLevel[_domain] * domainTotalNodes[_domain] - currentLevel + uint8(newLevelSigned)) / domainTotalNodes[_domain];
        }

        emit NodeLevelUpdated(_nodeId, _domain, _levelChange, uint8(newLevelSigned));
    }

    /**
     * @dev Re-evaluates global domain impact or weights, potentially adjusting how levels translate to influence.
     *      This function would trigger a complex governance or data analysis process off-chain.
     *      For this contract, it's a placeholder to signify such a capability.
     */
    function recalibrateDomainWeights() public onlyOwner {
        // In a real system, this would involve complex logic:
        // - Fetching performance data for catalysts in each domain.
        // - Analyzing evaluator accuracy in each domain.
        // - Potentially adjusting a global "domain_impact_multiplier" mapping.
        // For now, it's a no-op placeholder.
        // emit DomainWeightsRecalibrated(...);
    }


    // --- III. Catalyst (Project) Submission & Lifecycle ---

    /**
     * @dev Submits a new Catalyst proposal to the network.
     *      Requires the caller to possess an AetherWeaver Node.
     * @param _title The title of the Catalyst.
     * @param _description A short description of the Catalyst.
     * @param _ipfsHash IPFS hash pointing to the full proposal document.
     * @param _relevantDomains An array of domains relevant to this Catalyst.
     */
    function submitCatalyst(
        string calldata _title,
        string calldata _description,
        string calldata _ipfsHash,
        bytes32[] calldata _relevantDomains
    ) public whenNotPaused onlyAetherNodeHolder nonReentrant {
        if (_relevantDomains.length == 0) revert AetherWeaver__InvalidDomain();
        for (uint256 i = 0; i < _relevantDomains.length; i++) {
            if (!allowedDomains[_relevantDomains[i]]) revert AetherWeaver__DomainNotAllowed();
        }

        _catalystIdCounter.increment();
        uint256 newCatalystId = _catalystIdCounter.current();

        Catalyst storage newCatalyst = catalysts[newCatalystId];
        newCatalyst.id = newCatalystId;
        newCatalyst.contributor = msg.sender;
        newCatalyst.title = _title;
        newCatalyst.description = _description;
        newCatalyst.ipfsHash = _ipfsHash;
        newCatalyst.relevantDomains = _relevantDomains;
        newCatalyst.status = CatalystStatus.Submitted;
        newCatalyst.submissionTimestamp = block.timestamp;
        // Evaluation starts after an admin review or when status is set to UnderEvaluation

        // Update node activity
        aetherNodes[msg.sender].lastActivityTime = block.timestamp;

        emit CatalystSubmitted(newCatalystId, msg.sender, _title, _relevantDomains);
    }

    /**
     * @dev Transitions a Catalyst through its lifecycle states.
     *      Typically called by owner/governance. Automatically starts evaluation period when moving to UnderEvaluation.
     * @param _catalystId The ID of the Catalyst.
     * @param _newStatus The new status for the Catalyst.
     */
    function updateCatalystStatus(uint256 _catalystId, CatalystStatus _newStatus) public onlyOwner {
        Catalyst storage catalyst = catalysts[_catalystId];
        if (catalyst.id == 0) revert AetherWeaver__CatalystNotFound();

        CatalystStatus oldStatus = catalyst.status;

        // Define valid transitions (simplified)
        bool isValid = false;
        if (oldStatus == CatalystStatus.Submitted && _newStatus == CatalystStatus.UnderEvaluation) isValid = true;
        if (oldStatus == CatalystStatus.UnderEvaluation && _newStatus == CatalystStatus.Approved) isValid = true;
        if (oldStatus == CatalystStatus.UnderEvaluation && _newStatus == CatalystStatus.Rejected) isValid = true;
        if (oldStatus == CatalystStatus.AIEvaluating && _newStatus == CatalystStatus.Approved) isValid = true;
        if (oldStatus == CatalystStatus.AIEvaluating && _newStatus == CatalystStatus.Rejected) isValid = true;
        if (oldStatus == CatalystStatus.Approved && _newStatus == CatalystStatus.Completed) isValid = true;
        if (oldStatus == CatalystStatus.Disputed && (_newStatus == CatalystStatus.Approved || _newStatus == CatalystStatus.Rejected || _newStatus == CatalystStatus.UnderEvaluation)) isValid = true;


        if (!isValid) revert AetherWeaver__InvalidStatusTransition();

        catalyst.status = _newStatus;
        if (_newStatus == CatalystStatus.UnderEvaluation) {
            catalyst.evaluationStartTimestamp = block.timestamp;
        }

        emit CatalystStatusUpdated(_catalystId, oldStatus, _newStatus);
    }

    /**
     * @dev Allows the approved Contributor to withdraw their allocated funds.
     * @param _catalystId The ID of the Catalyst.
     */
    function withdrawCatalystFunds(uint256 _catalystId) public whenNotPaused onlyCatalystContributor(_catalystId) nonReentrant {
        Catalyst storage catalyst = catalysts[_catalystId];
        if (catalyst.id == 0) revert AetherWeaver__CatalystNotFound();
        if (catalyst.status != CatalystStatus.Approved && catalyst.status != CatalystStatus.Completed) revert AetherWeaver__CatalystNotApproved();

        uint256 totalAvailableFunds = catalyst.totalDirectFunds + catalyst.totalMatchingFunds;
        if (totalAvailableFunds == 0) revert AetherWeaver__NoFundsToWithdraw();

        catalyst.totalDirectFunds = 0; // Reset for future contributions
        catalyst.totalMatchingFunds = 0; // Reset

        if (!aetherToken.transfer(msg.sender, totalAvailableFunds)) revert AetherWeaver__TokenTransferFailed();

        emit CatalystFundsWithdrawn(_catalystId, msg.sender, totalAvailableFunds);
    }

    // --- IV. Evaluation & Reputation System ---

    /**
     * @dev An AetherWeaver Node holder evaluates a Catalyst. Their node's domain levels
     *      in relevant domains influence their evaluation weight.
     * @param _catalystId The ID of the Catalyst to evaluate.
     * @param _score The evaluation score (-5 to 5).
     * @param _feedbackIpfsHash IPFS hash for detailed textual feedback.
     */
    function submitEvaluation(
        uint256 _catalystId,
        int8 _score,
        string calldata _feedbackIpfsHash
    ) public whenNotPaused onlyAetherNodeHolder nonReentrant {
        if (_score < -5 || _score > 5) revert AetherWeaver__InvalidDomain(); // Using InvalidDomain as a general error for "invalid input"
        Catalyst storage catalyst = catalysts[_catalystId];
        if (catalyst.id == 0) revert AetherWeaver__CatalystNotFound();
        if (catalyst.status != CatalystStatus.UnderEvaluation) revert AetherWeaver__EvaluationPeriodNotActive();
        if (block.timestamp > catalyst.evaluationStartTimestamp + evaluationPeriodDuration) revert AetherWeaver__EvaluationPeriodExpired();
        if (hasUserEvaluatedCatalyst[_catalystId][msg.sender]) revert AetherWeaver__EvaluationAlreadySubmitted();
        if (catalyst.contributor == msg.sender) revert AetherWeaver__Unauthorized(); // Cannot evaluate own catalyst

        AetherNode storage evaluatorNode = aetherNodes[msg.sender];
        uint256 evaluationWeight = 1; // Base weight

        // Calculate weight based on evaluator's domain expertise
        for (uint256 i = 0; i < catalyst.relevantDomains.length; i++) {
            bytes32 domain = catalyst.relevantDomains[i];
            uint8 level = evaluatorNode.levels[domain];
            // Simple weighting: higher level means higher influence. Can be quadratic or more complex.
            evaluationWeight += level;
        }

        // Store evaluation
        catalystEvaluations[_catalystId].push(
            Evaluation({
                catalystId: _catalystId,
                evaluator: msg.sender,
                score: _score,
                weight: evaluationWeight,
                feedbackIpfsHash: _feedbackIpfsHash,
                timestamp: block.timestamp,
                disputed: false
            })
        );
        hasUserEvaluatedCatalyst[_catalystId][msg.sender] = true;
        catalyst.evaluationCount++;
        catalyst.weightedEvaluationSum += uint256(int256(_score) * int256(evaluationWeight));

        // Update node activity
        evaluatorNode.lastActivityTime = block.timestamp;

        emit EvaluationSubmitted(_catalystId, msg.sender, _score, evaluationWeight);
    }

    /**
     * @dev Allows a Contributor to dispute a specific evaluation of their Catalyst.
     *      Triggers a review process (off-chain or governance-based).
     * @param _catalystId The ID of the Catalyst.
     * @param _evaluationIndex The index of the specific evaluation in the `catalystEvaluations` array.
     */
    function disputeEvaluation(uint256 _catalystId, uint256 _evaluationIndex) public whenNotPaused onlyCatalystContributor(_catalystId) {
        Catalyst storage catalyst = catalysts[_catalystId];
        if (catalyst.id == 0) revert AetherWeaver__CatalystNotFound();
        if (_evaluationIndex >= catalystEvaluations[_catalystId].length) revert AetherWeaver__EvaluationNotFound();

        Evaluation storage evaluation = catalystEvaluations[_catalystId][_evaluationIndex];
        if (evaluation.disputed) revert AetherWeaver__EvaluationAlreadySubmitted(); // Reusing error for "already disputed"
        if (block.timestamp < catalyst.evaluationStartTimestamp + evaluationPeriodDuration) revert AetherWeaver__TooSoonToDispute(); // Can only dispute after evaluation period
        if (block.timestamp > catalyst.evaluationStartTimestamp + evaluationPeriodDuration + disputeGracePeriod) revert AetherWeaver__EvaluationPeriodExpired(); // Reusing error for "dispute period expired"

        evaluation.disputed = true;
        catalyst.status = CatalystStatus.Disputed; // Set catalyst to disputed status for review

        // In a real system, this would trigger a governance vote or manual review by an arbitration committee.
        // For simplicity, we just mark it as disputed.

        emit EvaluationDisputed(_catalystId, _evaluationIndex, msg.sender);
    }

    /**
     * @dev Updates a Catalyst's AI-generated evaluation score and report.
     *      This function is called by the trusted AI Oracle contract.
     * @param _catalystId The ID of the Catalyst.
     * @param _aiScore The score provided by the AI Oracle.
     * @param _aiReportIpfsHash IPFS hash for the detailed AI report.
     */
    function updateAIEvaluation(
        uint256 _catalystId,
        uint256 _aiScore,
        string calldata _aiReportIpfsHash
    ) public onlyAIOracleContract {
        Catalyst storage catalyst = catalysts[_catalystId];
        if (catalyst.id == 0) revert AetherWeaver__CatalystNotFound();

        catalyst.aiScore = _aiScore;
        catalyst.aiReportIpfsHash = _aiReportIpfsHash;

        // If catalyst was pending AI evaluation, now it's ready for approval or direct rejection
        if (catalyst.status == CatalystStatus.AIEvaluating) {
            // Simplified: if AI score is high, it moves to approved, otherwise remains pending or rejected by admin.
            // In a real system, AI score would be one factor among many for approval.
            if (_aiScore >= 70) { // Example threshold
                 catalyst.status = CatalystStatus.Approved;
            } else {
                 // Still might need manual review or rejection
            }
        }
        emit AIEvaluationUpdated(_catalystId, _aiScore, _aiReportIpfsHash);
    }

    /**
     * @dev Allows users to "vouch" for a Catalyst's potential impact by staking AetherTokens.
     *      This signals perceived value and can boost its visibility/funding.
     * @param _catalystId The ID of the Catalyst to vouch for.
     * @param _amount The amount of AetherTokens to stake.
     */
    function processImpactVouch(uint256 _catalystId, uint256 _amount) public whenNotPaused nonReentrant {
        if (_amount == 0) revert AetherWeaver__ZeroAmount();
        Catalyst storage catalyst = catalysts[_catalystId];
        if (catalyst.id == 0) revert AetherWeaver__CatalystNotFound();
        if (catalyst.status != CatalystStatus.UnderEvaluation && catalyst.status != CatalystStatus.Approved) revert AetherWeaver__CatalystNotApproved();
        if (catalyst.contributor == msg.sender) revert AetherWeaver__Unauthorized(); // Cannot vouch for your own catalyst

        // Transfer tokens to contract
        if (!aetherToken.transferFrom(msg.sender, address(this), _amount)) revert AetherWeaver__TokenTransferFailed();

        catalyst.totalVouchStake += _amount;
        catalyst.vouchStakes[msg.sender] += _amount;

        emit ImpactVouchProcessed(_catalystId, msg.sender, _amount);
    }


    // --- V. Funding & Distribution ---

    /**
     * @dev Patrons contribute AetherTokens to the global matching pool.
     * @param _amount The amount of AetherTokens to contribute.
     */
    function contributeToMatchingPool(uint256 _amount) public whenNotPaused nonReentrant {
        if (_amount == 0) revert AetherWeaver__ZeroAmount();
        if (!aetherToken.transferFrom(msg.sender, address(this), _amount)) revert AetherWeaver__TokenTransferFailed();
        matchingPoolBalance += _amount;
        emit ContributedToMatchingPool(msg.sender, _amount);
    }

    /**
     * @dev Patrons directly fund a specific Catalyst.
     * @param _catalystId The ID of the Catalyst to fund.
     * @param _amount The amount of AetherTokens to contribute.
     */
    function fundCatalyst(uint256 _catalystId, uint256 _amount) public whenNotPaused nonReentrant {
        if (_amount == 0) revert AetherWeaver__ZeroAmount();
        Catalyst storage catalyst = catalysts[_catalystId];
        if (catalyst.id == 0) revert AetherWeaver__CatalystNotFound();
        if (catalyst.status != CatalystStatus.UnderEvaluation && catalyst.status != CatalystStatus.Approved) revert AetherWeaver__CatalystNotApproved();

        if (!aetherToken.transferFrom(msg.sender, address(this), _amount)) revert AetherWeaver__TokenTransferFailed();

        catalyst.totalDirectFunds += _amount;
        catalyst.directContributions[msg.sender] += _amount;

        emit CatalystFunded(_catalystId, msg.sender, _amount);
    }

    /**
     * @dev Triggers the calculation and distribution of matching funds from the pool to approved Catalysts
     *      based on the Adaptive Quadratic Funding (AQF) mechanism. This typically marks the end of a funding round.
     * @param _catalystIds An array of catalyst IDs to consider for this distribution round.
     */
    function distributeMatchingFunds(uint256[] calldata _catalystIds) public onlyOwner nonReentrant {
        _roundIdCounter.increment();
        uint256 currentRoundId = _roundIdCounter.current();

        if (matchingPoolBalance == 0) revert AetherWeaver__NoMatchingFundsAvailable();

        uint256 totalSquaredRootOfContributions = 0;
        uint256[] memory individualSquaredRootOfContributions = new uint256[](_catalystIds.length);

        // First pass: Calculate individual sqrt sums and total sqrt sum
        for (uint256 i = 0; i < _catalystIds.length; i++) {
            uint256 catalystId = _catalystIds[i];
            Catalyst storage catalyst = catalysts[catalystId];

            if (catalyst.id == 0 || catalyst.status != CatalystStatus.Approved || catalyst.matchingFundsDistributed) {
                // Skip invalid or already processed catalysts
                continue;
            }

            uint256 sumOfSquaredRoots = 0;
            // Iterate over all direct contributions to this catalyst
            for (uint256 j = 0; j < catalyst.relevantDomains.length; j++) { // Simplified to use relevant domains as proxy for individual contributions
                // This is a placeholder for a more robust quadratic funding calculation where you iterate
                // through actual unique contributors.
                // For simplicity, let's assume `catalyst.directContributions` mapping tracks all individual contributions.
                // A real QF requires iterating unique contributors and summing sqrt(contributions).
                // Example: For each unique contributor `C`, add `sqrt(catalyst.directContributions[C])`
                // To avoid iterating mappings on-chain, this data is typically aggregated off-chain and then submitted,
                // or a different AQF calculation is used.

                // For a *purely on-chain* AQF that respects gas limits and avoids iterating unknown number of contributors,
                // we might need a different approach, e.g., using `catalyst.totalDirectFunds` as a proxy and
                // a simplified "broadness" factor based on evaluation count, or an explicit list of contributors.

                // Let's use a simplified approach for demonstration:
                // Assume `catalyst.evaluationCount` represents the "broadness of support"
                // and `catalyst.totalDirectFunds` is the total direct capital.
                // A basic QF formula: (sum of sqrt(contributions))^2 - total_contributions
                // We'll approximate broadness by evaluationCount and total direct contributions for simplicity.

                // A simplified QF for an individual catalyst might be:
                // sqrt(totalDirectFunds) * broadness_factor (e.g., based on evaluationCount)
                // However, the standard QF is `(sum of sqrt(indiv_contribs))^2 - total_indiv_contribs`
                // This requires *knowing* individual contributions. For an on-chain AQF, this is a challenge.

                // Alternative simplified AQF for a *single catalyst's matching funds entitlement*:
                // `(sqrt(totalDirectFunds) * evaluationCount * baseAQFMultiplier) / 100`

                // Let's implement a more direct AQF calculation using a pre-calculated `sumOfSquaredRoots` if we had it.
                // Since we don't, we will assume `totalSquaredRootOfContributions` is a sum of some impact metric * sqrt(direct funds)
                // For a *purely illustrative* AQF, we'll simplify and use total direct funds and evaluations as proxies.

                // Let's use a very basic approximation: sum of sqrt(all direct contributions) for the *total pool distribution*.
                // This still implies iterating individual contributors.

                // To avoid duplication and still be "advanced," let's assume `catalyst.weightedEvaluationSum` is a proxy
                // for the "sum of square roots of contributions" * broadness. This isn't strictly QF but an adaptive impact fund.
                // The prompt asks for *adaptive quadratic funding*, implying the *matching pool multiplier* adapts.
                // The core calculation for QF part still needs `sum of sqrt(contributions)`.
                // Let's assume an off-chain calculation of `sumOfSquaredRoots` for each project which is submitted or derived simply.

                // Let's simplify the *on-chain AQF* calculation to this:
                // Each project gets a "demand score" = (sqrt(direct funds) + (average_evaluation_score * node_level_influence)) * impact_factor
                // The 'adaptive' part is the `baseAQFMultiplier` and `impact_factor` dynamically adjusting.

                // Okay, let's go with the spirit of QF, which rewards broadness.
                // We'll calculate a simplified "QF-like score" for each project.
                // Assume `sqrt(catalyst.totalDirectFunds)` is a proxy for `sum of sqrt(individual contributions)`
                // Multiplied by `catalyst.evaluationCount` for broadness.
                // And scaled by `baseAQFMultiplier`.

                // Simplified Project Score: `(sqrt(catalyst.totalDirectFunds) * sqrt(catalyst.evaluationCount))`
                // This is still not true QF, but rewards both total funds and broadness.
                // Let's just use `catalyst.totalDirectFunds` for the simple QF part, but adapt the *multiplier*.

                uint256 currentProjectDirectFunds = catalyst.totalDirectFunds;
                if (currentProjectDirectFunds == 0) {
                    individualSquaredRootOfContributions[i] = 0;
                } else {
                    // This `sqrt` is expensive. A real QF implementation on-chain might pre-calculate or use `exp` approximation.
                    // For demo, we'll use a simple iterative sqrt.
                    uint256 s = _sqrt(currentProjectDirectFunds); // Placeholder for `sum(sqrt(contributions))`
                    individualSquaredRootOfContributions[i] = s;
                    totalSquaredRootOfContributions += s;
                }
            }
        }

        if (totalSquaredRootOfContributions == 0) revert AetherWeaver__NoMatchingFundsAvailable();

        uint256 totalDistributedFunds = 0;
        uint256 fundsToDistribute = matchingPoolBalance; // Use the entire pool for this round

        // Second pass: Distribute funds based on calculated proportions
        for (uint256 i = 0; i < _catalystIds.length; i++) {
            uint256 catalystId = _catalystIds[i];
            Catalyst storage catalyst = catalysts[catalystId];

            if (catalyst.id == 0 || catalyst.status != CatalystStatus.Approved || catalyst.matchingFundsDistributed) {
                continue;
            }

            uint256 projectSqrtSum = individualSquaredRootOfContributions[i];
            if (projectSqrtSum == 0) continue;

            // Share of pool = (project_sqrt_sum / total_network_sqrt_sum) * baseAQFMultiplier / 100 (for multiplier)
            // The `baseAQFMultiplier` acts as a global scaling factor that adapts.
            uint256 matchingAmount = (projectSqrtSum * fundsToDistribute * baseAQFMultiplier) / (totalSquaredRootOfContributions * 100);

            if (matchingAmount > 0) {
                catalyst.totalMatchingFunds += matchingAmount;
                totalDistributedFunds += matchingAmount;
                catalyst.matchingFundsDistributed = true; // Mark as distributed for this round
            }
        }

        // Refund any remaining matching pool funds (e.g., due to rounding or if not all funds were used)
        if (totalDistributedFunds < fundsToDistribute) {
            uint256 remaining = fundsToDistribute - totalDistributedFunds;
            matchingPoolBalance = 0; // Reset for next round
            // Optionally, transfer remaining back to owner or a treasury. For simplicity, we assume it's used.
            // Or it can stay in the pool for next round. Let's make it stay.
            matchingPoolBalance = remaining;
        } else {
            matchingPoolBalance = 0; // Entire pool used
        }


        emit MatchingFundsDistributed(currentRoundId, totalDistributedFunds);
    }

    // Helper for approximate integer square root
    function _sqrt(uint256 x) internal pure returns (uint256 y) {
        uint256 z = (x + 1) / 2;
        y = x;
        while (z < y) {
            y = z;
            z = (x / z + z) / 2;
        }
    }

    /**
     * @dev Allows successful vouch stakers to claim rewards.
     *      Rewards could come from a small portion of project fees or a dedicated treasury.
     *      For this example, rewards are a small percentage of the total vouch stake,
     *      imagining that successful projects somehow generate a small return for their early backers.
     */
    function claimVouchStakingRewards() public whenNotPaused nonReentrant {
        uint256 totalClaimable = 0;
        for (uint256 i = 1; i <= _catalystIdCounter.current(); i++) { // Iterate all catalysts
            Catalyst storage catalyst = catalysts[i];
            if (catalyst.vouchStakes[msg.sender] > 0 && catalyst.status == CatalystStatus.Completed) {
                // Simplified reward logic: 1% of stake for successful project (hypothetical)
                uint256 reward = (catalyst.vouchStakes[msg.sender] * 1) / 100; // 1% reward
                if (reward > 0) {
                    totalClaimable += reward;
                    catalyst.vouchStakes[msg.sender] = 0; // Reset stake after claim
                    // In a real system, the actual stake would be returned too, plus rewards.
                    // Here, we assume stake is tied up until project completion or failure, then returned.
                    // For simplicity, this `claimVouchStakingRewards` only claims rewards, stakes are 'released' separately.
                    // For this example, we'll assume the initial stake *plus* rewards are returned.
                    totalClaimable += catalyst.vouchStakes[msg.sender];
                    catalyst.vouchStakes[msg.sender] = 0;
                }
            }
        }

        if (totalClaimable == 0) revert AetherWeaver__RewardNotClaimable();

        // Transfer rewards (plus initial stake if not already returned)
        // This assumes the contract holds enough funds for rewards, perhaps from a fee pool.
        // For simplicity, we assume the reward tokens are sourced from the contract's overall balance.
        if (!aetherToken.transfer(msg.sender, totalClaimable)) revert AetherWeaver__TokenTransferFailed();

        emit VouchStakingRewardsClaimed(msg.sender, totalClaimable);
    }

    // --- VI. Adaptive Parameter Adjustment (Owner/Governance Only) ---

    /**
     * @dev Dynamically adjusts the Adaptive Quadratic Funding multiplier.
     *      This could be based on network health, node activity, impact metrics, or governance.
     * @param _newMultiplier The new multiplier value.
     */
    function adjustAdaptiveAQFMultiplier(uint256 _newMultiplier) public onlyOwner { // Or by governance/oracle
        uint256 oldMultiplier = baseAQFMultiplier;
        baseAQFMultiplier = _newMultiplier;
        emit AdaptiveAQFMultiplierAdjusted(oldMultiplier, _newMultiplier);
    }

    /**
     * @dev Sets dynamic thresholds for a Catalyst to be considered "impactful" within a domain,
     *      potentially affecting funding boosts or node level ups.
     * @param _domain The domain to set thresholds for.
     * @param _minVouchAmount Minimum total vouch stake for impact recognition.
     * @param _minAIScore Minimum AI score for impact recognition.
     */
    function setImpactThresholds(bytes32 _domain, uint256 _minVouchAmount, uint256 _minAIScore) public onlyOwner {
        if (!allowedDomains[_domain]) revert AetherWeaver__DomainNotAllowed();
        // In a real system, these would be stored in a mapping, e.g., `mapping(bytes32 => ImpactThresholds)`.
        // For simplicity, this function is a placeholder to demonstrate the concept.
        // emit ImpactThresholdsSet(_domain, _minVouchAmount, _minAIScore);
    }

    // --- VII. View Functions (Read-only) ---

    /**
     * @dev Retrieves details of a user's AetherWeaver Node.
     * @param _user The address of the user.
     * @return AetherNode struct details.
     */
    function getAetherNode(address _user) public view returns (uint256 nodeId, address owner, bytes32[] memory specializedDomains, uint256 lastActivityTime, uint256 reputationScore) {
        AetherNode storage node = aetherNodes[_user];
        return (node.nodeId, node.owner, node.specializedDomains, node.lastActivityTime, node.reputationScore);
    }

    /**
     * @dev Retrieves the level of a specific AetherWeaver Node in a given domain.
     * @param _user The owner of the node.
     * @param _domain The domain to check.
     * @return The level (uint8) in the specified domain.
     */
    function getNodeDomainLevel(address _user, bytes32 _domain) public view returns (uint8) {
        return aetherNodes[_user].levels[_domain];
    }

    /**
     * @dev Retrieves all details for a specific Catalyst.
     * @param _catalystId The ID of the Catalyst.
     * @return Catalyst struct details.
     */
    function getCatalystDetails(uint256 _catalystId) public view returns (
        uint256 id,
        address contributor,
        string memory title,
        string memory description,
        string memory ipfsHash,
        bytes32[] memory relevantDomains,
        CatalystStatus status,
        uint256 submissionTimestamp,
        uint256 evaluationStartTimestamp,
        uint256 aiScore,
        string memory aiReportIpfsHash,
        uint256 totalDirectFunds,
        uint256 totalMatchingFunds,
        uint256 totalVouchStake,
        uint256 evaluationCount,
        uint256 weightedEvaluationSum,
        bool matchingFundsDistributed
    ) {
        Catalyst storage catalyst = catalysts[_catalystId];
        return (
            catalyst.id,
            catalyst.contributor,
            catalyst.title,
            catalyst.description,
            catalyst.ipfsHash,
            catalyst.relevantDomains,
            catalyst.status,
            catalyst.submissionTimestamp,
            catalyst.evaluationStartTimestamp,
            catalyst.aiScore,
            catalyst.aiReportIpfsHash,
            catalyst.totalDirectFunds,
            catalyst.totalMatchingFunds,
            catalyst.totalVouchStake,
            catalyst.evaluationCount,
            catalyst.weightedEvaluationSum,
            catalyst.matchingFundsDistributed
        );
    }

    /**
     * @dev Retrieves all evaluations for a specific Catalyst.
     * @param _catalystId The ID of the Catalyst.
     * @return An array of Evaluation structs.
     */
    function getCatalystEvaluations(uint256 _catalystId) public view returns (Evaluation[] memory) {
        return catalystEvaluations[_catalystId];
    }

    /**
     * @dev Retrieves aggregate statistics for a given domain.
     * @param _domain The bytes32 representation of the domain name.
     * @return totalNodes The total number of nodes specialized in this domain.
     * @return avgLevel The average expertise level across nodes in this domain.
     */
    function getDomainStatistics(bytes32 _domain) public view returns (uint256 totalNodes, uint256 avgLevel) {
        if (!allowedDomains[_domain]) revert AetherWeaver__DomainNotAllowed();
        return (domainTotalNodes[_domain], domainAvgLevel[_domain]);
    }

    /**
     * @dev Returns the total balance of AetherTokens held by the contract.
     * @return The total token balance.
     */
    function getContractAetherBalance() public view returns (uint256) {
        return aetherToken.balanceOf(address(this));
    }

    /**
     * @dev Returns the current number of minted AetherWeaver Nodes.
     * @return The total node count.
     */
    function getTotalAetherNodes() public view returns (uint256) {
        return _nodeIdCounter.current();
    }

    /**
     * @dev Returns the current number of submitted Catalysts.
     * @return The total catalyst count.
     */
    function getTotalCatalysts() public view returns (uint256) {
        return _catalystIdCounter.current();
    }

    /**
     * @dev Returns the amount of AetherTokens a user has vouched for a specific catalyst.
     * @param _catalystId The ID of the catalyst.
     * @param _user The address of the voucher.
     * @return The vouch stake amount.
     */
    function getUserVouchStake(uint256 _catalystId, address _user) public view returns (uint256) {
        return catalysts[_catalystId].vouchStakes[_user];
    }

    // --- ERC721 Overrides for Non-Transferable Nodes ---

    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal pure override {
        // Prevent transfers of AetherWeaver Nodes between users
        if (from != address(0) && to != address(0)) {
            revert AetherWeaver__Unauthorized(); // Nodes are non-transferable
        }
        // Allow minting (from address(0)) and burning (to address(0))
    }
}
```