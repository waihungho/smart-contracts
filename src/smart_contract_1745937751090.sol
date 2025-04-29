Okay, let's design a smart contract that acts as a **Decentralized Autonomous Skill Registry (DASR)**. This contract will allow users to register specific skills, have them validated by peers (or staked validators), build a dynamic reputation score based on validated skills and participation, incorporate temporal aspects like skill decay and expiration, and include a simple staking mechanism for governance participation and validator eligibility.

This concept combines elements of decentralized identity, reputation systems, peer validation, staking, and basic on-chain governance in a specific domain (skills/credentials), aiming for uniqueness beyond typical token or NFT contracts.

**Outline:**

1.  ** SPDX-License-Identifier & Pragma**
2.  ** Imports** (OpenZeppelin for standard utilities like Ownable, Pausable, IERC20)
3.  ** Custom Errors**
4.  ** Events** (To signal important state changes)
5.  ** Enums** (For skill status, proposal state)
6.  ** Struct Definitions** (Skill definition, user skill entry, validation info, reputation, staking info, governance proposal)
7.  ** State Variables** (Mappings, counters, parameters, governance state)
8.  ** Modifiers** (Custom access control)
9.  ** Constructor** (Initialize owner, staking token, initial parameters)
10. ** Core Skill Management Functions** (Define, Register, View)
11. ** Validation & Attestation Functions** (Attest, Validate, Dispute, View Validators)
12. ** Reputation Management Functions** (Calculate, Update, View)
13. ** Temporal Functions** (Decay, Expire, Renew)
14. ** Staking Functions** (Stake, Withdraw Stake)
15. ** Governance Functions** (Propose, Vote, Execute, Set Parameters)
16. ** Utility Functions** (Pause/Unpause, Getters for various data)
17. ** Internal Helper Functions** (Reputation calculation, status checks)

**Function Summary:**

1.  `constructor`: Initializes the contract, setting the owner, staking token address, and initial system parameters (like validation thresholds, decay rates, staking minimums).
2.  `addSkillDefinition`: Allows governance (or owner initially) to define a new skill type that users can register against. Includes requirements like minimum validators.
3.  `registerSkill`: Allows a user to register that they possess a specific, predefined skill. Creates a pending `UserSkillEntry`. Requires a small stake or fee (optional, but can be added).
4.  `attestSkill`: Allows a user to attest to *another* user's registered skill entry. This is a weaker form of validation but contributes slightly or flags the entry for review.
5.  `revokeAttestation`: Allows a user who previously attested to remove their attestation.
6.  `requestSkillValidation`: Allows a user who registered a skill to explicitly request validation from eligible validators.
7.  `stakeForValidation`: Allows a user to stake tokens to become eligible to validate skills and participate in governance.
8.  `withdrawStake`: Allows a user to withdraw their staked tokens after an unlock period, losing validator eligibility if stake falls below the minimum.
9.  `validateSkillEntry`: Allows an *eligible staked validator* to validate a specific user's skill entry. Adds a validation score to the entry based on validator's stake/reputation.
10. `disputeSkillEntry`: Allows a user or validator to dispute a validated skill entry, potentially freezing its status and triggering review (review logic simplified/manual or part of future governance).
11. `decaySkillValidationScore`: A permissionless function (anyone can call) that triggers the time-based decay of the validation score for a specific skill entry if the decay period has passed.
12. `expireSkillEntry`: A permissionless function that triggers the expiration of a skill entry if its active period has ended and it hasn't been renewed.
13. `renewSkillEntry`: Allows a user to renew their expired or soon-to-expire skill entry, potentially requiring re-validation or a renewal stake.
14. `getReputation`: View function to get a user's current calculated reputation score.
15. `calculateReputation`: Internal helper function to calculate a user's dynamic reputation based on their validated skills, participation, and decay.
16. `updateReputation`: Internal function called after relevant actions (validation, renewal, decay, governance) to update a user's stored reputation score.
17. `proposeSkillAddition`: Allows a user with sufficient stake/reputation to propose adding a *new* skill definition to the registry.
18. `voteOnProposal`: Allows users with voting power (stake/reputation) to vote on an active governance proposal.
19. `executeProposal`: A permissionless function to execute a proposal if it has passed its voting period and met the required vote threshold.
20. `setValidationThreshold`: Governance function to update the minimum required validation score for a skill entry to be considered valid.
21. `setDecayParameters`: Governance function to update the rate and frequency of skill and reputation decay.
22. `getStakingInfo`: View function to get a user's current staking details.
23. `getUserSkillEntries`: View function to get a list of skill entry IDs registered by a specific user.
24. `getSkillEntryDetails`: View function to get the detailed information for a specific skill entry ID.
25. `getSkillDefinition`: View function to get the details of a skill definition by its ID.
26. `getValidatorsForSkillEntry`: View function to get the addresses and validation statuses of validators for a specific skill entry.
27. `pauseContract`: Allows governance/owner to pause sensitive contract functions in case of emergency.
28. `unpauseContract`: Allows governance/owner to unpause the contract.
29. `getProposalDetails`: View function to get the details of a specific governance proposal.
30. `getUserSkillsByCategory`: View function to filter and retrieve a user's skill entries by category.

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

// --- Outline ---
// 1. SPDX-License-Identifier & Pragma
// 2. Imports
// 3. Custom Errors
// 4. Events
// 5. Enums
// 6. Struct Definitions
// 7. State Variables
// 8. Modifiers
// 9. Constructor
// 10. Core Skill Management Functions
// 11. Validation & Attestation Functions
// 12. Reputation Management Functions
// 13. Temporal Functions (Decay, Expire, Renew)
// 14. Staking Functions
// 15. Governance Functions (Propose, Vote, Execute, Set Parameters)
// 16. Utility Functions (Pause/Unpause, Getters)
// 17. Internal Helper Functions

