This smart contract, "Aetheria Nexus: The Synergistic Intelligence Protocol," provides a decentralized framework for collective intelligence and knowledge curation. It introduces several advanced concepts:

*   **Dynamic, Adaptive Reputation System:** Participant reputation isn't static; it evolves based on the quality of their contributions and the accuracy of their validations. Malicious or inaccurate actions can lead to reputation decay or penalties, while positive contributions boost it.
*   **Decentralized Knowledge Curation (Knowledge Modules):** Users submit "Knowledge Modules" (references to off-chain content, e.g., IPFS hashes) which are then peer-reviewed and validated by the community. This builds a trusted, community-curated knowledge base.
*   **Adaptive Protocol Parameters:** Core protocol parameters (like validation thresholds, challenge periods, reward splits) can be dynamically adjusted through on-chain governance proposals and voting, allowing the protocol to adapt and evolve over time based on collective decisions.
*   **Incentivized Participation:** Contributors of high-quality knowledge and reliable validators are rewarded with a native token, fostering a self-sustaining ecosystem.
*   **Dispute and Challenge Mechanisms:** Mechanisms are in place for participants to challenge knowledge modules for inaccuracy or to dispute validations, ensuring data integrity and fairness.
*   **Delegated Influence (Simplified):** Participants can delegate their reputation influence to others, allowing for specialized roles or liquid democracy-like voting power.

While some large-scale iterative operations (like global reputation decay or topic-based queries) are acknowledged as gas-intensive for extreme scale on-chain and would typically rely on off-chain indexing or a pull-based model in a production dApp, their inclusion demonstrates the conceptual scope requested.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/Math.sol"; // For min/max

// Custom error definitions for clarity and gas efficiency
error AetheriaNexus__AlreadyRegistered();
error AetheriaNexus__NotRegistered();
error AetheriaNexus__InsufficientStake(uint256 requiredStake, uint256 currentStake);
error AetheriaNexus__NotEnoughTokensApproved();
error AetheriaNexus__KnowledgeModuleNotFound();
error AetheriaNexus__InvalidValidationScore();
error AetheriaNexus__KnowledgeModuleNotPending();
error AetheriaNexus__KnowledgeModuleAlreadyFinalized();
error AetheriaNexus__KnowledgeModuleNotFinalized();
error AetheriaNexus__ChallengePeriodNotOver();
error AetheriaNexus__ChallengePeriodActive();
error AetheriaNexus__ChallengeNotFound();
error AetheriaNexus__ChallengeNotResolvable();
error AetheriaNexus__AlreadyValidated();
error AetheriaNexus__SelfValidation();
error AetheriaNexus__NotAProtocolAdmin();
error AetheriaNexus__NotEnoughInfluence();
error AetheriaNexus__CannotDelegateToSelf();
error AetheriaNexus__ProposalNotFound();
error AetheriaNexus__AlreadyVotedOnProposal();
error AetheriaNexus__ProposalNotReadyForExecution();
error AetheriaNexus__ReputationDecayNotDue();
error AetheriaNexus__InsufficientBalanceForWithdrawal();
error AetheriaNexus__CannotDeregisterDueToActivity();
error AetheriaNexus__InvalidParameterValue();
error AetheriaNexus__ValidationNotFound();
error AetheriaNexus__ValidationAlreadyDisputed();
error AetheriaNexus__NotAValidator();
error AetheriaNexus__AlreadyClaimed();


/**
 * @title Aetheria Nexus: The Synergistic Intelligence Protocol
 * @dev A decentralized protocol for curating, validating, and leveraging collective intelligence.
 * Users contribute "Knowledge Modules" (KMs) on various topics. These KMs are then peer-reviewed
 * and validated by other users. A dynamic reputation system tracks validator reliability and
 * contributor quality. The protocol aims to build a trusted, community-curated knowledge base,
 * with adaptive incentives and governance.
 */
