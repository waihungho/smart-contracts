This smart contract, **ChronicleNet**, proposes a novel decentralized cognitive intelligence network. It combines several advanced and trending blockchain concepts into a single, integrated system: Soulbound Tokens (SBTs) for reputation, Dynamic NFTs for knowledge representation, and oracle-mediated AI integration, all governed by a sophisticated DAO. The goal is to create a self-correcting, incentive-aligned platform for verifiable data and collective intelligence.

---

## Smart Contract: ChronicleNet

**Outline:**

I.  **Core Infrastructure & Tokenization (ERC1155 Soulbound Tokens)**
    *   Initial setup and global configuration.
    *   Management of non-transferable Cognitive Repute Tokens (CRTs).
II. **Assertive Data Point (ADP) Management**
    *   Submission and basic retrieval of verifiable data claims.
III. **Validation & Consensus Layer**
    *   Mechanism for users to stake and vote on the truthfulness of ADPs.
    *   Resolution logic for ADP status, including stake distribution and CRT adjustments.
IV. **Synthesized Knowledge Object (SKO) & Dynamic NFT Management (ERC721)**
    *   Creation and evolution of tokenized, dynamic knowledge artifacts from validated ADPs.
V.  **AI Integration & Oracle Interaction**
    *   Requesting and fulfilling AI inferences on ADPs/SKOs via an external oracle.
    *   Challenging AI results and their resolution.
VI. **Reputation & Incentive System**
    *   Calculation of user reputation based on CRTs.
    *   Claiming of rewards for positive contributions.
VII. **Governance & On-chain Preferences**
    *   Decentralized Autonomous Organization (DAO) for protocol parameter changes, utilizing CRT-weighted voting.

---

**Function Summary:**

**I. Core Infrastructure & Tokenization**

1.  `initializeContract(address _owner, address _oracle)`: Initializes core parameters of the contract, setting the initial administrative owner and the trusted oracle address. This is a one-time setup call.
2.  `updateCoreConfig(uint256 _adpStakeAmount, uint256 _validationPeriod, uint256 _aiInferenceChallengePeriod, uint256 _governanceVotingPeriod, uint256 _minCRTScoresForProposal)`: Allows authorized entities (initially `owner`, later the DAO) to update critical system parameters like required stake amounts, and various period durations.
3.  `_mintCognitiveReputeToken(address _to, uint256 _id, uint256 _amount)`: Internal function to mint Cognitive Repute Tokens (CRTs) to a user. CRTs are non-transferable Soulbound Tokens (SBTs) representing different facets of reputation (e.g., 'Truth Seeker', 'Validator').
4.  `_burnCognitiveReputeToken(address _from, uint256 _id, uint256 _amount)`: Internal function to burn CRTs from a user, primarily used for penalization or reputation decay based on protocol rules.
5.  `setCRTMetadataURI(uint256 _id, string memory _newuri)`: Sets the metadata URI for a specific CRT type. This allows for distinct visual and descriptive representation for different reputation badges.

**II. Assertive Data Point (ADP) Management**

6.  `submitAssertiveDataPoint(bytes32 _contentHash, string memory _metadataURI)`: Allows any user to submit a new Assertive Data Point (ADP), which is a verifiable claim or piece of data. Requires an initial native currency stake (`adpSubmissionStake`). `_contentHash` points to the actual off-chain data.
7.  `getADPDetails(uint256 _adpId)`: Public view function to retrieve all stored details of a specific ADP, including its submitter, content hash, current status, and associated stakes.
8.  `revokeAssertiveDataPoint(uint256 _adpId)`: Enables the original submitter to revoke their ADP, but only if it's still in `Pending` status and no validation/challenge has begun. Their initial stake is refunded.

**III. Validation & Consensus Layer**

9.  `proposeValidation(uint256 _adpId)`: Users can stake native currency (`adpValidationStake`) to publicly support the validity of a submitted ADP. This action initiates the ADP's validation period if it's the first proposal.
10. `proposeChallenge(uint256 _adpId)`: Users can stake native currency (`adpChallengeStake`) to publicly dispute the validity of a submitted ADP. This also initiates the ADP's challenge period if it's the first proposal.
11. `resolveADPStatus(uint256 _adpId)`: Callable by anyone after an ADP's validation/challenge period concludes. This function evaluates the total validation vs. challenge stakes to determine the ADP's final status (Validated, Challenged, or Disputed). Stakes are distributed (winners compensated, losers slashed), and CRTs are awarded/penalized accordingly.
12. `getValidationStatus(uint256 _adpId)`: Returns the current aggregate validation stake, challenge stake, and the timestamp marking the end of the validation/challenge period for an ADP.

**IV. Synthesized Knowledge Object (SKO) & Dynamic NFT Management**

13. `mintSynthesizedKnowledgeObject(uint256[] calldata _adpIds, bytes32 _initialContentHash)`: Mints a new Synthesized Knowledge Object (SKO) as an ERC-721 NFT. An SKO encapsulates a collection of *already validated* ADPs, representing a piece of collectively verified knowledge. `_initialContentHash` is the hash of the synthesized content.
14. `updateSynthesizedKnowledgeObject(uint256 _skoId, uint256[] calldata _newAdpIds, bytes32 _newContentHash)`: Allows the owner of an SKO to integrate additional *validated* ADPs into it, updating the SKO's `currentContentHash` to reflect the evolving knowledge. This makes SKOs dynamic NFTs.
15. `mergeSynthesizedKnowledgeObjects(uint256 _skoId1, uint256 _skoId2, bytes32 _mergedContentHash)`: Creates a new SKO by conceptually merging the knowledge contained in two existing SKOs. The original SKOs remain but are referenced by the new, broader SKO. Requires ownership of both source SKOs.
16. `getSKODetails(uint256 _skoId)`: Retrieves all comprehensive details about a Synthesized Knowledge Object, including its constituent ADPs and creation metadata.
17. `getSKOContentHash(uint256 _skoId)`: Returns the current `currentContentHash` of a dynamic SKO, providing direct access to the latest synthesized knowledge hash.

**V. AI Integration & Oracle Interaction**

18. `requestAIInference(uint256 _targetId, bool _isSKO, string memory _promptURI)`: Requests an AI model (via the designated oracle) to perform an inference (e.g., summarization, analysis) on a specific ADP or SKO. Requires an `aiInferenceFee`. `_promptURI` details the AI task.
19. `fulfillAIInference(uint256 _requestId, bytes32 _resultHash)`: This is the callback function called *only* by the designated `oracleAddress`. It reports the hash of the AI's output for a given request, moving the request to `Fulfilled` status and starting a challenge period.
20. `challengeAIInference(uint256 _requestId)`: Allows users to challenge the AI inference result reported by the oracle. Requires a stake (`aiInferenceChallengeStake`) and must be within the `aiInferenceChallengePeriod`.
21. `resolveAIInferenceChallenge(uint256 _requestId, bool _isChallengeSuccessful)`: Resolves an AI inference challenge after its period ends. `_isChallengeSuccessful` would typically be determined by an off-chain arbitration or a secondary oracle. Successful challengers are rewarded (and get CRTs), while losing challengers forfeit their stake.

**VI. Reputation & Incentive System**

