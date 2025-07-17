Here is a Solidity smart contract named `AetherFlow`, designed as a decentralized platform for AI-driven content monetization and curation. It incorporates several advanced, creative, and trendy concepts, while aiming to avoid direct duplication of existing open-source projects by combining unique features and interactions.

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

// Custom Error Definitions for better revert messages
error AetherFlow__InvalidAmount();
error AetherFlow__NotEnoughStaked();
error AetherFlow__ContentNotFound();
error AetherFlow__AlreadyEvaluated();
error AetherFlow__NotAnAIOracle();
error AetherFlow__NotACurator();
error AetherFlow__NotSubscribed();
error AetherFlow__AlreadySubscribed();
error AetherFlow__SubscriptionNotFound();
error AetherFlow__OracleAlreadyRegistered();
error AetherFlow__OracleNotRegistered();
error AetherFlow__OracleAlreadyDeactivated();
error AetherFlow__NotEnoughVotes();
error AetherFlow__ProposalNotFound();
error AetherFlow__ProposalNotYetExecutable();
error AetherFlow__ProposalAlreadyExecuted();
error AetherFlow__CannotUpdateApprovedContent();
error AetherFlow__NotCreatorOfContent();
error AetherFlow__ChallengeAlreadyInitiated();
error AetherFlow__NoActiveChallenge();
error AetherFlow__VotingPeriodNotActive();
error AetherFlow__AlreadyVoted();
error AetherFlow__InsufficientFunds();
error AetherFlow__SharesSumMismatch(); // For subscription tier shares

