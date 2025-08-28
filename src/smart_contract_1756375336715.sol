Here's a smart contract in Solidity called "SynergyNexus: AI-Curated Skill-Mesh & Dynamic Reputation Protocol". This contract aims to create a decentralized platform for task execution and reputation building, incorporating several advanced, creative, and trendy concepts.

---

**Smart Contract Name:** SynergyNexus: AI-Curated Skill-Mesh & Dynamic Reputation Protocol

**Concept:**
SynergyNexus is a decentralized protocol designed to connect users (Providers) with tasks (Quests) posted by other users (Seekers) based on a verifiable, multi-dimensional skill and reputation system. It incorporates advanced concepts such as AI-assisted matching (via oracle), verifiable attestations (including mock Zero-Knowledge Proof (ZK-Proof) verification), and dynamic Soulbound Tokens (SBTs) called "Skill Shards" that evolve with a user's experience and contributions. The goal is to create a transparent, efficient, and reputation-driven freelance or task network on the blockchain.

**Key Innovations & Advanced Concepts:**

1.  **Multi-Dimensional, Dynamic Reputation:** Unlike simple one-dimensional scores, SynergyNexus tracks reputation across specific skills and general attributes (quality, communication, reliability), which decay over time to incentivize continuous activity and maintain relevance.
2.  **AI-Assisted Provider Matching (Off-chain Oracle):** Integrates an off-chain AI oracle to suggest optimal provider-quest matches. The contract verifies the oracle's recommendations via cryptographic proofs (e.g., a signed message), adding a layer of intelligent curation while maintaining on-chain trustlessness for the final decision.
3.  **Zero-Knowledge Proof (ZK-Proof) Attestation Verification:** Includes a function to verify ZK proofs for private skill attestations. This allows users to cryptographically prove they possess a certain skill or credential without revealing the underlying sensitive data to the public blockchain, enhancing privacy. (The actual ZK verifier is a placeholder for a complex external library/precompile).
4.  **Dynamic Soulbound Skill Shards (SBTs):** Introduces non-transferable ERC-721-like tokens called "Skill Shards." These SBTs represent a user's mastery in a specific skill. They dynamically level up and gain "experience" based on successful quest completions and positive attestations, visually evolving to reflect a user's growing expertise.
5.  **Community-Driven Skill Taxonomy:** Enables users to propose and vote on new skill categories, fostering a decentralized and evolving knowledge graph for matching and reputation.
6.  **Milestone-Based Quest System with Dispute Escalation:** Structured tasks with phased payments (milestones) and an integrated mechanism for escalating disputes to a dedicated resolution system, ensuring fair compensation and recourse.
7.  **Reputation Decay:** Implements an on-chain decay mechanism for reputation scores, ensuring that a user's standing reflects their recent activity and performance, rather than accumulating indefinitely.

**Outline:**

1.  **Core Data Structures:**
    *   `UserProfile`: Stores user-specific information, including skill-specific reputations and owned Skill Shards.
    *   `SkillShard`: Represents a non-transferable ERC-721 token for a specific skill.
    *   `Quest`: Defines a task, its bounty, milestones, status, and associated parties.
    *   `SkillReputation`: Captures multi-dimensional reputation scores for a given skill (overall, quality, communication, reliability).
    *   `SkillCategory`: For managing the hierarchical taxonomy of skills, including proposal and voting states.

2.  **User & Skill Management:**
    *   Profile registration and updates (linking to off-chain data).
    *   On-chain peer-to-peer attestation for skills.
    *   Verification of ZK-Proof-backed private skill attestations.
    *   Minting of dynamic Skill Shards (SBTs) for verified skills.
    *   Mechanisms for leveling up Skill Shards based on contributions.

3.  **Quest Lifecycle:**
    *   Creation of quests with multi-milestone payment structures and deadlines.
    *   AI-assisted provider proposal and on-chain acceptance.
    *   Submission and approval of milestone work, triggering payments.
    *   Initiation of disputes, deferring to an external resolution system.
    *   Cancellation of quests under specific conditions.

4.  **Reputation & Feedback:**
    *   Submission of detailed feedback (quality, communication, reliability) after quest completion, directly influencing reputation.
    *   On-demand retrieval of specific skill reputation scores.
    *   Protocol-level management of reputation decay parameters by administrators.

5.  **Governance & Protocol Administration:**
    *   Community proposal and voting system for adding new skill categories to the platform's taxonomy.
    *   Administrative functions for setting protocol fees, managing oracle addresses, and configuring the dispute resolver.
    *   Mechanism for withdrawing accumulated protocol fees.

**Function Summary (23 Functions):**

**I. User Profile & Skill Management**
1.  `registerProfile(string _uri)`: Registers a new user profile, linking to off-chain data (e.g., IPFS URI for bio/portfolio).
2.  `updateProfileInfo(string _uri)`: Allows a registered user to update their off-chain profile data URI.
3.  `attestSkill(address _targetUser, bytes32 _skillHash, uint8 _rating, string _detailsUri)`: A user attests to another user's skill, directly influencing their reputation for that specific skill.
4.  `verifyZKAttestation(address _attester, address _targetUser, bytes32 _skillHash, bytes memory _proof, uint256[8] memory _publicSignals)`: Placeholder function for verifying an off-chain generated ZK proof of a private skill attestation, enhancing user privacy.
5.  `mintSkillShard(address _owner, bytes32 _skillHash)`: Mints a new non-transferable `SkillShard` NFT (SBT) for a user, granted when certain skill verification or reputation thresholds are met.
6.  `levelUpSkillShard(uint256 _tokenId)`: Increments the level and experience points of a `SkillShard` based on successful quest completions or high-rated attestations.
7.  `getSkillShardInfo(uint256 _tokenId)`: Retrieves detailed information about a specific Skill Shard NFT (owner, skill, level, experience, token URI).

**II. Quest Management**
8.  `createQuest(bytes32 _questHash, bytes32[] _requiredSkillHashes, uint256 _bounty, uint256 _milestoneCount, uint256 _deadline)`: Creates a new quest, specifying required skills, total bounty (paid upfront), milestone structure, and deadline.
9.  `proposeProvider(uint256 _questId, address _provider, bytes memory _aiMatchProof, uint8 _aiMatchScore)`: Seeker proposes a provider for an open quest, potentially incorporating an AI oracle's recommendation and its cryptographic proof.
10. `acceptQuest(uint256 _questId)`: The proposed provider accepts the quest, officially becoming the assigned provider.
11. `submitMilestone(uint256 _questId, uint256 _milestoneIndex, string _proofUri)`: Provider submits work for a specific milestone, providing a URI to the proof of completion.
12. `approveMilestone(uint256 _questId, uint256 _milestoneIndex)`: Seeker approves a submitted milestone, releasing the corresponding payment to the provider.
13. `requestDispute(uint256 _questId, string _reasonUri)`: Initiates a dispute for a quest, marking its status and logging the reason for external resolution.
14. `cancelQuest(uint256 _questId)`: Allows the seeker to cancel an unaccepted or unresolved quest under specific conditions, refunding the remaining bounty.

