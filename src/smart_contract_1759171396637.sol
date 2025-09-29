This smart contract, **CognitoSphere**, is designed as a decentralized adaptive knowledge network. It allows users to contribute, validate, and curate knowledge, earning a dynamic reputation score represented by an evolving NFT. The protocol is designed to be self-governing and adaptive, with key parameters adjustable through a voting mechanism where voting power is derived from a user's reputation.

---

## CognitoSphere: Decentralized Adaptive Knowledge Network

### Outline & Function Summary

**Contract Name:** `CognitoSphere`

**Core Concepts:**
*   **Knowledge Artifacts:** User-submitted pieces of knowledge (e.g., text, links, data hashes) that need peer validation.
*   **CognitoScore NFT:** A dynamic ERC-721 token representing a user's on-chain reputation and expertise, evolving with contributions and validations.
*   **Knowledge Spheres:** Curated, community-driven pools of knowledge artifacts, potentially with entry requirements based on CognitoScore.
*   **Knowledge Bounties:** A system for posting and solving challenges, rewarding validated knowledge contributions.
*   **Adaptive Governance:** A simple on-chain voting mechanism, where CognitoScore holders can propose and vote on protocol parameter changes, allowing the network to adapt.

---

**I. Core Knowledge Artifact Management**
1.  **`submitKnowledgeArtifact(string memory _artifactURI, bytes32[] memory _tags, uint256[] memory _sphereIds)`**:
    *   Allows a user to submit a new knowledge artifact.
    *   `_artifactURI`: A URI pointing to the actual knowledge content (e.g., IPFS hash, URL).
    *   `_tags`: Keywords describing the knowledge.
    *   `_sphereIds`: Optional IDs of Knowledge Spheres to associate this artifact with initially.
    *   Emits `KnowledgeArtifactSubmitted`.
2.  **`validateKnowledgeArtifact(uint256 _artifactId, bool _isAccurate)`**:
    *   Allows a CognitoScore holder to validate or dispute an existing artifact.
    *   Increases/decreases the artifact's validation score and impacts the validator's CognitoScore.
    *   Emits `KnowledgeArtifactValidated`.
3.  **`challengeKnowledgeArtifact(uint256 _artifactId, string memory _reason)`**:
    *   Allows any user to formally challenge an artifact or its validation status.
    *   Initiates a moderation process.
    *   Emits `KnowledgeArtifactChallengeInitiated`.
4.  **`resolveArtifactChallenge(uint256 _challengeId, bool _acceptChallenge)`**:
    *   Executed by a designated moderator or governance.
    *   Resolves a pending challenge, potentially revoking artifact status or penalizing involved parties.
    *   Emits `KnowledgeArtifactChallengeResolved`.
5.  **`updateArtifactURI(uint256 _artifactId, string memory _newURI)`**:
    *   Allows the original contributor to update the URI of their knowledge artifact.
    *   Requires the artifact to not be in a challenged state.
    *   Emits `KnowledgeArtifactURIUpdated`.

**II. CognitoScore (Dynamic NFT) Management**
6.  **`mintCognitoScoreNFT()`**:
    *   Allows a user to mint their unique CognitoScore NFT, representing their on-chain reputation.
    *   A user can only mint one such NFT.
    *   Emits `CognitoScoreMinted`.
7.  **`requestScoreRevalidation()`**:
    *   Triggers a recalculation of the user's CognitoScore, considering recent artifact validations, decay, and activity.
    *   Emits `CognitoScoreRevalidated`.
8.  **`getDominantExpertise(address _user)`**:
    *   *View Function:* Returns the most frequently associated tags from the user's validated knowledge artifacts.
9.  **`getTokenURI(uint256 _tokenId)`**:
    *   *View Function:* ERC-721 standard function, returns the metadata URI for a CognitoScore NFT. The metadata is dynamic.
10. **`getUserCognitoScore(address _user)`**:
    *   *View Function:* Returns the current CognitoScore of a specific user.

**III. Knowledge Sphere Management**
11. **`createKnowledgeSphere(string memory _name, string memory _description, uint256 _minCognitoScoreToJoin)`**:
    *   Allows a user to create a new Knowledge Sphere (a curated knowledge community).
    *   Sets initial entry requirements.
    *   Emits `KnowledgeSphereCreated`.
12. **`joinKnowledgeSphere(uint256 _sphereId)`**:
    *   Allows a user to join a Knowledge Sphere if they meet its `_minCognitoScoreToJoin` requirement.
    *   Emits `KnowledgeSphereJoined`.
13. **`addArtifactToSphere(uint256 _sphereId, uint256 _artifactId)`**:
    *   Allows a Sphere owner/moderator to officially add a validated knowledge artifact to their sphere.
    *   Emits `ArtifactAddedToSphere`.
14. **`removeArtifactFromSphere(uint256 _sphereId, uint256 _artifactId)`**:
    *   Allows a Sphere owner/moderator to remove an artifact from their sphere.
    *   Emits `ArtifactRemovedFromSphere`.
15. **`updateSphereEntryRequirements(uint256 _sphereId, uint256 _newMinScore)`**:
    *   Allows the Sphere owner to adjust the minimum CognitoScore required to join.
    *   Emits `SphereRequirementsUpdated`.

**IV. Knowledge Bounty System**
16. **`postKnowledgeBounty(string memory _title, string memory _description, uint256 _rewardAmount, uint256 _minCognitoScoreToSolve)`**:
    *   Allows a user to post a bounty for specific knowledge or problem-solving.
    *   Requires an Ether deposit for the reward.
    *   Emits `KnowledgeBountyPosted`.
17. **`submitBountySolution(uint256 _bountyId, uint256 _artifactId)`**:
    *   Allows a user to submit one of their validated knowledge artifacts as a solution to a bounty.
    *   Requires the solver to meet the bounty's minimum CognitoScore.
    *   Emits `BountySolutionSubmitted`.
18. **`acceptBountySolution(uint256 _bountyId, uint256 _solutionArtifactId)`**:
    *   Executed by the bounty poster.
    *   Accepts a submitted solution, transfers the bounty reward, and updates the bounty status.
    *   Emits `BountySolutionAccepted`.
