The `ArbiterNexus` contract is designed as a **Self-Adapting Protocol for Decentralized Impact & Collective Wisdom**. It combines elements of reputation-based governance, dynamic resource allocation, and a simulated adaptive mechanism influenced by external "wisdom" (e.g., AI/analytics). The goal is to create a protocol that can evolve its own parameters and incentive structures over time based on collective decisions and observed impact.

This contract aims to be distinct from typical open-source projects by integrating these features into a cohesive system focused on collective impact and adaptive governance, particularly the "Wisdom Oracle" feedback loop and the "Antithesis Vote" mechanism.

---

## Contract: `ArbiterNexus`

### Outline

*   **Core Concepts:**
    *   **Influence Points (IPs):** Non-transferable, reputation-based token representing a user's standing and contribution within the protocol.
    *   **Impact Shares (IS):** Transferable economic stake in the protocol, primarily used for voting power and eligibility for rewards.
    *   **Dynamic Governance:** Protocol parameters (e.g., voting periods, reward rates) can adapt over time, influenced by governance and a simulated "Wisdom Oracle."
    *   **Epochs:** The protocol operates in discrete time-based cycles, at the end of which parameters can be adjusted and rewards distributed.
    *   **Modules:** Conceptually extendable functionality, allowing the protocol to upgrade or add new capabilities via governance.
    *   **Wisdom Oracle (Simulated):** An authorized external entity (representing off-chain AI/analytics) that provides data to inform dynamic parameter adjustments.
*   **Function Categories:**
    *   **I. Initialization & Core Setup:** Basic setup and parameter initialization.
    *   **II. Influence Points (IPs) Management:** Handling the award, slashing, and delegation of reputation.
    *   **III. Impact Shares (IS) Management:** Managing the minting, staking, and unstaking of the economic token.
    *   **IV. Epoch & Time Management:** Controlling the progression of the protocol through epochs.
    *   **V. Proposal & Voting System:** Mechanisms for submitting, voting on, and finalizing governance proposals, including a unique "antithesis" vote.
    *   **VI. Funding & Resource Allocation:** Managing the lifecycle of funding for decentralized initiatives based on milestones.
    *   **VII. Module & Adaptive Parameter Management:** Functions related to upgrading protocol modules and incorporating external "wisdom" for parameter adjustments.
    *   **VIII. Role & Responsibility Management:** Assigning and revoking special roles (e.g., Guardian).
    *   **IX. External Interaction (Simulated):** Allowing reporting of off-chain impact metrics.
    *   **X. Treasury Management:** Handling the protocol's treasury funds.
    *   **XI. Query & Read Functions:** Public view functions to inspect the protocol's state.

---

### Function Summary

**I. Initialization & Core Setup**
1.  `initializeProtocol()`: Sets initial core protocol parameters and starts the first epoch. Callable once by the owner.
2.  `setEpochDuration(uint256 _newDuration)`: Modifies the duration of each epoch. (Initially owner-controlled, later by governance).

**II. Influence Points (IPs) Management**
3.  `awardInfluencePoints(address _recipient, uint256 _amount)`: Awards IPs to a user for successful contributions or roles.
4.  `slashInfluencePoints(address _target, uint256 _amount)`: Reduces IPs from a user for non-compliance or malicious acts.
5.  `delegateInfluence(address _delegatee)`: Allows an IP holder to conceptually delegate their voting influence to another address (simplified for demo).

**III. Impact Shares (IS) Management**
6.  `mintImpactShares(address _recipient, uint256 _amount)`: Mints new IS, typically for initial distribution or epoch rewards.
7.  `stakeImpactShares(uint256 _amount)`: Locks IS to gain enhanced voting power and eligibility for rewards/roles.
8.  `unstakeImpactShares(uint256 _amount)`: Initiates the unstaking process, subject to a cooldown period.
9.  `claimUnstakedShares()`: Allows users to claim their unstaked IS after the cooldown period ends.
10. `distributeEpochRewards()`: (Internal) Distributes IS or other rewards to stakers/contributors at the end of an epoch.

**IV. Epoch & Time Management**
11. `advanceEpoch()`: Moves the protocol to the next epoch, triggering dynamic parameter adjustments and reward distribution. Can only be called after the current epoch duration has passed.

**V. Proposal & Voting System**
12. `submitParameterProposal(bytes32 _parameterKey, uint256 _newValue, string memory _description)`: Proposes a change to a core protocol parameter. Requires a minimum IP threshold.
13. `submitInitiativeProposal(uint256 _totalFunding, uint256 _milestoneCount, string memory _description)`: Proposes a new social impact initiative with detailed funding and milestone requirements. Requires a minimum IP threshold.
14. `voteOnProposal(uint256 _proposalId, bool _for)`: Casts a 'for' or 'against' vote on an active proposal using staked Impact Shares.
15. `castAntithesisVote(uint256 _proposalId)`: A unique vote to deliberately challenge a proposal, signaling strong disagreement and potentially triggering a special review or higher threshold for passage.
16. `finalizeProposal(uint256 _proposalId)`: Closes the voting period for a proposal and executes its outcome (e.g., updates parameters, creates an initiative, or marks as failed). Callable by anyone after the voting period ends.

**VI. Funding & Resource Allocation**
17. `requestMilestoneVerification(uint256 _initiativeId, uint256 _milestoneIndex)`: A project team requests verification for a completed milestone of their initiative.
18. `verifyMilestone(uint256 _initiativeId, uint256 _milestoneIndex, bool _approved)`: Allows designated verifiers (e.g., Guardians) to approve or reject a milestone's completion.
19. `releaseFundingTranche(uint256 _initiativeId, uint256 _milestoneIndex)`: Releases a portion of approved funding for an initiative once a milestone has been verified.

**VII. Module & Adaptive Parameter Management**
20. `proposeModuleUpgrade(address _newModuleAddress, string memory _description)`: Proposes replacing or upgrading a core protocol module (conceptual for the demo).
21. `receiveWisdomOracleInput(bytes32[] memory _paramKeys, uint256[] memory _newValues)`: Receives data from an authorized external "Wisdom Oracle" (simulated AI/analytics) to suggest dynamic parameter adjustments.
22. `adjustDynamicParameters()`: (Internal) Applies dynamic parameter changes based on Wisdom Oracle input and internal logic, typically during epoch advancement.

