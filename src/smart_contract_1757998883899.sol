The contract outlined below, **AetherMind**, is designed as a decentralized knowledge genesis engine. It aims to foster the creation, validation, and curation of high-quality knowledge artifacts (e.g., research papers, technical specs, data models) through a synergistic approach combining:

1.  **Decentralized Collaboration:** Users submit and revise knowledge artifacts.
2.  **Reputation System:** Contributors and curators earn non-transferable reputation for valuable contributions and accurate reviews.
3.  **AI Oracle Integration:** Off-chain AI models provide automated evaluations of submitted artifacts, contributing to a "trust score."
4.  **Human Curation:** Reputable human curators review artifacts, arbitrate AI evaluations, and resolve bounties, ensuring quality and accuracy.
5.  **Bounty System:** Sponsors can fund specific knowledge gaps or improvements, incentivizing focused work.

This contract integrates concepts like non-transferable reputation (akin to Soulbound Tokens), decentralized peer review, AI-human hybrid validation, and a dynamic funding mechanism, aiming for a novel approach to collective intelligence and verifiable knowledge generation on-chain.

---

## AetherMind - Decentralized Knowledge Genesis Engine

### Outline:

*   **I. Core Data Structures & State Management:** Defines the fundamental structs and mappings to store artifacts, reputations, bounties, and participant roles.
*   **II. Artifact Submission & Versioning:** Functions for creating new knowledge artifacts, proposing revisions, and managing their lifecycle.
*   **III. AI Oracle Integration & Evaluation:** Mechanisms for AI services to register and submit automated evaluations, influencing artifact acceptance.
*   **IV. Curator Network & Review Process:** Functions for nominating, voting for, and managing human curators who perform qualitative reviews.
*   **V. Reputation Management:** Internal functions to mint and burn non-transferable reputation based on contributions and actions.
*   **VI. Bounty System for Knowledge Creation:** A system allowing sponsors to fund specific tasks related to artifacts, and for contributors to claim and resolve them.
*   **VII. Governance & Parameter Configuration:** Functions for the contract owner to set key operational parameters and manage core roles.
*   **VIII. Utility & View Functions:** Read-only functions to query the state of the contract and retrieve information.

### Function Summary:

**I. Initial Setup & Ownership**
1.  `constructor()`: Initializes the contract owner.
2.  `transferOwnership()`: Transfers contract ownership to a new address.

**II. Knowledge Artifact Management**
3.  `submitNewArtifact(string calldata _ipfsHash, string calldata _title, string calldata _description)`: Allows users to submit a new knowledge artifact, referenced by an IPFS hash.
4.  `proposeArtifactRevision(uint256 _artifactId, string calldata _newIpfsHash, string calldata _newTitle, string calldata _newDescription)`: Proposes a new version or improvement to an existing artifact.
5.  `approveArtifactRevision(uint256 _artifactId, uint256 _revisionId)`: A curator approves a proposed revision, making it the new active version and rewarding the revisor.
6.  `deprecateArtifact(uint256 _artifactId)`: Marks an artifact as outdated or invalid (requires sufficient reputation or curator status).
7.  `getArtifactDetails(uint256 _artifactId)`: Retrieves detailed information about a specific artifact.
8.  `getArtifactVersionHistory(uint256 _artifactId)`: Retrieves a list of all versions (revisions) for a given artifact.

**III. AI Oracle Interaction**
9.  `registerAIOracle(address _oracleAddress)`: Whitelists an AI service provider to submit evaluations.
10. `submitAIEvaluation(uint256 _artifactId, uint8 _score, string calldata _detailsIpfsHash)`: An AI oracle submits its automated assessment (score and detailed report) for an artifact.
11. `getAIEvaluation(uint256 _artifactId, address _oracleAddress)`: Retrieves the AI evaluation score and details submitted by a specific oracle for an artifact.

**IV. Curator Network & Review**
12. `nominateCurator(address _nominee)`: Proposes a user to become a curator. Requires a minimum reputation.
13. `voteForCuratorNomination(address _nominee)`: Users with sufficient reputation can vote for a curator nominee.
14. `becomeCurator(address _nominee)`: A nominated user claims the curator role if sufficient votes are met.
15. `submitCuratorReview(uint256 _artifactId, uint8 _score, string calldata _commentIpfsHash)`: A curator provides a human review (score and detailed comment) for an artifact. This action contributes to the artifact's final status.
16. `revokeCuratorStatus(address _curatorAddress)`: Allows the contract owner to remove a curator due to misconduct or inactivity.

**V. Reputation System (Internal: `_mintReputation`, `_burnReputation` handled by other functions)**
17. `getReputation(address _user)`: Checks the current non-transferable reputation score of a specific address.

**VI. Bounty System**
18. `createBounty(uint256 _artifactId, string calldata _taskDescription, uint256 _reward, uint64 _deadline)`: Allows sponsors to fund specific tasks for artifact creation or improvement.
19. `claimBountyTask(uint256 _bountyId)`: A user commits to completing an open bounty.
20. `submitBountySolution(uint256 _bountyId, string calldata _solutionIpfsHash)`: The claimant submits their solution (e.g., an IPFS hash to a new artifact revision or data) for a claimed bounty.
21. `resolveBounty(uint256 _bountyId, address _solutionProvider, bool _accepted)`: A curator reviews a bounty solution; if accepted, the reward is transferred and reputation is granted.
22. `withdrawUnclaimedBounty(uint256 _bountyId)`: The sponsor can withdraw funds from an expired and unclaimed bounty.

