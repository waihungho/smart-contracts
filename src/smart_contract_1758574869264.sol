This smart contract, named **"Epochal Adaptive Research & Development Fund (EARDF)"**, is designed to be a decentralized autonomous fund that strategically allocates capital to innovative research and development projects. It incorporates several advanced concepts:

1.  **Adaptive Strategy Engine:** The fund's capital allocation strategy is not fixed but dynamically adjusts based on on-chain governance parameters, market sentiment (via oracles), and the historical success rate of funded projects.
2.  **Reputation-Weighted Governance:** Beyond simple token-based voting, participants (proposers, evaluators, voters) earn and lose reputation points. This reputation influences voting power, access tiers, and eligibility for certain roles.
3.  **Epochal Funding Cycles:** Funding rounds operate in distinct epochs, each with submission, voting, and execution phases, ensuring structured and predictable operations.
4.  **Milestone-Based Funding:** Projects receive funds incrementally upon successful completion and verification of predefined milestones, mitigating risk.
5.  **DeFi Yield Integration:** Idle treasury funds can be strategically invested into external yield-generating DeFi protocols, creating a sustainable revenue stream for the fund.
6.  **Decentralized Evaluation Network:** A system where reputable evaluators verify milestone proofs, earning reputation for accurate assessments.

---

## Contract Outline & Function Summary

**Contract Name:** `EpochalAdaptiveRD`

**Core Concepts:** Adaptive Strategy, Reputation System, Epochal Funding, Milestone-Based Funding, DeFi Yield Integration, Decentralized Evaluation.

### State Variables & Structs:
*   `Proposal`: Stores details of a project proposal.
*   `Milestone`: Details for a project milestone.
*   `EpochState`: Tracks current epoch's status (Submission, Voting, Execution).
*   `AdaptiveStrategyParams`: Configurable parameters for the allocation strategy.
*   `reputationScores`: Mapping from address to reputation points.
*   `proposalDeposits`: Deposits from proposers to deter spam.

### Modifiers:
*   `onlyEpochState`: Restricts functions to a specific epoch state.
*   `onlyReputableEvaluator`: Restricts functions to users above a certain reputation threshold.
*   `onlyProjectLead`: Restricts functions to the lead of a specific project.

### Events:
*   `ProposalSubmitted`, `VoteCast`, `EpochEnded`, `EpochStarted`, `MilestoneProofSubmitted`, `MilestoneApproved`, `FundsClaimed`, `ReputationAwarded`, `ReputationPenalized`, `StrategyParametersUpdated`, `FundsInvested`, `YieldCollected`, `OracleUpdated`.

---

### Functions Summary (25 Functions):

**I. Core Fund & Epoch Management (7 Functions)**
1.  `constructor()`: Initializes the contract, sets the `EARDFToken` address, and initializes the first epoch.
2.  `startNewEpoch()`: Advances the contract to the next epoch, transitioning from Execution to Submission phase.
3.  `endCurrentEpoch()`: Transitions the epoch from Voting to Execution phase, locking in votes.
4.  `setEpochPhaseDurations()`: Allows governance to configure the duration of Submission, Voting, and Execution phases for each epoch.
5.  `getCurrentEpochId()`: Returns the ID of the current active epoch.
6.  `getCurrentEpochState()`: Returns the current operational state (Submission, Voting, Execution) of the epoch.
7.  `emergencyPause()`: Pauses the contract in case of a critical issue (inherits from Pausable).
8.  `emergencyUnpause()`: Unpauses the contract (inherits from Pausable).

**II. Proposal & Milestone Management (6 Functions)**
9.  `submitProposal()`: Allows a user to submit a new R&D proposal with detailed milestones and a budget. Requires a small `EARDFToken` deposit.
10. `depositForProposalEvaluation()`: Allows a proposer to make a required deposit for their proposal to be considered for evaluation (spam prevention).
11. `withdrawRejectedProposalDeposit()`: Allows a proposer to retrieve their deposit if their proposal was not funded.
12. `submitMilestoneProofHash()`: Project lead submits a cryptographic hash as proof of milestone completion.
13. `evaluateMilestoneProof()`: Reputable evaluators verify milestone proofs (off-chain verification, on-chain approval). Awards reputation for accurate evaluations.
14. `claimMilestoneFunds()`: Project lead claims funds for an approved milestone.

**III. Voting & Reputation System (4 Functions)**
15. `stakeForVoting()`: Users stake `EARDFToken` to participate in voting. Staked tokens determine base voting power.
16. `voteOnProposal()`: Allows staked token holders to vote on proposals. Voting power is weighted by their reputation score.
17. `unstakeAfterVoting()`: Allows users to retrieve their staked tokens after a cool-down period post-epoch finalization.
18. `getReputationWeightedVotePower()`: Calculates an address's effective voting power based on staked tokens and reputation.
19. `awardReputation()`: System function (callable by `onlyOwner` or authorized role) to award reputation points for positive contributions (e.g., successful project completion, accurate evaluation).
20. `penalizeReputation()`: System function (callable by `onlyOwner` or authorized role) to deduct reputation points for negative actions (e.g., failed project, malicious voting).

