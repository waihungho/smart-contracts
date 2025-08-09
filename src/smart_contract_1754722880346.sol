Okay, this is an exciting challenge! Creating something truly unique and advanced while avoiding existing open-source patterns requires a deep dive into emerging concepts and how they can be woven together on-chain.

Let's imagine a "Decentralized Algorithmic Knowledge Synthesis Protocol" – a system where users contribute "knowledge fragments," which are then processed and synthesized by others using verifiable algorithms (or verifiable claims of algorithmic processing) into "synergistic insights." The protocol uses a multi-faceted reputation system, dynamic reward mechanisms, and a novel dispute resolution model, all while building an on-chain, evolving knowledge graph.

---

## Synergist Protocol: Outline and Function Summary

**Contract Name:** `SynergistProtocol`

**Core Concept:** A decentralized, collaborative network for the synthesis of verifiable knowledge. Participants contribute raw knowledge fragments, process them into richer insights using algorithms (or algorithmic claims), and collectively verify the quality and accuracy of the network's output. It features a dynamic reputation system, algorithmic reward distribution, and an on-chain evolving knowledge graph.

---

### **Outline**

1.  **Contract Setup:**
    *   Pragma, SPDX License, Imports (`Ownable`, `Pausable`).
    *   Custom Errors.
    *   Enums for statuses and roles.
    *   Structs for Knowledge Fragments, Synergistic Insights, Reputation Profiles, Proposals, Disputes, and Categories.
    *   State Variables (mappings, counters).
    *   Events for key actions.
    *   Modifiers for access control and state checks.

2.  **Core Knowledge Flow Functions (Contribution, Synthesis, Evolution, Attestation):**
    *   Submitting raw data/claims.
    *   Combining/processing raw data into insights.
    *   Refining existing insights.
    *   Verifying contributions and insights.

3.  **Reputation System Functions:**
    *   Calculating and updating multi-dimensional reputation scores.
    *   Delegating reputation for governance or processing power.

4.  **Reward Mechanism Functions:**
    *   Distributing rewards based on reputation, quality, and impact.
    *   Managing reward pools and multipliers.

5.  **Governance and Parameter Management Functions:**
    *   Proposing and voting on protocol changes, new categories, or new algorithmic validation rules.
    *   Executing approved proposals.

6.  **Dispute Resolution Functions:**
    *   Initiating disputes against fragments or insights.
    *   Submitting evidence.
    *   Facilitating arbitration and appeals.

7.  **Query & Utility Functions (Read-Only):**
    *   Retrieving knowledge data.
    *   Checking user status.
    *   Protocol state queries.

---

### **Function Summary (25+ Functions)**

**I. Core Knowledge Flow & Interaction (8 Functions)**

1.  `submitKnowledgeFragment(bytes32 _contentHash, string calldata _metadataURI, string[] calldata _sources, uint256 _categoryId)`: Allows a user to submit a new, raw piece of verifiable knowledge. Each fragment gets a unique ID and is stored with a content hash (for integrity) and metadata URI (for off-chain context/visuals).
2.  `attestKnowledgeFragment(uint256 _fragmentId, bool _isAccurate)`: Allows an eligible user to attest to the accuracy and quality of a Knowledge Fragment. Positive attestations increase the fragment's verification score and the attester's reputation.
3.  `synthesizeInsight(uint256[] calldata _linkedFragmentIds, bytes32 _insightContentHash, string calldata _metadataURI, uint256 _validationAlgorithmId)`: Enables a "Processor" to combine multiple verified Knowledge Fragments into a "Synergistic Insight," claiming a specific validation algorithm was used.
4.  `attestSynergisticInsight(uint256 _insightId, bool _isValid, bool _isNovel)`: Allows eligible users to attest to the validity, novelty, and coherence of a Synergistic Insight.
5.  `evolveSynergisticInsight(uint256 _parentInsightId, uint256[] calldata _newLinkedFragmentIds, bytes32 _newInsightContentHash, string calldata _newMetadataURI, uint256 _validationAlgorithmId)`: Allows a Processor to create a new version of an existing Synergistic Insight, incorporating new fragments or refined processing.
6.  `flagContent(uint256 _entityId, EntityType _entityType, string calldata _reason)`: Allows any user to flag a Knowledge Fragment or Synergistic Insight for review due to potential inaccuracy, plagiarism, or malicious content. This can trigger a dispute.
7.  `proposeNewCategory(string calldata _categoryName, string calldata _description)`: Allows a user to propose a new classification category for Knowledge Fragments, subject to governance vote.
8.  `voteOnNewCategoryProposal(uint256 _proposalId, bool _approve)`: Casts a vote on a new category proposal.

**II. Reputation & Stake Management (4 Functions)**

9.  `delegateReputation(address _delegatee, uint256 _amount)`: Allows a user to delegate a portion of their reputation score to another user, enhancing the delegatee's influence in specific roles (e.g., arbitration, processing, or voting).
10. `undelegateReputation(address _delegatee, uint256 _amount)`: Recalls previously delegated reputation.
11. `claimReputationReward()`: Allows users to claim their accrued reputation-based rewards, which are calculated dynamically based on successful contributions, attestations, and synthesis.
12. `getReputationProfile(address _user) view returns (ReputationProfile memory)`: Retrieves the detailed reputation profile of a given user, including scores for contribution, processing, verification, and governance.

**III. Algorithmic Validation & Registry (3 Functions)**

13. `registerValidationAlgorithm(string calldata _name, string calldata _description, string calldata _verifierContractAddress, string calldata _verificationMethodURI)`: Allows trusted entities (or governance-approved entities) to register a new "algorithmic validation method" that can be claimed by Processors when synthesizing insights. This doesn't run the algorithm on-chain, but defines *how* it should be verified off-chain.
14. `deregisterValidationAlgorithm(uint256 _algorithmId)`: Removes an algorithm from the registry (via governance).
15. `getValidationAlgorithm(uint256 _algorithmId) view returns (ValidationAlgorithm memory)`: Retrieves details about a registered validation algorithm.

**IV. Decentralized Governance & Parameter Control (5 Functions)**

16. `proposeProtocolParameterChange(string calldata _parameterName, uint256 _newValue)`: Initiates a governance proposal to change a key protocol parameter (e.g., reward multipliers, minimum reputation for roles).
17. `voteOnProposal(uint256 _proposalId, bool _approve)`: Allows users with governance reputation to vote on active proposals.
18. `executeProposal(uint256 _proposalId)`: Executes an approved and quorum-reached proposal, updating protocol parameters.
19. `updateRewardMultiplier(RewardType _type, uint256 _newMultiplier)`: Allows governance to adjust multipliers for different reward types (e.g., higher reward for novel insights). This would be called by `executeProposal`.
20. `allocateTreasuryFunds(address _recipient, uint256 _amount)`: Allows governance to allocate funds from the protocol's treasury (e.g., for grants, research, or development).

**V. Dynamic Dispute Resolution & Arbitration (3 Functions)**

21. `initiateDispute(uint256 _entityId, EntityType _entityType, string calldata _reason)`: Formally initiates a dispute process for a flagged Knowledge Fragment or Synergistic Insight. Requires a small stake.
22. `submitDisputeEvidence(uint256 _disputeId, string calldata _evidenceURI)`: Allows parties involved in a dispute (initiator, subject, and later arbitrators) to submit evidence.
23. `resolveDispute(uint256 _disputeId, DisputeResolution _resolution)`: An appointed (or randomly selected, or reputation-weighted voted) arbitrator resolves the dispute, leading to reputation adjustments and potential content status changes.

