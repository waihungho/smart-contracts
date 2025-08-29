Here's a smart contract written in Solidity that embodies advanced concepts, creative functionality, and is designed to be distinct from common open-source projects. It focuses on **dynamic NFTs, decentralized collaboration, reputation systems, and on-chain governance.**

The core idea is "ChronoForge" – a protocol for creating and evolving "Chronicles," which are dynamic NFTs representing collaborative projects, research, or artistic endeavors. These Chronicles gain "Maturity Points" (MPs) and "Integrity Score" (IS) through validated contributions. Contributors and validators earn "Legacy Fragments" (LF), a non-transferable reputation token, granting them influence within the ecosystem.

---

### ChronoForge - The Evolving Digital Legacy & Collaborative Creation Protocol

**Concept:** ChronoForge revolutionizes digital assets by introducing "Chronicles" — dynamic, evolving NFTs that represent collaborative projects, research endeavors, or artistic creations. These Chronicles aren't static; they gain "Maturity Points" (MPs) and "Integrity Score" (IS) through validated contributions, peer review, and the passage of time. Users who contribute to or validate successful Chronicles earn "Legacy Fragments" (LF), a non-transferable reputation token. LF then grants holders enhanced influence, voting power, and benefits within the ChronoForge ecosystem, fostering a self-sustaining and meritocratic decentralized research and creative network.

---

### Outline:

**I. Interfaces & Libraries:** Standard imports for ERC721, Ownable, Counters, Strings, and a custom Base64 library for on-chain metadata.
**II. Custom Errors:** For robust and gas-efficient error handling.
**III. Enums & Structs:** Definitions for Chronicle phases, contribution states, proposal types, and data structures for Chronicles, Contributions, Validators, Milestones, and Proposals.
**IV. Core State Variables:** Storage for all contract data, including counters, mappings, and adjustable system parameters.
**V. Events:** To emit notifications for important state changes.
**VI. Constructor:** Initializes the contract, sets the owner, and defines initial system parameters.
**VII. Modifiers:** Custom modifiers for access control and state checks.
**VIII. Chronicle Management (ERC721 & Dynamic Attributes):**
    - Creation of new Chronicles (NFTs).
    - Retrieval of detailed Chronicle information.
    - Dynamic generation of NFT metadata URIs reflecting Chronicle evolution.
    - Determination of a Chronicle's current evolutionary phase.
**IX. Contribution & Validation System:**
    - Submission of new contributions to Chronicles with a staking mechanism.
    - Registration and management of validators for the ecosystem.
    - Proposals by validators regarding the validity of contributions.
    - Finalization of contribution validity, updating Chronicle metrics and distributing rewards.
    - Mechanism for users to challenge proposed validations.
    - Resolution process for challenged validations (simplified).
**X. Reputation System (Legacy Fragments - Non-transferable Token):**
    - Retrieval of a user's Legacy Fragment balance.
    - Mechanism for burning Legacy Fragments (e.g., for penalties or specific redemptions).
**XI. Funding & Milestones:**
    - Allowing users to contribute funds to specific Chronicles.
    - Definition of project milestones with associated payout percentages.
    - Creator requests for milestone payouts.
    - Approval process (simplified) for milestone payouts.
**XII. Governance & Parameter Tuning:**
    - Proposals for updating core Chronicle attributes.
    - Voting mechanism for eligible stakeholders (Legacy Fragment holders) on various proposals.
    - Execution of approved governance proposals.
    - Privileged function for adjusting global ChronoForge parameters.
**XIII. Stake Management & Withdrawals:**
    - Withdrawal of contribution stakes upon successful validation.
    - Withdrawal of validator stakes after an unbonding period.
**XIV. Internal/Helper Functions:**
    - Logic for converting Chronicle phases to strings for metadata.

---

### Function Summary:

**I. Core Chronicle Management (ERC721 & Dynamic Attributes)**
1.  `createChronicle(string calldata _title, string calldata _description, uint256 _initialFundingGoal)`: Mints a new Chronicle NFT, setting its initial state, title, description, and an optional funding goal.
2.  `getChronicleDetails(uint256 _chronicleId)`: Retrieves comprehensive details about a specific Chronicle, including its title, description, Maturity Points, Integrity Score, and current phase.
3.  `tokenURI(uint256 _chronicleId)`: Standard ERC721 function; dynamically generates or retrieves the metadata URI for a Chronicle, reflecting its current evolving state, including its phase and metrics.
4.  `getCurrentChroniclePhase(uint256 _chronicleId)`: Returns the current evolutionary phase of a Chronicle (e.g., "Seed", "Growth", "Mature", "Legacy") based on its Maturity Points.

**II. Contribution & Validation System**
5.  `submitContribution(uint256 _chronicleId, string calldata _contributionHash, string calldata _contributionType, uint256 _stakeAmount)`: Allows users to submit a contribution to a Chronicle, requiring a stake (paid in ETH for this example) to prevent spam. The `_contributionHash` refers to off-chain data.
6.  `becomeValidator(uint256 _stakeAmount)`: Enables a user to register as a validator for the ChronoForge ecosystem by staking a required amount of ETH.
7.  `proposeContributionValidation(uint256 _chronicleId, uint256 _contributionId, bool _isValid)`: A registered validator proposes whether a specific contribution is valid or not.
8.  `finalizeContributionValidation(uint256 _chronicleId, uint256 _contributionId)`: After a voting/consensus period, this function finalizes the validity of a contribution, updates the Chronicle's Maturity Points and Integrity Score, and distributes Legacy Fragments.
9.  `challengeValidation(uint256 _chronicleId, uint256 _contributionId, uint256 _challengerStake)`: Allows any user to challenge a *proposed* validation outcome if they believe it's incorrect, requiring a stake.
10. `resolveChallenge(uint256 _chronicleId, uint256 _contributionId, bool _challengerWins)`: A privileged function (e.g., `onlyOwner` for this example, or a DAO) to resolve a disputed validation, penalizing the losing party and rewarding the winner.

**III. Reputation System (Legacy Fragments - Non-transferable Token)**
11. `getLegacyFragmentBalance(address _user)`: Retrieves the non-transferable Legacy Fragment (LF) balance for a given user, reflecting their reputation.
12. `burnLegacyFragments(address _target, uint256 _amount)`: Allows for burning of Legacy Fragments, typically for penalty or specific redemption mechanisms (e.g., to reduce spam potential for high-stakes actions).

**IV. Funding & Milestones**
13. `fundChronicle(uint256 _chronicleId)`: Allows users to send ETH to a Chronicle, contributing to its funding goal.
14. `defineChronicleMilestone(uint256 _chronicleId, string calldata _description, uint256 _payoutPercentage)`: The Chronicle's original creator defines a new milestone with a specified percentage of the total funds as payout.
15. `requestMilestonePayout(uint256 _chronicleId, uint256 _milestoneId)`: The Chronicle creator requests a payout for a completed milestone.
16. `approveMilestonePayout(uint256 _chronicleId, uint256 _milestoneId)`: A `onlyValidator` (or governance) function to approve a milestone payout. If approved, funds are released to the Chronicle creator.