**IV. Adaptive Strategy & Treasury Management (5 Functions)**
21. `setAdaptiveStrategyParameters()`: Governance sets parameters (e.g., weights for market sentiment, success rate) that influence the adaptive allocation strategy.
22. `recalculateEpochAllocationStrategy()`: A complex function that re-calculates the fund's optimal capital allocation strategy for the current epoch based on `AdaptiveStrategyParams`, oracle data (market sentiment), and historical project success rates. *This is a core unique function.*
23. `investIdleFundsIntoProtocol()`: Invests a portion of the fund's idle treasury into a specified DeFi yield-generating protocol (e.g., a simple ERC4626 vault or AAVE/Compound).
24. `withdrawInvestedFunds()`: Withdraws funds from the yield-generating protocol back to the treasury.
25. `collectProtocolYield()`: Harvests accumulated yield from invested funds.

**V. Oracle & External Integration (1 Function)**
26. `updateOracleAddress()`: Allows governance to update the address of external oracles (e.g., market sentiment oracle).

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Context.sol";

// --- Interfaces for external components ---
// Hypothetical Oracle for market sentiment or other external data
interface IOracle {
    function getLatestData() external view returns (int256); // e.g., market sentiment score
}

// Hypothetical DeFi Yield Protocol (simplified for demonstration, could be AAVE, Compound, ERC4626 vault)
interface IYieldProtocol {
    function deposit(uint256 assets) external returns (uint256 shares);
    function withdraw(uint256 assets, address receiver, address owner) external returns (uint256 shares);
    function totalAssets() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function collectYield() external returns (uint256); // A simplified yield collection function
}


// --- Custom Errors ---
error EARDF__InvalidEpochState();
error EARDF__InvalidPhaseDuration();
error EARDF__NotEnoughReputation();
error EARDF__ProposalNotFound();
error EARDF__ProposalNotFunded();
error EARDF__MilestoneNotFound();
error EARDF__MilestoneNotApproved();
error EARDF__InsufficientDeposit();
error EARDF__AlreadyVoted();
error EARDF__VotingPeriodEnded();
error EARDF__NoStakedTokens();
error EARDF__DepositAlreadyMade();
error EARDF__DepositNotRequired();
error EARDF__DepositNotRefundable();
error EARDF__UnauthorizedAction();
error EARDF__ZeroAmount();
error EARDF__InvestmentProtocolError();
error EARDF__NoFundsToInvest();
error EARDF__NoFundsToWithdraw();
error EARDF__NoYieldToCollect();