**VI. Read-Only Queries & Utilities (2 Functions)**

24. `getKnowledgeFragmentDetails(uint256 _fragmentId) view returns (KnowledgeFragment memory)`: Retrieves all on-chain details of a specific Knowledge Fragment.
25. `getSynergisticInsightDetails(uint256 _insightId) view returns (SynergisticInsight memory)`: Retrieves all on-chain details of a specific Synergistic Insight.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol"; // Assuming an ERC-20 token for rewards

// --- Custom Errors ---
error SynergistProtocol__InvalidContentHash();
error SynergistProtocol__MetadataURINotSet();
error SynergistProtocol__FragmentNotFound();
error SynergistProtocol__InsightNotFound();
error SynergistProtocol__CategoryNotFound();
error SynergistProtocol__NotEligibleForAttestation();
error SynergistProtocol__SelfAttestationForbidden();
error SynergistProtocol__AlreadyAttested();
error SynergistProtocol__InsufficientReputation();
error SynergistProtocol__InvalidProposalState();
error SynergistProtocol__AlreadyVoted();
error SynergistProtocol__ProposalVotingPeriodNotEnded();
error SynergistProtocol__ProposalQuorumNotReached();
error SynergistProtocol__ProposalNotApproved();
error SynergistProtocol__InvalidRewardType();
error SynergistProtocol__DisputeNotFound();
error SynergistProtocol__DisputeAlreadyResolved();
error SynergistProtocol__NotDisputeParticipant();
error SynergistProtocol__InvalidEntityForDispute();
error SynergistProtocol__CannotEvolveUnverifiedInsight();
error SynergistProtocol__InvalidValidationAlgorithm();
error SynergistProtocol__LinkedFragmentNotVerified();
error SynergistProtocol__DuplicateLinkedFragment();
error SynergistProtocol__DelegationAmountExceedsAvailable();
error SynergistProtocol__CannotUndelegateMoreThanDelegated();
error SynergistProtocol__RewardPoolEmpty();
error SynergistProtocol__NoRewardsToClaim();
error SynergistProtocol__ValidationAlgorithmAlreadyRegistered();