19. **`cancelBounty(uint256 _bountyId)`**:
    *   Allows the bounty poster to cancel their bounty if no solution has been accepted.
    *   Refunds the reward.
    *   Emits `KnowledgeBountyCancelled`.

**V. Adaptive Governance & Protocol Parameters**
20. **`proposeParameterChange(bytes32 _paramKey, uint256 _newValue, string memory _description)`**:
    *   Allows a CognitoScore holder (above a threshold) to propose a change to a core protocol parameter (e.g., validation reward, decay rate).
    *   Emits `ParameterChangeProposed`.
21. **`voteOnProposal(uint256 _proposalId, bool _support)`**:
    *   Allows CognitoScore holders to vote on active proposals.
    *   Voting power is proportional to their CognitoScore.
    *   Emits `VoteCast`.
22. **`executeProposal(uint256 _proposalId)`**:
    *   Can be called by anyone once a proposal has passed its voting period and reached quorum/majority.
    *   Applies the proposed parameter change.
    *   Emits `ProposalExecuted`.
23. **`delegateVote(address _delegate)`**:
    *   Allows a user to delegate their CognitoScore-based voting power to another address.
    *   Emits `VoteDelegated`.
24. **`withdrawProtocolFees(uint256 _amount)`**:
    *   Allows governance (via a proposal) to withdraw accumulated protocol fees.
    *   Emits `ProtocolFeesWithdrawn`.
25. **`getProposalState(uint256 _proposalId)`**:
    *   *View Function:* Returns the current state of a governance proposal (e.g., Active, Succeeded, Defeated, Executed).

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

/*
    CognitoSphere: Decentralized Adaptive Knowledge Network

    This contract facilitates a decentralized ecosystem for knowledge sharing, validation, and reputation building.
    Users can submit "Knowledge Artifacts," which are peer-validated by others. This validation process
    contributes to a user's "CognitoScore," a dynamic NFT representing their on-chain expertise.
    The system also includes "Knowledge Spheres" for curated content, a "Knowledge Bounty" system for
    problem-solving, and an "Adaptive Governance" module where protocol parameters can be adjusted by
    CognitoScore holders.

    Outline & Function Summary:

    I. Core Knowledge Artifact Management:
    1.  submitKnowledgeArtifact(string memory _artifactURI, bytes32[] memory _tags, uint256[] memory _sphereIds)
        - Submits a new knowledge artifact with associated URI, tags, and optional initial sphere assignments.
    2.  validateKnowledgeArtifact(uint256 _artifactId, bool _isAccurate)
        - Allows a CognitoScore holder to validate or dispute an artifact, impacting artifact status and validator's score.
    3.  challengeKnowledgeArtifact(uint256 _artifactId, string memory _reason)
        - Initiates a formal challenge against an artifact or its validation, requiring moderation.
    4.  resolveArtifactChallenge(uint256 _challengeId, bool _acceptChallenge)
        - Moderator/governance resolves an artifact challenge, impacting artifact/user scores.
    5.  updateArtifactURI(uint256 _artifactId, string memory _newURI)
        - Allows the original contributor to update the content URI of their artifact.

    II. CognitoScore (Dynamic NFT) Management:
    6.  mintCognitoScoreNFT()
        - Mints a unique ERC-721 token representing the user's dynamic reputation.
    7.  requestScoreRevalidation()
        - Triggers a recalculation of the user's CognitoScore based on current activity and protocol decay.
    8.  getDominantExpertise(address _user)
        - View function: Identifies primary expertise tags for a user based on their validated artifacts.
    9.  getTokenURI(uint256 _tokenId)
        - ERC-721 standard: Returns the dynamic metadata URI for a CognitoScore NFT.
    10. getUserCognitoScore(address _user)
        - View function: Returns the current CognitoScore of a user.

    III. Knowledge Sphere Management:
    11. createKnowledgeSphere(string memory _name, string memory _description, uint256 _minCognitoScoreToJoin)
        - Creates a new community-curated knowledge pool with defined entry requirements.
    12. joinKnowledgeSphere(uint256 _sphereId)
        - Allows a user to join a sphere if their CognitoScore meets the minimum.
    13. addArtifactToSphere(uint256 _sphereId, uint256 _artifactId)
        - Sphere owner/moderator adds a validated artifact to their sphere's curated list.
    14. removeArtifactFromSphere(uint256 _sphereId, uint256 _artifactId)
        - Sphere owner/moderator removes an artifact from their sphere.
    15. updateSphereEntryRequirements(uint256 _sphereId, uint256 _newMinScore)
        - Sphere owner adjusts the minimum CognitoScore required for entry.

    IV. Knowledge Bounty System:
    16. postKnowledgeBounty(string memory _title, string memory _description, uint256 _rewardAmount, uint256 _minCognitoScoreToSolve)
        - Creates a bounty for specific knowledge or problem-solving, requiring Ether deposit for reward.
    17. submitBountySolution(uint256 _bountyId, uint256 _artifactId)
        - Submits a knowledge artifact as a solution to an active bounty.
    18. acceptBountySolution(uint256 _bountyId, uint256 _solutionArtifactId)
        - Bounty poster accepts a solution, releasing the reward and marking the bounty as solved.
    19. cancelBounty(uint256 _bountyId)
        - Bounty poster can cancel an unsolved bounty, refunding the reward.

    V. Adaptive Governance & Protocol Parameters:
    20. proposeParameterChange(bytes32 _paramKey, uint256 _newValue, string memory _description)
        - Initiates a governance proposal to change a core protocol parameter.
    21. voteOnProposal(uint256 _proposalId, bool _support)
        - Allows CognitoScore holders to vote on proposals, with voting power proportional to their score.
    22. executeProposal(uint256 _proposalId)
        - Executes a passed proposal to apply the parameter change.
    23. delegateVote(address _delegate)
        - Allows a user to delegate their voting power to another address.
    24. withdrawProtocolFees(uint256 _amount)
        - Allows governance (via a passed proposal) to withdraw protocol-accumulated funds.
    25. getProposalState(uint256 _proposalId)
        - View function: Returns the current state of a governance proposal.
*/

