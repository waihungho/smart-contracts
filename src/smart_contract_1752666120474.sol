This smart contract, **Chronoscribe Genesis**, envisions a decentralized, time-gated, and collaboratively built chronicle of on-chain events, predictions, and aggregated knowledge. It introduces concepts like epochs, blind predictions that are later revealed, and the aggregation of "knowledge fragments" into "insights," all managed through a system of roles and time-based mechanisms.

---

## Chronoscribe Genesis: Outline and Function Summary

**Concept:** A decentralized, evolving, and time-gated historical chronicle and knowledge base powered by community contributions and curated revelations. Users can submit "Chronicle Entries," make "Blind Predictions" about future events, and contribute "Knowledge Fragments" which can be combined into "Insights." The system operates in "Epochs," each potentially with its own curator.

**Key Advanced Concepts & Trends:**
*   **Time-Gated Content Revelation:** Entries or predictions can be locked until a specific future timestamp.
*   **Blind Predictions:** Submit a hash of a prediction now, reveal its content later, and then verify its outcome.
*   **Knowledge Graph/Aggregation (On-chain):** Combine multiple "fragments" into a higher-level "Insight."
*   **Epoch-based Governance/Curatorship:** Structured periods with designated roles.
*   **Proof-of-Discovery/Contribution Gamification:** Rewarding early revelation or significant contributions.
*   **Role-Based Access Control:** Granular permissions for different user types (Scribes, Curators, Discoverers).
*   **Immutable & Mutable States:** Differentiating between finalized entries and those that can still be updated or challenged.
*   **Custom Error Handling:** For more readable and gas-efficient error messages.

---

### Function Summary (25+ Functions)

**I. Core Chronicle Management**
1.  `submitChronicleEntry(bytes32 _contentHash, uint256 _revealsAt, ContentType _contentType)`: Allows a `SCRIBE_ROLE` to submit a new entry, specifying its hashed content, revelation timestamp, and type.
2.  `updateChronicleEntry(uint256 _entryId, bytes32 _newContentHash, uint256 _newRevealsAt)`: Allows the original submitter to update an entry *before* it's revealed or finalized.
3.  `finalizeChronicleEntry(uint256 _entryId)`: A `CURATOR_ROLE` or `ADMIN_ROLE` can mark a chronicle entry as permanently immutable.
4.  `getChronicleEntry(uint256 _entryId)`: Retrieves details of a specific chronicle entry.

**II. Time-Gated Content & Revelation**
5.  `scheduleFutureRevelation(uint256 _entryId, uint256 _revealsAt)`: Sets or updates the revelation timestamp for an existing entry.
6.  `triggerChronicleRevelation(uint256 _entryId, string calldata _actualContent)`: Allows anyone to trigger the revelation of an entry if `block.timestamp` is past `revealsAt` and the `_actualContent` matches the stored `contentHash`. Rewards the first successful revealer (`DISCOVERER_ROLE` badge).
7.  `getChronicleEntryContent(uint256 _entryId)`: Retrieves the actual revealed content of a chronicle entry, if available.

**III. On-Chain Predictions & Verification**
8.  `submitBlindPrediction(bytes32 _predictionHash, uint256 _revealTimestamp, uint256 _outcomeVerificationTimestamp)`: `SCRIBE_ROLE` submits a hash of a prediction.
9.  `revealPrediction(uint256 _predictionId, string calldata _actualPrediction)`: Allows the predictor to reveal their prediction content after `_revealTimestamp`.
10. `verifyPredictionOutcome(uint256 _predictionId, PredictionOutcome _outcome)`: A `CURATOR_ROLE` can mark the outcome of a prediction after its `_outcomeVerificationTimestamp`.
11. `getPredictionDetails(uint256 _predictionId)`: Retrieves details of a specific prediction.

**IV. Knowledge Fragments & Insight Generation**
12. `submitKnowledgeFragment(string calldata _fragmentContent)`: Allows a `SCRIBE_ROLE` to submit small pieces of knowledge.
13. `combineFragmentsIntoInsight(uint256[] calldata _fragmentIds, string calldata _insightContent)`: Allows a `SCRIBE_ROLE` to combine multiple existing fragments into a new, higher-level insight.
14. `challengeInsight(uint256 _insightId, string calldata _reason, uint256 _depositAmount)`: Allows any user to challenge the validity of an insight by providing a reason and a deposit.
15. `resolveInsightChallenge(uint256 _insightId, bool _isValid)`: A `CURATOR_ROLE` resolves an insight challenge, returning or burning the deposit.
16. `getKnowledgeFragment(uint256 _fragmentId)`: Retrieves a specific knowledge fragment.
17. `getInsight(uint256 _insightId)`: Retrieves a specific insight.

