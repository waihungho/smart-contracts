Okay, this is an exciting challenge! Let's design a smart contract for a "QuantumLeap DAO" – a decentralized venture and innovation fund that uses advanced governance mechanisms, reputation systems, and dynamic incentive structures to fund highly speculative but potentially transformative projects.

The core idea is to move beyond simple token-weighted voting to incorporate long-term commitment, active participation, and a structured lifecycle for funded projects, all while maintaining adaptability in a rapidly changing environment.

---

## QuantumLeap DAO: Decentralized Venture & Innovation Fund

This contract defines a sophisticated Decentralized Autonomous Organization (DAO) designed to identify, fund, and govern high-risk, high-reward "Quantum Leap" projects. It integrates advanced concepts such as:

1.  **Liquid Reputation-Based Governance:** Voting power is not solely based on token holdings but is augmented by a reputation score earned through active participation, successful project vetting, and long-term staking. Users can also delegate their combined token and reputation-based voting power.
2.  **Dynamic Staking & Anti-Slashing:** Staking `QLT` tokens grants governance rights and earns rewards. A unique anti-slashing mechanism encourages long-term commitment, potentially imposing minor penalties for early unstaking unless justified by a governance vote.
3.  **Venture Project Lifecycle Management:** A structured process for projects to be proposed, undergo due diligence (through special committees), receive multi-stage funding, report milestones, and be monitored for performance.
4.  **Impact & Achievement NFTs (non-transferable):** ERC-721 tokens issued to contributors who significantly impact the DAO (e.g., successfully vetting a project, consistently voting on winning proposals, reaching specific reputation thresholds). These NFTs amplify reputation and unlock special privileges.
5.  **Adaptive Treasury & Dynamic Fee Structure:** The DAO can dynamically adjust fees on various operations (e.g., project funding success fees, unstaking fees) based on performance, market conditions, or governance decisions, ensuring sustainability.
6.  **Emergency Protocol & Circuit Breakers:** Mechanisms for the DAO to enter an "emergency mode" in critical situations (e.g., major exploit, market crash), allowing for swift, pre-approved actions or pausing non-critical operations.

### Outline

*   **Libraries & Interfaces:**
    *   `ERC20` (for QLT Token)
    *   `ERC721` (for ImpactNFTs)
    *   `Ownable` (for initial deployment and administrative setup, eventually to be deprecated or limited post-DAO initialization)
    *   `SafeERC20` (for secure token interactions)
    *   `ReentrancyGuard`
*   **Errors:** Custom errors for clarity and gas efficiency.
*   **Enums:**
    *   `ProposalStatus`: `Pending`, `Active`, `Succeeded`, `Failed`, `Executed`
    *   `ProjectStatus`: `Proposed`, `UnderReview`, `ApprovedForFunding`, `FundingInProgress`, `MilestoneReview`, `Completed`, `Failed`, `Offboarded`
    *   `MilestoneStatus`: `PendingSubmission`, `Submitted`, `UnderReview`, `Approved`, `Rejected`
*   **Structs:**
    *   `Proposal`: Details of a governance proposal.
    *   `Project`: Details of a venture project.
    *   `Milestone`: Details for project milestones.
*   **State Variables:**
    *   Tokens: `QLT` (ERC20), `ImpactNFT` (ERC721)
    *   DAO Parameters: `quorumPercentage`, `votingPeriod`, `minStakeForProposal`, `unstakePenaltyRate`, `protocolFeeRate`, `emergencyModeActive`
    *   Mappings: `stakedBalances`, `userReputation`, `delegates`, `proposalData`, `votedProposals`, `projectData`, `milestoneData`, `_projectWhitelistedAddress`, `impactNFTsMinted`
    *   Counters: `proposalCounter`, `projectCounter`, `impactNFTCounter`
*   **Events:** For all significant state changes.
*   **Modifiers:** Access control, state checks.
*   **Core Modules (Functions):**
    1.  **Initialization & Access Control**
    2.  **QLT Token Management**
    3.  **Impact NFT Management**
    4.  **Staking & Reputation System**
    5.  **Liquid Governance (Proposals & Voting)**
    6.  **Venture Project Lifecycle**
    7.  **Treasury & Fee Management**
    8.  **Emergency Protocols**
    9.  **Query & Utility Functions**

---

### Function Summary (25+ Functions)

1.  `constructor`: Initializes the DAO, deploys QLT & ImpactNFT contracts.
2.  `initializeDAOParameters`: Sets initial governance parameters (quorum, voting period, etc.). (Admin/Owner initially, later DAO governed)
3.  `stakeQLT`: Allows users to stake QLT, gaining voting power and reputation.
4.  `unstakeQLT`: Allows users to unstake QLT, potentially incurring a penalty if early.
5.  `claimStakingRewards`: Distributes accumulated staking rewards to active stakers.
6.  `delegateVote`: Allows users to delegate their voting power (QLT + Reputation) to another address.
7.  `undelegateVote`: Removes a previously set delegation.
8.  `createProposal`: Initiates a new governance proposal (requires min stake).
9.  `voteOnProposal`: Allows stakers to cast a vote (yes/no) on an active proposal.
10. `executeProposal`: Executes the action of a successful proposal.
11. `proposeNewVentureProject`: Whitelisted addresses can propose a new project for funding.
12. `submitProjectDueDiligence`: Special committee members can submit their review reports for a proposed project.
13. `approveProjectForFunding`: A governance proposal that, if passed, moves a project to `ApprovedForFunding`.
14. `disburseProjectFunding`: Transfers funds to an approved project (potentially in tranches).
15. `submitProjectMilestone`: Allows a funded project to report completion of a milestone.
16. `reviewProjectMilestone`: DAO (via proposal or delegated committee) reviews and approves/rejects a milestone.
17. `requestAdditionalProjectFunding`: A project can request more funds (requires new proposal).
18. `mintImpactNFT`: Mints a non-transferable ImpactNFT for a user based on specific achievements.
19. `updateUserReputation`: Internal function, triggered by actions like voting, milestone verification, etc.
20. `adjustProtocolFeeRate`: Governance proposal to change various DAO fee rates.
21. `collectProtocolFees`: Allows authorized roles to collect accrued protocol fees into the treasury.
22. `transferTreasuryFunds`: Transfers funds from the DAO treasury (via governance proposal).
23. `activateEmergencyProtocol`: Owner/DAO can activate emergency mode, pausing certain functions.
24. `deactivateEmergencyProtocol`: Owner/DAO can deactivate emergency mode.
25. `emergencyPauseFunds`: Pauses all external fund transfers (part of emergency protocol).
26. `addProjectWhitelistedAddress`: Adds an address to the list of allowed project proposers (DAO governed).
27. `removeProjectWhitelistedAddress`: Removes an address from the project proposer whitelist (DAO governed).
28. `getVotingPower`: Calculates a user's current voting power (QLT + Reputation + Delegation).
29. `getProjectDetails`: Fetches details of a specific project.
30. `getProposalDetails`: Fetches details of a specific proposal.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