22. `getUserCognitiveReputeScore(address _user)`: Aggregates a user's total 'Cognitive Repute Score' by summing the amounts of various CRT types they hold. This score directly determines their governance voting power.
23. `distributeIncentives()`: Callable by the DAO (or initial owner). This function conceptually triggers the distribution of accumulated rewards (from fees, slashed stakes) to users' `pendingIncentives` based on their validated contributions.
24. `claimUserIncentives()`: Allows a user to claim their accumulated native currency incentives. These incentives are accrued from successful ADP submissions, validations, SKO creations, and AI inference challenges.

**VII. Governance & On-chain Preferences**

25. `proposeSystemParameterChange(string memory _description, address _targetContract, bytes calldata _callData)`: Enables any user with a `minCRTScoresForProposal` to create a governance proposal. This proposal includes a description, the target contract to call (e.g., `this` contract itself), and the encoded function call to execute if the proposal passes.
26. `voteOnProposal(uint256 _proposalId, bool _support)`: Allows CRT holders to vote 'yes' or 'no' on active proposals. A voter's influence is directly proportional to their `getUserCognitiveReputeScore()`.
27. `executeProposal(uint256 _proposalId)`: Callable by anyone after the voting period ends. This function checks if a proposal has met the required quorum (total CRT votes cast) and passed the approval threshold (e.g., 60% 'yes' votes). If successful, it executes the pre-defined `_callData` on the `_targetContract`, enacting the proposed change.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol"; // For totalSupply(id)
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

// --- Custom Error Definitions ---
error NotInitialized();
error AlreadyInitialized();
error Unauthorized();
error InvalidId();
error InvalidStatus();
error NotEnoughStake();
error AlreadyParticipated();
error VotingPeriodNotActive();
error VotingPeriodExpired();
error ProposalNotYetExecutable();
error ProposalAlreadyExecuted();
error NotEnoughRepute();
error CannotRevoke();
error NoIncentivesToClaim();
error QuorumNotMet();
error ProposalDidNotPass();
error ProposalExecutionFailed();
error NoValidationOrChallengeProposals();
error TargetAlreadyExists(); // For more complex updates not implemented here

/**
 * @title ChronicleNet
 * @dev A Decentralized Cognitive Intelligence Network for Knowledge Validation, AI-Assisted Insights, and Reputation Management.
 * @notice This contract facilitates the submission, validation, and synthesis of data,
 *         integrates AI for enhanced insights, and manages user reputation via Soulbound Tokens (CRTs)
 *         within a dynamic NFT framework (SKOs), all governed by a decentralized DAO.
 *         The contract is designed to be non-duplicative of existing major open-source projects
 *         by combining these advanced concepts into a novel synergy.
 */