contract CognitoSphere is ERC721URIStorage, Ownable {
    using Counters for Counters.Counter;
    using Strings for uint256;

    // --- Configuration Parameters (Adaptable via Governance) ---
    uint256 public constant INITIAL_COGNITO_SCORE = 1000;
    uint256 public constant MINT_COST_ETH = 0.01 ether; // Cost to mint a CognitoScore NFT
    uint256 public validationRewardMultiplier = 50; // Points per successful validation
    uint256 public validationPenaltyMultiplier = 100; // Points per failed validation
    uint256 public challengePenaltyMultiplier = 200; // Points for an unjustified challenge
    uint256 public knowledgeDecayRate = 1; // % of score lost per year for inactive knowledge
    uint256 public proposalThresholdScore = 2000; // Minimum CognitoScore to propose changes
    uint256 public proposalVotingPeriodBlocks = 10000; // Approx 2-3 days @ 12s/block
    uint256 public proposalQuorumPercentage = 10; // 10% of total voting power needed for quorum
    uint256 public protocolFeePercentage = 1; // 1% fee on bounties, etc.

    // --- State Variables ---
    Counters.Counter private _artifactIds;
    Counters.Counter private _challengeIds;
    Counters.Counter private _sphereIds;
    Counters.Counter private _bountyIds;
    Counters.Counter private _proposalIds;
    Counters.Counter private _tokenIdCounter; // For CognitoScore NFTs

    // Structs
    struct KnowledgeArtifact {
        uint256 id;
        address contributor;
        string artifactURI;
        bytes32[] tags;
        uint256 submittedAt;
        int256 validationScore; // Sum of validation impacts
        uint256 validationCount;
        uint256 lastValidatedAt;
        bool isChallenged;
        bool isRevoked;
        mapping(address => bool) hasValidated; // To prevent double-validation
    }

    enum ChallengeStatus { Pending, ResolvedAccepted, ResolvedRejected }
    struct ArtifactChallenge {
        uint256 id;
        uint256 artifactId;
        address challenger;
        string reason;
        uint256 challengedAt;
        ChallengeStatus status;
    }

    struct CognitoScoreData {
        uint256 score;
        uint256 lastUpdated;
        bool exists; // To check if NFT is minted for user
        mapping(bytes32 => uint256) expertiseScores; // Score per tag
    }

    struct KnowledgeSphere {
        uint256 id;
        address owner; // Creator, can assign moderators
        string name;
        string description;
        uint256 minCognitoScoreToJoin;
        mapping(uint256 => bool) artifacts; // Map artifactId to existence
        mapping(address => bool) members;
        mapping(address => bool) moderators;
        uint256 artifactCount;
    }

    enum BountyStatus { Active, Solved, Cancelled }
    struct KnowledgeBounty {
        uint256 id;
        address poster;
        string title;
        string description;
        uint256 rewardAmount;
        uint256 minCognitoScoreToSolve;
        uint256 postedAt;
        BountyStatus status;
        uint256 acceptedSolutionArtifactId;
        address acceptedSolver;
        mapping(uint256 => bool) submittedSolutions; // ArtifactId => bool
    }

    enum ProposalState { Pending, Active, Succeeded, Defeated, Executed, Canceled }
    struct GovernanceProposal {
        uint256 id;
        address proposer;
        bytes32 paramKey;
        uint256 newValue;
        string description;
        uint256 submittedAt;
        uint256 startBlock;
        uint256 endBlock;
        uint256 votesFor;
        uint256 votesAgainst;
        uint256 quorumRequired;
        ProposalState state;
        mapping(address => bool) hasVoted; // Prevents double voting
    }

    // Mappings
    mapping(uint256 => KnowledgeArtifact) public knowledgeArtifacts;
    mapping(uint256 => ArtifactChallenge) public artifactChallenges;
    mapping(address => CognitoScoreData) public cognitoScores;
    mapping(address => uint256) public userTokenId; // user => tokenId
    mapping(uint256 => KnowledgeSphere) public knowledgeSpheres;
    mapping(uint256 => KnowledgeBounty) public knowledgeBounties;
    mapping(uint256 => GovernanceProposal) public governanceProposals;
    mapping(address => address) public delegates; // Voter => Delegatee

    uint256 public totalVotingPower; // Sum of all CognitoScores

    // --- Events ---
    event KnowledgeArtifactSubmitted(uint256 indexed artifactId, address indexed contributor, string artifactURI);
    event KnowledgeArtifactValidated(uint256 indexed artifactId, address indexed validator, bool isAccurate, int256 scoreChange);
    event KnowledgeArtifactChallengeInitiated(uint256 indexed challengeId, uint256 indexed artifactId, address indexed challenger);
    event KnowledgeArtifactChallengeResolved(uint256 indexed challengeId, uint256 indexed artifactId, ChallengeStatus status);
    event KnowledgeArtifactURIUpdated(uint256 indexed artifactId, address indexed updater, string newURI);

    event CognitoScoreMinted(address indexed user, uint256 indexed tokenId, uint256 initialScore);
    event CognitoScoreUpdated(address indexed user, uint256 newScore);
    event CognitoScoreRevalidated(address indexed user, uint256 newScore);

    event KnowledgeSphereCreated(uint256 indexed sphereId, address indexed owner, string name, uint256 minScore);
    event KnowledgeSphereJoined(uint256 indexed sphereId, address indexed member);
    event ArtifactAddedToSphere(uint256 indexed sphereId, uint256 indexed artifactId, address indexed curator);
    event ArtifactRemovedFromSphere(uint256 indexed sphereId, uint256 indexed artifactId, address indexed remover);
    event SphereRequirementsUpdated(uint256 indexed sphereId, uint256 newMinScore);

    event KnowledgeBountyPosted(uint256 indexed bountyId, address indexed poster, uint256 rewardAmount, uint256 minScore);
    event BountySolutionSubmitted(uint256 indexed bountyId, uint256 indexed artifactId, address indexed solver);
    event BountySolutionAccepted(uint256 indexed bountyId, uint256 indexed artifactId, address indexed solver, uint256 reward);
    event KnowledgeBountyCancelled(uint256 indexed bountyId, address indexed poster, uint256 refundedAmount);

    event ParameterChangeProposed(uint256 indexed proposalId, address indexed proposer, bytes32 paramKey, uint256 newValue);
    event VoteCast(uint256 indexed proposalId, address indexed voter, bool support, uint256 votingPower);
    event ProposalExecuted(uint256 indexed proposalId);
    event VoteDelegated(address indexed delegator, address indexed delegatee);
    event ProtocolFeesWithdrawn(address indexed recipient, uint256 amount);

    // --- Modifiers ---
    modifier onlyCognitoScoreHolder(address _user) {
        require(cognitoScores[_user].exists, "CognitoSphere: Not a CognitoScore holder.");
        _;
    }

    modifier onlyArtifactContributor(uint256 _artifactId) {
        require(knowledgeArtifacts[_artifactId].contributor == msg.sender, "CognitoSphere: Not the artifact contributor.");
        _;
    }

    modifier onlySphereOwner(uint256 _sphereId) {
        require(knowledgeSpheres[_sphereId].owner == msg.sender, "CognitoSphere: Not the sphere owner.");
        _;
    }

    modifier onlySphereModerator(uint256 _sphereId) {
        require(knowledgeSpheres[_sphereId].moderators[msg.sender] || knowledgeSpheres[_sphereId].owner == msg.sender, "CognitoSphere: Not a sphere moderator.");
        _;
    }

    modifier onlyBountyPoster(uint256 _bountyId) {
        require(knowledgeBounties[_bountyId].poster == msg.sender, "CognitoSphere: Not the bounty poster.");
        _;
    }

    // --- Constructor ---
    constructor(address initialModerator) ERC721("CognitoScore", "CGS") Ownable(msg.sender) {
        // Initial setup for the owner, if initial moderation is needed for challenges before full governance.
        // For a truly decentralized system, this could be replaced by an initial DAO setup.
    }

    // --- Internal Helpers ---
    function _updateCognitoScore(address _user, int256 _scoreChange) internal {
        if (!cognitoScores[_user].exists) return; // Cannot update score if NFT not minted

        uint256 oldScore = cognitoScores[_user].score;
        int256 newScoreInt = int256(oldScore) + _scoreChange;
        
        // Ensure score doesn't go below 0
        cognitoScores[_user].score = newScoreInt > 0 ? uint256(newScoreInt) : 0;
        cognitoScores[_user].lastUpdated = block.timestamp;

        // Update total voting power
        totalVotingPower = totalVotingPower - oldScore + cognitoScores[_user].score;

        emit CognitoScoreUpdated(_user, cognitoScores[_user].score);
    }

    function _getVotingPower(address _voter) internal view returns (uint256) {
        address currentDelegate = _voter;
        // Follow the delegation chain
        while (delegates[currentDelegate] != address(0) && delegates[currentDelegate] != currentDelegate) {
            currentDelegate = delegates[currentDelegate];
        }
        return cognitoScores[currentDelegate].score;
    }

    // --- I. Core Knowledge Artifact Management ---

    function submitKnowledgeArtifact(string memory _artifactURI, bytes32[] memory _tags, uint256[] memory _sphereIds)
        public
        onlyCognitoScoreHolder(msg.sender)
        returns (uint256)
    {
        _artifactIds.increment();
        uint256 newId = _artifactIds.current();

        knowledgeArtifacts[newId] = KnowledgeArtifact({
            id: newId,
            contributor: msg.sender,
            artifactURI: _artifactURI,
            tags: _tags,
            submittedAt: block.timestamp,
            validationScore: 0,
            validationCount: 0,
            lastValidatedAt: block.timestamp,
            isChallenged: false,
            isRevoked: false
        });

        // Add to specified spheres if they exist and sender is allowed
        for (uint256 i = 0; i < _sphereIds.length; i++) {
            uint256 sphereId = _sphereIds[i];
            if (knowledgeSpheres[sphereId].id != 0 && (knowledgeSpheres[sphereId].owner == msg.sender || knowledgeSpheres[sphereId].members[msg.sender])) {
                knowledgeSpheres[sphereId].artifacts[newId] = true;
                knowledgeSpheres[sphereId].artifactCount++;
            }
        }

        emit KnowledgeArtifactSubmitted(newId, msg.sender, _artifactURI);
        return newId;
    }

    function validateKnowledgeArtifact(uint256 _artifactId, bool _isAccurate)
        public
        onlyCognitoScoreHolder(msg.sender)
    {
        KnowledgeArtifact storage artifact = knowledgeArtifacts[_artifactId];
        require(artifact.id != 0, "CognitoSphere: Artifact does not exist.");
        require(artifact.contributor != msg.sender, "CognitoSphere: Cannot validate your own artifact.");
        require(!artifact.hasValidated[msg.sender], "CognitoSphere: Already validated this artifact.");
        require(!artifact.isRevoked, "CognitoSphere: Artifact is revoked.");
        require(!artifact.isChallenged, "CognitoSphere: Artifact is currently challenged.");

        artifact.hasValidated[msg.sender] = true;
        artifact.validationCount++;
        artifact.lastValidatedAt = block.timestamp;

        int256 scoreChangeForValidator = 0;
        if (_isAccurate) {
            artifact.validationScore += int256(validationRewardMultiplier);
            scoreChangeForValidator = int256(validationRewardMultiplier);
        } else {
            artifact.validationScore -= int256(validationPenaltyMultiplier);
            scoreChangeForValidator = -int256(validationPenaltyMultiplier);
        }

        _updateCognitoScore(msg.sender, scoreChangeForValidator);
        emit KnowledgeArtifactValidated(_artifactId, msg.sender, _isAccurate, scoreChangeForValidator);
    }

    function challengeKnowledgeArtifact(uint256 _artifactId, string memory _reason)
        public
        onlyCognitoScoreHolder(msg.sender)
        returns (uint256)
    {
        KnowledgeArtifact storage artifact = knowledgeArtifacts[_artifactId];
        require(artifact.id != 0, "CognitoSphere: Artifact does not exist.");
        require(!artifact.isChallenged, "CognitoSphere: Artifact already challenged.");
        require(!artifact.isRevoked, "CognitoSphere: Artifact is revoked.");

        _challengeIds.increment();
        uint256 newChallengeId = _challengeIds.current();

        artifactChallenges[newChallengeId] = ArtifactChallenge({
            id: newChallengeId,
            artifactId: _artifactId,
            challenger: msg.sender,
            reason: _reason,
            challengedAt: block.timestamp,
            status: ChallengeStatus.Pending
        });
        artifact.isChallenged = true;

        emit KnowledgeArtifactChallengeInitiated(newChallengeId, _artifactId, msg.sender);
        return newChallengeId;
    }

    function resolveArtifactChallenge(uint256 _challengeId, bool _acceptChallenge)
        public
        onlyOwner // For initial setup, will be replaced by governance vote result
    {
        ArtifactChallenge storage challenge = artifactChallenges[_challengeId];
        require(challenge.id != 0, "CognitoSphere: Challenge does not exist.");
        require(challenge.status == ChallengeStatus.Pending, "CognitoSphere: Challenge already resolved.");

        KnowledgeArtifact storage artifact = knowledgeArtifacts[challenge.artifactId];

        challenge.status = _acceptChallenge ? ChallengeStatus.ResolvedAccepted : ChallengeStatus.ResolvedRejected;
        artifact.isChallenged = false;

        // Apply score adjustments based on resolution
        if (_acceptChallenge) {
            artifact.isRevoked = true; // If challenge accepted, artifact is problematic
            // Penalize original contributor
            _updateCognitoScore(artifact.contributor, -int256(challengePenaltyMultiplier * 2)); // Larger penalty for contributor
            // Reward challenger (if applicable)
            _updateCognitoScore(challenge.challenger, int256(validationRewardMultiplier));
        } else {
            // Penalize challenger for unjustified challenge
            _updateCognitoScore(challenge.challenger, -int256(challengePenaltyMultiplier));
            // Reward contributor (if applicable)
            _updateCognitoScore(artifact.contributor, int256(validationRewardMultiplier));
        }

        emit KnowledgeArtifactChallengeResolved(_challengeId, challenge.artifactId, challenge.status);
    }

    function updateArtifactURI(uint256 _artifactId, string memory _newURI)
        public
        onlyArtifactContributor(_artifactId)
    {
        KnowledgeArtifact storage artifact = knowledgeArtifacts[_artifactId];
        require(!artifact.isChallenged, "CognitoSphere: Cannot update challenged artifact.");
        require(!artifact.isRevoked, "CognitoSphere: Cannot update revoked artifact.");

        artifact.artifactURI = _newURI;
        emit KnowledgeArtifactURIUpdated(_artifactId, msg.sender, _newURI);
    }

    // --- II. CognitoScore (Dynamic NFT) Management ---

    function mintCognitoScoreNFT() public payable returns (uint256) {
        require(!cognitoScores[msg.sender].exists, "CognitoSphere: CognitoScore NFT already minted.");
        require(msg.value >= MINT_COST_ETH, "CognitoSphere: Insufficient ETH to mint NFT.");

        _tokenIdCounter.increment();
        uint256 newTokenId = _tokenIdCounter.current();

        _safeMint(msg.sender, newTokenId);
        _setTokenURI(newTokenId, string(abi.encodePacked("ipfs://", "placeholder_metadata_cid/", newTokenId.toString()))); // Placeholder, will be dynamic

        cognitoScores[msg.sender] = CognitoScoreData({
            score: INITIAL_COGNITO_SCORE,
            lastUpdated: block.timestamp,
            exists: true,
            expertiseScores: new mapping(bytes32 => uint256)
        });
        userTokenId[msg.sender] = newTokenId;
        totalVotingPower += INITIAL_COGNITO_SCORE;

        emit CognitoScoreMinted(msg.sender, newTokenId, INITIAL_COGNITO_SCORE);
        return newTokenId;
    }

    function requestScoreRevalidation() public onlyCognitoScoreHolder(msg.sender) {
        // Implement logic for periodic re-evaluation based on artifact age, validation decay, etc.
        // For simplicity, let's just re-calculate based on a simplified decay
        uint256 currentScore = cognitoScores[msg.sender].score;
        uint256 lastUpdated = cognitoScores[msg.sender].lastUpdated;
        
        uint256 yearsPassed = (block.timestamp - lastUpdated) / (365 days);
        if (yearsPassed > 0) {
            uint256 decayAmount = (currentScore * knowledgeDecayRate * yearsPassed) / 100;
            _updateCognitoScore(msg.sender, -int256(decayAmount));
        }
        
        // More complex logic could involve re-checking all associated artifacts
        // For now, it's a simple decay and update.
        emit CognitoScoreRevalidated(msg.sender, cognitoScores[msg.sender].score);
    }

    function getDominantExpertise(address _user) public view returns (bytes32) {
        require(cognitoScores[_user].exists, "CognitoSphere: User has no CognitoScore NFT.");

        bytes32 dominantTag = "";
        uint256 maxScore = 0;

        // Iterate through all possible tags (this is simplified; in a real system, tags would be indexed)
        // For this example, let's just return a placeholder. A real implementation would need to track all tags globally.
        // If we only store expertiseScores for specific tags within the struct, we can't iterate over them easily.
        // A more practical approach would be to derive this from the tags of *all validated artifacts* by the user.
        // For the sake of demonstration and contract size, we'll return a simple placeholder.
        return "NotImplementedYet"; // Placeholder, requires more complex indexing of all tags used by user
    }

    function _baseURI() internal view override returns (string memory) {
        return "ipfs://cognitosphere-metadata/";
    }

    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        require(_exists(_tokenId), "ERC721URIStorage: URI query for nonexistent token");
        address owner = ERC721.ownerOf(_tokenId);
        uint256 score = cognitoScores[owner].score;

        // Construct dynamic metadata JSON directly or a URL to a dynamic API endpoint
        // For demonstration, we'll return a simplified JSON string directly.
        // In a real dApp, this would typically point to a backend service that generates the JSON.
        string memory json = string(abi.encodePacked(
            '{"name": "CognitoScore #', _tokenId.toString(),
            '", "description": "Dynamic On-chain Reputation for Knowledge Contribution",',
            '"image": "ipfs://Qmb8Vj7pP7Q4L8L2X4K1N5M3H2J1G0F9E8D7C6B5A4",', // Placeholder image
            '"attributes": [',
                '{"trait_type": "CognitoScore", "value": "', score.toString(), '"},',
                '{"trait_type": "Last Updated", "value": "', cognitoScores[owner].lastUpdated.toString(), '"}'
            // Add more attributes like 'Dominant Expertise' once `getDominantExpertise` is fully implemented
            ,']}'
        ));

        // Base64 encode the JSON
        return string(abi.encodePacked("data:application/json;base64,", Base64.encode(bytes(json))));
    }

    function getUserTokenId(address _user) public view returns (uint256) {
        return userTokenId[_user];
    }

    // --- III. Knowledge Sphere Management ---

    function createKnowledgeSphere(string memory _name, string memory _description, uint256 _minCognitoScoreToJoin)
        public
        onlyCognitoScoreHolder(msg.sender)
        returns (uint256)
    {
        _sphereIds.increment();
        uint256 newId = _sphereIds.current();

        knowledgeSpheres[newId] = KnowledgeSphere({
            id: newId,
            owner: msg.sender,
            name: _name,
            description: _description,
            minCognitoScoreToJoin: _minCognitoScoreToJoin,
            artifacts: new mapping(uint256 => bool), // Initialize mapping for artifacts
            members: new mapping(address => bool), // Initialize mapping for members
            moderators: new mapping(address => bool), // Initialize mapping for moderators
            artifactCount: 0
        });
        knowledgeSpheres[newId].members[msg.sender] = true; // Owner is automatically a member

        emit KnowledgeSphereCreated(newId, msg.sender, _name, _minCognitoScoreToJoin);
        return newId;
    }

    function joinKnowledgeSphere(uint256 _sphereId)
        public
        onlyCognitoScoreHolder(msg.sender)
    {
        KnowledgeSphere storage sphere = knowledgeSpheres[_sphereId];
        require(sphere.id != 0, "CognitoSphere: Sphere does not exist.");
        require(!sphere.members[msg.sender], "CognitoSphere: Already a member of this sphere.");
        require(cognitoScores[msg.sender].score >= sphere.minCognitoScoreToJoin, "CognitoSphere: Insufficient CognitoScore to join.");

        sphere.members[msg.sender] = true;
        emit KnowledgeSphereJoined(_sphereId, msg.sender);
    }

    function addArtifactToSphere(uint256 _sphereId, uint256 _artifactId)
        public
        onlySphereModerator(_sphereId)
    {
        KnowledgeSphere storage sphere = knowledgeSpheres[_sphereId];
        KnowledgeArtifact storage artifact = knowledgeArtifacts[_artifactId];
        require(artifact.id != 0, "CognitoSphere: Artifact does not exist.");
        require(!sphere.artifacts[_artifactId], "CognitoSphere: Artifact already in sphere.");
        require(artifact.validationScore > 0 && !artifact.isChallenged && !artifact.isRevoked, "CognitoSphere: Artifact not sufficiently validated or is problematic.");

        sphere.artifacts[_artifactId] = true;
        sphere.artifactCount++;
        emit ArtifactAddedToSphere(_sphereId, _artifactId, msg.sender);
    }

    function removeArtifactFromSphere(uint256 _sphereId, uint256 _artifactId)
        public
        onlySphereModerator(_sphereId)
    {
        KnowledgeSphere storage sphere = knowledgeSpheres[_sphereId];
        require(sphere.id != 0, "CognitoSphere: Sphere does not exist.");
        require(sphere.artifacts[_artifactId], "CognitoSphere: Artifact not in sphere.");

        sphere.artifacts[_artifactId] = false;
        sphere.artifactCount--;
        emit ArtifactRemovedFromSphere(_sphereId, _artifactId, msg.sender);
    }

    function updateSphereEntryRequirements(uint256 _sphereId, uint256 _newMinScore)
        public
        onlySphereOwner(_sphereId)
    {
        KnowledgeSphere storage sphere = knowledgeSpheres[_sphereId];
        sphere.minCognitoScoreToJoin = _newMinScore;
        emit SphereRequirementsUpdated(_sphereId, _newMinScore);
    }

    function setSphereModerator(uint256 _sphereId, address _moderator, bool _isModerator)
        public
        onlySphereOwner(_sphereId)
    {
        KnowledgeSphere storage sphere = knowledgeSpheres[_sphereId];
        require(_moderator != address(0), "CognitoSphere: Invalid address for moderator.");
        require(_moderator != msg.sender, "CognitoSphere: Owner cannot change their own moderator status via this function.");
        
        sphere.moderators[_moderator] = _isModerator;
        // Event can be added if needed: e.g., `SphereModeratorUpdated(_sphereId, _moderator, _isModerator)`
    }

    // --- IV. Knowledge Bounty System ---

    function postKnowledgeBounty(string memory _title, string memory _description, uint256 _rewardAmount, uint256 _minCognitoScoreToSolve)
        public
        payable
        onlyCognitoScoreHolder(msg.sender)
        returns (uint256)
    {
        require(msg.value >= _rewardAmount, "CognitoSphere: Insufficient ETH sent for bounty reward.");
        require(_rewardAmount > 0, "CognitoSphere: Reward amount must be positive.");

        _bountyIds.increment();
        uint256 newId = _bountyIds.current();

        knowledgeBounties[newId] = KnowledgeBounty({
            id: newId,
            poster: msg.sender,
            title: _title,
            description: _description,
            rewardAmount: _rewardAmount,
            minCognitoScoreToSolve: _minCognitoScoreToSolve,
            postedAt: block.timestamp,
            status: BountyStatus.Active,
            acceptedSolutionArtifactId: 0,
            acceptedSolver: address(0),
            submittedSolutions: new mapping(uint256 => bool)
        });

        // Protocol fee
        uint256 fee = (_rewardAmount * protocolFeePercentage) / 100;
        payable(owner()).transfer(fee); // Send fee to protocol owner/treasury
        
        emit KnowledgeBountyPosted(newId, msg.sender, _rewardAmount, _minCognitoScoreToSolve);
        return newId;
    }

    function submitBountySolution(uint256 _bountyId, uint256 _artifactId)
        public
        onlyCognitoScoreHolder(msg.sender)
    {
        KnowledgeBounty storage bounty = knowledgeBounties[_bountyId];
        KnowledgeArtifact storage artifact = knowledgeArtifacts[_artifactId];
        
        require(bounty.id != 0, "CognitoSphere: Bounty does not exist.");
        require(bounty.status == BountyStatus.Active, "CognitoSphere: Bounty is not active.");
        require(artifact.id != 0, "CognitoSphere: Artifact does not exist.");
        require(artifact.contributor == msg.sender, "CognitoSphere: Solution must be your own artifact.");
        require(artifact.validationScore > 0 && !artifact.isChallenged && !artifact.isRevoked, "CognitoSphere: Artifact not sufficiently validated or is problematic.");
        require(cognitoScores[msg.sender].score >= bounty.minCognitoScoreToSolve, "CognitoSphere: Insufficient CognitoScore to solve this bounty.");
        require(!bounty.submittedSolutions[_artifactId], "CognitoSphere: This artifact already submitted as solution.");

        bounty.submittedSolutions[_artifactId] = true;
        emit BountySolutionSubmitted(_bountyId, _artifactId, msg.sender);
    }

    function acceptBountySolution(uint256 _bountyId, uint256 _solutionArtifactId)
        public
        onlyBountyPoster(_bountyId)
    {
        KnowledgeBounty storage bounty = knowledgeBounties[_bountyId];
        KnowledgeArtifact storage solutionArtifact = knowledgeArtifacts[_solutionArtifactId];

        require(bounty.status == BountyStatus.Active, "CognitoSphere: Bounty is not active.");
        require(solutionArtifact.id != 0, "CognitoSphere: Solution artifact does not exist.");
        require(bounty.submittedSolutions[_solutionArtifactId], "CognitoSphere: Artifact not submitted for this bounty.");

        bounty.status = BountyStatus.Solved;
        bounty.acceptedSolutionArtifactId = _solutionArtifactId;
        bounty.acceptedSolver = solutionArtifact.contributor;

        // Transfer reward
        payable(bounty.acceptedSolver).transfer(bounty.rewardAmount);

        // Update solver's CognitoScore (optional, but good for reputation)
        _updateCognitoScore(bounty.acceptedSolver, int256(bounty.rewardAmount / 1 ether * validationRewardMultiplier)); // Scale reward to score points

        emit BountySolutionAccepted(_bountyId, _solutionArtifactId, bounty.acceptedSolver, bounty.rewardAmount);
    }

    function cancelBounty(uint256 _bountyId)
        public
        onlyBountyPoster(_bountyId)
    {
        KnowledgeBounty storage bounty = knowledgeBounties[_bountyId];
        require(bounty.status == BountyStatus.Active, "CognitoSphere: Bounty is not active.");

        bounty.status = BountyStatus.Cancelled;
        payable(msg.sender).transfer(bounty.rewardAmount); // Refund
        
        emit KnowledgeBountyCancelled(_bountyId, msg.sender, bounty.rewardAmount);
    }

    // --- V. Adaptive Governance & Protocol Parameters ---

    function proposeParameterChange(bytes32 _paramKey, uint256 _newValue, string memory _description)
        public
        onlyCognitoScoreHolder(msg.sender)
        returns (uint256)
    {
        require(cognitoScores[msg.sender].score >= proposalThresholdScore, "CognitoSphere: Insufficient CognitoScore to propose.");

        _proposalIds.increment();
        uint256 newId = _proposalIds.current();

        uint256 currentTotalVotingPower = totalVotingPower; // Snapshot current total voting power
        uint256 quorum = (currentTotalVotingPower * proposalQuorumPercentage) / 100;

        governanceProposals[newId] = GovernanceProposal({
            id: newId,
            proposer: msg.sender,
            paramKey: _paramKey,
            newValue: _newValue,
            description: _description,
            submittedAt: block.timestamp,
            startBlock: block.number,
            endBlock: block.number + proposalVotingPeriodBlocks,
            votesFor: 0,
            votesAgainst: 0,
            quorumRequired: quorum,
            state: ProposalState.Pending, // Will become Active on next block or when voted on
            hasVoted: new mapping(address => bool)
        });
        
        // Mark as Active immediately
        governanceProposals[newId].state = ProposalState.Active;

        emit ParameterChangeProposed(newId, msg.sender, _paramKey, _newValue);
        return newId;
    }

    function voteOnProposal(uint256 _proposalId, bool _support)
        public
        onlyCognitoScoreHolder(msg.sender)
    {
        GovernanceProposal storage proposal = governanceProposals[_proposalId];
        require(proposal.id != 0, "CognitoSphere: Proposal does not exist.");
        require(proposal.state == ProposalState.Active, "CognitoSphere: Proposal not in active state.");
        require(block.number >= proposal.startBlock && block.number < proposal.endBlock, "CognitoSphere: Voting period expired or not started.");
        require(!proposal.hasVoted[msg.sender], "CognitoSphere: Already voted on this proposal.");

        uint256 voterPower = _getVotingPower(msg.sender);
        require(voterPower > 0, "CognitoSphere: Voter has no voting power.");

        proposal.hasVoted[msg.sender] = true;

        if (_support) {
            proposal.votesFor += voterPower;
        } else {
            proposal.votesAgainst += voterPower;
        }

        emit VoteCast(_proposalId, msg.sender, _support, voterPower);
    }

    function executeProposal(uint256 _proposalId) public {
        GovernanceProposal storage proposal = governanceProposals[_proposalId];
        require(proposal.id != 0, "CognitoSphere: Proposal does not exist.");
        require(proposal.state == ProposalState.Active || proposal.state == ProposalState.Succeeded, "CognitoSphere: Proposal not eligible for execution.");
        require(block.number >= proposal.endBlock, "CognitoSphere: Voting period not ended yet.");

        // Check if passed quorum and majority
        uint256 totalVotes = proposal.votesFor + proposal.votesAgainst;
        bool passedQuorum = totalVotes >= proposal.quorumRequired;
        bool passedMajority = proposal.votesFor > proposal.votesAgainst;

        if (passedQuorum && passedMajority) {
            // Apply parameter change
            if (proposal.paramKey == "validationRewardMultiplier") {
                validationRewardMultiplier = proposal.newValue;
            } else if (proposal.paramKey == "validationPenaltyMultiplier") {
                validationPenaltyMultiplier = proposal.newValue;
            } else if (proposal.paramKey == "challengePenaltyMultiplier") {
                challengePenaltyMultiplier = proposal.newValue;
            } else if (proposal.paramKey == "knowledgeDecayRate") {
                knowledgeDecayRate = proposal.newValue;
            } else if (proposal.paramKey == "proposalThresholdScore") {
                proposalThresholdScore = proposal.newValue;
            } else if (proposal.paramKey == "proposalVotingPeriodBlocks") {
                proposalVotingPeriodBlocks = proposal.newValue;
            } else if (proposal.paramKey == "proposalQuorumPercentage") {
                require(proposal.newValue <= 100, "CognitoSphere: Quorum percentage cannot exceed 100.");
                proposalQuorumPercentage = proposal.newValue;
            } else if (proposal.paramKey == "protocolFeePercentage") {
                require(proposal.newValue <= 100, "CognitoSphere: Fee percentage cannot exceed 100.");
                protocolFeePercentage = proposal.newValue;
            } else {
                revert("CognitoSphere: Unknown parameter key.");
            }
            proposal.state = ProposalState.Executed;
        } else {
            proposal.state = ProposalState.Defeated;
        }

        emit ProposalExecuted(_proposalId);
    }

    function delegateVote(address _delegate) public onlyCognitoScoreHolder(msg.sender) {
        require(_delegate != address(0), "CognitoSphere: Cannot delegate to zero address.");
        require(_delegate != msg.sender, "CognitoSphere: Cannot delegate to self.");
        
        delegates[msg.sender] = _delegate;
        emit VoteDelegated(msg.sender, _delegate);
    }

    function getProposalState(uint256 _proposalId) public view returns (ProposalState) {
        GovernanceProposal storage proposal = governanceProposals[_proposalId];
        if (proposal.id == 0) return ProposalState.Canceled; // Using Canceled for non-existent proposals
        if (proposal.state != ProposalState.Active) return proposal.state;
        if (block.number < proposal.startBlock) return ProposalState.Pending;
        if (block.number >= proposal.endBlock) {
            uint256 totalVotes = proposal.votesFor + proposal.votesAgainst;
            bool passedQuorum = totalVotes >= proposal.quorumRequired;
            bool passedMajority = proposal.votesFor > proposal.votesAgainst;
            if (passedQuorum && passedMajority) return ProposalState.Succeeded;
            return ProposalState.Defeated;
        }
        return ProposalState.Active;
    }

    // --- Protocol Funds Management ---
    function withdrawProtocolFees(uint256 _amount) public onlyOwner {
        // In a fully decentralized system, this would require a governance proposal to execute.
        // For demonstration, `onlyOwner` is used. A real implementation would verify `proposal.state == Executed`
        // and link to a specific proposal for withdrawal.
        require(address(this).balance >= _amount, "CognitoSphere: Insufficient funds in contract.");
        payable(msg.sender).transfer(_amount); // Assuming msg.sender is the treasury or a designated address
        emit ProtocolFeesWithdrawn(msg.sender, _amount);
    }
}