/*
*   Contract Name: AetherFlow
*   Concept: Decentralized AI-Driven Content Monetization and Curation Platform
*   Description: AetherFlow is a smart contract platform designed to facilitate the creation,
*                evaluation, and monetization of AI-related content (e.g., AI models, datasets,
*                AI-generated art/text). It features a unique blend of decentralized AI oracle
*                evaluation, a reputation-based curation system, subscription-based content access,
*                and a robust DAO governance model. The platform aims to ensure high-quality,
*                ethically evaluated content while empowering creators and curators.
*
*   Features & Advanced Concepts:
*   1.  AI Oracle Integration: Off-chain AI models evaluate content; their results are reported on-chain.
*       The contract manages the whitelisting, activation, and deactivation of these oracles via DAO governance.
*   2.  Reputation (FlowScore): A non-transferable, internal scoring system for participants (creators,
*       oracles, curators) to incentivize positive behavior and quality contributions. This score
*       influences rewards and privileges within the ecosystem.
*   3.  Decentralized Curation: Users stake tokens to participate in content approval/disapproval.
*       Curators earn rewards based on their staked amount and active participation, contributing
*       to content quality and discoverability.
*   4.  Subscription Monetization: Creators earn from their content through tiered subscriptions.
*       Revenue is automatically split between creators, the platform treasury, and curator rewards
*       based on DAO-defined percentages.
*   5.  DAO Governance: Critical parameters (e.g., AI Oracle whitelisting/deactivation, fee structures,
*       subscription tier creation) are controlled by community proposals and votes, making the
*       platform truly decentralized.
*   6.  Content Challenge System: Users can challenge an AI oracle's evaluation of content, initiating
*       a dispute resolution process managed by DAO members, ensuring fairness and preventing oracle collusion.
*   7.  IPFS/Arweave Integration (via Hashes): Content itself is stored off-chain on decentralized
*       storage solutions, with only cryptographic hashes and metadata on-chain for verification and access.
*
*   Functions Summary (Total: 31 functions):
*
*   I. Core Content Management (5 Functions)
*   1.  `submitContentCapsule(string _ipfsHash, uint256 _category, string _metadataURI)`:
*       Allows creators to submit new content (e.g., AI models, datasets, generated media) to the platform.
*   2.  `getContentCapsuleDetails(uint256 _contentId)`:
*       Retrieves detailed information about a specific content capsule.
*   3.  `requestAIOracleEvaluation(uint256 _contentId)`:
*       Initiates an AI oracle evaluation process for content. (Placeholder for off-chain trigger via oracle network).
*   4.  `receiveAIOracleEvaluation(uint256 _contentId, uint256 _aiScore, address _evaluatorOracle, string _evaluationHash)`:
*       Called by whitelisted AI Oracles to report the evaluation score and proof hash for a content capsule.
*   5.  `updateContentMetadata(uint256 _contentId, string _newMetadataURI)`:
*       Allows a content creator to update the metadata URI of their content capsule, typically before AI approval.
*
*   II. AI Oracle & Evaluation System (5 Functions)
*   6.  `proposeAIOracle(address _oracleAddress, string _oracleURI)`:
*       Starts a DAO proposal for the community to vote on whitelisting a new AI Oracle.
*   7.  `registerAIOracle(address _oracleAddress, string _oracleURI)`:
*       Registers a new AI Oracle. This function is designed to be callable only by the `executeProposal`
*       function after a successful DAO vote, not directly by an admin.
*   8.  `deactivateAIOracle(address _oracleAddress)`:
*       Deactivates an AI Oracle. This function is designed to be callable only by the `executeProposal`
*       function after a successful DAO vote, removing its ability to submit evaluations.
*   9.  `challengeAIOracleEvaluation(uint256 _contentId, uint256 _challengerStake)`:
*       Allows a user to challenge an AI Oracle's evaluation of content by staking AETHER tokens.
*   10. `resolveChallenge(uint256 _contentId, bool _oracleWasCorrect)`:
*       DAO function to resolve an active content challenge, determining if the original oracle was correct and distributing stakes/penalties.
*
*   III. Curation & Staking (4 Functions)
*   11. `stakeForCuration(uint256 _amount)`:
*       Allows a user to stake AETHER tokens to become or maintain their status as a content curator, earning the `CURATOR_ROLE`.
*   12. `unstakeFromCuration()`:
*       Allows a curator to unstake all their AETHER tokens from curation, revoking their `CURATOR_ROLE`.
*   13. `curateContent(uint256 _contentId, bool _isApproved, string _reasonHash)`:
*       Curators use this to approve or disapprove content, influencing its FlowScore and the curator's own reputation.
*   14. `claimCurationRewards()`:
*       Allows active curators to claim their accumulated rewards, derived from platform fees and their staking duration/activity.
*
*   IV. Monetization & Subscriptions (5 Functions)
*   15. `createSubscriptionTier(string _name, uint256 _pricePerMonth, uint256[] _accessCategories, uint256 _creatorRoyaltyShare, uint256 _platformFeeShare, uint256 _curatorRewardShare)`:
*       Creates a new content subscription tier with defined prices and access categories. Callable only via DAO proposal execution.
*   16. `subscribe(uint256 _tierId)`:
*       Allows a user to subscribe to a specific content tier by paying the monthly fee in AETHER tokens.
*   17. `unsubscribe()`:
*       Allows a user to cancel their active subscription.
*   18. `getSubscriptionStatus(address _subscriber, uint256 _contentCategory)`:
*       Checks if a given user has an active subscription that grants access to a specified content category.
*   19. `claimCreatorEarnings(uint256 _contentId)`:
*       Allows content creators to claim their accumulated earnings from their approved content, based on its FlowScore and subscription revenue.
*
*   V. Governance (DAO related) (3 Functions)
*   20. `proposeGovernanceChange(string _description, address _targetContract, bytes _callData)`:
*       Enables DAO members to create new governance proposals for the community to vote on, including system upgrades or parameter changes.
*   21. `voteOnProposal(uint256 _proposalId, bool _support)`:
*       Allows DAO members to cast their vote (for or against) on an active governance proposal.
*   22. `executeProposal(uint256 _proposalId)`:
*       Executes a governance proposal that has successfully passed its voting period and met the approval threshold.
*
*   VI. Token & Utility (ERC-20 AETHER Token) (2 Functions)
*   23. `depositAETHER(uint256 _amount)`:
*       Allows users to deposit AETHER tokens into their internal balance within the contract, making them available for staking or subscriptions.
*   24. `withdrawAETHER(uint256 _amount)`:
*       Allows users to withdraw their AETHER tokens from their internal contract balance back to their external wallet.
*
*   VII. Reputation System (1 Function)
*   25. `getFlowScore(address _user)`:
*       Retrieves the current FlowScore (reputation) of any user within the AetherFlow ecosystem.
*
*   VIII. Helper Getters (6 Functions) - For external querying and UI integration
*   26. `getAIOracleDetails(address _oracleAddress)`: Retrieves details about a specific AI Oracle.
*   27. `getCuratorDetails(address _curatorAddress)`: Retrieves details about a specific curator.
*   28. `getCreatorContentIds(address _creator)`: Retrieves a list of content IDs submitted by a specific creator.
*   29. `getSubscriptionTierDetails(uint256 _tierId)`: Retrieves details of a specific subscription tier.
*   30. `getUserSubscription(address _user)`: Retrieves a user's current subscription details.
*   31. `getProposalDetails(uint256 _proposalId)`: Retrieves details about a specific governance proposal.
*/
contract AetherFlow is AccessControl, ReentrancyGuard {
    using Counters for Counters.Counter;

    // --- State Variables ---
    IERC20 public immutable i_aetherToken; // The utility token of the platform

    Counters.Counter private s_contentIdCounter;
    Counters.Counter private s_proposalIdCounter;
    Counters.Counter private s_subscriptionTierIdCounter;

    // --- Configuration Constants (Can be made configurable via DAO in a full implementation) ---
    uint256 public constant MIN_CURATION_STAKE = 100e18; // Example: 100 AETHER tokens for a curator role
    uint256 public constant CONTENT_SUBMISSION_FEE = 5e18; // Fee for submitting content
    uint256 public constant AI_ORACLE_EVALUATION_FEE = 10e18; // Fee (bounty) paid by requester for AI Oracle evaluation
    uint256 public constant PROPOSAL_THRESHOLD = 5; // Minimum votes required for a proposal to pass
    uint256 public constant PROPOSAL_VOTING_PERIOD = 7 days; // How long proposals are open for voting
    uint256 public constant AI_APPROVAL_THRESHOLD = 700; // Minimum AI score (0-1000) for content to be "approved"

    // --- Roles for AccessControl ---
    bytes32 public constant DAO_MEMBER_ROLE = keccak256("DAO_MEMBER_ROLE");
    bytes32 public constant AI_ORACLE_ROLE = keccak256("AI_ORACLE_ROLE");
    bytes32 public constant CURATOR_ROLE = keccak256("CURATOR_ROLE");
    // DEFAULT_ADMIN_ROLE is inherited from AccessControl, initially granted to deployer.
    // It's used here internally for functions that should only be callable by the `executeProposal` mechanism.

    // --- Content Categories ---
    enum ContentCategory {
        UNKNOWN,
        AI_MODEL,          // Hashed AI model weights or code
        AI_DATASET,        // Hashed dataset for AI training
        AI_GENERATED_ART,  // Hashed image/media generated by AI
        AI_GENERATED_TEXT, // Hashed text content generated by AI
        RESEARCH_PAPER,    // Hashed research paper (could be AI-related)
        SOFTWARE_CODE      // Hashed software code (e.g., AI-related scripts)
    }

    // --- Data Structures ---

    // Represents a piece of content or data submitted to the platform.
    struct ContentCapsule {
        address creator;
        string ipfsHash;            // IPFS/Arweave hash of the actual content
        string metadataURI;         // URI to additional metadata (license, description, previews)
        uint256 category;           // ContentCategory enum value
        uint256 submissionTimestamp;
        bool isApprovedByAIOracle;  // True if evaluated above AI_APPROVAL_THRESHOLD
        uint256 aiEvaluationScore;  // Score from AI Oracle (e.g., 0-1000)
        address lastEvaluatorOracle; // The specific AI Oracle that last evaluated this content
        uint256 lastEvaluationTimestamp;
        uint256 totalFlowScoreEarned; // Total FlowScore this content has contributed to its creator
        uint256 totalEarningsClaimed; // Total AETHER earnings claimed by creator
        bool isActive;              // Can be deactivated by DAO or if challenge fails
        address currentChallenger;  // Address of challenger if a challenge is active (address(0) if none)
        uint256 challengeStake;     // Stake locked by the challenger
        uint256 challengeStartTimestamp;
    }
    mapping(uint256 => ContentCapsule) private s_contentCapsules;
    mapping(address => uint256[]) private s_creatorContentIds; // Creator's list of their content IDs

    // Represents an AI Oracle entity in the system.
    struct AIOracle {
        string oracleURI;           // URI to oracle's description/endpoint for off-chain communication
        bool isActive;              // True if whitelisted and active by DAO
        uint256 totalEvaluations;   // Total evaluations performed
        uint256 successfulEvaluations; // Evaluations where oracle's score matched consensus or was unchallenged
    }
    mapping(address => AIOracle) private s_aiOracles;

    // Represents a Curator entity in the system.
    struct Curator {
        uint256 stakedAmount;       // AETHER tokens staked for curation
        uint256 lastClaimTimestamp; // Timestamp of last reward claim, for time-based calculations
    }
    mapping(address => Curator) private s_curators;

    // Represents a user's reputation score (non-transferable).
    mapping(address => uint256) private s_flowScores; // Non-transferable internal reputation score

    // Defines a subscription tier for content access.
    struct SubscriptionTier {
        string name;                // Name of the tier (e.g., "AI Pro", "Data Enthusiast")
        uint256 pricePerMonth;      // Price in AETHER tokens per month
        uint256[] accessCategories; // Array of ContentCategory enum values this tier grants access to
        uint256 creatorRoyaltyShare; // Percentage (e.g., 7000 for 70%) of subscription price for creators
        uint256 platformFeeShare;   // Percentage (e.g., 2000 for 20%) that goes to the platform treasury
        uint256 curatorRewardShare; // Percentage (e.g., 1000 for 10%) that goes to curator reward pool
    }
    mapping(uint256 => SubscriptionTier) private s_subscriptionTiers;

    // Tracks a user's active subscription.
    struct UserSubscription {
        uint256 tierId;             // ID of the subscribed tier
        uint256 startTime;          // Timestamp when subscription started
        uint256 nextRenewalTime;    // Timestamp for next monthly renewal
        bool isActive;              // True if subscription is currently active
    }
    mapping(address => UserSubscription) private s_userSubscriptions;

    // Represents a governance proposal.
    struct Proposal {
        string description;         // Description of the proposed change
        address targetContract;     // The contract address the proposal aims to call
        bytes callData;             // The encoded function call (selector + arguments) for the target contract
        uint256 creationTimestamp;
        uint256 votesFor;
        uint256 votesAgainst;
        mapping(address => bool) hasVoted; // Tracks if an address has voted on this proposal
        bool executed;              // True if the proposal has been successfully executed
    }
    mapping(uint256 => Proposal) private s_proposals;

    // Tracks AETHER deposited by users into a general contract balance, separate from stakes.
    mapping(address => uint256) private s_userDepositedBalances;

    // --- Events ---
    event ContentCapsuleSubmitted(
        uint256 indexed contentId,
        address indexed creator,
        string ipfsHash,
        uint256 category
    );
    event AIOracleEvaluationReceived(
        uint256 indexed contentId,
        address indexed oracle,
        uint256 score
    );
    event AIOracleRegistered(address indexed oracleAddress, string oracleURI);
    event AIOracleDeactivated(address indexed oracleAddress);
    event CuratorStaked(address indexed curator, uint256 amount);
    event CuratorUnstaked(address indexed curator, uint256 amount);
    event ContentCurated(
        uint256 indexed contentId,
        address indexed curator,
        bool isApproved
    );
    event CurationRewardsClaimed(address indexed curator, uint256 amount);
    event SubscriptionTierCreated(
        uint256 indexed tierId,
        string name,
        uint256 price
    );
    event UserSubscribed(
        address indexed subscriber,
        uint256 indexed tierId,
        uint256 price
    );
    event UserUnsubscribed(address indexed subscriber);
    event CreatorEarningsClaimed(
        uint256 indexed contentId,
        address indexed creator,
        uint256 amount
    );
    event FlowScoreUpdated(address indexed user, uint256 newFlowScore);
    event ProposalCreated(
        uint256 indexed proposalId,
        string description,
        address indexed proposer
    );
    event ProposalVoted(
        uint256 indexed proposalId,
        address indexed voter,
        bool support
    );
    event ProposalExecuted(uint256 indexed proposalId);
    event AETHERDeposited(address indexed user, uint256 amount);
    event AETHERWithdrawn(address indexed user, uint256 amount);
    event ContentChallengeInitiated(
        uint256 indexed contentId,
        address indexed challenger,
        uint256 stake
    );
    event ContentChallengeResolved(
        uint256 indexed contentId,
        address indexed resolver,
        bool oracleWasCorrect
    );

    // --- Constructor ---
    constructor(address _aetherTokenAddress) {
        // Grant DEFAULT_ADMIN_ROLE to the deployer. This role is used internally for DAO execution.
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        // Grant DAO_MEMBER_ROLE to the deployer for initial governance participation.
        _grantRole(DAO_MEMBER_ROLE, msg.sender);
        i_aetherToken = IERC20(_aetherTokenAddress);
    }

    // --- Modifiers ---
    modifier onlyAIOracle() {
        if (!hasRole(AI_ORACLE_ROLE, _msgSender()))
            revert AetherFlow__NotAnAIOracle();
        _;
    }

    modifier onlyCurator() {
        if (!hasRole(CURATOR_ROLE, _msgSender()))
            revert AetherFlow__NotACurator();
        _;
    }

    modifier onlyDaoMember() {
        if (!hasRole(DAO_MEMBER_ROLE, _msgSender()))
            revert AetherFlow__NotEnoughVotes(); // Error name indicates permission issue here, not vote count
        _;
    }

    // --- Internal Functions ---
    /// @dev Updates a user's FlowScore, preventing underflow.
    /// @param _user The address of the user.
    /// @param _amount The amount to add (positive) or subtract (negative) from FlowScore.
    function _updateFlowScore(address _user, int256 _amount) internal {
        if (_amount > 0) {
            s_flowScores[_user] += uint256(_amount);
        } else {
            uint256 absAmount = uint256(-_amount);
            if (s_flowScores[_user] < absAmount) {
                s_flowScores[_user] = 0; // Prevent underflow, cap at 0
            } else {
                s_flowScores[_user] -= absAmount;
            }
        }
        emit FlowScoreUpdated(_user, s_flowScores[_user]);
    }

    // --- I. Core Content Management ---

    /// @notice Submits a new content capsule to the platform.
    /// Requires `CONTENT_SUBMISSION_FEE` to be sent with the transaction.
    /// @param _ipfsHash IPFS hash of the content (e.g., AI model, dataset, generated media).
    /// @param _category Category of the content from `ContentCategory` enum.
    /// @param _metadataURI URI pointing to additional metadata (e.g., license, description, previews).
    function submitContentCapsule(
        string memory _ipfsHash,
        uint256 _category,
        string memory _metadataURI
    ) public payable nonReentrant {
        if (msg.value < CONTENT_SUBMISSION_FEE)
            revert AetherFlow__InsufficientFunds();
        if (_category == uint256(ContentCategory.UNKNOWN))
            revert AetherFlow__ContentCategoryMismatch();

        uint256 contentId = s_contentIdCounter.current();
        s_contentIdCounter.increment();

        s_contentCapsules[contentId] = ContentCapsule({
            creator: msg.sender,
            ipfsHash: _ipfsHash,
            metadataURI: _metadataURI,
            category: _category,
            submissionTimestamp: block.timestamp,
            isApprovedByAIOracle: false, // Needs AI evaluation
            aiEvaluationScore: 0,
            lastEvaluatorOracle: address(0),
            lastEvaluationTimestamp: 0,
            totalFlowScoreEarned: 0,
            totalEarningsClaimed: 0,
            isActive: true,
            currentChallenger: address(0),
            challengeStake: 0,
            challengeStartTimestamp: 0
        });
        s_creatorContentIds[msg.sender].push(contentId);
        emit ContentCapsuleSubmitted(
            contentId,
            msg.sender,
            _ipfsHash,
            _category
        );

        // Refund any excess payment
        if (msg.value > CONTENT_SUBMISSION_FEE) {
            payable(msg.sender).transfer(msg.value - CONTENT_SUBMISSION_FEE);
        }
    }

    /// @notice Gets the details of a specific content capsule.
    /// @param _contentId The ID of the content capsule.
    /// @return ContentCapsule struct details.
    function getContentCapsuleDetails(
        uint256 _contentId
    ) public view returns (ContentCapsule memory) {
        if (s_contentIdCounter.current() <= _contentId)
            revert AetherFlow__ContentNotFound();
        return s_contentCapsules[_contentId];
    }

    /// @notice Requests an AI Oracle evaluation for a content capsule.
    /// Callable by anyone, but requires `AI_ORACLE_EVALUATION_FEE` to be sent.
    /// This fee typically serves as a bounty for the off-chain oracle network.
    /// @param _contentId The ID of the content capsule to evaluate.
    function requestAIOracleEvaluation(
        uint256 _contentId
    ) public payable nonReentrant {
        if (s_contentIdCounter.current() <= _contentId)
            revert AetherFlow__ContentNotFound();
        if (msg.value < AI_ORACLE_EVALUATION_FEE)
            revert AetherFlow__InsufficientFunds();

        // In a real system, this would trigger an off-chain Chainlink request or similar.
        // The fee would be held for distribution to the oracle that fulfills the request.
        // For this contract, the fee is deposited to the contract's balance,
        // and its distribution would be handled by other mechanisms (e.g., DAO payout or automated).
    }

    /// @notice Receives an AI Oracle evaluation result for a content capsule.
    /// Only callable by whitelisted AI Oracles.
    /// @param _contentId The ID of the content capsule.
    /// @param _aiScore The evaluation score from the AI Oracle (e.g., 0-1000).
    /// @param _evaluatorOracle The address of the AI Oracle that performed the evaluation.
    /// @param _evaluationHash A hash of the full evaluation report/proof (for off-chain verification).
    function receiveAIOracleEvaluation(
        uint256 _contentId,
        uint256 _aiScore,
        address _evaluatorOracle,
        string memory _evaluationHash
    ) public onlyAIOracle {
        // Ensure the calling oracle is the one specified in the parameters if multiple oracles submit.
        // For simplicity, we just check `onlyAIOracle` on the sender.
        if (_evaluatorOracle != msg.sender) revert AetherFlow__NotAnAIOracle();

        ContentCapsule storage content = s_contentCapsules[_contentId];
        if (s_contentIdCounter.current() <= _contentId)
            revert AetherFlow__ContentNotFound();
        if (content.lastEvaluationTimestamp != 0)
            revert AetherFlow__AlreadyEvaluated(); // Prevents multiple evaluations for a single request

        content.aiEvaluationScore = _aiScore;
        content.lastEvaluationTimestamp = block.timestamp;
        content.isApprovedByAIOracle = (_aiScore >= AI_APPROVAL_THRESHOLD);
        content.lastEvaluatorOracle = _evaluatorOracle; // Store which oracle did the evaluation

        // Reward the oracle and creator based on evaluation outcome
        s_aiOracles[_evaluatorOracle].totalEvaluations++;
        if (content.isApprovedByAIOracle) {
            s_aiOracles[_evaluatorOracle].successfulEvaluations++;
            _updateFlowScore(_evaluatorOracle, 5); // Reward oracle for good evaluation
            _updateFlowScore(content.creator, 10); // Reward creator for approved content
        } else {
            _updateFlowScore(_evaluatorOracle, -2); // Small penalty for evaluations that don't meet threshold
        }

        emit AIOracleEvaluationReceived(
            _contentId,
            _evaluatorOracle,
            _aiScore
        );
    }

    /// @notice Allows the creator to update metadata of their content capsule.
    /// Only possible if content is not yet approved by an AI Oracle. Once approved, changes typically
    /// require a DAO proposal to ensure integrity.
    /// @param _contentId The ID of the content capsule.
    /// @param _newMetadataURI The new URI for metadata.
    function updateContentMetadata(
        uint256 _contentId,
        string memory _newMetadataURI
    ) public {
        ContentCapsule storage content = s_contentCapsules[_contentId];
        if (s_contentIdCounter.current() <= _contentId)
            revert AetherFlow__ContentNotFound();
        if (content.creator != msg.sender)
            revert AetherFlow__NotCreatorOfContent();
        if (content.isApprovedByAIOracle)
            revert AetherFlow__CannotUpdateApprovedContent(); // After AI approval, updates require DAO
        if (!content.isActive)
            revert AetherFlow__CannotUpdateApprovedContent(); // Can't update inactive content

        content.metadataURI = _newMetadataURI;
    }

    // --- II. AI Oracle & Evaluation System ---

    /// @notice Proposes an AI Oracle for whitelisting. This starts a DAO vote.
    /// Only callable by DAO members.
    /// @param _oracleAddress The address of the AI Oracle.
    /// @param _oracleURI URI pointing to the oracle's description/documentation.
    function proposeAIOracle(
        address _oracleAddress,
        string memory _oracleURI
    ) public onlyDaoMember {
        if (s_aiOracles[_oracleAddress].isActive)
            revert AetherFlow__OracleAlreadyRegistered();
        // Create a governance proposal to register this oracle
        bytes memory callData = abi.encodeWithSelector(
            this.registerAIOracle.selector,
            _oracleAddress,
            _oracleURI
        );
        _createProposal(
            string(abi.encodePacked("Register new AI Oracle: ", _oracleURI)),
            address(this),
            callData
        );
    }

    /// @notice Registers a new AI Oracle and grants it the `AI_ORACLE_ROLE`.
    /// This function is designed to be callable ONLY by the contract itself through a successful
    /// DAO proposal execution (via `executeProposal`). The `DEFAULT_ADMIN_ROLE` check is a mechanism
    /// to restrict direct external calls, ensuring proper governance.
    /// @param _oracleAddress The address of the AI Oracle.
    /// @param _oracleURI URI pointing to the oracle's description/documentation.
    function registerAIOracle(
        address _oracleAddress,
        string memory _oracleURI
    ) public onlyRole(DEFAULT_ADMIN_ROLE) {
        if (s_aiOracles[_oracleAddress].isActive)
            revert AetherFlow__OracleAlreadyRegistered();

        s_aiOracles[_oracleAddress] = AIOracle({
            oracleURI: _oracleURI,
            isActive: true,
            totalEvaluations: 0,
            successfulEvaluations: 0
        });
        _grantRole(AI_ORACLE_ROLE, _oracleAddress);
        emit AIOracleRegistered(_oracleAddress, _oracleURI);
    }

    /// @notice Deactivates an AI Oracle and revokes its `AI_ORACLE_ROLE`.
    /// This function is designed to be callable ONLY by the contract itself through a successful
    /// DAO proposal execution (via `executeProposal`).
    /// @param _oracleAddress The address of the AI Oracle to deactivate.
    function deactivateAIOracle(
        address _oracleAddress
    ) public onlyRole(DEFAULT_ADMIN_ROLE) {
        if (!s_aiOracles[_oracleAddress].isActive)
            revert AetherFlow__OracleNotRegistered();
        if (!hasRole(AI_ORACLE_ROLE, _oracleAddress))
            revert AetherFlow__OracleAlreadyDeactivated(); // Role already revoked or never active

        s_aiOracles[_oracleAddress].isActive = false;
        _revokeRole(AI_ORACLE_ROLE, _oracleAddress); // Revoke the role
        emit AIOracleDeactivated(_oracleAddress);
    }

    /// @notice Allows a user to challenge an AI Oracle's evaluation of content.
    /// Requires a stake that is locked during the challenge. This stake is used to penalize
    /// the challenger if their claim is found to be false.
    /// @param _contentId The ID of the content capsule whose evaluation is being challenged.
    /// @param _challengerStake The amount of AETHER tokens staked for the challenge.
    function challengeAIOracleEvaluation(
        uint256 _contentId,
        uint256 _challengerStake
    ) public nonReentrant {
        ContentCapsule storage content = s_contentCapsules[_contentId];
        if (s_contentIdCounter.current() <= _contentId)
            revert AetherFlow__ContentNotFound();
        if (content.currentChallenger != address(0))
            revert AetherFlow__ChallengeAlreadyInitiated();
        if (_challengerStake == 0) revert AetherFlow__InvalidAmount();
        if (!content.isApprovedByAIOracle) {
            // Can only challenge already approved content's evaluation.
            // Other content is handled by curators.
            revert AetherFlow__CannotUpdateApprovedContent();
        }

        i_aetherToken.transferFrom(msg.sender, address(this), _challengerStake);

        content.currentChallenger = msg.sender;
        content.challengeStake = _challengerStake;
        content.challengeStartTimestamp = block.timestamp;

        // Optionally, a DAO proposal could be automatically created here for review.
        emit ContentChallengeInitiated(
            _contentId,
            msg.sender,
            _challengerStake
        );
    }

    /// @notice Resolves an AI Oracle evaluation challenge.
    /// Callable only by DAO members after reviewing the challenge and associated evidence.
    /// @param _contentId The ID of the content capsule.
    /// @param _oracleWasCorrect True if the original AI Oracle's evaluation was deemed correct.
    function resolveChallenge(
        uint256 _contentId,
        bool _oracleWasCorrect
    ) public onlyDaoMember nonReentrant {
        ContentCapsule storage content = s_contentCapsules[_contentId];
        if (s_contentIdCounter.current() <= _contentId)
            revert AetherFlow__ContentNotFound();
        if (content.currentChallenger == address(0))
            revert AetherFlow__NoActiveChallenge();

        address challenger = content.currentChallenger;
        address evaluatorOracle = content.lastEvaluatorOracle;
        uint256 stake = content.challengeStake;

        if (_oracleWasCorrect) {
            // Oracle was correct: Challenger loses stake. Stake is transferred to platform treasury.
            // The stake remains in the contract, now part of the general treasury.
            _updateFlowScore(evaluatorOracle, 10); // Oracle gains reputation for correct evaluation
            _updateFlowScore(challenger, -15); // Challenger penalized for false claim
            _updateFlowScore(content.creator, 5); // Creator's content verified
        } else {
            // Oracle was incorrect: Challenger gets stake back and a reward. Oracle gets penalized.
            i_aetherToken.transfer(challenger, stake); // Return stake to challenger
            // Additional reward to challenger for exposing incorrect oracle
            if (i_aetherToken.balanceOf(address(this)) >= stake / 2) {
                i_aetherToken.transfer(challenger, stake / 2); // Example reward: half of stake
            }
            _updateFlowScore(challenger, 15); // Challenger rewarded
            _updateFlowScore(evaluatorOracle, -10); // Oracle penalized for incorrect evaluation
            // If the oracle was proven incorrect, content's approval status might be revisited
            content.isApprovedByAIOracle = false;
        }

        // Reset challenge state
        content.currentChallenger = address(0);
        content.challengeStake = 0;
        content.challengeStartTimestamp = 0;

        emit ContentChallengeResolved(_contentId, msg.sender, _oracleWasCorrect);
    }

    // --- III. Curation & Staking ---

    /// @notice Stakes AETHER tokens to become a content curator or increase existing stake.
    /// Requires a minimum stake (`MIN_CURATION_STAKE`) to be granted the `CURATOR_ROLE`.
    /// @param _amount The amount of AETHER tokens to stake.
    function stakeForCuration(uint256 _amount) public nonReentrant {
        if (_amount == 0) revert AetherFlow__InvalidAmount();

        i_aetherToken.transferFrom(msg.sender, address(this), _amount);
        s_curators[msg.sender].stakedAmount += _amount;
        // Grant curator role if minimum stake is met and role not already granted
        if (
            !hasRole(CURATOR_ROLE, msg.sender) &&
            s_curators[msg.sender].stakedAmount >= MIN_CURATION_STAKE
        ) {
            _grantRole(CURATOR_ROLE, msg.sender);
            s_curators[msg.sender].lastClaimTimestamp = block.timestamp; // Initialize for new curators
        }
        emit CuratorStaked(msg.sender, _amount);
    }

    /// @notice Unstakes all AETHER tokens from curation.
    /// The `CURATOR_ROLE` is revoked upon full unstake.
    function unstakeFromCuration() public nonReentrant {
        uint256 staked = s_curators[msg.sender].stakedAmount;
        if (staked == 0) revert AetherFlow__NotEnoughStaked();

        // In a real system, there might be a cool-down period or a withdrawal fee.
        i_aetherToken.transfer(msg.sender, staked);
        s_curators[msg.sender].stakedAmount = 0;
        _revokeRole(CURATOR_ROLE, msg.sender); // Revoke role upon full unstake
        emit CuratorUnstaked(msg.sender, staked);
    }

    /// @notice Allows a curator to approve or disapprove content.
    /// This action affects the content's internal visibility/score and the curator's FlowScore.
    /// Curators primarily evaluate content that is not yet fully approved by AI Oracles.
    /// @param _contentId The ID of the content capsule.
    /// @param _isApproved True if approving, false if disapproving.
    /// @param _reasonHash Hash of an off-chain reason/justification for the decision.
    function curateContent(
        uint256 _contentId,
        bool _isApproved,
        string memory _reasonHash
    ) public onlyCurator {
        if (s_contentIdCounter.current() <= _contentId)
            revert AetherFlow__ContentNotFound();
        ContentCapsule storage content = s_contentCapsules[_contentId];

        // Curators should primarily curate content not yet fully approved by AI.
        if (content.isApprovedByAIOracle) {
            revert AetherFlow__CannotUpdateApprovedContent();
        }

        // Basic logic: a curator's vote affects FlowScore.
        // Can be expanded with weighted voting based on stake or reputation.
        if (_isApproved) {
            _updateFlowScore(msg.sender, 2); // Reward for approving
            content.totalFlowScoreEarned += 1; // Content gets a tiny boost
        } else {
            _updateFlowScore(msg.sender, -1); // Small penalty for disapproving (to prevent spam/malicious disapproval)
        }
        emit ContentCurated(_contentId, msg.sender, _isApproved);
    }

    /// @notice Allows curators to claim their accumulated rewards.
    /// Rewards are based on staked amount, active curation time, and a share of platform fees.
    /// Rewards are drawn from the contract's accumulated balance from subscriptions and fees.
    function claimCurationRewards() public onlyCurator nonReentrant {
        Curator storage curator = s_curators[msg.sender];
        if (curator.stakedAmount == 0) revert AetherFlow__NotEnoughStaked();

        // Example reward calculation: Time-based reward + share from platform fees.
        // Simplified: (time_elapsed * staked_amount * annual_percentage) / 365 days
        uint256 rewards = ((block.timestamp - curator.lastClaimTimestamp) *
            curator.stakedAmount) / (30 days) / 100; // Example: approx. 1% monthly reward rate (simplified)
        // A more robust system would involve a `curatorRewardPool` balance accumulated from subscription fees.

        if (rewards == 0) revert AetherFlow__InsufficientFunds(); // Or a custom error like AetherFlow__NoRewardsAvailable()

        // Ensure the contract holds enough AETHER for rewards.
        if (i_aetherToken.balanceOf(address(this)) < rewards) {
            revert AetherFlow__InsufficientFunds();
        }

        i_aetherToken.transfer(msg.sender, rewards);
        curator.lastClaimTimestamp = block.timestamp; // Update last claim timestamp
        emit CurationRewardsClaimed(msg.sender, rewards);
    }

    // --- IV. Monetization & Subscriptions ---

    /// @notice Creates a new subscription tier.
    /// This function is designed to be callable ONLY by the contract itself through a successful
    /// DAO proposal execution. It requires the shares to sum to 100%.
    /// @param _name Name of the tier (e.g., "AI Developer Access").
    /// @param _pricePerMonth Price in AETHER tokens per month.
    /// @param _accessCategories Array of content categories this tier grants access to.
    /// @param _creatorRoyaltyShare Percentage (e.g., 7000 for 70%) of subscription price for creators.
    /// @param _platformFeeShare Percentage (e.g., 2000 for 20%) that goes to the platform treasury.
    /// @param _curatorRewardShare Percentage (e.g., 1000 for 10%) that goes to curator reward pool.
    function createSubscriptionTier(
        string memory _name,
        uint256 _pricePerMonth,
        uint256[] memory _accessCategories,
        uint256 _creatorRoyaltyShare,
        uint256 _platformFeeShare,
        uint256 _curatorRewardShare
    ) public onlyRole(DEFAULT_ADMIN_ROLE) {
        if (_creatorRoyaltyShare + _platformFeeShare + _curatorRewardShare != 10000) {
            revert AetherFlow__SharesSumMismatch(); // Shares must sum to 100% (10000 basis points)
        }

        uint256 tierId = s_subscriptionTierIdCounter.current();
        s_subscriptionTierIdCounter.increment();

        s_subscriptionTiers[tierId] = SubscriptionTier({
            name: _name,
            pricePerMonth: _pricePerMonth,
            accessCategories: _accessCategories,
            creatorRoyaltyShare: _creatorRoyaltyShare,
            platformFeeShare: _platformFeeShare,
            curatorRewardShare: _curatorRewardShare
        });
        emit SubscriptionTierCreated(tierId, _name, _pricePerMonth);
    }

    /// @notice Allows a user to subscribe to a content tier.
    /// The subscription fee is paid from the user's AETHER token balance.
    /// @param _tierId The ID of the subscription tier.
    function subscribe(uint256 _tierId) public nonReentrant {
        SubscriptionTier storage tier = s_subscriptionTiers[_tierId];
        if (tier.pricePerMonth == 0 && s_subscriptionTierIdCounter.current() <= _tierId)
            revert AetherFlow__SubscriptionNotFound(); // Tier does not exist or has zero price (invalid)

        UserSubscription storage currentSub = s_userSubscriptions[msg.sender];
        if (currentSub.isActive && currentSub.nextRenewalTime > block.timestamp)
            revert AetherFlow__AlreadySubscribed();

        // Transfer subscription fee from user to contract
        i_aetherToken.transferFrom(msg.sender, address(this), tier.pricePerMonth);

        // Distribute fees immediately to their respective pools/holders (simplified)
        uint256 creatorShare = (tier.pricePerMonth * tier.creatorRoyaltyShare) / 10000;
        uint256 platformShare = (tier.pricePerMonth * tier.platformFeeShare) / 10000;
        uint256 curatorShare = (tier.pricePerMonth * tier.curatorRewardShare) / 10000;

        // Creator share is accumulated for later claiming (or distributed directly to specific creators)
        // For simplicity, platform and curator shares accumulate in the contract for later distribution/management.
        // Creator share: This would need to be assigned to a general "creator pool" or specific creators based on content consumption.
        // For now, these shares remain in the contract and are conceptual.
        // A more advanced system would have specific accounting for each.

        currentSub.tierId = _tierId;
        currentSub.startTime = block.timestamp;
        currentSub.nextRenewalTime = block.timestamp + 30 days; // Assuming 30 days = 1 month
        currentSub.isActive = true;

        emit UserSubscribed(msg.sender, _tierId, tier.pricePerMonth);
    }

    /// @notice Allows a user to unsubscribe from their current subscription.
    /// This typically marks the subscription as inactive and prevents future renewals.
    function unsubscribe() public nonReentrant {
        UserSubscription storage currentSub = s_userSubscriptions[msg.sender];
        if (!currentSub.isActive)
            revert AetherFlow__NotSubscribed();

        // For simplicity, this just marks as inactive. A real system might offer prorated refunds
        // or allow access until the end of the current billing period.
        currentSub.isActive = false;
        currentSub.tierId = 0; // Reset tier
        emit UserUnsubscribed(msg.sender);
    }

    /// @notice Checks if a user has an active subscription for a given content category.
    /// @param _subscriber The address of the subscriber.
    /// @param _contentCategory The category of content to check access for.
    /// @return True if the user has an active subscription covering the category, false otherwise.
    function getSubscriptionStatus(
        address _subscriber,
        uint256 _contentCategory
    ) public view returns (bool) {
        UserSubscription storage sub = s_userSubscriptions[_subscriber];
        // Check if subscription is active and not expired
        if (!sub.isActive || sub.nextRenewalTime < block.timestamp) {
            return false;
        }

        SubscriptionTier storage tier = s_subscriptionTiers[sub.tierId];
        // Check if the subscribed tier includes access to the requested category
        for (uint256 i = 0; i < tier.accessCategories.length; i++) {
            if (tier.accessCategories[i] == _contentCategory) {
                return true;
            }
        }
        return false;
    }

    /// @notice Allows a content creator to claim earnings from their approved content.
    /// Earnings are based on subscription revenue allocated to creators and content's FlowScore.
    /// @param _contentId The ID of the content capsule.
    function claimCreatorEarnings(uint256 _contentId) public nonReentrant {
        ContentCapsule storage content = s_contentCapsules[_contentId];
        if (s_contentIdCounter.current() <= _contentId)
            revert AetherFlow__ContentNotFound();
        if (content.creator != msg.sender)
            revert AetherFlow__NotCreatorOfContent();
        if (!content.isApprovedByAIOracle)
            revert AetherFlow__CannotUpdateApprovedContent(); // Only AI-approved content earns

        // Calculate potential earnings based on content's FlowScore (simplified model)
        // In a complex system, this would involve tracking how many subscribers accessed this specific content
        // and its share of the `creatorRoyaltyShare` from each subscription.
        uint256 potentialEarnings = content.totalFlowScoreEarned * 1e18 / 100; // Example: 0.01 AETHER per FlowScore point
        uint256 unclaimedEarnings = potentialEarnings - content.totalEarningsClaimed;

        if (unclaimedEarnings == 0) revert AetherFlow__InsufficientFunds();

        // Ensure the contract has enough funds. These funds would primarily come from the `creatorRoyaltyShare`
        // of collected subscription fees, which are held by the contract.
        if (i_aetherToken.balanceOf(address(this)) < unclaimedEarnings) {
             revert AetherFlow__InsufficientFunds();
        }

        i_aetherToken.transfer(msg.sender, unclaimedEarnings);
        content.totalEarningsClaimed += unclaimedEarnings;

        emit CreatorEarningsClaimed(_contentId, msg.sender, unclaimedEarnings);
    }

    // --- V. Governance (DAO related) ---

    /// @notice Creates a new governance proposal.
    /// Only callable by DAO members.
    /// @param _description Description of the proposal.
    /// @param _targetContract The address of the contract the proposal aims to interact with (often `address(this)`).
    /// @param _callData The encoded function call (selector + arguments) for the target contract.
    function proposeGovernanceChange(
        string memory _description,
        address _targetContract,
        bytes memory _callData
    ) public onlyDaoMember {
        uint256 proposalId = s_proposalIdCounter.current();
        s_proposalIdCounter.increment();

        s_proposals[proposalId] = Proposal({
            description: _description,
            targetContract: _targetContract,
            callData: _callData,
            creationTimestamp: block.timestamp,
            votesFor: 0,
            votesAgainst: 0,
            executed: false
        });
        // Set the sender as having voted for their own proposal implicitly to prevent self-voting shenanigans, or require them to vote explicitly later.
        // For simplicity, they start with 0 votes, and must vote like others.
        emit ProposalCreated(proposalId, _description, msg.sender);
    }

    /// @notice Allows a DAO member to vote on an active proposal.
    /// @param _proposalId The ID of the proposal.
    /// @param _support True for 'for' the proposal, false for 'against'.
    function voteOnProposal(uint256 _proposalId, bool _support) public onlyDaoMember {
        Proposal storage proposal = s_proposals[_proposalId];
        if (s_proposalIdCounter.current() <= _proposalId)
            revert AetherFlow__ProposalNotFound();
        if (block.timestamp > proposal.creationTimestamp + PROPOSAL_VOTING_PERIOD)
            revert AetherFlow__VotingPeriodNotActive(); // Voting period has ended
        if (proposal.hasVoted[msg.sender]) revert AetherFlow__AlreadyVoted();
        if (proposal.executed) revert AetherFlow__ProposalAlreadyExecuted();

        if (_support) {
            proposal.votesFor++;
        } else {
            proposal.votesAgainst++;
        }
        proposal.hasVoted[msg.sender] = true;
        emit ProposalVoted(_proposalId, msg.sender, _support);
    }

    /// @notice Executes a successful governance proposal.
    /// Can only be called after the voting period has ended and if enough 'for' votes are cast.
    /// @param _proposalId The ID of the proposal to execute.
    function executeProposal(uint256 _proposalId) public nonReentrant {
        Proposal storage proposal = s_proposals[_proposalId];
        if (s_proposalIdCounter.current() <= _proposalId)
            revert AetherFlow__ProposalNotFound();
        if (block.timestamp < proposal.creationTimestamp + PROPOSAL_VOTING_PERIOD)
            revert AetherFlow__ProposalNotYetExecutable(); // Voting period not over
        if (proposal.executed) revert AetherFlow__ProposalAlreadyExecuted();
        if (proposal.votesFor < PROPOSAL_THRESHOLD)
            revert AetherFlow__NotEnoughVotes(); // Proposal did not pass

        // Execute the call to the target contract.
        // Functions like `registerAIOracle` or `createSubscriptionTier` are called here with DEFAULT_ADMIN_ROLE.
        (bool success, ) = proposal.targetContract.call(proposal.callData);
        require(success, "AetherFlow: Proposal execution failed");

        proposal.executed = true;
        emit ProposalExecuted(_proposalId);
    }

    // --- VI. Token & Utility (Assuming an ERC-20 utility token, 'AETHER') ---

    /// @notice Allows users to deposit AETHER tokens into the contract.
    /// These tokens are stored in the user's internal balance and can be used for subscriptions, staking, etc.
    /// @param _amount The amount of AETHER tokens to deposit.
    function depositAETHER(uint256 _amount) public nonReentrant {
        if (_amount == 0) revert AetherFlow__InvalidAmount();
        i_aetherToken.transferFrom(msg.sender, address(this), _amount);
        s_userDepositedBalances[msg.sender] += _amount; // Track user's deposited balance
        emit AETHERDeposited(msg.sender, _amount);
    }

    /// @notice Allows users to withdraw their AETHER tokens from their internal contract balance.
    /// Funds can only be withdrawn if not currently locked in stakes or active subscriptions.
    /// For this simple implementation, it draws from a generic user-deposited balance.
    /// @param _amount The amount of AETHER tokens to withdraw.
    function withdrawAETHER(uint256 _amount) public nonReentrant {
        if (_amount == 0) revert AetherFlow__InvalidAmount();
        // Ensure user has enough available balance that isn't locked in stakes or active subscriptions.
        // This simplified implementation assumes `s_userDepositedBalances` is the "free" balance.
        if (s_userDepositedBalances[msg.sender] < _amount)
            revert AetherFlow__InsufficientFunds();

        s_userDepositedBalances[msg.sender] -= _amount;
        i_aetherToken.transfer(msg.sender, _amount);
        emit AETHERWithdrawn(msg.sender, _amount);
    }

    // --- VII. Reputation System ---

    /// @notice Retrieves the FlowScore (reputation) of a user.
    /// FlowScore is a non-transferable internal metric.
    /// @param _user The address of the user.
    /// @return The FlowScore of the user.
    function getFlowScore(address _user) public view returns (uint256) {
        return s_flowScores[_user];
    }

    // --- VIII. Helper Getters (for testing and UI) ---

    /// @notice Retrieves the internal deposited AETHER balance of a user.
    /// @param _user The address of the user.
    /// @return The internal AETHER balance.
    function getUserDepositedBalance(
        address _user
    ) public view returns (uint256) {
        return s_userDepositedBalances[_user];
    }

    /// @notice Retrieves details about a specific AI Oracle.
    /// @param _oracleAddress The address of the AI Oracle.
    /// @return AIOracle struct containing its URI, activity status, and evaluation counts.
    function getAIOracleDetails(
        address _oracleAddress
    ) public view returns (AIOracle memory) {
        return s_aiOracles[_oracleAddress];
    }

    /// @notice Retrieves details about a specific curator.
    /// @param _curatorAddress The address of the curator.
    /// @return Curator struct containing staked amount and last claim timestamp.
    function getCuratorDetails(
        address _curatorAddress
    ) public view returns (Curator memory) {
        return s_curators[_curatorAddress];
    }

    /// @notice Retrieves a list of content IDs submitted by a given creator.
    /// @param _creator The address of the content creator.
    /// @return An array of content IDs.
    function getCreatorContentIds(
        address _creator
    ) public view returns (uint256[] memory) {
        return s_creatorContentIds[_creator];
    }

    /// @notice Retrieves details of a specific subscription tier.
    /// @param _tierId The ID of the subscription tier.
    /// @return SubscriptionTier struct containing its name, price, access categories, and share percentages.
    function getSubscriptionTierDetails(
        uint256 _tierId
    ) public view returns (SubscriptionTier memory) {
        if (s_subscriptionTierIdCounter.current() <= _tierId)
            revert AetherFlow__SubscriptionNotFound();
        return s_subscriptionTiers[_tierId];
    }

    /// @notice Retrieves a user's current subscription details.
    /// @param _user The address of the user.
    /// @return UserSubscription struct containing tier ID, start time, next renewal time, and active status.
    function getUserSubscription(
        address _user
    ) public view returns (UserSubscription memory) {
        return s_userSubscriptions[_user];
    }

    /// @notice Retrieves details about a specific governance proposal.
    /// @param _proposalId The ID of the proposal.
    /// @return Proposal struct containing its description, target, call data, votes, and execution status.
    function getProposalDetails(
        uint256 _proposalId
    ) public view returns (Proposal memory) {
        if (s_proposalIdCounter.current() <= _proposalId)
            revert AetherFlow__ProposalNotFound();
        return s_proposals[_proposalId];
    }
}
```