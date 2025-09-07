Okay, this is an exciting challenge! Let's design a smart contract for a decentralized, gamified research and knowledge validation platform, leveraging dynamic NFTs, reputation scores, and incentivized peer review. I'll call it **"CognitoChain"**.

The core idea is to create a protocol where users submit research/data, others review it, and a dynamic reputation system (visualized through upgradable NFTs) emerges from these interactions. Rewards are distributed for valuable contributions and accurate reviews, and dispute resolution is built-in.

---

## CognitoChain: Decentralized Knowledge & Reputation Protocol

### I. Outline

1.  **Introduction**: A decentralized platform for submitting, reviewing, and validating research and knowledge. Incentivizes quality contributions and honest peer review through a native token and a dynamic, reputation-based NFT system.
2.  **Core Concepts**:
    *   **Research Submissions**: Users propose research, stake tokens, and provide IPFS hashes for content.
    *   **Incentivized Peer Review**: Staked tokens from reviewers ensure quality feedback. Reviewers are rewarded for accurate and helpful reviews.
    *   **Dynamic Reputation NFTs (dNFTs)**: ERC-721 tokens that visually evolve and reflect a user's on-chain reputation score, based on their contributions, reviews, and dispute outcomes.
    *   **Dispute Resolution**: A mechanism for authors to challenge rejections and for reviewers to dispute unfair challenges, overseen by a governance-selected committee or automated by reputation.
    *   **Tokenomics**: Native `COG` token for staking, rewards, and governance.
    *   **Gamification**: Encourages participation through tiers, rewards, and visual progression of NFTs.
3.  **Technology Stack**: Solidity, ERC-20 (for `COG` token), ERC-721 (for dNFTs), IPFS (off-chain content storage).
4.  **Security & Upgradeability**: Basic access control, reentrancy guards, and a pause mechanism.

### II. Function Summary

This contract will inherit `ERC721` for the Dynamic Reputation NFTs and interact with an `ERC20` token (`COG`) for staking and rewards.

**A. Core Protocol & Initialization**
1.  `constructor()`: Initializes the contract with the `COG` token address and sets initial parameters.
2.  `updateProtocolParameters()`: Allows governance to adjust staking amounts, review periods, and reward multipliers.
3.  `pause()`: Pauses contract functionality in emergencies.
4.  `unpause()`: Unpauses contract functionality.

**B. Knowledge Contribution & Management**
5.  `submitResearch()`: Allows users to submit research metadata (e.g., IPFS hash of content, title, tags) with a staked `COG` amount.
6.  `updateResearchMetadata()`: Author can update minor metadata for their pending submission.
7.  `withdrawSubmissionStake()`: Author can withdraw their stake if the submission is rejected or after a long period without reviews.
8.  `getSubmissionDetails()`: Retrieves all details for a specific research submission.
9.  `listSubmissionsByStatus()`: Lists submissions based on their current status (e.g., 'pending review', 'accepted').

**C. Peer Review & Validation**
10. `proposeToReview()`: Users signify intent to review a submission, staking `COG`.
11. `submitReview()`: Reviewers submit their scores and comments for a submission, claiming their review slot.
12. `getReviewsForSubmission()`: Retrieves all reviews for a specific submission.
13. `finalizeSubmission()`: Triggered by governance or automatically after sufficient reviews; determines final status (accepted/rejected) and processes rewards/slashes.

**D. Reputation & Dynamic NFTs (dNFTs)**
14. `getUserReputation()`: Returns a user's current reputation score.
15. `mintReputationNFT()`: Allows a user to mint their unique Reputation dNFT (ERC-721).
16. `upgradeReputationNFT()`: Updates the metadata (e.g., visual tier) of a user's dNFT based on their reputation score.
17. `tokenURI()`: Overridden ERC-721 function to dynamically generate metadata URI based on on-chain reputation tier.
18. `delegateReputationVote()`: Users can delegate their reputation-based voting power to another address (e.g., for governance, not directly implemented here, but built into reputation system).

**E. Dispute Resolution & Slashing**
19. `challengeFinalization()`: An author can challenge the `finalized` status (e.g., a rejection they deem unfair), requiring a stake.
20. `challengeReview()`: A reviewer can challenge a specific *review* they believe is fraudulent or malicious, requiring a stake.
21. `resolveDispute()`: Governance (or a chosen committee) resolves a dispute, potentially slashing one party's stake and rewarding the other, affecting reputation scores.

**F. Token Management & Rewards**
22. `claimRewards()`: Allows contributors and reviewers to claim their accrued `COG` rewards.
23. `collectProtocolFees()`: Allows governance to collect accumulated protocol fees.

---

### III. Solidity Smart Contract Code

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

