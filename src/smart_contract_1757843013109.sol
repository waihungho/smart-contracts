Here's a Solidity smart contract named `CognitiveNexus` that implements a Decentralized Adaptive Learning & Curation Network. This contract integrates advanced concepts like dynamic relevance scoring, AI oracle integration, a reputation-based governance system, and gamified incentives, all without directly duplicating existing open-source protocols.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol"; // Using Ownable for initial deployment and administrative functions, to be replaced by full DAO control.

/**
 * @title CognitiveNexus
 * @dev A decentralized adaptive learning and curation network for knowledge capsules.
 *      Users contribute "knowledge capsules" (data, insights, research) which are dynamically
 *      evaluated for relevance by community consensus and an AI oracle. Capsule relevance scores
 *      evolve over time, and contributors earn rewards and reputation based on the utility and accuracy
 *      of their contributions and evaluations.
 *
 * Outline:
 * I. Core Data Structures & State Variables: Defines the structural elements and core state.
 * II. Module: Capsule Management (Contribution & Lifecycle): Handles submission, updates, and status changes of knowledge capsules.
 * III. Module: Evaluation & Dynamic Relevance Scoring: Manages community and AI evaluations, and updates capsule relevance.
 * IV. Module: Contributor Reputation & Rewards: Manages contributor profiles, reputation scores, and reward distribution.
 * V. Module: Decentralized Governance: Enables community-driven changes to protocol parameters and dispute resolution.
 * VI. Module: AI Oracle Integration & Dispute Resolution: Facilitates interaction with an off-chain AI oracle and formal dispute processes.
 * VII. Module: Utility & Access Control: Provides general utilities and enforces access permissions (initially Ownable, moving to DAO).
 */