**V. Governance & Parameter Tuning**
17. `proposeChronicleAttributeUpdate(uint256 _chronicleId, string calldata _newTitle, string calldata _newDescription)`: Initiates a governance proposal to update mutable attributes of a Chronicle (e.g., title, description), requiring a minimum amount of Legacy Fragments from the proposer.
18. `voteOnProposal(uint256 _proposalId, bool _support)`: Allows eligible users (based on Legacy Fragment balance) to vote on active proposals, with vote weight proportional to their LF.
19. `executeProposal(uint256 _proposalId)`: Executes a governance proposal once it has passed the voting threshold and its voting period has ended.
20. `setChronoForgeParameter(bytes32 _paramKey, uint256 _value)`: A privileged function (e.g., controlled by `onlyOwner` for this example, or a DAO) to adjust core system parameters like minimum stakes, validation periods, or MP gain rates.

**VI. Stake Management & Withdrawals**
21. `withdrawContributionStake(uint256 _chronicleId, uint256 _contributionId)`: Allows a contributor to withdraw their initial stake *if* their contribution was successfully validated and the unbonding period has passed.
22. `withdrawValidatorStake()`: Allows a validator to initiate withdrawal of their general stake from the validator pool. After an unbonding period, they can fully withdraw the funds.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
// import "@openzeppelin/contracts/token/ERC20/IERC20.sol"; // Uncomment if using a specific ERC20 token for staking/funding

/*
╔═════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════╗
║                                                     ChronoForge - The Evolving Digital Legacy & Collaborative Creation Protocol                   ║
╠═════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════╣
║ ChronoForge revolutionizes digital assets by introducing "Chronicles" — dynamic, evolving NFTs that represent collaborative projects,              ║
║ research endeavors, or artistic creations. These Chronicles aren't static; they gain "Maturity Points" (MPs) and "Integrity Score" (IS)           ║
║ through validated contributions, peer review, and the passage of time. Users who contribute to or validate successful Chronicles earn              ║
║ "Legacy Fragments" (LF), a non-transferable reputation token. LF then grants holders enhanced influence, voting power, and benefits                ║
║ within the ChronoForge ecosystem, fostering a self-sustaining and meritocratic decentralized research and creative network.                       ║
╚═════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════╝

Outline:
I. Interfaces & Libraries: Standard imports for ERC721, Ownable, Counters, Strings, and a custom Base64 library for on-chain metadata.
II. Custom Errors: For robust and gas-efficient error handling.
III. Enums & Structs: Definitions for Chronicle phases, contribution states, proposal types, and data structures for Chronicles, Contributions, Validators, Milestones, and Proposals.
IV. Core State Variables: Storage for all contract data, including counters, mappings, and adjustable system parameters.
V. Events: To emit notifications for important state changes.
VI. Constructor: Initializes the contract, sets the owner, and defines initial system parameters.
VII. Modifiers: Custom modifiers for access control and state checks.
VIII. Chronicle Management (ERC721 & Dynamic Attributes):
    - Creation of new Chronicles (NFTs).
    - Retrieval of detailed Chronicle information.
    - Dynamic generation of NFT metadata URIs reflecting Chronicle evolution.
    - Determination of a Chronicle's current evolutionary phase.
IX. Contribution & Validation System:
    - Submission of new contributions to Chronicles with a staking mechanism.
    - Registration and management of validators for the ecosystem.
    - Proposals by validators regarding the validity of contributions.
    - Finalization of contribution validity, updating Chronicle metrics and distributing rewards.
    - Mechanism for users to challenge proposed validations.
    - Resolution process for challenged validations (simplified).
X. Reputation System (Legacy Fragments - Non-transferable Token):
    - Retrieval of a user's Legacy Fragment balance.
    - Mechanism for burning Legacy Fragments (e.g., for penalties or specific redemptions).
XI. Funding & Milestones:
    - Allowing users to contribute funds to specific Chronicles.
    - Definition of project milestones with associated payout percentages.
    - Creator requests for milestone payouts.
    - Approval process (simplified) for milestone payouts.
XII. Governance & Parameter Tuning:
    - Proposals for updating core Chronicle attributes.
    - Voting mechanism for eligible stakeholders (Legacy Fragment holders) on various proposals.
    - Execution of approved governance proposals.
    - Privileged function for adjusting global ChronoForge parameters.
XIII. Stake Management & Withdrawals:
    - Withdrawal of contribution stakes upon successful validation.
    - Withdrawal of validator stakes after an unbonding period.
XIV. Internal/Helper Functions:
    - Logic for converting Chronicle phases to strings for metadata.
*/

// Function Summary:

// I. Core Chronicle Management (ERC721 & Dynamic Attributes)
// 1.  createChronicle(string calldata _title, string calldata _description, uint256 _initialFundingGoal)
//     - Mints a new Chronicle NFT, setting its initial state, title, description, and an optional funding goal.
// 2.  getChronicleDetails(uint256 _chronicleId)
//     - Retrieves comprehensive details about a specific Chronicle, including its title, description, Maturity Points, Integrity Score, and current phase.
// 3.  tokenURI(uint256 _chronicleId)
//     - Standard ERC721 function; dynamically generates or retrieves the metadata URI for a Chronicle, reflecting its current evolving state, including its phase and metrics.
// 4.  getCurrentChroniclePhase(uint256 _chronicleId)
//     - Returns the current evolutionary phase of a Chronicle (e.g., "Seed", "Growth", "Mature", "Legacy") based on its Maturity Points.

// II. Contribution & Validation System
// 5.  submitContribution(uint256 _chronicleId, string calldata _contributionHash, string calldata _contributionType, uint256 _stakeAmount)
//     - Allows users to submit a contribution to a Chronicle, requiring a stake (paid in ETH for this example) to prevent spam. The _contributionHash refers to off-chain data.
// 6.  becomeValidator(uint256 _stakeAmount)
//     - Enables a user to register as a validator for the ChronoForge ecosystem by staking a required amount of ETH.
// 7.  proposeContributionValidation(uint256 _chronicleId, uint256 _contributionId, bool _isValid)
//     - A registered validator proposes whether a specific contribution is valid or not.
// 8.  finalizeContributionValidation(uint256 _chronicleId, uint256 _contributionId)
//     - After a voting/consensus period, this function finalizes the validity of a contribution, updates the Chronicle's Maturity Points and Integrity Score, and distributes Legacy Fragments.
// 9.  challengeValidation(uint256 _chronicleId, uint256 _contributionId, uint256 _challengerStake)
//     - Allows any user to challenge a *proposed* validation outcome if they believe it's incorrect, requiring a stake.
// 10. resolveChallenge(uint256 _chronicleId, uint256 _contributionId, bool _challengerWins)
//     - A privileged function (e.g., `onlyOwner` for this example, or a DAO) to resolve a disputed validation, penalizing the losing party and rewarding the winner.