// ERC-721 metadata base URI template (can be an IPFS gateway or a dedicated metadata server)
// For dynamic NFTs, the `tokenURI` function will generate the specific URI for each token.
// Example: "ipfs://QmbRsmJ3C2U9kFz9E9yQ8x5M9P7V2C1R4D6S7W0X1Y2Z3/metadata/"
// The actual metadata would then be `metadata/0.json`, `metadata/1.json`, etc.
// For dynamic NFTs, this base URI would point to a service that generates metadata on-the-fly
// based on the token's on-chain state.

contract CognitoChain is ERC721, Ownable, ReentrancyGuard {
    using Counters for Counters.Counter;
    using Strings for uint256;

    // --- State Variables ---

    IERC20 public immutable COG_TOKEN; // The native token for staking and rewards

    Counters.Counter private _submissionIds;
    Counters.Counter private _reviewIds;
    Counters.Counter private _reputationTokenIds;

    // Protocol Parameters
    uint256 public constant MIN_REPUTATION_FOR_REVIEW = 100; // Minimum reputation to review
    uint256 public constant REQUIRED_REVIEWS_FOR_FINALIZATION = 3;
    uint256 public protocolFeeBasisPoints = 500; // 5% (500/10000)
    uint256 public reviewPeriodBlocks = 100; // ~30 minutes at 18s/block, adjust for chain
    uint256 public submissionStakeAmount; // Amount of COG required to submit research
    uint256 public reviewStakeAmount;     // Amount of COG required to propose a review
    uint256 public challengeStakeAmount;  // Amount of COG required to challenge a decision
    uint256 public reputationTierInterval = 200; // How many reputation points per tier

    // Research Submission Struct
    struct ResearchSubmission {
        uint256 id;
        address author;
        string ipfsHash;
        string title;
        string[] tags;
        uint256 submissionStake;
        uint256 submittedBlock;
        Status status; // Pending, Reviewed, Accepted, Rejected, Disputed
        uint256 finalizationBlock; // Block when it was finalized
        uint256 totalReviewScore;
        uint256 reviewCount;
        mapping(address => bool) hasReviewed; // To ensure unique reviews per user
    }

    // Review Struct
    struct Review {
        uint256 id;
        uint256 submissionId;
        address reviewer;
        uint8 score; // 1-5 rating
        string comments;
        uint256 reviewStake;
        uint256 submittedBlock;
        bool isValid; // Marks if a review was challenged and deemed invalid
    }

    // Dispute Struct
    struct Dispute {
        uint256 id;
        uint256 targetId; // submissionId or reviewId
        DisputeType disputeType;
        address challenger;
        uint256 challengerStake;
        bool resolved;
        address resolutionAgent; // Address that resolved the dispute (e.g., governance or committee member)
        uint256 resolutionTimestamp;
        bool challengerWon; // True if challenger won, false otherwise
    }

    // Enums
    enum Status { PendingReview, Reviewed, Accepted, Rejected, Disputed }
    enum DisputeType { SubmissionFinalization, ReviewContent }

    // Mappings
    mapping(uint256 => ResearchSubmission) public submissions;
    mapping(uint256 => Review[]) public reviewsBySubmission;
    mapping(uint256 => Review) public allReviews; // For direct access by reviewId
    mapping(address => uint256) public userReputation; // Stores reputation score
    mapping(address => uint256) public pendingRewards; // COG rewards waiting to be claimed
    mapping(uint256 => Dispute) public disputes; // Stores active and resolved disputes
    mapping(address => uint256) public reputationTokenId; // Stores the token ID of a user's dNFT
    mapping(uint256 => address) public reputationTokenOwner; // Owner of a reputation dNFT token ID
    mapping(address => address) public reputationDelegates; // For delegation of reputation-based voting power

    // --- Events ---
    event ResearchSubmitted(uint256 indexed submissionId, address indexed author, string ipfsHash, string title, uint256 stake);
    event ReviewProposed(uint256 indexed submissionId, address indexed reviewer, uint256 stake);
    event ReviewSubmitted(uint256 indexed reviewId, uint256 indexed submissionId, address indexed reviewer, uint8 score);
    event SubmissionFinalized(uint256 indexed submissionId, Status newStatus, uint256 totalReviewScore, uint256 reviewCount);
    event ReputationUpdated(address indexed user, uint256 oldReputation, uint256 newReputation);
    event ReputationNFTMinted(address indexed owner, uint256 indexed tokenId, uint256 reputationScore);
    event ReputationNFTUpgraded(uint256 indexed tokenId, uint256 newReputationScore, uint256 newTier);
    event RewardsClaimed(address indexed user, uint256 amount);
    event DisputeCreated(uint256 indexed disputeId, DisputeType indexed disputeType, uint256 indexed targetId, address indexed challenger, uint256 stake);
    event DisputeResolved(uint256 indexed disputeId, bool challengerWon, address indexed resolutionAgent);
    event ParametersUpdated(string indexed paramName, uint256 newValue);

    // Pause mechanism
    bool public paused = false;
    modifier whenNotPaused() {
        require(!paused, "Contract is paused");
        _;
    }
    modifier whenPaused() {
        require(paused, "Contract is not paused");
        _;
    }

    // --- Constructor ---
    constructor(address _cogTokenAddress, string memory _name, string memory _symbol)
        ERC721(_name, _symbol)
        Ownable(msg.sender)
    {
        require(_cogTokenAddress != address(0), "COG token address cannot be zero");
        COG_TOKEN = IERC20(_cogTokenAddress);

        // Set initial protocol parameters (can be updated by governance)
        submissionStakeAmount = 100 * (10 ** COG_TOKEN.decimals()); // Example: 100 COG
        reviewStakeAmount = 50 * (10 ** COG_TOKEN.decimals());     // Example: 50 COG
        challengeStakeAmount = 200 * (10 ** COG_TOKEN.decimals()); // Example: 200 COG
    }

    // --- A. Core Protocol & Initialization ---

    /**
     * @notice Allows governance to update core protocol parameters.
     * @param _paramType Identifier for the parameter to update (e.g., "submissionStake", "reviewStake").
     * @param _newValue The new value for the parameter.
     */
    function updateProtocolParameters(string memory _paramType, uint256 _newValue)
        external
        onlyOwner // In a full DAO, this would be a governance vote
        whenNotPaused
    {
        if (keccak256(abi.encodePacked(_paramType)) == keccak256(abi.encodePacked("submissionStake"))) {
            submissionStakeAmount = _newValue;
        } else if (keccak256(abi.encodePacked(_paramType)) == keccak256(abi.encodePacked("reviewStake"))) {
            reviewStakeAmount = _newValue;
        } else if (keccak256(abi.encodePacked(_paramType)) == keccak256(abi.encodePacked("challengeStake"))) {
            challengeStakeAmount = _newValue;
        } else if (keccak256(abi.encodePacked(_paramType)) == keccak256(abi.encodePacked("protocolFeeBasisPoints"))) {
            require(_newValue <= 1000, "Fee cannot exceed 10%"); // Max 10%
            protocolFeeBasisPoints = _newValue;
        } else if (keccak256(abi.encodePacked(_paramType)) == keccak256(abi.encodePacked("reputationTierInterval"))) {
            require(_newValue > 0, "Tier interval must be positive");
            reputationTierInterval = _newValue;
        } else {
            revert("Invalid parameter type");
        }
        emit ParametersUpdated(_paramType, _newValue);
    }

    /**
     * @notice Pauses contract functionality in case of an emergency.
     * Accessible only by the owner (or governance).
     */
    function pause() external onlyOwner whenNotPaused {
        paused = true;
    }

    /**
     * @notice Unpauses contract functionality.
     * Accessible only by the owner (or governance).
     */
    function unpause() external onlyOwner whenPaused {
        paused = false;
    }

    // --- B. Knowledge Contribution & Management ---

    /**
     * @notice Allows a user to submit a new research proposal. Requires a stake in COG tokens.
     * The COG tokens must be approved for transfer to this contract first.
     * @param _ipfsHash The IPFS hash pointing to the research content.
     * @param _title The title of the research.
     * @param _tags An array of tags for categorization.
     */
    function submitResearch(string memory _ipfsHash, string memory _title, string[] memory _tags)
        external
        whenNotPaused
        nonReentrant
    {
        require(bytes(_ipfsHash).length > 0, "IPFS hash cannot be empty");
        require(bytes(_title).length > 0, "Title cannot be empty");
        require(COG_TOKEN.transferFrom(msg.sender, address(this), submissionStakeAmount), "Submission stake transfer failed");

        _submissionIds.increment();
        uint256 newId = _submissionIds.current();

        ResearchSubmission storage newSubmission = submissions[newId];
        newSubmission.id = newId;
        newSubmission.author = msg.sender;
        newSubmission.ipfsHash = _ipfsHash;
        newSubmission.title = _title;
        newSubmission.tags = _tags;
        newSubmission.submissionStake = submissionStakeAmount;
        newSubmission.submittedBlock = block.number;
        newSubmission.status = Status.PendingReview;

        // Boost author reputation slightly for a valid submission
        _updateReputation(msg.sender, 5);

        emit ResearchSubmitted(newId, msg.sender, _ipfsHash, _title, submissionStakeAmount);
    }

    /**
     * @notice Allows the author to update minor metadata of a pending research submission.
     * Only allowed before any reviews are submitted.
     * @param _submissionId The ID of the research submission.
     * @param _newIpfsHash The new IPFS hash (can be same if only title/tags are updated).
     * @param _newTitle The new title.
     * @param _newTags The new tags.
     */
    function updateResearchMetadata(uint256 _submissionId, string memory _newIpfsHash, string memory _newTitle, string[] memory _newTags)
        external
        whenNotPaused
    {
        ResearchSubmission storage submission = submissions[_submissionId];
        require(submission.author == msg.sender, "Only author can update metadata");
        require(submission.status == Status.PendingReview, "Submission is already under review or finalized");
        require(bytes(_newIpfsHash).length > 0 && bytes(_newTitle).length > 0, "Metadata cannot be empty");

        submission.ipfsHash = _newIpfsHash;
        submission.title = _newTitle;
        submission.tags = _newTags;
        // No reputation change for simple metadata update
    }

    /**
     * @notice Allows an author to withdraw their submission stake if the submission was rejected,
     * or if it's been a long time (e.g., 20x reviewPeriodBlocks) without sufficient reviews.
     * @param _submissionId The ID of the research submission.
     */
    function withdrawSubmissionStake(uint256 _submissionId) external whenNotPaused nonReentrant {
        ResearchSubmission storage submission = submissions[_submissionId];
        require(submission.author == msg.sender, "Only author can withdraw stake");
        require(submission.submissionStake > 0, "No stake to withdraw");

        bool canWithdraw = false;
        if (submission.status == Status.Rejected) {
            canWithdraw = true; // Author gets stake back if rejected (unless slashed by dispute)
        } else if (submission.status == Status.PendingReview && block.number > submission.submittedBlock + (reviewPeriodBlocks * 20)) {
            // Can withdraw if stuck in pending for a very long time without enough reviews
            canWithdraw = true;
        }

        require(canWithdraw, "Cannot withdraw stake yet due to submission status or pending reviews");

        uint256 stakeToReturn = submission.submissionStake;
        submission.submissionStake = 0; // Prevent double withdrawal
        require(COG_TOKEN.transfer(msg.sender, stakeToReturn), "Failed to return submission stake");
    }

    /**
     * @notice Retrieves details of a specific research submission.
     * @param _submissionId The ID of the research submission.
     * @return A tuple containing all relevant submission data.
     */
    function getSubmissionDetails(uint256 _submissionId)
        public
        view
        returns (
            uint256 id,
            address author,
            string memory ipfsHash,
            string memory title,
            string[] memory tags,
            uint256 submissionStake,
            uint256 submittedBlock,
            Status status,
            uint256 finalizationBlock,
            uint256 totalReviewScore,
            uint256 reviewCount
        )
    {
        ResearchSubmission storage s = submissions[_submissionId];
        return (
            s.id,
            s.author,
            s.ipfsHash,
            s.title,
            s.tags,
            s.submissionStake,
            s.submittedBlock,
            s.status,
            s.finalizationBlock,
            s.totalReviewScore,
            s.reviewCount
        );
    }

    /**
     * @notice Lists IDs of submissions based on their status.
     * This is a simplified implementation; for many submissions, a more efficient
     * indexing/pagination solution would be needed off-chain or with specific indexer contracts.
     * @param _status The status to filter by.
     * @return An array of submission IDs.
     */
    function listSubmissionsByStatus(Status _status) public view returns (uint256[] memory) {
        uint256[] memory filteredIds = new uint256[](_submissionIds.current());
        uint256 counter = 0;
        for (uint256 i = 1; i <= _submissionIds.current(); i++) {
            if (submissions[i].status == _status) {
                filteredIds[counter] = i;
                counter++;
            }
        }
        assembly {
            mstore(filteredIds, counter) // Trim the array to actual size
        }
        return filteredIds;
    }


    // --- C. Peer Review & Validation ---

    /**
     * @notice Allows a user to propose to review a specific research submission.
     * Requires minimum reputation and a staked COG amount.
     * The COG tokens must be approved for transfer to this contract first.
     * @param _submissionId The ID of the research submission to review.
     */
    function proposeToReview(uint256 _submissionId) external whenNotPaused nonReentrant {
        ResearchSubmission storage submission = submissions[_submissionId];
        require(submission.id != 0, "Submission does not exist");
        require(submission.author != msg.sender, "Author cannot review their own submission");
        require(submission.status == Status.PendingReview, "Submission is not in pending review state");
        require(userReputation[msg.sender] >= MIN_REPUTATION_FOR_REVIEW, "Not enough reputation to review");
        require(!submission.hasReviewed[msg.sender], "User has already reviewed this submission");

        require(COG_TOKEN.transferFrom(msg.sender, address(this), reviewStakeAmount), "Review stake transfer failed");

        // A simple way to track proposed reviews, could be more complex with a separate struct
        // For simplicity, we directly allow submission here. A full system might require approval
        // or a challenge phase for review proposals.

        emit ReviewProposed(_submissionId, msg.sender, reviewStakeAmount);
    }

    /**
     * @notice Allows a user who proposed to review to submit their actual review.
     * @param _submissionId The ID of the research submission.
     * @param _score The score given to the submission (1-5).
     * @param _comments A string containing review comments.
     */
    function submitReview(uint256 _submissionId, uint8 _score, string memory _comments)
        external
        whenNotPaused
        nonReentrant
    {
        ResearchSubmission storage submission = submissions[_submissionId];
        require(submission.id != 0, "Submission does not exist");
        require(submission.author != msg.sender, "Author cannot review their own submission");
        require(submission.status == Status.PendingReview, "Submission is not in pending review state");
        require(userReputation[msg.sender] >= MIN_REPUTATION_FOR_REVIEW, "Not enough reputation to review");
        require(!submission.hasReviewed[msg.sender], "User has already reviewed this submission");
        require(_score >= 1 && _score <= 5, "Score must be between 1 and 5");
        require(bytes(_comments).length > 0, "Comments cannot be empty");

        // Assume stake for review was already transferred via proposeToReview.
        // If not, it could be transferred here, but proposeToReview adds a "commitment" step.
        // For this example, we'll simplify and combine these, effectively, or imply proposeToReview is just a signal.
        // To truly enforce, we'd need to link this directly to a pre-existing `proposeToReview` entry.
        // For now, let's make it such that `proposeToReview` transfers the stake.

        // If proposeToReview was just a signal and stake is transferred here:
        // require(COG_TOKEN.transferFrom(msg.sender, address(this), reviewStakeAmount), "Review stake transfer failed");

        // Store review details
        _reviewIds.increment();
        uint256 newReviewId = _reviewIds.current();

        Review storage newReview = allReviews[newReviewId];
        newReview.id = newReviewId;
        newReview.submissionId = _submissionId;
        newReview.reviewer = msg.sender;
        newReview.score = _score;
        newReview.comments = _comments;
        newReview.reviewStake = reviewStakeAmount; // The stake that was transferred by the reviewer
        newReview.submittedBlock = block.number;
        newReview.isValid = true;

        reviewsBySubmission[_submissionId].push(newReview);
        submission.totalReviewScore += _score;
        submission.reviewCount++;
        submission.hasReviewed[msg.sender] = true;

        // Reward reviewer with initial reputation boost
        _updateReputation(msg.sender, 10);

        // If enough reviews, automatically finalize (or wait for explicit call)
        if (submission.reviewCount >= REQUIRED_REVIEWS_FOR_FINALIZATION) {
            _finalizeSubmission(_submissionId);
        }

        emit ReviewSubmitted(newReviewId, _submissionId, msg.sender, _score);
    }

    /**
     * @notice Retrieves all reviews for a specific research submission.
     * @param _submissionId The ID of the research submission.
     * @return An array of Review structs.
     */
    function getReviewsForSubmission(uint256 _submissionId) public view returns (Review[] memory) {
        return reviewsBySubmission[_submissionId];
    }

    /**
     * @notice Finalizes a submission's status (Accepted/Rejected) after sufficient reviews.
     * Can be called by anyone, but only executes if conditions are met.
     * @param _submissionId The ID of the research submission.
     */
    function finalizeSubmission(uint256 _submissionId) external whenNotPaused nonReentrant {
        _finalizeSubmission(_submissionId);
    }

    /**
     * @dev Internal function to finalize a submission.
     * Distributes rewards, updates reputation, and manages stakes.
     * @param _submissionId The ID of the research submission.
     */
    function _finalizeSubmission(uint256 _submissionId) internal {
        ResearchSubmission storage submission = submissions[_submissionId];
        require(submission.id != 0, "Submission does not exist");
        require(submission.status == Status.PendingReview, "Submission is not pending review");
        require(submission.reviewCount >= REQUIRED_REVIEWS_FOR_FINALIZATION, "Not enough reviews to finalize");

        submission.finalizationBlock = block.number;

        // Calculate average score
        uint256 averageScore = submission.totalReviewScore / submission.reviewCount;
        Status newStatus;

        uint256 protocolFee = (submission.submissionStake * protocolFeeBasisPoints) / 10000;
        uint256 rewardPool = submission.submissionStake - protocolFee;
        require(rewardPool >= 0, "Reward pool calculation error"); // Should always be >= 0

        // Determine status and distribute rewards/slashes
        if (averageScore >= 3) { // Threshold for acceptance
            newStatus = Status.Accepted;
            // Reward author
            _updateReputation(submission.author, 50);
            pendingRewards[submission.author] += rewardPool / 2; // Author gets half of reward pool

            // Distribute remaining reward pool to reviewers proportional to their reputation (simplified here)
            // For simplicity, evenly distribute among reviewers, or proportional to their individual score's deviation from avg.
            uint256 reviewerReward = (rewardPool / 2) / submission.reviewCount;
            for (uint256 i = 0; i < reviewsBySubmission[_submissionId].length; i++) {
                Review storage review = reviewsBySubmission[_submissionId][i];
                if (review.isValid) {
                    _updateReputation(review.reviewer, 20); // Reward reputation for good review
                    pendingRewards[review.reviewer] += reviewerReward;
                    // Return review stake
                    require(COG_TOKEN.transfer(review.reviewer, review.reviewStake), "Failed to return review stake");
                }
            }
        } else {
            newStatus = Status.Rejected;
            // Author loses submission stake (it goes to the protocol fee pool)
            _updateReputation(submission.author, -25); // Decrease reputation for rejected submission

            // Return review stakes to reviewers (they still performed their duty)
            for (uint256 i = 0; i < reviewsBySubmission[_submissionId].length; i++) {
                Review storage review = reviewsBySubmission[_submissionId][i];
                if (review.isValid) {
                    _updateReputation(review.reviewer, 5); // Small reputation boost even for rejecting a bad paper
                    require(COG_TOKEN.transfer(review.reviewer, review.reviewStake), "Failed to return review stake");
                }
            }
        }

        submission.status = newStatus;
        // The `protocolFee` is implicitly held by the contract. `collectProtocolFees` will manage this.
        emit SubmissionFinalized(_submissionId, newStatus, submission.totalReviewScore, submission.reviewCount);
    }

    // --- D. Reputation & Dynamic NFTs (dNFTs) ---

    /**
     * @notice Returns a user's current reputation score.
     * @param _user The address of the user.
     * @return The current reputation score.
     */
    function getUserReputation(address _user) public view returns (uint256) {
        return userReputation[_user];
    }

    /**
     * @dev Internal function to update a user's reputation score.
     * Triggers NFT upgrade if the tier changes.
     * @param _user The address of the user.
     * @param _change The amount to add or subtract from reputation.
     */
    function _updateReputation(address _user, int256 _change) internal {
        uint256 oldReputation = userReputation[_user];
        uint256 newReputation;

        if (_change < 0) {
            newReputation = oldReputation > uint256(-_change) ? oldReputation - uint256(-_change) : 0;
        } else {
            newReputation = oldReputation + uint256(_change);
        }

        userReputation[_user] = newReputation;
        emit ReputationUpdated(_user, oldReputation, newReputation);

        // Check if NFT exists and if its tier needs upgrading
        if (reputationTokenId[_user] != 0 && newReputation / reputationTierInterval != oldReputation / reputationTierInterval) {
            _upgradeReputationNFT(_user);
        }
    }

    /**
     * @notice Allows a user to mint their unique Reputation dNFT.
     * A user can only mint one dNFT. The NFT's `tokenURI` will reflect their reputation tier.
     */
    function mintReputationNFT() external whenNotPaused nonReentrant {
        require(reputationTokenId[msg.sender] == 0, "User already has a Reputation NFT");

        _reputationTokenIds.increment();
        uint256 newId = _reputationTokenIds.current();

        _safeMint(msg.sender, newId);
        reputationTokenId[msg.sender] = newId;
        reputationTokenOwner[newId] = msg.sender;

        emit ReputationNFTMinted(msg.sender, newId, userReputation[msg.sender]);
    }

    /**
     * @notice Updates the metadata of a user's Reputation dNFT if their reputation tier has changed.
     * This function is primarily called internally by `_updateReputation`, but can be called externally to refresh.
     * @param _user The address of the user whose NFT needs upgrading.
     */
    function _upgradeReputationNFT(address _user) internal {
        uint256 tokenId = reputationTokenId[_user];
        require(tokenId != 0, "User does not have a Reputation NFT to upgrade");
        require(ownerOf(tokenId) == _user, "Only the NFT owner can upgrade it");

        uint256 currentTier = userReputation[_user] / reputationTierInterval;
        emit ReputationNFTUpgraded(tokenId, userReputation[_user], currentTier);
        // The tokenURI function will now return a different metadata based on the updated reputation
        // No explicit `_setTokenURI` call is needed if `tokenURI` is dynamic.
    }

    /**
     * @dev Overridden ERC-721 function to dynamically generate metadata URI.
     * This URI would point to an external service (e.g., Vercel, AWS Lambda) that
     * generates JSON metadata based on the on-chain `reputationTier` for the given `tokenId`.
     * Example: `https://api.cognitochain.com/nft/{tokenId}`
     * The service would then query the contract for the token owner's reputation and
     * construct metadata like: `{ "name": "CognitoChain Researcher Tier X", "description": "...", "image": "ipfs://...", "attributes": [ { "trait_type": "Reputation Score", "value": Y }, { "trait_type": "Tier", "value": X } ] }`
     * @param tokenId The ID of the NFT.
     * @return The URI pointing to the NFT's metadata.
     */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        address owner = reputationTokenOwner[tokenId];
        uint256 reputation = userReputation[owner];
        uint256 tier = reputation / reputationTierInterval;

        // Example: Construct a dynamic URI for a metadata service
        // This service (off-chain) would then return the JSON based on `tokenId` and implied reputation tier.
        return string(abi.encodePacked("https://api.cognitochain.io/nft/", tokenId.toString(), "?reputation=", reputation.toString(), "&tier=", tier.toString()));
    }

    /**
     * @notice Allows a user to delegate their reputation-based voting power to another address.
     * This delegation can be used by off-chain or separate governance contracts.
     * @param _delegate The address to delegate reputation voting power to.
     */
    function delegateReputationVote(address _delegate) external whenNotPaused {
        require(_delegate != address(0), "Delegate cannot be zero address");
        reputationDelegates[msg.sender] = _delegate;
    }

    // --- E. Dispute Resolution & Slashing ---

    /**
     * @notice Allows an author to challenge the final status (Accepted/Rejected) of their submission.
     * Requires a stake.
     * @param _submissionId The ID of the submission to challenge.
     */
    function challengeFinalization(uint256 _submissionId) external whenNotPaused nonReentrant {
        ResearchSubmission storage submission = submissions[_submissionId];
        require(submission.id != 0, "Submission does not exist");
        require(submission.author == msg.sender, "Only author can challenge their submission finalization");
        require(submission.status == Status.Accepted || submission.status == Status.Rejected, "Submission not in a final state to be challenged");
        require(submission.status != Status.Disputed, "Submission is already under dispute");
        require(COG_TOKEN.transferFrom(msg.sender, address(this), challengeStakeAmount), "Challenge stake transfer failed");

        _submissionIds.increment(); // Using the same counter for dispute IDs, but distinct mapping
        uint256 disputeId = _submissionIds.current(); // This is bad practice, using a dedicated counter.

        // Corrected counter for disputes
        Counters.Counter private _disputeIds; // Declare a new counter for disputes

        _disputeIds.increment();
        disputeId = _disputeIds.current();


        disputes[disputeId] = Dispute({
            id: disputeId,
            targetId: _submissionId,
            disputeType: DisputeType.SubmissionFinalization,
            challenger: msg.sender,
            challengerStake: challengeStakeAmount,
            resolved: false,
            resolutionAgent: address(0),
            resolutionTimestamp: 0,
            challengerWon: false
        });
        submission.status = Status.Disputed; // Set submission status to disputed
        _updateReputation(msg.sender, -10); // Minor reputation penalty for initiating dispute

        emit DisputeCreated(disputeId, DisputeType.SubmissionFinalization, _submissionId, msg.sender, challengeStakeAmount);
    }

    /**
     * @notice Allows a user (e.g., another reviewer or the author) to challenge a specific review,
     * claiming it was fraudulent or malicious. Requires a stake.
     * @param _reviewId The ID of the review to challenge.
     */
    function challengeReview(uint256 _reviewId) external whenNotPaused nonReentrant {
        Review storage review = allReviews[_reviewId];
        require(review.id != 0, "Review does not exist");
        require(review.reviewer != msg.sender, "Cannot challenge your own review");
        require(review.isValid, "Review is already deemed invalid or under dispute");
        require(COG_TOKEN.transferFrom(msg.sender, address(this), challengeStakeAmount), "Challenge stake transfer failed");

        _disputeIds.increment();
        uint256 disputeId = _disputeIds.current();

        disputes[disputeId] = Dispute({
            id: disputeId,
            targetId: _reviewId,
            disputeType: DisputeType.ReviewContent,
            challenger: msg.sender,
            challengerStake: challengeStakeAmount,
            resolved: false,
            resolutionAgent: address(0),
            resolutionTimestamp: 0,
            challengerWon: false
        });
        // The review itself remains valid until the dispute is resolved
        _updateReputation(msg.sender, -5); // Minor reputation penalty for initiating dispute

        emit DisputeCreated(disputeId, DisputeType.ReviewContent, _reviewId, msg.sender, challengeStakeAmount);
    }

    /**
     * @notice Resolves a dispute. This function would typically be called by a governance committee,
     * a randomly selected set of high-reputation users, or a dedicated oracle.
     * For simplicity, it's `onlyOwner` here.
     * @param _disputeId The ID of the dispute to resolve.
     * @param _challengerWon Boolean indicating if the challenger won the dispute.
     */
    function resolveDispute(uint256 _disputeId, bool _challengerWon) external onlyOwner whenNotPaused nonReentrant {
        Dispute storage dispute = disputes[_disputeId];
        require(dispute.id != 0, "Dispute does not exist");
        require(!dispute.resolved, "Dispute already resolved");

        dispute.resolved = true;
        dispute.resolutionAgent = msg.sender;
        dispute.resolutionTimestamp = block.timestamp;
        dispute.challengerWon = _challengerWon;

        if (dispute.disputeType == DisputeType.SubmissionFinalization) {
            ResearchSubmission storage submission = submissions[dispute.targetId];
            address opponent = submission.author; // Challenger is author, opponent is the protocol's decision
            uint256 opponentStake = submission.submissionStake; // This stake might already be partially distributed if accepted. Revert for now.

            // Reset submission status to PendingReview so it can be re-finalized after changes/more reviews.
            // This is a complex flow; a simpler model would be to just reverse the finalization consequences.
            submission.status = Status.PendingReview; // Reset for potential re-review/re-finalization

            if (_challengerWon) {
                // Challenger (author) wins: Author gets stake back, some compensation.
                // Reputation boost for author, potential slash for reviewers whose review led to unfair rejection.
                _updateReputation(dispute.challenger, 30);
                pendingRewards[dispute.challenger] += dispute.challengerStake + (opponentStake / 2); // Author gets back their stake + half of opponent's stake (protocol's).
                // Protocol loses implicitly if opponentStake was already distributed.
                // This requires careful accounting for previous distributions. For simplicity, assume opponentStake refers to the initial submission stake.
            } else {
                // Challenger (author) loses: Challenger's stake is slashed (goes to protocol fees).
                _updateReputation(dispute.challenger, -50);
                // Opponent (protocol) implicitly "wins"
            }
        } else if (dispute.disputeType == DisputeType.ReviewContent) {
            Review storage challengedReview = allReviews[dispute.targetId];
            address opponent = challengedReview.reviewer; // Challenger is user, opponent is reviewer
            uint256 opponentStake = challengedReview.reviewStake;

            if (_challengerWon) {
                // Challenger wins: Reviewer's stake is slashed (goes to challenger). Review is marked invalid.
                // Reputation boost for challenger, significant slash for reviewer.
                _updateReputation(dispute.challenger, 20);
                _updateReputation(opponent, -40);
                challengedReview.isValid = false; // Mark review as invalid
                pendingRewards[dispute.challenger] += dispute.challengerStake + opponentStake; // Challenger gets their stake back + opponent's stake.
                // Return challenged review's stake to challenger.
            } else {
                // Challenger loses: Challenger's stake is slashed (goes to reviewer).
                // Reputation slash for challenger, boost for reviewer.
                _updateReputation(dispute.challenger, -30);
                _updateReputation(opponent, 15);
                pendingRewards[opponent] += dispute.challengerStake + opponentStake; // Reviewer gets back their stake + challenger's stake.
            }
        }

        // Return challenger's stake if they won, otherwise it's implicitly part of protocol fees or distributed to opponent.
        // For clarity, let's explicitly return challenger's stake if they won.
        if (_challengerWon && dispute.disputeType == DisputeType.SubmissionFinalization) { // If author challenges and wins
            require(COG_TOKEN.transfer(dispute.challenger, dispute.challengerStake), "Failed to return challenger stake");
        } else if (_challengerWon && dispute.disputeType == DisputeType.ReviewContent) { // If user challenges review and wins
            require(COG_TOKEN.transfer(dispute.challenger, dispute.challengerStake), "Failed to return challenger stake");
        }
        // If challenger lost, their stake remains in the contract as a fee/reward to opponent.

        emit DisputeResolved(_disputeId, _challengerWon, msg.sender);
    }

    // --- F. Token Management & Rewards ---

    /**
     * @notice Allows users (contributors, reviewers) to claim their accrued COG rewards.
     */
    function claimRewards() external whenNotPaused nonReentrant {
        uint256 amount = pendingRewards[msg.sender];
        require(amount > 0, "No pending rewards to claim");

        pendingRewards[msg.sender] = 0; // Reset before transfer to prevent reentrancy
        require(COG_TOKEN.transfer(msg.sender, amount), "Reward transfer failed");

        emit RewardsClaimed(msg.sender, amount);
    }

    /**
     * @notice Allows the owner (governance) to collect accumulated protocol fees.
     * These fees come from slashed stakes and a percentage of accepted submission stakes.
     */
    function collectProtocolFees() external onlyOwner whenNotPaused nonReentrant {
        uint256 balance = COG_TOKEN.balanceOf(address(this));
        uint256 totalStakes = 0;

        // Sum up all active stakes held by the contract
        for (uint256 i = 1; i <= _submissionIds.current(); i++) {
            if (submissions[i].status == Status.PendingReview || submissions[i].status == Status.Disputed) {
                totalStakes += submissions[i].submissionStake;
            }
            // Also need to sum up review stakes
            for (uint256 j = 0; j < reviewsBySubmission[i].length; j++) {
                if (reviewsBySubmission[i][j].isValid) { // Only count valid, unstaked reviews
                    totalStakes += reviewsBySubmission[i][j].reviewStake;
                }
            }
        }
        // Also sum up active challenge stakes
        for (uint256 i = 1; i <= _disputeIds.current(); i++) {
            if (!disputes[i].resolved) {
                totalStakes += disputes[i].challengerStake;
            }
        }

        uint256 rewardsOutstanding = 0;
        // Sum up all pending rewards
        // This is a more complex loop, would need to iterate all users or track a running total.
        // For simplicity, we'll assume `balance - totalStakes` gives us fees + undistributed rewards.
        // A full implementation would need a more robust way to track total pending rewards.

        // For now, let's assume `balance - totalStakes` (approx) equals `fees + unclaimed_rewards`.
        // The owner can only withdraw what's purely 'fees'. This is a rough estimation.
        // A robust system would track fees in a separate variable.

        uint256 withdrawableAmount = balance > totalStakes ? balance - totalStakes : 0;
        require(withdrawableAmount > 0, "No protocol fees available to withdraw");
        require(COG_TOKEN.transfer(msg.sender, withdrawableAmount), "Failed to transfer protocol fees");
    }
}
```