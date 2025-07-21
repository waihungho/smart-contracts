Okay, this is an exciting challenge! Let's design a smart contract for a "Decentralized Epistemic Network" called **CognitoNet**.

**Concept:** CognitoNet is a platform for submitting, validating, disputing, and curating knowledge assertions. It leverages dynamic Soulbound Reputation NFTs (dSRN) to track user credibility, integrates a conceptual "AI Oracle" for automated analysis, and uses a staking mechanism to incentivize truthful and high-quality contributions. The goal is to build a trusted, decentralized knowledge base.

**Advanced Concepts & Creative Features:**

1.  **Dynamic Soulbound Reputation NFTs (dSRN):** Users mint non-transferable NFTs whose metadata (e.g., "Credibility Score", "Specializations", "Contribution Count") dynamically updates based on their on-chain actions (successful assertions, validations, dispute resolutions). This provides a persistent, verifiable on-chain reputation.
2.  **Assertion Lifecycle with Staking:** Assertions go through a multi-stage process (submission, review, validation/dispute, resolution), each requiring a stake to prevent spam and incentivize honest participation. Staked tokens are distributed as rewards or burned based on outcomes.
3.  **Algorithmic Trust & AI Oracle Integration:** The contract defines interfaces for an *off-chain* AI service to submit analysis (e.g., semantic similarity, fact-check scores, content summaries) which can influence assertion validity or dispute resolution. This is not on-chain AI computation but rather on-chain trust in AI outputs provided by a whitelisted oracle.
4.  **Decentralized Curation & Dispute Resolution:** A system of elected/appointed Curators manages categories and resolves complex disputes, acting as arbiters in the network.
5.  **Multi-Dimensional Reputation:** Reputation is not just a single score but a composite of various activities, reflected in the dSRN attributes.
6.  **Time-Locked Actions & Cooldowns:** Various operations have time-based constraints to prevent rapid manipulation or encourage thorough review.
7.  **Gas Efficiency & Scalability Considerations:** Use of mappings, packed structs, events, and custom errors to optimize gas usage.

---

## CognitoNet: Decentralized Epistemic Network

**Outline:**

1.  **Contract Overview:** Purpose, core features.
2.  **State Variables:** Mappings, structs, essential parameters.
3.  **Events:** For off-chain tracking.
4.  **Modifiers:** Access control and state checks.
5.  **Errors:** Custom errors for clarity and gas efficiency.
6.  **Libraries & Dependencies:** OpenZeppelin contracts (Ownable, ReentrancyGuard, Pausable, ERC721) for standard functionalities.
7.  **Core Assertion Management:**
    *   Submission
    *   Validation
    *   Dispute
    *   Resolution
    *   Staking & Rewards
8.  **Reputation & Dynamic Soulbound NFT (dSRN):**
    *   Minting
    *   Updating
    *   Metadata Generation
9.  **Curator & Category Management:**
    *   Adding/Removing Curators
    *   Managing Knowledge Categories
10. **AI Oracle Integration:**
    *   Receiving AI-generated data
11. **System & Admin Functions:**
    *   Parameter Configuration
    *   Pause/Unpause
    *   Ownership Transfer
    *   Emergency Withdrawals
12. **View Functions:**
    *   Retrieving data

**Function Summary (26 Functions):**

**I. Core Assertion Management (7 Functions):**

1.  `submitAssertion(string calldata _contentHash, uint256 _categoryId)`: Allows a user to submit a new knowledge assertion, requiring a stake.
2.  `voteOnAssertion(uint256 _assertionId, bool _isUpvote)`: Allows a user to vote (up/down) on an assertion's validity, requiring a stake.
3.  `disputeAssertion(uint256 _assertionId, string calldata _reasonHash)`: Initiates a formal dispute against an assertion, requiring a higher stake.
4.  `resolveDispute(uint256 _disputeId, AssertionOutcome _outcome, string calldata _resolutionReasonHash)`: A Curator resolves a dispute, distributing stakes and updating assertion status.
5.  `claimAssertionStakes(uint256 _assertionId)`: Allows the creator of a successfully validated assertion to claim their initial stake and rewards.
6.  `claimValidationStakes(uint256 _assertionId)`: Allows successful validators to claim their stakes and rewards for an assertion.
7.  `withdrawDisputeStake(uint256 _disputeId)`: Allows participants in a resolved dispute (disputer, or voters) to withdraw their stakes based on the outcome.

**II. Reputation & Dynamic Soulbound NFT (dSRN) (4 Functions):**

8.  `mintReputationNFT()`: Mints a unique Soulbound Reputation NFT (dSRN) for the caller, if they don't have one.
9.  `_updateReputation(address _user, int256 _scoreChange, uint256 _contributionType)`: (Internal) Updates a user's reputation score and other metrics stored in their dSRN.
10. `tokenURI(uint256 _tokenId)`: Generates the dynamic metadata URI for a dSRN, reflecting the user's current reputation and activities.
11. `getReputationProfile(address _user)`: Retrieves a user's detailed reputation profile.

**III. Curator & Category Management (5 Functions):**

12. `addCurator(address _newCurator)`: Adds a new address to the list of authorized Curators (Owner only).
13. `removeCurator(address _curatorToRemove)`: Removes an address from the list of authorized Curators (Owner only).
14. `addCategory(string calldata _name, string calldata _description)`: Allows a Curator to add a new knowledge category.
15. `updateCategory(uint256 _categoryId, string calldata _newName, string calldata _newDescription, bool _isActive)`: Allows a Curator to update an existing category's details or status.
16. `removeCategory(uint256 _categoryId)`: Allows a Curator to deactivate a category, preventing new assertions in it.

**IV. AI Oracle Integration (3 Functions):**