// III. Reputation System (Legacy Fragments - Non-transferable Token)
// 11. getLegacyFragmentBalance(address _user)
//     - Retrieves the non-transferable Legacy Fragment (LF) balance for a given user, reflecting their reputation.
// 12. burnLegacyFragments(address _target, uint256 _amount)
//     - Allows for burning of Legacy Fragments, typically for penalty or specific redemption mechanisms (e.g., to reduce spam potential for high-stakes actions).

// IV. Funding & Milestones
// 13. fundChronicle(uint256 _chronicleId)
//     - Allows users to send ETH to a Chronicle, contributing to its funding goal.
// 14. defineChronicleMilestone(uint256 _chronicleId, string calldata _description, uint256 _payoutPercentage)
//     - The Chronicle's original creator defines a new milestone with a specified percentage of the total funds as payout.
// 15. requestMilestonePayout(uint256 _chronicleId, uint256 _milestoneId)
//     - The Chronicle creator requests a payout for a completed milestone.
// 16. approveMilestonePayout(uint256 _chronicleId, uint256 _milestoneId)
//     - A `onlyValidator` (or governance) function to approve a milestone payout. If approved, funds are released to the Chronicle creator.

// V. Governance & Parameter Tuning
// 17. proposeChronicleAttributeUpdate(uint256 _chronicleId, string calldata _newTitle, string calldata _newDescription)
//     - Initiates a governance proposal to update mutable attributes of a Chronicle (e.g., title, description), requiring a minimum amount of Legacy Fragments from the proposer.
// 18. voteOnProposal(uint256 _proposalId, bool _support)
//     - Allows eligible users (based on Legacy Fragment balance) to vote on active proposals, with vote weight proportional to their LF.
// 19. executeProposal(uint256 _proposalId)
//     - Executes a governance proposal once it has passed the voting threshold and its voting period has ended.
// 20. setChronoForgeParameter(bytes32 _paramKey, uint256 _value)
//     - A privileged function (e.g., controlled by `onlyOwner` for this example, or a DAO) to adjust core system parameters like minimum stakes, validation periods, or MP gain rates.

// VI. Stake Management & Withdrawals
// 21. withdrawContributionStake(uint256 _chronicleId, uint256 _contributionId)
//     - Allows a contributor to withdraw their initial stake *if* their contribution was successfully validated and the unbonding period has passed.
// 22. withdrawValidatorStake()
//     - Allows a validator to initiate withdrawal of their general stake from the validator pool. After an unbonding period, they can fully withdraw the funds.
*/

// Custom Errors for enhanced clarity and gas efficiency
error ChronicleNotFound(uint256 chronicleId);
error ContributionNotFound(uint256 chronicleId, uint256 contributionId);
error ValidatorNotFound(address validatorAddress);
error NotAValidator();
error InsufficientStake(uint256 required, uint256 provided);
error InvalidChroniclePhase(); // Not used directly, but kept for consistency
error UnauthorizedAction();
error AlreadyValidated(uint256 contributionId); // Validator already proposed
error ChallengeInProgress(uint256 contributionId);
error NoActiveChallenge();
error MilestoneNotFound(uint256 chronicleId, uint256 milestoneId);
error InvalidPayoutPercentage();
error FundingGoalNotMet(uint256 current, uint256 required);
error ProposalNotFound(uint256 proposalId);
error NotEnoughLegacyFragments(uint256 required, uint256 provided);
error AlreadyVoted();
error ProposalNotReadyForExecution();
error ProposalAlreadyExecuted();
error WithdrawStakeLocked();
error UnbondingPeriodNotOver(uint256 unlockTime);
error InvalidParameter();
error InvalidContributionState();
error InvalidValidationState();