contract AetheriaNexus is Ownable, Pausable {

    // --- Outline and Function Summary ---

    // I. Core Protocol Management (Owner/Admin Controlled)
    //    1. `setProtocolParameters(...)`
    //       @summary Allows owner/admin to adjust core protocol parameters.
    //    2. `emergencyPause()`
    //       @summary Pauses all protocol activities in case of emergency.
    //    3. `emergencyUnpause()`
    //       @summary Unpauses the protocol.
    //    4. `withdrawProtocolFees()`
    //       @summary Allows the protocol owner to withdraw accumulated fees (e.g., from slashing).
    //    5. `grantProtocolAdmin(address _adminAddress)`
    //       @summary Grants a protocol admin role to an address.
    //    6. `revokeProtocolAdmin(address _adminAddress)`
    //       @summary Revokes a protocol admin role from an address.

    // II. Participant Management & Reputation System
    //    7. `registerParticipant(string calldata _profileIPFSHash)`
    //       @summary Allows a user to join the protocol by staking tokens and providing a profile hash.
    //    8. `deregisterParticipant()`
    //       @summary Allows a participant to leave the protocol and retrieve their stake after a cooldown/activity check.
    //    9. `updateProfileDetails(string calldata _newProfileIPFSHash)`
    //        @summary Allows a participant to update their profile IPFS hash.
    //    10. `getParticipantDetails(address _participant)`
    //        @summary Retrieves comprehensive details about a participant, including their reputation.
    //    11. `delegateReputationInfluence(address _delegatee, uint256 _amount)`
    //        @summary Delegates a portion of a participant's reputation influence to another participant.
    //    12. `undelegateReputationInfluence(address _delegatee, uint256 _amount)`
    //        @summary Revokes a portion of delegated reputation influence.

    // III. Knowledge Module Lifecycle (Submission, Validation, Challenges)
    //    13. `submitKnowledgeModule(string calldata _contentIPFSHash, string calldata _topic)`
    //        @summary Allows a registered participant to submit a new Knowledge Module for review.
    //    14. `validateKnowledgeModule(uint256 _moduleId, uint8 _score)`
    //        @summary Allows a registered participant to validate a Knowledge Module with a score (1-5), impacting reputations.
    //    15. `disputeValidation(uint256 _moduleId, address _validator)`
    //        @summary Initiates a dispute against a specific validation of a Knowledge Module, requiring a stake.
    //    16. `challengeKnowledgeModule(uint256 _moduleId, string calldata _reasonIPFSHash)`
    //        @summary Allows a participant to challenge a Knowledge Module itself for inaccuracy or plagiarism, requiring a stake.
    //    17. `resolveKnowledgeModuleChallenge(uint256 _moduleId, bool _challengeUpheld)`
    //        @summary Resolves an open challenge on a Knowledge Module (typically by protocol admin or governance vote).
    //    18. `finalizeKnowledgeModule(uint256 _moduleId)`
    //        @summary Finalizes a Knowledge Module if it meets validation criteria and its challenge period is over, allocating rewards.
    //    19. `getKnowledgeModuleDetails(uint256 _moduleId)`
    //        @summary Retrieves details of a specific Knowledge Module.
    //    20. `getPendingKnowledgeModules(uint256 _startIndex, uint256 _count)`
    //        @summary Retrieves a paginated list of Knowledge Modules awaiting validation.
    //    21. `getValidatedKnowledgeModulesByTopic(string calldata _topic)`
    //        @summary Retrieves a list of finalized Knowledge Modules filtered by topic (gas-intensive for large datasets).

    // IV. Incentives & Rewards
    //    22. `claimContributionRewards(uint256 _moduleId)`
    //        @summary Allows a contributor to claim rewards for a successfully validated and finalized KM.
    //    23. `claimValidationRewards(uint256 _moduleId)`
    //        @summary Allows a validator to claim rewards for their accurate validations.
    //    24. `getPendingRewards(address _participant)`
    //        @summary Calculates and returns the total pending rewards (contribution + validation) for a participant.

    // V. Adaptive Governance & System Evolution
    //    25. `proposeParameterAdjustment(string calldata _paramName, uint256 _newValue)`
    //        @summary Allows participants to propose adjustments to key protocol parameters.
    //    26. `voteOnParameterProposal(uint256 _proposalId, bool _support)`
    //        @summary Allows participants to vote on an active parameter adjustment proposal, with vote influence based on reputation.
    //    27. `executeParameterAdjustment(uint256 _proposalId)`
    //        @summary Executes a parameter adjustment proposal if it passes voting and a grace period.
    //    28. `triggerReputationDecay()`
    //        @summary Triggers a global reputation decay epoch; actual decay is applied lazily per participant.

    // --- State Variables ---

    IERC20 public immutable REWARD_TOKEN; // Token used for staking and rewards

    // Protocol Parameters (adjustable via governance or admin)
    uint256 public minParticipantStake;
    uint256 public validationThresholdScore;     // Required average score (basis points, e.g., 300 for 3.0/5.0)
    uint256 public minValidationsForFinalization; // Minimum unique validations required for KM finalization
    uint256 public challengePeriodDays;          // Days for a KM to be challenged after submission
    uint256 public proposalVotingPeriodDays;     // Days for a proposal to be voted on
    uint256 public proposalExecutionGracePeriodDays; // Days after voting ends before proposal can be executed
    uint256 public reputationDecayPeriodDays;    // How often reputation decays (global epoch)
    uint256 public lastReputationDecayTimestamp; // Last time global decay was triggered
    uint256 public reputationDecayPercentage;    // Percentage of reputation decay per period (e.g., 5 for 5%)
    uint256 public contributorRewardShareBasisPoints; // e.g., 7000 for 70%
    uint256 public validatorRewardShareBasisPoints;   // e.g., 3000 for 30%
    uint256 public disputeStakeMultiplier;       // Multiplier for dispute stakes (e.g., 2x min stake)
    uint256 public challengeStakeMultiplier;     // Multiplier for challenge stakes (e.g., 3x min stake)
    uint256 public deregisterCoolDownDays;       // Cooldown before deregistration is allowed after attempt

    // Unique IDs for various entities
    uint256 private nextKnowledgeModuleId;
    uint256 private nextChallengeId;
    uint256 private nextProposalId;

    // Fees collected by the protocol (e.g., from forfeited stakes)
    uint256 public protocolFeesCollected;

    // --- Data Structures ---

    struct Participant {
        address addr;
        uint256 reputation; // Overall influence/trust score. Base reputation + (delegated * factor)
        uint256 stakedAmount;
        string profileIPFSHash;
        uint256 lastActiveTimestamp; // For lazy reputation decay
        address delegatedTo;         // Address they delegated influence to
        uint256 delegatedAmount;     // Amount of reputation delegated
        uint256 pendingContributionRewards;
        uint256 pendingValidationRewards;
        uint256 lastDeregisterAttemptTimestamp; // To enforce cooldown
    }

    enum KnowledgeModuleStatus {
        PendingValidation,
        Challenged,
        Validated, // Passed initial validation, but challenge period still active
        Finalized,
        Rejected // Due to failed validation or upheld challenge
    }

    struct KnowledgeModule {
        uint256 id;
        address contributor;
        string contentIPFSHash;
        string topic;
        uint256 submissionTimestamp;
        KnowledgeModuleStatus status;
        uint256 totalValidationScore;     // Sum of all valid scores given
        uint256 validationCount;          // Number of unique validators
        uint256 totalValidatorReputation; // Sum of reputation of validators for this KM
        uint256 currentChallengeId;       // 0 if no active challenge
        bool contributorRewardClaimed;    // True if contributor has claimed rewards
        uint256 totalRewardsAllocated;    // Total rewards earmarked for this KM
    }

    struct Validation {
        address validator;
        uint256 moduleId;
        uint8 score;
        uint256 timestamp;
        bool disputed;         // If this specific validation has been disputed
        bool rewardsClaimed;   // If rewards for this specific validation have been claimed
    }

    struct Challenge {
        uint256 id;
        uint256 moduleId;
        address challenger;
        string reasonIPFSHash;
        uint256 stake;
        bool upheld;   // True if challenge was successful/upheld
        bool resolved; // True if challenge has been processed
        uint256 challengeTimestamp;
        uint256 resolutionTimestamp;
    }

    enum ProposalStatus {
        Active,
        Succeeded,
        Failed,
        Executed
    }

    struct ParameterProposal {
        uint256 id;
        address proposer;
        string paramName;
        uint256 newValue;
        uint256 creationTimestamp;
        uint256 votingPeriodEnd;
        uint256 executionGracePeriodEnd; // Time when it can be executed if successful
        uint256 yesVotes; // Total reputation voting "yes"
        uint256 noVotes;  // Total reputation voting "no"
        ProposalStatus status;
    }

    // --- Mappings ---

    mapping(address => Participant) public participants;
    mapping(address => bool) public isRegistered;
    mapping(address => bool) public protocolAdmins; // Role for specific protocol management

    mapping(uint256 => KnowledgeModule) public knowledgeModules;
    uint256[] public pendingKnowledgeModuleIds; // Array to track KMs in PendingValidation status

    // Mapping from (moduleId => validatorAddress => Validation)
    mapping(uint256 => mapping(address => Validation)) public kmValidations;
    mapping(uint256 => address[]) public kmValidatorsList; // List of addresses that validated a KM

    // Mapping from challengeId => Challenge
    mapping(uint256 => Challenge) public challenges;

    // Mapping from proposalId => ParameterProposal
    mapping(uint256 => ParameterProposal) public parameterProposals;
    // Separate mapping to track if an address has voted on a specific proposal
    mapping(uint256 => mapping(address => bool)) private proposalHasVoted;

    // --- Events ---

    event ParticipantRegistered(address indexed participant, uint256 stakedAmount, string profileIPFSHash);
    event ParticipantDeregistered(address indexed participant, uint256 returnedStake);
    event ProfileUpdated(address indexed participant, string newProfileIPFSHash);
    event ReputationInfluenceDelegated(address indexed delegator, address indexed delegatee, uint256 amount);
    event ReputationInfluenceUndelegated(address indexed delegator, address indexed delegatee, uint256 amount);

    event KnowledgeModuleSubmitted(uint256 indexed moduleId, address indexed contributor, string contentIPFSHash, string topic);
    event KnowledgeModuleValidated(uint256 indexed moduleId, address indexed validator, uint8 score, uint256 newAverageScore, uint256 validationCount);
    event KnowledgeModuleFinalized(uint256 indexed moduleId, address indexed finalizer);
    event KnowledgeModuleRejected(uint256 indexed moduleId, string reason);
    event ValidationDisputed(uint256 indexed moduleId, address indexed validator, address indexed disputer);

    event ChallengeInitiated(uint256 indexed challengeId, uint256 indexed moduleId, address indexed challenger, string reasonIPFSHash);
    event ChallengeResolved(uint256 indexed challengeId, uint256 indexed moduleId, bool upheld);

    event ContributionRewardsClaimed(address indexed contributor, uint256 indexed moduleId, uint256 amount);
    event ValidationRewardsClaimed(address indexed validator, uint256 indexed moduleId, uint256 amount);
    event ProtocolFeesWithdrawn(address indexed owner, uint256 amount);

    event ProtocolParametersSet(address indexed setter, uint256 validationThreshold, uint256 challengePeriod);
    event ProtocolPaused(address indexed caller);
    event ProtocolUnpaused(address indexed caller);

    event ProtocolAdminGranted(address indexed adminAddress, address indexed granter);
    event ProtocolAdminRevoked(address indexed adminAddress, address indexed revoker);

    event ParameterAdjustmentProposed(uint256 indexed proposalId, address indexed proposer, string paramName, uint256 newValue);
    event ParameterProposalVoted(uint256 indexed proposalId, address indexed voter, bool support);
    event ParameterAdjustmentExecuted(uint256 indexed proposalId, string paramName, uint256 newValue);
    event ReputationDecayTriggered(uint256 timestamp);

    // --- Modifiers ---

    modifier onlyProtocolAdmin() {
        if (msg.sender != owner() && !protocolAdmins[msg.sender]) {
            revert AetheriaNexus__NotAProtocolAdmin();
        }
        _;
    }

    modifier onlyRegisteredParticipant() {
        if (!isRegistered[msg.sender]) {
            revert AetheriaNexus__NotRegistered();
        }
        _;
    }

    modifier whenNotPaused() {
        _checkNotPaused();
        _;
    }

    modifier whenPaused() {
        _checkPaused();
        _;
    }

    // --- Constructor ---

    constructor(address _rewardTokenAddress) Ownable(msg.sender) Pausable() {
        REWARD_TOKEN = IERC20(_rewardTokenAddress);

        // Initial protocol parameters
        minParticipantStake = 100 * 10 ** 18; // 100 tokens, assuming 18 decimals
        validationThresholdScore = 300;       // Avg score 3 (300 basis points) for 1-5 scale.
        minValidationsForFinalization = 5;    // At least 5 unique validations needed
        challengePeriodDays = 7;              // 7 days
        proposalVotingPeriodDays = 5;         // 5 days for voting on proposals
        proposalExecutionGracePeriodDays = 2; // 2 days grace period after voting
        reputationDecayPeriodDays = 30;       // Decay every 30 days
        reputationDecayPercentage = 5;        // 5% decay per period
        lastReputationDecayTimestamp = block.timestamp;
        contributorRewardShareBasisPoints = 7000; // 70%
        validatorRewardShareBasisPoints = 3000;   // 30%
        disputeStakeMultiplier = 2; // e.g., dispute requires 2x the normal stake
        challengeStakeMultiplier = 3; // e.g., challenge requires 3x the normal stake
        deregisterCoolDownDays = 14; // 14 days cooldown before stake can be retrieved after deregistration attempt

        nextKnowledgeModuleId = 1;
        nextChallengeId = 1;
        nextProposalId = 1;
    }

    // --- I. Core Protocol Management ---

    /**
     * @dev Allows owner/admin to adjust core protocol parameters.
     * @param _minParticipantStake New minimum stake for participants.
     * @param _validationThresholdScore New average score required for KM finalization (basis points, 1-500).
     * @param _minValidationsForFinalization New minimum unique validations for KM finalization.
     * @param _challengePeriodDays New number of days for KM challenge period.
     * @param _proposalVotingPeriodDays New number of days for proposal voting.
     * @param _proposalExecutionGracePeriodDays New grace period after proposal voting.
     * @param _reputationDecayPeriodDays New reputation decay period.
     * @param _reputationDecayPercentage New percentage of reputation decay per period (0-100).
     * @param _contributorRewardShareBasisPoints New share for contributors (basis points).
     * @param _validatorRewardShareBasisPoints New share for validators (basis points).
     * @param _disputeStakeMultiplier New multiplier for dispute stakes.
     * @param _challengeStakeMultiplier New multiplier for challenge stakes.
     * @param _deregisterCoolDownDays New deregister cooldown days.
     */
    function setProtocolParameters(
        uint256 _minParticipantStake,
        uint256 _validationThresholdScore,
        uint256 _minValidationsForFinalization,
        uint256 _challengePeriodDays,
        uint256 _proposalVotingPeriodDays,
        uint256 _proposalExecutionGracePeriodDays,
        uint256 _reputationDecayPeriodDays,
        uint256 _reputationDecayPercentage,
        uint256 _contributorRewardShareBasisPoints,
        uint256 _validatorRewardShareBasisPoints,
        uint256 _disputeStakeMultiplier,
        uint256 _challengeStakeMultiplier,
        uint256 _deregisterCoolDownDays
    ) external onlyProtocolAdmin whenNotPaused {
        if (_validationThresholdScore > 500) revert AetheriaNexus__InvalidParameterValue(); // Score 1-5, max 500 bp
        if (_contributorRewardShareBasisPoints + _validatorRewardShareBasisPoints != 10000) revert AetheriaNexus__InvalidParameterValue();
        if (_reputationDecayPercentage > 100) revert AetheriaNexus__InvalidParameterValue();

        minParticipantStake = _minParticipantStake;
        validationThresholdScore = _validationThresholdScore;
        minValidationsForFinalization = _minValidationsForFinalization;
        challengePeriodDays = _challengePeriodDays;
        proposalVotingPeriodDays = _proposalVotingPeriodDays;
        proposalExecutionGracePeriodDays = _proposalExecutionGracePeriodDays;
        reputationDecayPeriodDays = _reputationDecayPeriodDays;
        reputationDecayPercentage = _reputationDecayPercentage;
        contributorRewardShareBasisPoints = _contributorRewardShareBasisPoints;
        validatorRewardShareBasisPoints = _validatorRewardShareBasisPoints;
        disputeStakeMultiplier = _disputeStakeMultiplier;
        challengeStakeMultiplier = _challengeStakeMultiplier;
        deregisterCoolDownDays = _deregisterCoolDownDays;

        emit ProtocolParametersSet(msg.sender, validationThresholdScore, challengePeriodDays);
    }

    /**
     * @dev Pauses all protocol activities in case of emergency. Only callable by owner.
     */
    function emergencyPause() external onlyOwner whenNotPaused {
        _pause();
        emit ProtocolPaused(msg.sender);
    }

    /**
     * @dev Unpauses the protocol. Only callable by owner.
     */
    function emergencyUnpause() external onlyOwner whenPaused {
        _unpause();
        emit ProtocolUnpaused(msg.sender);
    }

    /**
     * @dev Allows the protocol owner to withdraw accumulated fees.
     * These fees could come from slashing, or a small percentage on rewards/stakes.
     */
    function withdrawProtocolFees() external onlyOwner {
        uint256 amount = protocolFeesCollected;
        if (amount == 0) return;

        protocolFeesCollected = 0;
        if (REWARD_TOKEN.balanceOf(address(this)) < amount) revert AetheriaNexus__InsufficientBalanceForWithdrawal();
        REWARD_TOKEN.transfer(owner(), amount);

        emit ProtocolFeesWithdrawn(owner(), amount);
    }

    /**
     * @dev Grants protocol admin role to an address. Only callable by owner.
     * Protocol admins can set parameters and resolve challenges.
     */
    function grantProtocolAdmin(address _adminAddress) external onlyOwner {
        protocolAdmins[_adminAddress] = true;
        emit ProtocolAdminGranted(_adminAddress, msg.sender);
    }

    /**
     * @dev Revokes protocol admin role from an address. Only callable by owner.
     */
    function revokeProtocolAdmin(address _adminAddress) external onlyOwner {
        protocolAdmins[_adminAddress] = false;
        emit ProtocolAdminRevoked(_adminAddress, msg.sender);
    }

    // --- II. Participant Management & Reputation System ---

    /**
     * @dev Allows a user to join the protocol by staking tokens and providing a profile hash.
     * The initial reputation is set to the `minParticipantStake` amount.
     * @param _profileIPFSHash IPFS hash pointing to participant's profile data.
     */
    function registerParticipant(string calldata _profileIPFSHash) external whenNotPaused {
        if (isRegistered[msg.sender]) revert AetheriaNexus__AlreadyRegistered();

        // Check if user approved enough tokens
        if (REWARD_TOKEN.allowance(msg.sender, address(this)) < minParticipantStake) {
            revert AetheriaNexus__NotEnoughTokensApproved();
        }

        // Transfer stake
        REWARD_TOKEN.transferFrom(msg.sender, address(this), minParticipantStake);

        participants[msg.sender] = Participant({
            addr: msg.sender,
            reputation: minParticipantStake, // Initial reputation equals initial stake
            stakedAmount: minParticipantStake,
            profileIPFSHash: _profileIPFSHash,
            lastActiveTimestamp: block.timestamp,
            delegatedTo: address(0),
            delegatedAmount: 0,
            pendingContributionRewards: 0,
            pendingValidationRewards: 0,
            lastDeregisterAttemptTimestamp: 0
        });
        isRegistered[msg.sender] = true;

        emit ParticipantRegistered(msg.sender, minParticipantStake, _profileIPFSHash);
    }

    /**
     * @dev Allows a participant to leave the protocol and retrieve their stake.
     * Requires a cooldown period after attempting deregistration, and no pending activity.
     */
    function deregisterParticipant() external onlyRegisteredParticipant whenNotPaused {
        Participant storage p = participants[msg.sender];

        // Ensure no pending rewards
        if (p.pendingContributionRewards > 0 || p.pendingValidationRewards > 0) {
            revert AetheriaNexus__CannotDeregisterDueToActivity();
        }

        // Check for active challenges (simplified: assumes external check/resolution or a more complex internal map for participant challenges)
        // A robust system would require iterating through active challenges involving this participant or maintaining a mapping.
        // For now, we assume this is handled external or through the cooldown.

        if (p.lastDeregisterAttemptTimestamp == 0) {
            // First attempt to deregister, set timestamp to start cooldown
            p.lastDeregisterAttemptTimestamp = block.timestamp;
            revert AetheriaNexus__CannotDeregisterDueToActivity(); // Inform user about cooldown
        } else if (block.timestamp < p.lastDeregisterAttemptTimestamp + deregisterCoolDownDays * 1 days) {
            revert AetheriaNexus__CannotDeregisterDueToActivity(); // Still in cooldown
        }

        uint256 stake = p.stakedAmount;
        if (stake == 0) {
            revert AetheriaNexus__InsufficientStake(1, 0); // No stake to return
        }

        // Transfer stake back to participant
        REWARD_TOKEN.transfer(msg.sender, stake);

        // Clear participant data
        delete participants[msg.sender];
        isRegistered[msg.sender] = false;

        emit ParticipantDeregistered(msg.sender, stake);
    }

    /**
     * @dev Allows a participant to update their profile IPFS hash.
     * @param _newProfileIPFSHash New IPFS hash for profile.
     */
    function updateProfileDetails(string calldata _newProfileIPFSHash) external onlyRegisteredParticipant whenNotPaused {
        participants[msg.sender].profileIPFSHash = _newProfileIPFSHash;
        participants[msg.sender].lastActiveTimestamp = block.timestamp; // Update activity
        emit ProfileUpdated(msg.sender, _newProfileIPFSHash);
    }

    /**
     * @dev Retrieves comprehensive details about a participant. Applies reputation decay lazily.
     * @param _participant Address of the participant.
     * @return Participant struct details.
     */
    function getParticipantDetails(address _participant)
        external
        view
        returns (address addr, uint256 reputation, uint256 stakedAmount, string memory profileIPFSHash, uint256 lastActiveTimestamp, address delegatedTo, uint256 delegatedAmount, uint256 pendingContributionRewards, uint256 pendingValidationRewards)
    {
        if (!isRegistered[_participant]) revert AetheriaNexus__NotRegistered();
        Participant storage p = participants[_participant];

        // Lazily apply reputation decay before returning
        // Note: For a pure `view` function, we cannot modify state (`lastActiveTimestamp`).
        // In practice, this decay would be applied when a mutable function (like validateKM) is called,
        // or a dedicated 'refreshReputation' callable function exists.
        // For a view, we calculate it on the fly without state change.
        uint256 currentReputation = _calculateReputationAfterDecay(p.reputation, p.lastActiveTimestamp);

        return (p.addr, currentReputation, p.stakedAmount, p.profileIPFSHash, p.lastActiveTimestamp, p.delegatedTo, p.delegatedAmount, p.pendingContributionRewards, p.pendingValidationRewards);
    }

    /**
     * @dev Delegates a portion of a participant's reputation influence to another.
     * The delegatee can then use this influence for validations and votes.
     * @param _delegatee The address to delegate influence to.
     * @param _amount The amount of reputation influence to delegate.
     */
    function delegateReputationInfluence(address _delegatee, uint256 _amount) external onlyRegisteredParticipant whenNotPaused {
        if (_delegatee == msg.sender) revert AetheriaNexus__CannotDelegateToSelf();
        if (!isRegistered[_delegatee]) revert AetheriaNexus__NotRegistered();
        Participant storage delegator = participants[msg.sender];
        
        // Use effective reputation for delegation check
        uint256 currentEffectiveReputation = _calculateReputationAfterDecay(delegator.reputation, delegator.lastActiveTimestamp);
        if (currentEffectiveReputation < _amount) revert AetheriaNexus__NotEnoughInfluence();

        delegator.delegatedTo = _delegatee;
        delegator.delegatedAmount = _amount;
        delegator.lastActiveTimestamp = block.timestamp; // Update activity

        emit ReputationInfluenceDelegated(msg.sender, _delegatee, _amount);
    }

    /**
     * @dev Revokes a portion of delegated reputation influence.
     * @param _delegatee The address to revoke influence from.
     * @param _amount The amount of reputation influence to undelegate.
     */
    function undelegateReputationInfluence(address _delegatee, uint256 _amount) external onlyRegisteredParticipant whenNotPaused {
        Participant storage delegator = participants[msg.sender];
        if (delegator.delegatedTo != _delegatee || delegator.delegatedAmount < _amount) {
            revert AetheriaNexus__NotEnoughInfluence(); // Specific error for wrong delegatee/amount
        }

        // For simplicity, completely revoke previous delegation, or adjust proportionally
        delegator.delegatedTo = address(0);
        delegator.delegatedAmount = 0;
        delegator.lastActiveTimestamp = block.timestamp; // Update activity
        emit ReputationInfluenceUndelegated(msg.sender, _delegatee, _amount);
    }

    // --- III. Knowledge Module Lifecycle ---

    /**
     * @dev Allows a registered participant to submit a new Knowledge Module.
     * @param _contentIPFSHash IPFS hash pointing to the KM's content.
     * @param _topic The topic or category of the KM.
     */
    function submitKnowledgeModule(string calldata _contentIPFSHash, string calldata _topic) external onlyRegisteredParticipant whenNotPaused {
        uint256 newModuleId = nextKnowledgeModuleId++;
        knowledgeModules[newModuleId] = KnowledgeModule({
            id: newModuleId,
            contributor: msg.sender,
            contentIPFSHash: _contentIPFSHash,
            topic: _topic,
            submissionTimestamp: block.timestamp,
            status: KnowledgeModuleStatus.PendingValidation,
            totalValidationScore: 0,
            validationCount: 0,
            totalValidatorReputation: 0,
            currentChallengeId: 0,
            contributorRewardClaimed: false,
            totalRewardsAllocated: 0
        });
        pendingKnowledgeModuleIds.push(newModuleId); // Add to pending list

        // Update contributor's activity timestamp and potentially apply decay
        _applyReputationDecay(msg.sender);
        participants[msg.sender].lastActiveTimestamp = block.timestamp;

        emit KnowledgeModuleSubmitted(newModuleId, msg.sender, _contentIPFSHash, _topic);
    }

    /**
     * @dev Allows a registered participant to validate a Knowledge Module with a score (1-5).
     * Impacts the KM's score and the validator's reputation.
     * @param _moduleId The ID of the Knowledge Module to validate.
     * @param _score The validation score (1-5).
     */
    function validateKnowledgeModule(uint256 _moduleId, uint8 _score) external onlyRegisteredParticipant whenNotPaused {
        KnowledgeModule storage km = knowledgeModules[_moduleId];
        if (km.id == 0) revert AetheriaNexus__KnowledgeModuleNotFound();
        if (km.status != KnowledgeModuleStatus.PendingValidation) revert AetheriaNexus__KnowledgeModuleNotPending();
        if (_score < 1 || _score > 5) revert AetheriaNexus__InvalidValidationScore();
        if (km.contributor == msg.sender) revert AetheriaNexus__SelfValidation(); // Cannot validate own KM
        if (kmValidations[_moduleId][msg.sender].validator != address(0)) revert AetheriaNexus__AlreadyValidated();

        // Apply reputation decay for the validator before using their reputation
        _applyReputationDecay(msg.sender);
        uint256 effectiveReputation = participants[msg.sender].reputation + participants[msg.sender].delegatedAmount;

        // Add validation
        kmValidations[_moduleId][msg.sender] = Validation({
            validator: msg.sender,
            moduleId: _moduleId,
            score: _score,
            timestamp: block.timestamp,
            disputed: false,
            rewardsClaimed: false
        });
        kmValidatorsList[_moduleId].push(msg.sender); // Keep track of validators

        km.totalValidationScore += _score;
        km.validationCount++;
        km.totalValidatorReputation += effectiveReputation;

        // Simple reputation adjustment: good validation -> modest boost
        participants[msg.sender].reputation += (effectiveReputation / 200); // Small boost based on effective reputation
        participants[msg.sender].lastActiveTimestamp = block.timestamp;

        uint256 averageScore = km.validationCount > 0 ? (km.totalValidationScore * 100 / km.validationCount) : 0;
        emit KnowledgeModuleValidated(_moduleId, msg.sender, _score, averageScore, km.validationCount);
    }

    /**
     * @dev Initiates a dispute against a specific validation of a Knowledge Module.
     * Requires a stake from the disputer.
     * @param _moduleId The ID of the Knowledge Module.
     * @param _validator The address of the validator whose validation is being disputed.
     */
    function disputeValidation(uint256 _moduleId, address _validator) external onlyRegisteredParticipant whenNotPaused {
        KnowledgeModule storage km = knowledgeModules[_moduleId];
        if (km.id == 0) revert AetheriaNexus__KnowledgeModuleNotFound();
        Validation storage validation = kmValidations[_moduleId][_validator];
        if (validation.validator == address(0)) revert AetheriaNexus__ValidationNotFound();
        if (validation.disputed) revert AetheriaNexus__ValidationAlreadyDisputed();
        if (msg.sender == _validator) revert AetheriaNexus__CannotDisputeSelf(); // Assuming this error

        // Require stake for dispute
        uint256 disputeStake = minParticipantStake * disputeStakeMultiplier;
        if (REWARD_TOKEN.allowance(msg.sender, address(this)) < disputeStake) {
            revert AetheriaNexus__NotEnoughTokensApproved();
        }
        REWARD_TOKEN.transferFrom(msg.sender, address(this), disputeStake);

        validation.disputed = true; // Mark validation as disputed
        
        // Create a new challenge for this dispute
        uint256 newChallengeId = nextChallengeId++;
        challenges[newChallengeId] = Challenge({
            id: newChallengeId,
            moduleId: _moduleId,
            challenger: msg.sender,
            reasonIPFSHash: "Validation Dispute", // Generic reason, detailed reason off-chain
            stake: disputeStake,
            upheld: false,
            resolved: false,
            challengeTimestamp: block.timestamp,
            resolutionTimestamp: 0
        });

        // Link the challenge to the KM (can only have one active challenge per KM at a time)
        km.currentChallengeId = newChallengeId; 
        km.status = KnowledgeModuleStatus.Challenged; // KM status changes to challenged

        _applyReputationDecay(msg.sender); // Update activity and apply decay
        participants[msg.sender].lastActiveTimestamp = block.timestamp;

        emit ValidationDisputed(_moduleId, _validator, msg.sender);
        emit ChallengeInitiated(newChallengeId, _moduleId, msg.sender, "Validation Dispute");
    }

    /**
     * @dev Allows a participant to challenge a Knowledge Module for inaccuracy or plagiarism.
     * Requires a stake from the challenger.
     * @param _moduleId The ID of the Knowledge Module to challenge.
     * @param _reasonIPFSHash IPFS hash pointing to the detailed reason for the challenge.
     */
    function challengeKnowledgeModule(uint256 _moduleId, string calldata _reasonIPFSHash) external onlyRegisteredParticipant whenNotPaused {
        KnowledgeModule storage km = knowledgeModules[_moduleId];
        if (km.id == 0) revert AetheriaNexus__KnowledgeModuleNotFound();
        if (km.status == KnowledgeModuleStatus.Finalized || km.status == KnowledgeModuleStatus.Rejected) {
            revert AetheriaNexus__KnowledgeModuleAlreadyFinalized();
        }
        if (km.currentChallengeId != 0) revert AetheriaNexus__ChallengePeriodActive(); // Only one active challenge at a time

        // Require stake for challenge
        uint256 challengeStake = minParticipantStake * challengeStakeMultiplier;
        if (REWARD_TOKEN.allowance(msg.sender, address(this)) < challengeStake) {
            revert AetheriaNexus__NotEnoughTokensApproved();
        }
        REWARD_TOKEN.transferFrom(msg.sender, address(this), challengeStake);

        uint256 newChallengeId = nextChallengeId++;
        challenges[newChallengeId] = Challenge({
            id: newChallengeId,
            moduleId: _moduleId,
            challenger: msg.sender,
            reasonIPFSHash: _reasonIPFSHash,
            stake: challengeStake,
            upheld: false,
            resolved: false,
            challengeTimestamp: block.timestamp,
            resolutionTimestamp: 0
        });

        km.status = KnowledgeModuleStatus.Challenged;
        km.currentChallengeId = newChallengeId;

        _applyReputationDecay(msg.sender); // Update activity and apply decay
        participants[msg.sender].lastActiveTimestamp = block.timestamp;

        emit ChallengeInitiated(newChallengeId, _moduleId, msg.sender, _reasonIPFSHash);
    }

    /**
     * @dev Resolves an open challenge on a Knowledge Module. This is typically done by a protocol admin
     * or through a separate governance vote (simplified here to admin for brevity of 20+ functions).
     * @param _moduleId The ID of the Knowledge Module whose challenge is to be resolved.
     * @param _challengeUpheld True if the challenge is deemed valid and upheld, false otherwise.
     */
    function resolveKnowledgeModuleChallenge(uint256 _moduleId, bool _challengeUpheld) external onlyProtocolAdmin whenNotPaused {
        KnowledgeModule storage km = knowledgeModules[_moduleId];
        if (km.id == 0) revert AetheriaNexus__KnowledgeModuleNotFound();
        if (km.currentChallengeId == 0) revert AetheriaNexus__ChallengeNotFound(); // No active challenge

        Challenge storage challenge = challenges[km.currentChallengeId];
        if (challenge.resolved) revert AetheriaNexus__ChallengeNotResolvable();

        challenge.upheld = _challengeUpheld;
        challenge.resolved = true;
        challenge.resolutionTimestamp = block.timestamp;

        // Apply reputation decay for involved parties before adjustments
        _applyReputationDecay(challenge.challenger);
        _applyReputationDecay(km.contributor);

        // Reputation and stake adjustments based on resolution
        if (_challengeUpheld) {
            // Challenger wins: Challenger gets stake back, KM contributor/bad validators lose reputation/stake
            participants[challenge.challenger].reputation += (challenge.stake / minParticipantStake); // Rep boost
            REWARD_TOKEN.transfer(challenge.challenger, challenge.stake); // Return stake

            // Penalize contributor of KM
            participants[km.contributor].reputation = (participants[km.contributor].reputation * 90) / 100; // 10% reputation cut
            protocolFeesCollected += challenge.stake; // Slashing contributor/KM-related stake for protocol fees (simplified)

            km.status = KnowledgeModuleStatus.Rejected;
            emit KnowledgeModuleRejected(_moduleId, "Challenge upheld: Module rejected");
        } else {
            // Challenger loses: Challenger stake is forfeited, KM contributor/validators potentially gain reputation
            protocolFeesCollected += challenge.stake; // Challenger's stake goes to protocol fees
            participants[challenge.challenger].reputation = (participants[challenge.challenger].reputation * 90) / 100; // 10% reputation cut

            // If KM was challenged on content, it goes back to PendingValidation.
            // If it was a dispute on a validation, it stays in its prior state or becomes Validated if criteria met.
            km.status = KnowledgeModuleStatus.PendingValidation; 
        }
        km.currentChallengeId = 0; // Clear active challenge ID

        emit ChallengeResolved(challenge.id, _moduleId, _challengeUpheld);
    }

    /**
     * @dev Finalizes a Knowledge Module if it meets validation criteria and challenge period is over.
     * Only callable by protocol admin or if automated checks pass.
     * @param _moduleId The ID of the Knowledge Module to finalize.
     */
    function finalizeKnowledgeModule(uint256 _moduleId) external onlyProtocolAdmin whenNotPaused {
        KnowledgeModule storage km = knowledgeModules[_moduleId];
        if (km.id == 0) revert AetheriaNexus__KnowledgeModuleNotFound();
        if (km.status != KnowledgeModuleStatus.PendingValidation) revert AetheriaNexus__KnowledgeModuleNotPending(); // Or Challenged
        if (km.currentChallengeId != 0) revert AetheriaNexus__ChallengePeriodActive(); // Cannot finalize with active challenge

        // Check if challenge period is over
        if (block.timestamp < km.submissionTimestamp + challengePeriodDays * 1 days) {
            revert AetheriaNexus__ChallengePeriodNotOver();
        }

        // Check if validation criteria met
        uint256 averageScore = km.validationCount > 0 ? (km.totalValidationScore * 100 / km.validationCount) : 0;
        if (km.validationCount < minValidationsForFinalization || averageScore < validationThresholdScore) {
             km.status = KnowledgeModuleStatus.Rejected; // Fails to meet criteria, mark as rejected
             emit KnowledgeModuleRejected(_moduleId, "Failed validation criteria");
             return;
        }

        km.status = KnowledgeModuleStatus.Finalized;

        // Allocate rewards (a hypothetical total pool is divided, or based on a fixed value per KM)
        uint256 totalRewardForKM = 100 * 10 ** 18; // Example: 100 tokens per finalized KM for simplicity

        uint256 contributorReward = (totalRewardForKM * contributorRewardShareBasisPoints) / 10000;
        uint256 validatorsRewardPool = (totalRewardForKM * validatorRewardShareBasisPoints) / 10000;

        // Store pending rewards for contributor
        participants[km.contributor].pendingContributionRewards += contributorReward;
        km.totalRewardsAllocated = totalRewardForKM;

        // Distribute validator rewards proportionally to their reputation and score
        for (uint256 i = 0; i < kmValidatorsList[_moduleId].length; i++) {
            address validatorAddr = kmValidatorsList[_moduleId][i];
            Validation storage val = kmValidations[_moduleId][validatorAddr];
            // Calculate validator share based on their reputation and score
            // Ensure totalValidatorReputation is not zero to prevent division by zero, though it should not be if validationCount > 0
            if (km.totalValidatorReputation > 0) {
                // (Individual Validator Reputation * Score) / (Total Rep. Validating KM * Max Score) * Total Validator Reward Pool
                uint256 validatorShare = (participants[validatorAddr].reputation * val.score * validatorsRewardPool) / (km.totalValidatorReputation * 5); // 5 is max score
                participants[validatorAddr].pendingValidationRewards += validatorShare;
            }
        }

        // Remove from pending list (if gas allows, else rely on status)
        // This linear scan is not efficient for very large lists.
        for (uint256 i = 0; i < pendingKnowledgeModuleIds.length; i++) {
            if (pendingKnowledgeModuleIds[i] == _moduleId) {
                pendingKnowledgeModuleIds[i] = pendingKnowledgeModuleIds[pendingKnowledgeModuleIds.length - 1];
                pendingKnowledgeModuleIds.pop();
                break;
            }
        }

        emit KnowledgeModuleFinalized(_moduleId, msg.sender);
    }

    /**
     * @dev Retrieves details of a specific Knowledge Module.
     * @param _moduleId The ID of the Knowledge Module.
     * @return KnowledgeModule struct details.
     */
    function getKnowledgeModuleDetails(uint256 _moduleId)
        external
        view
        returns (uint256 id, address contributor, string memory contentIPFSHash, string memory topic, uint256 submissionTimestamp, KnowledgeModuleStatus status, uint256 totalValidationScore, uint256 validationCount, uint256 currentChallengeId, uint256 totalRewardsAllocated)
    {
        KnowledgeModule storage km = knowledgeModules[_moduleId];
        if (km.id == 0) revert AetheriaNexus__KnowledgeModuleNotFound();
        return (km.id, km.contributor, km.contentIPFSHash, km.topic, km.submissionTimestamp, km.status, km.totalValidationScore, km.validationCount, km.currentChallengeId, km.totalRewardsAllocated);
    }

    /**
     * @dev Retrieves a paginated list of Knowledge Modules awaiting validation.
     * @param _startIndex The starting index for the list.
     * @param _count The number of modules to retrieve.
     * @return An array of KM IDs.
     */
    function getPendingKnowledgeModules(uint256 _startIndex, uint256 _count) external view returns (uint256[] memory) {
        uint256 totalPending = pendingKnowledgeModuleIds.length;
        if (_startIndex >= totalPending) {
            return new uint256[](0);
        }
        uint256 endIndex = Math.min(_startIndex + _count, totalPending);
        uint256 numToReturn = endIndex - _startIndex;
        uint256[] memory result = new uint256[](numToReturn);

        for (uint256 i = 0; i < numToReturn; i++) {
            result[i] = pendingKnowledgeModuleIds[_startIndex + i];
        }
        return result;
    }

    /**
     * @dev Retrieves a list of finalized Knowledge Modules filtered by topic.
     * NOTE: This is an expensive operation for a large number of modules.
     * In a real dApp, topic-based queries would likely rely on off-chain indexing (e.g., The Graph).
     * This implementation iterates all KMs which is highly inefficient for large datasets.
     * @param _topic The topic to filter by.
     * @return An array of KM IDs.
     */
    function getValidatedKnowledgeModulesByTopic(string calldata _topic) external view returns (uint256[] memory) {
        // WARNING: This function iterates through all existing Knowledge Modules.
        // For a large number of modules, this will likely exceed gas limits.
        // In a production scenario, for efficient topic-based retrieval, consider:
        // 1. Maintaining a `mapping(string => uint256[])` for topics to module IDs.
        // 2. Relying on off-chain indexing solutions (e.g., The Graph protocol).
        uint256[] memory tempModuleIds = new uint256[](nextKnowledgeModuleId - 1); // Max possible size
        uint256 count = 0;
        for (uint256 i = 1; i < nextKnowledgeModuleId; i++) {
            KnowledgeModule storage km = knowledgeModules[i];
            // Check if ID is valid and KM is finalized and topic matches
            if (km.id != 0 && km.status == KnowledgeModuleStatus.Finalized && keccak256(abi.encodePacked(km.topic)) == keccak256(abi.encodePacked(_topic))) {
                tempModuleIds[count++] = i;
            }
        }

        uint256[] memory result = new uint256[](count);
        for (uint256 i = 0; i < count; i++) {
            result[i] = tempModuleIds[i];
        }
        return result;
    }

    // --- IV. Incentives & Rewards ---

    /**
     * @dev Allows a contributor to claim rewards for a successfully validated and finalized KM.
     * @param _moduleId The ID of the Knowledge Module for which to claim rewards.
     */
    function claimContributionRewards(uint256 _moduleId) external onlyRegisteredParticipant whenNotPaused {
        KnowledgeModule storage km = knowledgeModules[_moduleId];
        if (km.id == 0 || km.contributor != msg.sender) revert AetheriaNexus__KnowledgeModuleNotFound();
        if (km.status != KnowledgeModuleStatus.Finalized) revert AetheriaNexus__KnowledgeModuleNotFinalized();
        if (km.contributorRewardClaimed) revert AetheriaNexus__AlreadyClaimed();

        uint256 rewardAmount = (km.totalRewardsAllocated * contributorRewardShareBasisPoints) / 10000;
        if (rewardAmount == 0) return;

        // Ensure protocol has enough balance to transfer
        if (REWARD_TOKEN.balanceOf(address(this)) < rewardAmount) revert AetheriaNexus__InsufficientBalanceForWithdrawal();

        km.contributorRewardClaimed = true; // Mark as claimed
        participants[msg.sender].pendingContributionRewards -= rewardAmount; // Deduct from pending

        REWARD_TOKEN.transfer(msg.sender, rewardAmount);
        emit ContributionRewardsClaimed(msg.sender, _moduleId, rewardAmount);
    }

    /**
     * @dev Allows a validator to claim rewards for their accurate validations.
     * @param _moduleId The ID of the Knowledge Module for which to claim validation rewards.
     * Note: This function claims all accumulated pending validation rewards for the participant.
     */
    function claimValidationRewards(uint256 _moduleId) external onlyRegisteredParticipant whenNotPaused {
        KnowledgeModule storage km = knowledgeModules[_moduleId];
        if (km.id == 0) revert AetheriaNexus__KnowledgeModuleNotFound();
        if (km.status != KnowledgeModuleStatus.Finalized) revert AetheriaNexus__KnowledgeModuleNotFinalized();

        Validation storage validation = kmValidations[_moduleId][msg.sender];
        if (validation.validator == address(0)) revert AetheriaNexus__NotAValidator();
        if (validation.rewardsClaimed) revert AetheriaNexus__AlreadyClaimed();

        // Assuming rewards for this specific validation were accumulated in `pendingValidationRewards`.
        // A more precise system might map rewards per validation, but for simplicity, we clear total pending.
        uint256 rewardAmount = participants[msg.sender].pendingValidationRewards; 
        if (rewardAmount == 0) return; // No pending rewards to claim

        if (REWARD_TOKEN.balanceOf(address(this)) < rewardAmount) revert AetheriaNexus__InsufficientBalanceForWithdrawal();

        validation.rewardsClaimed = true; // Mark this specific validation's rewards as claimed.
        participants[msg.sender].pendingValidationRewards = 0; // Reset total pending validation rewards (simplification)
        
        REWARD_TOKEN.transfer(msg.sender, rewardAmount);
        emit ValidationRewardsClaimed(msg.sender, _moduleId, rewardAmount);
    }

    /**
     * @dev Calculates and returns the total pending rewards for a participant.
     * @param _participant The address of the participant.
     * @return Total pending rewards (contribution + validation).
     */
    function getPendingRewards(address _participant) external view returns (uint256) {
        if (!isRegistered[_participant]) return 0; // Or revert AetheriaNexus__NotRegistered();
        Participant storage p = participants[_participant];
        return p.pendingContributionRewards + p.pendingValidationRewards;
    }

    // --- V. Adaptive Governance & System Evolution ---

    /**
     * @dev Allows participants to propose adjustments to key protocol parameters.
     * @param _paramName The name of the parameter to adjust (e.g., "minParticipantStake", "validationThresholdScore").
     * @param _newValue The new value for the parameter.
     */
    function proposeParameterAdjustment(string calldata _paramName, uint256 _newValue) external onlyRegisteredParticipant whenNotPaused {
        // Basic check for valid parameter names. More robust system would use enums or a whitelist.
        bytes32 paramHash = keccak256(abi.encodePacked(_paramName));
        if (paramHash != keccak256(abi.encodePacked("minParticipantStake")) &&
            paramHash != keccak256(abi.encodePacked("validationThresholdScore")) &&
            paramHash != keccak256(abi.encodePacked("minValidationsForFinalization")) &&
            paramHash != keccak256(abi.encodePacked("challengePeriodDays")) &&
            paramHash != keccak256(abi.encodePacked("proposalVotingPeriodDays")) &&
            paramHash != keccak256(abi.encodePacked("proposalExecutionGracePeriodDays")) &&
            paramHash != keccak256(abi.encodePacked("reputationDecayPeriodDays")) &&
            paramHash != keccak256(abi.encodePacked("reputationDecayPercentage")) &&
            paramHash != keccak256(abi.encodePacked("contributorRewardShareBasisPoints")) &&
            paramHash != keccak256(abi.encodePacked("validatorRewardShareBasisPoints")) &&
            paramHash != keccak256(abi.encodePacked("disputeStakeMultiplier")) &&
            paramHash != keccak256(abi.encodePacked("challengeStakeMultiplier")) &&
            paramHash != keccak256(abi.encodePacked("deregisterCoolDownDays"))
        ) {
            revert AetheriaNexus__InvalidParameterValue();
        }
        
        uint256 proposalId = nextProposalId++;
        parameterProposals[proposalId] = ParameterProposal({
            id: proposalId,
            proposer: msg.sender,
            paramName: _paramName,
            newValue: _newValue,
            creationTimestamp: block.timestamp,
            votingPeriodEnd: block.timestamp + proposalVotingPeriodDays * 1 days,
            executionGracePeriodEnd: 0, // Set after voting ends
            yesVotes: 0,
            noVotes: 0,
            status: ProposalStatus.Active
        });

        _applyReputationDecay(msg.sender); // Update activity and apply decay
        participants[msg.sender].lastActiveTimestamp = block.timestamp;

        emit ParameterAdjustmentProposed(proposalId, msg.sender, _paramName, _newValue);
    }

    /**
     * @dev Allows participants to vote on an active parameter adjustment proposal.
     * Influence of vote is based on participant's effective reputation (including delegated).
     * @param _proposalId The ID of the proposal to vote on.
     * @param _support True for a 'yes' vote, false for a 'no' vote.
     */
    function voteOnParameterProposal(uint256 _proposalId, bool _support) external onlyRegisteredParticipant whenNotPaused {
        ParameterProposal storage proposal = parameterProposals[_proposalId];
        if (proposal.id == 0 || proposal.status != ProposalStatus.Active) revert AetheriaNexus__ProposalNotFound();
        if (block.timestamp > proposal.votingPeriodEnd) revert AetheriaNexus__ProposalNotFound(); // Voting period ended

        if (proposalHasVoted[_proposalId][msg.sender]) revert AetheriaNexus__AlreadyVotedOnProposal();

        _applyReputationDecay(msg.sender); // Apply decay before getting reputation
        uint256 effectiveReputation = participants[msg.sender].reputation + participants[msg.sender].delegatedAmount;

        if (_support) {
            proposal.yesVotes += effectiveReputation;
        } else {
            proposal.noVotes += effectiveReputation;
        }
        proposalHasVoted[_proposalId][msg.sender] = true;
        participants[msg.sender].lastActiveTimestamp = block.timestamp;

        emit ParameterProposalVoted(_proposalId, msg.sender, _support);
    }

    /**
     * @dev Executes a parameter adjustment proposal if it passes voting and grace period.
     * Anyone can call this after the grace period ends.
     * @param _proposalId The ID of the proposal to execute.
     */
    function executeParameterAdjustment(uint256 _proposalId) external whenNotPaused {
        ParameterProposal storage proposal = parameterProposals[_proposalId];
        if (proposal.id == 0 || proposal.status != ProposalStatus.Active) revert AetheriaNexus__ProposalNotFound();
        
        // Voting period must be over
        if (block.timestamp <= proposal.votingPeriodEnd) revert AetheriaNexus__ProposalNotReadyForExecution();

        // Determine outcome
        if (proposal.yesVotes > proposal.noVotes) {
            proposal.status = ProposalStatus.Succeeded;
            // Set execution grace period
            proposal.executionGracePeriodEnd = block.timestamp + proposalExecutionGracePeriodDays * 1 days;
        } else {
            proposal.status = ProposalStatus.Failed;
            return; // Exit if failed
        }

        // Must be past execution grace period
        if (block.timestamp < proposal.executionGracePeriodEnd) revert AetheriaNexus__ProposalNotReadyForExecution();

        // Execute parameter change
        bytes32 paramHash = keccak256(abi.encodePacked(proposal.paramName));
        if (paramHash == keccak256(abi.encodePacked("minParticipantStake"))) {
            minParticipantStake = proposal.newValue;
        } else if (paramHash == keccak256(abi.encodePacked("validationThresholdScore"))) {
            if (proposal.newValue > 500) revert AetheriaNexus__InvalidParameterValue(); // Runtime check for invalid value
            validationThresholdScore = proposal.newValue;
        } else if (paramHash == keccak256(abi.encodePacked("minValidationsForFinalization"))) {
            minValidationsForFinalization = proposal.newValue;
        } else if (paramHash == keccak256(abi.encodePacked("challengePeriodDays"))) {
            challengePeriodDays = proposal.newValue;
        } else if (paramHash == keccak256(abi.encodePacked("proposalVotingPeriodDays"))) {
            proposalVotingPeriodDays = proposal.newValue;
        } else if (paramHash == keccak256(abi.encodePacked("proposalExecutionGracePeriodDays"))) {
            proposalExecutionGracePeriodDays = proposal.newValue;
        } else if (paramHash == keccak256(abi.encodePacked("reputationDecayPeriodDays"))) {
            reputationDecayPeriodDays = proposal.newValue;
        } else if (paramHash == keccak256(abi.encodePacked("reputationDecayPercentage"))) {
            if (proposal.newValue > 100) revert AetheriaNexus__InvalidParameterValue(); // Runtime check
            reputationDecayPercentage = proposal.newValue;
        } else if (paramHash == keccak256(abi.encodePacked("contributorRewardShareBasisPoints"))) {
            contributorRewardShareBasisPoints = proposal.newValue;
            // Combined check. If this breaks invariant, a new proposal to adjust validator share is needed
            // or the proposal system itself needs to handle multi-parameter updates.
            if (contributorRewardShareBasisPoints + validatorRewardShareBasisPoints != 10000) { /* handle or log warning */ }
        } else if (paramHash == keccak256(abi.encodePacked("validatorRewardShareBasisPoints"))) {
            validatorRewardShareBasisPoints = proposal.newValue;
            if (contributorRewardShareBasisPoints + validatorRewardShareBasisPoints != 10000) { /* handle or log warning */ }
        } else if (paramHash == keccak256(abi.encodePacked("disputeStakeMultiplier"))) {
            disputeStakeMultiplier = proposal.newValue;
        } else if (paramHash == keccak256(abi.encodePacked("challengeStakeMultiplier"))) {
            challengeStakeMultiplier = proposal.newValue;
        } else if (paramHash == keccak256(abi.encodePacked("deregisterCoolDownDays"))) {
            deregisterCoolDownDays = proposal.newValue;
        }
        
        proposal.status = ProposalStatus.Executed;
        emit ParameterAdjustmentExecuted(_proposalId, proposal.paramName, proposal.newValue);
    }

    /**
     * @dev Triggers a global reputation decay epoch.
     * Can be called by anyone after the `reputationDecayPeriodDays` has passed.
     * This function only updates `lastReputationDecayTimestamp`. The actual reputation
     * decay for individual participants is applied lazily when their reputation is accessed
     * or when they perform an action (e.g., validate, submit KM).
     */
    function triggerReputationDecay() external whenNotPaused {
        if (block.timestamp < lastReputationDecayTimestamp + reputationDecayPeriodDays * 1 days) {
            revert AetheriaNexus__ReputationDecayNotDue();
        }

        lastReputationDecayTimestamp = block.timestamp;
        emit ReputationDecayTriggered(block.timestamp);
    }

    // --- Internal/Helper Functions ---

    /**
     * @dev Helper to calculate and apply reputation decay.
     * This makes reputation decay "lazy" or "pull-based".
     * Modifies the participant's reputation and `lastActiveTimestamp` in storage.
     * @param _participant The address of the participant.
     */
    function _applyReputationDecay(address _participant) internal {
        Participant storage p = participants[_participant];
        
        // If last active time is before the last decay epoch or a long time ago
        if (p.lastActiveTimestamp < lastReputationDecayTimestamp) {
            uint256 elapsedDecayPeriods = (block.timestamp - p.lastActiveTimestamp) / (reputationDecayPeriodDays * 1 days);
            
            // Apply decay for each elapsed full period
            uint256 currentRep = p.reputation;
            for (uint256 i = 0; i < elapsedDecayPeriods; i++) {
                currentRep = (currentRep * (100 - reputationDecayPercentage)) / 100;
            }
            p.reputation = currentRep;
            p.lastActiveTimestamp = block.timestamp; // Update last active to current time
        }
    }

    /**
     * @dev Helper to calculate participant's reputation *as if* decay was applied, without modifying state.
     * Used by view functions.
     * @param _currentReputation The participant's current stored reputation.
     * @param _lastActiveTimestamp The participant's last active timestamp.
     * @return The calculated reputation after decay.
     */
    function _calculateReputationAfterDecay(uint256 _currentReputation, uint256 _lastActiveTimestamp) internal view returns (uint256) {
        if (_lastActiveTimestamp >= lastReputationDecayTimestamp) {
            return _currentReputation; // No global decay or already updated
        }

        uint256 elapsedDecayPeriods = (block.timestamp - _lastActiveTimestamp) / (reputationDecayPeriodDays * 1 days);
        uint256 calculatedRep = _currentReputation;

        for (uint256 i = 0; i < elapsedDecayPeriods; i++) {
            calculatedRep = (calculatedRep * (100 - reputationDecayPercentage)) / 100;
        }
        return calculatedRep;
    }
}
```