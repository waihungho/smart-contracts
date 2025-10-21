Here is a Solidity smart contract named `CognitoLink` that incorporates several advanced, creative, and trendy concepts related to decentralized knowledge sharing, AI oracle integration, reputation, micro-licensing, and governance. It provides at least 20 distinct functions as requested.

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/**
 * @title CognitoLink - Decentralized Knowledge & Research Nexus
 * @author [Your Name/Alias]
 * @notice A platform for contributing, curating, licensing, and collectively evolving a
 *         decentralized knowledge base. It features a reputation system, micro-licensing
 *         models, AI-assisted validation (via oracle simulation), and dynamic bounties,
 *         all governed by its community through the CognitoLink Token (CLT).
 */

// OUTLINE:
// I. State Variables & Data Structures: Defines all storage variables, mappings, and structs used by the contract.
// II. Events: Declares events emitted for important state changes, facilitating off-chain monitoring.
// III. Modifiers: Custom modifiers for access control and common requirement checks.
// IV. Constructor: Initializes the contract, sets up the ERC-20 token, and whitelists an initial AI oracle.
// V. Knowledge Unit Management: Functions for creating, updating, and retrieving Knowledge Units (KUs).
// VI. Peer Review & Curation: Logic for users to review KUs and for the system to process these reviews.
// VII. AI Oracle Integration: Functions to request AI insights for KUs and for whitelisted oracles to fulfill these requests.
// VIII. Licensing & Monetization: Features for KU owners to define license models, and for users to purchase and check license status.
// IX. Bounty System: Functionality for creating research bounties, submitting solutions, community voting, and claiming rewards.
// X. Reputation & Staking: Manages user reputation scores, and allows users to stake/unstake CLT tokens for enhanced participation.
// XI. Governance & Platform Parameters: Enables decentralized governance through proposals, voting, and execution of parameter changes.
// XII. Admin & Oracle Management: Administrative functions for the contract owner, specifically for managing whitelisted AI oracles.

// FUNCTION SUMMARY (Total: 24 Functions):
// 1.  constructor(): Initializes the CognitoLink Token (CLT) address, an initial AI Oracle address, and core platform governance parameters.
// 2.  createKnowledgeUnit(string calldata _ipfsHash, string calldata _metadataURI, bytes32[] calldata _initialTags): Allows a user to submit a new Knowledge Unit (KU) to the platform, specifying its content hash, metadata, and initial tags.
// 3.  updateKnowledgeUnitMetadata(uint256 _kuId, string calldata _newIpfsHash, string calldata _newMetadataURI): Enables the owner of a KU to update its IPFS content hash or metadata URI, for versioning or corrections.
// 4.  getKnowledgeUnit(uint256 _kuId): Retrieves detailed information about a specific Knowledge Unit, including its owner, content, and aggregated review scores.
// 5.  submitKnowledgeUnitReview(uint256 _kuId, uint8 _score, string calldata _reviewHash): Allows users with a minimum reputation score to submit a peer review for a KU, impacting its overall quality score and boosting the reviewer's reputation.
// 6.  requestAIAssistedTagging(uint256 _kuId): Initiates a request to a whitelisted AI Oracle for automated tagging, summarization, or initial validation scores for a specified Knowledge Unit.
// 7.  fulfillAIAssistedTagging(uint256 _kuId, bytes32[] calldata _aiTags, uint256 _requestId): A callback function, callable only by whitelisted AI Oracles, to deliver AI-generated tags or insights for a KU.
// 8.  createLicenseModel(uint256 _kuId, uint256 _pricePerAccess, uint256 _durationDays, bool _isOneTimePurchase): Allows a KU owner to define a new licensing model for their Knowledge Unit, specifying pricing (in CLT), duration, and type (one-time or subscription).
// 9.  purchaseLicense(uint256 _kuId, uint256 _licenseModelId): Enables users to purchase access to a Knowledge Unit using CLT tokens, based on an existing license model.
// 10. getLicenseStatus(uint256 _kuId, address _user): Checks and returns the current licensing status (active/inactive, expiry) for a given user on a specific Knowledge Unit.
// 11. createResearchBounty(string calldata _title, string calldata _descriptionHash, uint256 _rewardAmount, uint256 _deadline): Allows users to create a research bounty, depositing CLT tokens as a reward for a specific research question or data contribution.
// 12. submitBountySolution(uint256 _bountyId, string calldata _solutionIpfsHash): Enables participants to submit their solutions (referenced by an IPFS hash) to an active research bounty before its deadline.
// 13. voteOnBountySolution(uint256 _bountyId, uint256 _solutionIndex, bool _approve): Allows users with sufficient staked CLT to vote on submitted bounty solutions after the submission deadline, influencing the selection of the winning solution.
// 14. claimBountyReward(uint256 _bountyId): Allows the creator of the approved winning solution to claim the deposited CLT reward for a finalized bounty.
// 15. getReputation(address _user): Retrieves the current reputation score of a specific user on the platform.
// 16. stakeCLT(uint256 _amount): Allows users to stake their CLT tokens to boost their reputation, gain voting power in governance, and potentially earn staking rewards.
// 17. unstakeCLT(uint256 _amount): Initiates a request to unstake CLT tokens. Funds become available for withdrawal after a defined cooldown period.
// 18. claimStakingRewards(): Allows stakers to claim any accumulated staking rewards (logic simplified/placeholder for a real rewards mechanism).
// 19. proposePlatformParameterChange(uint8 _parameterIndex, uint256 _newValue): Enables users with sufficient staked CLT to propose changes to core platform governance parameters.
// 20. voteOnProposal(uint256 _proposalId, bool _support): Allows users with voting power to cast their vote (for or against) on an active governance proposal.
// 21. executeProposal(uint256 _proposalId): Executes a governance proposal that has successfully passed its voting period and met the approval threshold.
// 22. withdrawLicenseFees(address _kuOwner): Allows a Knowledge Unit owner to withdraw the CLT tokens accumulated from licenses purchased for their KUs.
// 23. addAllowedOracle(address _oracleAddress): An administrative function, callable only by the contract owner, to whitelist new AI Oracle addresses.
// 24. removeAllowedOracle(address _oracleAddress): An administrative function to deregister a previously whitelisted AI Oracle address.
// 25. finalizeBountyVoting(uint256 _bountyId): A publicly callable function to finalize the voting for a bounty and determine the winning solution after the voting deadline.

