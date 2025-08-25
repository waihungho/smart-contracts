Here's a smart contract in Solidity called "Aetheria Nexus," designed around an advanced concept of a decentralized AI-driven research and development platform. It integrates DAO governance (conceptually), a dynamic reputation system, and two types of dynamic NFTs, all within a bounty-driven framework for AI models and research.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
// OpenZeppelin Governor components would typically be used for full DAO governance,
// but for brevity and focus on AetheriaNexus's unique logic, a placeholder is used.
// import "@openzeppelin/contracts/governance/TimelockController.sol";
// import "@openzeppelin/contracts/governance/Governor.sol";

/**
 * @title Aetheria Nexus: Decentralized AI-Driven Research & Development DAO
 * @author YourBlockchainDev
 * @notice Aetheria Nexus is a cutting-edge DAO designed to fund, validate, and deploy AI models and research outputs.
 *         It combines decentralized governance, a robust reputation system, and dynamic NFTs to create a vibrant ecosystem
 *         for AI innovation. Users propose bounties, submit solutions, and participate in a multi-modal review process
 *         involving staked reviewers, community voting, and oracle-verified AI performance metrics.
 *         Successful contributors earn AETHER tokens, reputation, and unique Dynamic NFTs representing their validated AI models or research.
 *
 * @dev This contract implements a sophisticated blend of:
 *      - **DAO Governance:** Utilizing OpenZeppelin's Governor for proposals, voting, and execution (conceptually; direct implementation in a separate Governor contract not shown here for brevity, instead `Ownable` and a `_isDaoGovernance` placeholder are used).
 *      - **Bounty System:** For funding and managing AI research challenges.
 *      - **Reputation System:** Tracks contributor standing, influencing access and rewards.
 *      - **Dynamic NFTs (dNFTs):**
 *          1. `ReputationBadges`: NFTs that visually evolve based on a user's reputation.
 *          2. `AIModelNFTs`: Representing validated AI models/research, whose metadata can be updated to reflect improvements or further findings.
 *      - **Staked Reviewers:** A mechanism to ensure quality control for submissions.
 *      - **Oracle Integration:** To verify off-chain AI model performance metrics.
 *      - **Reentrancy Protection:** For secure fund handling.
 *
 * --- Contract Outline and Function Summary ---
 *
 * I. Core Setup & Administration
 *    - `constructor`: Initializes AETHER token, Oracle, and DAO treasury addresses. Sets up the ERC721 NFT base.
 *    - `tokenURI(uint256 tokenId)`: ERC721 override to provide dynamic metadata URIs for both Reputation Badge and AI Model NFTs, based on their token ID range.
 *    - `setOracleAddress(address _newOracleAddress)`: Owner/DAO governance function to update the oracle contract address.
 *    - `setDAOTreasury(address _newTreasury)`: Owner/DAO governance function to update the DAO treasury address.
 *
 * II. Bounty Management (AI Research/Model Challenges)
 *    1. `proposeBounty(string _title, string _descriptionURI, uint256 _rewardAmount, uint256 _submissionDuration, uint256 _reviewDuration, uint256 _votingDuration)`:
 *       Proposes a new AI challenge, requiring a minimum reputation from the proposer.
 *    2. `fundBounty(uint256 _bountyId, uint256 _amount)`: Allows users to contribute AETHER tokens to a proposed bounty. Funds are held in the DAO treasury.
 *    3. `startBounty(uint256 _bountyId)`: Activates a funded bounty, opening it for submissions. Callable by proposer or DAO.
 *    4. `submitSolution(uint256 _bountyId, string _solutionURI, string _modelIdentifier)`:
 *       Contributors submit their AI model/research solutions before the deadline.
 *    5. `closeSubmissionPeriod(uint256 _bountyId)`: Transitions a bounty from 'Active' to 'ReviewPending' after the submission deadline has passed.
 *    6. `assignReviewers(uint256 _submissionId, uint256[] _reviewerStakeIds)`:
 *       Assigns qualified, staked reviewers to evaluate a submission. Callable by proposer or DAO.
 *    7. `submitReview(uint256 _submissionId, string _reviewURI, uint256 _score)`:
 *       Allows an assigned reviewer to submit their evaluation and score, earning reputation. Triggers oracle validation if reviews are sufficiently high.
 *    8. `receiveAIValidationResult(uint256 _submissionId, uint256 _score)`:
 *       Callback from the AetheriaOracle, providing off-chain AI model performance data. Only callable by the oracle.
 *    9. `voteOnSubmission(uint256 _submissionId, bool _isPositive)`:
 *       Community members vote on submissions, influencing the final outcome.
 *    10. `finalizeBounty(uint256 _bountyId)`: Determines the winning submission based on aggregated scores (reviews, oracle, votes),
 *        distributes rewards, updates reputation, and mints an `AIModelNFT`.
 *    11. `withdrawBountyFunds(uint256 _bountyId)`: Allows the proposer to retrieve unspent bounty funds if the bounty fails to finalize.
 *
 * III. Reviewer & Reputation Management
 *    12. `becomeReviewer()`: Allows a user to stake AETHER tokens and become a qualified reviewer, requiring minimum reputation.
 *    13. `removeReviewerStake()`: Initiates the unstaking process for a reviewer, marking their stake for a cool-down period.
 *    14. `claimReviewerStake()`: Allows a reviewer to withdraw their staked AETHER after the cool-down period has ended.
 *    15. `penalizeReviewer(address _reviewerAddress, uint256 _submissionId, string _reason)`:
 *        Owner/DAO governance function to penalize reviewers for poor performance, resulting in reputation loss and temporary stake locking.
 *
 * IV. Dynamic NFT (dNFT) Management
 *    - `ReputationBadges` (ERC721):
 *      16. `mintReputationBadgeNFT(address _user, string _initialMetadataURI)`: Mints a unique NFT representing a user's initial reputation.
 *      17. `upgradeReputationBadge(uint256 _tokenId, string _newMetadataURI)`: Allows the NFT owner to update the metadata URI of their Reputation Badge NFT
 *          to reflect reputation progression, making it visually dynamic.
 *    - `AIModelNFTs` (ERC721):
 *      18. `_mintAIModelNFT(address _owner, uint256 _bountyId, string _initialMetadataURI)`: (Internal) Mints an NFT representing a validated AI model
 *          or research, typically called automatically during bounty finalization for the winning submission.
 *      19. `updateAIModelNFTMetadata(uint256 _tokenId, string _newMetadataURI)`: Allows the NFT owner to update the metadata URI of an AI Model NFT
 *          to reflect model improvements, new benchmarks, or linked research.
 *      20. `linkResearchContribution(uint256 _aiModelNFTId, string _contributionURI)`: Conceptually links new research or fine-tuning
 *          outputs to an existing `AIModelNFT`. This might trigger a metadata update or internal state change.
 *
 * V. View Functions (Getters)
 *    21. `getBountyDetails(uint256 _bountyId)`: Returns all comprehensive details for a specific bounty.
 *    22. `getSubmissionDetails(uint256 _bountyId, uint256 _submissionId)`: Returns all details for a specific submission within a bounty.
 *    23. `getReviewDetails(uint256 _bountyId, uint256 _submissionId, address _reviewer)`: Returns details for a specific reviewer's submission review.
 *    24. `getReputation(address _user)`: Returns the current reputation score of a user.
 *    25. `getReviewerStakeDetails(address _reviewerAddress)`: Returns details about a reviewer's staked AETHER, including lock status.
 *
 * VI. Internal Helpers & Placeholders
 *    - `_updateReputation(address user, int256 change)`: Internal function to safely adjust a user's reputation score.
 *    - `_isDaoGovernance()`: Placeholder function to simulate a check against a DAO governance contract.
 */