**VII. Governance & Parameters**
23. `setMinCuratorNominationVotes(uint256 _minVotes)`: Sets the minimum number of votes required for a curator nomination to succeed.
24. `setRequiredCuratorReviews(uint8 _numReviews)`: Sets the number of curator reviews needed for an artifact to move from `UnderReview` to `Accepted` or `Rejected`.
25. `setAIOracleWeight(uint8 _weight)`: Adjusts the influence (weight) of AI evaluations when determining an artifact's final status, relative to human reviews.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

// Outline:
// I. Core Data Structures & State Management
// II. Artifact Submission & Versioning
// III. AI Oracle Integration & Evaluation
// IV. Curator Network & Review Process
// V. Reputation Management (Internal & External)
// VI. Bounty System for Knowledge Creation
// VII. Governance & Parameter Configuration
// VIII. Utility & View Functions

// Function Summary:
// I. Initial Setup & Ownership
// 1. constructor(): Initializes the contract owner.
// 2. transferOwnership(): Transfers contract ownership.
// II. Knowledge Artifact Management
// 3. submitNewArtifact(): Allows users to submit a new knowledge artifact.
// 4. proposeArtifactRevision(): Proposes a new version or improvement to an existing artifact.
// 5. approveArtifactRevision(): A curator approves a proposed revision, making it the new active version.
// 6. deprecateArtifact(): Marks an artifact as outdated or invalid (requires sufficient reputation or curator).
// 7. getArtifactDetails(): Retrieves detailed information about a specific artifact.
// 8. getArtifactVersionHistory(): Retrieves a list of all versions for a given artifact.
// III. AI Oracle Interaction
// 9. registerAIOracle(): Whitelists an AI service provider to submit evaluations.
// 10. submitAIEvaluation(): An AI oracle submits its automated assessment for an artifact.
// 11. getAIEvaluation(): Retrieves the AI evaluation score and details for an artifact.
// IV. Curator Network & Review
// 12. nominateCurator(): Proposes a user to become a curator.
// 13. voteForCuratorNomination(): Users with reputation can vote for a curator nominee.
// 14. becomeCurator(): A nominated user claims the curator role if sufficient votes are met.
// 15. submitCuratorReview(): A curator provides a human review and score for an artifact.
// 16. revokeCuratorStatus(): Allows governance to remove a curator due to misconduct.
// V. Reputation System (Internal: mint/burn handled by other functions)
// 17. getReputation(): Checks the reputation score of a specific address.
// VI. Bounty System
// 18. createBounty(): Allows sponsors to fund specific tasks for artifact creation or improvement.
// 19. claimBountyTask(): A user commits to completing an open bounty.
// 20. submitBountySolution(): The claimant submits their solution for a claimed bounty.
// 21. resolveBounty(): A curator reviews a bounty solution and awards the reward.
// 22. withdrawUnclaimedBounty(): The sponsor can withdraw funds from an expired, unclaimed bounty.
// VII. Governance & Parameters
// 23. setMinCuratorNominationVotes(): Sets the minimum votes required for a curator nomination.
// 24. setRequiredCuratorReviews(): Sets the number of curator reviews needed for an artifact to be accepted.
// 25. setAIOracleWeight(): Adjusts the influence of AI evaluations on artifact acceptance.