contract CognitiveNexus is Ownable {

    // --- Custom Errors ---
    // Provides descriptive error messages, a feature of Solidity 0.8.0+
    error Unauthorized();
    error CapsuleNotFound(uint256 capsuleId);
    error InvalidCapsuleStatus(uint256 capsuleId, string expectedStatus);
    error EvaluationRoundNotActive(uint256 roundId);
    error EvaluationRoundAlreadyActive(uint256 capsuleId);
    error EvaluationRoundExpired(uint256 roundId); // Used when calling before or after evaluation window
    error AlreadyVotedInRound(uint256 entityId); // Used for both evaluation rounds and proposals
    error InsufficientStake(uint256 requiredStake);
    error InsufficientReputation(uint256 requiredReputation);
    error ProposalNotFound(uint256 proposalId);
    error ProposalNotExecutable(uint256 proposalId);
    error ProposalVotingPeriodActive(uint256 proposalId); // Used when voting is still active or execution attempts too early/late
    error ProposalAlreadyExecuted(uint256 proposalId);
    error InvalidParameterValue(string parameterName);
    error NotEnoughFundsInRewardPool(uint256 requestedAmount);
    error SelfInteractionForbidden(); // Prevents a contract from interacting with itself in unexpected ways

    // --- Function Summary ---

    // II. Capsule Management (Contribution & Lifecycle)
    // 1.  submitKnowledgeCapsule(string calldata _contentHash, string calldata _metadataCID):
    //     Submits a new knowledge capsule with IPFS/Arweave CIDs for content and metadata.
    //     Initializes the capsule in 'Pending' status, awaiting evaluation. Assigns initial reputation if new contributor.
    // 2.  updateCapsuleContent(uint256 _capsuleId, string calldata _newContentHash):
    //     Allows the owner to propose an update to a capsule's content hash. This may trigger
    //     re-evaluation or require governance approval depending on its status.
    // 3.  requestCapsuleEvaluation(uint256 _capsuleId):
    //     Initiates a community evaluation round for a specified knowledge capsule.
    //     Automatically transitions 'Pending' capsules to 'Active'.
    // 4.  retireCapsule(uint256 _capsuleId):
    //     Allows the capsule owner or governance to mark a capsule as 'Deprecated',
    //     removing it from active consideration and reward eligibility.
    // 5.  getCapsuleDetails(uint256 _capsuleId):
    //     Retrieves all stored details for a given knowledge capsule ID.
    // 6.  listActiveCapsuleIDs():
    //     Returns an array of IDs for all capsules currently in 'Active' status.
    //     (Note: Can be gas-intensive for large numbers; off-chain indexing recommended for scale).

    // III. Evaluation & Dynamic Relevance Scoring
    // 7.  submitEvaluationVote(uint256 _roundId, uint256 _score):
    //     Allows a contributor to submit their subjective relevance score (0-10000) for a capsule
    //     within an active evaluation round. Requires a stake (returned upon finalization) and minimum reputation.
    // 8.  requestAIRelevanceCheck(uint256 _capsuleId):
    //     Signals to the off-chain AI oracle to perform an objective relevance assessment for a capsule.
    //     This doesn't change state but is a trigger for the oracle.
    // 9.  confirmAIRelevanceScore(uint256 _roundId, uint256 _aiScore):
    //     Called *only* by the trusted AI oracle address to submit its calculated relevance score (0-10000)
    //     for an evaluation round.
    // 10. finalizeEvaluationRound(uint256 _roundId):
    //     Processes all community votes and the AI oracle's input (if available) after the evaluation period ends.
    //     Calculates a new dynamic relevance score for the capsule, updates its evolution history,
    //     and potentially distributes rewards and updates reputation.
    // 11. disputeCapsuleStatus(uint256 _capsuleId, string calldata _reason):
    //     Allows a contributor to challenge a capsule's current status or relevance,
    //     creating a governance proposal for review and marking the capsule as 'Disputed'.

    // IV. Contributor Reputation & Rewards
    // 12. getContributorProfile(address _contributor):
    //     Retrieves the detailed profile (reputation score, contributions, etc.) for a specific contributor address.
    // 13. calculatePendingRewards(address _contributor):
    //     Estimates the total rewards currently claimable by a contributor.
    // 14. claimCapsuleRewards():
    //     Allows a contributor to withdraw their accumulated ETH rewards from the reward pool.

    // V. Decentralized Governance
    // 15. submitGovernanceProposal(string calldata _description, address _targetAddress, bytes calldata _callData, bool _requiresSuperMajority):
    //     Allows eligible contributors to propose changes to system parameters or other on-chain actions.
    //     Requires a stake and minimum reputation.
    // 16. voteOnProposal(uint256 _proposalId, bool _support):
    //     Allows eligible contributors to cast a 'yay' or 'nay' vote on an active governance proposal.
    //     Voting power is proportional to their reputation score, and requires a stake.
    // 17. executeProposal(uint256 _proposalId):
    //     Executes a passed governance proposal after its voting period ends,
    //     if it meets the required quorum and threshold.

    // VI. AI Oracle Integration & Dispute Resolution
    // (Functions 9 and 11 also fall here, but are listed under their primary modules)
    // 18. updateAIOracleAddress(address _newAIOracleAddress):
    //     A governance-controlled function to change the trusted AI oracle's address.
    //     (Initially `onlyOwner`, but designed to be called via `executeProposal`).

    // VII. Utility & Access Control
    // 19. depositToRewardPool(uint256 _amount):
    //     Allows any address to contribute ETH to the general reward pool.
    // 20. withdrawFromRewardPool(uint256 _amount, address _recipient):
    //     Allows governance (or `onlyOwner` initially) to withdraw funds from the reward pool,
    //     e.g., for operational costs or directed payouts.
    // 21. getStakedAmount(uint256 _entityId):
    //     Retrieves the total amount currently staked for a specific evaluation round or proposal.
    //     (Note: Current implementation merges stakes to rewardPool, this is conceptual).
    // 22. updateSystemParameter(string calldata _parameterName, uint256 _newValue):
    //     Allows governance (or `onlyOwner` initially) to modify various core parameters of the system,
    //     such as evaluation periods, stake amounts, or reputation thresholds.
    // 23. getEvolutionHistory(uint256 _capsuleId):
    //     Retrieves the array of historical relevance score snapshots for a given capsule.

    // --- I. Core Data Structures & State Variables ---

    // Status of a Knowledge Capsule
    enum CapsuleStatus {
        Pending,    // Waiting for initial evaluation
        Active,     // Publicly available, undergoing continuous evaluation
        Deprecated, // Deemed irrelevant or inaccurate
        Disputed    // Under governance review due to a dispute
    }

    // Source of a relevance score update
    enum ScoreSource {
        Community,
        AIOracle,
        Governance
    }

    // Records a historical snapshot of a capsule's relevance score
    struct RelevanceSnapshot {
        uint64 timestamp;      // When the score was recorded
        uint256 relevanceScore; // The score at that time (scaled: 0-10000, where 10000 = 100%)
        ScoreSource source;     // Who or what caused this update
    }

    // Represents a Knowledge Capsule
    struct KnowledgeCapsule {
        uint256 id;                 // Unique identifier for the capsule
        address owner;              // Address of the original contributor
        string contentHash;         // IPFS/Arweave CID of the actual knowledge data
        string metadataCID;         // IPFS/Arweave CID for display metadata (e.g., title, description)
        uint64 creationTime;        // Timestamp of creation
        uint64 lastUpdatedTime;     // Last time content or status was updated
        uint256 currentRelevanceScore; // Dynamic score (scaled: 0-10000)
        CapsuleStatus status;       // Current status of the capsule
        uint256 activeEvaluationRoundId; // 0 if no active round, otherwise ID of the current round
        RelevanceSnapshot[] evolutionHistory; // Recent history of relevance score changes (limited length to save gas)
        uint256 totalRewardAccrued; // Total rewards accumulated by this capsule over its lifetime
    }

    // Represents a Contributor's Profile (akin to an SBT score)
    struct ContributorProfile {
        uint256 reputationScore;        // Overall reputation, influences voting power and reward multipliers
        uint256 totalCapsulesSubmitted; // Count of capsules submitted
        uint256 successfulEvaluations;  // Count of accurate evaluation votes
        uint64 lastActivityTime;        // Timestamp of last significant interaction
        uint256 pendingRewards;         // Rewards claimable by the contributor
    }

    // Represents an ongoing evaluation round for a capsule
    struct EvaluationRound {
        uint256 id;                     // Unique ID for the evaluation round
        uint256 capsuleId;              // The capsule being evaluated
        uint64 startTime;               // When the round began
        uint64 endTime;                 // When the round ends
        mapping(address => uint256) communityVotes; // Voter => score they submitted (scaled: 0-10000)
        mapping(address => bool) hasVoted;          // To prevent double voting
        address[] participants;                     // Explicit list of voters for iteration
        uint256 totalCommunityScoreSum; // Sum of all community scores submitted
        uint256 communityVoteCount;     // Number of community votes
        uint256 aiSubmittedScore;       // Score submitted by the AI oracle (0 if not yet submitted)
        bool aiScoreConfirmed;          // True if AI score has been confirmed by oracle
        uint256 totalStakedForEvaluation; // Total Ether staked for this evaluation round
        bool isActive;                  // True if the round is currently open for votes/AI input
        bool finalized;                 // True if the round has been processed and scores updated
    }

    // Represents a governance proposal
    struct GovernanceProposal {
        uint256 id;                     // Unique proposal ID
        address proposer;               // Address that submitted the proposal
        string description;             // Description of the proposal
        uint64 creationTime;            // Timestamp of creation
        uint64 votingEndTime;           // When voting for this proposal ends
        uint256 yayVotes;               // Total reputation score of 'yay' voters
        uint252 nayVotes;               // Total reputation score of 'nay' voters
        mapping(address => bool) hasVoted; // Tracks if an address has voted
        bool executed;                  // True if the proposal has been executed
        address targetAddress;          // Contract address to call if proposal passes
        bytes callData;                 // Calldata for the target function
        bool requiresSuperMajority;     // True for critical parameter changes (e.g., AI oracle address)
    }

    // Global System Parameters, configurable by Governance
    struct SystemParameters {
        uint256 minRelevanceForActive;      // Minimum score (0-10000) for a capsule to be 'Active'
        uint256 initialReputationScore;     // Starting reputation for new contributors
        uint256 evaluationStakeAmount;      // ETH required to vote in an evaluation round
        uint256 proposalVoteStakeAmount;    // ETH required to vote on a governance proposal/dispute
        uint32 evaluationPeriodSeconds;     // Duration of an evaluation round in seconds
        uint32 proposalVotingPeriodSeconds; // Duration for governance proposal voting in seconds
        uint256 minReputationForProposing;  // Min reputation to submit a governance proposal
        uint252 minReputationForVoting;     // Min reputation to vote on a governance proposal or evaluation
        uint256 governanceQuorumFraction;   // (e.g., 2500 for 25%) minimum total reputation participating in a proposal for it to be valid
        uint256 superMajorityThreshold;     // (e.g., 6667 for 66.67%) 'yay' vote fraction for critical proposals
        uint256 maxEvolutionHistoryLength;  // Max snapshots stored on-chain for capsule history
        uint256 aiScoreWeight;              // Weight of AI score in final relevance (e.g., 3000 for 30%, community gets 70%)
        uint256 reputationBoostForAccuracy; // Points awarded for accurate evaluations
        uint256 reputationPenaltyForInaccuracy; // Points deducted for inaccurate evaluations
    }

    // State Variables
    uint256 public nextCapsuleId = 1;
    uint256 public nextEvaluationRoundId = 1;
    uint256 public nextProposalId = 1;

    address public aiOracleAddress; // The trusted address for submitting AI relevance scores
    address public governanceTreasuryAddress; // Address where governance fees/stakes might accumulate for operational use

    uint252 public rewardPoolBalance; // Total ETH available for rewards (stakes, deposits, etc.)

    SystemParameters public params;

    mapping(uint256 => KnowledgeCapsule) public capsules;
    mapping(address => ContributorProfile) public contributors;
    mapping(uint256 => EvaluationRound) public evaluationRounds;
    mapping(uint256 => GovernanceProposal) public proposals;

    // --- Events ---
    event CapsuleSubmitted(uint256 indexed capsuleId, address indexed owner, string contentHash, uint64 timestamp);
    event CapsuleContentUpdated(uint256 indexed capsuleId, string newContentHash, uint64 timestamp);
    event CapsuleStatusUpdated(uint256 indexed capsuleId, CapsuleStatus newStatus, uint64 timestamp);
    event EvaluationRoundStarted(uint256 indexed roundId, uint256 indexed capsuleId, uint64 endTime);
    event EvaluationVoteSubmitted(uint256 indexed roundId, address indexed voter, uint256 score);
    event AIRelevanceConfirmed(uint256 indexed roundId, uint256 indexed capsuleId, uint256 aiScore);
    event EvaluationRoundFinalized(uint256 indexed roundId, uint256 indexed capsuleId, uint252 newRelevanceScore, uint64 timestamp);
    event ContributorReputationUpdated(address indexed contributor, uint252 newReputationScore);
    event RewardsClaimed(address indexed contributor, uint252 amount);
    event GovernanceProposalSubmitted(uint252 indexed proposalId, address indexed proposer, string description, uint64 votingEndTime);
    event GovernanceVoteCast(uint252 indexed proposalId, address indexed voter, bool support);
    event GovernanceProposalExecuted(uint252 indexed proposalId, bool success);
    event AIOracleAddressUpdated(address indexed newAddress);
    event SystemParameterUpdated(string indexed parameterName, uint252 oldValue, uint252 newValue);
    event FundsDeposited(address indexed depositor, uint252 amount);
    event FundsWithdrawn(address indexed recipient, uint252 amount);
    event StakeReceived(address indexed staker, uint252 indexed entityId, uint252 amount);
    event StakeReleased(address indexed staker, uint252 indexed entityId, uint252 amount);

    // --- Modifiers ---
    modifier onlyAIOracle() {
        if (msg.sender != aiOracleAddress) revert Unauthorized();
        _;
    }

    // Constructor: Initializes the contract with the AI oracle address and governance treasury.
    constructor(address _aiOracleAddress, address _governanceTreasuryAddress) Ownable(msg.sender) {
        if (_aiOracleAddress == address(0) || _governanceTreasuryAddress == address(0)) {
            revert InvalidParameterValue("Addresses cannot be zero");
        }
        aiOracleAddress = _aiOracleAddress;
        governanceTreasuryAddress = _governanceTreasuryAddress;

        // Initialize default system parameters
        params = SystemParameters({
            minRelevanceForActive: 5000,         // 50%
            initialReputationScore: 100,
            evaluationStakeAmount: 0.01 ether,
            proposalVoteStakeAmount: 0.005 ether,
            evaluationPeriodSeconds: 3 days,     // 3 days
            proposalVotingPeriodSeconds: 7 days, // 7 days
            minReputationForProposing: 500,
            minReputationForVoting: 100,
            governanceQuorumFraction: 2500,      // 25% of total reputation
            superMajorityThreshold: 6667,        // 66.67%
            maxEvolutionHistoryLength: 10,       // Keep last 10 snapshots on-chain
            aiScoreWeight: 3000,                 // 30% weight for AI score in final relevance calculation
            reputationBoostForAccuracy: 10,
            reputationPenaltyForInaccuracy: 5
        });

        // Initialize deployer's reputation to give them a head start in governance/activity
        contributors[msg.sender].reputationScore = params.initialReputationScore * 10;
        contributors[msg.sender].lastActivityTime = uint64(block.timestamp);
    }

    // --- II. Module: Capsule Management (Contribution & Lifecycle) ---

    /**
     * @dev 1. Submits a new knowledge capsule to the network.
     *      The capsule starts in 'Pending' status, awaiting initial evaluation.
     *      Contributor receives initial reputation if new.
     * @param _contentHash IPFS/Arweave CID of the actual knowledge data.
     * @param _metadataCID IPFS/Arweave CID of the display metadata (e.g., title, description).
     */
    function submitKnowledgeCapsule(string calldata _contentHash, string calldata _metadataCID) external {
        if (bytes(_contentHash).length == 0 || bytes(_metadataCID).length == 0) {
            revert InvalidParameterValue("Content or metadata hash cannot be empty");
        }

        uint256 capsuleId = nextCapsuleId++;
        uint64 currentTime = uint64(block.timestamp);

        KnowledgeCapsule storage newCapsule = capsules[capsuleId];
        newCapsule.id = capsuleId;
        newCapsule.owner = msg.sender;
        newCapsule.contentHash = _contentHash;
        newCapsule.metadataCID = _metadataCID;
        newCapsule.creationTime = currentTime;
        newCapsule.lastUpdatedTime = currentTime;
        newCapsule.currentRelevanceScore = 0; // Initial score
        newCapsule.status = CapsuleStatus.Pending;
        newCapsule.activeEvaluationRoundId = 0;
        // Initial entry in evolution history
        newCapsule.evolutionHistory.push(RelevanceSnapshot(currentTime, 0, ScoreSource.Community));

        // Update contributor profile (or create if new)
        ContributorProfile storage contributor = contributors[msg.sender];
        if (contributor.reputationScore == 0) {
            contributor.reputationScore = params.initialReputationScore;
        }
        contributor.totalCapsulesSubmitted++;
        contributor.lastActivityTime = currentTime;

        emit CapsuleSubmitted(capsuleId, msg.sender, _contentHash, currentTime);
    }

    /**
     * @dev 2. Allows the owner to propose an update to a capsule's content.
     *      Requires the capsule to be in 'Pending' or 'Active' status.
     *      If active, it might implicitly trigger a new evaluation round or require explicit governance approval
     *      (though for simplicity here, it just updates and is subject to re-evaluation).
     * @param _capsuleId The ID of the capsule to update.
     * @param _newContentHash The new IPFS/Arweave CID for the capsule's content.
     */
    function updateCapsuleContent(uint256 _capsuleId, string calldata _newContentHash) external {
        KnowledgeCapsule storage capsule = capsules[_capsuleId];
        if (capsule.id == 0) revert CapsuleNotFound(_capsuleId);
        if (capsule.owner != msg.sender) revert Unauthorized();
        if (capsule.status == CapsuleStatus.Deprecated || capsule.status == CapsuleStatus.Disputed) {
            revert InvalidCapsuleStatus(_capsuleId, "Pending or Active");
        }
        if (bytes(_newContentHash).length == 0) revert InvalidParameterValue("Content hash cannot be empty");
        if (keccak256(abi.encodePacked(capsule.contentHash)) == keccak256(abi.encodePacked(_newContentHash))) {
            revert InvalidParameterValue("New content hash is identical to current");
        }

        capsule.contentHash = _newContentHash;
        capsule.lastUpdatedTime = uint64(block.timestamp);

        emit CapsuleContentUpdated(_capsuleId, _newContentHash, uint64(block.timestamp));
    }

    /**
     * @dev 3. Allows a contributor to request an evaluation round for a capsule.
     *      Automatically initiated for 'Pending' capsules when this is called.
     * @param _capsuleId The ID of the capsule to evaluate.
     */
    function requestCapsuleEvaluation(uint256 _capsuleId) external {
        KnowledgeCapsule storage capsule = capsules[_capsuleId];
        if (capsule.id == 0) revert CapsuleNotFound(_capsuleId);
        if (capsule.activeEvaluationRoundId != 0 && evaluationRounds[capsule.activeEvaluationRoundId].isActive) {
            revert EvaluationRoundAlreadyActive(_capsuleId);
        }

        uint256 roundId = nextEvaluationRoundId++;
        uint64 currentTime = uint64(block.timestamp);

        EvaluationRound storage newRound = evaluationRounds[roundId];
        newRound.id = roundId;
        newRound.capsuleId = _capsuleId;
        newRound.startTime = currentTime;
        newRound.endTime = currentTime + params.evaluationPeriodSeconds;
        newRound.isActive = true;
        newRound.finalized = false;

        capsule.activeEvaluationRoundId = roundId;
        if (capsule.status == CapsuleStatus.Pending) {
            capsule.status = CapsuleStatus.Active; // Capsule becomes active once evaluation starts
            emit CapsuleStatusUpdated(_capsuleId, CapsuleStatus.Active, currentTime);
        }

        emit EvaluationRoundStarted(roundId, _capsuleId, newRound.endTime);
    }

    /**
     * @dev 4. Allows a capsule owner or governance to deprecate a capsule.
     *      Deprecated capsules are no longer considered active or eligible for rewards.
     * @param _capsuleId The ID of the capsule to retire.
     */
    function retireCapsule(uint256 _capsuleId) external {
        KnowledgeCapsule storage capsule = capsules[_capsuleId];
        if (capsule.id == 0) revert CapsuleNotFound(_capsuleId);
        // Access control: only owner or contract owner (for governance) can retire
        if (capsule.owner != msg.sender && Ownable.owner() != msg.sender) {
            revert Unauthorized();
        }

        if (capsule.status == CapsuleStatus.Deprecated) return; // Already deprecated

        capsule.status = CapsuleStatus.Deprecated;
        capsule.lastUpdatedTime = uint64(block.timestamp);

        // In a more complex system, pending rewards for this capsule might be frozen or redirected.
        // For simplicity here, we just change status.

        emit CapsuleStatusUpdated(_capsuleId, CapsuleStatus.Deprecated, uint64(block.timestamp));
    }

    /**
     * @dev 5. Retrieves comprehensive details about a specific knowledge capsule.
     * @param _capsuleId The ID of the capsule to query.
     * @return KnowledgeCapsule struct.
     */
    function getCapsuleDetails(uint252 _capsuleId) external view returns (KnowledgeCapsule memory) {
        if (capsules[_capsuleId].id == 0) revert CapsuleNotFound(_capsuleId);
        return capsules[_capsuleId];
    }

    /**
     * @dev 6. Returns a list of all currently active knowledge capsule IDs.
     *      (Note: This can be gas-intensive for large numbers of capsules.
     *       In a real system, pagination or off-chain indexing would be preferred).
     * @return An array of active capsule IDs.
     */
    function listActiveCapsuleIDs() external view returns (uint252[] memory) {
        uint256[] memory activeCapsuleIds = new uint256[](nextCapsuleId - 1); // Max possible size
        uint256 count = 0;
        for (uint256 i = 1; i < nextCapsuleId; i++) {
            if (capsules[i].status == CapsuleStatus.Active) {
                activeCapsuleIds[count] = i;
                count++;
            }
        }
        // Resize array to actual count
        uint256[] memory result = new uint256[](count);
        for (uint256 i = 0; i < count; i++) {
            result[i] = activeCapsuleIds[i];
        }
        return result;
    }

    // --- III. Module: Evaluation & Dynamic Relevance Scoring ---

    /**
     * @dev 7. Allows contributors to cast their vote on a capsule's relevance.
     *      Requires a stake and minimum reputation. Stake is added to the reward pool and conceptually
     *      released/returned upon round finalization (via `claimCapsuleRewards` or `claimStake`).
     * @param _roundId The ID of the evaluation round.
     * @param _score The subjective score (0-10000) from the contributor.
     */
    function submitEvaluationVote(uint256 _roundId, uint256 _score) external payable {
        EvaluationRound storage round = evaluationRounds[_roundId];
        if (round.id == 0 || !round.isActive || round.finalized) {
            revert EvaluationRoundNotActive(_roundId);
        }
        if (block.timestamp >= round.endTime) {
            revert EvaluationRoundExpired(_roundId);
        }
        if (_score > 10000) {
            revert InvalidParameterValue("Score out of range (0-10000)");
        }
        if (round.hasVoted[msg.sender]) {
            revert AlreadyVotedInRound(_roundId);
        }
        if (msg.value < params.evaluationStakeAmount) {
            revert InsufficientStake(params.evaluationStakeAmount);
        }
        if (contributors[msg.sender].reputationScore < params.minReputationForVoting) {
            revert InsufficientReputation(params.minReputationForVoting);
        }

        round.communityVotes[msg.sender] = _score;
        round.hasVoted[msg.sender] = true;
        round.participants.push(msg.sender); // Track participants for iteration during finalization
        round.totalCommunityScoreSum += _score;
        round.communityVoteCount++;
        round.totalStakedForEvaluation += msg.value;
        rewardPoolBalance += msg.value; // Stakes are added to the reward pool (returned upon finalization)

        emit EvaluationVoteSubmitted(_roundId, msg.sender, _score);
        emit StakeReceived(msg.sender, _roundId, msg.value);

        contributors[msg.sender].lastActivityTime = uint64(block.timestamp);
    }

    /**
     * @dev 8. Initiates an AI oracle request for an objective relevance assessment.
     *      Can be called by anyone. This function primarily serves as an off-chain signal
     *      to the AI oracle system. The actual AI-determined score is then submitted
     *      via `confirmAIRelevanceScore`.
     * @param _capsuleId The ID of the capsule for which to request an AI check.
     */
    function requestAIRelevanceCheck(uint256 _capsuleId) external {
        KnowledgeCapsule storage capsule = capsules[_capsuleId];
        if (capsule.id == 0) revert CapsuleNotFound(_capsuleId);
        if (capsule.activeEvaluationRoundId == 0) {
            // No active round, or round already finalized.
            // A new evaluation round should be requested first if the capsule isn't undergoing one.
            revert EvaluationRoundNotActive(0);
        }

        EvaluationRound storage round = evaluationRounds[capsule.activeEvaluationRoundId];
        if (!round.isActive || round.finalized) revert EvaluationRoundNotActive(round.id);

        // Emit an event to be picked up by off-chain AI oracle listeners.
        // No explicit state change here, just a trigger.
        // event AIRelevanceCheckRequested(uint256 indexed capsuleId, uint256 indexed roundId, uint64 timestamp);
        // Could be added if needed for explicit off-chain communication.
    }

    /**
     * @dev 9. Called by the trusted AI oracle to update a capsule's AI-determined relevance score.
     *      This function can only be called by the `aiOracleAddress`.
     * @param _roundId The ID of the active evaluation round.
     * @param _aiScore The relevance score (0-10000) determined by the AI model.
     */
    function confirmAIRelevanceScore(uint256 _roundId, uint256 _aiScore) external onlyAIOracle {
        EvaluationRound storage round = evaluationRounds[_roundId];
        if (round.id == 0 || !round.isActive || round.finalized) {
            revert EvaluationRoundNotActive(_roundId);
        }
        if (_aiScore > 10000) {
            revert InvalidParameterValue("AI Score out of range (0-10000)");
        }
        if (round.aiScoreConfirmed) {
            revert InvalidParameterValue("AI score already confirmed for this round");
        }

        round.aiSubmittedScore = _aiScore;
        round.aiScoreConfirmed = true;

        emit AIRelevanceConfirmed(_roundId, round.capsuleId, _aiScore);
    }

    /**
     * @dev 10. Finalizes an evaluation round, calculates new relevance score, and distributes rewards.
     *      Can be called by anyone after the evaluation period ends.
     * @param _roundId The ID of the evaluation round to finalize.
     */
    function finalizeEvaluationRound(uint256 _roundId) external {
        EvaluationRound storage round = evaluationRounds[_roundId];
        if (round.id == 0 || !round.isActive || round.finalized) {
            revert EvaluationRoundNotActive(_roundId);
        }
        if (block.timestamp < round.endTime) {
            revert EvaluationRoundExpired(_roundId); // Revert if called before the round ends
        }

        KnowledgeCapsule storage capsule = capsules[round.capsuleId];
        if (capsule.id == 0) revert CapsuleNotFound(round.capsuleId);

        round.isActive = false; // Close the round
        round.finalized = true;

        uint256 newRelevanceScore;
        uint256 communityAverage = round.communityVoteCount > 0 ? (round.totalCommunityScoreSum / round.communityVoteCount) : 0;

        if (round.aiScoreConfirmed && communityAverage > 0) {
            // Weighted average of community and AI scores
            newRelevanceScore = ((communityAverage * (10000 - params.aiScoreWeight)) + (round.aiSubmittedScore * params.aiScoreWeight)) / 10000;
        } else if (communityAverage > 0) {
            newRelevanceScore = communityAverage;
        } else if (round.aiScoreConfirmed) {
            newRelevanceScore = round.aiSubmittedScore;
        } else {
            // No votes or AI, retain old score or default to 0 if initial
            newRelevanceScore = capsule.creationTime == round.startTime ? 0 : capsule.currentRelevanceScore;
        }

        capsule.currentRelevanceScore = newRelevanceScore;
        capsule.lastUpdatedTime = uint64(block.timestamp);
        capsule.activeEvaluationRoundId = 0; // No active round after finalization

        // Update evolution history (keeping recent history on-chain)
        if (capsule.evolutionHistory.length >= params.maxEvolutionHistoryLength) {
            // Shift elements to remove the oldest
            for (uint i = 0; i < params.maxEvolutionHistoryLength - 1; i++) {
                capsule.evolutionHistory[i] = capsule.evolutionHistory[i+1];
            }
            capsule.evolutionHistory[params.maxEvolutionHistoryLength - 1] = RelevanceSnapshot(uint64(block.timestamp), newRelevanceScore, round.aiScoreConfirmed ? ScoreSource.AIOracle : ScoreSource.Community);
        } else {
            capsule.evolutionHistory.push(RelevanceSnapshot(uint64(block.timestamp), newRelevanceScore, round.aiScoreConfirmed ? ScoreSource.AIOracle : ScoreSource.Community));
        }

        // --- Distribute Rewards and Update Reputation ---
        // 1. Reward capsule owner if score meets threshold, and add to pending rewards
        if (newRelevanceScore >= params.minRelevanceForActive) {
            // Example: 50% of stakes (from voters) are allocated to the capsule owner's pending rewards.
            uint256 capsuleReward = (round.totalStakedForEvaluation / 2);
            if (capsuleReward > 0) {
                if (rewardPoolBalance < capsuleReward) revert NotEnoughFundsInRewardPool(capsuleReward);
                capsule.totalRewardAccrued += capsuleReward;
                contributors[capsule.owner].pendingRewards += capsuleReward;
                rewardPoolBalance -= capsuleReward; // Deduct from main pool
            }
            // Capsule owner's reputation increase for successful contribution
            contributors[capsule.owner].reputationScore += params.reputationBoostForAccuracy * 5; // Higher boost for capsule owner
            emit ContributorReputationUpdated(capsule.owner, contributors[capsule.owner].reputationScore);
        }

        // 2. Return stakes to voters and adjust their reputation based on accuracy
        // Iterate through all participants who voted in this round.
        // The remaining 50% of `round.totalStakedForEvaluation` (plus any extra funds in `rewardPoolBalance`)
        // could be used to reward accurate evaluators or simply returned to them.
        for (uint i = 0; i < round.participants.length; i++) {
            address voter = round.participants[i];
            uint256 submittedScore = round.communityVotes[voter];
            uint256 deviation = (submittedScore > newRelevanceScore) ? (submittedScore - newRelevanceScore) : (newRelevanceScore - submittedScore);

            // Return stake to voter
            uint256 voterStake = params.evaluationStakeAmount; // Assuming fixed stake for simplicity
            if (rewardPoolBalance < voterStake) revert NotEnoughFundsInRewardPool(voterStake);
            contributors[voter].pendingRewards += voterStake; // Add stake back to pending rewards
            rewardPoolBalance -= voterStake;
            emit StakeReleased(voter, _roundId, voterStake);

            // Adjust reputation based on how close their vote was to the final score
            if (deviation <= 1000) { // Example: within 10% deviation (1000 out of 10000)
                contributors[voter].reputationScore += params.reputationBoostForAccuracy;
                contributors[voter].successfulEvaluations++;
            } else {
                contributors[voter].reputationScore = (contributors[voter].reputationScore > params.reputationPenaltyForInaccuracy) ? (contributors[voter].reputationScore - params.reputationPenaltyForInaccuracy) : 0;
            }
            emit ContributorReputationUpdated(voter, contributors[voter].reputationScore);
        }

        emit EvaluationRoundFinalized(_roundId, round.capsuleId, newRelevanceScore, uint64(block.timestamp));
    }

    /**
     * @dev 11. Allows a contributor to challenge a capsule's status or relevance score.
     *      Requires a stake and initiates a governance proposal for review.
     * @param _capsuleId The ID of the capsule being disputed.
     * @param _reason Description of the dispute.
     */
    function disputeCapsuleStatus(uint256 _capsuleId, string calldata _reason) external payable {
        KnowledgeCapsule storage capsule = capsules[_capsuleId];
        if (capsule.id == 0) revert CapsuleNotFound(_capsuleId);
        if (msg.value < params.proposalVoteStakeAmount * 2) { // Higher stake for disputes
            revert InsufficientStake(params.proposalVoteStakeAmount * 2);
        }
        if (contributors[msg.sender].reputationScore < params.minReputationForProposing) {
            revert InsufficientReputation(params.minReputationForProposing);
        }
        if (capsule.status == CapsuleStatus.Disputed) {
            revert InvalidCapsuleStatus(_capsuleId, "Not already Disputed");
        }

        // Create a governance proposal for the dispute
        uint256 proposalId = nextProposalId++;
        uint64 currentTime = uint64(block.timestamp);

        proposals[proposalId] = GovernanceProposal({
            id: proposalId,
            proposer: msg.sender,
            description: string(abi.encodePacked("DISPUTE: Capsule ID ", Strings.toString(_capsuleId), ". Reason: ", _reason)),
            creationTime: currentTime,
            votingEndTime: currentTime + params.proposalVotingPeriodSeconds,
            yayVotes: 0,
            nayVotes: 0,
            hasVoted: new mapping(address => bool),
            executed: false,
            targetAddress: address(0), // No direct target function, governance manually decides outcome
            callData: "",
            requiresSuperMajority: false
        });

        capsule.status = CapsuleStatus.Disputed; // Mark capsule as disputed
        capsule.lastUpdatedTime = currentTime;

        rewardPoolBalance += msg.value; // Dispute stake also goes to reward pool
        emit StakeReceived(msg.sender, proposalId, msg.value);
        emit GovernanceProposalSubmitted(proposalId, msg.sender, proposals[proposalId].description, proposals[proposalId].votingEndTime);
        emit CapsuleStatusUpdated(_capsuleId, CapsuleStatus.Disputed, currentTime);

        contributors[msg.sender].lastActivityTime = currentTime;
    }

    // --- IV. Module: Contributor Reputation & Rewards ---

    /**
     * @dev 12. Retrieves a contributor's reputation score and other relevant stats.
     * @param _contributor The address of the contributor.
     * @return ContributorProfile struct.
     */
    function getContributorProfile(address _contributor) external view returns (ContributorProfile memory) {
        return contributors[_contributor];
    }

    /**
     * @dev 13. Estimates the rewards a contributor can claim.
     * @param _contributor The address of the contributor.
     * @return The estimated amount of claimable rewards.
     */
    function calculatePendingRewards(address _contributor) external view returns (uint256) {
        return contributors[_contributor].pendingRewards;
    }

    /**
     * @dev 14. Allows contributors to claim accumulated rewards from their successful capsules and evaluation activities.
     */
    function claimCapsuleRewards() external {
        if (msg.sender == address(0)) revert SelfInteractionForbidden();

        ContributorProfile storage contributor = contributors[msg.sender];
        uint256 rewardsToClaim = contributor.pendingRewards;

        if (rewardsToClaim == 0) return;

        if (rewardPoolBalance < rewardsToClaim) revert NotEnoughFundsInRewardPool(rewardsToClaim);

        contributor.pendingRewards = 0; // Reset pending rewards
        rewardPoolBalance -= rewardsToClaim;

        // Transfer ETH to the contributor
        (bool success,) = payable(msg.sender).call{value: rewardsToClaim}("");
        if (!success) {
            // Revert the reward claim if transfer fails to prevent loss of funds
            contributor.pendingRewards = rewardsToClaim; // Re-add rewards to pending
            rewardPoolBalance += rewardsToClaim;
            revert("Reward transfer failed");
        }

        emit RewardsClaimed(msg.sender, rewardsToClaim);
        contributor.lastActivityTime = uint64(block.timestamp);
    }

    // --- V. Module: Decentralized Governance ---

    /**
     * @dev 15. Submits a new governance proposal for community voting.
     *      Requires minimum reputation and a stake (added to reward pool).
     * @param _description Description of the proposal.
     * @param _targetAddress The address of the contract to call if the proposal passes (can be this contract).
     * @param _callData The calldata for the target function if the proposal passes.
     * @param _requiresSuperMajority True if this proposal needs a higher voting threshold (e.g., for critical updates like AI oracle address).
     */
    function submitGovernanceProposal(
        string calldata _description,
        address _targetAddress,
        bytes calldata _callData,
        bool _requiresSuperMajority
    ) external payable {
        if (contributors[msg.sender].reputationScore < params.minReputationForProposing) {
            revert InsufficientReputation(params.minReputationForProposing);
        }
        if (msg.value < params.proposalVoteStakeAmount) {
            revert InsufficientStake(params.proposalVoteStakeAmount);
        }

        uint256 proposalId = nextProposalId++;
        uint64 currentTime = uint64(block.timestamp);

        proposals[proposalId] = GovernanceProposal({
            id: proposalId,
            proposer: msg.sender,
            description: _description,
            creationTime: currentTime,
            votingEndTime: currentTime + params.proposalVotingPeriodSeconds,
            yayVotes: 0,
            nayVotes: 0,
            hasVoted: new mapping(address => bool),
            executed: false,
            targetAddress: _targetAddress,
            callData: _callData,
            requiresSuperMajority: _requiresSuperMajority
        });

        rewardPoolBalance += msg.value; // Proposal stake also goes to reward pool
        emit StakeReceived(msg.sender, proposalId, msg.value);
        emit GovernanceProposalSubmitted(proposalId, msg.sender, _description, proposals[proposalId].votingEndTime);

        contributors[msg.sender].lastActivityTime = currentTime;
    }

    /**
     * @dev 16. Allows eligible contributors to vote on an active governance proposal.
     *      Voting power is proportional to reputation score. Requires a stake (added to reward pool).
     * @param _proposalId The ID of the proposal to vote on.
     * @param _support True for 'yay' vote, false for 'nay' vote.
     */
    function voteOnProposal(uint256 _proposalId, bool _support) external payable {
        GovernanceProposal storage proposal = proposals[_proposalId];
        if (proposal.id == 0) revert ProposalNotFound(_proposalId);
        if (block.timestamp >= proposal.votingEndTime) {
            revert ProposalVotingPeriodActive(_proposalId); // Voting period has ended
        }
        if (proposal.hasVoted[msg.sender]) {
            revert AlreadyVotedInRound(_proposalId); // Already voted
        }
        ContributorProfile storage voterProfile = contributors[msg.sender];
        if (voterProfile.reputationScore < params.minReputationForVoting) {
            revert InsufficientReputation(params.minReputationForVoting);
        }
        if (msg.value < params.proposalVoteStakeAmount) {
            revert InsufficientStake(params.proposalVoteStakeAmount);
        }

        proposal.hasVoted[msg.sender] = true;
        uint256 voteWeight = voterProfile.reputationScore; // Voting power proportional to reputation

        if (_support) {
            proposal.yayVotes += voteWeight;
        } else {
            proposal.nayVotes += voteWeight;
        }

        rewardPoolBalance += msg.value; // Vote stake also goes to reward pool
        emit StakeReceived(msg.sender, _proposalId, msg.value);
        emit GovernanceVoteCast(_proposalId, msg.sender, _support);
        voterProfile.lastActivityTime = uint64(block.timestamp);
    }

    /**
     * @dev 17. Executes a passed governance proposal. Can be called by anyone after voting ends.
     *      Requires proposal to meet quorum and threshold.
     * @param _proposalId The ID of the proposal to execute.
     */
    function executeProposal(uint256 _proposalId) external {
        GovernanceProposal storage proposal = proposals[_proposalId];
        if (proposal.id == 0) revert ProposalNotFound(_proposalId);
        if (block.timestamp < proposal.votingEndTime) {
            revert ProposalVotingPeriodActive(_proposalId); // Voting period not ended
        }
        if (proposal.executed) {
            revert ProposalAlreadyExecuted(_proposalId);
        }

        uint256 totalReputationSnapshot = _getTotalActiveReputation(); // Get current total reputation
        uint256 totalVotesInProposal = proposal.yayVotes + proposal.nayVotes;
        uint224 requiredQuorum = (totalReputationSnapshot * params.governanceQuorumFraction) / 10000;
        uint224 requiredThreshold = proposal.requiresSuperMajority ? params.superMajorityThreshold : 5001; // 50.01% for simple majority

        bool passed = false;
        if (totalVotesInProposal >= requiredQuorum) {
            if (proposal.yayVotes * 10000 / totalVotesInProposal >= requiredThreshold) {
                passed = true;
            }
        }

        proposal.executed = true; // Mark as executed regardless of pass/fail to prevent re-execution

        if (passed) {
            // If a target address and calldata are provided, attempt to execute the call
            if (proposal.targetAddress != address(0) && proposal.callData.length > 0) {
                // Ensure the call is to this contract or another trusted contract
                if (proposal.targetAddress == address(this) && msg.sender == address(this)) {
                     // Prevent reentrancy if target is self and not external call
                     revert SelfInteractionForbidden();
                }

                (bool success, ) = proposal.targetAddress.call(proposal.callData);
                emit GovernanceProposalExecuted(_proposalId, success);
                if (!success) {
                    // Log failure, but don't revert the proposal if it's already "passed" governance.
                    // The DAO might then need to submit a new proposal to address the failed execution.
                }
            } else {
                // For dispute resolutions or purely descriptive proposals without direct on-chain execution,
                // the passing merely signals a governance decision.
                emit GovernanceProposalExecuted(_proposalId, true);
            }
        } else {
            emit GovernanceProposalExecuted(_proposalId, false);
        }

        // Proposer's stake is not directly returned here but added to `rewardPoolBalance`.
        // The proposer can claim it back via `claimCapsuleRewards` if pendingRewards tracking includes stakes.
    }

    // --- VI. Module: AI Oracle Integration & Dispute Resolution ---
    // (Functions 9 and 11 are part of this module as well)

    /**
     * @dev 18. Governance function to update the trusted AI oracle's address.
     *      This function should ideally only be callable via a successful governance proposal
     *      (i.e., by `executeProposal` calling this contract with the appropriate calldata).
     *      It is `onlyOwner` for initial setup/admin, but a robust DAO would remove `onlyOwner` and rely on `executeProposal`.
     * @param _newAIOracleAddress The new address for the AI oracle.
     */
    function updateAIOracleAddress(address _newAIOracleAddress) public onlyOwner { // Marked public only for direct testing/initial setup, should be onlyCallableByGovernance
        if (_newAIOracleAddress == address(0)) revert InvalidParameterValue("AI Oracle address cannot be zero");
        address oldAddress = aiOracleAddress;
        aiOracleAddress = _newAIOracleAddress;
        emit AIOracleAddressUpdated(_newAIOracleAddress);
    }

    // --- VII. Module: Utility & Access Control ---

    /**
     * @dev 19. Allows anyone to deposit funds into the shared reward pool.
     * @param _amount The amount of ETH to deposit.
     */
    function depositToRewardPool(uint256 _amount) external payable {
        if (msg.value != _amount) revert InvalidParameterValue("Deposited amount does not match value");
        rewardPoolBalance += _amount;
        emit FundsDeposited(msg.sender, _amount);
    }

    /**
     * @dev 20. Allows governance (or owner for simplicity here) to withdraw funds from the reward pool.
     *      Should ideally be triggered by a governance proposal for transparency.
     * @param _amount The amount of ETH to withdraw.
     * @param _recipient The address to send the funds to.
     */
    function withdrawFromRewardPool(uint256 _amount, address _recipient) external onlyOwner { // Placeholder for governance control
        if (_recipient == address(0)) revert InvalidParameterValue("Recipient address cannot be zero");
        if (_amount == 0) revert InvalidParameterValue("Withdrawal amount cannot be zero");
        if (rewardPoolBalance < _amount) revert NotEnoughFundsInRewardPool(_amount);

        rewardPoolBalance -= _amount;
        (bool success,) = payable(_recipient).call{value: _amount}("");
        if (!success) {
            // Revert transfer if failed, add funds back to pool
            rewardPoolBalance += _amount;
            revert("ETH transfer failed during withdrawal");
        }
        emit FundsWithdrawn(_recipient, _amount);
    }

    /**
     * @dev 21. Retrieves the total amount currently staked for a specific entity (evaluation round or proposal).
     *      Note: This is a simplification; as currently implemented, all stakes go directly into `rewardPoolBalance`.
     *      A more granular system would use a dedicated mapping for `entityId => stakedAmount`.
     *      For this contract, it returns 0 as stakes are merged.
     * @param _entityId The ID of the evaluation round or proposal.
     * @return The total ETH staked for that entity.
     */
    function getStakedAmount(uint256 _entityId) external pure returns (uint256) {
        // As currently implemented, stakes are merged into rewardPoolBalance.
        // A dedicated mapping like `mapping(uint256 => uint256) entityStakes;` would be needed to track this.
        return 0; // Placeholder, as current implementation merges stakes into rewardPoolBalance
    }

    /**
     * @dev 22. Allows governance (or owner for simplicity) to modify various core parameters.
     *      This function should ideally only be callable via a successful governance proposal
     *      (i.e., by `executeProposal` calling this contract with the appropriate calldata).
     *      It is `onlyOwner` for initial setup/admin.
     * @param _parameterName The name of the parameter to update.
     * @param _newValue The new value for the parameter.
     */
    function updateSystemParameter(string calldata _parameterName, uint256 _newValue) external onlyOwner { // Placeholder for governance
        if (_newValue == 0 && !(_parameterName == "evaluationStakeAmount" || _parameterName == "proposalVoteStakeAmount")) {
            revert InvalidParameterValue("Parameter cannot be zero unless it's a stake amount");
        }

        bytes32 paramHash = keccak256(abi.encodePacked(_parameterName));
        uint256 oldValue; // Temporarily store old value for event

        if (paramHash == keccak256("minRelevanceForActive")) {
            oldValue = params.minRelevanceForActive;
            params.minRelevanceForActive = _newValue;
        } else if (paramHash == keccak256("initialReputationScore")) {
            oldValue = params.initialReputationScore;
            params.initialReputationScore = _newValue;
        } else if (paramHash == keccak256("evaluationStakeAmount")) {
            oldValue = params.evaluationStakeAmount;
            params.evaluationStakeAmount = _newValue;
        } else if (paramHash == keccak256("proposalVoteStakeAmount")) {
            oldValue = params.proposalVoteStakeAmount;
            params.proposalVoteStakeAmount = _newValue;
        } else if (paramHash == keccak256("evaluationPeriodSeconds")) {
            oldValue = params.evaluationPeriodSeconds;
            params.evaluationPeriodSeconds = uint32(_newValue);
        } else if (paramHash == keccak256("proposalVotingPeriodSeconds")) {
            oldValue = params.proposalVotingPeriodSeconds;
            params.proposalVotingPeriodSeconds = uint32(_newValue);
        } else if (paramHash == keccak256("minReputationForProposing")) {
            oldValue = params.minReputationForProposing;
            params.minReputationForProposing = _newValue;
        } else if (paramHash == keccak256("minReputationForVoting")) {
            oldValue = params.minReputationForVoting;
            params.minReputationForVoting = _newValue;
        } else if (paramHash == keccak256("governanceQuorumFraction")) {
            if (_newValue > 10000) revert InvalidParameterValue("Quorum fraction cannot exceed 100%");
            oldValue = params.governanceQuorumFraction;
            params.governanceQuorumFraction = _newValue;
        } else if (paramHash == keccak256("superMajorityThreshold")) {
            if (_newValue > 10000) revert InvalidParameterValue("Supermajority threshold cannot exceed 100%");
            oldValue = params.superMajorityThreshold;
            params.superMajorityThreshold = _newValue;
        } else if (paramHash == keccak256("maxEvolutionHistoryLength")) {
            oldValue = params.maxEvolutionHistoryLength;
            params.maxEvolutionHistoryLength = _newValue;
        } else if (paramHash == keccak256("aiScoreWeight")) {
            if (_newValue > 10000) revert InvalidParameterValue("AI score weight cannot exceed 100%");
            oldValue = params.aiScoreWeight;
            params.aiScoreWeight = _newValue;
        } else if (paramHash == keccak256("reputationBoostForAccuracy")) {
            oldValue = params.reputationBoostForAccuracy;
            params.reputationBoostForAccuracy = _newValue;
        } else if (paramHash == keccak256("reputationPenaltyForInaccuracy")) {
            oldValue = params.reputationPenaltyForInaccuracy;
            params.reputationPenaltyForInaccuracy = _newValue;
        }
        else {
            revert InvalidParameterValue("Unknown parameter name");
        }
        emit SystemParameterUpdated(_parameterName, oldValue, _newValue);
    }

    /**
     * @dev 23. Retrieves the historical relevance scores and evaluation events for a capsule.
     * @param _capsuleId The ID of the capsule.
     * @return An array of RelevanceSnapshot structs.
     */
    function getEvolutionHistory(uint256 _capsuleId) external view returns (RelevanceSnapshot[] memory) {
        if (capsules[_capsuleId].id == 0) revert CapsuleNotFound(_capsuleId);
        return capsules[_capsuleId].evolutionHistory;
    }

    // --- Internal Helpers ---

    /**
     * @dev Helper to get the total active reputation in the system.
     *      This is a simplistic estimate for quorum calculation. A more robust DAO with a dedicated
     *      governance token or reputation token would track total supply/staked amounts more precisely,
     *      potentially using a snapshot mechanism. This iterates through known contributors.
     */
    function _getTotalActiveReputation() internal view returns (uint256) {
        uint256 totalRep = 0;
        // Iterate through all possible capsule owners and count their reputation
        // (This is an approximation and can be gas-intensive for many capsules/contributors).
        for (uint256 i = 1; i < nextCapsuleId; i++) {
            address owner = capsules[i].owner;
            if (owner != address(0)) { // Check if the address is valid
                totalRep += contributors[owner].reputationScore;
            }
        }
        // Add the deployer's reputation (if not already counted as a capsule owner)
        totalRep += contributors[owner()].reputationScore;

        return totalRep;
    }
}

// Utility library for converting uint256 to string (part of OpenZeppelin Contracts)
// This is necessary for dynamically creating string descriptions for governance proposals.
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by Oraclize API's uint256 to ASCII https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ce64546af2b46ad69fd1378943/oraclizeAPI_0.4.25.sol
        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }
}
```