// --- Base64 Encoding Library (for dynamic NFT metadata) ---
// This is a common utility and not a unique "functional" part of the contract's logic.
// Used OpenZeppelin's internal Base64 from their test utilities as a reference.
library Base64 {
    string internal constant TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    function encode(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return "";

        // load the table into memory
        string memory table = TABLE;

        // calculate output length, ~4/3 of input length
        uint256 encodedLen = 4 * ((data.length + 2) / 3);

        // allocate output
        bytes memory result = new bytes(encodedLen);

        // set some pointers
        uint256 dataPtr = 0;
        uint256 resultPtr = 0;

        // main loop
        for (; dataPtr < data.length - 2; dataPtr += 3) {
            result[resultPtr++] = bytes1(table[uint8(data[dataPtr] >> 2)]);
            result[resultPtr++] = bytes1(table[uint8(((data[dataPtr] & 0x03) << 4) | (data[dataPtr + 1] >> 4))]);
            result[resultPtr++] = bytes1(table[uint8(((data[dataPtr + 1] & 0x0f) << 2) | (data[dataPtr + 2] >> 6))]);
            result[resultPtr++] = bytes1(table[uint8(data[dataPtr + 2] & 0x3f)]);
        }

        // handle tail
        if (dataPtr == data.length - 1) {
            result[resultPtr++] = bytes1(table[uint8(data[dataPtr] >> 2)]);
            result[resultPtr++] = bytes1(table[uint8((data[dataPtr] & 0x03) << 4)]);
            result[resultPtr++] = bytes1('=');
            result[resultPtr++] = bytes1('=');
        } else if (dataPtr == data.length - 2) {
            result[resultPtr++] = bytes1(table[uint8(data[dataPtr] >> 2)]);
            result[resultPtr++] = bytes1(table[uint8(((data[dataPtr] & 0x03) << 4) | (data[dataPtr + 1] >> 4))]);
            result[resultPtr++] = bytes1(table[uint8((data[dataPtr + 1] & 0x0f) << 2)]);
            result[resultPtr++] = bytes1('=');
        }

        return string(result);
    }
}
```