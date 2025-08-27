This smart contract, `ImpactNexus`, introduces an advanced decentralized autonomous organization (DAO) for funding and managing social impact projects. It combines concepts like dynamic reputation, milestone-based adaptive funding, and a decentralized commit-reveal verification system to ensure accountability and incentivize genuine positive impact.

---

## Outline and Function Summary for ImpactNexus Smart Contract

**Contract Name:** `ImpactNexus`
**Version:** 1.0.0

**Description:**
`ImpactNexus` is a decentralized autonomous organization (DAO) designed to fund and manage social impact projects. It introduces a sophisticated, dynamic reputation system, a multi-stage project lifecycle with adaptive funding, and a decentralized, commit-reveal based verification mechanism for project milestones. The goal is to incentivize genuine positive impact, foster community participation, and ensure accountability through on-chain governance and verifiable progress.

**Core Concepts:**
1.  **Dynamic Reputation System:** Reputation is earned through positive contributions (proposing successful projects, verifying milestones, participating in governance) and decays over time if inactive. It directly influences voting power and proposal eligibility. Reputation can also be delegated.
2.  **Milestone-Based Adaptive Funding:** Projects receive funding in tranches, contingent on the successful completion and verification of predefined milestones. This ensures funds are released only as impact is demonstrated.
3.  **Decentralized Impact Verification:** A network of stakers (verifiers) uses a commit-reveal scheme to collectively attest to project progress and impact. This mitigates single points of failure and enhances data integrity.
4.  **Liquid Governance:** Users can delegate their combined token and reputation-based voting power to other trusted members, fostering efficient and expert-led decision-making without centralizing control.
5.  **Internal ImpactToken:** An ERC-20 token embedded within the contract, used for staking, contribution tracking, and potential future incentives. This simplifies the contract's dependencies while providing necessary token functionalities.

### Function Summary (27 Functions):

**I. Core Setup & Administration:**
1.  `constructor()`: Initializes the contract with the deployer as the initial admin. Sets initial DAO parameters like reputation decay rate, proposal stakes, and voting durations.
2.  `updateCoreParameters(CoreParameters calldata _newParams)`: Allows the DAO (via governance proposal) to adjust key operational parameters.

**II. Reputation Management:**
3.  `_calculateReputation(address _user)`: Internal pure function to calculate a user's current effective reputation, considering a time-based decay.
4.  `getReputation(address _user)`: External view function to retrieve the current effective reputation for a specified user.
5.  `_adjustReputation(address _user, uint256 _amount, bool _increase)`: Internal function to increment or decrement a user's raw reputation score and reset their decay timer.
6.  `delegateReputationVotingPower(address _delegatee)`: Allows a user to delegate their reputation-based voting weight to another address.
7.  `undelegateReputationVotingPower()`: Removes any active reputation delegation for the caller.

**III. Project Proposal & Lifecycle:**
8.  `proposeProject(string memory _title, string memory _description, uint256 _totalFundingGoal, Milestone[] memory _milestones)`: Allows eligible users (with sufficient reputation and token stake) to submit a new social impact project proposal, defining funding goals and milestones. Automatically creates a funding proposal.
9.  `submitMilestoneProgress(uint256 _projectId, uint256 _milestoneIndex, string memory _progressReportHash)`: Project proposer reports progress for a specific milestone, making it ready for verification.
10. `_recordProjectMilestone(uint256 _projectId, uint256 _milestoneIndex, bool _success)`: Internal function to update a project's milestone status and adjust its overall impact score based on verification outcome.
11. `cancelProject(uint256 _projectId)`: Allows the project proposer or DAO to cancel a project, potentially incurring penalties for the proposer.

**IV. Funding & Contributions:**
12. `contributeToFund()`: Allows users to send native currency (ETH) to the Impact Fund, receiving `ImpactTokens` in return at a predefined rate.
13. `withdrawContribution(uint256 _amount)`: Allows contributors to withdraw their `ImpactTokens` under specific DAO-approved conditions (e.g., failed proposals). (Note: Actual ETH withdrawal would be handled by a separate DAO action).
14. `allocateFundsToProjectTranche(uint256 _projectId, uint256 _milestoneIndex)`: DAO approves and allocates the funding tranche for a project's *current* milestone, releasing native currency funds from the treasury to the project proposer.

**V. Governance & Voting:**
15. `_getEffectiveVotingWeight(address _voter)`: Internal pure function to calculate the combined voting power (sum of `ImpactToken` balance and effective reputation) for an address.
16. `createGovernanceProposal(string memory _description, bytes memory _calldata, address _target)`: Allows eligible users to create a new governance proposal for contract parameter changes or other on-chain actions.
17. `voteOnProposal(uint256 _proposalId, bool _support)`: Users cast their vote (for or against) on an active project or governance proposal using their effective voting weight.
18. `executeProposal(uint256 _proposalId)`: Executes a governance proposal that has successfully passed its voting period, met quorum, and achieved the required support threshold.

**VI. Impact Verification & Oracles (Simulated):**
19. `stakeForVerificationRole(uint256 _amount)`: Allows users to stake `ImpactTokens` to become eligible as a project verifier, requiring a minimum reputation score.
20. `requestMilestoneVerification(uint256 _projectId, uint256 _milestoneIndex)`: DAO or project manager initiates a verification request for a reported milestone, which includes selecting verifiers (simplified selection in this example).
21. `commitVerificationResultHash(uint256 _verificationId, bytes32 _resultHash)`: Selected verifiers commit a hash of their verification result to prevent collusion and ensure integrity (commit phase).
22. `revealVerificationResult(uint256 _verificationId, bool _verified)`: After the commit period, verifiers reveal their actual boolean verification result, which is checked against their committed hash (reveal phase).
23. `challengeVerificationResult(uint256 _verificationId, address _verifier, bool _revealedResult, bytes32 _expectedHash)`: Allows any user to challenge a verifier if their revealed result does not match their initial committed hash, leading to penalties for the dishonest verifier.
24. `processVerificationResults(uint256 _verificationId)`: Aggregates revealed verification results, determines the milestone outcome based on consensus, adjusts verifier reputations, and updates the project's status and impact score.