contract ChronoForge is ERC721, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _chronicleIds;
    Counters.Counter private _contributionIds;
    Counters.Counter private _milestoneIds;
    Counters.Counter private _proposalIds;

    // --- Enums and Structs ---

    enum ChroniclePhase {
        Seed,       // Early stage, low MPs
        Growth,     // Developing, gaining MPs, more active contributions
        Mature,     // Established, high MPs, focus on integrity and broader impact
        Legacy      // Very high MPs, historical significance, minimal changes
    }

    enum ContributionState {
        Pending,            // Submitted, awaiting validation
        Validated,          // Approved by validators
        Rejected,           // Rejected by validators
        Challenged,         // Validation challenged
        ChallengeResolved   // Challenge resolved
    }

    enum ProposalType {
        ChronicleAttributeUpdate,
        MilestoneApproval // Future implementation may involve a separate system for this
    }

    struct Chronicle {
        string title;
        string description;
        address creator;
        uint256 createdAt;
        uint256 maturityPoints; // Gained by validated contributions, time (simplified to contributions for now)
        uint256 integrityScore; // Reflects validation accuracy, peer review (0-1000)
        uint256 fundingGoal; // Optional target for funding
        uint256 fundsRaised; // Current funds collected (in ETH for this example)
        uint256 totalMilestonePayoutPercentage; // Sum of all defined milestone percentages
        mapping(uint256 => Milestone) milestones;
    }

    struct Contribution {
        uint256 id;
        uint256 chronicleId;
        address contributor;
        string contributionHash; // IPFS hash or similar for off-chain data
        string contributionType; // e.g., "code", "research_paper", "artwork"
        uint256 submittedAt;
        uint256 stakeAmount; // ETH staked by the contributor
        ContributionState state;
        mapping(address => bool) validatorProposed; // Has this validator already proposed for this contribution
        mapping(address => bool) validatorVote;     // True for valid, false for invalid
        uint256 validVotes;
        uint256 invalidVotes;
        address challenger; // Address of the challenger if state is Challenged
        uint256 challengeStake; // ETH staked by the challenger
        uint256 validationFinalizedAt; // Timestamp when validation or challenge was finalized (for stake withdrawal)
        address[] validatorsWhoVoted; // Tracks all unique validators who cast a vote
    }

    struct Validator {
        address validatorAddress;
        uint256 totalStake; // Total ETH staked by the validator
        uint256 lastActivity; // To track active validators, update on any validation proposal
        uint256 unbondingPeriodEnd; // When validator can withdraw stake (0 if not in unbonding)
        bool isActive;
    }

    struct Milestone {
        uint256 id;
        string description;
        uint256 payoutPercentage; // Percentage of total fundsRaised
        bool requested;
        bool approved;
        uint256 requestedAt;
        uint256 approvedAt;
    }

    struct Proposal {
        uint256 id;
        ProposalType propType;
        address proposer;
        uint252 targetChronicleId; // Can be 0 if not Chronicle-specific
        bytes data; // ABI-encoded data for the specific proposal action (e.g., new title/description)
        uint256 createdAt;
        uint256 votingEndsAt;
        uint256 requiredLegacyFragments; // Minimum LF to vote
        uint256 votesFor; // Sum of LF from "for" votes
        uint256 votesAgainst; // Sum of LF from "against" votes
        mapping(address => bool) hasVoted; // Tracks if an address has voted
        bool executed;
        bool approved; // Result of the vote
    }


    // --- Core State Variables ---

    mapping(uint256 => Chronicle) public chronicles;
    mapping(uint256 => mapping(uint256 => Contribution)) public chronicleContributions; // chronicleId -> contributionId -> Contribution
    mapping(address => Validator) public validators; // Address to Validator struct
    mapping(address => uint256) public legacyFragments; // Non-transferable reputation token
    mapping(uint256 => Proposal) public proposals; // proposalId -> Proposal

    // System parameters, adjustable by governance (e.g., owner, or future DAO)
    mapping(bytes32 => uint256) public parameters;

    // --- Events ---
    event ChronicleCreated(uint256 indexed chronicleId, address indexed creator, string title, uint256 fundingGoal);
    event ContributionSubmitted(uint256 indexed chronicleId, uint256 indexed contributionId, address indexed contributor, string contributionType, uint256 stakeAmount);
    event ValidatorRegistered(address indexed validatorAddress, uint256 stakeAmount);
    event ValidationProposed(uint256 indexed chronicleId, uint256 indexed contributionId, address indexed validator, bool isValid);
    event ValidationFinalized(uint256 indexed chronicleId, uint256 indexed contributionId, bool isValid, uint256 maturityPointsGained, int256 integrityScoreChange);
    event ChallengeInitiated(uint256 indexed chronicleId, uint256 indexed contributionId, address indexed challenger, uint256 challengeStake);
    event ChallengeResolved(uint256 indexed chronicleId, uint256 indexed contributionId, bool challengerWins);
    event LegacyFragmentsAwarded(address indexed recipient, uint256 amount);
    event LegacyFragmentsBurned(address indexed burner, uint256 amount);
    event ChronicleFunded(uint256 indexed chronicleId, address indexed funder, uint256 amount, uint256 totalFunds);
    event MilestoneDefined(uint256 indexed chronicleId, uint256 indexed milestoneId, string description, uint256 payoutPercentage);
    event MilestonePayoutRequested(uint256 indexed chronicleId, uint256 indexed milestoneId);
    event MilestonePayoutApproved(uint256 indexed chronicleId, uint256 indexed milestoneId, uint256 amount);
    event ProposalCreated(uint256 indexed proposalId, ProposalType propType, address indexed proposer, uint256 targetChronicleId, uint256 votingEndsAt);
    event VotedOnProposal(uint256 indexed proposalId, address indexed voter, bool support);
    event ProposalExecuted(uint256 indexed proposalId, bool approved);
    event ParameterSet(bytes32 indexed paramKey, uint256 value);
    event StakeWithdrawn(address indexed staker, uint256 amount);

    // --- Constructor ---

    constructor(string memory _name, string memory _symbol)
        ERC721(_name, _symbol)
        Ownable(msg.sender)
    {
        // Set initial system parameters (can be adjusted later by governance)
        parameters[keccak256("MIN_CONTRIBUTION_STAKE")] = 0.01 ether;
        parameters[keccak256("MIN_VALIDATOR_STAKE")] = 0.1 ether;
        parameters[keccak256("VALIDATION_PERIOD")] = 3 days; // Time for validators to propose validation
        parameters[keccak256("CHALLENGE_PERIOD")] = 3 days;  // Time for challenges after validation proposals begin
        parameters[keccak256("UNBONDING_PERIOD")] = 7 days;  // For stake withdrawals
        parameters[keccak256("LEGACY_FRAGMENT_AWARD_CONTRIBUTION")] = 10; // LF for successful contribution
        parameters[keccak256("LEGACY_FRAGMENT_AWARD_VALIDATION")] = 5;    // LF for correct validation
        parameters[keccak256("CHRONICLE_MP_PER_VALID_CONTRIBUTION")] = 10; // MPs gained per valid contribution
        parameters[keccak256("CHRONICLE_IS_GAIN_PER_VALIDATION")] = 10;    // IS gain per correct validation (out of 1000 max)
        parameters[keccak256("CHRONICLE_IS_LOSS_PER_CHALLENGE")] = 50;    // IS loss for failed challenge or incorrect validation
        parameters[keccak256("PROPOSAL_VOTING_PERIOD")] = 7 days;
        parameters[keccak256("MIN_LF_FOR_VOTING")] = 100; // Minimum LF required to vote on proposals
        parameters[keccak256("MIN_VALIDATORS_FOR_FINALIZATION")] = 3; // Minimum unique validators needed to finalize

        // Set initial phase thresholds (MPs)
        parameters[keccak256("PHASE_GROWTH_THRESHOLD")] = 50;
        parameters[keccak256("PHASE_MATURE_THRESHOLD")] = 200;
        parameters[keccak256("PHASE_LEGACY_THRESHOLD")] = 1000;
    }

    // --- Modifiers ---

    modifier onlyValidator() {
        if (!validators[msg.sender].isActive) {
            revert NotAValidator();
        }
        _;
    }

    modifier onlyChronicleCreator(uint256 _chronicleId) {
        if (chronicles[_chronicleId].creator == address(0)) {
            revert ChronicleNotFound(_chronicleId);
        }
        if (chronicles[_chronicleId].creator != msg.sender) {
            revert UnauthorizedAction();
        }
        _;
    }

    // --- I. Core Chronicle Management (ERC721 & Dynamic Attributes) ---

    function createChronicle(
        string calldata _title,
        string calldata _description,
        uint256 _initialFundingGoal
    ) external returns (uint256) {
        _chronicleIds.increment();
        uint256 newChronicleId = _chronicleIds.current();

        Chronicle storage chronicle = chronicles[newChronicleId];
        chronicle.title = _title;
        chronicle.description = _description;
        chronicle.creator = msg.sender;
        chronicle.createdAt = block.timestamp;
        chronicle.maturityPoints = 0;
        chronicle.integrityScore = 500; // Start with a neutral score out of 1000
        chronicle.fundingGoal = _initialFundingGoal;
        chronicle.fundsRaised = 0;
        chronicle.totalMilestonePayoutPercentage = 0;

        _safeMint(msg.sender, newChronicleId);

        emit ChronicleCreated(newChronicleId, msg.sender, _title, _initialFundingGoal);
        return newChronicleId;
    }

    function getChronicleDetails(uint256 _chronicleId)
        public view
        returns (
            string memory title,
            string memory description,
            address creator,
            uint256 createdAt,
            uint256 maturityPoints,
            uint256 integrityScore,
            uint256 fundingGoal,
            uint256 fundsRaised,
            ChroniclePhase currentPhase
        )
    {
        Chronicle storage chronicle = chronicles[_chronicleId];
        if (chronicle.creator == address(0)) {
            revert ChronicleNotFound(_chronicleId);
        }

        return (
            chronicle.title,
            chronicle.description,
            chronicle.creator,
            chronicle.createdAt,
            chronicle.maturityPoints,
            chronicle.integrityScore,
            chronicle.fundingGoal,
            chronicle.fundsRaised,
            getCurrentChroniclePhase(_chronicleId)
        );
    }

    // Overriding ERC721's tokenURI to provide dynamic metadata based on Chronicle's state
    function tokenURI(uint256 _chronicleId) public view override returns (string memory) {
        if (!ERC721._exists(_chronicleId)) {
            revert ChronicleNotFound(_chronicleId);
        }

        Chronicle storage chronicle = chronicles[_chronicleId];
        ChroniclePhase currentPhase = getCurrentChroniclePhase(_chronicleId);

        // This constructs a data URI with base64 encoded JSON.
        // In a real dApp, the `image` field would point to a dynamic image generated
        // off-chain (e.g., by a serverless function) reflecting the current phase and metrics,
        // or to an IPFS CID of a static image corresponding to the phase.
        string memory baseImageURI = "ipfs://QmYourIPFSHashHere"; // Placeholder IPFS Base URI

        string memory json = string.concat(
            '{"name": "', chronicle.title, '",',
            '"description": "', chronicle.description, '",',
            '"image": "', baseImageURI, '/', Strings.toString(_chronicleId), '-', _phaseToString(currentPhase), '.png",', // Dynamic image based on ID and Phase
            '"attributes": [',
            '{"trait_type": "Creator", "value": "', Strings.toHexString(uint160(chronicle.creator), 20), '"},',
            '{"trait_type": "Maturity Points", "value": ', Strings.toString(chronicle.maturityPoints), '},',
            '{"trait_type": "Integrity Score", "value": ', Strings.toString(chronicle.integrityScore), '},',
            '{"trait_type": "Phase", "value": "', _phaseToString(currentPhase), '"},',
            '{"trait_type": "Funds Raised", "value": ', Strings.toString(chronicle.fundsRaised), '}',
            ']}'
        );
        
        return string(
            abi.encodePacked(
                "data:application/json;base64,",
                Base64.encode(bytes(json))
            )
        );
    }

    function getCurrentChroniclePhase(uint256 _chronicleId) public view returns (ChroniclePhase) {
        Chronicle storage chronicle = chronicles[_chronicleId];
        if (chronicle.creator == address(0)) {
            revert ChronicleNotFound(_chronicleId);
        }

        if (chronicle.maturityPoints >= parameters[keccak256("PHASE_LEGACY_THRESHOLD")]) {
            return ChroniclePhase.Legacy;
        } else if (chronicle.maturityPoints >= parameters[keccak256("PHASE_MATURE_THRESHOLD")]) {
            return ChroniclePhase.Mature;
        } else if (chronicle.maturityPoints >= parameters[keccak256("PHASE_GROWTH_THRESHOLD")]) {
            return ChroniclePhase.Growth;
        } else {
            return ChroniclePhase.Seed;
        }
    }

    // --- II. Contribution & Validation System ---

    function submitContribution(
        uint256 _chronicleId,
        string calldata _contributionHash,
        string calldata _contributionType,
        uint256 _stakeAmount
    ) external payable { // Made payable for ETH stake
        Chronicle storage chronicle = chronicles[_chronicleId];
        if (chronicle.creator == address(0)) {
            revert ChronicleNotFound(_chronicleId);
        }
        if (_stakeAmount < parameters[keccak256("MIN_CONTRIBUTION_STAKE")]) {
            revert InsufficientStake(parameters[keccak256("MIN_CONTRIBUTION_STAKE")], _stakeAmount);
        }
        if (msg.value != _stakeAmount) {
             revert InsufficientStake(_stakeAmount, msg.value);
        }

        _contributionIds.increment(); // Use global contribution ID counter
        uint256 newContributionId = _contributionIds.current();

        Contribution storage newContribution = chronicleContributions[_chronicleId][newContributionId];
        newContribution.id = newContributionId;
        newContribution.chronicleId = _chronicleId;
        newContribution.contributor = msg.sender;
        newContribution.contributionHash = _contributionHash;
        newContribution.contributionType = _contributionType;
        newContribution.submittedAt = block.timestamp;
        newContribution.stakeAmount = _stakeAmount;
        newContribution.state = ContributionState.Pending;
        // The ETH stake is automatically held by the contract via `msg.value`

        emit ContributionSubmitted(_chronicleId, newContributionId, msg.sender, _contributionType, _stakeAmount);
    }

    function becomeValidator(uint256 _stakeAmount) external payable { // Made payable for ETH stake
        if (validators[msg.sender].isActive) {
            revert UnauthorizedAction(); // Already a validator
        }
        if (_stakeAmount < parameters[keccak256("MIN_VALIDATOR_STAKE")]) {
            revert InsufficientStake(parameters[keccak256("MIN_VALIDATOR_STAKE")], _stakeAmount);
        }
        if (msg.value != _stakeAmount) {
             revert InsufficientStake(_stakeAmount, msg.value);
        }

        Validator storage newValidator = validators[msg.sender];
        newValidator.validatorAddress = msg.sender;
        newValidator.totalStake = _stakeAmount;
        newValidator.lastActivity = block.timestamp;
        newValidator.isActive = true;

        emit ValidatorRegistered(msg.sender, _stakeAmount);
    }

    function proposeContributionValidation(uint256 _chronicleId, uint256 _contributionId, bool _isValid)
        external
        onlyValidator
    {
        Chronicle storage chronicle = chronicles[_chronicleId];
        if (chronicle.creator == address(0)) {
            revert ChronicleNotFound(_chronicleId);
        }
        Contribution storage contribution = chronicleContributions[_chronicleId][_contributionId];
        if (contribution.contributor == address(0)) {
            revert ContributionNotFound(_chronicleId, _contributionId);
        }
        if (contribution.state != ContributionState.Pending) {
            revert InvalidContributionState(); // Can only propose validation for pending contributions
        }
        if (contribution.validatorProposed[msg.sender]) {
            revert AlreadyValidated(_contributionId); // Already proposed by this validator
        }
        // Ensure validation period is still active
        if (block.timestamp > contribution.submittedAt + parameters[keccak256("VALIDATION_PERIOD")]) {
            revert InvalidValidationState(); // Validation period has expired
        }

        contribution.validatorProposed[msg.sender] = true;
        contribution.validatorVote[msg.sender] = _isValid;
        contribution.validatorsWhoVoted.push(msg.sender); // Record who voted

        if (_isValid) {
            contribution.validVotes++;
        } else {
            contribution.invalidVotes++;
        }

        // Update validator's last activity
        validators[msg.sender].lastActivity = block.timestamp;

        emit ValidationProposed(_chronicleId, _contributionId, msg.sender, _isValid);
    }

    function finalizeContributionValidation(uint256 _chronicleId, uint256 _contributionId) external {
        Chronicle storage chronicle = chronicles[_chronicleId];
        if (chronicle.creator == address(0)) {
            revert ChronicleNotFound(_chronicleId);
        }
        Contribution storage contribution = chronicleContributions[_chronicleId][_contributionId];
        if (contribution.contributor == address(0)) {
            revert ContributionNotFound(_chronicleId, _contributionId);
        }
        if (contribution.state != ContributionState.Pending) {
            revert InvalidContributionState();
        }
        // Must wait until validation period is over OR challenge period has passed for quicker finalization if no challenge.
        // For simplicity, we ensure validation period is over.
        if (block.timestamp < contribution.submittedAt + parameters[keccak256("VALIDATION_PERIOD")]) {
            revert InvalidValidationState(); // Validation period not over
        }
        if (contribution.validatorsWhoVoted.length < parameters[keccak256("MIN_VALIDATORS_FOR_FINALIZATION")]) {
             revert InvalidValidationState(); // Not enough validators participated
        }

        bool isValid = contribution.validVotes > contribution.invalidVotes;

        contribution.state = isValid ? ContributionState.Validated : ContributionState.Rejected;
        contribution.validationFinalizedAt = block.timestamp;

        uint256 mpGained = 0;
        int256 isChange = 0;

        if (isValid) {
            mpGained = parameters[keccak256("CHRONICLE_MP_PER_VALID_CONTRIBUTION")];
            chronicle.maturityPoints += mpGained;
            _awardLegacyFragments(contribution.contributor, parameters[keccak256("LEGACY_FRAGMENT_AWARD_CONTRIBUTION")]);

            // Reward validators who voted correctly
            for (uint256 i = 0; i < contribution.validatorsWhoVoted.length; i++) {
                address validatorAddress = contribution.validatorsWhoVoted[i];
                if (contribution.validatorVote[validatorAddress]) { // If validator voted "valid"
                    _awardLegacyFragments(validatorAddress, parameters[keccak256("LEGACY_FRAGMENT_AWARD_VALIDATION")]);
                } else { // If validator voted "invalid" when it was valid, penalize (or just no reward)
                    // _burnLegacyFragments(validatorAddress, parameters[keccak256("LEGACY_FRAGMENT_AWARD_VALIDATION")]); // Optional penalty
                }
            }
            // Challenger (if any) and their stake will be handled in resolveChallenge.
            isChange = int256(parameters[keccak256("CHRONICLE_IS_GAIN_PER_VALIDATION")]);
        } else { // Contribution was rejected
            // Contributor's stake is forfeited
            // Validators who voted "invalid" are implicitly correct and rewarded (or not penalized).
            // Validators who voted "valid" are implicitly incorrect.
            isChange = -int256(parameters[keccak256("CHRONICLE_IS_LOSS_PER_CHALLENGE")]);
        }

        _updateIntegrityScore(chronicle.integrityScore, isChange, _chronicleId);

        emit ValidationFinalized(_chronicleId, _contributionId, isValid, mpGained, isChange);
    }

    function challengeValidation(uint256 _chronicleId, uint256 _contributionId, uint256 _challengerStake) external payable {
        Chronicle storage chronicle = chronicles[_chronicleId];
        if (chronicle.creator == address(0)) {
            revert ChronicleNotFound(_chronicleId);
        }
        Contribution storage contribution = chronicleContributions[_chronicleId][_contributionId];
        if (contribution.contributor == address(0)) {
            revert ContributionNotFound(_chronicleId, _contributionId);
        }
        if (contribution.state != ContributionState.Pending) {
            revert InvalidContributionState(); // Challenge only if pending validation
        }
        // Must be after validation period is over, but before challenge period ends.
        if (block.timestamp < contribution.submittedAt + parameters[keccak256("VALIDATION_PERIOD")]) {
            revert InvalidValidationState(); // Validation period not over
        }
        if (block.timestamp > contribution.submittedAt + parameters[keccak256("VALIDATION_PERIOD")] + parameters[keccak256("CHALLENGE_PERIOD")]) {
            revert InvalidValidationState(); // Challenge period over
        }
        if (contribution.challenger != address(0)) {
            revert ChallengeInProgress(_contributionId);
        }
        if (_challengerStake < parameters[keccak256("MIN_CONTRIBUTION_STAKE")] * 2) { // Challenge stake higher than regular contribution
            revert InsufficientStake(parameters[keccak256("MIN_CONTRIBUTION_STAKE")] * 2, _challengerStake);
        }
        if (msg.value != _challengerStake) {
             revert InsufficientStake(_challengerStake, msg.value);
        }

        contribution.state = ContributionState.Challenged;
        contribution.challenger = msg.sender;
        contribution.challengeStake = _challengerStake;

        emit ChallengeInitiated(_chronicleId, _contributionId, msg.sender, _challengerStake);
    }

    function resolveChallenge(uint256 _chronicleId, uint256 _contributionId, bool _challengerWins) external onlyOwner {
        // This resolution is simplified to onlyOwner. In a real system, this would be
        // a complex process: e.g., via further voting by a larger set of validators,
        // a Schelling game, or an arbitration DAO.
        Chronicle storage chronicle = chronicles[_chronicleId];
        if (chronicle.creator == address(0)) {
            revert ChronicleNotFound(_chronicleId);
        }
        Contribution storage contribution = chronicleContributions[_chronicleId][_contributionId];
        if (contribution.contributor == address(0)) {
            revert ContributionNotFound(_chronicleId, _contributionId);
        }
        if (contribution.state != ContributionState.Challenged) {
            revert NoActiveChallenge();
        }

        contribution.state = ContributionState.ChallengeResolved;
        contribution.validationFinalizedAt = block.timestamp; // Update for stake withdrawal

        int256 isChange = 0;
        uint256 totalForfeitedStake = contribution.stakeAmount + contribution.challengeStake; // Simplified, assuming initial stake is also involved

        if (_challengerWins) {
            // Challenger wins: the initial validation was incorrect.
            // Challenger gets their stake back + a reward from the original contributor's forfeited stake.
            // All validators who voted against the challenger's claim (i.e., for the original, incorrect outcome) are implicitly penalized.
            _awardLegacyFragments(contribution.challenger, parameters[keccak256("LEGACY_FRAGMENT_AWARD_CONTRIBUTION")] * 2); // Higher reward for challenging correctly

            // Reward challenger with their stake + a portion of the original contribution stake
            (bool success, ) = contribution.challenger.call{value: contribution.challengeStake + (contribution.stakeAmount / 2)}(""); // Challenger gets their stake + half of contributor's stake
            require(success, "Challenger reward transfer failed.");

            // Original contributor's remaining stake (if any) could be distributed to correct validators or protocol treasury.
            // For simplicity, the other half of contributor's stake is burned/absorbed by the contract.

            isChange = -int256(parameters[keccak256("CHRONICLE_IS_LOSS_PER_CHALLENGE")]); // Integrity score loss
        } else {
            // Challenger loses: the original validation (or consensus) was correct.
            // Challenger's stake is forfeited.
            // Original contributor (if their contribution was valid) gets their stake back.
            (bool success, ) = contribution.contributor.call{value: contribution.stakeAmount}("");
            require(success, "Contributor stake transfer failed.");

            // Challenger's stake is absorbed by the contract (or distributed to validators, etc.).

            isChange = int256(parameters[keccak256("CHRONICLE_IS_GAIN_PER_VALIDATION")]); // Integrity score gain
            // No LF award here; initial validation awards LF.
        }

        _updateIntegrityScore(chronicle.integrityScore, isChange, _chronicleId);

        // Reset stakes to prevent double withdrawals. For simplicity, they are considered "burnt" or absorbed.
        contribution.stakeAmount = 0;
        contribution.challengeStake = 0;

        emit ChallengeResolved(_chronicleId, _contributionId, _challengerWins);
    }

    // Internal helper for updating integrity score
    function _updateIntegrityScore(uint256 currentScore, int256 change, uint256 _chronicleId) internal {
        int256 newScore = int256(currentScore) + change;
        if (newScore > 1000) {
            newScore = 1000;
        } else if (newScore < 0) {
            newScore = 0;
        }
        chronicles[_chronicleId].integrityScore = uint256(newScore);
    }


    // --- III. Reputation System (Legacy Fragments - Non-transferable ERC20-like) ---

    function getLegacyFragmentBalance(address _user) public view returns (uint256) {
        return legacyFragments[_user];
    }

    function burnLegacyFragments(address _target, uint256 _amount) external onlyOwner {
        // Can be used for penalties, or future redemption mechanisms
        if (legacyFragments[_target] < _amount) {
            revert NotEnoughLegacyFragments(_amount, legacyFragments[_target]);
        }
        legacyFragments[_target] -= _amount;
        emit LegacyFragmentsBurned(_target, _amount);
    }

    function _awardLegacyFragments(address _recipient, uint256 _amount) internal {
        legacyFragments[_recipient] += _amount;
        emit LegacyFragmentsAwarded(_recipient, _amount);
    }

    // --- IV. Funding & Milestones ---

    function fundChronicle(uint256 _chronicleId) external payable {
        Chronicle storage chronicle = chronicles[_chronicleId];
        if (chronicle.creator == address(0)) {
            revert ChronicleNotFound(_chronicleId);
        }
        if (msg.value == 0) {
            revert InsufficientStake(1, 0); // Must send some value
        }

        chronicle.fundsRaised += msg.value;
        emit ChronicleFunded(_chronicleId, msg.sender, msg.value, chronicle.fundsRaised);
    }

    function defineChronicleMilestone(
        uint256 _chronicleId,
        string calldata _description,
        uint256 _payoutPercentage
    ) external onlyChronicleCreator(_chronicleId) {
        Chronicle storage chronicle = chronicles[_chronicleId];
        if (_payoutPercentage == 0 || _payoutPercentage > 100) {
            revert InvalidPayoutPercentage();
        }
        if (chronicle.totalMilestonePayoutPercentage + _payoutPercentage > 100) {
            revert InvalidPayoutPercentage(); // Total payout cannot exceed 100%
        }

        _milestoneIds.increment();
        uint256 newMilestoneId = _milestoneIds.current();

        Milestone storage newMilestone = chronicle.milestones[newMilestoneId];
        newMilestone.id = newMilestoneId;
        newMilestone.description = _description;
        newMilestone.payoutPercentage = _payoutPercentage;
        newMilestone.requested = false;
        newMilestone.approved = false;

        chronicle.totalMilestonePayoutPercentage += _payoutPercentage;

        emit MilestoneDefined(_chronicleId, newMilestoneId, _description, _payoutPercentage);
    }

    function requestMilestonePayout(uint256 _chronicleId, uint256 _milestoneId)
        external
        onlyChronicleCreator(_chronicleId)
    {
        Chronicle storage chronicle = chronicles[_chronicleId];
        Milestone storage milestone = chronicle.milestones[_milestoneId];
        if (milestone.id == 0) {
            revert MilestoneNotFound(_chronicleId, _milestoneId);
        }
        if (milestone.approved) {
            revert UnauthorizedAction(); // Already approved
        }
        if (milestone.requested) {
            revert UnauthorizedAction(); // Already requested
        }
        if (chronicle.fundsRaised < chronicle.fundingGoal) {
            revert FundingGoalNotMet(chronicle.fundsRaised, chronicle.fundingGoal);
        }

        milestone.requested = true;
        milestone.requestedAt = block.timestamp;

        // In a more complex system, this would trigger a governance proposal for approval.
        // For simplicity, we directly allow validators to approve `approveMilestonePayout`.
        emit MilestonePayoutRequested(_chronicleId, _milestoneId);
    }

    function approveMilestonePayout(uint256 _chronicleId, uint256 _milestoneId)
        external
        onlyValidator // This could be extended to a proposal system similar to `executeProposal`
    {
        Chronicle storage chronicle = chronicles[_chronicleId];
        Milestone storage milestone = chronicle.milestones[_milestoneId];
        if (milestone.id == 0) {
            revert MilestoneNotFound(_chronicleId, _milestoneId);
        }
        if (!milestone.requested || milestone.approved) {
            revert UnauthorizedAction(); // Not requested or already approved
        }
        // Add a check for sufficient validators to approve or a voting period
        // For simplicity, a single validator can approve here, but a DAO/multi-sig is better.

        milestone.approved = true;
        milestone.approvedAt = block.timestamp;

        uint256 payoutAmount = (chronicle.fundsRaised * milestone.payoutPercentage) / 100;
        // Transfer funds to the creator
        (bool success, ) = payable(chronicle.creator).call{value: payoutAmount}("");
        require(success, "Milestone payout transfer failed.");

        chronicle.fundsRaised -= payoutAmount; // Deduct from funds raised

        emit MilestonePayoutApproved(_chronicleId, _milestoneId, payoutAmount);
    }


    // --- V. Governance & Parameter Tuning ---

    function proposeChronicleAttributeUpdate(
        uint256 _chronicleId,
        string calldata _newTitle,
        string calldata _newDescription
    ) external {
        if (legacyFragments[msg.sender] < parameters[keccak256("MIN_LF_FOR_VOTING")]) {
            revert NotEnoughLegacyFragments(parameters[keccak256("MIN_LF_FOR_VOTING")], legacyFragments[msg.sender]);
        }
        if (chronicles[_chronicleId].creator == address(0)) {
            revert ChronicleNotFound(_chronicleId);
        }

        _proposalIds.increment();
        uint256 newProposalId = _proposalIds.current();

        Proposal storage newProposal = proposals[newProposalId];
        newProposal.id = newProposalId;
        newProposal.propType = ProposalType.ChronicleAttributeUpdate;
        newProposal.proposer = msg.sender;
        newProposal.targetChronicleId = uint252(_chronicleId); // Cast to smaller type
        newProposal.data = abi.encode(_newTitle, _newDescription);
        newProposal.createdAt = block.timestamp;
        newProposal.votingEndsAt = block.timestamp + parameters[keccak256("PROPOSAL_VOTING_PERIOD")];
        newProposal.requiredLegacyFragments = parameters[keccak256("MIN_LF_FOR_VOTING")];
        newProposal.executed = false;
        newProposal.approved = false;

        emit ProposalCreated(newProposalId, ProposalType.ChronicleAttributeUpdate, msg.sender, _chronicleId, newProposal.votingEndsAt);
    }

    function voteOnProposal(uint256 _proposalId, bool _support) external {
        Proposal storage proposal = proposals[_proposalId];
        if (proposal.id == 0) {
            revert ProposalNotFound(_proposalId);
        }
        if (block.timestamp > proposal.votingEndsAt) {
            revert ProposalNotReadyForExecution(); // Voting period ended
        }
        if (legacyFragments[msg.sender] < proposal.requiredLegacyFragments) {
            revert NotEnoughLegacyFragments(proposal.requiredLegacyFragments, legacyFragments[msg.sender]);
        }
        if (proposal.hasVoted[msg.sender]) {
            revert AlreadyVoted();
        }

        proposal.hasVoted[msg.sender] = true;
        if (_support) {
            proposal.votesFor += legacyFragments[msg.sender]; // Weight vote by LF
        } else {
            proposal.votesAgainst += legacyFragments[msg.sender];
        }

        emit VotedOnProposal(_proposalId, msg.sender, _support);
    }

    function executeProposal(uint256 _proposalId) external {
        Proposal storage proposal = proposals[_proposalId];
        if (proposal.id == 0) {
            revert ProposalNotFound(_proposalId);
        }
        if (proposal.executed) {
            revert ProposalAlreadyExecuted();
        }
        if (block.timestamp <= proposal.votingEndsAt) {
            revert ProposalNotReadyForExecution(); // Voting period not over
        }

        // Determine if proposal passed (e.g., simple majority of LF by vote weight)
        if (proposal.votesFor > proposal.votesAgainst) {
            proposal.approved = true;
            if (proposal.propType == ProposalType.ChronicleAttributeUpdate) {
                (string memory newTitle, string memory newDescription) = abi.decode(proposal.data, (string, string));
                Chronicle storage chronicle = chronicles[proposal.targetChronicleId];
                if (chronicle.creator == address(0)) {
                    revert ChronicleNotFound(proposal.targetChronicleId);
                }
                chronicle.title = newTitle;
                chronicle.description = newDescription;
            }
            // Add more `else if` blocks for other proposal types here
        } else {
            proposal.approved = false; // Proposal failed
        }

        proposal.executed = true;
        emit ProposalExecuted(_proposalId, proposal.approved);
    }

    function setChronoForgeParameter(bytes32 _paramKey, uint256 _value) external onlyOwner {
        if (_paramKey == bytes32(0)) {
            revert InvalidParameter();
        }
        parameters[_paramKey] = _value;
        emit ParameterSet(_paramKey, _value);
    }

    // --- VI. Stake Management & Withdrawals ---

    function withdrawContributionStake(uint256 _chronicleId, uint256 _contributionId) external {
        Chronicle storage chronicle = chronicles[_chronicleId];
        if (chronicle.creator == address(0)) {
            revert ChronicleNotFound(_chronicleId);
        }
        Contribution storage contribution = chronicleContributions[_chronicleId][_contributionId];
        if (contribution.contributor == address(0) || contribution.contributor != msg.sender) {
            revert ContributionNotFound(_chronicleId, _contributionId);
        }
        if (contribution.state != ContributionState.Validated) { // Only withdraw if successfully validated
            revert WithdrawStakeLocked();
        }
        if (block.timestamp < contribution.validationFinalizedAt + parameters[keccak256("UNBONDING_PERIOD")]) {
            revert UnbondingPeriodNotOver(contribution.validationFinalizedAt + parameters[keccak256("UNBONDING_PERIOD")]);
        }
        if (contribution.stakeAmount == 0) { // Already withdrawn or forfeited
            revert WithdrawStakeLocked();
        }

        uint256 amountToWithdraw = contribution.stakeAmount;
        contribution.stakeAmount = 0; // Prevent double withdrawal
        (bool success, ) = payable(msg.sender).call{value: amountToWithdraw}("");
        require(success, "Contribution stake withdrawal failed.");

        emit StakeWithdrawn(msg.sender, amountToWithdraw);
    }

    function withdrawValidatorStake() external onlyValidator {
        Validator storage validator = validators[msg.sender];

        // If validator is active and not initiated unbonding, start it.
        if (validator.isActive && validator.unbondingPeriodEnd == 0) {
             validator.unbondingPeriodEnd = block.timestamp + parameters[keccak256("UNBONDING_PERIOD")];
             // In a real system, you'd mark validator as inactive for new proposals immediately.
        }

        if (block.timestamp < validator.unbondingPeriodEnd) {
            revert UnbondingPeriodNotOver(validator.unbondingPeriodEnd);
        }

        // Potential check for active challenges or pending validations.
        // This is complex due to mapping iteration. For simplicity, we assume validator
        // is responsible for ensuring no active engagements or system design guarantees.
        // In a production system, this would require careful state tracking (e.g., a list of active `_contributionIds` per validator).

        validator.isActive = false; // Mark as inactive
        uint256 amountToWithdraw = validator.totalStake;
        validator.totalStake = 0; // Reset stake
        validator.unbondingPeriodEnd = 0; // Reset unbonding state

        (bool success, ) = payable(msg.sender).call{value: amountToWithdraw}("");
        require(success, "Validator stake withdrawal failed.");

        emit StakeWithdrawn(msg.sender, amountToWithdraw);
    }


    // --- Internal/Helper Functions ---

    function _phaseToString(ChroniclePhase _phase) internal pure returns (string memory) {
        if (_phase == ChroniclePhase.Seed) return "Seed";
        if (_phase == ChroniclePhase.Growth) return "Growth";
        if (_phase == ChroniclePhase.Mature) return "Mature";
        if (_phase == ChroniclePhase.Legacy) return "Legacy";
        return "Unknown";
    }

    // Fallback function to receive ETH
    receive() external payable {}
}