// Custom Errors for clarity and gas efficiency
error NotEnoughStake();
error ProposalNotFound();
error ProposalNotActive();
error AlreadyVoted();
error QuorumNotReached();
error ProposalFailed();
error ProposalAlreadyExecuted();
error InvalidProposalState();
error NotProjectProposer();
error ProjectNotFound();
error MilestoneNotFound();
error UnauthorizedAction();
error EmergencyModeActive();
error ZeroAddressNotAllowed();
error AmountMustBePositive();
error CannotUnstakeEarly();
error DelegateeCannotBeSelf();
error NoDelegationToUndelegate();
error NoStakedBalance();
error InsufficientTreasuryFunds();
error ProjectNotApprovedForFunding();
error MilestoneNotApproved();

// --- Interfaces ---
// Assuming QLT is a separate ERC20 contract deployed earlier
interface IQLTToken is IERC20 {
    function mint(address to, uint256 amount) external;
    function burn(uint256 amount) external;
}

// --- QuantumLeapDAO Core Contract ---
contract QuantumLeapDAO is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;
    using Counters for Counters.Counter;

    // --- State Variables ---

    // Token Contracts
    IQLTToken public immutable QLT;
    ImpactNFT public immutable impactNFT;

    // DAO Parameters (set by owner initially, then via governance)
    uint256 public quorumPercentage; // e.g., 4% (400 for 4.00%)
    uint256 public votingPeriod;     // in seconds, e.g., 3 days
    uint256 public minStakeForProposal; // Minimum QLT required to create a proposal
    uint256 public unstakePenaltyRate; // e.g., 5% (500 for 5.00%) for early unstake
    uint256 public minUnstakeLockupPeriod; // e.g., 30 days
    uint256 public protocolFeeRate; // Percentage of successful project funding collected as fee

    // DAO State
    bool public emergencyModeActive; // If true, limits certain operations

    // Counters for unique IDs
    Counters.Counter private _proposalCounter;
    Counters.Counter private _projectCounter;

    // Mappings
    mapping(address => uint256) public stakedBalances; // QLT staked by user
    mapping(address => uint256) public userReputation; // Reputation score based on activity
    mapping(address => address) public delegates;      // Who an address has delegated their vote to
    mapping(address => uint256) public lastUnstakeTime; // Timestamp of last unstake attempt

    // Governance Proposals
    mapping(uint256 => Proposal) public proposals;
    mapping(uint256 => mapping(address => bool)) public votedProposals; // proposalId => voterAddress => hasVoted

    // Venture Projects
    mapping(uint256 => Project) public projects;
    mapping(uint256 => mapping(uint256 => Milestone)) public projectMilestones; // projectId => milestoneIndex => Milestone
    mapping(address => bool) public isProjectWhitelisted; // Addresses allowed to propose projects

    // Impact NFTs tracking
    mapping(address => mapping(uint256 => bool)) public hasImpactNFT; // address => nftId => bool (for non-transferable check)

    // --- Enums ---
    enum ProposalStatus { Pending, Active, Succeeded, Failed, Executed }
    enum ProjectStatus { Proposed, UnderReview, ApprovedForFunding, FundingInProgress, MilestoneReview, Completed, Failed, Offboarded }
    enum MilestoneStatus { PendingSubmission, Submitted, UnderReview, Approved, Rejected }

    // --- Structs ---
    struct Proposal {
        uint256 id;
        address proposer;
        string description;
        address targetContract;
        bytes callData;
        uint256 createdBlock;
        uint256 endBlock;
        uint256 yesVotes;
        uint256 noVotes;
        uint256 totalVotingPowerAtCreation; // Snapshot of total voting power for quorum calculation
        ProposalStatus status;
        bool executed;
    }

    struct Project {
        uint256 id;
        address proposer;
        string name;
        string description;
        address payable fundsRecipient; // Address to send funding to
        uint256 totalFundingApproved;
        uint256 totalFundingDisbursed;
        ProjectStatus status;
        uint256 totalMilestones;
        uint256 completedMilestones;
    }

    struct Milestone {
        uint256 projectId;
        uint256 milestoneIndex;
        string description;
        uint256 fundingAmount; // Amount to disburse for this milestone
        MilestoneStatus status;
        address verifier; // Address that approved the milestone
    }

    // --- Events ---
    event DAOInitialized(address indexed owner, address indexed qltToken, address indexed impactNFT);
    event QLTStaked(address indexed user, uint256 amount, uint256 newBalance);
    event QLTUnstaked(address indexed user, uint256 amount, uint256 penalty);
    event StakingRewardsClaimed(address indexed user, uint256 amount);
    event VoteDelegated(address indexed delegator, address indexed delegatee);
    event VoteUndelegated(address indexed delegator);
    event ProposalCreated(uint256 indexed proposalId, address indexed proposer, string description, uint256 endBlock);
    event Voted(uint256 indexed proposalId, address indexed voter, bool support, uint256 votingPower);
    event ProposalExecuted(uint256 indexed proposalId);
    event ProposalStatusChanged(uint256 indexed proposalId, ProposalStatus newStatus);
    event VentureProjectProposed(uint256 indexed projectId, address indexed proposer, string name, address fundsRecipient);
    event VentureProjectStatusChanged(uint256 indexed projectId, ProjectStatus newStatus);
    event ProjectFundingDisbursed(uint256 indexed projectId, uint256 amount, address indexed recipient);
    event ProjectMilestoneSubmitted(uint256 indexed projectId, uint256 indexed milestoneIndex);
    event ProjectMilestoneStatusChanged(uint256 indexed projectId, uint256 indexed milestoneIndex, MilestoneStatus newStatus);
    event ImpactNFTMinted(address indexed recipient, uint256 indexed tokenId, string tokenURI);
    event ProtocolFeeRateAdjusted(uint256 newRate);
    event TreasuryFundsTransferred(address indexed recipient, uint256 amount);
    event EmergencyModeActivated(address indexed activatedBy);
    event EmergencyModeDeactivated(address indexed deactivatedBy);
    event FundsEmergencyPaused(address indexed pauser);
    event ProjectWhitelisted(address indexed addr, bool isWhitelisted);
    event ReputationUpdated(address indexed user, uint256 newReputation);

    // --- Modifiers ---
    modifier onlyDAO() {
        // This modifier signifies that only a successfully executed governance proposal
        // can call this function by the DAO's own address.
        // In practice, `executeProposal` would call this contract itself.
        require(msg.sender == address(this), "Only DAO governance can call this");
        _;
    }

    modifier notEmergencyMode() {
        require(!emergencyModeActive, "Emergency mode is active");
        _;
    }

    modifier onlyProjectWhitelistedProposer() {
        require(isProjectWhitelisted[msg.sender], "Caller not whitelisted to propose projects");
        _;
    }

    // --- Constructor ---
    constructor(address _qltTokenAddress) Ownable(msg.sender) {
        require(_qltTokenAddress != address(0), "QLT Token address cannot be zero");

        QLT = IQLTToken(_qltTokenAddress);
        impactNFT = new ImpactNFT(address(this)); // Pass DAO address as minter/authority

        // Initial DAO parameters (these would ideally be set by a DAO proposal post-deployment)
        quorumPercentage = 400; // 4.00%
        votingPeriod = 3 days; // 3 days
        minStakeForProposal = 100 * (10 ** 18); // 100 QLT
        unstakePenaltyRate = 500; // 5.00%
        minUnstakeLockupPeriod = 30 days; // 30 days
        protocolFeeRate = 100; // 1.00% (of approved project funding)

        emergencyModeActive = false;

        emit DAOInitialized(msg.sender, _qltTokenAddress, address(impactNFT));
    }

    // --- 1. Initialization & Access Control ---
    // Note: Many of these admin functions should transition to `onlyDAO` after initialization
    // For simplicity of this example, some start as `onlyOwner`.

    /// @notice Initializes or updates DAO governance parameters.
    /// @dev This function should transition to `onlyDAO` after initial setup.
    /// @param _quorumPercentage The percentage of total voting power required for a quorum (e.g., 400 for 4%).
    /// @param _votingPeriod The duration of a proposal's voting phase in seconds.
    /// @param _minStakeForProposal The minimum QLT stake required to create a proposal.
    /// @param _unstakePenaltyRate The percentage penalty for unstaking before `minUnstakeLockupPeriod`.
    /// @param _minUnstakeLockupPeriod The minimum period (in seconds) before unstaking without penalty.
    /// @param _protocolFeeRate The percentage of approved project funding collected as a protocol fee.
    function initializeDAOParameters(
        uint256 _quorumPercentage,
        uint256 _votingPeriod,
        uint256 _minStakeForProposal,
        uint256 _unstakePenaltyRate,
        uint256 _minUnstakeLockupPeriod,
        uint256 _protocolFeeRate
    ) external onlyOwner { // TODO: Change to onlyDAO after initial setup
        require(_quorumPercentage > 0 && _quorumPercentage <= 10000, "Quorum must be between 0.01% and 100%");
        require(_votingPeriod > 0, "Voting period must be positive");
        require(_minStakeForProposal >= 0, "Min stake cannot be negative");
        require(_unstakePenaltyRate <= 10000, "Penalty rate cannot exceed 100%");
        require(_minUnstakeLockupPeriod >= 0, "Lockup period cannot be negative");
        require(_protocolFeeRate <= 10000, "Protocol fee rate cannot exceed 100%");

        quorumPercentage = _quorumPercentage;
        votingPeriod = _votingPeriod;
        minStakeForProposal = _minStakeForProposal;
        unstakePenaltyRate = _unstakePenaltyRate;
        minUnstakeLockupPeriod = _minUnstakeLockupPeriod;
        protocolFeeRate = _protocolFeeRate;

        emit DAOInitialized(owner(), address(QLT), address(impactNFT)); // Re-emit for parameter updates
    }

    /// @notice Allows the DAO (via governance) to add an address to the whitelist for proposing projects.
    /// @param _addr The address to whitelist.
    function addProjectWhitelistedAddress(address _addr) external onlyDAO {
        require(_addr != address(0), "Address cannot be zero");
        isProjectWhitelisted[_addr] = true;
        emit ProjectWhitelisted(_addr, true);
    }

    /// @notice Allows the DAO (via governance) to remove an address from the whitelist for proposing projects.
    /// @param _addr The address to remove.
    function removeProjectWhitelistedAddress(address _addr) external onlyDAO {
        require(_addr != address(0), "Address cannot be zero");
        isProjectWhitelisted[_addr] = false;
        emit ProjectWhitelisted(_addr, false);
    }

    // --- 2. QLT Token Management (Interacting with external QLT contract) ---
    // QLT supply is managed by its own contract, but DAO might mint/burn for specific purposes
    // (e.g., distributing staking rewards from a pool, or burning penalty fees)

    /// @notice Allows the DAO (via governance) to mint new QLT tokens.
    /// @dev This implies QLT's minter role is given to this DAO contract.
    /// @param _to The recipient of the minted tokens.
    /// @param _amount The amount of QLT to mint.
    function mintQLT(address _to, uint256 _amount) external onlyDAO {
        require(_to != address(0), "Recipient cannot be zero address");
        require(_amount > 0, "Amount must be positive");
        QLT.mint(_to, _amount);
    }

    /// @notice Allows the DAO (via governance) to burn QLT tokens.
    /// @dev This implies QLT's burner role is given to this DAO contract.
    /// @param _amount The amount of QLT to burn.
    function burnQLT(uint256 _amount) external onlyDAO {
        require(_amount > 0, "Amount must be positive");
        QLT.burn(_amount);
    }

    // --- 3. Impact NFT Management ---
    // Impact NFTs are non-transferable and serve as reputation boosters/achievement badges.
    // They are minted by the DAO itself based on specific criteria.

    /// @notice Mints a non-transferable ImpactNFT to a user based on specific achievements.
    /// @dev This function is called internally by DAO actions or by governance proposals.
    /// @param _recipient The address to receive the ImpactNFT.
    /// @param _tokenURI The URI for the NFT metadata (describing the achievement).
    function mintImpactNFT(address _recipient, string memory _tokenURI) internal {
        require(_recipient != address(0), "Recipient cannot be zero address");
        uint256 tokenId = _impactNFTCounter.current();
        _impactNFTCounter.increment();
        impactNFT.mint(_recipient, tokenId, _tokenURI);
        hasImpactNFT[_recipient][tokenId] = true; // Mark as owned by user
        userReputation[_recipient] += 500; // Example: Minting an NFT grants 500 reputation
        emit ImpactNFTMinted(_recipient, tokenId, _tokenURI);
        emit ReputationUpdated(_recipient, userReputation[_recipient]);
    }

    // --- 4. Staking & Reputation System ---

    /// @notice Allows a user to stake QLT tokens, increasing their voting power and reputation.
    /// @param _amount The amount of QLT to stake.
    function stakeQLT(uint256 _amount) external nonReentrant notEmergencyMode {
        if (_amount == 0) revert AmountMustBePositive();
        QLT.safeTransferFrom(msg.sender, address(this), _amount);
        stakedBalances[msg.sender] += _amount;
        userReputation[msg.sender] += (_amount / 1e18) * 10; // Example: 10 reputation per staked QLT
        emit QLTStaked(msg.sender, _amount, stakedBalances[msg.sender]);
        emit ReputationUpdated(msg.sender, userReputation[msg.sender]);
    }

    /// @notice Allows a user to unstake QLT tokens, potentially incurring a penalty.
    /// @param _amount The amount of QLT to unstake.
    function unstakeQLT(uint256 _amount) external nonReentrant notEmergencyMode {
        if (_amount == 0) revert AmountMustBePositive();
        if (stakedBalances[msg.sender] < _amount) revert NotEnoughStake();
        if (stakedBalances[msg.sender] == 0) revert NoStakedBalance();

        uint256 penalty = 0;
        if (block.timestamp < lastUnstakeTime[msg.sender] + minUnstakeLockupPeriod) {
            penalty = (_amount * unstakePenaltyRate) / 10000; // Calculate penalty based on rate
            stakedBalances[msg.sender] -= penalty; // Reduce stake by penalty amount
            // The penalty amount is conceptually "burned" or re-distributed by the DAO
            // For simplicity, we just reduce the user's balance and don't explicitly track a separate 'penalty pool'
        }

        stakedBalances[msg.sender] -= _amount;
        lastUnstakeTime[msg.sender] = block.timestamp;

        // Reduce reputation proportionally, ensure it doesn't go below 0
        uint256 reputationToReduce = (_amount / 1e18) * 10; // 10 reputation per QLT unstaked
        if (userReputation[msg.sender] < reputationToReduce) {
            userReputation[msg.sender] = 0;
        } else {
            userReputation[msg.sender] -= reputationToReduce;
        }

        QLT.safeTransfer(msg.sender, _amount - penalty); // Transfer net amount
        emit QLTUnstaked(msg.sender, _amount, penalty);
        emit ReputationUpdated(msg.sender, userReputation[msg.sender]);
    }

    /// @notice Allows stakers to claim staking rewards. (Requires a reward distribution mechanism)
    /// @dev This function would typically integrate with a separate reward pool or yield mechanism.
    /// For this example, it's a placeholder for future implementation.
    function claimStakingRewards() external notEmergencyMode {
        // TODO: Implement actual reward calculation and distribution logic
        // This would involve a reward pool held by the DAO or external source.
        uint256 rewards = 0; // Placeholder
        if (rewards == 0) return; // No rewards to claim

        // QLT.safeTransfer(msg.sender, rewards);
        emit StakingRewardsClaimed(msg.sender, rewards);
    }

    /// @notice Internal function to update a user's reputation score.
    /// @dev Called by various DAO actions like voting, milestone verification, etc.
    /// @param _user The address whose reputation is being updated.
    /// @param _amount The amount to add or subtract from reputation.
    /// @param _add True to add, false to subtract.
    function _updateUserReputation(address _user, uint256 _amount, bool _add) internal {
        if (_add) {
            userReputation[_user] += _amount;
        } else {
            if (userReputation[_user] < _amount) {
                userReputation[_user] = 0;
            } else {
                userReputation[_user] -= _amount;
            }
        }
        emit ReputationUpdated(_user, userReputation[_user]);
    }

    // --- 5. Liquid Governance (Proposals & Voting) ---

    /// @notice Allows a user with sufficient stake to delegate their voting power.
    /// @param _delegatee The address to delegate voting power to.
    function delegateVote(address _delegatee) external {
        if (_delegatee == address(0)) revert ZeroAddressNotAllowed();
        if (_delegatee == msg.sender) revert DelegateeCannotBeSelf();
        delegates[msg.sender] = _delegatee;
        emit VoteDelegated(msg.sender, _delegatee);
    }

    /// @notice Allows a user to remove their vote delegation.
    function undelegateVote() external {
        if (delegates[msg.sender] == address(0)) revert NoDelegationToUndelegate();
        delete delegates[msg.sender];
        emit VoteUndelegated(msg.sender);
    }

    /// @notice Creates a new governance proposal.
    /// @param _description A description of the proposal.
    /// @param _targetContract The address of the contract the proposal will interact with.
    /// @param _callData The encoded function call data for the target contract.
    /// @dev Requires `minStakeForProposal` and cannot be in emergency mode.
    function createProposal(
        string memory _description,
        address _targetContract,
        bytes memory _callData
    ) external notEmergencyMode {
        if (stakedBalances[msg.sender] < minStakeForProposal) revert NotEnoughStake();

        _proposalCounter.increment();
        uint256 proposalId = _proposalCounter.current();

        proposals[proposalId] = Proposal({
            id: proposalId,
            proposer: msg.sender,
            description: _description,
            targetContract: _targetContract,
            callData: _callData,
            createdBlock: block.number,
            endBlock: block.number + (votingPeriod / block.difficulty), // Estimate blocks based on avg block time
            yesVotes: 0,
            noVotes: 0,
            totalVotingPowerAtCreation: _getTotalVotingPower(), // Snapshot total power for quorum
            status: ProposalStatus.Active,
            executed: false
        });

        _updateUserReputation(msg.sender, 50, true); // Proposing earns reputation
        emit ProposalCreated(proposalId, msg.sender, _description, proposals[proposalId].endBlock);
    }

    /// @notice Allows a user to vote on an active proposal.
    /// @param _proposalId The ID of the proposal to vote on.
    /// @param _support True for 'yes', false for 'no'.
    function voteOnProposal(uint256 _proposalId, bool _support) external notEmergencyMode {
        Proposal storage p = proposals[_proposalId];
        if (p.id == 0) revert ProposalNotFound();
        if (p.status != ProposalStatus.Active) revert ProposalNotActive();
        if (votedProposals[_proposalId][msg.sender]) revert AlreadyVoted();

        // Resolve voting power: check if user delegated, then get their power
        address effectiveVoter = delegates[msg.sender] == address(0) ? msg.sender : delegates[msg.sender];
        uint256 voterPower = getVotingPower(effectiveVoter);

        if (voterPower == 0) revert NotEnoughStake(); // No voting power to cast a vote

        if (_support) {
            p.yesVotes += voterPower;
        } else {
            p.noVotes += voterPower;
        }
        votedProposals[_proposalId][msg.sender] = true;
        _updateUserReputation(msg.sender, 10, true); // Voting earns reputation

        emit Voted(_proposalId, msg.sender, _support, voterPower);
    }

    /// @notice Executes a successful governance proposal.
    /// @param _proposalId The ID of the proposal to execute.
    function executeProposal(uint256 _proposalId) external nonReentrant notEmergencyMode {
        Proposal storage p = proposals[_proposalId];
        if (p.id == 0) revert ProposalNotFound();
        if (p.executed) revert ProposalAlreadyExecuted();
        if (block.number <= p.endBlock) revert ProposalNotActive(); // Voting period not over

        uint256 totalVotes = p.yesVotes + p.noVotes;
        uint256 requiredQuorum = (p.totalVotingPowerAtCreation * quorumPercentage) / 10000;

        if (totalVotes < requiredQuorum) {
            p.status = ProposalStatus.Failed;
            emit ProposalStatusChanged(_proposalId, ProposalStatus.Failed);
            revert QuorumNotReached();
        }

        if (p.yesVotes <= p.noVotes) {
            p.status = ProposalStatus.Failed;
            emit ProposalStatusChanged(_proposalId, ProposalStatus.Failed);
            revert ProposalFailed();
        }

        // Proposal succeeded, attempt execution
        (bool success, ) = p.targetContract.call(p.callData);
        if (!success) {
            // If execution fails, mark as failed and log, but don't revert entire transaction
            p.status = ProposalStatus.Failed;
            emit ProposalStatusChanged(_proposalId, ProposalStatus.Failed);
            // Optionally, log error reason from call here if solidity version supports it or use try/catch
            // emit ProposalExecutionFailed(_proposalId, "Call to target contract failed");
            revert InvalidProposalState(); // Revert for external clarity
        }

        p.executed = true;
        p.status = ProposalStatus.Executed;
        _updateUserReputation(p.proposer, 100, true); // Proposer of successful proposal earns more reputation
        emit ProposalExecuted(_proposalId);
        emit ProposalStatusChanged(_proposalId, ProposalStatus.Executed);

        // Optionally, mint an ImpactNFT for significant contributors or successful proposers
        mintImpactNFT(p.proposer, string(abi.encodePacked("ipfs://quantumleap.dao/impact/proposal_success_", Strings.toString(_proposalId))));
    }

    // --- 6. Venture Project Lifecycle ---

    /// @notice Allows a whitelisted address to propose a new venture project.
    /// @param _name The name of the project.
    /// @param _description A detailed description of the project.
    /// @param _fundsRecipient The address where funds will be disbursed if approved.
    /// @param _totalMilestones The total number of milestones for the project.
    function proposeNewVentureProject(
        string memory _name,
        string memory _description,
        address payable _fundsRecipient,
        uint256 _totalMilestones
    ) external onlyProjectWhitelistedProposer notEmergencyMode {
        if (_fundsRecipient == address(0)) revert ZeroAddressNotAllowed();
        if (_totalMilestones == 0) revert AmountMustBePositive();

        _projectCounter.increment();
        uint256 projectId = _projectCounter.current();

        projects[projectId] = Project({
            id: projectId,
            proposer: msg.sender,
            name: _name,
            description: _description,
            fundsRecipient: _fundsRecipient,
            totalFundingApproved: 0,
            totalFundingDisbursed: 0,
            status: ProjectStatus.Proposed,
            totalMilestones: _totalMilestones,
            completedMilestones: 0
        });

        // Initial empty milestones. Milestones are added with funding proposals.
        for (uint256 i = 0; i < _totalMilestones; i++) {
            projectMilestones[projectId][i] = Milestone({
                projectId: projectId,
                milestoneIndex: i,
                description: "", // Description set during funding proposal
                fundingAmount: 0, // Amount set during funding proposal
                status: MilestoneStatus.PendingSubmission,
                verifier: address(0)
            });
        }

        _updateUserReputation(msg.sender, 20, true); // Proposing a project earns reputation
        emit VentureProjectProposed(projectId, msg.sender, _name, _fundsRecipient);
        emit VentureProjectStatusChanged(projectId, ProjectStatus.Proposed);
    }

    /// @notice Allows the DAO (via governance proposal) to approve a project for funding and define its milestones.
    /// @dev This function is intended to be called by `executeProposal`.
    /// @param _projectId The ID of the project to approve.
    /// @param _milestoneDescriptions Array of descriptions for each milestone.
    /// @param _milestoneAmounts Array of funding amounts for each milestone.
    function approveProjectForFunding(
        uint256 _projectId,
        string[] memory _milestoneDescriptions,
        uint256[] memory _milestoneAmounts
    ) external onlyDAO {
        Project storage p = projects[_projectId];
        if (p.id == 0) revert ProjectNotFound();
        if (p.status != ProjectStatus.Proposed && p.status != ProjectStatus.UnderReview) revert InvalidProposalState();
        if (_milestoneDescriptions.length != p.totalMilestones || _milestoneAmounts.length != p.totalMilestones) {
            revert("Milestone data mismatch");
        }

        uint256 totalApproved = 0;
        for (uint256 i = 0; i < p.totalMilestones; i++) {
            Milestone storage m = projectMilestones[_projectId][i];
            m.description = _milestoneDescriptions[i];
            m.fundingAmount = _milestoneAmounts[i];
            totalApproved += _milestoneAmounts[i];
        }

        p.totalFundingApproved = totalApproved;
        p.status = ProjectStatus.ApprovedForFunding;
        emit VentureProjectStatusChanged(_projectId, ProjectStatus.ApprovedForFunding);
        _updateUserReputation(p.proposer, 50, true); // Project approval boosts proposer reputation
    }

    /// @notice Disburses funds to a project for a specific milestone.
    /// @dev This function is intended to be called by `executeProposal` after a milestone is approved.
    /// @param _projectId The ID of the project.
    /// @param _milestoneIndex The index of the milestone to fund.
    function disburseProjectFunding(uint256 _projectId, uint256 _milestoneIndex) external onlyDAO nonReentrant {
        Project storage p = projects[_projectId];
        if (p.id == 0) revert ProjectNotFound();
        if (p.status != ProjectStatus.ApprovedForFunding && p.status != ProjectStatus.FundingInProgress && p.status != ProjectStatus.MilestoneReview) {
            revert ProjectNotApprovedForFunding();
        }
        if (_milestoneIndex >= p.totalMilestones) revert MilestoneNotFound();

        Milestone storage m = projectMilestones[_projectId][_milestoneIndex];
        if (m.status != MilestoneStatus.Approved) revert MilestoneNotApproved();
        if (m.fundingAmount == 0) revert("Milestone has no funding amount");
        if (address(this).balance < m.fundingAmount) revert InsufficientTreasuryFunds();

        // Calculate and collect protocol fees
        uint256 fee = (m.fundingAmount * protocolFeeRate) / 10000;
        uint256 amountToDisburse = m.fundingAmount - fee;

        p.fundsRecipient.transfer(amountToDisburse);
        p.totalFundingDisbursed += m.fundingAmount; // Total includes fee for record-keeping
        p.status = ProjectStatus.FundingInProgress; // Or keep MilestoneReview if it's the next step

        emit ProjectFundingDisbursed(_projectId, amountToDisburse, p.fundsRecipient);
        // The fee amount implicitly remains in the DAO treasury
    }

    /// @notice Allows a funded project's proposer to submit a milestone for review.
    /// @param _projectId The ID of the project.
    /// @param _milestoneIndex The index of the milestone being submitted.
    function submitProjectMilestone(uint256 _projectId, uint256 _milestoneIndex) external notEmergencyMode {
        Project storage p = projects[_projectId];
        if (p.id == 0) revert ProjectNotFound();
        if (p.proposer != msg.sender) revert UnauthorizedAction();
        if (_milestoneIndex >= p.totalMilestones) revert MilestoneNotFound();

        Milestone storage m = projectMilestones[_projectId][_milestoneIndex];
        if (m.status != MilestoneStatus.PendingSubmission) revert("Milestone not pending submission");

        m.status = MilestoneStatus.Submitted;
        emit ProjectMilestoneSubmitted(_projectId, _milestoneIndex);
        emit ProjectMilestoneStatusChanged(_projectId, _milestoneIndex, MilestoneStatus.Submitted);
    }

    /// @notice Allows the DAO (via governance proposal) to review and approve/reject a project milestone.
    /// @dev This function is intended to be called by `executeProposal`.
    /// @param _projectId The ID of the project.
    /// @param _milestoneIndex The index of the milestone to review.
    /// @param _approved True to approve, false to reject.
    function reviewProjectMilestone(
        uint256 _projectId,
        uint256 _milestoneIndex,
        bool _approved
    ) external onlyDAO {
        Project storage p = projects[_projectId];
        if (p.id == 0) revert ProjectNotFound();
        if (_milestoneIndex >= p.totalMilestones) revert MilestoneNotFound();

        Milestone storage m = projectMilestones[_projectId][_milestoneIndex];
        if (m.status != MilestoneStatus.Submitted && m.status != MilestoneStatus.UnderReview) {
            revert("Milestone not submitted for review");
        }

        m.verifier = msg.sender; // The DAO itself, or the delegated committee member who called this
        if (_approved) {
            m.status = MilestoneStatus.Approved;
            p.completedMilestones++;
            if (p.completedMilestones == p.totalMilestones) {
                p.status = ProjectStatus.Completed;
                emit VentureProjectStatusChanged(_projectId, ProjectStatus.Completed);
                // Mint NFT for successful project completion
                mintImpactNFT(p.proposer, string(abi.encodePacked("ipfs://quantumleap.dao/impact/project_complete_", Strings.toString(_projectId))));
            } else {
                p.status = ProjectStatus.MilestoneReview; // Or FundingInProgress, depending on flow
            }
            _updateUserReputation(msg.sender, 30, true); // Reviewing and approving milestones earns reputation
        } else {
            m.status = MilestoneStatus.Rejected;
            p.status = ProjectStatus.Failed; // Rejecting a milestone might fail the project
            _updateUserReputation(msg.sender, 15, true); // Even rejecting can show participation
        }
        emit ProjectMilestoneStatusChanged(_projectId, _milestoneIndex, m.status);
    }

    /// @notice Allows a project to request additional funding, triggering a new governance proposal.
    /// @dev The actual funding approval and disbursement happens via `createProposal` and `executeProposal`.
    /// @param _projectId The ID of the project.
    /// @param _amount The additional amount requested.
    /// @param _reason The reason for the additional funding request.
    function requestAdditionalProjectFunding(
        uint256 _projectId,
        uint256 _amount,
        string memory _reason
    ) external notEmergencyMode {
        Project storage p = projects[_projectId];
        if (p.id == 0) revert ProjectNotFound();
        if (p.proposer != msg.sender) revert UnauthorizedAction();
        if (_amount == 0) revert AmountMustBePositive();
        if (p.status == ProjectStatus.Completed || p.status == ProjectStatus.Failed || p.status == ProjectStatus.Offboarded) {
            revert("Project not in active state for additional funding");
        }

        // Project proposer needs to create a new governance proposal for this additional funding
        // The `targetContract` would be this DAO, and `callData` would be for `disburseProjectFunding`
        // after a new proposal that details the additional funding and potentially new milestones.
        // For simplicity, this function just registers the request, the actual funding requires a new DAO vote.
        // It returns a hint that a proposal is needed.
        emit ProjectMilestoneSubmitted(_projectId, 999); // Use a special index for funding request if needed
    }

    /// @notice Allows the DAO (via governance) to formally offboard a project (e.g., failed, completed).
    /// @param _projectId The ID of the project to offboard.
    function offboardProject(uint256 _projectId) external onlyDAO {
        Project storage p = projects[_projectId];
        if (p.id == 0) revert ProjectNotFound();
        if (p.status == ProjectStatus.Offboarded) revert("Project already offboarded");

        p.status = ProjectStatus.Offboarded;
        emit VentureProjectStatusChanged(_projectId, ProjectStatus.Offboarded);
    }

    // --- 7. Treasury & Fee Management ---

    /// @notice Allows the DAO (via governance) to adjust the protocol fee rate.
    /// @param _newRate The new percentage rate (e.g., 100 for 1.00%).
    function adjustProtocolFeeRate(uint256 _newRate) external onlyDAO {
        require(_newRate <= 10000, "Fee rate cannot exceed 100%");
        protocolFeeRate = _newRate;
        emit ProtocolFeeRateAdjusted(_newRate);
    }

    /// @notice Allows the DAO (via governance) to transfer funds from its treasury.
    /// @param _recipient The address to send funds to.
    /// @param _amount The amount of funds to transfer.
    function transferTreasuryFunds(address _recipient, uint256 _amount) external onlyDAO nonReentrant {
        if (_recipient == address(0)) revert ZeroAddressNotAllowed();
        if (_amount == 0) revert AmountMustBePositive();
        if (address(this).balance < _amount) revert InsufficientTreasuryFunds();

        (bool success, ) = _recipient.call{value: _amount}("");
        require(success, "Failed to transfer treasury funds");
        emit TreasuryFundsTransferred(_recipient, _amount);
    }

    /// @notice Fallback function to receive ETH. Funds received here are part of the DAO treasury.
    receive() external payable {
        // Any direct ETH sent to the contract becomes part of the DAO's treasury.
    }

    // --- 8. Emergency Protocols ---

    /// @notice Activates the emergency protocol, pausing certain sensitive operations.
    /// @dev Can be called by owner initially, or via critical DAO vote.
    function activateEmergencyProtocol() external onlyOwner { // TODO: Change to onlyDAO for full decentralization
        emergencyModeActive = true;
        emit EmergencyModeActivated(msg.sender);
    }

    /// @notice Deactivates the emergency protocol, restoring normal operations.
    /// @dev Can be called by owner initially, or via critical DAO vote.
    function deactivateEmergencyProtocol() external onlyOwner { // TODO: Change to onlyDAO for full decentralization
        emergencyModeActive = false;
        emit EmergencyModeDeactivated(msg.sender);
    }

    /// @notice Pauses external fund transfers if emergency mode is active.
    /// @dev This specific function is not called directly, but its effect is implicit
    /// by requiring `notEmergencyMode` on functions like `unstakeQLT`, `disburseProjectFunding`.
    /// For external ETH transfers out, `transferTreasuryFunds` also respects `notEmergencyMode`.
    /// A true "circuit breaker" might prevent all OUTBOUND ETH/token transfers.
    function emergencyPauseFunds() internal view {
        if (emergencyModeActive) {
            revert FundsEmergencyPaused(msg.sender);
        }
    }

    // --- 9. Query & Utility Functions ---

    /// @notice Gets a user's combined voting power (staked QLT + reputation + delegation).
    /// @param _voter The address of the voter.
    /// @return The calculated voting power.
    function getVotingPower(address _voter) public view returns (uint256) {
        address effectiveVoter = delegates[_voter] == address(0) ? _voter : delegates[_voter];
        return stakedBalances[effectiveVoter] + userReputation[effectiveVoter];
    }

    /// @notice Gets the details of a specific proposal.
    /// @param _proposalId The ID of the proposal.
    /// @return A tuple containing proposal details.
    function getProposalDetails(uint256 _proposalId) public view returns (
        uint256 id, address proposer, string memory description, address targetContract, bytes memory callData,
        uint256 createdBlock, uint256 endBlock, uint256 yesVotes, uint256 noVotes, uint256 totalVotingPowerAtCreation,
        ProposalStatus status, bool executed
    ) {
        Proposal storage p = proposals[_proposalId];
        if (p.id == 0) revert ProposalNotFound();
        return (
            p.id, p.proposer, p.description, p.targetContract, p.callData,
            p.createdBlock, p.endBlock, p.yesVotes, p.noVotes, p.totalVotingPowerAtCreation,
            p.status, p.executed
        );
    }

    /// @notice Gets the details of a specific venture project.
    /// @param _projectId The ID of the project.
    /// @return A tuple containing project details.
    function getProjectDetails(uint256 _projectId) public view returns (
        uint256 id, address proposer, string memory name, string memory description, address fundsRecipient,
        uint256 totalFundingApproved, uint256 totalFundingDisbursed, ProjectStatus status,
        uint256 totalMilestones, uint256 completedMilestones
    ) {
        Project storage p = projects[_projectId];
        if (p.id == 0) revert ProjectNotFound();
        return (
            p.id, p.proposer, p.name, p.description, p.fundsRecipient,
            p.totalFundingApproved, p.totalFundingDisbursed, p.status,
            p.totalMilestones, p.completedMilestones
        );
    }

    /// @notice Gets the details of a specific project milestone.
    /// @param _projectId The ID of the project.
    /// @param _milestoneIndex The index of the milestone.
    /// @return A tuple containing milestone details.
    function getMilestoneDetails(uint256 _projectId, uint256 _milestoneIndex) public view returns (
        uint256 projectId, uint256 milestoneIndex, string memory description, uint256 fundingAmount, MilestoneStatus status, address verifier
    ) {
        Project storage p = projects[_projectId];
        if (p.id == 0) revert ProjectNotFound();
        if (_milestoneIndex >= p.totalMilestones) revert MilestoneNotFound();
        Milestone storage m = projectMilestones[_projectId][_milestoneIndex];
        return (m.projectId, m.milestoneIndex, m.description, m.fundingAmount, m.status, m.verifier);
    }

    /// @notice Gets the total voting power across all staked tokens and accumulated reputation.
    /// @return The total current voting power.
    function _getTotalVotingPower() internal view returns (uint256) {
        // This is a simplified sum. In a real large-scale DAO,
        // snapshotting total supply or using a proxy for active users would be more complex/efficient.
        // For demonstration, we assume we can sum all current staked balances and reputation.
        // This would be a gas-intensive operation on a large scale.
        // A more advanced system would track total active voting power via checkpoints or a governance token's total supply.
        uint256 totalPower = 0;
        // This loop would be impractical on-chain for many users.
        // In a real system, total voting power would typically be derived from total staked tokens.
        // If reputation is added, it needs a way to sum globally without iterating.
        // For this example, we assume `QLT.totalSupply()` + a global reputation sum from a dedicated contract/system.
        // For now, let's just use `QLT.totalSupply()` as the base for quorum.
        return QLT.totalSupply(); // This is a simplification for quorum calculation
    }
}