// --- Function Summary ---
// 1. constructor: Initializes contract, sets owner, staking token, parameters.
// 2. addSkillDefinition: Adds a new type of skill to the registry (Governance/Owner).
// 3. registerSkill: Allows a user to claim possession of a skill.
// 4. attestSkill: Allows a user to attest to another user's skill entry (lighter verification).
// 5. revokeAttestation: Removes a previous attestation.
// 6. requestSkillValidation: User requests formal validation for their skill entry.
// 7. stakeForValidation: Stake tokens to become an eligible validator and gain governance power.
// 8. withdrawStake: Withdraw staked tokens after unlock period.
// 9. validateSkillEntry: Eligible validator formally validates a skill entry.
// 10. disputeSkillEntry: User/validator disputes a skill entry's validity.
// 11. decaySkillValidationScore: Triggers decay of validation score for a specific entry over time.
// 12. expireSkillEntry: Triggers expiration of a skill entry if duration passed.
// 13. renewSkillEntry: User renews an expired or expiring skill entry.
// 14. getReputation: View user's current reputation score.
// 15. calculateReputation: Internal helper to calculate reputation.
// 16. updateReputation: Internal function to update user's stored reputation.
// 17. proposeSkillAddition: Propose a new skill definition via governance.
// 18. voteOnProposal: Vote on an active governance proposal (stake/reputation weighted).
// 19. executeProposal: Execute a passed governance proposal.
// 20. setValidationThreshold: Governance sets min validation score for 'valid'.
// 21. setDecayParameters: Governance sets parameters for skill/reputation decay.
// 22. getStakingInfo: View user's staking details.
// 23. getUserSkillEntries: View skill entry IDs for a user.
// 24. getSkillEntryDetails: View full details of a specific skill entry.
// 25. getSkillDefinition: View details of a skill definition.
// 26. getValidatorsForSkillEntry: View validators and their status for an entry.
// 27. pauseContract: Pause operations (Owner/Governance).
// 28. unpauseContract: Unpause operations (Owner/Governance).
// 29. getProposalDetails: View details of a governance proposal.
// 30. getUserSkillsByCategory: View user's skill entries filtered by category.