// Interface for the external Aetheria Oracle contract
interface IAetheriaOracle {
    function requestAIValidation(uint256 submissionId, string calldata modelIdentifier, address callbackContract) external;
}

contract AetheriaNexus is Context, Ownable, ReentrancyGuard, ERC721 {
    using Counters for Counters.Counter;
    using SafeMath for uint256;

    // --- State Variables ---
    IERC20 public immutable AETHER_TOKEN; // Governance and utility token
    IAetheriaOracle public aetheriaOracle; // Oracle contract for AI validation (e.g., Chainlink, custom oracle)
    address public daoTreasury; // Address where bounty funds are held, controlled by DAO governance

    Counters.Counter private _bountyIds;
    Counters.Counter private _submissionIds;
    Counters.Counter private _reputationBadgeTokenIds;
    Counters.Counter private _aiModelNFTTokenIds;

    // --- Structs ---
    enum BountyState { Proposed, Funded, Active, ReviewPending, VotingPending, OracleValidationPending, Finalized, Failed }
    enum SubmissionState { PendingReview, UnderReview, OracleValidationRequired, Approved, Rejected }

    struct Bounty {
        uint256 id;
        address proposer;
        string title;
        string descriptionURI; // IPFS hash or URL for detailed bounty description
        uint256 rewardAmount; // Total AETHER tokens allocated for this bounty
        uint256 submissionDeadline;
        uint256 reviewDeadline;
        uint256 votingDeadline;
        uint256 oracleValidationDeadline;
        BountyState state;
        uint252 winningSubmissionId; // Stores the ID of the winning submission
        mapping(uint256 => Submission) submissions; // Submission ID to Submission struct
        uint256[] submissionIds; // List of submission IDs for iteration
    }

    struct Submission {
        uint256 id;
        uint256 bountyId;
        address submitter;
        string solutionURI; // IPFS hash or URL for the AI model/research solution
        string modelIdentifier; // Unique identifier for AI model, used by oracle for off-chain lookup
        SubmissionState state;
        uint256[] assignedReviewerStakeIds; // IDs of ReviewerStakes assigned to this submission
        mapping(address => Review) reviews; // Reviewer address to Review struct
        uint256 positiveVotes;
        uint252 negativeVotes;
        uint256 oracleScore; // Score returned by oracle (e.g., accuracy, performance metric)
        bool oracleValidated;
    }

    struct Review {
        uint256 submissionId;
        address reviewer;
        string reviewURI; // IPFS hash or URL for detailed review comments
        uint256 score; // 1-10 rating for the submission
        bool completed;
        bool penalized; // True if reviewer was penalized for this specific review
    }

    struct ReviewerStake {
        uint252 id;
        address reviewerAddress;
        uint256 stakeAmount; // AETHER tokens staked
        uint256 unlockTimestamp; // When stake can be withdrawn
        bool isActive; // True if reviewer is currently active for assignments
        bool isPenalized; // True if reviewer has a temporary penalty affecting their eligibility
    }

    // --- Mappings ---
    mapping(uint256 => Bounty) public bounties; // Bounty ID to Bounty struct
    mapping(address => uint256) public reputation; // Address to reputation score
    mapping(address => uint256) public reviewerStakes; // Reviewer address to their active ReviewerStake ID
    mapping(uint256 => ReviewerStake) public reviewerStakeRegistry; // ReviewerStake ID to ReviewerStake struct
    uint256[] public activeReviewerStakeIds; // List of active reviewer stake IDs for random assignment

    // Dynamic NFT metadata mapping
    mapping(uint256 => string) public reputationBadgeMetadataURIs; // Token ID to specific metadata URI for ReputationBadges
    mapping(uint256 => string) public aiModelNFTMetadataURIs; // Token ID to specific metadata URI for AIModelNFTs
    mapping(uint256 => uint256) public aiModelNFTBountyId; // AIModelNFT tokenId to original Bounty ID

    // --- Configuration Parameters (can be set by DAO governance in a full implementation) ---
    uint256 public constant MIN_REPUTATION_FOR_REVIEWER = 100;
    uint256 public constant REVIEWER_STAKE_AMOUNT = 1000 * (10 ** 18); // Example: 1000 AETHER
    uint256 public constant REVIEWER_STAKE_UNLOCK_PERIOD = 30 days; // 30 days cool-down for unstaking
    uint256 public constant MIN_REVIEWERS_PER_SUBMISSION = 3;
    uint256 public constant ORACLE_VALIDATION_TIME = 7 days; // Max time for oracle to respond
    uint256 public constant REPUTATION_FOR_BOUNTY_WIN = 50;
    uint252 public constant REPUTATION_FOR_POSITIVE_REVIEW = 5;
    uint256 public constant REPUTATION_PENALTY_FOR_BAD_REVIEW = 10;
    uint256 public constant MIN_REPUTATION_TO_PROPOSE_BOUNTY = 50;
    uint256 public constant MIN_AVG_SCORE_FOR_ORACLE_TRIGGER = 8; // Avg review score (out of 10) to trigger oracle

    // --- Events ---
    event BountyProposed(uint256 indexed bountyId, address indexed proposer, string title, uint256 rewardAmount, uint256 submissionDeadline);
    event BountyFunded(uint256 indexed bountyId, address indexed funder, uint256 amount);
    event BountyStarted(uint256 indexed bountyId);
    event SubmissionPeriodClosed(uint256 indexed bountyId);
    event SolutionSubmitted(uint256 indexed bountyId, uint256 indexed submissionId, address indexed submitter, string modelIdentifier);
    event ReviewersAssigned(uint256 indexed submissionId, uint256[] reviewerStakeIds);
    event ReviewSubmitted(uint256 indexed submissionId, address indexed reviewer, uint256 score);
    event SubmissionVoted(uint256 indexed submissionId, address indexed voter, bool isPositiveVote);
    event BountyFinalized(uint256 indexed bountyId, uint256 indexed winningSubmissionId, address indexed winner, uint256 rewardDistributed);
    event BountyFailed(uint256 indexed bountyId);
    event FundsWithdrawn(uint256 indexed bountyId, address indexed beneficiary, uint256 amount);
    event ReputationUpdated(address indexed user, uint256 newReputation);
    event ReviewerStaked(address indexed reviewer, uint256 stakeAmount, uint256 reviewerStakeId);
    event ReviewerUnstaked(address indexed reviewer, uint256 stakeAmount, uint256 reviewerStakeId);
    event ReviewerStakeClaimed(address indexed reviewer, uint256 amount);
    event ReviewerPenalized(address indexed reviewer, uint256 reviewerStakeId, string reason);
    event OracleValidationRequested(uint256 indexed submissionId, string modelIdentifier);
    event OracleValidationReceived(uint256 indexed submissionId, uint256 score);
    event ReputationBadgeMinted(address indexed owner, uint256 indexed tokenId, uint256 reputationScore);
    event ReputationBadgeUpgraded(address indexed owner, uint256 indexed tokenId, uint256 newReputationScore);
    event AIModelNFTMinted(address indexed owner, uint256 indexed tokenId, uint256 indexed bountyId);
    event AIModelNFTMetadataUpdated(uint256 indexed tokenId, string newUri);
    event ResearchContributionLinked(uint256 indexed aiModelNFTId, string contributionURI);

    // --- Constructor ---
    constructor(
        address _aetherTokenAddress,
        address _oracleAddress,
        address _daoTreasury
    ) ERC721("AetheriaNexus_NFT", "ANXNFT") {
        require(_aetherTokenAddress != address(0), "Invalid AETHER token address");
        require(_oracleAddress != address(0), "Invalid oracle address");
        require(_daoTreasury != address(0), "Invalid DAO treasury address");

        AETHER_TOKEN = IERC20(_aetherTokenAddress);
        aetheriaOracle = IAetheriaOracle(_oracleAddress);
        daoTreasury = _daoTreasury;
    }

    // --- ERC721 Overrides for Dynamic NFTs ---
    // We manage two types of NFTs here: Reputation Badges and AI Model NFTs.
    // To distinguish them by tokenId, we use an offset for AI Model NFTs.
    uint256 private constant AI_MODEL_NFT_TOKEN_ID_OFFSET = 1_000_000_000; // Large offset to separate ID ranges

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        if (tokenId < AI_MODEL_NFT_TOKEN_ID_OFFSET) {
            // This is a Reputation Badge NFT
            require(reputationBadgeMetadataURIs[tokenId].length > 0, "Reputation Badge NFT metadata not set");
            return reputationBadgeMetadataURIs[tokenId];
        } else {
            // This is an AI Model NFT
            require(aiModelNFTMetadataURIs[tokenId].length > 0, "AI Model NFT metadata not set");
            return aiModelNFTMetadataURIs[tokenId];
        }
    }

    // --- Internal Helpers ---
    function _updateReputation(address user, int256 change) internal {
        uint256 currentReputation = reputation[user];
        if (change > 0) {
            reputation[user] = currentReputation.add(uint256(change));
        } else {
            // Ensure reputation doesn't go below zero
            reputation[user] = currentReputation > uint256(-change) ? currentReputation.sub(uint256(-change)) : 0;
        }
        emit ReputationUpdated(user, reputation[user]);
    }

    // Placeholder for DAO governance check. In a real scenario, this contract
    // would be behind a Governor contract or an access control layer linked to the DAO.
    function _isDaoGovernance() internal view returns (bool) {
        // For this example, let's say only the owner (or a specific DAO address) can act as 'governance'
        return _msgSender() == owner(); // Replace with actual DAO contract address check if Governor is deployed
    }

    // --- Admin/Owner Functions ---
    // In a full DAO, these critical functions would be managed by DAO governance proposals.
    function setOracleAddress(address _newOracleAddress) external onlyOwner {
        require(_newOracleAddress != address(0), "Invalid oracle address");
        aetheriaOracle = IAetheriaOracle(_newOracleAddress);
    }

    function setDAOTreasury(address _newTreasury) external onlyOwner {
        require(_newTreasury != address(0), "Invalid treasury address");
        daoTreasury = _newTreasury;
    }

    // --- Bounty Management ---

    /**
     * @summary 1. proposeBounty: Proposes a new AI research or model challenge.
     * @dev Requires minimum reputation to prevent spam. The bounty is initially in 'Proposed' state.
     * @param _title The title of the bounty.
     * @param _descriptionURI IPFS hash or URL for detailed description of the bounty.
     * @param _rewardAmount The initial AETHER token amount suggested as a reward. This can be increased by `fundBounty`.
     * @param _submissionDuration Days allowed for contributors to submit solutions.
     * @param _reviewDuration Days allowed for reviewers to evaluate submissions.
     * @param _votingDuration Days allowed for community voting on submissions.
     * @return uint256 The ID of the newly proposed bounty.
     */
    function proposeBounty(
        string calldata _title,
        string calldata _descriptionURI,
        uint256 _rewardAmount,
        uint256 _submissionDuration,
        uint256 _reviewDuration,
        uint256 _votingDuration
    ) external nonReentrant returns (uint256) {
        require(reputation[_msgSender()] >= MIN_REPUTATION_TO_PROPOSE_BOUNTY, "Requires minimum reputation to propose bounty");
        require(_rewardAmount > 0, "Bounty reward must be greater than zero");
        require(_submissionDuration > 0 && _reviewDuration > 0 && _votingDuration > 0, "Durations must be positive");

        _bountyIds.increment();
        uint256 newBountyId = _bountyIds.current();

        Bounty storage newBounty = bounties[newBountyId];
        newBounty.id = newBountyId;
        newBounty.proposer = _msgSender();
        newBounty.title = _title;
        newBounty.descriptionURI = _descriptionURI;
        newBounty.rewardAmount = _rewardAmount;
        newBounty.submissionDeadline = block.timestamp.add(_submissionDuration.mul(1 days));
        newBounty.reviewDeadline = _reviewDuration.mul(1 days); // Store as duration, not timestamp yet
        newBounty.votingDeadline = _votingDuration.mul(1 days); // Store as duration, not timestamp yet
        newBounty.state = BountyState.Proposed;

        emit BountyProposed(newBountyId, _msgSender(), _title, _rewardAmount, newBounty.submissionDeadline);
        return newBountyId;
    }

    /**
     * @summary 2. fundBounty: Funds a proposed bounty with AETHER tokens.
     * @dev Anyone can fund a bounty. The funds are transferred from the caller to the DAO treasury.
     * @param _bountyId The ID of the bounty to fund.
     * @param _amount The amount of AETHER tokens to fund.
     */
    function fundBounty(uint256 _bountyId, uint256 _amount) external nonReentrant {
        Bounty storage bounty = bounties[_bountyId];
        require(bounty.id == _bountyId, "Bounty does not exist");
        require(bounty.state == BountyState.Proposed || bounty.state == BountyState.Funded, "Bounty not in fundable state");
        require(_amount > 0, "Amount must be greater than zero");

        AETHER_TOKEN.transferFrom(_msgSender(), daoTreasury, _amount);
        bounty.rewardAmount = bounty.rewardAmount.add(_amount);
        bounty.state = BountyState.Funded;

        emit BountyFunded(_bountyId, _msgSender(), _amount);
    }

    /**
     * @summary 3. startBounty: Transitions a funded bounty to 'Active' state.
     * @dev Callable by the bounty proposer or DAO governance. Submissions can begin after this.
     * @param _bountyId The ID of the bounty to start.
     */
    function startBounty(uint256 _bountyId) external {
        Bounty storage bounty = bounties[_bountyId];
        require(bounty.id == _bountyId, "Bounty does not exist");
        require(bounty.state == BountyState.Funded, "Bounty not in Funded state");
        require(block.timestamp < bounty.submissionDeadline, "Cannot start bounty after submission deadline");
        require(_msgSender() == bounty.proposer || _isDaoGovernance(), "Only proposer or DAO governance can start bounty");

        bounty.state = BountyState.Active;
        emit BountyStarted(_bountyId);
    }

    /**
     * @summary 4. submitSolution: Allows an AI scientist/developer to submit their solution for an active bounty.
     * @param _bountyId The ID of the bounty.
     * @param _solutionURI IPFS hash or URL for the solution details (e.g., model code, research paper).
     * @param _modelIdentifier A unique identifier for the AI model, potentially used by an oracle for validation.
     * @return uint256 The ID of the newly created submission.
     */
    function submitSolution(
        uint256 _bountyId,
        string calldata _solutionURI,
        string calldata _modelIdentifier
    ) external nonReentrant returns (uint256) {
        Bounty storage bounty = bounties[_bountyId];
        require(bounty.id == _bountyId, "Bounty does not exist");
        require(bounty.state == BountyState.Active, "Bounty not in active state for submissions");
        require(block.timestamp <= bounty.submissionDeadline, "Submission deadline has passed");

        _submissionIds.increment();
        uint256 newSubmissionId = _submissionIds.current();

        Submission storage newSubmission = bounty.submissions[newSubmissionId];
        newSubmission.id = newSubmissionId;
        newSubmission.bountyId = _bountyId;
        newSubmission.submitter = _msgSender();
        newSubmission.solutionURI = _solutionURI;
        newSubmission.modelIdentifier = _modelIdentifier;
        newSubmission.state = SubmissionState.PendingReview;
        bounty.submissionIds.push(newSubmissionId);

        emit SolutionSubmitted(_bountyId, newSubmissionId, _msgSender(), _modelIdentifier);
        return newSubmissionId;
    }

    /**
     * @summary 5. closeSubmissionPeriod: Transitions bounty from Active to ReviewPending.
     * @dev Callable once submission deadline passes. Sets review period start.
     * @param _bountyId The ID of the bounty.
     */
    function closeSubmissionPeriod(uint256 _bountyId) external {
        Bounty storage bounty = bounties[_bountyId];
        require(bounty.id == _bountyId, "Bounty does not exist");
        require(bounty.state == BountyState.Active, "Bounty not in active state");
        require(block.timestamp > bounty.submissionDeadline, "Submission period not yet ended");
        require(bounty.submissionIds.length > 0, "No submissions for this bounty, cannot proceed to review.");

        bounty.state = BountyState.ReviewPending;
        bounty.reviewDeadline = block.timestamp.add(bounty.reviewDeadline); // Now set as a timestamp
        emit SubmissionPeriodClosed(_bountyId);
    }

    /**
     * @summary 6. assignReviewers: Assigns active staked reviewers to a submission.
     * @dev Only callable by the bounty proposer or DAO governance.
     * @param _submissionId The ID of the submission to assign reviewers to.
     * @param _reviewerStakeIds An array of ReviewerStake IDs.
     */
    function assignReviewers(uint256 _submissionId, uint256[] calldata _reviewerStakeIds) external {
        Bounty storage bounty = bounties[bounties[_submissionId].bountyId]; // Get bounty via submission
        Submission storage submission = bounty.submissions[_submissionId];
        require(submission.id == _submissionId, "Submission does not exist");
        require(bounty.state == BountyState.ReviewPending, "Bounty not in review pending state");
        require(block.timestamp <= bounty.reviewDeadline, "Review period deadline passed.");
        require(_reviewerStakeIds.length >= MIN_REVIEWERS_PER_SUBMISSION, "Not enough reviewers assigned");
        require(_msgSender() == bounty.proposer || _isDaoGovernance(), "Only proposer or DAO governance can assign reviewers");
        require(submission.assignedReviewerStakeIds.length == 0, "Reviewers already assigned to this submission");

        for (uint256 i = 0; i < _reviewerStakeIds.length; i++) {
            ReviewerStake storage reviewerStake = reviewerStakeRegistry[_reviewerStakeIds[i]];
            require(reviewerStake.isActive, "Reviewer stake is not active");
            require(!reviewerStake.isPenalized, "Reviewer is temporarily penalized");
            require(reputation[reviewerStake.reviewerAddress] >= MIN_REPUTATION_FOR_REVIEWER, "Reviewer does not meet reputation requirement");

            submission.assignedReviewerStakeIds.push(_reviewerStakeIds[i]);
        }
        submission.state = SubmissionState.UnderReview;

        emit ReviewersAssigned(_submissionId, _reviewerStakeIds);
    }

    /**
     * @summary 7. submitReview: Allows an assigned reviewer to submit their review for a submission.
     * @dev Reviewers earn reputation for timely, quality reviews. If all reviews are in and average score is high, triggers oracle.
     * @param _submissionId The ID of the submission.
     * @param _reviewURI IPFS hash or URL for detailed review comments.
     * @param _score A score from 1 to 10 for the submission.
     */
    function submitReview(uint256 _submissionId, string calldata _reviewURI, uint256 _score) external nonReentrant {
        Bounty storage bounty = bounties[bounties[_submissionId].bountyId];
        Submission storage submission = bounty.submissions[_submissionId];
        require(submission.id == _submissionId, "Submission does not exist");
        require(bounty.state == BountyState.ReviewPending, "Bounty not in review pending state");
        require(block.timestamp <= bounty.reviewDeadline, "Review deadline has passed");
        require(_score >= 1 && _score <= 10, "Score must be between 1 and 10");

        bool isAssignedReviewer = false;
        uint256 reviewerStakeId = reviewerStakes[_msgSender()]; // Get the reviewer's current stake ID
        for (uint256 i = 0; i < submission.assignedReviewerStakeIds.length; i++) {
            if (submission.assignedReviewerStakeIds[i] == reviewerStakeId) {
                isAssignedReviewer = true;
                break;
            }
        }
        require(isAssignedReviewer, "Only assigned reviewers can submit reviews");
        require(!submission.reviews[_msgSender()].completed, "Review already submitted by this reviewer");

        Review storage newReview = submission.reviews[_msgSender()];
        newReview.submissionId = _submissionId;
        newReview.reviewer = _msgSender();
        newReview.reviewURI = _reviewURI;
        newReview.score = _score;
        newReview.completed = true;

        _updateReputation(_msgSender(), int256(REPUTATION_FOR_POSITIVE_REVIEW)); // Reward for completing a review

        // Check if all assigned reviewers have submitted
        uint256 completedReviewCount = 0;
        uint256 totalReviewScore = 0;
        for (uint256 i = 0; i < submission.assignedReviewerStakeIds.length; i++) {
            ReviewerStake storage rStake = reviewerStakeRegistry[submission.assignedReviewerStakeIds[i]];
            if (submission.reviews[rStake.reviewerAddress].completed) {
                completedReviewCount = completedReviewCount.add(1);
                totalReviewScore = totalReviewScore.add(submission.reviews[rStake.reviewerAddress].score);
            }
        }

        if (completedReviewCount == submission.assignedReviewerStakeIds.length) {
            uint256 averageReviewScore = totalReviewScore.div(submission.assignedReviewerStakeIds.length);

            if (averageReviewScore >= MIN_AVG_SCORE_FOR_ORACLE_TRIGGER) {
                // If average review score is high, trigger oracle validation
                submission.state = SubmissionState.OracleValidationRequired;
                bounty.state = BountyState.OracleValidationPending;
                bounty.oracleValidationDeadline = block.timestamp.add(ORACLE_VALIDATION_TIME);
                aetheriaOracle.requestAIValidation(_submissionId, submission.modelIdentifier, address(this));
                emit OracleValidationRequested(_submissionId, submission.modelIdentifier);
            } else {
                // Otherwise, proceed directly to community voting
                bounty.state = BountyState.VotingPending;
                bounty.votingDeadline = block.timestamp.add(bounty.votingDeadline); // Set actual timestamp
            }
        }

        emit ReviewSubmitted(_submissionId, _msgSender(), _score);
    }

    /**
     * @summary 8. receiveAIValidationResult: Callback function for the AetheriaOracle to provide AI model performance.
     * @dev Only callable by the designated aetheriaOracle address.
     * @param _submissionId The ID of the submission that was validated.
     * @param _score The performance score (e.g., accuracy percentage) from the oracle.
     */
    function receiveAIValidationResult(uint256 _submissionId, uint256 _score) external {
        require(_msgSender() == address(aetheriaOracle), "Only AetheriaOracle can call this function");
        Bounty storage bounty = bounties[bounties[_submissionId].bountyId];
        Submission storage submission = bounty.submissions[_submissionId];
        require(submission.id == _submissionId, "Submission does not exist");
        require(submission.state == SubmissionState.OracleValidationRequired, "Submission not awaiting oracle validation");
        require(block.timestamp <= bounty.oracleValidationDeadline, "Oracle validation period has expired");

        submission.oracleScore = _score;
        submission.oracleValidated = true;

        // After oracle validation, proceed to community voting
        submission.state = SubmissionState.UnderReview; // Transition back for state management before voting
        bounty.state = BountyState.VotingPending;
        bounty.votingDeadline = block.timestamp.add(bounty.votingDeadline); // Set actual timestamp

        emit OracleValidationReceived(_submissionId, _score);
    }

    /**
     * @summary 9. voteOnSubmission: Allows any AETHER token holder to vote on a submission.
     * @dev Voting power could be tied to AETHER tokens or reputation (future enhancement).
     *      For simplicity, it's 1 address = 1 vote per submission.
     * @param _submissionId The ID of the submission to vote on.
     * @param _isPositive True for a positive vote, false for a negative vote.
     */
    function voteOnSubmission(uint256 _submissionId, bool _isPositive) external nonReentrant {
        Bounty storage bounty = bounties[bounties[_submissionId].bountyId];
        Submission storage submission = bounty.submissions[_submissionId];
        require(submission.id == _submissionId, "Submission does not exist");
        require(bounty.state == BountyState.VotingPending, "Bounty not in voting state");
        require(block.timestamp <= bounty.votingDeadline, "Voting deadline has passed");
        // Additional checks: Prevent voting on own submission.
        // For simplicity, preventing double voting for a single user per submission is not implemented here,
        // but would require a mapping like `mapping(uint256 => mapping(address => bool)) hasVoted;`
        require(_msgSender() != submission.submitter, "Cannot vote on your own submission");

        if (_isPositive) {
            submission.positiveVotes = submission.positiveVotes.add(1);
        } else {
            submission.negativeVotes = submission.negativeVotes.add(1);
        }
        emit SubmissionVoted(_submissionId, _msgSender(), _isPositive);
    }

    /**
     * @summary 10. finalizeBounty: Finalizes a bounty, determines winner, distributes rewards, and mints NFTs.
     * @dev Callable by anyone after voting deadline. Aggregates scores from reviews, oracle, and community votes.
     * @param _bountyId The ID of the bounty to finalize.
     */
    function finalizeBounty(uint256 _bountyId) external nonReentrant {
        Bounty storage bounty = bounties[_bountyId];
        require(bounty.id == _bountyId, "Bounty does not exist");
        require(bounty.state == BountyState.VotingPending, "Bounty not in voting state");
        require(block.timestamp > bounty.votingDeadline, "Voting deadline has not passed");
        require(bounty.rewardAmount > 0, "Bounty has no reward to distribute");

        uint256 winningSubmissionId = 0;
        uint256 highestAggregatedScore = 0;

        for (uint256 i = 0; i < bounty.submissionIds.length; i++) {
            uint256 currentSubmissionId = bounty.submissionIds[i];
            Submission storage currentSubmission = bounty.submissions[currentSubmissionId];

            uint256 currentAggregatedScore = 0;
            // 1. Aggregate reviewer scores (weighted higher, e.g., x3)
            uint256 totalReviewScore = 0;
            uint256 validReviewers = 0;
            for (uint256 j = 0; j < currentSubmission.assignedReviewerStakeIds.length; j++) {
                ReviewerStake storage rStake = reviewerStakeRegistry[currentSubmission.assignedReviewerStakeIds[j]];
                if (currentSubmission.reviews[rStake.reviewerAddress].completed) {
                    totalReviewScore = totalReviewScore.add(currentSubmission.reviews[rStake.reviewerAddress].score);
                    validReviewers = validReviewers.add(1);
                }
            }
            if (validReviewers > 0) {
                currentAggregatedScore = currentAggregatedScore.add(totalReviewScore.div(validReviewers).mul(3));
            }

            // 2. Add oracle score (weighted highest, e.g., x5)
            if (currentSubmission.oracleValidated) {
                currentAggregatedScore = currentAggregatedScore.add(currentSubmission.oracleScore.mul(5));
            }

            // 3. Add community votes (weighted, e.g., x1 for positive, -1 for negative)
            currentAggregatedScore = currentAggregatedScore.add(currentSubmission.positiveVotes.mul(1));
            // Consider penalizing for negative votes or having a threshold
            // currentAggregatedScore = currentAggregatedScore.sub(currentSubmission.negativeVotes.mul(1));

            if (currentAggregatedScore > highestAggregatedScore) {
                highestAggregatedScore = currentAggregatedScore;
                winningSubmissionId = currentSubmissionId;
            }
        }

        if (winningSubmissionId != 0 && highestAggregatedScore > 0) {
            Submission storage winnerSubmission = bounty.submissions[winningSubmissionId];
            winnerSubmission.state = SubmissionState.Approved;
            bounty.winningSubmissionId = winningSubmissionId;
            bounty.state = BountyState.Finalized;

            // Distribute rewards to winner
            AETHER_TOKEN.transfer(winnerSubmission.submitter, bounty.rewardAmount);
            _updateReputation(winnerSubmission.submitter, int256(REPUTATION_FOR_BOUNTY_WIN));

            // Mint AI Model NFT for the winner
            _mintAIModelNFT(winnerSubmission.submitter, _bountyId, winnerSubmission.solutionURI);

            emit BountyFinalized(_bountyId, winningSubmissionId, winnerSubmission.submitter, bounty.rewardAmount);
        } else {
            bounty.state = BountyState.Failed;
            emit BountyFailed(_bountyId);
        }
    }

    /**
     * @summary 11. withdrawBountyFunds: Allows the proposer to withdraw funds if a bounty fails (e.g., no winner or passed deadline).
     * @dev Only callable if the bounty is in a 'Failed' state.
     * @param _bountyId The ID of the failed bounty.
     */
    function withdrawBountyFunds(uint256 _bountyId) external nonReentrant {
        Bounty storage bounty = bounties[_bountyId];
        require(bounty.id == _bountyId, "Bounty does not exist");
        require(bounty.state == BountyState.Failed, "Bounty is not in a failed state");
        require(_msgSender() == bounty.proposer, "Only bounty proposer can withdraw funds");
        require(bounty.rewardAmount > 0, "No funds to withdraw");

        uint256 amountToWithdraw = bounty.rewardAmount;
        bounty.rewardAmount = 0; // Clear reward amount to prevent re-withdrawal
        AETHER_TOKEN.transfer(bounty.proposer, amountToWithdraw);

        emit FundsWithdrawn(_bountyId, bounty.proposer, amountToWithdraw);
    }

    // --- Reviewer Management ---

    /**
     * @summary 12. becomeReviewer: Allows a user to stake AETHER tokens to become a qualified reviewer.
     * @dev Requires minimum reputation and stakes a predefined amount of AETHER.
     */
    function becomeReviewer() external nonReentrant {
        require(reputation[_msgSender()] >= MIN_REPUTATION_FOR_REVIEWER, "Not enough reputation to become a reviewer");
        require(reviewerStakes[_msgSender()] == 0, "Already an active reviewer or stake pending");

        _reputationBadgeTokenIds.increment(); // Use this counter to generate a unique ID for the reviewer stake
        uint256 newReviewerStakeId = _reputationBadgeTokenIds.current();

        AETHER_TOKEN.transferFrom(_msgSender(), address(this), REVIEWER_STAKE_AMOUNT);

        ReviewerStake storage newStake = reviewerStakeRegistry[newReviewerStakeId];
        newStake.id = newReviewerStakeId;
        newStake.reviewerAddress = _msgSender();
        newStake.stakeAmount = REVIEWER_STAKE_AMOUNT;
        newStake.unlockTimestamp = 0; // No unlock pending initially
        newStake.isActive = true;
        newStake.isPenalized = false;

        reviewerStakes[_msgSender()] = newReviewerStakeId;
        activeReviewerStakeIds.push(newReviewerStakeId);

        emit ReviewerStaked(_msgSender(), REVIEWER_STAKE_AMOUNT, newReviewerStakeId);
    }

    /**
     * @summary 13. removeReviewerStake: Allows a reviewer to initiate unstaking.
     * @dev Funds are locked for a cool-down period. Reviewer is no longer active for new assignments.
     */
    function removeReviewerStake() external nonReentrant {
        uint256 reviewerStakeId = reviewerStakes[_msgSender()];
        require(reviewerStakeId != 0, "Not an active reviewer stake");
        ReviewerStake storage stake = reviewerStakeRegistry[reviewerStakeId];
        require(stake.isActive, "Stake is not active or unstake already initiated");
        require(stake.unlockTimestamp == 0, "Unstake already initiated or pending withdrawal");

        stake.isActive = false;
        stake.unlockTimestamp = block.timestamp.add(REVIEWER_STAKE_UNLOCK_PERIOD);

        // Remove from activeReviewerStakeIds for future reviewer assignment
        for (uint256 i = 0; i < activeReviewerStakeIds.length; i++) {
            if (activeReviewerStakeIds[i] == reviewerStakeId) {
                activeReviewerStakeIds[i] = activeReviewerStakeIds[activeReviewerStakeIds.length - 1]; // Swap with last element
                activeReviewerStakeIds.pop(); // Remove last element
                break;
            }
        }

        emit ReviewerUnstaked(_msgSender(), stake.stakeAmount, reviewerStakeId);
    }

    /**
     * @summary 14. claimReviewerStake: Allows a reviewer to claim their unstaked funds after cool-down.
     * @dev Checks for cool-down period completion.
     */
    function claimReviewerStake() external nonReentrant {
        uint252 reviewerStakeId = reviewerStakes[_msgSender()];
        require(reviewerStakeId != 0, "No reviewer stake found");
        ReviewerStake storage stake = reviewerStakeRegistry[reviewerStakeId];
        require(!stake.isActive, "Stake is still active, must initiate unstake first");
        require(stake.unlockTimestamp != 0, "Unstake not initiated");
        require(block.timestamp >= stake.unlockTimestamp, "Cool-down period not over yet");
        require(stake.stakeAmount > 0, "No funds to claim");

        uint256 amount = stake.stakeAmount;
        delete reviewerStakes[_msgSender()]; // Remove reviewer from active reviewer mapping
        delete reviewerStakeRegistry[reviewerStakeId]; // Remove stake entirely

        AETHER_TOKEN.transfer(_msgSender(), amount);

        emit ReviewerStakeClaimed(_msgSender(), amount);
    }

    /**
     * @summary 15. penalizeReviewer: Punishes a reviewer for malicious or low-quality reviews.
     * @dev This function would typically be called by DAO governance after a proposal and vote.
     *      It results in reputation loss and temporary stake locking/penalty.
     * @param _reviewerAddress The address of the reviewer to penalize.
     * @param _submissionId The submission ID associated with the bad review.
     * @param _reason A string explaining the penalty.
     */
    function penalizeReviewer(address _reviewerAddress, uint256 _submissionId, string calldata _reason) external onlyOwner { // Changed to onlyOwner for simplicity in this example
        // In a real DAO, this would be `external _isDaoGovernance`
        uint256 reviewerStakeId = reviewerStakes[_reviewerAddress];
        require(reviewerStakeId != 0, "Not a registered reviewer");
        ReviewerStake storage stake = reviewerStakeRegistry[reviewerStakeId];

        Bounty storage bounty = bounties[bounties[_submissionId].bountyId];
        Submission storage submission = bounty.submissions[_submissionId];
        Review storage review = submission.reviews[_reviewerAddress];
        require(review.completed, "Reviewer did not complete a review for this submission");
        require(!review.penalized, "Reviewer already penalized for this review");

        // Penalize reputation
        _updateReputation(_reviewerAddress, -int256(REPUTATION_PENALTY_FOR_BAD_REVIEW));
        review.penalized = true;

        // Temporarily mark stake as penalized (could also slash or extend unlock time)
        stake.isPenalized = true;
        // A more complex system might also set `stake.unlockTimestamp = block.timestamp.add(penalty_duration);`
        // or slash a percentage of `stake.stakeAmount`.

        emit ReviewerPenalized(_reviewerAddress, reviewerStakeId, _reason);
    }

    // --- Reputation Badge NFT Management (Dynamic NFT) ---

    /**
     * @summary 16. mintReputationBadgeNFT: Mints a unique ERC721 token representing a user's reputation.
     * @dev Callable by anyone, but can only mint one badge per user. This links a reputation badge to a user.
     *      For simplicity, the token ID is linked to the user's address in `ownerOf`.
     * @param _user The address to mint the badge for.
     * @param _initialMetadataURI Initial metadata URI for the badge, reflecting the user's current reputation tier.
     */
    function mintReputationBadgeNFT(address _user, string calldata _initialMetadataURI) external nonReentrant {
        // Ensure a user doesn't already own a badge (this logic assumes one badge per user, using ownerOf to check)
        // A more robust system might store a mapping: `mapping(address => uint256) public userToReputationBadgeTokenId;`
        // and check `userToReputationBadgeTokenId[_user] == 0`.
        require(balanceOf(_user) == 0, "User already has a reputation badge NFT");

        _reputationBadgeTokenIds.increment();
        uint256 newBadgeTokenId = _reputationBadgeTokenIds.current();

        _safeMint(_user, newBadgeTokenId);
        reputationBadgeMetadataURIs[newBadgeTokenId] = _initialMetadataURI;

        emit ReputationBadgeMinted(_user, newBadgeTokenId, reputation[_user]);
    }

    /**
     * @summary 17. upgradeReputationBadge: Updates the metadata URI of a Reputation Badge NFT.
     * @dev Reflects an increase in reputation, making the NFT visually dynamic.
     *      Only the owner of the badge can call this.
     * @param _tokenId The token ID of the Reputation Badge NFT.
     * @param _newMetadataURI The updated metadata URI (e.g., showing a higher reputation tier visual).
     */
    function upgradeReputationBadge(uint256 _tokenId, string calldata _newMetadataURI) external {
        require(ownerOf(_tokenId) == _msgSender(), "Only owner can upgrade their badge");
        require(_tokenId < AI_MODEL_NFT_TOKEN_ID_OFFSET, "Token is not a Reputation Badge NFT");
        require(reputation[_msgSender()] > 0, "Reputation not sufficient for any badge upgrade"); // Basic check

        reputationBadgeMetadataURIs[_tokenId] = _newMetadataURI;
        emit ReputationBadgeUpgraded(_msgSender(), _tokenId, reputation[_msgSender()]);
    }

    // --- AI Model NFT Management (Dynamic NFT) ---

    /**
     * @summary 18. _mintAIModelNFT: Mints an ERC721 token representing a validated AI model or research.
     * @dev Internal function, typically called during bounty finalization for the winning submitter.
     * @param _owner The recipient of the NFT (the winning submitter).
     * @param _bountyId The bounty ID this model/research originated from.
     * @param _initialMetadataURI Initial metadata URI for the AI model NFT, linking to the solution details.
     */
    function _mintAIModelNFT(address _owner, uint256 _bountyId, string calldata _initialMetadataURI) internal {
        _aiModelNFTTokenIds.increment();
        uint256 newModelTokenId = _aiModelNFTTokenIds.current().add(AI_MODEL_NFT_TOKEN_ID_OFFSET); // Ensure unique ID range

        _safeMint(_owner, newModelTokenId);
        aiModelNFTMetadataURIs[newModelTokenId] = _initialMetadataURI;
        aiModelNFTBountyId[newModelTokenId] = _bountyId;

        emit AIModelNFTMinted(_owner, newModelTokenId, _bountyId);
    }

    /**
     * @summary 19. updateAIModelNFTMetadata: Updates the metadata URI of an AI Model NFT.
     * @dev Reflects model improvements, new benchmarks, or further linked research, making it dynamic.
     *      Only the owner of the AI Model NFT can update its metadata.
     * @param _tokenId The token ID of the AI Model NFT.
     * @param _newMetadataURI The updated metadata URI (e.g., linking to an improved model version, new performance report).
     */
    function updateAIModelNFTMetadata(uint256 _tokenId, string calldata _newMetadataURI) external {
        require(ownerOf(_tokenId) == _msgSender(), "Only owner can update their AI Model NFT");
        require(_tokenId >= AI_MODEL_NFT_TOKEN_ID_OFFSET, "Token is not an AI Model NFT");
        require(aiModelNFTMetadataURIs[_tokenId].length > 0, "AI Model NFT metadata not initialized");

        aiModelNFTMetadataURIs[_tokenId] = _newMetadataURI;
        emit AIModelNFTMetadataUpdated(_tokenId, _newMetadataURI);
    }

    /**
     * @summary 20. linkResearchContribution: Links new research/fine-tuning to an existing AIModelNFT.
     * @dev Conceptually, this updates the NFT's underlying data or metadata to reflect further work.
     *      This could either directly update the `_newMetadataURI` or add `_contributionURI` to an array within the NFT's custom metadata.
     *      For this example, it emits an event, and the owner can follow up with `updateAIModelNFTMetadata` if desired.
     * @param _aiModelNFTId The token ID of the AI Model NFT.
     * @param _contributionURI IPFS hash or URL of the new research contribution.
     */
    function linkResearchContribution(uint256 _aiModelNFTId, string calldata _contributionURI) external {
        require(ownerOf(_aiModelNFTId) == _msgSender(), "Only owner can link contributions to their AI Model NFT");
        require(_aiModelNFTId >= AI_MODEL_NFT_TOKEN_ID_OFFSET, "Token is not an AI Model NFT");
        require(aiModelNFTMetadataURIs[_aiModelNFTId].length > 0, "AI Model NFT not found");
        require(bytes(_contributionURI).length > 0, "Contribution URI cannot be empty");

        // A more advanced implementation could:
        // 1. Store an array of contribution URIs within the NFT's state (requiring more complex struct/mapping for NFTs).
        // 2. Automatically trigger an `updateAIModelNFTMetadata` by constructing a new metadata URI that includes this new contribution.
        // For simplicity here, we just emit an event.
        emit ResearchContributionLinked(_aiModelNFTId, _contributionURI);
    }

    // --- View Functions (getters) ---

    /**
     * @summary 21. getBountyDetails: Retrieves comprehensive details about a specific bounty.
     * @param _bountyId The ID of the bounty.
     * @return tuple Containing all relevant bounty information.
     */
    function getBountyDetails(uint256 _bountyId) public view returns (
        uint256 id,
        address proposer,
        string memory title,
        string memory descriptionURI,
        uint256 rewardAmount,
        uint256 submissionDeadline,
        uint256 reviewDeadline,
        uint256 votingDeadline,
        uint256 oracleValidationDeadline,
        BountyState state,
        uint256 winningSubmissionId,
        uint256[] memory submissionIds
    ) {
        Bounty storage bounty = bounties[_bountyId];
        require(bounty.id == _bountyId, "Bounty does not exist");
        return (
            bounty.id,
            bounty.proposer,
            bounty.title,
            bounty.descriptionURI,
            bounty.rewardAmount,
            bounty.submissionDeadline,
            bounty.reviewDeadline,
            bounty.votingDeadline,
            bounty.oracleValidationDeadline,
            bounty.state,
            bounty.winningSubmissionId,
            bounty.submissionIds
        );
    }

    /**
     * @summary 22. getSubmissionDetails: Retrieves details about a specific submission.
     * @param _bountyId The ID of the bounty the submission belongs to.
     * @param _submissionId The ID of the submission.
     * @return tuple Containing all relevant submission information.
     */
    function getSubmissionDetails(uint256 _bountyId, uint256 _submissionId) public view returns (
        uint256 id,
        uint256 bountyId,
        address submitter,
        string memory solutionURI,
        string memory modelIdentifier,
        SubmissionState state,
        uint256[] memory assignedReviewerStakeIds,
        uint256 positiveVotes,
        uint256 negativeVotes,
        uint256 oracleScore,
        bool oracleValidated
    ) {
        Bounty storage bounty = bounties[_bountyId];
        Submission storage submission = bounty.submissions[_submissionId];
        require(submission.id == _submissionId, "Submission does not exist");
        require(submission.bountyId == _bountyId, "Submission does not belong to this bounty");
        return (
            submission.id,
            submission.bountyId,
            submission.submitter,
            submission.solutionURI,
            submission.modelIdentifier,
            submission.state,
            submission.assignedReviewerStakeIds,
            submission.positiveVotes,
            submission.negativeVotes,
            submission.oracleScore,
            submission.oracleValidated
        );
    }

    /**
     * @summary 23. getReviewDetails: Retrieves details about a specific review.
     * @param _bountyId The ID of the bounty the submission belongs to.
     * @param _submissionId The ID of the submission the review belongs to.
     * @param _reviewer The address of the reviewer.
     * @return tuple Containing all relevant review information.
     */
    function getReviewDetails(uint256 _bountyId, uint256 _submissionId, address _reviewer) public view returns (
        uint256 submissionId,
        address reviewer,
        string memory reviewURI,
        uint256 score,
        bool completed,
        bool penalized
    ) {
        Bounty storage bounty = bounties[_bountyId];
        Submission storage submission = bounty.submissions[_submissionId];
        Review storage review = submission.reviews[_reviewer];
        require(review.submissionId == _submissionId, "Review does not exist for this reviewer and submission");
        return (
            review.submissionId,
            review.reviewer,
            review.reviewURI,
            review.score,
            review.completed,
            review.penalized
        );
    }

    /**
     * @summary 24. getReputation: Returns the reputation score of a user.
     * @param _user The address of the user.
     * @return uint256 The reputation score.
     */
    function getReputation(address _user) public view returns (uint256) {
        return reputation[_user];
    }

    /**
     * @summary 25. getReviewerStakeDetails: Retrieves details about a reviewer's stake.
     * @param _reviewerAddress The address of the reviewer.
     * @return tuple Containing stake ID, amount, unlock timestamp, active status, and penalized status.
     */
    function getReviewerStakeDetails(address _reviewerAddress) public view returns (
        uint256 id,
        address reviewerAddress,
        uint256 stakeAmount,
        uint256 unlockTimestamp,
        bool isActive,
        bool isPenalized
    ) {
        uint256 reviewerStakeId = reviewerStakes[_reviewerAddress];
        require(reviewerStakeId != 0, "No reviewer stake found for this address");
        ReviewerStake storage stake = reviewerStakeRegistry[reviewerStakeId];
        return (
            stake.id,
            stake.reviewerAddress,
            stake.stakeAmount,
            stake.unlockTimestamp,
            stake.isActive,
            stake.isPenalized
        );
    }

    // --- ERC721 Metadata Interface ---
    // Although we override tokenURI, for OpenSea compatibility, we might want to also include a base URI
    function _baseURI() internal pure override returns (string memory) {
        // This base URI would ideally point to a gateway that serves the JSON metadata for all NFTs,
        // dynamically generating it based on tokenID and the contract's state.
        return "ipfs://Qmb3A849c7Xj4G8c7Z9X6b4D7F8A7D9E0F1A2B3C4D5F6/"; // Placeholder base URI for NFTs
    }
}

// --- Minimalistic AETHER Token for local testing (not part of the main submission) ---
// This contract would be deployed separately.
contract AetheriaToken is ERC20("AetheriaToken", "AETHER") {
    constructor() {
        _mint(msg.sender, 1_000_000_000 * (10 ** 18)); // Mint 1 billion tokens to deployer for testing
    }
}
```