**III. Reputation & Feedback**
15. `submitQuestFeedback(uint256 _questId, uint8 _qualityRating, uint8 _communicationRating, uint8 _reliabilityRating)`: Seeker or provider submits multi-dimensional feedback after a quest is completed, directly impacting the counterparty's reputation scores.
16. `getReputationScore(address _user, bytes32 _skillHash)`: Retrieves the specific reputation scores (overall, quality, communication, reliability) for a user related to a given skill.
17. `updateReputationDecayParameters(uint256 _decayRateBasisPoints, uint256 _decayInterval)`: Admin function to adjust the rate and interval at which reputation scores decay due to user inactivity, ensuring relevance.

**IV. Governance & Protocol Management**
18. `proposeSkillCategory(string _name, bytes32 _parentHash)`: Allows any registered user to propose new hierarchical skill categories for community review and integration into the protocol.
19. `voteOnSkillCategory(bytes32 _skillHash, bool _approve)`: Enables registered users to vote on proposed skill categories (approval or rejection).
20. `setProtocolFee(uint256 _newFeeBasisPoints)`: Admin function to adjust the percentage-based protocol fee applied to quest bounties.
21. `withdrawFees()`: Allows the administrator to withdraw accumulated protocol fees to a designated wallet.
22. `updateOracleAddress(address _newOracle)`: Admin function to update the trusted address of the AI matching oracle.
23. `setDisputeResolver(address _resolver)`: Admin function to set the address of the dedicated external dispute resolution contract or entity.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol"; // For verifying AI oracle signatures

// --- START OUTLINE & FUNCTION SUMMARY ---

// Smart Contract Name: SynergyNexus: AI-Curated Skill-Mesh & Dynamic Reputation Protocol

// Concept:
// SynergyNexus is a decentralized protocol designed to connect users (Providers) with tasks (Quests) posted by other users (Seekers) based on a verifiable, multi-dimensional skill and reputation system. It incorporates advanced concepts such as AI-assisted matching (via oracle), verifiable attestations (including mock ZK-proof verification), and dynamic Soulbound Tokens (SBTs) called "Skill Shards" that evolve with a user's experience and contributions. The goal is to create a transparent, efficient, and reputation-driven freelance or task network on the blockchain.

// Key Innovations & Advanced Concepts:
// 1.  Multi-Dimensional, Dynamic Reputation: Tracks reputation across specific skills and general attributes (quality, communication, reliability), which decay over time.
// 2.  AI-Assisted Provider Matching (Off-chain Oracle): Integrates an off-chain AI oracle to suggest optimal provider-quest matches, with on-chain verification of oracle recommendations via cryptographic proofs.
// 3.  Zero-Knowledge Proof (ZK-Proof) Attestation Verification: Includes a function to verify ZK proofs for private skill attestations, allowing users to cryptographically prove a skill without revealing sensitive details. (Placeholder for full ZK verifier).
// 4.  Dynamic Soulbound Skill Shards (SBTs): Non-transferable ERC-721-like tokens that represent a user's mastery in a skill, dynamically leveling up and gaining "experience" based on successful contributions.
// 5.  Community-Driven Skill Taxonomy: Enables users to propose and vote on new skill categories, fostering a decentralized and evolving knowledge graph.
// 6.  Milestone-Based Quest System with Dispute Escalation: Structured tasks with phased payments and a mechanism for escalating disputes to a dedicated resolution system.
// 7.  Reputation Decay: Implements an on-chain decay mechanism for reputation scores, ensuring relevance.

// Outline:
// 1.  Core Data Structures:
//     *   UserProfile: Stores user-specific information.
//     *   SkillShard: Represents a non-transferable ERC-721 token for a skill.
//     *   Quest: Defines a task, its bounty, milestones, and status.
//     *   SkillReputation: Multi-dimensional reputation scores for a skill.
//     *   SkillCategory: Manages hierarchical skill taxonomy, proposals, and voting.
// 2.  User & Skill Management:
//     *   Profile registration and updates.
//     *   On-chain attestation for skills.
//     *   Zero-Knowledge Proof (ZK-Proof) verification for private skill attestations (simulated for concept).
//     *   Minting and leveling up dynamic Skill Shards (SBTs).
// 3.  Quest Lifecycle:
//     *   Creation of quests with multi-milestone payments.
//     *   AI-assisted provider proposal and acceptance.
//     *   Submission and approval of milestones.
//     *   Dispute initiation.
//     *   Quest cancellation.
// 4.  Reputation & Feedback:
//     *   Submission of post-quest feedback influencing multi-dimensional reputation.
//     *   Retrieval of reputation scores for specific skills.
//     *   Protocol-level reputation decay management.
// 5.  Governance & Protocol Administration:
//     *   Community-driven skill category proposals and voting.
//     *   Setting protocol fees.
//     *   Managing oracle and dispute resolver addresses.
//     *   Fee withdrawal.

// Function Summary (23 Functions):

// I. User Profile & Skill Management
// 1.  `registerProfile(string _uri)`: Registers a new user profile, linking to off-chain data (e.g., IPFS URI for bio).
// 2.  `updateProfileInfo(string _uri)`: Allows a user to update their off-chain profile data URI.
// 3.  `attestSkill(address _targetUser, bytes32 _skillHash, uint8 _rating, string _detailsUri)`: A user attests to another's skill, influencing their reputation for that skill.
// 4.  `verifyZKAttestation(address _attester, address _targetUser, bytes32 _skillHash, bytes memory _proof, uint256[8] memory _publicSignals)`: Placeholder for verifying an off-chain generated ZK proof of a skill attestation, enhancing privacy. This would typically involve a specific ZK verifier contract.
// 5.  `mintSkillShard(address _owner, bytes32 _skillHash)`: Mints a new non-transferable `SkillShard` NFT (SBT) for a user based on verified skills/attestations.
// 6.  `levelUpSkillShard(uint256 _tokenId)`: Increments the level and experience of a `SkillShard` based on successful quest completions or high-rated attestations.
// 7.  `getSkillShardInfo(uint256 _tokenId)`: Retrieves detailed information about a specific Skill Shard NFT.