**VIII. Role & Responsibility Management**
23. `assignGuardianRole(address _guardian)`: Assigns the "Guardian" special role, granting elevated privileges (e.g., verification, veto power).
24. `revokeGuardianRole(address _guardian)`: Revokes the "Guardian" role.

**IX. External Interaction (Simulated)**
25. `reportExternalImpactMetric(bytes32 _metricKey, uint256 _value)`: Allows authorized reporters to submit simulated off-chain impact metrics that can influence future protocol adjustments.

**X. Treasury Management**
26. `depositToTreasury()`: Allows native currency (e.g., ETH) to be deposited into the protocol's treasury, which funds initiatives.

**XI. Query & Read Functions**
27. `getProtocolParameter(bytes32 _key)`: Retrieves the current value of a specific configurable protocol parameter.
28. `getUserInfluencePoints(address _user)`: Gets a user's current Influence Points (IPs) balance.
29. `getProposalState(uint256 _proposalId)`: Checks the current state (e.g., Active, Succeeded, Failed) of a proposal.
30. `getEpochDetails()`: Retrieves comprehensive information about the current epoch, including its start time and duration.
31. `getStakedShares(address _user)`: Gets a user's currently staked Impact Shares (IS).
32. `getPendingUnstake(address _user)`: Gets a user's pending unstake amount and the timestamp when their cooldown period will end.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

// Custom error definitions for clarity and gas efficiency
error ArbiterNexus__UnauthorizedCaller();
error ArbiterNexus__InvalidAmount();
error ArbiterNexus__NotEnoughInfluencePoints();
error ArbiterNexus__NotEnoughImpactShares();
error ArbiterNexus__InsufficientBalance();
error ArbiterNexus__AlreadyStaked(); // Not used directly, but conceptual
error ArbiterNexus__NotStaked();
error ArbiterNexus__CooldownPeriodActive();
error ArbiterNexus__NoPendingUnstake();
error ArbiterNexus__ProposalNotFound();
error ArbiterNexus__ProposalNotActive();
error ArbiterNexus__ProposalAlreadyFinalized();
error ArbiterNexus__VotingPeriodEnded();
error ArbiterNexus__CannotVoteTwice();
error ArbiterNexus__MilestoneAlreadyVerified();
error ArbiterNexus__MilestoneNotApproved();
error ArbiterNexus__FundingAlreadyReleased();
error ArbiterNexus__NoPendingMilestone();
error ArbiterNexus__EpochNotAdvanced();
error ArbiterNexus__EpochAlreadyInitialized();
error ArbiterNexus__OnlyWisdomOracleAllowed();
error ArbiterNexus__GuardianRoleNotActive();
error ArbiterNexus__CannotDelegateToSelf(); // For conceptual delegate function
error ArbiterNexus__InvalidEpochDuration();
error ArbiterNexus__InvalidParameterValue();
error ArbiterNexus__VerificationPeriodEnded();