contract SynergistProtocol is Ownable, Pausable {

    // --- Enums ---
    enum FragmentStatus { PendingVerification, Verified, Disputed, Rejected }
    enum InsightStatus { PendingVerification, Verified, Disputed, Rejected, Evolved }
    enum EntityType { KnowledgeFragment, SynergisticInsight }
    enum ProposalState { Pending, Active, Succeeded, Failed, Executed }
    enum DisputeState { Open, EvidenceSubmission, Arbitration, Resolved, Appealed }
    enum DisputeResolution { Valid, Invalid, Undecided }
    enum RewardType { Contributor, Processor, Verifier, NoveltyBonus, GovernanceBonus }

    // --- Structs ---

    struct KnowledgeFragment {
        uint256 id;
        address contributor;
        bytes32 contentHash;
        string metadataURI; // IPFS URI for external content/metadata
        string[] sources;
        uint256 categoryId;
        FragmentStatus status;
        uint256 submissionTimestamp;
        mapping(address => bool) hasAttested; // Track who attested
        uint256 positiveAttestations;
        uint256 negativeAttestations;
    }

    struct SynergisticInsight {
        uint256 id;
        address creator;
        uint256[] linkedFragmentIds; // IDs of fragments used
        bytes32 insightContentHash;
        string metadataURI; // IPFS URI for synthesized content/metadata
        uint256 validationAlgorithmId; // ID referencing a registered algorithm
        InsightStatus status;
        uint256 creationTimestamp;
        uint256 version; // For evolved insights
        uint256 parentInsightId; // 0 if original, ID of parent if evolved
        mapping(address => bool) hasAttested; // Track who attested
        uint256 positiveAttestations;
        uint256 negativeAttestations;
        uint256 noveltyAttestations; // Specific for insights
    }

    struct ReputationProfile {
        uint256 totalReputation; // Overall reputation score
        uint256 contributionScore; // Based on submitted KFs
        uint256 processingScore;   // Based on created SIs
        uint256 verificationScore; // Based on attestations
        uint224 governanceScore;   // Based on governance participation (delegated + self)
        uint256 lastRewardClaimTimestamp;
        mapping(address => uint256) delegatedTo; // How much this user delegated to others
        mapping(address => uint256) delegatedFrom; // How much reputation this user received
    }

    struct ParameterProposal {
        uint256 id;
        address proposer;
        string parameterName;
        uint256 newValue;
        uint256 voteCount;
        uint256 requiredVotes;
        uint256 votingDeadline;
        mapping(address => bool) hasVoted;
        ProposalState state;
        string description; // For context
    }

    struct CategoryProposal {
        uint256 id;
        address proposer;
        string categoryName;
        string description;
        uint256 voteCount;
        uint256 requiredVotes;
        uint256 votingDeadline;
        mapping(address => bool) hasVoted;
        ProposalState state;
        uint256 newCategoryId; // Set upon execution
    }

    struct Dispute {
        uint256 id;
        uint256 entityId;
        EntityType entityType;
        address initiator;
        address subjectAddress; // Contributor/Creator of the entity
        string reason;
        string evidenceURI; // URI to evidence submitted by initiator
        DisputeState state;
        DisputeResolution resolution;
        uint256 initiationTimestamp;
        uint256 resolutionTimestamp;
        address currentArbitrator; // If single arbitrator model, or lead arbiter
        uint256 stakeAmount; // Amount staked to initiate dispute
    }

    struct KnowledgeCategory {
        uint256 id;
        string name;
        string description;
        bool exists;
    }

    struct ValidationAlgorithm {
        uint256 id;
        string name;
        string description;
        address verifierContractAddress; // Address of a contract that could potentially verify or validate off-chain claims
        string verificationMethodURI; // URI to detailed off-chain verification instructions/spec
        bool isActive;
    }

    // --- State Variables ---
    uint256 private _fragmentIdCounter;
    uint256 private _insightIdCounter;
    uint256 private _proposalIdCounter;
    uint256 private _disputeIdCounter;
    uint256 private _categoryIdCounter;
    uint256 private _algorithmIdCounter;

    mapping(uint256 => KnowledgeFragment) public knowledgeFragments;
    mapping(uint256 => SynergisticInsight) public synergisticInsights;
    mapping(address => ReputationProfile) public reputationProfiles;
    mapping(uint256 => ParameterProposal) public parameterProposals;
    mapping(uint256 => CategoryProposal) public categoryProposals;
    mapping(uint256 => Dispute) public disputes;
    mapping(uint256 => KnowledgeCategory) public categories;
    mapping(uint256 => ValidationAlgorithm) public validationAlgorithms;

    // Protocol Parameters (changeable via governance)
    uint256 public minReputationForAttestation = 100;
    uint256 public minReputationForProcessing = 500;
    uint256 public minReputationForProposing = 1000;
    uint256 public minReputationForArbitration = 2000;
    uint256 public proposalVotingPeriod = 7 days;
    uint256 public proposalQuorumPercentage = 51; // Percentage of total governance reputation
    uint256 public disputeInitiationStake = 1 ether; // Example value, needs ERC-20 token
    uint256 public minPositiveAttestationsForVerificationKF = 5;
    uint256 public minPositiveAttestationsForVerificationSI = 3;

    // Reward Multipliers (changeable via governance)
    mapping(RewardType => uint256) public rewardMultipliers;
    IERC20 public rewardToken; // The token used for rewards

    // --- Events ---
    event KnowledgeFragmentSubmitted(uint256 indexed fragmentId, address indexed contributor, uint256 categoryId, bytes32 contentHash);
    event KnowledgeFragmentAttested(uint256 indexed fragmentId, address indexed attester, bool isAccurate);
    event KnowledgeFragmentStatusUpdated(uint256 indexed fragmentId, FragmentStatus newStatus);
    event SynergisticInsightCreated(uint256 indexed insightId, address indexed creator, uint256 indexed parentInsightId, uint256 validationAlgorithmId, bytes32 insightContentHash);
    event SynergisticInsightAttested(uint256 indexed insightId, address indexed attester, bool isValid, bool isNovel);
    event SynergisticInsightStatusUpdated(uint256 indexed insightId, InsightStatus newStatus);
    event ReputationUpdated(address indexed user, uint256 newTotalReputation, uint256 contribution, uint256 processing, uint256 verification, uint256 governance);
    event ReputationDelegated(address indexed delegator, address indexed delegatee, uint256 amount);
    event ReputationUndelegated(address indexed delegator, address indexed delegatee, uint256 amount);
    event RewardClaimed(address indexed user, uint256 amount);
    event ParameterChangeProposed(uint256 indexed proposalId, string parameterName, uint256 newValue, address indexed proposer);
    event ProposalVoted(uint256 indexed proposalId, address indexed voter, bool approved);
    event ProposalExecuted(uint256 indexed proposalId);
    event NewCategoryProposed(uint256 indexed proposalId, string categoryName);
    event NewCategoryAdded(uint256 indexed categoryId, string categoryName);
    event DisputeInitiated(uint256 indexed disputeId, uint256 indexed entityId, EntityType entityType, address indexed initiator);
    event DisputeEvidenceSubmitted(uint256 indexed disputeId, address indexed submitter, string evidenceURI);
    event DisputeResolved(uint256 indexed disputeId, DisputeResolution resolution, address indexed arbitrator);
    event ContentFlagged(uint256 indexed entityId, EntityType entityType, address indexed flipper, string reason);
    event ValidationAlgorithmRegistered(uint256 indexed algorithmId, string name, address verifierContractAddress);
    event ValidationAlgorithmDeregistered(uint256 indexed algorithmId);


    // --- Modifiers ---
    modifier onlyEligibleAttester() {
        if (reputationProfiles[msg.sender].verificationScore < minReputationForAttestation) {
            revert SynergistProtocol__NotEligibleForAttestation();
        }
        _;
    }

    modifier onlyEligibleProcessor() {
        if (reputationProfiles[msg.sender].processingScore < minReputationForProcessing) {
            revert SynergistProtocol__InsufficientReputation();
        }
        _;
    }

    modifier onlyEligibleProposer() {
        if (reputationProfiles[msg.sender].totalReputation < minReputationForProposing) {
            revert SynergistProtocol__InsufficientReputation();
        }
        _;
    }

    // --- Constructor ---
    constructor(address _rewardTokenAddress) Ownable(msg.sender) Pausable() {
        rewardToken = IERC20(_rewardTokenAddress);
        // Initialize default categories
        _categoryIdCounter = 1;
        categories[1] = KnowledgeCategory(1, "General Science", "Broad scientific knowledge.");
        categories[2] = KnowledgeCategory(2, "Technology & AI", "Insights related to tech, AI, blockchain.");
        categories[3] = KnowledgeCategory(3, "Health & Wellness", "Information on health, medicine, biology.");
        categories[4] = KnowledgeCategory(4, "Social Sciences", "Topics in sociology, psychology, economics.");
        categories[5] = KnowledgeCategory(5, "Arts & Culture", "Knowledge in humanities, arts, history.");

        // Initialize default reward multipliers (e.g., in basis points, 10000 = 1x)
        rewardMultipliers[RewardType.Contributor] = 100; // 1% of base reward per fragment
        rewardMultipliers[RewardType.Processor] = 200;   // 2%
        rewardMultipliers[RewardType.Verifier] = 50;     // 0.5%
        rewardMultipliers[RewardType.NoveltyBonus] = 100; // 1% bonus
        rewardMultipliers[RewardType.GovernanceBonus] = 50; // 0.5% bonus
    }

    // --- Internal Helpers ---

    function _updateReputation(address _user, RewardType _type, uint256 _amount) internal {
        ReputationProfile storage profile = reputationProfiles[_user];
        uint256 multiplier = rewardMultipliers[_type];

        if (_type == RewardType.Contributor) {
            profile.contributionScore += _amount;
        } else if (_type == RewardType.Processor) {
            profile.processingScore += _amount;
        } else if (_type == RewardType.Verifier) {
            profile.verificationScore += _amount;
        } else if (_type == RewardType.NoveltyBonus) {
            profile.processingScore += _amount; // Novelty bonus contributes to processing
        } else if (_type == RewardType.GovernanceBonus) {
            profile.governanceScore += _amount;
        }

        profile.totalReputation = profile.contributionScore + profile.processingScore + profile.verificationScore + profile.governanceScore;
        
        // Add a base amount for the specific action, scaled by multiplier
        // This is a simplified example. Real rewards would be more complex.
        // For simplicity, totalReputation acts as "points" for later token claim.
        profile.totalReputation += (_amount * multiplier) / 10000; // Divide by 10000 for basis points

        emit ReputationUpdated(_user, profile.totalReputation, profile.contributionScore, profile.processingScore, profile.verificationScore, profile.governanceScore);
    }

    function _calculateClaimableRewards(address _user) internal view returns (uint256) {
        ReputationProfile storage profile = reputationProfiles[_user];
        // Simplified: Rewards accumulate based on reputation score after last claim
        // In a real system, this would be more nuanced, perhaps based on
        // a "points" system directly tied to actions, then convertible to tokens.
        // For this example, let's assume `totalReputation` directly translates to claimable points.
        // And these points clear upon claiming.
        return profile.totalReputation;
    }

    // --- I. Core Knowledge Flow & Interaction (8 Functions) ---

    /// @notice Allows a user to submit a new, raw piece of verifiable knowledge.
    /// @param _contentHash A unique hash of the knowledge fragment's content for integrity verification.
    /// @param _metadataURI IPFS or similar URI pointing to off-chain metadata (e.g., visual representation, detailed text).
    /// @param _sources An array of source references (e.g., URLs, DOIs, publication names).
    /// @param _categoryId The ID of the category this fragment belongs to.
    function submitKnowledgeFragment(
        bytes32 _contentHash,
        string calldata _metadataURI,
        string[] calldata _sources,
        uint256 _categoryId
    ) external whenNotPaused {
        if (_contentHash == bytes32(0)) revert SynergistProtocol__InvalidContentHash();
        if (bytes(_metadataURI).length == 0) revert SynergistProtocol__MetadataURINotSet();
        if (!categories[_categoryId].exists) revert SynergistProtocol__CategoryNotFound();

        _fragmentIdCounter++;
        uint256 newId = _fragmentIdCounter;

        KnowledgeFragment storage newFragment = knowledgeFragments[newId];
        newFragment.id = newId;
        newFragment.contributor = msg.sender;
        newFragment.contentHash = _contentHash;
        newFragment.metadataURI = _metadataURI;
        newFragment.sources = _sources;
        newFragment.categoryId = _categoryId;
        newFragment.status = FragmentStatus.PendingVerification;
        newFragment.submissionTimestamp = block.timestamp;

        _updateReputation(msg.sender, RewardType.Contributor, 10); // Base points for contribution

        emit KnowledgeFragmentSubmitted(newId, msg.sender, _categoryId, _contentHash);
    }

    /// @notice Allows an eligible user to attest to the accuracy and quality of a Knowledge Fragment.
    /// @param _fragmentId The ID of the Knowledge Fragment to attest.
    /// @param _isAccurate True if the fragment is deemed accurate, false otherwise.
    function attestKnowledgeFragment(uint256 _fragmentId, bool _isAccurate) external whenNotPaused onlyEligibleAttester {
        KnowledgeFragment storage fragment = knowledgeFragments[_fragmentId];
        if (fragment.id == 0) revert SynergistProtocol__FragmentNotFound();
        if (fragment.contributor == msg.sender) revert SynergistProtocol__SelfAttestationForbidden();
        if (fragment.hasAttested[msg.sender]) revert SynergistProtocol__AlreadyAttested();
        if (fragment.status != FragmentStatus.PendingVerification) revert SynergistProtocol__InvalidProposalState(); // Can only attest pending

        fragment.hasAttested[msg.sender] = true;
        if (_isAccurate) {
            fragment.positiveAttestations++;
            _updateReputation(msg.sender, RewardType.Verifier, 5); // Points for positive attestation
        } else {
            fragment.negativeAttestations++;
            _updateReputation(msg.sender, RewardType.Verifier, 2); // Less points for flagging inaccuracy
        }

        // Auto-verify if enough positive attestations
        if (fragment.positiveAttestations >= minPositiveAttestationsForVerificationKF) {
            fragment.status = FragmentStatus.Verified;
            emit KnowledgeFragmentStatusUpdated(_fragmentId, FragmentStatus.Verified);
        }
        // Could also add logic for auto-rejection if too many negative attestations

        emit KnowledgeFragmentAttested(_fragmentId, msg.sender, _isAccurate);
    }

    /// @notice Enables a "Processor" to combine multiple verified Knowledge Fragments into a "Synergistic Insight".
    /// @param _linkedFragmentIds An array of IDs of verified Knowledge Fragments to link.
    /// @param _insightContentHash A unique hash for the synthesized insight's content.
    /// @param _metadataURI IPFS or similar URI for off-chain metadata of the insight.
    /// @param _validationAlgorithmId The ID of the registered validation algorithm claimed to be used.
    function synthesizeInsight(
        uint256[] calldata _linkedFragmentIds,
        bytes32 _insightContentHash,
        string calldata _metadataURI,
        uint256 _validationAlgorithmId
    ) external whenNotPaused onlyEligibleProcessor {
        if (_linkedFragmentIds.length == 0) revert SynergistProtocol__InvalidContentHash();
        if (_insightContentHash == bytes32(0)) revert SynergistProtocol__InvalidContentHash();
        if (bytes(_metadataURI).length == 0) revert SynergistProtocol__MetadataURINotSet();
        if (validationAlgorithms[_validationAlgorithmId].id == 0 || !validationAlgorithms[_validationAlgorithmId].isActive) {
            revert SynergistProtocol__InvalidValidationAlgorithm();
        }

        // Check all linked fragments exist and are verified
        mapping(uint256 => bool) seenFragments; // To prevent duplicate links
        for (uint256 i = 0; i < _linkedFragmentIds.length; i++) {
            uint256 fragId = _linkedFragmentIds[i];
            KnowledgeFragment storage fragment = knowledgeFragments[fragId];
            if (fragment.id == 0) revert SynergistProtocol__FragmentNotFound();
            if (fragment.status != FragmentStatus.Verified) revert SynergistProtocol__LinkedFragmentNotVerified();
            if (seenFragments[fragId]) revert SynergistProtocol__DuplicateLinkedFragment();
            seenFragments[fragId] = true;
        }

        _insightIdCounter++;
        uint256 newId = _insightIdCounter;

        SynergisticInsight storage newInsight = synergisticInsights[newId];
        newInsight.id = newId;
        newInsight.creator = msg.sender;
        newInsight.linkedFragmentIds = _linkedFragmentIds; // Store the array directly
        newInsight.insightContentHash = _insightContentHash;
        newInsight.metadataURI = _metadataURI;
        newInsight.validationAlgorithmId = _validationAlgorithmId;
        newInsight.status = InsightStatus.PendingVerification;
        newInsight.creationTimestamp = block.timestamp;
        newInsight.version = 1; // First version

        _updateReputation(msg.sender, RewardType.Processor, 20); // Base points for synthesis

        emit SynergisticInsightCreated(newId, msg.sender, 0, _validationAlgorithmId, _insightContentHash);
    }

    /// @notice Allows eligible users to attest to the validity, novelty, and coherence of a Synergistic Insight.
    /// @param _insightId The ID of the Synergistic Insight to attest.
    /// @param _isValid True if the insight is logically sound and derived correctly.
    /// @param _isNovel True if the insight presents genuinely new or unique synthesis.
    function attestSynergisticInsight(uint256 _insightId, bool _isValid, bool _isNovel) external whenNotPaused onlyEligibleAttester {
        SynergisticInsight storage insight = synergisticInsights[_insightId];
        if (insight.id == 0) revert SynergistProtocol__InsightNotFound();
        if (insight.creator == msg.sender) revert SynergistProtocol__SelfAttestationForbidden();
        if (insight.hasAttested[msg.sender]) revert SynergistProtocol__AlreadyAttested();
        if (insight.status != InsightStatus.PendingVerification) revert SynergistProtocol__InvalidProposalState();

        insight.hasAttested[msg.sender] = true;
        if (_isValid) {
            insight.positiveAttestations++;
            _updateReputation(msg.sender, RewardType.Verifier, 10);
        } else {
            insight.negativeAttestations++;
            _updateReputation(msg.sender, RewardType.Verifier, 4);
        }
        if (_isNovel) {
            insight.noveltyAttestations++;
            // Novelty is a bonus to the verifier, potentially to the creator later
        }

        // Auto-verify if enough positive attestations
        if (insight.positiveAttestations >= minPositiveAttestationsForVerificationSI) {
            insight.status = InsightStatus.Verified;
            // Reward the creator for the now verified insight
            _updateReputation(insight.creator, RewardType.Processor, 50); // Additional points for successful verification
            if (insight.noveltyAttestations > 0) { // Simple check for novelty bonus
                _updateReputation(insight.creator, RewardType.NoveltyBonus, insight.noveltyAttestations * 5); // Points based on novelty attestations
            }
            emit SynergisticInsightStatusUpdated(_insightId, InsightStatus.Verified);
        }

        emit SynergisticInsightAttested(_insightId, msg.sender, _isValid, _isNovel);
    }

    /// @notice Allows a Processor to create a new version of an existing Synergistic Insight, incorporating new fragments or refined processing.
    /// @param _parentInsightId The ID of the existing insight to evolve.
    /// @param _newLinkedFragmentIds An array of new or existing fragment IDs for the evolved insight.
    /// @param _newInsightContentHash A new content hash for the evolved insight.
    /// @param _newMetadataURI A new metadata URI for the evolved insight.
    /// @param _validationAlgorithmId The ID of the registered validation algorithm used for this evolution.
    function evolveSynergisticInsight(
        uint256 _parentInsightId,
        uint256[] calldata _newLinkedFragmentIds,
        bytes32 _newInsightContentHash,
        string calldata _newMetadataURI,
        uint256 _validationAlgorithmId
    ) external whenNotPaused onlyEligibleProcessor {
        SynergisticInsight storage parentInsight = synergisticInsights[_parentInsightId];
        if (parentInsight.id == 0) revert SynergistProtocol__InsightNotFound();
        if (parentInsight.status != InsightStatus.Verified && parentInsight.status != InsightStatus.Evolved) {
            revert SynergistProtocol__CannotEvolveUnverifiedInsight();
        }
        if (_newInsightContentHash == bytes32(0)) revert SynergistProtocol__InvalidContentHash();
        if (bytes(_newMetadataURI).length == 0) revert SynergistProtocol__MetadataURINotSet();
        if (validationAlgorithms[_validationAlgorithmId].id == 0 || !validationAlgorithms[_validationAlgorithmId].isActive) {
            revert SynergistProtocol__InvalidValidationAlgorithm();
        }

        mapping(uint256 => bool) seenFragments;
        for (uint256 i = 0; i < _newLinkedFragmentIds.length; i++) {
            uint256 fragId = _newLinkedFragmentIds[i];
            KnowledgeFragment storage fragment = knowledgeFragments[fragId];
            if (fragment.id == 0) revert SynergistProtocol__FragmentNotFound();
            if (fragment.status != FragmentStatus.Verified) revert SynergistProtocol__LinkedFragmentNotVerified();
            if (seenFragments[fragId]) revert SynergistProtocol__DuplicateLinkedFragment();
            seenFragments[fragId] = true;
        }

        _insightIdCounter++;
        uint256 newId = _insightIdCounter;

        SynergisticInsight storage newInsight = synergisticInsights[newId];
        newInsight.id = newId;
        newInsight.creator = msg.sender;
        newInsight.linkedFragmentIds = _newLinkedFragmentIds;
        newInsight.insightContentHash = _newInsightContentHash;
        newInsight.metadataURI = _newMetadataURI;
        newInsight.validationAlgorithmId = _validationAlgorithmId;
        newInsight.status = InsightStatus.PendingVerification;
        newInsight.creationTimestamp = block.timestamp;
        newInsight.version = parentInsight.version + 1; // Increment version number
        newInsight.parentInsightId = _parentInsightId;

        parentInsight.status = InsightStatus.Evolved; // Mark parent as evolved

        _updateReputation(msg.sender, RewardType.Processor, 30); // Higher points for evolution

        emit SynergisticInsightCreated(newId, msg.sender, _parentInsightId, _validationAlgorithmId, _newInsightContentHash);
    }

    /// @notice Allows any user to flag a Knowledge Fragment or Synergistic Insight for review.
    /// @param _entityId The ID of the entity (fragment or insight) to flag.
    /// @param _entityType The type of entity (KnowledgeFragment or SynergisticInsight).
    /// @param _reason A string explaining the reason for flagging.
    function flagContent(uint256 _entityId, EntityType _entityType, string calldata _reason) external whenNotPaused {
        if (bytes(_reason).length == 0) revert SynergistProtocol__InvalidEntityForDispute(); // Simplified check

        // This action triggers a dispute. A small stake might be required for initiating.
        // For simplicity, we directly call initiateDispute here.
        initiateDispute(_entityId, _entityType, _reason); // This will handle the actual dispute creation
        emit ContentFlagged(_entityId, _entityType, msg.sender, _reason);
    }

    /// @notice Allows a user to propose a new classification category for Knowledge Fragments.
    /// @param _categoryName The name of the proposed category.
    /// @param _description A description of the proposed category.
    function proposeNewCategory(string calldata _categoryName, string calldata _description) external whenNotPaused onlyEligibleProposer {
        _proposalIdCounter++;
        uint256 newProposalId = _proposalIdCounter;

        CategoryProposal storage proposal = categoryProposals[newProposalId];
        proposal.id = newProposalId;
        proposal.proposer = msg.sender;
        proposal.categoryName = _categoryName;
        proposal.description = _description;
        proposal.votingDeadline = block.timestamp + proposalVotingPeriod;
        proposal.state = ProposalState.Active;
        // Calculate required votes based on total governance reputation (simplification: fixed number for now)
        proposal.requiredVotes = 1000; // Example: 1000 points of governance reputation needed

        emit NewCategoryProposed(newProposalId, _categoryName);
    }

    /// @notice Casts a vote on a new category proposal.
    /// @param _proposalId The ID of the category proposal to vote on.
    /// @param _approve True to approve the category, false to reject.
    function voteOnNewCategoryProposal(uint256 _proposalId, bool _approve) external whenNotPaused {
        CategoryProposal storage proposal = categoryProposals[_proposalId];
        if (proposal.id == 0 || proposal.state != ProposalState.Active) revert SynergistProtocol__InvalidProposalState();
        if (proposal.votingDeadline < block.timestamp) revert SynergistProtocol__ProposalVotingPeriodNotEnded();
        if (proposal.hasVoted[msg.sender]) revert SynergistProtocol__AlreadyVoted();

        uint256 voterRep = reputationProfiles[msg.sender].governanceScore + reputationProfiles[msg.sender].delegatedFrom[msg.sender];
        if (voterRep == 0) revert SynergistProtocol__InsufficientReputation(); // Must have some governance reputation

        proposal.hasVoted[msg.sender] = true;
        if (_approve) {
            proposal.voteCount += voterRep;
        } else {
            // Optional: Negative votes could count against
        }

        // Check if proposal succeeded instantly if quorum is met before deadline (optional)
        if (proposal.voteCount >= proposal.requiredVotes) {
            proposal.state = ProposalState.Succeeded;
        }
        emit ProposalVoted(_proposalId, msg.sender, _approve);
    }

    // --- II. Reputation & Stake Management (4 Functions) ---

    /// @notice Allows a user to delegate a portion of their reputation score to another user.
    /// @param _delegatee The address of the user to delegate reputation to.
    /// @param _amount The amount of reputation to delegate.
    function delegateReputation(address _delegatee, uint256 _amount) external whenNotPaused {
        if (_delegatee == address(0)) revert SynergistProtocol__InvalidProposalState(); // Re-use error for brevity
        if (_delegatee == msg.sender) revert SynergistProtocol__SelfAttestationForbidden(); // Re-use error
        if (_amount == 0) revert SynergistProtocol__InvalidProposalState(); // Re-use error

        ReputationProfile storage delegatorProfile = reputationProfiles[msg.sender];
        if (delegatorProfile.totalReputation < _amount) revert SynergistProtocol__DelegationAmountExceedsAvailable();

        delegatorProfile.delegatedTo[_delegatee] += _amount;
        delegatorProfile.governanceScore -= _amount; // Reduce own governance power
        reputationProfiles[_delegatee].delegatedFrom[msg.sender] += _amount;
        reputationProfiles[_delegatee].governanceScore += _amount; // Increase delegatee's governance power

        emit ReputationDelegated(msg.sender, _delegatee, _amount);
        emit ReputationUpdated(msg.sender, delegatorProfile.totalReputation, delegatorProfile.contributionScore, delegatorProfile.processingScore, delegatorProfile.verificationScore, delegatorProfile.governanceScore);
        emit ReputationUpdated(_delegatee, reputationProfiles[_delegatee].totalReputation, reputationProfiles[_delegatee].contributionScore, reputationProfiles[_delegatee].processingScore, reputationProfiles[_delegatee].verificationScore, reputationProfiles[_delegatee].governanceScore);
    }

    /// @notice Recalls previously delegated reputation.
    /// @param _delegatee The address from whom to undelegate reputation.
    /// @param _amount The amount of reputation to undelegate.
    function undelegateReputation(address _delegatee, uint256 _amount) external whenNotPaused {
        if (_delegatee == address(0)) revert SynergistProtocol__InvalidProposalState();
        if (_amount == 0) revert SynergistProtocol__InvalidProposalState();

        ReputationProfile storage delegatorProfile = reputationProfiles[msg.sender];
        if (delegatorProfile.delegatedTo[_delegatee] < _amount) revert SynergistProtocol__CannotUndelegateMoreThanDelegated();

        delegatorProfile.delegatedTo[_delegatee] -= _amount;
        delegatorProfile.governanceScore += _amount; // Restore own governance power
        reputationProfiles[_delegatee].delegatedFrom[msg.sender] -= _amount;
        reputationProfiles[_delegatee].governanceScore -= _amount; // Decrease delegatee's governance power

        emit ReputationUndelegated(msg.sender, _delegatee, _amount);
        emit ReputationUpdated(msg.sender, delegatorProfile.totalReputation, delegatorProfile.contributionScore, delegatorProfile.processingScore, delegatorProfile.verificationScore, delegatorProfile.governanceScore);
        emit ReputationUpdated(_delegatee, reputationProfiles[_delegatee].totalReputation, reputationProfiles[_delegatee].contributionScore, reputationProfiles[_delegatee].processingScore, reputationProfiles[_delegatee].verificationScore, reputationProfiles[_delegatee].governanceScore);
    }

    /// @notice Allows users to claim their accrued reputation-based rewards.
    function claimReputationReward() external whenNotPaused {
        uint256 claimableAmount = _calculateClaimableRewards(msg.sender);
        if (claimableAmount == 0) revert SynergistProtocol__NoRewardsToClaim();

        // For simplicity, totalReputation acts as "points" and is cleared upon claiming.
        // In a real system, you'd convert these points to a fixed amount of reward token or use a pool.
        // Let's assume 1 reputation point = 1 unit of reward token for this example.
        uint256 rewardAmount = claimableAmount;

        if (rewardToken.balanceOf(address(this)) < rewardAmount) revert SynergistProtocol__RewardPoolEmpty();

        reputationProfiles[msg.sender].totalReputation = 0; // Reset claimed reputation points
        reputationProfiles[msg.sender].lastRewardClaimTimestamp = block.timestamp;
        
        // This is where the actual token transfer happens
        rewardToken.transfer(msg.sender, rewardAmount);

        emit RewardClaimed(msg.sender, rewardAmount);
    }

    /// @notice Retrieves the detailed reputation profile of a given user.
    /// @param _user The address of the user.
    /// @return A ReputationProfile struct containing various scores and delegation info.
    function getReputationProfile(address _user) external view returns (ReputationProfile memory) {
        return reputationProfiles[_user];
    }

    // --- III. Algorithmic Validation & Registry (3 Functions) ---

    /// @notice Allows trusted entities (or governance-approved entities) to register a new "algorithmic validation method".
    /// @param _name The name of the algorithm (e.g., "ZK-Proof Verification for ML Model").
    /// @param _description A detailed description of what the algorithm does.
    /// @param _verifierContractAddress An optional address of an on-chain contract that helps with verification.
    /// @param _verificationMethodURI URI pointing to detailed off-chain verification instructions/spec.
    function registerValidationAlgorithm(
        string calldata _name,
        string calldata _description,
        string calldata _verifierContractAddress,
        string calldata _verificationMethodURI
    ) external whenNotPaused onlyOwner { // Can be changed to governance-controlled later
        // Simple check to prevent basic duplicates
        for (uint256 i = 1; i <= _algorithmIdCounter; i++) {
            if (keccak256(abi.encodePacked(validationAlgorithms[i].name)) == keccak256(abi.encodePacked(_name))) {
                revert SynergistProtocol__ValidationAlgorithmAlreadyRegistered();
            }
        }

        _algorithmIdCounter++;
        uint256 newAlgorithmId = _algorithmIdCounter;

        validationAlgorithms[newAlgorithmId] = ValidationAlgorithm(
            newAlgorithmId,
            _name,
            _description,
            address(this), // Placeholder, should be _verifierContractAddress
            _verificationMethodURI,
            true // isActive by default
        );

        emit ValidationAlgorithmRegistered(newAlgorithmId, _name, address(this)); // Placeholder address
    }

    /// @notice Removes an algorithm from the registry (via governance).
    /// @param _algorithmId The ID of the algorithm to deregister.
    function deregisterValidationAlgorithm(uint256 _algorithmId) external whenNotPaused onlyOwner { // Should be governance
        if (validationAlgorithms[_algorithmId].id == 0) revert SynergistProtocol__InvalidValidationAlgorithm();
        validationAlgorithms[_algorithmId].isActive = false;
        emit ValidationAlgorithmDeregistered(_algorithmId);
    }

    /// @notice Retrieves details about a registered validation algorithm.
    /// @param _algorithmId The ID of the algorithm.
    /// @return A ValidationAlgorithm struct.
    function getValidationAlgorithm(uint256 _algorithmId) external view returns (ValidationAlgorithm memory) {
        if (validationAlgorithms[_algorithmId].id == 0) revert SynergistProtocol__InvalidValidationAlgorithm();
        return validationAlgorithms[_algorithmId];
    }

    // --- IV. Decentralized Governance & Parameter Control (5 Functions) ---

    /// @notice Initiates a governance proposal to change a key protocol parameter.
    /// @param _parameterName The name of the parameter to change (e.g., "minReputationForAttestation").
    /// @param _newValue The new value for the parameter.
    function proposeProtocolParameterChange(string calldata _parameterName, uint256 _newValue) external whenNotPaused onlyEligibleProposer {
        _proposalIdCounter++;
        uint256 newProposalId = _proposalIdCounter;

        ParameterProposal storage proposal = parameterProposals[newProposalId];
        proposal.id = newProposalId;
        proposal.proposer = msg.sender;
        proposal.parameterName = _parameterName;
        proposal.newValue = _newValue;
        proposal.votingDeadline = block.timestamp + proposalVotingPeriod;
        proposal.state = ProposalState.Active;
        // Calculate required votes based on total governance reputation (simplified for example)
        proposal.requiredVotes = 1000; // Example fixed required votes

        emit ParameterChangeProposed(newProposalId, _parameterName, _newValue, msg.sender);
    }

    /// @notice Allows users with governance reputation to vote on active proposals.
    /// @param _proposalId The ID of the proposal to vote on.
    /// @param _approve True to approve the proposal, false to reject.
    function voteOnProposal(uint256 _proposalId, bool _approve) external whenNotPaused {
        ParameterProposal storage proposal = parameterProposals[_proposalId];
        if (proposal.id == 0 || proposal.state != ProposalState.Active) revert SynergistProtocol__InvalidProposalState();
        if (proposal.votingDeadline < block.timestamp) revert SynergistProtocol__ProposalVotingPeriodNotEnded();
        if (proposal.hasVoted[msg.sender]) revert SynergistProtocol__AlreadyVoted();

        uint256 voterRep = reputationProfiles[msg.sender].governanceScore + reputationProfiles[msg.sender].delegatedFrom[msg.sender];
        if (voterRep == 0) revert SynergistProtocol__InsufficientReputation();

        proposal.hasVoted[msg.sender] = true;
        if (_approve) {
            proposal.voteCount += voterRep;
        } else {
            // Negative votes could be implemented here
        }

        // Check for immediate success (optional)
        if (proposal.voteCount >= proposal.requiredVotes) {
            proposal.state = ProposalState.Succeeded;
        }

        emit ProposalVoted(_proposalId, msg.sender, _approve);
    }

    /// @notice Executes an approved and quorum-reached proposal, updating protocol parameters.
    /// @param _proposalId The ID of the proposal to execute.
    function executeProposal(uint256 _proposalId) external whenNotPaused {
        ParameterProposal storage proposal = parameterProposals[_proposalId];
        if (proposal.id == 0) revert SynergistProtocol__InvalidProposalState();
        if (proposal.state != ProposalState.Succeeded) {
            // Recalculate if voting period is over but state hasn't updated
            if (proposal.votingDeadline < block.timestamp && proposal.voteCount >= proposal.requiredVotes) {
                proposal.state = ProposalState.Succeeded;
            } else {
                revert SynergistProtocol__ProposalNotApproved();
            }
        }
        if (proposal.state == ProposalState.Executed) revert SynergistProtocol__InvalidProposalState();

        // Apply parameter change
        if (keccak256(abi.encodePacked(proposal.parameterName)) == keccak256(abi.encodePacked("minReputationForAttestation"))) {
            minReputationForAttestation = proposal.newValue;
        } else if (keccak256(abi.encodePacked(proposal.parameterName)) == keccak256(abi.encodePacked("minReputationForProcessing"))) {
            minReputationForProcessing = proposal.newValue;
        } else if (keccak256(abi.encodePacked(proposal.parameterName)) == keccak256(abi.encodePacked("minReputationForProposing"))) {
            minReputationForProposing = proposal.newValue;
        } else if (keccak256(abi.encodePacked(proposal.parameterName)) == keccak256(abi.encodePacked("minReputationForArbitration"))) {
            minReputationForArbitration = proposal.newValue;
        } else if (keccak256(abi.encodePacked(proposal.parameterName)) == keccak256(abi.encodePacked("proposalVotingPeriod"))) {
            proposalVotingPeriod = proposal.newValue;
        } else if (keccak256(abi.encodePacked(proposal.parameterName)) == keccak256(abi.encodePacked("proposalQuorumPercentage"))) {
            proposalQuorumPercentage = proposal.newValue;
        } else if (keccak256(abi.encodePacked(proposal.parameterName)) == keccak256(abi.encodePacked("disputeInitiationStake"))) {
            disputeInitiationStake = proposal.newValue;
        } else if (keccak256(abi.encodePacked(proposal.parameterName)) == keccak256(abi.encodePacked("minPositiveAttestationsForVerificationKF"))) {
            minPositiveAttestationsForVerificationKF = proposal.newValue;
        } else if (keccak256(abi.encodePacked(proposal.parameterName)) == keccak256(abi.encodePacked("minPositiveAttestationsForVerificationSI"))) {
            minPositiveAttestationsForVerificationSI = proposal.newValue;
        }
        // ... more parameters as needed

        // Handle category proposals execution
        if (proposal.id == categoryProposals[_proposalId].id && categoryProposals[_proposalId].state == ProposalState.Succeeded) {
             CategoryProposal storage catProposal = categoryProposals[_proposalId];
             _categoryIdCounter++;
             uint256 newCatId = _categoryIdCounter;
             categories[newCatId] = KnowledgeCategory(newCatId, catProposal.categoryName, catProposal.description, true);
             catProposal.newCategoryId = newCatId;
             catProposal.state = ProposalState.Executed;
             emit NewCategoryAdded(newCatId, catProposal.categoryName);
        }

        proposal.state = ProposalState.Executed;
        emit ProposalExecuted(_proposalId);
    }

    /// @notice Allows governance to adjust multipliers for different reward types.
    /// @param _type The type of reward to adjust (enum RewardType).
    /// @param _newMultiplier The new multiplier value (e.g., 100 for 1x, 200 for 2x).
    function updateRewardMultiplier(RewardType _type, uint256 _newMultiplier) external whenNotPaused onlyOwner { // Should be called by executeProposal
        if (_newMultiplier == 0) revert SynergistProtocol__InvalidRewardType(); // For simplicity
        rewardMultipliers[_type] = _newMultiplier;
        // Event for multiplier update (implicitly part of ProposalExecuted event usually)
    }

    /// @notice Allows governance to allocate funds from the protocol's treasury.
    /// @param _recipient The address to send funds to.
    /// @param _amount The amount of reward token to send.
    function allocateTreasuryFunds(address _recipient, uint256 _amount) external whenNotPaused onlyOwner { // Should be called by executeProposal after voting
        if (_amount == 0) revert SynergistProtocol__RewardPoolEmpty();
        if (rewardToken.balanceOf(address(this)) < _amount) revert SynergistProtocol__RewardPoolEmpty();
        rewardToken.transfer(_recipient, _amount);
        // Event for treasury allocation (implicitly part of ProposalExecuted event usually)
    }


    // --- V. Dynamic Dispute Resolution & Arbitration (3 Functions) ---

    /// @notice Formally initiates a dispute process for a flagged Knowledge Fragment or Synergistic Insight.
    /// @param _entityId The ID of the entity (fragment or insight) under dispute.
    /// @param _entityType The type of entity (KnowledgeFragment or SynergisticInsight).
    /// @param _reason A string explaining the reason for the dispute.
    function initiateDispute(uint256 _entityId, EntityType _entityType, string calldata _reason) public whenNotPaused { // Made public for flagContent to call
        if (rewardToken.balanceOf(msg.sender) < disputeInitiationStake) revert SynergistProtocol__InsufficientReputation(); // Using token balance as stake
        
        address subjectAddress;
        if (_entityType == EntityType.KnowledgeFragment) {
            KnowledgeFragment storage fragment = knowledgeFragments[_entityId];
            if (fragment.id == 0) revert SynergistProtocol__FragmentNotFound();
            fragment.status = FragmentStatus.Disputed;
            subjectAddress = fragment.contributor;
            emit KnowledgeFragmentStatusUpdated(_entityId, FragmentStatus.Disputed);
        } else if (_entityType == EntityType.SynergisticInsight) {
            SynergisticInsight storage insight = synergisticInsights[_entityId];
            if (insight.id == 0) revert SynergistProtocol__InsightNotFound();
            insight.status = InsightStatus.Disputed;
            subjectAddress = insight.creator;
            emit SynergisticInsightStatusUpdated(_entityId, InsightStatus.Disputed);
        } else {
            revert SynergistProtocol__InvalidEntityForDispute();
        }

        _disputeIdCounter++;
        uint256 newDisputeId = _disputeIdCounter;

        Dispute storage newDispute = disputes[newDisputeId];
        newDispute.id = newDisputeId;
        newDispute.entityId = _entityId;
        newDispute.entityType = _entityType;
        newDispute.initiator = msg.sender;
        newDispute.subjectAddress = subjectAddress;
        newDispute.reason = _reason;
        newDispute.state = DisputeState.Open;
        newDispute.initiationTimestamp = block.timestamp;
        newDispute.stakeAmount = disputeInitiationStake;

        // Transfer stake to contract
        rewardToken.transferFrom(msg.sender, address(this), disputeInitiationStake);

        emit DisputeInitiated(newDisputeId, _entityId, _entityType, msg.sender);
    }

    /// @notice Allows parties involved in a dispute to submit evidence.
    /// @param _disputeId The ID of the dispute.
    /// @param _evidenceURI IPFS or similar URI pointing to the evidence.
    function submitDisputeEvidence(uint256 _disputeId, string calldata _evidenceURI) external whenNotPaused {
        Dispute storage dispute = disputes[_disputeId];
        if (dispute.id == 0) revert SynergistProtocol__DisputeNotFound();
        if (dispute.state != DisputeState.Open && dispute.state != DisputeState.EvidenceSubmission) revert SynergistProtocol__InvalidProposalState(); // Re-use for state
        if (dispute.initiator != msg.sender && dispute.subjectAddress != msg.sender) revert SynergistProtocol__NotDisputeParticipant();
        
        dispute.evidenceURI = _evidenceURI; // Overwrites previous evidence (can be expanded to allow multiple)
        dispute.state = DisputeState.EvidenceSubmission; // Advance state

        emit DisputeEvidenceSubmitted(_disputeId, msg.sender, _evidenceURI);
    }

    /// @notice An appointed (or randomly selected, or reputation-weighted voted) arbitrator resolves the dispute.
    /// @param _disputeId The ID of the dispute to resolve.
    /// @param _resolution The resolution (Valid, Invalid, Undecided).
    function resolveDispute(uint256 _disputeId, DisputeResolution _resolution) external whenNotPaused {
        // This function would typically be called by a designated arbitrator or a multi-sig result.
        // For simplicity, let's assume `msg.sender` must have enough arbitration reputation.
        if (reputationProfiles[msg.sender].governanceScore < minReputationForArbitration) { // Using governance score as arb. score
             revert SynergistProtocol__InsufficientReputation();
        }

        Dispute storage dispute = disputes[_disputeId];
        if (dispute.id == 0) revert SynergistProtocol__DisputeNotFound();
        if (dispute.state == DisputeState.Resolved) revert SynergistProtocol__DisputeAlreadyResolved();

        dispute.resolution = _resolution;
        dispute.state = DisputeState.Resolved;
        dispute.resolutionTimestamp = block.timestamp;
        dispute.currentArbitrator = msg.sender;

        // Apply consequences based on resolution
        if (_resolution == DisputeResolution.Valid) {
            // Initiator was correct: Subject loses reputation, initiator gains reputation, initiator stake returned + reward
            _updateReputation(dispute.subjectAddress, RewardType.Contributor, 0); // Placeholder for negative reputation
            _updateReputation(dispute.initiator, RewardType.GovernanceBonus, 50); // Reward for successful dispute
            rewardToken.transfer(dispute.initiator, dispute.stakeAmount * 2); // Return stake + reward (simplified)

            if (dispute.entityType == EntityType.KnowledgeFragment) {
                knowledgeFragments[dispute.entityId].status = FragmentStatus.Rejected;
                emit KnowledgeFragmentStatusUpdated(dispute.entityId, FragmentStatus.Rejected);
            } else if (dispute.entityType == EntityType.SynergisticInsight) {
                synergisticInsights[dispute.entityId].status = InsightStatus.Rejected;
                emit SynergisticInsightStatusUpdated(dispute.entityId, InsightStatus.Rejected);
            }

        } else if (_resolution == DisputeResolution.Invalid) {
            // Initiator was incorrect: Initiator loses stake, subject gains reputation (or penalty removed)
            _updateReputation(dispute.initiator, RewardType.Contributor, 0); // Placeholder for negative reputation
            // Dispute stake could be burned or go to treasury/arbitrator
            rewardToken.transfer(owner(), dispute.stakeAmount); // Send to owner/treasury (simplified)

        } else { // Undecided or other cases
            // Stakes might be returned or split
            rewardToken.transfer(dispute.initiator, dispute.stakeAmount); // Return stake
        }

        _updateReputation(msg.sender, RewardType.GovernanceBonus, 20); // Reward arbitrator for participation

        emit DisputeResolved(_disputeId, _resolution, msg.sender);
    }

    // --- VI. Read-Only Queries & Utilities (2 Functions) ---

    /// @notice Retrieves all on-chain details of a specific Knowledge Fragment.
    /// @param _fragmentId The ID of the Knowledge Fragment.
    /// @return A KnowledgeFragment struct.
    function getKnowledgeFragmentDetails(uint256 _fragmentId) external view returns (KnowledgeFragment memory) {
        if (knowledgeFragments[_fragmentId].id == 0) revert SynergistProtocol__FragmentNotFound();
        return knowledgeFragments[_fragmentId];
    }

    /// @notice Retrieves all on-chain details of a specific Synergistic Insight.
    /// @param _insightId The ID of the Synergistic Insight.
    /// @return A SynergisticInsight struct.
    function getSynergisticInsightDetails(uint256 _insightId) external view returns (SynergisticInsight memory) {
        if (synergisticInsights[_insightId].id == 0) revert SynergistProtocol__InsightNotFound();
        return synergisticInsights[_insightId];
    }

    // --- Additional Owner/Admin Functions (inheriting from Ownable/Pausable) ---

    /// @notice Pauses the contract for emergency situations.
    function pause() external onlyOwner {
        _pause();
    }

    /// @notice Unpauses the contract.
    function unpause() external onlyOwner {
        _unpause();
    }

    /// @notice Allows the owner to fund the reward token pool.
    /// @param _amount The amount of reward tokens to add.
    function fundRewardPool(uint256 _amount) external onlyOwner {
        rewardToken.transferFrom(msg.sender, address(this), _amount);
    }

    /// @notice Get a specific protocol parameter value.
    /// @param _parameterName The name of the parameter.
    /// @return The current value of the parameter.
    function getProtocolParameter(string calldata _parameterName) external view returns (uint256) {
        if (keccak256(abi.encodePacked(_parameterName)) == keccak256(abi.encodePacked("minReputationForAttestation"))) {
            return minReputationForAttestation;
        } else if (keccak256(abi.encodePacked(_parameterName)) == keccak256(abi.encodePacked("minReputationForProcessing"))) {
            return minReputationForProcessing;
        } else if (keccak256(abi.encodePacked(_parameterName)) == keccak256(abi.encodePacked("minReputationForProposing"))) {
            return minReputationForProposing;
        } else if (keccak256(abi.encodePacked(_parameterName)) == keccak256(abi.encodePacked("minReputationForArbitration"))) {
            return minReputationForArbitration;
        } else if (keccak256(abi.encodePacked(_parameterName)) == keccak256(abi.encodePacked("proposalVotingPeriod"))) {
            return proposalVotingPeriod;
        } else if (keccak256(abi.encodePacked(_parameterName)) == keccak256(abi.encodePacked("proposalQuorumPercentage"))) {
            return proposalQuorumPercentage;
        } else if (keccak256(abi.encodePacked(_parameterName)) == keccak256(abi.encodePacked("disputeInitiationStake"))) {
            return disputeInitiationStake;
        } else if (keccak256(abi.encodePacked(_parameterName)) == keccak256(abi.encodePacked("minPositiveAttestationsForVerificationKF"))) {
            return minPositiveAttestationsForVerificationKF;
        } else if (keccak256(abi.encodePacked(_parameterName)) == keccak256(abi.encodePacked("minPositiveAttestationsForVerificationSI"))) {
            return minPositiveAttestationsForVerificationSI;
        }
        // Return 0 if not found, or revert
        revert();
    }
}
```