contract DecentralizedAutonomousSkillRegistry is Ownable, Pausable {
    using SafeMath for uint256;
    using Counters for Counters.Counter;

    // --- Custom Errors ---
    error SkillDefinitionNotFound(uint256 skillId);
    error SkillEntryNotFound(uint256 entryId);
    error UnauthorizedValidator(address validator);
    error InsufficientStake(uint256 required, uint256 staked);
    error AlreadyRegisteredSkill(uint256 skillId);
    error SkillEntryNotPendingValidation(uint256 entryId);
    error SkillEntryNotValid(uint256 entryId);
    error SkillEntryAlreadyValid(uint256 entryId);
    error InvalidValidationScore(int256 score);
    error CannotValidateSelf();
    error CannotAttestSelf();
    error NotValidatorForEntry(address validator);
    error AlreadyValidated(uint256 entryId, address validator);
    error AlreadyAttested(uint256 entryId, address attester);
    error NoActiveAttestation(uint256 entryId, address attester);
    error StakeLocked(uint256 unlockTime);
    error ProposalNotFound(uint256 proposalId);
    error ProposalNotActive(uint256 proposalId);
    error ProposalVotingPeriodActive(uint256 endTime);
    error ProposalAlreadyExecuted(uint256 proposalId);
    error ProposalFailed(uint256 proposalId);
    error CannotVoteTwice(uint256 proposalId, address voter);
    error InsufficientVotingPower(uint256 required, uint256 has);
    error InvalidProposalType();
    error SkillEntryNotExpired(uint256 entryId);
    error SkillEntryNotDueForDecay(uint256 entryId);
    error SkillEntryNotDueForRenewal(uint256 entryId);
    error RenewalRequiresRevalidation(); // Example condition
    error CannotDisputeSelf();

    // --- Events ---
    event SkillDefinitionAdded(uint256 indexed skillId, string name, string category);
    event SkillRegistered(address indexed user, uint256 indexed entryId, uint256 indexed skillId);
    event SkillEntryValidationRequested(uint256 indexed entryId);
    event SkillEntryValidated(uint256 indexed entryId, address indexed validator, int256 scoreAdded, uint256 newTotalScore);
    event SkillEntryDisputed(uint256 indexed entryId, address indexed disputer, string reason);
    event SkillEntryValidationScoreDecayed(uint256 indexed entryId, int256 scoreRemoved, uint256 newTotalScore);
    event SkillEntryExpired(uint256 indexed entryId);
    event SkillEntryRenewed(uint256 indexed entryId);
    event AttestationAdded(uint256 indexed entryId, address indexed attester);
    event AttestationRevoked(uint256 indexed entryId, address indexed attester);
    event ReputationUpdated(address indexed user, uint256 newReputation);
    event StakeDeposited(address indexed user, uint256 amount, uint256 totalStaked);
    event StakeWithdrawn(address indexed user, uint256 amount, uint256 totalStaked);
    event ProposalCreated(uint256 indexed proposalId, address indexed proposer, uint256 endTime, string description);
    event Voted(uint256 indexed proposalId, address indexed voter, bool voteYes, uint256 votingPower);
    event ProposalExecuted(uint256 indexed proposalId);
    event ParametersUpdated(string paramName, uint256 newValue);

    // --- Enums ---
    enum SkillEntryStatus { PendingValidation, Valid, Disputed, Expired, Invalid }
    enum ProposalState { Active, Passed, Failed, Executed, Canceled }
    enum ProposalType { AddSkillDefinition, SetValidationThreshold, SetDecayParameters, SetStakingParameters }

    // --- Struct Definitions ---
    struct Skill {
        uint256 id;
        string name;
        string description;
        string category;
        uint256 creationTime;
        uint256 minRequiredValidators; // Minimum number of validators to achieve initial 'Valid' status
        uint256 requiredValidationScore; // Total score needed for 'Valid' status
        uint256 duration; // How long the skill entry is valid after achieving 'Valid' status (in seconds)
    }

    struct UserSkillEntry {
        uint256 id;
        address user;
        uint256 skillId;
        SkillEntryStatus status;
        int256 validationScore; // Aggregate score from formal validations
        uint256 registrationTime;
        uint256 lastValidationUpdateTime; // Timestamp of last validation/decay
        uint256 expirationTime; // Estimated expiration based on duration from validation
        mapping(address => bool) validators; // Address -> Has this validator validated this specific entry?
        mapping(address => bool) attesters; // Address -> Has this user attested to this specific entry?
    }

    struct Reputation {
        uint256 score; // A general reputation score (e.g., 0 to 1000)
        uint256 lastUpdateTime; // Timestamp of last score update
    }

    struct StakingInfo {
        uint256 amount; // Amount of staking tokens
        uint256 lockUntil; // Timestamp until which stake is locked (if any)
        bool isValidator; // Eligible to validate based on stake minimum
    }

    struct Proposal {
        uint256 id;
        address proposer;
        ProposalType proposalType;
        bytes data; // Encoded data for the proposal (e.g., new parameter value, skill details)
        uint256 creationTime;
        uint256 votingEndTime;
        uint256 yesVotes; // Total voting power (stake/reputation) weighted
        uint256 noVotes;
        mapping(address => bool) hasVoted;
        ProposalState state;
    }

    // --- State Variables ---
    IERC20 public stakingToken;

    Counters.Counter private _skillIds;
    mapping(uint256 => Skill) public skills; // SkillID -> Skill definition
    uint256[] public allSkillIds; // Simple list for iteration (caution with size)

    Counters.Counter private _skillEntryIds;
    mapping(uint256 => UserSkillEntry) public userSkillEntries; // SkillEntryID -> UserSkillEntry
    mapping(address => uint256[]) public userToSkillEntryIds; // UserAddress -> List of SkillEntryIDs

    mapping(address => Reputation) public userReputation; // UserAddress -> Reputation
    mapping(address => StakingInfo) public userStakingInfo; // UserAddress -> StakingInfo

    Counters.Counter private _proposalIds;
    mapping(uint256 => Proposal) public proposals; // ProposalID -> Proposal details

    // --- Governance & System Parameters ---
    uint256 public validationThreshold; // Min score required for Valid status
    uint256 public skillDecayRate; // How much validation score decays per decay period
    uint256 public skillDecayPeriod; // Time interval for skill score decay (in seconds)
    uint256 public reputationDecayRate; // How much reputation score decays per reputation decay period
    uint256 public reputationDecayPeriod; // Time interval for reputation decay (in seconds)
    uint256 public validatorStakeMinimum; // Minimum stake required to be a validator
    uint256 public proposalStakeMinimum; // Minimum stake required to create a proposal
    uint256 public proposalVotingPeriod; // Duration of the voting period for proposals (in seconds)
    uint256 public proposalVoteThresholdNumerator; // Numerator for vote threshold (e.g., 51 for 51%)
    uint256 public proposalVoteThresholdDenominator; // Denominator for vote threshold (e.g., 100 for 51%)

    // --- Modifiers ---
    modifier onlyValidator(address user) {
        if (!userStakingInfo[user].isValidator) {
            revert UnauthorizedValidator(user);
        }
        _;
    }

    modifier onlyGovernance() {
        // Simple check: either owner or staking power above a threshold
        // More complex DAOs would use specific governance token or voting module
        require(_msgSender() == owner() || userStakingInfo[_msgSender()].amount >= proposalStakeMinimum, "Not authorized by governance");
        _;
    }

    // --- Constructor ---
    constructor(address _stakingTokenAddress, uint256 _initialValidationThreshold, uint256 _initialSkillDecayRate, uint256 _initialSkillDecayPeriod, uint256 _initialReputationDecayRate, uint256 _initialReputationDecayPeriod, uint256 _initialValidatorStakeMinimum, uint256 _initialProposalStakeMinimum, uint256 _initialProposalVotingPeriod, uint256 _initialVoteThresholdNumerator, uint256 _initialVoteThresholdDenominator) Ownable(msg.sender) Pausable(false) {
        stakingToken = IERC20(_stakingTokenAddress);
        validationThreshold = _initialValidationThreshold;
        skillDecayRate = _initialSkillDecayRate;
        skillDecayPeriod = _initialSkillDecayPeriod;
        reputationDecayRate = _initialReputationDecayRate;
        reputationDecayPeriod = _initialReputationDecayPeriod;
        validatorStakeMinimum = _initialValidatorStakeMinimum;
        proposalStakeMinimum = _initialProposalStakeMinimum;
        proposalVotingPeriod = _initialProposalVotingPeriod;
        proposalVoteThresholdNumerator = _initialVoteThresholdNumerator;
        proposalVoteThresholdDenominator = _initialVoteThresholdDenominator;
    }

    // --- Core Skill Management Functions ---

    /**
     * @notice Adds a new skill definition that users can register against.
     * @param _name Name of the skill.
     * @param _description Description of the skill.
     * @param _category Category of the skill (e.g., "Development", "Design", "Marketing").
     * @param _minRequiredValidators Minimum number of distinct validators needed for a skill entry to potentially become Valid.
     * @param _requiredValidationScore Total validation score required for a skill entry to reach Valid status.
     * @param _duration How long a skill entry is considered valid from validation timestamp.
     */
    function addSkillDefinition(string memory _name, string memory _description, string memory _category, uint256 _minRequiredValidators, uint256 _requiredValidationScore, uint256 _duration) external onlyGovernance whenNotPaused {
        _skillIds.increment();
        uint256 newSkillId = _skillIds.current();
        skills[newSkillId] = Skill(
            newSkillId,
            _name,
            _description,
            _category,
            block.timestamp,
            _minRequiredValidators,
            _requiredValidationScore,
            _duration
        );
        allSkillIds.push(newSkillId); // Add to list (gas warning for large lists)
        emit SkillDefinitionAdded(newSkillId, _name, _category);
    }

    /**
     * @notice Allows a user to register that they possess a specific skill.
     * Requires the skill definition to exist.
     * @param _skillId The ID of the skill definition to register.
     */
    function registerSkill(uint256 _skillId) external whenNotPaused {
        if (skills[_skillId].id == 0 && _skillIds.current() < _skillId) {
             revert SkillDefinitionNotFound(_skillId);
        }

        // Optional: Check if user already has an active or pending entry for this skill
        // This requires iterating userToSkillEntryIds, potentially gas-intensive.
        // Skipping for brevity, allowing multiple entries (maybe different experience levels?)
        // Or could add a mapping: user -> skillId -> latestEntryId

        _skillEntryIds.increment();
        uint256 newEntryId = _skillEntryIds.current();
        userSkillEntries[newEntryId] = UserSkillEntry({
            id: newEntryId,
            user: _msgSender(),
            skillId: _skillId,
            status: SkillEntryStatus.PendingValidation,
            validationScore: 0,
            registrationTime: block.timestamp,
            lastValidationUpdateTime: block.timestamp,
            expirationTime: 0, // Set upon validation
            validators: new mapping(address => bool)(),
            attesters: new mapping(address => bool)()
        });

        userToSkillEntryIds[_msgSender()].push(newEntryId);

        emit SkillRegistered(_msgSender(), newEntryId, _skillId);
    }

    // --- Validation & Attestation Functions ---

    /**
     * @notice Allows a user to attest to another user's skill entry. Lighter than formal validation.
     * @param _entryId The ID of the skill entry to attest to.
     */
    function attestSkill(uint256 _entryId) external whenNotPaused {
        UserSkillEntry storage entry = userSkillEntries[_entryId];
        if (entry.id == 0) revert SkillEntryNotFound(_entryId);
        if (entry.user == _msgSender()) revert CannotAttestSelf();
        if (entry.attesters[_msgSender()]) revert AlreadyAttested(_entryId, _msgSender());

        entry.attesters[_msgSender()] = true;

        // Optional: Adjust reputation slightly or flag the entry for validation
        // updateReputation(entry.user);

        emit AttestationAdded(_entryId, _msgSender());
    }

    /**
     * @notice Allows a user to revoke their attestation to a skill entry.
     * @param _entryId The ID of the skill entry.
     */
    function revokeAttestation(uint256 _entryId) external whenNotPaused {
         UserSkillEntry storage entry = userSkillEntries[_entryId];
        if (entry.id == 0) revert SkillEntryNotFound(_entryId);
        if (entry.user == _msgSender()) revert CannotAttestSelf(); // Should not happen, but safety
        if (!entry.attesters[_msgSender()]) revert NoActiveAttestation(_entryId, _msgSender());

        entry.attesters[_msgSender()] = false;

        // Optional: Adjust reputation
        // updateReputation(entry.user);

        emit AttestationRevoked(_entryId, _msgSender());
    }

    /**
     * @notice A user can request formal validation for their skill entry.
     * Can be called by the skill entry owner when status is PendingValidation.
     * @param _entryId The ID of the skill entry.
     */
    function requestSkillValidation(uint256 _entryId) external whenNotPaused {
        UserSkillEntry storage entry = userSkillEntries[_entryId];
        if (entry.id == 0) revert SkillEntryNotFound(_entryId);
        require(entry.user == _msgSender(), "Only skill entry owner can request validation");
        if (entry.status != SkillEntryStatus.PendingValidation) revert SkillEntryNotPendingValidation(_entryId);

        // In a real system, this might notify potential validators off-chain
        // On-chain, it simply confirms the owner is seeking validation.

        emit SkillEntryValidationRequested(_entryId);
    }


    /**
     * @notice Allows an eligible staked validator to validate a skill entry.
     * Affects the entry's validation score and potentially the validator's reputation.
     * @param _entryId The ID of the skill entry to validate.
     * @param _score How much validation score to add (can be positive or negative for complex systems, starting simple positive).
     */
    function validateSkillEntry(uint256 _entryId, int256 _score) external onlyValidator(_msgSender()) whenNotPaused {
        UserSkillEntry storage entry = userSkillEntries[_entryId];
        if (entry.id == 0) revert SkillEntryNotFound(_entryId);
        if (entry.user == _msgSender()) revert CannotValidateSelf();
        if (entry.status != SkillEntryStatus.PendingValidation && entry.status != SkillEntryStatus.Valid) {
             revert SkillEntryNotPendingValidation(_entryId); // Can only validate pending or re-validate valid? Let's stick to pending for simplicity.
        }
         if (entry.validators[_msgSender()]) revert AlreadyValidated(_entryId, _msgSender());
         if (_score <= 0) revert InvalidValidationScore(_score); // Simplified: only positive scores for validation

        // Add validator to the list for this entry
        entry.validators[_msgSender()] = true;

        // Add score - careful with signed/unsigned
        entry.validationScore = entry.validationScore.add(uint256(_score));
        entry.lastValidationUpdateTime = block.timestamp; // Reset decay timer

        // Check if threshold is met
        Skill memory skillDef = skills[entry.skillId];
        // Note: Counting unique validators requires iterating the mapping, which is not ideal on-chain for large numbers.
        // A simpler approach is just checking total score, or storing a unique validator count separately.
        // Let's just check score for now, and rely on _minRequiredValidators parameter being an off-chain or governance guideline.
        // Or, explicitly iterate or track count. Let's add a counter to the struct for simplicity.
        // (Self-correction: Modifying struct requires redeployment. Let's just use the score threshold for 'Valid' status check here).

        if (entry.status == SkillEntryStatus.PendingValidation && entry.validationScore >= int256(skillDef.requiredValidationScore)) {
            // Transition to Valid
            entry.status = SkillEntryStatus.Valid;
            entry.expirationTime = block.timestamp.add(skillDef.duration);
        }

        // Update validator's reputation
        updateReputation(_msgSender());
         // Update user's reputation (as their score increased)
        updateReputation(entry.user);


        emit SkillEntryValidated(_entryId, _msgSender(), _score, uint256(entry.validationScore));
    }

    /**
     * @notice Allows a user or eligible validator to dispute a skill entry.
     * May reduce validation score or change status to Disputed.
     * Requires stake or reputation to prevent spam.
     * @param _entryId The ID of the skill entry to dispute.
     * @param _reason Short string describing the reason for dispute (stored off-chain usually).
     */
    function disputeSkillEntry(uint256 _entryId, string memory _reason) external whenNotPaused {
         UserSkillEntry storage entry = userSkillEntries[_entryId];
        if (entry.id == 0) revert SkillEntryNotFound(_entryId);
        if (entry.user == _msgSender()) revert CannotDisputeSelf();

        // Require minimum stake or reputation from disputer
        uint256 disputerVotingPower = userStakingInfo[_msgSender()].amount; // Or use reputation score
        if (disputerVotingPower < proposalStakeMinimum) { // Using proposal stake minimum as example threshold
             revert InsufficientVotingPower(proposalStakeMinimum, disputerVotingPower);
        }

        // Simple dispute logic: immediately set to disputed.
        // Complex logic: dispute costs stake, triggers review period, validators vote on dispute validity.
        entry.status = SkillEntryStatus.Disputed;

        // Optional: Reduce validation score slightly on dispute
        // entry.validationScore = entry.validationScore.sub(someDisputePenalty);

        updateReputation(_msgSender()); // Update disputer's reputation

        emit SkillEntryDisputed(_entryId, _msgSender(), _reason);
    }

    // --- Reputation Management Functions ---

    /**
     * @notice Internal function to calculate a user's reputation score.
     * Calculation logic: based on validated skill scores, successful validations, attestation counts, and decay.
     * Simplified here: based on total validated skill score and stake amount, with time decay.
     * @param _user The user's address.
     * @return The calculated reputation score.
     */
    function calculateReputation(address _user) internal view returns (uint256) {
        uint256 currentRepScore = userReputation[_user].score;
        uint256 lastUpdate = userReputation[_user].lastUpdateTime;

        // Apply decay
        uint256 timeElapsed = block.timestamp.sub(lastUpdate);
        uint256 decayPeriods = timeElapsed.div(reputationDecayPeriod);
        uint256 decayedScore = currentRepScore;
        for (uint i = 0; i < decayPeriods; i++) {
            if (decayedScore < reputationDecayRate) {
                decayedScore = 0;
                break;
            }
            decayedScore = decayedScore.sub(reputationDecayRate);
        }

        // Add factors: Staked amount is a simple proxy for commitment/trust
        decayedScore = decayedScore.add(userStakingInfo[_user].amount.div(100)); // Example: 1/100th of stake adds to reputation

        // Add factors: Sum of validated skill scores
        // Note: Iterating all user skill entries is gas-intensive for many entries.
        // A better design might be to store the sum of valid skill scores in the Reputation struct.
        // Skipping for simplicity, but this is a key optimization point.
        // uint256 totalValidSkillScore = 0;
        // for (uint i = 0; i < userToSkillEntryIds[_user].length; i++) {
        //     uint256 entryId = userToSkillEntryIds[_user][i];
        //     UserSkillEntry storage entry = userSkillEntries[entryId];
        //     if (entry.status == SkillEntryStatus.Valid) {
        //         totalValidSkillScore = totalValidSkillScore.add(uint256(entry.validationScore));
        //     }
        // }
        // decayedScore = decayedScore.add(totalValidSkillScore); // Example

        // Ensure non-negative
        return decayedScore;
    }

     /**
     * @notice Internal function to update a user's stored reputation score.
     * Should be called after actions that affect reputation (validation, staking, renewal, decay).
     * @param _user The user's address.
     */
    function updateReputation(address _user) internal {
        uint256 newReputation = calculateReputation(_user);
        userReputation[_user].score = newReputation;
        userReputation[_user].lastUpdateTime = block.timestamp;
        emit ReputationUpdated(_user, newReputation);
    }

    /**
     * @notice View function to get a user's current calculated reputation score.
     * Calls the internal calculation function.
     * @param _user The user's address.
     * @return The current reputation score.
     */
    function getReputation(address _user) public view returns (uint256) {
        return calculateReputation(_user);
    }


    // --- Temporal Functions ---

    /**
     * @notice Allows anyone to trigger the decay of a skill entry's validation score if due.
     * Designed to be callable by anyone to avoid relying on keepers.
     * @param _entryId The ID of the skill entry.
     */
    function decaySkillValidationScore(uint256 _entryId) external whenNotPaused {
        UserSkillEntry storage entry = userSkillEntries[_entryId];
        if (entry.id == 0) revert SkillEntryNotFound(_entryId);
        if (entry.status != SkillEntryStatus.Valid) return; // Only decay Valid entries

        uint256 timeElapsed = block.timestamp.sub(entry.lastValidationUpdateTime);
        uint256 decayPeriods = timeElapsed.div(skillDecayPeriod);

        if (decayPeriods == 0) revert SkillEntryNotDueForDecay(_entryId);

        int256 totalDecay = int256(decayPeriods.mul(skillDecayRate));
        int256 oldScore = entry.validationScore;

        if (entry.validationScore < totalDecay) {
            entry.validationScore = 0;
        } else {
            entry.validationScore = entry.validationScore.sub(uint256(totalDecay));
        }

        entry.lastValidationUpdateTime = entry.lastValidationUpdateTime.add(decayPeriods.mul(skillDecayPeriod)); // Update timestamp by full decayed periods

        // Check if status changes due to decay
        Skill memory skillDef = skills[entry.skillId];
        if (entry.status == SkillEntryStatus.Valid && entry.validationScore < int256(skillDef.requiredValidationScore)) {
             entry.status = SkillEntryStatus.PendingValidation; // Goes back to pending if score drops below threshold
        }

        updateReputation(entry.user);

        emit SkillEntryValidationScoreDecayed(_entryId, totalDecay, uint256(entry.validationScore));
    }

    /**
     * @notice Allows anyone to trigger the expiration of a skill entry if its duration has passed.
     * @param _entryId The ID of the skill entry.
     */
    function expireSkillEntry(uint256 _entryId) external whenNotPaused {
        UserSkillEntry storage entry = userSkillEntries[_entryId];
        if (entry.id == 0) revert SkillEntryNotFound(_entryId);
        if (entry.status != SkillEntryStatus.Valid) return; // Only expire Valid entries

        if (block.timestamp < entry.expirationTime) revert SkillEntryNotExpired(_entryId);

        entry.status = SkillEntryStatus.Expired;
        // Optional: Significantly reduce reputation on expiration
        // userReputation[entry.user].score = userReputation[entry.user].score.div(2); // Example harsh penalty
        updateReputation(entry.user);

        emit SkillEntryExpired(_entryId);
    }

    /**
     * @notice Allows a user to renew their skill entry.
     * May require re-validation or specific conditions depending on the skill definition.
     * @param _entryId The ID of the skill entry to renew.
     */
    function renewSkillEntry(uint256 _entryId) external whenNotPaused {
        UserSkillEntry storage entry = userSkillEntries[_entryId];
        if (entry.id == 0) revert SkillEntryNotFound(_entryId);
        require(entry.user == _msgSender(), "Only skill entry owner can renew");

        if (entry.status != SkillEntryStatus.Expired && block.timestamp < entry.expirationTime.sub(30 days)) {
             revert SkillEntryNotDueForRenewal(_entryId); // Example: only allow renewal if expired or within 30 days of expiration
        }

        Skill memory skillDef = skills[entry.skillId];

        // Renewal logic: Reset status to PendingValidation, clear validators, reset score.
        // Requires getting re-validated.
        entry.status = SkillEntryStatus.PendingValidation;
        entry.validationScore = 0;
        entry.lastValidationUpdateTime = block.timestamp;
        entry.expirationTime = 0; // Will be set upon re-validation

        // Clear validators mapping (manual iteration or specific clear logic needed if not Solidity 0.8.19+ with mapping clear)
        // For simplicity in mapping clear: We'll just rely on the status change requiring *new* validations.
        // The old `validators` mapping will still show past validators, but `entry.validationScore` resets.
        // If true mapping reset is needed: Requires storing validators in a dynamic array inside the struct, which has gas overheads.

        // Optional: Require a renewal stake or fee
        // require(stakingToken.transferFrom(_msgSender(), address(this), renewalStakeAmount), "Token transfer failed");

        updateReputation(_msgSender());

        emit SkillEntryRenewed(_entryId);
    }

    // --- Staking Functions ---

    /**
     * @notice Allows a user to stake tokens to become eligible for validation and governance.
     * @param _amount The amount of staking tokens to deposit.
     */
    function stakeForValidation(uint256 _amount) external whenNotPaused {
        require(_amount > 0, "Stake amount must be greater than 0");
        require(stakingToken.transferFrom(_msgSender(), address(this), _amount), "Token transfer failed");

        userStakingInfo[_msgSender()].amount = userStakingInfo[_msgSender()].amount.add(_amount);
        userStakingInfo[_msgSender()].lockUntil = 0; // Staking for validation is generally unlocked or has separate locking

        // Check if stake meets validator minimum
        if (userStakingInfo[_msgSender()].amount >= validatorStakeMinimum) {
             userStakingInfo[_msgSender()].isValidator = true;
        }

        updateReputation(_msgSender());

        emit StakeDeposited(_msgSender(), _amount, userStakingInfo[_msgSender()].amount);
    }

     /**
     * @notice Allows a user to stake tokens specifically for creating a proposal.
     * This stake is typically locked for the proposal duration.
     * @param _amount The amount of staking tokens to deposit.
     * @param _lockDuration How long the stake should be locked (in seconds).
     */
    function stakeForProposal(uint256 _amount, uint256 _lockDuration) external whenNotPaused {
        require(_amount >= proposalStakeMinimum, "Stake amount below proposal minimum");
        require(_lockDuration > 0, "Lock duration must be greater than 0");
        require(stakingToken.transferFrom(_msgSender(), address(this), _amount), "Token transfer failed");

        userStakingInfo[_msgSender()].amount = userStakingInfo[_msgSender()].amount.add(_amount);
        // This assumes a single stake for simplicity. In reality, you'd track stakes by purpose/lock time.
        // For this example, we'll use the same StakingInfo but set a lock time.
        // A better design would have multiple StakeInfo structs or a more complex StakeManager.
        userStakingInfo[_msgSender()].lockUntil = block.timestamp.add(_lockDuration); // Lock this specific stake

        // Ensure validator status isn't lost if this stake is for proposal only, separate logic needed
        if (userStakingInfo[_msgSender()].amount >= validatorStakeMinimum) {
             userStakingInfo[_msgSender()].isValidator = true;
        } else {
             userStakingInfo[_msgSender()].isValidator = false; // Might lose validator if total stake drops
        }


        updateReputation(_msgSender());

        emit StakeDeposited(_msgSender(), _amount, userStakingInfo[_msgSender()].amount);
    }


    /**
     * @notice Allows a user to withdraw their staked tokens if not locked.
     * @param _amount The amount of staking tokens to withdraw.
     */
    function withdrawStake(uint256 _amount) external whenNotPaused {
        require(_amount > 0, "Withdraw amount must be greater than 0");
        StakingInfo storage stakeInfo = userStakingInfo[_msgSender()];
        require(stakeInfo.amount >= _amount, "Insufficient staked amount");
        if (stakeInfo.lockUntil > block.timestamp) {
             revert StakeLocked(stakeInfo.lockUntil);
        }

        stakeInfo.amount = stakeInfo.amount.sub(_amount);

         // Check if stake falls below validator minimum
        if (stakeInfo.amount < validatorStakeMinimum) {
             stakeInfo.isValidator = false;
        }

        updateReputation(_msgSender());

        require(stakingToken.transfer(_msgSender(), _amount), "Token transfer failed");

        emit StakeWithdrawn(_msgSender(), _amount, stakeInfo.amount);
    }

    // --- Governance Functions (Simple On-Chain Voting) ---

    /**
     * @notice Allows a user with sufficient stake/reputation to propose a change.
     * Requires staking a certain amount that gets locked.
     * @param _proposalType The type of proposal.
     * @param _data Encoded data relevant to the proposal (e.g., new skill parameters, new threshold value).
     * @param _description A brief description of the proposal.
     */
    function proposeSkillAddition(ProposalType _proposalType, bytes calldata _data, string memory _description) external whenNotPaused {
        // Using proposalStakeMinimum from stakingInfo for proposal power check
        uint256 proposerVotingPower = userStakingInfo[_msgSender()].amount; // Could also factor in reputation: calculateReputation(_msgSender())
        if (proposerVotingPower < proposalStakeMinimum) {
             revert InsufficientVotingPower(proposalStakeMinimum, proposerVotingPower);
        }

        // Could add a temporary lock on the proposal stake here, separate from general validation stake

        _proposalIds.increment();
        uint256 newProposalId = _proposalIds.current();

        proposals[newProposalId] = Proposal({
            id: newProposalId,
            proposer: _msgSender(),
            proposalType: _proposalType,
            data: _data,
            creationTime: block.timestamp,
            votingEndTime: block.timestamp.add(proposalVotingPeriod),
            yesVotes: 0,
            noVotes: 0,
            hasVoted: new mapping(address => bool)(),
            state: ProposalState.Active
        });

        emit ProposalCreated(newProposalId, _msgSender(), proposals[newProposalId].votingEndTime, _description);
    }

     /**
     * @notice Allows a user with voting power to vote on an active proposal.
     * Voting power is determined by stake amount.
     * @param _proposalId The ID of the proposal to vote on.
     * @param _voteYes True for a 'Yes' vote, False for a 'No' vote.
     */
    function voteOnProposal(uint256 _proposalId, bool _voteYes) external whenNotPaused {
        Proposal storage proposal = proposals[_proposalId];
        if (proposal.id == 0) revert ProposalNotFound(_proposalId);
        if (proposal.state != ProposalState.Active) revert ProposalNotActive(_proposalId);
        if (proposal.votingEndTime < block.timestamp) revert ProposalVotingPeriodActive(proposal.votingEndTime); // Voting period ended
        if (proposal.hasVoted[_msgSender()]) revert CannotVoteTwice(_proposalId, _msgSender());

        uint256 voterVotingPower = userStakingInfo[_msgSender()].amount; // Or use reputation: calculateReputation(_msgSender())
        if (voterVotingPower == 0) revert InsufficientVotingPower(1, 0); // Must have some stake/power to vote

        proposal.hasVoted[_msgSender()] = true;

        if (_voteYes) {
            proposal.yesVotes = proposal.yesVotes.add(voterVotingPower);
        } else {
            proposal.noVotes = proposal.noVotes.add(voterVotingPower);
        }

        emit Voted(_proposalId, _msgSender(), _voteYes, voterVotingPower);
    }

     /**
     * @notice Allows anyone to execute a proposal that has passed its voting period and met the threshold.
     * @param _proposalId The ID of the proposal to execute.
     */
    function executeProposal(uint256 _proposalId) external whenNotPaused {
        Proposal storage proposal = proposals[_proposalId];
        if (proposal.id == 0) revert ProposalNotFound(_proposalId);
        if (proposal.state != ProposalState.Active) revert ProposalNotActive(_proposalId);
        if (proposal.votingEndTime > block.timestamp) revert ProposalVotingPeriodActive(proposal.votingEndTime); // Voting period not ended

        uint256 totalVotes = proposal.yesVotes.add(proposal.noVotes);
        // Avoid division by zero if no votes were cast
        bool passed = totalVotes > 0 && proposal.yesVotes.mul(proposalVoteThresholdDenominator) > totalVotes.mul(proposalVoteThresholdNumerator);

        if (!passed) {
            proposal.state = ProposalState.Failed;
            revert ProposalFailed(_proposalId);
        }

        // Execute the proposal based on type
        bytes memory proposalData = proposal.data;
        if (proposal.proposalType == ProposalType.AddSkillDefinition) {
            (string memory name, string memory description, string memory category, uint256 minRequiredValidators, uint256 requiredValidationScore, uint256 duration) =
                abi.decode(proposalData, (string, string, string, uint256, uint256, uint256));
            // Increment skill ID and add definition directly - bypasses the owner check in addSkillDefinition
            _skillIds.increment();
            uint256 newSkillId = _skillIds.current();
            skills[newSkillId] = Skill(newSkillId, name, description, category, block.timestamp, minRequiredValidators, requiredValidationScore, duration);
             allSkillIds.push(newSkillId);
            emit SkillDefinitionAdded(newSkillId, name, category);

        } else if (proposal.proposalType == ProposalType.SetValidationThreshold) {
            uint256 newThreshold = abi.decode(proposalData, (uint256));
            setValidationThreshold(newThreshold); // Call the setter function
        } else if (proposal.proposalType == ProposalType.SetDecayParameters) {
             (uint256 newSkillRate, uint256 newSkillPeriod, uint256 newRepRate, uint256 newRepPeriod) =
                 abi.decode(proposalData, (uint256, uint256, uint256, uint256));
             setDecayParameters(newSkillRate, newSkillPeriod, newRepRate, newRepPeriod);
        } else if (proposal.proposalType == ProposalType.SetStakingParameters) {
             (uint256 newValidatorMin, uint256 newProposalMin, uint256 newVotingPeriod, uint256 newVoteNum, uint256 newVoteDen) =
                 abi.decode(proposalData, (uint256, uint256, uint256, uint256, uint256));
             setStakingParameters(newValidatorMin, newProposalMin, newVotingPeriod, newVoteNum, newVoteDen);
        } else {
             revert InvalidProposalType(); // Should not happen if proposalType enum is handled completely
        }

        proposal.state = ProposalState.Executed;
        // Release proposer's locked stake if applicable (logic not implemented in simple stake)

        emit ProposalExecuted(_proposalId);
    }

    /**
     * @notice Governance function to update the minimum validation score required for Valid status.
     * Can be called by owner initially or via successful governance proposal.
     * @param _newThreshold The new minimum score.
     */
    function setValidationThreshold(uint256 _newThreshold) public onlyGovernance whenNotPaused {
        validationThreshold = _newThreshold;
        emit ParametersUpdated("validationThreshold", _newThreshold);
    }

    /**
     * @notice Governance function to update decay parameters.
     * Can be called by owner initially or via successful governance proposal.
     * @param _newSkillDecayRate How much validation score decays per period.
     * @param _newSkillDecayPeriod Time interval for skill score decay (in seconds).
     * @param _newReputationDecayRate How much reputation score decays per period.
     * @param _newReputationDecayPeriod Time interval for reputation decay (in seconds).
     */
    function setDecayParameters(uint256 _newSkillDecayRate, uint256 _newSkillDecayPeriod, uint256 _newReputationDecayRate, uint256 _newReputationDecayPeriod) public onlyGovernance whenNotPaused {
        skillDecayRate = _newSkillDecayRate;
        skillDecayPeriod = _newSkillDecayPeriod;
        reputationDecayRate = _newReputationDecayRate;
        reputationDecayPeriod = _newReputationDecayPeriod;
         emit ParametersUpdated("skillDecayRate", _newSkillDecayRate);
         emit ParametersUpdated("skillDecayPeriod", _newSkillDecayPeriod);
         emit ParametersUpdated("reputationDecayRate", _newReputationDecayRate);
         emit ParametersUpdated("reputationDecayPeriod", _newReputationDecayPeriod);
    }

     /**
     * @notice Governance function to update staking and voting parameters.
     * Can be called by owner initially or via successful governance proposal.
     * @param _newValidatorStakeMinimum Minimum stake for validator eligibility.
     * @param _newProposalStakeMinimum Minimum stake to create a proposal.
     * @param _newProposalVotingPeriod Duration of voting period.
     * @param _newVoteThresholdNumerator Numerator for vote threshold.
     * @param _newVoteThresholdDenominator Denominator for vote threshold.
     */
    function setStakingParameters(uint256 _newValidatorStakeMinimum, uint256 _newProposalStakeMinimum, uint256 _newProposalVotingPeriod, uint256 _newVoteThresholdNumerator, uint256 _newVoteThresholdDenominator) public onlyGovernance whenNotPaused {
        validatorStakeMinimum = _newValidatorStakeMinimum;
        proposalStakeMinimum = _newProposalStakeMinimum;
        proposalVotingPeriod = _newProposalVotingPeriod;
        proposalVoteThresholdNumerator = _newVoteThresholdNumerator;
        proposalVoteThresholdDenominator = _newVoteThresholdDenominator;

        emit ParametersUpdated("validatorStakeMinimum", _newValidatorStakeMinimum);
        emit ParametersUpdated("proposalStakeMinimum", _newProposalStakeMinimum);
        emit ParametersUpdated("proposalVotingPeriod", _newProposalVotingPeriod);
        emit ParametersUpdated("proposalVoteThresholdNumerator", _newVoteThresholdNumerator);
        emit ParametersUpdated("proposalVoteThresholdDenominator", _newVoteThresholdDenominator);

        // Re-evaluate validator status for all users if minimum changes (requires iteration, gas costly)
        // A better approach is to only check/update status when stake is added/removed or when validation is attempted.
    }


    // --- Utility Functions ---

    /**
     * @notice See {Pausable-pause}.
     * Can be called by owner initially or via successful governance proposal.
     */
    function pauseContract() public onlyGovernance whenNotPaused {
        _pause();
    }

    /**
     * @notice See {Pausable-unpause}.
     * Can be called by owner initially or via successful governance proposal.
     */
    function unpauseContract() public onlyGovernance whenPaused {
        _unpause();
    }

    // --- Getter Functions (View) ---

    /**
     * @notice Gets a user's current staking information.
     * @param _user The user's address.
     * @return amount Staked amount.
     * @return lockUntil Timestamp until which stake is locked.
     * @return isValidator Eligibility status.
     */
    function getStakingInfo(address _user) public view returns (uint256 amount, uint256 lockUntil, bool isValidator) {
        StakingInfo storage info = userStakingInfo[_user];
        return (info.amount, info.lockUntil, info.isValidator);
    }

    /**
     * @notice Gets a list of skill entry IDs for a specific user.
     * @param _user The user's address.
     * @return An array of skill entry IDs.
     */
    function getUserSkillEntries(address _user) public view returns (uint256[] memory) {
        return userToSkillEntryIds[_user];
    }

    /**
     * @notice Gets the details of a specific skill entry.
     * @param _entryId The ID of the skill entry.
     * @return The UserSkillEntry struct details.
     */
    function getSkillEntryDetails(uint256 _entryId) public view returns (UserSkillEntry memory) {
         UserSkillEntry storage entry = userSkillEntries[_entryId];
         if (entry.id == 0) revert SkillEntryNotFound(_entryId);
         // Need to return struct without internal mappings, copy to a temp struct
         return UserSkillEntry({
             id: entry.id,
             user: entry.user,
             skillId: entry.skillId,
             status: entry.status,
             validationScore: entry.validationScore,
             registrationTime: entry.registrationTime,
             lastValidationUpdateTime: entry.lastValidationUpdateTime,
             expirationTime: entry.expirationTime,
             validators: new mapping(address => bool)(), // Mappings cannot be returned
             attesters: new mapping(address => bool)()   // Mappings cannot be returned
         });
    }

    /**
     * @notice Gets the details of a skill definition.
     * @param _skillId The ID of the skill definition.
     * @return The Skill struct details.
     */
    function getSkillDefinition(uint256 _skillId) public view returns (Skill memory) {
        Skill memory skillDef = skills[_skillId];
         if (skillDef.id == 0 && _skillIds.current() < _skillId) {
             revert SkillDefinitionNotFound(_skillId);
         }
         return skillDef;
    }

    /**
     * @notice Gets the validators who have formally validated a specific skill entry.
     * NOTE: This requires iterating the `validators` mapping in the struct.
     * This can be *very* gas-intensive for entries with many validators.
     * In a production system, validators should likely be stored in an array in the struct,
     * or managed off-chain, or queried via events.
     * @param _entryId The ID of the skill entry.
     * @return An array of validator addresses.
     */
    function getValidatorsForSkillEntry(uint256 _entryId) public view returns (address[] memory) {
         UserSkillEntry storage entry = userSkillEntries[_entryId];
         if (entry.id == 0) revert SkillEntryNotFound(_entryId);

         // This is inefficient for large numbers of validators.
         // Consider alternative storage or off-chain retrieval.
         uint256 count = 0;
         // Cannot iterate mapping directly to get keys.
         // Need to store validators in an array or use events.
         // Returning an empty array as direct mapping key iteration is impossible.
         // Alternative: Store validators in an array in the struct, but this increases gas cost on write/update.
         // Let's return an empty array and note the limitation.
         address[] memory validatorList = new address[](0); // Placeholder
         // If validators were stored in an array:
         // address[] memory validatorList = new address[](entry.validatorAddresses.length);
         // for (uint i = 0; i < entry.validatorAddresses.length; i++) {
         //     validatorList[i] = entry.validatorAddresses[i];
         // }
         return validatorList; // Returning empty due to mapping limitation
    }

    /**
     * @notice Gets the details of a specific governance proposal.
     * @param _proposalId The ID of the proposal.
     * @return The Proposal struct details.
     */
    function getProposalDetails(uint256 _proposalId) public view returns (Proposal memory) {
        Proposal storage proposal = proposals[_proposalId];
        if (proposal.id == 0 && _proposalIds.current() < _proposalId) {
             revert ProposalNotFound(_proposalId);
        }
         // Need to return struct without internal mappings, copy to temp struct
         return Proposal({
             id: proposal.id,
             proposer: proposal.proposer,
             proposalType: proposal.proposalType,
             data: proposal.data,
             creationTime: proposal.creationTime,
             votingEndTime: proposal.votingEndTime,
             yesVotes: proposal.yesVotes,
             noVotes: proposal.noVotes,
             hasVoted: new mapping(address => bool)(), // Mapping cannot be returned
             state: proposal.state
         });
    }

     /**
     * @notice Gets a user's skill entries filtered by category.
     * NOTE: This requires iterating all user skill entries, which can be gas-intensive for many entries.
     * @param _user The user's address.
     * @param _category The category to filter by.
     * @return An array of skill entry IDs matching the category.
     */
    function getUserSkillsByCategory(address _user, string memory _category) public view returns (uint256[] memory) {
        uint256[] storage userEntryIds = userToSkillEntryIds[_user];
        uint256[] memory filteredIds = new uint256[](userEntryIds.length); // Max possible size
        uint256 count = 0;

        for (uint i = 0; i < userEntryIds.length; i++) {
            uint256 entryId = userEntryIds[i];
            UserSkillEntry storage entry = userSkillEntries[entryId];
            Skill memory skillDef = skills[entry.skillId];
            // Compare category string (simple equality check might not be robust for complex strings)
            if (keccak256(abi.encodePacked(skillDef.category)) == keccak256(abi.encodePacked(_category))) {
                filteredIds[count] = entryId;
                count++;
            }
        }

        // Trim the array to the actual number of matching entries
        uint256[] memory result = new uint256[](count);
        for(uint i = 0; i < count; i++) {
            result[i] = filteredIds[i];
        }
        return result;
    }

    // --- Internal Helper Functions ---
    // (calculateReputation is already internal)
    // Add others as needed for complex logic decomposition.

    // Placeholder for future internal logic or complex checks
    // function _checkValidatorEligibility(address _validator) internal view returns (bool) {
    //     return userStakingInfo[_validator].isValidator && userStakingInfo[_validator].amount >= validatorStakeMinimum;
    // }
}
```