// --- ImpactNFT Contract (Non-transferable ERC721) ---
contract ImpactNFT is ERC721 {
    address public minterAddress; // The address of the QuantumLeapDAO contract

    constructor(address _minterAddress) ERC721("QuantumLeapImpact", "QLIMPACT") {
        require(_minterAddress != address(0), "Minter address cannot be zero");
        minterAddress = _minterAddress;
    }

    /// @notice Mints a new ImpactNFT. Only callable by the `minterAddress` (the DAO contract).
    /// @param to The recipient of the NFT.
    /// @param tokenId The unique ID for the NFT.
    /// @param tokenURI The URI for the NFT metadata.
    function mint(address to, uint256 tokenId, string memory tokenURI) external {
        require(msg.sender == minterAddress, "Only the DAO can mint ImpactNFTs");
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, tokenURI);
    }

    /// @notice Overrides transfer functions to make NFTs non-transferable.
    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal pure override {
        super._beforeTokenTransfer(from, to, tokenId);
        // Prevent all transfers after initial minting to address(0)
        // If from is not address(0), it means it's a transfer after initial mint, which is blocked.
        if (from != address(0)) {
            revert("ImpactNFTs are non-transferable");
        }
    }

    // Optional: Allow burning by owner or approved address if specific conditions are met (e.g., losing reputation)
    function burn(uint256 tokenId) public {
        require(_isApprovedOrOwner(msg.sender, tokenId) || msg.sender == minterAddress, "Not authorized to burn");
        _burn(tokenId);
    }

    // Further restrict approvals to ensure non-transferability even with approvals
    function approve(address to, uint256 tokenId) public pure override {
        revert("ImpactNFTs are non-transferable and cannot be approved");
    }

    function setApprovalForAll(address operator, bool approved) public pure override {
        revert("ImpactNFTs are non-transferable and cannot be approved for all");
    }

    function isApprovedForAll(address owner, address operator) public pure override returns (bool) {
        return false; // No approvals for all
    }

    function getApproved(uint256 tokenId) public pure override returns (address) {
        return address(0); // No single token approvals
    }
}
```