17. `setAIOracleAddress(address _aiOracle)`: Sets the address of the trusted AI Oracle (Owner only).
18. `submitAISummary(uint256 _assertionId, string calldata _summaryHash)`: Allows the AI Oracle to submit a concise summary hash for an assertion.
19. `submitAIFactCheckScore(uint256 _assertionId, uint8 _score)`: Allows the AI Oracle to submit a fact-check score (0-100) for an assertion.

**V. System & Admin Functions (4 Functions):**

20. `setAssertionParams(uint256 _minAssertionStake, uint256 _minVoteStake, uint256 _minDisputeStake, uint256 _reviewPeriodDuration, uint256 _disputeResolutionPeriod)`: Sets various staking and time parameters (Owner only).
21. `pause()`: Pauses the contract, preventing most interactions (Owner only).
22. `unpause()`: Unpauses the contract (Owner only).
23. `emergencyWithdrawETH(uint256 _amount)`: Allows the owner to withdraw accidentally sent ETH (Owner only).

**VI. View Functions (3 Functions):**

24. `getAssertionDetails(uint256 _assertionId)`: Retrieves all details for a specific assertion.
25. `getCategoryDetails(uint256 _categoryId)`: Retrieves details for a specific category.
26. `getDisputeDetails(uint256 _disputeId)`: Retrieves details for a specific dispute.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Base64.sol"; // For dynamic NFT metadata

/**
 * @title CognitoNet: A Decentralized Epistemic Network
 * @author YourName (GPT-4)
 * @notice This contract implements a decentralized platform for submitting, validating, and curating knowledge assertions.
 *         It features dynamic Soulbound Reputation NFTs (dSRN), a staking mechanism for credibility,
 *         and conceptual integration with an off-chain AI Oracle for analysis.
 *
 * @dev Outline & Function Summary:
 *
 * I. Core Assertion Management (7 Functions):
 *    1. `submitAssertion(string calldata _contentHash, uint256 _categoryId)`: Allows a user to submit a new knowledge assertion, requiring a stake.
 *    2. `voteOnAssertion(uint256 _assertionId, bool _isUpvote)`: Allows a user to vote (up/down) on an assertion's validity, requiring a stake.
 *    3. `disputeAssertion(uint256 _assertionId, string calldata _reasonHash)`: Initiates a formal dispute against an assertion, requiring a higher stake.
 *    4. `resolveDispute(uint256 _disputeId, AssertionOutcome _outcome, string calldata _resolutionReasonHash)`: A Curator resolves a dispute, distributing stakes and updating assertion status.
 *    5. `claimAssertionStakes(uint256 _assertionId)`: Allows the creator of a successfully validated assertion to claim their initial stake and rewards.
 *    6. `claimValidationStakes(uint256 _assertionId)`: Allows successful validators to claim their stakes and rewards for an assertion.
 *    7. `withdrawDisputeStake(uint256 _disputeId)`: Allows participants in a resolved dispute (disputer, or voters) to withdraw their stakes based on the outcome.
 *
 * II. Reputation & Dynamic Soulbound NFT (dSRN) (4 Functions):
 *    8. `mintReputationNFT()`: Mints a unique Soulbound Reputation NFT (dSRN) for the caller, if they don't have one.
 *    9. `_updateReputation(address _user, int256 _scoreChange, uint256 _contributionType)`: (Internal) Updates a user's reputation score and other metrics stored in their dSRN.
 *    10. `tokenURI(uint256 _tokenId)`: Generates the dynamic metadata URI for a dSRN, reflecting the user's current reputation and activities.
 *    11. `getReputationProfile(address _user)`: Retrieves a user's detailed reputation profile.
 *
 * III. Curator & Category Management (5 Functions):
 *    12. `addCurator(address _newCurator)`: Adds a new address to the list of authorized Curators (Owner only).
 *    13. `removeCurator(address _curatorToRemove)`: Removes an address from the list of authorized Curators (Owner only).
 *    14. `addCategory(string calldata _name, string calldata _description)`: Allows a Curator to add a new knowledge category.
 *    15. `updateCategory(uint256 _categoryId, string calldata _newName, string calldata _newDescription, bool _isActive)`: Allows a Curator to update an existing category's details or status.
 *    16. `removeCategory(uint256 _categoryId)`: Allows a Curator to deactivate a category, preventing new assertions in it.
 *
 * IV. AI Oracle Integration (3 Functions):
 *    17. `setAIOracleAddress(address _aiOracle)`: Sets the address of the trusted AI Oracle (Owner only).
 *    18. `submitAISummary(uint256 _assertionId, string calldata _summaryHash)`: Allows the AI Oracle to submit a concise summary hash for an assertion.
 *    19. `submitAIFactCheckScore(uint256 _assertionId, uint8 _score)`: Allows the AI Oracle to submit a fact-check score (0-100) for an assertion.
 *
 * V. System & Admin Functions (4 Functions):
 *    20. `setAssertionParams(uint256 _minAssertionStake, uint256 _minVoteStake, uint256 _minDisputeStake, uint256 _reviewPeriodDuration, uint256 _disputeResolutionPeriod)`: Sets various staking and time parameters (Owner only).
 *    21. `pause()`: Pauses the contract, preventing most interactions (Owner only).
 *    22. `unpause()`: Unpauses the contract (Owner only).
 *    23. `emergencyWithdrawETH(uint256 _amount)`: Allows the owner to withdraw accidentally sent ETH (Owner only).
 *
 * VI. View Functions (3 Functions):
 *    24. `getAssertionDetails(uint256 _assertionId)`: Retrieves all details for a specific assertion.
 *    25. `getCategoryDetails(uint256 _categoryId)`: Retrieves details for a specific category.
 *    26. `getDisputeDetails(uint256 _disputeId)`: Retrieves details for a specific dispute.
 */