contract AetherMind is Ownable, ReentrancyGuard {

    // I. Core Data Structures & State Management

    // --- Enums ---
    enum ArtifactStatus { Pending, UnderReview, Accepted, Rejected, Deprecated }
    enum BountyStatus { Open, Claimed, Submitted, Resolved, Withdrawn }

    // --- Structs ---
    struct ArtifactVersion {
        uint256 id;
        string ipfsHash;
        string title;
        string description;
        address creator;
        uint64 timestamp;
        uint256 parentVersionId; // 0 for initial version, otherwise parent
        uint256 aiScoreSum; // Sum of AI scores for this version
        uint256 aiEvaluationCount; // Number of AI evaluations
        uint256 curatorScoreSum; // Sum of curator scores for this version
        uint256 curatorReviewCount; // Number of curator reviews
        mapping(address => bool) hasReviewedCurator; // Track if a curator has reviewed this version
        mapping(address => bool) hasEvaluatedAI; // Track if an AI oracle has evaluated this version
    }

    struct Artifact {
        uint256 currentVersionId; // Points to the ID of the active ArtifactVersion
        ArtifactStatus status;
        address owner; // Original creator of the base artifact
        uint256 totalRevisions; // Count of all revisions, including initial
        mapping(uint256 => ArtifactVersion) versions; // All versions associated with this artifact
    }

    struct AIEvaluation {
        address oracle;
        uint8 score; // Score from 0-100
        string detailsIpfsHash; // IPFS hash to detailed AI report
        uint64 timestamp;
    }

    struct CuratorReview {
        address curator;
        uint8 score; // Score from 0-100
        string commentIpfsHash; // IPFS hash to detailed human comment
        uint64 timestamp;
    }

    struct Bounty {
        uint256 id;
        uint256 artifactId; // Optional: 0 if general knowledge gap, otherwise specific artifact
        address sponsor;
        string taskDescription;
        uint256 rewardAmount;
        uint64 deadline;
        BountyStatus status;
        address claimant;
        string solutionIpfsHash; // IPFS hash to the submitted solution
        uint64 claimedTimestamp;
        uint64 solutionTimestamp;
    }

    struct CuratorNomination {
        address nominee;
        address proposer;
        uint64 timestamp;
        uint256 votes;
        mapping(address => bool) hasVoted; // Voter => bool
    }

    // --- State Variables ---
    uint256 private nextArtifactId;
    uint256 private nextBountyId;
    uint256 private nextCuratorNominationId; // Not strictly needed, nominee address is key

    mapping(uint256 => Artifact) public artifacts;
    mapping(address => uint256) public reputation; // Non-transferable reputation score
    mapping(address => bool) public isCurator; // Whitelisted human curators
    mapping(address => bool) public isAIOracle; // Whitelisted AI service providers

    // Mapping for AI evaluations: artifactId => oracleAddress => AIEvaluation
    mapping(uint256 => mapping(address => AIEvaluation)) private artifactAIEvaluations;
    // Mapping for curator reviews: artifactId => versionId => curatorAddress => CuratorReview
    mapping(uint256 => mapping(uint256 => mapping(address => CuratorReview))) private artifactVersionCuratorReviews;


    mapping(uint256 => Bounty) public bounties;
    mapping(address => CuratorNomination) public curatorNominations; // Nominee => Nomination

    // --- Configuration Parameters ---
    uint256 public minReputationForCuratorNomination = 100; // Min reputation to nominate
    uint256 public minVotesForCuratorAcceptance = 5; // Min votes for a nominee to become curator
    uint256 public minReputationToVoteForCurator = 50; // Min reputation to vote for a curator
    uint8 public requiredCuratorReviews = 3; // Number of distinct curator reviews required
    uint8 public aiOracleWeight = 50; // Weight of AI evaluations vs. human reviews (out of 100). E.g., 50 means 50% AI, 50% human.

    // --- Events ---
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event ArtifactSubmitted(uint256 indexed artifactId, address indexed creator, string ipfsHash, string title);
    event ArtifactRevisionProposed(uint256 indexed artifactId, uint256 indexed newVersionId, address indexed proposer, string ipfsHash);
    event ArtifactRevisionApproved(uint256 indexed artifactId, uint256 indexed approvedVersionId, address indexed approver);
    event ArtifactDeprecated(uint256 indexed artifactId, address indexed deprecator);
    event AIOracleRegistered(address indexed oracleAddress);
    event AIEvaluationSubmitted(uint256 indexed artifactId, address indexed oracleAddress, uint8 score);
    event CuratorNominated(address indexed nominee, address indexed proposer);
    event CuratorVote(address indexed voter, address indexed nominee);
    event CuratorStatusGranted(address indexed curator);
    event CuratorReviewSubmitted(uint256 indexed artifactId, uint256 indexed versionId, address indexed curator, uint8 score);
    event CuratorStatusRevoked(address indexed curatorAddress, address indexed revoker);
    event BountyCreated(uint256 indexed bountyId, address indexed sponsor, uint256 rewardAmount, uint64 deadline);
    event BountyClaimed(uint256 indexed bountyId, address indexed claimant);
    event BountySolutionSubmitted(uint256 indexed bountyId, address indexed claimant, string solutionIpfsHash);
    event BountyResolved(uint256 indexed bountyId, address indexed solutionProvider, uint256 rewardAmount, bool accepted);
    event BountyWithdrawn(uint256 indexed bountyId, address indexed sponsor);
    event ReputationMinted(address indexed user, uint256 amount);
    event ReputationBurned(address indexed user, uint256 amount);


    // --- Modifiers ---
    modifier onlyCurator() {
        require(isCurator[msg.sender], "Caller is not a curator");
        _;
    }

    modifier onlyAIOracle() {
        require(isAIOracle[msg.sender], "Caller is not an AI oracle");
        _;
    }

    modifier hasMinReputation(uint256 _minRep) {
        require(reputation[msg.sender] >= _minRep, "Insufficient reputation");
        _;
    }

    // Constructor to initialize contract owner
    constructor() Ownable(msg.sender) {
        nextArtifactId = 1;
        nextBountyId = 1;
    }

    // II. Artifact Submission & Versioning

    /**
     * @notice Allows users to submit a new knowledge artifact.
     * @param _ipfsHash The IPFS hash pointing to the artifact content.
     * @param _title The title of the artifact.
     * @param _description A brief description of the artifact.
     */
    function submitNewArtifact(string calldata _ipfsHash, string calldata _title, string calldata _description) external nonReentrant {
        require(bytes(_ipfsHash).length > 0, "IPFS hash cannot be empty");
        require(bytes(_title).length > 0, "Title cannot be empty");

        uint256 artifactId = nextArtifactId++;
        uint256 versionId = 1; // First version is always 1

        artifacts[artifactId].versions[versionId] = ArtifactVersion({
            id: versionId,
            ipfsHash: _ipfsHash,
            title: _title,
            description: _description,
            creator: msg.sender,
            timestamp: uint64(block.timestamp),
            parentVersionId: 0,
            aiScoreSum: 0,
            aiEvaluationCount: 0,
            curatorScoreSum: 0,
            curatorReviewCount: 0
        });

        artifacts[artifactId].currentVersionId = versionId;
        artifacts[artifactId].status = ArtifactStatus.Pending;
        artifacts[artifactId].owner = msg.sender;
        artifacts[artifactId].totalRevisions = 1;

        _mintReputation(msg.sender, 10); // Reward for new artifact submission

        emit ArtifactSubmitted(artifactId, msg.sender, _ipfsHash, _title);
    }

    /**
     * @notice Proposes a new version or improvement to an existing artifact.
     *         The revision will be in `Pending` status until approved by curators.
     * @param _artifactId The ID of the artifact to revise.
     * @param _newIpfsHash The IPFS hash pointing to the new version's content.
     * @param _newTitle The new title for the revision.
     * @param _newDescription The new description for the revision.
     */
    function proposeArtifactRevision(
        uint256 _artifactId,
        string calldata _newIpfsHash,
        string calldata _newTitle,
        string calldata _newDescription
    ) external nonReentrant {
        Artifact storage artifact = artifacts[_artifactId];
        require(artifact.owner != address(0), "Artifact does not exist");
        require(artifact.status != ArtifactStatus.Deprecated, "Cannot revise a deprecated artifact");
        require(bytes(_newIpfsHash).length > 0, "New IPFS hash cannot be empty");
        require(bytes(_newTitle).length > 0, "New title cannot be empty");

        uint256 newVersionId = ++artifact.totalRevisions;
        artifact.versions[newVersionId] = ArtifactVersion({
            id: newVersionId,
            ipfsHash: _newIpfsHash,
            title: _newTitle,
            description: _newDescription,
            creator: msg.sender,
            timestamp: uint64(block.timestamp),
            parentVersionId: artifact.currentVersionId,
            aiScoreSum: 0,
            aiEvaluationCount: 0,
            curatorScoreSum: 0,
            curatorReviewCount: 0
        });

        // Set status to UnderReview only if the current version is Accepted.
        // If it's still Pending/UnderReview, the revision itself becomes Pending.
        if (artifact.status == ArtifactStatus.Accepted) {
            artifact.status = ArtifactStatus.UnderReview;
        }

        emit ArtifactRevisionProposed(_artifactId, newVersionId, msg.sender, _newIpfsHash);
    }

    /**
     * @notice A curator approves a proposed revision, making it the new active version.
     *         This requires enough curator reviews and AI evaluations (implicitly handled by review logic).
     * @param _artifactId The ID of the artifact.
     * @param _revisionId The ID of the proposed revision to approve.
     */
    function approveArtifactRevision(uint256 _artifactId, uint256 _revisionId) external onlyCurator nonReentrant {
        Artifact storage artifact = artifacts[_artifactId];
        require(artifact.owner != address(0), "Artifact does not exist");
        require(artifact.versions[_revisionId].creator != address(0), "Revision does not exist");
        require(artifact.currentVersionId != _revisionId, "Revision is already the current version");

        ArtifactVersion storage revision = artifact.versions[_revisionId];
        
        // This function primarily handles setting a revision as current, assuming it has passed checks.
        // The actual decision making (acceptance based on AI/Curator scores) happens when `submitCuratorReview` is called
        // and a threshold is met. This function is for a curator to explicitly push a *ready* revision.
        // For simplicity, we'll assume a revision is 'ready' if it has been reviewed and has a passing score.
        // In a more complex system, this would be a governance vote or automatic based on aggregate scores.
        
        // Let's implement a simpler check: at least one curator must explicitly call this.
        // A more robust system would involve aggregate scoring and voting.
        
        // To simplify for this exercise, we will assume a curator making this call implicitly "approves" it,
        // but actual acceptance rules should be tied to `requiredCuratorReviews` and `aiOracleWeight`.
        // For this function, we'll make it only possible if the artifact is in UnderReview.
        require(artifact.status == ArtifactStatus.UnderReview || artifact.status == ArtifactStatus.Pending, "Artifact is not under review or pending a decision.");

        // For a revision to be approved, it must have met the quality threshold.
        // This logic is usually handled by `_evaluateArtifactStatus` which is called by `submitCuratorReview`.
        // So, this `approveArtifactRevision` is more like a manual finalization by a single curator.
        // Let's make it so a curator can only approve if it has *already* reached an 'Accepted' state internally.
        // This implies `_evaluateArtifactStatus` would have been called.
        // A more realistic scenario is a governance vote or multi-curator approval to make a revision current.
        
        // Let's modify: a curator can approve *if* it passes the current review thresholds.
        if (!_evaluateArtifactStatus(_artifactId, _revisionId)) {
            revert("Revision has not met the required quality thresholds for approval.");
        }

        artifact.currentVersionId = _revisionId;
        artifact.status = ArtifactStatus.Accepted; // Now it's the accepted current version

        _mintReputation(revision.creator, 20); // Reward for approved revision
        _mintReputation(msg.sender, 5); // Reward for curator approving

        emit ArtifactRevisionApproved(_artifactId, _revisionId, msg.sender);
    }

    /**
     * @notice Marks an artifact as outdated or invalid. Requires sufficient reputation or curator status.
     * @param _artifactId The ID of the artifact to deprecate.
     */
    function deprecateArtifact(uint256 _artifactId) external nonReentrant {
        Artifact storage artifact = artifacts[_artifactId];
        require(artifact.owner != address(0), "Artifact does not exist");
        require(artifact.status != ArtifactStatus.Deprecated, "Artifact is already deprecated");

        // Only owner or a high-reputation user/curator can deprecate
        bool canDeprecate = (msg.sender == artifact.owner) ||
                            isCurator[msg.sender] ||
                            (reputation[msg.sender] >= minReputationForCuratorNomination * 2); // E.g., double min curator rep

        require(canDeprecate, "Insufficient permissions to deprecate artifact");

        artifact.status = ArtifactStatus.Deprecated;
        _burnReputation(artifact.owner, 10); // Penalty for owner if their artifact is deprecated (optional, can remove)

        emit ArtifactDeprecated(_artifactId, msg.sender);
    }

    /**
     * @notice Retrieves detailed information about a specific artifact.
     * @param _artifactId The ID of the artifact.
     * @return _currentVersionId The ID of the current active version.
     * @return _status The current status of the artifact.
     * @return _owner The original creator of the artifact.
     * @return _totalRevisions The total count of all versions/revisions.
     * @return _ipfsHash The IPFS hash of the current version.
     * @return _title The title of the current version.
     * @return _description The description of the current version.
     * @return _creator The creator of the current version.
     * @return _timestamp The timestamp of the current version.
     */
    function getArtifactDetails(uint256 _artifactId)
        external
        view
        returns (
            uint256 _currentVersionId,
            ArtifactStatus _status,
            address _owner,
            uint256 _totalRevisions,
            string memory _ipfsHash,
            string memory _title,
            string memory _description,
            address _creator,
            uint64 _timestamp
        )
    {
        Artifact storage artifact = artifacts[_artifactId];
        require(artifact.owner != address(0), "Artifact does not exist");

        ArtifactVersion storage currentVersion = artifact.versions[artifact.currentVersionId];

        return (
            artifact.currentVersionId,
            artifact.status,
            artifact.owner,
            artifact.totalRevisions,
            currentVersion.ipfsHash,
            currentVersion.title,
            currentVersion.description,
            currentVersion.creator,
            currentVersion.timestamp
        );
    }

    /**
     * @notice Retrieves a list of all versions for a given artifact.
     * @param _artifactId The ID of the artifact.
     * @return versionIds An array of all version IDs associated with the artifact.
     */
    function getArtifactVersionHistory(uint256 _artifactId) external view returns (uint256[] memory versionIds) {
        Artifact storage artifact = artifacts[_artifactId];
        require(artifact.owner != address(0), "Artifact does not exist");

        versionIds = new uint256[](artifact.totalRevisions);
        for (uint256 i = 0; i < artifact.totalRevisions; i++) {
            versionIds[i] = i + 1; // Assuming version IDs are sequential from 1
        }
        return versionIds;
    }

    // III. AI Oracle Integration & Evaluation

    /**
     * @notice Whitelists an AI service provider to submit evaluations. Only owner can call.
     * @param _oracleAddress The address of the AI oracle.
     */
    function registerAIOracle(address _oracleAddress) external onlyOwner {
        require(_oracleAddress != address(0), "Invalid address");
        require(!isAIOracle[_oracleAddress], "AI oracle already registered");
        isAIOracle[_oracleAddress] = true;
        emit AIOracleRegistered(_oracleAddress);
    }

    /**
     * @notice An AI oracle submits its automated assessment for an artifact.
     *         This assessment contributes to the artifact's overall score.
     * @param _artifactId The ID of the artifact to evaluate.
     * @param _score The AI's score (0-100).
     * @param _detailsIpfsHash IPFS hash to a detailed AI report.
     */
    function submitAIEvaluation(
        uint256 _artifactId,
        uint8 _score,
        string calldata _detailsIpfsHash
    ) external onlyAIOracle nonReentrant {
        Artifact storage artifact = artifacts[_artifactId];
        require(artifact.owner != address(0), "Artifact does not exist");
        require(artifact.status != ArtifactStatus.Deprecated, "Cannot evaluate deprecated artifact");
        require(_score <= 100, "Score must be between 0 and 100");

        uint256 currentVersionId = artifact.currentVersionId;
        ArtifactVersion storage currentVersion = artifact.versions[currentVersionId];
        require(!currentVersion.hasEvaluatedAI[msg.sender], "AI oracle already evaluated this version");

        artifactAIEvaluations[_artifactId][msg.sender] = AIEvaluation({
            oracle: msg.sender,
            score: _score,
            detailsIpfsHash: _detailsIpfsHash,
            timestamp: uint64(block.timestamp)
        });

        currentVersion.aiScoreSum += _score;
        currentVersion.aiEvaluationCount++;
        currentVersion.hasEvaluatedAI[msg.sender] = true;

        // Automatically set to UnderReview if enough AI evaluations start coming in
        if (artifact.status == ArtifactStatus.Pending && currentVersion.aiEvaluationCount > 0) {
            artifact.status = ArtifactStatus.UnderReview;
        }

        // Check if artifact can be auto-accepted/rejected based on AI if no human reviews yet (and AI weight is high)
        if (requiredCuratorReviews == 0 && currentVersion.aiEvaluationCount > 0) {
            _evaluateArtifactStatus(_artifactId, currentVersionId);
        }
        
        emit AIEvaluationSubmitted(_artifactId, msg.sender, _score);
    }

    /**
     * @notice Retrieves the AI evaluation score and details submitted by a specific oracle for an artifact.
     * @param _artifactId The ID of the artifact.
     * @param _oracleAddress The address of the AI oracle.
     * @return _score The AI's score.
     * @return _detailsIpfsHash IPFS hash to the detailed AI report.
     * @return _timestamp The timestamp of the evaluation.
     */
    function getAIEvaluation(uint256 _artifactId, address _oracleAddress)
        external
        view
        returns (uint8 _score, string memory _detailsIpfsHash, uint64 _timestamp)
    {
        AIEvaluation storage evaluation = artifactAIEvaluations[_artifactId][_oracleAddress];
        require(evaluation.oracle != address(0), "No evaluation found from this oracle for this artifact");
        return (evaluation.score, evaluation.detailsIpfsHash, evaluation.timestamp);
    }

    // IV. Curator Network & Review

    /**
     * @notice Proposes a user to become a curator. Requires a minimum reputation.
     * @param _nominee The address of the user to nominate.
     */
    function nominateCurator(address _nominee) external hasMinReputation(minReputationForCuratorNomination) nonReentrant {
        require(_nominee != address(0), "Invalid nominee address");
        require(!isCurator[_nominee], "Nominee is already a curator");
        require(curatorNominations[_nominee].nominee == address(0), "Nominee is already under nomination");
        require(msg.sender != _nominee, "Cannot nominate self");

        curatorNominations[_nominee] = CuratorNomination({
            nominee: _nominee,
            proposer: msg.sender,
            timestamp: uint64(block.timestamp),
            votes: 1
        });
        curatorNominations[_nominee].hasVoted[msg.sender] = true;

        emit CuratorNominated(_nominee, msg.sender);
    }

    /**
     * @notice Users with sufficient reputation can vote for a curator nominee.
     * @param _nominee The address of the nominee to vote for.
     */
    function voteForCuratorNomination(address _nominee) external hasMinReputation(minReputationToVoteForCurator) nonReentrant {
        CuratorNomination storage nomination = curatorNominations[_nominee];
        require(nomination.nominee != address(0), "Nominee not found");
        require(!isCurator[_nominee], "Nominee is already a curator");
        require(msg.sender != _nominee, "Cannot vote for self");
        require(!nomination.hasVoted[msg.sender], "Already voted for this nominee");

        nomination.votes++;
        nomination.hasVoted[msg.sender] = true;

        emit CuratorVote(msg.sender, _nominee);
    }

    /**
     * @notice A nominated user claims the curator role if sufficient votes are met.
     *         This function can be called by the nominee once the vote threshold is reached.
     * @param _nominee The address of the user claiming the curator role.
     */
    function becomeCurator(address _nominee) external nonReentrant {
        CuratorNomination storage nomination = curatorNominations[_nominee];
        require(nomination.nominee != address(0), "Nominee not found");
        require(nomination.nominee == msg.sender, "Only the nominee can claim curator status");
        require(!isCurator[_nominee], "Nominee is already a curator");
        require(nomination.votes >= minVotesForCuratorAcceptance, "Not enough votes");

        isCurator[_nominee] = true;
        delete curatorNominations[_nominee]; // Clear nomination data
        _mintReputation(_nominee, 50); // Reward for becoming a curator

        emit CuratorStatusGranted(_nominee);
    }

    /**
     * @notice A curator provides a human review and score for an artifact.
     *         This contributes to the artifact's final status determination.
     * @param _artifactId The ID of the artifact to review.
     * @param _score The curator's score (0-100).
     * @param _commentIpfsHash IPFS hash to detailed human comment.
     */
    function submitCuratorReview(
        uint256 _artifactId,
        uint8 _score,
        string calldata _commentIpfsHash
    ) external onlyCurator nonReentrant {
        Artifact storage artifact = artifacts[_artifactId];
        require(artifact.owner != address(0), "Artifact does not exist");
        require(artifact.status != ArtifactStatus.Deprecated, "Cannot review deprecated artifact");
        require(_score <= 100, "Score must be between 0 and 100");

        uint256 currentVersionId = artifact.currentVersionId;
        ArtifactVersion storage currentVersion = artifact.versions[currentVersionId];
        require(!currentVersion.hasReviewedCurator[msg.sender], "Curator already reviewed this version");

        artifactVersionCuratorReviews[_artifactId][currentVersionId][msg.sender] = CuratorReview({
            curator: msg.sender,
            score: _score,
            commentIpfsHash: _commentIpfsHash,
            timestamp: uint64(block.timestamp)
        });

        currentVersion.curatorScoreSum += _score;
        currentVersion.curatorReviewCount++;
        currentVersion.hasReviewedCurator[msg.sender] = true;

        // Set status to UnderReview if not already, as reviews are coming in
        if (artifact.status == ArtifactStatus.Pending) {
            artifact.status = ArtifactStatus.UnderReview;
        }

        // Evaluate artifact status after each review if thresholds are met
        if (currentVersion.curatorReviewCount >= requiredCuratorReviews) {
            bool accepted = _evaluateArtifactStatus(_artifactId, currentVersionId);
            if (accepted) {
                artifact.status = ArtifactStatus.Accepted;
                _mintReputation(currentVersion.creator, 20); // Reward creator for accepted artifact
            } else {
                artifact.status = ArtifactStatus.Rejected;
                _burnReputation(currentVersion.creator, 5); // Penalty for rejected artifact (optional)
            }
        }
        _mintReputation(msg.sender, 5); // Reward for reviewing

        emit CuratorReviewSubmitted(_artifactId, currentVersionId, msg.sender, _score);
    }

    /**
     * @notice Allows the contract owner to remove a curator due to misconduct or inactivity.
     * @param _curatorAddress The address of the curator to revoke.
     */
    function revokeCuratorStatus(address _curatorAddress) external onlyOwner {
        require(_curatorAddress != address(0), "Invalid address");
        require(isCurator[_curatorAddress], "Address is not a curator");

        isCurator[_curatorAddress] = false;
        _burnReputation(_curatorAddress, 100); // Significant penalty for revocation

        emit CuratorStatusRevoked(_curatorAddress, msg.sender);
    }

    // V. Reputation Management

    /**
     * @notice Checks the current non-transferable reputation score of a specific address.
     * @param _user The address to check reputation for.
     * @return The reputation score.
     */
    function getReputation(address _user) external view returns (uint256) {
        return reputation[_user];
    }

    /**
     * @notice Internal function to mint reputation tokens.
     * @dev Reputation is non-transferable and managed internally by contract logic.
     * @param _user The address to mint reputation for.
     * @param _amount The amount of reputation to mint.
     */
    function _mintReputation(address _user, uint224 _amount) internal {
        reputation[_user] += _amount;
        emit ReputationMinted(_user, _amount);
    }

    /**
     * @notice Internal function to burn reputation tokens.
     * @dev Reputation is non-transferable and managed internally by contract logic.
     * @param _user The address to burn reputation from.
     * @param _amount The amount of reputation to burn.
     */
    function _burnReputation(address _user, uint224 _amount) internal {
        if (reputation[_user] > _amount) {
            reputation[_user] -= _amount;
        } else {
            reputation[_user] = 0;
        }
        emit ReputationBurned(_user, _amount);
    }

    // VI. Bounty System

    /**
     * @notice Allows sponsors to fund specific tasks for artifact creation or improvement.
     * @param _artifactId The ID of the artifact the bounty is for (0 for general tasks).
     * @param _taskDescription A description of the task.
     * @param _reward The amount of ETH to reward upon completion.
     * @param _deadline The timestamp by which the bounty must be completed.
     */
    function createBounty(
        uint256 _artifactId,
        string calldata _taskDescription,
        uint256 _reward,
        uint64 _deadline
    ) external payable nonReentrant {
        require(msg.value == _reward, "Sent ETH must match reward amount");
        require(bytes(_taskDescription).length > 0, "Task description cannot be empty");
        require(_deadline > block.timestamp, "Deadline must be in the future");
        if (_artifactId != 0) {
            require(artifacts[_artifactId].owner != address(0), "Target artifact does not exist");
        }

        uint256 bountyId = nextBountyId++;
        bounties[bountyId] = Bounty({
            id: bountyId,
            artifactId: _artifactId,
            sponsor: msg.sender,
            taskDescription: _taskDescription,
            rewardAmount: _reward,
            deadline: _deadline,
            status: BountyStatus.Open,
            claimant: address(0),
            solutionIpfsHash: "",
            claimedTimestamp: 0,
            solutionTimestamp: 0
        });

        emit BountyCreated(bountyId, msg.sender, _reward, _deadline);
    }

    /**
     * @notice A user commits to completing an open bounty.
     * @param _bountyId The ID of the bounty to claim.
     */
    function claimBountyTask(uint256 _bountyId) external nonReentrant {
        Bounty storage bounty = bounties[_bountyId];
        require(bounty.sponsor != address(0), "Bounty does not exist");
        require(bounty.status == BountyStatus.Open, "Bounty is not open");
        require(block.timestamp <= bounty.deadline, "Bounty has expired");
        require(bounty.sponsor != msg.sender, "Sponsor cannot claim their own bounty");

        bounty.claimant = msg.sender;
        bounty.status = BountyStatus.Claimed;
        bounty.claimedTimestamp = uint64(block.timestamp);

        emit BountyClaimed(_bountyId, msg.sender);
    }

    /**
     * @notice The claimant submits their solution for a claimed bounty.
     * @param _bountyId The ID of the bounty.
     * @param _solutionIpfsHash IPFS hash to the submitted solution.
     */
    function submitBountySolution(uint256 _bountyId, string calldata _solutionIpfsHash) external nonReentrant {
        Bounty storage bounty = bounties[_bountyId];
        require(bounty.sponsor != address(0), "Bounty does not exist");
        require(bounty.status == BountyStatus.Claimed, "Bounty is not claimed or already resolved");
        require(bounty.claimant == msg.sender, "Only the claimant can submit a solution");
        require(block.timestamp <= bounty.deadline, "Bounty deadline passed");
        require(bytes(_solutionIpfsHash).length > 0, "Solution IPFS hash cannot be empty");

        bounty.solutionIpfsHash = _solutionIpfsHash;
        bounty.status = BountyStatus.Submitted;
        bounty.solutionTimestamp = uint64(block.timestamp);

        emit BountySolutionSubmitted(_bountyId, msg.sender, _solutionIpfsHash);
    }

    /**
     * @notice A curator reviews a bounty solution; if accepted, the reward is transferred and reputation is granted.
     * @param _bountyId The ID of the bounty.
     * @param _solutionProvider The address of the user who submitted the solution (to prevent front-running).
     * @param _accepted True if the solution is accepted, false otherwise.
     */
    function resolveBounty(uint256 _bountyId, address _solutionProvider, bool _accepted) external onlyCurator nonReentrant {
        Bounty storage bounty = bounties[_bountyId];
        require(bounty.sponsor != address(0), "Bounty does not exist");
        require(bounty.status == BountyStatus.Submitted, "Bounty solution not submitted");
        require(bounty.claimant == _solutionProvider, "Mismatch in solution provider");

        bounty.status = BountyStatus.Resolved;

        if (_accepted) {
            (bool success, ) = payable(bounty.claimant).call{value: bounty.rewardAmount}("");
            require(success, "Failed to transfer bounty reward");
            _mintReputation(bounty.claimant, 15); // Reward for solving bounty
            _mintReputation(msg.sender, 5); // Reward for curator resolving bounty
        } else {
            // If rejected, bounty funds can be re-opened or withdrawn by sponsor
            // For now, it's just marked as resolved.
            _burnReputation(bounty.claimant, 5); // Penalty for rejected solution
        }

        emit BountyResolved(_bountyId, bounty.claimant, bounty.rewardAmount, _accepted);
    }

    /**
     * @notice The sponsor can withdraw funds from an expired and unclaimed bounty.
     * @param _bountyId The ID of the bounty.
     */
    function withdrawUnclaimedBounty(uint256 _bountyId) external nonReentrant {
        Bounty storage bounty = bounties[_bountyId];
        require(bounty.sponsor != address(0), "Bounty does not exist");
        require(bounty.sponsor == msg.sender, "Only the sponsor can withdraw");
        require(bounty.status == BountyStatus.Open, "Bounty not open for withdrawal");
        require(block.timestamp > bounty.deadline, "Bounty has not expired yet");

        bounty.status = BountyStatus.Withdrawn;
        (bool success, ) = payable(msg.sender).call{value: bounty.rewardAmount}("");
        require(success, "Failed to withdraw bounty funds");

        emit BountyWithdrawn(_bountyId, msg.sender);
    }

    // VII. Governance & Parameters

    /**
     * @notice Sets the minimum number of votes required for a curator nomination to succeed.
     * @param _minVotes The new minimum vote count.
     */
    function setMinCuratorNominationVotes(uint256 _minVotes) external onlyOwner {
        require(_minVotes > 0, "Minimum votes must be greater than 0");
        minVotesForCuratorAcceptance = _minVotes;
    }

    /**
     * @notice Sets the number of curator reviews needed for an artifact to be accepted.
     * @param _numReviews The new number of required reviews. Set to 0 to rely purely on AI.
     */
    function setRequiredCuratorReviews(uint8 _numReviews) external onlyOwner {
        requiredCuratorReviews = _numReviews;
    }

    /**
     * @notice Adjusts the influence (weight) of AI evaluations when determining an artifact's final status,
     *         relative to human reviews. (e.g., 50 means 50% AI, 50% human).
     * @param _weight The new AI oracle weight (0-100).
     */
    function setAIOracleWeight(uint8 _weight) external onlyOwner {
        require(_weight <= 100, "Weight must be between 0 and 100");
        aiOracleWeight = _weight;
    }

    // VIII. Utility & View Functions (Implicitly covered by artifact/bounty getters)
    // Additional specific view functions can be added if needed, e.g., getCuratorNominationVotes.
    function getCuratorNominationVotes(address _nominee) external view returns (uint256) {
        return curatorNominations[_nominee].votes;
    }

    // --- Internal Logic ---

    /**
     * @notice Internal function to evaluate an artifact's status (Accepted/Rejected) based on
     *         accumulated AI and curator scores, respecting configured weights and thresholds.
     * @param _artifactId The ID of the artifact.
     * @param _versionId The ID of the specific version to evaluate.
     * @return True if the artifact is accepted, false if rejected.
     */
    function _evaluateArtifactStatus(uint256 _artifactId, uint256 _versionId) internal view returns (bool) {
        Artifact storage artifact = artifacts[_artifactId];
        ArtifactVersion storage version = artifact.versions[_versionId];

        uint256 totalScore = 0;
        uint256 maxPossibleScore = 0;

        // Calculate AI score contribution
        if (version.aiEvaluationCount > 0) {
            uint256 avgAIScore = version.aiScoreSum / version.aiEvaluationCount;
            totalScore += (avgAIScore * aiOracleWeight) / 100;
            maxPossibleScore += aiOracleWeight;
        }

        // Calculate Curator score contribution
        if (version.curatorReviewCount > 0) {
            uint256 avgCuratorScore = version.curatorScoreSum / version.curatorReviewCount;
            totalScore += (avgCuratorScore * (100 - aiOracleWeight)) / 100;
            maxPossibleScore += (100 - aiOracleWeight);
        }

        // If no evaluations/reviews, cannot determine status
        if (maxPossibleScore == 0) {
            return false;
        }

        // Determine average combined score (out of 100)
        uint256 combinedAverageScore = (totalScore * 100) / maxPossibleScore;

        // Set a threshold for acceptance (e.g., 70 out of 100)
        uint256 acceptanceThreshold = 70; 
        
        return combinedAverageScore >= acceptanceThreshold;
    }
}
```