// II. Quest Management
// 8.  `createQuest(bytes32 _questHash, bytes32[] _requiredSkillHashes, uint256 _bounty, uint256 _milestoneCount, uint256 _deadline)`: Creates a new quest, specifying required skills, total bounty, and milestone structure.
// 9.  `proposeProvider(uint256 _questId, address _provider, bytes memory _aiMatchProof, uint8 _aiMatchScore)`: Seeker proposes a provider, potentially backed by an AI oracle's recommendation and proof.
// 10. `acceptQuest(uint256 _questId)`: Proposed provider accepts the quest, locking funds.
// 11. `submitMilestone(uint256 _questId, uint256 _milestoneIndex, string _proofUri)`: Provider submits work for a specific milestone.
// 12. `approveMilestone(uint256 _questId, uint256 _milestoneIndex)`: Seeker approves a milestone, releasing the corresponding payment to the provider.
// 13. `requestDispute(uint256 _questId, string _reasonUri)`: Initiates a dispute for a quest, redirecting to an external dispute resolution system.
// 14. `cancelQuest(uint256 _questId)`: Allows the seeker to cancel an unaccepted or unresolved quest, with conditions.

// III. Reputation & Feedback
// 15. `submitQuestFeedback(uint256 _questId, uint8 _qualityRating, uint8 _communicationRating, uint8 _reliabilityRating)`: Seeker/Provider submits feedback after quest completion, influencing multi-dimensional reputation scores.
// 16. `getReputationScore(address _user, bytes32 _skillHash)`: Retrieves the specific reputation score for a user pertaining to a given skill.
// 17. `updateReputationDecayParameters(uint256 _decayRateBasisPoints, uint256 _decayInterval)`: Admin function to adjust how reputation scores decay over time due to inactivity, encouraging continuous engagement.

// IV. Governance & Protocol Management
// 18. `proposeSkillCategory(string _name, bytes32 _parentHash)`: Allows users to propose new hierarchical skill categories for community review.
// 19. `voteOnSkillCategory(bytes32 _skillHash, bool _approve)`: Enables users to vote on proposed skill categories to integrate them into the protocol's taxonomy.
// 20. `setProtocolFee(uint256 _newFeeBasisPoints)`: Admin function to adjust the protocol's fee percentage on quest bounties (e.g., 500 = 5%).
// 21. `withdrawFees()`: Allows the admin to withdraw accumulated protocol fees.
// 22. `updateOracleAddress(address _newOracle)`: Admin function to update the trusted AI matching oracle's address.
// 23. `setDisputeResolver(address _resolver)`: Admin function to set the address of the dedicated dispute resolution contract or entity.

// --- END OUTLINE & FUNCTION SUMMARY ---