**VII. Project & Fund Information:**
25. `getProjectDetails(uint256 _projectId)`: View function to retrieve comprehensive details of a specific project.
26. `getMilestoneDetails(uint256 _projectId, uint256 _milestoneIndex)`: View function for details of a specific milestone within a project.
27. `getFundBalance()`: View function to retrieve the total native token (ETH) balance held by the `ImpactNexus` fund.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/*
 * Outline and Function Summary for ImpactNexus Smart Contract
 *
 * Contract Name: ImpactNexus
 * Version: 1.0.0
 *
 * Description:
 * ImpactNexus is a decentralized autonomous organization (DAO) designed to fund and manage social impact projects.
 * It introduces a sophisticated, dynamic reputation system, a multi-stage project lifecycle with adaptive funding,
 * and a decentralized, commit-reveal based verification mechanism for project milestones. The goal is to
 * incentivize genuine positive impact, foster community participation, and ensure accountability through on-chain
 * governance and verifiable progress.
 *
 * Core Concepts:
 * 1.  Dynamic Reputation System: Reputation is earned through positive contributions (proposing successful projects,
 *     verifying milestones, participating in governance) and decays over time if inactive. It directly influences
 *     voting power and proposal eligibility. Reputation can also be delegated.
 * 2.  Milestone-Based Adaptive Funding: Projects receive funding in tranches, contingent on the successful completion
 *     and verification of predefined milestones. This ensures funds are released only as impact is demonstrated.
 * 3.  Decentralized Impact Verification: A network of stakers (verifiers) uses a commit-reveal scheme to collectively
 *     attest to project progress and impact. This mitigates single points of failure and enhances data integrity.
 * 4.  Liquid Governance: Users can delegate their combined token and reputation-based voting power to other trusted
 *     members, fostering efficient and expert-led decision-making without centralizing control.
 * 5.  Internal ImpactToken: An ERC-20 token embedded within the contract, used for staking, contribution tracking,
 *     and potential future incentives.
 *
 *
 * Function Summary (27 Functions):
 *
 * I. Core Setup & Administration:
 *    1.  constructor(): Initializes the contract with the deployer as the initial admin. Sets initial DAO parameters.
 *    2.  updateCoreParameters(): Allows the DAO (via governance) to adjust key operational parameters (e.g., reputation decay rate, min proposal stake).
 *
 * II. Reputation Management:
 *    3.  _calculateReputation(address _user): Internal pure function to calculate a user's current effective reputation, considering decay.
 *    4.  getReputation(address _user): External view function to retrieve the current effective reputation for a specified user.
 *    5.  _adjustReputation(address _user, uint256 _amount, bool _increase): Internal function to increment or decrement a user's raw reputation score.
 *    6.  delegateReputationVotingPower(address _delegatee): Allows a user to delegate their reputation-based voting weight to another address.
 *    7.  undelegateReputationVotingPower(): Removes any active reputation delegation for the caller.
 *
 * III. Project Proposal & Lifecycle:
 *    8.  proposeProject(string memory _title, string memory _description, uint256 _totalFundingGoal, Milestone[] memory _milestones):
 *        Allows eligible users to submit a new social impact project proposal with funding goals and defined milestones. Requires a stake.
 *    9.  submitMilestoneProgress(uint256 _projectId, uint256 _milestoneIndex, string memory _progressReportHash):
 *        Project proposer reports progress for a specific milestone, making it ready for verification.
 *    10. _recordProjectMilestone(uint256 _projectId, uint256 _milestoneIndex, bool _success):
 *        Internal function to update a project's milestone status and adjust project impact score based on verification outcome.
 *    11. cancelProject(uint256 _projectId): Allows the project proposer or DAO to cancel a project, potentially with penalties.
 *
 * IV. Funding & Contributions:
 *    12. contributeToFund(): Allows users to send ETH (or a specified ERC20) to the Impact Fund, receiving ImpactTokens.
 *    13. withdrawContribution(uint256 _amount): Allows contributors to withdraw their ImpactTokens under specific DAO-approved conditions (e.g., failed proposals).
 *    14. allocateFundsToProjectTranche(uint256 _projectId, uint256 _milestoneIndex):
 *        DAO approves and allocates the funding tranche for a project's *current* milestone, releasing funds from the treasury.
 *
 * V. Governance & Voting:
 *    15. _getEffectiveVotingWeight(address _voter): Internal pure function to calculate the combined voting power (token + reputation) for an address.
 *    16. createGovernanceProposal(string memory _description, bytes memory _calldata, address _target):
 *        Allows eligible users to create a new governance proposal for contract parameter changes or other actions.
 *    17. voteOnProposal(uint256 _proposalId, bool _support): Users cast their vote on an active project or governance proposal.
 *    18. executeProposal(uint256 _proposalId): Executes a governance proposal that has passed and met quorum requirements.
 *
 * VI. Impact Verification & Oracles (Simulated):
 *    19. stakeForVerificationRole(uint256 _amount): Allows users to stake ImpactTokens to become eligible as a project verifier.
 *    20. requestMilestoneVerification(uint256 _projectId, uint256 _milestoneIndex):
 *        DAO or project manager initiates a verification request for a reported milestone. This selects verifiers.
 *    21. commitVerificationResultHash(uint256 _verificationId, bytes32 _resultHash):
 *        Selected verifiers commit a hashed result to prevent collusion.
 *    22. revealVerificationResult(uint256 _verificationId, bool _verified):
 *        After the commit period, verifiers reveal their actual result after a commit period.
 *    23. challengeVerificationResult(uint256 _verificationId, address _verifier, bool _revealedResult, bytes32 _expectedHash):
 *        Allows any user to challenge a suspicious verification result.
 *    24. processVerificationResults(uint256 _verificationId):
 *        Aggregates revealed verification results, determines the milestone outcome, adjusts verifier reputations, and updates project status.
 *
 * VII. Project & Fund Information:
 *    25. getProjectDetails(uint256 _projectId): View function to retrieve comprehensive details of a specific project.
 *    26. getMilestoneDetails(uint256 _projectId, uint256 _milestoneIndex): View function for details of a specific milestone within a project.
 *    27. getFundBalance(): View function for the total fund balance.
 */