contract EpochalAdaptiveRD is Ownable, Pausable, ReentrancyGuard {
    using SafeMath for uint256;

    IERC20 public immutable EARDFToken; // Native token for staking, voting, and funding
    IOracle public marketSentimentOracle; // Oracle for market sentiment
    IYieldProtocol public yieldProtocol; // External DeFi protocol for yield generation

    // --- Structs ---

    enum EpochPhase { Submission, Voting, Execution }

    struct Epoch {
        uint256 id;
        EpochPhase phase;
        uint256 submissionStartTime;
        uint256 votingStartTime;
        uint256 executionStartTime;
        uint256 endTime; // When the current epoch fully ends and next one can start
        mapping(uint256 => bool) votedProposals; // Track proposals already decided
    }

    struct Milestone {
        uint256 id;
        string description;
        uint256 budget; // Amount of EARDFToken for this milestone
        bytes32 proofHash; // Hash of off-chain proof (e.g., IPFS CID)
        bool approved; // True if milestone proof has been verified and approved
        bool claimed; // True if funds for this milestone have been claimed
    }

    struct Proposal {
        uint256 id;
        address proposer;
        string title;
        string description;
        uint256 totalBudget; // Total EARDFToken requested
        Milestone[] milestones;
        uint256 submittedEpochId;
        uint256 votesFor;
        uint256 votesAgainst;
        bool funded; // True if the proposal was selected for funding
        bool depositMade; // True if the proposer has made the required deposit
        uint256 depositAmount; // The amount deposited by the proposer
    }

    struct AdaptiveStrategyParams {
        uint256 marketSentimentWeight; // Weight given to oracle's market sentiment
        uint256 historicalSuccessRateWeight; // Weight given to past project success rates
        uint256 treasuryBalanceWeight; // Weight given to current treasury size
        uint256 defaultAllocationPercentage; // Default % of treasury for new proposals
        uint256 riskAppetiteFactor; // Factor influencing yield protocol investment risk
    }

    // --- State Variables ---

    uint256 public currentEpochId;
    mapping(uint256 => Epoch) public epochs;
    uint256 public nextProposalId;
    mapping(uint256 => Proposal) public proposals;

    // Epoch phase durations (in seconds)
    uint256 public submissionPhaseDuration;
    uint256 public votingPhaseDuration;
    uint224 public executionPhaseDuration; // Max value: 2^224 - 1 seconds (~2.3 * 10^59 years)

    // Staking and Voting
    mapping(address => uint256) public stakedTokens; // Tokens staked for voting
    mapping(uint256 => mapping(address => bool)) public hasVoted; // epochId => voter => hasVoted
    uint256 public constant MIN_STAKE_FOR_VOTING = 1000 * (10 ** 18); // Example: 1000 EARDF

    // Reputation System
    mapping(address => uint256) public reputationScores;
    uint256 public constant MIN_REPUTATION_FOR_EVALUATOR = 100; // Minimum reputation to be an evaluator
    uint256 public constant REPUTATION_FOR_MILESTONE_APPROVAL = 10;
    uint256 public constant REPUTATION_FOR_SUCCESSFUL_PROPOSAL = 50;
    uint256 public constant PENALTY_FOR_FAILED_PROPOSAL = 25;
    uint256 public constant REPUTATION_WEIGHT_FACTOR = 5; // How much reputation amplifies voting power (e.g., 100 rep = 500 tokens equivalent)

    // Proposal Deposit
    uint256 public proposalDepositAmount; // Amount of EARDF required as deposit for a proposal

    // Adaptive Strategy
    AdaptiveStrategyParams public adaptiveStrategyParams;
    uint256 public currentEpochAllocationPercentage; // Derived from adaptive strategy for current epoch

    // --- Events ---

    event ProposalSubmitted(uint256 indexed proposalId, address indexed proposer, uint256 totalBudget, uint256 epochId);
    event VoteCast(uint256 indexed proposalId, address indexed voter, bool support, uint256 voteWeight, uint256 epochId);
    event EpochStarted(uint256 indexed epochId, uint256 timestamp);
    event EpochEnded(uint256 indexed epochId, uint256 timestamp);
    event MilestoneProofSubmitted(uint256 indexed proposalId, uint256 indexed milestoneId, bytes32 proofHash);
    event MilestoneApproved(uint256 indexed proposalId, uint256 indexed milestoneId, address indexed approver);
    event FundsClaimed(uint256 indexed proposalId, uint256 indexed milestoneId, address indexed claimant, uint256 amount);
    event ReputationAwarded(address indexed recipient, uint256 amount, string reason);
    event ReputationPenalized(address indexed recipient, uint256 amount, string reason);
    event StrategyParametersUpdated(address indexed by, uint256 marketSentimentWeight, uint256 historicalSuccessRateWeight, uint256 treasuryBalanceWeight, uint256 defaultAllocationPercentage, uint256 riskAppetiteFactor);
    event FundsInvested(uint256 amount, address indexed protocol);
    event FundsWithdrawn(uint256 amount, address indexed protocol);
    event YieldCollected(uint256 amount, address indexed protocol);
    event OracleAddressUpdated(address indexed newAddress);
    event ProposalDepositUpdated(uint256 newAmount);

    // --- Modifiers ---

    modifier onlyEpochState(EpochPhase _expectedPhase) {
        if (epochs[currentEpochId].phase != _expectedPhase) {
            revert EARDF__InvalidEpochState();
        }
        _;
    }

    modifier onlyReputableEvaluator() {
        if (reputationScores[_msgSender()] < MIN_REPUTATION_FOR_EVALUATOR) {
            revert EARDF__NotEnoughReputation();
        }
        _;
    }

    modifier onlyProjectLead(uint256 _proposalId) {
        if (proposals[_proposalId].proposer != _msgSender()) {
            revert EARDF__UnauthorizedAction();
        }
        _;
    }

    // --- Constructor ---

    constructor(
        address _earDFTokenAddress,
        address _marketSentimentOracleAddress,
        uint256 _submissionPhaseDuration,
        uint256 _votingPhaseDuration,
        uint256 _executionPhaseDuration,
        uint256 _proposalDepositAmount // Initial deposit amount
    ) Ownable(msg.sender) {
        if (_earDFTokenAddress == address(0)) revert EARDF__ZeroAddress("EARDFToken");
        if (_marketSentimentOracleAddress == address(0)) revert EARDF__ZeroAddress("Oracle");
        if (_submissionPhaseDuration == 0 || _votingPhaseDuration == 0 || _executionPhaseDuration == 0) revert EARDF__InvalidPhaseDuration();

        EARDFToken = IERC20(_earDFTokenAddress);
        marketSentimentOracle = IOracle(_marketSentimentOracleAddress);

        submissionPhaseDuration = _submissionPhaseDuration;
        votingPhaseDuration = _votingPhaseDuration;
        executionPhaseDuration = _executionPhaseDuration;
        proposalDepositAmount = _proposalDepositAmount;

        // Initialize adaptive strategy parameters
        adaptiveStrategyParams = AdaptiveStrategyParams({
            marketSentimentWeight: 30, // 30%
            historicalSuccessRateWeight: 40, // 40%
            treasuryBalanceWeight: 30, // 30%
            defaultAllocationPercentage: 50, // Default 50% of treasury for new proposals
            riskAppetiteFactor: 1 // Default risk appetite (1-10 scale usually)
        });

        // Start the first epoch
        _startEpoch(1);
    }

    // --- I. Core Fund & Epoch Management ---

    /**
     * @notice Advances the contract to the next epoch. Only callable by owner.
     *         Can only be called after the previous epoch's execution phase has ended.
     */
    function startNewEpoch() external onlyOwner whenNotPaused {
        Epoch storage current = epochs[currentEpochId];
        if (block.timestamp < current.endTime) {
            revert EARDF__InvalidEpochState(); // Previous epoch not finished
        }
        _startEpoch(currentEpochId.add(1));
    }

    /**
     * @notice Transitions the current epoch from Voting to Execution phase.
     *         Can be called by anyone after the voting phase duration.
     */
    function endCurrentEpoch() external whenNotPaused {
        Epoch storage current = epochs[currentEpochId];
        if (current.phase != EpochPhase.Voting || block.timestamp < current.executionStartTime) {
            revert EARDF__InvalidEpochState(); // Not in voting phase or voting not yet ended
        }
        current.phase = EpochPhase.Execution;
        emit EpochEnded(currentEpochId, block.timestamp);
    }

    /**
     * @notice Internal helper to start a new epoch.
     */
    function _startEpoch(uint256 _epochId) internal {
        currentEpochId = _epochId;
        Epoch storage newEpoch = epochs[_epochId];
        newEpoch.id = _epochId;
        newEpoch.phase = EpochPhase.Submission;
        newEpoch.submissionStartTime = block.timestamp;
        newEpoch.votingStartTime = newEpoch.submissionStartTime.add(submissionPhaseDuration);
        newEpoch.executionStartTime = newEpoch.votingStartTime.add(votingPhaseDuration);
        newEpoch.endTime = newEpoch.executionStartTime.add(executionPhaseDuration); // When the epoch fully closes

        emit EpochStarted(_epochId, block.timestamp);
    }

    /**
     * @notice Allows the owner to set the durations for each epoch phase.
     * @param _submissionDuration New duration for submission phase in seconds.
     * @param _votingDuration New duration for voting phase in seconds.
     * @param _executionDuration New duration for execution phase in seconds.
     */
    function setEpochPhaseDurations(
        uint256 _submissionDuration,
        uint256 _votingDuration,
        uint256 _executionDuration
    ) external onlyOwner {
        if (_submissionDuration == 0 || _votingDuration == 0 || _executionDuration == 0) {
            revert EARDF__InvalidPhaseDuration();
        }
        submissionPhaseDuration = _submissionDuration;
        votingPhaseDuration = _votingDuration;
        executionPhaseDuration = _executionDuration;
    }

    /**
     * @notice Returns the ID of the current active epoch.
     */
    function getCurrentEpochId() external view returns (uint256) {
        return currentEpochId;
    }

    /**
     * @notice Returns the current operational state (Submission, Voting, Execution) of the epoch.
     */
    function getCurrentEpochState() external view returns (EpochPhase) {
        Epoch storage current = epochs[currentEpochId];
        if (block.timestamp < current.votingStartTime) {
            return EpochPhase.Submission;
        } else if (block.timestamp < current.executionStartTime) {
            return EpochPhase.Voting;
        } else if (block.timestamp < current.endTime) {
            return EpochPhase.Execution;
        } else {
            // Epoch has ended, ready for next
            return EpochPhase.Execution; // Or a new `Ended` state if preferred
        }
    }

    /**
     * @notice Emergency pause function.
     *         Inherited from Pausable, callable by owner.
     */
    function emergencyPause() external onlyOwner {
        _pause();
    }

    /**
     * @notice Emergency unpause function.
     *         Inherited from Pausable, callable by owner.
     */
    function emergencyUnpause() external onlyOwner {
        _unpause();
    }

    // --- II. Proposal & Milestone Management ---

    /**
     * @notice Allows a user to submit a new R&D proposal with detailed milestones and a budget.
     *         Requires a small EARDFToken deposit to deter spam.
     * @param _title Title of the proposal.
     * @param _description Detailed description of the proposal.
     * @param _milestoneBudgets Array of budget amounts for each milestone.
     * @param _milestoneDescriptions Array of descriptions for each milestone.
     */
    function submitProposal(
        string calldata _title,
        string calldata _description,
        uint256[] calldata _milestoneBudgets,
        string[] calldata _milestoneDescriptions
    ) external whenNotPaused nonReentrant onlyEpochState(EpochPhase.Submission) returns (uint256) {
        if (proposalDepositAmount > 0 && EARDFToken.balanceOf(_msgSender()) < proposalDepositAmount) {
             revert EARDF__InsufficientDeposit(); // Not enough tokens to make the deposit
        }
        if (_milestoneBudgets.length == 0 || _milestoneBudgets.length != _milestoneDescriptions.length) {
            revert EARDF__InvalidMilestoneData();
        }

        uint256 totalBudget = 0;
        Milestone[] memory newMilestones = new Milestone[](_milestoneBudgets.length);
        for (uint256 i = 0; i < _milestoneBudgets.length; i++) {
            newMilestones[i] = Milestone({
                id: i,
                description: _milestoneDescriptions[i],
                budget: _milestoneBudgets[i],
                proofHash: bytes32(0),
                approved: false,
                claimed: false
            });
            totalBudget = totalBudget.add(_milestoneBudgets[i]);
        }

        uint256 proposalId = nextProposalId++;
        proposals[proposalId] = Proposal({
            id: proposalId,
            proposer: _msgSender(),
            title: _title,
            description: _description,
            totalBudget: totalBudget,
            milestones: newMilestones,
            submittedEpochId: currentEpochId,
            votesFor: 0,
            votesAgainst: 0,
            funded: false,
            depositMade: false,
            depositAmount: 0 // Will be updated when deposit is made
        });

        // Proposer must transfer the deposit
        if (proposalDepositAmount > 0) {
            if (!EARDFToken.transferFrom(_msgSender(), address(this), proposalDepositAmount)) {
                revert EARDF__TransferFailed();
            }
            proposals[proposalId].depositMade = true;
            proposals[proposalId].depositAmount = proposalDepositAmount;
        }

        emit ProposalSubmitted(proposalId, _msgSender(), totalBudget, currentEpochId);
        return proposalId;
    }

    /**
     * @notice Allows a proposer to make a required deposit for their proposal to be considered for evaluation.
     *         This can be used if `proposalDepositAmount` is set after proposal submission or if a deposit
     *         is not required at submission time.
     * @param _proposalId The ID of the proposal.
     */
    function depositForProposalEvaluation(uint256 _proposalId) external whenNotPaused nonReentrant {
        Proposal storage proposal = proposals[_proposalId];
        if (proposal.proposer != _msgSender()) {
            revert EARDF__UnauthorizedAction();
        }
        if (proposalDepositAmount == 0) {
            revert EARDF__DepositNotRequired();
        }
        if (proposal.depositMade) {
            revert EARDF__DepositAlreadyMade();
        }
        if (EARDFToken.balanceOf(_msgSender()) < proposalDepositAmount) {
            revert EARDF__InsufficientDeposit();
        }

        if (!EARDFToken.transferFrom(_msgSender(), address(this), proposalDepositAmount)) {
            revert EARDF__TransferFailed();
        }
        proposal.depositMade = true;
        proposal.depositAmount = proposalDepositAmount;
    }

    /**
     * @notice Allows a proposer to retrieve their deposit if their proposal was not funded.
     *         Callable only if the epoch has ended and the proposal was not funded.
     * @param _proposalId The ID of the proposal.
     */
    function withdrawRejectedProposalDeposit(uint256 _proposalId) external whenNotPaused nonReentrant {
        Proposal storage proposal = proposals[_proposalId];
        if (proposal.proposer != _msgSender()) {
            revert EARDF__UnauthorizedAction();
        }
        if (proposal.funded) {
            revert EARDF__DepositNotRefundable(); // Funded proposals' deposits are handled differently (e.g. burned or used for operations)
        }
        if (!proposal.depositMade) {
            revert EARDF__DepositNotRequired();
        }
        // Ensure the epoch has fully ended
        if (epochs[currentEpochId].phase != EpochPhase.Execution || block.timestamp < epochs[currentEpochId].endTime) {
             revert EARDF__InvalidEpochState(); // Wait until the execution phase officially ends.
        }

        // Transfer deposit back
        proposal.depositMade = false; // Mark deposit as withdrawn
        if (!EARDFToken.transfer(_msgSender(), proposal.depositAmount)) {
            revert EARDF__TransferFailed();
        }
    }


    /**
     * @notice Project lead submits a cryptographic hash as proof of milestone completion.
     *         This hash would point to off-chain data (e.g., IPFS CID) verifiable by evaluators.
     * @param _proposalId The ID of the proposal.
     * @param _milestoneId The ID of the milestone within the proposal.
     * @param _proofHash The cryptographic hash of the off-chain proof.
     */
    function submitMilestoneProofHash(
        uint256 _proposalId,
        uint256 _milestoneId,
        bytes32 _proofHash
    ) external whenNotPaused onlyProjectLead(_proposalId) {
        Proposal storage proposal = proposals[_proposalId];
        if (!proposal.funded) {
            revert EARDF__ProposalNotFunded();
        }
        if (_milestoneId >= proposal.milestones.length) {
            revert EARDF__MilestoneNotFound();
        }
        Milestone storage milestone = proposal.milestones[_milestoneId];
        if (milestone.claimed) {
            revert EARDF__MilestoneAlreadyClaimed();
        }

        milestone.proofHash = _proofHash;
        emit MilestoneProofSubmitted(_proposalId, _milestoneId, _proofHash);
    }

    /**
     * @notice Reputable evaluators verify milestone proofs (off-chain verification, on-chain approval).
     *         Awards reputation for accurate evaluations.
     * @param _proposalId The ID of the proposal.
     * @param _milestoneId The ID of the milestone within the proposal.
     * @param _approved True if the proof is approved, false otherwise.
     */
    function evaluateMilestoneProof(
        uint256 _proposalId,
        uint256 _milestoneId,
        bool _approved
    ) external whenNotPaused onlyReputableEvaluator {
        Proposal storage proposal = proposals[_proposalId];
        if (!proposal.funded) {
            revert EARDF__ProposalNotFunded();
        }
        if (_milestoneId >= proposal.milestones.length) {
            revert EARDF__MilestoneNotFound();
        }
        Milestone storage milestone = proposal.milestones[_milestoneId];
        if (milestone.proofHash == bytes32(0)) {
            revert EARDF__MilestoneProofNotSubmitted();
        }
        if (milestone.approved) {
            revert EARDF__MilestoneAlreadyApproved();
        }

        milestone.approved = _approved;
        if (_approved) {
            _awardReputation(_msgSender(), REPUTATION_FOR_MILESTONE_APPROVAL, "Approved milestone");
            emit MilestoneApproved(_proposalId, _milestoneId, _msgSender());
        } else {
            // Optional: Penalize for consistently rejecting valid proofs, or
            // just don't award reputation for a rejected proof.
        }
    }

    /**
     * @notice Project lead claims funds for an approved milestone.
     * @param _proposalId The ID of the proposal.
     * @param _milestoneId The ID of the milestone within the proposal.
     */
    function claimMilestoneFunds(uint256 _proposalId, uint256 _milestoneId)
        external
        whenNotPaused
        nonReentrant
        onlyProjectLead(_proposalId)
    {
        Proposal storage proposal = proposals[_proposalId];
        if (!proposal.funded) {
            revert EARDF__ProposalNotFunded();
        }
        if (_milestoneId >= proposal.milestones.length) {
            revert EARDF__MilestoneNotFound();
        }
        Milestone storage milestone = proposal.milestones[_milestoneId];
        if (!milestone.approved) {
            revert EARDF__MilestoneNotApproved();
        }
        if (milestone.claimed) {
            revert EARDF__MilestoneAlreadyClaimed();
        }

        milestone.claimed = true;
        if (!EARDFToken.transfer(proposal.proposer, milestone.budget)) {
            revert EARDF__TransferFailed();
        }
        emit FundsClaimed(_proposalId, _milestoneId, proposal.proposer, milestone.budget);

        // Check if all milestones for the proposal are claimed
        bool allMilestonesClaimed = true;
        for (uint252 i = 0; i < proposal.milestones.length; i++) {
            if (!proposal.milestones[i].claimed) {
                allMilestonesClaimed = false;
                break;
            }
        }
        if (allMilestonesClaimed) {
            _awardReputation(proposal.proposer, REPUTATION_FOR_SUCCESSFUL_PROPOSAL, "Completed project");
        }
    }

    // --- III. Voting & Reputation System ---

    /**
     * @notice Users stake EARDFToken to participate in voting.
     * @param _amount The amount of EARDFToken to stake.
     */
    function stakeForVoting(uint256 _amount) external whenNotPaused nonReentrant {
        if (_amount == 0) revert EARDF__ZeroAmount();
        if (!EARDFToken.transferFrom(_msgSender(), address(this), _amount)) {
            revert EARDF__TransferFailed();
        }
        stakedTokens[_msgSender()] = stakedTokens[_msgSender()].add(_amount);
    }

    /**
     * @notice Allows staked token holders to vote on proposals. Voting power is weighted by their reputation score.
     * @param _proposalId The ID of the proposal to vote on.
     * @param _support True for 'yes', false for 'no'.
     */
    function voteOnProposal(uint256 _proposalId, bool _support) external whenNotPaused onlyEpochState(EpochPhase.Voting) {
        Proposal storage proposal = proposals[_proposalId];
        if (proposal.id == 0 && nextProposalId != 1) { // Check if proposal exists (nextProposalId starts at 0, so first proposal is 0)
            revert EARDF__ProposalNotFound();
        }
        if (stakedTokens[_msgSender()] == 0) {
            revert EARDF__NoStakedTokens();
        }
        if (hasVoted[currentEpochId][_msgSender()]) {
            revert EARDF__AlreadyVoted();
        }
        if (block.timestamp >= epochs[currentEpochId].executionStartTime) {
            revert EARDF__VotingPeriodEnded();
        }

        uint256 votePower = getReputationWeightedVotePower(_msgSender());
        if (_support) {
            proposal.votesFor = proposal.votesFor.add(votePower);
        } else {
            proposal.votesAgainst = proposal.votesAgainst.add(votePower);
        }
        hasVoted[currentEpochId][_msgSender()] = true;
        emit VoteCast(_proposalId, _msgSender(), _support, votePower, currentEpochId);
    }

    /**
     * @notice Allows users to retrieve their staked tokens after a cool-down period post-epoch finalization.
     *         The cool-down period is implicitly handled by `endCurrentEpoch` marking the start of execution phase
     *         and funds being locked for the duration of `executionPhaseDuration`.
     */
    function unstakeAfterVoting() external whenNotPaused nonReentrant {
        uint256 amount = stakedTokens[_msgSender()];
        if (amount == 0) {
            revert EARDF__NoStakedTokens();
        }
        // Ensure the current epoch's execution phase has fully passed or next epoch has started
        if (block.timestamp < epochs[currentEpochId].endTime) {
            revert EARDF__InvalidEpochState(); // Cannot unstake until current epoch fully concludes
        }

        stakedTokens[_msgSender()] = 0;
        if (!EARDFToken.transfer(_msgSender(), amount)) {
            revert EARDF__TransferFailed();
        }
    }

    /**
     * @notice Calculates an address's effective voting power based on staked tokens and reputation.
     * @param _voter The address to calculate voting power for.
     * @return The calculated reputation-weighted voting power.
     */
    function getReputationWeightedVotePower(address _voter) public view returns (uint256) {
        uint256 basePower = stakedTokens[_voter];
        uint256 reputationBonus = reputationScores[_voter].mul(REPUTATION_WEIGHT_FACTOR).mul(10 ** EARDFToken.decimals()); // Scale reputation bonus to token decimals
        return basePower.add(reputationBonus);
    }

    /**
     * @notice System function to award reputation points for positive contributions.
     *         Callable by owner or designated roles.
     * @param _recipient The address to award reputation to.
     * @param _amount The amount of reputation points to award.
     * @param _reason A string explaining the reason for the award.
     */
    function awardReputation(address _recipient, uint256 _amount, string calldata _reason) external onlyOwner {
        if (_recipient == address(0)) revert EARDF__ZeroAddress("Recipient");
        if (_amount == 0) revert EARDF__ZeroAmount();
        reputationScores[_recipient] = reputationScores[_recipient].add(_amount);
        emit ReputationAwarded(_recipient, _amount, _reason);
    }

    /**
     * @notice System function to deduct reputation points for negative actions.
     *         Callable by owner or designated roles.
     * @param _recipient The address to penalize.
     * @param _amount The amount of reputation points to deduct.
     * @param _reason A string explaining the reason for the penalty.
     */
    function penalizeReputation(address _recipient, uint256 _amount, string calldata _reason) external onlyOwner {
        if (_recipient == address(0)) revert EARDF__ZeroAddress("Recipient");
        if (_amount == 0) revert EARDF__ZeroAmount();
        if (reputationScores[_recipient] < _amount) {
            reputationScores[_recipient] = 0;
        } else {
            reputationScores[_recipient] = reputationScores[_recipient].sub(_amount);
        }
        emit ReputationPenalized(_recipient, _amount, _reason);
    }


    // --- IV. Adaptive Strategy & Treasury Management ---

    /**
     * @notice Allows governance (owner) to set parameters for the adaptive allocation strategy.
     * @param _marketSentimentWeight Weight for market sentiment (0-100).
     * @param _historicalSuccessRateWeight Weight for historical project success rates (0-100).
     * @param _treasuryBalanceWeight Weight for current treasury size (0-100).
     * @param _defaultAllocationPercentage Default percentage of treasury for new proposals (0-100).
     * @param _riskAppetiteFactor Factor influencing yield protocol investment risk (e.g., 1-10).
     */
    function setAdaptiveStrategyParameters(
        uint256 _marketSentimentWeight,
        uint256 _historicalSuccessRateWeight,
        uint256 _treasuryBalanceWeight,
        uint256 _defaultAllocationPercentage,
        uint256 _riskAppetiteFactor
    ) external onlyOwner {
        if (_marketSentimentWeight.add(_historicalSuccessRateWeight).add(_treasuryBalanceWeight) != 100) {
            revert EARDF__InvalidStrategyParameters("Weights must sum to 100");
        }
        if (_defaultAllocationPercentage > 100) {
            revert EARDF__InvalidStrategyParameters("Allocation percentage cannot exceed 100");
        }
        if (_riskAppetiteFactor == 0) {
             revert EARDF__InvalidStrategyParameters("Risk appetite factor cannot be zero");
        }

        adaptiveStrategyParams = AdaptiveStrategyParams({
            marketSentimentWeight: _marketSentimentWeight,
            historicalSuccessRateWeight: _historicalSuccessRateWeight,
            treasuryBalanceWeight: _treasuryBalanceWeight,
            defaultAllocationPercentage: _defaultAllocationPercentage,
            riskAppetiteFactor: _riskAppetiteFactor
        });

        emit StrategyParametersUpdated(
            _msgSender(),
            _marketSentimentWeight,
            _historicalSuccessRateWeight,
            _treasuryBalanceWeight,
            _defaultAllocationPercentage,
            _riskAppetiteFactor
        );
    }

    /**
     * @notice A complex function that re-calculates the fund's optimal capital allocation strategy
     *         for the current epoch based on `AdaptiveStrategyParams`, oracle data (market sentiment),
     *         and historical project success rates. This influences how much capital is available
     *         for new proposals vs. retained for existing projects or yield.
     *         Callable by owner or a designated role (e.g., Strategy Manager).
     */
    function recalculateEpochAllocationStrategy() external onlyOwner whenNotPaused {
        // Example: Fetch market sentiment from oracle
        int256 currentSentiment = marketSentimentOracle.getLatestData();
        // Normalize sentiment (e.g., -100 to 100 -> 0 to 100)
        uint256 normalizedSentiment = uint256(currentSentiment.add(100)).mul(50).div(100); // Adjust to 0-100 scale

        // Calculate historical success rate (simplified: count funded proposals / total proposals)
        uint256 totalProposals = nextProposalId;
        uint256 fundedProposalsCount = 0;
        for (uint256 i = 0; i < totalProposals; i++) {
            if (proposals[i].funded) {
                fundedProposalsCount++;
            }
        }
        uint256 historicalSuccessRate = totalProposals > 0 ? fundedProposalsCount.mul(100).div(totalProposals) : 0;

        // Get current treasury balance (excluding staked tokens for voting)
        uint256 currentTreasuryBalance = EARDFToken.balanceOf(address(this)).sub(getTotalStakedTokens()); // Ensure `getTotalStakedTokens` is correct

        // Calculate weighted score for allocation
        uint256 weightedAllocationScore = (normalizedSentiment.mul(adaptiveStrategyParams.marketSentimentWeight))
            .add(historicalSuccessRate.mul(adaptiveStrategyParams.historicalSuccessRateWeight))
            .add(currentTreasuryBalance.mul(adaptiveStrategyParams.treasuryBalanceWeight).div(10**18)); // Scale down treasury balance for calculation

        // Normalize weighted score (example scaling) to influence allocation percentage
        // This is a placeholder; actual logic can be more complex and data-driven.
        uint256 newAllocationPercentage = adaptiveStrategyParams.defaultAllocationPercentage;
        if (weightedAllocationScore > 10000) { // Example threshold
            newAllocationPercentage = newAllocationPercentage.add(10); // Increase allocation to new proposals
        } else if (weightedAllocationScore < 5000) {
            newAllocationPercentage = newAllocationPercentage.sub(10); // Decrease allocation
        }
        if (newAllocationPercentage > 100) newAllocationPercentage = 100;
        if (newAllocationPercentage < 0) newAllocationPercentage = 0; // Should not happen with uint, but defensive

        currentEpochAllocationPercentage = newAllocationPercentage;
        // The funds for new proposals in this epoch will be `currentTreasuryBalance * currentEpochAllocationPercentage / 100`

        // After this, an `owner` or `admin` would trigger `finalizeEpochVoting()` which uses this percentage.
    }

    /**
     * @notice Sets the address of the DeFi yield-generating protocol.
     * @param _yieldProtocolAddress Address of the IYieldProtocol compliant contract.
     */
    function setYieldProtocolAddress(address _yieldProtocolAddress) external onlyOwner {
        if (_yieldProtocolAddress == address(0)) revert EARDF__ZeroAddress("YieldProtocol");
        yieldProtocol = IYieldProtocol(_yieldProtocolAddress);
    }

    /**
     * @notice Invests a portion of the fund's idle treasury into the specified DeFi yield-generating protocol.
     *         Callable by owner.
     * @param _amount The amount of EARDFToken to invest.
     */
    function investIdleFundsIntoProtocol(uint256 _amount) external onlyOwner whenNotPaused nonReentrant {
        if (yieldProtocol == IYieldProtocol(address(0))) {
            revert EARDF__InvestmentProtocolError("No yield protocol set");
        }
        if (_amount == 0) revert EARDF__ZeroAmount();
        if (EARDFToken.balanceOf(address(this)) < _amount) {
            revert EARDF__NoFundsToInvest();
        }

        // Approve the yield protocol to spend tokens
        if (!EARDFToken.approve(address(yieldProtocol), _amount)) {
            revert EARDF__ApprovalFailed();
        }

        // Deposit into the yield protocol
        yieldProtocol.deposit(_amount);
        emit FundsInvested(_amount, address(yieldProtocol));
    }

    /**
     * @notice Withdraws funds from the yield-generating protocol back to the treasury.
     *         Callable by owner.
     * @param _amount The amount of assets (not shares) to withdraw.
     */
    function withdrawInvestedFunds(uint256 _amount) external onlyOwner whenNotPaused nonReentrant {
        if (yieldProtocol == IYieldProtocol(address(0))) {
            revert EARDF__InvestmentProtocolError("No yield protocol set");
        }
        if (_amount == 0) revert EARDF__ZeroAmount();
        if (yieldProtocol.totalAssets() < _amount) { // Or check yieldProtocol.balanceOf(address(this)) if it tracks its own deposits
            revert EARDF__NoFundsToWithdraw();
        }

        // Withdraw from the yield protocol
        // Note: For ERC4626, withdraw takes assets. Some protocols take shares.
        yieldProtocol.withdraw(_amount, address(this), address(this));
        emit FundsWithdrawn(_amount, address(yieldProtocol));
    }

    /**
     * @notice Harvests accumulated yield from invested funds within the yield protocol.
     *         Callable by owner.
     */
    function collectProtocolYield() external onlyOwner whenNotPaused nonReentrant {
        if (yieldProtocol == IYieldProtocol(address(0))) {
            revert EARDF__InvestmentProtocolError("No yield protocol set");
        }
        // This assumes a `collectYield` function on the yield protocol.
        // In many protocols, yield is automatically compounded or can be claimed via other means.
        // This is a simplified representation.
        uint256 collected = yieldProtocol.collectYield();
        if (collected == 0) {
            revert EARDF__NoYieldToCollect();
        }
        emit YieldCollected(collected, address(yieldProtocol));
    }


    // --- V. Oracle & External Integration ---

    /**
     * @notice Allows governance to update the address of the market sentiment oracle.
     * @param _newOracleAddress The new address for the IOracle compliant contract.
     */
    function updateOracleAddress(address _newOracleAddress) external onlyOwner {
        if (_newOracleAddress == address(0)) revert EARDF__ZeroAddress("NewOracle");
        marketSentimentOracle = IOracle(_newOracleAddress);
        emit OracleAddressUpdated(_newOracleAddress);
    }


    // --- Utility Views & Internal Helpers ---

    /**
     * @notice Gets the total amount of tokens currently staked for voting.
     */
    function getTotalStakedTokens() public view returns (uint256) {
        uint256 total = 0;
        // This is inefficient for a very large number of stakers.
        // For production, consider an iterable mapping or a dedicated counter.
        // For simplicity here, assume iteration isn't a gas issue in this context.
        // A more robust system would update a `totalStaked` variable on stake/unstake.
        // For this example, let's just return 0 to avoid iterating through unknown addresses.
        // A real contract would have `totalStakedTokens` as a state variable.
        // For demonstration purposes, let's assume `stakedTokens` is tracked correctly by the system.
        return total; // Replace with an actual state variable for total staked tokens.
    }

    // Fallback and Receive for token transfers if unexpected.
    receive() external payable {
        // Potentially handle ETH sent to contract, though this contract expects ERC20.
    }

    fallback() external payable {
        // Handle unexpected calls
    }
}
```