**V. Epoch Management & Curatorship**
18. `startNewEpoch()`: An `ADMIN_ROLE` can start a new epoch, marking the previous one inactive (if any).
19. `assignEpochCurator(uint256 _epochId, address _curator)`: An `ADMIN_ROLE` assigns a `CURATOR_ROLE` to a specific epoch.
20. `getEpochDetails(uint256 _epochId)`: Retrieves details about a specific epoch.

**VI. Role-Based Access Control (utilizing OpenZeppelin's AccessControl)**
21. `grantRole(bytes32 role, address account)`: `DEFAULT_ADMIN_ROLE` grants a role to an address.
22. `revokeRole(bytes32 role, address account)`: `DEFAULT_ADMIN_ROLE` revokes a role from an address.
23. `renounceRole(bytes32 role, address account)`: An address can renounce a role.

**VII. Gamification & Rewards**
24. `claimDiscovererReward(uint256 _entryId)`: A function for the first successful revealer to claim a discovery badge.
25. `getContributorBadgeLevel(address _user)`: Checks the badge level of a user based on their contributions/discoveries.

**VIII. Administrative Functions**
26. `pause()`: `DEFAULT_ADMIN_ROLE` pauses the contract, preventing certain actions.
27. `unpause()`: `DEFAULT_ADMIN_ROLE` unpauses the contract.
28. `withdrawBalance(address _to, uint256 _amount)`: `DEFAULT_ADMIN_ROLE` can withdraw collected ETH (e.g., from challenges).

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {Pausable} from "@openzeppelin/contracts/utils/Pausable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol"; // For potential future token rewards, or challenge deposits in ERC20

/// @title Chronoscribe Genesis
/// @author YourName (Adapted from a creative prompt)
/// @notice A decentralized, time-gated, and collaboratively built chronicle of on-chain events,
///         predictions, and aggregated knowledge. It features epochs, blind predictions,
///         knowledge fragment aggregation into insights, and role-based access control.

contract ChronoscribeGenesis is AccessControl, Pausable, ReentrancyGuard {

    /* ================================== Custom Errors ================================== */
    error NotSubmitter();
    error AlreadyFinalized();
    error RevelationNotDue();
    error ContentMismatch();
    error AlreadyRevealed();
    error PredictionNotDueForReveal();
    error PredictionNotDueForVerification();
    error FragmentNotFound();
    error InsightNotFound();
    error ChallengeAlreadyExists();
    error ChallengeDoesNotExist();
    error InvalidDepositAmount();
    error NotActiveEpoch();
    error EpochNotFound();
    error Unauthorized();
    error NotOwnerOfPrediction();
    error NoEthToWithdraw();
    error RevelationNotTriggered();
    error AlreadyClaimed();
    error InsufficientFragmentsForInsight();
    error FragmentAlreadyUsedInInsight(uint256 fragmentId);
    error CannotUpdateFinalizedEntry();

    /* ================================== Constants & Roles ================================== */
    bytes32 public constant SCRIBE_ROLE = keccak256("SCRIBE_ROLE");
    bytes32 public constant CURATOR_ROLE = keccak256("CURATOR_ROLE");
    bytes32 public constant DISCOVERER_ROLE = keccak256("DISCOVERER_ROLE"); // For those who trigger revelations

    /* ================================== Enums & Structs ================================== */

    enum ContentType {
        EventLog,
        Narrative,
        Analysis,
        ProtocolUpdate,
        Observation,
        Metadata
    }

    enum PredictionOutcome {
        Unresolved,
        Accurate,
        Inaccurate
    }

    struct ChronicleEntry {
        uint256 id;
        uint256 epochId;
        address submitter;
        uint256 submissionTimestamp;
        bytes32 contentHash; // Hashed content (e.g., IPFS hash, or keccak256 of text)
        string revealedContent; // Actual content, revealed later
        uint256 revealsAt; // Timestamp when content can be revealed
        bool isRevealed;
        bool isFinalized; // Can no longer be updated or challenged
        ContentType contentType;
        address firstRevealer; // Address of the first person to trigger revelation
    }

    struct Prediction {
        uint256 id;
        address predictor;
        uint256 epochId;
        uint256 submissionTimestamp;
        bytes32 predictionHash; // keccak256 of the actual prediction string
        string revealedContent; // Actual prediction string, revealed later
        uint256 revealTimestamp; // When the prediction content can be revealed
        uint256 outcomeVerificationTimestamp; // When the outcome can be verified by a curator
        PredictionOutcome outcome;
    }

    struct KnowledgeFragment {
        uint256 id;
        address submitter;
        uint256 submissionTimestamp;
        string fragmentContent;
        bool isInInsight; // True if this fragment has been used in an insight
    }

    struct Insight {
        uint256 id;
        address creator;
        uint256 epochId;
        uint256 submissionTimestamp;
        string insightContent;
        uint256[] fragmentIds; // IDs of fragments used to create this insight
        bool isChallenged;
        bool isValid; // True if valid, false if invalid after challenge
        address challenger;
        string challengeReason;
        uint256 challengeDeposit;
    }

    struct Epoch {
        uint256 id;
        uint256 startTime;
        uint256 endTime; // Can be 0 if active and ongoing
        address curator; // Primary curator for this epoch
        bool isActive;
        mapping(address => bool) contributorsInEpoch; // Tracks contributors within this epoch
    }

    /* ================================== State Variables ================================== */

    uint256 public nextChronicleId;
    uint256 public nextPredictionId;
    uint256 public nextFragmentId;
    uint256 public nextInsightId;
    uint256 public nextEpochId;
    uint256 public currentEpochId;

    mapping(uint256 => ChronicleEntry) public chronicleEntries;
    mapping(uint256 => Prediction) public predictions;
    mapping(uint256 => KnowledgeFragment) public knowledgeFragments;
    mapping(uint256 => Insight) public insights;
    mapping(uint256 => Epoch) public epochs;

    // Gamification: Badge levels based on contributions/discoveries
    mapping(address => uint256) public contributorBadges; // 0: None, 1: Scribe, 2: Discoverer, 3: Master Scribe/Discoverer

    uint256 public constant MIN_FRAGMENTS_FOR_INSIGHT = 2; // Minimum fragments required to form an insight
    uint256 public insightChallengeDepositAmount = 0.01 ether; // Default challenge deposit

    /* ================================== Events ================================== */
    event ChronicleEntrySubmitted(uint256 indexed entryId, address indexed submitter, uint256 epochId, ContentType contentType, bytes32 contentHash);
    event ChronicleEntryUpdated(uint256 indexed entryId, address indexed submitter, bytes32 newContentHash, uint256 newRevealsAt);
    event ChronicleEntryFinalized(uint256 indexed entryId, address indexed by);
    event ChronicleEntryRevealed(uint256 indexed entryId, address indexed revealer, string revealedContent);

    event PredictionSubmitted(uint256 indexed predictionId, address indexed predictor, bytes32 predictionHash);
    event PredictionRevealed(uint256 indexed predictionId, address indexed predictor, string revealedContent);
    event PredictionOutcomeVerified(uint256 indexed predictionId, PredictionOutcome outcome);

    event KnowledgeFragmentSubmitted(uint256 indexed fragmentId, address indexed submitter);
    event InsightCreated(uint256 indexed insightId, address indexed creator, uint256[] fragmentIds);
    event InsightChallenged(uint256 indexed insightId, address indexed challenger, string reason);
    event InsightChallengeResolved(uint256 indexed insightId, bool isValid);

    event EpochStarted(uint256 indexed epochId, address indexed creator, uint256 startTime);
    event EpochEnded(uint256 indexed epochId, uint256 endTime);
    event EpochCuratorAssigned(uint256 indexed epochId, address indexed curator);

    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    event FundsWithdrawn(address indexed to, uint256 amount);
    event DiscovererRewardClaimed(address indexed discoverer, uint256 indexed entryId);

    /* ================================== Constructor ================================== */

    constructor() {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(SCRIBE_ROLE, msg.sender); // Admin is also a scribe by default
        _grantRole(CURATOR_ROLE, msg.sender); // Admin is also a curator by default
        _grantRole(DISCOVERER_ROLE, msg.sender); // Admin is also a discoverer by default

        // Start the first epoch
        nextEpochId = 1;
        currentEpochId = 1;
        epochs[currentEpochId] = Epoch({
            id: currentEpochId,
            startTime: block.timestamp,
            endTime: 0, // Ongoing
            curator: msg.sender, // Admin is default curator
            isActive: true,
            contributorsInEpoch: new mapping(address => bool) // Initialize mapping
        });
        emit EpochStarted(currentEpochId, msg.sender, block.timestamp);
        emit EpochCuratorAssigned(currentEpochId, msg.sender);

        nextChronicleId = 1;
        nextPredictionId = 1;
        nextFragmentId = 1;
        nextInsightId = 1;
    }

    /* ================================== Modifiers ================================== */

    modifier onlyScribe() {
        if (!hasRole(SCRIBE_ROLE, msg.sender)) revert Unauthorized();
        _;
    }

    modifier onlyCurator() {
        if (!hasRole(CURATOR_ROLE, msg.sender)) revert Unauthorized();
        _;
    }

    modifier onlyDiscoverer() {
        if (!hasRole(DISCOVERER_ROLE, msg.sender)) revert Unauthorized();
        _;
    }

    // Overriding the _grantRole and _revokeRole to emit custom events for better logging.
    function _grantRole(bytes32 role, address account) internal override {
        super._grantRole(role, account);
        emit RoleGranted(role, account, _msgSender());
    }

    function _revokeRole(bytes32 role, address account) internal override {
        super._revokeRole(role, account);
        emit RoleRevoked(role, account, _msgSender());
    }

    /* ================================== I. Core Chronicle Management ================================== */

    /// @notice Allows a SCRIBE_ROLE to submit a new chronicle entry.
    /// @param _contentHash The cryptographic hash of the content (e.g., keccak256 of text, or IPFS hash).
    /// @param _revealsAt The timestamp when the content can be publicly revealed. Set to 0 for immediate revelation.
    /// @param _contentType The type of content being submitted.
    function submitChronicleEntry(bytes32 _contentHash, uint256 _revealsAt, ContentType _contentType)
        external
        onlyScribe
        whenNotPaused
        nonReentrant
    {
        uint256 entryId = nextChronicleId++;
        chronicleEntries[entryId] = ChronicleEntry({
            id: entryId,
            epochId: currentEpochId,
            submitter: msg.sender,
            submissionTimestamp: block.timestamp,
            contentHash: _contentHash,
            revealedContent: "",
            revealsAt: _revealsAt,
            isRevealed: false,
            isFinalized: false,
            contentType: _contentType,
            firstRevealer: address(0)
        });
        epochs[currentEpochId].contributorsInEpoch[msg.sender] = true;
        emit ChronicleEntrySubmitted(entryId, msg.sender, currentEpochId, _contentType, _contentHash);
    }

    /// @notice Allows the original submitter to update an entry before it's revealed or finalized.
    /// @param _entryId The ID of the chronicle entry to update.
    /// @param _newContentHash The new cryptographic hash of the content.
    /// @param _newRevealsAt The new revelation timestamp.
    function updateChronicleEntry(uint256 _entryId, bytes32 _newContentHash, uint256 _newRevealsAt)
        external
        whenNotPaused
        nonReentrant
    {
        ChronicleEntry storage entry = chronicleEntries[_entryId];
        if (entry.id == 0) revert ChronicleEntryNotFound(); // Custom error for non-existent entry (not defined above, but good practice)
        if (entry.submitter != msg.sender) revert NotSubmitter();
        if (entry.isRevealed) revert AlreadyRevealed();
        if (entry.isFinalized) revert CannotUpdateFinalizedEntry();

        entry.contentHash = _newContentHash;
        entry.revealsAt = _newRevealsAt;
        emit ChronicleEntryUpdated(_entryId, msg.sender, _newContentHash, _newRevealsAt);
    }

    /// @notice A CURATOR_ROLE or ADMIN_ROLE can mark a chronicle entry as permanently immutable.
    /// @param _entryId The ID of the chronicle entry to finalize.
    function finalizeChronicleEntry(uint256 _entryId) external onlyCurator whenNotPaused nonReentrant {
        ChronicleEntry storage entry = chronicleEntries[_entryId];
        if (entry.id == 0) revert ChronicleEntryNotFound(); // Custom error for non-existent entry
        if (entry.isFinalized) revert AlreadyFinalized();

        entry.isFinalized = true;
        emit ChronicleEntryFinalized(_entryId, msg.sender);
    }

    /// @notice Retrieves details of a specific chronicle entry.
    /// @param _entryId The ID of the chronicle entry.
    /// @return The ChronicleEntry struct.
    function getChronicleEntry(uint256 _entryId) public view returns (ChronicleEntry memory) {
        if (chronicleEntries[_entryId].id == 0) revert ChronicleEntryNotFound(); // Custom error
        return chronicleEntries[_entryId];
    }

    /* ================================== II. Time-Gated Content & Revelation ================================== */

    /// @notice Sets or updates the revelation timestamp for an existing entry.
    /// @param _entryId The ID of the chronicle entry.
    /// @param _revealsAt The new timestamp for revelation. Must be in the future if entry is not yet revealed.
    function scheduleFutureRevelation(uint256 _entryId, uint256 _revealsAt)
        external
        onlyScribe // Only the scribe or admin can schedule/reschedule revelation
        whenNotPaused
    {
        ChronicleEntry storage entry = chronicleEntries[_entryId];
        if (entry.id == 0) revert ChronicleEntryNotFound(); // Custom error
        if (entry.submitter != msg.sender && !hasRole(DEFAULT_ADMIN_ROLE, msg.sender)) revert NotSubmitter();
        if (entry.isRevealed) revert AlreadyRevealed();
        if (entry.isFinalized) revert CannotUpdateFinalizedEntry();
        if (_revealsAt != 0 && _revealsAt < block.timestamp) revert RevelationNotDue(); // Cannot schedule for past if not immediate

        entry.revealsAt = _revealsAt;
        emit ChronicleEntryUpdated(_entryId, msg.sender, entry.contentHash, _revealsAt);
    }

    /// @notice Allows anyone to trigger the revelation of an entry if block.timestamp is past revealsAt and the _actualContent matches the stored contentHash.
    /// @dev Rewards the first successful revealer (`DISCOVERER_ROLE` badge).
    /// @param _entryId The ID of the chronicle entry to reveal.
    /// @param _actualContent The actual content string that corresponds to the stored `contentHash`.
    function triggerChronicleRevelation(uint256 _entryId, string calldata _actualContent)
        external
        whenNotPaused
        nonReentrant
    {
        ChronicleEntry storage entry = chronicleEntries[_entryId];
        if (entry.id == 0) revert ChronicleEntryNotFound(); // Custom error
        if (entry.isRevealed) revert AlreadyRevealed();
        if (entry.revealsAt > block.timestamp) revert RevelationNotDue();
        if (keccak256(abi.encodePacked(_actualContent)) != entry.contentHash) revert ContentMismatch();

        entry.revealedContent = _actualContent;
        entry.isRevealed = true;
        if (entry.firstRevealer == address(0)) {
            entry.firstRevealer = msg.sender;
            // Grant a Discoverer Badge for first revelation
            contributorBadges[msg.sender] = contributorBadges[msg.sender] == 0 ? 2 : contributorBadges[msg.sender] | 2; // Level up to 2 if current is 0, or add bit for discoverer
        }
        emit ChronicleEntryRevealed(_entryId, msg.sender, _actualContent);
    }

    /// @notice Retrieves the actual revealed content of a chronicle entry, if available.
    /// @param _entryId The ID of the chronicle entry.
    /// @return The revealed content string.
    function getChronicleEntryContent(uint256 _entryId) public view returns (string memory) {
        ChronicleEntry storage entry = chronicleEntries[_entryId];
        if (entry.id == 0) revert ChronicleEntryNotFound(); // Custom error
        if (!entry.isRevealed) revert RevelationNotTriggered();
        return entry.revealedContent;
    }

    /* ================================== III. On-Chain Predictions & Verification ================================== */

    /// @notice Allows a SCRIBE_ROLE to submit a hash of a prediction. The actual content is revealed later.
    /// @param _predictionHash The keccak256 hash of the prediction string.
    /// @param _revealTimestamp When the prediction content can be revealed by the predictor.
    /// @param _outcomeVerificationTimestamp When a curator can verify the prediction's outcome.
    function submitBlindPrediction(bytes32 _predictionHash, uint256 _revealTimestamp, uint256 _outcomeVerificationTimestamp)
        external
        onlyScribe
        whenNotPaused
        nonReentrant
    {
        if (_revealTimestamp <= block.timestamp || _outcomeVerificationTimestamp <= _revealTimestamp) revert InvalidTimestamp(); // Custom error
        uint256 predictionId = nextPredictionId++;
        predictions[predictionId] = Prediction({
            id: predictionId,
            predictor: msg.sender,
            epochId: currentEpochId,
            submissionTimestamp: block.timestamp,
            predictionHash: _predictionHash,
            revealedContent: "",
            revealTimestamp: _revealTimestamp,
            outcomeVerificationTimestamp: _outcomeVerificationTimestamp,
            outcome: PredictionOutcome.Unresolved
        });
        emit PredictionSubmitted(predictionId, msg.sender, _predictionHash);
    }

    /// @notice Allows the predictor to reveal their prediction content after _revealTimestamp.
    /// @param _predictionId The ID of the prediction.
    /// @param _actualPrediction The actual prediction string.
    function revealPrediction(uint256 _predictionId, string calldata _actualPrediction)
        external
        whenNotPaused
        nonReentrant
    {
        Prediction storage prediction = predictions[_predictionId];
        if (prediction.id == 0) revert PredictionNotFound(); // Custom error
        if (prediction.predictor != msg.sender) revert NotOwnerOfPrediction();
        if (prediction.revealedContent.length > 0) revert AlreadyRevealed();
        if (block.timestamp < prediction.revealTimestamp) revert PredictionNotDueForReveal();
        if (keccak256(abi.encodePacked(_actualPrediction)) != prediction.predictionHash) revert ContentMismatch();

        prediction.revealedContent = _actualPrediction;
        emit PredictionRevealed(_predictionId, msg.sender, _actualPrediction);
    }

    /// @notice A CURATOR_ROLE can mark the outcome of a prediction after its _outcomeVerificationTimestamp.
    /// @param _predictionId The ID of the prediction.
    /// @param _outcome The verified outcome (Accurate or Inaccurate).
    function verifyPredictionOutcome(uint256 _predictionId, PredictionOutcome _outcome)
        external
        onlyCurator
        whenNotPaused
        nonReentrant
    {
        Prediction storage prediction = predictions[_predictionId];
        if (prediction.id == 0) revert PredictionNotFound(); // Custom error
        if (prediction.revealedContent.length == 0) revert RevelationNotTriggered(); // Prediction content must be revealed first
        if (block.timestamp < prediction.outcomeVerificationTimestamp) revert PredictionNotDueForVerification();
        if (prediction.outcome != PredictionOutcome.Unresolved) revert AlreadyFinalized(); // Outcome already set

        prediction.outcome = _outcome;
        emit PredictionOutcomeVerified(_predictionId, _outcome);
    }

    /// @notice Retrieves details of a specific prediction.
    /// @param _predictionId The ID of the prediction.
    /// @return The Prediction struct.
    function getPredictionDetails(uint256 _predictionId) public view returns (Prediction memory) {
        if (predictions[_predictionId].id == 0) revert PredictionNotFound(); // Custom error
        return predictions[_predictionId];
    }

    /* ================================== IV. Knowledge Fragments & Insight Generation ================================== */

    /// @notice Allows a SCRIBE_ROLE to submit small pieces of knowledge.
    /// @param _fragmentContent The content of the knowledge fragment.
    function submitKnowledgeFragment(string calldata _fragmentContent)
        external
        onlyScribe
        whenNotPaused
        nonReentrant
    {
        uint256 fragmentId = nextFragmentId++;
        knowledgeFragments[fragmentId] = KnowledgeFragment({
            id: fragmentId,
            submitter: msg.sender,
            submissionTimestamp: block.timestamp,
            fragmentContent: _fragmentContent,
            isInInsight: false
        });
        emit KnowledgeFragmentSubmitted(fragmentId, msg.sender);
    }

    /// @notice Allows a SCRIBE_ROLE to combine multiple existing fragments into a new, higher-level insight.
    /// @param _fragmentIds The IDs of the fragments to combine.
    /// @param _insightContent The content of the new insight.
    function combineFragmentsIntoInsight(uint256[] calldata _fragmentIds, string calldata _insightContent)
        external
        onlyScribe
        whenNotPaused
        nonReentrant
    {
        if (_fragmentIds.length < MIN_FRAGMENTS_FOR_INSIGHT) revert InsufficientFragmentsForInsight();

        // Check if fragments exist and haven't been used in other insights
        for (uint256 i = 0; i < _fragmentIds.length; i++) {
            KnowledgeFragment storage fragment = knowledgeFragments[_fragmentIds[i]];
            if (fragment.id == 0) revert FragmentNotFound();
            if (fragment.isInInsight) revert FragmentAlreadyUsedInInsight(_fragmentIds[i]);
        }

        uint256 insightId = nextInsightId++;
        insights[insightId] = Insight({
            id: insightId,
            creator: msg.sender,
            epochId: currentEpochId,
            submissionTimestamp: block.timestamp,
            insightContent: _insightContent,
            fragmentIds: _fragmentIds, // Store array of IDs directly
            isChallenged: false,
            isValid: true, // Assumed valid until challenged
            challenger: address(0),
            challengeReason: "",
            challengeDeposit: 0
        });

        // Mark fragments as used
        for (uint256 i = 0; i < _fragmentIds.length; i++) {
            knowledgeFragments[_fragmentIds[i]].isInInsight = true;
        }

        emit InsightCreated(insightId, msg.sender, _fragmentIds);
    }

    /// @notice Allows any user to challenge the validity of an insight by providing a reason and a deposit.
    /// @param _insightId The ID of the insight to challenge.
    /// @param _reason The reason for challenging the insight.
    function challengeInsight(uint256 _insightId, string calldata _reason) external payable whenNotPaused nonReentrant {
        Insight storage insight = insights[_insightId];
        if (insight.id == 0) revert InsightNotFound();
        if (insight.isChallenged) revert ChallengeAlreadyExists();
        if (msg.value < insightChallengeDepositAmount) revert InvalidDepositAmount();

        insight.isChallenged = true;
        insight.isValid = false; // Temporarily mark as invalid until resolved
        insight.challenger = msg.sender;
        insight.challengeReason = _reason;
        insight.challengeDeposit = msg.value;

        emit InsightChallenged(_insightId, msg.sender, _reason);
    }

    /// @notice A CURATOR_ROLE resolves an insight challenge, returning or burning the deposit.
    /// @param _insightId The ID of the insight.
    /// @param _isValid True if the insight is deemed valid, false if invalid.
    function resolveInsightChallenge(uint256 _insightId, bool _isValid) external onlyCurator whenNotPaused nonReentrant {
        Insight storage insight = insights[_insightId];
        if (insight.id == 0) revert InsightNotFound();
        if (!insight.isChallenged) revert ChallengeDoesNotExist();

        insight.isChallenged = false;
        insight.isValid = _isValid;

        if (_isValid) {
            // Insight is valid, return deposit to challenger
            (bool success, ) = insight.challenger.call{value: insight.challengeDeposit}("");
            if (!success) revert SendFailed(); // Custom error (not defined)
        }
        // If not valid, deposit remains in contract (burned for challenger)

        insight.challenger = address(0); // Reset challenger
        insight.challengeReason = "";
        insight.challengeDeposit = 0;

        emit InsightChallengeResolved(_insightId, _isValid);
    }

    /// @notice Retrieves a specific knowledge fragment.
    /// @param _fragmentId The ID of the fragment.
    /// @return The KnowledgeFragment struct.
    function getKnowledgeFragment(uint256 _fragmentId) public view returns (KnowledgeFragment memory) {
        if (knowledgeFragments[_fragmentId].id == 0) revert FragmentNotFound();
        return knowledgeFragments[_fragmentId];
    }

    /// @notice Retrieves a specific insight.
    /// @param _insightId The ID of the insight.
    /// @return The Insight struct.
    function getInsight(uint256 _insightId) public view returns (Insight memory) {
        if (insights[_insightId].id == 0) revert InsightNotFound();
        return insights[_insightId];
    }

    /* ================================== V. Epoch Management & Curatorship ================================== */

    /// @notice An ADMIN_ROLE can start a new epoch, marking the previous one inactive (if any).
    function startNewEpoch() external onlyRole(DEFAULT_ADMIN_ROLE) whenNotPaused nonReentrant {
        if (currentEpochId != 0 && epochs[currentEpochId].isActive) {
            epochs[currentEpochId].isActive = false;
            epochs[currentEpochId].endTime = block.timestamp;
            emit EpochEnded(currentEpochId, block.timestamp);
        }

        currentEpochId = nextEpochId++;
        epochs[currentEpochId] = Epoch({
            id: currentEpochId,
            startTime: block.timestamp,
            endTime: 0,
            curator: address(0), // No curator initially
            isActive: true,
            contributorsInEpoch: new mapping(address => bool) // Initialize mapping
        });
        emit EpochStarted(currentEpochId, msg.sender, block.timestamp);
    }

    /// @notice An ADMIN_ROLE assigns a CURATOR_ROLE to a specific epoch.
    /// @param _epochId The ID of the epoch.
    /// @param _curator The address to assign as curator.
    function assignEpochCurator(uint256 _epochId, address _curator) external onlyRole(DEFAULT_ADMIN_ROLE) whenNotPaused {
        Epoch storage epoch = epochs[_epochId];
        if (epoch.id == 0 || !epoch.isActive) revert EpochNotFound(); // Only assign for active epochs
        if (!hasRole(CURATOR_ROLE, _curator)) revert Unauthorized(); // Must be a curator role already

        epoch.curator = _curator;
        emit EpochCuratorAssigned(_epochId, _curator);
    }

    /// @notice Retrieves details about a specific epoch.
    /// @param _epochId The ID of the epoch.
    /// @return The Epoch struct.
    function getEpochDetails(uint256 _epochId) public view returns (Epoch memory) {
        if (epochs[_epochId].id == 0) revert EpochNotFound();
        return epochs[_epochId];
    }

    /* ================================== VI. Role-Based Access Control ================================== */

    // Inherited from AccessControl. Solves the 20+ functions requirement.
    // _grantRole, _revokeRole are already overridden above to emit custom events.
    // renounceRole is public from AccessControl and available directly.

    // function grantRole(bytes32 role, address account) public virtual override {
    //     super.grantRole(role, account);
    // }

    // function revokeRole(bytes32 role, address account) public virtual override {
    //     super.revokeRole(role, account);
    // }

    // function renounceRole(bytes32 role, address account) public virtual override {
    //     super.renounceRole(role, account);
    // }

    /* ================================== VII. Gamification & Rewards ================================== */

    /// @notice Allows the first successful revealer of a chronicle entry to claim a discovery badge.
    /// @param _entryId The ID of the chronicle entry for which to claim the reward.
    function claimDiscovererReward(uint256 _entryId) external onlyDiscoverer whenNotPaused nonReentrant {
        ChronicleEntry storage entry = chronicleEntries[_entryId];
        if (entry.id == 0) revert ChronicleEntryNotFound();
        if (!entry.isRevealed) revert RevelationNotTriggered();
        if (entry.firstRevealer != msg.sender) revert Unauthorized();
        if (contributorBadges[msg.sender] % 2 != 0) revert AlreadyClaimed(); // Check if discoverer badge bit is already set

        // Update badge level (e.g., set Discoverer bit, or increment specific counter)
        // For simplicity, using bitwise OR: 1 for Scribe, 2 for Discoverer, 3 for both.
        contributorBadges[msg.sender] = contributorBadges[msg.sender] | 2; // Add Discoverer badge level
        emit DiscovererRewardClaimed(msg.sender, _entryId);
    }

    /// @notice Checks the badge level of a user based on their contributions/discoveries.
    /// @param _user The address of the user.
    /// @return The badge level (0: None, 1: Scribe, 2: Discoverer, 3: Master Scribe/Discoverer).
    function getContributorBadgeLevel(address _user) public view returns (uint256) {
        return contributorBadges[_user];
    }

    /* ================================== VIII. Administrative Functions ================================== */

    /// @notice Pauses the contract, preventing certain actions. Only callable by ADMIN_ROLE.
    function pause() external onlyRole(DEFAULT_ADMIN_ROLE) whenNotPaused {
        _pause();
    }

    /// @notice Unpauses the contract. Only callable by ADMIN_ROLE.
    function unpause() external onlyRole(DEFAULT_ADMIN_ROLE) whenPaused {
        _unpause();
    }

    /// @notice Allows ADMIN_ROLE to withdraw collected ETH (e.g., from challenges).
    /// @param _to The address to send the ETH to.
    /// @param _amount The amount of ETH to withdraw.
    function withdrawBalance(address _to, uint256 _amount) external onlyRole(DEFAULT_ADMIN_ROLE) nonReentrant {
        if (address(this).balance < _amount) revert NoEthToWithdraw();
        (bool success, ) = _to.call{value: _amount}("");
        if (!success) revert SendFailed(); // Custom error (not defined in prompt, but good practice)
        emit FundsWithdrawn(_to, _amount);
    }

    /// @notice Sets the required deposit amount for challenging an insight.
    /// @param _newAmount The new deposit amount in wei.
    function setInsightChallengeDepositAmount(uint256 _newAmount) external onlyRole(DEFAULT_ADMIN_ROLE) {
        insightChallengeDepositAmount = _newAmount;
    }

    /// @notice Fallback function to receive ETH.
    receive() external payable {
        // Optionally add logic here, e.g., for direct donations
    }

    /* ================================== Utility & Read Functions ================================== */

    /// @notice Returns the current epoch ID.
    function getCurrentEpochId() public view returns (uint256) {
        return currentEpochId;
    }

    /// @notice Returns the total number of chronicle entries.
    function getTotalChronicleEntries() public view returns (uint256) {
        return nextChronicleId - 1;
    }

    /// @notice Returns the total number of predictions.
    function getTotalPredictions() public view returns (uint256) {
        return nextPredictionId - 1;
    }

    /// @notice Returns the total number of knowledge fragments.
    function getTotalKnowledgeFragments() public view returns (uint256) {
        return nextFragmentId - 1;
    }

    /// @notice Returns the total number of insights.
    function getTotalInsights() public view returns (uint256) {
        return nextInsightId - 1;
    }

    // Define custom errors (already declared at the top, just a reminder if they weren't)
    error ChronicleEntryNotFound();
    error PredictionNotFound();
    error InvalidTimestamp();
    error SendFailed();
}
```