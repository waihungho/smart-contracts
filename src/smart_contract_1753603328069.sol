The `AgoraChronicle` smart contract envisions a **Decentralized Knowledge & Attestation Network (DKAN)**. This platform empowers users to contribute valuable knowledge artifacts (e.g., research, verifiable claims, art) and for a community to collectively attest to their attributes, quality, and veracity. It integrates several advanced concepts:

1.  **Flexible Attestations:** Beyond simple likes/dislikes, users can provide nuanced attestations on specific attributes (e.g., "originality," "scientific rigor") with both qualitative descriptions and quantitative scores.
2.  **Multi-Dimensional Reputation System:** Users build a dynamic reputation not just as content creators but also as credible attestors. Reputation is influenced by the quality and consensus on their attestations, with penalties for disputed or revoked claims. Domain-specific expertise scores are also tracked.
3.  **Soulbound-like Expertise Badges:** Non-transferable "Expertise Badges" can be minted to users who consistently demonstrate high-quality contributions and attestations within specific knowledge domains, acting as on-chain proofs of skill or achievement.
4.  **Dynamic Knowledge Tiering:** Knowledge artifacts dynamically move through quality tiers based on the aggregate score and volume of attestations they receive, making it easier to discover high-value content.
5.  **Decentralized Grant Funding:** A built-in mechanism allows the community to propose and vote on grants to fund high-impact knowledge artifacts or research initiatives, with a transparent voting process and proposer staking.

While individual components (like `Ownable` or basic mapping usage) are common, the **unique combination and interplay** of these features within a single contract, designed for a community-driven knowledge ecosystem, sets it apart from typical open-source projects.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

// Outline
// I. Core Knowledge Artifact Management
// II. Attestation & Validation
// III. Reputation & Expertise Badges
// IV. Knowledge Tiering & Curation
// V. Decentralized Funding & Grants
// VI. System Configuration & Governance

// Function Summary

// I. Core Knowledge Artifact Management
// 1. submitKnowledgeArtifact(string _ipfsHash, string _title, string _description, string[] _tags)
//    - Allows users to submit a new knowledge artifact, providing its IPFS hash (for off-chain content), title, description, and relevant tags.
//    - Emits a KnowledgeArtifactSubmitted event upon successful submission.
// 2. getKnowledgeArtifact(uint256 _artifactId)
//    - Retrieves the comprehensive details of a specific knowledge artifact by its unique ID.
// 3. updateKnowledgeArtifactMetadata(uint256 _artifactId, string _newTitle, string _newDescription, string[] _newTags)
//    - Enables the original submitter to update the non-content metadata (title, description, tags) of their artifact.
//    - Emits a KnowledgeArtifactUpdated event after the update.
// 4. archiveKnowledgeArtifact(uint256 _artifactId)
//    - Allows the original submitter to mark their artifact as archived, making it inactive for new attestations or grant proposals.
//    - Emits a KnowledgeArtifactArchived event.

// II. Attestation & Validation
// 5. attestToKnowledgeArtifact(uint256 _artifactId, string _attributeKey, string _attributeValue, int256 _score, string _commentIpfsHash)
//    - Enables users to provide a qualitative and quantitative attestation for a specific attribute (e.g., "accuracy", "originality") of a knowledge artifact.
//    - Automatically updates the attester's overall reputation and domain-specific expertise scores.
//    - Emits an AttestationSubmitted event.
// 6. getAttestation(uint256 _attestationId)
//    - Retrieves the full details of a specific attestation by its unique ID.
// 7. getAttestationsForArtifact(uint256 _artifactId)
//    - Returns an array of all attestation IDs associated with a given knowledge artifact, allowing for easy lookup of its validation history.
// 8. getAttestationsByAttester(address _attester)
//    - Returns an array of all attestation IDs made by a specific attester address, showcasing their contribution history.
// 9. revokeAttestation(uint256 _attestationId)
//    - Allows an attester to revoke their previously submitted attestation, which incurs a reputation penalty, enabling self-correction.
//    - Emits an AttestationRevoked event.
// 10. disputeAttestation(uint256 _attestationId, string _reasonIpfsHash)
//     - Initiates a formal dispute process against an existing attestation, requiring a detailed reason provided via IPFS.
//     - Emits an AttestationDisputed event.
// 11. resolveAttestationDispute(uint256 _disputeId, bool _isAttestationValid)
//     - (Admin/DAO controlled) Resolves an active attestation dispute. This function adjusts the reputations of both the attester and the disputer based on the dispute's outcome, and invalidates the attestation if found invalid.
//     - Emits a DisputeResolved event.

// III. Reputation & Expertise Badges
// 12. getAttesterReputation(address _attester)
//     - Retrieves the overall numerical reputation score of an attester, reflecting their general trustworthiness and contribution quality.
// 13. getAttesterDomainExpertise(address _attester, string _tag)
//     - Retrieves the numerical expertise score of an attester within a specific knowledge domain or tag, indicating their specialized knowledge.
// 14. mintExpertiseBadge(address _recipient, string _domainTag, uint256 _badgeLevel)
//     - (Admin/System controlled) Mints a non-transferable (soulbound-like) expertise badge for a user, signifying their proven proficiency in a given domain at a specific level.
//     - Emits an ExpertiseBadgeMinted event.
// 15. getExpertiseBadges(address _owner)
//     - Retrieves a list of all domain tags and their corresponding badge levels held by a specific address, acting as on-chain credentials.