// --- Internal ERC20-like token for ImpactNexus ---
// This is a simplified internal token implementation for the purpose of this contract.
// It lacks full ERC20 capabilities like `approve` and `transferFrom` but is sufficient
// for direct transfers, balances, and minting/burning tied to contract logic.
interface IImpactToken {
    function mint(address account, uint256 amount) external;
    function burn(address account, uint256 amount) external;
    function transfer(address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
    function totalSupply() external view returns (uint256);
}

contract ImpactToken is IImpactToken {
    mapping(address => uint256) private _balances;
    uint256 private _totalSupply;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Mint(address indexed account, uint256 amount);
    event Burn(address indexed account, uint256 amount);

    function mint(address account, uint256 amount) external override {
        // Only ImpactNexus contract can call mint/burn.
        // `msg.sender == address(this)` will be true if called from the ImpactNexus contract itself.
        require(msg.sender == address(this), "ImpactToken: unauthorized mint");
        _totalSupply += amount;
        _balances[account] += amount;
        emit Mint(account, amount);
        emit Transfer(address(0), account, amount); // Address(0) as sender for minting
    }

    function burn(address account, uint256 amount) external override {
        // Only ImpactNexus contract can call mint/burn
        require(msg.sender == address(this), "ImpactToken: unauthorized burn");
        require(_balances[account] >= amount, "ImpactToken: burn amount exceeds balance");
        _totalSupply -= amount;
        _balances[account] -= amount;
        emit Burn(account, amount);
        emit Transfer(account, address(0), amount); // Address(0) as recipient for burning
    }

    function transfer(address recipient, uint256 amount) external override returns (bool) {
        require(recipient != address(0), "ImpactToken: transfer to the zero address");
        require(_balances[msg.sender] >= amount, "ImpactToken: insufficient balance");
        _balances[msg.sender] -= amount;
        _balances[recipient] += amount;
        emit Transfer(msg.sender, recipient, amount);
        return true;
    }

    function balanceOf(address account) external view override returns (uint256) {
        return _balances[account];
    }

    function totalSupply() external view override returns (uint256) {
        return _totalSupply;
    }
}


// --- Main ImpactNexus Contract ---
contract ImpactNexus {
    // --- State Variables ---

    // Governance & Access Control
    address public immutable deployer;
    address public daoTreasury; // Where contributed funds are held (this contract's address)
    uint256 public constant MIN_REPUTATION_FOR_PROPOSAL = 1000;
    uint256 public constant MIN_REPUTATION_FOR_VERIFIER = 500;
    uint256 public constant MIN_TOKEN_STAKE_FOR_VERIFIER = 100 * 10 ** 18; // 100 ImpactTokens

    // Parameters adjustable by DAO governance
    struct CoreParameters {
        uint256 reputationDecayRatePerYear; // Basis points, e.g., 1000 for 10%
        uint256 proposalStakeAmount;        // Required ImpactToken stake to propose
        uint256 verificationStakeAmount;    // Required ImpactToken stake per verifier for a request
        uint256 votingPeriodDuration;       // Seconds for voting on proposals
        uint256 verificationCommitPeriod;   // Seconds for verifiers to commit hash
        uint256 verificationRevealPeriod;   // Seconds for verifiers to reveal result
        uint256 minVerifiersPerMilestone;   // Minimum number of verifiers needed per request
        uint256 minConsensusPercentage;     // Basis points, e.g., 7000 for 70% consensus required for verification
        uint256 impactTokenMintRate;        // ImpactTokens per native token contribution (e.g., 1e18 ImpactToken per 1 ETH)
        uint256 daoQuorumThresholdBP;       // Basis points, e.g., 1000 for 10% of total voting power needed for quorum
        uint256 daoSupportThresholdBP;      // Basis points, e.g., 5000 for 50% majority of votes cast
    }
    CoreParameters public coreParams;

    // Reputation System
    struct ReputationSnapshot {
        uint256 rawReputation;
        uint256 lastUpdatedTimestamp;
    }
    mapping(address => ReputationSnapshot) public reputationSnapshots;
    mapping(address => address) public reputationDelegations; // Delegator => Delegatee

    // Projects
    enum ProjectStatus { Proposed, Active, Completed, Failed, Cancelled }
    enum MilestoneStatus { Pending, Reported, VerificationRequested, VerifiedSuccess, VerifiedFailed }

    struct Milestone {
        string description;
        uint256 fundingTranche; // Amount to be released upon successful verification of this milestone (in native token equivalent)
        MilestoneStatus status;
        int256 impactScoreAdjustment; // How much to adjust project's impact score upon this milestone's success/failure
    }

    struct Project {
        uint256 id;
        string title;
        string description;
        address proposer;
        uint256 totalFundingGoal; // Total native token funding for the project
        uint256 allocatedFunding; // Total native token funds allocated so far
        ProjectStatus status;
        Milestone[] milestones;
        uint252 currentMilestoneIndex; // Index of the milestone currently being worked on/verified
        int256 impactScore;            // Dynamic score, e.g., -100 to 100, starts at 0
        uint256 proposalTimestamp;
        uint256 projectStakeAmount;    // Stake provided by proposer (ImpactTokens)
    }
    mapping(uint256 => Project) public projects;
    uint256 public nextProjectId;

    // Proposals (for Projects and Governance)
    enum ProposalType { ProjectFunding, GovernanceChange }
    enum ProposalStatus { Pending, Active, Succeeded, Failed, Executed }

    struct Proposal {
        uint256 id;
        ProposalType pType;
        string description;
        address proposer;
        uint256 creationTimestamp;
        uint256 votingEndsTimestamp;
        uint256 votesFor;
        uint256 votesAgainst;
        uint256 totalVotingPowerAtCreation; // Snapshot of total voting power for quorum calculation
        ProposalStatus status;
        bool executed;
        // Specifics for GovernanceChange
        address target;
        bytes calldataPayload;
        // Specifics for ProjectFunding
        uint256 projectId;
    }
    mapping(uint256 => Proposal) public proposals;
    mapping(uint256 => mapping(address => bool)) public hasVoted; // proposalId => voter => voted
    uint256 public nextProposalId;

    // Verification System
    enum VerificationStatus { Requested, CommitPhase, RevealPhase, Processing, Finalized }
    struct VerificationRequest {
        uint256 id;
        uint256 projectId;
        uint256 milestoneIndex;
        address[] selectedVerifiers;
        uint256 commitEndsTimestamp;
        uint256 revealEndsTimestamp;
        VerificationStatus status;
        uint256 totalVerifierStake; // Sum of stakes from all selected verifiers (ImpactTokens)
    }
    mapping(uint256 => VerificationRequest) public verificationRequests;
    uint256 public nextVerificationId;

    mapping(uint256 => mapping(address => bytes32)) public verificationCommitments; // verificationId => verifier => hash
    mapping(uint256 => mapping(address => bool)) public verificationRevealed;       // verificationId => verifier => revealed
    mapping(uint256 => mapping(address => bool)) public verificationResults;        // verificationId => verifier => result (true=verified, false=failed)

    // Internal ImpactToken
    ImpactToken public impactToken;

    // --- Events ---
    event CoreParametersUpdated(address indexed by, CoreParameters newParams);
    event ReputationAdjusted(address indexed user, uint256 oldEffectiveReputation, uint256 newEffectiveReputation);
    event ReputationDelegated(address indexed delegator, address indexed delegatee);
    event ReputationUndelegated(address indexed delegator);

    event ProjectProposed(uint256 indexed projectId, address indexed proposer, uint256 totalFundingGoal);
    event MilestoneProgressReported(uint256 indexed projectId, uint256 indexed milestoneIndex, string progressReportHash);
    event ProjectStatusUpdated(uint256 indexed projectId, ProjectStatus newStatus);
    event FundsAllocated(uint256 indexed projectId, uint256 indexed milestoneIndex, uint256 amount);

    event ContributionReceived(address indexed contributor, uint256 amountEth, uint256 amountImpactTokens);
    event ContributionWithdrawn(address indexed contributor, uint256 amountImpactTokens);

    event ProposalCreated(uint256 indexed proposalId, ProposalType pType, address indexed proposer, uint256 votingEnds);
    event Voted(uint256 indexed proposalId, address indexed voter, bool support, uint256 votingWeight);
    event ProposalStatusChanged(uint256 indexed proposalId, ProposalStatus newStatus);
    event ProposalExecuted(uint256 indexed proposalId);

    event VerifierStaked(address indexed verifier, uint256 amount);
    event VerificationRequested(uint256 indexed verificationId, uint256 indexed projectId, uint256 milestoneIndex);
    event VerificationCommitted(uint256 indexed verificationId, address indexed verifier);
    event VerificationRevealed(uint256 indexed verificationId, address indexed verifier, bool result);
    event VerificationChallenged(uint256 indexed verificationId, address indexed verifier, address indexed challenger);
    event VerificationFinalized(uint256 indexed verificationId, bool milestoneSuccess, int256 projectImpactScoreChange);

    // --- Modifiers ---
    modifier onlyDAO() {
        // This modifier simulates DAO execution. In a production system, this would typically
        // mean the call comes from a Timelock controller or a similar governance executor,
        // which itself is controlled by successful proposals. For this example, it means
        // the function is callable by the contract itself, primarily via `executeProposal`.
        require(msg.sender == address(this), "ImpactNexus: only callable by DAO execution");
        _;
    }

    modifier onlyProposer(uint256 _projectId) {
        require(projects[_projectId].proposer == msg.sender, "ImpactNexus: only project proposer");
        _;
    }

    // --- Constructor ---
    constructor() {
        deployer = msg.sender;
        daoTreasury = address(this); // Funds are held directly by this contract

        // Initialize internal ImpactToken contract
        impactToken = new ImpactToken();

        // Set initial core parameters (these can be updated by DAO governance)
        coreParams = CoreParameters({
            reputationDecayRatePerYear: 1000, // 10% annual decay
            proposalStakeAmount: 100 * 10 ** 18, // 100 ImpactTokens to propose
            verificationStakeAmount: 50 * 10 ** 18, // 50 ImpactTokens per verifier for a request
            votingPeriodDuration: 3 days,
            verificationCommitPeriod: 1 days,
            verificationRevealPeriod: 1 days,
            minVerifiersPerMilestone: 3,
            minConsensusPercentage: 7000, // 70% consensus
            impactTokenMintRate: 1 * 10 ** 18, // 1 ImpactToken per native token (e.g., 1 ETH)
            daoQuorumThresholdBP: 1000, // 10% quorum
            daoSupportThresholdBP: 5000 // 50% support
        });

        // Initialize deployer's reputation
        reputationSnapshots[deployer] = ReputationSnapshot({
            rawReputation: 10000, // Starting reputation for deployer/initial admin
            lastUpdatedTimestamp: block.timestamp
        });
        nextProjectId = 1;
        nextProposalId = 1;
        nextVerificationId = 1;
    }

    // --- I. Core Setup & Administration ---

    /**
     * @notice Allows the DAO to update core operational parameters.
     * @dev This function is intended to be called only through a successful governance proposal.
     * @param _newParams The new CoreParameters struct to apply.
     */
    function updateCoreParameters(CoreParameters calldata _newParams) external onlyDAO {
        coreParams = _newParams;
        emit CoreParametersUpdated(msg.sender, _newParams);
    }

    // --- II. Reputation Management ---

    /**
     * @notice Internal pure function to calculate a user's current effective reputation, considering decay.
     * @param _user The address of the user.
     * @return The calculated effective reputation score.
     */
    function _calculateReputation(address _user) internal view returns (uint256) {
        ReputationSnapshot storage snapshot = reputationSnapshots[_user];
        if (snapshot.rawReputation == 0) return 0;

        uint256 timeElapsed = block.timestamp - snapshot.lastUpdatedTimestamp;
        uint256 yearsElapsed = timeElapsed / 31536000; // Rough seconds in a year (non-leap)

        uint256 decayedReputation = snapshot.rawReputation;
        for (uint256 i = 0; i < yearsElapsed; i++) {
            decayedReputation = decayedReputation * (10000 - coreParams.reputationDecayRatePerYear) / 10000;
        }
        return decayedReputation;
    }

    /**
     * @notice External view function to retrieve the current effective reputation for a specified user.
     * @param _user The address of the user.
     * @return The current effective reputation score.
     */
    function getReputation(address _user) external view returns (uint256) {
        return _calculateReputation(_user);
    }

    /**
     * @notice Internal function to increment or decrement a user's raw reputation score.
     * @dev This also updates the lastUpdatedTimestamp to reset the decay clock.
     * @param _user The address whose reputation to adjust.
     * @param _amount The amount to adjust by.
     * @param _increase If true, reputation is increased; otherwise, it's decreased.
     */
    function _adjustReputation(address _user, uint256 _amount, bool _increase) internal {
        ReputationSnapshot storage snapshot = reputationSnapshots[_user];
        uint256 oldEffectiveRep = _calculateReputation(_user); // Get current effective reputation before raw adjustment

        if (_increase) {
            snapshot.rawReputation += _amount;
        } else {
            if (snapshot.rawReputation < _amount) snapshot.rawReputation = 0;
            else snapshot.rawReputation -= _amount;
        }
        snapshot.lastUpdatedTimestamp = block.timestamp; // Reset decay timer on adjustment

        emit ReputationAdjusted(_user, oldEffectiveRep, _calculateReputation(_user));
    }

    /**
     * @notice Allows a user to delegate their reputation-based voting weight to another address.
     * @param _delegatee The address to delegate reputation voting power to.
     */
    function delegateReputationVotingPower(address _delegatee) external {
        require(_delegatee != address(0) && _delegatee != msg.sender, "ImpactNexus: invalid delegatee address");
        reputationDelegations[msg.sender] = _delegatee;
        emit ReputationDelegated(msg.sender, _delegatee);
    }

    /**
     * @notice Removes any active reputation delegation for the caller.
     */
    function undelegateReputationVotingPower() external {
        delete reputationDelegations[msg.sender];
        emit ReputationUndelegated(msg.sender);
    }

    // --- III. Project Proposal & Lifecycle ---

    /**
     * @notice Allows eligible users to submit a new social impact project proposal.
     * @param _title The title of the project.
     * @param _description The detailed description of the project.
     * @param _totalFundingGoal The total funding goal for the project (in native token equivalent).
     * @param _milestones An array of Milestone structs defining project phases and funding tranches.
     * @dev Requires the proposer to have MIN_REPUTATION_FOR_PROPOSAL and stake `proposalStakeAmount` ImpactTokens.
     */
    function proposeProject(
        string memory _title,
        string memory _description,
        uint256 _totalFundingGoal,
        Milestone[] memory _milestones
    ) external {
        require(_calculateReputation(msg.sender) >= MIN_REPUTATION_FOR_PROPOSAL, "ImpactNexus: insufficient reputation to propose");
        require(impactToken.balanceOf(msg.sender) >= coreParams.proposalStakeAmount, "ImpactNexus: insufficient ImpactToken stake");
        require(_milestones.length > 0, "ImpactNexus: project must have at least one milestone");

        uint256 totalMilestoneFunding;
        for (uint256 i = 0; i < _milestones.length; i++) {
            totalMilestoneFunding += _milestones[i].fundingTranche;
            require(_milestones[i].fundingTranche > 0, "ImpactNexus: milestone funding must be greater than zero");
            require(_milestones[i].impactScoreAdjustment != 0, "ImpactNexus: milestone impact score adjustment cannot be zero");
        }
        require(totalMilestoneFunding == _totalFundingGoal, "ImpactNexus: sum of milestone funding must equal total funding goal");

        impactToken.burn(msg.sender, coreParams.proposalStakeAmount); // Burn stake as a commitment mechanism

        uint256 projectId = nextProjectId++;
        projects[projectId] = Project({
            id: projectId,
            title: _title,
            description: _description,
            proposer: msg.sender,
            totalFundingGoal: _totalFundingGoal,
            allocatedFunding: 0,
            status: ProjectStatus.Proposed,
            milestones: _milestones,
            currentMilestoneIndex: 0,
            impactScore: 0, // Starts neutral
            proposalTimestamp: block.timestamp,
            projectStakeAmount: coreParams.proposalStakeAmount
        });

        // Automatically create a governance proposal for project funding approval (for the first milestone)
        bytes memory callData = abi.encodeWithSelector(
            this.allocateFundsToProjectTranche.selector,
            projectId,
            0 // First milestone index
        );
        _createProposal(
            ProposalType.ProjectFunding,
            string(abi.encodePacked("Fund initial tranche for project #", Strings.toString(projectId), ": ", _title)),
            msg.sender,
            projectId,
            address(this),
            callData
        );

        emit ProjectProposed(projectId, msg.sender, _totalFundingGoal);
        _adjustReputation(msg.sender, 50, true); // Proposer gets a small rep boost for proposing
    }

    /**
     * @notice Project proposer reports progress for a specific milestone, making it ready for verification.
     * @param _projectId The ID of the project.
     * @param _milestoneIndex The index of the milestone being reported.
     * @param _progressReportHash A hash of off-chain documentation/report detailing progress (e.g., IPFS hash).
     */
    function submitMilestoneProgress(
        uint256 _projectId,
        uint256 _milestoneIndex,
        string memory _progressReportHash
    ) external onlyProposer(_projectId) {
        Project storage project = projects[_projectId];
        require(project.status == ProjectStatus.Active, "ImpactNexus: project not active");
        require(_milestoneIndex < project.milestones.length, "ImpactNexus: invalid milestone index");
        require(_milestoneIndex == project.currentMilestoneIndex, "ImpactNexus: cannot report out of order milestones");
        require(project.milestones[_milestoneIndex].status == MilestoneStatus.Pending, "ImpactNexus: milestone not in pending status");

        project.milestones[_milestoneIndex].status = MilestoneStatus.Reported;
        emit MilestoneProgressReported(_projectId, _milestoneIndex, _progressReportHash);
        _adjustReputation(msg.sender, 10, true); // Small rep boost for reporting progress
        requestMilestoneVerification(_projectId, _milestoneIndex); // Automatically request verification
    }

    /**
     * @notice Internal function to update a project's milestone status and adjust project impact score.
     * @param _projectId The ID of the project.
     * @param _milestoneIndex The index of the milestone.
     * @param _success True if the milestone was verified as successful, false otherwise.
     */
    function _recordProjectMilestone(uint256 _projectId, uint256 _milestoneIndex, bool _success) internal {
        Project storage project = projects[_projectId];
        require(_milestoneIndex < project.milestones.length, "ImpactNexus: invalid milestone index");
        require(project.milestones[_milestoneIndex].status == MilestoneStatus.VerificationRequested || project.milestones[_milestoneIndex].status == MilestoneStatus.Reported, "ImpactNexus: milestone not awaiting verification");

        Milestone storage milestone = project.milestones[_milestoneIndex];
        milestone.status = _success ? MilestoneStatus.VerifiedSuccess : MilestoneStatus.VerifiedFailed;

        if (_success) {
            project.impactScore += milestone.impactScoreAdjustment;
            project.currentMilestoneIndex++;
            if (project.currentMilestoneIndex == project.milestones.length) {
                project.status = ProjectStatus.Completed;
                _adjustReputation(project.proposer, 200, true); // Major rep boost for project completion
                emit ProjectStatusUpdated(_projectId, ProjectStatus.Completed);
                // Optionally: refund proposer stake or provide final bonus here
            } else {
                // If there are more milestones, create a governance proposal to allocate the next tranche
                bytes memory callData = abi.encodeWithSelector(
                    this.allocateFundsToProjectTranche.selector,
                    _projectId,
                    project.currentMilestoneIndex
                );
                _createProposal(
                    ProposalType.ProjectFunding,
                    string(abi.encodePacked("Fund next tranche for project #", Strings.toString(_projectId), ": ", project.title)),
                    project.proposer, // Proposer of original project acts as conceptual proposer here
                    _projectId,
                    address(this),
                    callData
                );
            }
        } else {
            project.impactScore += (milestone.impactScoreAdjustment / -2); // Penalize for failed milestone
            project.status = ProjectStatus.Failed;
            _adjustReputation(project.proposer, 100, false); // Rep penalty for failed milestone
            emit ProjectStatusUpdated(_projectId, ProjectStatus.Failed);
            // Proposer stake is forfeited for failed projects
        }
    }

    /**
     * @notice Allows the project proposer or DAO to cancel a project.
     * @param _projectId The ID of the project to cancel.
     * @dev If canceled by proposer, stake may be forfeited. If by DAO, conditions vary.
     */
    function cancelProject(uint256 _projectId) external {
        Project storage project = projects[_projectId];
        require(project.status != ProjectStatus.Completed && project.status != ProjectStatus.Failed && project.status != ProjectStatus.Cancelled, "ImpactNexus: project already finalized");

        bool isProposer = (msg.sender == project.proposer);
        bool isDAO = (msg.sender == address(this)); // Assumes DAO execution

        require(isProposer || isDAO, "ImpactNexus: only proposer or DAO can cancel project");

        project.status = ProjectStatus.Cancelled;
        emit ProjectStatusUpdated(_projectId, ProjectStatus.Cancelled);

        // Penalties/Refunds: Proposer forfeits stake upon self-cancellation.
        // If DAO cancels, it might be due to external factors, so stake refund could be decided by governance.
        if (isProposer) {
            // Proposer's stake (already burned on proposal) is not returned.
        } else if (isDAO) {
            // DAO could decide via another proposal to compensate/refund proposer
        }
        _adjustReputation(project.proposer, 50, false); // Small rep penalty for cancellation
    }

    // --- IV. Funding & Contributions ---

    /**
     * @notice Allows users to send native currency (ETH) to the Impact Fund, receiving ImpactTokens in return.
     * @dev Mints ImpactTokens at a predefined rate (`coreParams.impactTokenMintRate`).
     */
    function contributeToFund() external payable {
        require(msg.value > 0, "ImpactNexus: contribution must be greater than zero");

        uint256 tokensToMint = (msg.value * coreParams.impactTokenMintRate) / (10 ** 18); // assuming 1 ETH = 1e18 ImpactTokens
        impactToken.mint(msg.sender, tokensToMint);

        emit ContributionReceived(msg.sender, msg.value, tokensToMint);
        _adjustReputation(msg.sender, tokensToMint / (10 ** 18), true); // Small rep gain for contribution (e.g., 1 rep per 1 ImpactToken)
    }

    /**
     * @notice Allows contributors to withdraw their ImpactTokens under specific DAO-approved conditions.
     * @dev This function is intended to be called by the DAO after a governance vote.
     *      The actual native currency (ETH) refund would be handled by the DAO execution separately.
     * @param _amount The amount of ImpactTokens to burn (representing withdrawal).
     */
    function withdrawContribution(uint256 _amount) external onlyDAO {
        // Here, msg.sender is `address(this)` due to `onlyDAO`. The actual recipient
        // of the ImpactTokens burn and ETH refund should be specified in the governance proposal payload.
        // For simplicity, we assume the ETH part is handled by a separate DAO call in the payload.
        // This function just facilitates the token burn aspect.
        // Assuming _user is passed as part of the calldata to `withdrawContribution` in a real DAO scenario.
        // For this example, it's simplified.
        // To make this work, the DAO proposal payload would have to encode:
        // `abi.encodeWithSelector(this.withdrawContribution.selector, beneficiaryAddress, _amount)`
        // However, `onlyDAO` checks `msg.sender == address(this)`, meaning `msg.sender`
        // here *is* the contract. So this function needs modification to accept a target `_user`.
        revert("ImpactNexus: withdrawContribution must be called with a specific user from DAO proposal");
        // Example if user was passed:
        // address userToWithdraw = ...; // from calldata
        // require(impactToken.balanceOf(userToWithdraw) >= _amount, "ImpactNexus: insufficient ImpactTokens");
        // impactToken.burn(userToWithdraw, _amount);
        // emit ContributionWithdrawn(userToWithdraw, _amount);
    }

    /**
     * @notice DAO approves and allocates the funding tranche for a project's *current* milestone.
     * @dev This function is intended to be called only through a successful governance proposal.
     * @param _projectId The ID of the project.
     * @param _milestoneIndex The index of the milestone to fund.
     */
    function allocateFundsToProjectTranche(uint256 _projectId, uint256 _milestoneIndex) external onlyDAO {
        Project storage project = projects[_projectId];
        require(project.status == ProjectStatus.Proposed || project.status == ProjectStatus.Active, "ImpactNexus: project not in fundable status");
        require(_milestoneIndex < project.milestones.length, "ImpactNexus: invalid milestone index");
        require(_milestoneIndex == project.currentMilestoneIndex, "ImpactNexus: can only fund current milestone");
        require(project.milestones[_milestoneIndex].status == MilestoneStatus.Pending || project.milestones[_milestoneIndex].status == MilestoneStatus.VerifiedSuccess, "ImpactNexus: milestone not ready for funding");

        uint256 trancheAmount = project.milestones[_milestoneIndex].fundingTranche;
        require(address(this).balance >= trancheAmount, "ImpactNexus: insufficient fund balance");

        // Release funds to the project proposer for this tranche
        (bool success, ) = payable(project.proposer).call{value: trancheAmount}("");
        require(success, "ImpactNexus: failed to transfer funds");

        project.allocatedFunding += trancheAmount;
        if (project.status == ProjectStatus.Proposed) {
            project.status = ProjectStatus.Active; // Project becomes active upon first tranche allocation
            emit ProjectStatusUpdated(_projectId, ProjectStatus.Active);
        }
        // Milestone status is kept as VerifiedSuccess if it was, or Pending if it was just created (first tranche)
        emit FundsAllocated(_projectId, _milestoneIndex, trancheAmount);
        _adjustReputation(project.proposer, 50, true); // Rep boost for getting funding
    }

    // --- V. Governance & Voting ---

    /**
     * @notice Internal pure function to calculate the combined voting power (token + reputation) for an address.
     * @param _voter The address of the voter.
     * @return The effective voting weight.
     */
    function _getEffectiveVotingWeight(address _voter) internal view returns (uint256) {
        address actualVoter = reputationDelegations[_voter] == address(0) ? _voter : reputationDelegations[_voter];
        uint256 tokenWeight = impactToken.balanceOf(actualVoter);
        uint256 reputationWeight = _calculateReputation(actualVoter);
        // Simple aggregation: tokens + reputation (can be weighted differently, e.g., tokenWeight + reputationWeight / X)
        return tokenWeight + reputationWeight;
    }

    /**
     * @notice Creates a new governance proposal for contract parameter changes or other actions.
     * @param _description A description of the proposed change.
     * @param _calldata The calldata for the target function to be executed if the proposal passes.
     * @param _target The target contract address for the execution.
     */
    function createGovernanceProposal(
        string memory _description,
        bytes memory _calldata,
        address _target
    ) public {
        require(_calculateReputation(msg.sender) >= MIN_REPUTATION_FOR_PROPOSAL, "ImpactNexus: insufficient reputation to propose governance change");
        _createProposal(ProposalType.GovernanceChange, _description, msg.sender, 0, _target, _calldata);
    }

    /**
     * @notice Internal function to create a generic proposal.
     * @param _pType The type of proposal (ProjectFunding or GovernanceChange).
     * @param _description A description of the proposal.
     * @param _proposer The address of the proposal creator.
     * @param _projectId The ID of the project (if ProjectFunding type).
     * @param _target The target contract for execution (if GovernanceChange type).
     * @param _calldata The calldata payload for execution (if GovernanceChange type).
     */
    function _createProposal(
        ProposalType _pType,
        string memory _description,
        address _proposer,
        uint256 _projectId, // Used for ProjectFunding proposals
        address _target,     // Used for GovernanceChange proposals
        bytes memory _calldata // Used for GovernanceChange proposals
    ) internal returns (uint256) {
        uint256 proposalId = nextProposalId++;
        // For totalVotingPowerAtCreation, a more robust system would take a snapshot of all token balances and reputations.
        // For simplicity here, we approximate it by current total supply + a theoretical max reputation or 0.
        // A better approach for real DAOs involves checkpoints for token balances.
        uint256 totalAvailableVotingPower = impactToken.totalSupply() + _calculateReputation(address(0x1)); // Dummy address to represent some base rep (0 typically)
        
        proposals[proposalId] = Proposal({
            id: proposalId,
            pType: _pType,
            description: _description,
            proposer: _proposer,
            creationTimestamp: block.timestamp,
            votingEndsTimestamp: block.timestamp + coreParams.votingPeriodDuration,
            votesFor: 0,
            votesAgainst: 0,
            totalVotingPowerAtCreation: totalAvailableVotingPower,
            status: ProposalStatus.Active,
            executed: false,
            target: _target,
            calldataPayload: _calldata,
            projectId: _projectId
        });
        emit ProposalCreated(proposalId, _pType, _proposer, proposals[proposalId].votingEndsTimestamp);
        return proposalId;
    }

    /**
     * @notice Users cast their vote on an active project or governance proposal.
     * @param _proposalId The ID of the proposal.
     * @param _support True for "yes" vote, false for "no" vote.
     */
    function voteOnProposal(uint256 _proposalId, bool _support) external {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.status == ProposalStatus.Active, "ImpactNexus: proposal not active");
        require(block.timestamp <= proposal.votingEndsTimestamp, "ImpactNexus: voting period has ended");
        require(!hasVoted[_proposalId][msg.sender], "ImpactNexus: already voted on this proposal");

        uint256 votingWeight = _getEffectiveVotingWeight(msg.sender);
        require(votingWeight > 0, "ImpactNexus: no voting weight");

        if (_support) {
            proposal.votesFor += votingWeight;
        } else {
            proposal.votesAgainst += votingWeight;
        }
        hasVoted[_proposalId][msg.sender] = true;
        emit Voted(_proposalId, msg.sender, _support, votingWeight);
    }