// --- Base64 Library (for on-chain metadata) ---
// This library is included directly to ensure the contract is self-contained.
// Source: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Base64.sol (adapted slightly for direct inclusion)
library Base64 {
    string internal constant TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    function encode(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return "";

        // load the table into memory
        string memory table = TABLE;

        // calculate output length: 3 bytes of data => 4 bytes of base64
        uint256 encodedLen = 4 * ((data.length + 2) / 3);

        // allocate output buffer with space for base64 characters and padding
        bytes memory result = new bytes(encodedLen);

        // join data in chunks of 3 bytes, split into 4 characters
        for (uint256 i = 0; i < data.length; i += 3) {
            uint256 chunk;
            bytes1 b1 = data[i];
            bytes1 b2 = i + 1 < data.length ? data[i + 1] : 0;
            bytes1 b3 = i + 2 < data.length ? data[i + 2] : 0;

            chunk = uint256(uint8(b1) << 16) | (uint256(uint8(b2)) << 8) | uint256(uint8(b3));

            // Set the 2 least significant bits to zero (to avoid out of bounds in table[char])
            // and shift right by 6 to get the character.
            result[i / 3 * 4] = bytes(table)[(chunk >> 18) & 0x3F];
            result[i / 3 * 4 + 1] = bytes(table)[(chunk >> 12) & 0x3F];
            result[i / 3 * 4 + 2] = bytes(table)[(chunk >> 6) & 0x3F];
            result[i / 3 * 4 + 3] = bytes(table)[chunk & 0x3F];
        }

        // Add padding
        if (data.length % 3 == 1) {
            result[result.length - 2] = "=";
        }
        if (data.length % 3 == 2) {
            result[result.length - 1] = "=";
        }

        return string(result);
    }
}
```