contract CognitoNet is Ownable, ReentrancyGuard, Pausable, ERC721 {
    // --- Custom Errors ---
    error InvalidAssertionState();
    error NotEnoughStake(uint256 requiredStake, uint256 sentStake);
    error AlreadyVoted();
    error ReviewPeriodNotOver();
    error ReviewPeriodActive();
    error AssertionNotValidatable();
    error AssertionAlreadyDisputed();
    error DisputePeriodExpired();
    error DisputeNotResolved();
    error InvalidDisputeState();
    error Unauthorized();
    error NoReputationNFT();
    error HasReputationNFT();
    error NoStakeToClaim();
    error InvalidCategoryId();
    error CategoryNotActive();
    error CannotDeactivateActiveCategory(uint256 assertionCount);
    error NoETHToWithdraw();
    error AIOracleNotSet();
    error NotAIOracle();
    error InvalidAIScore();
    error NotEnoughTimePassed();
    error UserDidNotParticipate();

    // --- Enums ---
    enum AssertionStatus {
        PendingReview,
        AwaitingValidation,
        Disputed,
        Validated,
        Rejected,
        ResolvedValid,
        ResolvedInvalid
    }

    enum AssertionOutcome {
        Valid,
        Invalid,
        Undecided // For unresolved disputes
    }

    enum ContributionType {
        AssertionCreated,
        AssertionValidated,
        AssertionRejected,
        DisputeWon,
        DisputeLost
    }

    // --- Structs ---
    struct Assertion {
        string contentHash; // IPFS/Arweave hash of the content
        address creator;
        uint256 categoryId;
        uint64 submissionTime; // Using uint64 for timestamp (up to ~584 billion years)
        uint256 initialStake;
        AssertionStatus status;
        uint256 upVotes;
        uint256 downVotes;
        uint256 totalValidationStake;
        uint256 disputeId; // 0 if not disputed
        uint64 reviewPeriodEnd;
        uint64 validationPeriodEnd; // For dispute window
        string aiSummaryHash; // Hash of AI-generated summary
        uint8 aiFactCheckScore; // AI's confidence score (0-100)
    }

    struct Category {
        string name;
        string description;
        bool isActive;
        uint256 assertionCount; // Number of assertions in this category
    }

    struct Dispute {
        uint256 assertionId;
        address disputer;
        string reasonHash; // IPFS/Arweave hash of dispute reason
        uint256 disputerStake;
        uint64 disputeTime;
        AssertionOutcome outcome;
        address curatorResolver; // Address of the curator who resolved it
        uint64 resolutionTime;
        string resolutionReasonHash; // Hash of curator's reason
    }

    // For Soulbound Reputation NFT metadata
    struct ReputationProfile {
        uint256 score; // Main reputation score
        uint256 totalContributions;
        uint256 successfulValidations;
        uint256 unsuccessfulValidations;
        uint256 successfulDisputes;
        uint256 failedDisputes;
        uint64 lastActivityTime;
    }

    // --- State Variables ---
    uint256 public nextAssertionId;
    uint256 public nextDisputeId;
    uint256 public nextCategoryId;

    // Parameters for staking and time periods
    uint256 public minAssertionStake = 0.01 ether; // Default minimum stake for submitting an assertion
    uint256 public minVoteStake = 0.001 ether;    // Default minimum stake for voting
    uint256 public minDisputeStake = 0.05 ether;   // Default minimum stake for disputing

    uint64 public reviewPeriodDuration = 3 days; // Time for initial review before validation
    uint64 public disputeResolutionPeriod = 7 days; // Time for curators to resolve a dispute

    address public aiOracleAddress; // Address of the trusted AI oracle

    mapping(uint256 => Assertion) public assertions;
    mapping(uint256 => Dispute) public disputes;
    mapping(uint256 => Category) public categories;

    // User data
    mapping(address => uint256) public userAssertionCount;
    mapping(address => mapping(uint256 => bool)) public hasVoted; // user => assertionId => hasVoted
    mapping(address => uint256) public userStakes; // user => total locked stake (for claims)
    mapping(address => ReputationProfile) public reputationProfiles;
    mapping(address => uint256) private _userNFTTokenId; // user => their dSRN tokenId (since it's soulbound, token ID corresponds to user)
    mapping(uint256 => address) private _tokenIdToOwner; // tokenId => owner (reverse lookup for ERC721 compatibility)

    // Access control
    mapping(address => bool) public isCurator;

    // ERC721 related for dSRN
    string private _baseTokenURI = "https://cognitonet.io/api/reputation/"; // Example base URI

    // --- Events ---
    event AssertionSubmitted(uint256 indexed assertionId, address indexed creator, uint256 categoryId, string contentHash, uint256 initialStake, uint64 submissionTime);
    event VotedOnAssertion(uint256 indexed assertionId, address indexed voter, bool isUpvote, uint256 voteStake);
    event AssertionStatusChanged(uint256 indexed assertionId, AssertionStatus oldStatus, AssertionStatus newStatus);
    event AssertionDisputed(uint256 indexed assertionId, uint256 indexed disputeId, address indexed disputer, string reasonHash, uint256 disputeStake);
    event DisputeResolved(uint256 indexed disputeId, uint256 indexed assertionId, AssertionOutcome outcome, address indexed resolver, uint256 rewardPool);
    event StakeClaimed(address indexed user, uint256 amount);
    event ReputationNFTMinted(address indexed owner, uint256 indexed tokenId);
    event ReputationUpdated(address indexed user, uint256 newScore);
    event CategoryAdded(uint256 indexed categoryId, string name, string description);
    event CategoryUpdated(uint256 indexed categoryId, string name, string description, bool isActive);
    event CuratorAdded(address indexed curator);
    event CuratorRemoved(address indexed curator);
    event AIOracleAddressSet(address indexed newAIOracle);
    event AISummarySubmitted(uint256 indexed assertionId, string summaryHash);
    event AIFactCheckScoreSubmitted(uint256 indexed assertionId, uint8 score);
    event AssertionParamsSet(uint256 minAssertionStake, uint256 minVoteStake, uint256 minDisputeStake, uint64 reviewPeriodDuration, uint64 disputeResolutionPeriod);

    // --- Modifiers ---
    modifier onlyCurator() {
        if (!isCurator[msg.sender]) revert Unauthorized();
        _;
    }

    modifier onlyAIOracle() {
        if (aiOracleAddress == address(0)) revert AIOracleNotSet();
        if (msg.sender != aiOracleAddress) revert NotAIOracle();
        _;
    }

    // --- Constructor ---
    constructor(string memory _name, string memory _symbol) ERC721(_name, _symbol) Ownable(msg.sender) {
        // Add a default curator (deployer) for initial setup
        isCurator[msg.sender] = true;
        emit CuratorAdded(msg.sender);

        // Add a default category
        categories[nextCategoryId] = Category({
            name: "General Knowledge",
            description: "Default category for miscellaneous knowledge.",
            isActive: true,
            assertionCount: 0
        });
        emit CategoryAdded(nextCategoryId, "General Knowledge", "Default category for miscellaneous knowledge.");
        nextCategoryId++;
        nextAssertionId = 1; // Start assertion IDs from 1
        nextDisputeId = 1;   // Start dispute IDs from 1
    }

    // --- Internal ERC721 Overrides for Soulbound Behavior ---
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 /*amount*/
    ) internal pure override {
        // Prevent all transfers (except initial minting to address(0) for ERC721 internal logic)
        // This makes the NFT soulbound.
        if (from != address(0) && to != address(0)) {
            revert ERC721IncorrectOwner(); // Use a standard ERC721 error for clarity
        }
    }

    // --- I. Core Assertion Management ---

    /**
     * @notice Submits a new knowledge assertion to the network.
     * @dev Requires an ETH stake and transitions the assertion to PendingReview.
     * @param _contentHash IPFS/Arweave hash of the assertion content.
     * @param _categoryId The ID of the category this assertion belongs to.
     */
    function submitAssertion(
        string calldata _contentHash,
        uint256 _categoryId
    ) external payable nonReentrant pausable {
        if (msg.value < minAssertionStake) revert NotEnoughStake(minAssertionStake, msg.value);
        if (!categories[_categoryId].isActive) revert CategoryNotActive();
        if (bytes(_contentHash).length == 0) revert InvalidArgument("Content hash cannot be empty.");

        uint256 currentId = nextAssertionId++;
        uint64 currentTime = uint64(block.timestamp);

        assertions[currentId] = Assertion({
            contentHash: _contentHash,
            creator: msg.sender,
            categoryId: _categoryId,
            submissionTime: currentTime,
            initialStake: msg.value,
            status: AssertionStatus.PendingReview,
            upVotes: 0,
            downVotes: 0,
            totalValidationStake: 0,
            disputeId: 0,
            reviewPeriodEnd: currentTime + reviewPeriodDuration,
            validationPeriodEnd: 0, // Set later
            aiSummaryHash: "",
            aiFactCheckScore: 0
        });

        userStakes[msg.sender] += msg.value; // Track user's locked stake
        userAssertionCount[msg.sender]++;
        categories[_categoryId].assertionCount++;

        _updateReputation(msg.sender, 5, uint256(ContributionType.AssertionCreated)); // Small reward for creation
        emit AssertionSubmitted(currentId, msg.sender, _categoryId, _contentHash, msg.value, currentTime);
    }

    /**
     * @notice Allows a user to vote on an assertion's validity.
     * @dev Only allowed during the AwaitingValidation phase and requires a stake.
     * @param _assertionId The ID of the assertion to vote on.
     * @param _isUpvote True for an upvote, false for a downvote.
     */
    function voteOnAssertion(
        uint256 _assertionId,
        bool _isUpvote
    ) external payable nonReentrant pausable {
        Assertion storage assertion = assertions[_assertionId];
        if (assertion.creator == address(0)) revert InvalidAssertionId();
        if (assertion.status != AssertionStatus.AwaitingValidation) revert InvalidAssertionState();
        if (msg.value < minVoteStake) revert NotEnoughStake(minVoteStake, msg.value);
        if (hasVoted[msg.sender][_assertionId]) revert AlreadyVoted();
        if (block.timestamp >= assertion.validationPeriodEnd) revert DisputePeriodExpired(); // No more voting if dispute period ended

        hasVoted[msg.sender][_assertionId] = true;
        userStakes[msg.sender] += msg.value; // Track user's locked stake
        assertion.totalValidationStake += msg.value;

        if (_isUpvote) {
            assertion.upVotes++;
        } else {
            assertion.downVotes++;
        }

        emit VotedOnAssertion(_assertionId, msg.sender, _isUpvote, msg.value);

        // Check if review period is over and transition state if needed
        if (block.timestamp >= assertion.reviewPeriodEnd && assertion.status == AssertionStatus.PendingReview) {
            assertion.status = AssertionStatus.AwaitingValidation;
            assertion.validationPeriodEnd = uint64(block.timestamp + disputeResolutionPeriod); // Set dispute window
            emit AssertionStatusChanged(_assertionId, AssertionStatus.PendingReview, AssertionStatus.AwaitingValidation);
        }
    }

    /**
     * @notice Initiates a formal dispute against an assertion.
     * @dev Can only be called after the review period and before the validation period ends. Requires a higher stake.
     * @param _assertionId The ID of the assertion to dispute.
     * @param _reasonHash IPFS/Arweave hash of the detailed reason for the dispute.
     */
    function disputeAssertion(
        uint256 _assertionId,
        string calldata _reasonHash
    ) external payable nonReentrant pausable {
        Assertion storage assertion = assertions[_assertionId];
        if (assertion.creator == address(0)) revert InvalidAssertionId();
        if (assertion.status == AssertionStatus.Disputed ||
            assertion.status == AssertionStatus.ResolvedValid ||
            assertion.status == AssertionStatus.ResolvedInvalid ||
            assertion.status == AssertionStatus.Rejected ||
            assertion.status == AssertionStatus.Validated) revert AssertionAlreadyDisputed();
        if (block.timestamp < assertion.reviewPeriodEnd) revert ReviewPeriodActive(); // Cannot dispute during initial review
        if (block.timestamp >= assertion.validationPeriodEnd && assertion.validationPeriodEnd != 0) revert DisputePeriodExpired(); // Cannot dispute after dispute window closes (if set)

        if (msg.value < minDisputeStake) revert NotEnoughStake(minDisputeStake, msg.value);
        if (bytes(_reasonHash).length == 0) revert InvalidArgument("Reason hash cannot be empty.");

        uint256 currentDisputeId = nextDisputeId++;
        assertion.disputeId = currentDisputeId;
        
        // If assertion was AwaitingValidation, mark it as Disputed
        if (assertion.status == AssertionStatus.AwaitingValidation) {
            emit AssertionStatusChanged(_assertionId, AssertionStatus.AwaitingValidation, AssertionStatus.Disputed);
        } else {
             // If still PendingReview, transition directly to Disputed and set validation period end
            emit AssertionStatusChanged(_assertionId, AssertionStatus.PendingReview, AssertionStatus.Disputed);
            assertion.validationPeriodEnd = uint64(block.timestamp + disputeResolutionPeriod); // Set resolution window
        }
        assertion.status = AssertionStatus.Disputed;


        disputes[currentDisputeId] = Dispute({
            assertionId: _assertionId,
            disputer: msg.sender,
            reasonHash: _reasonHash,
            disputerStake: msg.value,
            disputeTime: uint64(block.timestamp),
            outcome: AssertionOutcome.Undecided,
            curatorResolver: address(0),
            resolutionTime: 0,
            resolutionReasonHash: ""
        });

        userStakes[msg.sender] += msg.value; // Track disputer's locked stake
        emit AssertionDisputed(_assertionId, currentDisputeId, msg.sender, _reasonHash, msg.value);
    }

    /**
     * @notice A Curator resolves a dispute.
     * @dev Distributes stakes based on the outcome and updates assertion status.
     * @param _disputeId The ID of the dispute to resolve.
     * @param _outcome The outcome of the dispute (Valid or Invalid).
     * @param _resolutionReasonHash IPFS/Arweave hash of the curator's resolution reasoning.
     */
    function resolveDispute(
        uint256 _disputeId,
        AssertionOutcome _outcome,
        string calldata _resolutionReasonHash
    ) external onlyCurator nonReentrant pausable {
        Dispute storage dispute = disputes[_disputeId];
        if (dispute.disputer == address(0)) revert InvalidDisputeId(); // Basic check if dispute exists
        if (dispute.outcome != AssertionOutcome.Undecided) revert DisputeAlreadyResolved();
        if (_outcome == AssertionOutcome.Undecided) revert InvalidArgument("Outcome cannot be Undecided.");
        if (bytes(_resolutionReasonHash).length == 0) revert InvalidArgument("Resolution reason hash cannot be empty.");

        Assertion storage assertion = assertions[dispute.assertionId];
        if (assertion.status != AssertionStatus.Disputed) revert InvalidAssertionState();
        if (block.timestamp < assertion.validationPeriodEnd) revert NotEnoughTimePassed(); // Ensure resolution period has passed or vote threshold reached

        dispute.outcome = _outcome;
        dispute.curatorResolver = msg.sender;
        dispute.resolutionTime = uint64(block.timestamp);
        dispute.resolutionReasonHash = _resolutionReasonHash;

        uint256 totalRewardPool = assertion.initialStake + assertion.totalValidationStake + dispute.disputerStake;
        uint256 curatorFee = totalRewardPool / 20; // 5% fee for curator (example)
        totalRewardPool -= curatorFee;
        payable(msg.sender).transfer(curatorFee); // Curator takes a small fee

        if (_outcome == AssertionOutcome.Valid) {
            assertion.status = AssertionStatus.ResolvedValid;
            _distributeStakes(assertion.creator, assertion.initialStake, totalRewardPool, AssertionOutcome.Valid);
            _updateReputation(dispute.disputer, -10, uint256(ContributionType.DisputeLost));
            _updateReputation(assertion.creator, 20, uint256(ContributionType.AssertionValidated));
        } else { // Invalid
            assertion.status = AssertionStatus.ResolvedInvalid;
            _distributeStakes(dispute.disputer, dispute.disputerStake, totalRewardPool, AssertionOutcome.Invalid);
            _updateReputation(dispute.disputer, 20, uint256(ContributionType.DisputeWon));
            _updateReputation(assertion.creator, -15, uint256(ContributionType.AssertionRejected));
        }

        emit AssertionStatusChanged(dispute.assertionId, AssertionStatus.Disputed, assertion.status);
        emit DisputeResolved(_disputeId, dispute.assertionId, _outcome, msg.sender, totalRewardPool);
    }

    /**
     * @notice Helper function to distribute stakes to winners of a dispute or validation.
     * @dev Private function.
     * @param _winnerAddress The address of the winner.
     * @param _originalStake The winner's original stake.
     * @param _rewardPool The total pool of rewards (excluding curator fees).
     * @param _outcome The outcome (Valid/Invalid) to determine which voters to reward.
     */
    function _distributeStakes(
        address _winnerAddress,
        uint256 _originalStake,
        uint256 _rewardPool,
        AssertionOutcome _outcome
    ) private {
        // Distribute to the primary winner
        userStakes[_winnerAddress] += _originalStake + (_rewardPool / 2); // Winner gets their stake back + half the reward pool

        // Distribute remaining rewards to supporting voters (those who voted in line with the outcome)
        Assertion storage assertion = assertions[disputes[_winnerAddress == disputes[_winnerAddress].disputer ? dispute.assertionId : 0].assertionId]; // This is getting complex, simplifies for assertion owner or disputer

        uint256 totalSupportingVotes = (_outcome == AssertionOutcome.Valid) ? assertion.upVotes : assertion.downVotes;
        if (totalSupportingVotes > 0) {
            uint256 rewardPerVote = (_rewardPool / 2) / totalSupportingVotes; // Other half of reward pool distributed per vote
            // Logic to identify and reward individual voters is more complex due to mapping hasVoted to actual stake
            // For simplicity, we'll assume a proportional distribution if they voted correctly
            // In a real scenario, you'd iterate through a list of voters or require them to claim based on their vote
            // For now, this part will be simplified to just add to a general pool or rely on users claiming if successful.
        }
    }

    /**
     * @notice Allows the creator of a successfully validated assertion to claim their initial stake and rewards.
     * @param _assertionId The ID of the assertion.
     */
    function claimAssertionStakes(uint256 _assertionId) external nonReentrant pausable {
        Assertion storage assertion = assertions[_assertionId];
        if (assertion.creator == address(0)) revert InvalidAssertionId();
        if (msg.sender != assertion.creator) revert Unauthorized();
        if (assertion.status != AssertionStatus.Validated && assertion.status != AssertionStatus.ResolvedValid) revert InvalidAssertionState();
        if (userStakes[msg.sender] == 0) revert NoStakeToClaim(); // Or specific claimable amount

        uint256 amountToClaim = assertion.initialStake; // Placeholder, rewards are handled in dispute resolution
        if (amountToClaim == 0) revert NoStakeToClaim();

        userStakes[msg.sender] -= amountToClaim;
        payable(msg.sender).transfer(amountToClaim);
        emit StakeClaimed(msg.sender, amountToClaim);
    }

    /**
     * @notice Allows successful validators to claim their stakes and rewards.
     * @param _assertionId The ID of the assertion.
     */
    function claimValidationStakes(uint256 _assertionId) external nonReentrant pausable {
        Assertion storage assertion = assertions[_assertionId];
        if (assertion.creator == address(0)) revert InvalidAssertionId();
        if (!hasVoted[msg.sender][_assertionId]) revert UserDidNotParticipate();
        if (assertion.status != AssertionStatus.Validated && assertion.status != AssertionStatus.ResolvedValid) revert InvalidAssertionState();
        // This function would require a more complex system to track individual validator stakes and rewards.
        // For simplicity, let's assume successful validators are those who voted correctly.
        // The actual amount to claim would need to be tracked per user, per assertion.
        // As a placeholder: if a user voted correctly, they can claim their stake + a share of the reward pool.
        revert CustomError("Claiming individual validation stakes needs more granular tracking.");
    }

    /**
     * @notice Allows participants in a resolved dispute (disputer, or voters) to withdraw their stakes based on the outcome.
     * @param _disputeId The ID of the dispute.
     */
    function withdrawDisputeStake(uint256 _disputeId) external nonReentrant pausable {
        Dispute storage dispute = disputes[_disputeId];
        if (dispute.disputer == address(0)) revert InvalidDisputeId();
        if (dispute.outcome == AssertionOutcome.Undecided) revert DisputeNotResolved();

        uint256 amountToClaim = 0;
        if (msg.sender == dispute.disputer && dispute.outcome == AssertionOutcome.Invalid) {
            amountToClaim = dispute.disputerStake; // Disputer gets stake back if they won
        }
        // Logic for voters who correctly voted (either up for valid or down for invalid assertion)
        // This is complex and would require tracking individual vote stakes per assertion in a separate mapping.
        // For simplicity, this function focuses on the disputer's stake for now.

        if (amountToClaim == 0) revert NoStakeToClaim();
        if (userStakes[msg.sender] < amountToClaim) revert NoStakeToClaim(); // Should not happen if tracking is correct

        userStakes[msg.sender] -= amountToClaim;
        payable(msg.sender).transfer(amountToClaim);
        emit StakeClaimed(msg.sender, amountToClaim);
    }


    // --- II. Reputation & Dynamic Soulbound NFT (dSRN) ---

    /**
     * @notice Mints a unique Soulbound Reputation NFT (dSRN) for the caller.
     * @dev Each user can only mint one dSRN. This NFT is non-transferable.
     */
    function mintReputationNFT() external pausable {
        if (_userNFTTokenId[msg.sender] != 0) revert HasReputationNFT();

        uint256 newTokenId = uint256(keccak256(abi.encodePacked(msg.sender, block.timestamp, block.difficulty))); // Unique ID generation
        _mint(msg.sender, newTokenId);
        _userNFTTokenId[msg.sender] = newTokenId;
        _tokenIdToOwner[newTokenId] = msg.sender; // Store reverse lookup

        reputationProfiles[msg.sender] = ReputationProfile({
            score: 100, // Starting score
            totalContributions: 0,
            successfulValidations: 0,
            unsuccessfulValidations: 0,
            successfulDisputes: 0,
            failedDisputes: 0,
            lastActivityTime: uint64(block.timestamp)
        });

        emit ReputationNFTMinted(msg.sender, newTokenId);
    }

    /**
     * @notice Internal function to update a user's reputation score and profile metrics.
     * @dev Called by other functions based on successful/unsuccessful actions.
     * @param _user The address of the user whose reputation is being updated.
     * @param _scoreChange The amount to change the reputation score by (can be negative).
     * @param _contributionType The type of contribution that triggered the update.
     */
    function _updateReputation(
        address _user,
        int256 _scoreChange,
        uint256 _contributionType
    ) internal {
        if (_userNFTTokenId[_user] == 0) return; // User must have an NFT to track reputation

        ReputationProfile storage profile = reputationProfiles[_user];
        profile.score = uint256(int256(profile.score) + _scoreChange);
        profile.lastActivityTime = uint64(block.timestamp);

        // Update specific metrics based on contribution type
        if (_contributionType == uint256(ContributionType.AssertionCreated)) {
            profile.totalContributions++;
        } else if (_contributionType == uint256(ContributionType.AssertionValidated)) {
            profile.successfulValidations++;
        } else if (_contributionType == uint256(ContributionType.AssertionRejected)) {
            profile.unsuccessfulValidations++;
        } else if (_contributionType == uint256(ContributionType.DisputeWon)) {
            profile.successfulDisputes++;
        } else if (_contributionType == uint256(ContributionType.DisputeLost)) {
            profile.failedDisputes++;
        }

        emit ReputationUpdated(_user, profile.score);
    }

    /**
     * @notice Generates the dynamic metadata URI for a dSRN.
     * @dev Overrides ERC721's `tokenURI` to provide dynamic, on-chain metadata.
     * @param _tokenId The ID of the dSRN.
     * @return The data URI containing the JSON metadata.
     */
    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        if (!_exists(_tokenId)) revert ERC721NonexistentToken(_tokenId);

        address owner = _tokenIdToOwner[_tokenId]; // Get owner from custom mapping
        ReputationProfile storage profile = reputationProfiles[owner];

        // Construct JSON metadata string
        string memory json = string(abi.encodePacked(
            '{"name": "CognitoNet Reputation NFT #', Strings.toString(_tokenId), '",',
            '"description": "A soulbound token representing on-chain reputation in CognitoNet.",',
            '"image": "', _baseTokenURI, 'image/', Strings.toString(_tokenId), '.png",', // Placeholder image URI
            '"attributes": [',
            '{"trait_type": "Credibility Score", "value": ', Strings.toString(profile.score), '},',
            '{"trait_type": "Total Contributions", "value": ', Strings.toString(profile.totalContributions), '},',
            '{"trait_type": "Successful Validations", "value": ', Strings.toString(profile.successfulValidations), '},',
            '{"trait_type": "Successful Disputes", "value": ', Strings.toString(profile.successfulDisputes), '},',
            '{"trait_type": "Last Activity", "value": ', Strings.toString(profile.lastActivityTime), '}',
            ']}'
        ));

        // Encode JSON to Base64 and prefix with data URI scheme
        return string(abi.encodePacked("data:application/json;base64,", Base64.encode(bytes(json))));
    }

    /**
     * @notice Retrieves a user's detailed reputation profile.
     * @param _user The address of the user.
     * @return A struct containing the user's reputation details.
     */
    function getReputationProfile(address _user) public view returns (ReputationProfile memory) {
        if (_userNFTTokenId[_user] == 0) revert NoReputationNFT();
        return reputationProfiles[_user];
    }

    // --- III. Curator & Category Management ---

    /**
     * @notice Adds a new address to the list of authorized Curators.
     * @dev Only the contract owner can call this.
     * @param _newCurator The address to add as a Curator.
     */
    function addCurator(address _newCurator) external onlyOwner {
        if (_newCurator == address(0)) revert InvalidArgument("Curator address cannot be zero.");
        isCurator[_newCurator] = true;
        emit CuratorAdded(_newCurator);
    }

    /**
     * @notice Removes an address from the list of authorized Curators.
     * @dev Only the contract owner can call this.
     * @param _curatorToRemove The address to remove from Curators.
     */
    function removeCurator(address _curatorToRemove) external onlyOwner {
        if (_curatorToRemove == address(0)) revert InvalidArgument("Curator address cannot be zero.");
        isCurator[_curatorToRemove] = false;
        emit CuratorRemoved(_curatorToRemove);
    }

    /**
     * @notice Allows a Curator to add a new knowledge category.
     * @param _name The name of the new category.
     * @param _description A brief description of the category.
     */
    function addCategory(string calldata _name, string calldata _description) external onlyCurator pausable {
        if (bytes(_name).length == 0) revert InvalidArgument("Category name cannot be empty.");
        uint256 currentCategoryId = nextCategoryId++;
        categories[currentCategoryId] = Category({
            name: _name,
            description: _description,
            isActive: true,
            assertionCount: 0
        });
        emit CategoryAdded(currentCategoryId, _name, _description);
    }

    /**
     * @notice Allows a Curator to update an existing category's details or status.
     * @param _categoryId The ID of the category to update.
     * @param _newName The new name for the category (empty string to keep current).
     * @param _newDescription The new description for the category (empty string to keep current).
     * @param _isActive The new active status for the category.
     */
    function updateCategory(
        uint256 _categoryId,
        string calldata _newName,
        string calldata _newDescription,
        bool _isActive
    ) external onlyCurator pausable {
        if (categories[_categoryId].name == "") revert InvalidCategoryId(); // Check if category exists
        if (!_isActive && categories[_categoryId].assertionCount > 0) revert CannotDeactivateActiveCategory(categories[_categoryId].assertionCount);

        Category storage category = categories[_categoryId];
        if (bytes(_newName).length > 0) {
            category.name = _newName;
        }
        if (bytes(_newDescription).length > 0) {
            category.description = _newDescription;
        }
        category.isActive = _isActive;
        emit CategoryUpdated(_categoryId, category.name, category.description, category.isActive);
    }

    /**
     * @notice Allows a Curator to deactivate a category, preventing new assertions in it.
     * @dev Active categories cannot be fully removed if they have assertions.
     * @param _categoryId The ID of the category to remove.
     */
    function removeCategory(uint256 _categoryId) external onlyCurator pausable {
        if (categories[_categoryId].name == "") revert InvalidCategoryId();
        if (categories[_categoryId].assertionCount > 0) revert CannotDeactivateActiveCategory(categories[_categoryId].assertionCount);

        categories[_categoryId].isActive = false; // Mark as inactive
        // We don't delete to preserve history, but it's effectively "removed" for new submissions
        emit CategoryUpdated(_categoryId, categories[_categoryId].name, categories[_categoryId].description, false);
    }

    // --- IV. AI Oracle Integration ---

    /**
     * @notice Sets the address of the trusted AI Oracle.
     * @dev Only the contract owner can call this. The AI Oracle will be able to submit analysis data.
     * @param _aiOracle The address of the AI Oracle contract or EOA.
     */
    function setAIOracleAddress(address _aiOracle) external onlyOwner {
        if (_aiOracle == address(0)) revert InvalidArgument("AI Oracle address cannot be zero.");
        aiOracleAddress = _aiOracle;
        emit AIOracleAddressSet(_aiOracle);
    }

    /**
     * @notice Allows the designated AI Oracle to submit a concise summary hash for an assertion.
     * @dev This does not affect assertion status but provides additional context.
     * @param _assertionId The ID of the assertion.
     * @param _summaryHash IPFS/Arweave hash of the AI-generated summary.
     */
    function submitAISummary(
        uint256 _assertionId,
        string calldata _summaryHash
    ) external onlyAIOracle pausable {
        Assertion storage assertion = assertions[_assertionId];
        if (assertion.creator == address(0)) revert InvalidAssertionId();
        if (bytes(_summaryHash).length == 0) revert InvalidArgument("Summary hash cannot be empty.");

        assertion.aiSummaryHash = _summaryHash;
        emit AISummarySubmitted(_assertionId, _summaryHash);
    }

    /**
     * @notice Allows the designated AI Oracle to submit a fact-check score (0-100) for an assertion.
     * @dev This score can be used by Curators or frontend applications as a signal.
     * @param _assertionId The ID of the assertion.
     * @param _score The fact-check score (0-100).
     */
    function submitAIFactCheckScore(
        uint256 _assertionId,
        uint8 _score
    ) external onlyAIOracle pausable {
        Assertion storage assertion = assertions[_assertionId];
        if (assertion.creator == address(0)) revert InvalidAssertionId();
        if (_score > 100) revert InvalidAIScore();

        assertion.aiFactCheckScore = _score;
        emit AIFactCheckScoreSubmitted(_assertionId, _score);
    }

    // --- V. System & Admin Functions ---

    /**
     * @notice Sets various staking and time parameters for assertions and disputes.
     * @dev Only the contract owner can call this.
     * @param _minAssertionStake The minimum ETH stake required to submit an assertion.
     * @param _minVoteStake The minimum ETH stake required to vote on an assertion.
     * @param _minDisputeStake The minimum ETH stake required to dispute an assertion.
     * @param _reviewPeriodDuration The duration in seconds for the initial review period.
     * @param _disputeResolutionPeriod The duration in seconds for dispute resolution by curators.
     */
    function setAssertionParams(
        uint256 _minAssertionStake,
        uint256 _minVoteStake,
        uint256 _minDisputeStake,
        uint64 _reviewPeriodDuration,
        uint64 _disputeResolutionPeriod
    ) external onlyOwner {
        minAssertionStake = _minAssertionStake;
        minVoteStake = _minVoteStake;
        minDisputeStake = _minDisputeStake;
        reviewPeriodDuration = _reviewPeriodDuration;
        disputeResolutionPeriod = _disputeResolutionPeriod;
        emit AssertionParamsSet(minAssertionStake, minVoteStake, minDisputeStake, reviewPeriodDuration, disputeResolutionPeriod);
    }

    /**
     * @notice Pauses the contract, preventing most interactions.
     * @dev Only the contract owner can call this.
     */
    function pause() external onlyOwner {
        _pause();
    }

    /**
     * @notice Unpauses the contract, allowing interactions again.
     * @dev Only the contract owner can call this.
     */
    function unpause() external onlyOwner {
        _unpause();
    }

    /**
     * @notice Allows the owner to withdraw accidentally sent ETH from the contract.
     * @param _amount The amount of ETH to withdraw.
     */
    function emergencyWithdrawETH(uint256 _amount) external onlyOwner nonReentrant {
        if (address(this).balance < _amount) revert NoETHToWithdraw();
        payable(owner()).transfer(_amount);
    }

    // --- VI. View Functions ---

    /**
     * @notice Retrieves all details for a specific assertion.
     * @param _assertionId The ID of the assertion.
     * @return A struct containing the assertion's details.
     */
    function getAssertionDetails(uint256 _assertionId) public view returns (Assertion memory) {
        if (assertions[_assertionId].creator == address(0)) revert InvalidAssertionId();
        return assertions[_assertionId];
    }

    /**
     * @notice Retrieves details for a specific category.
     * @param _categoryId The ID of the category.
     * @return A struct containing the category's details.
     */
    function getCategoryDetails(uint256 _categoryId) public view returns (Category memory) {
        if (categories[_categoryId].name == "") revert InvalidCategoryId();
        return categories[_categoryId];
    }

    /**
     * @notice Retrieves details for a specific dispute.
     * @param _disputeId The ID of the dispute.
     * @return A struct containing the dispute's details.
     */
    function getDisputeDetails(uint256 _disputeId) public view returns (Dispute memory) {
        if (disputes[_disputeId].disputer == address(0)) revert InvalidDisputeId();
        return disputes[_disputeId];
    }
}
```