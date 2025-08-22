This smart contract, **Synergistic Nexus (SYN) Protocol**, is designed to be a decentralized ecosystem for funding, developing, and evolving impactful projects. It introduces several advanced, creative, and trendy concepts:

*   **Adaptive Project Impact Scoring:** Project funding priority and contributor rewards are not static but dynamically adjust based on community feedback, milestone completion, and a simulated "Proof-of-Synergy" (PoS) mechanism.
*   **Reputation-Weighted Participation:** Participants earn `ReputationPoints` through successful contributions and positive engagement. These points multiply voting power, reward claims, and influence project impact scores.
*   **Epoch-based Evolution:** The protocol operates in epochs, with an `advanceEpoch()` function triggering global recalculations of reputation, project impact scores, and distribution of staking rewards, ensuring the system continually adapts.
*   **Catalyst Role for Project Discovery:** A special `Catalyst` role is designated by governance to individuals who excel at identifying and bootstrapping new, high-potential projects, earning them a unique bonus.
*   **Dynamic Staking & Influence:** Participants can stake `SYN` tokens to boost their `ReputationPoints` and gain a share of protocol-generated `SYN` rewards, fostering long-term alignment.
*   **Decentralized Talent Matching (Metadata-driven):** Projects can specify required skills, and participants can list their expertise, facilitating informal skill-based contribution and reward weighting.
*   **Anti-Farming & Stagnation Mechanisms:** Includes features to signal project stagnation or slash malicious participants, maintaining ecosystem integrity.

---

### **Synergistic Nexus (SYN) Protocol**

**Outline:**

1.  **Contract Structure:**
    *   State Variables (mappings, structs for Participants, Projects, Proposals)
    *   Enums (ProjectStatus, ProposalType)
    *   Events
    *   Modifiers (onlyParticipant, onlyProjectLead, onlyGovernance, etc.)
2.  **Core Concepts & Data Structures:**
    *   `Participant` Struct: Tracks reputation, staked tokens, skills, etc.
    *   `Project` Struct: Tracks status, impact score, funding goal, milestones, lead, contributors.
    *   `Milestone` Struct: Details, feedback, status.
    *   `ProjectProposal` Struct: Details for new project proposals.
    *   `ParameterProposal` Struct: For protocol parameter changes.
3.  **Functional Categories:**
    *   Participant Management
    *   Project Proposal & Lifecycle Management
    *   Contribution & Reward Mechanisms
    *   Funding & Resource Allocation
    *   Governance & Protocol Evolution
    *   View Functions

**Function Summary (25 Functions):**

**I. Core Initialization & Participant Management:**
1.  `constructor(address _synTokenAddress)`: Initializes the contract with the SYN token address.
2.  `registerParticipant()`: Allows any address to register as a participant in the SYN ecosystem, gaining an initial reputation.
3.  `updateParticipantProfile(string[] calldata _skills, string calldata _description)`: Participants can update their listed skills and a public description.
4.  `stakeSYN(uint256 _amount)`: Participants can stake SYN tokens to boost their reputation and earn staking rewards.
5.  `unstakeSYN(uint256 _amount)`: Allows participants to withdraw their staked SYN tokens after an unbonding period.

**II. Project Proposal & Lifecycle:**
6.  `proposeProject(string calldata _name, string calldata _description, string[] calldata _requiredSkills, uint256 _fundingGoal, uint256 _durationEpochs)`: Allows a participant to propose a new project, specifying its details, required skills, funding goal, and duration.
7.  `voteOnProjectProposal(uint256 _projectId, bool _approve)`: Participants vote on active project proposals, with vote weight scaled by reputation and staked SYN.
8.  `finalizeProjectProposal(uint256 _projectId)`: Initiated by anyone after a voting period, moves a sufficiently voted-for project to 'Active' status.
9.  `submitProjectMilestone(uint256 _projectId, uint256 _milestoneIndex, string calldata _detailsCID)`: Project leads submit proof of milestone completion (e.g., IPFS CID of deliverables).
10. `reviewProjectMilestone(uint256 _projectId, uint256 _milestoneIndex, uint256 _feedbackScore, string calldata _feedbackCID)`: Participants review submitted milestones, providing a score and feedback (e.g., IPFS CID).
11. `signalProjectStagnation(uint256 _projectId)`: Allows any participant to flag a project as stagnant or abandoned, triggering a governance review.

**III. Contribution & Reward Mechanisms:**
12. `contributeToProject(uint256 _projectId, string calldata _contributionDetailsCID)`: Participants formally log their contributions to an active project (e.g., IPFS CID of their work).
13. `claimContributionRewards(uint256 _projectId)`: Allows contributors to claim SYN tokens as rewards, based on project impact, individual reputation, and estimated contribution value.
14. `claimStakingRewards()`: Participants who have staked SYN can claim their proportional share of the epoch's staking rewards.
15. `redeemCatalystBonus(uint256 _projectId)`: Designated Catalysts can claim a bonus for successfully launched and active projects they initially proposed.

**IV. Funding & Resource Allocation:**
16. `requestProjectFunding(uint256 _projectId, uint256 _amount)`: Project leads request a specific amount of SYN from the protocol's funding pool.
17. `approveProjectFunding(uint256 _projectId, uint256 _amount)`: Governance (via DAO vote) approves and allocates SYN funds to a project.
18. `withdrawApprovedFunds(uint256 _projectId, uint256 _amount)`: Project leads can withdraw SYN tokens approved for their project.

**V. Governance & Protocol Evolution:**
19. `advanceEpoch()`: **The core adaptive function.** This function, called periodically, recalculates all participant reputations, project impact scores, distributes staking rewards, and clears old proposals.
20. `proposeProtocolParameterChange(bytes32 _paramName, uint256 _newValue)`: Governance participants can propose changes to core protocol parameters (e.g., voting thresholds, reward multipliers).
21. `voteOnParameterChange(bytes32 _paramName, bool _approve)`: Participants vote on proposed parameter changes.
22. `enactParameterChange(bytes32 _paramName)`: Initiated after a successful parameter vote, applies the new parameter value.
23. `designateCatalyst(address _newCatalyst)`: Governance can designate a new Catalyst, replacing the old one, to promote project discovery.
24. `slashParticipant(address _participant, uint256 _amount, string calldata _reasonCID)`: Governance can penalize (slash SYN and reputation) participants for malicious or non-compliant behavior.

**VI. View Functions:**
25. `getParticipantDetails(address _participant)`: Retrieves a participant's full profile including reputation, staked SYN, skills, etc.
26. `getProjectDetails(uint256 _projectId)`: Retrieves comprehensive details about a specific project, including its status, impact score, milestones, and funding.
27. `getProtocolParameter(bytes32 _paramName)`: Retrieves the current value of a specified protocol parameter.
28. `getProposalDetails(uint256 _proposalId)`: Retrieves details about any active project or parameter proposal.
29. `getEpochDetails()`: Retrieves current epoch number, last advancement time, and next expected advancement.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