// IV. Knowledge Tiering & Curation
// 16. calculateKnowledgeArtifactTier(uint256 _artifactId)
//     - Dynamically computes and returns the current "tier" of a knowledge artifact, derived from the aggregated quality and quantity of its attestations. Higher tiers indicate higher community consensus on quality.
// 17. getTopRatedKnowledgeArtifactsByTag(string _tag, uint256 _limit)
//     - Retrieves a limited array of knowledge artifact IDs that are considered top-rated within a specific tag, based on their aggregated attestation scores. (Note: For large datasets, this might be gas-intensive and typically handled by off-chain indexers in production for efficiency.)
// 18. getExpertAttestersForTag(string _tag, uint256 _limit)
//     - Retrieves a limited array of attester addresses identified as experts in a particular knowledge domain/tag, based on their domain expertise scores. (Note: Similar gas considerations as above; often relies on off-chain indexing for scale.)

// V. Decentralized Funding & Grants
// 19. proposeGrantForArtifact(uint256 _artifactId, string _proposalIpfsHash)
//     - Allows any user to propose a grant in native currency for a specific knowledge artifact, detailing the proposal via IPFS.
//     - Requires an initial stake from the proposer, demonstrating commitment.
//     - Emits a GrantProposalSubmitted event.
// 20. voteOnGrantProposal(uint256 _proposalId, bool _support)
//     - Allows eligible voters (based on future complex logic or current simplified "any user") to cast their vote on an active grant proposal.
//     - Emits a GrantVoteCast event.
// 21. executeGrant(uint256 _proposalId)
//     - Executes a successful grant proposal. This function transfers the proposed funds (which must be sent to the contract prior to or with this call) to the original submitter of the artifact and refunds the proposer's stake.
//     - Emits a GrantExecuted event.

// VI. System Configuration & Governance
// 22. setReputationModifier(string _modifierKey, int256 _value)
//     - (Admin) Allows the contract owner to configure or adjust the reputation impact (positive or negative) for various predefined actions within the system (e.g., successful attestation, dispute loss).
// 23. setMinAttestationScoreForTier(uint256 _tier, int256 _minScore)
//     - (Admin) Configures the minimum aggregated attestation score required for a knowledge artifact to achieve a specific quality tier level.
// 24. pauseContract()
//     - (Admin) Inherited from OpenZeppelin's Pausable. Pauses most user-facing functionalities of the contract, useful for emergencies or upgrades.
// 25. unpauseContract()
//     - (Admin) Inherited from OpenZeppelin's Pausable. Unpauses the contract, restoring full functionality after a pause.