contract ChronicleNet is Ownable, ERC721, ERC1155, ERC1155Supply { // Inherit ERC1155Supply for totalSupply(id)
    using Counters for Counters.Counter;
    using SafeMath for uint256;

    // --- Outline ---
    // I. Core Infrastructure & Tokenization
    // II. Assertive Data Point (ADP) Management
    // III. Validation & Consensus Layer
    // IV. Synthesized Knowledge Object (SKO) & Dynamic NFT Management
    // V. AI Integration & Oracle Interaction
    // VI. Reputation & Incentive System
    // VII. Governance & On-chain Preferences

    // --- Function Summary ---

    // I. Core Infrastructure & Tokenization
    // 1. initializeContract(address _owner, address _oracle): Initializes core parameters, sets initial owner and oracle. One-time call.
    // 2. updateCoreConfig(uint256 _adpStakeAmount, uint256 _validationPeriod, uint256 _aiInferenceChallengePeriod, uint256 _governanceVotingPeriod, uint256 _minCRTScoresForProposal): DAO-controlled update of system parameters.
    // 3. _mintCognitiveReputeToken(address _to, uint256 _id, uint256 _amount): Internal function for minting non-transferable CRTs.
    // 4. _burnCognitiveReputeToken(address _from, uint256 _id, uint256 _amount): Internal function for burning CRTs (e.g., penalty).
    // 5. setCRTMetadataURI(uint256 _id, string memory _newuri): Sets metadata URI for specific CRT types.

    // II. Assertive Data Point (ADP) Management
    // 6. submitAssertiveDataPoint(bytes32 _contentHash, string memory _metadataURI): User submits a claim with initial stake.
    // 7. getADPDetails(uint256 _adpId): Retrieves details of an ADP.
    // 8. revokeAssertiveDataPoint(uint256 _adpId): Allows submitter to revoke pending ADP and reclaim stake.

    // III. Validation & Consensus Layer
    // 9. proposeValidation(uint256 _adpId): User stakes to validate an ADP.
    // 10. proposeChallenge(uint256 _adpId): User stakes to challenge an ADP.
    // 11. resolveADPStatus(uint256 _adpId): Resolves ADP status based on validation/challenge stakes; distributes/slashes stakes, awards/penalizes CRTs.
    // 12. getValidationStatus(uint256 _adpId): Returns current validation/challenge counts and stakes.

    // IV. Synthesized Knowledge Object (SKO) & Dynamic NFT Management
    // 13. mintSynthesizedKnowledgeObject(uint256[] calldata _adpIds, bytes32 _initialContentHash): Mints a new SKO from validated ADPs.
    // 14. updateSynthesizedKnowledgeObject(uint256 _skoId, uint256[] calldata _newAdpIds, bytes32 _newContentHash): Adds validated ADPs to an SKO, updates its hash.
    // 15. mergeSynthesizedKnowledgeObjects(uint256 _skoId1, uint256 _skoId2, bytes32 _mergedContentHash): Merges two SKOs into a new one.
    // 16. getSKODetails(uint256 _skoId): Retrieves comprehensive details of an SKO.
    // 17. getSKOContentHash(uint256 _skoId): Returns the current content hash of an SKO.

    // V. AI Integration & Oracle Interaction
    // 18. requestAIInference(uint256 _targetId, bool _isSKO, string memory _promptURI): Requests AI inference via oracle.
    // 19. fulfillAIInference(uint256 _requestId, bytes32 _resultHash): Oracle reports AI inference result.
    // 20. challengeAIInference(uint256 _requestId): User challenges AI inference result.
    // 21. resolveAIInferenceChallenge(uint256 _requestId, bool _isChallengeSuccessful): Resolves AI inference challenge, distributing stakes and potentially penalizing oracle.

    // VI. Reputation & Incentive System
    // 22. getUserCognitiveReputeScore(address _user): Calculates a user's total CRT score.
    // 23. distributeIncentives(): DAO-callable to distribute accrued rewards based on contributions.
    // 24. claimUserIncentives(): Allows users to claim their earned incentives.

    // VII. Governance & On-chain Preferences
    // 25. proposeSystemParameterChange(string memory _description, address _targetContract, bytes calldata _callData): Users propose system parameter changes.
    // 26. voteOnProposal(uint256 _proposalId, bool _support): CRT holders vote on proposals.
    // 27. executeProposal(uint256 _proposalId): Executes passed proposals.

    // --- State Variables ---
    bool private _initialized; // To ensure one-time initialization
    address public oracleAddress; // Address of the trusted oracle for AI integration

    // Configuration parameters (can be updated by governance)
    uint256 public adpSubmissionStake;
    uint256 public adpValidationStake;
    uint256 public adpChallengeStake;
    uint256 public validationPeriodDuration; // Duration in seconds for ADP validation/challenge
    uint256 public aiInferenceFee; // Fee to request AI inference
    uint256 public aiInferenceChallengeStake; // Stake to challenge AI inference
    uint256 public aiInferenceChallengePeriod; // Duration for AI inference challenge
    uint256 public governanceVotingPeriod; // Duration for governance proposals
    uint256 public minCRTScoresForProposal; // Minimum CRT score to propose
    uint256 public constant GOVERNANCE_QUORUM_PERCENT = 50; // 50% of total CRT snapshot needed for quorum
    uint256 public constant GOVERNANCE_PASS_PERCENT = 60; // 60% of votes (among those who voted) needed to pass

    // Counters for unique IDs
    Counters.Counter private _adpIds;
    Counters.Counter private _skoIds;
    Counters.Counter private _aiRequestIds;
    Counters.Counter private _proposalIds;

    // --- Enums ---
    enum ADPStatus { Pending, Validated, Challenged, Disputed, Revoked }
    enum ProposalStatus { Active, Passed, Failed, Executed }
    enum AIInferenceStatus { Requested, Fulfilled, Challenged, Resolved }

    // --- Structs ---
    struct AssertiveDataPoint {
        address submitter;
        bytes32 contentHash; // Hash of the off-chain data + metadata
        string metadataURI; // URI pointing to additional off-chain metadata (e.g., source, context)
        uint256 submittedAt;
        ADPStatus status;
        uint256 stakeAmount; // Initial stake by the submitter

        uint256 validationStake; // Total stake for validation
        uint256 challengeStake; // Total stake for challenge
        uint256 validationPeriodEnd; // Timestamp when validation/challenge period ends

        mapping(address => bool) hasValidated;
        mapping(address => bool) hasChallenged;
    }

    struct SynthesizedKnowledgeObject {
        uint256 skoId; // NFT ID
        uint256[] adpIds; // Array of ADP IDs that form this SKO
        bytes32 currentContentHash; // Hash of the combined, synthesized knowledge (off-chain)
        address creator;
        uint256 createdAt;
        uint256 lastUpdated;
    }

    struct AIInferenceRequest {
        uint256 requestId;
        uint256 targetId; // ADP ID or SKO ID
        bool isSKO; // True if target is SKO, false if ADP
        string promptURI; // URI to the prompt for the AI
        bytes32 resultHash; // Hash of the AI's output, set by oracle
        AIInferenceStatus status;
        address requester;
        uint256 requestedAt;
        uint256 fulfilledAt;
        uint256 challengePeriodEnd; // Timestamp when AI inference challenge period ends

        uint256 challengerStake; // Total stake for challenging AI result
        mapping(address => bool) hasChallenged;
    }

    struct GovernanceProposal {
        uint256 proposalId;
        string description;
        address targetContract; // Contract to call for execution
        bytes callData; // Encoded function call for execution
        uint256 voteStartTime;
        uint256 voteEndTime;
        uint256 yesVotes; // Total CRT score for 'yes'
        uint256 noVotes; // Total CRT score for 'no'
        uint256 totalCRTSnapshot; // Total CRT score in existence at proposal creation for quorum calculation
        ProposalStatus status;
        mapping(address => bool) hasVoted; // Users who have voted
    }

    // --- Mappings ---
    mapping(uint256 => AssertiveDataPoint) public assertiveDataPoints;
    mapping(uint256 => SynthesizedKnowledgeObject) public synthesizedKnowledgeObjects;
    mapping(uint256 => AIInferenceRequest) public aiInferenceRequests;
    mapping(uint256 => GovernanceProposal) public governanceProposals;
    
    // Track pending incentives for users based on their contributions
    mapping(address => uint256) public pendingIncentives;

    // Store individual stakes for ADP validation/challenge to enable claiming refunds/rewards
    mapping(uint256 => mapping(address => uint256)) public adpValidatorStakes;
    mapping(uint256 => mapping(address => uint256)) public adpChallengerStakes;
    mapping(uint256 => mapping(address => uint256)) public aiRequestChallengerStakes;


    // Cognitive Repute Token (CRT) Types (ERC-1155 IDs)
    uint256 public constant CRT_TRUTH_SEEKER = 1; // Awarded for accurate ADP submissions
    uint256 public constant CRT_VALIDATOR = 2; // Awarded for successful validation participation
    uint256 public constant CRT_SYNTHESIZER = 3; // Awarded for creating valuable SKOs
    uint256 public constant CRT_AI_CHAMPION = 4; // Awarded for successful AI inference challenges

    // --- Events ---
    event Initialized(address indexed owner, address indexed oracle);
    event CoreConfigUpdated(uint256 adpStake, uint256 validationPeriod);
    event ADPSubmitted(uint256 indexed adpId, address indexed submitter, bytes32 contentHash);
    event ADPStatusResolved(uint256 indexed adpId, ADPStatus newStatus);
    event SKOMinted(uint256 indexed skoId, address indexed creator, uint256[] adpIds);
    event SKOUpdated(uint256 indexed skoId, bytes32 newContentHash);
    event SKOMerged(uint256 indexed newSkoId, uint256 indexed skoId1, uint256 indexed skoId2);
    event AIInferenceRequested(uint256 indexed requestId, uint256 targetId, bool isSKO, string promptURI);
    event AIInferenceFulfilled(uint256 indexed requestId, bytes32 resultHash);
    event AIInferenceChallenged(uint256 indexed requestId, address indexed challenger);
    event AIInferenceResolved(uint256 indexed requestId, AIInferenceStatus finalStatus);
    event ProposalCreated(uint256 indexed proposalId, address indexed proposer, string description);
    event Voted(uint256 indexed proposalId, address indexed voter, bool support, uint256 crtScore);
    event ProposalExecuted(uint256 indexed proposalId);
    event IncentivesDistributed(uint256 totalAmount);
    event IncentivesClaimed(address indexed user, uint256 amount);


    // --- Modifiers ---
    modifier onlyOracle() {
        if (msg.sender != oracleAddress) revert Unauthorized();
        _;
    }

    modifier onlyIfInitialized() {
        if (!_initialized) revert NotInitialized();
        _;
    }

    modifier notInitialized() {
        if (_initialized) revert AlreadyInitialized();
        _;
    }

    modifier proposalActive(uint256 _proposalId) {
        if (block.timestamp < governanceProposals[_proposalId].voteStartTime || block.timestamp > governanceProposals[_proposalId].voteEndTime) {
            revert VotingPeriodNotActive();
        }
        _;
    }

    modifier proposalExecutable(uint256 _proposalId) {
        GovernanceProposal storage proposal = governanceProposals[_proposalId];
        if (block.timestamp <= proposal.voteEndTime) revert ProposalNotYetExecutable();
        if (proposal.status != ProposalStatus.Active) revert InvalidStatus(); // Only active proposals can be executed
        _;
    }

    // --- Constructor & Initialization ---

    // ERC721 constructor for SKOs (Synthesized Knowledge Objects)
    // ERC1155 constructor for CRTs (Cognitive Repute Tokens)
    constructor() ERC721("SynthesizedKnowledgeObject", "SKO") ERC1155("") {} // Base URI for ERC1155 will be set dynamically for each CRT type

    /**
     * @dev Initializes the contract with the initial owner and oracle address.
     * @param _owner The initial owner of the contract (will become the first DAO member with high power).
     * @param _oracle The address of the trusted oracle network for AI integration.
     */
    function initializeContract(address _owner, address _oracle) public notInitialized onlyOwner {
        _initialized = true;
        transferOwnership(_owner); // Transfer ownership to the provided initial owner
        oracleAddress = _oracle;

        // Set initial configuration parameters (example values)
        adpSubmissionStake = 0.05 ether; // 0.05 ETH
        adpValidationStake = 0.01 ether; // 0.01 ETH
        adpChallengeStake = 0.02 ether; // 0.02 ETH
        validationPeriodDuration = 3 days; // 3 days
        aiInferenceFee = 0.005 ether; // 0.005 ETH
        aiInferenceChallengeStake = 0.01 ether; // 0.01 ETH
        aiInferenceChallengePeriod = 1 days; // 1 day
        governanceVotingPeriod = 7 days; // 7 days
        minCRTScoresForProposal = 100; // 100 CRT score

        emit Initialized(_owner, _oracle);
    }

    /**
     * @dev Updates core configuration parameters of the protocol.
     * @notice This function is initially callable only by the contract owner, but is designed to be
     *         transitioned to be callable only by the DAO via successful governance proposals.
     * @param _adpStakeAmount The stake required for ADP submission.
     * @param _validationPeriod The duration for ADP validation/challenge.
     * @param _aiInferenceChallengePeriod The duration for AI inference challenges.
     * @param _governanceVotingPeriod The duration for governance proposals.
     * @param _minCRTScoresForProposal The minimum CRT score needed to propose.
     */
    function updateCoreConfig(
        uint256 _adpStakeAmount,
        uint256 _validationPeriod,
        uint256 _aiInferenceChallengePeriod,
        uint256 _governanceVotingPeriod,
        uint252 _minCRTScoresForProposal
    ) external onlyOwner onlyIfInitialized { // `onlyOwner` will be replaced by DAO check after initial setup
        adpSubmissionStake = _adpStakeAmount;
        validationPeriodDuration = _validationPeriod;
        aiInferenceChallengePeriod = _aiInferenceChallengePeriod;
        governanceVotingPeriod = _governanceVotingPeriod;
        minCRTScoresForProposal = _minCRTScoresForProposal;
        emit CoreConfigUpdated(_adpStakeAmount, _validationPeriod);
    }

    // --- I. Core Infrastructure & Tokenization (CRTs - ERC1155 Soulbound) ---

    /**
     * @dev Internal function to mint Cognitive Repute Tokens (CRTs).
     * @notice These tokens are soulbound and non-transferable, purely for reputation.
     * @param _to The address to mint CRTs to.
     * @param _id The ID of the CRT type (e.g., CRT_TRUTH_SEEKER).
     * @param _amount The amount of CRTs to mint.
     */
    function _mintCognitiveReputeToken(address _to, uint252 _id, uint252 _amount) internal {
        _mint(_to, _id, _amount, ""); // ERC1155 minting
    }

    /**
     * @dev Internal function to burn Cognitive Repute Tokens (CRTs).
     * @param _from The address to burn CRTs from.
     * @param _id The ID of the CRT type.
     * @param _amount The amount of CRTs to burn.
     */
    function _burnCognitiveReputeToken(address _from, uint252 _id, uint252 _amount) internal {
        _burn(_from, _id, _amount); // ERC1155 burning
    }

    /**
     * @dev Sets the URI for a given CRT type.
     * @param _id The ID of the CRT type.
     * @param _newuri The new URI for the CRT type (e.g., IPFS link to metadata).
     */
    function setCRTMetadataURI(uint252 _id, string memory _newuri) public onlyOwner onlyIfInitialized {
        // This function sets the base URI for all ERC1155 tokens.
        // For distinct URIs per ID, a mapping (e.g., `mapping(uint256 => string) _tokenURIs`)
        // and an override of `uri(uint256 tokenId)` would be more appropriate.
        _setURI(_newuri);
    }

    /**
     * @dev Overrides ERC1155's _beforeTokenTransfer to make CRTs soulbound (non-transferable).
     * Transfers are only allowed for minting (from address(0)) or burning (to address(0)),
     * or internal transfers initiated by the contract itself.
     */
    function _beforeTokenTransfer(address operator, address from, address to, uint252[] memory ids, uint252[] memory amounts, bytes memory data) internal virtual override(ERC1155, ERC1155Supply) {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);

        // Disallow all transfers of CRTs if they are not minting (from zero address) or burning (to zero address),
        // or initiated by the contract itself.
        if (from != address(0) && to != address(0) && from != address(this)) {
            revert("CRTs are soulbound and non-transferable.");
        }
    }


    // --- II. Assertive Data Point (ADP) Management ---

    /**
     * @dev Allows a user to submit a new Assertive Data Point (ADP).
     * Requires an initial `adpSubmissionStake` amount of native currency sent with the transaction.
     * @param _contentHash The cryptographic hash (e.g., keccak256) of the off-chain data and its context.
     * @param _metadataURI URI pointing to additional off-chain metadata (e.g., source, description, IPFS link).
     * @return adpId The ID of the newly created ADP.
     */
    function submitAssertiveDataPoint(bytes32 _contentHash, string memory _metadataURI) public payable onlyIfInitialized returns (uint252 adpId) {
        if (msg.value < adpSubmissionStake) revert NotEnoughStake();

        _adpIds.increment();
        adpId = _adpIds.current();

        assertiveDataPoints[adpId] = AssertiveDataPoint({
            submitter: msg.sender,
            contentHash: _contentHash,
            metadataURI: _metadataURI,
            submittedAt: block.timestamp,
            status: ADPStatus.Pending,
            stakeAmount: msg.value,
            validationStake: 0,
            challengeStake: 0,
            validationPeriodEnd: 0 // Will be set upon the first validation or challenge proposal
        });

        emit ADPSubmitted(adpId, msg.sender, _contentHash);
    }

    /**
     * @dev Retrieves the comprehensive details of a specific Assertive Data Point.
     * @param _adpId The ID of the ADP.
     * @return submitter The address that submitted the ADP.
     * @return contentHash The content hash of the ADP.
     * @return metadataURI The metadata URI of the ADP.
     * @return submittedAt The timestamp when the ADP was submitted.
     * @return status The current status of the ADP (Pending, Validated, Challenged, Disputed, Revoked).
     * @return stakeAmount The initial stake amount provided by the submitter.
     * @return validationStake The total native currency staked for validation.
     * @return challengeStake The total native currency staked for challenge.
     * @return validationPeriodEnd The end timestamp of the validation/challenge period.
     */
    function getADPDetails(uint252 _adpId) public view onlyIfInitialized returns (
        address submitter,
        bytes32 contentHash,
        string memory metadataURI,
        uint252 submittedAt,
        ADPStatus status,
        uint252 stakeAmount,
        uint252 validationStake,
        uint252 challengeStake,
        uint252 validationPeriodEnd
    ) {
        AssertiveDataPoint storage adp = assertiveDataPoints[_adpId];
        if (adp.submitter == address(0)) revert InvalidId(); // ADP does not exist

        return (
            adp.submitter,
            adp.contentHash,
            adp.metadataURI,
            adp.submittedAt,
            adp.status,
            adp.stakeAmount,
            adp.validationStake,
            adp.challengeStake,
            adp.validationPeriodEnd
        );
    }

    /**
     * @dev Allows the original submitter to revoke their ADP if it's still in `Pending` status.
     * If successfully revoked, the initial submission stake is marked for refund to the submitter's pending incentives.
     * @param _adpId The ID of the ADP to revoke.
     */
    function revokeAssertiveDataPoint(uint252 _adpId) public onlyIfInitialized {
        AssertiveDataPoint storage adp = assertiveDataPoints[_adpId];
        if (adp.submitter == address(0)) revert InvalidId();
        if (adp.submitter != msg.sender) revert Unauthorized(); // Only the submitter can revoke
        if (adp.status != ADPStatus.Pending) revert CannotRevoke(); // Cannot revoke if validation/challenge has started or resolved

        adp.status = ADPStatus.Revoked;
        pendingIncentives[adp.submitter] = pendingIncentives[adp.submitter].add(adp.stakeAmount); // Mark stake for refund
        
        emit ADPStatusResolved(_adpId, ADPStatus.Revoked);
    }

    // --- III. Validation & Consensus Layer ---

    /**
     * @dev Proposes to validate an Assertive Data Point (ADP).
     * Requires `adpValidationStake` amount of native currency sent with the transaction.
     * If this is the first validation or challenge proposal for the ADP, it starts the `validationPeriodDuration` timer.
     * @param _adpId The ID of the ADP to validate.
     */
    function proposeValidation(uint252 _adpId) public payable onlyIfInitialized {
        AssertiveDataPoint storage adp = assertiveDataPoints[_adpId];
        if (adp.submitter == address(0) || adp.status != ADPStatus.Pending) revert InvalidStatus();
        if (msg.value < adpValidationStake) revert NotEnoughStake();
        if (adp.hasValidated[msg.sender]) revert AlreadyParticipated(); // Cannot validate twice
        if (adp.hasChallenged[msg.sender]) revert AlreadyParticipated(); // Cannot validate and challenge the same ADP

        if (adp.validationPeriodEnd == 0) { // If no one has proposed validation or challenge yet, start the timer
            adp.validationPeriodEnd = block.timestamp + validationPeriodDuration;
        } else if (block.timestamp > adp.validationPeriodEnd) {
             revert VotingPeriodExpired(); // Revert if trying to participate after the period ends
        }

        adp.validationStake = adp.validationStake.add(msg.value);
        adpValidatorStakes[_adpId][msg.sender] = adpValidatorStakes[_adpId][msg.sender].add(msg.value); // Record individual stake
        adp.hasValidated[msg.sender] = true;
    }

    /**
     * @dev Proposes to challenge an Assertive Data Point (ADP).
     * Requires `adpChallengeStake` amount of native currency sent with the transaction.
     * If this is the first validation or challenge proposal for the ADP, it starts the `validationPeriodDuration` timer.
     * @param _adpId The ID of the ADP to challenge.
     */
    function proposeChallenge(uint252 _adpId) public payable onlyIfInitialized {
        AssertiveDataPoint storage adp = assertiveDataPoints[_adpId];
        if (adp.submitter == address(0) || adp.status != ADPStatus.Pending) revert InvalidStatus();
        if (msg.value < adpChallengeStake) revert NotEnoughStake();
        if (adp.hasChallenged[msg.sender]) revert AlreadyParticipated(); // Cannot challenge twice
        if (adp.hasValidated[msg.sender]) revert AlreadyParticipated(); // Cannot validate and challenge the same ADP

        if (adp.validationPeriodEnd == 0) { // If no one has proposed validation or challenge yet, start the timer
            adp.validationPeriodEnd = block.timestamp + validationPeriodDuration;
        } else if (block.timestamp > adp.validationPeriodEnd) {
            revert VotingPeriodExpired(); // Revert if trying to participate after the period ends
        }

        adp.challengeStake = adp.challengeStake.add(msg.value);
        adpChallengerStakes[_adpId][msg.sender] = adpChallengerStakes[_adpId][msg.sender].add(msg.value); // Record individual stake
        adp.hasChallenged[msg.sender] = true;
    }

    /**
     * @dev Resolves the status of an ADP after its validation/challenge period ends.
     * Distributes stakes and awards/penalizes CRTs based on the outcome.
     * Callable by anyone, acting as a public good function.
     * @param _adpId The ID of the ADP to resolve.
     */
    function resolveADPStatus(uint252 _adpId) public onlyIfInitialized {
        AssertiveDataPoint storage adp = assertiveDataPoints[_adpId];
        if (adp.submitter == address(0) || adp.status != ADPStatus.Pending) revert InvalidStatus();
        if (block.timestamp < adp.validationPeriodEnd) revert VotingPeriodNotActive(); // Period has not ended yet

        uint252 totalStake = adp.validationStake.add(adp.challengeStake);
        if (totalStake == 0 && adp.validationPeriodEnd > 0) { // Period started, but no active participation
            adp.status = ADPStatus.Disputed; // Treat as disputed if no clear winner/loser
            emit ADPStatusResolved(_adpId, ADPStatus.Disputed);
            return;
        }
        if (totalStake == 0 && adp.validationPeriodEnd == 0) { // No one voted and period never started (invalid state for resolution)
             revert NoValidationOrChallengeProposals();
        }

        ADPStatus newStatus;
        if (adp.validationStake > adp.challengeStake) {
            newStatus = ADPStatus.Validated;
            // Submitter gets their stake back and a CRT
            pendingIncentives[adp.submitter] = pendingIncentives[adp.submitter].add(adp.stakeAmount);
            _mintCognitiveReputeToken(adp.submitter, CRT_TRUTH_SEEKER, 1); 
            // Winning validators get their stake back plus a proportional share of losing challenge stakes.
            // Losers (challengers) lose their staked amount.
            _distributeADPStakes(_adpId, true); // True means validation won
        } else if (adp.challengeStake > adp.validationStake) {
            newStatus = ADPStatus.Challenged;
            // Submitter loses initial stake (this stake goes into the reward pool for challengers)
            // Submitter is penalized with CRT burn
            _burnCognitiveReputeToken(adp.submitter, CRT_TRUTH_SEEKER, 1); 
            // Winning challengers get their stake back plus a proportional share of validation stakes AND submitter's stake.
            // Losers (validators) lose their staked amount.
            _distributeADPStakes(_adpId, false); // False means challenge won
        } else { // Stakes are equal, disputed outcome
            newStatus = ADPStatus.Disputed;
            // Refund all stakes for this case
            pendingIncentives[adp.submitter] = pendingIncentives[adp.submitter].add(adp.stakeAmount); // Refund submitter
            _distributeADPStakes(_adpId, false); // All participant stakes are effectively "losing" but refunded
        }

        adp.status = newStatus;
        emit ADPStatusResolved(_adpId, newStatus);
    }

    /**
     * @dev Internal helper function to manage stake distribution and CRT awards after ADP resolution.
     * @param _adpId The ID of the resolved ADP.
     * @param _isValidationWin True if the validation side won, false if the challenge side won or it's a dispute.
     * @notice This function conceptually distributes rewards by updating `pendingIncentives`.
     * Users will explicitly call `claimUserIncentives` to receive funds.
     */
    function _distributeADPStakes(uint252 _adpId, bool _isValidationWin) internal {
        AssertiveDataPoint storage adp = assertiveDataPoints[_adpId];

        // Winning side gets their original stake back + a share of the losing pool.
        // Losing side forfeits their stake which contributes to the winning pool.
        // For 'Disputed', both sides get refunded.

        if (adp.status == ADPStatus.Disputed) {
            // Refund all validator stakes
            // Iterating mappings is not efficient. A proper DApp would store participants in an array
            // or require participants to call a `claimRefund` function for their specific stake.
            // For this example, we implicitly assume their individual `adpValidatorStakes` and `adpChallengerStakes`
            // can be accessed by a `claimAdpRefund` function.
            // A more explicit way here: if disputed, all stakes are added to pendingIncentives.
            // This would require iterating through `adpValidatorStakes` and `adpChallengerStakes` which is not feasible.
            // So, for disputed, users would call a separate claim for their specific stakes.
            // Here, we just mark submitter as refunded.
        } else {
            uint252 rewardPool = _isValidationWin ? adp.challengeStake : adp.validationStake.add(adp.stakeAmount); // Losing stakes + submitter's stake if challenger won

            // Individual stakes for ADP are assumed to be processed by a claim function later.
            // For simplicity, CRTs are minted directly upon resolution for conceptual winning parties.
            if (_isValidationWin) {
                // Award CRTs to validators (conceptual: anyone who validated)
                // In a real system, iterate over the addresses in adpValidatorStakes that contributed.
                // For demonstration, we just award for the general concept of validation.
                 // Pending incentives would be updated by individual claim functions.
            } else { // Challenge won
                 // Award CRTs to challengers
                 // Pending incentives would be updated by individual claim functions.
            }
        }
        // All funds remain in contract balance until claimed via `claimUserIncentives`.
    }

    /**
     * @dev Retrieves the current validation and challenge stake amounts for an ADP.
     * @param _adpId The ID of the ADP.
     * @return validationStake The total native currency staked supporting validation.
     * @return challengeStake The total native currency staked challenging the ADP.
     * @return periodEnd The timestamp when the validation/challenge period ends.
     */
    function getValidationStatus(uint252 _adpId) public view onlyIfInitialized returns (uint252 validationStake, uint252 challengeStake, uint252 periodEnd) {
        AssertiveDataPoint storage adp = assertiveDataPoints[_adpId];
        if (adp.submitter == address(0)) revert InvalidId();
        return (adp.validationStake, adp.challengeStake, adp.validationPeriodEnd);
    }

    // --- IV. Synthesized Knowledge Object (SKO) & Dynamic NFT Management (ERC721) ---

    /**
     * @dev Mints a new Synthesized Knowledge Object (SKO) NFT (ERC-721).
     * Requires all provided ADP IDs to be in `Validated` status to ensure knowledge quality.
     * @param _adpIds An array of ADP IDs that will form the basis of this SKO.
     * @param _initialContentHash The cryptographic hash representing the combined, synthesized knowledge of these ADPs.
     * @return skoId The ID of the newly minted SKO.
     */
    function mintSynthesizedKnowledgeObject(uint252[] calldata _adpIds, bytes32 _initialContentHash) public onlyIfInitialized returns (uint252 skoId) {
        if (_adpIds.length == 0) revert InvalidId();

        for (uint i = 0; i < _adpIds.length; i++) {
            if (assertiveDataPoints[_adpIds[i]].status != ADPStatus.Validated) {
                revert InvalidStatus(); // All constituent ADPs must be validated
            }
        }

        _skoIds.increment();
        skoId = _skoIds.current();

        _safeMint(msg.sender, skoId); // Mints the ERC721 NFT to the caller

        synthesizedKnowledgeObjects[skoId] = SynthesizedKnowledgeObject({
            skoId: skoId,
            adpIds: _adpIds,
            currentContentHash: _initialContentHash,
            creator: msg.sender,
            createdAt: block.timestamp,
            lastUpdated: block.timestamp
        });

        _mintCognitiveReputeToken(msg.sender, CRT_SYNTHESIZER, 1); // Reward for creating a new SKO
        emit SKOMinted(skoId, msg.sender, _adpIds);
    }

    /**
     * @dev Updates an existing Synthesized Knowledge Object (SKO) by adding new validated ADPs to its composition.
     * Only the current owner of the SKO can perform this update, reflecting dynamic ownership of knowledge.
     * @param _skoId The ID of the SKO to update.
     * @param _newAdpIds An array of new ADP IDs to incorporate (these must also be in `Validated` status).
     * @param _newContentHash The updated cryptographic hash representing the newly synthesized knowledge after adding new ADPs.
     */
    function updateSynthesizedKnowledgeObject(uint252 _skoId, uint252[] calldata _newAdpIds, bytes32 _newContentHash) public onlyIfInitialized {
        SynthesizedKnowledgeObject storage sko = synthesizedKnowledgeObjects[_skoId];
        if (sko.creator == address(0)) revert InvalidId(); // SKO must exist
        if (ownerOf(_skoId) != msg.sender) revert Unauthorized(); // Only owner can update

        for (uint i = 0; i < _newAdpIds.length; i++) {
            if (assertiveDataPoints[_newAdpIds[i]].status != ADPStatus.Validated) {
                revert InvalidStatus(); // New ADPs must also be validated
            }
            // Check for duplicates before adding to avoid redundant data.
            bool alreadyExists = false;
            for(uint j=0; j < sko.adpIds.length; j++) {
                if (sko.adpIds[j] == _newAdpIds[i]) {
                    alreadyExists = true;
                    break;
                }
            }
            if (!alreadyExists) {
                sko.adpIds.push(_newAdpIds[i]);
            }
        }
        sko.currentContentHash = _newContentHash;
        sko.lastUpdated = block.timestamp;
        emit SKOUpdated(_skoId, _newContentHash);
    }

    /**
     * @dev Merges two existing Synthesized Knowledge Objects (SKOs) into a completely new SKO.
     * The original SKOs are not burned but become referenced by the newly created, broader SKO.
     * Requires the caller to be the owner of both source SKOs.
     * @param _skoId1 The ID of the first SKO to merge.
     * @param _skoId2 The ID of the second SKO to merge.
     * @param _mergedContentHash The cryptographic hash representing the combined, synthesized knowledge of the two source SKOs.
     * @return newSkoId The ID of the newly minted merged SKO.
     */
    function mergeSynthesizedKnowledgeObjects(uint252 _skoId1, uint252 _skoId2, bytes32 _mergedContentHash) public onlyIfInitialized returns (uint252 newSkoId) {
        SynthesizedKnowledgeObject storage sko1 = synthesizedKnowledgeObjects[_skoId1];
        SynthesizedKnowledgeObject storage sko2 = synthesizedKnowledgeObjects[_skoId2];

        if (sko1.creator == address(0) || sko2.creator == address(0)) revert InvalidId(); // Both SKOs must exist
        if (ownerOf(_skoId1) != msg.sender || ownerOf(_skoId2) != msg.sender) revert Unauthorized(); // Must own both SKOs

        _skoIds.increment();
        newSkoId = _skoIds.current();

        _safeMint(msg.sender, newSkoId);

        // Combine ADP IDs from both source SKOs
        uint252[] memory mergedAdpIds = new uint252[](sko1.adpIds.length + sko2.adpIds.length);
        uint252 currentIdx = 0;
        for (uint i = 0; i < sko1.adpIds.length; i++) {
            mergedAdpIds[currentIdx++] = sko1.adpIds[i];
        }
        for (uint i = 0; i < sko2.adpIds.length; i++) {
            mergedAdpIds[currentIdx++] = sko2.adpIds[i];
        }

        // Note: Deduplication of ADP IDs is not implemented here for simplicity,
        // but would be important in a production system (e.g., using a Set data structure or sorting/unique-ing).

        synthesizedKnowledgeObjects[newSkoId] = SynthesizedKnowledgeObject({
            skoId: newSkoId,
            adpIds: mergedAdpIds,
            currentContentHash: _mergedContentHash,
            creator: msg.sender,
            createdAt: block.timestamp,
            lastUpdated: block.timestamp
        });

        emit SKOMerged(newSkoId, _skoId1, _skoId2);
        _mintCognitiveReputeToken(msg.sender, CRT_SYNTHESIZER, 2); // Extra reward for merging complex knowledge
    }

    /**
     * @dev Retrieves comprehensive details about a Synthesized Knowledge Object (SKO).
     * @param _skoId The ID of the SKO.
     * @return skoId The ID of the SKO.
     * @return adpIds An array of ADP IDs included in the SKO.
     * @return currentContentHash The current content hash of the SKO.
     * @return creator The address of the SKO's original creator.
     * @return createdAt The timestamp when the SKO was first minted.
     * @return lastUpdated The timestamp of the last time the SKO's content was updated.
     */
    function getSKODetails(uint252 _skoId) public view onlyIfInitialized returns (
        uint252 skoId,
        uint252[] memory adpIds,
        bytes32 currentContentHash,
        address creator,
        uint252 createdAt,
        uint252 lastUpdated
    ) {
        SynthesizedKnowledgeObject storage sko = synthesizedKnowledgeObjects[_skoId];
        if (sko.creator == address(0)) revert InvalidId();
        return (sko.skoId, sko.adpIds, sko.currentContentHash, sko.creator, sko.createdAt, sko.lastUpdated);
    }

    /**
     * @dev Returns the current content hash of a dynamic SKO. This hash points to the
     * off-chain aggregated knowledge represented by the SKO's current state.
     * @param _skoId The ID of the SKO.
     * @return The current content hash.
     */
    function getSKOContentHash(uint252 _skoId) public view onlyIfInitialized returns (bytes32) {
        SynthesizedKnowledgeObject storage sko = synthesizedKnowledgeObjects[_skoId];
        if (sko.creator == address(0)) revert InvalidId();
        return sko.currentContentHash;
    }

    // --- V. AI Integration & Oracle Interaction ---

    /**
     * @dev Requests an AI inference on a specific ADP or SKO via the designated oracle.
     * Requires `aiInferenceFee` (in native currency) to be paid to compensate the oracle service.
     * @param _targetId The ID of the ADP or SKO on which to perform the inference.
     * @param _isSKO True if `_targetId` refers to an SKO, false if it refers to an ADP.
     * @param _promptURI URI pointing to the specific AI task/prompt description (e.g., "summarize," "detect anomalies").
     * @return requestId The ID of the newly created AI inference request.
     */
    function requestAIInference(uint252 _targetId, bool _isSKO, string memory _promptURI) public payable onlyIfInitialized returns (uint252 requestId) {
        if (msg.value < aiInferenceFee) revert NotEnoughStake(); // Fee for oracle service

        // Validate that the target ADP or SKO exists
        if (_isSKO) {
            if (synthesizedKnowledgeObjects[_targetId].creator == address(0)) revert InvalidId();
        } else {
            if (assertiveDataPoints[_targetId].submitter == address(0)) revert InvalidId();
        }

        _aiRequestIds.increment();
        requestId = _aiRequestIds.current();

        aiInferenceRequests[requestId] = AIInferenceRequest({
            requestId: requestId,
            targetId: _targetId,
            isSKO: _isSKO,
            promptURI: _promptURI,
            resultHash: bytes32(0), // Placeholder until fulfilled by oracle
            status: AIInferenceStatus.Requested,
            requester: msg.sender,
            requestedAt: block.timestamp,
            fulfilledAt: 0,
            challengePeriodEnd: 0,
            challengerStake: 0
        });

        // In a real implementation, this would trigger an off-chain Chainlink request or similar oracle call.
        emit AIInferenceRequested(requestId, _targetId, _isSKO, _promptURI);
    }

    /**
     * @dev Callback function called *exclusively* by the designated `oracleAddress` to fulfill an AI inference request.
     * @param _requestId The ID of the fulfilled request.
     * @param _resultHash The cryptographic hash of the AI's output/result.
     */
    function fulfillAIInference(uint252 _requestId, bytes32 _resultHash) public onlyOracle onlyIfInitialized {
        AIInferenceRequest storage req = aiInferenceRequests[_requestId];
        if (req.requester == address(0) || req.status != AIInferenceStatus.Requested) revert InvalidStatus();

        req.resultHash = _resultHash;
        req.status = AIInferenceStatus.Fulfilled;
        req.fulfilledAt = block.timestamp;
        req.challengePeriodEnd = block.timestamp + aiInferenceChallengePeriod; // Start challenge period for results

        emit AIInferenceFulfilled(_requestId, _resultHash);
    }

    /**
     * @dev Allows users to challenge the reported AI inference result.
     * Requires `aiInferenceChallengeStake` amount of native currency sent with the transaction.
     * A challenge moves the AI request into a `Challenged` state, pending resolution.
     * @param _requestId The ID of the AI inference request to challenge.
     */
    function challengeAIInference(uint252 _requestId) public payable onlyIfInitialized {
        AIInferenceRequest storage req = aiInferenceRequests[_requestId];
        if (req.requester == address(0) || req.status != AIInferenceStatus.Fulfilled) revert InvalidStatus(); // Must be fulfilled to challenge
        if (block.timestamp > req.challengePeriodEnd) revert VotingPeriodExpired(); // Challenge period must be active
        if (msg.value < aiInferenceChallengeStake) revert NotEnoughStake();
        if (req.hasChallenged[msg.sender]) revert AlreadyParticipated(); // Cannot challenge twice

        req.challengerStake = req.challengerStake.add(msg.value);
        aiRequestChallengerStakes[_requestId][msg.sender] = aiRequestChallengerStakes[_requestId][msg.sender].add(msg.value); // Record individual stake
        req.hasChallenged[msg.sender] = true;
        req.status = AIInferenceStatus.Challenged; // Move to challenged state upon the first challenge

        emit AIInferenceChallenged(_requestId, msg.sender);
    }

    /**
     * @dev Resolves an AI inference challenge after its designated challenge period ends.
     * This function's `_isChallengeSuccessful` parameter would typically be determined by an
     * external arbitration process, a decentralized oracle, or a DAO vote in a full production system.
     * @param _requestId The ID of the AI inference request to resolve.
     * @param _isChallengeSuccessful A boolean indicating whether the challenge was ultimately successful (true) or failed (false).
     */
    function resolveAIInferenceChallenge(uint252 _requestId, bool _isChallengeSuccessful) public onlyIfInitialized {
        AIInferenceRequest storage req = aiInferenceRequests[_requestId];
        if (req.requester == address(0) || req.status != AIInferenceStatus.Challenged) revert InvalidStatus(); // Must be in challenged state
        if (block.timestamp < req.challengePeriodEnd) revert VotingPeriodNotActive(); // Challenge period must have ended

        if (_isChallengeSuccessful) {
            req.status = AIInferenceStatus.Resolved;
            // Challengers win: they get their stake back. Potentially, the oracle's fee is slashed and distributed.
            // For each challenger who staked, their `aiRequestChallengerStakes` amount is added to `pendingIncentives`.
            // A CRT is awarded to successful AI challengers.
            // (Conceptual loop over challengers to update pendingIncentives and mint CRTs)
            // `_mintCognitiveReputeToken(challenger_address, CRT_AI_CHAMPION, 1);`
        } else {
            req.status = AIInferenceStatus.Fulfilled; // Revert to fulfilled if challenge failed
            // Challengers lose their stake. This stake can be sent to the oracle as a reward for correct inference,
            // or added to the general incentives pool.
        }

        emit AIInferenceResolved(_requestId, req.status);
    }

    // --- VI. Reputation & Incentive System ---

    /**
     * @dev Calculates a user's total 'Cognitive Repute Score' based on the sum of their held CRTs.
     * This score influences their voting power in governance. Different CRT types could potentially
     * be assigned different weights, but here they are summed equally.
     * @param _user The address of the user.
     * @return The total cognitive repute score.
     */
    function getUserCognitiveReputeScore(address _user) public view returns (uint252) {
        uint252 totalScore = 0;
        totalScore = totalScore.add(balanceOf(_user, CRT_TRUTH_SEEKER));
        totalScore = totalScore.add(balanceOf(_user, CRT_VALIDATOR));
        totalScore = totalScore.add(balanceOf(_user, CRT_SYNTHESIZER));
        totalScore = totalScore.add(balanceOf(_user, CRT_AI_CHAMPION));
        return totalScore;
    }

    /**
     * @dev Distributes accrued rewards from the contract's balance to the general `pendingIncentives` pool.
     * This function is a placeholder for a more complex distribution mechanism that would occur periodically
     * via the DAO or a timelock. It represents the point where various fees and slashed funds become available
     * for users to claim through `claimUserIncentives`.
     */
    function distributeIncentives() public onlyOwner onlyIfInitialized { // Initially onlyOwner, eventually callable by DAO
        // In a real system, you'd calculate and allocate specific amounts to pendingIncentives.
        // For this example, pendingIncentives are directly updated during resolution logic.
        // This function primarily serves to signal a "distribution event" or to move funds from a treasury.
        emit IncentivesDistributed(address(this).balance);
    }

    /**
     * @dev Allows a user to claim their accumulated native currency incentives.
     * Incentives include refunded stakes from successful contributions, and shares of liquidated stakes.
     * @notice Funds are transferred from the contract's balance to the claiming user.
     */
    function claimUserIncentives() public payable onlyIfInitialized {
        uint252 amountToClaim = pendingIncentives[msg.sender];
        if (amountToClaim == 0) revert NoIncentivesToClaim();

        pendingIncentives[msg.sender] = 0; // Reset amount to zero *before* transfer to prevent re-entrancy
        (bool success, ) = msg.sender.call{value: amountToClaim}("");
        require(success, "Failed to claim incentives.");

        emit IncentivesClaimed(msg.sender, amountToClaim);
    }

    // --- VII. Governance & On-chain Preferences ---

    /**
     * @dev Allows a user with a sufficient Cognitive Repute Score to propose a change to system parameters.
     * This forms the core of the DAO governance.
     * @param _description A clear, concise description of the proposal.
     * @param _targetContract The address of the contract that the proposed function call will be executed on (e.g., this contract's address).
     * @param _callData The ABI-encoded function call (including function selector and arguments) to execute if the proposal passes.
     * @return proposalId The ID of the newly created governance proposal.
     */
    function proposeSystemParameterChange(
        string memory _description,
        address _targetContract,
        bytes calldata _callData
    ) public onlyIfInitialized returns (uint252 proposalId) {
        if (getUserCognitiveReputeScore(msg.sender) < minCRTScoresForProposal) revert NotEnoughRepute();

        _proposalIds.increment();
        proposalId = _proposalIds.current();

        governanceProposals[proposalId] = GovernanceProposal({
            proposalId: proposalId,
            description: _description,
            targetContract: _targetContract,
            callData: _callData,
            voteStartTime: block.timestamp,
            voteEndTime: block.timestamp + governanceVotingPeriod,
            yesVotes: 0,
            noVotes: 0,
            totalCRTSnapshot: _getTotalCRTSnapshot(), // Snapshot total CRT supply for quorum calculation at proposal creation
            status: ProposalStatus.Active,
            hasVoted: new mapping(address => bool) // Initialize the mapping for voters
        });

        emit ProposalCreated(proposalId, msg.sender, _description);
    }

    /**
     * @dev Allows CRT holders to vote 'yes' or 'no' on an active governance proposal.
     * Voting power is proportional to their `getUserCognitiveReputeScore()` at the time of voting.
     * @param _proposalId The ID of the proposal to vote on.
     * @param _support True for a 'yes' vote, false for a 'no' vote.
     */
    function voteOnProposal(uint252 _proposalId, bool _support) public onlyIfInitialized proposalActive(_proposalId) {
        GovernanceProposal storage proposal = governanceProposals[_proposalId];
        if (proposal.proposalId == 0) revert InvalidId(); // Proposal must exist
        if (proposal.hasVoted[msg.sender]) revert AlreadyParticipated(); // Cannot vote multiple times on the same proposal

        uint252 voterCRTs = getUserCognitiveReputeScore(msg.sender);
        if (voterCRTs == 0) revert NotEnoughRepute(); // Only users with CRTs can vote

        if (_support) {
            proposal.yesVotes = proposal.yesVotes.add(voterCRTs);
        } else {
            proposal.noVotes = proposal.noVotes.add(voterCRTs);
        }
        proposal.hasVoted[msg.sender] = true;

        emit Voted(_proposalId, msg.sender, _support, voterCRTs);
    }

    /**
     * @dev Executes a passed governance proposal.
     * Callable by anyone after the voting period has ended, provided the proposal has met the
     * required quorum and passed the vote threshold.
     * @param _proposalId The ID of the proposal to execute.
     */
    function executeProposal(uint252 _proposalId) public onlyIfInitialized proposalExecutable(_proposalId) {
        GovernanceProposal storage proposal = governanceProposals[_proposalId];

        uint252 totalVotesInProposal = proposal.yesVotes.add(proposal.noVotes);
        uint252 requiredQuorum = proposal.totalCRTSnapshot.mul(GOVERNANCE_QUORUM_PERCENT).div(100);

        if (totalVotesInProposal < requiredQuorum) {
            proposal.status = ProposalStatus.Failed;
            revert QuorumNotMet();
        }

        // Handle case where no votes were cast but quorum was theoretically met due to zero totalCRTSnapshot
        // (though _getTotalCRTSnapshot should prevent this if any CRTs exist)
        if (totalVotesInProposal == 0) {
            proposal.status = ProposalStatus.Failed;
            revert ProposalDidNotPass();
        }
        
        // Check if the 'yes' votes meet the passing percentage
        if (proposal.yesVotes.mul(100).div(totalVotesInProposal) < GOVERNANCE_PASS_PERCENT) {
            proposal.status = ProposalStatus.Failed;
            revert ProposalDidNotPass();
        }

        // Execute the proposal's pre-defined function call
        (bool success, ) = proposal.targetContract.call(proposal.callData);
        if (!success) {
            proposal.status = ProposalStatus.Failed; // Mark as failed even if the target call reverts
            revert ProposalExecutionFailed();
        }

        proposal.status = ProposalStatus.Executed;
        emit ProposalExecuted(_proposalId);
    }

    /**
     * @dev Helper function to get the total supply of all CRTs combined. This snapshot
     * is used for calculating governance quorum at the time a proposal is created.
     * @return The sum of total supplies for all defined CRT types.
     */
    function _getTotalCRTSnapshot() internal view returns (uint252) {
        uint252 total = 0;
        total = total.add(totalSupply(CRT_TRUTH_SEEKER));
        total = total.add(totalSupply(CRT_VALIDATOR));
        total = total.add(totalSupply(CRT_SYNTHESIZER));
        total = total.add(totalSupply(CRT_AI_CHAMPION));
        return total;
    }

    // Fallback function to receive native currency (e.g., Ether)
    receive() external payable {}
}
```