contract CognitoLink is Ownable, ReentrancyGuard {
    // I. State Variables & Data Structures

    // --- Configuration Constants ---
    // These are initial defaults and can be changed via governance proposals.
    uint256 public constant DEFAULT_MIN_REPUTATION_FOR_REVIEW = 100; // Min reputation to review KUs
    uint256 public constant DEFAULT_MIN_STAKE_FOR_GOVERNANCE = 1000 * 10 ** 18; // Min CLT stake for governance participation
    uint256 public constant DEFAULT_PROPOSAL_VOTING_PERIOD = 7 days; // Duration for governance proposals
    uint256 public constant DEFAULT_UNSTAKE_COOLDOWN_PERIOD = 14 days; // Cooldown period for unstaking
    uint256 public constant DEFAULT_REVIEW_REPUTATION_BOOST = 10; // Reputation gained per review
    uint256 public constant DEFAULT_BOUNTY_VOTING_THRESHOLD_PERCENTAGE = 51; // % of total votes required to approve a bounty solution (e.g., 51%)

    // --- External Contract Addresses ---
    IERC20 public immutable cognitoLinkToken; // The ERC-20 token for the platform (CLT)

    // --- Core Data Structures ---

    struct KnowledgeUnit {
        address owner;
        string ipfsHash;
        string metadataURI;
        bytes32[] currentTags; // AI-generated or manually added tags
        uint256 creationTimestamp;
        uint256 totalReviews;
        uint256 totalReviewScore; // Sum of all review scores (1-10)
        bool isActive; // Can be disabled if found problematic or outdated
        uint256 lastUpdated;
    }
    mapping(uint256 => KnowledgeUnit) public knowledgeUnits;
    uint256 public nextKnowledgeUnitId;

    struct LicenseModel {
        uint256 kuId;
        uint256 pricePerAccess; // In CLT tokens (assuming 18 decimals)
        uint256 durationDays; // 0 for one-time/permanent access
        bool isOneTimePurchase; // True if it's a one-time purchase, false for duration-based
    }
    mapping(uint256 => mapping(uint256 => LicenseModel)) public licenseModels; // kuId => licenseModelId => LicenseModel
    mapping(uint256 => uint256) public nextLicenseModelId; // Stores the next available license model ID for each KU

    struct ActiveLicense {
        uint256 kuId;
        uint256 purchaseTimestamp;
        uint256 expiryTimestamp; // 0 for one-time/permanent licenses
        uint256 licenseModelId;
    }
    mapping(address => mapping(uint256 => ActiveLicense)) public activeLicenses; // user => kuId => ActiveLicense

    struct Review {
        address reviewer;
        uint8 score; // 1-10 rating
        string reviewHash; // IPFS hash of a detailed review text
        uint256 timestamp;
    }
    mapping(uint256 => mapping(address => Review)) public kuReviews; // kuId => reviewerAddress => Review

    struct ResearchBounty {
        address creator;
        string title;
        string descriptionHash; // IPFS hash of bounty details
        uint256 rewardAmount; // In CLT tokens
        IERC20 rewardToken; // Token used for reward (can be CLT or others, currently fixed to CLT)
        uint256 deadline; // Submission deadline
        bool isActive; // True until a winning solution is claimed or bounty is cancelled
        uint256 nextSolutionId;
        uint256 winningSolutionId; // 0 if not yet determined or no winner
        mapping(uint256 => BountySolution) solutions; // solutionId => BountySolution
        mapping(address => bool) hasVotedForBounty; // Prevents double voting on any solution for a specific bounty
        uint256 totalSolutionVotes; // Total cumulative staked CLT votes received for all solutions combined for this bounty
    }
    mapping(uint256 => ResearchBounty) public researchBounties;
    uint256 public nextBountyId;

    struct BountySolution {
        address submitter;
        string solutionIpfsHash; // IPFS hash of the solution content
        uint256 submissionTimestamp;
        uint256 votesReceived; // Cumulative staked CLT votes for this specific solution
        bool isApproved; // Set to true if this is the winning solution
        bool isClaimed;
    }

    struct UserReputation {
        uint256 score;
        uint256 lastUpdateTimestamp;
    }
    mapping(address => UserReputation) public userReputations;

    struct Stake {
        uint256 amount; // Amount of CLT staked
        uint256 timestamp; // When the last stake or unstake request was made
        uint256 rewardsAccumulated; // Placeholder for staking rewards (simplified)
        uint256 unstakeRequestTimestamp; // 0 if no pending unstake request
        uint256 unstakeRequestedAmount; // Amount requested to unstake
    }
    mapping(address => Stake) public userStakes;

    struct Proposal {
        address proposer;
        uint8 parameterIndex; // Corresponds to a GovernanceParameter enum value
        uint256 newValue;
        uint256 creationTimestamp;
        uint256 votingDeadline;
        uint256 votesFor; // Cumulative staked CLT votes for the proposal
        uint256 votesAgainst; // Cumulative staked CLT votes against the proposal
        bool executed;
        mapping(address => bool) hasVoted; // Prevents double voting on this proposal
    }
    mapping(uint256 => Proposal) public governanceProposals;
    uint256 public nextProposalId;

    // --- AI Oracle Management ---
    mapping(address => bool) public allowedOracles; // Whitelisted addresses that can call `fulfillAIAssistedTagging`
    // mapping(uint256 => address) public oracleRequestToRequester; // Map to track original requester (optional for simple mock)
    uint256 public nextOracleRequestId; // Simple sequential ID for oracle requests

    // --- Accumulated Fees ---
    mapping(address => uint256) public kuOwnerLicenseFees; // kuOwner => accumulated CLT fees from licenses

    // --- Governance Parameters (Changeable via Proposals) ---
    uint256 public minReputationForReviewParam;
    uint256 public minStakeForGovernanceParam;
    uint256 public proposalVotingPeriodParam;
    uint256 public unstakeCooldownPeriodParam;
    uint256 public reviewReputationBoostParam;
    uint256 public bountyVotingThresholdPercentage; // Percentage (e.g., 51 for 51%)

    // Enum for mapping parameter indices to governance parameters
    enum GovernanceParameter {
        MinReputationForReview,
        MinStakeForGovernance,
        ProposalVotingPeriod,
        UnstakeCooldownPeriod,
        ReviewReputationBoost,
        BountyVotingThresholdPercentage
    }

    // II. Events

    event KnowledgeUnitCreated(uint256 indexed kuId, address indexed owner, string ipfsHash);
    event KnowledgeUnitUpdated(uint256 indexed kuId, address indexed updater, string newIpfsHash);
    event KnowledgeUnitReviewed(uint256 indexed kuId, address indexed reviewer, uint8 score);
    event AIAssistedTaggingRequested(uint256 indexed kuId, uint256 indexed requestId, address requester);
    event AIAssistedTaggingFulfilled(uint256 indexed kuId, uint256 indexed requestId, bytes32[] aiTags);

    event LicenseModelCreated(uint256 indexed kuId, uint256 indexed licenseModelId, uint256 price, uint256 duration);
    event LicensePurchased(uint256 indexed kuId, address indexed buyer, uint256 licenseModelId, uint256 expiryTimestamp);
    event LicenseFeesWithdrawn(address indexed kuOwner, uint256 amount);

    event ResearchBountyCreated(uint256 indexed bountyId, address indexed creator, uint256 rewardAmount);
    event BountySolutionSubmitted(uint256 indexed bountyId, uint256 indexed solutionId, address submitter);
    event BountySolutionVoted(uint256 indexed bountyId, uint256 indexed solutionId, address voter, bool approved);
    event BountyWinnerDetermined(uint256 indexed bountyId, uint256 indexed winningSolutionId);
    event BountyRewardClaimed(uint256 indexed bountyId, address indexed winner, uint256 amount);

    event ReputationUpdated(address indexed user, uint256 newScore);
    event CLTStaked(address indexed user, uint256 amount);
    event CLTUnstakeRequested(address indexed user, uint256 amount, uint256 cooldownEnd);
    event CLTUnstaked(address indexed user, uint256 amount);
    event StakingRewardsClaimed(address indexed user, uint256 amount);

    event ProposalCreated(uint256 indexed proposalId, address indexed proposer, uint8 parameterIndex, uint256 newValue);
    event ProposalVoted(uint256 indexed proposalId, address indexed voter, bool support);
    event ProposalExecuted(uint256 indexed proposalId);
    event GovernanceParameterUpdated(uint8 indexed parameterIndex, uint256 oldValue, uint256 newValue);

    event OracleAdded(address indexed oracleAddress);
    event OracleRemoved(address indexed oracleAddress);

    // III. Modifiers

    modifier onlyKuOwner(uint256 _kuId) {
        require(knowledgeUnits[_kuId].owner == msg.sender, "CognitoLink: Not KU owner");
        _;
    }

    modifier onlyAllowedOracle() {
        require(allowedOracles[msg.sender], "CognitoLink: Not an allowed oracle");
        _;
    }

    modifier hasMinReputation(uint256 _minReputation) {
        require(userReputations[msg.sender].score >= _minReputation, "CognitoLink: Insufficient reputation");
        _;
    }

    modifier hasMinStake(uint256 _minStake) {
        require(userStakes[msg.sender].amount >= _minStake, "CognitoLink: Insufficient staked CLT for governance");
        _;
    }

    // IV. Constructor

    constructor(address _cltTokenAddress, address _initialOracleAddress) Ownable(msg.sender) {
        require(_cltTokenAddress != address(0), "CognitoLink: CLT Token address cannot be zero");
        require(_initialOracleAddress != address(0), "CognitoLink: Initial oracle address cannot be zero");

        cognitoLinkToken = IERC20(_cltTokenAddress);
        allowedOracles[_initialOracleAddress] = true;
        emit OracleAdded(_initialOracleAddress);

        // Initialize governance parameters to their default constant values
        minReputationForReviewParam = DEFAULT_MIN_REPUTATION_FOR_REVIEW;
        minStakeForGovernanceParam = DEFAULT_MIN_STAKE_FOR_GOVERNANCE;
        proposalVotingPeriodParam = DEFAULT_PROPOSAL_VOTING_PERIOD;
        unstakeCooldownPeriodParam = DEFAULT_UNSTAKE_COOLDOWN_PERIOD;
        reviewReputationBoostParam = DEFAULT_REVIEW_REPUTATION_BOOST;
        bountyVotingThresholdPercentage = DEFAULT_BOUNTY_VOTING_THRESHOLD_PERCENTAGE;
    }

    // V. Knowledge Unit Management

    // 2. createKnowledgeUnit
    function createKnowledgeUnit(
        string calldata _ipfsHash,
        string calldata _metadataURI,
        bytes32[] calldata _initialTags
    ) external returns (uint256 kuId) {
        kuId = nextKnowledgeUnitId++;
        knowledgeUnits[kuId] = KnowledgeUnit({
            owner: msg.sender,
            ipfsHash: _ipfsHash,
            metadataURI: _metadataURI,
            currentTags: _initialTags,
            creationTimestamp: block.timestamp,
            totalReviews: 0,
            totalReviewScore: 0,
            isActive: true,
            lastUpdated: block.timestamp
        });
        emit KnowledgeUnitCreated(kuId, msg.sender, _ipfsHash);
    }

    // 3. updateKnowledgeUnitMetadata
    function updateKnowledgeUnitMetadata(
        uint256 _kuId,
        string calldata _newIpfsHash,
        string calldata _newMetadataURI
    ) external onlyKuOwner(_kuId) {
        KnowledgeUnit storage ku = knowledgeUnits[_kuId];
        require(ku.isActive, "CognitoLink: KU is inactive");
        ku.ipfsHash = _newIpfsHash;
        ku.metadataURI = _newMetadataURI;
        ku.lastUpdated = block.timestamp;
        emit KnowledgeUnitUpdated(_kuId, msg.sender, _newIpfsHash);
    }

    // 4. getKnowledgeUnit
    function getKnowledgeUnit(uint256 _kuId)
        external
        view
        returns (
            address owner,
            string memory ipfsHash,
            string memory metadataURI,
            bytes32[] memory currentTags,
            uint256 creationTimestamp,
            uint256 totalReviews,
            uint256 avgReviewScore,
            bool isActive,
            uint256 lastUpdated
        )
    {
        KnowledgeUnit storage ku = knowledgeUnits[_kuId];
        require(ku.owner != address(0), "CognitoLink: KU does not exist"); // Check if KU exists
        owner = ku.owner;
        ipfsHash = ku.ipfsHash;
        metadataURI = ku.metadataURI;
        currentTags = ku.currentTags;
        creationTimestamp = ku.creationTimestamp;
        totalReviews = ku.totalReviews;
        avgReviewScore = ku.totalReviews > 0 ? ku.totalReviewScore / ku.totalReviews : 0;
        isActive = ku.isActive;
        lastUpdated = ku.lastUpdated;
    }

    // VI. Peer Review & Curation

    // 5. submitKnowledgeUnitReview
    function submitKnowledgeUnitReview(
        uint256 _kuId,
        uint8 _score, // 1-10
        string calldata _reviewHash // IPFS hash of detailed review
    ) external hasMinReputation(minReputationForReviewParam) {
        KnowledgeUnit storage ku = knowledgeUnits[_kuId];
        require(ku.owner != address(0), "CognitoLink: KU does not exist");
        require(ku.isActive, "CognitoLink: KU is inactive");
        require(msg.sender != ku.owner, "CognitoLink: KU owner cannot review their own unit");
        require(kuReviews[_kuId][msg.sender].reviewer == address(0), "CognitoLink: Already reviewed this KU");
        require(_score >= 1 && _score <= 10, "CognitoLink: Score must be between 1 and 10");

        kuReviews[_kuId][msg.sender] = Review({
            reviewer: msg.sender,
            score: _score,
            reviewHash: _reviewHash,
            timestamp: block.timestamp
        });

        ku.totalReviews++;
        ku.totalReviewScore += _score;

        // Update reviewer's reputation
        userReputations[msg.sender].score += reviewReputationBoostParam;
        userReputations[msg.sender].lastUpdateTimestamp = block.timestamp;

        emit KnowledgeUnitReviewed(_kuId, msg.sender, _score);
        emit ReputationUpdated(msg.sender, userReputations[msg.sender].score);
    }

    // VII. AI Oracle Integration

    // 6. requestAIAssistedTagging
    function requestAIAssistedTagging(uint256 _kuId) external {
        KnowledgeUnit storage ku = knowledgeUnits[_kuId];
        require(ku.owner != address(0), "CognitoLink: KU does not exist");
        require(ku.isActive, "CognitoLink: KU is inactive");

        // In a real scenario, this would call an external oracle contract (e.g., Chainlink)
        // that takes the kuId and relevant data, then calls back `fulfillAIAssistedTagging`.
        // We'll simulate this by generating a unique requestId.
        uint256 requestId = nextOracleRequestId++; // Simple sequential ID for oracle requests
        // oracleRequestToRequester[requestId] = msg.sender; // Optional: track requester if needed for complex oracle flows

        emit AIAssistedTaggingRequested(_kuId, requestId, msg.sender);
    }

    // 7. fulfillAIAssistedTagging - Only callable by whitelisted oracles
    function fulfillAIAssistedTagging(
        uint256 _kuId,
        bytes32[] calldata _aiTags,
        uint256 _requestId
    ) external onlyAllowedOracle {
        KnowledgeUnit storage ku = knowledgeUnits[_kuId];
        require(ku.owner != address(0), "CognitoLink: KU does not exist");
        require(ku.isActive, "CognitoLink: KU is inactive");
        // Optional: Implement logic to ensure _requestId is valid and expected.

        // Append AI-generated tags to existing tags
        for (uint256 i = 0; i < _aiTags.length; i++) {
            ku.currentTags.push(_aiTags[i]);
        }
        ku.lastUpdated = block.timestamp;

        emit AIAssistedTaggingFulfilled(_kuId, _requestId, _aiTags);
    }

    // VIII. Licensing & Monetization

    // 8. createLicenseModel
    function createLicenseModel(
        uint256 _kuId,
        uint256 _pricePerAccess, // In CLT tokens (assuming 18 decimals)
        uint256 _durationDays, // 0 for one-time
        bool _isOneTimePurchase
    ) external onlyKuOwner(_kuId) {
        KnowledgeUnit storage ku = knowledgeUnits[_kuId];
        require(ku.isActive, "CognitoLink: KU is inactive");
        require(_pricePerAccess > 0, "CognitoLink: Price must be greater than zero");
        require(!(_isOneTimePurchase && _durationDays > 0), "CognitoLink: One-time purchase cannot have duration");
        require((_isOneTimePurchase && _durationDays == 0) || (!_isOneTimePurchase && _durationDays > 0), "CognitoLink: Invalid license type configuration");

        uint256 licenseModelId = nextLicenseModelId[_kuId]++;
        licenseModels[_kuId][licenseModelId] = LicenseModel({
            kuId: _kuId,
            pricePerAccess: _pricePerAccess,
            durationDays: _durationDays,
            isOneTimePurchase: _isOneTimePurchase
        });
        emit LicenseModelCreated(_kuId, licenseModelId, _pricePerAccess, _durationDays);
    }

    // 9. purchaseLicense
    function purchaseLicense(uint256 _kuId, uint256 _licenseModelId) external nonReentrant {
        KnowledgeUnit storage ku = knowledgeUnits[_kuId];
        require(ku.owner != address(0), "CognitoLink: KU does not exist");
        require(ku.isActive, "CognitoLink: KU is inactive");
        require(msg.sender != ku.owner, "CognitoLink: KU owner does not need a license");

        LicenseModel storage model = licenseModels[_kuId][_licenseModelId];
        require(model.kuId == _kuId, "CognitoLink: License model does not exist for this KU");
        require(model.pricePerAccess > 0, "CognitoLink: License model is not configured for purchase");

        ActiveLicense storage currentLicense = activeLicenses[msg.sender][_kuId];

        // For one-time purchases, disallow if already owned
        if (model.isOneTimePurchase) {
            require(currentLicense.purchaseTimestamp == 0, "CognitoLink: One-time license already purchased");
        } else {
            // For duration-based, allow extending existing license if it's the same model
            if (currentLicense.expiryTimestamp > block.timestamp) {
                require(currentLicense.licenseModelId == _licenseModelId, "CognitoLink: Cannot change model for active duration license");
            }
        }

        // Transfer CLT tokens from buyer to contract, then earmark for KU owner
        require(cognitoLinkToken.transferFrom(msg.sender, address(this), model.pricePerAccess), "CognitoLink: CLT transfer failed");
        kuOwnerLicenseFees[ku.owner] += model.pricePerAccess;

        // Update active license
        currentLicense.kuId = _kuId;
        currentLicense.purchaseTimestamp = block.timestamp;
        currentLicense.licenseModelId = _licenseModelId;

        uint256 expiry = 0;
        if (!model.isOneTimePurchase) {
            expiry = (currentLicense.expiryTimestamp > block.timestamp ? currentLicense.expiryTimestamp : block.timestamp) + (model.durationDays * 1 days);
        }
        currentLicense.expiryTimestamp = expiry;

        emit LicensePurchased(_kuId, msg.sender, _licenseModelId, expiry);
    }

    // 10. getLicenseStatus
    function getLicenseStatus(uint256 _kuId, address _user)
        external
        view
        returns (bool isActive, uint256 expiryTimestamp, bool isOneTime)
    {
        KnowledgeUnit storage ku = knowledgeUnits[_kuId];
        require(ku.owner != address(0), "CognitoLink: KU does not exist");
        require(_user != address(0), "CognitoLink: User address cannot be zero");

        if (_user == ku.owner) {
            return (true, type(uint256).max, true); // Owner always has access
        }

        ActiveLicense storage license = activeLicenses[_user][_kuId];
        if (license.purchaseTimestamp == 0) {
            return (false, 0, false); // No license ever purchased
        }

        LicenseModel storage model = licenseModels[_kuId][license.licenseModelId];
        if (model.isOneTimePurchase) {
            return (true, 0, true); // One-time licenses are always active once purchased
        } else {
            return (license.expiryTimestamp > block.timestamp, license.expiryTimestamp, false);
        }
    }

    // 22. withdrawLicenseFees
    function withdrawLicenseFees(address _kuOwner) external nonReentrant {
        require(msg.sender == _kuOwner, "CognitoLink: Can only withdraw your own fees");
        uint256 amount = kuOwnerLicenseFees[_kuOwner];
        require(amount > 0, "CognitoLink: No fees to withdraw");

        kuOwnerLicenseFees[_kuOwner] = 0;
        require(cognitoLinkToken.transfer(_kuOwner, amount), "CognitoLink: Fee withdrawal failed");
        emit LicenseFeesWithdrawn(_kuOwner, amount);
    }

    // IX. Bounty System

    // 11. createResearchBounty
    function createResearchBounty(
        string calldata _title,
        string calldata _descriptionHash, // IPFS hash
        uint256 _rewardAmount, // In CLT tokens
        uint256 _deadline // Unix timestamp
    ) external nonReentrant returns (uint256 bountyId) {
        require(_rewardAmount > 0, "CognitoLink: Reward amount must be greater than zero");
        require(_deadline > block.timestamp, "CognitoLink: Deadline must be in the future");
        require(cognitoLinkToken.transferFrom(msg.sender, address(this), _rewardAmount), "CognitoLink: Reward deposit failed");

        bountyId = nextBountyId++;
        researchBounties[bountyId] = ResearchBounty({
            creator: msg.sender,
            title: _title,
            descriptionHash: _descriptionHash,
            rewardAmount: _rewardAmount,
            rewardToken: cognitoLinkToken, // Fixed to CLT for this contract
            deadline: _deadline,
            isActive: true,
            nextSolutionId: 0,
            winningSolutionId: 0,
            totalSolutionVotes: 0
        });

        emit ResearchBountyCreated(bountyId, msg.sender, _rewardAmount);
    }

    // 12. submitBountySolution
    function submitBountySolution(
        uint256 _bountyId,
        string calldata _solutionIpfsHash
    ) external {
        ResearchBounty storage bounty = researchBounties[_bountyId];
        require(bounty.creator != address(0), "CognitoLink: Bounty does not exist");
        require(bounty.isActive, "CognitoLink: Bounty is not active");
        require(block.timestamp <= bounty.deadline, "CognitoLink: Bounty submission deadline passed");
        require(msg.sender != bounty.creator, "CognitoLink: Creator cannot submit solution to own bounty");

        uint256 solutionId = bounty.nextSolutionId++;
        bounty.solutions[solutionId] = BountySolution({
            submitter: msg.sender,
            solutionIpfsHash: _solutionIpfsHash,
            submissionTimestamp: block.timestamp,
            votesReceived: 0,
            isApproved: false,
            isClaimed: false
        });
        emit BountySolutionSubmitted(_bountyId, solutionId, msg.sender);
    }

    // 13. voteOnBountySolution
    function voteOnBountySolution(
        uint256 _bountyId,
        uint256 _solutionIndex,
        bool _approve
    ) external hasMinStake(minStakeForGovernanceParam) {
        ResearchBounty storage bounty = researchBounties[_bountyId];
        require(bounty.creator != address(0), "CognitoLink: Bounty does not exist");
        require(bounty.isActive, "CognitoLink: Bounty is not active");
        require(block.timestamp > bounty.deadline, "CognitoLink: Voting period has not started (after submission deadline)");
        require(bounty.winningSolutionId == 0, "CognitoLink: Winning solution already chosen");
        require(bounty.solutions[_solutionIndex].submitter != address(0), "CognitoLink: Solution does not exist");
        require(msg.sender != bounty.solutions[_solutionIndex].submitter, "CognitoLink: Cannot vote on your own solution");
        require(!bounty.hasVotedForBounty[msg.sender], "CognitoLink: Already voted on this bounty");

        uint256 voterStake = userStakes[msg.sender].amount;
        require(voterStake > 0, "CognitoLink: Must have staked CLT to vote");

        bounty.hasVotedForBounty[msg.sender] = true;
        
        if (_approve) {
            bounty.solutions[_solutionIndex].votesReceived += voterStake;
            bounty.totalSolutionVotes += voterStake; // Sum of votes for potential winning solutions
        } else {
            // If voting "against", don't add to votesReceived or totalSolutionVotes for simplicity,
            // as approval is based on a threshold of 'votesFor'
        }

        emit BountySolutionVoted(_bountyId, _solutionIndex, msg.sender, _approve);
    }

    // Helper: Determine winning solution for a bounty based on votes and percentage threshold
    function _determineWinningBountySolution(uint256 _bountyId) internal {
        ResearchBounty storage bounty = researchBounties[_bountyId];
        require(bounty.winningSolutionId == 0, "CognitoLink: Winning solution already set");
        require(block.timestamp > bounty.deadline, "CognitoLink: Voting period not over");

        uint256 highestVotes = 0;
        uint256 winningSolutionCandidateId = 0;

        for (uint256 i = 0; i < bounty.nextSolutionId; i++) {
            BountySolution storage solution = bounty.solutions[i];
            if (solution.submitter != address(0) && solution.votesReceived > highestVotes) {
                highestVotes = solution.votesReceived;
                winningSolutionCandidateId = i;
            }
        }

        if (winningSolutionCandidateId != 0 && bounty.totalSolutionVotes > 0) {
            // Check if the highest voted solution meets the percentage threshold
            // The threshold is applied against the sum of 'for' votes for all solutions combined.
            uint256 requiredVotes = (bounty.totalSolutionVotes * bountyVotingThresholdPercentage) / 100;

            if (highestVotes >= requiredVotes) {
                bounty.winningSolutionId = winningSolutionCandidateId;
                bounty.solutions[winningSolutionCandidateId].isApproved = true;
                bounty.isActive = false; // Close the bounty
                emit BountyWinnerDetermined(_bountyId, winningSolutionCandidateId);
            } else {
                // No solution met the threshold. Bounty remains open or can be cancelled manually later.
            }
        }
    }

    // 25. finalizeBountyVoting (Added this function to ensure a callable external method)
    function finalizeBountyVoting(uint256 _bountyId) external {
        ResearchBounty storage bounty = researchBounties[_bountyId];
        require(bounty.creator != address(0), "CognitoLink: Bounty does not exist");
        require(bounty.isActive, "CognitoLink: Bounty is already inactive.");
        require(block.timestamp > bounty.deadline, "CognitoLink: Voting period not over yet.");
        require(bounty.winningSolutionId == 0, "CognitoLink: Winning solution already determined.");

        _determineWinningBountySolution(_bountyId);
    }

    // 14. claimBountyReward
    function claimBountyReward(uint256 _bountyId) external nonReentrant {
        ResearchBounty storage bounty = researchBounties[_bountyId];
        require(bounty.creator != address(0), "CognitoLink: Bounty does not exist");
        require(!bounty.isActive, "CognitoLink: Bounty is still active, must be resolved"); // Ensure resolved (winning solution chosen)
        require(bounty.winningSolutionId != 0, "CognitoLink: Winning solution not determined");

        BountySolution storage winningSolution = bounty.solutions[bounty.winningSolutionId];
        require(msg.sender == winningSolution.submitter, "CognitoLink: Only winning submitter can claim");
        require(winningSolution.isApproved, "CognitoLink: Solution not approved");
        require(!winningSolution.isClaimed, "CognitoLink: Reward already claimed");

        winningSolution.isClaimed = true;
        require(cognitoLinkToken.transfer(winningSolution.submitter, bounty.rewardAmount), "CognitoLink: Reward transfer failed");
        emit BountyRewardClaimed(_bountyId, winningSolution.submitter, bounty.rewardAmount);
    }

    // X. Reputation & Staking

    // 15. getReputation
    function getReputation(address _user) external view returns (uint256) {
        return userReputations[_user].score;
    }

    // 16. stakeCLT
    function stakeCLT(uint256 _amount) external nonReentrant {
        require(_amount > 0, "CognitoLink: Amount to stake must be greater than zero");
        require(cognitoLinkToken.transferFrom(msg.sender, address(this), _amount), "CognitoLink: CLT transfer failed for staking");

        Stake storage stake = userStakes[msg.sender];
        stake.amount += _amount;
        stake.timestamp = block.timestamp; // Update timestamp for new stake or combined stake

        // Reputation can implicitly be tied to stake amount for governance weight.
        // Direct reputation score increase could be added here if desired.
        emit CLTStaked(msg.sender, _amount);
    }

    // 17. unstakeCLT
    function unstakeCLT(uint256 _amount) external nonReentrant {
        Stake storage stake = userStakes[msg.sender];
        require(_amount > 0, "CognitoLink: Amount to unstake must be greater than zero");
        require(stake.amount >= _amount, "CognitoLink: Insufficient staked amount");

        if (stake.unstakeRequestTimestamp == 0) {
            // Initiate unstake request
            stake.unstakeRequestTimestamp = block.timestamp;
            stake.unstakeRequestedAmount = _amount;
            emit CLTUnstakeRequested(msg.sender, _amount, block.timestamp + unstakeCooldownPeriodParam);
        } else {
            // Fulfill unstake request after cooldown
            require(block.timestamp >= stake.unstakeRequestTimestamp + unstakeCooldownPeriodParam, "CognitoLink: Unstake cooldown period not over");
            require(stake.unstakeRequestedAmount > 0, "CognitoLink: No pending unstake request to fulfill");
            require(stake.amount >= stake.unstakeRequestedAmount, "CognitoLink: Staked amount reduced below requested unstake amount");

            uint256 amountToTransfer = stake.unstakeRequestedAmount;
            stake.amount -= amountToTransfer;
            stake.unstakeRequestTimestamp = 0; // Reset request
            stake.unstakeRequestedAmount = 0;
            
            require(cognitoLinkToken.transfer(msg.sender, amountToTransfer), "CognitoLink: CLT unstake transfer failed");
            emit CLTUnstaked(msg.sender, amountToTransfer);
        }
    }

    // 18. claimStakingRewards (Simplified placeholder)
    function claimStakingRewards() external nonReentrant {
        Stake storage stake = userStakes[msg.sender];
        require(stake.rewardsAccumulated > 0, "CognitoLink: No rewards to claim");

        uint256 rewards = stake.rewardsAccumulated;
        stake.rewardsAccumulated = 0; // Reset
        require(cognitoLinkToken.transfer(msg.sender, rewards), "CognitoLink: Reward claim failed");
        emit StakingRewardsClaimed(msg.sender, rewards);
    }

    // XI. Governance & Platform Parameters

    // 19. proposePlatformParameterChange
    function proposePlatformParameterChange(
        uint8 _parameterIndex,
        uint256 _newValue
    ) external hasMinStake(minStakeForGovernanceParam) returns (uint256 proposalId) {
        // Validate _parameterIndex against the enum bounds
        require(_parameterIndex <= uint8(GovernanceParameter.BountyVotingThresholdPercentage), "CognitoLink: Invalid parameter index");

        proposalId = nextProposalId++;
        governanceProposals[proposalId] = Proposal({
            proposer: msg.sender,
            parameterIndex: _parameterIndex,
            newValue: _newValue,
            creationTimestamp: block.timestamp,
            votingDeadline: block.timestamp + proposalVotingPeriodParam,
            votesFor: 0,
            votesAgainst: 0,
            executed: false
        });
        emit ProposalCreated(proposalId, msg.sender, _parameterIndex, _newValue);
    }

    // 20. voteOnProposal
    function voteOnProposal(uint256 _proposalId, bool _support) external hasMinStake(minStakeForGovernanceParam) {
        Proposal storage proposal = governanceProposals[_proposalId];
        require(proposal.proposer != address(0), "CognitoLink: Proposal does not exist");
        require(block.timestamp <= proposal.votingDeadline, "CognitoLink: Voting period has ended");
        require(!proposal.executed, "CognitoLink: Proposal already executed");
        require(!proposal.hasVoted[msg.sender], "CognitoLink: Already voted on this proposal");

        uint256 voterStake = userStakes[msg.sender].amount;
        require(voterStake > 0, "CognitoLink: Must have staked CLT to vote");

        proposal.hasVoted[msg.sender] = true;
        if (_support) {
            proposal.votesFor += voterStake;
        } else {
            proposal.votesAgainst += voterStake;
        }
        emit ProposalVoted(_proposalId, msg.sender, _support);
    }

    // 21. executeProposal
    function executeProposal(uint256 _proposalId) external {
        Proposal storage proposal = governanceProposals[_proposalId];
        require(proposal.proposer != address(0), "CognitoLink: Proposal does not exist");
        require(block.timestamp > proposal.votingDeadline, "CognitoLink: Voting period not over");
        require(!proposal.executed, "CognitoLink: Proposal already executed");

        uint256 totalVotes = proposal.votesFor + proposal.votesAgainst;
        require(totalVotes > 0, "CognitoLink: No votes cast for this proposal");
        require(proposal.votesFor > proposal.votesAgainst, "CognitoLink: Proposal did not pass (more 'for' votes needed)");

        uint256 oldValue;
        // Execute the parameter change
        if (proposal.parameterIndex == uint8(GovernanceParameter.MinReputationForReview)) {
            oldValue = minReputationForReviewParam;
            minReputationForReviewParam = proposal.newValue;
        } else if (proposal.parameterIndex == uint8(GovernanceParameter.MinStakeForGovernance)) {
            oldValue = minStakeForGovernanceParam;
            minStakeForGovernanceParam = proposal.newValue;
        } else if (proposal.parameterIndex == uint8(GovernanceParameter.ProposalVotingPeriod)) {
            oldValue = proposalVotingPeriodParam;
            proposalVotingPeriodParam = proposal.newValue;
        } else if (proposal.parameterIndex == uint8(GovernanceParameter.UnstakeCooldownPeriod)) {
            oldValue = unstakeCooldownPeriodParam;
            unstakeCooldownPeriodParam = proposal.newValue;
        } else if (proposal.parameterIndex == uint8(GovernanceParameter.ReviewReputationBoost)) {
            oldValue = reviewReputationBoostParam;
            reviewReputationBoostParam = proposal.newValue;
        } else if (proposal.parameterIndex == uint8(GovernanceParameter.BountyVotingThresholdPercentage)) {
            oldValue = bountyVotingThresholdPercentage;
            require(proposal.newValue <= 100, "CognitoLink: Threshold percentage cannot exceed 100");
            bountyVotingThresholdPercentage = proposal.newValue;
        } else {
            revert("CognitoLink: Unknown parameter index for execution");
        }

        proposal.executed = true;
        emit ProposalExecuted(_proposalId);
        emit GovernanceParameterUpdated(proposal.parameterIndex, oldValue, proposal.newValue);
    }

    // XII. Admin & Oracle Management

    // 23. addAllowedOracle
    function addAllowedOracle(address _oracleAddress) external onlyOwner {
        require(_oracleAddress != address(0), "CognitoLink: Oracle address cannot be zero");
        require(!allowedOracles[_oracleAddress], "CognitoLink: Oracle already allowed");
        allowedOracles[_oracleAddress] = true;
        emit OracleAdded(_oracleAddress);
    }

    // 24. removeAllowedOracle
    function removeAllowedOracle(address _oracleAddress) external onlyOwner {
        require(_oracleAddress != address(0), "CognitoLink: Oracle address cannot be zero");
        require(allowedOracles[_oracleAddress], "CognitoLink: Oracle not found");
        allowedOracles[_oracleAddress] = false;
        emit OracleRemoved(_oracleAddress);
    }
}
```