contract AgoraChronicle is Ownable, Pausable {
    using Counters for Counters.Counter;
    using Strings for uint256;

    // --- Events ---
    event KnowledgeArtifactSubmitted(uint256 indexed artifactId, address indexed submitter, string title, string[] tags);
    event KnowledgeArtifactUpdated(uint256 indexed artifactId, address indexed updater, string newTitle, string[] newTags);
    event KnowledgeArtifactArchived(uint256 indexed artifactId, address indexed archiver);
    event AttestationSubmitted(uint256 indexed attestationId, uint256 indexed artifactId, address indexed attester, string attributeKey, int256 score);
    event AttestationRevoked(uint256 indexed attestationId, address indexed revoker);
    event AttestationDisputed(uint256 indexed attestationId, uint256 indexed disputeId, address indexed disputer);
    event DisputeResolved(uint256 indexed disputeId, uint256 indexed attestationId, bool isAttestationValid);
    event ReputationUpdated(address indexed account, int256 newReputation);
    event DomainExpertiseUpdated(address indexed account, string indexed tag, int256 newScore);
    event ExpertiseBadgeMinted(address indexed recipient, string indexed domainTag, uint256 badgeLevel);
    event GrantProposalSubmitted(uint256 indexed proposalId, uint256 indexed artifactId, address indexed proposer, uint256 amount);
    event GrantVoteCast(uint256 indexed proposalId, address indexed voter, bool support);
    event GrantExecuted(uint256 indexed proposalId, uint256 indexed artifactId, address indexed recipient, uint256 amount);

    // --- Structs ---

    struct KnowledgeArtifact {
        uint256 id;
        address submitter;
        string ipfsHash; // IPFS hash of the actual content (e.g., PDF, image, code)
        string title;
        string description;
        string[] tags;
        uint256 submittedAt;
        bool isActive; // true unless archived by submitter or invalidated by system
        int256 totalAttestationScore; // Aggregate score from all valid attestations
        uint256 attestationCount; // Number of valid attestations
    }

    struct Attestation {
        uint256 id;
        uint256 artifactId;
        address attester;
        string attributeKey; // e.g., "originality", "relevance", "accuracy", "completeness"
        string attributeValue; // e.g., "high", "medium", "low", "true", "false", "verified"
        int256 score; // Quantitative score, e.g., -100 to 100 for a particular attribute
        string commentIpfsHash; // IPFS hash of a detailed comment or rationale for the attestation
        uint256 attestedAt;
        bool isRevoked; // Set to true if attestation is revoked by attester or invalidated by dispute
    }

    struct Dispute {
        uint256 id;
        uint256 attestationId;
        address disputer;
        string reasonIpfsHash; // IPFS hash of the detailed reason for the dispute
        uint256 initiatedAt;
        bool resolved;
        bool attestationValidOutcome; // True if original attestation was deemed valid, false if invalid
    }

    struct GrantProposal {
        uint256 id;
        uint256 artifactId;
        address proposer;
        uint256 amount; // Amount in native currency (ETH/MATIC) to be granted
        string proposalIpfsHash; // IPFS hash of the detailed grant proposal document
        uint256 submittedAt;
        uint256 votingDeadline;
        uint256 proposerStake; // Stake required from the proposer (refunded on success)
        mapping(address => bool) hasVoted; // Tracks if an address has voted on this proposal
        uint256 yesVotes;
        uint256 noVotes;
        bool executed; // True if the grant has been successfully executed
        bool passed; // True if the proposal passed its voting threshold
        bool active; // True if the proposal is currently open for voting or execution
    }

    // --- State Variables ---

    Counters.Counter private _knowledgeArtifactIds;
    Counters.Counter private _attestationIds;
    Counters.Counter private _disputeIds;
    Counters.Counter private _grantProposalIds;

    mapping(uint256 => KnowledgeArtifact) public knowledgeArtifacts;
    mapping(uint256 => Attestation) public attestations;
    mapping(uint256 => Dispute) public disputes;
    mapping(uint256 => GrantProposal) public grantProposals;

    // Mapping from artifact ID to a list of its attestation IDs
    mapping(uint256 => uint256[]) private _artifactAttestations;
    // Mapping from attester address to a list of attestation IDs they made
    mapping(address => uint256[]) private _userAttestations;

    // Reputation scores: General reputation and domain-specific expertise
    mapping(address => int256) private _attesterReputation; // Overall reputation score (can be negative)
    mapping(address => mapping(string => int256)) private _attesterDomainExpertise; // address -> tag -> expertise score

    // Expertise badges (soulbound-like): address -> domainTag -> badgeLevel (e.g., 1 for Novice, 2 for Expert, 3 for Master)
    // These badges are non-transferable and signify on-chain proof of expertise.
    mapping(address => mapping(string => uint256)) private _expertiseBadges;

    // Configuration for reputation modifiers. These values are set by the owner.
    mapping(string => int256) public reputationModifiers; 

    // Configuration for knowledge artifact tiers: tier level -> minimum aggregate score required
    mapping(uint256 => int256) public minAttestationScoreForTier; 

    uint256 public grantProposalVotingPeriod = 7 days; // Default voting period for grants
    uint256 public minProposerStake = 0.1 ether; // Minimum native currency stake required to propose a grant

    // --- Constructor ---
    constructor(
        int256 _initialRepModifierSuccess, // e.g., +5
        int256 _initialRepModifierFailure, // e.g., -10
        int256 _initialRepModifierRevoke    // e.g., -5
    ) Ownable(msg.sender) {
        // Initialize some default reputation modifiers for common actions
        reputationModifiers["successfulAttestation"] = _initialRepModifierSuccess; 
        reputationModifiers["disputeLoss"] = _initialRepModifierFailure; 
        reputationModifiers["attestationRevoked"] = _initialRepModifierRevoke; 
        reputationModifiers["disputeWin"] = 5; 
        reputationModifiers["grantProposerRefund"] = 0; // Reputation neutral for refund, adjust if desired

        // Initialize minimum scores for predefined tiers (Tier 0 is base/default)
        minAttestationScoreForTier[0] = 0; 
        minAttestationScoreForTier[1] = 100; 
        minAttestationScoreForTier[2] = 500; 
        minAttestationScoreForTier[3] = 1000; // Example tiers, can be configured by owner
    }

    // --- Modifiers ---
    modifier onlyArtifactSubmitter(uint256 _artifactId) {
        require(knowledgeArtifacts[_artifactId].submitter == msg.sender, "AgoraChronicle: Not the artifact submitter");
        _;
    }

    modifier onlyAttester(uint256 _attestationId) {
        require(attestations[_attestationId].attester == msg.sender, "AgoraChronicle: Not the attester of this claim");
        _;
    }

    modifier onlyActiveArtifact(uint256 _artifactId) {
        require(knowledgeArtifacts[_artifactId].isActive, "AgoraChronicle: Artifact is not active or has been archived");
        _;
    }

    modifier onlyActiveProposal(uint256 _proposalId) {
        require(grantProposals[_proposalId].active, "AgoraChronicle: Grant proposal is not active");
        _;
    }

    modifier notExecutedGrant(uint256 _proposalId) {
        require(!grantProposals[_proposalId].executed, "AgoraChronicle: Grant has already been executed");
        _;
    }

    // --- Core Knowledge Artifact Management (I) ---

    /**
     * @notice Allows users to submit a new knowledge artifact to the network.
     * @dev The actual content (e.g., research paper, image) is stored off-chain (e.g., IPFS),
     *      and only its hash and metadata are recorded on-chain.
     * @param _ipfsHash The IPFS hash pointing to the immutable content of the artifact.
     * @param _title The descriptive title of the knowledge artifact.
     * @param _description A brief summary or abstract of the artifact.
     * @param _tags An array of relevant keywords or categories for discovery.
     * @return The unique ID assigned to the newly submitted artifact.
     */
    function submitKnowledgeArtifact(
        string memory _ipfsHash,
        string memory _title,
        string memory _description,
        string[] memory _tags
    ) public whenNotPaused returns (uint256) {
        _knowledgeArtifactIds.increment();
        uint256 newId = _knowledgeArtifactIds.current();

        knowledgeArtifacts[newId] = KnowledgeArtifact({
            id: newId,
            submitter: msg.sender,
            ipfsHash: _ipfsHash,
            title: _title,
            description: _description,
            tags: _tags,
            submittedAt: block.timestamp,
            isActive: true,
            totalAttestationScore: 0,
            attestationCount: 0
        });

        emit KnowledgeArtifactSubmitted(newId, msg.sender, _title, _tags);
        return newId;
    }

    /**
     * @notice Retrieves the comprehensive details of a specific knowledge artifact.
     * @param _artifactId The ID of the knowledge artifact to retrieve.
     * @return A `KnowledgeArtifact` struct containing all its metadata.
     */
    function getKnowledgeArtifact(uint256 _artifactId) public view returns (KnowledgeArtifact memory) {
        require(_artifactId <= _knowledgeArtifactIds.current() && _artifactId > 0, "AgoraChronicle: Invalid Artifact ID");
        return knowledgeArtifacts[_artifactId];
    }

    /**
     * @notice Allows the original submitter to update non-content metadata of their artifact.
     * @dev Only the title, description, and tags can be updated. The IPFS hash (content) remains immutable.
     * @param _artifactId The ID of the artifact to update.
     * @param _newTitle The new title for the artifact.
     * @param _newDescription The new description for the artifact.
     * @param _newTags The new array of tags for the artifact (replaces existing tags).
     */
    function updateKnowledgeArtifactMetadata(
        uint256 _artifactId,
        string memory _newTitle,
        string memory _newDescription,
        string[] memory _newTags
    ) public whenNotPaused onlyArtifactSubmitter(_artifactId) {
        require(knowledgeArtifacts[_artifactId].isActive, "AgoraChronicle: Cannot update metadata of an archived artifact");
        KnowledgeArtifact storage artifact = knowledgeArtifacts[_artifactId];
        artifact.title = _newTitle;
        artifact.description = _newDescription;
        artifact.tags = _newTags; 
        emit KnowledgeArtifactUpdated(_artifactId, msg.sender, _newTitle, _newTags);
    }

    /**
     * @notice Allows the original submitter to mark their artifact as archived.
     * @dev Archived artifacts are considered inactive and cannot receive new attestations or grant proposals.
     * @param _artifactId The ID of the artifact to archive.
     */
    function archiveKnowledgeArtifact(uint256 _artifactId) public whenNotPaused onlyArtifactSubmitter(_artifactId) {
        require(knowledgeArtifacts[_artifactId].isActive, "AgoraChronicle: Artifact is already archived");
        knowledgeArtifacts[_artifactId].isActive = false;
        emit KnowledgeArtifactArchived(_artifactId, msg.sender);
    }

    // --- Attestation & Validation (II) ---

    /**
     * @notice Enables users to provide a qualitative and quantitative attestation for a specific attribute of an artifact.
     * @dev An attester cannot attest to their own submitted artifact.
     *      Successful attestations increase the attester's reputation and domain expertise.
     * @param _artifactId The ID of the artifact being attested.
     * @param _attributeKey A string identifying the attribute (e.g., "originality", "relevance", "accuracy").
     * @param _attributeValue A string representing the qualitative value for the attribute (e.g., "high", "low", "true").
     * @param _score A quantitative score for the attribute (must be between -100 and 100).
     * @param _commentIpfsHash IPFS hash for a detailed comment or rationale supporting the attestation.
     */
    function attestToKnowledgeArtifact(
        uint256 _artifactId,
        string memory _attributeKey,
        string memory _attributeValue,
        int256 _score,
        string memory _commentIpfsHash
    ) public whenNotPaused onlyActiveArtifact(_artifactId) {
        require(_score >= -100 && _score <= 100, "AgoraChronicle: Score must be between -100 and 100");
        require(msg.sender != knowledgeArtifacts[_artifactId].submitter, "AgoraChronicle: Submitter cannot attest to their own artifact");

        _attestationIds.increment();
        uint256 newAttestationId = _attestationIds.current();

        attestations[newAttestationId] = Attestation({
            id: newAttestationId,
            artifactId: _artifactId,
            attester: msg.sender,
            attributeKey: _attributeKey,
            attributeValue: _attributeValue,
            score: _score,
            commentIpfsHash: _commentIpfsHash,
            attestedAt: block.timestamp,
            isRevoked: false
        });

        _artifactAttestations[_artifactId].push(newAttestationId);
        _userAttestations[msg.sender].push(newAttestationId);

        // Update artifact's aggregate score for tiering
        knowledgeArtifacts[_artifactId].totalAttestationScore += _score;
        knowledgeArtifacts[_artifactId].attestationCount++;

        // Update attester's overall reputation
        _updateReputation(msg.sender, reputationModifiers["successfulAttestation"]);
        // Update attester's domain expertise for each tag associated with the artifact
        for (uint256 i = 0; i < knowledgeArtifacts[_artifactId].tags.length; i++) {
            _updateDomainExpertise(msg.sender, knowledgeArtifacts[_artifactId].tags[i], _score);
        }

        emit AttestationSubmitted(newAttestationId, _artifactId, msg.sender, _attributeKey, _score);
    }

    /**
     * @notice Retrieves the full details of a specific attestation by its ID.
     * @param _attestationId The ID of the attestation to retrieve.
     * @return An `Attestation` struct containing all its details.
     */
    function getAttestation(uint256 _attestationId) public view returns (Attestation memory) {
        require(_attestationId <= _attestationIds.current() && _attestationId > 0, "AgoraChronicle: Invalid Attestation ID");
        return attestations[_attestationId];
    }

    /**
     * @notice Returns a list of all attestation IDs for a given knowledge artifact.
     * @param _artifactId The ID of the knowledge artifact.
     * @return An array of attestation IDs.
     */
    function getAttestationsForArtifact(uint256 _artifactId) public view returns (uint256[] memory) {
        require(_artifactId <= _knowledgeArtifactIds.current() && _artifactId > 0, "AgoraChronicle: Invalid Artifact ID");
        return _artifactAttestations[_artifactId];
    }

    /**
     * @notice Returns a list of all attestation IDs made by a specific attester.
     * @param _attester The address of the attester.
     * @return An array of attestation IDs made by the specified address.
     */
    function getAttestationsByAttester(address _attester) public view returns (uint256[] memory) {
        return _userAttestations[_attester];
    }

    /**
     * @notice Allows an attester to revoke their previously submitted attestation.
     * @dev Revoking an attestation incurs a reputation penalty, encouraging careful and considered attestations.
     *      It also reverses the attestation's impact on the artifact's aggregate score and the attester's domain expertise.
     * @param _attestationId The ID of the attestation to revoke.
     */
    function revokeAttestation(uint256 _attestationId) public whenNotPaused onlyAttester(_attestationId) {
        Attestation storage attestation = attestations[_attestationId];
        require(!attestation.isRevoked, "AgoraChronicle: Attestation already revoked or invalidated");

        attestation.isRevoked = true;

        // Revert the attestation's impact on the artifact's total score and count
        knowledgeArtifacts[attestation.artifactId].totalAttestationScore -= attestation.score;
        knowledgeArtifacts[attestation.artifactId].attestationCount--;

        // Apply reputation penalty to the revoker
        _updateReputation(msg.sender, reputationModifiers["attestationRevoked"]);
        // Reduce domain expertise for each tag of the artifact by reverting the original score
        for (uint256 i = 0; i < knowledgeArtifacts[attestation.artifactId].tags.length; i++) {
            _updateDomainExpertise(msg.sender, knowledgeArtifacts[attestation.artifactId].tags[i], -attestation.score); 
        }

        emit AttestationRevoked(_attestationId, msg.sender);
    }

    /**
     * @notice Initiates a formal dispute process against an attestation.
     * @dev Prevents self-disputes and multiple active disputes for the same attestation.
     * @param _attestationId The ID of the attestation to dispute.
     * @param _reasonIpfsHash IPFS hash for a detailed reason explaining why the attestation is disputed.
     */
    function disputeAttestation(uint256 _attestationId, string memory _reasonIpfsHash) public whenNotPaused {
        require(_attestationId <= _attestationIds.current() && _attestationId > 0, "AgoraChronicle: Invalid Attestation ID");
        require(msg.sender != attestations[_attestationId].attester, "AgoraChronicle: Cannot dispute your own attestation");
        require(!attestations[_attestationId].isRevoked, "AgoraChronicle: Cannot dispute a revoked or invalidated attestation");

        // Basic check to prevent multiple open disputes for the same attestation
        // For a full-scale system, a more robust dispute tracking mechanism would be needed.
        for (uint256 i = 1; i <= _disputeIds.current(); i++) {
            if (disputes[i].attestationId == _attestationId && !disputes[i].resolved) {
                revert("AgoraChronicle: Attestation already has an active dispute.");
            }
        }

        _disputeIds.increment();
        uint256 newDisputeId = _disputeIds.current();

        disputes[newDisputeId] = Dispute({
            id: newDisputeId,
            attestationId: _attestationId,
            disputer: msg.sender,
            reasonIpfsHash: _reasonIpfsHash,
            initiatedAt: block.timestamp,
            resolved: false,
            attestationValidOutcome: false 
        });

        emit AttestationDisputed(_attestationId, newDisputeId, msg.sender);
    }

    /**
     * @notice (Admin/DAO controlled) Resolves an active attestation dispute.
     * @dev This function is critical for maintaining the integrity of the reputation system.
     *      It adjusts the reputations of the attester and disputer based on whether the original
     *      attestation was deemed valid or invalid. If invalid, the attestation is also marked as revoked.
     * @param _disputeId The ID of the dispute to resolve.
     * @param _isAttestationValid True if the original attestation is deemed valid, false otherwise.
     */
    function resolveAttestationDispute(uint256 _disputeId, bool _isAttestationValid) public onlyOwner {
        require(_disputeId <= _disputeIds.current() && _disputeId > 0, "AgoraChronicle: Invalid Dispute ID");
        Dispute storage dispute = disputes[_disputeId];
        require(!dispute.resolved, "AgoraChronicle: Dispute already resolved");

        dispute.resolved = true;
        dispute.attestationValidOutcome = _isAttestationValid;

        Attestation storage attestation = attestations[dispute.attestationId];

        if (_isAttestationValid) {
            // Attestation was valid: original attester gains, disputer loses reputation
            _updateReputation(attestation.attester, reputationModifiers["disputeWin"]);
            _updateReputation(dispute.disputer, reputationModifiers["disputeLoss"]);
        } else {
            // Attestation was invalid: original attester loses, disputer gains reputation
            _updateReputation(attestation.attester, reputationModifiers["disputeLoss"]);
            _updateReputation(dispute.disputer, reputationModifiers["disputeWin"]);

            // If attestation was found invalid, effectively 'revoke' it and adjust artifact score
            if (!attestation.isRevoked) { 
                attestation.isRevoked = true; 
                knowledgeArtifacts[attestation.artifactId].totalAttestationScore -= attestation.score;
                knowledgeArtifacts[attestation.artifactId].attestationCount--;
            }
        }

        emit DisputeResolved(_disputeId, dispute.attestationId, _isAttestationValid);
    }

    // --- Reputation & Expertise Badges (III) ---

    /**
     * @notice Internal function to update an account's overall reputation score.
     * @param _account The address whose reputation to update.
     * @param _change The integer amount to add to or subtract from the reputation.
     */
    function _updateReputation(address _account, int256 _change) internal {
        _attesterReputation[_account] += _change;
        emit ReputationUpdated(_account, _attesterReputation[_account]);
    }

    /**
     * @notice Internal function to update an account's domain-specific expertise score.
     * @param _account The address whose expertise to update.
     * @param _tag The specific domain tag (e.g., "Blockchain", "AI", "Art History").
     * @param _change The integer amount to add to or subtract from the expertise score in that domain.
     */
    function _updateDomainExpertise(address _account, string memory _tag, int256 _change) internal {
        _attesterDomainExpertise[_account][_tag] += _change;
        emit DomainExpertiseUpdated(_account, _tag, _attesterDomainExpertise[_account][_tag]);
    }

    /**
     * @notice Retrieves the overall numerical reputation score of an attester.
     * @param _attester The address of the attester to query.
     * @return The attester's current global reputation score.
     */
    function getAttesterReputation(address _attester) public view returns (int256) {
        return _attesterReputation[_attester];
    }

    /**
     * @notice Retrieves the numerical expertise score of an attester for a specific knowledge domain/tag.
     * @param _attester The address of the attester.
     * @param _tag The domain tag to query expertise for (e.g., "DeFi", "Smart Contracts").
     * @return The attester's expertise score in that specific domain.
     */
    function getAttesterDomainExpertise(address _attester, string memory _tag) public view returns (int256) {
        return _attesterDomainExpertise[_attester][_tag];
    }

    /**
     * @notice (Admin/System controlled) Mints a non-transferable (soulbound-like) expertise badge for a user.
     * @dev These badges signify proven proficiency in a given domain at a specific level and cannot be transferred.
     * @param _recipient The address to receive the badge.
     * @param _domainTag The specific domain tag the badge is for (e.g., "ZKP", "DAO Governance").
     * @param _badgeLevel The level of the badge (e.g., 1 for Novice Contributor, 2 for Expert, 3 for Master).
     */
    function mintExpertiseBadge(address _recipient, string memory _domainTag, uint256 _badgeLevel) public onlyOwner {
        require(_badgeLevel > 0, "AgoraChronicle: Badge level must be positive");
        _expertiseBadges[_recipient][_domainTag] = _badgeLevel;
        emit ExpertiseBadgeMinted(_recipient, _domainTag, _badgeLevel);
    }

    /**
     * @notice Retrieves all expertise badges held by a specific address.
     * @dev This is a simplified implementation. In a large-scale system, direct iteration over all possible
     *      tags for every user might be gas-prohibitive. A more robust solution might involve a global
     *      registry of tags or off-chain indexing combined with on-chain lookups for specific badges.
     *      For demonstration, it attempts to return badges related to domains the user has attested in.
     * @param _owner The address to query badges for.
     * @return Two arrays: one of domain tags and one of their corresponding badge levels.
     */
    function getExpertiseBadges(address _owner) public view returns (string[] memory, uint256[] memory) {
        // Collect tags from artifacts the user has attested to.
        uint256[] memory userAttestationIds = _userAttestations[_owner];
        
        // Use temporary dynamic arrays to collect tags and levels
        string[] memory tempTags = new string[](0);
        uint256[] memory tempLevels = new uint256[](0);

        mapping(string => bool) seenTags; // To prevent adding duplicate tags to the result

        // Iterate through attestations by this user to find relevant tags
        for (uint256 i = 0; i < userAttestationIds.length; i++) {
            Attestation storage att = attestations[userAttestationIds[i]];
            KnowledgeArtifact storage art = knowledgeArtifacts[att.artifactId]; // Get artifact details for tags

            for (uint256 j = 0; j < art.tags.length; j++) {
                string memory currentTag = art.tags[j];
                if (!seenTags[currentTag]) { // If this tag hasn't been processed yet
                    uint256 level = _expertiseBadges[_owner][currentTag];
                    if (level > 0) { // If a badge exists for this tag
                        tempTags = _appendToStringArray(tempTags, currentTag);
                        tempLevels = _appendToUintArray(tempLevels, level);
                        seenTags[currentTag] = true; // Mark tag as seen
                    }
                }
            }
            if (tempTags.length >= 20) break; // Limit the number of tags returned for gas efficiency
        }
        return (tempTags, tempLevels);
    }

    // Internal helper function to append a string to a dynamic string array (for demo purposes)
    function _appendToStringArray(string[] memory _array, string memory _element) internal pure returns (string[] memory) {
        string[] memory newArray = new string[](_array.length + 1);
        for (uint256 i = 0; i < _array.length; i++) {
            newArray[i] = _array[i];
        }
        newArray[_array.length] = _element;
        return newArray;
    }

    // Internal helper function to append a uint256 to a dynamic uint256 array (for demo purposes)
    function _appendToUintArray(uint256[] memory _array, uint256 _element) internal pure returns (uint256[] memory) {
        uint256[] memory newArray = new uint256[](_array.length + 1);
        for (uint256 i = 0; i < _array.length; i++) {
            newArray[i] = _array[i];
        }
        newArray[_array.length] = _element;
        return newArray;
    }


    // --- Knowledge Tiering & Curation (IV) ---

    /**
     * @notice Dynamically calculates and returns the current "tier" of a knowledge artifact.
     * @dev The tier is determined by comparing the artifact's `totalAttestationScore` against
     *      predefined minimum scores for each tier, configured by the contract owner.
     * @param _artifactId The ID of the knowledge artifact.
     * @return The calculated tier level (0 for base/unrated, higher for better quality).
     */
    function calculateKnowledgeArtifactTier(uint256 _artifactId) public view returns (uint256) {
        KnowledgeArtifact storage artifact = knowledgeArtifacts[_artifactId];
        if (artifact.attestationCount == 0 && artifact.totalAttestationScore == 0) {
            return 0; // Base tier if no attestations or score is zero
        }

        uint256 currentTier = 0;
        // Check predefined tiers from highest to lowest to find the highest applicable tier
        for (uint256 i = 3; i >= 1; i--) { // Assuming tiers 1, 2, 3 (adjust loop based on max tiers)
            if (minAttestationScoreForTier[i] > 0 && artifact.totalAttestationScore >= minAttestationScoreForTier[i]) {
                currentTier = i;
                break; // Found the highest tier, no need to check lower ones
            }
        }
        return currentTier;
    }

    /**
     * @notice Retrieves a limited array of knowledge artifact IDs that are considered top-rated within a specific tag.
     * @dev This function iterates through all existing artifacts to find those with the specified tag
     *      and a positive aggregate attestation score. For large datasets, this can be very gas-intensive.
     *      In a production environment, this functionality would typically be offloaded to an off-chain indexer
     *      or involve a more complex on-chain caching/sorting mechanism.
     * @param _tag The tag to filter artifacts by (e.g., "Climate Change", "Web3 Gaming").
     * @param _limit The maximum number of artifact IDs to return.
     * @return An array of artifact IDs matching the criteria.
     */
    function getTopRatedKnowledgeArtifactsByTag(string memory _tag, uint256 _limit) public view returns (uint256[] memory) {
        uint256[] memory tempTopArtifacts = new uint256[](_limit); // Temporary array to hold results
        uint256 count = 0;

        // Iterating over all artifacts. This is for demonstration.
        // For large 'knowledgeArtifacts' mappings, this loop will consume significant gas.
        for (uint256 i = 1; i <= _knowledgeArtifactIds.current() && count < _limit; i++) {
            KnowledgeArtifact storage artifact = knowledgeArtifacts[i];
            if (artifact.isActive && artifact.attestationCount > 0) { // Only consider active and attested artifacts
                bool hasTag = false;
                for (uint256 j = 0; j < artifact.tags.length; j++) {
                    if (keccak256(abi.encodePacked(artifact.tags[j])) == keccak256(abi.encodePacked(_tag))) {
                        hasTag = true;
                        break;
                    }
                }
                // Simplified "top-rated" logic: positive total attestation score AND matches tag.
                if (hasTag && artifact.totalAttestationScore > 0) {
                    tempTopArtifacts[count] = artifact.id;
                    count++;
                }
            }
        }

        // Resize the array to the actual count of found artifacts
        uint256[] memory result = new uint256[](count);
        for(uint256 i = 0; i < count; i++) {
            result[i] = tempTopArtifacts[i];
        }
        return result;
    }

    /**
     * @notice Retrieves a limited array of attester addresses identified as experts in a particular knowledge domain/tag.
     * @dev Similar to `getTopRatedKnowledgeArtifactsByTag`, this function iterates over existing attestations
     *      which can be gas-intensive for a large number of users/attestations. Production systems would
     *      typically use off-chain indexing for efficient retrieval of top experts.
     *      It finds unique attesters with a positive domain expertise score for the given tag.
     * @param _tag The domain tag to find experts for (e.g., "Decentralized Science", "Oracles").
     * @param _limit The maximum number of attester addresses to return.
     * @return An array of attester addresses identified as experts in the specified domain.
     */
    function getExpertAttestersForTag(string memory _tag, uint256 _limit) public view returns (address[] memory) {
        address[] memory tempExpertAttesters = new address[](_limit);
        uint256 count = 0;
        mapping(address => bool) seenAttesters; // To avoid adding duplicate attester addresses

        // Iterating over all attestations to identify experts.
        // This can be very gas-intensive for contracts with many attestations.
        for (uint256 i = 1; i <= _attestationIds.current() && count < _limit; i++) {
            Attestation storage att = attestations[i];
            address attester = att.attester;

            if (!seenAttesters[attester]) { // Check if this attester has already been added to the list
                // Simplified "expert" logic: attester has a positive domain expertise score in the specified tag.
                if (_attesterDomainExpertise[attester][_tag] > 0) {
                    tempExpertAttesters[count] = attester;
                    count++;
                    seenAttesters[attester] = true;
                }
            }
        }
        
        // Resize the array to the actual count of found experts
        address[] memory result = new address[](count);
        for(uint256 i = 0; i < count; i++) {
            result[i] = tempExpertAttesters[i];
        }
        return result;
    }

    // --- Decentralized Funding & Grants (V) ---

    /**
     * @notice Allows any user to propose a grant for a specific knowledge artifact.
     * @dev The proposer must send a minimum stake (`minProposerStake`) with the transaction.
     *      This stake is held by the contract and refunded if the proposal is successfully executed.
     *      The actual grant amount is provided later during `executeGrant`.
     * @param _artifactId The ID of the knowledge artifact to propose a grant for.
     * @param _proposalIpfsHash IPFS hash for the detailed grant proposal, outlining objectives and requested amount.
     * @return The unique ID assigned to the new grant proposal.
     */
    function proposeGrantForArtifact(uint256 _artifactId, string memory _proposalIpfsHash) public payable whenNotPaused onlyActiveArtifact(_artifactId) returns (uint256) {
        require(msg.value >= minProposerStake, "AgoraChronicle: Proposer must send minimum stake");
        
        _grantProposalIds.increment();
        uint256 newProposalId = _grantProposalIds.current();

        grantProposals[newProposalId] = GrantProposal({
            id: newProposalId,
            artifactId: _artifactId,
            proposer: msg.sender,
            amount: 0, // Amount will be set when funds are provided during execution
            proposalIpfsHash: _proposalIpfsHash,
            submittedAt: block.timestamp,
            votingDeadline: block.timestamp + grantProposalVotingPeriod,
            proposerStake: msg.value,
            yesVotes: 0,
            noVotes: 0,
            executed: false,
            passed: false,
            active: true
        });

        emit GrantProposalSubmitted(newProposalId, _artifactId, msg.sender, 0); 
        return newProposalId;
    }

    /**
     * @notice Allows eligible voters to cast their vote on an active grant proposal.
     * @dev Eligibility for voting could be based on reputation, expertise scores, or other criteria
     *      (simplified to any user for this example, but can be extended).
     * @param _proposalId The ID of the grant proposal to vote on.
     * @param _support True for a 'yes' vote (in favor), false for a 'no' vote (against).
     */
    function voteOnGrantProposal(uint256 _proposalId, bool _support) public whenNotPaused onlyActiveProposal(_proposalId) {
        GrantProposal storage proposal = grantProposals[_proposalId];
        require(block.timestamp <= proposal.votingDeadline, "AgoraChronicle: Voting period has ended");
        require(!proposal.hasVoted[msg.sender], "AgoraChronicle: Already voted on this proposal");

        if (_support) {
            proposal.yesVotes++;
        } else {
            proposal.noVotes++;
        }
        proposal.hasVoted[msg.sender] = true;

        emit GrantVoteCast(_proposalId, msg.sender, _support);
    }

    /**
     * @notice Executes a successful grant proposal, transferring the proposed funds to the artifact submitter.
     * @dev This function can only be called after the voting deadline has passed and if the proposal
     *      has received more 'yes' votes than 'no' votes. The required grant funds must be sent
     *      with this transaction or have been previously deposited into the contract.
     * @param _proposalId The ID of the grant proposal to execute.
     */
    function executeGrant(uint256 _proposalId) public payable whenNotPaused onlyActiveProposal(_proposalId) notExecutedGrant(_proposalId) {
        GrantProposal storage proposal = grantProposals[_proposalId];
        
        require(block.timestamp > proposal.votingDeadline, "AgoraChronicle: Voting period is still active");
        require(proposal.yesVotes > proposal.noVotes, "AgoraChronicle: Grant proposal did not pass voting");
        require(msg.value > 0, "AgoraChronicle: No funds provided for grant execution.");
        require(knowledgeArtifacts[proposal.artifactId].isActive, "AgoraChronicle: Cannot execute grant for an inactive artifact");

        // Mark proposal as passed, executed, and no longer active for further interaction
        proposal.passed = true;
        proposal.executed = true;
        proposal.active = false; 
        proposal.amount = msg.value; // Record the actual amount received for the grant

        address recipient = knowledgeArtifacts[proposal.artifactId].submitter;

        // Transfer grant funds to the artifact submitter
        (bool successSendGrant, ) = payable(recipient).call{value: proposal.amount}("");
        require(successSendGrant, "AgoraChronicle: Failed to send grant funds to recipient");

        // Refund the proposer's initial stake
        (bool successRefundStake, ) = payable(proposal.proposer).call{value: proposal.proposerStake}("");
        require(successRefundStake, "AgoraChronicle: Failed to refund proposer stake");

        _updateReputation(proposal.proposer, reputationModifiers["grantProposerRefund"]); // Apply any specific reputation change for proposer refund

        emit GrantExecuted(_proposalId, proposal.artifactId, recipient, proposal.amount);
    }

    /**
     * @notice Fallback function to allow the contract to receive native currency (e.g., Ether, Matic).
     * @dev This allows users to deposit funds into the contract, which can then be used for grants.
     */
    receive() external payable {}

    // --- System Configuration & Governance (VI) ---

    /**
     * @notice (Admin) Allows the contract owner to configure or adjust the reputation impact value for various actions.
     * @dev This provides flexibility to tune the reputation system's parameters over time.
     * @param _modifierKey A string key identifying the action (e.g., "successfulAttestation", "disputeLoss", "attestationRevoked").
     * @param _value The integer value representing the reputation change (can be positive or negative).
     */
    function setReputationModifier(string memory _modifierKey, int256 _value) public onlyOwner {
        reputationModifiers[_modifierKey] = _value;
    }

    /**
     * @notice (Admin) Configures the minimum aggregated attestation score required for a knowledge artifact to achieve a specific tier level.
     * @dev Tier 0 is the base tier and typically has a minimum score of 0. Higher tiers require progressively higher scores.
     * @param _tier The tier level to configure (e.g., 1, 2, 3).
     * @param _minScore The minimum total attestation score required for an artifact to be classified in this tier.
     */
    function setMinAttestationScoreForTier(uint256 _tier, int256 _minScore) public onlyOwner {
        require(_tier > 0, "AgoraChronicle: Tier must be greater than 0"); 
        minAttestationScoreForTier[_tier] = _minScore;
    }

    /**
     * @notice (Admin) Pauses most user-facing functionalities of the contract.
     * @dev This function is inherited from OpenZeppelin's Pausable and is crucial for emergency situations,
     *      allowing the owner to halt operations temporarily.
     */
    function pauseContract() public onlyOwner {
        _pause();
    }

    /**
     * @notice (Admin) Unpauses the contract, restoring full functionality.
     * @dev This function is inherited from OpenZeppelin's Pausable.
     */
    function unpauseContract() public onlyOwner {
        _unpause();
    }

    // --- Auxiliary View Functions (for convenience) ---

    /**
     * @notice Returns the number of attestations associated with a specific knowledge artifact.
     * @param _artifactId The ID of the knowledge artifact.
     * @return The count of attestations.
     */
    function getAttestationIdsForArtifactLength(uint256 _artifactId) public view returns (uint256) {
        return _artifactAttestations[_artifactId].length;
    }

    /**
     * @notice Returns the total number of attestations made by a specific user.
     * @param _attester The address of the attester.
     * @return The count of attestations.
     */
    function getUserAttestationIdsLength(address _attester) public view returns (uint256) {
        return _userAttestations[_attester].length;
    }

    /**
     * @notice Returns the ID that will be assigned to the next knowledge artifact.
     */
    function getNextKnowledgeArtifactId() public view returns (uint256) {
        return _knowledgeArtifactIds.current() + 1;
    }

    /**
     * @notice Returns the ID that will be assigned to the next attestation.
     */
    function getNextAttestationId() public view returns (uint256) {
        return _attestationIds.current() + 1;
    }

    /**
     * @notice Returns the ID that will be assigned to the next dispute.
     */
    function getNextDisputeId() public view returns (uint256) {
        return _disputeIds.current() + 1;
    }

    /**
     * @notice Returns the ID that will be assigned to the next grant proposal.
     */
    function getNextGrantProposalId() public view returns (uint256) {
        return _grantProposalIds.current() + 1;
    }
}
```