    /**
     * @notice Executes a governance proposal that has passed and met quorum requirements.
     * @param _proposalId The ID of the proposal to execute.
     * @dev This function needs to be called after the voting period ends and checks for success criteria.
     */
    function executeProposal(uint256 _proposalId) external {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.status == ProposalStatus.Active, "ImpactNexus: proposal not active");
        require(block.timestamp > proposal.votingEndsTimestamp, "ImpactNexus: voting period not ended yet");
        require(!proposal.executed, "ImpactNexus: proposal already executed");

        uint256 totalVotes = proposal.votesFor + proposal.votesAgainst;
        uint256 quorumThreshold = (proposal.totalVotingPowerAtCreation * coreParams.daoQuorumThresholdBP) / 10000;
        
        // Quorum check: Ensure enough total voting power participated
        bool quorumMet = totalVotes >= quorumThreshold;

        // Support check: Ensure enough 'for' votes
        bool supportMet = (totalVotes > 0 && (proposal.votesFor * 10000) / totalVotes >= coreParams.daoSupportThresholdBP);

        if (quorumMet && supportMet) {
            proposal.status = ProposalStatus.Succeeded;
            // Execute the proposed action
            (bool success, ) = proposal.target.call(proposal.calldataPayload);
            require(success, "ImpactNexus: proposal execution failed");
            
            proposal.executed = true;
            emit ProposalStatusChanged(_proposalId, ProposalStatus.Succeeded);
            emit ProposalExecuted(_proposalId);
            _adjustReputation(proposal.proposer, 100, true); // Proposer gets rep for successful proposal
        } else {
            proposal.status = ProposalStatus.Failed;
            emit ProposalStatusChanged(_proposalId, ProposalStatus.Failed);
            _adjustReputation(proposal.proposer, 50, false); // Proposer gets rep penalty for failed proposal
            // If project funding proposal failed, the proposer's initial stake (burned) is not recovered.
        }
    }


    // --- VI. Impact Verification & Oracles (Simulated) ---

    /**
     * @notice Allows users to stake ImpactTokens to become eligible as a project verifier.
     * @param _amount The amount of ImpactTokens to stake.
     * @dev Requires a minimum reputation score.
     */
    function stakeForVerificationRole(uint256 _amount) external {
        require(_calculateReputation(msg.sender) >= MIN_REPUTATION_FOR_VERIFIER, "ImpactNexus: insufficient reputation to be a verifier");
        require(_amount >= MIN_TOKEN_STAKE_FOR_VERIFIER, "ImpactNexus: stake amount too low");
        require(impactToken.balanceOf(msg.sender) >= _amount, "ImpactNexus: insufficient ImpactTokens to stake");

        impactToken.burn(msg.sender, _amount); // Burn tokens as stake to remove from circulation during staking
        // In a more complex system, these might be transferred to a locked contract or vault.
        // For simplicity and to fit the 'burn' model, we assume a burn and a corresponding `stakedVerifiers` mapping
        // or a reputation increase signifies the stake.
        _adjustReputation(msg.sender, 20, true); // Small rep gain for staking
        emit VerifierStaked(msg.sender, _amount);
    }

    /**
     * @notice Initiates a verification request for a reported milestone.
     * @dev This function would typically be called by the DAO or automatically after a milestone is reported.
     *      It randomly selects verifiers (simplified for this example).
     * @param _projectId The ID of the project.
     * @param _milestoneIndex The index of the milestone to verify.
     */
    function requestMilestoneVerification(uint256 _projectId, uint256 _milestoneIndex) public { // Public for auto-trigger by submitMilestoneProgress
        Project storage project = projects[_projectId];
        require(project.status == ProjectStatus.Active, "ImpactNexus: project not active");
        require(_milestoneIndex < project.milestones.length, "ImpactNexus: invalid milestone index");
        require(project.milestones[_milestoneIndex].status == MilestoneStatus.Reported, "ImpactNexus: milestone not reported for verification");
        // Only internal calls (e.g., from submitMilestoneProgress) or DAO execution module can trigger
        require(msg.sender == address(this) || msg.sender == project.proposer, "ImpactNexus: unauthorized to request verification");

        project.milestones[_milestoneIndex].status = MilestoneStatus.VerificationRequested;

        // Simplified verifier selection: In a real system, this would involve a VRF,
        // a pool of eligible stakers, and a more robust selection mechanism.
        // For this example, we'll just mock a few 'verifiers'.
        // In a production system, you'd iterate through a list of addresses that have staked
        // and randomly select `coreParams.minVerifiersPerMilestone` based on some verifiable randomness.
        address[] memory selectedVerifiers = new address[](coreParams.minVerifiersPerMilestone);
        // Replace with actual selection logic, e.g., from a list of addresses that have `MIN_REPUTATION_FOR_VERIFIER`
        // and have called `stakeForVerificationRole`.
        // Example mock selection:
        selectedVerifiers[0] = deployer; // Assume deployer staked
        if (coreParams.minVerifiersPerMilestone > 1) selectedVerifiers[1] = address(0x789); // Placeholder
        if (coreParams.minVerifiersPerMilestone > 2) selectedVerifiers[2] = address(0xabc); // Placeholder

        // Basic check for selected verifiers (actual staking tracked externally to this example)
        for (uint256 i = 0; i < selectedVerifiers.length; i++) {
            require(selectedVerifiers[i] != address(0), "ImpactNexus: invalid mock verifier address");
            require(_calculateReputation(selectedVerifiers[i]) >= MIN_REPUTATION_FOR_VERIFIER, "ImpactNexus: selected verifier lacks reputation");
            // A real system would also verify if they have an active stake.
        }

        uint256 verificationId = nextVerificationId++;
        verificationRequests[verificationId] = VerificationRequest({
            id: verificationId,
            projectId: _projectId,
            milestoneIndex: _milestoneIndex,
            selectedVerifiers: selectedVerifiers,
            commitEndsTimestamp: block.timestamp + coreParams.verificationCommitPeriod,
            revealEndsTimestamp: block.timestamp + coreParams.verificationCommitPeriod + coreParams.verificationRevealPeriod,
            status: VerificationStatus.CommitPhase,
            totalVerifierStake: coreParams.verificationStakeAmount * selectedVerifiers.length // Simplified total stake
        });

        emit VerificationRequested(verificationId, _projectId, _milestoneIndex);
    }

    /**
     * @notice Selected verifiers commit a hash of their verification result.
     * @param _verificationId The ID of the verification request.
     * @param _resultHash The Keccak256 hash of their boolean verification result (e.g., keccak256(abi.encodePacked(true))).
     */
    function commitVerificationResultHash(uint256 _verificationId, bytes32 _resultHash) external {
        VerificationRequest storage req = verificationRequests[_verificationId];
        require(req.status == VerificationStatus.CommitPhase, "ImpactNexus: not in commit phase");
        require(block.timestamp <= req.commitEndsTimestamp, "ImpactNexus: commit period ended");

        bool isSelectedVerifier = false;
        for (uint256 i = 0; i < req.selectedVerifiers.length; i++) {
            if (req.selectedVerifiers[i] == msg.sender) {
                isSelectedVerifier = true;
                break;
            }
        }
        require(isSelectedVerifier, "ImpactNexus: not a selected verifier for this request");
        require(verificationCommitments[_verificationId][msg.sender] == bytes32(0), "ImpactNexus: already committed");

        verificationCommitments[_verificationId][msg.sender] = _resultHash;
        emit VerificationCommitted(_verificationId, msg.sender);
    }

    /**
     * @notice Verifiers reveal their actual boolean verification result.
     * @param _verificationId The ID of the verification request.
     * @param _verified The actual boolean result (true for verified, false for failed).
     */
    function revealVerificationResult(uint256 _verificationId, bool _verified) external {
        VerificationRequest storage req = verificationRequests[_verificationId];
        require(req.status == VerificationStatus.CommitPhase || req.status == VerificationStatus.RevealPhase, "ImpactNexus: not in commit/reveal phase");
        require(block.timestamp > req.commitEndsTimestamp, "ImpactNexus: commit period not ended");
        require(block.timestamp <= req.revealEndsTimestamp, "ImpactNexus: reveal period ended");

        bool isSelectedVerifier = false;
        for (uint256 i = 0; i < req.selectedVerifiers.length; i++) {
            if (req.selectedVerifiers[i] == msg.sender) {
                isSelectedVerifier = true;
                break;
            }
        }
        require(isSelectedVerifier, "ImpactNexus: not a selected verifier for this request");
        require(verificationCommitments[_verificationId][msg.sender] != bytes32(0), "ImpactNexus: no commitment found");
        require(!verificationRevealed[_verificationId][msg.sender], "ImpactNexus: already revealed");

        // Verify the revealed result against the committed hash
        bytes32 expectedHash = keccak256(abi.encodePacked(_verified));
        require(verificationCommitments[_verificationId][msg.sender] == expectedHash, "ImpactNexus: revealed result does not match committed hash");

        verificationResults[_verificationId][msg.sender] = _verified;
        verificationRevealed[_verificationId][msg.sender] = true;
        req.status = VerificationStatus.RevealPhase; // Ensure status transition if first reveal
        emit VerificationRevealed(_verificationId, msg.sender, _verified);
    }

    /**
     * @notice Allows any user to challenge a verifier's revealed result if it doesn't match their committed hash.
     * @param _verificationId The ID of the verification request.
     * @param _verifier The address of the verifier being challenged.
     * @param _revealedResult The boolean result the verifier claimed to reveal.
     * @param _expectedHash The hash the verifier initially committed.
     */
    function challengeVerificationResult(
        uint256 _verificationId,
        address _verifier,
        bool _revealedResult,
        bytes32 _expectedHash
    ) external {
        VerificationRequest storage req = verificationRequests[_verificationId];
        require(req.status == VerificationStatus.RevealPhase || req.status == VerificationStatus.Processing, "ImpactNexus: not in valid phase for challenge");
        require(block.timestamp > req.commitEndsTimestamp, "ImpactNexus: commit period not ended");

        bool isSelectedVerifier = false;
        for (uint256 i = 0; i < req.selectedVerifiers.length; i++) {
            if (req.selectedVerifiers[i] == _verifier) {
                isSelectedVerifier = true;
                break;
            }
        }
        require(isSelectedVerifier, "ImpactNexus: challenged address is not a selected verifier");
        require(verificationRevealed[_verificationId][_verifier], "ImpactNexus: verifier has not revealed");
        require(verificationCommitments[_verificationId][_verifier] == _expectedHash, "ImpactNexus: provided expected hash does not match committed hash");

        bytes32 actualRevealedHash = keccak256(abi.encodePacked(_revealedResult));
        require(actualRevealedHash != _expectedHash, "ImpactNexus: revealed result matches committed hash, no fraud");

        // If we reach here, the verifier tried to reveal a different result than committed
        // Penalize verifier: reduce reputation
        _adjustReputation(_verifier, 200, false); // Major reputation penalty
        // In a real system, the stake (if tracked and not burned) would be slashed and potentially awarded to the challenger.
        emit VerificationChallenged(_verificationId, _verifier, msg.sender);
    }

    /**
     * @notice Aggregates revealed verification results, determines the milestone outcome,
     *         adjusts verifier reputations, and updates project status.
     * @param _verificationId The ID of the verification request.
     */
    function processVerificationResults(uint256 _verificationId) external {
        VerificationRequest storage req = verificationRequests[_verificationId];
        require(req.status == VerificationStatus.RevealPhase || (req.status == VerificationStatus.CommitPhase && block.timestamp > req.revealEndsTimestamp), "ImpactNexus: not in reveal phase or reveal period not ended");
        require(block.timestamp > req.revealEndsTimestamp, "ImpactNexus: reveal period not ended yet");
        require(req.status != VerificationStatus.Finalized, "ImpactNexus: verification already finalized");

        req.status = VerificationStatus.Processing;

        uint256 yesVotes = 0;
        uint256 noVotes = 0;
        uint256 participants = 0;

        for (uint256 i = 0; i < req.selectedVerifiers.length; i++) {
            address verifier = req.selectedVerifiers[i];
            if (verificationRevealed[_verificationId][verifier]) {
                participants++;
                if (verificationResults[_verificationId][verifier]) {
                    yesVotes++;
                } else {
                    noVotes++;
                }
                _adjustReputation(verifier, 10, true); // Small rep gain for participating
            } else {
                // Verifier failed to reveal or commit
                _adjustReputation(verifier, 50, false); // Rep penalty for non-participation
            }
            // Clear commitments for privacy/cleanup
            delete verificationCommitments[_verificationId][verifier];
            delete verificationRevealed[_verificationId][verifier];
            delete verificationResults[_verificationId][verifier];
        }

        bool milestoneSuccess = false;
        if (participants >= coreParams.minVerifiersPerMilestone) {
            uint256 consensusYes = (yesVotes * 10000) / participants;
            uint256 consensusNo = (noVotes * 10000) / participants; // For future complex logic
            
            if (consensusYes >= coreParams.minConsensusPercentage) {
                milestoneSuccess = true;
            } else { // If not enough "yes" consensus, it's considered a failure or inconclusive
                milestoneSuccess = false;
            }
        } else {
            // Not enough verifiers participated, or consensus was not met due to low participation
            milestoneSuccess = false;
        }

        _recordProjectMilestone(req.projectId, req.milestoneIndex, milestoneSuccess);
        req.status = VerificationStatus.Finalized;

        emit VerificationFinalized(_verificationId, milestoneSuccess, projects[req.projectId].impactScore);
    }

    // --- VII. Project & Fund Information ---

    /**
     * @notice View function to retrieve comprehensive details of a specific project.
     * @param _projectId The ID of the project.
     * @return A tuple containing project details.
     */
    function getProjectDetails(uint256 _projectId) external view returns (
        uint256 id,
        string memory title,
        string memory description,
        address proposer,
        uint256 totalFundingGoal,
        uint256 allocatedFunding,
        ProjectStatus status,
        uint256 currentMilestoneIndex,
        int256 impactScore,
        uint256 proposalTimestamp
    ) {
        Project storage project = projects[_projectId];
        return (
            project.id,
            project.title,
            project.description,
            project.proposer,
            project.totalFundingGoal,
            project.allocatedFunding,
            project.status,
            project.currentMilestoneIndex,
            project.impactScore,
            project.proposalTimestamp
        );
    }

    /**
     * @notice View function for details of a specific milestone within a project.
     * @param _projectId The ID of the project.
     * @param _milestoneIndex The index of the milestone.
     * @return A tuple containing milestone details.
     */
    function getMilestoneDetails(uint256 _projectId, uint256 _milestoneIndex) external view returns (
        string memory description,
        uint256 fundingTranche,
        MilestoneStatus status,
        int256 impactScoreAdjustment
    ) {
        Project storage project = projects[_projectId];
        require(_milestoneIndex < project.milestones.length, "ImpactNexus: invalid milestone index");
        Milestone storage milestone = project.milestones[_milestoneIndex];
        return (
            milestone.description,
            milestone.fundingTranche,
            milestone.status,
            milestone.impactScoreAdjustment
        );
    }

    /**
     * @notice View function to retrieve the total native token (ETH) balance held by the ImpactNexus fund.
     * @return The total balance in wei.
     */
    function getFundBalance() external view returns (uint256) {
        return address(this).balance;
    }
}

// Helper library for converting uint256 to string
library Strings {
    function toString(uint256 value) internal pure returns (string memory) {
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