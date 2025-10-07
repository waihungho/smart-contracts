```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title Self-Evolving Adaptive Reputation Ecosystem (SEARE)
 * @author YourName (concept by AI)
 * @notice This contract implements a novel decentralized reputation system designed for contribution-based platforms.
 *         It features a decaying reputation score, a multi-stage validation process for tasks,
 *         a robust challenge system for disputes, and a dynamic weighting mechanism for reputation-affecting events.
 *         The "adaptive" nature comes from the ability for high-reputation users (via proposals)
 *         or the owner (initially) to adjust the reputation impact (weights) of different actions
 *         based on the system's evolving needs, mimicking an on-chain "self-evolution."
 *         It aims to incentivize high-quality contributions and accurate validation through a robust
 *         and responsive reputation economy, providing a framework for on-chain verifiable work.
 */

// --- OUTLINE OF THE SEARE CONTRACT ---
// 1.  Enums & Structs:
//     -   ReputationEventType: Defines types of actions impacting reputation (e.g., ContributionSuccess).
//     -   ReputationTier: Defines different privilege levels based on reputation (e.g., Validator, Governor).
//     -   TaskStatus, ChallengeStatus, ProposalStatus: Lifecycle states for entities.
//     -   User: Stores user-specific data (reputation, last update, profile hash, etc.).
//     -   Task: Defines a contribution task (reward, deadline, status, contributor, validation details).
//     -   ValidationProposal: Records a proposed validation verdict for a task by a validator.
//     -   Challenge: Stores details of a dispute over a task's validation (challenger, evidence, voting).
//     -   WeightAdjustmentProposal: For dynamic adjustments of reputation event weights through governance.
//
// 2.  State Variables:
//     -   Ownership and administrative controls (`Ownable`).
//     -   Mappings for `users`, `tasks`, `challenges`, `weightAdjustmentProposals`.
//     -   Counters for unique IDs (`nextTaskId`, `nextChallengeId`, `nextProposalId`).
//     -   `reputationDecayRatePerSecond`: Global rate at which reputation decays.
//     -   `reputationTierThresholds`: Array defining score boundaries for each privilege tier.
//     -   `reputationEventWeights`: Mapping defining the reputation impact for each `ReputationEventType`.
//     -   `taskEndorsementThreshold`: Minimum collective reputation required to finalize a task validation.
//     -   `challengeVotingPeriod`, `proposalVotingPeriod`: Durations for voting phases.
//     -   `proposalQuorumThreshold`, `proposalPassThreshold`: Governance parameters for proposals.
//     -   `totalPlatformBalance`: Total ETH held by the contract for task rewards.
//
// 3.  Events:
//     -   To signal important state changes on-chain for off-chain monitoring and indexing.
//
// 4.  Modifiers:
//     -   `onlyOwner`: Restricts function access to the contract owner.
//     -   `onlyRegisteredUser`: Ensures the caller is part of the SEARE ecosystem.
//     -   `onlyTierNOrHigher`: Enforces minimum reputation tier for specific actions.
//
// 5.  Internal Helper Functions:
//     -   `_calculateCurrentReputation`: Applies decay logic to a user's raw reputation to get their real-time score.
//     -   `_adjustReputation`: Core logic for modifying a user's raw reputation score based on `ReputationEventType` weights.
//     -   `_getReputationTier`: Determines a user's current privilege tier based on their effective reputation.
//
// 6.  Core Functionality (Grouped by category, with detailed summary below):
//     a.  User Registration & Profile (2 functions)
//     b.  Task Creation & Contribution (2 functions)
//     c.  Multi-Stage Validation & Endorsement (3 functions)
//     d.  Challenge & Dispute Resolution (4 functions)
//     e.  Reputation Management (Decay, Tiers, Dynamic Weights) (3 functions)
//     f.  System Parameter Proposals & Governance (3 functions)
//     g.  Funds Management (2 functions)
//     h.  View Functions (7 functions)

// --- FUNCTION SUMMARY (26 functions total, exceeding the minimum of 20) ---

// a. User Registration & Profile (2 functions)
// 1.  `registerUser()`: Allows a new user to join the ecosystem, receiving an initial reputation score determined by `ReputationEventType.Registration` weight.
// 2.  `updateProfile(bytes32 _metadataHash)`: Allows a registered user to update their off-chain profile metadata (e.g., an IPFS hash pointing to their identity).

// b. Task Creation & Contribution (2 functions)
// 3.  `createTask(bytes32 _metadataHash, uint256 _rewardAmount, uint256 _deadline, uint256 _validatorRepTierRequired)`:
//     Allows users in the `Contributor` tier or higher to create a new task, specifying a reward, deadline, and the minimum reputation tier required for validators.
// 4.  `contributeToTask(uint256 _taskId, bytes32 _contributionHash)`:
//     Allows a registered user to submit their work/contribution for an open task, attaching an off-chain data hash.

// c. Multi-Stage Validation & Endorsement (3 functions)
// 5.  `proposeValidation(uint256 _taskId, bool _isValid)`:
//     A user in the `Validator` tier or higher proposes a verdict (valid/invalid) for a submitted task contribution. Their reputation contributes to the proposal's endorsement power.
// 6.  `endorseValidationProposal(uint256 _taskId, address _proposer, bool _support)`:
//     Other users in the `Validator` tier or higher can endorse or reject a specific validation proposal, adding or subtracting their reputation power to its total endorsement.
// 7.  `finalizeTaskValidation(uint256 _taskId)`:
//     Once a validation proposal (usually the one with the highest endorsement power) receives enough collective endorsements, this function finalizes the task's status, adjusts reputations, and makes rewards claimable.

// d. Challenge & Dispute Resolution (4 functions)
// 8.  `challengeValidationDecision(uint256 _taskId, bytes32 _reasonHash)`:
//     Allows any registered user to challenge a `finalized` validation decision, initiating a multi-stage dispute process with an off-chain reason hash.
// 9.  `submitChallengeEvidence(uint256 _challengeId, bytes32 _evidenceHash)`:
//     Participants in a challenge (challenger, challenged party) can submit off-chain evidence hashes to support their claims.
// 10. `voteOnChallengeVerdict(uint256 _challengeId, bool _supportChallenger)`:
//     Users in the `Adjudicator` tier or higher vote on the outcome of an ongoing challenge, influencing whether the challenger wins or loses.
// 11. `resolveChallengeVerdict(uint256 _challengeId)`:
//     Finalizes a challenge after the voting deadline, based on the votes. This function adjusts reputations for all involved parties (challenger, challenged, and potentially voters) according to the outcome.

// e. Reputation Management (Decay, Tiers, Dynamic Weights) (3 functions)
// 12. `updateReputationDecayRate(uint256 _newRatePerSecond)`:
//     The contract owner (or later, a DAO) can adjust the global rate at which reputation naturally decays over time.
// 13. `setReputationTierThresholds(uint256[] memory _newThresholds)`:
//     The contract owner (or later, a DAO) defines the reputation scores required to reach different privilege tiers (e.g., Contributor, Validator, Adjudicator, Governor).
// 14. `adjustReputationEventWeight(ReputationEventType _eventType, uint256 _newWeight)`:
//     The contract owner (or later, a DAO via proposals) can directly adjust the reputation impact (weight) of specific event types. This is the core "adaptive" mechanism, allowing the system to dynamically tune incentives.

// f. System Parameter Proposals & Governance (3 functions)
// 15. `proposeDynamicWeightAdjustment(ReputationEventType _eventType, uint256 _newWeight, bytes32 _descriptionHash)`:
//     Users in a designated `Governor` tier can propose changes to the `reputationEventWeights`, decentralizing the adaptive mechanism.
// 16. `voteOnWeightAdjustmentProposal(uint256 _proposalId, bool _support)`:
//     Users in the `Governor` tier vote on active weight adjustment proposals. Their vote weight is their current reputation.
// 17. `executeWeightAdjustmentProposal(uint256 _proposalId)`:
//     Executes a weight adjustment proposal once it passes the voting threshold (quorum and pass percentage), applying the new weight to the system.

// g. Funds Management (2 functions)
// 18. `depositFundsForTasks() payable`:
//     Allows anyone to deposit ETH into the contract, which is used to fund task rewards.
// 19. `withdrawPlatformFunds(address _to, uint256 _amount)`:
//     The contract owner (or later, a DAO) can withdraw funds from the contract to a specified address.

// h. View Functions (7 functions)
// 20. `getReputationScore(address _user) view`: Returns the current effective (decayed) reputation score of a user.
// 21. `getReputationTier(address _user) view`: Returns the current privilege tier (e.g., Contributor, Validator) of a user.
// 22. `getTaskDetails(uint256 _taskId) view`: Returns comprehensive details of a specific task.
// 23. `getChallengeDetails(uint256 _challengeId) view`: Returns detailed information about a specific challenge.
// 24. `getReputationEventWeight(ReputationEventType _eventType) view`: Returns the current dynamic reputation impact weight for a given event type.
// 25. `getWeightAdjustmentProposal(uint256 _proposalId) view`: Returns details of a specific weight adjustment proposal.
// 26. `getUserProfileMetadataHash(address _user) view`: Returns the IPFS hash associated with a user's off-chain profile.
// 27. `getTotalRegisteredUsers() view`: Returns the total count of users registered in the system.
// 28. `getPlatformBalance() view`: Returns the total ETH balance currently held by the contract.
// 29. `getTaskEndorsementThreshold() view`: Returns the current endorsement power required to finalize a task validation.

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol"; // SafeMath is less critical in 0.8+ but used for clarity/habit

contract SEARE is Ownable {
    using SafeMath for uint256; // For safe arithmetic operations

    // --- ENUMS ---

    // Defines types of actions that can affect a user's reputation score.
    // Each event type has a configurable weight, making the system adaptive.
    enum ReputationEventType {
        Registration,               // Initial reputation upon joining
        ContributionSuccess,        // Successful task contribution
        ContributionFailure,        // Failed task contribution (e.g., rejected by consensus)
        ValidationProposalSuccess,  // Validator proposes correct verdict
        ValidationProposalFailure,  // Validator proposes incorrect verdict
        ValidationEndorsement,      // Endorsing a correct validation
        ChallengeInitiation,        // Initiating a challenge (positive/negative depending on outcome)
        ChallengeSuccess,           // Challenger wins the dispute
        ChallengeFailure,           // Challenger loses the dispute
        AdjudicationVoteCorrect,    // Adjudicator votes correctly on challenge
        AdjudicationVoteIncorrect,  // Adjudicator votes incorrectly on challenge
        ProposalCreation,           // Creating a governance proposal
        ProposalVoteSuccess,        // Voting on a proposal that passes
        ProposalVoteFailure         // Voting on a proposal that fails
    }

    // Defines privilege tiers based on reputation scores, granting different access levels.
    enum ReputationTier {
        Unregistered,
        Registered,     // Base level, can perform basic actions
        Contributor,    // Can create tasks, contribute
        Validator,      // Can propose/endorse task validations
        Adjudicator,    // Can vote on challenge outcomes
        Governor        // Can propose/vote on system parameter changes (e.g., event weights)
    }

    // Defines the lifecycle status of a task.
    enum TaskStatus {
        Open,                   // Task is available for contributions
        ContributionSubmitted,  // A contribution has been submitted
        ValidationProposed,     // A validation verdict has been proposed
        ValidationFinalized,    // The validation verdict has been finalized
        Challenged,             // The finalized validation is under dispute
        Resolved,               // The task is fully resolved (after validation or challenge)
        Cancelled               // The task was cancelled (e.g., by creator or system)
    }

    // Defines the lifecycle status of a challenge.
    enum ChallengeStatus {
        PendingEvidence, // Challenge just started, waiting for evidence
        Voting,          // Evidence submitted, now voting on the verdict
        Resolved         // Challenge has been decided
    }

    // Defines the lifecycle status of a governance proposal.
    enum ProposalStatus {
        Active,   // Proposal is open for voting
        Passed,   // Proposal passed the voting threshold
        Failed,   // Proposal failed to pass
        Executed  // Proposal passed and its effects have been applied
    }

    // --- STRUCTS ---

    // Stores detailed information for each registered user.
    struct User {
        bool isRegistered;                  // True if the address is a registered user
        uint256 rawReputation;              // Base reputation score, before decay is applied
        uint256 lastReputationUpdate;       // Timestamp of the last reputation change/update
        bytes32 profileMetadataHash;        // IPFS hash for off-chain profile data (e.g., public key, description)
        uint256 contributionCount;          // Number of successful contributions
        uint256 validationCount;            // Number of successful validations
        uint256 challengeCount;             // Number of challenges participated in (won/lost)
    }

    // Stores details about a specific task/work item.
    struct Task {
        uint256 id;                         // Unique ID for the task
        address creator;                    // Address of the user who created the task
        bytes32 metadataHash;               // IPFS hash for task description and requirements
        uint224 rewardAmount;               // Reward in wei for successful completion (uint224 for gas efficiency)
        uint64 deadline;                    // Timestamp by which the task must be completed and validated (uint64 for gas efficiency)
        uint256 validatorRepTierRequired;   // Minimum reputation tier required for validators of this task
        TaskStatus status;                  // Current status of the task
        address contributor;                // Address of the user who submitted a contribution
        bytes32 contributionHash;           // IPFS hash for the submitted contribution data
        address validationProposer;         // Address of the validator whose proposal was finalized
        bool validationVerdict;             // The final verdict: true for valid, false for invalid
        uint256 challengeId;                // ID of the active challenge if the task's validation is disputed
    }

    // Represents a proposed validation verdict for a task by a validator.
    struct ValidationProposal {
        address proposer;                   // Address of the user who proposed this validation
        bool verdict;                       // Proposed verdict: true for valid, false for invalid
        uint256 totalEndorsementPower;      // Sum of reputation scores of all endorsers (including proposer)
        mapping(address => bool) hasEndorsed; // Tracks which users have endorsed this specific proposal
    }

    // Stores details of a dispute initiated against a task's validation.
    struct Challenge {
        uint256 id;                         // Unique ID for the challenge
        uint256 taskId;                     // ID of the task being challenged
        address challenger;                 // Address of the user who initiated the challenge
        bytes32 reasonHash;                 // IPFS hash for the challenger's detailed reason
        address challengedParty;            // Address of the party whose action is being challenged (usually the final validator)
        bytes32 challengerEvidenceHash;     // IPFS hash for challenger's evidence
        bytes32 challengedPartyEvidenceHash; // IPFS hash for challenged party's evidence
        ChallengeStatus status;             // Current status of the challenge
        uint64 votingDeadline;              // Timestamp when voting on the challenge ends
        uint256 votesForChallenger;         // Total reputation-weighted votes supporting the challenger
        uint256 votesAgainstChallenger;     // Total reputation-weighted votes against the challenger
        mapping(address => bool) hasVoted;  // Tracks which users have voted on this challenge
    }

    // Stores details of a governance proposal to adjust reputation event weights.
    struct WeightAdjustmentProposal {
        uint256 id;                         // Unique ID for the proposal
        address proposer;                   // Address of the user who created the proposal
        ReputationEventType eventType;      // The reputation event type to be adjusted
        uint256 newWeight;                  // The proposed new weight for the event type
        bytes32 descriptionHash;            // IPFS hash for the detailed proposal description
        uint64 creationTime;                // Timestamp when the proposal was created
        uint64 votingDeadline;              // Timestamp when voting on the proposal ends
        uint256 votesFor;                   // Total reputation-weighted votes in favor
        uint256 votesAgainst;               // Total reputation-weighted votes against
        ProposalStatus status;              // Current status of the proposal
        mapping(address => bool) hasVoted;  // Tracks which users have voted on this proposal
    }

    // --- STATE VARIABLES ---

    // User management
    mapping(address => User) public users;
    address[] public registeredUsers;       // List of all registered user addresses (for iteration, might be gas-intensive if large)
    uint256 public totalRegisteredUsers;    // Counter for total registered users

    // Task management
    mapping(uint256 => Task) public tasks;
    uint256 public nextTaskId;              // Counter for generating unique task IDs

    // Validation proposals (per task)
    // taskId => proposerAddress => ValidationProposal
    mapping(uint256 => mapping(address => ValidationProposal)) public validationProposals;
    uint256 public taskEndorsementThreshold; // Minimum total endorsement power needed to finalize a task validation

    // Challenge management
    mapping(uint256 => Challenge) public challenges;
    uint256 public nextChallengeId;         // Counter for generating unique challenge IDs
    uint64 public challengeVotingPeriod;    // Duration for challenge voting (in seconds)

    // Weight adjustment proposals (governance)
    mapping(uint256 => WeightAdjustmentProposal) public weightAdjustmentProposals;
    uint256 public nextProposalId;          // Counter for generating unique proposal IDs
    uint64 public proposalVotingPeriod;     // Duration for proposal voting (in seconds)
    uint256 public proposalQuorumThreshold; // Minimum total voting power required for a proposal to be considered valid
    uint256 public proposalPassThreshold;   // Percentage (multiplied by 100) of votes_for / total_votes for a proposal to pass (e.g., 5100 for 51%)

    // System parameters, adjustable by owner/governance
    uint256 public reputationDecayRatePerSecond; // Rate at which reputation decays per second (e.g., 1 for 1 point/sec)
    // Array of reputation scores that define the thresholds for each tier:
    // [Registered, Contributor, Validator, Adjudicator, Governor]
    uint256[] public reputationTierThresholds;
    // Maps each ReputationEventType to its corresponding impact on a user's reputation.
    mapping(ReputationEventType => uint256) public reputationEventWeights;

    // Funds management
    uint256 public totalPlatformBalance;    // Tracks total ETH held by the contract for rewards

    // --- EVENTS ---
    // Events are emitted to provide an auditable log of contract activities.

    event UserRegistered(address indexed userAddress, uint256 initialReputation);
    event ProfileUpdated(address indexed userAddress, bytes32 metadataHash);
    event TaskCreated(uint256 indexed taskId, address indexed creator, uint256 rewardAmount, uint256 deadline);
    event ContributionSubmitted(uint256 indexed taskId, address indexed contributor, bytes32 contributionHash);
    event ValidationProposed(uint256 indexed taskId, address indexed proposer, bool verdict, uint256 endorsementPower);
    event ValidationEndorsed(uint256 indexed taskId, address indexed endorser, address indexed proposer, bool support);
    event TaskValidationFinalized(uint256 indexed taskId, address indexed validator, bool verdict);
    event ChallengeInitiated(uint256 indexed challengeId, uint256 indexed taskId, address indexed challenger);
    event ChallengeEvidenceSubmitted(uint256 indexed challengeId, address indexed party, bytes32 evidenceHash);
    event ChallengeVoteCast(uint256 indexed challengeId, address indexed voter, bool supportChallenger);
    event ChallengeResolved(uint256 indexed challengeId, uint256 indexed taskId, bool challengerWon);
    event ReputationDecayRateUpdated(uint256 newRate);
    event ReputationTierThresholdsUpdated(uint256[] newThresholds);
    event ReputationEventWeightAdjusted(ReputationEventType indexed eventType, uint256 newWeight);
    event WeightAdjustmentProposalCreated(uint256 indexed proposalId, address indexed proposer, ReputationEventType eventType, uint256 newWeight);
    event WeightAdjustmentProposalVoted(uint256 indexed proposalId, address indexed voter, bool support);
    event WeightAdjustmentProposalExecuted(uint256 indexed proposalId, bool passed);
    event FundsDeposited(address indexed depositor, uint256 amount);
    event FundsWithdrawn(address indexed to, uint256 amount);
    event TaskRewardClaimed(uint256 indexed taskId, address indexed beneficiary, uint256 amount);
    event ReputationAdjusted(address indexed user, ReputationEventType indexed eventType, int255 adjustment, uint256 newRawReputation);


    // --- MODIFIERS ---
    // Modifiers enforce access control and preconditions for function execution.

    modifier onlyRegisteredUser() {
        require(users[_msgSender()].isRegistered, "SEARE: Caller not a registered user");
        _;
    }

    modifier onlyTierNOrHigher(ReputationTier _requiredTier) {
        require(users[_msgSender()].isRegistered, "SEARE: Caller not a registered user");
        require(_getReputationTier(_msgSender()) >= _requiredTier, "SEARE: Insufficient reputation tier");
        _;
    }

    // --- CONSTRUCTOR ---

    constructor() Ownable(msg.sender) {
        // Initialize core system parameters upon deployment.
        reputationDecayRatePerSecond = 1; // Default: 1 reputation point decays per second

        // Initial reputation tier thresholds (example values, can be adjusted):
        // [Registered, Contributor, Validator, Adjudicator, Governor]
        reputationTierThresholds = [0, 100, 500, 2000, 5000];

        // Initial weights for various reputation-affecting events (example values, highly adaptive):
        reputationEventWeights[ReputationEventType.Registration] = 100;
        reputationEventWeights[ReputationEventType.ContributionSuccess] = 50;
        reputationEventWeights[ReputationEventType.ContributionFailure] = 0; // No penalty for trying, but no reward
        reputationEventWeights[ReputationEventType.ValidationProposalSuccess] = 30;
        reputationEventWeights[ReputationEventType.ValidationProposalFailure] = 20; // Penalty expressed as positive weight for negative adjustment
        reputationEventWeights[ReputationEventType.ValidationEndorsement] = 10;
        reputationEventWeights[ReputationEventType.ChallengeInitiation] = 10; // Penalty for initiating a losing challenge
        reputationEventWeights[ReputationEventType.ChallengeSuccess] = 80;
        reputationEventWeights[ReputationEventType.ChallengeFailure] = 50;
        reputationEventWeights[ReputationEventType.AdjudicationVoteCorrect] = 20;
        reputationEventWeights[ReputationEventType.AdjudicationVoteIncorrect] = 15;
        reputationEventWeights[ReputationEventType.ProposalCreation] = 5;
        reputationEventWeights[ReputationEventType.ProposalVoteSuccess] = 1;
        reputationEventWeights[ReputationEventType.ProposalVoteFailure] = 0;

        taskEndorsementThreshold = 100; // Default collective reputation power needed to finalize a task validation
        challengeVotingPeriod = 3 days; // Challenges typically have a few days for voting
        proposalVotingPeriod = 7 days;  // Governance proposals have a longer voting period
        proposalQuorumThreshold = 1000; // Minimum total reputation voting power needed for a proposal to be considered
        proposalPassThreshold = 5100;   // 51% (represented as 5100 for precision, out of 10000) of votes_for / total_votes to pass
    }

    // --- INTERNAL HELPER FUNCTIONS ---
    // These functions encapsulate core logic used by multiple external functions.

    /**
     * @dev Calculates the current effective reputation score for a user, applying the configured decay.
     *      This ensures that reputation is always up-to-date when accessed.
     * @param _user The address of the user.
     * @return The effective (decayed) reputation score of the user.
     */
    function _calculateCurrentReputation(address _user) internal view returns (uint256) {
        User storage user = users[_user];
        if (!user.isRegistered) {
            return 0; // Unregistered users have no reputation
        }

        uint256 timeElapsed = block.timestamp.sub(user.lastReputationUpdate);
        uint256 decayAmount = timeElapsed.mul(reputationDecayRatePerSecond);

        // Ensure reputation doesn't go below zero due to decay
        if (decayAmount >= user.rawReputation) {
            return 0;
        }
        return user.rawReputation.sub(decayAmount);
    }

    /**
     * @dev Adjusts a user's raw reputation score and updates their last update timestamp.
     *      This is the central function for all reputation changes.
     * @param _user The address of the user whose reputation is being adjusted.
     * @param _eventType The type of event causing the adjustment (e.g., ContributionSuccess).
     * @param _isPositive A boolean indicating if the reputation impact should be positive (gain) or negative (loss).
     *                    The actual weight is fetched from `reputationEventWeights`.
     */
    function _adjustReputation(address _user, ReputationEventType _eventType, bool _isPositive) internal {
        User storage user = users[_user];
        if (!user.isRegistered) return; // Cannot adjust reputation for unregistered users

        uint256 weight = reputationEventWeights[_eventType];
        int255 adjustment; // Use int255 to allow negative adjustments

        if (_isPositive) {
            adjustment = int255(weight);
        } else {
            adjustment = -int255(weight); // Apply penalty by subtracting the weight
        }

        // Apply decay to the raw reputation before making the new adjustment.
        // This ensures reputation is always effectively up-to-date before any new changes.
        user.rawReputation = _calculateCurrentReputation(_user);

        // Perform the adjustment safely, preventing underflow/overflow.
        if (adjustment > 0) {
            user.rawReputation = user.rawReputation.add(uint256(adjustment));
        } else if (adjustment < 0) {
            user.rawReputation = user.rawReputation.sub(uint256(-adjustment));
        }
        
        user.lastReputationUpdate = block.timestamp; // Update timestamp after adjustment

        emit ReputationAdjusted(_user, _eventType, adjustment, user.rawReputation);
    }

    /**
     * @dev Determines the current privilege tier of a user based on their effective reputation.
     *      This function is used for enforcing reputation-based access control.
     * @param _user The address of the user.
     * @return The `ReputationTier` of the user.
     */
    function _getReputationTier(address _user) internal view returns (ReputationTier) {
        if (!users[_user].isRegistered) {
            return ReputationTier.Unregistered;
        }
        uint256 effectiveRep = _calculateCurrentReputation(_user);

        // Check against thresholds in descending order to assign the highest applicable tier
        if (effectiveRep >= reputationTierThresholds[4]) return ReputationTier.Governor;
        if (effectiveRep >= reputationTierThresholds[3]) return ReputationTier.Adjudicator;
        if (effectiveRep >= reputationTierThresholds[2]) return ReputationTier.Validator;
        if (effectiveRep >= reputationTierThresholds[1]) return ReputationTier.Contributor;
        // All registered users start at or above the 'Registered' threshold (which is 0)
        return ReputationTier.Registered;
    }


    // --- CORE FUNCTIONALITY ---

    // a. User Registration & Profile

    /**
     * @dev 1. Allows a new user to join the ecosystem, receiving an initial reputation score.
     *      Requires the caller not to be already registered.
     */
    function registerUser() external {
        require(!users[_msgSender()].isRegistered, "SEARE: Caller is already a registered user");

        users[_msgSender()].isRegistered = true;
        // Initial reputation is determined by the `Registration` event weight
        users[_msgSender()].rawReputation = reputationEventWeights[ReputationEventType.Registration];
        users[_msgSender()].lastReputationUpdate = block.timestamp;
        
        registeredUsers.push(_msgSender()); // Add to the array of registered users
        totalRegisteredUsers = totalRegisteredUsers.add(1);

        emit UserRegistered(_msgSender(), users[_msgSender()].rawReputation);
    }

    /**
     * @dev 2. Allows a registered user to update their off-chain profile link/metadata.
     *      This hash can point to an IPFS document or similar for more detailed user info.
     * @param _metadataHash An IPFS hash (or similar) pointing to the user's profile data.
     */
    function updateProfile(bytes32 _metadataHash) external onlyRegisteredUser {
        users[_msgSender()].profileMetadataHash = _metadataHash;
        emit ProfileUpdated(_msgSender(), _metadataHash);
    }

    // b. Task Creation & Contribution

    /**
     * @dev 3. Allows a registered user (specifically, a `Contributor` tier or higher) to create a new task.
     *      Requires specified `rewardAmount` and a future `deadline`.
     *      Funds for the reward are *not* automatically transferred here; they are expected to be deposited
     *      to the contract via `depositFundsForTasks` before rewards can be claimed.
     * @param _metadataHash IPFS hash for task description (e.g., requirements, scope).
     * @param _rewardAmount The amount of wei to be rewarded upon successful task completion.
     * @param _deadline Timestamp by which the task must be completed and validated.
     * @param _validatorRepTierRequired Minimum reputation tier needed for users to propose/endorse validation for this task.
     */
    function createTask(
        bytes32 _metadataHash,
        uint256 _rewardAmount,
        uint64 _deadline, // Use uint64 to match struct type and save gas
        uint256 _validatorRepTierRequired
    ) external onlyTierNOrHigher(ReputationTier.Contributor) {
        require(_rewardAmount > 0, "SEARE: Task reward must be greater than zero");
        require(_deadline > block.timestamp, "SEARE: Task deadline must be in the future");
        require(_validatorRepTierRequired >= uint256(ReputationTier.Validator) && 
                _validatorRepTierRequired <= uint256(ReputationTier.Governor), 
                "SEARE: Invalid validator tier requirement (must be Validator to Governor)");

        uint256 currentTaskId = nextTaskId++;
        tasks[currentTaskId] = Task({
            id: currentTaskId,
            creator: _msgSender(),
            metadataHash: _metadataHash,
            rewardAmount: uint224(_rewardAmount), // Ensure reward fits uint224
            deadline: _deadline,
            validatorRepTierRequired: _validatorRepTierRequired,
            status: TaskStatus.Open,
            contributor: address(0),            // Initially no contributor
            contributionHash: bytes32(0),       // Initially no contribution
            validationProposer: address(0),     // Initially no validation
            validationVerdict: false,
            challengeId: 0
        });

        emit TaskCreated(currentTaskId, _msgSender(), _rewardAmount, _deadline);
    }

    /**
     * @dev 4. Allows a registered user to submit their work/contribution for an open task.
     *      A task can only accept one contribution.
     * @param _taskId The ID of the task to contribute to.
     * @param _contributionHash IPFS hash for the submitted contribution data/proof.
     */
    function contributeToTask(uint256 _taskId, bytes32 _contributionHash) external onlyRegisteredUser {
        Task storage task = tasks[_taskId];
        require(task.creator != address(0), "SEARE: Task does not exist");
        require(task.status == TaskStatus.Open, "SEARE: Task is not open for contributions");
        require(block.timestamp <= task.deadline, "SEARE: Task deadline has passed");
        require(task.contributor == address(0), "SEARE: Task already has a contributor"); // One contributor per task for simplicity

        task.contributor = _msgSender();
        task.contributionHash = _contributionHash;
        task.status = TaskStatus.ContributionSubmitted;

        emit ContributionSubmitted(_taskId, _msgSender(), _contributionHash);
    }

    // c. Multi-Stage Validation & Endorsement

    /**
     * @dev 5. A user in the `Validator` tier or higher proposes a verdict (valid/invalid) for a submitted task contribution.
     *      Their own reputation acts as an initial endorsement for their proposal.
     * @param _taskId The ID of the task.
     * @param _isValid True if the contribution is valid, false otherwise.
     */
    function proposeValidation(uint256 _taskId, bool _isValid) external onlyTierNOrHigher(ReputationTier.Validator) {
        Task storage task = tasks[_taskId];
        require(task.status == TaskStatus.ContributionSubmitted || task.status == TaskStatus.ValidationProposed,
                "SEARE: Task not ready for validation proposal (must be Submitted or already Proposed)");
        require(block.timestamp <= task.deadline, "SEARE: Task deadline has passed");
        
        // Ensure proposer meets the task's specific validator tier requirement
        require(_getReputationTier(_msgSender()) >= ReputationTier(task.validatorRepTierRequired), 
                "SEARE: Insufficient tier for validating this specific task");
        
        ValidationProposal storage proposal = validationProposals[_taskId][_msgSender()];
        require(proposal.proposer == address(0), "SEARE: Validation already proposed by this user for this task");

        proposal.proposer = _msgSender();
        proposal.verdict = _isValid;
        proposal.totalEndorsementPower = _calculateCurrentReputation(_msgSender()); // Proposer's rep is initial endorsement
        proposal.hasEndorsed[_msgSender()] = true; // Proposer implicitly endorses their own proposal

        task.status = TaskStatus.ValidationProposed; // Update task status to reflect ongoing validation

        // Adjust proposer's reputation for making a proposal (initial positive adjustment).
        // Actual success/failure adjustment happens in `finalizeTaskValidation`.
        _adjustReputation(_msgSender(), ReputationEventType.ValidationProposalSuccess, true);
        users[_msgSender()].validationCount = users[_msgSender()].validationCount.add(1);

        emit ValidationProposed(_taskId, _msgSender(), _isValid, proposal.totalEndorsementPower);
    }

    /**
     * @dev 6. Other users in the `Validator` tier or higher can endorse or reject a specific validation proposal.
     *      Their reputation power is added to (or subtracted from, if rejecting) the proposal's total endorsement power.
     * @param _taskId The ID of the task.
     * @param _proposer The address of the user who made the initial validation proposal.
     * @param _support True to endorse the proposal's verdict, false to reject (disagree with) it.
     */
    function endorseValidationProposal(uint256 _taskId, address _proposer, bool _support) external onlyTierNOrHigher(ReputationTier.Validator) {
        Task storage task = tasks[_taskId];
        require(task.status == TaskStatus.ValidationProposed, "SEARE: Task not in validation proposed state");
        require(block.timestamp <= task.deadline, "SEARE: Task deadline has passed");
        require(_msgSender() != _proposer, "SEARE: Cannot endorse your own validation proposal"); // Prevent self-endorsement

        ValidationProposal storage proposal = validationProposals[_taskId][_proposer];
        require(proposal.proposer != address(0), "SEARE: Targeted validation proposal does not exist");
        require(!proposal.hasEndorsed[_msgSender()], "SEARE: Caller has already endorsed/rejected this proposal");

        // Endorsers must also meet the task's required validator tier
        require(_getReputationTier(_msgSender()) >= ReputationTier(task.validatorRepTierRequired), 
                "SEARE: Insufficient tier to endorse this task's validation");

        uint256 endorserRep = _calculateCurrentReputation(_msgSender());
        if (_support == proposal.verdict) { // Endorsing agreement with the proposal's verdict
            proposal.totalEndorsementPower = proposal.totalEndorsementPower.add(endorserRep);
            _adjustReputation(_msgSender(), ReputationEventType.ValidationEndorsement, true);
        } else { // Endorsing disagreement (effectively rejecting) the proposal's verdict
            // Rejecting a proposal reduces its endorsement power. This discourages incorrect endorsements.
            proposal.totalEndorsementPower = proposal.totalEndorsementPower.sub(endorserRep);
            _adjustReputation(_msgSender(), ReputationEventType.ValidationEndorsement, false); // Penalty for endorsing wrong/disagreement
        }
        proposal.hasEndorsed[_msgSender()] = true;

        emit ValidationEndorsed(_taskId, _msgSender(), _proposer, _support);
    }

    /**
     * @dev 7. Once a validation proposal (the one with the highest endorsement power) receives enough collective endorsements,
     *          this function can be called by any registered user to finalize the task's status, adjust reputations,
     *          and prepare for reward claiming.
     * @param _taskId The ID of the task to finalize.
     */
    function finalizeTaskValidation(uint256 _taskId) external onlyRegisteredUser {
        Task storage task = tasks[_taskId];
        require(task.status == TaskStatus.ValidationProposed, "SEARE: Task not in validation proposed state");
        require(block.timestamp <= task.deadline, "SEARE: Task deadline has passed");
        require(task.contributor != address(0), "SEARE: Task has no contributor");

        // Find the validation proposal with the highest endorsement power.
        // NOTE: Iterating `registeredUsers` is gas-intensive for large user bases.
        // A production-grade system might require proposers to register their proposals in an array per task
        // or use an off-chain oracle to identify the leading proposal. For this advanced concept demo, it's acceptable.
        uint256 maxPower = 0;
        address strongestProposer = address(0);
        for (uint256 i = 0; i < registeredUsers.length; i++) {
            address currentUser = registeredUsers[i];
            ValidationProposal storage currentProposal = validationProposals[_taskId][currentUser];
            if (currentProposal.proposer != address(0) && currentProposal.totalEndorsementPower > maxPower) {
                maxPower = currentProposal.totalEndorsementPower;
                strongestProposer = currentUser;
            }
        }
        require(strongestProposer != address(0), "SEARE: No valid validation proposals found with endorsement");

        ValidationProposal storage finalProposal = validationProposals[_taskId][strongestProposer];
        require(finalProposal.totalEndorsementPower >= taskEndorsementThreshold, 
                "SEARE: Not enough endorsement power to finalize this validation");

        task.validationProposer = strongestProposer;
        task.validationVerdict = finalProposal.verdict;
        task.status = TaskStatus.ValidationFinalized;

        if (finalProposal.verdict) { // Contribution was deemed valid
            _adjustReputation(task.contributor, ReputationEventType.ContributionSuccess, true);
            _adjustReputation(task.validationProposer, ReputationEventType.ValidationProposalSuccess, true);
        } else { // Contribution was deemed invalid
            _adjustReputation(task.contributor, ReputationEventType.ContributionFailure, false);
            _adjustReputation(task.validationProposer, ReputationEventType.ValidationProposalSuccess, true); // Proposer was correct
        }

        emit TaskValidationFinalized(_taskId, task.validationProposer, finalProposal.verdict);
    }

    // d. Challenge & Dispute Resolution

    /**
     * @dev 8. Allows any registered user to challenge a `finalized` validation decision, initiating a dispute process.
     *      This is a key mechanism for ensuring fairness and preventing malicious validation.
     * @param _taskId The ID of the task whose validation decision is being challenged.
     * @param _reasonHash IPFS hash for the challenger's detailed reason/justification for the dispute.
     */
    function challengeValidationDecision(uint256 _taskId, bytes32 _reasonHash) external onlyRegisteredUser {
        Task storage task = tasks[_taskId];
        require(task.creator != address(0), "SEARE: Task does not exist");
        require(task.status == TaskStatus.ValidationFinalized, "SEARE: Task validation not finalized or already challenged");
        require(task.contributor != address(0), "SEARE: Task has no contributor to validate");
        require(task.validationProposer != address(0), "SEARE: Task has no validation proposer to challenge");
        require(task.challengeId == 0, "SEARE: Task is already under challenge"); // Only one challenge at a time for simplicity
        // Prevent parties directly involved from challenging their own action
        require(_msgSender() != task.contributor && _msgSender() != task.validationProposer, 
                "SEARE: Cannot challenge your own contribution or validation decision");

        uint256 currentChallengeId = nextChallengeId++;
        challenges[currentChallengeId] = Challenge({
            id: currentChallengeId,
            taskId: _taskId,
            challenger: _msgSender(),
            reasonHash: _reasonHash,
            challengedParty: task.validationProposer, // The validator who made the final verdict is challenged
            challengerEvidenceHash: bytes32(0),
            challengedPartyEvidenceHash: bytes32(0),
            status: ChallengeStatus.PendingEvidence,
            votingDeadline: uint64(block.timestamp.add(challengeVotingPeriod)),
            votesForChallenger: 0,
            votesAgainstChallenger: 0,
            hasVoted: new mapping(address => bool) // Initialize the mapping for this specific challenge
        });

        task.status = TaskStatus.Challenged;    // Update task status to reflect ongoing dispute
        task.challengeId = currentChallengeId;  // Link task to its challenge

        // Initial reputation adjustment for initiating a challenge (could be a small penalty to discourage frivolous ones)
        _adjustReputation(_msgSender(), ReputationEventType.ChallengeInitiation, false);

        emit ChallengeInitiated(currentChallengeId, _taskId, _msgSender());
    }

    /**
     * @dev 9. Participants in a challenge (the challenger and the challenged party) can submit off-chain evidence hashes.
     *      This allows external data (e.g., detailed logs, images) to be referenced during the dispute.
     * @param _challengeId The ID of the challenge.
     * @param _evidenceHash IPFS hash for the evidence data.
     */
    function submitChallengeEvidence(uint256 _challengeId, bytes32 _evidenceHash) external onlyRegisteredUser {
        Challenge storage challenge = challenges[_challengeId];
        require(challenge.challenger != address(0), "SEARE: Challenge does not exist");
        require(challenge.status == ChallengeStatus.PendingEvidence, "SEARE: Challenge not in evidence submission phase");
        require(block.timestamp < challenge.votingDeadline, "SEARE: Evidence submission deadline passed"); // Evidence must be submitted before voting ends
        require(_msgSender() == challenge.challenger || _msgSender() == challenge.challengedParty, 
                "SEARE: Only challenger or challenged party can submit evidence");

        if (_msgSender() == challenge.challenger) {
            challenge.challengerEvidenceHash = _evidenceHash;
        } else {
            challenge.challengedPartyEvidenceHash = _evidenceHash;
        }

        // If both parties have submitted evidence, the challenge can move to the voting phase.
        // A more advanced system might have explicit evidence submission periods and states.
        if (challenge.challengerEvidenceHash != bytes32(0) && challenge.challengedPartyEvidenceHash != bytes32(0)) {
            challenge.status = ChallengeStatus.Voting;
        }

        emit ChallengeEvidenceSubmitted(_challengeId, _msgSender(), _evidenceHash);
    }

    /**
     * @dev 10. Users in the `Adjudicator` tier or higher vote on the outcome of an ongoing challenge.
     *      Their vote weight is proportional to their current reputation score.
     * @param _challengeId The ID of the challenge to vote on.
     * @param _supportChallenger True if the voter believes the challenger's claim is correct, false otherwise.
     */
    function voteOnChallengeVerdict(uint256 _challengeId, bool _supportChallenger) external onlyTierNOrHigher(ReputationTier.Adjudicator) {
        Challenge storage challenge = challenges[_challengeId];
        require(challenge.challenger != address(0), "SEARE: Challenge does not exist");
        require(challenge.status == ChallengeStatus.Voting, "SEARE: Challenge not in voting phase");
        require(block.timestamp < challenge.votingDeadline, "SEARE: Challenge voting deadline has passed");
        require(!challenge.hasVoted[_msgSender()], "SEARE: Caller has already voted on this challenge");
        // Prevent challenger or challenged party from voting on their own dispute
        require(_msgSender() != challenge.challenger && _msgSender() != challenge.challengedParty, 
                "SEARE: Challenger or challenged party cannot vote on their own dispute");

        challenge.hasVoted[_msgSender()] = true;
        uint256 voterRep = _calculateCurrentReputation(_msgSender());

        // Votes are weighted by the voter's reputation.
        if (_supportChallenger) {
            challenge.votesForChallenger = challenge.votesForChallenger.add(voterRep);
            _adjustReputation(_msgSender(), ReputationEventType.AdjudicationVoteCorrect, true); // Tentative positive adjustment
        } else {
            challenge.votesAgainstChallenger = challenge.votesAgainstChallenger.add(voterRep);
            _adjustReputation(_msgSender(), ReputationEventType.AdjudicationVoteCorrect, true); // Tentative positive adjustment
        }
        // Actual correct/incorrect vote adjustment can be done during resolution based on outcome.
        // For simplicity, all votes get a 'contribution' adjustment here.

        emit ChallengeVoteCast(_challengeId, _msgSender(), _supportChallenger);
    }

    /**
     * @dev 11. Finalizes a challenge based on the accumulated votes, adjusting reputations for all parties involved.
     *      This function can be called by any registered user once the voting deadline has passed.
     * @param _challengeId The ID of the challenge to resolve.
     */
    function resolveChallengeVerdict(uint256 _challengeId) external onlyRegisteredUser {
        Challenge storage challenge = challenges[_challengeId];
        require(challenge.challenger != address(0), "SEARE: Challenge does not exist");
        require(challenge.status == ChallengeStatus.Voting, "SEARE: Challenge not in voting phase or already resolved");
        require(block.timestamp >= challenge.votingDeadline, "SEARE: Challenge voting is still active");

        Task storage task = tasks[challenge.taskId];
        address contributor = task.contributor;
        address validationProposer = task.validationProposer;

        bool challengerWon = challenge.votesForChallenger > challenge.votesAgainstChallenger;

        if (challengerWon) {
            // Challenger wins: Validator was wrong, Challenger was right.
            _adjustReputation(challenge.challenger, ReputationEventType.ChallengeSuccess, true);
            _adjustReputation(validationProposer, ReputationEventType.ValidationProposalFailure, false); // Validator gets penalty
            // If the original verdict was 'invalid' and challenger proved it was 'valid', credit contributor.
            if (!task.validationVerdict) { // If previous verdict was invalid, and challenger won, contributor was right.
                _adjustReputation(contributor, ReputationEventType.ContributionSuccess, true);
            } else { // If previous verdict was valid, but challenger proved it was invalid, contributor was wrong.
                _adjustReputation(contributor, ReputationEventType.ContributionFailure, false);
            }
            task.validationVerdict = !task.validationVerdict; // Flip the task's final verdict
        } else {
            // Challenger loses: Validator was right, Challenger was wrong.
            _adjustReputation(challenge.challenger, ReputationEventType.ChallengeFailure, false);
            _adjustReputation(validationProposer, ReputationEventType.ValidationProposalSuccess, true); // Validator confirmed correct
            // Contributor's reputation reflects the original verdict, which is now confirmed correct.
            if (task.validationVerdict) { // If previous verdict was valid, and challenger lost, contributor was right.
                _adjustReputation(contributor, ReputationEventType.ContributionSuccess, true);
            } else { // If previous verdict was invalid, and challenger lost, contributor was wrong.
                _adjustReputation(contributor, ReputationEventType.ContributionFailure, false);
            }
        }

        challenge.status = ChallengeStatus.Resolved;
        task.status = TaskStatus.Resolved; // Task is now fully resolved (with or without verdict flip)

        emit ChallengeResolved(_challengeId, challenge.taskId, challengerWon);
    }

    /**
     * @dev 12. Allows a contributor to claim their reward for a successfully validated task.
     *          This is separated from `finalizeTaskValidation` to allow explicit claim action.
     * @param _taskId The ID of the task.
     */
    function claimTaskReward(uint256 _taskId) external onlyRegisteredUser {
        Task storage task = tasks[_taskId];
        require(task.creator != address(0), "SEARE: Task does not exist");
        require(task.contributor == _msgSender(), "SEARE: Only the task contributor can claim this reward");
        require(task.status == TaskStatus.ValidationFinalized || task.status == TaskStatus.Resolved, 
                "SEARE: Task not yet finalized or resolved");
        require(task.validationVerdict, "SEARE: Task contribution was not marked valid");
        require(task.rewardAmount > 0, "SEARE: Reward already claimed or zero");
        require(totalPlatformBalance >= task.rewardAmount, "SEARE: Insufficient funds in contract for reward");

        uint256 reward = task.rewardAmount;
        task.rewardAmount = 0; // Mark as claimed by setting to zero

        totalPlatformBalance = totalPlatformBalance.sub(reward);
        (bool success, ) = payable(_msgSender()).call{value: reward}("");
        require(success, "SEARE: Failed to transfer reward");

        emit TaskRewardClaimed(_taskId, _msgSender(), reward);
    }

    // e. Reputation Management (Decay, Tiers, Dynamic Weights)

    /**
     * @dev 13. The contract owner can adjust the global rate at which reputation naturally decays over time.
     *      This parameter helps maintain a dynamic and active reputation system.
     * @param _newRatePerSecond The new decay rate per second (e.g., 0 for no decay, 10 for faster decay).
     */
    function updateReputationDecayRate(uint256 _newRatePerSecond) external onlyOwner {
        reputationDecayRatePerSecond = _newRatePerSecond;
        emit ReputationDecayRateUpdated(_newRatePerSecond);
    }

    /**
     * @dev 14. The contract owner can define the reputation scores required to reach different privilege tiers.
     *      This allows tuning the difficulty of achieving higher roles in the ecosystem.
     *      The array must contain 5 strictly increasing thresholds for: [Registered, Contributor, Validator, Adjudicator, Governor].
     * @param _newThresholds An array of new reputation thresholds.
     */
    function setReputationTierThresholds(uint256[] memory _newThresholds) external onlyOwner {
        require(_newThresholds.length == 5, "SEARE: Must provide 5 thresholds for all tiers");
        require(_newThresholds[0] == 0, "SEARE: Registered tier threshold must be 0"); // A registered user always has at least 0 rep
        for (uint256 i = 1; i < _newThresholds.length; i++) {
            require(_newThresholds[i] > _newThresholds[i - 1], "SEARE: Thresholds must be strictly increasing");
        }
        reputationTierThresholds = _newThresholds;
        emit ReputationTierThresholdsUpdated(_newThresholds);
    }

    /**
     * @dev 15. The contract owner can directly adjust the reputation impact weight of specific event types.
     *      This is the core "adaptive" mechanism when controlled by a centralized authority (owner initially).
     *      This allows the system to incentivize/disincentivize certain behaviors by changing their reputation impact.
     * @param _eventType The type of reputation event to adjust.
     * @param _newWeight The new weight to apply for this event (e.g., 50 for +50 rep, or 20 for -20 rep if `_isPositive` is false).
     */
    function adjustReputationEventWeight(ReputationEventType _eventType, uint256 _newWeight) external onlyOwner {
        reputationEventWeights[_eventType] = _newWeight;
        emit ReputationEventWeightAdjusted(_eventType, _newWeight);
    }

    // f. System Parameter Proposals & Governance

    /**
     * @dev 16. Users in a designated `Governor` tier can propose changes to the `reputationEventWeights`.
     *      This moves the "adaptive" mechanism towards decentralization.
     * @param _eventType The type of reputation event to propose adjustment for.
     * @param _newWeight The proposed new weight for this event type.
     * @param _descriptionHash IPFS hash for a detailed description/justification of the proposal.
     */
    function proposeDynamicWeightAdjustment(
        ReputationEventType _eventType,
        uint256 _newWeight,
        bytes32 _descriptionHash
    ) external onlyTierNOrHigher(ReputationTier.Governor) {
        uint256 currentProposalId = nextProposalId++;
        weightAdjustmentProposals[currentProposalId] = WeightAdjustmentProposal({
            id: currentProposalId,
            proposer: _msgSender(),
            eventType: _eventType,
            newWeight: _newWeight,
            descriptionHash: _descriptionHash,
            creationTime: uint64(block.timestamp),
            votingDeadline: uint64(block.timestamp.add(proposalVotingPeriod)),
            votesFor: 0,
            votesAgainst: 0,
            status: ProposalStatus.Active,
            hasVoted: new mapping(address => bool) // Initialize mapping
        });

        _adjustReputation(_msgSender(), ReputationEventType.ProposalCreation, true);
        emit WeightAdjustmentProposalCreated(currentProposalId, _msgSender(), _eventType, _newWeight);
    }

    /**
     * @dev 17. Users in the `Governor` tier vote on active weight adjustment proposals.
     *      Their vote weight is directly proportional to their current effective reputation score.
     * @param _proposalId The ID of the proposal to vote on.
     * @param _support True to vote for the proposal, false to vote against it.
     */
    function voteOnWeightAdjustmentProposal(uint256 _proposalId, bool _support) external onlyTierNOrHigher(ReputationTier.Governor) {
        WeightAdjustmentProposal storage proposal = weightAdjustmentProposals[_proposalId];
        require(proposal.proposer != address(0), "SEARE: Proposal does not exist");
        require(proposal.status == ProposalStatus.Active, "SEARE: Proposal not active for voting");
        require(block.timestamp < proposal.votingDeadline, "SEARE: Voting deadline has passed");
        require(!proposal.hasVoted[_msgSender()], "SEARE: Caller has already voted on this proposal");

        proposal.hasVoted[_msgSender()] = true;
        uint256 voterRep = _calculateCurrentReputation(_msgSender());

        if (_support) {
            proposal.votesFor = proposal.votesFor.add(voterRep);
        } else {
            proposal.votesAgainst = proposal.votesAgainst.add(voterRep);
        }

        emit WeightAdjustmentProposalVoted(_proposalId, _msgSender(), _support);
    }

    /**
     * @dev 18. Executes a weight adjustment proposal once its voting deadline has passed and it meets the quorum and pass thresholds.
     *      Any registered user can call this to trigger the execution.
     * @param _proposalId The ID of the proposal to execute.
     */
    function executeWeightAdjustmentProposal(uint256 _proposalId) external onlyRegisteredUser {
        WeightAdjustmentProposal storage proposal = weightAdjustmentProposals[_proposalId];
        require(proposal.proposer != address(0), "SEARE: Proposal does not exist");
        require(proposal.status == ProposalStatus.Active, "SEARE: Proposal not active");
        require(block.timestamp >= proposal.votingDeadline, "SEARE: Voting is still active");

        uint256 totalVotes = proposal.votesFor.add(proposal.votesAgainst);
        bool proposalPassed = false;

        if (totalVotes >= proposalQuorumThreshold && 
            totalVotes > 0 && // Prevent division by zero if no votes were cast
            proposal.votesFor.mul(10000).div(totalVotes) >= proposalPassThreshold) {
            
            reputationEventWeights[proposal.eventType] = proposal.newWeight; // Apply the proposed new weight
            proposal.status = ProposalStatus.Executed;
            proposalPassed = true;
            _adjustReputation(proposal.proposer, ReputationEventType.ProposalVoteSuccess, true); // Proposer gets bonus for successful proposal
        } else {
            proposal.status = ProposalStatus.Failed;
            _adjustReputation(proposal.proposer, ReputationEventType.ProposalVoteFailure, false); // Proposer gets penalty for failed proposal
        }

        emit WeightAdjustmentProposalExecuted(_proposalId, proposalPassed);
    }

    // g. Funds Management

    /**
     * @dev 19. Allows anyone to deposit ETH into the contract. These funds are used to pay out task rewards.
     *      This is a payable function, so it can receive ETH directly.
     */
    function depositFundsForTasks() external payable {
        require(msg.value > 0, "SEARE: Must send ETH to deposit funds");
        totalPlatformBalance = totalPlatformBalance.add(msg.value);
        emit FundsDeposited(_msgSender(), msg.value);
    }

    /**
     * @dev 20. The contract owner can withdraw funds from the contract to a specified address.
     *      In a fully decentralized system, this would transition to a DAO-controlled multisig or similar.
     * @param _to The address to send the withdrawn funds to.
     * @param _amount The amount of ETH (in wei) to withdraw.
     */
    function withdrawPlatformFunds(address _to, uint256 _amount) external onlyOwner {
        require(_amount > 0, "SEARE: Amount must be greater than zero");
        require(totalPlatformBalance >= _amount, "SEARE: Insufficient contract balance to withdraw");

        totalPlatformBalance = totalPlatformBalance.sub(_amount);
        (bool success, ) = payable(_to).call{value: _amount}("");
        require(success, "SEARE: Failed to transfer funds to recipient");

        emit FundsWithdrawn(_to, _amount);
    }

    // h. View Functions
    // These functions allow external callers to read the contract's state without making transactions.

    /**
     * @dev 21. Returns the current effective (decayed) reputation score of a specified user.
     * @param _user The address of the user.
     * @return The calculated effective reputation score.
     */
    function getReputationScore(address _user) external view returns (uint256) {
        return _calculateCurrentReputation(_user);
    }

    /**
     * @dev 22. Returns the current privilege tier of a specified user.
     * @param _user The address of the user.
     * @return The `ReputationTier` of the user.
     */
    function getReputationTier(address _user) external view returns (ReputationTier) {
        return _getReputationTier(_user);
    }

    /**
     * @dev 23. Returns comprehensive details of a specific task.
     * @param _taskId The ID of the task.
     * @return All fields of the `Task` struct.
     */
    function getTaskDetails(uint256 _taskId) external view returns (
        uint256 id,
        address creator,
        bytes32 metadataHash,
        uint256 rewardAmount,
        uint256 deadline,
        uint256 validatorRepTierRequired,
        TaskStatus status,
        address contributor,
        bytes32 contributionHash,
        address validationProposer,
        bool validationVerdict,
        uint256 challengeId
    ) {
        Task storage task = tasks[_taskId];
        require(task.creator != address(0), "SEARE: Task does not exist"); // Ensure task exists
        return (
            task.id,
            task.creator,
            task.metadataHash,
            task.rewardAmount,
            task.deadline,
            task.validatorRepTierRequired,
            task.status,
            task.contributor,
            task.contributionHash,
            task.validationProposer,
            task.validationVerdict,
            task.challengeId
        );
    }

    /**
     * @dev 24. Returns details of a specific challenge.
     * @param _challengeId The ID of the challenge.
     * @return All fields of the `Challenge` struct (excluding the internal `hasVoted` mapping).
     */
    function getChallengeDetails(uint256 _challengeId) external view returns (
        uint256 id,
        uint256 taskId,
        address challenger,
        bytes32 reasonHash,
        address challengedParty,
        bytes32 challengerEvidenceHash,
        bytes32 challengedPartyEvidenceHash,
        ChallengeStatus status,
        uint256 votingDeadline,
        uint256 votesForChallenger,
        uint256 votesAgainstChallenger
    ) {
        Challenge storage challenge = challenges[_challengeId];
        require(challenge.challenger != address(0), "SEARE: Challenge does not exist");
        return (
            challenge.id,
            challenge.taskId,
            challenge.challenger,
            challenge.reasonHash,
            challenge.challengedParty,
            challenge.challengerEvidenceHash,
            challenge.challengedPartyEvidenceHash,
            challenge.status,
            challenge.votingDeadline,
            challenge.votesForChallenger,
            challenge.votesAgainstChallenger
        );
    }

    /**
     * @dev 25. Returns the current dynamic weight for a given reputation event type.
     * @param _eventType The `ReputationEventType` to query.
     * @return The weight associated with the event type.
     */
    function getReputationEventWeight(ReputationEventType _eventType) external view returns (uint256) {
        return reputationEventWeights[_eventType];
    }

    /**
     * @dev 26. Returns details of a specific weight adjustment proposal.
     * @param _proposalId The ID of the proposal.
     * @return All fields of the `WeightAdjustmentProposal` struct (excluding the internal `hasVoted` mapping).
     */
    function getWeightAdjustmentProposal(uint256 _proposalId) external view returns (
        uint256 id,
        address proposer,
        ReputationEventType eventType,
        uint256 newWeight,
        bytes32 descriptionHash,
        uint256 creationTime,
        uint256 votingDeadline,
        uint256 votesFor,
        uint256 votesAgainst,
        ProposalStatus status
    ) {
        WeightAdjustmentProposal storage proposal = weightAdjustmentProposals[_proposalId];
        require(proposal.proposer != address(0), "SEARE: Proposal does not exist");
        return (
            proposal.id,
            proposal.proposer,
            proposal.eventType,
            proposal.newWeight,
            proposal.descriptionHash,
            proposal.creationTime,
            proposal.votingDeadline,
            proposal.votesFor,
            proposal.votesAgainst,
            proposal.status
        );
    }

    /**
     * @dev 27. Get a user's profile metadata hash.
     * @param _user The address of the user.
     * @return The IPFS hash for the user's profile. Returns `bytes32(0)` if user is not registered.
     */
    function getUserProfileMetadataHash(address _user) external view returns (bytes32) {
        return users[_user].profileMetadataHash;
    }

    /**
     * @dev 28. Get the total number of registered users in the ecosystem.
     * @return The total count.
     */
    function getTotalRegisteredUsers() external view returns (uint256) {
        return totalRegisteredUsers;
    }

    /**
     * @dev 29. Get the current total ETH balance held by the contract.
     * @return The total balance in wei.
     */
    function getPlatformBalance() external view returns (uint256) {
        return totalPlatformBalance;
    }

    /**
     * @dev 30. Get the current endorsement threshold required for task validation.
     * @return The minimum total endorsement power required.
     */
    function getTaskEndorsementThreshold() external view returns (uint256) {
        return taskEndorsementThreshold;
    }
}
```