contract SynergyNexus is Ownable, ReentrancyGuard {
    using Counters for Counters.Counter;

    // --- State Variables ---

    Counters.Counter private _questIds;
    Counters.Counter private _skillShardIds;

    // --- User Profile & Reputation ---
    struct UserProfile {
        bool exists;
        string profileUri; // IPFS hash or similar for detailed user bio/portfolio
        mapping(bytes32 => SkillReputation) skillReputations; // Reputation per skill
        mapping(uint256 => bool) ownedSkillShards; // Track owned SkillShard NFTs by tokenId
        mapping(bytes32 => bool) hasSkillShardFor; // Check if a user has a shard for a specific skill hash
    }

    // Multi-dimensional reputation
    struct SkillReputation {
        uint256 overallScore; // General score for this skill, 0-1000 (0-100 for display, *10 to allow decimal precision)
        uint256 qualityScore; // Score for work quality (0-100)
        uint256 communicationScore; // Score for communication (0-100)
        uint256 reliabilityScore; // Score for reliability (0-100)
        uint256 lastUpdated; // Timestamp for decay calculations
    }

    mapping(address => UserProfile) public userProfiles;

    // --- Skill Shards (Soulbound Tokens - SBTs) ---
    // ERC-721-like structure, but non-transferable (implicitly by no transfer function)
    struct SkillShard {
        uint256 tokenId;
        address owner;
        bytes32 skillHash;
        uint256 level;
        uint256 experiencePoints; // Accumulated XP
        string tokenURI; // Dynamic URI reflecting level/XP
        bool exists;
    }

    mapping(uint256 => SkillShard) public skillShards; // tokenId => SkillShard details
    mapping(address => mapping(bytes32 => uint256)) public ownerSkillShardId; // owner -> skillHash -> tokenId (for quick lookup)

    // --- Quest Management ---
    enum QuestStatus {
        Open,                 // Quest created, awaiting provider proposal
        Proposed,             // Provider proposed by seeker, awaiting acceptance
        Accepted,             // Provider accepted quest, work can begin
        MilestoneSubmitted,   // Provider submitted work for a milestone
        MilestoneApproved,    // Seeker approved a milestone
        Completed,            // All milestones approved, quest finished
        Disputed,             // Quest is under dispute resolution
        Cancelled             // Quest cancelled by seeker or resolution
    }

    struct Milestone {
        uint256 amount; // Amount for this specific milestone
        string proofUri; // IPFS hash for work proof
        bool approved;
        bool submitted;
    }

    struct Quest {
        uint256 id;
        address seeker;
        address provider; // 0x0 until accepted
        bytes32 questHash; // IPFS hash of quest details or unique identifier
        bytes32[] requiredSkillHashes;
        uint256 bounty; // Total bounty in native token (e.g., ETH)
        QuestStatus status;
        Milestone[] milestones;
        uint256 deadline;
        uint256 creationTime;
        uint256 acceptedTime;
        bool feedbackSubmittedBySeeker;
        bool feedbackSubmittedByProvider;
    }

    mapping(uint256 => Quest) public quests;

    // --- Skill Taxonomy & Governance ---
    struct SkillCategory {
        bool exists; // To differentiate between non-existent and default values
        string name;
        bytes32 parentHash; // For hierarchical structure, bytes32(0) for top-level
        uint256 proposalTime;
        mapping(address => bool) votes; // true for approve, false for reject (for a simple binary vote)
        uint256 approvalVotes;
        uint256 rejectionVotes;
        bool approved;
    }

    mapping(bytes32 => SkillCategory) public skillCategories; // skillHash => SkillCategory details
    bytes32[] public proposedSkillCategoryHashes; // List of skill hashes for proposed categories

    // --- Protocol Fees & Administration ---
    address public protocolFeeWallet;
    uint256 public protocolFeeBasisPoints; // e.g., 500 for 5% (500/10000)
    uint256 public accumulatedFees;
    address public aiMatchingOracle; // Trusted oracle for AI matching suggestions
    address public disputeResolver; // Contract/Address responsible for dispute resolution

    // Reputation decay parameters
    uint256 public reputationDecayRateBasisPoints; // e.g., 100 for 1% per interval
    uint256 public reputationDecayInterval; // e.g., 30 days in seconds

    // --- Events ---
    event ProfileRegistered(address indexed user, string profileUri);
    event ProfileUpdated(address indexed user, string newProfileUri);
    event SkillAttested(address indexed attester, address indexed targetUser, bytes32 indexed skillHash, uint8 rating, string detailsUri);
    event ZKAttestationVerified(address indexed attester, address indexed targetUser, bytes32 indexed skillHash);
    event SkillShardMinted(address indexed owner, uint256 indexed tokenId, bytes32 skillHash, uint256 level);
    event SkillShardLeveledUp(uint256 indexed tokenId, uint256 newLevel, uint256 newXP);

    event QuestCreated(uint256 indexed questId, address indexed seeker, bytes32 questHash, uint256 bounty, uint256 deadline);
    event ProviderProposed(uint256 indexed questId, address indexed provider, uint8 aiMatchScore);
    event QuestAccepted(uint256 indexed questId, address indexed provider);
    event MilestoneSubmitted(uint256 indexed questId, uint256 indexed milestoneIndex, string proofUri);
    event MilestoneApproved(uint256 indexed questId, uint256 indexed milestoneIndex, address indexed provider, uint256 amount);
    event QuestCompleted(uint256 indexed questId, address indexed seeker, address indexed provider);
    event DisputeRequested(uint256 indexed questId, address indexed initiator, string reasonUri);
    event QuestCancelled(uint256 indexed questId);

    event FeedbackSubmitted(uint256 indexed questId, address indexed submitter, address indexed targetUser, uint8 quality, uint8 communication, uint8 reliability);
    event ReputationUpdated(address indexed user, bytes32 indexed skillHash, uint256 newOverallScore);

    event SkillCategoryProposed(bytes32 indexed skillHash, string name, bytes32 parentHash);
    event SkillCategoryVoted(address indexed voter, bytes32 indexed skillHash, bool approved);
    event SkillCategoryApproved(bytes32 indexed skillHash);

    event ProtocolFeeUpdated(uint256 oldFeeBasisPoints, uint256 newFeeBasisPoints);
    event FeesWithdrawn(address indexed to, uint256 amount);
    event OracleAddressUpdated(address indexed oldOracle, address indexed newOracle);
    event DisputeResolverUpdated(address indexed oldResolver, address indexed newResolver);
    event ReputationDecayParamsUpdated(uint256 newDecayRate, uint256 newDecayInterval);

    // --- Constructor ---
    constructor(address _initialOracle, address _initialDisputeResolver, address _protocolFeeWallet) Ownable(msg.sender) {
        require(_initialOracle != address(0), "Invalid oracle address");
        require(_initialDisputeResolver != address(0), "Invalid dispute resolver address");
        require(_protocolFeeWallet != address(0), "Invalid fee wallet address");

        aiMatchingOracle = _initialOracle;
        disputeResolver = _initialDisputeResolver;
        protocolFeeWallet = _protocolFeeWallet;
        protocolFeeBasisPoints = 500; // Default 5%
        reputationDecayRateBasisPoints = 100; // Default 1%
        reputationDecayInterval = 30 days; // Default 30 days
    }

    // --- Modifiers ---
    modifier onlyRegisteredUser() {
        require(userProfiles[msg.sender].exists, "User not registered");
        _;
    }

    modifier onlyQuestSeeker(uint256 _questId) {
        require(quests[_questId].seeker == msg.sender, "Only quest seeker can call this");
        _;
    }

    modifier onlyQuestProvider(uint256 _questId) {
        require(quests[_questId].provider == msg.sender, "Only quest provider can call this");
        _;
    }

    // --- I. User Profile & Skill Management ---

    /// @notice Registers a new user profile with an associated off-chain URI.
    /// @param _uri The URI (e.g., IPFS hash) pointing to the user's detailed profile information.
    function registerProfile(string calldata _uri) external {
        require(!userProfiles[msg.sender].exists, "User already registered");
        userProfiles[msg.sender].exists = true;
        userProfiles[msg.sender].profileUri = _uri;
        emit ProfileRegistered(msg.sender, _uri);
    }

    /// @notice Allows a registered user to update their off-chain profile data URI.
    /// @param _uri The new URI for the user's profile information.
    function updateProfileInfo(string calldata _uri) external onlyRegisteredUser {
        userProfiles[msg.sender].profileUri = _uri;
        emit ProfileUpdated(msg.sender, _uri);
    }

    /// @notice Allows a user to attest to another user's skill, influencing their reputation.
    /// @dev This is a direct on-chain attestation. Higher ratings contribute more.
    /// @param _targetUser The address of the user whose skill is being attested.
    /// @param _skillHash A unique identifier (e.g., keccak256 hash) for the skill.
    /// @param _rating A rating from 1 to 5, where 5 is excellent.
    /// @param _detailsUri An optional URI for further details about the attestation.
    function attestSkill(address _targetUser, bytes32 _skillHash, uint8 _rating, string calldata _detailsUri) external onlyRegisteredUser {
        require(_targetUser != address(0) && _targetUser != msg.sender, "Invalid target user");
        require(userProfiles[_targetUser].exists, "Target user not registered");
        require(_rating >= 1 && _rating <= 5, "Rating must be between 1 and 5");

        // Simple reputation update logic for demonstration
        SkillReputation storage rep = userProfiles[_targetUser].skillReputations[_skillHash];
        _applyReputationDecay(_targetUser, _skillHash); // Apply decay before updating

        // Max overall score is 1000 (representing 100.0)
        rep.overallScore = Math.min(rep.overallScore + (_rating * 20), 1000); // Max score + base
        rep.lastUpdated = block.timestamp;

        // If user doesn't have a SkillShard for this skill, mint one after sufficient reputation
        if (!userProfiles[_targetUser].hasSkillShardFor[_skillHash] && rep.overallScore >= 100) { // Example threshold
            _mintSkillShard(_targetUser, _skillHash);
        }

        emit SkillAttested(msg.sender, _targetUser, _skillHash, _rating, _detailsUri);
        emit ReputationUpdated(_targetUser, _skillHash, rep.overallScore);
    }

    /// @notice Placeholder for verifying an off-chain generated ZK proof of a skill attestation.
    /// @dev In a real implementation, this function would interact with a precompiled SNARK verifier contract
    ///      or a custom verifier. For this conceptual contract, it acts as a gate for a ZK-verified claim.
    ///      The `_publicSignals` would contain the necessary inputs like `_targetUser` and `_skillHash`.
    /// @param _attester The address of the entity providing the ZK proof (could be an oracle or a user).
    /// @param _targetUser The address of the user whose skill is being attested privately.
    /// @param _skillHash A unique identifier for the skill being attested.
    /// @param _proof The serialized zero-knowledge proof.
    /// @param _publicSignals The public inputs for the ZK proof verification.
    function verifyZKAttestation(address _attester, address _targetUser, bytes32 _skillHash, bytes calldata _proof, uint256[8] calldata _publicSignals) external {
        require(_targetUser != address(0), "Invalid target user");
        require(userProfiles[_targetUser].exists, "Target user not registered");
        require(_proof.length > 0, "Proof cannot be empty");

        // --- Mock ZK Proof Verification ---
        // A real ZK-SNARK verifier would call a precompiled contract (e.g., `ecVerify`)
        // or a complex Solidity verifier implementation here.
        // Example: `require(SNARKVerifier.verifyProof(proof, publicSignals), "Invalid ZK proof");`
        // For this concept, we'll simulate a simple check and ensure _attester is a trusted entity.
        require(_attester == aiMatchingOracle, "Only trusted ZK attesters (oracle) can call this in mock setup");
        // We'd also check if _publicSignals match expected values derived from _targetUser, _skillHash, etc.
        // For example, one of the public signals could be a hash of (_targetUser, _skillHash).
        // `require(uint256(keccak256(abi.encodePacked(_targetUser, _skillHash))) == _publicSignals[0], "Public signal mismatch");`
        // --- End Mock ZK Proof Verification ---

        SkillReputation storage rep = userProfiles[_targetUser].skillReputations[_skillHash];
        _applyReputationDecay(_targetUser, _skillHash); // Apply decay before updating

        // ZK-verified attestations could grant a significant, less decaying reputation boost.
        rep.overallScore = Math.min(rep.overallScore + 150, 1000); // Substantial boost, capped at 1000
        rep.lastUpdated = block.timestamp;

        // If user doesn't have a SkillShard for this skill, mint one
        if (!userProfiles[_targetUser].hasSkillShardFor[_skillHash]) {
            _mintSkillShard(_targetUser, _skillHash);
        } else {
             // If they have it, level it up immediately for this significant attestation
            levelUpSkillShard(ownerSkillShardId[_targetUser][_skillHash]);
        }

        emit ZKAttestationVerified(_attester, _targetUser, _skillHash);
        emit ReputationUpdated(_targetUser, _skillHash, rep.overallScore);
    }

    /// @notice Internal function to mint a new non-transferable SkillShard NFT.
    /// @param _owner The address to whom the SkillShard will be minted.
    /// @param _skillHash The unique identifier for the skill.
    function _mintSkillShard(address _owner, bytes32 _skillHash) internal {
        require(userProfiles[_owner].exists, "Owner not registered");
        require(!userProfiles[_owner].hasSkillShardFor[_skillHash], "Owner already has a shard for this skill");

        _skillShardIds.increment();
        uint256 newId = _skillShardIds.current();

        SkillShard storage newShard = skillShards[newId];
        newShard.tokenId = newId;
        newShard.owner = _owner;
        newShard.skillHash = _skillHash;
        newShard.level = 1;
        newShard.experiencePoints = 0;
        newShard.tokenURI = string(abi.encodePacked("ipfs://skillshard/", Strings.toString(newId))); // Example dynamic URI
        newShard.exists = true;

        userProfiles[_owner].ownedSkillShards[newId] = true;
        userProfiles[_owner].hasSkillShardFor[_skillHash] = true;
        ownerSkillShardId[_owner][_skillHash] = newId;

        emit SkillShardMinted(_owner, newId, _skillHash, 1);
    }

    /// @notice Mints a new non-transferable `SkillShard` NFT (SBT) for a user based on verified skills/attestations.
    /// @dev This function can be called by a user to request a shard if conditions are met (e.g., minimum attestations/reputation).
    /// @param _owner The address to whom the SkillShard will be minted.
    /// @param _skillHash The unique identifier for the skill.
    function mintSkillShard(address _owner, bytes32 _skillHash) external onlyRegisteredUser {
        require(_owner == msg.sender, "Can only mint for yourself");
        require(!userProfiles[_owner].hasSkillShardFor[_skillHash], "You already have a shard for this skill");
        require(userProfiles[_owner].skillReputations[_skillHash].overallScore >= 100, "Insufficient skill reputation to mint a shard"); // Example threshold
        
        _mintSkillShard(_owner, _skillHash);
    }

    /// @notice Increments the level and experience of a `SkillShard`.
    /// @dev This can be triggered by successful quest completions or high-rated attestations.
    ///      Only the shard owner or the contract itself can call this.
    /// @param _tokenId The ID of the SkillShard NFT to level up.
    function levelUpSkillShard(uint256 _tokenId) public { 
        SkillShard storage shard = skillShards[_tokenId];
        require(shard.exists, "SkillShard does not exist");
        require(shard.owner == msg.sender || msg.sender == address(this), "Only owner or contract can level up shard"); 

        uint256 newXP = shard.experiencePoints + 50; // Example XP gain for an event
        uint256 newLevel = shard.level;

        // Level up condition: e.g., level 1 needs 100 XP, level 2 needs 200 XP, etc.
        uint256 xpToNextLevel = shard.level * 100;
        if (newXP >= xpToNextLevel) { 
            newLevel++;
            newXP = newXP - xpToNextLevel; // Carry over excess XP
            shard.tokenURI = string(abi.encodePacked("ipfs://skillshard/", Strings.toString(shard.tokenId), "/level/", Strings.toString(newLevel)));
        }

        shard.experiencePoints = newXP;
        shard.level = newLevel;

        emit SkillShardLeveledUp(_tokenId, newLevel, newXP);
    }

    /// @notice Retrieves detailed information about a specific Skill Shard NFT.
    /// @param _tokenId The ID of the SkillShard.
    /// @return owner The owner's address.
    /// @return skillHash The hash representing the skill.
    /// @return level The current level of the shard.
    /// @return experiencePoints The current experience points of the shard.
    /// @return tokenURI The URI pointing to the shard's metadata (e.g., image).
    function getSkillShardInfo(uint256 _tokenId) external view returns (address owner, bytes32 skillHash, uint256 level, uint256 experiencePoints, string memory tokenURI) {
        SkillShard storage shard = skillShards[_tokenId];
        require(shard.exists, "SkillShard does not exist");
        return (shard.owner, shard.skillHash, shard.level, shard.experiencePoints, shard.tokenURI);
    }


    // --- II. Quest Management ---

    /// @notice Creates a new quest with required skills, a total bounty, and milestone structure.
    /// @dev The total bounty must be sent with this transaction. The protocol fee is deducted.
    /// @param _questHash An IPFS hash or unique identifier for the quest's detailed description.
    /// @param _requiredSkillHashes An array of skill hashes required for the quest.
    /// @param _bounty The total bounty for the quest in native currency (e.g., ETH).
    /// @param _milestoneCount The number of milestones for the quest.
    /// @param _deadline Timestamp by which the quest should be completed.
    function createQuest(bytes32 _questHash, bytes32[] calldata _requiredSkillHashes, uint256 _bounty, uint256 _milestoneCount, uint256 _deadline) external payable onlyRegisteredUser nonReentrant returns (uint256) {
        require(_bounty > 0, "Bounty must be greater than zero");
        require(msg.value == _bounty, "Msg.value must match bounty");
        require(_milestoneCount > 0, "Must have at least one milestone");
        require(_deadline > block.timestamp, "Deadline must be in the future");
        require(_requiredSkillHashes.length > 0, "At least one skill is required");

        for (uint256 i = 0; i < _requiredSkillHashes.length; i++) {
            require(skillCategories[_requiredSkillHashes[i]].approved, "Required skill category not approved");
        }

        _questIds.increment();
        uint256 questId = _questIds.current();

        // Calculate protocol fee
        uint256 fee = (_bounty * protocolFeeBasisPoints) / 10000;
        accumulatedFees += fee;
        uint256 distributableBounty = _bounty - fee;
        require(distributableBounty > 0, "Bounty too small after fees");
        uint256 amountPerMilestone = distributableBounty / _milestoneCount;
        require(amountPerMilestone > 0, "Bounty too small for fees and milestones");

        Milestone[] memory newMilestones = new Milestone[](_milestoneCount);
        for (uint256 i = 0; i < _milestoneCount; i++) {
            newMilestones[i].amount = amountPerMilestone;
        }

        quests[questId] = Quest({
            id: questId,
            seeker: msg.sender,
            provider: address(0),
            questHash: _questHash,
            requiredSkillHashes: _requiredSkillHashes,
            bounty: _bounty,
            status: QuestStatus.Open,
            milestones: newMilestones,
            deadline: _deadline,
            creationTime: block.timestamp,
            acceptedTime: 0,
            feedbackSubmittedBySeeker: false,
            feedbackSubmittedByProvider: false
        });

        emit QuestCreated(questId, msg.sender, _questHash, _bounty, _deadline);
        return questId;
    }

    /// @notice Seeker proposes a provider for an open quest, potentially based on an AI oracle's recommendation.
    /// @dev The AI match proof can be a signed message from the oracle, verified on-chain.
    /// @param _questId The ID of the quest.
    /// @param _provider The address of the proposed provider.
    /// @param _aiMatchProof Signature from the AI oracle, proving its recommendation.
    /// @param _aiMatchScore A score from the AI oracle (e.g., 0-100) indicating match quality.
    function proposeProvider(uint256 _questId, address _provider, bytes calldata _aiMatchProof, uint8 _aiMatchScore) external onlyQuestSeeker(_questId) {
        Quest storage quest = quests[_questId];
        require(quest.status == QuestStatus.Open, "Quest is not open for provider proposal");
        require(_provider != address(0) && _provider != quest.seeker, "Invalid provider address");
        require(userProfiles[_provider].exists, "Proposed provider not registered");

        // --- AI Match Proof Verification ---
        // Verify _aiMatchProof against the aiMatchingOracle's public key
        // to ensure the oracle signed a message containing _questId, _provider, and _aiMatchScore.
        require(aiMatchingOracle != address(0), "AI matching oracle not set");
        require(_aiMatchProof.length > 0, "AI match proof required");
        
        // Hash the message components that the AI oracle is expected to sign
        bytes32 messageHash = ECDSA.toEthSignedMessageHash(keccak256(abi.encodePacked(quest.id, _provider, _aiMatchScore)));
        address signer = ECDSA.recover(messageHash, _aiMatchProof);
        require(signer == aiMatchingOracle, "Invalid AI match proof signature");
        // --- End AI Match Proof Verification ---

        // Further checks: Does the provider have required skills and sufficient reputation?
        for (uint256 i = 0; i < quest.requiredSkillHashes.length; i++) {
            require(userProfiles[_provider].skillReputations[quest.requiredSkillHashes[i]].overallScore >= 50, "Provider lacks required skill reputation"); // Min score of 5 for that skill
        }

        quest.provider = _provider;
        quest.status = QuestStatus.Proposed;

        emit ProviderProposed(_questId, _provider, _aiMatchScore);
    }

    /// @notice The proposed provider accepts a quest.
    /// @param _questId The ID of the quest.
    function acceptQuest(uint256 _questId) external nonReentrant {
        Quest storage quest = quests[_questId];
        require(quest.status == QuestStatus.Proposed, "Quest not in proposed state");
        require(quest.provider == msg.sender, "Only the proposed provider can accept this quest");
        
        quest.status = QuestStatus.Accepted;
        quest.acceptedTime = block.timestamp;

        emit QuestAccepted(_questId, msg.sender);
    }

    /// @notice Provider submits work for a specific milestone.
    /// @param _questId The ID of the quest.
    /// @param _milestoneIndex The index of the milestone (0-based).
    /// @param _proofUri An IPFS hash or URI pointing to the proof of work.
    function submitMilestone(uint256 _questId, uint256 _milestoneIndex, string calldata _proofUri) external onlyQuestProvider(_questId) {
        Quest storage quest = quests[_questId];
        require(quest.status == QuestStatus.Accepted || quest.status == QuestStatus.MilestoneApproved || quest.status == QuestStatus.MilestoneSubmitted, "Quest not in an active state for submission");
        require(_milestoneIndex < quest.milestones.length, "Invalid milestone index");
        require(!quest.milestones[_milestoneIndex].submitted, "Milestone already submitted");
        
        quest.milestones[_milestoneIndex].proofUri = _proofUri;
        quest.milestones[_milestoneIndex].submitted = true;
        
        // Update general quest status if it was just 'Accepted'
        if (quest.status == QuestStatus.Accepted) {
             quest.status = QuestStatus.MilestoneSubmitted; 
        }

        emit MilestoneSubmitted(_questId, _milestoneIndex, _proofUri);
    }

    /// @notice Seeker approves a milestone, releasing the corresponding payment to the provider.
    /// @param _questId The ID of the quest.
    /// @param _milestoneIndex The index of the milestone (0-based).
    function approveMilestone(uint256 _questId, uint256 _milestoneIndex) external onlyQuestSeeker(_questId) nonReentrant {
        Quest storage quest = quests[_questId];
        require(quest.status == QuestStatus.MilestoneSubmitted || quest.status == QuestStatus.MilestoneApproved, "Quest not in milestone submitted state");
        require(_milestoneIndex < quest.milestones.length, "Invalid milestone index");
        require(quest.milestones[_milestoneIndex].submitted, "Milestone not submitted yet");
        require(!quest.milestones[_milestoneIndex].approved, "Milestone already approved");

        Milestone storage milestone = quest.milestones[_milestoneIndex];
        milestone.approved = true;

        // Transfer funds for this milestone
        payable(quest.provider).transfer(milestone.amount);

        // Check if all milestones are approved to mark quest as completed
        bool allApproved = true;
        for (uint256 i = 0; i < quest.milestones.length; i++) {
            if (!quest.milestones[i].approved) {
                allApproved = false;
                break;
            }
        }

        if (allApproved) {
            quest.status = QuestStatus.Completed;
            // Optionally, level up provider's skill shard for the primary skill
            if (userProfiles[quest.provider].hasSkillShardFor[quest.requiredSkillHashes[0]]) { 
                levelUpSkillShard(ownerSkillShardId[quest.provider][quest.requiredSkillHashes[0]]);
            }
            emit QuestCompleted(_questId, quest.seeker, quest.provider);
        } else {
            quest.status = QuestStatus.MilestoneApproved; 
        }

        emit MilestoneApproved(_questId, _milestoneIndex, quest.provider, milestone.amount);
    }

    /// @notice Initiates a dispute for a quest.
    /// @dev This marks the quest as disputed and assumes an external dispute resolution system.
    /// @param _questId The ID of the quest.
    /// @param _reasonUri An IPFS hash or URI pointing to the detailed reason for the dispute.
    function requestDispute(uint256 _questId, string calldata _reasonUri) external {
        Quest storage quest = quests[_questId];
        require(quest.status != QuestStatus.Open && quest.status != QuestStatus.Cancelled && quest.status != QuestStatus.Completed, "Quest cannot be disputed in its current state");
        require(msg.sender == quest.seeker || msg.sender == quest.provider, "Only seeker or provider can request dispute");
        require(disputeResolver != address(0), "Dispute resolver not set");
        
        quest.status = QuestStatus.Disputed;
        // In a full system, funds for remaining milestones would be locked in a dispute contract
        emit DisputeRequested(_questId, msg.sender, _reasonUri);
    }

    /// @notice Allows the seeker to cancel an unaccepted or unresolved quest.
    /// @dev Conditions apply: before acceptance, or if disputed and resolved as cancelled.
    /// @param _questId The ID of the quest.
    function cancelQuest(uint256 _questId) external onlyQuestSeeker(_questId) nonReentrant {
        Quest storage quest = quests[_questId];
        require(quest.status == QuestStatus.Open || quest.status == QuestStatus.Proposed || quest.status == QuestStatus.Disputed, "Quest cannot be cancelled in its current state");
        // If quest.status is Disputed, a separate resolution from disputeResolver should typically trigger this,
        // but for simplicity, we allow seeker to cancel if status is disputed.

        // Calculate amount to refund: total bounty minus already-paid milestones and accumulated fees.
        uint256 amountPaidToProvider = 0;
        for (uint256 i = 0; i < quest.milestones.length; i++) {
            if (quest.milestones[i].approved) {
                amountPaidToProvider += quest.milestones[i].amount;
            }
        }
        uint256 totalDistributable = quest.bounty - ((quest.bounty * protocolFeeBasisPoints) / 10000);
        uint256 refundAmount = totalDistributable - amountPaidToProvider;
        
        if (refundAmount > 0) {
            payable(quest.seeker).transfer(refundAmount);
        }

        quest.status = QuestStatus.Cancelled;
        emit QuestCancelled(_questId);
    }

    // --- III. Reputation & Feedback ---

    /// @notice Seeker/Provider submits feedback after quest completion, influencing multi-dimensional reputation.
    /// @param _questId The ID of the quest.
    /// @param _qualityRating Rating for work quality (1-5).
    /// @param _communicationRating Rating for communication (1-5).
    /// @param _reliabilityRating Rating for reliability (1-5).
    function submitQuestFeedback(uint256 _questId, uint8 _qualityRating, uint8 _communicationRating, uint8 _reliabilityRating) external onlyRegisteredUser {
        Quest storage quest = quests[_questId];
        require(quest.status == QuestStatus.Completed, "Feedback can only be submitted for completed quests");
        require(_qualityRating >= 1 && _qualityRating <= 5, "Invalid quality rating");
        require(_communicationRating >= 1 && _communicationRating <= 5, "Invalid communication rating");
        require(_reliabilityRating >= 1 && _reliabilityRating <= 5, "Invalid reliability rating");

        address targetUser;
        bytes32 primarySkillHash = quest.requiredSkillHashes[0]; // For simplicity, update reputation for the primary skill
        
        if (msg.sender == quest.seeker) {
            require(!quest.feedbackSubmittedBySeeker, "Seeker already submitted feedback");
            targetUser = quest.provider;
            quest.feedbackSubmittedBySeeker = true;
        } else if (msg.sender == quest.provider) {
            require(!quest.feedbackSubmittedByProvider, "Provider already submitted feedback");
            targetUser = quest.seeker; // Provider rates seeker (e.g., clarity of requirements, responsiveness)
            quest.feedbackSubmittedByProvider = true;
            // For provider's feedback on seeker, we could use a different set of scores or apply to a "seeker" reputation.
            // For now, let's just log it and potentially update a generic "collaborator" score if it existed.
            // This example focuses on provider's skill reputation.
            primarySkillHash = keccak256("GeneralCollaboratorReputation"); // Placeholder for seeker's 'skill'
            // Ensure this skillCategory exists or is auto-approved.
        } else {
            revert("Only seeker or provider can submit feedback");
        }

        SkillReputation storage rep = userProfiles[targetUser].skillReputations[primarySkillHash];
        
        // Decay existing reputation before updating
        _applyReputationDecay(targetUser, primarySkillHash);

        // Update based on new feedback (weighted average to allow new feedback to influence more)
        // Scores are 0-100, ratings 1-5. Scale ratings to 0-100 for averaging (rating * 20)
        rep.qualityScore = (rep.qualityScore * 4 + (_qualityRating * 20)) / 5; 
        rep.communicationScore = (rep.communicationScore * 4 + (_communicationRating * 20)) / 5;
        rep.reliabilityScore = (rep.reliabilityScore * 4 + (_reliabilityRating * 20)) / 5;
        
        // Calculate overall score (0-1000, 10x for precision)
        rep.overallScore = ((rep.qualityScore + rep.communicationScore + rep.reliabilityScore) / 3) * 10;
        rep.lastUpdated = block.timestamp;

        emit FeedbackSubmitted(_questId, msg.sender, targetUser, _qualityRating, _communicationRating, _reliabilityRating);
        emit ReputationUpdated(targetUser, primarySkillHash, rep.overallScore);
    }

    /// @notice Retrieves the specific reputation score for a user pertaining to a given skill.
    /// @param _user The address of the user.
    /// @param _skillHash The unique identifier for the skill.
    /// @return overallScore The general reputation score for this skill (scaled by 10 for precision).
    /// @return qualityScore The quality score for this skill (0-100).
    /// @return communicationScore The communication score (0-100).
    /// @return reliabilityScore The reliability score (0-100).
    function getReputationScore(address _user, bytes32 _skillHash) external view returns (uint256 overallScore, uint256 qualityScore, uint256 communicationScore, uint256 reliabilityScore) {
        // This view function will return the current (potentially stale) values.
        // Off-chain clients should call a helper function or estimate decay based on `lastUpdated`.
        SkillReputation storage rep = userProfiles[_user].skillReputations[_skillHash];
        return (rep.overallScore, rep.qualityScore, rep.reliabilityScore, rep.communicationScore);
    }

    /// @notice Internal helper to apply reputation decay.
    /// @param _user The user whose reputation to decay.
    /// @param _skillHash The skill hash for which to decay reputation.
    function _applyReputationDecay(address _user, bytes32 _skillHash) internal {
        SkillReputation storage rep = userProfiles[_user].skillReputations[_skillHash];
        if (rep.overallScore == 0 || reputationDecayInterval == 0 || rep.lastUpdated == 0) return; 

        uint256 timeElapsed = block.timestamp - rep.lastUpdated;
        if (timeElapsed < reputationDecayInterval) return;

        uint256 intervalsPassed = timeElapsed / reputationDecayInterval;
        uint256 currentOverallScore = rep.overallScore;
        uint256 currentQualityScore = rep.qualityScore;
        uint256 currentCommunicationScore = rep.communicationScore;
        uint256 currentReliabilityScore = rep.reliabilityScore;
        
        for (uint256 i = 0; i < intervalsPassed; i++) {
            currentOverallScore = currentOverallScore - (currentOverallScore * reputationDecayRateBasisPoints / 10000);
            currentQualityScore = currentQualityScore - (currentQualityScore * reputationDecayRateBasisPoints / 10000);
            currentCommunicationScore = currentCommunicationScore - (currentCommunicationScore * reputationDecayRateBasisPoints / 10000);
            currentReliabilityScore = currentReliabilityScore - (currentReliabilityScore * reputationDecayRateBasisPoints / 10000);
            
            // Ensure scores don't drop too low (e.g., maintain a minimum base of 10% of max for active users)
            if (currentOverallScore < 100) currentOverallScore = 100; // Min 10.0 (100 in 10x scale)
            if (currentQualityScore < 10) currentQualityScore = 10;
            if (currentCommunicationScore < 10) currentCommunicationScore = 10;
            if (currentReliabilityScore < 10) currentReliabilityScore = 10;
        }

        rep.overallScore = currentOverallScore;
        rep.qualityScore = currentQualityScore;
        rep.communicationScore = currentCommunicationScore;
        rep.reliabilityScore = currentReliabilityScore;
        rep.lastUpdated = block.timestamp; 
    }

    /// @notice Admin function to adjust how reputation scores decay over time due to inactivity.
    /// @param _decayRateBasisPoints The percentage of decay per interval (e.g., 100 for 1%).
    /// @param _decayInterval The time interval in seconds after which decay is applied.
    function updateReputationDecayParameters(uint256 _decayRateBasisPoints, uint256 _decayInterval) external onlyOwner {
        require(_decayRateBasisPoints <= 10000, "Decay rate cannot exceed 100%");
        reputationDecayRateBasisPoints = _decayRateBasisPoints;
        reputationDecayInterval = _decayInterval;
        emit ReputationDecayParamsUpdated(_decayRateBasisPoints, _decayInterval);
    }


    // --- IV. Governance & Protocol Management ---

    /// @notice Allows a registered user to propose a new hierarchical skill category.
    /// @param _name The human-readable name of the skill category.
    /// @param _parentHash The skill hash of the parent category, or bytes32(0) for a top-level category.
    function proposeSkillCategory(string calldata _name, bytes32 _parentHash) external onlyRegisteredUser {
        bytes32 newSkillHash = keccak256(abi.encodePacked(_name, _parentHash));
        require(!skillCategories[newSkillHash].exists, "Skill category already proposed or exists");
        
        if (_parentHash != bytes32(0)) {
            require(skillCategories[_parentHash].approved, "Parent skill category must be approved");
        }

        skillCategories[newSkillHash] = SkillCategory({
            exists: true,
            name: _name,
            parentHash: _parentHash,
            proposalTime: block.timestamp,
            approvalVotes: 0,
            rejectionVotes: 0,
            approved: false
        });
        proposedSkillCategoryHashes.push(newSkillHash);
        emit SkillCategoryProposed(newSkillHash, _name, _parentHash);
    }

    /// @notice Enables users to vote on proposed skill categories.
    /// @param _skillHash The hash of the proposed skill category.
    /// @param _approve True to vote for approval, false to vote for rejection.
    function voteOnSkillCategory(bytes32 _skillHash, bool _approve) external onlyRegisteredUser {
        SkillCategory storage category = skillCategories[_skillHash];
        require(category.exists && !category.approved, "Skill category not proposed or already approved");
        require(!category.votes[msg.sender], "Already voted on this skill category");

        category.votes[msg.sender] = true;
        if (_approve) {
            category.approvalVotes++;
        } else {
            category.rejectionVotes++;
        }

        // Simple approval mechanism: e.g., if total votes >= 5 and 80% approval
        uint256 totalVotes = category.approvalVotes + category.rejectionVotes;
        if (totalVotes >= 5 && (category.approvalVotes * 100) / totalVotes >= 80) {
            category.approved = true;
            emit SkillCategoryApproved(_skillHash);
        }
        emit SkillCategoryVoted(msg.sender, _skillHash, _approve);
    }

    /// @notice Admin function to adjust the protocol's fee percentage on quest bounties.
    /// @param _newFeeBasisPoints The new fee in basis points (e.g., 500 for 5%).
    function setProtocolFee(uint256 _newFeeBasisPoints) external onlyOwner {
        require(_newFeeBasisPoints <= 1000, "Fee cannot exceed 10%"); // Capped at 10%
        uint256 oldFee = protocolFeeBasisPoints;
        protocolFeeBasisPoints = _newFeeBasisPoints;
        emit ProtocolFeeUpdated(oldFee, _newFeeBasisPoints);
    }

    /// @notice Allows the admin to withdraw accumulated protocol fees to the designated fee wallet.
    function withdrawFees() external onlyOwner nonReentrant {
        uint256 feesToWithdraw = accumulatedFees;
        accumulatedFees = 0;
        if (feesToWithdraw > 0) {
            payable(protocolFeeWallet).transfer(feesToWithdraw);
            emit FeesWithdrawn(protocolFeeWallet, feesToWithdraw);
        }
    }

    /// @notice Admin function to update the trusted AI matching oracle's address.
    /// @param _newOracle The address of the new AI matching oracle.
    function updateOracleAddress(address _newOracle) external onlyOwner {
        require(_newOracle != address(0), "Invalid oracle address");
        address oldOracle = aiMatchingOracle;
        aiMatchingOracle = _newOracle;
        emit OracleAddressUpdated(oldOracle, _newOracle);
    }

    /// @notice Admin function to set the address of the dedicated dispute resolution contract or entity.
    /// @param _resolver The address of the new dispute resolver.
    function setDisputeResolver(address _resolver) external onlyOwner {
        require(_resolver != address(0), "Invalid dispute resolver address");
        address oldResolver = disputeResolver;
        disputeResolver = _resolver;
        emit DisputeResolverUpdated(oldResolver, _resolver);
    }
}

// Helper library for min/max operations
library Math {
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }
}
```