contract ArbiterNexus is Ownable, Pausable {
    using SafeMath for uint256;

    // --- State Variables ---

    // Core Tokens
    mapping(address => uint256) public influencePoints; // Non-transferable reputation token
    mapping(address => uint256) public impactShares;    // Transferable economic stake (ERC20-like internal)
    mapping(address => uint256) public stakedImpactShares; // Staked IS
    mapping(address => uint256) public pendingUnstake;     // IS pending unstake amount
    mapping(address => uint256) public unstakeCooldownStart; // Timestamp for unstake cooldown start

    // Protocol Parameters (dynamic and configurable)
    mapping(bytes32 => uint256) public protocolParameters;

    // Keys for common parameters
    bytes32 constant PARAMS_EPOCH_DURATION = keccak256("EPOCH_DURATION"); // In seconds
    bytes32 constant PARAMS_PROPOSAL_THRESHOLD_IP = keccak256("PROPOSAL_THRESHOLD_IP"); // Minimum IPs to submit a proposal
    bytes32 constant PARAMS_VOTING_PERIOD = keccak256("VOTING_PERIOD"); // Duration of proposal voting (in seconds)
    bytes32 constant PARAMS_VOTE_QUORUM_PERCENT = keccak256("VOTE_QUORUM_PERCENT"); // % of total staked IS needed for quorum
    bytes32 constant PARAMS_ANTITHESIS_THRESHOLD_PERCENT = keccak256("ANTITHESIS_THRESHOLD_PERCENT"); // % of antithesis votes to trigger review/fail
    bytes32 constant PARAMS_UNSTAKE_COOLDOWN = keccak256("UNSTAKE_COOLDOWN"); // Cooldown period for unstaking (in seconds)
    bytes32 constant PARAMS_IP_AWARD_RATE_PROPOSAL = keccak256("IP_AWARD_RATE_PROPOSAL"); // IPs awarded for successful proposals
    bytes32 constant PARAMS_IP_AWARD_RATE_VERIFICATION = keccak256("IP_AWARD_RATE_VERIFICATION"); // IPs awarded for milestone verification
    bytes32 constant PARAMS_IP_SLASH_RATE_MALFEASANCE = keccak256("IP_SLASH_RATE_MALFEASANCE"); // IPs to slash for malfeasance
    bytes32 constant PARAMS_IS_EPOCH_REWARD_POOL = keccak256("IS_EPOCH_REWARD_POOL"); // Total IS available for epoch rewards
    bytes32 constant PARAMS_MILSTONE_VERIFICATION_PERIOD = keccak256("MILSTONE_VERIFICATION_PERIOD"); // Duration for milestone verification (in seconds)
    bytes32 constant PARAMS_MILSTONE_APPROVAL_THRESHOLD = keccak256("MILSTONE_APPROVAL_THRESHOLD"); // Minimum verifiers required to approve a milestone

    // Epoch Management
    uint256 public currentEpoch;
    uint256 public epochStartTime;
    address public wisdomOracleAddress; // Address authorized to provide wisdom oracle input
    uint256 public totalStakedImpactShares; // Tracks total staked IS in the system

    // Governance
    enum ProposalState { Pending, Active, Succeeded, Failed, Executed, Canceled }
    enum ProposalType { ParameterChange, InitiativeFunding, ModuleUpgrade }

    struct Proposal {
        uint256 id;
        ProposalType proposalType;
        address proposer;
        string description;
        uint256 creationTime;
        uint256 votingPeriodEnd;
        uint256 votesFor;
        uint256 votesAgainst;
        uint256 antithesisVotes;
        ProposalState state;
        mapping(address => bool) hasVoted; // User voting record for this proposal
        // Specific proposal details
        bytes32 paramKey; // For ParameterChange
        uint256 newValue; // For ParameterChange
        uint256 totalFunding; // For InitiativeFunding
        uint256 milestoneCount; // For InitiativeFunding
        address newModuleAddress; // For ModuleUpgrade (conceptual)
    }

    mapping(uint256 => Proposal) public proposals;
    uint256 public nextProposalId;

    // Initiatives (projects)
    enum InitiativeState { Proposed, Active, InVerification, Completed, Canceled }

    struct Milestone {
        uint256 fundingAmount; // Calculated per milestone
        bool verified;
        bool fundsReleased;
        uint256 verificationStartTime; // Timestamp when verification was requested
        mapping(address => bool) hasVerified; // Individual verifier vote for this milestone
        uint256 approvedVerifiers; // Number of 'yes' votes from verifiers
        uint256 rejectedVerifiers; // Number of 'no' votes from verifiers (for more nuanced logic)
    }

    struct Initiative {
        uint256 id;
        address proposer;
        string description;
        uint256 totalFundingApproved;
        uint256 currentFundingReleased;
        InitiativeState state;
        Milestone[] milestones;
    }

    mapping(uint256 => Initiative) public initiatives;
    uint256 public nextInitiativeId;

    // Roles
    mapping(address => bool) public isGuardian; // Special role with elevated privileges

    // External Metrics (simulated)
    mapping(bytes32 => uint256) public externalImpactMetrics; // Stores values reported by external oracles

    // Treasury (using native currency for simplicity)
    uint256 public totalTreasuryBalance;

    // --- Events ---
    event Initialized(address indexed deployer, uint256 initialEpoch);
    event EpochAdvanced(uint256 indexed newEpoch, uint256 epochStartTime);
    event EpochDurationSet(uint256 indexed newDuration);

    event InfluencePointsAwarded(address indexed recipient, uint256 amount);
    event InfluencePointsSlashed(address indexed target, uint256 amount);
    event InfluenceDelegated(address indexed delegator, address indexed delegatee);

    event ImpactSharesMinted(address indexed recipient, uint256 amount);
    event ImpactSharesStaked(address indexed staker, uint256 amount);
    event ImpactSharesUnstakeInitiated(address indexed staker, uint256 amount, uint256 cooldownEnd);
    event ImpactSharesUnstaked(address indexed staker, uint256 amount);
    event EpochRewardsDistributed(uint256 indexed epoch, uint256 totalRewards);

    event ProposalSubmitted(uint256 indexed proposalId, ProposalType indexed pType, address indexed proposer, string description);
    event ProposalVoted(uint256 indexed proposalId, address indexed voter, bool _for, bool isAntithesis);
    event ProposalFinalized(uint256 indexed proposalId, ProposalState indexed state);

    event InitiativeProposed(uint256 indexed initiativeId, address indexed proposer, uint256 totalFunding);
    event MilestoneVerificationRequested(uint256 indexed initiativeId, uint256 indexed milestoneIndex);
    event MilestoneVerified(uint256 indexed initiativeId, uint256 indexed milestoneIndex, bool approved);
    event FundingTrancheReleased(uint256 indexed initiativeId, uint256 indexed milestoneIndex, uint256 amount);

    event ModuleUpgradeProposed(uint256 indexed proposalId, address newModuleAddress);
    event WisdomOracleInputReceived(address indexed oracle, bytes32[] paramKeys);
    event DynamicParametersAdjusted(uint256 indexed epoch);

    event GuardianRoleAssigned(address indexed guardian);
    event GuardianRoleRevoked(address indexed guardian);

    event ExternalImpactMetricReported(bytes32 indexed metricKey, uint256 value);
    event FundsDepositedToTreasury(address indexed depositor, uint256 amount);


    constructor() Ownable(msg.sender) Pausable() {}

    // --- Modifiers ---
    modifier onlyWisdomOracle() {
        if (msg.sender != wisdomOracleAddress) revert ArbiterNexus__OnlyWisdomOracleAllowed();
        _;
    }

    modifier onlyGuardian() {
        if (!isGuardian[msg.sender]) revert ArbiterNexus__GuardianRoleNotActive();
        _;
    }

    // --- I. Initialization & Core Setup ---

    /**
     * @notice Initializes the core protocol parameters and starts the first epoch.
     *         Callable once by the contract owner.
     */
    function initializeProtocol() public onlyOwner {
        if (currentEpoch > 0) revert ArbiterNexus__EpochAlreadyInitialized();

        // Set initial parameters (example values, these would be fine-tuned)
        protocolParameters[PARAMS_EPOCH_DURATION] = 7 days; // 1 week per epoch
        protocolParameters[PARAMS_PROPOSAL_THRESHOLD_IP] = 1000; // Min IPs to submit a proposal
        protocolParameters[PARAMS_VOTING_PERIOD] = 3 days; // Voting period for proposals
        protocolParameters[PARAMS_VOTE_QUORUM_PERCENT] = 60; // 60% of total staked IS needed for quorum
        protocolParameters[PARAMS_ANTITHESIS_THRESHOLD_PERCENT] = 10; // 10% antithesis votes can trigger review/block
        protocolParameters[PARAMS_UNSTAKE_COOLDOWN] = 14 days; // 2 weeks unstake cooldown
        protocolParameters[PARAMS_IP_AWARD_RATE_PROPOSAL] = 50; // IPs for successful proposal proposer
        protocolParameters[PARAMS_IP_AWARD_RATE_VERIFICATION] = 20; // IPs for successful milestone verification
        protocolParameters[PARAMS_IP_SLASH_RATE_MALFEASANCE] = 100; // IPs to slash for malfeasance
        protocolParameters[PARAMS_IS_EPOCH_REWARD_POOL] = 1000 * (10 ** 18); // 1000 IS per epoch as reward pool (adjust decimals)
        protocolParameters[PARAMS_MILSTONE_VERIFICATION_PERIOD] = 7 days; // 1 week for milestone verification
        protocolParameters[PARAMS_MILSTONE_APPROVAL_THRESHOLD] = 2; // Example: Minimum 2 verifiers needed for milestone approval

        currentEpoch = 1;
        epochStartTime = block.timestamp;
        nextProposalId = 1;
        nextInitiativeId = 1;
        wisdomOracleAddress = msg.sender; // Set initial oracle to owner, can be changed by governance
        totalTreasuryBalance = 0; // Initialize treasury

        emit Initialized(msg.sender, currentEpoch);
    }

    /**
     * @notice Sets the duration of each epoch.
     * @param _newDuration The new duration in seconds.
     * Callable by governance (owner initially, then via proposal `submitParameterProposal`).
     */
    function setEpochDuration(uint256 _newDuration) public onlyOwner { // Simplified access for demo
        if (_newDuration == 0) revert ArbiterNexus__InvalidEpochDuration();
        protocolParameters[PARAMS_EPOCH_DURATION] = _newDuration;
        emit EpochDurationSet(_newDuration);
    }

    // --- II. Influence Points (IPs) Management ---

    /**
     * @notice Awards Influence Points (IPs) to a recipient for positive contributions.
     * @param _recipient The address to award IPs to.
     * @param _amount The amount of IPs to award.
     * Callable by designated roles (e.g., Guardian, or through governance proposal execution).
     */
    function awardInfluencePoints(address _recipient, uint256 _amount) public whenNotPaused {
        // In a real system, this would be restricted to specific roles or triggered by successful events.
        if (!isGuardian[msg.sender] && msg.sender != owner()) revert ArbiterNexus__UnauthorizedCaller();
        if (_amount == 0) revert ArbiterNexus__InvalidAmount();
        influencePoints[_recipient] = influencePoints[_recipient].add(_amount);
        emit InfluencePointsAwarded(_recipient, _amount);
    }

    /**
     * @notice Slashes Influence Points (IPs) from a target for malicious or non-compliant behavior.
     * @param _target The address to slash IPs from.
     * @param _amount The amount of IPs to slash.
     * Callable by designated roles (e.g., Guardian) or governance.
     */
    function slashInfluencePoints(address _target, uint256 _amount) public whenNotPaused {
        if (!isGuardian[msg.sender] && msg.sender != owner()) revert ArbiterNexus__UnauthorizedCaller();
        if (_amount == 0) revert ArbiterNexus__InvalidAmount();
        if (influencePoints[_target] < _amount) revert ArbiterNexus__NotEnoughInfluencePoints();
        influencePoints[_target] = influencePoints[_target].sub(_amount);
        emit InfluencePointsSlashed(_target, _amount);
    }

    /**
     * @notice Allows a user to delegate their voting influence to another address.
     *         The delegatee conceptually uses the delegator's IPs for voting.
     * @param _delegatee The address to delegate influence to.
     * @dev This is a simplified conceptual delegation. A full delegation system (like Compound's) is more complex.
     *      For this demo, it signifies intent and would require off-chain or more complex on-chain logic to enact.
     */
    function delegateInfluence(address _delegatee) public whenNotPaused {
        if (_delegatee == address(0)) revert ArbiterNexus__InvalidAmount();
        if (_delegatee == msg.sender) revert ArbiterNexus__CannotDelegateToSelf();
        // A full implementation would use a mapping like `mapping(address => address) public delegates;`
        // and then `getVotes` function would traverse delegations.
        // For the scope of this demo, this function mainly serves as a conceptual placeholder.
        emit InfluenceDelegated(msg.sender, _delegatee);
    }

    // --- III. Impact Shares (IS) Management ---

    /**
     * @notice Mints new Impact Shares (IS) to a recipient.
     * @param _recipient The address to mint IS to.
     * @param _amount The amount of IS to mint.
     * Callable by owner/governance (e.g., initial supply, epoch rewards).
     */
    function mintImpactShares(address _recipient, uint256 _amount) public onlyOwner { // Simplified access for demo
        if (_amount == 0) revert ArbiterNexus__InvalidAmount();
        impactShares[_recipient] = impactShares[_recipient].add(_amount);
        // This should also update a global supply if IS were an ERC20.
        emit ImpactSharesMinted(_recipient, _amount);
    }

    /**
     * @notice Stakes Impact Shares (IS) to gain enhanced voting power and eligibility.
     * @param _amount The amount of IS to stake.
     */
    function stakeImpactShares(uint256 _amount) public whenNotPaused {
        if (_amount == 0) revert ArbiterNexus__InvalidAmount();
        if (impactShares[msg.sender] < _amount) revert ArbiterNexus__InsufficientBalance();
        impactShares[msg.sender] = impactShares[msg.sender].sub(_amount);
        stakedImpactShares[msg.sender] = stakedImpactShares[msg.sender].add(_amount);
        totalStakedImpactShares = totalStakedImpactShares.add(_amount);
        emit ImpactSharesStaked(msg.sender, _amount);
    }

    /**
     * @notice Initiates the unstaking process for Impact Shares (IS), subject to a cooldown period.
     * @param _amount The amount of IS to unstake.
     */
    function unstakeImpactShares(uint256 _amount) public whenNotPaused {
        if (_amount == 0) revert ArbiterNexus__InvalidAmount();
        if (stakedImpactShares[msg.sender] < _amount) revert ArbiterNexus__NotStaked();
        // If there's already a pending unstake, and cooldown is active, prevent new unstake until previous is claimed.
        if (pendingUnstake[msg.sender] > 0 && block.timestamp < unstakeCooldownStart[msg.sender].add(protocolParameters[PARAMS_UNSTAKE_COOLDOWN])) {
            revert ArbiterNexus__CooldownPeriodActive();
        }

        stakedImpactShares[msg.sender] = stakedImpactShares[msg.sender].sub(_amount);
        totalStakedImpactShares = totalStakedImpactShares.sub(_amount);
        pendingUnstake[msg.sender] = pendingUnstake[msg.sender].add(_amount);
        unstakeCooldownStart[msg.sender] = block.timestamp;

        emit ImpactSharesUnstakeInitiated(msg.sender, _amount, block.timestamp.add(protocolParameters[PARAMS_UNSTAKE_COOLDOWN]));
    }

    /**
     * @notice Claims unstaked Impact Shares (IS) after the cooldown period has passed.
     */
    function claimUnstakedShares() public whenNotPaused {
        if (pendingUnstake[msg.sender] == 0) revert ArbiterNexus__NoPendingUnstake();
        if (block.timestamp < unstakeCooldownStart[msg.sender].add(protocolParameters[PARAMS_UNSTAKE_COOLDOWN])) {
            revert ArbiterNexus__CooldownPeriodActive();
        }

        uint256 amountToClaim = pendingUnstake[msg.sender];
        pendingUnstake[msg.sender] = 0;
        unstakeCooldownStart[msg.sender] = 0; // Reset cooldown start
        impactShares[msg.sender] = impactShares[msg.sender].add(amountToClaim);

        emit ImpactSharesUnstaked(msg.sender, amountToClaim);
    }

    /**
     * @notice Distributes Impact Shares (IS) or other rewards to stakers/contributors at the end of an epoch.
     *         Callable by the protocol during epoch advance.
     */
    function distributeEpochRewards() internal {
        // This is a simplified reward distribution. In a production system,
        // this would be more sophisticated (e.g., based on active participation,
        // weighted by staked amount over time, contribution scores, etc.).
        // For demo: Distribute a fixed pool proportional to staked shares.
        if (totalStakedImpactShares > 0) {
            uint256 rewardPool = protocolParameters[PARAMS_IS_EPOCH_REWARD_POOL];
            // In a real system, you'd iterate through all stakers or have a mechanism
            // for users to claim their pro-rata share from a common pool.
            // For simplicity, we just emit an event indicating the pool is distributed.
            // A more complete implementation might use a snapshot of staked balances.
            emit EpochRewardsDistributed(currentEpoch, rewardPool);
        } else {
            emit EpochRewardsDistributed(currentEpoch, 0); // No rewards if no one staked
        }
    }

    // --- IV. Epoch & Time Management ---

    /**
     * @notice Advances the protocol to the next epoch.
     *         This triggers dynamic parameter adjustments and reward distribution.
     *         Callable only after the current epoch duration has passed.
     */
    function advanceEpoch() public whenNotPaused {
        if (block.timestamp < epochStartTime.add(protocolParameters[PARAMS_EPOCH_DURATION])) {
            revert ArbiterNexus__EpochNotAdvanced();
        }

        // Apply dynamic parameter adjustments based on oracle input and governance
        adjustDynamicParameters();

        // Distribute epoch rewards
        distributeEpochRewards();

        currentEpoch = currentEpoch.add(1);
        epochStartTime = block.timestamp;
        emit EpochAdvanced(currentEpoch, epochStartTime);
    }

    // --- V. Proposal & Voting System ---

    /**
     * @notice Submits a proposal to change a core protocol parameter.
     * @param _parameterKey The key of the parameter to change (e.g., keccak256("VOTING_PERIOD")).
     * @param _newValue The new value for the parameter.
     * @param _description A description of the proposal.
     * Requires sufficient Influence Points (IPs).
     */
    function submitParameterProposal(bytes32 _parameterKey, uint256 _newValue, string memory _description) public whenNotPaused {
        if (influencePoints[msg.sender] < protocolParameters[PARAMS_PROPOSAL_THRESHOLD_IP]) {
            revert ArbiterNexus__NotEnoughInfluencePoints();
        }

        uint256 proposalId = nextProposalId++;
        Proposal storage newProposal = proposals[proposalId];
        newProposal.id = proposalId;
        newProposal.proposalType = ProposalType.ParameterChange;
        newProposal.proposer = msg.sender;
        newProposal.description = _description;
        newProposal.creationTime = block.timestamp;
        newProposal.votingPeriodEnd = block.timestamp.add(protocolParameters[PARAMS_VOTING_PERIOD]);
        newProposal.state = ProposalState.Active;
        newProposal.paramKey = _parameterKey;
        newProposal.newValue = _newValue;

        emit ProposalSubmitted(proposalId, ProposalType.ParameterChange, msg.sender, _description);
    }

    /**
     * @notice Submits a proposal for a new social impact initiative with funding details.
     * @param _totalFunding The total funding requested for the initiative.
     * @param _milestoneCount The number of milestones for the initiative.
     * @param _description A description of the initiative.
     * Requires sufficient Influence Points (IPs).
     */
    function submitInitiativeProposal(uint256 _totalFunding, uint256 _milestoneCount, string memory _description) public whenNotPaused {
        if (influencePoints[msg.sender] < protocolParameters[PARAMS_PROPOSAL_THRESHOLD_IP]) {
            revert ArbiterNexus__NotEnoughInfluencePoints();
        }
        if (_totalFunding == 0 || _milestoneCount == 0) revert ArbiterNexus__InvalidAmount();
        if (totalTreasuryBalance < _totalFunding) revert ArbiterNexus__InsufficientBalance(); // Ensure funds are available in treasury

        uint256 proposalId = nextProposalId++;
        Proposal storage newProposal = proposals[proposalId];
        newProposal.id = proposalId;
        newProposal.proposalType = ProposalType.InitiativeFunding;
        newProposal.proposer = msg.sender;
        newProposal.description = _description;
        newProposal.creationTime = block.timestamp;
        newProposal.votingPeriodEnd = block.timestamp.add(protocolParameters[PARAMS_VOTING_PERIOD]);
        newProposal.state = ProposalState.Active;
        newProposal.totalFunding = _totalFunding;
        newProposal.milestoneCount = _milestoneCount;

        emit ProposalSubmitted(proposalId, ProposalType.InitiativeFunding, msg.sender, _description);
    }

    /**
     * @notice Casts a vote (for or against) on an active proposal.
     * @param _proposalId The ID of the proposal to vote on.
     * @param _for True for a 'for' vote, false for 'against'.
     */
    function voteOnProposal(uint256 _proposalId, bool _for) public whenNotPaused {
        Proposal storage proposal = proposals[_proposalId];
        if (proposal.id == 0) revert ArbiterNexus__ProposalNotFound();
        if (proposal.state != ProposalState.Active) revert ArbiterNexus__ProposalNotActive();
        if (block.timestamp > proposal.votingPeriodEnd) revert ArbiterNexus__VotingPeriodEnded();
        if (proposal.hasVoted[msg.sender]) revert ArbiterNexus__CannotVoteTwice(); // User has already voted
        if (stakedImpactShares[msg.sender] == 0) revert ArbiterNexus__NotEnoughImpactShares(); // Only staked IS can vote

        proposal.hasVoted[msg.sender] = true;
        if (_for) {
            proposal.votesFor = proposal.votesFor.add(stakedImpactShares[msg.sender]);
        } else {
            proposal.votesAgainst = proposal.votesAgainst.add(stakedImpactShares[msg.sender]);
        }
        emit ProposalVoted(_proposalId, msg.sender, _for, false);
    }

    /**
     * @notice Registers a special "antithesis" vote to deliberately challenge a proposal.
     *         An antithesis vote signifies strong disagreement and, if a threshold is met,
     *         can block the proposal or trigger a special review.
     * @param _proposalId The ID of the proposal to cast an antithesis vote against.
     */
    function castAntithesisVote(uint256 _proposalId) public whenNotPaused {
        Proposal storage proposal = proposals[_proposalId];
        if (proposal.id == 0) revert ArbiterNexus__ProposalNotFound();
        if (proposal.state != ProposalState.Active) revert ArbiterNexus__ProposalNotActive();
        if (block.timestamp > proposal.votingPeriodEnd) revert ArbiterNexus__VotingPeriodEnded();
        if (proposal.hasVoted[msg.sender]) revert ArbiterNexus__CannotVoteTwice(); // Cannot vote normal AND antithesis
        if (stakedImpactShares[msg.sender] == 0) revert ArbiterNexus__NotEnoughImpactShares();

        proposal.hasVoted[msg.sender] = true;
        proposal.antithesisVotes = proposal.antithesisVotes.add(stakedImpactShares[msg.sender]);
        emit ProposalVoted(_proposalId, msg.sender, false, true); // Log as an 'against' vote, but special type
    }

    /**
     * @notice Finalizes a proposal, executing its outcome if passed, or marking it as failed.
     * Callable by anyone after the voting period ends.
     * @param _proposalId The ID of the proposal to finalize.
     */
    function finalizeProposal(uint256 _proposalId) public whenNotPaused {
        Proposal storage proposal = proposals[_proposalId];
        if (proposal.id == 0) revert ArbiterNexus__ProposalNotFound();
        if (proposal.state != ProposalState.Active) revert ArbiterNexus__ProposalNotActive();
        if (block.timestamp <= proposal.votingPeriodEnd) revert ArbiterNexus__VotingPeriodEnded();

        uint256 totalVotesCast = proposal.votesFor.add(proposal.votesAgainst).add(proposal.antithesisVotes);
        uint256 quorumRequired = totalStakedImpactShares.mul(protocolParameters[PARAMS_VOTE_QUORUM_PERCENT]).div(100);
        uint256 antithesisThreshold = totalStakedImpactShares.mul(protocolParameters[PARAMS_ANTITHESIS_THRESHOLD_PERCENT]).div(100);

        if (totalVotesCast < quorumRequired) {
            proposal.state = ProposalState.Failed; // Not enough participation
        } else if (proposal.antithesisVotes >= antithesisThreshold) {
            proposal.state = ProposalState.Failed; // Antithesis triggered: proposal fails or requires re-evaluation
            // In a more complex system, this could trigger a specific review phase or a new vote.
        } else if (proposal.votesFor > proposal.votesAgainst) {
            proposal.state = ProposalState.Succeeded;
            // Execute the proposal based on its type
            if (proposal.proposalType == ProposalType.ParameterChange) {
                protocolParameters[proposal.paramKey] = proposal.newValue;
                emit DynamicParametersAdjusted(currentEpoch); // Indicate a parameter changed by governance
            } else if (proposal.proposalType == ProposalType.InitiativeFunding) {
                uint256 initiativeId = nextInitiativeId++;
                Initiative storage newInitiative = initiatives[initiativeId];
                newInitiative.id = initiativeId;
                newInitiative.proposer = proposal.proposer;
                newInitiative.description = proposal.description;
                newInitiative.totalFundingApproved = proposal.totalFunding;
                newInitiative.state = InitiativeState.Active;
                newInitiative.milestones.length = proposal.milestoneCount; // Initialize milestones array

                uint256 fundingPerMilestone = proposal.totalFunding.div(proposal.milestoneCount);
                for (uint256 i = 0; i < proposal.milestoneCount; i++) {
                    newInitiative.milestones[i].fundingAmount = fundingPerMilestone;
                    newInitiative.milestones[i].verified = false;
                    newInitiative.milestones[i].fundsReleased = false;
                }
                emit InitiativeProposed(initiativeId, proposal.proposer, proposal.totalFunding);
            } else if (proposal.proposalType == ProposalType.ModuleUpgrade) {
                // In a real system, this would involve deploying a new module and updating its address.
                // For this demo, we'll just conceptually acknowledge the upgrade.
                // `currentModuleAddress` would be a state variable storing the address of the active module.
                // For simplicity, we just emit an event indicating the proposed new address.
                emit ModuleUpgradeProposed(proposal.id, proposal.newModuleAddress);
            }
            proposal.state = ProposalState.Executed;
            awardInfluencePoints(proposal.proposer, protocolParameters[PARAMS_IP_AWARD_RATE_PROPOSAL]);
        } else {
            proposal.state = ProposalState.Failed; // More against votes
        }
        emit ProposalFinalized(_proposalId, proposal.state);
    }

    // --- VI. Funding & Resource Allocation ---

    /**
     * @notice A project team requests verification for a completed milestone.
     * @param _initiativeId The ID of the initiative.
     * @param _milestoneIndex The index of the milestone (0-based).
     * Callable by the initiative proposer.
     */
    function requestMilestoneVerification(uint256 _initiativeId, uint256 _milestoneIndex) public whenNotPaused {
        Initiative storage initiative = initiatives[_initiativeId];
        if (initiative.id == 0) revert ArbiterNexus__ProposalNotFound();
        if (initiative.proposer != msg.sender) revert ArbiterNexus__UnauthorizedCaller();
        if (_milestoneIndex >= initiative.milestones.length) revert ArbiterNexus__NoPendingMilestone();

        Milestone storage milestone = initiative.milestones[_milestoneIndex];
        if (milestone.verified) revert ArbiterNexus__MilestoneAlreadyVerified();
        if (milestone.verificationStartTime != 0) revert ArbiterNexus__MilestoneVerificationAlreadyRequested(); // Custom error

        milestone.verificationStartTime = block.timestamp;
        // Optionally change initiative state to 'InVerification' here if only one milestone can be verified at a time.
        // For simplicity, keeping initiative state as 'Active' until all funds released.
        emit MilestoneVerificationRequested(_initiativeId, _milestoneIndex);
    }

    /**
     * @notice Designated "Verifiers" confirm or reject a milestone's completion.
     *         Requires a threshold of verifier votes (e.g., minimum 'approvedVerifiers').
     * @param _initiativeId The ID of the initiative.
     * @param _milestoneIndex The index of the milestone.
     * @param _approved True if approved, false if rejected.
     * Callable by designated Verifier roles (e.g., Guardians for this demo).
     */
    function verifyMilestone(uint256 _initiativeId, uint256 _milestoneIndex, bool _approved) public whenNotPaused {
        if (!isGuardian[msg.sender]) revert ArbiterNexus__UnauthorizedCaller(); // Only Guardians can verify for demo
        Initiative storage initiative = initiatives[_initiativeId];
        if (initiative.id == 0) revert ArbiterNexus__ProposalNotFound();
        if (_milestoneIndex >= initiative.milestones.length) revert ArbiterNexus__NoPendingMilestone();

        Milestone storage milestone = initiative.milestones[_milestoneIndex];
        if (milestone.verified) revert ArbiterNexus__MilestoneAlreadyVerified();
        if (milestone.verificationStartTime == 0) revert ArbiterNexus__NoPendingMilestone(); // Verification not requested yet
        if (block.timestamp > milestone.verificationStartTime.add(protocolParameters[PARAMS_MILSTONE_VERIFICATION_PERIOD])) {
            revert ArbiterNexus__VerificationPeriodEnded();
        }
        if (milestone.hasVerified[msg.sender]) revert ArbiterNexus__CannotVoteTwice(); // Already verified this milestone

        milestone.hasVerified[msg.sender] = true;
        if (_approved) {
            milestone.approvedVerifiers = milestone.approvedVerifiers.add(1);
        } else {
            milestone.rejectedVerifiers = milestone.rejectedVerifiers.add(1);
        }

        // Check if approval threshold is met or if too many rejections
        if (milestone.approvedVerifiers >= protocolParameters[PARAMS_MILSTONE_APPROVAL_THRESHOLD]) {
            milestone.verified = true;
            awardInfluencePoints(msg.sender, protocolParameters[PARAMS_IP_AWARD_RATE_VERIFICATION]);
        } else if (milestone.rejectedVerifiers >= protocolParameters[PARAMS_MILSTONE_APPROVAL_THRESHOLD]) {
             // Or some other rule for rejection. For simplicity, enough rejections also makes it unverified.
             // This might also trigger a slash on the project team's IPs
             milestone.verified = false; // Explicitly mark as not verified
        }
        emit MilestoneVerified(_initiativeId, _milestoneIndex, _approved);
    }

    /**
     * @notice Releases a funding tranche for a verified milestone.
     * @param _initiativeId The ID of the initiative.
     * @param _milestoneIndex The index of the milestone.
     * Callable by anyone after milestone verification is complete and approved.
     */
    function releaseFundingTranche(uint256 _initiativeId, uint256 _milestoneIndex) public whenNotPaused {
        Initiative storage initiative = initiatives[_initiativeId];
        if (initiative.id == 0) revert ArbiterNexus__ProposalNotFound();
        if (_milestoneIndex >= initiative.milestones.length) revert ArbiterNexus__NoPendingMilestone();

        Milestone storage milestone = initiative.milestones[_milestoneIndex];
        if (!milestone.verified) revert ArbiterNexus__MilestoneNotApproved();
        if (milestone.fundsReleased) revert ArbiterNexus__FundingAlreadyReleased();

        uint256 amount = milestone.fundingAmount;
        if (totalTreasuryBalance < amount) revert ArbiterNexus__InsufficientBalance(); // Check treasury balance

        totalTreasuryBalance = totalTreasuryBalance.sub(amount);
        // Transfer funds to initiative proposer (project team)
        payable(initiative.proposer).transfer(amount);
        milestone.fundsReleased = true;
        initiative.currentFundingReleased = initiative.currentFundingReleased.add(amount);

        if (initiative.currentFundingReleased == initiative.totalFundingApproved) {
            initiative.state = InitiativeState.Completed;
        }
        emit FundingTrancheReleased(_initiativeId, _milestoneIndex, amount);
    }

    // --- VII. Module & Adaptive Parameter Management ---

    /**
     * @notice Proposes an upgrade or replacement of a core protocol module.
     * @param _newModuleAddress The address of the new module contract.
     * @param _description A description of the proposed module and its changes.
     * Callable by users with sufficient IPs, subject to governance vote.
     * @dev This is conceptual; actual module upgrade involves complex proxy patterns (e.g., UUPS, Transparent UUPS).
     *      For this demo, it signifies the intent to upgrade and the governance process for it.
     */
    function proposeModuleUpgrade(address _newModuleAddress, string memory _description) public whenNotPaused {
        if (influencePoints[msg.sender] < protocolParameters[PARAMS_PROPOSAL_THRESHOLD_IP]) {
            revert ArbiterNexus__NotEnoughInfluencePoints();
        }
        if (_newModuleAddress == address(0)) revert ArbiterNexus__InvalidAmount(); // Using InvalidAmount for null address

        uint256 proposalId = nextProposalId++;
        Proposal storage newProposal = proposals[proposalId];
        newProposal.id = proposalId;
        newProposal.proposalType = ProposalType.ModuleUpgrade;
        newProposal.proposer = msg.sender;
        newProposal.description = _description;
        newProposal.creationTime = block.timestamp;
        newProposal.votingPeriodEnd = block.timestamp.add(protocolParameters[PARAMS_VOTING_PERIOD]);
        newProposal.state = ProposalState.Active;
        newProposal.newModuleAddress = _newModuleAddress;

        emit ProposalSubmitted(proposalId, ProposalType.ModuleUpgrade, msg.sender, _description);
    }

    /**
     * @notice Receives input from an authorized Wisdom Oracle to suggest dynamic parameter adjustments.
     *         This data is then considered during epoch advancement or governance decisions.
     * @param _paramKeys An array of parameter keys to be adjusted.
     * @param _newValues An array of corresponding new values.
     * Callable only by the designated Wisdom Oracle address.
     */
    function receiveWisdomOracleInput(bytes32[] memory _paramKeys, uint256[] memory _newValues) public onlyWisdomOracle whenNotPaused {
        if (_paramKeys.length != _newValues.length) revert ArbiterNexus__InvalidParameterValue();
        
        // For this demo, we directly update the parameters with the oracle's suggestions.
        // In a more complex system, these would be 'suggestions' that are factored into
        // the `adjustDynamicParameters` calculation, possibly with weights or requiring
        // a governance override if outside certain bounds.
        for (uint256 i = 0; i < _paramKeys.length; i++) {
            protocolParameters[_paramKeys[i]] = _newValues[i];
        }
        emit WisdomOracleInputReceived(msg.sender, _paramKeys);
    }

    /**
     * @notice Internal function to apply dynamic parameter changes.
     *         This would incorporate Wisdom Oracle input and potentially other on-chain metrics.
     *         Called during epoch advancement (`advanceEpoch`).
     */
    function adjustDynamicParameters() internal {
        // This is the core of the "adaptive" mechanism.
        // Logic here would process the Wisdom Oracle's inputs (which for this demo
        // are directly applied in `receiveWisdomOracleInput`) and potentially other
        // on-chain metrics (e.g., total funds disbursed, number of active proposals,
        // IP growth rates) to algorithmically adjust parameters.
        // Example logic (if not directly applied by oracle):
        // if (externalImpactMetrics[keccak256("SOME_METRIC")] > threshold) {
        //     protocolParameters[PARAMS_IP_AWARD_RATE_PROPOSAL] = newHigherRate;
        // }
        // For this demo, the changes are already applied by the oracle, this function
        // primarily serves as the conceptual integration point during epoch advance.
    }

    // --- VIII. Role & Responsibility Management ---

    /**
     * @notice Assigns a user to the special "Guardian" role.
     *         Guardians have elevated privileges, including specific verification roles.
     * @param _guardian The address to assign the Guardian role to.
     * Callable by governance (owner initially, then passed governance proposal).
     */
    function assignGuardianRole(address _guardian) public onlyOwner { // Simplified access for demo
        if (_guardian == address(0)) revert ArbiterNexus__InvalidAmount();
        isGuardian[_guardian] = true;
        emit GuardianRoleAssigned(_guardian);
    }

    /**
     * @notice Revokes the Guardian role from a user.
     * @param _guardian The address to revoke the Guardian role from.
     * Callable by governance.
     */
    function revokeGuardianRole(address _guardian) public onlyOwner { // Simplified access for demo
        if (_guardian == address(0)) revert ArbiterNexus__InvalidAmount();
        isGuardian[_guardian] = false;
        emit GuardianRoleRevoked(_guardian);
    }

    // --- IX. External Interaction (Simulated) ---

    /**
     * @notice Allows authorized entities to report simulated off-chain impact metrics.
     *         These metrics can feed into the Wisdom Oracle or be directly consumed by governance logic.
     * @param _metricKey A unique key for the impact metric (e.g., keccak256("FOREST_REGENERATED_ACRES")).
     * @param _value The value of the metric.
     * Callable by authorized reporters (e.g., Guardians or specific oracles).
     */
    function reportExternalImpactMetric(bytes32 _metricKey, uint256 _value) public whenNotPaused {
        if (!isGuardian[msg.sender] && msg.sender != wisdomOracleAddress) revert ArbiterNexus__UnauthorizedCaller();
        externalImpactMetrics[_metricKey] = _value;
        emit ExternalImpactMetricReported(_metricKey, _value);
    }

    // --- X. Treasury Management ---

    /**
     * @notice Allows depositing native currency (ETH) into the protocol's treasury.
     * @dev Funds deposited here are available for funding initiatives.
     */
    function depositToTreasury() public payable whenNotPaused {
        if (msg.value == 0) revert ArbiterNexus__InvalidAmount();
        totalTreasuryBalance = totalTreasuryBalance.add(msg.value);
        emit FundsDepositedToTreasury(msg.sender, msg.value);
    }

    // --- XI. Query & Read Functions ---

    /**
     * @notice Retrieves the current value of a specific protocol parameter.
     * @param _key The key of the parameter.
     * @return The current value of the parameter.
     */
    function getProtocolParameter(bytes32 _key) public view returns (uint256) {
        return protocolParameters[_key];
    }

    /**
     * @notice Gets a user's current Influence Points (IPs) balance.
     * @param _user The address of the user.
     * @return The IP balance.
     */
    function getUserInfluencePoints(address _user) public view returns (uint256) {
        return influencePoints[_user];
    }

    /**
     * @notice Checks the current state of a proposal.
     * @param _proposalId The ID of the proposal.
     * @return The state of the proposal.
     */
    function getProposalState(uint256 _proposalId) public view returns (ProposalState) {
        // If proposal ID is 0 or not found, return Pending or throw, depending on desired behavior.
        // Here, we'll return Pending if ID is 0 (uninitialized proposal).
        if (proposals[_proposalId].id == 0) return ProposalState.Pending;
        return proposals[_proposalId].state;
    }

    /**
     * @notice Retrieves information about the current epoch.
     * @return _currentEpoch The current epoch number.
     * @return _epochStartTime The timestamp when the current epoch started.
     * @return _epochDuration The duration of an epoch in seconds.
     * @return _nextEpochEnd The timestamp when the current epoch is expected to end.
     */
    function getEpochDetails() public view returns (uint256 _currentEpoch, uint256 _epochStartTime, uint256 _epochDuration, uint256 _nextEpochEnd) {
        _currentEpoch = currentEpoch;
        _epochStartTime = epochStartTime;
        _epochDuration = protocolParameters[PARAMS_EPOCH_DURATION];
        _nextEpochEnd = epochStartTime.add(_epochDuration);
    }

    /**
     * @notice Gets a user's currently staked Impact Shares (IS).
     * @param _user The address of the user.
     * @return The amount of staked IS.
     */
    function getStakedShares(address _user) public view returns (uint256) {
        return stakedImpactShares[_user];
    }

    /**
     * @notice Gets a user's pending unstake amount and cooldown end time.
     * @param _user The address of the user.
     * @return _amount The amount of IS pending unstake.
     * @return _cooldownEnd The timestamp when the cooldown period ends.
     */
    function getPendingUnstake(address _user) public view returns (uint256 _amount, uint256 _cooldownEnd) {
        _amount = pendingUnstake[_user];
        if (unstakeCooldownStart[_user] == 0) { // No pending unstake
            _cooldownEnd = 0;
        } else {
            _cooldownEnd = unstakeCooldownStart[_user].add(protocolParameters[PARAMS_UNSTAKE_COOLDOWN]);
        }
    }

    // Fallback and Receive functions for ETH to allow deposits to treasury
    receive() external payable {
        depositToTreasury();
    }

    fallback() external payable {
        depositToTreasury();
    }
}
```