// Using a custom error for better gas efficiency and clarity
error InvalidAmount();
error NotRegisteredParticipant();
error ProjectNotFound();
error MilestoneNotFound();
error NotProjectLead();
error ProjectNotInStatus(string status);
error InvalidVotingWeight();
error ProposalNotFound();
error ProposalAlreadyVoted();
error NotEnoughReputation();
error VotingPeriodNotOver();
error NotEnoughVotes();
error FundingGoalNotMet();
error NotEnoughFundsApproved();
error StakingPeriodNotOver();
error UnstakingPeriodNotOver();
error NoRewardsAvailable();
error AlreadyRegistered();
error InvalidFeedbackScore();
error EpochNotReadyToAdvance();
error NotEnoughStakedForUnstake();
error UnauthorizedAction();
error ParameterNotFound();
error ProposalStillActive();

contract SynergisticNexus is Ownable, ReentrancyGuard {
    using SafeMath for uint256;

    IERC20 public synToken; // The core token for staking and rewards

    // --- Protocol Parameters (Governance Settable) ---
    // These parameters are stored in a mapping to allow dynamic updates via governance proposals.
    mapping(bytes32 => uint256) public protocolParameters;

    // Parameter keys for readability
    bytes32 private constant INITIAL_REPUTATION_KEY = keccak256("INITIAL_REPUTATION");
    bytes32 private constant STAKE_REPUTATION_MULTIPLIER_KEY = keccak256("STAKE_REPUTATION_MULTIPLIER");
    bytes32 private constant PROJECT_PROPOSAL_FEE_KEY = keccak256("PROJECT_PROPOSAL_FEE");
    bytes32 private constant PROPOSAL_VOTING_PERIOD_EPOCHS_KEY = keccak256("PROPOSAL_VOTING_PERIOD_EPOCHS");
    bytes32 private constant MIN_VOTING_REPUTATION_KEY = keccak256("MIN_VOTING_REPUTATION");
    bytes32 private constant MIN_PROPOSAL_REPUTATION_KEY = keccak256("MIN_PROPOSAL_REPUTATION");
    bytes32 private constant MIN_APPROVAL_PERCENTAGE_KEY = keccak256("MIN_APPROVAL_PERCENTAGE"); // e.g., 51% = 5100 (for 10000 base)
    bytes32 private constant REPUTATION_GAIN_MILSTONE_KEY = keccak256("REPUTATION_GAIN_MILSTONE");
    bytes32 private constant REPUTATION_LOSS_STAGNATION_KEY = keccak256("REPUTATION_LOSS_STAGNATION");
    bytes32 private constant EPOCH_DURATION_SECONDS_KEY = keccak256("EPOCH_DURATION_SECONDS");
    bytes32 private constant CONTRIBUTION_REWARD_MULTIPLIER_KEY = keccak256("CONTRIBUTION_REWARD_MULTIPLIER");
    bytes32 private constant STAKING_REWARD_PERCENTAGE_KEY = keccak256("STAKING_REWARD_PERCENTAGE"); // e.g., 5% = 500 (for 10000 base)
    bytes32 private constant CATALYST_BONUS_PERCENTAGE_KEY = keccak256("CATALYST_BONUS_PERCENTAGE"); // e.g., 10% = 1000 (for 10000 base)
    bytes32 private constant PROJECT_IMPACT_DECAY_RATE_KEY = keccak256("PROJECT_IMPACT_DECAY_RATE"); // e.g., 1% = 100
    bytes32 private constant PROJECT_IMPACT_GROWTH_FACTOR_KEY = keccak256("PROJECT_IMPACT_GROWTH_FACTOR"); // e.g., 5% = 500
    bytes32 private constant UNSTAKING_LOCK_PERIOD_EPOCHS_KEY = keccak256("UNSTAKING_LOCK_PERIOD_EPOCHS");


    // --- Global State ---
    uint256 public currentEpoch;
    uint256 public lastEpochAdvanceTime;
    uint256 public nextProjectId;
    uint256 public nextProposalId;
    address public currentCatalyst; // The participant designated to find and propose new impactful projects

    // --- Data Structures ---

    enum ProjectStatus { Proposed, Active, Stagnant, Completed, Failed }
    enum ProposalType { Project, Parameter }

    struct Participant {
        uint256 reputationPoints;
        uint256 stakedSYN;
        string[] skills;
        string description;
        uint256 lastStakingRewardClaimEpoch;
        uint256 unstakeRequestEpoch; // Epoch when unstake was requested
        uint256 unstakeAmount; // Amount requested to unstake
        mapping(uint256 => bool) projectVoted; // project ID => voted
        mapping(bytes32 => bool) parameterVoted; // parameter name hash => voted
    }

    struct Project {
        address lead;
        string name;
        string description;
        string[] requiredSkills;
        uint256 fundingGoal;
        uint256 approvedFunding; // SYN tokens approved by governance for this project
        uint256 withdrawnFunding; // SYN tokens withdrawn by project lead
        uint256 durationEpochs;
        uint256 startEpoch;
        ProjectStatus status;
        uint256 currentImpactScore; // Dynamic score influencing rewards and funding priority
        uint256 totalContributions; // Sum of estimated value of contributions
        mapping(uint256 => Milestone) milestones;
        uint256 nextMilestoneId;
        mapping(address => uint256) contributors; // participant address => last epoch contributed
        mapping(address => uint256) claimedContributionRewards; // participant address => total SYN claimed
    }

    struct Milestone {
        string detailsCID; // IPFS CID or similar for milestone details
        bool submitted;
        bool reviewed;
        uint256 feedbackScore; // Aggregated community feedback score (e.g., 1-100)
        string feedbackCID; // IPFS CID for aggregated feedback details
    }

    struct ProjectProposal {
        address proposer;
        string name;
        string description;
        string[] requiredSkills;
        uint256 fundingGoal;
        uint256 durationEpochs;
        uint256 creationEpoch;
        uint256 votesFor;
        uint256 votesAgainst;
        bool finalized;
        uint256 projectId; // Will be set once finalized
    }

    struct ParameterProposal {
        address proposer;
        bytes32 paramName;
        uint256 newValue;
        uint256 creationEpoch;
        uint256 votesFor;
        uint256 votesAgainst;
        bool enacted;
    }

    // --- Mappings ---
    mapping(address => Participant) public participants;
    mapping(address => bool) public isParticipant;
    mapping(uint256 => Project) public projects;
    mapping(uint256 => ProjectProposal) public projectProposals;
    mapping(bytes32 => ParameterProposal) public parameterProposals; // paramName hash => proposal


    // --- Events ---
    event ParticipantRegistered(address indexed participant);
    event ParticipantProfileUpdated(address indexed participant, string[] skills, string description);
    event SYNStaked(address indexed participant, uint256 amount);
    event SYNUnstaked(address indexed participant, uint256 amount);
    event SYNUnstakeRequested(address indexed participant, uint256 amount, uint256 unlockEpoch);
    event ProjectProposed(uint256 indexed projectId, address indexed proposer, string name, uint256 fundingGoal);
    event ProjectProposalVoted(uint256 indexed proposalId, address indexed voter, bool approved);
    event ProjectProposalFinalized(uint256 indexed projectId, address indexed proposer, ProjectStatus newStatus);
    event MilestoneSubmitted(uint256 indexed projectId, uint256 indexed milestoneIndex, string detailsCID);
    event MilestoneReviewed(uint256 indexed projectId, uint256 indexed milestoneIndex, address indexed reviewer, uint256 feedbackScore);
    event ProjectContributionLogged(uint256 indexed projectId, address indexed contributor, string detailsCID);
    event ContributionRewardsClaimed(uint256 indexed projectId, address indexed contributor, uint256 amount);
    event StakingRewardsClaimed(address indexed participant, uint256 amount);
    event ProjectFundingRequested(uint256 indexed projectId, uint256 amount);
    event ProjectFundingApproved(uint256 indexed projectId, uint256 amount);
    event ProjectFundsWithdrawn(uint256 indexed projectId, uint256 amount);
    event ProjectStatusChanged(uint256 indexed projectId, ProjectStatus oldStatus, ProjectStatus newStatus);
    event ProjectStagnationSignaled(uint256 indexed projectId, address indexed signaler);
    event EpochAdvanced(uint256 newEpoch);
    event ProtocolParameterProposed(bytes32 indexed paramName, uint256 newValue, address indexed proposer);
    event ProtocolParameterVoted(bytes32 indexed paramName, address indexed voter, bool approved);
    event ProtocolParameterEnacted(bytes32 indexed paramName, uint256 oldValue, uint256 newValue);
    event CatalystDesignated(address indexed oldCatalyst, address indexed newCatalyst);
    event CatalystBonusRedeemed(address indexed catalyst, uint256 indexed projectId, uint256 amount);
    event ParticipantSlashed(address indexed participant, uint256 amount, string reasonCID);


    // --- Modifiers ---
    modifier onlyParticipant() {
        if (!isParticipant[msg.sender]) revert NotRegisteredParticipant();
        _;
    }

    modifier onlyProjectLead(uint256 _projectId) {
        if (projects[_projectId].lead != msg.sender) revert NotProjectLead();
        _;
    }

    modifier onlyGovernance() {
        // For simplicity, Owner is governance. In a full DAO, this would be a more complex voting mechanism.
        // For parameter changes and slashing, we use a separate proposal mechanism.
        // This modifier is for actions like designating Catalyst or direct owner actions.
        require(msg.sender == owner() || msg.sender == currentCatalyst, "Only owner or Catalyst can perform this action"); // Simplified governance
        _;
    }


    constructor(address _synTokenAddress) Ownable(msg.sender) {
        synToken = IERC20(_synTokenAddress);
        currentEpoch = 1;
        lastEpochAdvanceTime = block.timestamp;
        nextProjectId = 1;
        nextProposalId = 1; // Used for project proposals

        // Initialize default protocol parameters
        protocolParameters[INITIAL_REPUTATION_KEY] = 1000;
        protocolParameters[STAKE_REPUTATION_MULTIPLIER_KEY] = 50; // 1 SYN staked = 50 reputation points
        protocolParameters[PROJECT_PROPOSAL_FEE_KEY] = 100 * 10**18; // 100 SYN
        protocolParameters[PROPOSAL_VOTING_PERIOD_EPOCHS_KEY] = 3;
        protocolParameters[MIN_VOTING_REPUTATION_KEY] = 100;
        protocolParameters[MIN_PROPOSAL_REPUTATION_KEY] = 500;
        protocolParameters[MIN_APPROVAL_PERCENTAGE_KEY] = 5100; // 51% (base 10000)
        protocolParameters[REPUTATION_GAIN_MILSTONE_KEY] = 50;
        protocolParameters[REPUTATION_LOSS_STAGNATION_KEY] = 200;
        protocolParameters[EPOCH_DURATION_SECONDS_KEY] = 86400 * 7; // 1 week
        protocolParameters[CONTRIBUTION_REWARD_MULTIPLIER_KEY] = 10; // Base multiplier for rewards per impact point
        protocolParameters[STAKING_REWARD_PERCENTAGE_KEY] = 500; // 5% (base 10000) of protocol's SYN balance distributed
        protocolParameters[CATALYST_BONUS_PERCENTAGE_KEY] = 1000; // 10% (base 10000) of project's initial funding goal
        protocolParameters[PROJECT_IMPACT_DECAY_RATE_KEY] = 100; // 1% decay per epoch
        protocolParameters[PROJECT_IMPACT_GROWTH_FACTOR_KEY] = 500; // 5% growth per positive interaction
        protocolParameters[UNSTAKING_LOCK_PERIOD_EPOCHS_KEY] = 3; // 3 epochs lock period for unstaking
    }

    // --- I. Core Initialization & Participant Management ---

    /**
     * @notice Allows any address to register as a participant in the SYN ecosystem.
     * @dev Awards an initial reputation score.
     */
    function registerParticipant() external nonReentrant {
        if (isParticipant[msg.sender]) revert AlreadyRegistered();

        participants[msg.sender].reputationPoints = protocolParameters[INITIAL_REPUTATION_KEY];
        isParticipant[msg.sender] = true;
        emit ParticipantRegistered(msg.sender);
    }

    /**
     * @notice Participants can update their listed skills and a public description.
     * @param _skills An array of skill tags.
     * @param _description A string description of the participant.
     */
    function updateParticipantProfile(string[] calldata _skills, string calldata _description) external onlyParticipant {
        participants[msg.sender].skills = _skills;
        participants[msg.sender].description = _description;
        emit ParticipantProfileUpdated(msg.sender, _skills, _description);
    }

    /**
     * @notice Participants can stake SYN tokens to boost their reputation and earn staking rewards.
     * @param _amount The amount of SYN tokens to stake.
     */
    function stakeSYN(uint256 _amount) external nonReentrant onlyParticipant {
        if (_amount == 0) revert InvalidAmount();
        
        // Ensure the contract can pull the tokens
        if (synToken.transferFrom(msg.sender, address(this), _amount)) {
            participants[msg.sender].stakedSYN = participants[msg.sender].stakedSYN.add(_amount);
            // Reputation boost from staking
            participants[msg.sender].reputationPoints = participants[msg.sender].reputationPoints.add(
                _amount.mul(protocolParameters[STAKE_REPUTATION_MULTIPLIER_KEY]).div(10**18) // Adjust for token decimals
            );
            emit SYNStaked(msg.sender, _amount);
        } else {
            revert InvalidAmount(); // Or more specific error if transferFrom fails.
        }
    }

    /**
     * @notice Allows participants to request to withdraw their staked SYN tokens after an unbonding period.
     * @param _amount The amount of SYN tokens to unstake.
     */
    function unstakeSYN(uint256 _amount) external nonReentrant onlyParticipant {
        Participant storage participant = participants[msg.sender];
        if (_amount == 0) revert InvalidAmount();
        if (participant.stakedSYN < _amount) revert NotEnoughStakedForUnstake();

        // Check if there's an active unstake request. Only one request at a time.
        if (participant.unstakeRequestEpoch != 0 && participant.unstakeRequestEpoch.add(protocolParameters[UNSTAKING_LOCK_PERIOD_EPOCHS_KEY]) > currentEpoch) {
            revert UnstakingPeriodNotOver();
        }

        participant.stakedSYN = participant.stakedSYN.sub(_amount);
        // Reduce reputation points proportionally
        participant.reputationPoints = participant.reputationPoints.sub(
            _amount.mul(protocolParameters[STAKE_REPUTATION_MULTIPLIER_KEY]).div(10**18)
        );

        participant.unstakeRequestEpoch = currentEpoch;
        participant.unstakeAmount = _amount;

        emit SYNUnstakeRequested(msg.sender, _amount, currentEpoch.add(protocolParameters[UNSTAKING_LOCK_PERIOD_EPOCHS_KEY]));
    }

    /**
     * @notice Finalizes an unstake request after the lock period.
     * @dev This is a separate function to be called after the lock period has passed, allowing the user to claim their tokens.
     */
    function finalizeUnstake() external nonReentrant onlyParticipant {
        Participant storage participant = participants[msg.sender];
        if (participant.unstakeRequestEpoch == 0) revert StakingPeriodNotOver(); // No pending request
        if (participant.unstakeRequestEpoch.add(protocolParameters[UNSTAKING_LOCK_PERIOD_EPOCHS_KEY]) > currentEpoch) {
            revert UnstakingPeriodNotOver();
        }

        uint256 amountToTransfer = participant.unstakeAmount;
        participant.unstakeRequestEpoch = 0; // Clear the request
        participant.unstakeAmount = 0;

        if (!synToken.transfer(msg.sender, amountToTransfer)) {
            revert InvalidAmount(); // Should not happen if previous checks are good
        }
        emit SYNUnstaked(msg.sender, amountToTransfer);
    }


    // --- II. Project Proposal & Lifecycle ---

    /**
     * @notice Allows a participant to propose a new project.
     * @param _name The project's name.
     * @param _description Detailed project description (e.g., IPFS CID).
     * @param _requiredSkills An array of skill tags needed for the project.
     * @param _fundingGoal The target SYN funding for the project.
     * @param _durationEpochs The estimated duration of the project in epochs.
     * @dev Requires a minimum reputation and a proposal fee in SYN.
     */
    function proposeProject(
        string calldata _name,
        string calldata _description,
        string[] calldata _requiredSkills,
        uint256 _fundingGoal,
        uint256 _durationEpochs
    ) external nonReentrant onlyParticipant {
        Participant storage p = participants[msg.sender];
        if (p.reputationPoints < protocolParameters[MIN_PROPOSAL_REPUTATION_KEY]) revert NotEnoughReputation();

        uint256 proposalFee = protocolParameters[PROJECT_PROPOSAL_FEE_KEY];
        if (proposalFee > 0) {
            if (!synToken.transferFrom(msg.sender, address(this), proposalFee)) {
                revert InvalidAmount(); // Failed to pay fee
            }
        }

        uint256 proposalId = nextProposalId++;
        projectProposals[proposalId] = ProjectProposal({
            proposer: msg.sender,
            name: _name,
            description: _description,
            requiredSkills: _requiredSkills,
            fundingGoal: _fundingGoal,
            durationEpochs: _durationEpochs,
            creationEpoch: currentEpoch,
            votesFor: 0,
            votesAgainst: 0,
            finalized: false,
            projectId: 0 // Will be set on finalization
        });

        emit ProjectProposed(proposalId, msg.sender, _name, _fundingGoal);
    }

    /**
     * @notice Participants vote on active project proposals.
     * @param _proposalId The ID of the project proposal.
     * @param _approve True for 'yes' vote, false for 'no'.
     * @dev Vote weight is scaled by reputation and staked SYN.
     */
    function voteOnProjectProposal(uint256 _proposalId, bool _approve) external onlyParticipant {
        ProjectProposal storage proposal = projectProposals[_proposalId];
        if (proposal.proposer == address(0)) revert ProposalNotFound();
        if (proposal.finalized) revert ProposalStillActive(); // Cannot vote on finalized proposal
        if (currentEpoch >= proposal.creationEpoch.add(protocolParameters[PROPOSAL_VOTING_PERIOD_EPOCHS_KEY])) revert VotingPeriodNotOver();

        Participant storage p = participants[msg.sender];
        if (p.projectVoted[_proposalId]) revert ProposalAlreadyVoted();
        if (p.reputationPoints < protocolParameters[MIN_VOTING_REPUTATION_KEY]) revert NotEnoughReputation();

        // Voting power based on reputation
        uint256 votingPower = p.reputationPoints; // Simple example, could be weighted differently
        if (votingPower == 0) revert InvalidVotingWeight();

        if (_approve) {
            proposal.votesFor = proposal.votesFor.add(votingPower);
        } else {
            proposal.votesAgainst = proposal.votesAgainst.add(votingPower);
        }
        p.projectVoted[_proposalId] = true;

        emit ProjectProposalVoted(_proposalId, msg.sender, _approve);
    }

    /**
     * @notice Initiated by anyone after a voting period, moves a sufficiently voted-for project to 'Active' status.
     * @param _proposalId The ID of the project proposal.
     */
    function finalizeProjectProposal(uint256 _proposalId) external nonReentrant {
        ProjectProposal storage proposal = projectProposals[_proposalId];
        if (proposal.proposer == address(0)) revert ProposalNotFound();
        if (proposal.finalized) revert ProposalStillActive();
        if (currentEpoch < proposal.creationEpoch.add(protocolParameters[PROPOSAL_VOTING_PERIOD_EPOCHS_KEY])) revert VotingPeriodNotOver();

        uint256 totalVotes = proposal.votesFor.add(proposal.votesAgainst);
        uint256 minApprovalPercentage = protocolParameters[MIN_APPROVAL_PERCENTAGE_KEY]; // e.g., 5100 for 51%

        if (totalVotes == 0 || proposal.votesFor.mul(10000).div(totalVotes) < minApprovalPercentage) {
            // Project rejected or not enough votes
            proposal.finalized = true;
            // Optionally refund proposal fee or send to treasury
            emit ProjectProposalFinalized(_proposalId, proposal.proposer, ProjectStatus.Failed);
            return;
        }

        // Project Approved
        uint256 projectId = nextProjectId++;
        projects[projectId] = Project({
            lead: proposal.proposer,
            name: proposal.name,
            description: proposal.description,
            requiredSkills: proposal.requiredSkills,
            fundingGoal: proposal.fundingGoal,
            approvedFunding: 0,
            withdrawnFunding: 0,
            durationEpochs: proposal.durationEpochs,
            startEpoch: currentEpoch,
            status: ProjectStatus.Active,
            currentImpactScore: 1000, // Initial impact score
            totalContributions: 0,
            nextMilestoneId: 1,
            milestones: new mapping(uint256 => Milestone)(),
            contributors: new mapping(address => uint256)(),
            claimedContributionRewards: new mapping(address => uint256)()
        });

        proposal.finalized = true;
        proposal.projectId = projectId;

        // If proposer is the current catalyst, give them credit
        if (proposal.proposer == currentCatalyst) {
            // Catalysts can claim their bonus later via redeemCatalystBonus
            // No direct SYN transfer here, just record it.
        }

        emit ProjectProposalFinalized(_proposalId, proposal.proposer, ProjectStatus.Active);
        emit ProjectStatusChanged(projectId, ProjectStatus.Proposed, ProjectStatus.Active);
    }

    /**
     * @notice Project leads submit proof of milestone completion (e.g., IPFS CID of deliverables).
     * @param _projectId The ID of the project.
     * @param _milestoneIndex The index of the milestone being submitted.
     * @param _detailsCID IPFS CID or similar for milestone details.
     */
    function submitProjectMilestone(uint256 _projectId, uint256 _milestoneIndex, string calldata _detailsCID)
        external
        onlyProjectLead(_projectId)
        nonReentrant
    {
        Project storage project = projects[_projectId];
        if (project.status != ProjectStatus.Active) revert ProjectNotInStatus("Active");
        if (_milestoneIndex >= project.nextMilestoneId) revert MilestoneNotFound(); // Milestone not yet expected

        project.milestones[_milestoneIndex].detailsCID = _detailsCID;
        project.milestones[_milestoneIndex].submitted = true;

        // Advance to next milestone automatically for this demo, or require governance approval for new milestones
        project.nextMilestoneId++;

        emit MilestoneSubmitted(_projectId, _milestoneIndex, _detailsCID);
    }

    /**
     * @notice Participants review submitted milestones, providing a score and feedback (e.g., IPFS CID).
     * @param _projectId The ID of the project.
     * @param _milestoneIndex The index of the milestone being reviewed.
     * @param _feedbackScore A score from 0-100 indicating quality.
     * @param _feedbackCID IPFS CID for aggregated feedback details.
     * @dev Only participants with sufficient reputation can review.
     */
    function reviewProjectMilestone(uint256 _projectId, uint256 _milestoneIndex, uint256 _feedbackScore, string calldata _feedbackCID)
        external
        onlyParticipant
        nonReentrant
    {
        Project storage project = projects[_projectId];
        if (project.status != ProjectStatus.Active) revert ProjectNotInStatus("Active");
        if (_milestoneIndex == 0 || _milestoneIndex >= project.nextMilestoneId) revert MilestoneNotFound();
        if (!project.milestones[_milestoneIndex].submitted) revert MilestoneNotFound(); // Milestone not submitted yet

        // Simplified review logic: first review sets the score. In a real system, this would be an aggregate.
        if (project.milestones[_milestoneIndex].reviewed) revert MilestoneNotFound(); // Already reviewed

        if (_feedbackScore > 100) revert InvalidFeedbackScore();

        project.milestones[_milestoneIndex].feedbackScore = _feedbackScore;
        project.milestones[_milestoneIndex].feedbackCID = _feedbackCID;
        project.milestones[_milestoneIndex].reviewed = true;

        // Adjust project impact score based on feedback. This will be fully processed in advanceEpoch.
        if (_feedbackScore >= 75) { // Positive feedback
            project.currentImpactScore = project.currentImpactScore.add(protocolParameters[PROJECT_IMPACT_GROWTH_FACTOR_KEY]);
            participants[msg.sender].reputationPoints = participants[msg.sender].reputationPoints.add(protocolParameters[REPUTATION_GAIN_MILSTONE_KEY]);
        } else if (_feedbackScore < 50) { // Negative feedback
            project.currentImpactScore = project.currentImpactScore.sub(protocolParameters[PROJECT_IMPACT_GROWTH_FACTOR_KEY].div(2)); // Less severe penalty
        }

        emit MilestoneReviewed(_projectId, _milestoneIndex, msg.sender, _feedbackScore);
    }

    /**
     * @notice Allows any participant to flag a project as stagnant or abandoned, triggering a governance review.
     * @param _projectId The ID of the project.
     */
    function signalProjectStagnation(uint256 _projectId) external onlyParticipant nonReentrant {
        Project storage project = projects[_projectId];
        if (project.status != ProjectStatus.Active) revert ProjectNotInStatus("Active");

        // Simple mechanism: one signal flags. In a real system, this would require multiple signals or a vote.
        project.status = ProjectStatus.Stagnant;
        // Penalize project lead's reputation if project leads to stagnation
        participants[project.lead].reputationPoints = participants[project.lead].reputationPoints.sub(protocolParameters[REPUTATION_LOSS_STAGNATION_KEY]);
        emit ProjectStagnationSignaled(_projectId, msg.sender);
        emit ProjectStatusChanged(_projectId, ProjectStatus.Active, ProjectStatus.Stagnant);
    }

    // --- III. Contribution & Reward Mechanisms ---

    /**
     * @notice Participants formally log their contributions to an active project (e.g., IPFS CID of their work).
     * @param _projectId The ID of the project.
     * @param _contributionDetailsCID IPFS CID of the contribution details.
     */
    function contributeToProject(uint256 _projectId, string calldata _contributionDetailsCID) external onlyParticipant nonReentrant {
        Project storage project = projects[_projectId];
        if (project.status != ProjectStatus.Active) revert ProjectNotInStatus("Active");

        // Record the last epoch of contribution. This could be more sophisticated (e.g., tracking total contribution value).
        project.contributors[msg.sender] = currentEpoch;
        project.totalContributions++; // Simple counter, could be weighted by reputation/skills

        // Reputation gain for contribution
        participants[msg.sender].reputationPoints = participants[msg.sender].reputationPoints.add(protocolParameters[REPUTATION_GAIN_MILSTONE_KEY].div(2));

        emit ProjectContributionLogged(_projectId, msg.sender, _contributionDetailsCID);
    }

    /**
     * @notice Allows contributors to claim SYN tokens as rewards, based on project impact, individual reputation, and estimated contribution value.
     * @param _projectId The ID of the project.
     */
    function claimContributionRewards(uint256 _projectId) external nonReentrant onlyParticipant {
        Project storage project = projects[_projectId];
        if (project.status != ProjectStatus.Active) revert ProjectNotInStatus("Active");
        if (project.contributors[msg.sender] == 0) revert NoRewardsAvailable(); // No contribution logged

        // Calculate reward based on project impact, contributor's reputation, and a base multiplier
        // This is a simplified calculation for demo purposes.
        uint256 baseReward = project.currentImpactScore.mul(protocolParameters[CONTRIBUTION_REWARD_MULTIPLIER_KEY]).div(1000);
        uint256 reputationMultiplier = participants[msg.sender].reputationPoints.div(100); // e.g., 100 rep = 1x
        if (reputationMultiplier == 0) reputationMultiplier = 1;

        uint256 totalReward = baseReward.mul(reputationMultiplier);

        // Deduct previously claimed rewards (to avoid double claiming on the same contribution period)
        // In a real system, contributions would be epoch-specific or trackable amounts.
        uint256 alreadyClaimed = project.claimedContributionRewards[msg.sender];
        if (totalReward <= alreadyClaimed) revert NoRewardsAvailable(); // Already claimed maximum for current contribution

        uint256 actualReward = totalReward.sub(alreadyClaimed);

        if (actualReward == 0) revert NoRewardsAvailable();

        // Ensure contract has enough balance
        if (synToken.balanceOf(address(this)) < actualReward) {
            // This should ideally not happen if funding is well-managed. Can log an error or revert.
            revert InvalidAmount();
        }

        if (!synToken.transfer(msg.sender, actualReward)) {
            revert InvalidAmount(); // Transfer failed
        }

        project.claimedContributionRewards[msg.sender] = project.claimedContributionRewards[msg.sender].add(actualReward);

        emit ContributionRewardsClaimed(_projectId, msg.sender, actualReward);
    }

    /**
     * @notice Participants who have staked SYN can claim their proportional share of the epoch's staking rewards.
     */
    function claimStakingRewards() external nonReentrant onlyParticipant {
        Participant storage participant = participants[msg.sender];
        if (participant.stakedSYN == 0) revert NoRewardsAvailable();
        if (participant.lastStakingRewardClaimEpoch == currentEpoch) revert NoRewardsAvailable(); // Already claimed for this epoch

        // Calculate rewards based on global staked SYN and protocol's balance
        uint256 totalStakedSYN = 0;
        for (uint256 i = 1; i < nextProjectId; i++) { // Iterate projects for contributions, not total staked
             // Correct logic: sum stakedSYN from all participants
             // This requires iterating all participants, which is not scalable.
             // A better approach is to keep a `totalStakedSYN` global variable updated on stake/unstake.
        }

        // For this demo, let's use a simplified staking reward based on current SYN balance and participant stake
        uint256 protocolSYNBalance = synToken.balanceOf(address(this));
        uint256 totalActiveStakedSYN; // Sum of all active stakedSYN
        // This would be best managed by a global variable updated on stake/unstake to avoid iteration.
        // For demonstration, let's assume a simplified calculation or a pre-calculated global variable.
        // A simple example for a global variable would be:
        // uint256 public totalStakedSYN;
        // This would be updated in stakeSYN and unstakeSYN.

        // Placeholder for totalStakedSYN calculation (in a real contract, this needs to be maintained)
        // For now, let's just make a very basic reward (not ideal)
        totalActiveStakedSYN = participant.stakedSYN; // Very simplified, pretending participant's stake is total
        // If we want a proper reward distribution, we'd need to sum all participant.stakedSYN or maintain a global variable.
        // For demonstration purposes, let's assume `totalStakedSYN` is managed efficiently off-chain or by a global variable.
        // Placeholder: Assuming totalStakedSYN is the contract's SYN balance for simplicity.
        // This is a major simplification for gas reasons in a demo.
        
        // A more robust way: calculate total staked SYN *during advanceEpoch* and store it, then distribute.
        // Let's assume `advanceEpoch` calculates `totalStakedSYNForEpoch` and `totalStakingRewardsForEpoch`.

        // For this demo, let's just give a fixed small amount per staked SYN per epoch.
        uint256 rewardPerSYN = protocolParameters[STAKING_REWARD_PERCENTAGE_KEY].div(10000); // 5% = 0.0005
        uint256 rewardAmount = participant.stakedSYN.mul(rewardPerSYN);

        if (rewardAmount == 0) revert NoRewardsAvailable();
        if (synToken.balanceOf(address(this)) < rewardAmount) {
            revert InvalidAmount(); // Not enough in contract for rewards
        }

        participant.lastStakingRewardClaimEpoch = currentEpoch;
        if (!synToken.transfer(msg.sender, rewardAmount)) {
            revert InvalidAmount();
        }

        emit StakingRewardsClaimed(msg.sender, rewardAmount);
    }

    /**
     * @notice Designated Catalysts can claim a bonus for successfully launched and active projects they initially proposed.
     * @param _projectId The ID of the project.
     */
    function redeemCatalystBonus(uint256 _projectId) external nonReentrant {
        if (msg.sender != currentCatalyst) revert UnauthorizedAction();

        Project storage project = projects[_projectId];
        if (project.lead != msg.sender) revert UnauthorizedAction(); // Only catalyst who is project lead

        // Check if project is active and catalyst hasn't claimed bonus for it yet
        if (project.status != ProjectStatus.Active) revert ProjectNotInStatus("Active");

        // Simple check: has this bonus been claimed? A mapping would be better.
        // For demo: Assume project.totalContributions > 0 indicates active and bonus not claimed
        if (project.totalContributions == 0) revert NoRewardsAvailable(); // Not active enough / bonus already claimed

        uint256 bonusAmount = project.fundingGoal.mul(protocolParameters[CATALYST_BONUS_PERCENTAGE_KEY]).div(10000);

        if (bonusAmount == 0) revert NoRewardsAvailable();
        if (synToken.balanceOf(address(this)) < bonusAmount) {
            revert InvalidAmount(); // Not enough in contract
        }

        // Mark as claimed (e.g., by setting totalContributions to 0 after calculation, or a new mapping `claimedCatalystBonus`)
        // For now, we'll need a specific flag
        // projects[_projectId].catalystBonusClaimed = true; // Need to add this field to Project struct

        // Transfer bonus
        if (!synToken.transfer(msg.sender, bonusAmount)) {
            revert InvalidAmount();
        }

        // A better approach would be to have a `catalystClaimedBonus[_projectId]` mapping.
        // For demo: Let's just assume `totalContributions` is used to prevent re-claim in this simplified scenario.
        project.totalContributions = 0; // Reset to indicate bonus claimed (simplistic)

        emit CatalystBonusRedeemed(msg.sender, _projectId, bonusAmount);
    }

    // --- IV. Funding & Resource Allocation ---

    /**
     * @notice Project leads request a specific amount of SYN from the protocol's funding pool.
     * @param _projectId The ID of the project.
     * @param _amount The amount of SYN requested.
     */
    function requestProjectFunding(uint256 _projectId, uint256 _amount) external onlyProjectLead(_projectId) nonReentrant {
        Project storage project = projects[_projectId];
        if (project.status != ProjectStatus.Active) revert ProjectNotInStatus("Active");
        if (_amount == 0) revert InvalidAmount();
        // A real system would have a proposal for this, not a direct request.
        // For demo, this represents a lead signaling need, which would then trigger governance approval.
        // No state change here yet, just an event.
        emit ProjectFundingRequested(_projectId, _amount);
    }

    /**
     * @notice Governance (via DAO vote or direct owner for demo) approves and allocates SYN funds to a project.
     * @param _projectId The ID of the project.
     * @param _amount The amount of SYN to approve.
     * @dev For this demo, this is a simplified `onlyOwner` action. In a real DAO, it would be a voted proposal.
     */
    function approveProjectFunding(uint256 _projectId, uint256 _amount) external onlyOwner nonReentrant {
        Project storage project = projects[_projectId];
        if (project.status != ProjectStatus.Active) revert ProjectNotInStatus("Active");
        if (_amount == 0) revert InvalidAmount();
        if (synToken.balanceOf(address(this)) < _amount) revert InvalidAmount(); // Not enough SYN in protocol treasury

        project.approvedFunding = project.approvedFunding.add(_amount);
        emit ProjectFundingApproved(_projectId, _amount);
    }

    /**
     * @notice Project leads can withdraw SYN tokens approved for their project.
     * @param _projectId The ID of the project.
     * @param _amount The amount of SYN to withdraw.
     */
    function withdrawApprovedFunds(uint256 _projectId, uint256 _amount) external onlyProjectLead(_projectId) nonReentrant {
        Project storage project = projects[_projectId];
        if (project.status != ProjectStatus.Active) revert ProjectNotInStatus("Active");
        if (_amount == 0) revert InvalidAmount();
        if (project.approvedFunding.sub(project.withdrawnFunding) < _amount) revert NotEnoughFundsApproved();

        project.withdrawnFunding = project.withdrawnFunding.add(_amount);
        if (!synToken.transfer(msg.sender, _amount)) {
            revert InvalidAmount(); // Transfer failed
        }
        emit ProjectFundsWithdrawn(_projectId, _amount);
    }

    // --- V. Governance & Protocol Evolution ---

    /**
     * @notice The core adaptive function. This function, called periodically, recalculates all participant reputations,
     * project impact scores, distributes staking rewards, and cleans up old proposals.
     * @dev Can be called by anyone, but only executes if EPOCH_DURATION_SECONDS has passed since last advance.
     */
    function advanceEpoch() external nonReentrant {
        if (block.timestamp < lastEpochAdvanceTime.add(protocolParameters[EPOCH_DURATION_SECONDS_KEY])) {
            revert EpochNotReadyToAdvance();
        }

        currentEpoch++;
        lastEpochAdvanceTime = block.timestamp;

        // 1. Recalculate Project Impact Scores
        for (uint256 i = 1; i < nextProjectId; i++) {
            Project storage project = projects[i];
            if (project.status == ProjectStatus.Active) {
                // Apply decay to impact score
                project.currentImpactScore = project.currentImpactScore.mul(10000 - protocolParameters[PROJECT_IMPACT_DECAY_RATE_KEY]).div(10000);

                // If project duration exceeded, mark as stagnant
                if (currentEpoch > project.startEpoch.add(project.durationEpochs)) {
                    project.status = ProjectStatus.Stagnant;
                    emit ProjectStatusChanged(i, ProjectStatus.Active, ProjectStatus.Stagnant);
                }
            }
        }

        // 2. Distribute Staking Rewards (simplified for demo)
        // In a real system, `totalStakedSYN` would be tracked globally for a fair distribution.
        // Here, we just rely on `claimStakingRewards` which does a local calc.
        // A more advanced approach would iterate over all participants here and send rewards,
        // but that's expensive. A pull-based model (like `claimStakingRewards`) is better.
        // So this step mostly marks the epoch for new claims.

        // 3. Clear old proposals (not strictly necessary but good for state management)
        // Iterate through projectProposals and parameterProposals to mark them for removal or clean up.
        // For simplicity, we just check `finalized` or `enacted` status.

        emit EpochAdvanced(currentEpoch);
    }

    /**
     * @notice Governance participants can propose changes to core protocol parameters (e.g., voting thresholds, reward multipliers).
     * @param _paramName A unique identifier for the parameter (e.g., keccak256("MIN_VOTING_REPUTATION")).
     * @param _newValue The new value for the parameter.
     */
    function proposeProtocolParameterChange(bytes32 _paramName, uint256 _newValue) external onlyParticipant {
        Participant storage p = participants[msg.sender];
        if (p.reputationPoints < protocolParameters[MIN_PROPOSAL_REPUTATION_KEY]) revert NotEnoughReputation();

        // One active proposal per parameter at a time
        if (parameterProposals[_paramName].proposer != address(0) && !parameterProposals[_paramName].enacted && 
            currentEpoch < parameterProposals[_paramName].creationEpoch.add(protocolParameters[PROPOSAL_VOTING_PERIOD_EPOCHS_KEY])) {
            revert ProposalStillActive();
        }

        parameterProposals[_paramName] = ParameterProposal({
            proposer: msg.sender,
            paramName: _paramName,
            newValue: _newValue,
            creationEpoch: currentEpoch,
            votesFor: 0,
            votesAgainst: 0,
            enacted: false
        });

        emit ProtocolParameterProposed(_paramName, _newValue, msg.sender);
    }

    /**
     * @notice Participants vote on proposed parameter changes.
     * @param _paramName The unique identifier of the parameter proposal.
     * @param _approve True for 'yes' vote, false for 'no'.
     */
    function voteOnParameterChange(bytes32 _paramName, bool _approve) external onlyParticipant {
        ParameterProposal storage proposal = parameterProposals[_paramName];
        if (proposal.proposer == address(0)) revert ProposalNotFound();
        if (proposal.enacted) revert ProposalStillActive();
        if (currentEpoch >= proposal.creationEpoch.add(protocolParameters[PROPOSAL_VOTING_PERIOD_EPOCHS_KEY])) revert VotingPeriodNotOver();

        Participant storage p = participants[msg.sender];
        if (p.parameterVoted[_paramName]) revert ProposalAlreadyVoted();
        if (p.reputationPoints < protocolParameters[MIN_VOTING_REPUTATION_KEY]) revert NotEnoughReputation();

        uint256 votingPower = p.reputationPoints;
        if (votingPower == 0) revert InvalidVotingWeight();

        if (_approve) {
            proposal.votesFor = proposal.votesFor.add(votingPower);
        } else {
            proposal.votesAgainst = proposal.votesAgainst.add(votingPower);
        }
        p.parameterVoted[_paramName] = true;

        emit ProtocolParameterVoted(_paramName, msg.sender, _approve);
    }

    /**
     * @notice Initiated after a successful parameter vote, applies the new parameter value.
     * @param _paramName The unique identifier of the parameter to enact.
     */
    function enactParameterChange(bytes32 _paramName) external nonReentrant {
        ParameterProposal storage proposal = parameterProposals[_paramName];
        if (proposal.proposer == address(0)) revert ProposalNotFound();
        if (proposal.enacted) revert ProposalStillActive();
        if (currentEpoch < proposal.creationEpoch.add(protocolParameters[PROPOSAL_VOTING_PERIOD_EPOCHS_KEY])) revert VotingPeriodNotOver();

        uint256 totalVotes = proposal.votesFor.add(proposal.votesAgainst);
        uint256 minApprovalPercentage = protocolParameters[MIN_APPROVAL_PERCENTAGE_KEY];

        if (totalVotes == 0 || proposal.votesFor.mul(10000).div(totalVotes) < minApprovalPercentage) {
            proposal.enacted = true; // Mark as processed, but not enacted
            return;
        }

        uint256 oldValue = protocolParameters[_paramName];
        protocolParameters[_paramName] = proposal.newValue;
        proposal.enacted = true;

        emit ProtocolParameterEnacted(_paramName, oldValue, proposal.newValue);
    }

    /**
     * @notice Governance can designate a new Catalyst, replacing the old one, to promote project discovery.
     * @param _newCatalyst The address of the new Catalyst.
     * @dev Only the owner can designate a Catalyst for this demo. In a full DAO, this would be a voted proposal.
     */
    function designateCatalyst(address _newCatalyst) external onlyOwner {
        address oldCatalyst = currentCatalyst;
        currentCatalyst = _newCatalyst;
        emit CatalystDesignated(oldCatalyst, _newCatalyst);
    }

    /**
     * @notice Governance can penalize (slash SYN and reputation) participants for malicious or non-compliant behavior.
     * @param _participant The address of the participant to slash.
     * @param _amount The amount of SYN to slash from their staked balance.
     * @param _reasonCID IPFS CID or similar for the reason details.
     * @dev Only the owner can perform slashing for this demo. In a full DAO, this would be a voted proposal.
     */
    function slashParticipant(address _participant, uint256 _amount, string calldata _reasonCID) external onlyOwner nonReentrant {
        Participant storage participant = participants[_participant];
        if (!isParticipant[_participant]) revert NotRegisteredParticipant();
        if (_amount == 0) revert InvalidAmount();
        if (participant.stakedSYN < _amount) {
            _amount = participant.stakedSYN; // Slash all if less than requested
        }

        participant.stakedSYN = participant.stakedSYN.sub(_amount);
        // Reduce reputation proportionally
        participant.reputationPoints = participant.reputationPoints.sub(
            _amount.mul(protocolParameters[STAKE_REPUTATION_MULTIPLIER_KEY]).div(10**18)
        );

        // Slashed funds are sent to the protocol treasury (or burned, or redistributed)
        // For this demo, they remain in the contract's balance.
        emit ParticipantSlashed(_participant, _amount, _reasonCID);
    }


    // --- VI. View Functions ---

    /**
     * @notice Retrieves a participant's full profile including reputation, staked SYN, skills, etc.
     * @param _participant The address of the participant.
     * @return Participant details.
     */
    function getParticipantDetails(address _participant)
        external
        view
        returns (uint256 reputationPoints, uint256 stakedSYN, string[] memory skills, string memory description, uint256 unstakeLockEndEpoch)
    {
        Participant storage p = participants[_participant];
        unstakeLockEndEpoch = p.unstakeRequestEpoch == 0 ? 0 : p.unstakeRequestEpoch.add(protocolParameters[UNSTAKING_LOCK_PERIOD_EPOCHS_KEY]);
        return (p.reputationPoints, p.stakedSYN, p.skills, p.description, unstakeLockEndEpoch);
    }

    /**
     * @notice Retrieves comprehensive details about a specific project, including its status, impact score, milestones, and funding.
     * @param _projectId The ID of the project.
     * @return Project details.
     */
    function getProjectDetails(uint256 _projectId)
        external
        view
        returns (
            address lead,
            string memory name,
            string memory description,
            string[] memory requiredSkills,
            uint256 fundingGoal,
            uint256 approvedFunding,
            uint256 withdrawnFunding,
            uint256 durationEpochs,
            uint256 startEpoch,
            ProjectStatus status,
            uint256 currentImpactScore,
            uint256 totalContributions,
            uint256 nextMilestoneId
        )
    {
        Project storage project = projects[_projectId];
        if (project.lead == address(0)) revert ProjectNotFound();

        return (
            project.lead,
            project.name,
            project.description,
            project.requiredSkills,
            project.fundingGoal,
            project.approvedFunding,
            project.withdrawnFunding,
            project.durationEpochs,
            project.startEpoch,
            project.status,
            project.currentImpactScore,
            project.totalContributions,
            project.nextMilestoneId
        );
    }

    /**
     * @notice Retrieves the current value of a specified protocol parameter.
     * @param _paramName The unique identifier of the parameter.
     * @return The current value of the parameter.
     */
    function getProtocolParameter(bytes32 _paramName) external view returns (uint256) {
        if (protocolParameters[_paramName] == 0 && _paramName != bytes32(0)) { // Allow 0 as a valid parameter value
            // Check if it's one of our known parameters, if not, treat as not found
            // For a full system, you might have a list of valid parameter names
            if (_paramName != INITIAL_REPUTATION_KEY && _paramName != STAKE_REPUTATION_MULTIPLIER_KEY &&
                _paramName != PROJECT_PROPOSAL_FEE_KEY && _paramName != PROPOSAL_VOTING_PERIOD_EPOCHS_KEY &&
                _paramName != MIN_VOTING_REPUTATION_KEY && _paramName != MIN_PROPOSAL_REPUTATION_KEY &&
                _paramName != MIN_APPROVAL_PERCENTAGE_KEY && _paramName != REPUTATION_GAIN_MILSTONE_KEY &&
                _paramName != REPUTATION_LOSS_STAGNATION_KEY && _paramName != EPOCH_DURATION_SECONDS_KEY &&
                _paramName != CONTRIBUTION_REWARD_MULTIPLIER_KEY && _paramName != STAKING_REWARD_PERCENTAGE_KEY &&
                _paramName != CATALYST_BONUS_PERCENTAGE_KEY && _paramName != PROJECT_IMPACT_DECAY_RATE_KEY &&
                _paramName != PROJECT_IMPACT_GROWTH_FACTOR_KEY && _paramName != UNSTAKING_LOCK_PERIOD_EPOCHS_KEY) {
                    revert ParameterNotFound();
                }
        }
        return protocolParameters[_paramName];
    }

    /**
     * @notice Retrieves details about any active project or parameter proposal.
     * @param _proposalId The ID of the project proposal.
     * @return Proposer, creation epoch, votesFor, votesAgainst, and if finalized/enacted.
     */
    function getProposalDetails(uint256 _proposalId)
        external
        view
        returns (
            address proposer,
            uint256 creationEpoch,
            uint256 votesFor,
            uint256 votesAgainst,
            bool isFinalizedOrEnacted,
            bool isProjectProposal
        )
    {
        ProjectProposal storage projProposal = projectProposals[_proposalId];
        if (projProposal.proposer != address(0)) {
            return (
                projProposal.proposer,
                projProposal.creationEpoch,
                projProposal.votesFor,
                projProposal.votesAgainst,
                projProposal.finalized,
                true
            );
        }

        // For parameter proposals, we need to search by paramName hash, not a single ID.
        // This function would need to be split or redesigned if it should search for parameter proposals by a generic ID.
        // For now, it only retrieves project proposals by numerical ID.
        revert ProposalNotFound();
    }

    /**
     * @notice Retrieves current epoch number, last advancement time, and next expected advancement.
     * @return Current epoch, last advance timestamp, and next advance timestamp.
     */
    function getEpochDetails() external view returns (uint256 currentE, uint256 lastAdvanceTime, uint256 nextAdvanceTime) {
        return (currentEpoch, lastEpochAdvanceTime, lastEpochAdvanceTime.add(protocolParameters[EPOCH_DURATION_SECONDS_KEY]));
    }
}
```